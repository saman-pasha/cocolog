%% 25. A character-level language model, trained on cocolog itself
%%
%% A language model in the strict sense and the smallest honest one: a
%% distribution over the next character given the previous sixteen,
%% trained by maximum likelihood. The tokens are single characters, so the
%% vocabulary is whatever the corpus contains rather than anything learned
%% or negotiated, and the network is an embedding, an LSTM, and a head:
%%
%%     E  = index_rows(Emb, Ids)                    each character id becomes a learned vector of 16
%%     I  = sigmoid(X Wi + H Ui + Bi)   F = sigmoid(X Wf + H Uf + Bf)
%%     O  = sigmoid(X Wo + H Uo + Bo)   G = tanh(X Wg + H Ug + Bg)
%%     C2 = F * C + I * G               H2 = O * tanh(C2)                    the cell, 96 wide, sixteen times
%%     Logits = H matmul Wout + Bout    cross_entropy against the next character
%%
%% The four gates are four expressions through ONE defined function,
%% `gate(X, H, W, U, B) ::= X matmul W + H matmul U + B'; the cell is a
%% procedure of six bindings; the recurrence over the sixteen positions is
%% a rule recursing over them, threading H and C the way tutorial 41
%% threads its GRU state. The loss is the same objective a large language
%% model is trained on. What differs is scale, tokenisation and
%% architecture -- three enormous differences, and none of them a
%% difference in kind. (An earlier version of this file was a
%% `model_new([sequence(16), embedding(V, 16), lstm(96), dense(V, log_softmax)])'
%% trained by model_train; every line of the network is now in the open.)
%%
%% THE CORPUS IS EMBEDDED, not read from disk, so the file runs from any
%% directory. The text IS cocolog: it is drawn from
%% tutorials/basics/01-facts-and-rules.pl, 03-lists.pl and
%% 06-findall-and-friends.pl, cut at 520-character chunk boundaries rather
%% than at clause boundaries -- so the `must/3' inside it lost the line its
%% else-branch needed and is not readable Prolog. Harmless to a character
%% model, which is learning shapes. At four thousand characters it learns
%% the TEXTURE of cocolog, not its grammar: balanced-ish parentheses, `:-'
%% after a head, lowercase runs, a full stop before a newline. Expect
%% something that looks like Prolog from across the room and does not
%% compile. That is the honest result at this size.
%%
%% THE BASELINES, AND WHY UNIFORM IS THE WRONG ONE. Uniform over the 77
%% characters is 1.3%, and a gate set "fifteen times chance" at 20% would
%% be passed by a model that ALWAYS PREDICTS A SPACE, which scores 20.05%
%% on this held-out set. The baselines that matter are what a trivial
%% model reaches after seeing the data -- always-space, and the bigram
%% argmax at 32.94% -- so the floor is 40%: the first number that cannot
%% be reached without using CONTEXT, which is what the LSTM is for. All
%% three were computed over this exact corpus and the same 3765/419 split
%% the code makes; change the corpus and they are wrong.
%%
%% SIZED FOR THE BUDGET: 3765 training windows in batches of 64, cycled in
%% order, Adam at 0.006 for thirty epochs -- 1770 steps of sixteen cells
%% each -- ninety-six hidden units, 52,093 numbers. Measured on this Mac's
%% CPU: train about two minutes under either library, test seconds, predict
%% twenty seconds; held-out accuracy 0.5227 under libtorch and 0.5155 under
%% TensorFlow, the two libraries drawing different random starts.
%%
%%   train    windows from the first ninety percent, 30 epochs of Adam; saved as t25_charlm
%%   test     next-character accuracy on the last tenth, never trained on, at least 0.40
%%   predict  the model continues `parent(tom, ' at three temperatures
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/25-char-lm.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/25-char-lm.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/25-char-lm.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).

%% ---- the corpus, as real cocolog ---------------------------------------
chunk(1, 'parent(tom, bob).\nparent(tom, liz).\nparent(bob, ann).\nparent(bob, pat).\nparent(pat, jim).\nmale(tom).   male(bob).   male(jim).\nfemale(liz). female(ann). female(pat).\ngrandparent(X, Z) :- parent(X, Y), parent(Y, Z).\ngrandfather(X, Z) :- grandparent(X, Z), male(X).\nsibling(A, B) :- parent(P, A), parent(P, B), A \\== B.\nmain :-\n    ( parent(tom, bob) -> R1 = yes ; R1 = no ),\n    must(\'parent(tom, bob)\', R1, yes),\n    ( parent(bob, tom) -> R2 = yes ; R2 = no ),\n    must(\'parent(bob, tom)\', R2, no),\n    format("~n-- leav').
chunk(2, 'e a blank and the same fact SEARCHES~n"),\n    findall(C, parent(tom, C), Children),\n    must(\'children of tom\', Children, [bob, liz]),\n    format("~n-- ...in either direction, which a function cannot do~n"),\n    findall(P, parent(P, ann), Parents),\n    must(\'parents of ann\', Parents, [bob]),\n    format("~n-- a rule is a fact with conditions~n"),\n    findall(X-Z, grandparent(X, Z), Gs),\n    must(\'every grandparent pair\', Gs, [tom-ann, tom-pat, bob-jim]),\n    findall(Z, grandfather(tom, Z), TomsGrandchildren),\n    mu').
chunk(3, 'st(\'tom is grandfather of\', TomsGrandchildren, [ann, pat]),\n    format("~n-- and rules stand on rules~n"),\n    findall(A-B, sibling(A, B), Sibs),\n    must(\'sibling pairs\', Sibs, [bob-liz, liz-bob, ann-pat, pat-ann]),\n    format("done~n").\nshow(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).\nmust(Label, Got, Want) :-\n    (   Got == Want\n    ->  format("   ~w = ~q~n", [Label, Got])\n        fail\n    ).\nmy_append([], Ys, Ys).\nmy_append([X|Xs], Ys, [X|Zs]) :- my_append(Xs, Ys, Zs).\nmy_length([], 0).\nmy_length([').
chunk(4, '_|T], N) :- my_length(T, M), N is M + 1.\nmy_member(X, [X|_]).\nmy_member(X, [_|T]) :- my_member(X, T).\nmain :-\n    format("~n-- a list is a term, and [H|T] takes it apart~n"),\n    [H|T] = [a, b, c],\n    must(\'head\', H, a),\n    must(\'tail\', T, [b, c]),\n    must(\'the term behind the sugar\', \'.\'(a, \'.\'(b, [])), [a, b]),\n    format("~n-- append/3 forwards: the use everybody knows~n"),\n    my_append([1, 2], [3, 4], Joined),\n    must(\'append([1,2], [3,4], X)\', Joined, [1, 2, 3, 4]),\n    format("~n-- BACKWARDS: the same cl').
chunk(5, 'auses, asked the other way~n"),\n    my_append(Front, [3, 4], [1, 2, 3, 4]),\n    must(\'what goes BEFORE [3,4]\', Front, [1, 2]),\n    format("~n-- and sideways: every way to cut a list in two~n"),\n    findall(A-B, my_append(A, B, [1, 2, 3]), Splits),\n    must(\'all splits of [1,2,3]\', Splits,\n         [[]-[1, 2, 3], [1]-[2, 3], [1, 2]-[3], [1, 2, 3]-[]]),\n    format("~n-- which makes prefix/suffix free, with no new code~n"),\n    ( my_append([1, 2], _, [1, 2, 3]) -> Pre = yes ; Pre = no ),\n    must(\'is [1,2] a prefix of').
chunk(6, ' [1,2,3]\', Pre, yes),\n    ( my_append(_, [9], [1, 2, 3]) -> Suf = yes ; Suf = no ),\n    must(\'does [1,2,3] end in 9\', Suf, no),\n    format("~n-- member/2 is a test AND a generator~n"),\n    ( my_member(2, [1, 2, 3]) -> In = yes ; In = no ),\n    must(\'2 in [1,2,3]\', In, yes),\n    findall(X, my_member(X, [a, b, c]), Each),\n    must(\'every element, one at a time\', Each, [a, b, c]),\n    my_length([a, b, c], Len),\n    must(\'length\', Len, 3),\n    length(BlankList, 3),\n    length(BlankList, HowMany),\n    must(\'length/2 can').
chunk(7, ' also MAKE a list of 3 holes\', HowMany, 3),\n    msort([c, a, b, a], Msorted),\n    must(\'msort([c,a,b,a])\', Msorted, [a, a, b, c]),\n    sort([c, a, b, a], Sorted),\n    must(\'sort([c,a,b,a])\', Sorted, [a, b, c]),\n    format("~ndone~n").\nshow(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).\nmust(Label, Got, Want) :-\n    (   Got == Want\n    ->  format("   ~w = ~q~n", [Label, Got])\n        fail\n    ).\nage(ann, 34).  age(bob, 34).  age(cyd, 41).\nlikes(ann, tea).  likes(ann, cake).  likes(bob, tea).\nmain :-\n    fo').
chunk(8, 'rmat("~n-- findall: every answer, in order, as a list~n"),\n    findall(N, age(N, _), Names),\n    must(\'every name\', Names, [ann, bob, cyd]),\n    findall(N-A, age(N, A), Pairs),\n    must(\'as pairs\', Pairs, [ann-34, bob-34, cyd-41]),\n    format("~n-- the template can be anything, and it is COPIED~n"),\n    findall(person(N), age(N, _), People),\n    findall(N, age(N, 99), Nobody),\n    must(\'nobody is 99\', Nobody, []),\n    format("~n-- bagof FAILS instead, which is a different claim~n"),\n    ( bagof(N, age(N, 99), _) ->').
chunk(9, ' B = answered ; B = failed ),\n    must(\'').

%% ---- shape and budget, in one place --------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.
context(16).
epochs(30).
batch(64).
lr(0.006).

%% The baselines are constants because the corpus is embedded and fixed;
%% change the corpus and they are wrong -- recompute them, do not scale them.
baseline(uniform,      0.0130).
baseline(always_space, 0.2005).
baseline(bigram,       0.3294).
threshold(0.40).

%% ---- corpus, vocabulary, ids ---------------------------------------------

%% `sort/2' AND NOT `keysort/2': `run' consults this file into the store,
%% the store is the same for all three goals and CONSULT APPENDS, so by the
%% `test' process every chunk/2 fact is there twice. sort/2 orders AND
%% deduplicates on the whole term, so three consults give the same 4200
%% characters as one.
corpus(Codes) :-
    findall(N-C, chunk(N, C), Pairs0),
    sort(Pairs0, Pairs),
    findall(C, member(_-C, Pairs), Chunks),
    join(Chunks, Atom),
    atom_codes(Atom, Codes), !.

join([], '') :- !.
join([A|As], Out) :- join(As, Rest), atom_concat(A, Rest, Out), !.

%% THE VOCABULARY IS `sort/2' AND NOTHING ELSE: the distinct characters
%% come out sorted, so the id of a character is its position, stable
%% across runs, with no table to save alongside the weights.
vocabulary(Vocab) :- corpus(Codes), sort(Codes, Vocab), !.

id(Vocab, Code, Id) :- nth0(Id, Vocab, Code), !.
code(Vocab, Id, Code) :- nth0(Id, Vocab, Code), !.

ids(_, [], []) :- !.
ids(Vocab, [C|Cs], [I|Is]) :- id(Vocab, C, I), ids(Vocab, Cs, Is), !.

%% ---- windows -------------------------------------------------------------

%% Every position after the first K is one training example: the K ids
%% before it are the window, the id at it is the target. The context
%% SLIDES -- drop the oldest, append the newest -- rather than being re-cut
%% out of the id list each time, which would make the pass quadratic.
windows(Ids, K, Xs, Ys) :-
    length(Ctx, K),
    append(Ctx, Rest, Ids),
    slide(Ctx, Rest, Xs, Ys), !.

slide(_, [], [], []) :- !.
slide(Ctx, [Next|Rest], [Ctx|Xs], [Next|Ys]) :-
    Ctx = [_|Tail],
    append(Tail, [Next], Ctx2),
    slide(Ctx2, Rest, Xs, Ys), !.

%% data(-Vocab, -V, -Xs, -Ys, -N): every window of the corpus, as lists.
%% The last tenth is never trained on; `test' is the only goal that looks
%% at it, which is what makes its number worth printing.
data(Vocab, V, Xs, Ys, N) :-
    corpus(Codes), vocabulary(Vocab), length(Vocab, V),
    ids(Vocab, Codes, Ids), context(K),
    windows(Ids, K, Xs, Ys), length(Xs, N), !.

split(N, NTrain) :- NTrain is truncate(N * 0.9), !.

take(Xs, N, Xs, []) :- length(Xs, L), L =< N, !.
take(Xs, N, Front, Rest) :- length(Front, N), append(Front, Rest, Xs), !.

%% batches(+Ws, +Ts, +V, +Size, -Bs): the windows in batches of Size, each
%% b(B, Ids, Y, Targets) -- Ids an index tensor of the B*16 ids TIME-MAJOR
%% (every window's first character, then every window's second, ...), so
%% one embedding lookup answers all sixteen steps and `rows' slices step t
%% out of it; Y the one-hot of the targets; Targets the ids themselves, for
%% accuracy/3. A rule, so the tensors it makes are freed by exec/1.
batches([], [], _, _, []) --> !.
batches(Ws, Ts, V, Size, [b(B, Ids, Y, Tb)|Bs]) -->
    { take(Ws, Size, Wb, Wr), take(Ts, Size, Tb, Tr), length(Wb, B), context(K), K1 is K - 1,
      findall(I, ( between(0, K1, T), member(W, Wb), nth0(T, W, I) ), Flat) },
    Ids = Flat, one_hot(Tb, V, Y),
    batches(Wr, Tr, V, Size, Bs).

%% ---- the network ------------------------------------------------------------
%% Embeddings of 16, a hidden state of 96; the forget gate's bias starts at
%% one, so the cell begins by remembering.

parameters(V, [Emb, Wi, Ui, Bi, Wf, Uf, Bf, Wo, Uo, Bo, Wg, Ug, Bg, Wout, Bout]) :-
    Emb := parameter(randn([V, 16]) * 0.3),
    Wi := parameter(glorot(16, 96)), Ui := parameter(glorot(96, 96)), Bi := parameter(zeros([1, 96])),
    Wf := parameter(glorot(16, 96)), Uf := parameter(glorot(96, 96)), Bf := parameter(ones([1, 96])),
    Wo := parameter(glorot(16, 96)), Uo := parameter(glorot(96, 96)), Bo := parameter(zeros([1, 96])),
    Wg := parameter(glorot(16, 96)), Ug := parameter(glorot(96, 96)), Bg := parameter(zeros([1, 96])),
    Wout := parameter(glorot(96, V)), Bout := parameter(zeros([1, V])), !.

%% count(+Ps, -N): how many numbers the parameters hold.
count([], 0) :- !.
count([P|Ps], N) :- S := shape(P), product(S, K), count(Ps, N0), N is N0 + K, !.
product([], 1) :- !.
product([D|Ds], P) :- product(Ds, P0), P is P0 * D, !.

%% gate/5 is a DEFINED FUNCTION: a clause `Head ::= Body', used by name in
%% any expression -- the same pre-activation for all four gates.
gate(X, H, W, U, B) ::= X matmul W + H matmul U + B.

%% lstm(+Cell, +X, +H, +C, -H2, -C2): one step -- input, forget and output
%% gates, the candidate, the new memory and the new state. A PROCEDURE: a
%% DCG rule of six bindings, its output list every tensor it made, threaded
%% up to whoever called it.
lstm([Wi, Ui, Bi, Wf, Uf, Bf, Wo, Uo, Bo, Wg, Ug, Bg], X, H, C, H2, C2) -->
    I = sigmoid(gate(X, H, Wi, Ui, Bi)),
    F = sigmoid(gate(X, H, Wf, Uf, Bf)),
    O = sigmoid(gate(X, H, Wo, Uo, Bo)),
    G = tanh(gate(X, H, Wg, Ug, Bg)),
    C2 = F * C + I * G,
    H2 = O * tanh(C2).

%% forward(+Ps, +Ids, +B, -Logits): B windows, their ids time-major in Ids,
%% read left to right from a zero state; the logits of the character after
%% each window, [B, V], from the last state. exec(forward(...)) frees every
%% gate and state along the way and keeps Logits.
forward([Emb|Rest], Ids, B, Logits) -->
    { length(Cell, 12), append(Cell, [Wout, Bout], Rest), context(K) },
    E = index_rows(Emb, Ids),
    H0 = zeros([B, 96]), C0 = zeros([B, 96]),
    steps(0, K, E, B, Cell, H0, C0, H),
    Logits = H matmul Wout + Bout.

steps(K, K, _, _, _, H, _, H) --> !.
steps(T, K, E, B, Cell, H, C, HF) -->
    { From is T * B, To is From + B },
    X = rows(E, From, To),
    lstm(Cell, X, H, C, H2, C2),
    { T1 is T + 1 },
    steps(T1, K, E, B, Cell, H2, C2, HF).

%% ---- the three goals ----------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop and the sampler stay predicates in braces, since one
%% steps an optimiser that frees the old parameters and the other frees as
%% it goes.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(25),
    { data(_, V, Xs, Ys, N), split(N, NTrain), Held is N - NTrain,
      format("corpus: ~w windows over a vocabulary of ~w characters~n", [N, V]),
      format("training on ~w, holding out ~w~n", [NTrain, Held]),
      take(Xs, NTrain, XsTr, _), take(Ys, NTrain, YsTr, _), batch(Size) },
    batches(XsTr, YsTr, V, Size, Batches),
    batches(XsTr, YsTr, V, NTrain, [b(_, IdsAll, YAll, TsAll)]),
    { parameters(V, Ps0), count(Ps0, NP),
      format("~w parameters~n", [NP]),
      adam_init(Ps0, St0), epochs(E), length(Batches, NB), Steps is E * NB, lr(LR),
      fit(Steps, Ps0, St0, Batches, NB, LR, Ps) },
    forward(Ps, IdsAll, NTrain, Logits),
    Nll = item(cross_entropy(Logits, YAll)),
    accuracy(Logits, TsAll, Acc),
    %% THE LOSS IS IN NATS, and it wants two comparators, because only the
    %% second is about language: log(77) = 4.3438 is what an untrained model
    %% scores; 3.4288 is the entropy of this corpus's character frequencies,
    %% what a model that learned only which characters are common would
    %% score. Beating the first proves the optimiser ran; only beating the
    %% second proves something was learned about cocolog.
    { Uniform is log(V),
      format("trained: nll ~4f over the training windows, next-character accuracy ~2f~n", [Nll, Acc]),
      format("   untrained ~4f;  character frequencies alone 3.4288~n", [Uniform]) },
    params_save(t25_charlm, Ps),
    { write(saved), nl }.

%% fit(+K, +Ps, +State, +Batches, +NB, +LR, -PsF): K steps of Adam, the
%% batches cycled in order; the loss is printed once an epoch.
fit(0, Ps, _, _, _, _, Ps) :- !.
fit(K, Ps, St, Batches, NB, LR, PsF) :-
    B is K mod NB, nth0(B, Batches, b(N, Ids, Y, _)),
    exec(forward(Ps, Ids, N, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( B =:= 0 -> Lv := item(L), Left is K // NB, format("   ~w epochs to go, loss ~4f~n", [Left, Lv]) ; true ),
    adam_step(Ps, Gs, St, LR, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Batches, NB, LR, PsF).

test -->
    Ps = params(t25_charlm),
    { data(_, V, Xs, Ys, N), split(N, NTrain), Held is N - NTrain,
      take(Xs, NTrain, _, XsTe), take(Ys, NTrain, _, YsTe) },
    batches(XsTe, YsTe, V, Held, [b(_, Ids, _, Ts)]),
    forward(Ps, Ids, Held, Logits),
    accuracy(Logits, Ts, Acc),
    %% PRINTED BESIDE THE BASELINES, ALWAYS. A score with no comparator is a
    %% decoration, and the comparator that matters is not chance -- it is
    %% what a trivial model reaches after seeing the same data.
    { format("held-out next-character accuracy ~4f on ~w windows the training never saw~n", [Acc, Held]),
      forall(member(Name-Label,
                    [uniform-'uniform over the vocabulary',
                     always_space-'always predict a space',
                     bigram-'bigram argmax (no context)']),
             ( baseline(Name, BV), format("   vs ~w: ~4f~n", [Label, BV]) )),
      threshold(Floor),
      (   Acc >= Floor
      ->  format("above the ~2f floor, and so above the bigram model~n", [Floor]),
          write(ok), nl
      ;   format("BELOW THE FLOOR of ~2f: a score at or under the bigram baseline~n", [Floor]),
          format("means the context is not being used, which is the whole of what this is.~n"),
          write('FAIL'), nl, halt(1)
      ) }.

%% ---- generation ----------------------------------------------------------

%% NO `random/1' IN THIS DIALECT, so the sampler carries its own: the
%% fractional part of a large multiple of a sine, indexed by the countdown
%% -- so the three temperatures below consume the IDENTICAL sequence of
%% random values and differ only in the temperature applied to them: an
%% ablation, not three draws.
noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is abs(S - truncate(S)), !.

%% Log-probabilities to weights at a temperature: below 1 sharpens toward
%% the argmax, above 1 flattens toward uniform. The exponential is taken
%% AFTER the division, which is the whole of what temperature is.
weights([], _, []) :- !.
weights([LP|LPs], T, [W|Ws]) :- W is exp(LP / T), weights(LPs, T, Ws), !.

total([], 0.0) :- !.
total([W|Ws], S) :- total(Ws, S0), S is S0 + W, !.

%% Walk the weights until the running total passes the target; the last
%% clause guards against a target floating-point error left just above the
%% sum, answering the final index rather than failing.
pick([_], _, _, 0) :- !.
pick([W|Ws], Target, Acc, Id) :-
    Acc1 is Acc + W,
    (   Target =< Acc1
    ->  Id = 0
    ;   pick(Ws, Target, Acc1, Id0),
        Id is Id0 + 1
    ), !.

sample(LogProbs, T, Step, Id) :-
    weights(LogProbs, T, Ws),
    total(Ws, Sum),
    noise(Step, R),
    Target is R * Sum,
    pick(Ws, Target, 0.0, Id), !.

%% next_char(+Ps, +Ctx, +T, +Step, -Id): the context in, one window of one,
%% log-probabilities out of the expression, one character chosen.
next_char(Ps, Ctx, T, Step, Id) :-
    Ids := Ctx,
    exec(forward(Ps, Ids, 1, Logits)),
    [LogProbs] := list(log_softmax(Logits)),
    free_all([Ids, Logits]),
    sample(LogProbs, T, Step, Id), !.

generate(_, _, _, _, 0, []) :- !.
generate(Ps, Vocab, Ctx, T, N, [Code|Rest]) :-
    next_char(Ps, Ctx, T, N, Id),
    code(Vocab, Id, Code),
    Ctx = [_|Tail],
    append(Tail, [Id], Ctx2),
    N1 is N - 1,
    generate(Ps, Vocab, Ctx2, T, N1, Rest), !.

%% prime(+Vocab, +Text, -Ctx): a piece of real cocolog, cut or padded with
%% spaces to the context width. 32 is the space, written as a number
%% because `0' followed by a space is a character literal that depends on
%% the reader agreeing with you about whitespace.
prime(Vocab, Text, Ctx) :-
    context(K),
    atom_codes(Text, Codes0),
    ids(Vocab, Codes0, Ids0),
    length(Ids0, L),
    (   L >= K
    ->  Drop is L - K, length(Pre, Drop), append(Pre, Ctx, Ids0)
    ;   Pad is K - L,
        id(Vocab, 32, SpaceId),
        length(Padding, Pad), fill(Padding, SpaceId),
        append(Padding, Ids0, Ctx)
    ), !.

fill([], _) :- !.
fill([V|Vs], V) :- fill(Vs, V), !.

predict -->
    Ps = params(t25_charlm),
    { vocabulary(Vocab),
      format("~n-- one character at a time, at three temperatures~n"),
      format("   The seed is real cocolog; everything after the arrow is the~n"),
      format("   model's. Read it for TEXTURE, not for grammar.~n~n"),
      forall(member(T-Label, [0.5-'0.5 (sharp)', 0.8-'0.8', 1.2-'1.2 (loose)']),
             ( prime(Vocab, 'parent(tom, ', Ctx),
               generate(Ps, Vocab, Ctx, T, 180, Out),
               atom_codes(Sample, Out),
               format("temperature ~w~n", [Label]),
               format("parent(tom, ~w~n~n", [Sample]) )),
      format("-- what to look for~n"),
      format("   What temperature DOES is certain, because it is one division:~n"),
      format("   below 1 it sharpens the distribution toward the argmax, above 1~n"),
      format("   it flattens it toward uniform. The failure modes are the two a~n"),
      format("   sampler always has: a low temperature that collapses into~n"),
      format("   repeating whatever the corpus does most, and a high one that~n"),
      format("   emits character pairs which never occur in cocolog. If some~n"),
      format("   middle setting reads better than both, that is the trade~n"),
      format("   working as designed.~n"),
      write(done), nl }.
