%% cocolog -- library(reasoning/tagger): the network that labels typed text for
%% library(reasoning/reason), trained on what library(reasoning/normalise) makes.
%%
%%     :- use_module(library(reasoning/tagger)).
%%
%% TIER 2, clauses only, over library(tensor_expr) and library(torch). It
%% LOADS where torch is absent -- the vocabulary, the encoding, the tag ids
%% and the padding plan are pure, and test/tagger.pl proves them on any box
%% -- and a goal that touches a tensor then throws torch's existence_error.
%%
%% WHAT IT IS. A TAGGER: one label a token, from the alphabet
%% library(reasoning/normalise) fixes, so that normalise_assemble/3 can
%% rebuild the sentence in the shapes library(reasoning/reason) reads and
%% the grammar can verify it. It never emits a word: a name it has never
%% seen is copied by the assembler, and a wrong label costs a refusal or a
%% wrong term the grammar still reads -- so tag accuracy is the correctness
%% number, and tagger_evaluate/4 answers it on sentences training never saw.
%%
%% THE NETWORK. Two embeddings -- the word, 24 wide, and its SHAPE (lower,
%% upper, a comma, padding), 4 wide -- concatenated into 28; a GRU over the
%% sentence in each direction, 48 wide each, so a token's label sees what
%% came before it and what follows; and a linear head from the two states
%% to the eleven tags. Sequences are padded to the longest in the batch and
%% batched position-major, as tutorials/tensor/41 batches its sequences; a
%% MASK holds a sequence's state still past its end, so the backward pass
%% starts at the real last word and not at padding. The forward is a
%% tensor_expr PROCEDURE, tg_forward//5, and exec/1 frees every state and
%% gate it made but the logits.
%%
%% AN UNSEEN WORD IS THE POINT. A word outside the vocabulary is `<unk>',
%% and a capitalised one keeps the shape `upper'. Training replaces an
%% open-class word by `<unk>' at some of its positions -- a name at a
%% quarter, a noun or an adjective at a fifth, a verb at a seventh,
%% deterministic in the pair and the position so a run reproduces -- and
%% the network learns the label of a word it does not know from where it
%% stands. Then `Zed owns a bicycle' tags as `Alice owns a car' does, and
%% the assembler writes Zed and bicycle. (Without the nouns in that set,
%% measured, `must pay the rent' lost its object: `rent' was tagged D, the
%% only label an unknown lower-case word had ever carried.)
%%
%% THE KNOWLEDGE BASE IS THE MODEL FILE. tagger_train/2 saves the parameters
%% through params_save/2 and the vocabulary as one fact, '$tg_vocab'/2, so a
%% process run over a store (--embed DIR, or a server) hands the model to
%% the next one, and a --local process keeps it for its own life. No file
%% format, and nothing exported.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     tagger_train(+Name, +Options)
%%         Trains on normalise_corpus/2 and saves under Name. Options:
%%         pairs(N) the corpus, seeds 1..N (8192); steps(K) optimiser steps
%%         (300); batch(B) sequences a step (128); lr(R) Adam's rate (0.005);
%%         seed(S) the tensor seed (45); verbose(true) prints the loss.
%%
%%     tagger_load(+Name, -Model)        the parameters back as parameters, and the vocabulary
%%     tagger_free(+Model)               frees them
%%
%%     tagger_tag(+Model, +Tokens, -Tags)
%%         One sentence's tokens, as reason_tokens/2 gives them without the
%%         stop, to one tag each.
%%     tagger_tag_all(+Model, +TokenLists, -TagLists)      many sentences, ONE batch
%%
%%     tagger_normalise(+Model, +Text, -Controlled, -Terms)
%%         Prose in: every sentence tagged, assembled with
%%         normalise_assemble/3, and the whole read by reason_text/2. FAILS
%%         when the grammar refuses what came out, and reason_refused/2 over
%%         Controlled then names the sentence.
%%
%%     tagger_evaluate(+Model, +From, +N, -Report)
%%         Over the pairs of seeds From..From+N-1 -- sentences a training
%%         over seeds 1..Pairs never saw when From is past Pairs.
%%         Report = report(TokenAccuracy, SentenceAccuracy, Accepted, N):
%%         the fraction of tags right, of sentences with every tag right,
%%         and of sentences whose assembled text parses to the clean text's
%%         terms.
%%
%%   pure, and proved without torch:
%%
%%     tagger_vocabulary(+Pairs, -Vocab)    every word of the pairs, sorted; `<pad>' 0, `<unk>' 1, the words from 2
%%     tagger_word_id(+Vocab, +Word, -Id)   1 for a word not in it
%%     tagger_size(+Vocab, -V)              the rows of the word embedding
%%     tagger_encode(+Vocab, +Tokens, -Ids, -Shapes)     shapes: 1 lower, 2 upper, 3 comma; 0 is padding
%%     tagger_tag_id(?Tag, ?Id)             normalise_tags/1's order, S 0 .. B 10
%%     tagger_pad(+Seqs, -Plan)             seq(Ids, Shapes, TagIds|none) each, to
%%                                          plan(N, M, IdRows, ShapeRows, MaskRows, Flat):
%%                                          M rows of N, position-major, padding 0, its
%%                                          mask 0.0 and its gold tag D
%%
%% THE CORPUS IS THE CAPABILITY. The first draft trained on 512 pairs from
%% a lexicon of ten names and twelve nouns, and read its own kind of
%% sentence at 0.99 -- and dropped the noun of `a small blue lamp', because
%% no object it had seen carried two adjectives, and dropped `in Lagos'
%% after `lives', because the only place it had seen after a verb was an
%% adjunct to be thrown away. Every such miss was a SHAPE the generator did
%% not make, never the network, and every one was fixed in
%% library(reasoning/normalise): fifty names, forty-eight nouns, twenty
%% shapes, ten transforms. A tagger generalises to the words it never saw
%% exactly as far as the shapes it did.
%%
%% MEASURED, on a four-core box with no GPU, the defaults: 300 steps over
%% 8192 pairs train in about thirty-five seconds; over 300 pairs training
%% never saw (seeds past the corpus) every tag is right; and forty-two
%% hand-written sentences whose names, nouns, adjectives and verbs are
%% outside the lexicon all give their terms -- test/tagger.pl holds both.
%% At 2048 pairs the same network read forty of the forty-two, losing
%% `lives in Lagos' and `waits at Oslo' to the adjunct reading, and at 4096
%% all of them: the corpus is the lever, and it is cheap, since the steps
%% and not the pairs are what a training costs. The lesson is
%% tutorials/library/45-tagger.pl.

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).

:- dynamic '$tg_vocab'/2.

%% ---- the shape of the network ---------------------------------------------

tg_hidden(48).
tg_word_dim(24).
tg_shape_dim(4).
tg_shapes(4).                      % padding, lower, upper, comma

%% ---- the vocabulary ---------------------------------------------------------

tagger_vocabulary(Pairs, Vocab) :-
    findall(W, ( member(pair(_, Toks, _, _, _), Pairs), member(T, Toks), tg_word(T, W) ), Ws0),
    sort(Ws0, Words),
    tg_vocab(Words, Vocab).

tg_vocab(Words, vocab(Words, Assoc)) :-
    findall(W-Id, ( nth0(I, Words, W), Id is I + 2 ), Ps),
    list_to_assoc(Ps, Assoc).

tagger_word_id(vocab(_, Assoc), W, Id) :- ( get_assoc(W, Assoc, Id0) -> Id = Id0 ; Id = 1 ).

tagger_size(vocab(Words, _), V) :- length(Words, N), V is N + 2.

%% the word a token carries, and its shape
tg_word(word(W, _), W) :- !.
tg_word(T, T).
tg_shape(word(_, lower), 1) :- !.
tg_shape(word(_, upper), 2) :- !.
tg_shape(',', 3) :- !.
tg_shape(_, 1).

tagger_encode(_, [], [], []).
tagger_encode(V, [T|Ts], [Id|Ids], [S|Ss]) :-
    tg_word(T, W), tagger_word_id(V, W, Id), tg_shape(T, S),
    tagger_encode(V, Ts, Ids, Ss).

tagger_tag_id(Tag, Id) :- normalise_tags(Tags), nth0(Id, Tags, Tag).

%% ---- the padding plan ---------------------------------------------------------
%% N sequences to M positions: at each position the N ids, the N shapes, the
%% N masks as one-element rows (1.0 inside a sequence, 0.0 past its end),
%% and the gold tags position-major with D where there is padding -- the
%% order cat(Ls, 0) puts the logits in.

tagger_pad(Seqs, plan(N, M, IdRows, ShapeRows, MaskRows, Flat)) :-
    length(Seqs, N),
    findall(L, ( member(seq(Ids, _, _), Seqs), length(Ids, L) ), Ls),
    tg_max(Ls, M), M1 is M - 1,
    tagger_tag_id('D', Pad),
    findall(Row, ( between(0, M1, P), findall(Id, ( member(seq(Ids, _, _), Seqs), tg_at(P, Ids, 0, Id) ), Row) ), IdRows),
    findall(Row, ( between(0, M1, P), findall(S, ( member(seq(_, Shs, _), Seqs), tg_at(P, Shs, 0, S) ), Row) ), ShapeRows),
    findall(Row, ( between(0, M1, P), findall([Mk], ( member(seq(Ids, _, _), Seqs), length(Ids, L), ( P < L -> Mk = 1.0 ; Mk = 0.0 ) ), Row) ), MaskRows),
    findall(T, ( between(0, M1, P), member(seq(_, _, Tags), Seqs), ( Tags == none -> T = Pad ; tg_at(P, Tags, Pad, T) ) ), Flat).

tg_at(P, List, Default, X) :- ( nth0(P, List, X0) -> X = X0 ; X = Default ).

tg_max([X], X) :- !.
tg_max([X|Xs], M) :- tg_max(Xs, M0), ( X > M0 -> M = X ; M = M0 ).

%% ---- a batch: the plan as tensors -------------------------------------------------

tg_batch(Seqs, Gold, batch(Ins, Shs, Mks, Flat, Y)) :-
    tagger_pad(Seqs, plan(_, _, IdRows, ShapeRows, MaskRows, Flat)),
    findall(T, ( member(R, IdRows), T := R ), Ins),
    findall(T, ( member(R, ShapeRows), T := R ), Shs),
    findall(T, ( member(R, MaskRows), T := R ), Mks),
    (   Gold == yes
    ->  normalise_tags(Tags), length(Tags, K), one_hot(Flat, K, Y)
    ;   Y = none
    ).

tg_batch_free(batch(Ins, Shs, Mks, _, Y)) :-
    free_all(Ins), free_all(Shs), free_all(Mks),
    ( Y == none -> true ; tensor_free(Y) ).

%% ---- the parameters ---------------------------------------------------------------

tg_parameters(V, Ps) :-
    tg_word_dim(Dw), tg_shape_dim(Ds), tg_shapes(NS), tg_hidden(H),
    In is Dw + Ds, H2 is 2 * H,
    normalise_tags(Tags), length(Tags, K),
    Ew := parameter(randn([V, Dw]) * 0.5),
    Es := parameter(randn([NS, Ds]) * 0.5),
    tg_gru_params(In, H, F), tg_gru_params(In, H, B),
    Wo := parameter(glorot(H2, K)), Bo := parameter(zeros([1, K])),
    append([[Ew, Es], F, B, [Wo, Bo]], Ps), !.

tg_gru_params(In, H, [Wz, Uz, Bz, Wr, Ur, Br, Wn, Un, Bn]) :-
    Wz := parameter(glorot(In, H)), Uz := parameter(glorot(H, H)), Bz := parameter(zeros([1, H])),
    Wr := parameter(glorot(In, H)), Ur := parameter(glorot(H, H)), Br := parameter(zeros([1, H])),
    Wn := parameter(glorot(In, H)), Un := parameter(glorot(H, H)), Bn := parameter(zeros([1, H])), !.

tg_unpack(Ps, Ew, Es, F, B, Wo, Bo) :-
    length(F, 9), length(B, 9), append([[Ew, Es], F, B, [Wo, Bo]], Ps), !.

%% ---- the forward, as procedures --------------------------------------------------------
%% tg_gru(+Cell, +X, +H, +Mask, -H2): one step over the batch's rows, and the
%% mask keeps the old state where a sequence has ended.

tg_gru([Wz, Uz, Bz, Wr, Ur, Br, Wn, Un, Bn], X, H, Mk, H2) -->
    Z = sigmoid(X matmul Wz + H matmul Uz + Bz),
    R = sigmoid(X matmul Wr + H matmul Ur + Br),
    C = tanh(X matmul Wn + (R * H) matmul Un + Bn),
    Hc = (1.0 - Z) * H + Z * C,
    H2 = Hc * Mk + H * (1.0 - Mk).

%% the embedded input at every position: the word's row beside the shape's
tg_embeds(_, _, [], [], []) --> [].
tg_embeds(Ew, Es, [In|Ins], [Sh|Shs], [X|Xs]) -->
    X = cat([index_rows(Ew, In), index_rows(Es, Sh)], 1),
    tg_embeds(Ew, Es, Ins, Shs, Xs).

%% one direction: every state kept, in the order the inputs came
tg_scan(_, [], [], _, []) --> [].
tg_scan(Cell, [X|Xs], [Mk|Mks], H, [H2|Hs]) -->
    tg_gru(Cell, X, H, Mk, H2),
    tg_scan(Cell, Xs, Mks, H2, Hs).

%% the head at every position, over the two states
tg_heads(_, _, [], [], []) --> [].
tg_heads(Wo, Bo, [Hf|Hfs], [Hb|Hbs], [L|Ls]) -->
    L = cat([Hf, Hb], 1) matmul Wo + Bo,
    tg_heads(Wo, Bo, Hfs, Hbs, Ls).

%% tg_forward(+Ps, +Ins, +Shapes, +Masks, -Logits): [M*N, 11], position-major
tg_forward(Ps, Ins, Shs, Mks, Logits) -->
    { tg_unpack(Ps, Ew, Es, F, B, Wo, Bo), Ins = [In0|_], tg_hidden(Hd) },
    [N] = shape(In0),
    H0 = zeros([N, Hd]),
    tg_embeds(Ew, Es, Ins, Shs, Xs),
    tg_scan(F, Xs, Mks, H0, Hfs),
    { reverse(Xs, Rxs), reverse(Mks, Rmks) },
    tg_scan(B, Rxs, Rmks, H0, Hbs0),
    { reverse(Hbs0, Hbs) },
    tg_heads(Wo, Bo, Hfs, Hbs, Ls),
    Logits = cat(Ls, 0).

%% ---- training -------------------------------------------------------------------------

tagger_train(Name, Options) :-
    tg_option(pairs(NP), Options, 8192),
    tg_option(steps(K), Options, 300),
    tg_option(batch(B), Options, 128),
    tg_option(lr(LR), Options, 0.005),
    tg_option(seed(S), Options, 45),
    ( memberchk(verbose(true), Options) -> Verbose = yes ; Verbose = no ),
    normalise_corpus(NP, Pairs),
    tagger_vocabulary(Pairs, Vocab), Vocab = vocab(Words, _),
    tg_drop_table(Table),
    tg_training_sequences(Vocab, Table, Pairs, 1, Seqs),
    tg_by_length(Seqs, Sorted),
    tg_chunks(Sorted, B, Groups),
    findall(Bt, ( member(G, Groups), tg_batch(G, yes, Bt) ), Batches),
    seed(S),
    tagger_size(Vocab, V),
    tg_parameters(V, Ps0), adam_init(Ps0, St0),
    tg_fit(K, Ps0, St0, Batches, LR, Verbose, Ps),
    forall(member(Bt, Batches), tg_batch_free(Bt)),
    params_save(Name, Ps),
    retractall('$tg_vocab'(Name, _)),
    assertz('$tg_vocab'(Name, Words)),
    free_all(Ps).

tg_option(Term, Options, Default) :-
    ( memberchk(Term, Options) -> true ; arg(1, Term, Default) ).

%% the pairs as sequences, with WORD DROPOUT: an open-class word is `<unk>'
%% at some of its positions -- decided by a hash of the pair's index and the
%% position, never by a random number, so a run reproduces -- and the
%% network learns the label of a word it does not know from where it
%% stands. The closed words, the fillers and the adverbs are never dropped:
%% those ARE the shape the rest is read by.
tg_training_sequences(_, _, [], _, []).
tg_training_sequences(Vocab, Table, [pair(_, Toks, Tags, _, _)|Ps], I, [seq(Ids, Shs, TagIds)|Ss]) :-
    tagger_encode(Vocab, Toks, Ids0, Shs),
    tg_dropout(Toks, Ids0, Table, I, 0, Ids),
    findall(T, ( member(Tag, Tags), tagger_tag_id(Tag, T) ), TagIds),
    I1 is I + 1,
    tg_training_sequences(Vocab, Table, Ps, I1, Ss).

tg_dropout([], [], _, _, _, []).
tg_dropout([T|Ts], [Id|Ids], Table, I, P, [Id2|Ids2]) :-
    (   tg_word(T, W), get_assoc(W, Table, Rate), tg_hash(I * 131 + P, R), R < Rate
    ->  Id2 = 1
    ;   Id2 = Id
    ),
    P1 is P + 1,
    tg_dropout(Ts, Ids, Table, I, P1, Ids2).

%% the rate a word is dropped at, as ONE table built before the pairs are
%% walked: a name at a quarter of its positions, a noun or an adjective at
%% a fifth, a verb -- base or third person, the verb half of a phrasal one
%% -- at about a seventh. (Looked up per token instead, with the lexicon
%% scanned through downcase_atom/2 and the inflector each time, this cost
%% 25 ms a pair: 207 of the 235 seconds an 8192-pair training took.)
tg_drop_table(Table) :-
    findall(W-0.25, ( member(C, [proper, place]), normalise_lexicon(C, Ws), member(X, Ws), downcase_atom(X, W) ), Names),
    findall(W-0.20, ( member(C, [noun, class, adj]), normalise_lexicon(C, Ws), member(W, Ws) ), Nouns),
    findall(W-0.15, ( member(C, [vt, vi]), normalise_lexicon(C, Vs), member(V, Vs), ( W = V ; normalise_third(V, W) ) ), Verbs),
    findall(W-0.15, ( normalise_lexicon(vpp, Vs), member(V-_, Vs), ( W = V ; normalise_third(V, W) ) ), Phrasal),
    append([Names, Nouns, Verbs, Phrasal], All),
    tg_first_rates(All, [], Pairs),
    list_to_assoc(Pairs, Table).

%% one entry a word, the first rate given winning
tg_first_rates([], Acc, Pairs) :- reverse(Acc, Pairs).
tg_first_rates([W-R|Ws], Acc, Pairs) :-
    ( memberchk(W-_, Acc) -> Acc1 = Acc ; Acc1 = [W-R|Acc] ),
    tg_first_rates(Ws, Acc1, Pairs).

tg_hash(I, R) :- S is sin(I * 78.233) * 43758.5453, R is abs(S - truncate(S)).

%% batches of NEIGHBOURS IN LENGTH: a batch is padded to its longest
%% sequence and every position costs a GRU step each way, so sixty-four
%% sentences drawn at random pay for the longest of them all -- measured,
%% sorting them first nearly halves a step
tg_by_length(Seqs, Sorted) :-
    findall(L-S, ( member(S, Seqs), S = seq(Ids, _, _), length(Ids, L) ), Keyed),
    keysort(Keyed, Ordered),
    findall(S, member(_-S, Ordered), Sorted).

tg_chunks([], _, []) :- !.
tg_chunks(Xs, B, [G|Gs]) :- length(G, B), append(G, Rest, Xs), !, tg_chunks(Rest, B, Gs).
tg_chunks(Xs, _, [Xs]).

%% the fit loop: the batches in turn, an Adam step each, the old parameters
%% and the gradients freed by the step itself
tg_fit(0, Ps, _, _, _, _, Ps) :- !.
tg_fit(K, Ps, St, Batches, LR, Verbose, PsF) :-
    length(Batches, NB), B is K mod NB, nth0(B, Batches, batch(Ins, Shs, Mks, _, Y)),
    exec(tg_forward(Ps, Ins, Shs, Mks, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    (   Verbose == yes, K mod 40 =:= 0
    ->  Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv])
    ;   true
    ),
    adam_step(Ps, Gs, St, LR, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    tg_fit(K1, Ps2, St2, Batches, LR, Verbose, PsF).

%% ---- loading ------------------------------------------------------------------------------

tagger_load(Name, model(Ps, Vocab)) :-
    (   catch('$tg_vocab'(Name, Words), _, fail)
    ->  true
    ;   throw(error(existence_error(tagger, Name), tagger_load/2))
    ),
    params_load(Name, Ps),
    tg_vocab(Words, Vocab).

tagger_free(model(Ps, _)) :- free_all(Ps).

%% ---- tagging ---------------------------------------------------------------------------------

tagger_tag(Model, Tokens, Tags) :- tagger_tag_all(Model, [Tokens], [Tags]).

tagger_tag_all(_, [], []) :- !.
tagger_tag_all(model(Ps, Vocab), TokenLists, TagLists) :-
    findall(seq(Ids, Shs, none), ( member(Toks, TokenLists), tagger_encode(Vocab, Toks, Ids, Shs) ), Seqs),
    tg_batch(Seqs, no, Batch), Batch = batch(Ins, Shs, Mks, _, _),
    exec(tg_forward(Ps, Ins, Shs, Mks, Logits)),
    Got := list(argmax(Logits, 1)),
    tensor_free(Logits), tg_batch_free(Batch),
    length(Seqs, N),
    tg_decode(Seqs, 0, N, Got, TagLists).

tg_decode([], _, _, _, []).
tg_decode([seq(Ids, _, _)|Ss], I, N, Got, [Tags|Ts]) :-
    length(Ids, L), L1 is L - 1,
    findall(Tag, ( between(0, L1, P), J is P * N + I, nth0(J, Got, G), Id is round(G), tagger_tag_id(Tag, Id) ), Tags),
    I1 is I + 1,
    tg_decode(Ss, I1, N, Got, Ts).

%% ---- prose to predicates -----------------------------------------------------------------

tagger_normalise(Model, Text, Controlled, Terms) :-
    reason_tokens(Text, Toks),
    tg_sentences(Toks, Sents),
    tagger_tag_all(Model, Sents, TagLists),
    findall(T, ( nth0(I, Sents, S), nth0(I, TagLists, Tg), normalise_assemble(S, Tg, T), T \== '' ), Texts),
    atomic_list_concat(Texts, ' ', Controlled),
    reason_text(Controlled, Terms).

%% the token list cut at every stop, empty sentences dropped
tg_sentences([], []) :- !.
tg_sentences(Toks, Sents) :-
    tg_upto_stop(Toks, S, Rest),
    ( S == [] -> Sents = Sents1 ; Sents = [S|Sents1] ),
    tg_sentences(Rest, Sents1).
tg_upto_stop([], [], []).
tg_upto_stop(['.'|Ts], [], Ts) :- !.
tg_upto_stop([T|Ts], [T|S], Rest) :- tg_upto_stop(Ts, S, Rest).

%% ---- evaluation ---------------------------------------------------------------------------

tagger_evaluate(Model, From, N, report(TokenAcc, SentenceAcc, Accepted, N)) :-
    To is From + N - 1,
    findall(p(Toks, Tags, Clean), ( between(From, To, I), normalise_pair(I, pair(_, Toks, Tags, Clean, _)) ), Ps),
    tg_chunks(Ps, 64, Groups),
    findall(r(Toks, Gold, Got, Clean),
            ( member(G, Groups),
              findall(Toks, member(p(Toks, _, _), G), TLs),
              tagger_tag_all(Model, TLs, Gots),
              nth0(I, G, p(Toks, Gold, Clean)), nth0(I, Gots, Got) ),
            Rs),
    findall(H-T, ( member(r(_, Gold, Got, _), Rs), tg_hits(Gold, Got, H), length(Gold, T) ), HTs),
    findall(H, member(H-_, HTs), Hs), sum_list(Hs, Hits),
    findall(T, member(_-T, HTs), Ts), sum_list(Ts, Tokens),
    ( Tokens > 0 -> TokenAcc is Hits / Tokens ; TokenAcc = 0.0 ),
    findall(x, ( member(r(_, Gold, Got, _), Rs), Gold == Got ), Right), length(Right, NR),
    findall(x, ( member(r(Toks, _, Got, Clean), Rs), tg_accepted(Toks, Got, Clean) ), Acc), length(Acc, NA),
    ( N > 0 -> SentenceAcc is NR / N, Accepted is NA / N ; SentenceAcc = 0.0, Accepted = 0.0 ).

tg_hits([], _, 0).
tg_hits([G|Gs], [T|Ts], H) :- !, tg_hits(Gs, Ts, H0), ( G == T -> H is H0 + 1 ; H = H0 ).
tg_hits([_|Gs], [], H) :- tg_hits(Gs, [], H).

%% the assembled sentence parses, to the clean text's terms up to variable names
tg_accepted(Toks, Got, Clean) :-
    normalise_assemble(Toks, Got, Asm),
    catch(reason_text(Asm, T2), _, fail),
    catch(reason_text(Clean, T1), _, fail),
    tg_variant(T1, T2).

tg_variant(A, B) :-
    copy_term(A, A1), copy_term(B, B1),
    term_variables(A1, Va), tg_number(Va, 0),
    term_variables(B1, Vb), tg_number(Vb, 0),
    A1 == B1.
tg_number([], _).
tg_number(['$v'(N)|Vs], N) :- N1 is N + 1, tg_number(Vs, N1).
