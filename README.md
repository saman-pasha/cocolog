# cocolog

**A Prolog interpreter whose running state is data, so it can be suspended into
a database and finished by a different process.**

cocolog is written in [Cicili](https://github.com/saman-pasha/cicili) and keeps
its knowledge base in [ZiguratIP](https://github.com/saman-pasha/ziguratip).
It uses both and modifies neither.

```console
$ cocolog --kb demo forget                       # consult ADDS; it does not replace
forgot 0 clause(s) in 'demo'

$ cocolog --kb demo consult demo/family.pl
consulted 12 clause(s) into 'demo'

$ cocolog --kb demo start job "ancestor(tom,X)"
started 'job'

$ cocolog --kb demo --steps 12 step job          # one process
  1. ancestor(tom,bob)
  2. ancestor(tom,liz)
job: suspended at 13 inference(s), 2 answer(s) this turn

$ cocolog --kb demo --steps 12 step job          # a different process
  1. ancestor(tom,ann)
  2. ancestor(tom,pat)
job: suspended at 26 inference(s), 2 answer(s) this turn
```

Between those two commands the machine was not in memory anywhere. It was three
hundred bytes of ASCII in a table.

## The one decision everything follows from

A term is an **index into a flat array of 64-bit cells**, not a pointer into a
graph, and the resolution engine **never recurses in C**: the continuation is a
term on the heap and the choice points are an array of integers.

Written the natural way — malloc'd term nodes, a recursive `solve()` that uses
the C stack as its continuation — an interpreter is half the length. But its
state is then pointers and stack frames, and neither is data. cocolog exists to
stop mid-proof and go into a database, so:

| | |
|---|---|
| terms are indices | an array of indices is position independent: write it out, read it back at a different address, and every reference still means what it meant |
| the continuation is a term | `'$k'(Goal, Barrier, Rest)` on the heap, so a pending goal is a cell like any other |
| a cut barrier travels per goal | a suspended machine has to remember the barrier of *every* pending goal, not just the current one |
| choice points are integer frames | `{kind, goals, trail_mark, heap_mark, call, pred, clause_ix, barrier}` and nothing else |

`lib/state.cicili` is what that buys: freezing a machine is printing six arrays
and thawing one is reading them back. There is no graph walker, no pointer
fixup and no stack to reconstruct — and there could not be one, because a C
stack is not something you can write to a table.

## Layout

```
lib/term.cicili        cells, the machine, interning, unification with a
                       trail, copying, and a compile-time term DSL
lib/syntax.cicili      the operator table, the reader and the writer
lib/kb.cicili          the clause store, and the hook a backend fills in
lib/solve.cicili       the engine: continuation, choice stack, cut, negation,
                       if-then-else, and the builtins
lib/state.cicili       freeze and thaw
lib/zigurat-kb.cicili  the knowledge base over Zigurat's binary protocol
lib/zeytun-kb.cicili   the same, over Zeytun's HTTP pages (read only)
lib/zigurat.cicili     Cicili declarations for the C client, and a front end
lib/zeytun.cicili      the same for the page client

client/                the two protocols, in C. No C++, no ZiguratIP headers:
                       libc and the sockets API and nothing else
parsi/                 the schema and the pages, compiled into a ZiguratIP
                       home by ZiguratIP's own parsi compiler
cocolog.cicili         the program
test/                  the suite; groups.sh and ruler.sh are the concurrent
                       ones, and are crowds of processes rather than .cicili
demo/family.pl         something to run it on
```

## Building

```sh
export CICILI=/path/to/cicili                 # a Cicili checkout, for sbcl
export ZIGURATIP_HOME=/path/to/ZiguratIP/home # a built ZiguratIP home
make            # the C client and the cocolog program
make schema     # compile the Parsi objects into $ZIGURATIP_HOME
make test       # the suite; the database tests skip without a server
```

Cicili is needed only to build: `sbcl` runs `cicili.lisp` over the `.cicili`
files and out comes C. ZiguratIP is needed to run — a server to talk to — and
once, at setup, for its `parsi` compiler.

## The knowledge base is a seam, not a dependency

`lib/kb.cicili` gives the clause store two function pointers: `fetch`, called at
most once per predicate, and `on_assert`. Everything above them is written
against the store and knows nothing about where clauses come from.

That is three arrangements from one interpreter:

* **local** — no hooks. Everything in memory.
* **Zigurat** — `lib/zigurat-kb.cicili`. Clauses are fetched from a table as
  the proof reaches them, and asserting writes through. Machines suspend and
  resume here.
* **Zeytun** — `lib/zeytun-kb.cicili`. The same reads over HTTP, for an
  interpreter that cannot open a socket to the binary port.

The HTTP backend deliberately does not write. One HTTP request is one
transaction; a machine is a header row plus a row per chunk, and over HTTP
those would be separate transactions with no way to roll the first back when
the third failed.

## What is stored, and how

**Clauses are text** — the canonical written form, which the reader reads back.
The writer and the reader are tested against each other, so the round trip
loses nothing, and text buys three things a binary encoding would not: a person
can read the table, a Parsi procedure can search it, and the schema is not tied
to the cell layout. Change a tag in the interpreter and every clause already in
the database still loads.

**Machine state is an opaque blob**, in chunks of 4000 bytes. A `Text` is
documented at 65535 and the wire agrees, but a row has to fit in a page: with
the default 8192-byte page a `Text` of 8000 stores and one of 8192 comes back
`allocation overflow`. Measured, not guessed.

**Thawing is two steps, in order**: thaw the machine, which rebuilds the atom
table exactly as it was, *then* load the knowledge base, whose clauses intern
against that table. The other order leaves the store's cells referring to atom
ids the thawed heap does not agree with.

## Cicili, used as a Lisp

The interpreter is not C in parentheses. The macro layer does the work a
handwritten interpreter would repeat:

* **The cell tags are one table.** `*cell-tags*` in `lib/term.cicili` emits the
  C enum, the constructors and the testers, and because the macros know the
  numbers at expansion time `(co-tag-is REF c)` folds to a comparison against a
  literal.
* **The operator table is read by both halves of the grammar.** One
  `*operators*` list emits the reader's lookups and the writer's, so they cannot
  disagree about an operator.
* **The lexer is written in characters and compiles to numbers.** Cicili has no
  character literal, so `(co-ch-between c "a" "z")` becomes `c >= 97 && c <= 122`
  at expansion time and the reader stays readable.
* **Builtins are a table.** `*builtins*` emits the dispatcher grouped by arity,
  so a goal of arity 3 is never compared against a builtin of arity 1 and the
  dispatcher cannot fall out of step with the table.
* **Terms can be written as terms.** `(co-term m (append (splice xs) (cons 1 nil) ?Rest))`
  expands to the heap construction, reservations and fixups — the dance every
  hand-written term repeats, written once.

## Two things about Cicili worth knowing before writing any

**A string literal is raw.** It reaches C untouched, which is why `"\n"` is two
characters in the source and a newline only after the C compiler sees it.

**A string may not end in a backslash.** The reader decides where a literal
stops by asking whether the previous character was one, so the closing quote of
`"/\\"` is read as escaped, the reader runs on into the rest of the file, and
every string after it is read as code. The failure surfaces hundreds of lines
later as `Package +-*/\^<>=~ does not exist`.

## Twelve interpreters, four states

```console
$ sh test/groups.sh
twelve interpreters, three per machine
starting four machines
ok   state-a produced its full answer set   ancestor(tom,ann) ... ancestor(tom,zoe)
ok   state-a answered nothing twice         0
...
     turns: a1=6 a2=4 a3=7
     turns: b1=4 b2=4 b3=4
     turns: c1=10 c2=10 c3=10
     turns: d1=11 d2=7 d3=12
ok   all three interpreters of group a took turns
ok   no machine left suspended              0
GREEN: 0 failure(s)
```

Twelve `cocolog work` processes against one server, three per machine. Each
machine produces its full answer set exactly once however many workers produced
it, and every member of every group does some of the work.

`test/ruler.sh` is the other half of the claim: one interpreter asserting a
program clause by clause while eight others query the same knowledge base, and
none of them may ever answer something the finished program cannot prove.

**One decision does most of the work, and it is about isolation.**

`cocolog::machine_claim_named` is a read followed by a write of the row it read
— find an idle machine, then mark it as one worker's — and it is the only thing
in cocolog that runs `SERIALIZABLE`. At `READ COMMITTED` two workers arriving
together both see `suspended`, both take it, and both advance the same state from
the same point; the answers come out twice. ZiguratIP's `SERIALIZABLE` excludes
only other `SERIALIZABLE` transactions, so twelve claims queue for microseconds
each while the work that matters — loading a machine, proving, saving it — goes
on at `READ COMMITTED` all at once. A short critical section at the strongest
level and everything else at the weakest that is still correct.

The rest is in [STATUS.md](STATUS.md): why an empty claim means two different
things, why "the machine is gone" is not proof the first time you see it, and
what had to be fixed in ZiguratIP before any of this held.

## Status

The interpreter, the serialisation, both transports, the schema and the
concurrent arrangements are done and tested; `make test` ends `red: 0`.
See [STATUS.md](STATUS.md) for what is finished, what it cost to get there, and
what is known to be missing.

cocolog is a client and modifies neither of the projects it uses — but running
twelve of it at once turned up four faults in ZiguratIP, from unguarded B-tree
walks over the shared page store to a documented Parsi clause that had never
compiled. Those are fixed in ZiguratIP itself; its `doc/concurrency.md` is the
account.
