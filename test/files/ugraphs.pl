%  library(ugraphs), the vendored copy, against SWI's own.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.

:- use_module(library(ugraphs)).

p(X) :- writeq(X), nl.

main :-
    vertices_edges_to_ugraph([], [a-b, a-c, b-c, c-d], G), p(G),
    vertices(G, Vs), p(Vs),
    edges(G, Es), p(Es),
    add_vertices(G, [e, a], G1), p(G1),
    add_edges(G, [d-a, b-d], G2), p(G2),
    del_edges(G2, [a-b, d-a], G3), p(G3),
    del_vertices(G2, [c], G4), p(G4),
    neighbors(a, G, Na), p(Na),
    neighbours(c, G, Nc), p(Nc),
    transpose_ugraph(G, T), p(T),
    reachable(a, G, Ra), p(Ra),
    reachable(d, G, Rd), p(Rd),
    top_sort(G, Sorted), p(Sorted),
    ( top_sort([a-[b], b-[a]], _) -> p(bad) ; p(cycle-failed) ),
    transitive_closure(G, C), p(C),
    compose([a-[b], b-[c]], [b-[x], c-[y]], Comp), p(Comp),
    complement([a-[b], b-[], c-[]], Neg), p(Neg),
    ugraph_union([a-[b]], [a-[c], d-[]], U), p(U),
    connect_ugraph([b-[c], c-[]], Start, Conn), p(Start-Conn).
