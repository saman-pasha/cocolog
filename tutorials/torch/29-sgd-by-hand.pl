%% 29. SGD by hand
%%
%% Every earlier tutorial hands its training loop to model_train/4, whose
%% loop is C++. This one writes the loop in Prolog: forward, loss, gradient,
%% step. tensor_grad/3 asks libtorch's autograd for the gradient of a loss
%% the program itself built out of tensor_binary/4 and tensor_agg/3, and
%% tensor_step/4 answers a NEW parameter -- nothing is ever overwritten. The
%% parameters are threaded through a recursion, the way a Prolog program
%% threads anything, and the same file runs under torch_execution(eager) and
%% torch_execution(graph) with identical numbers (test/torch-graph.sh checks).
%%
%% The learned weights are then handed to a one-layer model through
%% model_set_params/2 and saved, so `test' and `predict' are the usual two
%% processes against the store, and the model they reload is one no
%% model_train ever saw.
%%
%%   train    fit y = 3 x1 - 2 x2 + 0.5 x3 + 1 by 300 steps of plain SGD, save as t29_sgd
%%   test     reload the model, rmse on fresh rows, pass under 0.05
%%   predict  reload the model, answer for three rows beside the truth
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/29-sgd-by-hand.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/29-sgd-by-hand.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/29-sgd-by-hand.pl predict

:- use_module(library(torch)).

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

% Rows From .. From+N-1 as two tensors, [N,3] and [N,1].
data(From, N, X, Y) :-
    To is From + N - 1,
    findall(R, (between(From, To, I), row(I, R, _)), XR),
    findall(R, (between(From, To, I), row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.

% ONE STEP OF SGD, IN PROLOG. The forward pass is two tensor ops, the loss is
% mean((XW + B - Y)^2) as a one-element TENSOR -- tensor_agg/3 rather than
% tensor_reduce/3, because a number cannot be differentiated -- and
% tensor_grad/3 answers d Loss / d W and d Loss / d B. tensor_step/4 makes
% the next W and B as fresh leaves; the old ones are freed, along with every
% intermediate, so 300 steps do not fill the handle table.
step(X, Y, W, B, LR, W2, B2, Loss) :-
    tensor_binary(matmul, X, W, XW),
    tensor_binary(add, XW, B, P),
    tensor_binary(sub, P, Y, D),
    tensor_binary(mul, D, D, D2),
    tensor_agg(mean, D2, L),
    tensor_item(L, Loss),
    tensor_grad(L, [W, B], [GW, GB]),
    tensor_step(W, GW, LR, W2),
    tensor_step(B, GB, LR, B2),
    tensor_free(XW), tensor_free(P), tensor_free(D), tensor_free(D2),
    tensor_free(L), tensor_free(GW), tensor_free(GB),
    tensor_free(W), tensor_free(B).

% K steps, threading the parameters; answers the last loss.
sgd(0, _, _, W, B, _, W, B, Loss, Loss) :- !.
sgd(K, X, Y, W, B, LR, WF, BF, _, LossF) :-
    step(X, Y, W, B, LR, W2, B2, Loss),
    K1 is K - 1,
    sgd(K1, X, Y, W2, B2, LR, WF, BF, Loss, LossF).

train :-
    data(0, 128, X, Y),
    tensor_zeros([3, 1], W0), tensor_parameter(W0, W),
    tensor_zeros([1], B0),    tensor_parameter(B0, B),
    sgd(300, X, Y, W, B, 0.3, WF, BF, none, Loss),
    format("trained: final mse ~6f~n", [Loss]),
    tensor_to_list(WF, [[W1], [W2], [W3]]),
    tensor_to_list(BF, [Bv]),
    format("w ~4f ~4f ~4f  b ~4f  (the plane says 3 -2 0.5  1)~n", [W1, W2, W3, Bv]),
    % the weights become a model: dense(1) from input(3) holds four numbers,
    % the weight row first and then the bias, which is model_params' order
    model_new([input(3), dense(1)], M),
    model_set_params(M, [W1, W2, W3, Bv]),
    model_save(t29_sgd, M),
    write(saved), nl.

test :-
    model_load(t29_sgd, M),
    % fresh rows from the same plane, not the training set
    data(5000, 64, X, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("test rmse ~4f~n", [S]),
    ( S < 0.05 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

%% HEAVY: the same loop on far more data, generated as tensors rather than
%% rows -- Rows x Features inputs, a hidden plane with Features weights, a
%% little noise -- so the matmuls are worth a GPU's while. Not one of the
%% three goals the runner drives; it is the workload test/torch-replay.sh
%% times on the Colab T4 against the VM's own CPUs, and it prints how far the
%% learned weights sit from the plane, which more rows pull closer.
%%
%%   ./cocolog run tutorials/torch/29-sgd-by-hand.pl "heavy(20000, 32, 200)"
%%   ./cocolog run tutorials/torch/29-sgd-by-hand.pl "torch_device(cuda), heavy(200000, 64, 200)"
%% A GPU WORKLOAD, like tutorial 28's: with no CUDA device here the rows are
%% capped at 20000 and the steps at 100, and the run says so; a machine that
%% has a GPU but was told torch_device(cpu) runs what it was given.
heavy(Rows0, Features, Steps0) :-
    (   torch_cuda_available(false), ( Rows0 > 20000 ; Steps0 > 100 )
    ->  Rows is min(Rows0, 20000), Steps is min(Steps0, 100),
        format("heavy: no CUDA device here -- running heavy(~w, ~w, ~w) instead of heavy(~w, ~w, ~w); the full run wants a GPU~n",
               [Rows, Features, Steps, Rows0, Features, Steps0])
    ;   Rows = Rows0, Steps = Steps0 ),
    torch_seed(29),
    tensor_randn([Rows, Features], X),
    tensor_randn([Features, 1], WT0), tensor_scalar(mul, WT0, 2.0, WT),   % the plane's weights
    tensor_binary(matmul, X, WT, Y0),
    tensor_scalar(add, Y0, 1.0, Y1),                                       % ... and its bias, 1
    tensor_randn([Rows, 1], E0), tensor_scalar(mul, E0, 0.1, E),
    tensor_binary(add, Y1, E, Y),
    tensor_zeros([Features, 1], W0), tensor_parameter(W0, W),
    tensor_zeros([1], B0), tensor_parameter(B0, B),
    sgd(Steps, X, Y, W, B, 0.05, WF, BF, none, Loss),
    tensor_binary(sub, WF, WT, DW), tensor_unary(abs, DW, ADW), tensor_reduce(max, ADW, WErr),
    tensor_to_list(BF, [Bv]), BErr is abs(Bv - 1),
    torch_current_device(D), torch_execution(Mode),
    format("heavy ~w rows ~w features ~w steps on ~w under ~w: final mse ~6f, max |w - plane| ~6f, |b - 1| ~6f~n",
           [Rows, Features, Steps, D, Mode, Loss, WErr, BErr]).

predict :-
    model_load(t29_sgd, M),
    data(9000, 3, X, Y),
    model_predict(M, X, P),
    tensor_to_list(X, Xs), tensor_to_list(Y, Ys), tensor_to_list(P, Ps),
    forall(( nth0(I, Xs, [X1, X2, X3]), nth0(I, Ys, [Truth]), nth0(I, Ps, [Yhat]) ),
           format("x ~5f ~5f ~5f  predicted ~4f  (plane says ~4f)~n",
                  [X1, X2, X3, Yhat, Truth])).
