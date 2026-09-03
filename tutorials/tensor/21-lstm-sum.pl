%% 21. An LSTM reads a sequence of plain numbers
%%
%% The first recurrent tutorial: eight numbers arrive ONE PER TIMESTEP --
%% column t of the [N, 8] batch is the input at step t -- and the LSTM's
%% final hidden state, having seen them all, hands a summary to a dense
%% head, which learns to report (a quarter of) their sum. A dense net over
%% the same flat row could learn this too; the LSTM's claim is that it does
%% it by ACCUMULATING, one step at a time, which is what makes it a machine
%% for order and memory rather than shape.
%%
%% The cell is written out. Four gates -- input, forget, output and the
%% candidate -- are each a sigmoid or a tanh of `x W + h U + b'; the cell
%% state is `f * c + i * g' and the hidden state `o * tanh(c)': six
%% bindings of a PROCEDURE, a DCG rule over the batch's rows at one
%% timestep. The sequence is a recursion over the eight steps threading the
%% hidden and cell states, the way tutorial 29 threads its parameters, and
%% the whole network is expressions: `Gs := grad(L, Ps)' differentiates
%% through all eight steps. An earlier version of this file spelled the
%% same network as model_new's sequence(8), lstm(16), dense(1); that layer
%% API is still taught in tutorials/library/22-torch.pl.
%%
%%   train    128 sequences, Adam over four batches of 32, 400 epochs; saved as t21_lstm_sum
%%   test     reload, rmse over the 128 under 0.1
%%   predict  reload, sum a couple of visible sequences
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/21-lstm-sum.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/21-lstm-sum.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/21-lstm-sum.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the sequences ----------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.

sum_row([], 0) :- !.
sum_row([V|Vs], S) :- sum_row(Vs, S0), S is S0 + V, !.

%% sq_row(+I, -Row, -Y): eight numbers in (-1, 1), and a quarter of their sum.
sq_row(I, Row, [Y]) :-
    findall(V, ( between(0, 7, J), noise(I * 8 + J + 60000, V) ), Row),
    sum_row(Row, S), Y is S / 4, !.

%% sq_data(-X, -Y): the 128 sequences as [128, 8], their sums as [128, 1].
sq_data(X, Y) -->
    { findall(R, ( between(0, 127, I), sq_row(I, R, _) ), XR),
      findall(R, ( between(0, 127, I), sq_row(I, _, R) ), YR) },
    X = XR, Y = YR, !.

%% ---- the network -------------------------------------------------------------
%% One input a step, a hidden state of 16, a dense head of one. The cell's
%% twelve parameters are three per gate: the input weights W, the recurrent
%% weights U, and a bias.

parameters(Ps) :-
    cell_params(1, 16, Cell),
    Wd := parameter(glorot(16, 1)), Bd := parameter(zeros([1, 1])),
    append(Cell, [Wd, Bd], Ps), !.
cell_params(In, H, [Wi, Ui, Bi, Wf, Uf, Bf, Wo, Uo, Bo, Wg, Ug, Bg]) :-
    Wi := parameter(glorot(In, H)), Ui := parameter(glorot(H, H)), Bi := parameter(zeros([1, H])),
    Wf := parameter(glorot(In, H)), Uf := parameter(glorot(H, H)), Bf := parameter(zeros([1, H])),
    Wo := parameter(glorot(In, H)), Uo := parameter(glorot(H, H)), Bo := parameter(zeros([1, H])),
    Wg := parameter(glorot(In, H)), Ug := parameter(glorot(H, H)), Bg := parameter(zeros([1, H])), !.
unpack(Ps, Cell, Wd, Bd) :- length(Cell, 12), append(Cell, [Wd, Bd], Ps), !.

%% lstm(+Cell, +X, +H, +C, -H2, -C2): one step over the batch's rows. Input,
%% forget and output gates, the candidate, the new cell state, the new
%% hidden state -- a PROCEDURE, a DCG rule of six bindings. Everything that
%% makes tensors from here down is one, and a procedure called inside
%% another threads what it made up to the caller; exec/1 at the top frees
%% all of it but what the head returns.
lstm([Wi, Ui, Bi, Wf, Uf, Bf, Wo, Uo, Bo, Wg, Ug, Bg], X, H, C, H2, C2) -->
    I = sigmoid(X matmul Wi + H matmul Ui + Bi),
    F = sigmoid(X matmul Wf + H matmul Uf + Bf),
    O = sigmoid(X matmul Wo + H matmul Uo + Bo),
    G = tanh(X matmul Wg + H matmul Ug + Bg),
    C2 = F * C + I * G,
    H2 = O * tanh(C2).

%% steps(+Cell, +X, +T, +H, +C, -HF): steps T to 7, column T of X the input
%% at step T; HF is the hidden state after the last one.
steps(_, _, 8, H, _, H) --> !.
steps(Cell, X, T, H, C, HF) -->
    { T1 is T + 1 },
    Xt = cols(X, T, T1),
    lstm(Cell, Xt, H, C, H2, C2),
    steps(Cell, X, T1, H2, C2, HF).

%% forward(+Ps, +X, -Pred): [N, 8] in, the final hidden state through the head, [N, 1] out.
forward(Ps, X, Pred) -->
    { unpack(Ps, Cell, Wd, Bd) },
    [N, _] = shape(X),
    H0 = zeros([N, 16]), C0 = zeros([N, 16]),
    steps(Cell, X, 0, H0, C0, H),
    Pred = H matmul Wd + Bd.

%% ---- the three goals -----------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the batches are a rule recursing over their number; the fit loop
%% stays a predicate in braces, since it steps an optimiser that frees the
%% old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

batches(4, _, _, []) --> !.
batches(B, X, Y, [b(Xb, Yb)|Bs]) -->
    { F is B * 32, T is F + 32 },
    Xb = rows(X, F, T), Yb = rows(Y, F, T),
    { B1 is B + 1 },
    batches(B1, X, Y, Bs).

train -->
    seed(21),
    sq_data(X, Y),
    batches(0, X, Y, Batches),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(1600, Ps0, St0, Batches, Ps) },
    forward(Ps, X, Pred),
    Rmse = item(sqrt(mse(Pred, Y))),
    { format("trained: rmse ~4f over the 128 sequences~n", [Rmse]) },
    params_save(t21_lstm_sum, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, Ps) :- !.
fit(K, Ps, St, Batches, PsF) :-
    B is K mod 4, nth0(B, Batches, b(X, Y)),
    exec(forward(Ps, X, Pred)),
    L := mse(Pred, Y),
    Gs := grad(L, Ps),
    ( K mod 400 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.02, Ps2, St2),
    free_all([Pred, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Batches, PsF).

test -->
    Ps = params(t21_lstm_sum),
    sq_data(X, Y),
    forward(Ps, X, Pred),
    Rmse = item(sqrt(mse(Pred, Y))),
    { format("rmse ~4f~n", [Rmse]),
      ( Rmse < 0.1 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    Ps = params(t21_lstm_sum),
    { Rows = [[0.5, 0.5, 0.5, 0.5, 0.0, 0.0, 0.0, 0.0],
              [0.25, -0.25, 0.25, -0.25, 0.25, -0.25, 0.25, -0.25]] },
    X = Rows,
    forward(Ps, X, Pred),
    Out = list(Pred),
    { forall(( nth0(I, Out, [Yhat]), nth0(I, Rows, Row) ),
             ( sum_row(Row, S), Truth is S / 4,
               format("sum/4 of ~w  predicted ~3f  (truth ~3f)~n", [Row, Yhat, Truth]) )) }.
