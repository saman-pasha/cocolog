%% 41. Sequence to sequence, with attention: a GRU that reads, a GRU that writes, and a glance between them
%%
%% The encoder-decoder with attention -- Bahdanau, Cho and Bengio, 2014 --
%% is the shape machine translation took before the transformer, and the
%% paper that named attention. An encoder GRU reads the source, one token a
%% step, keeping every hidden state; a decoder GRU writes the target, one
%% token a step, and before each step it LOOKS BACK: a small network scores
%% every encoder state against the decoder's state, a softmax turns the
%% scores into weights, and the weighted sum of encoder states -- the
%% context -- goes into the step beside the previous token. The weights are
%% the payoff: `predict' prints them, and for a model that has learned to
%% REVERSE its input they lean along the anti-diagonal -- the first output
%% looks hardest at the last input.
%%
%% Everything is expressions. The GRU cell is four lines of them; the
%% recurrence over the steps is Prolog, threading the hidden state the way
%% tutorial 29 threads its parameters; teacher forcing is which token list
%% the decoder is handed. index_rows/2 is the embedding lookup, and argmax/2
%% answers an index tensor that goes straight back in as the next lookup
%% when the decoder feeds itself.
%%
%%   train    sequences of five tokens from eight, eight rotating batches of 64, Adam, 400 steps; saved as t41_seq2seq
%%   test     64 fresh sequences decoded by the model on its own, token accuracy at least 0.9
%%   predict  four sequences reversed, and the attention weights of the first
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/41-seq2seq-attention.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/41-seq2seq-attention.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/41-seq2seq-attention.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the sequences --------------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.
pick(I, Salt, N, P) :- J is I * 7 + Salt, noise(J, R), P is truncate(abs(R) * N), !.

%% sequence(+I, -Source, -Target): five tokens from 0..7, and the same reversed.
sequence(I, Source, Target) :-
    findall(T, ( between(0, 4, P), Salt is 11 + P * 13, pick(I, Salt, 8, T) ), Source),
    reverse(Source, Target), !.

%% batch(+From, +N, -Ins, -Outs, -Feeds, -Y): N sequences as, per step, an
%% index tensor of N source tokens (Ins), the N target tokens as lists
%% (Outs), the index tensor the decoder is fed at that step under teacher
%% forcing -- the start token 8, then the true previous target (Feeds) --
%% and the one-hot of all N*5 targets, step-major, for the loss.
batch(From, N, Ins, Outs, Feeds, Y) :-
    To is From + N - 1,
    findall(S-T, ( between(From, To, I), sequence(I, S, T) ), Pairs),
    findall(In, ( between(0, 4, P), findall(Tok, ( member(S-_, Pairs), nth0(P, S, Tok) ), L), In := L ), Ins),
    findall(L, ( between(0, 4, P), findall(Tok, ( member(_-T, Pairs), nth0(P, T, Tok) ), L) ), Outs),
    findall(Feed, ( between(0, 4, P), ( P =:= 0 -> findall(8, member(_, Pairs), L) ; P0 is P - 1, nth0(P0, Outs, L) ), Feed := L ), Feeds),
    findall(Tok, ( member(L, Outs), member(Tok, L) ), Flat), one_hot(Flat, 8, Y), !.

%% ---- the networks ---------------------------------------------------------------------------
%% Embeddings of 16, hidden states of 32, the attention's own layer 32 wide.

gru_params(In, [Wz, Uz, Bz, Wr, Ur, Br, Wn, Un, Bn]) :-
    Wz := parameter(glorot(In, 32)), Uz := parameter(glorot(32, 32)), Bz := parameter(zeros([1, 32])),
    Wr := parameter(glorot(In, 32)), Ur := parameter(glorot(32, 32)), Br := parameter(zeros([1, 32])),
    Wn := parameter(glorot(In, 32)), Un := parameter(glorot(32, 32)), Bn := parameter(zeros([1, 32])), !.
parameters(Ps) :-
    EmbIn := parameter(randn([8, 16]) * 0.5), EmbOut := parameter(randn([9, 16]) * 0.5),      % 9: the eight tokens and the start token
    gru_params(16, Enc), gru_params(48, Dec),                                                % the decoder reads [token | context]
    Wa := parameter(glorot(32, 32)), Ua := parameter(glorot(32, 32)), Va := parameter(glorot(32, 1)),
    Wo := parameter(glorot(32, 8)), Bo := parameter(zeros([1, 8])),
    append([[EmbIn, EmbOut], Enc, Dec, [Wa, Ua, Va, Wo, Bo]], Ps), !.
unpack(Ps, EmbIn, EmbOut, Enc, Dec, Wa, Ua, Va, Wo, Bo) :-
    length(Enc, 9), length(Dec, 9), append([[EmbIn, EmbOut], Enc, Dec, [Wa, Ua, Va, Wo, Bo]], Ps), !.

%% gru(+Cell, +X, +H, -H2): one step. Update gate, reset gate, candidate,
%% blend -- a PROCEDURE, a DCG rule of four bindings. Everything that makes
%% tensors from here down is one, and a procedure called inside another
%% threads what it made up to the caller; exec/1 at the top frees all of it
%% but what the head returns.
gru([Wz, Uz, Bz, Wr, Ur, Br, Wn, Un, Bn], X, H, H2) -->
    Z = sigmoid(X matmul Wz + H matmul Uz + Bz),
    R = sigmoid(X matmul Wr + H matmul Ur + Br),
    C = tanh(X matmul Wn + (R * H) matmul Un + Bn),
    H2 = (1.0 - Z) * H + Z * C.

%% encode(+EmbIn, +Enc, +Ins, -Hs): the source, a step a token; every state kept.
encode(EmbIn, Enc, Ins, Hs) -->
    { Ins = [In0|_] }, [N] = shape(In0), H0 = zeros([N, 32]),
    encode(Ins, EmbIn, Enc, H0, Hs).
encode([], _, _, _, []) --> [].
encode([In|Ins], EmbIn, Enc, H, [H2|Hs]) -->
    X = index_rows(EmbIn, In), gru(Enc, X, H, H2),
    encode(Ins, EmbIn, Enc, H2, Hs).

%% attend(+Wa, +Ua, +Va, +Hs, +H, -Ctx, -Weights): additive attention -- a
%% score per encoder state from tanh(H Wa + Hj Ua) Va, softmaxed across the
%% five, and the context as the weighted sum. Weights is [N, 5].
attend(Wa, Ua, Va, Hs, H, Ctx, Weights) -->
    Q = H matmul Wa,
    scores(Hs, Q, Ua, Va, Scores),
    Weights = softmax(cat(Scores, 1)),
    { Hs = [H1, H2, H3, H4, H5] },
    Ctx = cols(Weights, 0, 1) * H1 + cols(Weights, 1, 2) * H2 + cols(Weights, 2, 3) * H3 + cols(Weights, 3, 4) * H4 + cols(Weights, 4, 5) * H5.
scores([], _, _, _, []) --> [].
scores([Hj|Hs], Q, Ua, Va, [S|Ss]) --> S = tanh(Q + Hj matmul Ua) matmul Va, scores(Hs, Q, Ua, Va, Ss).

%% decode(+Ps, +Hs, +Feeds, -Logits, -Ws): five steps, each fed the token
%% Feeds says (teacher forcing) or, when Feeds is `self', its own argmax.
%% Logits is [N*5, 8] step-major; Ws the five weight tensors.
decode(Ps, Hs, Feeds, Logits, Ws) -->
    { unpack(Ps, _, EmbOut, _, Dec, Wa, Ua, Va, Wo, Bo), last(Hs, HLast), Hs = [H1|_] },
    [N, _] = shape(H1),
    ( { Feeds == self } -> { findall(8, between(1, N, _), Starts) }, First = Starts, { Plan = self(First) } ; { Plan = Feeds } ),
    decode_steps(0, Plan, EmbOut, Dec, Wa, Ua, Va, Wo, Bo, Hs, HLast, Ls, Ws),
    Logits = cat(Ls, 0).
decode_steps(5, _, _, _, _, _, _, _, _, _, _, [], []) --> !.
decode_steps(T, Plan, EmbOut, Dec, Wa, Ua, Va, Wo, Bo, Hs, H, [L|Ls], [W|Ws]) -->
    { ( Plan = self(Feed) -> true ; nth0(T, Plan, Feed) ) },
    attend(Wa, Ua, Va, Hs, H, Ctx, W),
    X = cat([index_rows(EmbOut, Feed), Ctx], 1),
    gru(Dec, X, H, H2),
    L = H2 matmul Wo + Bo,
    ( { Plan = self(_) } -> Next = argmax(L, 1), { Plan2 = self(Next) } ; { Plan2 = Plan } ),
    { T1 is T + 1 },
    decode_steps(T1, Plan2, EmbOut, Dec, Wa, Ua, Va, Wo, Bo, Hs, H2, Ls, Ws).

%% run(+Ps, +Ins, +Feeds, -Logits, -Ws): encoder then decoder; exec(run(...))
%% frees every state and gate along the way and keeps Logits and the weights.
run(Ps, Ins, Feeds, Logits, Ws) -->
    { unpack(Ps, EmbIn, _, Enc, _, _, _, _, _, _) },
    encode(EmbIn, Enc, Ins, Hs),
    decode(Ps, Hs, Feeds, Logits, Ws).

%% ---- the three goals --------------------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the batches and the fit loop stay predicates in braces -- one is
%% findall over positions, the other steps an optimiser that frees the old
%% parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(41),
    { findall(b(Ins, Feeds, Y), ( between(0, 7, B), From is B * 64, batch(From, 64, Ins, _, Feeds, Y) ), Batches),
      parameters(Ps0), adam_init(Ps0, St0),
      fit(400, Ps0, St0, Batches, Ps),
      batch(0, 64, Ins0, Outs0, _, _) },
    own_accuracy(Ps, Ins0, Outs0, Acc),
    { format("trained: token accuracy on the first batch, the decoder feeding itself, ~2f~n", [Acc]) },
    params_save(t41_seq2seq, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, Ps) :- !.
fit(K, Ps, St, Batches, PsF) :-
    B is K mod 8, nth0(B, Batches, b(Ins, Feeds, Y)),
    exec(run(Ps, Ins, Feeds, Logits, Ws)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 100 =:= 0 -> Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.005, Ps2, St2),
    free_all([Logits, L|Ws]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Batches, PsF).

%% own_accuracy(+Ps, +Ins, +Outs, -Acc): the decoder fed its own output, against the targets.
own_accuracy(Ps, Ins, Outs, Acc) -->
    run(Ps, Ins, self, Logits, _),
    { findall(Tok, ( member(L, Outs), member(Tok, L) ), Flat) },
    accuracy(Logits, Flat, Acc), !.

test -->
    params_load(t41_seq2seq, Ps),
    { batch(1000, 64, Ins, Outs, _, _) },
    own_accuracy(Ps, Ins, Outs, Acc),
    { format("test token accuracy ~2f on 64 fresh sequences, the decoder feeding itself~n", [Acc]),
      ( Acc >= 0.9 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    params_load(t41_seq2seq, Ps),
    { batch(2000, 4, Ins, _, _, _) },
    run(Ps, Ins, self, Logits, Ws),
    Got0 = list(argmax(Logits, 1)),
    { findall(G, ( member(G0, Got0), G is round(G0) ), Got),
      forall(between(0, 3, I),
             ( J is 2000 + I, sequence(J, Source, Target),
               findall(Tok, ( between(0, 4, P), Q is P * 4 + I, nth0(Q, Got, Tok) ), Answer),
               ( Answer == Target -> Verdict = right ; Verdict = wrong ),
               format("   ~w  ->  ~w  (~w)~n", [Source, Answer, Verdict]) )),
      nl, write('   the attention of the first sequence, a row per output step, a column per input position:'), nl,
      forall(nth0(T, Ws, W),
             ( [Row|_] := list(W),
               format("   step ~w:", [T]), forall(member(V, Row), format(" ~2f", [V])), nl )) }.
