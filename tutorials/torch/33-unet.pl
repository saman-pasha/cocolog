%% 33. U-Net: an encoder, a decoder, and the skip between them
%%
%% Segmentation: every pixel gets an answer. A U-Net goes DOWN -- convolve,
%% pool, convolve at half the size -- and comes back UP -- upsample,
%% convolve -- and the thing that makes it a U is the skip connection: the
%% upsampled features are concatenated with the encoder's features at the
%% same size, so the decoder sees both what the bottleneck understood and
%% where the edges were. This one is two levels deep, 8x8 down to 4x4, and
%% learns to mask a bright rectangle of random size and place out of noise.
%%
%% Pixels are rows: a batch of N pictures is [N*64, C], conv2d/3 is nine
%% shifted matmuls, pool2/2 and up2/2 are one matmul each with a constant
%% built by pool_matrix/3 and up_matrix/3, and cat/2 along dimension 1 is
%% the skip. The output is a sigmoid per pixel and the loss is bce/2.
%%
%%   train    32 pictures, Adam, 100 steps; saved as t33_unet
%%   test     16 fresh pictures, mean IoU of the thresholded mask at least 0.8
%%   predict  two pictures: the input, the truth, the network's mask
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/33-unet.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/33-unet.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/33-unet.pl predict

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the pictures and their masks -------------------------------------------
%% Every predicate here ends in a cut: a `run' consults this file into the
%% store, the store keeps every consult, and a generator without a cut
%% would answer once per copy.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.
pick(I, Salt, N, P) :- J is I * 7 + Salt, noise(J, R), P is truncate(abs(R) * N), !.

%% picture(+I, -Pixels, -Mask): a rectangle 2-4 wide and 2-4 tall somewhere
%% in the 8x8, at a brightness of 0.6 to 1.0, over noise of amplitude 0.3.
picture(I, Pixels, Mask) :-
    pick(I, 11, 3, W0), W is W0 + 2, pick(I, 23, 3, H0), H is H0 + 2,
    pick(I, 37, 7, X0), X1 is min(X0, 8 - W), pick(I, 41, 7, Y0), Y1 is min(Y0, 8 - H),
    pick(I, 53, 5, B0), Bright is 0.6 + 0.1 * B0,
    findall(V-M, ( between(0, 63, P), Y is P // 8, X is P mod 8,
                   ( Y >= Y1, Y < Y1 + H, X >= X1, X < X1 + W -> M = 1.0 ; M = 0.0 ),
                   J is I * 97 + P, noise(J, R), V is M * Bright + 0.3 * R ), Pairs),
    findall(V, member(V-_, Pairs), Pixels), findall(M, member(_-M, Pairs), Mask), !.

%% pictures(+From, +N, -X, -Y): the inputs as [N*64, 1], the masks likewise.
pictures(From, N, X, Y) :-
    To is From + N - 1,
    findall([V], ( between(From, To, I), picture(I, Ps, _), member(V, Ps) ), XR),
    findall([M], ( between(From, To, I), picture(I, _, Ms), member(M, Ms) ), YR),
    X := XR, Y := YR, !.

draw(Title, Values, Threshold) :-
    format("   ~w~n", [Title]),
    forall(between(0, 7, Yy),
           ( write('   '),
             forall(between(0, 7, Xx), ( P is Yy * 8 + Xx, nth0(P, Values, V), ( V > Threshold -> write('#') ; write('.') ) )), nl )), !.

%% ---- the network ---------------------------------------------------------------

constants(c(S8, S4, P8, U8)) :- shifts(8, 8, S8), shifts(4, 4, S4), pool_matrix(8, 8, P8), up_matrix(8, 8, U8), !.

parameters([K1, B1, K2, B2, K3, B3, K4, B4, K5, B5]) :-
    K1 := parameter(glorot(9, 4)),    B1 := parameter(zeros([1, 4])),     % 1 -> 4 at 8x8
    K2 := parameter(glorot(36, 4)),   B2 := parameter(zeros([1, 4])),     % 4 -> 4 at 8x8
    K3 := parameter(glorot(36, 8)),   B3 := parameter(zeros([1, 8])),     % 4 -> 8 at 4x4, the bottleneck
    K4 := parameter(glorot(108, 4)),  B4 := parameter(zeros([1, 4])),     % 8 + 4 -> 4 at 8x8, after the skip
    K5 := parameter(glorot(36, 1)),   B5 := parameter(zeros([1, 1])), !.  % 4 -> 1, the mask

%% forward(+Ps, +Constants, +X, -Out): down, across, and up with the skip --
%% a PROCEDURE, a DCG rule of bindings; proc/1 runs it and frees everything
%% it made but Out.
forward([K1, B1, K2, B2, K3, B3, K4, B4, K5, B5], c(S8, S4, P8, U8), X, Out) -->
    E1 = relu(conv2d(X, K1, S8) + B1),                 % [N*64, 4]   encoder, level 1
    E2 = relu(conv2d(E1, K2, S8) + B2),                % [N*64, 4]
    Pd = pool2(E2, P8),                                % [N*16, 4]   down
    Bn = relu(conv2d(Pd, K3, S4) + B3),                % [N*16, 8]   the bottleneck, at 4x4
    Up = up2(Bn, U8),                                  % [N*64, 8]   up
    Sk = cat([Up, E2], 1),                             % [N*64, 12]  THE SKIP: what came up, beside what was there
    D1 = relu(conv2d(Sk, K4, S8) + B4),                % [N*64, 4]   decoder
    Out = sigmoid(conv2d(D1, K5, S8) + B5).            % [N*64, 1]   a probability per pixel

%% ---- the three goals -------------------------------------------------------------

train :-
    torch_seed(33),
    constants(Cs),
    pictures(0, 32, X, Y),
    parameters(Ps0), adam_init(Ps0, St0),
    fit(100, Ps0, St0, Cs, X, Y, Ps),
    iou(Ps, Cs, X, Y, IoU),
    format("trained: mean IoU on the 32 training pictures ~3f~n", [IoU]),
    params_save(t33_unet, Ps),
    write(saved), nl.

fit(0, Ps, _, _, _, _, Ps) :- !.
fit(K, Ps, St, Cs, X, Y, PsF) :-
    proc(forward(Ps, Cs, X, Out)),
    L := bce(Out, Y),
    Gs := grad(L, Ps),
    ( K mod 25 =:= 0 -> Lv := item(L), format("   ~w steps to go, bce ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    free_all([Out, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Cs, X, Y, PsF).

%% iou(+Ps, +Cs, +X, +Y, -IoU): the mask thresholded at 0.5 against the
%% truth, intersection over union, averaged over the pictures.
iou(Ps, Cs, X, Y, IoU) :-
    proc(forward(Ps, Cs, X, Out)),
    OL := list(Out), YL := list(Y), tensor_free(Out),
    findall(P-T, ( nth0(I, OL, [P]), nth0(I, YL, [T]) ), Pairs),
    length(Pairs, Len), N is Len // 64,
    findall(S, ( between(0, N, Pi), Pi < N, From is Pi * 64, To is From + 63,
                 findall(x, ( between(From, To, Q), nth0(Q, Pairs, P-T), ( P > 0.5 -> true ; T > 0.5 ) ), U), length(U, Un),
                 findall(x, ( between(From, To, Q), nth0(Q, Pairs, P-T), P > 0.5, T > 0.5 ), In), length(In, Inn),
                 ( Un =:= 0 -> S = 1.0 ; S is Inn / Un ) ), Ss),
    sum_list(Ss, Sum), IoU is Sum / N, !.

test :-
    constants(Cs),
    params_load(t33_unet, Ps),
    pictures(1000, 16, X, Y),
    iou(Ps, Cs, X, Y, IoU),
    format("test mean IoU ~3f on 16 fresh pictures~n", [IoU]),
    ( IoU >= 0.8 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    constants(Cs),
    params_load(t33_unet, Ps),
    pictures(2000, 2, X, _),
    proc(forward(Ps, Cs, X, Out)),
    OL := list(Out),
    forall(between(0, 1, I),
           ( J is 2000 + I, picture(J, Pixels, Mask),
             From is I * 64, To is From + 63,
             findall(P, ( between(From, To, Q), nth0(Q, OL, [P]) ), Got),
             draw('the picture', Pixels, 0.45), draw('the truth', Mask, 0.5), draw('the network', Got, 0.5), nl )).
