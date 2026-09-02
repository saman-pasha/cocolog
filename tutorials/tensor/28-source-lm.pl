%% cocolog tutorial 28 -- a character model trained on cocolog's OWN SOURCE.
%%
%% TIER 2: `use_module(library(torch))', from `sh modules/torch/build.sh'.
%%
%%     S=/tmp/t28; cocolog --kb tutorials --embed $S run FILE corpus
%%     ...                                                  FILE train
%%     ...                                                  FILE test
%%     ...                                                  FILE generate
%%     ...                                                  FILE judge
%%
%% IT NEEDS A STORE, and --local will waste your training run. model_save/2
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
%% asks a different one: train the same transformer on the .pl files in this
%% repository -- the tutorials and the libraries, cocolog's own source -- and
%% look at what it generates.
%%
%% WHAT TO EXPECT, SAID BEFORE THE RESULT SO IT CANNOT BE DRESSED UP AFTER.
%% This is a CHARACTER model of about a hundred thousand parameters. It has no
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
    append(AB, C, Files).

%% cs_text(-Codes, -Bytes) is det.
%% The whole corpus as one code list. A cut per file: read_file_to_codes/2 is
%% deterministic and the accumulator walk does not want its choice point.
cs_text(Codes, Bytes) :-
    cs_sources(Files),
    cs_read_all(Files, Codes),
    length(Codes, Bytes).

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
    length(Vocab, V).

cs_id(Vocab, Code, Id) :- nth0(Id, Vocab, Code), !.

cs_ids([], _, []).
cs_ids([C|Cs], Vocab, [I|Is]) :- cs_id(Vocab, C, I), cs_ids(Cs, Vocab, Is).

%% ---- windows ---------------------------------------------------------
%%
%% K CHARACTERS IN, THE NEXT ONE OUT, striding by cs_stride/1 rather than by
%% one. A stride of 1 over 400 KB is 400 000 windows and hours of CPU; a
%% stride of 3 is a third of that and loses nothing a character model can use,
%% because consecutive windows overlap in all but one position anyway.
cs_context(32).
cs_stride(3).

cs_windows(Ids, Xs, Ys, N) :-
    cs_context(K),
    cs_stride(S),
    cs_windows_(Ids, K, S, Xs, Ys),
    length(Xs, N).

cs_windows_(Ids, K, S, [X|Xs], [Y|Ys]) :-
    length(X, K),
    append(X, [Y|_], Ids),
    !,
    cs_drop(S, Ids, Rest),
    cs_windows_(Rest, K, S, Xs, Ys).
cs_windows_(_, _, _, [], []).

cs_drop(0, L, L) :- !.
cs_drop(_, [], []) :- !.
cs_drop(N, [_|T], R) :- N1 is N - 1, cs_drop(N1, T, R).

%% ---- the model -------------------------------------------------------
%%
%% THE SAME SHAPE AS LESSON 26, one width up. attention(4) is four heads over
%% a 128-wide embedding; positional is the learned position embedding the
%% attention needs to know order at all; ffn(256) is the pointwise half.
%% dense(V, log_softmax) makes the output a distribution over the vocabulary,
%% which is what the sampler in `generate' needs -- an argmax model can only
%% ever write the same file twice.
cs_spec(V, [sequence(K), embedding(V, 128), positional,
            attention(4), ffn(256),
            attention(4), ffn(256),
            dense(V, log_softmax)]) :-
    cs_context(K).

cs_epochs(4).
cs_batch(64).
cs_lr(0.0015).
cs_cap(60000).

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
    write(done), nl.

%% ---- training --------------------------------------------------------

cs_data(Vocab, V, X, Y, N) :-
    cs_text(Codes0, _),
    cs_cap(Cap),
    cs_take(Cap, Codes0, Codes),
    cs_vocab(Codes, Vocab, V),
    cs_ids(Codes, Vocab, Ids),
    cs_windows(Ids, Xs, Ys, N),
    tensor_from_list(Xs, X),
    tensor_from_list(Ys, Y).

cs_take(0, _, []) :- !.
cs_take(_, [], []) :- !.
cs_take(N, [C|T], [C|R]) :- N1 is N - 1, cs_take(N1, T, R).

cs_split(N, NTrain) :- NTrain is (N * 9) // 10.

train :-
    torch_seed(28),
    cs_data(_, V, X, Y, N),
    cs_split(N, NTrain), Held is N - NTrain,
    cs_spec(V, Spec),
    cs_epochs(E), cs_batch(B), cs_lr(LR),
    tensor_rows(X, 0, NTrain, XTr), tensor_rows(Y, 0, NTrain, YTr),
    format("~w windows over a ~w-character vocabulary~n", [N, V]),
    format("training on ~w, holding out ~w~n", [NTrain, Held]),
    model_new(Spec, M),
    model_params(M, P), length(P, NP),
    format("~w parameters~n", [NP]),
    model_train(M, XTr, YTr, [epochs(E), batch(B), lr(LR), optimiser(adam),
                              loss(nll), shuffle(true), final_loss(L)]),
    Uniform is log(V),
    format("final nll ~4f  (uniform is ~4f)~n", [L, Uniform]),
    model_save(t28_cs, M),
    write(done), nl.

%% ---- held-out accuracy -----------------------------------------------

test :-
    model_load(t28_cs, M),
    cs_data(_, V, X, Y, N),
    cs_split(N, NTrain),
    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),
    model_evaluate(M, XTe, YTe, accuracy, A),
    Pct is truncate(A * 1000 + 0.5) / 10.0,
    Uni is truncate(100000.0 / V + 0.5) / 1000.0,
    format("held-out accuracy ~w% over ~w windows~n", [Pct, N]),
    format("uniform would be ~w%~n", [Uni]),
    write(done), nl.

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
%% THE HELD-OUT SPLIT STAYS POSITIONAL, and it looks like an oversight. A
%% shuffled split is what a table of independent rows wants; these rows are
%% windows striding by three over a context of thirty-two, so two neighbours
%% share twenty-nine characters. Shuffle them and nearly every held-out
%% window has its own text in the training set: the accuracy goes up and
%% stops measuring anything. The last tenth of the stream is the only tenth
%% whose TEXT the model has not seen.
%%
%% THE TRANSIENT LISTS ARE FREED. A megabyte of codes becomes as many ids
%% becomes three hundred thousand windows of thirty-two, and every one of
%% those is a Prolog list this engine reclaims only by backtracking. So the
%% whole build runs inside free_list/2, whose double negation gives the heap
%% back on the way out, and what has to survive -- two tensor handles, the
%% count and the vocabulary size, four integers -- leaves through an assert.
%% The tensors are process state and outlive the scope; the lists do not.
%%
%%   ./cocolog run tutorials/tensor/28-source-lm.pl "heavy(60000)"
%%   ./cocolog run tutorials/tensor/28-source-lm.pl "torch_device(cuda), heavy(all)"
%%   ./cocolog run tutorials/tensor/28-source-lm.pl "torch_device(cuda), tensor_execution(torch, graph), heavy(all)"

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
    append(E1, E3, E).

%% one file from each group in turn, until every group is spent
cs_roundrobin([], []) :- !.
cs_roundrobin(Groups, Files) :-
    cs_rr_heads(Groups, Heads, Tails),
    append(Heads, Rest, Files),
    cs_roundrobin(Tails, Rest).

cs_rr_heads([], [], []).
cs_rr_heads([[]|Gs], Hs, Ts) :- !, cs_rr_heads(Gs, Hs, Ts).
cs_rr_heads([[H|T]|Gs], [H|Hs], [T|Ts]) :- cs_rr_heads(Gs, Hs, Ts).

cs_sources_heavy(Files) :-
    cs_heavy_groups(Gs),
    cs_roundrobin(Gs, Files).

%% size_file/2 answers without reading, so the whole corpus can be measured
%% and the reach of a cap counted before a byte goes on the heap.
cs_heavy_bytes(Bytes) :-
    cs_sources_heavy(Files),
    cs_bytes(Files, Bytes).

cs_bytes([], 0).
cs_bytes([F|Fs], N) :- size_file(F, S), cs_bytes(Fs, R), N is S + R.

cs_reach(_, [], 0) :- !.
cs_reach(Cap, _, 0) :- Cap =< 0, !.
cs_reach(Cap, [F|Fs], N) :-
    size_file(F, S),
    (   S >= Cap
    ->  N = 1
    ;   Rem is Cap - S, cs_reach(Rem, Fs, N0), N is N0 + 1
    ), !.

%% THE CORPUS IS LOADED ONE FILE AT A TIME, and here is why. The first
%% whole-corpus run built a megabyte of codes, as many ids and three hundred
%% thousand windows as ONE set of lists inside ONE free_list scope, and the
%% container killed it at 11 GB resident: a scope reclaims on the way out, and
%% nothing about a scope lowers its peak. So the peak is made small instead.
%% Pass one reads each file inside its own scope and asserts the distinct
%% codes it saw -- at most a few hundred facts -- and the vocabulary is their
%% sorted union, the same for every file. Pass two reads each file again
%% inside its own scope, makes its ids, windows and TWO TENSORS, and asserts
%% the two handles; on the way out that file's lists are gone. The parts are
%% then concatenated along the rows, and the parts freed. What is lost: the
%% windows that would have straddled a file boundary, at most thirty-one
%% per boundary out of thousands per file. What is kept: the round-robin
%% order, the cap that cuts exactly one file, and the positional held-out
%% split over the concatenation.
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
                                          ( '$cs_code'(C) -> true ; assertz('$cs_code'(C)) )))).

%% pass two: one file's windows as two tensors, out through a fact
cs_load_part(Seq, Vocab, F-Take) :-
    free_list([Cs]>>(read_file_to_codes(F, Cs0), cs_take(Take, Cs0, Cs)),
              [Cs]>>( cs_ids(Cs, Vocab, Ids),
                      cs_windows(Ids, Xs, Ys, N),
                      (   N > 0
                      ->  tensor_from_list(Xs, X), tensor_from_list(Ys, Y),
                          assertz('$cs_part'(Seq, X, Y))
                      ;   true ))).

cs_load_parts(_, _, []).
cs_load_parts(Seq, Vocab, [P|Ps]) :-
    cs_load_part(Seq, Vocab, P),
    Seq1 is Seq + 1,
    cs_load_parts(Seq1, Vocab, Ps).

%% the parts in order, concatenated two at a time so no list of sixty-five
%% handles is ever needed; the consumed parts are freed as it goes
cs_cat_parts([X-Y], X, Y) :- !.
cs_cat_parts([X1-Y1, X2-Y2 | Rest], X, Y) :-
    tensor_cat([X1, X2], 0, X12), tensor_cat([Y1, Y2], 0, Y12),
    tensor_free(X1), tensor_free(X2), tensor_free(Y1), tensor_free(Y2),
    cs_cat_parts([X12-Y12 | Rest], X, Y).

%% cs_heavy_load(+Cap, -X, -Y, -N, -V): the capped corpus as two tensors,
%% never more than one file's lists on the heap at a time
cs_heavy_load(Cap, X, Y, N, V) :-
    cs_sources_heavy(Files),
    cs_plan(Cap, Files, Plan),
    retractall('$cs_code'(_)), retractall('$cs_part'(_, _, _)),
    forall(member(P, Plan), cs_note_codes(P)),
    findall(C, '$cs_code'(C), Cs0), sort(Cs0, Vocab), length(Vocab, V),
    cs_load_parts(0, Vocab, Plan),
    findall(S-Xp-Yp, '$cs_part'(S, Xp, Yp), Parts0), msort(Parts0, Parts1),
    findall(Xp-Yp, member(_-Xp-Yp, Parts1), Parts),
    retractall('$cs_part'(_, _, _)),
    cs_cat_parts(Parts, X, Y),
    tensor_shape(X, [N | _]).

%% heavy(+Cap) is det.   Cap is a byte count, or `all' for the whole corpus.
%%
%% A GPU WORKLOAD. On a machine with no CUDA device the cap is brought down to
%% cs_cpu_cap/1 and the run says so: the whole corpus is minutes on a T4 and
%% the better part of an hour on two CPUs, and a small run proves the same
%% path. A machine that HAS a GPU but was told torch_device(cpu) runs the cap
%% it was given -- that is the comparison, and it is asked for on purpose.
cs_cpu_cap(20000).
heavy(all) :- !, cs_heavy_bytes(B), heavy(B).
heavy(Cap0) :-
    cs_cpu_cap(Small),
    (   torch_cuda_available(false), Cap0 > Small
    ->  format("heavy: no CUDA device here -- running heavy(~w) instead of heavy(~w); the full run wants a GPU~n", [Small, Cap0]),
        Cap = Small
    ;   Cap = Cap0 ),
    torch_seed(28),
    cs_sources_heavy(Files), length(Files, NF),
    cs_heavy_bytes(Bytes),
    cs_reach(Cap, Files, NR),
    Used is min(Bytes, Cap),
    cs_heavy_load(Cap, X, Y, N, V),
    cs_split(N, NTrain), Held is N - NTrain,
    cs_spec(V, Spec),
    cs_epochs(E), cs_batch(B), cs_lr(LR),
    tensor_rows(X, 0, NTrain, XTr), tensor_rows(Y, 0, NTrain, YTr),
    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),
    format("heavy: ~w bytes of ~w, reaching ~w of ~w files, ~w windows over ~w characters, holding out ~w~n",
           [Used, Bytes, NR, NF, N, V, Held]),
    model_new(Spec, M),
    model_params(M, P), length(P, NP),
    model_train(M, XTr, YTr, [epochs(E), batch(B), lr(LR), optimiser(adam),
                              loss(nll), shuffle(true), final_loss(L)]),
    model_evaluate(M, XTe, YTe, accuracy, A),
    Pct is truncate(A * 1000 + 0.5) / 10.0,
    Uniform is log(V),
    torch_current_device(D), tensor_execution(Mode),
    format("heavy: ~w parameters on ~w under ~w: final nll ~4f (uniform ~4f), held-out accuracy ~w%~n",
           [NP, D, Mode, L, Uniform, Pct]),
    write(done), nl.

%% ---- generation ------------------------------------------------------
%%
%% SAMPLED, NOT ARGMAXED. An argmax model writes one file for ever; the
%% temperature divides the log-probabilities before they are exponentiated, so
%% low T is timid and repetitive and high T is adventurous and wrong. Both
%% failure modes are worth seeing, which is why generate/0 shows three.

cs_step(M, Ctx, T, Step, Id) :-
    tensor_from_list([Ctx], X),
    model_predict(M, X, P),
    tensor_to_list(P, [LogProbs]),
    cs_sample(LogProbs, T, Step, Id),
    tensor_free(X),
    tensor_free(P), !.

cs_generate(_, _, _, _, 0, []) :- !.
cs_generate(M, Vocab, Ctx, T, N, [Code|Rest]) :-
    cs_step(M, Ctx, T, N, Id),
    nth0(Id, Vocab, Code),
    append(_, [_|Tail], Ctx),
    length(Ctx, K), length(Tail, K1), K1 is K - 1,
    append(Tail, [Id], Ctx1),
    N1 is N - 1,
    cs_generate(M, Vocab, Ctx1, T, N1, Rest).

%% THE WEIGHTS, exponentiated at temperature T. exp/1 of a log-probability
%% divided by T: at T=1 that is the model's own distribution, below it sharpens
%% and above it flattens.
cs_sample(LogProbs, T, Step, Id) :-
    cs_weights(LogProbs, T, Ws),
    cs_sum(Ws, Sum),
    cs_noise(Step, R),
    Target is R * Sum,
    cs_pick(Ws, Target, 0.0, Id), !.

cs_weights([], _, []).
cs_weights([L|Ls], T, [W|Ws]) :- W is exp(L / T), cs_weights(Ls, T, Ws).

cs_sum([], 0.0).
cs_sum([W|Ws], S) :- cs_sum(Ws, S0), S is S0 + W.

%% THERE IS NO random/1 IN THIS DIALECT -- an unknown arithmetic functor is
%% uncatchably fatal, not an error you can catch. This is the same sin-based
%% hash lesson 22 uses: deterministic, so a run repeats, and uncorrelated
%% enough across steps to sample with.
%% THE abs/1 IS NOT DECORATION. truncate/1 rounds TOWARD ZERO, so for a
%% negative S the fraction S - truncate(S) is NEGATIVE -- and a negative
%% target makes cs_pick/4 match its first clause immediately, returning id 0
%% every time. Id 0 is the lowest character code in the vocabulary, which here
%% is a newline: the model was fine and the sampler emitted whitespace for
%% half of all steps. Lesson 25 has the abs and this did not.
cs_noise(Step, R) :-
    S is sin(Step * 12.9898 + 78.233) * 43758.5453,
    R is abs(S - truncate(S)).

cs_pick([W|_], Target, Acc, 0) :- Acc + W >= Target, !.
cs_pick([W|Ws], Target, Acc, Id) :-
    Acc1 is Acc + W,
    cs_pick(Ws, Target, Acc1, Id0),
    Id is Id0 + 1.

generate :-
    model_load(t28_cs, M),
    cs_data(Vocab, _, _, _, _),
    cs_seed_context(Vocab, Ctx),
    forall(member(T, [0.5, 0.8, 1.0]),
           ( format("~n---- temperature ~w ----~n", [T]),
             cs_generate(M, Vocab, Ctx, T, 400, Codes),
             format("~s~n", [Codes]) )),
    write(done), nl.

%% A REAL PROMPT FROM THE CORPUS, so the model starts somewhere it has seen
%% rather than from a context of one repeated character.
cs_seed_context(Vocab, Ctx) :-
    cs_context(K),
    atom_codes('main :-\n    format("~n-- ', Seed),
    cs_pad(Seed, K, Padded),
    cs_ids(Padded, Vocab, Ctx).

cs_pad(Codes, K, Out) :-
    length(Codes, N),
    (   N >= K
    ->  Skip is N - K, cs_drop(Skip, Codes, Out)
    ;   Pad is K - N, cs_spaces(Pad, Sp), append(Sp, Codes, Out)
    ).

cs_spaces(0, []) :- !.
cs_spaces(N, [32|R]) :- N1 is N - 1, cs_spaces(N1, R).

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

judge :-
    model_load(t28_cs, M),
    cs_data(Vocab, _, _, _, _),
    cs_seed_context(Vocab, Ctx),
    forall(member(T, [0.5, 0.8, 1.0]),
           ( cs_generate(M, Vocab, Ctx, T, 1200, Codes),
             cs_judge_one(T, Codes) )),
    write(done), nl.

cs_judge_one(T, Codes) :-
    cc_split_clauses(Codes, Spans),
    length(Spans, NSpans),
    cs_heads(Spans, Codes, Heads),
    length(Heads, NHeads),
    length(Codes, NB),
    format("~n-- temperature ~w: ~w bytes~n", [T, NB]),
    format("   ~w runs the reader accepted as a clause~n", [NSpans]),
    format("   ~w of them had a head it could name~n", [NHeads]),
    cs_show_heads(Heads, 6).

cs_heads([], _, []).
cs_heads([Span|Ss], Codes, Out) :-
    Span = at(Off, _, _, Len),
    cs_drop(Off, Codes, Tail),
    cs_take(Len, Tail, Slice),
    (   catch(cc_read_head(Slice, Span, cc_clause(_, head(N, A), _)), _, fail)
    ->  Out = [N/A|Rest]
    ;   Out = Rest
    ),
    cs_heads(Ss, Codes, Rest).

cs_show_heads([], _) :- !.
cs_show_heads(_, 0) :- !.
cs_show_heads([H|Hs], N) :-
    format("     ~q~n", [H]),
    N1 is N - 1,
    cs_show_heads(Hs, N1).

%% predict/0 IS THE SUITE'S THIRD GOAL, and it has to fit in 300 seconds like
%% the other twenty-seven. It generates a short sample at one temperature and
%% puts it to the reader, which is the whole lesson in miniature; generate/0
%% and judge/0 above are the same thing at a length a human wants to read.
predict :-
    model_load(t28_cs, M),
    cs_data(Vocab, _, _, _, _),
    cs_seed_context(Vocab, Ctx),
    cs_generate(M, Vocab, Ctx, 0.8, 200, Codes),
    format("~n~s~n", [Codes]),
    cs_judge_one(0.8, Codes),
    write(done), nl.

main :- corpus, train, test, generate, judge.
