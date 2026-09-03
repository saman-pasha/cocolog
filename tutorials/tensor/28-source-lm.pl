%% cocolog tutorial 28 -- a character model trained on cocolog's OWN SOURCE.
%%
%% TIER 2: `use_module(library(torch))', from `sh modules/torch/build.sh',
%% and library(tensor_expr) over it.
%%
%%     S=/tmp/t28; cocolog --kb tutorials --embed $S run FILE corpus
%%     ...                                                  FILE train
%%     ...                                                  FILE test
%%     ...                                                  FILE generate
%%     ...                                                  FILE judge
%%     ...                                                  FILE predict
%%
%% IT NEEDS A STORE, and --local will waste your training run. params_save/2
%% writes the weights into the KNOWLEDGE BASE as clauses; under --local there
%% is nothing behind those clauses, so `train' reports success, the process
%% exits, and `generate' answers not_found. Every torch lesson here is run
%% with --embed for exactly this reason.
%%
%% AND A STORE ACCUMULATES THE PROGRAM, NOT JUST THE WEIGHTS. `run FILE goal'
%% CONSULTS the file, and under --embed every clause it reads is written
%% through into the knowledge base -- so a second run against the same store
%% appends a second copy of the whole tutorial, a third a third. That is
%% merely slow while the file is unchanged. Edit the file between runs and it
%% is a bug that looks like a model failure: consult appends, so the OLDEST
%% definition is the one that matches, and the fix you just made is never
%% reached. This file's sampler had a corrected cs_noise/2 sitting behind four
%% stale copies of the broken one for an afternoon, and the samples went on
%% being whitespace with the right code in the file. `listing(cs_noise/2)'
%% against the store says so in one line. Run against a FRESH directory after
%% an edit -- or run `main', which does everything in one process.
%%
%% THE QUESTION. Lessons 25 and 26 trained on English and tied at 51.1%. This
%% asks a different one: train a small transformer on the .pl files in this
%% repository -- the tutorials and the libraries, cocolog's own source -- and
%% look at what it generates.
%%
%% THE MODEL IS TUTORIAL 35'S DECODER, one size up: character and position
%% embeddings of 128, two blocks of four-head causal attention and a GELU
%% feed-forward of 256, a final layer norm and a head over the vocabulary,
%% every piece a tensor expression and the batch one [N*32, 128] matrix that
%% causal_mask/3 keeps honest -- a position sees itself and what came before
%% it, never after. So a window of 32 characters is 32 predictions, one per
%% position, and cross_entropy over all of them is the loss. The earlier
%% version of this file built the same shape with model_new/2 and predicted
%% only the character after the window; library lesson 22 still teaches
%% that API. The CORPUS IS ONE TENSOR, the id of every character in order,
%% and a batch is two gathers from it through index_rows -- the windows,
%% and the windows shifted by one, which are their targets.
%%
%% WHAT TO EXPECT, SAID BEFORE THE RESULT SO IT CANNOT BE DRESSED UP AFTER.
%% This is a CHARACTER model of about three hundred thousand parameters. It has no
%% notion of a predicate, a clause or a variable's scope; it predicts the next
%% BYTE from the previous few. On source code that is enough to learn the
%% shape of the language -- indentation, `:-', matching brackets over a short
%% span, common identifiers -- and nowhere near enough to write a program that
%% runs. A model that could do that is four or five orders of magnitude larger
%% than this one and is trained on far more than 700 KB.
%%
%% So the honest claim is: it learns the TEXTURE of cocolog, not the language.
%% The interesting part is exactly where that breaks -- which is why `generate'
%% prints raw samples rather than a cherry-picked line, and why the last
%% section feeds what it wrote to the actual reader and reports how much of it
%% is even a clause.

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% THE CLAUSE READER, to judge the model's output with. It is a tool under
%% tools/coco-agent rather than a library on the path, so it loads by plain
%% path -- see tutorials/library/37-lint.pl for what it is.
:- use_module('tools/coco-agent/clauses.pl').

%% ---- the corpus ------------------------------------------------------
%%
%% EVERY .pl THIS REPOSITORY OWNS, in a fixed order so a run is repeatable:
%% the ten libraries, then the basics lessons, then the library lessons. The
%% vendored SWI libraries under lib/swipl are LEFT OUT on purpose -- they are
%% another Prolog's code, and the question is what cocolog's own source looks
%% like.
cs_sources(Files) :-
    expand_file_name('library/*.pl', A0), sort(A0, A),
    expand_file_name('tutorials/basics/[0-9]*.pl', B0), sort(B0, B),
    expand_file_name('tutorials/library/[0-9]*.pl', C0), sort(C0, C),
    append(A, B, AB),
    append(AB, C, Files), !.

%% cs_text(-Codes, -Bytes) is det.
%% The whole corpus as one code list. A cut per file: read_file_to_codes/2 is
%% deterministic and the accumulator walk does not want its choice point.
cs_text(Codes, Bytes) :-
    cs_sources(Files),
    cs_read_all(Files, Codes),
    length(Codes, Bytes), !.

cs_read_all([], []).
cs_read_all([F|Fs], Out) :-
    read_file_to_codes(F, Cs),
    cs_read_all(Fs, Rest),
    append(Cs, Rest, Out), !.

%% ---- the vocabulary --------------------------------------------------
%%
%% ONE ID PER DISTINCT BYTE, and the model's output layer is that wide. Source
%% code uses more of the printable range than English does -- brackets, the
%% operator characters, the whole punctuation set -- so this is larger than
%% lesson 26's 77 and the uniform baseline it has to beat is correspondingly
%% higher.
cs_vocab(Codes, Vocab, V) :-
    sort(Codes, Vocab),
    length(Vocab, V), !.

cs_id(Vocab, Code, Id) :- nth0(Id, Vocab, Code), !.

cs_ids([], _, []) :- !.
cs_ids([C|Cs], Vocab, [I|Is]) :- cs_id(Vocab, C, I), cs_ids(Cs, Vocab, Is), !.

%% ---- windows ---------------------------------------------------------
%%
%% K CHARACTERS IN, THE NEXT K OUT: a window at offset O is the characters
%% O .. O+K-1 and its targets are O+1 .. O+K, so every position predicts its
%% successor from what it can see. Windows start every cs_stride/1
%% characters; a window is only its OFFSET until a step gathers it, so the
%% corpus is never a list of windows -- which is what kept the first
%% whole-corpus run under control, below.
cs_context(32).
cs_stride(3).

%% cs_offsets(+Len, -Offsets): every window offset a stream of Len ids allows.
cs_offsets(Len, Offsets) :-
    cs_context(K), cs_stride(S), Last is Len - K - 1,
    findall(O, ( between(0, Last, O), O mod S =:= 0 ), Offsets), !.

%% cs_gather(+Offsets, -In, -Out): the K positions of every window in
%% Offsets, and the K after them, as flat lists -- the two index lists a
%% batch is gathered by.
cs_gather(Offsets, In, Out) :-
    cs_context(K), K1 is K - 1,
    findall(P, ( member(O, Offsets), between(0, K1, D), P is O + D ), In),
    findall(P, ( member(O, Offsets), between(1, K, D), P is O + D ), Out), !.

%% ---- the model -------------------------------------------------------
%%
%% D = 128, four heads of 32, the feed-forward 256 wide, two blocks -- the
%% GPT-2 arrangement of tutorial 35, one size up.
cs_dim(128).
cs_heads(4).
cs_ffn(256).
cs_blocks(2).

cs_batch(32).           %% windows per step
cs_epochs(1).           %% passes over the training windows
cs_lr(0.002).
cs_cap(60000).

%% cs_parameters(+V, -Ps): the embeddings, the blocks, the final norm and the head, one flat list.
cs_parameters(V, Ps) :-
    cs_dim(D), cs_context(K), cs_blocks(NB),
    Emb := parameter(randn([V, D]) * 0.3), Pos := parameter(randn([K, D]) * 0.3),
    cs_block_params(NB, Blocks),
    G := parameter(ones([1, D])), Bt := parameter(zeros([1, D])),
    Wout := parameter(glorot(D, V)), Bout := parameter(zeros([1, V])),
    append(Blocks, Flat),
    append([[Emb, Pos], Flat, [G, Bt, Wout, Bout]], Ps), !.
cs_block_params(0, []) :- !.
cs_block_params(N, [[G1, Bt1, Wq, Wk, Wv, Wo, G2, Bt2, W1, B1, W2, B2]|Bs]) :-
    cs_dim(D), cs_ffn(F),
    G1 := parameter(ones([1, D])), Bt1 := parameter(zeros([1, D])),
    Wq := parameter(glorot(D, D)), Wk := parameter(glorot(D, D)), Wv := parameter(glorot(D, D)), Wo := parameter(glorot(D, D)),
    G2 := parameter(ones([1, D])), Bt2 := parameter(zeros([1, D])),
    W1 := parameter(glorot(D, F)), B1 := parameter(zeros([1, F])),
    W2 := parameter(glorot(F, D)), B2 := parameter(zeros([1, D])),
    N1 is N - 1, cs_block_params(N1, Bs), !.

%% cs_unpack(+Ps, -Emb, -Pos, -Blocks, -G, -Bt, -Wout, -Bout): the flat list
%% back into its parts -- the twelve parameters of each block as one list.
cs_unpack(Ps, Emb, Pos, Blocks, G, Bt, Wout, Bout) :-
    cs_blocks(NB), Total is NB * 12, length(Flat, Total),
    append([[Emb, Pos], Flat, [G, Bt, Wout, Bout]], Ps),
    cs_unflat(Flat, Blocks), !.
cs_unflat([], []) :- !.
cs_unflat(Flat, [B|Bs]) :- length(B, 12), append(B, Rest, Flat), cs_unflat(Rest, Bs), !.

%% head//6, block//4 and forward//5 are PROCEDURES: DCG rules of bindings,
%% and exec(forward(...)) frees everything they made but the logits.
head(Q, K, V, Mask, H, O) -->
    { cs_dim(D), cs_heads(Hn), Dh is D // Hn, F is H * Dh, T is F + Dh, Scale is 1.0 / sqrt(Dh) },
    O = softmax(cols(Q, F, T) matmul transpose(cols(K, F, T)) * Scale + Mask) matmul cols(V, F, T).
heads(Hn, Hn, _, _, _, _, []) --> !.
heads(H, Hn, Q, K, V, Mask, [O|Os]) -->
    head(Q, K, V, Mask, H, O), { H1 is H + 1 }, heads(H1, Hn, Q, K, V, Mask, Os).

blocks([], _, X, X) --> [].
blocks([[G1, Bt1, Wq, Wk, Wv, Wo, G2, Bt2, W1, B1, W2, B2]|Bs], Mask, X, Out) -->
    { cs_heads(Hn) },
    Xn = layer_norm(X) * G1 + Bt1,                              % pre-norm
    Q = Xn matmul Wq, K = Xn matmul Wk, V = Xn matmul Wv,
    heads(0, Hn, Q, K, V, Mask, Os),
    H = X + cat(Os, 1) matmul Wo,                               % attention, and its residual
    X2 = layer_norm(H) * G2 + Bt2,
    Ff = H + gelu(X2 matmul W1 + B1) matmul W2 + B2,            % feed-forward, and its residual
    blocks(Bs, Mask, Ff, Out).

%% forward(+Ps, +Ids, +PosIds, +Mask, -Logits): logits at every position, [N*K, V].
forward(Ps, Ids, PosIds, Mask, Logits) -->
    { cs_unpack(Ps, Emb, Pos, Blocks, G, Bt, Wout, Bout) },
    E = index_rows(Emb, Ids) + index_rows(Pos, PosIds),
    blocks(Blocks, Mask, E, H),
    Xf = layer_norm(H) * G + Bt,
    Logits = Xf matmul Wout + Bout.

%% constants(+N, -Ctx): what a batch of N windows reads -- the position of
%% every row, the causal mask, and the rows where each window ends.
constants(N, c(N, PosIds, Mask, Lasts)) -->
    { cs_context(K), K1 is K - 1,
      findall(P, ( between(1, N, _), between(0, K1, P) ), PosList),
      findall(L, ( between(1, N, I), L is I * K - 1 ), LastList) },
    PosIds = PosList, Lasts = LastList,
    causal_mask(N, K, Mask), !.

%% ---- the corpus as a stream, and its batches -------------------------
%%
%% cs_stream(-Vocab, -V, -Stream, -Len): the first cs_cap/1 bytes of the
%% corpus as one index tensor of character ids -- a rule, so the tensor is
%% the caller's to keep or to let exec/1 free.
cs_stream(Vocab, V, Stream, Len) -->
    { cs_text(Codes0, _), cs_cap(Cap), cs_take(Cap, Codes0, Codes),
      cs_vocab(Codes, Vocab, V), cs_ids(Codes, Vocab, Ids), length(Ids, Len) },
    Stream = Ids.

cs_take(0, _, []) :- !.
cs_take(_, [], []) :- !.
cs_take(N, [C|T], [C|R]) :- N1 is N - 1, cs_take(N1, T, R), !.

cs_split(N, NTrain) :- NTrain is (N * 9) // 10, !.

%% THE HELD-OUT SPLIT IS POSITIONAL, and it looks like an oversight. A
%% shuffled split is what a table of independent rows wants; these rows are
%% windows striding by three over a context of thirty-two, so two neighbours
%% share twenty-nine characters. Shuffle them and nearly every held-out
%% window has its own text in the training set: the accuracy goes up and
%% stops measuring anything. The last tenth of the windows is the only tenth
%% whose TEXT the model has not seen. The TRAINING windows are shuffled --
%% by the hash, so a run repeats -- and cut into batches of cs_batch/1.
cs_windows(Len, Train, Held, N, NTrain) :-
    cs_offsets(Len, Offsets), length(Offsets, N), cs_split(N, NTrain),
    length(Train, NTrain), append(Train, Held, Offsets), !.

cs_shuffle(Offsets, Shuffled) :-
    findall(R-O, ( member(O, Offsets), cs_noise(O, R) ), Keyed), msort(Keyed, Sorted),
    findall(O, member(_-O, Sorted), Shuffled), !.

%% cs_batches(+Offsets, -Batches): consecutive groups of cs_batch/1 offsets;
%% what does not fill a batch is left out.
cs_batches(Offsets, Batches) :- cs_batch(B), cs_groups(Offsets, B, Batches), !.
cs_groups(Offsets, B, [G|Gs]) :- length(G, B), append(G, Rest, Offsets), !, cs_groups(Rest, B, Gs).
cs_groups(_, _, []).

%% ---- what it learns from ---------------------------------------------

corpus :-
    cs_sources(Files), length(Files, NF),
    cs_text(Codes, Bytes),
    cs_vocab(Codes, _, V),
    cs_cap(Cap),
    Used is min(Bytes, Cap),
    format("~w files, ~w bytes, ~w distinct characters~n", [NF, Bytes, V]),
    format("training on the first ~w~n", [Used]),
    Uniform is log(V),
    UniAcc is 1.0 / V,
    format("uniform baseline: nll ~4f, accuracy ~4f~n", [Uniform, UniAcc]),
    write(done), nl, !.

%% ---- training --------------------------------------------------------
%%
%% THE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls: the stream, the constants and the parameters a goal loads are
%% made inside it and freed when it ends. The fit loop and the sampler are
%% predicates in braces: one steps an optimiser that frees the old
%% parameters itself, the other frees each step's logits as it goes.
train :- exec(train).
test :- exec(test).
generate :- exec(generate).
judge :- exec(judge).
predict :- exec(predict).

train -->
    seed(28),
    cs_stream(_, V, Stream, Len),
    { cs_windows(Len, Train0, _, N, NTrain), Held is N - NTrain,
      cs_shuffle(Train0, Train), cs_batches(Train, Batches), length(Batches, NB),
      cs_batch(B), cs_epochs(E), cs_lr(LR), Steps is E * NB,
      format("~w windows over a ~w-character vocabulary~n", [N, V]),
      format("training on ~w, holding out ~w~n", [NTrain, Held]),
      format("~w steps of ~w windows, ~w pass(es) over the training windows~n", [Steps, B, E]) },
    constants(B, Ctx),
    Eye = eye(V),
    { cs_parameters(V, Ps0), cs_count(Ps0, NP), format("~w parameters~n", [NP]),
      train_fit(Steps, Ps0, Stream, Eye, Ctx, Batches, LR, L),
      Uniform is log(V),
      format("final loss ~4f  (uniform is ~4f)~n", [L, Uniform]),
      write(done), nl }.

cs_count(Ps, N) :- findall(S, ( member(P, Ps), tensor_shape(P, Sh), cs_product(Sh, S) ), Ss), sum_list(Ss, N), !.
cs_product([], 1) :- !.
cs_product([D|Ds], P) :- cs_product(Ds, P0), P is P0 * D, !.

%% train_fit(+Steps, +Ps0, +Stream, +Eye, +Ctx, +Batches, +LR, -Loss): the
%% whole fit as a predicate -- Adam's state made, the steps taken, the
%% parameters saved under t28_cs and freed with the state; what comes out
%% is the last loss, a number.
train_fit(Steps, Ps0, Stream, Eye, Ctx, Batches, LR, Loss) :-
    adam_init(Ps0, St0),
    fit(Steps, Ps0, St0, Stream, Eye, Ctx, Batches, LR, none, Ps, St, Loss),
    params_save(t28_cs, Ps),
    free_all(Ps), adam_free(St), !.
adam_free(adam(_, Ms, Vs, _)) :- free_all(Ms), free_all(Vs), !.

%% fit(+K, +Ps, +St, +Stream, +Eye, +Ctx, +Batches, +LR, +L0, -PsF, -StF, -Loss):
%% K Adam steps, each over the next batch of window offsets; the loss of
%% the last step comes out.
fit(0, Ps, St, _, _, _, _, _, Loss, Ps, St, Loss) :- !.
fit(K, Ps, St, Stream, Eye, Ctx, Batches, LR, _, PsF, StF, Loss) :-
    length(Batches, NB), B is K mod NB, nth0(B, Batches, Offsets),
    fit_step(Ps, St, Stream, Eye, Ctx, Offsets, LR, Ps2, St2, Lv),
    ( K mod 100 =:= 0 -> format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    K1 is K - 1,
    fit(K1, Ps2, St2, Stream, Eye, Ctx, Batches, LR, Lv, PsF, StF, Loss).

%% fit_step(+Ps, +St, +Stream, +Eye, +Ctx, +Offsets, +LR, -Ps2, -St2, -Loss):
%% one step -- the windows and their targets gathered from the stream, the
%% targets one-hot through the identity, the loss over every position, the
%% gradient, and Adam; what the step made is freed here, and the old
%% parameters by adam_step/6.
fit_step(Ps, St, Stream, Eye, c(_, PosIds, Mask, _), Offsets, LR, Ps2, St2, Loss) :-
    cs_gather(Offsets, InL, OutL),
    In := InL, Out := OutL,
    Ids := index_rows(Stream, In), Tgt := index_rows(Stream, Out),
    exec(forward(Ps, Ids, PosIds, Mask, Logits)),
    L := cross_entropy(Logits, index_rows(Eye, Tgt)),
    Gs := grad(L, Ps),
    Loss := item(L),
    adam_step(Ps, Gs, St, LR, Ps2, St2),
    free_all([In, Out, Ids, Tgt, Logits, L]), !.

%% ---- held-out accuracy -----------------------------------------------
%%
%% Two numbers. Every position of a held-out window predicts its successor,
%% and the first is how often it is right -- the loss's own measure, over a
%% context of anything from one character to thirty-one. The second is the
%% last position only: a full window of context, which is what the earlier
%% version of this file measured and what the sampler runs on.
cs_floor(0.35).         %% what the all-positions accuracy must clear

test -->
    Ps = params(t28_cs),
    cs_stream(_, V, Stream, Len),
    { cs_windows(Len, _, Held, N, _), cs_batches(Held, Batches), length(Batches, NB), cs_batch(B), Seen is NB * B },
    constants(B, Ctx),
    { evaluate(Batches, Ps, Stream, Ctx, 0, 0, 0, 0, Hits, Total, LHits, LTotal),
      Acc is Hits / Total, LAcc is LHits / LTotal,
      Pct is truncate(Acc * 1000 + 0.5) / 10.0, LPct is truncate(LAcc * 1000 + 0.5) / 10.0,
      Uni is truncate(100000.0 / V + 0.5) / 1000.0,
      format("held-out next-character accuracy ~w% over every position of ~w windows~n", [Pct, Seen]),
      format("~w% at the last position, a full ~w-character context~n", [LPct, 32]),
      format("uniform would be ~w%~n", [Uni]),
      cs_floor(F), FPct is truncate(F * 100 + 0.5),
      (   Acc >= F
      ->  write(ok), nl
      ;   format("BELOW ~w%~n", [FPct]), write('FAIL'), nl, halt(1) ) }.

%% evaluate(+Batches, +Ps, +Stream, +Ctx, +H0, +T0, +LH0, +LT0, -H, -T, -LH, -LT):
%% hits and totals over every position, and over the last positions.
evaluate([], _, _, _, H, T, LH, LT, H, T, LH, LT) :- !.
evaluate([Offsets|Bs], Ps, Stream, Ctx, H0, T0, LH0, LT0, H, T, LH, LT) :-
    Ctx = c(_, PosIds, Mask, Lasts),
    cs_gather(Offsets, InL, OutL),
    In := InL, Out := OutL,
    Ids := index_rows(Stream, In), Tgt := index_rows(Stream, Out),
    exec(forward(Ps, Ids, PosIds, Mask, Logits)),
    TgtL := list(Tgt), accuracy(Logits, TgtL, A), length(TgtL, NT),
    LastLogits := index_rows(Logits, Lasts), LastL := list(index_rows(Tgt, Lasts)),
    accuracy(LastLogits, LastL, LA), length(LastL, NL),
    free_all([In, Out, Ids, Tgt, Logits, LastLogits]),
    H1 is H0 + round(A * NT), T1 is T0 + NT, LH1 is LH0 + round(LA * NL), LT1 is LT0 + NL,
    evaluate(Bs, Ps, Stream, Ctx, H1, T1, LH1, LT1, H, T, LH, LT).

%% ---- heavy: the whole dialect, round robin, and the lists freed ------
%%
%% THE SAME MODEL ON MORE OF THE SAME DIALECT. `train' learns from the
%% libraries and the two prose tutorial sets; this adds the two that were
%% never in cs_sources/1 -- the torch lessons, and cocolint, which is
%% tools/coco-agent's clauses.pl, lint.pl, blocklist.pl and the rest, a
%% quarter of a megabyte of cocolog written to READ cocolog. Five groups and
%% about a megabyte, which is a workload for a GPU rather than one of the
%% goals the runner drives.
%%
%% THE CAP TAKES ROUND ROBIN, NOT A PREFIX, and that is a correction rather
%% than a refinement. Appending a group to the end of a concatenation and
%% training on the first Cap bytes puts that group in the corpus only when
%% the cap REACHES it -- and library/*.pl and the basics are 286 KB, so a run
%% capped at 300 000 stopped fourteen kilobytes into the library tutorials
%% and read not one byte of the linter it was named for. Its numbers were
%% real and they were about a different corpus. So the groups are interleaved
%% a file at a time and the cap is filled from THAT order: every group is in
%% every cap, the file that crosses the line is the only one cut, and the
%% files past it are never read.
%%
%% THE TRANSIENT LISTS ARE FREED. A megabyte of codes becomes as many ids,
%% and every one of those is a Prolog list this engine reclaims only by
%% backtracking. So each file is read inside free_list/2, whose double
%% negation gives the heap back on the way out, and what has to survive --
%% one tensor handle and a length per file -- leaves through an assert. The
%% tensors are process state and outlive the scope; the lists do not. And
%% there is no list of windows at all, on any path: a window is an offset
%% into its file's stream until the step that gathers it.
%%
%%   ./cocolog run tutorials/tensor/28-source-lm.pl "heavy(60000)"
%%   ./cocolog run tutorials/tensor/28-source-lm.pl "tensor_execution(torch, graph, cuda), heavy(all)"
%%   ./cocolog run tutorials/tensor/28-source-lm.pl "tensor_execution(tensorflow, graph, cuda), heavy(all)"

%% THE FIVE GROUPS, kept apart so the cap can take from all of them. What
%% stays out stays out for cs_sources/1's reason: lib/swipl is another
%% Prolog's code, and test/files/*.pl is written to read under swipl TOO,
%% which makes it the portable subset rather than this dialect.
cs_heavy_groups([A, B, C, D, E]) :-
    expand_file_name('library/*.pl', A0), sort(A0, A),
    expand_file_name('tutorials/basics/[0-9]*.pl', B0), sort(B0, B),
    expand_file_name('tutorials/library/[0-9]*.pl', C0), sort(C0, C),
    expand_file_name('tutorials/tensor/[0-9]*.pl', D0), sort(D0, D),
    expand_file_name('tools/coco-agent/*.pl', E0), sort(E0, E1),
    expand_file_name('tools/coco-agent/selftest/*.pl', E2), sort(E2, E3),
    append(E1, E3, E), !.

%% one file from each group in turn, until every group is spent
cs_roundrobin([], []) :- !.
cs_roundrobin(Groups, Files) :-
    cs_rr_heads(Groups, Heads, Tails),
    append(Heads, Rest, Files),
    cs_roundrobin(Tails, Rest), !.

cs_rr_heads([], [], []) :- !.
cs_rr_heads([[]|Gs], Hs, Ts) :- !, cs_rr_heads(Gs, Hs, Ts).
cs_rr_heads([[H|T]|Gs], [H|Hs], [T|Ts]) :- cs_rr_heads(Gs, Hs, Ts), !.

cs_sources_heavy(Files) :-
    cs_heavy_groups(Gs),
    cs_roundrobin(Gs, Files), !.

%% size_file/2 answers without reading, so the whole corpus can be measured
%% and the reach of a cap counted before a byte goes on the heap.
cs_heavy_bytes(Bytes) :-
    cs_sources_heavy(Files),
    cs_bytes(Files, Bytes), !.

cs_bytes([], 0) :- !.
cs_bytes([F|Fs], N) :- size_file(F, S), cs_bytes(Fs, R), N is S + R, !.

%% THE CORPUS IS LOADED ONE FILE AT A TIME, and here is why. The first
%% whole-corpus run built a megabyte of codes, as many ids and three hundred
%% thousand windows as ONE set of lists inside ONE free_list scope, and the
%% container killed it at 11 GB resident: a scope reclaims on the way out, and
%% nothing about a scope lowers its peak. So the peak is made small instead.
%% Pass one reads each file inside its own scope and asserts the distinct
%% codes it saw -- at most a few hundred facts -- and the vocabulary is their
%% sorted union, the same for every file. Pass two reads each file again
%% inside its own scope, makes its ids and ONE TENSOR of them, and asserts
%% the handle and the length; on the way out that file's lists are gone. A
%% batch is then thirty-two windows of one file, gathered from that file's
%% stream. What is lost: the windows that would have straddled a file
%% boundary, at most thirty-one per boundary out of thousands per file.
%% What is kept: the round-robin order, the cap that cuts exactly one file,
%% and the positional held-out split over the concatenation.
:- dynamic('$cs_code'/1).
:- dynamic('$cs_part'/3).

%% the files a cap reaches, each with the byte count to take from it
cs_plan(Cap, _, []) :- Cap =< 0, !.
cs_plan(_, [], []) :- !.
cs_plan(Cap, [F|Fs], [F-Take|Rest]) :-
    size_file(F, S),
    (   S >= Cap
    ->  Take = Cap, Rest = []
    ;   Take = S, Rem is Cap - S, cs_plan(Rem, Fs, Rest)
    ), !.

%% pass one: the distinct codes of one file, out through facts
cs_note_codes(F-Take) :-
    free_list([Cs]>>(read_file_to_codes(F, Cs0), cs_take(Take, Cs0, Cs)),
              [Cs]>>(sort(Cs, Ds), forall(member(C, Ds),
                                          ( '$cs_code'(C) -> true ; assertz('$cs_code'(C)) )))), !.

%% pass two: one file's ids as one tensor, out through a fact
cs_load_part(Seq, Vocab, F-Take) :-
    free_list([Cs]>>(read_file_to_codes(F, Cs0), cs_take(Take, Cs0, Cs)),
              [Cs]>>( cs_ids(Cs, Vocab, Ids), length(Ids, Len),
                      cs_context(K),
                      (   Len > K + 1
                      ->  Stream := Ids, assertz('$cs_part'(Seq, Stream, Len))
                      ;   true ))), !.

cs_load_parts(_, _, []) :- !.
cs_load_parts(Seq, Vocab, [P|Ps]) :-
    cs_load_part(Seq, Vocab, P),
    Seq1 is Seq + 1,
    cs_load_parts(Seq1, Vocab, Ps), !.

%% cs_heavy_load(+Cap, -Parts, -V): the capped corpus as one stream tensor
%% per file, in order, never more than one file's lists on the heap at a time
cs_heavy_load(Cap, Parts, V) :-
    cs_sources_heavy(Files),
    cs_plan(Cap, Files, Plan),
    retractall('$cs_code'(_)), retractall('$cs_part'(_, _, _)),
    forall(member(P, Plan), cs_note_codes(P)),
    findall(C, '$cs_code'(C), Cs0), sort(Cs0, Vocab), length(Vocab, V),
    cs_load_parts(0, Vocab, Plan),
    findall(S-Stream-Len, '$cs_part'(S, Stream, Len), Parts0), msort(Parts0, Parts1),
    findall(Stream-Len, member(_-Stream-Len, Parts1), Parts),
    retractall('$cs_part'(_, _, _)), !.

%% cs_heavy_windows(+Parts, -Train, -Held, -N, -NTrain): the windows of
%% every part, the last tenth of the concatenation held out, as batches of
%% b(Stream, Offsets) -- one file each. The training windows are shuffled
%% within their file, and the training batches among themselves.
cs_heavy_windows(Parts, TrainBatches, HeldBatches, N, NTrain) :-
    findall(Len, member(_-Len, Parts), Lens), sum_list(Lens, Total),
    Boundary is (Total * 9) // 10,
    cs_part_batches(Parts, 0, Boundary, Batches0, HeldBatches, 0, NTrain, 0, NHeld),
    N is NTrain + NHeld,
    findall(R-B, ( nth0(I, Batches0, B), cs_noise(I, R) ), Keyed), msort(Keyed, Sorted),
    findall(B, member(_-B, Sorted), TrainBatches), !.

cs_part_batches([], _, _, [], [], NT, NT, NH, NH) :- !.
cs_part_batches([Stream-Len|Ps], Start, Boundary, Train, Held, NT0, NT, NH0, NH) :-
    cs_context(K),
    cs_offsets(Len, Offsets),
    findall(O, ( member(O, Offsets), Start + O + K < Boundary ), TrainO), length(TrainO, T),
    findall(O, ( member(O, Offsets), Start + O + K >= Boundary ), HeldO), length(HeldO, H),
    cs_shuffle(TrainO, Shuffled), cs_batches(Shuffled, TG), findall(b(Stream, G), member(G, TG), TrainHere),
    cs_batches(HeldO, HG), findall(b(Stream, G), member(G, HG), HeldHere),
    Next is Start + Len, NT1 is NT0 + T, NH1 is NH0 + H,
    cs_part_batches(Ps, Next, Boundary, TrainRest, HeldRest, NT1, NT, NH1, NH),
    append(TrainHere, TrainRest, Train), append(HeldHere, HeldRest, Held), !.

%% heavy(+Cap) is det.   Cap is a byte count, or `all' for the whole corpus.
%%
%% A GPU WORKLOAD. When the run is on the CPU -- no device here, or none
%% asked for -- the cap is brought down to cs_cpu_cap/1 and the run says so:
%% the whole corpus is minutes on a T4 and hours on two CPUs, and a small run
%% proves the same path. The device is the third argument of the switch,
%% tensor_execution(Backend, Mode, cuda), set from outside before the goal.
cs_cpu_cap(20000).
heavy(all) :- !, cs_heavy_bytes(B), heavy(B).
heavy(Cap0) :-
    cs_cpu_cap(Small),
    tensor_execution(_, _, Dev),
    (   Dev == cpu, Cap0 > Small
    ->  format("heavy: on the cpu -- running heavy(~w) instead of heavy(~w); the full run wants a GPU~n", [Small, Cap0]),
        Cap = Small
    ;   Cap = Cap0 ),
    exec(heavy_run(Cap, Parts)),
    forall(member(Stream-_, Parts), tensor_free(Stream)), !.

%% heavy_run(+Cap, -Parts): the run as a rule; the file streams come out,
%% since the loader made them outside it and heavy/1 frees them after.
heavy_run(Cap, Parts) -->
    seed(28),
    { cs_sources_heavy(Files), length(Files, NF),
      cs_heavy_bytes(Bytes),
      Used is min(Bytes, Cap),
      cs_heavy_load(Cap, Parts, V), length(Parts, NR),
      cs_heavy_windows(Parts, Batches, HeldBatches, N, NTrain), Held is N - NTrain,
      length(Batches, NB), cs_batch(B), cs_epochs(E), cs_lr(LR), Steps is E * NB,
      format("heavy: ~w bytes of ~w, reaching ~w of ~w files, ~w windows over ~w characters, holding out ~w~n",
             [Used, Bytes, NR, NF, N, V, Held]) },
    constants(B, Ctx),
    Eye = eye(V),
    { cs_parameters(V, Ps0), cs_count(Ps0, NP),
      heavy_fit(Steps, Ps0, Eye, Ctx, Batches, LR, HeldBatches, L, A),
      Pct is truncate(A * 1000 + 0.5) / 10.0,
      Uniform is log(V),
      tensor_execution(Backend, Mode, D),
      format("heavy: ~w parameters on ~w under ~w ~w: final loss ~4f (uniform ~4f), held-out accuracy ~w%~n",
             [NP, D, Backend, Mode, L, Uniform, Pct]),
      write(done), nl }.

%% heavy_fit(+Steps, +Ps0, +Eye, +Ctx, +Batches, +LR, +Held, -Loss, -Acc): the
%% fit and the measure over b(Stream, Offsets) batches -- fit_step/10 and
%% evaluate/12 with the stream taken from the batch rather than passed in;
%% the parameters and Adam's state freed at the end.
heavy_fit(Steps, Ps0, Eye, Ctx, Batches, LR, Held, Loss, Acc) :-
    adam_init(Ps0, St0),
    heavy_steps(Steps, Ps0, St0, Eye, Ctx, Batches, LR, none, Ps, St, Loss),
    heavy_evaluate(Held, Ps, Ctx, 0, 0, Hits, Total), Acc is Hits / Total,
    free_all(Ps), adam_free(St), !.
heavy_steps(0, Ps, St, _, _, _, _, Loss, Ps, St, Loss) :- !.
heavy_steps(K, Ps, St, Eye, Ctx, Batches, LR, _, PsF, StF, Loss) :-
    length(Batches, NB), B is K mod NB, nth0(B, Batches, b(Stream, Offsets)),
    fit_step(Ps, St, Stream, Eye, Ctx, Offsets, LR, Ps2, St2, Lv),
    ( K mod 100 =:= 0 -> format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    K1 is K - 1,
    heavy_steps(K1, Ps2, St2, Eye, Ctx, Batches, LR, Lv, PsF, StF, Loss).
heavy_evaluate([], _, _, H, T, H, T) :- !.
heavy_evaluate([b(Stream, Offsets)|Bs], Ps, Ctx, H0, T0, H, T) :-
    evaluate([Offsets], Ps, Stream, Ctx, H0, T0, 0, 0, H1, T1, _, _),
    heavy_evaluate(Bs, Ps, Ctx, H1, T1, H, T).

%% ---- generation ------------------------------------------------------
%%
%% SAMPLED, NOT ARGMAXED. An argmax model writes one file for ever; the
%% temperature divides the log-probabilities before they are exponentiated, so
%% low T is timid and repetitive and high T is adventurous and wrong. Both
%% failure modes are worth seeing, which is why generate/0 shows three.
%%
%% cs_step(+Ps, +Ctx, +Context, +T, +Step, -Id): one character -- the window
%% through the network, the last position's distribution, one draw.
cs_step(Ps, c(_, PosIds, Mask, _), Context, T, Step, Id) :-
    cs_context(K), K1 is K - 1,
    Ids := Context,
    exec(forward(Ps, Ids, PosIds, Mask, Logits)),
    [LogProbs] := list(log_softmax(rows(Logits, K1, K))),
    free_all([Ids, Logits]),
    cs_sample(LogProbs, T, Step, Id), !.

cs_generate(_, _, _, _, _, 0, []) :- !.
cs_generate(Ps, Ctx, Vocab, Context, T, N, [Code|Rest]) :-
    cs_step(Ps, Ctx, Context, T, N, Id),
    nth0(Id, Vocab, Code),
    Context = [_|Tail],
    append(Tail, [Id], Context1),
    N1 is N - 1,
    cs_generate(Ps, Ctx, Vocab, Context1, T, N1, Rest), !.

%% THE WEIGHTS, exponentiated at temperature T. exp/1 of a log-probability
%% divided by T: at T=1 that is the model's own distribution, below it sharpens
%% and above it flattens.
cs_sample(LogProbs, T, Step, Id) :-
    cs_weights(LogProbs, T, Ws),
    cs_sum(Ws, Sum),
    cs_noise(Step, R),
    Target is R * Sum,
    cs_pick(Ws, Target, 0.0, Id), !.

cs_weights([], _, []) :- !.
cs_weights([L|Ls], T, [W|Ws]) :- W is exp(L / T), cs_weights(Ls, T, Ws), !.

cs_sum([], 0.0) :- !.
cs_sum([W|Ws], S) :- cs_sum(Ws, S0), S is S0 + W, !.

%% THERE IS NO random/1 IN THIS DIALECT -- an unknown arithmetic functor is
%% uncatchably fatal, not an error you can catch. This is the same sin-based
%% hash lesson 22 uses: deterministic, so a run repeats, and uncorrelated
%% enough across steps to sample with -- and to shuffle the windows with.
%% THE abs/1 IS NOT DECORATION. truncate/1 rounds TOWARD ZERO, so for a
%% negative S the fraction S - truncate(S) is NEGATIVE -- and a negative
%% target makes cs_pick/4 match its first clause immediately, returning id 0
%% every time. Id 0 is the lowest character code in the vocabulary, which here
%% is a newline: the model was fine and the sampler emitted whitespace for
%% half of all steps. Lesson 25 has the abs and this did not.
cs_noise(Step, R) :-
    S is sin(Step * 12.9898 + 78.233) * 43758.5453,
    R is abs(S - truncate(S)), !.

cs_pick([W|_], Target, Acc, 0) :- Acc + W >= Target, !.
cs_pick([W|Ws], Target, Acc, Id) :-
    Acc1 is Acc + W,
    cs_pick(Ws, Target, Acc1, Id0),
    Id is Id0 + 1, !.

generate -->
    Ps = params(t28_cs),
    { cs_text(Codes0, _), cs_cap(Cap), cs_take(Cap, Codes0, Codes), cs_vocab(Codes, Vocab, _),
      cs_seed_context(Vocab, Context) },
    constants(1, Ctx),
    { forall(member(T, [0.5, 0.8, 1.0]),
             ( format("~n---- temperature ~w ----~n", [T]),
               cs_generate(Ps, Ctx, Vocab, Context, T, 400, Out),
               format("~s~n", [Out]) )),
      write(done), nl }.

%% A REAL PROMPT FROM THE CORPUS, so the model starts somewhere it has seen
%% rather than from a context of one repeated character.
cs_seed_context(Vocab, Ctx) :-
    cs_context(K),
    atom_codes('main :-\n    format("~n-- ', Seed),
    cs_pad(Seed, K, Padded),
    cs_ids(Padded, Vocab, Ctx), !.

cs_pad(Codes, K, Out) :-
    length(Codes, N),
    (   N >= K
    ->  Skip is N - K, cs_drop(Skip, Codes, Out)
    ;   Pad is K - N, cs_spaces(Pad, Sp), append(Sp, Codes, Out)
    ), !.

cs_drop(0, L, L) :- !.
cs_drop(_, [], []) :- !.
cs_drop(N, [_|T], R) :- N1 is N - 1, cs_drop(N1, T, R), !.

cs_spaces(0, []) :- !.
cs_spaces(N, [32|R]) :- N1 is N - 1, cs_spaces(N1, R), !.

%% ---- what it wrote, put to the real reader ---------------------------
%%
%% THE ONLY HONEST MEASURE OF "does it write cocolog". Reading a sample and
%% saying it looks plausible is how everyone overstates a character model;
%% cocolog has an actual clause reader, so the sample can be put to it and the
%% answer counted. cc_split_clauses/2 finds every clause; cc_read_head/3 says
%% what each one's head is. A run of bytes that ends in a `.' the reader
%% accepts, with a head it can name, is as close to "a clause" as text gets
%% without being consulted.
%%
%% IT IS STILL NOT A PROGRAM. A clause that reads is not a clause that means
%% anything -- the reader has no opinion about whether the predicate exists,
%% whether the arity matches, or whether the body could ever prove. Expect the
%% count to be much better than the content.

judge -->
    Ps = params(t28_cs),
    { cs_text(Codes0, _), cs_cap(Cap), cs_take(Cap, Codes0, Codes), cs_vocab(Codes, Vocab, _),
      cs_seed_context(Vocab, Context) },
    constants(1, Ctx),
    { forall(member(T, [0.5, 0.8, 1.0]),
             ( cs_generate(Ps, Ctx, Vocab, Context, T, 1200, Out),
               cs_judge_one(T, Out) )),
      write(done), nl }.

cs_judge_one(T, Codes) :-
    cc_split_clauses(Codes, Spans),
    length(Spans, NSpans),
    cs_heads(Spans, Codes, Heads),
    length(Heads, NHeads),
    length(Codes, NB),
    format("~n-- temperature ~w: ~w bytes~n", [T, NB]),
    format("   ~w runs the reader accepted as a clause~n", [NSpans]),
    format("   ~w of them had a head it could name~n", [NHeads]),
    cs_show_heads(Heads, 6), !.

cs_heads([], _, []) :- !.
cs_heads([Span|Ss], Codes, Out) :-
    Span = at(Off, _, _, Len),
    cs_drop(Off, Codes, Tail),
    cs_take(Len, Tail, Slice),
    (   catch(cc_read_head(Slice, Span, cc_clause(_, head(N, A), _)), _, fail)
    ->  Out = [N/A|Rest]
    ;   Out = Rest
    ),
    cs_heads(Ss, Codes, Rest), !.

cs_show_heads([], _) :- !.
cs_show_heads(_, 0) :- !.
cs_show_heads([H|Hs], N) :-
    format("     ~q~n", [H]),
    N1 is N - 1,
    cs_show_heads(Hs, N1), !.

%% predict/0 IS THE SUITE'S THIRD GOAL, and it has to fit the budget like
%% the other tutorials'. It generates a short sample at one temperature and
%% puts it to the reader, which is the whole lesson in miniature; generate/0
%% and judge/0 above are the same thing at a length a human wants to read.
predict -->
    Ps = params(t28_cs),
    { cs_text(Codes0, _), cs_cap(Cap), cs_take(Cap, Codes0, Codes), cs_vocab(Codes, Vocab, _),
      cs_seed_context(Vocab, Context) },
    constants(1, Ctx),
    { cs_generate(Ps, Ctx, Vocab, Context, 0.8, 200, Out),
      format("~n~s~n", [Out]),
      cs_judge_one(0.8, Out),
      write(done), nl }.

main :- corpus, train, test, generate, judge.
