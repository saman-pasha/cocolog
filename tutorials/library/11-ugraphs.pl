%% LIBRARY 11 -- library(ugraphs): graphs as sorted adjacency lists
%%
%%     ./cocolog run tutorials/library/11-ugraphs.pl main
%%
%% TIER 1: no import. SWI's own file, vendored unedited.
%%
%% A GRAPH IS A LIST OF `Vertex-Neighbours' PAIRS, sorted by vertex, with
%% each neighbour list an ordset:
%%
%%     [a-[b, c], b-[c], c-[]]
%%
%% That is the whole representation, and it is the same trick
%% `library(ordsets)' plays: keep an invariant, get linear algorithms, and
%% pay for it by having to maintain the invariant yourself. Build with
%% `vertices_edges_to_ugraph/3' and edit with the `add_'/`del_'
%% predicates.
%%
%% THE EDGES ARE DIRECTED. An undirected graph is one where you added both
%% directions -- `transpose_ugraph/2' plus `ugraph_union/3' is one way.
%%
%% WHAT IT IS ACTUALLY GOOD FOR here: `top_sort/2' and `reachable/3'.
%% Dependency order and "what does this touch" are the two graph questions
%% that come up in a build system, a schema, or a chain of rules -- and
%% both are one call.

%% X comes before Y in the list. Used to check the PROPERTY a topological
%% order has, rather than pinning one of the several valid orders.
before(X, Y, List) :-
    nth0(I, List, X), nth0(J, List, Y), I < J.

main :-
    format("~n-- building a graph~n"),
    vertices_edges_to_ugraph([], [a-b, a-c, b-d, c-d], G),
    must('vertices_edges_to_ugraph/3', G, [a-[b, c], b-[d], c-[d], d-[]]),
    format("   Note `d-[]': a vertex with no edges out is still a vertex,~n"),
    format("   and it appeared because an edge pointed AT it.~n"),
    vertices(G, Vs),
    must('vertices/2', Vs, [a, b, c, d]),
    edges(G, Es),
    must('edges/2', Es, [a-b, a-c, b-d, c-d]),

    format("~n-- neighbours~n"),
    neighbours(a, G, NA),
    must('neighbours/3', NA, [b, c]),
    neighbours(d, G, ND),
    must('...of a sink', ND, []),

    format("~n-- TOP_SORT: dependency order, in one call~n"),
    top_sort(G, Order),
    must('top_sort/2', Order, [a, c, b, d]),
    format("   Every vertex comes after everything that points to it.~n"),
    format("   That is `what order do I build these in', and it is the~n"),
    format("   reason to keep a graph rather than a set of pairs.~n"),
    format("~n"),
    format("   NOTE THE ORDER IS a, c, b, d AND NOT a, b, c, d. Both are~n"),
    format("   valid: b and c neither points at the other, so nothing in~n"),
    format("   the graph decides between them and the algorithm's own~n"),
    format("   bookkeeping does. A test that pinned one particular~n"),
    format("   ordering would be testing the implementation, not the~n"),
    format("   property -- so check the PROPERTY instead:~n"),
    ( before(a, d, Order), before(b, d, Order), before(c, d, Order)
    -> Prop = every_edge_respected ; Prop = broken ),
    must('everything comes before what it points to', Prop,
         every_edge_respected),

    format("~n-- ...and a cycle simply FAILS, which is the right answer~n"),
    vertices_edges_to_ugraph([], [x-y, y-x], Cyclic),
    ( top_sort(Cyclic, _) -> C = ordered ; C = failed ),
    must('top_sort of a cycle', C, failed),
    format("   There is no such order, so there is no such answer. A~n"),
    format("   library that returned a partial order there would be~n"),
    format("   lying about a dependency loop.~n"),

    format("~n-- REACHABLE: what does this touch~n"),
    reachable(a, G, FromA),
    must('reachable/3 includes the start', FromA, [a, b, c, d]),
    reachable(b, G, FromB),
    must('...from b', FromB, [b, d]),

    format("~n-- transitive closure, and the reverse graph~n"),
    transitive_closure(G, TC),
    memberchk(a-ReachA, TC),
    must('a reaches everything', ReachA, [b, c, d]),
    transpose_ugraph(G, T),
    neighbours(d, T, IntoD),
    must('transpose_ugraph/2: who points AT d', IntoD, [b, c]),

    format("~n-- editing, keeping the invariant~n"),
    add_vertices(G, [e], G1),
    vertices(G1, Vs1),
    must('add_vertices/3', Vs1, [a, b, c, d, e]),
    add_edges(G1, [d-e], G2),
    neighbours(d, G2, ND2),
    must('add_edges/3', ND2, [e]),
    del_edges(G2, [a-b], G3),
    neighbours(a, G3, NA3),
    must('del_edges/3', NA3, [c]),
    del_vertices(G3, [e], G4),
    vertices(G4, Vs4),
    must('del_vertices/3 removes its edges too', Vs4, [a, b, c, d]),

    format("~n-- and the set operations, on graphs~n"),
    vertices_edges_to_ugraph([], [a-b], P),
    vertices_edges_to_ugraph([], [b-c], Q),
    ugraph_union(P, Q, PQ),
    must('ugraph_union/3', PQ, [a-[b], b-[c], c-[]]),
    format("~ndone~n").

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
