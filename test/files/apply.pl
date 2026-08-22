%  library(apply): a goal applied to the elements of a list.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

add1(X, Y) :- Y is X + 1.
add(X, Y, Z) :- Z is X + Y.
add3(X, Y, Z, W) :- W is X + Y + Z.
add4(A, B, C, D, E) :- E is A + B + C + D.
positive(X) :- X > 0.
cmp0(X, Order) :- ( X < 0 -> Order = (<) ; X =:= 0 -> Order = (=) ; Order = (>) ).
halve(X, Y) :- 0 is X mod 2, Y is X // 2.
wrap(X, f(X)).

main :-
    %  ---- maplist, every arity ----
    yn(maplist(positive, [1,2,3]), maplist2_yes),
    yn(maplist(positive, [1,-2]), maplist2_no),
    yn(maplist(positive, []), maplist2_empty),
    ( maplist(add1, [1,2,3], A1) -> s(maplist3, A1) ; s(maplist3, no) ),
    ( maplist(add, [1,2], [10,20], A2) -> s(maplist4, A2) ; s(maplist4, no) ),
    ( maplist(add3, [1], [2], [3], A3) -> s(maplist5, A3) ; s(maplist5, no) ),
    %  maplist runs backwards when its goal does -- with a relational goal,
    %  not an arithmetic one: `Y is X+1' with X unbound is an error in both
    %  systems and they word it differently, which is the one divergence the
    %  shared tests cannot cross.
    ( maplist(wrap, B1, [f(1),f(2)]) -> s(maplist_backwards, B1) ; s(maplist_backwards, no) ),
    yn(maplist(add1, [1,2], [2,3,4]), maplist_length_mismatch),

    %  ---- foldl, every arity ----
    ( foldl(add, [1,2,3], 0, C1) -> s(foldl4, C1) ; s(foldl4, no) ),
    ( foldl(add, [], 7, C2) -> s(foldl_empty, C2) ; s(foldl_empty, no) ),
    ( foldl(add3, [1,2], [10,20], 0, C3) -> s(foldl5, C3) ; s(foldl5, no) ),
    ( foldl(add4, [1], [2], [3], 0, C4) -> s(foldl6, C4) ; s(foldl6, no) ),

    %  ---- scanl: one longer than the input ----
    ( scanl(add, [1,2,3], 0, D1) -> s(scanl4, D1) ; s(scanl4, no) ),
    ( scanl(add, [], 5, D2) -> s(scanl_empty, D2) ; s(scanl_empty, no) ),
    ( scanl(add3, [1,2], [10,20], 0, D3) -> s(scanl5, D3) ; s(scanl5, no) ),

    %  ---- filtering ----
    ( include(positive, [1,-2,3], E1) -> s(include, E1) ; s(include, no) ),
    ( exclude(positive, [1,-2,3], E2) -> s(exclude, E2) ; s(exclude, no) ),
    ( include(positive, [], E3) -> s(include_empty, E3) ; true ),
    ( partition(positive, [1,-2,3,-4], F1, F2) -> s(partition_in, F1), s(partition_ex, F2) ; true ),
    ( partition(cmp0, [1,0,-1,2], G1, G2, G3) -> s(partition5_lt, G1), s(partition5_eq, G2), s(partition5_gt, G3) ; true ),

    %  ---- convlist drops what the goal fails on ----
    ( convlist(halve, [1,2,3,4], H1) -> s(convlist, H1) ; s(convlist, no) ),
    ( convlist(halve, [], H2) -> s(convlist_empty, H2) ; true ),
    true.
