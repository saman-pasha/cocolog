%% 5. Function approximation: a gaussian bump through relu layers
%%
%% The counterpart of tutorial 4: relu units are hinges, and two layers of
%% them assemble a piecewise-linear tent that hugs exp(-4 x^2). Depth is
%% doing the work here that tanh smoothness did there -- one relu layer
%% needs many more units for the same curve than two need together. The
%% network is one defined function, two relu layers and a linear head,
%%
%%     net(X, Ps) ::= relu(relu(X matmul W1 + B1) matmul W2 + B2) matmul W3 + B3.
%%
%% six parameters stepped by Adam. An earlier version of this file used
%% model_new and model_train; that API is still taught in
%% tutorials/library/22-torch.pl.
%%
%%   train    fit the bump, save the parameters as t05_bump
%%   test     reload, rmse over [-2, 2], pass under 0.1
%%   predict  reload, sample the tent beside the true bump
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/05-relu-approximation.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/05-relu-approximation.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/05-relu-approximation.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the data ---------------------------------------------------------------
%% Every predicate ends in a cut: the store keeps every consult, and a
%% generator without one would answer once per copy.

bump_row(I, [X], [Y]) :- X is -2 + 4 * I / 159, Y is exp(-4 * X * X), !.

%% bump_data(-X, -Y): 160 points over [-2, 2], [160, 1] each.
bump_data(X, Y) -->
    { findall(R, (between(0, 159, I), bump_row(I, R, _)), XR),
      findall(R, (between(0, 159, I), bump_row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the network ------------------------------------------------------------
%% The network takes its parameter LIST, so the loop and the goals pass the
%% six around as one thing; the loss is the network's distance from the samples.

net(X, [W1, B1, W2, B2, W3, B3]) ::=
    relu(relu(X matmul W1 + B1) matmul W2 + B2) matmul W3 + B3.
loss(X, Y, Ps) ::= mse(net(X, Ps), Y).

%% a PREDICATE, not a rule: the optimiser frees these, and a rule must not
%% emit what something else frees.
parameters([W1, B1, W2, B2, W3, B3]) :-
    W1 := parameter(glorot(1, 24)),   B1 := parameter(zeros([24])),
    W2 := parameter(glorot(24, 24)),  B2 := parameter(zeros([24])),
    W3 := parameter(glorot(24, 1)),   B3 := parameter(zeros([1])), !.

%% ---- the three goals ----------------------------------------------------------
%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(5),
    bump_data(X, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(2000, Ps0, St0, X, Y, Ps) },
    L = item(loss(X, Y, Ps)),
    { format("trained: final mse ~4f~n", [L]) },
    params_save(t05_bump, Ps),
    { write(saved), nl }.

%% fit(+K, +Ps, +State, +X, +Y, -PsF): K full-batch steps of Adam at 0.02.
fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, X, Y, PsF) :-
    L := loss(X, Y, Ps),
    Gs := grad(L, Ps),
    ( K mod 500 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.02, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    Ps = params(t05_bump),
    bump_data(X, Y),
    S = item(sqrt(loss(X, Y, Ps))),
    { format("rmse ~4f~n", [S]),
      ( S < 0.1 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    Ps = params(t05_bump),
    { Points = [-2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0],
      findall([Xv], member(Xv, Points), Rows) },
    Out = list(net(Rows, Ps)),
    { forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
             ( Truth is exp(-4 * Xv * Xv),
               format("x ~2f  predicted ~3f  (bump says ~3f)~n", [Xv, Yhat, Truth]) )) }.
