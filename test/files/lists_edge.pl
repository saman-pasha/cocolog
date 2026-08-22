%  library(lists): the empty list, the one-element list, and the corners.
%  Run by BOTH SWI-Prolog and cocolog, output compared.
%
%  WHAT IS NOT HERE, and why. SWI THROWS where cocolog FAILS: `msort(notalist,
%  _)' is a type_error there and false here, and `length(_, -1)' is a
%  domain_error there and false here -- cocolog has no error terms and no
%  catch/3, so the two cannot be compared on those paths at all. They are
%  listed in MODULES.md rather than quietly left out.

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

main :-
    %  ---- sort/4 in each of its four orders ----
    ( sort(0, @<, [c,a,b,a], A1) -> s(sort4_strict_asc, A1) ; true ),
    ( sort(2, @=<, [f(x,2),f(y,1)], A2) -> s(sort4_by_second_arg, A2) ; true ),

    %  ---- the empty list, everywhere it is allowed ----
    ( msort([], B1) -> s(msort_empty, B1) ; true ),
    ( sort([], B2) -> s(sort_empty, B2) ; true ),
    ( length(B3, 0) -> s(length_zero, B3) ; true ),
    ( list_to_set([], B4) -> s(l2s_empty, B4) ; true ),
    ( clumped([], B5) -> s(clumped_empty, B5) ; true ),
    yn(is_set([]), is_set_empty),
    ( intersection([], [a], B6) -> s(intersection_empty, B6) ; true ),
    ( union([], [a], B7) -> s(union_empty, B7) ; true ),
    ( subtract([a], [], B8) -> s(subtract_empty, B8) ; true ),
    yn(subset([], [a]), subset_empty),
    ( delete([], a, B9) -> s(delete_empty, B9) ; true ),
    ( append([], [], BA) -> s(append_empties, BA) ; true ),
    yn(same_length([], []), same_length_empty),
    ( permutation([], BB) -> s(permutation_empty, BB) ; true ),
    yn(last([], _), last_empty),

    %  ---- one element ----
    ( reverse([a], C1) -> s(reverse_one, C1) ; true ),

    %  ---- numbers that are not all positive integers ----
    ( numlist(-2, 1, D1) -> s(numlist_negative, D1) ; true ),
    ( sum_list([1, 2.5], D2) -> s(sum_mixed, D2) ; true ),
    ( max_list([1.5, 2], D3) -> s(max_mixed, D3) ; true ),

    %  ---- nesting ----
    ( flatten([[[a]]], E1) -> s(flatten_deep, E1) ; true ),
    true.
