%% 4. Function approximation: sin(2 pi x) through a tanh hidden layer
%%
%% The universal-approximation tutorial. A single hidden layer of 48 tanh
%% units bends a straight head into a full period of the sine; tanh suits
%% smooth targets the way relu suits kinked ones (tutorial 5 is the
%% counterpart). Watch the width: 8 units underfit visibly, 48 are ample.
%%
%%   train    fit the wave, save as t04_sine
%%   test     reload, rmse over the period, pass under 0.1
%%   predict  reload, sample the learned wave beside sin itself

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

sine_row(I, [X], [Y]) :- X is -1 + 2 * I / 159, Y is sin(2 * pi * X), !.

train :-
    torch_seed(4),
    findall(R, (between(0, 159, I), sine_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), sine_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(48, tanh), dense(1)], M),
    model_train(M, X, Y, [epochs(1200), batch(32), lr(0.01), optimiser(adam),
                          final_loss(L)]),
    format("trained: final mse ~4f~n", [L]),
    model_save(t04_sine, M),
    write(saved), nl.

test :-
    model_load(t04_sine, M),
    findall(R, (between(0, 159, I), sine_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), sine_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("rmse ~4f~n", [S]),
    ( S < 0.1 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t04_sine, M),
    Points = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0],
    findall([Xv], member(Xv, Points), Rows),
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
           ( Truth is sin(2 * pi * Xv),
             format("x ~2f  predicted ~3f  (sin says ~3f)~n", [Xv, Yhat, Truth]) )).
