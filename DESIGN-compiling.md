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
does nothing whatever about the heap.

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

## 8. If any of this were to be done, in order

1. **A garbage collector, or a heap that a deterministic recursion does not
   grow.** 572 MB for two million iterations is the binding constraint on
   program size today, and no amount of compilation touches it. This is the
   highest-value work in the study and it is not a compiler.
2. **The static-fraction count** of section 7 — a day's work, and it decides
   whether 3B is worth weeks.
3. **Packaging (3A)**, if a single-file deliverable is what is wanted. It is
   nearly free and it is orthogonal to everything else.
4. **3B, emitting C**, if the count in step 2 comes back high.
5. **Not 3C**, unless the project decides that freeze-and-resume is no longer
   what it is for. That is a decision about the project, not about a compiler.

## 9. What this study did not check

Said plainly, so nobody mistakes its scope:

* No prototype was written, and no compiled clause was measured. Every
  performance claim about a *compiler* is an estimate; every claim about the
  *interpreter* is measured and reproducible from section 1.
* The static-fraction count (section 7) is not done.
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

`-s FILE` is literally `use_module('FILE'), main` (`cocolog.cicili:772`), and
`use_module` takes the **dlopen** branch for any path ending in `.so`
(`lib/library.cicili:347`, dispatched at `:451`). So `cocolog -s ./prog.so`
already loads and runs a compiled object today, with no new mechanism: one
exported symbol, `int coco_library_entry(void)`, returning ABI version 1.

**With one catch that matters.** `coco_module_load` MUTES the store while it
consults a module's Prolog half (`lib/module.cicili:455`, `:468`), so a program
delivered that way has its clauses marked `library` and writes nothing through.
A compiled program shipped as a module is therefore a program that has opted
out of the knowledge base — which for many programs is right, and for the ones
this project exists to demonstrate is exactly wrong.

### 10.3 There is nothing for an object file to link against

`main` is inside the same 16 960-line translation unit as the engine
(`cocolog.c`), the Makefile links `.libs/cocolog.o` plus `embed/.libs/embed.o`
straight to the executable, and the only archive in the tree,
`build/libcocologc.a`, holds the wire client (`zigurat.o`, `zeytun.o`) and
nothing else. There is no engine runtime library.

Worse for a code generator: the four functions it would most need —
`coco_k_push`, `coco_push_choice`, `coco_backtrack`, `coco_select_clause` — are
all declared `(static)`, and `nm -D --defined-only ./cocolog` finds none of
them. Option 3B's first task is therefore not a code generator: it is
splitting a runtime out of `cocolog.c` and deciding what it exports.

### 10.4 Two things a compiler would not be allowed to do

* **`clause_ix` is an ordinal a frozen choice frame holds** (`lib/state.cicili`
  writes it; `lib/solve.cicili:284` is the frame). A machine suspended part way
  through a predicate resumes at "clause number N". So a compiled predicate may
  not reorder, merge, inline, specialise or dead-eliminate its clauses without
  breaking resumption — which removes most of the optimisations that make
  compiling a predicate worth doing.
* **Atom and functor ids are assigned in intern ORDER** (`lib/term.cicili:638`,
  `:656`), and a store cell carries the machine's ids unchanged. So compiled
  clause data cannot be a static blob of cells; it has to be built through the
  intern table at load time, which is most of what `coco_store_get` already
  costs.

### 10.5 The binary is not self-contained today

`readelf -d ./cocolog` lists `libCore.so` and `libStreamIO.so` as NEEDED with
**no RUNPATH and no RPATH at all**, so the shipped binary finds ZiguratIP's
libraries only through `LD_LIBRARY_PATH` at run time. Option 3A's "one file you
can run" therefore has a step before it that has nothing to do with compiling:
either static linkage of those two, or an RPATH, or a launcher. (An earlier
draft of this section said an absolute RUNPATH was baked in. It is not; there
is none. Checked.)

### 10.6 A bug, found on the path this study recommends compiling

Not a feasibility finding — a defect, discovered while checking §9's claim
about load-time semantics, and reported here because this is where the evidence
is.

**`use_module` of any file containing a GOAL directive exhausts the C stack and
dies of SIGSEGV.** Since `-s FILE` *is* `use_module('FILE'), main`, that means
the documented form for running a program crashes on the documented behaviour
of a directive:

```
$ printf ':- write(hello), nl.\nmain :- write(done), nl.\n' > p.pl
$ ./cocolog -s p.pl ; echo $?
139                      # no output, empty stderr
$ ./cocolog run p.pl main
hello
done
```

Measured and characterised:

| directive | `-s` |
|---|---|
| `:- dynamic(foo/1).` `:- op(700, xfx, ===).` `:- use_module(library(lists)).` | fine |
| `:- write(x), nl.` `:- true.` `:- X is 1+1.` `:- initialization(main).` | **SIGSEGV** |

That is exactly CLAUDE.md's split: the handful of directives that act on the
READER are answered by `coco_directive`, "and everything else is called" — and
the called path is the one that dies. It reproduces through a nested
`use_module` too (`run outer.pl main` where `outer.pl` imports a file with a
goal directive), so it is `use_module` and not `-s` that is broken.

It is stack exhaustion, not a null dereference: time-to-crash scales with the
limit — `ulimit -s 1024` 14 ms, `8192` 21 ms, `65536` 75 ms.

`lb_goal_hook` (`lib/library.cicili:557`) is where to look: it makes a whole
`coco_engine` as a C local and runs the directive's goal on it, over the same
machine and store, from inside a consult that the module loader is holding.

**Why it has never been seen:** no shipped `library/*.pl` has a goal directive
— checked, all twelve — and `test/directives.sh` exercises directives through
`run` only and never once through `-s`. The suite is green because nothing in
it stands on this path.

The obvious repair — a re-entrancy guard on the goal hook — is not applied
here; the diagnosis is, and it wants the full suite behind it.
