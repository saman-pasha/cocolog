%% 27. Where attention actually wins: an induction task
%%
%%   train    five networks on the same task, each from a specification and each for the same 300 steps;
%%            the lstm and the two-layer attention saved as t27_lstm and t27_attn2
%%   test     reload both, and hold the crossover: attention above 90%, the lstm below 60%
%%   predict  watch the trained models do the lookup, by hand
%%
%% LESSON 26 ENDED ON A LOOSE THREAD. It found an lstm and a transformer
%% tied exactly on character prediction -- at 4,200 characters and again at
%% 200,000 -- and guessed that the crossover would come with a longer
%% CONTEXT WINDOW, where attention can look anywhere and a recurrent state
%% starts to forget. That guess was tested and it was wrong. Measured on
%% 64,000 characters of cocolog:
%%
%%   window     lstm    transformer
%%       4     56.3%       55.7%          (24 epochs, two seeds each)
%%      16     52.5%       55.1%          (8 epochs)
%%      64     56.4%       54.6%          (24 / 8 epochs)
%%     128     51.9%       out of memory
%%
%% Four characters of context are as good as sixty-four. The window was
%% never the constraint: NEXT-CHARACTER PREDICTION IS A LOCAL TASK, and no
%% amount of window helps a model attend to information that is not there.
%%
%% SO THIS FILE CHANGES THE TASK INSTEAD. The sequence is random tokens
%% over an alphabet of eight. The label is the token that FOLLOWED the last
%% previous occurrence of the final token:
%%
%%   [5,2,7,5,4,7,2,7,2,0,0,2,1,4,4,5,5,3,4,7,2,4,0,5]  ->  3
%%    ^                              ^ ^                     ^
%%    |                              | the 5 at position 17  |
%%    the query is the last token, 5 | is followed by a 3 ---+
%%
%% To answer it you must FIND the earlier occurrence -- which can be
%% anywhere in the window -- and read off its successor. Nothing local
%% helps. This is the "induction" task, and the circuit that solves it is
%% known: a previous-token head in one layer, and a head in the NEXT layer
%% that matches the query against what the first one wrote. One attention
%% layer cannot express it. Two can.
%%
%% EVERY NETWORK HERE IS A SPECIFICATION, a list of layers the way the
%% torch module's model_new/2 took one -- the earlier version of this file
%% handed those lists to model_new, and library lesson 22 still teaches
%% that API. This one INTERPRETS them: build/3 walks a specification making
%% one flat parameter list, forward//5 walks it again making the tensor
%% expressions -- an lstm cell is four gates and a blend over the
%% timesteps, an attention layer is softmax(Q K^T / sqrt(d) + Mask) V one
%% head at a time, both in the open -- and the same walk serves all five
%% networks. The batch is one [N*24, D] matrix; causal_mask/3 keeps every
%% position to its own sequence and to what came before it; the recurrent
%% layers read the matrix a timestep at a time through index_rows with a
%% constant index per step, and hand their states back in row order the
%% same way. Adam steps every parameter; params_save/2 keeps the two the
%% test wants.
%%
%% AND EVERY POSITION IS A QUERY. The earlier version predicted one label
%% per sequence, at the end, and needed sixty epochs -- eight minutes of
%% CPU -- to get its two-layer model there. Under a causal mask position t
%% sees tokens 1..t and nothing after, so the prefix that ends at t is the
%% same task on a shorter window, its label given by the same rule, and
%% the loss is cross_entropy at every position: twenty-four targets a
%% sequence instead of one, at no extra cost. The held-out MEASURE is
%% still the query, the last position, a full window of context. With that
%% objective the two-layer model finds the circuit in under two hundred
%% steps, and five fits stay inside the runner's budget.
%%
%% ---- THE RESULT, on this file's seed, 300 Adam steps of 40 sequences ---
%%
%%   model                            held-out accuracy   (chance 12.5%)
%%   lstm(96)                              52.2%
%%   lstm(96), lstm(96)   -- depth         65.3%
%%   lstm(192)            -- capacity      78.0%
%%   attention x1                          36.8%
%%   attention x2                          97.0%
%%
%% Those are libtorch's numbers; `train' prints them every run, and under
%% tensor_execution(tensorflow, graph) the same file gives 55.2, 60.7,
%% 80.7, 34.7 and 97.3. The budget is the point of the table, so here is
%% the same measurement every hundred steps, the two models the test
%% reloads, on both libraries:
%%
%%   steps          100     200     300     400     500     600
%%   attention x2   0.38    0.94    0.97    0.97    0.99    0.99     (tensorflow: 0.40 0.92 0.98 0.98 0.98 0.99)
%%   lstm(96)       0.34    0.40    0.50    0.57    0.62    0.68     (tensorflow: 0.33 0.43 0.48 0.57 0.66 0.72)
%%
%% THE TWO-LAYER TRANSFORMER SOLVES IT, AND IT SOLVES IT ALL AT ONCE.
%% Between step 100 and step 200 its accuracy goes from chance-and-a-bit
%% to over ninety: the previous-token head and the matching head form
%% together, and once they exist the lookup is one matmul at any distance.
%% The lstm CLIMBS -- six points a hundred steps, still climbing at six
%% hundred, and it would go on. A state of ninety-six numbers can hold the
%% followers of eight tokens; what it has to learn is to keep that table
%% and to overwrite the right entry at every step, and it learns that
%% slowly, one step-size at a time. So the crossover this file holds is a
%% gap at an equal budget, and the earlier version's numbers -- 37% for
%% the lstm after sixty epochs on one label a sequence -- were that same
%% slowness starved of targets.
%%
%% The controls say what a bigger state buys under this objective: a
%% second lstm layer thirteen points, twice the width twenty-six -- the
%% table is easier to keep in a wider state. None of them is near the
%% two-layer attention, and the ONE-layer transformer is the worst model on
%% the table. That is not noise and it is not a bug: a single attention
%% layer has no previous-token head to match against, so it cannot do the
%% lookup either, and it has a worse inductive bias for the local guessing
%% that is all any of the losing models are doing. Depth is not a dial
%% here. It is the difference between expressible and not.
%%
%% WHAT LESSON 26 SHOULD HAVE SAID, and now does: attention wins when the
%% task requires reaching an arbitrary earlier position, and the model is
%% deep enough to express the reach -- and it wins by finding the reach at
%% once, where a recurrent state has to learn to carry it. Character
%% prediction over source code asks for neither.
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/27-induction.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/27-induction.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/27-induction.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the task -------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

ind_len(24).            %% window
ind_rows(6000).         %% sequences
ind_train(5400).        %% the first 90%
ind_batch(40).          %% sequences per step; 5400 and 600 are both multiples
ind_steps(300).         %% Adam steps per network, the same for all five
ind_lr(0.003).
ind_chance(0.125).      %% one of eight
ind_floor(0.90).        %% what the two-layer model must clear
ind_ceiling(0.60).      %% what a model that cannot do the lookup must NOT

%% No random/1 in this dialect, so the data carries its own hash -- the same
%% one tutorial 22 uses. Deterministic, so `train' and `test' generate the
%% identical rows in different processes without storing them.
ind_noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is abs(S - truncate(S)), !.
ind_tok(Seed, I, T) :- ind_noise(Seed * 7919 + I, F), T is truncate(F * 7.999), !.

%% ind_row(+Seed, +K, -Row, -Label): the K tokens of a sequence and its label.
ind_row(Seed, K, Row, Label) :-
    findall(T, (between(1, K, J), ind_tok(Seed, J, T)), Row),
    ind_labels(Row, Labels), last(Labels, Label), !.

%% ind_labels(+Row, -Labels): THE LABEL OF EVERY PREFIX, one pass. Position
%% t is the query of the prefix that ends there, and its label is the token
%% that followed the newest earlier occurrence of that token -- an
%% occurrence at t-1 has no follower yet and does not count -- or 0 when
%% there is none. The pass keeps a table of eight, the follower of the
%% newest occurrence of each token so far, reads the query's entry before
%% writing the pair (previous, query) into it, and so the entry it reads
%% is about positions up to t-2, which is the rule. The FINAL label is the
%% sequence's; the others are the same task on shorter windows, and
%% training on all of them is what gives a step 24 targets a sequence.
%%
%% The first version of this labelled by walking the window backwards from
%% the query, and defined the walk the wrong way round -- directly under a
%% comment saying the opposite. That does not fail: it silently defines a
%% DIFFERENT task, one with no learnable structure, and every model then
%% scores near chance. The models were right and the labels were wrong.
ind_labels(Row, Labels) :- ind_labels(Row, none, [0, 0, 0, 0, 0, 0, 0, 0], Labels), !.
ind_labels([], _, _, []) :- !.
ind_labels([Q|Qs], Prev, Table, [L|Ls]) :-
    nth0(Q, Table, L),
    ( Prev == none -> Table2 = Table ; ind_set(Table, Prev, Q, Table2) ),
    ind_labels(Qs, Q, Table2, Ls), !.
ind_set([_|T], 0, V, [V|T]) :- !.
ind_set([H|T], I, V, [H|T2]) :- I1 is I - 1, ind_set(T, I1, V, T2), !.

%% How far back the match is, for predict's table.
ind_gap(Row, D) :-
    last(Row, Q), length(Row, K), Before is K - 1,
    length(Head, Before), append(Head, _, Row), reverse(Head, Rev),
    ( nth1(P, Rev, Q) -> D = P ; D = none ), !.

%% ---- batches ------------------------------------------------------------------
%% A batch of N sequences is ONE index tensor of N*24 tokens, sequence by
%% sequence; the label of every position one-hot, for the loss; and the
%% final labels as a list, for accuracy/3 at the query.
%% GENERATE ONLY THE SLICE YOU NEED: `test' builds its 600 held-out rows and
%% not the 5400 it will never look at, and `predict' builds six.

batch(From, N, batch(Ids, Y, Finals)) -->
    { To is From + N - 1, ind_len(K),
      findall(R-Ls, ( between(From, To, S), ind_row(S, K, R, _), ind_labels(R, Ls) ), Pairs),
      findall(T, ( member(R-_, Pairs), member(T, R) ), Flat),
      findall(L, ( member(_-Ls, Pairs), member(L, Ls) ), All),
      findall(F, ( member(_-Ls, Pairs), last(Ls, F) ), Finals) },
    Ids = Flat, one_hot(All, 8, Y), !.

%% batches(+From, +To, +N, -Batches): the seeds From .. To, N to a batch.
batches(From, To, _, []) --> { From > To }, !.
batches(From, To, N, [B|Bs]) -->
    batch(From, N, B), { Next is From + N }, batches(Next, To, N, Bs).

%% constants(+N, -Ctx): what every network reads for a batch of N -- the
%% position of each row for the positional embedding; the causal mask, so
%% attention stays inside a sequence and looks only backwards; one index
%% tensor per timestep naming the rows of all N sequences at that step, for
%% the recurrent layers, the last of them the queries; and the permutation
%% that puts a recurrent layer's time-major output back into row order.
constants(N, c(N, K, PosIds, Mask, Ats, Perm)) -->
    { ind_len(K), K1 is K - 1, N1 is N - 1,
      findall(P, ( between(1, N, _), between(0, K1, P) ), PosList),
      findall(I, ( between(0, N1, S), between(0, K1, T), I is T * N + S ), PermList) },
    PosIds = PosList, Perm = PermList,
    causal_mask(N, K, Mask),
    steps(0, K, N1, Ats), !.
steps(K, K, _, []) --> !.
steps(T, K, N1, [At|Ats]) -->
    { findall(I, ( between(0, N1, S), I is S * K + T ), L) },
    At = L,
    { T1 is T + 1 }, steps(T1, K, N1, Ats).

%% ---- the five networks, as specifications -----------------------------------
%% embedding(D) is a table of 8 rows; positional a table of 24; lstm(H) a
%% cell with H units; attention(Heads) a pre-norm self-attention with its
%% residual; ffn(F) a pre-norm feed-forward of width F with its residual;
%% dense(8) the readout, at every position.

spec(lstm,  [embedding(32), lstm(96), dense(8)]).
spec(lstm2, [embedding(64), lstm(96), lstm(96), dense(8)]).
spec(wide,  [embedding(64), lstm(192), dense(8)]).
spec(attn1, [embedding(64), positional, attention(4), ffn(128), dense(8)]).
spec(attn2, [embedding(64), positional, attention(4), ffn(128), attention(4), ffn(128), dense(8)]).

label(lstm,  'lstm(96)                     ').
label(lstm2, 'lstm(96), lstm(96)  -- depth ').
label(wide,  'lstm(192)        -- capacity ').
label(attn1, 'attention x1                 ').
label(attn2, 'attention x2                 ').

%% build(+Spec, +D, -Ps): the parameters a specification needs, one flat list
%% in the order forward//5 reads them back; D is the width coming in.
build([], _, []) :- !.
build([embedding(D)|Spec], _, [Emb|Ps]) :- !,
    Emb := parameter(randn([8, D])), build(Spec, D, Ps).
build([positional|Spec], D, [Pos|Ps]) :- !,
    ind_len(K), sinusoids(K, D, Table), Pos := parameter(Table), build(Spec, D, Ps).
build([lstm(H)|Spec], D, [W, U, B|Ps]) :- !,
    H4 is 4 * H,
    W := parameter(glorot(D, H4)), U := parameter(glorot(H, H4)), B := parameter(zeros([1, H4])),
    build(Spec, H, Ps).
build([attention(_)|Spec], D, [G, Bt, Wq, Wk, Wv, Wo|Ps]) :- !,
    G := parameter(ones([1, D])), Bt := parameter(zeros([1, D])),
    Wq := parameter(glorot(D, D)), Wk := parameter(glorot(D, D)), Wv := parameter(glorot(D, D)), Wo := parameter(glorot(D, D)),
    build(Spec, D, Ps).
build([ffn(F)|Spec], D, [G, Bt, W1, B1, W2, B2|Ps]) :- !,
    G := parameter(ones([1, D])), Bt := parameter(zeros([1, D])),
    W1 := parameter(glorot(D, F)), B1 := parameter(zeros([1, F])),
    W2 := parameter(glorot(F, D)), B2 := parameter(zeros([1, D])),
    build(Spec, D, Ps).
build([dense(C)|Spec], D, [Wc, Bc|Ps]) :- !,
    Wc := parameter(glorot(D, C)), Bc := parameter(zeros([1, C])), build(Spec, D, Ps).

%% sinusoids(+K, +D, -Rows): the position code of the original transformer,
%% sin and cos at D/2 frequencies from 1 to 1/10000 -- the START of the
%% position table, which is then learned like any parameter. It is chosen
%% for what the induction circuit needs first: under this code `one position
%% back' is the same rotation at every position, so the previous-token head
%% is a linear map a head can express from the first step. A table started
%% at random gets there too, and took several times the steps.
sinusoids(K, D, Rows) :-
    K1 is K - 1, D1 is D - 1,
    findall(Row, ( between(0, K1, T),
                   findall(V, ( between(0, D1, I), Pair is (I // 2) * 2, W is 10000.0 ** (Pair / D), A is T / W,
                                ( I mod 2 =:= 0 -> V is sin(A) ; V is cos(A) ) ), Row) ), Rows), !.

%% forward(+Spec, +Ps, +Ctx, +Ids, -Logits): the network a specification
%% names, over one batch -- a PROCEDURE, a DCG rule of bindings; exec/1 runs
%% it and frees everything it made but Logits, which is [N*24, 8]: an
%% answer at every position, each from what that position can see. The
%% walk carries the width and the activation: a matrix of N*24 rows, or,
%% after a recurrent layer, steps(Hs) -- the hidden state at every
%% timestep, N rows each.
forward([embedding(D)|Spec], [Emb|Ps], Ctx, Ids, Logits) -->
    X = index_rows(Emb, Ids),
    forward(Spec, Ps, Ctx, D, X, Logits).

forward([positional|Spec], [Pos|Ps], Ctx, D, X, Out) -->
    { Ctx = c(_, _, PosIds, _, _, _) },
    X2 = X + index_rows(Pos, PosIds),
    forward(Spec, Ps, Ctx, D, X2, Out).
forward([lstm(H)|Spec], [W, U, B|Ps], Ctx, _, X, Out) -->
    { Ctx = c(N, _, _, _, Ats, _) },
    H0 = zeros([N, H]), C0 = zeros([N, H]),
    lstm(Ats, 0, X, W, U, B, H, H0, C0, Hs),
    forward(Spec, Ps, Ctx, H, steps(Hs), Out).
forward([attention(Heads)|Spec], [G, Bt, Wq, Wk, Wv, Wo|Ps], Ctx, D, X, Out) -->
    { Ctx = c(_, _, _, Mask, _, _), Dh is D // Heads, Scale is 1.0 / sqrt(Dh) },
    Xn = layer_norm(X) * G + Bt,
    Q = Xn matmul Wq, K = Xn matmul Wk, V = Xn matmul Wv,
    heads(0, Heads, Dh, Scale, Q, K, V, Mask, Os),
    X2 = X + cat(Os, 1) matmul Wo,
    forward(Spec, Ps, Ctx, D, X2, Out).
forward([ffn(_)|Spec], [G, Bt, W1, B1, W2, B2|Ps], Ctx, D, X, Out) -->
    X2 = X + relu((layer_norm(X) * G + Bt) matmul W1 + B1) matmul W2 + B2,
    forward(Spec, Ps, Ctx, D, X2, Out).
forward([dense(_)], [Wc, Bc], Ctx, _, steps(Hs), Logits) --> !,
    { Ctx = c(_, _, _, _, _, Perm) },
    joined(Hs, J),                                                  % the states, time-major
    Logits = index_rows(J, Perm) matmul Wc + Bc.                    % back in row order
forward([dense(_)], [Wc, Bc], _, _, X, Logits) -->
    Logits = X matmul Wc + Bc.

%% joined(+Ts, -J): the tensors as one, along the rows -- cat/2 six at a
%% time, since a backend may cap what one cat takes (TensorFlow's is seven).
joined(Ts, J) --> { length(Ts, N), N =< 6 }, !, J = cat(Ts, 0).
joined(Ts, J) --> { sixes(Ts, Cs) }, joined_each(Cs, Js), joined(Js, J).
joined_each([], []) --> [].
joined_each([C|Cs], [J|Js]) --> J = cat(C, 0), joined_each(Cs, Js).
sixes([], []) :- !.
sixes(Ts, [C|Cs]) :- length(C, 6), append(C, Rest, Ts), !, sixes(Rest, Cs).
sixes(Ts, [Ts]) :- !.

%% heads(+H, +Heads, +Dh, +Scale, +Q, +K, +V, +Mask, -Os): one head's attention
%% per column slice, the outputs joined back by cat/2 in the caller.
heads(Heads, Heads, _, _, _, _, _, _, []) --> !.
heads(H, Heads, Dh, Scale, Q, K, V, Mask, [O|Os]) -->
    { F is H * Dh, T is F + Dh },
    O = softmax(cols(Q, F, T) matmul transpose(cols(K, F, T)) * Scale + Mask) matmul cols(V, F, T),
    { H1 is H + 1 }, heads(H1, Heads, Dh, Scale, Q, K, V, Mask, Os).

%% lstm(+Ats, +T, +X, +W, +U, +B, +H, +Hin, +Cin, -Hs): the cell over the
%% timesteps -- one matmul of the input and one of the state make all four
%% gates at once, cols/3 cuts them apart, and the hidden state of every
%% step is kept for the layer above.
lstm([], _, _, _, _, _, _, _, _, []) --> [].
lstm([At|Ats], T, X, W, U, B, H, Hin, Cin, [Hout|Hs]) -->
    { H2 is 2 * H, H3 is 3 * H, H4 is 4 * H },
    input(X, At, T, Xt),
    Z = Xt matmul W + Hin matmul U + B,
    I = sigmoid(cols(Z, 0, H)), F = sigmoid(cols(Z, H, H2)), O = sigmoid(cols(Z, H2, H3)), G = tanh(cols(Z, H3, H4)),
    Cout = F * Cin + I * G,
    Hout = O * tanh(Cout),
    { T1 is T + 1 },
    lstm(Ats, T1, X, W, U, B, H, Hout, Cout, Hs).

%% input(+X, +At, +T, -Xt): the rows of every sequence at step T -- a gather
%% from a matrix, or the T-th state of the recurrent layer below.
input(steps(Xs), _, T, Xt) --> !, { nth0(T, Xs, Xt) }.
input(X, At, _, Xt) --> Xt = index_rows(X, At).

%% ---- fitting and measuring ---------------------------------------------------
%% Predicates, not rules: the fit loop steps an optimiser that frees the old
%% parameters itself, and the evaluation frees each batch's logits as it goes.

fit(0, _, Ps, St, _, _, _, Ps, St) :- !.
fit(K, Spec, Ps, St, Ctx, Batches, LR, PsF, StF) :-
    length(Batches, NB), B is K mod NB, nth0(B, Batches, batch(Ids, Y, _)),
    exec(forward(Spec, Ps, Ctx, Ids, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 200 =:= 0 -> Lv := item(L), format("      ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, LR, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Spec, Ps2, St2, Ctx, Batches, LR, PsF, StF).

%% evaluate(+Spec, +Ps, +Ctx, +Batches, -Acc): held-out accuracy at the
%% query -- the last position of every sequence -- a batch at a time.
evaluate(Spec, Ps, Ctx, Batches, Acc) :-
    evaluate(Batches, Spec, Ps, Ctx, 0, 0, Hits, Total), Acc is Hits / Total, !.
evaluate([], _, _, _, H, T, H, T) :- !.
evaluate([batch(Ids, _, Finals)|Bs], Spec, Ps, Ctx, H0, T0, H, T) :-
    Ctx = c(_, _, _, _, Ats, _), last(Ats, Last),
    exec(forward(Spec, Ps, Ctx, Ids, Logits)),
    Queries := index_rows(Logits, Last),
    accuracy(Queries, Finals, A), free_all([Logits, Queries]),
    length(Finals, N), H1 is H0 + round(A * N), T1 is T0 + N,
    evaluate(Bs, Spec, Ps, Ctx, H1, T1, H, T).

%% fit_one(+Kind, +Ctx, +Batches, +Held): one network from its specification,
%% on the same seed as the others; printed, saved if the test wants it, freed.
fit_one(Kind, Ctx, Batches, Held) :-
    seed(27),
    spec(Kind, Spec), build(Spec, 0, Ps0), adam_init(Ps0, St0),
    ind_steps(Steps), ind_lr(LR),
    fit(Steps, Spec, Ps0, St0, Ctx, Batches, LR, Ps, adam(_, Ms, Vs, _)),
    evaluate(Spec, Ps, Ctx, Held, A),
    label(Kind, Label), Pct is truncate(A * 1000 + 0.5) / 10.0,
    format("   ~w ~w%~n", [Label, Pct]),
    ( Kind == attn2 -> params_save(t27_attn2, Ps) ; true ),
    ( Kind == lstm  -> params_save(t27_lstm, Ps)  ; true ),
    free_all(Ps), free_all(Ms), free_all(Vs), !.

%% ---- the three goals -------------------------------------------------------------
%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls: the constants and the batches are made inside them and freed when
%% they end; the loop over the networks is a predicate in braces.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    { ind_rows(N), ind_train(NTr), ind_batch(B), ind_steps(Steps), From is NTr + 1,
      ind_chance(Ch), ChPct is truncate(Ch * 1000 + 0.5) / 10.0, Held is N - NTr,
      format("the induction task: ~w sequences, ~w held out, chance ~w%~n", [N, Held, ChPct]),
      format("~w Adam steps of ~w sequences per network~n", [Steps, B]) },
    constants(B, Ctx),
    batches(1, NTr, B, Batches),
    batches(From, N, B, HeldBatches),
    { forall(member(Kind, [lstm, lstm2, wide, attn1, attn2]), fit_one(Kind, Ctx, Batches, HeldBatches)),
      write(saved), nl }.

test -->
    { ind_rows(N), ind_train(NTr), ind_batch(B), From is NTr + 1 },
    constants(B, Ctx),
    batches(From, N, B, Held),
    PsA = params(t27_attn2), PsL = params(t27_lstm),
    { spec(attn2, SA), spec(lstm, SL),
      evaluate(SA, PsA, Ctx, Held, AA), evaluate(SL, PsL, Ctx, Held, AL),
      APct is truncate(AA * 1000 + 0.5) / 10.0,
      LPct is truncate(AL * 1000 + 0.5) / 10.0,
      format("two attention layers: ~w%~n", [APct]),
      format("one lstm layer:       ~w%~n", [LPct]),
      ind_floor(F), ind_ceiling(C),
      FPct is truncate(F * 100 + 0.5), CPct is truncate(C * 100 + 0.5),
      %% BOTH HALVES ARE THE CLAIM. A file that only checked the winner would
      %% pass just as happily if the task had quietly become easy enough for
      %% anything to solve, and the lesson is the GAP.
      (   AA >= F, AL =< C
      ->  format("the gap holds: attention above ~w%, recurrence below ~w%~n", [FPct, CPct]),
          write(ok), nl
      ;   AA < F
      ->  format("the two-layer model FELL BELOW ~w%~n", [FPct]),
          write('FAIL'), nl, halt(1)
      ;   format("the lstm ROSE ABOVE ~w% -- the task got easier, not the~n", [CPct]),
          format("model better, and the lesson no longer says anything.~n"),
          write('FAIL'), nl, halt(1)
      ) }.

%% HELD-OUT SEEDS, and chosen because the two models DISAGREE on them.
%% The first version of this used seeds 3..250, which are all in the
%% training set -- where the lstm has memorised and gets every one right. A
%% demonstration on training data shows nothing. These six are from
%% 5401..6000, which no model has seen, and they span match distances 2 to 23.
predict -->
    PsA = params(t27_attn2), PsL = params(t27_lstm),
    { Seeds = [5426, 5436, 5408, 5427, 5572, 5566], ind_len(K),
      findall(R-W, ( member(S, Seeds), ind_row(S, K, R, W) ), Pairs),
      findall(T, ( member(R-_, Pairs), member(T, R) ), Flat),
      spec(attn2, SA), spec(lstm, SL) },
    constants(6, Ctx),
    { Ctx = c(_, _, _, _, Ats, _), last(Ats, Last) },
    Ids = Flat,
    forward(SA, PsA, Ctx, Ids, LA), forward(SL, PsL, Ctx, Ids, LL),
    GA = list(argmax(index_rows(LA, Last), 1)), GL = list(argmax(index_rows(LL, Last), 1)),
    { format("~n-- the lookup, one row at a time~n"),
      format("   Each row ends with a query token. The answer is whatever~n"),
      format("   followed that token the last time it appeared. `want' is~n"),
      format("   the truth, computed by ind_row/4 and not by either model.~n~n"),
      forall(( nth0(I, Pairs, Row-Want), nth0(I, GA, A0), nth0(I, GL, L0) ),
             ( PA is round(A0), PL is round(L0), ind_gap(Row, D),
               ( PA =:= Want -> OA = ok ; OA = '  ' ),
               ( PL =:= Want -> OL = ok ; OL = '  ' ),
               %% NO COLUMN DIRECTIVES. `~t', `~|' and `~+' are refused by
               %% name in this dialect (lib/builtins.cicili), so the columns
               %% are labels rather than stops.
               format("     back ~w   want ~w   attention ~w ~w   lstm ~w ~w~n",
                      [D, Want, PA, OA, PL, OL]) )),
      format("~n   `back' is how far back the earlier occurrence sits.~n"),
      format("   Attention reaches it at any distance because reaching is~n"),
      format("   one matmul. The lstm has to have carried that pair forward~n"),
      format("   in ninety-six numbers, along with every other pair.~n"),
      write(done), nl }.
