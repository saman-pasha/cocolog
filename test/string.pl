%% The string type: SWI's, as a cell tag in the engine.
%%
%% WHAT IS BEING CHECKED IS THAT IT IS A TYPE, not that a handful of
%% predicates answer. A string that were secretly an atom would pass every
%% conversion test and fail the three that matter: it must not BE an atom, it
%% must carry a NUL, and it must sit between atom and compound in the standard
%% order. Those three are the reason SWI has the type and the reason cocolog
%% now does.
%%
%%     cocolog -s test/string.pl        from the checkout root
%%
%% ONE PROCESS FOR THIRTY-NINE CHECKS. This was test/string.sh, forty
%% cocolog invocations at ~120 ms each, 4.9 s for the case; it is under a
%% second now. The questions are the same and the answers are read as
%% terms rather than grepped out of a pipe. The double_quotes checks that
%% need a FILE still take a child each, because what they pin is what
%% `cocolog run FILE main' makes of that file's own "ab" -- a one-goal
%% query can never see its own flag change, and neither can a clause that
%% was read before the flag was.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    types, nul, order, conversions, splitting, substrings, code_lists,
    writer, flag_files(D), flag_modules(D), char_lists, refused(D),
    shl(['rm -rf ', D]),
    checks_done.

%% ---- it is a TYPE, not an atom in disguise -------------------------------
types :-
    yes_no((atom_string(a, S), string(S)), A1),
    check('string/1 is true of one', A1, yes),
    yes_no(string(a), A2),
    check('and false of the atom', A2, no),
    yes_no((atom_string(a, S3), atom(S3)), A3),
    check('a string is not an atom', A3, no),
    yes_no((atom_string(a, S4), is_list(S4)), A4),
    check('nor a list', A4, no),
    yes_no((atom_string(a, S5), S5 == a), A5),
    check('nor equal to its atom', A5, no).

%% ---- the NUL, which is the whole reason the type exists -------------------
%%
%% The same three bytes: a 3-character STRING and a 1-character ATOM, because
%% an atom is a NUL-terminated name in a table and stops at the first one.
nul :-
    answer((string_codes(S1, [0'a, 0, 0'b]), string_length(S1, N1)), N1, G1),
    check('a string carries a NUL', G1, 3),
    answer((atom_codes(A2, [0'a, 0, 0'b]), atom_length(A2, N2)), N2, G2),
    check('the same bytes as an atom stop', G2, 1),
    answer((string_codes(S3, [0'a, 0, 0'b]), string_codes(S3, C3), length(C3, N3)), N3, G3),
    check('and the codes come back whole', G3, 3).

%% ---- the standard order is SWI's ------------------------------------------
order :-
    yes_no((atom_string(a, S1), compare(<, a, S1)), A1),
    check('atom < string', A1, yes),
    yes_no((atom_string(a, S2), compare(<, S2, f(1))), A2),
    check('string < compound', A2, yes),
    yes_no((atom_string(a, S3), compare(<, 1, S3)), A3),
    check('number < string', A3, yes),
    yes_no((atom_string(x, X), atom_string(x, Y), X == Y), A4),
    check('== is by bytes, not by identity', A4, yes).

%% ---- the conversions -------------------------------------------------------
conversions :-
    answer((atom_string(hello, S1), atom_string(A1, S1)), A1, G1),
    check('atom_string both ways', G1, hello),
    answer(number_string(N2, "3.5"), N2, G2),
    check('number_string parses', G2, 3.5),
    answer((string_concat("a", "b", S3), atom_string(A3, S3)), A3, G3),
    check('string_concat', G3, ab),
    answer((string_upper("aBc", S4), atom_string(A4, S4)), A4, G4),
    check('string_upper', G4, 'ABC'),
    yes_no((term_string(T5, "g(2)"), T5 = g(2)), A5),
    check('term_string reads back', A5, yes).

%% ---- split_string, including the two rules everybody trips over -----------
splitting :-
    answer((split_string("a,b,c", ",", "", P1), length(P1, N1)), N1, G1),
    check('split_string counts the fields', G1, 3),
    answer((split_string("a,,b", ",", "", P2), length(P2, N2)), N2, G2),
    check('an empty field is a field', G2, 3),
    answer((split_string("abc", "", "", P3), length(P3, N3)), N3, G3),
    check('no separators means one field', G3, 1),
    answer((split_string("  ab  ", "", " ", [S4]), atom_string(A4, S4)), A4, G4),
    check('padding is stripped', G4, ab).

%% ---- sub_string/5 backtracks, which is why it is a clause ------------------
substrings :-
    answer((findall(B-L, sub_string("hello", B, L, _, _), All), length(All, N1)), N1, G1),
    check('sub_string enumerates', G1, 21),
    answer(sub_string("hello", B2, _, _, "ell"), B2, G2),
    check('and finds a known substring', G2, 1).

%% ---- A CODE LIST IS TEXT, which is SWI's rule and matters more here --------
%%
%% `double_quotes' is `codes', so "hello" IS [104,101,108,108,111]. Before
%% these accepted a code list, string_length("hello", N) answered 21 -- the
%% length of the list written out -- which is a silent wrong answer.
code_lists :-
    answer(string_length("hello", N1), N1, G1),
    check('a code list is text', G1, 5),
    %% and what has NOT changed
    yes_no(string("abc"), A2),
    check('a double-quoted literal is codes', A2, no).

%% ---- the writer ------------------------------------------------------------
writer :-
    answer((sub_string("hello", 1, 3, _, S1), format(atom(A1), "~q", [S1])), A1, G1),
    check('quoted, it writes in quotes', G1, '"ell"'),
    answer((sub_string("hello", 1, 3, _, S2), format(atom(A2), "~w", [S2])), A2, G2),
    check('unquoted, it writes its text', G2, ell).

%% ---- double_quotes, all four of SWI's values -------------------------------
%%
%% THESE NEED FILES, not a goal. The flag takes effect for the REST OF THE
%% CONSULT and not for the directive's own term -- the term is already read by
%% the time the directive runs -- so a one-goal query can never see its own
%% flag change, and a clause of this file was read under `codes' before any
%% of these ran. That is SWI's order too.
%%
%% Each file asks what its own "ab" turned out to BE, and reads the flag back
%% through current_prolog_flag/2, so a flag that were set without changing the
%% reader (or a reader changed without the flag following) fails here. Each
%% is a child `cocolog run FILE main', because the claim is about a consult.
flag_files(D) :-
    dq(D, codes, G1),  check('codes is the default', G1, answer(codes/codes)),
    dq(D, chars, G2),  check('chars makes one-char atoms', G2, answer(chars/chars)),
    dq(D, atom, G3),   check('atom makes an atom', G3, answer(atom/atom)),
    dq(D, string, G4), check('string makes a string', G4, answer(string/string)),
    %% A FILE WITH NO DIRECTIVE IS UNCHANGED, which is what makes the default
    %% a default rather than whatever the last file to run happened to ask for.
    atom_concat(D, '/plain.pl', Plain),
    fixture(Plain,
            [ 'main :- X = "ab",',
              '        ( string(X) -> T = string ; is_list(X) -> T = codes ; T = other ),',
              '        format("answer(~w)~n", [T]).' ]),
    sh_join(['run ', Plain, ' main'], Args5),
    cocolog_answer(Args5, G5),
    check('a file that asks for nothing', G5, answer(codes)).

dq(D, Value, Got) :-
    sh_join([D, '/dq-', Value, '.pl'], File),
    sh_join([':- set_prolog_flag(double_quotes, ', Value, ').'], Directive),
    fixture(File,
            [ Directive,
              'main :- X = "ab",',
              '        ( string(X) -> T = string ; atom(X) -> T = atom',
              '        ; X = [a,b] -> T = chars ; is_list(X) -> T = codes ; T = other ),',
              '        current_prolog_flag(double_quotes, F),',
              '        format("answer(~w/~w)~n", [T, F]).' ]),
    sh_join(['run ', File, ' main'], Args),
    cocolog_answer(Args, Got).

%% THE FLAG IS PER-MACHINE AND A MODULE LOAD PUTS IT BACK. A module that
%% sets it gets what it asked for -- its own "ab" is a string -- and the
%% goal that loaded it does not: coco_module_load (lib/module.cicili) forces
%% `codes' across the consult and restores the caller's value after, so the
%% vendored SWI libraries in lib/swipl, written for codes, read their own
%% text right whatever a program set before them. The third check is the one
%% the .sh never made and the one that found the guard in the wrong place:
%% a library loaded AS A GOAL after such a module used to fail with "its
%% clauses would not consult", because the guard sat on the ask-time hook
%% only and a runtime use_module never passed it.
flag_modules(D) :-
    atom_concat(D, '/mod.pl', Mod),
    fixture(Mod,
            [ ':- set_prolog_flag(double_quotes, string).',
              'mine(X) :- X = "ab".' ]),
    yes_no((use_module(Mod), mine(X), string(X)), A1),
    check('a module got what it asked for', A1, yes),
    answer(current_prolog_flag(double_quotes, F2), F2, G2),
    check('and the goal that loaded it kept its own flag', G2, codes),
    answer((use_module(library(json)), json_atom(json([a-1]), J)), J, G3),
    check('so a library loaded after it still reads codes', G3, '{"a":1}').

%% A CHAR LIST IS TEXT, which is what makes the flag usable at all rather than
%% merely settable. Under `chars' a file's own format strings are lists of
%% one-character atoms, and BOTH text seams took only codes: format/2 raised
%% type_error(text, [a,n,s,...]) from the format call itself, and every string
%% builtin fell through to writing the term out -- string_length("ab", N)
%% answering 5, the same silent wrong answer as the code-list case above.
char_lists :-
    answer(format(atom(A1), ['~', w], [ab]), A1, G1),
    check('a char list is text to format', G1, ab),
    answer(string_length([a, b], N2), N2, G2),
    check('and to the string builtins', G2, 2),
    answer(string_length([a, 0'b], N3), N3, G3),
    check('a mixed list still is', G3, 2).

%% A VALUE THAT IS NOT ONE OF THE FOUR IS REFUSED BY NAME, and the refusal is
%% reported where the file is read -- a flag nodded at and not honoured makes
%% every "..." in the file mean something other than it says. A child, because
%% the report is on the loader's stderr.
refused(D) :-
    atom_concat(D, '/bad.pl', Bad),
    fixture(Bad,
            [ ':- set_prolog_flag(double_quotes, banana).',
              'main :- true.' ]),
    sh_join(['run ', Bad, ' main'], Args),
    cocolog_out(Args, Out),
    (   re_match('takes codes, chars, atom or string', Out) -> R = yes ; R = no ),
    check('a fifth value is refused', R, yes).
