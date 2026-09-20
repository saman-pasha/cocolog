# Working on cocolog

README.md says what cocolog is and STATUS.md what is proven. This says how to
work in here and what will bite you.

## cicili and ZiguratIP are frozen

**Only this repository may be modified.** The other two are inputs.

| repo | role | frozen at |
|---|---|---|
| `../cicili` | the language cocolog is written in; used at BUILD time | `b5fafd0` |
| `../ZiguratIP` | the database; used at RUN time and by `make schema` | **unfrozen** |

**cicili stays frozen**: no edits, commits, pushes, branch changes or `git add`
in it. A cocolog problem that traces to the transpiler gets a diagnosis and a
proposed patch, not an applied one.

**THE SHA IN THAT ROW IS AN OBSERVATION, NOT A PIN, AND IT HAD GONE STALE.** It
read `00ca101` while the checkout sat eighteen commits ahead of it on `master`
at `b5fafd0` -- the OWNER moves cicili, and the freeze says only that nothing on
this side does. So read the row as "what a session here last saw", check it with
`git -C ../cicili log --oneline -1` when a build behaves oddly, and correct it
rather than trusting it: a stale SHA in a freeze table reads as a pin somebody
broke, which is the wrong alarm.

**ZiguratIP was unfrozen** to fix the twelve-worker slowdown, and carries the
`TCP_NODELAY` change described in STATUS.md — and, since the forget wedge,
two more: the unmap resume mark in the MVCCS engine and the
rollback-on-disconnect in the server's connection scope (the "APPLIED"
section below) — and, since ZiguratIP#37, the streams guard's own writer
preference and the shared row cursors, which landed together as `f1ff4d5`,
0.1.16. Rebuild it and then `make schema` after touching it — see
the hazard below; a change to `MVCCS-cicili/mvccs-lib.cicili` also rebuilds
cocolog's EMBEDDED engine, which is transpiled from the same file through
the `embed/mvccs-lib.cicili` symlink.

What the freeze still allows: `make schema` compiles cocolog's OWN Parsi objects
into `$ZIGURATIP_HOME/ld`, and the server writes to `$ZIGURATIP_HOME/data`.
Neither dirties the ZiguratIP repo — `*.so` is gitignored there and `home/data`
has no tracked files — so `git status` in it stays empty. Verify that it does.

## Build and test

```sh
export CICILI=/home/user/cicili                  # a Cicili checkout, for sbcl
export ZIGURATIP=/home/user/ZiguratIP            # a BUILT ZiguratIP checkout
export ZIGURATIP_HOME=/home/user/ZiguratIP/home  # and its home
make            # the C client and the ONE cocolog binary (the embedded
                # store is linked in, so this NEEDS A BUILT ZiguratIP;
                # every module is tier 2 and separate, so it needs no
                # libtorch and no libcurl)
make EMBED=0    # the same binary without the embedded store: no ZiguratIP
                # needed, and `--embed' refuses by name. Everything else --
                # --local, the server, --http, every library and module --
                # is unchanged
make schema     # compile the Parsi objects into $ZIGURATIP_HOME
make modules    # every loadable module buildable here; SKIPPED, by name,
                # for the rest
make test       # the suite
cocolog -s test/run.pl -- solve            # one case
make lint FILES=myprogram.pl    # cocolint, over a file you name
sh tools/lexicon/build.sh       # the reasoning lexicon from WordNet 3.0
                                # (apt install wordnet-base); a cocolog
                                # program, library/reasoning/lexicon/build.pl,
                                # and its output IS committed
sh tools/tagger/train.sh        # the shipped tagger, library/reasoning/model.rows:
                                # generate.pl writes the training data to
                                # library/reasoning/generated/ (committed),
                                # train.pl trains on it; three minutes with
                                # libtorch, and the model is committed too
```

**`cocolog --version` ANSWERS ON STDOUT, AND THE NUMBER GOES UP WITH
EVERY CHANGE.** It lives in ONE place -- `coco_version_text` in
`cocolog.cicili` -- because a `#define` is raw C that Cicili cannot see and
a second copy anywhere is a second thing to forget.

**THE PATCH IS THE DEFAULT**, and the owner's instruction: bump it for an
ordinary change and keep bumping it. The minor is for something new being
reachable from a program and the major for a program that worked stopping,
but neither is TAKEN -- it is proposed, with what changed observably, and
the owner decides. Getting that wrong the timid way costs nothing; getting
it wrong the loud way tells every reader downstream that something broke
when nothing did. Bump it in the same commit as the change, never
afterwards, and a documentation-only commit does not bump at all -- there
is no new binary for the number to describe. `--help` explains and goes to
stderr, so a script can read `V=$(cocolog --version)` with no redirection.
`test/argv.pl` pins the SHAPE and deliberately not the number -- a case
that named it would be a second place to edit, and the one somebody
forgets.

There is one `cocolog` binary and it is full: the four knowledge-base
arrangements — `--local`, the server, `--http`/`--https`, `--embed [DIR]`
— are runtime options, never builds. Local is the default; naming `--kb`, `--host`
or `--tcp` chooses the server, and a bare `--embed` opens the store at
`./KB`. There is no `--store`: `--embed` with its optional directory is
the one spelling, and a store named like a command verb is written `./run`.

**`-s FILE` IS THE FORM FOR A PROGRAM, AND `run FILE main` WRITES ITS
SOURCE INTO THE DATABASE.** `-s` is `use_module(FILE), main`, so the
program's clauses are muted the way any module's are; `run` CONSULTS, and
consulting writes through. Measured with a store either side:

```sh
cocolog --embed KB -s  tool.pl        # tool_private_fact/1 absent after
cocolog --embed KB run tool.pl main   # tool_private_fact(1) is IN the store
```

Under `--local` there is nothing behind the clauses and the two look
identical, which is how the difference stays invisible until a tool is
pointed at a real knowledge base. The suite still runs the tutorials with
`run` on purpose — a lesson has nothing private to leak — and
`test/argv.pl` pins both halves. It also decides which `main/0` wins when a
file defines one beside `library(main)`'s: `run` puts the file's clauses
first, `-s` puts the library's, which is the N1 trap seen from the inside.

**A PROGRAM'S OWN ARGUMENTS COME AFTER `--`.** Everything before it is
cocolog's, everything after reaches the program as
`current_prolog_flag(argv, V)` — `[Executable|Tail]`, with `os_argv` for
the literal command line. There has to be a separator because `run FILE
GOAL` reads the LAST argument as the goal. `library(main)` parses the tail
into option terms; `tutorials/library/38-main.pl` is the lesson.

The server, which the database tests need:

```sh
cd /home/user/ZiguratIP && ZIGURATIP_HOME=$PWD/home \
  LD_LIBRARY_PATH=$PWD/home/lib setsid ./home/bin/ziguratip
```

Start it detached. A plain `nohup … &` from a tool call does not survive the
turn, and what you get then is the next hazard.

**`ziguratip --config=<file>` runs a CUSTOM-CONFIGURED server without
touching `home/etc/ziguratip.conf`** — the owner's own pointer. A test
that needs different settings (TLS_MODE, ports, permissions) copies the
conf, edits the copy, and raises a second server on it; the home config
stays what it was. Without `--config` the usual lookup order applies.

### A test case is a Prolog file, and one process runs all of it

**`test/<case>.pl`, run as `./cocolog -s test/<case>.pl` FROM THE CHECKOUT
ROOT with `COCOLOG_LIBRARY` naming this checkout's `library/`** (which
`test/run.pl` sets for every case it runs), is what EVERY shell case
became on 2026-09-04 -- there is no `.sh` under `test/` any more, the
runner included -- and `test/prelude.pl` is what they share.
The `.sh` shape spawned a cocolog per check -- `timeout 60 cocolog query
... | grep -aoE 'answer(...)' | sed`, forty times in `string.sh` alone --
and a check cost ~120 ms of start-up and pipes to hear an answer that
takes a millisecond to compute. Measured on the Mac, same checks, same
pins:

| case | `.sh` | `.pl` | checks |
|---|---|---|---|
| serialize | 15.6 s | 0.2 s | 114 |
| httpd | 230 s | 32 s | 73 |
| http | 18.3 s | 2.8 s | 47 |
| opencv | 8.3 s | 0.6 s | 33 |
| thread | 13.1 s | 3.4 s | 19 |
| curl | 9.0 s | 1.5 s | 12 |
| nineteen cases together | 361 s | 74 s | 533 |

`httpd.sh`'s four minutes were not spawning at all: it `sleep 3`'d for
each of seventeen servers and then `wait`ed for servers told to accept
more times than the case connected, forty seconds a server. The `.pl`
waits for a port with `lsof -iTCP:PORT -sTCP:LISTEN` -- never a probe
connection, since a server that accepts N times would count it -- and
stops a server that has answered.

**THE SHAPE IS CivV's, decision for decision.** `main/0` runs the
checks; `check/3` and `checks_done/0` are `library(process)`'s -- the
harness every `.sh` re-implemented -- and the EXIT CODE IS THE VERDICT,
0 exactly when `main` proved, which `checks_done` withholds on any red
check. `test/run.pl` -- a cocolog script itself, `make test` is
`./cocolog -s test/run.pl` and `-- NAME` runs one case -- builds the seven
`.cicili` binaries through Cicili and runs every `.pl` case that way; a
line beginning `SKIP` at column 0 skips the case (so a SECTION that
cannot run says so indented, `     (skipped: ...)`), and every case line
carries its seconds. A case's fixtures are files it writes to a scratch
directory, or programs beside it under another name (`test/trace-program.pl`
is what `trace.pl` traces; `test/edge.pl`, `test/term.pl` and
`test/colab-check.pl` are the programs `tunnel`, `zigurat-tls` and `colab`
raise). `test/prelude.pl` adds `answer/3` (prove
once; `failed` or `error(Ball)` instead of ending the case), `written/3`
(the value as `write/1` spells it, for a pin the `.sh` made against a
written term -- kept byte for byte rather than re-guessed as a term),
`yes_no/2`, `skip/1`, `scratch/1`, `fixture/2` and `cocolog_out/2` for
the checks that genuinely ARE a second process. Those remain children on
purpose: a consult whose directive reports on stderr, a store read back
by another cocolog, a server, a goal that must run under something that
can kill it (`engine.pl`'s timed runs through `proc_run/4`).

**Five things bit, in order of how long each cost:**

* **A SPAWNED SERVER MUST BE `exec`'d, or `proc_stop/1` kills a shell and
  orphans it.** `proc_spawn/2` runs `/bin/sh -c CMD`, and this `/bin/sh`
  FORKS for a command carrying redirections rather than execing it, so the
  pid it answers is the shell's: measured, `proc_stop` reported the pid
  `gone` while the port was still held, by a pid two higher. The orphan
  goes on listening, and the next run of that case meets its own port
  taken -- the suite's first end-to-end run lost `tunnel` and
  `zigurat-tls` to servers a standalone run of those two cases had left
  behind an hour earlier, which reads as a routing bug and is not one.
  `test/prelude.pl`'s `spawn/2` puts `exec` in front; every case that
  raises a server uses it, and a case whose child is a shell LOOP
  (`ruler.pl`'s queriers) keeps `proc_spawn` and lets the loop end itself.

* **A clause has ONE scope.** `opencv.pl` named a PNG's signature bytes
  `B0..B3` in a check six lines below one that named a 64f handle `B2`;
  the byte was unified with a handle and the check FAILED only in
  sequence, never in isolation. Suffix a check's variables with its
  number, and do not reuse a suffix.
* **libc's regex `.` matches a newline.** `answer\(.*\)` over a child's
  whole transcript ran on to the last `)` of `1 answer(s).`; the
  prelude's `cocolog_answer/2` uses `answer\([^\n]*\)`.
* **`get_time/1` answered WHOLE SECONDS** -- `time(NULL)` cast to a
  double -- so `thread.pl` timed one thread at 2000 ms and four at
  1000 ms. It is `gettimeofday` now (`lib/files.cicili`, with
  `<sys/time.h>` in `cocolog.cicili`'s includes), SWI's resolution.
* **The `double_quotes` guard was on the wrong path.** `string.pl`'s
  first in-process run loaded `library(json)` AS A GOAL after a module
  had set the flag to `string`, and json.pl "would not consult": the
  guard sat in `lib/solve.cicili` around the ask-time hook, and a
  runtime `use_module` reached `coco_module_load` without passing it. It
  lives in `coco_module_load` now (`lib/module.cicili`), on the one path
  every module consult takes, and the goal that loads a module keeps its
  own flag -- which CLAUDE.md had claimed all along and the `.sh` never
  checked, because its goal's `"ab"` was read before the load.

`set_prolog_flag/2` is a DIRECTIVE, not a goal -- it acts on the reader
and does not exist at run time -- which is why a case cannot put the flag
back itself and the guard had to.

### One compiler, and where it is written down

Everything here is built by **clang**: the client, the interpreter, the
embedded store, every `.so` under `library/`, and — over in ZiguratIP —
libCore and the server the tests talk to. That is not a preference, it is
a requirement of the arrangement: cocolog links ZiguratIP's C++ libraries
into its own binary and `dlopen`s modules into its own process, so a
mixed toolchain is one address space with two ABIs in it.

`tools/cc/` is the whole answer, in four small files, and `tools/cc/README`
is the long version. Two things in it are worth knowing before a build
surprises you:

* **Cicili names `gcc` outright** in `config.lisp` and takes no override.
  It is frozen, so the build puts `tools/cc` on `PATH` for that one step
  and keeps a `gcc`/`g++` pair there that exec the real compilers. The
  three-line Cicili patch that would retire them is in the README, offered
  and not applied.
* **`clang++` alone does not compile C++ on this box.** It borrows
  libstdc++ from the newest gcc it can find, which is gcc-14's runtime
  directory — crtbegin.o, libgcc_s.so, and not one header, because g++ is
  13.3. Every C++ file then dies at `fatal error: 'string' file not found`
  naming a header that is plainly installed. `tools/cc/cxx` works out
  which gcc install dir actually has a header set and passes
  `--gcc-install-dir`.

`make CICILI_CC=gcc CICILI_CXX=g++` builds with gcc, and ZiguratIP's
`make COMPILER=g++` does the same there. Nothing is load-bearing on clang;
what is load-bearing is that all of it agrees.

**`?=` DOES NOT DO WHAT YOU WANT FOR `CC` AND `CXX`.** make gives them
built-in values (`cc`, `g++`) whose origin is `default`, not `undefined`,
so `CXX ?= …` leaves `g++` in place. The final link went on being a gcc
link while every other line of the build said clang, and the only way to
see it was `readelf -p .comment`. Test the origin instead:

```make
ifeq ($(origin CXX),default)
CXX := $(CURDIR)/tools/cc/cxx
endif
```

**Clang is stricter, and Cicili treats compiler chatter as FATAL.** A
target compiled as C++ needs `-Wno-parentheses-equality` and
`-Wno-dangling-else` in its own `:compile` list, because the transpiler
emits `while ((x == 0))` and unbraced else-if chains and clang complains
about both. Without them the build stops with an `Unhandled SIMPLE-ERROR`
whose text is a warning. gcc ignores unknown `-Wno-` options, so the flags
travel to every platform. `cocolog.cicili`, `embed/embed.cicili` and all
three MVCCS-cicili targets carry them.

## Four defects that lost information, and the shapes that fix them

All four were reported from cicili-lang, which had worked around three of
them. They are one family: the interpreter knew something had gone wrong
and the program could not find out. `test/errors.pl` is the case, 42
checks, and each section names what it is guarding. A FIFTH section joined
them in 1.2.8 and it is the one that did not raise at all: `nb_setval/2`'s
globals read against the wrong store, which answered a value that was not
true, or a signal.

**A `catch/3` WHOSE GOAL SUCCEEDED WENT ON CATCHING.** The frame was pushed
and never taken down, so

```prolog
catch(( catch(true, _, assertz(seen)), throw(b) ), Ball, true)
```

ran the INNER recovery and continued from after the inner catch; the outer
one, written for exactly that ball, never heard. The goal now carries a
`'$catch_exit'(Ci)` marker after it (`*construct-names*` in
`lib/solve.cicili` -- **add the name to the table, or the build stops at
`no dispatch id`**), which marks the frame DEAD, and a COCO_CH_CATCH_RETRY
frame above the goal's own alternatives marks it live again if anything
ever fails back INTO the goal. The retry frame carries the index it
revives in `clause_ix`, a field a catch frame does not use -- so a frozen
machine still travels as a row of numbers with no new field in it, the
same argument COCO_CH_DEAD was added under. It is only pushed when the goal
left something to fail back into.

**A `throw/1` INSIDE `findall/3`, `forall/2` OR `aggregate_all/3` ESCAPED
THE CATCH AROUND IT.** All three are `coco_engine_findall`, which runs the
goal on a SUB-ENGINE with a choice stack of its own: the ball found no
catch frame there and came back as an error, which all four callers turned
into -1 and ended the query. `coco_engine_call_limited` had the answer
already -- put the machine back, then throw again from the outer engine,
where the frames are -- so findall answers **2** now, the builtin protocol's
"the continuation is already set", and its callers pass that straight
through.

**`atomic_list_concat/2,3` HAD AN 8 KB CEILING AND A USE-AFTER-FREE.** The
output was a `char out[8192]` and the overflow was a bare `return 0`, so
joining anything sizeable simply FAILED with no error term -- measured,
6400 characters answered and 8320 did not, and a caller reading that as
"these atoms do not join" is reading a buffer size. The split half had the
same ceiling on its INPUT. And the error path built its ball from an array
it had just freed, which is why an unbound element named the FIRST element
rather than the culprit, and could crash instead. It is a `coco_strbuf` for
the result now, `coco_b_text_dup` for each element (an atom answers its own
length and fits first time; everything else doubles to 16 MB), the culprit's
heap INDEX copied out before the free, and an unbound element is an
`instantiation_error`.

**AND A PARTIAL LIST SPLITS, which is SWI's rule and was not this one.**
Only a bare variable did, so `atomic_list_concat([A,B], -, 'x-y')` -- what
a caller writes when it knows how many parts it wants -- went to the JOIN
and raised `instantiation_error` about its own output. The third argument
decides: bound, with a list that is not ground, means split.

**A CLAUSE TOO LONG FOR A ROW TOOK EVERY OTHER CLAUSE OF THE TRANSACTION
WITH IT.** Zigurat fits a row in ONE page and throws `allocation overflow`
at COMMIT: measured on the embedded engine, a clause of 8013 characters
stores and one of 8014 does not, and the refusal lost the small facts
asserted before and after it -- silently as far as the program could tell,
because its own `findall` had already answered with all of them in it. The
store now carries `clause_max`, and `coco_assert_from` measures the term
the backend will write, `'$from'` wrapper and all, BEFORE the predicate is
touched -- above the reconsult forget in particular, which is the line that
did the emptying. `assertz/1` raises `resource_error(clause_length)`,
catchable, and a consult REPORTS it in SWI's shape and goes on to the next
clause, because a syntax error is still the only thing that ends a load.

**THE BUDGET IS MEASURED, NOT GUESSED.** Bisecting the longest clause text
that stores, against the embedded engine:

| page | max | | name | kb | max |
|---|---|---|---|---|---|
| 8192 | 8013 | | 1 | 4 | 8013 |
| 16384 | 16205 | | 20 | 4 | 7994 |
| 32768 | 32589 | | 1 | 20 | 7997 |

-- exactly `page - 174 - len(kb) - len(name)` at every one of them, so
`coco_zg_attach` sets `clause_max` to `page - 190 - len(kb)` (sixteen bytes
of margin, because 174 is the engine's row layout and a change to it should
shorten the budget rather than break a store) and `coco_assert_from` takes
the predicate's name off per clause. A local store keeps 0 and pays nothing.

**ONLY THE EMBEDDED ENGINE CAN BE ASKED**, and `zg_page_size` is the
question: `embed/embed.cicili` opens its `Memory` on `ce_page_bytes` and
`ce_page_size` hands that number to the client. A SERVER's page is
`MEMORY/PAGE_SIZE` in its own configuration on its own machine and no call
in the protocol asks, so over the wire the client assumes the documented
8192 and **`$COCOLOG_PAGE_SIZE` is how an operator who raised it says so**.
Assuming the default is the safe way to be wrong: too small a budget
refuses a clause that would have fitted and the program gets a catchable
error naming the number; too large a one loses the transaction, which is
the defect this exists for. The engine keeps no value across pages -- no
overflow chain, no blob table, one allocation inside one page -- and
`MEMORY/PAGE_SIZE` is capped at 65536 by the cursor's hexmap buffer, which
`cursor_page_hexmap` refuses by name rather than overrunning.

**The fifth report, ~70 goal-carrying facts segfaulting a consult, does NOT
reproduce** on this binary -- tried as the real cicili-lang gate rewritten
as facts, as 30/70/100/200 synthetic ones, as 70 facts of 3700 characters
each, as one clause with a 20 000-deep conjunction, and through both `run`
and `-s`. The two fixes that most plausibly covered it are the iterative
term walks of 2026-09-04 and the row limit above.

## Four hazards, each of which has already cost a day

**A SLOW SUITE IS OFTEN THE SERVER'S UPTIME, AND THAT IS NOT THE SAME AS
THE STORE.** Measured 2026-09-08, and it cost most of a session because the
paragraph below sent the diagnosis the wrong way. A server up for 2 days 16
hours had `groups` RED at 65s and `ruler` at 38s; the store was emptied to
**140 live rows** (74 knowledge bases forgotten, ~550 000 clauses) and
vacuumed until a pass took under a second, and the cases were **exactly as
slow**. One `kill` and a restart on the same 358 MB file with the same rows:
`groups` GREEN in **12s**, `ruler` 16s, `vacuum` 6s. So the rows were never
the problem -- the PROCESS was -- and the tell is that emptying the store
changes nothing while a restart changes everything. Restart first, it costs
two seconds; the store is what you look at when a restart did not help.
(Check `pgrep -fl 'test/run.sh|cocolog -s test/'` before you do: a restart
mid-run breaks whoever is using it.)

**A slow suite can also be the store ageing, and that is the other half.**
Deleted rows are kept under MVCC and nothing reclaims them, so every run
leaves more behind and every later read walks past it. Twelve workers went from 14s to 32s over five identical
runs. `test/groups.pl` allows 60s per worker, so a long-lived store will
eventually push it over — and that reads as a hang. Restart from a fresh
`$ZIGURATIP_HOME/data` if the numbers stop making sense. `cocolog vacuum` is
the answer on a store written since the schema went `NOT NULL` — `groups` and
`ruler` run it in setup, and README's "A worked store slows down. Truncate it."
has the numbers; a store from before that carries NULLs and can only be
restarted (STATUS.md says why).

Two things follow when a run does go wrong. A killed worker used to **strand
its machine as claimed**; since the turn became ONE transaction (claim
included), a dead or failed worker's claim rolls back with its turn and the
machine goes straight back to the pool — but a `list` after a bad run is
still worth a look, because a machine claimed by a *live* wedged worker
looks the same as it always did. And a wedged server answers NOBODY on any
knowledge base, so restart it before blaming whatever you were working on.

**A store wiped under a server that is still dying answers writes and
keeps NONE.** `pkill`, then `rm -rf home/data/*` a breath later, then a
new server: every `query` says `1 answer(s)`, a second process reads
nothing back, and `:- dynamic` answers `dynamic: out of memory` -- from
the OLD binary as much as the new one, which is how an hour went to
suspecting an engine commit that was innocent. `pgrep ziguratip` must
print nothing before the `rm`; a clean restart afterwards is the whole
cure.

**`red: 0` does not mean the suite passed.** `zigurat`, `shared`, `groups` and
`ruler` SKIP rather than fail when there is no server, because "no server here"
and "the backend is wrong" are different findings — and the runner prints
`red: 0` either way. **Run `pgrep ziguratip` before believing a green run**, and
read the eight per-case lines rather than the last one.

**Rebuild the Parsi objects after ANY change to the ZiguratIP engine.** A `.so`
in `$ZIGURATIP_HOME/ld` compiled against old engine headers does not fail to
load politely; it takes the server down with `symbol lookup error`. `make schema`
after every engine build, always.

**A RED `contention_test` ABORTS ZiguratIP'S `make`, AND ON LINUX IT IS
PROBABLY NOT YOURS.** The engine's gauntlet runs inside `make` and a red
contention run ends it with `Error 1` *after* the artefacts are already built
— which reads as "whatever I just changed broke the engine" and usually is
not. Measured here over **144 runs**: intermittently red at **12.5 %**
standalone (8 of 64) and **~24 %** interleaved with the box busy (19 of 80),
so the absolute rate is load-sensitive and neither number is THE rate. The A/B
that settles the attribution is 40 runs a side, alternating, both arms built
whole — library *and* test binary — and it is **10 anomalies at `f0ac1e2`
against 9 at `9712da6`**, which is no difference at all. So it PREDATES the
page-list, the growth change and both clock commits, and none of them caused
it. **BOTH HALVES ARE SOLVED NOW** -- the `claims` shapes since ZiguratIP
`55896d9` and the harness shape since `90b717a` (0.1.9) -- and the cause of
each is recorded below. On a build that carries both, a red contention run is
a finding again.

Three shapes, and they are not one fault. `writer under readers: readers made
progress` was **11 of the 19** and WAS the harness, proved and then fixed
(ZiguratIP#36, latched in `4081120` and `90b717a`). The check is `reads > 0`,
the readers looped `while (writing)`, and nothing made them start first:
timestamped here, every reader thread reached the top of its body inside
68-353 µs while the writer ran 65-147 ms, and on a red run all six finished
`session()` AFTER the writer had set `writing = false` -- the earliest at
94 799 µs against a writer done at 94 691. Green runs shaded into it
continuously, `reads` of 2, 3, 4 and 5 being common, so it was a coin toss
with a fat tail rather than a property. The fix counts readers ready AFTER
`session()` and holds the writer until all of them are, with a `do`/`while`
so "every reader reads at least once" is structural; FOUR scenarios had the
shape, not the two this file first found. A SIGSEGV or SIGABRT turns up 6
times in 144 and is not covered by any of it. **Re-run before you believe a
red one**, and do not go looking in your own change first.

**AND `claims: not one increment lost` IS A STRING COMING BACK EMPTY.** This
file said it was "a value DECODE on the read path", which was the third of four
wrong readings and is corrected here. The symptom is a sum short by ten or
twenty, sometimes with an `0xFFFF` fill in the top bytes. Dumping the 80-byte
row image straight off the store's data file settles it, and both firings were
byte for byte the same:

| | a good row | the bad one |
|---|---|---|
| id | `0c` + `02…` = 2 | `0c` + `01…` = **1, intact** |
| kind | `29` + len `06` + `washer` | `29` + len **`00`** + nothing |
| weight | `0c` + `2d…` = 45 | `0c` + `19…` = 25 |

`id 1`'s kind should be `nut`, three characters, and the length byte on disk is
ZERO -- so the row image is three bytes SHORT and every field after the string
sits three bytes early. The "lost increment" is a weight read out of a shifted
slot. It never heals because the scenario's update copies the kind from the row
it just read, so one empty read makes every later write empty too.

**FOUR READINGS DIED ON THE WAY AND EACH COST A PROBE**, which is the part
worth keeping: that it was a regression (the A/B says no -- 10 anomalies at
`f0ac1e2` against 9 at `9712da6`, every shape on both arms); that the scan
missed a newer version (`row_latest` walks 0 hops and the unique index returns
the same bytes); that the row was an earlier generation of itself (the value is
25 whichever row is bad, and two rows cannot reach one number by different
arithmetic); and that `0xFFFF` was the fingerprint (present in one firing,
absent from the next with the payload otherwise identical -- stale content past
the shortened image). ZiguratIP#33 carries the dumps. **A fingerprint is not a
cause, and a decoded field cannot tell you what the row image can.**

**IT IS A READ WITH NOTHING HELD, AND THE FIX IS ONE GUARD** (ZiguratIP
`e8ada3f`, in master as `55896d9`). `read_row` does a `seekg` and then an
`unpack` -- two operations on ONE stream with one position -- and it held
nothing between them. Both cursors, `cursor_walk` and the B-tree's output
callback, release the streams guard around the callback UNCONDITIONALLY and
redirect the window's reads to the thread's private stream only when
`reader_eligible` (`mvccs-lib.cicili:793`), which answers 0 for a store with no
reader paths OR at REPEATABLE READ or SERIALIZABLE -- **either one, not both**.
`contention_test` sets reader paths like everybody else (`memory_reader_paths`,
`contention-test.cpp:1118`), so what made `find_then_update` ineligible was its
SERIALIZABLE claim ALONE; its callback reads rode the canonical stream with
nothing held while seven other threads sought that same stream. A position moved between the seek and a
string's length byte reads the tag and then whatever byte is now under the
cursor, and `00` is what an empty length looks like -- which is the row image
in the table above, put there by a WRITE whose `current` had unpacked empty.
`read_row` now takes the guard for itself: SHARED wherever a shared one is
possible, which routes the read to the thread's private stream and leaves the
parallel-read design as concurrent as it was, and exclusive only where there
is no private stream to use, which is the case that raced. The guard is
re-entrant per thread, so a caller already holding it pays nothing.

**AND THAT IS WHY NO COCOLOG CASE EVER SAW IT: THE CONDITION IS THE ISOLATION
LEVEL, AND NOTHING HERE CLAIMS AT ONE.** cocolog and the server read at READ
COMMITTED, so `reader_eligible` answers 1 for them and every callback read
already went to a private stream. (This file first said the fault needed BOTH
halves -- no reader paths AND the level -- which is what `e8ada3f`'s commit
message says and is wrong: `contention_test` calls `memory_reader_paths` in
its own `main`. Taken on trust, checked later, corrected here; the fix and its
mechanism are untouched, and the claim is NARROWER than the wrong one was.) A
scenario that reproduces nowhere else is not thereby a test-only defect; it is
one whose condition nothing else happens to meet.

**MEASURED HERE, 80 RUNS A SIDE**, alternating, both arms built whole --
library and test binary -- `2794635` against `e8ada3f`:

| runs showing | before | with the guard |
|---|---|---|
| `claims: no thread met trouble` | 10 | **0** |
| `claims: every round claimed` | 10 | **0** |
| `claims: not one increment lost` | 4 | **0** |
| any `claims` shape | **13** | **0** |
| `writer under readers` | 7 | 9 |
| a crash | 1 | 0 |
| anomalous runs in all | 20/80 | 9/80 |

Fisher one-sided on 13/80 against 0/80 is **p = 7.2e-5**. `writer under
readers` standing still is the CONTROL and is the useful half of the table:
the runs were detecting, that shape is engine-indifferent, and it is the
harness exactly as this file said above. **These runs were not timed** -- the
cost is the owner's measurement, 10.3-10.5 s against master's 10.4 s.

A fourth firing on the old arm retires the `0xFFFF` reading for good: the sum
came back **`0xc57fa1440000020d`** where 535 was wanted, with 25 rounds lost
as well. Arbitrary high bytes, not a fill -- which is what a read whose
position moved produces, and what no decode of a well-formed value could.

**AND THE SAME THREAD ASKED WHAT THAT GUARD COSTS. OPENING A TRANSACTION
TAKES IT EXCLUSIVELY, AND UNDER CONTENTION IT IS FULL** (ZiguratIP#37,
measured here on 0.1.10). `session()` is `begin_transaction` plus
`engine_isolate`, and the second is free -- 1 µs at its worst over 120
entries. The first is not, and timestamping its four regions says where:

| region of `begin_transaction` | median | p90 | max | share |
|---|---|---|---|---|
| id generation + `transaction_register` | 4 µs | 11 µs | 169 µs | 0.0 % |
| `transaction_reset` | 0 µs | 1 µs | 2 µs | 0.0 % |
| **taking the `Streams` guard** | 2 117 µs | 67 543 µs | **90 655 µs** | **99.9 %** |
| the writes under it | 13 µs | 19 µs | 41 µs | 0.1 % |

It is `pthread_rwlock_wrlock` on `streams_rw`, and it is EXCLUSIVE whatever
the caller's isolation: `begin_transaction` never sets `tl_want_shared`,
correctly, because it writes a row. So a thread that only wants to READ must
take a writer's lock to start.

**THE GUARD IS ~95 % OCCUPIED EITHER WAY, AND ONLY THE FILLER INVERTS.**
Four readers against one writer, 20 runs an arm:

| | filebuf | mapped |
|---|---|---|
| writer held | 6.7 % | **87.3 %** |
| four readers held | **91.0 %** | 6.1 % |
| **exclusive occupancy** | **97.4 %** | **93.9 %** |
| a reader's hold | 112.8 µs | 6.4 µs |
| a writer's hold | 147.7 µs | 116.8 µs |

Exclusive holds cannot overlap, so 100 % is a hard ceiling and both arms
sitting under it is the arithmetic working. Mapped, the writer's wall
improved **16.5x** while its own holds improved 1.26x -- what it stopped
doing is WAITING, behind 32 264 reader acquisitions.

**AND A READER'S SHARE IS THE INDEX LOOKUP, NOT THE TRANSACTION.** Splitting
a reader's exclusive time three ways, and the parts sum to the thread total
to the microsecond:

| | filebuf | mapped |
|---|---|---|
| `begin_transaction` | 3.2 µs a call, **0.7 %** | 1.2 µs, 5.5 % |
| **the `cursor_equal` window** | **223.2 µs an acquisition, TWO a lookup, 98.0 %** | 9.1 µs, 86.6 % |
| `commit_transaction` | 5.7 µs a call, **1.3 %** | 1.7 µs, 7.9 % |

So the 91 % above is the B-tree lookup taking the exclusive guard twice per
`cursor_equal`. **The SHARED path costs 0.7-1.2 µs a hold**, three orders
less -- which is also the measurement that says `e8ada3f`'s `read_row` guard
cost nothing.

**THREE HAZARDS FELL OUT, and the first is the one that will bite a
measurement here:**

* **`contention_test` OPENS ITS STORE AS A FILEBUF and the arrangements
  cocolog runs are MAPPED.** `STORE_MAP=1` in the environment switches it
  (`contention-test.cpp`'s `open_store`); the server opens mapped by
  default and so does `embed/embed.cicili`. A number taken from the
  gauntlet's default stream is not a number about `--embed` or the server,
  and the two differ by more than an order of magnitude per hold.
* **GUARD-HELD TIME IS NOT CALL DURATION** -- but that was the WRONG reading
  of the numbers this file first put here, and the right one matters more.
  An empty `commit_transaction` holds the guard for **5.7 µs on ext4** and
  **1 332 µs on APFS**, and the second is 99.4 % of a 1 340 µs call: the
  coalescing walk is INSIDE the guard on both, `free_pointer` being the first
  statement in the `letin*`. The gap is the PLATFORM. It is the same 512-byte
  hexmap walk at an 8 KB page either side, and one `seekg` + `read_std_ubyte`
  costs **~2.6 µs a byte on APFS**, where the filebuf reloads its get area on
  the seek, against **~0.011 µs on ext4**, where it never leaves the process
  -- the same asymmetry an `ftruncate` showed at ~700 µs against 23. So a
  claim about the free's cost is a claim about a FILESYSTEM: making it
  cheaper buys almost nothing here and almost everything on a Mac, and this
  project is developed on both. (What is left of the original lesson: a call
  duration and a guard-held time answer different questions, so ask which one
  a number is -- just do not reach for it to explain a gap that is a box.)
* **`MVCCS_DEBUG=info|warn|debug sh MVCCS-cicili/build.sh` compiles the
  engine's trace points in**, guard waits and holds among them, and an
  ordinary build emits none of them. At `debug` it writes two lines per
  acquisition, so a distribution taken there is of a build busy writing to
  stderr; `warn` carries only what passed a millisecond. A thread-local
  counter the harness reads back is what an unperturbed figure still needs.

**THREE READINGS DIED HERE TOO**, and the pattern is the one worth keeping:
that the 256 µs hold was `Streams::unlock`'s double flush (it scales with
PAGE SIZE, so it is a walk, and the owner's series settled it); that mapping
would dissolve the saturation (it raises it); and that a seventeenfold drop
in begins counted was a throughput difference (it was the window -- the rate
is 2 157 against 2 165 a second, within 0.4 %). Each died to a measurement
that had been named as missing and then taken. **The count is what is
suspicious: a raw total over an interval nobody recorded is not a rate.**

**AND IT IS FIXED: THE GUARD PREFERS WRITERS ITSELF NOW, BECAUSE GLIBC DOES
NOT** (ZiguratIP `f1ff4d5`, 0.1.16, and it is ONE commit on purpose). A shared
acquirer stands down while a writer is queued -- asleep on a condition
variable the writer broadcasts on every grant, and **at most twice**, after
which it takes the shared side regardless. The row cursors ask for the shared
side again in the same commit. Four measurement rounds on the four-core box
settled the shape, and every one of them killed a design that looked right:

* **The rwlock was never deferring anything.** `PREFER_WRITER_NONRECURSIVE_NP`
  is set and **36 729 941 of 36 731 243 shared grants were made with a writer
  already queued** -- 99.996 % -- with the writer granted the guard **zero**
  times in 120 rounds. `read_row`'s grants had barged the same way since
  `e8ada3f`; the shared cursor did not introduce it, it took the volume from
  7 109 acquisitions to 36.7 million and made it load-bearing.
* **A POLLING gate fixed the writer and destroyed the readers.** `usleep 20`
  while the count is above zero: the writer finished 120/120 at every reader
  count, and lookups served fell **14x to 57x**, ten range separations out of
  ten. The cost was not the gate's DECISION but its GRANULARITY -- 110 sleeps
  a lookup, and a nominal 20 µs measuring **~137 µs** among thirteen runnable
  threads on four cores, to let through a `begin` that holds the guard 3.2 µs.
* **THE BOUND IS WHAT FIXED IT, not the condition variable.** A `pthread_cond_wait`
  costs 56-88 µs here against `usleep 20`'s 86-99 -- the same order. Capping
  the stand-down at two removes **98 %** of it either way. Strict preference is
  unbounded BY CONSTRUCTION, and a stream of short exclusive acquisitions is a
  workload where "defer while any writer is queued" means "never run": that is
  this fault mirrored, and a mirror of a livelock is still a livelock.
* **AND THE READERS WERE THEIR OWN WRITERS.** `writers_enqueue` sits on the
  exclusive path and cannot know who called it, so with exclusive cursors
  **about 90 % of the queued "writers" were readers**, gating each other. The
  proof is the fix seen from the other side: with the shared cursor the
  probe's exclusive acquisitions go **FLAT IN N** -- 364 at two readers, 384 at
  twelve, and the difference of 20 is exactly the extra `begin`/`commit` calls
  ten more readers make.

**NEITHER HALF IS AN IMPROVEMENT ALONE, WHICH IS WHY IT IS ONE COMMIT.** The
gate by itself serves **0.02-0.18x** of ungated lookups on a tree whose lookups
are all exclusive, and the shared lookup by itself livelocks. Two commits would
be two bisectable regressions of two different kinds.

**FOR COCOLOG IT IS NEITHER A COST NOR A GAIN, AND THE REASON IS NESTING.**
Measured with `library(httpd)`'s pool over the wire -- `httpd_serve` with
`workers(N)`, a page whose body reads a row another process wrote, eight
concurrent clients, the engine's counters read out of the LIVE server with
`gdb -p`:

| | 0.1.12 | 0.1.16 |
|---|---|---|
| requests at 2/4/8/12 workers | 2 142 / 3 511 / 4 213 / 4 214 | 2 146 / 3 468 / 4 271 / 4 219 |
| exclusive acquisitions a request | 57.0 | 57.0 |
| shared acquisitions a request | 1.000 | 1.000 |

-- within 1 % at every width, and the profile identical to three figures, which
it should not be once the cursor asks for the shared side. Instrumenting
`reader_eligible`'s four refusals and the `Streams` constructor's four outcomes
over 13 894 requests says why: the shared side is asked for **2.01 times a
request**, **half of those asks arrive while this thread already holds an
exclusive guard** (13 920 of 27 869) and are made `mine_ = false`, and every
one of the 13 949 that reaches the outermost is granted. **`reader_eligible`
never refuses** -- not initialised, no reader paths, no transaction and the
isolation level are **0, 0, 0 and 0**, so `run_isolated/2` really does read at
READ COMMITTED with reader paths set. A cocolog request is 57 exclusive
acquisitions to one shared, so by the gate's reckoning nearly everything the
pool does IS a writer, and a writer-preferring guard has almost nothing to
defer.

**AND THE ENCLOSING HOLD HAS TWO NAMES, BOTH DELIBERATE** -- the owner's
answer, and only the second is in the process these numbers came from.
`ce_dispatch` wraps any procedure whose `ce_write_intent` is 1 in ONE
exclusive `Streams` for its whole run (`embed/embed.cicili`), so every lookup
inside an `assertz`, a `forget` or a `machine_*` rides that hold -- and the
CLAIMS are excluded from the wrapper on purpose, because a claim's
`check_lock` must release the streams while it waits and a nested guard
cannot, measured once as a full-swarm deadlock. **That is the EMBEDDED
engine, and the pool figures above are the SERVER**: `nm` finds no
`ce_dispatch` in `ziguratip` at all, so it cannot be the nesting they
counted. What is in that process is the engine's own -- `online_insert` and
`online_update` take the exclusive guard and call `map` INSIDE it, one
`bt_map` walk per index per row, so every index-maintenance lookup during a
write nests under that write's hold. A nested no-op riding a write hold is
the guard working, not an ask refused, and a write must hold across its own
index updates or the index and the row disagree across a crash.

**WHICH MAKES "no gain" THE EXPECTED RESULT AND NOT A DISAPPOINTMENT: the
shared cursor pays where lookups happen OUTSIDE a write, and cocolog's
request path is not that shape.** The probe's page writes nothing and a
request is still 57 exclusive acquisitions to one shared, so that is a
property of `run_isolated/2`'s turn rather than of the page -- and WHICH
writes those are, on a read-only page, is not measured here. A read-mostly
workload is the lead if the shared lookup is ever to pay downstream.

**THE STAND-DOWN CLIMBS WITH THE POOL AND PLATEAUS AT A QUARTER OF THE CAP** --
0.05 stand-downs a request at two workers, 0.25 at four, 0.47 at eight and
twelve, reproduced on two independently built engines. There is exactly one
shared acquisition a request, so that number compares directly with
`GATE_STANDDOWNS = 2`. The preference still grants three quarters of shared
acquisitions immediately, so **the bound is not doing all the work and the cap
should stay at 2** -- but the margin narrows as the pool widens, and on a box
with more cores it is the number to re-take.

**MAPPED WIDENS THE MARGIN RATHER THAN INVERTING IT.** Every figure above is a
filebuf; `STORE_MAP=1` is the path `--embed` and the server actually use, and
there the combination serves **2.6-4.6x** the ungated arm where on a filebuf it
was 0.9-4.9x. The gate ALONE stays a regression mapped too, at 0.1-0.5x.

**TWO THINGS ABOUT MEASURING THIS, both learned the expensive way.** The
suite's own `groups` and `httpd` cannot answer a question about the guard:
`groups` finishes twelve workers and 177 turns in **1.5 s** against a small
store, and `httpd` makes **82 shared acquisitions and zero stand-downs** in a
ten-second run, because most of it proves `httpd_answer/3` with no port open.
Both are green on 0.1.16 and identical to 0.1.12 across eighteen runs, and that
is a correctness result, not a load one. And **the noise floor of this rig is
3.4x on a median of five**: three byte-identical libraries, built by a runner
whose patch had silently failed, gave 547 / 1 850 / 881 lookups at six readers.
A ratio under ~3x taken from medians alone means nothing here; separate the
RANGES or do not claim it.

**AND THE HOLD THAT WAS LEFT IS THE SCHEDULER, NOT THE STORE** (cocolog#16,
ZiguratIP 0.1.19). About **one predicate fetch in 166** over the binary
protocol holds the exclusive streams guard for **9-22 ms** where the other 165
take 3-5 µs. It survived every fix in ZiguratIP#37 and predates all of them.
It is not code at all:

```
mvccs[te6c0] guard HELD   22779 us, on cpu 103 us
mvccs[te6c0] draw STALLED 22729 us, on cpu  56 us
```

**The thread is off CPU for 99.5 % of the hold** -- 22 676 µs of 22 779 -- and
the entropy draw inside `Statement`'s constructor is **99.8 % of that wall and
100 % of the off-CPU time**, with 47 µs of CPU spent anywhere else. So a thread
is PREEMPTED AT THE `read()` inside `Utility::random_bytes` while holding the
guard, and nothing runs for those milliseconds. `bt_cursor_equal_dep` takes the
guard and THEN builds a `Statement` in the same `letin*`, so the syscall is
inside the hold.

**SIX CANDIDATES DIED FIRST AND THE LIST IS THE USEFUL PART**, because every
one of them was a thing a counter could have confirmed and did not: an fsync
landing on ext4's journal (the backtrace says cursor, not sync); the mapped
store crossing a growth chunk (same stack); the DEPENDENT CALLBACK (**92 µs
across three holds**, which retired the `bt_emit_key` window before anybody
built it); COLD KEY READS (**zero misses in 72 000 reads, a 100 % hit rate**);
a long key walk (**one key**, and the "99 keys" that preceded it was a
cumulative counter read as a delta); and the draw BLOCKING, which the owner
killed by reading the source -- `/dev/urandom` holds a thread-local fd and does
not block after boot.

**A STOPWATCH CANNOT TELL A BLOCKING CALL FROM A DESCHEDULED ONE**, and that is
the hazard to carry away. `mvccs_wall_micros` is `CLOCK_REALTIME`, so a thread
preempted inside `read()` measures EXACTLY like a `read()` that blocked -- the
first timing said "the draw takes 12 603 µs" and would have been reported as a
blocking draw. It is the same shape as the note above about a call duration
against a guard-held time, wearing wall-against-CPU as a new coat. **Ask which
clock a number came from before believing what it says happened.**

**THE INSTRUMENT IS A BUILD FLAG, NOT A PATCH.** Since ZiguratIP 0.1.19
`MVCCS_DEBUG=warn` emits `guard HELD N us, on cpu N us` past a millisecond and
`draw STALLED N us, on cpu N us` for the draw, with `debug` carrying both per
acquisition; the CPU clock is `CLOCK_THREAD_CPUTIME_ID`. Nothing at the default
level. Both are suffixes, so a `grep -o 'guard HELD [0-9]* us'` written before
them still matches.

**WHAT IS ACTIONABLE HERE IS THE COUNT, NOT THE TAIL: cocolog makes 105
dependent-cursor lookups PER REQUEST** -- 41 600 over 400 requests, beside 57
exclusive guard acquisitions a request. A typical lookup is tiny (1.73 keys,
and only 1.9 % reach a dependent callback at all), so the cost is the number of
them. The way to survive a scheduler tail is to take the guard fewer times
rather than hold it for less, which makes this a question about
`parsi/02-procedures.parsi` and `COCOLOG::CLAUSES_OF`, not about the engine.

### cocolog#18: the 104 lookups, two engine branches refused, and what the cost is

**THE 104 IS 52 PREDICATES TIMES TWO DEPENDENT LEVELS, AND 51 OF THE 52 HAVE
NO ROWS.** The fetch hook is asked once per predicate (`coco_pred_ensure`), so
one request through `library(httpd)`'s pool asks for 52 distinct predicates --
51 of them machinery, one the page's own data. `cocolog::clauses` is indexed
`(kb, name, arity)` and `_COCOLOG::CLAUSES_OF_.cpp` -- what the Parsi compiler
emits, in `$ZIGURATIP_HOME/tmp` -- is **three nested `cursor_equal` lambdas**,
one per level. `engine-compat.hpp:273-282` sends the outer two through
`bt_cursor_equal_dep` with a `DepShim` and the innermost through
`bt_cursor_equal_multi` with ONE key, so 52 x 2 = **104 `bt_cursor_equal_dep`
calls a request** and one `bt_cursor_equal`.

**`bt_emit_key` RUNS PER KEY EMITTED, NOT PER CALL**, which is why the same
request opens only **53** dependent callbacks: the `kb` level finds its key on
all 52 fetches, the `name` level on the one predicate that has rows, and the
`arity` level is INNER and hands rows. 52 + 1 = 53, measured to the unit at
`MVCCS_DEBUG=debug`. The arithmetic of a fetch follows from it -- 51 fetches at
3 shared acquisitions and 1 at 5 -- and it is the number to re-derive before
reading any per-request figure here.

**AND `bt_eqchain_dcb` HAS A CALLER, JUST NOT ONE COCOLOG USES.** The engine's
own chain -- the multi-level descent that `bt_cursor_equal_multi` drives with a
full `ks[8]` -- is reached from `mvccs-lib.cicili:6074`, the generated table
macro's whole-tuple equality. Nothing the Parsi PROCEDURE compiler emits calls
it: every `_COCOLOG::*.cpp` reaches its index through `engine-compat.hpp`, and
outside `mvccs-lib.cicili` the only caller of `bt_cursor_equal_multi` in
ZiguratIP is `engine-compat.hpp:278`, always with one key, which short-circuits
at `bt_cursor_equal_multi:5119` before the chain. A branch that recognised the
chain pointer was therefore correct about a callback nobody sends.

**TWO ENGINE BRANCHES WERE BUILT TO CUT THE COST AND BOTH ARE REFUSED BY
MEASUREMENT.** Twelve workers, eight clients, fifteen seconds a point, three
alternating repeats, arms built whole and differing only in the engine commit:

| arm | exclusive a request | shared a request | W=12 |
|---|---|---|---|
| `0.1.20` (9326417) | 56 | 1 | 1.00 |
| `6298244` a window at every dependent callback | 3 | 160 | 0.92 |
| `618bb8f` the window only when a write arrives | 3 | **54** | **0.88** |

**CUTTING THE SHARED ACQUISITIONS BY TWO THIRDS MADE IT WORSE**, which is the
whole finding: the acquisitions were never the cost. By width, `618bb8f`
against `0.1.20`: **1.040, 0.997, 0.955, 0.879** at W=2/4/8/12, with the ranges
touching at 2 and 4 and SEPARATED at 8 (3408-3446 against 3533-3624) and 12
(3897-4012 against 4476-4538).

**THE GUARD WAIT IS 0.06 % OF A REQUEST AND ITS SIGN IS WRONG.** `probe_x_wait_us`
and `probe_s_wait_us`, three arms at W=12:

| arm | `x_wait` an acquisition | ALL guard wait a request |
|---|---|---|
| `0.1.20` | 0.88 us (0.75-1.00) | **49.7 us** -- the most, and the fastest |
| `6298244` | 2.30 us (1.41-3.57) | 24.0 us |
| `618bb8f` | 2.57 us (1.64-4.09) | 19.1 us |

It RISES per acquisition and master separates from both branches, so a writer
really does drain behind shared holders -- but the branches do not separate
from EACH OTHER, and the TOTAL falls as throughput falls. The deficits are
+2.55 and +3.27 ms a request against guard-wait changes of -25.7 and -30.7 us:
**a factor of about a hundred, with the sign inverted.** So the drain is real,
measurable, and cannot be the cost -- and removing all three of a request's
exclusive acquisitions (the read-only begin ZiguratIP#37 proposed) could
recover at most 7.7 us of 3 270.

**IT IS CPU, AND ON A SATURATED BOX THROUGHPUT IS ITS RECIPROCAL.** utime+stime
from `/proc/<pid>/stat` for the store and the cocolog server, and non-idle from
`/proc/stat`, per request, `618bb8f` against `0.1.20`:

| W | store CPU/req | machine CPU/req | throughput | 1 / machine CPU | machine busy |
|---|---|---|---|---|---|
| 2 | 0.954 | 0.976 | **1.053** | 1.025 | 59 % |
| 4 | 1.002 | 1.003 | **0.999** | 0.997 | 82 % |
| 8 | 1.139 | 1.050 | **0.944** | 0.952 | 91 % |
| 12 | **1.485** | **1.125** | **0.868** | 0.889 | 94 % |

Throughput is the reciprocal of machine CPU a request at every width, to within
two points, and the box is saturated from W=8 on -- so at the widths where this
shows, throughput is CPU efficiency and nothing else. The store carries the
larger PROPORTION (+48.5 % at W=12) and the cocolog server the rest; in absolute
milliseconds at W=12 it is +0.89 ms store and +0.75 ms server of +1.63 ms.

**AND ONE ENVIRONMENT VARIABLE SETTLES THE CAUSE, WITH NO BUILD.**
`ZIGURATIP_PARALLEL_READS=0` (`ziguratip/loadmemory.cpp:152-160`) withholds
`memory_reader_paths`, so `reader_eligible` answers 0 and every shared ask falls
back to the exclusive side. One library -- `618bb8f` -- both modes, W=12, three
alternating repeats:

| | parallel reads ON | OFF |
|---|---|---|
| requests / 15 s | 3775 (3722-3827) | **4376 (4369-4384)** |
| mean latency | 20.10 ms | **16.45 ms** |
| p95 | 36.80 ms | 31.75 ms |
| store CPU a request | 2.70 ms | **1.78 ms** |
| shared a request | 54.0 | **0.0** |
| exclusive a request | 3.0 | 57.0 |
| store minor faults a request | 0.026 | 0.012 |

`0.0` shared is the check that the variable did what it says, and the OFF arm
lands on master's profile exactly -- 57 exclusive, 1.78 ms of store CPU against
master's 1.84, 4376 requests against master's 4308-4349. **So the whole 3.3 ms
is the shared read path**, on the same binary and the same library.

**IT IS NOT THE MAPPINGS, AND WHAT KILLED THAT READING IS THE CLEANEST A/B IN
THIS FILE.** What stood here -- twelve `MAP_SHARED` VMAs of one file mean twelve
sets of translations where master's exclusive lookups walked one, so the cost is
per read and scales with the mappings actually reading -- was the only mechanism
nameable from source with the right shape, and it is REFUTED. ZiguratIP's
`reader-pool` branch (`b8f70ec`, 0.1.25) caps the private pairs with
`ZIGURATIP_READER_POOL=P`, so six arms run on ONE binary and ONE library
differing only in an environment variable: **no rebuild anywhere**, which retires
the stale-library hazard outright. W=12, eight clients, fifteen seconds, three
repeats, pre-warm off:

| arm | mappings | requests | range | store CPU/req | vs OFF |
|---|---|---|---|---|---|
| `PARALLEL_READS=0` | 0 | **4252** | 4111-4347 | 2.079 ms | 1.000 |
| pool unset | ~12 | 3853 | 3823-3882 | 2.653 ms | 0.906 |
| `POOL=12` | <=12 | 3898 | 3815-4015 | 2.642 ms | 0.917 |
| `POOL=4` | <=4 | 3904 | 3867-3933 | 2.616 ms | 0.918 |
| `POOL=2` | <=2 | 3835 | 3809-3880 | 2.701 ms | 0.902 |
| `POOL=1` | **1** | 3856 | 3835-3867 | 2.663 ms | 0.907 |

The ON/OFF separation reproduces -- every pool arm's MAXIMUM is below the OFF
arm's MINIMUM -- so the rig is detecting, and the ladder does not move: every cap
in 0.902-0.918, all five ranges overlapping, no ordering in P at all.

**P=1 MAKES IT A REFUTATION AND NOT A NULL RESULT.** `rpool_made` can only reach
the cap, so at P=1 exactly ONE pair exists for the whole process -- and the waits
prove the cap BOUND rather than being read and ignored: 37 waits at P=1 against
~35 000 checkouts, and zero at every larger cap. Twelve mappings 3853, one
mapping 3856. **And it bounds the fix that was proposed here.** "One mapping,
many positions" and P=1 have the same mapping count and differ only in
serialising the position, which costs 0.11 % of checkouts -- so the view would
land on 3856, not 4252, and `mapbuf::reserve`'s moving base need not be solved
at all.

**THE COST IS CONTENTION, AND THE EVIDENCE WAS IN THIS FILE'S OWN TABLE.** The
`618bb8f` ratio in the section above runs **0.954 / 1.002 / 1.139 / 1.485** at
W=2/4/8/12, and a fixed cost per read through a different streambuf is FLAT IN W
by construction -- so that column refuted "per read" before the ladder ran. What
was done with it instead was a DIVISION: +0.58 ms a request over ~54 lookups,
"~10.7 us a lookup", which looks like a rate and carries none of the evidence
that would make it one. Same family as the per-acquisition rate read against the
per-request total, wearing the count as a new coat. **Ask what a number would
look like if the hypothesis were FALSE, and check that against the columns you
already have.**

**THE CANDIDATE IS `BTCache.access`, and it is the owner's** (ZiguratIP#39): ONE
mutex for 4 096 node slots and 16 384 key slots, taken on every `bt_node_read`
and `bt_key_read` (`mvccs-lib.cicili:3566-3613`), two a descent level and ~312 a
request. Under the exclusive path the write lock serialised the readers before
they ever reached it; under a read lock there are eleven other threads on it. A
contended `pthread_mutex` costs a microsecond or two once it falls into the
futex, and 312 of them is the 0.58 ms -- an operation COUNT, not a division.
`cache-stripes` is the branch and **nothing here measures it yet**.

**AND THE INVERSION AT W=2 IS THE OTHER HYPOTHESIS'S PREDICTION NOW.** This file
has already offered two explanations for that one point -- the mapping count,
then saturation -- which is the tell that neither was load-bearing. Contention
gives it for free: two readers collide rarely, so the shared path pays almost
nothing and keeps what it saves on not serialising fifty-six exclusive holds.
**It is the point that discriminates, it costs one arm, and every future run of
this probe should take it.**

**SO THE SHARED LOOKUP IS A LOSS ON THIS ARRANGEMENT AT THIS WIDTH, AND THE
OWNER MEASURED IT A WIN ON SIXTEEN THREADS.** Both are measured, on different
boxes; this one has FOUR cores. The lever left on #18 was the 51 fetches a
request that find nothing -- and it was TAKEN, in the section below: `prewarm/1`
halves a pooled request and leaves nothing on this workload for the engine to
recover. What keeps #39 open is a workload whose lookups the pre-warm CANNOT
remove, which is exactly the program's own predicates.

### Three mechanisms dead, and the surprise is the CACHE (2026-09-18)

> **READ THE SECTION AFTER NEXT FIRST.** Everything refuted in these two
> sections was innocent, and the answer is not in the engine at all: on this
> box a cross-vCPU wakeup is a VM exit costing ~18 us, and every suspect here
> was only a way of making more threads runnable at once. The refutations are
> kept because the ORDER they died in is the useful part, and because each
> instrument is one to reuse -- but the cost was never any of them.

**WHAT SURVIVES HAS TO SCALE WITH TWO THINGS AT ONCE, and nothing named so far
does.** Three readings of the shared read path's 10 % are dead, each to a
different instrument, and the LIST is worth more than any one of them:

| the reading | what killed it |
|---|---|
| twelve mappings, one per reader thread | the `reader-pool` ladder: flat in P, and P=1 is ONE VMA |
| a fixed cost per read through a different streambuf | the W column, 0.954/1.002/1.139/1.485 -- flat in W by construction |
| the `BTCache` mutex twelve readers collide on | striping it 64 ways is flat, and REMOVING the cache WIDENS the gap |

So the cost scales with STREAM READS -- the no-cache arm below more than doubles
the deficit by multiplying them -- and with CONCURRENT READERS, which is the W
column. The one candidate that did both was the mapping count, and P=1 refuted
it. **The arm nobody has run is the only per-read variable left**: reader paths
set and the shared side granted exactly as now, with `hex_in`/`data_in` handing
back a private `filestream` instead of a `mapstream`. (`reader_ensure`'s own
comment says why that is not a DESIGN -- a private filebuf caches a get area and
answered zeros once against a fresh page's zero-fill -- but it is a measurement
arm, and it is the one variable neither `PARALLEL_READS` nor the pool nor the
stripes has moved.)

**THE SIX ARMS.** A = `8948241` with the ladder's pool at cap 0 (inert), B =
`fd4be7c` 0.1.26, `BTCache`'s one mutex made 64 stripes by slot. W=12, eight
clients, fifteen seconds, three alternating repeats, pre-warm off. The stripe
build was checked in the ARTEFACT first -- `engine.cpp` naming the stripes
fourteen times and no single-mutex `->access)` left:

| W=12 | requests | range | mean ms | sh/req | ex/req |
|---|---|---|---|---|---|
| one mutex, cache, reads ON | 3828 | 3774-3864 | 19.66 | 54.0 | 3.0 |
| one mutex, cache, reads OFF | **4293** | 4210-4417 | 16.98 | 0.0 | 57.0 |
| **64 stripes**, cache, ON | 3860 | 3748-4008 | 19.65 | 54.0 | 3.0 |
| 64 stripes, cache, OFF | 4332 | 4317-4346 | 16.79 | 0.0 | 57.0 |
| **no cache at all**, ON | 4000 | 3990-4011 | 18.70 | 54.0 | 3.0 |
| no cache at all, OFF | **5142** | 5072-5237 | 13.57 | 0.0 | 57.0 |

-- ON/OFF **0.8910** striped against **0.8915** on one mutex, four figures and
the ranges overlapping entirely, with the acquisition counts unchanged (54.0 and
3.0 either side, which is the check that striping changed only the lock). And
`MVCCS_NO_CACHE` -- one environment variable, `bt_cache_new` answering nil
(`mvccs-lib.cicili:3601-3605`) -- gives **0.7780**, the gap WIDER where it was
predicted to collapse, with the absolute deficit **466 requests a point with the
cache and 1142 without**. At W=2 it is 1.0250 and 1.0123, ON faster, ranges
overlapping: flat under striping as predicted, and not a confirmed inversion.

**AND THE B-TREE CACHE IS A NET LOSS ON A MAPPED STORE**, which neither side
predicted and which is the largest number in the run. Same library, same binary,
one environment variable:

| | with cache | no cache | |
|---|---|---|---|
| exclusive arm | 4293 | **5142** | **1.198x** |
| shared arm | 3828 | 4000 | 1.045x |

Ranges SEPARATED on both -- the no-cache exclusive minimum, 5072, is above the
cached maximum of 4417. Twenty per cent on the path cocolog actually runs, for
removing a cache whose hit rate cocolog#16 measured at **100 % over 72 000
reads**. The reading, marked as one: on a MAPPED store the miss path is a memory
read from the page cache, so the cache pays a lookup and a lock for something
that was nearly free. **Do not generalise it past this shape** -- a filebuf
store, cold pages or larger nodes are where it must earn its keep, and none of
those was measured.

**`triple-window` IS INERT HERE, AND IT IS MEASURED NOW RATHER THAN ARGUED.**
`c23a521` has `bt_emit_key` recognise the engine's own chain callback and open no
window for it. Rebasing it onto master is EMPTY by construction -- its whole diff
rewrites the window block `6298244` added, master has no such block, and the one
conflict hunk has master's side as the single line `(set cont ((-> em dcb) (-> em
user) (aof dep))))))`, so the only resolutions are "no-op" and "put `6298244`
back". And on the branch it was written for, a counter on the branch point says
it never fires: over 200 requests, **`probe_eqchain_yes` 0.00 a request,
`probe_eqchain_no` 53.00, shared 160.00, exclusive 3.00** -- `dependent-window`'s
profile to the unit, and that arm is already 0.92x. The cause is at the CALLER:
`engine-compat.hpp:279` passes `&DepShim<F>::call`, so `(-> em dcb)` is a C++
template static and never `bt_eqchain_dcb`. The 53.00 is the 52-plus-one
arithmetic confirming itself a second time.

**THREE THINGS BIT WHILE MEASURING THIS, and the first cost nothing only because
the number beside it was printed:**

* **A PATCH SCRIPT TOUCHES MORE THAN ONE FILE, AND REVERTING ONE OF THEM MAKES
  `git checkout` ABORT.** `patch4.py` edits `mvccs-lib.cicili` AND
  `contention-test.cpp`; only the first was reverted, the branch switch refused,
  and the rebuild that followed produced the WRONG ARM while reporting exit 0.
  What caught it is that the runner prints the library's md5 beside the expected
  one -- `a6f22cc9` where master is `865d490a`. **Print the md5 next to the one
  you expect, every time**, and `git checkout -- .` rather than naming files.
* **`pgrep -f 'make'` MATCHES THE SHELL THAT IS RUNNING IT.** A waiter written
  `until ! pgrep -f 'make'; do sleep 20; done` has "make" in its own command
  line, finds itself, and never exits -- it sat for nineteen minutes after the
  build it watched had finished. Match a pattern that cannot name the matcher
  (`stripes\.sh`, not a bare word), and break the loop when the thing you are
  watching is gone. Same family as `ps -eo args | grep -F 'serve(PORT,'` finding
  nothing.
* **A COLUMN ADDED TO THE LOG AND NOT TO THE PARSER READS EVERY ARM AS ZERO.**
  The runner gained a `W12` field and the awk kept `$4` for the request count,
  so it parsed the REP as a number and every mean came out 0 with `-nan` beside
  it. It is loud rather than silent, which is the only good thing about it: a
  parser that shifts quietly is the one to fear.

### Two more mechanisms dead, the cost is COUNTED, and then it turned out not to be per probe (2026-09-18, later)

**FIVE READINGS OF THE SHARED READ PATH AND THE CACHE ARE DEAD, AND THE TABLE IS
THE POINT.** Each died to its own instrument, three of them on branches the owner
built and this box ran:

| the reading | what killed it |
|---|---|
| twelve mappings, one a reader thread | the `reader-pool` ladder: flat in P, P=1 is ONE VMA |
| a fixed cost per read through a different streambuf | the W column, flat in W by construction |
| the `BTCache` mutex twelve readers collide on | 64 stripes flat, and REMOVING the cache widens the gap |
| the private `mapstream` ITSELF | `reader-file`: a private `filestream` recovers 12 % |
| the mutex falling into the kernel | `strace -c -f`: **3.67 futex a request cached, 4.81 uncached** |
| the cache table's 460 pages, under nested paging | `cache-hugepage`: one 2 MB page recovers **6.5 %** |

**`reader-file` (`1b662ad`, 0.1.27), W=12, pre-warm off, three repeats:**
`PARALLEL_READS=0` **4464** (4403-4547), private `mapstream` 3974 (3950-3996),
private `filestream` **4026** (3960-4077) -- FILE/MAP **1.0133** with the ranges
overlapping, both separated from OFF, and the acquisition counts identical at
54.0 shared and 3.0 exclusive. In store CPU the MAP->OFF gap is 0.743 ms a
request and FILE recovers 0.091 of it.

**`cache-hugepage` (`26bd2e7`, 0.1.28):** `cache` 4230 at 2.053 ms, **huge** 4259
at 2.001 ms with `AnonHugePages` at exactly **2048 kB**, `nocache` **4964** at
1.240 ms with the ranges separated. The advice TOOK and nothing moved: 6.5 % of
the gap.

**AND THE DENOMINATOR EVERY PER-PROBE FIGURE DIVIDED BY IS COUNTED NOW.**
Counters at the top of `bt_node_read` and `bt_key_read` and in each hit branch,
master, three repeats:

| arm | node reads/req | key reads/req | total | hit rate |
|---|---|---|---|---|
| cache | 105.0 | **558.0** | **663.0** | **100.00 %** |
| `MVCCS_NO_CACHE` | 105.0 | 558.0 | 663.0 | 0.00 % |
| pre-warm ON | 3.0 | 12.0 | **15.0** | 100.00 % |

-- **663, where the estimates were ~312 and ~600**, so the reads a lookup is
**6.4 and not 3**, and the shape nobody guessed is that **KEY reads are 558 of
the 663**: a three-level descent reads one node and five keys. Both cross-checks
hold -- the no-cache arm does the IDENTICAL 663 at a 0 % hit rate, so the count
is the WORKLOAD's and not the cache's, and the pre-warm arm does 15, which is
44x fewer for 52x fewer fetches.

**AND THE PER-PROBE FRAMING IS WRONG, WHICH THREE FREE CHECKS SETTLED AN HOUR
LATER.** It looked like 1.15 us a probe -- 1.838 ms against 1.075 over 663
probes, and at a 100 % hit rate `bt_node_read` IS `bt_cache_node_get`, so the
whole of it seemed to sit in one function whose visible work is ~50 ns. **It is
not per probe at all.** None of the three checks needed a build:

| the check | what it said |
|---|---|
| `utime` beside `stime` at W=12 | **+0.050 ms user, +0.962 ms SYSTEM** -- 95 % kernel |
| the same pair at **`workers(1)`** | cache **0.24 ms a request CHEAPER**, 4 % faster |
| 30 stack samples an arm | 2377 futex-wait frames against 2391 -- no difference |

**AT ONE WORKER THE CACHE COSTS NOTHING.** The whole ~1 ms appears only under
concurrency, so there is no per-probe cost to explain: the probe is free when one
thread makes it. Every per-probe figure this file and ZiguratIP#40 carried --
3.6 us, then 1.8, then 1.15 -- was **a per-request total divided by a count that
has nothing to do with where the time goes**, which is the same error in a fourth
coat. The count was worth taking anyway; what it could not do was locate
anything.

**"NOT REACHING FUTEX" IS NOT "NOT IN THE KERNEL", AND THIS FILE PUBLISHED THE
SECOND FROM THE FIRST.** The strace arm showed the mutex staying in user space
and the conclusion drawn was "the cost is user-space CPU" -- and it is 95 %
system time. A refutation of one mechanism is not a positive claim about where
the cost is; it only removes a candidate.

**THE FUTEX REFUTATION ITSELF SURVIVES, on an instrument that cannot be accused
of suppressing contention.** `strace -c -f` halves throughput and serialises
threads, so its counts were suspect in exactly the direction that mattered.
Context switches summed over every thread in `/proc/PID/task/*/status`, with no
ptrace: **140.7 voluntary a request cached against 143.0 uncached**, marginally
LOWER with the cache, minor faults 0.014 against 0.012 and negligible either way.
So: kernel time, only under concurrency, with no more syscalls, no more blocking
and no more faults than the arm without it. **No sixth mechanism is proposed
here** -- that register is 0 for 3.

**TWO THINGS ABOUT THE INSTRUMENTS, both of which cost a run:**

* **A TOP-FRAME HISTOGRAM OF A POOL MEASURES WAITING.** Twelve workers on four
  cores are nearly all blocked at any instant, so 2 377 of 2 940 frames are
  `__futex_abstimed_wait_common64` on BOTH arms and exactly ONE sample an arm
  landed in engine code. Sample running threads only, or take hundreds.
* **`utime`/`stime` FROM `/proc` IS TICK-SAMPLED, NOT MEASURED.** The kernel
  charges a whole tick to whichever mode it catches the CPU in. At 0.5 CPU-seconds
  a second over fifteen seconds the sample is large and the arms differ by 2.5x,
  so the split is almost certainly real -- but it is a SAMPLE, and a number
  carrying a conclusion should be named as one. Same family as asking which clock
  a figure came from.

**AND THIS BOX DRIFTS ~20 %, WHICH RETIRES AN ERROR BAR THIS FILE PUBLISHED.**
Cached store CPU a request, same box, same protocol, three builds in one day:
**2.252, 2.053, 1.838 ms**, with `nocache/cache` at **1.238, 1.173, 1.148**. The
counter build should be the SLOWEST of the three and is the fastest, so it is not
instrumentation. The honest form of the cache claim is **1.15-1.24x, measured
three times**, and the rule that follows is **a within-run pair or nothing**: an
arm that does not carry its own control beside it cannot be compared to a figure
from three hours ago.

**AND THE OWNER'S BOX WANTS THE OPPOSITE, WHICH IS THE REAL DISPOSITION.** On a
16-thread Mac the cache WINS -- 7.2x at one reader over a filebuf store, and
**2.6x mapped**, where it loses 1.24x here. So it is per-MACHINE, not per store
kind, "skip the cache when mapped" is withdrawn, and `MVCCS_NO_CACHE` staying a
knob is the right shape. ZiguratIP#40 carries it.

**FOUR THINGS BIT, AND THE FIRST IS THE ONE THAT NEARLY PUBLISHED A FALSE
RESULT:**

* **A CHECK YOU READ AFTERWARDS IS NOT A CHECK THAT STOPS YOU.** The first
  `cache-hugepage` build measured the WRONG ENGINE and reported exit 0: two files
  were still patched from the previous arm, `git checkout` aborted, `make`
  rebuilt the old engine, and nine points ran against a binary with no hugepage
  knob in it -- which would have read as a clean refutation of the hypothesis it
  was testing. The md5 and `grep -c KNOB engine.cpp` were both printed and both
  wrong, and they only caught it because somebody read them. **The re-run makes
  them a GATE**: the arms print `REFUSING TO RUN` and exit unless the md5 differs
  from the previous library and every symbol is in the emitted C++. And the rule
  this file already carried -- `git checkout -- .` rather than naming files -- is
  the rule that was broken, by the session that wrote it down that afternoon.
* **A KNOB THAT TESTS `!= nil` IS ON WHEN IT IS EMPTY.** `MVCCS_NO_CACHE` and
  `MVCCS_CACHE_HUGEPAGE` both do, so `env MVCCS_NO_CACHE= …` turns the thing ON
  while reading as off -- the owner lost twelve arms to it. `${VAR:+NAME=1}`
  omits the assignment entirely and is the form to use.
* **EVERY STREAMBUF OR ALLOCATION ARM NEEDS A POSITIVE CHECK, because "near the
  other arm" and "the knob did nothing" are the same picture.** `/proc/PID/maps`
  is it for the reader (**40 read-only store mappings under `mapstream`, ZERO
  under `filestream`**, the canonical pair left in both) and `AnonHugePages` in
  `smaps_rollup` for the huge page (**2048 kB against 0**). The first attempt at
  the mapping check grepped `data.bin|hexmap.bin` and returned 0 on EVERY arm,
  because **the store's files are named `data` and `hexmap`** -- which this file
  also had wrong, in two places, now corrected.
* **AND THE PARSER SHIFTED TWICE, in both directions.** A `W12` column added to
  the log and not to the awk read the REP as the request count; the next runner
  dropped that column and the awk still skipped it. Every arm came out 0 with
  `-nan` beside it both times, which is the only good thing about it.

### AND IT WAS THE BOX: a cross-vCPU wakeup costs ~18 us here, CONFIRMED by pinning (2026-09-18/19, last)

**`/proc/interrupts` NAMED IT IN ONE READ, AFTER SIX MECHANISMS DIED.** The
question stopped being "what does the cache cost" the moment the W=1 arm showed
it costing nothing, and became "what does adding threads cost". Interrupts
summed over all four vCPUs and differenced across a point answer it. Three
pairs, two issues, two engines:

| pair | d utime | d stime | d (RES+CAL) a request | **us an extra IPI** |
|---|---|---|---|---|
| cache vs `MVCCS_NO_CACHE` | **+0.003 ms** | **+0.790 ms** | 45.7 | **17.3** |
| the same, longer window | -0.005 ms | **+1.046 ms** | 58.9 | **17.8** |
| **shared vs exclusive lookups** | **-0.002 ms** | **+0.272 ms** | 14.1 | **19.3** |

**User time is identical in all three -- to three decimals, and TWICE WITH THE
WRONG SIGN.** Every difference is system time, and in each pair it divides by
the extra interrupts to the same number. That number is a VM exit on a
Firecracker guest.

**AND THE SELECTIVITY IS WHAT MAKES IT A FINDING RATHER THAN A CORRELATION.**
`RES` 44.39 a request against 5.23 -- **8.5x** -- and `CAL` 7.94 against 1.37;
but `TLB` 0.62 against 0.54 and the local timer 3.61 against 3.03. Only the two
classes that mean *a wakeup landed on another vCPU* move at all.

**SO ZiguratIP#39 AND #40 ARE ONE PHENOMENON, AND NEITHER SUSPECT WAS A CAUSE.**
The shared read path's cost is 101 % system time at the same price an IPI. The
cache's is 100 %. Mappings, streams, acquisitions, the cache mutex, the cache
table's pages and the futex path were all innocent because **none of them was
ever the thing being paid for** -- each is only a way of making more threads
runnable at once. It also explains the W=1 result with no new assumption: one
worker, no other vCPU to wake, no exit, and the cache is a cache again.

**WHICH MEANS A CONCURRENCY NUMBER TAKEN ON THIS BOX IS A NUMBER ABOUT A
MICROVM.** The kernel is `6.18.44-fc-v33`, the hypervisor flag is set, there are
four vCPUs. The owner's sixteen-thread Mac measures the cache a **2.6x WIN**
mapped and the shared lookup a win too -- the same code, the opposite sign, and
now a reason rather than a shrug. **Before reporting any pooled or threaded
figure from here as a property of the engine, take the `utime`/`stime` split and
the `RES` row**; if the difference is system time and tracks IPIs, it is this
box. The suite runs here too.

**THE NUMBER THAT DID NOT FIT FITS NOW, AND THE ANSWER IS THE GUEST'S IDLE
PATH.** Voluntary context switches are EQUAL -- 140.7 a request cached against
143.0, measured with no ptrace -- while the reschedule IPIs are 8.5x. Same
blocking, far more of it crossing a vCPU boundary. **A wakeup costs an IPI in
two cases: the target vCPU is running something else and must be told to
reschedule, or it is IDLE AND MUST BE BROUGHT OUT OF `HLT`** -- and on a guest
the second is a VM exit. A Linux guest normally polls before it halts
(`cpuidle-haltpoll`), and a wakeup landing inside that window needs no IPI at
all. **This box has no such window:**

| | |
|---|---|
| `/sys/devices/system/cpu/cpuidle/current_driver` | **`none`** |
| `cpu0/cpuidle/state*` | **no states at all** |
| `current_governor` | `menu` |
| `haltpoll` governor module | loaded, `guest_halt_poll_ns` 200000, UNUSED |
| `/proc/cmdline` | nothing about idle |

No driver, so no idle states, so nothing polls: every idle vCPU is halted and
every wakeup to one is an exit. **So the arm whose threads finish FASTER leaves
vCPUs idle longer, halts them, and pays to wake them** -- which is why the cache,
a win on one thread, is a loss on twelve. (The mechanism is the owner's;
the reads are from here. The knob he proposed cannot be turned: `guest_halt_poll_ns`
is inert with no driver, and `idle=poll` is a kernel command line needing a reboot.)

**AND PINNING THE STORE TO ONE vCPU PROVES IT, WITH NO REBOOT.** If the cost is
cross-vCPU wakeups, removing them by construction removes the cost. Four arms,
`cache`/`nocache` x free/pinned, W=12, pre-warm off, two repeats, one library
behind an md5 gate, `taskset -cp` read off the live pid:

| arm | affinity | requests | utime/req | stime/req | RES/req |
|---|---|---|---|---|---|
| cache, free | 0-3 | 4624 | 0.421 ms | **1.440 ms** | **49.0** |
| nocache, free | 0-3 | **5510** | 0.467 ms | **0.632 ms** | **5.5** |
| cache, **pinned** | **0** | **3682** | **0.361 ms** | 2.109 ms | 70.7 |
| nocache, pinned | **0** | 3598 | 0.585 ms | 2.103 ms | 68.1 |

-- free, the cache costs **+0.809 ms of system time and +43.5 IPIs a request**,
the control reproducing to the figure with the ranges not touching. **Pinned it
costs +0.006 ms and +2.6: the penalty falls 99.3 %.** And with the wakeups gone
the cache is visibly a cache -- pinned it SAVES 0.224 ms of user time a request
and runs 2.3 % faster, ranges separated, which is the W=1 result reproduced at
twelve workers by removing only the cross-vCPU path.

**TWO THINGS THAT TABLE DOES NOT LICENSE.** `RES` is SYSTEM-WIDE, not per
process, so the pinned arms' higher absolute levels are the cocolog server and
the clients still running on the other three vCPUs -- only the within-arm
DIFFERENCE is a measurement, and that is the column that collapses. And pinning
costs a fifth of the throughput, so nothing compares across the free/pinned
boundary.

**AND THE RUN BEFORE IT WAS VOID, WHICH IS THE THIRD TIME THIS EXACT HAZARD HAS
BITTEN IN ONE DAY.** The first attempt ran against `9afee649` -- the
`reader-file` library left installed by an earlier arm, whose dependent lookups
take the shared side -- and its free arms showed **NO cache/nocache gap at all**
(4225/4067 against 4083/4051). That is what a failed control looks like, and
eight arms were thrown away rather than read. The runner had PRINTED that md5 in
its own header. **Printing the md5 is not the check; comparing it is** -- the
gate now reads the installed library, compares it to the expected one, and exits
with `REFUSING TO RUN` otherwise. First time in the day's chain that this class
of failure was caught before a number left the box, and the only reason it was
caught is that the FREE arms exist to reproduce a known result.

**AND A CONTAINER RESTART MOVED THE KERNEL UNDER THE EXPERIMENT**, `6.18.44-fc-v33`
to `-v37`, between the idle reads and the pinning run. The reads were TAKEN AGAIN
before the earlier finding was trusted -- driver `none`, no states, governor
`menu`, four vCPUs, identical. **A box that can change under a measurement is one
whose environment reads have a shelf life**, and the cheap ones are worth
re-taking rather than assuming.

**THE INSTRUMENTS, IN THE ORDER THEY EARNED THEIR PLACE:**

* **`/proc/interrupts`, differenced across a point.** Free, needs nothing
  installed, and it is the only one that named a cause. `RES`, `CAL`, `TLB` and
  `LOC` summed per vCPU; the ratio between two arms is the reading.
* **`utime` beside `stime`, never summed.** Asked for twice on the issue before
  it was taken, free, and it overturned a published conclusion the moment it
  was. **Fields 14 and 15 -- do not add them together.**
* **Context switches from `/proc/PID/task/*/status`**, summed over every thread.
  Unperturbed, where `strace -c -f` halves throughput and serialises threads --
  which suppresses contention in exactly the direction a blocking hypothesis
  needs.
* **`/proc/<tid>/stack` for threads in state `R`** is the right way to see
  kernel time, and MY USE OF IT WAS WRONG TWICE: the loop was never redirected
  to its file, and reading `stat` then `stack` is RACY -- a thread marked `R`
  has usually blocked by the time its stack is read, so the dump fills with
  `sk_wait_data` and `futex_do_wait` and says nothing. A gdb histogram of ALL
  threads is worse still: twelve workers on four cores are nearly all blocked at
  any instant, so 2 377 of 2 940 frames were futex waits on BOTH arms.

**AND ONE CONFIGURATION CAVEAT ON THE #39 PAIR.** It ran the `reader-file`
library against a schema built for a different engine. It loaded, smoke-tested
and served four thousand requests an arm, so the WITHIN-PAIR comparison is sound
-- one library, one schema, one environment variable -- but its absolute numbers
are not comparable to the ladder in the section above (1.797 ms here against
1.826 there on the exclusive arm, 2.068 against 2.569 on the shared). A swap
without `make schema` is a valid pair and an invalid level.

### And the lever WAS the fetches: `prewarm/1` (1.2.17)

**FIFTY-TWO PREDICATES A REQUEST, AND FIFTY-ONE OF THEM CANNOT BE IN THE
DATABASE.** Traced over the binary protocol on a page that reads one row: 27 of
`library(http)`, 18 of `library(httpd)`, six tier-1 (`append/3`,
`atomic_list_concat/2`, `length/2`, `member/2`, `phrase/3`, `'$dcg_list'/1`) and
`pp_stock/2`, the page's own. Every one of the 51 is a MODULE's, so its clauses
are muted and never write through -- and the store asks anyway, because
`coco_assert` leaves `loaded` at 0 on a muted assert on purpose, so that a first
REAL call still fetches "as it would have without the module". **That is the
line that cost 51 round trips a request**, and it is right in a `--local`
process and wrong in a pool.

**WHAT IT COST, MEASURED BEFORE ANYTHING WAS BUILT**: 6.06 ms of a 10.47 ms
request inside the fetch hook, 117 us a fetch -- against **0.99 ms** for the
same page on a store that persists (`workers(0)`). So a pooled request was
**twelve times** the same page's cost on a warm store, and 58 % of it was the
hook.

**`prewarm/1` ASKS ONCE AND REMEMBERS THE ABSENCE.** It walks the store's
library predicates, fetches each, and records the (name, arity) of every one the
backend added NOTHING to -- keyed on the name TEXT, because an atom id belongs
to one machine and every `run_isolated/2` proof has its own. A later store's
muted assert consults that table and sets `loaded` itself. `coco_pred_ensure`
records the "nothing came back" in a per-predicate `empty_fetch`, which is the
only moment the difference can be seen: afterwards a module's predicate has its
own clauses either way. `library(httpd)`'s `httpd_serve/3` calls it before the
pool starts.

**ONLY THE ABSENCE, AND ONLY A MODULE'S.** A predicate the backend DID have rows
for stays out of the table and goes on being fetched by every store -- proved
with a `http_header/3` row written by a process that does not load
`library(http)` at all. The program's own predicates are never in it, because
only a muted assert sets `library`. **The staleness contract is therefore
exactly one sentence**: another process writing into a predicate a MODULE
defines will not be seen here. And it carries the module registry's own rule --
**PRE-WARM BEFORE YOU SPAWN**, because the table is written once and then read
by every worker thread with no lock, the same as `use_module`'s registry.

**MEASURED WITH ONE BINARY AND THE CALL IN OR OUT OF `library(httpd)`**, three
alternating repeats, ranges not touching:

| workers | prewarm off | prewarm on | |
|---|---|---|---|
| 1 | 10.35 10.02 10.66 | **5.14 4.96 4.97** | **2.06x** |
| 4 | 10.76 10.08 10.43 | **5.04 5.16 5.37** | **2.01x** |

-- and fetches a request go **52 to 1**, the one left being the page's own data.
Under load at twelve workers and eight clients it is **4282 to 5551 requests a
fifteen-second point, 1.30x**: the single-client figure is latency, the
saturated one is what a CPU-bound box can do with the work removed.

**`library(cowork)` DELIBERATELY DOES NOT CALL IT, and the measurement is why.**
Added to `cowork_start/3` it made a crew **4-6x SLOWER** -- a crew of four 13 ms
to 51, a crew of twelve 21 ms to 65, start plus one real job each -- and was
reverted before it shipped. A crew worker's store lives as long as the WORKER
and is filled lazily, so it asks only about the predicates its own jobs call,
once: about fifteen a worker, so a crew of twelve makes ~180 fetches where the
pre-warm buys 437. An httpd pool is the other shape -- a fresh store per
REQUEST asks again every time -- so the ~51 ms the call costs is repaid in about
nine requests. **THE RULE IS THE FETCHES RECURRING, NOT THE THREADS EXISTING**,
and this file's first draft of it said the opposite.

**AND IT RETIRED ZiguratIP#39's URGENCY -- BUT NOT BY CONFIRMING ITS MECHANISM,
which this file claimed and the ladder above refutes.** Re-running the
`PARALLEL_READS` A/B on 1.2.17, same engine (`618bb8f`) on every arm, W=12:

| pre-warm | shared a request | store CPU a request | the shared read path costs |
|---|---|---|---|
| off | 54.0 | 2.73 ms | **1.115x**, ranges SEPARATED |
| on | **3.0** | **0.35 ms** | **1.009x**, ranges overlapping |

Cutting the lookups EIGHTEENFOLD cut the penalty about THIRTEENFOLD, where the
acquisition count never gave one -- 160 against 54 moved nothing. **What that
dose-response proves is that the cost lives IN THE LOOKUPS, and it cannot choose
between a per-read cost and a per-lookup contention**: `BTCache.access` is taken
per node read and per key read, so cutting the lookups cuts the collisions by
the same factor. A dose-response separates the two hypotheses it was built
against and nothing else, and the one it was not built against is the one that
survived. There is still nothing left to recover on this workload: the 12 % is
reproducible only with the pre-warm off, which is now a configuration nobody
runs.

**ONE DEFECT WAS FOUND ON THE WAY, AND IS FIXED IN 1.2.18.** `assertz` into a
predicate a MODULE defines wrote the MODULE's own clauses into the knowledge
base, because the backend rewrites a dirty predicate WHOLESALE and the store
holds the library's clauses beside the program's: after
`assertz(member(foo,[a]))` the kb held THREE rows -- the program's clause and
both of `library(lists)`'s -- and every later process fetched those two ON TOP
of the copy its own modules had already given it, so
`findall(X, member(X,[p,q]), L)` answered `[p,q,q,p,q,q]`. It reproduced with
the pre-warm removed, so it was older than it.

**THE MARK HAD TO BE PER CLAUSE, AND NEITHER FIELD THAT LOOKED RIGHT WOULD DO.**
`coco_pred`'s `library` flag is per PREDICATE, and the moment a program asserts
into `member/2` the predicate holds both kinds. `origins` is per clause and
still cannot tell them apart -- measured, not assumed: a tier-2 library is
consulted from a real file and its clauses carry that file's path exactly as a
program's do (`library(http)`'s own `http_header/3` leaked the same way), while
a compiled-in module's carry 0 exactly as a runtime `assertz` does. What is
common to every library clause and to no program clause is that the store was
MUTED when it arrived, so `coco_pred` gained a `muted` array parallel to
`clauses`, `keys`, `origins` and `chain`, and `coco_zg_sync_pred` skips those.

**SKIPPED ON BOTH SIDES OF THE WINDOW.** The flush is a pipeline -- up to 128
calls sent before the first is answered -- so a clause that is not sent has no
answer to wait for, and skipping on the send side alone drifts the two counters
apart by exactly the muted clauses between them.

**IT IS FORWARD-ONLY, AND THAT IS NOT LAZINESS.** A base written by an older
binary keeps its duplicates and does NOT heal on the next write: the fetch
brings those rows into the store as ordinary clauses, and by then nothing can
tell them from rows a program meant to write. `cocolog forget NAME ARITY`
cleans one predicate -- measured, `forgot 4 clause(s) of member/2`, and the
next assert stays clean -- and a whole-base `forget` cleans the lot.
`test/reconsult.pl` is the case, in the arrangement where it bites (`--embed`,
so it never SKIPs), and it checks the SYMPTOM a program would meet rather than
the row count: `member(X,[p,q])` answering two solutions, the program's own
clause still in the store, and one row for the tier-2 predicate. Both halves go
RED on a binary without the fix.

**FIVE THINGS THAT BIT WHILE MEASURING THIS, and the first is the one to carry
away:**

* **A PER-ACQUISITION RATE AND A PER-REQUEST TOTAL ANSWER DIFFERENT QUESTIONS.**
  `probe_x_wait_us` rose per acquisition and FELL per request, and only the
  second bears on throughput. A hypothesis confirmed in its ordering and refuted
  in its quantity is refuted. This is the same hazard as guard-held time against
  call duration, and as the cumulative counter read as a delta in cocolog#16.
* **THE BOX HAS FOUR CORES AND W=12 OVERSUBSCRIBES IT.** Store CPU a request
  FALLS at W=12 on both arms (3.1 ms to 1.8-2.7) -- that is the store being
  served less CPU, not asking for less, and reading it as efficiency inverts the
  finding. Take the per-width RATIO, which both arms pay equally.
* **`ps -eo args | grep -F 'serve(PORT,'` FINDS NOTHING.** A whole CPU run came
  back with a zero column for the server process. `lsof -iTCP:PORT -sTCP:LISTEN -t`
  is the exact answer and is what the probes use now.
* **A DERIVED FIGURE IS NOT A MEASUREMENT.** Worker-wall a request taken as
  clients x seconds / requests is a division, not a clock; the probes time each
  request with curl's `%{time_total}` and report mean and p95.
* **`perf` IS NOT INSTALLED HERE** and the kernel is a custom one, so
  `dTLB-load-misses` cannot be taken on this box. `minflt` from `/proc` is the
  proxy that was available, and it answered the question it could: the mappings
  are stable.

**An index changed in `parsi/01-schema.parsi` comes up EMPTY on a live
SERVER store, and the old trees stay as orphan pages.** The server attaches
an index it has no catalogue record for with an empty root and maps nothing
that was already there, so every read through it answers nothing -- and a
`forget` through it deletes nothing, leaving the rows live and invisible.
`cocolog vacuum` right after the restart, before any base is touched: its
TRUNCATE rebuilds every index from the live rows. (Learned changing
`cocolog::clauses` from two single-column indexes to the composite
`(kb, name)`, on the server.) **Re-run for `(kb, name)` to `(kb, name,
arity)` on 2026-09-05**: after the restart and the vacuum, rows written under
the old index answer through the new one -- `tls_test` 1 predicate,
`groups_test` 4 -- and fresh rows at two arities round-trip through a second
process. Whether the vacuum was NECESSARY on the Cicili engine was not
captured (the non-empty bases were probed only after it), so keep running it.

**`--embed` DOES NOT HAVE THIS HAZARD ANY MORE.** Since ZiguratIP `b290cc6`
`_attach` answers 1 the first time a store meets an index and `_rebuild`
fills the tree from the rows already there, inside the open transaction the
first commit settles -- so a store written before an index existed gets it
at its next open, with nothing to run first. Measured: a 20 000-row store
made before the `(kb, name)` index answers every row through it on first
open, a present key is found, an absent one stays absent, and the first call
of a predicate costs **0.35 ms for fifty** where it cost 474 ms -- flat from
an empty store to 10 MB, because the walk is the index and not the table.
The index is `(kb, name, arity)` -- the arity joined it the same day, because
over `(kb, name)` a name at two arities walked the other arity's rows:
`shared/2` beside 20 000 `shared/1` cost 21.3 ms on its first call and costs
0.027 ms, and a store from before the change rebuilt the three-level tree at
its first open.

**A STORE IS IN THE WRITING MACHINE'S BYTE ORDER, AND IT DOES NOT TRAVEL**
(ZiguratIP 0.1.6, cocolog `36fde5e`). The store's streams are `hbostream` --
HOST order, a raw eight-byte read with no swap -- while the PROTOCOL is
`nbostream` and normalised. So the wire crosses an endian boundary and the
file does not, and the reason it needed saying is that a foreign store
**opens**: the page list is built from twenty-byte hash keys, which are byte
arrays and read the same everywhere. It is every `int64` after that -- stamps,
ids, addresses -- which comes back reversed, and the first thing the process
does is write more of it. That is not an error, it is nonsense.

A store therefore keeps a mark beside it, `byteorder.bin`, eight bytes holding
`0x0123456789ABCDEF` written in host order; `ce_engine_open` reads it through
`store_order_check` BEFORE `memory_open`, and a refusal arrives on the path a
missing store already used. A fresh store marks itself, and an existing
unmarked one is stamped at its next open with the opening machine's order --
a guess, and the engine's README says so, because nothing can know where bytes
written before the mark came from. Exercised here on all four paths:

| the mark | what happens |
|---|---|
| absent | written, store opens |
| this machine's | opens |
| the magic **reversed** | refused: *written on a machine of the OTHER byte order* |
| neither, e.g. `0xAA…` | refused: *the file is damaged* |
| shorter than 8 bytes | refused: *the store cannot be judged either way* |

-- and restoring the mark opens the same store again with every row in it, so
the check reads and does not repair. **A refusal EXITS 1 with an empty stdout
and the reason on stderr**, exactly as a store directory that does not exist
does, which is the property a script needs -- and the same one the silent Zeytun
fetch in the `--https` section below failed to have.

**`make schema` COPIES THE EMITTED TABLES INTO `$ZIGURATIP/MVCCS-cicili/generated/`**,
which used to be a step done by hand and then forgotten: parsi writes each
table as `_COCOLOG::CLAUSES_.cicili` into `$ZIGURATIP_HOME/ld`, the embedded
engine imports `cocolog-clauses.cicili` from `generated/` (a symlink from
`embed/generated`), and a schema change that reached the server's objects
left the embedded engine on the previous tables. `parsi/build.sh` does the
copy under the one rule that maps every name, and needs `$ZIGURATIP` set.

**A THREE-LEVEL COMPOSITE BROKE THE WHERE COMPILER, and it is fixed in
ZiguratIP.** A predicate binding only the leading column has every level
below it walked whole; the compiler wrote those walks as siblings, which
compiles for two levels and not for three -- `make schema` died in
`predicates_of` with `no matching function for call to object of type
lambda`. `Test/run-keys-e2e.sh` there carries the `demo::triple` proof.

**A PAGE and a PROCEDURE of the same name are ONE compiled object**, and pages
compile last. `cocolog::predicates` was both, so the procedure's `.so` was
silently replaced and every call to it died with `undefined symbol: call`. That
is why the procedures are `predicates_of` and `props_of`. Check
`parsi/03-pages.parsi` before naming anything in `parsi/02-procedures.parsi`.

**A refused forget WAS a disconnected writer's debris — both causes are
fixed in ZiguratIP now, and the story stays here because the diagnosis cost
two sessions.** `lock wait timeout` on every touch of ONE knowledge base —
while every other base answered — meant a transaction nobody would finish
still held its row locks: the server never rolled back a disconnected
connection's transaction (`handle_client` in ZiguratIP's `loadzigurat.cpp`
left its loop with no rollback on any error path, and logged "Transaction
Closed" on the way out regardless), and the pooled thread kept the id
registered as live, so the lazy stale-lock breaker RIGHTLY refused to break
it. A server restart always cleared it — startup recovery rolls staged work
back; a session spent believing the wedge survived restarts and vacuums,
because every diagnostic forget was itself timing out mid-grind and
re-wedging the base it was diagnosing. What made the debris was a client
giving up mid-write, and the one-DELETE `forget_all` invited exactly that:
~10ms a row, ~30s for a 3 200-clause base on a FRESH store (CivV's rung-6
match). Both halves are now fixed at the source — see the section below —
so against a patched server a vanished client's transaction dies with its
connection, the whole-base forget is ONE atomic call again (a brief
predicate-at-a-time chunking of `cmd_forget` lived between diagnosis and
fix, and is retired), and a `lock wait timeout` today means a LIVE
contending writer, or a server old enough to predate the patch.
`test/vacuum.pl` pins forget's contract: count, emptiness with
declarations, idempotence.

### Four findings about ZiguratIP, diagnosed and then APPLIED

The first two were recorded here as proposals while ZiguratIP was frozen; the
owner unfroze it and both landed (MVCCS-cicili/mvccs-lib.cicili and
ziguratip/loadzigurat.cpp). The third was measured here and diagnosed there:

* **A vanished client's transaction rolls back with its connection.**
  `ConnectionScope`'s destructor — the one place stack unwinding guarantees
  on every way out of a handler, an error reply throwing into a dead stream
  included — now calls `rollback_transaction`. A transaction the client
  committed has nothing staged, so the clean path is a no-op. Verified: a
  20 000-clause consult killed mid-write leaves a clean base and the very
  next forget runs in 43ms where it used to wait its whole lock timeout.
* **One DELETE's unlinks were quadratic in the index value chain, and the
  UNMAP RESUME MARK made them one walk per chain.** `bt_unmap` finds a
  row's index entry by walking the key's value chain from the head — and a
  mass DELETE's i-th row walked past the i−1 entries the same statement had
  already staged dead, at two indexes per clause row. Entries join a chain
  at its HEAD, so any two rows sit in every index's chain in the same
  relative order they were inserted, and a scan deletes in chain order
  whichever index it rides — so each unmap now remembers where it ended,
  per (transaction, index, key), and the next one on that key starts there.
  The mark is a HINT and never an answer: a miss falls back to the head, so
  it can only save work, never lose an entry; and it is transaction-stamped
  because only an address this transaction itself staged dead is pinned
  against TRUNCATE. Measured: the same 3 227-clause whole-base forget went
  from 31s to **1.59s**. The engine's own gauntlet (consumer, contention,
  carryover, ageing) stays green.
* **The streams guard was not writer-preferring, whatever the rwlock was
  told.** Measured here: 99.996 % of shared grants made with a writer already
  queued, and a writer granted the guard zero times in 120 rounds. The gate,
  its bound of two, and the reading that the readers were their own writers
  are all from this box; the condition variable and the commit are the
  owner's. It is `f1ff4d5`, 0.1.16, one commit, and the whole story is in the
  guard section above.
* **A writing process was quadratic in its own rows, and it was the PAGE
  LIST.** Every row written draws a sequence value, a draw is a cursor over
  the sequence's own key, and `cursor_walk` snapshotted a page list that was
  one chain for the whole store — so a draw cost O(pages) and the pages grow
  with the rows. A page now also sits in the chain of the pages under its own
  key. 128 000 rows in one process: 15.0 s to **7.45 s** here, and the cost a
  row is flat where it climbed. The measurement and the rest of the diagnosis
  are in the store section below; the guard is a counter in `mvccs_test`, not
  a stopwatch.

## Cicili, as it is actually written

Cicili is Lisp-syntax C. It is not C in parentheses, and these are the places
that read like C and are not:

* **A string literal is raw.** It reaches C untouched, so `"\n"` is two
  characters in the source and a newline only after the C compiler sees it. A
  string may **not** end in a backslash.
* **`defer` is a variable attribute of a `let` or `var` binding, not a
  statement** (`../cicili/doc/DOC-C.md`). Nothing in cocolog uses it yet, so
  there is no local example to copy.
* **`break` and `continue` are bare keyword symbols** — `break`, not `(break)`.
* **Use `bitand`, `bitor`, `xor`** — not `&`, `|`, `^`.
* **There is no character literal.** `(coco-ch-between c "a" "z")` expands to the
  numeric comparison; write characters through the macros, or as their codes
  with a comment saying which character.
* **A function pointer in a variable is written as a `func` clause in type
  position.** `coco_store_reset` in `lib/kb.cicili` is the worked example.

* **A string literal cannot contain a newline** — as a real newline it lands
  unescaped inside a C literal, as `\n` it is emitted as an escaped backslash.
  A module's Prolog half is therefore joined with spaces; see MODULES.md.
* **Lambda-list markers must be uppercase** in a macro: `&REST`, not `&rest`.
  Case is preserved, so the lowercase one is a different symbol and the macro
  is called with the wrong arity.
* **A macro emits ONE form.** Several from one macro leaves the symbols
  unregistered and the next reference is "unknown symbol".
* **`new` is a Cicili macro**, so a local of that name is read as a call to it.
* **A dotted initialiser** — `(var size_t n . 0)` — cannot be written inside a
  generic in this package, because `nil` there is `cocolog::nil` and the form
  is genuinely dotted. A static is zero anyway.
* **`(out (T *))` is wrong; `(out T *)` is right.** The parenthesised form
  emits a cast to a non-scalar type.
* **`(cast unsigned char x)` is wrong** — a cast takes ONE type token, so a
  two-word C type cannot be written. Mask instead: `(bitand (cast int c) 255)`.
* **A `let` declares locals; `block` does not.** `(block (char err [256]) ...)`
  fails with `unknown symbol: [`.
* **`for` takes a BINDING LIST, not a C-style init**: `(for ((size_t i . 0)) (< i n)
  ((++ i)) BODY)` — four parts, and the step is parenthesised. Writing
  `(for ((set i 0) (< i n) (++ i)) BODY)` fails with `The value 0 is not of type
  SEQUENCE`, which is a message about Lisp and says nothing about the loop.
* **Indexing is `(nth INDEX ARRAY)`** — index first — and there is no `aref`.
* **Arrays may have two dimensions** — `[]`, `[N]`, `[N][M]`, and no more. (This
  file briefly said the opposite: a `for`-loop error was blamed on the array
  beside it. `doc/DOC-C.md` says two, and two work.)
* **A `#define` is invisible to Cicili**: it is raw C, so a constant named in one
  is an `unknown symbol` when a Cicili form uses it. Write the number out, the
  way `files.cicili` writes 4096 rather than PATH_MAX.
* **`../cicili/lib/std/c/posix/` ALREADY DECLARES the POSIX structs**, members
  and all — `sockaddr_in`, `pollfd`, `addrinfo`, `stat_t` — and the prelude loads
  them before your file. Do not describe a system header again. What is missing
  is only the C typedef, because a Cicili type is one token and `struct pollfd`
  is two: `(@define (code "pollfd struct pollfd"))`, and **the name must match
  the one std declares the members under**. `pollfd_t` is a different name with
  no members, and `($ p fd)` then says `unknown struct type` — which is how
  `modules/tcp/tcp.cicili` ended up written in raw C escapes for a day.
* **`(code "...")` is the fire escape, not the door.** It is C that Cicili cannot
  see or type-check, and no front end can help it. Reach for a Cicili clause
  first, every time.
* **`$` chains**: `($ a b c)` is `a.b.c`. `(-> p m)` is `p->m`. `(=> o m args)`
  calls a function stored in a member, one level only.
* **An external `struct` needs a name**: `(@define (code "stat_t struct stat"))`,
  per `../cicili/doc/lib-std-c.md`. `(code "...")` is the raw-C escape for what
  `lib/std/c` does not declare — `glob` and `realpath`, in `lib/files.cicili`.

`../cicili/doc/` is the reference, and `../cicili/lib/README.md` an index of
what the language ships with. Read them rather than guessing at syntax — a
wrong guess usually compiles to something that fails much later.

The macro layer is where the work is. `*cell-tags*`, `*operators*`, `*builtins*`
and `*turn-outcomes*` each emit several things that must not drift apart —
**add to the table, never to the generated code.**

## Parsi, as it is actually written

* `IF cond BEGIN … END`, not `IF … THEN … END IF`.
* `<>` for not-equal.
* Names fold to upper case, so a column named `text` collides with the `Text`
  type — which is why the clause column is called `body`.
* A row must fit in a page. With the default 8192-byte page a `Text` of 8000
  stores and one of 8192 comes back `allocation overflow`, which is why machine
  state travels in 4000-byte chunks.

## Two tiers of library, and which one a thing belongs in

**TIER 1 — always present. No `use_module` needed, and none of it is
optional.** Registered before the first goal runs:

    apply  builtins  dcg  files  library  lists  zigurat
    assoc  pairs  ordsets  yall  aggregate  ugraphs  dcg_basics  dcg_high_order

The first row is Cicili modules compiled into the binary; the second is
SWI's own libraries, vendored in `lib/swipl` under their own BSD-2
headers and read from disk beside the binary at start-up by
`coco_library_preload`. **They are part of Prolog, not an optional
extra** — a program that must say `use_module(library(assoc))` before it
can use an association list is doing the interpreter's bookkeeping.
`use_module` on any of them still succeeds, at once, because a registered
module answers the call for nothing.

It is a load rather than an autoload because it MEASURED free: 469ms bare
against 459ms with all eight, then 441/446, then 458/443 — inside the
noise of a start-up dominated by the embedded store and libtorch. A
missing `lib/swipl` is not an error; the binary still boots.

**SO A `use_module` FOR ANY OF THEM IS A DIRECTIVE THAT DOES NOTHING**,
and none is written anywhere in this repository or in The Coco. It reads
like a dependency and is not one; the first two libraries here already
knew it (neither `http.pl` nor `httpd.pl` imports `lists`) and 26 lines
written out of habit for another Prolog have been removed — three in
`library/json.pl`, `xml.pl` and `html.pl`, eight in
`test/zigurat-lib.pl`, and 23 across The Coco. The list to check against
is the two rows above, and it can be checked rather than remembered:

```sh
D=$(mktemp -d); cp cocolog "$D/"          # a binary with no library/ beside it
COCOLOG_LIBRARY="$D/none" "$D/cocolog" query "use_module(library(lists)), write(yes), nl"
```

Answering `yes` from a directory with no library path at all is what
compiled-in means. Three places legitimately keep such a directive and
each says why in the file: `test/files/*.pl` and
`emacs/test/conformance.pl` are run by **swipl as well**, where the
import is required; and `test/library.pl` is the case that checks
`use_module` on a registered module succeeds at once.

**It measured free LOCALLY and cost 272 HTTP round trips over Zeytun**,
and finding out why paid for itself. `coco_assert` fetched the shared
predicate before adding each clause — *muted clauses included*. A module's
clause never writes through, so it has nothing to be appended to and
nothing to read first; `kb.cicili` now skips the fetch while the store is
muted. One `edge_fact(X)` through a Zeytun edge went from **440 requests
and 91.4 seconds to one request and 447ms** — and 168 of those requests
predated the vendored libraries entirely, from the Coco halves of the
modules compiled in. The lesson is the one in "Where things are" below,
arrived at the expensive way: **a start-up cost is not a cost until you
have measured it in the arrangement where a predicate is a page.**

**TIER 2 — on the library path, loaded when asked.**
`$COCOLOG_LIBRARY` (colon-separated), then `./library`, then
`<exedir>/library`, then `<exedir>/lib/swipl`:

| | |
|---|---|
| `library/*.pl` | clauses only — `http.pl`, HTTP/1.1 as a grammar; `httpd.pl`, a server whose pages are clauses; `json.pl`, `xml.pl`, `html.pl`, a term as a document; `ca.pl`, a certificate authority as rules; `kbs.pl`, many knowledge bases from one script -- every kb_* goal a process-proof over the wire, goals as terms; `cowork.pl`, a crew of workers that outlives the turn -- one process doing several things where a thread costs what the PROGRAM costs to start; `main.pl`, a command line as terms -- SWI's library(main) INTERFACE, written here because its own file draws 31 HARD findings from cocolint; `astar.pl`, A* whose graph is two caller goals; `hex.pl`, hexagonal-grid arithmetic; `tensor_expr.pl`, a network as an expression; `llm.pl`, a chat completion as a goal; and, under `library/reasoning/`, loaded as `library(reasoning/NAME)`: `reason.pl`, a paragraph as predicates -- a controlled English read by a DCG whose semantic argument is the term; `normalise.pl`, the training data for the network that will feed it -- the grammar's shapes as a generator with gold tags, noise transforms that carry them, and the assembler the round trip holds them to, over `library/reasoning/lexicon/`, files of census names and WordNet words read as needed and NEVER written into the code (`library/reasoning/lexicon/build.pl` regenerates them from a WordNet 3.0 dict), over `library/reasoning/corpus/`, the lessons whose words the lesson shapes draw, one sentence a line, and written out to `library/reasoning/generated/` by `generate.pl` so the pairs a model trained on are in the tree; `tagger.pl`, that network -- a tagger over `tensor_expr`, two embeddings, a GRU each way and a head, trained on the pairs and saved into the knowledge base, so prose goes in and `reason.pl`'s terms come out, and measured on sentences it never saw |
| `library/*.so` | a Cicili module against `lib/sdk.cicili`, dlopen'd — built from `modules/` |

**THE REASONING LEXICON IS FILES, NOT SOURCE, AND THE GRAMMAR FILTERS
THEM AS THEY LOAD.** `library/reasoning/lexicon/<class>.txt` -- one word a
line, commonest first -- is what `library(reasoning/normalise)` generates
from: `proper.txt` is the US Census's first names, the rest are WordNet
3.0 ranked by its SemCor tag counts, written by `library/reasoning/lexicon/build.pl`
(cocolog: `read_file_to_codes` takes data.noun's fifteen megabytes in
half a second and `split_string/4` cuts a megabyte into lines in ten
milliseconds). The library reads them on the first pick, keeps them as
globals of the machine -- never asserted, so no store is written -- and
drops what the grammar would not read as an open word: a closed word
(`will` is a modal before it is a name) and a verb whose third person the
stemmer cannot invert, so `test/normalise.pl`'s inflection round trip
holds by construction. Two things bit: `ng_base_of` walked the whole verb
list with the inflector for every pair, nothing over twenty verbs and
eighty milliseconds a pair over four thousand -- it stems with the grammar
now; and the tagger's batches were built as tensors all at once, which at
128 batches ran torch's handle table out and died a step later with
`tensor expected, found 0` -- a batch's tensors are made per step now. And
the numbers moved: over this lexicon 8192 pairs read 0.96 of unseen
sentences whatever the step count, which is memorising, so the tagger's
defaults were 16384 pairs and 400 steps (0.997), about eighty seconds here -- and are 32768 pairs and 500 steps since the ten lesson shapes of 1.2.39, whose bare mentions are the hard part.

**A TAGGER THAT CANNOT SAY NO READS `Boston, Mass.` AS mass(boston), AND
THE NO DOES NOT LIVE IN THE NETWORK.** The Brown corpus's government
documents were the lawsuit corpus this box could reach -- every legal site
is off the egress list -- and of 875 sentences the tagger "read" a tenth,
nearly all wrongly, because every sentence it had ever seen had a reading
and the grammar's defaults are positional. Three learned refusers were
built and measured, and each cost recall where it counted: X as a twelfth
tag trained on every token of `prose.txt` (eight thousand of WordNet's own
example sentences, which nothing else trains on) took the generated
unseen sentences from 0.997 to 0.907; a sentence head over the shared GRU
states, and a separate refuser network, each refused seven to ten of the
forty-three hand-written sentences at any threshold. Confidence gating is
weak too: fragments come out at 0.87 to 0.98. What stayed is deterministic
-- six lexicon rules, `tagger_sane/2`: a sentence has a relation; a
relation is a closed word, or a lower-case word past the first that the
lexicon does not know ONLY as a noun, adjective or adverb, its stem
included; a subject, object or adjective is not a closed word; a
capitalised first word tagged subject that the lexicon knows is a name;
an adjective is not a word known only as an adverb -- and an empty
assembly is a refusal, where `Terms = []` had been what 319 Brown
sentences "read" as. A tagging the rules contradict comes back X
throughout and the assembler refuses it. Measured on one model: WordNet
example sentences read 15.3 % -> 6.3 %, Brown prose 13.5 % -> 3.6 %,
generated unseen sentences 0.997 either way, the hand-written forty-three
as before. `tagger_refused/4` is the instrument and `test/tagger.pl`'s
`refusals` section pins 0.90 over a slice of prose.txt. What still slips
is a real sentence in the grammar's shape -- `Every person is mortal.` is
read, and it is true -- and a fragment the lexicon cannot fault, `Feeling
amorous.` as amorou(feeling).

**AND THE PLACE THE TAGGER DROPPED WAS THE GENERATOR'S TEACHING.** `Dana
rents a flat in Bristol.` came back as `rent(dana, flat_1)` because the
`pp_place` transform appended `in Rome` after every noun-phrase object as
NOISE, tagged D -- the grammar had no reading for a place after an object,
so the generator taught the network to drop one. The grammar reads it now:
the preposition joins the relation exactly as it does when written joined
to a bare verb, and the place is a third argument, `rent_in(dana, flat_1,
bristol)`; only after an object, so `sleeps in Rome` stays refused and
`sleeps_in Rome` is the written form. Four shapes replaced the transform
(23 to 26: an indefinite, a definite, a rule's and a denied object, each
with a place), `pp_extra` lost `on Monday` and `on Friday` because a
capitalised word after a preposition after an object IS a place now, and a
joined relation stems its verb -- `lives_in` reads as `live_in`, the same
predicate its denial `does not live_in` always gave, which `truth/2` had
never been able to connect. `test/reason.pl` pins the shape, the
stemming and the refusals that stay.

**AND A CAPITALISED WORD CARRIES NO ENDING SHAPE, because `Zed' is not a
participle.** The tagger's shape embedding gave a capitalised word the same
-s/-ly/-ing/-ed ending a lower-case one gets, so `Zed' and `Ted' after
`does not like' wore a shape that twenty-three objects in sixteen thousand
pairs had worn -- and three trainings in a row dropped them where `Bob' and
`Mia' were kept every time. (`like' itself is picked once in the whole
corpus, so it is `<unk>' too: the pattern was two unknowns and a rare
shape.) A capitalised word is shape 2 now whatever it ends in; the lower
case keeps its endings, which is where `flies' and `wholly' are read.

**A POSITION THE GENERATOR NEVER MAKES IS ONE THE TAGGER GUESSES AT.**
`Priya is a baker and, as far as I know, Priya is licensed.` tagged the
`and` as an object and `baker` as noise, and the lexicon refused it -- the
right outcome for a guess, and still a sentence a person types. Every
filler the generator made sat at the start or the end of the WHOLE text,
so a filler after a conjunction had never been seen. `filler_join` is the
tenth transform: a filler between commas, or a hedge, right after the
`and`, conjoining a second sentence itself when nothing has so that it
stands alone under `test/normalise.pl`'s per-transform check. The rule it
is an instance of: when the tagger fails a hand-written sentence, read the
TAGS before the network, and ask which shape or which position the
generator does not make.

**EVERY SENTENCE CARRIES STATE, AND THE STATE IS THE LAST SUBJECT.** `She
is a baker and is licensed` has to give two facts about the person the
paragraph was talking about, and until 1.2.28 the grammar did no
coreference at all and the assembler wrote a subjectless sentence after
the break. Two things carry it now. `reason_text/2` keeps the subject of
the last FACT it read (`'$rs_subject'`, reset at every entry) and `she`,
`he` or `they` as a subject stands for it; a rule between leaves it, a
paragraph that opens with a pronoun is refused, `it` is left alone (`It
rains` is about nobody), an object pronoun is still refused, and
`reason_refused/2` walks with the same state so a resolved pronoun is not
reported. And `normalise_assemble/3` gives a sentence a break left without
an S the subject phrase of the one before it -- everything before the
first R, D and commas aside, so a rule's `every baker that is licensed`
travels whole. The generator's eleventh transform, `conjoin_shared`, makes
both forms so the tagger sees them; the lexicon rule that refuses a closed
word as a subject lets a subject pronoun through. `test/reason.pl`'s
`state` section pins eleven cases, the refusals included.

**A QUESTION IS A GOAL, AND THE ANSWER CARRIES ITS REASON.** `?` was
already a stop, so a question is known by its first word -- `does`, `is`,
a modal, `who`, `what`, `where` -- and reads to the term the statement
would have asserted with a variable where the question word stood:
`question(sell(priya, bread))`, `question(X, (flat(F), rent_in(X, F,
bristol)))`. `reason_ask/2` proves it against the knowledge base and
answers `yes(Why)`, `no(Why)`, `unknown` or `conflict` for a yes-or-no
question and a list of `Value-Why` for the rest, where Why is `fact`,
`rule(Head :- Body)` with the body as it proved (one level, from
`clause/2`), or `denied(neg(...))`; an indefinite object is an
existential in the goal and the class atom in the denial, which is what
a negative sentence gives. Neither `reason_question/2` nor `reason_ask/2`
resets the subject state, so `Is she licensed?` may follow the paragraph
that introduced her. The question words joined the closed classes, or
`Who` at the head of a sentence was somebody's name. The generator makes
six question shapes with the statements' tags -- `who` an S, `what` and
`where` an O -- so the tagger drops the noise around a typed question and
`tagger_ask/3` answers it; the transforms that would join or hedge a
question stand down for one, and the text ends in `?`. `tagger_ask/3`
goes to the controlled text and then `reason_ask/2`, NOT through
`tagger_normalise/4`, whose `reason_text/2` resets the subject state:
measured, `Is she insured?` typed after a paragraph about Lena came back
refused that way. `test/reason.pl`'s `questions` section pins the forms
and the answers, and the tagger case pins the pronoun question.

**A QUANTITY IS A VALUE, NOT AN INDIVIDUAL, AND `how much` READS THROUGH
THE AMOUNT.** The tokeniser dropped a token that began with a digit, so
`Nadia pays 500 euros` read as `pay(nadia, euros)` -- a claim the text
never made. Digits are `num(N)` now (`5.5`, `1,000`, and `5%` as 5 and
the word `percent`), the number words are closed (`five` is never an
adjective and `Six` never a name; `twenty five`, `two hundred fifty`, `a
hundred` compose), and a number and the noun it counts are ONE object,
`quantity(500, euros)` -- the noun as written, no `euro_1` introduced,
because three of a thing is not one -- in a fact, a rule's head and a
denial alike, with `quantity(2, litres, milk)` for `two litres of milk`
and a bare number as itself. `The rent is 500 euros` is the one sentence
with a definite subject and reads as `amount(rent, quantity(500,
euros))`. `How much does Omar pay?` is `question(Q, (pay(omar, O),
reason_amount(O, Q)))`: the object itself when it is a quantity, or the
amount the text gave a class atom, so `Omar pays the rent` beside the
amount answers 600 euros and not the word `rent`; `how many NOUN` goes
through `reason_count/3`, which reads the number out of a quantity of
that noun with or without an `of` part; and `rq_claim` takes the reason
from the claim before either helper, or the reason would have been
`rule(reason_amount(...) :- ...)`. What is refused: an adjective inside a
quantity (`three red cars`), a comparison (`more than 500 euros`) and a
definite phrase after the quantity (`for the flat`, because `pp_extra`'s
`at the moment` must stay noise). The generator has eight shapes for it
(33 to 40: a quantified object, the rule, the amount sentence and its
question, the denial, `does S V N UNIT`, `how much`, `how many`, `how
much is`), a number tagged T before its noun and `of` a K, over
`lexicon/unit.txt` -- WordNet's hyponyms of `unit_of_measurement` and
`time_unit`, which `lexicon/build.pl` now walks by the `~`
pointers, because noun.quantity alone offers `nothing`, `much` and
`half`; the tagger gives a number one word, `<num>`, and shape 15, and
the judge lets a number or a number word be T or O only and `much` or
`many` an O. `test/reason.pl`'s `quantities` section pins the forms and
the answers, `test/tagger.pl` ten typed sentences and two `how much`
questions over a paragraph.

**THE EXPLANATION IS THE WHOLE PROOF, IN SENTENCES, AND A CHESS MATE IS THE
CASE.** `reason_why/2` answered one level, and `Why is Kh8 checkmated?`
wants all of them: `reason_explain/2` is a meta-interpreter that proves the
goal as Prolog would -- first proof, clause order, the body left to right --
and keeps what it proved by: `fact(G)`, `rule(G, Whys)`, `absent(G)` for a
`\+ G` that held, `denied(G)` when `neg(G)` was said besides, `holds(G)`
for a builtin, and `forall(A, B, Instances)` for `\+ (A, \+ B)`, the one
shape that needs its own record, because a universal's explanation IS its
instances. `reason_explanation/2` says it depth first, one sentence per
rule -- `Kh8 is checkmated because Kh8 is a captive and nothing shows that
Kh8 is defended. Kh8 is a captive because ... Kh8 is immobile because Kh8
is a king and whenever Kh8 may move to X, X is unsafe (X: G8, G7 and H7).
G8 is unsafe because ...` -- and the words are the knowledge base's own:
the verb in the third person through `reason_third/2` (the inflector MOVED
here from normalise.pl, beside the stemmer it inverts, so the pair is
changed together), a proper noun the reader met capitalised and a class
noun it met after `a`, `the` or `every` with its article (two globals the
reader fills as it goes, `'$rs_names'` and `'$rs_nouns'`, never asserted),
any other atom as `the ...`, an individual `flat_1` as `the flat`. `Why
...?` before any yes-or-no form is `question(why(Goal))`, answered
`because(Text)` or `unknown`; `reason_ask/3` puts the explanation beside
every answer, a denial as `..., as said.` and an unknown as `Nothing shows
that ...` with an existential written `a flat`. The scenario is the
back-rank mate -- Kh8 behind Pg7 and Ph7, Re8 arrived -- in twenty-nine
terms of the controlled English (check and mate are three `every` rules
chained through class nouns, target and captive, because a relative clause
carries ONE condition) plus four Prolog clauses for what the English cannot
say, a rule over two variables and the universal `immobile`; the
explanation walks both alike. The generator has two `why` shapes (41, 42),
`why` an O like `what`, and `tagger_ask/4` carries the text for typed
prose. And the typed scenario found a shape nobody had made: `Every
square that is attacked is unsafe`, a rule whose head is an ADJECTIVE
after a relative clause -- shapes 8, 15, 16 and 21 put a class, a verb or
a modal there, never `is ADJ` -- so the tagger dropped `unsafe` on every
such definition; shape 43 makes it, with and without `not`. And a second
one the same afternoon: `Kh8 may move to G8`, a MODAL before a phrasal
verb, read with `move` as the object -- shape 6 has a modal before a verb
and a noun, shape 9 a phrasal verb with no modal, and nothing had put the
two together; shape 44 does (`may live_in Rome`, split and joined back to
may_live_in, which the grammar reads as a modal and a base form). The
typed scenario found both, one training apart, and the rule stands: read
the tags, ask which shape the generator does not make. Two things bit: the universal's phrase copied the instance bindings
BEFORE collecting the pattern's variables, so a `member/2` ran over an
unbound list inside a `findall/3` and never came back -- a hang that
looked, for an hour, like the engine looping on `checkmated(kh8)`, until
the plain goal was run without the explainer and answered in a
millisecond. Bisect the CALL before the engine. And `flush_output/0` did
not put a line into a FILE before a `timeout` killed the process -- five
lines arrived and the sixth, written and flushed the same way, did not --
so a marker missing from a redirected log is not proof the goal before it
hung; a pipe behaved.

**AND WHAT A TEXT IS ABOUT: CONCEPTS RANKED, AND AN OUTLINE BY TOPIC.**
`reason_concepts/2` counts every mention in the terms -- a name, an
individual, a class, a property, a relation, one count per occurrence in a
fact, a denial, an amount or a rule -- and ranks them, ties in order of
first mention, so the chess position is about Kh8 (6), Re8 (6) and
`attack` (6) before anything else. `reason_topics/2` is the outline: one
topic per SUBJECT with its sub-topics grouped in order of first mention --
`class-[king]`, `property-[black]`, `relation(occupy)-[[h8]]`,
`relation(may_move_to)-[[g8], [g7], [h7]]`, `denied`, `amount`; a class
with its `members` and the `rules` quantified over it; a class or property
with the `definition` rules whose head names it (`unsafe: a square that is
attacked; a square that is occupied`); and an OBJECT with what is said of
it from the other side, `by(attack)-[attack(re8, h8)]`, which is how a
square becomes a topic. `reason_topic_lines/2` writes it with the
explanation's renderer, the subject taken off the front of each claim:
`Kh8, a king: black; occupies H8; may move to G8, G7 and H7.`; a class as
a class heads its line bare with its members, `King (Kh8)`, and a class
atom something is said OF heads it as the reader wrote it, `The rent: 600
euros.`; an individual's own noun, `flat(flat_1)`, makes no class of flats
and no `the flat, a flat`. `reason_outline/2` reads a text and outlines it,
`reason_outline_prose/2` the same over typed prose. `test/reason.pl`'s
`topics` section pins thirty concepts, twenty-one topics and the lines
over the chess position, and lesson 43's section 16 shows it.

**A WORD IN QUOTATION MARKS IS MENTIONED, AND A LANGUAGE LESSON IS A
KNOWLEDGE BASE (1.2.32).** `"casa" means "house"` is not about a house:
the tokeniser reads a word between quotation marks (the plain `"` or the
typographic pair) as `quoted(Word)`, the grammar lets it stand as a
subject, as an object, and after a preposition after a BARE verb -- `ends
in "a"` is `end_in(X, a)`, where `sleeps in Rome` stays refused, because
a mention can belong to nothing but the verb -- and `the noun "casa"`,
`the feminine article "la"` are appositions that hand back the class and
the adjectives as facts about the word, before the claim: `noun(casa),
mean(casa, house)`; `article(la), feminine(la), mean(la, the)`. A
relative clause takes a VERB now, `that [does not] VERB [OBJECT]`, and
`that is a NOUN`, still one condition each; `end_in/2`, `end_with/2`,
`begin_with/2` and `start_with/2` are the library's so that `Every noun
that ends in "a" is feminine` RUNS, and the explainer says one as it is
(`"perro" does not end in "a"`, never `nothing shows that`). `reason_learn/1`
reads and asserts. `library(reasoning/translate)` is the consumer:
`reason_translate/2,3` takes a simple sentence -- a subject, a verb, then
an object or a bare adjective, each phrase an article, adjectives and a
noun, or a name -- between English and the language the lesson teaches,
asking the knowledge base five things (`mean/2`, the four classes,
`feminine/1` and `masculine/1`, `follow(A, noun)`, `language/1`) and
knowing no word of Spanish itself: an article and an adjective are chosen
among the words the lesson gives for the English one by the NOUN's
gender, a bare adjective after the verb agrees with the subject, and an
adjective goes after its noun exactly when the rule says so; a sentence
with a word the lesson left out is refused whole and
`reason_untranslated/2` names the word. `test/translate.pl` is the case
-- twenty lines of Spanish, forty-four terms, both directions, the
lesson questioned, and the order rule retracted to show the order was
the rule -- and lesson 46 the tutorial. Two things bit: `atom_codes/2`
answers BYTES, so the tokeniser dropped every byte past 127 and
`pequeño` read as `peque` and `o` until such a byte counted as a letter;
and `clause/2` SEES a module's clauses (probed: `clause(reason_third(have,
X), B)` answers), so a helper would have explained itself by its own
body until `re_goal` asked `re_helper/1` first.

**PLURALS AND NEGATION ARE THE LESSON'S TOO (1.2.33).** Three more shapes
read: a definite phrase after an object is a place, `keeps the tractor
in the barn` being `keep_in(omar, tractor, barn)`; a determined noun
after a bare verb's preposition is its class atom, `ends in a vowel`
being `end_in(X, vowel)`, and `end_in/2` knows the two letter classes
(the five vowels and their accented UTF-8 forms); and `is the NOUN of X`
is the relation the noun names, `plural_of(los, el)`, `mother_of(alice,
bob)`, asked as `What is the plural of "el"?`. `reason_base/2` is the
stemmer made public, because a noun's plural comes off the way a verb's
-s does. So a lesson says `Every noun that ends in a vowel takes "s" in
the plural`, `"los" is the plural of "el"`, `Every verb that ends in
"e" takes "n" in the plural`, `"son" is the plural of "es"` and `The
word "no" means "not"`, and the translator asks `plural_of/2`,
`take_in(W, E, plural)`, `mean(N, not)` and `follow(N, verb)`. A word's
LEXEME is the form the lesson gave -- the word, or the singular a stated
or ruled plural is made from, and in English a noun the stemmer takes
back or a verb by its third person -- the noun's number is the phrase's,
the subject's is the verb's, and a denial comes off before the split and
goes back on the verb: `no come`, or `does not eat`, `do not eat`, `is
not`, `are not`, which is English and the translator's own, as `an`
before a vowel and no `a` in the plural are. Measured over the lesson
grown to thirty-two lines: `The dogs do not eat the bread` is `Los perros
no comen el pan` and back, `The houses are not big` is `Las casas no son
grandes` and back, and `Maria tiene unos libros` is `Maria has books`.
What bit: the order rule must be asked about the adjective's SINGULAR
(`follow(rojas, noun)` proves nothing), so an adjective travels with its
lexeme beside its form. And a REFUSED sentence used to leave its word
notes behind: `the big barn` in one made `big` a class noun for the rest
of the process, and an explanation three sections later said `the box is
a big`. The reader's notes are pending until the sentence parses and
dropped when it does not. Two refusal pins moved with the shapes:
`Alice owns a house near the river` reads as `own_near/3` now and `Alice
sleeps at the house` as `sleep_at/2`; `near a river` and `in Rome` after
a bare verb stay refused.

**QUESTIONS TOO, AND THE QUESTION WORDS ARE VOCABULARY (1.2.34).** A
sentence that ends in `?` is a question in either direction. The lesson
says `The word "qué" means "what"`, `The word "quién" means "who"` and
`The mark "¿" begins the question` -- `begin(M, question)`, and both
words in it are chosen: `a question` would introduce an individual whose
class is the reader's own `question/1` wrapper, which `reason_name/2`
skips as a question and leaves a variable in, and `opens` is `open`,
which cocolint reads as the stream builtin and flags. What the translator knows is
English's: the copula or `does`/`do` fronted, `what` asking for the
object and `who` for the subject. The lesson's language asks in the
statement's order (`¿La casa es grande?`, which needs no rule), except
that after a question word asking for the object the verb comes before
the subject (`¿Qué come el perro?`), and it is READ in either order --
`¿Es grande la casa?` puts the adjective before the subject and is read
too. Two things bit: `¿` is two bytes past 127 and the tokeniser had
made every such byte a letter, so `¿Qué` was one word `¿qué` -- U+0080
to U+00BF and the general punctuation block are signs now, dropped like
any other; and a word's case travelled with it, so `Is the house big?`
came out `¿La casa Es grande?` -- the head of a sentence goes lower when
the lesson knows the word, and only a name keeps its capital. And a
question word the lesson has no word for was passed through as a NAME,
by the capitalised-and-unknown rule; a question word is never one.

**THE PAST, TOO, AND A PAST IS STATED OF A FORM (1.2.35).** `"comió" is
the past of "come"` and `"comieron" is the past of "comen"`: the lesson
states a past of the singular form and of the plural form, because a
Spanish preterite is no suffix of its present, and a rule
(`take_in(F, E, past)`, `takes "ba" in the past`) serves where it is
one. The verb's LEXEME comes with a TENSE now: a present form the lesson
gave, or a past the lesson stated or its rule makes, and in English
`was`, `were`, `had`, a regular `-ed` taken back to a base whose third
person the lesson gave, or `did` fronted or before `not` -- which the
base form after it cannot say, so the negation and the fronting report
the tense they saw and the sentence takes the past if any sign says so.
English's own is the copula in `was`/`were`, `did not` and `did` with the
base, `had`, `-ed` with `-d` and `-ied` (`"ate" is the past of "eats"`
for the rest), and the translator generates a Spanish past of the
NUMBER's form, so `comieron` is asked for as the past of `comen`. A past
that spells like a present form (`read`) is read as the present: `The
cats read the books` is `leen`, and `leyeron` comes back as `read`. What
bit: a stated past of a plural form the RULES make (`comen` is no
lexeme) was refused until the past lookup went through the lexeme
machinery rather than `plural_of/2` facts.

**A FULL TRANSLATION, AND A SENTENCE IS ONE SHAPE READ FROM EITHER SIDE
AND WRITTEN TO THE OTHER (1.2.36).** `library(reasoning/translate)` was
rewritten around one shape -- a subject, a verb group (the lexeme, its
tense, simple or perfect, denied or not) and the complements after it --
a question first put into the statement's order and its question word
kept aside with what it asks for. What a lesson may say now, and the
translator asks for: the first and second PERSONS of a form (`"como" is
the first person of "come"`, read by the grammar's new `is the ADJ NOUN
of X` shape as `first(como), person_of(como, come)`; the third is the
form); the FUTURE by an ending rule (`takes "rá" in the future`) or
stated; the PERFECT as the auxiliary the lesson names (`The auxiliary
"ha" means "has"`) in the subject's person and number, with a stated
participle; pronouns, possessives, prepositions, adverbs, numbers and the
conjunction as classes, and whether a pronoun precedes the verb -- a
DENIAL overriding the rule for one word (`Every pronoun precedes the
verb. The pronoun "él" does not precede the verb.`, through
`tr_holds/1`); the words for `where`, `when` and `which`, and one word
meaning two (`qué` is `what` and `which`, chosen by what the question
asks for). A sentence of the lesson's language with no subject takes the
pronoun its verb says (`Comemos el pan` is `We eat the bread`; a third
person singular is refused, because it could be anybody), and English's
`it` as a subject becomes no subject at all. A lesson learned under a
NAME (`reason_learn/3`, asserted as `lesson(L, Term)`) shares nothing
with another; the words vote for the language a text is in or goes
into, and two that fit equally refuse it until `reason_translate/3`
names one. `test/translate.pl` is the case, 329 checks over 171 lines of
Spanish and 18 of Italian, and lesson 46 gained four sections. Four
things bit, and each is a fact about ENGLISH rather than Spanish: `lo`
means `him` and `it`, and `it` is a subject in English, so `Ella lo ve`
read `lo` as the subject until a word that also means an object's-only
pronoun was ruled out as a subject (`tr_subject_pronoun/4`, and its
mirror for objects); `la` is the article and the pronoun `her`, so `en
la ciudad` read as `in her` until an object pronoun before a noun was
ruled an article; `I` went through the inflector to `is` and became the
verb of `I eat the bread`, so the group finder guards English's own
words (`en_own/1`); and `Every pronoun precedes the verb` made
`nosotros` a clitic too, so `with us` came out `con nos` until a pronoun
that may be a subject was preferred after a preposition. And the
tokeniser's case was ASCII-only -- `Él` was `word('Él', lower)` -- so a
capital in the Latin-1 block (U+00C0..U+00DE, the UTF-8 bytes 195 and
128..158) is a capital now and lower-cases to its small letter, on the
reader's side and the writer's.

**`whom`, AND THE WORD A LESSON PUTS BEFORE A PERSON (1.2.37).** Spanish
marks a person as the object with `a` -- `Maria ve a Omar` -- and the
translator had read that `a` as the preposition `to`. The lesson says it
now: `The word "a" precedes the person.` is `precede(a, person)`, `"amigo"
is a person.` says which nouns are persons, and a name is one. Written
into the lesson's language, the word goes before an object that is a
person -- a name, a phrase whose noun the lesson calls one, two such
joined, `whom` -- and never before a pronoun that stands before the verb
(`Maria lo ve`); read on the lesson's side, that word with a person after
it and NO OBJECT BEFORE IT is the object (`tr_complements/4` carries
whether one has been read), and after an object it is the preposition it
is (`da el libro a Omar` is `to Omar`). The cost is stated in the header:
`Maria canta a Omar` reads as `sings Omar`, because nothing in the
sentence says otherwise. `whom` is `who` asked for as the object and needs
no word of the lesson's: `Whom does Maria see?` is `¿A quién ve Maria?`
and comes back as itself, where `¿Quién ve a Maria?` is `Who sees Maria?`;
`¿A qué amigo ve Maria?` is `Which friend does Maria see?`. And a
contraction is the lesson's too -- `"al" is the contraction of "a el"` --
read as its words and written back as itself, so `Maria ve al amigo` and
`los perros del amigo` go both ways. What bit: the words VOTE for the
language a sentence is in, and `Maria ha visto a Omar` tied, because the
English inflector reads `ha` as the base of `has` and `a` is the article
too, while the participle `visto` counted as no word at all; a lesson's
word that English knows only by inflecting it is the lesson's now, and a
participle is a known word. `test/translate.pl` pins it in its `persons`
section, and lesson 46 in its fifteenth.

**A TIME PHRASE IS NOT A PLACE, AND A LESSON ENDS IN `done` (1.2.38) --
two things the full suite found that six standalone case runs had not.**
The 1.2.33 shapes -- a definite phrase after an object is a place, a
determined noun after a bare verb's preposition its class atom -- let
the generator's noise through: `Maryann does not redistribute an
enceliopsis in the morning` read as `redistribute_in(..., morning)` and
`Young decays for a while` as `decay_for(young, while)`, so
`test/normalise.pl`'s `every noisy text is refused` went RED, and with
it the tagger's teaching that such a phrase is noise. `rl_time_noun/1`
is a closed list -- moment, morning, evening, night, day, week, year,
while, end and the rest -- and `rs_place` and the bare-verb mention
refuse one, so `keeps the tractor in the barn` and `ends in a vowel`
read as before and `at the moment` stays noise. And `test/tutorials.pl`
requires a lesson's LAST LINE to be exactly `done` (`one_lesson/3`,
300 s a lesson, from the repo root), which lessons 43, 44 and 46 broke
with `Done.` -- each passed under `-s` and under `run FILE main` by hand,
because nothing by hand reads the last line. The rule to carry: **a
case that passes alone proves the case, and the suite proves the
contract between cases**; run `make test` before the claim, with a
server up, and read the 58 lines. Measured on this box after the fix:
58 lines, 7 SKIPs (tensors, the three torch cases, tensorflow, ray,
numpy -- every one a missing library, none a missing server), `red: 0`.

**A LESSON TYPED AS PROSE, AND THE TAG THAT WRITES THE QUOTATION MARKS
(1.2.39).** A language lesson is written about WORDS -- `The noun "casa"
means "house"`, `"los" is the plural of "el"`, `Every noun that ends in
"a" is feminine` -- and prose writes them bare: `The noun casa means
house`. A token tagger labels and never emits, so the marks had nowhere to
come from until a thirteenth tag, `M`, a MENTIONED word, which is the one
tag `normalise_assemble/3` writes something for: an M token goes between
quotation marks and a run of them is one mention (`al is the contraction
of a el` gives `"a el"`), a `quoted(W)` token is M and nothing else, and a
sentence with a mention before its relation has a subject of its own, so
`and is feminine` after `casa means house` takes `"casa"` as the assembler
already took `Priya`. Ten shapes make the lessons (45-54) and two
transforms undo the prose: `unquote` (the marks off, at seven pairs in
ten) and `in_language` (`In Spanish,` at the head, `in Spanish` after a
fact about a mention, both D). **NO WORD OF A LESSON LIVES IN THE CODE,
which is the owner's rule for training data**: the shapes draw their
mentioned words, the classes said of them, the adjectives, the forms, the
relations and the class atoms out of `library/reasoning/corpus/*.txt` --
the Spanish and Italian lessons of `test/translate.pl`, one sentence a
line, the same controlled English -- by pattern over the tokens
(`ng_corpus_word/3`), so a lesson that needs a word or a shape the corpus
lacks gets a LINE there, and `tagger_lessons/4` measures the shipped
tagger on those lines typed bare (`normalise_bare/2`). `lexicon/language.txt`
joined the WordNet files for `Spanish is a language` and the noise:
a word under `natural_language` in its first sense, or its second when
the first is a person (Italian, German), never a thing (tongue, chin).
Three things the grammar had to learn, each found by the round trip:
`"casa" is a feminine noun` is `feminine(casa), noun(casa)` (the
indefinite property takes adjectives, as the apposition does); a
sentence that MENTIONS a word names no place, so `"casa" means "house" in
Spanish` and `The word "no" precedes the verb in Spanish` are refused
rather than read as mean_in/3 -- where `takes "s" in the plural`, a
definite phrase, is still the form; and `on the whole` is an adjunct
noun like `in the morning`. And the judge gained two rules: a quoted
token is M whatever the network says, and a sentence with a mention is
related only by `is` or a verb some lesson uses, which is what keeps
`Boston, Mass.` from becoming a fact about the word `boston`. Two
things bit. A class word taken from `begins the question` made
`question(lo)` a fact, and `question/1` is the reader's own wrapper: the
classes said of a word come only from `the CLASS "w"` and `"w" is a
CLASS`, never from what a relation ends in. And `unquote` is the one
transform whose noisy text the grammar may READ -- `Leche is feminine`
is a fact about a name -- with the same term either way, so
`test/normalise.pl` now holds every noisy text to the clean text's terms
rather than to a refusal. **WHICH IS ALSO WHY A BARE MENTION AT THE HEAD
IS TAGGED S, THE NAME READING**: the first model trained with head
mentions tagged M read `Mia is a nurse and is careful` as `"mia" is a
nurse` -- a bare word at the head of a copula sentence cannot be told
from a name, and the network had been taught to guess. The term is the
same either way (`feminine(leche)`, `mean(casa, house)`), so `unquote`
writes a head mention bare and tagged S, and keeps the marks when the
lexicon knows the word as a common word (the judge refuses `House` as a
subject, as it refuses `Small business management`) or it is closed;
`normalise_bare/2` types a lesson the same way. A lesson typed bare
therefore reads back to its terms with its head words as names, and a
name typed after a lesson stays a name. Measured on the shipped model,
trained on `generated/training.txt` (32768 pairs, 500 steps): over 300
unseen pairs 0.988 of the tags, 0.933 of the sentences, 0.953 assembled
and parsed to the clean terms -- and 0.963 and 0.973 from the 16384-pair,
400-step training before it, so a training moves the sentence figure by
three points either way and the pins sit at 0.90 (0.9997 and 0.997
before the lesson shapes, whose bare mentions are the hard part); real
prose refused 0.950; the corpus's 194 lines typed bare read back at
0.876. That 16384-pair model dropped `late` in `Is Dana late?` to D and
lesson 45 went red on it, which is what moved the defaults: more pairs
per shape, once fifty-five shapes shared them. **AND THE DATA A MODEL TRAINED ON IS IN THE
TREE, WHICH IS THE OWNER'S SECOND RULE**: `library/reasoning/generate.pl`
writes the generator's pairs to `library/reasoning/generated/`
(`training.txt`, seeds 1..32768; `evaluation.txt`, 30001..30300; one
`pair(...)` term a line, `normalise_save/2` and `normalise_load/2`),
`train.pl` trains on that file through `tagger_train/2`'s `pairs_file(F)`,
`tools/tagger/train.sh` runs the two in turn, and the files are committed
beside `model.rows` -- a seed is reproducible only while nothing under it
moves. The generator programs are `.pl` files in the reasoning library
now, `library/reasoning/lexicon/build.pl` and `library/reasoning/train.pl`
(the `tools/` scripts stay as launchers), which is the rule's other half:
a generator is a cocolog program beside the data it writes.

**THE TRAINED MODEL IS KEPT, AND THE REASON LIBRARY LOADS IT ON ITS
OWN.** `tagger_pretrained/1` answers a model without training: the one
named `tagger` in the knowledge base this process proves against when
there is one -- a program over its own `--embed` store runs
`library/reasoning/train.pl` there once and every later run finds it -- and
otherwise `library/reasoning/model.rows` beside the library, the rows
`tagger_export/2` writes, consulted as a MODULE so they are muted and
never written into the program's base. `reason_prose/2` and
`reason_ask_prose/2` in `library(reasoning/reason)` load the tagger and
that model on first use, so a grammar-only program stays grammar-only and
a program that wants prose gets it with no training. A store was tried as
the shipped form and refused by measurement: sixteen megabytes for 3661
live rows, because a consult rewrites the predicate wholesale and a store
never shrinks below its high-water mark, and in one machine's byte order
besides; the text file is four megabytes at six decimals, which a weight
near one cannot feel. It is `model.rows`, not `.pl`, because cocolint's
retrieval index walks `library/*/*.pl` and was KILLED for want of memory
reading four megabytes of numbers as clauses. `sh tools/tagger/train.sh`
writes it, training into a scratch store and exporting; `test/tagger.pl`'s `pretrained` section
and `test/reason.pl`'s `prose` section load it, and SKIP by name where
torch or the file is missing.

**THE JUDGE'S LEXICON IS NOT THE GENERATOR'S.** `Death put a period to
his endeavors.` was read as `put(death, period_1)` because `death` is in
no lexicon file: the generator's nouns are things to own (WordNet's
artifact, food, object, plant, possession files), and the judge had been
reading the generator's lists. `lexicon/build.pl` now also writes
`known_noun`, `known_verb`, `known_adj` and `known_adverb` -- every
SemCor-counted lemma of that part of speech whatever its sense, 18 782
words -- and `tagger_sane/2` reads those beside the generator's; the same
model went from 28 of 300 real sentences read to 11, and `test/tagger.pl`
pins 0.93 refused where it pinned 0.90. A seventh rule joined the six: a
lower-case subject or object known only as a verb is refused (`Discuss
values`), unless it is a third person whose stem is also a noun (`keys`,
which the table holds as the verb form of `key`) -- an exception found by
the scratch paragraph's `Priya keeps the keys in Leeds` coming back X.

**`$COCOLOG_LIBRARY` IS A LIST, AND THE SUITE APPENDS TO IT RATHER THAN
REPLACING IT.** `test/run.pl`'s `environment/1` is the one place that sets
it — for every case it runs — and it puts this checkout's `library/` at
the FRONT and keeps whatever the caller had behind it. Ours first so a
suite cannot go green about somebody else's `httpd.pl`; theirs kept
because ten cases used to write `export COCOLOG_LIBRARY="$ROOT/library"`
and every one of them threw away a path somebody had exported on purpose.
So `COCOLOG_LIBRARY=/opt/my/modules make test` works, and a case run by
hand wants the variable set the same way. The Coco's `test/config.sh` does the same, and is
the one variable in that file which appends instead of deferring to the
environment — the two directories it names are not a default anybody could
have meant to replace.

**`modules/` IS WHERE A LOADABLE MODULE LIVES**, one directory each, all
the same shape: a `.cicili`, a `build.sh`, and output nobody commits.

| | needs | build |
|---|---|---|
| `modules/tcp` | nothing | `sh modules/tcp/build.sh` |
| `modules/thread` | nothing | `sh modules/thread/build.sh` |
| `modules/process` | nothing | `sh modules/process/build.sh` |
| `modules/text` | nothing | `sh modules/text/build.sh` |
| `modules/os` | nothing | `sh modules/os/build.sh` |
| `modules/curl` | libcurl | `sh modules/curl/build.sh` |
| `modules/bigint` | a **built** ZiguratIP | `sh modules/bigint/build.sh` |
| `modules/torch` | libtorch | `sh modules/torch/build.sh` |
| `modules/sha` | a **built** ZiguratIP | `sh modules/sha/build.sh` |
| `modules/aes` | a **built** ZiguratIP | `sh modules/aes/build.sh` |
| `modules/der` | a **built** ZiguratIP | `sh modules/der/build.sh` |
| `modules/x509` | a **built** ZiguratIP | `sh modules/x509/build.sh` |
| `modules/tls` | a **built** ZiguratIP | `sh modules/tls/build.sh` |
| `modules/tensorflow` | libtensorflow (the C API) | `sh modules/tensorflow/build.sh` |
| `modules/ray` | raylib | `sh modules/ray/build.sh` |
| `modules/numpy` | a python3 with numpy and a shared libpython | `sh modules/numpy/build.sh` |
| `modules/opencv` | an OpenCV 4 with dnn (pkg-config `opencv4`) | `sh modules/opencv/build.sh` |

`make modules` builds every one that can be built here and says SKIPPED,
by name, for the rest. **None of them is part of `make`** — which is the
point: a cocolog with no libtorch, no libcurl and no OpenCV still builds
and still runs.

**BUT `make` NEEDS A BUILT ZiguratIP, and this file and README both used to
say otherwise.** The sentence above once read "no libtorch, no ZiguratIP
headers and no libcurl", which is true of the MODULES and reads as a claim
about `make` — and that is how it was read: a cicili-lang session spent an
afternoon on a fresh Ubuntu clone before finding that `make` dies in Cicili
with `FILE-DOES-NOT-EXIST … embed/mvccs-lib.cicili`, a symlink
`embed/build.sh` makes into ZiguratIP's checkout. The embedded store IS part
of the binary and links `libCore` and `libStreamIO`; there was no flag.

**`make EMBED=0` is that flag now.** It skips `embed/build.sh`, drops
`embed/.libs/embed.o` and ZiguratIP's two libraries from the link, and
relies on the machinery that was already there: the engine's entry points
are declared weak (`CE_WEAK` in `client/zigurat.c`), so they bind to null
rather than failing the link, and `zg_open_embed` already refused by name
when `ce_engine_open` is null — *this build carries no embedded engine*.
So `--embed` is the only thing given up. Measured here: **381 KB against
632 KB**, `--local` and the wire arrangements both fine, tier-2 `.pl`
libraries and dlopen'd `.so` modules both loading. The default is still 1,
and the full binary is what every suite line and every `--embed` claim in
this file is measured against.

**A thing belongs in tier 2 when its dependency should not be
everybody's**, and that argument ate three modules that used to be tier 1.
tcp was swept into `cocolog.c` by the Makefile's wildcard; torch and
bigint were objects in the link reached through weak symbols, so **every
link needed libtorch and libCore** for two modules most programs never
call. The binary went from 936 KB to **585 KB** and `ldd` now shows no
torch at all. What is left of its C++ dependency is the embedded store,
which genuinely is part of the binary.

**The conversion is small and the same every time.** `coco-defmodule` —
which names an entry point the composition root calls — becomes
`coco-deflibrary`, or for the two C++ ones a hand-written
`coco_library_entry` **inside their `extern "C"` block**, because a
mangled entry point is one `dlsym` will not find. A loadable module holds
the engine as an OPAQUE pointer, so `(coco_new_int (-> e m) V)` — reaching
through the engine for its machine — becomes `(coco_m_new_int e V)`. And
the target names its own headers, instead of borrowing `cocolog.cicili`'s.

**Two things bite.** A file compiled ON ITS OWN must have no `DEFPACKAGE`:
it expands to an `EVAL-WHEN` that Cicili then reads as a Cicili form, and
the error is `unknown symbol: EVAL-WHEN`, which names the expansion and
not the cause. And **every `.pl` that calls a moved predicate now needs
the directive** — 27 tutorials, the coworkers, and the heredocs inside the
tests. `tensor_*` belongs to torch as much as `torch_*` does, which a
sweep looking only for the latter will miss.

**A C++ LIBRARY BECOMES A MODULE ONE WAY, and it is the owner's standard.**
The module is ONE Cicili file with `(make :cpp #t :compile #f)`. Every
C++ call and every C++ type in it is a Cicili clause -- `(cv::imread path
flags)`, `(($ m channels))`, `(letin* ((pts ((t<> std::vector
cv::Point)))) …)`, `(try … (catch ((const cv::Exception & ex)) …))` --
written against a DECLARATION BINDING under Cicili's `lib/cpp/<lib>/`,
the shape `lib/cpp/torch` has: a package, an `init-macro` that declares
what the module uses and emits nothing, imported inside the target. The
SDK is declared raw in an `extern "C"` block first, and everything
cocolog reaches -- `coco_library_entry`, the dispatcher -- sits in
`(extern-c …)`. **Not C++ pasted into `(code "…")` lines, and not a
`.cpp` beside the file**: `code` is the fire escape for the one thing
Cicili cannot say (an operator overload, a macro), and a back end made of
pasted C++ is a back end the front end cannot see. Every C++ module is
written this way now: `opencv` over `lib/cpp/opencv`; `sha`, `aes`,
`bigint`, `der`, `x509` and `tls` over `lib/cpp/zigurat` (one part per
ZiguratIP header, importable alone); `torch` over `lib/cpp/torch` with
`lib/cpp/dl` for the sibling it dlopens. What `code` still carries in
them is the SDK's C prototypes and a function-pointer typedef, nothing
else. (A LIBRARY'S OWN SOURCE is a different thing from pasted code:
`modules/opencv/pil/Resample.c` is Pillow's resampler, unchanged and
licensed, compiled as C beside the module and reached through one declared
entry -- a back end that is somebody else's, kept whole so it stays
byte-exact.) `doc/DOC-CPP.md` in the Cicili checkout is the C++ half of the
language, and `modules/README.md` lists what bites when writing one.

**WHAT A `coco_m_*_error` RETURNS IS THE PREDICATE'S ANSWER, NOT A STATUS,
and a helper that raises must hand it back rather than swallow it.** The
raise answers **2** -- the builtin protocol's "the continuation is already
set", because the recovery goal is on it -- so a caller that writes the
ordinary guard

```lisp
(if (not (ray_iarg e g 0 (aof x))) (return 0))        ; WRONG
```

tests `not 2`, which is FALSE, and the guard never fires: the predicate
carries on with an uninitialised value and then answers 1, success, with a
ball in flight and the engine about to put the caller's continuation back
over the recovery. It is not a failed call and not a raised one; it is
neither, and the process usually ends. **All sixty-six guards in
`modules/ray` were this**, and CivV found it the expensive way -- an icon's
centre computed as `X + Size * 0.64`, and `ray_circle(20.5, 20.5, 5.5,
white)` killing the window with nothing `catch/3` could hold. Two shapes are
right, and the module directories hold one of each:

```lisp
(let ((int rc . #'(ray_iarg e g 0 (aof x)))) (if (!= rc 1) (return rc)))
(let ((int rc . 0) (int s . #'(th_mutex_arg e t (aof rc)))) (if (< s 0) (return rc)))
```

-- pass the raise straight through, or have the helper answer 0 and carry
the raise out in a parameter (`modules/thread`, `modules/numpy`).
`modules/tensorflow` takes the third road and raises at the call site,
`(return (coco_m_type_error ...))`, which is the same rule seen from the
other end. **The tell is a helper that both RAISES and returns int**: every
one of its callers is a place to check. cicili-lang reached the identical
rule from its own segfault -- a helper of theirs raised, returned its own
answer, and the caller walked on into LLVM with a null module.

**A HANDLE IS AN INTEGER, SO LOSING ONE LEAKS WHAT IT NAMES, SILENTLY.**
Every handle-table module -- `tcp`, `tls`, `ray`, and anything else that
hands out a slot -- gives Prolog an INDEX and keeps the real thing in its
own table, which is what lets a socket or a render texture cross a channel
and survive a term copy. The cost is that a handle has no lifetime of its
own: nothing in the engine knows the integer means anything, so
`nb_setval(Key, none)` over one, or a `retract` that drops the fact holding
it, frees NOTHING and warns about NOTHING. Found in CivV, which dropped a
canvas handle out of a cache at the top of every half and took a fresh slot
from ray's 256 each time; the table is bounded, so the symptom is eventually
a `ray_canvas/3` that simply fails, arriving long after the cause.

**The probe is to exhaust the table on purpose**: call the allocating goal
in a loop until it fails, count the successes, and do it again after the
code you suspect. 255 before and 255 after is the shape of a clean one --
CivV's read 255 either side once the drop unloaded first. Free before you
forget, and where two caches hold the SAME handle only one may free it.

**WHAT A `build.sh` MAKES IS NEVER COMMITTED**, and every module
directory here is the same shape: a `.cicili`, a `build.sh`, and output.
Output is the `.o`, the `.so`, the C or C++ Cicili generates, *and the
symlinks* — `modules/curl/sdk.cicili` points inside this checkout,
`modules/bigint/zigheaders` inside ZiguratIP's, and both dangle in anyone
else's clone. Five such files were tracked and are not now.

The mistake is easy because the output sits beside the sources —
`library/` holds `http.pl`, which *is* source — and because a transpile
is deterministic, so a stale artifact never looks stale. `make clean`
had been deleting two of these tracked files for a while, which means a
clean clone could dirty its own tree by cleaning.

**The test is to delete everything a `build.sh` makes and run it.** What
comes back was output; what does not was source. Both times it was worth
doing: `modules/curl/` came back with an implicitly declared `toupper`,
because nothing had ever compiled that file without a stale `curl.c`
beside it, and `modules/bigint/` came back byte for byte.

**THE PATH IS ANCHORED TO THE BINARY, not to the working directory**, and
that was a bug worth naming. `./library` finds what shipped only when
cocolog is run from its own checkout — an installed one, or one invoked
from a project directory, could not load its own libraries. And it was
not merely unhelpful: `./library` is a directory somebody else may
control, so a cocolog run inside an untrusted tree would prefer THEIR
`library(lists)` to its own. `/proc/self/exe` is the kernel's exact
answer to "which file am I" — no argv[0] guessing, correct through
symlinks. The caller's `$COCOLOG_LIBRARY` still comes first, because an
override that cannot override is not one.

## A directive is a GOAL, and `initialization` puts one off

**`:- G.` RUNS G.** Not a whitelist any more: `coco_directive` answers the
handful that must act on the READER while the file is still being read —
`op/3`, `set_prolog_flag/2`, `dynamic/1`, `discontiguous/1`, `multifile/1`,
`module/2`, `use_module/1,2`, `autoload/1,2`, `ensure_loaded/1`,
`meta_predicate/1`, and `if/elif/else/endif` — and **everything else is
called**, in file order, so `:- assert(config(fast)).` sees the clauses
above it and the directive after it sees what it asserted.

**The store is still compiled below the engine.** What made this possible
is a second hook beside the `use_module` one: `coco_goal_install`
(`lib/kb.cicili`), filled in by `lib/library.cicili` with a function that
opens an engine over the same machine and store. A store with no engine
over it — the schema compiler — still refuses a directive by name rather
than crashing, and says so.

**`:- initialization(G).` runs G when the FILE has been read**, which is
the point of it: a goal at the top may call a predicate defined at the
bottom. `initialization(G, now)` runs it where it stands.
`initialization(G, main)` runs it after the load and then **halts** — 0
proved, 1 failed, 2 threw — so the CLI's own goal never runs, exactly as
`swipl script.pl` behaves. Any other `when` names a saved state and is
refused by name.

**A DIRECTIVE THAT FAILS OR THROWS NO LONGER ENDS THE LOAD.** It is
reported in SWI's shapes, which were measured against `swipl` and not
remembered:

```
ERROR: p.pl:4:
ERROR:    Unknown procedure: nosuch_goal/0
Warning: p.pl:5:
Warning:    Goal (directive) failed: fail
Warning: p.pl:1: Initialization goal failed
```

**A syntax error is now the ONLY thing that ends a consult**, and it has
to be: after one the reader does not know where the next clause begins.

**Consulting a file REPLACES the clauses it put in the store last time.**
Every clause a consult reads is owned by the file, under its real path
(`coco_pred`'s `origins`, beside `clauses`), and the first clause of each
predicate the file defines takes the file's old clauses of it out before
going in. What a program asserted, and what another file put there, is
untouched — and on the wire the owner travels with the clause as
`'$from'(Path, Clause)` in the same text column, unwrapped at fetch, so a
row written before this existed is a bare clause nobody replaces. The
store used to APPEND, so the second of the three processes a tutorial
runs against one store held two copies of every clause. `test/reconsult.pl`
is the case; a test that built a program by rewriting one scratch file
per clause (`test/ruler.pl` did) now writes one file per clause.

**An uncaught exception reads as a sentence.** `coco_error_text`
(`lib/solve.cicili`) turns a ball into SWI's words — `Unknown procedure:
main/0`, ``Arithmetic: `foo/0' is not a function``, `Unknown message:
my_ball` for a ball that is not an `error/2` — and the CLI prints `ERROR:
-g main: …`. **The exit status is SWI's: 0 proved, 1 failed silently, 2
threw -- and `halt(N)` is N, from `-s`, `run` and `query` alike, with a
bare `halt` as 0.** Until 1.2.4 a halt exited 1 whatever N, because the
engine reports a halted goal as "no more solutions" and the three
commands read that as `main` failing; `test/ray.pl` found it by skipping
its windowed half with `halt(0)` after every check had passed and
coming out RED. `test/argv.pl` pins all three. A test that expected 1 for a thrown ball wants 2 now.

`test/directives.pl` is the case, and its last section runs the same files
under `swipl` and diffs what the programs printed.

## The string type, and the flag that decides what `"..."` is

**There IS a string type** — SWI's, as a sixth cell tag (`STR 5` in
`*cell-tags*`), an index into a per-machine table of `(pointer, length)`
pairs. `string/1`, `string_concat/3`, `split_string/4`, `sub_string/5`,
`atom_string/2`, `string_to_atom/2`, `number_string/2`, `string_codes/2`,
`string_chars/2`, `term_string/2`, `text_concat/3`, `string_length/2` and
`string_lower/upper/2` all answer, and `format(string(S), …)` and
`with_output_to(string(S), …)` build one.

**THE C HALVES ARE THE ENGINE'S, not `lib/builtins.cicili`'s** — thirteen
entries in `*builtins*` in `lib/solve.cicili`, beside `atom_codes/2`.
`sub_string/5` is the one piece in the builtins module, as clauses, because
it is nondeterministic in two arguments and a C half has no choice stack.
A `string(_) :- fail.` clause and a comment saying cocolog has no string
type lived in `lib/builtins.cicili` until 1.2.1: **shadowed and therefore
dead** — dispatch is construct, C builtin, module, store, so a C-registered
name never reaches the knowledge base — but `listing(string/1)` printed it,
which told a reader the opposite of what the interpreter does, and MODULES.md
had taken the claim from that comment. `listing(string/1)` fails now, the way
it does for any predicate with no clauses of its own.

**THE REASON IT EXISTS IS THE NUL.** An atom is a NUL-terminated name in a
table, so `atom_codes(A, [0'a, 0, 0'b])` gives a ONE-character atom. A
string of the same three bytes is three characters and comes back whole.
Everything else about the type follows from that one difference; the
standard order puts it between atom and compound, which is SWI's.

**`double_quotes` TAKES ALL FOUR OF SWI'S VALUES** — `codes` (the ISO
default and cocolog's), `chars`, `atom`, `string` — and the flag really
changes what the reader builds. `:- set_prolog_flag(double_quotes, string).`
at the head of a file makes every `"..."` in it a string.

* **It takes effect for the REST OF THE FILE, not for the directive's own
  term** — the term is read before the directive runs. SWI's order too.
* **It is PER-MACHINE, and it is forced back to `codes` across a module
  load.** `lib/solve.cicili` saves it around `coco_extern_load` because the
  vendored SWI libraries in `lib/swipl` are written for codes and a
  caller's choice must not reach inside them. So a `-s FILE` whose file
  sets the flag gets what it asked for, and the goal that loaded it does
  not. Without that guard a file with no string in it failed to load at
  all, which is how the guard was found.
* **A fifth value is refused by name**, and the refusal is now REPORTED
  rather than fatal — `ERROR: p.pl:1:` and the reason, then the load goes
  on with the flag unchanged. A flag accepted and not honoured makes every
  `"..."` in the file mean something other than it says, which was the
  argument for refusing `string` back when there was nothing to build.

**TWO TEXT SEAMS TAKE A CHAR LIST, and both had to be taught to.**
`coco_m_text` in `lib/module.cicili` (format, and every module asking for
a name) and `coco_codes_to_text` in `lib/solve.cicili` (the string
builtins) walked a list of CODES only. Under `chars` a file's own format
strings are `[a,b,c]`, so `format/2` raised `type_error(text, [a,n,s,…])`
from the format call itself, and `string_length("ab", N)` fell through to
writing the term and answered 5. **A flag you can set and cannot use is
not a feature**, and the second of those is the silent kind.

**A STRING WITH A NUL IN IT IS REFUSED BY `coco_m_text`, not truncated.**
That seam hands back a C string and the buffer cannot carry one;
`string_codes/2` is the way to read such a string and does not go through
it.

**A STRING DOES NOT SURVIVE THE STORE OR A CHANNEL — it comes back as
CODES.** Measured, in both: `assertz(note("hi"))` under the flag, read
from a second process through `--embed`, answers `[104,105]`; the same
string through a `library(thread)` channel arrives the same way. This is
NOT the flag's doing — it was true from the day the type landed, and the
flag only makes it easy to reach.

The cause is one line of the existing design meeting the new type. A
clause travels as canonical text and is parsed by whichever process
fetches it, and `lib/syntax.cicili`'s own comment says why that text is
written with operators IGNORED: a clause written with an operator "could
only be read by a process that had made the same declaration".
`double_quotes` is exactly that hazard again — a per-machine READER
setting that makes canonical text mean different things in different
processes — and the canonical reader honours it.

**The fix looks small and is not a small change.** A string writes
canonically as `"hi"` and a code list as `[104,101,…]`, so the two have
distinct canonical spellings and forcing the canonical reader to
`string` would be lossless and exact. What makes it a pass of its own is
that `coco_read_term_from` serves the store's fetch, the module API's
`coco_m_read_term`, and the user-facing readers (`term_to_atom/2`,
`term_string/2`) — and those last ones SHOULD honour the flag, the way
SWI's do. So it needs the two readers split, and it touches all three
knowledge-base arrangements, which means the cross-process claim has to
be re-proved rather than assumed. It is written down here rather than
done in passing.

`test/string.pl` is the case — 39 checks, and the four flag values are
checked through FILES rather than `query`, because a one-goal query can
never see its own flag change. Tutorial `basics/08` is the lesson.

## The three document libraries, and the rules they share

`library(json)`, `library(xml)` and `library(html)` go both ways: a term
out as a document, a document back in as a term. All six halves are DCGs,
all three answer **codes** when writing (an atom is a C string and stops
at the first NUL; codes are what `tcp_write/2` wants), and all three take
**codes or an atom** when reading.

| | write | read |
|---|---|---|
| the whole thing | `json_codes/2,3` `xml_codes/2,3` `html_codes/2,3` | `json_parse/2,3` `xml_parse/2,3` `html_parse/2,3` |
| as an atom | `json_atom/2,3` `xml_atom/2,3` `html_atom/2,3` | — the readers take an atom |
| to the output | `json_write/1,2` `xml_write/1,2` `html_write/1,2` | — |
| in your own grammar | `json_value//1` `xml_content//1` `html_content//1` | `json_input//1` `xml_input//1` `html_input//1` |

**THE ROUND TRIP IS THE REAL TEST.** Write a document, read it, write it
again, compare the two texts — a reader and a writer that disagree about
the same bytes are worse than either alone, and no amount of hand-written
expectations on each half finds a disagreement between them. Six cases in
`test/serialize.pl` do exactly that.

`html.pl` stands on `xml.pl` by NAME — `xml_escaped//1`,
`xml_text_codes/2`, `xml_no_nul/2` — rather than by copy. One namespace is
the reason that works, and a private copy of an escaper is how two
escapers end up disagreeing about the apostrophe. **The UTF-8 encoder IS
copied**, three times, and the distinction is the point: an escaper
encodes a POLICY, which drifts; RFC 3629 is a fixed transform, which
cannot, and copying it is what lets `json.pl` stand alone rather than
importing a markup library to read a `\uXXXX`.

**A CODE LIST IS A LIST, IN ALL THREE, and `str/1` is the way out.**
`double_quotes` defaults to `codes`, so `"hello"` IS `[104,101,…]` unless
the file set the flag — and a serialiser that guessed would turn a JSON
array of byte values into a word, or `element(p,[],["hello"])` into
`<p>104101108108111</p>`. That second one is not hypothetical: it is what
`xml.pl` did before the rule, and the case is in the suite. So a bare list
is an array (JSON) or an error (XML, HTML), and `str(X)` is how you say
you meant text.

**THEY THROW RATHER THAN GUESS.** An unbound variable is not `null`;
`foo(1)` is not `"foo(1)"`; `@(maybe)` is not a literal; `<br>text</br>`
is not markup. Every refusal names the term, because the alternative is a
document that parses into something else three days later.

Five places where they deliberately differ from each other, each because
the LANGUAGES differ:

* **`<br/>` vs `<br>`.** XML self-closes an empty element; HTML's void
  elements close by being themselves, and giving one children is an error.
* **`--` in a comment.** XML 1.0 forbids it outright with no escape, so
  `xml.pl` refuses; HTML5's tokenizer ends on `-->` and nothing else, so
  `html.pl` allows `--` and refuses `-->`.
* **`indent(N)`.** `xml.pl` has it and indents only element-only content,
  because a whitespace node between elements is what a schema-aware reader
  ignores and a text child makes the content *mixed*. `html.pl` has NO
  indent option: whitespace between two inline elements is a rendered
  space, so an indenter there would be a renderer that quietly edits.
* **An unknown entity.** `xml.pl` refuses it — XML declares entities in a
  DTD and an undeclared one is an error the spec names. `html.pl` leaves
  it as text, because HTML's table has two thousand names and a browser
  leaves anything not in it alone. That is what makes `AT&T` render as
  `AT&T`.
* **The shape that comes back.** `xml_parse/2` answers ONE element
  because XML requires exactly one root; `html_parse/2` answers a LIST
  because HTML does not — and a list is what `html_codes/2` takes at the
  top, so the two compose with no wrapper.

**The one security-shaped check in the three is `</script`**, in any case,
inside a `script` or `style` element — where escaping is not the answer,
because `a < b` must reach the JavaScript parser as `a < b`. That is also
why `json.pl` does not escape the solidus: the hazard lives at the
embedding, and it is caught there, by name. The parser is the other half
of the same rule: it reads a script verbatim to the matching end tag, so
what the writer refused to emit is exactly what would have broken the read.

**THERE IS NO DTD, AND THAT IS THE XXE ANSWER.** `xml.pl` skips the
DOCTYPE — internal subset and all — and has no code that could open a
file or a socket, so the whole external-entity family is structurally
impossible rather than defended against. An entity a DOCTYPE declared is
therefore never defined and `&whatever;` is an error naming it, which is
the honest answer: the parser cannot know what it expands to.

**`html.pl` IS NOT AN HTML5 TREE BUILDER**, and its header says so at
length. It handles void elements, raw text, optional end tags,
case-insensitive names, unquoted and bare attributes, a `<` that begins
no tag, and misnested end tags. It does NOT do implied
`<html>`/`<head>`/`<body>`, foster parenting, or the adoption agency. A
half tree builder is worse than none, because it produces a tree that
looks right and quietly is not the one a browser built.

**CSS PARSES IN `html.pl` TOO — `css_parse/2`, `css_declarations/2`,
and the writers `css_codes/atom/write` — because CSS lives inside HTML
twice**: a `<style>` element's raw text and a `style="..."` attribute,
both exactly what `html_parse/2` just handed you. A stylesheet is a
list of `rule(Selectors, Decls)` and `at/2,3` terms; `!important`
surfaces as `important(Value)`; properties fold to lower case except
case-sensitive `--custom` ones; and the scanner respects strings,
parens and brackets, so a `;` inside `url(...)` is content. It is NOT
a value parser or a selector-tree builder (a value and a selector come
back as the atoms they were written as, stated in the header), and it
throws rather than guesses in both directions — the writer checks with
the reader's own scanner, so nothing it emits reparses as a different
stylesheet. Round trips in `test/serialize.pl`, lesson in tutorial 14.

## ZiguratIP's cryptography, imported rather than rewritten

Four modules and one Prolog library, all tier 2, all with prefixes of
their own — nothing is called `zigurat_anything`:

| | is | links |
|---|---|---|
| `library(sha)` | `sha_hash/3`, `sha_hmac/4`, `sha_file/3` — SHA-1/224/256/384/512 | libCryptography |
| `library(aes)` | `aes_encrypt/4` (CBC), `aes_pad/2`, PKCS #7 | libCryptography |
| `library(der)` | `der_encode/2`, `der_decode/2` — DER as terms, both ways | **libEncoding only** |
| `library(x509)` | the whole `ca` tool: keygen, csr, issue, validate, sign, verify, encrypt, decrypt | libCryptography |
| `library(ca)` | clauses only: trusted roots, enrolment, and authorisation as a RULE | — |
| `library(tls)` | `library(tcp)` with a handshake in front of it | libSocketIO |

**THE SPLIT IS ARITHMETIC / GRAMMAR / POLICY**, and it is the answer to
"import it or write it in DCG":

* **Arithmetic is bound, never rewritten.** RSA modexp, AES rounds, the
  SHA compression function. A Prolog implementation is not merely slow,
  it cannot be made constant-time, so a private-key operation would leak
  by timing. There is no hash or cipher code in any of these files.
* **Grammar is Prolog.** `library(der)`'s C++ half knows ONE tag-length-value;
  walking a sequence of them is a two-clause recursion, and it is written
  as one. Note where the C++ gave up: `x509.cpp` reaches for OpenSSL's
  ASN.1 rather than hand-rolling DER.
* **Policy is clauses.** `ca_may/2` and `ca_covers/2` are four lines you
  can read, `listing/1` and argue with. That is the part that is better
  here than in any C++ stack.

**`library(der)` LINKS NO CIPHER**, which is worth stating: `Zigurat::DER`
lives in libEncoding beside base16/32/64, so everything a certificate is
made of can be taken apart with no OpenSSL in the process.

**KEYS ARE FILES, NOT TERMS**, and that is the one design decision to
preserve. A private key read into an atom would be on the heap, in the
trail, in every copy a channel made of the term holding it, and in the
knowledge base the moment anything asserted it. This project's whole
claim is that a clause is a row somebody else can read; a signing key is
the one thing that must never become one. `getenv/2` is how a pass
phrase arrives, for the same reason.

### Five things that cost time here, all recorded

* **A `:cpp #t` target must declare the SDK's prototypes RAW, inside
  `extern "C"`, before `(coco-sdk)`.** Otherwise C++ gives them C++
  linkage, the `.so` links cleanly, and `use_module` fails with
  `undefined symbol: _Z11coco_m_textP18coco_engine_opaquemPcm` — a
  mangled name for a function the interpreter exports unmangled.
  **Wrapping `(coco-sdk)` in `(extern-c ...)` is NOT the fix**: a macro
  must emit ONE form, and several leaves every symbol unregistered, so
  the next reference is `unknown symbol: coco_m_domain_error`.
* **`$`-prefixed predicate names must be QUOTED in a module's Prolog
  half.** `$` is a symbol character and `x` is alphanumeric, so
  `$x509_issue` is two tokens and the clause will not read — surfacing
  as `use_module: its clauses would not consult`, which names the module
  and not the line. `lib/builtins.cicili` writes `'$cp_member'`.
* **Which library a symbol is in is not guessable, and a miss LINKS
  FINE.** `DER::encode_oid` is in libEncoding, not libCore; a shared
  object may leave a symbol undefined, so it surfaced at `use_module`.
  `nm -D --defined-only` over `home/lib` settles it.
* **Name every transitive dependency.** `-rpath` applies to what THIS
  link records as needed; libCryptography's own libConfiguration is
  looked for on the system path. `libConfiguration.so: cannot open
  shared object file`, at `use_module`, from a link that succeeded.
* **`X509::issue`'s issuer argument is a NAME CONFIGURATION, not a
  certificate.** Handing it the issuer's `.crt` fails deep inside the
  configuration parser with `key error at line 1, '0\x82\x03...'` — a
  message about a config file, naming DER bytes, from a certificate
  routine. `ca/main_ca.cpp` documents `--issuer` as "issuer name
  configuration file".

### Four transports, spelled out

The arrangement a run uses is now named rather than inferred:

| | is | default port |
|---|---|---|
| `--tcp [PORT]` | the binary protocol, in the clear | 2160 |
| `--tls [PORT]` | the binary protocol over TLS | **2160** |
| `--http [PORT]` | Zeytun, plain HTTP | 80 |
| `--https [PORT]` | Zeytun over TLS | 443 |

**`--tls` KEEPS THE PORT AND `--https` CHANGES IT**, and the asymmetry is
ZiguratIP's rather than ours: `SERVER/TLS_MODE: TRUE` changes *what is
on* 2160, while 80 and 443 are two different ports. Read
`home/etc/ziguratip.conf` before assuming either.

**A CLIENT CERTIFICATE IS OPTIONAL, AND MANDATORY FOR PERMISSIONS.** Both,
and they are not in tension. `loadzigurat.cpp` accepts REQUIRED (the
default), OPTIONAL and NONE for `SERVER/TLS_CLIENT_AUTH`, and
`require_security()` demands only the SERVER's own certificate, key and
authority — so `--tls` with nothing but `--cacert` is a real arrangement.

What a certificate is *required* for is `SECURITY/PERMISSIONS_MODE`.
`zigurat_tls_handler` calls `Globals::set_peer(...)` for **every** TLS
peer, certificate or not, and `Globals::permits` opens with
`if (!_identified) return true;` — the header says it outright:
"Unidentified means a plain connection, where there is no peer to ask
about and everything is allowed — turning TLS on is what turns access
control on."

| connection | `PERMISSIONS_MODE: TRUE` reaches |
|---|---|
| plain | everything — unidentified |
| TLS, no client certificate | **nothing** — identified, empty subject, empty permissions |
| TLS with one | what the certificate grants |

That is the same permission list `library(ca)` reads out of a
certificate, on the other side of the same seam.

**A MISSING CLIENT CERTIFICATE IS NOT A FAILED HANDSHAKE.** Under TLS 1.3
the server does not examine what the client sent until the client has
finished talking, so `SSL_connect` SUCCEEDS and the refusal arrives as an
alert on the first read. `client/tls.c` keeps the reason in the handle
and `coco_client_tls_why` hands it back, so the client says
`read failed: tlsv13 alert certificate required -- this server wants a
client certificate: --cert and --key` rather than `read failed: Success`.
Every test that asserts a TLS-1.3 refusal must check what the peer
*reaches*, never whether the connect returned.

**`--port` IS DEPRECATED**, and still accepted: it is exactly `--tcp
PORT`. It named a number when there was one transport. Nothing warns —
the flag is a spelling, not a mistake, and a line on stderr every run
would land in the output of every script that pipes cocolog — and
nothing in this tree spells it any more. `test/zigurat-lib.pl` holds it
to both halves: that it still reaches the server, and that it says
nothing on stderr.

**`--tls` and `--https` together are refused**: one names a Zigurat and
the other a Zeytun, and a run reaches one knowledge base.

**One TLS unit, `client/tls.c`, for both clients**, because a handshake
is a handshake — and its functions are `coco_client_tls_*` rather than
`coco_tls_*` because `library(tls)`'s module already owns the latter and
both live in one process when a cocolog serves and queries at once.

### `--https`, and two bugs it uncovered in the arrangement it joined

The Zeytun client speaks TLS: `--https [PORT]` (443 by default) beside
`--http [PORT]` (80), with `--cacert`, `--capath`, `--cert`, `--key`,
`--key-pass` and `--insecure`. Both ports are now OPTIONAL, the way
`--embed`'s directory is — a querier behind Cloudflare should not have to
know what port an edge listens on.

**The TLS is in `client/tls.c` and nowhere else.** `zeytun.c` is
still libc and the sockets API: it reaches OpenSSL through six functions
behind an opaque pointer, and a build without OpenSSL compiles that
file's stub half so `--https` reports the missing feature by name rather
than failing to link. The Makefile probes for `<openssl/ssl.h>` and
defines `COCO_ZT_TLS` when it is there.

**The hostname is checked, not just the chain**, and that is the check a
hand-rolled client forgets: a certificate valid for somebody else is
exactly what a man in the middle presents.
`X509_VERIFY_PARAM_set1_host` is the instruction, and SNI takes the same
name — one decision rather than two.

**TWO REAL BUGS FELL OUT, both older than this change:**

* **`--http` dialled the binary server as well.** `open_connection` had
  no Zeytun branch, so a Zeytun run opened a connection on 2160 that it
  never used — and a querier that could only reach the HTTP edge got
  `no server at NAME:2160`. Which defeats the entire point of the
  tunnel. **It went unnoticed because the suite always has a server**:
  `test/tunnel.pl` raises its edge stand-in on localhost, where 2160 is
  answering too, so the extra connection succeeded and paid for nothing.
* **A failed Zeytun fetch was SILENT.** `coco_zt_fail` put the reason in
  `z->err` and answered 0, which the engine reads as "this predicate has
  no clauses" — so an unreachable edge, a refused certificate and an
  empty knowledge base were all `existence_error(procedure, p/1)`. That
  is unacceptable for a verification failure in particular: the whole
  purpose of checking a server's name is to REFUSE, and a refusal a
  reader cannot tell from an empty database is not one. It now prints
  `cocolog: Zeytun at HOST:PORT -- ...` on stderr. Only transport and
  HTTP errors reach it; a predicate with no clauses is a 200 with an
  empty body.

`test/tunnel.pl` gains a TLS-terminating edge stand-in — the arrangement
Cloudflare actually is — and checks a query through it, `--insecure`
going through loudly, and a **second** edge presenting a certificate for
a name nobody asked for, refused with `hostname mismatch`.

### `library(tls)`, and the objection that was wrong

**"cocolog has no stream layer" was the wrong reason not to bind TLS**,
and it is worth recording because it was written down here as settled.
`Zigurat::tlsstream` is a C++ iostream and there is genuinely nothing in
cocolog to hand one to — but nothing has to be. **The stream stays in
the module for its whole life and what crosses into Prolog is an INDEX
into a table**, which is exactly what `library(tcp)` does with a
descriptor. A TLS connection is no more a term than a socket is.

So `modules/tls` is `modules/tcp`'s shape: `Entry g_slots[256]`, each
either a listener or a connection, and a handle is a slot. An integer
this module did not hand out is not a connection — which is the
difference between a failed call and a closed stdout.

**The socket is ours in both directions**, and that is deliberate:
`coco_tls_connect` does `getaddrinfo`/`socket`/`connect` by hand rather
than using `tlsstream`'s host/service constructor, because owning the
descriptor is what lets `tls_read/4` put `SO_RCVTIMEO` on it. A
connection whose fd lives inside somebody else's stream can be waited on
for ever.

**`tls_read/4` is at-least-one-byte, at-most-max.** `peek()` blocks
until something arrives, `in_avail()` then says how much came with it.
A blocking `read(buf, max)` waits for ALL of max, so a reader asking for
4096 bytes of a 20-byte request never returns.

**Every refusal FAILS rather than raising** — a stranger, a certificate
this authority did not sign, and nobody arriving inside the timeout
alike, with `tls_why/1` to tell them apart. A server that raised would
stop serving everybody else because one impostor knocked.

**What the handshake answers is the interesting part.**
`tls_peer_subject/2` and `tls_peer_permissions/2` are settled during the
handshake, against the authority, before a byte moves — so a server does
not authenticate its peer and what is left is authorisation, which is a
`library(ca)` rule.

**`library(httpd)` DOES HTTPS NOW**, and only the transport changed. A
connection became a TAGGED TERM — `plain(S)` or `secure(S)`, a listener
carrying its credentials as `secure(S, Creds)` — and five predicates
dispatch on the tag: `httpd_sock_listen/3`, `_accept/4`, `_read/4`,
`_write/2`, `_close/1`. Routing, keep-alive, the path rules and
`httpd_answer/3` are the same code on both, which is the point of doing
it as a term rather than a flag: HTTPS cannot drift away from HTTP by
being maintained separately.

    httpd_serve(9443, [ tls([ certificate('node.crt'),
                              key('node.key'),
                              authority('ca.crt') ]),
                        workers(4) ]).

**The tag survives a channel**, so the worker pool is unchanged: a
channel copies in canonical text and `conn(secure(7))` reads back on
another machine exactly as `conn(7)` did.

**THE PEER'S IDENTITY REACHES A PAGE AS TWO SYNTHETIC HEADERS** —
`Tls-Peer-Subject` and `Tls-Peer-Permissions` — so a page reads them with
`http_header/3` like any other and needs no new predicate and no access
to the socket. `httpd_answer/3` stays a request in and bytes out, which
is what lets `test/httpd.pl` check every routing rule with no port open.

**THEY ARE STRIPPED FROM THE CLIENT'S REQUEST FIRST, on both
transports.** A client may send any header it likes; a server that merely
ADDED its own would leave two, with the client's first — which is the one
`http_header/3` finds. That is the standard reverse-proxy hole. On a
plain connection they are stripped and NOT replaced, so a page that
trusts them is closed to port 80 by construction. Both halves are in
`test/httpd-tls.pl`.

**`current_predicate/1` IS NOT AN AVAILABILITY PROBE**, and it cost a
debugging round here: it answers about the KNOWLEDGE BASE, and a
module's predicates are not clauses in it — so it says no for a library
that is loaded and working. The probe that replaced it, a call with a
throwaway port, raised `domain_error(port_number, 0)` from the library
that WAS there. The answer is to catch `existence_error` around the real
call and rethrow it with the build hint.

### And one finding about ZiguratIP, not applied

`x509.hpp` says `certificate_public_key` "yields a DER
SubjectPublicKeyInfo, the same shape the .pub files hold". It yields the
SPKI's **contents**: 289 bytes against `dont-use-public.key`'s 293,
which is exactly a four-byte `30 82 01 21` header. `der_wrap(48, K, S)`
puts it back. Documented in `modules/x509/x509.cicili` and in
`tutorials/library/26-x509.pl`; ZiguratIP is not patched for it.

## `sort/4` was an insertion sort, and `keysort/2` is `sort/4` (1.2.40)

**A TABLE OF THIRTY-FIVE THOUSAND WORDS TOOK TEN SECONDS TO KEYSORT, AND A
PROCESS THAT TAGGED ONE SENTENCE PAID FORTY-TWO SECONDS BEFORE ITS FIRST
ANSWER.** `coco_l_sort4` in `lib/lists.cicili` was an insertion sort --
"stable, and n is small in every use this has" -- and `keysort/2` is
`sort(1, @=<, L, S)`, so every keysort was quadratic: measured, 20 000
pairs in 1.03 s where `msort/2` took 0.009, and 35 081 in 10.6 s where
`msort` took 0.022. Nobody saw it because nothing keysorted more than a
few hundred things until the reasoning tagger's judge built its lexicon
(`tg_lexicon_classes`, ~55 000 pairs, 42 s) and the head rule its
known-word table (~35 000, 11 s), once a process -- and
`test/tagger.pl`'s across-processes section, whose children each pay
both, ran past `cocolog_out/2`'s 120 s and FAILED SILENTLY, `main`
failing with no red check, exit 1 and no verdict line. It is a bottom-up
merge sort now, stable by construction (the left run wins a tie, which
`bagof/3` needs), 20 000 pairs in 4 ms. **The tell was a probe, not the
suite**: the case's log ended after a green line with no RED or GREEN,
and timing the children by hand said 66 s and 40 s for work worth five.
A section that fails without a check line is a goal that failed, and
`proc_run/4` failing on its timeout is the first thing to suspect.

## `fork` refuses a process bigger than the machine, and `library(process)` spawns with `posix_spawn` now (1.2.41)

**THE SECTION ABOVE SAID `test/tagger.pl`'S CHILDREN RAN PAST THE 120 s
TIMEOUT. THEY NEVER STARTED.** The merge sort made each child worth ten
seconds where it had been worth sixty, and the across-processes section
went on failing exactly as before: `main` failing with no red check, exit
1, no verdict line. Traced from inside the case, `proc_run('true', 5000,
_, E)` FAILED there -- any command, `echo hi` included -- while the same
section standalone is green. What made it loud was one change to the
module: a spawn that cannot happen RAISES now, with the errno's own words,
where `coco_p_fork` answered -1 and `proc_run/4` turned that into a plain
failure. The next run said it in one line:

```
ERROR: -s main: proc_run: could not spawn a child: Cannot allocate memory
```

**IT IS `fork(2)` BEING REFUSED, AND THE PROCESS'S SIZE IS THE REASON.**
Read out of `/proc` while the case ran its torch training: **VmSize
19.2 GB, VmRSS 10.4 GB, four threads, on a 16 GB box with no swap.** Under
Linux's default `vm.overcommit_memory = 0` (the heuristic), a fork's copy of
the address space is charged one mapping at a time, and the heuristic
refuses any single request larger than physical memory plus swap
(`__vm_enough_memory`, OVERCOMMIT_GUESS: `pages > totalram_pages() +
total_swap_pages`) -- whether or not a byte of it is resident. Adjacent
anonymous mappings with the same flags MERGE into one, and a torch
allocator mmaps block after block, so the arena is ONE mapping the size of
everything it ever asked for. Confirmed with a probe that maps N untouched
gigabytes a gigabyte at a time and then forks and spawns:

| mapped | VMAs | largest | `fork` | `posix_spawn` |
|---|---|---|---|---|
| 4 GB | 25 | 4 096 MB | ok | ok |
| 12 GB | 25 | 12 288 MB | ok | ok |
| **17 GB** | 25 | **17 408 MB** | **Cannot allocate memory** | ok |
| 20 GB | 25 | 20 480 MB | Cannot allocate memory | ok |

-- the gigabytes land in one VMA (25 mappings whatever N is), the refusal
starts exactly where that VMA passes the machine's 16 GB, and nothing was
ever touched: VmRSS read **1 684 kB** with the 17 GB mapped. So a process
that has trained a network cannot fork, and the size of the CHILD --
`/bin/sh -c true` -- has nothing to do with it.

**`posix_spawn(3)` COPIES NOTHING, AND IT IS WHAT `coco_p_start` IS NOW.**
glibc implements it as `clone(CLONE_VM | CLONE_VFORK)` and Darwin in the
kernel: the child shares the parent's memory until its exec, so no mapping
is duplicated, none is charged, and a child costs the same from a 19 GB
process as from a one-megabyte one. The two things the fork child used to
do by hand are attributes: `POSIX_SPAWN_SETPGROUP` with group 0 for
`proc_run/4` (the group is what a timeout kills whole -- still measured:
`sleep 20 | sleep 20` under a 300 ms budget answers 124 and both sleeps are
dead) and `POSIX_SPAWN_SETSID` for `proc_spawn/2` (a session of its own,
checked against `/proc/PID/stat`'s sixth field); the pipe is three file
actions. **`POSIX_SPAWN_SETSID` IS SHOWN BY glibc ONLY UNDER `_GNU_SOURCE`**,
which `modules/process/build.sh` now defines on the compile line (Darwin
has the flag in the open and ignores the macro), and **`environ` IS A
VARIABLE A SHARED LIBRARY ON DARWIN MAY NOT NAME** -- the loader owns it and
`_NSGetEnviron()` hands back its address -- so the module reaches it
through `coco_p_environ`, defined either way under `@ifdef __APPLE__`.
`test/process.pl` is green on the new module, `test/tagger.pl` is green
end to end for the first time since its lexicon grew, and the version is
1.2.41 because a spawn that fails raises where it failed.

**TWO THINGS TO CARRY AWAY, and the first is a correction to this file.**
The 1.2.40 section's last sentence -- suspect the timeout first -- was an
inference from two standalone timings and not a measurement of the case,
and it was wrong: a section that fails with no red check and no error
term is a builtin ANSWERING 0 WHERE IT SHOULD RAISE, and the place to look
is the C, for a `(return 0)` on a syscall's failure. That shape is the
same one the module README records for an error call tested as a boolean,
seen from the other side. And **a `(code "...")` statement gets its
semicolon from the emitter**: a `;` written inside the string makes an
empty statement, and an empty statement between an `if` and its `else` is
`error: expected expression` at the `else` -- which is how the first build
of this died, naming a line that had nothing wrong on it.

## The engine was quadratic, and the fix is one call

**`coco_make` now dereferences every argument as it stores it**, in
`lib/term.cicili`. That one call is the difference between a linear
interpreter and a quadratic one, and it is worth knowing why.

An argument is kept as a REF cell pointing at the index it was given —
and `coco_arg` hands back a REF. So every structure built on a previous
one added a link, and **the continuation is exactly that**:
`$k(Goal, Barrier, Rest)` built on the `Rest` taken out of the last one.
A recursion 3 000 deep left a REF chain **8 999 links long**, and
`coco_deref` walked it on every engine step.

It was invisible until counted. `callgrind` put **85% of all instructions
in `coco_deref`**; an instrumented build showed 27 million hops with a
longest chain of 8 999. With the deref the longest is **2**.

| | before | after |
|---|---|---|
| `between(1,20000,_), fail` | 15 529 ms | **51 ms** |
| `findall` over 20 000 | 9 167 ms | **53 ms** |
| `between(1,100000,_), fail` | never finished | **226 ms** |
| naive reverse of 700 | 178 ms | 182 ms (noise) |

So it is enormous for deep recursion that backtracks, and free everywhere
else. `test/engine.pl` guards it with a **timeout at a hundred-fold
margin**, not a stopwatch with a threshold — the latter fails on a loaded
machine, and this property is coarse enough not to need the precision.

**Why deref-at-build is safe**, since it is the obvious worry: an argument
that is a bound variable gets stored as what it is bound *to*, and an undo
would put the variable back while the cell still pointed at the value. But
a cell built after a binding lives above that choice point's `heap_mark`,
and `coco_backtrack` sets `heap_len` back to the mark — so anything that
could see the stale value has already been dropped. It is the invariant the
WAM builds on, and the reason it dereferences into a structure too.

## The store reclaims what it no longer reaches (1.2.13)

**THE STORE NEVER SHRANK, AND `nb_setval/2` WAS THE BILL.** Every write
copies a whole term into the store's cell array -- a clause, a global's
new value, a thrown ball, each solution a `findall/3` keeps until its
search is over -- and until 1.2.13 nothing took one out: a retract dropped
the clause from its predicate and orphaned the cells, a global written
again pointed elsewhere. Reported from cicili-lang as a resident size that
doubled between identical runs, and measured with a one-off counting
build on their smaller fixture (a 12-line `std::map<std::string,int>`
program against libc++): **105 049 `nb_setval` calls, 103 192 of them
overwrites, put 1 073 MB into a store whose LIVE contents -- every clause
of every predicate and the current value of every global -- came to
20 MB.** Ninety-eight per cent garbage, plus 236 MB of findall solutions
nobody could reach either. The other 1.5 GB of that process was the heap,
which held the program's own terms (`./2` 452 MB, its type terms after
that, `$k/3` continuations 84 MB) and is reclaimed by backtracking exactly
as before -- the store was the half that had no story at all.

**COMPACTION COPIES WHAT IS REACHABLE AND DROPS THE ARRAY.** Every root the
store can still reach is one the store itself holds -- a predicate's
`clauses[]` entry or a global's cell -- and each term is copied out to the
heap and back into a fresh array by the two walkers that put it there
(`coco_store_get`, `coco_store_put`), the heap wound back after every one,
so a compacted term is exactly what an `assertz` of its copy would have
stored. Nothing else moves: `keys` hold cell VALUES, `chain` and `slots`
hold positions, `origins` hold atoms, so the first-argument index stays
valid across a compaction and `clause_ix` goes on meaning what it meant.
`coco_store_compact` in `lib/kb.cicili` is the whole of it.

**WHEN: at a safe point, once at least four million cells (32 MB) are
known dead and they outnumber the live ones -- or, as the net under that,
once the store has grown by as much again as it held at the last
compaction and by those 32 MB.** The dead are counted where a death is
cheap to see: a global's old value (its size is kept beside its cell), a
retracted or reconsulted clause and an initialization goal that has run
(each was just copied to the heap, and the copy's length is the span), a
findall's solutions (their puts are its own), a ball once caught. The
growth net is for whatever a site forgets to count, because the one it
forgets is the one that grows without bound; its price is a compaction of
a store that is all live once per doubling, the amortised cost of the
`realloc` it already pays, and the 32 MB floor means a small program never
compacts at all. The first draft counted growth alone, and 3 000 `asserta`
calls followed by 2 999 retracts kept 192 MB for 16 KB of clauses: the mark
had been set while everything was live, and a retract never lowered it. The check sites
are `nb_setval/2`, the assert and retract builtins, `abolish/1`, the end
of a findall, a caught throw and the end of a consult; the policy lives in
`coco_store_maybe_compact`. **`garbage_collect/0` forces one**, SWI's name.

**A SAFE POINT IS ONE WHERE EVERY CELL INDEX ANYBODY HOLDS IS ONE THE STORE
KNOWS ABOUT**, and two callers keep indices of their own for a while:
`coco_engine_findall` keeps each solution's root until the search is over,
and a consult keeps its `initialization/1` goals until they have run. Both
REGISTER their array with the store (`coco_store_root_push`, a stack popped
on the way out) and a compaction rewrites its entries like any other root.
Registered rather than declined -- the first draft declined under a hold --
because `forall/2` IS a findall and a script's whole life runs inside its
`initialization(main)`: a compaction declined under either would never
have happened. A ball is put and read back by the frame that catches it
with no goal run between; a clause is registered before its assert
returns; everything else that reads a cell reads it at once.

**`statistics/2` IS HOW A PROGRAM SEES IT**: `cputime` (seconds, a float),
`inferences`, `globalused` and `trailused` (bytes), `atoms`, `functors`,
and `store_used` -- the bytes the store's cell array holds, live and
orphaned alike, which is the number `garbage_collect/0` brings down. Any
other key is `domain_error(statistics_key, K)`. `test/gc.pl` is the case:
2 000 overwrites of a 128 KB global hold the store under 64 MB where 256 MB
would have accumulated and `garbage_collect/0` takes it under 8; clauses,
the index, a shared variable, a float, a string and a retract survive a
compaction; a findall whose goal compacts three times answers whole; a
consult whose directive compacts still runs the goals it put off; and
under `--embed` and on the wire what one process wrote reads back from the
next after a compaction on either side of a retract.

**MEASURED ON THE FIXTURE THAT REPORTED IT**: 37 s before and after, the
output byte for byte the same, and `statistics/2` at the end of the run
says heap 1 616 MB, store **53 MB** (from 1 323), trail 29 MB -- about
1.7 GB honest where it had been about 2.9 GB. (`maximum resident set size`
said 694, 737 and 1 701 MB across three runs of that one binary, which is
the Mac hazard below and not the engine; ask `statistics/2` instead.)

**AND `retract/1` SKIPS BY KEY NOW, which the new case found the expensive
way**: it copied every candidate clause whole on to the heap and unified
afterwards, no first-argument skip, so `test/gc.pl`'s 3 000 `asserta`
calls followed by 2 999 retracts of 16 KB clauses copied some thirty-six
billion cells and took **153 s**; one comparison against the key the index
already keeps per clause -- sound by the argument call resolution makes,
two different non-zero keys cannot unify -- makes it **1.1 s**. A float or
unbound first argument keys as 0 and skips nothing, and a rule asked for
as a fact is still refused by its body.

The heap is now the whole of what remains, and it is the program's: a heap collector
is still the item in STATUS.md's "Not started", and `\+ \+` around a phase
whose results go to the store is still the way a long deterministic program
gives the heap back.


**WHAT A COMPACTION COSTS WHILE IT RUNS, and it is not what it leaves (1.2.14).**
The new array used to be filled by `coco_store_grow` as the copy went in --
doubling from 64 cells, so compacting a large store was a LADDER of large
reallocs (16, 32, 64, 128, 256 MB), each a fresh region taken while the old
store was still held, and the last rung overshooting past what was needed.
It allocates the live size exactly once now -- `len` is an upper bound on
what is live and is known before the walk starts -- and trims the slack with
a shrinking realloc, which for a large block trims pages rather than copying.
Measured: peak footprint on a churn probe **573 -> 345 MB**, on thirty forced
compactions over a 64 MB store **205 -> 137 MB**, and large-block traffic from
86 blocks to a handful. The store's cap now equals what it holds after a
compaction, which is what the number `garbage_collect/0` moves ought to mean.

**A SEMISPACE WAS TRIED HERE AND REVERTED, and the measurement is the reason
to record it.** Keeping the old array to copy into next time removes a large
malloc and a large free per compaction -- and those are free on Darwin: 100
alloc/free cycles of 128 MB leave `phys_footprint` at **zero**, so a freed
large region goes straight back rather than sitting dirty in the allocator's
cache. The spare's footprint was real and its benefit was not. It is in
`coco_store_compact`'s comment so nobody pays for it twice.

**`statistics/2` ANSWERS THE CAPS NOW, AND THE CAPS ARE THE POINT**:
`store_cap`, `globalcap` and `trailcap` beside the three `used` keys, plus
`choicepoints`, `strings` and `compactions`. A length is what the program put
there and a cap is what the process is HOLDING, and an array that doubles sits
at up to twice its contents. CivV read `store_used` at 28 MB inside a window
whose footprint was 13.2 GB; the length was true and was not the question.

**AND EVERY ONE OF THEM IS ABOUT THE CALLING THREAD.** A machine, a store and
an engine belong to the thread proving on them, so a `library(thread)` worker,
a cowork crew member and every `run_isolated/2` proof have their own and NONE
of them appears in what the main thread's `statistics/2` reports. That is not
a gap to be closed -- a process-wide total would need a lock on the one
unguarded thing there -- it is a fact to know when a footprint and a reading
disagree: count the threads first (`ps -M`), because 122 worker machines at
128 MB each is 15 GB that no `statistics/2` call in the main thread can see.

**THE COMPACTION IS THIS PROCESS'S ARRAY, AND NOT THE STORE ON DISK.** Worth
saying outright, because a reader of the section above can take the two for
one thing and cicili-lang's notes did: `garbage_collect/0` moves `store_used`
and `store_cap`, which are the cell array THIS PROCESS holds, and it moves
nothing an `--embed` directory or a server holds. Measured on 1.2.16, one
writing process over a 20 000-row predicate, run with a forced compaction in
it and without: the compaction ran (`compactions=1`) and trimmed the cap from
2 097 152 to 1 288 752, and `data` grew by **7 151 616 bytes either way,
to the byte**. Two numbers, two questions, and only one of them is the disk.

**A WRITING PROCESS REWRITES THE WHOLE PREDICATE, AND `cocolog vacuum` IS
WHAT BOUNDS IT.** The Zigurat backend flushes a dirty predicate WHOLESALE, so
one `assertz` costs a copy of every row that predicate already held -- 358 to
369 bytes of new store per EXISTING row, measured at three sizes on a fresh
`--embed`, while a read-only process costs **0**:

| predicate rows | after the seed | one `assertz` adds | per existing row |
|---|---|---|---|
| 200 | 114 688 | 73 728 | 369 |
| 2 000 | 753 664 | 720 896 | 360 |
| 20 000 | 7 192 576 | 7 151 616 | 358 |

The old rows stay dead, so every process pays it again and the store carries
every generation. **A vacuum after the write takes all of that away, and the
TIME with it** -- ten successive writing processes over that 20 000-row
predicate:

| build | no vacuum, s | no vacuum | vacuumed, s | vacuumed |
|---|---|---|---|---|
| 1 | 1.05 | 13 MB | 1.06 | 13 MB |
| 5 | 1.82 | 40 MB | 0.89 | 13 MB |
| 10 | **2.78** | **75 MB** | **0.87** | **13 MB** |

-- the vacuum itself 0.36 s, every row kept. Without it each build is slower
than the one before, which is the shape a slow suite has and is worth knowing
before the engine is blamed. The file does not SHRINK below its high-water
mark and does not need to: the space is reused, which is why the vacuumed
column is flat rather than falling. (Reported from cicili-lang, which
abandoned its C++ header cache over this -- `cicili++` runs `--local` and
re-reads its headers every run -- having read the reclamation as impossible
rather than as one command. The probe that made them stamp and restart the
store is gone as 1.2.2 said: 300 distinct predicates, first call each, 0.096 s
over an 11.5 MB store.)

**AND ONE PROCESS'S WRITE WAS QUADRATIC IN THE ROWS IT WROTE, the wall no
vacuum moved -- diagnosed and fixed in ZiguratIP since; what was measured
first, and then what it was.** The assert loop is linear -- a flat 3.8 µs a
clause from 1 000 to 16 000, 3.0 µs under `--local`. The commit was not:

| rows one process writes | total | µs a row |
|---|---|---|
| 16 000 | 0.53 s | 33 |
| 32 000 | 1.42 s | 44 |
| 64 000 | 5.77 s | 90 |
| 128 000 | **26.9 s** | 210 |

Doubling the rows roughly quadruples the time, and **splitting them over more
predicates does not help**: 128 predicates of 1 000 rows took 29.0 s against
24.9 s for one predicate of 128 000, the cost merely moving out of the commit
and into the loop. That made a process comfortable to about 30 000 rows --
~1.3 s, and flat however the rows are split -- and expensive past 32 000, and
it is almost certainly what a cicili-lang read of one C++ file over a fresh
store was when it ran past five minutes.

**IT WAS THE PAGE LIST, AND THE TWO FACTS ABOVE ARE WHAT FOUND IT**
(ZiguratIP `f5d6dd2`, `MVCCS-cicili/mvccs-lib.cicili`). The obvious guess --
that every row of a predicate shares the index key `(kb, name, arity)` and so
one value chain -- is the one the split argued against, and the answer was a
level below the index. **Every row written draws a SEQUENCE value, and a draw
is a CURSOR**: over the sequence's own key, which owns one page holding one
row. `cursor_walk` snapshots the page list under the lock, and that list was
ONE chain for the whole store -- walk every entry to count them, allocate two
arrays of that size, walk every entry again to filter, and all of it twice,
because a second round is what proves no page appeared during the first. So a
draw cost O(pages in the store), the store's pages grow with the rows, and the
write came out quadratic in its own rows. Which is exactly why splitting over
predicates did not help -- pages are one store's however the rows are named --
and why no vacuum moved it: the pages a walk steps over are LIVE. A sampling
profile of a 128 000-row write put 57 % of the process inside that one
function, under `seq_next`.

Every page now also sits in the chain of the pages under ITS key. Measured
again from cocolog 1.2.16 over a fresh `--embed`, one process, on macOS (the
table above is Linux, so compare columns and not rows). This is that fix
alone; the paragraph after the table takes the same write further:

| rows one process writes | before | after | µs a row after |
|---|---|---|---|
| 16 000 | 1.13 s | 0.97 s | 61 |
| 32 000 | 2.15 s | 1.82 s | 57 |
| 64 000 | 5.14 s | **3.69 s** | 58 |
| 128 000 | 15.0 s | **7.45 s** | 58 |

-- a doubling costs twice now where it cost nearly three times, the cost a row
is flat, and the ceiling at ~30 000 rows is gone. **A build gets it by
rebuilding against an updated ZiguratIP checkout**: the engine is compiled
into `cocolog` itself, so `make` with `ZIGURATIP` set is what carries the fix
into `--embed`. The engine guards it with a counter rather than a stopwatch
(`mvccs_cursor_steps`): a draw may not step over more page entries than the
store has pages.

**AND THEN WHAT WAS LEFT, which was `ftruncate`** (ZiguratIP `c4a7e19`,
then 0.1.2). Two thirds of the write that remained: a mapped page may not be
touched past the file's end, so the store moved the end before every
extending write, and that is a metadata transaction -- ~115 µs on APFS, 23
on ext4 -- six of them for every fresh 8 KB page. The store grows a
**megabyte at a time** now and cuts the file back to what was written at
every sync and at close, so the length anybody can observe is still the
exact one. 128 000 rows, three runs each: **9.22 s → 3.26 s** here, and
26.9 s → 2.2 s on the Linux box with the page-list fix above -- 12× for that
write, and ~17 µs a row where it was 210.

**AND ONE THING THIS COST BEFORE IT SETTLED**, which is worth knowing
because it is the shape of a bug a suite can catch and a benchmark cannot:
the first attempt made the extending write a `pwrite` (0.1.1). It was
faster and kept the file's length exact at every instant, but it put
CONTENT through a second path -- `write(2)` past the end, the mapping
everywhere else -- and on Linux/ext4 a store written that way was
**intermittently unreadable to the next process that opened it**: about
30 % of first reads could not find `gc_w/3` though every row was there.
`test/gc.pl`'s "a second process reads every one of them back" is the case
that caught it, and an interleaved 20-run A/B swapping one `.so` is what
pinned it (ZiguratIP#32). The rule that replaced it is narrower and is a
good rule -- one path writes the bytes, and the kernel is only ever asked
to move the end. **It is not what was wrong**, and this file said it was.

**THE MIXING WAS INNOCENT. IT IS THE VERSION CLOCK, AND THE TWO FASTER
WRITES ONLY EXPOSED IT.** The chunked grow puts every byte back through the
mapping and the fault SURVIVED it at the same rate -- nine of thirty first
reads failed on a freshly built stack with nothing swapped -- which is what
sent the diagnosis past StreamIO altogether. What decays is not on disk.
Over 40 fresh stores, failing and passing alike, `data` and
`hexmap` are the same length to the byte before and after the first
read; two independent writes of one program differ only in 82 622 bytes at
8 bytes every 64, which are the row STAMPS, with the hexmap identical; an
unrelated older store read in the same wake of a writer is 25/25; and the
first open writes to the store in EVERY run, the passing ones included, so
it was never a repair. The store is whole and the reader cannot see it.

**THE COMMIT STAMP IS IN THE FUTURE.** `version_time`
(`MVCCS-cicili/mvccs-lib.cicili:231`) answers the wall clock, or
`clock_last + 1` when two calls land in one microsecond -- and `clock_last`
is PER-PROCESS and only ratchets, so a flush making more calls than it has
microseconds pushes it past the wall clock, where nothing outside that
process can see where it got to. `commit_transaction` takes ONE
`version_time` for the whole transaction (`:1657`) and writes it into every
committed row's `create_time` (`:1429`). **So the writer exits before the
clock it stamped its own rows with.** A reader is a new process, its
`clock_last` is 0, its snapshot is therefore the true wall clock, and
`alive_at` (`:1753`) applies its own rule -- *born after this read began*
-- to every row of that commit, the CATALOGUE row included. Which is why
the symptom is `Unknown procedure: gc_w/3` rather than an empty answer, why
a second process a few milliseconds later reads all of it, and why nothing
is lost: the wall clock catches up.

Measured against the wall clock read the instant the writer exited, on
fresh `--embed` stores, beside the first read at three delays (8 stores a
cell):

| rows | commit stamp | d=0 | 5 ms | 20 ms |
|---|---|---|---|---|
| 500 | **-3.0 ms** | 8/8 | 8/8 | 8/8 |
| 2 000 | +1.9 ms | 8/8 | 8/8 | 8/8 |
| 8 000 | +10.4 ms | 7/8 | 8/8 | 8/8 |
| 32 000 | **+25.6 ms** | **0/8** | 3/8 | 8/8 |

-- the delay a store needs is the lead its own stamp carries. And the same
binary, same engine, same clock code, only `libStreamIO.so` swapped, at
32 000 rows:

| libStreamIO | commit stamp |
|---|---|
| `3b50f88` ftruncate per write | **-16.5 ms** |
| `c4a7e19` pwrite | +9.6 ms |
| `f0ac1e2` chunked grow | +26.3 ms |

The lead crosses zero exactly at the two commits that were suspected, in
the order their failure rates ran (20/20, 15/20, 12/20). **Neither put a
defect in.** Both made the flush fast enough for the same number of
`version_time` calls to outrun the microseconds available to them -- which
is also why slowing the CALLER changes nothing: 32 000 rows with a burn
loop between the asserts takes 0.54 s to 8.33 s, sixteen times as long, and
the lead does not move. The backend flushes a dirty predicate WHOLESALE, so
the calls land in one burst whatever the program above is doing.

**THE SHAPE TO WATCH FOR IS ONE PROCESS WRITING TENS OF THOUSANDS OF ROWS
AND ANOTHER READING AT ONCE.** In the whole suite that is `test/gc.pl`'s
"a second process reads every one of them back" and nothing else -- 46
GREEN, 7 SKIP and that one RED on `f0ac1e2`. Any delay hides it, and so
does any real work between the two, which is why it is invisible everywhere
a person is driving and why a 500-row store never meets it at all.

**FIXED IN THE ENGINE, AND IT TOOK TWO GOES (ZiguratIP 0.1.4, then 0.1.5):
a commit does not RETURN until real time has reached the stamp it wrote.** Of
the roads proposed on #32 this is the one that needed nothing persisted —
seeding a process's clock at open had no cheap source, because the transaction
row carrying the stamp is zeroed when the commit retires its intention. The
wait is the lead and nothing else: an ordinary commit leads by microseconds
and spins them out, a flush that outran the clock sleeps the difference in one
call. `clock_settle` in `MVCCS-cicili/mvccs-lib.cicili` carries the reasoning
and the numbers above; `mvccs_test` pins the invariant without needing two
processes or a fast machine — it runs the clock milliseconds ahead on purpose,
commits, and requires the lead back at zero with the stamped row readable.

**AND THE PLACEMENT WAS WRONG IN 0.1.4, WHICH THIS FILE REPEATED.** What stood
here said the wait "is paid after the rows are durable and the streams guard is
back, so a committer waiting holds nothing". The streams, yes — but it sat
BEFORE `transaction_retire` and `transaction_reset`, and it is
`transaction_reset` that hands back the SERIALIZABLE slot, a semaphore of ONE
whose waiters poll at ten milliseconds. So a committing SERIALIZABLE
transaction slept its whole lead holding the one thing every other writer
needed, and each such wait was rounded up to a 10 ms poll for all of them.
0.1.5 puts the wait LAST, after the streams, the live id and the slot have all
gone back: a wait that holds anything is a wait somebody else pays for.
`test/gc.pl` is still green on 0.1.5 — 34 ok, exit 0 — so moving it past the
retire did not put the stamp back in the future, which is the one thing that
had to be re-proved.

The vacuum finding above is untouched by either fix; a writing process still
rewrites the whole predicate, and `cocolog vacuum` is still what bounds it.

## Concurrency: share nothing, copy the term

`library(thread)` is threads and channels, and the shape is the one the
`swarm` command already had: **a thread gets its own machine, store and
engine.** A cocolog machine is an unguarded heap, a trail and an atom
table; two threads proving goals on one would corrupt it in a millisecond,
and locking at that level would be neither correct nor fast.

**So a channel copies**, in canonical text — the same form the database
stores clauses in, quoted and with operators ignored, so a term reads back
on a machine that never ran the same `op/3`. Two machines cannot share a
heap cell, so a term crossing between them is copied whatever the
mechanism; text is the copy this interpreter already trusts.

**What a thread can see, in one line each:**

- **every registered module** — linked-in ones, and anything `use_module`
  loaded *before* it started. The registry is process-wide and a fresh
  store consults all of it on the first goal.
- **nothing the parent asserted.** A thread's store starts empty, and it
  has no database connection — `db` is thread-local and null on a new
  thread, so a thread is a `--local` proof whatever the parent was.

**Register your modules before you spawn.** `use_module` writes the
process-wide registry, and a thread reading it while another writes is the
one unguarded thing there — unguarded because loading libraries at start-up
is what every program does, and a lock would sit on the first goal of every
proof in the process.

`coco_m_run_isolated` in `lib/module.cicili` is the seam: the engine's
lifetime belongs to the interpreter, pthreads and queues belong to the
module. A module *cannot* write it — `coco_engine` is opaque to anything
built against `lib/sdk.cicili`, so a module cannot declare one, let alone
stack-allocate the three a proof needs.

**`library(httpd)`'s `workers(N)` is what it is for.** One thread accepts
and posts connections down a channel; N workers each take one and hold it
for the whole conversation, keep-alive included. That split is the design:
accepting is the one thing that *must* be serialised — `library(tcp)`
hands out handle-table slots and nothing guards the allocation — and it is
also the one thing that costs nothing.

**A handle crosses threads because it is not a descriptor.** `coco_t_fd[256]`
is file-scope in tcp's `.so`, so a handle is an index into a table the whole
*process* shares. Only the accepting thread allocates; a worker uses one and
closes it.

**AND THAT IS WHAT THE MUTEXES ARE FOR (1.2.6).** `mutex_create/1`,
`mutex_lock/1`, `mutex_trylock/1`, `mutex_unlock/1`, `mutex_destroy/1` and
`with_mutex/2` are SWI's names and SWI's recursive semantics; `cond_create/1`,
`cond_wait/2,3`, `cond_wait_until/3`, `cond_signal/1`, `cond_broadcast/1` and
`cond_destroy/1` are ours. **They protect nothing in the knowledge base** —
two machines share no cell and a channel carries its own lock — they serialise
access to the WORLD: a file, one of those tcp handles, the terminal. **An atom
names a lock** the whole process shares, made on first use, which is the only
way a thread handed no term can share one (an httpd page is proved on a machine
with nothing of yours in it). **`with_mutex/2` is the form to use**: it unlocks
on success, on failure and on the way out of a throw, where a bare `mutex_lock`
and a raising goal hold the lock for the life of the process. `cond_wait` on a
mutex held TWICE is refused by name — the wait releases it once, so POSIX calls
depth two undefined and this calls it
`permission_error(wait, recursive_mutex, M)`.

**Measured**: one slow page 372 ms; four of them at once, one connection at
a time, **1 365 ms**; the same four through four workers, **419 ms**. The
pool is not faster at one request — it is what stops one slow request
holding every other client, which is what the keep-alive note called the
real exposure.

**A WORKER HAS THE DATABASE NOW**, and `coco_m_kb_install` in
`lib/module.cicili` is the seam that gave it one. `lib/module.cicili` can
make a machine and a store but cannot know whether this process is
`--local`, a socket, Zeytun or embedded — the composition root can, so it
installs a pair of hooks and every isolated proof opens a connection of its
own. One per thread, which is the `swarm` command's rule and the only one
that works. Connections NEST: the previous one is saved and restored, which
is what lets a worker hold one while each request opens another.

**EACH REQUEST IS ITS OWN TURN, and that is not a refinement.** A store
CACHES — the first proof to ask for `visit/1` marks the predicate loaded and
never asks again — and the Zigurat backend flushes a dirty predicate
WHOLESALE, so two workers each answering a write hold divergent pictures and
the second commit writes its stale copy over the first. Measured: three
sequential POSTs through a pool of three left **two** facts in the database,
with no concurrency involved at all. So a request runs through
`run_isolated/2`: fresh machine, fresh store, fresh connection, one commit
at the end, a rollback when the goal did not prove.

**WHICH ASKS ONE THING OF THE PROGRAM ABOVE IT, and the failure is a silent
404**: a worker's store is filled from the process-wide MODULE REGISTRY, so
pages must be loaded with `use_module` and not consulted, asserted, or
written into the file handed to `cocolog run`. `workers(0)` serves those
perfectly well, which is exactly how this is easy to meet in a demo and lose
the moment a pool is added. Four cases in `test/httpd.pl` hold both halves.

**Measured**: four threads doing four times the work of one took 1.7× the
time on four cores. Eight senders put 800 terms through one channel and all
800 arrived.

## Where things are

| path | what |
|---|---|
| `lib/term.cicili` | cells, unification, the trail, copying |
| `lib/syntax.cicili` | the reader and the writer, from one operator table, plus the run-time one `op/3` adds |
| `lib/kb.cicili` | the clause store, its five backend hooks, and since 1.2.13 its compaction |
| `lib/solve.cicili` | the engine and the builtin table |
| `lib/module.cicili` | the module seam and the API a module is written against |
| `lib/files.cicili` | SWI's Files library, as a module — mostly C. Also `get_time/1`, the wall clock, which was simply not there: nothing in cocolog could ask what time it is, so a certificate's validity window had nowhere to come from |
| `modules/tcp/tcp.cicili` | the socket seam: listen, connect, accept, read, write, close. A handle is an index into this module's own table, never a file descriptor |
| `lib/lists.cicili` | SWI's Lists library, as a module — mostly Prolog, because nondeterministic predicates cannot live in a C half |
| `lib/apply.cicili` | SWI's Apply library — clauses only, no C half |
| `lib/builtins.cicili` | the ISO core builtins cocolog was missing, plus `format/1,2,3`, `code_type/2` and `must_be/2`. **No failure-driven loops in here** — every builtin is deterministic, so `G, fail` runs the body once and then stops |
| `lib/dcg.cicili` | `-->` translation, `phrase/2,3`. Two generics: the translator sits BEFORE `kb` because `coco_assert` calls it, the module half after the engine |
| `lib/swipl/` | EIGHT of SWI's libraries — `assoc`, `pairs`, `ordsets`, `yall`, `aggregate`, `ugraphs`, `dcg/basics`, `dcg/high_order` — copied unmodified under their own BSD-2 headers and read at start-up. Do not edit them — see the README there |
| `lib/library.cicili` | `use_module`: run-time loading of `.pl` and dlopen'd `.so` libraries |
| `lib/sdk.cicili` | the module API over opaque types, for out-of-tree Cicili modules |
| `modules/` | the seventeen loadable modules: `tcp`, `thread`, `process`, `text`, `os`, `curl`, `bigint`, `torch`, `tensorflow`, `numpy`, `opencv`, `ray`, and ZiguratIP's cryptography — `sha`, `aes`, `der`, `x509`, `tls`. One directory each — a `.cicili`, a `build.sh`, output nobody commits — and none of them part of `make`. `embed/` is the same shape and is NOT here, because the embedded store really is part of the binary |
| `lib/state.cicili` | freeze and thaw of a machine |
| `lib/zigurat-kb.cicili` | the binary-protocol backend (reads and writes) |
| `lib/zeytun-kb.cicili` | the HTTP backend (reads only) |
| `client/` | pure C, speaks the wire protocol, includes nothing of ZiguratIP |
| `parsi/` | the schema, procedures and pages compiled into a ZiguratIP home |
| `tools/cocolint/` | **the dialect linter**, and the deterministic half of the NL-to-cocolog agent around it: the clause reader as one grammar, the rules as clauses, the dialect card whose citations are checked rather than trusted, the retrieval index, the collision oracle and the gate script. `sh tools/cocolint/lint.sh FILE.pl` or `make lint FILES=FILE.pl`; `test/lint.pl` is the suite case, and `tutorials/library/37-lint.pl` the lesson. It was `tools/coco-agent` and is named for the part a person runs by hand |

The store's hooks — `fetch`, `on_assert`, `on_retract`, `on_dynamic`, `warm` —
are the seam. Everything above them is written against the store and knows
nothing about where clauses come from. **A feature that touches the knowledge
base needs all three arrangements considered**: local (no hooks), Zigurat (all
five), Zeytun (`fetch` and `warm` only, because one HTTP request is one
transaction and a machine is many rows).

## The tutorials are documentation that RUNS

`tutorials/` has four categories and `test/tutorials.pl` runs all
**123** files as one suite case (counted from the tree, not remembered; this said 122,
this said 121, this said 120, before that 118, ninety-three, and sixty-eight):

| | | needs |
|---|---|---|
| `tutorials/basics/` | eleven lessons, the language itself | nothing |
| `tutorials/library/` | forty-seven lessons, numbered 00 to 46: one per library that ships, one for cocolint, one for the library path | `$COCOLOG_LIBRARY` for tier 2 |
| `tutorials/opencv/` | twenty-three lessons of image processing | `library/opencv.so` |
| `tutorials/tensor/` | forty-two networks, each running on either tensor library | libtorch |

**EVERY CLAIM IS A `must/3`**, in every basics and library file:

```prolog
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
```

So a lesson that stops being true FAILS, naming both answers, and a
tutorial cannot quietly document a language that has moved on. It is
repeated at the bottom of all forty files rather than shared,
deliberately: a tutorial you can copy anywhere and run is worth six
duplicated lines, and one that needs a support file beside it stops
working the moment it moves.

**Writing them found three real interpreter bugs**, which is the whole
argument for the shape:

* **`once/1` and `ignore/1` did not exist.** They are now CONTROL
  CONSTRUCTS in `lib/solve.cicili`, beside `\+` — `once(G)` is
  `coco_ite(G, $true, $fail)` and `ignore(G)` is `coco_ite(G, $true,
  $true)`. They were Prolog clauses for a day, which is how every
  textbook writes them and is the wrong shape here: a clause costs a
  frame, a `call` and a hand-written cut to say what the engine already
  has a construct for. As if-then-else the goal gets its cut barrier
  FROM THE CONSTRUCT, which is what makes `once/1` opaque to cut the way
  ISO 8.15.2 requires — `once((X > 1, !))` inside a `member/2` leaves
  the outer choice point alone, and there is nothing left to get wrong.
* **`flush_output/0` did not exist.** cocolog writes to the literal
  stdout, which the C library buffers by LINE at a terminal and by BLOCK
  everywhere else — so a program that prints a marker and then blocks
  prints nothing at all into a pipe or a file, and everything at once
  when it exits. Found by `test/tls.pl`: the server printed READY, the
  harness waited for it, and it arrived after the server gave up.
  Interactively it had always worked.
* **`retractall/1` was one clause short of correct.** It was written
  `retractall(H) :- retract(H), fail.` / `retractall(_).` — the classic
  failure-driven loop, and it retracts exactly ONE clause here, because
  **every builtin in cocolog is deterministic** and `retract/1` leaves
  no choice point to fail back into. It is now recursive over
  `copy_term/2`, which is also what keeps a partially-bound head from
  being narrowed by the first match.

That last one is the pattern to watch for anywhere in `lib/`: a
failure-driven loop written from habit against another Prolog is not
slow here, it is wrong, and it is wrong quietly.

**A NEW LIBRARY GETS A TUTORIAL IN THE SAME COMMIT.** `tutorials/library/`
is numbered one per library, so a gap is visible — and a library with no
`NN-name.pl` beside it is one nobody has demonstrated end to end. Each of
them found something while being written: a predicate that
did not exist, an arity that was wrong, `bigint_cmp/3` documented as
`-1/0/1` and actually answering `<`/`=`/`>`, `httpd_content_type/2` keyed
on the bare extension where `httpd_type/2` is the one that takes a file
name.

## modules/ray changes are validated downstream

The owner's rule: a change to modules/ray does NOT require the full
suite here -- run `cocolog -s test/ray.pl` (and the tutorial if the surface
changed) and let CivV's own suite exercise it fully, which it does
against real worlds. The full-suite discipline stands for everything
else.

## Before saying something works

Run `make test` with a server up, and read all **58** case lines (counted
from `test/run.pl`'s list, not remembered; this said 39, then 42, then 43, then 48, then
51, then 52, then 53, then 54, then 57, and the suite keeps moving -- seven `.cicili` binaries and
fifty-one `.pl` cases, each line with its seconds). A change to
the knowledge base also wants proving **across processes** — one `cocolog`
invocation writing and a second, which consulted nothing, reading — because
that is the claim the project exists to make and an in-process test cannot make
it.

**COUNT THE SKIPs.** `red: 0` is printed over a run where nothing happened
just as happily as over a real one, and the suite is deliberately built that
way: "no server here" and "the backend is wrong" are different findings, so
the first is never dressed up as the second. Measured with nothing listening
on 2160, when the suite was 48 lines long: **`red: 0` and FOURTEEN SKIPs.**
Both halves of that are worth having — the discipline holds, not one case
mistakes a missing server for a broken backend, and the trap is exactly as
wide as it looks. **The number of SKIPs is a fact about the MACHINE, not
about the suite**, so it is not worth memorising: count them each run.

**NINE CASES SKIP WITHOUT A SERVER** — `zigurat`, `shared`, `tunnel`,
`tensors`, `zigurat-lib`, `kbs`, `zigurat-tls`, `groups`, `ruler`. This said
SEVEN for a long time and named the wrong set; `kbs` and `zigurat-tls` were
missing. **And do not extend the list by reading the guards**, which is how
it went wrong: `vacuum`, `repl`, `library` and `httpd` each carry a SKIP
message of their own that mentions a server, and all four come out GREEN
without one, because what they skip is a SECTION rather than the case.

The other five are missing tools: `files` and `trace` want `swipl`
(`apt-get install swi-prolog-nox`), because both compare cocolog against
it; `ray` wants raylib, `tensorflow` libtensorflow, and `torch-replay` a
CUDA toolkit to compile the replay path in. **A run that says `red: 0` with
fourteen SKIPs has not touched the database at all.** What a box gives
depends on what is installed on it: measured on this Mac with a server up
and swipl, raylib and libtensorflow all present, **52 case lines and ONE
SKIP** -- `torch-replay`, for want of a CUDA toolkit.

### What macOS gets wrong, and the recipe

A Mac builds the whole family -- clang is native, and every layer came up
clean -- but each of these fails naming something other than its cause,
and every one has cost a session at least an hour:

* **A shared object may not leave the interpreter's symbols undefined,
  and neither may a program that links only the client archive.** Every
  loadable module refers to `coco_module_register` and the rest of the
  SDK, to be found in the cocolog that `dlopen`s it; every test binary
  refers to the TLS entry points and the embedded engine's, declared
  `weak` on Linux so a build without them links and leaves them null.
  Apple's linker says `ld: symbol(s) not found for architecture x86_64`
  to both, naming symbols that plainly exist. Two halves fix it:
  `client/zeytun.h`'s `COCO_WEAK` (and `zigurat.c`'s `CE_WEAK`) are
  `weak_import` on Darwin, and `tools/cc/cc` and `cxx` add
  `-Wl,-undefined,dynamic_lookup` to EVERY link step there -- Mach-O's
  `weak_import` still wants a definition at link time, and only dynamic
  lookup lets the reference stay open and bind to null at load, which is
  the behaviour every caller of those symbols checks for. Once, in the
  wrappers, rather than in every `build.sh` and `:link` list. **And the
  wrappers must be REACHED**: on Darwin Cicili names `clang` outright
  (its config.lisp says so), so `tools/cc` carries `clang` and `clang++`
  shims beside `gcc` and `g++` -- each takes itself off PATH before
  handing over, or the wrapper's `exec clang` would be the shim again --
  and `test/run.pl` puts `tools/cc` at the front of PATH (what
  `tools/cc/env.sh` does for a shell), which the runner never used to:
  the seven test binaries were built with whatever the bare name resolved
  to, and failed on a Mac beside a `make` that succeeded.
* **Apple's clang 21 defaults to C++14** (`__cplusplus 201402L`) where
  Ubuntu's defaults to gnu++17, and fires `-Wparentheses-equality` on
  the transpiler's `while ((x == 0))` in more places. Under C++14 there
  is no guaranteed copy elision, so ZiguratIP's engine died at `call to
  implicitly-deleted copy constructor of 'Zigurat::filestream'` on a
  line that is correct C++17. Every Cicili target that compiles C++ now
  says `-std=gnu++17` (gnu, for the statement expressions the transpiler
  emits), and every target here carries the `-Wno-` pair -- including
  the seven `test/*.cicili`, which used to inherit whatever the compiler
  felt like. Apple's SDK also marks `sprintf` deprecated, which is a
  warning, which Cicili treats as fatal: `-Wno-deprecated-declarations`
  rides beside it in the C++ targets.
* **There is no `/proc/self/exe`.** `lb_exedir` in `lib/library.cicili`
  asks `_NSGetExecutablePath` + `realpath` under `(@ifdef (code
  "__APPLE__"))` -- note the `code` payload: a bare symbol in an `@ifdef`
  is `unknown symbol: __APPLE__`, and a libc function `lib/std/c` does
  not declare (`_NSGetExecutablePath`, `realpath`) goes through the raw-C
  escape exactly as `files.cicili` reaches `realpath`. The engine now
  answers `current_prolog_flag(executable, P)` -- one of the THREE SWI
  flags it answers, with `argv` and `os_argv`, and no others -- and `library(kbs)` and CivV's suite read it instead of
  `/proc/self/exe`, which had failed silently and made every `kb_*` goal
  fail with nothing printed.
* **`make schema` dies inside libc++.** ZiguratIP's `memory.hpp` derives
  from `std::binary_function`, which C++17 removed and Apple's libc++
  actually deletes; the error is `no template named 'binary_function'`
  from the middle of `01-schema.parsi`. ZiguratIP is frozen, so the fix
  is the owner's own `--config` road: copy `home/etc/ziguratip.conf`
  somewhere, append `-D_LIBCPP_ENABLE_CXX17_REMOVED_BINARY_FUNCTION` to
  its `CPP_FLAGS`, and `ZIGURATIP_CONF=that-file make schema` --
  `parsi/build.sh` passes it through. The tracked configuration is
  untouched. ZiguratIP's own `System/` objects and `demo/` compile with
  the home configuration as they are.
* **After ANY engine rebuild, EVERY object in `home/ld` is stale**, and
  the server or `parsi` dies at `dlopen(...): Symbol not found:
  __ZN7Globals11echo_streamEv` -- a symbol the old engine had and the
  new one renamed. `make -C System clean && make -C System`, then each
  `demo/0*.parsi` through `parsi`, then `make schema` here. `nm -u
  home/ld/*.so | grep echo_stream` lists whoever is still behind.
* **The X11 that `xdotool` needs is XQuartz's**, and it ships with the
  XTEST extension off. `brew install xdotool` says so on the way in:
  `defaults write org.x.X11 enable_test_extensions -boolean true`, then
  restart X11. `raylib` for `modules/ray` is `brew install raylib`.
* **A raylib photograph is ONE FRAME BEHIND on macOS**, measured: a red
  frame, then a blue one, photographed, comes back red. After a single
  frame it is black. A program that screenshots draws the same frame
  twice first -- CivV's two renderers do -- and an overlay drawn twice
  had better be idempotent. `ray_screen_pixel/6` reads the same
  photograph, so a pixel read wants the two frames too: the texture
  section of `test/ray.pl` pinned a BLACK tile before it did.
* **A Mac whose screen has gone to sleep opens NO raylib window**, and a
  set `DISPLAY` says nothing about it: `InitWindow` fails at once with
  `GLFW: Failed to determine Monitor to center Window` and `SYSTEM:
  Failed to initialize platform`, and every windowed check of `test/ray.pl`
  went red in a second, naming the module for what the room did. The case
  probes with one 8x8 window first and SKIPs its windowed half with
  raylib's reason when none comes. `caffeinate -u -t N` turns the screen
  on, and on this box it slept again 32 s later under that assertion, so
  a ray run you mean to believe wants the screen awake -- `pmset -g log |
  grep -i 'display is turned'` says when it last went.
* **Ask `library(os)`, not a shell.** `os_is(darwin)`, `os_has(Tool)`,
  `os_lib_path_var(V)`, `os_tmp(T)`, `os_cpus(N)` are the questions the
  suites used to put to `uname`, `command -v`, `$TMPDIR` and `nproc` --
  answered by libc, the same clause on both systems. `modules/os`,
  tutorial 35, `test/os.pl`.
* **No `setsid`, no `LD_LIBRARY_PATH`, no `date +%N`, and `wc` pads.**
  Raise the server with `nohup` in a subshell and `DYLD_LIBRARY_PATH`;
  `timeout` is coreutils' (brew). **`test/portable.sh` is GONE and there
  is nothing in its place**, which is the right end of that story: it
  carried `now_ms` (perl's Time::HiRes -- BSD `date` prints a literal
  `3N`, and the arithmetic after it died with `value too great for base`,
  which is how a timing check came to call parallel threads "serial") and
  `detach` (setsid where it exists, plain elsewhere), and it went with the
  rest of the shell on 2026-09-04 because every case that sourced it now
  times with `get_time/1` and spawns with `proc_spawn/2` -- neither of
  which cares which `date` or which `setsid` the machine has. BSD `wc -c`
  left-pads
  its count: `tr -d " "`. `library(process)`'s `proc_spawn` calls the
  syscall and is unaffected.
* **A page that warms a store takes ~4x longer here** -- CivV's `/view`
  measured 12-13s against ~3s on the Linux box -- so a client's first
  read must wait for that, and a server's READY line is printed ~1.4s
  BEFORE its port opens. Wait for the port with `lsof -iTCP:PORT
  -sTCP:LISTEN`, never with a probe connection: `httpd`'s accept loop
  ENDS on a failed accept, and a bare TCP connect to a TLS listener is
  exactly that.

* **`maximum resident set size` AND `peak memory footprint` BOTH UNDERCOUNT
  AFTER A LARGE `realloc` MOVES A BLOCK, and which runs move is a coin
  toss.** Darwin's allocator extends a large block in place when the
  address space after it is free and otherwise moves it by copy-on-write
  remap (a 512 MB move took 4.6 ms; there is no memcpy and no transient
  doubling), and the moved pages leave BOTH counters until they are touched
  again. **A FREED large block, by contrast, goes back AT ONCE** -- 100
  alloc/free cycles of 128 MB leave `phys_footprint` at zero, measured -- so
  large regions a process is still holding are ones something still points
  at, and "allocator debris" is never the explanation for a footprint -- probed: 1 024 MB written, 808 MB reported, all 1 024 back the
  moment every page was read, with the machine's free memory unchanged
  throughout. Whether a block moves depends on what landed after it, which
  is why one cocolog run reported 933 MB and the identical next one
  1 404 MB. **The low number is the wrong one**; a watchdog reading `ps`
  is fooled the same way, and a two-valued spread across identical runs is
  this before it is anything in the engine. glibc `mremap`s and Linux does
  not have it. (cicili-lang's report of 2026-09-14, which read the spread
  as realloc doubling; the real cost underneath was the store, above.)

**THE SUITE IS GREEN ON A MAC NOW -- 51 of 52, the one SKIP being
`torch-replay` for want of a CUDA toolkit -- and the twelve that used to
fail were the tests' own portability, exactly as this said.** They fixed
themselves when the suite stopped being shell (2026-09-04): `files` and
`trace` compared byte for byte against this machine's swipl, `vacuum`,
`repl` and `tensors` fell over BSD `rm` on a `$TMPDIR` scratch directory,
`tunnel` and `colab` wanted GNU tools and privileged ports, `http` and
`tcp` were a second process reaching a first through `detach` and a
sleep, `engine` was a timing ratio taken with `date +%N`, and `groups`
and `ruler` timed a socket read out under a slow vacuum. A `.pl` case
times with `get_time/1`, spawns with `proc_spawn/2`, waits for a port
with `lsof`, and removes its scratch directory with one `rm -rf` it
issues itself -- so eleven of the twelve had nothing left to be
unportable about, and the twelfth (`engine`) had already been rewritten
as a timeout at a hundred-fold margin rather than a stopwatch.

**The list is kept because the DIAGNOSIS is the useful part**: when a
case goes red on a Mac and green on Linux, suspect what the case shells
out to before suspecting the interpreter. Read the per-case lines, as
always, and count the SKIPs.

One engine self-test fails on this Mac and passes on Linux --
`contention_test`'s "rewrite vs index" (a writer rewriting one row under
a unique index while readers look it up: `[writer: unique key]` and the
row missing 4 times) -- and the gauntlet aborts the ZiguratIP `make`
after the artefacts are already built. It is a real finding about the
engine on Darwin and it is NOT fixed here; it is recorded for the owner.

### The two things a container gets wrong

Both cost a session time, and neither announces itself:

* **`$HOME` is not where the checkouts are.** Every `build.sh` defaults to
  `${CICILI:-$HOME/cicili}` and `${ZIGURATIP:-$HOME/ZiguratIP}`, which is
  right on a workstation and wrong wherever `$HOME` is `/root` and the
  repositories are somewhere else. Set both explicitly:

      export CICILI=/path/to/cicili ZIGURATIP=/path/to/ZiguratIP

  Getting it wrong fails LOUDLY but far from the cause — a Lisp backtrace
  about `embed/mvccs-lib.cicili` not existing, which is a SYMLINK
  `embed/build.sh` made, pointing wherever `$HOME` was the last time it ran.
  A stale symlink is not repaired by `make`; re-run the script, or delete it.

* **The server needs its own libraries on the path.** Started plainly,
  `ziguratip` dies at once with `libStreamIO.so: cannot open shared object
  file` — and then every database case SKIPs, so the suite still says
  `red: 0`. Raise it as:

      export ZIGURATIP_HOME=/path/to/ZiguratIP/home
      setsid env LD_LIBRARY_PATH="$ZIGURATIP_HOME/lib" \
        "$ZIGURATIP_HOME/bin/ziguratip" > /tmp/zig.log 2>&1 &

  `setsid` because a plain `&` from a tool call does not outlive the turn.
  Then CHECK it before trusting a green line — the answer should be a
  sentence, not a refusal:

      ./cocolog --kb main --host 127.0.0.1 --tcp 2160 --timeout 10 list
