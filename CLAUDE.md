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
  github CI when i ask", and again the same day, "Do not run github CI
  after each change"): start no run by hand and watch none. `ci.yml`
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
the default**: bump it for every change to the binary or to a library, in the
same commit, never afterwards. A minor (something new reachable from a
program) or a major (a program that worked stopping) is PROPOSED with what
changed observably, **and the owner's rule of 2026-10-20 is that the
version proposed is USED** -- set it in the source and commit it with the
change; do not wait for a separate answer. **A documentation-only commit does
not bump** (there is no new binary for the number to describe); say "cocolog
stays X.Y.Z" in its message. `--help` goes to stderr. `test/argv.pl` pins the
shape of the answer, deliberately not the number.

**Two lines of work bump the same number**: before a bump, `git fetch` and
read `git show origin/master:cocolog.cicili | grep coco_version_text`; a bump
taken from the local value is a guess about where the other line has got to.
A merged tree that holds both lines' changes takes a number neither had.

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
* **An inference count moves with where the binary stands too** (3.62.3):
  a program that takes the executable's path apart counts its components.
  a library's library-path walk does, with append/3, an inference a
  component each time it is asked: one program counted 3 458 375 from the
  checkout and 3 458 381 from a copy three directories deeper, another
  counted three more -- on one binary. Two binaries' inferences are
  compared from paths of one depth, where 3.62.2 and 3.62.3 count the
  second alike, 245 746 056.
* **A process's speed can depend on where the kernel loads it.** 2.14.1's
  counting loop runs about 30 % slower whenever the binary's base has
  address bits 12 and 13 both set -- one load in four, 60 runs of 60 sorted
  by that alone -- and 2.2.5's does not (bench/README.md, Run Z). That was
  the 2.80 GHz Cascade Lake: on the 2.10 GHz Emerald Rapids neither 2.14.1
  nor 3.62.3 has it, 40 runs each (Run AA). Two single runs can land in
  different modes: look at twenty runs of each build for two clusters
  before reading a pair, or time both with `setarch -R`, which fixes one
  layout for each (a placement of its own, to be named).
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
and `library/flow/`: `flow/chart` and
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
  the store is a database of terms as well as a program, so a library may
  store word classes such as `number(dos)` and read them with `clause/2`
  (refusing it stopped such a library's tests).
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
  tree loads with no warning**: a variable a
  clause never uses is `_`, and one it uses twice is named plainly, never
  `_X` -- the walk found a check in test/template.pl that tested nothing.
  **A predicate's clauses stand together**: a change moved 159 blocks of a
  library's clause file up to their predicate's first clause, each
  predicate's clauses in their order, which a dump of every clause before
  and after holds equal; a helper goes after the predicate whose clause calls it,
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
  (msort/2 a file took over, and the facts a library asserts
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
  it is given asks `coco-l-too-long` first** (3.42.3; the macro is
  lib/term.cicili's since 3.62.2: lib/lists.cicili's nth0/3's and nth1/3's
  tail, length/2's, numlist/3's, and lib/files.cicili's
  read_file_to_codes/2): cells whose bytes
  alone pass the limit raise resource_error(stack) before one is built, as
  swipl's length/2 does -- a growth past the limit is given and stops the
  engine only at its next step, so a C loop never sees it, and
  `length(L, 10^12)` built until the kernel killed the process.
  **read_file_to_codes/2 has no ceiling of its own** (3.62.2; through
  3.62.1 a file past 16 MiB FAILED, as a missing file does, and a program
  that read 21 MB was told nothing): a file's codes are a list, asked of
  the limit before the read by its bytes (a quarter of them under
  characters, a character being four bytes at most) and by the count once
  they are read; a buffer refused is resource_error(memory); a missing
  file, a directory and a read cut short fail still. **The list is built
  where it stands**: three cells a code -- the list cell, the code in its
  first argument, a reference to the next cell in its second -- reserved
  in one growth and written front to back, so the text is decoded as it
  is read (no array of code points first, `coco_text_list`'s eight bytes
  a byte) and 1 GB holds the 44 million codes `coco-l-too-long` says it
  does. `coco_m_cons` over `coco_new_int` is FOUR cells an element, the
  integer a cell of its own that the list cell refers to: what every
  other row that builds a list of numbers still costs (numlist/3,
  atom_codes/2), a quarter more than the macro counts. An integer in an
  argument's own cell is what a `'$k'` frame's barrier always was; the
  walks reach it by `coco_deref` of the slot as they reach any argument
  (the case's children under COCOLOG_GC_CELLS and COCOLOG_KMAT hold a list
  so built to one consed the usual way). test/errors.pl's
  `file_no_ceiling`.
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
* **A machine refused memory outright is FINISHED, and its engine stops**
  (3.62.3; STATUS.md). `coco_oom` (lib/term.cicili, cold) sets `oom` AND
  stops the engine running on the machine (`haltp`, 2), whose next step
  raises nothing: the run ends `out of memory`. Through 3.62.2 a mark was
  the flag alone and the engine ran on -- on a trail that undid nothing,
  over a goal built on cell 0 -- until a builder of its continuation
  happened to find no room. **Every mark of a machine goes through
  `coco_oom`, never `(set (-> m oom) 1)`** (the store's own `st->oom` and
  the recorder's `r->oom` still stop nothing). What stands on it:
  - **A put is all of its term or none** (`coco_store_put`): a compound's
    header and slots are reserved in one growth, a refusal leaves no
    frame, and the put's end winds the store back to where it began,
    finishes the machine and answers a cell that is not there
    (`coco_store_put_short`). **A caller that reads its cell back, or
    links it where others read, in the same step asks
    `coco_store_put_refused` first** (a throw, findall/3, assertz/1,
    nb_setval/2) -- of the MACHINE, never of the store's length, which in
    a green world another task has moved by then.
  - **A variable the map has no room for is a loss the map keeps**
    (`lost`), and `coco_varmap_give` finishes the machine for it: entered
    again at its next occurrence, `f(X, X)` came out `f(A, B)` of a copy,
    of a store's read and of findall/3. The clause compiler takes no
    clause whose variables the map lost (`cc_var`), takes the map's word
    back, and the clause is matched in the store and copied, as any
    clause it cannot take; through 3.62.2 `p(X, X)` ran as `p(_, _)` for
    every call after it.
  - **A machine whose construct mask was refused is finished** (the mask's
    making in lib/solve.cicili): with a mask of no length `!`, `,` and
    `;` were unknown procedures.
  - **A growth refused where its caller would FAIL finishes the machine**:
    a predicate's room for one more clause (`coco_pred_room`: assertz/1
    failed), a unification's and the store matcher's pairs (a clause that
    was there not matched). nb_setval/2 raises resource_error(memory)
    where its table or its hash cannot grow. A new growth whose refusal
    would read as a failure does the same: a goal that fails for want of
    memory takes a program's other branch.
* **A text the buffer had no room for is no text, and a read across a
  refusal is no term** (3.62.3; STATUS.md). A put that is refused leaves a
  `coco_strbuf` as it was and its writer goes on, so the text came out
  short of a piece, and through 3.62.2 was used as it stood: an atom made
  of it, a length taken, a status sent. Nothing in the buffer can say so
  (a module holds its three words), so THE THREAD COUNTS ITS REFUSALS
  (`coco_refused`, lib/term.cicili) and the buffer's growth decides
  (`coco_sb_grow`, cold and out of line; `coco_sb_room` is the test
  alone): a doubling refused asks again for what is needed and a
  sixteenth, and given, the text is whole and the engine running on the
  thread is stopped as any growth given short stops it
  (`coco_refuse_short`: halted 2, the catchable resource_error(memory));
  refused too, `coco_refuse` counts it and FINISHES THE MACHINE RUNNING ON
  THE THREAD (`coco_refuse_m`, which `coco_engine_next` sets around its
  run and puts back after). What a session must keep:
  - **A caller that answers a refusal itself takes the machine away for
    its stretch** (`coco_refuse_take`, `coco_refuse_give`) and reads the
    count before and after (`coco_refusals`): the green world's two
    writers (`coco_g_write`, `coco_g_kind_text`), which answer no text so
    that the task raises resource_error(memory), and
    `coco_read_term_from`. Any other writer leaves the machine where it
    is, and a text short of a piece ends the run.
  - **A caller that fails by its own road counts and no more**
    (`coco_refuse_count`): the reader's `coco_fail` of `out of memory`,
    its variable table (a variable not recorded is a new variable at its
    next occurrence, no term the text says) and a variable name's copy.
  - **A read is all of its term or none**: the reader's three entries
    (`coco_read_clause`, `coco_read_goal`, `coco_read_term_from`) compare
    the thread's count across the parse and fail `out of memory`, and the
    first token of the NEXT term, which the last read's tail has already
    asked, is the reader's `lexref` (`coco_next_first`: **a new site that
    asks the first token of a term asks it there, never
    `coco_next_token`**). The text builtins raise resource_error(memory)
    for such a read (`coco_tx_syntax`), where they said a syntax error.
  - **A request with no smaller one to make finishes the machine on ONE
    refusal**, by design: a scratch `malloc` (`coco_text_list`,
    `coco_new_string`, a name's copy), a walk's stack of pairs or frames
    (`coco_pairs_push`, `coco_su_push`, `coco_cells_push`) and a
    builtin's own array (term_variables/2's). The run ends `out of
    memory`, where atom_codes/2 answered the tail it was given and a
    unification failed.
  - Not done: the writers that persist a text in flight (the store's
    sync in lib/zigurat-kb.cicili, `coco_freeze`, the journal, the seam's
    `coco_m_term_text`) act on it, though the machine is finished at its
    next step; a load goes on past a clause there was no memory to read,
    its ERROR said and the clause left out; library(stream)'s reads say
    a syntax error; the store's and the recorder's marks stop nothing.
* **`test/refuse.c` refuses each allocation in turn** (3.62.3; an
  LD_PRELOAD shim before glibc's allocator, built by test/async.pl's
  `refusals` with the suite's compiler, `-O3`; glibc only). It counts the
  requests a program makes between two marks -- a `getenv` of `REFUSE_ON`
  and one of `REFUSE_OFF`, names nobody sets, which to a run without the
  shim are nothing -- and answers the `REFUSE_N`-th with nothing,
  `REFUSE_RUN` of them in a row (0: every one to the stretch's end), only
  requests of `REFUSE_SIZE` bytes, or of `REFUSE_MIN` bytes or more
  (`REFUSE_MIN=4096 REFUSE_N=1 REFUSE_RUN=0` is a ceiling on what is big
  alone); `REFUSE_REPORT=1` writes the count and `REFUSE_BT=1` the
  backtrace of the request refused. A fixture is run once to count and
  then once for EVERY request it made. What bites:
  - **One refusal never refuses a growth of the machine's arrays, the
    store's or a buffer** (a buffer since 3.62.3): each asks again for
    less and is given it. Two in a row is the growth refused outright, the
    state a real shortage leaves: a sweep is run at both, and the first
    sweeps of one refusal came back clean of every fault two in a row then
    found. A walk's stack and a builtin's scratch ask once (above).
  - **Three and four in a row are states of their own**: three is a cell
    the store refused and then a growth given short after it (the put is
    still none of its term: `memreq` keeps the refusal), four a text
    refused its read and the error named in its place refused its read
    too (a buffer's two requests each), where nothing can be put in a
    status cell. test/async.pl has a row of each: the arms that let the
    second refusal pass unasked were green at one and at two.
  - **An uncaught error under `cocolog run FILE main` is exit 2 with
    nothing on stdout**, which is how a host out of memory ends and what
    a sweep accepts: a fixture's own checks are wrapped in catch/3 and
    print what they found, or a check that raised is a pass.
  - **A world hides what a host's own run shows**: the world's loop asks
    a task's machine for `oom` when its run is back (`coco_g_run`) and
    ends the task with the memory status whatever its engine did after
    the mark, so a rule of the form "mark AND stop" is red only in a
    fixture the HOST runs (`cocolog run FILE main`: test/async.pl's
    `fx_host`), where an engine that ran on says `failed` or dies.
  - **Under `REFUSE_MIN=4096` an engine's first choice frames are a
    page** (64 frames, 4 608 bytes): a fixture that is to refuse a big
    TEXT pushes a choice point in every engine it uses before the mark
    (`bg_warm`), or the page refused is the engine's and the check passes
    by another road.
  - **A ceiling (`ulimit -v`) refuses what is big, and the shim what is
    small**: the thirty-two bytes of a status's copy are never refused by
    a ceiling, a thread's stack never by the shim. A fault of memory wants
    a row of ceilings (which allocation is refused moves with every
    kilobyte) and a sweep of requests.
  - **With one worker the N-th request is the same request in every run**;
    with two a run's verdict is its outcome's kind, never its text.
  - **What a run may do**: print its answer, print `memory` (a task caught
    resource_error(memory) and went on), say the row's own word (`died`:
    the error came out through the world; `deadlock`), or end as a host
    out of memory ends, exit 2 and nothing printed. Anything else is a
    fault: `failed`, `lost` (a world that succeeded and bound nothing),
    `broken` (a store whose clauses are not the ones asserted), `wrong`
    (a status that is another term), a signal.
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
  NOT before the main task exists: the world lock is held from the first
  worker's creation to the main task's). The main is task 0 on worker 0;
  the caller runs worker 0's loop. 1024 tasks and 64 channels a world. A
  result is the goal as
  instantiated, in canonical text; a throw is rethrown by `await/2`; a
  deadlock is raised as resource_error(deadlock) at `async_run/1,2`.
  **THE 3.62.1 REVIEW** found sixteen faults, each with a section of
  test/async.pl red on 3.62.0 (STATUS.md has the table). What a session
  must keep:
  - **The world ends when its main task ends** (`coco_g_end`: the main's
    finish, a deadlock, a task's halt): every worker leaves at its loop's
    TOP -- the acknowledgement of a write in flight first, then
    `main_done`, then the pick -- and says so under the lock (`gone`). A
    task still ready is not run; one inside a nested wait is abandoned
    (`coco_g_abandon`: its engines halted, which `coco_g_run` reads after
    the world's end as nobody's halt). Through 3.62.0 a worker ran its
    ready tasks to the end first, and a task that never ended on the
    main's own worker kept async_run/1 from returning.
  - **A write counts the workers it asks** (`asked`, the op's sequence):
    not one inside a foreign call, not one gone; and **only a counted
    worker's acknowledgement counts** (`coco_g_ack`, the one place an
    acknowledgement is made: the loop's top, a write's own wait, a nested
    wait, the foreign pair). A worker back from a foreign call
    acknowledged a write that never counted it, and the write began under
    a task that had not stopped. **A worker leaving for a foreign call
    answers until no write is in flight** (`coco_g_foreign_begin`'s loop):
    the wait for one write gives the lock up, and the next writer counts a
    worker that has not said it is away -- a deadlock where the call waits
    for that writer (mutex_lock/1 of the mutex it holds).
  - **A task's tables are synced wherever it may have slept through a
    write** (`coco_g_sync_here`: after an acknowledgement made in a
    write's own wait, after a foreign call; the main task's machine is its
    own, not the host's). `coco_intern_h` syncs at every intern, which is
    why most paths never showed it.
  - **The names' lock and generation are a thread's** (`coco_tbl_mx`,
    `coco_tbl_genp`, thread-local; `coco_tbl_set(mx, genp)` by the caller
    and by each worker's loop, `(nil, nil)` by each as it leaves): a
    library(thread) thread beside a world, or a second world in another
    thread, never takes them. **The lock is asked through
    `coco_tbl_lock`, the process's count first** (`coco_tbl_live`, the
    threads whose lock is set, kept by `coco_tbl_set`): every intern asks
    it, and the thread-local alone -- three instructions and two more
    saved registers, a call on Darwin -- cost a start 103 171
    instructions, all in `coco_intern_len` and `coco_functor_id`. **The atom
    buckets are not freed while the tables are shared**
    (`coco_atoms_rehash`), as no table's array is: an intern probes them
    with no lock.
  - **A nested waiter is state 3 from its first line to its last**
    (`coco_g_wait_nested`, the one body of the await's and the channel's
    wait): `coco_g_serve` hands it its text and leaves it 3 -- made
    ready, a deeper wait on the same C stack ran it a second time --,
    `coco_g_live` counts another worker's waiter whose wait is over as
    alive, `coco_g_wait_leave` takes a waiter that gave up out of its
    channel's list, and `coco_g_deadlock` WAKES the nested waiters of a
    world nothing else can move (each asks `coco_g_live` and raises in
    its own task). **A new way to wake a waiter goes through
    `coco_g_serve`; a new blocking builtin sets `resume_cell` on BOTH its
    paths** (the plain send did not: its status went to the task's last
    wait's cell, or heap cell 0) **and waits through
    `coco_g_wait_nested`.**
  - **A task's halt is the process's** (`halt`, `halt_code` on the world,
    handed to the engine that called async_run/1,2, 3.57.0's rule), and a
    world is as wide as the threads it was given (`pthread_create`'s
    refusal ends the count).
  - **Each risky shape in test/async.pl is a CHILD PROCESS with a
    ceiling**: a hang is the usual failure, and it must cost the case a
    red line, not the suite its run. The arms are one build each
    (STATUS.md lists the nineteen).
  **3.62.3: A WORLD SHORT OF MEMORY SAYS SO** (STATUS.md; test/async.pl's
  `ceiling`, `refusals`, `channel_room`, `no_status` and `dead_running`).
  What a session must keep:
  - **A status is never nil, and the nine that never change are nobody's
    to allocate**: `*green-texts*`, one array of literals taken by name
    with `coco-g-text` (a new fixed status is a row of it), told from a
    text somebody owns by its address (`coco_g_text_free`, through which
    every status and resume text is freed). `coco_g_finish` writes
    resource_error(memory) for a status there was no memory to write, and
    a waiter woken by a task's end is handed the mark `awaited`, never a
    copy: it reads the status where the task left it, with the world's
    lock given back. Through 3.62.2 each was a `strdup` at every use, a
    refused one a nil, and an await of a task that had FAILED succeeded.
  - **A text that does not read is the error its reader raises, never
    nothing**: `coco_g_resume` answers 1, 0 (the unify refused) or -1
    (nothing could be put in the cell), and EVERY caller asks the -1 -- a
    builtin through `coco_g_answer`, which raises resource_error(memory),
    and a task that cannot be handed its text ends with it for its status.
    A text written or read across a refusal is none (`coco_g_refused`:
    the machine's `oom` or the thread's count), and a goal read across
    one is not run as it came out.
  - **A message is written ONCE, before the world's lock is taken, and
    read once with the lock given back**: the waiter builds `'$async'(ok,
    T)` around the term it reads (`resume_msg`). A new builtin that hands
    a term to another task writes it before it locks; under the lock a
    write that fails leaves a waiter served nothing.
  - **Everything the world allocates is asked**: a task's machine, its
    engine and its first 64 cells (`coco_machine_init_alias`: an alias
    has a heap cell before anybody pushes), the world's four blocks, a
    channel's buffer (`coco_g_chan_new`; its size is an i64 held to an
    int's, and `channel/2` raises resource_error(memory)), and a write's
    record is the world's own (`op_one`: one write is in flight at a time,
    told from the next by its sequence), no `calloc` at every write. A
    task there was no memory for ends with resource_error(memory) for its
    status, whichever piece was refused.
  - **A stop already asked for at a step is the stop** (`coco_limit_go`,
    lib/solve-loop.cicili): the loop asks the limit before the halt, so a
    task whose receive, send, await or yield was the LAST STEP OF ITS
    QUANTUM had its block (`halted` 128) unread when the quantum ended
    the run. It was made ready, its next run stopped at once on the stale
    128 with nothing to wait for, and that was read as a goal that failed:
    an await of the task failed, and a world whose sender it was went
    dead -- one block in ten thousand of a task that ran its quantum out,
    since 2.8.0, found by an arm that would not go red. test/async.pl's
    `quantum_block` walks each of the four across the boundary. **A new
    stop a green builtin asks for is a value of `halted`**, which the
    quantum now leaves to the halt's own test.
  - **No task ends on a channel's list**: a machine that is finished
    stops before its next step, so it reaches no receive after the mark,
    and a block is a block. A nested waiter that gives up takes itself
    off (`coco_g_wait_leave`).
  - **The world is dead only when no blocked task's worker is still
    inside its run** (`coco_g_deadlock`). A builtin that blocks sets its
    task's state under the lock, and its thread is then on its way out of
    the engine: such a task is its worker's still (`cur`), the check
    passes it by, and that worker asks again when its run is back
    (`coco_g_run`). Through 3.62.2 a worker with nothing to run that
    asked in that moment finished the main task under its own worker --
    its machine freed under a thread still returning through it, `failed`
    written over the deadlock.
  - **library(async) refuses an unbound status by name** (`async_done/2`,
    `async_sent/1`, `async_recv/2`: error(system_error, _)). The engine
    binds a status or raises, so the clauses never fire; they are there
    because every fault above was silent only for as long as the library
    took a variable for an answer.
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

## Tutorials are documentation that runs

`tutorials/` holds 131 files -- `basics/` 13, `library/` 53, `opencv/` 23,
`tensor/` 42 -- and `test/tutorials.pl` runs them all (300 s a lesson, 600 s
for opencv). **Every claim is a `must/3`**,
repeated at the bottom of each file so a lesson can be copied anywhere; a
lesson that stops being true FAILS, naming both answers. **A lesson's last
line is exactly `done`.** A `main/0` that grows past a page (cocolint Z1):
move sections into predicates of their own.

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
