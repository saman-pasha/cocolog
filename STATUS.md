# Status

Where this stands, what is proven, and what is not. Written to be picked up
again rather than to look finished.

## Done and tested

`make test` ends `red: 0`. The database suites **skip** rather than fail when
there is no server, because "no server here" and "the backend is wrong" are
different findings.

| suite | what it establishes |
|---|---|
| `test/term.cicili` | interning, unification, the trail undoing exactly, copying that renames consistently, the standard order, and the term DSL — 27 checks |
| `test/syntax.cicili` | the reader and the writer against each other: precedence, associativity, the spacing that decides whether `-(1)` reads back as a compound or an integer, lists, curly terms, quoting, radix and character literals — 41 checks |
| `test/solve.cicili` | backtracking, cut, negation, if-then-else, arithmetic, lists, term inspection, assert/retract, `:- dynamic` in all three spec shapes and as a goal, `listing`, a 50000-deep deterministic recursion that must leave no choice points, and a failing goal that must not grow the heap |
| `test/module.cicili` | the module seam itself: no modules behaves as before modules, three at once, a module's Coco half calling its own C half, a module that is only clauses, precedence against both builtins and the knowledge base, a failing module predicate leaving no binding, and the Coco half coming back after the store is emptied — 22 checks |
| `test/files/*.pl` | the Files and Lists libraries, run by **both swipl and cocolog** in the same fresh directory and compared byte for byte — 194 lines of agreement across seven cases |
| `test/state.cicili` | a machine run to one solution, frozen, its machine and store **freed**, thawed into new ones, and finishing the proof correctly; and `freeze(thaw(x)) == x` byte for byte |
| `test/zigurat.cicili` | the Cicili binding against a real server: every parameter width, a cursor, and a Text large enough to matter |
| `test/shared.cicili` | ten interpreters in sequence — one writes the knowledge base, a second built from nothing answers from it, a third suspends mid-proof and is freed, a fourth picks it up and finishes it, a fifth asserts at run time, a sixth sees it, a seventh retracts, an eighth agrees it is gone, a ninth declares two predicates dynamic and a tenth — which starts knowing nothing — warms its store and finds them declared and empty. Then the same knowledge base over HTTP, and a machine written over the binary protocol picked up over HTTP — 39 checks |
| `test/groups.sh` | **twelve interpreters at once over four machine states** — below |
| `test/ruler.sh` | **one interpreter writing the knowledge base while eight read it** — below |
| `client/probe.c` | the C client against a real server, including a clause made of nothing but the five HTML-escapable characters, asserted over the binary protocol and read back through a page unchanged |

## Twelve interpreters, four states

`test/groups.sh`. Four groups of three: twelve `cocolog work` processes at once,
each group taking turns on one machine and handing it back and forth through the
database. Every machine produces its full answer set with **no answer twice**,
every member of every group takes turns, and nothing is left suspended.

```
     turns: a1=6 a2=4 a3=7
     turns: b1=4 b2=4 b3=4
     turns: c1=10 c2=10 c3=10
     turns: d1=11 d2=7 d3=12
GREEN: 0 failure(s)
```

Three things had to be right, and each was wrong first.

**The claim has to be SERIALIZABLE.** It is a read followed by a write of the
row it read: find an idle machine, then mark it. At READ COMMITTED — which is
what every other procedure runs at, and rightly — two workers arriving together
both see `suspended`, both take it, and both advance the same state from the same
point. The answers come out twice. It is the one place in cocolog that needs the
strongest level, and ZiguratIP's SERIALIZABLE excludes only other SERIALIZABLE
transactions, so twelve claims queue for microseconds each while the work that
matters — loading, proving, saving — goes on at READ COMMITTED all at once.

**An empty claim means two different things.** The machine is either gone —
proved out and dropped — or busy in a partner, which is the normal state of
affairs and no reason at all to stop. Treating the second as the first made every
machine get finished by whichever worker reached it first.

**And "gone" is not quite proof the first time you see it.** A worker gives up
only after the machine has been out of sight *continuously* for
`CO_GONE_CONFIRM` polls — and waits far longer for one it has never seen at all,
because absence before the first sighting means "not created yet". That is what
lets a pool of twelve be started before the work exists, which is the only way to
start twelve without the first few finishing before the last are running.

That confirmation used to be three hundred polls — a second and a half — and is
now two. Both reductions are ZiguratIP fixes. A reader at READ COMMITTED used to
*wait* on the lock of a row another transaction was rewriting, and by the time
the wait ended the version it was waiting on had been retired and the replacement
was at an address it had already passed: for the whole length of a save, a
partner asking after the machine was told it did not exist. With the wait gone
the same thing remained in miniature, because a scan spans time. A reader now
takes the version that was current when its statement began, decided against a
microsecond clock, so a machine being saved is there throughout and there exactly
once.

Two polls and not none, because a worker's `exists` and its next `claim` are
separate transactions and a partner may drop the machine between them.

That last number is a heuristic and is allowed to be: what it decides is only
**when a worker goes home**. It cannot make two workers advance one machine, lose
a turn, or produce an answer twice. The claim settles all of that exactly.

## One ruler, eight queriers

`test/ruler.sh`. One process asserts a program one clause at a time — rules
first, so that for most of the run there are rules whose facts have not arrived —
while eight others query the same knowledge base against the same server.

The check is deliberately one-sided: **no querier may ever answer anything
outside the finished program's answer set**. A rule that cannot prove anything
yet is not wrong, it is early. Anything else means a querier read a clause that
was never committed, or half of one. The suite also checks that the queriers were
genuinely reading while it was being written — the number of answers has to grow
across the run, or they were only ever reading a finished program and the run
proved nothing about concurrency.

## The database is the knowledge base, all the way

`:- dynamic`, `listing`, `assert` and `retract` now mean the same thing whether
the clauses are in this process's memory or in a table several interpreters
share. Four things had to change for that, and three of them were bugs.

**A directive was asserted as a clause.** `:- dynamic counter/1.` in a consulted
file was read as a term whose functor is `:-` and arity 1, and put in the store
under a predicate called `:-`. `co_directive` handles the declarations that are
about the store itself — `dynamic/1` in all three shapes a spec is written in
(`a/1`, `a/1, b/2`, `[a/1, b/2]`), `discontiguous/1` parsed and deliberately
ignored — and REFUSES anything else by name rather than storing it. Directives
that are goals still want an engine, which the store is a layer below.

**`retract` was local.** The clause came out of the store in memory and the
database never heard: it was back the next time the predicate was fetched, and
no other interpreter ever saw it go. An interpreter that can assert into a
shared knowledge base and not retract from it is halfway to being one. The
`on_retract` hook is the other half.

**A query never committed.** `cocolog query` opened a transaction, proved the
goal, printed the answers and closed the connection — so a goal that asserted
or retracted said it had and changed nothing. It commits now, and rolls back
whole when the goal ended in an error.

**And a declaration has to outlive the process that made it.** In a knowledge
base kept in memory `:- dynamic` can be a flag on a struct, because the program
that declared it is the program that runs. Here the clauses are shared and the
declaration is about them, so it is a row in `cocolog::props` and the `warm`
hook brings it back. A predicate declared and never written to exists and is
empty, which is not the same as its not being there — `listing` shows the
difference and so does the store.

Two smaller things fell out of it:

* **A PAGE and a PROCEDURE of the same name are one object.** `cocolog::
  predicates` was both, and pages are compiled last, so the procedure's `.so`
  was silently replaced and every call to it died with `undefined symbol: call`.
  The procedures are `predicates_of` and `props_of` now. Worth knowing before
  naming anything in Parsi.
* **Writing a predicate back must not clear its declaration.** Assert and
  retract both rewrite the whole predicate, and the procedure they called to
  clear it was `cocolog::forget` — which, once it also removed the `:- dynamic`
  row, would have undeclared a predicate the moment anything was asserted into
  it. They call `forget_clauses`; `forget` still takes the whole predicate,
  declaration and all, because a predicate that is not there is not declared
  either.

## What had to be fixed in ZiguratIP

cocolog began as a client that modified nothing. Most of what follows was found
by pointing twelve of them at one server, and it is fixed in ZiguratIP itself now
rather than worked around here. See its `doc/concurrency.md`.

* **The B-tree indexes took no lock on the shared page streams.** Two clients
  doing `WHERE indexed_column == value` at once read from each other's file
  position: `hexmap ends inside the chunk at NNNNN`, and often enough a dead
  server and a store to throw away.
* **A reader at READ COMMITTED waited for a writer, and then saw neither
  version** of the row it had waited for. A machine being saved did not exist as
  far as its partners were concerned, for as long as the save took.
* **A scan had no fixed view**, so a row rewritten while one was running could be
  counted twice or missed — 865 double counts in one run of three scanners
  against a single writer. Version stamps were at one-second resolution, which
  cannot tell two versions of a busy row apart.
* **`TRANSACTION ISOLATION LEVEL` had never compiled.** The generated C++ used
  `->` on a value member, so every procedure carrying the documented clause
  failed to build.
* **An isolation level outlived the transaction that set it**, and with
  SERIALIZABLE that leaked a server-wide semaphore slot — one client did all the
  work and the rest hung.
* **`SERVER/POOL_SIZE` shipped as 5**, which is the most clients that can be
  connected at once. The twelve did not get an error; they got silence until
  their own sockets timed out.

## Modules, and the Files library

`lib/module.cicili` adds a second seam beside the knowledge base one: two null
function pointers in `lib/solve.cicili` that a module fills in. A module carries
predicates written in Cicili and clauses written in Prolog, and a program cannot
tell which half answered it. MODULES.md is how to write one.

Two ship, and they are mirror images of each other. `lib/files.cicili` is
SWI's file-system predicates: seventeen in C, five in Prolog on three private
primitives. `lib/lists.cicili` is all thirty-six of `library(lists)` the other
way round — thirty-odd in Prolog, seven in C.

**That shape is forced, not chosen.** `member/2`, `select/3`, `append/3` and
`permutation/2` answer many times, and a module's C half cannot: it has no
access to the choice stack, deliberately, so that no module can break the
invariant suspension depends on. In the Coco half the engine provides the
choice points, and a machine frozen mid-backtrack thaws in another process and
goes on. Written in C they would work until the first `cocolog step`.

Lists also needed `call/N` in the engine — `max_member/3` takes a comparison
predicate and is `call(Pred, A, B)` and nothing else — and four SWI builtins
cocolog lacked: `length/2`, `msort/2`, `sort/2` and `sort/4`.

**It is checked against a real SWI rather than against its author.**
`test/files/*.pl` are Prolog programs run twice — by `swipl` and by
`cocolog --local run` — in a freshly made empty directory that is the same
absolute path both times, and the two outputs compared byte for byte. That is
the only form of compatibility claim that cannot be fooled by what the author
believes SWI does, and it earned itself on the first run:
`file_name_extension(B, E, '.bashrc')` gives `B = ''` and `E = bashrc` in SWI,
because a leading dot **is** an extension separator. This library had the rule
everybody would guess instead.

Three things had to be added to make that comparison possible at all:

* **`cocolog run FILE [GOAL]`** — consult and prove in one process, with no
  database. Deliberately the shape of `swipl -q -g GOAL -t halt FILE`: nothing
  is printed but what the program writes.
* **A muted store.** A module's clauses belong to the build, not the knowledge
  base. Written through they would be saved into the shared database, come back
  on every fetch, and be listed as the user's own — and the next interpreter to
  open the same knowledge base would hold two copies of the library.
* **A `library` flag on a predicate**, so `listing` with no argument is the
  program and not everything reachable. `listing(Name)` still shows a library
  predicate, because asking for one by name is asking about that one.

## The writer agrees with SWI about spacing

It used to put a space around every operator: `1 + 2 * 3`, `a - b`. SWI writes
`1+2*3` and `a-b`, and the difference meant the shared tests could not print a
compound term at all without measuring formatting rather than the library.

**The rule is the reader's own tokeniser read backwards.** A space goes in
exactly where the two pieces would otherwise lex as ONE token: `a` and `-` do
not merge, so `a-b`; `-` and `-` do, so `1- -2`; `mod` and `b` do, so
`a mod b`. A solo character never merges, which is why `a,-1` has no space.

The operator and the right operand are rendered into buffers of their own
before the decision, because it needs their real first and last characters — a
quoted atom begins with a quote and a negative number with a minus, and neither
is knowable from the term.

Prefix position has one rule that is not a merge at all: **a digit after a
symbolic prefix operator takes a space** — `- 1`, because `-1` is not the
operator applied to one, it is the integer. `1-2` is right without one, so it
is genuinely about prefix position. An opening parenthesis takes one too,
which is what SWI does: `- (a+b)`.

Sixty-two terms were compared against a running SWI 9 term by term; sixty-one
now agree, and the one that does not is a *reader* gap — `:` is not an operator
in cocolog — and nothing to do with spacing. `test/syntax.cicili` holds the
rule as twenty golden cases and seven round-trips, because a writer that agrees
with SWI and no longer reads back would be a worse writer.

One real bug came out of it and is worth remembering: routing the operator
through `co_write_atom` quoted the comma, so `a:-b,c` became `a:-b','c`, which
reads back as something else entirely. The comma is the only operator in the
table that gets quoted, and it is now written directly.

## Known limitations, by choice

* **`--lock` is off by default and should stay off.** It makes cocolog processes
  take turns through a `flock`, one per transaction, which is what a server that
  cannot take concurrent clients needs and is about as concurrent as a queue. It
  is kept for talking to a ZiguratIP without the fixes above.
* **A claim has no lease.** `cocolog::machine_release` puts a machine back, and a
  worker that loses its connection calls it — but one killed outright strands its
  machine as claimed, and only `cocolog drop` clears it. A lease with an expiry
  would want a timestamp column and a clock the server agrees with.
* **The HTTP backend does not write.** One request is one transaction; a machine
  is a header row plus a row per chunk. Stated in `lib/zeytun-kb.cicili` and in
  `parsi/03-pages.parsi`.
* **`consult` asserts, it does not replace.** Consult the same file twice and
  every proof answers everything twice; `cocolog forget` is how a knowledge base
  is emptied.
* **A directive is not run as a goal.** `co_directive` handles `dynamic/1` and
  ignores `discontiguous/1`; anything else in a consulted file is an error
  naming what it was. `:- initialization(main).` would want an engine, and the
  store is a layer below the engine — the file that would have to call into
  solve.cicili is compiled before it.
* **`listing` writes to stdout.** It is a builtin that prints, not one that
  builds a term, so a program cannot capture what it produces. `listing/0` and
  `listing/1` both answer once and are deterministic like every other builtin.
* **Builtins are all deterministic.** One that could leave a choice point behind
  — `between/3`, `clause/2` — would need the engine's choice stack in its hands.
  They belong in a Prolog-level library instead, which does not yet exist.
* **Resuming assumes the clauses have not moved.** A choice point remembers a
  predicate by name and the position of the next clause to try, so retracting
  from underneath a suspended machine makes it resume at the wrong one. This is
  the hazard `retract` has always had against a running query; the fix is to hold
  a transaction over the clause tables.
* **`asserta` rewrites its whole predicate** in the database, because putting a
  clause at the front changes every later clause's ordinal. O(n) per assert and
  always right.
* **No error terms.** A goal that cannot be run reports through the engine's
  `err` string and stops the query, rather than throwing a Prolog `error/2` a
  program could catch. `catch/3` and `throw/1` are not implemented.
* **A module cannot define an operator.** The reader's table is fixed at build
  time, so a module whose predicates want infix syntax cannot have it. This is
  the one real gap in the module seam; the other two — no choice points, no
  per-session state — are the price of being suspendable and are not going to
  change.
* **No garbage collection.** The heap only grows within a solution; it is
  reclaimed on backtracking and on a new query. A long deterministic run that
  builds structure will grow until it ends.

## Not started

* A REPL. `cocolog query` runs one goal and exits.
* `findall/3`, `bagof/3`, `setof/3`.
* Strings as a type; `"abc"` reads as a code list, which is the ISO default.
* Any indexing on the first argument. A predicate's clauses are tried in order.
