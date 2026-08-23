%  library(pairs), the vendored copy, against SWI's own.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.

:- use_module(library(pairs)).

p(X) :- writeq(X), nl.

main :-
    pairs_keys_values(P0, [a,b,c], [1,2,3]), p(P0),
    pairs_keys_values([x-9,y-8], K1, V1), p(K1-V1),
    pairs_keys([one-1,two-2,three-3], K2), p(K2),
    pairs_values([one-1,two-2,three-3], V2), p(V2),
    msort([b-2,a-1,b-1,a-3,c-9], S),
    group_pairs_by_key(S, G), p(G),
    transpose_pairs([a-2,b-1,c-2], T), p(T),
    map_list_to_pairs(atom_length, [ab,cde,f], M), p(M).
