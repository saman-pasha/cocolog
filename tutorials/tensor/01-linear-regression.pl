%% 1. Linear regression
%%
%% The first network of every tutorial: one weight and one bias recover the
%% line y = 3x - 2 from noisy samples. In PyTorch this is nn.Linear(1, 1),
%% an MSELoss and an SGD loop; here the network is ONE EXPRESSION,
%%
%%     loss(X, Y, W, B) ::= mse(X matmul W + B, Y).
%%
%% and the loop is four lines: the loss, its gradient, an sgd_step, and the
%% count. Nothing here is a layer of the torch module -- W and B are two
%% parameters made with parameter(...), `Gs := grad(L, [W, B])'
%% differentiates the expression, and sgd_step/4 answers NEW parameters,
%% freeing the old ones. An earlier version of this file used model_new and
%% model_train; that API is still taught in tutorials/library/22-torch.pl.
%%
%% The three goals, each meant to be its OWN PROCESS against the same store,
%% because trained parameters are terms in the knowledge base, not memory:
%%
%%   train    build the data, fit the line, save the parameters as t01_linreg
%%   test     reload them, measure rmse on fresh points, pass under 0.15
%%   predict  reload them, answer for a few x values beside the truth
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/01-linear-regression.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/01-linear-regression.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/01-linear-regression.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the data ---------------------------------------------------------------
%% Deterministic noise in (-1, 1): the classic sin-hash. Every run sees the
%% same "random" data, so train and test agree across processes with no files.
%% EVERY PREDICATE HERE ENDS IN A CUT: a `run' consults this file into the
%% store, the store keeps every consult, and a generator without a cut would
%% answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

%% One sample: x evenly over [-1, 1], y on the line plus a little noise.
lin_row(I, N, [X], [Y]) :-
    N1 is N - 1,
    X is -1 + 2 * I / N1,
    noise(I, E),
    Y is 3 * X - 2 + 0.05 * E, !.

%% lin_data(+N, -X, -Y): N rows as two tensors, [N, 1] each -- a PROCEDURE,
%% a DCG rule whose `X = Rows' binding makes the tensor and emits it.
lin_data(N, X, Y) -->
    { N1 is N - 1,
      findall(R, (between(0, N1, I), lin_row(I, N, R, _)), XR),
      findall(R, (between(0, N1, I), lin_row(I, N, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the network ------------------------------------------------------------
%% THE LOSS IS A DEFINED FUNCTION, a clause `Head ::= Body' used by name in
%% any expression: the line, and the mean squared distance from the samples.

loss(X, Y, W, B) ::= mse(X matmul W + B, Y).

%% parameters(-Ps): a random start for the weight, zero for the bias -- a
%% PREDICATE, not a rule, because the optimiser will free these and a rule
%% must not emit what something else frees.
parameters([W, B]) :-
    W := parameter(randn([1, 1])),
    B := parameter(zeros([1])), !.

%% ---- the three goals ----------------------------------------------------------
%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls: every tensor a goal makes is freed when it ends. The fit loop stays
%% a predicate, in braces: it steps an optimiser, which frees the old
%% parameters itself, and a rule must not emit what something else frees.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(1),
    lin_data(64, X, Y),
    { parameters(Ps0), fit(200, Ps0, X, Y, [W, B]) },
    L = item(loss(X, Y, W, B)),
    [[Wv]] = list(W), [Bv] = list(B),
    { format("trained: final mse ~4f  w ~3f  b ~3f~n", [L, Wv, Bv]) },
    params_save(t01_linreg, [W, B]),
    { write(saved), nl }.

%% fit(+K, +Ps, +X, +Y, -PsF): K steps of full-batch gradient descent at
%% learning rate 0.2. sgd_step/4 answers new parameters and frees the old
%% ones and the gradients; the loss is the one handle this loop frees itself.
fit(0, Ps, _, _, Ps) :- !.
fit(K, [W, B], X, Y, PsF) :-
    L := loss(X, Y, W, B),
    Gs := grad(L, [W, B]),
    ( K mod 50 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~4f~n", [K, Lv]) ; true ),
    sgd_step([W, B], Gs, 0.2, Ps2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, X, Y, PsF).

test -->
    [W, B] = params(t01_linreg),
    % fresh points from the same law, not the training set
    lin_data(40, X, Y),
    S = item(sqrt(loss(X, Y, W, B))),
    { format("test rmse ~4f~n", [S]),
      ( S < 0.15 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    [W, B] = params(t01_linreg),
    { Points = [-1.0, 0.0, 0.5, 1.0], findall([Xv], member(Xv, Points), Rows) },
    Out = list(Rows matmul W + B),
    { forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
             ( Truth is 3 * Xv - 2,
               format("x ~2f  predicted ~2f  (line says ~2f)~n", [Xv, Yhat, Truth]) )) }.
