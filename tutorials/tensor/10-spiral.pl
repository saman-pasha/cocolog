%% 10. A three-arm spiral: depth, and raw logits under cross_entropy
%%
%% The spiral is the classic "you need depth" dataset: three interleaved
%% arms that a single hidden layer struggles to unwind. Two relu layers do
%% it comfortably. The head is BARE dense(3) -- raw logits -- because
%% loss(cross_entropy) applies its own log_softmax inside, exactly as
%% PyTorch's nn.CrossEntropyLoss does. Ending in log_softmax AND using
%% cross_entropy is the double-softmax mistake; this file is the reminder.
%%
%%   train    unwind the arms, save as t10_spiral
%%   test     reload, accuracy along the spiral, pass at 85%
%%   predict  reload, walk one arm outward and watch the class hold

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

spiral_row(I, [A, B], L) :-
    L is I mod 3,
    K is I // 3,
    T is 0.4 + 3.5 * K / 59,
    Phi is T + L * 2 * pi / 3,
    noise(I, E1), noise(I + 1100, E2),
    A is 0.25 * T * cos(Phi) + 0.02 * E1,
    B is 0.25 * T * sin(Phi) + 0.02 * E2, !.

spiral_data(X, Y) :-
    findall(R, (between(0, 179, I), spiral_row(I, R, _)), XR),
    findall(L, (between(0, 179, I), spiral_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y), !.

train :-
    torch_seed(10),
    spiral_data(X, Y),
    model_new([input(2), dense(32, relu), dense(32, relu), dense(3)], M),
    model_train(M, X, Y, [epochs(600), batch(32), lr(0.01), optimiser(adam),
                          loss(cross_entropy), final_loss(L)]),
    format("trained: final ce ~4f~n", [L]),
    model_save(t10_spiral, M),
    write(saved), nl.

test :-
    model_load(t10_spiral, M),
    spiral_data(X, Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("accuracy ~w%~n", [Pct]),
    ( Pct >= 85 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t10_spiral, M),
    % five points outward along arm 0
    findall([A, B], (member(T, [0.5, 1.2, 2.0, 2.8, 3.6]),
                     A is 0.25 * T * cos(T), B is 0.25 * T * sin(T)), Rows),
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_argmax(P, 1, AM),
    tensor_to_list(AM, Picks),
    forall(( nth0(I, Picks, Pk), nth0(I, Rows, [A, B]) ),
           ( C is truncate(Pk),
             format("(~2f, ~2f) on arm ~w~n", [A, B, C]) )).
