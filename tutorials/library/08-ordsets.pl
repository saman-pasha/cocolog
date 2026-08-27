%% LIBRARY 08 -- library(ordsets): sets that are sorted lists
%%
%%     ./cocolog run tutorials/library/08-ordsets.pl main
%%
%% TIER 1: no import. SWI's own file, vendored unedited.
%%
%% AN ORDSET IS NOT A NEW TYPE. It is an ordinary list that happens to be
%% sorted by the standard order with no duplicates -- so every list
%% predicate still works on one, and `write/1' shows you a list.
%%
%% WHY BOTHER: because with that ONE invariant, union, intersection and
%% difference are a single merge -- O(n+m) instead of the O(n*m) that
%% `library(lists)'s `union/3' and `intersection/3' cost. On two hundred
%% elements that is forty thousand comparisons against four hundred.
%%
%% THE INVARIANT IS YOURS TO MAINTAIN. Nothing checks it. Hand
%% `ord_union/3' an unsorted list and it will answer, wrongly and without
%% complaint -- which is the price of the sets being plain lists. Build
%% them with `list_to_ord_set/2' and only ever edit them with the
%% `ord_' predicates, and the invariant looks after itself.
%%
%% WHEN TO USE WHICH:
%%     a handful of items, order matters   library(lists)
%%     real set algebra, many items        this
%%     a MAP rather than a set             library(assoc)

main :-
    format("~n-- building: sorted, and duplicates gone~n"),
    list_to_ord_set([c, a, b, a], S1),
    must('list_to_ord_set/2', S1, [a, b, c]),
    list_to_ord_set([], Empty),
    must('the empty set is []', Empty, []),
    ( is_ordset([a, b, c]) -> Chk = yes ; Chk = no ),
    must('is_ordset/1', Chk, yes),
    ( is_ordset([c, a]) -> Chk2 = yes ; Chk2 = no ),
    must('...and it does notice an unsorted one', Chk2, no),

    format("~n-- the algebra, all of it one merge~n"),
    list_to_ord_set([1, 2, 3, 4], A),
    list_to_ord_set([3, 4, 5], B),
    ord_union(A, B, U),
    must('ord_union/3', U, [1, 2, 3, 4, 5]),
    ord_intersection(A, B, I),
    must('ord_intersection/3', I, [3, 4]),
    ord_subtract(A, B, Sub),
    must('ord_subtract/3', Sub, [1, 2]),
    ord_symdiff(A, B, Sym),
    must('ord_symdiff/3 -- in one or the other, not both', Sym, [1, 2, 5]),

    format("~n-- membership and containment~n"),
    ( ord_memberchk(3, A) -> Mem = yes ; Mem = no ),
    must('ord_memberchk/2', Mem, yes),
    ( ord_subtract([3, 4], A, []) -> Sst = yes ; Sst = no ),
    must('is [3,4] a subset of A', Sst, yes),
    ( ord_intersection(A, [9], []) -> Dis = yes ; Dis = no ),
    must('are A and [9] disjoint', Dis, yes),

    format("~n-- adding and removing one element~n"),
    ord_add_element(A, 0, Added),
    must('ord_add_element/3 puts it in its place', Added, [0, 1, 2, 3, 4]),
    ord_del_element(A, 2, Deleted),
    must('ord_del_element/3', Deleted, [1, 3, 4]),
    ord_add_element(A, 3, Again),
    must('...and adding one already there changes nothing', Again, A),

    format("~n-- union of MANY sets at once~n"),
    ord_union([[1, 2], [2, 3], [3, 4]], All),
    must('ord_union/2 over a list of sets', All, [1, 2, 3, 4]),

    format("~n-- and the warning, which is the price of the plain list~n"),
    ord_union([b, a], [c], Wrong),
    format("   ord_union([b,a], [c], X) answered ~q~n", [Wrong]),
    format("   -- silently, because [b,a] is not an ordset and nothing~n"),
    format("   checked. Build with list_to_ord_set/2 and edit only with~n"),
    format("   the ord_ predicates, and this cannot happen to you.~n~n"),
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
