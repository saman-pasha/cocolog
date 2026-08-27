%% 18. A mini LeNet: two convolutional stages, three classes
%%
%% The LeNet shape at toy scale: conv-pool-conv, then a dense hidden layer
%% and the classification head. The shape flows down the list and the
%% module checks it at model_new -- 8x8 through conv(3, pad 1) stays 8x8,
%% pool(2) halves it to 4x4, the second conv(3) unpadded leaves 2x2, and
%% flatten hands 8*2*2 = 32 features to the head. Get any of that wrong
%% and model_new refuses rather than letting libtorch fail deep inside.
%% Classes: a vertical bar, a horizontal bar, or a cross (both at once).
%%
%%   train    learn the three shapes, save as t18_lenet
%%   test     reload, accuracy at 95%
%%   predict  reload, name the shape in a clean image of each kind

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

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
                ; L =:= 1 -> ( R =:= Pos -> V is 1 + 0.1 * E ; V is 0.1 * E )
                ; ( ( C =:= Pos ; R =:= Pos ) -> V is 1 + 0.1 * E ; V is 0.1 * E ) )),
            Row), !.

clean_shape(Kind, Pos, Row) :-
    findall(V, (between(0, 63, P),
                R is P // 8, C is P mod 8,
                ( Kind =:= 0 -> ( C =:= Pos -> V = 1.0 ; V = 0.0 )
                ; Kind =:= 1 -> ( R =:= Pos -> V = 1.0 ; V = 0.0 )
                ; ( ( C =:= Pos ; R =:= Pos ) -> V = 1.0 ; V = 0.0 ) )), Row), !.

shape_name(0, 'a vertical bar').
shape_name(1, 'a horizontal bar').
shape_name(2, 'a cross').

shapes_data(X, Y) :-
    findall(R, (between(0, 89, I), img_row(I, 3, R, _)), XR),
    findall(L, (between(0, 89, I), img_row(I, 3, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y), !.

train :-
    torch_seed(18),
    shapes_data(X, Y),
    model_new([image(1, 8, 8),
               conv(4, 3, relu, pad(1)), pool(2),
               conv(8, 3, relu), flatten,
               dense(16, relu), dense(3, log_softmax)], M),
    model_train(M, X, Y, [epochs(80), batch(15), lr(0.01), optimiser(adam),
                          loss(nll), final_loss(L)]),
    format("trained: final nll ~4f~n", [L]),
    model_save(t18_lenet, M),
    write(saved), nl.

test :-
    model_load(t18_lenet, M),
    shapes_data(X, Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("accuracy ~w%~n", [Pct]),
    ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t18_lenet, M),
    clean_shape(0, 2, S0), clean_shape(1, 4, S1), clean_shape(2, 3, S2),
    tensor_from_list([S0, S1, S2], X),
    model_predict(M, X, P),
    tensor_argmax(P, 1, AM),
    tensor_to_list(AM, Picks),
    forall(( nth0(I, Picks, Pk), nth0(I, [0, 1, 2], Actual) ),
           ( C is truncate(Pk), shape_name(C, Name), shape_name(Actual, Real),
             format("shown ~w  ->  the net says ~w~n", [Real, Name]) )).
