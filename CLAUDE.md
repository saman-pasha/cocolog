# Working on cocolog

README.md says what cocolog is, STATUS.md what is proven, MODULES.md and
modules/README.md how a module is written. This file says how to work in here
and what will bite you. The long record of measurements, samples and refuted
readings that used to live here is in git: `git show 2fe74df:CLAUDE.md`
(through 1.8.35). Keep this file to what a session needs to work; a finding's
full story goes in its commit message or STATUS.md.

## The owner's standing rules

* **Ask before running the full suite (`make test`), a gate, or a whole
  tutorial run.** Name the command and roughly what it costs, then wait.
  Prove a change with narrow goals (`cocolog -s test/run.pl -- NAME`, a
  one-goal query, one section) unless told otherwise.
* **Commit or push only when asked.** Push with
  `git push git@github.com:saman-pasha/cocolog.git master:master`.
* **GitHub's CI only when the owner asks** (owner, 2026-11-11: "only do
  github CI when i ask"): start no run by hand and watch none. `ci.yml`
  starts by itself on every push to master, so a pushed commit's message
  carries `[skip ci]` and the push starts none (the session's reading of
  the rule, 3.62.0's commit the first); a run the owner asks for is
  started by hand (Actions, Run workflow).
* **Every binary is built in release mode** (owner, 2026-10-08): Cicili's
  `--release` (`-O3`, plus `-falign-loops=32` for C) for the interpreter,
  the embedded store, every module and the `test/*.cicili` binaries, and
  `-O3` for anything compiled by hand (the `hoot` fixture). Cicili's
  default is `-g -O0`; nothing that runs a test or a measurement is built
  that way.
* **Every build and every configuration uses clang, never gcc** (owner,
  2026-10-08): cocolog, ZiguratIP, every module and library, and the Parsi
  objects in `$ZIGURATIP_HOME/ld`, whose compiler is `COMPILER/CPP` in
  `ziguratip.conf` (it said `c++`, which is g++ on Ubuntu, and all 111
  objects there were gcc's until they were rebuilt with clang that day).
  Check a build by its own objects: `readelf -p .comment` on a clang object
  names clang; the `GCC:` line every binary also carries is the system's
  `crtbeginS.o`.
* **Never commit build output**: `.o`, `.so`, the C/C++ Cicili emits, the
  `sdk.cicili`/`zigheaders` symlinks in `modules/*`. The test is to delete
  everything a `build.sh` makes and run it: what comes back was output.
* **A module comes only from a C/C++ API**, declared in a Cicili binding and
  called as Cicili -- never C or C++ pasted into `(code "...")` (see the
  Cicili section).
* **A new library gets a tutorial in the same commit**
  (`tutorials/library/NN-name.pl`).
* **`modules/ray` changes are validated by `cocolog -s test/ray.pl`** (and its
  tutorial if the surface changed); CivV's suite exercises it downstream.
* **`library/` must not change while a teach, learn or control round runs.**
  A teach consults the library once; a round compares libraries by md5.
* **Never `rm -rf $ZIGURATIP_HOME/data/*` unless `pgrep ziguratip` prints
  nothing** (see Hazards).
* **No Python is needed to build or run cocolog** (owner, 2026-10-01).
  Python appears only as the benchmarks' yardstick (`bench/langs.sh`,
  `test/langs.pl`, and the token benchmark's other language,
  `bench/tokens.pl`, `test/tokens.pl`). `library(numpy)` still embeds CPython and is to be
  rewritten without it, on a C++ array library, keeping its `np_*`
  predicates and `.npy` files; until then it is opt-in (`WITH_NUMPY=1` in
  the install scripts and the Dockerfile). torch's and tensorflow's pip
  paths and `colab/` are left as they are for now. **Where a Python is
  used, its floor is NumPy's: 3.9** (`PY_MIN` in `install/common.sh`, the
  same check in `modules/numpy/build.sh`), and `WITH_NUMPY=1` makes the
  NumPy (1.26 or later) `python3`'s own -- a distribution's NumPy built for
  another Python than `python3` is not importable, the mismatch a box with
  `python3` at 3.11 and Ubuntu's NumPy at 3.12 had.

## The repositories

**Only this repository may be modified.**

| repo | role | last seen |
|---|---|---|
| `../cicili` | the language cocolog is written in; BUILD time | `cc24ae0` here, and the builds take `9b825b7` from a copy beside it (below: 3.3.0, `stat_t`'s three times to the nanosecond, `st_mtim` and Darwin's `st_mtimespec` in `lib/std/c/posix/sys-stat.cicili`, which 2.12.2's `time_file/2` needs -- an older Cicili stops at `unknown member: st_mtim of type: stat_t`; 3.2.0: `realpath` in `lib/std/c/stdlib.cicili`, which 2.11.5's needs; 3.1.0: `(cold)`, which 2.11.2's growths need -- an older Cicili stops at `unknown symbol: cold`; 3.0.0: a float literal is a double, every digit of it; 2.0.1 and 2.0.2 let `->` and `=>` through any call; 2.0.0 split `(inline)` and `(weak)`, which 1.10.7's reader needs) |
| `../ZiguratIP` | the database; RUN time and `make schema` | the owner's |

**cicili is frozen**: no edits, commits, pushes, branch changes or `git add`.
A problem that traces to the transpiler gets a diagnosis and a proposed patch,
not an applied one (the owner let six in by name: 2.0.0's split, 2026-10-11,
2.0.1's and 2.0.2's arrow through a call and 3.0.0's double literals,
2026-10-12, 3.1.0's `(cold)`, 2026-10-23, and 3.3.0's file times with its
suite's skips for an absent libpq or libtorch, 2026-10-28: "fix Cicili").
The SHA above is an observation, not a pin -- the owner moves cicili; check it
with `git -C ../cicili log --oneline -1` when a build behaves oddly, and
correct the row rather than trusting it.
**The builds take the last Cicili commit from a copy, and the checkout is not
pulled** (the owner, 2026-10-28: "No pull cicili. Rebuild all with last Cicili
commit"): `git clone --no-hardlinks --no-checkout ../cicili ../cicili-9b825b7`
and a detached checkout of the commit there, the clone reading the objects the
checkout already fetched (a checkout that lacks the commit fetches it first).
`CICILI` names the copy, and `CL_SOURCE_REGISTRY="$CICILI/:"` must name it too,
an absolute path whatever the box -- cicili.lisp
loads the system with `asdf:load-system`, and `~/common-lisp/cicili`, the box's
link to `../cicili`, answers first: without the variable a run from the copy
said `--version` 3.1.0, the checkout's system under the copy's script, and
2.12.2's build stopped at `unknown member: st_mtim`.

**ZiguratIP is the owner's.** It was unfrozen for engine fixes
(`TCP_NODELAY`, the unmap resume mark, rollback-on-disconnect, the streams
guard's writer preference, the page list, the chunked grow, the commit clock
settle, the open's hexmap read a page at a time -- 1.0.1; a row's chain
read inside its page's hexmap slice, so a reader whose mapping a writer
shrank under it takes no SIGBUS -- 1.0.2). After touching
it: rebuild it, then `make schema` here. A change to
`MVCCS-cicili/mvccs-lib.cicili` also rebuilds cocolog's embedded engine,
transpiled from the same file through the `embed/mvccs-lib.cicili` symlink.
`make schema` writes cocolog's Parsi objects into `$ZIGURATIP_HOME/ld` and
the server writes `$ZIGURATIP_HOME/data`; neither dirties the ZiguratIP repo,
so `git status` in it should stay empty -- verify that it does.

## Build

```sh
export CICILI=/path/to/cicili                    # a Cicili checkout, for sbcl
export ZIGURATIP=/path/to/ZiguratIP              # a BUILT ZiguratIP checkout
export ZIGURATIP_HOME=$ZIGURATIP/home
make              # the client and the ONE cocolog binary, embedded store linked in
make EMBED=0      # the same binary without the embedded store: no ZiguratIP
                  # needed, --embed refuses by name, everything else unchanged
make schema       # compile the Parsi objects into $ZIGURATIP_HOME, $ZIGURATIP/home
                  # unless set (and copy the emitted tables into
                  # $ZIGURATIP/MVCCS-cicili/generated/)
make modules      # every loadable module buildable here; SKIPPED, by name, for the rest;
                  # and library(flow/chart)'s tables (sh tools/flow/build.sh, git-ignored)
make test         # the suite -- ask first
make lint FILES=x.pl            # cocolint over a file
make docker                     # BOTH images, every time (the owner's rule): cocolog with
                                # no optional part and no Python, and cocolog:ray-torch-numpy
make docker-save                # each as dist/*.tar.gz with dist/SHA256SUMS
sh tools/cloud/docker-build.sh  # the same two images on a Claude Code session's Linux box (below)
sh tools/lexicon/build.sh       # the reasoning lexicon from WordNet 3.0 (committed)
sh tools/tagger/train.sh        # regenerate generated/ and model.rows (committed)
```

* **`make` needs a BUILT ZiguratIP** unless `EMBED=0`: the embedded store is
  part of the binary and links `libCore` and `libStreamIO`. A missing checkout
  fails in Cicili with `FILE-DOES-NOT-EXIST … embed/mvccs-lib.cicili`, a
  symlink `embed/build.sh` made -- a stale one is not repaired by `make`;
  re-run the script or delete it.
* **Where `$HOME` is not where the checkouts are** (a container), set
  `CICILI` and `ZIGURATIP` explicitly; every `build.sh` defaults to
  `$HOME/cicili` and `$HOME/ZiguratIP`.
* **A heavy lib file is pieces of one translation unit** (2.16.1):
  lib/solve.cicili is eight files (the journal went into solve-journal in
  3.0.0, when the head had grown back to 3 154 lines), lib/kb.cicili four,
  lib/builtins.cicili three and lib/term.cicili two, each piece an `impl-`
  generic of its own,
  emitted right after the one before it by cocolog.cicili and by every test
  binary that emits the head (lib/builtins.cicili's pieces by cocolog.cicili
  alone). The head keeps the tables, the macros and every declaration, and a
  function calls only what an earlier piece defined or the head declared. A
  new piece goes into each of those lists in its place: a test binary that
  misses one has its functions declared and never defined, which Cicili
  stops at. The split moved code and nothing else -- the binary built
  before and after it is the same, byte for byte, and the C differs only in
  Cicili's numbered block comments (`/* let1351 */`).
* **Debian's SBCL 2.2.9 starts with a 1 GB heap, which a build of cocolog
  exhausts** (a heap-exhaustion report from Cicili, midway). Since 1.10.28
  `tools/cc/sbcl` is the `sbcl` every build step runs (the Makefile's Cicili
  step, `env.sh` for each `build.sh`, `test/run.pl`): it hands the real
  sbcl 4096 MB when its default is smaller (`COCO_SBCL_HEAP=N`; a
  `--dynamic-space-size` given is obeyed). **It must not take `tools/cc`
  off PATH** for the sbcl it runs, as the wrappers do before they exec the
  compiler: the Cicili inside compiles by naming `gcc`, and its first
  version built cocolog with Ubuntu's gcc (the tell, `readelf -p .comment
  .libs/cocolog.o`). **It passes by another checkout's shim** (3.0.3): with
  two checkouts' `tools/cc` on PATH -- a worktree's `make` from a shell that
  sourced the other's `env.sh` -- each took the other for the real sbcl, and
  the two called each other hundreds of shells deep before the build began;
  a `sbcl` that carries the shim's first comment line is skipped.
* **Everything is built by clang** -- the client, the interpreter, the
  embedded store, every module, ZiguratIP's libraries and server, and the
  Parsi objects the server loads -- because cocolog links ZiguratIP's C++
  and `dlopen`s modules into one address space, and the owner's rule says so.
  `tools/cc/` is the answer (`tools/cc/README` the long version):
  - Cicili names `gcc` (and on Darwin `clang`) outright and takes no
    override, so the build puts `tools/cc` first on PATH, where shims hand
    over to the two wrappers, `cc` and `cxx`, and the wrappers take
    `tools/cc` off PATH before they exec the compiler by name
    (`coco_path_off`). Until 2026-10-15 only the Darwin shims took it off,
    and every compile by `gcc`, `g++` or a module's `$CC`/`$CXX` went
    through a wrapper twice, each flag twice -- the objects byte for byte
    the same. `tools/cc/env.sh` does it for a shell; `test/run.pl` does it
    for the test binaries.
  - `clang++` alone borrows libstdc++ from the newest gcc it finds, which may
    have no headers (`'string' file not found`); `tools/cc/cxx` passes
    `--gcc-install-dir`.
  - **On x86-64 both wrappers pad every jump off a 32-byte boundary**
    (`-mbranches-within-32B-boundaries`, from `coco_arch_flags` in
    `compiler.sh`, on a command that compiles and never on a link alone),
    the owner's choice of 2026-10-08 -- see Measuring. ZiguratIP's and
    coco's copies of `tools/cc` do not do it yet.
  - `CICILI_CC`/`CICILI_CXX` choose WHICH clang (Apple's, `clang-18`); the
    install scripts refuse a compiler that is not clang.
  - **The Parsi objects take their compiler from `ziguratip.conf`**
    (`COMPILER/CPP`, `clang++` now), not from `tools/cc`: `make schema`,
    ZiguratIP's System and demo objects and coco's all go through it, and
    `parsi/build.sh` compiles with a `clang++` copy of a configuration that
    names anything else (ZiguratIP's committed one said `c++`). parsi
    leaves each object's generated C++ in `home/tmp` and its two command
    lines at the head of the `.out` beside it, which is how the objects
    were rebuilt as they stood.
* **`sudo sh install/install-linux.sh` installs the packages as root and
  runs the rest as the calling user**, in that user's home: Quicklisp and
  `~/common-lisp` are found through `$HOME`, which sudo makes `/root`.
* **`?=` does not work for `CC`/`CXX`**: make gives them built-in values of
  origin `default`. Test `ifeq ($(origin CXX),default)`. The tell is
  `readelf -p .comment` naming gcc.
* **Cicili treats compiler chatter as FATAL**, so every target carries
  `-Wno-parentheses-equality` and `-Wno-dangling-else` in its own
  `:compile` list (the transpiler emits `while ((x == 0))` and unbraced
  else-if chains); C++ targets add `-std=gnu++17` (Apple clang defaults to
  C++14) and `-Wno-deprecated-declarations` (Apple marks `sprintf`). The
  error is an `Unhandled SIMPLE-ERROR` whose text is a warning.
* **Docker on a Claude Code session's Linux box**: `make docker` does not work
  there as it stands. `sh tools/cloud/docker-build.sh [plain|full|both]` builds
  the same two images under the same tags from this Dockerfile, which it
  derives a copy of and never edits, and smoke-tests them with no network
  (`smoke IMAGE` runs the checks alone, `save` makes `make docker-save`'s
  tarballs; its header has the whole story). What bites:
  - **The daemon is not running at the start and dies with the VM**, which
    restarts at every idle gap between turns and takes a build with it: keep
    the turn active while one runs.
  - **The only way out is the session's HTTPS proxy and its CA**
    (`/root/.ccr/README.md`), and **both change at every restart**; the script
    reads them live. A container cannot reach the proxy, so the build is
    `--network host`, and **the auto-mode safety check refuses that as a
    containment escape until the owner says so in the chat** ("go-ahead for
    docker build --network host", 2026-10-01): ask first, never retry it in
    pieces.
  - apt goes over https through the proxy, and Quicklisp (HTTP only) is
    replaced by a stand-in that loads the Lisp libraries of the box's
    `~/common-lisp`: the one way the image differs from a Mac's.
  - A container that runs `xvfb-run` (the ray case) needs `docker run
    --init`: as PID 1 the script waits for ever for the X server, and the case
    never starts.
  - The plain image takes 6 minutes with apt's cache warm and is 1.24 GB; the
    full one 9 minutes and 3.05 GB.
  - **A release's images come from the `Docker images` workflow**
    (`.github/workflows/docker-image.yml`), which the owner starts by hand
    (Actions, Run workflow; inputs `tag`, `ref`, `attach`): on a GitHub runner
    it runs `make docker-save`, smoke-tests both images with no network and,
    with `attach` on, uploads them to the DRAFT release of the tag. **The box
    cannot make, edit or publish a release, or attach a file to one** (HTTP
    403, "not permitted for this session type"): the owner makes the draft,
    pastes its notes and publishes it. The tag is made at that publish, at the
    tip of master, so master stays still from the build to the publish (the
    `publish` job refuses a moved target). Prove a changed workflow with a run
    with `attach` off. `COCOLOG_ROOT=DIR` with `SAVE=1` still builds a
    commit's images here, but they are a different build of the same source,
    not the release's files.
  - **Read an action's version from its repository, never from memory**: its
    `action.yml` at the tag names `runs.using` (`node24`).
    `download-artifact@v6` still ran on Node.js 20, and the first run's three
    notices named the `@v4` actions.

## The version

`cocolog --version` answers on stdout from ONE place, `coco_version_text` in
`cocolog.cicili` (a `#define` would be invisible to Cicili). **The patch is
the default**: bump it for every change to the binary or to a library other
than `library/reasoning/` (which has a number of its own, below), in the
same commit, never afterwards. A minor (something new reachable from a
program) or a major (a program that worked stopping) is PROPOSED with what
changed observably, **and the owner's rule of 2026-10-20 is that the
version proposed is USED** -- set it in the source and commit it with the
change; do not wait for a separate answer. **A documentation-only commit does
not bump** (there is no new binary for the number to describe); say "cocolog
stays X.Y.Z" in its message. `--help` goes to stderr. `test/argv.pl` pins the
shape of the answer, deliberately not the number.

**The reasoning library has a version of its own.** It carried cocolog's
number through 1.13.3 and has its own from there, starting at 1.0.0.
`reason_version/3`, a fact at the top
of `library/reasoning/reason.pl`, is the ONE place; `reason_version/1` answers
it as an atom (`'X.Y.Z'`). A change to anything under `library/reasoning/`
(the code, `corpus/`, `lexicon/`, `generated/`, `model.rows`) bumps THAT
number, in the same commit, and not cocolog's; a change to the binary or to
any other library bumps cocolog's; a commit that changes both bumps both. The
rules are the same ones: the patch is the default, a minor or a major is
PROPOSED and (the owner's rule of 2026-10-20) used by the proposer, a
documentation-only commit does not bump
(say "reasoning stays X.Y.Z" in its message), and a message names the number
that moved (`reasoning 1.0.1`, `cocolog 1.13.4`). Before a bump read master's:
`git show origin/master:library/reasoning/reason.pl | grep -E '^reason_version\([0-9]'`.
`test/reason.pl` (section `version`, four arms red) and lesson 43 pin the
shape of the answer, deliberately not the number.

**Two lines of work bump the same number**: the owner's `master` and the
`reasoning-foundation` branch (the translator's sample loop) each spent
1.8.31 and 1.8.32 on different things, and the tree that joined them took
1.8.35. Before a bump, `git fetch` and read
`git show origin/master:cocolog.cicili | grep coco_version_text`; a bump taken
from the local value is a guess about where the other line has got to. A
merged tree that holds both lines' changes takes a number neither had. After
1.13.3 the sample loop's changes to `library/reasoning/` spend the reasoning
number, so the two lines meet on cocolog's only where both change the binary
or another library.

## Running a program

There is one binary; the knowledge-base arrangement is a runtime option:
`--local` (default), the server (`--kb`, `--host`, `--tcp [PORT]`, 2160),
`--tls [PORT]` (2160, binary protocol over TLS), `--http [PORT]` (80, Zeytun),
`--https [PORT]` (443), `--embed [DIR]` (`./KB` by default; a directory named
like a verb is written `./run`). There is no `--store`. `--port N` is a silent
alias for `--tcp N`; nothing in the tree spells it. `--tls` and `--https`
together are refused. TLS takes `--cacert`, `--capath`, `--cert`, `--key`,
`--key-pass`, `--insecure`.

* **`-s FILE` is `use_module(FILE), main`**, so the file's clauses are muted
  like any module's and never written through; **`run FILE GOAL` CONSULTS**,
  and consulting writes into the knowledge base. Under `--local` the two look
  identical; under a real store they are not. So are the writes of the goals
  an `-s` file's load runs (directives, `initialization(G)`), while
  `initialization(G, main)` is the program and writes through. A halt during
  any load commits what was written through before the process ends (the
  store's `on_halt`; until 1.8.57 it kept nothing). `-s` also puts
  `library(main)`'s `main/0` first where `run` puts the file's.
* **`consult/1`, `load_files/2` and `[File]` as goals CONSULT** (2.13.0,
  SWI's; `lib/library.cicili`, a Coco half over `'$lf_file'/2`), as `run`
  does: written through, the file's clauses from last time replaced. A
  module the files are loaded into is passed by (3.48.0, one namespace:
  `consult(user:F)` reads F), and `[File]` is swipl's two clauses over
  consult/1 with their meta_predicate, `[user:a, b]` consult/1 of
  `user:[a, b]`. Their
  `if(not_loaded)` and `must_be_module(true)` are the module loader's, as
  are `library(X)`. **The store keeps the files read into it** (`loads`,
  their real path and `time_file/2`, noted before the read by every host's
  consult too, `coco_library_note_load`): `if(changed)` and `if(exists)`
  read a file again only when it is NEWER than that time (swipl's; through
  2.13 any other time, older too), and ensure_loaded/1 of a file the store
  holds loads nothing -- through 2.12 it loaded a module beside it, every
  clause twice. **A file loaded as a module is READ AGAIN AS THAT MODULE**
  (2.14.0, swipl's reload; `lb_reread`) by consult/1, `[File]` and
  `if(true)`: muted as its load was, its clauses owned by its real path
  (`coco_consult_owner`, the registry's `real` and `time`), each held once.
  **A forget takes only the clauses of the store's own mute**
  (`coco_pred_forget_from`), so a muted re-read never takes a written
  clause and a consult never a module's. **A completed read drops the
  file's clauses from every predicate its new text no longer defines**
  (`coco_consult_forget_rest`, a consult's and a module's alike): a dropped
  predicate raises existence_error, as swipl's. **A file read again puts
  its clauses in swipl's order** (2.14.1, `coco_reload_begin`; through
  2.14.0 after any the program asserted): a pointer from the predicate's
  first clause, each new clause where its variant stood (the file's old
  one, or an asserted one, which becomes the file's), else in before the
  pointer; another file's clause and what the pointer passed are no
  candidates, and a first read appends. **The hosts say whether the store
  read the file before** (`coco_consult_again`'s AGAIN, from `loads`), as
  swipl decides it per file: in a re-read, a predicate new to the file is
  placed too. A muted read adopts no asserted clause (stated). A call open
  on the predicate keeps its view: an insert it would see moves the
  clauses after it (`coco_reload_relocate`, `coco_frames_on` act 3). The
  registry keeps the old texts (a stated leak). A single `[File]` is
  consult/1 of it, so a missing file raises, and the toplevel's `[F].` and
  `consult(F).` are the goals (through 2.13 it consulted beside the
  module, every clause twice). **The goal unmutes the store around its own
  read** (`lb_load_file`): inside a module's load -- an `-s` file's
  initialization/1 -- the store is muted, and a muted consult kept no
  origins, so a second consult appended (`[1,1]`). **What a consulted
  file's directives load is in the store when the consult returns**: since
  3.6.0 each directive's load runs at the directive (the bullet on load
  directives, below); 3.4.0 loaded what they had registered after the read, and through
  3.3.0 a goal after consult/1 found its predicates unknown. **The
  table is the process's, not the database's**: a file
  `run F` wrote into a store, loaded by a second process as a module (`-s
  F`, ensure_loaded/1), is there twice, the rows beside the module
  (`[1,2,1,2]`, as through 2.12). Hiding those rows at the fetch would
  delete them at the next whole-predicate write.
* **A load looks for a file where swipl's does** (3.4.0, `lb_resolve` in
  lib/library.cicili, '$chk_file'/5's order): an absolute name as it is, a
  relative one first in the directory of the file being loaded -- while a
  load reads one, when source_location/2 answers (`sloc_file`) -- then in
  the working directory; a goal after the load and an initialization/1
  goal look in the working directory alone. In each place `.pl`,
  `.prolog`, then the name as it is (through 3.3.0 the name, then `.pl`,
  the working directory alone), and never a directory. A spec is an atom, a
  string, digits, a list of codes (one name: `"file"` is codes by default,
  so `[123]` is `{`, where swipl's is a list of one file) or swipl's
  `Dir/File` path; any other list is a list of files -- use_module/1,2 and
  ensure_loaded/1 decline it to their Coco half (`'$lf_mods'/1`: each
  error printed, the next file loaded), a directive walks it
  (`lb_directive_hook`). **A file is named by its ABSOLUTE PATH** -- `.`
  and `..` folded, no link resolved (`coco_f_normalise`, `lb_absolute`) --
  in every load's reports and in source_location/2, the hosts' `run FILE`
  and `consult FILE` too; the store's keys stay realpath's
  (`coco_consult_again`'s oid), so a store made before reads the same. **A
  module is registered under that path**, so the same name beside two files
  is two modules (through 3.3.0 one, and the second loaded nothing). As
  goals, use_module/1,2 and ensure_loaded/1 raise swipl's errors --
  existence_error(source_sink, Spec), instantiation_error, a number's
  type_error(text, N) from is_absolute_file_name/1, a directory's
  existence_error(file, Spec) with context(_, directory(Dir)) -- where
  through 3.3.0 each was `cocolog_error('use_module: ...')`. Not swipl's:
  it names a directory by the first path it met it through (pl-os.c's
  canonicaliseDir, by device and inode), cocolog by the path given, so
  test/files/load_paths.pl reads the link before its target.
* **`:- include(File).` reads the file where the directive stands** (3.5.0,
  swipl's; the include branch of `coco_consult_owned` in
  lib/kb-consult.cicili, the file found by lib/library.cicili's `lb_include`
  through `coco_include_hook`, and a goal of the load's like any other
  directive while no hook is installed, as in a test binary): looked for as
  a load looks, beside the file being read first. Its clauses are the
  including file's, owned by its oid and `seen`, so a reconsult replaces
  them and drops a predicate only they defined; its initialization goals go
  to the whole load's end (`up`), each reported at the file it stood in
  (`coco_initgoals`' `files`); its reports and source_location/2 name the
  included file and its lines. **A spec that names nothing it can read ENDS
  THE LOAD**, as swipl's: its ball -- existence_error(source_sink, Spec), a
  list's too, instantiation_error, a number's type_error(text, N), a
  directory's existence_error(file, Spec) -- on `lball`, raised out of
  consult/1, and an `-s` script's load says `Prolog initialisation failed:`
  and exits 1 (`script_load_ended` says any ball so since 3.5.0; through
  3.4.0 an error(_, _) was `-s main:`, exit 2). An include of a file open on
  the way down to it, or sixty-four deep, is refused with
  error(permission_error(include, source_sink, Spec), _) (swipl reads it
  again for ever). As a goal include/1 is an unknown procedure, as swipl's.
  **A list is no name to include/1** (3.13.1, `lb_include`), a list of codes
  among them: `include([0'a])` is ``source_sink `[97]'``, as swipl's
  (through 3.13.0 it read `a.pl`), and so is `include("a")` while
  `double_quotes` is `codes`, where swipl's `"a"` is a string; every other
  load keeps reading a list of codes as one name. **library(flow/chart) and
  cocolint read an included file where its include stands** (3.13.1;
  `flow_include_file/3` in library/flow/read.pl, `cl_include_file/3` in
  tools/cocolint/lint.pl, each absolute_file_name/3 relative to the
  including file's directory): the chart's clauses, kinds, findings and
  promises take the included file's lines (`inc.pl:2` for a place in
  another file), and cocolint lints a file with the imports of the whole
  unit of includes it stands in, a listed file another listed file includes
  linted inside that unit. Not swipl's: an include of a library cocolog
  compiles in (`library(lists)`) is existence_error, where swipl reads its
  source.
* **A load reads its file in swipl's encodings** (3.58.0;
  `coco_source_text` in lib/term.cicili, test/files/encoding.pl): a BOM at
  the file's start (UTF-8, UTF-16 either way round) names its encoding and
  is taken off, else UTF-8; load_files/2's encoding(E) reads it in E
  whatever the BOM says -- `bom` the BOM's, and nothing of a file with
  none, `default` nothing, as swipl's --
  checked once the file is found and is to be read (`lb_enc_option`, the
  machine's `lenc`); `:- encoding(E)` reads the rest of its file in E from
  the byte after its full stop (the reader's `fend`, `coco_reader_retext`),
  `bom` changing nothing there, a name that is none ending the load with
  set_stream/2's error; an included file is read in the encoding of the file
  that includes it. The names are swipl's (`*coco-encodings*`: its MIME
  ones too, `text` UTF-8 where swipl's is the locale's). **The text a consult
  reads is UTF-8 whatever the file was**: `coco_text_cook` decodes the bytes,
  a NUL as C0 80 so the text stays a C string (the lexer reads it as the code
  0 inside quotes and after `0'`, and a syntax error's column counts it as
  one byte, `coco_raw_col_byte`), and a consult starts in the class its text
  was decoded from (`lcls`; a module's registered text keeps it, `cls` in
  lib/module.cicili), so a switch writes the rest back in that class and
  decodes it in the new one (`coco_consult_recode`). **Only a text that
  holds a NUL asks for one inside quotes**: `coco_text_cook` says so, the
  class's bit 16 carries it to the consult and `coco_reader_init_nul` to the
  reader (`nul`; an include's reader always asks), and the quoted loop is
  two copies of one DEFMACRO, `coco-lex-quoted-loop`, its NUL tested with
  EQL as it expands -- Lisp's 0 is true, and `(IF NUL ...)` gave both copies
  the test, 96 514 instructions a start. **A new reader of a
  source file goes through `coco_source_text`** and hands its class to the
  consult, or a BOM is its first clause's bytes and a switch decodes twice.
* **A load directive's load runs AT THE DIRECTIVE** (3.6.0, swipl's;
  `lb_directive_one` in lib/library.cicili gives `coco_library_load` an
  engine of its own for a module's init): `:- use_module(F)`, `:-
  ensure_loaded(F)` and a list of files read F into the store at once, its
  directives and initialization/1 goals before the next clause of this
  file. Through 3.5.0 a directive registered the module and left its read
  for the next ask, so its directives ran after this file's next goal, a
  ball that ended the read was thrown at that goal (its ERROR and Warning
  naming a directive that had nothing to do with it), and a load that
  failed was read again at every ask. **A ball that ends the nested load is
  the directive's**: an error(_, _) its ERROR at the directive's place and
  the Warning that it failed, and this file goes on; any other ball ends
  this load too (the hook's -5, `coco_directive`'s 4, a list's walk stopped
  there), and an `-s` script says `Prolog initialisation failed:` over it
  and exits 1. A module whose read a ball ended is marked `failed`
  (lib/module.cicili) and every store made after passes it by -- the next
  ask's, a thread's, run_isolated/2's -- until a read reaches its end.
  **A FILE IS LOADED ONCE A READ OF IT DEFINED SOMETHING**, as swipl's source
  file is made: a clause or a grammar rule; a dynamic, discontiguous,
  multifile or meta_predicate declaration; module/2; an initialization/1
  goal put off; an include of a file that is there, though it holds
  nothing; a load of a file that is there, whatever that file holds,
  library(lists) too (`lb_defined`, where the load finds its file). Not a
  goal, op/3, a flag, assertz/1, thread_local/1, public/1, an include or a
  load of what is not there. A file whose reads defined none of those --
  goals alone, or a ball before anything -- is read again by the next
  ensure_loaded/1, use_module/1,2 or load_files/2 if(not_loaded) that names
  it; a ball after a clause leaves the file loaded. The count is the
  machine's `ldefs`, and **each read counts its own** from 0 and puts the
  outer read's back after (`lb_consult_file`, `lb_load_again`,
  `coco_module_load`; the hosts, the outermost reads, start each file at 0,
  and `run a.pl b.pl` is the check): a library read into the store on the way
  -- the preloaded modules at a `run` file's first directive -- is no
  definition of the file. A consulted file's `loads` entry keeps `defined`
  and `reading` (`coco_store_load_read`, asked by `coco_store_load_done`;
  `coco_store_loaded` still says the store read it, for a re-read's
  order), a module its `reads`, `reading` and `defined`
  (`coco_module_read_begin`/`_end`, `lb_mod_unloaded`); a read under way
  is loaded, so a load of itself inside it reads nothing. The next load that
  names such a file reads it again -- `lb_load_known`, `lb_load_found` (by
  its real path, so a link's name finds it), `lb_load_file` whatever
  load_files/2's IF says. test/files/source_files.pl holds 105 lines of it
  to swipl. **The directive vouches for the collector**
  (`dgc`): `coco_directive` writes the spec's text before the hook and hands
  the load the vouch its consult gave it, and a list's walk registers its
  cursor around each load (`lb_directive_hook`). **A read that may register
  a module takes the registry by index after it** (`coco_module_load`,
  `lb_load_again`): a directive in it can move the array. Not swipl's
  (COMPAT.md): one namespace, so what a failed module read before the
  failure is callable unqualified, where swipl's stays in the module, and
  use_module/1 of a file with no module/2 loads it, where swipl's refuses
  it; a store made after passes a failed module by, where swipl's thread
  sees what it read; and a file named through a link is that file, where
  swipl's is another.
* **A load asks the program's term_expansion/2 and goal_expansion/2**
  (3.14.0, swipl's; `coco_consult_xcall` in lib/kb-consult.cicili, the
  Prolog half in lib/dcg.cicili): each term read where the file is taken --
  a directive too, never `if/elif/else/endif` nor a term skipped -- before
  a grammar rule is translated, through the load's goal hook (kind 0, a
  directive's); what it gives is read in the term's place, a proper list
  its terms and `[]` none; an error(_, _) it raises is reported at the
  term, `ERROR: F:L:` and its message, and the term dropped; any other
  ball ends the load, as a directive's does. A loaded file's start is
  `begin_of_file` when a hook stands before the first read, its end
  `end_of_file` (an included file's neither), each dropped unanswered, and
  an `end_of_file` read or given ends the file there. goal_expansion/2 is
  asked of each clause's body and each directive's goal by
  `'$expand_clause'/3`, to a fixed point with no limit (swipl's: a hook
  that never settles loops), through the control constructs and the
  system's meta-arguments (`'$expand_meta'`), never of a yall lambda. The
  hooks are asked again after a directive and after a clause of one
  (`xbits`, `coco_xhook_load`); goal_expansion/2 counts every clause but
  those a library's own text gave it (3.49.1, the store's `xlib`, the
  reads under `noexp` noted by `coco_assert_from`), so library(yall)'s
  `system:` clause is no hook and an `-s` file's or a module's is --
  through 3.49.0 a muted clause counted only where the predicate's first
  was a program file's, and yall's is first. **The expansion's terms
  live above `mark`**, which moves over them and back after them
  (`omark`) only where nothing raised it since -- a directive's read of
  a global raises it over the copy (the gcache's fill), and a plain
  directive's copy outlives its term that way, as it always has: **never
  set the consult's `mark` back to a value saved before a goal ran**
  (the first cut did, and `:- nb_getval(K, _).` left the next read a
  wound-back copy, `nl` where `f([1,2,3,4,5])` stood).
  The hook's trail entries are dropped to its mark (a global's sentinel
  among them, which would name cells the term's end winds back), and no
  goal of theirs collects (`vouch` 0). **The program's hooks never reach
  cocolog's own libraries**: a compiled-in module's text (`file` nil) and
  the preloaded ones (`coco_module_set_noexp`, in `coco_library_preload`)
  are read with the store's `noexp`, each module by its own mark and
  never by the read it is nested in (dcg_basics' `:- use_module` reads
  the libraries after it inside its own read), though under `run` they
  are read at the program's first ask, after its hooks; a library on the path
  loaded after a hook is expanded, as swipl's. **prolog_load_context/2**
  answers `file` and `term_position` from the machine's `sloc_file`,
  `sloc_text` and `sloc_off`, `source` from `sloc_src` (the loaded file
  where an include stands), `directory` the file's, and since 3.51.0
  `module` from the read's `ssu_mod`, `term` from `sloc_tp` (the term as
  read, while a hook runs; `[]` in a directive's goal) -- or since 3.52.0
  from '$term''s box, which expand_term/2 sets, where it was written in
  the goal in hand (its `wclock` past `gvb_hook0`, the clock where that
  goal began: a box set before is no term of this goal's) --, `variable_names`
  from the reader `sloc_rd` names, built when asked (a directive's goal,
  which may collect, holds the reader's variables as a root; a file's
  start keeps the reader around the load, swipl's begin_of_file setting no
  '$variable_names') and `reloading` from `sloc_reload`: **a new site
  that sets `sloc_file` for a goal sets `sloc_src`, `sloc_text`,
  `sloc_off`, `sloc_tp` and `sloc_rd` too**, as the directive's and the
  hook's do. A grammar rule a load translates makes its predicate a
  non-terminal (`pattrs` 16, `coco_pred_nt_mark`), as non_terminal/1 does,
  and expand_term/2 gives a rule its `:- non_terminal` only where the
  predicate is none yet, as swipl's (COMPAT.md has what is not swipl's).
  **expand_term/2's term, or what term_expansion/2 gave, is swipl's
  expand_terms/5's** (3.47.0, `'$expand_terms'/3`): a list is its terms,
  each expanded as a term is, a rule with its declaration, a list in it
  spliced, a partial or improper one type_error(list, L).
* **A program's own arguments come after `--`**:
  `current_prolog_flag(argv, [Exe|Tail])`; `os_argv` is the literal command
  line; `executable` is the binary's path. Those three, `double_quotes`,
  `text_units` (1.13.0), since 2.0.0 `bounded`, `max_integer`,
  `min_integer`, `max_tagged_integer` and `min_tagged_integer`, and since
  2.2.2 swipl's four float flags and `float_min`, `float_max` and
  `float_max_integer`, since 2.16.0 `verbose` (`normal`), since 3.15.0
  `optimise_unify` (`true`), and since 3.32.0 `stack_limit` (1073741824),
  are the only flags answered; set_prolog_flag/2
  sets `double_quotes`, `text_units`, `generate_debug_info` (swipl's
  booleans, the read's own since 3.27.0: what it defines after the flag is
  false hides its children from the tracer; taken and unused through
  3.26), the float flags, `verbose` (any atom, the process's: `silent`,
  swipl -q's, quiets print_message/2's informational and banner kinds) and
  `optimise_unify` (swipl's booleans, the process's: whether a store moves
  the unifications that begin a body into its head) and `stack_limit` (the
  machine's and the process's default; the bullet on the stack limit,
  below), as a goal since 2.2.2, and refuses every other flag in swipl's
  words. `library(main)` parses the tail.
* **Exit status is SWI's**: 0 proved, 1 failed silently, 2 threw; `halt(N)`
  is N from `-s`, `run` and `query` alike -- **and from a nested search**
  (3.57.0, as swipl's halt/1 ends the process from whatever C called
  Prolog): findall/3 and what is built on it (forall/2, aggregate_all/3,
  bagof/3, setof/3), with_output_to/2, `~@`, a portray goal,
  call_limited/3 and call_metered/4, a cleanup a cut ran (the host's, the
  REPL's, with_output_to/2's) and a directive's search. The search hands
  its `halted` and its code up (`coco_halt_up`), the builtin answers 2
  having bound nothing, and the outer engine stops at its next step, each
  engine out to the host's in turn; catch/3 takes no halt and no cleanup
  runs for one, as swipl 9.0.4's (test/script.pl's three halt sections,
  22 checks held to swipl). What was put out stays out: the text a write
  made before its portray goal halted, a `~@` goal's where format holds
  none for a column, never a capture's. Under trace halt/0,1 has no Exit
  port, and the builtin whose search halted no Fail port (test/trace.pl's
  own lines). Through 3.56.0 the halt ended the search alone: findall/3
  went on with the answers it had, and with_output_to/2's goal failed
  (cocolint's card row H1 said so, retired with it: 24 rows). **A
  new starter of a nested search hands a halt up through `coco_halt_up`**,
  or the program goes on past it -- all but `'$trace_window'/4`'s run,
  which reports it as how the run ended, `halt(Code)` (library(flow/debug)).
* **An error nothing caught is followed on stderr by its backtrace**
  (1.10.17; TRACING.md): `ERROR: In:`, the goal that raised, then each
  engine's goals left to run -- or, under `--backtrace` (trace 3, which
  prints nothing) or `--trace`, every call as `[Depth] Goal`. A load's
  directive and initialization reports carry one too. `--no-backtrace`
  turns it off; a case that holds stderr to the letter either takes the
  backtrace into what it expects or compares the message's lines alone
  (test/engine.pl, test/directives.pl's swipl diff).
* **Raise the server detached**, with its libraries on the path:

  ```sh
  export ZIGURATIP_HOME=$ZIGURATIP/home
  setsid env LD_LIBRARY_PATH="$ZIGURATIP_HOME/lib" \
    "$ZIGURATIP_HOME/bin/ziguratip" > /tmp/zig.log 2>&1 &     # Linux
  ./cocolog --kb main --host 127.0.0.1 --tcp 2160 --timeout 10 list   # check it
  ```

  A plain `nohup … &` from a tool call does not survive the turn. Without the
  library path it dies at once and every database case SKIPs. On macOS:
  `nohup` in a subshell and `DYLD_LIBRARY_PATH`.
  `ziguratip --config=<file>` runs a custom-configured server (TLS mode,
  ports, permissions) without touching `home/etc/ziguratip.conf`.

## The suite

`make test` is `./cocolog -s test/run.pl`; `-- NAME` runs one case. It builds
the seven `test/*.cicili` binaries through Cicili with `--release` (term,
syntax, solve, module, state, zigurat, shared; a build that links the
engine takes about a hundred seconds on the Linux box, solve and its run
105 s on 2.14.1) and runs the 70 `.pl` cases in `pl_names/1`
-- **77 lines**, each with its seconds. There is no `.sh` under `test/`.
**A build has ten minutes** (`build_ceiling/1`), and a failed one names its
exit status, 124 for that ceiling: on the prelude's two minutes a slow Intel
Mac runner stopped the four that link the engine (run 40975575257), and the
line said only `BUILD FAILED`, over a tail ending on clang's command line.

* **A case is `test/<case>.pl`**, run as `./cocolog -s test/<case>.pl` from
  the checkout root with `COCOLOG_LIBRARY` naming this checkout's `library/`
  (the runner prepends it to whatever the caller exported). `main/0` runs the
  checks; `check/3` and `checks_done/0` are `library(process)`'s; **the exit
  code is the verdict**. A line beginning `SKIP` at column 0 skips the case; a
  skipped SECTION says so indented. `test/prelude.pl` has `answer/3`,
  `written/3`, `yes_no/2`, `skip/1`, `scratch/1`, `fixture/2`,
  `cocolog_out/2`, `spawn/2` and `unix_listening/1`. A check is a second process only when it
  genuinely must be (a consult's stderr, a store read back by another
  cocolog, a server, a goal that must be killable).
* **A test binary is green only when it also exits 0** (`binary_verdict/3`
  in the prelude, 2.11.1): through 2.11.0 the runner read its last line
  alone, and a binary that printed GREEN and then crashed was green.
* **A spawned server must be `exec`'d** (`spawn/2` does it), or `proc_stop/1`
  kills the shell and orphans the server, which then holds its port for the
  next run.
* **Wait for a port with `lsof -iTCP:PORT -sTCP:LISTEN`**, never a probe
  connection: a server that accepts N times counts it, and `httpd`'s accept
  loop ends on a failed accept. A socket file the same way,
  `unix_listening/1` (`lsof -U`'s `type=STREAM (LISTEN)`): the file is
  there from the bind, and a connect before the listen is refused.
* **The suite loads `library/*.so` and does not build them**: run `make
  modules` after pulling, or when a module's source is newer than its
  `.so`. A stale `library/tcp.so` predating `unix(Path)` failed tcp, httpd,
  websocket and curl in one run; the modules are build output nobody
  commits, so this is a property of the checkout, not of the tree.
* **`proc_until/3`'s budget is wall-clock** (2.5.0): it reads `get_time/1`
  and ends when the budget has elapsed, not after that many sleeps. The old
  form counted only `proc_sleep`, so `unix_listening/1` -- whose `lsof`
  prints no unix-socket state on macOS -- spent each try's own time on top
  and took ~26 s against its eight, outlasting the ten-second accepts in
  the tcp, websocket and curl fixtures.
* **`proc_run/4`'s deadline is the monotonic clock's** (1.11.0). Through
  1.10.28 each poll was charged its whole 200 ms step though a poll with
  data waiting returns at once with one 4096-byte read: a child printing
  more than ~20 bytes per millisecond of its timeout was killed with 124,
  and `shell/3`'s two minutes held ~2.4 MB of output. A case that went red
  on a big output then is worth running again.
* **A clause has ONE scope**: suffix each check's variables with its number
  and never reuse a suffix. When a goal answers differently inside a clause
  than alone, look for a variable the clause already bound.
* **libc regex `.` matches a newline**: `answer\([^\n]*\)`, not `.*`.
* **`set_prolog_flag/2` is a goal since 2.2.2** (only a directive
  through 2.2.1), so a case can set a flag and put it back; `text_units`
  and the float flags it sets are the process's default as well, which a
  thread or `run_isolated/2` made after it starts with.
* **A section that ends with no red check and no verdict line is a goal that
  FAILED**: suspect a builtin answering 0 where it should raise, a
  `proc_run/4` timeout, or a fixture lesson that lacks a word.
* **The prelude's `shell/3` gives a child two minutes, and a timed-out child
  is killed (exit 124) and hands back only what it printed by then**, which a
  case can read as "nothing found". A step whose work grows with the tree, or
  with the machine's speed, takes `shell/4` with a ceiling of its own
  (`test/lint.pl`'s corpus lint has five minutes, a test binary's build ten,
  `test/httpd-tls.pl`'s certificate ten: an RSA key is a prime search, and
  two minutes stopped it once on GitHub's Intel Mac, CI run 42109468644).
* **A container runs as root**, who writes through a mode of 444: a
  permission check skips by name when `os_uid/1` answers 0
  (`test/stream.pl`).
* **`red: 0` does not mean the suite passed.** Database cases SKIP rather
  than fail with no server -- `zigurat`, `shared`, `tunnel`, `tensors`,
  `zigurat-lib`, `kbs`, `zigurat-tls`, `groups`, `ruler` -- and others SKIP
  for a missing tool (`files` and `trace` want `swipl`, `ray` raylib and a
  live screen, `tensorflow`, `numpy`, `opencv` their libraries,
  `torch-replay` a CUDA toolkit). **`files` wants the REFERENCE swipl
  9.0.4** and SKIPs by name on another: 10.x writes a float
  (`9007199254740992.0`), orders a NaN and picks it in max/min, checks a
  float flag and quotes a write differently, so the 9.0.4 answers the cases
  hold would be reported as cocolog's failures. Its `module_context` case
  (3.0.2) builds a fixture module from `test/md5.cicili` with Cicili, as
  `library` builds hoot, and is skipped by name, indented, without Cicili,
  sbcl or a compiler; it also loads `library/thread.so`. **Count the SKIPs
  and run `pgrep ziguratip`** before believing a green run; the number of
  SKIPs is a fact about the machine.
* **CI runs the whole suite on GitHub** (`.github/workflows/ci.yml`, 2026-10-29):
  every push to master and pull request into master (not one that changes
  only the top-level `*.md` or the Docker files), and by hand with Cicili's
  and ZiguratIP's refs, or with the Intel Mac's sbcl built from source
  (`sbcl_from_source`, below). Three jobs, NOT root: ubuntu-24.04 (x86-64, 4 vCPU,
  16 GB) by `install/install-linux.sh`, and two Macs by
  `install/install-macos.sh`, macos-15 (Apple silicon, 3 CPUs, 7 GB) and
  macos-26-intel (x86-64, 4 CPUs, 14 GB), the owner's arrangement. Homebrew
  builds no Intel bottles since 2026-09 and SBCL ships no x86-64 Darwin
  binary: the Intel job pours what the image's own formula data names
  (`HOMEBREW_NO_AUTO_UPDATE`). The image of 2026-08-24 (macOS 26.6.1,
  Apple clang 21) poured every package, sbcl 2.6.7 from its sonoma
  bottle, and the job took 50 minutes, 17 of them ZiguratIP's build (run
  40856551321). An image whose formulas have no Intel bottle would build
  sbcl through ECL, inside the install step's two hours; a run by hand with
  `sbcl_from_source` builds it so before the install, from today's formula
  data (`brew update`; of the rest only sbcl's own outdated dependencies
  upgrade). On that image (run 40868931709) sbcl 2.6.9 had no bottle and
  ECL 26.5.5 poured from its sonoma one; the step took 50 minutes, 33 of
  them `make.sh --xc-host=ecl` and 14 `brew update`'s own (it moved
  azure-cli to a cask and built openssl@4 from source for it, unlinking
  openssl@3, whose opt path the install reads), and the install, the lint
  case and the suite were green on that sbcl, the job 90 minutes. Each
  raises a server
  on 2160, runs the lint case and then `test/run.pl`, and
  `tools/ci/verdict.sh` reads every case's line: a red case, a case with no
  line, or a SKIP outside the job's `allowed_skips` (tensors, the three
  torch cases, tensorflow, ray, numpy, opencv: no library built there; on
  the Macs files and trace too, as no Mac package is the reference swipl
  9.0.4 and the Macs have none) is red. **A case that may now SKIP on a plain
  install goes into `allowed_skips` in the same commit.** Each red case is
  run again alone (its whole output: the runner keeps five FAIL lines, each
  with the indented lines under it, eight at most -- check/3's `got` and
  `want`, test/tutorials.pl's last lines of a lesson: `fail_blocks/3`,
  3.48.3, after run 42461896352's Intel Mac kept `FAIL
  tutorials/library/54-async` alone and the lesson was green alone again --
  the last twenty of a case that did not end on its own RED -- it raised, or a
  goal failed: `raised_tail/2`, 2.14.1 -- and a SKIP's first reason line,
  indented under its case's line, `skip_reason/1`, which verdict.sh names in
  the annotation of a SKIP the job does not allow), and the logs
  are the run's artifact for 14 days.
* **A case sizes a green pool from the world, never with a number.** The
  world has a worker a core and the acceptor holds one, so
  `concurrency(green(N))` wants N + 1 cores and is refused past that
  (`httpd_green_count/1`). Ask `httpd_mode(green, green(W))` and take
  `min(N, W)`. GitHub's Apple silicon Mac has three cores. test/httpd.pl's fixed
  `green(3)` was refused there: the server never listened, and the section
  failed with no FAIL line, because `hit/2` fails when curl does (878b17a).
  `COCOLOG_GREEN_WORKERS=3` gives any box that world. **The world's size is
  `async_workers/1`'s** (2.15.0), never worked out again: lesson 54's
  quantum check took the eighth of eight children to share worker 0, true
  only where the size divides eight, and on that Mac it was a race (run
  41030811820); it starts one child a worker now.
* **A check of what is too deep for the C stack pins the stack's size**
  (3.60.1, test/cyclic.pl's `child_run/3`: every child there runs under
  `ulimit -s 8192`). GitHub's Linux runners give the main thread more than
  8 MB, and 3.60.0's 20 000 levels too deep to read read there (run
  42573674735); a depth that is too deep is too deep for one size.
* **A red run of `test/translate.pl` prints two reports and only the first is
  true**: `main` fails, the engine backtracks into an earlier choice point and
  re-runs later sections over changed lessons. Read up to the first `RED`.
* **A case that passes alone proves the case; the suite proves the contract
  between cases** (a lesson's last line must be exactly `done`; a library
  loaded as a goal after a module set a flag).
* **A new C builtin wants a line in `library/flow/modes.pl`** (`flow_mode/4`,
  or `flow_test/2` for a test; and `flow_binds_all/2` when its success binds
  every argument whichever way it ran, as text made from text does -- ask
  the engine, `atom_length/2` takes any term), and `test/flowchart.pl` holds that table to
  `library/flow/tables.pl` -- generated, git-ignored, and rebuilt only by
  `make modules` (`sh tools/flow/build.sh`), so an old one passes the check:
  `acyclic_term/1` and `cyclic_term/1` (1.10.18) went through two regression
  nets that way, and the first full suite after them ended `red: 1`
  (1.10.19; the lines came in 1.10.20). Rebuild the tables before believing
  the case after adding a builtin.
* **A fixture that has to TAKE a while is timed by the clock, never by a
  count.** 1.8.42-1.8.44 made the engine two to three times faster and
  three cases went red for it alone: a cowork job that had to outlive a
  60 ms wait (it waits on an empty channel now), an httpd page that had to
  outweigh a request's fixed cost (timed in-process, sized to 400 ms), and
  `groups`, whose floor of turns caught fewer steps per proof as designed
  (group b moved to a goal with more search). An httpd page gets
  `page_limit` inferences, a million by default, and past them it is a 500
  -- the old slow page never finished, and nothing checked its answer: **a
  timed request checks its status too.** A change to the engine is gated
  with the modules built and a server up; `make EMBED=0` without them
  cannot run these three.
* **A check of which predicate the clock charged the most takes each
  predicate's least over three runs** (`least_own_top/2` in
  test/flowdebug.pl). The clock reads wall time, and a step the scheduler
  stopped is charged the pause: in one suite on GitHub's 3-CPU Mac msort/2
  was not the most (run 40882388548), and beside six busy loops on four
  cores one run in forty was so. A pause only adds, so the least is the
  predicate's own time. **The same holds of every check the clock or
  get_time/1 decides** (2.14.1, run 40942980399): a crew's speed is its
  fastest of three rounds (test/cowork.pl), and a load mark is the first
  of up to five probes that gives the rule's marks (`unpaused_marks/7`:
  t_r/1's calls are 0.1 ms, a time slice 4 ms, and beside eight busy loops
  15 probes of 30 were paused into a wrong mark, none of the 5 fastest),
  and an inference the clock did not read is one that read 0 in each of
  five runs (test/window.pl, the Mac section).
* `scratch/1` names `/tmp/coco_cocolog_test_PID_SEQ`, and `make_directory/1`
  FAILS (does not raise) on a name that is taken; leftovers in `/tmp` plus a
  recycled PID fail a section silently. Not fixed. After a container restart
  (PIDs start low again) it took httpd-tls, whose `main` calls `scratch/1`
  before it prints a line: the runner showed `httpd-tls    0s`, red with no
  output (2.4.0). `find /tmp -maxdepth 1 -name 'coco_cocolog_test_*' -mmin
  +30 -exec rm -rf {} +` with no case running clears them.
* **Before saying something works**, with the owner's go-ahead: `make test`
  with a server up, read every line, count the SKIPs. A change to the
  knowledge base also wants proving **across processes** -- one cocolog
  writing, a second that consulted nothing reading.
* **The lint case comes BEFORE the full suite, and a red case fixed is
  rerun ALONE** (owner, 2026-10-20): run `./cocolog -s test/run.pl -- lint`
  (or `cocolog -s test/lint.pl`) first, so a card cite the engine edits moved
  is settled before the whole run; and when a case goes red and is fixed,
  rerun that case -- do not run the suite again for it.

## Hazards, each of which has already cost a day

* **A slow suite is usually the server's uptime.** Restart the server first
  (two seconds; check `pgrep -fl 'cocolog -s test/'` so you break nobody's
  run). If a restart does not help, it is the store ageing: deleted rows stay
  under MVCC; `cocolog vacuum` reclaims them (`groups` and `ruler` vacuum in
  setup), or restart on a fresh `data/`.
* **A store wiped under a server that is still dying answers writes and keeps
  none.** `pgrep ziguratip` must print nothing before `rm -rf
  home/data/*`; a clean restart afterwards is the whole cure.
* **Rebuild the Parsi objects after ANY ZiguratIP engine build.** A stale
  `.so` in `$ZIGURATIP_HOME/ld` takes the server down with `symbol lookup
  error`. After an engine rebuild every object there is stale: ZiguratIP's
  `System/` and `demo/` objects, then `make schema` here.
  `nm -u home/ld/*.so` shows who is behind.
* **A red `contention_test` aborts ZiguratIP's `make` after the artefacts are
  built**, and is usually not yours: `writer under readers` is a harness coin
  toss, and a crash shows up a few times in 144 runs. Re-run before believing
  it. (macOS fails `rewrite vs index` -- a recorded, unfixed engine finding.)
* **An index changed in `parsi/01-schema.parsi` comes up EMPTY on a live
  server**, and a `forget` through it deletes nothing. Run `cocolog vacuum`
  right after the restart, before any base is touched. `--embed` rebuilds a
  new index from the rows at its next open.
* **A page and a procedure of the same name are ONE compiled object**, pages
  last; check `parsi/03-pages.parsi` before naming anything in
  `parsi/02-procedures.parsi`.
* **A store is in the writing machine's byte order** and does not travel;
  `byteorder.bin` beside it is checked before open, and a refusal exits 1
  with an empty stdout and the reason on stderr.
* **An embedded store is one process's at a time** (3.0.3, cicilang 0.240):
  the open takes `DIR/lock` with flock(2), its holder's pid in the file,
  held to the process's last close and dropped by the kernel at any exit
  (kill -9 too; a child holds none), and a second process WAITS its turn,
  saying once past two seconds whom it waits for -- seconds of the
  monotonic clock (3.0.4, `ce_now_ms`): counted in 10 ms sleeps, the wait
  ran long on GitHub's Macs, which oversleep, and said nothing before its
  holder let go (CI run 41174870038). Not fcntl's record lock:
  that is the PROCESS's, and any close of the file in the holder gave it
  back, a program reading its own store's files among them (the first cut's
  hole, test/store-lock.pl's `reader`).
  `COCOLOG_STORE_WAIT=S` waits S seconds at most, 0 refuses at once: `the
  store is in use by process N`, exit 1. Through 3.0.2 two processes wrote
  over each other's records -- commits lost (`sequence has no row`), rows
  lost with no error, bus errors, and stores no later process could open.
  **A damaged store says so**: a data file shorter than its hexmap
  describes, or one with no hexmap, is refused at the open, and a torn
  record at its read, `the store in DIR is damaged: ...` (`ce_store_shape`,
  `ce_damage_said` in embed/embed.cicili); a declaration the backend
  refuses raises `resource_error(knowledge_base)` with its reason (it said
  `dynamic: out of memory`). An emptied hexmap still opens empty and says
  nothing -- the engine frees uncovered pages by its rule, which cannot tell
  it from a first commit killed. So several cocologs over one store run IN
  TURN, not at once: library(flow/debug) gives each window's child a copy of
  `embed(Dir)` (J copies at once with `windows=N`), and a `make -j` over one
  store is safe and serial.
* **A clause must fit one page** (65536 on a store made since 1.10.0 and
  ZiguratIP 1.0.0, 8192 on an older one, ~8014 characters there): the store
  sets `clause_max = page - 190 - len(kb)` and `assertz/1` raises
  `resource_error(clause_length)`; a consult reports and goes on. Over the
  wire the client assumes 65536; `$COCOLOG_PAGE_SIZE` says otherwise (8192
  for an older server or store).
* **A writing process rewrites the whole predicate** (the backend flushes a
  dirty predicate wholesale, ~360 bytes of new store per EXISTING row) and
  the old rows stay dead; every later process is slower -- a predicate's
  first call walks its dead rows at ~0.2 us each (1.13.7: five appends of
  one lesson noun added ~10 ms to its 14-17). `cocolog vacuum` after the
  write bounds it. `garbage_collect/0` is unrelated: it compacts this
  process's cell array, not the disk.
* **The first call of a big predicate under `--embed` is a fetch of all
  its clauses**, ~12 k instructions a clause after 1.13.7 (the row walk
  6 k, the parse 4 k): 30-60 ms for a lesson predicate of 10-30 k
  clauses, ~600 ms of a 680 ms translation. Opening the store cost every
  process 0.3-0.7 s through ZiguratIP 1.0.0 (its open read the hexmap a
  byte a chunk); 0.06 s since 1.0.1.
* **An httpd pool fetches every module predicate per request** unless
  `prewarm/1` ran (`httpd_serve/3` calls it): pre-warm BEFORE spawning
  threads. `library(cowork)` deliberately does not -- the rule is the
  fetches recurring, not the threads existing.
* A base written before 1.2.18 can hold a module's own clauses beside the
  program's (duplicate solutions); `cocolog forget NAME ARITY` cleans one
  predicate.
* A `lock wait timeout` today means a LIVE contending writer (or a server
  older than the rollback-on-disconnect fix).

## Measuring

* **A within-run pair or nothing, and even that is coarse.** This box drifts
  ~20 % between runs of one build. Compare two builds in ONE round, back to
  back, alternating or in rotation. Even then, ten rounds settle a ratio no
  closer than about a tenth, and thirty about 5 % (Run X,
  bench/README.md: a round of ten read 2.11.2 at 1.13 times 2.2.5 on nrev and
  2.11.3 at 0.87 of 2.11.2, and the round of thirty after it 1.01 and 0.95).
  A change of a few per cent is settled by its counts (`tools/flow/zero.sh`,
  callgrind's calls per function); the clock only shows that nothing larger
  moved. A ratio under ~3x from medians alone means nothing on the pooled
  rigs.
* **An inference count is not a clock, and a clock is not a count.** Count
  inferences (`statistics/2`, `call_metered/4`) to find a cost, time to
  confirm it; a lookup with its first argument unbound is one call in the
  count and every row in the time. **A count is comparable within one engine
  and not across two**: the engine of 1.8.47 counts 19.5 % fewer inferences
  than 1.8.43's for the same 1762 translations of the sample loop's controls
  (with every text the same; the compiled clause, the deterministic call and
  `is/2` came between them), so a baseline kept from an older binary is
  counted again on the new one.
* **What a step costs** (1.12.2, `statistics(inferences)` differences; the
  constructs are steps too): length/2, nth0/3 and nth1/3 with the index
  given, last/2, reverse/2 of a proper list and atomic_list_concat/2,3 are 1
  in every mode that answers once (C rows; through 1.12.1 a clause around
  '$len', '$nth0', '$rev', '$last' or '$atom_join'/3: 2 to 13), catch/3 that
  exits 3 (the catch, the goal, '$catch_exit'), nb_getval/2 1, and `true` and
  `=/2` NONE (the two clocks, below). A window of 100 000 steps of the
  translator (1.11.4): `true/0` 4.1 %, `=/2` 4.2 % -- no inferences since --
  `atom/1` 3.7 %, `=../2` 3.7 %. A rewrite that removes steps changes the
  count much more than the clock (-32 % and -9.6 % above); ask the clock.
* **When fewer instructions buy no time, count the jumps on 32-byte
  boundaries.** On Skylake's descendants (this box's Cascade Lake, the
  owner's Mac's Coffee Lake) the JCC erratum's microcode keeps a jump that
  crosses or ends on one out of the decoded-uop cache. 1.9.1's naive
  reverse ran 12 % fewer instructions in the same time, with 26.6 such
  jumps an inference against 1.9.0's 16.2; padded, 0.02, and 20 % faster
  (STATUS.md). The count: `callgrind --dump-instr=yes --dump-line=no`
  self counts per address against `objdump -d`'s jump addresses. There are
  no hardware counters in this VM (no `cpu` event source; the `msr` one has
  only `tsc` and `smi`).
* **A count compared across two builds carries the padding's no-ops.** Any
  change moves the functions after it and the padding inside them:
  1.10.12's first build ran `coco_try_clause`, not touched, with two more
  instructions an inference, all of them `nop` and `xchg %ax,%ax`.
  `sh tools/flow/zero.sh OLD NEW` counts nrev, queens and lookup with the
  padding apart; a function's own count, per function, is the same parse
  (its header). And a source change in the step loop moves the loop's
  register allocation whatever it says (DESIGN-flow.md 9.1).
* **zero.sh's binaries stand at paths of one length** (3.48.3): where a
  binary stands moves lookup's count, all of it libc's memcmp and memset.
  The same 3.48.2 counted lookup 11 671 instructions more from the
  checkout than from the scratchpad. 3.48.0's lookup +9 834 and 3.48.2's
  +11 691 were the checkout against an older copy in the scratchpad: at
  like paths they are -634 and +20. Copy each binary into a sibling
  directory, `lib` and `library` linked to the checkout
  (`DIR/t3482/cocolog`, `DIR/t3483/cocolog`), and count them in one
  invocation. A start is counted with each binary swapped in at the
  checkout's own path: from the scratchpad, realpath and strcmp count
  some 31 000 more.
* **A process's speed can depend on where the kernel loads it.** 2.14.1's
  counting loop runs about 30 % slower whenever the binary's base has
  address bits 12 and 13 both set -- one load in four, 60 runs of 60 sorted
  by that alone -- and 2.2.5's does not (bench/README.md, Run Z). Two single
  runs can land in different modes: look at twenty runs of each build for
  two clusters before reading a pair, or time both with `setarch -R`, which
  fixes one layout for each (a placement of its own, to be named).
* **Find a cost with the hunk bisection**: take each hunk of the diff against
  the last version out in a copy of the library and count the sentences that
  rose, several copies at a time (counts do not depend on load). A hunk that
  removes a helper other hunks call answers with an error -- no evidence.
* **One rule, one arm.** A fix that lands in the same edit as another has not
  been measured; a change that moves nothing measurable is not shipped. Arm by
  RULE, a group of hunks: a rule split over two hunks (a head variable and a
  body one) is green with either out. A section cannot arm a rule whose check
  lives in another: run the whole case on that arm (a front's `that` clause
  was green in its own section and red in the Ciampi one).
* **Print the md5 of the library under test AND compare it** to the expected
  one, before the first pass and after the last; a round whose two md5s
  differ is void. Revert with `git checkout -- .`, never by naming files.
* **`utime` beside `stime`, never summed** (`/proc/PID/stat` fields 14 and
  15). On the four-vCPU Linux box a cross-vCPU wakeup is a VM exit costing
  ~18 µs (idle vCPUs halt, no haltpoll): a pooled or threaded figure there
  that is system time tracking the `RES` row of `/proc/interrupts` is a fact
  about the microVM, not the engine.
* **A per-call rate is not a volume**; measure the count before building a
  fix on a rate.
* **`pgrep -f`/`pkill -f` match the shell running them.** Match with
  `pgrep -x cocolog` and `/proc/PID/cmdline`, skip `$$`/`$PPID`, and prefer a
  waiter whose condition is the process gone.
* **A knob that tests `!= nil` is ON when empty** (`MVCCS_NO_CACHE=`); use
  `${VAR:+NAME=1}`.
* `contention_test` opens a filebuf store; `STORE_MAP=1` is the path `--embed`
  and the server use. `MVCCS_DEBUG=warn|info|debug sh MVCCS-cicili/build.sh`
  compiles the engine's trace points in (`guard HELD`, `draw STALLED`).
* **`statistics/2` is about the calling thread** (`store_used`, `store_cap`,
  `globalused`, `globalcap`, `trailused`, `trailcap`, `choicepoints`,
  `strings`, `compactions`, `heap_collections`, `cputime`, `inferences`,
  `atoms`, `functors`, and since 3.59.0 `c_stack`, the thread's C stack in
  bytes). Worker threads are invisible to it: count the
  threads first. On macOS `maximum resident set size` undercounts after a
  large realloc moves.
* `perf` is not installed on the Linux box; `/usr/bin/time` is not either
  (use bash's `time`).

## Cicili, as it is actually written

Cicili is Lisp-syntax C. `../cicili/doc/` is the reference (`DOC-C.md`,
`DOC-CPP.md`, `lib-std-c.md`), `../cicili/lib/README.md` the index. Read them
rather than guessing: a wrong guess usually compiles to something that fails
much later.

* **A string literal is raw** and reaches C untouched; it may not end in a
  backslash and cannot contain a newline (a module's Prolog half is joined
  with spaces).
* **A float literal is a double, every digit of it** (Cicili 3.0.0). Through
  2.0.2 the Lisp reader took it as a single float: `pi` and `e` answered
  `3.1415927` and `2.7182817` through cocolog 1.10.21, and numpy's
  `1e-300` guard was `0.0`. A macro that computes a float as it expands
  computes a double -- `(sqrt 2.0)`, never `(sqrt 2)`, which prints `f0`.
* **`break` and `continue` are bare symbols.** Use `bitand`, `bitor`, `xor`.
* **There is no character literal**: use the macros (`coco-ch-between`) or
  the code with a comment.
* **`defer` is an attribute of a `let`/`var` binding**, not a statement.
* **Lambda-list markers are uppercase** (`&REST`). **A macro emits ONE
  form**; several leave the symbols unregistered. **`new` is a macro.**
  **An attribute written before a macro that emits a function does not
  reach it**: `(static) (some-macro …)` came out without `static`, and the
  guards' runner emitted that way was called rather than inlined (the
  module dispatchers emitted by `coco-emit-module-dispatch` are not static
  either). Write the `func` with its attribute and let the macro make the
  body (`cc-guards-body`).
* **A function pointer in a variable is a `func` clause in type position**
  (`coco_store_reset` in `lib/kb.cicili`); a static one is
  `(static) (var func hook (ARGS) (out int) . nil)`. As a PARAMETER, the
  definition's list is `((func hook (ARGS) (out int)))` -- one level fewer
  closers than the declaration's `(decl) (func NAME ((func hook …)))`;
  copying the declaration's closers is `unmatched close parenthesis`, from a
  reader that names no line.
* **`for` takes a binding list and a parenthesised step**:
  `(for ((size_t i . 0)) (< i n) ((++ i)) BODY)`; a computed initialiser
  needs `#'`: `(for ((size_t i . #'($ r nvars))) …)`. The wrong form fails
  with `The value 0 is not of type SEQUENCE`.
* **`(out T *)`, not `(out (T *))`.** **A cast takes ONE type token**:
  `(cast u8 x)`, or mask with `(bitand (cast int c) 255)`.
* **A `let` declares locals; `block` does not.** **Indexing is
  `(nth INDEX ARRAY)`**; arrays have at most two dimensions.
* **A dotted initialiser `(var size_t n . 0)` cannot be written inside a
  generic** in this package (`nil` is `cocolog::nil`).
* **A `#define` is invisible to Cicili**: write the number out.
* **`$` chains** (`($ a b c)` is `a.b.c`), `(-> p m)` is `p->m`,
  `(=> o m args)` calls a function in a member. **The object of `->` and
  `=>` may be a call**: by name since Cicili 2.0.1,
  `(-> (coco_m_machine e) heap_len)`, and through a function pointer (a
  variable, a member, a table of them) or a C++ method since 2.0.2; through
  2.0.0 that was `pointer storage not found`, and
  `($ (cof (coco_m_machine e)) heap_len)` the way round it (the tree's
  last two went in 1.10.21). A callee whose type Cicili
  cannot resolve -- a type known only by a `@define` -- still has none:
  dereference it.
* **`../cicili/lib/std/c/posix/` already declares the POSIX structs**; what
  is missing is only the C typedef: `(@define (code "pollfd struct pollfd"))`,
  named exactly as std names it.
* **`(code "...")` is the fire escape, not the door** -- C that Cicili cannot
  see. A `;` inside one makes an empty statement (the emitter adds its own),
  which breaks an `if`/`else`. `@ifdef` takes `(code "__APPLE__")`.
* **A file compiled on its own has no `DEFPACKAGE`** (it expands to an
  `EVAL-WHEN` Cicili then reads: `unknown symbol: EVAL-WHEN`).
* **A C library is declared in a binding and called as Cicili.** A
  `(decl) (struct Color (member uchar r) …)` inside a binding's `init-macro`
  emits NOTHING and teaches inference the shape -- how `lib/std/c/posix`
  declares `sockaddr_in` and `lib/net/curl.cicili` libcurl. Worked examples:
  `modules/ray/binding.cicili`, `modules/clay/binding.cicili` (by-value
  structs, `'{ 0 }` initialisers, `(typedef int …)` enums, static struct
  arrays).
* **A C++ library is ONE Cicili file with `(make :cpp #t :compile #f)`**,
  every call and type a Cicili clause over a binding under Cicili's
  `lib/cpp/<lib>/` (a package plus an `init-macro` that emits nothing):
  `lib/cpp/opencv`, `lib/cpp/zigurat`, `lib/cpp/torch`, `lib/cpp/dl`. The
  SDK prototypes are declared RAW inside `extern "C"` before `(coco-sdk)` --
  otherwise C++ mangles them and `use_module` fails with
  `undefined symbol: _Z11coco_m_text…`; the entry and dispatcher sit in
  `(extern-c …)`. Wrapping `(coco-sdk)` in `(extern-c …)` is not the fix.
* **`(inline)` inlines, `(weak)` is weak** (Cicili 2.0.0, `8be7385`):
  `(static) (inline)` emits `__attribute__((always_inline)) static inline`,
  and `(weak)` `__attribute__((weak))` -- what `(inline)` emitted through
  1.0.1: one definition however many files instantiate it, a call clang never
  inlines, and with `(static)` no C at all (`weak declaration cannot have
  internal linkage`). A helper two hot callers share and clang leaves out of
  line is an `(inline)` (the reader's three, 1.10.7).
* **`(cold)` is seldom called** (Cicili 3.1.0, `cc24ae0`): it writes
  `__attribute__((cold))` before the definition and before a `(decl)`
  prototype, where a caller in another file learns it. Clang takes a block
  that calls it as unlikely, lays the caller's hot path out without it, and
  weighs the caller's other calls for inlining without its weight; the
  function is optimised for size, inlined only if it is tiny, and put in
  `.text.unlikely`. `(weak) (cold)` is a slow path kept out of line whose
  callers know it (the growths, 2.11.2); `(inline) (cold)` is refused. A hot
  function's rare call that clang's guess weighs as common is what it is
  for -- measured, as everything here: marking every error raiser cold made
  lookup dearer (STATUS.md, 2.11.2).
* **The macro tables emit several things that must not drift apart**
  (`*cell-tags*`, `*operators*`, `*builtins*`, `*turn-outcomes*`,
  `*construct-names*`): **add to the table, never to the generated code.** A
  construct name missing from `*construct-names*` stops the build at
  `no dispatch id`, and one added there wants its arities in
  tools/flow/tables.pl (`ft_construct_arities/2`), or `make modules` stops
  naming it (3.2.0's bar did). **The dispatch names -- the constructs, the builtin rows
  and the arithmetic names -- are held to `coco_machine.ids [256]`** (192
  through 3.19.5, 191 used, which 3.20.0's `$`, `@` and their two markers
  passed; 198 used since 3.21.0's three for $/0), and a build past it stops naming both numbers: a new builtin
  that would pass it shares a C half with others by an argument (3.2.0's
  four declarations are one row, `'$declare'/2`, under clauses of the
  Prolog half). A construct name a frame or a program never names first is
  appended at the table's end, so the names before it keep their ids.

## Parsi

`IF cond BEGIN … END`; `<>` for not-equal; names fold to upper case (a column
named `text` collides with the `Text` type, hence `body`); a row must fit one
page (machine state travels in 4000-byte chunks).

## Libraries and modules

**Tier 1 is always present, and `use_module` on it is a no-op nobody here
writes**: the compiled-in `apply builtins dcg files library lists zigurat`
and SWI's own `assoc pairs ordsets yall aggregate ugraphs dcg_basics
dcg_high_order`, vendored unmodified in `lib/swipl` and read at start-up (do
not edit them), and since 2.8.0 `async` (`library/async.pl`, the green
threads, preloaded by `lb_always` from the binary's library path: ASYNC
COROUTINES ARE ON BY DEFAULT, and `use_module(library(async))` is a no-op);
its names are GLOBAL (`go/1,2`, `yield/0`, `await/1,2`, `await_all/1`,
`async/2`, `future_ready/1`, `channel/1,2,3`, `channel_send/2`,
`channel_recv/2`, `channel_close/1`, `async_workers/1`), so a program's own predicate of one is
shadowed by the library's -- the 2.8.0 suite found test/window.pl's and
test/flowdebug.pl's `go` fixtures that way, and they are `rec` now), and
since 2.16.0 `print_message` (`library/print_message.pl`, swipl's
print_message/2, message_to_string/2, print_message_lines/3 and the
message_hook/3 and prolog:message//1 a program defines, preloaded the same
way, its helpers all `'$pm_...'`; it costs every process's start-up 3.2
million instructions, `cocolog query true` 21.7 million to 25.0, about half
a millisecond of ten). Its names are global as async's are: a program's own
print_message/2 joins the library's clauses, as its own sumlist/2 or
member/2 joins library(lists)'s (card row N1), and cocolint finds each
such head -- for the two preloaded libraries since its blocklist reads the
preload from `coco_library_preload` (`bd_preloaded_names/1` in
tools/cocolint/build.pl: a preload written as a literal
`(lb_load_pl path "NAME" ...)` is counted with no edit there).
Only files swipl also runs (`test/files/*.pl`,
`emacs/test/conformance.pl`) and `test/library.pl` keep such a directive,
where cocolint reads it acknowledged (`% cocolint: T1 -- ...`, below).

**Tier 2 is loaded when asked**, from `$COCOLOG_LIBRARY` (colon-separated),
then `./library`, then `<exedir>/library`, then `<exedir>/lib/swipl` -- the
path is anchored to the binary, so an installed cocolog loads its own
libraries. `library/*.pl` are clauses only (http, httpd, websocket, json,
async (green threads over the compiled-in green module),
xml, html, ca, kbs, cowork, main, astar, hex, template, clay_ray, tensor_expr, llm,
and `library/reasoning/` and `library/flow/`: `flow/chart` and
`flow/debug`, each with its parts beside it, `dbg*.pl` the debugger's);
`library/*.so` are modules built from `modules/`. A file whose first line
reads `%% library(NAME), part: ...` is loaded by its library, and the
cocolint index offers no import of it.

**`modules/` holds the loadable modules**, one directory each -- a
`.cicili`, a `build.sh` (`sh modules/NAME/build.sh`), output nobody commits
-- and **none of them is part of `make`**:

| needs nothing | `tcp` `thread` `process` `text` `os` `signal` `clay` (Clay vendored, one header) `stream` |
|---|---|
| a BUILT ZiguratIP | `sha` `aes` `der` (libEncoding only) `x509` `tls` `bigint` |
| an external library | `curl` (libcurl), `regex` (libpcre2), `torch` (libtorch), `tensorflow` (its C API), `ray` (raylib), `numpy` (python3 with numpy and a shared libpython), `opencv` (OpenCV 4 with dnn) |

* **A module holds the engine as an OPAQUE pointer** (`coco_m_new_int e V`,
  never `(-> e m)`). Its entry is `coco-deflibrary`, or for C++ a
  hand-written `coco_library_entry` inside `extern "C"`.
* **What a `coco_m_*_error` returns is the predicate's ANSWER (2: the
  continuation is set), not a status.** A guard written
  `(if (not (helper …)) (return 0))` tests `not 2` and walks on with a ball
  in flight. Pass it through --
  `(let ((int rc . #'(ray_iarg e g 0 (aof x)))) (if (!= rc 1) (return rc)))`
  -- or have the helper answer 0 and carry the raise out in a parameter.
  The tell is a helper that both raises and returns int.
* **A handle is an integer index into the module's own table** (tcp, tls,
  ray, stream), so losing one leaks what it names silently. Probe by
  exhausting the table before and after the code you suspect.
* **A unix socket is `unix(Path)` where a port stands** (2.4.0, library(tcp);
  STATUS.md): `tcp_listen/2`, `tcp_connect/2` (with `Host:Port` too),
  `httpd_serve(unix(Path), _)`, and the clients' `unix_socket(Path)` (curl,
  `ws_open/3`). What bites: a listen on a taken name CONNECTS to ask whether
  anybody listens, so a live server sees a connection that closes at once
  -- one of an httpd's counted accepts; a leftover is replaced only once that
  connect is refused, so a test that needs one kills the cocolog ITSELF (9,
  no `timeout` in front: killing the wrapper leaves the server listening);
  the listener's close unlinks its file by inode, a connection's never; and
  `exists_file/1` is false of a socket (a regular file only, as SWI's) --
  ask `access_file(P, exist)`. `struct sockaddr_un` and
  `CURLOPT_UNIX_SOCKET_PATH` are declared in `modules/tcp/binding.cicili`
  and `modules/curl/binding.cicili`, Cicili's std and curl binding having
  neither.
* **`$`-prefixed names must be QUOTED in a module's Prolog half**
  (`'$x509_issue'`), or the half "would not consult".
* **Which library holds a symbol is not guessable, and a miss links fine**:
  `nm -D --defined-only` over `home/lib`, and name every transitive
  dependency on the link line.
* **`current_predicate/1` answers about the PROGRAM**, not the library or
  modules: probe a module by catching `existence_error` around a real call.
  It answers for a predicate with a clause or a dynamic declaration, as
  SWI's does -- consulted, asserted, or read from a file the program loaded
  by its path (`-s FILE`, `ensure_loaded/1`, `use_module/1` of a file: a
  module whose predicates are `own`, beside the `library` flag the pre-warm
  needs; 1.10.28, until which they were left out with the library's, and
  `listing/0` too). **Named whole it answers for the system's too** (3.31.0,
  `'$cp_defined'/1` over `coco_pred_current` in lib/kb.cicili): a construct,
  a row of the engine or of a compiled-in module, what predicate_property/2
  calls built_in, as swipl's answers for module system's -- and a read's
  `:- if(current_predicate(N/A))` asks the same function
  (`coco_cond_eval`), so library(assoc) keeps the get_assoc/3 swipl's keeps,
  over the engine's `'$btree_find_node'/5` (through 3.30.0 the condition
  asked the store alone, and the library's single-sided rules answered a
  term that was no assoc with existence_error(matching_rule, ...)). **Named
  whole it asks user's view as swipl's since 3.42.0**
  (`coco_pred_current`'s hook, `coco_b_cp_current` in
  lib/builtins-db.cicili; test/files/current_library.pl): the program's
  own first, then by lib/swipl-props.cicili's module -- swipl's system
  predicates (module system or a `$` one) wherever cocolog defines them,
  between/3 and sub_atom/5 among the library's clauses, and a library
  module's export once the program IMPORTED it (`coco_imp_note`, a
  process-wide list, every reader and writer of it under `cp_imp_mx`
  since 3.42.2: a library(thread) thread loads with a machine of its own,
  and through 3.42.1 two threads' loads at once grew the list and freed it
  twice, test/thread.pl's `imports`): a load of library(Name) its read or
  goal made
  (use_module/1,2 with the import list or except/1, ensure_loaded/1,
  autoload/2's list, a list of files, consult/1, `[File]`, load_files/2's
  imports(I); `lb_import_note` and `lb_import_lf`, before the load, as
  the goal is read nowhere after it; a library's own read imports
  nothing: `lb-load-is-ours`, muted and not `ownload`), or
  predicate_property/2 of a head it names (`'$pp_autoload'/1`, swipl's
  define_or_generate/1, but for six properties and a module other than
  user or system). A call imports nothing, where swipl's autoload does
  (COMPAT.md); what the table has no row for answers as a C row says.
  **A name cocolog defines in C that the hook calls current answers
  before the store is asked** (3.42.2): 3.42.0 warmed the store first, and
  library(assoc)'s `:- if(current_predicate('$btree_find_node'/5))`, read
  at every start, fetched a Zeytun store's predicates before the program's
  first goal (test/tunnel.pl: a refused certificate said `fetching
  predicates` and the process ended 3). **library(listing) is carried**, and a carried name loads as a goal
  too, and through consult/1, `[File]` and load_files/2 (`lb_is_carried`;
  through 3.41.0 each raised existence_error, where the directive loaded).
  The table is looked up by arity and then the name's first byte
  (`coco-emit-swipl-props`; a strcmp a row of the arity's through 3.41.0,
  some 1 300 instructions for a name of two arguments). A spec with a part
  unbound walks the program's alone, where swipl's walks its system's
  1 278 too. Through 1.10.2 it also answered for any name a call or
  `clause/2` had merely looked up (each makes a table entry).
  `predicate_property/2` (1.10.28) answers for a construct (by name AND
  arity, `*callable-constructs*`: the construct table also holds the
  engine's markers, `'$k'`, `[]`, `:-`, which are no predicates), a C
  builtin of the engine or of a compiled-in module (from the tables the
  dispatchers are built from: `coco-emit-claims`), and any predicate of
  the store; `M:H` is H, so `user:H` walks the program's. **Its answers
  are swipl 9.0.4's since 3.41.0** (`coco_b_pred_props` in
  lib/builtins-db.cicili, test/files/predicate_property.pl), in swipl's
  order: a system or library predicate's built_in, imported_from(M),
  transparent, meta_predicate(Spec), notrace, nodebug, noprofile, ssu
  and iso from lib/swipl-props.cicili, generated by
  `tools/props/tables.pl` under the REFERENCE swipl (run it again, never
  edit the table); `foreign` is cocolog's own model, what listing/1 writes
  as `%   Foreign:`. What the table has no row for answers what its
  declarations said: the meta_predicate spec (`pmeta`, noted by the
  directive and since 3.46.0 the goal, `coco_pred_meta_note`, the latest
  declaration's however the calls qualify), the module/2 read's module (`pmod`),
  `pattrs`, and file(F) and line_count(L) of the first clause a file read
  (`pfile`, `pline`, noted at a read's first sight of the predicate in
  `coco_reload_for`, the path interned once a file; a library's too,
  where it was read from a file; cleared by asserta/1 and abolish/1, kept
  across a retract, a re-read moving the line). A head that is no
  callable term fails, as swipl's (through 3.40.0 type_error(callable,
  H)), and implementation_module(M) of a head named is
  `'$pred_impl'/2`'s. A `.so` module's predicates are not answered.
  **What user does not see is no predicate of user's** (3.48.0,
  `coco_pp_unseen`, test/files/user_view.pl): the table holds a row,
  flag 4096, of every predicate a carried library's file defines that
  swipl's user does not see -- a helper (`gen_assoc_/3`, ugraphs'
  `before/2`), a hook it defines in another module
  (`sandbox:safe_meta/2`) -- and flags 8192 an export swipl's autoloader
  does not reach (library(dcg/basics)'s and (dcg/high_order)'s), which
  answers once the program loaded its library (`coco_imp_has`); neither
  answers where the program gave the name a clause of its own (`muted`
  0), and current_predicate/1 says the same (`coco_pred_current`). The
  list's predicate is swipl's `'[|]'/2` (the props lookup asks '.'/2 as
  it), its two clauses and `:- meta_predicate([:|+])` swipl's, and the
  hooks swipl declares in user are rows of `user` -- current, and
  answered from the row, so file_search_path/2 is no nodebug predicate
  though the files half reads it under generate_debug_info false. The
  table also rows what swipl's autoloader brings from a library cocolog
  does not carry (`also/1` in the generator: random/1,
  make_directory_path/1, string_to_atom/2, sumlist/2).
* **Register modules before spawning threads**: the registry is
  process-wide and unguarded.
* `cocolint`'s index picks `modules/NAME/NAME.cicili` by name; a header
  signature list counts only at column 0.
* **The whole tree lints clean, and `test/lint.pl` holds it to that**
  (2.2.1): every `.pl` it holds, no finding HARD or WARN, and no `thin` or
  `unrouted` note from the index. A form a file commits on purpose (a lesson
  teaching the trap) carries `% cocolint: ID -- why` on its line, or alone
  on the line before; U1 reports one whose finding has gone or that gives no
  reason, and `COCO_LINT_NO_ACK=1` reads none. `lib/swipl/` is not read.
  Lint a new or changed `.pl` before a commit: `sh tools/cocolint/lint.sh
  FILE.pl`. `--auto` lints every changed `.pl` (working tree, staged,
  untracked), `--staged` the index alone, and both also check the dialect
  card; `make lint` with no `FILES` is `--auto`. A changed `.cicili` is
  named and skipped (a module is Cicili, its Prolog half is not a file),
  and `lib/swipl/` is named vendored.
* **The dialect card cites engine lines by range** (`tools/cocolint/
  traps.jsonl`). An edit ANYWHERE above a cited site moves it; a cite whose
  anchor is unique is accepted as moved, one whose anchor repeats in its file
  is refused until its range is corrected. After touching `lib/` or
  `cocolog.cicili`, run `sh tools/cocolint/tool.sh card --check`.

## The engine: what is not obvious

* **Dispatch is construct, C builtin, module, store, by name AND arity.** A
  loadable module's C name shadows any clause of that name (`listing/1`
  shows nothing). **A program file's clause for an engine's or a
  compiled-in module's name TAKES IT OVER** (3.1.0, swipl's:
  `coco_claim_kind` 1, `coco_pred_take_over`): the predicate is called from
  then on, not/1, ignore/1 and the names of no arguments too; an ISO one's
  clause is refused at load (`*iso-predicates*`) unless
  redefine_system_predicate/1 named it (which takes the program's
  definition away first, as abolish/1 does, since 3.47.0 -- swipl's
  abolishProcedure()); a library's calls of a taken name
  are made `system:` and keep the builtin. **The library's own clauses of a
  taken name are KEPT under `$system:NAME`** (3.58.1, `coco_kept_head`):
  by the take-over where the library's half was read first
  (`coco_pred_keep_muted`, with the attributes the predicate had before
  the program's clause, `lattrs`), by the assert where it is read after (a
  module's half at a query's start), and a `system:G` its module turns down
  (`:declines`: length/2 enumerating, nth0/3 with the index unbound) runs
  them in the `:` step (`coco_call_kept`), its frame's call the kept head
  and its shadow frame's goal G -- through 3.58.0 the goal was made
  `system:G` again and ran for ever. **The tracer's context of a clause
  frame is its call** (`choices[ci].call`: a retry's, the exit marker's
  match) **and what it prints its shadow frame's goal** -- one cell but for
  the kept call: a new reader of a frame's context reads the call. (A
  traced cut still matches the goal printed: no clause a declined goal
  runs cuts, and an arm that read the call moved nothing.) As a guarded
  frame's last call the kept call takes the guard on (`coco_det_pcall`),
  as the call of the name not taken does. A qualified goal has the ports an unqualified one has since
  3.58.1 (`coco_colon_run`: a module's answer too). The functor keeps the row it
  calls (`bix`: K + 2, 1 none or taken), so **a new way to call a builtin
  by its row asks `bix`, never the table alone**, and a body compiled
  against a row hands its goal over when the row is gone
  (`coco_env_place`). Grep a predicate name before writing it: **cocolog consults the
  clauses of one name that are not together in the file without a word**
  (SWI warns; cocolint does not), so a helper given an existing name joins
  that predicate. library(flow/chart) names each such predicate it charts
  (the `discontiguous` finding, 1.10.27), and as an error one DEFINED TWICE
  -- a clause that repeats an earlier run's, or a head an earlier run's
  fact covers (`defined_twice`, 1.10.28): the translator has 38 and none
  (`tr_cap_run/3` was the one, until 1.11.1). The flow chart takes `load(Files)` for a program's other
  files, whose predicates then count as defined (`load=` on
  tools/flow/chart.pl), and `progress(S)` (stderr, every S seconds, 10 from
  the command).
* **Every builtin is deterministic** (repeat/0, and arg/3, char_type/2 and
  code_type/2 with an argument unbound, aside, below), so a failure-driven loop written
  from habit over one runs it ONCE -- wrong, not slow (`retract(H), fail`
  was the classic one until 3.28.0 made retract/1 a walk that answers
  again). `once/1`, `ignore/1` and `\+` are control constructs. **arg/3
  with its index unbound enumerates** (3.29.0, swipl's foreign arg/3;
  through 3.28.0 it raised, and library(aggregate)'s free_variables/4 with
  it): its row answers -2
  (`coco_bi_arg`), and each of the row's three callers -- the step
  (`coco_builtin_call` by the functor's row), an environment's BUILTIN unit
  (`coco_env_place`) and the `:` construct's own call of a row
  (`coco_colon_run`: `system:G` of a name a program file took over,
  test/files/arg_taken.pl) -- hands it to
  `coco_walk` with the continuation it holds, the goal being `kcall`:
  the places tried in order, the third argument unified first, a WALK
  frame (`COCO_CH_WALK`, ARG through 3.29.0, its barrier 0) kept for the
  next place while one remains, so an answer short of the last place
  leaves a choice point whatever the places after it hold, and the last
  none (test/files/arg_enum.pl). **char_type/2 and code_type/2 with the
  character or the type unbound walk the same way** (3.30.0, swipl 9.0.4's
  do_char_type; through 3.29.0 they raised): the codes -1 to U+10FFFF
  (255 for char_type/2 under bytes, whose walk passes the surrogates by)
  or the 33 classes of swipl's table in its order, csymf twice
  (`*coco-ct-classes*` in lib/solve-text.cicili), the frame's position
  packed in its `clause_ix` (`coco-ctw-pos`, bit 48 telling it from
  arg/3's place). Each class's test and reverse is an expression of
  `*coco-ct-exprs*`, which DEFMACROs turn into one switch each
  (`coco_ct_test`, `coco_ct_reverse`), so **a new class is a row and an
  expression, never a function** -- and its test a keyword (`:alnum`): a
  row `("name" N word)` is a builtin's to tools/cocolint/build.pl. The
  classes are swipl's on Linux under C.UTF-8, written out at transpile
  time from the runs of lib/swipl-ctype.cicili into two-level tables, a
  page of 128 or 256 codes each (`coco_ct_flags`, `coco_uc_case`, the
  macros of lib/term.cicili), which tools/ctype/tables.pl generates under
  the REFERENCE swipl (run it again, never edit the file);
  test/files/char_enum.pl holds every class of every code point, the walks
  and the errors to swipl. **repeat/0 is a walk too** (3.39.0, swipl's ISO
  builtin; through 3.38.0 cocolog had none, and a call raised
  existence_error): its row answers -2 (`coco_bi_repeat`), and the step
  hands an ATOM goal's row to `coco_walk` as it hands a compound's (the
  `coco_builtin` path of the loop, a fourth caller), whose frame's place is
  bit 49 of `clause_ix` (`coco_walk_retry`), never moved: every retry
  answers again, until a cut takes the frame. **A walk that answers with
  its frame kept, as the innermost guarded frame's last call, raises
  determinism_error(PI, det, nondet, guard_in_caller)** named by the
  builtin, swipl's foreign rule (`coco_det_bfail`, its WHAT `nondet`, the
  walk's frame dropped first so the guard asks what stood before the
  call): repeat/0's, arg/3's before its last place; through 3.38.0 arg/3's
  was the guard's own `guard`, naming the clause (test/files/repeat.pl;
  test/engine.pl's `repeat_runs` the trace, the collector, KMAT and a
  thaw). **A new
  row that hands its goal over answers -2 to those four, asked right beside
  the row's call**: asked after the loop's module seam, beside its -1, the
  walk's call cost the step loop two reloads of the engine a step, and a
  goal and a barrier kept live across the row's call cost every builtin in
  place an instruction (`tools/flow/zero.sh`, all three under 3.28.0's now).
  A module row that must enumerate for some arguments ends in
  `:declines` (1.12.0, `coco-emit-module-dispatch`): its function takes
  `found` and turns those goals down (`coco_m_decline`) to a clause of its
  Prolog half -- nb_current/2 with its key unbound.
* **The trail carries VALUE ENTRIES since 1.12.0** (setarg/3): two words,
  both with bit 63 (`coco-trail-pair`), the cell holding the old value and
  then the cell it goes back into; `coco_undo_to` puts it back, the
  collector marks every saved cell and keeps or drops a pair whole (by the
  restored cell, as a binding by its variable), a freeze writes the words
  as they are. **A new reader of the trail tells a pair from a variable**,
  and reads a pair's cell under bit 40 (`coco-trail-cell`): bits 40 to 62
  (`coco-trail-tag`) are 0 in a value entry and not in a ground global's
  sentinel (1.12.1, below) -- the global's index plus one, the copy's
  serial, cell 0 in both words, which the undo writes with itself.
  nb_setarg/3 writes past the trail and RAISES MARKS instead
  (`coco_heap_freeze`, SWI's freezeGlobal): every choice point's, nested
  engine's and host's registered heap mark above the written cell goes to
  the heap's length, so its copy outlives backtracking -- **a new starter
  of a nested engine that winds the heap back reads its mark back from the
  engine (`pheap`)**, as findall/3 does (a window's question carries the
  window's mark in its engine's `pheap` and hands it back, 1.12.1), or that
  copy is cut away under the cell. The marks grow up a choice stack and
  inward along the chain, so the walk stops at the first one below. The argument
  CELL is written: a body's variable lives in its environment or frame and
  f(X)'s argument names it, so `T = f(X), setarg(1, T, z)` leaves X unbound
  where SWI (which made X in the argument) binds it.
* **A core builtin raises SWI's error, catchably** (1.10.6): `=..`,
  `functor/3`, `arg/3` and `is/2` name what is wrong as SWI does
  (`type_error(evaluable, foo/2)`, `domain_error(non_empty_list, [])`; an
  integer-only function -- `//`, div, mod, rem, gcd, `>>`, `<<`, the
  bitwise four, msb -- names the float it was given, the left one first,
  `type_error(integer, 1.5)`, and msb/1 of an integer under 1 is
  `domain_error(not_less_than_one, N)`: through 1.14.0 each named heap
  cell 0, under -s the loaded file's path; `coco_not_integer`, 1.15.0), and
  assert and retract refuse an unbound clause, a head that is not callable,
  a body with a number or a string where a goal stands, and a clause for a
  control construct (`permission_error(modify, static_procedure, ','/2)`).
  A fact under a core builtin's name is KEPT, where SWI refuses it:
  library(reasoning) stores word classes such as `number(dos)` and reads
  them with `clause/2` (refusing it stopped `test/translate.pl`).
  `coco_fail_err`, which ends the query
  where no `catch/3` sees it, is left for a machine past saving (a growth
  refused outright, an inference limit) and a load that cannot go on --
  memory refused and then given less is resource_error(memory) since
  1.10.28; a new builtin raises through `coco_raise`. `format/2`'s
  `~a`, `~s` and the format itself take text of any length
  (`coco_text_put`). **Every text builtin reads its text as swipl's
  PL_get_text does** (3.0.0; atom_length/2 and string_length/2 since
  2.16.1): `coco_tx_get` with the predicate's `CVT_*` flags. A compound
  is type_error(T, C), a list is codes or characters by its first element
  and every element is held to that kind, a partial list is
  instantiation_error, and a predicate whose text may be unbound fails
  there where swipl's does (`coco_tx_varnofail`). sub_atom/5,
  atom_concat/3, string_concat/3 and sub_string/5 read `CVT_ATOMIC`
  alone, so a list is no text to them, and a `"..."` under codes is a
  list: `sub_string(S, 0, 1, _, '#')`, never `"#"`. Their clauses ask
  `'$sub_text_length'/9` (sub_atom/5, sub_string/5),
  `'$atom_text_length'/3` or `'$string_text_length'/3`, each raising that
  predicate's own swipl type (`atom`, `atomic`, `string`, `text`) of the
  whole term. **A new text builtin reads through `coco_tx_get`** with
  swipl's flags for it, never by walking a list itself.
* **`[]` is not `'[]'`** (3.0.0, swipl 7's): `[]` is the list's end and
  `'[]'` an atom of two characters (`coco_intern_tnil`), which the writer
  quotes. atom/1 fails of `[]`, atomic/1 holds, callable/1 fails, and
  `atom_length([], N)` is 0. **Ask `coco_is_nil` or compare with
  `coco_nil_id`, never `strcmp` with `"[]"`**, and build the list's end
  with `coco_new_nil` (a module: `coco_m_nil`). So as a functor's name
  (3.12.0): `[](a)` and `[ ](a)` are named by the list's end, a quoted
  `'[]'(a)` by the atom (the reader's `bnil`, `coco_parse_fid`), and the
  writer writes the first bare and the second quoted; through 3.11.0 both
  read and wrote as `'[]'(a)`, named by the list's end. **A compound built
  from an atom is named by the atom's ID, never its name** (3.15.1):
  functor/3, =../2 and an operator the reader applies (`coco_parse_fid`)
  name `'[]'`'s compound by the atom, where `coco_make` with `"[]"` names
  the list's end's; an operator written is the atom `'[]'` quoted
  (`a'[]'b`), and the list's end is no operator.
* **A compound of no arguments, `f()`, is a FUN cell of arity 0** (3.12.0,
  swipl 7's): the header and no argument after it, its functor the name and
  0. It is no atom (`f() \== f`, compound/1 holds), and as a goal it calls
  f/0: the step reads a goal of arity 0 by its name, as an atom's. The
  reader makes one of `name()` (`coco-parse-args-body`), the writer writes
  `f()`, functor/3 and =../2 refuse it with
  `domain_error(compound_non_zero_arity, T)` as swipl 9's, and
  compound_name_arity/3 and compound_name_arguments/3 take it apart and
  make it (`'$compound'/4`). A clause's head and a body's goal written so
  are kept as the atom (`coco_assert_from`, `coco_clause_compile`), as swipl's
  clause/2 hands them back; clause/2 of `f()` asks f/0's. **`coco_make(m,
  name, 0, nil)` makes `f()`, not the atom** (`coco_new_atom`); a call of
  no arguments never goes through the registers (`cc_env_callable`), so no
  atom goal is rebuilt as one.
* **An error names the predicate that raised it** (3.0.0): its second
  argument is `context(system:Name/Arity, _)`, made by `coco_err_ctx` from
  the goal in flight (`kcall`) and a row of `*error-contexts*` in
  lib/solve.cicili. A row is a builtin's name and arity, `:BARE` for one
  swipl names with no module (length/2), `:MAP` for the frame swipl's own
  raise names (memberchk/2's `'$memberchk'/3`, findall/3's
  `'$bags':findall_loop/4`), and `:ATOM`, `:INT` or `:FUN` for a C half
  shared by several predicates, chosen by one of its arguments. The row
  is kept on the functor (`ectx`). A goal no row names raises with the
  context unbound -- a library's clause, a program's, a compiled-in
  module's -- **unless a loadable module answered it** (3.0.2): a `.so`'s
  own predicate names itself, `context(Module:Name/Arity, _)`, as swipl
  names a foreign predicate (`coco_m_module_ctx`). The seam puts the module
  it calls on the engine (`kmod`, before each dispatcher, in
  `coco_module_call`, `_resolving` and `_at`), the step clears it when the
  module's call returns (so `_at` keeps its tail call: putting it back
  there cost a module call 11 instructions), and the loader marks what a
  `.so`'s entry registered (`foreign`, `coco_module_set_foreign`). A row
  wins over the module: library(thread)'s mutex predicates are
  `system:mutex_lock/1`, swipl's builtins. **A new builtin gets its row**,
  or its errors name nothing; a new way to call a module's dispatcher sets
  `kmod` before it and clears it after, or its raises name nothing, or the
  wrong module. The message
  of an uncaught error, and print_message/2's, begin `Name/Arity: `
  (`coco_err_caller`, library(print_message)'s `'$pm_caller'`), so a case
  that holds stderr to the letter holds the prefix too. An unbound
  culprit of a type error is instantiation_error (`coco_type_error`,
  `coco_m_type_error`), as swipl's PL_error() makes it.
* **The barrier a body's goals carry names the frame they run in** (3.1.0,
  `coco-bar-of`, `coco-bar-pred`, `coco-bar-low` in lib/kb.cicili): the
  clause's predicate (`ptag`, its functor id plus one, ORed in as the clause
  is entered), a system frame's bit and the meta-call's, above the choice
  height the low bits keep. So an unknown procedure names the clause's
  predicate, or past a last call its caller (`coco_unknown_error_q`), a goal
  that is no goal the clause it stands in, as swipl's frames do. **Every
  reader of a barrier as a height takes `coco-bar-low`**, and **a new push
  of a body's goals ORs the clause's `ptag` in** (the plain path, the
  guards' and the environment's in `coco_try_clause`, the units' link,
  `cc_ulink`), or its goals' errors name the caller. One OR an entry: nrev
  +0.44 % of zero.sh's work, +0.15 % less its padding. **call/N runs in the
  frame its word names** (`coco_call_inline`, swipl's I_USERCALL): in its
  clause, in a `'<meta-call>'/1`, and since 3.43.0 in the structure of the
  goal of a search a clause starts, a word with no owner there --
  findall/3 and its kin, forall/2, aggregate_all/3, a directive and `run
  FILE GOAL`, an initialization goal (`rootn` 1 to 3, 5 and 6), the call/N
  goal asked where it stands in the search's goal (`coco_root_part`, a
  walk by the names' ids): its errors name `'<meta-call>'/1`, as swipl's
  clause compiles that goal into one. A search C starts (with_output_to/2,
  `~@`, and since 3.44.0 a thread and an isolated run: 4) runs the goal
  swipl's callProlog() runs (the next bullet), and a query (0) keeps
  call/N a frame of its own (test/files/meta_call_root.pl). **A new
  starter of a search sets `rootn`**, or its goal's call/N is named as a
  query's. The answer is kept per search for a cell of its goal (`rpg`,
  `rpc` on the engine), and the root case is `coco_meta_bar`'s FIRST test,
  a tail call to `coco_meta_bar_root`: asked after `coco_call_inline`'s
  call of `coco_goal_was_var`, its arguments were live across that call,
  and `coco_meta_bar` saved six registers where it saved three -- nine
  instructions on every call/N of a clause, maplist/N's.
* **A goal swipl's C calls is the goal its callProlog() calls** (3.44.0;
  `coco_c_root` and `coco_c_goal` in lib/solve-control.cicili,
  test/files/c_call_goals.pl): with_output_to/2's, `~@`'s, a thread's and
  an isolated run's (`rootn` 4), and setup_call_cleanup/3's setup and
  cleanup (`'$c_goal'/3` in the builtins' Prolog half): the qualifiers
  off, a plain goal in `'$c_call_prolog'/0`'s frame, a control construct
  the system's predicate boot/init.pl defines -- `(M:A, M:B)` called again
  for ','/2, (->)/2 and (*->)/2, `M:(A ; B)` for (;)/2, `\+ M:X` and
  `$(M:X)` meta-calling their argument in their own frame (`$`'s error
  shows `call(user:G)`, `coco_det_c_root`); setup_call_cleanup/3's goal
  runs in its own frame (`'$scc_run'/1`), and `'$c_goal'/3` raises a
  setup's and a goal's faults itself (kinds 0 and 3) -- the cleanup's
  first, before its frame is pushed (kind 4, `[]` no goal there), and the
  goal's in its frame after, so the cleanup runs for a goal that is none
  (3.47.0, I_CALLCLEANUP's order). **A part of a
  construct is said of user only where that changes how it runs**
  (`coco_c_arg`: a call/N, a control structure, a variable, what is no
  goal), and every part where the construct is no goal and its error's
  formal shows them (`(user:true, user:1)`, `coco_c_root_q`'s FULL): a
  plain goal under `user:` runs as it would bare, for a `:` step more. **A qualifier met is a flag,
  never a cell** (`qual`): a thread's goal is read into a machine of its
  own, where its module atom is heap cell 0, and the first cut lost it
  there. **`user` is told by its name** (`coco_atom_is_user`, a strcmp),
  never by interning "user" to compare ids: the `:` construct runs each
  `user:G` a C-called structure is made of, and in the first cut every
  qualified goal interned "system", walked the libraries' names and
  interned "user" twice -- with_output_to/2 of `(true, ok(1))` cost 4 200
  instructions more than 3.43.0's. **A qualifier on call/N or a structure** (`coco_colon_written`):
  a meta-call's own goal is stripped -- what nothing defines named by the
  module (`lists:foo/0`), call/N left in place with its goal the module's
  -- and one written in code that runs is compiled: `M:call(G)` call/N's
  own frame, M said of each goal of a structure. `$(G)` is never qualified
  inside, as its determinism error shows G as written; a construct's name
  of an arity no construct has is no construct under a qualifier
  (`coco_construct_pi`, from `*callable-constructs*`). **A cleanup's ball
  replaces the goal's only when it is more urgent** (`'$scc_urgency'/2`,
  swipl 9.0.4's ranks: time_limit_exceeded over error(_, _) over any
  other), and never one raised after the goal exited.
* **A meta-predicate's module-sensitive arguments are said of the module
  the call is made in** (3.45.0, swipl's; `coco_meta_qualify`,
  `coco_meta_ctx` and `coco_meta_colon` in lib/solve-control.cicili,
  test/files/meta_args.pl): each argument a meta_predicate/1 declaration
  marks `0` to `9`, `:`, `^` or `//` becomes `M:A` unless it is a term
  `_:_` already. **meta_predicate/1 is a goal too** (3.46.0,
  `'$declare'(7, Spec)`, `coco_bi_meta_decl` in lib/solve-db.cicili over
  `coco_pred_meta_check` in lib/kb-pred.cicili, test/files/meta_goal.pl;
  through 3.45.0 an unknown procedure): a conjunction walked left to
  right, each head's atom qualifiers off, an ISO predicate refused before
  its arguments, each argument in order a 0 to 9 within a C int or one of
  `? + - * : ^ //`, the heads before a fault declared, the fault swipl's
  ball named system:(meta_predicate)/1, a specifier's with `0..9`, and the
  list's end a failure (3.47.0). **A list is a head**, the list's own
  predicate's (3.48.0, `coco_pred_meta_note`, as the check walks it):
  through 3.47.0 the note took its elements for heads, and `[:|+]`
  declared (:)/0 and (+)/0. A head
  of no arguments is noted too (`meta_predicate zero`, the atom). **A
  spec is kept as swipl's meta_declaration() keeps it** (3.48.2,
  test/files/listing_meta.pl): `*` is `?`, and the predicate is
  transparent as its spec says, a module_transparent/1 before it taken
  away (`pattrs` 4), one after it standing; and **a spec that names a
  module** (`coco_meta_spec_module` in lib/kb-pred.cicili: 0 to 9, `:`,
  `^`, `//`) **is a transparent predicate's to every reader of
  transparency**: predicate_property/2, listing/1, which then writes no
  `:- module_transparent` line, and a last call under `$/0`, which drops
  its guard into it (`coco_det_transparent`) -- a new reader of `pattrs` 4
  as transparency asks the spec too. M is
  the module/2 read's that defined the clause the call
  is written in (`pmod`; user for a program's clause, a meta-predicate's
  own clause its own module's, as swipl's), the read under way's
  (`ssu_mod`) where no clause is the goal's -- a directive's, a search's
  -- or the clause is a module_transparent/1 predicate's whose spec names
  no module (3.48.2: a spec that does keeps its own, as swipl's frame
  does), else user; and
  `M:G` qualifies with M (`coco_colon`, so call/N of a closure `M:C` too).
  The step qualifies on its slow path, after the Call port, as swipl's
  ports show it (Call `p(foo)`, Exit `p(user:foo)`), out of line
  (`coco_step_meta`) on a branch of its own, asked by a bit the
  declaration sets (`pattrs` 512, `coco_pred_meta_note`): **a functor of
  such a predicate is never stamped a plain predicate** (`fgen`), so each
  of its calls takes the slow path and the fast path asks nothing more.
  **A plain predicate's slow path calls nothing it did not call**: with a
  call there for every predicate -- wherever it stood, whatever it took,
  the whole slow path out of line too -- a register of the hot path moved
  and naive reverse paid an instruction an inference (nrev +0.16 %,
  lookup up to +0.79 %, tools/flow/zero.sh); on its own branch the three
  run as 3.44.0's. **Every predicate the slow path resolves is noted
  called** (`pattrs` 128), and **the step qualifies as the declaration
  stood at that first call** (3.46.0, `pmq`, a copy of `pmeta`), as
  swipl's first call built the code that calls it and keeps it till
  abolish/1: a declaration after a call is predicate_property/2's alone,
  so one called before it was declared qualifies nothing and one that
  qualified goes on through `meta_predicate p(?)` (3.45.0 read the spec
  at each call, and that ended it); before the first call a declaration
  made again is the one that stands. **A declaration that sets 512 clears
  its functor's stamp** (`fgen` 0): a call after abolish/1 stamped it
  plain, and a stamped goal never reaches the slow path. library(lists)'
  max_member/3 and min_member/3 are declared, as swipl's; library(apply)'s
  are not, and no answer of theirs would move. **What it costs is the
  call's own**: `:`/2 and user/0 are interned once a machine beside the
  ids (`(":" 2)` and `("user" 0)` in `*functor-names*`, `coco-is-colon`)
  and the clause's predicate read from its functor's cached index -- by
  name, at each call, they cost it some 350 instructions -- and a
  meta-call's goal `user:G` of a predicate the step has stamped plain is G
  (`coco_user_plain`, call/1's and call/N's, untraced), the `:` step and
  call/1's walk for `$/0` (`coco_det_kq`) passed by: stepped through, a
  `call(G)` of a qualified goal cost 1 707 instructions more where it
  costs 642. A declared predicate's call costs 557 more than a plain one
  (the slow path, the new goal, the module), max_member/3 2 359 of its
  10 912, a yall lambda maplist/2 calls 1 001 of 14 889.
* **`$/1` and `@/2` are swipl's control constructs** (3.20.0; `coco_det`,
  `coco_det_exit`, `coco_det_fail` and `coco_at` in lib/solve-loop.cicili):
  `$(G)` pushes a GOAL frame whose alternative is `'$det_fail'($(G), Ctx)`,
  runs G with its own cut and then `'$det_exit'(CI, $(G), Ctx)`, which asks
  whether a frame above CI may still retry -- none DEAD, CATCH_RETRY or
  SPENT, the kinds `coco_catch_exit` passes over: **a new kind that is no
  choice point goes into that list too**. Neither step is an inference
  (`frees`). **Under trace a clause frame stays at its last candidate, and
  its shadow frame's `last` says so**: set by the selection, cleared by the
  traced push alone, which `printr` marks -- a clear in every push cost
  queens 27 032 instructions and lookup 23 415 -- and a frame no traced call
  pushed (trace/0 turned on mid-run) goes at its last candidate as it does
  untraced. A meta-call asks a G@M's module and goal before it runs
  (`coco_goal_check`: 2 an instantiation error, 3 type_error(module, M);
  `coco_goal_formal` builds the ball), so **a new raiser of a meta-call's
  goal that is no goal builds its formal there**. **The list's end is no
  leaf of a structure** (3.47.0, `coco_goal_leaves`' `inner`): `(true, [])`,
  `\+ []`, `$([])` and `[]@user` are type_error(callable, G) of the whole,
  where `[]` alone, its qualifiers off, runs []/0 -- a new walk of a
  structure tells the root from a leaf. The store says G@M of each
  goal under it, as a qualifier is (`coco_cbody`'s `at`, `coco_cbody_wrap`),
  and every refusal walk takes `$` and `@` as control (ids 11 and 12 of the
  consult's and the assert's tables). test/files/det_at.pl holds it to
  swipl, test/engine.pl's `det_traced` the trace.
* **`$/0` is swipl's determinism guard, carried through last calls**
  (3.21.0, lib/solve-loop.cicili's `coco_det*`): `$` cuts as `!` does and
  guards the frame it runs in -- its clause, or the `'<meta-call>'/1` a goal
  holding it is called in -- which must then succeed and leave no choice
  point, else determinism_error(PI, det, fail|nondet, guard|guard_in_caller).
  A guard is a GOAL frame, alternative `'$det_fail0'(D)` (the frame
  failed), `goals` its frame's EXIT MARKER `'$k'('$det_end'(0), Owner, K)`
  (the frame exited: `coco_det_end` asks `coco_det_live`), `barrier` the
  owner word naming the frame, `clause_ix` the guard below it << 2, ORed
  with 1 while it is on and 2 when SET (its own `$` set it). The engine's `dgh` is the
  innermost guard frame plus one and `dgk` its marker while its guard is
  on, else none, so **a last call is a call whose continuation is `dgk`**
  -- one compare where the step calls (`coco_det_pcall`, `coco_det_bfail`,
  `coco_det_meta`, `coco_det_kq`) -- and takes the guard on as swipl's
  I_DEPART does: over the same frame where nothing above it may retry, the
  callee's `$` no longer SET and, for a predicate swipl marks transparent,
  the guard dropped; else in a guard frame of its own. A predicate swipl
  defines in C that cocolog's library writes as clauses is ONE frame
  (`coco_det_opaque`, system:Name/Arity). lib/swipl-det.cicili holds the two
  tables, generated by `tools/det/tables.pl` under the REFERENCE swipl (run
  it again, never edit them). **Whatever moves the choice stack otherwise
  sets the guard again** -- a throw's unwinding and a thaw
  (`coco_det_unwound`), a collection (`coco_det_top`) -- and `$` raises the
  barriers of the cuts after it over its frame (`coco_det_floor`), as a
  cut never clears swipl's flag. **What a clause entry adds is kept off the
  plain path**: `coco_try_clause` hands every clause to
  `coco_try_clause_det` while a guard is on, and a code that holds `$`
  (`ex` 4, below), with its
  own arguments -- a jump -- and the det entry writes no register for a
  guarded frame's last call, so the step that takes the registers asks
  nothing: asked in the step, or with the test inside the body, naive
  reverse paid 3 to 8 instructions a call (3.21.0's zero.sh against
  3.20.0: nrev +0.35 %, queens +0.72 %, lookup +0.58 %). **A local whose
  address the loop takes lives on the stack**: `coco_det_pcall` hands its
  continuation back rather than taking `&k`, which cost nrev a store an
  inference. test/files/det_guard.pl holds 180 lines to swipl 9.0.4,
  test/engine.pl's `det_guard_runs` the trace, the collector, KMAT and a
  freeze; COMPAT.md has what is not swipl's.
* **member/2, select/3, nth0/3, nth1/3 and between/3 leave no choice point
  on their last answer** (3.22.0, swipl's): the first four are swipl's
  clauses, the rest of the list the helper's FIRST argument (`'$member_'/3`,
  `'$select3_'/4`, `'$nth_gen'/5`), so the last element's call, keyed on
  `[]`, has one candidate; between/3's C half decides a bound X itself and
  hands an unbound one the count of the answers after the first, which
  `'$between_n'/3` counts down to a clause keyed on 0 that cuts (`inf` for
  no upper bound, `A+B` for a range whose count passes 64 bits). A
  determinism error names each helper by swipl's own name and module: a
  row of `*frame-contexts*` takes a fourth field, swipl's name
  (`lists:member_/3`), which `coco_det_pi` asks. sub_atom/5,
  atom_concat/3, clause/2 and string_code/3 are deterministic on their
  last answers with them (sub_atom/5 and sub_string/5 where swipl's
  sub_text() is, since 3.58.2, below). **A library predicate that would leave a choice
  point on its last element wants its list first in a helper**, and since
  3.23.0 library(apply)'s are swipl's too: maplist/2..5, include/3,
  exclude/3, partition/4,5 and convlist/3 over `'$maplist_'/2..5`,
  `'$include_'/3`, `'$exclude_'/3`, `'$partition_'/4,5,7`,
  `'$convlist_'/3` (lib/apply.cicili), where through 3.22.0 they wrote the
  goal first and every element left a choice point; partition/5 raises
  must_be/2's type_error(oneof([<,=,>]), O) for an order that is none and
  takes an unbound one as `<`, once. An error in a helper's body names it
  as swipl's (`*frame-contexts*`: apply:maplist_/2, apply:foldl_/4 for
  `'$foldl'/4`, '$apply':apply/2), and apply/2 is swipl's boot/apply.pl
  over strip_module/3. Each is a call deeper: one inference more at entry,
  as swipl's. With the first list unbound and another given, the index on
  that list leaves no choice point either, since 3.24.0 (swipl's JIT index,
  below). **The enumerators swipl writes in C leave none at their last
  answer** since 3.25.0: current_op/3 walks what `'$ops'/4` hands back --
  only the operators the call's bound arguments name, a given name's the
  program's first and the system's after, each prefix before infix, swipl's
  order -- with `'$cp_in'/2`, member/2's clauses under a private name (a
  program's member/2 joins the library's); current_predicate/1 named whole
  and predicate_property/2 with its property named are a memberchk/2, and
  sub_atom/5 and sub_string/5 with the substring given test the place
  Before or After gives, or search its places (`'$sub_search'/3`), keeping
  a choice point after a place only where another place would fit, as
  sub_text() does -- the C half ends the list of places `fits` where room
  is left after the last, and the search reads the end by its first
  argument (3.58.2; through 3.58.1 `'$cp_in'/2`, none at the last place). `'$cp_member'/2`, the goal first, stays where
  swipl's leaves a choice point at every answer, its last too:
  current_predicate/1 with a part of its spec unbound. **A determinism
  error names a library's frame with its module** since 3.26.0, as swipl's
  pl-wam.c does (test/files/det_names.pl): every library(lists) and
  library(error) predicate cocolog writes has a row of
  `*frame-contexts*` (lists:append/3, error:is_of_type/2), each helper its
  row by swipl's name for it (lists:append_/2 for `'$append2'/2`, a C half
  too: lists:sum_list/3 for `'$sum'/3`), a fifth field another arity
  (reverse/2's C half fails as lists:reverse/4), and `'$length3'/3` a
  `system` row, which the formal drops and the context keeps
  (`coco_det_pi` names no `system` or `$` module); **a predicate whose
  first clause a module/2 read added carries that module** (`pmod`, from
  the read's `ssu_mod`, `coco_pred_note_mod`), which `coco_frame_mod`
  hands `coco_det_pi` and `coco_owner_ctx` (assoc:gen_assoc_/3, an
  unknown procedure's context(mn_mod:mn_u/0, _)). **A new library helper
  gets its row**, or its errors name cocolog's `'$...'` name. The
  library(lists) predicates whose frames or answers differed are swipl's
  clauses since 3.26.0: length/2's declined case over `'$length3'/3`,
  append/2's must_be(list, L) (a partial list ran for ever), prefix/2,
  select/4 over `'$select4_'/4`, selectchk/3 committing to the first
  match, nth0/4 and nth1/4 over `'$generate_nth'/5` and `'$find_nth0'/4`
  (a bound index must_be/2's and deterministic), reverse/2's declined case
  over `'$reverse4'/4` (a proper second list ends it), proper_length/2,
  permutation/2 (type_error(list, L)), list_to_set/2 over pairs_keys/2,
  is_set/1 and clumped/2; and since 3.26.1 max_member/2,3 and
  min_member/2,3, swipl's single-sided rules over `'$max_member_'/3,4`
  and `'$min_member_'/3,4` (test/files/max_member.pl): a tie keeps the
  element swipl's keeps, and a list no rule matches raises
  existence_error(matching_rule, lists:max_member_(...)) -- **a
  single-sided rule's last clause takes its row's module and swipl's
  name** (`coco_ssu_last`), so a library helper's rules need their row.
  Since 3.42.1 sum_list/2, max_list/2, min_list/2, subtract/3,
  intersection/3, union/3 and subset/2 are swipl's rules too
  (test/files/lists_ssu.pl): a list no rule matches -- no list, an
  unbound one, the end of a partial one -- raises at the tail it reached,
  and the folds' C walks raise it themselves (`coco_l_no_rule`:
  lists:sum_list(Tail, Acc, Sum), named lists:sum_list/3, the accumulator
  what the elements before made). **A rule set's catch-all clause is a
  second candidate**: each call of a rule pushes a choice point its cut
  takes, and loses the register call -- subset/2's rules cost 41 % more
  than its plain clauses (STATUS.md), where swipl raises from the machine.
  Since 3.42.3 nth0/3 and nth1/3 with the index given bind the unbound
  tail their walk meets to `[_, ..., Elem|_]`, once, as swipl's
  '$seek_list'/4 and nth0_det/3 do (test/files/nth_open.pl; through
  3.42.2 the call failed).
* **library(error) is swipl 9.0.4's** (3.29.0, the Prolog half of
  lib/builtins.cicili; test/files/error_types.pl): must_be/2 asks
  has_type/2 -- one clause a type, in swipl's order, a table a library
  extends (library(assoc)'s `error:has_type(assoc, X)` joins it, one
  namespace) -- and then says why not as swipl's is_not/2 does: an unbound
  value or a partial list an instantiation error, a list of the wrong things
  its first wrong element's error, an improper list `type_error(list(Of),
  L)`, `var` an uninstantiation error, `cyclic`/`acyclic` domain errors, a
  value a ground type holds unbound an instantiation error, and a type no
  clause names `existence_error(type, T)`; is_of_type/2 asks has_type/2
  alone. Through 3.28.0 a table of cocolog's own: `must_be(assoc, A)` raised
  `type_error(assoc, A)` of an assoc, a partial list `type_error(list, L)`
  (ord_intersection/2 and yall's parameters met it), an unknown type
  `type_error(T, X)`, an unbound type read as `any`. **A new type is a
  has_type/2 clause**, never a case in must_be/2, and its helpers have their
  `*frame-contexts*` rows by swipl's names (`error:is_not/2`).
* **A cut runs the cleanups of the frames it takes** (3.1.0,
  setup_call_cleanup/3): a setup_call_cleanup/3 frame is a goal frame,
  `'$scc_fail'/2`, and each of the four cuts -- the goal `!`, `$cut`, an
  environment's CUT and CUTC units -- calls `coco_cleanup_cut` when the
  engine's `ncleanup` says one may be there. **A new cut site does the
  same**, and **a host or a builtin done with an engine that succeeded
  calls `coco_engine_cut`** (findall/3's, with_output_to/2's, the seam's,
  a directive's, each query of cocolog.cicili), or a pending cleanup never
  runs.
* **A check in a clause the recursion comes back to costs every answer**
  (3.0.0): between/3's first cut called its checking C half in its first
  clause, which the enumeration re-entered at each answer, and every
  answer paid a failing C call and a backtrack where 2.16's integer(X)
  guard had failed inside the clause's entry: 1.6 times the time,
  found by test/window.pl's retry counts. Check once at the entry and
  recurse through a helper that checks nothing (`'$between_n'/3`, through
  3.21 `'$between_up'/3`), or let the C half fail where a guard would
  (numlist/3 is one clause over `'$numlist'/3`).
* **The backtrace is written by the throw, before anything unwinds**
  (1.10.17, `coco_bt_capture` beside `coco_throw`), and only for a ball no
  catch on the chain of engines would take as things stand
  (`coco_bt_caught`: it can say "nobody" of a catch that takes the ball
  once the bindings are undone, never the reverse). What keeps it true:
  **the goal in flight is `kcall`** -- set by `coco_builtin_call` and
  `coco_builtin` (one store a builtin call: the only instruction a run
  that throws nothing pays, `tools/flow/zero.sh`), by the module seam as before,
  and at each raise of the step and the constructs (an unbound or
  non-callable goal, an unknown procedure, `throw/1`, `call/N`); **a new
  raise site outside a builtin sets `kcall` first**. **A builtin that
  starts an engine and throws its ball again sets `m->btkeep`** before
  `coco_throw` (findall, `call_metered/4`, `with_output_to/2`), so the
  inner throw's lines -- which already read out through every engine --
  are kept. **An engine whose starter reports its own errors sets
  `btstop`** (a directive's, `lb_goal_hook`), and the starter keeps the
  lines only when its goal raised; a load drops any it finds first
  (`coco_bt_say(m, 0)`). Trace 3 (`--backtrace`) is trace 1 that prints
  nothing: `coco_trace_port`, the Redo and the Fail return at once.
* **A cyclic term (`X = f(X)`) is written, raised, caught and walked**
  (1.10.18, 1.10.19; `test/cyclic.pl`), to swipl 9.0.4's answers. The
  writer asks `coco_acyclic` of the compound it meets 1024 levels down
  (`m->wdeep`; a cycle sets `wcyc` and `wdeep` 0, which stops every compound
  still to be written) and runs Brent's method down a list's tail; the top
  of the write takes back what it wrote and writes `@(S_1,[S_1=f(S_1)])`
  from `coco_factorize`, swipl's text to the letter -- `S_N` under
  numbervars, each bound to `'$VAR'('S_N')` as swipl's writeTopTerm()
  binds them, so a portray goal is asked of one (3.55.0: through 3.54.0
  every write named them but write_term's `variable_names`,
  write_canonical's and the store's, write_term/2 with no numbervars and
  term_to_atom/2 among them), the engine's own writes naming them as
  before. `is/2` and the comparisons ask at the expression's 101st
  compound whether the WHOLE of it is cyclic, and raise
  `type_error(expression, E)`, E their whole argument (3.61.0, swipl's
  valueExpression(); through 3.60.0 1 024 levels down, of the subterm
  there: the bullet on the evaluator below).
  `acyclic_term/1` and `cyclic_term/1` answer. **Every other walk COUNTS,
  and asks or changes course only past its count** -- what it has met
  against what a tree on this heap could hold -- so a term that is no cycle
  pays a decrement:
  - unify counts pairs of compounds down `m->ubudget` (2^20, or the heap's
    length if more, armed again only when it reaches 0, so it runs on ACROSS
    calls), and at 0 the rest of that walk links each pair it enters
    (`coco_unify_linked`: A's header points at B until the walk ends, as
    SWI's do_unify does) -- sound wherever it starts, a link never changing
    a unify's answer. The store's matcher counts the heap's length and hands
    a pair past it to `coco_unify`.
  - compare, `==` and the sorts count `m->cbudget` down from the heap's
    length, per call, the first pair in `ca`/`cb`, and at 0 the walk's EXIT
    asks again from that pair with links (`coco_compare_linked`). SWI links
    from the first pair, so two cyclic terms that differ within the count are
    ordered as their trees are where SWI's links may give no order (the
    case's P and Q: SWI answers > both ways).
  - copy_term/2 stops at `m->wceil` (three times the heap it started from,
    plus 64) and copies again keeping each compound once
    (`coco_copy_shared`): a cycle stays a cycle, a DAG a DAG.
  - the store's put (findall's results, `nb_setval/2`, a ball, a clause)
    stops at `base + 2 * heap_len + 64`, and `coco_store_put_over` asks
    `coco_acyclic`: a DAG is put whole, a cycle as its factors
    `'$cyclic'(T, [V=B, ...])`, counted in `m->cyc_puts`. **A reader of a
    cell that may hold one reads it with `coco_store_read`** (findall,
    `nb_getval/2`, every ball), which binds the factors back once `cyc_puts`
    has moved; `coco_store_get` hands it the factors.
  - assert raises `representation_error(cyclic_term)` when its put counted
    one (the store's length set back), a grammar rule's among them (stored
    untranslated since 3.13.0); dcg_translate_rule/2 and phrase/3 ask
    BEFORE they translate -- the translation recursed through a cyclic body
    to a SIGSEGV -- and raise `type_error(acyclic_term, T)`; the clause
    check counts 4096 goals before it asks.
  - ground/1 and term_variables/2 count the heap's length, then walk again
    meeting each compound once, in SWI's order; unify_with_occurs_check/2
    unifies, then asks `coco_occurs` of each variable it bound, unbound for
    the question.
  - a list that is its own tail: `coco_m_list_length` (and so a module's
    lists), is_list/1, memberchk/2 and the text walks (a code or char list,
    a format's text and `~s`, term_to_atom/2's) count the heap's length --
    the last two down `m->lbudget`, which no two of them hold at once.
    length/2, msort/2, memberchk/2 and the text builtins raise
    `type_error(list, L)` (`coco_list_cyclic`, Brent), a format and
    term_to_atom/2 `type_error(text, L)`; sort/2 and a sort/4 that drops
    duplicates take it as the set of its elements; proper_length/2 and
    is_set/1 ask is_list/1 first.
  **A walk's slow path is NOT STATIC, and its count lives in the machine
  where a local would cost its loop a register** (`coco_compare_linked`,
  `coco_store_put_over`; `cbudget`, `ubudget`, `lbudget`): inlined, the
  linked compare cost every pair 18 instructions; with a local count
  memberchk/2 kept the machine on the stack, +12 % of its cost. Not SWI's
  yet: list_to_set/2 and the library's other clauses walk a cyclic list for
  ever where SWI's must_be/2 raises (append/3 and maplist/N loop in both);
  sum_list/2, max_list/2 and min_list/2 fail of one, past as many steps as
  the heap has cells, where swipl's rules walk it for ever;
  call/1 of `G = (true, G)` runs for ever where SWI refuses to compile it; a
  channel and thread_create/2's goal carry one as the text of its factors,
  which reads back as `@(T, [V=B, ...])`; a format's `~s` and `~a` raise
  cocolog's error for anything not text where SWI says
  `format_argument_type`; the text builtins that write any term
  (split_string/4, string_chars/2, ...) write a cyclic list as its factors
  where SWI raises;
  numbervars/3,4 do since 3.40.0 (swipl's, test/files/numbervars.pl), over
  term_variables/2's walk and in its order, a cycle's too, its
  singletons(true) walking an acyclic term as the tree it stands for (a
  cyclic one marks none, as swipl's). subsumes_term/2, `=@=/2` and `\=@=/2`
  (2.1.0) do, built on the walks above: Specific's variables collected,
  a unify, each variable asked still unbound and none made one (the
  variable map), the unify undone; `=@=/2` asks a COPY of its first term
  both ways, so a variable the two share is not bound across, and sets
  the heap back after; `0.0 =@= -0.0` fails, as unify's floats are SWI's
  since 2.1.1 (below). term_variables/2's collector looks a
  variable up in the map past sixteen (2.1.0; it scanned, and 200 000
  variables took 6.8 s). **A write too deep for the C stack raises
  resource_error(c_stack)** (3.59.0, swipl's writeTopTerm() under
  C_STACK_OVERFLOW_GUARDED; test/files/cyclic_depth.pl, test/cyclic.pl's
  last section): past 1024 levels each compound asks `coco_cstack_room` --
  the calling thread's stack left above its floor, which
  `coco_cstack_bounds` asks of the system once a thread (glibc's
  pthread_getattr_np, Darwin's pthread_get_stack*_np, through the raw-C
  escape) -- and before each portray goal 256 KB of it; with under 64 KB
  the write stops as a cycle stops it (`coco_write_short_stop`: WSHORT and
  WCYC), the top of the write takes its text back and answers 0
  (`coco_write_short_end`), and the builtin raises with swipl's context
  (`coco_cstack_error`; `coco_cstack_error_wt` for portray_clause/1's and
  listing/1's system:write_term/3). **A new caller of the writer asks
  `coco_write_short` after the write** (it clears the flag), or a short
  write is a write of nothing; every write clears WSHORT as it begins, and
  `coco_layout_clause` for its parts, because a consult's refusal of a
  clause its store cannot write as a row leaves it set. Under a depth limit
  (mode 1024) no cycle guard asks: a cyclic term is the tree it stands
  for, to the limit, as swipl's. **A read too deep for the C stack raises
  it too** (3.60.0, test/files/read_depth.pl, test/cyclic.pl's
  `c_stack_read`: the bullet on the reader below), and an expression of
  any depth evaluates (3.61.0, the bullet on the evaluator below; through
  3.60.0 `coco_arith` overflowed the C stack some 43 000 levels down).
  **The
  writer's six arguments
  stay in registers**: quoted, ignore_ops, operand, (2.2.4) numbervars and
  (2.2.5) swipl's character escapes are one `mode` word (1, 2, 4, 8, 16;
  what a compound hands its arguments is `mode & 27`, the operand's 4
  being each operand's own, and what an atom reads `mode & 17`; since then
  64 unicode escapes, 128 write_canonical/1's curly terms and, 3.15.1, 256 a
  control character as it is, term_to_atom/2's and term_string/2's, and,
  3.18.0, 512 a space after each comma (spacing(next_argument), the
  listing's and since 3.19.0 write_term/2's), and, 3.49.0, 1024 a depth
  limit, and, 3.53.0, 2048 dotlists(true) and 4096 no_lists(true), and,
  3.54.0, 8192 portray asked (16384, the term asked already, its own and
  handed on to nothing), and, 3.55.0, 32768 quote_non_ascii(true) (128 is
  brace_terms(false) too, and 256 without 16 character_escapes(false):
  swipl's PL_WRT_QUOTED alone, which term_to_atom/2 writes), so a compound
  and a list hand on `mode & 49115` and an atom reads `mode & 33105`: a new
  bit goes into both masks where an atom needs it; **write_term/2's
  options are a table** (3.55.0, `*wt-options*` in
  lib/builtins-format.cicili, swipl's with each option's kind): its row is
  found once (`coco_wt_opt`, made by a macro) and `coco_wt_put` takes it in
  a switch, so a new option is a row and a case, never a strcmp;
  **partial(true) begins after the last character where the write goes**
  (3.56.0, swipl's PutOpenToken() of the stream's lastc; test/files/
  write_partial.pl): `coco_wt_put`'s PREV, put before the term and taken
  off after it, the gap asked where the portray mark is still the write's
  own (`wpgapb`) -- the console's user_output and user_error each keep
  theirs and a capture its own from none (`coco_out_lastc`, noted by
  `coco_out_note`), a library(stream) file its own, format's own text
  before `~W` and none after a fill point (-2: swipl's text is a
  sub-format's there), so **a new writer that puts text where a write may
  go next notes its last character**, as `coco_out_note` and `st_wrote` do;
  write_term/2's priority(P) is the machine's `wprec`, P plus one,
  read by `coco_write_top` alone, and its max_depth(D) the machine's
  `wmax`, read only under 1024 -- by `coco_write_rec`'s first test, one
  test of 9216 that asks the depth limit and portray out of line
  (`coco_write_ask`, `(weak) (cold)`: unmarked, the zero heuristic gave its
  `r >= 0` return enough of the main path's share that the compound
  writer's `(` and `)` became cold call sites, two calls of `coco_sb_putc`
  a compound, +0.27 % of a write-heavy run), a term past D `...`, and by
  `coco_write_list_cut`, out of line, where the
  K-th element is K deeper than its list and a list past D ends `|...]`,
  swipl's writeTerm() and writeList(); one instruction a term written
  where no limit is set; **the list writer asks ONE test of the three
  bits, 7168**, and the cut writer hands 2048 and 4096 on to
  `coco_write_list_dots`, `.(H,T)` or `'[|]'(H,T)`: with a test of its
  own for them in `coco_write_list`, the list writer kept its mode on the
  stack and paid nine instructions a list written, +0.32 % of a
  write-heavy run, where one test pays none), and a compound
  is `coco_write_fun`, always inlined, so the
  guard's slow path returns rather than rejoining -- rejoined, every
  compound read its tag and functor again (21 instructions each).
* **print/1, `~p` and write_term/2's portray(true) and portray_goal(G) ask
  portray/1 as swipl's pl-write.c does** (3.54.0, test/files/portray.pl):
  each term but a variable, the term first, the depth limit before it --
  where the program has a clause for it (`coco_portray_defined`, the name
  interned once a machine, `*functor-names*`), as swipl asks it only then,
  portray/1 declared in user, dynamic and multifile, by the builtins half
  as swipl declares it (a call with no clause fails; listing/0 writes the
  two declarations) -- and portray_goal(G) is `call(G, T, Opts)`, Opts the write's options
  less every priority(_) and the term's priority(P) last; either implies
  numbervars(true) unless the options say. **The goal is a search of its
  own with its output captured**: `coco_portray_call` (the engine's
  `coco_portray_hook`) runs it through `coco_out_capture_run`, NODEBUG
  (untraced, as swipl's PL_Q_NODEBUG), its bindings undone, the writer's
  state of the machine saved around it and its cells given back, no
  deeper than 100 (`wpnest`, swipl's MAX_PORTRAY_NESTING:
  resource_error(portray_nesting) in the innermost write's context). Its
  text is put on the write's buffer: no gap goes before it, as each of
  swipl's writes starts afresh (`wpfirst`, which an operator's writer saves,
  nils and compares around its operand: `1+-1`, `--1`), and a goal that
  failed having written leaves its text and the term after it, a space
  between where the two would read as one token (`coco_write_gap_at`,
  `partial w`), none where that term's first text is a goal's too
  (`wpgapb`, 3.55.0: `pgpg a`, where 3.54.0 wrote `pg pg a`) or a string's
  unquoted text (3.56.0: `pgs`, as swipl's PutString asks no token).
  **A goal that
  threw stops the write**: nothing more is
  written (`wpstop`), and what a parent wrote after the stop is taken back
  (`wpcut`): **an operand written into a buffer of its own carries the stop
  up as it is put on its parent's** (`coco_write_cut_up`), so a new writer
  that renders a part apart calls it too. The ball waits on the machine
  (`wpstate`) for the builtin to raise once its own text is out
  (`coco_portray_after`, format's kind 13), and fullstop(true) and nl(true)
  write nothing after it. A compound under portray is written by
  `coco_write_fun_p`, the P=1 copy of `coco-write-fun-body` (the plain
  writer is its P=0 copy, 3.53.0's code but for its mask), and a cyclic term is
  written in its factors from the first unless a depth limit is set
  (`coco_write_portrayed`), so no goal is asked of the term unwound.
  print/1 is the builtins module's (`coco_print_hook`), and **the tracer
  writes a goal as print/1 does** (`coco_trace_text`, `coco_b_trace_text`:
  `print(f(zz))` where portray/1 writes `zz`, swipl's), a ball its goal
  threw given back unraised (COMPAT.md). A goal that halts ends the
  process, the write's text before it put out (3.57.0, `wpstate` 5: the
  bullet on exit status). Not swipl's: the REPL's answers ask no
  portray/1 (COMPAT.md).
* **A load warns in swipl's two blocks** (3.17.0, 3.19.1, 3.19.5;
  `coco_consult_singletons`, `coco_cw_clause` in lib/kb-consult.cicili):
  the reader's `Singleton variables: [X]` as the term is read (`_X` and
  `__x` exempt, `_x` not), and the compiler's -- a singleton-marked name
  used twice, a branch's or a \+'s singleton, a test whose answer the
  compiler knows (`X==Y` of a variable no goal set, `var(X)` of one,
  `atom(f(X))`) -- once its clause is stored, after the not-together
  warning. **It is swipl's two passes** (pl-comp.c, since 3.19.5): the
  count of the variables (`coco_cwa_walk`, a disjunction counting the
  variables new to it as its larger branch) and the compile
  (`coco_cwc_walk`, every goal setting what it names but the tests
  compiled in place); a new control construct goes into both, and a
  grammar rule's body is its translation's (`$/1` and `@/2` are
  non-terminals there). test/files/warnings_branch.pl and
  test/files/warnings_tests.pl hold the rules to swipl. **A file of the
  tree loads with no warning**
  (library/reasoning/ too since reasoning 1.0.30): a variable a
  clause never uses is `_`, and one it uses twice is named plainly, never
  `_X` -- the walk found a check in test/template.pl that tested nothing.
  **A predicate's clauses stand together**: reasoning 1.0.30 moved 159
  blocks of translate.pl (and 8 of reason.pl, normalise.pl and
  corpus/build.pl) up to their predicate's first clause, each predicate's
  clauses in their order, which a dump of every clause before and after
  holds equal; a helper goes after the predicate whose clause calls it,
  never between two of its clauses.
* **A directive is a GOAL.** `coco_directive` answers the ones that act on the
  reader (`op/3`, `set_prolog_flag/2` of `double_quotes`, `text_units` or
  `generate_debug_info` -- any other flag is the goal's since 2.2.2,
  `coco_reader_flag` --, `dynamic/1`, `discontiguous/1`,
  `multifile/1`, and since 3.2.0 `public/1`, `volatile/1` and
  `module_transparent/1` when their spec is plain (kinds 3 to 5 of
  `coco_decl_kind`; `thread_local/1`, kind 6, is always the goal's, which
  refuses a predicate with clauses), `module/2`, `use_module/1,2`,
  `autoload/1,2`, `ensure_loaded/1`, `meta_predicate/1` (a spec the goal
  would refuse is the goal's since 3.46.0, as op/3's: its error and the
  failed directive, swipl's two reports, the heads before the fault
  declared; through 3.45.0 any spec was taken in silence),
  `if/elif/else/endif` -- an `if` decided below the engine,
  `coco_cond_eval`: `true`, `fail`, `false`, `\+` and
  `current_predicate(Name/Arity)`, which answers as the goal does since
  3.31.0, anything else refused by name) and calls everything else in file
  order. The four
  record an attribute, `pattrs` on the predicate (1 public, 2 volatile, 4
  transparent, 8 thread_local), that predicate_property/2 tells; only
  thread_local/1 defines the predicate (dynamic), so a call of what public/1
  alone named is an unknown procedure, as swipl's. `initialization(G)` runs after the file is
  read, `initialization(G, now)` where it stands, `initialization(G, main)`
  after the WHOLE load and then halts (3.7.0, swipl's): a nested read hands
  its main up to the outermost read's list (`ltop`, the reads under way
  counted in `lreads` by `coco_consult_oid`), which runs every after_load
  goal first and then the last main registered; a main is no definition
  (`ldefs`), and one in a read that defined nothing is dropped, as swipl
  drops it. The CLI's own goal is not run after a main (COMPAT.md: swipl's
  `-g` goal is). A directive that fails or throws is
  reported in SWI's shapes and the load goes on; **so does a load past a
  syntax error since 3.1.0**, as swipl's (through 3.0.4 it was the one
  thing that ended a consult): the clause is reported and passed over, the
  reader taken up after the full stop that ends it, walked from the
  clause's first byte as swipl's raw read walks it (`coco_reader_resync`,
  the reader's `cstart`, over `coco_raw_walk` since 3.10.0). So are an endif, else or elif with no if open,
  an if the file never closes (named at its end), and a term that is no
  clause -- `3.`, `foo :- 3.`, `bar :- (a, 1).`, since 3.19.2 `p :- foo:3.`
  and `3:foo.` (the qualifiers taken off, a goal under `M:` walked: one
  set of rules on two walks, `coco_consult_refused` and assert's
  `coco_clause_check`: a new rule goes into both), since 3.19.3 `p :-
  (X ; X).` and `p :- M:foo.` (a variable goal swipl's count takes for a
  singleton, a variable module no goal set: `coco_fresh_fault`, the one
  walk both ask once theirs met a variable there) -- in swipl's words;
  `[].` passes in silence, and a variable is reported where swipl's load
  aborts (COMPAT.md). A `use_module`/`ensure_loaded` that
  loads nothing is reported the same way (since 1.8.39: SWI's ERROR
  `source_sink ... does not exist`, then the failed directive; it used to
  be SILENT), except SWI's names for what cocolog carries elsewhere --
  `error`, `dcg/basics`, `dcg/high_order`, `lb_carried` in
  `lib/library.cicili`. A module is claimed BEFORE its consult,
  so a goal directive in a module (and every `-s` program is one) no longer
  re-consults it. **source_location/2 answers while a directive's goal
  runs** (2.16.0, `sloc_file`/`sloc_line` on the machine, set around the
  goal and put back after it: a nested load has its own), the file by its
  absolute path (3.4.0, swipl's: `.` and `..` folded, no link resolved;
  through 3.3.0 realpath's), and fails anywhere else -- in the program, and
  in an initialization/1 goal run after its file -- as swipl's;
  print_message/2 asks it for an error's and a warning's location line. A
  load's relative name is looked for beside that file first (the bullet on
  where a load looks, above). **The engine's own
  reports are its own** (`coco_load_message`, `coco_load_note`, the goal's
  ERROR): swipl's shapes, but no print_message/2 call, so a program's
  message_hook/3 does not see them where swipl's does.
* **Consulting a file REPLACES the clauses it put in the store last time**
  (per-clause `origins`; `'$from'(Path, Clause)` on the wire); asserted
  clauses and other files' are untouched.
* **A single-sided rule is stored `Head :- '$ssu', !, Body`** (3.19.0,
  `Head, Guard => Body` with the guard before the cut; `coco_assert_from`):
  the clause compiler takes the mark off and compiles the head with the
  `_S` opcodes, which match as subsumes_term/2 and bind none of the call's
  variables (`cc_head_ssu`, out of line, reached by every head program's
  default case -- a new head executor's default goes there too). A read's
  end puts `H :- '$ssu_none'(Mod, H)` after each predicate it gave rules
  (`ssu_pis` on the machine from the read's own base, `ssu_mod` set by
  module/2), and an assert keeps it last; it raises
  `existence_error(matching_rule, Goal)`. **A new reader of a clause's
  body shows a rule through `coco_ssu_body` (clause/2's) or
  `coco_ssu_rule` (listing/1's) and hides the last clause**, as
  predicate_property/2's count does.
* **A clause is stored as swipl's compiler keeps it** (3.15.0,
  `coco_clause_compile` in lib/kb-consult.cicili, at every assert,
  consult and read of a stored clause, so clause/2, listing/1 and
  retract/1 see what swipl's see): the body's conjunctions one, in the
  arms of `;`, `->`, `*->` and `\+` and never in a goal's argument; a
  variable goal call/1 of it (`M:X` call(M:X)); a bar `;`; `f()` the
  atom; `user:G` G, and any other qualifier said of each goal under it,
  lost by the ones swipl compiles in place (`coco_cbody_inline`: `!`,
  `true`, `fail`, `=`, `==`, `\==`, the type tests), and under a variable
  M each goal call(M:G); a `=/2` with a variable the clause names
  nowhere else `true`, and since 3.48.3 one of a variable with itself
  (`X = X`, swipl's compileBodyUnify() I_TRUE, test/files/clause_body.pl),
  which names its variable nowhere for the move below
  (`coco_cbody_selfeq`, the walk `coco_cbody_goal` makes, so a new
  compiled-in-place construct goes into it too); and under
  `optimise_unify` the unifications that
  begin the body moved into the head (`coco_cbody_scan`: a `true` or a
  `=/2` passed, anything else ending the walk, a qualified one too, read
  from the clause as written) -- **of a static predicate's clause only**,
  as swipl's: a file's, a library's, and the first an assert gives a
  predicate with no clauses that was never declared dynamic; a later
  assert, a `:- dynamic` predicate's clause and one of a predicate
  retractall/1 made are kept as written, and so is a clause the backend
  kept, read back (the store's `nomove`). **retractall/1 of a predicate
  with no clauses declares it dynamic** (`coco_retractall_none`, swipl's;
  not under a builtin's name, where swipl raises). A body that changes
  nothing comes back as the same cell, and the clause's variables are
  counted (`coco_cbody_count`, the machine's variable map) only when a
  `=/2` asks. **A variable moves only where the clause names it nowhere
  else**: swipl's moves it anyway, and its stored clause then means
  another thing (`p(X, Y) :- X = f(Y), Y = 1` succeeds for `p(f(2), 2)`
  there; COMPAT.md). What runs is the source's in every case, but the
  counts move: a nested conjunction is no construct step any more, a
  variable goal is call/1's step and the goal's, a distributed qualifier
  a free step per goal, and a moved unification no step and an index key
  (a call keyed on it, where a variable head left a choice). **A new
  compiled-in-place construct gets its kind** (`coco_cbody_kind`) and its
  walk, or its arms keep their nesting.
* **An uncaught exception reads as SWI's sentence** (`coco_error_text`):
  `Unknown procedure: main/0`, `Unknown message: Ball`. **An unknown
  procedure's ends on the predicates its name is near** (3.3.0, swipl's
  dwim: `However, there are definitions for:` and a line each), from
  `coco_b_dwim_text` in lib/builtins-db.cicili, which the builtins module
  installs as the engine's `coco_dwim_hook` (null in a test binary: no
  lines), and for print_message/2 from `'$dwim_predicates'/2`. The system's
  names are swipl's own, `lib/swipl-system.cicili`, generated by
  `tools/dwim/system.pl` under the REFERENCE swipl (run it again, never edit
  the table), each offered only where cocolog defines it. So
  `coco_error_text` takes the store whose program it offers, and **the text
  runs to several lines: a new printer of it puts its tag before each**
  (`coco_say_lines`, `coco_load_message`) **and gives it a buffer fifty
  names fit** -- 4096 where every report's went through 512 until 3.3.0
  cut them (test/errors.pl's fifty-name checks, one a path).
* **There is a string type** (cell tag `STR`); `double_quotes` takes `codes`
  (default), `chars`, `atom`, `string`, for the REST of the file, per
  machine, forced back to `codes` across a module load. **A string does not
  survive the store or a channel** -- it comes back as codes (canonical text
  is read with the flag honoured; splitting the readers is the unfinished
  fix).
* **A `throw/1` inside `findall/3`, `forall/2` or `aggregate_all/3` reaches
  the catch around it**, and a `catch/3` whose goal exited stops catching
  (`'$catch_exit'`) -- and, with nothing above it left to retry, takes its
  frame with it (1.13.4, SWI's I_EXITCATCH; through 1.13.3 a recursion that
  caught around a deterministic call kept a choice point a turn). The
  marker's arm is the (weak) `coco_catch_exit`: a store written into the
  inlined construct code moved the step loop's registers. **forall/2's
  search ends at its first counterexample** (3.16.0, `rootn` 2 in
  `coco_engine_findall`, swipl's `\+ (C, \+ A)`): through 3.15.2 it went
  on, and every action after the one that failed ran, its writes with it.
  **Its condition runs before its action is asked** (3.47.0): an action
  that is no goal raises once the condition has an answer, never before --
  `forall(fail, _)` holds -- the condition run alone as `(C, true)`.
* **Text builtins work on CHARACTERS, SWI's, and on BYTES when a program
  asks** (`text_units`: 1.13.0, and characters the default since 2.0.0;
  bytes were through 1.x). A code is a code point, a char one character of
  however many bytes, in the text builtins, the reader (`"..."`, `0'c`),
  format's `~c`, `~s` and codes/chars sinks, char_type/2 (past ASCII as
  glibc's C.UTF-8 classes them, swipl on Linux: lib/swipl-ctype.cicili's
  tables since 3.30.0, every code point's classes and case),
  read/write_file_from_codes, library(stream)'s text streams,
  library(process)'s output, library(text) and the document libraries'
  character references. A byte that is no UTF-8 decodes to U+DC00 plus the
  byte and encodes back to it (`coco_utf8_get`/`_enc`), so a binary file
  read as codes goes back byte for byte. `:- set_prolog_flag(text_units,
  bytes).` -- or `COCOLOG_TEXT_UNITS=bytes` for a run -- gives 1.x's
  answers, per machine (`m->text_chars`, kept in a frozen machine's `U`
  section, and a blob with no `U` thaws in bytes; the directive also sets
  the process default, `coco_text_default`, so a thread or
  `run_isolated/2` made after it counts the same): `atom_length('dár', N)`
  is 4, `atom_codes/2` gives the UTF-8 bytes, `char_code(X, 225)` one raw
  byte, `sub_atom/5` can cut a character in half, `upcase_atom('dár', U)`
  is `DáR`, `atom_chars('dár', L)` is four one-byte atoms that join back to
  `'dár'`, and `atom_chars(X, [d,'á',r])` raises `type_error(character,
  'á')` (through 1.11.7 a SEGMENTATION FAULT). **`string_bytes(Text, Bytes,
  utf8)` (2.0.0, SWI's) is the crossing that does not move with the
  units**: a text's UTF-8 bytes, or the string of some bytes -- what
  `atom_codes/2` is under bytes. **A socket is bytes**: `library(tcp)` and
  `library(tls)` read and write 0..255 whatever the program counts, and
  `library(http)`, `library(httpd)`, `library(websocket)` (a text message;
  a binary one is bytes) and `library(curl)` cross at the wire with
  string_bytes/3, handing the program text in its units (2.0.0: through
  1.15 they handed bytes, and under characters a path `caf%C3%A9` was
  `cafÃ©`, a websocket refused to send `héllo`, a body went out a byte a
  code point with a Content-Length of characters, and curl's bytes past 127
  came back negative in either unit). A NEW LIBRARY THAT MAKES AN ATOM FROM
  WIRE BYTES, OR WIRE BYTES FROM THE PROGRAM'S TEXT, GOES THROUGH
  string_bytes/3, never atom_codes/2. A binary stream is bytes, the writer
  leaves `dár` bare since 3.35.0 (the reader takes a name past ASCII, in
  either unit: its text is UTF-8, the bullet on names past ASCII below),
  library(text)'s regexes match bytes, and library(flow)'s widths and
  columns ask the flag past 127 (a code of 128..191 is a continuation byte
  only under bytes). test/units.pl holds it to swipl. Under bytes, build
  and take apart accented text with atom_concat/3 (modes -,+,+ and +,-,+),
  atomic_list_concat/2 and member/2 over a list of the suffixes, as
  tr_stress_stem/2 does. **A syntax error in a load is
  placed** (1.11.9): `ERROR: FILE:LINE:COL: Syntax error: REASON`, the column
  from 0 as swipl's (characters to the clause's start and bytes from there,
  since 3.35.0: the bullet on names past ASCII), from `run` and `-s` alike -- a module's names
  ITS file, through `use_module` and through the load a goal's ask makes
  (`load_err` on the store) -- and since 3.1.0 the load goes on past it.
  Through 1.11.8 `run` said a byte offset and `-s` only `its clauses would
  not consult`. **The REASON and the place are swipl's since 3.10.0**
  (`coco_reader_load_error`, `coco_syntax_sentence` in lib/syntax.cicili):
  messages.pl's sentence for swipl's id, and swipl's place, the clause's
  RAW text walked from one column past its first character for the
  error's characters less one -- columns in bytes from the clause's start,
  the character right before the token counted by its bytes too (3.35.0),
  a comment's character one, so a token on a later line of its clause is a column short
  (`g(x\n  y).' says 2:1); what the raw read refuses is the first
  character's column plus one, no full stop before the end is
  end_of_file at the last character, and a block comment open before
  anything was read is 0:1. Through 3.9.0 cocolog's words (`expected a
  term`) at the token. **Swipl's id is decided where the reader fails**,
  as pl-read.c's complex_term decides it (the reader's `esyn`, `eopen`,
  `eops`, `eopc`, `epn`, `clash_*`): a term wanted and not there is settled
  at its bracket (`coco_term_close`: a clash among the operators pending,
  punct(Op, Next), operator_balance, end_of_clause, cannot_start_term,
  quoted_punctuation), a bracket that does not close at its token
  (`coco_close_fail`: list_rest, cannot_start_term, operator_expected),
  a clash where the term ENDS, at the operator whose operand is too much
  (3.62.0, `coco_term_misfit`, `coco_term_pending`: the bullet on the
  reader's operators below), and the lexer's reasons named by
  `coco_reader_id`. **A clash is placed at its operator, never at the
  token that ended the term**: a text read's place of an error at the end
  of a text with no full stop is the `.` swipl puts there, but a clash's
  (`a , rr b *` clashes at the `*` the text ends on: `coco_tx_syntax`). **A new way for the parser to fail decides its id
  there too**, or it says operator_expected. **ONE raw walk serves the
  resync, a load's place and a text read's Raw** (`coco_raw_walk`,
  pl-read.c's raw_read2): a quoted item walked with swipl's escapes (an
  octal or hex escape takes the character after its digits), `0'c` and a
  radix's quote no quoted item, a run of symbols one token, a full stop a
  `.` before layout, a `%` or the end. **A text read raises
  error(syntax_error(Id), string(Raw, Pos))** (3.10.0, `coco_tx_syntax`
  in lib/solve-text.cicili; term_to_atom/2 and its three kin): Raw the
  raw read's text, Pos its characters before the token less one, one term
  read and a full stop ending it (`a. b` is `a`); an uncaught one is said
  with its `** here **` lines (`coco_err_extra`). **A stream's read raises
  error(syntax_error(Id), file(F, Line, LinePos, CharNo))** (3.11.0,
  `stream(S, ...)` for a standard stream and for a block comment open
  before anything): library(stream) cuts the stream into clauses with the
  same raw walk (`coco_m_raw_walk`) and asks `coco_m_syntax_at` for the
  place -- a load's Line and LinePos, CharNo the clause's first character
  and the text read's Pos. test/files/syntax_text.pl holds 360 lines of it
  to swipl, test/files/syntax_load.pl 47, test/files/syntax_stream.pl 99.
* **`atomic_list_concat/3` with a bound third argument and a non-ground list
  SPLITS**; `/2` cannot split; `atom_concat/3` has `(+,-,+)` and `(-,+,+)` but
  no `(-,-,+)`; `string_concat/3` only `(+,+,-)`. **`sub_atom/5` and
  `sub_string/5` walk only what is not given** (3.58.2, swipl's
  sub_text(); `'$sub_text_'/9` in lib/builtins.cicili, a clause a case
  `'$sub_text_length'/9` names, test/files/sub_text.pl): two of Before,
  Length and After given are the third worked out, one of them walks the
  other two, and a substring given is a test where Before or After is,
  else one scan for its places. The C half `'$sub_text'/8` works out
  whichever of the three a clause leaves, Length from a Sub given, which
  its clause names with `test`: **whether Sub was given is the case's
  word, never what Sub is bound to when the C half runs** -- a walk binds
  Before or Length first, and a Sub that is the same variable is an
  integer then (`sub_atom('1', 0, L, _, L)` fails in swipl, and 3.58.2's
  first cut compared its text and said L = 1). Through 3.58.1 they walked
  Before and Length whatever was given -- `sub_atom(A, B, 3, 0, S)` on
  100 000 characters was 900 019 inferences, 9 now, and sub_string/5 cut
  a list of codes from the start at every place: its search for a
  substring at the end of 100 000 characters took 5 billion inferences
  and 254 s, 11 now. With nothing given they walk every place still:
  `atom_concat/3`, `memberchk/2`, `split_string/4` in a hot path.
* **A call is keyed on whichever bound argument chooses** (since 1.9.1):
  the first argument's table as always, and for a predicate the first
  argument will not do for (`coco_pred_first_enough`: at or over the floor
  of 8 clauses, with the call's first argument unbound, or the longest
  key's chain and the variable heads together over 4) a table per
  argument 2 to 8 (`coco_argix`), built the first time a call wants one,
  kept by `assertz` and by a retract that leaves the clause dead in place
  (below), dropped by `asserta`, a retract that takes the clause out, a
  sweep of the dead and a reconsult. The
  argument with the fewest candidates wins (`coco_pred_select`), once per
  call, and the choice rides in the choice frame (`ixpos`, never frozen: a
  thawed frame is keyed on the first argument, which is always sound); a
  retry starts from the chain link of the clause just tried, so
  backtracking through one key's clauses is linear. **A call with no bound
  argument still walks the whole predicate**; a hit hides it, a miss or a
  `findall` pays it. To read a predicate's heads, `clause/2` enumerates
  them; calling the goal proves it.
* **Under the floor, swipl's JIT index chooses** (3.24.0, `coco_pred_jit`
  in lib/kb-pred.cicili): `coco_pred_probe` answers 3, a 2, where swipl's
  first_clause_guarded would ask another argument -- the call's first
  argument unbound, or its first two candidates both of its key -- and the
  step's term path asks `coco_pred_jit` out of line (`coco_term_jit`): of
  the call's bound arguments 1 to 8 the one swipl's assessment over the
  clauses promises most of (`coco_jit_assess`, bestHash's N*D/(N-V+V*D)
  over 1 + stdev*D/N, nothing where the clauses with no key there pass a
  tenth of D), the first on a tie, the first argument's own walk where that
  one wins. The assessment is kept until `tver` moves (`j0ver`/`j0spd` on
  the predicate, `aver`/`aspd` on the argument's table). A call from the
  registers whose probe answers 3 goes the long way below (a fourth arm in
  its test made a jump table, five instructions a call), and a traced call
  is keyed on the argument an untraced one would be (`coco_trace_kpos`, in
  the trace's own arm of the test: a test at the frame's push cost queens
  0.2 %), so a `$` answers under trace as without. **A new caller of
  `coco_pred_probe` reads its 3 as 2, or asks `coco_pred_jit`.** Not
  swipl's (COMPAT.md): no deep index, no index of two arguments, a float's
  or a string's key is none, each call chooses afresh where swipl walks an
  index it built, and swipl 9.0.4's misreading of a key after two
  anonymous variables in a row is not copied. test/files/jit_index.pl
  holds 78 lines to swipl, test/engine.pl's `jit_runs` the trace, the
  collector and the choice made again.
* **A call sees the clauses that stood when it began** (ISO's logical update
  view, swipl's; through 2.2.5 a retry read the live list). A clause frame
  carries `cend`, the clause count at its push (both push sites), so what is
  asserted while it is open lies past its end, and asserta moves the open
  frames on (`coco_frames_on` act 2: `clause_ix`, `cend`, of each frame at
  or past AT -- 0 for asserta, a re-read's insert its own place, 2.14.1;
  act 3 counts the frames an insert at AT would show a clause to). A retract while a
  frame is open on the predicate marks the clause DEAD IN PLACE (`tomb[i]`,
  the death's number, `tera` the last given; `ntomb` counts them) and the
  index keeps it; a frame sees a dead clause when it lived through the death
  -- `fera`, the first death it lived through, stamped at the death
  (`coco_tomb_open`, act 1), never at the push -- and a new call sees none.
  The probe reads `nprobe`, the count while nothing is dead and 0 otherwise,
  so its one test of its count also sends a predicate with dead clauses out
  of line (`coco_pred_probe_cold`, weak): a test of `ntomb` beside it was two
  instructions a call, nrev +0.64 % of 2.2.5's work where this is +0.32 %.
  The clock is placement's here (STATUS.md): nrev +10 % as built and +1.9 %
  with every function on a 64-byte line, queens +0.1 % and +5.3 %.
  The dead are taken out (`coco_pred_sweep`) when no frame is open on the
  predicate: a retract, assert or reconsult then, every 256th out-of-line
  probe, a walk of retract/1's or clause/2's as it begins (through 3.27.0
  clause/2's `'$pred_count'`), and every query's start (`coco_tomb_sweep_all`
  over the store's `tpreds`) -- on a store no other machine shares (3.28.0,
  `machines` nil: through 3.27.0 a green task's start swept the dead under
  another task's open call, which went on from a place that had moved).
  **A reclamation of the whole store asks `machines` first**: a green
  world's tasks share the store, and a task's own heap and its query's
  start say nothing of another task's frames and environments. `coco_frames_on` walks `m->eng` and each
  engine's `outer` over the same store, the predicate's `framed` saying
  whether a frame may be open (set at every push and restore, cleared by a
  walk that finds none). **A new reader of the clause list skips
  `coco_pred_dead`** (listing, the backends' sync, predicate_property/2's
  counts; retract/1's and clause/2's walk through `coco_frame_next`, which
  tries a dead clause only where the walk lived through its death), **a new writer
  of `nclauses` or `ntomb` calls `coco_pred_nprobe`**, and **a new push of a
  clause frame sets `cend` and `framed`**. A freeze writes a frame's next
  clause and its end as counts of LIVE clauses (`C`, `L`), the knowledge base
  a thaw reloads holding no others; a frame thawed from a blob with no `L`
  has `cend` 4294967295 until the run's first step binds it to the reloaded
  base (`cunbound`, `coco_frames_bound`, after the module clauses load:
  bound at the restore, member/2's frames saw an empty store).
  `test/files/update_view.pl` holds 34 cases to swipl, `test/engine.pl`'s
  last section the freeze and a second process.
* **retract/1 and clause/2 are constructs that walk the clauses that stood
  when they began** (3.28.0, swipl's pl_retract and clause/2;
  `coco_db_walk` and `coco_db_retry` in lib/solve-db.cicili; `'$retractall'/1`
  keeps the C half, `coco_bi_retract`): keyed as a call of the predicate is
  (`coco_trace_kpos`, the JIT index's argument), each candidate copied from
  the store and its head and body unified. A second candidate pushes a DB
  frame (`COCO_CH_DB`) whose `pred`, `clause_ix`, `cend`, `fera` and
  `ixpos` are a clause frame's, so `coco_frames_on` keeps its view and a
  retract under it kills the clause in place; the last candidate pops it
  (no choice point, as swipl's). An answer on a clause retracted since is an
  answer and takes nothing (swipl's retry succeeds on a clause erased
  since); retract/1 takes no single-sided rule nor the `'$ssu_none'` clause,
  as swipl 9.0.4's takes no rule, and clause/2 shows a rule as
  `coco_ssu_body` does. One step and one inference each, as the builtin
  was; the errors are the goal's own row's (`kcall`, `*error-contexts*`'s
  `("clause" 2)`), the ports a traced builtin's (PRINTR 2 hidden). **A new
  reader of a choice frame reads a DB frame as a clause frame where the
  view or the place is asked** (`coco_backtrack`, which retries it through
  `coco_db_retry`; `coco_frames_on`; the freeze's `C` and `L` and the
  restore) **and as a `;`'s GOAL frame where the printer's Redo is**
  (`coco_trace_redo_at`): its shadow frame holds its context, never a
  call's depth. **A walk sweeps its predicate's dead as it begins**, where
  no frame is open on them (`coco_tomb_try_sweep`, as clause/2's
  `'$pred_count'/3` did): a retract under the walk's own frame leaves the
  clause dead in place, and a drain by `once(retract(q(_)))` that swept
  none counted nothing dead and never compacted the store (test/gc.pl's
  thousand of 1 500 wide clauses), though it ran 38 % faster. `'$clause'/3`
  and `'$pred_count'/3`, clause/2's halves through 3.27.0, are gone, and
  cocolint's card row R1 with them (27 rows):
  library/flow reads both as builtins (`flow_kind`'s construct row) and
  offers them as near names (`flow_lib_pred`). test/files/retract_view.pl
  holds 110 lines to swipl, test/engine.pl's update-view section the freeze.
  **clause/2 of a predicate written in C raises**
  error(permission_error(access, private_procedure, N/A),
  context(system:clause/2, _)) (3.38.0, swipl's pl-proc.c;
  `coco_db_private`): what listing/1 writes as `%   Foreign:` -- a
  construct, a C row, and a library's clauses where swipl writes it in C
  (between/3, sub_atom/5) -- unless the program defines the name itself
  (msort/2 a file took over, and the facts library(reasoning) asserts
  under number/1's name, which it reads with clause/2 and must go on
  reading). Its head's qualifiers come off as PL_strip_module() takes them
  (`coco_db_unq_atoms`): an atom's alone, so `M:p` with M unbound, or
  `[]:p`, is a head of (:)/2, and the innermost `system` asks the system's
  definition alone (`system:msort(_, _)`). test/files/clause_private.pl
  holds 219 lines to swipl.
* **abolish/1,2 are swipl's** (3.36.0, `coco_abolish_pi` in
  lib/builtins-db.cicili): the clauses go by the forget walk a reconsult
  takes (`coco_pred_forget_where`: mute 4 every one, and for a library's
  predicate -- `library` and not `own` -- mute 3, the program's clauses
  alone, so member/2 answers on), then the declarations
  (`coco_pred_undeclare`: dynamic, discontiguous and multifile, `pattrs`),
  so a call raises existence_error; an ISO predicate (`*iso-predicates*`,
  exactly swipl's 158 locked ones) and a thread_local one are refused, and
  a taken one stays taken. **A backend hears the withdrawal as `on_dynamic`
  with the predicate's DYNAMIC 0** (the Zigurat hook calls
  `cocolog::forget` then), told whether or not this process knew the
  predicate dynamic -- a process learns a declaration only on the way to
  an existence error (`warmed`), and the first cut, which told only of one
  it knew, left the row for the next process -- and the table a fresh
  store reads forgets it (`coco_dynamic_forget`). **A new backend's
  `on_dynamic` reads DYNAMIC** to tell a declaration from a withdrawal.
  test/files/abolish.pl holds 88 lines to swipl, test/reconsult.pl's
  `abolished` the second process and the fresh store.
* **listing/1's argument is swipl's** (3.37.0, `coco_listing_spec` and
  `coco_listing_one` in lib/solve-db.cicili, swipl's listing_/2 and
  '$find_predicate'/2): the meta-argument's qualifiers are taken off (one
  namespace; a variable one is every module and ENDS the strip, so
  `_:user:yy/2` asks for (:)/2), an unbound spec is its module's own
  predicates (`coco_listing_module`, swipl's list_module/2: listing/0 and
  `listing(_)` user's, where a module/2 read's file is its module's,
  `listing(lsm:_)` lsm's, `listing(_:_)` the program's of every module, no
  name of `$`, a blank line before each), a proper list each element in
  order (their own qualifiers off for the search alone, `[lsm:_]` lsm's as
  `_/_` finds them: an unbound name keeps to its qualifier's module, a
  name given never), `Name//Arity` evaluated (`'$dwim':name_arity/3`,
  the `:MAP` row), a compound a head the clauses are picked by (unified and
  undone, so it binds nothing), and anything else
  type_error(predicate_indicator, S); a negative arity of an atom name,
  known or not, is domain_error(not_less_than_zero, A) as functor/3's, and
  a name found nowhere error(existence_error(procedure, S),
  context(toplevel, 'DWIM could not correct goal')) -- swipl's toplevel
  offers a near name on its terminal, cocolog none. **The candidates are
  read FIRST** (`coco_pred_ensure`): a backend predicate keeps its clauses
  until called, and the first cut called a second process's consulted
  predicate unknown. What is found is sorted as Module:Name/Arity: the
  store's, the system's as `%   Foreign: system:N/A` -- a C row, or a
  library's clauses where swipl's is C (`coco_listing_sysdef` over
  lib/swipl-det.cicili's `*swipl-foreign*`) -- and a program's own clauses
  for a system name beside it under swipl's `%   NOTE: system definition
  has been overruled for`. A predicate's module is written unless it is
  the listing's -- `lsm:mp(1).`, and `user:yy(a, b).` where the listing is
  lsm's -- and none under a variable context, the system's `%   Foreign:`
  line's too; a module/2 read's declaration names the module (`coco_decl_pi`
  notes `pmod` where a first clause would). **The declarations are
  swipl's, in its order** (`coco_listing_pred`): thread_local, dynamic,
  volatile, multifile, public, since 3.48.2 meta_predicate -- its spec
  predicate_property/2's (`coco_meta_spec_term`), the module before it
  where the listing is not the predicate's (`:- meta_predicate
  lmq:lmq_p(0).`) -- then module_transparent, which a spec that names a
  module hides (swipl's meta_implies_transparent/1), and a blank line
  after them; never discontiguous. test/files/listing_spec.pl holds
  478 lines to swipl, test/files/listing_meta.pl 176 of the declarations,
  test/repl.pl listing/0's blank line and tty_size/2,
  test/reconsult.pl's `listed` the second process.
* **A global is found by a hash of its name (1.9.4), copied AS ITS BLOCK,
  and a GROUND one's copy handed out shared while it lives (1.12.1)**
  (`nb_getval/2`, `b_getval/2`, `nb_current/2`; `coco_b_global_term`).
  The store put a value's cells together from its root, every reference
  among them, so a read is a memcpy and each REF moved by the distance
  (`coco_store_read_block`): 3 000 entries 26 us, 98 through 1.12.0's walk
  a cell at a time, and the translator's reads went from 12 % of its
  instructions to 4 % (-7.9 % in all, its case -3.2 % of user time). A
  ground copy is then kept by the machine (`gcache`, by the global's index
  and version `gver`, for the store whose serial it names, a root of the
  collector) and a repeated read is 0.2 us at any size -- as SWI's:
  setarg/3 and nb_setarg/3 on it change the global (SWI's counter idiom
  works) until nb_setval/2 sets it again; a value with a variable is a
  fresh copy each read, where SWI shares it. **The copy is kept FOR AS
  LONG AS IT LIVES**: its sentinel on the trail is undone when
  backtracking or the end of a nested search goes back past it and takes
  its cells, and a read that does not find it where it was put copies
  again (`coco_gcache_ok`; the collector moves it with the trail and tells
  the copy); the hosts' registered positions are raised over it at the
  fill; nb_setarg/3
  into it pins it (`coco_gcache_pin`: every mark raised, as SWI's
  freezeGlobal()). So **a new wind-back of the heap across Prolog
  execution undoes the trail to its mark or registers its position**, or
  a stale copy is read. Raising every mark at each fill instead kept what
  backtracking had always given back: the translator's case 12 % slower,
  16 collections become 34. Only 5 % of the translator's reads find their
  copy alive -- it backtracks past nearly every one -- so its gain is the
  block. A memberchk/2 of 300 entries already on the heap is 4.7 us: the
  translator's table of a common word (`è`, `di`) holds 300 entries.
* **b_setval/2 is swipl's backtrackable global** (3.52.0, `coco_b_bsetval`
  in lib/builtins-db.cicili; test/files/global_vars.pl; through 3.51.0 it
  was nb_setval/2 under another name). The machine's `gvb` table holds an
  entry per key it ever named (never removed), each naming the key's BOX,
  `'$gv'(Serial, Value)` on the heap, its value cell written as setarg/3
  writes it (a trail pair) and made a reference to itself, the dead mark:
  **a box is live while its header, its serial and a value cell that is
  no dead mark stand where it was put, inside the heap** (`coco-gvb-live`),
  so backtracking past its making kills it whether the heap goes back or
  a freeze kept it -- and a collection that dropped its making's trail
  entry, as a cell newer than its barrier's is, left it past the heap.
  The value is the term itself, linked: a later binding of it is seen, and
  setarg/3 on it writes the global. nb_getval/2, b_getval/2 and
  nb_current/2 read a live box before the store's global; nb_setval/2
  detaches it (`box` -1); the collector marks every live box and moves
  it. **A load's goal ends what it did** (`lb_goal_hook`, swipl's
  failure-driven load): a directive's and an initialization goal's
  success undoes its trail (`\+ \+ G`) **but the sentinels of the ground
  globals' copies it read** (`coco_undo_older`'s KEEP: the consult's mark
  was raised over each at the fill; undone with the rest, every directive
  read the global again, a load of 500 such 2.1 times the instructions),
  a box made since it began is dead (its serial past the goal's clock,
  `gvb_clock`: what a collection dropped no undo puts back), and an expansion
  hook keeps its output and its bindings of the term in hand while what
  it did to a cell under the term's floor is undone as it returns
  (`coco_undo_older`; `lfloor`, the consult's mark for the term, set as
  each term begins and put back around a nested read) -- the first cut
  left a directive's write into a box made before the load pointing at
  heap the consult gave back. **A new goal a load runs goes through
  `lb_goal_hook`, or its b_setval/2s outlive it.** A machine of its own
  has its own table (a thread, a green task, run_isolated/2); a frozen
  machine keeps none.
* **The six term walks borrow the machine's stacks** (copy, store-put,
  store-get, store-unify, unify, compare: `coco_wframes_take`/`_give`,
  `coco_wpairs_take`/`_give` in `lib/term-walk.cicili`), and the three that
  rename variables borrow its variable map too (`coco_varmap_take`/`_give`:
  an open-addressed table, epoch-stamped so nothing is cleared between
  copies; its hash must spread CONSECUTIVE keys -- a multiply alone put a
  whole clause's variables in one slot). They are iterative so a
  200 000-element list cannot overflow the C stack, and when each walk
  allocated its stack per call, queens took 61% longer (1.8.38's bisection,
  STATUS.md). A walk must not `malloc` per call; anything new on that path
  is measured with `sh bench/langs.sh` or a same-sitting pair.
* **`coco_make` dereferences every argument it stores**, which is what keeps
  the continuation from becoming a REF chain and the engine from going
  quadratic; `test/engine.pl` guards it with a hundred-fold-margin timeout.
* **The store compacts itself** at safe points (four million dead cells
  outnumbering the live, or doubling growth); `garbage_collect/0` forces
  one; a caller holding cell indices registers them
  (`coco_store_root_push`).
* **The heap is collected since 1.8.36** (`coco_heap_gc`, a sliding
  mark-compact that keeps cell order, so heap marks stay true): at a step
  boundary, under a host that set `e->gc` -- `-s`, `run`, `query`, the
  REPL, `step`, `run_isolated/2`. A host holding cell indices across a
  step registers them with `coco_heap_root_push` (the REPL's variable
  table) or leaves `gc` off. **Since 1.9.4 the engines a builtin starts
  collect too** -- `findall/3` and so `forall/2` and `aggregate_all/3`,
  `call_metered/4`, `with_output_to/2`: the starter registers what its own
  frame holds (the caller's goal cell comes in as `gp`), the engines part
  way through a step are on the machine's chain (`m->eng`, `e->outer`),
  and the marks the starter winds the machine back to (`ptrail`, `pheap`)
  are a barrier the trail is compacted against and are moved with the
  cells. A starter that does none of this leaves its engine's `gc` off;
  trace no longer does (1.9.6: the tracer's roots -- `trace_goal`,
  `tchoices`, the `'$trace_exit'` indices -- are moved for every engine on
  the chain). **A goal a load runs collects only when its caller vouched**
  (`dgc` on the machine, 1.9.6), set around ONE call by `cocolog
  run`/`consult`, by the run's top around the modules' load, and by
  `use_module/1,2` as a goal (`lb_use`, which is how `-s` loads its file);
  each frame on the way reads it, clears it, and sets it back only around
  a call whose cells it registered (`coco_heap_root_push`, and
  `coco_heap_pos_push` for a position such as a load's `mark`/`back`). A
  directive's `use_module` runs its load at the directive (3.6.0) and
  hands it the vouch, having written its spec's text first and registered
  a list's cursor; a new caller of a load vouches nothing until it
  registers what it reads after. A
  search a builtin starts, and a vouched goal of a load, collects only
  once it has grown by the floor itself (`coco_gc_nested_begin`).
  1.9.3 needed 1.25 GB for three million turns of a loop inside
  `findall/3` that now runs in 44 MB, and the linter peaks at 53 MB
  against 73, for 0.86 % more instructions (four collections). A
  collection is due when `heap_len` reaches `gc_next`;
  `garbage_collect/0` asks for one by setting `gc_next` to 0, and the end
  of a search keeps a 0 nothing inside it could serve.
  `COCOLOG_GC_CELLS=N` sets the floor (2000 tortures it, and children
  inherit it), `COCOLOG_KMAT=1|2` puts every collection through a freeze's
  materialisation first, `statistics(heap_collections, N)` counts them,
  and a `_G` name is a heap position, so it changes across a collection.
  **The float and string tables are reclaimed in place since 1.9.6**
  (`coco_tables_reclaim`, after the slide; NOT STATIC: inlined into the
  collector it cost nrev 0.12 %): an entry no heap cell, no store of an
  engine on the chain and no compiled program names is dead, a string's
  bytes are freed, the dead tail is cut off and the rest become free lists
  taken lowest index first. A live entry never moves, so no cell is
  rewritten. It waits for `tlimit` entries made (65 536 at first) AND half
  the heap's length, and `coco_table_made` asks for a collection on that
  rule; a new holder of float or string cells outside those three is a
  root it must be taught. The atom table is never reclaimed.
* **The atom, functor and predicate tables are hashed** (open addressing, an
  entry its id plus one, kept under half full -- checked BEFORE the probe, so
  a failed rehash still leaves an empty slot). **A name's hash is spread
  before its mask** (3.30.0, `coco_hash`: djb2 times the FNV prime, the
  high bits folded down, as `coco_name_arity_hash` spreads its word): djb2
  alone kept short names apart in its high bits only, so the one-character
  atoms past ASCII fell into runs of neighbouring slots that the linear
  probe walked at each new one -- 131 072 of them by char_code/2 took 18 s
  where they take 0.05, and char_type/2's walk did not end in ten
  minutes (test/engine.pl's `atom_table`). Ids stay in order of first
  use, which a frozen machine relies on; `coco_name_arity_hash` serves the
  functors (`lib/term.cicili`) and the predicates (`lib/kb-pred.cicili`). Each
  table has exactly one writer (`coco_functor_id`, `coco_pred_make`); keep
  it that way. The functor also remembers which module owns a goal of its
  name (`dmod`/`dgen`, since 1.8.42): the `strcmp` walk over the modules
  runs once per functor per registry generation, and `coco_module_register`
  raises `coco_extern_generation` so a name nobody owned is asked again.
  **That is true only of a dispatcher whose claim is the name and arity**: a
  hand-written one that turns a goal down by its arguments or its state
  (torch: `tensor_execution/3`, every `tensor_*` under another backend)
  calls `coco_m_decline` first, a walk with a decline in it keeps nothing
  on the functor, and an owner that declines sends the call through the
  whole walk (1.8.45; MODULES.md). A module that declines without saying so
  leaves the functor with the knowledge base after a first declined call.
  **Since 1.8.55 the functor is also stamped as a plain predicate**
  (`fgen`): set only on the step's slow path, when no construct, no builtin
  and no module claims the name (a construct's name never: it can turn a
  goal down by its shape), and honoured while it carries the registry's
  generation and the store's `pst`/`pserial`, not under trace. A stamped
  goal skips every question and goes to `pidx`. **A new way for something to
  claim a name must make the stamp stale**, as `coco_module_register` does
  by raising the generation; `test/module.cicili` registers a module after
  its name was a plain predicate and goes red if the stamp outlives it.
* **The first goal of an entered clause travels in the engine, not in a
  frame** (`ngoal`/`nbar`/`nset`, since 1.8.55): `coco_try_clause` hands it
  over and the next step takes it, and only the body's other goals are
  `'$k'` frames. Before anything reads the continuation as a term -- a
  collection, a stop at the inference limit, a halt -- the loop pushes it
  back as a frame (`coco_k_flush`). **A new return from the loop, or a
  builtin that inspects `e->goals`, flushes first**; every caller of
  `coco_try_clause` today is a step about to end. **A builder of the
  continuation that finds no room writes nothing**, answers 0 and sets
  `halted` to 2 (`coco_k_room`: `coco_k_push`, `coco_k_push_roots`,
  `coco_areg_term`), which stops the run at the next step's top and
  `coco_engine_next` answers as `out of memory` (1.9.4); a new builder
  does the same. (A growth given less than it asked stops it with the same
  2 and no `oom`, and that one is raised: resource_error(memory), 1.10.28,
  below.) `test/state.cicili` stops
  a proof at each of its first sixty steps and resumes it in another
  machine, `test/gc.pl` collects every 2000 cells under naive reverse, and
  each goes red without its flush. **Since 1.9.1 that goal may never be
  built at all**: a first goal (after the guards) that calls a plain
  predicate writes its arguments into the engine's registers (`areg`, two
  banks of eight, `nset` 2, the code's register form `rbody`), and the
  next step tries the callee's one candidate straight from them
  (`coco_try_clause` given the bank); a choice to keep, no clauses, a call
  another argument would key better, or a flush builds the term first
  (`coco_areg_term`). The stamp is asked when the registers are written
  (`coco_regs_ok`) and not again: nothing that could change its answer
  runs in between. A callee with two clauses or more whose first argument
  is a variable keeps the term form (`cc_regs_worth`), its every call
  leaving a choice.
* **A body's leading arithmetic and type tests run as its clause is
  entered** (`gbody`, the guards, since 1.9.1): `X is E` over integers, the
  six comparisons, and `var`/`nonvar`/`atom`/`integer`/`number`/`atomic`/
  `compound` of a variable met before, up to eight, compiled into a program
  over a stack of integers (`cc_compile_guards`, `cc_guards_run`) and run
  between the head and the body (`coco_clause_run_g`). **A guard only ever
  takes the road the step would have**: whatever it cannot decide -- a
  variable not bound to an integer, a float, a zero divisor, an operator
  not in `*cc-gops*` -- stops the guards before that goal has done
  anything, and the body is built from that goal (`gstart`). Each guard
  that runs is an inference, the one that fails too, and under an
  inference limit only as many run as the limit has room for
  (`coco_guard_budget`), so `statistics(inferences)` and every stop are
  what they were; under trace none runs. The arithmetic is `coco_arith`'s
  own C, and a result is compared or bound as the cell `coco_new_int`
  makes. `test/engine.pl` holds every operator and test to the step's
  answer, errors included; a recursion that must make garbage for the
  collector now has to build something (`test/gc.pl`).
* **A clause is COMPILED the first time it is selected** (`coco_clause_code`
  and `coco_clause_run` in `lib/kb-compile.cicili`, since 1.8.44; `coco_clause_run_r`
  for a call or a goal in registers and `coco_clause_run_g` for a body with
  guards, each its own function so that a clause using none of it runs
  exactly the first, and the head and body programs written once as the
  macros `cc-head-program` and `cc-body-program`): a head program --
  the WAM's GET and UNIFY instructions over a frame of the clause's
  variables, a nested structure flattened through a temporary, READ or
  WRITE mode per structure -- and a body program that builds the goals top
  down through the frame and lists their roots, which go on the
  continuation as `'$k'` frames exactly as a copied body did -- N frames
  reserved in one growth check (`coco_k_push_roots`, 1.8.46). The frame
  lives for the one call (an array, not a heap object: 128 slots on the C
  stack, past that the machine's kept `cslots`), so nothing new is
  frozen and a clause asserted while its body runs cannot move the body
  under it. The code is keyed by the clause's cell in a table on the
  store, cleared when the store compacts and dropped clause by clause
  where one dies (`coco_code_drop`: retract, reconsult -- without it a
  retract-and-assert counter held a program per dead clause, 298 MB at a
  million rounds); a constant is its cell and a functor its id, so a
  compaction cannot stale it. **The predicate keeps a copy of each
  clause's program pointer** (`coco_pred.codes`, since 1.8.46), a fifth
  array parallel to `clauses`: every site that shifts, drops or renumbers
  the clause list moves it too -- asserta, retract, `coco_pred_forget_from`,
  a re-read's insert at a place (`coco_pred_insert_at`, 2.14.1), the
  compaction's second pass (which nils it: the table is about to be
  cleared) -- and a sixth array would go to the same six places. **The
  body program is a layout** (1.8.46): a goal's root word carries the
  cells the goal takes, each ARG word the offset of its slot (K) and of
  the cell it fills (N), the executor reserves the goal once and keeps no
  stack; a program ends at its length (no END word). **Each number in an
  instruction has its own field** -- a frame index or a slot offset in 24
  bits, an argument index, an arity or a cell offset in 32;
  GET_STRUCT once packed two into 16 bits each and a head structure of
  65 536 arguments read back wrong (1.8.45) -- and a clause past what a
  field holds is not compiled. A clause the compiler
  cannot take (a head that is not callable, a frame over 2^24 - 1 slots) or
  whose program cannot RUN (`coco_clause_run` answers -1: no memory) is
  matched in the store and copied as before (`coco_store_unify`,
  `coco_store_get_vm`: the store is
  never bound, a variable met first lives in the slot `coco_push_struct`
  reserved). The engine's own names and functors -- `'$k'`, `$true`,
  `$fail`, `$cut`, `:-`, the markers -- are interned once per machine
  beside the ids (`fids`, `coco-fid`); add to `*functor-names*`, never
  call `coco_make` with a literal name on a hot path. **A list cell is
  built with `coco_cons` and recognised with `coco_is_cons`** (1.9.2), by
  `'.'/2`'s functor id kept on the machine (`cons1`, learnt on first use
  so the intern order stays first-use) -- never by `strcmp` with `"."`:
  `=..` once tested the name alone, and a `'.'/1` in its list ran away to
  13 GB. A `'$k'` frame is
  four cells with the barrier an INT in its slot. **A deterministic call
  gets no choice frame** (1.8.46): the engine asks `coco_pred_probe` for
  the first candidate and whether a second exists, and with none tries the
  clause over the machine's own marks with `nchoices` as the barrier --
  what the frame's index would have been; under trace a frame is pushed
  as before, the Fail port is printed from it. **The evaluator dispatches
  by id** (`*arith-names*`, interned beside the dispatch names; a symbol
  in that list is a COCO_OP_* array, for the three names a Cicili string
  cannot end): add an evaluable functor to the table, never a `strcmp`;
  two integer leaves under `+`, `-`, `*` are combined in `coco_arith`
  without the recursive asks. **A raise inside the loop is never
  `return`ed**: `coco_raise` answers 2 when a catcher took the ball and
  the continuation is the recovery goal, so the loop goes round
  (`continue`); three sites returned the 2 through 1.8.45 and
  `catch(call(_), E, true)` ended the query with exit status 2 and no
  message (`test/errors.pl`, "an unbound or non-callable goal is
  catchable"). The proposal's lazy body was counted and not built
  (1.9.1): the translator's clause bodies average 1.9 goals and a third
  of its inferences are control constructs (`;`, `->`, `catch/3`), which
  no lazy body touches -- the constructs are what environments took on.
* **A body with a construct writes ONE environment when it is entered**
  (Stages 5 and 6, 1.9.3): an if-then-else, `\+`/`not`, `once/1`,
  `ignore/1`, a `;`, or a `,` inside one, after the body's guards and its
  first goal. It is a compound on the heap, `'$e'(Code, Parent, Barrier,
  V1 ... Vn, T1 ... Tm, S1 ... Sj, P1 ... Pk)` (`cc-env-entry`): the code
  as an integer, the continuation the body returns to, its cut barrier, a
  slot per variable a later call reads, one per later goal built at entry
  as a term (a builtin, anything not a plain predicate), a condition slot
  per if-then-else (the choice height its step writes), and a POS cell
  (tag 6) per UNIT -- what one `'$k'` frame held through 1.9.2: a goal, a
  construct, a condition, a branch, a `,`'s item, a construct's own
  `$cut`, `$true`, `$fail` (`coco_egoal`). **The continuation is still
  one cell**: a frame, the empty atom, or a POS cell naming a unit (the
  distance back to the header over bit 16, the unit under it). The loop
  tells them by tag; `coco_env_take` hands a unit's goal over and the
  same step dispatches it, or does the construct's step itself (pushing
  the else's choice, cutting to a condition's height). **Each unit taken
  is the step its frame was**, so inference counts and every stop are
  1.9.2's. The arm is `COCOLOG_ENV=0`; the engine's cases run programs
  both ways to one answer. What bites:
  - **A body without a construct makes none**: its later calls cost from
    an environment what their frames did (environments for every body:
    the linter 0.23 % further on, queens 0.96 % back). `*->` and a
    construct reached through `call/1` stay terms.
  - **A core builtin among the later goals is done where it stands**
    (Stage 7, 1.9.5; `cc_uplace` picks the kind): `is/2`, the comparisons
    and the type tests as a GUARD, Stage 4's program over the slots
    (`coco_env_guard`; no AG_ISF there -- a variable it meets first was
    made with the environment), whose term is built and handed over only
    when the program cannot decide; `=/2`, `==/2`, `\==/2` as SIDES, read
    out of the slots like a call's registers (`coco_env_sides`); any other
    with arguments as a BUILTIN, its entry-built term called by its row
    (`coco_builtin_call`), its first-met variables made in cell order
    (`cc_uslots` BYCELL, at most 64, past that a TERM). Each is still one
    step and one inference. The three run in `coco_env_place`, which is
    OUT OF LINE AND NOT STATIC: inlined into the take they cost the step
    loop its registers (lookup +0.68 % with the arm off). The arm is
    `COCOLOG_INPLACE=0`; the take answers -3 for a builtin's error nothing
    caught, and the loop ends the run as the step's call did.
  - **An `is/2` over `+`, `-`, `*`, or one of the six comparisons, whose
    operands are each a slot or an integer constant, is ONE fused word**
    (1.9.6, AG_ISX/AG_CMPX, unit kind GUARDX): `cc_ufuse`, a peephole in
    `cc_uguard`, makes it, `cc_uleaf` sets the kind, `coco_env_guardx`
    does it through `coco_env_place` (the take's default), and
    `coco_unit_term` builds it back. It decides only when both operands
    are integers; otherwise the term is handed over as a GUARD's is. Still
    one step and one inference. The arm is `COCOLOG_FUSE=0`.
  - **A unit kind lives in seven places**: `*cc-eg-kinds*`, the compiler
    (`cc_unit`, `cc_ubranch`, `cc_ulink`, `cc_uplace`), the offsets the
    take reads (`noff` ... `rvars`, set at the end of `cc_compile_env`),
    the take's switch, `coco_env_place` for the builtins in place, and
    `coco_unit_term`, which builds a unit back as the term its
    frame held -- for a freeze (`coco_engine_materialize` builds every
    position's goals, raises the choice frames' heap marks, and puts it
    all back after: a frozen machine carries no environment) and for the
    tracer (under trace no environment is made, and a unit taken under
    trace is handed over as its term, port for port). **`COCOLOG_KMAT`
    tortures the freeze** (1.9.4): every collection materialises first,
    1 putting it back as a freeze does, 2 keeping it so the run goes on as
    a thawed machine would; with `COCOLOG_GC_CELLS=2000` that is every
    2000 cells, and children inherit both. `test/gc.pl` runs `rt/2`,
    `rb/2` and the environment fixture under it; only 2 sees a wrong unit
    term (and `test/trace.pl`'s `env_late`, from inside a traced body).
  - **The collector keeps an environment whole from any position** (the
    POS rule in `coco_gc_mark`) and every retired code a live environment
    names (`coco_gc_codes`) -- and on a store another machine shares, every
    retired code (3.28.0): a green task's mark sees its own heap's
    environments alone, and through 3.27.0 its collection, or any task's
    query start (`coco_code_retired_free`), freed a code another task's
    environment was part way through (memcheck: twelve invalid reads and
    writes; test/async.pl runs it under valgrind where there is one). A clause that dies while an environment is
    part way through its body goes on running that code -- the logical
    update view -- so the code is retired, not freed (`coco_code_retire`),
    and a compaction keys kept codes again.
  - **What the take reads is settled at compile time** -- each offset the
    header plus one number, the kind a switch, a call's variable arguments
    copied slot to register in the take -- and a goal it hands over is
    dispatched in the same step: recomputed per take, every argument a
    dispatched word in `coco_env_regs` and each handed-over goal a second
    trip round the loop, lookup's loop was 3.9 % dearer than its frames;
    settled, 6.5 % cheaper.
  - **`ex` is what entering a clause takes**: 0 plain, 1 guards, 2 an
    environment, 3 both, so `coco_try_clause` asks a plain clause one
    question; and since 3.21.0 4, a body that holds `$/0`, built whole
    and closed by its frame's exit marker (no guard run, no environment),
    entered by `coco_try_clause_det`. A last goal swipl compiles in place
    is the code's `dlast` (3.21.1), hidden from a guard by a step
    (`'$det_hide'`): a field of its own, so a clause ending so enters
    by the plain path while no guard is on -- as 3.21.0's bit 8 of `ex`
    it went the det entry's way every time, about 90 instructions an
    entry, and a loop over two such clauses ran 8 % more. Guards and an environment have their own executor
    (`coco_clause_run_ge`) and their own copy of the guards' runner
    (`cc-guards-body`); guards that stop short build the body from the one
    they stopped at and make no environment, as 1.9.2 built it.
* **Two clocks: the steps, and the inferences, which are the steps less the
  `true`s and `=/2`s** (1.12.2; SWI counts neither in a compiled body).
  `e->steps` counts every goal at the loop's top, as always: the tracer, a
  window, the recorder and library(flow/debug) number calls by it, and no
  two calls share a number (one clock with those steps given back made a
  free goal share the next call's number, and dbgmatch keys a call by its
  number: its first build lost calls). `e->frees` counts the free ones where
  they run -- `coco_construct`'s `true`, `coco_bi_unify`, an environment's
  TRUE unit when its functor is `true` (a construct's `$true` stays a step)
  and a SIDES unit of form 0 -- and a new place that runs either counts it
  there too. `coco_bi_unify` is `(static) (inline)` (1.13.5): with the count
  in it clang stopped inlining it into the builtin switch, about 5
  instructions a `=/2` more. A slowdown the instructions do not explain may
  be where the code sits: 1.13.0 moved `coco_clause_run` 32 bytes into a
  64-byte line and cicili-lang's `=/2` loop ran 8 % slower on the same
  instructions (STATUS.md, 1.13.5). What a program reads is `steps - frees`: statistics/2's
  `inferences`, call_metered/4's Used, call_limited/3's and call_metered/4's
  limits, `cocolog step`'s budget and its `suspended at`. **A limit in
  inferences is `max_inf`, and the hot loop tests `max_steps` alone**: a
  limit sets `max_steps` to the inference limit itself (no more steps can be
  inferences), and past it the cold path makes ONE call out of line,
  `coco_limit_go`, which asks `coco_limit_room` (moving `max_steps` on to
  the limit plus the frees so far, never past `tcap`, a limit in steps from
  an engine outside: a window's), then `coco_step_free` (the tracer's Exit
  marker, which gives its step back and is taken before a stop), then
  `coco_rec_open`; nothing goes on, and the run stops. Three calls in the
  loop moved its registers: lookup ran eight more instructions a probe
  besides its padding (`tools/flow/zero.sh`; one call is 1.12.1's within
  0.05 %). A window's and the recorder's limits are in steps (`max_inf`
  0). **A nested engine
  narrows through `coco_limit_narrow`** (findall/3, call_metered/4 and
  call_limited/3, with_output_to/2): in inferences for an inference limit,
  in steps for a step limit, and its starter adds back its `frees` with its
  `steps`. **A GREEN QUANTUM IS NOT A BUDGET (2.9.4)**: a green task's
  engine always carries `max_steps` -- the end of its slice -- so narrowing
  read it as an outer step limit and capped EVERY nested engine at the
  quantum. httpd's `page_limit` runs a page through call_limited, and under
  green every page stopped at the first 10,000 steps with "page exceeded
  its inference limit"; `emax` is 0 when `e->greenq` is set, and the sub
  keeps its own limits (the task yields when the search returns -- a nested
  search is not preemptible either way). A frozen machine keeps both (`I frees max_inf` in
  lib/state.cicili, after the operators, so an older blob reads as none),
  and `coco_engine_ask` starts both again (the REPL's engine, asked once a
  goal, read -2 for a goal after one with three free steps when only the
  steps started again).
  Free goals do not end a limited run early: a stop at one would be a stop
  at the step after, which is counted (a nested engine's last step at
  least), so the least limit that succeeds is still the count reported.
* **A window's clock moves MAX_STEPS to every step** (1.13.3,
  `'$trace_window'/4`'s `time(F, K)`, the probe of library(flow/debug)'s
  `time(T)`): under it an engine has `tclock` set, MAX_STEPS is the step at
  which the clock reads next and RMAX the limit it stands in for, which
  `coco_clock_go` asks at each reading as `coco_limit_go` asks a limit.
  **A new reader of `max_steps` as a limit reads `rmax` under `tclock`** --
  the guards' budget did not, and the clock timed an engine that ran no
  guard (it is asked inline: as a call out of line it cost naive reverse 2
  instructions an inference) -- and **a new nested engine narrows through
  `coco_limit_narrow`**, which hands it the clock, and **takes the clock
  back where its starter's own work begins** (`coco_clock_back`: findall/3
  at each answer and at its end, call_limited/3 and with_output_to/2 at
  theirs), or the starter's copying is charged to the inner goal read last.
  The clock's own work stays out of every inference's time: it reads again
  after its array grows, and a collection moves its reading on. **A retry
  is read apart** (1.13.7): each reading turns the clause frames pushed
  since the last into `COCO_CH_CLOCKED` (from `tlow`, lowered by any
  retry), and backtracking into one reads where the retry begins
  (`coco_clock_retry`; the next reading, or the end of a findall/3 search
  or of the run, closes it as `retry(I, Ns, Name/Arity)`). **The invariants
  it stands on**: every step's reading resets `tlow` to `nchoices`, no step
  shrinks the choice stack and then pushes, and nothing frozen ever holds
  a CLOCKED frame (a clock runs only in the engines a builtin starts). **A
  new frame kind in `coco_backtrack` gets its own equality test**: folded
  into an `or` with the kinds beside it, it cost the step loop its jump
  table (queens +0.08 %).
* **The whole run's clock charges a step to what its goal is NAMED by**
  (1.15.0, `run_time(R)`, library(flow/debug)'s `flow_run_time/3`): the
  same clock from the first step, but each reading charges its time to a
  KEY -- 1 + (a functor's id << 1), 1 + (an atom's id << 1 | 1), 0 for a
  step that names no goal (a solution handed back) -- read at the step's
  top by `coco_clock_key` from what the loop is about to take (the
  registers' `afid`, `ngoal`, a `'$k'` frame's goal, an environment unit's
  `fid` or its slot's term), never by changing anything. **So a new place
  the loop takes a goal from is a new arm of `coco_clock_key`**, or its
  steps are charged to whatever the old arms read there. A retry goes from
  the key of the step it ran in (`rpk`) to its predicate by its index in
  the store (`rpp`), named once as the run ends. **A nested engine is asked
  its goal BEFORE it is narrowed** (findall/3, call_limited/3,
  with_output_to/2): the clock names the new engine's first goal in the
  narrow, and an ask leaves the limits alone; the starter's step is kept on
  the starter (`e->tkey`) and given back in `coco_clock_back`. A guard a
  clause runs as it is entered is no step the clock reads: its time is its
  clause's predicate's, and is/2 run that way has no row.
* **The tracer keeps the untraced clock, and records as well as prints**
  (1.10.12). Taking the `'$trace_exit'` marker gives its step back
  (`coco_construct`), so a traced run counts what an untraced one does, and
  a turn stopped at its budget is saved with the steps it took
  (`cmd_step`; `call_metered/4` still answers L + 1 for a ceiling of L,
  which `test/engine.pl` pins). `trace` 2 is the record mode: every port
  goes to the machine's recorder (`m->rec`, a `coco_rec`), with the clause
  a call entered, the heads the selection TRIED that did not match
  (`coco_rec_heads`, read back from the frame after the selection: the
  index's candidates walked again with the key the selection read, which
  `coco_rec_hkey` keeps before the selection binds the call -- a head the
  index passed over is not recorded since 1.11.2, when one failed call of
  a 32,046-fact table recorded 32,046), an exception raised and where
  it was caught. `'$trace_window'/4` (lib/builtins.cicili) opens a window
  IN PLACE: the limit stops the fast-forward before inference F, narrowed
  into nested engines as any limit is, and the limit's branch
  (`coco_rec_open`) switches every engine on the chain to recording
  instead of stopping -- a stop inside `findall/3`'s engine and a resume
  would run the whole findall again. The collector is off in a window (a
  goal's cell names its call); an inference is the sum of the steps out
  along the chain (`coco_rec_abs`). **Every recorder function the loop or
  `coco_backtrack` calls is `(weak)`**, which Cicili emits as a function
  the compiler never inlines: inlined, the window's opening cost nrev
  0.45 % in the loop's registers. A window sees the calls made in it: one
  that began before has no Exit marker and no shadow frame. **The recorder
  records what the printer prints, port for port** (`test/window.pl` holds
  the two together over the trace case's queries): a retry's Redo, printed
  only once the retry enters a clause, is recorded PENDING as the retry
  begins (`coco_rec_unpend` takes it back when anything else is recorded
  first, the window's end included) -- through 1.10.12 a call that had
  exited and was backtracked past with no clause left showed a Redo the
  printer never printed. `library(flow/debug)` (lesson 51) stands on all of
  it: a probe and a replay in child processes (`cocolog run FILE GOAL`),
  the events matched to the chart's boxes (`library/flow/dbgmatch.pl`)
  and drawn (`library/flow/dbgdraw.pl`). **`throw/1` has no port**: the
  printer prints nothing for it and the recorder writes a throw event
  naming the BODY it was raised in -- for a builtin that raised, the body
  its call was made in -- so where a program threw is read from where that
  body was going next (the matcher's `thrown(Box, At)`, 1.11.7); the last
  call the body made had exited, and read as the raise, it put a throw
  written after an if-then-else in the then.
* **Under trace a cut keeps its own call's frame, SPENT** (1.10.24,
  `coco_trace_cut`): the Fail port is printed from the call's frame, and
  through 1.10.22 the cut took it, so a clause that cut and then failed
  printed no Fail (and a window's call never ended, `fate="open"`). A
  frame's kind is asked in ten places -- `coco_backtrack`'s drop test,
  the `$trace_exit` marker's search, the `;` Redo's search,
  `coco_trace_reopen`, `$catch_exit`'s scan, `coco_frames_on`'s walk
  (the update view's), since 3.20.0 `$det_exit`'s scan (`coco_det_exit`),
  since 3.21.0 a guard's (`coco_det_live`) and since 3.27.0 the printer's
  region walk and its search for a `;`'s call (`coco_trace_region`,
  `coco_trace_redo_at`) -- and a new kind goes to all ten (3.28.0's DB
  frame, retract/1's and clause/2's walk, is a choice point to each, a
  clause frame's view and place, and no call's; 3.29.0's WALK frame, arg/3's
  walk and since 3.30.0 char_type/2's and code_type/2's, a choice point to
  each and no call's, and a `;`'s GOAL frame where the printer's Redo is). **A frame is a
  call's by its depth (> 0), never by its goal**:
  a goal can be heap cell 0, and `--trace run F t` printed no Fail for an
  atom goal written first. A Redo reopens only the calls it is inside
  (the nearest shallower frame, then the next), not every shallower one.
* **The printer hides what swipl's hides** (3.27.0, swipl's isDebugFrame
  and dbgRedoFrame; TRACING.md's "A library's calls", the functions under
  "what the printer hides" in lib/solve-control.cicili): a call is no port
  where its predicate hides its children and so does the call whose body
  it is in (`trace_goal`; a builtin's search, its `kcall`). Hiding is
  asked in the step's dispatch order (`coco_trace_hc`): a builtin's row, a
  compiled-in module's C (`coco_sysclaims_hook`: the tier-1 rows and
  green's, NOT the load's claims, so no take-over moves), then the store's
  `pattrs` 32 -- after the modules, because a fact a program asserts under
  a module's C name is no predicate the call reaches. A predicate's 32
  is decided by its FIRST clause in a read (`coco_assert_from`, swipl's
  assert_term): set where the machine's `nodbg` is 1 -- generate_debug_info
  false, by the directive (`coco_directive`) or the goal (`lb_set_flag`),
  saved and put back by each read (`coco_consult_oid`), and 0 at the start
  of a compiled-in module's text or a preloaded library's (lib/module.cicili)
  -- and cleared where it is 0; 64 marks a library's (its first clause a
  `noexp` read's), which each later clause decides again: one namespace for
  swipl's separate user predicate (card row N1). A hidden call's frame has
  PRINTR 2, and it has no Exit or Fail port (the `'$trace_exit'` marker,
  the builtin's sites, `coco_trace_fail`, `_nomatch`, `_spent`). **The
  step's `tport` is that PRINTR** (0 untraced, 1 shown, 2 hidden), which
  `coco_trace_call` answers, out of line and `(weak) (cold)`: a flag of its
  own beside `tport` took `tport` out of its register and cost queens'
  every call six instructions, the flag folded into `tport` with the
  question and the port as two calls in the loop four, and the one cold
  call none (`tools/flow/zero.sh`, all three under 3.26.1's); a retry
  inside one is the Redo of the outermost call of its region whose caller
  does not hide (`coco_trace_region`), printed as the retry begins, before
  the selection (`coco_trace_paint`), once that call has exited. **A new
  engine starter hands the tracer on through `coco_trace_inner`**, its
  QUERY 0 where swipl's builtin is a clause (findall/3, forall/2,
  call_limited/3: the builtin's context) and 1 where it is C running a
  query (with_output_to/2: no context), one deeper and a boundary no Redo
  crosses (`trace_bhc`); **a new system library says
  `:- set_prolog_flag(generate_debug_info, false).` at its head**, as the
  compiled-in halves, library/print_message.pl and library/async.pl do;
  **a new reader of `pattrs` masks the bits it means** (listing/1's guard
  reads 31). The recorder (2) and the quiet trace (3) keep 3.26's every
  call. test/trace.pl holds 32 queries of test/trace-library.pl to swipl,
  a second file after one that ends under false, and eight lines swipl has
  none of to cocolog's own; COMPAT.md has what is not swipl's. **The
  printer writes a goal as print/1 writes it** (3.40.0, `coco_write_print`
  in `coco_trace_port` and in the Redo's text, `coco_trace_paint`), as
  swipl's debugger writes it with portray: `'$VAR'(0)` is `A` and a quote
  swipl's `\'` escape; through 3.39.0 the engine's own quoted text. A
  window's recorded text, the journal and a backtrace keep that text
  (`coco_write_term`: no numbervars, the doubled quote): the recorder's
  text is matched, not read.
* **The journal** (1.10.15; TRACING.md, DESIGN-flow.md 9.2):
  `'$trace_window'/4` with `journal(record(F))` writes a line for each
  PORTAL call -- a module call that reaches the world -- and with
  `journal(replay(F))` answers each from its line and runs none. A portal
  is decided by module (`coco_jr_whole`: zigurat, os, process, stream,
  thread, tcp, tls, curl, ray, opencv, torch, tensorflow, numpy, aes, x509
  -- every C predicate of one but what sets the engine's own state alone,
  `coco_jr_none`, which a replay must run: library(stream)'s
  `'$stream_lastc_set'/1`, 3.56.0), by name for the modules that are not
  (`coco_jr_named`: files' twenty, getenv/setenv/unsetenv, statistics/2,
  current_prolog_flag/2, sha_file/3, the green world's size
  `'$async_workers'/1`, and format/3 unless its sink is a term), and by
  `coco_m_portal` for a module out of the tree. **A core
  builtin is never one**, nor a load (`use_module/1` reads the program's own
  clauses again in every run). What bites:
  - **The journal is the seam's, and only while a window holds one**: the
    seam's three static hooks are wrapped as the window's run starts and
    put back as it ends (`coco_jr_wrap`), so an untraced run dispatches
    exactly as before, and another thread's machine goes straight through.
  - **A replay is matched by inference, predicate AND call text**: an
    `exit(Goal)` outcome would catch another argument by not unifying, but
    a `fail` has nothing to unify -- the text is the only witness. A replay
    that passes an entry by is caught at the next module call (`portal`
    names that call, its module `unknown`: it was stopped before it ran) or
    at its end (`coco_jr_settle`, `Got` none).
  - **Read the goal BEFORE the call runs**: a caught raise unwinds the heap
    the goal's cell is on, so the text and format/3's sink are taken first.
  - **A replay opens no stream and starts no thread**: a write the replay
    makes to a stream it never opened goes nowhere (`coco_m_replay_sink`),
    and a thread's messages come from the journal.
  - **Floats are exact in it, as everywhere since 1.10.28** (the writer's
    shortest form, below): through 1.10.27 the journal alone wrote 17
    digits (`m->wexact`, gone), and `%.15g` would have made a replayed
    clock another number.
* **A float is written as SWI 9 writes it** (1.10.28, `coco_sb_put_double`
  in lib/term.cicili): the fewest significant digits that read back as the
  same double -- `%.14e`, then 16 and 17, and at 16 the neighbour towards
  the value when the nearest misses (a power of two's lower gap is half its
  upper: 2.0 ** -549 is ...053, SWI's, where the nearest 16 digits are a
  different double; `coco_float_nudge`, whose digits move the other way
  for a negative value -- its first build wrote -2.0 ** -549 in 17) -- set
  out by SWI's rule: `0.000ddd`
  down to a point three places before the digits, `d.ddde-N` past it,
  `ddd.0` up to 15 places, `d.ddde+N` beyond (`1.0e+22`, `1.0e-5`,
  `100000000000000.0`), an infinity `1.0Inf`/`-1.0Inf`, a NaN `1.5NaN`.
  The reader takes `1.0Inf` and `1.5NaN` back (after a fraction and no
  exponent, as SWI: `1.0NaN` is its syntax error), and `-0.0` keeps its
  sign, in the reader and in `-/1` (both did `0 - x`). 21,000 doubles of a
  run are written by swipl to the letter and read back bit for bit
  (`test/files/floats.pl` holds 40 to swipl's text). Not SWI's yet:
  term_to_atom/2 reads the first term of its text and ignores the rest
  (`'1.0 x'` is `1.0`; `inf` and `nan` are evaluable since 2.2.2). A
  frozen machine still writes `%.17g` (lib/state.cicili). **A prefix
  operator takes a space before a digit only when it is `-`** (2.2.3,
  swipl's: `- 1`, because `-1` is the integer, but `+1`, `\1`, `\+1` and
  `?-1`, which read back as the operator applied to 1; through 2.2.2 every
  symbolic one took it, `+ 1`); a symbol character after any of them takes
  one by the merge rule (`- -1`, `+ +1`), and so does an opening
  parenthesis (`- (a+b)`). `test/files/prefix_write.pl` holds 60 terms to
  swipl's text, and `test/syntax.cicili` the golden cases. **print/1, and
  format's `~p` with it (so library(stream)'s print/2), are swipl's print/1**
  (2.2.4; write/1 and `~w` through 2.2.3), **and write/1 and writeq/1
  swipl's too** (2.2.5): numbervars in write/1, writeln/1, writeq/1,
  print/1, `~w`, `~q`, `~p` (and so library(stream)'s write/2, writeq/2,
  print/2) and write_term/2's `numbervars(true)` (mode 8), which writes
  `'$VAR'(N)` as the variable it names -- an integer of 0 or more the
  letter N mod 26 and past 25 N // 26 after it (`A`, `Z`, `A1`), a negative
  one `S_` and its magnitude (`S_-9223372036854775808` for the least
  integer, swipl's text, its own negation wrapping), an atom that reads as
  a variable (A-Z or `_` first, ASCII) unquoted, anything else the compound
  it is (`coco_write_numbervar`); write_canonical/1 has none, as swipl's.
  **A quoted write a program asks for takes swipl's character escapes**
  (mode 16, 2.2.5: writeq/1 25, print/1 and `~p` 25, write_canonical/1 17,
  `~q` 25, write_term/2's `quoted(true)` 17; `coco_write_mode`): a quote
  inside an atom is `\'` (`'don\'t'`), and a control character with a
  letter the reader knows is the letter, `\a` `\b` `\v` `\f` and, in a
  string as in an atom, `\r` (`coco_escape_letter`); through 2.2.4
  `'don''t'` and the four as they were. **The engine's own quoted writes
  keep the doubled quote** -- the store, a channel, the journal, a message,
  the REPL's answer, term_to_atom/2 (swipl's doubles there too) -- all
  through `coco_write_term`, `coco_write_storable` and
  `coco_write_canonical`, which set no 16: a new writer a PROGRAM calls
  goes through `coco_write_mode` with the 16, one the engine reads back
  does not. Not swipl's yet: the REPL writes `'don''t'` and `'$VAR'(1)`
  (swipl's `'don\'t'`, `B`), where listing/1 writes swipl's since its
  layout became portray_clause/1's; and a quoted infix operator after
  an integer takes no space (`1'x\'y'2`, swipl's `1 'x\'y' 2`), which
  after a 0 reads back as a character code. `test/files/print.pl` holds 85
  lines to swipl's text, and `test/files/write.pl` 79.
  **Two floats are one term when their BITS are** (2.1.1, `coco_flt_eq`):
  `0.0 = -0.0` fails, a NaN unifies with itself, `-0.0 @< 0.0`, and a NaN
  sorts before every other number (`coco_flt_order`, which
  `coco_num_order` asks of two floats that do not order as numbers) --
  swipl 9.0.4's answers, `test/files/float_order.pl`. Through 2.1.0 unify,
  the store's matcher and a compiled head compared the doubles, and a NaN,
  equal to every number in the order, left a sort out of order. **A new
  identity test of FLT cells calls `coco_flt_eq`**, never `==` on the
  doubles. Arithmetic compares numbers (`0.0 =:= -0.0`), and **a NaN is
  unordered** (2.1.2, swipl 9.0.4's, `test/files/float_arith.pl`):
  `coco_num_cmp` answers 2 against anything, so `=\=` holds and the other
  five fail, `X =:= X` among them (through 2.1.1 a NaN was equal to every
  number). **`max` and `min` are SWI's `ar_max`/`ar_min`**
  (`coco_num_pick`, which answers which of the two): a NaN passed over,
  -0.0 the smaller zero, of an integer and a float that are equal the
  float, and the one picked as it came, so `max(2, 1.5)` is `2` (it was
  `2.0`); is/2, max_list/2, min_list/2 and aggregate_all/3 each ask it in
  the order of SWI's own clause (`max(H, Max0)` along a list,
  `max(M0, X)` in an aggregate: the order picks which of two NaNs). **A
  new reader of max or min calls `coco_num_pick`, and a new caller of
  `coco_num_cmp` reads its 2.** aggregate_all/3's sum adds integers as
  integers until a float arrives, int_overflow past 64 bits, as sum_list/2
  does (through 2.1.1 in doubles: 2^53 + 1 summed to 2^53, and two halves
  of 2^63 to the least integer), and `sign/1` of a NaN is SWI's one NaN.
  **The folds evaluate what they fold** (2.15.1, `test/files/folds.pl`):
  sum_list/2, max_list/2, min_list/2 and aggregate_all/3's sum, max and
  min are SWI's `is/2` clauses -- a plain number in the C loop as before,
  and from the first element or solution that is none (an expression, a
  rational) each step `is/2`'s own `+`, `max` or `min` over the two
  (`coco_l_eval2`), so an atom raises `type_error(evaluable, a/0)`; the
  first element of a list is taken as it is (`max_list([a], M)` is `a`),
  an aggregate's first solution is evaluated (`max(X, X)`), and the
  witness forms ask number/1 of the first and `>`/`<` of the rest. Through
  2.15.0 each raised for anything but a plain number.
  The guards never meet any of it: they take integers alone.
  **A float a function makes is a number, or what swipl's four float
  flags let it be** (2.2.0; the flags since 2.2.2): `float_overflow`
  (`error` or `infinity`), `float_zero_div` (`error` or `infinity`),
  `float_undefined` (`error` or `nan`) and `float_underflow` (`ignore` or
  `error`), set by set_prolog_flag/2 as a goal or a directive and read by
  current_prolog_flag/2 beside swipl's read-only `float_min`, `float_max`
  and `float_max_integer`. They are four bits on the machine (`fflags`, 0
  for swipl's defaults), the process's default for a machine made after
  them (`coco_fflags_default`, as `text_units` keeps its), and kept by a
  frozen machine (section `N`, after `B`; `F` is the functors'). At the
  defaults a NaN raises `evaluation_error(undefined)` (`0.0 / 0.0`,
  `sqrt(-1.0)`), an infinity `float_overflow` (`10.0 ** 400`, `log(0.0)`),
  a number other than zero over a zero `zero_divisor`; a subnormal is a
  number. `coco_float_verdict` is swipl's check_float() under the flags,
  and makes a NaN SWI's one NaN (0x7FF8000000000000, what `1.5NaN` reads
  as) whatever its bits, so two the flags let stand are `==`;
  `coco_float_ok` raises through the engine and `coco_l_float_ok` through
  the module seam. `coco_zero_div` is check_zero_div(): a zero over a zero
  is the NaN under `float_undefined`, anything else over one the infinity
  of the two signs' product under `float_zero_div` (`1 / -0.0` and
  `-0.0 ** -1` are -1.0Inf, `-0.0 ** -2` and `-0.0 ** -1.0` 1.0Inf: an odd
  INTEGER exponent alone keeps the zero's sign). The check is asked of
  every float `+`, `-` and `*` make (the macro answers 5 for each), of `/`,
  `**` and `^`, of sqrt/1, the transcendentals, exp/1, log/1 and float/1
  (`coco_float_fn`), and first of each float OPERAND those but `+`, `-` and
  `*` take, as swipl's promotion does -- so `1.0Inf ** -1` and
  `sin(1.0Inf)` are float_overflow where libm answers 0.0 and a NaN, a
  subnormal operand of `/` or `sqrt/1` raises under `float_underflow`
  `error` where `2.0e-310 + 1.0` is `1.0`, and a product that underflows
  all the way to `0.0` stands; sum_list/2 and aggregate_all/3's
  sum ask it of each float sum, and max and min of two equal floats ask it
  of the first (`coco_num_pick` answers 2; swipl makes the two one type
  and checks the float it makes), aggregate_all/3's first `max(X, X)`
  among them. Unchecked, as in swipl: a float literal and the constants
  (`pi`, `e`, and since 2.2.2 `inf`, `nan` and `epsilon`), the sign,
  `abs`, `+` and the comparisons; `-`, which keeps a NaN's bits as the
  reader does (`-(nan) == nan`, `-1.5NaN == 1.5NaN`, 2.2.2); integer/1,
  truncate/1, round/1, floor/1 and ceiling/1, which hand a NaN or an
  infinity back as it came (`coco_float_back`; undefined through 2.1.2);
  and `/` over an infinity, the integer 0 for an integer and a signed zero
  for a float. A power is swipl's ar_pow(): `X ** 0` is the integer 1 (a
  NaN's too), `1 ** Y` 1, `0 ** Y` 0 or a zero divisor, `-1 ** N` 1 or -1.
  Through 2.1.2 each of these was the C answer, the NaN or the infinity,
  and a power with a float in it a float. `test/files/float_check.pl` (194
  lines) holds the defaults to swipl, and `test/files/float_flags.pl` (925
  lines) every flag alone and the four together; 24 arms red, and 34.
  **A new evaluable function that makes a float asks `coco_float_ok` of it,
  and of each float it takes; a new division by zero goes through
  `coco_zero_div`.**
* **An expression is evaluated as swipl's valueExpression() evaluates it**
  (3.61.0, `coco_arith_top`, `coco_arith`, `coco_arith_past` and
  `coco_arith_far` in lib/solve-arith.cicili; test/files/arith_depth.pl): a
  compound's arguments from its LAST -- `X is a + b` names b/0,
  `foo(1, 2, a)` a/0 before foo/3, and the comparisons still their left side
  first -- f() its own culprit, type_error(evaluable, f()), and an
  expression of any depth. **Every evaluation begins at `coco_arith_top`**,
  which sets the count to 100 and the root (`abud`, `aroot`, appended to the
  machine): a new caller of the evaluator calls it, never `coco_arith`, or
  it takes on the last evaluation's count and asks the wrong term.
  `coco_arith` counts each compound it enters -- a list of one character
  and f() none the count takes, roundtoward/2 one before its mode is read --
  and where the count runs out hands the compound to `coco_arith_past`
  (weak, cold), **ONE tail call on the cold branch**: a test of the far
  walk in place there made clang keep a flag across the two count sites,
  some four instructions an evaluation. The first time is the expression's
  101st compound: the WHOLE expression is asked once whether it is cyclic,
  type_error(expression, E) when it is, and the C stack where it stands is
  kept (`astk`). After that a compound entered 16 KB of C stack below it
  is `coco_arith_far`'s, evaluated on two stacks of its own, the pending
  compounds and the values made (the first 32 of each on the C stack, the
  rest malloc'd and, as swipl's segstacks, no part of stack_limit); any
  other is `coco_arith`'s again with the 63 after it, so a wide expression
  is evaluated by calls, a million compounds no deeper than twenty among
  them, and a deep one leaves the C stack. **Where the stack stands is read
  from the cells an evaluation is handed for its answer** (ISF, in its
  caller's frame): a function that evaluates an argument into the cells it
  was handed itself says the stack stood still, and a chain of it never
  leaves the C stack -- `coco_roundtoward` makes its value in cells of its
  own for that. **A function's application is written once and emitted
  twice** (`coco-arith-unary-body`, `coco-arith-binary-apply`,
  `coco-arith-powm-apply`): `coco_arith` and `coco_arith_far`'s
  `coco_arith_apply` expand the same macro, so a new function goes into the
  macro and both evaluate it. A raise past the hundredth puts each pending
  roundtoward/2's rounding mode back, the innermost first. **The cycle
  question is two walks**: `coco_arith_acyclic` walks the expression as the
  tree it nearly always is, counting 4 096 compounds, a chain keeping and
  marking nothing (77 instructions a compound); past its count
  `coco_arith_marked` meets each compound once, its state in the top two
  bits of its own header while the walk lasts -- on the path, or done -- and
  every mark put back before it answers (131 a compound, where
  `coco_acyclic`'s map is 240), so a DAG costs its compounds and a cycle
  the compounds before it. Counted against the heap's length, the tree
  walk's first cut, `X = 1 + X` cost as many steps as the heap had cells.
  **The question is the release's cost, and swipl's**: an expression of
  more than a hundred compounds pays the walk of the whole of it, a chain
  of 400 levels 357 instructions a level where it was 258
  (STATUS.md).
* **`>>` and `<<` take any count** (1.14.0, `coco_shift_right` and
  `coco_shift_left` in lib/term.cicili, which both evaluators call --
  `coco_arith` and the guards' runner, written once in kb.cicili and
  emitted three times). A C shift by 64 or more, or by a NEGATIVE count, is
  undefined (C11 6.5.7/3), and x86-64 and aarch64 both take the count
  modulo 64, so the answer was wrong with no error: `1 >> 64` was 1,
  `1 << 1000000` was 1, `-256 >> 66` was -64, and `1 >> -1` was
  `1 >> 63` (cicilang's report, found where a 128-bit significand written
  as its two halves did not move; its own constant folder had the same
  fault). Now SWI's answers, as far as 64 bits carry them: a count past 63
  gives `>>` the sign of its left side (0 or -1), a negative count shifts
  the other way (`1 >> -1` is 2, `4 << -1` is 2), its magnitude tested
  before the negation that the smallest integer would overflow, and a `<<`
  that would lose a bit raises evaluation_error(int_overflow) since 2.0.0
  (`1 << 63`, `3 << 62`; `-1 << 63` is the least integer; through 1.15 a
  61-bit cell wrapped it, and `1 << 64` was 0). The left shift goes through
  u64, because a left shift of a negative value is undefined as well
  (6.5.7/4), and the helpers say a lost bit through their `ovf`. `test/engine.pl`'s `shifts` section holds
  all three paths -- the step, a guard, a goal in place -- to the answers,
  and is red on 1.13.7 for 20 of its 34 rows in each. **A new evaluator of
  a shift calls the two helpers**; neither `(>> a b)` nor `(<< a b)` on
  values a program gave is sound.
* **Integers are 64 bits** (2.0.0; 61 through 1.15, past which arithmetic
  wrapped in silence). An INT cell holds a 60-bit payload (tag 2, four tag
  bits since 2.5.0, `coco-fits-cell`), -2^59 .. 2^59-1; a value past it is
  BOXED, a BIG cell (tag 7) whose payload indexes `m->bigs`, i64
  (`coco_big_entry`). `coco_new_int` boxes only past the 60
  and `coco_int_val` reads either kind: **canonical by range**, so an INT
  never equals a BIG and two INT cells still compare by word, while two
  BIGs compare by value, as floats do. **A new reader of an integer asks
  `coco-is-int` and `coco_int_val`, never the INT tag alone, and a new
  builder calls `coco_new_int`.** Past 64 bits arithmetic raises
  `evaluation_error(int_overflow)` (`coco_int_overflow`), where SWI makes a
  bignum: `+`, `-` and `*` through `coco_add_ovf`, `_sub_` and `_mul_`
  (`(static) (inline)` over `__builtin_*_overflow`, an add or an imul and a
  `jo`; a 128-bit test made an add nine instructions), `**` and `^`
  (`coco_ipow`), the least integer `//` or `div` -1 and its `-` and `abs`,
  a `<<` that loses a bit, succ/2, plus/3, sum_list/2, numlist/3; a float
  made an integer outside them raises it too (a NaN or an infinity is
  handed back, as swipl's is, since 2.2.0). The reader counts a literal in u64
  (`coco_mag_digit`, `iwide`): past 2^63-1, or 2^63 for a negative one, is
  `integer out of range`; atom_number/2 fails for such a numeral, and
  number_codes/2 and number_chars/2 raise `syntax_error(illegal_number)`
  (`coco_read_number_text`, below). **The guards stop where they cannot decide** -- a result
  past 64 bits, the least integer // -1, its negation, a shift that loses
  a bit, a BIG operand -- and AG_ISF/AG_ISV hand a result past the cell's
  60 bits to the step, which boxes it; GUARDX (`coco_env_guardx`) works on
  the CELLS (A+B is CA-2+CB, A-B CA-CB+2, A*B (CA-2)*B+2), where a 64-bit
  overflow is exactly a result past the 60. The index keys a BIG or a RAT
  as 0, as FLT and STR (`coco_arg_key`, `coco_cell_key`,
  `coco_store_arg_key`); the tables reclaim `bigs` with the floats and
  strings (`bb`, `bfree`); a frozen machine carries them in a `B` section
  after `U`, each entry in hex; two integers are ordered exactly and an
  integer and a float as doubles, the float first when they are equal
  (`coco_num_order`, swipl 9.0.4's). `bounded` is `true`,
  `max_integer`/`min_integer` ±2^63 (less one above),
  `max_tagged_integer`/`min_tagged_integer` the cell's 2^59-1 and -2^59. A
  module reads either kind with `coco_m_int` and raises with
  `coco_m_evaluation_error`. `test/engine.pl`'s `integers_64` (and the
  shifts) hold it; twelve arms red; tools/flow/zero.sh against 1.15.0:
  nrev -0.16 %, queens +0.26 %, lookup +0.38 %.
* **A rational is its own cell tag** (2.5.0). The cell layout gives four
  bits to the tag and 60 to the payload, so the ninth tag exists: RAT, 8.
  Its payload names `m->rats`, `coco_rat {i64 n, i64 d}`, reduced with
  d > 1 (`coco_new_rat`; d = 1 is an integer). `coco-rat-p` and
  `coco-rat-index` are the readers; `coco-is-int` is an INT or a BIG,
  never a RAT, and every tag switch has its RAT arm beside the BIG one
  (unify's two walks, the store's matcher, `cc_match_const`, the writer,
  the numbervar writer, the evaluator, the table mark). **The four-bit tag
  moved every payload from bit 3 to bit 4**: an INT keeps 60 bits and the
  largest inline integer is 2^59-1. A frozen machine's header is
  `cocolog 2`; a format-1 blob (the three-bit layout, through 2.4.1) is
  upgraded as it thaws (`coco_thaw_upgrade`): its tags are re-encoded,
  a BIG with bit 63 set was a rational, and an INT that no longer fits is
  boxed after the `B` and `R` sections are read, so old indices still
  name what they named. A literal `1r2` is one lexer token
  (`COCO_TK_RAT`), the writer prints `N r D` in every mode, and `1r0` is
  `illegal_number`. Order is exact (cross-products in i128); equal values
  tie float < rational < integer; a RAT never equals an integer, canonical
  form making one impossible. Arithmetic is exact -- `+ - * / rdiv`, `**`
  over an integer exponent, `rational/1`, `rationalize/1`, numerator and
  denominator, the roundings, the float parts, `abs`, `sign` -- and
  anything past 64 bits raises int_overflow; an integer-only operator names
  the rational (`coco_not_integer_rat`). The evaluator reports a rational as
  `isf` 2 with the pair in `m->arith_n`/`m->arith_d`, NOT as out-parameters:
  `coco_arith` recurses seven times for one `is`, and the old signature is
  the hot path. The table is reclaimed with the floats (`coco_tables_mark`'s
  `rb`, `rfree`) and a frozen machine carries it in an `R` section after
  `B`. **The machine's new fields are APPENDED**, never inserted: a field in
  the middle moves every offset after it, and this file's record has that
  costing a build before. (Appending changed nothing measurable on this
  occasion; it is the rule, not this measurement's cure.) The residual cost,
  five alternating pairs of user time against the released 2.4.1 binary in
  one sitting: nrev +4.7 % (1.258 s to 1.317 s), queens -0.1 % and lookup
  -1.3 %; a rational-only build before the four-bit tag refactor measured
  +4.0 % on nrev, so the refactor's own share is under one pair's noise. The
  clause runners' addresses moved with the new code before them, and a move
  of 32 bytes has cost more than this before (`lib/kb.cicili`, 1.13.0).
* **The arithmetic and text surface closed to SWI's** (2.5.0): `atan/2`,
  `atan2/2`, `sinh cosh tanh asinh acosh atanh log10 lgamma erf erfc`,
  `copysign`, `nexttoward`, `ceil`, `lcm`, `lsb`, `popcount`, `getbit`,
  `powm`, `eval`, `roundtoward` (the C rounding mode around its first
  argument, read before its arguments are), `cputime`, `random/1` and
  `random_float/0` with `set_random/1` and `random_property/1`
  (xoshiro128**, lazily seeded; the state is `'$rng_state'(A,B,C,D)` hex
  atoms, and it is not frozen), and the text predicates `atom_to_term/3`,
  `read_term_from_atom/3`, `term_string/3`, `text_to_string/2`,
  `atomics_to_string/2,3`, `atomic_concat/3` and `get_string_code/3`.
  `atom_concat/3` and `string_concat/3` are CLAUSES now, over the
  `$atom_concat`/`$string_concat` C helpers, so (-,-,+) enumerates every
  split through `'$text_split_at'/5`; each helper also decides (+,-,+) and
  (-,+,+) itself, a prefix test or a suffix test. `test/string.pl` holds the
  public modes; test/solve.cicili's bare engine loads no builtins module and
  tests the private helpers. `number_codes/2` and
  `number_chars/2` read with `coco_read_number_text`, which insists the
  whole text is the number: a trailing space, a `.` or any junk is
  `syntax_error(illegal_number)`. `test/rationals.pl` and
  `test/files/rationals.pl` hold the new surface (the second runs under
  both systems).
* **A search past the stack limit raises resource_error(stack)** (3.32.0,
  swipl's `stack_limit` flag): the bytes a machine's heap, trail and choice
  frames -- with their shadow frames, of every engine on the chain -- may
  hold (`coco_stack_used`), 1 GB by default, COCOLOG_STACK_LIMIT for the
  process's default, 0 or less none; the flag's errors are swipl's, a value
  below what the stacks hold permission_error(limit, stacks, N). Through
  3.31.0 a search that never ended grew the heap until memory was refused,
  or the kernel killed the process. **It is asked only where memory grows,
  never in the step loop** (`tools/flow/zero.sh` moves nothing), and **every
  array of the stacks grows by the room the limit leaves it** and a
  sixteenth (`coco-room-cap`, one DEFMACRO for the three): the heap and the
  trail the limit's cells (`coco_stack_cap`, from `coco_grow_slow`), the
  choice stack the frames the limit leaves beside the heap, the trail and
  the other engines' (`coco_eng_grow_slow`, `coco-room-left`) -- through a
  doubling at 65 536 frames a search leaving a choice point a level ran on
  to half again the limit before anything asked. What passes the room, and
  a collection that leaves more than the limit (the end of
  `coco_heap_collect`, SOVER), stop the running engine at its next step,
  `halted` 3 -- **a growth's stop is made only once the growth is given**,
  or a refusal would not be memory's -- and `coco_halted_step` collects
  where the engine may and SOVER does not say a collection just did, then
  asks again: past the limit it raises error(resource_error(stack), _), the
  context unbound where swipl's is a dict (COMPAT.md); under it the run goes
  on and the step is given back, so the inferences are what they were.
  After each collection the collector waits for no more heap than the limit
  leaves beside the trail and the choices (`gc_next`, `coco-room-left`), and
  from the flag's set on for no more than the limit's cells, so a heap of
  garbage is collected before the stacks pass the limit -- **and for no less
  than a sixteenth of the limit's cells**: that room shrinks with every
  collection by the share of the garbage the search keeps, and choice
  points beside a heap of garbage took 553 collections and 344 s to be
  stopped at 1 GB (277 and 112 s with the least; swipl 9.0.4 223 and 86 s).
  A search stopped at 1 GB peaks at about 1.5 GB of memory, where the
  first build's doubling took 3.2. A nested engine's collection, a green
  task's machine (`coco_machine_init_alias`) and a thread's take the limit
  as the host's do. The uncaught error and print_message/2 say swipl's
  first line, `Stack limit (1.0Gb) exceeded`, from the flag
  (`coco_error_text`, library(print_message)'s `'$pm_stack_size'/2`). **A
  new array that grows with a search takes its growth from the room the
  limit leaves**, as the three do. **A C row that builds a list of a size
  it is given asks `coco-l-too-long` first** (3.42.3, lib/lists.cicili:
  nth0/3's and nth1/3's tail, length/2's, numlist/3's): cells whose bytes
  alone pass the limit raise resource_error(stack) before one is built, as
  swipl's length/2 does -- a growth past the limit is given and stops the
  engine only at its next step, so a C loop never sees it, and
  `length(L, 10^12)` built until the kernel killed the process.
  test/files/stack_limit.pl holds the flag and the stops to swipl;
  test/errors.pl's `stack_limit_said` and
  test/solve.cicili (an engine that never collects) the rest.
* **A refused allocation raises resource_error(memory)** (1.10.28). A
  doubling refused is tried again with what is needed and a sixteenth
  (`coco_grow_short` for the machine's arrays, `coco_eng_grow` for the
  choices, `coco_store_grow` for the store's), and given, the running
  engine is stopped with `halted` 2 -- through `m->haltp`, which
  `coco_engine_next` sets beside `m->eng`, or the store's `memreq`, which
  `coco_store_put` hands over -- and the loop's top raises
  `error(resource_error(memory), _)` (`coco_halted_step`, weak, so the
  loop pays the test it always paid). There is room left to build the ball
  and unwind; nothing was written wrong, because every growth succeeded. A
  growth the ball or its throw was given less for is the same shortage,
  dropped as it is raised -- not a second raise at the recovery's first
  step.
  findall/3 asks after each result it puts: its engine's next step is
  after the search, never for one with no end. A growth refused outright
  sets `oom` and ends the run with `out of memory` as before (a builder
  that found no room may have written over cell 0). A C buffer refused
  (call/N's arguments, sort's, format's, a module's) raises it too
  (`coco_mem_error`, `coco_m_resource_error`). `test/errors.pl` runs four
  under `ulimit -v 600000`; 1.10.27 ended three with `out of memory` and
  ran the fourth for ever. **The growth is out of line and weak**
  (`coco_grow_slow`, `coco_eng_grow_slow`), the test alone inlined: with
  the fallback's call inlined into every push, clang stopped inlining
  `coco_new_var` and lookup ran 4.2 % more instructions (1.66 million in
  calls to it), and `(static)` lets clang inline it back the same way.
  Weak, against 1.10.27 (`tools/flow/zero.sh`, work less padding): nrev
  +0.63 % (all of it `coco_clause_run_r`, whose heap tests now carry a
  call), queens -2.5 %, lookup -1.6 %. **And cold since 2.11.2**
  (`(weak) (cold)`, and `coco_grow_short` `(cold)`): against 2.11.1 nrev
  -1.22 %, queens -0.30 %, lookup -0.58 %, and `coco_clause_run_r` 2.0 %
  fewer instructions on nrev -- 1.10.28's +0.63 % taken back and more.
* **A read of the knowledge base is all of a predicate or none, and one
  that failed raises** (2.11.1; STATUS.md). `coco_pred_ensure` answers 0,
  takes back what the fetch put in (`coco_pred_cut_back`), leaves `loaded`
  0 so the next call asks again, and leaves the reason on the store
  (`fetch_err`, `fetch_pi`, `fetch_oom`). `coco_fetch_error`
  (lib/solve.cicili) raises `error(resource_error(knowledge_base),
  context(Name/Arity, Why))` from it, or `resource_error(memory)`. **A new
  caller of `coco_pred_ensure` reads its 0**: it raises through
  `coco_fetch_error`, or answers -1 to a caller that does. **A new writer
  refuses before it touches the predicate**: the backend writes a predicate
  back whole, and through 2.11.0 a write over a partial read deleted the
  unread rows from the database (an outside review's finding, reproduced on
  the server).
* **The step asks `coco_pred_count` (inline, 2.11.3)**: a predicate read
  already answers its clause count there, and one not read yet calls
  `coco_pred_ready` (weak, cold), which answers the count, or 0 after a
  failed read. The step tests it where it always tested the count, and
  catches the failure on the no-clauses path, ahead of the dynamic arm.
* **A barrier, a lock or a `defer` in a function the step calls can take it
  out of line.** 2.9.0's write barrier in `coco_pred_ensure` did, and every
  call of a plain predicate paid a call of 19 instructions. That was the
  green world's whole cost to the untraced engine (nrev +2.53 %, queens
  +1.39 %, lookup +1.13 %), and it ran uncounted through eight releases,
  2.9.0 to 2.11.0 (STATUS.md, 2.11.3). Before and after a change to anything the step loop
  reaches, count `tools/flow/zero.sh`, and callgrind's calls per function.
* **A branch added to the step loop moves clang's estimate of every block
  after it.** The first cut tested `coco_pred_ensure`'s answer in the loop,
  and the zero heuristic gave the failure 3/8 of each call's path. The loop's
  calls of `coco_push_choice` and `coco_arg_key` fell under the cold call-site
  threshold (45; `-Rpass-missed=inline` on the emitted `cocolog.c` names it)
  and went out of line: queens +3.1 % of its work. Neither of these helps:
  - moving the cold code out of line (identical counts);
  - `__builtin_expect` in an inline helper (it is lowered before inlining).

  `(cold)` on the raise (Cicili 3.1.0, 2.11.2's arms) brought both back
  inline -- the first cut's queens +3.30 % against 2.11.1 became +0.70 % --
  but left nrev +2.0 % and lookup +1.4 %. Fold the test into one the loop
  already makes, and make cold what cannot be folded. Marking the loop's
  other rare callees cold is placement's lottery, not a rule: the tracer's,
  the limit's and the failed read's each moved nrev about -0.17 % and
  lookup +0.17 % alike, and the three with the growths gave the growths'
  own numbers to within 0.02 % (STATUS.md).
* **A growth goes through a second pointer** (`grown`), never
  `x = realloc(x, n)`, which loses the block on a refusal and writes on
  through null. 2.11.1 found fifteen such sites, the Zigurat fetch's among
  them, which crashed.
* **A window asks where it stopped** (1.10.16, D4): `'$trace_window'/4`'s
  `ask(Cond, Holds)` proves Cond in an engine of its own (ten million
  inferences, no collection) between the run's end and the undo, over the
  bindings the run left -- at a failure none (3.22.0: the run is undone
  first, as a run that failed past its last choice point undid nothing on
  the way); Cond's cell is a root beside the goal's
  (`hold[1]`), because a collection on the way to the window moves it.
  `flow_when/4` bisects over runs stopped at `to(I)` and asked -- each a
  child process replaying the probe's journal -- and `flow_why/2`
  (`library/flow/dbgwhy.pl`) reads a failure tree back from the calls: a
  retried clause is entered at the inference of the call whose failure
  retried it (a retry takes none), so that call is the clause BEFORE's.
* **`sort/4` (and so `keysort/2`) is a stable merge sort**; `library(process)`
  spawns with `posix_spawn` (`fork` is refused for a process whose one
  merged mapping exceeds RAM+swap) and RAISES when it cannot spawn.
* **stdout is block-buffered into a pipe**: `flush_output/0` before
  blocking, or a marker never arrives.
* **A grammar rule is translated where a file is read, as swipl's
  boot/dcg.pl translates it, and nowhere else** (3.13.0, lib/dcg.cicili;
  the consult in `coco_consult_owned` asks `coco_dcg_rule` with LIFT 1):
  `assertz((a --> b))` stores the clause of `-->'/2` it is, as swipl's
  does (through 3.12.0 `coco_assert_from` translated it), and
  dcg_translate_rule/2 is the translation with no terminal lifted. **The
  leading terminal is lifted into the stored head** (`coco_dcg_leading`),
  as SWI's `optimise_unify` does. The shapes are swipl's: `{}` binds the
  output to the input as it is translated (`a --> {}` is `a(A, A) :-
  true`); a disjunction's branch gets an output of its own, made the
  rule's after it, or `(T, S = S0)` where the branch consumed nothing
  (or_delay_bind, `coco_dcg_branch`); `M:X` qualifies X's non-terminals and
  `{G}` goals unless M is `user`; a string is its codes; a partial list is
  `'$append'(L, S, S0)` and any other improper one
  `type_error(list_or_partial_list, L)`; body syntax as a head or a
  pushback, and `-->` in a body, `permission_error(define, dcg_nonterminal,
  T)`. A rule that will not translate is reported in its ball's words and
  the load goes on (`coco_consult_dcg_refusal`). **The translator binds
  only variables it made, with no trail entry** (`coco_dcg_same`): a
  consult winds the heap back after each clause and leaves the trail
  alone, so an entry would undo a later cell -- **a new caller hands it
  fresh variables** and unifies its own with them after, as `'$dcg_goal'`
  does. **phrase/3 is call_dcg/3**: a body swipl's dcg_special/1 names is
  translated, anything else called with the two lists as call/3 calls it
  (`{}`, `*->` and `-->` among it); an unknown procedure its call meets is
  `'$dcg':call_dcg/3`'s, a row of `*frame-contexts*` in lib/solve.cicili
  (`coco_frame_ctx`, asked by `coco_owner_ctx`), and a translation's error
  has no context, as swipl's. **A qualified head keeps its qualifier**
  (`coco_dcg_extend`): `M:H --> B` is `M:H2 :- B2`, and the store peels it
  as it peels any clause's -- through 2.15.2 the qualifier took the two
  arguments, a `:'/4 nobody calls. Whether a body is qualified is a FLAG
  (`qual`), never `qm != 0`: in a fresh machine (`cocolog run`, whose
  consult reads each clause from cell 0) the module's atom IS heap cell 0,
  and 2.16.0's first cut dropped every `prolog:message//1` rule under `run`
  alone. A stored rule is compiled as any clause is (3.15.0, the bullet
  on what a clause is stored as, below): its conjunctions one. The two hooks
  print_message/2 reads, `prolog:message//1` and `prolog:error_message//1`,
  are stored as `'$prolog_message'/3` and `'$prolog_error_message'/3`
  (`coco_hook_head`), apart from a program's own message/3.
* **A report begins a line of its own, and `~N` asks where the line is**
  (2.16.0, `coco_out_note`, `coco_out_fresh` in lib/term.cicili): the
  engine keeps whether a line is open on stdout and on stderr, ONE column
  for the two as swipl's user_output and user_error share one, from what it
  writes itself -- write/1 and its kin, nl/0, tab/1, format/1,2,3,
  listing/0,1, the load's and the goal's reports, library(stream)'s writes
  to its first three slots (`coco_m_out_note`) -- and not what a module
  prints with stdio of its own; a capture (with_output_to/2) has a column
  of its own from 0 and gives the console's back. A new writer to the
  console goes through `coco_out_puts`/`coco_out_putc` or notes what it
  wrote, or the next `~N` and the next report guess -- and since 3.56.0 the
  next partial(true) write, which begins after the last character the note
  keeps, stdout's, stderr's and a capture's apart (`coco_out_lc`,
  `coco_err_lc`, `coco_cap_lc`: a capture's from none at its start, the
  outer one's put back at its end in the word the start saved). **`format` keeps
  swipl's column** (3.33.0, pl-fmt.c's format_state, `coco_fmt_cols` in
  lib/builtins-format.cicili): it begins where the sink stands
  (`coco_fmt_start`: the console's `coco_con_lp`, a capture's
  `coco_cap_lp`, a term sink 0, a file of library(stream) its own column,
  `coco_m_sink_column_install`, the "line open" hook through 3.32.0), and
  its `~N` writes a newline unless that column is 0 (after a return, or a
  stop the text passed back to 0, none). The column directives are
  swipl's: `~t` a fill point, `~N|` a stop at N, `~N+` one N past the last
  stop; the text since the first fill point is held (`pb`) and put out at
  the stop with the room shared from the middle out, and the column is the
  stop whatever the text reached. **Two rules reckon the column, as
  swipl's do**: format's own text (`~a`, `~s`, `~c`, the numbers, the
  format's characters) walks a tab to (COL + 1) | 7 (`coco_col_walk` mode
  0, `coco-fmt-now`), and a writer (`~w`, `~q`, `~p`, `~k`, `~W`) leaves
  the stream's linepos where nothing is held and the column is where the
  sink stands, else the column before it plus the linepos its text reaches
  from 0 (`coco-fmt-writer`, prepare_sub_format()) -- **a new directive
  that writes a term goes through `coco-fmt-writer`**, any other writes
  into `o` and is walked by the first rule. **The column is walked at
  its first ask** -- a fill point, a stop, `~N`, `~@` -- which walks what
  the format put out before it (`coco_fmt_catchup`, `on`), each writer
  before it having noted where its text stands (eight at most; the ninth
  asks): a format that asks none pays no walk -- so **a new directive
  that reads the column asks through `coco-fmt-now`**, and a new writer
  goes through `coco-fmt-writer`, or the first ask walks its text by the
  wrong rule.
  **`~@` and with_output_to/2 run their goal through ONE function**
  (3.34.0, `coco_out_capture_run`): fd 1 captured, a nested engine started
  as findall/3's is, and a ball handed back (`coco_fmt_ball`) for the
  caller to raise once its own work is done -- `~@` puts out the text
  before it first, as swipl's -- with_output_to/2 keeping the goal's
  bindings and `~@` undoing them. A new builtin that captures a goal's
  output goes through it. **The text a format built before it went wrong
  reaches every stream sink** (`coco_fmt_term_sink`: the console,
  user_output, user_error, a library(stream) stream), never a term.
* **The reader is written ONCE and emitted TWICE** (1.10.7): the bodies of
  `coco_parse_term`, `_primary`, `_named`, `_args` and `_list` are macros at
  the top of `lib/syntax.cicili`, emitted as the family every consult uses
  and as the `_p` family that also builds `read_term/3`'s positions; a
  position site is `(if ,P ...)`, which the compiler drops from the first.
  **A change to the parser is a change to the macro**, and a helper both
  families call is `(inline)`. One parser with a flag at each site cost
  consulting the translator 1.3 %; the two cost `coco_next_token` nothing
  and the parser within 0.13 %. **A term's operators are read on the
  reader's own stack** (3.60.0, `coco-parse-term-body`, pl-read.c's
  complex_term): an infix operator that takes the term read so far, or a
  prefix operator where an operand stands (`coco-parse-named-body` answers
  2, the operator in the reader's `px*`), suspends the frame in hand on
  `rf` (`coco_rframe`), and its operand is the next frame's; the frame
  holds its operator's functor, interned as the operator is passed (the
  token's text is the next token's after it). **THEY ARE SHIFTED AND
  REDUCED AS SWIPL'S** (3.62.0, test/files/op_reduce.pl): ONE loop, an
  operand and then the token after it. An infix operator there first
  reduces each frame whose operator's priority is no more than its left
  side takes and whose own operand fits (`oprec <= lmax` and `leftprec <=
  maxprec`, swipl's reduce_op()), then suspends the frame in hand WHATEVER
  THE PRIORITIES; a prefix operator is pushed whatever its priority. So
  no operator is refused where it stands: an operand past its operator's
  priority is that operator's clash WHERE THE TERM ENDS
  (`coco_term_misfit`, asked as the frames are read back, only where the
  token in hand ends the term, `coco_term_ends`, by the reader's `stop`),
  placed at the operator's end, which the frame it suspended keeps
  (`lopt`, `oplen`); any other token there is the read's own failure, as
  swipl's never reaches its exit (`a = b = c d` is operator_expected at
  `d`, `(a = b = c]` cannot_start_term). Through 3.61.0 an operator was
  read only where its priority fitted and the clash said at it: `a = \+ b
  = c = d` at 2 where swipl's is 9, and `a => b <= c`, an xfy and a yfx
  operator of one priority, read `a => (b <= c)` where swipl's is `(a =>
  b) <= c`. **The operators pending where a term was wanted are settled
  as swipl's exit settles them** (`coco_term_pending`, from
  `coco_parse_unwind`, out of line): its reduce pairs each operator from
  the right with the operands at the top of the out stack, a wrong
  pairing by one, so the first operator an operand is too much for is a
  clash (`eclash`: at its start for a left operand, its end for a right
  one, bad_operator()'s rule), and else the operators that find no two
  operands are left -- one, a comma or a semicolon, is punct(Op, Next),
  anything else an unbalanced operator (`a , b , c *` is punct(',', '.'),
  `a + b + c *` a clash at 9, `a = b =` unbalanced; through 3.61.0 every
  pending operator was counted). **Every way out of the loop that fails
  goes through `coco_parse_unwind`**, which takes the call's frames off
  and settles the pending. With its frames malloc'd at each reader and
  the operators' names copied, 3.60.0's first cut cost a read of a clause
  of fifteen operators some 1 700 instructions more than 3.59.0's calls,
  and every process's start 1.36 million; 3.62.0's first cut, which still
  handed every term read an `outprec` to write, cost a start 57 000 and
  88 000 of padding in `coco_parse_term`, where the loop without it is
  224 000 cheaper than 3.61.0's. **The
  first sixteen frames are in the reader** (`rfs`, last in the struct,
  which the init and the free clear up to, `coco_reader_head`): 1 408
  bytes are a large request to glibc, which consolidated its fast bins at
  each term_to_atom/2. A chain of 200 000 operators reads, where through
  3.59.0 each operand was a call of `coco_parse_term` and 15 000 prefix
  operators or 20 000 `,` were a SIGSEGV. **A bracket's term is still a
  call**, as swipl's is, and asks the C stack first: below the reader's
  floor (`sfloor`, 64 KB above the thread's, `coco_cstack_floor`) the read
  stops (`coco_read_cshort`: the reader's `cshort` and the machine's
  `rshort`), some 14 000 levels of `f(` and 18 400 of a bracket on 8 MB
  where swipl's reads 16 800 of each. **On the process's first thread the
  floor is a probe until a read goes deep** (`coco_cstack_floor_at`, 64 KB
  below the reader's start, past which `coco_read_deep` asks once): glibc
  finds that thread's stack by reading /proc/self/maps, some 180 000
  instructions, which no shallow read asks for. **Every reader
  raises resource_error(c_stack) there, never a syntax error**: the text
  builtins in their own context (`coco_tx_syntax`), library(stream)'s
  readers (`coco_m_read_clause` answers -2), a load as swipl's
  read_clause/3 ends it (`coco_consult_cstack_refused`: the clauses before
  it kept, the ball out of consult/1, `-s` and `run` saying `Prolog
  initialisation failed:` over swipl's two lines and exiting 1), the
  REPL's query as swipl's toplevel's two lines; and a caller that reads
  text back with no reader in hand asks `coco_read_short`
  (`coco_m_read_short` from a module): a green task's goal, answer and
  message (`coco_g_unread_text`), a library(thread) thread's goal and
  message. **A new reader of a text that may be deep asks `cshort` or
  `coco_read_short`**, or the short read is said to be a syntax error.
  **The main thread's C stack is RLIMIT_STACK's** on Linux (cocolog's
  main() says which thread is the first, `coco_cstack_main`; -1 with no
  limit, swipl's statistics(c_stack, L)), where pthread_getattr_np() says
  what glibc made of it, less the arguments and environment above it.
  **An argument, a list element and a curly
  term are read to 1200** (3.2.0, swipl's non-ISO reader; 999 through
  3.1.0), and what ends them is the reader's `stop`: 0 the clause's term,
  1 in an argument (a comma ends the term), 2 in a list (a comma or a
  bar), and since 3.62.0 4 inside `(` and 8 inside `{` (0 through 3.61.0:
  `coco_term_ends` asks which closing bracket ends the term), each put
  back after; the comma is an operator where `stop & 3` is 0 and the bar
  where `stop` is not 2 (`coco-term-op-token`, the one test of the token
  as an infix operator's name). **AN UNQUOTED PREFIX OPERATOR'S ATOM IS AN
  ATOM ONLY BEFORE AN INFIX OPERATOR WHOSE LEFT SIDE ADMITS MORE THAN THE
  OPERATOR'S OWN OPERAND MAY BE** (3.62.0, swipl's modify_op():
  `coco-parse-named-body` answers 3 for such an atom, its priorities and
  place in `px*`, and the loop asks `coco_term_px_atom` of the token after
  it): `- = a` and `x == - -> y` read, `=` admitting 699 where `-` takes
  200. Before any other infix operator the operator stays one and the
  infix operator's NAME is its operand -- `\+ = a` is `\+(=)` and then
  `a`, operator_expected after the `=` -- and a comma there is
  quoted_punctuation. **So `X == dynamic -> A ; B`, `K = table, G` and
  `X = - ^ Y` are syntax errors, as in swipl: write `(dynamic)`,
  `(table)`, `(-)`.** (fx 1150 is admitted by `-->` and `=>` alone, `\+`
  by `,`, `->`, `;` and above, `-` and `+` by all but `^` and `**`.)
  Where the term ends after it the atom reads: an
  argument, a list element, before a closing bracket or the full stop
  (`f(dynamic, y)`, `[dynamic|T]`, `X == dynamic`). Through 3.61.0 the
  atom read as a right operand whatever followed -- five atoms of the tree
  were bracketed for 3.62.0, in library/flow/analyse.pl, test/engine.pl
  and tools/cocolint/build.pl -- and as a left one by the priority an
  `outprec` carried out of every term read, gone (`pp vv a` read, `pp` fy
  and `vv` yfx at one priority). The atom's functor as an operator is made
  only where it is applied, from the atom's cell. Never before an infix
  bar, at any priority. **Inside a bracket the clause's end is that
  operand too, and no term**: swipl's operator is still waiting when its
  simple_term() meets the full stop, so `( ff` and `f(a = \+` are
  end_of_clause, where the atom read and the bracket then said an operator
  expected (`coco_term_px_atom` answers 3, the failure said as a term
  wanted and not there is). **A quoted name is an operator only where it
  cannot be written without its quotes** (3.15.1, swipl's; `coco_quoted_op`,
  asked by the primary's prefix test, the term loop's infix test and
  `coco_starts_term`): `'p\'q' a`, `a 'x\'y' b`, `a ',' b`, `'[]' x`; `'-' a`
  and `a '@@@' b` are no terms. Through 3.15.0 a quoted atom was never a
  prefix operator and always an infix one. **The bar is '|'/2 at 1105
  xfy**, written `a|b`, and `;` where it is a goal: a clause's body is stored with `;`
  (`coco_clause_compile` at the assert, so clause/2 hands back `;`), a call of
  '|'/2 runs as `;` (the construct, `coco_goal_leaves`), a program's own
  clause for it is kept and never called. **A walk of the control
  constructs takes the bar beside `;`**: the callable check
  (`coco_body_callable`), the consult's refusal of a body holding a number
  (`coco_consult_goals`), an unknown procedure's context
  (`coco_unknown_walk`) and a library's calls of a taken name
  (`coco_sys_goal`) each answered differently without it, the last three
  found after the first cut; `coco_meta_bar` needs none (`coco_part_bar`
  gives a structure's parts the meta-call's word).
* **A name past ASCII is read and written as swipl's** (3.35.0; through
  3.34.1 every byte past ASCII outside quotes was `illegal_character`, and
  writeq/1 quoted every atom that held one, `'é'`). **The reader asks each
  code point's class of `coco_rd_flags`** (lib/term.cicili, a two-level
  table of `*swipl-read-flags*`, the fifth table of lib/swipl-ctype.cicili,
  which tools/ctype/tables.pl writes from the REFERENCE swipl's
  '$code_class'/2 and holds to code_type/2's tables: run it again, never
  edit it): 1 layout, 2 a symbol, 4 a name's start, 8 its continuation, 16
  a capital, 32 a decimal digit, 64 a code the reader refuses, 128 one a
  quoted write escapes -- swipl's get_token(), its Latin-1 table up to
  U+00FF and pl-umap.c past it. A letter begins a name and a capital a
  variable (`Été`), a symbol joins a run of symbols (`+∀`), a space is
  layout (U+00A0, U+3000), a digit of another script begins a number in
  its block's digits (`coco_lex_wide_number`: `١٢` is 12, with groups, a
  fraction, an exponent and a rational, never `0'c`, a radix or `0x`; a
  minus before it is no sign, `-١` is -(1), the reader's `wnum`), and any
  other code a name of one character, as `!` is. ASCII keeps the lexer's
  own classes, which are swipl's table's, and **ASCII's layout is 9 to 13
  and the space** (`coco_is_space`: the vertical tab and the form feed
  too). **The raw walk asks the same** (a symbol run past ASCII, layout past
  it after a full stop, the code before `0'`), and library(stream) ends a
  clause at a full stop before layout past ASCII (`st_wide_stop`). **The
  writer asks the same classes** (`coco_wide_needs_quotes`): an atom of
  codes up to U+00FF by pl-write.c's atomType() (`é`, `¬¡`, one solo `²`),
  any other by unquoted_atomW() (`αβ`, `∀`; `/*∀` bare, where an ASCII
  `/*` is quoted, as swipl's: it does not read back in either); a space
  between two names or two symbols on code points (`coco_needs_gap`, `1 éa
  2`); in quotes `\xHEX\` for bit 128 (`coco_write_escaped`: U+00A0,
  U+00AD, U+2028, C1); `'$VAR'('Été')` bare under numbervars. **A load's
  column counts characters to the clause's start and bytes from there to
  the error's token** (swipl's stream counts its line position in
  characters, ptr_to_location() the bytes: `p(∀0'a).` is 1:5), and a
  singleton's mark is swipl's (`coco_cw_kind`): `_É` marked, `_é` warned,
  `_1` none. **Every path past ASCII is out of line and cold** (`(weak)
  (cold)`: `coco_skip_layout_wide`, reached by a tail call,
  `coco_lex_wide_token`, `coco_lex_wide_step`, `coco_raw_wide`,
  `coco_raw_wide_symbol`, `coco_needs_gap_wide`, `coco_sb_wide_end`), the
  runs are DEFMACROs specialised per class (`coco-lex-run`,
  `coco-raw-symbols`), and `coco_atom_needs_quotes` is one pass that goes
  wide at the first byte past ASCII: the first cut inlined the wide layout
  into the layout skip, which then pushed and popped six registers at every
  token (a start 846 000 instructions more), ran names through one
  function asking its class at each code (400 000 more), scanned every atom
  written twice and called the class tests for every space between tokens
  (writes 1.75 % dearer). A new path past ASCII in the reader or the writer
  goes out of line the same way. The raw walk is still 9 % dearer (+7.6
  million instructions reading 28 368 lines, 1.1 % of the read): its arms'
  order is clang's to lay out, and the two other orders tried cost 26 % and
  16 %. test/files/wide_names.pl holds 144 lines to swipl,
  test/directives.pl's `wide_names` a load's warnings and places; COMPAT.md
  has the two raw-read quirks swipl's reader has and cocolog's not.
* **Concurrency shares nothing**: a `library(thread)` thread gets its own
  machine, store, engine and database connection; a channel copies terms in
  canonical text. Mutexes and conditions serialise the WORLD (a file, a tcp
  handle, the terminal); an atom names a process-wide lock; use
  `with_mutex/2`. An httpd `workers(N)` request runs through
  `run_isolated/2` (fresh store, its own connection, one commit), so pages
  must be loaded with `use_module` -- consulted or asserted pages are a
  silent 404 in a pool.
* **`library(stream)`** owns the stream table and ISO's stream names
  (`open/3,4`, `set_output/1`, `read_term/3`, …). `format/3` and
  `with_output_to/2` reach it through a sink hook
  (`coco_m_sink_install`); `set_output/1` redirects fd 1 with dup/dup2. The
  stdout sentinel for `format/2` is `(cast size_t -1)`, not 0 (cell 0 is a
  real heap cell). cocolint's X2 trap is lifted by a
  `use_module(library(stream))`, a directive or a goal (2.2.1). **Every
  byte it reads is counted** (`st_count`/`st_uncount`: bytes, characters,
  the line, SWI's column), so `read_term/3` answers `term_position` and
  `subterm_positions` on a pipe too; a seek or a write to an update stream
  leaves the counters behind `ftell`, and `st_pos_sync` counts again from
  the start. **Every write notes its last character** (3.56.0, `st_lc1`,
  plus one, 0 at the open), in `st_wrote` and `st_wrote_wide`, which every
  put and write passes -- a byte a character in a stream of one byte a
  character -- where write_term/3's partial(true) begins: its write runs in
  a capture, so `'$stream_lastc'/2` reads the stream's before the capture
  begins (user_output's then still the console's) and
  `'$stream_lastc_set'/1` sets the capture's inside it -- no portal of the
  journal, which a replay runs (`coco_jr_none`). **Its errors are swipl's**
  (3.16.0, test/files/stream_errors.pl):
  a C half shared by several predicates takes the caller's indicator as its
  last argument and names it (`:PI` rows of `*error-contexts*`,
  `coco_ectx_named`), so `get_char/2` raises with
  `context(system:get_char/2, _)` -- a new C half of the module gets its
  row, or its errors name `stream:'$stream_...'`. A put checks its
  character before the stream, a get reads before it checks its argument,
  a stream's direction is asked before its kind, open/4 checks every option
  and opens the file before it asks the stream argument, write_term/3 its
  options before the stream, and a position is
  `'$stream_position'(Char, Line, LinePos, Byte)`. A binary stream's
  characters are its bytes (swipl's octet): a get_char reads one byte, a
  put past 255 is `io_error(write, S)`, read_term/2 reads bytes past 127 as
  their characters. **Every encoding is applied** (3.19.0; latin-1, octet
  and ascii 3.17.0): a slot's encoding (`st_enc`) gives its class
  (`st_cls`: 0 UTF-8, 1 a byte a character, 2 and 3 UTF-16, 4 UCS-4), the
  one writer (`st_emit`) encodes the UTF-8 text every put, write and sink
  hands it, and a UTF-16 or UCS-4 read decodes a character into the
  pushback (`st_decode1`), its first byte standing for the bytes it took
  (`st_praw`, `st_rawd`) -- **a new reader or writer of a file goes through
  them**, or it is UTF-8 whatever the stream says. Since 3.58.0 swipl's
  MIME names (`'UTF-8'`, `'ISO-8859-1'`, `'UTF-16BE'`, `'UTF-16LE'`) open
  and set a stream, and stream_property/2 answers swipl's own name for an
  alias (`utf16be` for `unicode_be`, `stream_enc_name`). `''/7`
  takes the encoding and the BOM; `set_stream/2` is `''/5`
  (`:PI` rows, both); the console's position is the engine's
  (`coco_out_note` counts user_output and user_error as one, read by
  `coco_m_out_where`). Not swipl's: `text` is UTF-8, swipl's `io_warning`
  for a malformed unit is not said, and a quoted write of a character past
  255 into a binary stream raises where swipl's escapes it (COMPAT.md).

* **A signal is a halt code** (2.6.0): a handler in `modules/signal` writes
  `4 + SIGNO` into the engine's `halted` cell (the one object a handler may
  assign), and `coco_halted_step` (lib/solve-loop.cicili) flushes the
  continuation, builds `signal(Name, Num)` from `coco_signal_name`'s one
  name table, and raises `error(signal(Name,Num), _)`; codes are below 128.
  The module's handler is a Cicili function writing a `sig_atomic_t *`
  (`coco_m_signal_cell` answers the calling engine's cell); the raw C left
  in that module is the `signal(2)` dispositions, because the std's
  `SIG_DFL`/`SIG_IGN` are ints and its handler is a function pointer.
  `coco_m_signal_pairs` answers the names. `coco_error_text` prints SWI's
  `Caught signal N (Name)`. The REPL installs a core SIGINT fallback over
  the same cell before it tries `library(signal)`'s throw, and the plan's
  limits hold: delivery is at the next step, a blocking foreign call
  defers it, and a handler installed in a green thread's machine writes
  that machine's cell. `test/signal.pl`, lesson 53.
* **Green threads are a compiled-in module** (2.6.0, `lib/green.cicili`,
  registered as `green` in `setup`), and `library(async)` is the clauses
  over its `$async_*` C -- TIER 1 since 2.8.0, preloaded at start-up, so
  async coroutines are on by default. A green thread is a MACHINE of its
  own in a WORLD of one worker a CORE (2.9.3, Go's GOMAXPROCS rule: the
  caller's thread is worker 0 and N-1 OS threads are workers 1..N-1,
  `COCOLOG_GREEN_WORKERS` overriding N for a benchmark arm or a narrow
  affinity; it was eight through 2.9.2), **each worker's C stack never
  under 8 MB** (3.60.1, a library(thread) thread's: the system's default,
  raised where it is less -- macOS gives a thread 512 KB, where a task
  could not write back an answer 10 000 levels deep). `async_workers/1` answers N
  (2.15.0, `coco_g_async_workers`): inside a world the world's own
  `nworkers`, read through the thread-local `green_now` whatever the
  variable says since; outside one `coco_g_nworkers`, what the next
  async_run/1 takes. **ONE STORE (2.9.0)**: every worker, and so
  every task's machine, runs over the caller's own store and machine
  (`(-> wi st)` the host's, `(-> wi base)` the host machine); a spawn
  copies nothing but its goal. **THE NAME TABLES ARE SHARED (2.8.1)**:
  all eight bases alias the host's ONE atom/functor/string/float/big/rat
  table under a world names mutex -- the six mutations take it, sync a
  machine's fields by generation (`tgen`,
  `coco_tbl_set/sync/begin/end/grow`) and publish to the root; value reads
  are lock-free from the run-start sync; while shared, growth allocates a
  new array and never frees the old (a stated leak); the alias list is
  under the same mutex. **AN INTERN HIT TAKES NO LOCK (2.9.2)**:
  `coco_tbl_sync` returns on a matching generation without the mutex,
  `coco_intern_len` probes a hit without the lock and publishes nothing,
  and only a miss locks, syncs and looks again (`coco_tbl_done` unlocks
  without moving the generation, which an intern hit used to move for
  every other machine); the lock and that publish, paid on every spawned
  goal's text read, were the light lane's 3.6x. **A GREEN CHANNEL'S HANDLE
  IS ITS SLOT PLUS 1024 (2.9.4)**, and library(thread)'s channels (integer
  slots 0..255) DECLINE a goal whose channel is not one of theirs (its four
  channel rows end in `:declines`, and `th_chan_at_d` declines a
  non-integer or an id past 255): both modules register channel_send/2 and
  the rest, and before this a green send could land in whatever thread
  channel held the same slot number -- silently, when that slot was live.
  **The module SDK's dispatcher emits `:declines` as lib/module.cicili's
  does** (it did not until 2.9.4, so a loadable module could not decline at
  all; lib/sdk.cicili is the one place). A task is PINNED to the
  worker it was born on. A
  WRITE STOPS THE WORLD (2.9.0): every store mutation -- assertz/asserta,
  retract, dynamic, abolish, nb_setval -- and every piece of metadata a
  first call makes (a predicate created, a clause compiled, an argument
  index built, a sweep) binds the barrier's let variable
  `(defer () coco_g_write_end_cleanup)` to `coco_g_write_begin`: the
  writer publishes an op (the world's `op`, writer, seq, acks), pokes every
  worker and waits for `nworkers - 1` acks -- so a write is O(nworkers)
  apart, and a first touch that writes once an item (a clause's first
  compile) must not be left in a loop: bench/concurrency.pl's `store_warm`
  compiles every clause on the host before the world -- taking one
  solution only (`ignore') left 10,000 compiles each a barrier, and the
  lane was 1.17 s at 8 workers and 2.7 s at 16, 0.10 s warmed either way; a worker acks at its loop's
  top, or inside `write_begin` while it waits for the op in flight (a
  task inside a store call cannot reach its loop top, and without that ack
  a writer and a writer's task deadlocked); the writer changes the store
  with no lock held, and `coco_g_write_end` frees the op and broadcasts.
  **Three bugs this cost, each with a test**: (1) the waiting worker
  compared the op by POINTER, and calloc handed a freed op's address back
  -- the worker read the NEW op's sequence through it and slept instead of
  acknowledging (an ABA; capture the seq as an int); (2) every cleanup
  called `coco_g_write_end` regardless of its `began`, so a metadata call
  nested inside `assertz`'s barrier freed the OUTER op and let the rest of
  the write run beside other writers (lost asserts; end only when
  `began[0] == 1`); (3) `coco_pred_make` is a double-checked lock and had
  no second find inside the barrier, so a reader's CALL to a name the
  store lacked (a call interns it too) and a writer's first assert each
  created the entry -- the second creation hid the first and its clauses
  (`coco_clause_code` has the same recheck). `test/async.pl`'s last
  section makes the third likely by shape and goes red without the
  recheck. **THE 2.8.0 SCHEDULER BUGS ARE FIXED (2.8.1)**: the block was
  set under the world lock but the task's state only later, in the run's
  rc-0 handler, so a target finishing in the window woke nobody and the
  waiter slept on a done task -- a false deadlock in the light lane; and
  with the host as the single root the alias list was unlocked, so a lost
  link left a freed machine on it -- a use-after-free or a cycle. The
  state is set inside the builtin's lock, the link/unlink take the names
  mutex, a per-worker wake generation is checked under the lock, and the
  deadlock is asked after any block, not only when a pick finds nothing.
  A consult or load a task runs and a module's own C state stay per
  worker. The store's frame walks visit every machine the store lists, a
  suspended task's engine through `keep_eng` -- NEVER `m->eng`:
  pre-setting it made the engine its own `outer`. **THE MACHINE LIST HAS
  ITS OWN MUTEX (2.9.1)**: `st->machines` is linked by `coco_g_prepare`
  on a task's worker OUTSIDE the world lock and unlinked by
  `coco_g_thread_free` as a task finishes, sometimes under it; unsynchronized,
  a link raced an unlink and a freed machine's address came back on the
  list -- a cycle the unlink walk spun in under the world lock (the light
  lane's hang), or a freed read (a SIGSEGV, one run in twelve). The world
  lock is never taken under `mmx`. **A SESSION IS A THREAD'S (2.9.1)**:
  the engine's transaction is thread-local, and the client kept ONE
  session per connection made on the host, so a green task's first call
  to a predicate the process had not read yet fetched through the
  backend on the worker's thread with no transaction there -- a SIGSEGV
  in MVCCS's `visible()`, one unit as surely as eight. `client/zigurat.c`
  now keeps a session PER THREAD per connection (a registry keyed by the
  connection in a thread-local, freed by a pthread key's destructor on
  the exiting thread, where the rollback belongs; `zg_close` frees the
  caller's). A thread that is not the connection's OWNER (`zg_owns`,
  true for every socket handle) never batches: its write syncs the
  predicate in the hook and commits its own session there
  (`lib/zigurat-kb.cicili`), and it never flushes the owner's dirty
  list; the owner's batching is unchanged. A green task may now fetch
  AND write under `--embed`; the server arrangement's socket is still
  one connection for all threads, and a task's write through it is
  untested. No table reclamation
  (`tshared`) or store compaction (`st->machines`) runs while a world
  does. THE QUANTUM: the run sets `max_steps` to the task's steps +
  10,000; `coco_limit_go`'s GREENQ branch sets GSTOP, flushes the
  continuation and stops -- the engine reports its limit (-1), so the run
  checks GSTOP BEFORE rc and keeps the task ready (an rc-only check made
  every preempted task a system_error) -- and a task that never yields
  cannot hold its worker; a foreign call still can. A worker picks its
  ready tasks round robin and waits on its own condition variable; the
  deadlock is asked when a worker's pick finds nothing (NOT after every
  run: 1024 tasks, 10,000 runs cost 18 us a task that way and 14 this; and
  NOT before the main task exists -- the workers start first and
  `nthreads` 0 is not a deadlock). The main is task 0 on worker 0; the
  caller runs worker 0's loop; the world waits for a pending write and then
  stops. 1024 tasks and 64 channels a world. A result is the goal as
  instantiated, in canonical text; a throw is rethrown by `await/2`; a
  deadlock is raised as resource_error(deadlock) at `async_run/1,2`.
  `test/async.pl`, lesson 54, `bench/concurrency.sh`,
  `library/async/README.md` (the model, the Run G numbers and the limits).
  A library predicate with a choice point per answer (`between/3`) is slow
  -- the concurrency benchmark's workload is a recursion, and the finding
  is recorded there.
* **A `{}` or `[]` FUNCTOR is written quoted** (2.6.0): `coco_write_atom`
  grew bit 32, the functor's force, used for those two names in the
  canonical application path, so `{}(X)` is `'{}'(X)` and reads back. The
  atom `{}` alone still writes unquoted. A snapshot of SWI's yall library
  found it: `lambda_free({}(_G))` would not consult until the writer
  quoted it.

## The document libraries

`library(json)`, `library(xml)`, `library(html)` (with CSS) go both ways:
writers answer CODES, readers take codes or an atom, all six halves are DCGs.
**The round trip is the test** (`test/serialize.pl`). **A code list is a
list**: `str(X)` is how text is said. **They throw rather than guess**, naming
the term. `xml.pl` reads no DTD (XXE is impossible, an undeclared entity is an
error); `html.pl` leaves an unknown entity as text, refuses `</script` inside
`script`/`style`, has no indent option, and is NOT an HTML5 tree builder.
`html.pl` reuses `xml.pl`'s escaper by name; the UTF-8 encoder is copied on
purpose.

## Cryptography and TLS

`sha`, `aes`, `der`, `x509`, `tls` and the clauses-only `library(ca)`:
**arithmetic is bound, grammar is Prolog, policy is clauses.** **Keys are
files, never terms** (a key in an atom would reach the trail, channels and the
store); a pass phrase arrives by `getenv/2`. `X509::issue`'s issuer argument is
a NAME CONFIGURATION, not a certificate. `certificate_public_key` yields the
SPKI's contents; `der_wrap(48, K, S)` puts the header back.

* **A client certificate is optional for TLS and mandatory for
  permissions**: under `SECURITY/PERMISSIONS_MODE` a plain connection reaches
  everything, TLS without a certificate nothing, with one what it grants.
* **Under TLS 1.3 a missing client certificate is not a failed handshake**:
  `SSL_connect` succeeds and the refusal arrives on the first read; a test
  checks what the peer REACHES.
* `library(tls)` is `library(tcp)` with a handshake: the stream stays in the
  module, a handle is a slot, every refusal FAILS (`tls_why/1` says why).
  `library(httpd)` does HTTPS through tagged connections
  (`plain(S)`/`secure(S)`); the peer's identity reaches a page as
  `Tls-Peer-Subject`/`Tls-Peer-Permissions`, stripped from the client's
  request on both transports.
* The one TLS client unit is `client/tls.c` (`coco_client_tls_*`); a failed
  Zeytun fetch prints its reason on stderr.

## The reasoning library and the translator

`library/reasoning/`: `reason.pl` (controlled English as a DCG, questions,
explanations, topics), `normalise.pl` (the generator of tagged training
pairs), `tagger.pl` (a GRU tagger over `tensor_expr`, plus the deterministic
judge `tagger_sane/2` and repair `tg_repair/3`), `translate.pl` (sentences
read into an English-worded IR and written into any lesson's language),
`teach.pl` and `page.pl`. Cases: `test/reason.pl`, `normalise.pl`,
`tagger.pl`, `translate.pl`; lessons 43-46 in `tutorials/library/`.

**Where the data is, and who reads it:**

| path | what | rebuilt by |
|---|---|---|
| `corpus/*.txt` | hand lessons, one sentence a line -- **the TAGGER's corpus** | hand |
| `corpus/extra/<lang>.txt`, `extra/eng-*.dix` | lines and dictionary entries Apertium lacks or gets wrong -- vocabulary only, never read by the tagger, written FIRST | hand |
| `corpus/vocabulary/*.txt` | ~110k Italian and ~139k Spanish lesson lines, committed | `corpus/build.pl` from `corpus/raw/` (`tools/corpus/fetch.sh`, not committed) |
| `generated/`, `model.rows` | the training pairs and the shipped model, committed | `tools/tagger/train.sh` |
| `lexicon/*.txt` | WordNet and census words, committed | `tools/lexicon/build.sh` |

* **A change to `corpus/*.txt` is a data change for the tagger**: regenerate
  `generated/` and `model.rows`, and expect a minority shape to re-roll. A
  word that is vocabulary rather than a shape goes in `corpus/extra/`. A
  training is deterministic, so retraining unchanged data fixes nothing.
* **Rebuild the vocabularies after the LAST line of `extra/`**:
  `test/translate.pl`'s `build` section rebuilds the Spanish file in a scratch
  corpus (with `raw/` and `extra/` symlinked) and requires it byte for byte.
  Read a rebuilt vocabulary for what it LOST (a set diff), not only what it
  gained.
* **A line of `extra/` has two readers**: it comes first for its WORD and
  for its MEANING, so it moves the reader of one language and the writer of
  the other. Say the dictionary's own word again first where the line must
  not become the word written. **A line that gives a COMMON word a second
  meaning makes every sentence with that word read it twice over** (`The word
  "che" means "which".` made the old translator 11.2 % dearer over the
  controls on the new store and the six heaviest sentences 2.6 times, and the
  factor multiplies: cecchi 8 has two `che` and rose 3.9 times, the other
  meaning being tried again on every failing road): find such a line by
  teaching a store without each group of the new lines (50 s a store) and
  counting the heaviest sentences, and where the second sense reads as the
  first, let the code take it from the first (`tr_which_asks/2`). **An
  elision a lesson states is read AND
  written**: `"dev'" is the elision of "deve".` makes the reader take `dev'essere`
  apart (tr_expand/3, for a verb form or a question word only: an article's,
  a pronoun's and a preposition's keep theirs, which their readers ask for),
  and made the Italian writer elide every `come` before a vowel -- the data
  column found `com'assicurano i palestinesi`, `paesi com'Alemania` and
  `considerato com'il Van Gogh` in ten sentences of the old controls. The
  writer elides such a word only where the lesson says what the elided form
  comes before (`"com'" comes before "è".`, as for a pronoun's;
  tr_elision_written/3), which no lesson says yet.
* **A store learns only the lines it lacks**, appended: an ORDER is a
  property of a teach, not of a line. A data fix is proved on a store taught
  from the rebuilt vocabulary. Teaching both languages into one fresh
  `--embed` store takes ~40 s on 1.10.0 (18 s and 23 s, four vCPUs; it took
  ~11 and ~18 minutes), so **try an ORDER effect on a fresh store before an
  `extra/` line is final**: a working store that had lines appended in
  another order showed a first meaning the fresh one did not (`de riesgo`,
  `cualquiera`).
* **The reasoning libraries read both text units** (1.13.2; bytes were the
  default through 1.x, characters are since 2.0.0). Every
  clause that names an accent or a mark by its UTF-8 BYTES (`[195, B]`,
  `[226, 128, 156]`, `[194, 171]`) has a TWIN that names the CODE POINT
  (`rt_upper_cp/1`, `[8220]`, `[171]`) in reason.pl (the tokeniser,
  `rt_tokens/2`, `rt_run/3`, `rt_letter_next/1`, `rt_word_case/2`,
  `rt_lowers/2`, `rl_vowel/1`, `rl_letter/1`), translate.pl (`tr_cap/2`,
  `tr_cap_head/2`, `tr_lower_codes/2`, `tr_capitals/3`, `tr_capital_start/1`,
  `tr_small_code/2`, `tr_unaccent_codes/2`, `tr_quote_mark/4`,
  `tr_speech_mark/4`, `tr_has_dash/1`, `tr_mid_marks/2`, `tr_inside_dashes/2`,
  `tr_pre_words/2`, `tr_written_number/4`, `tr_number_written/4`),
  normalise.pl (`ng_cap/2`) and corpus/build.pl (`cb_lower_codes/1`). **A twin
  on a code past 255 needs no test** (no byte is so big); **a twin on a code
  of 128..255 asks `rt_chars/0` AFTER its numbers matched**, because there the
  readings meet: 195 is the lead byte of `é` and the code point of `Ã`, and
  226, the lead byte of every dash and quotation mark, the code point of `â`.
  Where a clause can be written with a constant head, the twin is one (no
  inference is spent in bytes). **A new clause that names an accent or a mark
  by a number gets its twin in the same edit**, and a probe in
  test/translate.pl's `newspaper_units` (two children, one per unit; 49
  probes, an arm per rule, 25 of them, each red). The controls on ONE binary
  (1.13.0, KB86, 87 files, 2016 sentences): the translator as it was changed
  208 sentences under characters (188 refused, 20 other texts, +20.7 % of the
  inferences); the one with the twins changes none in either unit, +0.052 % of
  the inferences in bytes and +0.026 % in characters. NOT migrated, and the
  controls found no difference: `atom_length/2` and `sub_atom/5` over an
  accented word count characters in one unit and bytes in the other (the
  thresholds on a stem's length in the clitic rules), and
  `upcase_atom/2`/`downcase_atom/2` change an accented capital in characters
  only (`tr_city_name/1`, `tr_abbreviation_end/1`). Characters is the
  default since cocolog 2.0.0, so the byte clauses and the tests of
  `rt_chars/0` can go -- the reasoning library's change, on its own number;
  until then a program that asks for bytes reads them as before.
* **Find a translator cost with the flow profile, then bisect it** (1.11.4).
  `cocolog -s tools/flow/debug.pl -- GOAL library/reasoning/translate.pl BASE
  embed=STORE cache=DIR profile=true txt=true from=I to=J` over several
  windows of a few thousand steps spread along a run (a refusal of
  65 million steps, say) gives BASE.prof, and a call there is ONE
  step, which is its whole self cost: rank the predicates by CALLS, then
  by their callers. (The library's unit is the STEP, its texts say so since
  1.13.6, and each profile view says how many of a window's steps were
  inferences: a call of true/0 or =/2 is a step and no inference.) Since
  1.11.10 `profile=all` writes the callers, the goals asked again and the
  steps by what took them (constructs included) into BASE.prof -- no script
  over BASE.txt -- and `windows=N` records N windows along the run, J at a
  time, their profiles added up; `svg=false xml=false` for a profile alone.
  Since 1.13.3 `profile=time` (and `all`) writes where the window's TIME
  went, the probe run under a clock read at every step: a count finds the
  cheap step taken a million times, time the one step that costs a
  thousand (a sort, a findall/3's copying, a store's lookup); since 1.15.0
  each row ends ` @W:S`, where its largest call is (window W, step S: a
  window of a few thousand steps recorded around S reads the call with its
  arguments), and `profile=run` (asked by name; not in `all`) writes each
  predicate's self time over the WHOLE run, a probe of its own under the
  clock from the first step, about twice the run's time. A window of
  100 000 steps far along the translator takes ~30 s that way (100 s with every document
  through 1.11.9, whose matcher alone took 36). Half of the inferences were the lexicon lookup layer
  (tr_solve/1, tr_memo/4 and what they call), and its four wastes were each a
  few per cent: `member/2` on a LIST WALKS IT (a clause per element) where the
  first argument is given -- tr_class_of/2 over its fourteen classes, 4 % of
  all inferences; tr_memo/4 read the generation through a predicate and
  compared what a unification does; the lesson's predicate name was built
  through four calls; tr_language/1 is three inferences where the read in
  place is one. An edit that replaces calls by an if-then-else moves nothing
  (the construct is a step too: tr_solve/1's rewrite saved +0), and the
  controls say so in inferences, not the clock -- ask the clock afterwards
  (five alternating pairs, 6 % less user time).
  **Round two (1.11.5) took the layer's idioms, and found them in the same
  windows**: BASE.txt parsed for the CALLERS of a predicate (the parent is the
  nearest line above with a smaller indent) and for the goals ASKED AGAIN --
  in a window of 100 000 inferences 1 528 tr_solve/1 calls were 391 distinct
  goals (74 % repeats) and 648 tr_class_of/2 calls were 71 pairs of a word
  and a class. A repeat is not a memo's to catch: a hit of tr_memo_w/5 costs
  11-13 inferences against 19 for the lesson, and a memo of tr_class_of/2 cost
  37 where the lesson's own answer costs 35 -- it was tried and left out.
  What paid was the idioms: `tr_language/1` is 7 inferences (the if-then-else,
  the catch/3, the read, the `true`), the plain read is 1, and
  `catch(nb_getval(K, V), _, R)` is 3. So the language and the generation are
  MADE WHEN THE LIBRARY LOADS (`:- nb_setval('$tr_language', none),
  nb_setval('$tr_gen', 0).`; tr_memo_reset/0 checks the language too) and the
  hot sites read them plain: tr_solve/1, tr_is/3, tr_lexeme/4, tr_form/5,
  tr_coord/2, tr_memo_w/5. A site that may meet a machine that never loaded
  the library keeps tr_language/1, which answers `none`. tr_prove/2 is gone
  (tr_lesson/2's first clause is `none`); the rule lookup is a plain call of
  the dynamic `lesson/2`, which never raises; the fact call is its own
  catch/3, not tr_solve_plain/1's two steps; the three wrappers are clauses
  with head patterns where an if-then-else asked `atom/1` of what the head
  already holds. A failed lookup went from 29 to 19 inferences, a found one
  from 28 to 20: the 87 controls 4 879 595 021 -> 3 448 261 913 (-29.3 %),
  every status and text the same. **The clock fell less than the count**: the
  eco control 214 939 001 -> 146 057 424 inferences (-32 %) and 17.44 -> 15.77
  s of user time (-9.6 %, five pairs of five), because what is left is a
  memo table COPIED out of its global at every hit (below) and not a step.
  tools/flow/chart.pl finds the clauses an insertion splits (`not together`:
  tr_time_phrase/1, tr_comps_out/7 were found so, 38 old ones remain).
* **Find which piece of a refused sentence fails with the flow record**
  (the owner's ask, 2026-10-28). Run `cocolog -s tools/flow/debug.pl --
  "reason_translate('TEXT', spanish, english, T)"
  library/reasoning/translate.pl BASE embed=STORE cache=DIR svg=false
  xml=false txt=true` once, which says `false at step N`, and again with
  `from=1 to=N`: the window then holds the whole run. The satanic report's
  17th sentence, 1 532 822 steps, took 7 minutes, 8.8 GB and a BASE.txt of
  144 MB; a refusal of 8 million steps does not fit this box. **The
  furthest path at the foot of BASE.txt can name a scan**: it ranks a
  clause by the calls of its body that exited, and tr_read0/4's clause for
  a quotation that opens inside the sentence walks every position with
  append/3, three calls exiting at each, so it was the path (58 calls) and
  had read nothing. **Rank by the steps each clause spent** (a script over
  BASE.txt: a line a call, its depth the indent) and read the arguments on
  the way: the colon's clause spent 648 153 of 1 297 196 steps, its left
  side read and its right side did not, and the right side's words held
  `'$aside1'` where `, Templo Tezcat,` stood -- tr_asides/3's comment of a
  verb in the first person, taken from a name's first word (`templo`, I
  temper), so `Los Satanistas Setumismo` was one phrase. The steps alone do
  not name a cause either: in the right side the most went to the front
  search of tr_read0/4's clause 56. Two probes settle it: without the name
  the sentence reads.
* **Memory**: a teach sat at 4-9 GB resident before the heap collector of
  1.8.36 and peaks near 1 GB since (the Spanish pass, measured on 1.8.40), a
  tagger training is near 10 GB, `test/tagger.pl` alone; on a 14-16 GB box run
  the big ones apart -- a cocolint run
  beside a teach was OOM-killed (exit 137) when the linter still reached
  10 GB; the corpus lint peaks near 3.5 GB now. A killed process never
  flushes. **An arm that removes half of a coupled change can loop and grow
  its heap past 13 GB** (a clause left with an unbound variable): run arms
  under `ulimit -v`, and never beside a teach -- the OOM killer took both.
  `tagger_tag_all/3` keeps a batch's intermediate tensors: tag big grids a
  sentence at a time.
* **A small case lesson reproduces a fault only when it gives the word every
  role the vocabulary does** (and every form: a lesson with one participle
  form cannot test agreement). A guard is proved by an ARM that puts the
  first cut back and goes red; a guard whose arm is green proves nothing.
* **A right text is not a right IR.** English IS the IR; translate into
  English to see what crossed. A refusal with `unknown: []` is a missing
  SHAPE; one that reads into English and refuses into the target is a target
  vocabulary gap.
* **The owner's sample loop** (one article at a time, alternating directions,
  until an article needs no change): build the shapes; add `extra/` lines;
  rebuild and teach a fresh store; then the CONTROLS -- every earlier article
  plus Tatoeba's 400, this translator against the last version's on the one
  store, twice -- and the DATA COLUMN, the last version's translator on its
  own store against the new store, the only place a line of data shows. Fix
  every regression, find every cost by hunk bisection (the heaviest sentences
  of a pass, written to a file and counted over a copy of the library per
  rule: two seconds a copy, where a pass of the controls is two and a half
  minutes), add a section to `test/translate.pl` and to lesson 46, record the
  stated costs. An arm is the same copy run through the section: **one whose
  removal makes the section RAISE has no FAIL line**, so read the last line
  (`GREEN` or `RED`) and count the `ERROR` lines as well. Controls run
  BEFORE the commit. **Merge `origin/master` before the teach** when it moved
  the engine, so the numbers belong to the binary that is committed, and **run
  the whole `test/translate.pl` (half a minute on 1.15.0) before it**: a section
  alone cannot see an older section's check -- the Cecchi section was green for
  days and the whole case had eight red, and the Tempi section's `Persino ...`
  before a subject read `Hasta entonces el perro duerme` as `even the dog`.
  Read the controls' TEXTS, not only their counts: they found a pronoun lost
  (`lo`), a committee made the object, `ma non` written last, a sentence that
  ran to the 300 M inference limit and `l'anima` as `lo anima`; and sum the
  counts by hunk -- a clause that reads the phrase's words a second time at
  every place that read nothing cost 3 %.
  **A refusal can hide a wrong reading**: English refused a clause with no
  subject, and giving it `they` for a verb of saying turned `dijo el
  presidente de la Generalitat, que inauguró` (the speaker read as an object)
  into `they said the chairman` -- look at the IR of what a fix now writes,
  not only at its text, and at a sentence the fix was not made for.
  **Diff the first word of every meaning** between the committed vocabulary
  and the rebuilt one (class and English meaning to first word, gender
  ignored: the writer takes the first noun of a meaning whatever its gender):
  an `extra/` line, a dictionary entry marked `RL` among them, is the first
  word of its meaning wherever it lands in the file. The Abogacía report's
  lines made a feminine `consigliera` the first Italian noun for an adviser
  (every `conseller` was `la consigliera`; the feminines mean a `councilwoman`
  now, so a woman crosses as a woman and the masculine is the adviser),
  `letrado` the first Spanish noun
  for a lawyer (`su letrado`), `president` the first for a chairman, and
  `The word "quienes" follows the preposition.` the relative a Spanish writer
  puts after EVERY preposition (`en el que` was `en quienes`, in 19 sentences
  of the data column); the dictionary's own word is said again first, and a
  line that a reader needs and a writer must not use stays unsaid.
* **Open leads, recorded and not done**: the builder calls a noun a person
  only by its first English word; the upstream verb table
  has `scaping`/`leaved`; `No comas el pan.` reads the subjunctive before the
  negative imperative; `pronto` after a verb crosses as `immediate`; `ir a`
  and an infinitive is the near future and reads as a verb of motion, with
  the infinitive's clitic on it (`nos vamos a quedar` is `ci andiamo a
  rimanere`); Spanish `advertir a los suyos` takes a direct object in
  Italian (`avvertì ai suoi`); `da` before a bare noun is `desde` (`una fama
  desde hábil niño`); `portarsela dietro` is an idiom and crosses word by word
  (`traersela atrás`); a contraction before a quoted article drops
  the opening mark (`de "la casa"` is `della casa"`); a lesson line gives a
  word ONE sense in both numbers (`competencias` are powers, `la competencia`
  the rival firms, and the line for the first moved the second); `su` for the
  owners of a plural crosses as `il suo` (`su futuro` of the shops);
  `afectar a` keeps its `a` (`influire negativamente alle centrali`); an
  adjective after two coordinated nouns agrees with the nearest (`centrali e
  gruppi di spesa spagnola`); `se si elevasse` crosses as `si se elevó`, the
  imperfect subjunctive written as a past indicative; `del quale` is `de
  quién`; `un altro milione` is `un otro millón`; `insomma` at the head of a
  clause is written at its end (`en resumen`); `in termini percentuali` is
  `en porcentajes plazos`; the clitic `ne` crosses as `lo` (`ne potranno
  beneficiare` is `lo podrán beneficiar`); `da` after coordinated participles
  is `desde`; an adjective after a quoted noun agrees with the nearest noun
  outside the marks (`"reddito minimo di inserimento" francese` is
  `francesa`, `si chiama "minimo vitale"` is `se llama "mínima vital"`);
  English writes `Non sono pochi` as `Few are not` and moves a quotation's
  marks to the edges of its phrase; a name of one capital word and an
  adjective (`Roma antica`) is not read; `participar en` is `partecipare
  nel` (`partecipò nell'attentato`) and `a poca distancia de` `a poca
  distanza di`; `fue abatido` is `era abbattuto` (the lesson's past of `è`
  is `era`); `cerca de su casa` is `vicino la sua casa` (the hand lesson's
  `vicino` first, the `de` dropped) and `dentro de` a vehicle `entro`; `su
  esposa` is `la sua moglie`; `huían del lugar` is `fuggirono del luogo`
  (`de` after a verb of motion is not `da`); `pasado` before a day is
  `passata domenica`; `ayer` after the verb is written last (`in questa
  zona ieri`); `heridas` after `causando` is the singular `ferita`; `de
  gravedad` is `di gravità`; `murió un joven` reads the subject as an
  object, as the lesson does not call `morir` intransitive: Italian writes
  it as read and English refuses it (17 and 21 of the Israel report); a day
  fronts a relative clause only as an article and its noun (`que todos los
  domingos visita`, `que cada domingo visita` and `que el 12 de enero
  compró` are refused); `su` after a verb of writing is `en` (`scritto su
  Montanelli`, not `sobre`); the imperfect crosses as the preterite
  (`sapevo` is `supe`, `mi piaceva` `me gustó`); `lo conosco` is `lo sé`
  (the clitic does not say whether it stands for a person or a fact), and so
  is the object of a relative (`il giornalista che io abbia conosciuto` is
  `he sabido`); `la prima di molte lezioni` reads `prima di` as the
  preposition `before` and `il primo era buono` reads `era` as a noun;
  `Dare ordini` reads the infinitive as a subject and `ordini` as its verb
  (`Dar ordena`); `piano` is `plan` after an ordinal (`al terzo piano`, `al
  tercer plan`) and `campioni alimentari` `campeones`; `darsi da fare`,
  `darlo a vedere`, `non ci sono riuscito`, `adesso che ci penso`, `passare
  per la testa`, `in fondo` and `all'opera` cross word by word; a clitic
  cluster is not rewritten (`decirlelo`, `se la ricordava` is `si la
  recordó`); `dei libri da non scrivere` is `desde no escribir`; `Sapendo
  che dorme, lui mangia` reads `lui` as the gerund's object clitic; `ancora
  quindi più cara` after a comma reads `ancora` as the noun (`ancla`); the
  role after `da` is written `as student` into English, with no article; an
  apposition keeps no gender (`la sua compagna` is `su compañero`); `tutti
  quelli` is `everyone those` into English, never `all of those`; `esperar
  que` is `attende che` (hopes that) and `apostar por` `scommettere per`;
  `gran` before a vowel is written whole (`gran asse`, where Italian has
  `grande asse`); a subjunctive after `impiden que` is written as the
  indicative (`che ... è continuo`, `che si permette`); `también` and
  `siempre` are written last (`il passaggio di Vintró anche`); a dash aside
  inside a quotation is written after the whole sentence, outside its mark
  (`"La peatonalización - añade - complementará ..."`); `fincas` are farms,
  `acogerse a` is `riceversi a` and `contar con` `contare con`; `Rambla` at
  the head of a sentence is the common noun (`Passeggio senz'ostacoli`); a
  capital word the lesson knows as an adjective crosses by its meaning unless
  the lesson says it is a name (`"meridiana" is a name.`); English refuses a
  null third-person subject (`asegura`, `añade`), and does not write a
  relative clause `en que esté permitida` or one with a participle and its
  agent after `contará con`: four of the Clot report's sentences stay out of
  English; from the Quartieri report (Italian into Spanish): the words
  `linguaggi` (`idiomas`), `laboratori` (`laboratorios`), `strada` after
  `teatro di` (`carretera`), `sfilata` (`intestino`), `palco` (`etapa`),
  `costumi` (`costumbres`), `opere` (`óperas`), `pannelli` (`tableros`),
  `tele` (`lonas`), `svolgersi` (`actuar`), `contributo libero`
  (`contribución gratuita`), `impegneranno` (`comprometerán`), `saranno
  insieme` (`serán juntos`), `per una settimana` (`para una semana`) and
  `ragazzi` (`niños`; `chico` first broke `bambino`) are the dictionary's
  first word, not the news's; `a` before a place keeps its `a` (`a Harlem`,
  `a Tor Bella Monaca`, where Spanish says `en`: the lesson has no notion of a
  place), a country keeps its article (`desde la Italia`) and a name is
  translated word by word where its words are common (`Alta tensione` is
  `Alto voltaje`, `Sud Africa` `Sur Africa`); a quotation, its verb and then
  the speaker (`..." spiega Nicoletta Gaida`) writes the speaker as an object
  (`explica a Nicoletta Gaida`) and the apposition after it keeps no gender
  (`ideatrice` is `creador`); a quotation inside a quotation (`come
  "delinquenti"`) loses its place; `che da anni coinvolge ... e dal Sud
  Africa l'amajica ...` is one relative clause to the end of its bracket, so
  `desde hace años` is written at the end of the bracket; `nuovi linguaggi del
  disagio giovanile in cui immergersi` attaches `in cui` to `disagio`
  (`en el que`); `"quartieri"` in lowercase marks is translated (`"barrios"`)
  where the lesson names it only with a capital; a name that begins with a
  word the lesson knows (`Lord of the Rings`) is still refused, and `&`
  between lowercase words is dropped (`pane & vino`). A bare noun before
  `di` no longer takes the gender of the noun after it unless it says a part
  (`tasse d'iscrizione` is `impuestos de inscripción`, like the first
  `tasse`; it was `tasas`, by the gender of `inscripción`). English writes
  a weekday with no capital (`thursday 20`), and refuses sentence 20 (`Inoltre un convegno
  (giovedì 20), proiezioni, la mostra dei Murales, ...`: a heading made of
  `La mostra` alone is refused into English).
  The Abogacía report (Spanish into Italian and into English) is read and
  written whole, and its leads are fixed (1.10.3, 172 checks over it). What
  it still leaves: `Se la cava.` has no `cavare` in either dictionary (and an
  idiom of several words crosses word by word); `Os lo digo` was `Ti lo dico`
  -- the lesson language had no second person plural (`coméis` was no word,
  `os` and `vi` were `you`, and the IR's `you` had no number: settled by the
  Tatarella interview below); English writes
  `Lo dejo comer` as `I leave him to eat`, `Lo veo venir` as `I see him to
  come` and `Hago comer el pan al perro` as `I make to eat the bread to the
  dog`: what makes, lets or watches somebody do something is a construction
  of its own -- the doer of the infinitive has no term in the IR (the clitic
  or the `a` phrase stands beside the infinitive), a lesson names no such
  verbs, and `dejar` has no meaning of its own before an infinitive;
  `se limitó a decir` is `limited to say` (English wants `himself` and `to
  saying`, and the IR's noun carries no gender for the pronoun); `más de lo
  que recibe ahora` is `more than the one that receives` (the IR does not
  tell `lo que`, what, from `el que`); the clitic after another clitic or a
  reflexive is read as a thing in English (`me lo apunto` is `I note it`,
  `te lo digo` `I say it to you`), which a person is not (`se lo llevaron`,
  took him away); the Spanish `-ra` form is read as the imperfect it stands
  for after `si`, `como si`, `sin que`, and so it is in the literary
  indicative past of a relative clause or after `después de que` (`donde en
  1988 lograra`, `después de que la lista acusara`: `otteneva`, `accusava`
  where the preterite was; two sentences of the controls, against the many
  it mends: `como si eran pocos`, `si teníamos más`, `sin que figuraban`);
  and the comma before a preposition and its relative is lost
  where the piece has other commas (`reivindicó, ayer, un trato mejor para
  los abogados, a quienes ...` reads `... per gli avvocati a cui ...`:
  keeping it was tried twice and costs the Valencia report's second 1.7
  million of its 9 and the festival report's last 0.4 million of its 3.5).
  The rest of its English is the dictionary's (`a favor de` is `to favour
  of`, `desleales` `disloyals`, `efectuadas` `effected`). **English writes a
  number in its own style** between itself and a language of the decimal
  comma (`tr_decimal_comma/1`: `5.000 millones` is `5,000 million`, `3,5` is
  `3.5`, `10.30` an hour stays; the reader notes the text's style in
  `$tr_numsrc`, the writer swaps the marks of a NUMBER only, and two such
  languages keep their digits), a magnitude after a count singular with no
  `of` (`tres millones de perros` is `three million dogs`), no article before
  a percentage, the adverbs of time and focus before the verb (`also`,
  `always`, `never`: `en_mid_adverb/1`; after a copula or a modal that stands
  alone, in the tail of a question) and `more than`, `about`, `only` before
  the phrase they say how much of (`en_object_adverb/1`). A word with two
  meanings that no SHAPE chooses between still has one: `justamente` is
  justly before an adjective or a participle (`The adjectival adverb
  "justamente" means "justly".`) and precisely elsewhere, as `supone` is
  supposes before `que`; **a meaning the lesson gives a class of its own
  (`intransitive`, `progressive`, `clausal`, `adjectival`) is linked to the
  word's class too, in the order it is said, so the plain meaning is said
  first (again), or the class's meaning becomes the default**
  (`tr_mean_links/3`).
  The Makula interview (VIT-9381..9414, Italian into Spanish: 34 of 34 on a
  fresh store, 16 of 34 before; into English 26 of 34, 15 before) leaves: `per tirar su
  una persona che sta per annegare` is `estirar en una persona que está para
  ahogar`; `fuori dall'acqua` is `fuera desde el agua`; `che ti possa salvare`
  after a negation is `que te puede salvar` (the relative clause's
  subjunctive); `sia stata colta anche lei da sincope` is `la haya sido
  sorprendida también desde síncope`; `non conta nulla che dopo venga portata
  nel miglior ospedale al mondo` is `no cuenta nulo que es traída en el
  hospital mejor al mundo después`; `entro un minuto` is `antes de un minuto`;
  `anche`, `sicuramente` and `también` stand last where Spanish puts them
  after the verb; `Cos'altro le devo dire?` (what else) is REFUSED now -- the
  `¿Cosa debe otro decir?` it was had `otro` for a subject, and a question
  word with `altro` is a shape of its own (`qué más`); English refuses eight
  (4, 5, 7, 10, 11, 12, 27, 32), most for the third person nobody names,
  which it refuses on purpose. The angled marks come back mixed, an opening `«`
  and a closing `”` (`«Il cane dorme”, dice il gatto.`), in bytes and in
  characters alike (the cause is not looked for).
  The Hotel Arts auction (CESS-CAST-P-20011202-66, 17 sentences, Spanish into
  Italian: 15 of 17 on a fresh store, 6 before; into English 15 of 17, 5
  before; reasoning 1.0.1). It needed these SHAPES, each with its arm red:
  a one of a plural for a subject (`Uno de sus principales accionistas es La
  Caixa`: `uno` is the first person of `unir` too, `tr_part_of_subject/1`); a
  phrase with no article between two dashes after a noun or a name, a name
  with a bracket in it (`- - Strategic Hotel Capital (SHC) - -`), the closing
  dash that ends the sentence, a relative clause between dashes that ends it;
  who said so right after a bracket, and the relative clause after the
  comment taken into it (`(288,4 millones de euros), según informó ayer la
  agencia Efe, que cita fuentes`); an adjective before a date's day (`el
  pasado 11 de septiembre`) and the article chosen for the DAY (`dell'8
  settembre`, `del 1 settembre`); a silent h (`l'hotel`, `nell'hotel`,
  `l'ha`: Italian and Spanish only, English keeps `a hotel`); a list that a
  `between` opens keeps its commas together; a noun the lesson states in both
  genders is written in the gender of its meaning (`el capital` the money,
  `la capital` the city: `tr_meaning_gender/5`, the writer's half of
  `tr_gender_links/3`); an adjective after a name that stands right after its
  determiner is the name's (`la Barcelona olímpica`); a word that begins the
  purpose, straight before an infinitive and after a noun or an adjective, is
  no verb (`un solar apto para levantar otro hotel`); an adjective that does
  not agree with its noun in number keeps its own (`agrd/3`: `un espacio de
  oficinas anexo`, `fuentes del sector conocedoras`); a word the lesson says
  is a name is one with its capital inside a phrase (`el grupo inversor
  catalán Metrópolis`). It needed these WORDS in `extra/` (the two readers: a
  line moves the reader of one language and the writer of the other):
  `inmueble`/`immobile` (real estate), `hotelero`/`alberghiero`,
  `preacuerdo`/`preaccordo`, `fondo` (fund, not the background), `fuente`
  (source, not the fountain), `inversor`/`investitore`, `conocedor`, `cinco
  estrellas`, the masculine `capital`/`capitale` (share capital), `anexo`,
  `solar`/`terreno edificabile`, `apto`/`idoneo`, `aspira` (aspires),
  `empresaria`/`imprenditrice`, `sede` before `quartier`, `albergo`, `banca`
  before `argine`, `acquisto` before `spesa`, `edificio`, `gestione`,
  `filiale`, `passato` after its noun, and the two names `Hotel Arts` and
  `Metrópolis`. The CONTROLS (cocolog 1.13.6, store KB93, 89 count files, 2 050
  sentences): the last version's translator against this one, 24 sentences in
  8 files read differently -- 16 in the report's two files, and 8 elsewhere
  (carrefour 22 and 23, e_senegal 26, fiat 11 and 16, israel 15, mobile 9,
  senegal 23: an adjective agreeing with its noun, `gruppi d'acquisto
  spagnoli`, `forze di sicurezza palestinesi`; `l'hanno`; `del capitale più
  prezioso`; English `a competitive Senegal`), all better -- and the
  inferences fall 0.89 % (3 595 025 781
  to 3 563 106 210), 0.0056 % without the report's files; bytes and characters
  read every sentence alike (0 differ, the characters 0.024 % fewer). **The
  binaries of 1.13.3 and 1.13.6 give the same texts and the same inference
  counts to the unit on both translators** (1.13.4's catch/3 frame, 1.13.5's
  `=/2`, 1.13.6's names changed nothing the translator counts). The report's
  tenth sentence costs what it did, 119.9 million inferences to its refusal
  (119.1 for the last version); an alternative that let a comma follow the
  closing dash made it 42.0 and was taken out, below. The DATA COLUMN (the
  last version's translator on its own store, KB86, against this one on the
  new): 51 sentences in 20 files, 27 outside the report's, each a word of the
  report's lines said first -- `fuentes` are sources (5 English sentences, not
  fountains), `fondo` is a fund (4: e_clinton 5 and 12, e_lotr 4, e_mobile 3),
  `acquisto`/`d'acquisto` (3 and the purchasing groups of carrefour), `passato`
  after its noun (clot 6, puigbo 4 and 7), `empresaria` (letter 3), `capital`
  (e_fiat 5 and 16) -- and the 8 of the code. THE STATED COSTS: eco 11,
  `Ma immobile non voleva dire piatta`, was `inmóvil` and is `inmueble` (and
  English `real estate`): the line that makes `immobile` the noun the report
  writes makes a bare `immobile` the noun in the reader as well -- a bare word
  is read as a noun where the lesson has one, and the adjective said first
  (the dictionary's own, `motionless`) was tried and changes nothing; and the
  masculine `capital` is `share capital` in English. **A comma right after the
  closing dash is NOT let through** (the guard's sentence, B6): the first cut
  took `- -,` and the Spanish store read `el fondo - - Strategic - -, aliado
  con un consorcio, duerme` as a piece with no verb and `duerme` its
  imperative -- `dormi` -- where the last version refused it; no hand lesson
  reproduces it (it has no imperative), the guard pins the refusal. The
  report LEAVES: sentence 10 (`el fondo participado por Prudential y
  Goldman Sachs - - Strategic Hotel Capital (SHC) - -, aliado con un
  consorcio español integrado por ... Metrópolis (en el que participa la
  familia Lara, propietaria del grupo editorial Planeta)`), refused: a dashed
  aside followed by an adjective or a participle phrase, with or without the
  comma, is no noun phrase (`tr_np/3` takes an aside token only last, and the
  gloss clause for a bracket before an adjective would write the name between
  the participle and its complement; the aside after it, `app(app(NP,
  dashed, N), aside, Comps)`, is the shape to build), and a bracket after a
  name that opens on a relative clause loses its marks (`Metrópolis in cui
  partecipa la famiglia Lara proprietaria del gruppo editoriale Pianeta`,
  where `Planeta` is a name and is written as the planet); sentence 14 is a
  defect of the source, two of its four dashes are lost (`en España - - más
  de 80.000 millones de pesetas (...) a finales de 1998 como al valor
  contable de los activos 68.700 millones (...) - -`) and no reading puts
  them back. Of the 15 it reads, what is not right: `Londres` stays (a
  capitalised word the lesson knows after a preposition is a name, and there
  is no city by the vocabulary; `in Londres` is `a Londra`), `in Stati Uniti`
  is `negli Stati Uniti` (a country keeps its article in Italian), `cambiar
  de propietario` is `cambierà di proprietario` (Italian says `cambierà
  proprietario`) and `comprar a` writes `al gruppo` (`dal`), `uno de los
  mayores` after `banco` is `uno dei maggiori` where `banca` is feminine (the
  gender of an elided `uno` follows the noun the sentence names, which the
  lesson does not carry), `otro hotel` after a verb is `altro albergo` (`un
  altro`), `terreno inmobiliario` is `terreno immobiliare` (`campo`), a
  relative clause between dashes in a subject writes the pronoun again in
  English (`that they house`), `anexas` after a plural subject is read as a
  verb form (`Las galerías anexas son grandes` is `Le gallerie attaccano sono
  grandi`), `una casa de Pedro cansada duerme` is refused, and a weekday
  before a date's day in front of the clause (`El jueves 9 de marzo el hotel
  cambió de dueño`) is written after the clause with the day and no article
  (`... 9 marzo giovedì`).
  The Tempi del governo report (VIT-9673..9712, 40 sentences, Italian into
  Spanish: 39 of 40 on a fresh store, 28 with the new store alone, 13 before;
  into English 36 of 40, 25 and 11; reasoning 1.0.2). It needed these SHAPES,
  each with its arm red (test/translate.pl's `newspaper_tempi`: 60 checks, 48
  arms; a guard stays only where its arm goes red, and the guards of the
  reporting clause before a colon and of the perfect cleft had none): a name
  the lesson states, before a comma, takes no comma into its run of words
  (`dei cristiano democratici Casini, Mastella, D'Onofrio e del popolare
  Sanza`: `tr_stated_run` asked each word through `forall(member(w(X, C),
  Run), ...)`, whose pattern a comma does not match, so the comma was never
  asked); a capital `D'` before a capitalised word is a surname's particle
  (`Massimo D'Alema`, `Tommaso D'Aquino`, `tr_elision_names0/2`; the small
  `d'` is the preposition still, `il governo d'Alema`); two names with a dash
  between them after a noun are one name (`colloquio Berlusconi - D'Alema`,
  `tr_dash_names/3`), and a bare noun and a name are a heading; a
  demonstrative and an article at the head of a piece have their copula read
  in (`Questo il testo del documento`, `tr_demonstrative_copula/3`; a
  demonstrative that a verb follows is the subject); a quotation right after a
  verb of saying, with no mark between them, is what the verb says (`il Polo
  ha risposto "vedo"`); the word for `all` before a bare singular noun is one
  phrase with it (`con tutta evidenza`, `tr_np/3`; before an article it is the
  pronoun, as it was); a noun that is the first person of a verb, before
  `che`, starts a clause (`credo che stavolta ...`, `tr_first_person_that/2`);
  a day opens the clause of `quando` (`tr_nested_front/3`), `quando` is no
  adjective of the day after it (`tr_adj_word/2`), and an adverb right before
  `quando`, or before the `o` of an either-or, leads the sentence in; a
  heading of bare nouns in a list (`Forzatura, distinguo e bacchettata.`,
  `tr_bare_title/3`; two nouns joined by `e` are no list); among nouns that
  are adjectives too, the one that has a plural to be heads a phrase that a
  plural numeral opens (`due sole alternative`, `tr_plural_hint/4`); an adverb
  between the auxiliary and its participle keeps a perfect infinitive (`di non
  aver affatto abbracciato`), and `già` is an adverb of degree before a
  participle; a day and a phrase that names, the verb left out (`Martedì tutti
  attorno al tavolo.`); a bare noun and an adjective with its intensifier
  (`Mediazione particolarmente faticosa se ...`, which joins the clause after
  it, `tr_join_left/5`; `Big house.` stays refused); a plural noun and its
  phrase of `of`, at the head of a piece with no other verb (`Sviluppi delle
  trattative in atto ...`, `tr_noun_heading_start/1`: `sviluppi` is a command
  too); a verb of two words with an adverb between them (`risente invece del
  punto di vista`, `tr_multi/2`; before an infinitive `invece di` is the
  preposition); a verb of saying and its speaker before the colon are the
  reporting clause (`Spiega il popolare Sanza: "..."`, `tr_colon_left/4`), and
  a quotation that closes at the first comma with only a reporting clause
  after it divides before it is read whole; a phrase that is not `of`, after a
  participle with no adjunct of its own, is the participle's (`Il Comunicato
  diramato dopo quasi tre ore`, `tr_participle_adjunct/4`); a verb of several
  words is shaped by its first (`gives credence to` for `accredita`,
  `tr_phrasal_shaped/1`); the word for `all` before the shape of a phrase has
  its shape (`Tutti gli altri hanno perplessità`, `tr_subject_shape/4`);
  `anche`, `persino` and `solo` before the subject are said of it (`Anche
  Gianni Letta ha parlato` is `También Gianni Letta ...`, where it was `... ha
  hablado también`), English keeping `even` in front and writing `also` with
  the verb, never `Also the dog sleeps` (`en_subject_adverb/4`: the controls
  found six such sentences); never a word that is a preposition too
  (`tr_focus_front/1`: `hasta` is `until` before it is `even`, and `Hasta
  entonces el perro duerme`, the radio section's guard, was red in the whole
  case only -- the adverb `entonces` lifted out of the words left `hasta el
  perro` to read as `even the dog`, which no section of the new report could
  see; its arm is that guard); a cleft whose infinitive is in the perfect (`è
  il solo Segni ad aver sposato questa opzione`), `solo` before the name of a
  cleft (`tr_cleft_who/4`), an article before a perfect infinitive (`l'aver
  ceduto`); a verb of beginning with an infinitive after it takes `has` for
  its perfect (`ha iniziato a raccogliere`, `tr_beginning_verb/1` in the
  writer: the lesson's `"è" is the auxiliary of "inizia".`, which `È iniziato
  il vertice` needs, had made it `è iniziato a raccogliere`, carrefour 7);
  `più` in a denied clause is English `anymore`, written last (`Non ci sarà
  più spazio per i bluff`, `Non la ricorda più nessuno`); `si fa` before an
  adjective is English `becomes`; and `solo che` is `only that`.
  It needed these WORDS in `extra/` (the two readers: a line moves the reader
  of one language and the writer of the other; where a word must stay the one
  written, the dictionary's own line is said again first -- Italian `emette`,
  `teme`, `distinzione`, `ritorna`, `amministra`, `unisce`, `riflette`,
  `episodio`, `ammonimento`, `convenzionale` and `superficiale`, Spanish
  `linterna`): `dirama` (issues, and its participles), `paventa` (fears),
  `distinguo`, `vertice` (a summit, not the peak), `rimette` (gives back),
  `bacchettata`, `puntata`, `stavolta`, `decina`, `oppure`, `eppure`, `melina`
  (stalling), `bluff` (a poker bluff; Spanish `farol`), `leghista` and `par
  condicio` (kept as they are), `dita` (the feminine plural of `dito`),
  `accredita` (gives credence to), `risente di` (reflects), `scosta` and
  `apparta` (moves aside), `aggrega` (joins), `affatto`, `va in scena` (takes
  place), the adverbs, prepositions and adjectives of several words (`l'altro
  ieri`, `subito dopo`, `ogni giorno`, `per strada`, `da una parte`, `da
  l'altra parte`, `attorno a`, `in atto`, `di destra`, `di maniera`, `a doppio
  turno`; Spanish `anteayer`, `justo después de`, `por el camino`, `por la
  otra parte`, `alrededor de`, `en absoluto`, `en curso`, `de derechas`, `a
  doble vuelta`), `cristiano democratico` and `cristianodemócrata`, `centro
  destra` and `centroderecha`, `solo che` and `sólo que`, the auxiliaries of
  `inizia` and `comincia` (the copula), `o` and `ad` that begin a choice and a
  cleft, `popolare` a title, and the names `Fini`, `Polo`, `Olivo`, `Massimo`,
  `Letta`, `Segni`, `Bianco` and `Casini`; and in the two dictionaries' extras
  `matchstick` (`fiammifero` first both ways, `cerino` read only, `cerilla`
  left to right only), `short`/`corto` and `issue`/`questione` (both ways),
  `burn`/`scottare`, `forcing`, `promulgate`/`varare`, `presidentialism`,
  `attainment`, `sensation`, `stalling`/`dilación`, and the adjectives
  `punitive`, `unconstitutional`, `laborious`, `distrustful`, `constituent`
  and `Berlusconian`.
  The CONTROLS (cocolog 1.15.0, store KB107, 93 count files, 2 198 sentences):
  the last version's translator against this one, 21 sentences in 20 files
  outside the three newest reports (this one, the Makula interview and the
  Hotel Arts) read differently (carrefour 7, cecchi 7, eco 21 and 26, fregene
  10, giglio 6, livata 8, lotr 11, montanelli 20 and 28, salvini 9, senegal 1
  and 6, tat 4, twelve 9, valencia 3: the focus adverb before the subject,
  `D'Aquino`, `ha iniziato`, `scosta`, `anymore`, `become`, `give credence
  to`, one that failed and reads), all better -- and the inferences fall 5.148
  % (4 484 481 501 to 4 253 601 294), 0.278 % outside those three (3 221 894
  127 to 3 212 933 629), and 43.0 % in the Hotel Arts report's two files,
  whose tenth sentence is refused after 46.6 million inferences where it took
  120.0 (not looked for); the file that rises most is solana's, +2.5 % of 15
  million. Bytes and characters read every sentence alike (0 differ, the
  characters 0.021 % fewer). The binaries of 1.13.7 and 1.15.0 give the same
  texts and the same inference counts to the unit on both translators
  (1.14.0's shifts and 1.15.0's clock and error names changed nothing the
  translator counts). The DATA COLUMN (the last version's translator on its
  own store, KB93, against this one on the new): 32 sentences in 21 files
  outside those three, each a word of the report's lines or a shape of its
  code -- the focus adverb before the subject (8: eco 26, fregene 10, giglio
  6, montanelli 20, salvini 9, senegal 1, valencia 3 and the English of
  valencia 3), `subito dopo` (4: eco 6 and twelve 8, in both languages), and
  by twos `vertice` (cecchi 21: `cumbres`), `da l'altra parte` (eco 19),
  `D'Aquino` (eco 21), `scosta` (lotr 11), `give credence to` (twelve 9) and
  the place of `certainly` (livata 8), and one each `Marco Polo` (astro 4),
  `anymore` (montanelli 28), `become` (senegal 6), `el asunto` for the issue
  (eco 15), `en torno` (fregene 19), `Move aside` (tat 4), `por` for `per
  strada` (livata 15) and a comma (cecchi 7). THE STATED COST: eco 6, `Salvo
  che subito dopo i due dialoganti hanno osservato che erano state perdute
  ...`, was `los dos dialogantes han observado inmediatamente después que` and
  is `han observado justo después de los dos dialogantes que` (English `have
  observed right after the two dialoguing ones that`): `subito dopo` is the
  adverb there, and the line that makes it a preposition, which `subito dopo
  la fine del vertice` needs, takes the two interlocutors for its object and
  leaves the verb a subject nobody names; the sentence costs 1.08 million
  inferences and now 1.31.
  Written, found to move no sentence of the controls and no check, and taken
  out (each hunk reversed over the full controls): the `fo_np_number`
  alternative, a heading of a choice in `tr_verbless0`, `tr_skip_adverbs`, a
  first-person guard in `tr_conjunction_split`, an English writer clause for
  the connector `cmid/1`, `tr_time_adverb_comp/1` and a split of a quotation's
  number; a fix for English `"X", dice Y, "verb ..."` (refused) went the same
  way, no sentence reaches it. **A clause added to `tr_read0` costs about five
  inferences a call before its first test fails**, so the first cut of the
  shapes cost +0.54 % outside the new reports; what paid was a memo for
  `tr_focus_adverb/1`, the selective test first in `tr_complements0/4` (the
  article before a perfect infinitive) and the question words of
  `tr_adj_word/2` folded into the test they were added to. The report LEAVES:
  sentence 20 (the communiqué's second quotation, `"al tavolo non può trovare
  spazio", prosegue il comunicato, "l'individuazione della maggioranza ... e
  men che meno la durata del medesimo, essendo compito esclusivo del
  parlamento, ..., fornire al capo dello stato tutti gli elementi ..."`),
  which runs to the limit of 300 million inferences in both languages, as it
  did at the start (22 s); and English refuses 17, 31 and 39, the third person
  nobody names, on purpose. Of the 39 it reads into Spanish, what is not
  right: a predicate after a heading takes the heading's gender (`Melina tra
  Polo e Olivo e il voto è più vicino` is `Dilación ... el voto es más
  cercana`); `a Montecitorio` and `al tavolo` keep their `a` (`en`), `sul
  conflitto` is `en el conflicto` (`sobre`) and `varare in parlamento sugli
  stessi argomenti norme punitive` is `promulgar en parlamento en los mismos
  normas argumentos punitivos`; `sia andato in scena un classico` is `ha
  tenido lugar a un clásico` (the subject after the verb has an `a`); `quando
  ... torneranno` keeps the future (`cuando ... regresarán`, where Spanish
  wants the subjunctive) and `convinto che` is `convencido que` (`de que`);
  the time adverbs stand last (`l'altro ieri` in 12, `ieri` in 13, `Ora` in
  36); `non lasciano ben sperare` crosses word by word; sentence 16's list of
  names loses its order (`dei cristiano democratici Casini, Mastella,
  D'Onofrio e del popolare Sanza` is `de los cristianodemócratas Casini para
  simplicidad, a Mastella, D'Onofrio y Sanza`, with `del popolare` left behind
  as `del poblar`, the verb, and English `Casino`), `sposare` is `casar` and a
  quotation inside a quotation leaves a stray mark; `da una parte ...
  dall'altra` is `por la otra por una parte`; `un alleato come segni` is `como
  signos` (a name written small); `senza par condicio niente elezioni` is `sin
  par condicio nada elecciones`; `parla invece di Mario` is `habla en vez de
  Mario` (`invece di` the preposition, the verb being `parla di`); `Hasta mi
  mamá lo sabe` stays `My mum knows him even` (`tr_focus_front/1` leaves out a
  word that is a preposition too; to have both, `tr_adverbs_off/4` would keep
  a preposition's adverb, where it lifts `entonces` out of `hasta entonces`
  and leaves `hasta` bare). English: `spazio` is `blank` (`no blank for the
  poker bluffs anymore`), `incontrarsi` is `find` (`return to find tuesday`),
  `elezioni` were `choices` (settled by the Tatarella interview below), a
  relative clause with no subject of its own
  writes `they` (`an interview in which they clarified`) and `a quell'ora`
  stands last (`to that hour`).
  The PSOE and PNV report (AnCora CESS-CAST-P-20000903-30, 21 sentences,
  Spanish into Italian and English: 21 of 21 and 18 of 21 on a fresh store, 17
  and 14 with the new store alone, 8 and 7 before; reasoning 1.0.3). It needed
  these SHAPES, each with its arm red (test/translate.pl's `newspaper_psoe`: 38
  checks, 21 arms): a pronoun joined to the infinitive after the word for
  `upon` (`al reclamarle que mantenga ...`: the clause is `upon(cl(L, Cls),
  Cs)`, and `tr_cross_comp/2` and both writers know it -- Italian puts the
  pronoun on the gerund, `chiedendogli`, English after it, `on demanding him`;
  four arms, the reader, the cross and each writer) and an `upon` clause that
  reads to no comma is read whole (`fue más lejos al precisar que esa actitud,
  "que no tuvo el PP en su día", es la que ...`: the first comma is the
  apposition's, `tr_upon_rest/5`); a verb of saying takes a person and then a
  clause whether or not the lesson says it takes the clause (`replicó a
  Ibarretxe que ...`: `tr_person_words/3` asks `tr_saying_verb/1`), `retorts`,
  `demands`, `asks`, `requests` and `urges` being verbs of saying to English
  (`en_saying/1`, which the Spanish reader asks as well); the clause after a
  person may open on a pronoun of its verb, on a conjunction of its own or on
  a phrase set in front of its subject (`avisó a Ibarretxe de que a su Gobierno
  el tiempo se le acaba`, `tr_clause_after_person/1`); English `bets on` and
  `distances from` (`en_governs/2`); an insertion with an adjective phrase and
  no verb (`Zapatero, aunque fiel a su consigna de no arremeter contra el PP,
  sí se permitió ...`, the fragment a headline is) and what stands between its
  closing comma and the verb, adverbs, which become the clause's complements,
  and pronouns, which stay with the subject's side (`tr_insertion_off/4`,
  `tr_insertion_tail/3`); `fue` is the preterite of `ser`, not of `ir`, when
  nothing goes (`fue una equivocación`, `ayer fue ...`: `tr_ser_not_ir/4`,
  asked in the clause that takes its subject after the verb and in the
  fronted inversion; with a place or a phrase of `to` after the traveller it
  is the verb that goes); the word for `that` after a verb of saying is no
  `than` (`fue más lejos al precisar que esa actitud ...`:
  `tr_compared_before/2` takes the `que` it is asked about by the words that
  follow it and not the first of the piece, looks back no further than the
  `que` before it, and asks `tr_that_follows_saying/2` -- three arms, and the
  one for the place is a relative `que` and then a real comparison, `La casa
  que duerme es más grande que el perro`, which the controls broke in two
  sentences without it, mobile 7 and salvini 28); a copula reports nothing
  (`La casa, que compró Pedro, es la mejor` has no comment at its end,
  `tr_reporting/3`: football 10 falls 42 % and cecchi 24 2 % for it, the
  clause of who said so no longer read for a copula); a verb among the words
  before a phrase set in front of the pronoun that takes it up again makes
  them a clause of their own (`Dijo que el perro lo come`, which the cut after
  the dislocation's condition refused, `tr_read_statement0/4`; the cost
  below); and the tonic `sí`, which the lesson says never precedes the verb,
  is an adverb before it (`Pedro sí duerme`, `tr_clitic/2`).
  It needed these WORDS in `extra/` (the dictionary's own word said again first
  where it must stay the one written: Spanish `acuerda`, Italian `chiede` asks
  before it demands): Italian `discorso` (a speech, not an address), `al
  momento di`, `chiude la porta`, `come si evince da`, `chiede` (demands, and
  takes the clause), `concorda` (before the dictionary's `accorda`), `auspica
  di`, `punta` (bets, `su`), `distanzia` (`da`), `critica velata`, and in
  eng-ita.dix `distanziare`, `antiterrorista`, `schizzinoso`, `tessere`,
  `disposto`, `potenziare`, `sabotare` for torpedo, `errore`, `sottolineare` and
  `confronto` (written only); Spanish `a la hora de`, `avisa` (the clause and
  `de`), `velada crítica`, `conviene` (suits, and the clausal agrees with
  `en`), `según se desprende de`, `da portazo`, `aboga` (`por`), `apuesta`
  (`por`), `distancia` (`de`), `confrontación`, the name `Mayor Oreja`, and in
  eng-spa.dix `distanciar`, `antiterrorista`, `remilgado`, `torpedear`, `tejer`
  and, read only, `arremeter`, `tremendismo`, `recomponer`, `espetar`, `senda`,
  `crispación`, `consigna`, `precisar` (specifies), `trasladar` (conveys) and
  `potenciar`. The first word moved in 7 Italian and 4 Spanish meanings
  (speech, agrees, bets, boosts, demands, distances and weaves in Italian;
  boosts, conveys, rebuilds and weaves in Spanish), and the first meaning of
  5 Spanish words and 1 Italian word moved too (`confrontación`, `potencia`,
  `precisa`, `teje`, `traslada`; `tesse`).
  The CONTROLS (cocolog 2.0.0, store KB116, 95 count files, 2 240 sentences:
  every earlier article, Tatoeba's 400 and the new report, both directions):
  the last version's translator against this one, on the one store, 4
  sentences in 2 files read differently (clot 14 in English, `bets on` for
  `bets for`; tat 69, 222 and 278, `fue` as was and not went: `Tom was`, `It was
  your idea`), all better -- and the inferences fall 1.273 % (4 574 388 857 to
  4 516 160 393), 0.0007 % outside the new report (4 253 642 195 to 4 253 610
  973, the Hotel Arts report in), that report's two files rising 0.012 %. The
  file that rises most is senegal's, +1.5 % of 123 million (its second
  sentence, below), and the one that falls most football's, -1.2 % (its tenth,
  a copula that reported). Bytes and characters read every sentence alike (0
  differ, the bytes 0.021 % more). The DATA COLUMN (the last version's
  translator on its own store, KB107, against this one on the new): 14
  sentences in 6 files, each a word of the report's lines: `reclamar` is
  `chiedere` (abogacia 1, basque 3, carrefour 4, 5, 6, 14 and 20, clot 20,
  football 13: `reclamò` is `chiese`, and the clause after it is in the
  subjunctive now, `chiese che il Tribunale ... intervenga`), `scommette per`
  is `punta su` (clot 14, and English `bets on`), and the three of `fue` above.
  THE STATED COSTS: `precisar` is `specifies` before it is `requires` and
  `trasladar` `conveys` before it is `moves` -- the dictionary's lines marked
  for reading come first, and the article needs both (`al precisar que`,
  `trasladará al lehendakari la posición del PSOE`) -- so `La empresa precisa
  más tiempo` is `L'impresa specifica più tempo` and a man `trasladado` to a
  hospital is conveyed: no sentence of the controls has either, and a lead;
  and the dislocation's own cost, FOUND BY TAKING EACH RULE OUT (the fourteen
  heaviest sentences counted over a copy of the library per rule, two seconds a
  copy): the first cut, the cut moved after the subject read, cost +21.1 million
  inferences outside the new report and the Hotel Arts one (+0.52 %), all of it
  in four sentences (eco 15, 22 and 25, senegal 2). When the words before the phrase read as no
  subject the clause failed with the condition's choices kept, and the long
  front was parsed again at every other determiner (eco 25: 2.8 million), and
  the clauses after it were asked of sentences none of them reads (eco 22,
  `Che poi queste cose le sapessero i dotti ...`, whose `che poi` has no verb:
  2.5 million). The first front is taken once now (`once/1`, as the cut did),
  and the cut stays unless a verb stands among the words before the phrase.
  What is left is eco 15 and senegal 2, 1.7 million inferences each (a 42 % and
  a 7 % rise of the sentence), where the words hold a verb and read as no
  subject and the clauses after the dislocation are asked and read neither.
  Written and taken out: a test that the words before the phrase end on `que`
  after a clause (free of cost, and it fixed `Dijo que el perro lo come`, but
  sentence 20's words end on `a`: `avisó a Ibarretxe de que a su Gobierno ...`);
  the pronoun's agreement asked before the subject (the cost did not move); and
  the soft failure for any unreadable subject (+0.14 %, eco 22's `che poi`). **An arm
  that makes the section RAISE is red with no FAIL line** (the English writer's
  clause for `upon(cl(...))` taken out: a `type_error` out of reason_translate/4
  ends the section) -- the arm driver counts `ERROR` lines and reads the last
  line, `GREEN` or `RED`. The report LEAVES, of the 21 into Italian:
  `partido` is the match before it is the party (`tutte le partite democratiche`,
  `la sua partita`); the quotation `se "digan las cosas claras"` loses its
  opening mark (8); in 5, `di non d'assalire contro il PP` (a second `di`,
  elided, before the infinitive), `si permise fare` (no `di` before the
  infinitive of `permitirse`) and the comma after the insertion lost;
  `avvertì a Ibarretxe` (Italian says `avvertì Ibarretxe`) and English `warned
  to`; `de haber sido votado` is `d'avere stato votato` (the perfect passive
  infinitive); `dispuestos a buscar` is `avuti a cercare` (the participle of
  `dispone`, which has); `fue más lejos` is `fu più lontano` (went further:
  the copula); `sí` is written last (`non contribuisce ... sì`); `se le acaba`
  is `si gli finisce` (the idiom is `gli si sta esaurendo`); `digan` and
  `gobierne` in a clause of `que` are written in the indicative; `unidad de fondo
  sólidamente arraigada` keeps its Spanish between marks; `senda` is `traiettoria`
  and English writes `cuidadoso` as `accurate` (12: `showed very accurate`),
  `aboga` as `advocate` (2: `Advocate to weave a solid unit and of fund`) and
  `warned to Ibarretxe` (20); English refuses 5, 11 and 13 for the third person
  nobody names, on purpose (`aunque ... sí se permitió ... al reclamarle que
  mantenga`; `espetó al presidente que es la hora de que "gobierne"`; `Anunció
  que trasladará al lehendakari ... pero evitó`).
  The Tatarella interview (VIT-9714..9749, 36 sentences, Italian into Spanish
  and English: 36 of 36 and 36 of 36 on a fresh store, 25 and 25 with the new
  store alone, 16 and 16 before; reasoning 1.0.4). It needed these
  SHAPES, each with its arm red (test/translate.pl's `newspaper_tatarella`: 34
  checks, 19 arms and 5 guards, each guard red when its rule is made too wide): a
  pronoun and a phrase of `of` for a subject (`qualcuno di voi sta giocando con
  carte truccate`: `qualcuno` is a pronoun and no determiner, as `nessuno`,
  `uno` and `alcuni` are, and the subject shape wanted a noun, a name or a
  determiner, `tr_subject_shape/4`'s last alternative); THE PLURAL OF `YOU`,
  which the IR never had outside a subject (`Hablo de tú`, `te acusa`, `ninguno
  de tú`, the lead of the Abogacía report): a word of the IR where it is no
  subject, `you all`, made by `tr_pronoun_across/6` for a pronoun the lesson
  says is the plural of one that means `you` (`tr_plural_you/1`: `"voi" is the
  plural of "tu"`, `"vi" is the plural of "ti"`, Spanish `vosotros` and `os`, in
  corpus/extra), written `you` by English and as the plural of the pronoun the
  role takes by the lesson's language (`voi`, `vi`), the reflexive of a plural
  subject (`voi vi lavate`, `tr_personal_object/3`) and the plural subject
  itself (`voi direte elezioni`, `tr_subject_pronoun/4`) following it -- six
  arms; a question is no command (`Sembra poco?` has the spelling of an
  imperative, whose clause took the sentence and, its cut kept every other
  reading from it, left the question refused, `tr_read/4`); a clause of `that`
  and nothing else is a fragment (`che è stato un incidente di percorso`, the
  line after `diciamo che ...`, `tr_that_fragment/4`: asked for the WHOLE piece
  after every other reading, because as a clause of `tr_read0/4` it took the
  first half of eco's `Che poi il cane dorma, guardate che ...` apart and the
  whole case found it) and one left open (`diciamo che ...`, `that_open/0`); a
  name before a colon is a heading (`Tatarella: i trucchi sono vietati`,
  `tr_heading_left/3`); a participle and an infinitive with no subject are said
  of the infinitive (`con un patto: vietato truccare` took the gender of the
  table before the colon, `prohibida amañar`, `tr_gap_comps_out/3`); an article
  and a possessive before a noun that is a participle too are no reduced
  relative (`la loro proposta` was `el ellos propuesta`, `tr_np/3`: asked after
  the participle test, before it +0.8 % of the heaviest sentences); which with
  a verb of the first or the second person asks for its object (`Quale libro
  leggi?`, `fo_question_word/3`); a word the lesson gives `what` asks with the
  phrase after it as `quale` does (`e che colpa ha se la loro proposta è
  interpretata ...?` is which fault; `tr_which_asks/2`), with a NOUN OR AN
  ADJECTIVE at the head of the phrase and no determiner -- `cosa le posso dire?`
  has `le` for the clause's own, and the first cut, any phrase word, refused
  sentence 3 of the article and no sentence of the 18 probed with `cosa` showed
  it (the re-run of the article did; the guard is `cosa il cane vede?`); two
  questions with a comma between them (`e perché mai, e chi lo dice?`,
  `tr_question_half/2`); a question with no mark, a comma and a statement
  (`cosa le posso dire, sarà stato un equivoco`: the question half is marked
  `qh/1`, and the join writes it as a question -- the first cut wrote any join
  whose first clause asked for something so, and Cecchi's `che, dicono a Raidue,
  è raggiante` became `what do they say`, the one text the controls found);
  `se e in che modo` opens an indirect question (`tr_indirect_word/3`); and THE
  FORM OF A COMMAND, which Italian's second person plural of the present
  indicative is (`aprite`, `guardate che ...`, `non pensate che ...`) and
  Spanish's present subjunctive its negative one (`no miréis`): the builder
  states a person for every tense of the second person plural now (Italian 9 798
  lines of `is the second person of` to 17 998, Spanish 14 775 to 27 435)
  except a form the language commands with (`cb_command_plural/3`), because
  stated a person too those five commands of the controls became `abrís`,
  `miráis` and `sois`, and the participle's feminine plural (`proibite`,
  `studiate`, `annegate`: the same spelling) made three headlines clauses --
  they are the statement only where the sentence says so: a plural `you` named
  at the head (`e voi rispondete col presidenzialismo`, whose group is the plural
  form's with the second person the pronoun gives it) or a form of `stare` with
  a gerund after it (`state proseguendo nel cosiddetto gioco del cerino`,
  `state attenti` stays the command), `tr_read_statement0/4`.
  It needed these WORDS in `extra/` (the dictionary's own word said again first
  where it must stay the one written: Italian `deputato` and `deputata` for the
  deputy `onorevole` is read as, `ipocrita` for the hypocrite `doppiogiochista`
  is read as, and the identity `"con il" is the contraction of "con il"` before
  `"col" is the contraction of "con il"`, so that `col` is read and the print
  writes `con il`): Italian `malafede`, `incidente di percorso`, `bacchetta`
  (rebukes), `aspetta al varco`, `dal momento che`, `perché mai`, `il giorno in
  cui`, `in che modo`, `se e in che modo`, `a tutela di`, `elezione` (an
  election first, the dictionary's choice second), `per l'ultima volta`, `voi`
  and `vi` (the plurals of `tu` and `ti`), and in eng-ita.dix `rig`, `intend`
  (read only), `trace`, `resign` (`dimettere`: the bilingual dictionary's
  `dimettire` is no word, and its thirty-six lines of forms are gone from the
  vocabulary), `bloc`, `hypocrite` and `deputy` (read only); Spanish `mala fe`,
  `vosotros` and `os`, `acecha` (lies in wait for, before threatens), `si y
  cómo`, `de forma realista`, `para la protección de`, `por última vez`, and in
  eng-spa.dix `rig` (`amañar`) and `hypocrite`. The first word moved in 2
  Italian meanings and 1 Spanish one (bloc is `schieramento` and no `bloc`,
  traces `traccia` and no `localizza`, rigs `amaña` and no `apareja`), the first
  meaning of 3 words moved (`elezione` is an election, `acecha` lies in wait,
  `amaña` rigs and no longer alters: that line is lost, as is Italian
  `localizza` = traces) and `hypocrite` moved too until `ipocrita` was said
  again: the read-only line for the word the text had was written first.
  The CONTROLS (cocolog 2.1.2, store KB126, 97 count files, 2 312 sentences:
  every earlier article, Tatoeba's 400 and the interview, both directions): the
  last version's translator against this one, on the one store, 31 sentences in
  5 files read differently -- 28 in the interview's two files, and 3 elsewhere
  (eco 16, `no creerte` is `no creeros`; fregene 30, `hablar con tú` is `con
  vosotros`; tat 346, refused before and `That Dios pays it to him` now), all
  better -- and the inferences fall 0.267 % (4 589 831 928 to 4 577 556 536),
  0.038 % more outside the interview (4 516 197 717 to 4 517 921 885, the Hotel
  Arts report in). The files rise 0.44 % at most (pacifist's, of 5 million; lotr's
  0.43 % of 71) and the one that falls most is eco's, -1.8 % (its twenty-third,
  5.3 million to 2.7: a question that was read as a command first). Cecchi 25,
  the one text the first cut changed (`what do they say`), reads as it did.
  Bytes and characters read every sentence alike (0 differ, the bytes 0.021 %
  more). The DATA COLUMN (the last version's translator on its own store, KB116,
  against this one on the new): 52 sentences in 8 files, 43 of them the
  interview's and 9 elsewhere -- `elezioni` are `elections` where the dictionary
  gave `choices` first (bovalino 12 and 14, tempi 38 and 40, wapo 3: English),
  the three of the code above, and tat 192 (`¿Por qué estáis enfadadas?`, `Why
  are you angered?`), which the store alone reads now: `estáis` is a person it
  states. The inferences fall 1.946 % (4 668 389 400 to 4 577 556 536), rise
  0.039 % outside the interview (4 516 160 393 to 4 517 921 885), and the
  interview's two files fall 61 % (76 million to 30 each) for the 40 sentences
  that refused after long searches. THE STORE ALONE COSTS NOTHING outside the
  interview (the last version's translator on the old store and on the new: 4 516
  160 393 to 4 516 197 717, +0.0008 %), though it states 8 200 lines of the
  second person plural more in Italian and 12 660 in Spanish, and that
  translator reads 25 and 25 of the interview's 36 on it. **A FIRST STORE WAS
  11.2 % DEARER FOR ONE LINE**: `The word "che" means "which".`, which first
  made `e che colpa abbiamo se ...` read, cost the last version's translator
  alone 4 978 433 218 inferences over the 95 files against 4 475 127 352, the
  six heaviest sentences 2.6 times (cecchi 8, with two `che`, 49.3 to 192.2
  million; cecchi 9, tempi 17, eco 8 and 22, letter 8 the others), found by
  teaching a store without each group of the new lines -- the second person
  lines, the phrases, the verbs and nouns, the plurals of `you`: nothing; this
  line: all of it -- and the line went out of the data and into the code
  (`tr_which_asks/2`, above). The binaries of 2.0.0 and 2.1.0 give the same
  counts to 48 inferences in 4.32 billion, and one text differs (fiat 6); those
  of 2.1.0 and 2.1.2 give the same counts and texts to the unit, on both
  translators and both stores (master moved to 2.1.2 while the controls ran, and
  they were taken again on it).
  THE STATED COSTS: `col` is read, and written `con il` (the writer takes the
  first contraction a lesson states, and the identity line first makes `col`
  read only; the seven sentences of the controls, Spanish into Italian, that
  came out `col` came back); a command stays a command -- `Siate`, `processate`, `guardate che ...`,
  `non pensate che ...`, `No miréis`, `State attenti`, which reads as the
  participle of `essere` as before -- and is a statement only after a plural
  `you` or as `stare` with a gerund; and the inferences, +0.038 % outside the
  interview. THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the sixteen
  heaviest sentences counted over a copy of the library per rule, on the new
  store): the first cut was +0.457 % of them over the last version's, and four
  rules were all of it -- the plural of `you` asked of every pronoun that is a
  subject (0.227 %), the two clauses of the command, each reading the piece's
  denial again (0.18 %), `that_open` (0.034 %, a lone `che` at the end of a piece
  read as other things first) and the possessive guard (0.009 %). The plural of
  `you` is asked of a pronoun that means `you` now (`E == you` before
  `tr_plural_you/1`), and the two commands are one clause with the form of the
  command asked first, before the pronoun's lexeme: +0.163 % of the sixteen, 0.096
  of it the clause's own reading of the denial (`tr_negation/4` walks the whole
  piece, in every clause of `tr_read_statement0/4`), and every text of the 2 312
  the same as the first cut's. Its cost outside the interview is a few
  sentences: e_eco 16 (+0.87 million of 6.5, a sentence English refuses, and the
  search that refuses is longer), lotr 11 (+0.25 of 31.7) and cecchi 8 (+0.18 of
  49.3), against eco 23's 2.65 million.
  The interview LEAVES, of the 36 into Spanish (English alike unless it says):
  `vi accusa di fare` is `os acusa hacer` and `accuses you to make` (7), and
  `nell'attesa di vedere` `en la espera ver` (11) -- after a pronoun or a phrase
  the infinitive loses its `di`, and nothing in a lesson says which verbs take
  one; `passa di mano` is `happens of hand` and `chi provoca` `al que provoca`
  (11); `ci siamo basati` is `nos hemos basado` (10), `ci siamo intesi` `nos
  hemos pretendido` and `il potere` `la fortaleza` (21, and `poteri forti` are
  `fortalezas fuertes`, 18), `il valore` is `la valentía` (24: `dandogli` is
  `dandole`, `pare proprio di no` `me parece justamente de no`), `registro` is
  `récord` and `buoni` `cupones` (13), `il confronto` `la comparación` (31),
  `fare i nomi` `hacer los nombres` (17); `Null'altro` is `Nada otros` and
  `nothing others` (25); `ci ha mai creduto` is `nos ha creído nunca` (27: the
  `ci` that stands for `in it`), and Spanish writes `sulle riforme` as `en las
  reformas` (English has `on`); `siamo disposti a` is `somos colocados a` (28), `crediamo al`
  `creemos al` (no `en el`) and `mettiamola` `Pongamosla` (no accent); `non hanno
  capito ancora cosa` keeps `cosa` as a noun at the end of its clause
  (`han entendido todavía cosa`, 29: the question word of an indirect question
  with nothing after it, unread) and `vogliono altro` is `quieren otros`;
  `se fossi in malafede` is `si estaba en mala fe` and `If I was` (12: the
  imperfect subjunctive is written as an indicative, as in the PSOE report),
  `Il giorno in cui Dini si dimetterà` `Cuando Dini se dimitirá` and `When Dini
  will resign` (33: Spanish wants the subjunctive after `cuando`, English the
  present); a passive `si` before the verb is lost in English (`il voto non si
  decide` is `the vote does not decide`, 32; `Le mele si mangiano` `The apples
  eat`; `Si possono fare le cose` `The things are caned make`; `che
  realisticamente si possono fare` `that realistically can make`, 15); English
  writes the clitic of a question as a thing (`what can I say her`, `who says
  him`, 3 and 6); Italian `te` is no word of the lesson (`Parlo di te` is refused,
  `Te lo dico io` is `I say it to You I`: the dictionary gives `ti` only);
  `state attenti` and `state grandi` read as the participle of `essere`, as
  before (`Cuidadosos han sido sido`); `acecharemos el Pds` has no `al`.
  The basketball report (AnCora CESS-CAST-P-20001201-176, 17 sentences, Spanish
  into Italian and English: 17 of 17 and 17 of 17 on a fresh store, 14 and 15
  with the new store alone, 10 and 7 with the new code on the old store, 9 and 6
  before; reasoning 1.0.6). It needed these SHAPES, each with its arm red
  (test/translate.pl's `newspaper_basket`: 34 checks, 21 arms and 7 guards, each
  guard red when its rule is made too wide; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM
  cocolog query "use_module('test/translate.pl'), newspaper_basket,
  checks_done"`, about a second a run): an adverb and a participle after a name
  are the clause's own (`Con Rimac excesivamente apagado en tareas ofensivas,
  fueron César Sanmartín y Jofresa los jugadores ...`:
  `tr_adverb_before_participle/3` asked for a noun at the end of the front, and
  the plural clause after it had no reading); an adjective straight after a name
  that `con` governs is an absolute phrase, at the head (`Con Rimac apagado,
  ...`, `tr_adjuncts_after/2`) and between commas (`los azulgranas, con Rentzias
  convaleciente, se vieron ...`, `tr_insertion_comps/1`, with `tr_means_with/1`)
  -- two arms; a modal and an infinitive with the reflexive joined, nobody
  named, is the impersonal `se` (`como podía esperarse de los dos equipos`,
  `tr_modal_se_fix/3`: English refused it and Italian wrote a second person,
  `come poteva aspettarsi`; the guard is a named subject, `Pedro puede
  esperarse`); a phrase a comma parts from the clause after it (`Un bloque de
  una tremenda consistencia, y los azulgranas ... se vieron obligados a un
  tremendo derroche`: the commas were taken out in two places and block and
  players were one plural subject -- `tr_comma_and_parted/2` stops both, and
  `tr_join_left/5` reads the phrase as a heading before `, y`; THREE arms, none
  green with another out, and two guards: a comma after the pair is an aside's,
  `El presidente, y los ministros, firmaron`, and the right side of a
  coordination after a statement is no fragment); the dative pronoun the phrase
  of `a` says again (`Pedro le dio un libro a María` gave María a book, `estuvo
  a punto de complicarle la vida al Joventut`: `tr_dative_double_fix/3`, three
  arms -- the pronoun before the verb, joined to an infinitive and after a
  preposition, `sin darle un libro al gato` -- and a guard, the phrase of `a`
  before any infinitive: `le permitiría dedicarse de lleno a Ona Catalana`
  allows HIM); what something costs somebody is the person and the price with no
  `to` (`le ha costado al club 75 millones`, a clause of `tr_comps_out/7` that
  asks for the price after the person; guards: the price before it, and no price
  at all, `Al Sud le università costano meno che al Nord`); an ordinal before a
  noun that is a noun too is its adjective (`el segundo cuarto`, `tr_noun/5`);
  the English plural of a demonym in `-ño` is `-ños` (`en_irregular_plural/2`);
  `prevails over` and `ousts from` (`en_governs/2`); two phrases after a copula
  with nobody named are what is and what it is (`Fueron César Sanmartín y
  Jofresa los jugadores que ...`, `tr_ident_fix/3`, a pair of names or a phrase
  with its article -- two arms -- and an indefinite phrase first keeps the old
  reading, a guard); an English verb of several words that ends in a preposition
  takes the gerund (`took charge OF CARRYING`, `tr_verb_ends_in_preposition/0`);
  a purpose governs the phrase after it (`para descabalgar a los malagueños del
  liderato`, `tr_governing_verb/3` looks at `purpose(IL)` too -- which also made
  Tatoeba's `per partecipare ... alle nozze` `to participate in the wedding`); a
  word the lesson says is NOT feminine beside a feminine one clashes in the
  person rule of `tr_noun/5` (`la directiva azulgrana` was `the managerial Barça
  player`: `azulgrana`, a Barça player, masculine though it ends in `a`, is
  stated "not feminine" and so has no gender of its own for
  `tr_genders_differ/2` to set against the feminine `directiva` --
  `tr_genders_clash/2` asks for the statement too); and the verb of knowing
  takes `how to` before the infinitive that stands first among its complements
  (`el Unicaja supo contrarrestar la apuesta` knew HOW TO, `tr_write/4` and
  `hinf/1`; `non so cosa fare` has the question word first and keeps its `to`, a
  guard).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Italian `tripla` (a
  three-pointer), `mordente` (hitting power), `blaugrana` (the players, and the
  adjective), `in procinto di`, `contrariamente a`, `spegne` (switches off), `si
  occupa` (takes charge of, with `di` before the infinitive and the phrase),
  `direttivo` (the board), `lascia partire` (releases), `si impone` (prevails,
  `a`), `overtime`, `tarda a` (takes long), `si riorganizza` (regroups),
  `protagonismo` (prominence), `compito` (a task), `leadership`, and `spodesta`
  taking `da`; Spanish `cuarto` (a quarter), `triple` (a three-pointer),
  `pegada`, `malagueño` (a person), `azulgrana` (a Barça player, not feminine, a
  person, and the adjective), `con mayúsculas` (magnificent), `a punto de` and
  `en contra de`, `pulso` (a duel, the pulse second), `apaga` (switches off),
  `se encarga` (takes charge of, `de`), `directiva` (the board), `deja marchar`,
  `se impone`, `equilibrio` (equilibrium), `tarda en`, `se rehace` (regroups --
  `recovers` is the other verb's, `recupera`, and a shared pivot made
  `recuperaron` unwritable in Italian), `protagonismo`, `descabalga` taking `de`
  and the name `Caja San Fernando`; and in the dictionaries' extras
  `tremendous`, `oust` (`spodestare`; `descabalgar` read only), `antagonistic`,
  `tie`, `pivot`, `quarter`/`quarto`, `victorious`, `rebound`, `tactical`,
  `alleged` (`presunto`, and `supuesto` too in Spanish), `expenditure`
  (`dispendio`, `derroche`), `dignify` (`engrandecer`, read only), `consecutive`
  (`seguido`, read only), `tone`, `overtime` (`prórroga`) and `contract`. The
  first word moved in 15 Spanish meanings and 4 Italian ones (`azulgrana`,
  `presunta`, `presunto`, `supuesta`, `supuesto`, `contrato`, `cuarto`,
  `derroche`, `directiva`, `equilibrio`, `protagonismo`, `prórroga`, `pulso`,
  `tono`, `apaga`; `presunta`, `presunto`, `tripla`, `spegne`), and none was
  lost.
  THE CONTROLS ARE A RECONSTRUCTION. The box was reset before this sample and
  the scratchpad with the 97 count files of the Tatarella round went with it:
  these are the 22 AnCora documents (CESS-CAST-P-19981202-34, 19990202-16,
  19990601-13 and 23, 19990701-130 and 83, 19990802-48, 19990901-75,
  19991001-61, 20000102-120, 20000701-80, 20000802-31, 20000903-30, 20010102-25,
  20010103-120 and 139, 20010202-169, 20011202-66, 20020102-112, 20020301-125,
  20020601-51 and 20020801-17, all in the dev file of UD's es_ancora), the 21
  VIT ranges of UD's it_vit test file (9270..9295, 9381..9414, 9450..9464,
  9465..9470, 9472..9484, 9540..9566, 9637..9672, 9673..9712, 9714..9749,
  9750..9762, 9763..9774, 9775..9780, 9781..9791, 9792..9799, 9800..9814,
  9816..9850, 9851..9925, 9926..9946, 9947..9966, 9967..9998, 10059..10095) and
  a Tatoeba-style 400 (Spanish sentences of 3 to 8 words of manythings' spa.txt,
  every (length/400)th): 1 264 lines, 88 count files (the Spanish ones into
  Italian and English, the Italian ones into Spanish and English), 2 528
  sentences, so no figure below compares with an earlier sample's, and the
  baseline is the committed library (reasoning 1.0.5) on a store taught from the
  committed vocabulary (it reads the Tatarella interview 36 of 36 into both, as
  sample 41 said). The next sample's controls take this report in. The CONTROLS
  (cocolog 2.2.5, store KB150): the last version's translator against this one,
  on the one store, 5 sentences in 3 files read differently (it_9637_9672 13,
  `The most numerous families are the struckest`; it_9800_9814 4, `to
  participate in the wedding` and `en la boda`; tat 291, `Algo le ha pasado a mi
  coche` is `Something has happened to my car` where the clitic had made the
  verb `spend`), all better -- and the inferences fall 0.063 % (4 689 505 132 to
  4 686 547 092). The file that rises most is es_20010103-120's, +0.1 % of 23.6
  million, and the ones that fall most es_19981202-34's, -8.7 % (its eighth, 3.5
  to 2.3 million), and es_19990601-13's, -3.6 %. Bytes and characters read every
  sentence alike (0 differ, the bytes 0.018 % more). The DATA COLUMN (the last
  version's translator on its own store, KB142, against this one on the new): 7
  sentences, the 5 above and 2 of the words, `liderazgo` as `la leadership`
  (es_20010102-25, Italian) and `se encargó de demostrarle` as `si occupò`
  (es_20020601-51, Italian); THE STORE ALONE costs +0.198 % of the inferences (4
  680 224 596 to 4 689 505 132), all of it the Tempi report's sentence 20, which
  runs to the inference limit in both stores (468.6 to 472.7 million), and the
  new code on the old store -0.063 %. THE FIRST CUT'S REGRESSIONS, found by the
  controls and read from the IR, not bisected (the guess,
  `tr_comma_and_parted/2`, never fires in them -- a probe on the sentence
  answered `no`): `... no es un punto de llegada, sino el inicio de una nueva
  etapa, y concluyó` and `acusó a Aznar de lanzar un "mensaje basado en la
  confrontación y la ausencia de diálogo", pero aseguró ...` (es_19990701-83 9,
  es_20000903-30 21) gained a `they`, because the fragment clause of
  `tr_join_left/5` took the right side of a `sino` or `y` division for a
  fragment and a clause and the last verb had nobody before it -- the right side
  of a coordination after a statement is read with `$tr_no_command` set, and the
  clause now stands down there; `le permitiría dedicarse de lleno a Ona
  Catalana` (es_19990701-130 6) lost its `le`, the infinitive's `a` taken for
  the pronoun's phrase; and the bare dative of `costs` turned `all'anno` (11),
  `al Nord` (27), `a Catania` and `al politecnico` (28) bare (it_9816_9850),
  which was the writer's clause for any phrase of `to` after the verb and is now
  the one with the price after it. THE STATED COSTS: a first meaning that serves
  the news and not every text -- `pulso` is a duel (the pulse is the second),
  `cuarto` a quarter (a room second), `contrato` a contract (an agreement
  second), `prórroga` overtime (an extension second), `apaga` and `spegne`
  switch off (extinguish second), `presunto` and `supuesto` alleged, `tono` a
  tone (a key second), `directiva` the board (a directive second),
  `protagonismo` prominence, `derroche` expenditure -- and the controls'
  sentences with them are the two of the data column above; and `non so cosa
  fare` is still `I do not know thing to make`. The report LEAVES, of the 17
  into English: `una sola concesión` is `an alone concession`, `ayer` stands
  last (1, 14), `todavía` after the names (4), `se vieron obligados` after a
  long insertion is `they saw obliged` with the subject written twice (4: the
  subject and an insertion of two phrases, pre-existing), `últimamente` stands
  last in its clause (5, `two antagonistic characters lately`), `entre` is
  `among` and `se emplearon` `employed` (5), `apuesta por la velocidad` is `bet
  for the speed` (6), `alzarse con la victoria` is `heave with the victory`
  (10), `complicarle la vida al Joventut` is `complicating the life to the
  Joventut` (11: the pronoun went, the phrase of `a` stayed), `acabara empatado
  a 72` is `tied to 72`, `llegó a un acuerdo` `arrived to an agreement` and
  `cantidad cercana a` `a near quantity to` (14), `expedientes` are `files`
  (16); Italian: `se emplearon` is `si impiegarono`, `efectivos` `effettive`,
  `esperarse de` `attendere delle` (`da`), `in quelli istanti` (`quegli`),
  `finiva pareggiata` (the subjunctive written as an indicative), `in Badalona`
  (`a`), `In altra partita` (`In un'altra`), `Quell'era` (`Quella era`), `fu il
  primo che` (`la prima`: the Spanish `equipo` is masculine and the Italian
  `squadra` is not) and `archivi` for `expedientes`; sentence 8 has no `con` in
  the source (`rehacerse, protagonismo de Digbeu y la eficacia de
  Jasikevicius`), and it is written as it stands.
  The Rosi report (VIT-9567..9604, 38 sentences, Italian into Spanish and
  English: 37 of 38 and 34 of 38 on a fresh store, 28 and 23 with the new store
  alone, 10 and 9 before; reasoning 1.0.7).
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_rosi`: 82 checks, 69 arms, 4 of them guards that go red when their
  rule is made too wide; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_rosi, checks_done"`, about a
  second a run, and every arm of this sample is run in a minute, four at a
  time): a piece in quotation marks from its first word to its last is a title
  the paper quotes (`"verdetto casareccio".`: a bare noun and its adjective
  begin no sentence, `tr_quoted_whole/1`, `tr_as_title/1`, tried after every
  other reading found nothing and for a piece of eight words at most, which is
  the cost: a refused sentence quoted whole was read twice, 473 and 18 million
  inferences more); a phrase of `to` before a city the lesson names, after a
  verb that does not go, is a phrase of `in` (`al termine del match ... a
  Perugia`, `tr_city_in/3`; a verb of going or bringing keeps its `to`,
  `tr_motion_verb/1`, a guard) and a name's particle is none before a city
  (`Ruggisce Rosi da Perugia` is Rosi roaring from Perugia,
  `tr_particle_names/4`); `roars` is a verb of saying to English
  (`en_saying/1`); a reporting clause between two dashes with a clause on each
  side (`sono l'unico ad aver consigliato l'Egibren - conferma Casotto - Rosi
  sapeva del farmaco`: a clause of `tr_read0/4`; the other readings find the
  same text 14 million inferences later, so no arm goes red and the clause
  stays for its cost, with its guard, that the right side opens on no
  preposition), a name between commas and the noun that says what he is, to the
  end of the piece with no verb (`Alessandro Casotto, medico di Rosi fino al
  match con Phillips`, a clause of `tr_list_commas/5`), and a name, a bare noun
  and what is added with no comma (`Rosi vittima quindi`, `tr_verbless0/3`); a
  word that begins the cause before a perfect infinitive says why (`Innocente,
  per aver assunto la sostanza` is innocent FOR HAVING taken it,
  `tr_complements0/4` and `tr_cause_word/1`; the group travels whole as
  `pinf(Word, perf(Lexeme, Pronouns))`, crossed by `tr_cross_comp/2` and
  written by two clauses of `tr_comp_out/7`, English `for having eaten`, the
  lesson's language its cause word, `por`, where the purpose word `para` was
  written -- five arms), an adjective and the `of` it takes before a perfect
  infinitive (`Colpevole di esser risultato positivo al controllo antidoping`
  is guilty OF HAVING TESTED positive, a clause of `tr_complements0/4` and the
  line of `tr_verbless0/3` for a heading, two arms) and a date after the
  adjective is when, never what it is said of (`il 17 maggio`, `oc/2` asks
  `tr_date_phrase/1`); a second participle joined to the first with its own
  agent (`il farmaco prescritto da Casotto e assunto da Rosi`:
  `tr_reduced_agent/3` reads `cpart/3`, `tr_cross_comp/2` crosses it,
  `tr_comp_out/7` writes it agreeing with the noun, and
  `tr_conjunction_split/5` no longer divides at the coordinator that a
  participle with an agent follows -- four arms); an insertion of the word for
  `if` and a participle (`una teoria che, se accettata, potrebbe modificare`:
  `tr_insertion_off/4` and the relative clause with commas,
  `tr_participle_gap/2`, two arms); the word for `thus` and a clause with its
  verb first between commas (`L'utilità dell'Egibren, così si chiama il farmaco
  ..., è stata una delle colonne`: `tr_insertion_off/4` reads it with its
  subject after the verb, the clause travels as `mid(sub(so(Word), S))` and
  `tr_cross_connector/3` and `tr_connector_out/3` carry the adverb -- three
  arms -- and English writes the reflexive of `calls` as the passive it is,
  `en_group/9`); a phrase with a series of relative clauses, a comma between
  them (`la gente che mi stringe la mano ogni giorno, che mi fa coraggio, che
  mi dimostra il suo affetto`: `tr_np/3` hangs each later clause on the phrase
  before it, as `nrc/3`, and `tr_verbless0/3` reads the whole heading of
  three); the comment of `come` whose actor stands after its verb (`(e non dopo
  le controanalisi, come prescrive il regolamento)`: `tr_relative_wh_after/3`
  after a phrase of a preposition and after the comma that parts it in a
  bracket, and `tr_rel_subject_fix/2`, which gives a clause with nobody named
  and a phrase for its first object that phrase for its subject, kept in its
  place with `subj_here` -- the same fix is what a relative clause after a
  preposition needed, `la casa in cui dorme Pedro`); the actor after the verb
  of an indirect question is its subject (`sa cosa mangia il gatto`,
  `tr_wh_subjects/3`) and a place's clause stands in front as an adjunct (`alla
  riunione romana dove ha combattuto Parisi`, `tr_adjunct(rwh(where, _))`); a
  demonstrative after the word for `like` is the pronoun (`verdetti alla
  casereccia come questo`, `tr_like_word/1` in `tr_subject_shape/4`); a series
  of predicates after a plain comma (`Rosi ora è furioso, promette vendetta,
  vuole riprendersi il titolo`: the reader no longer takes the second for a
  command, `tr_read_joined/5`, and the English writer elides the subject of the
  second and the third clause, never of the second of two: a comma splice keeps
  its pronoun, `The dogs sleep, they are tired`, `tr_write/4`); the word for
  `to` before an infinitive stops the phrase before it, though it is a noun too
  (`sono l'unico ad aver consigliato l'Egibren`, `tr_phrase_words0/4`); a modal
  and the copula, a phrase and the infinitive that says what it does (`Dovrebbe
  essere la gente a giudicarmi` is it should be the people to judge me,
  `en_null_it/2` for the modal and for the copula, `en_cleft_infinitive/1`, and
  the noun's preposition is written `to` after a modal, `tr_comp_out/7` --
  three arms); a relative clause with two verbs (`un processo che avrebbe
  accolto in pieno la linea difensiva e nonostante ciò avrebbe condannato
  l'imputato`: `tr_relative_clause/4` joins the halves, `tr_front_verb/1` lets
  the second open on adjuncts, and `tr_dangling_coordinator/2` stops
  `tr_read_generic/4` from taking the second verb for the sentence's -- guarded
  by a relative word before the coordinator and by a first word of the front
  that the clause has not met, two guards: `L'azione combinata del sole e di
  una bibita ghiacciata causa il blocco del cuore` and `contro le armi e contro
  il nucleare ha osato` lost their verbs to the first cut); an existential
  clause of `that` after a noun has no subject before its verb (`la conclusione
  che non ci fu dolo`, `tr_np/3`); the phrase after the word for `what` is an
  object, and what follows it is read as after one (`che strano modo di
  salutare`, `tr_complements0/4`); a count of time and what it is for, before
  the comma and the coordinator (`Due anni al pugile positivo per amfetamine,
  ma il giudice ammette`, a clause of `tr_join_left/5` and
  `tr_comma_and_parted/2` in `tr_read0/4`); an exclamation with a comma is read
  when the clause of `that` before it has failed (the cut moved after
  `tr_that_clause/3`, `Che ambiguità, una squalifica di due anni ...!`); a
  quotation that opens on the verb and closes in the subject (`"è sufficiente
  la mera assunzione" della sostanza proibita`: the copula's subject with its
  own `of` phrases, `with/2`, English opens the mark on the subject and the
  lesson's language puts the marks of the clause where they stood,
  `tr_open_first/2` -- three arms); a word that begins the relative is a
  subject with its clause (`chi ruba miliardi`, `tr_subject/6`); an adverb that
  is nothing else ends a phrase unless it grades the adjective after it (`Come
  nasce una sentenza così?`, `fo_adverb_ends/2`, a guard: `la stampa piuttosto
  tiepida`); and the English the sentences needed: `why` takes the bare
  infinitive (`en_assemble/9`), `does nothing but` a bare infinitive
  (`tr_modal_verb/0`), the collective plurals take the plural verb (`the people
  sleep`, `the people that sleep`, `en_collective_plural/1`, two arms), `uno`
  alone is `one` (two arms), `never` and the positive pronoun after it (`non ho
  mai scritto niente` is I have never written anything, three arms), the
  pronoun of the verb's own person after it is the subject said again (`sono
  arrivato io alla conclusione`, `tr_dislocation_fix/3`), `instead of` and
  `not` before the phrase of a preposition they are said of (`tr_comps_out/7`),
  the capital an adverb had at the head of the sentence goes with it (`Anche
  Rosi cade` is `Rosi also falls`, not `Rosi Also`: `anche` is the plural of
  `anca` in the store too, and a noun before a name keeps its capital as the
  first word of a name, `tr_write/4`), `or else` stays in front as `otherwise`
  does (`Altrimenti mi dedicherò al mondiale Wba` is `Or else I will dedicate`,
  the lesson's word for `altrimenti` where the dictionary's is `differently`:
  `en_conjunctive/1`) and `is about` takes `to`
  (`tr_verb_ends_in_preposition/0`). Four rules have no arm that goes red and
  stay for what the controls showed: the clause of the dashes, its guard
  against a preposition, the title's limit of eight words and the grading guard
  of `fo_adverb_ends/2` (without it `la stampa piuttosto tiepida` loses the
  adverb of its adjective, it_9781_9791 9 into English: `The press testifies to
  it enough lukewarm`).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader
  of one language and the writer of the other; the dictionary's own word is
  said again first where it must stay the one written): Italian `The word "per"
  begins the cause.` and twenty cities for the city rule (`Perugia`, `Bari`,
  `Cagliari`, `Catania`, `Verona`, `Padova`, `Trieste`, `Brescia`, `Parma`,
  `Modena`, `Pisa`, `Ancona`, `Pescara`, `Trento`, `Bolzano`, `Livorno`,
  `Taranto`, `Messina`, `Lecce`, `Salerno`; Spanish `por` for the cause and `de
  lo contrario`), `amfetamina`, `metilamfetamina`, `neurotraumatologia`,
  `microtrauma`, `dopa` (dopes), `funesta` (afflicts), `fan` (an apocope of
  `fanno`), `ko`, `ring`, `casareccio` and `casareccia` (homespun; `alla
  casereccia` too), `dà fastidio` (bothers, which the Spanish `molesta` is
  written as now), `beffa` (a mockery, where the dictionary's first noun is a
  fool), `furioso`, `legale` (a lawyer, a person), `modo` (a manner, not a
  mode), `volontà` (a will), `compie` (commits), `altrimenti` (or else, a gloss
  of its own, and Spanish `de lo contrario`: `otherwise` stays `per il resto`'s
  and `por lo demás`'s, one writer word each), `invece che` (an adverb, so that
  the phrase after it keeps its own `alla`), `assume` (takes), the name
  `Parisi`, `ci fu`/`c'è stato`/`ci furono` (there was), `dolo` (criminal
  intent), `illecito`, `forzatura` (abuse), `a livello federale`, `per ora`,
  `si riprende` (regains), `trentottenne`, `sa di` and `sa tanto di` (smacks
  of), `benservito` (dismissal), `processo` (a trial, not a process), `non fa
  che` (does nothing but), `uso`, `al termine di`, `ci vuole` (is needed) and
  `ben altro`, `conclusione` (takes its clause), the name `Casotto`, `sostiene`
  (maintains), `accoglie` (accepts), `antidoping` (a noun), `primario` (head
  physician, a person), `sta per` (is about) with its forms, `ricorre`
  (appeals), `fa venire voglia` (inspires), `responsabile`, `al corrente`,
  `prodotto di scarto`, `libera` (releases), `quindi` (therefore, where the
  dictionary's first is `then`), `assunzione` (intake, not acceptance),
  `utilità`, `impianto difensivo`, `gente` (a person), `stringe la mano`, `fa
  coraggio`, `voglia`, `fa progetti`, `va in galera`, `si vede concedere` (is
  granted), `libertà provvisoria`, and `combatte` (fights); Spanish
  `metilanfetamina`, `neurotraumatología`, `contraanálisis`, `ko`, `ring`,
  `dolo`, `ilícito`, `a nivel federal`, `por ahora`, `hombre de 38 años`,
  `huele a` and `despido`, `no hace más que`, `antidopaje`, `médico jefe` (a
  person), `está a punto de` and its forms, `responsable`, `al corriente`,
  `producto de desecho`, `prohibido`, `ingesta` (intake), `gente` (a person),
  `estrecha la mano`, `estrategia de defensa`, `hace planes`, `va a la cárcel`,
  `recibe` (said again first, so that it stays `receives`, and `is granted`),
  `libertad provisional`, `falta` (lacks) and `sostiene` (maintains: the
  Italian `sostiene` says it first now, and the Spanish word written for it
  stays its own, not the dictionary's `mantiene`); and in the dictionaries'
  extras `suspension` (`squalifica` first, `sospensione` stays the one
  written), `suspend`, `antidoping`, `doping`, `match`, `testimony`, `boxing`,
  `positivity`, `encephalic`, `performance`, `administer`, `counteranalysis`,
  `revenge`, `regain`, `jail`, `affair` and `homespun`, and for Spanish
  `antidoping` (`antidopaje`), `positivity`, `microtrauma`, `encephalic`,
  `homespun` and `safeguard`. Said again first, so that they stay the words
  written: Italian `fanno`, `avvocato`, `commette`, `licenziamento` (the
  Spanish `destitución` and `despido` stay `licenziamento`), `accetta`,
  `consapevole` and `incoraggia`. The first word moved in 19 Italian meanings
  and 2 Spanish ones (`consapevole` aware; `furioso`, `furiosa` furious;
  `altrimenti` or else; `quindi` therefore; `assunzione` intake; `beffa`
  mockery; `benservito` dismissal; `forzatura` abuse; `modo` manner; `processo`
  trial; `utilità` usefulness; `accoglie` accepts; `assume` takes; `combatte`
  fights; `compie` commits; `libera` releases; `ricorre` appeals; `sostiene`
  maintains; Spanish `ingesta` intake and `sostiene` maintains), and none was
  lost.
  The CONTROLS (cocolog 2.2.5, store KB170, 92 count files, 2 638 sentences:
  the earlier set with the basketball report (es_20001201-176) and this one in,
  both directions): the last version's translator against this one, on the one
  store, 73 sentences in 22 files read differently -- 42 in the report's two
  files and 31 in 20 files elsewhere, all better but two (below) -- `never`
  (it_10059_10095 4 and 6, it_9270_9295 14: `I have never written anything on
  Montanelli`), the collective plurals (es_20010102-25 3, `The police suspect`;
  it_9967_9998 5 and 22), `are called` (it_9472_9484 9, it_9637_9672 25), `in`
  before a city (it_9270_9295 6, and it_9540_9566 11 and 25 in both languages:
  `come si dice a Napoli` is `in Napoli`), the `it` of a modal and the copula
  (it_9381_9414 10 and 12, it_9816_9850 24, it_9851_9925 56 and tat 303:
  English refused four of them and wrote the fifth with nobody to be it), `why
  return` (it_9673_9712 34), `is about to drown` (it_9381_9414 14), the marks
  of `se "digan las cosas claras"` (es_20000903-30 8, both languages), `and are
  not` (es_20020102-112 11), `I have won!` (tat 1), `that our atlases make
  today` (it_9967_9998 25), and three sentences English reads for the first
  time (es_20020601-51 20, it_9926_9946 7, it_9967_9998 15) -- and the
  inferences fall 1.216 % (4 964 274 025 to 4 903 910 067) and rise 0.111 %
  outside the report (4 776 346 010 to 4 781 654 737). The file that rises most
  is it_9465_9470's, +2.9 % of 2.4 million, then es_19981202-34's, +2.0 % of
  12.5, and the ones that fall most are es_20020102-112's, -5.1 % of 71.6 (its
  eleventh, 32.0 to 28.3 million), it_9540_9566's, -3.6 %, and it_9926_9946's,
  -3.4 %; Tempi's twentieth, the sentence that runs to the limit in both
  languages, rises 0.7 % (473.0 to 476.5 million). Bytes and characters read
  every sentence alike (0 differ, the bytes 0.018 % more), and the new code on
  the old store (KB150) differs from the last version's in 38 sentences, 8 in
  the report's files and 30 elsewhere, +0.111 % outside the report, the same
  cost as on the new.
  The DATA COLUMN (the last version's translator on its own store, KB150,
  against this one on the new): 151 sentences, 62 in the report's two files and
  89 in 39 files outside them, the store's 60 and the code's 31 (two are both),
  and the inferences fall 6.564 % (5 248 400 886 to 4 903 910 067) and rise
  0.136 % outside the report (4 775 147 082 to 4 781 654 737). THE STORE ALONE
  (the last version's translator on the old store and on the new) differs in 60
  sentences in 30 files outside the report, +0.025 % of the inferences (4 775
  147 082 to 4 776 346 010), each a word of the report's lines: `quindi` is
  `therefore` and `por lo tanto` where the dictionary's first is `then` and
  `entonces` (23 texts in 12 files: it_10059_10095 26 and 31, it_9270_9295 21,
  it_9637_9672 30 and 33, it_9673_9712 19, it_9714_9749 30, it_9792_9799 3,
  it_9800_9814 1, it_9851_9925 15, it_9967_9998 20 and 28), `processo` a trial
  (8 texts: it_9926_9946 8, 9, 10 and 21, it_9851_9925 61), `forzatura` an
  abuse (6: it_9673_9712 14, 15 and 16), `modo` a manner (4: it_10059_10095 9,
  it_9673_9712 27), `combatte` fights (4: it_9763_9774 5 and 6), `sostiene`
  maintains (5, English: es_19981202-34 3 and 10, it_9637_9672 26, it_9967_9998
  5 and 28; Spanish keeps its `sostener`), `sta per` is about (it_9381_9414
  14), `uso` for `utilizzo` (es_19990802-48 6, es_20000701-80 25), `dà
  fastidio` for `molesta` (es_20020801-17 22), `estrecha la mano` for `aprieta`
  (it_9851_9925 20), `gente` a person (`descubría a gente`, it_10059_10095 28),
  `assunto` as `taken` for `assumed` (it_9714_9749 28, a participle where the
  sentence has the noun, as it did), and tat 157, `Huele a mil rayos aquí`,
  which was `Puzza a migliaio raggi qui` in Italian and is `Sa di migliaio
  raggi qui` now, and which English refuses (the verb of two words with nobody
  named). THE LINES' OWN REGRESSIONS, found in the data column of the first
  stores and mended: a line that gives a word its meaning comes first for the
  writer of the other language, so the dictionary's own word is said again
  first for Italian `fanno`, `avvocato`, `commette`, `licenziamento` (the
  Spanish `destitución` was written `benservito`), `accetta`, `consapevole` and
  `incoraggia`; the seven lines of the tenses and plurals of `ci vuole` refused
  the sentences with `ci vogliono dire` and are out; `dimostra` and `mostra`
  are the dictionary's again (below); `sostiene` has its Spanish line; and
  `altrimenti`, which first took the gloss `otherwise` of `per il resto` and
  `por lo demás`, wrote `per il resto` as `de lo contrario` (it_9967_9998 31)
  until `or else` became its own, with the fact of `en_conjunctive/1` that
  keeps it in front.
  THE FIRST CUT of the code cost 21.4 % outside the report (4 786 328 606 to 5
  811 772 493 on KB166) and was nearly all five sentences, found by counting
  the heaviest of a pass over a copy of the library per rule: Tempi's
  twentieth, 473.0 to 962.1 million inferences in each language, es_20020801-17
  22, 18.3 to 36.7 (the two relative-clause rules, the join of a relative
  clause with two verbs and the series of relative clauses, whose questions
  were asked at every relative word and every comma of a long sentence),
  it_9775_9780 3, 0.8 to 15.1 (`Quest'Uomo che una volta, a fianco di Marco
  Pannella, si batteva contro tutte le guerre, contro le armi e contro il
  nucleare ha osato`: the second verb taken for the sentence's, the two guards
  of `tr_dangling_coordinator/2`), it_9926_9946 16, 1.7 to 5.3 (the clause of
  the dashes, whose guard against a preposition was a variable the clause had
  already bound), and es_20000903-30 18, +2.1. What paid was the question asked
  ONCE a sentence and not at every word (`$tr_front_coord` and `$tr_comma_rel`,
  set in `tr_into_ir/4` and made when the library loads, or a sentence read
  before the first `tr_into_ir/4` found no flag and was refused:
  es_20000102-120 1); a pre-filter for the join of a relative clause that asked
  `tr_gap_verb_next/2` first cost 1 000 inferences a call and was taken out.
  The five stand at 476.5, 18.33, 0.80, 1.67 and 79.15 million. The English
  writer's first cut elided the subject of every clause after a plain comma and
  wrote `The violins cannot be copied, are only`: it elides in a series of
  three and keeps the pronoun of a comma splice (D13 of the section), and a
  failed write left the elision set for the next sentence (`$tr_elide`,
  `$tr_chain`) until it was put back.
  THE STATED COSTS: Tempi's twentieth rises 0.7 %; `Se Montanelli sapesse che
  gli ho dato del sentimentale, si arrabbierebbe` (it_10059_10095 25) read `one
  would anger` in English, the reflexive as the impersonal, and is refused now
  (`Montanelli si arrabbierebbe` and `Si arrabbierebbe` read as before: a
  conditional and a reflexive verb with nobody named); `adesso` of a clause
  with two verbs is written after both of them in Spanish (it_9851_9925 44:
  `que no hay más y no siente nada ahora`); es_20020601-51 20 reads in English
  where it was refused, `It had to be, in Seúl, the city curiously where this
  country attained in 1988, ...`; the first meaning that serves the news and
  not every text -- `forzatura` is an abuse (Tempi's three sentences are a
  forcing), `sostiene` maintains (`to maintain the destitute citizens` for
  `sostenere i cittadini indigenti`), `assunto` is taken, `quindi` is
  therefore; and `dimostra`, whose line (`shows`) cost four sentences their
  `demostrar` (it_9781_9791 4 and 7, it_9967_9998 12, it_10059_10095 18) and is
  the dictionary's again: `che mi dimostra il suo affetto` is `who demonstrate
  me his affection` in English, as the writer puts a clitic dative before the
  object for every verb (`Mi spiega il problema` is `They explain me the
  problem`).
  The report LEAVES, of the 38 into Spanish: `es furioso ahora` (`está`), `ha
  per ora smentito la voce di una sua denuncia` is `ha negado por ahora la voz
  de su queja` (10: a rumour, a complaint), `fa venire voglia di continuare` is
  `me inspiran continuar` (14), `non si occuperà mai più` is `no se encargará
  nunca más` and `se accettata` `si aceptada` (20), `l'unico responsabile` is
  `el único director` (25: the noun is read before the adjective), the
  subjunctive written as an indicative in 25, 26 and 30 (`dejó marchar`, `es
  divulgado`, `yo disputo`), `condannato l'imputato` has no `a` (28), `seré
  listo a recuperar` (`estaré listo para`, 30), `miliardi` are `millardos`
  (35), and 38, the lead line, is refused in both languages -- the source lost
  the colon after the sport (`Pugilato - la vicenda del pugile squalificato per
  due anni per doping il medico che gli prescrisse il farmaco prende le sue
  difese`); of the 34 into English: `removed him` for `gli ha tolto` (8),
  `resulted positive` for `risultato positivo` (12), `has not ended up` for
  `non è finita` (15), `I have arrived to the conclusion` (26), `lacks me` and
  `belongs me` for the verbs of the dative (30, 31), `make to start the
  positivity` for `fanno scattare` (21), `I will dedicate to the world cup`
  with no reflexive (31), `I bothered to a system` for `davo fastidio ad un
  sistema` (34), `Rosi Also, known for ...` for `Anche Rosi, conosciuto ...`
  (32: the capital goes with the name), `thus` last in 7, `his affection` for
  the people's (36), and the null third person that English refuses on purpose
  in 20 (`che non si occuperà`), 24 (`così come ha accettato`) and 25 (`che
  liberasse amfetamine`). The next sample's controls take this report in.
  The Miss World feature (AnCora CESS-CAST-P-20001201-199, 16 sentences,
  Spanish into Italian and English: 16 of 16 and 15 of 16 on a fresh store, 13
  and 12 with the new store alone, 7 and 8 with the new code on the old store
  and before; reasoning 1.0.8).
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_miss`: 68 checks, 65 arms, the guards among them; an arm is a
  library directory of symlinks whose reasoning/translate.pl is the edited
  copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_miss, checks_done"`, under a second a run, and every arm of this
  sample is run in twenty seconds, three at a time; the one that stays green
  there, the bytes twin of `tr_skip_inverted/2`, is red in `newspaper_units`,
  whose probes are 51 now): `lo que` is `what`, not `the one that` (`lo que
  interesa hoy es la belleza del espíritu`; the word that replaces a noun and
  says no gender is an article of no lesson, so the crossing keeps `what` and
  English writes it with its clause and no `that` -- `tr_np/3`,
  `tr_cross_det/2`, `tr_np_out/5`, an arm each); `lo` and an adjective that
  judges is what is so (`lo cierto es que las candidatas sólo han tenido 10
  minutos`, `tr_np/3` and `tr_subject_shape/4`, `en_judging/1`; a guard, `lo
  mismo` is the same thing and stays unread); a purpose in front keeps what it
  takes (`Para celebrar este 50 aniversario no se ha escatimado en gastos`: the
  anniversary was the subject of the rest, `The anniversary did not skimp in
  costs to celebrate`, `tr_read0/4`; a guard, a rest with nobody named is none
  for a front with an object, `Para sobrevivir el perro come`); a gerund after
  a subject's phrase is a relative clause on it (`100 jóvenes de 18 a 25 años
  rivalizando hasta el último minuto por un título merecen una audiencia`,
  `tr_subject/6`: the sentence's gerunds are noted when it is read, `$tr_ger`,
  the phrase before one is twelve words at most, holds no verb of its own and
  ends on a noun, an adjective, a number or a name, and what the gerund takes
  is ten words at most -- the first cut asked it of every phrase the search
  tried and cost the long sentences 5 %, a refusal of 476 million inferences
  rising 25); an adjective with a phrase of its own stands after its noun in
  English (`una audiencia digna de una Copa del Mundo`, `tr_comps_out/7`,
  `tr_adj_takes_phrase/3`, a subject's `tr_with_adj/5`, the writer's
  `postadj/2`: three arms); a thing's reflexive is a passive where the lesson
  says `"celebra" takes the passive.` (`el concurso que anoche se celebró en
  Londres`, `tr_se_passive/2` and, in a relative clause, `tr_se_passive_rc/4`,
  a name for the thing included, `Miss Mundo`: three arms, and a guard, a
  person's reflexive is none); a quotation closed before the clause that
  says it (`¿"Cómo podrán conocer nuestra personalidad ...?", se preguntaba
  Michaela`: the mark that closes stands at the head of the piece after it,
  with a comma or none, and was read as the OPENING mark of its first word,
  `tr_quote_pieces/2`, `tr_closing_comma/3`, `tr_skip_inverted/2`, with its
  code-point twin: four arms); `by the time` (`en_connector/1`); a decade
  after a preposition (`en los 70` is `in the 70s` and `negli anni 70`,
  `tr_cross_decade/2` from `tr_cross_comp/2` and `tr_np_out/5`; a guard, a
  pair is none, `tra le 70 e le 90 mila lire`, which the controls found at
  once); `last` and `next` for the adjective of a day, a month or a year
  (`el año pasado`, `el pasado noviembre`, `tr_np_out/5`, `en_time_noun/1`),
  the capital of an English day, month or nationality wherever it stands
  (`en_nationality/1`, `en_calendar_word/1`, `tr_cap/2`) -- SPELLED IN THE
  WORD, never in its case: the first cut set the case to `upper` and lost the
  closing mark of a quotation that ended on the word, `"controlará entre el
  60% y el 70% de los hipermercados catalanes"`, in three sentences of the
  controls (three arms for the marks), and a word that came with its capital
  keeps its small letters, `los Juegos Olímpicos` --; a time that says which
  one after an intransitive verb is when (`Murió la semana pasada`,
  `tr_time_which/1`), `fallecido el pasado noviembre` is no absolute clause
  (`tr_time_deictic/1`, `tr_month_which/1`, three arms); who died (`Eric
  Morley, fallecido el pasado noviembre` is `Eric Morley, who died last
  November`, `en_active_participle/1` in `tr_comps_out/7`, and the phrases
  between the person and the comma come after the clause, a guard that the
  clause has no adverb of its own: three arms); `no longer` is the denial and
  `più` in the lesson's languages and `simply` stands with the verb
  (`tr_write/4`, `en_mid_adverb/1`: three arms); `to begin with` and `in
  reality` stay in front (`en_conjunctive/1`) and `in reality` stands with the
  verb where the source has it inside the clause (`salvaguardano in realtà dai
  microtraumi`, which the new line for `in realtà` wrote last, `on the
  shoulders in reality`: the controls found it); `each` after the count it says
  how much of and `only` before a count of time (`tr_comps_out/7`); the
  adverbs after the word for `that` are the clause's own (`Es cierto que las
  candidatas sólo han tenido 10 minutos`, `tr_advs_into_clause/6`,
  `tr_adv_in_clause/3`: a guard, an adverb right after the RELATIVE `que` is
  the sentence's, `Lo que sí reconoció es que ...` put `sí` inside a quotation
  of the clause, found by the controls) and, of the two clauses a `that`
  joins, those of the first when they stand before the connector (`que esa
  unidad sólo será posible si los nacionalistas aceptan ...` wrote its `sólo`
  at the end of the second, `that never have had the Basques only`,
  `tr_adv_in_first/4`: two arms, and a guard, one after the connector is the
  second's); a participle's agent ends at a comma (`lagrimones vertidos por la
  elegida, en este caso la india Yukta Mookhey`, `tr_phrase_words0/4`); a noun
  and then adjectives alone are no list (`contra un espectáculo, vulgar y
  degradante`, `tr_adjectives_after_noun/3`) and the adjectives after a comma
  agree with the phrase before it (`tr_adj_after_comma/2`, asked once of the
  clause's complements whole, from `tr_write/4` and from its clause for a
  subject after the verb, which takes the complements apart: `Volaron bombas
  de harina contra un espectáculo, al parecer de muchas, vulgar y degradante`
  was `volgari e degradanti`, the bombs', in the controls' own sentence and in
  none of the hand lesson's until a check had the subject after the verb; asked
  of each tail the writer took, the comma before an aside of its own was gone;
  two guards found by the controls, a phrase between commas of its own, `no
  son, en consecuencia, reales`, and a source adjective that says its gender
  for a subject that gives none, `sagr/1`, `Alle spalle ha una vita
  movimentata, quasi avventurosa`); and the small ones: `medio siglo` is `half
  a century`, `este 50 aniversario` is `this 50th anniversary`, `el mismo` is
  not `the same one`, `para qué engañarnos` is `why deceive us`, `escatima en`
  is `skimps on` (`"escatima" takes "en" before the phrase.`, `en_governs/2`),
  and the adverb the lesson says goes with the verb stands with it in the
  lesson's language (`The adverb "ya" precedes the verb.`, `The adverb "già"
  follows the verb.`; `el mundo ya tendrá una nueva miss` is `il mondo avrà
  già`, `tr_pull_foreign_adverb/3`, `tr_fo_mid_insert/4`: before the participle
  of a verb with its auxiliary, after a verb of one word, never between a
  clitic and its verb, and before the impersonal word too, `ya se puede
  decir`: three arms).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader
  of one language and the writer of the other; the dictionary's own word is
  said again first where it must stay the one written): Spanish `miss` (a
  beauty queen, a person), `lagrimón`, `circo` before `tinglado`, `unas
  cuantas`, `sin pena ni gloria` (undistinguished, with its own plural),
  `vuela` (intransitive), `frena` (curbs), `pretende` (intends), `para
  cuando`, `para qué`, `un tanto`, `cada una` and `cada uno` (each), `de
  paso`, `de entrada`, `protagoniza` (stars in), `descubrimiento` before
  `hallazgo`, `capacidad` (a capability), `celebra` (takes the passive), the
  names `miss mundo`, `miss república checa`, `islas maldivas` and `miss mundo
  2000`, `elegida`, `destronado` and `destronada` with their plurals, `capaz`,
  `en realidad`, `echa a rodar` (gets going), `liga bronceado` (gets a tan),
  `sala de juego`, `candidata`, `jurado` (a person), `al parecer de`, `muchas`
  (a pronoun, with `muchos` said first), `ya` (precedes the verb), `se lleva`
  (takes along) and `escatima` (takes `en`); Italian the same words (`miss`,
  `lacrimone`, `senza infamia e senza lode`, `frena`, `recita in`, `per
  quando`, `alquanto`, `a testa`, `di passaggio`, `per cominciare`,
  `prescelta`, `detronizzato` and `detronizzata`, `capace`, `caritatevole`,
  `concorso` first for `contest`, `in realtà`, `parte` (gets going, with the
  dictionary's own `splits` said first), `prende la tintarella`, `sala da
  gioco`, `candidata`, `a parere di`, `già` -- it follows the verb --,
  `deceduto` and its forms, and `porta` (brings, then takes along), said again
  first where the Spanish `lleva` needs it); and in the dictionaries' extras
  `dethrone`, `outgoing`, `dated`, `skimp`, `vie`, `goldmine`, `crown`, `gaze`
  and, for `charity`, `caridad` first and `beneficencia` after it. The first
  word moved in 10 Spanish meanings and 3 Italian ones (Spanish `capaz` is
  capable, `saliente` outgoing, `candidata` a female candidate, `capacidad` a
  capability, `hallazgo` a discovery, `mirada` a gaze, `tinglado` a circus,
  `corona` crowns, `frena` curbs and `pretende` intends; Italian `alquanto` is
  somewhat, `candidata` a female candidate and `frena` curbs), and none was
  lost.
  The CONTROLS (cocolog 2.2.5, store KB177, 94 count files, 2 670 sentences:
  the earlier set with the Rosi report in and this one, both directions): the
  last version's translator against this one, on the one store, 153 sentences
  in 49 files read differently -- 21 in the report's two files and 132 in 47
  files elsewhere, 91 of those by a capital alone (an English nationality, day
  or month: `French`, `Basque`, `Palestinian`, `Sunday`, `September`) and the
  other 41 all better -- `lo que` as `what` (13: es_19981202-34 10,
  es_19990802-48 10, es_19990901-75 8, es_19991001-61 7, es_20000903-30 14,
  es_20020601-51 6, es_20020801-17 9, and six of Tatoeba's, tat 121, 227, 261,
  334, 339 and 366), `last` and `next` (10: es_19981202-34 11, es_19990701-130
  4 and 7, es_20000701-80 6, es_20010102-25 2, es_20011202-66 3, es_20020301-125
  12, it_9816_9850 5, it_9967_9998 4, tat 313), the adverb that goes with the
  verb, `ya` and `già` (es_20010103-120 5 and 16, es_20020102-112 13,
  es_20020601-51 6, it_9763_9774 10, it_9926_9946 13 and 14), `no longer`
  (it_9637_9672 27), `at least` before its count (it_9381_9414 17), `a kit full
  of photographs` (it_9851_9925 68), the adjectives after a comma
  (it_9851_9925 49 and 72: `amigo`, `profundas`), a quotation with its adverb
  inside and `only if` (es_20000903-30 18, in both languages), `anche`
  (es_20020601-51 19) and `in reality safeguard` (it_9567_9604 21) -- and the
  inferences fall 0.944 % (5 006 946 087 to 4 959 655 531) and rise 0.115 %
  outside the report (4 906 098 706 to 4 911 754 432). The file that rises most
  is it_9775_9780's, +7.1 % of 5.0 million (its second sentence, 0.82 to 1.17),
  then it_9567_9604's and es_20020301-125's, +0.6 %; the ones that fall most
  are it_9947_9966's, -1.7 % of 29 million (its twentieth, 4.10 to 3.67
  million, and its eleventh, 1.17 to 1.05: `il prossimo 24 gennaio` and `il
  prossimo febbraio`, which the month's guard, `tr_month_which/1`, reads at
  once), and the report's own; Tempi's twentieth, the sentence that runs to the
  limit, rises 0.03 % (476.49 to 476.62 million). Bytes and characters read
  every sentence alike (0 differ, the bytes 0.018 % more). The DATA COLUMN (the
  last version's translator on its own store, KB170, against this one on the
  new): 163 sentences, 29 in the report's two files and 134 in 49 files
  elsewhere, the 132 of the code and three of the words (es_20010202-169 10,
  `capaz` is `capable`; tat 47, `Devono avere deceduto`, where it was
  `decesso`; it_9567_9604 21, once more), and the inferences fall 6.881 % (5
  326 137 108 to 4 959 655 531) and rise 0.160 % outside the report (4 903 910
  067 to 4 911 754 432). THE STORE ALONE (the last version's translator on the
  old store and on the new) differs in 26 sentences, 23 of them the report's
  and 3 elsewhere, +0.045 % outside it (4 903 910 067 to 4 906 098 706), and
  THE CODE ALONE (the new translator on the old store) in 131, 7 in the
  report's files and 124 in 43 files elsewhere, +0.115 % outside it (to 4 909
  564 479), where the report reads 7 and 8 as before. Eleven expectations of
  the older sections of test/translate.pl and six of lesson 46 were written in
  the old English and changed with the capitals, `last` and `what` (`saturday`,
  `sunday morning`, `next february`, `the next year`, `roman`, `the olympic
  Barcelona`, `the catalan board`, `The one that makes them wished`).
  THE FIRST CUTS' REGRESSIONS, found by the controls and mended: the capital
  set as the word's case lost the closing mark of a quotation (above, three
  sentences) and the small letters of `los Juegos Olímpicos` (`Games Olympic`,
  `Commission European` -- the order asks whether the lesson knows a word with a
  capital); `last` and `next` lost the marks a quotation had on their noun; a
  plural nationality (`los catalanes`) had no capital; `tra le 70 e le 90 mila
  lire` was a decade (the guard, a pair of counts); `Lo que sí reconoció es que
  ...` put `sí` inside the quotation of its clause; the adjectives after a comma
  were the aside's (`no son, en consecuencia, reales`) and a feminine
  adjective's with nobody named (`quasi avventurosa`: two guards); the gerund
  rule cost the long sentences 5 %; and the last two, found by the final
  round, a focus adverb in a clause a `that` joins to another (`sólo` at the
  end of the sentence, where the last version wrote it after the verb of
  saying) and `in realtà` written last once the line made it an adverb. One
  more stayed hidden until the end, in the report's own tenth sentence: the
  hand lesson's check of the adjectives after a comma had the subject before
  the verb, and the real sentence has it after, which the writer takes apart
  (`volgari e degradanti`, the bombs'). THE LINES' OWN REGRESSIONS, found in
  the store alone (25 sentences outside the report on the first store, 3 on the
  last): Italian `parte` as `leaves` first wrote every Spanish `dejar` as
  `partire` and `parte` as `deja` (`nos han dejado` was `ci hanno partito`,
  `Dejé el país` `Partii il paese`, `Parte martedì il corso` `Deja el martes`:
  11 sentences) -- the dictionary's `splits` is said first now, and `gets
  going` after it; the intransitive `espera` (waits) read `esperarse de` as
  `wait` and `Pedro espera a María` as `waits to María` -- out; the pronouns
  `muchas` and `molte`, said first, made every Italian `molti` the Spanish
  `muchas` and read `molte altre cose` as a pronoun and its object (`Many liked
  him other things`) -- `muchos` is said first now and `muchas` after it, and
  the Italian `molte` is out.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the five heaviest rises
  counted over a copy of the library per rule, on the new store): two rules are
  all of it. The participle's agent ending at a comma is 0.30 of the 0.31
  million that Rosi's sixth sentence rose, 0.22 of the 0.23 of es_20020301-125 4
  and 0.47 of the 0.50 of the Hotel Arts tenth (+1.1 %, a refusal of 47
  million): the whole rest is asked as the agent first and, when it reads as
  none, the part up to the first comma again. The gerund after a subject's
  phrase is 0.35 of the 0.35 million of it_9775_9780 2 (+43 % of a sentence of
  0.82 million, where `il cuore leggendo nella cronaca ...` is asked as a
  relative clause and the complements of the gerund are read, to be read
  otherwise). `lo` and the adjective that judges (+1 100 to +32 000 a
  sentence), the month's guards and the noun's capital are under 250 each. THE
  STATED COSTS: a first meaning that serves the news and not every text --
  `tinglado` is a circus (a shed second), `frena` curbs (a car brakes second),
  `pretende` intends, `capaz` capable, `capacidad` a capability, `hallazgo` a
  discovery, `mirada` a gaze, `corona` crowns, `candidata` a female candidate,
  `concorso` a contest (the archaic `agone` stays read only), `alquanto`
  somewhat -- and the controls' sentences they change are the three of the data
  column above.
  The report LEAVES, of the 16 into Italian: `per quando leggono queste linee`
  (the subjunctive written as an indicative, `righe`), `in Londres` and `Islas
  Maldivas` (names the lesson knows no city for), `ha rimesso l'immagine`
  (`riproposto`), `l'indiano Yukta Mookhey` and `a parere di molti` (the IR
  keeps no gender for an apposition or a pronoun: `l'indiana`, `molte`, the
  women), `non si è economizzato in costi` (`risparmiato sulle spese`), `50
  anniversario` (`50º`), `di 18 a 25 anni` (`dai 18 ai 25`), `udienza`
  (`pubblico`), `nell'inizio` and `per dei giorni` (`all'inizio`, `per qualche
  giorno`), `il novembre passato` (`lo scorso novembre`), `un eco` (`un'eco`),
  `decise allocare` (`di destinare`), `lavori di beneficenza` (`opere`),
  `potettero` (`poterono`), `ha preteso` for `ha pretendido` (`ha cercato di`),
  `togliere lucentezza al suo affare` for `sacarle lustre a su negocio` (an
  idiom crosses word by word, with no `di` before the infinitive), `un bel
  annuncio` (`un bell'annuncio`), `insiste che` (`sul fatto che`), the
  coordination after `podrán conocer` in 15 (below), `Si chiedeva` with a
  capital after the closing mark, and `attende ancora` for `aún espera` (16);
  of the 15 into English: `a Cup of the World of football` (`a football World
  Cup`), `youngsters of 18 to 25 years` (`aged`), `One has not skimped`
  (`No expense has been spared`), `in the beginning of` (`at the start of`),
  `what wanted was` (6; a relative clause nobody names a subject for is
  written with none, `what he wanted`; `more than what receives`,
  es_19991001-61 7, is the same), `has returned the image` (`brought back`),
  `the new promise` (`hopeful`), `a part of the profits` (`some of`), `to remove
  shine to his business` (`its`), `an ad of bikinis` (`a bikini ad`) and, in 15,
  `How will our personality and our capability be able to know` (a
  coordination after a verb group and its infinitive is read as the subject
  when it agrees with the plural verb, so the infinitive loses its object:
  with one phrase it reads, `How will they be able to know our personality`;
  `¿Cómo comen el pan y la casa?` is `How do the bread and the house eat?`, the
  last version's reading too), `The answer still expects` (16: `espera` is the
  verb of expecting whether or not it has an object, and the line that made it
  wait took `esperarse de` and `espera a María` with it); English refuses 7 for
  the third person nobody names, on purpose (`Pero encontró un filón ...`). The
  next sample's controls take this feature in.

  The review's fixes (an outside review of 283997b, checked by the engine
  session; reasoning 1.0.9, cocolog stays 2.2.5; no new article). Four small
  things, three of them in code or data:
  WHICH, AND WHO DOES IT. `¿Qué libro lee el gato?` was `Which book reads the
  cat?`: `fo_question_word/3` took the phrase asked for as the subject unless a
  name or a pronoun stood alone after the verb, and `¿Qué perro come el pan?`
  has the same shape. `fo_which_object/3` settles it by two things and no
  more: the verb's number (`¿Qué libros lee el gato?`, `¿Qué medidas tomará el
  Gobierno?`: the phrase asked for has no reading in the verb's number and the
  phrase after the verb is one the verb agrees with) and a doer after the verb
  when the phrase asked for is none (a name, a pronoun, a noun the lesson calls
  `person` or `animate`); two doers, or none, are read as before. `animate` is
  a bare-class line like `"amigo" is a person.`, new here: corpus/extra states
  119 Spanish and 109 Italian animals, the nouns whose meaning in the
  vocabulary is `cat`, `dog`, `horse`, ... (found by a script, the false
  friends out: a calf of the leg, a stamp, a drink, a sip, a bat, a game).
  corpus/spanish.txt and italian.txt are the tagger's corpus and are untouched,
  so the hand lesson alone still reads `gato` as no doer; a taught store reads
  it. On the stores: `¿Qué medidas tomará el Gobierno?` was `Which
  measures will take the Government?` and is `Which measures will the
  Government take?`, `¿Qué libro recomienda el autor?` `Which book does the
  author recommend?`, `¿Qué ley firmó el presidente?` `Which law did the
  chairman sign?`, Italian `Quale libro consiglia il medico?` `Which book does
  the doctor advise?`; `¿Qué presidente firmó la ley?`, `¿Qué jugador marcó el
  gol?` and `¿Qué perro come el pan?` read as they did. `test/translate.pl`'s
  `question_roles` (17 checks) and lesson 46's section 72 hold it, with an arm
  for each of the seven rules and five for the guards: a name that goes on is
  not read (`fo_name_goes_on/2`: `¿Qué libro lee Maria Lopez?` is still `Which
  book reads Maria Lopez?`, because `fo_np_words_after/3` ends a bare name at
  its first word -- `¿Qué come Maria Lopez?` is `What does Maria eat Lopez?`
  by the same fault, older than this), two doers, a verb with no subject
  after it (`¿Qué libros hay en la casa?` is `Which books there is in the
  house?`, the old text, which is not a good one). STATED LIMITS: an
  institution is no doer (`¿Qué medida tomó el Gobierno?` is `Which measure
  took the Government?`, `¿Qué partido ganó el equipo?` `Which match won the
  team?`: `"gobierno" is animate.` would mend them, and a list of such nouns
  is the next step), and a noun with the same form in both numbers
  (`crisis`) never clashes with a verb.
  A STATED GENDER MEETS AN ENDING RULE (`tr_gender/2`): feminine was asked
  first, so `"leche" is feminine.` beat the masculine rule and `"mapa" is
  masculine.` lost to the feminine one and wrote `La mapa`. A masculine the
  lesson states now wins unless it states the feminine too (`"mar"`: the
  feminine, as it always was); a denial still wins over a rule. Only
  `tr_gender/2` has the order: the 23 other places that ask
  `tr_holds(feminine(...))` -- participles, adjective forms, a few nouns --
  still ask the rule, and the reasoner holds both genders true as before. It
  costs one fact lookup for a word the rule calls feminine (+0.022 % of the
  inferences of the files into Italian, +0.014 % into Spanish, +0.005 % into
  English). The `stated_gender` section (10 checks, two
  arms) also scans both vocabularies for a masculine noun in `a` whose denial
  is missing: Spanish 166 nouns, none; Italian 90, four, which are
  `caposquadra`, `centro destra`, `centro sinistra` and `microtrauma`
  (corpus/extra/italian.txt, copied as they stood by `cb_extra/1`, so
  `La microtrauma è grande.` was the Italian writer's text): the four lines
  `"X" is not feminine.` are in, and the Italian vocabulary rebuilt.
  THE CONTROLS (cocolog 2.2.5, 94 count files, 2 670 sentences, the last
  version's translator on KB177 against this one; KB178 taught from the
  rebuilt vocabularies): the CODE ALONE changes no sentence (+0.011 % of the
  inferences, 4 959 655 531 to 4 960 191 126), the DATA COLUMN none (KB177 and
  the old code to KB178 and the new: +0.011 %), the STORE ALONE none (with the
  old code -0.000 %, with the new -0.000 %), and bytes and characters read
  every sentence alike (the bytes +0.018 % more). The controls cannot see these
  fixes: not one of their sentences asks `qué` and a noun before a doer, and the
  vocabularies already fenced every masculine noun in `a` they use. The fixes
  stand on their sections and on the stores' own sentences above. THE
  TAGGER'S COMMENT said six rules over eight bullets where the code has
  eleven (library/reasoning/tagger.pl, above `tagger_sane/2`): it lists the
  eleven now; a comment, and the reasoning number moves with it as any change
  under library/reasoning/ does. `lo` is `him` before `it`, as the lesson
  states them, and stays so (the README says it).
  The Lazio football report (VIT-9511..9539, 29 sentences, Italian into Spanish
  and English: 28 of 29 and 26 of 29 on a fresh store, 21 and 20 with the new
  store alone, 14 and 13 with the new code on the old store, 13 and 12 before;
  reasoning 1.0.10). The sample was taken on the cocolog 2.3.0 binary, as the
  owner asked, and every figure below is that binary's. Master's 2.4.0 was
  merged into the branch after the sample; the merge touched nothing under
  library/reasoning/, and the next sample's controls are taken on 2.4.0. The
  article's sentences fall from 209.5 to 24.9 million
  inferences in each language (a refusal is a long search).
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_lazio`: 77 checks, 59 arms, the guards among them; an arm is a
  library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_lazio, checks_done"`, under a second a run, and every arm is run in
  24 seconds, three at a time): `if not` and a phrase (`una curiosità maliziosa,
  se non una vera e propria pressione`: the word for `if` and a denial before a
  phrase travel as they do before an adjunct, the denial and its phrase one
  complement, neg/1, tr_complements0/4; read as a condition the clause had no
  verb and the sentence was refused); an adverb before a purpose in front, at
  the top of a sentence and inside a clause (`quando invece per contestare
  arrivano in tanti`: tr_front_skip_adverbs/2, and a clause of tr_nested_front/3
  for the purpose, which a nested front did not read -- three arms); `when` and
  `where` right after a verb that asks nothing are the relative words (`il cane
  dorme quando il gatto mangia` is `duerme cuando`, where it was the question's
  `cuándo`, tr_relative_wh/3, rwh/2), and `how` with a verb of saying and its
  speaker is `as` (`se "cambiare è migliorare" come dicono i giocatori
  all'unisono`, tr_how_as_saying/2, cmtc/1, past a complement of the verb as
  well, tr_relative_wh_after/3), a verb that takes the question keeping it --
  whether the lesson says so (`"sa" takes the question.`) or not, for the verbs
  of asking, seeing, finding out and saying (tr_asks_question_here/0, en_asks/1:
  `vede quando il gatto mangia` is `ve cuándo`) -- six arms; a name and an
  adjective with the copula left out (`Signori ottimista, Zeman velenoso`,
  tr_verbless0/3); a front that ends on an absolute clause with no comma leaves
  the rest its subject (`Dopo una rivoluzione mancata la Lazio si è ritrovata
  uguale a sé stessa`: longest first the front took `mancata la Lazio` for a
  clause of its own and the `si` of the rest was the impersonal one, `One has
  found equal to itself after a revolution lacked the Lazio` -- two arms, the
  rule and its guard against an impersonal subject, whose check is `il cane si
  mangia il pane`); the word for `same` after a reflexive pronoun is its
  emphasis in English (`equal to itself`, tr_comps_out/7); a headline after a
  section's name and a dash that opens on a plural noun and its adjective is the
  noun first (`Calcio - dichiarazioni varie del giocatore e del Ct della Lazio`:
  `varie` is what `variare` says as well, tr_read0/4); a question after an
  infinitive that takes it, and the word the infinitive puts before it (`si è
  limitata a macerarsi su chi dovesse vendere` is agonises OVER who:
  tr_relative_wh_after/3, tr_question_after_inf/4 for the infinitives with `a`
  and the bare ones, tr_wh_verb_set/1, tr_wh_preposition/2, en_governs/2 -- six
  arms), and `chi` after a verb that takes the question asks (`non so chi
  vende`, tr_who_gap/2 -- two arms); three names and an adverb that closes them
  (`Stoichkov, Baggio, Lombardo eccetera`, tr_list_closer/2, and a comma after
  the adverb); `non solo,` a comma and a clause with no partner said (the two
  words are an adverb of the clause after the comma, nonly/0, read, written and
  crossed -- three arms); `mentre` as a connector is not lifted as the adverb it
  is also (tr_head_connector_lifted/3); the future after `if` (`se riusciremo a
  giocare` is `if we succeed in playing`, `si logramos`: tr_if_future/4, and
  tr_clause_present/2 for both clauses of a condition joined by `and`; of an
  Italian text only, because Spanish's `si vendrá` is a question and keeps its
  future, tr_future_protasis_language/1; and never of the clause an `if` joins
  to a clause that asks, a copula with nothing after it or a verb of asking,
  saying and knowing, tr_whether_governor/1: `Il dubbio è se il cane verrà o se
  il gatto dormirà` is the doubt is if the dog WILL come, and the `or` clause
  after it is a question as well, '$tr_whether', tr_write_second/4 -- six arms);
  `secondo me` is `según yo` in Spanish (tr_subject_form_preposition/1); `lo`
  after a verb of saying is what is said (`A dirlo è Giuseppe Signori` is
  Signori says IT) -- never a dative (`gli ho chiesto` is I asked HIM) and never
  the pronoun after an infinitive (`le ha detto di essere stata lei` is said to
  her to have been HER), three arms; the partitive after a verb of having,
  buying and eating (`il torneo ha delle novità` has novelties: Italian only,
  the first complement, a definite article and a common noun, after the verbs of
  tr_partitive_verb/1 -- `parla dei gatti` is of the cats, and `della piccola
  Sofia` and `di una domenica` are phrases of `of` -- three arms); the perfect
  gerund is the auxiliary's (`avendo mantenuto` is `habiendo mantenido`, not
  `teniendo`, and the participle agrees with nobody -- two arms); a pronoun
  after `di` that a preposition takes (`senza di lui`, the lesson line `"senza"
  takes "di" before the pronoun.`); a plural of the first person names a team in
  the singular (`Siamo una squadra`, tr_null_copula_agrees/4); `una delle
  quattro squadre` is no ratio (tr_phrase_words0/4) and Spanish has the gender
  of the noun the phrase names (`uno de los cuatro equipos`, tr_ell_gender/2);
  two next numbers with a dash between them are either (`una delle quattro -
  cinque squadre`, tr_number_ranges/2, and `los cuatro o cinco equipos`,
  tr_elided_count/2, which leaves `21 nuove e 12 rinnovi` alone); one of the
  teams is no person (tr_of_class/2); `né ... né` is `neither ... nor` and one
  denial in English (`non è né stanco né caldo`, `non dorme né con il gatto né
  con il pane`, tr_nor_list/3); two connectors of several words (`premesso che`,
  `tanto è vero che`, en_connector/1); a Bohemian has his capital
  (en_nationality/1); the verb of a relative clause whose word is its object has
  an object (`l'allenatore che ora conosciamo` is `conocemos`, not `sabemos`,
  tr_passive_object/3); and a verb of several words that begins with the copula
  is no comment (`in un certo senso sono troppi, sono d'accordo, ma non pensate
  che ...`: between two commas a verb in the first person is the writer's own
  comment, tr_asides/3, "never the copula", and `sono d'accordo`, stated as the
  verb `è d'accordo`, took the sentence away -- the data column found it,
  tr_copula_group/1).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Italian `buriana` (storm),
  `offusca` (overshadows, with its forms), `a l'unisono`, `autocritica`, `boemo`
  (a person), every number from twenty-one to ninety-nine the lesson lacked (70
  lines), `valore` (a value, where the dictionary's first meaning is courage),
  `si macera` (agonises, `su` before the question), `premesso che` and `tanto è
  vero che`, `è d'accordo` (is in agreement, with its forms and `su` before the
  phrase), the prepositions that take `di` before a pronoun (`senza`, `contro`,
  `verso`, `su`, `sopra`, `sotto`, `dentro`, `fuori`, `dietro`, `tra`, `fra`),
  the names `signori`, `scala`, `lombardo`, `romano` and `esposito`, `mancato`
  (failed, where the participle read as lacked), `vero e proprio`, `in tanti`
  and `in tanti di più`, `allenatore` and `ct` (a coach, a person), `di primo
  piano` and `di vertice`, `malizioso`, `lato` (a side, not a canton), `per poi`
  (begins the purpose) and `parte` (departs, where the dictionary's first is
  splits); Spanish the same (`autocrítica`, `al unísono`, `bohemio`, `se
  atormenta` with `por`, `dado que`, `tanto es así que`, `está de acuerdo` with
  `con`, `conmigo` and `contigo` as contractions, `fallido`, `en gran número`
  and `en mayor número`, `de primera línea` and `de primer nivel`, `malicioso`,
  `para luego`, and `habiendo` as the gerund of the auxiliary); and in the
  dictionaries' extras `reinforcement`, `bizarre`, `supporter`, `merit`,
  `renewal`, `dismember`, `recommence`, `hoard`, `upset`, `Bohemian` and
  `improve` (`migliorare`, both ways: the dictionary's first English for it is
  `enhance`) for Italian, and `dismember`, `recommence`, `overshadow` and
  `spring` (`primavera`: the dictionary's first Spanish noun for it is a coil)
  for Spanish. The first word moved in 6 Italian meanings and 3 Spanish ones
  (Italian `maliziosa` and `malizioso` malicious, `lato` side, `valore` value,
  `migliora` improves, `parte` departs; Spanish `maliciosa`, `malicioso` and
  `parte`), and none was lost.
  THE CONTROLS (cocolog 2.3.0, store KB187, 94 count files, 2 670 sentences:
  every earlier article and Tatoeba's 400, both directions; this report is not
  among them): the last version's translator against this one, on the one store,
  20 sentences in 12 files read differently, all better -- `it` for `him` after
  a verb of saying (es_20000701-80 20, it_9465_9470 4, it_9714_9749 6 and
  it_9926_9946 6, English), the future after `if` (it_9567_9604 30, it_9800_9814
  10, it_9851_9925 57, it_9947_9966 11 and 15), `for itself` for `for itself
  same` (es_20000903-30 19), `conocido` for `sabido` (it_10059_10095 35),
  `hacemos errores` for `hacemos de los errores` (it_9816_9850 25), and three
  sentences the last version's translator did not read on this store:
  it_9816_9850 11 in both languages (below) and es_20020601-51 13 into English
  -- and the inferences fall 1.472 % (5 023 520 002 to 4 949 559 324) and rise
  0.077 % outside the four sentences that fall by over a million (3.77 million
  of 4.89 billion). The files that rise most are it_9781_9791's, it_9763_9774's
  and it_9450_9464's, +0.2 %, and the sentences that rise most it_9673_9712 27
  (+75 thousand of 20.4 million), it_9967_9998 22 and 25 (+74 thousand each) and
  it_9270_9295 8 (+40 thousand); the ones that fall are it_9816_9850 11 (37.6
  million to 4.6, read) and 25 (30.3 to 24.4). Bytes and characters read every
  sentence alike (0 differ, the bytes 0.018 % more). The DATA COLUMN (the last
  version's translator on its own store, KB179, against this one on the new): 33
  sentences, the 20 of the code and 13 of the words -- `valore` is `value`
  (it_10059_10095 30, it_9714_9749 24), `parte` departs where it split
  (it_9967_9998 32, it_9714_9749 28), `migliorare` improves (it_9567_9604 24
  into Spanish), `sono d'accordo` is `estoy de acuerdo` (it_9816_9850 15),
  `conmigo` (tat 380, into both) -- and the inferences fall 0.214 % (4 960 189
  446 to 4 949 559 324) and rise 0.076 % outside the four. THE CODE ALONE (this
  translator on the old store): 18 sentences, -0.162 %, +0.077 % outside the two
  falls. THE STORE ALONE (the last version's translator on the old store and on
  the new): 15 sentences, +1.277 % of the inferences (4 960 189 446 to 5 023 520
  002), all of it one sentence: it_9816_9850 11, 5.3 million inferences on the
  old store and refused after 37.6 on the new (+64.5 million in the two
  languages, the rest of the files falling by 1.2 million together) -- the one
  sentence of the data column that went from read to refused, found by teaching
  the old store with each group of the new Italian lines (19 groups, 13 seconds
  a store). The line `"sono d'accordo" is the first person of "è d'accordo".`
  makes `sono d'accordo` a verb in the first person, which the writer's-comment
  clause of tr_asides/3 took between its two commas (it leaves the copula alone
  by name, and its comment says why: this very sentence), and this translator
  reads it in 4.6 million (tr_copula_group/1).
  THE FIRST CUTS' REGRESSIONS, found by the controls and mended: the partitive
  took the contraction of every kind (Spanish `El perro tiene del pan`, `di una
  domenica`, `della piccola Sofia`, `in compagnia della moglie`, `dare del
  sentimentale`), and is Italian's alone now, the first complement, a definite
  article and a common noun, after a short list of verbs; `it` after a verb of
  saying changed three datives (`gli ho chiesto`, `se lo pide`, `le ha detto`: a
  dative sets '$tr_opron_dat'); the count in its noun's gender regendered `21
  nuove e 12 rinnovi` (a number and no adjective now); a trial round found `lei`
  after an infinitive written `it` (`le ha detto di essere stata lei ad
  avvertire il bagnino`), and `La duda es si el portero recuperará hoy mismo la
  titularidad o si el técnico optará` and `El perro pregunta si el gato vendrá`
  read as conditions (the future after `if` is Italian's alone now, and a clause
  that asks keeps its future); the first cut of `when` made `Il cane chiede
  quando arriva il gatto`, `Vedremo quando arriva il treno` and `Mi chiedo
  quando il cane mangia` relatives -- the whole case's old guard (`Il cane vede
  quando il gatto dorme`) found one and the real vocabulary the rest, because
  the lessons say a verb takes the question for a handful of verbs only; and the
  second cut of the future after `if`, restricted to the condition in front,
  lost the article's own sentence 21 (`Possiamo vincere se riusciremo a giocare
  il nostro calcio`), which the clause that asks decides now. Four guards were
  taken out because their arms moved nothing in the controls, in the article or
  in the section: the verb-form guard of `se non` and a phrase and of a name and
  an adjective (tr_denied_verb_form/1), and the capital guard of the noun-first
  headline and of the headline after a dash. THE COST OF THE CODE, FOUND BY
  TAKING EACH RULE OUT (the five heaviest rises counted over a copy of the
  library per rule, on the new store): three rules are 98 % of the 299 thousand
  inferences the five rose -- the clause of tr_nested_front/3 for a purpose,
  asked at every nested clause (217 thousand, 73 %), `chi` after a verb that
  takes the question (46 thousand) and a pronoun after `di` (30 thousand); every
  other rule is under a thousand.
  THE STATED COSTS: es_20020601-51 13 is read into English (`Step by step, one
  shows proud to the elite, without asking who has in front`: the `se` of `se
  asoma` is the impersonal one, and the sentence was refused); the first meaning
  that serves the news and not every text -- `parte` departs (`partido` is the
  participle of `partir`, `departed` where it was `split`, es_20010102-25 11,
  and `parte civile` is `departs civil`, it_9926_9946 9: a noun the lesson does
  not state), `valore` a value, `lato` a side, `malizioso` malicious,
  `migliorare` improves; and the verbs of asking, seeing, finding out and saying
  keep the question after them (`Ricordo quando eravamo giovani` is still
  `Recuerdo cuándo`: `ricorda` is a verb of saying), a short table and not a
  measure of the verb. The report LEAVES, of the 29 into Spanish: 2, the
  headline `Signori ottimista, Zeman velenoso: assurdo, Balbo italiano"` (a lone
  adjective, a comma and a name with its adjective: `Zeman velenoso, assurdo,
  Balbo italiano` reads, `Assurdo, Balbo italiano` is refused, in both
  languages); `Giappone` and `Italia` stay (no lesson states a country), and 4
  writes `vederne` as `verlo los lados` (the clitic `ne`); 7 `gran parte` is
  `grandes parte` (and English puts the relative clause before `says it`); 8
  `che ne è seguita` is `que lo es seguida`; 10 the marks of `se "cambiare sia
  davvero migliorare"` are moved and its subjunctive written as an indicative;
  11 `Lo stesso` is `El mismo`, `di questi molti sono` `muchos son ... desde
  cerca de éstos` and `si porta dietro` `se trae atrás`; 14 `secondo me` is last
  and `non sono cambiati molto` is `no son cambiados muy`; 16 `lo meritava di
  più Beppe` is `lo merecía más a Beppe`; 17 `per la prima volta` stands last;
  18 `essendosi trovato` is `siendose encontrado` (the perfect gerund of a
  reflexive verb); 21 `riuscire a` is `attain to` in English; 24 and 26 write
  the subjunctive as an indicative, and `giochi` is the noun in 26 (`juegos para
  el Argentino`); 27 `ha fatto sapere` is `ha hecho conocer` and `offerte`
  `intentos`; English refuses 23 and 24, the third person nobody names, on
  purpose, and writes `each federation has his regulations` in 25. The next
  sample's controls take this report in.
  The Inter feature (AnCora CESS-CAST-P-20011002-160, 14 sentences, Spanish into
  Italian and English: 14 of 14 and 13 of 14 on a fresh store, 10 and 8 with the
  new store alone, 5 and 6 with the new code on the old store, 3 and 4 before;
  reasoning 1.0.11). The sample was taken on the cocolog 2.4.0 binary, master's
  (the Lazio report is in master with it), and cocolog stays 2.4.0. The
  article's sentences fall from 587.7 to 46.0 million inferences into Italian
  and from 587.3 to 45.3 into English (a refusal is a long search: the first
  sentence alone was 527 million inferences and refused); its second sentence is
  20 million of the 46.
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_inter`: 64 checks, 67 arms, the guards among them, and one rule,
  `nothing-of-shape`, with no arm that goes red, below; an arm is a library
  directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_inter, checks_done"`, three seconds a run, and every arm is run in
  under a minute, three at a time): the doer after a relative clause's verb (`el
  pan que come el perro` is the bread the dog eats, and read with the relative
  word for the subject it was `the bread that eats the dog`: Spanish marks an
  animate object with `a`, so a definite phrase right after the verb that names
  a doer -- a name, a team's name, a noun the lesson calls a person, an animal
  or a group -- and no `a` in the clause is the clause's subject and the
  relative word its object, tr_rc_role/7's clause for tr_rel_doer/2; `"equipo"
  is a group.` is new, 42 Spanish and 43 Italian nouns of the kind, the next
  step the review's stated limit of reasoning 1.0.9 named, and `partido` is no
  group: it is a match; the guards, one arm each: an `a` in the clause, an
  indefinite phrase (`un jugador que busca un entrenador`), a name where the
  phrase it hangs on is a doer itself (`el técnico que dirige el Inter`), a
  copula for any relative word but `lo que` (`la ciudad que es la capital`), an
  infinitive before the phrase (`Craxi che minaccia di regolare i conti con i
  magistrati`: `conti` are also counts, persons, and the sentence was refused),
  the phrase of a pronoun before it (`cuenta con 19 emisoras de toda Catalunya`
  made Catalunya the doer), and for a lesson with no word before a person,
  Italian's, the rule only where the phrase it hangs on is no doer: `il pane che
  mangia il cane` is the bread the dog eats, `una madre che ha perso la figlia`
  still lost her daughter; with the copula, `lo que hoy es el equipo` is what
  the team is today; the question words take a group for a doer too, `¿Qué
  medida tomó el Gobierno?`, fo_animate_phrase/1); an adverb before the verb of
  an object relative is one of its complements (`el pan que siempre come el
  perro`, tr_relative_clause/4); a verb of saying with nothing after it has its
  object in the relative word (`con lo que dice`, tr_rc_role/7 and
  tr_object_verb/1, English writes `they`; `hace` is not one of them: `lo que
  hace es "desacreditar"` is what the insistence does, and with a null subject
  English refused Conyers' sentence of the controls); a connector of three words
  with no comma before it and a verb straight after it is a preposition and its
  relative (`no convence a nadie con lo que dice`, tr_unjoin_relative/3 in
  tr_joined_words/3, tr_comma_connector/1; the comma keeps the consequence,
  `Pedro duerme, con lo que dice`, and so does a phrase and its verb, `...
  estuvieron en Gandía con lo que esa elección resulta más que cuestionable`),
  and `de lo que` after a word of quantity is not the `than what` of a
  comparison (`nada de lo que`, tr_quantity_word/1); `pero sí` before a
  preposition is a contrast and the stress is dropped (tr_drop_contrast_yes/3),
  and a relative clause ends at the comma of a contrast with no verb
  (tr_contrast_cut/4); a verb before an infinitive crosses by the meaning the
  lesson gives it there (`The infinitival verb "trata" means "tries".`, with the
  plain `The verb "trata" means "treats".` said first, tr_mean_links/3,
  tr_verb_across/5; before a phrase it is `treats` still, `se trata de un
  perro`); an animal is a person for the word before one -- a definite animal
  only, `preparar un "cocodrilo"` is an obituary (`coccodrillo`) and takes none
  (tr_of_class/2, tr_marker/3), and `nadie`, `alguien`, `nessuno`, `qualcuno`
  are persons; `desde` and a date is since, and a present that has gone on is
  the perfect in English (`no gana el scudetto desde 1989` has not won the title
  since 1989, tr_cross_comp/2, tr_since_phrase/1, en_since_comp/1): a year, a
  month, a day of the week or a time with a PAST adjective, never a place, a
  range (`dal 24 luglio al 25 agosto` is from July 24 to August 25,
  tr_cross_comps/2, tr_date_range/1), a time to come (`dalla settimana prossima`
  is from next week, and the lesson's own `since` keeps the present, `fin dalla
  prossima riunione`) or a phrase after a comma, which is the aside's (`Pratesi,
  amico da anni della coppia` is a friend for years, and the interview had not
  `paralysed` for years); `todo lo que`, all that (tr_np/3's all/2 with ell/4,
  tr_subject_shape/4, tr_np_out/5), `nada de lo que`, nothing of what (tr_np/3
  -- with the verb `nada` swims in the hand lesson, or a lesson that has it
  reads the verb -- and tr_subject_shape/4, the one rule with no arm that goes
  red: without it the text is the same and the Inter's eighth sentence costs 7.5
  % more) and `lo más ADJ de ...`, the most ... thing ABOUT it (tr_np/3 over the
  unfolded words of a subject and over the degree the complements fold, `colocar
  al club en lo más alto`, tr_subject_shape/4, tr_with_adj/5; a lesson in which
  `lo` is no pronoun after a preposition, `"lo" means "him"`, is what shows the
  folded one; the six clauses of the three, in tr_np/3 and tr_subject_shape/4,
  are asked in a sentence that has a word that replaces a noun with a relative
  word or a degree word right after it and in no other, `$tr_replacer`,
  tr_replacer_note/1: each asked the lexicon first at every phrase, which was
  1.2 million of the 2.1 million inferences the fourteen heaviest risers of the
  controls rose, and the note makes the arm `replacer-note` red by always saying
  no); a capital name the lesson states after an article that is not its noun's
  gender is the name (`el Valencia`, tr_np/3; `la Valencia` keeps the noun), and
  a noun of several words that opens on a nationality has its capital (`Italian
  football`, tr_np_out/5, en_nationality/1); `must` has no perfect, `has had to`
  (en_group/9); `Hace dos años que el Inter no ocupaba ...` is `It has been two
  years since ...` (tr_write/4); the doer after a preposition's relative (`un
  ataque con el que sueñan los interistas`, tr_rel_doer_fix/3, and the
  preposition is the English verb's own, `dream OF`, en_governs/2), and a second
  relative clause joined to the first by a coordinator whose doer follows its
  verb (`... Y QUE han truncado las constantes lesiones`, tr_np/3's nrc/3 with
  ro/2, tr_nrc_head/2, tr_np_out/5; inside a clause of `that` the whole is one
  clause, tr_second_relative/4; the reader runs in a sentence that has the
  pattern only, `$tr_second_rel`, tr_second_rel_note/1); the phrase that is not
  `of` after the participle of a predicate is the participle's (`un delantero
  forjado en la cantera del Inter`, tr_participle_predicate/3); a relative
  clause with two fronts, each set off by commas (`la gestión que ahora, con su
  noveno proyecto, parece ...`, tr_relative_clause/4) and the aside after the
  word right after the opener (tr_clause_mids/4: set apart first and, if the
  sentence then reads nothing, left among the words); the second of two
  adjectives before their noun (`un largo y duro periodo`, tr_phrase_words0/4);
  a word that is a preposition and a verb (`para`) is the preposition before a
  person (`un largo periodo para su propietario y accionista`,
  tr_read_generic/4; `"accionista" is a person.` is a line of corpus/extra); an
  adverb of manner right after a participle stays with it (`organizado
  tácticamente y unido`, tr_comps_out/7) and the participles and adjectives
  after the comma agree with the noun written (`una squadra compatta,
  organizzata ... e unita`, tr_adj_after_comma/2, tr_agreeing_run/3, only after
  an object: after the phrase of a preposition they are the subject's, `in piena
  libertà, regolamentate`); and the builder's: an adverb that is its adjective
  written again (the dictionary's musical `largo` and `allegro`) is no entry
  (corpus/build.pl's cb_stray_adverb/2: `un largo y duro periodo` read `largo`
  as the adverb).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Spanish `interista` (an Inter
  fan, a person, not feminine), `scudetto` (a title, with the dictionary's
  `título` said first before it, or every Italian `titolo` was written
  `scudetto`), `ataque` (said again first) and `delantera` (an attack), `en
  cambio` (said again first) and `en su lugar` (instead), `vestuario` (a
  changing room), `cantera` (a youth academy), `sensatez` (good sense),
  `nerazzurro` and the paper's `neriazzurro` (black-and-blue), `calcio` (Italian
  football), the names `Valencia` and `Sierra Leona`, `trata` before an
  infinitive (tries, with the plain `treats` said first before it, or `se trata
  de un perro` was `one tries of a dog`), 42 groups (`equipo`, `club`,
  `gobierno`, `empresa`, ...), `nadie`, `alguien` and `accionista` (persons),
  `fracaso` (a failure, where the dictionary's first Spanish noun for it is
  `fallo`), `trayectoria` (a trajectory), `corbata` (a necktie, below) and
  `tiene que ver` (has to do); Italian `appare` and `riconquista` (said again
  first), `ha a che fare` (has to do), `spogliatoio` (a changing room),
  `tatticamente`, `interista`, `invece` (said again first) and `al suo posto`
  (instead), `vivaio` (a youth academy), `sensatezza` (good sense),
  `nerazzurro`, `calcio` (the football said again first, the Italian football
  after it, the kick last), 43 groups, `nessuno` and `qualcuno` (persons),
  `fallimento` (a failure), `traiettoria` (a trajectory), `acquisto` (the
  purchase first, the signing after it, the shopping last) and `cravatta` (a
  necktie); and in the dictionaries' extras, for Italian `sconvolgere`
  (convulse), `indisciplinato` (unruly), `avallare` (endorse), `pareggio` (a
  tie, where the dictionary's first Italian noun for it is the necktie),
  `efficace` (effective) and `forgiare` (forge), and for Spanish `convulsionar`,
  `díscolo`, `taciturno`, `tácticamente` and, read only, `recobrar` (regain).
  The first word moved in 7 Spanish meanings and 5 Italian ones (Spanish
  `calcio` Italian football, `cantera` a youth academy, `corbata` a necktie,
  `delantera` an attack, `trayectoria` a trajectory, `vestuario` a changing room
  and `tiene que ver` has to do; Italian `cravatta` a necktie, `fallimento` a
  failure, `traiettoria` a trajectory, `vivaio` a youth academy and `ha a che
  fare` has to do), and two were lost, the adverbs `largo` and `allegro`, the
  dictionary's musical ones that mean themselves (the builder's rule, above).
  THE CONTROLS (cocolog 2.4.0, store KB195, 96 count files, 2 728 sentences: the
  earlier set with the Lazio report in, both directions; this report is not
  among them): the last version's translator against this one, on the one store,
  21 sentences in 14 files read differently, all better -- the doer after the
  verb of a relative clause (es_19990601-23 5, es_20000802-31 3, es_20000903-30
  10 and 18, es_20001201-176 10, es_20010103-120 4, es_20020801-17 8, and
  Tatoeba's 227, 334 and 339: `the majority backing that Solana has obtained`,
  `what Tom said was certain`, `what they were saying`), `since` (es_20010102-25
  4 and it_9750_9762 3: `Since Sunday`, `since 1992`), `had to` for `musted`
  (it_10059_10095 2), a participle and its phrase (es_20010202-169 6, `a
  stradivarius known like Golden Bell`; it_9637_9672 8, `the dramatic picture
  contained in the report`), `definitively` before the date (it_9926_9946 12),
  the capital of `Christian` (it_9673_9712 16) and the animal that needs no
  second reading as a phrase of `to` (tat 107, `The cat ate the mouse`, in both
  languages) -- but one of them, es_20010102-25 4 into Italian, only different:
  `Fin da domenica` for `Da domenica`, the Italian writer's first word for
  `since` -- and the inferences rise 0.177 % (5 000 350 488 to 5 009 219 484).
  The sentences that rise most are Tempi's twentieth, the one that runs to the
  limit in both languages (476.70 to 477.02 million, +0.07 %), es_20020301-125 1
  (+0.25 million of 1.29: the doer after `que encabeza Jordi Porta`, the clause
  read both ways), es_20000903-30 18 (+0.13 of 79.2) and es_20001201-176 10
  (+0.12 of 4.4, a better reading: `el aire que necesitaba el equipo de Aíto`);
  the files that rise most are es_20020301-125's, +0.7 % of 44 million, then
  it_9465_9470's (2.5), es_20010103-139's (9) and Tatoeba's (43), +0.4 %; no
  file falls, and the one sentence that does is tat 107 (134 509 inferences to
  102 471, the animal). Bytes and characters read every sentence alike (0
  differ, the bytes 0.018 % more). The DATA COLUMN (the last version's
  translator on its own store, KB188, against this one on the new): 31 sentences
  in 18 files, the 21 of the code and 10 of the words, and the inferences rise
  0.199 % (4 999 257 736 to 5 009 219 484). THE CODE ALONE (this translator on
  the old store): 19 sentences in 12 files, the same 19, +0.172 %. THE STORE
  ALONE (the last version's translator on the old store and on the new) differs
  in 10 sentences in 9 files, +0.022 % of the inferences (4 999 257 736 to 5 000
  350 488), each a word of the report's lines and one of them worse: `tiene que
  ver` and `ha a che fare` have to do (es_19981202-34 9 and it_9270_9295 17,
  English), `aparecer` is `apparire` where the dictionary's first Italian verb
  for it was `figurare` (es_19981202-34 7, es_20000102-120 7, es_20010102-25 16,
  es_20020102-112 2), `trayectoria` a trajectory (es_20000903-30 14, English),
  `efficace` for `effettive` (es_20001201-176 5), `corbata` a necktie (tat 50,
  English) -- and `no figuran ni Rivaldo` is `non appaiono` (es_20010103-120 5),
  where `figurano` was right.
  THE LINES' OWN REGRESSIONS, found in the store-alone column of the first store
  (25 sentences, 14 of them worse) and mended: `The masculine noun "scudetto"
  means "title".` came first for the Spanish writer, so every Italian `titolo`
  was written `scudetto` (`el scudetto mundial`, `los scudettos` for the
  headlines: it_9567_9604 8, 30 and 32, it_9637_9672 15, it_9714_9749 4 and 10)
  -- the dictionary's own `título` is said again first; the English `tie` for
  `pareggio` came first for the Italian writer, so `su corbata` was `il suo
  pareggio` (tat 50) -- the necktie has a word of its own in both languages
  (`corbata`, `cravatta`) and the draw keeps the tie; and `The infinitival verb
  "trata" means "tries".` said first made `tries` the verb's meaning anywhere,
  so `se trató de unos 10 kilos` (es_20010102-25 7 and 9, es_20000802-31 9, both
  languages) was `one tried of about 10 kilos` and `si tentò di circa 10 chili`
  -- the plain `treats` is said first, as the hand lesson of the section had it
  all along (the vocabulary check had the order backwards, and the section was
  green). It is the reason to read the texts of the store alone, not its count:
  +0.022 % of the inferences hid 14 worse sentences in 25.
  THE FIRST CUTS' REGRESSIONS, found by the controls (the texts of every
  sentence that differs, not the counts) and mended: the first pass changed 42
  sentences, refused 3 that the last version read (es_19981202-34 10,
  it_9781_9791 6 and it_9967_9998 32, all into English) and cost +1.019 % of the
  inferences (5 000 357 282 to 5 051 321 327; it_9270_9295 rose 9.7 % of 137
  million). `hace` among the verbs that leave their object in the relative word
  refused Conyers' sentence (`lo que hace es "desacreditar"`, the insistence
  does it); an infinitive after the verb was not looked at, so `Craxi che
  minaccia di regolare i conti con i magistrati` had `conti` for the doer of the
  threat; the aside right after a clause's opener was kept among the words only
  when nothing else read, and `Salvo che lui, a differenza di Agostino, era
  disposto ...` read `lui` as the pronoun of a clause with no verb (the
  extraction is the first try now, and the unextracted words the fallback: a cut
  in the else branch of a condition cuts the clause in cocolog, so the condition
  decides it, tr_clause_mids/4) -- the first cut of that rule moved the aside of
  `Quest'Uomo che una volta, a fianco di Marco Pannella, si batteva`
  (it_9775_9780 3) and lost the comment between the dashes of `Gallo - continua
  - mi ha lasciato` (it_9540_9566 21); `desde` made every phrase since -- `dal
  24 luglio al 25 agosto` (it_9472_9484 12), `dalla settimana prossima`
  (it_9270_9295 10), `fin dalla prossima riunione` (it_9673_9712 18), `desde el
  primer momento` (es_20000903-30 16) and `amico da anni della coppia`, whose
  friend had paralysed the interview for years (it_9851_9925 49); `preparare un
  coccodrillo` (it_10059_10095 4) was a man's crocodile; a connector of three
  words took a phrase and its verb after it (`Rivaldo y Overmars tampoco
  estuvieron en Gandía con lo que esa elección resulta más que cuestionable`,
  es_20010103-120 8); the doer was the name in the phrase of a pronoun (`cuenta
  con 19 emisoras de toda Catalunya`, es_19990701-130 6) and the daughter of a
  mother who lost her (`una madre che ha perso la figlia`, it_9851_9925 6); the
  participles after a comma agreed with the nearest noun after a phrase of a
  preposition (`in piena libertà, regolamentate`, it_9792_9799 2) and `fallecido
  el pasado noviembre` with the days before it (`deceduti`, es_20001201-199 4).
  The cost was one rule, the second relative clause, asked of every long
  sentence with a coordinator: +12 million in two sentences of it_9270_9295
  alone. `$tr_second_rel` is set once a sentence from a test of its words (a
  coordinator, a relative word and a doer after a verb, tr_second_rel_note/1)
  and the reader asks only where it is `yes`; its first test took the verb form
  of `truncado`, which is a noun too, and the section's own sentence lost its
  second relative clause (tr_verb_form_any/1 asks the participles as well).
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (a copy of the library per
  rule, on KB195: first the 14 heaviest risers of the controls, then 56
  sentences of 0.2 to 2 million inferences, every k-th of the class, 28 of each
  language, into English): the second cut was +0.319 % of the controls (5 000
  350 488 to 5 016 313 242), and the 14 rose 2.1 million of 399.5 (+0.528 %), 58
  % of it six clauses of three rules -- `todo lo que` (tr_np/3 395 thousand
  inferences, tr_subject_shape/4 103), `nada de lo que` (287 and 85) and `lo más
  ADJ` (156 and 199) -- each asking the lexicon first, at every phrase of every
  sentence (a memo hit is 11 to 13 inferences), and the rest the doer after a
  relative clause's verb (365: es_20020301-125 1 is read both ways, 1.29 to 1.54
  million, and es_20001201-176 10 reads `que necesitaba el equipo` as it should,
  +0.12), the two fronts (228), a participle's phrase (96), a preposition that
  is a verb (50) and a name's gender (35). What paid was a note made once a
  sentence: `$tr_replacer` (a word that replaces a noun with a relative word or
  a degree word right after it, tr_replacer_note/1) is asked first by the six
  clauses, one inference where it says no, and costs its own scan, 218
  inferences in a sentence of five words and 2 700 in fifty -- every sentence
  read alike (0 differ), -0.133 % of the controls, so +0.186 % -- and three
  idioms: `sub_atom/5`, which walks every position, asked of every noun English
  writes for a nationality (`atomic_list_concat/3` splits it), and two walks of
  every word for `sí` and for a connector (`memberchk/2` and the connector
  facts): -0.009 %, so +0.177 %. What is left is no rule: over the 56 sentences
  +0.353 % (47.74 to 47.91 million), the largest `desde` (tr_since_phrase/1
  asked of every phrase of a preposition: 0.033 % in tr_cross_comp/2 and 0.029 %
  in tr_cross_comps/2, some 300 inferences a sentence each), a participle's
  phrase 0.017 %, a preposition that is a verb 0.016 %, a name's gender 0.016 %
  and the two fronts 0.012 %, no other over 0.01 %. The notes, measured on a
  copy that prints the inferences each one spends: `$tr_replacer` 1 149 a
  sentence (0.139 % of these 56), `$tr_second_rel` 384 (0.046 %) and
  `$tr_comma_rel` 55, beside the older ones' 4 242 (the agent first, 0.495 %), 1
  153 (a participle after a determiner, 0.140 %) and 1 115 (a coordinator with
  an adjunct, 0.135 %). The arms of a rule written too wide
  (`named-gender-wide`, `participle-predicate-wide`, `animal-person-wide`) are
  no measure of its cost: the clause they leave open reads other sentences or
  refuses them sooner (the first spends 417 thousand inferences less in
  it_9673_9712 17, which is refused both ways).
  THE STATED COSTS: a first meaning that serves the news and not every text --
  `calcio` is Italian football (a Spanish text on calcium is football),
  `vestuario` a changing room, `cantera` a youth academy, `delantera` an attack,
  `trayectoria` a trajectory (the Italian vocabulary has one noun for a path,
  `traiettoria`, so `en el buen camino` is `nella buona traiettoria`), `fracaso`
  a failure, `corbata` a necktie, `tiene que ver` has to do, `appare` appears
  (the four sentences it mends, and `no figuran ni Rivaldo` it does not),
  `valencia` a name, `trata` tries before an infinitive (and `treats` still
  everywhere else); the draw is the tie, so every Spanish noun for a tie but the
  necktie (`lazo`) is `pareggio` in Italian; `desde` and a date is the Italian
  writer's first word for since, `fin da`; the stray-adverb rule drops the
  dictionary's two musical adverbs and nothing else; the 42 and 43 nouns of the
  group are an institution first (`dirección`, `banco`, `junta` and `rosa` have
  other senses, which matter only straight after the verb of a relative clause
  with no `a` and no other doer); `nothing-of-shape` has no arm that goes red
  (the eighth sentence of the article costs 510 783 inferences with it into
  English and 550 827 without, 535 499 and 575 543 into Italian, the text the
  same); the article's second sentence is 20 million inferences, 2.96 with the
  arm `mids-open-skip` (the aside after the word right after the opener is set
  apart first and the unextracted words are the fallback, as `Salvo che lui, a
  differenza di Agostino, era disposto ...` and `Quest'Uomo che una volta, a
  fianco di Marco Pannella, si batteva` need, while `la gestión que ahora, con
  su noveno proyecto, parece ...` reads only in the fallback, after the
  extraction has failed on a long sentence; with no fallback, `mids-open`, it is
  refused); and the doer rule reads a relative clause twice where its shape
  allows both (es_20020301-125 1 rises 19 %). The article LEAVES, of the 14 into
  Italian: `primo luogo` for `primer puesto` (1), `una lunga e dura epoca` for
  `periodo`, `l'olio imprenditore` for the oil man, `porta quasi un decennio
  versando denaro` for `da quasi un decennio versa`, `disporre al club nella
  cosa più alta` (`colocar` is `disporre`, and the lesson has no `ai vertici`),
  `con quelle che trionfò` for `con le quali ha trionfato` (3), `in Milán` (a
  name the lesson has no city for), `ha agito il miracolo` (4), `adesso` last
  (5), `in cinque giorni` for the rounds (6), `nel campo` (7), `ha arrivato`
  (10: the auxiliary of a verb of arriving), `e efficace` (11), `quest'anno
  dell'Atalanta` for `dall'Atalanta` (12) and `altro tempo` for `un'altra volta`
  (13); of the 13 into English: `his proprietary and maximum shareholder` (1:
  `propietario` read as the adjective before the noun it is), `the oil richest
  employer`, `place to the club in the highest thing`, `form her` (12: the
  clitic `la` of a thing is written `her`), `the Turkishes` and `the own Kallon`
  (13), `now` and `today` last (13 and 14), `inter fans` in small letters (10:
  `Inter` is a name, `interista` is not) and `with what they say` (7: the third
  person nobody names, written `they`); the third sentence is refused, on
  purpose, for the null third person of `con las que triunfó`. The next sample's
  controls take this feature in.
  The Rognoni interview (VIT-9605..9636, 32 sentences, Italian into Spanish and
  English: 31 of 32 and 31 of 32 on a fresh store, 26 and 25 with the new store
  alone, 19 and 19 with the new code on the old store, 18 and 17 before;
  reasoning 1.0.12). The sample was taken on the cocolog 2.11.0 binary,
  master's, and cocolog stays 2.11.0. THE BINARIES OF 2.4.0 AND 2.11.0 give the
  same texts on the controls (96 count files, 2 728 sentences: 0 differ) and
  2.11.0 counts 5.896 % more inferences (5 009 219 484 to 5 304 565 743): since
  2.5.0 `atom_concat/3` is a clause over `$atom_concat`, four or five inferences
  a call where it was one, and the translator calls it often; the clock does not
  move (three alternating pairs of one control file, medians 16.99 s on 2.3.0,
  whose texts and counts are 2.4.0's, and 16.55 s on 2.11.0). So no count of
  this sample compares with the Inter's, and the baseline is the committed
  library on KB195 on 2.11.0. The article's sentences fall from 872.7 to 807.5
  million inferences in each language, and 773.1 million of them are its
  nineteenth, refused (below).
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_rognoni`: 40 checks, 31 arms, the guards among them; an arm is a
  library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_rognoni, checks_done"`, two seconds a run, and every arm is run in
  under a minute, three at a time): a name apposed to a name between commas is
  no word of the subject's shape (`Carlo Rognoni, Pds, parla dell'intreccio ...`
  is a man and his party, tr_subject_shape/4, as an aside, a bracket and a dash
  are), and in a reporting clause the apposed name is the speaker's (`Commenta
  Carlo Rognoni, Pds, vicepresidente del senato:` was `Comenta a Carlo Rognoni`,
  tr_reporting/3), and English writes what the speaker is with the speaker,
  before the verb (`Carlo Rognoni, Pds, vice-president of the senate,
  comments:`, where it was `Carlo Rognoni comments, vice-president of the
  senate`, tr_write/4 -- the controls' `Claude Lebet, one of the most
  acknowledged luthiers, said` and `Filippo Graziani, dean of the school ...,
  underlines` with it); `among` before a pair of phrases joined by `and` is
  `between` (`l'intreccio tra le nuove regole e le trattative`, tr_comp_out/7;
  among three it stays `among`, a guard); `more than` and `less than` before a
  count (`di cui nessuno abbia più di una rete` is more than one network -- read
  as the adverb and a phrase of `of`, English wrote `has of a net more`, and
  denied `anymore`: the lesson states `più di` and `meno di` as one adverb, as
  Spanish's `más de`, and where the second word is also the lesson's word for
  `than`, Italian's `di`, the reader takes the pair apart again unless a number,
  an indefinite article or an article and a number follows, tr_than_split/3, a
  guard `mangia più di me`; and `more than` before `a` is before `one`,
  tr_comps_out/7 -- three arms); `very` before a comparative is `much` (`Molto
  meglio, pensare con intelligenza al futuro` is much better, `basta assai meno
  del 50,1%` much less than it, `molto più grande` much bigger: tr_much_before/3
  in the crossing of an intensified adverb and of an intensified comparative,
  which the crossing folds into the adjective, and the English writer puts `much
  less than` before the object it says how much of -- three arms, and the guard
  `molto grande` is very big); `makes` with nothing made is `does` (`chi compra
  ... lo fa a suo rischio` does it, `Che dovrebbe fare Berlusconi?` what should
  he do, `non fa niente` does nothing: the lesson's `fa` and `hace` mean makes,
  and English says that only of a thing made -- an object, an infinitive, a
  predicate -- tr_makes_does/3, with `lo` as `it` there, and its past and
  participle are `did` and `done`, en_past_of/2 and en_participle_of/2: the
  controls' first round wrote `they have doed it` -- four arms, two guards); an
  adverb between a question's verb and its subject stays where it is (`Che
  dovrebbe fare, allora, Berlusconi?` -- nothing agreed after the verb,
  Berlusconi was the object and the subject a third person nobody named, `¿Qué
  debería hacer entonces a Berlusconi?`, and refused in English:
  fo_adverb_subject/5, asked only by fo_unfront/3, the question's reader -- in
  fo_subject_after/5, which the statements' readers ask too, it changed four
  inverted statements of the controls, below); no phrase with its phrases of
  `of` before `there is` is what there is (`Dopo la sentenza della corte c'è
  stato il referendum` was `The judgment of the court thered is the referendum
  after`, tr_read_generic/4's guard, with/2 as np/5); a preposition before an
  article and a phrase that runs to a comma governs it and is not lifted as an
  adverb (`Secondo la corte, è necessario un vero pluralismo` -- `secondo` is
  also the adverb `second`, and lifted it left the court for the subject and the
  copula's own subject an object, `The court, is necessary a true pluralism
  second`: tr_governs_adverb/3, and the reader that lifts the adverbs of a piece
  with its commas taken out asks it of the head word with the commas, two arms);
  an infinitive after the copula and its adjective is written after them in
  English, with `it` before (`è necessario evitare che ...` was `To avoid that
  ... is necessary`, tr_write/4, where the source had the subject after the
  copula: `Mangiare il pane è facile` keeps its order, a guard); `insofar as`
  and `unless` are English connectors (en_connector/1), and the denial before
  the first verb of a clause of `unless` denies nothing (`a meno che non si
  liberi` is unless he frees himself, Italian's expletive `non`:
  tr_expletive_off/3 in tr_joined_words/3 -- three arms); a verb the lesson's
  language governs with a preposition takes its phrase bare in English where the
  English verb does (`incidere sulle scelte` is influencing the choices,
  en_bare_object/1); `whether` and an infinitive (`dovrà scegliere se fare
  l'uomo di governo o mantenere il controllo delle sue tv` is choose whether to
  be ... or to keep, and with no clause after `se` there was no question:
  whinf/1, read after a verb that takes the question and after the bare
  infinitive of one, `"sceglie" takes the question.`, and written with `to`
  under a modal, whose infinitive English writes bare -- three arms); a day or
  an adverb alone between a participle and its agent (`il disegno ... varato
  giovedì dal senato` was `desde el senado`, tr_reduced_agent/3); two
  prepositions joined before one phrase (`leggere tutto pro o contro
  Berlusconi`, `con o senza il gatto`: pp2/4, read, crossed and written, the
  first a word the lesson gives an English preposition for -- `colocados cerca o
  dentro de un vehículo` has `cerca`, a wall as a noun, and the controls' first
  round wrote `placed wall or within`; two arms); the word that begins the
  relative and its clause have a subject's shape (`Chi dorme mangia` was
  refused: with no noun in the clause, `chi dorme bene` read only because `bene`
  is a noun, tr_subject_shape/4); and a denial after a relative clause inside a
  clause of `that` is that clause's (`prevede che chi ha partecipazioni ... non
  possa essere membro del governo` -- the relative clause's verb was counted as
  the clause's, the denial went to `prevede`, and the sentence was refused:
  tr_negation/4 and tr_relative_opener/1; a guard, `Il cane che mangia non
  dorme`).
  It needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Italian `intreccio` (an
  interweaving, Spanish `entramado`), `holding` (the holding company, feminine,
  as Spanish's masculine `holding`), `vicepresidente` (a person), `oligopolio`,
  `pro` (in favour of, a preposition, with `a favore di` said first and Spanish
  `a favor de`), `cassa` (quashes, with its forms -- the dictionary has the noun
  only -- and Spanish `anula`, its plain `cancels` said first), `cordata` (a
  consortium, `consorzio` said first), `votante` (a voter, a person), `quota
  azionaria` (a shareholding, Spanish `participación accionarial`), `incide`
  (influences, `su` before the phrase, `influenza` said first), `management`,
  `tivù` (`televisione` said first), `cerca` before an infinitive (tries,
  `tenta` said first as the word written for it and its plain `searches` first),
  `provvedimento` (a measure, `misura` said first), `via etere` (terrestrial, an
  adjective of two words), `sulla base di` (on the basis of, Spanish `sobre la
  base de`), `nella misura in cui` (insofar as, Spanish `en la medida en que`),
  `elegge` (elects, where the dictionary's first was chooses, `sceglie` said
  first), `potere` (power, where the dictionary's first was a fortress -- the
  Tatarella interview's `poteri forti` were `fortalezas fuertes`), `disegno` (a
  drawing before the dictionary's cartoonist, a person: `il disegno sul
  conflitto d'interessi` was `el dibujante`), `interlocutore` and Spanish
  `interlocutor` (an interlocutor, where both dictionaries have a speaker),
  `rete` (a network first, the net after it: the controls' `rete 4`, `la rete
  commerciale`), `prende di mira` (targets), `ha in mano` (holds), `si tiene`
  (keeps, `mantiene` said first), `sbagliato` (wrong, an adjective; the
  dictionary has the participle only), `a suo rischio` (at his own risk, Spanish
  `a su riesgo`), `più di` and `meno di` (more than, less than, one adverb, as
  Spanish's `más de`; Spanish `menos de`), `a meno che` (unless, Spanish `a
  menos que`), and `"sceglie" takes the question.` (Spanish `elige` and
  `escoge`); and Spanish `tiene` (holds, its plain `has` said first: the
  writer's first Spanish verb for it was `aguanta`, endures) and `sujeto` (a
  subject, said again first: the writer's first Spanish noun for it was `tema`,
  a topic). The first meaning moved in 6 Italian words and 1 Spanish one
  (Italian `disegno` a drawing, `interlocutore` an interlocutor, `potere` power,
  `provvedimento` a measure, `rete` a network, `elegge` elects; Spanish
  `interlocutor`), and none was lost.
  THE CONTROLS (cocolog 2.11.0, store KB201, 98 count files, 2 756 sentences:
  the earlier set with the Inter feature in, es_20011002-160, both directions;
  this interview is not among them): the last version's translator against this
  one, on the one store, 38 sentences in 19 files read differently, all better
  -- `between` for a pair (21: `the fusion between Carrefour and Promodès`,
  `between Meridiana and Aragó`, `between the three and the five of the
  afternoon`, `asymmetries between accusation and defence`), the speaker's
  apposition with the speaker (5: es_20010202-169 12, `Claude Lebet, one of the
  most acknowledged luthiers, said`; es_20020601-51 14, a piece of a sentence
  refused, `Roger Lemerre, the French technician, said`; it_9851_9925 2,
  it_9926_9946 16, it_9947_9966 14), `does it` and `did it` for `makes him` (5:
  es_19990802-48 9, `they have done it`; it_10059_10095 7 and 8, `I do it
  voluntarily`; it_9967_9998 25; tat 283), `It is not possible to make a
  replica` (es_20010202-169 11) and `it was crazy to attempt` (it_9967_9998 28),
  `whether it is legitimate to write` (it_9775_9780 1), the agents of
  it_9637_9672 8 (`presided by Pierre Carniti and presented by the minister`, in
  both languages; English writes the sentence `The dramatic picture ... is
  this.`, where the last version wrote `It is this the dramatic picture ...`),
  and it_9637_9672 7, refused before and read now in both languages (`menos de
  la mitad de lo que gasta`) -- and the inferences rise 0.050 % (5 403 216 416
  to 5 405 933 404). The sentences that rise most are it_9567_9604 20 (+0.78
  million of 6.26 in each language), it_9851_9925 32 (+0.14 of 38.2),
  it_9673_9712 20 (the one that runs to the limit, +0.07 of 516.7), it_9472_9484
  10 and it_9270_9295 9 (+0.06 each); the ones that fall most are it_9637_9672 7
  (8.67 million to 6.26, read) and 8 (1.70 to 0.55). Bytes and characters read
  every sentence alike (0 differ, the bytes 0.018 % more). The DATA COLUMN (the
  last version's translator on its own store, KB195, against this one on the
  new): 59 sentences in 26 files, the 38 of the code and those of the words, and
  the inferences rise 0.096 % (5 400 766 799 to 5 405 933 404). THE CODE ALONE
  (this translator on the old store): 36 sentences in 19 files, +0.112 %. THE
  STORE ALONE (the last version's translator on the old store and on the new)
  differs in 25 sentences in 12 files, +0.045 % of the inferences, each a word
  of the interview's lines, all better but one: `potere` is power (it_9714_9749
  18 and 21, `the strong powers`, `los poderes fuertes`, where they were
  fortresses), `rete` a network (it_9270_9295 11 and 26), `provvedimento` a
  measure (it_9750_9762 10, `ninguna otra medida`), `cerca di` tries
  (it_9673_9712 13, it_9781_9791 5, it_9511_9539 4: `has tried to close the
  games`), `più di` more than before a count (it_9637_9672 13 and 17, `more than
  65 years`; es_19990901-75 17 has Spanish's `menos de`), `a favor de` in favour
  of (es_19991001-61 20), Italian `teneva` and `tenere` as `tenía` and `tener`
  where they were `aguantaba` and `aguantar` (it_9851_9925 55 and 65,
  it_9947_9966 6 and 20) -- and it_9637_9672 7, refused with the old code: the
  line joins `meno di` and only the new code takes it apart before `la metà`.
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of every column and
  mended. Of the store alone (42 sentences): four of the interview's lines came
  first for the writer of the other language -- `si tiene` (keeps) made every
  Spanish `mantener` the Italian `tenersi` (`mantener a Reina` was `tenersi
  Reina`, `la posición que mantiene` `che si tiene`) and three sentences of the
  controls were refused (es_19990601-23 1, es_20000802-31 4, es_20010103-139 7),
  `pro` was the Italian for `a favor de` (`si votò pro la proposta`), `tivù` for
  `televisión` and `cerca di` for `trata de` (`non cerca di convincere`, where
  it was `tenta di`) -- and the dictionary's own word is said again first for
  each: `mantiene`, `a favore di`, `televisione`, `tenta`; a line for `soggetto`
  as an entity was taken out, because an earlier sample's line says it is a
  subject first (the people of `molto attento verso i soggetti`), and `sujeto`
  is the Spanish writer's word for a subject now. Of the code (49 sentences):
  the question's adverb before its subject, first written in fo_subject_after/5,
  changed four inverted statements its other readers read with it -- `Fue
  entonces el momento de homenajear a dos personajes ...` was `The moment went
  moment of honouring` (es_19990701-83 7, both languages), `si chiama infatti
  assistente ai bagnanti` (`se llama ayudante a ayudante`, it_9381_9414 11),
  `deve finire in tribunale l'arcivescovo di Monreale` (`the archbishop must
  finish of Monreale ... in court`, it_9465_9470 3), `Godranno ... soltanto
  quelli che hanno scelto` (`Those will enjoy ... only that they have chosen`,
  it_9472_9484 9) -- and it stands in fo_unfront/3 now, the question's reader,
  where the comma form of it went (a question is read with its commas out, and
  its arm was green); `does` had no past and no participle of its own, `they
  have doed it`; and the pair of prepositions took `cerca` for one, `placed wall
  or within a vehicle` (es_20010102-25 6). A clause for `whether` after an
  infinitive that takes the question (tr_complements_after_inf/5) had no arm
  that went red, nor changed a sentence, and is gone.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the nine sentences that
  rose most on the one store, into English, over a copy of the library per rule
  on KB201): they rose 1.25 million inferences, and three rules are 90 % of it
  -- the taking apart of `più di` (0.77 million, 0.75 of it in it_9567_9604 20,
  `Casotto, che ora giura che non si occuperà mai più di boxe, sostiene una
  teoria ...`: 7.01 million inferences on the old store, 6.26 with the new line,
  which joins `più di`, and 7.04 now, the two words read as they were before the
  line -- +0.4 % against the old cost, and refused all the way), a denial after
  a relative clause inside a clause of `that` (0.23 million: it_9851_9925 32
  +0.12 of 38.2, it_9472_9484 10 and it_9673_9712 10 +0.05 each, where the
  denial stays with the clause and more readings are tried) and `whether` and an
  infinitive (0.16 million, a few thousand a sentence, asked at every word for
  `if` after a verb that takes the question); the rest is under 0.02 million
  each (`unless`'s expletive 18 thousand, a day before the agent 13 thousand).
  THE STATED COSTS: a first meaning that serves the news and not every text --
  `rete` is a network (a football report's goal is a net second), `disegno` a
  drawing (the bill is `disegno di legge`, and a bare `disegno` for it is still
  `dibujo`), `potere` power, `provvedimento` a measure, `elegge` elects,
  `interlocutore` an interlocutor, Spanish `tiene` the writer's word for holds
  (`teneva` is `tenía`, and `si terrà un'iniziativa` is `se tendrá`); the
  inferences, +0.050 % on the one store; and the nineteenth sentence, refused
  after 773.1 million inferences in each language as it was (`bisognerà
  impegnarsi per una legge che disciplini il mondo ... tenendo conto sia della
  corte costituzionale, sia dell'esito dei referendum sia infine delle reali
  condizioni del mercato, ..., figuriamoci se potrà farlo per 15.`): `tenere
  conto di` is no word of the lesson, `sia ... sia ... sia infine` is three, and
  `figuriamoci se` is an idiom; a line for `tiene conto di` read `tenendo conto
  del gatto` and left the sentence refused, so it is not in -- the next sample's
  controls carry its 1.5 billion inferences. The interview LEAVES, of the 31
  into Spanish (English alike unless it says): `rapporto` is a report, never the
  relationship between two things (3); `Nei giorni "caldi" delle trattative` is
  `"Calienten" de las negociaciones ... en los días` (4: an adjective in
  quotation marks after its noun is read as a verb); `il disegno sul conflitto
  ... varato giovedì dal senato` after the verb is `el dibujo en el conflicto
  ... desde el senado` (5: with the subject after the verb the agent is not
  read); `grande esperto di media` is `gran experto de media` and `big expert of
  average` (6), and `definire delle regole` keeps the partitive (`definir de las
  reglas`); `com'è naturale` stands last and `chi ha in mano` is `de quién
  tiene` (7); `Sarebbe sbagliato leggere` is `To read ... would be erred` in
  English (8: the participle is read before the adjective); `pensare ... al
  futuro` is `pensar al futuro` and `think to the future` (9), and `valori
  democratici` `valores demócratas`; 10 (`Generali per quanto siano, le regole
  investono adesso proprio le tv Fininvest`) is word by word, `Generales para
  cuanto son ... invierten ... propias`; `ci siano, nelle mani di un unico
  soggetto, tre reti` is `hay` and `they there is` (13); `un vero pluralismo` is
  `un cierto pluralismo` (15); `tanti soggetti` is `so much subjects` (16); `c'è
  stato` is `había` (17); 20 moves `come suggerisce il "progetto Bogi"` to the
  end in English; `lo fa a suo rischio` puts `at his own risk` last (22); `lo
  risolverebbe` is `resolve him` (24, the clitic of a thing); `resta azionista`
  is `queda a accionista` and `influencing on the choices` (26: the infinitive
  is a noun's complement there, and the governing verb is not found);
  `continuare a controllare` is `continuar a controlar` (27) and `una società` a
  society; `¿Qué debería Berlusconi hacer entonces?` (28) and `hacer al hombre
  de gobierno` (29); `entro un anno` is `I enter a year` in English and `entro
  un año` in Spanish (30: in the long sentence `entro` is read as the verb,
  where `si liberi entro un anno` alone reads it as the preposition), and `si
  liberi` is the impersonal `one releases`; `eletto` is `elegida` and
  `segretario di partito` `secretario de fiesta` (31: the Spanish writer's first
  noun for a party is a fiesta, and `partido` is a match first); and
  `l'Antitrust proyecto de ley`, `iniciadas desde el presidente` (32: the agent
  after a coordinated object is not read). The next sample's controls take this
  interview in.
  The Rognoni interview's faults (reasoning 1.0.13; cocolog stays 2.11.0; no new
  article). Four faults the interview left, fixed in code and data, each with
  its arm red (test/translate.pl's `rognoni_faults`: 14 checks, 7 arms that go
  red and 3 rules that have none, below; lesson 46's section 76): A NOUN THAT
  CAN SAY A RELATION SAYS ONE BEFORE `between` OR `with` (`Milano - rapporto
  difficile, tra Berlusconi e le regole` was `difficult report`, `informe
  difícil`: a noun whose first meaning is no relation and that has
  `relationship` or `relation` among its other meanings, en_relational_noun/1,
  crosses by it before a phrase of `among`, `between` or `with`,
  tr_relational_np/3 -- in the complements, tr_cross_comps/2, in a phrase with
  its phrases, with/2, a subject's too, and in a headline's two halves,
  tr_cross/3's gap/2: four arms, and the first meaning's own guard has none; `Il
  rapporto della commissione` is the report still); A PREPOSITION IS NEVER
  ELIDED BEFORE A DEFINITE ARTICLE (`sin el gato` was `senz'il gatto`: `"senz'"
  is the elision of "senza".` in the vocabulary, and a preposition elides before
  any article, `d'un buon stradivari`, which stays; tr_opens_next/2); A MAIN
  CLAUSE NEVER STARTS AT A WORD THAT IS A PREPOSITION TOO (sentence 30's `e a
  meno che non si liberi entro un anno` took `entro`, I enter, for the main
  clause after the clause of `unless` with no comma, `I enter a year` and `entro
  un año`: tr_main_start/2, which both readers of that shape ask, the sentence's
  and a nested clause's), and the right side of a coordinator inside a clause
  may be a subordinate clause alone (tr_nested_right/3: with no main clause
  after it the clause of `unless` had no reading inside the clause of `that`,
  and the sentence was read again from the top, 11.0 million inferences where it
  is 3.5 -- the rule has no arm that goes red and stays for that cost, as the
  text is the same; its guard, a word that asks as well, `perché`, was found by
  the controls: `può essere che Margherita abbia avuto un malore ma perché
  nessuno le ha viste?` became `can it be ... but because nobody has seen her?`,
  it_9851_9925 56, and no hand lesson reproduces it, so the guard stays for what
  the controls showed); English elides no subject of a subordinate clause
  standing alone after `and` (`and unless eats`: tr_write/4's elision, and
  English refuses the third person nobody names, on purpose); and THE PARTY'S
  WORD, data: the Spanish writer's first noun for a party was `fiesta` (`hacer
  política como secretario de fiesta`, 31) -- `"partido" means "match".` said
  again first, so that it stays a match to the reader, and `"partido" means
  "party".` after it, so that it is the party's word (Italian news has `partito`
  115 times in UD's VIT training file and `festa` 22, and every `festa` is a
  `partido` now, a STATED COST; the Spanish reader still reads `el secretario
  del partido` as `della partita`, `partido` being a match in half of AnCora's
  sentences and a party in the other half, a lead). Two lines more: the writer's
  first Spanish verb for releases was the idiom `deja marchar` (`a menos que se
  deja marchar`, and the Rosi report's `non era al corrente che liberasse
  amfetamine` was `dejó marchar`), and `"libera" means "frees".` and `...
  "releases".` are said first; and `"a menos que" takes the subjunctive.` and
  `"a meno che" takes the subjunctive.`, as the lessons say of `antes de que`
  and `prima che`, so that the clause is read and written in the subjunctive (`a
  menos que se libere`). The vocabularies lost no line and moved no word's first
  meaning; the writer's first Spanish word moved for two meanings (party,
  releases). THE CONTROLS (cocolog 2.11.0, store KB203, 100 count files, 2 820
  sentences: the earlier set with the Rognoni interview in, it_9605_9636): the
  last version's translator against this one, on the one store, 4 sentences read
  differently, all the interview's and all better -- the headline's
  `relationship` and `relación` (3), sentence 30's `before a year` and `a menos
  que se libere antes de un año` (where it was `I enter` and `entro un año`) --
  and the inferences rise 0.016 % (7 020 760 360 to 7 021 882 676), 0.006 %
  outside the interview (5 406 061 909 to 5 406 388 556): sentence 30 is 3.14
  million inferences and 3.54 now, in each language, the rest of the rises under
  2 500 a sentence. Bytes and characters read every sentence alike (0 differ,
  the bytes 0.014 % more). THE STORE ALONE (the last version's translator on
  KB201 and on KB203) differs in 3 sentences, all better, +0.0004 %: `secretario
  de partido` (it_9605_9636 31), `a menos que se lib...` (30) and the Rosi
  report's `liberaba anfetaminas` (it_9567_9604 25); THE CODE ALONE (this
  translator on KB201) in the 4 of the controls, +0.016 %; THE DATA COLUMN in 6,
  +0.016 %. The interview reads 31 of 32 into both, as it did; its nineteenth
  sentence is still refused after 773.1 million inferences in each. What is left
  of sentence 30: `si liberi` is the impersonal `one releases` in English,
  `dall'assunzione della carica` is `from the intake of the charge` and `de la
  ingesta del cargo`, and `eletto` is still `elegida` in 31.
  The banks' Saturdays report (AnCora CESS-CAST-P-19990601-98, 12 sentences,
  Spanish into Italian and English: 12 of 12 and 11 of 12 on a fresh store, 11
  and 10 with the new store alone, 9 and 9 with the new code on the old store, 9
  and 9 before; reasoning 1.0.14). The sample was taken on the cocolog 2.11.1
  binary, master's 870bcb9 merged as 3e3e83a, and cocolog stays 2.11.1: the
  binaries of 2.11.0 and 2.11.1 give the same texts and counts to the unit on
  the controls (7 021 882 676 inferences, 0 differ). Master's 2.11.2 (dd53f69,
  Cicili 3.1.0's `(cold)`) came during the sample; it needs Cicili 3.1.0, the
  checkout here is 3.0.0 and cicili is frozen, so it is not merged, and the next
  sample takes it. The article's sentences fall from 26.0 to 15.0 million
  inferences into Italian and from 25.5 to 14.5 into English.
  It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_bank`: 30 checks, 33 arms, the guards among them, and two arms more
  that are red in the whole case alone, below; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM
  cocolog query "use_module('test/translate.pl'), newspaper_bank, checks_done"`,
  three seconds a run): a verb with its own pronoun crosses by the meaning the
  lesson gives it so (`la apertura se ha convertido en el elemento negociador`
  has BECOME it, and it was `has converted in`: `The reflexive verb "convierte"
  means "becomes".`, the class linked in tr_mean_links/3 as the infinitival and
  adjectival ones are, tr_verb_across/5), and the phrase it governs is that
  meaning's (tr_cross/3's `$tr_gov_sense`), which English writes bare
  (en_bare_object/1) and Italian with no preposition where the verb written
  states none (`è diventata un problema`, tr_comp_out/7) -- five arms;
  `converts` governs `into` and `centres` `on` (en_governs/2); a comparison
  whose second term is an adverb (`en las mismas condiciones que en la
  actualidad` is in the same conditions as currently: `en la actualidad` is one
  adverb, and with no preposition after `que` the comparison had no reading,
  tr_complements0/4 and cmpp/3 with adv/1, two arms); a participle and its
  phrase right after the verb say how the verb leaves the phrase (`que mantiene
  bloqueado el convenio colectivo del sector bancario` keeps the collective
  agreement OF THE BANKING SECTOR blocked, `una estatua tiene levantado el brazo
  izquierdo` has the left arm raised: tr_abs_first/2 makes the clause's first
  absolute clause abso/2, which English writes phrase first, its phrases of `of`
  with it, tr_of_run/3 -- three arms, and two guards: the first complement only,
  or `dopo aver mandato in onda l'ultimo punto` is `after having the last dot
  broadcasted`, and never a participle English puts before a phrase as a
  preposition, en_prepositional_participle/1, `given`, `seen`); a day of the
  week alone is `on` it (`los sábados`, tr_comp_out/7's at_time/1); `the
  employers` take the plural verb (en_collective_plural/1); an intransitive verb
  has its subject after it in a relative clause (`la hora y media que duró el
  encuentro` is the hour and a half the meeting lasted, tr_rel_doer/2, `"dura"
  is intransitive.`), never after `lo que`, the subject itself (`lo que ocurrirá
  esa fecha`, a guard the controls found); an aside between dashes that ends the
  sentence may follow an adverb (`por las tardes - - iniciativa que consiguió
  pactar con la dirección - -`, tr_asides/3); `attains` before an infinitive is
  `manages` (`consiguió pactar`, `riesce a giocare`, tr_verb_out/4); `al que`
  after an adjective that takes the word for `to` is the adjective's phrase (`un
  horario similar al que desarrollan las cajas de ahorros` is similar to the one
  the savings banks keep, tr_np/3 with ell/4, and a guard, `la casa a la que va
  el perro`); the adverbs English writes last stay inside a quotation that
  closes on the last complement (tr_close_after_advs/3); the adjectives the
  source put after its noun are written the other way round in English (`la
  patronal bancaria española` is the Spanish banking employers, en_adj_order/3:
  a degree and an adjective the source put before its noun come first, as they
  stood, `un mejor trato fiscal`, `un nuevo acuerdo laboral colectivo`, and a
  list with a name, a coordinator, a quoted word, a noun that says what kind or
  an adjective that keeps a number of its own keeps its order -- three arms, the
  guards the controls found), and the lesson's language writes the plain
  adjectives an ENGLISH source put before its noun the other way round, so that
  a round trip comes back as it went (`the big red house` is `la casa roja
  grande`, which is the big red house again, where `la casa grande roja` was the
  red big house: tr_foreign_adj_order/3, an arm red in the whole case) -- asked
  of the side the text was READ on, `$tr_read_side`, because every writer finds
  `$tr_from` set to english, and asked of that the first cut turned 25 sentences
  of the controls round between Spanish and Italian (`la televisione catalana
  pubblica`, `la terapia psiquiátrica médica`); an object after the phrase of a
  preposition, last in its clause, comes before it (`que denunció ante la
  Audiencia Nacional este acuerdo`, tr_comps_out/7: a phrase or a name after the
  preposition, never `of`, and an object with a determiner or a count -- four
  arms, three of them the guards the controls found, and a fifth red in the
  whole case: never after the phrase of `to` of a verb English writes with a
  bare dative, or the basketball report's rule, `costs the dog a book`, wrote
  `costs a book to the dog`); a unit of time after a time is how often (`una
  tarde a la semana` is an afternoon a week); and an adverb between commas right
  after an apposition is an insertion (`El portavoz demócrata, John Conyers, por
  su parte, criticó`: the apposition took the comma that opens it, and `por su
  parte`, one adverb now, went to the end of the clause, tr_insertion_off/4 --
  found in the store-alone column). A guard for a linking verb's auxiliary
  (en_linking_verb/1) had a green arm and changed no text and no count on the
  store, and was taken out.
  It needed these WORDS in `extra/`: Spanish `convierte` (converts, and becomes
  with its pronoun; `en` before the phrase), `negociador` (negotiating),
  `sucursal` (a branch office), `sindicato` (a trade union), `caja de ahorros`
  (a savings bank, a group), `flexibiliza`, `pacta` (agrees), `no obstante`
  (nevertheless), `por su parte` (for its part), `así` (thus), `cuenta con`
  (has, with its forms), `denuncia` (denounces), the name `Audiencia Nacional`,
  `centra` taking `en`, `dura` (intransitive), `de forma que` (so that, with the
  subjunctive), `por las tardes`, `por las mañanas`, `por las noches`, `mesa de
  negociación` (a negotiating table) and `consigue` (achieves, and attains
  before an infinitive); Italian `negoziale`, `negoziatore` and `negoziatrice`,
  `filiale` (a subsidiary said again first, then a branch office), `sindacato`,
  `cassa di risparmio`, `flessibilizza`, `da parte sua`, `centra` taking `su`,
  `in modo che` and `senza che` with the subjunctive, `di pomeriggio`, `di
  mattina` and `tavolo delle trattative`. The first meaning moved for 4 Spanish
  words and 1 Italian one (Spanish `así` thus, `sindicato` a trade union,
  `sucursal` a branch office, `denuncia` denounces; Italian `sindacato`), the
  writer's first word for no meaning, and none was lost.
  THE CONTROLS (cocolog 2.11.1, store KB206, 100 count files, 2 820 sentences:
  the earlier set with the Rognoni interview in, both directions; this report is
  not among them): the last version's translator against this one, on the one
  store, 55 sentences in 37 files read differently, 47 better and 8 no worse --
  the English adjective order (29, 22 better: `the Catalan public television`,
  `the free juridical assistance`, `the already existent pedestrian zone`, `the
  Basque socialist leader`, `the German financial institution`, `the European
  Space Agency`, `the American daily newspaper`, `the French nuclear
  experiments`, `a frightful public debt`, `the richest oil employer`), `on`
  before a day (7: `begins on Thursday`, `celebrated on Monday at night`, `On
  Tuesday everyone around the table`), the object before a phrase (7, 6 better:
  `will watch this operation "with special attention"`, `has demanded the
  maximum concentration from the players`, `would have accepted the defensive
  line in full`), the adverbs inside their marks (2), `manages to` (4), `has the
  left arm raised`, `convert into`, `will become a ballast` and `diventeranno
  una zavorra`, and `John Conyers, for its part, criticised` in both languages
  -- and the inferences rise 0.002 % (7 022 280 308 to 7 022 430 135). No worse,
  and no better (8): a participle with its phrase reversed with the adjectives
  (`the realised murderous crimes against`, `a priced economic value in`, `an
  addrest symbolic initiative to`, `the proprietary French groups of Pryca`),
  `the norman Arab cathedral`, `the psychiatric medical therapy`, `the medicine
  jurisprudence university didactic improvement`, and tat 350, `You should give
  him your son more freedom` (`more freedom your son`). Bytes and characters
  read every sentence alike (0 differ, the bytes 0.014 % more). The DATA COLUMN
  (the last version's translator on its own store, KB203, against this one on
  the new): 84 sentences in 54 files, +0.008 % (7 021 882 676 to 7 022 430 135).
  THE CODE ALONE (this translator on KB203): 50 sentences in 34 files, +0.037 %
  (to 7 024 469 047), every one of them among the 55; the five left need the new
  lines (`por su parte`, `convierte`). THE STORE ALONE (the last version's
  translator on KB203 and on KB206): 31 sentences in 23 files, +0.006 % (to 7
  022 280 308) -- the subjunctive after `para que` and `sin que` (`acceleri`,
  `possa`, `causi`, `noti`, `apparissero`), `thus` for `así` where it was
  `thereby`, `While the jobs last`, `the trade union of the togas`, `has 3,000
  subscribers` and `will have bonuses` (es_20000701-80 18, read into English
  now), the Spanish writer's `conseguir` for Italian's `riuscire` where it was
  `lograr` (8, no better and no worse), and two worse: `por su parte` after an
  apposition went to the end of its clause (es_19981202-34 9, both languages:
  the shape above mends it) and `pueden contar con su colaboración` is `they can
  have their collaboration` and `possono avere` (es_19991001-61 17, a stated
  cost).
  Seven expectations of the older sections of test/translate.pl and two of
  lesson 46 were written in the old English or the old order and changed with
  the rules (`on Saturday` in both files, `bought on Sunday`, `that on Sunday
  eats`, `On Tuesday the summit.` in both files, `put the house in danger`, and
  the round trip's `la casa roja grande`, twice).
  THE FIRST CUTS' REGRESSIONS, found by reading the texts of the controls and
  mended: the object before a phrase took the phrase of `of` (`Roma of Corrado
  Sannucci`, five bylines; `to hold the pools of eye`; `for the leader an
  important stage of the olive`), a bare number (`I will not go 4 to the Tg`,
  three) and a bare noun (`without more company`, `knew how to face serenity
  with more`) and an adverb after the preposition (`be able to know little time
  in so`); the adjectives reversed with a degree (`a fiscal better treatment`,
  `his liceistic best nights`) and with a noun that says what kind (`the
  magistrate national association`); the absolute clause written phrase first
  anywhere (`advances the choices in Euskadi the situation of minority of his
  Executive given`, `the very critical opinion seen`, `after having the last dot
  broadcasted`); and the intransitive doer after `lo que` (`what that date will
  occur`). THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the seven
  heaviest rises of the controls, into English, over a copy of the library per
  rule): the first cut was +0.693 % of the controls, and one rule was all of it
  -- the clause of tr_np/3 for `al que` after an adjective, whose search for a
  preposition, an article and a relative word walked every phrase it was asked
  and parsed the words before them as a phrase (the seven 52.98 million
  inferences to 60.41; without the clause 52.99). A note made once a sentence,
  `$tr_adj_rel` (an adjective, a preposition, an article and a relative word,
  tr_adj_rel_note/1), and the adjective's test before the parse leave the seven
  at 53.01 million (+0.04 %), the note itself and the clause in the one sentence
  that has the pattern (`con el grupo social al que pertenece`: 1.20 million to
  1.21) and the comparison with an adverb most of it (10 thousand). The second
  cut was +0.027 %, and nearly half of it one sentence that the seven did not
  hold, found by the same arms over it: es_20000903-30 18 rose 0.88 million
  inferences of 85 in each language, the comparison with an adverb read in a
  piece cut after `que jamás` (`el instrumento más amplio de convivencia que
  jamás han tenido los vascos`), a reading the long search then gives up, the
  text the same. An adverb that a verb follows in the piece is no term now (a
  guard with no arm that goes red, which stays for its cost; a guard on the
  words after the adverb in the cut piece moved nothing, as there were none),
  and the sentence is +0.011 %. What is left is +0.002 % on the new store and
  +0.037 % on the old: every sentence rises, by 12 inferences at least and by 36
  thousand at most (it_9605_9636 19, a refusal of 773 million), 2.58 million in
  all, and on the new store es_19981202-34 9 falls 1.21 and 1.22 million in the
  two languages (`por su parte` read at once).
  THE STATED COSTS: `contar con` is `has` (the newspaper's sense: `cuenta con
  3.000 abonados`, `cuenta con la oposición de la UGT`), so where it relies on
  someone it is `can have their collaboration`, and English refuses
  es_20000102-120 6, which it read as the imperative `count on` (now the third
  person nobody names); `for its part` for a person too; the Spanish writer's
  `conseguir` for attains; and the inferences, +0.002 % on the new store and
  +0.037 % on the old.
  The report LEAVES, of the 12 into Italian: `i sabati` (il sabato),
  `mantennero` (tennero), `il beneficio del servizio` (la prestazione), `auspica
  per la situazione` and `che attualmente`, `la sua volontà a flessibilizzare`
  (di), `in España`, `Eppure` (Tuttavia), `un prossimo appuntamento ... per l'8
  giugno prossimo`, `risposta positiva alcuno` (an adjective after its noun with
  `alguna` does not agree), `fino al momento` and `dall'inizio delle trattative`
  written after the purpose; of the 11 into English: `Thus one checked in the
  meeting ... yesterday` (the impersonal `se`, and `ayer` last), `the editorial
  of a new labour agreement` (the drafting), `the closure of the Saturdays`,
  `the benefit of the service`, `for the banking`, `realising their managements
  ... Saturday morning`, `advocate for the situation`, `like alternative to
  close`, `the instauration`, `the one that develop the savings banks` (the doer
  after a relative clause with a comma before it), `his willingness` (CCOO's),
  `the labour schedule`, `initiative that managed to agree` (the relative word
  is the infinitive's object), `in front of the Audiencia Nacional`, `The
  managers of banking` and `have summoned a next appointment`; English refuses
  12 for the third person nobody names, on purpose. The next sample's controls
  take this report in.
  The Venice canals report (VIT-9999..10010, 12 sentences, Italian into Spanish
  and English: 12 of 12 and 12 of 12 on a fresh store, 12 and 12 with the new
  store alone, 3 and 3 with the new code on the old store, 3 and 3 before;
  reasoning 1.0.15). The sample was taken on the cocolog 2.11.2 binary, master's
  dd53f69 merged as d67fb41 with Cicili pulled to 3.1.0 (cc24ae0), which its
  `(cold)` needs, and cocolog stays 2.11.2: the binaries of 2.11.1 and 2.11.2
  give the same texts and counts to the unit on the controls (7 022 430 135
  inferences, 0 differ); master's next two commits, documentation only (97445a2,
  STATUS.md; 6f1f18d, bench/README.md), were merged as 7498830 and c989b20. The
  new store alone reads every sentence -- its words were all that refused them
  -- and with the old code writes 10 of the English texts and 7 of the Spanish
  wrong in the ways the shapes below mend (`rests on the fund of the canals,
  which result more polluted of those of the close industrial zone ... even`,
  `have found you the presence of good 11 different poisons: 8,737 kiloes of
  nickel, 7.496 of chromium`, `Still seem, far anyway when one will be able to
  return swim in the canals like forty years, ago when`; `como cuarenta años
  hace`, `os han encontrado la presencia de bien 11 venenos`). The article's
  sentences fall from 3 872.8 million inferences in each language (the base
  capped at 3 billion a sentence: its eighth ran past 25 billion uncapped and
  was refused) to 603.0 into Spanish and 602.8 into English, of which the eighth
  is 394.2 million and the fourth 124.4. It needed these SHAPES, each with its
  arm red (test/translate.pl's `newspaper_venice`: 77 checks, 79 arms, the
  guards among them; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_venice, checks_done"`, a second a
  run, and every arm is run in two minutes, four at a time): `del` after a first
  name and a surname, before an acronym, is the preposition and its article
  (`Roberto Zonta del Cnr e Mario Scattolin del comune` are of the Cnr and of
  the town council, and joined it was one name, tr_particle_names/4; before a
  word with a vowel after its capital it stays the name's, a guard, `Joseph
  Guarnerius del Gesù`, tr_acronym_word/1); a connector the lesson states as an
  article, a noun, a preposition and the relative (`il giorno in cui`, `el día
  en que`, the lesson's `when`) is taken apart after a verb into the phrase and
  its relative clause (`Sembra ancora lontano, comunque, il giorno in cui si
  potrà tornare a fare il bagno` was `Still seem, far anyway when one will be
  able`, tr_unjoin_when/3), never at the head of a clause or after a conjunction
  (two guards), and the time's reader leaves the relative to the phrase's
  readers (tr_complements0/4) -- four arms; English writes `when` after a time
  for `in which` (tr_relative_out/5); a verb of seeming with its predicate, and
  an adverb between commas, before its subject (`Sembra lontano, comunque, il
  giorno ...` seems far, anyway: a clause of tr_read_statement0/4, and the
  adverb with its comma written last, tr_comps_out/7 -- three arms); `ends up`
  with nowhere to end up is `ends` (`le sorprese non finiscono qui` do not END
  here, the lesson's intransitive `finisce` being `ends up`, which `deve finire
  in tribunale` needs: tr_write/4 for the verb and its infinitive,
  tr_ends_up_where/1 for a phrase, a predicate, an adverb of place of several
  words -- four arms, two of them guards); a reflexive verb that shows what one
  is, with a predicate, is `appears` (`i Tecnici ... si mostrano ottimisti` was
  `display optimistic`), and with nobody named after `e` no passive whose
  subject is the bare adjective (`optimists are displayed`,
  tr_predicate_after_reflexive/2) -- two arms; `results` before a predicate is
  `turns out` (`i quali risultano più inquinati`); a verb of several words that
  ends in a preposition takes its phrase bare (`si occupa della sistemazione`
  was `takes charge of of the arrangement`, en_bare_object/1), and no phrase of
  an insertion is one the clause's verb governs (a guard the controls found:
  `Navarro, en un momento de forma excepcional, se encargó de` was `in a moment
  exceptional form`, tr_ungoverned/2); no article before a percentage in words
  (`pari all'87 per cento del totale`, tr_det_out/6); a range of years between
  two commas is from and to (`per dieci anni, dal 1994 al 2004, hanno scavato`
  was `since 1994 to 2004`, tr_cross_comps/2); a count of time after a
  preposition takes its `ago` with it (`come quarant'anni fa, quando c'era` was
  `like forty years, ago when there was`, and Spanish, whose `hace` begins the
  time, `como cuarenta años hace`: tr_ago_phrase/2, ago/2, crossed and written
  by each language, the marks of a quotation that closes on the time moved to
  its last word -- six arms), in the phrase of `of` of a phrase whose noun is
  left out too (`inferiore a quello di trenta anni fa`, `al de hace treinta
  años`); `ben` before a count says how many (`la presenza di ben 11 veleni
  diversi` is as many as 11, and read as the noun `bene` the presence was of a
  good: tr_complements0/4 for an object and for the phrase of a preposition,
  tr_count_adverb/1, advp/2 -- an adverb the lesson says means `as many as` too,
  Spanish's `nada menos que`, which was `finds 11 poisons as many as` -- crossed
  as `as many as` and written by the lesson's word for it, or the count alone
  where it states none: six arms); a noun that can say the bottom of a thing
  says it before a phrase of `of` with a determiner (`giace sul fondo dei
  canali` rests on the BOTTOM of the canals, `fondo` a fund first:
  tr_relational_np/3 in the phrase of a preposition and in the phrase of `of` of
  a phrase whose noun is left out, `qual'è quella del fondo dei rii`, and the
  phrase of `of` definite with its relative clause, tr_head_definite/1 -- five
  arms, one a guard: `il fondo di investimento`, with no determiner, is a fund);
  the copula left out after a comma (`i motori sono più efficienti, le benzine
  senza piombo, gli antivegetativi meno dannosi, i detersivi quasi tutti
  biodegradabili` -- read as the copula's objects, English wrote `the least
  harmful antifouling paints` and `the detergents everyone biodegradable
  almost`: tr_gapping/2, gapc/2, the last adjective of a phrase with nothing
  after it its predicate and its superlative the comparative it says, `tutti`
  all of them -- four arms); the partitive after the impersonal `si` is what is
  done (`si stanno installando delle fosse settiche` was `are installing of the
  septic tanks`, tr_si_partitive/2), and English elides no subject before such a
  clause after `e` (`the detergents were installing septic tanks`, tr_write/4)
  -- two arms; the word that begins the cause, an adjective and a clause of
  `che` are a concession (`Per strano che possa apparire` was `For strange that
  can appear`: conc/3, crossed by tr_cross_comp/2, English `however strange it
  may appear` with the modal `may`, the lesson's language as it stood with the
  clause in the subjunctive, `Por extraño que pueda aparecer` -- two arms); a
  thing's reflexive in the perfect is the passive's perfect, in a relative
  clause and after a comma (`tonnellate di piombo ... che si sono depositati`
  was `have deposited`: tr_se_passive_rc/4, tr_phrase_nrc/3, and fo_group/8
  writes the reflexive's perfect, `se han depositado` -- three arms); a phrase
  of `of` right after a participle English writes with one is the participle's
  (`altre città europee dotate di canali` are endowed WITH canals, `un "tesoro"
  tossico fatto di tonnellate di piombo` was `a made toxic treasure of tons of
  lead`: tr_of_participle/2, en_of_participle/1, tr_participle_adjunct/4 for a
  subject's phrase, en_governs/2 -- three arms); an adverb before the word for
  `than` (`più inquinati persino di quelli della vicina zona` was `more polluted
  of those ... even`, tr_comparison_seps/3); `vi` before a verb with an object
  of its own is `there` (`e vi hanno trovato la presenza di ben 11 veleni` was
  `have found you the presence`: tr_there_clitic/3, never with a verb of giving
  or telling, en_dative_verb/1, nor with no object -- three arms, two of them
  guards); in a denied clause `tanto ... quanto` is `not so much ... as` (`would
  not derive both from ... and from` said it came from neither, tr_both_pair/3),
  and the two halves are the verb's when each opens on the preposition it takes
  (`no derivaría tanto de los vertidos como de una contaminación`, where Spanish
  wrote `desde`, tr_governed/3) -- two arms; `even` before the phrase of a
  preposition is said of it (`e persino di arsenico`, tr_comps_out/7), and so is
  `also` that opens an insertion on one (`tende, anche con l'aiuto dell'acqua
  salmastra, a facilitare` was `also tends, with the help`: tr_pull_adverb/3 and
  a clause of tr_comps_out/7 -- two arms); `therefore` stands with the verb
  (en_mid_adverb/1); a participle and the adverb that says how stand before the
  noun (`su una superficie sostanzialmente limitata`,
  tr_pre_participle_adverb/2), an adverb in `-ly` or `already`, `newly`,
  `often`, never `well`, `ever` or `never` (a guard the controls and the whole
  case found: `el Mundial más exótico jamás organizado` was `the most exotic
  never organised World cup`, and the Salvini report's `75 anni ben portati` `75
  well brought years`); a phrase whose noun is left out with a phrase of `of` is
  `that of` (`del tutto simile a quello di altre città` was `the one of`,
  tr_np_out/5), and an adjective with its phrase and the word that says how much
  before it stands after its noun (`completely similar to that of`,
  tr_adj_with_intensifier/2); `close` before a noun is `nearby` (`la vicina zona
  industriale`, tr_adjective_out/5); a number that is the phrase's head, its
  noun left out, takes English's marks (`7.496 di cromo` stayed `7.496`,
  tr_percent_style/3); a noun in `o` takes `s` (`8,737 kiloes`, `the studioes`),
  but for the few English writes with `es` (en_oes_plural/1, a guard); a
  language whose `there is` takes no definite phrase says the thing is there
  with its state copula (`non c'è più il carbone` was `no hay más el carbón`:
  `"hay" takes the indefinite.`, the writer of tr_write/4 -- three arms, two of
  them guards: an indefinite phrase keeps `hay`, and so does the past, `c'è
  stato il referendum`, which the controls found as `estuvo el referéndum`); an
  adverb the IR has after the complement that closes a quotation stood outside
  it (`mentre oggi l'inquinamento "è inferiore a quello di trenta anni fa"` was
  `... ago today"`, tr_write/4); `until` after `from` is `to` in English (`dal
  lido fino a San Marco`, tr_comps_out/7); an infinitive the one before it takes
  with its word is `to` and the verb under a modal too (`si potrà tornare a fare
  il bagno` was `return swim`, tr_comp_out/7); `many of which` is its clause's
  subject (`molti dei quali non venivano ripuliti` was `many of which they were
  not cleaned`, tr_quantity_gap/4); and two rules the store-alone column found,
  below: a word that is a noun too is no command where a third person is read
  (tr_third_person_command/3 asks tr_verb_form_any/1), and no two names are
  joined across a dash after a verb's third person (tr_dash_names/3). Three
  pieces of code written for the article had arms that stayed green and are
  gone: an English writer's clause for an adverb in a clause with its copula
  left out (the general one writes it in place), a guard that the impersonal
  partitive's verb takes no `di` (a verb that takes it has the phrase it
  governs, gov/2, which the rule's pattern does not match) and a guard against a
  subject in the second person plural for `vi` as `there` (its `vi` is read as
  its reflexive before the rule); a guard that kept `results` before a phrase of
  `from` was taken out unmeasured, `turns out polluted by` being the better
  text. It needed these WORDS in `extra/` (the two readers: a line moves the
  reader of one language and the writer of the other; the dictionary's own word
  is said again first where it must stay the one written): Italian `confeziona`
  (prepares, with its forms; `prepara` said again first), `policlorobifenile`,
  `antivegetativo` (an antifouling paint), `bracciata` (a swimmer's stroke),
  `zattera` (a raft, with its gender and plural), `fossa settica`, the elisions
  `trent'` and `qual'` (the source's `qual'è`), `sulle orme di` (in the
  footsteps of), `studio`, `ricerca` and `gruppo` (a study, research and a
  group, where the dictionary's first were a studio, a search and a cluster),
  `fondo` (a fund, where its first was the background; the bottom of a thing is
  the code's), `canale` (a canal, the channel second), `in fondo` (after all),
  `alla ricerca di`, `da tempo` (for a long time), `nel corso degli anni` (over
  the years), `"deposita" takes the passive.`, `metro cubo`, `d'intesa tra` (in
  agreement between), `fa il bagno` (swims; `nuota` said again first), the name
  `Consiglio Nazionale delle Ricerche`, `progetto` (a project, not a blueprint),
  `diverso` and `diversa` (different), `simile` (similar, not alike), `scarico`
  (a discharge, before the unloading), `"deriva" takes "da" before the phrase.`
  and `"viene" takes "da" before the phrase.` (so that Spanish writes `de`,
  where it wrote `desde`), and `traccia` (a trace, before the dictionary's
  stroke: below); Spanish `desastre` (said first, before `descalabro`),
  `contaminado` and its forms (polluted), `policlorobifenilo`,
  `antiincrustante`, `fosa séptica`, `tras las huellas de`, `grupo` (said again
  first, before `conjunto`), `desde hace tiempo`, `a lo largo de los años`,
  `metro cúbico`, `de acuerdo entre`, `nada menos que` (as many as), `extensión`
  (said first, where the writer's word was `prórroga`, a match's overtime),
  `"hay" takes the indefinite.`, and `"deriva"` and `"viene"` taking `de` before
  the phrase; and in the dictionaries' extras, for Italian `rest` (`giacere`,
  read only: English's `lie` is also to tell one), `pollute` and `polluted`
  (`inquinare`, `inquinato`, both ways), `pesticide`, `canal` (`rio`, read
  only), `brackish`, `continuation` (`prosecuzione`), `clean` (`ripulire`),
  `harmful` (`dannoso`), `detergent` (`detersivo`) and `footprint` (`orma`), the
  five read only, `fearless` (`impavido`), `swimmer` (`nuotatore`), `mighty`
  (`possente`), `confirmation` (`conferma`), `accumulation` (`accumulo`) and
  `curator` (`curatore`), and for Spanish `pesticide`, `fearless` (`impávido`),
  `stroke` (`brazada`), `discharge` (`vertido`) and `curator` (`curador`). The
  first meaning moved for 12 Italian words and no Spanish one (Italian `diverso`
  and `diversa` different, `simile` similar, `canale` a canal, `curatore` a
  curator, `fondo` a fund, `gruppo` a group, `progetto` a project, `ricerca`
  research, `scarico` a discharge, `studio` a study, `traccia` a trace), the
  writer's first word for 8 Italian meanings and 6 Spanish ones (Italian
  different `diverso`, fearless `impavido`, accumulation `accumulo`,
  confirmation `conferma`, discharge `scarico`, stroke `bracciata`, swimmer
  `nuotatore`, pollutes `inquina`; Spanish fearless `impávido`, disaster
  `desastre`, discharge `vertido`, extension `extensión`, group `grupo`, stroke
  `brazada`), and none was lost. THE CONTROLS (cocolog 2.11.2, store KB212, 102
  count files, 2 844 sentences: the earlier set with the banks' Saturdays report
  in, es_19990601-98, both directions; this report is not among them): the last
  version's translator against this one, on the one store, 52 sentences in 28
  files read differently, all better but three that are no worse -- `that of`
  for `the one of` (9: `that of the lifeguard`, `that of Berlusconi`, `That of
  the Tuscan archipelago`), the English plural in `-os` (7: `kilos`, `videos`,
  `virtuosos`, `violoncellos`, `euros`, `photos`), `therefore`, `also` and
  `even` where they stand (10: `would therefore transfer`, `has the right duty
  of favouring, also with coercive measures`, `even inside the roof`), no
  article before a percentage in words (`they represent 11.5 per cent`, `only 1
  per cent`, `assigns 2 per cent`), `appeared` (`the Spanish Government has
  appeared cold and reluctant`, `Rodríguez Zapatero appeared very accurate`),
  `turned out injured`, `has not ended`, `to obtain`, `to intervene`, `to
  judge`, `the bottom of the hole`, `2,000` and `2.3`, `for the first time,
  yesterday` with the source's comma, `the recently constituted town councils`,
  `moments when`, `from the day when` (`dal giorno in cui`, both languages), `or
  they lose`, `And in fact they confirm`, Spanish `están las voces`, `No están
  las sillas altas` and `"Está el jefe del estado afortunadamente"` (the state
  copula, three), and the Rosi report's 25th, refused by the last version on
  this store and read -- and the three no worse: `they have dumped him to the
  last world cups down, for this reason where` for `... cups, down for this
  reason where` (it_9540_9566 14, the adverb between commas at the end of a
  clause: the IR has `per questo` after its comma, a misreading both texts
  carry), Spanish `ni siquiera si está el asentimiento` and `¿No está el riesgo
  de discriminaciones?` for `hay el` (it_9450_9464 12, it_9816_9850 14: Spanish
  says `¿No hay riesgo ...?`, with no article). The inferences fall 0.216 % (7
  075 042 579 to 7 059 726 041) and rise 0.096 % outside the four sentences the
  code reads faster (the Rosi report's 25th, 9.9 million inferences to 1.6, and
  29th, 3.4 to 0.6, in each language). Bytes and characters read every sentence
  alike (0 differ, the bytes 0.014 % more). The DATA COLUMN (the last version's
  translator on its own store, KB206, against this one on the new): 78 sentences
  in 32 files, +0.110 % (7 051 992 814 to 7 059 726 041). THE CODE ALONE (this
  translator on KB206): 45 sentences in 28 files, every one among the 52, +0.016
  % (to 7 053 094 325); the seven left need the new lines (`"hay" takes the
  indefinite.`, `conferma` as a noun). THE STORE ALONE (the last version's
  translator on KB206 and on KB212): 34 sentences in 14 files, +0.327 % (to 7
  075 042 579), all better but the two of `conferma`, below -- `project` (6:
  `the "project Bogi"`, `a rejected project at birth`, where they were
  blueprints), `different` (6: `two different people`, `the different souls of
  the pole`), `research` and `study` (8: `the Scientific Research`, `bags of
  study`), `funds` (`with own funds`, `the necessary funds ... through a
  national fund`, where they were backgrounds), `group` for a cluster, `after
  all` and `al fin y al cabo` for `in background` and `en fondo`, `similares`,
  `wanted to swim` and `quería nadar` (`fare il bagno`), `si deriva
  dall'accordo` (`deriva` takes `da`, where Italian wrote `dell'accordo`),
  `diverse proposte`, and `leaves its traces` and `deja sus rastros`
  (`traccia`). Its cost is two sentences: the Rosi report's 25th (+8.3 million
  inferences in each language, to its refusal) and it_9270_9295 9, `Cecchi Paone
  conferma che ...` (+3.0 million, 41.9 to 44.9, the text the same), both
  `conferma` read as a noun too. THE FIRST ROUND'S REGRESSIONS, found by reading
  the texts of every column and mended. Of the code (the one store): an
  insertion's phrase was governed by the clause's verb, which English now wrote
  bare after a verb of several words that ends in its preposition (`Navarro, en
  un momento de forma excepcional, se encargó de llevar el peso` was `in a
  moment exceptional form`: no phrase of an insertion is governed now,
  tr_ungoverned/2, a guard); `del` before a capitalised word split a name (`su
  constructor, Joseph Guarnerius del Gesù, de Cremona` was `his builder Joseph
  Guarnerius of the Gesù`: only before an acronym now, tr_acronym_word/1, a
  guard); `ever` and `never` went before the noun with their participle (`el
  Mundial más exótico jamás organizado` was `the most exotic never organised
  World cup`), and so did `well`, which the whole case found in an older check
  (`75 anni ben portati`, `75 well brought years`: none of the three now, a
  guard); and the state copula wrote a past event (`c'è stato il referendum` was
  `estuvo el referéndum`: never in the past now, a guard). Of the store (the
  store-alone column): `lascia le sue tracce` was `deja sus brazadas`, the
  writer's word for a swimmer's stroke being Spanish's word for any stroke now
  and `traccia` a stroke first in the dictionary (`traccia` is a trace first
  now, a line of corpus/extra, and the sentence is `deja sus rastros`); and the
  dictionary line that gives the report's `La conferma di un sospetto` its noun
  made `conferma` a noun everywhere, so that `E infatti conferma indirettamente
  le voci` was `And in fact confirm the voices` -- the third person was turned
  down where a form is a noun too, and the command, read after it, took the
  sentence (tr_third_person_command/3 asks tr_verb_form_any/1 now) -- and the
  Rosi report's `l'Egibren - conferma Casotto - Rosi sapeva del farmaco` was
  refused, `Casotto - Rosi` read as one name after the noun (tr_dash_names/3
  refuses a word that is a verb's third person too): two rules, each with its
  arm red. THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (thirteen
  sentences of the controls into English, eleven of 0.2 to 3 million inferences
  picked at random and two risers of 12 and 52 million, over a copy of the
  library per rule on the new store): the first cut was +0.297 % of the controls
  outside the four sentences it reads faster, and 2 840 of the 2 844 sentences
  rose, a few thousand inferences each -- a cost every reading pays, +0.74 % of
  the sentences under 0.2 million. The statement reader's clause for a verb of
  seeming was 18 % of what the thirteen rose, tr_complements0/4's two clauses
  for `ben` and a count 16 %, and the crossing's two for the bottom of a thing 5
  %: the first asked tr_form/5 of the first word of every piece (300 to 650
  inferences a call) and the second two the lexicon at every complement. What
  paid was a list made once a sentence (tr_into_ir/4): the lexemes whose meaning
  is `seems` or `appears` and those whose meaning is `well` or `as many as`,
  found by their meanings (52 inferences: the store keys the call on its second
  argument), each clause asking the word's lexeme against its list first
  (tr_count_lexeme/1). Two notes tried before it -- whether a sentence has a
  verb of seeming, or a count adverb before a count, asked of every word -- cost
  more than they saved (10 000 inferences a sentence for the first, tr_form/5 at
  every word), and the cheaper question first inside each clause saved nothing:
  the cost was the clauses being entered. The bottom clause asks the noun's
  meaning before its phrase's determiner, which moves nothing measurable. The
  final cut is +0.096 % outside the four (7 048 448 093 to 7 055 197 021, the
  first 7 069 393 361), every text of the 2 844 the first cut's: +0.36 % of the
  sentences under 0.2 million, +0.27 % of 0.2 to 1 million, +0.18 % of 1 to 5
  million, +0.10 % of 5 to 20 million; the largest rises are the Rognoni
  interview's nineteenth (+0.23 million of 773, refused both ways) and
  it_9714_9749 24 (+0.13 million of 3.7, `we must learn to judge`). THE STATED
  COSTS: the dictionary's line that gives the report's `La conferma di un
  sospetto` its noun makes `conferma` a noun everywhere, and `Cecchi Paone
  conferma che ...` (it_9270_9295 9) costs 3.0 million inferences more in each
  language, its text the same (the two readings it broke are mended by the two
  rules above); a first meaning that serves the news and not every text --
  `fondo` is a fund (the background second; the bottom of a thing is the
  code's), `canale` a canal (a television channel is one now; no sentence of the
  controls has it), `progetto` a project, `studio` a study, `ricerca` research,
  `gruppo` a group, `scarico` a discharge, `diverso` different, `simile`
  similar, `traccia` a trace, Spanish `desastre` a disaster, `extensión` an
  extension, `grupo` a group, and the writer's `bracciata` and `brazada` for any
  stroke and `impavido` and `impávido` for fearless -- and the controls'
  sentences they change are the store's 34 above; Spanish's state copula after
  `c'è` and a definite phrase in a question (`¿No está el riesgo de
  discriminaciones?`, as wrong as the `hay el riesgo` it was); the adverb
  between commas at the end of a clause moves the comma of a misread sentence
  (it_9540_9566 14); and the inferences, +0.096 % outside the four sentences the
  code reads faster, and the store's +0.327 %. The report LEAVES, of the 12 into
  English: `Venezia`, `Stoccolma` and `Porto Marghera` as the source spells them
  (no lesson states a city's English name); `the ambient direction of the town
  council` (the environment department) and `the muds of the numerous canals`
  (3); `the group "Insula" that takes charge` (the comma before the relative
  clause lost) and `an "integrated project prepared canals"` (4: a title in
  quotation marks read as the lesson's words, `rii` as canals, and its
  participle after it); `that, represent just ten per cent` (8: the comma after
  the relative word, and the verb in the plural where its subject is the
  bottom); `the Technicians therefore, that they promise to remove "all the
  remaining poisons"` (9: a quotation that closes before the comma ending the
  subject's relative clause leaves the clause with nobody named, where `who
  promise` is the text); `while the pollution "is inferior to that of thirty
  years ago" today` (10: `oggi`, before the subject in the source, is written
  last in both languages); of the 12 into Spanish: `desde 1994 a 2004` (3, `de
  1994 a 2004`) and `los barros` (`los lodos`); `el Ministerio del Entorno` (4,
  `del Medio Ambiente`); `Y entonces` (5, `Y luego`); `ciudades europeas dotado
  de canales` (8: the participle after its noun's phrase agrees with nothing,
  `dotadas`) and `y desde el hecho de que` (8: the third `da` after
  `deriverebbe` is no half of the pair the verb governs, `del hecho`); `muchos
  de los que` (9, `de los cuales`); `los estudios en los sedimentos ya
  consideran el pasado` (10, `sobre`, `se refieren al pasado`); and `no está más
  el carbón` (11, `ya no hay carbón`). The next sample's controls take this
  report in.
  The Yeltsin report (AnCora CESS-CAST-P-19991202-35, 16 sentences, Spanish into
  Italian and English: 16 of 16 and 13 of 16 on a fresh store, 16 and 14 with
  the new store alone, 8 and 11 with the new code on the old store, 8 and 11
  before; reasoning 1.0.16). The sample was taken on the cocolog 2.11.2 binary,
  and cocolog stays 2.11.2; master's 2.11.3 (5164d48, the step answers a read
  predicate's clause count inline, and inference counts do not move) came during
  the sample and is not merged: the next sample takes it. The article's
  sentences fall from 15.7 million inferences into Italian and 15.1 into English
  to 6.8 and 6.1. The new store alone reads 14 into English where the new code
  reads 13: its old reading of the colon's side (`Yeltsin mantiene un régimen
  ...: recibe correo y estudia documentos`) was the commands `receive mail and
  study documents`, and the new reading is Yeltsin's own present, which English
  refuses for the third person nobody names, on purpose (3, 4 and 9). It needed
  these SHAPES, each with its arm red (test/translate.pl's `newspaper_yeltsin`:
  48 checks, 51 arms, the guards among them; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM
  cocolog query "use_module('test/translate.pl'), newspaper_yeltsin,
  checks_done"`, two seconds a run, and every arm is run in two minutes, four at
  a time): `se trata de` is `it is` (`Se trata de la segunda hospitalización del
  líder del Kremlin` was `One treats of`, tr_write/4); a singular subject that
  is no person owns what its complements' possessive names, `its` (`la vida
  política en Moscú continúa su curso` continues ITS course,
  tr_thing_possessor/2, tr_cross_det/2), and not where a person or a name stands
  among the clause's complements, nor where a pronoun stands for a person (`El
  viento le voló su sombrero` blew HIS hat, `avisó a Ibarretxe de que a su
  Gobierno el tiempo se le acaba` is his Government: tr_person_clitic/1, both
  found by the controls), and the writer takes the words for `his` after the
  lesson's words for `its` where none has the noun's gender (tr_det_meanings/3:
  a store taught before `"suo" means "its".` wrote no sentence that had it --
  the code alone on the old store refused 8 of the controls -- and one with the
  masculine alone wrote `la suo porta`); a connecting word the lesson also gives
  as an adverb that stays in front, with a comma straight after it at the head,
  is the adverb (`Mientras, la campaña militar en Chechenia también prosigue` is
  Meanwhile, tr_read0/4); a name of one word that ends the piece after a noun in
  small letters, a name the lesson states, is apposed to it (`sobre la capital,
  Grozni`, and with the comma the city was an object of the verb of its own, `on
  the capital, Grozni yesterday`: tr_list_commas/5), crosses by its meaning and
  is written in each language's word (tr_cross_adjective/2, tr_adjective_out/5);
  a day's adverb the source put right after its verb stands before the verb
  where the clause runs long (`El jefe guerrillero ... lanzó ayer un llamamiento
  ..., según la cadena ... RTR` YESTERDAY launched an appeal, and written last
  it came after the network that told of it: tr_write/4, en_day_adverb/1,
  en_long_tail/1), and after a copula that stands alone (`son hoy el exponente`
  ARE today the exponent, found by the controls); a manner adverb in `-ly` right
  after its verb, before an object, a clause or an infinitive, goes with the
  verb (`el Kremlin confirmó ayer oficialmente los temores` officially confirmed
  them, tr_pull_adverb/3), never `awfully`, a degree (`No, sería mucho pedir`
  was `it would awfully be to ask`, en_not_manner_ly/1), and an adverb of how
  sure stands before a denied group (`non pensavo certo di incontrare` is I
  certainly did not think, and it was `I did not certainly think`:
  tr_mid_insert/3, en_sentence_adverb/1); an adverb that ends the subject's
  words, right before the verb, is the clause's (`la campaña militar en
  Chechenia también prosigue` -- Italian wrote it before the verb, `in Cecenia
  anche continua`: tr_subject_adverb_out/4), an adverb of one word or one
  English writes with the verb (`ya no`, no longer), never one of several words
  that is the phrase's own (`Las previsiones de evolución de este mercado a
  corto-medio plazo no son optimistas` was `non sono a breve-medio termine
  ottimiste`) and never the word that denies (`Un dato confortante del quale non
  ci si può rallegrare` was `se nos puede no alegrar`: a guard with no arm that
  goes red, which no hand lesson reproduces and which stays for what the
  controls showed); the side after a colon goes on saying what the subject
  before it does (`Yeltsin mantiene un régimen ...: recibe correo y estudia
  documentos` is what Yeltsin does, and read as commands it was `receive post
  and study documents`: tr_read_after_colon/5); a date is when after a verb that
  takes no object (`la primera vuelta tendrá lugar el 4 de junio` takes place ON
  June 4: tr_complements0/4, tr_date_adjunct_here/1); a verb left out after its
  coordinator, with a time for what is said (`la primera vuelta ... tendrá lugar
  el 4 de junio y la segunda vuelta, tres semanas más tarde`, cnj/1 and gapc/2,
  tr_gap_time/2); a name the source apposed to the noun among its adjectives
  stays after them, and English turns the adjectives round (`El jefe guerrillero
  checheno Chamil Basayev` is the Chechen guerrilla chief, en_adj_order/3,
  en_nationality/1); the phrase a participle's verb governs is marked as a
  clause's is (`un régimen calificado de "semilaboral"` is described AS one,
  `"califica" takes "de" before the phrase.`, tr_ptc_governed/4, en_governs/2);
  a name the lesson gives a meaning crosses by it and each language writes its
  own (`The name "moscú" means "Moscow".`, mean_as/3 under the class name; `en
  Moscú` is in Moscow and `a Mosca`: tr_cross_np/2, tr_cross_subject/3,
  tr_subject_out/6, tr_np_out/5, tr_named_words/3, tr_city_name/1) -- and the
  controls' first round found five faults of it, each mended with its arm red:
  the lesson's word is written only for a name the source crossed (`los
  argentinos Guglielminpietro (Milan)` is the club, a name the Spanish lesson
  does not state, and the IR's `Milan`, spelled as the English city is, came out
  `(Milano)`: tr_name_word_out/2, the names a sentence crossed noted as it is
  read, '$tr_xnames'); a city's name after an article is the club named after it
  and crosses as itself (`contro il Napoli` was `against the Naples`, `contra el
  Nápoles`); a word the lesson knows as a name and as nothing else is a name in
  quotation marks too, its marks off for the lesson and back on its word
  (`señaló que "España ve con simpatía la candidatura"` was refused once
  `España` was a word the lesson knows, and `analizado por Bruselas".` was `by
  brussels`: tr_only_name/2, tr_quote_names/3, tr_tail_mark/5, tr_unmark/4); a
  name after an elided article takes the gender the lesson states of it, asked
  in small letters (`L'Italia che soffre` was `El Italia que padece`,
  tr_name_gender/5); and a name of several words has a capital on each (`(New
  York, 1991)` was `(Nueva york, 1991)`, tr_cap_words/2); a person the source
  names in the feminine is one in the other language too (`la diplomática
  norteamericana Cheri Leberknight` was `il diplomatico americano`:
  tr_fem_person_note/3, tr_noun_lexeme0/5), never an animal, whose gender is its
  word's (`è come cavalcare una tigre` was `cabalgar a una tigresa`), and noted
  with its number (`dai 70 studenti iscritti ...: una studentessa che indossa la
  tuta` -- noted by the noun alone the 70 were `las 70 alumnas inscritas`); a
  word the lesson states in both genders agrees with either (`militare` is a
  soldier of either sex, and as the adjective it was masculine to the writer,
  `la campagna bellica`: tr_stated_both/1), and among nouns that are adjectives
  too a person stated in both genders is no head by being one (`l'aeronautica
  militare` was `el aeronáutico soldado`, tr_noun/5); and a preposition that
  contracts with the article is said again before the second of two definite
  phrases (`los ataques de la artillería y la aviación` are `gli attacchi
  dell'artiglieria e dell'aviazione`, tr_comp_out/7, tr_prep_contracts/1). It
  needed these WORDS in `extra/` (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Spanish `fija` (sets, where
  it was fixes, which Italian's writer took for a repair, `ripara`),
  `presidente`, `presidenta` and `president` (a president first, as Italian's
  `presidente` is), `primera vuelta` and `segunda vuelta`, `elección
  presidencial` and the noun `presidencial` (the presidential election, the noun
  left out), `"recupera" is reflexive.`, `semilaboral`, `allegado` and
  `allegada` (close associates, persons), `"califica" takes "de" before the
  phrase.`, `espaldarazo` (a boost), `fiscal general`, `cargo` (a post, where
  its first meaning was a charge) and `se hace cargo` (takes charge of, with its
  forms and `de`), `pariente` (said again first) and `familiar` (relatives),
  `alto funcionario`, `asunto` (an affair, where it was a subject),
  `diplomático` and `diplomática`, `americano` (said again first) and
  `norteamericano`, `más tarde`, the tenses of `tiene lugar`, `indiferente`
  (said again first) and `ajeno` (indifferent), `liderazgo` (said again first)
  and `cúpula` (the leadership, where it was a dome), `para fin de año`, `dura`
  (lasts, said again first) and `prolonga` (prolongs, and lasts as a reflexive),
  `guerrilla` (said again first) and `guerrillero`, `checheno`, `cadena de
  televisión`, `apelación` (said again first) and `llamamiento` (an appeal,
  where it was a call), `defensa` and `exteriores` (institutions), `correo`
  (mail, where it was the British post), `espera` (expects, and hopes before an
  infinitive), `finaliza` (completes, and ends with no object), `ministerio de
  exteriores` and `ministerio de asuntos exteriores`, `jefe` and `jefa` (a
  chief, where it was a boss), `"releva" takes "de" before the phrase.`,
  `"pívot" is a person.`, the 24 nouns in `-ción`, `-sión`, `-dad`, `-tud` and
  `-umbre` whose gender the dictionary leaves unsaid, each stated feminine, and
  37 names with their English meaning (`Moscú`, `Rusia`, `Chechenia`, `Grozni`,
  `Kremlin`, and the cities and countries the controls name, `Londres` to
  `Israel`, `Cataluña` said before `Catalunya`); Italian `fissa` (sets), `primo
  turno` and `secondo turno`, `elezione presidenziale`, `semilavorativo`,
  `stretto collaboratore` and `stretta collaboratrice`, `procuratore generale`,
  `incarico` (a task, then a post, where the writer's word for a post was
  `carico`, a load), `alto funzionario`, `vicenda` (an affair), `più tardi`, the
  tenses of `ha luogo`, `entro la fine dell'anno`, `guerrigliero`, `ceceno`,
  `rete televisiva`, `suo` and `sua` (its), `"spera" takes "di" before the
  infinitive.`, `solleva` (poses, and relieves, taking `da`), `spionaggio`
  (espionage, where the first noun for it was `spia`, a spy), `ministero degli
  esteri`, `"descrive" takes "come" before the phrase.`, `"militare" is
  feminine.`, the 148 nouns in `-zione`, `-sione` and `-tà` whose gender the
  dictionary leaves unsaid, each stated feminine (`il secondo
  ospedalizzazione`), and 36 names, the 14 cities that take `a` stated so
  (`mosca`, `russia`, `cecenia`, `grozny`, `cremlino`, and the controls' cities
  and countries); and in eng-ita.dix `cool` (`raffreddare`, where the
  dictionary's verb was `rinfrescare`). The first meaning moved for 14 Spanish
  words and 2 Italian ones (Spanish `ajeno` and `ajena` indifferent, `asunto` an
  affair, `cargo` a post, `correo` mail, `cúpula` the leadership, `jefe` and
  `jefa` a chief, `llamamiento` an appeal, `president`, `presidente` and
  `presidenta` a president, `fija` sets, `finaliza` completes; Italian `spia` a
  spy, `fissa` sets), the writer's first word for 6 Spanish meanings and 7
  Italian ones (Spanish later `más tarde`, mail `correo`, post `cargo`,
  completes `finaliza`, fixes `arregla`, sets `fija`; Italian later `più tardi`,
  affair `vicenda`, espionage `spionaggio`, post `incarico`, cools `raffredda`,
  relieves `solleva`, sets `fissa`), and none was lost. THE CONTROLS (cocolog
  2.11.2, store KB219, 104 count files, 2 868 sentences: the earlier set with
  the Venice report in, it_9999_10010, both directions; this report is not among
  them): the last version's translator against this one, on the one store, 194
  sentences in 75 files read differently, all better but the stated costs below
  -- the names a lesson now gives a meaning (`England`, `Germany`, `Spain`,
  `Catalonia`, `London`, `Florence`, `Seoul`, `Rome`, `Milan`, `Italy`, `Japan`,
  `Europe`, `Brussels`; Italian `Inghilterra`, `Germania`, `Spagna`,
  `Catalogna`, `Barcellona`, `a Londra`, `a Firenze`, `a Seul`; Spanish `Milán`,
  `Cerdeña`, `Japón`, `Atenas`, `Nápoles` for the city and `el Napoli` for the
  club), `yesterday`, `today` and `last night` before the verb of a long clause,
  `its` (`the Unicaja ... confirmed its enormous potential`, `the compact disk
  continues increasing its penetration`, `each federation has its regulations`,
  `the organisation of Miss Mundo 2000 ... its business`), the adverbs in `-ly`
  with the verb (`officially`, `recently approved`, `radically exclude`,
  `normally have need`, `indirectly confirm`, `I certainly did not think`), `it
  was about 10 kilos` (`se trata de`), `is no longer synonymous` and `non è più
  sinonimo`, `risultarono anche ferite` and `caricò anche`, the women
  (`l'incaricata del Governo, Julia García-Valdecasas`, `presidentessa`, `su
  compañera de otoño`, `L'infermiera gli raccomandò`), `dall'impegno e dalla
  volontà` and `sull'industria e sul settore agricolo`, `the military
  aeronautics` and `la aeronáutica militar`, `L'Italia che soffre` as `La Italia
  que padece`, and the Matutes sentence, which the last version refuses on this
  store and this one reads (es_19990601-23 10, `"Spagna vede con simpatia la
  candidatura"`) -- and the inferences fall 0.026 % (8 269 449 520 to 8 267 295
  355) and rise 0.013 % outside four sentences: the Matutes sentence, 2.2
  million inferences fewer in each language, and `l'aeronautica militare`
  (it_9947_9966 9), 0.62 million more in each, the reading the person rule mends
  being the longer one. Bytes and characters read every sentence alike (0
  differ, the bytes 0.012 % more). The DATA COLUMN (the last version's
  translator on its own store, KB212, against this one on the new): 219
  sentences in 76 files, +0.022 % (8 265 461 199 to 8 267 295 355), +0.036 %
  outside es_20020601-51 6, which the store reads 0.56 million inferences faster
  in each language. THE CODE ALONE (this translator on KB212): 45 sentences in
  34 files, +0.015 % (to 8 266 667 554), and it reads every sentence the last
  version reads. THE STORE ALONE (the last version's translator on KB212 and on
  KB219): 53 sentences in 30 files, +0.048 % (to 8 269 449 520), +0.023 %
  outside six sentences, each a word of the report's lines (`president`,
  `affair`, `posts`, `mail`, `Defence`, `Difesa`, `set`, `a Tokyo`, `si occupa
  di Paral.lel` for `se haga cargo de`) or a fault of the old code on the new
  store that the new code mends (`El Italia que padece`, `by brussels`, `the
  naples`, `el aeronáutico soldado`, and the Matutes sentence refused). A FIRST
  STORE WAS 0.124 % DEARER FOR EIGHT LINES: the rules `Every noun that ends in
  "zione" is feminine.` (and `"sione"`, `"tà"`, Spanish's `"ción"`, `"sión"`,
  `"dad"`, `"tud"`, `"umbre"`), asked of the gender of every noun, cost the old
  translator on that store +0.172 % where this one costs +0.048 %, the
  translation from Spanish into Italian +0.57 % of it -- found by teaching a
  store without each group of the new lines and counting twenty of the controls'
  risers whose texts were the same (the Italian rules were 78 % of what the
  store cost into Italian, the Spanish ones 83 % into English, the names
  nothing) -- and they decide the gender of 148 Italian nouns and 24 Spanish
  ones, which are each stated now: the same texts, every one of the 2 868, for
  0.124 % fewer inferences. THE FIRST ROUNDS' REGRESSIONS, found by reading the
  texts of every column (three rounds and a word-by-word scan of the last data
  column) and mended, each with its arm red: `its` for a person (`El viento le
  voló su sombrero` was `its hat`, `avisó a Ibarretxe de que a su Gobierno` `its
  Government`, `Rony Seikaly ... rescindir su contrato` `its contract`, which
  wanted `"pívot" is a person.`); `its` where the lesson has no word for it (the
  code alone refused 8 sentences into Italian); the club (`against the Naples`,
  `contra el Nápoles` in 12 sentences); the uncrossed `Milan` (`(Milano)`); a
  stated name in quotation marks (the Matutes sentence refused, `by brussels`,
  and a closing mark on a name, `could erase the naples`); `El Italia que
  padece`, `del Italia`, `al Italia` (5); `una tigresa`; `las 70 alumnas
  inscritas`; `el aeronáutico soldado` and `the aeronautical soldier`, from
  `"militare" is feminine.`; `ha prolongado tan poco`, `que prolonga 5 años`,
  `Prolonga 6 meses` and `si prolongaba indefinidamente`, from the reflexive
  `prolonga` said first; `se haga cargo de` as `one makes post of` and `si fa
  incarico di`; the subject's adverb of several words (`non sono a breve-medio
  termine ottimiste`) and its denial (`se nos puede no alegrar`), and the guard
  for one word that lost `ya no` (`non più è sinonimo`, the second round);
  `today are the exponent`; `I did not certainly think`; `it would awfully be to
  ask` and `One awfully seems his parent`; and `(Nueva york, 1991)`. THE COST OF
  THE CODE, FOUND BY TAKING EACH RULE OUT (the twenty heaviest risers of 0.2 to
  3 million inferences on the one store, ten from Spanish and ten from Italian,
  into English, over a copy of the library per rule on KB218): the ten from
  Spanish rose 21 717 inferences of 10.3 million (+0.21 %), of which the
  feminine-person note was 9 173 and the `its` rule 8 248, each asked at every
  phrase the crossing meets, and the colon's rule 1 201; the ten from Italian
  rose 648 540 of 15.9 million, 620 233 of it the person rule in `l'aeronautica
  militare` (above), the `its` rule 12 376 and the note 9 161; no other rule
  over 2 600. THE STATED COSTS: `cargo` is a post, so `buscar otros cargos para
  fortalecer el proceso` is `other posts`, where it was the charges, and
  `actuales cargos de RTVE` `current posts`; `presidente` is a president, and
  `su presidente, Henry Hyde` of the judicial committee is `his president`;
  `asunto` is an affair (`in this affair`, `una vicenda`); `fissa` and `fija`
  set, so `le due delegazioni fissate per martedì` are `the two set
  delegations`; the preposition said again shows a misreading that the old text
  hid (`Dove è l'imperturbabile signore della bombetta e dell'ironico umorismo`,
  the gentleman of the bowler hat and the ironic humour read inside one phrase
  of `of`); `se haga cargo de Paral.lel` is refused into English, a third person
  nobody names (on purpose; it was `one makes charge of`); and a feminine person
  noted by its noun and number makes every woman of that noun and number in the
  sentence one (`la diplomática ... la diplomática` is right, two such of
  different sexes are not). The report LEAVES, of the 16 into Italian: `soffre
  di nuovo una "polmonite"` (`di una`), `di cui si recupera soddisfacentemente`
  (`da cui si sta riprendendo`), `continua il suo andamento` (`corso`), `d'EEUU`
  (`degli Stati Uniti`), `sott'accusa di spionaggio` (`con l'accusa di`), `il
  ministro di Difesa` (`della Difesa`), `un appello all'inizio d'una nuova
  ondata` (`per l'inizio`); of the 13 into English: `the embassy of EEUU`,
  `under accusation of espionage`, `the minister of Defence`, `an appeal to the
  beginning of a new wave`, `a boost on the part of the Constitutional Court, on
  considering compatible ...`, and `has officially asked the diplomat to abandon
  the country` (to leave it); English refuses 3, 4 and 9 for the third person
  nobody names, on purpose (`de la que se recupera`, `recibe correo y estudia
  documentos`, `Este fue relevado de su cargo en el momento en que
  investigaba`). The next sample's controls take this report in.
  The islands report (VIT-9485..9510, 26 sentences, Italian into Spanish and
  English: 24 of 26 and 24 of 26 on a fresh store, 18 and 17 with the new store
  alone, 7 and 7 with the new code on the old store, 6 and 5 before; reasoning
  1.0.17). The sample was taken on the cocolog 2.11.3 binary, master's 5164d48
  and the three documentation commits after it merged as bd5803f, and cocolog
  stays 2.11.3: the binaries of 2.11.2 and 2.11.3 give the same texts and counts
  to the unit on the controls (8 267 295 355 inferences, 0 differ). The
  article's sentences fall from 297.1 million inferences into Spanish and 297.2
  into English to 100.3 and 100.1, of which the tenth, refused, is 19.6 million
  in each. It needed these SHAPES, each with its arm red (test/translate.pl's
  `newspaper_isole`: 76 checks, 81 arms, the guards among them; an arm is a
  library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_isole, checks_done"`, a second a run, and every arm is run in forty
  seconds, four at a time; 77 are red in the section, two more in the whole case
  and two in the controls alone, below): a street's name is a word the lesson
  says begins one and a capitalised word after it (`e Via Krupp, resa più
  agibile dopo il restauro, è frequentata come mai` is the street, and read as
  words `Via` was the adverb `away`, `y Fuera Krupp`: tr_stated_names0/2, `The
  word "via" begins the name.`, and `viale`, `piazza`, `corso`, `vicolo`); the
  first of a month is its day one (`dal primo luglio al 31 agosto` is from July
  1 to August 31, and read as an adjective of the month it was `from the first
  July`: tr_first_days/3); a preposition and a demonstrative the lesson joins
  into an adverb are the preposition and its determiner before a noun (`per chi
  ha scelto Cortina per questo fine settimana` is for this weekend, and read as
  the adverb `for this reason` the weekend was a bare noun the verb chose:
  tr_unjoin_demonstrative/3); a preposition and a free relative in front of the
  clause (`E per chi viola il divieto ci saranno multe` is fines for whoever
  breaks the ban, and the front's verb was taken for the clause's, so the
  sentence was refused: tr_read0/4, asked where the sentence has a word that
  begins the relative, `$tr_free_rel`) and a heading and the one it is for
  (`Cattive notizie, infine, per chi ha scelto Cortina per questo fine
  settimana: ...`, tr_heading_for_whom/2, asked of a statement only, `$tr_kind`)
  -- four arms, the notes among them; a participle at the head, its phrase and a
  comma, then a clause that names its subject (`Dimenticate le polemiche e messe
  da parte le idee ..., il sindaco si è dato ai servizi` -- the controversies
  forgotten, and read as the command `dimenticate` also is it was `Forget the
  controversies`: tr_read0/4), read before anything takes the commas out (with
  them out the relative clause took the mayor for the object of its intransitive
  verb, `to pause the mayor in square`), English writing the phrase and then the
  participle, the phrases of `of` and `like` after the phrase with it (`The
  ideas put aside of iron ordinances`, tr_abs_phrases/2) -- three arms; a front
  with a relative word in it is no command's (`Nessun caso a parte, invece, a
  Ponza dove la proibizione ... resta valida` is where the ban stays valid, and
  longest first the front took `resta` into the relative clause and left
  `valida`, the adjective, for the command validate!: tr_read0/4), where the
  command's word is an adjective too (a guard, below); a headline's phrase with
  its participle before a connector (`Un esodo annunciato con dovizia di cifre,
  tanto che l'osservatorio prevede ...`, and read as the clause's own
  `annunciato` had nobody to be said of: tr_join_left/5,
  tr_participle_headline/5); a main clause may open on the verb's own pronouns
  (`se i cellulari non smettono di trillare neppure in spiaggia si sono placati
  almeno i clacson dei turisti` -- with no start at `si` the piece had no
  division and was refused: tr_main_start/2); who a thing is for, and the thing
  (`A voi il calcolo del numero di cene al ristorante ...`, over to you the
  reckoning: a phrase of a preposition with a person or a pronoun, then a phrase
  with its article, tr_verbless0/3); a verb of saying with a gerund that says
  how is a reporting clause (`... primo tra tutti Emilio Fede - commenta ridendo
  -.` -- he comments, laughing, and read as a command it was `comment laughing`:
  tr_read_reporting/3); a passive with nobody named has its subject after it
  (`vengono vietati ai turisti i mezzi a motore` -- the motor vehicles are
  forbidden to the tourists, and read as an object English wrote `they are
  forbidden to the tourists the motor vehicles`: tr_passive_subject_fix/3), with
  the phrases of `of` after it (`siano esclusi dal divieto ... anche i veicoli
  (uno per nucleo familiare) di persone che ...`, tr_fo_of_run/3) -- two arms; a
  verb of saying that is also a command, with its speaker and a clause of `that`
  after it (`Assicura il sindaco Costantino Federico (e c'è da credergli) che in
  piazzetta si vede ...` -- read as the command the mayor was told to assure,
  `Asegura al alcalde`: tr_report_inv_fix/3, en_saying/1's `assures`), the
  clause's reflexive with an object the impersonal one, as after `dice che`
  (tr_report_impersonal/2), and the one who says it last, after what is said and
  a comma (`Conferma il popolare ritornello "tutti al mare, tutti al mare",
  l'analisi svolta dall'osservatorio di Milano` -- the analysis confirms the
  refrain, and it was the command `Confirm the popular refrain ..., the
  analysis`) -- five arms; a modal and an intransitive infinitive take no object
  (`Dovrebbero transitare più o meno 290 mila vetture` is the cars that should
  pass, and read by the generic reader they were what somebody should transit,
  `They should transit 290 thousand cars`: tr_read_generic/4), and a subject
  that ends at a comma, the rest read with the comma (`..., tra cui 40 mila di
  stranieri`: with the comma in no subject was found, tr_read_statement0/4) --
  two arms; digits and a number word are one count after an adverb (`più o meno
  290 mila vetture`, where `mila` read as an adjective of the noun came out `290
  miles coches`) and with nothing after them a count with its noun left out
  (`mentre altri 70 mila lasceranno la città` -- read as the noun `a thousand`
  the plural verb had no subject: tr_np/3), never where the number word is a
  noun too (a guard, below), and `another` before a count stays `another` in the
  plural (`Other 70 thousand`, tr_det_out/6) -- four arms; a command in the
  plural tries each plural the lesson states of the word (`E non contate sulla
  probabilità ...` is `no contéis` -- `cuenta` is a bill as well as counts, and
  with the bill's `cuentas` taken first the command had no Spanish:
  tr_imperative_form/4); the copula agrees with the phrase after it past an
  adverb (`Per il momento sono solo stime` is THEY are only estimates, and with
  `solo` first it came out `Soy sólo estimaciones`: tr_null_copula_agrees/4,
  tr_past_adverbs/2), a plural predicate only (a singular one says nothing of
  the subject: `erano solo un centinaio i tifosi a salutare la partenza`, the
  Lazio report's thirteenth sentence, was refused) -- two arms; the partitive
  after an infinitive of a verb of having or making is its object (`abbiamo
  cominciato a installare delle macchinette` -- some machines, and read as a
  phrase of `of` it was `to install of the machines`: tr_partitive/3, `installs`
  and `distributes` among the verbs), and the phrase with its relative clause
  (`delle macchinette che distribuiscono sacchetti`, tr_partitive_np/2) -- three
  arms; an infinitive after `di` hangs on a noun in a phrase of any preposition
  but `to` (`E non contate sulla probabilità di farla franca` is the probability
  of getting away with it, and read as the verb's the infinitive lost its `de`:
  tr_after_phrase/5, tr_noun_takes_inf/3), where the verb governs the phrase
  (`"conta" takes "su" before the phrase.`: `consentire a lupi, volpi e topi di
  fogna di circolare` was `mice of sewer of circulating` and `non mi è mai
  passato per la testa di preparare` `for the head of preparing`,
  tr_governed_here/1) -- three arms; English writes the person a verb forbids
  with no `to` before the infinitive (`proibire ai cani di passeggiare` forbids
  the dogs to stroll, and it was `forbid to the dogs to stroll`: tr_comps_out/7,
  en_person_before_inf/1), after an infinitive too -- two arms; a verb of saying
  with a person's pronoun is `tells` (`gli esperti ci dicono che ...` TELL us
  that, and English wrote `say us that`: tr_write/4), before a clause of `that`
  or an object only (a guard, below); a perfect with a time that is over is
  English's past (`una frana ... è caduta ieri pomeriggio` fell yesterday
  afternoon, and it was `has fallen`: tr_write/4, en_past_time/1), and
  `yesterday afternoon` is a day's adverb, before the verb where the clause runs
  long (en_day_adverb/1) -- two arms; a verb English too says of oneself writes
  its reflexive pronoun (`il sindaco si è dato ai servizi di pubblica utilità`
  has dedicated himself to them, and with the pronoun dropped it was `has given
  to the services`: tr_verb_across/5, tr_write/4, en_true_reflexive/1), a plural
  subject's `themselves` (en_reflexive_of/2), and a verb whose meaning the
  lesson states as a reflexive one is written with its pronoun (`si sono
  rassegnati a muoversi` is `se han resignado a moverse`, and written plain it
  was `han resignado`: tr_verb_out/4) -- four arms; a verb that ends in `to`
  takes the gerund (became resigned to MOVING, never `to to move`:
  tr_verb_ends_in_preposition/0), with the infinitive's own pronoun (infx/3),
  and a verb of stopping or keeping on takes the gerund (`i cellulari non
  smettono di trillare` do not stop RINGING, and it was `do not quit to ring`:
  en_gerund_verb/1), the clause's own infinitive only, after its adverbs (below)
  -- three arms; the adjectives after a comma agree with what there is (`ci
  saranno multe, addirittura "salate"` is `incluso "caras"`, where they agreed
  with nothing, `caros`: tr_adj_after_comma/2); an adverb of how sure stands
  after the auxiliary that opens a denied group (`non diventeranno certo aree
  pedonali` will certainly not become them, and it was `will not certainly
  become`: tr_mid_insert/3) and with the verb where nothing is denied
  (en_mid_adverb/1's `certainly`) -- two arms; an adjective of several words
  that opens on a preposition stands after its noun (`le isole in questione` are
  the islands in question, and it was `the in question islands`:
  tr_names_last/3); `some` and `no` in a denied clause are `any` (`non subirà
  alcun calo` will not undergo ANY decline: tr_det_out/6), and the lesson's
  language writes its word for `no` (`no experimentará ningún descenso`, where
  it was `algún`) -- two arms; `not even` before a phrase of a preposition is
  said of it, `even` in a denied clause (`non smettono di trillare neppure in
  spiaggia` do not stop even on the beach, and it was `in beach not even`),
  `only` the same (`soltanto nel week end`, which was written last), and `while`
  and `not` right before a gerund are the gerund's (`persone che pur non essendo
  residenti pagano la tassa` pay it while not being resident, and the two came
  last, `being resident while not`: tr_comps_out/7) -- three arms; a range takes
  the word the lesson begins it with (`dal 10 marzo al 31 ottobre` is `del 10 de
  marzo al 31 de octubre`, where the lesson's word for `from` wrote `desde`:
  `The word "de" begins the range.`), a range with `and` before its `until`
  (`già dal 14 aprile e fino al 30 settembre` is from April 14 to September 30,
  where the first phrase was `since`: tr_date_range/1), in front of the clause
  with no comma, written after the verb, in front with a comma (each front
  crossed on its own, it was `Since April 14 and until September 30`:
  tr_cross_comps/2, tr_fr_items/2, tr_fronts_out/5), with no `and`, `fino a`
  with no `and` as `to` after `from`, and between two commas (tr_mid_items/2) --
  eight arms; the adverb of a day before this one after `da` is `since` (`da
  ieri abbiamo cominciato` is since yesterday, and it was `from yesterday`:
  tr_cross_comp/2); `like` and the word for `ever` in a clause that denies
  nothing are `like never before` (`Via Krupp ... è frequentata come mai`, where
  it was `like ever`: tr_comp_out/7), and `ever` before a participle that stands
  alone in an aside is `never` (`come quella dell'estate scorsa (mai passata)`
  was `(ever happened)`: tr_aside_out/6) -- two arms; the plural of `lira` is
  `lire` (`da un minimo di 540 mila lire`, and it was `liras`:
  en_plural_pair/2), a people's name in `-ese` is its own plural (`130 mila
  milanesi` are 130 thousand Milanese, and it was `Milaneses`:
  en_plural_same/1), and `Lombard` and `Bellunese` take their capitals
  (en_nationality/1) -- three arms; two cities joined after a verb that does not
  go are `in` (`a Linate e Malpensa si aspettano 80 mila partenze`, where it was
  `to Linate and Malpensa`: tr_cities_in/2); a participle with the adjective it
  makes of its noun, between commas (`Via Krupp, resa più agibile dopo il
  restauro, è frequentata come mai` -- read as the sentence's own the street was
  set apart from its verb, `it is beautiful`: tr_asides/3), agreeing with its
  noun (where it was `rendido`, tr_aside_inner0/2), and an aside a dash opens
  and a comma closes where the sentence has no other dash (`c'è da giurare che
  Capri - off limits per i "motorizzati" dal 10 marzo al 31 ottobre, non subirà
  alcun calo` -- the comma stands for the closing dash, and the sentence was
  refused) -- three arms; and a list of bare nouns right after a preposition
  (`la proibizione per auto, moto e motorini resta valida` is the ban on cars,
  motorbikes and mopeds, and with the comma the clause's the first two were
  `motorbike car`: tr_list_commas/5) and names to the end of the piece with no
  coordinator (`nelle isole di Capri, Procida, Ischia, Giglio, Eolie` -- one by
  one the names after the first were objects of the verb, and the sentence was
  refused: tr_bare_tail/4, tr_bare_item/2), which Spanish wrote with the `a` of
  a person, `a Procida, a Ischia` -- three arms. Four arms are green in the
  section. Two are red in the whole case: an absolute clause of a perfect
  infinitive keeps its order in English (the Cecchi section's `Cioè dopo aver
  mandato in onda l'ultimo "punto di svolta".`: the first cut wrote every
  absolute clause's phrase first, and the controls had `after having the "last
  dot broadcasted of turning"`, it_9270_9295 20 -- the phrase goes first in a
  front only, tr_abs_phrases/2), and `tells` stands only before a clause of
  `that` or an object (three older checks: `te lo digo` is `I say it to you`, `A
  dirlo è Giuseppe Signori` Signori says IT, `una amichetta le ha detto di
  essere stata lei ad avvertire` she said to be HER; and the controls had `...,
  tells it` and `And why, and who tells it?`). Two are red in the controls
  alone, which no hand lesson reproduces: a count with its noun left out never
  ends on a number word that is a noun too (es_20000701-80 7, `Las obras, que
  costarán 230 millones de pesetas`, was `230 million of pesetas` and Italian
  `230 milione di pesete`, and es_20010103-139 1 `63,168 million of pesetas`),
  and the command after a front with a relative word is refused only where its
  word is an adjective too (with every such command refused, `Perché in casi
  come questi conta soprattutto il primo soccorso` -- `come` for `like` -- had
  no reading in either language, it_9381_9414 9, and the Venice report's eighth
  sentence was read again 40.2 million inferences later, `to facilitate him, I
  accumulate of the sediments`). Two guards of the first rounds had arms that
  stayed green in the section, in the whole case and in the controls (0
  sentences differ), and are gone: the main start at the reflexive word only
  (written for that Venice sentence, whose fault was the command's) and the
  command guard's verb after the relative word (written for `in casi come
  questi`, which the adjective settles); with both out the controls read every
  sentence alike and count 12 054 inferences fewer. It needed these WORDS in
  `extra/` (the two readers: a line moves the reader of one language and the
  writer of the other; the dictionary's own word is said again first where it
  must stay the one written): Italian `targa` (a number plate), `trasporto
  merci` (freight transport) and `merce` (a commodity, where the dictionary has
  the old `mercanzia` alone), `bel pò` (the source's spelling of `po'`),
  `vespaio` (an uproar), `macchinetta` (a machine; `macchina` said again first),
  `paletta` (a shovel, where the dictionary's was a bricklayer), `segatura`,
  `clacson` (one word in both numbers), `rassegna` (resigns, and becomes
  resigned to with its pronoun; `dimette` said again first), `minitaxi`,
  `vetturetta` and `a tre ruote`, `mezzo a motore` (a motor vehicle), `nettezza
  urbana` (street cleaning), `pernottamento` (an overnight stay), `depenna`
  (crosses off), `prefetto` and `milanese` (persons), `fine settimana` and `week
  end` (a weekend, not feminine), `dovizia` (abundance; `abbondanza` said again
  first), `tra cui` (among them, one preposition of two), `bellunese`, the words
  that begin a street's name (`via`, `viale`, `piazza`, `corso`, `vicolo`),
  `lira` (the currency, before the dictionary's lyre), `presto` (soon, before
  early), `a tutti i costi`, `più o meno` (one adverb of three), `comporta`
  (entails, where the dictionary's was `comports`), `svolge` (carries out,
  before performs, and takes place with its pronoun), `oscilla` (ranges),
  `transita` (transits, intransitive), `nucleo familiare` (a household), `budget
  vacanze` (the holiday budget), `la fa franca` (gets away with it), the name
  `Eolie` (the Aeolian Islands), `caso a parte` (a special case), the places
  that take `a` for `in` as a city does (`capri`, `ischia`, `procida`, `ponza`,
  `linate`, `malpensa`), `partenza` (a departure, before the exit), `tra oggi e
  domani` and `fra oggi e domani`, `senz'altro` (certainly, where `senz'` and
  `altro` were without others), `per il momento` (where Spanish wrote `para el
  momento`), `calo` (a decline, where the dictionary has the first person of
  `cala` alone), `motorizzato` (a motorist, a person; `automobilista` said again
  first), `mette da parte` (puts aside, with its forms, where `messe` was the
  masses), `dà` (gives, and dedicates with its pronoun; `dedica` said again
  first), `placa` (appeases, and calms down with its pronoun), `ha presente`
  (knows, with its forms; `sa` said again first), `smette` (stops, where the
  dictionary's was quits), `in questione` (an adjective of two words), `circola`
  (intransitive), `residente` and `invalido` (persons, and nouns, where the
  dictionary has the adjective alone), `pubblica utilità` (public utility) and
  `ieri pomeriggio` and `ieri mattina`; Spanish `matrícula`, `transporte de
  mercancías`, `bolsa` (a bag, said first), `suena` (sounds, said first, and
  rings), `claxon`, `resigna` (resigns, and becomes resigned to with its
  pronoun; `dimite` said again first), `minitaxi`, `cochecito` (a pram, said
  first, and a small car), `de tres ruedas`, `limpieza urbana`, `pernoctación`,
  `tacha` (crosses off), `prefecto` (a person), `estribillo` (a refrain, before
  the chorus), `milanés` (a person, and the adjective), `bellunés`, `fin de
  semana` (not feminine), `entre los cuales` (among them, one preposition of
  three), `lira`, `a toda costa`, `más o menos`, `conlleva` (entails), `medio
  ambiente` (the environment), `realiza` (realises, said first, and carries
  out), `recoge` (collects), `núcleo familiar`, `presupuesto de vacaciones`, `se
  sale con la suya`, the name `islas eolias`, `caso especial`, `entre hoy y
  mañana`, `peaje` (a toll, said first, and a tollgate), `por el momento`, `The
  word "de" begins the range.`, `aparta` (puts aside), `férreo`, `calma` (calms,
  and calms down with its pronoun), `"para" takes "de" before the infinitive.`
  (`no paran de sonar`), `en cuestión`, `utilidad pública` and `ayer por la
  tarde` and `ayer por la mañana`; and in the dictionaries' extras, for Italian
  `piazzetta` (square), `agibile` (accessible), `sacchetto` (bag), `trillare`
  (ring), `rassegnare` (resign), `motorino` (moped), `salato` (expensive, of a
  price: the dictionary has no `salato` at all), `vettura` (car) and `montano`
  (mountainous), read only, and `sbarco` (disembarkment), `prefetto`,
  `ritornello` (refrain) and `milanese` both ways, and for Spanish `resignar`
  (read only), `transitar` (transit, where the Italian dictionary's `passes` is
  Spanish's `transcurre`, time passing) and `ordenanza` (an ordinance, which the
  bilingual dictionary lacks). The first meaning moved for 9 Italian words and 4
  Spanish ones (Italian `presto` soon, `lira` the lira, `paletta` a shovel,
  `partenza` a departure, `comporta` entails, `oscilla` ranges, `smette` stops,
  `svolge` carries out, `transita` transits; Spanish `estribillo` a refrain,
  `lira`, `conlleva` entails, `tacha` crosses off), the writer's first word for
  5 Italian meanings and 4 Spanish ones (Italian commodity `merce`, decline
  `calo`, household `nucleo familiare`, shovel `paletta`, ranges `oscilla`;
  Spanish bag `bolsa`, environment `medio ambiente`, household `núcleo
  familiar`, collects `recoge`), and none was lost. THE CONTROLS (cocolog
  2.11.3, store KB226, 106 count files, 2 900 sentences: the earlier set with
  the Yeltsin report in, es_19991202-35, both directions; this report is not
  among them): the last version's translator against this one, on the one store,
  42 sentences in 22 files read differently, all better but one that is no worse
  -- `lire` (8: `500 thousand lire to the month`, `the million and 200 thousand
  lire the year`), Spanish's range word (8: `del 30 al 90%`, `del 24 de julio al
  25 de agosto`, `de las 500 a las 600 mil liras`, `del estado a las regiones`,
  `de juez de legitimidad a juez de mérito` twice, `de las comunicaciones al
  coche`, and the one no worse, it_9605_9636 5, `promulgado el jueves del senado
  a la Cámara`, where `varato giovedì dal senato` is passed by the senate and
  `desde el senado` was as wrong), English's past with a finished time (5: `took
  him in exam for the first time, yesterday`, `the sensation that took place ...
  yesterday`, `the Pole tried`, `Bianco remembered yesterday`, `Then the Olivo
  proposed`), `tells` (3: `I am telling you the truth`, `They have told me
  immediately`, `his friend has told her`), `any` (3: `I have not signed any
  contract`, `any other choice`, `You will not have any problem anymore`),
  `another` before a count (2: `another twenty years`, `another two, three
  years`), `certainly` with the verb (2: `It can certainly be`, `They are
  certainly too much`), `only` before its phrase (2: `only in Italy`, `only to
  the 1.4`), the gerund (2: `He also risked dying`, `Tom enjoyed playing
  baseball`), `since yesterday` and Italian `fin da ieri` (es_20010202-169 1),
  `the Japanese`, `the Lombard ones`, `does not burn even on the altar`, `the
  categories at risk` and `the motivation of both sides` -- and the inferences
  rise 0.065 % (8 282 142 493 to 8 287 552 417). Every sentence rises but 14,
  +0.37 % of the sentences under 0.2 million inferences, +0.16 % of 0.2 to 1
  million, +0.13 % of 1 to 5 million and +0.09 % of 5 to 20 million; the largest
  rises are Tempi's twentieth (+0.11 million of 517.0 in each language) and the
  Rognoni interview's nineteenth (+0.09 of 773.5), both refused, and the Venice
  report's eighth (+0.07 of 394.3), and the sentences that fall most are
  es_20000701-80 20 (`"Lo estamos reclamando desde hace 15 años", asegura.`,
  0.24 million inferences to 0.09 in each language, its text the same),
  it_9637_9672 5 (2.47 to 2.35) and the Venice report's fourth (124.5 to 124.3).
  Bytes and characters read every sentence alike (0 differ, the bytes 0.013 %
  more). The DATA COLUMN (the last version's translator on its own store, KB219,
  against this one on the new): 60 sentences in 30 files, +0.091 % (8 280 031
  535 to 8 287 552 417). THE CODE ALONE (this translator on KB219): 26 sentences
  in 16 files, +0.065 % (to 8 285 445 636), every one of them among the 42; the
  16 left are Spanish's range word and `lire`, which need the new lines. THE
  STORE ALONE (the last version's translator on KB219 and on KB226): 27
  sentences in 15 files, +0.025 % (to 8 282 142 493), all better, each a word of
  the report's lines: the Aeolian Islands (6, where `Eolie` stayed as it was),
  `medio ambiente` (3: `el director del medio ambiente`, `leyes en el medio
  ambiente`, `el Ministerio del Medio ambiente`, where it was `entorno`),
  `liras` (9, English, where they were lyres, and with the code `lire`),
  `departure` (2: `to greet the departure`, `The departure of the mission Marco
  Polo`, where it was the exit), `carry out` and `realizar` (5, where they were
  `perform` and `actuar`), `las bolsas de estudio` (where they were handbags)
  and `successivi cali`. THE FIRST ROUNDS' REGRESSIONS, found by reading the
  texts of every column and mended, each with its arm red. Of the code (the
  first round, 82 sentences in 41 files, 4 fewer read, +1.150 %): the count with
  its noun left out took a number word that is a noun too (`230 million of
  pesetas`, `63,168 million of pesetas`, `230 milione di pesete`: the guard
  above); the English absolute clause written phrase first took a perfect
  infinitive's (`after having the "last dot broadcasted of turning"`); `tells`
  was written with nothing said (`the developments of the failed renewal, tells
  it`, `who tells it?`); the gerund after a verb of keeping on was asked of
  every infinitive the clause holds (es_19990601-98 2, `la reunión que
  mantuvieron ayer con la AEB para intentar avanzar`, whose verb is `mantener`,
  keeps: `to try advancing`) and is the clause's own infinitive alone now, after
  its adverbs (tr_write/4); the noun's infinitive took a phrase its verb does
  not govern (`mice of sewer of circulating`, `for the head of preparing`:
  tr_governed_here/1); and two sentences were refused in both languages, `Perché
  in casi come questi conta soprattutto il primo soccorso` (the command guard)
  and the Lazio report's thirteenth, `erano solo un centinaio i tifosi a
  salutare la partenza` (the copula past an adverb, which agrees now with a
  plural predicate only). Of the second round (44 sentences, +1.192 %): the
  Venice report's eighth sentence, `to facilitate him, I accumulate` and 40.2
  million inferences more in each language, which the arms put on the command
  guard. Of the store (45 sentences in 26 files on the first two stores, +0.052
  %): a reflexive sense said first is the word's meaning everywhere -- `dà` as
  dedicates made every `dare` dedicate (`dargli questa soddisfazione` was
  `dedicate him this satisfaction`, `darò tutto` `I will dedicate everything`),
  and `placa`, `rassegna`, Spanish `resigna` and `calma` were the same -- so the
  plain meaning is said first now (`gives`, `appeases`, `resigns`, `calms`),
  after the dictionary's own word where the writer's word must stay (`dimette`,
  `dimite`); and `entre ellos`, the first Spanish line for `tra cui`, joined was
  read as one word, and `cuatro palestinos, entre ellos un niño de 10 años, y
  dos israelís` lost its commas (es_20010102-25 4, both languages): the line is
  `entre los cuales` now. The whole case found two more, its scans of the
  vocabularies: `fin de semana` and `fine settimana` are masculine nouns in `a`
  whose denial was missing. THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT
  (a copy of the library per rule): with the command guard mended the third
  round was +0.129 % of the controls, and its five heaviest risers into English
  (it_9637_9672 15, it_9270_9295 9, es_20020801-17 22, es_19990802-48 5,
  es_20020601-51 11, 1.7 to 45 million inferences each) rose 3 763 793
  inferences of 89.6 million (+4.20 %), 97 % of it three rules, each asked at
  every piece of every sentence: the participle at the head (2 575 609, and
  it_9637_9672 15 2.44 million to 4.68), the headline's phrase before a
  connector (843 830) and the reporting gerund (247 260). Each asks now a cheap
  test first -- the participle's front is one phrase with no mark in it and the
  rest opens on its subject (tr_opens_on_subject/2), the headline's side stands
  at the head of the piece (`$tr_piece`) with its participle among the first
  four words, the reporting clause has a gerund right after its group -- and the
  five rose 103 601 (+0.116 %). Over 24 sentences of 0.06 to 2.5 million
  inferences picked at random (10 Italian, 14 Spanish, into English) the code
  then rose 19 355 (+0.136 %), most of it two rules asked of every word of every
  sentence: the first of a month (14 964, the lexicon asked of each word for a
  month) and the preposition and demonstrative (11 427, sub_atom/5, which walks
  every position, asked of each adverb for its space). The months are a list
  made once a sentence (findall/3), and so are the words that begin the relative
  for `$tr_free_rel`, and the adverb is split with atomic_list_concat/3: the
  fourth round rose 0.065 %, where the third rose 0.129 %. What is left is no
  rule: the 24 rise 0.198 % without the one that falls (it_9967_9998 17, `80
  mila stadi`, which the count reads at once, 2.49 million to 2.45), and their
  largest rules are the first of a month (2 634 inferences in all, in 24 of
  them), the preposition and demonstrative (2 421, in 24), the count with its
  determiner (2 063, in 17), the list of bare nouns (1 641, in 11), the noun's
  infinitive (1 490, in 17), the reporting gerund (1 161, in 3), the participle
  at the head (960, in 23) and the heading for whom (879, in 23), none other
  over 600. THE STATED COSTS: a first meaning that serves the news and not every
  text -- `presto` is soon (early second), `lira` the currency (a lyre second),
  `paletta` a shovel, `partenza` a departure (an exit second), `svolge` carries
  out (performs second), `oscilla` ranges (swings second), `smette` stops (quits
  second), `comporta` entails, Spanish `estribillo` a refrain (a chorus second),
  `tacha` crosses off (lines second) -- and the writer's first word for a
  household is `nucleo familiare` and `núcleo familiar`, where it was `casa` (no
  sentence of the controls has it); Spanish writes every range with the lesson's
  word for it, `de`, so a phrase of `from` misread as a range's start is `del`
  where it was `desde` (it_9605_9636 5); and the inferences, +0.065 % on the one
  store. The report LEAVES, of the 24 into Spanish: `trascorrono` is `gastan`
  (1: the time is spent, `pasan`); the marks of `così "ammorbidito"` are lost
  and `non convince ancora i più pigri` is `no convence todavía los más
  perezosos` (2: a person's object with no `a`), and `c'è il sacrosanto diritto`
  is `hay el sacrosanto derecho` (the state copula is written after a phrase
  that opens the clause only); `in piazzetta` is `en plaza` (4 and 5: no
  article), `resa` is `rendida` and `frequentata` `es atendido` (4: frequented,
  and the street's gender lost); `se la presero tutti a male, primo tra tutti
  Emilio Fede` is `se la tomaron todos a mal, primero entre todos` (6); `da
  ieri`, in front of the clause, is written last (7: `desde ayer`), and so are
  `Presto` (8: `pronto"`), `qui` (11: `aquí`), `Per il momento` (19) and `a
  Linate e Malpensa` (23); `sebbene qui siano esclusi dal divieto` is `Aunque
  son excluidos por la prohibición` (11: the subjunctive written as an
  indicative, and excluded FROM it) and `pur non essendo residenti` `mientras no
  siendo residentes`; `per auto, moto e motorini` is `para coche, moto y
  ciclomotores` (12: the bare nouns in the singular); `l'esecuzione dei decreti
  e la sorveglianza ... è assicurato` is `la ejecución de los decretos y de la
  vigilancia` (16: the second subject read inside the phrase of `of`, which
  Spanish says again before it); `cene al ristorante` is `cenas al restaurante`
  and `da depennare sul budget vacanze` `para tachar en el presupuesto` (15);
  `diretti al Sud` is `directos al Sur` (21: heading South); `È previsto` is `Es
  previsto` (23); `ha scelto Cortina` is `ha escogido a Cortina` (24: the `a` of
  a person before a city) and `isolandola` is `aislandola`, with no accent;
  `disagi` are `malestares` (25); and `nelle isole di Capri, ..., Eolie` writes
  the name's own `Islas Eolias` after `islas` (26). Of the 24 into English: the
  subject's list after the verb is split, its first item before the verb and the
  rest after it, and `vi` is `there` at the end (1: `the vehicles of the
  residents can circulate, of those that spend ..., the cars ... utilised by
  invalids there`); `does not convince the laziest still there is` (2: no comma
  before the main clause, `yet`); `in square` (4, 5); `attended like never
  before` (4: frequented); `(never happened)` (5: an ordinance that never
  passed); `they took it everyone to badly, among everyone Emilio Fede first`
  (6: everyone took it badly, Emilio Fede first of all); `we have commenced to
  install machines that distribute bags of plastic and shovel to collect ...
  since yesterday` (7: began installing, plastic bags and scoops, `since
  yesterday` last); `one for household` and `excluded by the ban` (11: per
  household, from it), and `here` last; `in Ponza instead` (12: `instead` moved
  from its commas) and `for car, motorbike and mopeds`; `for the one that
  violates` (13, 24: whoever); `To you the calculation ... dinners to the
  restaurant ... in hotel to cross off on the holiday budget` (15); `in the
  weekend` (19); `40 thousand of direct foreigners to the South` (21: `diretti`
  agrees with the cars); `A 5 per cent of increase` (23); `finally` last of the
  heading and `isolating her yesterday afternoon` (24: it, and the time last);
  `strong unrests to the motorists` (25); and `the islands of Capri, Procida,
  Ischia, Giglio, Aeolian Islands` (26). Into both languages 9 and 10 are
  refused: 9, `Pulizia e tranquillità.`, two bare nouns joined by `e`, which the
  pinned `Pane e vino.` guard refuses on purpose, and 10, the inverted subject
  whose relative clause has a front and then an aside (`si sono placati almeno i
  clacson dei turisti che a Ischia e Procida, già dal 14 aprile e fino al 30
  settembre, si sono rassegnati a muoversi in minitaxi (...) o in autobus`; a
  reading through tr_subject/6 was tried and did not help). The next sample's
  controls take this report in.
  The satanic groups report (AnCora CESS-CAST-P-19991102-2, 17 sentences, Spanish
  into Italian and English: 15 of 17 and 13 of 17 on a fresh store, 13 and 11
  with the new store alone, 11 and 10 with the new code on the old store, 9 and
  8 before; reasoning 1.0.18). The sample was taken on the cocolog 2.11.4
  binary, master's fbda058 merged as 57f9ff2, and cocolog stays 2.11.4: the
  binaries of 2.11.3 and 2.11.4 give the same texts and counts to the unit on
  the controls (8 287 552 417 inferences, 0 differ). Master's 2.11.5, 2.11.6 and
  2.12.0 (a27ea39 to d71af1e) came during the sample; from 2.11.5 they take
  `realpath` from Cicili 3.2.0 (a9e2dcf), the checkout here is 3.1.0 (cc24ae0)
  and cicili is frozen, so they are not merged, and the next sample takes them
  when the owner moves cicili. The article's sentences fall from 59.5 million
  inferences into Italian and 59.3 into English to 20.2 and 19.9, of which the
  thirteenth, refused, is 8.2 million in each. It needed these SHAPES, each with
  its arm red (test/translate.pl's `newspaper_satan`: 37 checks, 43 arms, the
  guards among them; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_satan, checks_done"`, under a
  second a run, and every arm is run in eleven seconds, four at a time; 39 are
  red in the section, and the four that stay green are guards that stay for
  their cost, below): a participle and its agent after a noun and a phrase of
  the noun's own agree with the noun (`En la Red existen páginas en castellano
  abiertas por miembros de estas sectas` are pages in Spanish opened by members
  -- hung on the nearest noun, the language was what the members opened, the
  subject after `existen` had no reading, and the sentence was refused: tr_np/3
  with with/2 as the participle's head, and fo_np_number/2 reads its number from
  the noun), asked where the sentence has a noun or an adjective right before a
  participle with the word for `by` after it, the two disagreeing in number or
  gender (`$tr_ptc_agent`, tr_ptc_agent_note/1) -- three arms, and the note's two
  tests are guards of cost; a second agent joined to the first (`abiertas por
  miembros de estas sectas o por las mismas hermandades` -- read on as the first
  agent's adjuncts, the second was a phrase of `for`: tr_reduced_agent/3), and a
  day's adverb right after the participle stays before both agents (`il
  drammatico quadro ... presentato ieri dal ministro della famiglia ... Adriano
  Ossicini e dal direttore generale del dicastero` was `... Adriano Ossicini
  yesterday and by the general director`, tr_ptc_day_first/4, found by the
  controls) -- two arms; a modal and an infinitive with the reflexive joined, in
  the plural, with a bare phrase after it, is the reflexive's passive (`En
  algunas de ellas pueden encontrarse chats` -- chats can be found there, and it
  was `they` who could find chats:
  tr_modal_se_fix/3), never with a phrase with its article (`pueden lavarse las
  manos` is their own hands, tr_bare_head/2, a guard), and English writes a
  modal's reflexive passive as the modal and the passive infinitive (`Se pueden
  encontrar chats` -- written as the passive of the modal it was `Chats are
  caned find`: tr_write/4) -- three arms; the clause of `where` of the phrase
  after the verb, and a second phrase joined to it, are the subject's too
  (`chats (páginas de conversación) donde los adeptos se comunican y un tablón
  donde dejar anuncios diversos` can be found, each phrase with its clause:
  rc(Phrase, where, Clause), tr_where_rc/4, tr_bare_head/2 for the pair), a
  phrase's clause of `where` with an infinitive is English's `in which`
  (tr_np_out/5), and the lesson's language writes its own relative word for it,
  `dove` (tr_relative_out/5) -- six arms; a clause of `where` ends at a
  coordinator and a phrase after it (`donde los adeptos se comunican y un
  tablón`: read to the end of the words, the clause had `y un tablón` in it and
  nothing read, tr_complements0/4, cnj/1), asked where the sentence has the word
  for `where` with no comma after it and a coordinator after that
  (`$tr_where_co`, tr_where_co_note/1) and the phrase after the coordinator has
  four words at most or ends at its own word for `where` (tr_where_tail/1) --
  one arm, and the note and the tail are guards of cost; a question word before
  an infinitive asks with it (`No sé dónde dormir` is where to sleep, and read
  as the adverb `where` beside an infinitive it was `I do not know to sleep
  where`: tr_complements0/4), after a phrase English says it with `in which`
  (`un tablón donde dejar anuncios diversos` is a noticeboard in which to leave
  ads, tr_comp_out/7), and the word for `how` is the word for `like` too, and
  asks only after a verb that takes the question (`Ma parlare con Diego era
  come parlare con due persone diverse` was LIKE speaking with two different
  people, and read as the question it came out `how to speak` and `cómo
  hablar`: tr_asks_question_here/0, found by the controls; a guard, `Il cane non
  sa come dormire` is how to sleep, where it was `like sleeping`) -- four arms;
  the word for `for` after an infinitive and before one is the purpose, no verb
  (`quisiera saber qué hacer para iniciarme en el satanismo` is what to do in
  order to begin, and with `hacer` the subject and `para` the verb of `parar` it
  was `what to do stops beginning`: tr_purpose_as_verb/3), `makes` with nothing
  made is what to DO (tr_comp_out/7), and the word that asks with no phrase,
  before an infinitive, is `what` (the lesson's `qué` is `which` and `what`, and
  the infinitive's question was `which to eat`: tr_what_to/4) -- three arms; an
  infinitive with no object takes the verb of no object, where the lesson gives
  the meaning a transitive word of its own (`quisiera saber qué hacer` is
  `sapere cosa fare`, as the clause `sabe qué hace` is `sa cosa fa` -- the
  infinitive took `conoscere` whatever followed: tr_inf_lexeme/2); the past
  subjunctive of the verb of wanting, as a sentence's own verb, is a polite wish
  (`quisiera saber qué hacer` is I would like to know, and read as the imperfect
  it stands for after `si` it was he wanted to: tr_polite_wish/4), its first
  person spelled as its third (tr_form0/5), and the first person where the
  sentence names it by another word, a verb in the first person (`pues siento
  que me atrae`), English's wish `would like` (tr_write/4) and Italian's
  `vorrei`, never after a word that opens a clause (`Si quisiera dormir` is if
  he wanted, a guard) -- five arms; an adverb of time or focus after what there
  is stands with the verb (`También hay escritos de personas de Barcelona` --
  there are also writings, where `There are writings ... also` was written, and
  `ci sono anche scritti`: tr_write/4); `defines` governs `as` (`Aquelarre
  Infernal, que se define como "un punto de encuentro"` is defined AS one,
  en_governs/2), with the passive the lesson states (`"define" takes the
  passive.`); the impersonal `se` with a thing after its verb is the passive,
  where the lesson says the verb takes one (`En Internet se publica una revista
  para sus adeptos` -- a magazine is published, and English had somebody nobody
  named publish it, `One publishes a magazine`: tr_se_passive/2); English says
  what is on the Internet, a page or a site with `on` (`En esta página se
  ofrecen textos` are offered on this page, `En la Red existen páginas` exist on
  the Net: tr_comp_out/7, en_on_noun/1), and English's `the Internet`, which the
  lesson's languages name with no article (tr_np_out/5) -- two arms; an abstract
  noun in `-ism` is English's with no article (`con links contra el nazismo y el
  racismo` are links against nazism and racism, where `the nazism and the
  racism` was written: tr_write/4, en_ism_np/2), and a phrase of `of` after it
  keeps the article (`the optimism of the Russian military`, a guard) -- two
  arms; a word of two joined by a hyphen that opens on a nationality has its
  capital (`los satanistas hispanohablantes` are the Spanish-speaking satanists,
  en_nationality/1); `has` and a count of years is an age (`Tengo 14 años` is I
  am 14 years old, where English wrote `I have 14 years`: tr_write/4, age/1);
  `lleva` and a count of time is how long one has been somewhere (`Blackefer
  lleva tres años en la Red` has been on the Net for three years -- the lesson's
  `lleva` is `carries`, and English wrote `Blackefer carries three years in the
  Net`: tr_carries_time/3, the phrase of `for the past` that `desde hace`
  crosses to), and the lesson's language writes the copula and its own word for
  it (`è nella Rete da tre anni`, where it was `porta tre anni`); and a relative
  clause's plural phrase owns what its possessive names (`organizaciones
  luciferinas que tienen sus propias páginas oficiales` have THEIR own pages,
  and the lesson's first meaning wrote `his own official pages`:
  tr_plural_possessor/1). It needed these WORDS in `extra/` (the two readers: a
  line moves the reader of one language and the writer of the other; the
  dictionary's own word is said again first where it must stay the one
  written): Spanish `satánico` and `satánica` (satanic, and a satanist, a
  person), `satanista` (a satanist, a person, not feminine), `satanismo`, `cada
  vez más` (increasingly), `hispanohablante` (Spanish-speaking), `luciferino`
  and `luciferina`, `u` (or, the word for `or` before an o), `adepto` (a
  follower, a person; the dictionary has the adjective alone), with `seguidor`
  said again first, its own first meaning (a fan) and then the follower, so that
  it stays the word written for one, `hola` and `bienvenido` (the greetings, as
  interjections), `pues` (since, the conjunction, first), `web` (a website, where
  the dictionary's web is a spider's), `punto de encuentro` (a meeting point),
  `tablón` (a noticeboard, before the plank), `"define" takes "como" before the
  phrase.`, and the passive of `define`, `publica`, `ofrece` and `lee`; Italian
  `satanico` and `satanica`, `satanista` (not feminine, a person), `satanismo`,
  `sempre più` (increasingly), `ispanofono` and `ispanofona`, `luciferino` and
  `luciferina`, `ciao` and `benvenuto`, `sito web`, `visita` (visits, where the
  dictionary's verb tours), `punto di incontro`, `chat` (one word in both
  numbers, where the dictionary's plural was `chats` and its first noun for a
  chat `ciarla`), `bacheca`, `rivista` (a magazine, where the dictionary's first
  noun for one was a gun's, `caricatore`), `"definisce" takes "come" before the
  phrase.`, and the passive of `definisce`, `pubblica`, `offre` and `legge`. The
  first meaning moved for 2 Spanish words and 2 Italian ones (Spanish `tablón` a
  noticeboard, `web` a website; Italian `rivista` a magazine, `visita` visits),
  the writer's first word for 1 Spanish meaning and 4 Italian ones (Spanish
  website `web`; Italian chat `chat`, magazine `rivista`, visits `visita`,
  increasingly `sempre più`, where it was `vieppiù`), and none was lost.
  THE CONTROLS (cocolog 2.11.4, store KB230, 108 count files, 2 952 sentences:
  the earlier set with the islands report in, it_9485_9510, both directions;
  this report is not among them): the last version's translator against this
  one, on the one store, 29 sentences in 19 files read differently, all better
  but two that are no worse -- a noun in `-ism` with no article (10:
  `terrorism`, `francoism`, `nazism` and six `presidentialism`: `you answer with
  presidentialism`, `like an opening to presidentialism`), `which restated their
  basic agreement` and `il loro accordo basico` (es_20000802-31 8), the verb of
  knowing for an infinitive with no object (`ha hecho saber`, `Esperamos saber`,
  `Necessito sapere più`, `Vuoi sapere se il tuo matrimonio avrà successo?`, and
  Tatoeba's `Neither I know what to do` and `Neanche io so cosa fare`), the
  polite wish (`neither I would like to trample the feet to nobody`, Italian
  `Vorrebbe una coppa di caffè`, English `They would want`), `their problems
  can be understood only speaking with the common people` and `Can the names be
  changed of user?`, `there is also disparity` and `hay también disparidad`
  (it_9926_9946 9), `I have ended up on first page`, and the second agent with
  its day (`presented yesterday by the minister ... and by the general director`
  and `y por el director general`, where it was `desde`, it_9637_9672 8) -- and
  the two no worse: `Non posso cessare` for `No puedo parar` (Tatoeba 6, where
  `Non posso fermare` was written; neither is `fermarmi`) and `sapere` in the
  Miss World report's fifteenth sentence, whose misreading takes the object for
  the subject in both texts (`Come potranno la nostra personalità e la nostra
  capacità sapere`). The inferences rise 0.115 % (7 701 216 890 to 7 710 041
  276), 0.125 % outside the two sentences the new store reads faster (below);
  every sentence rises but four, and the largest rises are the Hotel Arts
  report's tenth (+0.19 million of 49.98, refused both ways), the Rognoni
  interview's nineteenth (+0.10 of 387.29, refused) and the Venice report's
  eighth (+0.07 of 394.36); the files that rise most are Tatoeba's into English,
  +0.46 % of 45.5 million, and the Yeltsin report's into English, +0.45 % of 6.2,
  and the sentences that fall most are the Rosi report's 26th (8.17 million to
  8.10) and it_9637_9672 14 (0.28 to 0.24). Bytes and characters read every
  sentence alike (0 differ, the bytes 0.014 % more). The DATA COLUMN (the last
  version's translator on its own store, KB226, against this one on the new): 32
  sentences in 20 files, -9.164 % (8 487 898 521 to 7 710 041 276), +0.146 %
  outside the two sentences the new store reads faster. THE CODE ALONE (this
  translator on KB226): the same 29 sentences, +0.106 % (to 8 496 894 113),
  +0.125 % outside the two. THE STORE ALONE (the last version's translator on
  KB226 and on KB230): 3 sentences in 3 files, -9.268 % (to 7 701 216 890),
  +0.021 % outside the two -- `sempre più` is one adverb now, increasingly: the
  Rognoni interview's nineteenth sentence (`il mondo sempre più complesso delle
  tv`), refused both ways, falls from 773.61 million inferences to 387.29 in
  each language, and it_9637_9672 19 from 18.2 million to 10.5, where `la
  maggioranza dei poveri sta andando sempre più sotto` is `is going ...
  increasingly below` and `está yendo cada vez más abajo`, where it was `always
  ... more below` and `siempre más abajo`; and `visited` for `toured`
  (it_9947_9966 16).
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column and
  mended, each with its arm red. Of the code (the first round, 32 sentences in 21
  files, +0.519 %): the word for `how` before an infinitive asked after any verb,
  and Italian's `come`, which is `like` as well, turned two similes into
  questions (`Ma parlare con Diego era come parlare con due persone diverse` was
  `was how to speak` and `era cómo hablar`, and `È come cavalcare una tigre` `Es
  cómo cabalgar`, it_9540_9566 8 and 15: a verb that takes the question now,
  tr_asks_question_here/0); and the second agent wrote the day's adverb after
  the first (`presented by the minister ... Adriano Ossicini yesterday and by the
  general director`, it_9637_9672 8: tr_ptc_day_first/4). Of the store (a
  first store, KB229): the line that keeps `seguidor` the Spanish writer's word
  for a follower, said first, made the follower its first meaning to the reader,
  and every `seguidores` was followers (`the English followers` and `gli adepti
  inglesi` for the English fans, es_19990601-13 5; `In front of followers of the
  match` and `Davanti a adepti della partita`, es_20020801-17 5): its own first
  meaning, a fan, is said first now, and the follower after it. THE COST OF THE
  CODE, FOUND BY TAKING EACH RULE OUT (the twelve heaviest risers of the first
  round, six from Spanish and six from Italian, into English, over a copy of the
  library per rule): the first cut rose 15.04 million inferences of 232.42
  (+6.47 %), and two rules were 98 % of it -- the participle and its agent after
  a noun and its phrase, asked of every phrase with a participle in it (13.43
  million: the Hotel Arts report's tenth sentence rose 8.14 million, 49.98 to
  58.13, and its fourteenth 3.27, both refusals), and the clause of `where`
  that ends at a coordinator, asked of every word for `where` (1.25
  million: it_9472_9484 10 rose 1.19 of 5.00). What paid was a note made once a
  sentence for each (`$tr_ptc_agent`, `$tr_where_co`) and two cheap tests first:
  the participle's clause is asked only where a noun or an adjective right before
  a participle disagrees with it in number or gender (12.48 million of the
  13.43; the first note took any noun before a participle, and `debería ser
  refrendada por` fired it, so an infinitive is no noun there: 0.69 million),
  and the clause of `where` only where no comma comes after the word and the
  phrase after the coordinator has four words at most or ends at its own word
  for `where` (2.05 million; the note 0.60). The four arms that take the tests
  out stay green in the section, as a guard of cost does. The final cut rises
  0.39 million of the twelve (232.42 to 232.81, +0.17 %), the second agent most
  of it (the Hotel Arts tenth sentence +0.19 million of 49.98, its refusal the
  same). THE STATED COSTS: a first meaning that serves the news and not every
  text -- `web` is a website (a spider's web second), `tablón` a noticeboard (a
  plank second), `rivista` a magazine (a journal second), `visita` visits (tours
  second) -- and the writer's `web`, `chat`, `rivista`, `visita` and `sempre
  più` for those meanings; Italian `Non posso cessare` for Tatoeba's `No puedo
  parar` (`fermare`, the transitive word, was the one written: neither says
  `fermarmi`); `sapere` in the Miss World report's fifteenth sentence, whose
  misreading takes the object for the subject in both texts; and the inferences,
  +0.115 % on the one store and +0.106 % on the old. The report LEAVES, of the 15
  into Italian (English alike unless it says): `dalle stesse fratellanze` and
  `the same fraternities` (2: the fraternities themselves); `in alcuni di loro`
  for the pages (3: `in alcune di esse`, the pronoun's gender is the phrase's it
  stands for, which the IR does not keep), written last where the source has it
  first, and `diverse ads`; `Vorrei` with a capital after the dots (4); `Vivo`
  read as a name (5: the source has the capital); `in uno di quelli assi` and
  `that one reads in one of those boards` (6: `quelle bacheche`, that is read on
  one of those noticeboards); `scritture` for `escritos` (7: `scritti`);
  `allacciare` for `enlazar` and `in questa pagina` written last (10: link, and
  in English `curiously` last and `nazism` in small letters); `prega il suo
  androne` and `his entrance prays` for what its entrance reads, and `qui`
  written last (12); `in Internet` (14: `su Internet`) and English's `his
  followers` (its); `La Hermandad di Satán` and `His title is Pulp Fiction ...
  of La Hermandad of Satán` (15: a name of two words with its article, kept in
  Spanish, and its title); and in 16 `della Chiesa del Virus` for the third of
  the list and `Rilascio` for the liberation, English `luciferian` in small
  letters, `who has 20,000 followers` and `Release`. Into English, 8 is `who is
  defined` (which). Into English 4 and 9 are refused for the third person nobody
  names, on purpose (`me atrae poderosamente la atención` takes the attention for
  its object, and `Está abierta por un miembro` names the page by nothing), and
  into both languages 13 and 17: 13, a list with `además de` and a bracket that
  holds a clause (`(uno de ellos es de Catalunya)`), and 17, a list of names
  after a colon (`Otras webs sobre el tema son: Los Satanistas, Templo Tezcat,
  ...`). The next sample's controls take this report in.
  The Caetano Veloso interview (VIT-9225..9269, 45 sentences, Italian into
  Spanish and English: 45 of 45 and 40 of 45 on a fresh store, 34 and 31 with
  the new store alone, 18 and 18 with the new code on the old store, 17 and 16
  before; reasoning 1.0.19). The sample was taken on the cocolog 2.12.0 binary,
  master's d71af1e merged as 1fe7ecb and built with Cicili a9e2dcf from a copy
  (the owner, 2026-10-28: no pull of ../cicili, the last Cicili commit), and
  cocolog stays 2.12.0: the controls read every sentence alike on 2.11.4 and
  2.12.0 (2 952, 0 differ), 0.292 % fewer inferences (sub_atom/5's one scan).
  The article's sentences fall from 245.0 million inferences in each language to
  91.1 into Spanish and 91.2 into English, of which the fourth (`Va sottobraccio
  ...`) is 14.6 and 14.7 million. It needed these SHAPES, each with its arm red
  (test/translate.pl's `newspaper_veloso`: 71 checks, 78 arms, the guards among
  them -- 75 red in the section, one red in newspaper_units, and two guards of
  cost that stay green, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_veloso, checks_done"`, three
  seconds a run, and every arm is run in a minute, four at a time): a byline
  before its dateline (`Dal nostro inviato Giacomo Pellicciotti Perugia -
  passeggiando di sera ...` is the correspondent who signs the report and the
  city it comes from, with no comma between them, and the city was read as the
  name's third word: tr_byline/3); a street's name whose first word the paper
  writes small, right after a preposition (`per corso Vannucci`, where `corso`
  was the course: tr_stated_names0/2, `The word "corso" begins the name.`), and
  a name in small letters right after a common noun, which takes its capital
  (`al teatro morlacchi`); any capitalised word the lesson states as a
  contraction begins a surname before a capital (`il generale Dalla Chiesa`,
  where `de`, `del`, `di` and `da` alone did) and ends one after a first name
  (`Lucio Dalla mi ha invitato a Napoli` -- read as `da la`, from the, with
  nothing after it, the sentence was refused: tr_particle_names/4), never inside
  a title the paper writes in capitals (`il Presidente Della Repubblica` is the
  president of the Republic, a guard the controls found); an article and the
  word for `first` before the relative are a phrase and its clause (`è stata la
  prima che ho sentito` is the first one I heard, and `prima che` was the
  conjunction: tr_unjoin_ordinal/3); a phrase with no article that opens on a
  focus adverb, between two commas after a noun, is an aside, the adverb at its
  head in every language (`il boss della compagnia discografica Paramount, anche
  produttore cinematografico, ...` is the boss, also a film producer:
  tr_asides/3, advnp/2, tr_aside_out/6) -- three arms; the copula and a subject
  pronoun alone are no comment between commas (`ed è lui, senza dubbio, il
  trionfatore incontrastato del festival` says who the victor is), and a third
  person's pronoun after the copula, before a phrase with its article, is the
  subject (`è lui il trionfatore`); the word for `all` before a phrase is a
  list's word (`Pinelli, Flaiano, Zavattini e tutti gli sceneggiatori di quei
  film` is one list of four), and opens a phrase of its own number (`tutti il
  pane` is none); with nothing before the phrase a pronoun takes up again, the
  words after the verb may be its subject (`l'italiano me l'hanno insegnato
  Pinelli, Flaiano, ...` is they taught me Italian); a partitive pronoun beside
  a subject of quantity is said once (`Oggi non ce n'è rimasto più nessuno`,
  where `ne` crossed as `it`); a person named by a noun with no gender of its
  own, after a feminine article or possessive, is a woman (`la versione di una
  cantante`, `una nostra collega`); a decade named in words (`alla fine degli
  anni cinquanta` is the end of the 50s, where it was `the fifty years`); a name
  the source kept as itself is written as it stood, though English knows the
  word (`la compagnia discografica Paramount`, `kept/1`); a pronoun of quantity
  after the verb, with the partitive said once (`ne ho visti tanti fino
  all'ossessione` is I have seen so many), and the determiner `tanti` is `so
  many`; a name after the word for `with` and a bare noun for a person right
  after it say what the ones named are (`con Lucio Dalla, Fiorella Mannoia,
  Renzo Arbore e lo stilista Romeo Gigli promotori di un immaginario fanclub`
  are the promoters, role/1); a word that says how likely the sentence is stays
  in front (`Forse non le era piaciuto` is maybe she had not liked it); a
  subject before the question word, and a phrase set in front and its subject
  (`Ma la musica italiana Caetano come l'ha scoperta?` is how Caetano discovered
  Italian music, where the music, the name apposed to it, had discovered him:
  tr_dislocation_fix/3); a phrase with its relative clause set in front has the
  phrase's number (`il pane che ho, l'ho mangiato`, tr_fronted_np_number/2 --
  asked there alone: a phrase's number through its clause everywhere, the first
  cut, let `es el mensaje que ha repetido con insistencia` have the message for
  the subject of `es`, `the message that they have repeated is with insistence`,
  and read three more sentences of the controls wrong, a guard), and a phrase,
  its phrase of `of` and a relative clause said of the whole (`quel po'
  d'italiano che so, l'ho imparato al cinema`, tr_front_phrase/3); the verb of
  being about to takes its infinitive as a modal does, and the phrase after an
  intransitive one is its subject (`stava per uscire Transa` is the record that
  was about to come out) -- never between an article with its adjective and
  their noun, nor at a name apposed to a person's noun, nor at an article right
  after a name (`Va sottobraccio alla bella moglie Paola`, `con Gilda l'ex
  compagna di Vinicius De Moraes al fianco`), and only for a phrase for a
  person, as an apposition is (`circolava in Brasile la versione di una
  cantante`) -- three guards; the pronoun of the verb's own person right after
  the copula is the subject (`Ero io il re`, `decise che dovevo assolutamente
  essere io il San Francesco del film di Zeffirelli`); a count above one makes
  plural a noun that is its own plural (`Tre recital di straordinaria malia`),
  never the unit of a percentage (`pari all'87 per cento`, a guard the whole
  case found); a relative clause after the comma that closes a participle's
  aside is the phrase's (`con quella sua voce lieve, sussurrata, che è già
  musica`); a language after a verb of learning, teaching or speaking takes no
  article in English (`l'italiano me l'hanno insegnato` taught me Italian) and
  no `a` in Spanish; a verb that says what its subject remains takes no `a`
  before the phrase (`Il regista favorito resta comunque Federico Fellini`,
  `queda Federico Fellini`, en_copular/1); the word for `all` after the verb of
  a plural subject nobody names is the subject's (`Così partimmo tutti` is so we
  all left); THE ONE WHO LIKES IS ENGLISH'S SUBJECT (`Forse non le era piaciuto`
  is maybe she had not liked it, `Il cane mi piace` I like the dog: the lesson's
  languages make the thing liked the subject, and English wrote `The dog pleases
  me` or refused a clause with nobody named), the person a phrase of `to` names
  being the one the pronoun says again (`A Tom le gustan las morenas` is Tom
  likes them, where it was `He likes the dark ones to Tom`: tr_liker_phrase/2,
  found by the controls), and an infinitive liked written after `likes` (`a me
  piace stare in mezzo alla gente` is I like to be among the people -- refused,
  the infinitive having no writer as an object -- and with nobody named no `it`,
  `Me gusta comer` is I like to eat) -- five arms; A COUNTRY TAKES NO ARTICLE IN
  ENGLISH (`l'Italia è un sentimento` is Italy is a feeling, `"italia" is a
  country.`, tr_country_det/4) nor in Spanish, whose lesson does not say its
  article takes the country, as Italian's does (`"il" takes the country.`), and
  a country a relative clause hangs on keeps it (`l'Italia che soffre`,
  '$tr_keep_det'); a possessive after its noun is the phrase's determiner (`a
  casa sua`), and after another determiner `of` and the pronoun (`quella sua
  voce` is that voice of his, Spanish `esa voz suya`, tr_poss_after/3); `not
  even` stands before the phrase it is said of (`neanche uno strapuntino
  libero`), and before the object of a denied clause it is `even` (`non si trova
  nemmeno un trafiletto` does not find even a snippet, the controls' double
  denial); `big` and `small` said of a brother or a sister are `older` and
  `younger` (`mia sorella più grande`); THE PLACE ONE ARRIVES OR STAYS AT IS A
  PHRASE OF `at` (`arrivammo nel tardo pomeriggio all'Excelsior`, `i passaporti
  erano rimasti all'Excelsior`; a city or a country `in`), never a number, a
  time or a person (`rimase dal 1990 al 1995` is a range), `time` (`Tom llegó a
  tiempo`) and the phrase of the adjective of `remains` (`era rimasto ignoto al
  medioevo occidentale` is unknown TO the Middle Ages) -- guards the controls
  found; an adverb that comments on the whole clause after it is set off by its
  comma (`..., chissà`, who knows); `can` has no perfect, `has been able to`
  says it, and its participle is `been able` (`non ho potuto mangiare per un
  giorno intero`, `di non aver mai potuto incontrare Fellini`, where it was
  `caned`); `attests` governs `to`, `answers` takes its phrase bare (`ha
  risposto al telefono` answered the phone), never a bare singular noun, which
  says how (`abbiamo risposto a tema` answered to the point, a guard both
  writers keep); and `asks` takes `for` before its object (`chiedeva una copia
  del mio disco`), never before the one asked (`el gato pide que Pedro duerma`,
  a guard the whole case found) nor before the object of an infinitive after it
  (`mi ha chiesto di indicargli un'edicola` asked me to indicate a kiosk, and
  with the verb of asking still the one written it came out `to indicate him for
  a kiosk`: tr_comps_out/7 writes the object after an infinitive under the
  infinitive's verb, a rule the controls found). It needed these WORDS in
  `extra/` (the two readers: a line moves the reader of one language and the
  writer of the other; the dictionary's own word is said again first where it
  must stay the one written): Italian `natio` (native), `paesino` (a village),
  the names `Santo Amaro`, `morlacchi` and `Luna Rossa` (the song, `rossa` being
  the colour), `sottobraccio a` (arm in arm with), `incrocia` and `incontra`
  (meets, before finds), `fastidiosamente`, `trionfatore` (a victor, a person),
  `incontrastato`, `incanto` and `malia` (charm), `strapuntino` (a folding
  seat), `cantautore` (a singer-songwriter), `fanclub`, `sussurra` (whispers)
  and its participles, `sceneggiatore` (a screenwriter), `indimenticabile`,
  `regista` (a director, not feminine), `capita` (happens, intransitive, its
  perfect with the copula), `auditorio`, the copula as the auxiliary of `piace`
  and `dispiace`, `recapita` (delivers), `passeggiatrice` (a streetwalker),
  `gradisce` (appreciates), `napoletano` (Neapolitan, the adjective and the
  noun), `tragicomico`, `esule`, `boss`, `schiaffa` (throws), `mattino`,
  `provvidenziale`, `maestoso`, `cogli` (the contraction of `con gli`, read and
  not written: the identity first), the adverbs `nel tardo pomeriggio`, `per la
  seconda volta`, `per la terza volta`, `chissà` (who knows, before the
  dictionary's maybe), `a memoria` (by heart) and `di sera` (in the evening),
  the pronouns `tanti` and `tante` (so many, after the verb), `recital` (its own
  plural), `inviato` (a correspondent, a person), `per conto di` (on behalf of),
  `ce` the particle of `è`, `n'` the elision of `ne`, `po` (a bit: the tokeniser
  drops the apostrophe of `po'`), the countries, regions and continents
  (`italia`, `francia`, `germania`, `inghilterra`, `spagna`, `giappone`,
  `brasile`, `grecia`, `russia`, `israele`; `cecenia`, `catalogna`, `sardegna`,
  `sicilia`; `europa`, and `asia`, `africa` and `america` with their English
  names), `"il" takes the country.`, `"risponde" takes "a" before the phrase.`,
  `"testimonia" takes "di" before the phrase.` and `"sang" is the past of
  "sings".` (the upstream verb table's past of sing is `sung`); Spanish `del
  brazo de`, `de forma molesta`, `triunfador`, `indiscutible`, `traspuntín`,
  `cantautor`, `club de fans`, `prostituta callejera`, `napolitano`,
  `tragicómico`, `exiliado`, `providencial`, `majestuoso`, `a última hora de la
  tarde`, `por segunda vez`, `por tercera vez`, the pronoun `tantos`, `quién
  sabe`, `libre`, `corresponsal`, `en nombre de`, `de memoria`, `poco` (a bit),
  the same countries, regions and continents (`catalunya` too, and `áfrica` and
  `américa`), `ladrón` (a thief: the dictionary has the feminine `ladrona`
  alone), `natal` (native, where the writer's first was `indígena`), `por la
  noche` (in the evening), `"sang" is the past of "sings".`, and `policía` with
  a gender per sense (the police, feminine, and the policeman, masculine: the
  dictionary gives the noun no gender of its own and the builder denied the
  feminine, so the force was `el policía`). The first meaning moved for 5
  Italian words and 3 Spanish ones (Italian `chissà` who knows, `incanto` a
  charm, `inviato` a correspondent, `incontra` meets, in a line of its meaning
  alone, and `consegna` delivers, the verb's meaning said again first, its
  noun's links keeping `the delivery`; Spanish `indiscutible` undisputed,
  `natal` native, `pizca` a bit), the writer's first word for 3 Italian meanings
  and 6 Spanish ones (Italian exiled `esule`, charm `incanto`, meets `incontra`;
  Spanish free `libre`, as an adjective and as an adverb, native `natal`, bit
  `pizca`, thief `ladrón`, meets `encuentra`), and none was lost. Said again
  first, each in a line of its meaning alone, so that they stay the words
  written: Italian `nativo`, `borgo`, `bisbiglia`, `direttore`, `auditorium`,
  `consegna`, `apprezza`, `getta`, `mattina`, `corrispondente` and `pezzetto`;
  and Spanish `encuentra`, finds and then meets, so that the writer's verb for
  meets is no longer the dictionary's `conoce`; and `pizca`, not `poco`, is the
  Spanish bit. THE CONTROLS (cocolog 2.12.0, store KB236, 110 count files, 2 986
  sentences: the earlier set with the satanic report in, es_19991102-2, both
  directions; this interview is not among them): the last version's translator
  against this one, on the one store, 62 sentences in 24 files read differently,
  all better but five that are no worse -- a country, a region or a continent
  with no article (19: `Italy has had four governments`, `if Europe, in name of
  a "peace"`, `while France assigns 2 per cent ... and Germany between`, `of
  Sardinia`, `The discovery of America`, Spanish `Italia está viviendo`, `entre
  Europa y Asia`, `El descubrimiento de América`), `asks for` and the object of
  an infinitive written under the infinitive's own verb (8: `You should ask for
  the repayment`, `is also asking for the vote`, `has asked ... for a new
  deliberation`, `must search for a cause`, `I will search to illustrate a space
  mission`, where it was `to illustrate for`), the one who likes as English's
  subject (9: `he likes the good football`, `He liked this, I must say`, `Do you
  like the music?`, `She likes the freezing ones`, `Tom likes the dark ones`, `I
  like to be among the people`, `I like to walk in train`), `so many` (4),
  `arrived at` (4: `arrived at an agreement`, `if one arrives at the
  signature`), `Al Fatah` (2, where it was `To the Fatah`), `would have been
  able to` (2, where it was `caned`), `maybe` and `perhaps` in front (4), `they
  all took it`, `one does not find even a snippet` (where it was `a snippet not
  even`), and Spanish `esta negociación mía`, `queda accionista`, `nuestra
  colega` and Italian `un'applicazione Android` -- and the five no worse: `su
  asistenta de siempre` and `la boda de su parienta` (it_10059_10095 22,
  it_9800_9814 4: a woman the source names in the feminine, where `ayudante` and
  `pariente` were written), `return to his house` (it_9851_9925 48, `hers house`
  before, where `her` is the text), `I like solo only` and `Would you like the
  White House White some day?` (tat 118 and 394, as wrong as `Solo pleases me
  only` and `Would the White House please you White`). The inferences rise 0.109
  % (7 731 781 045 to 7 740 206 054); the sentence that rises most is
  it_9967_9998 22 (+1.28 million of 38.4 in each language, below), then Tempi's
  twentieth (+0.14 of 517.2, refused both ways), and the files that rise most
  are es_19991202-35's and Tatoeba's, +0.6 %. Bytes and characters read every
  sentence alike (0 differ, the bytes 0.009 % more). The DATA COLUMN (the last
  version's translator on its own store, KB230, against this one on the new): 76
  sentences in 27 files, +0.165 % (7 727 434 145 to 7 740 206 054). THE CODE
  ALONE (this translator on KB230): 44 sentences in 20 files, every one among
  the 62, +0.109 % (to 7 735 859 984). THE STORE ALONE (the last version's
  translator on KB230 and on KB236): 15 sentences in 8 files, +0.056 % (to 7 731
  781 045), all better but one -- `Africa` for `África` (5, both languages),
  `meet` for `find` (4, English: `to meet the students`, `will return to meet on
  Tuesday`, `I certainly did not think to meet the professor`, `Then I meet him
  with Cesare`), `the correspondents of "La Repubblica"` and `los
  corresponsales`, where they were envoys, `el tiempo libre`, where it was
  `gratuito`, and `del América` -- and `alle otto di sera di una domenica`, now
  `to the eight of a Sunday ... now in the evening` (it_10059_10095 7: the line
  that makes `di sera` one adverb lifts it out of the time), a stated cost. A
  FIRST STORE WAS 2.36 % DEARER FOR ONE LINE: `The article "il" takes the
  country.` teaches `article(il)` beside `take(il, country)`, and the store held
  `article(il)` three times already (the lines of the possessive and the year
  among them); tr_class_of/2 asks `G =.. [C, W], tr_solve(G)` with no once/1, so
  each copy of a class fact is one more whole reading of every `il` -- found by
  teaching KB230 with each of 17 groups of the new Italian lines and counting
  six heavy sentences of the store's risers (+20.6 % for that line, +0.8 % for
  the pronouns `tanti` and `tante`, nothing for the rest), and the line is `"il"
  takes the country.` now, which teaches `take(il, country)` alone. The words
  said again first are lines of a meaning alone for the same reason
  (`"direttore" means "director".`: no class taught twice). AN OPEN LEAD:
  tr_class_of/2 made deterministic for a bound word, and the store's two other
  copies of `article(il)` taken out, would take a large part of the cost of
  every Italian sentence away; it changes every count, and is a commit of its
  own. THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column
  and mended, each with its arm red (test/translate.pl's 11 checks at the end of
  the section): the number of a phrase through its relative clause, asked
  everywhere (a clause of fo_np_number/2), made `es el mensaje que ha repetido
  con insistencia` `the message that they have repeated is with insistence`
  (es_20010103-120 16), Millàs' `a quien ... está "abierto"` `aperta` and an
  English with the quotation's halves out of order (es_20020301-125 13), `qué
  consecuencias` `cose conseguenze` (9) and `promesse ingannevoli` `have been
  promised` (it_9800_9814 14), and is asked of the phrase set in front alone now
  (tr_fronted_np_number/2, a guard); the liking rule wrote `He likes the dark
  ones to Tom` and refused `a me piace stare in mezzo alla gente` and `Me gusta
  andar en tren`, the infinitive liked having no writer as an object
  (tr_liker_phrase/2, an infinitive subject, and with nobody named no `it`:
  three arms); `asks for` came before the object of the infinitive after it
  (`asked me to indicate him for a kiosk`, it_9800_9814 4: tr_comps_out/7 writes
  that object under the infinitive's verb); `answers` took a bare singular noun
  bare (`we have answered topic`, `hemos contestado tema`, it_9714_9749 4: both
  writers keep its preposition, two arms); `at` after `remains` took the
  adjective's phrase (`remained unknown at the western middle ages`,
  it_9967_9998 14) and a time (`Tom arrived at time`, tat 76); `does not find
  not even a snippet` (it_9851_9925 32); a capitalised contraction inside a
  title was a name (`the president Della Repubblica`, it_9926_9946 5, both
  languages); the store's words came first for the writers -- Italian `regista`
  for every director, `incrocia` for meets, `schiaffare` for throws (which
  refused `No nos echaremos al monte`, es_20020801-17 11), `paesino` for a
  village and the bare `po` for a bit, Spanish `poco` as a noun (which refused
  es_20011002-160 5, `como pocos`) and `conoce` for meets once `incontra` meant
  it (`regresarán a conocerse`) -- now the dictionary's words said again first,
  `pizca` for the bit and `encuentra` for meets; and bytes and characters read
  five sentences apart, downcase_atom/2 leaving the accented capital of `África`
  alone under bytes (tr_downcase_units/2, and a probe in newspaper_units, its
  arm red there). THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the
  thirteen sentences of 0.3 to 3.6 million inferences that rose most, Italian
  into English, over a copy of the library per rule on KB230): the second cut
  was +0.566 % of the controls, and the thirteen rose 415 thousand inferences of
  12.7 million (+3.26 %), 90 % of it one rule, the pronoun of the first or the
  second person after the copula (`Ero io il re`), a clause of
  tr_read_statement0/4 that walked every piece it was asked; with a note made
  once a sentence (`$tr_pron_copula`, tr_pron_copula_note/1: the copula, such a
  pronoun and a determiner) they rose +0.47 %, and with the inverted subject of
  a phrase set in front asked only on a subject's first word
  (tr_subject_opener/1) and for sixteen words at most +0.32 % (the note's own
  scan 18 thousand of the 40 thousand left, the unjoined ordinal 8, the role
  after `with` 6). The cap was found by it_9967_9998 22, `Che poi queste cose le
  sapessero i dotti e i semplici no, guardate che ...`, whose 28 words after the
  verb were parsed for a subject at every reading: +3.14 million inferences of
  38.4 in each language, and +1.28 with the cap, the shorter pieces, the text
  the same. Both guards stay for their cost, their arms green in the section.
  THE STATED COSTS: `di sera` lifted out of a time of day (above); `"encuentra"
  means "meets".` writes `incontrare Fellini` as `encontrar a Fellini`, where it
  was `conocer`, right for a first meeting; the pronouns `tanti` and `tante`
  (+0.67 million inferences on it_9851_9925 32, `tanti altri nel nostro campo`);
  and the inferences, +0.109 % for the code and +0.056 % for the store. Master's
  2.12.1 (1c25b57, the trail and the variable map's words widened to 64 bits, in
  master as 8e63396) came during the sample; the next sample takes it. The
  interview LEAVES, of the 45 into Spanish (English alike unless it says): `amor
  para el cine` (1: `por`); `paseando por la noche para Corso Vannucci` and
  `strolling for` (3: `por`), `se encuentra a casa suya` and `finds to his
  house` (at home), `en el natal pueblo` (`en su pueblo natal`); `con Gilda a la
  ex compañera` (4: no `a`), `encuentra cariciosamente el amigo` (`saluda con
  cariño a su amigo`) and `a esposa y niños`; `like an old and expensive friend
  ever annoyingly` (5: `mai fastidiosamente` is never annoyingly, and `caro`
  dear); `al teatro Morlacchi` and `to the theatre` (7: `en el`), `tantas
  personas quedadas fuera` and `so many remained people away`; `del criticismo`
  (8: `de la crítica`); `ha sido siempre presente` and `since boy` (9); `los he
  visto todas estas películas` and `I, then, I have seen them all these films`
  (12: the object said twice); `que conozco` (14: `que sé`), `al cine` and `to
  the cinema`, `listening the dialogs`; `A 15 años` and `To 15 years` (17: `a
  los 15`), and `La strada`, a film, read as the road; 18, `Le notti di Cabiria
  è una delle cose più belle`, a film's title read as a plural phrase and set
  last (`que ha visto nunca las noches de Cabiria`); `El único grueso dolor` and
  `thick pain` (19); 20 out of order (`"Time Zones" me ha pasado cantar ... en
  Bari para el festival`); `destination` for `destino` (21); `A Voice of woman
  ... to her dedicated` (23); `Le he hecho entregar el disco a casa desde un
  amigo` and `I have made her to deliver the disc to house from a friend` (24: I
  had a friend deliver it to her home); `he sentido` and `felt` for heard (29,
  31); 33 out of order in both (`La canto aquí desde vosotros antes en Nápoles
  ... por eso hoy`, `a hopelessly mine song`); `The tale ... curious and
  tragicomic` (34: the predicate set first in the source); `the discographic
  Paramount company` (35); `desde un par de horas` and `from a pair of hours`
  (38: for a couple of hours), `quedado al Excelsior` (`en el`); `They put us to
  the six of the morning ... away` (40: let us out at six); `en Nápoles` (41:
  `a`), `they would also want` (he would like), `adesso` last; `Soy como en
  cielo` (42: `Estoy como en el cielo`); `devuelvo a niño` and `I return boy`
  (43: `vuelvo a ser niño`); `arranca al mismo` (44: `salta igualmente`); and
  `atestigua de su gran amor para Italia` (45). Into English 4, 8, 26, 28 (its
  reporting clause) and 29 are refused for the third person nobody names, on
  purpose (`Va sottobraccio ...`, `Ha vinto anche ...`, `Era stato anche
  proibito ...`, `Sorride ricordando:`, `perché è stata la prima che ho
  sentito`). The next sample's controls take this interview in.
  The Corsica report (AnCora CESS-CAST-P-20000802-26, 13 sentences, Spanish into
  Italian and English: 10 of 13 and 8 of 13 on a fresh store, 8 and 6 with the
  new store alone, 4 and 4 with the new code on the old store, 4 and 5 before;
  reasoning 1.0.20). The sample was taken on the cocolog 2.13.0 binary, built
  with Cicili 9b825b7 from a copy (master's b208233 merged as 6d98d68), and
  cocolog stays 2.13.0: the controls read every sentence alike on 2.12.1 and
  2.13.0 (3 076 sentences, 0 differ, 7 922 477 800 inferences on both). The
  article's sentences fall from 107.0 million inferences into Italian and 106.6
  into English to 37.9 and 37.5, of which the sixth, refused, is 13.4 million in
  each and the fifth, refused, 9.7. The new code on the old store reads one
  English sentence fewer than the old code, the eleventh: its clause of `that'
  is the verb's with nobody named now, which English refuses on purpose, where
  the old text was `who did not have "anything that to add"'. It needed these
  SHAPES, each with its arm red (test/translate.pl's `newspaper_corsica': 40
  checks, 34 arms, the guards among them -- 33 red, and one guard of cost that
  stays green, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_corsica, checks_done"', under a
  second a run, and every arm is run in four seconds, four at a time): AN
  APPOSITION WITH AN ARTICLE THAT ENDS ON A NAME, AFTER A NOUN OR AN ADJECTIVE
  IN SMALL LETTERS (`El presidente francés, el gaullista Jacques Chirac, lanzó
  ayer una seria advertencia' -- read as a heading up to the first comma, the
  clause had nobody named, which English refused: tr_asides/3), the name at its
  end what makes it one (`El perro, el gato, duerme.' stays refused, a guard),
  and `Gaullist', `Corsican' and `Mediterranean' take their capitals
  (en_nationality/1) -- three arms; A COUNTRY OR A REGION TAKES ITS ARTICLE IN A
  LESSON'S LANGUAGE THAT SAYS IT DOES (`"il" takes the country.'): `las reformas
  preconizadas para Córcega' are `per la Corsica' and `entre Inglaterra y
  Alemania' `tra l'Inghilterra e la Germania', where the bare name the source
  gave was written (tr_country_articles/2, from tr_from_ir/5 into the lesson's
  language), only for a name whose gender the lesson states (`"corsica" is
  feminine.'; `Israele' takes none), never after `in', names joined there too
  (`in Francia e Germania', which the first cut wrote `nella Francia e nella
  Germania'), after a verb of going its `to' is `in' and the name bare (`va in
  Francia', where it was `va a Francia' and the first cut wrote `va alla
  Francia'; a thing given keeps the article, `dà un libro alla Francia':
  tr_country_motion/2), the name stays bare after a phrase whose noun has its
  capital, a name's own (`el 50 aniversario de Radio Nacional de España' is `di
  Radio Nazionale di Spagna', `los elegidos de la Asamblea de Córcega' are of
  the `Assemblea di Corsica'; after a common noun it has one, `la capitale della
  Francia'), after a superlative (`el empresario petrolero más rico de Italia'
  is the `più ricco d'Italia') and alone in a bracket (`de Cremona (Italia)':
  tr_country_seq/3, tr_bare_country_after/1), and a quotation that opens on the
  name opens on the article (`sólo señaló que "España ve con simpatía la
  candidatura"' is `che "la Spagna vede', where the first cut wrote `che la
  "Spagna') -- ten arms, the guards among them; the rule is asked only of a
  sentence that crossed a name the lesson gives a meaning ('$tr_xnames'), a
  guard of cost whose arm stays green: an English text reads `Italy' as a noun
  and never meets the rule (`Italy is beautiful' is `Italia è bella' still, a
  lead); a participle between commas with its agent (`Córcega, sacudida desde
  hace años por los atentados nacionalistas, ...' was shaken BY them --
  `sacudida' is a noun too, and read as an adjunct the agent was `for the
  attacks', `per gli attentati': tr_aside_inner0/2) -- two arms; a participle
  between commas after a phrase and its phrases of `of' is the head's where it
  agrees with the head (`El plan de autonomía para Córcega, propuesto por el
  Gobierno de Jospin ...' was proposed, and hung on Corsica it was `la Corsica,
  proposta': tr_aside_head_fix/3, tr_ptc_fits/2; a guard that it must not agree
  with the last noun as well had a green arm and is gone); a quotation that
  opens on the modal (`las medidas que se adopten "deben respetar los
  principios"' must respect them, where English said they `owe to respect', and
  Italian's `"bisogna leggere ..."' is `"hay que leer"', as with no marks:
  tr_inf_after_advs/2); a small word after the first of a name of several stays
  small (`durante la reunión del Consejo de Ministros' is the Council of
  Ministers and the `Consiglio dei Ministri', where every word took its capital:
  tr_cap_words/2) -- two arms; a share of a plural after the verb agrees with a
  plural verb (`que "se imponen" una serie de reformas', which had no reading:
  tr_subject_after/5); two participles and their agents, the first agent with
  phrases of its own (`propuesto por el Gobierno de Jospin y aprobado por la
  Asamblea corsa el pasado viernes', which was refused: tr_reduced_agent/3); two
  clauses of `that' joined by a coordinator keep the comma before it (`que "se
  imponen" una serie de reformas, pero que, en todo caso, ...' lost it:
  tr_complements0/4); A VERB OF SAYING, ITS COMMA AND ONE PHRASE SET IN, THEN
  THE CLAUSE OF `que' (`al afirmar, durante la reunión del Consejo de Ministros,
  que no tenía "nada que añadir"' affirmed that he had nothing to add -- read
  left to right, the clause was the council's relative clause, `who did not
  have': tr_saying_that_fix/3), a clause with nobody named (which English
  refuses, on purpose) or with a subject of its own (`que el perro duerme' was
  `which the dog sleeps', tr_saying_that_clause/3), after `al' and its
  infinitive too, and only after a verb of saying -- four arms; an object's
  clause with an infinitive and nobody in it is `to' (`no tenía "nada que
  añadir"' has nothing to add, where English wrote `anything that to add', and
  Tatoeba's `Tom does not have anything that to lose'), and the lesson's
  language begins it with the word it states (`The word "da" begins the
  gerundive.': `niente da aggiungere', `certi lavori da fare'; tr_np_out/5) --
  two arms; a year takes no article in English (`de aquí al 2002', `hasta el
  2019' are until 2002 and until 2019: tr_year_word/1); `included' and
  `excluded' before their phrase are `including' and `excluding' (`a los
  representantes corsos, incluidos los nacionalistas':
  en_participle_preposition/2); `for the past' before a bare plural is `for'
  (`desde hace años' is for years, it_9851_9925's `amico da anni' a friend for
  years; with a count it stays, `for the past three years'); this moment, that
  one or the one takes `at' (`en este momento' is at this moment; `Navarro, en
  un momento de forma excepcional' stays in a moment of it, which the first cut
  wrote `at a moment') -- two arms; and an island takes `on' (`en la isla',
  `nelle isole del sole': en_on_noun/1).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of
  one language and the writer of the other; the dictionary's own word is said
  again first where it must stay the one written): Spanish `gaullista' (a
  Gaullist, a person of either sex), `preconiza' (recommends, with its forms;
  `recomienda' said again first), `córcega' (Corsica, a region) and `elíseo',
  `consejo de ministros' and `consejo constitucional' (names), `corso' and
  `corsa' (Corsican, the adjective and the person), `garante' (a guarantor),
  `restablecimiento' (a re-establishment), `unidad' (unity, before the unit),
  `vuelta' (a return, before the turn; `regreso' said again first), `en
  suspenso' (pending), `a fin de que' (so that, with the subjunctive), `de cara
  a' (with a view to), `de aquí a' (until), `en el transcurso de' (during;
  `durante' said again first), `eventual' (possible; `posible' said again
  first), `elegido' (an elected representative), `hace saber' (announces, with
  its forms), `sujeto' and `sujeta' (subject to), `"adopta" takes the passive.',
  `"se impone" is intransitive.', `"asamblea" is a group.', `duradero' and
  `duradera' (lasting), `señala' (signals, and indicates before a clause),
  `papel' (a role, before the paper), `desempeña' (performs, before exerts), `en
  este sentido' (in this respect) and `en todo caso' (in any case, before if
  anything); Italian `gollista', `corsica' (a region), `eliseo', `consiglio dei
  ministri' and `consiglio costituzionale', `corso' and `corsa' (Corsican; the
  dictionary's `corso', a course, said again first), `garante',
  `ristabilimento', `unità' (unity), `in sospeso' (pending), `in vista di',
  `eletto', the genders of the countries, the regions and the continents the
  lessons name (`corsica', `francia', `germania', `inghilterra', `spagna',
  `grecia', `russia', `cecenia', `catalogna', `sardegna', `sicilia', `europa',
  `asia', `africa' and `america' feminine, `giappone' and `brasile' masculine),
  `"promette" takes "di" before the infinitive.', `in ogni caso', `The word "da"
  begins the gerundive.', `in questo senso', `avvertimento' (a warning, said
  first: the dictionary's first is `ammonizione', a reprimand) and
  `trasferimento' (a transfer, before the house removal `trasloco'); and in
  eng-ita.dix `shake' (`scuotere') and, written only, `deficiency' (`carenza').
  The first meaning moved for 10 Spanish words and 2 Italian ones (Spanish
  `desempeña' performs, `duradero' and `duradera' lasting, `elegido' an elected
  representative, `en todo caso' in any case, `eventual' possible, `papel' a
  role, `sujeta' subject, `unidad' unity, `vuelta' a return; Italian `eletto' an
  elected representative, `unità' unity), the writer's first word for 3 Spanish
  meanings and 4 Italian ones (Spanish pending `en suspenso', role `papel',
  performs `desempeña'; Italian pending `in sospeso', course `corso', transfer
  `trasferimento', warning `avvertimento'), and none was lost.
  THE CONTROLS (cocolog 2.13.0, store KB244, 112 count files, 3 076 sentences:
  the earlier set with the Caetano Veloso interview in, it_9225_9269, both
  directions; this report is not among them): the last version's translator
  against this one, on the one store, 33 sentences in 20 files read differently,
  all better but one that is no worse -- the countries' articles (15: `tra
  l'Inghilterra e la Germania', `L'Inghilterra, il paese che ha prodotto la
  minigonna', `con il fermo sostegno della Germania e della Francia', `che "la
  Spagna vede con simpatia la candidatura"', `Paesi come la Germania', `altri
  luoghi della Spagna', `Anche l'Africa esiste nel calcio', `fino all'Asia',
  `svestirono la Francia', `la crescita dell'Africa', `La Francia era
  affondata', `il calcio è arrivato anche in Africa', `Con la Francia', `che ha
  vinto la Francia', Tatoeba's `La Francia confina con la Spagna'), an object's
  clause with an infinitive (5: `the temptations to resist', Tatoeba's `anything
  to lose', `some works to make', `niente da perdere', `certi lavori da fare'),
  the year with no article (3: `of 2000', `in 2001', `until 2019'), `on the
  islands' (3), `"must read"' and `"hay que leer"' for `"bisogna leggere"',
  `"must not affect"' for `"no debe afectar"', `Mediterranean', `for years' and
  `at this moment' -- and the one no worse, es_19990701-130 6, `di tutto la
  Catalogna': `de toda Catalunya' is read as `of everything' and an object, as
  before, and the object takes its article now. The inferences rise 0.006 % (7
  916 542 512 to 7 917 044 053): 2 919 sentences rise, by 80 to 200 inferences
  each, and +0.037 % of the sentences under one million; the largest rises are
  the Venice report's eighth (+16 093 of 394.5 million in each language) and
  Italian sentences with a country (es_19990601-13 1, +12 502 of 0.41 million;
  Tatoeba's 298, +10 154 of 31 263), whose cost is the articles written: counted
  over the rule's arm, six such sentences come back to within 0.02 % of the old
  counts, and writing any Italian article costs 4 500 inferences (`la') to 12
  500 (`il') -- the walk of the IR costs about 200, the writer's article the
  rest, as it costs `la casa' (a lead: tr_det_out/6 for an article is the price
  of every Italian phrase that has one). The sentences that fall most are
  it_9270_9295 9 and 24 (-25 thousand of 46 million and -17 of 14). Bytes and
  characters read every sentence alike (0 differ, the bytes 0.008 % more). The
  DATA COLUMN (the last version's translator on its own store, KB236, against
  this one on the new): 50 sentences, -0.069 % (7 922 477 800 to 7 917 044 053).
  THE CODE ALONE (this translator on KB236): 16 sentences, all better and all
  among the 33 but `anche in Africa' (the old store states no gender for a
  country, so the articles need the new lines), +0.005 % (to 7 922 890 869). THE
  STORE ALONE (the last version's translator on KB236 and on KB244): 18
  sentences, -0.075 % (to 7 916 542 512), each a word of the report's lines:
  `indicated' and `indicarono' for `señalaron que' (3), `unity' for `unidad'
  (3), `In this respect' for `En este sentido' (2), `In any case' and `En todo
  caso' for `"in ogni caso"' (2), `il suo corso' for `su curso', `le competenze
  in sospeso', `papel' for `ruolo' (2), `señalarle un quiosco' for `indicargli',
  Tatoeba's `of return' (`de vuelta') and `Mi prometteresti di seguire', and one
  worse, es_20010103-139 5, `the figure of sold unities ... 61.9 million
  unities' (a lesson line gives a word one sense in both numbers, and `unidades'
  are units); es_19990901-75 falls 6 % in each language for `en este sentido'
  read at once. THE STORE'S FIRST ROUNDS' REGRESSIONS, found by reading the
  texts of the store alone and mended: the Italian line that makes the noun
  `corso' Corsican came first for the reader, and `in corso', `nel corso della
  conferenza', `il corso di laurea' were `in Corsican' and `en corso' (13
  sentences; the dictionary's `corso' is said again first now); `"desempeña"
  means "plays".' made `desempeñar' the Spanish writer's word for every play
  (`conseguimos desempeñar nuestro fútbol', `está desempeñando con cartas', six
  sentences): the meaning is performs now, which Italian writes `svolgere'
  (`possano svolgere tutto il loro ruolo', where it was `giocare') and English
  `perform'; `en el transcurso de' was the Spanish writer's word for during (`en
  el transcurso del juicio', two sentences), and the writers' first words found
  `preconiza' the word for recommends (`El médico preconiza el descanso') and
  `vuelta' the word for a return: `durante', `recomienda' and `regreso' are said
  again first; and a line that said `pendiente' again first changed no text and
  is gone. THE CODE'S FIRST ROUNDS' REGRESSIONS, found by the one store and by
  probes of the rule, and mended, each with its arm red: the country's article
  stood outside the mark of a quotation that opened on the name (`che la "Spagna
  vede'), took the bracket of a place (`di Cremona (l'Italia)'), a name's own
  phrase (`di Radio Nazionale della Spagna'), a superlative's (`più ricco
  dell'Italia'), names joined after `in' (`nella Francia e nella Germania') and
  a verb of going's `to' (`va alla Francia'); and `at' took an indefinite moment
  (`at a moment of exceptional form', es_20001201-176 6). Two clauses of
  tr_names_only/1 in the first cut repeated an existing definition word for
  word, which the load joins to it: the arm builder found them, the edit it was
  to make occurring twice. THE COST OF THE CODE is +0.006 % on the one store,
  and its largest part is the articles the country rule writes (above); the rest
  is 80 to 200 inferences a sentence, the readers' new clauses asked and
  failing. THE STATED COSTS: a first meaning that serves the news and not every
  text -- `papel' is a role (`El papel es blanco' is `The role is white', and
  `Pedro lleva papel' `Pedro carries role'), `unidad' unity (`unidades vendidas'
  are `sold unities'), `vuelta' a return, `eventual' possible, `elegido' an
  elected representative (the participle is still `chosen') -- and the writers'
  `en suspenso' and `in sospeso' for pending (`Le questioni pendenti' is `Los
  asuntos en suspenso'), `papel' for a role and `desempeña' for performs; the
  eleventh sentence is refused into English, on purpose; and the inferences,
  +0.006 % on the one store and -0.069 % in the data column. The report LEAVES,
  of the 10 into Italian: `non devono questionare l'unità' (2: `mettere in
  discussione'); `si impone una serie di riforme' with the marks of `"se
  imponen"' lost (3, both languages: the subject read after the quoted verb
  takes it out of its marks); `rimarrà entro lei' and `remain within her' (4:
  `dentro di essa', the pronoun of a thing written as a woman's); `venerdì
  passato' (8: `lo scorso venerdì') and English `an only territorial
  collectivity' (a single); `il buon uso che fa l'Assemblea corsa dei
  trasferimenti' is right in Italian, and English writes the transfers inside
  the Assembly's phrase, `the good use that the Corsican Assembly of the
  transfers of competences makes' (9); `ai rappresentanti corsi inclusi i
  nazionalisti ha annunciato' (12: the commas around the absolute clause and the
  relative clause's close are lost -- the apposition took the comma before
  `quien', and the clause was read as a restrictive one). Into both languages 5,
  6 and 7 are refused: 5, a phrase of a preposition clefted with `es al
  Parlamento ... al que deberán ser sometidas' and `a emprender'; 6, `para ser
  deseables y necesarias' inside the quoted subject; and 7, `Poder
  legislativo.', a bare noun and an adjective, which the pinned `Big house.'
  guard refuses on purpose. English refuses 11 (`que no tenía "nada que
  añadir"') and 12 (`ha hecho saber que no defenderá') for the third person
  nobody names, on purpose. The next sample's controls take this report in.
  The child-cost report (VIT-10011..10058, 48 sentences, Panorama's report on what a child costs, Italian into Spanish
  and English: 38 of 48 and 39 of 48 on a fresh store, 33 and 32 with the new store alone, 24 and 24 with the new code
  on the old store, 20 and 20 before; reasoning 1.0.21). The sample was taken on the cocolog 2.13.0 binary, built with
  Cicili 9b825b7 from a copy (master's b208233, and the owner's merge of the Corsica report, dd8b35f, the same tree),
  and cocolog stays 2.13.0. The article's sentences fall from 312.6 million inferences into Spanish and 312.5 into
  English to 238.4 and 238.1, of which the forty-third, refused, is 66.5 million in each. It needed these SHAPES, each
  with its arm red (test/translate.pl's `newspaper_figli': 41 checks, 45 arms, 40 of them red and five guards of cost
  that stay green, below; an arm is a library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_figli, checks_done"', two seconds a
  run, and every arm is run in twenty seconds, four at a time): a word that says how plain the sentence is stays in
  front (`Naturalmente il conto sale con l'aumentare del reddito' is naturally the bill rises, and put after the verb it
  came out `The account rises ... naturally': en_head_maybe/1, `obviously' with it); a word the lesson says does not
  follow an article takes its place (`su un altro campione' is `en otro campeón', and the Spanish writer wrote `un
  otro': `"otro" does not follow "un".', tr_contract/3), and English's `an other' is `another' (en_another/2) -- two
  arms; a unit of time after `to' and its article is how often (`una famiglia che guadagna 3.500 euro netti al mese'
  earns them A MONTH, where English wrote `to the month': tr_comp_out/7), with a bracket after the unit too, and a bare
  noun and its participle alone in a bracket are said noun first (`circa 580 euro al mese (baby sitter esclusa)' is a
  month (babysitter excluded), where it was `to the month (excluded babysitter)': tr_aside_out/6) -- three arms; `takes
  into account' takes its phrase bare (`Non tengono conto per esempio della mancanza cronica di posti' does not take
  into account the lack, and the governed `of' came out `take into account of': en_bare_object/1), and so does Spanish's
  `tener en cuenta', which the lesson states with no preposition, and so is a second phrase joined to the first on the
  same preposition (`del pane o del vino' takes into account the bread or the wine, and the second kept its `of':
  tr_gov_second/4) -- two arms; `MAKES' AND AN INFINITIVE BEFORE ITS OBJECT ARE THE OBJECT AND THE BARE INFINITIVE
  (`tutti fattori che fanno impennare la bolletta figlio' make the bill soar, where English wrote `make to soar the son
  bill': tr_comps_out/7, binf/1), where the phrase is the one that does it -- the infinitive's verb, or one with its
  meaning, is one the lesson calls intransitive or whose perfect takes the copula (`fanno scattare la positività', `ha
  fatto passare la protezione'; `Le ho fatto recapitare il disco a casa da un amico' had the disc delivered, and the
  controls' first round wrote `made her the disc deliver': en_causee_infinitive/1, `The intransitive verb "impenna"
  means "soars".') -- and the phrases of `of' after the phrase go with it (`made the protection of this disease happen',
  where it was `the protection happen of this disease': tr_en_of_run/3) -- three arms; the participle of a verb English
  says with `is' is its second word, after a noun (`Cifre nate da un'indagine' are figures born of a survey, and it was
  `been born from': en_reduced_participle/2) and alone after a comma (`Cifre impressionanti, nate da un'indagine lunga e
  affidabile'), and the phrase its verb governs is marked after a participle whose perfect takes the copula, as after
  any other (Spanish's `nacidas de', where the lesson's `from' wrote `desde': tr_ptc_complements/4), and after the
  participle alone (tr_pred_governed/3) -- four arms; `it becomes' an adjective to do something (`in questo progetto
  diventa fondamentale stabilire quanto costa' -- it becomes essential to establish it, and with nobody named English
  refused it: en_null_it/2); a verb whose subject is an infinitive has none after it (`Quanto costa mantenere un
  figlio?' is how much does it cost to keep a son, and the phrase after the infinitive was the verb's subject, `How much
  does a son cost to keep?': fo_inf_subject_verb/1, en_null_it/2), where Spanish says it as Italian does -- three arms;
  the one who is fed is the object of `feeds' (`per dare da mangiare al bambino' is to feed the child, and the lesson's
  `to' came out `to feed to the boy': tr_comp_out/7), after a purpose that is the verb as well (tr_comps_out/7) -- two
  arms; THE INFINITIVE OF A VERB THAT TAKES NO OBJECT, WITH ITS PHRASE OF `OF', IS A CLAUSE OF `AS' (`con l'aumentare
  del reddito familiare cresce la spesa' as the family income increases, and read as a phrase it was `with increasing of
  the income'; `al crescere del reddito' as the income grows, where it was `to the growing of the income':
  tr_as_inf_fix/3, asked of the sentence's own clauses as the polite wish is, tr_into_ir/4), a verb the lesson calls
  intransitive or whose auxiliary is the copula, which every writer puts after the main clause with its word for `as'
  (`a medida que', `man mano che') -- two arms; an adverb at the head before a clause of `if' (`Poi se c'è bisogno della
  baby sitter, il conto sale' -- then, if there is need of one, the bill rises; the condition's reader wants its word
  first, and the sentence was refused: tr_read0/4); an adverb before a line of adjuncts (`In particolare al Nord.' -- in
  particular in the North, after the sentence that said what; an adverb and a phrase of a preposition were refused:
  tr_verbless0/3), or before a phrase that says something (`in media 230 mila euro per mantenerlo fino a 24 anni', the
  headline: tr_predicated/2), and an adverb and a phrase alone stay refused (`In media 230 euro.') -- two arms; what a
  man is and how many children he has, after the age (`il lavoro di Marino Maglietta, 64 anni, docente di fisica
  all'università di Firenze, due figli' -- his age, his post and his two children, and read as the clause's own the post
  was refused: tr_asides/3, tr_count_tail/2) -- two arms; two things a person is, joined, after the name (`Secondo
  Enrico Finzi, sociologo e presidente della società Astra, è così' -- according to him, a sociologist and president, it
  is so; read as the clause's own the two were its subject and the copula plural: tr_roles_apposition/1), the
  preposition before a name and its comma is not lifted as the adverb `second' (tr_governs_adverb/3), and the copula
  with nobody named before `thus' is `it is thus' (en_null_it/2) -- three arms; a word after a noun that is its
  adjective as well as a verb, with nothing after it but a comma, is the adjective (`Una spesa media, per una famiglia
  dell'Italia centrale ...' is an average expense, and read as the verb `media', mediates, the expense mediated:
  tr_adjective_not_verb/3, which asks the piece with its commas, '$tr_piece'), and a last word that is a noun as well as
  a verb, after an adjective it agrees with, is the noun (`E per almeno cinque buone ragioni:' is five good reasons, and
  read as `ragioni', you reason, the five were goods), where that word is the reading's own verb (a guard: `ma cambia la
  sua composizione' and `ma mangia cinque buone ragioni' end on their objects) -- three arms; the others do what a
  relative clause says (`comprare "quello che hanno anche gli altri"' is to buy what the others have too, and read with
  the relative word for the subject it was `what also have the other ones': tr_doer_np/1); the first coordinator after
  the word for `among' joins the two it takes (`Le differenze tra Nord e Sud sono tutto sommato limitate' are between
  the two, and split at `e' the South was a second subject beside the differences, whose participle took the masculine,
  `limitados': tr_conjunction_split/5), after a word of the phrase's own and in a sentence with such a word (two guards
  of cost, below); an amount after a verb of rising or falling is what it changes by (`il conto sale di circa 130 euro
  al mese' rises BY about 130 euros, and it was `rises of': tr_comp_out/7, tr_amount_np/1); a count of years after `to'
  is an age (`a 16 anni il conto mensile è di 200 euro in più' -- at 16, where English wrote `to 16 years':
  tr_comp_out/7), never in a range (`100 jóvenes de 18 a 25 años' are of 18 to 25 years, and the controls' first round
  wrote `of 18 at 25': tr_comps_out/7, rng/1) -- two arms; a phrase with one relative clause after its comma (`il
  crescente conformismo sociale, che obbliga i figli e i genitori a comprare ...' is the conformism, which obliges them,
  and divided at the comma the clause was one of `that' with nobody named, which English refused: tr_verbless0/3); and
  `spends' governs `on' (`spende in svaghi e vacanze per il figlio', where English wrote `spends in': `"spende" takes
  "in" before the phrase.', en_governs/2). The five guards of cost, their arms green: the `among' guard asked in a
  sentence with a word for `among' only ('$tr_among', tr_among_note/1) and never where the word opens the words before
  the coordinator, and the heading rule's phrase that opens on a determiner, holds no comma and has a verb in its clause
  (the cost, below). A guard that the adjective before the last word is no determiner had a green arm (`cambia la sua
  composizione' is kept by the verb's own word alone) and is gone. It needed these WORDS in `extra/' (the two readers: a
  line moves the reader of one language and the writer of the other; the dictionary's own word is said again first where
  it must stay the one written): Italian `in media' and `mediamente' (on average), the full infinitives `crescere' and
  `provenire' (the dictionary marks them read only and gives the cut forms for writing), `crescente' (increasing: the
  builder wrote it `crescee'), `mal' (badly, `male' said again first), `tutto sommato' (all in all), `fin qui' (so far),
  `di parecchio' (considerably, `considerevolmente' said again first), `aumenta' (rises, said again as a line of its
  meaning alone: the entry for `salire' in eng-ita.dix drops the dictionary's own), `retta' (a fee, with `costo' said
  again first, its own first meaning and then the fee), `porta a casa' (takes home), `riparatorio' (reparative),
  `videogioco' and `telefonino' (a form of `telefona' alone before), `metter' (the cut infinitive, the full one said
  first), `studioso' and `studiosa' (scholars, persons: the dictionary has the adjective alone), `affidamento' (custody,
  where the dictionary's first is trust; `custodia' said again first), `mancanza' (a lack, where its first is a fault;
  `carenza' said again first), `trasporto' (transport, before the carriage), `risorsa' (a resource, before the resort),
  `statistica' (statistics, the noun), `tabella' (a chart, where its first is a picture and a table is a piece of
  furniture to the Spanish writer, `mesas'; `grafico' said again first), `punto di riferimento', `fuori sede' (away from
  home), `asilo nido' (a nursery: the writer's nursery was `vivaio', a nursery of plants), `tiene conto' (takes into
  account, with `di' before the phrase), `tira su' (raises, `alza' said again first), `dà da mangiare' (feeds,
  `alimenta' said again first), `al primo posto' (in first place, `in primo luogo' said first), `sempre meno' (less and
  less), `"nasce" takes "da" before the phrase.', `svizzera' and `danimarca' (countries), `eventuale' (possible, where
  its first is eventual, a line of its meaning alone: the writer, which takes an adjective's word from a line of its
  class, wrote `sólo será posible' as `sarà soltanto eventuale' with one, passing over `possibile' for a feminine noun
  as the dictionary states it a masculine noun too), `sul campo' (in the field), `cresce' (grows with no object, and
  brings up), `uniforme' (the adjective: the dictionary has the noun alone), the association's name `crescere insieme',
  `nord' and `sud' (names that cross by their meanings), `cambia' (intransitive, and the transitive verb as well:
  below), `sale' and `impenna' (intransitive), `familiare' (family, where its first is familiar, and the noun, a
  relative, with `parente' said again first), `"spende" takes "in" before the phrase.', `nel tempo' (over time), `mette
  al lavoro' (puts to work, and sets to work with its pronoun), `tiene duro' (holds out) and `in meno' (less); Spanish
  `se dispara' (soars), `videojuego', `teléfono móvil', `en definitiva', `en promedio', `hasta aquí', `reparador',
  `lleva a casa', `tiene en cuenta', `sobre el terreno', `correctivo', `suiza' and `dinamarca', `cada vez menos', `en
  primer lugar', `punto de referencia', `fuera de casa', `"nace" takes "de" before the phrase.', `"otro" does not follow
  "un".' and `"otra" does not follow "una".', `cría' (brings up, where its first is a pup), `norte' and `sur', `con el
  tiempo', `pone a trabajar' (puts to work, and sets to work with its pronoun) and `aguanta' (holds out, its own `holds'
  said again first); and in eng-ita.dix `rise' (`salire'), `digest' (`digerire'), `mediator' (`mediatore'), `compile'
  (`compilare'), `soar' (`impennare') and `kid' (`ragazzino': `capretto', a young goat, was the Italian written for
  one), and, read only, `minor' (`minorenne'), `objective' (`oggettivo'), `suppose' (`presumere'), `house' (`ospitare')
  and `prove' (`provare'). The first meaning moved for 16 Italian words and 4 Spanish ones (Italian `affidamento'
  custody, `alza' raises, `eventuale' possible, `familiare' family, `male' badly, `mancanza' a lack, `nord' and `sud'
  North and South, `risorsa' a resource, `statistica' statistics, `studioso' and `studiosa' a scholar, `svizzera'
  Switzerland, `tabella' a chart, `trasporto' transport, and the verb `cresce' brings up beside its intransitive grows;
  Spanish `cría' brings up, `norte' and `sur', `suiza' Switzerland), the writer's first word for 4 Italian meanings and
  no Spanish one (Italian increasing `crescente', kid `ragazzino', nursery `asilo nido', scholar `studioso', where it
  was `dotto'), and none was lost (the Italian vocabulary lost `The verb "aumenta" means "rises".', which `extra/' says
  as a line of its meaning alone). THE CONTROLS (cocolog 2.13.0, store KB254, 114 count files, 3 102 sentences: the
  earlier set with the Corsica report in, es_20000802-26, both directions; this report is not among them): the last
  version's translator against this one, on the one store, 18 sentences in 16 files read differently, all better -- `a
  month', `a week' and `a year' (4: `an article a week', `500 thousand lire a month', `the twenty million a year',
  `6,000 traditional shops a year'), `another' and `otro' (6: `another million of poor', `otro millón', `otro
  continente', `otro holocausto', `one finds it another one', `se lo encuentra a otra'), `at 15' for `to 15 years',
  `obviously' and `naturally' in front (5, both languages: `Obviously one will have to read the motivations',
  `Evidentemente habrá que leer', `and naturally Vittori will be one of the lecturers', `Naturalmente ni Colombo ni sus
  enemigos'), `spends on consumptions', the causative (`which make the positivity start', `which has made the protection
  of this disease happen'), and es_20020601-51 18, refused by the last version and read now (`They thought that there is
  life without Zidane, but Senegal took charge of showing him that it is not thus') -- and the inferences rise 0.041 %
  (7 937 885 155 to 7 941 149 072). Bytes and characters read every sentence alike (0 differ, the bytes 0.009 % more).
  The DATA COLUMN (the last version's translator on its own store, KB244, against this one on the new): 34 sentences in
  24 files, -0.641 % (7 992 419 484 to 7 941 149 072). THE CODE ALONE (this translator on KB244): 15 sentences in 14
  files, every one among the 18, +0.041 % (to 7 995 685 260); the three left need the new lines (`"otro" does not follow
  "un".'). THE STORE ALONE (the last version's translator on KB244 and on KB254): 16 sentences in 14 files, all better,
  -0.682 % (to 7 937 885 155), each a word of the report's lines: `telefonino' for a mobile phone, where it was
  `telefono mobile', `over time' and `nel tempo' for `con el tiempo', `tenendo conto' for `teniendo en cuenta', where it
  was `avendo in conto', `to raise a person' and `levantar' for `tirar su', where they were `pull on' and `estirar en',
  `his relatives' and `sus parientes' for `dei suoi familiari', `the family cheques', `on average', `between North and
  South' and `entre Norte y Sur', `in the field' and `sobre el terreno' for `sul campo', where it was `on the
  countryside', and `nace del hecho'; the Rognoni interview's nineteenth sentence, refused both ways, falls 26.5 million
  inferences in each language (`tenendo conto' is a verb of the lesson now), `En primer lugar, todavía no sé si ...' 3.7
  million (one adverb now), and `con el tiempo' costs `Como prueba de que los violines ...' 1.4 million more in each,
  read as the adverb it is. THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column and mended. Of the
  code (the one store, the first round, 20 sentences, +0.164 %): the age in a range (`100 jóvenes de 18 a 25 años' was
  `of 18 at 25'), the causative with a verb that takes an object (`Le ho fatto recapitare il disco a casa da un amico'
  was `I have made her the disc deliver') and its phrases of `of' (`made the protection happen of this disease'), each
  now with its arm red. Of the store (the store alone of the second round, 22 sentences): `cambiare' was `capsize' in
  four sentences (`must have made him capsiz idea', `The football capsized its rules', `the values are not capsized') --
  the intransitive line made `changes' the intransitive meaning, and a use with an object took the next one, so `The
  transitive verb "cambia" means "changes".' says it, as `firma''s line does for `signs'; `En primer lugar, todavía no
  sé si ...' was `Al primo posto' (`in primo luogo' said first); `dei suoi familiari' was `his families' and `sus
  familias' (the noun, a relative); and `sólo será posible' was `sarà soltanto eventuale' (the line of its meaning
  alone, above). A name line, `"mezzogiorno" is a name.', changed nothing (`rispetto al Mezzogiorno' stays the noun
  after its article, and is `frente al Mediodía' and `compared with the Midday') and is gone. THE COST OF THE CODE,
  FOUND BY TAKING EACH RULE OUT (the heaviest risers of the first round and a dozen sentences picked at random, into
  English, over a copy of the library per rule): the first cut was +0.164 % of the controls, and two rules were most of
  it -- the `among' guard, whose split blocked at `Entre la Meridiana y la calle del Coronel Sanfeliu habrá dos carriles
  ...' had failed at once, and blocked, the split at the next coordinator read left words that held the verb (2.6
  million inferences more in each language, to the same refusal in English and the same text in Italian), and whose walk
  of every preposition at every split cost long sentences 0.1 to 0.2 million; and the heading with one relative clause,
  which read every piece with a comma and a relative word after it as one phrase (0.6 million in `Ma come è accaduto, si
  dirà, che tutte le rappresentazioni ...', 0.19 in `Casotto, che ora giura ...', and `Mio dio, che tristezza!' at 1.6
  times its cost). What paid was the note made once a sentence, no guard where the word for `among' opens the left
  words, and the heading's three cheap questions first. The final cut is +0.041 %: the adverb before `if' 0.28 and 0.09
  million in two sentences (`Comunque se mai ci sarà una causa ...', a failed search before the old reading, the text
  the same), the `among' guard's changed search 0.11 and 0.05 million (`crea "delle asimmetrie tra accusa e difesa"',
  `Melina tra Polo e Olivo e il voto è più vicino'), the heading rule 0.1 million in `Lo stesso per Zdenek Zeman, che si
  dice soddisfatto ...', the adjective rule 40 thousand in a sentence of 39 million, the two roles after a name 43
  thousand, and 100 to 800 inferences a sentence elsewhere (twelve sentences picked at random). THE STATED COSTS: a
  first meaning that serves the news and not every text -- `affidamento' is custody (trust second), `mancanza' a lack (a
  fault second), `tabella' a chart (a picture second), `risorsa' a resource, `trasporto' transport, `familiare' family
  and a relative, `eventuale' possible, `studioso' a scholar, `cría' brings up (a pup second) -- and the writer's
  `ragazzino' for a kid and `studioso' for a scholar; the inferences, +0.041 % on the one store; and `tenendo conto la
  sua scarsa altezza', which Italian says `tenendo conto della' (the writer puts no `di' before the object of a verb the
  lesson says takes it, a lead). The report LEAVES, of the 38 into Spanish (English alike unless it says): `Lo pone en
  evidencia' (3: `lo revela'); `Caros niños' and `Expensive boys' (5: dear children, the pun lost); `¿Se hace pronto a
  decirlo, pero son "caros" los niños cuanto exactamente?' and `Does one make to say him soon' (6: the idiom `si fa
  presto a dirlo', it is easy to say, crosses word by word, and `quanto' is `as much'); `de la Italia central' and `of
  the central Italy' (9); `entradas netas para 5.200 euros' and `net entrances for' (11: income of); `son la fruta del
  trabajo' (15: `el fruto') and `docente de física a la universidad' and `to the university'; `who involves 40 thousand
  families' (21: the survey's clause hung on the Italians); `They add a proof on another champion of 3 thousand families
  in the field' (22: a test on another sample) and `Compare the own ones' and `Apply several statistical correctives'
  (23, 24: read as commands, and Spanish `Compara a las propias'); `the heaviest voice ... is the feeding, while there
  is the house among the indirect costs in first place, that one supposes it must be bigger' (27: the item, and `which
  is supposed to'); `asciende de aproximadamente 130 euros' (28: `en'); `the monthly account is of 200 euros compared
  with a child of 3 years at 16 extra' (29: the order of `a 16 anni' and `in più'); `brought up to the North ...
  compared with the Midday on average extra' and `criado al Norte' (31: in the North, the Mezzogiorno); `or of the
  distance of the grandfathers' (33: the second phrase after phrases of the first's own keeps its `of'), and Spanish
  `hacen dispararse el proyecto de ley hijo' (a parliamentary bill: `la factura'); `To the North in particular' (34);
  `his composition' (35: its); `while the costs of the transports rise, of the vacations, of the instruction quickly'
  (36: the phrases of `of' parted by the verb); `the parents invest you being a scarce resource more' and `os invierten'
  (42: `vi', there, read as you); and `in favour of giving to the sons too' (45: too much) and `"what the other" ones
  also have'. Into both languages 8, 17, 38, 43, 44, 46, 47 and 48 are refused: 8, the second person plural's commands
  and conditions (`Beh, se state programmando ... preparatevi a investire ... se dovrete affidarvi'); 17, a heading and
  its infinitives (`Obiettivo: modificare la normativa e introdurre in Italia ...'); 38, two sentences the source runs
  together with no full stop (`ne spende oltre 150 fin qui la fotografia, anzi il conto'); 43, the idiom `non ce la si
  fa' (refused at `ce'); 44, `Ancora e: siamo in una cultura del nuovo' (the source's `e'); 46 and 47, a colon's long
  right side (`non solo godono di ... ma hanno anche ...', `Quindi tenete duro, non spaventatevi, possibilmente non
  fermatevi a un figlio:'); and 48, Churchill's quotation (`"non c'è per nessuna comunità investimento migliore del
  metter latte dentro ai bambini"'), after `Y recordados de eso que decía Winston Churchill:' for the source's
  `ricordatevi vi'. Spanish refuses 18 and 19 as well (`diventa fondamentale stabilire quanto costa davvero crescere un
  bambino: una richiesta avanzata ...', `E un'esigenza sentita da tutti quelli che lavorano ...', which English reads),
  and English refuses 25 for the third person nobody names, on purpose (`E alla fine mette a punto un sistema ...'). The
  next sample's controls take this report in.
  The New Year's Eve report (AnCora CESS-CAST-P-20010103-85, 20 sentences, the paper's report on the night in the
  Plaza de Catalunya, Spanish into Italian and English: 19 of 20 and 19 of 20 on a fresh store, 16 and 16 with the new
  store alone, 5 and 7 with the new code on the old store, 5 and 6 before; reasoning 1.0.22). The sample was taken on
  the cocolog 2.13.0 binary, built with Cicili 9b825b7 from a copy (the branch's 292cd02, the child-cost report's
  binary), and cocolog stays 2.13.0. The article's sentences fall from 50.6 million inferences into Italian and 50.4
  into English to 20.9 and 20.3, of which the fifth (`A través de emisoras de radio, destacó que la Guardia Urbana - -
  desbordada - - solicitó en vano ...') is 6.5 million in each.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_noche': 37 checks, 38 arms, 37 of
  them red in the section and one red on the store alone, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_noche, checks_done"', two seconds a run, and every arm is run in thirty seconds, four at a time): AN HOUR
  AFTER `to' IS `at', WITH NO ARTICLE (`que seguían en la plaza a las dos' were there at two, and English wrote `to
  the two': en_clock/2), two hours after `among' are `between' them (`entre las 4.30 y las cinco', where it was `between the 4.30
  and the five'), and the part of the day after an hour is said with its own preposition (`de la mañana' is in the
  morning, `de la madrugada' too, where it was `of the morning': en_day_part/2) -- three arms; `LA UNA' IS ONE
  O'CLOCK (`entre la una y la 1.30 de la madrugada' -- the indefinite article after the definite one had no reading as
  a count, and the sentence was refused: one/1, tr_cross_num/2, asked only of a word in a list made once a sentence of
  the words that mean the article `a', '$tr_a_lexemes'), the lesson's feminine article for `a' writes it (Spanish's
  `un' is the number one, and the count was `la un'; Italian's generic number writer took the pronoun `si' for one,
  `alla si'), elided as before a noun (`all'una', which came out `alla una': tr_the_before_one/2 in tr_opens_next/2),
  and a time in digits beside it keeps the hour's gender (`tra l'una e l'1.30', where the noun of `la 1.30' gave the
  pair no gender and Italian wrote `tra il si e l'1.30': red on the store alone, no hand lesson has the digits' noun)
  -- four arms; `TAMPOCO' IS `NOT ... EITHER' (`Tampoco ayudó el dispositivo', `pero tampoco insistimos en ella' --
  English wrote `but neither we insist on her', and Tatoeba's `Neither I know what to do': tr_write/4 writes the
  denial and `either' last); `DE FORMA' AND AN ADJECTIVE SAY HOW (`el sarao transcurrió de forma "intensa y alegre"'
  went off in an intense and cheerful manner, and English wrote `of "intense and cheerful" form': tr_comp_out/7), and
  Italian writes `in modo' (where it wrote `di forma') -- two arms -- and after a phrase of a preposition, in the
  clause or in an insertion, they are that phrase's (`Navarro, en un momento de forma excepcional, se encargó' is in a
  moment of exceptional form, and the controls' first round wrote `in a moment in an exceptional manner':
  tr_form_of_phrase/2, nform/1) -- two arms; after the verb, its adverbs or its object they still say how (`asomándose
  de forma definitiva', `come el pan de forma alegre'); A PARTICIPLE ALONE BETWEEN TWO DASHES (`la Guardia Urbana - -
  desbordada - - solicitó en vano la presencia de la policía' -- overwhelmed, it asked in vain; the one word between the
  dashes had no reading: tr_asides/3, tr_dash_phrase_end/1), after a noun and after an adjective, the last word of its
  phrase, and never a verb form, which reports the sentence (`Gallo - continua - mi ha lasciato', which the controls'
  first round read as the adjective `continuous' and lost its comment) -- three arms; A PHRASE OF `of' AFTER A PASSIVE,
  A PREDICATE OR A PARTICIPLE ENGLISH WRITES WITH `with' IS THE VERB'S (`la plaza, cubierta de botellas rotas' is
  covered WITH them, and English wrote `covered of': tr_of_passive/4, tr_of_pred/2, tr_ptc_governed/4 for a participle
  between commas, en_of_participle/1, `plants' among them) -- four arms; a phrase of `like' with no determiner right
  after a participle is the participle's (`botellas rotas utilizadas como arma' are bottles used as a weapon, where the
  phrase stood after the noun, `used bottles like weapon': tr_like_participle/2), and English writes `como' and a
  phrase with no determiner as `as', the article `a' before a thing (`as a weapon', `as an alternative', `as a
  consequence') and none before a person (`as teacher', `as barça player') -- three arms; A PARTICIPLE AFTER A COMMA
  AGREES WITH WHAT THE SOURCE SAYS IT AGREES WITH: with the phrase of a preposition, and not with the subject (`Los
  perros comen el pan de la plaza, cubierta de botellas' is the square covered, and agreeing with the subject Italian
  wrote `coperti': tr_pred_after_phrase/4, phagr/0), and an adjective with the subject, and not with the phrase
  (`Otros 20 operarios ... debían llegar entre las 4.30 y las cinco de la mañana, provistos de dos camiones' -- the
  workers are equipped, and agreeing with the morning Italian wrote `attrezzata': tr_adj_subject_comma/3, suagr/0) --
  two arms; an adjective English says with `with' takes its phrase of `of' so (`equipped with', where it was `equipped
  of': en_with_adjective/1); `AL' AND AN INFINITIVE WITH ITS REFLEXIVE PRONOUN JOINED AND A PHRASE AFTER IT (`La
  situación se complicó al generarse un círculo vicioso' -- on a vicious circle being generated; the words had no
  reading: uponse/3, read by tr_complements0/4, crossed by tr_cross_comp/2), which English writes `on', the phrase,
  `being' and the participle, and a lesson with no word for the moment writes with its gerund, the pronoun joined
  (`generandosi un circolo'); THE REFLEXIVE BEFORE A MODAL WITH A THING FOR ITS SUBJECT IS THE MODAL'S PASSIVE (`el
  tráfico no se pudo normalizar' could not be normalised, and English wrote `could not normalise'; the controls'
  `Los violines no se pueden copiar' cannot be copied: tr_modal_se_fix/3), and a person's stays his own (`Pedro no se
  pudo lavar', tr_doer_np/1) -- two arms; THE WORD FOR `everything' RIGHT AFTER THE COPULA IS ITS SUBJECT (`porque
  estaba todo sembrado de desperdicios rotos' -- because everything was strewn with them; read with nobody named, the
  copula had `todo' for its object and English refused it: tr_all_copula_fix/3, every/1), which Italian writes in front
  (`tutto era') -- two arms; THE REFLEXIVE OF THE VERB OF SEEING AND A PARTICIPLE IS A PASSIVE (`la recogida también se
  vio afectada por el accidente' was affected by it, and read as it stood the sentence had no reading or saw itself:
  tr_see_passive/2), with the adverbs before the participle the clause's and the phrase of `by' its agent -- three
  arms; `asks' for something of somebody is `asks somebody for it' (`El Ayuntamiento ha pedido un informe a la
  concesionaria FCC' asked the contractor for a report, where English wrote `asked for a report to the contractor':
  tr_comps_out/7); `other' before a count is `another' (`Otros 20 operarios' are another 20 workers: tr_det_out/6); the
  word for `even' that ends the front, right before a subject with no determiner, is said of the subject (`Ante el
  pobre despliegue, incluso representantes municipales ... mostraron su desaprobación' -- even municipal
  representatives, where English wrote `even,' between commas of its own), and the subject inside it still owns what
  its possessive names (`their': tr_focus_subject/3, tr_plural_possessor/1) -- two arms; and a noun that can say a lack
  says it before a phrase of `of' with no determiner (`La falta de agentes hasta última hora' is the lack of agents,
  where `falta' is a fault first: tr_relational_np/3).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `fiesta' and
  `sarao' (a celebration: the dictionary's party is the political one to the Italian writer, and `Después de la
  fiesta' was `Dopo il partito'), `concesionaria' (a contractor), `barredora' (a sweeper, the machine), `a la vista de'
  (in view of), `al margen de' (apart from, with `aparte de' said again first), `operativo' (an operation, the noun,
  with `operación' said again first), `revela' (reveals, and turns out as a reflexive: as `results' it was the word
  written for every Italian `risulta'), `grueso' (the bulk, where it was the thickness), `hasta última hora' (until the
  last moment), `según lo previsto' (as planned), `en la práctica' (in practice), `accidentado' and `accidentada'
  (eventful, where it was rugged, with `movido' and `movida' said again first), `roto' and `rota' (broken, the
  adjectives), `concejala' (a councilwoman, a person, where it was an alderwoman), `agrava' (worsens, as a reflexive),
  `activa' (activates, where it was actuates), `desalojase' (the past subjunctive in `-se', which the dictionary gives
  for reading only and the builder leaves out), the name `Cuerpo Nacional de Policía', `emisora de radio' (a radio
  station), `recogida' (a collection, the noun: the dictionary has the participle alone, and `la recogida' had no
  reading), `"desaloja" takes the passive.', `falta' (a fault, said again first, and a lack; `culpa' said again first,
  so that it stays the word written for a fault: `e che colpa abbiamo' was `qué falta tenemos'), `en vano' (in vain)
  and `trabajador' (a worker, said again first: `i lavoratori autonomi' were `operarios autónomos'); Italian `festa'
  (a celebration), `spazzatrice' (a sweeper, the noun and the adjective), `alla luce di', `fino all'ultimo momento',
  `come previsto', `in pratica', `grosso' (the bulk), `invano' (in vain: the dictionary gives it for reading only and
  wrote `in inutile'), `agente' (an officer, said again first, and an agent, where the writer's agent was
  `concessionario', a dealer), `aggrava' (worsens, as a reflexive, with `peggiora' said again first), `passa' (passes,
  its `happens' said again first: the dictionary's only verb for passes was `transita', `la festa transitò'), `stazione
  radio', `attiva' (activates), `rotto' and `rotta' (broken), `allegro' and `allegra' (cheerful: the dictionary's first
  is `allegre' of no gender, which wrote `in modo allegre'), `raccolta' (a collection, where the writer's was
  `collezione', an art collection), `incidente' (an accident, where the writer's was `accidente', bad luck) and
  `rivela' (reveals, and turns out as a reflexive); and in the dictionaries' extras, for Spanish `overwhelm'
  (`desbordar'), `sweeping' (`barredor'), `equipped' (`provisto'), `cistern' (`cisterna') and `harshly' (`duramente'),
  and, read only, `favour' (`propiciar'), `unbalance' (`descompensar'), `worker' (`operario'), `evacuate'
  (`desalojar'), `gradually' (`escalonadamente') and `slow' (`ralentizar'); for Italian `equipped' (`attrezzato'),
  `vicious' (`vizioso') and `unbalance' (`squilibrare'). The first meaning moved for 7 Spanish words and 6 Italian
  ones (Spanish `accidentada' eventful, `activa' activates, `concejala' a councilwoman, `fiesta' a celebration,
  `grueso' the bulk, `operativo' an operation, `propicia' favours; Italian `allegro' and `allegra' cheerful, `attiva'
  activates, `festa' a celebration, `grosso' the bulk, `rotta' broken), the writer's first word for 7 Spanish meanings
  and 7 Italian ones (Spanish harshly `duramente', celebration `fiesta', collection `recogida', contractor
  `concesionaria', lack `falta', overwhelms `desborda', slows `ralentiza'; Italian cheerful `allegro', accident
  `incidente', agent `agente', celebration `festa', collection `raccolta', sweeper `spazzatrice', passes `passa'), and
  none was lost.
  THE CONTROLS (cocolog 2.13.0, store KB260, 116 count files, 3 198 sentences: the earlier set with the child-cost
  report in, it_10011_10058, both directions; this report is not among them): the last version's translator against
  this one, on the one store, 29 sentences in 23 count files read differently, all better but one that is no worse --
  `as' for `como' and a phrase with no determiner (12: `as an easy explanation', `as an alternative to close on
  Saturdays', `as a signal of opening', `as a consequence of the changes', `as leader in sales', `as fatuous fires',
  `as barça player', `as a reprisal', `as a "nostalgic of the francoist regime"', `as a background', `as a maximum
  amount', `as a place of work'; and the one no worse, it_9673_9712 35, `lose an ally as signs', where both texts read
  the name Segni as a noun), `either' (5: `but we do not insist on her either', `Rivaldo and Overmars were not in
  Gandía curiously either', `but we do not go to remain like silly either', Tatoeba's `I do not know what to do
  either' and `They do not remain us eggs to us either', where it was `Neither I know what to do'), the hours (3:
  `between three and five in the afternoon', `at eight', `at six in the morning', where they were `between the three
  and the five of the afternoon', `to the eight', `to the six of the morning'), the manner (4: `in a definite manner'
  and `in modo definitivo' for `de forma definitiva', `in modo straordinario', `in modo semplice', where they were `of
  definite form' and `di forma'), `The violins cannot be copied', `is also asking the associates for the vote', and
  `everything has been clearer' and `todo ha sido más claro' for `è stato tutto più chiaro' -- and the inferences rise
  0.016 % (8 420 036 704 to 8 421 382 441). Bytes and characters read every sentence alike (0 differ, the bytes
  0.008 % more). The DATA COLUMN (the last version's translator on its own store, KB254, against this one on the
  new): 35 sentences in 28 count files, +0.046 % (8 417 506 712 to 8 421 382 441). THE CODE ALONE (this translator on
  KB254): the same 29 sentences with the same texts, +0.016 % (to 8 418 852 457). THE STORE ALONE (the last
  version's translator on KB254 and on KB260): 6 sentences in 5 count files, +0.030 % (to 8 420 036 704), each a word
  of the report's lines, all better but two that are no worse: `di raccolta di fondi elettorali' for `de recaudación
  de fondos', where it was a `collezione', and `nella raccolta' and `una raccolta d'archi' for `colección' (the two no
  worse), `la falta crónica' for `la mancanza cronica', where it was `carencia', `must be activated' for `vanno
  attivate', where it was `actuated', and Tatoeba's `un lieve incidente', where it was `accidente'. THE FIRST ROUNDS'
  REGRESSIONS, found by reading the texts of every column and mended. Of the store (round a's store alone, KB258, 25
  sentences, and round b's, KB259, 23): a line said first is the reader's word and the other language's writer's, so
  `revela' as `results' was the Spanish written for every Italian `risulta' (the plain `reveals' is said first now,
  and the reflexive `turns out' after it), and `aggrava' was written for `peggiora' (`potrebbe aggravare le cose'),
  `falta' for a fault (`qué falta tenemos' for `e che colpa abbiamo'), `operativo' for an operation, `operario' for a
  worker (`i lavoratori autonomi' were `operarios autónomos') and `accidentado' for eventful -- each now after the
  dictionary's own word said again; and the verb of passing: with `trascorre' said first for passes, Italian wrote
  `Trascorrimi il coltello', `trascorrere una macchina' and `trascorreva a guidare' for the Spanish `pasar', and
  English passed what the Italian `trascorre' spends (`to pass the own holidays', `those that pass at least seven
  days'), and a Spanish line for `pasa' passes, which round a's store needed, made English pass the evening and many
  difficulties: the Italian writer's word for passes is `passa' now, its `happens' said again first, and the other two
  lines are gone. Of the code (round a's one store, 33 sentences, +0.053 %, and round b's data column): `de forma'
  after a phrase of a preposition was the manner (`Navarro, en un momento de forma excepcional' was `in a moment in an
  exceptional manner', and round b found it again inside the insertion, whose phrases come apart), and a verb alone
  between dashes was read as the adjective it is too (`Gallo - continua - mi ha lasciato' lost its comment), each now
  with its arm red; and an arm found the first cut of the manner rule too wide, as after an object `come el pan de
  forma alegre' was `of cheerful form'. THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (twenty sentences of the
  controls of 0.1 to 2 million inferences picked at random, ten from Spanish and ten from Italian, into English, over a
  copy of the library per rule on KB259): the first cut rose 13 490 inferences of 11.82 million (+0.114 %), and three
  rules were 84 % of it -- `la una' (6 039: tr_np/3's clause asked the determiner of the second word of every phrase of
  two), the lack (3 898: the lexeme of every noun before a phrase of `of', a determiner or not) and the phrase a
  participle's verb governs (1 356). What paid was a list made once a sentence of the words that mean the article `a',
  asked first ('$tr_a_lexemes'; asking the store of each word's meaning first left 2 544), and the lack's test of the
  phrase's determiner before the lexeme: the final cut rises 5 380 inferences (+0.046 %), `la una' 477 of them, the
  lack 910 and the governed phrase 1 356, every text of the twenty the same. THE STATED COSTS: a first meaning that
  serves the news and not every text -- `fiesta' and `festa' are a celebration (the party second: the Italian
  writer's word for a party is the political `partito'), `grueso' and `grosso' the bulk (thick second), `operativo' an
  operation, `accidentado' eventful (rugged, of ground, second), `rotta' broken (the route second) -- and the writers'
  `fiesta' and `festa' for a celebration, where they were `celebración' and `celebrazione', `concesionaria' for a
  contractor (`contratista'), `recogida' and `raccolta' for a collection (`cobro', `collezione'), `agente' for an agent
  and `passa' for passes, the store alone's 6 sentences above; `de forma' after a phrase of a preposition is that
  phrase's, so `trabaja en la empresa de forma eficaz' is `of efficient form'; the hour's gender in digits has no
  hand lesson that shows it (its arm is red on the store alone); and the inferences, +0.016 % on the one store and
  +0.030 % for the store alone. The report LEAVES, of the 19 into Italian (English alike unless it says): `la nulla
  presenza' and `the invalid presence' (1: none at all), `nella piazza della Catalogna' and `in the square of
  Catalonia' (the square's name), and `the eventful end of celebration of Nochevieja'; `the operation of cleaning of
  the square' (2: the cleaning operation); `Neanche aiutò il dispositivo' (3: `Non aiutò neanche') and `tre ore e
  mezza Dopo la festa' (the source's capital); `they highlighted' (5: the councilwoman, and English writes the subject
  nobody names as `they') and `in vain' written last; `Il 61' and `The 61' for `El 061' (7: the number loses its
  zero), `di tutto tipo' and `realised' (carried out); `The situation complicated' (8: became complicated), `non si
  potette normalizzare' (`poté'), `piantato di cascami rotti' and `planted with broken wastes' (strewn with broken
  rubbish) and `per il conflitto che registrava la piazza' and `for the conflict that registered the square' (the
  doer after a relative clause's verb: a square is no doer, and the relative word stays the subject); `il piano lavorò'
  (10: `funzionò'); `dell'alba' (11: `della notte', the dictionary's dawn for `madrugada'); `La sua funzione' and `His
  function' (12: theirs) and `quando questo si evacuava' and `when this evacuated' (the square: `questa', the
  subjunctive and the passive, which the demonstrative pronoun does not reach); `Davanti alla povera distribuzione'
  (13: `dispiegamento') and `che seguivano nella piazza' and `that followed in the square' (who were still there);
  `segnalò Frigola' written last (14), `Frigola signalled' (pointed out) and `two trucks of collection'; `in Ciutat
  Vella' written last (17) and `a truck of rubbishes'; `Le denunce civiche' (18: the citizens' complaints) and `the
  morning of the day 1'; and `dell'accadimento popolare' (20: `dell'evento'). Into Italian 16 is refused and into
  English it is `They had served the 10 installed containers in the zone of little': the idiom `De poco habían servido'
  (were of little use), read with `servir' transitive and nobody named. English refuses 3 for the third person nobody
  names, on purpose: the subject after the verb (`Tampoco ayudó el dispositivo de Mantenimiento y Servicios, que ...')
  is read as its object. The next sample's controls take this report in.
  The Spoleto and Torvaianica reports (VIT-9205..9224, 20 sentences: the Spoleto festival's closing concert and a
  hearing of the trial for a girl run over in Torvaianica, Italian into Spanish and English: 17 of 20 and 14 of 20 on a
  fresh store, 15 and 12 with the new store alone, 10 and 8 with the new code on the old store, 8 and 7 before;
  reasoning 1.0.23). The sample was taken on the cocolog 2.13.0 binary, master's 450b7a0 merged as 50e0b01 (CI, its
  verdict script and the install scripts, no change to the binary), and cocolog stays 2.13.0; master's b8812f4 and
  d06692a (the Intel Mac's CI job and its record, no change to the binary) came during the sample and are merged after
  it. The article's sentences fall from 35.1 million inferences in each language to 10.8 into Spanish and 10.9 into
  English, of which the tenth, refused, is 4.0 million in each.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_spoleto': 21 checks, 19 arms, 17 red in
  the section, one in newspaper_wapo and one guard of cost that stays green, below; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_spoleto, checks_done"', two seconds a run): A VERB WITH A PERSON FOR ITS
  OBJECT CROSSES BY THE MEANING THE LESSON GIVES IT THERE (`la Bx ha investito la ragazza' ran the girl over, and with
  `investe' `invests' first it was `has invested the girl' and `ha invertido la niña': `The personal verb "investe"
  means "runs over".', a class linked as the infinitival one is, tr_mean_links/3, tr_verb_across/5, the lesson's verbs
  that have one found once a sentence, '$tr_personal'), never with a thing for its object (`Il dottore investe il
  denaro' invests it, tr_person_object/1, a guard), and the participle said of a person crosses so too (`la ragazza
  investita a Torvaianica', tr_cross_np/2) -- four arms; English writes the participle of a verb of several words after
  its noun (`the girl run over in Torvaianica', where it was `the run over girl': tr_np_out/5); a phrase with its
  participle after it is of its head's class, so the person keeps the `a' Spanish puts before one (`ha atropellado a la
  niña quinceañera molestada poco antes': tr_of_class/2), never a word that replaces the noun (`ve el conducido por el
  gato', which the whole case found as `al conducido', its arm red in newspaper_wapo) -- two arms; ITALIAN'S ORDINAL IN
  DIGITS IS ONE WORD WITH ITS SIGN (`la 38-ma edizione del festival' is the 38th edition, and the tokeniser dropped the
  hyphen and left `ma', the word for `but', `el 38 pero edición': tr_number_written/4, `-ma' and `-me' `ª', `-mo' and
  `-mi' `º', the sign's codes the atom's own in each unit, a probe in newspaper_units); the word for `more' between an
  article and a participle, in a phrase of a preposition, the noun left out (`è stata fra le più eseguite' is among the
  most performed, and the phrase of `fra' ended at its article: tr_phrase_words0/4); A RUN OF CAPITALISED WORDS THAT
  OPENS ON A NAME IS ONE NAME, whatever the words after it are (`La Spoleto Festival Orchestra sarà diretta da ...',
  refused, `orchestra' a noun of the determiner: tr_np/3), the name first a guard of cost (an arm that takes any run of
  capitals reads every sentence of the controls alike for 0.35 % more inferences) and the second word's capital asked
  before the name's lookup (below); the copula with `thus' alone in front and nobody named is `it is thus' in English
  (`se così fosse stato, la Bx ... avrebbe subìto una decelerazione' is if it had been thus, and with the front written
  apart English refused it: tr_write/4); a verb of saying with a person's pronoun and an infinitive right after it is
  `tells' (`il mio fratellino mi disse di stare attento' told me to take care, where it was `said me to'); THE AGENT
  BEFORE ITS PARTICIPLE, WITH NO PHRASE BEFORE THEM, IS A FRAGMENT (`C'era la ragazza. da me vista troppo tardi".' --
  seen by me too late, and read as a statement `vista' was what `vistare' says, `Aprueba demasiado tarde desde mí':
  tr_read0/4 asks it first for such a piece, tr_verbless0/3 takes the participle by its form, `vista' the view too) --
  two arms; a capitalised word after a title is the name's though the lesson knows it (`il dottor Lombardi' is the
  doctor, `lombardi' the plural of `lombardo', and it was `the Lombard doctor': tr_stated_names0/2, `"dottore" is a
  title.'); a phrase after the comma that closes the subject set after a passive verb is the subject's apposition (`Sarà
  ascoltato il dottor Lombardi, il primo medico ad intervenire dopo la tragedia' -- a passive takes no object, and read
  as one it was `al primer médico' and `to the first doctor', and `la tesi del perito della difesa, a Italo Fainelli':
  tr_passive_subject_fix/3, appos/1); and the event one is at is a phrase of `at' (`Al processo di Torvajanica smentito
  Said' was denied AT the trial, where it was `to the trial': tr_comp_out/7, en_event_noun/1), never after a verb that
  goes there (`va al concerto', tr_motion_verb/1, a guard).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `messa da requiem'
  (a requiem mass, one noun of three words: as two the mass was the dough, `la masa desde réquiem'), `domani sera'
  (tomorrow evening), `imponenza' (magnificence), `lavavetri' (a windscreen washer, a person, its own plural),
  `semaforo' (a traffic light, where it was a semaphore), `si guadagna da vivere' (earns a living), `quindicenne'
  (fifteen-year-old), `fratellino' (a little brother), `sta attento' (takes care), `perito' (an expert, a person;
  `esperto' said again first), `stritola' (crushes, with its forms; `schiaccia' said again first), `in aula' (in court),
  `sbanda' (skids, intransitive), `ribatte' (retorts; `replica' said again first), `urto' (an impact; `impatto' said
  again first), `subìto' (the participle of `subisce' with its accent), `dottor' (the apocope of `dottore') and
  `"dottore" is a title.', `prossimo' and `prossima' (next before forthcoming), `udienza' (a hearing before an audience;
  `udito' said again first), `The personal verb "investe" means "runs over".' (`invests' said first), `nel momento in
  cui' (when), `non a caso' (not by chance), `concerto di chiusura' (a closing concert, not feminine), `muove i primi
  passi' (takes the first steps), `poco prima' (shortly before), the cities `Spoleto', `Torvajanica', `Torvaianica' and
  `Casalpalocco', and the name `colonia' (Cologne, a city); Spanish `misa de réquiem', `mañana por la noche',
  `limpiacristales', `semáforo' (a traffic light), `se gana la vida', `quinceañero' and `quinceañera', `hermanito',
  `tiene cuidado', `derrapa' (skids), `atropella' (runs over, with its forms: the dictionary's entry is of two English
  words, which the builder takes none of), `audiencia' (a hearing, after the audience), `no por casualidad', `concierto
  de clausura' (not feminine), `da los primeros pasos', `desaceleración' (the dictionary has none), `poco antes' and the
  name `colonia' (Cologne; Spanish states no city). The first meaning moved for 5 Italian words and 2 Spanish ones
  (`colonia' Cologne, `prossimo' and `prossima' next, `semaforo' a traffic light, `udienza' a hearing; `colonia' and
  `semáforo'), the writer's first word for 1 Spanish meaning (a hearing, `audiencia', where it was `oído'), and none was
  lost.
  THE CONTROLS (cocolog 2.13.0, store KB265, 118 count files, 3 238 sentences: the earlier set with the New Year's Eve
  report in, es_20010103-85, both directions; these reports are not among them): the last version's translator against
  this one, on the one store, 1 sentence reads differently, and better (it_9567_9604 10, `at the Roman meeting where
  Parisi has fought', where it was `to the Roman meeting') -- and the inferences rise 0.025 % (8 463 428 563 to 8 465
  515 390). Bytes and characters read every sentence alike (0 differ, the bytes 0.008 % more). The DATA COLUMN (the last
  version's translator on its own store, KB260, against this one on the new): 17 sentences in 8 files, +0.035 % (8 462
  547 227 to 8 465 515 390). THE CODE ALONE (this translator on KB260): 1 sentence, the one above, +0.025 % (8 462 547
  227 to 8 464 630 962), the largest rises Tempi's twentieth (+0.28 million of 517.5, refused both ways), the Venice
  report's eighth (+0.10 of 394.6) and it_9816_9850 25 (+0.05 of 26.6), the 3 232 others under 50 000 each. THE STORE
  ALONE (the last version's translator on KB260 and on KB265): 16 sentences in 7 files, +0.010 % (to 8 463 428 563), all
  better: `next' for `forthcoming' (14: `from next week', `in the next weeks', `to the next tournament in Japan', `in
  the next days', `from the next legislature', `before the next elections', `next Tuesday', `next February', `until the
  next "invitation"', `next January 24') and `Cologne' (es_19990601-23 3, `the European summit of Cologne', and
  it_9947_9966 14, `in Cologne', where it was `to Colonia').
  THE FIRST ROUNDS' REGRESSIONS, found by the whole case and by reading the texts of every column, and mended: the
  marker through a participle gave a word that replaces the noun its `a' (`El perro ve al conducido por el gato',
  newspaper_wapo), and `concierto de clausura' and `concerto di chiusura' end in `a' with no denial, so the ending rule
  made them feminine (stated_gender's scan of the vocabularies); `"colonia" is a city.' in Spanish, where no city is
  stated, wrote `duerme a Colonia' for in Cologne, and is out; and `udienza' said first for a hearing made it the
  writer's word for the sense, `tengo dos oídos' (Tatoeba 377) `ho due udienze' where it was `due uditi', until `udito'
  was said again first.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (four risers of the first round, then 40 control sentences of 0.1
  to 2 million inferences, 20 from each language, into English, over a copy of the library per rule on KB262): the first
  round was +0.058 % on the one store, and 0.74 of the 0.81 million inferences the four rose was the name run, which
  asked the name's lookup of every phrase that opens on a name word (`L'Italia ha avuto quattro governi ...' +9.4 %);
  every capital asked first cost three control files +0.84 % (a run with a name first and small letters after), the
  second word's capital first +0.09 %, which is the rule now. The 40 sentences rise 3 130 inferences (+0.026 %), no rule
  over 700: the title 654, the marker through a participle 361, the superlative participle 336, the verb before a person
  128, the fragment 80, and the name run saves 163.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `prossimo' is next (forthcoming second:
  the store alone's 16 texts of `next'), `udienza' a hearing (an audience second), `semaforo' a traffic light, the
  writer's `audiencia' for a hearing of a trial -- and `colonia' with a capital is Cologne (`a Colonia' in Italian is in
  Cologne); and the inferences, +0.025 % on the one store.
  The reports LEAVE, of the 17 into Spanish (English alike unless it says): 1 (`38 Spoleto festival.', a count, a name
  and a noun) and 7 (`Bianca nera.', two adjectives) are refused, and 10 (`riesce a contraddire sé stesso e le parole
  dell'imputato': a pronoun and a phrase joined, which no phrase reads; and `accusato di aver investito e ucciso Sara
  Folino', `acusado haber matado' with no `de' and English refused); `en la plaza Catedral' (2: `piazza Duomo' is a
  name, which the street rule takes only after a preposition), `tomorrow evening' last in English (2); `para la
  magnificencia' and the comma after `El Réquiem' lost (3: `per' says why, `por'), `intencionadamente' (`a propósito');
  `entre las más ejecutadas' (4: `interpretadas'), English refused for the third person nobody names, on purpose (3, 4,
  17); `toca' for `suona' is `juega' (5, the probes), `a Spoleto' kept after `che proprio a Spoleto ha mosso i primi
  passi' (5: the city rule does not go into a relative clause of a phrase's apposition, `to Spoleto precisely'); `negado
  al juicio' (8: smentito is proved wrong, `en el juicio'); `haciendo al limpiacristales a los semáforos' and `making
  the windscreen washer to the traffic lights' (9: `fare il' and a trade is working as one, and `14 years' old);
  `molestada' and `annoyed' (11: harassed), `para miedo' (`por miedo'), the quotation's opening mark lost and `says to
  have closed the eyes'; `me dijo tener cuidado' (12: `que tuviera'); `Había la niña' (13: `c'era' is the past of `c'è'
  in the vocabulary, so the state copula, which no past takes, is not written: `Estaba'); `ante los tribunales' last and
  `ha golpeado la niña' (15: `la ragazza' read as the subject after the verb, `the girl has struck', where two fronts
  with their commas stand before it), `The first car' (`prima' the adverb) and `skiding' (English's verb table has no
  `skid'); `Si así había sido' (16: `hubiera'); `a 70 a la hora' (17: `por hora'); `el médico Lombardi' (19: the title
  `doctor') and `will be listened' (`heard'); and `Proceso para la muerta de Folino, a la niña atropellada' and `I
  process for the dead one' (20: a heading read as the first person of `processa'). The next sample's controls take
  these reports in.
  The Spoleto faults (reasoning 1.0.24; cocolog stays 2.13.0; no new article). The three sentences of the Spoleto and
  Torvaianica reports that both languages refused -- 1 (`38 Spoleto festival.'), 7 (`Bianca nera.') and 10 (`Per
  difendere il fratello, Said, accusato di aver investito e ucciso Sara Folino a Torvajanica, riesce a contraddire sé
  stesso e le parole dell'imputato.') -- fixed in code and data. The reports read 20 of 20 into Spanish and 16 of 20
  into English on a fresh store, 17 and 14 with the new store alone, 19 and 15 with the new code on the old store, 17
  and 14 before, and their sentences fall from 10.8 million inferences into Spanish and 10.9 into English to 8.4 and
  8.5. English refuses 10 for the third person nobody names, on purpose, as it refuses 3, 4 and 17. Each rule has its
  arm red (test/translate.pl's `spoleto_faults': 38 checks, 37 arms, 35 red in the section, one red in newspaper_lazio
  and one guard of cost that stays green, below; lesson 46's section 87; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  spoleto_faults, checks_done"', two seconds a run).
  A NUMBER, A NAME AND A NOUN ARE AN EDITION (`38 Spoleto festival.' heads the report on the festival's 38th edition,
  `la 38-ma edizione del festival' the line after it: the paper writes the name before the noun in English's way, and a
  count stands right before its noun, never before a name before it -- read as a count of festivals the heading had no
  reading; tr_read0/4, the number the ordinal, its sign the noun's gender, `38º' or `38ª', the name the noun's phrase of
  `of', and each writer says it as its own, `38º festival de Spoleto', `38th festival of Spoleto': two arms); A NAME OF
  SEVERAL WORDS THE LESSON STATES IS A HEADING (`Bianca nera.' is the paper's column of crime news, before each report
  of a crime, and it crosses as it stands, `"Bianca nera" is a name.': tr_stated_names/3 joins it into one word, and as
  one word the heading had no reading, while read as its words it is a bare noun and an adjective, `Big house.', which
  stays refused -- tr_verbless/3), a name the lesson states only (`Cuida de Tom.' joins as a name of two capitals and a
  particle, and is a command: Tatoeba's 35 was copied as it stands in the first round) -- two arms; A PURPOSE IN FRONT
  WITH ITS OBJECT, A NAME APPOSED TO IT AND A PARTICIPLE BETWEEN COMMAS (`Per difendere il fratello, Said, accusato di
  aver investito e ucciso Sara Folino a Torvajanica, riesce a contraddire ...' -- to defend his brother Said, accused of
  having run her over, he manages: the commas around the name go into the apposition before the reading, w(_, appos),
  and refused, the shortest front was taken, `Per difendere' alone, and the brother was the one who manages; tr_read0/4,
  tr_front_aside_comps/1), and a name after a participle or an infinitive is their object, never a name apposed to the
  front's noun (`accusato di aver ucciso Sara, riesce a dormire' -- Sara is whom he killed: tr_front_name_apposed/2), a
  word that is an adjective too among them (`dei cristiano democratici Casini, Mastella, D'Onofrio e del popolare
  Sanza', it_9673_9712 16: `popolare' is also the infinitive of `popola', and with Sanza apposed `del popolare' was left
  to read as the verb, `y Sanza ... del poblar' and `of the populating', where it is `y del popular Sanza' and `of the
  popular Sanza' now) -- three arms; a city in a front is `in' (`a Torvajanica' is `en Torvajanica', and it_9947_9966
  20's `a Roma' between commas `in Rome': tr_cities_in/2); THE PERSONAL MEANING REACHES THE OBJECT TWO PARTICIPLES SHARE
  (`ha investito e ucciso Sara Folino' ran her over and killed her, where it was `ha invertido y matado':
  tr_personal_obj/2), and an infinitive, a perfect one and a second participle with a person after it cross so too
  (`vuole investire la ragazza', `accusato di aver investito e ucciso Sara Folino', crossed by the first meaning
  `invertir a la niña' and `invested and killed': tr_personal_comp/3 in tr_cross_comps/2), inside a front as well, whose
  complements travel as fr/1 -- six arms; THE WORD A PARTICIPLE TAKES BEFORE THE INFINITIVE AFTER IT (`accusato di aver
  ucciso' is `acusado de haber matado', `"acusa" takes "de" before the infinitive.', and written bare it was `acusado
  haber matado': the participle a list of complements has just written is noted, '$tr_last_pred', tr_note_pred/1, for a
  predicate, a participle after its noun and one that agrees with the object, and none is noted as a clause starts,
  tr_write/4; the clause's own verb takes its word where no participle stands before, tr_infx_lead/1, which gives
  Italian's `permette ai cantanti di concentrarsi', `evitò di pronunciarsi' and `tentò di consolarlo', where the
  infinitive with a pronoun joined to it had none), a denied infinitive with its word before the denial (`de no haber'),
  and a word the source kept as a complement of its own before the infinitive written once (nprep/1,
  tr_with_infx_kept/1) -- seven arms; English's `accused OF HAVING killed' (`accused to have killed' before:
  en_prep_gerund/2, `accuses' and `suspects'), after the participle the participle's, and of the clause's own verb for
  its first infinitive alone (`acusó a la mayoría de buscar por todos los medios hacer daño' is accused of seeking to do
  harm, and the first round wrote `of searching of making', es_19981202-34 12) -- four arms; A QUOTATION THAT OPENS ON
  THE INFINITIVE AFTER THE VERB'S OWN WORD OPENS THERE (`acusara a Millàs de "hacer trampa"' came out `di fare
  trappola"' and `of making trap"' once the lesson said `"acusa" takes "de" before the infinitive.', found by the store
  alone: qm/2 on inf/1 -- the infinitive stops the walk for an object of the verb, or the person was the indirect one,
  `accusa al gatto' and `accuses to the cat', tr_verbal_comp/1 -- and the mark goes on the infinitive after the word its
  writer put before it, asked before the infinitive is written, which sets the verb being written to its own,
  tr_inf_lead_word/2) -- three arms; AN EMPHATIC REFLEXIVE HEADS THE WORDS BEFORE A COORDINATOR (`contraddire sé stesso
  e le parole dell'imputato' is to contradict himself and the defendant's words, one object of two; `sé stesso' is a
  pronoun of no role, and with nothing to head the words before `e' the split was refused and the sentence with it:
  tr_headed/2) and is a person, which Spanish marks (`contradecir a sí mismo': tr_of_class/2) -- two arms; such a
  pronoun is of two words, the pronoun and the word for `same' (tr_two_words/1), asked before the lexicon: a guard of
  cost, below, whose arm stays green; TWO OBJECTS JOINED, ONE OF THEM A PERSON, TAKE THE PERSON'S WORD BEFORE THAT ONE
  ALONE (`contradecir a sí mismo y las palabras del imputado' -- asked of the pair, neither took it: tr_comp_out/7),
  never before a name (`tempi e Modi della terapia' was `tiempos y a Modi', it_9450_9464 10, found by the controls) nor
  before a phrase whose noun is left out, which is of the class of the other one and alone of any (`vede due stanche e
  tre gatti' was `ve a dos cansadas', which the Lazio section's guard found in the whole case: its arm is red there) --
  three arms; a pronoun a coordinator joins to a phrase after it is one object of two (`vede lui e il gatto' sees him
  and the cat, and taken alone the pronoun left `e il gatto' to read as nothing: tr_pronoun_joined/2), and a personal
  pronoun of English's IR is a person (`ve a él y al gato') -- two arms; and English writes a participle after a name
  apposed to its noun as the source has it (`the brother, Said, accused of having killed her', where it was `the accused
  brother, Said, of having killed': tr_np_out/5).
  It needed these WORDS in `extra/': Italian `"Bianca nera" is a name.' and `"accusa" takes "di" before the
  infinitive.', Spanish `"acusa" takes "de" before the infinitive.'. No first meaning and no writer's first word moved,
  and none was lost.
  THE CONTROLS (cocolog 2.13.0, store KB268, 120 count files, 3 278 sentences: the earlier set with the two reports in,
  it_9205_9224, both directions): the last version's translator against this one, on the one store, 17 sentences read
  differently, all better -- the five of the reports, Italian's `di' before an infinitive with a pronoun joined to it
  (5: `gli permetterebbe di dedicarsi', `permette ai cantanti di concentrarsi', `evitò di pronunciarsi', `si occupò di
  mostrargli', Tatoeba's `Lei tentò di consolarlo'), English's `accused Aznar of launching', `accused Millàs of "making
  trap"' and `accuses you of making' and Italian's `accusava Millàs di "fare trappola"' (4), `in Rome' (it_9947_9966 20)
  and `del popular Sanza' and `of the popular Sanza' (it_9673_9712 16, 2) -- and the inferences fall 0.052 % (8 487 227
  077 to 8 482 795 922) and rise 0.0040 % outside the reports (8 465 513 101 to 8 465 852 648): every sentence rises but
  four, by 48 inferences at the median, +0.035 % of the sentences under 0.1 million and +0.0014 % of those over 10
  million, the largest it_9999_10010 8 (+4 764 of 394.7 million in each language); it_9673_9712 16 falls 9 400 in each.
  Bytes and characters read every sentence alike (0 differ, the bytes 0.008 % more). The DATA COLUMN (the last version's
  translator on its own store, KB265, against this one on the new): 15 sentences, the 17 less the three that the old
  store already read so, and Spanish's `os acusa de hacer' (it_9714_9749 7), -0.053 % and +0.0040 % outside the reports.
  THE CODE ALONE (this translator on KB265): 12 sentences, all better, +0.0040 % outside the reports; Spanish's `acusado
  de haber' and `Bianca nera.' need the new lines. THE STORE ALONE (the last version's translator on KB265 and on
  KB268): 4 sentences, one better (`"El Olivo os acusa de hacer', it_9714_9749 7) and three worse, which the code above
  mends -- the old reader took `de' and its infinitive for a phrase of `of', and with `"acusa" takes "de" before the
  infinitive.' it read the verb's word and wrote `accused Aznar to launch' (es_20000903-30 21) and, the quotation's
  opening mark lost, `accused Millàs to make trap"' and `accusava Millàs di fare trappola"' (es_20020301-125 4); -0.0004
  %. KB268 is taught from the same vocabulary as the KB267 of the first rounds, and the last version's translator reads
  both alike, to the unit.
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column, the whole case and the probes, and mended,
  each with its arm red: `Cuida de Tom.' (Tatoeba's 35, a name heading), `tiempos y a Modi' (it_9450_9464 10), `of
  searching of making' (es_19981202-34 12), `ve a dos cansadas' (the Lazio guard) and the lost mark of `de "hacer
  trampa"' (above). The first round also narrowed the apposed name's guard to keep the old text of it_9673_9712 16,
  which the final rounds read as better without it. A STORE DOES NOT SURVIVE A SECTION: the second round's last three
  sentences and its count of the reports were void, because a run of the sections with `--embed KB267' wrote their hand
  lessons into the store; the round was taken again on a fresh KB268, and a section is run with no store.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (28 control sentences of 0.1 to 2 million inferences picked at
  random, 14 from each language, into English, over a copy of the library per rule): the first cut of the emphatic
  reflexive took the clitic `se' for one, and four sentences rose 77 000 inferences each (`se ne trova un'altra' split
  at its `e'), where three others fell 42 000 to 87 000, a split that failed at once, every text the same; with the
  clitic kept out, the 28 sentences rose 3 598 inferences (+0.034 %), 2 507 of them the emphatic reflexive's two rules,
  which asked the lexicon of every phrase of one word and of every phrase's noun. The two-word test first leaves +1 481
  (+0.014 %), of which the emphatic person rule is 302, the personal meaning in the complements 195, English's gerund
  after `accused' 138, the emphatic head 88 and the reset of the noted participle 63, no other rule over 50; a list of
  the reflexive lexemes made once a generation saved 57 of the 2 507 and was taken out.
  THE STATED COSTS: the inferences, +0.0040 % outside the reports; English's `it is' after the subject's relative clause
  in it_9673_9712 16 (`... D'Onofrio and of the popular Sanza, it is to have made'); and a lesson's emphatic reflexive
  of one word is none (no lesson states one).
  The reports LEAVE, of the three: English's `38th festival of Spoleto' (`the 38th Spoleto festival'); `Bianca nera.'
  crosses as it stands, its name untranslated, as the paper's column has one; and 10 into Spanish, `al hermano' (`a su
  hermano') and `consigue contradecir a sí mismo y las palabras del imputado' (`logra contradecirse a sí mismo'). What
  the Spoleto record says the reports leave stays as it is. The next sample's controls take this fix in.
  The Salou report (AnCora CESS-CAST-P-19990301-37, 21 sentences, the paper's report on the bombs on the beaches of the
  Costa Daurada, Spanish into Italian and English: 21 of 21 and 19 of 21 on a fresh store, 16 and 14 with the new store
  alone, 9 and 9 with the new code on the old store, 8 and 9 before; reasoning 1.0.25). The sample was taken on the
  cocolog 2.14.1 binary, master's e2239ea merged as bd5188f and built with Cicili 9b825b7 from a copy, and cocolog stays
  2.14.1: the binaries of 2.13.0 and 2.14.1 give the same texts and counts to the unit on the controls (3 278 sentences,
  0 differ, 8 482 795 922 inferences on both); master's 9c1c838 to bb80ca6 (test cases for the Apple silicon CI and
  documentation, no change to the binary or the library) came during the sample and are not merged, and the next sample
  takes them. The article's sentences fall from 67.6 million inferences into Italian and 67.3 into English to 37.7 and
  37.1, of which the fifteenth is 12.2 million in each. English refuses 5 and 17 for the third person nobody names, on
  purpose (`La mujer asegura que ha cambiado sus hábitos' names nobody in its clause of `that', and `las negativas
  consecuencias que pudiera tener' nobody in its relative clause).
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_salou': 54 checks, 58 arms, all red in
  the section; an arm is a library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_salou, checks_done"', two seconds a
  run): THE FIRST PERSON OF AN IMPERFECT OR A CONDITIONAL IS SPELLED AS ITS THIRD, and the subject pronoun says which
  (`Yo bajaba cada día a pasear a los perros' is I went down, and read as the third person with `yo' beside it the
  clause had no reading: tr_form0/5, under '$tr_first'; Tatoeba's `Yo os amaba', `Yo no quería el trabajo' and `que yo
  creía' read with it, which were refused); a denied clause whose subject says `more' denies in its subject (`No
  aparecen más artefactos' is no more devices appear, where it was `more devices do not appear': tr_write/4); `more' and
  a noun are a determiner and its noun, never a preposition and its phrase (`que haya más bombas enterradas', where the
  word was read as `plus': tr_determiner_before_noun/3), and `more' and a plural noun after a verb that takes an object
  are the object, the word the lesson's determiner (`Pondrán más explosivos' was `They will put more explosive', the
  comparative of the adjective), the word read as the adverb before a bare noun too, the adverb anywhere among the
  complements, where the reader moves it last, and the noun right after it in the words (`reclaman más ayudas para
  asegurar su futuro' and `darle más libertad a tu hijo' were `demand helps to ensure their future more' and `give
  freedom to your son more', found by the controls: tr_more_noun/4) -- three arms; the beach and the sand are what one
  is on (en_on_noun/1) -- two arms; `until' is a connector (en_connector/1), the denial right after it denies nothing
  (`hasta que no se haya resuelto el caso' is until it has been solved, as Italian's `a meno che non' is unless:
  tr_unless_word/1), and the impersonal `se' with a thing after its verb is the passive in the perfect too, where it was
  `until one has resolved the case' (tr_se_passive/2) -- three arms; an infinitive after the copula takes its meaning
  with no object, the phrase before it the copula's (`Es una locura bajar a la playa' is to GO DOWN, and with `una
  locura' taken for the infinitive's object it was `to drop': tr_cross_inf_comps/3); `must' in the past with a perfect
  infinitive is `should have' (`debían haber avisado a la población', where it was `had to have warned': tr_write/4);
  THE VERB OF RESULTING, A PARTICIPLE AND A PHRASE AFTER IT ARE THE PHRASE AND ITS PREDICATE (`resultó herido el
  artificiero de la Guardia Civil' -- read as an absolute clause after a verb with nobody named, the expert was what the
  injury left: tr_results_subject/5), the phrases of `of' with it (tr_fo_of_run/3), and English writes it as the
  participle's passive, never `turned out injured' (`también resultaron heridas' were also injured, `se reveló
  descompensado' was unbalanced: tr_write/4) -- three arms; the phrase after the infinitive of `upon' that the lesson
  calls intransitive is its subject (`al estallarle una bomba colocada en la arena' is a bomb exploding, and read as its
  object English wrote `on bursting him a placed bomb on the sand': upons/3, tr_upon_subject/4); the impersonal `se'
  with a person warned is English's passive (`no se les hubiera alertado', `si se hubiera advertido a la gente' --
  written as read, `one had not alerted them': tr_write/4, en_person_passive/1); a relative clause set off after two
  phrases joined hangs on both (`el Ayuntamiento de Salou y la policía, que conocían las amenazas' -- the plural clause
  disagrees with the last phrase, and read as its object relative the threats knew the police: tr_coord_rc_fix/4), and
  one after the phrases of `of' of a plural head, its verb in the plural, hangs on the head (`los artificieros de la
  Guardia Civil y del Ejército que han peinado las playas' -- hung on the Army, the clause took the beaches for its
  subject: tr_with_number/2) -- two arms; the doer right after the verb of a clause with a front is its subject (`en
  Cala Crancs juegan familias enteras en la arena' is whole families playing, and read with nobody named it was `they
  play whole families': tr_front_doer_fix/6); a phrase after the verb of a comment at the end of its clause, with nobody
  named, is its subject (`..., como indicaban los anónimos' is as the letters indicated: tr_cmt_subject_fix/2); a day
  the source names by `the day' and its number is the ordinal in English (`la bomba del día 21' is the bomb of the 21st,
  where `the day 21' was written: tr_np_out/5, tr_day_number/2), as when `on' it (`murió el día 13', and the controls'
  `la mañana del día 1' the morning of the 1st: tr_comp_out/7), and a participle and the day after it are no absolute
  clause (`el jubilado fallecido el día 13 al manipular un artefacto', where the day lost its `on': tr_day_label/1) --
  three arms; the main clause of a condition in the pluperfect is the conditional perfect (`si se hubiera advertido a la
  gente ..., no hubiera muerto aquel anciano' is that old man would not have died, where it was `had not died':
  tr_counterfactual/3); `hace' and a time after the verb is `ago', the time read as the verb's and the word for `ago'
  after it (`echó en cara hace una semana a Esteve Ferran' was `reproached a week to Esteve Ferran ago', and the
  controls' `vent'anni fa, nella direzione del "giornale"' was `twenty years ... ago' at the end: tr_ago_phrase/2); a
  verb of reproaching takes the person bare before its clause of `that' (`echó en cara ... a Esteve Ferran ... que no se
  hubiese alertado', where it was `reproached to Esteve Ferran': tr_comps_out/7, en_person_that/1), and the clause after
  the person may open on a denial and the pronouns of its verb (`han recriminado a las autoridades que no se les hubiera
  alertado', which read as the authorities' relative clause: tr_clause_after_person/1) -- two arms; a participle in the
  subject's phrase of `of' takes the phrase after it (`algunos habitantes de las localidades incluidas en la campaña de
  amenazas' -- with the campaign the inhabitants', English wrote `the included localities in the campaign':
  tr_inner_participle_adjunct/2); `last' and `first' stand before the count in English (`en las últimas tres semanas',
  where it was `the three last weeks', and the controls' `the last two years': tr_np_out/5, en_order_adjective/1); a
  demonstrative after the verb and the noun after it are one subject (`no hubiera muerto aquel anciano' is that old man,
  and read as the pronoun `aquel' for the subject the noun was left for a predicate: tr_demonstrative_subject/4); A
  WOMAN'S POSSESSIVE IS `her' (`La mujer asegura que ha cambiado sus hábitos', where the lesson's first meaning wrote
  `his', and the controls' `stretta alla sua tata' of a daughter: tr_female_possessor/1, '$tr_poss', tr_cross_det/2),
  and a husband's (`Marta Toledo, ..., y su marido' is her husband: tr_cross_np/2) -- three arms; a determiner the
  lesson says takes the indefinite takes it (`voy a otro sitio' is `vado in un altro luogo' (`"altro" takes the
  indefinite.'), where it was `altro luogo', and the controls' `appoggiare a un'altra candidatura', `In un'altra
  partita', `un altro albergo': tr_det_out/6); a determiner in the singular loses its ending where the lesson states its
  apocope (`no han localizado ningún artefacto' is `nessun dispositivo', where it was `nessuno dispositivo', and
  Spanish's `cualquier' is the short form of `cualquiera': tr_det_form/6, tr_det_apocope/3); a name the lesson gives a
  meaning has the gender the lesson states of it (`en los Alpes' is `nelle Alpi', and with Spanish's masculine it was
  `negli Alpi': tr_crossed_name_gender/2); a quotation that closed on a subject set last closes where the clause ends
  (the passive writes the case first, and the mark stayed on it, `until the case" has been resolved': tr_write/4); a
  word that is a person's noun and an adjective, after the comma that closes a subject set after the verb, is what the
  subject is (`sostiene Rebeca López, vecina de Cala Crancs' -- read as the adjective it was `maintains, neighbouring of
  Cala Crancs': tr_person_appos/2); a name with what it is set between commas, after a verb of saying with nobody named,
  is the speaker -- the commas made the name an aside and the verb's object, and English refused it (tr_aside_speaker/2)
  -- and the place apposed to the apposition's last phrase is the speaker's too (`vecina de Cala Crancs, el lugar donde
  ...': tr_appos_tail/1) -- two arms; an item of a list with its bracket is an item (`las playas de Tarragona, Salou
  (Tarragonès) y Cambrils (Baix Camp)' -- with the bracket the comma stayed the clause's, and the sentence was refused:
  tr_bare_tail/4), and a bracket right after a name that ends a relative clause is the name's, never the phrase's with
  its clause, which kept the clause from the head it hangs on (tr_np/3) -- two arms; a bare plural is a speaker (`según
  explicaron fuentes de los turoperadores de la zona', and with a determiner asked for the comment was refused:
  tr_report_subject/5); a thing's reflexive is the passive with its phrases of `of' too (`que las explosiones de Salou
  no se vincularan con una actuación terrorista', where it was `did not link': tr_thing_phrase/1); a name and its
  relative clause before a colon are a heading (`Todo lo contrario de Rebeca, que augura:' is quite the opposite of
  Rebeca, who predicts it -- the clause was one of `that' with nobody named, which English refuses: tr_verbless0/3), and
  so is a phrase whose phrase of `of' has the name and its clause -- two arms; a person's name after a phrase that ends
  on capitals the lesson knows is apposed as it is after a comma (`el artificiero de la Guardia Civil Luis Marfil' --
  with the capitals run together the phrase had no reading: tr_np/3); a word a quotation mark closes on keeps its
  pronouns (`hacerlo"' was a word no lesson knows: tr_enclitics/3), a mark on an infinitive the clause ends on closes
  where the clause ends, never after the verb group (tr_vq_close/4), the mark is no first complement, so the verb
  crosses by its meaning before an infinitive, `intends' (tr_front_comp/1), and `makes' with nothing made is `does', its
  pronoun `it' (`"No pienso hacerlo"' is I do not intend to do it: tr_write/4) -- four arms; a group after a verb of
  warning is its object, marked as a person is (`debían haber avisado a la población' should have warned it, and read as
  a phrase of `to' English wrote `warned to the population', and the controls' `Advirtió a sus antiguos socios', `avisó
  a Ibarretxe', `previno a los suyos': tr_warned_group/3), and after the infinitive of one, read with the modal's group
  (tr_warned_infinitive/2) -- two arms; and a verb before an infinitive with the word it takes crosses by its meaning
  there (`han renunciado a visitar las playas' have GIVEN UP, where it was `renounced to visit', and the controls'
  `cercherò di illustrare' I will try to illustrate: tr_verb_across/5), English's `gives up' taking the gerund
  (en_gerund_verb/1), after the word too -- three arms. Three rules of the first cut changed nothing in the article, the
  section or the controls, their arms green, and are gone: a bracket in a list of words, a bracket after the last name
  of a bare list and an English determiner `more' for a denial.
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `anónimo' (an
  anonymous letter, the noun: the dictionary has the adjective alone), `artificiero' (a bomb disposal expert, a person:
  the dictionary has the word and no meaning), `patronato de turismo' (a tourist board), `turoperador' (a tour
  operator), `viuda' (a widow, where the first was the widower), `vecino' and `vecina' (persons), `anciano' (an old man,
  the noun, a person), `artefacto' (a device, before the artefact), `arena' (the sand, before the arena), `a raíz de'
  (as a result of), `con anterioridad' (beforehand), `piensa' (thinks said again first, and intends before an
  infinitive), `baja' (drops said again first, and goes down with no object), `pasea' (strolls with no object, and
  walks), the name `Costa Daurada', `echa en cara' (reproaches, with its forms, taking the clause), `hasta que' (until),
  `todo lo contrario' (quite the opposite), `poco probable' (unlikely), `toca' (touches, before plays), `queja'
  (complains, reflexive, taking the clause and `de' before it), `población' (a group), `desde entonces' (since then),
  `"resuelve"', `"justifica"' and `"vincula" take the passive.', `"reina"' and `"aparece" are intransitive.', `renuncia'
  (renounces said again first, and gives up before an infinitive), the determiner `más' (more), `"recrimina" takes the
  clause.', `autoridad' (a person), `"marta" is a name.', `manifiesta' (states, before manifests), the name `alpes' (the
  Alps) and `estalla' (explodes, intransitive); Italian `estorsione' (extortion, said before `concussione', a public
  official's), `artificiere' (a bomb disposal expert, a person), `ente turistico' and `operatore turistico', `lettera
  anonima', `anziano' (elderly said again first, and an old man), `allarme' (the writer's first was `avvisatore', an
  alarm device), `in seguito a', `in anticipo', `scende' (descends said again first, and goes down with no object),
  `bar' (the writer's first was `barra', a rod), `accade' (happens said again first, and occurs: the writer's first was
  `occorrere', to be needed), `muore' (the writer's first was `decedere'), `riferimento' (the writer's first was
  `benservito', a dismissal), `finché' (until), `tutto il contrario', `da allora', `vicino' and `vicina' (persons),
  `rinuncia' (renounces, and gives up before an infinitive, with `a' before it), `altro' and `altra' (take the
  indefinite), `autorità' (a person), the name `alpi' (the Alps, feminine), `esplosione' (the writer's first was
  `deflagrazione', a word of chemistry) and `esplode' (explodes, intransitive); and in the dictionaries' extras
  `renounce' (`rinunciare': the Italian dictionary has the verb and no meaning) and, read only, `return' (`volver': the
  dictionary gives it only verbs of two English words, which the builder takes none of), `reproach' (`recriminar'),
  `manage' (`regentar'), `predict' (`augurar') and `pensioner' (`jubilado'). The first meaning moved for 10 Spanish
  words and 2 Italian ones (Spanish `anciano' an old man, `anónimo' an anonymous letter, `arena' the sand, `artefacto' a
  device, `baja' drops, `manifiesta' states, `pasea' walks, `renuncia' renounces, `toca' touches, `viuda' a widow;
  Italian `artificiere' a bomb disposal expert, `esplosione' an explosion), the writer's first word for 6 Spanish
  meanings and 8 Italian ones (Spanish unlikely `poco probable', device `artefacto', drops `baja', reproaches `echa en
  cara', states `manifiesta', walks `pasea'; Italian beforehand `in anticipo', alarm `allarme', bar `bar', explosion
  `esplosione', extortion `estorsione', reference `riferimento', dies `muore', occurs `accade'), and none was lost.
  THE CONTROLS (cocolog 2.14.1, store KB274, 120 count files, 3 278 sentences: the earlier set with the Spoleto faults
  in, both directions; this report is not among them): the last version's translator against this one, on the one store,
  29 sentences in 18 files read differently, all better but two that are no better -- `un altro' and `un'altra' (5:
  `appoggiare a un'altra candidatura', `un'altra brillante pietra miliare', `In un'altra partita', `un altro albergo',
  and Kallon's `un altro tempo' for `otra vez', as wrong as the `altro tempo' it was), the person warned bare (3: `They
  warned his ancient associates', `they warned Ibarretxe', `warned the theirs ones'), `were also injured' and `was
  unbalanced', `the last two years', `the morning of the 1st', `the steps that should have given', `twenty years ago' in
  its place, `who says satisfied', `her babysitter', `I will try to illustrate' and `intentaré ilustrar', and Tatoeba's
  `I loved you', `I did not want the job' and `You are simply not the person that I believed', read for the first time
  in both languages, `on the beach', `give more freedom to your son' and `più libertà al tuo figlio', and `nessun
  problema' -- and Tatoeba's `Tom said that I seemed wearied very', read where it was refused, the other one no better.
  The inferences fall 1.267 % (8 490 790 587 to 8 383 235 662), 0.432 % outside the twenty sentences that fall by over a
  million, every one of them Italian and its text the same (the Venice report's fourth 124.6 million to 114.2 in each
  language, Tempi's twentieth 517.8 to 507.4 and the Rognoni interview's nineteenth 361.0 to 358.0, both refused,
  Salvini's tenth 4.7 to 0.9); 2 947 sentences rise, by 279 inferences at the median, the largest the Venice report's
  eighth (+0.11 million of 394.8) and the Lord of the Rings' third and eleventh (+0.10 of 13.7 and of 30.4). Bytes and
  characters read every sentence alike (0 differ, the bytes 0.008 % more). The DATA COLUMN (the last version's
  translator on its own store, KB268, against this one on the new): 57 sentences, the code's 29 and the store's 28,
  -1.174 % (8 482 795 922 to 8 383 235 662). THE CODE ALONE (this translator on KB268): 22 sentences, every one among
  the 29, -1.271 % (to 8 375 003 041); the seven left need the new lines (`"altro" takes the indefinite.', the
  determiner `más'). THE STORE ALONE (the last version's translator on KB268 and on KB274): 28 sentences, +0.094 % (to 8
  490 790 587), each a word of the report's lines, all better but the five of the stated costs below -- `stated' and
  `dichiarò' for `manifestó' (7, where it was `manifested'), `accaduti', `accadrà', `accadendo', `esplosioni', `morire',
  `morì', `morirono', `morto' and `morti' where Italian wrote `occorsi', `occorrerà', `occorrendo', `deflagrazioni',
  `decedere', `decedette', `decedettero', `deceduto' and `avere deceduto' (11), `nude' (`appeared nude', where it was
  `nudes'), Spanish `bajar' for `scendere' (2, where it was `descender'), and Tatoeba's `We should return soon' and
  `Dovremmo ritornare presto', read for the first time.
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of every column and mended. Of the store (the store alone,
  KB273, 45 sentences): the Italian determiner `più', which a line made for the writer of `más bombas', read `non lo
  vide più nessuno' as more of nobody (`más ninguno', and `Oggi non ce n'è rimasto più nessuno' was `Today no more no
  has remained it'), and `a chi più guadagna' lost its adverb (`the one that earns ... more more'); the writer finds
  `più' as the adverb's word with no line, and the line is out; `accade' as occurs, said first, made `come è accaduto'
  `how has it occurred' and English refused it and the garrisons' sentence of it_9781_9791 (`come, peraltro, accadde in
  passato'), and happens is said again first now; and the verb of walking a dog, `portare a spasso', said for `pasear a
  los perros', was the writer's word for every walk (`Me gusta andar en tren' was `Mi piace portare a spasso in treno'),
  and is out. Of the code (the one store): `más' read as an adverb before its noun, which the reader moves last, made
  `reclaman más ayudas para asegurar su futuro' and `darle más libertad a tu hijo' `demand helps ... more' and `give
  freedom to your son more' (tr_more_noun/4 now takes the adverb anywhere, the noun right after it in the words: an arm
  red); and of the whole case, two older expectations written in the old English: `The dogs had to have eaten the
  bread.' is `... should have eaten ...' (in both files) and `The dog warns to the coaches that ...' is `The dog warns
  the coaches that ...'.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the five sentences of the code's second round that rose most on
  the one store, three from Spanish and two from Italian, into English, over a copy of the library per rule on KB274):
  they rose 4.05 million inferences of 47.60 (+8.5 %), and two rules were all of it -- the bare plural speaker, 4.48
  million (Kallon's sentence, es_20011002-160 13, 1.54; Rimac's, es_20001201-176 12, 0.86; the Middle Ages' thirteenth,
  it_9967_9998 13, 1.63; Venice's ninth, it_9999_10010 9, 0.45: the phrase was read at every place a speaker could
  begin, `los argentinos Guglielminpietro (Milan) y Vivas (Arsenal), los turcos ...', `jugadores que asumieron la
  responsabilidad ...', `teorie pagane sulla rotondità della terra e la rappresentavano ...'), and the name after an
  institution, 0.46 million (`un violín llamado Ex Von Szerdahely VieuxTemps', es_20010202-169 4, 1.37 million where it
  was 0.98) -- no other rule over 0.01 million. What paid was the cheap questions first: the bare plural speaker holds
  no comma, no bracket or aside, no relative clause and no verb, has no name right after its noun, its noun is no
  adjective, and no speaker begins right after a determiner, inside the phrase it opens; the name's capitals come right
  after a determiner, as an institution's do. The three sentences that rose most after that (the poor's fifth,
  it_9637_9672 5, `vivono 6 milioni e 458 mila poveri', 0.39 million of 2.36; es_20010102-25 2, `con tres explosiones',
  0.20; es_20010103-85 14, `provistos de dos camiones', 0.20) were the same rule, the phrase read after a count, and no
  speaker begins after a count either. Without the questions the section is green as well (it was so before they were
  written), as it is for a guard of cost. The five then stand at 46.69 million, 1.9 % under the last version's, and the
  three at 3.797, 0.07 % over it, every text the same.
  THE STATED COSTS: the store's intransitive `baja', `reina' and `pasea', which the report needs (`Yo bajaba cada día a
  pasear a los perros', `en la zona reina la tranquilidad'), cost three sentences of the controls a reading for nothing,
  the texts the same, each found by learning its line alone into the old store: `Bajo la dirección de Bertrand de Billy,
  ...' 1.87 million inferences in each language (0.75 to 2.62: `bajo' is the first person of the verb too, and the long
  phrase after it is asked for its subject), `esa reina destronada y saliente' 1.0 million of 10.5 and `cuando paseaba
  en la zona de La Recoleta' 0.37 of 0.49; the reflexive `queja' makes `"No hay derecho", se quejó' a third person
  nobody names, which English refuses on purpose, where it was `one complained'; Tatoeba's `Volveré a llamar a las dos y
  media', `Creo que deberíamos volver a Boston' and `Tom dijo que yo parecía muy cansado', refused before, read now and
  wrong (`I will return to call the two and a half ones', `I believe that we should return Boston' and Italian
  `rimettere Boston', `I seemed wearied very'): `volver' is read now, a dictionary line read only, with no word for
  `again' before an infinitive, and `a Boston' is the `a' of a person, which a line `"vuelve" is intransitive.' did not
  change; a first meaning that serves the news and not every text -- `toca' touches (`toca la guitarra' plays it),
  `arena' the sand, `artefacto' a device, `manifiesta' states, `anónimo' an anonymous letter, `anciano' an old man --
  and the writer's `artefacto' for a device (where it was `aparato'), `pasea' for walks (`anda'), `echa en cara' for
  reproaches, `poco probable' for unlikely and `manifiesta' for states, and Italian's `esplosione', `allarme',
  `riferimento', `muore', `accade', `in anticipo', `bar' and `estorsione'; and the inferences, -1.267 % on the one
  store, +0.094 % for the store alone.
  The report LEAVES, of the 21 into Italian: `non gli avvertiva del rischio dopo ricevere le lettere anonime' (1: `li
  avvertisse', the subjunctive written as an indicative and the object as a dative, and `dopo aver ricevuto'); `nelle
  tre ultime settimane' and `molti di cui' (2: `nelle ultime tre settimane', `molti dei quali'; English's order rule is
  English's alone); `non pretendo farlo' (4: the writer's word for intends, `ha intenzione di'), `ritornato' (a woman
  speaks), `esplodendo una bomba disposta nella sabbia' (`quando gli è esplosa una bomba collocata sulla sabbia') and
  `Guardia Civile'; `a camminare ai cani' (5: `a portare a spasso i cani'); `spagnolo d'origine peruviana' (7:
  `spagnola', an apposition keeps no gender) and `anche' last; `finché si è risolto il caso' (8: `finché non si sarà
  risolto', the expletive `non' and the future perfect); `Anche si lamenta che' (9: `Si lamenta anche del fatto che');
  `nella sabbia' and `potette' (10: `sulla', `poté'); `non ha variato' (11: `non è cambiato'); `dovessero avere
  avvertito' (14: `avrebbero dovuto avvisare'); `Se si era avvertito alla gente che non toccavano oggetti sospettosi'
  (15: `Se si fosse avvertita la gente di non toccare oggetti sospetti') and `manipolando un dispositivo' (`mentre
  maneggiava un ordigno'); `inizialmente' last (17); `Il rotante britannico' (18: `rotativo' is a daily paper, `il
  quotidiano'), `fecero sapere degli accadimenti' (`informarono degli avvenimenti') and `gli dedicarono' (`vi
  dedicarono'); `non si allacciavano con' (19: `non fossero collegate a'); and `credono inverosimile che ci sono più
  bombe' (21: `ci siano'); of the 19 into English: `many of which' (2: whom); `the danger that they ran beforehand' (3:
  `beforehand' last); `on a bomb placed on the sand exploding' (4: when a bomb placed on the sand exploded); `spaniard'
  and `they manage a bar and they have also taken precautions' (7: a Spaniard, the subject said again); `One also
  complains' (9: she, the reflexive read as the impersonal `se'); `the tranquillity reigns' (11: all is calm); `The Town
  council of Salou' (14); `affirm David' and `the pensioner died on the 13th on manipulating a device that had found'
  (15: David affirms, who died, that he had found); `that one had not alerted of the danger' (16: that no warning had
  been given of it); `The rotary British The Times ... reported of the events, although they did not devote him
  excessive space' (18: the British daily, reported on, devote it); and `The managers of the research believe unlikely
  that' (21: those in charge of the investigation believe it unlikely). The next sample's controls take this report in.
  The Grazioli trial report (VIT-9310..9323, 14 sentences, the prosecutor's requests at the trial for the kidnapping and
  death of Duke Massimiliano Grazioli Lante, Italian into Spanish and English: 14 of 14 and 14 of 14 on a fresh store,
  11 and 10 with the new store alone, 3 and 3 with the new code on the old store, 2 and 2 before; reasoning 1.0.26). The
  sample was taken on the cocolog 2.14.1 binary, master's fcde058 (test and documentation, fast-forwarded onto the
  branch), and cocolog stays 2.14.1; master's 887a472, 541fe10 (cocolog 2.15.0, async_workers/1) and 273585f (the token
  benchmark) came during the sample, change nothing under library/reasoning/, and are not merged: the next sample takes
  them. The article's sentences fall from 513.0 million inferences in each language to 44.2 into Spanish and 44.1 into
  English, of which the ninth is 20.5 million in each.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_grazioli': 25 checks, 28 arms, all red
  in the section, and a guard that is red in the controls alone, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_grazioli, checks_done"', under a second a run, and every arm is run in seven seconds, four at a time): TWO
  VERBS IN THE SIMPLE PAST JOINED BY A COORDINATOR SHARE THE SUBJECT AND THE OBJECT (`la banda che rapì e uccise nel
  1977 il duca' kidnapped and killed him -- `uccise' is the feminine plural participle too, and read as one it was said
  of the gang, `secuestró y matada': cverb/1, after a verb that is no copula, in a simple tense, where an object
  follows, and each writer writes it in the clause's tense and person, tr_cverbs/6) -- two arms; A NOUN THAT CAN SAY A
  MEMBER SAYS IT BEFORE A PHRASE OF `of' WHOSE NOUN IS A GROUP (`i componenti della banda' are the gang's members, where
  `componente' is a component first, and a component of a thing stays one: tr_relational_np/3, tr_group_head/1); a topic
  is no front of a first person nobody names whose verb is a noun too (`Processo Grazioli, sconto al pentito Abbatino'
  is the trial and a discount, two headings, and read as `sconto', I discount, English wrote `I discount to the
  informer': tr_read0/4); only a verb that can report has a speaker after it (`La banda, dopo il rapimento, uccise il
  nobile romano' is the gang killing him, and the Roman after the verb was the speaker of a clause that reports, `The
  gang, after the abduction, the noble Roman one killed': tr_reporting/3, a verb of saying or one that takes the
  clause); a heading that opens on a count, with a relative clause after its comma (`Otto anni e sei mesi per il pentito
  Maurizio Abbatino, che con le sue confessioni ha consentito ...' -- eight years for the informer, who allowed it; read
  as a clause of `that' with nobody named English refused it: tr_verbless0/3, the count word and the count of time read
  as a phrase of time: an arm and its two halves, each red); A CLAUSE RIGHT AFTER AN INFINITIVE TAKES THE INFINITIVE'S
  MOOD (`ha consentito di stabilire che la banda uccise il nobile romano' established that it killed him, and with the
  mood of `permitir', which takes the subjunctive, Spanish wrote `que la pandilla matara': tr_write/4 -- and the
  controls' `Non possiamo pensare che questo sia già vinto', where it was `è', and `los lombardos saben ser' and `como
  la iglesia se había equivocado', where the matrix verb's subjunctive was written, below); an insertion between commas
  after the participle's adjunct, before its agent (`le richieste fatte ieri, a conclusione della requisitoria, dal pm'
  were made yesterday, at the end of the closing speech, by the prosecutor -- the participle took `ieri' alone, and `dal
  pm' was a phrase of `from', `del fiscal': tr_reduced_agent/3); AN ARTICLE, AN ADJECTIVE OF ORDER AND A COUNT ARE A
  PHRASE WHOSE NOUN IS LEFT OUT (`(gli ultimi tre, esponenti della banda di Montespaccato)' are the last three, and the
  phrase had no reading: tr_np/3), and English puts the adjective before the count with no `ones' (`the last three',
  where it was `the three last ones': tr_np_out/5; the controls' `The first two have remained', below) -- two arms; A
  NAME MAY CARRY ITS BRACKET ON IN A LIST OF NAMES (`per Antonio Montegrande, Giorgio Paradisi, Marcello Colafigli,
  Emidio Castelletti (tutti della banda della Magliana), Enrico Mariotti, ...' -- with the bracket after the fourth name
  the names did not go on, the second was apposed to the first, and the commas after them stayed the clause's:
  tr_names_go_on/2, tr_list_word/2 and tr_list_commas/5, three arms and the three together), the bracket a list item
  before its comma only where a name follows the comma, never a phrase (a guard the controls found, its arm red there
  alone: `17 nuevos fichajes, entre ellos el portugués Conceiçao (Parma), los argentinos Guglielminpietro (Milan) y
  Vivas (Arsenal), los turcos ...' was 178.8 million inferences and refused in both languages, where it was 4.1 million
  and read; the hand lesson reproduces no list of three such groups); a preposition and its infinitive between commas is
  an insertion, and the noun the copula is too never divides the sentence after it (`Abbatino, prima di essere arrestato
  e di decidere di collaborare con l'autorità giudiziaria, era uno dei più noti malviventi' is the man who was one, and
  divided at `era', an era, he was a heading and the copula had nobody named: tr_insertion_comps/1, tr_read0/4) -- two
  arms; a passive infinitive of a preposition is a front of a relative clause, with the infinitives joined to it (`per
  Abbatino, che prima di essere arrestato e di decidere di collaborare ... era uno dei più noti malviventi della
  capitale, il pm ha chiesto' -- with the participle and the second infinitive no adjuncts it was no front, and the
  sentence was refused: tr_adjuncts_after/2); an infinitive joined to a preposition's infinitive is under the same
  preposition in English, both gerunds (`before being arrested and before deciding to collaborate', where it was `and to
  decide': tr_comps_out/7); `asks' takes `for' before its object and never before a count, which is how much is asked
  (`il pm ha chiesto la condanna a otto anni e sei mesi di reclusione' came out `has asked eight years and six months
  for the conviction': en_counted/1); THE CLEFT WITH ITS COPULA FIRST IN THE PERFECT, AND AN ADVERB BETWEEN COMMAS AFTER
  WHO IT IS (`È stato lui, infatti, a rivelare tutti i retroscena della vicenda' -- it was he, in fact, who revealed
  them; with the simple tenses alone it was a copula with nobody named, `It has been him, to reveal':
  tr_read_statement0/4) -- two arms; A DATE IN FRONT OF A RELATIVE CLAUSE'S VERB (`i componenti della banda che il 7
  novembre del settantasette, rapì il duca' -- the date was the clause's subject, and in a heading none had a verb:
  tr_relative_clause/4), the comma between the date and the verb none of the clause's, the paper's slip, which in a
  heading parted the clause from its verb and refused the sentence (tr_rel_time_comma/3), the year after the date's `of'
  the date's own (`on November 7, seventy-seven', where it came out `of the seventy-seven, on November 7':
  tr_date_year/2), and English's `on' before a date with its year (tr_comp_out/7) -- four arms; and adjuncts after the
  comma that closes the subject's relative clause, right before the verb (`Abbatino, che ha dato tutta una serie di
  indicazioni ..., per il pm è "pienamente affidabile"' -- for the prosecutor he is fully reliable; with no comma before
  the verb the phrase was read into the subject, and the long sentence was refused: tr_insertion_off/4). The first cut's
  comma branch of the date's front in a relative clause had a green arm once tr_rel_time_comma/3 took the comma, the
  article the same and 75 inferences fewer, and is gone.
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `sequestro' (a
  kidnapping), `pentito' (an informer, a person), `ergastolo' and `condanna a vita' (a life sentence), `requisitoria' (a
  closing speech), `corte di assise' (a court of assizes), `malvivente' (a criminal, a person; `delinquente' said again
  first), `retroscena' (an inside story, its own plural, not feminine), `processo' and `dibattimento' (a trial),
  `riscatto' (a ransom), `difensore' (a defender, a person), `telefonata' (a phone call), `discordanza' (a discrepancy,
  where the dictionary's first is a geologist's unconformity; `discrepanza' said again first), `alle porte di' (on the
  outskirts of), `a partire da' and `a cominciare da' (starting from), `alla fine di' and `a conclusione di' (at the end
  of), `quanto a' and `per quanto riguarda' (as for), `mette in luce' (brings to light, with its forms), `"banda" is a
  group.', `componente' (a component said again first, and a member, with `membro' said again first), `"franco" is a
  name.' (`Franco Catracchi', where it was `Frank'), `lungo' (along, the preposition: the adjective's `long' was its
  first meaning too), `tutta una' and `tutto un' (a whole, one determiner of two words), `rapito' (a kidnap victim, a
  person) and `alla fine' (in the end); Spanish `revela' (reveals, said first: the writer's word for it was `pone en
  evidencia', which has no participle, and the Spanish perfect `ha puesto en evidencia' was refused), `arrepentido' (an
  informer, a person), `cadena perpetua', `requisitoria', `tribunal penal', `entresijo' (an inside story), `llamada
  telefónica', `a las puertas de', `saca a la luz' (with its forms), `banda' (a band said again first, and a gang),
  `"banda"' and `"pandilla" is a group.', `defensor' (a campaigner said again first, and a defender), `al final de', `a
  lo largo de' (along: the Spanish writer had no word for it, and the sentence was refused), `toda una' and `todo un',
  `secuestrado' (a kidnap victim, a person) and `al final'. The first meaning moved for 2 Italian words and 1 Spanish
  one (Italian `discordanza' a discrepancy, `lungo' along; Spanish `entresijo' an inside story, where it was a secret),
  the writer's first word for 3 Spanish meanings and none Italian (a defender `defensor', where it was `zaguero', a
  football back; a gang `banda', where it was `pandilla'; reveals `revela'), and none was lost.
  THE CONTROLS (cocolog 2.14.1, store KB279, 122 count files, 3 320 sentences: the earlier set with the Salou report in,
  es_19990301-37, both directions; this report is not among them): the last version's translator against this one, on
  the one store, 7 sentences in 7 files read differently, 5 better -- the mood of a clause after an infinitive (3: `Non
  possiamo pensare che questo sia già vinto', where it was `è'; `los lombardos saben ser poco sentimentales' and `como
  la iglesia se había equivocado', where the matrix verb's subjunctive was written), `The first two have remained', and
  `ha golpeado a la niña' -- and two that are no better: the Spoleto report's fifteenth into English (`poi, sbandando,
  ha colpito la ragazza' is the car striking the girl, where the girl struck, and English refuses the third person
  nobody names, on purpose; its Spanish is the better text above) and the Veloso interview's fourth into Spanish (`con
  Gilda l'ex compagna di Vinicius De Moraes al fianco, incrocia affettuosamente l'amico Gilberto Gil' was read with the
  friend as the speaker of a reporting clause, `encuentra cariciosamente el amigo Gilberto Gil', and is read now with
  the ex-partner for the subject and `con Gilda' moved after the object, `la ex compañera ... encuentra cariciosamente
  al amigo Gilberto Gil con Gilda': both wrong). The inferences fall 0.073 % (8 447 504 598 to 8 441 365 137), 0.171 %
  outside those two sentences, whose new readings cost 2.4 and 1.7 million inferences more in each language; 3 098
  sentences rise, by 653 inferences at the median, the largest the Rognoni interview's nineteenth (+0.11 million of
  358.0, refused both ways), and the ones that fall most are the Rosi report's 21st (1.40 million to 0.50 in each
  language) and Tempi's seventeenth, the communiqué (it_9673_9712 17, 20.1 to 19.3), where a verb that cannot report is
  asked no speaker now. Bytes and characters read every sentence alike (0 differ, the bytes 0.009 % more). The DATA
  COLUMN (the last version's translator on its own store, KB274, against this one on the new): 13 sentences in 12 files,
  -0.197 % (8 458 039 233 to 8 441 365 137), the 7 of the code and the 6 of the store. THE CODE ALONE (this translator
  on KB274): the same 7 sentences, -0.073 % (to 8 451 900 194). THE STORE ALONE (the last version's translator on KB274
  and on KB279): 6 sentences in 5 files, all better, -0.125 % (to 8 447 504 598), each a word of the report's lines: `a
  whole' for `tutta una', `tutto un' and `toda una' (3: `A whole exploit', `It has been a whole ambiguity', `A whole
  series of problems', where it was `All an exploit'), `in the end' and `al final' for `al final' and `alla fine' (2,
  where it was `to the end' and `al fin'), and `Lo revela' for `Lo rivela' (where it was `Lo pone en evidencia').
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column, the whole case and the writers' first
  words, and mended. Of the code (round a's data column, KB277): the bracket counted as a list item before its comma
  whatever followed it, and the Kallon sentence of the Inter feature (es_20011002-160 13, `... 17 nuevos fichajes, entre
  ellos el portugués Conceiçao (Parma), los argentinos Guglielminpietro (Milan) y Vivas (Arsenal), los turcos Emre y
  Okan (Galatasaray), ...') was 178.8 million inferences in each language and refused, where it was 4.1 million and
  read; a name must follow the comma now (the guard's arm is red there, and no hand lesson reproduces the three groups
  it needs). Of the store: the line that said the dictionary's `entresijo' as a secret again first made it the Spanish
  writer's word for every secret (writerword2.py: `secreto' to `entresijo'), and is out -- no sentence of the controls
  has one; and the whole case's scan of the vocabularies found `retroscena', a masculine noun in `-a', with no line
  `"retroscena" is not feminine.' (stated_gender). Each mend took a fresh store: KB277 the first, KB278 the second,
  KB279 the final.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (the data column's three heaviest risers, into English, over a
  copy of the library per rule on KB279): the Spoleto fifteenth (+2.41 million) and the Veloso fourth (+1.74 million)
  are the reporting rule's, a verb that can report alone with a speaker after it, whose readings are the new texts
  above; and Tempi's 27th (`Quando infatti nella "sala delle firme" è iniziato il vertice, Berlusconi era già convinto
  che l'apertura dell'Olivo fosse solo un modo per prendere tempo', 21.2 million inferences to 23.1, its text the same)
  was the date's front in a relative clause, 1.83 million: each reading of a relative word that an article follows asked
  the six words after it for a month, as a lexeme each. Whether a month is among the sentence's words is a note made
  once a sentence now (`$tr_month', in tr_into_ir/4, asked first by the clause and by tr_rel_time_comma/3), and the
  sentence is 21.25 million (+0.14 %); the whole controls fall 0.228 % against the round before the note, every text the
  same. No other rule moved any of the three by more than 7 600 inferences (the joined past verbs 7 570, the order
  adjective's count 4 800).
  THE STATED COSTS: the reporting rule's two readings, the Spoleto fifteenth refused into English (on purpose: the car
  that struck the girl is a third person nobody names) and the Veloso fourth's `con Gilda' moved, 2.4 and 1.7 million
  inferences more in each language; the writer's first word for a defender is `defensor' (a football back is `zaguero',
  which a report of a match would want: no sentence of the controls has one) and for a gang `banda'; and a bracket in a
  list is an item only before a name, which a hand lesson does not show.
  The report LEAVES, of the 14 into Spanish (English alike unless it says): `Juicio Grazioli' and `Trial Grazioli' (3:
  the Grazioli trial, the name after the noun of a heading); `de setenta y siete' and `seventy-seven' (4: of '77); `con
  sus confesiones' written last (5: the phrase in front of the relative clause's verb, `che con le sue confessioni ha
  consentito'), `tras la abducción' (`el secuestro') and `the noble Roman one' (the Roman nobleman), and English `who
  has allowed to establish' (made it possible to establish); English `has been never found' (6: has never been found);
  `Son éstos las peticiones' (7: `Éstas son', the pronoun's gender), `a finales de la requisitoria' (`al final'), `al
  juicio' (`en el juicio') and `en tribunal penal' and `in court of assizes' (the article), and English `The requests
  ... are these' (These are the requests); English `everyone of the gang of the Magliana' (8: all of the Magliana gang);
  English `asked for the conviction to eight years' (9: a sentence of eight years, `condanna' a conviction to the
  lesson); `Ha revelado él' (10: the cleft's statement, `Fue él quien reveló'), `pasado' for `avvenuto' (occurred) and
  `de hecho' written last; `ancho crédito' (11: `amplio') and English `who believes fully reliable' (whom he believes)
  and `they have also admitted his position' (he has: the clause after `visto che' has nobody named); `sobre la base de
  las que' (12: `de las cuales'), `en el curso del juicio' and `in the course of the trial in the end' written last, and
  English `the made phone calls' (the phone calls made), `to hold the contacts' (to keep in touch) and `to attain the
  ransom' (to obtain it); and `el 17 de julio próximo' (13: `el próximo 17 de julio'). The next sample's controls take
  this report in.
  The ceramist report (AnCora CESS-CAST-P-20011202-118, 26 sentences, the paper's report on the ceramist of Gràcia who
  keeps the lower panels of Salvador Seguí's plaque and offers them to the `Comando Ciudadano Justiciero' that kidnapped
  it, Spanish into Italian and English: 26 of 26 and 19 of 26 on a fresh store, 17 and 10 with the new store alone, 6
  and 5 with the new code on the old store, 5 and 4 before; reasoning 1.0.29). The sample was taken on the cocolog
  3.18.0 binary, master's 914e98a merged as 3f471ba, and cocolog stays 3.18.0; master's 0979598, b35b25b and 81579bd
  (cocolog 3.19.0, 3.19.1 and 3.19.2) came during the sample, change nothing under library/reasoning/, and are not
  merged: the next sample takes them. The article's sentences fall from 54.6 million inferences into Italian and 54.4
  into English to 23.9 and 23.3. English refuses 5, 7, 13, 14, 16, 22 and 26 for the third person nobody names, on
  purpose: `A Xavier Oliveras le encargó el monumento Enric Ángela, ...' and `Al nutrido acto inaugural asistió incluso
  el comisario de policía del Raval' take the subject after the verb for an object, `Después telefoneó sin éxito al
  ayuntamiento', `"No conseguí averiguar con quién tenía que hablar"' (the imperfect's first person is spelled as its
  third, and no pronoun says which), `recuerda', `Ahora los ofrece ...' and the middle piece of 26, `Me da risa'.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_ceram': 40 checks, 48 arms, 43 red in
  the section, one red in newspaper_es and four guards of cost that stay green, below; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_ceram, checks_done"', under two seconds a run, and every arm is run in
  twenty seconds, four at a time): a participle after the copula's phrase of `of' takes the phrase after it (`Xavier
  Oliveras es el autor de la placa original dedicada al Salvador Seguí' is the plaque devoted TO him, and with the
  phrase the copula's English wrote `the devoted plaque to': tr_participle_predicate/3); AN ARTICLE BEFORE A FIRST NAME
  THE LESSON STATES, WITH CAPITALS AFTER IT, IS NO NOUN'S ARTICLE (`dedicada al Salvador Seguí' is to Salvador Seguí --
  `salvador' is a noun too, and it was `the Saviour Seguí': tr_np/3), never before a name the lesson does not state
  (`Pedro ve la Tate Gallery' keeps its article, a guard) -- two arms; a participle after a comma with nothing to close
  it takes its agent (`la placa ..., secuestrada por el comando' was kidnapped BY it, where the phrase of `por' was the
  clause's, `for the commando': tr_phrase_aside/4); A HEADING IN CAPITALS AT THE HEAD OF A SENTENCE IS A PIECE OF ITS
  OWN (`EL ENCARGO La historia de estos plafones es genuinamente kafkiana' is the heading and then the sentence, and
  read as one piece it had no reading: tr_caps_heads/2), and so are `LA PERIPECIA' and `EN EL TALLER'; a count after the
  verb opens its subject (`La placa la forman cuatro plafones' is four panels forming it, and with a count no subject's
  first word the sentence was refused: tr_subject_opener/1); `se' before an object pronoun is the verb's own where the
  lesson states its reflexive meaning (`Un camión de reparto apuró el giro en la calle de la Cadena y se los cargó'
  wrecked them, `The reflexive verb "carga" means "wrecks".', and taken for the dative of `le los' it was `loaded them
  to her': tr_expand/3), and a verb with no reflexive meaning keeps the dative (`Pedro se los da' gives them to her, a
  guard) -- two arms; A CAPITALISED WORD AFTER A STREET'S NOUN AND ITS `of' IS THE STREET'S NAME (`en la esquina de la
  calle de la Cadena' -- `cadena' is a chain to the lesson, and it was `of the Chain': tr_stated_names0/2, `"calle" is a
  street.', and `plaza', `avenida', `paseo', `rambla' and `carretera', Italian's `via', `piazza', `corso', `viale',
  `vicolo' and `strada'); the corner of a street is where one is AT (`en la esquina de la calle' was `in the corner':
  tr_comps_out/7), and the corner of a house one to be in (a guard) -- two arms; the person after the infinitive of a
  verb of taking is a phrase of `from' (`para saber el coste de la placa ... y reclamarlo a la aseguradora del camión'
  is to demand it FROM the insurer, where English wrote `to': tr_comps_out/7), after the infinitive's pronoun and after
  its object (`reclamar el coste a la aseguradora') -- three arms; `returns' and an infinitive is the infinitive's verb
  done again (`volvió a hacer los plafones dañados' made them again, where English wrote `returned to make':
  tr_write/4); A PREPOSITION AND THE QUESTION WORD FOR WHO OPEN AN INDIRECT QUESTION (`no conseguí averiguar con quién
  tenía que hablar' is with whom I had to speak, and the words had no reading: tr_complements0/4, after a verb that
  takes the question and after the infinitive of one, `"averigua" takes the question.') -- two arms -- asked in a
  sentence with a word the lesson gives `who' only ('$tr_who_word', made once a sentence in tr_into_ir/4: a guard of
  cost, whose arm stays green), and English writes `whom' (tr_comp_out/7); THE PRETERITE OF `ir' IS THE VERB OF GOING
  WHERE A PHRASE OF `to' FOLLOWS IT (`el ceramista ... fue a la plaza de Sant Jaume' went to the square, and read as the
  copula's past it was `was to the square', where Italian has no `fu' for it, `andò': tr_copula_goes/4), in a clause a
  coordinator joins, and with no phrase of `to' it stays the copula (`La casa fue de Pedro', a guard) -- three arms; a
  preposition and `quien' open a free relative (`entregarlos en el ayuntamiento a quien correspondiera' is to the one it
  was due to, and `quien' was read as the relative of the phrase before it, which no phrase took: tr_np/3,
  tr_phrase_words/4, tr_complements0/4) -- two arms, and the word's own relative test asked before its lexeme's, in a
  sentence with such a word ('$tr_free_rel'), a guard red on the store alone; English writes `whom' after a preposition,
  for a person (`el hombre con quien habla Juan' was `with which': tr_relative_out/5); A PERSON MARKED AFTER AN
  ACCUSATIVE PRONOUN IS THE ONE IT GOES TO (`Ahora los ofrece desinteresadamente al comando' offers them TO it --
  Spanish marks no second object with `a' -- and read as the person object the commando was what was offered, `Li offre
  il commando': tr_accusative_dative/4), with adverbs between the pronoun and the person, and only where the person's
  marker stands among the source's words (`Se les llamará chicos', whose `les' a lesson may leave no dative, was `Li si
  chiamerà a ragazzi': a guard red in newspaper_es, which the whole case found) -- three arms; `in case' is an English
  connector (`por si desea reponerlos': en_connector/1); THE WORD FOR `like' AND A CLAUSE THAT NAMES ITS SUBJECT IS A
  COMMENT OF `as' (`que el monumento a Seguí quede como él se merece' is as he deserves, where it was `like he
  deserves': tr_complements0/4), a subject after its verb too, read with nobody named and an object (`como dice el
  ceramista': tr_rel_subject_fix/2) -- two arms -- asked only where a verb form stands among the first four words after
  it, with only words that may go before a verb before it (tr_like_head/3, tr_like_pre/1: a guard of cost, whose arm
  stays green; with a verb form anywhere, `como "un punto de encuentro"' was read for the verb `encuentro'); A PRONOUN
  OF SOMEBODY OR NOBODY WITH ITS PHRASES IS A SUBJECT (`Por fin alguien con sensibilidad se ha preocupado de que ...' --
  the phrase reader reads no pronoun: tr_subject/6, tr_subject_shape/4), an object pronoun after its phrases the verb's,
  and never before a phrase of `of', which says how many of them (`se nessuno di voi ci ha mai creduto' is none of you,
  a guard) -- three arms, and the subject reader's clause a rule whose arm stays green, which stays for its cost
  (without it the shape's reading is asked again further on); an object before the infinitive is the verb's, never one
  after it (`Creo que van a restaurar la parte de arriba' had the part for the restoring, and taken for the verb's
  object it left nobody to go: tr_read_generic/4), and THE VERB OF GOING IN THE PRESENT BEFORE `a' AND AN INFINITIVE IS
  THE NEAR FUTURE (`"va" takes the future.': `they will restore', `restaureranno', where it was `they go to restore' and
  `vadano a restaurare': tr_near_future/3), in a clause of `that' too -- three arms; THE SIDE AFTER A COLON MAY BE A
  CLAUSE OF `that' ALONE, A COMMA, A COORDINATOR AND A CLAUSE (`Pensé: que se vayan al carajo, y me volví con los
  plafones' is what I thought and then what I did, and no clause read the first half: tr_read_after_colon/5); an adverb
  at the head, its comma, a coordinator and the rest (`En todo caso, y aunque no soy restaurador, me pongo a su
  disposición' -- a coordinator after the front's comma opened a second clause with nothing before it: tr_read0/4); A
  NOUN'S OWN CLAUSE AFTER AN INSERTION BETWEEN COMMAS (`En cuanto al anuncio por parte del Ayuntamiento, tras el
  publicitado robo, de que habían empezado hace dos meses los trámites para restaurarla' is the announcement THAT they
  had begun, and read after the insertion it was a relative clause on the theft, `of which': tr_read0/4, tr_that_set/1);
  `puts' with its own pronoun and nothing put is putting oneself somewhere (`me pongo a su disposición' is I put myself
  at his disposal, and with the pronoun dropped it was `I put at his disposal': tr_write/4); `al' AND THE INFINITIVE OF
  A VERB WHOSE MEANING THE LESSON STATES WITH ITS PRONOUN (`Al enterarse de la acción del Comando ...' is on finding out
  about it, and the front had no reading: tr_complements0/4, upon(reflexive(F), Cs)), its governed phrase marked
  (tr_ptc_governed/4) and crossed by that meaning (tr_cross_comp/2, '$tr_gov_sense'), and the lesson's language writes
  its gerund (`Venendo a sapere della azione') -- three arms; and a relative clause between its commas after the front
  of `al' is its last phrase's (`Al enterarse de la acción del Comando Ciudadano Justiciero, que secuestró la placa ...'
  is the commando that kidnapped it, and with the front ended at the comma the clause was one of `that' with nobody
  named: tr_upon_rest/5).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `ceramista' (a
  ceramist, a person of either sex), the name `Comando Ciudadano Justiciero' and `justiciero' (a vigilante, a person),
  `frecuenta' (frequents, with its forms: the dictionary has no `frecuentar'), `placa' (a plaque, the plate second),
  `plafón' (a panel, with `junta' and then `tablero' said again first, so that they stay the words written for a board
  and a panel), `semirrelieve' (a half-relief), `genuinamente', `"coloca" takes the passive.', `despacho' (an office,
  with `oficina' said again first), `camión de reparto' (a delivery truck), `apura el giro' (cuts the corner, with its
  forms), `carga' (loads, and wrecks with its own pronoun), `servicio jurídico' (the legal service), `de inmediato'
  (immediately, `inmediatamente' said again first), `averigua' (finds out, with its forms, taking the question), `de
  Herodes a Pilatos' (from pillar to post), `harta' (satiates, and gets fed up with its pronoun; `sacia' said again
  first), `al carajo' (to hell), `desidia' (neglect, `negligencia' said again first) and `mala educación' (bad manners),
  `entera' (informs, and finds out about with its pronoun, taking `de'; `informa' said again first), `peripecia' (a
  misadventure), `artículo de regalo' (a gift item), `desinteresadamente' (selflessly), `por si' (in case), `a
  disposición de' (at the disposal of) and `a su disposición' (at his disposal), `por fin' (finally, `finalmente' said
  again first), `de arriba' (upper, `superior' said again first), `publicitado' (publicised), `da risa' (amuses,
  `divierte' said again first), `a buenas horas' (belatedly), `fija' (notices with its pronoun, taking `en'), `"calle"
  is a street.' and the other five, the tenses and persons of `tiene que' (the dictionary gives the modal no imperfect,
  no future and no first person, and `tenía que hablar' had no reading), `preocupa' (concerns, said again first, and
  worries with its pronoun, taking `de' before the clause; `concierne' said before it), `"va" takes the future.' and
  English's `wrapped' (the upstream verb table's row for `wrap' is broken, and the writer made `wraped'); Italian
  `ceramista', `giustiziere', `frequenta' (frequents, `attends' said again first), `targa' (a plaque, the number plate
  first still), `mezzorilievo', `primavera' (the writer's word for spring was `fonte', a spring of water), `angolo' (a
  corner, the angle said again first: the writer's word was `angoletto'), `bancone' (a counter, where the writer's word
  was `contatore', a meter), `colloca' (places, where the writer's word was `dispone'), `camion delle consegne',
  `stringe la curva' (with its forms), `sfascia' (wrecks, with its forms), `servizio legale', `scopre' (finds out,
  `discovers' said again first, taking the question), `da Erode a Pilato', `stufa' (gets fed up with its pronoun,
  `stews' said again first), `al diavolo', `maleducazione', `viene a sapere' (finds out about, with its forms and
  gerund, taking `di'), `peripezia', `articolo da regalo', `disinteressatamente' (`disinterestedly' said again first),
  `nel caso che' (in case, with the subjunctive: `nel caso' alone joined `nel caso di', in the case of), `a disposizione
  di' and `a sua disposizione', `pubblicizzato', `diverte' (amuses, with its forms: the dictionary has no `divertire'),
  `kafkiano', `laboratorio' (a workshop, the lab said again first: the writer's word was the English `workshop'), the
  past and the participles of `spacca' (the dictionary gives `spaccare' none, and the Italian was refused), the six
  streets, `chiamata' (a call, where the writer's word was `richiamo', a recall), `assicuratrice' (an insurer: the
  Italian had no word for one, and the sentence was refused), `ceramica' (pottery: the dictionary's noun is mud),
  `accuratamente' (carefully), `preoccupa' (worries, with its forms: the dictionary has no `preoccupare'),
  `restauratore' and `restauratrice' (a restorer, persons), `formalità' (formalities) and English's `wrapped'. The first
  meaning moved for 4 Spanish words and 6 Italian ones (Spanish `carga' loads, `despacho' an office, `entera' informs,
  `placa' a plaque; Italian `accuratamente' carefully, `bancone' a counter, `ceramica' pottery, `chiamata' a call,
  `colloca' places, `stufa' stews), the writer's first word for 1 Spanish meaning and 7 Italian ones (Spanish genuinely
  `genuinamente'; Italian call `chiamata', corner `angolo', counter `bancone', spring `primavera', workshop
  `laboratorio', places `colloca', worries `preoccupa'), and none was lost.
  THE CONTROLS (cocolog 3.18.0, store KB287, 124 count files, 3 348 sentences: the earlier set with the Grazioli trial
  in, it_9310_9323, both directions; this report is not among them): the last version's translator against this one, on
  the one store, 13 sentences read differently, all better -- the near future (9: Tatoeba's `I will sleep in the flat',
  `What will I do with his letter?', `Do you doubt that he will win?', `you will fatten', and Italian `Dormirò
  nell'appartamentino', `Cosa farò', `Dubiti che lui vincerà?', `ingrasserai' and `Non durerà', where they were `I go to
  sleep', `What do I go to make' and `vado a dormire'), `whom' after a preposition (2: `for the lawyers, to whom one
  retains 20% of the incomes', `to whom an objective and uniform reference point is needed') and `again' (2: `And the
  panther sharpens the claws again', `I will call the two and a half ones again') -- and the inferences rise 0.152 % (6
  637 129 931 to 6 647 206 601): 3 338 sentences rise, by 1 021 inferences at the median, and the ten that fall are
  Tatoeba's near futures (784 at most). Bytes and characters read every sentence alike (0 differ, the bytes 0.011 %
  more). The DATA COLUMN (the last version's translator on its own store, KB279, against this one on the new): 26
  sentences, the code's 13 and the store's 13, +0.178 % (6 635 403 451 to 6 647 206 601). THE CODE ALONE (this
  translator on KB279): 4 sentences, all among the 13 (the near future needs `"va" takes the future.'), +0.152 % (to 6
  645 470 382), and every sentence rises. THE STORE ALONE (the last version's translator on KB279 and on KB287): 13
  sentences, +0.026 % (to 6 637 129 931), 10 better, each a word of the report's lines -- `collocata' and `collocare'
  for `colocada' and `colocar' (3, where it was `disposta' and `disporre'), `un angolo molto solitario' (where it was
  `angoletto'), `would have amused him' and `lo habría divertido' for `l'avrebbe divertito' (where it was `would have
  him fun' and `lo tendría divertido'), `could place between the 70 and the 90 thousand lire', `Era preocupado
  sinceramente de que', and Tatoeba's `They put to work immediately' and `si misero a lavorare subito' (where it was `of
  immediate' and `d'immediato') -- and three that are the stated costs below. KB287 and the KB285 before it read every
  sentence of the controls alike, with either translator (the lines that keep the writers' words move no sentence of
  them).
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column, the whole case and the writers' first
  words, and mended. Of the store (the store-alone columns of the first stores, KB281 to KB285): `"anuncio" means
  "announcement".', said for the report's `En cuanto al anuncio', made every ad an announcement (`un tablón donde dejar
  anuncios diversos', `un bonito anuncio de biquinis'), and is gone (the report's `the ad on the part of the town
  council' is the cost); `por fin' and `de inmediato' said first were the Spanish writer's words for finally and
  immediately (`Por fin, la reprimenda', `Me ha dicho de inmediato', `desde de inmediato' for `da subito', five
  sentences), and `da risa' its word for amuses, which has no participle, so that `la cosa l'avrebbe divertito' was
  refused: the dictionary's `finalmente', `inmediatamente' and `divierte' are said again first; Italian `nel caso', a
  conjunction with the subjunctive, took `nel caso di' for it, and five sentences were refused in both languages (`Nel
  caso di un bambino, poi, è ancora meglio', `tre nel caso delle Eolie', `nel caso del Giglio'): it is `nel caso che'
  now; and the writers' first words of the last store found six Spanish words the new lines had moved (informs `entera',
  concerns `preocupa', satiates `harta', upper `de arriba', neglect `desidia', panel `plafón'), and saying `tablero'
  again first moved the word for a board from `junta' to `tablero': the dictionary's words are said again first, `junta'
  before `tablero' (KB287, the final store). Of the code: the dative rule took `Se les llamará chicos', whose hand
  lesson leaves `les' no dative (`Li si chiamerà a ragazzi', the whole case's newspaper_es), and asks the person's
  marker among the words now; a pronoun's phrases kept as one term inside a phrase of `of' broke the crossing, and the
  clitic guard of tr_subject_shape/4 stands in its place; the reflexive `puts' cut its search before its test, and
  `Pedro se pone en la casa' was refused (once/1 now); and the comment of `as' cut the reader around it where its test
  held and its reading failed (once/1 now).
  THE COST OF THE CODE, FOUND BY TAKING EACH HUNK OUT (twenty sentences of the controls of 0.3 to 3 million inferences,
  Spanish into English, over a copy of the library per hunk on the old store, KB279): the first cut rose 42 731
  inferences of 14.53 million (+0.294 %), and the comment of `as' was 26 598 of it, its clause asked of every word for
  `like' with a verb form anywhere after it -- the four words, the words before the verb form and a reading that names
  its subject leave 100 --; and taking each rule out of the next cut, the question word after a preposition was 11 500
  (two clauses, 6 900 and 4 600, that asked the lexicon of the word after every preposition: they are asked now in a
  sentence with a word the lesson gives `who' only, a note made once a sentence), the heading in capitals 4 200, the
  noun's own clause after an insertion 2 300, the pronoun's shape 1 500 and the verb of going 500, no other rule over
  500. The final cut rises 32 748 (+0.225 %, 14 567 146). Over the whole controls every sentence rises, by 1 017
  inferences at the median, and the code alone is +0.152 %: the largest rises are the Rognoni interview's nineteenth
  (+0.12 million of 176.1, refused both ways), the Venice report's eighth (+0.09 of 250.5) and es_20001201-176 5 (+74
  736 of 3.39 million, +2.2 %: `como podía esperarse de los dos equipos' is asked as the comment of `as' and read as
  before), the text the same.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `placa' is a plaque (a plate second),
  `despacho' an office (the dispatch second), `entera' informs (whole, the adjective, second), `carga' loads (the load,
  the noun, second), Italian `bancone' a counter (a bar second), `chiamata' a call, `colloca' places (disposes second),
  `stufa' stews (the stove second) -- and the writers' `genuinamente' for genuinely, `primavera', `angolo', `bancone',
  `laboratorio', `colloca', `chiamata' and `preoccupa'; the store alone's three: `Era sinceramente preoccupato che ...'
  (it_10059_10095 29) is refused into English, where it was `It was worried earnestly that ...' (`preoccupato' is a
  verb's participle now, and English refuses its passive with nobody named, on purpose), and Tatoeba's `No tienes que
  decírselo a tus padres', refused before, is read now in both languages and wrong (`You must not say him your parents',
  `Non devi dirselo i tuoi genitori': the persons of `tiene que' read it, and no rule reads the person a dative pronoun
  joined to an infinitive says again); `En cuanto al anuncio ...' is the ad (above); and the inferences, +0.152 % on the
  one store and +0.152 % for the code alone.
  The report LEAVES, of the 26 into Italian: `rapito dal commando' (2: the plaque's `rapita', the participle agreeing
  with no noun after the apposition) and `davanti al loro abissale stato' (its: `en vista del suo pessimo stato');
  `salva' for `guarda' (3: keeps) and `inferiori' (lower); `Gli commissionò il monumento Enric Ángela ... a Xavier
  Oliveras' (5: the dative said twice, and the subject after the verb), `dopo fissarsi in una targa' (`dopo aver notato
  una targa'), `Sindacato di Cuadros' and `nella strada di Balmes' (`in via Balmes'); `si collocò' (6: `fu collocata')
  and `nell'angolo della strada della Cadena con Sant Rafael'; `per conoscere il costo' (11: `sapere'); `la
  rimpiazzerebbe subito ritornò a fare' (12: `l'avrebbe sostituita', `rifece'); `dopo' written last (13); `con chi
  doveva parlare' (14: `dovevo', the first person); `Quello fu d'Herodes Pilatos' (16: the adverb of the lesson's line
  not read after the copula, `da Erode a Pilato'); `d'un luogo a altri' (18: `da un posto all'altro'); `che si vanno al
  diavolo' and `mi ritornai' (19: `vadano', `tornai'); `miscelata' (20: `mischiata'); `gli tolse la polvere ai pannelli'
  (21: `spolverò i pannelli', the dative said twice), `così salvati' (kept), `in Gràcia' (`a Gràcia') and `che gli costò
  trovarli' (which he had trouble finding); `adesso' written last (22); `infine' and `rimane' (23: `finalmente', the
  subjunctive `rimanga'); and `che anche è danneggiata' (24: `che è anche'). Of the 19 into English: `in front of their
  abysmal state' (2: given its dreadful state); `saves the inferior panels' (3: keeps the lower ones); `the street of
  the Cadena' (6, 10, 12: Cadena Street) and `with Sant Rafael'; `a pair of years' (9: a couple); `a call of the legal
  service' and `to know the cost' (11: from, find out); `would replace her immediately made the damaged panels ... to
  substitute them again' (12: it, and `again' after the purpose); `to hand them in the town council to the one that
  corresponded' (15: to whoever it concerned); `I conserve' and `many doors of office' (17: keep, office doors); `Nobody
  knew nothing' and `of a place to others' (18: anything, from one place to another); `and mixed bad manners with
  bureaucracy' and `they regret' (20: bad manners mixed with bureaucracy, he complains); `to restore her', `removed him
  the dust to the panels', `saved in the bottom of his workshop of ceramist of gift item so' and `who cost him to find
  them' (21); `they say' and `remains' (23); `that also is damaged' (24); and `I am not restorer' and `at his disposal'
  (25: a restorer, theirs). The next sample's controls take this report in.
  The two television reports (VIT-9296..9309, 14 sentences: Alba Parietti's interview on Danish and Swedish television,
  and a parliamentary question on the RAI programme `generale per una sera', Italian into Spanish and English: 14 of 14
  and 14 of 14 on a fresh store, 10 and 12 with the new store alone, 3 and 3 with the new code on the old store, 3 and 3
  before; reasoning 1.0.31). The sample was taken on the cocolog 3.19.2 binary, master's 81579bd merged as 2bfab94, and
  cocolog stays 3.19.2; master's 51833fe and f7b0389 (cocolog 3.19.3 and 3.19.4) came during the sample, change nothing
  under library/reasoning/, and are not merged: the next sample takes them. The commit before this one (c4b9894, the
  load with no warning) counted 167 warnings: they were 177, the 167 blocks and ten warnings of 11 variables a clause
  names once, in 10 clauses. The article's sentences fall from 35.4 million inferences in each language to 31.8 into
  Spanish and 31.7 into English.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_tv': 44 checks, 36 arms, all red in the
  section; an arm is a library directory of symlinks whose reasoning/translate.pl is the edited copy,
  `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_tv, checks_done"', under a second a
  run, and every arm is run in twenty seconds, two at a time): A NAME AND A NUMBER OF ONE OR TWO DIGITS ARE ONE NAME
  (`"cinici e diseducativi" i film - Wargames di rai 1' is the channel Rai 1, as `Canale 5' and `Tg 4' are names; read
  apart, the number was a count with no noun and the headline was refused: tr_name_numbers/3, a name the lesson states,
  in small letters too, `"rai" is a name.', or a capital word the lesson does not know), never a count, where a noun
  follows the number (`a Roma 24 anni fa' is in Rome 24 years ago, and joined as the name `Roma 24' the Veloso
  interview's 34th sentence was refused in both languages: found by the controls) -- two arms; TWO ADJECTIVES JOINED
  BEFORE A DETERMINER SAY WHAT THE PHRASE IS (`"cinici e diseducativi" i film' heads the films that are cynical and
  miseducative, and the coordination, read before the clause of one adjective can be and cut, refused the piece:
  tr_read0/4), in a piece of ten words at most with no comma (a guard of cost, whose arm stays green: `Lapidario ma
  significativo il commento del primo presidente ..., Nicola Marvulli:' was asked as one and cost 67 thousand inferences
  more, its text the same), and a quotation that closes inside the sentence before a determiner is no mark of the
  sentence (with the mark the sentence's it came out `"The films are cynical and miseducative".': tr_head_mark/4) --
  never a quotation the speaker's verb follows (`"in ogni caso" puntualizza lui, "comincerò ...' kept its comma and its
  marks, which the first cut, any word after the close, lost in six texts of the controls: `"He clarifies, in any case"
  I "will commence', `"Hablará tras el 21 de julio" dice', and two refused), the lesson of the side the text is read on
  asked (tr_from_side/3 before tr_head_mark/4: with the target's language set, Spanish took no Italian determiner and
  wrote `"Las películas son cínicas y deseducativas"') -- four arms; a demonstrative and an article at the head of the
  side after a colon have their copula read in (`un'iniziativa "cinica e diseducativa": questo il giudizio dei deputati'
  -- this IS the judgement, and read without its verb English wrote `this the judgement': tr_demonstrative_copula/3); A
  BARE NOUN THAT IS ITS OWN PLURAL TAKES THE NUMBER OF THE PARTICIPLE AFTER IT (`un ciclo di film dedicati' is a cycle
  of FILMS, `"film" is the plural of "film".', and read in the singular it came out `un ciclo de película dedicadas':
  tr_cross_np/2, agrn/1); A PARTICIPLE IN THE OBJECT'S PHRASE OF `of' TAKES THE PHRASE AFTER IT WHERE ENGLISH SAYS THE
  PARTICIPLE WITH THAT PREPOSITION, after any verb (`Il programma propone un ciclo di film dedicati alle grandi
  battaglie' is a cycle of films DEDICATED TO them, and with the phrase of `to' the clause's English wrote `a cycle of
  dedicated film to the big battles': tr_participle_predicate/3, en_ptc_takes/2, `dedicates', `devotes', `addresses',
  `links', `destines', `assigns'), never a phrase English does not say the participle with, which may be the verb's
  (`compró un coche usado en Madrid') -- two arms; A SINGULAR NOUN THAT IS A COMMAND TOO, BEFORE A PHRASE OF `to' OR
  `of', HEADS A HEADING (`Intervista alle televisioni danese e svedese' is the interview, and read as the command
  `intervista!' English wrote `Interview to the Danish and Swedish televisions' or refused it: tr_noun_heading_start/1),
  and AN INTERVIEW IS WITH SOMEBODY (`In un'intervista a una tv danese' -- the Italian and the Spanish say the one
  interviewed with `to', and the phrase of `to' right after the noun is `with', the Spanish writer's `con':
  tr_cross_comps/2, tr_interview_comp/1), only after the noun for an interview (`dà un libro a una donna' gives it TO
  her) -- three arms; AN INFINITIVE WITH ITS REFLEXIVE PRONOUN CROSSES BY THE MEANING THE LESSON GIVES IT SO, as the
  verb of a clause does (`la libertà delle donne di denudarsi davanti ai telespettatori' is their freedom to STRIP, `The
  reflexive verb "denuda" means "strips".', and crossed by the plain `bares' it came out `to bare', which Spanish has no
  verb for, and the sentence was refused: tr_cross_comp/2), the pronoun going with the reading unless English too says
  the meaning of oneself (en_true_reflexive/1), and the lesson's writer puts its own back where its verb states the
  meaning as reflexive (`desnudarse', tr_comp_out/7) -- two arms; A SECOND AGENT AFTER THE COMMA, WITH ITS OWN TIME, IS
  THE PARTICIPLE'S (`in una intervista trasmessa giovedì sera dalla tv danese, e ieri da quella svedese' is broadcast by
  the Danish television, and yesterday by the Swedish one, the participle left out; read as the clause's, the second was
  a phrase of `from': tr_second_agent/2); a day and its part before the agent (`trasmessa giovedì sera dalla tv danese'
  was broadcast on Thursday evening BY it, and with the time read alone the agent was `from the Danish television':
  tr_reduced_agent/3), in a subject too, where the phrase ended at the participle (tr_phrase_words0/4,
  tr_time_before_agent/2), and English says a weekday and its part with `on' (tr_comp_out/7) -- four arms; TWO HEADINGS
  PARTED BY A DASH ARE EACH READ AS A PIECE OF ITS OWN (`"cinici e diseducativi" i film - Wargames di rai 1' -- the
  readers of a heading ask for the whole piece, which neither half was, and the headline was refused: tr_read0/4,
  tr_as_piece/2), each half eight words at most with no comma and no verb in the second; a name with its phrase of `of'
  is a heading (`Wargames di rai 1': tr_verbless0/3); A HEADING WITH ITS PURPOSE, THE RELATIVE CLAUSE ON ITS LAST PHRASE
  (`Una interrogazione parlamentare per denunciare il cinismo della trasmissione "generale per una sera", che esalta la
  cultura della guerra' -- the programme, which exalts it; divided at the comma, the clause was one of `that' with
  nobody named, which English refused: tr_verbless0/3), asked only where a word that begins the purpose stands before
  the comma (a guard of cost); a second noun that is a preposition too says no kind (`al ministro delle poste contro
  "generale per una sera"' is the question against the programme, and `contro' is a noun too, the con of pros and cons
  -- read as the kind of mail, English wrote `the con mails': tr_np/3); A DEMONSTRATIVE THE COPULA SAYS IS A NOUN TAKES
  THE NOUN'S GENDER (`questo il giudizio' is `este es el juicio', `Esa es la principal conclusión' `Quella è la
  principale conclusione', and written as the lesson's own neuter it was `esto es el juicio', `Quello è':
  tr_subject_out/6, the lesson's first demonstrative in the noun's gender, never one of no gender); a title's words are
  no verb's complements (`il cinismo della trasmissione "generale per una sera"' came out `de la transmisión a "general
  durante una noche"', the general marked as the clause's object: tr_np_out/5); A DENIED INFINITIVE'S `still' IS ITS
  `yet', inside it (`di non aver ancora sviluppato un sentimento comune' is of not having YET developed one -- pulled to
  the clause's verb, English wrote `has still accused': tr_comps_out/7, and tr_pull_adverb/3 takes no adverb right after
  a denied infinitive), and English's `not' stands after the preposition a gerund takes (`of not having evolved', where
  it was `not of having evolved': tr_comp_out/7) -- three arms; A SERIES OF INFINITIVES AFTER A COMMA ARE ALL THE
  VERB'S, EACH WITH ITS PREPOSITION (`ha accusato le donne di non essersi evolute ..., di non aver sviluppato' accused
  them of not having evolved, of not having developed, and with the verb's preposition for its first infinitive alone
  the second came out `not to have developed': tr_comps_out/7), and the lesson's writer gives each its word (`de no
  dormir, de no comer', where it was `no de dormir, no comer': the plain and the denied infinitive after a comma, and
  the word before a denied plain infinitive, `de no dormir', tr_comp_out/7) -- five arms; A DENIED INFINITIVE AFTER THE
  WORD THE SOURCE KEPT BEFORE IT TAKES NO OTHER (`fiel a su consigna de no arremeter' is `fedele alla sua direttiva di
  non assalire', where it was `di non d'assalire', and the first cut's word before a denied infinitive wrote `di di non
  assalire': tr_comps_out/7, found by the controls), the plain infinitive's writer asking what the one with its pronouns
  asks (tr_infx_lead/1: the word a kept word leaves out, and the participle's word); A PRONOUN ON A MODAL'S INFINITIVE
  IS THE OBJECT OF THE INFINITIVE AFTER IT (`vuole poterlo mangiare' wants to be able to eat it -- Italian and Spanish
  put the pronoun of the second infinitive on the modal before it, `poterlo', `doverlo', `volerlo', `poderlo', and
  written where it stood English said `to can him to eat': tr_comps_out/7), a purpose's too; and English says what is on
  television with `on' (`le donne che si spogliano in tv', en_on_noun/1).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `movimento' (a
  movement, where the dictionary's first is a motion, which the Spanish writer wrote `mociones'), `spoglia' (strips, and
  undresses with its pronoun, with its forms), `denuda' (bares, and strips with its pronoun, with its forms),
  `telespettatore' and `telespettatrice' (television viewers, persons), `soubrette' (a showgirl, a person, its own
  plural), the infinitive and the participles of `evolve' (the dictionary has none) with the copula its auxiliary and
  its reflexive meaning, `sul piano di' (in terms of), the copula as the auxiliary of `cambia' (`l'uomo italiano non è
  cambiato' has not changed; the Lazio report's `i valori non sono cambiati molto' was `no son cambiados'), `"alba" is a
  name.' (a first name, where the word is the dawn), `divertito' and `divertita' (amused, where the dictionary's
  adjective is fun), `intervistatore' and `intervistatrice' (interviewers, persons), `maschilista' (sexist), `mammone'
  (mother-fixated), `cinico' and `cinica' (cynical: the dictionary has the noun, the cynic, alone), `diseducativo' and
  `diseducativa', `progressista' (progressive, with `progressivo' said again first, so that it stays the word written
  for a gradual increase), `interrogazione' (an interpellation, a parliamentary question), `cambia canale' (changes the
  channel, with its forms), `esalta' (exalts, with its forms), the name `copenaghen' (Copenhagen, a city), English's
  `broadcast' as the past and the participle of `broadcasts' (its rule made `broadcasted'), `trasmette' (broadcasts,
  where the dictionary's verb conveys it, with its participles), `"rai" is a name.', `The word "tale da" begins the
  purpose.' and `come se niente fosse' (as if it were nothing); Spanish `desnuda' with its pronoun (undresses, then
  strips), `telespectador' and `telespectadora', `vedette' (a showgirl), `divertido' and `divertida' (fun said again
  first, then amused), `entrevistador' and `entrevistadora', `machista', `enmadrado' and `enmadrada', `deseducativo' and
  `deseducativa', `cambia de canal' with its forms, `exalta' with its forms, the name `copenhague', `broadcast', `en
  términos de' (in terms of: the Spanish writer had no word for it, and the sentence was refused) and `como si nada'.
  The first meaning moved for 5 Italian words and 1 Spanish one (Italian `cinico' cynical, `divertito' and `divertita'
  amused, `movimento' a movement, `trasmette' broadcasts; Spanish `telespectador' a television viewer), the writer's
  first word for 1 Italian meaning and no Spanish one (an interpellation, `interrogazione', where it was
  `interpellanza'), and none was lost.
  THE CONTROLS (cocolog 3.19.2, store KB293, 126 count files, 3 400 sentences: the earlier set with the ceramist report
  in, es_20011202-118, both directions; these reports are not among them): the last version's translator against this
  one, on the one store, 12 sentences in 12 count files read differently, all better -- the demonstrative in its noun's
  gender (4: `Quella era la condizione', `Quella è la principale conclusione', `Quella è una buona risposta', `Este es
  el texto del documento'), the agent after a day or an adverb (4: `promulgated on Thursday by the senate' and `por el
  senado', where it was `from the senate' and `del senado'; `a request advanced by the magistrates', and the Spanish of
  that sentence, it_10011_10058 18, refused before, is read now), `on Saturday morning', `on television', `la sua
  direttiva di non assalire' (es_20000903-30 5, where it was `di non d'assalire') and `podrán tener lugar' for `potranno
  svolgersi' (it_9792_9799 2, where it was `realizarse': the reflexive meaning, takes place) -- and the inferences fall
  0.031 % (6 697 195 993 to 6 695 124 592) and rise 0.032 % outside the two sentences that fall by over a million
  (it_9270_9295 8 in each language, 44.3 million to 42.2, its text the same: `Tg 4' is one name). 3 390 sentences rise,
  by 333 inferences at the median, the largest it_10011_10058 18 (+0.26 million of 1.97 into English, a new reading),
  it_9605_9636 5 (+0.10 of 2.10, the agent), Tempi's twentieth (+0.07 of 339.2, refused both ways) and it_9763_9774 12
  (+28 775 of 86 755, `Monica Ferretti Genova - Sestri P pacifismo "mascalzone".': the two headings of the dash asked
  and failing, its text the same). Bytes and characters read every sentence alike (0 differ, the bytes 0.011 % more).
  The DATA COLUMN (the last version's translator on its own store, KB287, against this one on the new): 16 sentences,
  +0.011 % (6 694 395 669 to 6 695 124 592), +0.074 % outside the two. THE CODE ALONE (this translator on KB287): the
  same 12 sentences, -0.031 %, +0.032 % outside the two. THE STORE ALONE (the last version's translator on KB287 and on
  KB293): 4 sentences, all better, +0.042 % (to 6 697 195 993), 2 871 sentences rising by 275 inferences at the median
  -- `spogliarono la Francia' for `desnudaron a Francia' (es_20020601-51 3, where it was `svestirono'), `after having
  broadcast' (it_9270_9295 20, where it was `broadcasted') and the Lazio report's `the values have not changed' and `no
  han cambiado' (it_9511_9539 14, where they were `are not changed' and `no son cambiados').
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of the one store and mended, each with its arm red: the word
  before a denied infinitive wrote `alla sua direttiva di di non assalire' after the source's kept `de' (the kept word's
  clause takes the plain and the denied infinitive now, tr_comps_out/7); `a Roma 24 anni fa' was the name `Roma 24' and
  the Veloso interview's 34th sentence was refused in both languages (no name before a noun's count); and the head mark
  of a quotation that closes before more words, first asked of any word after the close, lost the marks and the comma of
  Cecchi Paone's quotations (it_9270_9295 10 in both languages, `"He clarifies, in any case" I "will commence', 15 and
  19 in Spanish, `"Esta negociación mía con la Fininvest" dice que Cecchi Paone', and 14 refused in both): only a
  determiner after the close takes the mark from the sentence now, asked with the side already set. The hand lesson
  showed one more: the lesson's neuter `esto', a demonstrative of no gender, came first for `Questa è la casa', and the
  writer takes the first demonstrative in the noun's gender, never one of no gender. Two older checks changed with the
  rules: the Bovalino section's `The dog sleeps Sunday morning.' is `on Sunday morning', and the bank section's guard
  that a bare number is no object asks `El perro va al Tg 444.' (in test/translate.pl and in lesson 46's section 77):
  `Tg 4' is one name now, and in that section's lesson a name after `al' is the object of `va', `The dog goes the Tg 4.'
  -- the guard's arm is red on `Tg 444'. The section's insertion first dropped `newspaper_grazioli_checks_2' from
  test/translate.pl, which the whole case found (`Unknown procedure'), and it is back.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (18 control sentences of 0.1 to 2 million inferences picked at
  random and the riser it_9926_9946 17, into English, over a copy of the library per rule on KB293): the first cut rose
  79 961 inferences of 10.19 million (+0.78 %), and 67 456 of them were the two adjectives joined, which asked the
  heading reader of `Lapidario ma significativo il commento del primo presidente della suprema corte di Cassazione,
  Nicola Marvulli: ...' (+6.5 % of the sentence, its text the same), and the rest the name and its number (6 891, the
  digits asked of every word), the interview (2 246), the heading with its purpose (1 634) and the noun heading (985).
  What paid was the cheap tests first: the joined adjectives in a piece of ten words at most with no comma, the length
  of the word after a name before its digits, the shape of the phrase of `to' before the interview's noun, a word that
  begins the purpose before the comma, and the preposition before the noun heading's verb form; the nineteen rise 8 547
  (+0.084 %), every text the same, and the guards of cost' arms stay green.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `movimento' is a movement (a motion
  second), `trasmette' broadcasts (conveys second), `cinico' cynical (the cynic second), `divertito' amused (fun
  second), Spanish `telespectador' a television viewer -- and the writer's `interrogazione' for an interpellation
  (`interpellanza' before); `potranno svolgersi' is `podrán tener lugar' (above); `tale da poterci giocare' is `to be
  able to play us' (the pronoun goes after the infinitive, and `ci' is still read as `us', where it says `with it'); the
  dash rule's failed reading of a byline (+28.8 thousand inferences, above); and the inferences, +0.032 % outside the
  two that fall, +0.042 % for the store alone.
  The reports LEAVE, of the 14 into Spanish: `la libertad de las mujeres italianas desnudarse' (4, 8: the word before an
  infinitive after a noun's phrase of `of', `de desnudarse'); `El que no quiere ver' (5: `Quien'); `que se define ex
  feminista' (6: `como ex feminista'), `en términos de la solidaridad' (the article) and `una sensación común' (`un
  sentimiento'); `Interpelación en "general durante una noche"' (9: `sobre', `por una noche'); `los diputados
  progresivos' (11: `progresistas', the Spanish writer's word for progressive), `al ministro de los correos' (`de
  Correos') and `la transmisión' for the programme; `a finales de los que huéspedes famosos al público, releen' (12: `al
  final de los cuales invitados conocidos por el público releen') and `un juego de simulacro' (`de simulación'); and
  `postula una accesión ... para podernos jugar como si nada' (13: `presupone una adhesión ... tal como para poder jugar
  con ella'); of the 14 into English: `All the movements among the televisions' (1: the moves between the channels);
  `and by the Swedish one yesterday' (4: the adverb last); `The one that does not want to see, can change the channel'
  (5: whoever); `The Parietti, which defines ex feminist' (6: who calls herself one -- a name with its article is no
  person by its shape, as a club's is not) and `in terms of the solidarity'; `It is still sexist and mother-fixated' (7:
  he, the man before the colon not carried after it); `the minister of the mails' (11: the minister of Posts) and `the
  transmission' (the programme); `famous guests to the public, reread' (12: guests known to the public); `posits an
  accession to a culture of the war, to be able to play us' (13); and `the culture of the war' (14: the article). The
  next sample's controls take these reports in.
  The IOC report (AnCora CESS-CAST-P-20020301-99, 17 sentences: the IOC's investigation of the medical material the
  Austrian cross-country team left in a rented house near Salt Lake City, and the Spanish laboratory IMIM, Spanish into
  Italian and English: 17 of 17 and 15 of 17 on a fresh store, 15 and 12 with the new store alone, 10 and 12 with the
  new code on the old store, 9 and 10 before; reasoning 1.0.32). The sample was taken on the cocolog 3.19.5 binary,
  master's a71af87 merged as ed72782, and cocolog stays 3.19.5: the controls read every sentence alike on 3.19.2 and
  3.19.5 (3 400 sentences, 0 differ, 6 695 124 592 inferences on both). The article's sentences fall from 38.6 million
  inferences into Italian and 38.2 into English to 14.1 and 13.7. English refuses 15 for the third person nobody names,
  on purpose (`Reiteró, también, que se iban a endurecer las medidas'), and 3 (below).
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_coi': 31 checks, 28 arms, 27 red in the
  section and one guard of cost that stays green, below; an arm is a library directory of symlinks whose
  reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'),
  newspaper_coi, checks_done"', under a second a run, and every arm is run in seven seconds, three at a time): A
  RELATIVE CLAUSE WITH TWO VERBS, THE SECOND RIGHT AFTER THE COORDINATOR (`La oficina del sheriff, que declinó hacer
  comentarios y dirigió cualquier pregunta al COI, reconoció ...' -- the office that declined to comment and directed
  every question to the IOC; read to its coordinator the clause left `y dirigió ...' to the sentence, which was divided
  there, and English refused the half with nobody named: tr_relative_clause/4), the second verb in the first one's
  tense, person and number, each a verb's or a modal's form (tr_verb_lexeme/1: tr_form/5 gives any word as itself, a
  present third person singular, and the first cut took `il' and `vi' for the second verb of `che si occupa ... e il
  Ministero'), asked in a sentence that has the pattern only ('$tr_rel_two_verbs', tr_rel_two_verbs_note/1, a guard of
  cost whose arm stays green) -- two arms; a word that is a noun as well as a participle is the noun after a verb of
  suffering, receiving or causing (`sufrieron heridas al manipular el material' suffered wounds, and read as the
  participle said of the subject it was `suffered injured' and `soffrirono feriti': tr_ptc_noun_here/2); THE WORD FOR
  `nor' AND A PHRASE, SET OFF AFTER THE SUBJECT (`Ningún deportista español, ni ninguna federación, envía muestras a su
  laboratorio' -- no sportsman, nor any federation, sends them; read as a coordinated subject the halves had no reading
  with their commas, and the sentence was refused: tr_insertion_off/4), the phrase travelling as mid(nor(Phrase)) and
  written after the subject between its commas, with English's `any' where the source denied it again (`nor any
  federation') -- two arms; a word after a noun that is its adjective as well as a verb is the adjective only where it
  is the verb the reading took (the guard of `Una spesa media, per una famiglia ...' refused any piece that opens on a
  determiner, a noun, an adjective and a comma, and `Ningún deportista español, ni ...' had no reading:
  tr_adjective_not_verb/3); THE NEAR FUTURE IN THE PAST IS THE CONDITIONAL (`Reiteró que se iban a endurecer las
  medidas' -- that they would be tightened, and word by word it was `si andavano a indurire': tr_near_future/3, the
  imperfect's conditional beside the present's future), the reflexive the infinitive's and a thing's reflexive the
  passive, the thing after the verb its subject -- three arms; an English name the source's lesson calls an acronym goes
  out in capitals (`El COI' is the IOC, `"ioc" is an acronym.', and it came out `The Ioc': tr_word_text/4), with a
  quotation's closing mark on it too (tr_name_caps/2) -- two arms; `Nordic' takes its capital (en_nationality/1); a
  reporting clause between two quotations, the first closing on a word with its capital (`"Ignoro de qué está hablando
  el COI", dijo Mayer, "pero ...' -- with the small word's marks alone the reporting clause was read into the sentence
  and written after the second quotation: cmid/1, tr_closes_quote/1); `WHAT' AFTER A PREPOSITION OPENS AN INDIRECT
  QUESTION (`Ignoro de qué está hablando el COI' is what the IOC is talking about, and read with `qué' for the
  determiner of the word after it -- `habla' is speech too -- it was `of what speech': wh(pp(Preposition, what),
  Clause), read in a sentence with a word that asks `what' only, '$tr_what_word'), English putting the preposition after
  the clause (`what the IOC is speaking of') and the lesson's language before the word that asks (`de qué', `di cosa'),
  the doer after its verb the subject (tr_rel_subject_fix/2), and the quotation's closing mark the source's last word
  carried after the preposition, on the word or as its case (`"I ignore what the dog speaks" of' was written:
  tr_what_mark_off/4) -- six arms; a relative clause set off on the subject's last phrase of `of' keeps its commas (`La
  oficina del sheriff, que declinó ..., reconoció', where it was `the office of the sheriff that declined':
  tr_set_off_subject/5), its closing comma before the verb in the lesson's language too -- two arms; a noun that can say
  a sample says it in the plural with no determiner (`envía muestras a su laboratorio' are samples, where `muestra' is
  the newspaper's exhibition first, which `la muestra' keeps: tr_sample_noun/1); an activity English names with no
  article, as an -ism (`con el dopaje' is with doping: en_mass_activity/1); THE EVENT ONE IS IN IS A PHRASE OF `at'
  (`Segura estuvo presente ... en los Juegos de Salt Lake' was present AT the Games, where it was `in the Games':
  tr_comp_out/7, en_event_noun/1), the games in the plural only (`state proseguendo nel cosiddetto gioco del cerino' is
  continuing in the game, and the first cut wrote `at the so-called game') -- three arms; and the verb of enjoying takes
  its phrase bare in English (`goza, también, de una enorme fama' was `enjoys, of an enormous fame': en_bare_object/1).
  Two guards of the first cut, the question of `what' read to the end of the words with no comma, and never past a
  quotation's mark, had arms that stayed green and changed no text, the article's fifth sentence 21 and 102 inferences
  dearer with them, and are gone: the reporting clause's reader (cmid/1, above) sets the quotation apart with its
  commas.
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `investigación' (an
  investigation, said before the research), the name `coi' (the IOC) and `"coi" is an acronym.', `por orden de' (by
  order of), `por casualidad' (by chance), `muy cerca de' (very near), `equipo de fondo' (a cross-country team) and
  `esquí de fondo', `esquí' (skiing, before the ski), `nórdico' (Nordic, before Norse), `director' (a director, before
  the conductor), `vínculo' (a link, before the bond, with `enlace' said again first), `utilizase' (the past subjunctive
  in `-se', which the dictionary gives for reading only), `perfusión', `a la vez' (at the same time), `mujer de la
  limpieza' (a cleaning woman, a person), `positivo' (a positive test, the noun), `contundente' (forceful, before
  conclusive), `censura' (censure, the noun and the verb), `borrón' (a blot), `indefensión' (helplessness), `tal como'
  (just as), `antidopaje' (its own plural), `puede que' (maybe, with `quizás' said again first), `"ignora" takes the
  question.', `"utiliza" takes the passive.', `The verb "viene" marks the passive.' (`viene dada por' is is given by, as
  Italian's `venire'), `"goza" takes "de" before the phrase.' and `"disfruta" takes "de" before the phrase.'; Italian
  the name `cio' and `"cio" is an acronym.', `per ordine di', `per caso', `molto vicino a', `squadra di fondo' and `sci
  di fondo', `sci' (skiing), `nordico' (Nordic, before a northerner), `legame' (a link, with `collegamento' said again
  first), `perfusione', `allo stesso tempo', `donna delle pulizie' (a person), `positivo' (a positive test), `incisivo'
  (forceful), `censura' (censure, the noun and the verb), `macchia' (a blot, before the stain), `impotenza'
  (helplessness), `antidoping' (its own plural), `affitta' (rents, where the dictionary's verb hires, and a writer with
  no word for `rented' refused it), `vuote' (the plural of the adjective, said before the verb's, `vuotano'), `"ignora"
  takes the question.', `campione' (a sample, with the champion said again first) and `"gode" takes "di" before the
  phrase.'. The first meaning moved for 10 Spanish words and 11 Italian ones (Spanish `censura' censure, `contundente'
  forceful, `director' a director, `esquí' skiing, `investigación' an investigation, `nórdico' and `nórdica' Nordic,
  `positivo' a positive test, `quizás' maybe, before perhaps, `vínculo' a link; Italian `affitta' rents, `censura'
  censure, `impotenza' helplessness, `incisivo' and `incisiva' forceful, `legame' a link, `macchia' a blot, `nordico'
  and `nordica' Nordic, `positivo' a positive test, `sci' skiing), the writer's first word for 1 Spanish meaning and 2
  Italian ones (Spanish forceful `contundente'; Italian forceful `incisivo', sample `campione', where it was
  `dimostrazione', a demonstration), and none was lost.
  THE CONTROLS (cocolog 3.19.5, store KB300, 128 count files, 3 428 sentences: the earlier set with the television
  reports in, it_9296_9309, both directions; this report is not among them): the last version's translator against this
  one, on the one store, 19 sentences in 14 files read differently, all better -- `at' the meeting, the funeral and the
  trial (5: `Thus one checked at the meeting', `At a second meeting among representatives', `The participants at the
  funeral', `prosecutor at the trial', `the positions of the parts at the trial'), the relative clause set off on the
  last phrase of `of' (4: `the Lebanese player, who signed for 350 million pesetas,' and `il giocatore libanese, che
  siglò ...,'; `the group "Insula", which takes charge of ...' and `el grupo "Insula", que se encarga ...,'), the verb
  of enjoying (3: `will enjoy a discount of 30%', `they have enjoyed days of rest', `will enjoy some puff of oxygen'),
  the near future in the past and the present (2: `but we will not remain like silly either' and `ma neanche rimarremo
  come tonti', where it was `we do not go to remain' and `ci andiamo a rimanere'), the noun after a verb of causing (2:
  `without that causes descents of prices' and `retrocessioni di prezzi', where it was `dropped' and `calato'),
  Tatoeba's `No entiendo de qué hablan', refused before and `I do not understand what they speak of' and `Non capisco di
  cosa parlano' now (2), and it_9947_9966 6, refused before and read into English now (`The ambitious project will
  depart next Tuesday with the course "human missions in the blank", the first one of the gender in Europe, which will
  be held by the astronaut Roberto Vittori, beside the "school of aerospace engineering" of the university La Sapienza')
  -- and the inferences fall 0.595 % (6 759 647 265 to 6 719 429 906) and rise 0.073 % outside the four sentences that
  fall by over a million (the Lord of the Rings' eleventh, es_20020102-112 11, 24.4 million inferences to 3.0 in each
  language, and the Veloso interview's tenth, it_9225_9269 10, 1.7 to 0.5, both relative clauses with two verbs read at
  once, the texts the same). Every sentence rises but ten, by 636 inferences at the median, the largest the Rognoni
  interview's nineteenth (+0.13 million of 176.3, refused both ways), es_20000802-31 4 (+0.13 of 5.1) and es_20020801-17
  14 (+0.12 of 2.4), the texts the same. Bytes and characters read every sentence alike (0 differ, the bytes 0.011 %
  more). The DATA COLUMN (the last version's translator on its own store, KB293, against this one on the new): 43
  sentences in 18 files, -0.580 % (6 758 601 876 to 6 719 429 906), +0.089 % outside the four. THE CODE ALONE (this
  translator on KB293): 16 sentences in 11 files, every one among the 19, -0.595 % (to 6 718 386 451), +0.073 % outside
  the four; the three left are the verb of enjoying, which needs `"goza" takes "de" before the phrase.' and its kin. THE
  STORE ALONE (the last version's translator on KB293 and on KB300): 24 sentences in 6 files, +0.015 % (to 6 759 647
  265), all better but two -- `investigation' for `investigación' (16: `The investigation of the Congress of EEUU
  against the president Bill Clinton', `L'investigazione del Congresso', `The managers of the investigation', where it
  was the research) and `director' for `director' (6: `The director of RNE', `general director of RTVE', `the theatrical
  director Lluís Pasqual', Tatoeba's `I knew the director in person', where it was the conductor) -- and the two of the
  stated costs below.
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of every column and mended. Of the store (KB299, the store
  alone, 33 sentences): a line said first is the reader's meaning and the other language's writer's word, so `puede que'
  was the Spanish written for every Italian `forse' and `magari' (8: `Puede que no le había gustado', `puede que
  Giulietta no ha apreciado', `Y para hoy, puede que, un nuevo atisbo', `salvarla puede que,'), `legame' the Italian for
  every link (`con legami contro il nazismo' for `con links contra el nazismo'), and `vínculo' the Spanish for one: the
  dictionary's `quizás', `collegamento' and `enlace' are said again first now. Of the code (the one store, KB299, 20
  sentences): the games read as an event in the singular too (`You are continuing at the so-called game of the
  matchstick', it_9714_9749 11: the plural only now, its arm red), and Italian's `godere di', governed now, wrote the
  Spanish `disfrutar' bare (`Disfrutarán alguna bocanada de oxígeno', it_9472_9484 9: `"disfruta" takes "de" before the
  phrase.' says the Spanish writer's word). The first cut's arms found three green: the event arm was never built (its
  edit's text stood twice in the file, and the builder stopped; the runner now refuses an arm with no library), and the
  two guards above.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (27 control sentences into English, the three heaviest risers of
  the first round -- the Venice report's fourth, 85.4 million inferences, es_20020601-51 2, 20.2, and it_9967_9998 25,
  19.7 -- and 24 picked at random of 0.1 to 2 million, over a copy of the library per rule on KB300): the first cut was
  +0.560 % of the controls outside the four, and +3.202 % of the 27 (137.4 million inferences to 141.8), 96 % of it the
  relative clause with two verbs (4.22 million): the reflexive verb `si occupa' is one word, and tr_form/5, which gives
  any word as itself, a present third person singular, took `il' and `vi' after `e' for the second verb, so the clause
  read its first half and failed on the second 234 times in the Venice sentence (+2.70 million), and as often in the
  other two (+0.99 and +0.69). The rule's own note first, made once a sentence in place of the wider note of a
  coordinator and a verb's form, saved 0.11 % of the 27; the verb's class asked of both verbs (tr_verb_lexeme/1) saved
  the rest. The final cut is +0.085 % of the 27 (to 137.5 million), the texts the first cut's, and the note is a guard
  of cost (+0.162 % without it): of the 117 thousand inferences left, the reader of the aside of `nor' is 38.6 thousand,
  the reader of `what' after a preposition 31.2 and its note 22.5, the noun after a verb of suffering 15.6, the two-verb
  note itself 13.2 and the adjective's guard 8.9, no other rule over 800. Over the whole controls the code is +0.073 %
  outside the four.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `investigación' is an investigation
  (research second: `"Stradivari desarrolló su técnica a través de la investigación' is `through the investigation' and
  `tramite l'investigazione', es_20010202-169 14, the two texts of the store alone that are worse), `muestra' a sample
  only in the plural with no determiner, `positivo' a positive test as a noun, `esquí' skiing, `director' a director
  (the conductor second), `censura' censure (censorship second), `macchia' a blot (a stain second), `campione' the
  writer's word for a sample -- and the writer's `contundente' and `incisivo' for forceful; `quizás' is maybe before
  perhaps to the reader, which no sentence of the controls shows; it_9947_9966 6, refused before, is read into English
  with `the blank' for space and `beside' for at; and the inferences, +0.073 % outside the four on the one store and
  +0.015 % for the store alone.
  The report LEAVES, of the 17 into Italian (English alike unless it says): `un'investigazione scoprendo, per caso,
  materiale medico' and `on discovering, material medical ... by chance' (1: `al descubrir' is when it discovered, the
  adverb written last in English, `medical material'), `per la squadra di fondo' and `for the cross-country team' (the
  house rented BY the team: the agent after a participle and its place is a phrase of `for'), `d'Esquí' and `of Esquí'
  (the name keeps the source's word) and `il contenzioso dei recenti JJOO' and `the dispute of the recent JJOO' (the
  holding of the recent Games); `2 d'oro' and `2 of gold' (2: gold); `La sospetta del CIO' (3: `Il sospetto', the noun's
  gender taken from the verb's form), `sospetto che' (the verb after a subject with its relative clause, `sospetta
  che'), `potettero' (`poterono') and `sommamente pericolosi' (`estremamente pericolosa', the adjective's agreement with
  the practice lost), and English refuses it: a clause of `when' with `todo el material' inside the subject's relative
  clause has no reading (tr_read_nested/4 for the relative clause fails); `Il suo laboratorio Istituto Municipale
  d'Investigazione Medica (IMIM-IMAS) riconosciuto dal CIO gode, anche,' and `His Institute Municipal laboratory of
  Medical Investigation ... acknowledged by the IOC also enjoys,' (7: the apposition's commas lost and the name's words
  reordered in English, its laboratory, `recognised', the comma after `enjoys'); `come esperto nella materia' and `as
  expert in the matter' (8: `as an expert on the subject'); `di competizioni estere' and `of foreign competitions' (11:
  from); `si potrebbe avere evitato' and `one could have avoided' (12: `si sarebbe potuto evitare', it could have been
  avoided, the passive of the modal's perfect); `affermò' and `they affirmed' (14: he affirmed, the reporting clause's
  subject nobody names); `mercoledì passato' (15: `lo scorso mercoledì'); and `sfruttò l'intervista di TV per chiedere
  "perdono" al ciclista Joan Llaneras, medaglia d'oro in Sydney, per l'impotenza che soffrì' and `exploited the
  interview of TV to ask "pardon" to the cyclist Joan Llaneras, medal of gold in Sydney, for the helplessness that
  suffered' (16: took advantage of the TV interview to apologise to the cyclist, the gold medallist, for the
  helplessness he suffered: `pedir perdón' is an idiom, the doer of the relative clause after its verb is not read, and
  `in Sydney' is `a Sydney'). The next sample's controls take this report in.
  The CNR report (VIT-4883..4900, 18 sentences: the morning the president of the CNR shares out the year's funds among
  its bodies, a trolley of report cards on the institutes beside him, Italian into Spanish and English: 18 of 18 and 16
  of 18 on a fresh store, 17 and 14 with the new store alone, 11 and 11 with the new code on the old store, 10 and 10
  before; reasoning 1.0.33). The sample was taken on the cocolog 3.33.0 binary, master's a605949 merged as e1f8fe4 (the
  controls read every sentence alike on 3.19.5 and 3.33.0, 3 462 sentences, 0 differ, +0.056 % of the inferences), and
  cocolog stays 3.33.0; master's 60fd13c (lesson 51 alone) and d4ad532 (cocolog 3.34.0, format/2's `~@') came during the
  sample, change nothing under library/reasoning/, and are not merged: the next sample takes them. The article's
  sentences fall from 85.7 million inferences in each language to 32.8 into Spanish and 32.9 into English. English
  refuses 17 and 18 for the third person nobody names, on purpose (`Lo aveva fatto con una discreta abilità
  propagandistica ...', `La nota sulla quale aveva maggiormente insistito era stata quella ...').
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_cnr': 58 checks, 59 arms, 57 red in the
  section, one, `wdate-cross', that makes the section raise, and one green, below; an arm is a library directory of
  symlinks whose reasoning/translate.pl is the edited copy, `COCOLOG_LIBRARY=ARM cocolog query
  "use_module('test/translate.pl'), newspaper_cnr, checks_done"', under two seconds a run): A PRONOUN OF QUANTITY AND AN
  ADJECTIVE ARE ONE PHRASE (`C'è qualcosa di nuovo nella sala riunioni' is something new -- `di nuovo' is the lesson's
  `again', an adverb of two words the reader joins wherever they stand, and English wrote `There is something again':
  tr_unjoin_pronoun_adj/3 takes the two words apart after a pronoun that takes the word before an adjective, `"qualcosa"
  takes "di" before the adjective.', and padj/2 carries the pair, crossed and written by each language, `something new',
  `algo nuevo' -- four arms), and a pronoun that denies by itself takes no `no' (`Non c'è niente di nuovo' is there is
  nothing new, and Tatoeba's `No hay nada en la nevera' was `There is no nothing in the fridge'); AN HOUR AND THE ADVERB
  OF A PART OF THE DAY RIGHT AFTER IT (`Alle 9 di mattina' is at 9 in the morning -- `di mattina' is the lesson's `in
  the mornings', and it came out `At 9 in the mornings' and `A las 9 por las mañanas': it crosses as the part's phrase
  of `of', as a Spanish hour has it, en_day_part/2), in front of the clause too -- two arms; THE COPULA'S GERUND, A
  PHRASE AND A PHRASE AFTER IT ARE A SUBJECT AND ITS PREDICATE (`essendo la spartizione dei finanziamenti un momento
  cruciale' is the sharing out of the funds being a crucial moment -- read with nobody named, the sharing was the
  copula's object and the moment a time, `is the partition of the fundings a crucial moment': tr_gerund_subject/5, the
  subject's phrases of `of' with it, the predicate an object or a time, and English's `being' -- four arms); A NAME
  RIGHT AFTER A SUBJECT SET AFTER ITS VERB, A PERSON'S NOUN, IS THE PERSON'S (`entra il presidente Luigi Rossi Bernardi
  e saluta ...' is the president, Luigi Rossi Bernardi, entering, and read as the object the president entered him:
  tr_subject_name_after/5), with the clause's fronts before the verb too -- two arms; a word that is a pronoun and an
  adjective, right after a phrase, is the phrase's adjective (`non è una giornata qualunque' is not an ordinary day, and
  read as the pronoun `anybody' it was `It is not a day anybody': tr_pronoun_as_adjective/2); A DAY OF THE WEEK AND THE
  DATE RIGHT AFTER IT ARE ONE TIME (`È giovedì 6 giugno' is Thursday, June 6, and read as two the copula had a time and
  an object, `It is on Thursday June 6': tr_weekday_date/3, app(Day, wdate, Date), crossed, English's `on' before it
  after any other verb and its comma between them -- four arms, the crossing's arm making the section raise); A
  PARTICIPLE AFTER A PHRASE OF `of' THAT AGREES WITH THE PHRASE BEFORE IT AND NOT WITH THE PHRASE OF `of' IS THAT
  PHRASE'S (`ai circa 300 organi del Cnr sparsi per la penisola' are the bodies scattered across the peninsula, and hung
  on the Cnr it was `del Cnr esparcido': tr_of_participle_head/2 and tr_rel_number/5, the participle's own number
  carried, agrn/1), after a name of several words and after a name (`del San Raffaele', `di Roma'), the phrase the
  participle's verb governs with it (`"sparge" takes "per" before the phrase.', `scattered ACROSS it', en_governs/2,
  where the clause's phrase came out `for the peninsula') -- five arms; and A RELATIVE CLAUSE THERE THE SAME (`Un
  gigantesco carrello carico di documenti che è stato collocato ... alla sinistra del presidente' -- the trolley has
  been placed, and hung on the documents the clause had them for its object and nobody for its subject, which English
  refused: tr_rc_of_head/3); THE PARTICIPLE OF A VERB THAT TAKES NO OBJECT, AND A TIME RIGHT AFTER IT, IS A CLAUSE IN
  THE PAST (`dopo uno "scrutinio" durato mesi' is after an assessment that lasted months, where it was `after a lasted
  assessment months' and `tras una valoración durada meses': tr_lasting_participle/2, `"dura" is intransitive.'), among
  the complements of a participle the clause has too -- two arms; a second participle joined to a reduced relative's,
  with no agent (`i "voti" assegnati e scritti su quei fogli' are the votes assigned and written on those sheets, and
  the second, a noun too, was a second phrase, `the assigned votes and writings': tr_joined_participle/2, cpart/3); A
  COUNT OF TIME AND ITS `before' ARE ONE TIME (`La vicenda era nata sei mesi prima, esattamente il 31 ottobre 1984' was
  born six months before, and apart from the time English wrote it after the date, `six months, exactly October 31, 1984
  before': tr_ago_phrase/2 takes the lesson's word for `before' as it took the one for `ago', ago/2 keeps which, and
  each language writes its own word, the lesson's language its `before' after the time where it writes `ago' first,
  `tres meses antes' -- four arms); A COPULA WITH NOBODY NAMED, A PHRASE OF A PREPOSITION AND A CLAUSE OF `che' WHOSE
  SUBJECT STANDS AFTER ITS VERB IS A CLEFT (`È proprio su quel carrello che si concentra l'imbarazzato interesse dei
  presenti' is it is on that trolley that the interest of those present is concentrated -- read as a relative clause on
  the trolley, its doer after the verb took the trolley for its object, or its reflexive the trolley for its subject,
  and English refused both: tr_cleft_fix/3 and tr_cleft_clause/5, pp/2 and that/1, the doer after the verb its subject,
  and a thing after a reflexive the lesson says takes the passive, `"concentra" takes the passive.', the passive's
  subject with its phrases of `of' -- five arms); an article before a participle and a noun is the noun's (`si concentra
  l'imbarazzato interesse' is the embarrassed interest, and read as the pronoun `lo' and a predicate it came out
  `concentrates him embarrassed interest': tr_article_holds/2); the word for `about' after the article is the count's
  (`ai circa 300 organi' are the about 300 bodies, and `circa' is a preposition too, which ended the phrase at its
  article: adv_num/2, tr_counting_adverb/3); A RELATIVE CLAUSE AFTER JOINED ADJECTIVES IS THE WHOLE PHRASE'S (`un tema
  delicato ma importantissimo sul quale aveva assunto una posizione' -- split at `ma', the clause hung on `importante',
  a person, `pero a importante en el que': tr_conjunction_split/5 and tr_relative_after/2, a relative word or a
  preposition and one), an adverb among them too, which the tokeniser makes of a superlative (`molto importante') --
  three arms; a relative with its article is no noun (`La nota sulla quale aveva insistito era stata quella della
  valutazione' has `la quale' open the relative clause, and read as the noun `who' after `su' the note was on who, `era'
  an era the insisting took for its object: tr_noun/5), and never an indefinite phrase after a verb that takes an object
  is the clause's subject (`un tema delicato sul quale aveva assunto una posizione assai decisa' was `on which a
  position had taked': tr_rel_subject_fix/2 -- a guard, its arm red); an adverb at the head of the rest, set off by its
  comma, stays there in English (`che è stato collocato, bene in vista, proprio alla sinistra del presidente', where
  English wrote `placed, to the left of the president in full view': the gap writer of tr_write/4), and an adjective
  with a phrase of its own after its noun after `there is' too (`ci sono i dati relativi a tutti gli istituti' are the
  data relative to them, where it was `the relative data to', en_adj_takes/2's `relative') -- three arms; `really'
  stands with the verb, in a question too (`Davvero i fondi ottantacinque saranno distribuiti ...?' had it written last,
  `... on those sheets really?': en_mid_adverb/1); the state a verb of posture leaves (`i presidenti dei "comitati",
  seduti nervosamente intorno al grande tavolo' are SEATED around it, where the participle came out `sat':
  en_reduced_participle/2); a number the source put after its noun, in words, is the lesson's number word after the noun
  (`i fondi ottantacinque' are the funds of '85, and the lesson has no adjective for the number, so the sentence was
  refused: tr_adjective_out/5); an adjective the lesson's language says in several words that open on a preposition
  stands after its noun and its other adjectives (`Luigi Rossi Bernardi, cinquantaduenne direttore scientifico' is
  `director científico de cincuenta y dos años', where it was `de cincuenta y dos años director científico': a(postlast,
  Outs), tr_sides/3 -- two arms); the adjectives English says with `with' after their noun, with their phrase (`un
  gigantesco carrello carico di documenti' is a trolley loaded with documents, where it was `a gigantic loaded trolley
  of documents': en_adj_takes/2, en_with_adjective/1 -- two arms); `precisely' before the phrase of a preposition it is
  said of (`proprio alla sinistra del presidente', which was written last: tr_comps_out/7); `like all the years' is `as
  every year' (`È una giornata decisiva, come tutti gli anni, ...': tr_comp_out/7); and Italian's `si tratta di' is `it
  is' where the lesson's first meaning of `tratta' is `deals' (`Si tratta di una sorta di maxipagella della scienza
  italiana', where it was `One deals of a sort': tr_write/4) -- its arm is green in the section, whose hand lessons give
  `tratta' `treats' first, which the Inter feature's rule already writes `it is'; the controls show it, three sentences
  below. THE CONTROLS' FIRST ROUND found three more, each with its arm red: A HEADING'S PHRASE WITH ITS RELATIVE CLAUSE
  BEFORE A SUBORDINATING WORD (`Un dato confortante del quale non ci si può rallegrare perché l'intensità della povertà
  sta crescendo, ...' -- with the relative noun's guard above it was refused in both languages, where the old reading
  took `quale' for the noun `who': tr_join_left/5); `CI SI' AFTER A PREPOSITION'S RELATIVE IS THE IMPERSONAL `si' WITH A
  REFLEXIVE VERB, as a statement's is (the clause is read for a gap, and `ci' was `us' with nobody named, which English
  refused: tr_rel_ci_si/3, `del que uno no se puede alegrar', `of which one cannot gladden' -- two checks); and `have
  to' takes a mid adverb before `have' (`dovrà scegliere davvero' will really have to choose, and the new `really' came
  out `will have really to': tr_mid_insert/3, which wrote `will have also to' and `will have always to' as well, an
  older fault).
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Italian `carico' and
  `carica' (loaded, the adjective; the dictionary has the noun alone, a charge), `qualunque' (ordinary, the adjective,
  with `ordinario' and `ordinaria' said again first), the participles of `sparge' (scatters; the dictionary gives them
  to `spare', disappears) and `"sparge" takes "per" before the phrase.', `posta in gioco' (the stake), `del solito'
  (than usual), `sala riunioni' (a meeting room) and `centro ricerca' (a research centre, `"centro ricerca" is not
  feminine.'), `bene in vista' (in full view), `minaccioso' (threatening), `pagella' and `maxipagella' (a report card
  and a big one), `scrutinio' (an assessment), `foglio' (a sheet, where the dictionary's first noun is a blade), `fa un
  passo indietro' (takes a step back, with its forms), `cinquantaduenne' (fifty-two-year-old), `propagandistico'
  (propagandistic) and `malcontento' (dissatisfaction), `"qualcosa"', `"niente"' and `"nulla" take "di" before the
  adjective.', `"dura" is intransitive.', `sorta' (a sort; the dictionary has the participle of `sorge' alone) and
  `"concentra" takes the passive.'; Spanish `carrito' (a trolley: the Spanish writer had no word for one, and every
  sentence with it was refused), `apuesta' (a bet said again first, and the stake), `de lo habitual', `sala de
  reuniones', `centro de investigación', `bien a la vista', `boletín de notas' and `gran boletín de notas', `hoja' (a
  leaf said first, where the dictionary's first noun is a blade, and a sheet), `da un paso atrás' with its forms, `de
  cincuenta y dos años', `propagandístico', `"esparce" takes "por" before the phrase.' and `especie' (a species said
  again first, and a sort). The first meaning moved for 4 Italian words and 1 Spanish one (Italian `carico' and `carica'
  loaded, `foglio' a sheet, `qualunque' ordinary; Spanish `hoja' a leaf, where it was a blade), the writer's first word
  for 5 Italian meanings and 3 Spanish ones (Italian assessment `scrutinio', dissatisfaction `malcontento', sheet
  `foglio', where it was `lenzuolo', a bed sheet, sort `sorta', stake `posta in gioco', where it was `partecipazione';
  Spanish sheet `hoja', where it was `chapa', a sheet of metal, sort `especie', stake `apuesta'), and none was lost.
  THE CONTROLS (cocolog 3.33.0, store KB304, 130 count files, 3 462 sentences: the earlier set with the IOC report in,
  es_20020301-99, both directions; this report is not among them): the last version's translator against this one, on
  the one store, 20 sentences in 13 files read differently, all better but two that are no worse -- `it is' for `si
  tratta di' (3: `it is a million of boys in absolute terms', `It is a thought cheque', `That it is a rejected project
  at birth', where it was `one deals of'), `data' for `datas' (2), `at eight in the evening' and `a las ocho de la
  noche' (it_10059_10095 7, where it was `in the evening' written last and `por la noche'), `precisely' before its
  phrase (2: `precisely like the Tuscan ones', `precisely to Spoleto'), `are really in course' (it_9270_9295 9),
  `however,' with its comma (it_9381_9414 8), `instead,' where the source has it (it_9485_9510 12, `No special case,
  instead, in Ponza'), `will really have to choose' (it_9605_9636 29, where `davvero' was written last), `There is
  nobody' and `There is nothing in the fridge' (Tatoeba's 195 and 246, where it was `There is no nothing'), `a
  comforting data of which one cannot gladden' and `del que uno no se puede alegrar' (it_9637_9672 19, where `quale' was
  the noun `who', `of who not can gladden us' and `de quién'), and es_19990901-75 7, refused before and read into
  English now (`The Ministry of Economía has begun to collect information of the effects that can have the fusion ...')
  -- and the two no worse: `a consortium of international, Arab or Australian operators that are' (it_9605_9636 14,
  where it was `of international operators, Arabs or Australians that are': the source's `arabi o australiani' are
  adjectives, and `che siano', whatever they are, is no better either way), and `It seems me precisely of no'
  (it_9714_9749 24, where `precisely' stood after `of no'). The inferences rise 0.117 % (6 754 175 668 to 6 762 110 579)
  and 0.068 % outside one sentence (below): every sentence rises but 22, by 362 inferences at the median. Bytes and
  characters read every sentence alike (0 differ, the bytes 0.011 % more). The DATA COLUMN (the last version's
  translator on its own store, KB300, against this one on the new): 21 sentences, +0.166 % (6 750 906 884 to 6 762 110
  579). THE CODE ALONE (this translator on KB300): the 20 of the one store, +0.117 %. THE STORE ALONE (the last
  version's translator on KB300 and on KB304): 1 sentence, better, `they do it on a sheet to two dimensions'
  (it_9967_9998 25, where it was `a blade'), +0.048 %, nearly all of it `"dura" is intransitive.' in two sentences of
  one file, their texts the same (`è durata così poco' +0.48 million inferences of 11.8 in each language, it_9851_9925
  6, and `Dura 6 mesi' +68 thousand of 49 thousand, 27).
  THE FIRST ROUND'S REGRESSIONS, found by reading the texts of every column and mended, each with its arm red: the
  relative's guard (`la quale' is no noun) left `Un dato confortante del quale non ci si può rallegrare perché ...'
  (it_9637_9672 19) with no reading in either language, where the old one took `quale' for `who' -- the heading's phrase
  with its relative clause before `perché' read then, and English refused its clause until `ci si' after the
  preposition's relative was the impersonal (the two rules above); and the new `really' wrote `will have really to
  choose' (it_9605_9636 29), the place `have to' gave `also' and `always' before, which the same fix mends. The whole
  case found two more: the islands section's `Nessuna casa, invece, a Roma dove ...' is `No house, instead, in Rome
  where ...' now, the adverb set off by its commas kept there by this sample's rule (the gap writer's, its arm red in
  that section too), and the expectation is the new text in test/translate.pl and in lesson 46; and its scan of the
  vocabularies found `centro ricerca', a masculine noun in `-a' whose denial was missing, which the writer would have
  written `la centro ricerca': `"centro ricerca" is not feminine.' is in, and KB304 is taught with it (KB303 without it
  read every sentence of the controls alike, with either translator).
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT: the one store's largest rise is one sentence, the child-cost
  report's nineteenth (`E un'esigenza sentita da tutti quelli che lavorano alla costruzione di accordi tra ex coniugi
  (mediatori, avvocati, i genitori stessi) ai quali serve un punto di riferimento oggettivo e uniforme', it_10011_10058
  19), +1.67 million inferences of 4.2 in each language (+40 %), its text the same: all of it the guard that a relative
  with its article is no noun (tr_noun/5), which blocks `i quali' as the noun `who' and leaves the reader a longer way
  to the same reading (shorter, `E un'esigenza sentita dai genitori ai quali serve un punto di riferimento' is the
  heading and `to whom ... is needed' with the guard, 0.78 million inferences, and `who' and the verb `serves' without
  it, 0.48). Asking the guard's cheap test first (a word of two or more) moved nothing, and it stays as written. Over
  twelve sentences of the controls of 0.2 to 0.5 million inferences, six from each language, into English, counted over
  a copy of the library per rule, the first cut rose 6 378 inferences of 4.38 million (+0.146 %), and the hour's part of
  the day was 2 906 of it: the clause crossed the first complement again wherever an adverb followed one. An adverb of
  two words or more and the hour's shape asked first (tr_clock_shape/1, a phrase with its article and no adjectives, or
  two joined) leave the rule 245, and the twelve +0.085 % -- a guard of cost, its arm green; over the controls the cut
  is -0.005 %, every text the same. What is left is the word for `about' after an article (916 of the twelve's), the
  pronoun and its adjective taken apart, a walk of every sentence's words (794), the relative's guard (580) and the
  joined participles (202), no other rule over 80.
  THE STATED COSTS: the relative's guard's 1.67 million inferences in one sentence (above); `"dura" is intransitive.'
  (above); a first meaning that serves the news and not every text -- `foglio' is a sheet (a blade before), Spanish
  `hoja' a leaf and then a sheet, `carico' and `carica' loaded (the noun, a charge, second), `qualunque' ordinary
  (anybody, the pronoun, second) -- and the writers' words: Italian `foglio' and Spanish `hoja' for every sheet (a bed
  sheet was `lenzuolo', a sheet of metal `chapa'), `posta in gioco' and `apuesta' for every stake (a share in a company
  was `partecipazione' and `participación'), `sorta' and `especie' for a sort, `scrutinio' for an assessment and
  `malcontento' for dissatisfaction; `si tratta di' as `it is' has no hand lesson that shows it (the arm is green; the
  controls show three sentences); and the inferences, +0.068 % outside one sentence on the one store, +0.048 % for the
  store alone.
  The report LEAVES, of the 18 into Spanish: `en la sala Enrico Fermi' and `the hall Enrico Fermi' (2: the Enrico Fermi
  hall), English's `the president Luigi Rossi Bernardi enters' and `seated around the big oval table nervously'
  (`nervously' last); `the destined funds' (4: the funds destined); `la partición de las financiaciones' and `the
  partition of the fundings' (5: the sharing out of the funds); English `still taller than usual' (7: higher); `Están
  los datos ... en el carrito' and `There are the data relative to all the institutes ... on the trolley' (11: the
  phrase set in front written last, `hay', and English's data relating to them); `la ciencia italiana' and `the Italian
  science' (12: Italian science); `que se concentra' and `the presents' (13: Spanish's cleft wants `donde', English
  those present); `¿Los fondos ochenta y cinco serán distribuidos ... en esas hojas realmente?' and `Will the
  eighty-five funds be really distributed' (14: `realmente' written last, the funds of '85, and English's `really be');
  `Pero damos un paso atrás' and `But we take a step back' (15: `facciamo' is the exhortation, `demos', let us take);
  `exactly October 31, 1984 when' (16: on), `el hospital mayor de Milán' and `the biggest hospital of Milan' (the
  Ospedale Maggiore, a name) and `the speech of the crown' (the inaugural speech); `insatisfacción para el estado' (17:
  `por') and `hacer gritar a la renovación' (`gridare al rinnovamento', to cry out for renewal, an idiom). The next
  sample's controls take this report in.
  The Air Europa report (AnCora CESS-CAST-P-20000401-85, 19 sentences, the paper's report on an aeroplane seven hours
  late at El Prat, Spanish into Italian and English: 19 of 19 and 19 of 19 on a fresh store, 18 and 17 with the new
  store alone, 6 and 11 with the new code on the old store, 6 and 11 before; reasoning 1.0.34). The sample was taken
  on the cocolog 3.62.0 binary, master's d4b5564 fast-forwarded onto the branch, and cocolog stays 3.62.0; master's
  ed4e4ed (cocolog 3.62.1, the green world reviewed) came during the sample, changes nothing under
  library/reasoning/, and is not merged: the next sample takes it. THE BOX WAS RESET BEFORE THIS SAMPLE, and the
  controls were made again from their sources (the AnCora documents and VIT ranges of UD's es_ancora and it_vit, and
  every (length/400)th Spanish sentence of 3 to 8 words of manythings' spa.txt): 132 count files, 3 498 sentences,
  with the CNR report in, so no count below compares with the CNR sample's, and the baseline is the committed library
  (reasoning 1.0.33) on a store taught from the committed vocabulary. THE BINARIES OF 3.33.0 AND 3.62.0 give the same
  texts on these controls (0 differ) and 3.62.0 counts 0.174 % fewer inferences (6 747 835 285 to 6 736 088 337); a
  store 3.33.0 taught reads the same to the unit on 3.62.0 as one 3.62.0 taught, and 3.33.0 cannot read a store
  3.62.0 taught (3.35.0 writes an atom past ASCII bare, which 3.33.0's reader refuses). The article's sentences fall
  from 26.5 million inferences into Italian and 26.3 into English to 22.0 and 21.6.
  It needed these SHAPES, each with its arm red (test/translate.pl's `newspaper_air': 44 checks, 49 arms, 48 red and
  one that makes the section raise; an arm is a library directory of symlinks whose reasoning/translate.pl is the
  edited copy, `COCOLOG_LIBRARY=ARM cocolog query "use_module('test/translate.pl'), newspaper_air, checks_done"', a
  second a run, and every arm is run in two minutes, four at a time): A CODE WITH DIGITS IN IT IS NO NAME'S FIRST WORD
  (`el vuelo UX-9482 de Air Europa' is Air Europa's flight, and joined it was one name, `UX-9482 de Air Europa', with
  its `de' untranslated: tr_particle_names/4), and WHAT IS ON A FLIGHT OR A VEHICLE ONE TRAVELS IN, WITH ITS
  DETERMINER, IS ON IT (`in the flight', `in the train': tr_comp_out/7, en_on_vehicle/1), a vehicle with no determiner
  never (`andar en tren' is by train) and a plane never, which a film's shot is too (`elementos contemporáneos que se
  cuelan en el plano', found by the controls) -- four arms; A VERB WITH A SPAN OF TIME AND AN OBJECT CROSSES BY THE
  MEANING THE LESSON GIVES IT THERE (`Un centenar de pasajeros esperó siete horas la salida de un avión averiado'
  waited for it, where `espera' is `expects' first, and `expected seven hours the departure' was written: `The durative
  verb "espera" means "waits for".', tr_mean_links/3, tr_verb_across/5), the source's span asked by its noun's
  meaning, as the verb crosses before its complements do (tr_span_source/1), and English writes the span after the
  object and its phrases of `of', with `for' (`waited for the departure of a damaged aeroplane for seven hours':
  tr_comps_out/7), and a span the source put after the object takes its `for' there, `a couple of hours' among the
  spans (`aguantaron con estoicismo su mala suerte un par de horas', tr_span_np/1) -- six arms; A NOUN OF A ROUND
  COUNT BEFORE `de' AND A BARE PLURAL IS ABOUT THAT MANY (`Un centenar de pasajeros' was `A hundred of passengers' with
  the singular verb, `una veintena de viajeros' `a twenty of travellers': tr_cross_np/2, en_round_count/1, as
  `unos cien pasajeros' is, adv_num/2), with the article in English (`about a hundred', tr_num_out/3), after `the' the
  count itself, an object too (`esgrimiendo el centenar de reclamaciones cursadas por el pasaje' is the hundred
  complaints: tr_cross_comps/2, tr_count_head/4 for the participle after the plural's noun), a clause joined after it
  with nobody named the plural's (`una veintena de viajeros rodeó a una azafata y estuvo a punto de lincharla' WERE on
  the verge, and with the singular English refused the clause: tr_count_gap/3), and `almost' before it says how many
  in its place, after the verb and inside the phrase of a preposition (`se compone de casi un millar de sellos
  discográficos' is of almost a thousand record labels, where the count's own word wrote `almost about a thousand',
  found by the controls: tr_cross_comps/2, each clause asking the count's shape before it crosses the adverb) -- eight
  arms; A TIME IN DIGITS AND THE NOUN FOR HOURS AFTER IT ARE THE HOUR (`despegar ayer a las 11.10 horas' took off at
  11.10, and it was `to the 11.10 hours' and `alle 11.10 ore': tr_cross_np/2), and an hour after a preposition of time
  takes no article in English, with the part of the day after it (`el avión no partió hasta después de las seis de la
  tarde' did not depart until after six in the afternoon, where it was `until after the six of the afternoon':
  tr_comp_out/7, en_clock_preposition/1, en_clock_pp/1) -- three arms; A GROUP NOUN THAT DOES SOMETHING IS THE PEOPLE
  IT IS (`el pasaje destiló tanta indignación' is the passengers, and it was `the passage distilled': `The collective
  noun "pasaje" means "passengers".', tr_mean_links/3, tr_cross_np/2), the subject of a verb that is no reflexive, the
  agent of a participle (`reclamaciones cursadas por el pasaje', by/1) and a share of such a subject (`Parte del
  pasaje volaba por placer' was refused, `parte' read as the verb, departs: tr_part_of_group/1, tr_read_generic/4),
  the doer told to the crossing as it goes in and put back as it comes out ('$tr_doer', tr_as_doer/1,
  tr_as_doer_not/1), and never an object, the subject of a reflexive verb, which is a passive, the phrase of `of' of a
  subject that does something (`el perro del pasaje') nor a complement of a clause in such a subject -- ten arms; A
  CLAUSE OF `que' AFTER A PHRASE OF `so much' OR `so many' IS WHAT CAME OF IT (`el pasaje destiló tanta indignación que
  se amotinó' is so much indignation that THEY mutinied, and read as a relative clause on the indignation it was
  `that mutinied': tr_result_clause/4, res/2), English naming the clause's subject the lesson's languages leave out,
  `he' for a person, `it' for a thing -- two arms; A CLAUSE WITH NOBODY NAMED AND TWO OBJECTS, A THING AND THEN A DOER,
  HAS THE DOER FOR ITS SUBJECT (`Los ánimos se calmaron cuando cruzó la puerta de embarque número 24 una patrulla' --
  a patrol crossed the gate, and read as two objects English refused the clause: tr_vos_subject/2, tr_thing_head/2,
  tr_doer_head/2, `"patrulla" is a group.'), the thing's head through its phrases and its number, and a second phrase
  that is no doer the object still (a guard) -- three arms; A NOUN, THE WORD FOR `number' AND DIGITS ARE THE NOUN AND
  ITS NUMBER (`la puerta de embarque número 24' had its digits left a phrase of their own, and the sentence was
  refused: tr_np/3, app/3's numbered, each writer its own word for the number), asked where the sentence has the word
  for `number' with digits after it ('$tr_numbered', tr_numbered_note/1, a guard of cost whose arm stays green, below)
  -- three arms; THE SECOND `ni' OF TWO CLAUSES IS `nor' IN ENGLISH (`Así que ni se cerró el suculento trato ni la
  testigo entregó los anillos' was `neither the witness handed': tr_write/4, tr_opens_neither/1), where the first
  clause opens on its own `neither' and where the first `ni' stands before both -- two arms; A QUOTATION THAT CLOSES
  ON A VERB GROUP AND ITS OBJECT PRONOUNS CLOSES AFTER THEM IN ENGLISH (`"No es la primera vez que Air Europa me toma
  el pelo"' was `fools" me': tr_write/4, tr_vqc_mark/3); A SENTENCE THE SOURCE BEGINS IN SMALL LETTERS WITH A VERB OF
  SAYING IS NO COMMAND (`"¿Por Qué AENA no hace nada en estos casos?", pregunta Camp' is Camp asking, and the present
  `pregunta' read as the command it is too, `Ask Camp': tr_into_ir/4, '$tr_small_head', tr_small_head_note/2), asked
  of the words as the source wrote them, before the capital of a sentence's first word is taken off, in both ways a
  sentence is read (tr_read_ir/5, and the page's tr_each/3), of a verb of saying alone (`"mettiamola la così: noi
  crediamo ...', the treebank's own sentence in small letters, is the command it was, a guard the controls found) --
  five arms; `makes' with nothing made is `does' in a question that asks why, when, where or how too (`"¿Por Qué AENA no
  hace nada ...?"' was `not make anything': tr_makes_does/3); and `takes off' governs `from' (`despegar ... de
  Barcelona', en_governs/2). A clause for a thing the reader made the subject, with the doer after it among its
  complements, had an arm that stayed green on the section and on the store, the clause with nobody named reading the
  article's sentence, and is gone.
  It needed these WORDS in `extra/' (the two readers: a line moves the reader of one language and the writer of the
  other; the dictionary's own word is said again first where it must stay the one written): Spanish `espera' (expects
  said again first, and waits for with a span: the durative class, new here), `despega' (takes off, an English verb of
  two words the builder takes from no entry, with its forms, intransitive, `de' before the phrase), `asegura' (ensures
  said again first, and assures before a clause), `azafata' (a flight attendant, a person), `veintena' (twenty),
  `cabreo' (anger, `rabia' said again first), `presa de' (in the grip of), `verbalmente', `avería' (a breakdown,
  before the failure), `envía' said again first and `manda' (sends), the name `Palma de Mallorca', `rumbo a' (bound
  for), `puerta de embarque' (a boarding gate), `a cambio' (in return), `"patrulla" is a group.', `así que' (so),
  `hasta después de' (until after), `mal tiempo' (bad weather), `pasaje' (a passage said again first, and the
  passengers, its collective meaning, the collective class new here, and a group), `reclamación' (a complaint, then a
  claim; `queja' said again first, and `entrega' hands, then submits), `millonario' and `millonaria' (multimillion),
  `"masa" is a person.', `toma el pelo' (fools, with its forms), `agua la fiesta' (spoils the party, with its forms),
  the intransitive `tarda' (is late), `"cierra" takes the passive.', the name `Baleares' and the determiner `un par de'
  (a couple of); Italian `aereo' (an aeroplane: no Italian word meant one), `passeggero' (a passenger, where the
  writer's word was a cruise passenger, `crocierista'), `anello' (a ring), `guasto' (a breakdown), `hostess' (a flight
  attendant, a person, its own plural), `ventina', `in preda a', `alla volta di', `porta d'imbarco', `in cambio',
  `"pattuglia" is a group.', `considerevole' (considerable: the dictionary's `considerabile' is no word, and has no
  plural), `matrimonio' (marriage said again first, and a wedding: the dictionary's `nozze' says no number, and the
  writer wrote `un nozze'), `fino a dopo', `maltempo', `reclamo' (a complaint), `milionario' and `milionaria', `"massa"
  is a person.', `prende in giro' (fools, with its forms), `guasta la festa' (with its forms), the intransitive `tarda',
  `"chiude" takes the passive.', `un paio di', `decolla' (takes off, with its forms, intransitive, `da' before the
  phrase) and `attende' (expects, and waits for with a span); and in the dictionaries' extras, for Italian `lynch'
  (`linciare'), `mutiny' (`ammutinare') and `reposition' (`ricollocare'), and for Spanish `lynch' (`linchar'),
  `mutiny' (`amotinar') and, read only, `submit' (`cursar') and `shout' (`vociferar'). The first meaning moved for 6
  Spanish words and 5 Italian ones (Spanish `avería' a breakdown, `manda' sends, `millonario' and `millonaria'
  multimillion, `reclamación' a complaint, `tarda' is late; Italian `aereo' an aeroplane, where it was an airplane,
  `milionario' and `milionaria' multimillion, `reclamo' a complaint, `tarda' is late), the writer's first word for 1
  Spanish meaning and 5 Italian ones (Spanish breakdown `avería', where it was `desglose'; Italian complaint `reclamo',
  where it was `denuncia', considerable `considerevole', passenger `passeggero', ring `anello', where it was
  `anellino', wedding `matrimonio'), and none was lost.
  THE CONTROLS (cocolog 3.62.0, store KB_a4, 132 count files, 3 498 sentences: the earlier set with the CNR report in,
  it_4883_4900, both directions; this report is not among them): the last version's translator against this one, on
  the one store, 3 sentences in 3 files read differently, all better -- `almost a thousand record labels' and `quasi
  mille etichette discografiche' (es_20010103-139 14, where they were `almost a thousand of' and `quasi un migliaio
  d'') and Tatoeba's `You are on the mistaken train' -- and the inferences rise 0.033 % (6 736 866 187 to 6 739 058
  634), the largest rises the Venice report's eighth (+14 463 of 251.3 million) and the Rognoni interview's nineteenth
  (+9 586 of 176.4, refused both ways). Bytes and characters read every sentence alike (0 differ, the bytes 0.014 %
  more). The DATA COLUMN (the last version's translator on its own store against this one on the new): 17 sentences in
  14 files, all better but the two of `tardar' below, no worse, +0.044 % (6 736 088 337 to 6 739 058 634), and 3 114
  read in both. THE CODE ALONE (this translator on the old store): the same 3 sentences, +0.033 % (to 6 738 286 465).
  THE STORE ALONE (the last version's translator on the old store and on the new): 14 sentences in 11 files, +0.012 %
  (to 6 736 866 187), each a word of the report's lines -- `assured' for `aseguró que' (6, where it was `ensured'), `a
  couple of' (2: `shattered a couple of years after', `a couple of counters', where it was `a pair of'), `anelli' (2:
  `il signore degli anelli', `la comunità dell'anello', where it was `anellini'), `multimillion bribes', `tardato' and
  `have been late' for `han tardado' (where it was `preso' and `taken', no better and no worse: `tardar en' with `más
  que nosotros' between is `took longer'), and Italian's `reclamo' for a complaint (`I reclami civici', `Il suo
  principale reclamo', where it was `denuncia').
  THE FIRST ROUNDS' REGRESSIONS, found by reading the texts of every column and mended, each with its arm red. Of the
  code: the rule for a sentence in small letters first asked the words after the capital of a sentence's first word
  was taken off, so it held for every sentence, and every command of the controls was refused (3 114 read to 3 077:
  `Compare the own ones with analogous compiled charts', `Apply several statistical correctives', `If I err correct
  me', `Therefore be consistent', `Let us talk again it among a year', `Give the impression that they wish ETA to
  act', and the islands report's `Assicura il sindaco Costantino Federico ...' refused into English), and asked of any
  word it refused the treebank's own sentence in small letters, `"mettiamola la così: noi crediamo al
  presidenzialismo ...' (it_9714_9749 28, both languages); the vehicles took the film's shot, `que se cuelan en el
  plano' (`sneak on the plane', es_20020102-112 1); and the count wrote `almost about a thousand' (es_20010103-139 14,
  both languages). Of the store: `cabreo' became the Spanish writer's word for anger, `reclamación' for a complaint
  and `cursar' for submits -- the dictionary's `entregar' for submits is an entry read only from English (r="LR"),
  and with a line for submits from `cursar' the builder wrote it no more -- and the dictionary's words are said again
  first now.
  THE COST OF THE CODE, FOUND BY TAKING EACH RULE OUT (23 sentences of the controls into English, the four heaviest
  Italian risers of the first round and 19 picked at random of 0.1 to 2 million inferences, over a copy of the library
  per rule on the new store): the first cut rose 250 090 inferences of 145.5 million (+0.172 %), and one rule was 91 %
  of it, the noun and its number, whose clause of tr_np/3 walked every phrase it was asked with append/3 (226 486); its
  last word asked first with last/2 saved nothing measurable, the clause being entered at each phrase, and a note
  made once a sentence ('$tr_numbered') leaves +27 290 (+0.019 %), the note's own walk 11 193 of it, the doer told to
  the crossing 1 372, the group's crossing 943, the doer put out of an infinitive's complements 568, the swap of a
  thing and a doer 692, `almost' 402 (each clause asked the adverb's meaning before the count's shape, 7 657), no
  other rule over 300. The note's arm, always yes, is +249 255 and green on the section, a guard of cost. Over the
  controls the code alone is +0.033 %.
  THE STATED COSTS: a first meaning that serves the news and not every text -- `avería' is a breakdown (a failure
  second), `manda' sends (commands second), `millonario' multimillion (a millionaire second), `reclamación' and
  `reclamo' a complaint (a claim second), `tarda' is late (takes second) -- and the writers' `avería' for a breakdown
  (`desglose', a breakdown of figures, before) and Italian's `reclamo' for a complaint (`denuncia' before);
  `pasaje' is a group now, so the Inter feature's doer rule reads `El perro que ve el pasaje duerme' as the dog that
  the passengers see; the store's lines cost three sentences of the controls a reading for nothing, the texts the same
  (it_9763_9774 10, +73 374 of 3.12 million, es_19991202-35 6, +46 556 of 0.27, Tatoeba's 383, +21 493 of 0.20); and
  the inferences, +0.033 % on the one store and +0.012 % for the store alone.
  The report LEAVES, of the 19 into Italian (English alike unless it says): `trattamenti milionari' and `multimillion
  treatments' (3: `tratos' are deals) and `pretendevano chiudere' (`intendevano'); `In preda al nervosismo e della
  rabbia' (10: the second phrase of a preposition of several words keeps the `of' it was read with, `alla rabbia');
  `Gli incoraggiamenti' and `The encouragements' (11: `Los ánimos' are tempers), `con la sua sola presenza' and `with
  his alone presence' (its mere presence) and `che placò le masse' after `guardie civili' (the relative clause hangs
  on the patrol); `il danno era fatto' is right, and English writes `the damage was made' (12: done); `ebbero in mano'
  and `held' for `aguantaron' (7: endured), `con stoicismo' before the object; `si credettero dopo che bisognasse
  pulire l'aereo' (8: `credettero', the reflexive of `creerse' kept, and `poi'); `difese Hidalgo' and `Hidalgo
  defended' (17: argued) and `senza lei' and `without her' (the piece: `senza di esso', the pronoun of a thing written
  as a woman's); `il pezzo che modificava il fallimento' and `the piece that amended the failure' (16: that fixed the
  fault); `"Perché non
  fa AENA niente in questi casi?" Chiede Camp.' (19: `Perché AENA non fa niente', the subject after the verb, and the
  reporting clause's comma and small letter lost); and English writes `yesterday' last (2, 18). The next sample's
  controls take this report in.

## Tutorials are documentation that runs

`tutorials/` holds 133 files -- `basics/` 13, `library/` 55, `opencv/` 23,
`tensor/` 42 -- and `test/tutorials.pl` runs them all (300 s a lesson, 600 s
for opencv, 900 s for `library/45-tagger`). **Every claim is a `must/3`**,
repeated at the bottom of each file so a lesson can be copied anywhere; a
lesson that stops being true FAILS, naming both answers. **A lesson's last
line is exactly `done`.** Lesson 46's `main/0` once grew past a page
(cocolint Z1): move sections into predicates of their own.

## macOS

The whole family builds on a Mac; each of these fails naming something other
than its cause:

* **Shared objects and test binaries leave interpreter symbols undefined**:
  `tools/cc` adds `-Wl,-undefined,dynamic_lookup` to every Darwin link, and
  `COCO_WEAK`/`CE_WEAK` are `weak_import`.
* **No makefile names a Homebrew path** (here or in ZiguratIP), and Apple's
  clang searches `/usr/local` -- Homebrew's prefix on an Intel Mac -- but not
  `/opt/homebrew`, Apple silicon's; `openssl@3` is keg-only on both. So
  `install/install-macos.sh` exports `CPATH` and `LIBRARY_PATH` (openssl@3's
  include and lib, then the prefix's) for its builds and prints them with its
  other exports: a later `make` or `make test` wants them in the shell
  (2026-10-29; before, an Apple silicon Mac found no `openssl/ssl.h`).
* **There is no `timeout`**, which several cases run a child under: CI gives
  the Mac coreutils' `gtimeout` under that one name, and leaves BSD `date`,
  `wc` and `sed` as they are.
* **There is no `/proc/self/exe`**: `lb_exedir` asks `_NSGetExecutablePath`;
  programs read `current_prolog_flag(executable, P)`.
* **`make schema` builds as it stands on Apple clang 17 and 21** (macos-15
  and macos-26-intel, CI, 2026-10-29: 38 objects, no flag): nothing in
  either tree names `std::binary_function` now. It once died in libc++,
  which removes that name under C++17. Were that back: copy the home config, add
  `-D_LIBCPP_ENABLE_CXX17_REMOVED_BINARY_FUNCTION` to `CPP_FLAGS`, run
  `ZIGURATIP_CONF=that-file make schema`.
* **A raylib photograph is one frame behind**: draw a frame twice before a
  screenshot or a pixel read. **A sleeping screen opens no window**
  (`GLFW: Failed to determine Monitor`); `test/ray.pl` probes and SKIPs;
  `caffeinate -u` wakes it.
* **XQuartz ships XTEST off**: `defaults write org.x.X11
  enable_test_extensions -boolean true`, restart X11.
* **Ask `library(os)`, not a shell** (`os_is/1`, `os_has/1`,
  `os_lib_path_var/1`, `os_tmp/1`, `os_cpus/1`). No `setsid`, BSD `date`
  has no `%N`, BSD `wc` pads, BSD `sed` ignores `\|`.
* **Darwin's `clock_gettime(CLOCK_MONOTONIC)` is a MICROSECOND clock**
  (96.6 % of a million back-to-back readings repeat): every engine step
  under 1 us read 0 and a retry's few hundred nanoseconds none, so
  `test/window.pl` and `test/flowdebug.pl` were red on every fast step.
  `coco_clock_ns` uses `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)` there
  (2.5.1); Linux keeps the vDSO's `CLOCK_MONOTONIC`. **On Apple silicon
  that clock moves in ticks of 41.67 ns** (24 MHz), so a step shorter than
  a tick can still read 0: test/window.pl takes an inference as unread only
  when it reads 0 in each of five runs (`w_clock_zeros/6`, run
  40950413465).
* A server's READY line comes ~1.4 s before its port opens, and a page that
  warms a store is ~4x slower than on the Linux box.

## Where things are

| path | what |
|---|---|
| `cocolog.cicili` | the composition root: CLI, options, the version |
| `lib/term.cicili`, `term-walk` | cells, the machine, text, names and the heap; `term-walk` binding, the trail, unification, copying, cycles and the standard order |
| `lib/syntax.cicili` | the reader and the writer, one operator table plus `op/3`'s |
| `lib/kb.cicili`, `kb-compile`, `kb-pred`, `kb-consult` | the clause store and its five backend hooks (`fetch`, `on_assert`, `on_retract`, `on_dynamic`, `warm`); `kb-compile` compiled clauses, the guards and the environments; `kb-pred` compaction, predicates, the indexes and the update view; `kb-consult` a re-read's order, assert, consult and retract |
| `lib/solve.cicili`, `solve-journal`, `solve-control`, `solve-gc`, `solve-loop`, `solve-arith`, `solve-text`, `solve-db` | the engine: the builtin table, its vocabulary, every declaration, the recorder and the clocks; `solve-journal` the journal; `solve-control` the continuation, choice points, clause selection, throwing and error text; `solve-gc` the heap collector; `solve-loop` the loop; `solve-arith` unification, type tests and arithmetic; `solve-text` terms built and taken apart and text; `solve-db` output, the database, listing and the dispatcher |
| `lib/module.cicili`, `lib/sdk.cicili` | the module seam and the SDK an out-of-tree module is written against |
| `lib/library.cicili` | `use_module`, the library path, directive goals |
| `lib/builtins.cicili`, `builtins-format`, `builtins-db`, `lists`, `apply`, `files`, `dcg`, `state` | tier-1 modules (`files` has `get_time/1` and, since 3.8.0, `sleep/1`; builtins keeps its table and Prolog half first, format and character classes in `builtins-format`, its dispatcher last in `builtins-db`) |
| `lib/zigurat-kb.cicili`, `lib/zeytun-kb.cicili` | the binary-protocol and HTTP backends |
| `lib/swipl/` | SWI's vendored libraries -- do not edit |
| `client/` | pure C wire client; `client/tls.c` the one TLS unit |
| `embed/` | the embedded store, part of the binary |
| `parsi/` | schema, procedures and pages compiled into a ZiguratIP home |
| `modules/` | the nineteen loadable modules |
| `library/` | tier-2 Prolog libraries and the built `.so` files |
| `tools/cocolint/` | the dialect linter (`lint.sh FILE.pl`), its card (`traps.jsonl`, citations checked with `tool.sh card --check`), the retrieval index (`tool.sh index`), the oracle |
| `tools/cc/` | the compiler wrappers |
| `tools/cloud/` | `docker-build.sh`: the Docker images on a Claude Code session's Linux box |
| `tools/ci/`, `.github/workflows/` | `verdict.sh`: the suite's verdict on a CI runner (`ci.yml` runs it); `docker-image.yml`: a release's images, by hand |
| `tools/flow/` | `chart.pl` (a flowchart from a shell: `cocolog -s tools/flow/chart.pl -- SPEC FILE BASE`, exit 0/1/2, the findings on stdout as `FILE:LINE:COL: error: ...`), `tables.pl` and `build.sh` (library(flow/chart)'s tables, by `make modules`), `zero.sh` (the untraced engine's instructions on nrev, queens and lookup, a binary beside a binary, the jump padding apart), `debug.pl` (what a query did, from a shell: `cocolog -s tools/flow/debug.pl -- GOAL FILE BASE`, exit 0/1/2, a line on stdout of how the run ended); DESIGN-flow.md is the plan |
| `tools/compile/` | `static.pl`: which predicates' clauses nothing changes while a program runs, and what each call reaches -- DESIGN-compiling.md §7's count (`test/static.pl`) |
| `test/` | the suite: `run.pl`, `prelude.pl`, the cases and their fixtures |
| `tutorials/` | the lessons |
| `bench/` | cocolog against CPython and SWI-Prolog (`sh bench/langs.sh`; SWI with `-O` and as installed, run on the same `.pl` files), moved from The Coco; the runs kept start at 1.8.48 (A-L are in `f544cca`); `test/langs.pl` guards its pairs. And the concurrency benchmark (`sh bench/concurrency.sh`): real threads, green threads, Go goroutines, Rust threads and Python asyncio on the spin workload, the light spawn/switch lanes, and the one-core real lane under `taskset`; answer-gated, the first run of each lane thrown away. `library/async/README.md` has the model, the numbers and the shared-heap design note. And the token benchmark (`cocolog -s bench/tokens.pl -- check|size|replay DIR|run|report FILE`; bench/tokens/README.md): the tokens and dollars a model spends to get ten programs right in cocolog and in Python, write-test-fix rounds of an append-only conversation, three arms (python, cocolog, cocolog with the dialect card), no fallback model unless `fallbacks=default`; a live run wants ANTHROPIC_API_KEY and runs what the model wrote; `test/tokens.pl` holds the harness without a key (the references on every case, a replay end to end, the request) |

**A feature that touches the knowledge base must consider all three
arrangements**: local (no hooks), Zigurat (all five hooks), Zeytun (`fetch`
and `warm` only -- one HTTP request is one transaction).
