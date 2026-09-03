%% 10. A three-arm spiral: depth, and raw logits under cross_entropy
%%
%% The spiral is the classic "you need depth" dataset: three interleaved
%% arms that a single hidden layer struggles to unwind. Two relu layers do
%% it comfortably, three expressions deep. The head is BARE -- `H2 matmul W3
%% + B3', raw logits -- because cross_entropy applies its own log_softmax
%% inside, exactly as PyTorch's nn.CrossEntropyLoss does: the composite is
%% `-mean(sum(OneHot * log_softmax(Logits)))'. Writing
%% `cross_entropy(log_softmax(Logits), Y)' is the double-softmax mistake --
%% it trains, slowly, to a loss that cannot reach zero -- and this file is
%% the reminder. The fit is Adam from library(tensor_expr), full batch, 600
%% steps. (An earlier version of this file was model_new's three dense
%% layers under loss(cross_entropy); tutorials/library/22-torch.pl still
%% teaches that API.)
%%
%%   train    unwind the arms, save as t10_spiral
%%   test     reload, accuracy along the spiral, pass at 85%
%%   predict  reload, walk one arm outward and watch the class hold
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/10-spiral.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/10-spiral.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/10-spiral.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).

%% ---- the spiral ---------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

spiral_row(I, [A, B], L) :-
    L is I mod 3,
    K is I // 3,
    T is 0.4 + 3.5 * K / 59,
    Phi is T + L * 2 * pi / 3,
    noise(I, E1), noise(I + 1100, E2),
    A is 0.25 * T * cos(Phi) + 0.02 * E1,
    B is 0.25 * T * sin(Phi) + 0.02 * E2, !.

%% spiral(-X, -Classes): the 180 rows as a [180, 2] tensor, and their arms
%% 0..2 as a list -- what one_hot/3 and accuracy/3 take.
spiral(X, Classes) -->
    { findall(R, ( between(0, 179, I), spiral_row(I, R, _) ), Rows),
      findall(L, ( between(0, 179, I), spiral_row(I, _, L) ), Classes) },
    X = Rows, !.

%% ---- the network --------------------------------------------------------------

parameters([W1, B1, W2, B2, W3, B3]) :-
    W1 := parameter(glorot(2, 32)),  B1 := parameter(zeros([1, 32])),
    W2 := parameter(glorot(32, 32)), B2 := parameter(zeros([1, 32])),
    W3 := parameter(glorot(32, 3)),  B3 := parameter(zeros([1, 3])), !.

%% forward(+Ps, +X, -Logits): two relu layers and the bare head -- a
%% PROCEDURE, a DCG rule of bindings; exec/1 runs it and frees H1 and H2.
forward([W1, B1, W2, B2, W3, B3], X, Logits) -->
    H1 = relu(X matmul W1 + B1),
    H2 = relu(H1 matmul W2 + B2),
    Logits = H2 matmul W3 + B3.

%% ---- the three goals ----------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls, so every tensor a goal makes is freed when it ends. The fit loop
%% stays a predicate in braces: it steps an optimiser, which frees the old
%% parameters itself, and a rule must not emit what something else frees.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(10),
    spiral(X, Classes), one_hot(Classes, 3, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(600, Ps0, St0, X, Y, Ps) },
    forward(Ps, X, Logits), accuracy(Logits, Classes, Acc),
    L = item(cross_entropy(Logits, Y)),
    { format("trained: cross-entropy ~4f, accuracy on the 180 training rows ~2f~n", [L, Acc]) },
    params_save(t10_spiral, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, X, Y, PsF) :-
    exec(forward(Ps, X, Logits)),
    L := cross_entropy(Logits, Y),                    % the logits, bare: the log_softmax is inside
    Gs := grad(L, Ps),
    ( K mod 200 =:= 0 -> Lv := item(L), format("   ~w steps to go, cross-entropy ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    Ps = params(t10_spiral),
    spiral(X, Classes),
    forward(Ps, X, Logits), accuracy(Logits, Classes, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("accuracy ~w%~n", [Pct]),
      ( Pct >= 85 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

%% predict: five points outward along arm 0, clean -- the class must hold.
predict -->
    Ps = params(t10_spiral),
    { findall([A, B], ( member(T, [0.5, 1.2, 2.0, 2.8, 3.6]),
                        A is 0.25 * T * cos(T), B is 0.25 * T * sin(T) ), Rows) },
    X = Rows,
    forward(Ps, X, Logits),
    Got = list(argmax(Logits, 1)),
    { forall(( nth0(I, Got, G), nth0(I, Rows, [A, B]) ),
             ( C is round(G),
               format("(~2f, ~2f) on arm ~w  (it is arm 0)~n", [A, B, C]) )) }.
