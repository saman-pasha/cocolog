%% 14. The 8-3-8 autoencoder
%%
%% The historical compression exercise: eight one-hot patterns squeezed
%% through a bottleneck of three units and reconstructed. Three tanh units
%% suffice IN PRINCIPLE (three bits name eight patterns), but the bare
%% 8->3->8 gets stuck in practice -- this file's own first draft plateaued
%% at rmse 0.25 -- and the classic remedy is a hidden layer either side of
%% the bottleneck, so the encoder and decoder each have room to work.
%% The target is the input itself: model_train(M, X, X, ...).
%%
%%   train    learn to reconstruct, save as t14_autoenc
%%   test     reload, reconstruction rmse under 0.15
%%   predict  reload, show a pattern beside its reconstruction

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

ae_row(I, Row) :-
    H is I mod 8,
    findall(V, (between(0, 7, J),
                noise(I * 8 + J, E),
                ( J =:= H -> V is 1 + 0.05 * E ; V is 0.05 * E )), Row), !.

ae_data(X) :-
    findall(R, (between(0, 127, I), ae_row(I, R)), XR),
    tensor_from_list(XR, X), !.

train :-
    torch_seed(14),
    ae_data(X),
    model_new([input(8), dense(8, tanh), dense(3, tanh), dense(8, tanh), dense(8)], M),
    model_train(M, X, X, [epochs(2000), batch(32), lr(0.01), optimiser(adam),
                          final_loss(L)]),
    format("trained: final mse ~4f~n", [L]),
    model_save(t14_autoenc, M),
    write(saved), nl.

test :-
    model_load(t14_autoenc, M),
    ae_data(X),
    model_evaluate(M, X, X, rmse, S),
    format("reconstruction rmse ~4f~n", [S]),
    ( S < 0.15 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t14_autoenc, M),
    % the clean pattern with the one at position 2, reconstructed
    tensor_from_list([[0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]], X),
    model_predict(M, X, P),
    tensor_to_list(P, [Out]),
    write('in :  [0, 0, 1, 0, 0, 0, 0, 0]'), nl,
    write('out:  '),
    forall(member(V, Out), format("~2f ", [V])), nl.
