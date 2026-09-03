%% 29. SGD by hand
%%
%% Every earlier tutorial hands its training loop to model_train/4, whose
%% loop is C++. This one writes the loop in Prolog -- forward, loss,
%% gradient, step -- and writes it the way every tutorial from here on
%% writes its numbers: as TENSOR EXPRESSIONS, library(tensor_expr). The loss
%% is one defined function,
%%
%%     loss(X, Y, W, B) ::= mean((X matmul W + B - Y) ^ 2.0).
%%
%% the gradient is an answer, `[GW, GB] = grad(L, [W, B])', and the step is
%% a function, `W2 = step(W, GW, LR)', which makes a NEW parameter -- nothing
%% is ever overwritten. Behind the three lines stand the module's own
%% predicates, and `train' prints them: the grammar turns the loss into
%% tensor_binary/4 and tensor_agg/3 -- a one-element TENSOR, because a number
%% cannot be differentiated -- grad into tensor_grad/3, which asks libtorch's
%% autograd, and step into tensor_step/4. The five goals a hand would have
%% written are still there, in the list.
%%
%% THE STEP IS A PROCEDURE, a DCG rule of bindings; exec/1 runs it and frees
%% what it made and did not return. THE LOOP IS A PREDICATE: it threads the
%% parameters through a recursion, the way a Prolog program threads
%% anything, and frees the old pair each round -- the one thing a rule may
%% not do, and the reason a loop of hundreds of steps is written this way
%% rather than as a rule (tutorial 31 shows the other way, on six rows).
%% Nothing here names the execution path or the library: the same file runs
%% under tensor_execution(eager) and tensor_execution(graph) with identical
%% numbers (ALL=1 sh test/torch-graph.sh checks), and under
%% tensor_execution(tensorflow, graph) on the second backend, from outside:
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/29-sgd-by-hand.pl "tensor_execution(graph), train"
%%
%% The learned parameters are saved with params_save/2, so `test' and
%% `predict' are the usual two processes against the store, reloading them
%% with `[W, B] = params(t29_sgd)'.
%%
%%   train    fit y = 3 x1 - 2 x2 + 0.5 x3 + 1 by 300 steps of plain SGD, save as t29_sgd
%%   test     reload the parameters, rmse on fresh rows, pass under 0.05
%%   predict  reload the parameters, answer for three rows beside the truth
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/29-sgd-by-hand.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/29-sgd-by-hand.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/29-sgd-by-hand.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the program ---------------------------------------------------------------
%% THE LOSS IS A DEFINED FUNCTION: a clause `Head ::= Body', used by name in
%% any expression. mean(...) is tensor_agg, not tensor_reduce: a tensor of
%% one element, so it differentiates.

loss(X, Y, W, B) ::= mean((X matmul W + B - Y) ^ 2.0).

% Deterministic "random" numbers in (-1, 1): the sin-hash the other
% tutorials use, so every process sees the same rows with no files.
noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

% One row: three inputs, and the plane plus a little noise.
row(I, [X1, X2, X3], [Y]) :-
    noise(I, X1), J is I + 1000, noise(J, X2), K is I + 2000, noise(K, X3),
    M is I + 3000, noise(M, E),
    Y is 3*X1 - 2*X2 + 0.5*X3 + 1 + 0.02*E, !.

% Rows From .. From+N-1 as two tensors, [N,3] and [N,1] -- a rule, so the
% two leaves it makes are in the caller's list.
data(From, N, X, Y) -->
    { To is From + N - 1,
      findall(R, (between(From, To, I), row(I, R, _)), XR),
      findall(R, (between(From, To, I), row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ONE STEP OF SGD, IN PROLOG -- a procedure. The loss, its value, the two
%% gradients, and the two new leaves; exec/1 frees L, GW and GB when the
%% step returns and keeps W2 and B2, which the head names. The old W and B
%% came in, so they are the caller's.
step(X, Y, W, B, LR, W2, B2, Loss) -->
    L = loss(X, Y, W, B),
    Loss = item(L),
    [GW, GB] = grad(L, [W, B]),
    W2 = step(W, GW, LR),
    B2 = step(B, GB, LR).

%% K STEPS, THREADING THE PARAMETERS -- a predicate, and this is why: each
%% round frees the pair it stepped from, so 300 steps hold two parameters
%% at a time instead of six hundred, and a rule frees nothing. Answers the
%% last loss.
sgd(0, _, _, W, B, _, W, B, Loss, Loss) :- !.
sgd(K, X, Y, W, B, LR, WF, BF, _, LossF) :-
    exec(step(X, Y, W, B, LR, W2, B2, Loss)),
    free_all([W, B]),
    K1 is K - 1,
    sgd(K1, X, Y, W2, B2, LR, WF, BF, Loss, LossF).

%% fit(+X, +Y, +Features, +Steps, +LR, -W, -B, -Loss): the parameters are
%% made here, where the loop that frees them lives, from zeros -- so the
%% fit has no random start and needs no seed.
fit(X, Y, Features, Steps, LR, W, B, Loss) :-
    W0 := parameter(zeros([Features, 1])),
    B0 := parameter(zeros([1])),
    sgd(Steps, X, Y, W0, B0, LR, W, B, none, Loss), !.

%% ---- the three goals -------------------------------------------------------------
%% Each is a rule run by exec/1 through the one-liner the runner calls, so
%% every tensor a goal makes is freed when it ends; the fit is in braces,
%% being a predicate, and the parameters it answers are saved.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    data(0, 128, X, Y),
    { fit(X, Y, 3, 300, 0.3, W, B, Loss),
      % the expression, and the goals the grammar makes of it: the five
      % predicates this loop was once written with, by hand
      phrase(expr(loss(X, Y, W, B), _), Goals),
      format("the loss, as goals: ~w~n", [Goals]),
      format("trained: final mse ~6f~n", [Loss]) },
    [[W1], [W2], [W3]] = list(W),
    [Bv] = list(B),
    { format("w ~4f ~4f ~4f  b ~4f  (the plane says 3 -2 0.5  1)~n", [W1, W2, W3, Bv]) },
    params_save(t29_sgd, [W, B]),
    { write(saved), nl }.

test -->
    [W, B] = params(t29_sgd),
    % fresh rows from the same plane, not the training set
    data(5000, 64, X, Y),
    S = item(sqrt(loss(X, Y, W, B))),                        % the rmse, through the defined loss
    { format("test rmse ~4f~n", [S]),
      ( S < 0.05 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    [W, B] = params(t29_sgd),
    data(9000, 3, X, Y),
    Xs = list(X), Ys = list(Y),
    Ps = list(X matmul W + B),
    { forall(( nth0(I, Xs, [X1, X2, X3]), nth0(I, Ys, [Truth]), nth0(I, Ps, [Yhat]) ),
             format("x ~5f ~5f ~5f  predicted ~4f  (plane says ~4f)~n",
                    [X1, X2, X3, Yhat, Truth])) }.

%% ---- heavy: the same loop on far more data ---------------------------------------
%% HEAVY: the same loop on data generated as tensors rather than rows --
%% Rows x Features inputs, a hidden plane with Features weights, a little
%% noise -- so the matmuls are worth a GPU's while. Not one of the three
%% goals the runner drives; it is the workload test/torch-replay.sh times on
%% the Colab T4 against the VM's own CPUs, and it prints how far the learned
%% weights sit from the plane, which more rows pull closer. The path and the
%% device come from outside, as a goal prefix:
%%
%%   ./cocolog run tutorials/tensor/29-sgd-by-hand.pl "heavy(20000, 32, 200)"
%%   ./cocolog run tutorials/tensor/29-sgd-by-hand.pl "tensor_execution(torch, graph, cuda), heavy(200000, 64, 200)"
%%
%% A GPU WORKLOAD, like tutorial 28's: with no CUDA device here the rows are
%% capped at 20000 and the steps at 100, and the run says so; a machine that
%% has a GPU but was told the cpu runs what it was given. The cap is the
%% predicate's, the work is the rule's.
heavy(Rows0, Features, Steps0) :-
    (   torch_cuda_available(false), ( Rows0 > 20000 ; Steps0 > 100 )
    ->  Rows is min(Rows0, 20000), Steps is min(Steps0, 100),
        format("heavy: no CUDA device here -- running heavy(~w, ~w, ~w) instead of heavy(~w, ~w, ~w); the full run wants a GPU~n",
               [Rows, Features, Steps, Rows0, Features, Steps0])
    ;   Rows = Rows0, Steps = Steps0 ),
    exec(heavy(Rows, Features, Steps)), !.

heavy(Rows, Features, Steps) -->
    seed(29),
    X = randn([Rows, Features]),
    WT = randn([Features, 1]) * 2.0,                            % the plane's weights
    Y = X matmul WT + 1.0 + randn([Rows, 1]) * 0.1,             % ... its bias, 1, and the noise
    { fit(X, Y, Features, Steps, 0.05, W, B, Loss) },
    WErr = reduce(max, abs(W - WT)),
    [Bv] = list(B), { BErr is abs(Bv - 1) },
    torch_current_device(D),
    % the path is ASKED, so it is asked in braces: as a nonterminal with Mode
    % unbound, tensor_execution(Mode, S0, S) is the module's tensor_execution/3
    { tensor_execution(Mode) },
    { format("heavy ~w rows ~w features ~w steps on ~w under ~w: final mse ~6f, max |w - plane| ~6f, |b - 1| ~6f~n",
             [Rows, Features, Steps, D, Mode, Loss, WErr, BErr]) }.
