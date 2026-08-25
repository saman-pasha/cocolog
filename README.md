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
emacs/                 cocolog-mode: a Prolog major mode with colours for
                       variables and execution graphs drawn under the rules,
                       its engine held to this interpreter
colab/                 train on a Colab GPU, query from anywhere: the
                       notebook, and COLAB.md for the arrangement it runs
```

## Installing

What the build needs on the machine:

* **SBCL** — Cicili is Lisp that emits C, and `sbcl` runs it. Needed only to
  build.
* **A C and a C++ compiler and GNU make** — `gcc`/`g++` or equivalents. The
  interpreter is C; the embedded engine and the torch module are C++.
* **libtorch** — either `$LIBTORCH` pointing at the directory that HOLDS
  `include/` and `lib/` (for headers under `/usr/local/include/torch/...`
  and dylibs under `/usr/local/lib`, that is `LIBTORCH=/usr/local` — not
  `/usr/local/lib`), or the pip `torch` package (`pip install torch`),
  which is where everything looks by default. A standalone or installed
  libtorch also wants `TORCH_LIB=$LIBTORCH/lib` exported for the
  Makefile's link line.
* **SWI-Prolog** — optional; only the `files` test case compares against it,
  and it SKIPs when `swipl` is absent.

Three checkouts, side by side:

```sh
git clone https://github.com/saman-pasha/cicili
git clone https://github.com/saman-pasha/ziguratip ZiguratIP
git clone https://github.com/saman-pasha/cocolog
```

**Set these three, and put them in your shell profile** (`~/.zshrc` or
`~/.bashrc`) — every build and every test shell needs all of them, and a
shell without them fails with `set CICILI to a Cicili checkout` or, worse,
builds against the wrong tree:

```sh
# Coco requisites
export CICILI="$HOME/Projects/GitHub/cicili"        # the Cicili checkout, for sbcl
export ZIGURATIP="$HOME/Projects/GitHub/ZiguratIP"  # the BUILT ZiguratIP checkout
export ZIGURATIP_HOME="$ZIGURATIP/home"             # and its home

# macOS, libtorch via Homebrew: headers land in /usr/local/include and
# dylibs in /usr/local/lib, so the root that holds both is /usr/local
export LIBTORCH="/usr/local"
export TORCH_LIB="/usr/local/lib"                   # the Makefile's link line
```

(On Linux with the pip `torch` package, the last two are not needed —
everything asks Python where the package lives.)

Build ZiguratIP first — plain `make` in its checkout; a C++11 compiler is all
it asks — which fills `ZiguratIP/home` with its libraries, its `parsi`
compiler and the server binary. Then:

```sh
cd cocolog
make            # the C client and the ONE cocolog binary
make schema     # compile the Parsi objects into $ZIGURATIP_HOME
make test       # the suite; the database tests skip without a server
```

And it runs — the first three need nothing else on the machine at all:

```sh
./cocolog                                     # the toplevel: ?- awaits
./cocolog query "X is 2 + 2"                  # local: memory, the default
./cocolog --embed run tutorials/07-xor.pl train   # the store at ./KB
cd $ZIGURATIP && ZIGURATIP_HOME=$PWD/home \
  LD_LIBRARY_PATH=$PWD/home/lib ./home/bin/ziguratip &   # the server
./cocolog --kb demo consult demo/family.pl    # naming a kb chooses it
```

Bare `cocolog` is what bare `swipl` is — a toplevel. Line editing is built
in — the emacs keys, the arrows, and a history walked with `C-p` that
survives in `~/.cocolog_history` — written into the binary rather than
linked, GNU readline's license not being this project's. `?- ` reads a goal to
its full stop, over as many lines as it takes; answers come back under the
query's own variable names, in SWI's shapes down to the aliases (`X = f(Z),
Y = Z.` answers `X = f(Y), Z = Y.`, held to a live SWI); `;` asks for
another solution, and the punctuation is honest — an answer that left no
choice point ends `.` with nobody asked. `[family].` consults `family.pl`,
what one goal asserts the next goal sees, `halt.` leaves. It runs in any of
the four arrangements: against a store or the server, every finished goal is
one committed transaction, so a toplevel session is also the quickest way to
poke at a knowledge base other processes are working.

There is one `cocolog` binary and it is the full one: the interpreter, the
embedded MVCCS engine and the torch module, all in it. Which knowledge base a
run uses is a runtime choice among four arrangements — `--local` (memory,
the default when no other arrangement is named),
the server (`--kb`/`--host`/`--port`), `--http` (Zeytun, read only), and
`--embed [DIR]` (the store inside the process; a bare
`--embed` opens `./KB`) — never a build. Cicili is needed only to build:
`sbcl` runs `cicili.lisp` over the `.cicili` files and out comes C. The
embedded engine links against the built ZiguratIP's `Core` and `StreamIO`,
the torch module against libtorch, and a server is needed only when a run
chooses the server arrangement.

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

That is four arrangements from one interpreter:

* **local** — no hooks. Everything in memory. The default: naming `--kb`,
  `--host` or `--port` chooses the server instead.
* **Zigurat** — `lib/zigurat-kb.cicili`. All five, over the wire. Machines
  suspend and resume here.
* **embedded** — `--embed [DIR]` (a bare `--embed` opens `./KB`). The same
  five hooks — `lib/zigurat-kb.cicili` again, its wire swapped for
  `embed/embed.cicili`: the same eighteen procedures the server offers,
  in-process over the Cicili MVCCS engine. No server, no socket, and
  machines suspend and resume here exactly as they do over the wire.
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

**Model parameters are doubles**, in `cocolog::tensors` — a table of one
`Vector<Double>` field, each row's id columns saying which tensor it belongs
to and `seq` which piece, 512 doubles to a piece for the same
row-fits-in-a-page reason. `model_save`/`model_load` use it wherever the
arrangement can (the server; over HTTP the tensor page serves it back
**paged**, `from` and `limit`, the elements travelling as the IEEE bits of
the double so nothing rounds) and fall back to the older clause chunks
where it cannot — `--local` by nature, the embedded store until the Cicili
engine grows a vector column. The spec stays a clause either way, so
`torch_model(Name, _)` is still the question a poller asks.

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
C++ pair. It is in the one `cocolog` binary: `--embed [DIR]` (which
opens `./KB` when the directory is
left off) opens the store inside the process — no server, no
socket — and every command works unchanged, because the C client dispatches
each verb to the embedded engine behind the same `zg_conn` handle. The hooks
are weak symbols the interpreter carries either way; linking the engine in is
all that plugs it in.

An embedded store belongs to one process, so the group test's concurrency
moves inside it: `cocolog swarm A1 M1 A2 M2 ...` runs each worker as a thread
with its own session (the engine keeps transactions thread-local, and the
`SERIALIZABLE` claim is the same gate of one the server uses), and
`test/groups-embed.sh` runs the identical twelve-worker choreography and
checks. What the two arrangements measure, three runs each, same machine:

|                          | run 1 | run 2 | run 3 | run 4 | run 5 |
|--------------------------|-------|-------|-------|-------|-------|
| wire, fresh server       | 11.5s | 19.0s | 24.8s | —     | —     |
| embedded, fresh store    | 14.7s | 14.5s | 14.5s | —     | —     |
| wire, vacuuming in setup | 15.2s | 15.7s | 16.0s | 16.7s | 15.0s |

All green throughout. The first two rows are the measurement that forced the
vacuum's hand: the embedded times were flat because the store was new each
run, while the wire times grew because the server's store kept the dead rows
of every earlier run. The third row is the same wire test after `cocolog
vacuum` went into its setup — flat for as long as it is run, on the same
worked store the first row was ageing.

Then the same benchmark was pointed at a PERSISTENT embedded store
(`GROUPS_EMBED_STORE=DIR test/groups-embed.sh`), and what it found was not a
number but three storage engine bugs, shared by the C++ engine and the
Cicili port alike: a record sized at an exact chunk multiple measured one
chunk short everywhere it was read back (so its frees leaked and its holes
fit nothing), a fully-emptied page could never return to the allocator (the
whole-page test counted chunks a page can never surrender), and every
commit paid three syncs of two files even when it had written nothing —
which, for a choreography whose workers poll, was most of the wall clock.
All three are fixed in ZiguratIP, in `MVCCS/memory.cpp` and
`MVCCS-cicili/mvccs-lib.cicili` both, and the table after the fixes reads:

|                              | run 1 | run 2 | run 3 | run 4 | run 5 |
|------------------------------|-------|-------|-------|-------|-------|
| wire, vacuuming in setup     | 7.7s  | 7.9s  | 7.9s  | 7.9s  | 7.9s  |
| embedded, fresh store        | 8.7s  | —     | —     | —     | —     |
| embedded, persistent + vacuum| 9.7s  | 16.2s | 26.0s | 44.4s | 55.9s |

The wire halved and went perfectly flat — the server had been fsyncing
twice per client poll. The embedded fresh run dropped the same way. The
last row was, for a while, the honest open item: a persistent embedded
store stayed bounded but each run started slower than the last, walk-length
under the engine's one stream guard growing with the store's history. That
ager was then hunted through four more engine layers — the cursor read the
hexmap a byte at a time through a stream whose buffer every seek discarded;
`load_control` did nine reads where one block read serves; index storage
was swept when it should be **rebuilt** at truncate (four indexes held 72
of a vacuumed store's 168 pages, remembering every id they had ever seen);
and truncate reclaimed only settled DELETEs, never the superseded versions
an UPDATE leaves, so a machine claimed and released a thousand times left a
thousand old versions no vacuum would touch. With all of it fixed (the
ZiguratIP branch's "walk-length ager, solved" commit is the account):

|                              | run 1 | run 3 | run 5 | run 8 | run 10 |
|------------------------------|-------|-------|-------|-------|--------|
| embedded, persistent + vacuum| 5.1s  | 4.5s  | 4.8s  | 4.6s  | 4.6s   |

**Dead flat, and the store byte-identical at 912KB from run 1 to run 10.**
The persistent embedded arrangement is now the fastest way to run the
choreography — faster than the wire, faster than a fresh store every run —
because the vacuum in its setup now actually returns the store to the same
state every time. The one stream guard still serialises every reader
(STATUS.md's one-core section), but nothing behind it accumulates any
more: the guard protects work proportional to live data, not to history.
And a worker killed mid-write no longer bricks the store: the recovery
walk salvages a torn tail — what a kill catches in flight never reached
its commit sync, so by shadow paging's own rule it never happened — keeps
every parseable record, and refrees the rest.

## Prolog that trains

**Coco is a Prolog that trains.** Most languages bolt machine learning
on through a foreign library; Coco makes it part of the logic. A
network is a term you assert, training is a goal you call, and the
learned weights are facts — saved, queried, and reloaded through the
same knowledge base that holds your rules. The last seam to be filled:
[torch/](torch/README.md) puts libtorch behind the module system, so a
Prolog program can load a dataset the Files module vouched for, train a
network on it, and `model_save` the result — an assert of the model *as
terms*, which the knowledge base persists like any other fact.
It is in the one `cocolog` binary, paired with the embedded store,
and `test/torch.sh` runs the whole story: train, store in Zigurat,
reload in a fresh process, predict identically.

The classic AI/ML challenges pass, one `.pl` file at a time.
**[tutorials/](tutorials/README.md) holds twenty-four such programs**,
each a documented file carrying `train`, `test` and `predict` as
separate goals in separate processes — the store carries the model
between them: regression and classification, two-moons and spirals,
autoencoders and denoising, CNNs through a mini-LeNet, batch norm,
dropout, learning-rate schedules, LSTM sequence models with embeddings,
and fitted Q-iteration reinforcement learning. The whole suite runs
green, deterministically, in about seventy-five seconds. The one to
read first is
[22-embedding-lstm](tutorials/22-embedding-lstm.pl), the shape of every
text classifier at toy scale — token ids through a learned embedding
into an LSTM, trained to remember whether token 3 ever appeared:

```console
$ ./cocolog --embed /tmp/tut run tutorials/22-embedding-lstm.pl train
trained: final nll 0.0117
saved
$ ./cocolog --embed /tmp/tut run tutorials/22-embedding-lstm.pl predict
[0,1,2,3,4,5]  ->  contains token 3
[0,1,2,4,5,6]  ->  no token 3
[3,0,0,0,0,0]  ->  contains token 3
[7,7,7,7,7,7]  ->  no token 3
```

That third line is the point: the token sat at the very start and the
LSTM carried the fact across five further steps, in a model that was
trained by one process, stored as terms, and is answering in another.
And [24-q-learning](tutorials/24-q-learning.pl) closes the collection
with reinforcement learning — fitted Q-iteration on a gridworld, the
DQN idea built from nothing but `model_predict` for the Bellman targets
and `model_train` for the regression, whose greedy policy walks the
optimal six moves around the pit.

Underneath: a full torch surface — layers, losses, optimisers, metrics,
and device selection with honest CUDA refusal rather than silent
fallback — models persisted as Prolog terms via
`model_save`/`model_load`, and an MVCC storage engine (ZiguratIP) so
learned knowledge survives the process the same way asserted knowledge
does. Where a neural net stops — explaining, constraining, chaining
conclusions — the Prolog engine picks up, because they were never in
different systems to begin with.

And because a trained model is clauses, it travels the way clauses do.
[colab/COLAB.md](colab/COLAB.md) is that claim on free hardware: one
Colab session trains on its GPU into a knowledge base that Google Drive
keeps between sessions, a Cloudflare tunnel publishes Zeytun's
read-only view of it, and every other cocolog — another Colab, a
laptop's `?- ` prompt — does `model_load(xor, M), model_predict(M, ...)`
over `--http`, the weights arriving as terms and the prediction running
wherever the querier is. One writer, many readers, enforced by which
port is public; `test/tunnel.sh` rehearses the edge locally, port for
port and Host for Host.

## The tracer speaks SWI

`--trace` turns on a four-port tracer: `Call`, `Exit`, `Redo` and `Fail`
lines in SWI-Prolog's own format, on stderr, for every goal the engine
proves — and `trace/0` / `notrace/0` switch it from inside a program, as
they do there. It is held to SWI the way everything here is held to
something: `test/trace.sh` asks both tracers the same queries over the
same program and compares the port lines one for one, down to the
subtleties — a `Redo` re-entering a clause shows the call with its
bindings undone, taking the other arm of a `;` (or the else of an
`->`, or failing out of a `\+`) is a `Redo` of the call it sits in,
a deeper `Redo` reopens the calls it is nested in so their `Fail`
prints when the failure finally crosses them, and a call whose
remaining clause heads can never match is discarded in silence, which
is the quiet SWI's clause indexing buys. The engine's design pays for
itself here: the continuation is a term, so the `Exit` port is just a
marker the body proves its way through, and a frozen machine carries
its pending exits with it. **[TRACING.md](TRACING.md)** is the whole
story: turning it on, reading the ports, the subtleties, and how the
conformance is kept.

## The Emacs mode

[emacs/](emacs/README.md) holds **cocolog-mode**, a Prolog major mode
with two ideas of its own: a variable can be a *colour* instead of a
name — same colour, same variable, which is how Prolog scopes them
anyway — and a test case lives in a comment beside its rule, where
`C-c C-t` runs it and draws the whole execution graph underneath, every
clause tried, as comments that survive git and any other editor. The
mode carries its own Prolog engine in Emacs Lisp so all of that works
with nothing installed — and that engine is a deliberate shadow of this
interpreter, held to it twice over: offline, `make coco` in `emacs/`
asks both the same 234 queries and compares; live, every graph drawn on
a machine with a cocolog binary is certified against it on the spot,
with the four-port trace of the rule refreshing alongside. Pickers
insert the goals, the grammar pieces and the torch rules (`C-c C-i`,
`C-c C-g`), and `C-c C-e` [traces a goal](TRACING.md) under the real
interpreter in any of the four knowledge-base arrangements.

## Status

The interpreter, the serialisation, both transports, the schema and the
concurrent arrangements are done and tested; `make test` ends `red: 0`.
See [STATUS.md](STATUS.md) for what is finished, what it cost to get there, and
what is known to be missing.

## A worked store slows down. Truncate it.

This is the one piece of operating knowledge cocolog demands, and skipping it
costs a factor of five.

**The knowledge base grows with use, not with data.** A deleted row is kept
under MVCC so that a transaction entitled to an earlier view can still read
it, and nothing reclaims those versions on its own. The workload does not look
like deleting, which is why this is easy to miss: saving a machine rewrites
its row, so a proof of thirty turns leaves twenty-nine dead ones; `forget`
then `consult` leaves a dead copy of every clause. The *live* contents stay
the same size. What grows is the number of dead versions every read walks
past — so nothing breaks, and everything gets slower.

Measured, twelve interpreters over four machines, identical work every time:

|  | wall clock |
|---|---|
| empty store | 12s |
| the same store, five runs later | 32s |
| a store a few hundred test runs old | 60s |
| that store, after one `TRUNCATE` pass | 16s, stable thereafter |

Five times the wall clock on identical work and identical live data. Every
benchmark number in this README was taken against a fresh store, and a number
taken against a worked one measures the store's history, not the change being
tested. **If an unexplained slowdown appears and the answer to "when was this
store last truncated" is "never", that is the cause** until proven otherwise.

`TRUNCATE` is ZiguratIP's vacuum — per table, reclaiming only rows committed
as deleted that no running transaction can still be entitled to, so it is
safe against a knowledge base in use (`ZiguratIP/doc/truncate.md` is the full
account). cocolog carries the pass in three forms, one per kind of caller:

```sh
cocolog vacuum                       # against the server (make schema ships
                                     # the cocolog::vacuum procedure it calls)
cocolog --embed DIR vacuum           # the same pass, embedded — the Cicili
                                     # engine's own truncate over the same
                                     # four tables
cocolog --vacuum query "vacuum_kb"   # from inside a program; also
                                     # vacuum_kb(Live) for the live count
```

The verb prints — and `vacuum_kb(Live)` answers — the number of **live** rows
left behind, which is the more useful number than the reclaimed count: run it
twice, and the second answer being the same is what says there was nothing
left to reclaim. It is store-wide, not per `--kb`, because a dead row no
longer has a knowledge base to belong to.

Run it the way any store with MVCC and no background vacuum wants its
maintenance run: **on a schedule, whenever the store has been worked** —
between benchmark runs always, between test-suite runs if the numbers are to
mean anything (`test/groups.sh` and `test/ruler.sh` run it in setup, which is
why they no longer slow down run over run), and periodically in any
long-lived deployment. The first measured pass took a 35MB store down to its
263 live rows.

Three caveats, so the schedule is chosen with open eyes:

* **It spends point-in-time reads.** The reclaimed versions are exactly what
  `SNAPSHOT` isolation and `rollback_transaction_to` read from, so after a
  pass the store cannot be read at a moment before it ran. Giving that up is
  an operator's decision, which is why `vacuum_kb` is **gated**: without
  `--vacuum` on the command line it raises
  `permission_error(vacuum, knowledge_base, _)` — a refusal, never a quiet
  no-op — and a program never spends the store's history unless the operator
  said this run may. The `vacuum` verb needs no flag; typing it is the
  decision.
* **A store written before the schema made every column `NOT NULL` can never
  be reclaimed** — `TRUNCATE` refuses rows carrying a NULL, and old stores
  have them (`machines.note`; STATUS.md has the story). For those the only
  cure is a fresh data directory.
* **A vacuumed store is fast, not small.** Reclaimed pages go back to the
  allocator for any table to reuse; the files do not shrink. What recovers is
  the number of dead versions every read walks past — which is the thing the
  measurements above show was being paid for.

cocolog is a client and modifies neither of the projects it uses — but running
twelve of it at once turned up four faults in ZiguratIP, from unguarded B-tree
walks over the shared page store to a documented Parsi clause that had never
compiled. Those are fixed in ZiguratIP itself; its `doc/concurrency.md` is the
account.
