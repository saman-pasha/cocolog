# cocolint — the deterministic half, in cocolog

The deterministic half of the NL-to-cocolog agent designed in
[`library/llm/DESIGN.md`](../../library/llm/DESIGN.md). These are increments **1–6 and 8** of
that document's build order: every part that needs **no model, no API key and
no network**. All of it is useful on its own — a cocolog dialect linter a human
runs by hand, a dialect card whose citations are checked rather than trusted,
and a gate script that says why a program did not prove.

**The directory is named for the part you run by hand.** cocolint is one of
the things in it — the linter, `lint.pl` and the reader under it — and the
card, the retrieval index, the oracle probe and the agent's own driver live
here too, because every one of them is deterministic and they share the one
clause reader. `library/llm/DESIGN.md` names the whole system Ashurbanipal;
nothing in this directory needs a model.

```sh
sh tools/cocolint/verify.sh myprogram.pl   # every gate, in order
sh tools/cocolint/lint.sh   myprogram.pl   # G1 alone
sh tools/cocolint/oracle.sh myprogram.pl   # G2+G3 alone
make lint FILES=myprogram.pl               # G1, through make
make index                                 # rebuild the blocklist and index
make dialect-check                         # every citation still resolves
sh test/lint.sh                            # the suite case
```

| file | is |
|---|---|
| `clauses.pl` | **the clause reader**, as one grammar |
| `lint.pl` | **the rules**, as clauses |
| `tool.sh` | one driver for `build`, `card`, `index` and `assemble` |
| `selftest/reader.pl` `.expected` | every shape that has ever fooled a clause reader |
| `build.pl` | the reserved-name blocklist, from five registration shapes |
| `traps.jsonl` | the dialect card as data: 34 rows, 42 checked citations |
| `card.pl` | the anchor checker, and the generator of `traps.pl` |
| `lint.sh` | the human wrapper; rebuilds the index first, always |
| `oracle.pl` / `.sh` | G2+G3: which predicates the store calls the program's own |
| `assemble.pl` | the prompt, block by block, with the budget ladder |
| `agent.sh` | the driver: route, assemble, generate, verify |
| `generate.pl` | the model call, through `library(llm)` — the one unexercised line |
| `verify.sh` | G0–G5 in order, each with the reason it exists |
| `index.pl` | `surface.jsonl`, `exemplars.jsonl`, `capabilities.json` — the libraries AND the loadable modules |
| `pre-commit` | an opt-in git hook: the card, plus cocolint over staged `.pl` |
| `selftest/traps.pl` | a file that walks into every divergence, on purpose |
| `blocklist.pl` `traps.pl` | the blocklist and the card as CLAUSES, generated |
| `blocklist.json` and the three index files | generated, not committed — remade in seconds |

## The linter is cocolog

`clauses.py` (375 lines of hand-rolled scanning) and `lint.py` (332 lines of
compiled regexes) were the tool disagreeing with the repository it lints. They
are `clauses.pl` and `lint.pl` now, and the Python is **gone** — the rewrite
was held to it byte for byte first:

```
GREEN: 3974 clauses over 99 files, identical to clauses.py in offset,
       line, column, length, name, arity and kind
GREEN: lint.pl and lint.py agree byte for byte -- 7 HARD, 10 WARN over 58
       file(s), and 24 HARD, 4 WARN on selftest/traps.pl
```

**What replaced that check is two fixtures and a probe**, and the trade is
worth naming rather than glossing. A second implementation catches a
regression by *disagreeing* — powerful, and it rots the moment nobody
maintains it. A fixture catches one by being **specific** about cases that
actually broke something, and does not go stale when an unrelated tutorial is
edited. `selftest/reader.pl` is twenty clauses covering every shape that has
ever fooled a clause reader here; `selftest/traps.pl` walks into all 24 lint
rules; and the store probe checks the blocklist against the **interpreter**,
which was always better ground truth than a second reader.

Verified by breaking it: delete `cc_charskip`'s four-character doubled-quote
clause and `rd_quote(0''')` reads as `rd_quote/1 plain` where the fixture pins
`rd_quote/3 dcg`, and the case reports
`RED: clauses.pl no longer reads its own fixture the way it is pinned`.

**Two scanners became one grammar.** `clauses.py` needed a clause splitter *and*
a lexical-region scanner, and its own docstring names the hazard: "two scanners
that disagree about where a string ends is exactly the bug this is meant to
prevent." In the DCG they are the same non-terminals, so the disagreement is
not guarded against — it cannot be written down.

**Each rule became a clause.** `cl_collision/8` is three clauses in dispatch
order, which is the order the interpreter itself uses: construct, then C table,
then store. First-argument indexing does what a `dict` lookup did.

**`build.py` and `index.py` read through `clauses.pl` too**, via `ccbatch.py`
— an adapter that hands the whole workload to **one** cocolog process through
a length-prefixed document stream. A per-call adapter would have been 615
start-ups and measured 3.7 s against 0.19 s; batched it is 489 documents in
**one** process. The blocklist and the surface index come out byte-identical.

Getting to one process took two rounds of hoisting, both visible in the
`reader:` line `build.py` now prints so a regression in batching is loud
rather than merely slow: 24 processes because `shape4_pl` is called per
library file, then 14 because `shape2_prolog_halves` is called per module, and
one once both collections are hoisted into `build()`.

**The cost is real and is paid once.** `build.py` went 0.19 s → 4.4 s, so
`lint.sh` — which rebuilt the index unconditionally — went 0.25 s → 4.5 s for
a single file. `--if-stale` keeps the guarantee that mattered (never lint
against a stale blocklist: a missing or out-of-date output is rebuilt) and
drops the waste. Cold 4.8 s, **warm 0.25 s**, and touching `lib/lists.cicili`
correctly makes it cold again.

**There is one clause reader.** `build.py` and `index.py` reach it through
`ccbatch.py`; `oracle.sh` and `verify.sh` do too; `lint.pl` calls it directly.
Nothing carries a second one.

## S1 is terms, not regexes

The seventeen banned forms live in `traps.jsonl` as **terms**, and nothing
else — they carried a Python regex too while a Python linter matched them, and
that half is gone with it.

```prolog
cl_trap('P1', hard, code,
        seq([lit(current_prolog_flag), ws, lit('('), ws,
             notword(executable), oneof('abcdefghijklmnopqrstuvwxyz_')]), ...)
```

Porting them to `library(text)`'s POSIX binding instead would have lost six
things, **three of them silently**: `\d` becomes a literal `d`; lazy `.*?`
compiles and is greedy; lookaround and `(?:...)` fail with no error; `[^\n]`
reads as "not backslash, not n"; a pattern `regcomp` rejects is
indistinguishable from one that missed; and there are no flags. Worst of all,
nothing in that binding answers *where* a match was, and every finding is a
`file:line:col`.

Nine constructors cover all seventeen — `seq alt lit ws oneof noneof someof
exactly bstart bend notword bol` — and a tenth would mean a rule wants a real
parser and should be a rule of its own.

**`card --check` validates the terms**, and it checks more than the
`re.compile` it replaced could: a regex that compiled might still be a rule
nobody had written a matcher for, whereas an unknown constructor here is a
rule that loads fine and **silently never fires**. It knows which arguments
are patterns and which are data — `lit(format)` names a word, it does not call
a constructor — and it catches `lit(foo`, `oneuf(bar)` and a bare `bstrt`.

## Making it fast enough to be a suite case

The first working version took **2 minutes 11 seconds** over the 58 files
against Python's 0.4 s. It is **23 s** now, and every step was measured rather
than guessed:

| | | |
|---|---|---|
| the blocklist as clauses, not JSON | 275 ms → 7 ms | and first-arg indexing on every lookup after |
| `Z1` reusing the file's regions | 43,000 ms → 0 ms | on one file: `cc_in_region` per byte is 16M comparisons; the walk is ordered, so consume the regions in lockstep |
| every clause's text in one walk | 14.7 s → 5.7 s | `cc_drop` from the start per clause is quadratic — 396 clauses × 24 KB |
| `S1` indexed by first code | 41 s → 23 s | seventeen patterns tried at every byte becomes one lookup |

The remaining 23 s is DCG walking, roughly linear. It is ~58× slower than
Python and fast enough for a suite case that also proves two rewrites
equivalent.

## Why a clause reader and not a regex

On `lib/swipl/dcg_basics.pl` a regex over heads answers `digit/1`, `digits/1`,
`string/1`, `blank/0`. What the store holds is `digit/3`, `digits/3`,
`string/3`, `blank/2`, because **a DCG head occupies arity+2**. A regex
blocklist is under-broad *in exactly the arity that collides*: it blocks a name
nothing defines and lets the real one through. The reader also strips `/* */`
and `%` regions, without which `yall.pl`'s `/** <module> */` header contributes
a bogus `call/1..4`, `atom_concat/3` and `maplist/3`.

Two bugs found in the reader by its own calibration corpus, both of the kind
that fails silently:

* **`:- dynamic seen/1.` is `dynamic/1`, not `dynamic/0`.** A prefix operator
  takes its argument without parentheses. Reading it as arity 0 made the linter
  reject eight files of correct code.
* **A `.` after a digit still ends a clause.** A guard meant to protect `3.14`
  refused to end `:- table foo/2.`, so that directive silently swallowed the
  clause after it and dropped its head from the blocklist. The `3.14` case is
  already excluded by the following character being a digit rather than
  whitespace; the extra guard only did harm.

## The five registration shapes

| # | shape | where | count |
|---|---|---|---|
| 1 | `("name" arity fn)` tables | `lib/*.cicili` | **141** |
| 2 | clauses inside `*X-prolog*` string tables | `lib/`, `modules/` | read with the same clause reader |
| 3 | a `strcmp` chain under `(== arity N)` | torch (**37**), bigint (**17**) | no arity recorded — blocked at every arity |
| 4 | clause heads at column 0 | `lib/swipl/*.pl`, `library/*.pl` | DCG heads at arity+2 |
| 5 | `*construct-names*` | `lib/solve.cicili:151-154` | **22**, no arity |

Shape 1's pattern must accept **any** name, not an alphanumeric one: the first
version required `[a-zA-Z_]` and therefore missed every operator builtin —
`=/2`, `==/2`, `is/2`, `</2`, `=../2` — which is fifteen names in `lib/` alone
and precisely the ones a generated program redefines by accident.

**No total is an acceptance test.** Two independent extractions this session got
464 and ~533 for tier 1, differing on `$`-prefixed internals, DCG arity and
comment stripping. What is pinned instead is behaviour: `digit/3` present and
`digit/1` absent, `call/1` absent, `=/2` present — and, once there was a binary,
the probe below.

## The blocklist, asked of the running store

The strongest check here, and it costs two processes. One file defines **every**
clause-defined tier-1 name at its recorded arity and puts it to the oracle:

```
probe: 342 of 342 clause-defined names confirmed taken by the store;
       110 C-dispatched names come back visible, which is the blind spot N2 covers
```

The second half is the point as much as the first. A C-dispatched name's record
has `library = 0`, so the oracle calls it **own** while the clauses are dead —
the design said "neither mechanism is sound alone" and this is that claim
measured: the oracle misses 110 of 112 probeable C names, and rule N2 is the
only thing that sees them.

**It found three defects in the extractor, and each was silent.**

* **Shape 2 was scanning every string literal in a `.cicili` file, not the
  `*X-prolog*` table.** `"abs"` out of the arithmetic `strcmp` chain became the
  clause `abs.` and was recorded as `abs/0`; so did `"abc"` from a test and
  `"access_mode"` from a mode check — **352 names in all**, every one of which
  would have made the linter reject a program for defining a name nothing in
  cocolog defines. That is the worst kind of false positive, because the
  message is confident and cites a file. The blocklist went 752 → 400.
* **A `Module:Head` clause was read under the qualifier.** `aggregate.pl` writes
  `sandbox:safe_meta_predicate(...)`, and cocolog — having no module system —
  stores that under the **head**. Asked directly: a file defining
  `safe_meta_predicate/1` comes back COLLIDED, one defining `sandbox/1` comes
  back own. Reading the qualifier as the name was wrong in both directions at
  once, blocking a free name and missing a taken one.
* **`throw/1` sat in the clause set.** A control construct is recorded with no
  arity (`throw/*`), so the rule that removes C-registered names from the clause
  set — an exact key match — left the arity-1 entry behind, where the prompt's
  symbol block would have called it `nondet`. It is a construct: rule N3, which
  matches on the name alone, is the only thing that catches it.

## Two axes, because the halves fail differently

**When** — tier 1 is always live; a module's names count only once the file
imports it. Blocking `ray_open/3` in a program that never touches raylib is
noise, and noise is how a linter gets turned off.

**How** — a C-registered name is dispatched *before* the store
(`lib/solve.cicili:1352-1386`), so redefining one is **dead code**. A
clause-defined one is consulted into the same store and consult **appends**, so
redefining one merges the two sets of clauses. The rules say different things.

## Hooks are not collisions

`library/httpd.pl:683` is `httpd_page(_, _, _) :- fail.` — a **declared
extension point**, which exists so a program can add its own pages. That is the
whole design of that library. A clause of the form `H :- fail.` in a library is
excluded from the blocklist; blocking it would tell every httpd user to rename
the one predicate they are supposed to write.

**The oracle and rule N1 agree on all 58 files**, and the one place they used
to differ is why `blocklist.json` now records the hooks rather than discarding
them. `16-httpd.pl` defines `httpd_page/3`: the oracle called it **COLLIDED**,
correctly — the clauses really do merge into that record and
`current_predicate/1` really does say no — and N1 stayed quiet, also correctly,
because it is the extension point the library exists to offer. Both are right
about the mechanism and only one is right about the intent, so both now read
the same list.

## The dialect card is data, and its citations are checked

`traps.jsonl` is section 4 of the design doc as 34 rows of
`{id, swi, cocolog, why, cite, anchor, rule, severity}`. Each cite is a
`path:A-B` line range and each anchor a literal substring that must appear
inside it. `card --check` verifies all 42, and when one has moved it says
where it is now, so the repair is a single number:

```
traps: F1: anchor not in lib/builtins.cicili:900-910 (it is at line 1015)
             '(== d 116)'
```

**The anchor is code, never prose near it.** A comment is the part of a file
that gets rewritten without the behaviour changing, so anchoring on one buys a
check that passes while the claim quietly stops being true. Row F1 anchors on
`(== d 116)` rather than on the word "column"; row I1 on `coco_arg_key` rather
than on the shouted comment above the declaration, true though that comment is.
Two rows anchor on a comment anyway and say so in the file: `Z1`'s page limit
lives in `parsi/01-schema.parsi` as a paragraph of measured numbers with no
code beside it, and `R2`'s evidence *is* the Prolog text inside a `*X-prolog*`
string table.

**S1 is generated from it**, so a rule and the evidence for it cannot drift
apart. Adding a divergence means adding a row, never editing `lint.pl`.

## Three things the binary corrected, once there was one to ask

The design doc was written without a build (its section 16 says so). Three of
its card rows turned out to need amending, and each correction is in the row
that was wrong, under `empirical`:

* **C2 was backwards for builtins.** The card said `catch(G, error(T,
  context(_,_)), _)` never matches here. Measured: a builtin leaves the second
  argument **unbound**, and an unbound argument unifies with `context(_,_)`, so
  SWI's pattern catches builtin errors perfectly well. What it does *not* catch
  is the house style the card itself prescribes — `throw(error(type_error(a,b),
  my_codes/2))` — where the context is a bare `Name/Arity`. Split into rows C2
  and C3.
* **T1's mechanism is exact and the claim survived.** A missing library really
  does make the directive succeed in total silence — verified with an empty
  stderr and exit 0 — and the reason is one line: `lb_directive_hook` maps every
  non-zero return to success, including the **−1** that means *not found*.
* **Z1 is worse than documented.** The card says a too-big row is refused at the
  turn's flush. Measured under `--embed`: a clause of 8000 bytes reads back from
  a second process and one of 8020 does not, and the writing process reports
  **exit 0, empty stderr and `done` on stdout** either way. Nothing says the
  clause was lost. That makes the lint rule the only warning there is.

## Every rule has to fire, and a corpus of correct code cannot show that

`test/lint.sh` has two halves. The first runs cocolint over the 58 files and
pins the exact **set** of findings — not a count, because two findings that
cancel out in a total would slip through. The second runs it over
`selftest/traps.pl`, which walks into every divergence on purpose, and asserts
that all 24 rules still fire. A rule whose pattern has quietly stopped matching
is invisible against code that is correct; this is the half that sees it.

Writing the trap file caught two bugs in the linter itself:

* **`"\x41\"` ends a string with a backslash**, which cocolog forbids and
  which no scanner can read: the literal ran to end of file, and every rule
  after it found its match inside a quote and skipped it. H1 and L1 both went
  missing that way — the trap file trapping its own author.
* **`'[|]'` is a quoted atom by construction**, so L1 needed the same
  `scan: text` that F1's format directives and E1's escapes have. The three of
  them read a quote as code; nothing reads a comment as code, because a comment
  naming `~t` documents the rule rather than breaking it.

## What survives on the calibration corpus, and why it stays

Seventeen findings over 58 known-good files, and **ten of them are tutorials
teaching the very trap the rule enforces** — `basics/07`'s
`( retract(seen(_)), fail ; true )`, `library/04`'s `~t~20|` inside a `catch/3`,
and six `1000000000000000000 * 997` wraps across three lessons. That is the
strongest evidence available that the rules point at real divergences: somebody
thought each one worth writing a lesson about.

Four are real findings left for the owner rather than quietly edited: three
tutorials whose `must/3` calls `halt(1)` where the other 44 fail, and one whose
`main/0` is ~15 KB stored — twice the page budget, harmless only because the
tutorial runs `--local`. The last three are no-op tier-1 imports already named
in `CLAUDE.md`.

## The gates, and what each is for

`verify.sh` runs them in cost order, and the cheapest one blocks first — G1
finds a collision before any process starts.

| | is | and the reason it is not the obvious thing |
|---|---|---|
| G0 | the file reads and defines `main/0` | there is no entry directive; the CLI names the goal |
| G1 | cocolint | free, exact, and mechanical to repair |
| G2 | it consults under `--local` | a byte offset is the highest-value repair signal there is, and `-s` throws it away |
| G3 | the collision oracle | asks the running binary, where G1 asks a table somebody maintains |
| G4 | exit 0 **and** the last line of stdout is `done` | exit 0 alone is satisfied by `main :- true.` |
| G5 | a `--trace` tail, **only** when G4 failed with no `must/3` line | with a `must/3` line the two values already say more than a trace would |

**Two things it does that a hand-rolled runner would not.** It runs in a
scratch directory with **no `library/` in it**, because the library path probes
`./library` relative to the working directory first — so a candidate's own
directory could otherwise shadow the real one. And it **never merges the
streams**: stdout is block-buffered into a file, stderr's buffering is a
platform default, so a merged capture's ordering is meaningless.

**It probes a tier-2 library as a goal, never as a directive**, because the
directive succeeds in total silence when the library is missing. And when a
run dies with `existence_error(procedure, x509_validate/2)` it looks the name
up in the blocklist and answers `library(x509)`, `sh modules/x509/build.sh` —
catching the case the preflight cannot, a file that *calls* a library it never
declared. `tutorials/library/27-ca.pl` is exactly that file.

Over the 48 basics+library tutorials, in a scratch directory: **40 pass, 7 skip
for a library this checkout has not built, 1 fails** — and the one failure is
`03-files.pl`, whose own `must/3` says `run_me_from_the_repo_root`. A correct
verdict, not a gate bug.

## The index: what a library says about itself

`index.pl` builds three files, and validates everything it names.

**A header block is the only authority on what a library offers.**
`library/json.pl` has **70 clause heads and documents 6**; a clause-head
listing would offer `json_hex4/3` as API, and a model handed that will call it.
So `surface.jsonl` carries the leading `%%` block verbatim plus every
`%% name(...)` doc line whose name the file *actually defines* — that last
condition matters, or prose naming `split_string/4` as something cocolog does
**not** have would enter the index as something it does.

**Tier 2 has two kinds and a caller cannot tell them apart.** `library(json)`
is a `.pl` on the library path; `library(tcp)` is a `.so` dlopen'd from
`modules/tcp`; both are one `use_module` and neither says which it is. The
index had rows for the first kind only — so a request routed to `torch`, `tcp`
or `tensorflow` reached the model with its NAMES, out of the blocklist in
block D, and not one line saying what any of them is for. Fifteen modules, and
half the capability table pointed at them.

A module's header is the same kind of document in the same voice; the comment
marker is Lisp's, and `;;;;` is `%%`. It is the `.cicili`'s and not the
README's: `modules/torch` and `modules/tensorflow` each carry seventeen
kilobytes of README, which is the right size for a reader and four times the
budget of a prompt block. And its heads come from **`build.pl`'s own three
shapes** — the `("name" arity fn)` table, the `*X-prolog*` half and the strcmp
chain a C++ target dispatches on — rather than from a second scanner over the
same two files. Across the whole of tier 2: **12 libraries and 15 modules,
98 KB of header, 176 documented names of 940 heads**.

Where a header has no signature list the index says so rather than
under-serving quietly: `library(kbs)` documents 1 of 14, because its header
explains the design at length and names its predicates only inside running
prose. Nine rows say it now, and eight of the nine are modules whose surface
lives in a README or nowhere but the code.

**And it says which library nothing can route to.** `ix_unrouted` compares
what ships against what the topic table names, because that is the half a
hand-written table cannot check about itself. Four were unrouted when the
check was written and not one was a decision: `tensor_expr` and `tensorflow`
arrived after the table did, and `main` and `ray` were missed on the day it
was written.

**Exemplars are anchored by substring and they are RUN.** A line-range citation
rots faster than a file citation, and silently — the span still resolves, it
just teaches half a predicate. Every anchor must match **exactly once** or the
build fails. And each runnable exemplar carries the stdout
`cocolog --local run FILE main` actually produced: the only grounding signal in
the repository that a stale comment cannot corrupt, because the model sees
behaviour rather than appearance.

**`capabilities.json` is twenty-three hand-written topic rows** and the builder
checks every library and every exemplar tag they name — which is §9.2's whole
argument against embeddings, that this is an exact-match problem over a few
dozen documents with one hand-labelled topic each.

## The prompt, and a correction to the drop order

`assemble.pl` builds the system prompt and the user turn from the index and
nothing else, so the budget ladder can be checked without spending a token.

```
system  : ~3644 tokens
  A. the request                           ~   15
  B. router verdict                        ~   79
  C. surface library(json)                 ~ 1184
  D. symbols: C table and imports          ~ 2303
  D2. symbols: tier-1 library predicates   ~  349
  E. reserved short names                  ~  397
  F. exemplar parser: dispatch             ~ 1470
  F. exemplar self-checking program        ~ 1221
user    : ~7144 tokens of a 24000 cap
```

**The design's drop order is corrected here, and the correction is measured.**
It read: third exemplar → second exemplar → largest header → symbol scope. That
was written expecting block D at 0.8–2k tokens. Counted, the C table plus the
everyday tier-1 predicates is 2.7k, and on a request importing eleven libraries
the symbol block reaches **13k** — following the stated order there leaves the
model *one* exemplar and a 13k name dump. The wrong half kept: the exemplars are
the only grounding signal in the turn, and the symbol list is exactly what the
gates check perfectly. So D2 goes **first**. Block E and the router verdict are
still never dropped, because E is the one place the model needs a *blocklist*
rather than a vocabulary.

When every rung is spent and the turn is still over, it **says so** rather than
going over in silence: the tier-2 symbol rows dominate, and dropping those while
keeping the imports would hand the model a library it may use and no names for
it. Narrowing the request is §11's business, not the assembler's.

**The full reserved table is deliberately not in the prompt** — the design says
so, and the reason is the split above: a generator needs a vocabulary, and the
blocklist half of the job belongs to block E and to G1.

## What is not exercised, exactly

One line: the model call in `generate.pl`. Everything around it is arranged so
that everything else is — `agent.sh --dry` prints exactly what would be sent,
and `agent.sh --from FILE.pl` runs the whole verification half against a
candidate that already exists, which is what the repair loop does on every
iteration. Without a key, `agent.sh` says which key is missing and exits 3
rather than sending an unauthenticated request and reporting a 401 three layers
down.

`generate.pl` passes its own gates, and G1 caught its first bug: it called
`write_file/2`, which does not exist. The predicate is `write_file_from_codes/2`
— there is no stream layer here, so `library(files)` names the one predicate
that writes a whole file. The smallest possible demonstration that the tool
works.

## Not built yet

Increment 7, the bootstrap, is done. Increment 9's assembler is done and its
generator is written; **increment 10's router is a keyword stub** and says so on
every line it prints — `capabilities.json` is the exact-match table either way,
but a feasibility verdict, a refusal and `request_divergences` are a model's job.
What is left: the repair loop and the presenter (11), the last lint rules (12),
G6's swipl differential and G7's cross-process gate (13 — which want a `swipl`
and a server this container has neither of), and the eval set (14) that produces
every number the design's "add it when" thresholds refer to.
