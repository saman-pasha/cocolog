# Where cocolog differs from SWI-Prolog and from ISO

One table for everything a program written for SWI-Prolog can trip over. Each
row was checked by running the same goal on both systems (SWI-Prolog 9.0.4, and
the installed 10.0.2 where the two agree; cocolog 2.5.0) — not recalled from the
code — and the column on the right says what to write instead.

The rows that can give a **silently wrong answer** come first, because they are
the ones a ported program will not report. Everything below them fails loudly:
an existence error, an instantiation error, a refusal by name.

## Silent: the answer is different and nothing says so

| what | SWI-Prolog | cocolog | what to do |
|---|---|---|---|
| `retract/1` | re-executable: `findall(X, retract(p(X)), L)` takes every clause, `[1,2,3]` | **deterministic**: removes the first match and leaves no choice point, `[1]` | `retractall/1` for all of them; or a recursion that retracts one and recurses until `retract/1` fails |
| `clause/2` changing its predicate during its own enumeration | the clauses that stood when it began: `findall(X, ( clause(q(X), true), ( X == 1 -> retract(q(1)) ; true ) ), L)` over `q(1). q(2). q(3).` is `[1,2,3]`, and with `asserta(q(0))` in the retract's place `[1,2,3]` too | the count taken when it began and each clause read by its place among the live ones then: `[1,3]`, and `[1,1,1]`. A CALL of the predicate keeps ISO's logical update view as swipl's does (since 2.3.0; through 2.2.5 a retry read the live clauses too) | `findall/3` the clauses first, then change the predicate |
| `abolish/1` | takes the predicate away, its `dynamic` declaration with it: a later call raises `existence_error(procedure, q/1)` | takes its clauses away and keeps it known: a later call fails | `retractall/1`, which keeps the predicate dynamic in both |
| `listing/1` and the REPL's answer | `f('don\'t')`, and `f(B)` for `f('$VAR'(1))`, which reads back as a variable | `f('don''t')` and `f('$VAR'(1))`, which read back as the term. writeq/1, print/1, write_canonical/1, `~q`, `~p` and write_term/2's `quoted(true)` write `'don\'t'` as swipl's do since 2.2.5, and write/1, writeq/1 and their kin `B` (through 2.2.4 `'don''t'`, and `'$VAR'(1)` but for print/1); term_to_atom/2 writes `'don''t'` in both | writeq/1 |
| a control character with no letter of its own (1-6, 14-31, 127) in a quoted atom or string | `writeq('\x1\')` is `'\x1\'`, print/1's `'\u0001'` | the character itself between the quotes, which reads back here; this reader has no `\x..\` escape (cocolint E1). The four with a letter are written `\a` `\b` `\v` `\f` as swipl's since 2.2.5. term_to_atom/2 writes a newline or a tab as it is in swipl, `\n` and `\t` here | — |
| an integer before an infix operator written quoted | `1 'x\'y' 2` | `1'x\'y'2`, and after a 0 it reads back as a character code (`0'x`) | an unquoted operator name |
| a `portray/1` hook | `print/1` and `~p` call it for each subterm | not called: `print/1` is `writeq/1` | write the term yourself |
| `last(L, X)` with `L` unbound | enumerates: `[X]`, then `[_, X]`, ... | fails | bind the list first |
| `write_canonical/1` of a term with variables | names them: `f(A,_,A)` for `f(X,Y,X)` | writes each one's own name, `f(_G0,_G1,_G0)`; both read back as the same term | `numbervars`-style names of your own |
| an error's context, in two places | a loadable module's predicate and an unknown procedure a clause body calls name a predicate, `context(Name/Arity, _)`, and the message begins `Name/Arity: ` | the context is unbound and the message has no prefix. A core builtin, a compiled-in module's row and an unknown procedure under a meta-call or a search name swipl's since 3.0.0 (through 2.16 every one was unbound) | match `error(Formal, _)` |

## Loud: an error where SWI enumerates or accepts

| what | SWI-Prolog | cocolog | what to do |
|---|---|---|---|
| `between(1, infinite, X)` | counts for ever, as `between(1, inf, X)` does | `type_error(evaluable, infinite/0)`; `between(1, inf, X)` counts for ever since 2.2.2, where `inf` became the infinity (through 2.2.1 `type_error(evaluable, inf/0)`) | `inf` |
| `set_prolog_flag/2` with a flag cocolog has not got (`float_rounding`, `user_flags`, a flag of the program's own) | sets SWI's own; an unknown one is MADE (`user_flags` is `silent`), so `set_prolog_flag(my_flag, 3)` and then `current_prolog_flag(my_flag, V)` answer `3` | `existence_error(prolog_flag, F)`. It sets `double_quotes`, `text_units`, `generate_debug_info` and swipl's four float flags, `float_overflow`, `float_zero_div`, `float_undefined` and `float_underflow`, as a goal or a directive alike (since 2.2.2; through 2.2.1 a directive only, an `existence_error` as a goal, and no float flag at all: every float was checked as swipl's defaults check it) | a global (`nb_setval/2`) for a flag of the program's own |
| `set_prolog_flag(argv, L)` and `os_argv` | change the flag | `permission_error(modify, flag, argv)`, as for `executable`, `bounded`, the integer and the float bounds, which SWI refuses too | `library(main)`'s parse of the tail, or a list of the program's own |
| a float flag set in a thread | that thread's alone: a thread starts with its creator's flags, so a later thread of `main` reads `main`'s | the thread's, and the process's default as well: a thread made after it starts with the value set last anywhere, as for `text_units` | set it in `main` before the threads are made |
| `format/2` column directives | `~t`, `~\|`, `~+` | refused by name | pad with `atom_length/2` and `tab/1` |
| a `"..."` text given to `sub_atom/5`, `sub_string/5`, `atom_concat/3` or `string_concat/3` | a string, which each of them takes | a list of codes (the default `double_quotes`, below), which each refuses as swipl's own does a list: `type_error(atom, L)`, `type_error(string, L)`, `type_error(atomic, L)` -- `sub_string(S, 0, 1, _, "#")` raises. Since 3.0.0; through 2.16 they read a list as text | `'#'`, or `:- set_prolog_flag(double_quotes, string).` |
| `discontiguous/1` and `multifile/1` called as goals | declare, as the directives do | `existence_error(procedure, discontiguous/1)`: they are directives only | the directive |
| integers | unbounded | **64-bit**, −2^63 … 2^63−1 (since 2.0.0; through 1.15.0 61-bit, and a result past them wrapped in silence): a result outside that raises `evaluation_error(int_overflow)` — `X is 2**63` and `9223372036854775807 + 1`, and `2**63 - 1` too, whose `2**63` comes first — and a float made an integer outside it as well (a NaN or an infinity is handed back as it came, as SWI's is, since 2.2.0). A literal outside it is refused, `syntax error ... integer out of range` (`9223372036854775808`, `0x8000000000000000`), and `atom_number/2` and `number_codes/2` fail for such a numeral | `library(bigint)` for anything that can get that large |
| `current_prolog_flag/2` | dozens of flags | seventeen: `argv`, `os_argv`, `executable`, `double_quotes`, `text_units`, since 2.0.0 `bounded` (`true`), `max_integer`, `min_integer`, `max_tagged_integer` and `min_tagged_integer`, and since 2.2.2 the four float flags and `float_min`, `float_max` and `float_max_integer`; any other fails, `generate_debug_info` among them, which `set_prolog_flag/2` takes | — |
| rational numbers (2.5.0) | exact, unbounded: a numerator and a denominator may be bignums | **64-bit** on both, reduced to lowest terms with a positive denominator; a result past them raises `evaluation_error(int_overflow)` where SWI bignums — `X is 1r2 ** 100`, `X is rational(1.0e308)`, `X is rdiv(9223372036854775807, 2) * 2 + 1`, `lcm(9223372036854775807, 2)`, and `rational(1.0Inf)` is `rational_overflow` while `rational(1.5NaN)` and `rationalize(1.5NaN)` are `undefined` | `library(bigint)`, or keep the values in range |
| `random/1` (function), `random_float/0`, `set_random/1`, `random_property/1` (2.5.0) | SWI's Mersenne Twister; `state(S)` is SWI's own term | the API is SWI's and the SEQUENCE is cocolog's (xoshiro128\*\*): `set_random(seed(N))` repeats within cocolog and not across systems, and the state is `'$rng_state'(A,B,C,D)`, four 32-bit words in hex — an ordinary term, but not SWI's | seed and compare within one system |
| `roundtoward/2` (2.5.0) | the C rounding mode set around libm, and swipl's own caveat that some functions ignore it | the same: the mode is set around the evaluation of its first argument and put back | — |

## Not there at all (`existence_error`)

`numbervars/3`, `freeze/2` and coroutining, `table/1` and tabling,
`flag/3`, `recorda/2` and the recorded database, `prolog_load_context/2`,
`setup_call_cleanup/3`, `absolute_file_name/3` (`/2` is there),
`sub_atom_icasechk/3`, and `name/2`, which as a builtin of the engine
would shadow a program's own `name//0` (`test/files/dcg.pl`) and so waits
on swipl's rule for redefining a system predicate.
(`print_message/2` is there since 2.16.0.)
(`predicate_property/2` is there since 1.10.28, for the program's
predicates, the constructs and the C builtins.)
`tab/2` and the other ISO stream predicates exist once
`:- use_module(library(stream)).` is loaded.
SWI 10's `cmpr/2`, `maxr/2` and `minr/2` are not here — the reference is
SWI 9.0.4's arithmetic; `random_between/3` and the rest of
`library(random)`, `library(strings)` and the stream string predicates
(`read_string/3,5`, `open_string/2`) are not either.

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
| a predicate a database-backed store cannot read | no such case: the clauses are in memory | every reader of it raises `error(resource_error(knowledge_base), context(Name/Arity, Why))` (a call, `clause/2`, `predicate_property/2`, `listing`, `abolish/1`, `retract/1`, `assertz/1`), nothing of the failed read is kept, and the next call asks again (2.11.1) | a predicate is written back whole, so a write over part of one would delete the rest; MORE.md, "The knowledge base is a seam" |
| the heap | collected, atoms too | collected since 1.8.36, inside the engines a builtin starts (`findall/3`, `forall/2`, `aggregate_all/3`, ...) since 1.9.4, and the float and string tables reclaimed in place since 1.9.6; the atom table is never reclaimed | `lib/solve-gc.cicili`, `coco_heap_gc` and `coco_tables_reclaim` |

## Where to report one

A difference that is not on this page is either a bug or a row missing here.
Either way the useful report is the goal, what SWI answers and what cocolog
answers — the shape of every row above.
