%  library(lists): length, reversal, sorting, sets and arithmetic over a list.
%  Run by BOTH SWI-Prolog and cocolog, output compared.

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

main :-
    %  ---- length, in all its modes ----
    ( length([a,b,c], L1) -> s(length_count, L1) ; s(length_count, no) ),
    ( length(L2, 3) -> ( is_list(L2) -> s(length_make, 3) ; s(length_make, no) ) ; true ),
    ( length([], L3) -> s(length_empty, L3) ; true ),
    ( length([a|T], 3) -> ( is_list(T) -> s(length_partial, yes) ; s(length_partial, no) ) ; true ),
    yn(length([a,b], 2), length_check_yes),
    yn(length([a,b], 3), length_check_no),
    ( proper_length([a,b], L4) -> s(proper_length, L4) ; s(proper_length, no) ),
    yn(proper_length([a|_], _), proper_length_partial),
    yn(same_length([a,b], [1,2]), same_length_yes),
    yn(same_length([a,b], [1]), same_length_no),

    %  ---- reverse ----
    ( reverse([a,b,c], R1) -> s(reverse, R1) ; true ),
    ( reverse([], R2) -> s(reverse_empty, R2) ; true ),

    %  ---- sorting, by the STANDARD ORDER of terms ----
    ( msort([c,a,b,a], M1) -> s(msort_keeps_dups, M1) ; true ),
    ( sort([c,a,b,a], M2) -> s(sort_drops_dups, M2) ; true ),
    ( msort([2,1,a,'B',1.5], M3) -> s(msort_mixed_types, M3) ; true ),
    ( sort(0, @>=, [1,3,2,3], M4) -> s(sort4_desc_keep, M4) ; true ),
    ( sort(0, @>, [1,3,2,3], M5) -> s(sort4_desc_drop, M5) ; true ),
    ( sort(0, @=<, [b,a,b], M6) -> s(sort4_asc_keep, M6) ; true ),
    ( sort(1, @=<, [f(2,x),f(1,y),f(2,z)], M7) -> s(sort4_by_key, M7) ; true ),

    %  ---- sets ----
    ( list_to_set([a,b,a,c,b], S1) -> s(list_to_set, S1) ; true ),
    yn(is_set([a,b,c]), is_set_yes),
    yn(is_set([a,b,a]), is_set_no),
    %  clumped/2 answers PAIRS, which these tests can now print: the writer
    %  spaces operators the way SWI does, so `a-2' is `a-2' on both sides.
    %  It is also taken apart, because the printed form alone would not show
    %  that the counts are integers rather than something that prints like one.
    ( clumped([a,a,b,c,c,c], C1) -> s(clumped, C1) ; s(clumped, no) ),
    ( C1 = [K1-V1, K2-V2, K3-V3] -> true ; K1 = no, V1 = no, K2 = no, V2 = no, K3 = no, V3 = no ),
    s(clumped_k1, K1), s(clumped_v1, V1),
    s(clumped_k2, K2), s(clumped_v2, V2),
    s(clumped_k3, K3), s(clumped_v3, V3),
    yn(integer(V1), clumped_count_is_integer),

    %  ---- arithmetic over a list ----
    ( sum_list([1,2,3], A1) -> s(sum_list, A1) ; true ),
    ( sum_list([], A2) -> s(sum_empty, A2) ; true ),
    ( max_list([1,5,3], A3) -> s(max_list, A3) ; true ),
    ( min_list([4,2,9], A4) -> s(min_list, A4) ; true ),
    ( numlist(1, 5, A5) -> s(numlist, A5) ; true ),
    ( numlist(3, 3, A6) -> s(numlist_one, A6) ; true ),
    yn(numlist(5, 1, _), numlist_backwards),

    %  ---- the standard order, not arithmetic ----
    ( max_member(X1, [1, a, 'Z']) -> s(max_member, X1) ; true ),
    ( min_member(X2, [1, a, 'Z']) -> s(min_member, X2) ; true ),
    yn(max_member(_, []), max_member_empty),

    %  ---- flatten ----
    ( flatten([a,[b,[c,d]],e], F1) -> s(flatten, F1) ; true ),
    ( flatten([], F2) -> s(flatten_empty, F2) ; true ),
    ( flatten([a,[],[b]], F3) -> s(flatten_holes, F3) ; true ),
    true.
