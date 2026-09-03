%% 26. The same character-level language model, as a TRANSFORMER
%%
%% THE POINT OF THIS FILE IS THE COMPARISON. Lesson 25 is an LSTM over the
%% same 4200 characters, the same 3765/419 split, the same vocabulary of
%% 77, the same head reading the state after sixteen characters. Only the
%% middle of the network changes -- recurrence out, one decoder block in:
%%
%%     E  = index_rows(Emb, Ids) + index_rows(Pos, PosIds)          a learned vector per character AND per position
%%     X1 = layer_norm(E) * G1 + Bt1                                 pre-norm
%%     O  = softmax(Q K^T / sqrt(24) + Mask) V, four heads of 24     causal self-attention
%%     H  = E + cat(heads) matmul Wo                                 the residual
%%     Ff = H + gelu((layer_norm(H) * G2 + Bt2) matmul W1 + B1) matmul W2 + B2
%%     Logits = (layer_norm(row 15 of every window) * G3 + Bt3) matmul Wout + Bout
%%
%% The batch of windows is ONE score matrix, [B*16, B*16], and
%% causal_mask/3 is what keeps it honest: -1e9 wherever two rows belong to
%% different windows, and wherever a position would see what comes AFTER
%% it. Position i may attend to every position up to and including i and
%% to none after; get it backwards and the model reads the next character
%% off the input, scores wonderfully, and has learned nothing. Without the
%% positional vectors attention is permutation-invariant and cannot tell
%% `ab' from `ba'. The head reads the last position of every window
%% (index_rows/2 on the block's output, one row per window), so the
%% objective is exactly lesson 25's: the character after the window. An
%% earlier version of this file was a model_new spec -- `[sequence(16),
%% embedding(77, 96), positional, attention(4), ffn(192), dense(77,
%% log_softmax)]' -- trained by model_train; the block is now in the open,
%% the arrangement of tutorial 35 with a final layer norm before the head.
%%
%% AND THE TRANSFORMER DOES NOT WIN. Measured, this file against lesson 25,
%% on this Mac's CPU, both files trained thirty epochs:
%%
%%   model                                 parameters   held-out accuracy, libtorch   TensorFlow
%%   lstm(96), lesson 25                       52,093    0.5227  (219 of 419)          0.5155
%%   one block, 4 heads of 24, ffn 192         90,989    0.4415  (185 of 419)          0.4821
%%
%% Behind under both libraries -- eight points under libtorch, four under
%% TensorFlow, which draws a different random start -- on three quarters
%% more parameters, and a training loss that says why: the block fits the
%% 3765 windows to 0.1-0.2 nats. It memorises. That is not a defect in
%% the implementation and it is not a criticism of transformers: it is
%% what four thousand characters of training data buys. Attention learns
%% which positions matter, which is powerful and expensive; recurrence has
%% "read left to right, keep a running state" built in for free, and when
%% data is scarce a free correct prior beats a learned one. (The model_*
%% version of these two files, at 45 epochs and with that layer library's
%% own initialisation, tied at 0.5107 to the window; the expression version
%% reports what it measures.) One window of the 419 is 0.24 of a point, so
%% `test' calls anything closer than that a tie rather than reading noise
%% as a result. The scale at which attention starts winning is a fact
%% about data and context length, not about code: this window is sixteen
%% characters, and both architectures can hold sixteen characters.
%%
%% THE CORPUS IS DUPLICATED FROM LESSON 25 rather than imported, so that
%% the file runs from any directory. Byte for byte the same text, so the
%% comparison above is exact. SIZED FOR THE BUDGET: the score matrix is
%% [B*16, B*16] and its softmax and backward are the cost, so the batch is
%% 32 -- a [512, 512] matrix per head -- cycled in order, Adam at 0.002
%% for thirty epochs, 3540 steps; batches of 64 for 45 epochs ran past ten
%% minutes of libtorch on this CPU, against a budget of ten per goal.
%% Measured: train about four minutes under libtorch and three under
%% TensorFlow, test and predict seconds.
%%
%%   train    windows from the first ninety percent, 30 epochs of Adam; saved as t26_ctf
%%   test     next-character accuracy on the last tenth, against the baselines AND lesson 25; at least 0.40
%%   predict  the model continues `parent(tom, ' at three temperatures, the same noise as lesson 25
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/26-char-transformer.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/26-char-transformer.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/26-char-transformer.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the corpus, byte for byte lesson 25's --------------------------------
chunk(1, 'parent(tom, bob).\nparent(tom, liz).\nparent(bob, ann).\nparent(bob, pat).\nparent(pat, jim).\nmale(tom).   male(bob).   male(jim).\nfemale(liz). female(ann). female(pat).\ngrandparent(X, Z) :- parent(X, Y), parent(Y, Z).\ngrandfather(X, Z) :- grandparent(X, Z), male(X).\nsibling(A, B) :- parent(P, A), parent(P, B), A \\== B.\nmain :-\n    ( parent(tom, bob) -> R1 = yes ; R1 = no ),\n    must(\'parent(tom, bob)\', R1, yes),\n    ( parent(bob, tom) -> R2 = yes ; R2 = no ),\n    must(\'parent(bob, tom)\', R2, no),\n    format("~n-- leav').
chunk(2, 'e a blank and the same fact SEARCHES~n"),\n    findall(C, parent(tom, C), Children),\n    must(\'children of tom\', Children, [bob, liz]),\n    format("~n-- ...in either direction, which a function cannot do~n"),\n    findall(P, parent(P, ann), Parents),\n    must(\'parents of ann\', Parents, [bob]),\n    format("~n-- a rule is a fact with conditions~n"),\n    findall(X-Z, grandparent(X, Z), Gs),\n    must(\'every grandparent pair\', Gs, [tom-ann, tom-pat, bob-jim]),\n    findall(Z, grandfather(tom, Z), TomsGrandchildren),\n    mu').
chunk(3, 'st(\'tom is grandfather of\', TomsGrandchildren, [ann, pat]),\n    format("~n-- and rules stand on rules~n"),\n    findall(A-B, sibling(A, B), Sibs),\n    must(\'sibling pairs\', Sibs, [bob-liz, liz-bob, ann-pat, pat-ann]),\n    format("done~n").\nshow(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).\nmust(Label, Got, Want) :-\n    (   Got == Want\n    ->  format("   ~w = ~q~n", [Label, Got])\n        fail\n    ).\nmy_append([], Ys, Ys).\nmy_append([X|Xs], Ys, [X|Zs]) :- my_append(Xs, Ys, Zs).\nmy_length([], 0).\nmy_length([').
chunk(4, '_|T], N) :- my_length(T, M), N is M + 1.\nmy_member(X, [X|_]).\nmy_member(X, [_|T]) :- my_member(X, T).\nmain :-\n    format("~n-- a list is a term, and [H|T] takes it apart~n"),\n    [H|T] = [a, b, c],\n    must(\'head\', H, a),\n    must(\'tail\', T, [b, c]),\n    must(\'the term behind the sugar\', \'.\'(a, \'.\'(b, [])), [a, b]),\n    format("~n-- append/3 forwards: the use everybody knows~n"),\n    my_append([1, 2], [3, 4], Joined),\n    must(\'append([1,2], [3,4], X)\', Joined, [1, 2, 3, 4]),\n    format("~n-- BACKWARDS: the same cl').
chunk(5, 'auses, asked the other way~n"),\n    my_append(Front, [3, 4], [1, 2, 3, 4]),\n    must(\'what goes BEFORE [3,4]\', Front, [1, 2]),\n    format("~n-- and sideways: every way to cut a list in two~n"),\n    findall(A-B, my_append(A, B, [1, 2, 3]), Splits),\n    must(\'all splits of [1,2,3]\', Splits,\n         [[]-[1, 2, 3], [1]-[2, 3], [1, 2]-[3], [1, 2, 3]-[]]),\n    format("~n-- which makes prefix/suffix free, with no new code~n"),\n    ( my_append([1, 2], _, [1, 2, 3]) -> Pre = yes ; Pre = no ),\n    must(\'is [1,2] a prefix of').
chunk(6, ' [1,2,3]\', Pre, yes),\n    ( my_append(_, [9], [1, 2, 3]) -> Suf = yes ; Suf = no ),\n    must(\'does [1,2,3] end in 9\', Suf, no),\n    format("~n-- member/2 is a test AND a generator~n"),\n    ( my_member(2, [1, 2, 3]) -> In = yes ; In = no ),\n    must(\'2 in [1,2,3]\', In, yes),\n    findall(X, my_member(X, [a, b, c]), Each),\n    must(\'every element, one at a time\', Each, [a, b, c]),\n    my_length([a, b, c], Len),\n    must(\'length\', Len, 3),\n    length(BlankList, 3),\n    length(BlankList, HowMany),\n    must(\'length/2 can').
chunk(7, ' also MAKE a list of 3 holes\', HowMany, 3),\n    msort([c, a, b, a], Msorted),\n    must(\'msort([c,a,b,a])\', Msorted, [a, a, b, c]),\n    sort([c, a, b, a], Sorted),\n    must(\'sort([c,a,b,a])\', Sorted, [a, b, c]),\n    format("~ndone~n").\nshow(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).\nmust(Label, Got, Want) :-\n    (   Got == Want\n    ->  format("   ~w = ~q~n", [Label, Got])\n        fail\n    ).\nage(ann, 34).  age(bob, 34).  age(cyd, 41).\nlikes(ann, tea).  likes(ann, cake).  likes(bob, tea).\nmain :-\n    fo').
chunk(8, 'rmat("~n-- findall: every answer, in order, as a list~n"),\n    findall(N, age(N, _), Names),\n    must(\'every name\', Names, [ann, bob, cyd]),\n    findall(N-A, age(N, A), Pairs),\n    must(\'as pairs\', Pairs, [ann-34, bob-34, cyd-41]),\n    format("~n-- the template can be anything, and it is COPIED~n"),\n    findall(person(N), age(N, _), People),\n    findall(N, age(N, 99), Nobody),\n    must(\'nobody is 99\', Nobody, []),\n    format("~n-- bagof FAILS instead, which is a different claim~n"),\n    ( bagof(N, age(N, 99), _) ->').
chunk(9, ' B = answered ; B = failed ),\n    must(\'').

%% ---- shape and budget, in one place ----------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.
context(16).
epochs(30).
batch(32).
lr(0.002).

%% The same three baselines as lesson 25, over the same corpus and split,
%% plus the lstm's own result under libtorch -- because the interesting
%% comparison for a transformer here is not chance, it is the simpler
%% model. Stored to four places: 219 of 419.
baseline(uniform,      0.0130).
baseline(always_space, 0.2005).
baseline(bigram,       0.3294).
baseline(lstm_25,      0.5227).
threshold(0.40).

%% ---- corpus, vocabulary, windows: lesson 25's --------------------------------

%% sort/2 and not keysort/2, for the reason lesson 25 spells out: the three
%% goals consult this file into ONE store, so by `predict' every chunk fact
%% is there three times and keysort would keep them all.
corpus(Codes) :-
    findall(N-C, chunk(N, C), Pairs0),
    sort(Pairs0, Pairs),
    findall(C, member(_-C, Pairs), Chunks),
    join(Chunks, Atom),
    atom_codes(Atom, Codes), !.

join([], '') :- !.
join([A|As], Out) :- join(As, Rest), atom_concat(A, Rest, Out), !.

vocabulary(Vocab) :- corpus(Codes), sort(Codes, Vocab), !.
id(Vocab, Code, Id) :- nth0(Id, Vocab, Code), !.
code(Vocab, Id, Code) :- nth0(Id, Vocab, Code), !.

ids(_, [], []) :- !.
ids(Vocab, [C|Cs], [I|Is]) :- id(Vocab, C, I), ids(Vocab, Cs, Is), !.

windows(Ids, K, Xs, Ys) :-
    length(Ctx, K), append(Ctx, Rest, Ids),
    slide(Ctx, Rest, Xs, Ys), !.

slide(_, [], [], []) :- !.
slide(Ctx, [Next|Rest], [Ctx|Xs], [Next|Ys]) :-
    Ctx = [_|Tail], append(Tail, [Next], Ctx2),
    slide(Ctx2, Rest, Xs, Ys), !.

data(Vocab, V, Xs, Ys, N) :-
    corpus(Codes), vocabulary(Vocab), length(Vocab, V),
    ids(Vocab, Codes, Ids), context(K),
    windows(Ids, K, Xs, Ys), length(Xs, N), !.

split(N, NTrain) :- NTrain is truncate(N * 0.9), !.

take(Xs, N, Xs, []) :- length(Xs, L), L =< N, !.
take(Xs, N, Front, Rest) :- length(Front, N), append(Front, Rest, Xs), !.

%% batches(+Ws, +Ts, +V, +Size, -Bs): the windows in batches of Size, each
%% b(B, Ids, PosIds, Last, Y, Targets) -- Ids the B*16 ids WINDOW-MAJOR, so
%% a window is sixteen consecutive rows and the mask's blocks line up;
%% PosIds their positions 0..15; Last the row of each window's last
%% position, [15, 31, ...], for the head; Y the one-hot of the targets;
%% Targets the ids themselves, for accuracy/3. A rule, so exec/1 frees
%% what it makes.
batches([], [], _, _, []) --> !.
batches(Ws, Ts, V, Size, [b(B, Ids, PosIds, Last, Y, Tb)|Bs]) -->
    { take(Ws, Size, Wb, Wr), take(Ts, Size, Tb, Tr), length(Wb, B), context(K), K1 is K - 1, B1 is B - 1,
      findall(I, ( member(W, Wb), member(I, W) ), Flat),
      findall(P, ( member(_, Wb), between(0, K1, P) ), Pos),
      findall(R, ( between(0, B1, I), R is I * K + K1 ), Rows) },
    Ids = Flat, PosIds = Pos, Last = Rows, one_hot(Tb, V, Y),
    batches(Wr, Tr, V, Size, Bs).

%% sizes(+Bs, -Sizes): the distinct batch sizes -- 64, and the remainder.
sizes(Bs, Sizes) :- findall(B, member(b(B, _, _, _, _, _), Bs), Bs0), sort(Bs0, Sizes), !.

%% masks(+Sizes, -Masks): a causal mask per batch size, m(B, Mask); the
%% [B*16, B*16] matrix is built once and shared by every batch of that size.
masks([], []) --> [].
masks([B|Bs], [m(B, M)|Ms]) --> { context(K) }, causal_mask(B, K, M), masks(Bs, Ms).

%% ---- the network ----------------------------------------------------------------
%% D = 96, four heads of 24, the feed-forward 192 wide, GELU in it, and a
%% final layer norm before the head.

parameters(V, [Emb, Pos, G1, Bt1, Wq, Wk, Wv, Wo, G2, Bt2, W1, B1, W2, B2, G3, Bt3, Wout, Bout]) :-
    context(K),
    Emb := parameter(randn([V, 96]) * 0.3), Pos := parameter(randn([K, 96]) * 0.3),
    G1 := parameter(ones([1, 96])), Bt1 := parameter(zeros([1, 96])),
    Wq := parameter(glorot(96, 96)), Wk := parameter(glorot(96, 96)), Wv := parameter(glorot(96, 96)), Wo := parameter(glorot(96, 96)),
    G2 := parameter(ones([1, 96])), Bt2 := parameter(zeros([1, 96])),
    W1 := parameter(glorot(96, 192)), B1 := parameter(zeros([1, 192])),
    W2 := parameter(glorot(192, 96)), B2 := parameter(zeros([1, 96])),
    G3 := parameter(ones([1, 96])), Bt3 := parameter(zeros([1, 96])),
    Wout := parameter(glorot(96, V)), Bout := parameter(zeros([1, V])), !.

%% count(+Ps, -N): how many numbers the parameters hold.
count([], 0) :- !.
count([P|Ps], N) :- S := shape(P), product(S, K), count(Ps, N0), N is N0 + K, !.
product([], 1) :- !.
product([D|Ds], P) :- product(Ds, P0), P is P0 * D, !.

%% head//6 and forward//6 are PROCEDURES: DCG rules of bindings, and
%% exec(forward(...)) frees everything it and the heads made but Logits.
%% One head: its 24 columns of Q, K and V, the scores scaled by 1/sqrt(24),
%% the mask added, softmax, and the weighted sum of V.
head(Q, K, V, Mask, H, O) -->
    { F is H * 24, T is F + 24 },
    O = softmax(cols(Q, F, T) matmul transpose(cols(K, F, T)) * 0.2041241 + Mask) matmul cols(V, F, T).

%% forward(+Ps, +Ids, +PosIds, +Mask, +Last, -Logits): the block over a batch
%% of windows, and the logits of the character after each, [B, V], read
%% from each window's last position.
forward([Emb, Pos, G1, Bt1, Wq, Wk, Wv, Wo, G2, Bt2, W1, B1, W2, B2, G3, Bt3, Wout, Bout], Ids, PosIds, Mask, Last, Logits) -->
    E = index_rows(Emb, Ids) + index_rows(Pos, PosIds),
    X1 = layer_norm(E) * G1 + Bt1,
    Q = X1 matmul Wq, K = X1 matmul Wk, V = X1 matmul Wv,
    head(Q, K, V, Mask, 0, O0), head(Q, K, V, Mask, 1, O1),
    head(Q, K, V, Mask, 2, O2), head(Q, K, V, Mask, 3, O3),
    H = E + cat([O0, O1, O2, O3], 1) matmul Wo,
    X2 = layer_norm(H) * G2 + Bt2,
    Ff = H + gelu(X2 matmul W1 + B1) matmul W2 + B2,
    Xf = layer_norm(index_rows(Ff, Last)) * G3 + Bt3,
    Logits = Xf matmul Wout + Bout.

%% ---- the three goals --------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop, the evaluation over batches and the sampler stay
%% predicates in braces, since they step an optimiser that frees the old
%% parameters, or free a batch's logits before the next batch's are made.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(26),
    { data(_, V, Xs, Ys, N), split(N, NTrain), Held is N - NTrain,
      format("corpus: ~w windows over a vocabulary of ~w characters~n", [N, V]),
      format("training on ~w, holding out ~w~n", [NTrain, Held]),
      take(Xs, NTrain, XsTr, _), take(Ys, NTrain, YsTr, _), batch(Size) },
    batches(XsTr, YsTr, V, Size, Batches),
    { sizes(Batches, Sizes) }, masks(Sizes, Masks),
    { parameters(V, Ps0), count(Ps0, NP),
      format("~w parameters (the lstm of lesson 25 has 52093)~n", [NP]),
      adam_init(Ps0, St0), epochs(E), length(Batches, NB), Steps is E * NB, lr(LR),
      fit(Steps, Ps0, St0, Batches, Masks, NB, LR, Ps),
      evaluate(Ps, Batches, Masks, Nll, Acc),
      Uniform is log(V),
      format("trained: nll ~4f over the training windows, next-character accuracy ~2f~n", [Nll, Acc]),
      format("   untrained ~4f;  character frequencies alone 3.4288~n", [Uniform]) },
    params_save(t26_ctf, Ps),
    { write(saved), nl }.

%% fit(+K, +Ps, +State, +Batches, +Masks, +NB, +LR, -PsF): K steps of Adam,
%% the batches cycled in order, each under the mask of its size; the loss
%% is printed once an epoch.
fit(0, Ps, _, _, _, _, _, Ps) :- !.
fit(K, Ps, St, Batches, Masks, NB, LR, PsF) :-
    B is K mod NB, nth0(B, Batches, b(N, Ids, PosIds, Last, Y, _)), memberchk(m(N, Mask), Masks),
    exec(forward(Ps, Ids, PosIds, Mask, Last, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( B =:= 0 -> Lv := item(L), Left is K // NB, format("   ~w epochs to go, loss ~4f~n", [Left, Lv]) ; true ),
    adam_step(Ps, Gs, St, LR, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Batches, Masks, NB, LR, PsF).

%% evaluate(+Ps, +Batches, +Masks, -Nll, -Acc): the mean loss and the
%% accuracy over every window of the batches, a batch at a time -- a
%% predicate, so each batch's logits are freed before the next is made.
evaluate(Ps, Batches, Masks, Nll, Acc) :-
    evaluate(Batches, Ps, Masks, 0, 0.0, 0.0, Total, LossSum, Hits),
    Nll is LossSum / Total, Acc is Hits / Total, !.
evaluate([], _, _, T, L, H, T, L, H) :- !.
evaluate([b(N, Ids, PosIds, Last, Y, Ts)|Bs], Ps, Masks, T0, L0, H0, T, L, H) :-
    memberchk(m(N, Mask), Masks),
    exec(forward(Ps, Ids, PosIds, Mask, Last, Logits)),
    Lv := item(cross_entropy(Logits, Y)),
    accuracy(Logits, Ts, A),
    tensor_free(Logits),
    T1 is T0 + N, L1 is L0 + Lv * N, H1 is H0 + A * N,
    evaluate(Bs, Ps, Masks, T1, L1, H1, T, L, H).

test -->
    Ps = params(t26_ctf),
    { data(_, V, Xs, Ys, N), split(N, NTrain), Held is N - NTrain,
      take(Xs, NTrain, _, XsTe), take(Ys, NTrain, _, YsTe), batch(Size) },
    batches(XsTe, YsTe, V, Size, Batches),
    { sizes(Batches, Sizes) }, masks(Sizes, Masks),
    { evaluate(Ps, Batches, Masks, _, Acc),
      format("held-out next-character accuracy ~4f on ~w windows the training never saw~n", [Acc, Held]),
      forall(member(Name-Label,
                    [uniform-'uniform over the vocabulary',
                     always_space-'always predict a space',
                     bigram-'bigram argmax (no context)',
                     lstm_25-'the lstm of lesson 25']),
             ( baseline(Name, BV), format("   vs ~w: ~4f~n", [Label, BV]) )),
      %% WITHIN ONE WINDOW IS A TIE. There are 419 held-out windows, so one
      %% of them is 0.24 of a point; calling a difference smaller than that
      %% a win either way would be reading noise as a result.
      baseline(lstm_25, LstmAcc), Gap is Acc - LstmAcc,
      (   abs(Gap) < 0.0024
      ->  format("   -- the SAME, to the window, and the transformer pays three quarters more parameters for it~n")
      ;   Gap > 0
      ->  format("   -- the transformer is ahead here, by ~4f~n", [Gap])
      ;   Behind is -Gap, format("   -- the lstm is ahead, with three fifths of the parameters, by ~4f~n", [Behind])
      ),
      threshold(Floor),
      (   Acc >= Floor
      ->  format("above the ~2f floor, and so above the bigram model~n", [Floor]),
          write(ok), nl
      ;   format("BELOW THE FLOOR of ~2f: under the bigram baseline means the context~n", [Floor]),
          format("is not being used -- for a transformer that usually means the positional~n"),
          format("vectors are missing and attention has gone order-blind.~n"),
          write('FAIL'), nl, halt(1)
      ) }.

%% ---- generation, lesson 25's sampler ---------------------------------------
%% The same sin-hash noise indexed by the same countdown, so a sample here
%% and a sample there differ by the architecture and nothing else.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is abs(S - truncate(S)), !.

weights([], _, []) :- !.
weights([LP|LPs], T, [W|Ws]) :- W is exp(LP / T), weights(LPs, T, Ws), !.

total([], 0.0) :- !.
total([W|Ws], S) :- total(Ws, S0), S is S0 + W, !.

pick([_], _, _, 0) :- !.
pick([W|Ws], Target, Acc, Id) :-
    Acc1 is Acc + W,
    (   Target =< Acc1
    ->  Id = 0
    ;   pick(Ws, Target, Acc1, Id0), Id is Id0 + 1
    ), !.

sample(LogProbs, T, Step, Id) :-
    weights(LogProbs, T, Ws), total(Ws, Sum),
    noise(Step, R), Target is R * Sum,
    pick(Ws, Target, 0.0, Id), !.

%% next_char(+Ps, +One, +Ctx, +T, +Step, -Id): one window of one through
%% the block; One holds the positions, the last row and the mask for it.
next_char(Ps, one(PosIds, Last, Mask), Ctx, T, Step, Id) :-
    Ids := Ctx,
    exec(forward(Ps, Ids, PosIds, Mask, Last, Logits)),
    [LogProbs] := list(log_softmax(Logits)),
    free_all([Ids, Logits]),
    sample(LogProbs, T, Step, Id), !.

generate(_, _, _, _, _, 0, []) :- !.
generate(Ps, One, Vocab, Ctx, T, N, [Code|Rest]) :-
    next_char(Ps, One, Ctx, T, N, Id), code(Vocab, Id, Code),
    Ctx = [_|Tail], append(Tail, [Id], Ctx2),
    N1 is N - 1, generate(Ps, One, Vocab, Ctx2, T, N1, Rest), !.

prime(Vocab, Text, Ctx) :-
    context(K), atom_codes(Text, Codes0), ids(Vocab, Codes0, Ids0),
    length(Ids0, L),
    (   L >= K
    ->  Drop is L - K, length(Pre, Drop), append(Pre, Ctx, Ids0)
    ;   Pad is K - L, id(Vocab, 32, SpaceId),
        length(Padding, Pad), fill(Padding, SpaceId),
        append(Padding, Ids0, Ctx)
    ), !.

fill([], _) :- !.
fill([V|Vs], V) :- fill(Vs, V), !.

predict -->
    Ps = params(t26_ctf),
    { vocabulary(Vocab), context(K), K1 is K - 1, findall(P, between(0, K1, P), Pos) },
    PosIds = Pos, Last = [K1], causal_mask(1, K, Mask),
    { format("~n-- the transformer generating, at three temperatures~n"),
      format("   Same seed and same noise sequence as lesson 25, so what~n"),
      format("   differs between the two files is the architecture.~n~n"),
      forall(member(T-Label, [0.5-'0.5 (sharp)', 0.8-'0.8', 1.2-'1.2 (loose)']),
             ( prime(Vocab, 'parent(tom, ', Ctx),
               generate(Ps, one(PosIds, Last, Mask), Vocab, Ctx, T, 180, Out),
               atom_codes(Sample, Out),
               format("temperature ~w~n", [Label]),
               format("parent(tom, ~w~n~n", [Sample]) )),
      format("-- what to read in these~n"),
      format("   A recurrent state carries one thread forward; attention can look~n"),
      format("   anywhere in the sixteen characters at once. Whether that shows in~n"),
      format("   one seed and one noise sequence is an illustration, not a~n"),
      format("   measurement; the measurement is in `test', against lesson 25.~n"),
      format("~n"),
      format("-- what this lesson is actually for~n"),
      format("   Not to show that transformers are better. On four thousand~n"),
      format("   characters they are not, and the numbers in this file's header~n"),
      format("   say so. It is to show that the architecture is EXPRESSIONS --~n"),
      format("   a block you can read, edit and re-run -- and that swapping~n"),
      format("   recurrence for attention is a change to one procedure. The~n"),
      format("   scale at which attention starts winning is a fact about data,~n"),
      format("   not about code.~n"),
      write(done), nl }.
