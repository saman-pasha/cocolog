%% 37. A GAN: two networks, and a loss each
%%
%% A generator turns noise into a point; a discriminator says whether a
%% point came from the data or from the generator; each is trained against
%% the other. The discriminator's loss is bce(D(real), 1) + bce(D(fake), 0);
%% the generator's is bce(D(fake), 1) -- it wants to be believed -- and the
%% gradient of that loss flows THROUGH the discriminator to the generator's
%% parameters, which is why `grad(L, Ps)' takes the list of parameters to
%% differentiate for: the same forward, two lists, two steps.
%%
%% The data are points on a ring of radius one, a little blurred. A GAN
%% has no held-out accuracy, so `test' asks the two things that can be
%% asked of samples: are they ON the ring, and are they ALL THE WAY ROUND
%% it -- a generator that collapses onto one arc fails the second. Tutorial
%% 40 learns the same ring by diffusion, in fifty steps instead of one;
%% `predict' here draws the samples, and there it draws them too.
%%
%% THE ONE SETTING THAT MATTERS: Adam's first moment at 0.5 for both players,
%% adam_init/3 with [beta1(0.5)]. At the default 0.9 the direction a player
%% remembers is a thousand rounds stale against an opponent that has moved,
%% and the generator collapses onto an arc; at 0.5 it forgets fast enough to
%% follow, and the ring closes.
%%
%%   train    256 real points a round, Adam on both at beta1 0.5, 5000 rounds; saved as t37_gan
%%   test     256 samples: at least 0.8 within 0.15 of the ring, at least 10 of 12 sectors reached
%%   predict  300 samples as a scatter, and the discriminator on a real and a fake point
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/37-gan.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/37-gan.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/37-gan.pl predict

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the ring ----------------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.

%% ring(+From, +N, -X): N points at angles the noise picks, radius 1 blurred by 0.05.
ring(From, N, X) :-
    To is From + N - 1,
    findall([Px, Py], ( between(From, To, I), noise(I, R1), A is R1 * 3.14159265, J is I + 7919, noise(J, R2), Rad is 1.0 + 0.05 * R2,
                        Px is Rad * cos(A), Py is Rad * sin(A) ), Rows),
    X := Rows, !.

%% on_ring(+Rows, -Fraction, -Sectors): how many of the points sit within
%% 0.15 of the ring, and how many of twelve 30-degree sectors hold one.
on_ring(Rows, Fraction, Sectors) :-
    length(Rows, N),
    findall(x, ( member([Px, Py], Rows), R is sqrt(Px * Px + Py * Py), abs(R - 1.0) < 0.15 ), Hits), length(Hits, H),
    Fraction is H / N,
    findall(S, ( member([Px, Py], Rows), angle(Px, Py, A), S is floor((A + 3.14159265) / 3.14159265 * 6) mod 12 ), Ss),
    sort(Ss, Distinct), length(Distinct, Sectors), !.

%% angle(+X, +Y, -A): the angle of (X, Y) in (-pi, pi], from acos and the sign of Y.
angle(X, Y, A) :- R is sqrt(X * X + Y * Y), ( R < 1.0e-9 -> A = 0.0 ; C is max(-1.0, min(1.0, X / R)), A0 is acos(C), ( Y >= 0 -> A = A0 ; A is -A0 ) ), !.

scatter(Rows) :-
    forall(between(0, 20, Row),
           ( write('   '),
             forall(between(0, 41, Col),
                    ( ( member([Px, Py], Rows), C is round((Px + 1.5) / 3.0 * 41), R is round((1.5 - Py) / 3.0 * 20), C =:= Col, R =:= Row -> write('o') ; write(' ') ) )),
             nl )), !.

%% ---- the two networks ---------------------------------------------------------------

generator([Wg1, Bg1, Wg2, Bg2, Wg3, Bg3]) :-
    Wg1 := parameter(glorot(2, 32)),  Bg1 := parameter(zeros([1, 32])),
    Wg2 := parameter(glorot(32, 32)), Bg2 := parameter(zeros([1, 32])),
    Wg3 := parameter(glorot(32, 2)),  Bg3 := parameter(zeros([1, 2])), !.
discriminator([Wd1, Bd1, Wd2, Bd2, Wd3, Bd3]) :-
    Wd1 := parameter(glorot(2, 32)),  Bd1 := parameter(zeros([1, 32])),
    Wd2 := parameter(glorot(32, 32)), Bd2 := parameter(zeros([1, 32])),
    Wd3 := parameter(glorot(32, 1)),  Bd3 := parameter(zeros([1, 1])), !.

%% generate//3 and judge//3 are PROCEDURES: DCG rules of bindings, run by proc/1,
%% which frees what they made but what the head returns.
generate([Wg1, Bg1, Wg2, Bg2, Wg3, Bg3], Z, Fake) -->
    Fake = relu(relu(Z matmul Wg1 + Bg1) matmul Wg2 + Bg2) matmul Wg3 + Bg3.
%% leaky units in the discriminator -- relu(h) - 0.2 relu(-h) -- so a unit
%% that is off still passes a gradient back to the generator
judge([Wd1, Bd1, Wd2, Bd2, Wd3, Bd3], X, P) -->
    H1 = X matmul Wd1 + Bd1, A1 = relu(H1) - relu(- H1) * 0.2,
    H2 = A1 matmul Wd2 + Bd2, A2 = relu(H2) - relu(- H2) * 0.2,
    P = sigmoid(A2 matmul Wd3 + Bd3).

%% ---- the three goals ---------------------------------------------------------------------

train :-
    torch_seed(37),
    generator(G0), discriminator(D0), adam_init(G0, [beta1(0.5)], SG0), adam_init(D0, [beta1(0.5)], SD0),
    rounds(5000, G0, D0, SG0, SD0, G, D),
    append(G, D, Ps), params_save(t37_gan, Ps),
    write(saved), nl.

%% one round: fresh real points and fresh noise, the discriminator's step on
%% real and fake, then the generator's step through the updated discriminator
rounds(0, G, D, _, _, G, D) :- !.
rounds(K, G, D, SG, SD, GF, DF) :-
    From is K * 256, ring(From, 256, X),
    Z := randn([256, 2]),
    proc(generate(G, Z, Fake)),
    proc(judge(D, X, PReal)), proc(judge(D, Fake, PFake)),
    Ld := bce(PReal, ones([256, 1])) + bce(PFake, zeros([256, 1])),
    GDs := grad(Ld, D), adam_step(D, GDs, SD, 0.0003, D2, SD2),
    proc(judge(D2, Fake, PFake2)),
    Lg := bce(PFake2, ones([256, 1])),
    GGs := grad(Lg, G), adam_step(G, GGs, SG, 0.0003, G2, SG2),
    ( K mod 1000 =:= 0 -> Ldv := item(Ld), Lgv := item(Lg), Rows := list(Fake), on_ring(Rows, Fr, Se),
                         format("   ~w rounds to go, D loss ~3f, G loss ~3f; of the fakes ~2f on the ring, ~w sectors~n", [K, Ldv, Lgv, Fr, Se]) ; true ),
    free_all([X, Z, Fake, PReal, PFake, Ld, PFake2, Lg]),
    K1 is K - 1,
    rounds(K1, G2, D2, SG2, SD2, GF, DF).

load(G, D) :- params_load(t37_gan, Ps), length(G, 6), append(G, D, Ps), !.

test :-
    torch_seed(1037),
    load(G, _),
    Z := randn([256, 2]), proc(generate(G, Z, Fake)), Rows := list(Fake),
    on_ring(Rows, Fraction, Sectors),
    format("test: 256 samples, ~2f within 0.15 of the ring, ~w of 12 sectors reached~n", [Fraction, Sectors]),
    ( Fraction >= 0.8, Sectors >= 10 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    torch_seed(2037),
    load(G, D),
    Z := randn([300, 2]), proc(generate(G, Z, Fake)), Rows := list(Fake),
    write('300 samples from the generator:'), nl, scatter(Rows), nl,
    ring(999999, 1, R), proc(judge(D, R, PR)), [[PRv]] := list(PR), [[Rx, Ry]] := list(R),
    Fake = Fake, Rows = [[Fx, Fy]|_], F1 := rows(Fake, 0, 1), proc(judge(D, F1, PF)), [[PFv]] := list(PF),
    format("   the discriminator gives a real point (~2f, ~2f) ~2f and a fake (~2f, ~2f) ~2f~n", [Rx, Ry, PRv, Fx, Fy, PFv]).
