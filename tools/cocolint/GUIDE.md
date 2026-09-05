# cocolint — the guide to the tools

[`README.md`](README.md) beside this file says why each tool is the way it
is. This is the other half: how to run them, what they read and write, what
their lines mean, and what to do when one says no. Every command here was
run against the tree as written; when a script and this guide disagree, the
script is right and this guide has a bug.

There is one prerequisite for all of it: a built `cocolog` at the root of
the checkout, or at `$COCOLOG_BIN`. No server, no model, no network, and no
Python — the tools are cocolog programs run by the binary they lint for.

## The one-minute version

```sh
sh tools/cocolint/lint.sh   myprogram.pl        # the linter: exit 1 on a HARD finding
sh tools/cocolint/oracle.sh myprogram.pl        # which of its predicates the store folded into a library's
sh tools/cocolint/verify.sh myprogram.pl        # the gates G0..G5, in cost order; stops at the first FAIL
sh tools/cocolint/agent.sh --dry "REQUEST"      # the prompt a model would get, and its size
make lint FILES=myprogram.pl                    # lint.sh through make, index rebuilt first
make index                                      # rebuild the blocklist and the retrieval index
make dialect-check                              # every citation of the dialect card still anchors
cocolog -s test/lint.pl                                 # the suite case: about three minutes
```

Paths may be relative or absolute; relative ones are taken from where you
stand. Every script accepts more than one file.

## What is in the directory

| you run | it is | it reads | it writes |
|---|---|---|---|
| `lint.sh` | the dialect linter, cocolint | your files, `blocklist.pl`, `traps.pl` | findings to stdout |
| `oracle.sh` | the collision oracle, G2+G3 | your files, `blocklist.pl` | one verdict per predicate |
| `verify.sh` | the gates G0–G5 | your files, everything above | one line per gate |
| `agent.sh` | request → prompt → candidate → gates | the index, a key | a candidate in a scratch directory |
| `tool.sh build` | the reserved-name blocklist | `lib/`, `modules/`, `library/`, `lib/swipl/` | `blocklist.json`, `blocklist.pl` |
| `tool.sh card` | the dialect card's checker and generator | `traps.jsonl`, the files it cites | `traps.pl`; with `--fix`, `traps.jsonl` |
| `tool.sh index` | the retrieval index | every library and module header, the exemplars | `surface.jsonl`, `exemplars.jsonl`, `capabilities.json` |
| `tool.sh assemble` | the prompt, block by block | the index, `blocklist.json`, `traps.jsonl` | text, or sizes |
| `pre-commit` | a git hook | staged `.pl` files | nothing |
| `test/lint.pl` | the suite case | all of the above | GREEN, RED or SKIP |

The generated files — `blocklist.json`, `blocklist.pl`, `traps.pl`,
`surface.jsonl`, `exemplars.jsonl`, `capabilities.json` — are **never
committed**; `.gitignore` names them. `lint.sh` rebuilds the two it needs
when they are missing or older than their sources, so there is nothing to
do before the first run.

## `lint.sh` — the linter

```sh
sh tools/cocolint/lint.sh FILE.pl [FILE.pl ...]
```

Exit **0** with no HARD finding, **1** with one, **2** for a usage error, no
binary, or an index that would not build. WARN findings do not change the
exit status.

Before linting it runs `tool.sh build --if-stale` and `tool.sh card --facts
--if-stale`, so the blocklist and the S1 patterns are this checkout's own
and current. A cold rebuild is about five seconds; warm it is a quarter of
one.

### A finding

```
tutorials/library/30-hex.pl:75:8 HARD S1 [H1] halt/0 sets `halted', and the engine tests halted BEFORE ...
    fix: let main succeed; the CLI's exit code is the verdict
```

`path:line:col`, the severity, the rule, the card row in brackets when the
rule has one, the message, and on the next line what to do about it. The
last line of the run is the count:

```
cocolint: 1 HARD, 0 WARN over 1 file(s)
```

HARD is a divergence that will fail or silently misbehave; WARN is one that
costs something without breaking anything (a no-op import, an integer near
the wrap, a clause that will not fit a page).

### The rules

| rule | severity | fires on | fix |
|---|---|---|---|
| **P1** | HARD | the file does not read at all | the syntax error the reader names |
| **N1** | HARD | a head that collides with a clause-defined tier-1 name; the two sets of clauses MERGE, and which is tried first depends on how the file is run | prefix the head with the program's own name — a DCG head too (row N4): `digit//1` is `digit/3` in the store |
| **N2** | HARD | a head that collides with a C-registered name; dispatched before the store, so the clauses are DEAD CODE and `listing/1` will still show them | prefix the head |
| **N3** | HARD | a head whose NAME is a control construct (`once`, `call`, `catch`, `throw`, …); no arity escapes it | prefix the head |
| **S1** | HARD | one of the fourteen banned forms below, matched as a term with comments and quotes masked | the row's own fix |
| **T1** | WARN | `use_module` of a tier-1 library, compiled in or preloaded; the directive succeeds and does nothing | delete it |
| **A1** | WARN | an integer literal at or above 2^59 — a cell is a u64 with three tag bits and no range check, so arithmetic wraps SILENTLY at 2^60 | keep under 2^59, or `library(bigint)` |
| **Z1** | WARN | a clause over 7,800 bytes stored (a row must fit a page; the store's own budget is `page - 190 - len(kb) - len(name)` and it refuses there with `resource_error(clause_length)`, so this warns a little early on purpose), or a term over 65,535 bytes (the wire refuses it) | chunk it |
| **C2** | HARD | one name defined in two of the files named, when they are declared one program; off by default, see below | one definition |

S1's fourteen forms are rows of the dialect card, `traps.jsonl`, each with
a `pattern`. `tool.sh card --patterns` prints the terms.

| row | the SWI reflex | cocolog | why |
|---|---|---|---|
| R1 | `clear :- retract(x(_)), fail.` | `( retract(x(_)) -> clear ; true )` | `retract/1` is a C builtin, deterministic: the failure-driven loop removes ONE clause |
| H1 | `main :- ..., halt.` | omit `halt` | `halted` is tested before the empty continuation, so the goal reports no solution and exits 1 with nothing on stderr |
| D2 | `:- table p/2.` `:- thread_local p/1.` | delete | not prefix operators here: the file does not parse |
| C1 | `catch(findall(...), E, ...)` | `findall(X, catch(G, E, fail), L)` | `findall`, `forall`, `aggregate_all`, `bagof`, `setof`, `with_output_to` run a nested engine that drops the ball |
| C2 | `error(T, context(_,_))` | `error(T, _)` | a library failure is `error(cocolog_error(Text), _)` and the house style puts a bare `Name/Arity` second |
| A1 | `atan(Dy, Dx)` `log(2, N)` `random(10)` | the one-argument forms | an unknown arithmetic FUNCTOR is uncatchably fatal |
| G1 | `b_setval/2` | thread an accumulator | `b_setval` IS `nb_setval`; nothing about it backtracks |
| F1 | `~t ~| ~+` | pad by hand | refused by name at the three codes |
| W1 | `write_canonical/1` | `write_term(T, [quoted(true), ignore_ops(true)])` | `write_canonical` here keeps operators |
| L1 | `'[|]'` | `'.'/2` or `[_|_]` | a list cell is `'.'/2` |
| X2 | `open/3` `close/1` `read/1` `nl/1` `write/2` … | `read_file_to_codes/2` and a DCG; `format/3` with a sink | there is no stream layer |
| X3 | `setup_call_cleanup/3` `predsort/3` `numbervars/3` `freeze/2` `dif/2` … | write it out; `call_limited/3` | deliberately absent so ported code errors instead of differing |
| P1 | `current_prolog_flag(bounded, B)` | do not branch on a flag | four flags answer — `executable`, `argv`, `os_argv`, `double_quotes` — and every other one FAILS |
| E1 | `\xHH\` `\uXXXX` `\e` `16'FF` `1_000_000` | write the codes; write `1000000` | not in the reader's escape set; each is a syntax error refusing the WHOLE file |

The card has twenty more rows that inform the prompt rather than the
linter — row T1 on probing a library as a goal, Z1 on the page budget, the
PROMPT rows on determinism, `**` staying an integer and the like. `tool.sh
card --card` prints the card whole.

### C2 and the manifest

C2 asks whether two files of ONE PROGRAM define the same name, and a bag of
unrelated files is not a program: over all the tutorials it would report
`main/0` forty-odd times, true and useless. So it runs only when
`COCO_LINT_MANIFEST` is set in the environment, to anything, and then the
files named on the command line are taken as one program:

```sh
COCO_LINT_MANIFEST=1 sh tools/cocolint/lint.sh prog.pl helpers.pl
```

reports each name both files define, at line 1 of the first file, with
`keep it in one file` as the fix. Without the variable the same two files
lint separately and C2 is silent.

### Honest limits

S1 is textual with comment and quote regions masked, so a banned form
inside a format string is not a finding, and one spread over two lines by an
unusual layout may be missed. Nothing here type-checks, runs the program, or
proves it correct; the oracle and the gates are for that.

## `oracle.sh` — the collision oracle

```sh
sh tools/cocolint/oracle.sh FILE.pl [FILE.pl ...]
```

Consults the files under `--local` in a scratch directory with no `library/`
in it, then asks the store which predicates it calls the program's own. One
line per predicate the files DECLARE:

```
own       main/0
hook      httpd_page/3 -- a declared extension point (H :- fail.) in a library.
COLLIDED  step/4 -- the store folded it into a library's record, so it is
          invisible to current_predicate/1 and its clauses merged.
```

Exit **0** with nothing collided, **1** with a collision, **2** when the
files did not consult (the reader's message is printed, and its byte offset
is the highest-value repair signal there is).

What it sees and what it cannot: a name a vendored library already defined
is ABSENT from the store's answer and comes back COLLIDED, which is exactly
rule N1's finding asked of the binary instead of a table. A name a C builtin
owns is VISIBLE, because its record has no library flag, while the clauses
are dead — that is the blind spot rule N2 covers. Neither mechanism is
sound alone, which is why `verify.sh` runs both.

It is `--local` only, on purpose: under `--kb` or `--embed` the store is
warmed before enumerating, so every predicate any other process wrote to
that base would join the answer.

## `verify.sh` — the gates

```sh
sh tools/cocolint/verify.sh FILE.pl [FILE.pl ...]
sh tools/cocolint/verify.sh --gates G1,G4 FILE.pl
sh tools/cocolint/verify.sh --goal check FILE.pl        # a program whose entry point is not main/0
```

One line per gate, in cost order, and the first FAIL ends the run:

```
G0 pass  40-numpy.pl reads, and defines main/0
G1 pass  cocolint: 0 HARD, 0 WARN over 1 file(s)
G2 pass  consulted cleanly
G3 pass  no collisions (3 own, 0 declared hooks)
G4 pass  exit 0 and the last line of stdout is `done'
```

| gate | is | fails when |
|---|---|---|
| G0 | shape | a file does not exist, or none defines the goal, `main/0` by default |
| G1 | cocolint | a HARD finding — no process has started, so every message is exact |
| G2 | consult | the files do not load under `--local` |
| G3 | oracle | a predicate collided with a library's |
| G4 | execute | `run FILES GOAL` in a scratch directory does not exit 0 **with `done` as the last line of stdout** — both, always, since `main :- true.` satisfies exit 0 alone |
| G5 | localise | only when G4 failed with no `must/3` line: the last twenty lines of a `--trace`, which name the innermost sub-goal that ran out of ways with its arguments as they stood |

Exit **0** when every wanted gate passed or the run was skipped, **1** at a
FAIL, **2** for a usage error. `COCO_VERIFY_TIMEOUT` is the seconds G4 and
G5 allow a run, 60 by default; exit 124 from the program is that timeout.

Two skips are deliberate and both say so. Before G2 it probes every
`use_module(library(X))` the files name **as a goal**, because as a
directive a missing library succeeds in total silence (card row T1); a
library this checkout has not built ends the run with
`-- skip  NAME needs a library this checkout has not built` and the
`build.sh` to run. And when G4 dies with `existence_error(procedure, P)`
for a predicate the blocklist knows a module owns, it says which module and
skips — the case the probe cannot see, a file that calls a library it never
declared.

On a failed G4 it prints the `must/3` lines that named both values, the
first ten lines of stderr, and, with no `must/3` line, the G5 trace tail.

## `tool.sh` — the four builders

```sh
sh tools/cocolint/tool.sh build    [--if-stale]
sh tools/cocolint/tool.sh card     --check [--fix] | --facts [--if-stale] | --card | --patterns
sh tools/cocolint/tool.sh index    [--check] [--no-run]
sh tools/cocolint/tool.sh assemble [--show system|user] [--sizes] [--cap N] "REQUEST"
```

One driver, because the list of files each tool needs consulted beside it is
the only thing that varies. It exits with the tool's own status: 1 when the
goal failed, which is how a failing check reaches the shell.

### `build` — the blocklist

Reads every registration shape in the tree — the `("name" arity fn)`
tables, the clauses in `*X-prolog*` string tables, the `strcmp` chains of
the C++ modules, the clause heads of `lib/swipl/*.pl` and `library/*.pl`, and
the control constructs — and writes `blocklist.json` and `blocklist.pl`, the
same data as JSON for a reader and as facts for the linter. `--if-stale`
rebuilds only when an output is missing or older than a source. A hook — a
library clause of the form `H :- fail.` — is recorded as a hook, not a
collision.

### `card` — the dialect card

`traps.jsonl` is the card as data: thirty-four rows of `{id, severity, rule,
swi, cocolog, why, cite, fix, pattern}`. Each `cite` is a `path:A-B` line
range with an `anchor`, a literal substring that must appear inside it.

`--check` verifies every anchor and answers one of three ways:

```
traps: 34 rows, 42 cites all anchored, 14 S1 pattern terms
traps: T1: lib/library.cicili:537-537 moved to lib/library.cicili:585 (unique anchor, accepted)
traps: N1: anchor is not in lib/library.cicili:500-509 and appears 2 times (lines 63, 548) -- the range is what picks the site, so which one this row means is yours to say
```

A moved anchor that is unique in its file is accepted, and `--check --fix`
renumbers the range in place. An anchor that appears several times is a
complaint: the range was the only thing choosing between them, so a person
picks. An anchor that appears nowhere is the failure the check exists for:
the evidence was deleted or rewritten, and the row needs rereading, not
renumbering. Complaints make the exit status 1, and `--check` also
validates every `pattern` term: an unknown constructor is a rule that loads
and silently never fires.

`--facts` writes `traps.pl`, the rows as `cl_trap/7` facts the linter
consults (`--if-stale` skips it when current). `--card` prints the
divergence table as Markdown — the design document's card §B, one row per
`traps.jsonl` row, regenerated so the two cannot drift. `--patterns` prints
the fourteen S1 terms. `COCOLOG_TRAPS` points the checker at another
`traps.jsonl`, which is how the suite breaks a copy on purpose.

### `index` — the retrieval index

Writes three files and validates everything they name: `surface.jsonl`, one
row per library and per loadable module with its header block verbatim and
the names it documents; `exemplars.jsonl`, whole files and anchored spans
with the stdout each produced; `capabilities.json`, the hand-written topic
table. `--check` validates and writes nothing; `--no-run` skips running the
exemplars for their stdout. The report:

```
surface : 12 tier-2 libraries and 16 loadable modules, 121 KB of header, 464 documented of 1022 heads
exemplar: 8 rows, 5 with recorded stdout, all anchors matched once
capabil.: 24 topics, every library and tag checked
thin    : library(X) documents 0 of 15 heads -- its header has no signature list, so the index cannot offer a surface for it
unrouted: library(X) ships and no capability row names it -- nothing a reader asks for can route to it
```

`thin` and `unrouted` are reports, not failures. A thin library wants a
signature list in its header; an unrouted one wants a row in the topic
table. Both recipes are below.

### `assemble` — the prompt

Builds the system prompt and the user turn a model would receive for
`"REQUEST"`, from the index and nothing else, so the budget can be checked
without spending a token. `--sizes` prints the blocks and their estimated
tokens; `--show system` or `--show user` prints the text; `--cap N` changes
the 24,000-token cap on the user turn, which exists to exercise the drop
ladder and should not change on a real request. The router that picks the
topics is a keyword stub and says so on every line it prints.

## `agent.sh` — natural language in, a verified program out

```sh
sh tools/cocolint/agent.sh "read a JSON file and count the keys"
sh tools/cocolint/agent.sh --dry  "..."                # steps 1 and the prompt; no key needed
sh tools/cocolint/agent.sh --from gen/solver.pl "..."  # skip the model, verify this candidate
```

Three steps: route and assemble, generate, verify. The model call is the one
line that needs a key — `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` in the
environment, read by `library(llm)` — and without one it says which is
missing and exits **3**, having already run everything before it. Exit
**0** on a passed verification or a `--dry` run, **1** at a gate FAIL, **2**
for usage or a missing binary, **4** when the model call failed, **5** when
the reply was not a candidate. `--from` runs the whole verification half on
a file that already exists, which is what a repair iteration is.

## The hook

```sh
ln -s ../../tools/cocolint/pre-commit .git/hooks/pre-commit
```

Nothing installs it for you. On every commit it checks the card's
citations and lints the `.pl` files the commit stages, with a built binary;
without one it says SKIPPED rather than passing quietly. `git commit
--no-verify` skips it once.

## The suite case

```sh
cocolog -s test/lint.pl
```

Five things, in cost order: the card's 42 citations anchor and the checker's
three verdicts behave on a copy broken each way; the index's paths and
anchors resolve; `clauses.pl` reads `selftest/reader.pl` into exactly
`selftest/reader.expected`; every rule fires on `selftest/traps.pl`; and the
findings over the calibration corpus — every `.pl` under `library/` and
`tutorials/` — are the pinned set, and the blocklist agrees with the running
store. The last line is GREEN, RED or SKIP; about three minutes.

**A finding in the corpus is a linter bug until shown otherwise.** The
twenty-two that stand there are argued one by one in the script; ten of them
are tutorials teaching the very trap the rule enforces.

## Environment

| variable | read by | means |
|---|---|---|
| `COCOLOG_BIN` | every script | the binary; default `./cocolog` at the checkout's root |
| `COCOLOG_ROOT` | the `.pl` tools | the checkout; default the working directory, set by `tool.sh` |
| `COCOLOG_LIBRARY` | everything that runs cocolog | the library path; the scripts put `library/` first and keep yours |
| `COCOLOG_TRAPS` | `card` | another `traps.jsonl` to check, for tests |
| `COCO_LINT_MANIFEST` | `lint.pl` | set to anything: the files named are one program, and C2 runs over them |
| `COCO_VERIFY_TIMEOUT` | `verify.sh` | seconds for G4 and G5; default 60 |
| `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` | `agent.sh` | the model call, and only that |

`COCO_LINT_FILES`, `COCO_CC_FILES` and the three `COCO_AGENT_*` variables
are how the scripts hand file lists to the `.pl` tools; nothing outside this
directory sets them.

## Recipes

**Lint what you are writing.** `sh tools/cocolint/lint.sh prog.pl`; read the
`fix:` line under each finding. A HARD N-rule finding is a rename; an S1
finding is the card row's spelling; a WARN is a judgement call, and the
message says what it costs.

**Before a commit.** Install the hook once, or run `make dialect-check` and
`make lint FILES="a.pl b.pl"` by hand.

**Check a whole directory.** `sh tools/cocolint/lint.sh library/*.pl`. The
count line is the summary; the exit status is 1 if anything was HARD.

**Verify a program end to end.** `sh tools/cocolint/verify.sh prog.pl`. A
program whose entry point is not `main/0` names it with `--goal`; a program
that should print something other than `done` last cannot pass G4, and that
is the contract, not a gap.

**Add a divergence.** Add a row to `traps.jsonl` with `id`, `severity`,
`rule`, `swi`, `cocolog`, `why`, `cite` (a real line range and an anchor that
is code, never a comment), `fix`, and a `pattern` from the nine constructors
— `seq alt lit ws oneof noneof someof exactly bstart bend notword bol` — if
the linter is to catch it. Add the form to `selftest/traps.pl` so the suite
proves the rule fires. Run `sh tools/cocolint/tool.sh card --check`, then
`cocolog -s test/lint.pl`; if the new rule fires on the corpus, decide whether that
finding is real before touching the pinned set. Never edit `lint.pl` for an
S1 rule: S1 is generated from the card.

**A citation moved.** `sh tools/cocolint/tool.sh card --check`. Accepted
moves need nothing; `--check --fix` renumbers them. An ambiguous one names
the candidate lines: pick the definition, edit the range in `traps.jsonl`.
A gone one means rereading the row against the code as it is now.

**A library reads as thin.** Give its header a signature list: lines
starting at column 0 with the comment marker (`%%` in a `.pl`, `;;;` in a
`.cicili`), then the signature — `%%   name(+In, -Out)`, `%%   name/2`,
`%%   name//1` — one signature per line, since only the first on a line
counts, and the arity read up to the first `)`, so keep argument lists flat.
`?Mode` is fine. Internal `$`-prefixed heads need no line. In a `.cicili`
the list must sit in the leading comment block before its first blank line.
Check with `tool.sh index`.

**A library reads as unrouted.** Add an `ix_capability/5` row in `index.pl`:
the topic, the words a request would use, the libraries, the exemplar tags,
and `local`. `tool.sh index` checks every path and tag the row names.

**Run the agent without a key.** `--dry` shows the prompt; `--from FILE.pl`
verifies a candidate you wrote or a model returned elsewhere. Together they
exercise everything but the one line that sends a request.

## Where the rest is

The design the tools implement is `library/llm/DESIGN.md`: section 4 is the
card these rows come from, 5 the linter, 6 the oracle and its ordering
finding, 7 the gates, 9 the prompt, 10 the repair loop that is not built
yet. `README.md` beside this file records what each rewrite measured and
found. `tutorials/library/37-lint.pl` runs the linter as a lesson, with
every claim a `must/3`.
