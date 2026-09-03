%% 14. The 8-3-8 autoencoder
%%
%% The historical compression exercise: eight one-hot patterns squeezed
%% through a bottleneck of three units and reconstructed. Three tanh units
%% suffice IN PRINCIPLE (three bits name eight patterns), but the bare
%% 8->3->8 gets stuck in practice -- an early draft of this file plateaued
%% at rmse 0.25 -- and the classic remedy is a hidden layer either side of
%% the bottleneck, so the encoder and decoder each have room to work. The
%% network is two PROCEDURES, DCG rules of bindings:
%%
%%     encode(Ps, X, Z)   -->  Z = tanh(tanh(X matmul W1 + B1) matmul W2 + B2).
%%     decode(Ps, Z, Out) -->  Out = tanh(Z matmul W3 + B3) matmul W4 + B4.
%%
%% and the target is the input itself: the loss is mse(Out, X), nothing
%% else tells the network what a pattern is. Z is three numbers per
%% pattern, the code the network invented, and `predict' prints the eight
%% of them. (An earlier version of this file was the same network as a
%% model_new spec, trained by model_train with X as its own target.)
%%
%%   train    learn to reconstruct, 128 noisy patterns, Adam; save as t14_autoenc
%%   test     reload, reconstruction rmse under 0.15
%%   predict  reload, show a pattern beside its code and its reconstruction
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/14-autoencoder.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/14-autoencoder.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/14-autoencoder.pl predict

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

%% ae_row(+I, -Row): the one-hot pattern I mod 8, with a little noise on every entry.
ae_row(I, Row) :-
    H is I mod 8,
    findall(V, (between(0, 7, J),
                noise(I * 8 + J, E),
                ( J =:= H -> V is 1 + 0.05 * E ; V is 0.05 * E )), Row), !.

%% patterns(-X): the 128 rows as one [128, 8] tensor.
patterns(X) --> { findall(R, (between(0, 127, I), ae_row(I, R)), Rows) }, X = Rows, !.

%% ---- the network ------------------------------------------------------------------------

parameters([W1, B1, W2, B2, W3, B3, W4, B4]) :-
    W1 := parameter(glorot(8, 8)), B1 := parameter(zeros([1, 8])),      % 8 -> 8, the encoder's room to work
    W2 := parameter(glorot(8, 3)), B2 := parameter(zeros([1, 3])),      % 8 -> 3, the bottleneck
    W3 := parameter(glorot(3, 8)), B3 := parameter(zeros([1, 8])),      % 3 -> 8, the decoder's
    W4 := parameter(glorot(8, 8)), B4 := parameter(zeros([1, 8])), !.   % 8 -> 8, the reconstruction

%% encode//3 and decode//3 are PROCEDURES: a procedure called inside another
%% threads what it made up to the caller, and exec/1 at the top frees all
%% of it but what the head returns.
encode([W1, B1, W2, B2 | _], X, Z) -->
    Z = tanh(tanh(X matmul W1 + B1) matmul W2 + B2).
decode([_, _, _, _, W3, B3, W4, B4], Z, Out) -->
    Out = tanh(Z matmul W3 + B3) matmul W4 + B4.
forward(Ps, X, Out) --> encode(Ps, X, Z), decode(Ps, Z, Out).

%% ---- the three goals ---------------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(14),
    patterns(X),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(2000, Ps0, St0, X, Ps) },
    forward(Ps, X, Out), S = item(sqrt(mse(Out, X))),
    { format("trained: reconstruction rmse ~4f on the 128 patterns~n", [S]) },
    params_save(t14_autoenc, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, Ps) :- !.
fit(K, Ps, St, X, PsF) :-
    exec(forward(Ps, X, Out)),
    L := mse(Out, X),                                       % the input is the target
    Gs := grad(L, Ps),
    ( K mod 500 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    free_all([Out, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, PsF).

test -->
    Ps = params(t14_autoenc),
    patterns(X),
    forward(Ps, X, Out),
    S = item(sqrt(mse(Out, X))),
    { format("reconstruction rmse ~4f~n", [S]),
      ( S < 0.15 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

%% the clean pattern with the one at position 2, through the bottleneck and
%% back; then the code of every clean pattern -- eye(8) is the eight of them
predict -->
    Ps = params(t14_autoenc),
    X = [[0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]],
    encode(Ps, X, Z), decode(Ps, Z, Out),
    [Code] = list(Z), [Row] = list(Out),
    { write('in :   [0, 0, 1, 0, 0, 0, 0, 0]'), nl,
      write('code:  '), forall(member(V, Code), format("~2f ", [V])), nl,
      write('out:   '), forall(member(V, Row), format("~2f ", [V])), nl, nl,
      write('the code of each of the eight patterns, three numbers where eight went in:'), nl },
    encode(Ps, eye(8), Codes), CL = list(Codes),
    { forall(nth0(I, CL, C),
             ( format("   pattern ~w:  ", [I]), forall(member(V, C), format("~5f ", [V])), nl )) }.
