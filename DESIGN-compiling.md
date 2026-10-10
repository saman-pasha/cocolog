# Compiling a cocolog program: a feasibility study

**Nothing here is built, and nothing here is decided.** This is a study of one
question — *could a cocolog program be compiled to an object file and a linked
binary, instead of being interpreted from clauses at run time?* — written
because the answer turns on a design decision the tree already made on purpose,
and because the measurements that ought to inform it did not exist until now.

The short answer is in three parts:

* **Packaging a program into one binary is nearly free**, and most of the
  machinery is already here. It makes nothing faster.
* **Compiling clauses to C, keeping the engine's own data structures**, is
  real work with a real payoff and no loss of anything. It is the honest
  middle.
* **Native compilation in the ordinary sense — a clause body becomes a C
  function that calls its subgoals — costs this project its defining
  property.** `lib/solve.cicili` says so in its first paragraph, and it is
  right.

And one finding that reframes the question: **there is no garbage collector.**
Measured below. A compiler makes the interpreter's inference rate better and
does nothing whatever about the heap. (There is one since 1.8.36 — §8, item 1;
since 1.9.6 it reaches a directive's goal and a traced run, and the float and
string tables give back what nothing holds. The atom table never does.)

## 1. The measurement, first

Every number here is from this box, this tree, at the commit this file was
written on. `-s` a file, best of three, peak RSS from `getrusage`.

| what | wall | peak RSS |
|---|---|---|
| start-up, `main :- write(done), nl.` | 8 ms | — |
| `nrev` of 100, ×50 — 257 550 logical inferences | 0.217 s | 66 MB |
| `count(2000000)` — a deterministic tail recursion | 1.87 s | **572 MB** |
| `( between(1, 2000000, _), fail ; true )` | 5.48 s | **938 MB** |

From the second row: **1.19 MLIPS**, and **about 270 bytes — some 34 eight-byte
cells — allocated per logical inference.**

From the third: a deterministic loop that allocates never gives the memory
back. `grep` for a collector in `lib/` finds one comment about a store flush
and no code. The heap is reclaimed by BACKTRACKING and by nothing else:
`coco_backtrack` sets `heap_len` back to the choice point's `heap_mark`, which
is exactly right for a failure-driven loop and does nothing at all for a
recursion that succeeds. Two million iterations of a three-line predicate cost
572 MB.

That is the number to hold on to. A compiler that made cocolog ten times
faster would reach the same wall ten times sooner.

**For scale, and stated as the soft comparison it is:** a modern optimising
Prolog interpreter is usually quoted in the region of 20–30 MLIPS on `nrev`,
and a natively compiled one higher again. Those figures are not measured here
and the benchmark's shape matters more than its name, so treat them as an
order of magnitude and not a score. The order of magnitude is the point: there
is a lot of room.

## 2. The one structural fact

`lib/solve.cicili:3`, the first paragraph of the engine:

> NOTHING HERE RECURSES IN C, and that is the whole point of the file. A Prolog
> interpreter is naturally written as a recursive `solve()` that calls itself
> for each subgoal and uses the C stack as its continuation — it is half the
> length that way. But a machine whose continuation is the C stack cannot be
> stopped and written to a database, because the C stack is not data. cocolog
> exists to be suspended and resumed, so the continuation is a term on the heap
> and the choice points are an array of integers, and the engine is a loop over
> them.

And `lib/state.cicili:8`, from the other side:

> If terms were made of malloc'd nodes and the engine recursed in C, this file
> could not exist at all; that is what `term.cicili` and `solve.cicili` are
> paying for.

**This is the whole feasibility question in two quotations.** The standard way
to compile Prolog — WAM instructions lowered to native code, or a clause body
emitted as a C function that calls its subgoals — puts the continuation back on
the machine stack. A machine whose continuation is the C stack cannot be
frozen into a `Text` column, shipped to another process and resumed there. That
is not a nice-to-have here: it is `swarm`, the coworkers, the balancer, and the
claim the project exists to make.

So the question is not "can Prolog be compiled" — it plainly can, several
systems do it — but "what does compiling cost THIS design", and the answer is
specific and large.

## 3. Four things "compile to a binary" could mean

Priced separately, because they are separate projects and only one of them is
what the phrase usually means.

### A. One file you can run — packaging (days)

A binary that carries its program and needs no `.pl` beside it. **Most of this
exists.** `--embed [DIR]` already links the embedded store into the one binary
and opens a knowledge base out of a directory; `lib/state.cicili` already
freezes a whole machine to ASCII and thaws it back; `run FILE main` already
writes a consulted program's clauses THROUGH into the store. A
`qsave_program`-shaped path — bundle the interpreter, the program's clauses as
a store image, and an entry goal — is assembly of parts that are all present.

What it buys: distribution. What it does not buy: one microsecond.

### B. Compile clauses to C, keep the engine's structures (weeks, and the honest middle)

A clause becomes a C function that builds the SAME `'$k'(Goal, Barrier, Rest)`
frames and pushes the SAME choice points, calling the same `coco_*` runtime —
generated code as a state machine, never as recursive C. Everything freezable
stays freezable, because the representation does not change.

What it removes: walking the clause term to build each goal, the per-goal
dispatch, re-deref of head arguments the compiler could have laid out. What it
cannot remove: the heap traffic, because the continuation frames ARE the
freezability.

Honest expectation: a small multiple, not an order of magnitude — and I have
not prototyped it, so that is a judgement, not a measurement.

### C. Native compilation, the ordinary kind (months, and it costs the design)

WAM or direct lowering, continuation on the machine stack. This is where the
order of magnitude lives, and it is exactly what section 2 says the tree
refuses. It would need either the freeze/thaw property abandoned, or a second
execution mode with two engines to keep in step — and "two implementations that
must agree" is the hazard `tools/cocolint`'s own README was written about.

### D. Compile the *interpreter* better (already done, mostly)

Worth naming because it is where the recent wins actually came from, and
because a compiler is often proposed for work that has already been done here
another way. See section 5.

## 4. LLVM specifically

**Emitting C and letting clang be the back end gets LLVM for free.** Every
line of this tree is already built by clang (`tools/cc/README`), the module
seam is already a C ABI, and `modules/*/build.sh` already turns generated C
into a `.so`. A generated `.c` inherits the whole optimiser with no new
dependency and no new build step.

**Emitting LLVM IR directly would add libLLVM to the build.** CLAUDE.md's own
rule for that decision is written down — *"a thing belongs in tier 2 when its
dependency should not be everybody's"* — and it is the argument that moved
torch and bigint out of the binary. libLLVM is far larger than either. Against
that cost, emitting IR rather than C buys: control over calling conventions and
tail calls, and the ability to JIT. Neither is worth libLLVM unless option C is
being taken, and option C is the one that costs the design.

If a compiler is ever written here, it should emit C.

## 5. What a compiler would usually deliver, and this engine already has

This matters, because it is most of the case FOR compiling — and much of it is
spent.

* **First-argument indexing** — `lib/kb.cicili:69` and `:273`, with
  `coco_arg_key` and `coco_pred_next_clause` called by the engine. Present.
* **Dispatch by interned id, not string comparison** — `*dispatch-names*` in
  `lib/solve.cicili:175` emits a switch, grouped by arity.
* **The last clause drops its choice point**, so deterministic recursion runs
  in constant choice-stack space (`lib/solve.cicili:38`).
* **Deref-at-build**, the fix that took `between(1,20000,_), fail` from
  15 529 ms to 51 ms and `findall` over 20 000 from 9 167 ms to 53 ms
  (CLAUDE.md, "The engine was quadratic"). The single largest speed-up this
  interpreter has had was one call in `coco_make`, not a compiler.

**Two cheap wins are NOT taken, and a second pass found them.** Every call of
a user predicate resolves its name through `coco_pred_find`
(`lib/kb.cicili:714`), which is a `for` loop over every predicate in the store
comparing name and arity — reached on each goal by way of `coco_pred_of` ->
`coco_pred_make` (`:740`, `:727`). That is O(predicates) per inference, and a
hash or an interned slot would remove it without touching the engine's shape.
And `coco_bind` (`lib/term.cicili:847`) trails unconditionally: two statements,
write the cell and push the trail, with no test of the variable's age against
the newest choice point's `heap_mark`. The WAM's conditional-trail test is
absent from the tree.

So the sentence to keep is narrower than "the cheap wins are spent": the
LARGEST ones are spent, and two ordinary ones are still on the table and are
cheaper than any compiler. What is left after those is the cost of the
continuation being data — which is the thing that must not be removed.
(The first was taken in 1.8.32: the functor and predicate tables are
hashed. The second, the conditional trail, still has not been: in 1.9.6
`coco_bind`, now `lib/term.cicili:1250`, is the same two statements.)

## 6. What the other systems gave up

Stated from general knowledge rather than measured here, and flagged as such.

* **GNU Prolog** (`gplc`) compiles to native through a WAM and a mini-assembly,
  and is fast. It is also the system where the dynamic database is the awkward
  part: predicates you intend to `assert` into must be declared, and a compiled
  program is not a system you can `consult` new source into at will.
* **SWI-Prolog's `qsave_program`** is deliberately NOT native code — it is the
  interpreter plus a compiled clause image in one file. That is option A above,
  and SWI is the largest, most dynamic Prolog in use choosing it.
* **Mercury** compiles beautifully and is a different language: modes,
  determinism and types declared, no run-time database in the Prolog sense.
  That is the honest price list for a compiler that really wins.
* **wamcc and the emit-C school** chose C over machine code for the reason in
  section 4 — the C compiler is a better back end than a small team's code
  generator, and it is portable for free.

The pattern across all of them: **what gets compiled is the static part, and
every system either restricts the dynamic part or keeps an interpreter for
it.** cocolog is unusually far toward the dynamic end — its clauses are ROWS
IN A DATABASE that another process may be writing.

## 7. The database is the deepest obstacle, and it is not incidental

In the three server arrangements a predicate's clauses are fetched from the
store on first use. `lib/kb.cicili`'s five hooks (`fetch`, `on_assert`,
`on_retract`, `on_dynamic`, `warm`) exist precisely so that "what clauses does
`p/2` have" is a question answered at RUN time, over the wire.

**A first draft of this section said the clauses can change under a running
proof from another process, and the code says otherwise.** `coco_pred_ensure`
(`lib/kb.cicili:748`) is `if (loaded) return 1; loaded = 1; fetch(...)`, and
the comment above it gives the reason: "The backend is asked once per
predicate and the answer is remembered whether or not it produced clauses --
otherwise a call to an undefined predicate inside a loop is a database round
trip per iteration." So within one process a predicate is fetched ONCE and
then held; a writer elsewhere does not move it under the proof. That makes the
obstacle smaller and sharper than the first draft claimed: not "the clause set
mutates mid-proof", but "the clause set is unknown until the first call, and
the first call happens at run time in another process's database".

A compiler must therefore compile only what it can prove nobody will change,
and fall back to the interpreter for the rest. That is a normal design — but
here the fraction that can be proven static is smaller than in any other
Prolog, because the entire point of the system is that a clause is a row
somebody else can read and write.

**This is the part of the study I have not measured**, and it is the part that
decides how much of a real program would actually compile. The measurement to
make is a count over `library/*.pl`, `tutorials/**/*.pl` and the coworkers: how
many predicates are reachable without `assert`, `retract`, `dynamic/1`,
`consult` or a computed `call/N`. Until that number exists, section 3B's payoff
is a guess.

**Measured in 1.9.4**, by `tools/compile/static.pl`, which reads each file as
cocolog reads it and says of every predicate whether its clauses can change
while the program runs, and of every goal what it calls. A predicate's clauses
can change when its file declares it `dynamic` or asserts into it, retracts
from it or abolishes it by name; and all of a file's can when the file asserts
a clause it builds at run time, which no compiler can name in advance, or
consults while it runs. Over the 154 files — 3 799 predicates, 8 109 clauses:

| | predicates | fixed, provably | fixed, a built clause read as data |
|---|---:|---:|---:|
| `library/` | 2 336 | 1 061 (45.4 %) | 2 333 (99.9 %) |
| `tutorials/` | 1 442 | 1 431 (99.2 %) | 1 442 (100 %) |
| `coworker/` | 21 | 21 (100 %) | 21 (100 %) |
| all | 3 799 | 2 513 (66.1 %) | 3 796 (99.9 %) |

Three predicates with clauses in their own file are declared `dynamic`; the
rest of what changes at run time is predicates no file defines — a lesson's
vocabulary, a certificate authority's grants, the assert tutorial's counter,
the grammar rule the DCG tutorial asserts to show that it is translated. The
whole gap between the two columns is four files that assert a clause they
build: the reasoner's and the translator's learning paths (`reason_learn/2`,
`tr_learn_term/2`, `assert_once/1` and two more) and the two tutorials that
use them, whose 1 283 predicates a compiler that cannot see what such a
clause will be must treat as changeable. What they assert is what they are
taught — facts, and the reasoner's rules read from English (`Every employee
has a badge`) — and never their own code.

Of the 40 661 calls in bodies (a cut and `true` are none), 34.7 % are of
their own file's predicates, 42.4 % of builtins and 20.5 % of a library's; 81
call a predicate their file asserts by name and defines nowhere, 76 an
argument of the clause's head (a closure, which the caller knows) and 14 a
goal built at run time; 2.0 % name nothing a file defines — almost all the
vocabulary a lesson teaches (`mean/2`, `plural_of/2`), which the translator
reaches through a goal it builds. 92.9 % of the predicates are reached from
their file's directives, `main/0` or exports by literal calls.

**Where the time goes** is what the count cannot say, so a scratch build
counted, per predicate, the clauses the engine entered and the asserts and
retracts a run made (the counters were not committed). The linter's 12.5
million clause entries all went to predicates whose clauses never changed
after loading. The translator's lesson made 54.2 million: 88.2 % into
predicates fixed since load, and 11.7 % into the 184 that its 45 139 asserts
and retracts changed — each one something a lesson taught it (`lesson/2`,
`lesson_predicate/3`, `italian:mean/2` and the like). None of its own
predicates changed.

So the obstacle is real and smaller than this section feared: in this corpus
a program's own code is fixed and what it learns is not. A compiler of 3B's
kind would take every predicate a file defines and leave what the program
learns where it is, in the store and indexed, which is what the store is for.

## 8. If any of this were to be done, in order

1. **A garbage collector, or a heap that a deterministic recursion does not
   grow.** 572 MB for two million iterations is the binding constraint on
   program size today, and no amount of compilation touches it. This is the
   highest-value work in the study and it is not a compiler.
   **Done in 1.8.36** (STATUS.md, "The heap is collected"): a sliding
   mark-compact between engine steps. `count(2000000)` now finishes holding
   23 MB of heap where it held 560 MB, the `between/3` loop peaks at 44 MB
   where it peaked near a gigabyte, and neither got slower. Since 1.9.4 it
   reaches a phase inside the engines a builtin starts — `findall/3` and its
   family, `call_metered/4`, `with_output_to/2` — and since 1.9.6 a
   directive's goal, when whoever started the load may collect (the
   `consult` and `run` commands, and a `use_module` reached from a goal that
   may, which is how `-s` loads its file), and a traced run. 1.9.6 also
   gives back the floats and strings no live cell names, in place — a free
   list and a trimmed tail, so no cell that names one is rewritten — and
   asks for a collection once the entries made since the last reclaim
   reach half the heap's length. The atom table is never reclaimed.
2. **The static-fraction count** of section 7 — a day's work, and it decides
   whether 3B is worth weeks. **Done in 1.9.4** (§7): 99.9 % of the
   predicates have clauses nothing changes by name, 66.1 % even when a
   clause built at run time is read as able to change anything in its file,
   and of the two real workloads' clause entries 100 % (the linter) and
   88 % (the translator; the rest went to what its lessons taught it) went
   to code fixed since load. It came back high, which is step 4's
   condition.
3. **Packaging (3A)**, if a single-file deliverable is what is wanted. It is
   nearly free and it is orthogonal to everything else. Not started as of
   1.9.6: its first step is §10.5's — today's binary finds ZiguratIP's
   libraries only where they were when it was linked — and the feature itself
   is something new a program can reach, so a minor version, which is proposed
   to the owner rather than taken.
4. **3B, emitting C**, if the count in step 2 comes back high. It did. Its
   first task is §10.3's, and checked in 1.9.6 there are two roads to it: a
   runtime split out of `cocolog.c`, or the functions a compiled clause would
   call made non-static under the `-rdynamic` link that already exports the
   rest. Either fixes an ABI every later change to the engine has to keep, so
   the choice is the project's; in 1.9.6 it has not been made.
5. **Not 3C**, unless the project decides that freeze-and-resume is no longer
   what it is for. That is a decision about the project, not about a compiler.

## 9. What this study did not check

Said plainly, so nobody mistakes its scope:

* No prototype was written, and no compiled clause was measured. Every
  performance claim about a *compiler* is an estimate; every claim about the
  *interpreter* is measured and reproducible from section 1.
* The static-fraction count (section 7) was not done; it was in 1.9.4, over
  this repository's own Prolog, which is not every program a user will
  write.
* `catch/throw` across a compiled boundary, and cut across one, are named in
  the literature as the standard hazards and are not analysed here.
* The interaction with `library(thread)` — a compiled predicate reached from an
  isolated machine — is not considered.
* Load-time semantics a compiler must reproduce are not enumerated:
  `:- G.` is a GOAL and runs during the load, `initialization(G, main)` halts
  after it, `op/3` changes the reader mid-file, and
  `set_prolog_flag(double_quotes, …)` changes what `"..."` MEANS for the rest
  of the file. A compiler has to run the loader to know what the program even
  is.

## 10. A second pass, and what it changed

Sections 1–9 were written from a first reading. A second pass — six
independent readers over the engine, the terms, the knowledge base, the build,
this tree's own documents and the prior art, each then challenged by a reader
told to refute it — corrected two claims above and added five facts worth
having. Everything below was checked against the code by hand afterwards; the
two corrections are already folded into §5 and §7.

### 10.1 This engine is BinProlog's shape, and that is thirty years of evidence

`'$k'(Goal, Barrier, Rest)` as a term on the heap is **binarization** — Paul
Tarau's transformation, `a(X) :- b(X), c(X,Y), d(Y).` becoming
`a(X, Cont) :- b(X, c(X, Y, d(Y, Cont)))` — which drops the WAM's environment
stack and makes the continuation an explicit heap object. cocolog arrived there
for its own reason (freeze and thaw, `lib/state.cicili:7`) rather than Tarau's
(a simplified WAM), but the machine is the same shape.

That converts several of the questions above from speculation into a documented
experiment, and the two most useful results point the same way as §8:

* **BinProlog ships a copying garbage collector and a term-compression scheme,
  and needs both**, because on a binarized machine every inference allocates a
  continuation frame. That is §1's 34 cells per inference, named by somebody
  else thirty years earlier.
* **Prolog Cafe**, also binarization-based, compiling one Java class per binary
  clause, measured about **10.9× slower than LLP** — and its authors attribute
  the loss to allocation, not to dispatch. A compiler that does not also fix
  allocation can lose to an interpreter that does.

These are read, not measured here, and the comparison across implementations
is soft. The direction is what matters: **allocation, not dispatch, is the
thing to fix first**, and that is the same conclusion §8 reached from this
box's own numbers.

### 10.2 The delivery channel for a compiled program already exists

`-s FILE` is literally `use_module('FILE'), main` (`cocolog.cicili:824`; the
lines in this section are 1.9.6's), and `use_module` takes the **dlopen**
branch for any path ending in `.so` (`lb_load_so`, `lib/library.cicili:346`,
dispatched at `:486`). So `cocolog -s ./prog.so` already loads and runs a
compiled object today, with no new mechanism: one exported symbol,
`int coco_library_entry(void)`, returning ABI version 1.

**With one catch that matters.** `coco_module_load` MUTES the store while it
consults a module's Prolog half (`lib/module.cicili:603`, `:625`), so a program
delivered that way has its clauses marked `library` and writes nothing through.
A compiled program shipped as a module is therefore a program that has opted
out of the knowledge base — which for many programs is right, and for the ones
this project exists to demonstrate is exactly wrong.

### 10.3 There is nothing for an object file to link against

`main` is inside the same translation unit as the engine (`cocolog.c`, 16 960
lines when this was written, 28 556 in 1.9.6), the Makefile links
`.libs/cocolog.o` plus `embed/.libs/embed.o` straight to the executable, and
the only archive in the tree, `build/libcocologc.a`, holds the wire client
(`zigurat.o`, `zeytun.o`) and nothing else. There is no engine runtime library.

Worse for a code generator: the four functions it would most need —
`coco_k_push`, `coco_push_choice`, `coco_backtrack`, `coco_select_clause` — are
all declared `(static)`, and `nm -D --defined-only ./cocolog` finds none of
them; nor `coco_try_clause`, which has entered a clause since 1.8.46. Option
3B's first task is therefore not a code generator: it is splitting a runtime
out of `cocolog.c` and deciding what it exports.

**The split is one road, and checked in 1.9.6 there is a shorter one.** The
executable is linked `-rdynamic` (Makefile:189), so every function it does not
declare static is already in its dynamic symbol table — 411 `coco_*`, 43 of
them the `coco_m_*` SDK, and among the rest `coco_make`, `coco_bind`,
`coco_unify`, `coco_new_int`, `coco_engine_next` and `coco_pred_next_clause` —
and a `.so` that `use_module` opens resolves its undefined symbols against the
executable itself, which is how every module in `modules/` links today. So a
compiled object needs no library to link against; it needs what it calls to
stop being static. The decision does not shrink with the road: which functions
to export, and what they take — the machine's and the engine's fields — then
becomes an ABI that every later change to the engine has to keep.

### 10.4 Two things a compiler would not be allowed to do

* **`clause_ix` is an ordinal a frozen choice frame holds**
  (`lib/state.cicili:164` writes it; `lib/solve.cicili:389` is the frame; the
  lines in this section are 1.9.6's too). A machine suspended part way
  through a predicate resumes at "clause number N". So a compiled predicate may
  not reorder, merge, inline, specialise or dead-eliminate its clauses without
  breaking resumption — which removes most of the optimisations that make
  compiling a predicate worth doing.
* **Atom and functor ids are assigned in intern ORDER** (`lib/term.cicili:864`,
  `:934`), and a store cell carries the machine's ids unchanged. So compiled
  clause data cannot be a static blob of cells; it has to be built through the
  intern table at load time, which is most of what `coco_store_get` already
  costs.

### 10.5 The binary is not self-contained today

`readelf -d ./cocolog` lists `libCore.so` and `libStreamIO.so` as NEEDED with
one RUNPATH: the build's own absolute `$(ZIGURATIP)/home/lib`, which
`EMBED_LIBS` passes as `-Wl,-rpath` (Makefile:181) and which has been there
since this history's first commit (77f374b, 1.2.13). `make EMBED=0` links
neither library and has none. So the binary finds ZiguratIP's libraries where
they were when it was linked, and anywhere else only through
`LD_LIBRARY_PATH`. Option 3A's "one file you can run" therefore has a step
before it that has nothing to do with compiling: static linkage of those two,
an `$ORIGIN`-relative RUNPATH with the libraries shipped beside the binary, or
a launcher. (An earlier draft of this section said an absolute RUNPATH was
baked in, and the published text corrected it to "none". The draft was right:
checked again in 1.9.6, on a build with the store linked in.)

### 10.6 A bug, found on the path this study recommends compiling (fixed in 1.6.16)

Not a feasibility finding — a defect, discovered while checking §9's claim
about load-time semantics, and reported here because this is where the evidence
was. **It was fixed in 1.6.16 (063e299), and not where this section said to
look.**

**`use_module` of any file containing a GOAL directive exhausted the C stack
and died of SIGSEGV.** Since `-s FILE` *is* `use_module('FILE'), main`, the
documented form for running a program crashed on the documented behaviour of
a directive:

```
$ printf ':- write(hello), nl.\nmain :- write(done), nl.\n' > p.pl
$ ./cocolog -s p.pl ; echo $?
139                      # before 1.6.16: no output, empty stderr
$ ./cocolog run p.pl main
hello
done
```

Measured and characterised then, and run again on 1.9.6:

| directive | `-s` before 1.6.16 | `-s` in 1.9.6 |
|---|---|---|
| `:- dynamic(foo/1).` `:- op(700, xfx, ===).` `:- use_module(library(lists)).` | fine | fine |
| `:- write(x), nl.` `:- true.` `:- X is 1+1.` | **SIGSEGV** | fine |
| `:- initialization(main).` | **SIGSEGV** | fine: `main` runs when the load ends and again as `-s`'s own goal |

That was exactly CLAUDE.md's split: the handful of directives that act on the
READER are answered by `coco_directive`, "and everything else is called" — and
the called path was the one that died. It reproduced through a nested
`use_module` too (`run outer.pl main` where `outer.pl` imports a file with a
goal directive), so it was `use_module` and not `-s` that was broken; on 1.9.6
that prints the inner file's directive and runs, under `run` and `-s` alike,
and `p.pl` prints `hello` and `done` under both.

It was stack exhaustion, not a null dereference: time-to-crash scaled with the
limit — `ulimit -s 1024` 14 ms, `8192` 21 ms, `65536` 75 ms.

This section pointed at `lb_goal_hook`, which makes a whole `coco_engine` as a
C local and runs the directive's goal on it, and proposed a re-entrancy guard
there. **The cause was in the module loader.** `coco_module_load` counted a
module as loaded (the store's `libs`) only AFTER its consult; a goal
directive's engine, whose first step is `coco_module_load`, found the module
still unloaded and consulted it again, whose directive did the same — 7 500
frames of `coco_directive` -> `lb_goal_hook` -> `coco_engine_next` ->
`coco_module_load` -> `coco_consult` until the stack ran out. 1.6.16 claims the
module before its consult and reads the count again each time round its loop,
and `test/directives.pl` gained eight checks through `-s` and through a
library `.pl` loaded by a goal and by a directive; 1.6.15 fails all eight.

**Why it had never been seen:** no shipped `library/*.pl` had a goal directive
— checked, all twelve — and `test/directives.pl` exercised directives through
`run` only and never once through `-s`. The suite was green because nothing in
it stood on this path.
