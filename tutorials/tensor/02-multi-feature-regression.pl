%% 2. Regression over three features, with a held-out test set
%%
%% y = 2a - b + 0.5c + 1: three inputs, one output, and the tutorial habit
%% worth keeping -- the test rows are NEVER shown to the optimiser. The
%% split is tensor_train_test/4, the optimiser is adam, and the judgment
%% is rmse on the held-out fifth.
%%
%%   train    fit on the first 96 of 120 rows, save as t02_multi
%%   test     reload, judge on the held-out 24, pass under 0.15
%%   predict  reload, answer for a few hand-picked feature rows

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

mlin_row(I, [A, B, C], [Y]) :-
    noise(I, A), noise(I + 1000, B), noise(I + 2000, C), noise(I + 3000, E),
    Y is 2 * A - B + 0.5 * C + 1 + 0.05 * E, !.

mlin_data(X, Y) :-
    findall(R, (between(0, 119, I), mlin_row(I, R, _)), XR),
    findall(R, (between(0, 119, I), mlin_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.

train :-
    torch_seed(2),
    mlin_data(X0, Y0),
    tensor_train_test(X0, 96, XTr, _),
    tensor_train_test(Y0, 96, YTr, _),
    model_new([input(3), dense(1)], M),
    model_train(M, XTr, YTr, [epochs(250), batch(24), lr(0.02), optimiser(adam),
                              final_loss(L)]),
    format("trained: final mse ~4f~n", [L]),
    model_save(t02_multi, M),
    write(saved), nl.

test :-
    model_load(t02_multi, M),
    mlin_data(X0, Y0),
    tensor_train_test(X0, 96, _, XTe),
    tensor_train_test(Y0, 96, _, YTe),
    model_evaluate(M, XTe, YTe, rmse, S),
    format("held-out rmse ~4f~n", [S]),
    ( S < 0.15 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t02_multi, M),
    Rows = [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.5, -0.5, 1.0]],
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [Yhat]), nth0(I, Rows, [A, B, C]) ),
           ( Truth is 2 * A - B + 0.5 * C + 1,
             format("f(~1f, ~1f, ~1f)  predicted ~2f  (law says ~2f)~n",
                    [A, B, C, Yhat, Truth]) )).
