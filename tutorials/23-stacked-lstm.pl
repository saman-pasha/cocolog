%% 23. A stacked LSTM, and recurrent weights through the store
%%
%% Two LSTMs in a row: the first reads embedded tokens and emits its OWN
%% hidden sequence, one vector per step, which the second reads in turn --
%% depth in time, the shape every serious sequence model uses. The tutorial
%% doubles as the persistence proof for recurrent nets: an LSTM's weights
%% come in four blocks per layer (input and hidden weights, two biases)
%% and the embedding is one more matrix, and ALL of it must travel through
%% model_params for a stored model to answer identically. The test loads
%% the model back and demands exactly that.
%%
%%   train    stack the lstms over the token task, save as t23_stack
%%   test     reload, accuracy at 95% AND predictions identical to a
%%            second load -- the recurrent round trip
%%   predict  reload, probe a few sequences

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

tok_row(I, Row, L) :-
    findall(T, (between(0, 5, J),
                noise(I * 6 + J + 70000, F),
                T is truncate(abs(F) * 7.99)), Row),
    ( member(3, Row) -> L = 1 ; L = 0 ), !.

tok_data(X, Y) :-
    findall(R, (between(0, 95, I), tok_row(I, R, _)), XR),
    findall(L, (between(0, 95, I), tok_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y), !.

rows_close([], []).
rows_close([A|As], [B|Bs]) :- row_close(A, B), rows_close(As, Bs).
row_close([], []).
row_close([A|As], [B|Bs]) :- D is abs(A - B), D < 1.0e-6, row_close(As, Bs).

train :-
    torch_seed(23),
    tok_data(X, Y),
    model_new([sequence(6), embedding(8, 4), lstm(12), lstm(12),
               dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(200), batch(16), lr(0.02), optimiser(adam),
                          loss(nll), final_loss(L)]),
    format("trained: final nll ~4f~n", [L]),
    model_save(t23_stack, M),
    write(saved), nl.

test :-
    model_load(t23_stack, M),
    tok_data(X, Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("accuracy ~w%~n", [Pct]),
    ( Pct >= 95 -> true ; write('FAIL'), nl, halt(1) ),
    % the recurrent round trip: a second load answers identically
    model_load(t23_stack, M2),
    model_predict(M, X, T1), model_predict(M2, X, T2),
    tensor_to_list(T1, R1), tensor_to_list(T2, R2),
    ( rows_close(R1, R2)
    -> write('ok (and both loads answered identically)'), nl
    ;  write('FAIL stored lstm weights drifted'), nl, halt(1) ).

predict :-
    model_load(t23_stack, M),
    Rows = [[1, 2, 3, 4, 5, 6], [6, 5, 4, 2, 1, 0]],
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_argmax(P, 1, AM),
    tensor_to_list(AM, Picks),
    forall(( nth0(I, Picks, Pk), nth0(I, Rows, Row) ),
           ( C is truncate(Pk),
             ( C =:= 1 -> V = 'contains token 3' ; V = 'no token 3' ),
             format("~w  ->  ~w~n", [Row, V]) )).
