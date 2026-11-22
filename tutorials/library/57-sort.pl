%% LIBRARY 57 -- library(sort): predsort/3, a sort by your own order
%%
%%     ./cocolog run tutorials/library/57-sort.pl main
%%
%% NO IMPORT NEEDED. swipl's own file, vendored unedited in lib/swipl, and
%% read the first time predsort/3 or locale_sort/2 is called, as swipl's
%% autoloader reads it. `:- use_module(library(sort)).' loads it too, and
%% is the line to write in a program with threads or green tasks: a first
%% call made while another thread runs an engine is an unknown procedure.
%%
%% `predsort(Compare, List, Sorted)' SORTS BY A PREDICATE. msort/2 and
%% sort/2 order by the standard order of terms; predsort/3 calls
%% `call(Compare, Order, A, B)' for each pair it merges, and Compare
%% answers `<', `>' or `='. What it answers `=' for counts as ONE element:
%% the second is dropped, as sort/2 drops a duplicate.
%%
%% THREE THINGS TO KNOW:
%%   - Compare is called with the ORDER FIRST: compare/3's own shape, so
%%     `predsort(compare, L, S)' is sort/2.
%%   - Compare must answer once. A second answer is predsort/3's second
%%     answer, a different list: wrap Compare's body in once/1, or end it
%%     with a cut, if it could answer twice.
%%   - A list that is no proper list is an error naming the list as a
%%     TYPE, existence_error(type, L): swipl's code calls must_be(L, list)
%%     with its arguments the other way round, and cocolog runs that code.
%%
%% `locale_sort(Atoms, Sorted)' sorts atoms by the locale's collation.
%% cocolog has no locales: the key is the text itself, the C locale's
%% order, capitals before small letters.

%% a country, its capital and its population in millions
country(france, paris, 68).
country(japan, tokyo, 125).
country(chile, santiago, 19).
country(kenya, nairobi, 55).

%% the order of two countries by their population, the largest first
by_people(Order, C1, C2) :-
    country(C1, _, P1),
    country(C2, _, P2),
    compare(Order, P2, P1).

%% the order of two words by their length: words of one length are `='
by_length(Order, A, B) :-
    atom_length(A, LA),
    atom_length(B, LB),
    compare(Order, LA, LB).

%% the order of two pairs by their keys alone
by_key(Order, K1-_, K2-_) :- compare(Order, K1, K2).

%% a comparator that answers twice: `<', then `>'
either(<, _, _).
either(>, _, _).

main :-
    format("~n-- predsort(compare, ...) is sort/2~n"),
    predsort(compare, [c, a, b, a], S1),
    must('compare/3 as the order, a duplicate dropped', S1, [a, b, c]),

    format("~n-- an order of your own~n"),
    findall(C, country(C, _, _), Cs),
    predsort(by_people, Cs, S2),
    must('the countries by population, the largest first', S2,
         [japan, france, kenya, chile]),

    format("~n-- `=' DROPS AN ELEMENT: only one word of each length stays~n"),
    predsort(by_length, [tree, oak, leaf, ash, branch], S3),
    must('one word of each length', S3, [oak, tree, branch]),

    format("~n-- keyed pairs: the first of each key stays~n"),
    predsort(by_key, [2-b, 1-a, 2-c, 1-d], S4),
    must('one pair a key', S4, [1-a, 2-b]),

    format("~n-- a comparator that answers twice gives two sorts~n"),
    findall(S, predsort(either, [x, y], S), Ss),
    must('both answers', Ss, [[x, y], [y, x]]),
    predsort([O, A, B]>>once(either(O, A, B)), [x, y], S5),
    must('once/1 around it keeps the first', S5, [x, y]),

    format("~n-- what predsort/3 refuses~n"),
    catch(predsort(compare, [a|b], _), error(E1, _), true),
    must('a list that is no list, named as a type', E1, existence_error(type, [a|b])),
    catch(predsort(no_such_order, [a, b], _), error(E2, _), true),
    must('a comparator nothing defines', E2,
         existence_error(procedure, no_such_order/3)),

    format("~n-- locale_sort/2, and the key it sorts by~n"),
    locale_sort([pear, 'Apple', banana, apple], S6),
    must('the C order: capitals first', S6, ['Apple', apple, banana, pear]),
    collation_key(apple, K),
    ( string(K) -> Kind = string ; Kind = other ),
    must('the key is a string', Kind, string),
    string_to_atom(K, KA),
    must('and its text is the atom''s', KA, apple),

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
