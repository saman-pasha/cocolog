# coco-agent — the deterministic half, built

The deterministic half of the NL-to-cocolog agent designed in
[`library/llm/DESIGN.md`](../../library/llm/DESIGN.md). These are increments **1–6 and 8** of
that document's build order: every part that needs **no model, no API key and
no network**. All of it is useful on its own — a cocolog dialect linter a human
runs by hand, a dialect card whose citations are checked rather than trusted,
and a gate script that says why a program did not prove.

```sh
sh tools/coco-agent/verify.sh myprogram.pl   # every gate, in order
sh tools/coco-agent/lint.sh    myprogram.pl  # G1 alone
sh tools/coco-agent/oracle.sh  myprogram.pl  # G2+G3 alone
make lint FILES=myprogram.pl                 # G1, through make
make index                                   # rebuild the blocklist and index
make dialect-check                           # every citation still resolves
sh test/lint.sh                              # the suite case
```

| file | is |
|---|---|
| `clauses.py` | the clause reader everything stands on |
| `build.py` | the reserved-name blocklist, from five registration shapes |
| `traps.jsonl` | the dialect card as data: 36 rows, 43 checked citations |
| `traps.py` | the anchor checker, and the S1 pattern table lint.py loads |
| `lint.py` | the rules |
| `lint.sh` | the human wrapper; rebuilds the blocklist first, always |
| `oracle.pl` / `.sh` | G2+G3: which predicates the store calls the program's own |
| `verify.sh` | G0–G5 in order, each with the reason it exists |
| `index.py` | `surface.jsonl`, `exemplars.jsonl`, `capabilities.json` |
| `pre-commit` | an opt-in git hook: the card, plus cocolint over staged `.pl` |
| `selftest/traps.pl` | a file that walks into every divergence, on purpose |
| `blocklist.json` and the three index files | generated, not committed — remade in seconds |

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
`digit/1` absent, `call/1` absent, `=/2` present.

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

`traps.jsonl` is section 4 of the design doc as 36 rows of
`{id, swi, cocolog, why, cite, anchor, rule, severity}`. Each cite is a
`path:A-B` line range and each anchor a literal substring that must appear
inside it. `traps.py --check` verifies all 43, and when one has moved it says
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
apart. Adding a divergence means adding a row, never editing `lint.py`.

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

`index.py` builds three files, and validates everything it names.

**A header block is the only authority on what a library offers.**
`library/json.pl` has **70 clause heads and documents 6**; a clause-head
listing would offer `json_hex4/3` as API, and a model handed that will call it.
So `surface.jsonl` carries the leading `%%` block verbatim plus every
`%% name(...)` doc line whose name the file *actually defines* — that last
condition matters, or prose naming `split_string/4` as something cocolog does
**not** have would enter the index as something it does. Across the ten tier-2
libraries: 43 KB of header, **86 documented names of 450 heads**.

Where a header has no signature list the index says so rather than
under-serving quietly: `library(kbs)` documents 1 of 14, because its header
explains the design at length and names its predicates only inside running
prose.

**Exemplars are anchored by substring and they are RUN.** A line-range citation
rots faster than a file citation, and silently — the span still resolves, it
just teaches half a predicate. Every anchor must match **exactly once** or the
build fails. And each runnable exemplar carries the stdout
`cocolog --local run FILE main` actually produced: the only grounding signal in
the repository that a stale comment cannot corrupt, because the model sees
behaviour rather than appearance.

**`capabilities.json` is twenty-one hand-written topic rows** and the builder
checks every library and every exemplar tag they name — which is §9.2's whole
argument against embeddings, that this is an exact-match problem over a few
dozen documents with one hand-labelled topic each.

## Not built yet

Increment 7 is the bootstrap and is done — cicili, sbcl, a built ZiguratIP,
`make`. What is left all needs a model: the router (10), the generator and
assembler (9), the repair loop and presenter (11), G6's swipl differential and
G7's cross-process gate (13, which also want a `swipl` and a server this
container has neither of), and the eval set (14) that produces every number the
design's "add it when" thresholds refer to.
