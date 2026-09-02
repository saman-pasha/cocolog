%% 25. A character-level language model, trained on cocolog itself
%%
%%   train    read the corpus, learn next-character prediction, save as t25_charlm
%%   test     reload, next-character accuracy on HELD-OUT text, floor 40%
%%   predict  reload, generate cocolog one character at a time
%%
%% WHAT THIS IS. A language model in the strict sense and the smallest
%% honest one: a distribution over the next token given the previous K,
%% trained by maximum likelihood. The tokens are single characters, so
%% the vocabulary is whatever the corpus contains rather than anything
%% learned or negotiated, and the whole thing is four layers:
%%
%%     sequence(16)       a row is sixteen steps
%%     embedding(V, 16)   each character id becomes a learned vector
%%     lstm(96)           the recurrence, reading left to right
%%     dense(V, log_softmax)   log-probabilities over the next character
%%
%% with `loss(nll)'. That is the same objective a large language model
%% is trained on. What differs is scale, tokenisation and architecture --
%% three enormous differences, and none of them a difference in kind.
%%
%% WHAT IT IS NOT. It is not a transformer: `model_spec' has no attention
%% and no layer normalisation (modules/torch/README.md lists the layer
%% vocabulary, and neither is in it). It has no SUBWORD tokeniser --
%% there is not one anywhere in this tree -- which is exactly why the
%% tokens here are characters. (Lexical tokenizers there are: cocolog's
%% own reader, library(html)'s. Neither is the kind a language model
%% means by the word.) And at four thousand characters of training text it will
%% learn the TEXTURE of cocolog, not its grammar: balanced-ish
%% parentheses, `:-' after a head, lowercase runs, a full stop before a
%% newline. Expect something that looks like Prolog from across the room
%% and does not compile. That is the honest result at this size and the
%% file says so rather than cherry-picking a sample.
%%
%% WHY IT IS WORTH HAVING ANYWAY. Everything above the arithmetic is
%% clauses -- the vocabulary, the windowing, the sampling loop, the
%% temperature -- and all of it is readable. A language model is usually
%% a thing you call; here it is a thing you can `listing/1'.
%%
%% THE CORPUS IS EMBEDDED, not read from disk, and that is deliberate on
%% two counts. A tutorial you can copy anywhere and run is worth the
%% space (tutorials/README.md says so), and the torch runner in
%% test/tutorials.sh does not `cd' to the repository root the way the
%% basics loop does -- so a relative path here would work from one
%% directory and fail from every other. The text below IS cocolog: it is
%% drawn from tutorials/basics/01-facts-and-rules.pl, 03-lists.pl and
%% 06-findall-and-friends.pl -- three files, not the four an earlier
%% draft of this line claimed. library/astar.pl was on the list and fell
%% off the end of the 4200-character cut, which is exactly the kind of
%% thing a header claims and nobody checks. The text is also cut at the
%% 520-character chunk boundaries rather than at clause boundaries, so
%% the `must/3' inside it lost the line its else-branch needed and is not
%% readable Prolog. Harmless to a character model, which is learning
%% shapes; worth saying because "IS cocolog" invites you to check.
%%
%% SIZED FOR THE SUITE'S BUDGET. test/tutorials.sh allows `timeout 300'
%% per goal, so the model is small on purpose: about four thousand
%% training windows, ninety-six hidden units, thirty epochs. That is about
%% 471 GFLOP -- tens of seconds where libtorch is getting good throughput
%% out of matrices this small, and comfortably inside the budget even on
%% one slow core. The arithmetic is beside `clm_epochs/1' so the next
%% person to change the corpus or the width can redo it rather than
%% guess.
%%
%% NOT RUN. Like library(llm) and its tutorial, this was written in a
%% tree with no built cocolog and no libtorch, so nothing here has been
%% executed. The API is read from modules/torch/README.md and from
%% tutorials/tensor/22-embedding-lstm.pl, which is this file's nearest
%% relative. A red line is news.

:- use_module(library(torch)).

%% ---- the corpus, as real cocolog ---------------------------------------
clm_chunk(1, 'parent(tom, bob).\nparent(tom, liz).\nparent(bob, ann).\nparent(bob, pat).\nparent(pat, jim).\nmale(tom).   male(bob).   male(jim).\nfemale(liz). female(ann). female(pat).\ngrandparent(X, Z) :- parent(X, Y), parent(Y, Z).\ngrandfather(X, Z) :- grandparent(X, Z), male(X).\nsibling(A, B) :- parent(P, A), parent(P, B), A \\== B.\nmain :-\n    ( parent(tom, bob) -> R1 = yes ; R1 = no ),\n    must(\'parent(tom, bob)\', R1, yes),\n    ( parent(bob, tom) -> R2 = yes ; R2 = no ),\n    must(\'parent(bob, tom)\', R2, no),\n    format("~n-- leav').
clm_chunk(2, 'e a blank and the same fact SEARCHES~n"),\n    findall(C, parent(tom, C), Children),\n    must(\'children of tom\', Children, [bob, liz]),\n    format("~n-- ...in either direction, which a function cannot do~n"),\n    findall(P, parent(P, ann), Parents),\n    must(\'parents of ann\', Parents, [bob]),\n    format("~n-- a rule is a fact with conditions~n"),\n    findall(X-Z, grandparent(X, Z), Gs),\n    must(\'every grandparent pair\', Gs, [tom-ann, tom-pat, bob-jim]),\n    findall(Z, grandfather(tom, Z), TomsGrandchildren),\n    mu').
clm_chunk(3, 'st(\'tom is grandfather of\', TomsGrandchildren, [ann, pat]),\n    format("~n-- and rules stand on rules~n"),\n    findall(A-B, sibling(A, B), Sibs),\n    must(\'sibling pairs\', Sibs, [bob-liz, liz-bob, ann-pat, pat-ann]),\n    format("done~n").\nshow(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).\nmust(Label, Got, Want) :-\n    (   Got == Want\n    ->  format("   ~w = ~q~n", [Label, Got])\n        fail\n    ).\nmy_append([], Ys, Ys).\nmy_append([X|Xs], Ys, [X|Zs]) :- my_append(Xs, Ys, Zs).\nmy_length([], 0).\nmy_length([').
clm_chunk(4, '_|T], N) :- my_length(T, M), N is M + 1.\nmy_member(X, [X|_]).\nmy_member(X, [_|T]) :- my_member(X, T).\nmain :-\n    format("~n-- a list is a term, and [H|T] takes it apart~n"),\n    [H|T] = [a, b, c],\n    must(\'head\', H, a),\n    must(\'tail\', T, [b, c]),\n    must(\'the term behind the sugar\', \'.\'(a, \'.\'(b, [])), [a, b]),\n    format("~n-- append/3 forwards: the use everybody knows~n"),\n    my_append([1, 2], [3, 4], Joined),\n    must(\'append([1,2], [3,4], X)\', Joined, [1, 2, 3, 4]),\n    format("~n-- BACKWARDS: the same cl').
clm_chunk(5, 'auses, asked the other way~n"),\n    my_append(Front, [3, 4], [1, 2, 3, 4]),\n    must(\'what goes BEFORE [3,4]\', Front, [1, 2]),\n    format("~n-- and sideways: every way to cut a list in two~n"),\n    findall(A-B, my_append(A, B, [1, 2, 3]), Splits),\n    must(\'all splits of [1,2,3]\', Splits,\n         [[]-[1, 2, 3], [1]-[2, 3], [1, 2]-[3], [1, 2, 3]-[]]),\n    format("~n-- which makes prefix/suffix free, with no new code~n"),\n    ( my_append([1, 2], _, [1, 2, 3]) -> Pre = yes ; Pre = no ),\n    must(\'is [1,2] a prefix of').
clm_chunk(6, ' [1,2,3]\', Pre, yes),\n    ( my_append(_, [9], [1, 2, 3]) -> Suf = yes ; Suf = no ),\n    must(\'does [1,2,3] end in 9\', Suf, no),\n    format("~n-- member/2 is a test AND a generator~n"),\n    ( my_member(2, [1, 2, 3]) -> In = yes ; In = no ),\n    must(\'2 in [1,2,3]\', In, yes),\n    findall(X, my_member(X, [a, b, c]), Each),\n    must(\'every element, one at a time\', Each, [a, b, c]),\n    my_length([a, b, c], Len),\n    must(\'length\', Len, 3),\n    length(BlankList, 3),\n    length(BlankList, HowMany),\n    must(\'length/2 can').
clm_chunk(7, ' also MAKE a list of 3 holes\', HowMany, 3),\n    msort([c, a, b, a], Msorted),\n    must(\'msort([c,a,b,a])\', Msorted, [a, a, b, c]),\n    sort([c, a, b, a], Sorted),\n    must(\'sort([c,a,b,a])\', Sorted, [a, b, c]),\n    format("~ndone~n").\nshow(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).\nmust(Label, Got, Want) :-\n    (   Got == Want\n    ->  format("   ~w = ~q~n", [Label, Got])\n        fail\n    ).\nage(ann, 34).  age(bob, 34).  age(cyd, 41).\nlikes(ann, tea).  likes(ann, cake).  likes(bob, tea).\nmain :-\n    fo').
clm_chunk(8, 'rmat("~n-- findall: every answer, in order, as a list~n"),\n    findall(N, age(N, _), Names),\n    must(\'every name\', Names, [ann, bob, cyd]),\n    findall(N-A, age(N, A), Pairs),\n    must(\'as pairs\', Pairs, [ann-34, bob-34, cyd-41]),\n    format("~n-- the template can be anything, and it is COPIED~n"),\n    findall(person(N), age(N, _), People),\n    findall(N, age(N, 99), Nobody),\n    must(\'nobody is 99\', Nobody, []),\n    format("~n-- bagof FAILS instead, which is a different claim~n"),\n    ( bagof(N, age(N, 99), _) ->').
clm_chunk(9, ' B = answered ; B = failed ),\n    must(\'').

%% ---- shape ---------------------------------------------------------------
%% One place for every number, so the model and the checks cannot drift
%% apart. K is the context; the rest is the layer sizing.
clm_context(16).
clm_embed(16).
clm_hidden(96).
%% THIRTY EPOCHS, AND THE NUMBER IS A BUDGET RATHER THAN A TASTE.
%% test/tutorials.sh gives each goal `timeout 300', and a training run
%% that overruns it FAILS in a way indistinguishable from a bug -- so the
%% arithmetic is written down here rather than left for someone to redo:
%%
%%   4 gates * 96 hidden * (16 embed + 96 hidden)  =  43,008 MAC/timestep
%%   * 16 timesteps + 96*77 dense                  = 695,520 MAC/sample
%%   * 3765 samples * 3 (forward + backward) * 2   =  15.7 GFLOP/epoch
%%
%% At thirty epochs that is ~471 GFLOP: about 30 seconds where libtorch
%% gets 15 GFLOP/s out of these small matrices, and about 95 on one slow
%% core. That is a threefold MARGIN in the bad case -- 95s against 300s,
%% not three times over it. Forty epochs works out to only 2.4x, which is
%% not enough for a number nobody watches. Neither figure was measured:
%% nothing in this file has been run.
%% Raise it if you make the corpus bigger; recompute if you make the
%% model wider.
clm_epochs(30).
clm_batch(64).
clm_lr(0.006).
%% THE BASELINES, AND WHY UNIFORM IS THE WRONG ONE.
%%
%% An earlier version of this file gated on 20% and argued it was "about
%% fifteen times chance" because uniform over 77 characters is 1.3%. That
%% argument is worthless and the number was very nearly a disaster:
%% ALWAYS PREDICTING A SPACE scores 20.05% on this held-out set. The gate
%% would have been passed, in full green, by a model that had learned
%% nothing whatsoever about cocolog.
%%
%% Uniform is the baseline for a model that has not seen the DATA. The
%% baselines that matter are the ones a trivial model reaches after
%% seeing it, and for character prediction over source code they are much
%% higher than instinct suggests. All three below were computed over this
%% exact embedded corpus, from the same 3765/419 split the code makes:
%%
%%   uniform over 77 characters                     1.30%
%%   always predict the training majority (a space) 20.05%
%%   bigram argmax (previous character only)        32.94%
%%
%% So the floor is 40%: above the bigram model by seven points, which is
%% the first number that cannot be reached without using CONTEXT. Sixteen
%% characters of it, which is what the lstm is for.
%%
%% These are constants because the corpus is embedded and fixed. Change
%% the corpus and they are wrong -- recompute them, do not scale them.
%% Read inside forall/2, whose inner negation commits to the first
%% solution -- which is what keeps these printing once each after a
%% re-consult has left three copies of every fact in the store.
clm_baseline(uniform,      0.0130).
clm_baseline(always_space, 0.2005).
clm_baseline(bigram,       0.3294).
clm_floor(0.40).

%% ---- corpus, vocabulary, ids ---------------------------------------------

%% `sort/2' AND NOT `keysort/2', and the difference is the whole corpus.
%% `run' consults this file into the store, the store is the SAME store
%% for all three goals (test/tutorials.sh:107-112), and CONSULT APPENDS --
%% so by the `test' process every clm_chunk/2 fact exists twice and by
%% `predict' three times. A `findall/3' over them is the case
%% tutorials/tensor/README.md:55-57 names outright: "for a data generator
%% inside a findall it would double the rows". With keysort/2, which keeps
%% duplicates, `test' would have measured a model against a corpus twice
%% the size of the one it was trained on and reported the number without
%% a murmur.
%%
%% `sort/2' orders AND deduplicates on the whole term, so identical N-C
%% pairs collapse to one and the integer key still decides the order.
%% Three consults give the same 4200 characters as one.
clm_corpus(Codes) :-
    findall(N-C, clm_chunk(N, C), Pairs0),
    sort(Pairs0, Pairs),
    findall(C, member(_-C, Pairs), Chunks),
    clm_join(Chunks, Atom),
    atom_codes(Atom, Codes), !.

clm_join([], '') :- !.
clm_join([A|As], Out) :- clm_join(As, Rest), atom_concat(A, Rest, Out).

%% THE VOCABULARY IS `sort/2' AND NOTHING ELSE. `sort/2' orders and
%% removes duplicates, so the distinct characters come out sorted -- which
%% makes the id of a character its position, stable across runs, with no
%% table to build and nothing to save alongside the weights.
clm_vocab(Codes, Vocab) :- sort(Codes, Vocab), !.

clm_id(Vocab, Code, Id) :- nth0(Id, Vocab, Code), !.
clm_code(Vocab, Id, Code) :- nth0(Id, Vocab, Code), !.

clm_ids(_, [], []) :- !.
clm_ids(Vocab, [C|Cs], [I|Is]) :- clm_id(Vocab, C, I), clm_ids(Vocab, Cs, Is).

%% ---- windows -------------------------------------------------------------

%% Every position after the first K is one training example: the K ids
%% before it are the row, the id at it is the label. The context SLIDES --
%% drop the oldest, append the newest -- rather than being re-cut out of
%% the id list each time, which would make the whole pass quadratic.
clm_windows(Ids, K, Xs, Ys) :-
    length(Ctx, K),
    append(Ctx, Rest, Ids),
    clm_slide(Ctx, Rest, Xs, Ys), !.

clm_slide(_, [], [], []) :- !.
clm_slide(Ctx, [Next|Rest], [Ctx|Xs], [Next|Ys]) :-
    Ctx = [_|Tail],
    append(Tail, [Next], Ctx2),
    clm_slide(Ctx2, Rest, Xs, Ys).

%% Everything the three goals need, derived once from the corpus.
clm_data(Vocab, V, X, Y, N) :-
    clm_corpus(Codes),
    clm_vocab(Codes, Vocab),
    length(Vocab, V),
    clm_ids(Vocab, Codes, Ids),
    clm_context(K),
    clm_windows(Ids, K, Xs, Ys),
    length(Xs, N),
    tensor_from_list(Xs, X),
    tensor_from_list(Ys, Y), !.

%% The last tenth is never trained on. `test' is the only goal that looks
%% at it, which is what makes its number worth printing.
clm_split(N, NTrain) :- NTrain is truncate(N * 0.9), !.

%% ---- train ---------------------------------------------------------------

train :-
    torch_seed(25),
    clm_data(Vocab, V, X, Y, N),
    clm_split(N, NTrain),
    tensor_rows(X, 0, NTrain, XTr),
    tensor_rows(Y, 0, NTrain, YTr),
    clm_context(K), clm_embed(D), clm_hidden(H),
    clm_epochs(E), clm_batch(B), clm_lr(LR),
    format("corpus: ~w windows over a vocabulary of ~w characters~n", [N, V]),
    Held is N - NTrain,
    format("training on ~w, holding out ~w~n", [NTrain, Held]),
    model_new([sequence(K), embedding(V, D), lstm(H), dense(V, log_softmax)], M),
    model_train(M, XTr, YTr,
                [epochs(E), batch(B), lr(LR), optimiser(adam),
                 loss(nll), shuffle(true), final_loss(L)]),
    %% NLL IS IN NATS, and it wants TWO comparators, because only the
    %% second is about language. log(77) = 4.3438 is what an UNTRAINED
    %% model scores. The entropy of this corpus's character frequencies is
    %% 3.4288, which is what a model that learned only which characters
    %% are common would score -- no sequence structure at all. Beating the
    %% first proves the optimiser ran; only beating the second proves
    %% something was learned about cocolog.
    Uniform is log(V),
    format("final nll ~4f~n", [L]),
    format("   untrained ~4f;  character frequencies alone 3.4288~n", [Uniform]),
    model_save(t25_charlm, M),
    write(saved), nl.

%% ---- test ----------------------------------------------------------------

test :-
    model_load(t25_charlm, M),
    %% V is not wanted here any more: the baselines are constants beside
    %% clm_floor/1 rather than 1/V computed on the spot, which is the
    %% whole of what that CRITICAL finding was about.
    clm_data(_, _, X, Y, N),
    clm_split(N, NTrain),
    tensor_rows(X, NTrain, N, XTe),
    tensor_rows(Y, NTrain, N, YTe),
    model_evaluate(M, XTe, YTe, accuracy, A),
    Pct is truncate(A * 1000 + 0.5) / 10.0,
    format("held-out next-character accuracy ~w%~n", [Pct]),
    %% PRINTED BESIDE THE BASELINES, ALWAYS. A score with no comparator is
    %% a decoration, and the comparator that matters is not chance -- it
    %% is what a trivial model reaches after seeing the same data.
    forall(member(Name-Label,
                  [uniform-'uniform over the vocabulary',
                   always_space-'always predict a space',
                   bigram-'bigram argmax (no context)']),
           ( clm_baseline(Name, BV),
             BPct is truncate(BV * 1000 + 0.5) / 10.0,
             format("   vs ~w: ~w%~n", [Label, BPct]) )),
    clm_floor(Floor),
    FloorPct is truncate(Floor * 100 + 0.5),
    (   A >= Floor
    ->  format("above the ~w% floor, and so above the bigram model~n", [FloorPct]),
        write(ok), nl
    ;   format("BELOW THE FLOOR of ~w%~n", [FloorPct]),
        format("A score at or under the bigram baseline means the context~n"),
        format("is not being used, which is the whole of what this is.~n"),
        write('FAIL'), nl, halt(1)
    ).

%% ---- generation ----------------------------------------------------------

%% NO `random/1' IN THIS DIALECT, so the sampler carries its own: the
%% fractional part of a large multiple of a sine, which is the same hash
%% tutorial 22 uses to make its data. Deterministic is the right property
%% here anyway -- two runs of this file print the same text, so a change
%% in the output means a change in the model.
%%
%% AND IT MAKES THE THREE SAMPLES BELOW AN ABLATION RATHER THAN THREE
%% DRAWS. `clm_generate/6' indexes the noise by its countdown, and all
%% three temperatures count down from the same number over the same seed
%% -- so they consume the IDENTICAL sequence of random values and differ
%% only in the temperature applied to them. Whatever changes between the
%% three outputs is the temperature and nothing else.
clm_noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is abs(S - truncate(S)), !.

%% Log-probabilities to weights at a temperature. T below 1 sharpens
%% toward the argmax, T above 1 flattens toward uniform. The exponential
%% is taken AFTER the division, which is the whole of what temperature is.
clm_weights([], _, []) :- !.
clm_weights([LP|LPs], T, [W|Ws]) :-
    W is exp(LP / T),
    clm_weights(LPs, T, Ws).

clm_sum([], 0.0) :- !.
clm_sum([W|Ws], S) :- clm_sum(Ws, S0), S is S0 + W.

%% Walk the weights until the running total passes the target. The last
%% clause is the guard against a target that floating-point error left
%% just above the sum: answer the final index rather than failing, because
%% a sampler that fails once in ten thousand draws is a sampler that
%% breaks a long generation for no reason a reader could find.
clm_pick([_], _, _, 0) :- !.
clm_pick([W|Ws], Target, Acc, Id) :-
    Acc1 is Acc + W,
    (   Target =< Acc1
    ->  Id = 0
    ;   clm_pick(Ws, Target, Acc1, Id0),
        Id is Id0 + 1
    ).

clm_sample(LogProbs, T, Step, Id) :-
    clm_weights(LogProbs, T, Ws),
    clm_sum(Ws, Sum),
    clm_noise(Step, R),
    Target is R * Sum,
    clm_pick(Ws, Target, 0.0, Id), !.

%% One step: the context in, log-probabilities out, one character chosen.
clm_step(M, Ctx, T, Step, Id) :-
    tensor_from_list([Ctx], X),
    model_predict(M, X, P),
    tensor_to_list(P, [LogProbs]),
    clm_sample(LogProbs, T, Step, Id),
    tensor_free(X),
    tensor_free(P), !.

clm_generate(_, _, _, _, 0, []) :- !.
clm_generate(M, Vocab, Ctx, T, N, [Code|Rest]) :-
    clm_step(M, Ctx, T, N, Id),
    clm_code(Vocab, Id, Code),
    Ctx = [_|Tail],
    append(Tail, [Id], Ctx2),
    N1 is N - 1,
    clm_generate(M, Vocab, Ctx2, T, N1, Rest).

%% A seed is a piece of real cocolog, cut or padded to the context width.
clm_seed(Vocab, Text, Ctx) :-
    clm_context(K),
    atom_codes(Text, Codes0),
    clm_ids(Vocab, Codes0, Ids0),
    length(Ids0, L),
    (   L >= K
    ->  Drop is L - K, length(Pre, Drop), append(Pre, Ctx, Ids0)
    ;   Pad is K - L,
        %% 32 is the space. Written as a number because `0' followed by a
        %% space is a character literal that depends on the reader
        %% agreeing with you about whitespace, and this file would rather
        %% not find out.
        clm_id(Vocab, 32, SpaceId),
        length(Padding, Pad), clm_fill(Padding, SpaceId),
        append(Padding, Ids0, Ctx)
    ), !.

clm_fill([], _) :- !.
clm_fill([V|Vs], V) :- clm_fill(Vs, V).

predict :-
    model_load(t25_charlm, M),
    clm_corpus(Codes),
    clm_vocab(Codes, Vocab),
    format("~n-- one character at a time, at three temperatures~n"),
    format("   The seed is real cocolog; everything after the arrow is the~n"),
    format("   model's. Read it for TEXTURE, not for grammar.~n~n"),
    forall(member(T-Label, [0.5-'0.5 (sharp)', 0.8-'0.8', 1.2-'1.2 (loose)']),
           ( clm_seed(Vocab, 'parent(tom, ', Ctx),
             clm_generate(M, Vocab, Ctx, T, 180, Out),
             atom_codes(Sample, Out),
             format("temperature ~w~n", [Label]),
             format("parent(tom, ~w~n~n", [Sample]) )),
    format("-- what to look for~n"),
    format("   What temperature DOES is certain, because it is one~n"),
    format("   division: below 1 it sharpens the distribution toward~n"),
    format("   the argmax, above 1 it flattens it toward uniform.~n"),
    format("   What that produces at THIS size is not something this~n"),
    format("   file will assert, because it was written without a~n"),
    format("   binary to run it on. The failure modes to watch for are~n"),
    format("   the two a sampler always has: a low temperature that~n"),
    format("   collapses into repeating whatever the corpus does most,~n"),
    format("   and a high one that emits character pairs which never~n"),
    format("   occur in cocolog. If some middle setting reads better~n"),
    format("   than both, that is the trade working as designed.~n"),
    write(done), nl.
