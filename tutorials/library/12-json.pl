%% LIBRARY 12 -- library(json): a term as JSON, and JSON as a term
%%
%%     ./cocolog run tutorials/library/12-json.pl main
%%
%% TIER 2: needs `use_module(library(json))', and it is on the library
%% path as `library/json.pl'. Clauses only -- there is no C in it.
%%
%% BOTH DIRECTIONS ARE DCGs, which is the shape everything in this
%% repository that touches a format uses: a grammar that emits is the
%% format written down, readable a clause at a time.
%%
%%     json_codes(+Term, -Codes)      json_parse(+Text, -Term)
%%     json_atom(+Term, -Atom)        json_parse(+Codes, -Term, -Rest)
%%     json_write(+Term)              json_input(-Term)//
%%     json_value(+Term)//
%%
%% THE TERM:
%%     json([Key-Value, ...])   an object (`=' and `:' pairs accepted too)
%%     [E1, E2, ...]            an array
%%     @(true) @(false) @(null) the three literals
%%     a number                 a number
%%     an atom                  a string
%%     str(X)                   a string, from an atom, number or CODES
%%
%% A CODE LIST IS A LIST, AND `str/1' IS THE WAY OUT. cocolog has no
%% string type -- `"hi"' IS `[104, 105]' -- so nothing in the term says
%% which you meant. Guessing turns a JSON array of byte values into a
%% word. A bare list is always an array.
%%
%% IT THROWS RATHER THAN GUESSES: an unbound variable is not `null',
%% `foo(1)' is not `"foo(1)"', `@(maybe)' is not a literal, and an integer
%% past 64 bits is refused rather than wrapped.

:- use_module(library(json)).

main :-
    format("~n-- writing~n"),
    json_atom(json([name-'Ada', n-42, ok- @(true)]), A1),
    must('an object', A1, '{"name":"Ada","n":42,"ok":true}'),
    json_atom([1, 2.5, @(null)], A2),
    must('an array', A2, '[1,2.5,null]'),
    json_atom(json([]), A3), must('an empty object', A3, '{}'),
    json_atom([], A4), must('an empty array', A4, '[]'),

    format("~n-- key order is PRESERVED, because diffs are not unordered~n"),
    json_atom(json([b-1, a-2]), A5),
    must('written in the order given', A5, '{"b":1,"a":2}'),

    format("~n-- a code list is an ARRAY; str/1 is how you mean text~n"),
    json_atom("hi", A6),
    must('json_atom("hi", A)', A6, '[104,105]'),
    json_atom(str("hi"), A7),
    must('json_atom(str("hi"), A)', A7, '"hi"'),

    format("~n-- escaping, which is where a serialiser is silently wrong~n"),
    atom_codes(QB, [0'a, 0'", 0'b, 92, 0'c]),
    json_atom(json([k-QB]), A8),
    atom_codes(A8, A8Codes),
    %% CHECKED AS CODES, because writing the expected answer as a quoted
    %% atom means escaping backslashes twice -- once for Prolog and once
    %% for the JSON -- and a lesson nobody can read is not a lesson.
    %% {"k":"a\"b\\c"}
    must('a quote and a backslash', A8Codes,
         [0'{, 0'", 0'k, 0'", 0':, 0'", 0'a, 92, 0'", 0'b, 92, 92, 0'c, 0'", 0'}]),
    atom_codes(Ctrl, [0'a, 9, 10]),
    json_atom(json([k-Ctrl]), A9),
    must('tab and newline', A9, '{"k":"a\\t\\n"}'),
    atom_codes(Utf, [0xC3, 0xA9]),
    json_atom(json([k-Utf]), A10),
    atom_length(A10, L10),
    must('a UTF-8 byte pair passes through untouched', L10, 10),

    format("~n-- indenting, when a human has to read it~n"),
    json_atom(json([a-[1]]), Pretty, [indent(2)]),
    atomic_list_concat(Lines, '\n', Pretty),
    length(Lines, LineCount),
    must('indent(2) breaks it up', LineCount, 5),

    format("~n-- reading~n"),
    json_parse('{"a":1,"b":[true,null]}', T1),
    must('json_parse/2', T1, json([a-1, b-[@(true), @(null)]])),
    json_parse('"text"', T2),
    must('a string comes back as an ATOM', T2, text),
    json_parse('  [1 , 2]  ', T3),
    must('whitespace between tokens is skipped', T3, [1, 2]),
    %% BUILT FROM CODES, not written as a quoted atom. The document is
    %% the eight characters  " \ u 0 0 e 9 "  and spelling that inside
    %% Prolog quotes needs a backslash escaped for the reader as well as
    %% for JSON. Two levels of escaping in a teaching file is one too
    %% many; 92 is a backslash and everybody can see it.
    atom_codes(Esc, [0'", 92, 0'u, 0'0, 0'0, 0'e, 0'9, 0'"]),
    json_parse(Esc, T4),
    atom_codes(T4, T4Codes),
    must('a u-escape becomes UTF-8', T4Codes, [195, 169]),
    atom_codes(Pair, [0'", 92, 0'u, 0'd, 0'8, 0'3, 0'd,
                            92, 0'u, 0'd, 0'e, 0'0, 0'0, 0'"]),
    json_parse(Pair, T5),
    atom_codes(T5, T5Codes),
    must('...and a surrogate PAIR becomes one character', T5Codes,
         [240, 159, 152, 128]),
    format("   A u-escape names a UTF-16 CODE UNIT, not a character, so~n"),
    format("   anything above U+FFFF arrives as a high unit and a low one~n"),
    format("   and the reader has to put them together. A lone surrogate~n"),
    format("   is an error: there is no UTF-8 for half a character.~n"),

    format("~n-- the streaming entry point, for a socket~n"),
    json_parse("{\"a\":1}rest", T6, Rest),
    atom_codes(RestAtom, Rest),
    must('json_parse/3 hands back what was not this value', T6-RestAtom,
         json([a-1])-rest),

    format("~n-- and it is RFC 8259, including the parts people leave out~n"),
    refuses('01', 'a leading zero'),
    refuses('[1,]', 'a trailing comma'),
    refuses('{"a" 1}', 'a missing colon'),
    refuses('12345678901234567890', 'an integer past 64 bits'),
    format("   That last one matters most: `number_codes/2' answers -1~n"),
    format("   for a twenty-digit literal and complains about nothing, so~n"),
    format("   the parser writes the digits back and compares. A silently~n"),
    format("   wrong balance is the worst thing a JSON parser can do.~n"),

    format("~n-- THE ROUND TRIP, which is the real check~n"),
    Doc = json([n-1, s-'a"b', l-[1, @(null)], o-json([k- @(true)])]),
    json_atom(Doc, Once),
    json_parse(Once, Back),
    json_atom(Back, Twice),
    must('write, read, write again', Once, Twice),
    must('...and the term survives too', Back, Doc),
    format("   A reader and a writer that disagree about the same bytes~n"),
    format("   are worse than either alone, and no amount of~n"),
    format("   hand-written expectations on each half finds it.~n~n"),
    format("done~n").

refuses(Text, Label) :-
    (   catch(json_parse(Text, _), error(syntax_error(_), _), true)
    ->  R = refused
    ;   R = accepted
    ),
    must(Label, R, refused).

%% ---- the two helpers every lesson here carries ------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth six duplicated lines; a tutorial that needs a support
%% library beside it is a tutorial that stops working the moment it is
%% moved.
show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers. A tutorial that prints whatever it computed is a tutorial
%% that goes quietly wrong the day the language changes underneath it.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
