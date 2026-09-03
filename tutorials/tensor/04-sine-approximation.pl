%% 4. Function approximation: sin(2 pi x) through a tanh hidden layer
%%
%% The universal-approximation tutorial. A single hidden layer of 48 tanh
%% units bends a straight head into a full period of the sine; tanh suits
%% smooth targets the way relu suits kinked ones (tutorial 5 is the
%% counterpart). The network is ONE DEFINED FUNCTION,
%%
%%     net(X, W1, B1, W2, B2) ::= tanh(X matmul W1 + B1) matmul W2 + B2.
%%
%% and the loss another, `mse(net(...), Y)'; four parameters, glorot for the
%% weights, zeros for the biases, and Adam stepping them. Watch the width:
%% 8 units underfit visibly, 48 are ample. An earlier version of this file
%% used model_new and model_train; that API is still taught in
%% tutorials/library/22-torch.pl.
%%
%%   train    fit the wave, save the parameters as t04_sine
%%   test     reload, rmse over the period, pass under 0.1
%%   predict  reload, sample the learned wave beside sin itself
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/04-sine-approximation.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/04-sine-approximation.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/04-sine-approximation.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the data ---------------------------------------------------------------
%% Every predicate ends in a cut: the store keeps every consult, and a
%% generator without one would answer once per copy.

sine_row(I, [X], [Y]) :- X is -1 + 2 * I / 159, Y is sin(2 * pi * X), !.

%% sine_data(-X, -Y): 160 points over one period, [160, 1] each.
sine_data(X, Y) -->
    { findall(R, (between(0, 159, I), sine_row(I, R, _)), XR),
      findall(R, (between(0, 159, I), sine_row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the network ------------------------------------------------------------
%% Two defined functions: the network, and its distance from the samples.

net(X, W1, B1, W2, B2) ::= tanh(X matmul W1 + B1) matmul W2 + B2.
loss(X, Y, W1, B1, W2, B2) ::= mse(net(X, W1, B1, W2, B2), Y).

%% a PREDICATE, not a rule: the optimiser frees these, and a rule must not
%% emit what something else frees.
parameters([W1, B1, W2, B2]) :-
    W1 := parameter(glorot(1, 48)),  B1 := parameter(zeros([48])),
    W2 := parameter(glorot(48, 1)),  B2 := parameter(zeros([1])), !.

%% ---- the three goals ----------------------------------------------------------
%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(4),
    sine_data(X, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(3000, Ps0, St0, X, Y, Ps) },
    { Ps = [W1, B1, W2, B2] },
    L = item(loss(X, Y, W1, B1, W2, B2)),
    { format("trained: final mse ~4f~n", [L]) },
    params_save(t04_sine, Ps),
    { write(saved), nl }.

%% fit(+K, +Ps, +State, +X, +Y, -PsF): K full-batch steps of Adam at 0.01.
fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, X, Y, PsF) :-
    Ps = [W1, B1, W2, B2],
    L := loss(X, Y, W1, B1, W2, B2),
    Gs := grad(L, Ps),
    ( K mod 500 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    [W1, B1, W2, B2] = params(t04_sine),
    sine_data(X, Y),
    S = item(sqrt(loss(X, Y, W1, B1, W2, B2))),
    { format("rmse ~4f~n", [S]),
      ( S < 0.1 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    [W1, B1, W2, B2] = params(t04_sine),
    { Points = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0],
      findall([Xv], member(Xv, Points), Rows) },
    Out = list(net(Rows, W1, B1, W2, B2)),
    { forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
             ( Truth is sin(2 * pi * Xv),
               format("x ~2f  predicted ~3f  (sin says ~3f)~n", [Xv, Yhat, Truth]) )) }.
