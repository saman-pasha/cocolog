%% LIBRARY 04 -- library(builtins): the ISO core, and format/2
%%
%%     ./cocolog run tutorials/library/04-builtins.pl main
%%
%% TIER 1: no import.
%%
%% NOT A LIBRARY ANYBODY IMPORTS ON PURPOSE. It is the ISO core cocolog
%% was missing once the engine existed -- `findall/3' and its family,
%% `between/3', the atom and term predicates, `clause/2',
%% `current_predicate/1', `format/1,2,3', `code_type/2', `must_be/2'. You
%% will call these constantly and never name the library.
%%
%% THIRTY-ONE IN C AND TWELVE IN PROLOG, and the split follows the same
%% rule as everywhere: needs the outside world or the whole list at once
%% goes in C; nondeterministic goes in clauses; both means a
%% `$'-prefixed C primitive with a clause around it -- which is how
%% `length/2' is a single C walk for a proper list and still generative
%% for `length(L, 3)'.
%%
%% ONE LIMITATION WORTH KNOWING UP FRONT: `format/2' has no COLUMN
%% directives. `~t', `~|' and `~+' measure what has been written since the
%% last column stop, which is a second pass over the buffer this does not
%% make. They RAISE an error naming themselves rather than being quietly
%% ignored -- dropping them turns a table into a run-on line and blames
%% the program.

:- dynamic sample/1.

main :-
    format("~n-- format/2, and the directives that are here~n"),
    format("   ~~w writes ~w, ~~q writes ~q -- quoting is the difference~n",
           ['an atom', 'an atom']),
    format(atom(A1), "~w-~w", [a, b]),
    must('format/3 into an atom', A1, 'a-b'),
    format(codes(C1), "~w", [hi]),
    must('...or into codes', C1, [104, 105]),
    format(atom(A2), "~a", [plain]),
    must('~~a writes an atom without quotes', A2, plain),
    format(atom(A3), "~d", [42]),
    must('~~d writes an integer', A3, '42'),
    format(atom(A4), "~s", [[104, 105]]),
    must('~~s writes a CODE LIST as text', A4, hi),
    format(atom(A5), "a~nb", []),
    must('~~n is a newline', A5, 'a\nb'),
    format(atom(A6), "100~~", []),
    must('~~~~ is a literal tilde', A6, '100~'),

    format("~n-- and the ones that are NOT, loudly~n"),
    catch(format(atom(_), "~t~20|x", []), error(cocolog_error(Fmt), _), true),
    ( sub_atom(Fmt, _, _, _, 'no column directives') -> F = refused ; F = Fmt ),
    must('a column directive', F, refused),
    format("   ...and the message NAMES all three of them, so the fix is~n"),
    format("   in the error rather than in the manual.~n"),

    format("~n-- between/3 is the loop, and it GENERATES~n"),
    findall(N, between(1, 5, N), Ns),
    must('between(1, 5, N)', Ns, [1, 2, 3, 4, 5]),
    ( between(1, 10, 7) -> In = yes ; In = no ),
    must('...and tests, with the third bound', In, yes),

    format("~n-- term inspection: functor, arg, =..~n"),
    functor(point(1, 2), Name, Arity),
    must('functor/3 takes a term apart', Name/Arity, point/2),
    functor(T, person, 2),
    %% CHECKED BY SHAPE, not by `=='. Two distinct fresh variables are
    %% never `==' -- `person(_, _) == person(_, _)' is FALSE -- so a
    %% lesson that compared the term against a written-out one would fail
    %% for the wrong reason. Ask what it IS instead.
    functor(T, TN, TA),
    must('...and builds a blank one', TN/TA, person/2),
    arg(1, T, Blank),
    ( var(Blank) -> BV = a_fresh_variable ; BV = Blank ),
    must('whose arguments are holes', BV, a_fresh_variable),
    arg(2, point(1, 2), Second),
    must('arg/3', Second, 2),
    point(1, 2) =.. Univ,
    must('=.. to a list', Univ, [point, 1, 2]),
    Rebuilt =.. [point, 3, 4],
    must('...and back', Rebuilt, point(3, 4)),

    format("~n-- the type tests, which never raise~n"),
    check(var(_), 'var(_)', true),
    check(atom(foo), 'atom(foo)', true),
    check(number(1.5), 'number(1.5)', true),
    check(integer(1.5), 'integer(1.5)', false),
    check(atomic(foo), 'atomic(foo)', true),
    check(compound(f(x)), 'compound(f(x))', true),
    check(is_list([1, 2]), 'is_list([1,2])', true),
    check(callable(foo), 'callable(foo)', true),
    check(ground(f(x)), 'ground(f(x))', true),
    check(ground(f(_)), 'ground(f(_))', false),

    format("~n-- copy_term/2: a fresh copy with fresh variables~n"),
    copy_term(f(X, X, Y), Copy),
    Copy = f(1, One, _),
    must('the shared variable is still shared', One, 1),
    ( var(X), var(Y) -> Orig = untouched ; Orig = bound ),
    must('and the original is untouched', Orig, untouched),

    format("~n-- the standard order, and compare/3~n"),
    msort([foo, 2, "s", f(x), _Var, 1.0], Sorted),
    length(Sorted, SLen),
    must('six terms sort without complaint', SLen, 6),
    compare(Order, 1, 2),
    must('compare/3', Order, <),
    format("   The order is Var < Number < Atom < String < Compound.~n"),

    format("~n-- clause/2 and current_predicate/1: a program reading itself~n"),
    assertz(sample(1)), assertz(sample(2)),
    findall(H, clause(sample(H), true), Heads),
    must('clause/2', Heads, [1, 2]),
    ( current_predicate(sample/1) -> P = known ; P = unknown ),
    must('current_predicate/1', P, known),
    retractall(sample(_)),

    format("~n-- must_be/2 and code_type/2~n"),
    catch(must_be(integer, foo), error(MB, _), true),
    must('must_be(integer, foo)', MB, type_error(integer, foo)),
    ( code_type(0'7, digit) -> CT = yes ; CT = no ),
    must('code_type(0''7, digit)', CT, yes),
    format("~ndone~n").

check(Goal, Label, Want) :-
    ( call(Goal) -> Got = true ; Got = false ),
    must(Label, Got, Want).

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
