%% 19. Batch normalisation, and the buffers that are not parameters
%%
%% Batch norm after a convolution standardises each CHANNEL by the BATCH's
%% statistics while training -- its mean and variance over every pixel of
%% every picture in the batch -- and by RUNNING statistics, learned by
%% watching rather than by gradient, when the network answers for real.
%% Written as expressions there is nothing hidden about either half. With
%% pixels as rows a channel is a column of the [N*64, 4] map, so the batch
%% statistics are mean_rows/2 over all N*64 rows,
%%
%%     Mu = mean_rows(C, R),  V = mean_rows((C - Mu) ^ 2.0, R)       [1, 4] each
%%     H  = relu((C - Mu) / sqrt(V + 1.0e-5) * G + Bt)               standardise, then the affine
%%
%% where G and Bt -- the scale and the shift -- are PARAMETERS, made by
%% parameter/1 and moved by Adam. The running mean and variance are BUFFERS:
%% plain tensors the fit loop moves a tenth of the way toward each batch's
%% statistics, by step/3 -- `step(RM, RM - Mu, 0.1)' is a fresh leaf, so no
%% gradient is asked of them and none reaches back through them. Both kinds
%% go to the store in one params_save list: the store keeps shapes and
%% values and does not distinguish, and what makes a buffer a buffer is only
%% that no grad/2 ever names it. This tutorial's test rides on exactly that:
%% the accuracy check happens in a fresh process, through the store, with
%% the RUNNING statistics doing the normalising -- a dropped buffer would
%% show up as a wrong answer here.
%%
%% (An earlier version of this tutorial used model_new's `norm' layer, whose
%% buffers the torch module carried; library lesson 22-torch still teaches it.)
%%
%%   train    72 pictures, Adam, 60 steps; parameters AND buffers saved as t19_bn
%%   test     72 fresh pictures through the running statistics, accuracy at least 95%
%%   predict  a clean bar, classified, and the running mean that came back
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/19-batch-norm.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/19-batch-norm.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/19-batch-norm.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).

%% ---- the pictures ----------------------------------------------------------
%% Every predicate here ends in a cut: a `run' consults this file into the
%% store, the store keeps every consult, and a generator without a cut
%% would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

%% img_row(+I, +Classes, -Row, -L): the I-th picture, 64 pixels row-major,
%% a vertical (0) or horizontal (1) bar at a wandering position, a little noise.
img_row(I, Classes, Row, L) :-
    L is I mod Classes,
    Pos is 1 + (I // Classes) mod 6,
    findall(V, (between(0, 63, P),
                R is P // 8, C is P mod 8,
                noise(I * 64 + P + 90000, E),
                ( L =:= 0 -> ( C =:= Pos -> V is 1 + 0.1 * E ; V is 0.1 * E )
                ; ( R =:= Pos -> V is 1 + 0.1 * E ; V is 0.1 * E ) )),
            Row), !.

%% pictures(+From, +N, -X, -Classes): N pictures as one [N*64, 1] tensor,
%% pixels as rows, and their classes as a list.
pictures(From, N, X, Classes) -->
    { To is From + N - 1,
      findall(L, ( between(From, To, I), img_row(I, 2, _, L) ), Classes),
      findall([V], ( between(From, To, I), img_row(I, 2, Row, _), member(V, Row) ), Rows) },
    X = Rows, !.

draw(Pixels) :-
    forall(between(0, 7, Y),
           ( write('   '),
             forall(between(0, 7, X), ( P is Y * 8 + X, nth0(P, Pixels, V), ( V > 0.5 -> write('#') ; write('.') ) )), nl )), !.

%% ---- the network -----------------------------------------------------------

%% the constants every process builds once: the nine tap matrices at 8x8,
%% and the pooling matrix
constants(c(S8, P8)) --> shifts(8, 8, S8), pool_matrix(8, 8, P8), !.

%% THE PARAMETERS -- what gradient moves: the kernel and its bias, batch
%% norm's scale G (ones) and shift Bt (zeros), and the dense head.
parameters([K, B, G, Bt, Wd, Bd]) :-
    K := parameter(glorot(9, 4)),    B := parameter(zeros([1, 4])),
    G := parameter(ones([1, 4])),    Bt := parameter(zeros([1, 4])),
    Wd := parameter(glorot(64, 2)),  Bd := parameter(zeros([1, 2])), !.

%% THE BUFFERS -- what watching moves: a running mean and variance per
%% channel, plain tensors, started where a standardised channel would be.
buffers([RM, RV]) :-
    RM := zeros([1, 4]), RV := ones([1, 4]), !.

%% forward(+Ps, +Constants, +N, +X, ?Stats, -Logits): the network. Stats
%% says which statistics normalise: batch(Mu, V) while training -- the
%% batch's own, computed here and ANSWERED through the head, so the fit loop
%% can fold them into the running ones -- or running(RM, RV) when the
%% network answers for real. A PROCEDURE either way: exec/1 runs it and
%% frees everything it made but what the head names.
forward([K, B | Rest], c(S8, P8), N, X, batch(Mu, V), Logits) -->
    { R is N * 64 },
    C = conv2d(X, K, S8) + B,                          % [N*64, 4]  the convolution, before the norm
    Mu = mean_rows(C, R),                              % [1, 4]     this batch's mean per channel, over every pixel of every picture
    V = mean_rows((C - Mu) ^ 2.0, R),                  % [1, 4]     and its variance
    normalised(Rest, P8, N, C, Mu, V, Logits).
forward([K, B | Rest], c(S8, P8), N, X, running(RM, RV), Logits) -->
    C = conv2d(X, K, S8) + B,
    normalised(Rest, P8, N, C, RM, RV, Logits).

%% normalised(+Ps, +P8, +N, +C, +Mu, +V, -Logits): from the convolved map
%% to the logits, standardising each channel by whichever Mu and V came in.
normalised([G, Bt, Wd, Bd], P8, N, C, Mu, V, Logits) -->
    H = relu((C - Mu) / sqrt(V + 1.0e-5) * G + Bt),    % [N*64, 4]  standardise per channel, then the affine the parameters own
    Pd = pool2(H, P8),                                  % [N*16, 4]  8x8 -> 4x4
    Logits = reshape(Pd, [N, 64]) matmul Wd + Bd.       % [N, 2]     flatten, then the dense head

%% ---- the three goals ------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself -- and moves the buffers,
%% freeing the old ones itself too.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(19),
    constants(Cs),
    pictures(0, 72, X, Classes), one_hot(Classes, 2, Y),
    { parameters(Ps0), buffers(Bs0), adam_init(Ps0, St0),
      fit(60, Ps0, Bs0, St0, Cs, 72, X, Y, Ps, Bs) },
    { Bs = [RM, RV] },
    forward(Ps, Cs, 72, X, running(RM, RV), Logits), accuracy(Logits, Classes, Acc),
    { format("trained: accuracy on the 72 training pictures ~2f, through the running statistics~n", [Acc]),
      append(Ps, Bs, All) },
    params_save(t19_bn, All),                          % parameters and buffers, one list
    { write(saved), nl }.

%% fit(+K, +Ps, +Bs, +St, +Cs, +N, +X, +Y, -PsF, -BsF): K steps of Adam on
%% the parameters, and K moves of the buffers toward the batch statistics
%% the forward pass answered -- the same forward pass, so the gradient and
%% the statistics come from one batch.
fit(0, Ps, Bs, _, _, _, _, _, Ps, Bs) :- !.
fit(K, Ps, [RM, RV], St, Cs, N, X, Y, PsF, BsF) :-
    exec(forward(Ps, Cs, N, X, batch(Mu, V), Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 20 =:= 0 -> Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    RM2 := step(RM, RM - Mu, 0.1),                     % a tenth of the way toward this batch's mean: a NEW leaf, no gradient through it
    RV2 := step(RV, RV - V, 0.1),
    free_all([Logits, L, Mu, V, RM, RV]),
    K1 is K - 1,
    fit(K1, Ps2, [RM2, RV2], St2, Cs, N, X, Y, PsF, BsF).

test -->
    constants(Cs),
    [K, B, G, Bt, Wd, Bd, RM, RV] = params(t19_bn),    % the buffers come back beside the parameters
    pictures(1000, 72, X, Classes),
    forward([K, B, G, Bt, Wd, Bd], Cs, 72, X, running(RM, RV), Logits), accuracy(Logits, Classes, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("accuracy ~w% on 72 fresh pictures (through stored running statistics)~n", [Pct]),
      ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    constants(Cs),
    [K, B, G, Bt, Wd, Bd, RM, RV] = params(t19_bn),
    { findall([Vv], ( between(0, 63, P), Cc is P mod 8, ( Cc =:= 4 -> Vv = 1.0 ; Vv = 0.0 ) ), Rows),
      findall(Vv, member([Vv], Rows), Bar) },
    X = Rows,
    forward([K, B, G, Bt, Wd, Bd], Cs, 1, X, running(RM, RV), Logits),
    [Pk] = list(argmax(Logits, 1)),
    [Means] = list(RM),
    { C2 is round(Pk), draw(Bar),
      format("a clean bar down column 4 -> class ~w (0 is vertical)~n", [C2]),
      format("normalised by the running mean per channel ~w, a buffer the store gave back~n", [Means]) }.
