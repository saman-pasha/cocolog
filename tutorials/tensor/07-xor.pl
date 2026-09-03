%% 7. XOR: the network that needs its hidden layer
%%
%% The historical one. No line separates xor's classes, so a single linear
%% unit CANNOT learn it -- the fact that stalled neural networks for a
%% generation -- and one small tanh layer settles it. The network is two
%% expressions, `H = tanh(X matmul W1 + B1)' and `Logits = H matmul W2 + B2';
%% the loss is cross_entropy over the logits against one-hot labels --
%% log_softmax and the negative log-likelihood folded into one composite,
%% the standard classification pairing -- and `Gs := grad(L, Ps)'
%% differentiates the lot. The fit is Adam from library(tensor_expr), full
%% batch, 300 steps. (An earlier version of this file built the same
%% network as model_new's dense(8, tanh) and dense(2, log_softmax);
%% tutorials/library/22-torch.pl still teaches that API.)
%%
%%   train    learn xor from 128 jittered corner points, save as t07_xor
%%   test     reload, the four CLEAN corners must all be right
%%   predict  reload, show the class and confidence at each corner
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/07-xor.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/07-xor.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/07-xor.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).

%% ---- the points ---------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

xor_point(I, [A, B], L) :-
    Q is I mod 4,
    ( Q =:= 0 -> A0 = 0, B0 = 0, L = 0
    ; Q =:= 1 -> A0 = 0, B0 = 1, L = 1
    ; Q =:= 2 -> A0 = 1, B0 = 0, L = 1
    ; A0 = 1, B0 = 1, L = 0 ),
    noise(I, E1), noise(I + 300, E2),
    A is A0 + 0.05 * E1, B is B0 + 0.05 * E2, !.

%% points(+From, +N, -X, -Classes): N jittered corners as an [N, 2] tensor,
%% and their classes as a list -- what one_hot/3 and accuracy/3 take.
points(From, N, X, Classes) -->
    { To is From + N - 1,
      findall(R, ( between(From, To, I), xor_point(I, R, _) ), Rows),
      findall(L, ( between(From, To, I), xor_point(I, _, L) ), Classes) },
    X = Rows, !.

corners([[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]], [0, 1, 1, 0]) :- !.

%% ---- the network --------------------------------------------------------------

parameters([W1, B1, W2, B2]) :-
    W1 := parameter(glorot(2, 8)), B1 := parameter(zeros([1, 8])),
    W2 := parameter(glorot(8, 2)), B2 := parameter(zeros([1, 2])), !.

%% forward(+Ps, +X, -Logits): the hidden tanh layer and the linear head -- a
%% PROCEDURE, a DCG rule of bindings; exec/1 runs it and frees H.
forward([W1, B1, W2, B2], X, Logits) -->
    H = tanh(X matmul W1 + B1),
    Logits = H matmul W2 + B2.

%% ---- the three goals ----------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls, so every tensor a goal makes is freed when it ends. The fit loop
%% stays a predicate in braces: it steps an optimiser, which frees the old
%% parameters itself, and a rule must not emit what something else frees.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(7),
    points(0, 128, X, Classes), one_hot(Classes, 2, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(300, Ps0, St0, X, Y, Ps) },
    forward(Ps, X, Logits), accuracy(Logits, Classes, Acc),
    L = item(cross_entropy(Logits, Y)),
    { format("trained: cross-entropy ~4f, accuracy on the 128 training points ~2f~n", [L, Acc]) },
    params_save(t07_xor, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, X, Y, PsF) :-
    exec(forward(Ps, X, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 100 =:= 0 -> Lv := item(L), format("   ~w steps to go, cross-entropy ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.05, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    Ps = params(t07_xor),
    { corners(Rows, Classes) }, X = Rows,
    forward(Ps, X, Logits), accuracy(Logits, Classes, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("corners right ~w%~n", [Pct]),
      ( Pct =:= 100 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    Ps = params(t07_xor),
    { corners(Rows, Classes) }, X = Rows,
    forward(Ps, X, Logits),
    Probs = list(softmax(Logits)),
    { forall(( nth0(I, Probs, [P0, P1]), nth0(I, Rows, [A, B]), nth0(I, Classes, Truth) ),
             ( ( P1 > P0 -> C = 1, Conf = P1 ; C = 0, Conf = P0 ),
               format("xor(~0f, ~0f) = ~w  (confidence ~2f; the truth is ~w)~n", [A, B, C, Conf, Truth]) )) }.
