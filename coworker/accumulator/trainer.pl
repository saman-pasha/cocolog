%% One trainer of three. Called as train_part(1), train_part(2) or
%% train_part(3), each in its own process against its own knowledge
%% base -- run.sh wires which. The trainer sees only its third of the
%% data, trains a full model on it, and saves it under the one name
%% the accumulator will ask for: rings.
%%
%% Every part seeds torch the same, so all three start from the SAME
%% initial weights -- which is what makes averaging the three trained
%% parameter sets meaningful: three walks from one starting point over
%% three samples of the same distribution end near one another.

%% Two concentric rings, deterministic in I: class 0 at radius ~0.5,
%% class 1 at radius ~1.0, both jittered. Indices 0..899 are training
%% data (shard by I mod 3), 900..1049 the accumulator's held-out test.

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).
noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

ring_point(I, [X, Y], L) :-
    L is I mod 2,
    noise(I, N1), noise(I + 7000, N2), noise(I + 14000, N3),
    T is 6.28318 * N1,
    R is 0.5 + 0.5 * L + 0.08 * (N2 - 0.5),
    X is R * cos(T) + 0.02 * (N3 - 0.5),
    Y is R * sin(T), !.

shard_index(Part, I) :-
    between(0, 899, I),
    I mod 3 =:= Part - 1.

%% Trains in --local -- the long compute never sits inside a database
%% transaction -- and prints the finished model in its STORED form:
%% torch_model/2 and torch_params/3 clauses, exactly what model_save
%% would have put in a knowledge base. run.sh captures the torch_*
%% lines and publishes them into this part's knowledge base as one
%% short consult, so the write turn is brief and small.
train_part(Part) :-
    torch_seed(7),
    findall(X, (shard_index(Part, I), ring_point(I, X, _)), Xs),
    findall(L, (shard_index(Part, I), ring_point(I, _, L)), Ls),
    length(Xs, N),
    tensor_from_list(Xs, TX), tensor_from_list(Ls, TY),
    model_new([input(2), dense(16, tanh), dense(16, tanh),
               dense(2, log_softmax)], M),
    model_train(M, TX, TY, [epochs(300), batch(32), lr(0.02),
                            optimiser(adam), loss(nll), final_loss(FL)]),
    model_save(rings, M),
    format("part ~w: trained on ~w points, final nll ~4f~n", [Part, N, FL]),
    torch_model(rings, Spec),
    format("torch_model(rings, ~q).~n", [Spec]),
    forall(torch_params(rings, Q, C),
           format("torch_params(rings, ~w, ~q).~n", [Q, C])),
    !.
