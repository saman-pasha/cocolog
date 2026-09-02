%% 34. A transformer encoder: attention over a batch, as expressions
%%
%% One encoder block, written out: token and position embeddings, a
%% pre-norm multi-head self-attention with a residual, a pre-norm
%% feed-forward with a residual, mean pooling over the sequence, a dense
%% head. Every piece is a tensor expression, so the block that tutorials
%% 25 to 28 get from the torch module's attention(H) layer is here in the
%% open -- softmax(Q K^T / sqrt(d) + Mask) V, one head at a time through
%% cols/3, the heads joined back by cat/2.
%%
%% THE BATCH IS ONE MATRIX. N sequences of L tokens are [N*L, D] rows, and
%% attention over them is ONE [N*L, N*L] score matrix; block_mask/3 puts
%% -1e9 on every score that crosses from one sequence to another, so after
%% the softmax each sequence attends within itself. That is how a batch of
%% attentions is a single expression.
%%
%% The task wants attention: six tokens from an alphabet of eight, and the
%% question is whether any token appears TWICE. A position has to look at
%% the others and find its own token there, which is what Q K^T does.
%%
%%   train    1024 sequences in sixteen rotating batches of 64, Adam, 800 steps; saved as t34_encoder
%%   test     32 fresh sequences, accuracy at least 0.9
%%   predict  four sequences, with the answer beside the truth
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/34-transformer-encoder.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/34-transformer-encoder.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/34-transformer-encoder.pl predict

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the sequences ----------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.
pick(I, Salt, N, P) :- J is I * 7 + Salt, noise(J, R), P is truncate(abs(R) * N), !.

%% sequence(+I, -Tokens, -Class): six tokens from 0..7. Even I: all distinct
%% (the first six of a shuffle of the alphabet), class 0. Odd I: the same,
%% then one token copied over another position, class 1.
sequence(I, Tokens, Class) :-
    Class is I mod 2,
    findall(K-T, ( between(0, 7, T), J is I * 13 + T, noise(J, K) ), Pairs), msort(Pairs, Sorted),
    findall(T, member(_-T, Sorted), Perm), append(Distinct, _, Perm), length(Distinct, 6),
    (   Class =:= 1
    ->  pick(I, 11, 6, A), pick(I, 23, 5, B0), ( B0 >= A -> B is B0 + 1 ; B = B0 ),
        nth0(A, Distinct, Tok),
        findall(X, ( nth0(P, Distinct, D), ( P =:= B -> X = Tok ; X = D ) ), Tokens)
    ;   Tokens = Distinct ), !.

%% sequences(+From, +N, -Ids, -PosIds, -Classes): N sequences as one list of
%% N*6 token ids, the position of each, and the classes.
sequences(From, N, Ids, PosIds, Classes) :-
    To is From + N - 1,
    findall(C, ( between(From, To, I), sequence(I, _, C) ), Classes),
    findall(T, ( between(From, To, I), sequence(I, Ts, _), member(T, Ts) ), IdList),
    findall(P, ( between(From, To, _), between(0, 5, P) ), PosList),
    Ids := IdList, PosIds := PosList, !.

%% ---- the network -------------------------------------------------------------------
%% D = 16, two heads of 8, the feed-forward 32 wide, six positions.

parameters([Emb, Pos, G1, Bt1, Wq, Wk, Wv, Wo, G2, Bt2, W1, B1, W2, B2, Wc, Bc]) :-
    Emb := parameter(randn([8, 16]) * 0.5),  Pos := parameter(randn([6, 16]) * 0.5),
    G1 := parameter(ones([1, 16])),          Bt1 := parameter(zeros([1, 16])),
    Wq := parameter(glorot(16, 16)), Wk := parameter(glorot(16, 16)), Wv := parameter(glorot(16, 16)), Wo := parameter(glorot(16, 16)),
    G2 := parameter(ones([1, 16])),          Bt2 := parameter(zeros([1, 16])),
    W1 := parameter(glorot(16, 32)),         B1 := parameter(zeros([1, 32])),
    W2 := parameter(glorot(32, 16)),         B2 := parameter(zeros([1, 16])),
    Wc := parameter(glorot(16, 2)),          Bc := parameter(zeros([1, 2])), !.

%% head(+Q, +K, +V, +Mask, +H, -O): one head's attention, columns H*8 to H*8+8.
head(Q, K, V, Mask, H, O) :-
    F is H * 8, T is F + 8,
    O := softmax(cols(Q, F, T) matmul transpose(cols(K, F, T)) * 0.3535534 + Mask) matmul cols(V, F, T), !.

%% forward(+Ps, +Ids, +PosIds, +Mask, -Logits): the block, then the head.
forward([Emb, Pos, G1, Bt1, Wq, Wk, Wv, Wo, G2, Bt2, W1, B1, W2, B2, Wc, Bc], Ids, PosIds, Mask, Logits) :-
    E := index_rows(Emb, Ids) + index_rows(Pos, PosIds),        % [N*6, 16]  what each position is, and where
    X1 := layer_norm(E) * G1 + Bt1,                              % pre-norm
    Q := X1 matmul Wq, K := X1 matmul Wk, V := X1 matmul Wv,
    head(Q, K, V, Mask, 0, O0), head(Q, K, V, Mask, 1, O1),
    H := E + cat([O0, O1], 1) matmul Wo,                         % attention, and its residual
    X2 := layer_norm(H) * G2 + Bt2,
    Ff := H + relu(X2 matmul W1 + B1) matmul W2 + B2,            % feed-forward, and its residual
    Pooled := mean_rows(Ff, 6),                                  % [N, 16]  the sequence as one row
    Logits := Pooled matmul Wc + Bc,
    free_all([E, X1, Q, K, V, O0, O1, H, X2, Ff, Pooled]), !.

%% ---- the three goals ----------------------------------------------------------------

train :-
    torch_seed(34),
    % sixteen batches of 64: a step sees one, the next step the next, so the
    % network meets 1024 sequences and cannot learn them by heart
    findall(batch(Ids, PosIds, Y), ( between(0, 15, B), From is B * 64, sequences(From, 64, Ids, PosIds, Classes), one_hot(Classes, 2, Y) ), Batches),
    block_mask(64, 6, Mask),
    parameters(Ps0), adam_init(Ps0, St0),
    fit(800, Ps0, St0, Batches, Mask, Ps),
    Batches = [batch(Ids0, PosIds0, _)|_], sequences(0, 64, _, _, Classes0),
    forward(Ps, Ids0, PosIds0, Mask, Logits), accuracy(Logits, Classes0, Acc), tensor_free(Logits),
    format("trained: accuracy on the first training batch ~2f~n", [Acc]),
    params_save(t34_encoder, Ps),
    write(saved), nl.

fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, Batches, Mask, PsF) :-
    B is K mod 16, nth0(B, Batches, batch(Ids, PosIds, Y)),
    forward(Ps, Ids, PosIds, Mask, Logits),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 200 =:= 0 -> Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.005, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Batches, Mask, PsF).

test :-
    params_load(t34_encoder, Ps),
    sequences(1000, 32, Ids, PosIds, Classes),
    block_mask(32, 6, Mask),
    forward(Ps, Ids, PosIds, Mask, Logits), accuracy(Logits, Classes, Acc),
    format("test accuracy ~2f on 32 fresh sequences~n", [Acc]),
    ( Acc >= 0.9 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    params_load(t34_encoder, Ps),
    sequences(2000, 4, Ids, PosIds, Classes),
    block_mask(4, 6, Mask),
    forward(Ps, Ids, PosIds, Mask, Logits),
    A := argmax(Logits, 1), Got := list(A),
    forall(( nth0(I, Classes, C), nth0(I, Got, G) ),
           ( J is 2000 + I, sequence(J, Tokens, _), Gi is round(G),
             answer(Gi, GA), answer(C, CA),
             format("   ~w  ->  ~w  (~w)~n", [Tokens, GA, CA]) )).
answer(0, 'all different') :- !.
answer(1, 'a repeat') :- !.
