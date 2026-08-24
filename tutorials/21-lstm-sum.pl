%% 21. An LSTM reads a sequence of plain numbers
%%
%% The first recurrent tutorial: eight numbers arrive ONE PER TIMESTEP --
%% sequence(8) reshapes each row to eight steps of one feature -- and the
%% LSTM's final hidden state, having seen them all, hands a summary to the
%% dense head, which learns to report (a quarter of) their sum. A dense
%% net over the same flat row could learn this too; the LSTM's claim is
%% that it does it by ACCUMULATING, one step at a time, which is what
%% makes it a machine for order and memory rather than shape.
%%
%%   train    learn to sum, save as t21_lstm_sum
%%   test     reload, rmse under 0.1
%%   predict  reload, sum a couple of visible sequences

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

sum_row([], 0).
sum_row([V|Vs], S) :- sum_row(Vs, S0), S is S0 + V.

sq_row(I, Row, [Y]) :-
    findall(V, (between(0, 7, J), noise(I * 8 + J + 60000, V)), Row),
    sum_row(Row, S), Y is S / 4, !.

sq_data(X, Y) :-
    findall(R, (between(0, 127, I), sq_row(I, R, _)), XR),
    findall(R, (between(0, 127, I), sq_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.

train :-
    torch_seed(21),
    sq_data(X, Y),
    model_new([sequence(8), lstm(16), dense(1)], M),
    model_train(M, X, Y, [epochs(400), batch(32), lr(0.02), optimiser(adam),
                          final_loss(L)]),
    format("trained: final mse ~4f~n", [L]),
    model_save(t21_lstm_sum, M),
    write(saved), nl.

test :-
    model_load(t21_lstm_sum, M),
    sq_data(X, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("rmse ~4f~n", [S]),
    ( S < 0.1 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t21_lstm_sum, M),
    Rows = [[0.5, 0.5, 0.5, 0.5, 0.0, 0.0, 0.0, 0.0],
            [0.25, -0.25, 0.25, -0.25, 0.25, -0.25, 0.25, -0.25]],
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [Yhat]), nth0(I, Rows, Row) ),
           ( sum_row(Row, S), Truth is S / 4,
             format("sum/4 of ~w  predicted ~3f  (truth ~3f)~n", [Row, Yhat, Truth]) )).
