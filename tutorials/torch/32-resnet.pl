%% 32. ResNet: residual blocks, as expressions
%%
%% A ResNet's idea in one line: a block answers its INPUT PLUS what it
%% learned to add, `relu(H + conv(relu(conv(H))))', so a deep stack starts
%% out as the identity and every block only has to learn a correction.
%% This file builds a small one -- a stem convolution, a residual block at
%% 8x8, a 2x2 pool, a residual block at 4x4, global average pooling and a
%% dense head -- and trains it to tell three shapes apart: a horizontal
%% bar, a vertical bar, a 3x3 square, each somewhere in a noisy 8x8 picture.
%%
%% THE LAYOUT IS PIXELS AS ROWS: a batch of N pictures with C channels is
%% one [N*64, C] tensor, and conv2d/3 from library(tensor_expr) is nine
%% shifted matmuls over it, with the shift matrices built once by shifts/3
%% and passed in. Nothing here is a layer of the torch module -- the whole
%% network is tensor expressions, and tensor_grad/3 differentiates it.
%%
%%   train    48 pictures, Adam, 80 steps; the parameters saved as t32_resnet
%%   test     30 fresh pictures, accuracy at least 0.9
%%   predict  three pictures drawn, with the class the network answers
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/32-resnet.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/32-resnet.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/32-resnet.pl predict

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the pictures ----------------------------------------------------------

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.
pick(I, Salt, N, P) :- J is I * 7 + Salt, noise(J, R), P is truncate(abs(R) * N), !.

%% picture(+I, -Class, -Pixels): the I-th picture, 64 values row-major.
picture(I, Class, Pixels) :-
    Class is I mod 3,
    pick(I, 11, 6, A), pick(I, 23, 6, B),
    findall(V, ( between(0, 63, P), Y is P // 8, X is P mod 8,
                 ( on(Class, A, B, Y, X) -> S = 0.9 ; S = 0.0 ),
                 J is I * 97 + P, noise(J, R), V is S + 0.15 * R ), Pixels), !.
on(0, A, _, Y, X) :- Y =:= A + 1, X >= 1, X =< 6.                   % a horizontal bar on row A+1
on(1, A, _, Y, X) :- X =:= A + 1, Y >= 1, Y =< 6.                   % a vertical bar on column A+1
on(2, A, B, Y, X) :- Y >= A, Y =< A + 2, X >= B, X =< B + 2.         % a 3x3 square at (A, B)

%% pictures(+From, +N, -X, -Classes): N pictures as one [N*64, 1] tensor.
pictures(From, N, X, Classes) :-
    To is From + N - 1,
    findall(C, ( between(From, To, I), picture(I, C, _) ), Classes),
    findall([V], ( between(From, To, I), picture(I, _, Ps), member(V, Ps) ), Rows),
    tensor_from_list(Rows, X), !.

draw(Pixels) :-
    forall(between(0, 7, Y),
           ( forall(between(0, 7, X), ( P is Y * 8 + X, nth0(P, Pixels, V), ( V > 0.5 -> write('#') ; write('.') ) )), nl )), !.

%% ---- the network -----------------------------------------------------------
%% EVERY PREDICATE HERE ENDS IN A CUT. A `run' consults this file into the
%% store, and the store keeps every consult, so the third process against it
%% holds three copies of each clause: a generator without a cut would answer
%% three times, and a batch would be three batches. The cut is the convention
%% every tutorial in this directory follows.

%% the constants every process builds once: the nine tap matrices at 8x8 and
%% at 4x4, and the pooling matrix
constants(c(S8, S4, P8)) :- shifts(8, 8, S8), shifts(4, 4, S4), pool_matrix(8, 8, P8), !.

parameters([K0, B0, K1a, B1a, K1b, B1b, K2a, B2a, K2b, B2b, Wd, Bd]) :-
    K0 := parameter(glorot(9, 8)),    B0 := parameter(zeros([1, 8])),
    K1a := parameter(glorot(72, 8)),  B1a := parameter(zeros([1, 8])),
    K1b := parameter(glorot(72, 8)),  B1b := parameter(zeros([1, 8])),
    K2a := parameter(glorot(72, 8)),  B2a := parameter(zeros([1, 8])),
    K2b := parameter(glorot(72, 8)),  B2b := parameter(zeros([1, 8])),
    Wd := parameter(glorot(8, 3)),    Bd := parameter(zeros([1, 3])), !.

%% forward(+Ps, +Constants, +X, -Logits): the network, top to bottom.
forward([K0, B0, K1a, B1a, K1b, B1b, K2a, B2a, K2b, B2b, Wd, Bd], c(S8, S4, P8), X, Logits) :-
    H0 := relu(conv2d(X, K0, S8) + B0),                                          % stem: 1 -> 8 channels
    H1 := relu(H0 + conv2d(relu(conv2d(H0, K1a, S8) + B1a), K1b, S8) + B1b),     % residual block at 8x8
    Pd := pool2(H1, P8),                                                          % 8x8 -> 4x4
    H2 := relu(Pd + conv2d(relu(conv2d(Pd, K2a, S4) + B2a), K2b, S4) + B2b),     % residual block at 4x4
    G := mean_rows(H2, 16),                                                       % global average pool: [N, 8]
    Logits := G matmul Wd + Bd,
    free_all([H0, H1, Pd, H2, G]), !.

%% ---- the three goals ------------------------------------------------------------

train :-
    torch_seed(32),
    constants(Cs),
    pictures(0, 48, X, Classes), one_hot(Classes, 3, Y),
    parameters(Ps0), adam_init(Ps0, St0),
    fit(80, Ps0, St0, Cs, X, Y, Ps),
    forward(Ps, Cs, X, Logits), accuracy(Logits, Classes, Acc), tensor_free(Logits),
    format("trained: accuracy on the 48 training pictures ~2f~n", [Acc]),
    params_save(t32_resnet, Ps),
    write(saved), nl.

fit(0, Ps, _, _, _, _, Ps) :- !.
fit(K, Ps, St, Cs, X, Y, PsF) :-
    forward(Ps, Cs, X, Logits),
    L := cross_entropy(Logits, Y),
    tensor_grad(L, Ps, Gs),
    ( K mod 20 =:= 0 -> tensor_item(L, Lv), format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Cs, X, Y, PsF).

test :-
    constants(Cs),
    params_load(t32_resnet, Ps),
    pictures(1000, 30, X, Classes),
    forward(Ps, Cs, X, Logits), accuracy(Logits, Classes, Acc),
    format("test accuracy ~2f on 30 fresh pictures~n", [Acc]),
    ( Acc >= 0.9 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    constants(Cs),
    params_load(t32_resnet, Ps),
    pictures(2000, 3, X, Classes),
    forward(Ps, Cs, X, Logits),
    tensor_argmax(Logits, 1, A), tensor_to_list(A, Got),
    forall(( nth0(I, Classes, C), nth0(I, Got, G) ),
           ( J is 2000 + I, picture(J, _, Pixels), draw(Pixels),
             name_of(C, CN), Gi is round(G), name_of(Gi, GN),
             format("   the network says ~w (it is ~w)~n~n", [GN, CN]) )).
name_of(0, 'a horizontal bar') :- !.
name_of(1, 'a vertical bar') :- !.
name_of(2, 'a square') :- !.
