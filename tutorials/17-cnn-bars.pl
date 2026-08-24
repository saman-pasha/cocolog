%% 17. A first convolutional net: vertical or horizontal?
%%
%% 8x8 one-channel images of a single bright bar, vertical (class 0) or
%% horizontal (class 1), the bar's position wandering. A 3x3 convolution
%% learns an oriented edge detector, max-pool discards where the bar was
%% while keeping THAT it was, flatten hands the map to a dense head. The
%% input spec is image(1, 8, 8): the rows arrive flat (64 numbers) and the
%% module reshapes them itself.
%%
%%   train    learn the orientation, save as t17_cnn
%%   test     reload, accuracy at 95%
%%   predict  reload, classify one vertical and one horizontal bar

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

% An image row: 64 pixels, the bar at a wandering position, a little noise.
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

% A clean bar for predict: vertical (Kind 0) or horizontal (Kind 1) at Pos.
clean_bar(Kind, Pos, Row) :-
    findall(V, (between(0, 63, P),
                R is P // 8, C is P mod 8,
                ( Kind =:= 0 -> ( C =:= Pos -> V = 1.0 ; V = 0.0 )
                ;               ( R =:= Pos -> V = 1.0 ; V = 0.0 ) )), Row), !.

bars_data(X, Y) :-
    findall(R, (between(0, 71, I), img_row(I, 2, R, _)), XR),
    findall(L, (between(0, 71, I), img_row(I, 2, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y), !.

train :-
    torch_seed(17),
    bars_data(X, Y),
    model_new([image(1, 8, 8), conv(4, 3, relu), pool(2), flatten,
               dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(60), batch(12), lr(0.01), optimiser(adam),
                          loss(nll), final_loss(L)]),
    format("trained: final nll ~4f~n", [L]),
    model_save(t17_cnn, M),
    write(saved), nl.

test :-
    model_load(t17_cnn, M),
    bars_data(X, Y),
    model_evaluate(M, X, Y, accuracy, A),
    Pct is truncate(A * 100 + 0.5),
    format("accuracy ~w%~n", [Pct]),
    ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t17_cnn, M),
    clean_bar(0, 3, V), clean_bar(1, 5, H),
    tensor_from_list([V, H], X),
    model_predict(M, X, P),
    tensor_argmax(P, 1, AM),
    tensor_to_list(AM, [P1, P2]),
    C1 is truncate(P1), C2 is truncate(P2),
    format("a bar down column 3 -> class ~w (0 is vertical)~n", [C1]),
    format("a bar along row 5   -> class ~w (1 is horizontal)~n", [C2]).
