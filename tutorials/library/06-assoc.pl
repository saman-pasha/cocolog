%% LIBRARY 06 -- library(assoc): a map that is a term
%%
%%     ./cocolog run tutorials/library/06-assoc.pl main
%%
%% TIER 1: no import. SWI's own file, vendored unedited under its BSD-2
%% header in `lib/swipl/assoc.pl'.
%%
%% WHY NOT JUST A LIST OF PAIRS? Because lookup in a list is O(n) and a
%% list has no cheap "the same but with one key changed". An assoc is an
%% AVL tree: O(log n) to look up, O(log n) to put, and PUTTING RETURNS A
%% NEW TREE that shares almost all of its structure with the old one.
%%
%% WHICH IS THE POINT. There is no mutation here and there cannot be:
%% `put_assoc(K, Old, V, New)' leaves `Old' exactly as it was. So you can
%% keep a version from before an edit, backtrack over an edit for free,
%% and hand the same tree to two branches of a search knowing neither can
%% disturb the other. A hash table cannot do any of that.
%%
%% THE KEYS ARE COMPARED BY THE STANDARD ORDER, so anything can be a key
%% -- atoms, numbers, compounds -- as long as it is GROUND. A key with a
%% variable in it will not stay in the same place as bindings happen.

main :-
    format("~n-- building one~n"),
    empty_assoc(E),
    ( empty_assoc(E) -> Em = empty ; Em = not_empty ),
    must('empty_assoc/1', Em, empty),
    list_to_assoc([a-1, b-2, c-3], A0),
    get_assoc(b, A0, B),
    must('get_assoc/3', B, 2),

    format("~n-- and a lookup that is not there simply FAILS~n"),
    ( get_assoc(zz, A0, _) -> M = found ; M = absent ),
    must('get_assoc on a missing key', M, absent),
    format("   An ordinary no, not an error -- so `( get_assoc(K,A,V) ->~n"),
    format("   use(V) ; default )' is the idiom, with no catch in sight.~n"),

    format("~n-- PUTTING GIVES YOU A NEW TREE, and keeps the old one~n"),
    put_assoc(b, A0, 22, A1),
    get_assoc(b, A1, NewB),
    must('the new tree', NewB, 22),
    get_assoc(b, A0, OldB),
    must('and the OLD one, untouched', OldB, 2),
    format("   That is the whole reason to use this rather than a~n"),
    format("   dictionary: an edit does not destroy the thing it edits,~n"),
    format("   so backtracking over one costs nothing at all.~n"),

    format("~n-- adding a key that was not there~n"),
    put_assoc(d, A1, 4, A2),
    assoc_to_list(A2, AsList),
    must('assoc_to_list/2, sorted by key', AsList, [a-1, b-22, c-3, d-4]),
    assoc_to_keys(A2, Keys),
    must('assoc_to_keys/2', Keys, [a, b, c, d]),
    assoc_to_values(A2, Values),
    must('assoc_to_values/2, in KEY order', Values, [1, 22, 3, 4]),

    format("~n-- deleting~n"),
    del_assoc(b, A2, Was, A3),
    must('del_assoc/4 hands back what was there', Was, 22),
    assoc_to_keys(A3, Left),
    must('and the tree without it', Left, [a, c, d]),

    format("~n-- keys need not be atoms: the standard order decides~n"),
    list_to_assoc([3-three, 1-one, 2-two], Nums),
    assoc_to_keys(Nums, NumKeys),
    must('numeric keys come back sorted', NumKeys, [1, 2, 3]),
    list_to_assoc([point(1, 1)-origin, point(9, 9)-far], Pts),
    get_assoc(point(9, 9), Pts, Far),
    must('a COMPOUND key', Far, far),

    format("~n-- and a fold over one, which is where the tree pays off~n"),
    assoc_to_list(A3, Final),
    foldl([_-V, S0, S1]>>(S1 is S0 + V), Final, 0, Total),
    must('the values summed', Total, 8),

    format("~n-- WHEN NOT TO USE IT: for a handful of keys a plain~n"),
    format("   pair list and memberchk/2 is simpler and faster, and~n"),
    format("   library(pairs) -- next -- has the tools for it. Reach for~n"),
    format("   an assoc when the map is big, or when you need the old~n"),
    format("   version after an edit.~n~n"),
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
