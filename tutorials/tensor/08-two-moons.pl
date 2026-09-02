%% 8. Two moons: a curved boundary through one relu layer
%%
%% The scikit-learn classic: two interleaved half-circles that no line can
%% split. Sixteen relu units carve the crescent boundary; the head and
%% loss are the standard log_softmax + nll pairing.
%%
%%   train    learn the moons, save as t08_moons
%%   test     reload, accuracy over the two arcs, pass at 90%
%%   predict  reload, classify a point deep inside each moon

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

% First 80 rows walk the upper moon, the next 80 the lower, both jittered.
moon_row(I, [A, B], L) :-
    T is pi * (I mod 80) / 79,
    noise(I, E1), noise(I + 700, E2),
    ( I < 80
    -> L = 0, A is cos(T) + 0.1 * E1,      B is sin(T) + 0.1 * E2
    ;  L = 1, A is 1 - cos(T) + 0.1 * E1,  B is 0.4 - sin(T) + 0.1 * E2 ), !.

moon_data(X, Y) :-
    findall(R, (between(0, 159, I), moon_row(I, R, _)), XR),
    findall(L, (between(0, 159, I), moon_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y), !.

train :-
    torch_seed(8),
    moon_data(X, Y),
    model_new([input(2), dense(16, relu), dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(300), batch(32), lr(0.02), optimiser(adam),
                          loss(nll), final_loss(L)]),
    format("trained: final nll ~4f~n", [L]),
    model_save(t08_moons, M),
    write(saved), nl.

test :-
    model_load(t08_moons, M),
    moon_data(X, Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("accuracy ~w%~n", [Pct]),
    ( Pct >= 90 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t08_moons, M),
    Rows = [[0.0, 1.0], [1.0, -0.6], [-1.0, 0.0], [2.0, 0.4]],
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [L0, L1]), nth0(I, Rows, [A, B]) ),
           ( ( L1 > L0 -> C = lower ; C = upper ),
             format("(~2f, ~2f) is in the ~w moon~n", [A, B, C]) )).
