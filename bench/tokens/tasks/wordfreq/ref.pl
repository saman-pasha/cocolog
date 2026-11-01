:- use_module(library(stream)).

main :-
    read_stream_to_codes(user_input, Cs),
    append(First, [10|Text], Cs), !,
    number_codes(K, First),
    wf_words(Text, Words),
    msort(Words, Sorted),
    wf_runs(Sorted, Runs),
    sort(1, @>=, Runs, ByCount),
    wf_print(K, ByCount).

wf_words([], []).
wf_words([C|Cs], Words) :-
    (   wf_letter(C)
    ->  wf_take([C|Cs], Letters, Rest),
        atom_codes(A, Letters), downcase_atom(A, W),
        Words = [W|Words1],
        wf_words(Rest, Words1)
    ;   wf_words(Cs, Words)
    ).

wf_take([C|Cs], [C|Ls], Rest) :- wf_letter(C), !, wf_take(Cs, Ls, Rest).
wf_take(Rest, [], Rest).

wf_letter(C) :- ( C >= 0'a, C =< 0'z -> true ; C >= 0'A, C =< 0'Z ).

wf_runs([], []).
wf_runs([W|Ws], [N-W|Runs]) :- wf_same(W, Ws, 1, N, Rest), wf_runs(Rest, Runs).

wf_same(W, [W|Ws], N0, N, Rest) :- !, N1 is N0 + 1, wf_same(W, Ws, N1, N, Rest).
wf_same(_, Rest, N, N, Rest).

wf_print(0, _) :- !.
wf_print(_, []) :- !.
wf_print(K, [N-W|Runs]) :- format("~w ~d~n", [W, N]), K1 is K - 1, wf_print(K1, Runs).
