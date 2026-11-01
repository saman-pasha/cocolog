:- use_module(library(stream)).

main :-
    read_stream_to_codes(user_input, Cs),
    split_string(Cs, "", " \n", [S]),
    number_string(N, S),
    numlist(1, N, Cols),
    findall(Qs, qn_place(Cols, N, [], Qs), All),
    length(All, Count),
    format("~d~n", [Count]),
    (   All = [First|_]
    ->  atomic_list_concat(First, ' ', Line), format("~w~n", [Line])
    ;   format("none~n")
    ).

%% Placed holds the columns of the rows done so far, the latest first.
qn_place(_, N, Placed, Qs) :- length(Placed, N), !, reverse(Placed, Qs).
qn_place(Cols, N, Placed, Qs) :-
    member(C, Cols),
    qn_safe(C, Placed, 1),
    qn_place(Cols, N, [C|Placed], Qs).

qn_safe(_, [], _).
qn_safe(C, [Q|Qs], D) :- C =\= Q, abs(C - Q) =\= D, D1 is D + 1, qn_safe(C, Qs, D1).
