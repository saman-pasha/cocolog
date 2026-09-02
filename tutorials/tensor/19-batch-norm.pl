%% 19. Batch normalisation, and the buffers that are not parameters
%%
%% norm after a conv is BatchNorm2d: it standardises each channel by the
%% BATCH's statistics while training, and by RUNNING statistics -- learned
%% by watching, not by gradient -- when the model answers for real. Those
%% running means and variances are buffers, not parameters, and the module
%% carries them through model_params, so a saved model normalises the same
%% way after model_load. This tutorial's test rides on exactly that: the
%% accuracy check happens in a fresh process, through the store, so a
%% dropped buffer would show up as a wrong answer here.
%%
%%   train    learn the bars through batch-norm, save as t19_bn
%%   test     reload (buffers included), accuracy at 95%
%%   predict  reload, classify clean bars

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

img_row(I, Classes, Row, L) :-
    L is I mod Classes,
    Pos is 1 + (I // Classes) mod 6,
    findall(V, (between(0, 63, P),
                R is P // 8, C is P mod 8,
                noise(I * 64 + P + 90000, E),
                ( L =:= 0 -> ( C =:= Pos -> V is 1 + 0.1 * E ; V is 0.1 * E )
                ; ( R =:= Pos -> V is 1 + 0.1 * E ; V is 0.1 * E ) )),
            Row), !.

bars_data(X, Y) :-
    findall(R, (between(0, 71, I), img_row(I, 2, R, _)), XR),
    findall(L, (between(0, 71, I), img_row(I, 2, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y), !.

train :-
    torch_seed(19),
    bars_data(X, Y),
    model_new([image(1, 8, 8), conv(4, 3, relu), norm, pool(2), flatten,
               dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(60), batch(12), lr(0.01), optimiser(adam),
                          loss(nll), final_loss(L)]),
    format("trained: final nll ~4f~n", [L]),
    model_save(t19_bn, M),
    write(saved), nl.

test :-
    model_load(t19_bn, M),
    bars_data(X, Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("accuracy ~w% (through stored running statistics)~n", [Pct]),
    ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t19_bn, M),
    findall(V, (between(0, 63, P), C is P mod 8,
                ( C =:= 4 -> V = 1.0 ; V = 0.0 )), Bar),
    tensor_from_list([Bar], X),
    model_predict(M, X, P),
    tensor_argmax(P, 1, AM),
    tensor_to_list(AM, [Pk]),
    C2 is truncate(Pk),
    format("a clean bar down column 4 -> class ~w (0 is vertical)~n", [C2]).
