%% 1. Linear regression
%%
%% The first network of every tutorial: one weight and one bias recover the
%% line y = 3x - 2 from noisy samples. In PyTorch this is nn.Linear(1, 1),
%% an MSELoss and an SGD loop; here it is one dense layer trained with
%% optimiser(sgd), and the whole loop lives inside model_train.
%%
%% The three goals, each meant to be its OWN PROCESS against the same store,
%% because a trained model is terms in the knowledge base, not memory:
%%
%%   train    build the data, fit the line, save the model as t01_linreg
%%   test     reload the model, measure rmse on fresh points, pass under 0.15
%%   predict  reload the model, answer for a few x values beside the truth
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/01-linear-regression.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/01-linear-regression.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/01-linear-regression.pl predict

% Deterministic noise in (-1, 1): the classic sin-hash. Every run sees the
% same "random" data, so train and test agree across processes with no files.
noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

% One sample: x evenly over [-1, 1], y on the line plus a little noise.
lin_row(I, N, [X], [Y]) :-
    N1 is N - 1,
    X is -1 + 2 * I / N1,
    noise(I, E),
    Y is 3 * X - 2 + 0.05 * E, !.

lin_data(N, X, Y) :-
    N1 is N - 1,
    findall(R, (between(0, N1, I), lin_row(I, N, R, _)), XR),
    findall(R, (between(0, N1, I), lin_row(I, N, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.

train :-
    torch_seed(1),
    lin_data(64, X, Y),
    model_new([input(1), dense(1)], M),
    model_train(M, X, Y, [epochs(200), batch(16), lr(0.1), optimiser(sgd),
                          final_loss(L)]),
    format("trained: final mse ~4f~n", [L]),
    model_save(t01_linreg, M),
    write(saved), nl.

test :-
    model_load(t01_linreg, M),
    % fresh points from the same law, not the training set
    lin_data(40, X, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("test rmse ~4f~n", [S]),
    ( S < 0.15 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t01_linreg, M),
    tensor_from_list([[-1.0], [0.0], [0.5], [1.0]], X),
    model_predict(M, X, P),
    tensor_to_list(P, Rows),
    forall(( nth0(I, Rows, [Yhat]), nth0(I, [-1.0, 0.0, 0.5, 1.0], Xv) ),
           ( Truth is 3 * Xv - 2,
             format("x ~2f  predicted ~2f  (line says ~2f)~n", [Xv, Yhat, Truth]) )).
