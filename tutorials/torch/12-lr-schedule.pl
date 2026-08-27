%% 12. A learning-rate schedule over plain sgd
%%
%% schedule(step, 400, 0.5) halves the learning rate every 400 epochs: the
%% big early steps find the valley, the halved late ones settle into it.
%% The optimiser is deliberately plain sgd -- adam adapts its own rates and
%% hides the schedule's effect. A lesson this file keeps from its own
%% tuning: sgd at lr 0.3 on a TANH net diverged to NaN, where the same
%% rate-family on this relu net glides; activation and rate are a pair.
%%
%%   train    fit the bump under the decaying rate, save as t12_schedule
%%   test     reload, rmse under 0.1
%%   predict  reload, sample the fit

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

bump_row(I, [X], [Y]) :- X is -2 + 4 * I / 159, Y is exp(-4 * X * X), !.

train :-
    torch_seed(12),
    findall(R, (between(0, 159, I), bump_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), bump_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(24, relu), dense(24, relu), dense(1)], M),
    model_train(M, X, Y, [epochs(1500), batch(32), lr(0.1), optimiser(sgd),
                          schedule(step, 400, 0.5), final_loss(L)]),
    format("trained: final mse ~6f~n", [L]),
    model_save(t12_schedule, M),
    write(saved), nl.

test :-
    model_load(t12_schedule, M),
    findall(R, (between(0, 159, I), bump_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), bump_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("rmse ~4f~n", [S]),
    ( S < 0.1 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t12_schedule, M),
    Points = [-1.5, -0.5, 0.0, 0.5, 1.5],
    findall([Xv], member(Xv, Points), Rows),
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
           ( Truth is exp(-4 * Xv * Xv),
             format("x ~2f  predicted ~3f  (bump says ~3f)~n", [Xv, Yhat, Truth]) )).
