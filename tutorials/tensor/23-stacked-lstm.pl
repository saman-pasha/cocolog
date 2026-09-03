%% 23. A stacked LSTM, and recurrent weights through the store
%%
%% Two LSTMs in a row: the first reads embedded tokens and emits its OWN
%% hidden sequence, one vector per step, which the second reads in turn --
%% depth in time, the shape every serious sequence model uses. In
%% expressions the stack is two cells feeding: at every step the first
%% cell's new hidden state is the second cell's input, and the recursion
%% over the six steps threads FOUR states, a hidden and a cell state per
%% layer. The tutorial doubles as the persistence proof for recurrent
%% nets: an LSTM cell is twelve parameters -- input weights, recurrent
%% weights and a bias for each of four gates -- two cells are twenty-four,
%% the embedding and the head are three more, and ALL twenty-seven must
%% travel through params_save/2 and `params(Name)' for a stored network to
%% answer identically. The test loads the parameters back twice and
%% demands exactly that. An earlier version of this file spelled the same
%% network as model_new's sequence(6), embedding(8, 4), lstm(12), lstm(12),
%% dense(2, log_softmax); that layer API is still taught in
%% tutorials/library/22-torch.pl.
%%
%%   train    96 sequences, Adam, 300 steps over the whole batch; saved as t23_stack
%%   test     reload, accuracy over the 96 at 95% AND predictions identical to a
%%            second load -- the recurrent round trip
%%   predict  reload, probe a few sequences
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/23-stacked-lstm.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/23-stacked-lstm.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/23-stacked-lstm.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

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

rows_close([], []) :- !.
rows_close([A|As], [B|Bs]) :- row_close(A, B), rows_close(As, Bs), !.
row_close([], []) :- !.
row_close([A|As], [B|Bs]) :- D is abs(A - B), D < 1.0e-6, row_close(As, Bs), !.

%% ---- the network -------------------------------------------------------------
%% An embedding of [8, 4], two hidden states of 12, a head of two logits.

parameters(Ps) :-
    Emb := parameter(randn([8, 4]) * 0.5),
    cell_params(4, 12, Cell1), cell_params(12, 12, Cell2),
    Wd := parameter(glorot(12, 2)), Bd := parameter(zeros([1, 2])),
    append([[Emb], Cell1, Cell2, [Wd, Bd]], Ps), !.
cell_params(In, H, [Wi, Ui, Bi, Wf, Uf, Bf, Wo, Uo, Bo, Wg, Ug, Bg]) :-
    Wi := parameter(glorot(In, H)), Ui := parameter(glorot(H, H)), Bi := parameter(zeros([1, H])),
    Wf := parameter(glorot(In, H)), Uf := parameter(glorot(H, H)), Bf := parameter(zeros([1, H])),
    Wo := parameter(glorot(In, H)), Uo := parameter(glorot(H, H)), Bo := parameter(zeros([1, H])),
    Wg := parameter(glorot(In, H)), Ug := parameter(glorot(H, H)), Bg := parameter(zeros([1, H])), !.
unpack(Ps, Emb, Cell1, Cell2, Wd, Bd) :-
    length(Cell1, 12), length(Cell2, 12), append([[Emb], Cell1, Cell2, [Wd, Bd]], Ps), !.

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

%% scan(+Emb, +Cell1, +Cell2, +Ins, +H1, +C1, +H2, +C2, -HF): the sequence, a
%% step per index tensor -- the lookup, the first cell, and the second cell
%% reading the first's new hidden state -- threading both layers' states.
scan(_, _, _, [], _, _, H2, _, H2) --> [].
scan(Emb, Cell1, Cell2, [In|Ins], H1, C1, H2, C2, HF) -->
    X = index_rows(Emb, In),
    lstm(Cell1, X, H1, C1, H1b, C1b),
    lstm(Cell2, H1b, H2, C2, H2b, C2b),
    scan(Emb, Cell1, Cell2, Ins, H1b, C1b, H2b, C2b, HF).

%% forward(+Ps, +Ins, -Logits): six index tensors in, [N, 2] logits out.
forward(Ps, Ins, Logits) -->
    { unpack(Ps, Emb, Cell1, Cell2, Wd, Bd), Ins = [In0|_] },
    [N] = shape(In0),
    H10 = zeros([N, 12]), C10 = zeros([N, 12]),
    H20 = zeros([N, 12]), C20 = zeros([N, 12]),
    scan(Emb, Cell1, Cell2, Ins, H10, C10, H20, C20, H),
    Logits = H matmul Wd + Bd.

%% ---- the three goals -----------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(23),
    { tok_data(Rows, Labels) },
    steps(Rows, Ins), one_hot(Labels, 2, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(300, Ps0, St0, Ins, Y, Ps) },
    forward(Ps, Ins, Logits), accuracy(Logits, Labels, Acc),
    { format("trained: accuracy on the 96 sequences ~2f~n", [Acc]) },
    params_save(t23_stack, Ps),
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
    Ps = params(t23_stack),
    { tok_data(Rows, Labels) },
    steps(Rows, Ins),
    forward(Ps, Ins, Logits), accuracy(Logits, Labels, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("accuracy ~w%~n", [Pct]),
      ( Pct >= 95 -> true ; write('FAIL'), nl, halt(1) ) },
    % the recurrent round trip: a second load of the twenty-seven answers identically
    Ps2 = params(t23_stack),
    forward(Ps2, Ins, Logits2),
    R1 = list(Logits), R2 = list(Logits2),
    { ( rows_close(R1, R2)
      -> write('ok (and both loads answered identically)'), nl
      ;  write('FAIL stored lstm weights drifted'), nl, halt(1) ) }.

predict -->
    Ps = params(t23_stack),
    { Rows = [[1, 2, 3, 4, 5, 6], [6, 5, 4, 2, 1, 0]] },
    steps(Rows, Ins),
    forward(Ps, Ins, Logits),
    Picks = list(argmax(Logits, 1)),
    { forall(( nth0(I, Picks, Pk), nth0(I, Rows, Row) ),
             ( C is round(Pk),
               ( C =:= 1 -> V = 'contains token 3' ; V = 'no token 3' ),
               ( member(3, Row) -> Truth = 'contains token 3' ; Truth = 'no token 3' ),
               format("~w  ->  ~w  (truth: ~w)~n", [Row, V, Truth]) )) }.
