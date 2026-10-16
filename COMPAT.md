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
| `retract/1` | re-executable: `findall(X, retract(p(X)), L)` takes every clause, `[1,2,3]` | **deterministic**: removes the first match and leaves no choice point, `[1]` | `retractall/1` for all of them; or a recursion that retracts one and recurses until `retract/1` fails |
| `number_codes/2` | `number_codes(N, "3x")` is a `syntax_error` | answers `3`, ignoring what follows the number | check the text first if it may carry trailing characters |
| a float result that is no number, or infinite | raises, its flags `float_undefined`, `float_overflow` and `float_zero_div` being `error`: `evaluation_error(undefined)` for a NaN (`0.0 / 0.0`, `sqrt(-1.0)`, `1.5NaN + 1`), `float_overflow` for an infinity (`10.0 ** 400`, `exp(1000)`), `zero_divisor` for `2 / 0.0` (swipl 9.0.4) | answers the NaN or the infinity: `X is 0.0 / 0.0` is `1.5NaN`, `2 / 0.0` is `1.0Inf`. What a NaN meets is SWI's: as a term since 2.1.1 (`0.0 \== -0.0`, a NaN unifies with itself and sorts first), and in the comparisons, `max`, `min` and `sign` since 2.1.2 (only `=\=` holds of a NaN, `max(1.0, NaN)` is `1.0`, `max(0.0, -0.0)` is `0.0`, `max(2, 1.5)` is `2`) | test a float result: `X =:= X` fails for a NaN, `abs(X) =:= 1.0Inf` holds for an infinity |
| `**` and `^` with a zero exponent, or the integer base 1 | the integer `1`: `2.0 ** 0`, `2 ** 0.0`, `1 ** 2.5`, `1.5NaN ** 0` (swipl 9.0.4) | the float `1.0`, and the integer `1` only of two integers (`2 ** 0`) | `integer/1` on the result |

## Loud: an error where SWI enumerates or accepts

| what | SWI-Prolog | cocolog | what to do |
|---|---|---|---|
| `atom_concat/3` with only the third argument bound | enumerates every split | `instantiation_error`; `(+,-,+)` and `(-,+,+)` work | `atomic_list_concat/3` with a separator, or `sub_atom/5` |
| `string_concat/3` with only the third argument bound | enumerates every split | `instantiation_error`; only `(+,+,-)` | `sub_string/5` |
| `between(1, inf, X)` | counts for ever | `Arithmetic: inf is not a function` | a large finite bound, or a recursion |
| `truncate/1`, `integer/1`, `round/1`, `floor/1` and `ceiling/1` of a NaN or an infinity | hands the float back: `truncate(1.0Inf)` is `1.0Inf`, `integer(1.5NaN)` is `1.5NaN` (swipl 9.0.4) | `evaluation_error(undefined)` (since 2.0.0; through 1.15.0 C made some integer of it) | test the float first (`X =:= X`, `abs(X) < 1.0Inf`) |
| `format/2` column directives | `~t`, `~\|`, `~+` | refused by name | pad with `atom_length/2` and `tab/1` |
| `set_prolog_flag/2` as a goal | allowed | a directive only — as a goal it is an `existence_error` | `:- set_prolog_flag(double_quotes, string).` at the head of the file |
| integers | unbounded | **64-bit**, −2^63 … 2^63−1 (since 2.0.0; through 1.15.0 61-bit, and a result past them wrapped in silence): a result outside that raises `evaluation_error(int_overflow)` — `X is 2**63` and `9223372036854775807 + 1`, and `2**63 - 1` too, whose `2**63` comes first — and a float made an integer outside it as well, `evaluation_error(undefined)` for an infinity or a NaN. A literal outside it is refused, `syntax error ... integer out of range` (`9223372036854775808`, `0x8000000000000000`), and `atom_number/2` and `number_codes/2` fail for such a numeral | `library(bigint)` for anything that can get that large |
| `current_prolog_flag/2` | dozens of flags | ten: `argv`, `os_argv`, `executable`, `double_quotes`, `text_units`, and since 2.0.0 `bounded` (`true`), `max_integer`, `min_integer`, `max_tagged_integer` and `min_tagged_integer`; any other fails | — |

## Not there at all (`existence_error`)

`numbervars/3`, `freeze/2` and coroutining, `table/1` and tabling,
`atom_to_term/3`, `string_code/3`, `print_message/2`,
`flag/3`, `recorda/2` and the recorded database, `prolog_load_context/2`.
(`predicate_property/2` is there since 1.10.28, for the program's
predicates, the constructs and the C builtins.)
`tab/2` and the other ISO stream predicates exist once
`:- use_module(library(stream)).` is loaded.

## Different by design, and documented where they live

| what | SWI-Prolog | cocolog | why |
|---|---|---|---|
| `"..."` | a string (SWI 7) | a list of codes, ISO's default; `double_quotes` takes `codes`, `chars`, `atom` and `string` | ISO, and what most Prolog text assumes |
| text counted in bytes | no such flag: text is characters | characters, SWI's, since 2.0.0 — and BYTES where a program asks, `:- set_prolog_flag(text_units, bytes).` or `COCOLOG_TEXT_UNITS=bytes`, the default through 1.x: `atom_length('pequeño', N)` is `8`, `atom_codes('ñ', C)` `[195,177]`, `sub_atom/5` counts bytes, `char_code(C, 241)` is the one-byte atom 0xF1, and case maps ASCII only (`'ñANDú'`) | a program written against 1.x's bytes; lesson basics/13 |
| a socket's codes | a stream with an encoding | `library(tcp)` and `library(tls)` read and write BYTES, 0..255, whatever the program counts; `library(http)`, `library(httpd)`, `library(websocket)` and `library(curl)` hand the program text in its units and put its text on the wire as UTF-8 (2.0.0; through 1.15 they handed bytes, and under characters a path `caf%C3%A9` was `cafÃ©`); `string_bytes(Text, Bytes, utf8)` is the crossing, SWI's, whatever the units | a socket is a binary stream; library/http.pl's header |
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
