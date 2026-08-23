%  library(ordsets), the vendored copy, against SWI's own.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.

:- use_module(library(ordsets)).

p(X) :- writeq(X), nl.

e(Label, G) :-
    ( catch(G, error(E, _), true)
    ->  ( var(E) -> R = ok ; R = E )
    ;   R = failed ),
    p(Label-R).

main :-
    list_to_ord_set([c,a,b,a,c], S1), p(S1),
    p(is_ordset(S1)-ok),
    ( is_ordset([b,a]) -> p(bad) ; p(unordered-failed) ),
    ord_add_element(S1, d, S2), p(S2),
    ord_del_element(S2, a, S3), p(S3),
    list_to_ord_set([b,d,f], T1),
    ord_union(S2, T1, U), p(U),
    ord_union([[a,b],[b,c],[x]], U2), p(U2),
    ord_intersection(S2, T1, I), p(I),
    ord_intersection(S2, T1, I2, Rest), p(I2-Rest),
    ord_subtract(S2, T1, D), p(D),
    ord_symdiff(S2, T1, Y), p(Y),
    ( ord_subset([a,b], S2) -> p(subset-ok) ; p(bad) ),
    ( ord_subset([a,z], S2) -> p(bad) ; p(subset-failed) ),
    ( ord_disjoint([p,q], S2) -> p(disjoint-ok) ; p(bad) ),
    ( ord_intersect([b,q], S2) -> p(intersect-ok) ; p(bad) ),
    ( ord_memberchk(c, S2) -> p(member-ok) ; p(bad) ),
    ord_selectchk(b, S2, Sel), p(Sel),
    ord_empty(E0), p(E0),
    ord_union(S2, T1, U3, New), p(U3-New),
    e('powerset of nonlist', ord_subtract(x, [a])).
