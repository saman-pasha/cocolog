%% 3. Polynomial regression through engineered features
%%
%% A LINEAR model fits the cubic y = x^3 - x exactly, because the features
%% do the bending: each x arrives as the row [x, x^2, x^3] and the dense
%% layer only has to find the weights (0, 0, 1) minus (1, 0, 0). This is
%% the PyTorch polynomial-regression tutorial, and its lesson is that
%% feature engineering and model capacity trade against each other.
%%
%%   train    fit the cubic through its powers, save as t03_poly
%%   test     reload, rmse over the curve, pass under 0.05
%%   predict  reload, evaluate a few x beside the true cubic

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

poly_row(I, [X, X2, X3], [Y]) :-
    X is -1 + 2 * I / 99,
    X2 is X * X, X3 is X2 * X,
    Y is X3 - X, !.

poly_features(Xv, [Xv, X2, X3]) :- X2 is Xv * Xv, X3 is X2 * Xv, !.

train :-
    torch_seed(3),
    findall(R, (between(0, 99, I), poly_row(I, R, _)), XR),
    findall(R, (between(0, 99, I), poly_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(3), dense(1)], M),
    model_train(M, X, Y, [epochs(400), batch(25), lr(0.05), optimiser(adam),
                          final_loss(L)]),
    format("trained: final mse ~6f~n", [L]),
    model_save(t03_poly, M),
    write(saved), nl.

test :-
    model_load(t03_poly, M),
    findall(R, (between(0, 99, I), poly_row(I, R, _)), XR),
    findall(R, (between(0, 99, I), poly_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("rmse ~6f~n", [S]),
    ( S < 0.05 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t03_poly, M),
    Points = [-0.9, -0.5, 0.0, 0.5, 0.9],
    findall(F, (member(Xv, Points), poly_features(Xv, F)), Rows),
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
           ( Truth is Xv * Xv * Xv - Xv,
             format("x ~2f  predicted ~4f  (cubic says ~4f)~n", [Xv, Yhat, Truth]) )).
