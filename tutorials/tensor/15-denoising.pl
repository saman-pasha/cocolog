%% 15. A denoising autoencoder: noisy in, clean out
%%
%% The same eight patterns as tutorial 14, but the input carries six times
%% the noise and the TARGET is the clean pattern -- the network learns the
%% signal by being forbidden to learn the noise. That asymmetry (X noisy,
%% Y clean) is the whole difference between an autoencoder and a denoiser,
%% and in expressions it is one letter: tutorial 14's loss is mse(Out, X)
%% and this file's is mse(Out, Y). The network is one procedure,
%%
%%     denoise(Ps, X, Out) --> Out = tanh(X matmul W1 + B1) matmul W2 + B2.
%%
%% eight tanh units between eight noisy numbers and eight clean ones. (An
%% earlier version of this file was the same network as a model_new spec,
%% trained by model_train.)
%%
%%   train    learn to clean, 128 noisy patterns against their clean ones, Adam; save as t15_denoise
%%   test     reload, rmse of cleaned-vs-clean under 0.12
%%   predict  reload, clean one noisy pattern before your eyes
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/15-denoising.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/15-denoising.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/15-denoising.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the patterns -------------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

%% dn_rows(+I, -Noisy, -Clean): the one-hot pattern I mod 8, noisy and clean.
dn_rows(I, Noisy, Clean) :-
    H is I mod 8,
    findall(V, (between(0, 7, J), ( J =:= H -> V = 1.0 ; V = 0.0 )), Clean),
    findall(V, (between(0, 7, J),
                noise(I * 8 + J + 40000, E),
                ( J =:= H -> V is 1 + 0.3 * E ; V is 0.3 * E )), Noisy), !.

%% pairs(-X, -Y): 128 noisy rows and, row for row, the clean pattern each came from.
pairs(X, Y) -->
    { findall(R, (between(0, 127, I), dn_rows(I, R, _)), XR),
      findall(R, (between(0, 127, I), dn_rows(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the network ------------------------------------------------------------------------

parameters([W1, B1, W2, B2]) :-
    W1 := parameter(glorot(8, 8)), B1 := parameter(zeros([1, 8])),
    W2 := parameter(glorot(8, 8)), B2 := parameter(zeros([1, 8])), !.

%% denoise//3 is a PROCEDURE: a DCG rule of bindings; exec/1 runs it and
%% frees everything it made but Out.
denoise([W1, B1, W2, B2], X, Out) -->
    Out = tanh(X matmul W1 + B1) matmul W2 + B2.

%% ---- the three goals ---------------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(15),
    pairs(X, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(1200, Ps0, St0, X, Y, Ps) },
    denoise(Ps, X, Out), S = item(sqrt(mse(Out, Y))),
    { format("trained: denoised rmse ~4f on the 128 patterns~n", [S]) },
    params_save(t15_denoise, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, X, Y, PsF) :-
    exec(denoise(Ps, X, Out)),
    L := mse(Out, Y),                                       % the CLEAN pattern is the target
    Gs := grad(L, Ps),
    ( K mod 300 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.02, Ps2, St2),
    free_all([Out, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    Ps = params(t15_denoise),
    pairs(X, Y),
    denoise(Ps, X, Out),
    S = item(sqrt(mse(Out, Y))),
    { format("denoised rmse ~4f~n", [S]),
      ( S < 0.12 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    Ps = params(t15_denoise),
    { dn_rows(999, Noisy, Clean) },
    denoise(Ps, [Noisy], Out), [Row] = list(Out),
    { write('noisy:   '), forall(member(V, Noisy), format("~2f ", [V])), nl,
      write('cleaned: '), forall(member(V, Row), format("~2f ", [V])), nl,
      write('truth:   '), forall(member(V, Clean), format("~2f ", [V])), nl }.
