%% 22. Embedding + LSTM: remembering whether a token ever appeared
%%
%% The shape of every text classifier: tokens (small integers) become
%% learned vectors through an embedding -- a vocabulary of eight, four
%% dimensions each -- and an LSTM reads the vector sequence and keeps what
%% matters in its cell state. The task is pure memory: did token 3 appear
%% ANYWHERE in the six-token sequence? A bag of words could answer this
%% one too, but the machinery -- ids in, embedding, recurrence, class out
%% -- is exactly the sentiment-analysis pipeline at toy scale.
%%
%% The embedding is a parameter matrix E of [8, 4], and the lookup is
%% `index_rows(E, Ids)': the step's N token ids, as an index tensor, pick
%% their N rows. The LSTM cell is tutorial 21's, four gates written out as
%% a PROCEDURE over the batch's rows at one timestep; the sequence is a
%% recursion over the six steps threading the hidden and cell states, and
%% the last hidden state goes through a dense head to two logits, with
%% cross_entropy against the one-hot label. An earlier version of this
%% file spelled the same network as model_new's sequence(6), embedding(8, 4),
%% lstm(16), dense(2, log_softmax); that layer API is still taught in
%% tutorials/library/22-torch.pl.
%%
%%   train    96 sequences, Adam, 300 steps over the whole batch; saved as t22_embed
%%   test     reload, accuracy over the 96 at 95%
%%   predict  reload, probe with and without the token
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/22-embedding-lstm.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/22-embedding-lstm.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/22-embedding-lstm.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).

%% ---- the sequences ----------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.

%% tok_row(+I, -Row, -Label): six tokens from 0..7, and 1 when 3 is among them.
tok_row(I, Row, L) :-
    findall(T, ( between(0, 5, J), noise(I * 6 + J + 70000, F), T is truncate(abs(F) * 7.99) ), Row),
    ( member(3, Row) -> L = 1 ; L = 0 ), !.

%% tok_data(-Rows, -Labels): the 96 sequences as lists, and their labels.
tok_data(Rows, Labels) :-
    findall(R, ( between(0, 95, I), tok_row(I, R, _) ), Rows),
    findall(L, ( between(0, 95, I), tok_row(I, _, L) ), Labels), !.

%% steps(+Rows, -Ins): the six columns of the token rows, each an index
%% tensor of the N ids at that step -- what index_rows/2 looks up with.
steps(Rows, Ins) --> steps(0, Rows, Ins).
steps(6, _, []) --> !.
steps(P, Rows, [In|Ins]) -->
    { findall(T, ( member(Row, Rows), nth0(P, Row, T) ), Col) },
    In = Col,
    { P1 is P + 1 },
    steps(P1, Rows, Ins).

%% ---- the network -------------------------------------------------------------
%% An embedding of [8, 4], a hidden state of 16, a head of two logits.

parameters(Ps) :-
    Emb := parameter(randn([8, 4]) * 0.5),
    cell_params(4, 16, Cell),
    Wd := parameter(glorot(16, 2)), Bd := parameter(zeros([1, 2])),
    append([[Emb], Cell, [Wd, Bd]], Ps), !.
cell_params(In, H, [Wi, Ui, Bi, Wf, Uf, Bf, Wo, Uo, Bo, Wg, Ug, Bg]) :-
    Wi := parameter(glorot(In, H)), Ui := parameter(glorot(H, H)), Bi := parameter(zeros([1, H])),
    Wf := parameter(glorot(In, H)), Uf := parameter(glorot(H, H)), Bf := parameter(zeros([1, H])),
    Wo := parameter(glorot(In, H)), Uo := parameter(glorot(H, H)), Bo := parameter(zeros([1, H])),
    Wg := parameter(glorot(In, H)), Ug := parameter(glorot(H, H)), Bg := parameter(zeros([1, H])), !.
unpack(Ps, Emb, Cell, Wd, Bd) :- length(Cell, 12), append([[Emb], Cell, [Wd, Bd]], Ps), !.

%% lstm(+Cell, +X, +H, +C, -H2, -C2): one step over the batch's rows --
%% input, forget and output gates, the candidate, the new cell state, the
%% new hidden state -- a PROCEDURE, a DCG rule of six bindings; a procedure
%% called inside another threads what it made up to the caller, and exec/1
%% at the top frees all of it but what the head returns.
lstm([Wi, Ui, Bi, Wf, Uf, Bf, Wo, Uo, Bo, Wg, Ug, Bg], X, H, C, H2, C2) -->
    I = sigmoid(X matmul Wi + H matmul Ui + Bi),
    F = sigmoid(X matmul Wf + H matmul Uf + Bf),
    O = sigmoid(X matmul Wo + H matmul Uo + Bo),
    G = tanh(X matmul Wg + H matmul Ug + Bg),
    C2 = F * C + I * G,
    H2 = O * tanh(C2).

%% scan(+Emb, +Cell, +Ins, +H, +C, -HF): the sequence, a step per index
%% tensor -- the lookup, then the cell -- threading the states.
scan(_, _, [], H, _, H) --> [].
scan(Emb, Cell, [In|Ins], H, C, HF) -->
    X = index_rows(Emb, In),
    lstm(Cell, X, H, C, H2, C2),
    scan(Emb, Cell, Ins, H2, C2, HF).

%% forward(+Ps, +Ins, -Logits): six index tensors in, [N, 2] logits out.
forward(Ps, Ins, Logits) -->
    { unpack(Ps, Emb, Cell, Wd, Bd), Ins = [In0|_] },
    [N] = shape(In0),
    H0 = zeros([N, 16]), C0 = zeros([N, 16]),
    scan(Emb, Cell, Ins, H0, C0, H),
    Logits = H matmul Wd + Bd.

%% ---- the three goals -----------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(22),
    { tok_data(Rows, Labels) },
    steps(Rows, Ins), one_hot(Labels, 2, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(300, Ps0, St0, Ins, Y, Ps) },
    forward(Ps, Ins, Logits), accuracy(Logits, Labels, Acc),
    { format("trained: accuracy on the 96 sequences ~2f~n", [Acc]) },
    params_save(t22_embed, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, Ins, Y, PsF) :-
    exec(forward(Ps, Ins, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 100 =:= 0 -> Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.02, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Ins, Y, PsF).

test -->
    Ps = params(t22_embed),
    { tok_data(Rows, Labels) },
    steps(Rows, Ins),
    forward(Ps, Ins, Logits), accuracy(Logits, Labels, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("accuracy ~w%~n", [Pct]),
      ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    Ps = params(t22_embed),
    { Rows = [[0, 1, 2, 3, 4, 5],    % contains 3
              [0, 1, 2, 4, 5, 6],    % does not
              [3, 0, 0, 0, 0, 0],    % 3 at the very start: the memory test
              [7, 7, 7, 7, 7, 7]] },
    steps(Rows, Ins),
    forward(Ps, Ins, Logits),
    Picks = list(argmax(Logits, 1)),
    { forall(( nth0(I, Picks, Pk), nth0(I, Rows, Row) ),
             ( C is round(Pk),
               ( C =:= 1 -> V = 'contains token 3' ; V = 'no token 3' ),
               ( member(3, Row) -> Truth = 'contains token 3' ; Truth = 'no token 3' ),
               format("~w  ->  ~w  (truth: ~w)~n", [Row, V, Truth]) )) }.
