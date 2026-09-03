%% 9. Four blobs: multiclass classification
%%
%% One gaussian cloud per corner of the plane, four classes, and the
%% multiclass pairing in its plainest form: a head of FOUR logits, `H matmul
%% W2 + B2' with W2 of shape [16, 4]; one_hot/3 turning the labels 0..3 into
%% a [160, 4] target; cross_entropy over the two, which is log_softmax and
%% the negative log-likelihood in one composite; and accuracy/3's argmax
%% across the four columns. The fit is Adam from library(tensor_expr), full
%% batch, 300 steps. (An earlier version of this file was model_new's
%% dense(4, log_softmax) under loss(nll); tutorials/library/22-torch.pl
%% still teaches that API.)
%%
%%   train    learn the corners, save as t09_blobs
%%   test     reload, accuracy over the clouds, pass at 95%
%%   predict  reload, name the corner for a few points
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/09-four-blobs.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/09-four-blobs.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/09-four-blobs.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the blobs ----------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

blob_row(I, [A, B], L) :-
    L is I mod 4,
    ( L =:= 0 -> CA = -1, CB = -1 ; L =:= 1 -> CA = -1, CB = 1
    ; L =:= 2 -> CA = 1,  CB = -1 ; CA = 1,  CB = 1 ),
    noise(I, E1), noise(I + 900, E2),
    A is CA + 0.3 * E1, B is CB + 0.3 * E2, !.

%% blobs(-X, -Classes): the 160 rows as a [160, 2] tensor, and their classes
%% 0..3 as a list -- what one_hot/3 and accuracy/3 take.
blobs(X, Classes) -->
    { findall(R, ( between(0, 159, I), blob_row(I, R, _) ), Rows),
      findall(L, ( between(0, 159, I), blob_row(I, _, L) ), Classes) },
    X = Rows, !.

corner_name(0, 'south-west') :- !.
corner_name(1, 'north-west') :- !.
corner_name(2, 'south-east') :- !.
corner_name(3, 'north-east') :- !.

%% corner_of(+A, +B, -C): the class a point belongs to, by its signs.
corner_of(A, B, C) :- ( A < 0 -> CA = 0 ; CA = 2 ), ( B < 0 -> CB = 0 ; CB = 1 ), C is CA + CB, !.

%% ---- the network --------------------------------------------------------------

parameters([W1, B1, W2, B2]) :-
    W1 := parameter(glorot(2, 16)), B1 := parameter(zeros([1, 16])),
    W2 := parameter(glorot(16, 4)), B2 := parameter(zeros([1, 4])), !.

%% forward(+Ps, +X, -Logits): the relu layer and the four-way head -- a
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
    seed(9),
    blobs(X, Classes), one_hot(Classes, 4, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(300, Ps0, St0, X, Y, Ps) },
    forward(Ps, X, Logits), accuracy(Logits, Classes, Acc),
    L = item(cross_entropy(Logits, Y)),
    { format("trained: cross-entropy ~4f, accuracy on the 160 training rows ~2f~n", [L, Acc]) },
    params_save(t09_blobs, Ps),
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
    Ps = params(t09_blobs),
    blobs(X, Classes),
    forward(Ps, X, Logits), accuracy(Logits, Classes, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("accuracy ~w%~n", [Pct]),
      ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    Ps = params(t09_blobs),
    { Rows = [[-1.0, -1.0], [-0.8, 1.1], [1.2, -0.9], [0.9, 0.9]] },
    X = Rows,
    forward(Ps, X, Logits),
    Got = list(argmax(Logits, 1)),
    { forall(( nth0(I, Got, G), nth0(I, Rows, [A, B]) ),
             ( C is round(G), corner_name(C, Name),
               corner_of(A, B, T), corner_name(T, Truth),
               format("(~1f, ~1f) belongs to the ~w blob  (it is ~w)~n", [A, B, Name, Truth]) )) }.
