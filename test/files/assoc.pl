%  library(assoc), the vendored copy, against SWI's own.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  AN ASSOC IS NEVER PRINTED WHOLE. Its tree shape depends on insertion
%  order and rebalancing, which upstream documents as private -- what is
%  compared is every OBSERVABLE: the sorted lists it converts to, the
%  answers lookups give, the errors bad input raises.

:- use_module(library(assoc)).

p(X) :- writeq(X), nl.

e(Label, G) :-
    ( catch(G, error(E, _), true)
    ->  ( var(E) -> R = ok ; R = E )
    ;   R = failed ),
    p(Label-R).

main :-
    empty_assoc(A0),
    p(is_assoc(A0)-ok),
    put_assoc(k1, A0, v1, A1),
    put_assoc(k2, A1, v2, A2),
    put_assoc(k1, A2, v1b, A3),
    assoc_to_list(A3, L3), p(L3),
    assoc_to_keys(A3, K3), p(K3),
    assoc_to_values(A3, V3), p(V3),
    get_assoc(k1, A3, Got), p(got-Got),
    ( get_assoc(missing, A3, _) -> p(bad) ; p(miss-failed) ),
    get_assoc(k2, A3, Old, A4, v2new), p(swapped-Old),
    get_assoc(k2, A4, New), p(now-New),
    list_to_assoc([b-2,a-1,c-3,e-5,d-4], B0),
    assoc_to_list(B0, BL), p(BL),
    max_assoc(B0, MaxK, MaxV), p(max-(MaxK-MaxV)),
    min_assoc(B0, MinK, MinV), p(min-(MinK-MinV)),
    del_assoc(c, B0, DelV, B1), p(deleted-DelV),
    assoc_to_keys(B1, BK), p(BK),
    del_min_assoc(B1, MnK, MnV, B2), p(delmin-(MnK-MnV)),
    del_max_assoc(B2, MxK, MxV, B3), p(delmax-(MxK-MxV)),
    assoc_to_list(B3, B3L), p(B3L),
    list_to_assoc([n-1], N0),
    put_assoc(q, N0, 77, N1),
    assoc_to_list(N1, NL), p(NL),
    e('dup keys', list_to_assoc([a-1,a-2], _)),
    e('unsorted ord list', ord_list_to_assoc([b-1,a-2], _)),
    ord_list_to_assoc([a-1,b-2], O0),
    assoc_to_list(O0, OL), p(OL).
