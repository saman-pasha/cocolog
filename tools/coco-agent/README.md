# coco-agent — increment one

The deterministic half of the NL-to-cocolog agent designed in
[`library/llm/DESIGN.md`](../../library/llm/DESIGN.md). It is increment one of
that document's build order, chosen because it needs **no model, no API key, no
network and no built binary**, and because it is useful on its own: a cocolog
dialect linter a human runs by hand.

```sh
sh tools/coco-agent/lint.sh myprogram.pl
sh test/lint.sh                     # the suite case, over the 58-file corpus
```

| file | is |
|---|---|
| `clauses.py` | the clause reader everything stands on |
| `build.py` | the reserved-name blocklist, from five registration shapes |
| `lint.py` | the rules |
| `lint.sh` | the human wrapper; rebuilds the blocklist first, always |
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

## What the suite case holds

`test/lint.sh` runs the linter over the 47 basics+library tutorials and the 10
`library/*.pl` and expects exactly **3 HARD and 3 WARN**, all named. They are
true positives the corpus tolerates, and the case prints them rather than
hiding them — each is the argument for the rule that found it. The most
interesting is `tutorials/basics/10-grammars.pl`, which defines `digits//1` and
`digit//1`: those are also `dcg_basics`' names, and **the two definitions
differ** — the tutorial's wants at least one digit, `dcg_basics`' allows none.
It is latent rather than harmful only because their first solutions agree.

## Not built yet

Everything after increment three of `DESIGN.md` §13: the surface index, the
exemplar corpus, the router, the generator, the repair loop, and the collision
oracle that would replace the static blocklist with a runtime probe. This is
the part that needs no model; the rest needs one.
