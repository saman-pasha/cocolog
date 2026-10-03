# Where cocolog differs from SWI-Prolog and from ISO

One table for everything a program written for SWI-Prolog can trip over. Each
row was checked by running the same goal on both systems (SWI-Prolog 10.0.2, cocolog
1.8.36) — not recalled from the code — and the column on the right says what
to write instead.

The rows that can give a **silently wrong answer** come first, because they are
the ones a ported program will not report. Everything below them fails loudly:
an existence error, an instantiation error, a refusal by name.

## Silent: the answer is different and nothing says so

| what | SWI-Prolog | cocolog | what to do |
|---|---|---|---|
| integers | unbounded | 61-bit, −2^60 … 2^60−1; a result outside that **wraps without an error**: `X is 2**70` is `0`, `1152921504606846975 + 1` is `-1152921504606846976`. A literal outside it is refused, `syntax error ... integer out of range` (`2305843009213693952`, `0xffffffffffffffff`; before 1.8.50 a literal read as its low 61 bits, the first as `0`) | `library(bigint)` for anything that can get that large |
| `retract/1` | re-executable: `findall(X, retract(p(X)), L)` takes every clause, `[1,2,3]` | **deterministic**: removes the first match and leaves no choice point, `[1]` | `retractall/1` for all of them; or a recursion that retracts one and recurses until `retract/1` fails |
| text length and codes | characters: `atom_length('pequeño', N)` is `7`, `atom_codes('ñ', C)` is `[241]` | **UTF-8 bytes**: `8`, and `[195,177]`; `sub_atom/5` counts bytes too, `char_code('ñ', X)` raises an `instantiation_error`, and `char_code(C, 241)` makes the one-byte atom 0xF1, which is not `'ñ'` | keep text ASCII where its length matters, or count characters yourself from the bytes |
| case mapping | Unicode: `upcase_atom('ñandú', U)` is `'ÑANDÚ'` | ASCII only: `'ñANDú'` | — |
| `number_codes/2` | `number_codes(N, "3x")` is a `syntax_error` | answers `3`, ignoring what follows the number | check the text first if it may carry trailing characters |

## Loud: an error where SWI enumerates or accepts

| what | SWI-Prolog | cocolog | what to do |
|---|---|---|---|
| `atom_concat/3` with only the third argument bound | enumerates every split | `instantiation_error`; `(+,-,+)` and `(-,+,+)` work | `atomic_list_concat/3` with a separator, or `sub_atom/5` |
| `string_concat/3` with only the third argument bound | enumerates every split | `instantiation_error`; only `(+,+,-)` | `sub_string/5` |
| `between(1, inf, X)` | counts for ever | `Arithmetic: inf is not a function` | a large finite bound, or a recursion |
| `format/2` column directives | `~t`, `~\|`, `~+` | refused by name | pad with `atom_length/2` and `tab/1` |
| `set_prolog_flag/2` as a goal | allowed | a directive only — as a goal it is an `existence_error` | `:- set_prolog_flag(double_quotes, string).` at the head of the file |
| `current_prolog_flag/2` | dozens of flags | four: `argv`, `os_argv`, `executable` and `double_quotes`; any other fails | — |

## Not there at all (`existence_error`)

`numbervars/3`, `freeze/2` and coroutining, `table/1` and tabling,
`predicate_property/2`, `atom_to_term/3`, `string_code/3`, `print_message/2`,
`flag/3`, `recorda/2` and the recorded database, `prolog_load_context/2`.
`tab/2` and the other ISO stream predicates exist once
`:- use_module(library(stream)).` is loaded.

## Different by design, and documented where they live

| what | SWI-Prolog | cocolog | why |
|---|---|---|---|
| `"..."` | a string (SWI 7) | a list of codes, ISO's default; `double_quotes` takes `codes`, `chars`, `atom` and `string` | ISO, and what most Prolog text assumes |
| the list cell | `'[\|]'/2` | `'.'/2` — visible through `=..` and `functor/3` on a list | ISO's and the traditional name |
| a string written to the knowledge base or sent down a channel | a string | comes back as a code list | the store and the channel carry canonical text; README "What is stored" |
| builtins written in C | some leave choice points | every one is deterministic; the enumerating ones (`between/3`, `clause/2`, `sub_atom/5`, `member/2`) are clauses | a choice point needs the engine's choice stack, which a C builtin is not handed (STATUS.md, "Known limitations, by choice") |
| modules | separate namespaces; `use_module/2` imports a list | one namespace; the import list is accepted and ignored | MODULES.md |
| a predicate's clauses split across a file | joined, with a warning | joined, silently | — |
| a clause in a database-backed store | any size | must fit one page, about 8 000 characters; past it `assertz/1` raises `resource_error(clause_length)` | a row is one page; STATUS.md |
| floats written | `1.0e10` prints `1.0e+10` | prints `10000000000.0` | — |
| the heap | collected | collected since 1.8.36, between steps of the outermost engine — not inside a `findall/3` or `forall/2` goal while it runs; the float and string tables are not compacted | `lib/solve.cicili`, `coco_heap_gc` |

## Where to report one

A difference that is not on this page is either a bug or a row missing here.
Either way the useful report is the goal, what SWI answers and what cocolog
answers — the shape of every row above.
