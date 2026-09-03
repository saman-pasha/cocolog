%% 3. Polynomial regression through engineered features
%%
%% A LINEAR model fits the cubic y = x^3 - x exactly, because the features
%% do the bending: each x arrives as the row [x, x^2, x^3] and the one
%% expression `X matmul W + B' only has to find the weights (0, 0, 1) minus
%% (1, 0, 0). This is the PyTorch polynomial-regression tutorial, and its
%% lesson is that feature engineering and model capacity trade against each
%% other: tutorials 4 and 5 buy the bending with a hidden layer instead.
%% The optimiser is Adam, adam_step/6 answering new parameters each step.
%% An earlier version of this file used model_new and model_train; that API
%% is still taught in tutorials/library/22-torch.pl.
%%
%%   train    fit the cubic through its powers, save the parameters as t03_poly
%%   test     reload, rmse over the curve, pass under 0.05
%%   predict  reload, evaluate a few x beside the true cubic
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/03-polynomial-features.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/03-polynomial-features.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/03-polynomial-features.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).

%% ---- the data ---------------------------------------------------------------
%% Every predicate ends in a cut: the store keeps every consult, and a
%% generator without one would answer once per copy.

poly_row(I, [X, X2, X3], [Y]) :-
    X is -1 + 2 * I / 99,
    X2 is X * X, X3 is X2 * X,
    Y is X3 - X, !.

poly_features(Xv, [Xv, X2, X3]) :- X2 is Xv * Xv, X3 is X2 * Xv, !.

%% poly_data(-X, -Y): the hundred rows of powers, and the cubic at each.
poly_data(X, Y) -->
    { findall(R, (between(0, 99, I), poly_row(I, R, _)), XR),
      findall(R, (between(0, 99, I), poly_row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the network ------------------------------------------------------------

loss(X, Y, W, B) ::= mse(X matmul W + B, Y).

%% a PREDICATE, not a rule: the optimiser frees these, and a rule must not
%% emit what something else frees.
parameters([W, B]) :-
    W := parameter(randn([3, 1])),
    B := parameter(zeros([1])), !.

%% ---- the three goals ----------------------------------------------------------
%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(3),
    poly_data(X, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(800, Ps0, St0, X, Y, [W, B]) },
    L = item(loss(X, Y, W, B)),
    [[W1], [W2], [W3]] = list(W), [Bv] = list(B),
    { format("trained: final mse ~6f  weights ~3f ~3f ~3f  bias ~3f~n", [L, W1, W2, W3, Bv]) },
    params_save(t03_poly, [W, B]),
    { write(saved), nl }.

%% fit(+K, +Ps, +State, +X, +Y, -PsF): K full-batch steps of Adam at 0.05.
fit(0, Ps, _, _, _, Ps) :- !.
fit(K, [W, B], St, X, Y, PsF) :-
    L := loss(X, Y, W, B),
    Gs := grad(L, [W, B]),
    ( K mod 200 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~6f~n", [K, Lv]) ; true ),
    adam_step([W, B], Gs, St, 0.05, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    [W, B] = params(t03_poly),
    poly_data(X, Y),
    S = item(sqrt(loss(X, Y, W, B))),
    { format("rmse ~6f~n", [S]),
      ( S < 0.05 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    [W, B] = params(t03_poly),
    { Points = [-0.9, -0.5, 0.0, 0.5, 0.9],
      findall(F, (member(Xv, Points), poly_features(Xv, F)), Rows) },
    Out = list(Rows matmul W + B),
    { forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
             ( Truth is Xv * Xv * Xv - Xv,
               format("x ~2f  predicted ~4f  (cubic says ~4f)~n", [Xv, Yhat, Truth]) )) }.
