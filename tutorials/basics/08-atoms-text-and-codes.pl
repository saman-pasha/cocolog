%% BASICS 08 -- atoms, codes, and the string you have to ask for
%%
%%     ./cocolog run tutorials/basics/08-atoms-text-and-codes.pl main
%%
%% `double_quotes' DEFAULTS TO `codes', and that is the single most
%% important thing on this page. It is the ISO default, so
%%
%%     "hi"   IS   [104, 105]
%%
%% and not a string object -- unless the file says otherwise. There IS a
%% string type now (library 37 is its whole lesson); what there is not is
%% a double-quoted literal that gives you one for free.
%%
%% SO TEXT COMES IN THREE SHAPES, and you convert between them:
%%
%%     an ATOM      'hello'  -- one indivisible name, interned, cheap to
%%                  compare, and a C string underneath: it STOPS AT A NUL
%%     a CODE LIST  "hello"  -- a list of integers, one per BYTE, which
%%                  you can walk with ordinary list predicates
%%     a STRING     -- a distinct type, from atom_string/2 or its kin, or
%%                  from "..." in a file that set the flag. It carries a
%%                  NUL, which is exactly what an atom cannot.
%%
%% THE FLAG TAKES ALL FOUR OF SWI'S VALUES -- codes, chars, atom, string --
%% and `:- set_prolog_flag(double_quotes, string).' at the head of a file
%% makes every "..." in it a string. It takes effect for the REST OF THE
%% FILE, not for the directive's own term, which is SWI's order too.
%%
%% THIS PAGE STAYS ON THE DEFAULT, and says so rather than setting the
%% flag, because the default is what every file that says nothing gets --
%% including every one of the other ten lessons here.
%%
%% BYTES, NOT CHARACTERS. cocolog is byte-oriented: `atom_length/2' counts
%% bytes, so a UTF-8 character outside ASCII counts as its byte length.
%% Nothing here decodes UTF-8, which is also why UTF-8 passes through
%% every library in one piece.
%%
%% WHICH TO USE: atoms for names and keys, code lists for anything you are
%% going to take apart, a string when you need text that survives a NUL or
%% when you are talking to something that already speaks SWI's strings. A
%% DCG (basics 10) always parses codes.

main :-
    format("~n-- \"hi\" is a LIST, and that is not a surprise once you know~n"),
    Codes = "hi",
    must('"hi"', Codes, [104, 105]),
    ( is_list(Codes) -> K = a_list ; K = something_else ),
    must('is it a list', K, a_list),
    ( string(Codes) -> S0 = a_string ; S0 = not_a_string ),
    must('is it a string', S0, not_a_string),
    format("   The flag DEFAULTS to codes, so a bare \"hi\" is a list here.~n"),
    format("   `:- set_prolog_flag(double_quotes, string).' changes that~n"),
    format("   for the rest of a file. This one does not set it.~n"),

    format("~n-- the third shape: a STRING, which you have to ask for~n"),
    atom_string(hi, Str),
    ( string(Str) -> S1 = a_string ; S1 = not_a_string ),
    must('atom_string/2 makes one', S1, a_string),
    ( atom(Str) -> S2 = also_an_atom ; S2 = not_an_atom ),
    must('and it is NOT an atom', S2, not_an_atom),
    ( Str == hi -> S3 = same ; S3 = different ),
    must('nor equal to the atom it came from', S3, different),
    %% THE NUL IS THE WHOLE REASON THE TYPE EXISTS. An atom is a
    %% NUL-terminated name in a table, so the same three bytes are a
    %% one-character atom and a three-character string.
    string_codes(NulStr, [0'a, 0, 0'b]),
    string_length(NulStr, NulLen),
    must('a string carries a NUL', NulLen, 3),
    atom_codes(NulAtom, [0'a, 0, 0'b]),
    atom_length(NulAtom, AtomLen),
    must('  where an atom of the same bytes stops', AtomLen, 1),

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
