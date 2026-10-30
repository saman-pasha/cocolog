:- use_module(library(stream)).
:- dynamic fm_parent/2.

main :-
    read_stream_to_codes(user_input, Cs),
    split_string(Cs, "\n", "", Lines),
    forall(( member(L, Lines), string_length(L, Len), Len > 0 ), fm_line(L)).

fm_line(L) :-
    split_string(L, " ", "", Ws),
    maplist([S, A]>>atom_string(A, S), Ws, Words),
    fm_do(Words).

fm_do([parent, X, Y]) :- !, assertz(fm_parent(X, Y)).
fm_do([Kind, X]) :-
    findall(Y, fm_rel(Kind, X, Y), Ys0),
    sort(Ys0, Ys),
    (   Ys == []
    ->  format("none~n")
    ;   atomic_list_concat(Ys, ' ', Line), format("~w~n", [Line])
    ).

fm_rel(ancestors, X, Y) :- fm_ancestor(X, Y).
fm_rel(descendants, X, Y) :- fm_ancestor(Y, X).
fm_rel(siblings, X, Y) :- fm_sibling(X, Y).
fm_rel(cousins, X, Y) :- fm_cousin(X, Y).

fm_ancestor(X, A) :- fm_parent(A, X).
fm_ancestor(X, A) :- fm_parent(P, X), fm_ancestor(P, A).

fm_sibling(X, Y) :- fm_parent(P, X), fm_parent(P, Y), X \== Y.

fm_cousin(X, Y) :-
    fm_parent(P, X), fm_parent(Q, Y), fm_sibling(P, Q),
    X \== Y, \+ fm_sibling(X, Y).
