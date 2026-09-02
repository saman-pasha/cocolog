%% 40. A diffusion model: noise it fifty times, learn to take one step back
%%
%% DDPM, Ho, Jain and Abbeel, 2020. The forward process is fixed: at step t
%% a point is a blend of the data and Gaussian noise, x_t = sqrt(abar_t) x_0
%% + sqrt(1 - abar_t) eps, with abar_t falling from nearly 1 to nearly 0
%% over T = 50 steps. The network learns ONE thing: given x_t and t, what
%% was the noise eps. Its loss is mse(eps_predicted, eps), and that is the
%% whole of training. Sampling runs the schedule backwards from pure noise,
%% fifty times: subtract the predicted noise, scaled, add a little fresh
%% noise, and a ring appears.
%%
%% The same ring as the GAN of tutorial 37, so the two can be compared: a
%% GAN makes a sample in one pass and is trained against an adversary; a
%% diffusion model makes one in fifty passes and is trained by regression,
%% which is why it is the steadier of the two to train.
%%
%% The step t reaches the network as a LEARNED EMBEDDING, a row of a
%% [50, 8] table picked by index_rows/2; and the per-point schedule values
%% come the same way, from constant [50, 1] tables. Both are one expression.
%%
%%   train    256 points a step, Adam, 4000 steps; saved as t40_ddpm
%%   test     256 samples: at least 0.8 within 0.15 of the ring, at least 10 of 12 sectors reached
%%   predict  the sampling drawn at three moments: pure noise, halfway, and the end
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/40-ddpm.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/40-ddpm.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/40-ddpm.pl predict

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the ring, and the schedule ------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.

ring(From, N, X) -->
    { To is From + N - 1,
      findall([Px, Py], ( between(From, To, I), noise(I, R1), A is R1 * 3.14159265, J is I + 7919, noise(J, R2), Rad is 1.0 + 0.05 * R2,
                        Px is Rad * cos(A), Py is Rad * sin(A) ), Rows) },
    X = Rows, !.

angle(X, Y, A) :- R is sqrt(X * X + Y * Y), ( R < 1.0e-9 -> A = 0.0 ; C is max(-1.0, min(1.0, X / R)), A0 is acos(C), ( Y >= 0 -> A = A0 ; A is -A0 ) ), !.
on_ring(Rows, Fraction, Sectors) :-
    length(Rows, N),
    findall(x, ( member([Px, Py], Rows), R is sqrt(Px * Px + Py * Py), abs(R - 1.0) < 0.15 ), Hits), length(Hits, H),
    Fraction is H / N,
    findall(S, ( member([Px, Py], Rows), angle(Px, Py, A), S is floor((A + 3.14159265) / 3.14159265 * 6) mod 12 ), Ss),
    sort(Ss, Distinct), length(Distinct, Sectors), !.

scatter(Rows) :-
    forall(between(0, 20, Row),
           ( write('   '),
             forall(between(0, 41, Col),
                    ( ( member([Px, Py], Rows), C is round((Px + 2.0) / 4.0 * 41), R is round((2.0 - Py) / 4.0 * 20), C =:= Col, R =:= Row -> write('o') ; write(' ') ) )),
             nl )), !.

%% beta(+T, -B): linear from 0.001 to 0.2 over the fifty steps; alpha and
%% abar follow. abar_49 is about 0.006: by the last step the data are gone.
beta(T, B) :- B is 0.001 + (0.2 - 0.001) * T / 49, !.
alpha(T, A) :- beta(T, B), A is 1.0 - B, !.
abar(T, Ab) :- findall(A, ( between(0, T, S), alpha(S, A) ), As), product(As, Ab), !.
product([], 1.0).
product([A|As], P) :- product(As, P0), P is A * P0.

%% tables(-SA, -SOM): [50, 1] constants, sqrt(abar_t) and sqrt(1 - abar_t).
tables(SA, SOM) -->
    { findall([V], ( between(0, 49, T), abar(T, Ab), V is sqrt(Ab) ), L1),
      findall([V], ( between(0, 49, T), abar(T, Ab), V is sqrt(1.0 - Ab) ), L2) },
    SA = L1, SOM = L2, !.

%% ---- the network: eps from (x_t, t) ------------------------------------------------------

parameters([Temb, W1, B1, W2, B2, W3, B3]) :-
    Temb := parameter(randn([50, 8]) * 0.5),
    W1 := parameter(glorot(10, 128)), B1 := parameter(zeros([1, 128])),
    W2 := parameter(glorot(128, 128)), B2 := parameter(zeros([1, 128])),
    W3 := parameter(glorot(128, 2)),  B3 := parameter(zeros([1, 2])), !.

%% predict_noise(+Ps, +Xt, +TIds, -Eps): the point and its step's embedding,
%% side by side -- a PROCEDURE, a DCG rule of one binding, run by exec/1.
predict_noise([Temb, W1, B1, W2, B2, W3, B3], Xt, TIds, Eps) -->
    Eps = relu(relu(cat([Xt, index_rows(Temb, TIds)], 1) matmul W1 + B1) matmul W2 + B2) matmul W3 + B3.

%% ---- the three goals --------------------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop and the sampler stay predicates in braces, since one
%% steps an optimiser that frees the old parameters and the other frees as
%% it goes, fifty times.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    torch_seed(40),
    tables(SA, SOM),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(4000, Ps0, St0, SA, SOM, Ps) },
    params_save(t40_ddpm, Ps),
    { write(saved), nl }.

%% one step: fresh points, a step t for each, fresh noise, x_t by the
%% schedule, and the regression of the network's noise onto the real one
fit(0, Ps, _, _, _, Ps) :- !.
fit(K, Ps, St, SA, SOM, PsF) :-
    From is K * 256, exec(ring(From, 256, X0)),
    findall(T, ( between(1, 256, I), J is K * 1009 + I, noise(J, R), T is truncate(abs(R) * 50) ), Ts), TIds := Ts,
    Eps := randn([256, 2]),
    Xt := X0 * index_rows(SA, TIds) + Eps * index_rows(SOM, TIds),
    exec(predict_noise(Ps, Xt, TIds, Pred)),
    L := mse(Pred, Eps),
    Gs := grad(L, Ps),
    ( K mod 1000 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse of the predicted noise ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.001, Ps2, St2),
    free_all([X0, TIds, Eps, Xt, Pred, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, SA, SOM, PsF).

%% sample(+Ps, +N, +Watch, -X): N points from noise, the schedule run
%% backwards; Watch is a list of steps at which to draw the crowd.
sample(Ps, N, Watch, X) :-
    X49 := randn([N, 2]),
    ( member(49, Watch) -> write('   at t = 49, pure noise:'), nl, R49 := list(X49), scatter(R49) ; true ),
    unstep(49, Ps, N, Watch, X49, X), !.
unstep(-1, _, _, _, X, X) :- !.
unstep(T, Ps, N, Watch, Xt, X) :-
    findall(T, between(1, N, _), Ts), TIds := Ts,
    exec(predict_noise(Ps, Xt, TIds, Eps)),
    beta(T, B), alpha(T, A), abar(T, Ab),
    Coef is B / sqrt(1.0 - Ab), Inv is 1.0 / sqrt(A), Sigma is sqrt(B),
    (   T > 0
    ->  Xn := (Xt - Eps * Coef) * Inv + randn([N, 2]) * Sigma
    ;   Xn := (Xt - Eps * Coef) * Inv ),
    free_all([TIds, Eps, Xt]),
    ( member(T, Watch), T < 49 -> format("   at t = ~w:~n", [T]), Rows := list(Xn), scatter(Rows) ; true ),
    T1 is T - 1,
    unstep(T1, Ps, N, Watch, Xn, X).

test -->
    torch_seed(1040),
    params_load(t40_ddpm, Ps),
    { sample(Ps, 256, [], X) }, Rows = list(X),
    { on_ring(Rows, Fraction, Sectors),
      format("test: 256 samples, ~2f within 0.15 of the ring, ~w of 12 sectors reached~n", [Fraction, Sectors]),
      ( Fraction >= 0.8, Sectors >= 10 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    torch_seed(2040),
    params_load(t40_ddpm, Ps),
    { sample(Ps, 300, [49, 25, 0], _) }.
