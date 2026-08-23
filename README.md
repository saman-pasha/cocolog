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
lib/module.cicili      the module seam: a bridge between C and Coco
lib/files.cicili       SWI's Files library, as a module
lib/lists.cicili       SWI's Lists library, as a module
lib/apply.cicili       SWI's Apply library -- clauses only, no C at all
lib/builtins.cicili    the ISO core builtins cocolog was missing, plus
                       format/1,2,3, code_type/2 and must_be/2
lib/dcg.cicili         definite clause grammars: the --> translation, and
                       phrase/2,3
lib/vendor/swipl/      SWI's dcg/basics and dcg/high_order, copied
                       unmodified under their own BSD-2 headers
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
test/files/            Prolog programs run by BOTH swipl and cocolog, with
                       their output compared line for line
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

`lib/kb.cicili` gives the clause store five function pointers. Everything above
them is written against the store and knows nothing about where clauses come
from.

| hook | when | what it is for |
|---|---|---|
| `fetch` | at most once per predicate, when something calls it | clauses arrive as the proof reaches them |
| `on_assert` | a clause was added | write it through |
| `on_retract` | a clause was removed | write that through too |
| `on_dynamic` | a predicate was declared `dynamic` | a declaration is about the knowledge base, so it has to outlive the process |
| `warm` | `listing` | name every predicate the knowledge base holds, without fetching any clauses |

`on_assert` and `on_retract` both rewrite the WHOLE predicate. Clauses are
stored by ordinal, and `asserta` puts one at the front — which changes the
ordinal of every clause after it — so writing back only what changed would
leave two clauses both claiming to be first. O(n) per assert, and always right.

`warm` exists because the laziness that makes a shared knowledge base
affordable also means a fresh interpreter knows of no predicate it has not
already reached: `listing` asking what there is would answer "nothing", which
is true of the store and false of the knowledge base. It interns names and
declarations only — what the clauses ARE is still nobody's business until
somebody calls one.

That is three arrangements from one interpreter:

* **local** — no hooks. Everything in memory.
* **Zigurat** — `lib/zigurat-kb.cicili`. All five. Machines suspend and resume
  here.
* **Zeytun** — `lib/zeytun-kb.cicili`. `fetch` and `warm`, over HTTP, for an
  interpreter that cannot open a socket to the binary port.

The HTTP backend deliberately does not write. One HTTP request is one
transaction; a machine is a header row plus a row per chunk, and over HTTP
those would be separate transactions with no way to roll the first back when
the third failed. Reading is another matter, so `listing` over HTTP shows
exactly what `listing` over the binary protocol shows.

## Modules: a bridge between C and Coco

A module carries predicates written in Cicili and clauses written in Prolog, and
a program cannot tell which half a predicate came from. `lib/solve.cicili` holds
two null function pointers and consults them; `lib/module.cicili` fills them in.
A cocolog built without a single module is the cocolog that existed before
modules, because the hooks stay null.

A goal is tried as a control construct, then a core builtin, then a module
predicate, then the knowledge base — so a module can add to the language but
cannot redefine `is` underneath a program, and is not shadowed by a clause
somebody asserted.

Five libraries ship, and they are deliberately spread across the range.
**Files** is seventeen predicates in C and five in Prolog, because a file
system is a syscall away. **Lists** is thirty-odd in Prolog and seven in C,
because `member/2` and `permutation/2` must answer *many times* and a module's
C half cannot — it has no access to the choice stack, so a nondeterministic
predicate belongs in the Coco half where the engine provides the choice points
and a frozen machine can be thawed elsewhere and go on backtracking through it.
**Apply** has no C half at all. **Builtins** is the ISO core cocolog was
missing — `findall/3` and its family, `between/3`, the atom and term
predicates, `clause/2`, `current_predicate/1`, `format/1,2,3` and
`code_type/2`. **DCG** is one C predicate and three clauses.

Every one of them is checked by running the same Prolog program under `swipl`
and under `cocolog` and comparing the output byte for byte — the only kind of
compatibility claim that cannot be fooled by its author. It has caught five
things that would otherwise have shipped looking right.

**MODULES.md** is how to write one.

## Grammars, and code borrowed rather than written

`-->` works, and so does everything built on it. The translation lives in
`lib/dcg.cicili` and runs inside `coco_assert` — the one function every clause
passes through — so a grammar rule means the same thing consulted from a file,
asserted by a running program, or arriving from the database.

It is **written, not copied**. SWI's own `boot/dcg.pl` is half source-position
terms and module qualification, machinery for a module system cocolog does not
have; what is left once both are removed is short enough to write, and writing
it keeps third-party code out of the core.

Two of SWI's libraries **are** copied, byte for byte, under their own BSD-2
headers: `library(dcg/basics)` and `library(dcg/high_order)`, in
`lib/vendor/swipl/`. Nothing in them is edited. Instead the things they needed
were built here — the soft cut `*->`, `code_type/2`, `must_be/2`,
`format/1,2,3` with its `codes(H,T)` sink, `with_output_to/2`,
`ord_intersection/3` and `ord_subtract/3`, and acceptance of the `:- module`
and `:- use_module` lines a library file starts with. `test/files/run.sh`
consults those very bytes into cocolog and runs the same test file under SWI,
and the two agree exactly.

```sh
cocolog --local run lib/vendor/swipl/dcg_basics.pl my_grammar.pl main
```

cocolog has one namespace, so `:- module/2`'s export list is ignored and a
vendored file's private predicates are callable. That is a real difference, not
a shim; `lib/vendor/swipl/README.md` records it along with the provenance and
checksums of both copies.

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
  numbers at expansion time `(coco-tag-is REF c)` folds to a comparison against a
  literal.
* **The operator table is read by both halves of the grammar.** One
  `*operators*` list emits the reader's lookups and the writer's, so they cannot
  disagree about an operator.
* **The lexer is written in characters and compiles to numbers.** Cicili has no
  character literal, so `(coco-ch-between c "a" "z")` becomes `c >= 97 && c <= 122`
  at expansion time and the reader stays readable.
* **Builtins are a table.** `*builtins*` emits the dispatcher grouped by arity,
  so a goal of arity 3 is never compared against a builtin of arity 1 and the
  dispatcher cannot fall out of step with the table.
* **Terms can be written as terms.** `(coco-term m (append (splice xs) (cons 1 nil) ?Rest))`
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

## The same twelve, embedded

The knowledge base is a seam, and `embed/` is a third thing plugged into it:
the same eighteen `cocolog::*` procedures the server offers, implemented
in-process over the **Cicili MVCCS engine** (`ZiguratIP/MVCCS-cicili/`) and
the very `.cicili` table definitions the Parsi compiler generated beside its
C++ pair. `make embed` builds `cocolog-embed`; `--store DIR` then opens the
store inside the process — no server, no socket — and every command works
unchanged, because the C client dispatches each verb to the embedded engine
behind the same `zg_conn` handle. The hooks are weak symbols, so the plain
`cocolog` binary still builds with nothing but libc, as always.

An embedded store belongs to one process, so the group test's concurrency
moves inside it: `cocolog swarm A1 M1 A2 M2 ...` runs each worker as a thread
with its own session (the engine keeps transactions thread-local, and the
`SERIALIZABLE` claim is the same gate of one the server uses), and
`test/groups-embed.sh` runs the identical twelve-worker choreography and
checks. What the two arrangements measure, three runs each, same machine:

|                       | run 1 | run 2 | run 3 |
|-----------------------|-------|-------|-------|
| wire, fresh server    | 11.5s | 19.0s | 24.8s |
| embedded, fresh store | 14.7s | 14.5s | 14.5s |

Both are green throughout. The embedded times are flat because the store is
new each run; the wire times grow because the server's store keeps the dead
rows of every earlier run until a vacuum. The wall clock in both is mostly
the choreography itself — polls and deliberate yields between turns — not
the engine: the test exists to prove hand-off, and proving hand-off is
waiting, either side of a socket or not.

## Prolog that trains

The last seam to be filled: [torch/](torch/README.md) puts libtorch
behind the module system, so a Prolog program can load a dataset the
Files module vouched for, train a network on it, and `model_save` the
result — an assert of the model *as terms*, which the knowledge base
persists like any other fact. `make torch` builds it; `make full` pairs
it with the embedded store, and `test/torch.sh` runs the whole story:
train, store in Zigurat, reload in a fresh process, predict
identically.

## Status

The interpreter, the serialisation, both transports, the schema and the
concurrent arrangements are done and tested; `make test` ends `red: 0`.
See [STATUS.md](STATUS.md) for what is finished, what it cost to get there, and
what is known to be missing.

**The store grows and nothing reclaims it.** A deleted row is kept under MVCC so
that a transaction entitled to an earlier view can still read it, and there is no
vacuum. Saving a machine rewrites its row, so a proof of thirty turns leaves
twenty-nine dead ones. Nothing breaks; everything gets slower, because every read
walks past all of it — twelve interpreters over four machines went from 14s to
32s over five identical runs while the file grew 72KB. `TRUNCATE` is ZiguratIP's
vacuum, but it cannot be used here: see STATUS.md.

cocolog is a client and modifies neither of the projects it uses — but running
twelve of it at once turned up four faults in ZiguratIP, from unguarded B-tree
walks over the shared page store to a documented Parsi clause that had never
compiled. Those are fixed in ZiguratIP itself; its `doc/concurrency.md` is the
account.
