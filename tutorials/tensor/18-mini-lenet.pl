%% 18. A mini LeNet: two convolutional stages, three classes
%%
%% The LeNet shape at toy scale: conv-pool-conv-pool, then a dense hidden
%% layer and the classification head. Classes: a vertical bar, a
%% horizontal bar, or a cross (both at once). Written as expressions, THE
%% SHAPE FLOWS DOWN THE RULE and you can read it off beside each line --
%% pixels as rows, so a batch of N pictures is [N*64, 1]; conv2d/3 keeps
%% the size (zero padding, same as pad(1)) and changes only the channels,
%% [N*64, 4]; pool2/2 halves each side, [N*16, 4]; the second conv makes 8
%% channels at 4x4, [N*16, 8]; the second pool leaves 2x2, [N*4, 8]; and
%% reshape to [N, 32] is the flatten -- 8 channels times 2x2 = 32 features
%% for the head, exactly LeNet's arithmetic. Get any of it wrong and the
%% `:=' that binds the line refuses the shape, as tutorial 31 shows, rather
%% than letting a library fail deep inside.
%%
%% Nothing here is a layer: every stage is a matmul in the end -- nine of
%% them for a convolution, one against the matrix pool_matrix/3 builds for a
%% pool -- and `Gs := grad(L, Ps)' differentiates the whole thing.
%%
%% (An earlier version of this tutorial built the same net from model_new's
%% conv/pool/flatten/dense layers; library lesson 22-torch still teaches those.)
%%
%%   train    90 pictures, Adam, 100 steps; the parameters saved as t18_lenet
%%   test     90 fresh pictures, accuracy at least 95%
%%   predict  a clean picture of each kind, and the name the net gives it
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/18-mini-lenet.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/18-mini-lenet.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/18-mini-lenet.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the pictures ----------------------------------------------------------
%% Every predicate here ends in a cut: a `run' consults this file into the
%% store, the store keeps every consult, and a generator without a cut
%% would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

%% img_row(+I, +Classes, -Row, -L): the I-th picture, 64 pixels row-major,
%% a bar (or a cross) at a wandering position over a little noise; L its class.
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

%% clean_shape(+Kind, +Pos, -Row): a clean picture of each kind, for predict.
clean_shape(Kind, Pos, Row) :-
    findall(V, (between(0, 63, P),
                R is P // 8, C is P mod 8,
                ( Kind =:= 0 -> ( C =:= Pos -> V = 1.0 ; V = 0.0 )
                ; Kind =:= 1 -> ( R =:= Pos -> V = 1.0 ; V = 0.0 )
                ; ( ( C =:= Pos ; R =:= Pos ) -> V = 1.0 ; V = 0.0 ) )), Row), !.

shape_name(0, 'a vertical bar') :- !.
shape_name(1, 'a horizontal bar') :- !.
shape_name(2, 'a cross') :- !.

%% pictures(+From, +N, -X, -Classes): N pictures as one [N*64, 1] tensor,
%% pixels as rows, and their classes as a list.
pictures(From, N, X, Classes) -->
    { To is From + N - 1,
      findall(L, ( between(From, To, I), img_row(I, 3, _, L) ), Classes),
      findall([V], ( between(From, To, I), img_row(I, 3, Row, _), member(V, Row) ), Rows) },
    X = Rows, !.

draw(Pixels) :-
    forall(between(0, 7, Y),
           ( write('   '),
             forall(between(0, 7, X), ( P is Y * 8 + X, nth0(P, Pixels, V), ( V > 0.5 -> write('#') ; write('.') ) )), nl )), !.

%% ---- the network -----------------------------------------------------------

%% the constants every process builds once: the nine tap matrices at 8x8 and
%% at 4x4, and the two pooling matrices
constants(c(S8, S4, P8, P4)) --> shifts(8, 8, S8), shifts(4, 4, S4), pool_matrix(8, 8, P8), pool_matrix(4, 4, P4), !.

%% the parameters, stage by stage: a kernel is [9*Cin, Cout], the nine taps
%% stacked, and a bias is one row broadcast over every pixel
parameters([K1, B1, K2, B2, W1, C1, W2, C2]) :-
    K1 := parameter(glorot(9, 4)),    B1 := parameter(zeros([1, 4])),      % 1 -> 4 channels at 8x8
    K2 := parameter(glorot(36, 8)),   B2 := parameter(zeros([1, 8])),      % 4 -> 8 channels at 4x4
    W1 := parameter(glorot(32, 16)),  C1 := parameter(zeros([1, 16])),     % 32 features -> 16, the hidden layer
    W2 := parameter(glorot(16, 3)),   C2 := parameter(zeros([1, 3])), !.   % 16 -> 3 classes

%% forward(+Ps, +Constants, +N, +X, -Logits): the network, top to bottom,
%% with the shape of every stage beside it -- a PROCEDURE, a DCG rule of
%% bindings; exec/1 runs it and frees everything it made but Logits.
forward([K1, B1, K2, B2, W1, C1, W2, C2], c(S8, S4, P8, P4), N, X, Logits) -->
    H1 = relu(conv2d(X, K1, S8) + B1),        % [N*64, 4]  conv, 1 -> 4 channels, still 8x8
    P1 = pool2(H1, P8),                       % [N*16, 4]  pool, 8x8 -> 4x4
    H2 = relu(conv2d(P1, K2, S4) + B2),       % [N*16, 8]  conv, 4 -> 8 channels, still 4x4
    P2 = pool2(H2, P4),                       % [N*4, 8]   pool, 4x4 -> 2x2
    F = reshape(P2, [N, 32]),                 % [N, 32]    flatten: 8 channels times 2x2
    Hd = relu(F matmul W1 + C1),              % [N, 16]    the dense hidden layer
    Logits = Hd matmul W2 + C2.               % [N, 3]     the head

%% ---- the three goals ------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(18),
    constants(Cs),
    pictures(0, 90, X, Classes), one_hot(Classes, 3, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(100, Ps0, St0, Cs, 90, X, Y, Ps) },
    forward(Ps, Cs, 90, X, Logits), accuracy(Logits, Classes, Acc),
    { format("trained: accuracy on the 90 training pictures ~2f~n", [Acc]) },
    params_save(t18_lenet, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, _, _, _, Ps) :- !.
fit(K, Ps, St, Cs, N, X, Y, PsF) :-
    exec(forward(Ps, Cs, N, X, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 25 =:= 0 -> Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Cs, N, X, Y, PsF).

test -->
    constants(Cs),
    Ps = params(t18_lenet),
    pictures(1000, 90, X, Classes),
    forward(Ps, Cs, 90, X, Logits), accuracy(Logits, Classes, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("accuracy ~w% on 90 fresh pictures~n", [Pct]),
      ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    constants(Cs),
    Ps = params(t18_lenet),
    { clean_shape(0, 2, S0), clean_shape(1, 4, S1), clean_shape(2, 3, S2),
      findall([P], ( member(Row, [S0, S1, S2]), member(P, Row) ), Rows) },
    X = Rows,
    forward(Ps, Cs, 3, X, Logits),
    Picks = list(argmax(Logits, 1)),
    { forall(( nth0(I, [S0, S1, S2], Shown), nth0(I, Picks, Pk) ),
             ( draw(Shown), C is round(Pk), shape_name(C, Name), shape_name(I, Real),
               format("   shown ~w  ->  the net says ~w~n~n", [Real, Name]) )) }.
