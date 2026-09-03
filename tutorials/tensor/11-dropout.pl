%% 11. Dropout, and the train/eval mode split
%%
%% Dropout at 0.3 silences a random third of a layer's units EVERY TRAINING
%% STEP, which fights co-adaptation -- and must switch itself off the moment
%% the network answers for real. As expressions, dropout is a MASK: rand(S)
%% is uniform on [0, 1), so `rand(S) - Rate' is positive for a fraction
%% 1 - Rate of the units, and a very steep ramp clamped to [0, 1] by two
%% relus turns that sign into a 0 or a 1. The survivors are scaled by
%% 1/(1 - Rate) so the expected activation is unchanged -- inverted
%% dropout, as PyTorch does it -- and the evaluation pass needs no scaling
%% at all. THE SWITCH IS WHICH EXPRESSION THE FORWARD PASS IS GIVEN:
%% dropout(H, S, Rate, train) multiplies by a fresh mask, dropout(H, _, _,
%% eval) is H, and there is no mode bit anywhere to forget. `test' still
%% proves it the way it always did: two evaluation passes over the same
%% rows must agree to the last bit, which they could not if a mask were
%% still being drawn. (An earlier version of this file was model_new's
%% dropout(0.3) layers, with the switch inside model_predict;
%% tutorials/library/22-torch.pl still teaches that API.)
%%
%%   train    learn the moons through dropout, save as t11_dropout
%%   test     reload; accuracy at 85%, and two predicts must be identical
%%   predict  reload, classify a few points (deterministically)
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/11-dropout.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/11-dropout.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/11-dropout.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the moons ----------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

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

rows_close([], []) :- !.
rows_close([A|As], [B|Bs]) :- row_close(A, B), rows_close(As, Bs), !.
row_close([], []) :- !.
row_close([A|As], [B|Bs]) :- D is abs(A - B), D < 1.0e-6, row_close(As, Bs), !.

%% ---- dropout, as expressions -------------------------------------------------
%% keep(S, Rate): a mask of shape S, 1.0 where a unit survives and 0.0 where
%% it is dropped. rand(S) - Rate is positive with probability 1 - Rate; the
%% ramp `* 1.0e6' makes the sign enormous and the two relus clamp it to
%% [0, 1] -- relu(A) cuts below 0, 1 - relu(1 - A) cuts above 1 -- so what
%% remains is a step: 0.0 or 1.0, except within a millionth of the rate.
keep(S, Rate) ::= 1.0 - relu(1.0 - relu((rand(S) - Rate) * 1.0e6)).

%% dropout(H, S, Rate, Mode): the two clauses ARE the mode split. Under
%% `train' a fresh mask is drawn and the survivors scaled by 1/(1 - Rate);
%% under `eval' the layer's output passes through, and nothing is random.
dropout(H, S, Rate, train) ::= H * keep(S, Rate) / (1.0 - Rate).
dropout(H, _, _, eval) ::= H.

%% ---- the network --------------------------------------------------------------

parameters([W1, B1, W2, B2, W3, B3]) :-
    W1 := parameter(glorot(2, 32)),  B1 := parameter(zeros([1, 32])),
    W2 := parameter(glorot(32, 32)), B2 := parameter(zeros([1, 32])),
    W3 := parameter(glorot(32, 2)),  B3 := parameter(zeros([1, 2])), !.

%% forward(+Ps, +X, +N, +Mode, -Logits): two relu layers, each followed by
%% dropout at 0.3 -- masks of [N, 32] under `train', nothing under `eval' --
%% and the linear head. A PROCEDURE, a DCG rule of bindings; exec/1 runs it
%% and frees H1 and H2.
forward([W1, B1, W2, B2, W3, B3], X, N, Mode, Logits) -->
    H1 = dropout(relu(X matmul W1 + B1), [N, 32], 0.3, Mode),
    H2 = dropout(relu(H1 matmul W2 + B2), [N, 32], 0.3, Mode),
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
    seed(11),
    Kept = item(mean(keep([160, 32], 0.3))),
    { format("one mask of [160, 32] at rate 0.3 keeps a fraction ~3f of its units~n", [Kept]) },
    moons(X, Classes), one_hot(Classes, 2, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(300, Ps0, St0, X, Y, Ps) },
    forward(Ps, X, 160, eval, Logits), accuracy(Logits, Classes, Acc),
    L = item(cross_entropy(Logits, Y)),
    { format("trained: cross-entropy ~4f, accuracy on the 160 training rows ~2f, dropout off~n", [L, Acc]) },
    params_save(t11_dropout, Ps),
    { write(saved), nl }.

%% every step draws its own masks: the forward pass is run under `train'
fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, X, Y, PsF) :-
    exec(forward(Ps, X, 160, train, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 100 =:= 0 -> Lv := item(L), format("   ~w steps to go, cross-entropy through dropout ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.02, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    Ps = params(t11_dropout),
    moons(X, Classes),
    forward(Ps, X, 160, eval, Logits), accuracy(Logits, Classes, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("accuracy ~w%~n", [Pct]),
      ( Pct >= 85 -> true ; write('FAIL'), nl, halt(1) ) },
    % the mode split: two evaluation passes over the same rows, and nothing
    % random between them -- they must agree to the last bit
    forward(Ps, X, 160, eval, Logits2),
    R1 = list(softmax(Logits)), R2 = list(softmax(Logits2)),
    { ( rows_close(R1, R2)
      -> write('ok (and two predicts agreed exactly)'), nl
      ;  write('FAIL dropout still sampling at predict time'), nl, halt(1) ) }.

predict -->
    Ps = params(t11_dropout),
    { Points = [[0.0, 1.0]-upper, [1.0, -0.6]-lower],
      findall(R, member(R-_, Points), Rows) },
    X = Rows,
    forward(Ps, X, 2, eval, Logits),
    Got = list(argmax(Logits, 1)),
    { forall(( nth0(I, Got, G), nth0(I, Points, [A, B]-Truth) ),
             ( C is round(G), moon_name(C, Name),
               format("(~2f, ~2f) is in the ~w moon  (it is ~w)~n", [A, B, Name, Truth]) )) }.
