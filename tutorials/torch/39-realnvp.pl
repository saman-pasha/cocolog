%% 39. RealNVP: a normalising flow, and the density it can state
%%
%% A flow is a network you can run BACKWARDS. Four affine coupling layers,
%% each leaving one coordinate alone and moving the other by a scale and a
%% shift that a small network computes FROM the coordinate left alone --
%% y2 = x2 * exp(s(x1)) + t(x1) -- so the inverse is immediate,
%% x2 = (y2 - t(x1)) * exp(-s(x1)), and the log-determinant of the
%% Jacobian is just the sum of the s values. The layers alternate which
%% coordinate they move. Dinh, Sohl-Dickstein and Bengio, 2016.
%%
%% Trained by maximum likelihood: push the data through to z, and ask that
%% z look standard normal, paying for the volume change along the way --
%% NLL = 0.5 |z|^2 + log 2pi - sum of the s's. Sampling is the inverse:
%% draw z, run the layers backwards. And unlike the GAN of tutorial 37 or
%% the diffusion of 40, this model can say how likely a point is.
%%
%% The data are two interleaving moons.
%%
%%   train    256 points, Adam, 1500 steps; saved as t39_realnvp
%%   test     on 256 fresh points, the flow's NLL must beat a Gaussian fitted to them by 0.5 nats
%%   predict  300 samples drawn backwards through the flow, as a scatter, and how many sit on a moon
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/39-realnvp.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/39-realnvp.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/39-realnvp.pl predict

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the moons ------------------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.

%% moon(+I, -Point): even I on the upper moon, odd on the lower, centred.
moon(I, [X, Y]) :-
    noise(I, R1), T is abs(R1) * 3.14159265, J is I + 7919, noise(J, R2), K is I + 104729, noise(K, R3),
    (   I mod 2 =:= 0
    ->  X is cos(T) - 0.5 + 0.06 * R2,       Y is sin(T) - 0.25 + 0.06 * R3
    ;   X is 0.5 - cos(T) + 0.06 * R2,       Y is 0.25 - sin(T) + 0.06 * R3 ), !.

moons(From, N, X) :-
    To is From + N - 1,
    findall(P, ( between(From, To, I), moon(I, P) ), Rows),
    X := Rows, !.

%% near_moon(+Point): within 0.15 of either moon's arc.
near_moon([X, Y]) :-
    DA is abs(sqrt((X + 0.5) * (X + 0.5) + (Y + 0.25) * (Y + 0.25)) - 1.0),
    DB is abs(sqrt((X - 0.5) * (X - 0.5) + (Y - 0.25) * (Y - 0.25)) - 1.0),
    ( ( Y >= -0.3, DA < 0.15 ) ; ( Y =< 0.3, DB < 0.15 ) ), !.

scatter(Rows) :-
    forall(between(0, 20, Row),
           ( write('   '),
             forall(between(0, 41, Col),
                    ( ( member([Px, Py], Rows), C is round((Px + 2.0) / 4.0 * 41), R is round((1.5 - Py) / 3.0 * 20), C =:= Col, R =:= Row -> write('o') ; write(' ') ) )),
             nl )), !.

%% ---- the flow ----------------------------------------------------------------------------
%% Four coupling layers of six tensors each: the conditioner's hidden layer,
%% and its two heads, s (through tanh, so the scale stays sane) and t.

layer([W1, B1, Ws, Bs, Wt, Bt]) :-
    W1 := parameter(glorot(1, 32)),  B1 := parameter(zeros([1, 32])),
    Ws := parameter(glorot(32, 1)),  Bs := parameter(zeros([1, 1])),
    Wt := parameter(glorot(32, 1)),  Bt := parameter(zeros([1, 1])), !.
parameters(Ps) :- layer(L0), layer(L1), layer(L2), layer(L3), append([L0, L1, L2, L3], Ps), !.
layers(Ps, [L0, L1, L2, L3]) :- length(L0, 6), length(L1, 6), length(L2, 6), length(L3, 6), append([L0, L1, L2, L3], Ps), !.

%% split(+K, +X, -Kept, -Moved) and join(+K, +Kept, +Moved, -Y): even layers
%% keep x1 and move x2, odd layers the other way round.
split(K, X, Kept, Moved) :- ( K mod 2 =:= 0 -> Kept := cols(X, 0, 1), Moved := cols(X, 1, 2) ; Kept := cols(X, 1, 2), Moved := cols(X, 0, 1) ), !.
join(K, Kept, Moved, Y)  :- ( K mod 2 =:= 0 -> Y := cat([Kept, Moved], 1) ; Y := cat([Moved, Kept], 1) ), !.

%% scale_shift(+Layer, +Kept, -S, -T): what the conditioner says about the kept coordinate.
scale_shift([W1, B1, Ws, Bs, Wt, Bt], Kept, S, T) :-
    H := tanh(Kept matmul W1 + B1),
    S := tanh(H matmul Ws + Bs), T := H matmul Wt + Bt,
    tensor_free(H), !.

%% forward(+Layers, +X, -Z, -LogDet): data to noise, and the log-determinant per point, [N, 1].
forward(Layers, X, Z, LogDet) :- forward(Layers, 0, X, none, Z, LogDet).
forward([], _, X, LD, X, LD) :- !.
forward([L|Ls], K, X, LD, Z, LogDet) :-
    split(K, X, Kept, Moved), scale_shift(L, Kept, S, T),
    Out := Moved * exp(S) + T,
    join(K, Kept, Out, Y),
    ( LD == none -> LD2 = S ; LD2 := LD + S, free_all([LD, S]) ),
    free_all([Kept, Moved, T, Out]), ( K > 0 -> tensor_free(X) ; true ),
    K1 is K + 1,
    forward(Ls, K1, Y, LD2, Z, LogDet).

%% inverse(+Layers, +Z, -X): noise to data, the layers in reverse.
inverse(Layers, Z, X) :- reverse(Layers, Rev), inverse(Rev, 3, Z, X).
inverse([], _, X, X) :- !.
inverse([L|Ls], K, Y, X) :-
    split(K, Y, Kept, Out), scale_shift(L, Kept, S, T),
    Moved := (Out - T) * exp(- S),
    join(K, Kept, Moved, Y2),
    free_all([Kept, Out, S, T, Moved]), ( K < 3 -> tensor_free(Y) ; true ),
    K1 is K - 1,
    inverse(Ls, K1, Y2, X).

%% nll(+Layers, +X, -L): the mean negative log-likelihood, a one-element tensor.
nll(Layers, X, L) :-
    forward(Layers, X, Z, LogDet),
    L := mean(row_sum(Z ^ 2.0) * 0.5 - LogDet) + 1.8378771,      % + log 2pi
    free_all([Z, LogDet]), !.

%% ---- the three goals ------------------------------------------------------------------------

train :-
    torch_seed(39),
    moons(0, 256, X),
    parameters(Ps0), adam_init(Ps0, St0),
    fit(1500, Ps0, St0, X, Ps),
    layers(Ps, Layers), nll(Layers, X, L), Lv := item(L),
    format("trained: NLL ~4f nats per point on the training moons~n", [Lv]),
    params_save(t39_realnvp, Ps),
    write(saved), nl.

fit(0, Ps, _, _, Ps) :- !.
fit(K, Ps, St, X, PsF) :-
    layers(Ps, Layers), nll(Layers, X, L),
    Gs := grad(L, Ps),
    ( K mod 300 =:= 0 -> Lv := item(L), format("   ~w steps to go, NLL ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.005, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, PsF).

%% gaussian_nll(+Rows, -G): the NLL of the best diagonal Gaussian for these
%% points -- the baseline any density model has to beat.
gaussian_nll(Rows, G) :-
    length(Rows, N),
    findall(X, member([X, _], Rows), Xs), findall(Y, member([_, Y], Rows), Ys),
    variance(Xs, N, Vx), variance(Ys, N, Vy),
    G is 0.5 * (log(2 * 3.14159265 * Vx) + 1) + 0.5 * (log(2 * 3.14159265 * Vy) + 1), !.
variance(Vs, N, Var) :- sum_list(Vs, S), M is S / N, findall(D, ( member(V, Vs), D is (V - M) * (V - M) ), Ds), sum_list(Ds, SD), Var is SD / N, !.

test :-
    params_load(t39_realnvp, Ps), layers(Ps, Layers),
    moons(1000, 256, X), nll(Layers, X, L), Lv := item(L),
    Rows := list(X), gaussian_nll(Rows, G),
    format("test: the flow's NLL ~4f against a fitted Gaussian's ~4f, on 256 fresh points~n", [Lv, G]),
    ( Lv =< G - 0.5 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    torch_seed(2039),
    params_load(t39_realnvp, Ps), layers(Ps, Layers),
    Z := randn([300, 2]), inverse(Layers, Z, X), Rows := list(X),
    write('300 points drawn from N(0, I) and run backwards through the flow:'), nl, scatter(Rows),
    findall(x, ( member(P, Rows), near_moon(P) ), Near), length(Near, Nn), Frac is Nn / 300,
    format("   ~2f of them within 0.15 of a moon~n", [Frac]),
    moons(3000, 2, Two), nll(Layers, Two, L2), L2v := item(L2), Far := [[1.5, 1.5], [-1.5, -1.5]], nll(Layers, Far, L3), L3v := item(L3),
    format("   and it can say how likely a point is: two on the moons at ~2f nats, two far away at ~2f~n", [L2v, L3v]).
