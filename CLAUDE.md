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
  Python appears only as the benchmark's yardstick (`bench/langs.sh`,
  `test/langs.pl`). `library(numpy)` still embeds CPython and is to be
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
| `../cicili` | the language cocolog is written in; BUILD time | `9d74a5e` (3.0.0: a float literal is a double, every digit of it; 2.0.1 and 2.0.2 let `->` and `=>` through any call; 2.0.0 split `(inline)` and `(weak)`, which 1.10.7's reader needs) |
| `../ZiguratIP` | the database; RUN time and `make schema` | the owner's |

**cicili is frozen**: no edits, commits, pushes, branch changes or `git add`.
A problem that traces to the transpiler gets a diagnosis and a proposed patch,
not an applied one (the owner let four in by name: 2.0.0's split, 2026-10-11,
2.0.1's and 2.0.2's arrow through a call and 3.0.0's double literals,
2026-10-12).
The SHA above is an observation, not a pin -- the owner moves cicili; check it
with `git -C ../cicili log --oneline -1` when a build behaves oddly, and
correct the row rather than trusting it.

**ZiguratIP is the owner's.** It was unfrozen for engine fixes
(`TCP_NODELAY`, the unmap resume mark, rollback-on-disconnect, the streams
guard's writer preference, the page list, the chunked grow, the commit clock
settle, the open's hexmap read a page at a time -- 1.0.1). After touching
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
* **Debian's SBCL 2.2.9 starts with a 1 GB heap, which a build of cocolog
  exhausts** (a heap-exhaustion report from Cicili, midway). Since 1.10.28
  `tools/cc/sbcl` is the `sbcl` every build step runs (the Makefile's Cicili
  step, `env.sh` for each `build.sh`, `test/run.pl`): it hands the real
  sbcl 4096 MB when its default is smaller (`COCO_SBCL_HEAP=N`; a
  `--dynamic-space-size` given is obeyed). **It must not take `tools/cc`
  off PATH** for the sbcl it runs, as the wrappers do before they exec the
  compiler: the Cicili inside compiles by naming `gcc`, and its first
  version built cocolog with Ubuntu's gcc (the tell, `readelf -p .comment
  .libs/cocolog.o`).
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
* **A program's own arguments come after `--`**:
  `current_prolog_flag(argv, [Exe|Tail])`; `os_argv` is the literal command
  line; `executable` is the binary's path. Those three, `double_quotes`,
  `text_units` (1.13.0), since 2.0.0 `bounded`, `max_integer`,
  `min_integer`, `max_tagged_integer` and `min_tagged_integer`, and since
  2.2.2 swipl's four float flags and `float_min`, `float_max` and
  `float_max_integer` are the only flags answered; set_prolog_flag/2 sets
  `double_quotes`, `text_units`, `generate_debug_info` (taken and unused)
  and the float flags, as a goal since 2.2.2, and refuses every other flag
  in swipl's words. `library(main)` parses the tail.
* **Exit status is SWI's**: 0 proved, 1 failed silently, 2 threw; `halt(N)`
  is N from `-s`, `run` and `query` alike.
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
syntax, solve, module, state, zigurat, shared; about forty seconds each that
links the engine) and runs the 67 `.pl` cases in `pl_names/1`
-- **74 lines**, each with its seconds. There is no `.sh` under `test/`.

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
* **The prelude's `shell/3` gives a child two minutes and a timed-out child
  hands back EMPTY output**, which a case reads as "nothing found". A step
  whose work grows with the tree takes `shell/4` with a ceiling of its own
  (`test/lint.pl`'s corpus lint has five minutes).
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
  hold would be reported as cocolog's failures. **Count the SKIPs and run
  `pgrep ziguratip`** before believing a green run; the number of SKIPs is a
  fact about the machine.
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

* **A within-run pair or nothing.** This box drifts ~20 % between runs of one
  build. Compare two builds in ONE round, back to back, and settle a few per
  cent with five alternating pairs; a ratio under ~3x from medians alone
  means nothing on the pooled rigs.
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
  `atoms`, `functors`). Worker threads are invisible to it: count the
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
* **The macro tables emit several things that must not drift apart**
  (`*cell-tags*`, `*operators*`, `*builtins*`, `*turn-outcomes*`,
  `*construct-names*`): **add to the table, never to the generated code.** A
  construct name missing from `*construct-names*` stops the build at
  `no dispatch id`.

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
`channel_recv/2`, `channel_close/1`), so a program's own predicate of one is
shadowed by the library's -- the 2.8.0 suite found test/window.pl's and
test/flowdebug.pl's `go` fixtures that way, and they are `rec` now). Only files swipl also runs (`test/files/*.pl`,
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
| an external library | `curl` (libcurl), `torch` (libtorch), `tensorflow` (its C API), `ray` (raylib), `numpy` (python3 with numpy and a shared libpython), `opencv` (OpenCV 4 with dnn) |

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
  `listing/0` too). SWI answers for a library's and a builtin's as well;
  this does not. Through 1.10.2 it also answered for any name a call or
  `clause/2` had merely looked up (each makes a table entry).
  `predicate_property/2` (1.10.28) answers for a construct (by name AND
  arity, `*callable-constructs*`: the construct table also holds the
  engine's markers, `'$k'`, `[]`, `:-`, which are no predicates), a C
  builtin of the engine or of a compiled-in module (`built_in`, `foreign`,
  from the tables the dispatchers are built from: `coco-emit-claims`), and
  any predicate of the store (`dynamic`/`static`, `number_of_clauses/1`,
  `number_of_rules/1`); `M:H` is H, so `user:H` walks the program's. A
  `.so` module's predicates are not answered, and a library's carry no
  `built_in`/`imported_from` (a muted consult records no file).
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
  C-registered name shadows any clause of that name (`listing/1` shows
  nothing). Grep a predicate name before writing it: **cocolog consults the
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
* **Every builtin is deterministic**, so a failure-driven loop written from
  habit (`retract(H), fail`) runs ONCE -- wrong, not slow. `once/1`,
  `ignore/1` and `\+` are control constructs. So `arg(N, f(a, b), A)` with
  `N` unbound and `char_type(C, alpha)` with `C` unbound RAISE where SWI
  enumerates. A module row that must enumerate for some arguments ends in
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
  (`coco_text_put`).
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
  from `coco_factorize`, swipl's text to the letter -- `S_N` unless the
  write names variables itself (write_term's `variable_names`) or is
  write_canonical's or the store's. `is/2` and the comparisons ask at 1024
  levels and raise `type_error(expression, E)`, E their whole argument.
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
    one (the store's length set back); a grammar rule is asked BEFORE its
    translation, which recursed through a cyclic body to a SIGSEGV; the
    clause check counts 4096 goals before it asks.
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
  call/1 of `G = (true, G)` runs for ever where SWI refuses to compile it; a
  channel and thread_create/2's goal carry one as the text of its factors,
  which reads back as `@(T, [V=B, ...])`; a format's `~s` and `~a` raise
  cocolog's error for anything not text where SWI says
  `format_argument_type`; the text builtins that write any term
  (string_length/2, split_string/4, ...) write a cyclic list as its factors
  where SWI raises; term_to_atom/2 names the factors `S_1` where swipl
  writes a variable (`_3586`), and 1.10.18's case pins `S_1` as SWI's;
  numbervars/3 does not exist. subsumes_term/2, `=@=/2` and `\=@=/2`
  (2.1.0) do, built on the walks above: Specific's variables collected,
  a unify, each variable asked still unbound and none made one (the
  variable map), the unify undone; `=@=/2` asks a COPY of its first term
  both ways, so a variable the two share is not bound across, and sets
  the heap back after; `0.0 =@= -0.0` fails, as unify's floats are SWI's
  since 2.1.1 (below). term_variables/2's collector looks a
  variable up in the map past sixteen (2.1.0; it scanned, and 200 000
  variables took 6.8 s). A
  deep TREE overflows the C stack where it always did (~47k levels of
  `coco_write_rec`, ~87k of `coco_arith`). **The writer's six arguments
  stay in registers**: quoted, ignore_ops, operand, (2.2.4) numbervars and
  (2.2.5) swipl's character escapes are one `mode` word (1, 2, 4, 8, 16;
  what a compound hands its arguments is `mode & 27`, the operand's 4
  being each operand's own, and what an atom reads `mode & 17`), and a compound
  is `coco_write_fun`, always inlined, so the
  guard's slow path returns rather than rejoining -- rejoined, every
  compound read its tag and functor again (21 instructions each).
* **A directive is a GOAL.** `coco_directive` answers the ones that act on the
  reader (`op/3`, `set_prolog_flag/2` of `double_quotes`, `text_units` or
  `generate_debug_info` -- any other flag is the goal's since 2.2.2,
  `coco_reader_flag` --, `dynamic/1`, `discontiguous/1`,
  `multifile/1`, `module/2`, `use_module/1,2`, `autoload/1,2`,
  `ensure_loaded/1`, `meta_predicate/1`, `if/elif/else/endif`) and calls
  everything else in file order. `initialization(G)` runs after the file is
  read, `initialization(G, now)` where it stands, `initialization(G, main)`
  after the load and then halts. A directive that fails or throws is
  reported in SWI's shapes and the load goes on; **a syntax error is the
  only thing that ends a consult.** A `use_module`/`ensure_loaded` that
  loads nothing is reported the same way (since 1.8.39: SWI's ERROR
  `source_sink ... does not exist`, then the failed directive; it used to
  be SILENT), except SWI's names for what cocolog carries elsewhere --
  `error`, `dcg/basics`, `dcg/high_order`, `lb_carried` in
  `lib/library.cicili`. A module is claimed BEFORE its consult,
  so a goal directive in a module (and every `-s` program is one) no longer
  re-consults it.
* **Consulting a file REPLACES the clauses it put in the store last time**
  (per-clause `origins`; `'$from'(Path, Clause)` on the wire); asserted
  clauses and other files' are untouched.
* **An uncaught exception reads as SWI's sentence** (`coco_error_text`):
  `Unknown procedure: main/0`, `Unknown message: Ball`.
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
  inlined construct code moved the step loop's registers.
* **Text builtins work on CHARACTERS, SWI's, and on BYTES when a program
  asks** (`text_units`: 1.13.0, and characters the default since 2.0.0;
  bytes were through 1.x). A code is a code point, a char one character of
  however many bytes, in the text builtins, the reader (`"..."`, `0'c`),
  format's `~c`, `~s` and codes/chars sinks, char_type/2 (past ASCII as
  glibc's C.UTF-8 classes them, swipl on Linux: `coco_uc_case`,
  `coco_uc_letter`, `coco_uc_space` in lib/term.cicili, written out),
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
  still quotes `'dár'` (the reader takes no unquoted letter past ASCII),
  library(text)'s regexes match bytes, and library(flow)'s widths and
  columns ask the flag past 127 (a code of 128..191 is a continuation byte
  only under bytes). test/units.pl holds it to swipl. Under bytes, build
  and take apart accented text with atom_concat/3 (modes -,+,+ and +,-,+),
  atomic_list_concat/2 and member/2 over a list of the suffixes, as
  tr_stress_stem/2 does. **A syntax error in a load is
  placed** (1.11.9): `ERROR: FILE:LINE:COL: Syntax error: REASON`, the column
  from 0 in bytes as swipl's, from `run` and `-s` alike -- a module's names
  ITS file, through `use_module` and through the load a goal's ask makes
  (`load_err` on the store) -- and the consult still ends there. Through
  1.11.8 `run` said a byte offset and `-s` only `its clauses would not
  consult`.
* **`atomic_list_concat/3` with a bound third argument and a non-ground list
  SPLITS**; `/2` cannot split; `atom_concat/3` has `(+,-,+)` and `(-,+,+)` but
  no `(-,-,+)`; `string_concat/3` only `(+,+,-)`. **`sub_atom/5` and
  `sub_string/5` are clauses** walking every position -- use
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
* **A call sees the clauses that stood when it began** (ISO's logical update
  view, swipl's; through 2.2.5 a retry read the live list). A clause frame
  carries `cend`, the clause count at its push (both push sites), so what is
  asserted while it is open lies past its end, and asserta moves the open
  frames on (`coco_frames_on` act 2: `clause_ix`, `cend`). A retract while a
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
  probe, `'$pred_count'`, and every query's start (`coco_tomb_sweep_all`
  over the store's `tpreds`). `coco_frames_on` walks `m->eng` and each
  engine's `outer` over the same store, the predicate's `framed` saying
  whether a frame may be open (set at every push and restore, cleared by a
  walk that finds none). **A new reader of the clause list skips
  `coco_pred_dead`** (listing, the backends' sync, clause/2 by live ordinal
  through `coco_pred_live_at`, predicate_property/2's counts), **a new writer
  of `nclauses` or `ntomb` calls `coco_pred_nprobe`**, and **a new push of a
  clause frame sets `cend` and `framed`**. A freeze writes a frame's next
  clause and its end as counts of LIVE clauses (`C`, `L`), the knowledge base
  a thaw reloads holding no others; a frame thawed from a blob with no `L`
  has `cend` 4294967295 until the run's first step binds it to the reloaded
  base (`cunbound`, `coco_frames_bound`, after the module clauses load:
  bound at the restore, member/2's frames saw an empty store).
  `test/files/update_view.pl` holds 34 cases to swipl, `test/engine.pl`'s
  last section the freeze and a second process.
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
* **The six term walks borrow the machine's stacks** (copy, store-put,
  store-get, store-unify, unify, compare: `coco_wframes_take`/`_give`,
  `coco_wpairs_take`/`_give` in `lib/term.cicili`), and the three that
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
  directive's `use_module` runs no goal and is not vouched; a new caller
  of a load vouches nothing until it registers what it reads after. A
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
  a failed rehash still leaves an empty slot). Ids stay in order of first
  use, which a frozen machine relies on; `coco_name_arity_hash` serves the
  functors (`lib/term.cicili`) and the predicates (`lib/kb.cicili`). Each
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
  and `coco_clause_run` in `lib/kb.cicili`, since 1.8.44; `coco_clause_run_r`
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
  the compaction's second pass (which nils it: the table is about to be
  cleared) -- and a sixth array would go to the same five places. **The
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
    names (`coco_gc_codes`). A clause that dies while an environment is
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
    question. Guards and an environment have their own executor
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
  frame's kind is asked in six places -- `coco_backtrack`'s drop test,
  the `$trace_exit` marker's search, the `;` Redo's search,
  `coco_trace_reopen`, `$catch_exit`'s scan and `coco_frames_on`'s walk
  (the update view's) -- and a new kind goes to all six. **A frame is a
  call's by its depth (> 0), never by its goal**:
  a goal can be heap cell 0, and `--trace run F t` printed no Fail for an
  atom goal written first. A Redo reopens only the calls it is inside
  (the nearest shallower frame, then the next), not every shallower one.
* **The journal** (1.10.15; TRACING.md, DESIGN-flow.md 9.2):
  `'$trace_window'/4` with `journal(record(F))` writes a line for each
  PORTAL call -- a module call that reaches the world -- and with
  `journal(replay(F))` answers each from its line and runs none. A portal
  is decided by module (`coco_jr_whole`: zigurat, os, process, stream,
  thread, tcp, tls, curl, ray, opencv, torch, tensorflow, numpy, aes, x509
  -- every C predicate of one), by name for the modules that are not
  (`coco_jr_named`: files' twenty, getenv/setenv/unsetenv, statistics/2,
  current_prolog_flag/2, sha_file/3, and format/3 unless its sink is a
  term), and by `coco_m_portal` for a module out of the tree. **A core
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
  does not. Not swipl's yet: print/1 calls no portray/1 hook; a control
  character with no letter is written as it is (swipl's `\x1\`; this
  reader has no `\x..\`); listing/1 and the REPL write `'don''t'` and
  `'$VAR'(1)` (swipl's `'don\'t'`, `B`); and a quoted infix operator after
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
  `integer out of range`, and atom_number/2 and number_codes/2 fail for
  such a numeral. **The guards stop where they cannot decide** -- a result
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
  call), queens -2.5 %, lookup -1.6 %.
* **A window asks where it stopped** (1.10.16, D4): `'$trace_window'/4`'s
  `ask(Cond, Holds)` proves Cond in an engine of its own (ten million
  inferences, no collection) between the run's end and the undo, over the
  bindings the run left; Cond's cell is a root beside the goal's
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
* **A grammar rule's leading terminal is stored in its head**, as SWI's
  `optimise_unify` does.
* **The reader is written ONCE and emitted TWICE** (1.10.7): the bodies of
  `coco_parse_term`, `_primary`, `_named`, `_args` and `_list` are macros at
  the top of `lib/syntax.cicili`, emitted as the family every consult uses
  and as the `_p` family that also builds `read_term/3`'s positions; a
  position site is `(if ,P ...)`, which the compiler drops from the first.
  **A change to the parser is a change to the macro**, and a helper both
  families call is `(inline)`. One parser with a flag at each site cost
  consulting the translator 1.3 %; the two cost `coco_next_token` nothing
  and the parser within 0.13 %.
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
  the start.

* **A signal is a halt code** (2.6.0): a handler in `modules/signal` writes
  `4 + SIGNO` into the engine's `halted` cell (the one object a handler may
  assign), and `coco_halted_step` (lib/solve.cicili) flushes the
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
  affinity; it was eight through 2.9.2). **ONE STORE (2.9.0)**: every worker, and so
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
* **There is no `/proc/self/exe`**: `lb_exedir` asks `_NSGetExecutablePath`;
  programs read `current_prolog_flag(executable, P)`.
* **`make schema` dies in libc++** (`binary_function` removed): copy the home
  config, add `-D_LIBCPP_ENABLE_CXX17_REMOVED_BINARY_FUNCTION` to
  `CPP_FLAGS`, run `ZIGURATIP_CONF=that-file make schema`.
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
  (2.5.1); Linux keeps the vDSO's `CLOCK_MONOTONIC`.
* A server's READY line comes ~1.4 s before its port opens, and a page that
  warms a store is ~4x slower than on the Linux box.

## Where things are

| path | what |
|---|---|
| `cocolog.cicili` | the composition root: CLI, options, the version |
| `lib/term.cicili` | cells, unification, the trail, copying |
| `lib/syntax.cicili` | the reader and the writer, one operator table plus `op/3`'s |
| `lib/kb.cicili` | the clause store, its five backend hooks (`fetch`, `on_assert`, `on_retract`, `on_dynamic`, `warm`), compaction |
| `lib/solve.cicili` | the engine, the builtin table, error text |
| `lib/module.cicili`, `lib/sdk.cicili` | the module seam and the SDK an out-of-tree module is written against |
| `lib/library.cicili` | `use_module`, the library path, directive goals |
| `lib/builtins.cicili`, `lists`, `apply`, `files`, `dcg`, `state` | tier-1 modules (`files` has `get_time/1`) |
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
| `tools/flow/` | `chart.pl` (a flowchart from a shell: `cocolog -s tools/flow/chart.pl -- SPEC FILE BASE`, exit 0/1/2, the findings on stdout as `FILE:LINE:COL: error: ...`), `tables.pl` and `build.sh` (library(flow/chart)'s tables, by `make modules`), `zero.sh` (the untraced engine's instructions on nrev, queens and lookup, a binary beside a binary, the jump padding apart), `debug.pl` (what a query did, from a shell: `cocolog -s tools/flow/debug.pl -- GOAL FILE BASE`, exit 0/1/2, a line on stdout of how the run ended); DESIGN-flow.md is the plan |
| `tools/compile/` | `static.pl`: which predicates' clauses nothing changes while a program runs, and what each call reaches -- DESIGN-compiling.md §7's count (`test/static.pl`) |
| `test/` | the suite: `run.pl`, `prelude.pl`, the cases and their fixtures |
| `tutorials/` | the lessons |
| `bench/` | cocolog against CPython and SWI-Prolog (`sh bench/langs.sh`; SWI with `-O` and as installed, run on the same `.pl` files), moved from The Coco; the runs kept start at 1.8.48 (A-L are in `f544cca`); `test/langs.pl` guards its pairs. And the concurrency benchmark (`sh bench/concurrency.sh`): real threads, green threads, Go goroutines, Rust threads and Python asyncio on the spin workload, the light spawn/switch lanes, and the one-core real lane under `taskset`; answer-gated, the first run of each lane thrown away. `library/async/README.md` has the model, the numbers and the shared-heap design note |

**A feature that touches the knowledge base must consider all three
arrangements**: local (no hooks), Zigurat (all five hooks), Zeytun (`fetch`
and `warm` only -- one HTTP request is one transaction).
