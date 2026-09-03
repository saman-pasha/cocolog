%% 17. A first convolutional net: vertical or horizontal?
%%
%% 8x8 one-channel pictures of a single bright bar, vertical (class 0) or
%% horizontal (class 1), the bar's position wandering. A 3x3 convolution
%% learns an oriented edge detector, a 2x2 pool discards WHERE the bar was
%% while keeping THAT it was, and a flatten hands the pooled map to a dense
%% head. Written as an EXPRESSION, the whole network is three lines:
%%
%%     H      = relu(conv2d(X, K, S8) + B)            a 3x3 convolution, 1 -> 4 channels
%%     Pd     = pool2(H, P8)                           2x2 average pooling, 8x8 -> 4x4
%%     Logits = reshape(Pd, [N, 64]) matmul Wd + Bd    flatten, and the dense head
%%
%% THE LAYOUT IS PIXELS AS ROWS: a batch of N pictures with C channels is
%% one [N*64, C] tensor, and conv2d/3 from library(tensor_expr) is nine
%% shifted matmuls over it -- one per tap of the 3x3 kernel, each through a
%% 0/1 matrix built once by shifts/3 that moves every pixel one step, and
%% zero padding is a row of that matrix with no 1 in it. pool2/2 is one
%% more matmul, with the matrix pool_matrix/3 builds. So a convolution is
%% nothing the grammar had to learn: it is matmuls, and `Gs := grad(L, Ps)'
%% differentiates it like any other expression.
%%
%% (An earlier version of this tutorial built the same net from model_new's
%% conv/pool/flatten layers; library lesson 22-torch still teaches those.)
%%
%%   train    72 pictures, Adam, 60 steps; the parameters saved as t17_cnn
%%   test     72 fresh pictures, accuracy at least 95%
%%   predict  a clean vertical bar and a clean horizontal bar, classified
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/17-cnn-bars.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/17-cnn-bars.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/17-cnn-bars.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the pictures ----------------------------------------------------------
%% EVERY PREDICATE HERE ENDS IN A CUT. A `run' consults this file into the
%% store, and the store keeps every consult, so the third process against it
%% holds three copies of each clause: a generator without a cut would answer
%% three times, and a batch would be three batches.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

%% img_row(+I, +Classes, -Row, -L): the I-th picture, 64 pixels row-major,
%% the bar at a wandering position, a little noise; L is its class.
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

%% clean_bar(+Kind, +Pos, -Row): a clean bar for predict, vertical (Kind 0)
%% or horizontal (Kind 1), at Pos.
clean_bar(Kind, Pos, Row) :-
    findall(V, (between(0, 63, P),
                R is P // 8, C is P mod 8,
                ( Kind =:= 0 -> ( C =:= Pos -> V = 1.0 ; V = 0.0 )
                ;               ( R =:= Pos -> V = 1.0 ; V = 0.0 ) )), Row), !.

%% pictures(+From, +N, -X, -Classes): N pictures as one [N*64, 1] tensor,
%% pixels as rows, and their classes as a list.
pictures(From, N, X, Classes) -->
    { To is From + N - 1,
      findall(L, ( between(From, To, I), img_row(I, 2, _, L) ), Classes),
      findall([V], ( between(From, To, I), img_row(I, 2, Row, _), member(V, Row) ), Rows) },
    X = Rows, !.

draw(Pixels) :-
    forall(between(0, 7, Y),
           ( write('   '),
             forall(between(0, 7, X), ( P is Y * 8 + X, nth0(P, Pixels, V), ( V > 0.5 -> write('#') ; write('.') ) )), nl )), !.

%% ---- the network -----------------------------------------------------------

%% the constants every process builds once: the nine tap matrices at 8x8,
%% and the pooling matrix
constants(c(S8, P8)) --> shifts(8, 8, S8), pool_matrix(8, 8, P8), !.

%% the parameters: a kernel of nine taps for 1 -> 4 channels and its bias,
%% and the dense head over the pooled 4x4 map's 4 channels -- 64 features
parameters([K, B, Wd, Bd]) :-
    K := parameter(glorot(9, 4)),    B := parameter(zeros([1, 4])),
    Wd := parameter(glorot(64, 2)),  Bd := parameter(zeros([1, 2])), !.

%% forward(+Ps, +Constants, +N, +X, -Logits): the network, top to bottom --
%% a PROCEDURE, a DCG rule of bindings; exec/1 runs it and frees everything
%% it made but Logits. N is the number of pictures in X, which the flatten
%% needs: the pooled map is [N*16, 4], pixels as rows, and read row-major
%% that is already each picture's 64 numbers one after the other.
forward([K, B, Wd, Bd], c(S8, P8), N, X, Logits) -->
    H = relu(conv2d(X, K, S8) + B),                    % [N*64, 4]  the convolution, 1 -> 4 channels
    Pd = pool2(H, P8),                                  % [N*16, 4]  8x8 -> 4x4
    Logits = reshape(Pd, [N, 64]) matmul Wd + Bd.       % [N, 2]     flatten, then the dense head

%% ---- the three goals ------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the constants, the pictures, the forward pass and the library's
%% predicates are nonterminals in them, and every tensor a goal makes is
%% freed when it ends. The fit loop stays a predicate, in braces: it steps an
%% optimiser, which frees the old parameters itself, and a rule must not
%% emit what something else frees.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(17),
    constants(Cs),
    pictures(0, 72, X, Classes), one_hot(Classes, 2, Y),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(60, Ps0, St0, Cs, 72, X, Y, Ps) },
    forward(Ps, Cs, 72, X, Logits), accuracy(Logits, Classes, Acc),
    { format("trained: accuracy on the 72 training pictures ~2f~n", [Acc]) },
    params_save(t17_cnn, Ps),
    { write(saved), nl }.

fit(0, Ps, _, _, _, _, _, Ps) :- !.
fit(K, Ps, St, Cs, N, X, Y, PsF) :-
    exec(forward(Ps, Cs, N, X, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    ( K mod 20 =:= 0 -> Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    free_all([Logits, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Cs, N, X, Y, PsF).

test -->
    constants(Cs),
    Ps = params(t17_cnn),
    pictures(1000, 72, X, Classes),
    forward(Ps, Cs, 72, X, Logits), accuracy(Logits, Classes, Acc),
    { Pct is truncate(Acc * 100 + 0.5),
      format("accuracy ~w% on 72 fresh pictures~n", [Pct]),
      ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    constants(Cs),
    Ps = params(t17_cnn),
    { clean_bar(0, 3, V), clean_bar(1, 5, H),
      findall([P], ( member(Row, [V, H]), member(P, Row) ), Rows) },
    X = Rows,
    forward(Ps, Cs, 2, X, Logits),
    [G1, G2] = list(argmax(Logits, 1)),
    { C1 is round(G1), C2 is round(G2),
      draw(V), format("a bar down column 3 -> class ~w (0 is vertical)~n~n", [C1]),
      draw(H), format("a bar along row 5   -> class ~w (1 is horizontal)~n", [C2]) }.
