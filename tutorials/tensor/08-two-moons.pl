%% 8. Two moons: a curved boundary through one relu layer
%%
%% The scikit-learn classic: two interleaved half-circles that no line can
%% split. Sixteen relu units carve the crescent boundary -- the network is
%% `relu(X matmul W1 + B1) matmul W2 + B2', two expressions -- and the loss
%% is cross_entropy over the logits against one-hot labels, the standard
%% pairing of log_softmax and the negative log-likelihood in one composite.
%% The fit is Adam from library(tensor_expr), full batch, 400 steps. (An
%% earlier version of this file was model_new's dense(16, relu) and
%% dense(2, log_softmax) under loss(nll); tutorials/library/22-torch.pl
%% still teaches that API.)
%%
%%   train    learn the moons, save as t08_moons
%%   test     reload, accuracy over the two arcs, pass at 90%
%%   predict  reload, classify a point deep inside each moon
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/08-two-moons.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/08-two-moons.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/08-two-moons.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the moons ----------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

% First 80 rows walk the upper moon, the next 80 the lower, both jittered.
moon_row(I, [A, B], L) :-
    T is pi * (I mod 80) / 79,
    noise(I, E1), noise(I + 700, E2),
    ( I < 80
    -> L = 0, A is cos(T) + 0.1 * E1,      B is sin(T) + 0.1 * E2
    ;  L = 1, A is 1 - cos(T) + 0.1 * E1,  B is 0.4 - sin(T) + 0.1 * E2 ), !.

%% moons(-X, -Classes): the 160 rows as a [160, 2] tensor, and their classes
%% as a list -- what one_hot/3 and accuracy/3 take.
moons(X, Classes) -->
    { findall(R, ( between(0, 159, I), moon_row(I, R, _) ), Rows),
      findall(L, ( between(0, 159, I), moon_row(I, _, L) ), Classes) },
    X = Rows, !.

moon_name(0, upper) :- !.
moon_name(1, lower) :- !.

%% ---- the network --------------------------------------------------------------

%% W1 is unit-variance randn rather than glorot: on a two-wide input glorot's
%% scale is sqrt(2/18), the sixteen relu bends start out nearly parallel, and
%% under one library's draws Adam settled for a one-kink boundary at 92%.
%% Wider starting weights spread the bends, and both libraries carve the crescent.
parameters([W1, B1, W2, B2]) :-
    W1 := parameter(randn([2, 16])), B1 := parameter(zeros([1, 16])),
    W2 := parameter(glorot(16, 2)), B2 := parameter(zeros([1, 2])), !.

%% forward(+Ps, +X, -Logits): the relu layer and the linear head -- a
%% PROCEDURE, a DCG rule of bindings; exec/1 runs it and frees H.
forward([W1, B1, W2, B2], X, Logits) -->
    H = relu(X matmul W1 + B1),
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
    seed(8),
    moons(X, Classes), one_hot(Classes, 2, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(400, Ps0, St0, X, Y, Ps) },
    forward(Ps, X, Logits), accuracy(Logits, Classes, Acc),
    L = item(cross_entropy(Logits, Y)),
    { format("trained: cross-entropy ~4f, accuracy on the 160 training rows ~2f~n", [L, Acc]) },
    params_save(t08_moons, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, X, Y, PsF) :-
    exec(forward(Ps, X, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 100 =:= 0 -> Lv := item(L), format("   ~w steps to go, cross-entropy ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.02, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    Ps = params(t08_moons),
    moons(X, Classes),
    forward(Ps, X, Logits), accuracy(Logits, Classes, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("accuracy ~w%~n", [Pct]),
      ( Pct >= 90 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

%% predict: a point deep inside each moon, and two more, each with the moon
%% it was drawn from.
predict -->
    Ps = params(t08_moons),
    { Points = [[0.0, 1.0]-upper, [1.0, -0.6]-lower, [-1.0, 0.0]-upper, [2.0, 0.4]-lower],
      findall(R, member(R-_, Points), Rows) },
    X = Rows,
    forward(Ps, X, Logits),
    Got = list(argmax(Logits, 1)),
    { forall(( nth0(I, Got, G), nth0(I, Points, [A, B]-Truth) ),
             ( C is round(G), moon_name(C, Name),
               format("(~2f, ~2f) is in the ~w moon  (it is ~w)~n", [A, B, Name, Truth]) )) }.
