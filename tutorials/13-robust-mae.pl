%% 13. Outliers in training, judged by mean absolute error
%%
%% Every tenth training target is shoved six units off the line -- the
%% corrupted-labels setup. Mean squared error SQUARES those misses, so the
%% fit is dragged toward them; the honest judgment on clean data is mae,
%% which weighs every miss linearly. The tutorial's point is the metric:
%% the same model, judged by the measure that matches the question.
%%
%%   train    fit through the outliers, save as t13_mae
%%   test     reload, mae against the CLEAN line, pass under 0.6
%%   predict  reload, compare a few answers with the clean law

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

out_row(I, [X], [Y]) :-
    X is -1 + 2 * I / 119,
    noise(I, E),
    Y0 is 2 * X + 1 + 0.05 * E,
    ( I mod 10 =:= 0 -> Y is Y0 + 6 ; Y = Y0 ), !.

clean_row(I, [X], [Y]) :- X is -1 + 2 * I / 39, Y is 2 * X + 1, !.

train :-
    torch_seed(13),
    findall(R, (between(0, 119, I), out_row(I, R, _)), XR),
    findall(R, (between(0, 119, I), out_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(1)], M),
    model_train(M, X, Y, [epochs(300), batch(24), lr(0.05), optimiser(adam),
                          final_loss(L)]),
    format("trained: final mse ~4f (inflated by the outliers)~n", [L]),
    model_save(t13_mae, M),
    write(saved), nl.

test :-
    model_load(t13_mae, M),
    findall(R, (between(0, 39, I), clean_row(I, R, _)), XR),
    findall(R, (between(0, 39, I), clean_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_evaluate(M, X, Y, mae, S),
    format("clean mae ~4f~n", [S]),
    ( S < 0.6 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t13_mae, M),
    Points = [-1.0, 0.0, 1.0],
    findall([Xv], member(Xv, Points), Rows),
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
           ( Truth is 2 * Xv + 1,
             format("x ~2f  predicted ~2f  (clean law says ~2f)~n", [Xv, Yhat, Truth]) )).
