%% The accumulator's own program. By the time this runs, run.sh has
%% consulted part_1.pl, part_2.pl and part_3.pl beside it -- each
%% part's model exported from its trainer's knowledge base as
%% part_spec/2 and part_chunk/3 clauses, the parameters travelling in
%% the same 120-float chunks model_save stores them in, because a
%% clause row has to fit in a page wherever it goes.
%%
%% Accumulating is arithmetic on terms: the three flat parameter lists
%% are averaged element-wise (one-shot federated averaging -- sound
%% here because all parts started from the same seed and trained on
%% thirds of the same distribution), the averaged list goes into a
%% fresh model of the shared spec, and that model is saved, tested on
%% the held-out points no trainer ever saw, and asked to predict.

%% the same deterministic data the trainers used -- indices 900..1049
%% are the held-out test set no shard contains
noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

ring_point(I, [X, Y], L) :-
    L is I mod 2,
    noise(I, N1), noise(I + 7000, N2), noise(I + 14000, N3),
    T is 6.28318 * N1,
    R is 0.5 + 0.5 * L + 0.08 * (N2 - 0.5),
    X is R * cos(T) + 0.02 * (N3 - 0.5),
    Y is R * sin(T), !.

%% a part's flat parameter list, chunks joined in sequence order --
%% the same join model_load performs
part_params(Part, Ps) :-
    findall(Q-C, part_chunk(Part, Q, C), Pairs),
    msort(Pairs, Sorted),
    join_chunks(Sorted, Ps).

join_chunks([], []).
join_chunks([_-C|T], Ps) :- join_chunks(T, Rest), append(C, Rest, Ps).

avg3([], [], [], []).
avg3([A|As], [B|Bs], [C|Cs], [M|Ms]) :-
    M is (A + B + C) / 3,
    avg3(As, Bs, Cs, Ms).

accumulate :-
    part_spec(1, Spec),
    part_params(1, P1), part_params(2, P2), part_params(3, P3),
    avg3(P1, P2, P3, P),
    length(P, NP),
    model_new(Spec, M),
    model_set_params(M, P),
    model_save(rings, M),
    format("accumulated: ~w parameters averaged over 3 parts~n", [NP]),
    test,
    predict.

test :-
    model_load(rings, M),
    findall(X, (between(900, 1049, I), ring_point(I, X, _)), Xs),
    findall(L, (between(900, 1049, I), ring_point(I, _, L)), Ls),
    tensor_from_list(Xs, TX), tensor_from_list(Ls, TY),
    model_evaluate(M, TX, TY, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("held-out accuracy ~w% on 150 points~n", [Pct]),
    ( Pct >= 90 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(rings, M),
    Probes = [[0.5, 0.0], [0.0, -1.0], [-0.35, 0.35], [0.7, 0.7]],
    tensor_from_list(Probes, TX),
    model_predict(M, TX, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [L0, L1]), nth0(I, Probes, [X, Y]) ),
           ( ( L1 > L0 -> C = outer, Conf is exp(L1)
             ; C = inner, Conf is exp(L0) ),
             format("ring(~2f, ~2f) = ~w  (confidence ~2f)~n",
                    [X, Y, C, Conf]) )).
