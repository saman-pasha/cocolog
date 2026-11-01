:- use_module(library(stream)).

main :-
    read_stream_to_codes(user_input, Cs),
    split_string(Cs, "\n", "", Lines),
    empty_assoc(A0),
    foldl(bk_line, Lines, A0, _).

bk_line(L, A0, A) :-
    (   string_length(L, 0)
    ->  A = A0
    ;   split_string(L, " ", "", Ws),
        maplist([S, X]>>atom_string(X, S), Ws, Words),
        bk_do(Words, A0, A)
    ).

bk_do([open, N], A0, A) :- !,
    (   get_assoc(N, A0, _)
    ->  format("error: account ~w exists~n", [N]), A = A0
    ;   put_assoc(N, A0, 0, A)
    ).
bk_do([Cmd|Args], A0, A0) :-
    bk_names(Cmd, Args, Names),
    member(N, Names), \+ get_assoc(N, A0, _), !,
    format("error: no account ~w~n", [N]).
bk_do([balance, N], A, A) :- !,
    get_assoc(N, A, B), format("~d~n", [B]).
bk_do([deposit, N, M], A0, A) :- !,
    atom_number(M, X), get_assoc(N, A0, B), B1 is B + X, put_assoc(N, A0, B1, A).
bk_do([withdraw, N, M], A0, A) :- !,
    atom_number(M, X), bk_take(N, X, A0, A, _).
bk_do([transfer, F, T, M], A0, A) :-
    atom_number(M, X),
    bk_take(F, X, A0, A1, Ok),
    (   Ok == ok
    ->  get_assoc(T, A1, B), B1 is B + X, put_assoc(T, A1, B1, A)
    ;   A = A0
    ).

bk_names(transfer, [F, T|_], [F, T]) :- !.
bk_names(_, [N|_], [N]).

%% Takes X from N's balance, or says it cannot and changes nothing.
bk_take(N, X, A0, A, Ok) :-
    get_assoc(N, A0, B),
    (   X > B
    ->  format("error: insufficient funds~n"), A = A0, Ok = no
    ;   B1 is B - X, put_assoc(N, A0, B1, A), Ok = ok
    ).
