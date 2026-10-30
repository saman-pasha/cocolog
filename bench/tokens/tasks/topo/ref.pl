:- use_module(library(stream)).

main :-
    read_stream_to_codes(user_input, Cs),
    split_string(Cs, "\n", "", Lines),
    findall(A-B, ( member(L, Lines), split_string(L, " ", "", [SA, SB]),
                   atom_string(A, SA), atom_string(B, SB) ), Edges),
    findall(X, ( member(A-B, Edges), ( X = A ; X = B ) ), Xs0),
    sort(Xs0, Tasks),
    tp_order(Tasks, Edges, Order),
    (   length(Tasks, N), length(Order, N)
    ->  atomic_list_concat(Order, ' ', Line), format("~w~n", [Line])
    ;   format("cycle~n")
    ).

%% Tasks is sorted, so the first one with no edge left into it is the one
%% to do next; doing it drops the edges out of it.
tp_order([], _, []) :- !.
tp_order(Tasks, Edges, [X|Order]) :-
    member(X, Tasks), \+ memberchk(_-X, Edges), !,
    selectchk(X, Tasks, Tasks1),
    exclude(tp_from(X), Edges, Edges1),
    tp_order(Tasks1, Edges1, Order).
tp_order(_, _, []).

tp_from(X, A-_) :- A == X.
