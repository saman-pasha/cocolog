%% 7. XOR: the network that needs its hidden layer
%%
%% The historical one. No line separates xor's classes, so a single linear
%% unit CANNOT learn it -- the fact that stalled neural networks for a
%% generation -- and one small tanh layer settles it. The head is
%% dense(2, log_softmax) with loss(nll): two log-probabilities, integer
%% labels, the standard classification pairing.
%%
%%   train    learn xor from jittered corner points, save as t07_xor
%%   test     reload, the four CLEAN corners must all be right
%%   predict  reload, show the class and confidence at each corner

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

xor_point(I, [A, B], L) :-
    Q is I mod 4,
    ( Q =:= 0 -> A0 = 0, B0 = 0, L = 0
    ; Q =:= 1 -> A0 = 0, B0 = 1, L = 1
    ; Q =:= 2 -> A0 = 1, B0 = 0, L = 1
    ; A0 = 1, B0 = 1, L = 0 ),
    noise(I, E1), noise(I + 300, E2),
    A is A0 + 0.05 * E1, B is B0 + 0.05 * E2, !.

train :-
    torch_seed(7),
    findall(R, (between(0, 127, I), xor_point(I, R, _)), XR),
    findall(L, (between(0, 127, I), xor_point(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([input(2), dense(8, tanh), dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(400), batch(16), lr(0.05), optimiser(adam),
                          loss(nll), final_loss(L)]),
    format("trained: final nll ~4f~n", [L]),
    model_save(t07_xor, M),
    write(saved), nl.

test :-
    model_load(t07_xor, M),
    tensor_from_list([[0.0,0.0],[0.0,1.0],[1.0,0.0],[1.0,1.0]], X),
    tensor_from_list([0, 1, 1, 0], Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("corners right ~w%~n", [Pct]),
    ( Pct =:= 100 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t07_xor, M),
    Corners = [[0.0,0.0],[0.0,1.0],[1.0,0.0],[1.0,1.0]],
    tensor_from_list(Corners, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [L0, L1]), nth0(I, Corners, [A, B]) ),
           ( ( L1 > L0 -> C = 1, Conf is exp(L1) ; C = 0, Conf is exp(L0) ),
             format("xor(~0f, ~0f) = ~w  (confidence ~2f)~n", [A, B, C, Conf]) )).
