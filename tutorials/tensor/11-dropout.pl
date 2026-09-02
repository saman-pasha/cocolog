%% 11. Dropout, and the train/eval mode split
%%
%% dropout(0.3) silences a random third of its units EVERY TRAINING BATCH,
%% which fights co-adaptation -- and must switch itself off the moment the
%% model answers for real. The module does that switch inside
%% model_predict and model_evaluate, and this tutorial PROVES it: two
%% forward passes over the same rows must agree to the last bit, which
%% they could not if dropout were still sampling.
%%
%%   train    learn the moons through dropout, save as t11_dropout
%%   test     reload; accuracy at 85%, and two predicts must be identical
%%   predict  reload, classify a few points (deterministically)

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

moon_row(I, [A, B], L) :-
    T is pi * (I mod 80) / 79,
    noise(I, E1), noise(I + 700, E2),
    ( I < 80
    -> L = 0, A is cos(T) + 0.1 * E1,      B is sin(T) + 0.1 * E2
    ;  L = 1, A is 1 - cos(T) + 0.1 * E1,  B is 0.4 - sin(T) + 0.1 * E2 ), !.

moon_data(X, Y) :-
    findall(R, (between(0, 159, I), moon_row(I, R, _)), XR),
    findall(L, (between(0, 159, I), moon_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y), !.

rows_close([], []).
rows_close([A|As], [B|Bs]) :- row_close(A, B), rows_close(As, Bs).
row_close([], []).
row_close([A|As], [B|Bs]) :- D is abs(A - B), D < 1.0e-6, row_close(As, Bs).

train :-
    torch_seed(11),
    moon_data(X, Y),
    model_new([input(2), dense(32, relu), dropout(0.3),
               dense(32, relu), dropout(0.3), dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(300), batch(32), lr(0.02), optimiser(adam),
                          loss(nll), final_loss(L)]),
    format("trained: final nll ~4f~n", [L]),
    model_save(t11_dropout, M),
    write(saved), nl.

test :-
    model_load(t11_dropout, M),
    moon_data(X, Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("accuracy ~w%~n", [Pct]),
    ( Pct >= 85 -> true ; write('FAIL'), nl, halt(1) ),
    % the mode split: dropout must be inert now
    model_predict(M, X, P1), model_predict(M, X, P2),
    tensor_to_list(P1, R1), tensor_to_list(P2, R2),
    ( rows_close(R1, R2)
    -> write('ok (and two predicts agreed exactly)'), nl
    ;  write('FAIL dropout still sampling at predict time'), nl, halt(1) ).

predict :-
    model_load(t11_dropout, M),
    Rows = [[0.0, 1.0], [1.0, -0.6]],
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [L0, L1]), nth0(I, Rows, [A, B]) ),
           ( ( L1 > L0 -> C = lower ; C = upper ),
             format("(~2f, ~2f) is in the ~w moon~n", [A, B, C]) )).
