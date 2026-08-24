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
| `test/files/*.pl` | the Files, Lists, Apply, Builtins and DCG libraries — and SWI's own `dcg/basics` and `dcg/high_order`, unedited — run by **both swipl and cocolog** in the same fresh directory and compared byte for byte. 555 lines of agreement across nineteen cases |
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
`COCO_GONE_CONFIRM` polls — and waits far longer for one it has never seen at all,
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
under a predicate called `:-`. `coco_directive` handles the declarations that are
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

`lib/apply.cicili` is all seventeen of `library(apply)` with **no C half at
all**, and `lib/builtins.cicili` is the thirty-eight ISO-core builtins cocolog
was missing, computed against SWI's list rather than remembered. SWI has 655
builtins; the ones that cannot exist here are the stream, module, thread,
tabling, foreign-interface and string families, and that is stated in
MODULES.md rather than left to be discovered.

`findall/3` had to be an ENGINE service — it runs a goal to exhaustion and a
module cannot see the engine — so `coco_engine_findall` starts a nested engine on
the same machine and store. **Its solutions travel through the store and not
the heap**, because backtracking truncates the heap to the choice point's mark
and a copy made there during the search is gone by the time the search ends.

`bagof/3` and `setof/3` are in, and they are not findall plus a sort: they
answer once per distinct binding of the goal's free variables and FAIL where
findall answers `[]`. They are clauses, because the backtracking comes from
`member/2` over the groups.

**Implementing them found a real bug in `findall/3`.** The sub-engine's last
solution left its bindings on the trail — a predicate's final clause drops its
own choice point, so there was no frame left to backtrack through and undo
them. `findall(X, p(X,Y), L)` came back with Y still bound to whatever the last
solution made it, which is invisible until something reuses Y and then sees one
solution where there were four. `coco_engine_findall` puts the machine back as it
was before building the answer, which also reclaims everything the search
built.

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
through `coco_write_atom` quoted the comma, so `a:-b,c` became `a:-b','c`, which
reads back as something else entirely. The comma is the only operator in the
table that gets quoted, and it is now written directly.

## catch/3 and throw/1, and errors that are SWI's

A goal that cannot be run used to report through the engine's `err` string and
stop the query. It now raises `error(Formal, _)` with the same Formal SWI
raises, and a program catches it with the portable
`catch(G, error(type_error(T, V), _), R)`. Ten error terms are compared against
a running SWI in `test/files/catch.pl` and all ten agree.

**A catch is a choice-point frame, and that is what made it affordable.** The
engine already writes every frame into a frozen machine field by field with its
kind, and the catcher and the recovery goal ride on the heap as one
`'$catch'(C, R)` term — which the heap serialiser already carries. So a machine
suspended *inside* a `catch` comes back inside it. `test/state.cicili` freezes
one part-way through a guarded goal, thaws it into a new machine and store, and
the throw is still caught by the frame that came back; `cocolog step` does the
same thing five times over a real database.

`throw/1` puts the ball in the **store** before unwinding, for the same reason
`findall` does: unwinding truncates the heap to the frame's mark, and the ball
was built above it.

One thing had to change in the engine's dispatch and is worth remembering: a
builtin that threw *and was caught* must answer **2**, not 1. The engine sets
the continuation from the builtin's own `k` on a 1, which would throw away the
recovery goal `throw/1` had just installed and carry on as if nothing had been
raised. That bug printed nothing at all and returned success.

## op/3, and what it forced about the database

`*operators*` is read at BUILD time and emits both halves of the grammar, which
is what stops the reader and the writer disagreeing about an operator. `op/3`
cannot change that table, so it adds a second one consulted first — and an
entry there with priority 0 hides the built-in of the same name, which is how
`op(0, xfx, =)` takes one away.

**`:- op(...)` is handled by `coco_directive` and not by the engine**, because a
declaration has to take effect for the *rest of the file being read*. A
directive dealt with after the whole file was parsed would be too late to
matter. That is why `lib/kb.cicili`, which is compiled below the engine and
cannot run a goal, reaches into `lib/syntax.cicili`: the operator table is the
reader's, and this directive is about the reader.

**And it exposed something the database had wrong all along.** A clause lives
in ZiguratIP as text and is parsed by whichever process fetches it. Written
with operators, `rule(a ===> b)` can only be read back by a process that has
declared `===>` — and a second interpreter opening the same knowledge base has
declared nothing. It did not fail loudly either: the text simply did not parse
and the predicate looked empty. Measured, not reasoned about — a fresh process
answered `false.` to `rule(X)` for two clauses that were plainly there.

Clauses are stored functionally now — `rule(===>(a,b))` — through
`coco_write_storable`, so they need no operator table at all and read the same in
every process for ever. `listing` still shows operators, because that is for a
person; `test/shared.cicili` proves the cross-process case.

A machine's declared operators also travel with it, in an optional `O` section
of the frozen form. Optional so that a machine frozen by an older build still
thaws.

**One writer bug came out of it.** An operator atom was bracketed in every
position but the top: `f((-))`, `[(-)]`. SWI brackets one only as an OPERAND —
`f(-)` and `[a,-]` are fine as they stand, because an argument is read at
priority 999 and a `-` followed by `,` or `]` cannot be a prefix operator.
`- (-)` and `(-)-a` are not fine, and are still bracketed.

## The reader knows what can start a term

An atom that is a prefix operator is only a prefix operator if what follows it
could begin a term. `- - a` is prefix `-` applied to `-a`, because the second
`-` can begin one. `- = a` is infix `=` with the **atom** `-` on its left,
because `=` is only ever infix and begins nothing.

The reader used to say that any name could start a term, so it read `- = a` as
prefix `-` applied to the atom `=` and stopped with `a` unread. `- * a` and
`- mod a` were misread the same way.

**And a quoted atom is never a prefix operator.** `'-' - a` is infix with the
atom `-` on the left where `- - a` is prefix applied to `-a` — the same tokens,
differing only in the quotes, so the lexer has to remember which it saw.

One more thing had to give: an operator atom used as a plain operand now has
**priority 0**. Carrying the operator's priority made `- * a` unreadable — the
atom `-` came back at 500, `*` is 400 yfx and admits a left operand of at most
400, and the reader gave up with the `*` unconsumed. Every Prolog is lenient
there; the strict reading buys nothing and refuses terms that are perfectly
clear. The **writer** is where the priority still matters, and it brackets such
an atom when it stands as an operand.

## Twelve workers: what was actually wrong, and what still is

`test/groups.sh` used to fail, and the cause was none of the things it looked
like. Written down because several wrong answers looked right for a while, and
two of them were acted on before being checked.

**It was never a hang.** Run without the `timeout` wrapper the suite always
completed — every worker finished, every answer appeared. It was slow, and
`WORKER_TIMEOUT` is 60 seconds.

**It was not the SERIALIZABLE gate**, though a profile showed 63 samples sitting
on `_serialize_mutex` and three threads waiting on `_serialize_cv` with the
counter at zero. Removing `TRANSACTION ISOLATION LEVEL SERIALIZABLE` from both
procedures made it *slower* — 58s against 52s. The profile pointed at a queue
that was a symptom.

**What was actually fixed, and it was latency:**

* **`TCP_NODELAY`, at both ends** (`client/zigurat.c`, and ZiguratIP's
  `TCPServer::run`). Small request, small reply, wait: the pattern Nagle
  coalesces and delayed ACK stalls 40ms at a time.
* **The client read one byte at a time.** `rd_u8` called `recv` for a single
  byte — one `cocolog step` measured **957 `recvfrom` and 383 `sendto`** for a
  few dozen bytes of conversation. Reads now fill 8KB: 957 down to 383, one per
  exchange. With NODELAY, 155ms per step became 85ms.
* **A busy poll no longer writes.** A worker waiting on a claimed machine used
  to find out by *attempting the claim* — a write transaction, at SERIALIZABLE,
  committed, several times a second per waiting worker. It now asks with a read
  and only writes when nobody holds it.

`make test` ends `red: 0`, and `groups` runs in about 16 seconds.

### What is still wrong: the store only grows

A deleted row is kept under MVCC so that a transaction entitled to an earlier
view can still read it, and **there is no vacuum**. `machine_open` saves a
machine by deleting its row and inserting a replacement, so a proof of thirty
turns leaves twenty-nine dead rows; `forget` then `consult` leaves a dead copy of
every clause. Eight consult+forget cycles netting *zero* rows added 32KB to the
file every time.

Measured, twelve workers over four machines, no compaction between runs:

| run | wall | data file |
|---|---|---|
| 1 | 14s | 34736 KB |
| 2 | 20s | 34752 KB |
| 3 | 24s | 34776 KB |
| 4 | 29s | 34792 KB |
| 5 | 32s | 34808 KB |

More than double, on identical work, while the file grew 72KB. It is not size —
it is how many dead versions each index entry has to be walked past.

**ZiguratIP's `TRUNCATE` is the vacuum, and cocolog cannot currently use it.**
A `cocolog compact` command was built and then withdrawn, for two reasons:

1. **It spends something real.** `TRUNCATE` gives up exactly the deleted
   versions that `rollback_transaction_to` and SNAPSHOT are made of, so after it
   the store cannot be read at a point in time before it ran. That is a
   capability of the knowledge base, not a cache.
2. **It does not work on any store cocolog has already written.** `TRUNCATE`
   reads whole rows to unlink their index entries, and a NULL column cannot be
   read back at all — the engine refuses the row with `NULL value`. `machines.note`
   was nullable and the client wrote the empty string into it, which the store
   keeps as NULL. Both are fixed going forward (the column is `NOT NULL`, the
   client writes `-`), but every row already written carries a NULL and cannot
   be reclaimed.

So on a store from before the schema fix the growth is unmitigated, and the
only cure is a fresh data directory. On a store written since, the pass works —
and it came back, this time with the permission model the withdrawal was
asking for. `cocolog vacuum` is the verb, on the wire (`cocolog::vacuum`,
which `make schema` ships) and embedded (`--store`, the Cicili engine's own
truncate) alike; `vacuum_kb/0,1` is the builtin, and it is **gated**: without
`--vacuum` on the command line it raises
`permission_error(vacuum, knowledge_base, _)`, because spending the store's
point-in-time reads is the operator's scheduled decision and never a
program's side effect. README's "A worked store slows down. Truncate it."
carries the measured numbers (12s empty, 60s aged, 16s after one pass) and
the schedule doctrine; `test/vacuum.sh` proves the pass and the gate in both
arrangements, and the concurrency suites run the verb in setup, which is why
they no longer slow down run over run. The honest long-term fix is still a
vacuum that does not cost point-in-time reads.

### The one-core ceiling is lifted, and parallel reads are the default

The ceiling was `Memory::Streams`: one global mutex pair over the two shared
file streams, every read serialised against every other. The Cicili engine
now has the design the first attempt was reaching for, with the lesson that
attempt taught built in — **the lock mode follows the isolation level**. The
guard is a read-write lock; a cursor whose isolation writes nothing
(READ UNCOMMITTED, READ COMMITTED, SNAPSHOT) takes it shared and reads
through the thread's own private streams; REPEATABLE READ and SERIALIZABLE
cursors — which stamp shared row locks as they scan — and every writer take
it exclusive, and an exclusive release flushes both canonical streams so a
private reader taken the next instant cannot miss bytes still sitting in
their buffers.

Measured, the twelve-worker embedded choreography on a fresh store: 5.3s at
~119% CPU with the guard exclusive; **1.6s at ~150% CPU with the shared side
on** — three times faster, on more than one core. About one run in three
under the flag once timed out, and all three causes of that stall are now
found and killed. Two were in the walk: a cursor's page-list snapshot
missing a page a writer committed into mid-walk (the walk now repeats until
a pass adds no pages), and the find-then-write procedures acting on a
lookup that could race a writer (they now hold one exclusive guard for
their whole body). The third was the engine's, and it is the interesting
one: **a stage does not always still belong to the transaction that comes
back to flip it**. A SERIALIZABLE claim stamps SHARED row locks as it
scans; a concurrent save's delete checks only for EXCLUSIVE conflicts, so
it stages its delete over the claim's stamp; the claim then loses its
serialization race, and its partial rollback "restored" the row — erasing
the save's staged delete, so the save's commit found nothing of its own to
flip and the row came back from the dead. Twelve workers then bounced their
saves between a machine and its twin forever. The fix is an ownership rule
in both engines' `commit_pointer` and `rollback_pointer`: a control block
whose `transaction_id` is not the caller's is no longer the caller's
business and is left exactly as found (startup recovery, whose job is
precisely other transactions' recorded intentions, stands outside the
rule). Traced by instrumenting every claim, save and drop with its thread
and the row's control block, and replaying the ledger: one row deleted
twice, then found pristine and alive. Measured after: **40 runs under the
flag, zero stalls, exact answer sets every time**, and the C++ suite —
whose commit and rollback walk through the same guard — stays green. With
the stall dead and 55 post-fix runs green without one, **the shared side is
now the default** for an embedded store; `COCOLOG_PARALLEL_READS=0` keeps
the exclusive guard, so one env var still separates the two modes in any
future bisect. The C++ server has since taken the same design — the story
continues below, after the turn became one transaction.

### A dead transaction's lock breaks on contact

The ownership guard exposed a debt the engine had always carried: a
transaction that dies without commit or rollback — a crashed client, a
pooled connection abandoned mid-turn — leaves its staged row locks on disk,
and nothing sweeps them until the next restart's recovery. Measured, in the
server: one turn killed mid-save left `state-c` wedged behind a stale lock,
`start` refused with `lock wait timeout`, and every following `groups` run
failed the same way until the server was restarted. Before the guard that
debris was sometimes scrubbed by accident, by exactly the promiscuous
rollback the guard exists to forbid; with the accident gone, the sweep had
to become deliberate.

It is now lazy recovery, in both engines. A transaction id names one
transaction (the C++ engine's id was per-THREAD — every transaction a
pooled connection ever ran shared it, so "is the owner still running" had
no answer; the Cicili engine's was hashed from the thread and the wall
second, so two begins in one second collided), and a process-wide registry
holds the ids currently between begin and end — taken at a fresh begin,
released only after commit or rollback has cleared every lock. A begin on
a thread whose transaction is still open CONTINUES it, id and registration
standing: the server begins once per request while a turn's transaction
spans many, and the first cut of this work handed those nested begins
fresh ids — orphaning every stage the turn had already made, which the
commit's ownership guard then skipped, and a fresh store grew ghost
machine rows and torn index chains within a handful of runs (387 unique-key
refusals in one afternoon; 7 after the fix). What makes an id dead is
death: commit and rollback retire it, a dying thread's destructor retires
it after its best-effort rollback, and a crashed process's ids are simply
unknown to the next process's registry. When `check_lock` meets a lock
whose owner is not in the registry, it no longer waits on the corpse: it
rolls that one pointer back in place — the same foreign-id work startup
recovery does, done on contact — and looks at the row again. A live owner,
however slow, is never touched: its id is in the registry until its locks
are already gone.

Proven at the engine seam in both engines: the C++ suite gained
`a_dead_transactions_lock_breaks_on_contact` (stage, abandon, second writer
through in milliseconds instead of a ten-second refusal, committed data
intact, the abandoned stage never landing) and the standalone Cicili
harness the same case; 304 C++ cases and the full cocolog suite stay green.
The stale expectation this flushed out of the standalone harness — a
truncate count written before superseded UPDATED versions became
reclaimable — was corrected to match the documented behaviour.

Settling that debris surfaced one more engine debt. The C++ index's
truncate walks every value chain to unlink the settled dead, and a link
whose address never finished landing — a stage cut off mid-write, exactly
the kind of record the breaker now settles — read back NULL and refused
the WHOLE pass with `NULL value`: one torn link in a machine-state chain
made every `cocolog vacuum` fail on that store forever, with a fresh data
directory the only cure. A NULL address in a chain now ends the chain
exactly as `-1` does — nothing lies beyond a link that never landed — and
the store that was refusing every vacuum healed in place, no restart, no
new data directory. (The Cicili engine never had the debt: its truncate
rebuilds each index wholesale instead of editing chains.)

The last residue — about one run in three losing a group to a
`unique key 'IDX_COCOLOG_MACHINES_NAME'` refusal — was then hunted to
ground with ledgers at three depths (ZiguratIP 1c2c86f). The refusals
were CORRECT verdicts on a ghost: an alive committed index entry whose
machines row was gone. The ghost was born when the breaker rolled back a
LIVE transaction's staged index entry — and the registry was right too,
because the stage had been made AFTER its transaction's commit: the
server's layer commits between statements without always beginning before
the next one, so the next statement's stages arrived under the retired id,
alive by every intention and dead by the registry. The fix is the oldest
idea in autocommit engines, applied at the engine's own seam: **a stage
that arrives with no transaction open opens one** — the push, the three
control writers and the SERIALIZABLE read stamp lazily begin, which the
begin-continues rule makes idempotent. Measured after, twelve-worker wire
choreography, fresh store: **15/15 runs green at 6–8 seconds flat, zero
breaker fires, zero unique-key refusals, zero lost unmaps, and the full
cocolog suite `red: 0`** — wall-to-wall at last.

The begin-continues rule then claimed one victim of its own: the EMBEDDED
choreography went twelve reds in twelve runs while the wire ran green on
the same engine. The embed-side ledgers named it (ZiguratIP 5af6c36): only
the READ-ONLY commit path nulled the transaction record pointer, so after
a writing commit the next begin CONTINUED a committed-out transaction —
its stages carried the retired id and the breaker ate live machine saves.
The wire never showed it because the request layer's rollback hygiene
nulls the pointer between requests; the embedded arrangement speaks to the
engine bare. A writing commit now spends its pointer exactly as the
read-only path always has, and both arrangements are green on one engine:
embedded 12/12 at 1–2 seconds (parallel default) and 4/4 at 5 seconds
(exclusive), wire 6/6 at 6–8 seconds with zero engine errors, vacuum and
torch green in both arrangements, the full suite `red: 0`, 304 C++ cases
and the standalone Cicili harness green.

### A turn is one transaction, in both arrangements

The turn used to be two: the claim committed ahead of the work "so it would
stand before the machine was touched", and that standing claim was the
stranded-machine hazard in person — a worker killed mid-turn left the
machine marked as its own forever, `drop` would not clear it, and CLAUDE.md
taught the manual recovery. The claim now RIDES the turn's single
transaction: the turn-final commit is what makes it stand, a turn that
fails in-band is rolled back explicitly, and a worker that dies takes its
claim down with the server's rollback of the broken connection — the
machine goes straight back to the pool. Proven directly: a worker
SIGKILLed mid-run leaves its machine `suspended`, not stranded. The
`release` hand-back function is gone with the hazard it existed for.

What made this affordable is the isolation hand-back: the claim procedures
(and the embedded claim) drop from SERIALIZABLE to READ COMMITTED after
their update, inside the still-open transaction — the stamps stay staged
until the turn commits, but the slot-of-one goes to the next claimant
after the claim's few statements instead of being held for a whole turn.
Measured with the turn as one transaction, and then benchmarked again on
AGED stores to prove the numbers hold: embedded 12/12 green at **2–3
seconds flat** on a store thirty-plus runs deep, wire 12/12 green at **5–6
seconds flat** on a store eighteen runs deep, zero engine errors across all
of it, vacuum and torch green in both arrangements. And the halved commit
count collapsed the guard-mode gap: **exclusive mode now runs the same
choreography at ~2 seconds too**, down from 4–5 — the old turn paid the
commit's three-syncs-of-two-files dance twice, once for the claim and once
for the work, and in exclusive mode those serialised syncs were most of
what a turn cost. The parallel default keeps its edge under heavier read
mixes; the exclusive fallback is simply no longer a 2–3× penalty here.

### The wire server runs parallel reads too

The C++ engine now carries the same shared-read architecture the Cicili
engine proved out, member for member: a writer-preferring read-write lock
behind `Streams`, the lock mode following the isolation level, per-thread
private read streams for eligible cursors, an exclusive release flushing
both canonical streams, the fixed-point page-list re-walk, and index
cursors staying exclusive — the same eligibility line the Cicili engine
drew. The port surfaced one lesson of its own: a thread's private streams
are opened against a store's files and can OUTLIVE that store — the test
suite hops stores, and the first shared-mode run failed 73 cases reading
the previous store's dead files through cached streams. A reader epoch
fixes it: opening reader paths stamps the store from a global counter, and
a thread whose streams predate the stamp reopens them before reading.

The server turns it on by default; `ZIGURATIP_PARALLEL_READS=0` keeps the
exclusive guard, mirroring the embedded flag. The C++ test fixture opens
reader paths too, so all 304 cases run against the shared shape — green,
five runs in a row. On the wire, twelve workers: 12/12 green at **5–6
seconds flat**, zero engine errors, the full cocolog suite `red: 0` with
every server case really running. The twelve-worker number matches the
exclusive server's — that choreography is commit-bound, not read-bound, so
the win here is queueing behaviour (readers no longer serialise behind one
stream pair) and one engine design in both languages, not a headline
seconds cut. One bring-up hazard worth recording: the first parallel
server heap-smashed at startup (`malloc(): invalid next size`) because the
binary had been built minutes BEFORE the header gained the reader-epoch
members while the library was built after — `Memory` allocated at the old
size, constructed at the new one. After ANY engine header change, rebuild
the library, the server binary, and the schema objects together.

The embedded side was re-benchmarked against the same engine state to
prove the port moved nothing it should not have: on the aged persistent
store, now thirty-plus runs deep, 12/12 green at **2–3 seconds** with the
parallel default and 4/4 at **2 seconds flat** exclusive — the converged
numbers exactly, no drift. The torch suite ran green against the same
engine state too — train, store, reload in a fresh process with identical
predictions, the conv net's batch-norm buffers back out of Zigurat intact.
So did the vacuum, in both arrangements against the parallel server: the
verb reclaims, a second pass finds nothing more, the gate refuses without
`--vacuum`, and live clauses survive — the reclaim machinery running under
the new shared-read guard, with zero engine errors in the server log.
And the cross-process case — one process writing through the wire, a
second that consulted nothing reading it back, the claim the project
exists to make — reconfirmed green against the same server instance,
which by then had absorbed the twelve-worker benchmark, the vacuum and
the full suite without one engine error. The ruler — one writer growing
the program clause by clause under eight concurrent queriers, the very
mix the shared guard exists for — ran green on it too: readers
demonstrably read WHILE the writer wrote (a querier's answer count grew
from 0 to 37 across its own run), nobody answered outside the program,
and the finished program proved the full closure. Every server-dependent
case has now run standalone against the parallel server: groups, vacuum,
shared, ruler, and zigurat — the backend case that pushes frozen machine
state through the wire in its 4000-byte chunks — all green, one server
instance, zero engine errors. The pure C client's probe ran against the
same instance too, 20 checks green: protocol framing and its refusals
(the String and Text limits refused cleanly, connection still in step),
the transaction lifecycle, ordered clause reads, machine state in chunks
and back in seq order, the Zeytun page serving the same clauses over
HTTP, and escapable characters surviving the full round trip. (The state and files cases are green too,
but they are local ones — state freezes and thaws in-process, files runs
cocolog and SWI side by side and diffs their answers line for line, and
neither has a server in the loop; that is exactly why state reads GREEN,
not SKIP, on a serverless run, and why files' SKIP condition is "no
swipl", not "no server".)
That closes the loop: one shared-read design, both engines, both
arrangements, benchmarked green on aged stores at wire 5–6s and embedded
2–3s, with the heaviest module the store carries confirmed on top.

### A torn chain link ends the walk instead of wedging the server

Found by a routine groups run after the AI e2e test: the setup vacuum
froze the whole parallel server — 80% CPU, log stopped at
`cocolog::vacuum`, every new connection refused. GDB showed the vacuum
thread spinning in the machines-id index's dead-value walk with
`address = 0` on every sample, and the preserved store told the rest:
a value's `next_address` was ZERO, address 0's data was all zeros, and
address 0's hexmap chunk was FREE — never allocated. The walks had
learned (STATUS above) that NULL and -1 end a chain, but 0 is a "valid"
address, so the walk chased it into free space, where `_pointer` scanned
the whole hexmap per call, forever — and because the vacuum holds the
streams guard exclusive, every other thread queued behind the spin. A
torn in-place chain edit is how such a link lands, the same family as
the NULL link before it, and a torn link can equally point BACK into its
own chain, which no free-space check can see.

The rules now, in both engines: `_pointer` refuses a chunk without the
DATA bit instead of walking free space; every chain walk asks whether a
link resolves to an allocated record before following it, and an
unresolvable or REVISITED address ends the chain exactly as NULL and -1
do (a visited set in C++, Brent's cycle check in Cicili; the free walk
is additionally self-limiting, because freeing marks chunks free and a
link that comes around again stops resolving before it can double-free).
The SELECT-path walk — every index read, not just the vacuum — got the
same guards and the NULL normalization it had never had. Proven by a
C++ case that forges both shapes into a real chain through the store's
own stream: a self-loop answers one row and ends, an unresolvable link
answers the rows before it and ends, reclaim over the torn chain
completes — and against the unfixed engine the same case hangs forever,
the wedge reproduced in miniature. Validated after: C++ suite 305/305 in
shared mode, Cicili harness green, embedded groups 2s on the aged store,
wire groups 6/6 at 5–6s on a parallel server, suite `red: 0`, zero
engine errors. And benchmarked, because the guards sit on the hottest
read path in the engine — every index SELECT's value walk now asks
whether each link resolves and remembers where it has been: the
twelve-worker wire choreography ran 12/12 green at **5–7 seconds,
effectively 6s flat**, on a store eighteen runs deep — the established
band, unmoved. The embedded arrangement holds its band the same way:
27 of 28 runs green at **2–3 seconds flat** on the aged store, parallel
default and exclusive alike. The one red exited through a worker's
normal "nothing left to do" line with healthy claim counts and did not
recur in 23 straight runs after — the rare-flake territory the
Contention watch already covers, not a property of the guards. And the
vacuum itself — the walk that wedged — is confirmed from both ends: the
vacuum test green in both arrangements against the fixed parallel
server, all ten checks, and the groups setup vacuum, the exact path
that spun, green more than eighteen times over on the ageing store it
originally died on. Torch ran green on the guarded walks too — its model
chunks travel exactly the multi-value chains the walks now guard, and
train, store, fresh-process reload with identical predictions, and the
conv net's buffers all came back intact in 3 seconds. And the
cross-process case — one process writing through the wire, a second that
consulted nothing reading it back — is green on the guarded SELECT walk
too, which is the read path every one of that second process's queries
takes. So are state and zigurat: state locally (freeze and thaw have no
server in the loop), and zigurat against the fixed server — the case
that matters here, because machine state travels in 4000-byte chunks
that land as exactly the multi-value chains the torn link corrupted.
With ruler green under eight concurrent readers as well, and the pure C
client's probe green through all twenty checks — its reads riding the
guarded SELECT walk, its machine-state chunks landing as the very chain
shape that tore, the Zeytun page serving the same clauses over HTTP —
every case the store has now runs green on the guarded walks. The
wedge-immunity came for free.

### The torn-link producer, hunted to one byte

The zero links had a maker, and it took eight instrumented reproduction
rounds to corner it: not a torn write, not a kill catching a flush, not
a poisoned stream — every one of those was hypothesized, instrumented,
and ruled out by a run that refused to show it. What the ledger finally
proved, with a preserved store and a byte-watcher bracketing every step,
was this: the corruption appeared at STARTUP, deterministically at the
eleventh run's restart, and the startup page walk was the producer. That
walk asked `_pointer` whether each address held a record, and `_pointer`
seeks past the control chunks before measuring — right for a record, and
a read STRAIGHT THROUGH a short free run into the record behind it. A
one-chunk free run parsed as a 64-byte "record", the walk went one phase
out of step, read data codes as control bytes, mistook a live index
node's standalone code for an online lock, and rolled back live rows as
uncommitted debris. The next restart read the scribbled region as
reclaimable, the page went back to the allocator, and the recycle
zero-filled a node the tree still linked — the zero link of both
preserved specimens, born whenever the store's churn laid down a short
free run in the walk's path. The engine's own comment KNEW free runs
read through — the free branch measured them from the hexmap for exactly
that reason — but the record-or-free decision gating the two branches
came out of the same misparsing call. The fix is one byte read first: a
record's first chunk is a control chunk and always carries the high bit,
a free chunk never does.

The hunt hardened everything it touched on the way through, in both
engines: offline inserts now land data and control under one flush
BEFORE the hexmap marking goes durable, so a death mid-insert leaves
unmarked bytes instead of an allocated record of zeros; every canonical
write clears a poisoned stream first, as the read accessors already did;
and a node reading degree 0 with a keys head of 0 — the torn shape no
real node writes — walks as empty. Proven end to end: startup on the
preserved store that lost its node at every eleventh-run restart now
keeps it byte for byte; fifteen kill-and-restart pressure cycles ran
30/30 groups runs green where cycle six used to fail every time; the
C++ suite 305/305, the Cicili harness green, the full suite `red: 0`
with zero engine errors, and groups-embed green on the aged store.

### The test that blocked all of it is fixed

`readers_do_not_queue_behind_staged_writes` — the suite's ~one-in-three
failure that made the first ceiling attempt unvalidatable — was a REAL
dirty read, and it is fixed at its source. `_rollback_pointer` flags a
never-committed row `DELETED` with `modify_time = now` but left
`create_time = 0`, and `_alive_at` only rejects future births when
`create_time` is set — so a reader whose statement began before a peer's
ROLLBACK read "died after my snapshot" on a row that was never alive. The
rollback now stamps the birth too (born and died at the same instant, so no
snapshot anywhere can see it), `_alive_at` refuses the old unstamped shape,
and the SNAPSHOT branches require a version to have been born by the
snapshot before "deleted after it" can mean "visible to it". Measured: the
suite failed 4 of 10 runs before the fix and 0 of 21 after, in both
engines. (A different, much rarer Contention flake — one failure in ten
runs, not reproduced in six retries — remains under watch.)

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
* **A directive is not run as a goal.** `coco_directive` handles `dynamic/1` and
  `op/3`, ignores `discontiguous/1`, `multifile/1`, `module/2`, `use_module/1,2`
  and `meta_predicate/1`, and accepts `set_prolog_flag(double_quotes, codes)`
  because that is what the reader actually does — any other value of that flag
  is refused rather than nodded at. Anything else in a consulted file is an
  error naming what it was. `:- initialization(main).` and
  `:- ( catch(...) -> ... ; ... ).` would want an engine, and the store is a
  layer below the engine — the file that would have to call into solve.cicili is
  compiled before it.
* **`format/2` has no column directives.** `~t`, `~|` and `~+` measure what has
  been written since the last column stop, which is a second pass over the
  buffer this does not make. They raise an error naming themselves rather than
  being quietly ignored — dropping them turns a table into a run-on line and
  blames the program.
* **`with_output_to/2` redirects file descriptor 1**, because cocolog writes to
  the literal `stdout` in some seventy places rather than to a stream it passes
  around. Its goal runs in a nested engine, so — like `findall/3` — it cannot be
  suspended.
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
* **The reader is lenient where SWI raises a syntax error.** `- \+ a` is an
  operator clash in SWI — `\+` is 900 and `-` admits an argument of at most
  200 — and this reader accepts it. Leniency is the safe direction: it accepts
  terms SWI rejects and misreads none of them. `dynamic foo` as an argument is
  the other way round: SWI accepts it and this reader wants brackets, because
  `dynamic` is 1150 and an argument is read at 999.
* **A list cell is `'.'`/2 and not SWI 7's `'[|]'`/2.** Deliberate: `.` is the
  traditional and ISO name. It shows in `X =.. L` on a list and nowhere else.
* **A module still cannot declare an operator from its C half**, though a
  program can with `op/3` and a module's Coco half can carry a `:- op(...)`.
  The remaining seam limits — no choice points, no per-session state — are the
  price of being suspendable and are not going to change.
* **No garbage collection.** The heap only grows within a solution; it is
  reclaimed on backtracking and on a new query. A long deterministic run that
  builds structure will grow until it ends.

## Not started

* A REPL. `cocolog query` runs one goal and exits.
* Strings as a type; `"abc"` reads as a code list, which is the ISO default.
* Any indexing on the first argument. A predicate's clauses are tried in order.
