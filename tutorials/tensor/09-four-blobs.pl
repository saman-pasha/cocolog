%% 9. Four blobs: multiclass classification
%%
%% One gaussian cloud per corner of the plane, four classes, and the
%% multiclass pairing in its plainest form: a dense(4, log_softmax) head,
%% loss(nll), integer labels 0..3, and the accuracy metric's argmax across
%% the four columns.
%%
%%   train    learn the corners, save as t09_blobs
%%   test     reload, accuracy over the clouds, pass at 95%
%%   predict  reload, name the corner for a few points

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

blob_row(I, [A, B], L) :-
    L is I mod 4,
    ( L =:= 0 -> CA = -1, CB = -1 ; L =:= 1 -> CA = -1, CB = 1
    ; L =:= 2 -> CA = 1,  CB = -1 ; CA = 1,  CB = 1 ),
    noise(I, E1), noise(I + 900, E2),
    A is CA + 0.3 * E1, B is CB + 0.3 * E2, !.

blob_data(X, Y) :-
    findall(R, (between(0, 159, I), blob_row(I, R, _)), XR),
    findall(L, (between(0, 159, I), blob_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y), !.

corner_name(0, 'south-west'). corner_name(1, 'north-west').
corner_name(2, 'south-east'). corner_name(3, 'north-east').

train :-
    torch_seed(9),
    blob_data(X, Y),
    model_new([input(2), dense(16, relu), dense(4, log_softmax)], M),
    model_train(M, X, Y, [epochs(300), batch(32), lr(0.02), optimiser(adam),
                          loss(nll), final_loss(L)]),
    format("trained: final nll ~4f~n", [L]),
    model_save(t09_blobs, M),
    write(saved), nl.

test :-
    model_load(t09_blobs, M),
    blob_data(X, Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("accuracy ~w%~n", [Pct]),
    ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t09_blobs, M),
    Rows = [[-1.0, -1.0], [-0.8, 1.1], [1.2, -0.9], [0.9, 0.9]],
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_argmax(P, 1, AM),
    tensor_to_list(AM, Picks),
    forall(( nth0(I, Picks, Pk), nth0(I, Rows, [A, B]) ),
           ( C is truncate(Pk), corner_name(C, Name),
             format("(~1f, ~1f) belongs to the ~w blob~n", [A, B, Name]) )).
