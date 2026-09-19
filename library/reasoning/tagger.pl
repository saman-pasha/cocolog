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
%% AND THE LEXICON JUDGES WHAT IT LABELS. Shown 875 sentences of real
%% government prose, the tagger "read" a tenth of them -- `Boston, Mass.'
%% as mass(boston), a heading as business(small) -- because every sentence
%% it had ever seen had a reading, and the grammar's defaults are
%% positional. So a tagging is put to the lexicon before the assembler
%% sees it (tagger_sane/2, seven rules, each a clause), and one the lexicon
%% contradicts comes back X throughout, the twelfth tag, which the
%% assembler refuses. Three ways of teaching the network itself to refuse
%% were tried and each took a tenth of the hand-written sentences it should
%% read; the rules take none. What the lexicon knows is the known_*.txt
%% files beside the generator's -- every SemCor-counted noun, verb,
%% adjective and adverb, whatever its sense -- because the generator's
%% nouns are things to own and `Death put a period' walked past a judge that
%% had never heard of death. tagger_refused/4 measures the refusals over
%% prose.txt, WordNet's example sentences, which nothing here trains on.
%%
%% THE NETWORK. Two embeddings -- the word, 24 wide, and its SHAPE (the case
%% it was written in and, for a lower-case word, the ending it carries: -s,
%% -ly, -ing, -ed or none; a capitalised word is a name whatever it ends
%% in), 4 wide -- concatenated into 28; a GRU over the sentence in each
%% direction, 96 wide each, so a token's label sees what came before it and
%% what follows; a linear head from the two states to the eleven tags inside
%% the grammar. X, the twelfth, is never the network's to answer: it is the
%% lexicon's verdict on a tagging, below. Sequences are padded to the
%% longest in the batch and batched position-major, as tutorials/tensor/41
%% batches its sequences; a MASK holds a sequence's state still past its
%% end, so the backward pass starts at the real last word and not at
%% padding. The forward is a tensor_expr PROCEDURE, tg_forward//5, and
%% exec/1 frees every state and gate it made but the logits.
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
%%         Trains on normalise_corpus/2 and saves under Name -- the parameters
%%         through params_save/2, the vocabulary as '$tg_vocab'/3 rows of
%%         two hundred words. Options:
%%         pairs(N) the corpus, seeds 1..N (16384); steps(K) optimiser steps
%%         (400); batch(B) sequences a step (128); lr(R) Adam's rate (0.005);
%%         seed(S) the tensor seed (45); min_count(C) the times a word must
%%         be seen to have an embedding row of its own (2); hidden(H) the
%%         width of each GRU (96) -- a saved model carries its own, in the
%%         shapes of its parameters;
%%         verbose(true) prints the loss.
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
%%     tagger_ask(+Model, +Text, -Answers)
%%         Prose in, questions answered: tagger_normalise/4 and then
%%         reason_ask/2 over the controlled text, so `Well, does Dana
%%         really rent a flat in Bristol?' answers yes(fact) against the
%%         knowledge base. Fails as tagger_normalise/4 fails.
%%
%%     tagger_refused(+Model, +From, +N, -Rate)
%%         Over N real sentences of prose.txt from the From-th, the
%%         fraction tagger_normalise/4 refuses. The other half of
%%         correctness: a tagger that reads `Boston, Mass.' as a fact is
%%         wrong even when every tag of every sentence it should read is
%%         right.
%%
%%     tagger_sane(+Tokens, +Tags)
%%         The lexicon's judgement of a tagging: fails where the lexicon
%%         contradicts it, seven rules. Applied by tagger_tag/3 and
%%         tagger_tag_all/3, whose refused sentence comes back X throughout.
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
%%     tagger_vocabulary(+Pairs, +MinCount, -Vocab)   only the words seen MinCount times
%%     tagger_word_id(+Vocab, +Word, -Id)   1 for a word not in it
%%     tagger_size(+Vocab, -V)              the rows of the word embedding
%%     tagger_encode(+Vocab, +Tokens, -Ids, -Shapes)     a shape is the case, and a lower-case word's ending: 1 lower,
%%                                          2 upper, 3 comma, then +3 for -s, +6 for -ly, +9 for -ing, +12 for -ed
%%                                          on a lower-case word only; 0 is padding
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
%% library(reasoning/normalise): thirty-three shapes, eleven transforms, and a
%% lexicon no longer written by hand at all -- files beside the library,
%% 2500 census names and some seventeen thousand WordNet words ranked by
%% use, read as they are needed (library/reasoning/lexicon/SOURCES.md). A
%% tagger generalises to the words it never saw exactly as far as the
%% shapes it did.
%%
%% MEASURED, on a four-core box with no GPU, the defaults: 400 steps over
%% 16384 pairs train in about eighty seconds; over 300 pairs training never
%% saw (seeds past the corpus) 0.9997 of the tags and 0.997 of the
%% sentences are right; and of fifty-four hand-written sentences whose
%% names, nouns, adjectives and verbs are outside the lexicon -- questions
%% and shared subjects among them -- fifty-two or more give their terms, a
%% different one missed from one training to the next -- test/tagger.pl
%% holds both. And the other half: of 300 WordNet example sentences from
%% prose.txt, 0.93 to 0.94 came back refused where the network alone
%% refused 0.85, and of 757 sentences of real government prose 0.96 where
%% it was 0.87 -- with the hand-written sentences read exactly as before,
%% which is what the learned refusers could not do. With the judge reading
%% the known_*.txt files rather than the generator's concrete nouns alone
%% it is 0.95 to 0.96 of prose.txt, the same model going from 28 sentences
%% read to 11.
%% Over the WordNet lexicon the corpus is the
%% lever twice over: 8192 pairs read 0.96 of the unseen sentences whatever
%% the step count (the loss fell to 0.001 while the evaluation stood still,
%% which is memorising), 16384 read 0.987 and 32768 read 0.993 in 140
%% seconds. A corpus too large to memorise is what makes a tagger
%% generalise, and the steps and not the pairs are what a training costs.
%% The lesson is tutorials/library/45-tagger.pl.

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).

:- dynamic '$tg_vocab'/3.

%% ---- the shape of the network ---------------------------------------------

tg_hidden(96).
tg_word_dim(24).
tg_shape_dim(4).
tg_shapes(16).                     % padding, then case x ending, below

%% ---- the vocabulary ---------------------------------------------------------

tagger_vocabulary(Pairs, Vocab) :- tagger_vocabulary(Pairs, 1, Vocab).

%% tagger_vocabulary(+Pairs, +MinCount, -Vocab): the words seen at least
%% MinCount times, sorted. A word seen once cannot be learned and is `<unk>'
%% in all but name, and over a lexicon of thousands most words are seen
%% once -- so tagger_train/2 keeps those at two by default, which bounds the
%% embedding and is exactly the dropout the rare words would have had.
tagger_vocabulary(Pairs, MinCount, Vocab) :-
    findall(W, ( member(pair(_, Toks, _, _, _), Pairs), member(T, Toks), tg_word(T, W) ), Ws0),
    msort(Ws0, Sorted),
    tg_counted(Sorted, MinCount, Words),
    tg_vocab(Words, Vocab).

tg_counted([], _, []).
tg_counted([W|Ws], Min, Out) :-
    tg_run(W, Ws, 1, N, Rest),
    ( N >= Min -> Out = [W|Out1] ; Out = Out1 ),
    tg_counted(Rest, Min, Out1).
tg_run(W, [W|Ws], N0, N, Rest) :- !, N1 is N0 + 1, tg_run(W, Ws, N1, N, Rest).
tg_run(_, Ws, N, N, Ws).

tg_vocab(Words, vocab(Words, Assoc)) :-
    findall(W-Id, ( nth0(I, Words, W), Id is I + 2 ), Ps),
    list_to_assoc(Ps, Assoc).

tagger_word_id(vocab(_, Assoc), W, Id) :- ( get_assoc(W, Assoc, Id0) -> Id = Id0 ; Id = 1 ).

tagger_size(vocab(Words, _), V) :- length(Words, N), V is N + 2.

%% the word a token carries, and its SHAPE: the case it was written in and,
%% for a lower-case word, the ending it carries -- none, -s, -ly, -ing or
%% -ed, so `flies' and `curses' look like verbs and `wholly' like an adverb
%% before any word is known. A capitalised word carries NO ending: it is a
%% name whatever it ends in. Measured before that was so: `Zed' and `Ted'
%% after `does not like' were dropped by three trainings in a row, because
%% their -ed made them a shape that twenty-three objects in sixteen thousand
%% pairs had worn, where `Bob' and `Mia' were kept every time. 0 is
%% padding; a comma is 3.
tg_word(word(W, _), W) :- !.
tg_word(T, T).
tg_shape(',', 3) :- !.
tg_shape(word(_, upper), 2) :- !.          % a name, whatever it ends in
tg_shape(word(W, lower), S) :- !,
    tg_ending(W, E),
    S is 1 + 3 * E.
tg_shape(_, 1).

tg_ending(W, 2) :- sub_atom(W, _, 2, 0, ly), !.
tg_ending(W, 3) :- sub_atom(W, _, 3, 0, ing), !.
tg_ending(W, 4) :- sub_atom(W, _, 2, 0, ed), !.
tg_ending(W, 1) :- sub_atom(W, _, 1, 0, s), !.
tg_ending(_, 0).

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
%% Made when a step needs it and freed after: the plans of a whole corpus
%% are lists and cost nothing, where the tensors of 128 batches at once ran
%% the module's handle table out (a handle came back 0, and the next step
%% died with `tensor expected, found 0').

tg_batch(Seqs, Gold, Batch) :- tagger_pad(Seqs, Plan), tg_batch_tensors(Plan, Gold, Batch).

tg_batch_tensors(plan(_, _, IdRows, ShapeRows, MaskRows, Flat), Gold, batch(Ins, Shs, Mks, Flat, Y)) :-
    findall(T, ( member(R, IdRows), T := R ), Ins),
    findall(T, ( member(R, ShapeRows), T := R ), Shs),
    findall(T, ( member(R, MaskRows), T := R ), Mks),
    (   Gold == yes
    ->  tg_inside_tags(K), one_hot(Flat, K, Y)
    ;   Y = none
    ).

tg_batch_free(batch(Ins, Shs, Mks, _, Y)) :-
    free_all(Ins), free_all(Shs), free_all(Mks),
    ( Y == none -> true ; tensor_free(Y) ).

%% ---- the parameters ---------------------------------------------------------------

tg_parameters(V, Ps) :- tg_hidden(H), tg_parameters(V, H, Ps).
tg_parameters(V, H, Ps) :-
    tg_word_dim(Dw), tg_shape_dim(Ds), tg_shapes(NS),
    In is Dw + Ds, H2 is 2 * H,
    tg_inside_tags(K),
    Ew := parameter(randn([V, Dw]) * 0.5),
    Es := parameter(randn([NS, Ds]) * 0.5),
    tg_gru_params(In, H, F), tg_gru_params(In, H, B),
    Wo := parameter(glorot(H2, K)), Bo := parameter(zeros([1, K])),
    append([[Ew, Es], F, B, [Wo, Bo]], Ps), !.

tg_gru_params(In, H, [Wz, Uz, Bz, Wr, Ur, Br, Wn, Un, Bn]) :-
    Wz := parameter(glorot(In, H)), Uz := parameter(glorot(H, H)), Bz := parameter(zeros([1, H])),
    Wr := parameter(glorot(In, H)), Ur := parameter(glorot(H, H)), Br := parameter(zeros([1, H])),
    Wn := parameter(glorot(In, H)), Un := parameter(glorot(H, H)), Bn := parameter(zeros([1, H])), !.

%% the head answers the eleven tags inside the grammar; X, outside, is
%% never predicted -- it is what a tagging the lexicon contradicts comes
%% back as, tagger_sane/2 below
tg_inside_tags(K) :- normalise_tags(Tags), length(Tags, K12), K is K12 - 1.

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
    { tg_unpack(Ps, Ew, Es, F, B, Wo, Bo), Ins = [In0|_],
      F = [_, Uz|_], tensor_shape(Uz, [Hd, _]) },              % the width is the model's own
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
    tg_option(pairs(NP), Options, 16384),
    tg_option(steps(K), Options, 400),
    tg_option(batch(B), Options, 128),
    tg_option(lr(LR), Options, 0.005),
    tg_option(seed(S), Options, 45),
    tg_option(min_count(MinCount), Options, 2),
    tg_option(hidden(H), Options, 96),
    ( memberchk(verbose(true), Options) -> Verbose = yes ; Verbose = no ),
    normalise_corpus(NP, Pairs),
    tagger_vocabulary(Pairs, MinCount, Vocab), Vocab = vocab(Words, _),
    tg_drop_table(Table),
    tg_training_sequences(Vocab, Table, Pairs, 1, PosSeqs),
    tg_by_length(PosSeqs, PosSorted), tg_chunks(PosSorted, B, PosGroups),
    findall(Plan, ( member(G, PosGroups), tagger_pad(G, Plan) ), Plans),
    seed(S),
    tagger_size(Vocab, V),
    tg_parameters(V, H, Ps0), adam_init(Ps0, St0),
    tg_fit(K, Ps0, St0, Plans, LR, Verbose, Ps),
    params_save(Name, Ps),
    tg_vocab_save(Name, Words),
    free_all(Ps).

%% the vocabulary in the store, 200 words a clause: a row must fit in a
%% page, and one clause holding thousands of words would not
tg_vocab_save(Name, Words) :-
    retractall('$tg_vocab'(Name, _, _)),
    tg_vocab_chunks(Words, Name, 0).
tg_vocab_chunks([], _, _) :- !.
tg_vocab_chunks(Words, Name, Seq) :-
    ( length(Chunk, 200), append(Chunk, Rest, Words) -> true ; Chunk = Words, Rest = [] ),
    assertz('$tg_vocab'(Name, Seq, Chunk)),
    Seq1 is Seq + 1, tg_vocab_chunks(Rest, Name, Seq1).
tg_vocab_load(Name, Words) :-
    findall(Seq-Chunk, '$tg_vocab'(Name, Seq, Chunk), Cs0), Cs0 \== [],
    msort(Cs0, Cs), findall(W, ( member(_-Chunk, Cs), member(W, Chunk) ), Words).

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
%% walked: a name at a quarter of its positions, a noun, an adjective or an
%% adverb at a fifth, a verb -- base or third person, the verb half of a
%% phrasal one -- at about a seventh. (Three in ten and a quarter were
%% tried over the WordNet lexicon and read fewer sentences, not more: what
%% a rare word's embedding still carries is worth keeping.) (Adverbs joined when `works hard' was
%% read as works_hard over the WordNet lexicon: an unknown word after a verb
%% at the end had never been seen, because no adverb had ever been dropped.) (Looked up per token instead, with the lexicon
%% scanned through downcase_atom/2 and the inflector each time, this cost
%% 25 ms a pair: 207 of the 235 seconds an 8192-pair training took.)
tg_drop_table(Table) :-
    findall(W-0.25, ( member(C, [proper, place]), normalise_lexicon(C, Ws), member(X, Ws), downcase_atom(X, W) ), Names),
    findall(W-0.20, ( member(C, [noun, class, adj, adverb]), normalise_lexicon(C, Ws), member(W, Ws) ), Nouns),
    findall(W-0.15, ( member(C, [vt, vi, vpp]), normalise_lexicon(C, Vs), member(V0, Vs),
                      ( V0 = V-_ -> true ; V = V0 ), ( W = V ; normalise_third(V, W) ) ), Verbs),
    append([Names, Nouns, Verbs], All),
    keysort(All, Sorted),
    tg_first_rates(Sorted, Pairs),
    list_to_assoc(Pairs, Table).

%% one entry a word, the first rate given winning: keysort is stable, so of
%% two rates for one word the earlier list's comes first
tg_first_rates([], []).
tg_first_rates([W-R|Ws], [W-R|Pairs]) :- tg_drop_same(W, Ws, Rest), tg_first_rates(Rest, Pairs).
tg_drop_same(W, [W-_|Ws], Rest) :- !, tg_drop_same(W, Ws, Rest).
tg_drop_same(_, Ws, Ws).

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
tg_fit(K, Ps, St, Plans, LR, Verbose, PsF) :-
    length(Plans, NB), B is K mod NB, nth0(B, Plans, Plan),
    tg_batch_tensors(Plan, yes, Batch), Batch = batch(Ins, Shs, Mks, _, Y),
    exec(tg_forward(Ps, Ins, Shs, Mks, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    (   Verbose == yes, K mod 40 =:= 0
    ->  Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv])
    ;   true
    ),
    adam_step(Ps, Gs, St, LR, Ps2, St2),
    free_all([Logits, L]), tg_batch_free(Batch),
    K1 is K - 1,
    tg_fit(K1, Ps2, St2, Plans, LR, Verbose, PsF).

%% ---- loading ------------------------------------------------------------------------------

tagger_load(Name, model(Ps, Vocab)) :-
    (   catch(tg_vocab_load(Name, Words), _, fail)
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
    tg_decode(Seqs, 0, N, Got, TagLists0),
    tg_judged(TokenLists, TagLists0, TagLists).

tg_decode([], _, _, _, []).
tg_decode([seq(Ids, _, _)|Ss], I, N, Got, [Tags|Ts]) :-
    length(Ids, L), L1 is L - 1,
    findall(Tag, ( between(0, L1, P), J is P * N + I, nth0(J, Got, G), Id is round(G), tagger_tag_id(Tag, Id) ), Tags),
    I1 is I + 1,
    tg_decode(Ss, I1, N, Got, Ts).

%% ---- the lexicon's judgement of a tagging -------------------------------------------------
%% A tagging the LEXICON contradicts is refused -- the sentence comes back
%% X throughout -- before the assembler sees it. These are the fragments the
%% grammar would read, because its defaults are positional: `Boston, Mass.'
%% tagged S D O is mass(boston), `Loan policies' is policies(loan), `This
%% should be played' is should_played(this). Six rules, each a clause:
%%
%%   * a sentence has a relation word, and no token is outside;
%%   * a relation word is a closed word of the grammar (is, may, will), or
%%     lower case and not the first token and not a word the lexicon knows
%%     only as a noun, an adjective or an adverb: `Mass', `policies';
%%   * a subject at the head of the sentence, capitalised only by its
%%     position, is not a common word of the lexicon unless it is a known
%%     first name: `Loan', `Small' -- and Rose or Bill, who are both;
%%   * a subject, an object or an adjective is not a closed word: `This',
%%     `It', `up';
%%   * an adjective is not a word the lexicon knows only as an adverb:
%%     `often' after `is';
%%   * and a sentence assembled to nothing -- every token dropped -- is
%%     refused, not read as nothing (tg_assemble_all/3).
%%
%% An unknown word passes every rule, so `Priya snores' and `Zed owns a
%% bicycle' read as before. (A second network trained to tell generated
%% sentences from real ones was tried instead and refused a sixth of the
%% hand-written sentences: it learned the two sources apart, not what the
%% grammar reads.)

tg_judged([], [], []).
tg_judged([Toks|TLs], [Tags|Tgs], [Out|Outs]) :-
    (   tagger_sane(Toks, Tags)
    ->  Out = Tags
    ;   length(Tags, L), findall('X', between(1, L, _), Out)
    ),
    tg_judged(TLs, Tgs, Outs).

tagger_sane(Toks, Tags) :-
    \+ memberchk('X', Tags),
    memberchk('R', Tags),
    tg_lexicon_classes(Lex),
    forall(( nth0(I, Toks, Tok), nth0(I, Tags, Tag) ), tg_sane_token(I, Tok, Tag, Lex)).

tg_sane_token(I, word(W, Case), 'R', Lex) :- !,
    (   rl_closed(W)
    ->  true
    ;   I > 0, Case == lower,
        \+ tg_only(W, Lex, [noun, class, adj, adverb]),
        ( rs_base(W, Base), Base \== W -> \+ tg_only(Base, Lex, [noun, class, adj, adverb]) ; true )
    ).
tg_sane_token(_, word(W, _), Tag, _) :-
    rl_question(W), !, memberchk(Tag, ['S', 'O']).                       % `who' a subject, `what' or `where' an object
tg_sane_token(_, word(W, _), 'S', _) :-
    rl_subject_pronoun(W), !.                                            % `she' may be a subject: the grammar resolves it
tg_sane_token(I, word(W, Case), Tag, Lex) :-
    memberchk(Tag, ['S', 'O', 'A', 'C']), !,
    \+ rl_closed(W),
    (   memberchk(Tag, ['S', 'O']), Case == lower, tg_only(W, Lex, [verb])                 % `Discuss values': no subject --
    ->  rs_base(W, B), B \== W, tg_classes(B, Lex, Cs), Cs \== [], \+ tg_only(B, Lex, [verb])   % unless `keys' is the noun `key'
    ;   true
    ),
    (   I =:= 0, Tag == 'S', Case == upper, tg_classes(W, Lex, Cs), Cs \== []
    ->  memberchk(name, Cs)
    ;   true
    ),
    (   memberchk(Tag, ['A', 'C'])
    ->  \+ tg_only(W, Lex, [adverb])
    ;   true
    ).
tg_sane_token(_, _, _, _).

tg_classes(W, Lex, Cs) :- ( get_assoc(W, Lex, Cs0) -> Cs = Cs0 ; Cs = [] ).
%% known, and known as nothing outside the classes given
tg_only(W, Lex, Only) :- tg_classes(W, Lex, Cs), Cs \== [], forall(member(C, Cs), memberchk(C, Only)).

%% the lexicon as one assoc, word -> its classes, made once a machine
tg_lexicon_classes(Lex) :-
    (   catch(nb_getval('$tg_lexicon_classes', Lex), _, fail)
    ->  true
    ;   findall(W-C, ( member(File-C, [noun-noun, class-class, adj-adj, adverb-adverb,
                                       known_noun-noun, known_adj-adj, known_adverb-adverb]),
                       normalise_lexicon(File, Ws), member(W, Ws) ), Cs1),
        findall(W-name, ( normalise_lexicon(proper, Ws), member(X, Ws), downcase_atom(X, W) ), Cs2),
        findall(W-verb, ( member(C, [vt, vi, vpp, known_verb]), normalise_lexicon(C, Vs), member(V0, Vs),
                          ( V0 = V-_ -> true ; V = V0 ), ( W = V ; normalise_third(V, W) ) ), Cs3),
        append([Cs1, Cs2, Cs3], All), keysort(All, Sorted),
        tg_group_classes(Sorted, Pairs), list_to_assoc(Pairs, Lex),
        nb_setval('$tg_lexicon_classes', Lex)
    ).
tg_group_classes([], []).
tg_group_classes([W-C|Rest], [W-[C|Cs]|Pairs]) :- tg_same_word(W, Rest, Cs, Others), tg_group_classes(Others, Pairs).
tg_same_word(W, [W-C|R], [C|Cs], O) :- !, tg_same_word(W, R, Cs, O).
tg_same_word(_, R, [], R).

%% ---- prose to predicates -----------------------------------------------------------------

%% prose in, its questions answered against the knowledge base
tagger_ask(Model, Text, Answers) :-
    tagger_normalise(Model, Text, Controlled, _),
    reason_ask(Controlled, Answers).

tagger_normalise(Model, Text, Controlled, Terms) :-
    reason_tokens(Text, Toks),
    tg_sentences(Toks, Sents),
    Sents \== [],
    tagger_tag_all(Model, Sents, TagLists),
    tg_assemble_all(Sents, TagLists, Texts),           % FAILS on a refused sentence
    atomic_list_concat(Texts, ' ', Controlled),
    reason_text(Controlled, Terms).

%% every sentence assembled, or the paragraph refused: a sentence the
%% tagger marks outside must not vanish into an empty reading (it did once,
%% and 319 sentences of government prose "read" as nothing at all)
tg_assemble_all([], [], []).
tg_assemble_all([S|Ss], [Tg|Tgs], [T|Texts]) :-
    normalise_assemble(S, Tg, T),
    T \== '',                                          % every token dropped is a refusal too
    tg_assemble_all(Ss, Tgs, Texts).

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

tagger_refused(Model, From, N, Rate) :-
    normalise_negatives(From, N, Pairs),
    tg_chunks(Pairs, 64, Groups),
    findall(x, ( member(G, Groups),
                 findall(Toks, member(pair(_, Toks, _, _, _), G), TLs),
                 tagger_tag_all(Model, TLs, Gots),
                 nth0(I, TLs, Toks), nth0(I, Gots, Got),
                 \+ ( normalise_assemble(Toks, Got, Asm), catch(reason_text(Asm, _), _, fail) ) ),
            Refused),
    length(Refused, NR), length(Pairs, NP),
    ( NP > 0 -> Rate is NR / NP ; Rate = 0.0 ).

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
