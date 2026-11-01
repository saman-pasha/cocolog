:- use_module(library(stream)).
:- dynamic pt_edge/2.

main :-
    read_stream_to_codes(user_input, Cs),
    split_string(Cs, " \n", "", Parts),
    findall(N, ( member(P, Parts), string_length(P, Len), Len > 0, number_string(N, P) ),
            [_, M|Nums]),
    pt_edges(M, Nums, [Q|Queries]),
    pt_queries(Q, Queries).

pt_edges(0, Rest, Rest) :- !.
pt_edges(M, [U, V|Nums], Rest) :- assertz(pt_edge(U, V)), M1 is M - 1, pt_edges(M1, Nums, Rest).

pt_queries(0, _) :- !.
pt_queries(Q, [S, T|Nums]) :-
    pt_bfs([S-0], [S], T, D),
    format("~d~n", [D]),
    Q1 is Q - 1,
    pt_queries(Q1, Nums).

%% A queue of Node-Distance pairs, and the nodes already queued.
pt_bfs([], _, _, -1).
pt_bfs([U-Du|Queue], Seen, T, D) :-
    (   U =:= T
    ->  D = Du
    ;   findall(V, ( pt_edge(U, V), \+ memberchk(V, Seen) ), Vs0),
        sort(Vs0, Vs),
        append(Seen, Vs, Seen1),
        D1 is Du + 1,
        findall(V-D1, member(V, Vs), New),
        append(Queue, New, Queue1),
        pt_bfs(Queue1, Seen1, T, D)
    ).
