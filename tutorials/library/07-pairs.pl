%% LIBRARY 07 -- library(pairs): Key-Value, and the sorting idiom
%%
%%     ./cocolog run tutorials/library/07-pairs.pl main
%%
%% TIER 1: no import. SWI's own file, vendored unedited.
%%
%% FIVE PREDICATES AND ONE IDEA. `-' is just an operator, so `a-1' is the
%% compound `-(a, 1)' and a "pair" is a convention rather than a type.
%% What this library gives you is the three ways to take a LIST of them
%% apart and put it back together.
%%
%% THE IDIOM WORTH LEARNING IS SORT-BY-KEY. The standard order compares a
%% compound by arity, then name, then arguments LEFT TO RIGHT -- so
%% sorting a list of `Key-Value' pairs sorts by key, and ties break on the
%% value. Which means:
%%
%%     pairs_keys_values(Pairs, Keys, Values)   build the pairs
%%     keysort(Pairs, Sorted)                   sort by key, STABLY
%%     pairs_values(Sorted, InKeyOrder)         throw the keys away
%%
%% is how you sort anything by a computed key, in three lines, with no
%% comparator to write. `keysort/2' is stable, which is the property that
%% makes it composable: sort by the minor key first, then the major.

main :-
    format("~n-- taking a list of pairs apart, and putting it back~n"),
    pairs_keys_values(P0, [a, b, c], [1, 2, 3]),
    must('pairs_keys_values/3 builds', P0, [a-1, b-2, c-3]),
    pairs_keys_values([x-9, y-8], Ks, Vs),
    must('...and splits, the same predicate', Ks-Vs, [x, y]-[9, 8]),
    pairs_keys([a-1, b-2], JustKeys),
    must('pairs_keys/2', JustKeys, [a, b]),
    pairs_values([a-1, b-2], JustValues),
    must('pairs_values/2', JustValues, [1, 2]),

    format("~n-- keysort/2 sorts by key and keeps duplicates~n"),
    keysort([c-3, a-1, b-2, a-0], Sorted),
    must('keysort/2', Sorted, [a-1, a-0, b-2, c-3]),
    format("   Note a-1 still comes before a-0: keysort is STABLE, so~n"),
    format("   equal keys stay in the order they arrived. `sort/2' would~n"),
    format("   have ordered them by value and dropped nothing; `sort/4'~n"),
    format("   is the one to reach for when you want a say in both.~n"),

    format("~n-- SORTING BY A COMPUTED KEY, which is the whole idiom~n"),
    Words = [banana, kiwi, apple, fig],
    findall(L-W, (member(W, Words), atom_length(W, L)), Tagged),
    keysort(Tagged, ByLength),
    pairs_values(ByLength, Shortest),
    must('the words, shortest first', Shortest, [fig, kiwi, apple, banana]),
    format("   Three lines, no comparator, and it is stable -- so words~n"),
    format("   of the same length keep their original order.~n"),

    format("~n-- and stability is what lets you sort twice~n"),
    People = [p(bo, 30), p(al, 25), p(cy, 30), p(di, 25)],
    findall(N-P1, (member(P1, People), P1 = p(N, _)), ByName),
    keysort(ByName, NameSorted),
    pairs_values(NameSorted, Step1),
    findall(Ag-P2, (member(P2, Step1), P2 = p(_, Ag)), ByAge),
    keysort(ByAge, AgeSorted),
    pairs_values(AgeSorted, Step2),
    must('by age, then by name within each age', Step2,
         [p(al, 25), p(di, 25), p(bo, 30), p(cy, 30)]),
    format("   Sort by the MINOR key first, then the major. Because the~n"),
    format("   second sort is stable, the first one's order survives~n"),
    format("   inside each group. That is the classic use of stability~n"),
    format("   and it is worth having met once.~n"),

    format("~n-- transpose_pairs/2: swap the sides and sort by the new key~n"),
    transpose_pairs([a-2, b-1], Flipped),
    must('transpose_pairs/2', Flipped, [1-b, 2-a]),
    format("   Which is how you invert a mapping: values become keys,~n"),
    format("   and the result is keysorted for you.~n"),

    format("~n-- group_pairs_by_key/2 needs the list sorted FIRST~n"),
    keysort([a-1, b-2, a-3], ToGroup),
    group_pairs_by_key(ToGroup, Grouped),
    must('group_pairs_by_key/2', Grouped, [a-[1, 3], b-[2]]),
    format("   It only groups ADJACENT equal keys, so keysort first --~n"),
    format("   which is a feature: it is one linear pass, and you keep~n"),
    format("   control of the order.~n~n"),
    format("done~n").

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
