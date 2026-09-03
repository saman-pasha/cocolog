%% One worker of three, and there is no fourth: every worker owns one
%% third of the training data in its own knowledge base, fetches the
%% two other thirds from its peers, trains a full model on the union,
%% and publishes it back into its own knowledge base -- so when the
%% dust settles ANY of the three answers test and predict, and queries
%% can go to whichever is nearest. run.sh drives the choreography;
%% every predicate here ends in a cut so a clause that is there twice
%% never doubles an answer. (A consult REPLACES what the same file put
%% in the base before, so the file itself no longer doubles; the cut
%% stays for the chunks a worker publishes beside another's.)

%% Two concentric rings, deterministic in I: class 0 at radius ~0.5,
%% class 1 at radius ~1.0, both jittered. Indices 0..899 are training
%% data (shard by I mod 3), 900..1049 the held-out test.

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

%% Seeding: this worker's own third, into its own knowledge base -- as
%% a handful of CHUNK rows, sixty samples to a row, the way machine
%% state travels in 4000-byte chunks and model parameters in 120-float
%% ones: a clause row has to fit in a page, wherever the store keeps
%% it (the hunt in STATUS.md exonerated the server of everything
%% else). One turn seeds everything;
%% part_ready/1 is asserted last in it, and a turn being one
%% transaction, a peer that sees the mark sees every chunk with it.
chunked([], _, []) :- !.
chunked(Items, N, [Chunk|Rest]) :-
    take(N, Items, Chunk, More),
    chunked(More, N, Rest), !.

take(0, Xs, [], Xs) :- !.
take(_, [], [], []) :- !.
take(N, [X|Xs], [X|Cs], Rest) :- N1 is N - 1, take(N1, Xs, Cs, Rest), !.

seed_part(Part) :-
    findall(s(I, X, L),
            ( between(0, 899, I), I mod 3 =:= Part - 1, ring_point(I, X, L) ),
            Samples),
    chunked(Samples, 60, Chunks),
    forall(( nth0(Q, Chunks, C) ),
           assertz(samples_chunk(Part, Q, C))),
    assertz(part_ready(Part)),
    length(Samples, N), length(Chunks, NC),
    format("part ~w: ~w samples seeded in ~w chunk rows~n", [Part, N, NC]), !.

%% Training: over every sample chunk in sight -- by the time run.sh
%% calls this, the worker's own chunks and both fetched parts have been
%% consulted into the --local session. Sorted by index, so the tensor
%% is the same whatever order the parts arrived in.
train_sample(I, X, L) :-
    samples_chunk(_, _, C), member(s(I, X, L), C).

train_full :-
    torch_seed(7),
    findall(I, train_sample(I, _, _), Is0),
    msort(Is0, Is),
    findall(X, (member(I, Is), train_sample(I, X, _)), Xs),
    findall(L, (member(I, Is), train_sample(I, _, L)), Ls),
    length(Xs, N),
    tensor_from_list(Xs, TX), tensor_from_list(Ls, TY),
    model_new([input(2), dense(16, tanh), dense(16, tanh),
               dense(2, log_softmax)], M),
    model_train(M, TX, TY, [epochs(300), batch(32), lr(0.02),
                            optimiser(adam), loss(nll), final_loss(FL)]),
    model_save(rings, M),
    format("trained on ~w points (own third and two fetched), final nll ~4f~n",
           [N, FL]),
    torch_model(rings, Spec),
    format("torch_model(rings, ~q).~n", [Spec]),
    forall(torch_params(rings, Q, C),
           format("torch_params(rings, ~w, ~q).~n", [Q, C])),
    !.

%% Verification, asked of EACH worker in turn: its own copy of the
%% model against the held-out points no shard contains.
test :-
    model_load(rings, M),
    findall(X, (between(900, 1049, I), ring_point(I, X, _)), Xs),
    findall(L, (between(900, 1049, I), ring_point(I, _, L)), Ls),
    tensor_from_list(Xs, TX), tensor_from_list(Ls, TY),
    model_evaluate(M, TX, TY, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("held-out accuracy ~w% on 150 points~n", [Pct]),
    ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ), !.

probe(X, Y) :-
    model_load(rings, M),
    tensor_from_list([[X, Y]], TX),
    model_predict(M, TX, P),
    tensor_to_list(P, [[L0, L1]]),
    ( L1 > L0 -> C = outer, Conf is exp(L1)
    ; C = inner, Conf is exp(L0) ),
    format("ring(~2f, ~2f) = ~w  (confidence ~2f)~n", [X, Y, C, Conf]), !.
