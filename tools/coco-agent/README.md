# coco-agent — increments one through four

The deterministic half of the NL-to-cocolog agent designed in
[`library/llm/DESIGN.md`](../../library/llm/DESIGN.md). These are increments
one through four of that document's build order, which are exactly the ones
that need **no model, no API key and no network** — and, but for the empirical
notes in `traps.jsonl`, no built binary either. All of it is useful on its own:
a cocolog dialect linter a human runs by hand, and a dialect card whose
citations are checked rather than trusted.

```sh
sh tools/coco-agent/lint.sh myprogram.pl
make lint FILES=myprogram.pl        # the same thing, through make
make dialect-check                  # every citation still points at its code
sh test/lint.sh                     # the suite case, over the 58-file corpus
```

| file | is |
|---|---|
| `clauses.py` | the clause reader everything stands on |
| `build.py` | the reserved-name blocklist, from five registration shapes |
| `traps.jsonl` | the dialect card as data: 36 rows, 43 checked citations |
| `traps.py` | the anchor checker, and the S1 pattern table lint.py loads |
| `lint.py` | the rules |
| `lint.sh` | the human wrapper; rebuilds the blocklist first, always |
| `pre-commit` | an opt-in git hook: the card, plus cocolint over staged `.pl` |
| `selftest/traps.pl` | a file that walks into every divergence, on purpose |
| `blocklist.json` | generated, not committed — `build.py` remakes it in under a second |

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

## Not built yet

`DESIGN.md` §13's increments 5, 6 and 8 — the surface index, `verify.sh`'s
gates, and the collision oracle — are next and still need no model. Everything
from 9 on does: the router, the generator, the repair loop, the eval set.
