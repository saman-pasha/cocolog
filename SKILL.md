---
name: cocolog
description: Use when working on cocolog — its Prolog engine, shared store, green scheduler, loadable modules, libraries, tests, or Cicili sources. Read this before changing code; it points to the authoritative Cicili library declarations and the repository's build/test rules.
---

# SKILL — working in cocolog

cocolog is a Prolog whose running proofs can be frozen into ZiguratIP and
resumed elsewhere. It is written in **Cicili** (C in S-expressions) and its
knowledge base is a runtime arrangement: `--local`, `--embed`, a ZiguratIP
server, or Zeytun/HTTP.

Read, in this order:

1. This file.
2. [`CLAUDE.md`](CLAUDE.md) — owner rules, build details, hazards, engine notes.
3. [`README.md`](README.md) and [`MORE.md`](MORE.md) — what it is and how to use it.
4. [`MODULES.md`](MODULES.md) — the module seam and how to write one.
5. [`COMPAT.md`](COMPAT.md) — every deliberate Prolog divergence.
6. [`../cicili/SKILL.md`](../cicili/SKILL.md) — **the language you write the C half in**
   (Cicili 3.2.0 and later; a 3.1.0 checkout has no `SKILL.md`).
7. [`../cicili/lib/README.md`](../cicili/lib/README.md) — **the declaration source**.

When this file and `CLAUDE.md` disagree, `CLAUDE.md` has the owner's current
rule; when this file and the source disagree, the source wins.

---

## 1. Use Cicili's `lib/` — do not write its declarations again

**Rule zero: before writing any `(decl) (func …)`, `(struct …)`, `(typedef …)`,
`@define`, C/POSIX binding, or `(code …)`, inspect `../cicili/lib/`.**

Cicili already declares:

- the C17 headers and POSIX headers under [`../cicili/lib/std/c/`](../cicili/lib/std/c);
- the standard containers and algebraic layer under [`../cicili/lib/std/`](../cicili/lib/std);
- the bindings under `../cicili/lib/db`, `net`, `python`, `cpp`, and `parsi`.

Import the binding, include the **real header**, and add the link flags. Do not
copy a declaration from a header or from another project into cocolog. The
usual truly missing item is only a C typedef for a struct with no typedef in
the real header — e.g. `(@define (code "pollfd struct pollfd"))` — and its name
must be the one the std declaration uses for the members.

Cicili's own skill has the full index, import prefixes, headers, link needs and
usage rules. Read it before adding a binding. If a declaration is genuinely
missing, add it to Cicili's `lib/` rather than duplicating it here — Cicili is
an input to this repository, so that change needs the owner's explicit leave.

The only declarations that belong in cocolog are cocolog's **own** seams:
`lib/module.cicili` and `lib/sdk.cicili` for the module API,
`lib/zigurat-kb.cicili` / `lib/zeytun-kb.cicili` for the backends, and each
module's library-specific `binding.cicili`.

---

## 2. Source map

| path | what lives there |
|---|---|
| [`cocolog.cicili`](cocolog.cicili) | the CLI, targets, version, REPL, commands; one binary |
| [`lib/term.cicili`](lib/term.cicili) | flat cell heap, terms, atoms, functors, floats, strings, GC primitives |
| [`lib/syntax.cicili`](lib/syntax.cicili) | reader and writer, operators, DCG translation |
| [`lib/solve.cicili`](lib/solve.cicili) | engine loop, choice frames, catch/throw, findall, freeze/thaw hooks |
| [`lib/kb.cicili`](lib/kb.cicili) | store, predicates, clauses, indexing, compaction, logical update view |
| [`lib/state.cicili`](lib/state.cicili) | frozen machine format: save, load, freeze, thaw |
| [`lib/green.cicili`](lib/green.cicili) | green scheduler, workers, channels, barrier, foreign-call handshake |
| [`lib/module.cicili`](lib/module.cicili) | the module registry and in-tree module seam |
| [`lib/sdk.cicili`](lib/sdk.cicili) | the loadable-module SDK (also symlinked into `modules/*/sdk.cicili`) |
| [`lib/files.cicili`](lib/files.cicili), [`lists`](lib/lists.cicili), [`apply`](lib/apply.cicili), [`builtins`](lib/builtins.cicili), [`library`](lib/library.cicili) | the core surface |
| [`lib/zigurat-kb.cicili`](lib/zigurat-kb.cicili), [`lib/zeytun-kb.cicili`](lib/zeytun-kb.cicili) | the two remote backends |
| [`client/`](client) | the Zigurat binary/TLS client in plain C |
| [`embed/`](embed) | the embedded MVCCS engine and its C++ bridge |
| [`library/`](library) | tier-2 Prolog libraries |
| [`library/reasoning/`](library/reasoning) | controlled English and the translator: a version of its own (`reason_version/3` in `reason.pl`), the cases `test/{reason,normalise,tagger,translate}.pl` and lesson 46; its sample loop and record are in `CLAUDE.md`'s reasoning section |
| [`library/flow/`](library/flow), [`tools/flow/`](tools/flow) | flowcharts, the run debugger and profiles; `tools/flow/chart.pl` and `tools/flow/debug.pl` from a shell (§9) |
| [`modules/`](modules) | loadable C/C++ modules and their build scripts |
| [`tools/cocolint/`](tools/cocolint) | the repository-aware linter and dialect card |
| [`test/`](test) | the suite, one `.pl`/`.cicili` case per family |
| [`tutorials/`](tutorials) | executable documentation; every claim is a test |
| [`parsi/`](parsi) | the ZiguratIP schema, compiled by `make schema` |

The engine is a **flat cell array**, not a pointer graph: terms are indices,
the continuation is `'$k'(Goal, Barrier, Rest)`, and choice points are integer
frames. Freezing a machine is writing its arrays; thawing is reading them.
Every change must preserve that property or state why it does not.

---

## 3. Build and test

The build uses Cicili at `$(CICILI)` (default `$HOME/cicili`) and ZiguratIP at
`$(ZIGURATIP)`. Everything is Clang; `CICILI_CC`/`CICILI_CXX` choose which
Clang, and `tools/cc` is the single wrapper all layers use.

**This tree needs Cicili 3.2.0 or later**: since cocolog 2.11.5 `realpath` comes
from Cicili's `lib/std/c/stdlib.cicili`, and since 2.11.2 the growths are
`(cold)` (Cicili 3.1.0).

**`CICILI` does not choose the Cicili that runs; ASDF does.** `cicili.lisp`
loads the system with `asdf:load-system "cicili"`, which takes the first
`cicili.asd` in ASDF's source registry. The install scripts make
`~/common-lisp/cicili` a link to the checkout that `CICILI` named at install
time, and ASDF finds that link first. A build from another checkout (a newer
commit, a copy kept beside a frozen one) needs
`CL_SOURCE_REGISTRY=/path/to/that/checkout/:` too, or it runs one Cicili's Lisp
under the other's script and `lib/`. Ask before you trust a build:
`cd "$CICILI" && sbcl --script cicili.lisp --version` answers from the system
that ASDF found.

**After a new Cicili or a ZiguratIP change, rebuild in this order**: ZiguratIP
first (`make clean && make MODE=Release` in `$ZIGURATIP`, which also runs its
engine tests and builds its System objects; `demo/build.sh` again where the
demo was built), then here `make clean && make`, `make schema` (the Parsi
objects for the new engine) and `make modules` (`make clean` removes
`library/*.so`). The `.o` files must name only clang (`readelf -p .comment`;
the `GCC:` line in a `.so` is the system's `crtbeginS.o`), and `git status`
must stay empty in both repositories.

```sh
make                    # C client + one cocolog binary (embedded store)
make EMBED=0            # no ZiguratIP embedded engine
make schema             # compile parsi into $(ZIGURATIP_HOME)
make modules            # every loadable module; each may SKIP with a reason
make test               # the full suite
make lint               # cocolint over the working tree
make lint FILES="x.pl"  # one file
make clean
```

Useful direct runs:

```sh
./cocolog FILE.pl GOAL
./cocolog -s test/NAME.pl
./cocolog -s test/run.pl -- NAME
./cocolog query "goal"
./cocolog --local run FILE.pl main
./cocolog --embed STORE run FILE.pl main
```

The suite is [`test/run.pl`](test/run.pl); `make test` builds it and the two
modules the runner itself needs (`process`, `text`). Database cases require a
ZiguratIP server and **SKIP** without one; that is not a pass. `ray` needs a
display/raylib, torch needs libtorch, and the tensor/Numpy cases need their
runtime. Count SKIPs and read the case lines, not just `red: 0`.

The known window case is `ray`: it can flake in a long suite and pass alone.
A red case is rerun alone before being called a code regression.

If the compiler is Homebrew LLVM and the binary needs Z3/libCore, the local
build may need:

```sh
DYLD_LIBRARY_PATH=/usr/local/Cellar/z3/5.1.0/lib \
CICILI_CC=/usr/local/opt/llvm/bin/clang \
CICILI_CXX=/usr/local/opt/llvm/bin/clang++ \
make
```

Never commit build output: `.o`, `.so`, generated `.c`/`.cpp`, `library/*.so`,
the `modules/*/sdk.cicili` and `zigheaders` symlinks, or `test` binaries.

---

## 4. The Prolog surface

Tier 1 is always present (compiled in): `apply`, `builtins`, `dcg`, `files`,
`library`, `lists`, `zigurat`, the vendored SWI libraries (`assoc`, `pairs`,
`ordsets`, `yall`, `aggregate`, `ugraphs`, `dcg_basics`, `dcg_high_order`), and
`async` (green threads, preloaded). `use_module` on a tier-1 library is a
no-op.

Tier 2 is loaded on demand from `$COCOLOG_LIBRARY`, `./library`, the executable's
`library`, then `lib/swipl`:

`astar`, `async`, `ca`, `clay_ray`, `cowork`, `hex`, `html`, `http`, `httpd`,
`json`, `kbs`, `llm`, `main`, `template`, `tensor_expr`, `websocket`, `xml`,
plus `reasoning/` and `flow/` (`flow/chart`, `flow/debug`). The source of truth
for names and modes is the file's header and [`library/`](library), not this
list.

The dialect is ISO/SWI-shaped with the deliberate exceptions pinned in
[`COMPAT.md`](COMPAT.md). Do not "fix" a difference without reading that row
and the test that pins it. `library(thread)` shares nothing and copies terms;
`library(async)` shares one store with green tasks. Choose deliberately.

### Modules

Loadable modules are in [`modules/`](modules): `aes`, `bigint`, `clay`, `curl`,
`der`, `numpy`, `opencv`, `os`, `process`, `ray`, `regex`, `sha`, `signal`,
`stream`, `tcp`, `tensorflow`, `text`, `thread`, `tls`, `torch`, `x509`.

Each has `NAME.cicili`, a `build.sh`, and optional `binding.cicili`. Build one
with `sh modules/NAME/build.sh`; output goes to `library/NAME.so` and is
ignored by git. `make modules` builds all, reporting SKIPs with the reason.

The module rules are in [`MODULES.md`](MODULES.md) and `../cicili/SKILL.md`:

- A loadable module imports **only** `lib/sdk.cicili`; never import both
  `lib/module.cicili` and `lib/sdk.cicili` in one target.
- A C++ module needs its SDK C prototypes with C linkage before the Cicili
  declarations; do not wrap `(coco-sdk)` in `extern-c` (the SDK macro's own
  declarations and `extern-c` expansion do not compose).
- No C pasted into Prolog strings. A C library is declared in a binding and
  called as Cicili.
- Reuse the C/POSIX declarations from `../cicili/lib/std/c` before declaring
  a header again.

---

## 5. The store, freeze/thaw, and the green world

### One store

The knowledge base is a store selected at runtime:

| mode | store |
|---|---|
| `--local` | in memory, no database (default) |
| `--embed DIR` | ZiguratIP's MVCCS linked in-process |
| `--kb NAME` / `--tcp` | a ZiguratIP server over the binary protocol |
| `--tls` | the same over TLS |
| `--http`/`--https` | Zeytun/HTTP |

A clause is a row; a proof is a term that can be frozen into rows and resumed.
`run_isolated/2` gives a proof a fresh store; terms cross only through
channels/rows, never shared cell indices.

### Green world

`library(async)` runs green tasks over **one shared store**, one worker per
core, each task with its own machine, preempted at 10,000 steps.

- A store write takes the **write barrier**: other workers acknowledge at a
  safe point. This is why writes are expensive and reads parallelise.
- A declared non-store foreign call (`coco_g_foreign_begin/end`) is not waited
  for; the call's end syncs with an in-flight write. Ray's `EndDrawing` and
  thread-module waits use it.
- `findall/3` results and a caught ball live in **private per-engine stores**
  (`pst`/`bst`); their puts skip the barrier. A ball crossing into a catch in
  the immediate outer engine stays in that engine's private `bst` and carries
  its store with the cell (2.11.6); only a ball no catch takes is copied to the
  shared store.
- Empty private stores larger than 65,536 cells give their array back, so a
  huge one-shot findall does not pin its high-water mark to a long-lived task.
- The heap and store collectors are manual. Any new root or cached cell index
  must be declared to the collector; a store compaction can move cells. Private
  stores are marked by `coco_tables_reclaim`.
- The nested engine behind `findall/3`, `forall/2`, `call_limited/3` cannot
  suspend its C search; blocking calls inside it are waited for in the
  builtin, with the worker's ready tasks run.
- `yield` inside a nested engine is a no-op.

---

## 6. The engine invariants

Changes here need more than a green build:

- **Flat cells, no pointers in terms.** A term is a cell index; a REF points to
  itself when unbound.
- **Continuation is a term.** `'$k'/3` carries the pending goal, its cut
  barrier and the rest.
- **Choice frames are integers.** Adding a field changes the frozen format;
  append, don't reorder.
- **One writer at a time.** Store mutations take the barrier; readers are
  lock-free on their last synced table pointers.
- **Tables are shared across green machines.** Growth publishes a new array
  and never frees the old one while the world lives; a machine one generation
  behind reads valid memory and syncs before its next mutation.
- **Logical update view.** A call sees the clauses that stood when it began;
  tombstones and frame marks make assert/retract safe with open calls.
- **Throw balls and findall results must survive heap wind-back.** They are
  stored in the private stores; a ball crossing an engine boundary carries its
  store pointer, and only an uncaught ball goes to the shared store.
- **The store compactor moves cells.** Every cell index held across a safe
  point must be a registered root (`coco_store_root_push`, or private store).

Read the relevant `CLAUDE.md` section before changing any of these.

---

## 7. Editing rules for agents

- **Read `CLAUDE.md` first.** It carries the owner's standing rules, current
  toolchain, version policy, and hazards that have already cost a day.
- **Do not edit another repository**, including `../CivV`, unless the owner
  explicitly says so. `../cicili` is an input; a change there needs explicit
  permission.
- **Use `lib/` declarations.** See §1. Never duplicate a C/POSIX declaration
  or a Cicili binding in a target.
- **Write Prolog in `.pl`, C in `.cicili`, never C in a Prolog string.** A
  module is a Cicili binding; call it from Prolog.
- **Add a regression test** under `test/` and run the narrow case, then the
  full suite for an engine/store/scheduler change.
- **Run `git diff --check` and `make lint`**; cocolint's dialect citations must
  still resolve after moving source lines.
- **Bump the version** in the same commit, never in a later one: cocolog's in
  `cocolog.cicili` (`coco_version_text`) and `README.md` for a change to the
  binary or to a library; the reasoning library's own, `reason_version/3` in
  `library/reasoning/reason.pl`, for a change under `library/reasoning/` (and
  then not cocolog's); both when a commit changes both. Patch by default,
  minor for a reachable feature, major for a source/behavior break; a minor or
  a major is proposed and used in the same commit (`CLAUDE.md`). A
  documentation-only commit bumps nothing and says `cocolog stays X.Y.Z` in
  its message. Read master's number first
  (`git show origin/master:cocolog.cicili | grep coco_version_text`): two lines
  of work bump the same number.
- **Do not commit build outputs.** Check `git status --short` for generated
  `.c/.cpp`, `.so`, `.o`, symlinks and test binaries.
- **A red case is not a pass.** Rerun it alone; distinguish a missing optional
  dependency (SKIP), a flaky window test, and a real regression.
- **Wait for a background job by what it writes** (a `DONE` line in its log),
  not by `pgrep -f` of its script's name: the pattern matches the waiting
  shell's own command line, and the wait never ends.

---

## 8. Where to look when something fails

| symptom | start here |
|---|---|
| Prolog answer differs from SWI | `COMPAT.md`, the matching `test/` case, then `lib/solve.cicili` |
| a store/read/freeze problem | `lib/kb.cicili`, `lib/state.cicili`, `test/window.pl`, `test/state.cicili` |
| green task hangs or a write stalls | `lib/green.cicili`, `test/async.pl`, the barrier invariants above |
| a module will not load/call | `MODULES.md`, module `binding.cicili`, `lib/sdk.cicili`, `nm`/`otool -L` |
| a binding/header is missing | `../cicili/lib/README.md` and the binding file; do not redeclare |
| a compilers/build message | `CLAUDE.md`'s build section, `tools/cc/README`, then the generated C |
| a linter citation drift | `tools/cocolint/traps.jsonl`, the named source line, rerun `test/lint.pl` |
| a test is SKIP | the case's own guard; count it and report it, do not call it green |
| a goal fails, or a sentence is refused, and you do not know where | `tools/flow/debug.pl` with `txt=true` and the whole run recorded (§9) |
| a build behaves like an older Cicili | `cd "$CICILI" && sbcl --script cicili.lisp --version`, then `CL_SOURCE_REGISTRY` (§3) |

The authoritative test record is [`STATUS.md`](STATUS.md), but the current
suite is the only verdict: `make test`, all case lines, all SKIP reasons.

---

## 9. Why a proof failed: `library(flow/debug)`

`tools/flow/debug.pl` runs a goal twice, each time in a child process: a probe
at full speed, then a replay that records a window. It can write the run as
text, `BASE.txt`, one line a call:

```sh
cocolog -s tools/flow/debug.pl -- GOAL FILE BASE svg=false xml=false txt=true
#   over a store: embed=STORE (and kb=NAME); a big program: cache=DIR (its chart is built once)
```

- **Debug the entry goal** (`reason_translate/4` for the translator). Each
  child starts afresh, so a goal from the middle of a program does not have
  the globals and facts that an earlier call set.
- **Record the whole run.** The first run's line says `false at step N`, and
  its window is the last 2 000 steps, whose why is only the last fallbacks.
  Run it again with `from=1 to=N`: the window then holds the top call, and the
  foot of `BASE.txt` says `% where it got furthest:` -- at each failed call the
  clause that got furthest, down to the call it failed at.
- **The furthest path can name a scan.** It ranks a clause by the calls of its
  body that exited, and it counts every exit. A clause that walks every
  position with `append/3` and tests each one (three exits a position) beats
  the clauses that did the work, and it has read nothing. When the path ends
  in such a clause, rank the clauses by the steps they spent, and read the
  arguments on the way. `BASE.txt` has what that needs: each line is
  `S INDENT GOAL FATE [CLAUSES] BOX WHERE`, the depth is the indent (two spaces
  a level), `cK` is a clause entered and `hK` a head that did not unify, and
  `pP.cK.gN` names the clause a call was made in. A long argument is cut
  (`...[318]`); `text=N` writes it whole up to N characters. The most steps
  is not always the cause either (a search over every split spends the most).
  The arguments usually show the cause (a marker, a word list that lost its
  commas), and a probe without the suspect words settles it.
- **A whole-run record is held in memory**: about 6 KB a step (1.5 million
  steps: 8.8 GB and 7 minutes, and a `BASE.txt` of 144 MB). For a run of
  several million steps, debug the entry goal over a shorter input.
- `own=all` explains the failed calls of every predicate with clauses, not
  only those of the chart's panels (a program of several files).
