%% BASICS 08 -- atoms, codes, and the text that is not a string
%%
%%     ./cocolog run tutorials/basics/08-atoms-text-and-codes.pl main
%%
%% COCOLOG HAS NO STRING TYPE, and that is the single most important thing
%% on this page. `double_quotes' is `codes' -- the ISO default -- so
%%
%%     "hi"   IS   [104, 105]
%%
%% not a string object. There is no `string/1' that answers true of
%% anything (the one that exists always fails, on purpose, so that
%% vendored SWI library code takes its code-list branch).
%%
%% SO TEXT COMES IN TWO SHAPES and you convert between them:
%%
%%     an ATOM      'hello'  -- one indivisible name, interned, cheap to
%%                  compare, and a C string underneath: it STOPS AT A NUL
%%     a CODE LIST  "hello"  -- a list of integers, one per BYTE, which
%%                  you can walk with ordinary list predicates
%%
%% BYTES, NOT CHARACTERS. cocolog is byte-oriented: `atom_length/2' counts
%% bytes, so a UTF-8 character outside ASCII counts as its byte length.
%% Nothing here decodes UTF-8, which is also why UTF-8 passes through
%% every library in one piece.
%%
%% WHICH TO USE: atoms for names and keys, code lists for anything you are
%% going to take apart. A DCG (basics 10) always parses codes.

main :-
    format("~n-- \"hi\" is a LIST, and that is not a surprise once you know~n"),
    Codes = "hi",
    must('"hi"', Codes, [104, 105]),
    ( is_list(Codes) -> K = a_list ; K = something_else ),
    must('is it a list', K, a_list),

    format("~n-- converting between the two shapes~n"),
    atom_codes(hello, HCodes),
    must('atom_codes(hello, C)', HCodes, [104, 101, 108, 108, 111]),
    atom_codes(Back, [104, 105]),
    must('and back again', Back, hi),
    atom_chars(hello, Chars),
    must('atom_chars gives one-char ATOMS', Chars, [h, e, l, l, o]),
    number_codes(42, NCodes),
    atom_codes(NAtom, NCodes),
    must('number_codes(42, C)', NAtom, '42'),
    atom_number('42', Num),
    must('atom_number the other way', Num, 42),

    format("~n-- joining and splitting~n"),
    atom_concat(hello, ' world', Greeting),
    must('atom_concat/3', Greeting, 'hello world'),
    atomic_list_concat([a, b, c], Joined),
    must('atomic_list_concat/2', Joined, abc),
    atomic_list_concat([a, b, c], '-', Dashed),
    must('with a separator', Dashed, 'a-b-c'),
    atomic_list_concat(Parts, '-', 'a-b-c'),
    must('and SPLITTING with the same predicate', Parts, [a, b, c]),

    format("~n-- atom_concat/3 runs backwards -- but ONE WAY AT A TIME~n"),
    atom_concat(Front, bc, abc),
    must('what comes before bc', Front, a),
    atom_concat(a, Rest, abc),
    must('what comes after a', Rest, bc),
    catch(atom_concat(_, _, abc), error(Both, _), true),
    must('with BOTH ends unknown', Both, instantiation_error),
    format("   `append/3' enumerates every split because it is CLAUSES and~n"),
    format("   the engine gives it choice points. atom_concat/3 is a C~n"),
    format("   builtin, and every builtin here answers once. So it solves~n"),
    format("   for either end and refuses to guess at both.~n"),

    format("~n-- sub_atom/5 is the general one: five arguments, many uses~n"),
    sub_atom(hello, 0, 2, _, Prefix),
    must('the first two characters', Prefix, he),
    ( sub_atom(hello, _, _, _, ell) -> C = contains ; C = missing ),
    must('does hello contain ell', C, contains),
    sub_atom(hello, Before, 3, 0, Suffix),
    must('the last three', Suffix, llo),
    must('and how many came before them', Before, 2),

    format("~n-- length is in BYTES, which matters outside ASCII~n"),
    atom_length(hello, Len),
    must('atom_length(hello)', Len, 5),
    atom_codes(Eacute, [0xC3, 0xA9]),
    atom_length(Eacute, ELen),
    must('one UTF-8 e-acute, in bytes', ELen, 2),

    format("~n-- case, and char_code~n"),
    upcase_atom(hello, Up),
    must('upcase_atom', Up, 'HELLO'),
    downcase_atom('HeLLo', Down),
    must('downcase_atom', Down, hello),
    char_code(a, Code),
    must('char_code(a, X)', Code, 97),

    format("~n-- and a term is text too, both ways~n"),
    %% THE VARIABLE'S NAME IS NOT ITS IDENTITY. A written variable comes
    %% out as `_G' and a number the machine chose, and that number depends
    %% on everything the process did before -- so a lesson that pinned it
    %% would fail the day a line was added above. Check the SHAPE instead.
    term_to_atom(foo(X1, bar), TA),
    ( sub_atom(TA, 0, 4, _, 'foo(') -> W1 = starts_right ; W1 = TA ),
    must('term_to_atom writes it', W1, starts_right),
    ( sub_atom(TA, _, _, _, ',bar)') -> W2 = ends_right ; W2 = TA ),
    must('with the rest of the term', W2, ends_right),
    term_to_atom(Read, 'point(1,2)'),
    must('and reads one back', Read, point(1, 2)),
    ( var(X1) -> V = untouched ; V = bound ),
    must('the variable in the written term', V, untouched),
    format("~ndone~n").

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
