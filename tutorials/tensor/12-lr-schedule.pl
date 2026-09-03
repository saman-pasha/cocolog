%% 12. A learning-rate schedule over plain sgd
%%
%% The rate is halved every 400 epochs: the big early steps find the
%% valley, the halved late ones settle into it. As expressions the schedule
%% is nothing but a Prolog predicate, `rate(Epoch, LR)', and the loop hands
%% its answer to sgd_step/4 -- there is no optimiser object to configure,
%% so a schedule is whatever arithmetic you like. The optimiser is
%% deliberately plain sgd; adam adapts its own rates and hides the
%% schedule's effect. A lesson this file keeps from its own tuning: sgd at
%% lr 0.3 on a TANH net diverged to NaN, where the same rate-family on this
%% relu net glides; activation and rate are a pair. (An earlier version of
%% this file was model_train's schedule(step, 400, 0.5) option;
%% tutorials/library/22-torch.pl still teaches that API.)
%%
%%   train    fit the bump under the decaying rate, 1500 epochs of five batches, save as t12_schedule
%%   test     reload, rmse under 0.1
%%   predict  reload, sample the fit
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/12-lr-schedule.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/12-lr-schedule.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/12-lr-schedule.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the bump -----------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

bump_row(I, [X], [Y]) :- X is -2 + 4 * I / 159, Y is exp(-4 * X * X), !.

%% bump(-X, -Y): the 160 rows on [-2, 2] as two [160, 1] tensors.
bump(X, Y) -->
    { findall(R, ( between(0, 159, I), bump_row(I, R, _) ), XR),
      findall(R, ( between(0, 159, I), bump_row(I, _, R) ), YR) },
    X = XR, Y = YR, !.

%% batches(+X, +Y, +From, -Bs): the rows from From on in batches of 32, as
%% Xb-Yb pairs -- a procedure, so the slices are freed by exec/1 when the
%% rule that made them ends.
batches(_, _, 160, []) --> !.
batches(X, Y, From, [Xb-Yb|Bs]) -->
    { To is From + 32 },
    Xb = rows(X, From, To), Yb = rows(Y, From, To),
    batches(X, Y, To, Bs).

%% ---- the schedule -------------------------------------------------------------
%% rate(+Epoch, -LR): 0.1, halved every 400 epochs. THIS IS THE SCHEDULE --
%% a predicate, called once per epoch, its answer handed to sgd_step/4.
rate(Epoch, LR) :- LR is 0.1 * 0.5 ** (Epoch // 400), !.

%% ---- the network --------------------------------------------------------------

parameters([W1, B1, W2, B2, W3, B3]) :-
    W1 := parameter(glorot(1, 24)),  B1 := parameter(zeros([1, 24])),
    W2 := parameter(glorot(24, 24)), B2 := parameter(zeros([1, 24])),
    W3 := parameter(glorot(24, 1)),  B3 := parameter(zeros([1, 1])), !.

%% forward(+Ps, +X, -P): two relu layers and a linear output -- a PROCEDURE,
%% a DCG rule of bindings; exec/1 runs it and frees H1 and H2.
forward([W1, B1, W2, B2, W3, B3], X, P) -->
    H1 = relu(X matmul W1 + B1),
    H2 = relu(H1 matmul W2 + B2),
    P = H2 matmul W3 + B3.

%% ---- the three goals ----------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls, so every tensor a goal makes is freed when it ends. The fit loop
%% stays a predicate in braces: it steps an optimiser, which frees the old
%% parameters itself, and a rule must not emit what something else frees.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(12),
    bump(X, Y), batches(X, Y, 0, Bs),
    { parameters(Ps0),
      fit(0, 1500, Ps0, Bs, Ps) },
    forward(Ps, X, P),
    L = item(mse(P, Y)),
    { format("trained: final mse ~6f~n", [L]) },
    params_save(t12_schedule, Ps),
    { write(saved), nl }.

%% fit(+Epoch, +Epochs, +Ps, +Bs, -PsF): an epoch is one pass over the
%% batches at the rate the schedule answers for it; each halving is printed.
fit(E, E, Ps, _, Ps) :- !.
fit(E, N, Ps, Bs, PsF) :-
    rate(E, LR),
    epoch(Bs, Ps, LR, Ps2, Loss),
    ( E mod 400 =:= 0 -> format("   epoch ~w  lr ~4f  mse ~6f~n", [E, LR, Loss]) ; true ),
    E1 is E + 1,
    fit(E1, N, Ps2, Bs, PsF).

%% epoch(+Bs, +Ps, +LR, -PsF, -Loss): one sgd step per batch; Loss is the
%% mean of the batches' losses, each read before its step.
epoch(Bs, Ps, LR, PsF, Loss) :- epoch(Bs, Ps, LR, PsF, 0.0, 0, Loss).
epoch([], Ps, _, Ps, Sum, N, Loss) :- !, Loss is Sum / N.
epoch([Xb-Yb|Bs], Ps, LR, PsF, Sum, N, Loss) :-
    exec(forward(Ps, Xb, P)),
    L := mse(P, Yb),
    Gs := grad(L, Ps),
    Lv := item(L),
    sgd_step(Ps, Gs, LR, Ps2),
    free_all([P, L]),
    Sum1 is Sum + Lv, N1 is N + 1,
    epoch(Bs, Ps2, LR, PsF, Sum1, N1, Loss).

test -->
    Ps = params(t12_schedule),
    bump(X, Y),
    forward(Ps, X, P),
    S = item(sqrt(mse(P, Y))),
    { format("rmse ~4f~n", [S]),
      ( S < 0.1 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    Ps = params(t12_schedule),
    { Points = [-1.5, -0.5, 0.0, 0.5, 1.5],
      findall([Xv], member(Xv, Points), Rows) },
    X = Rows,
    forward(Ps, X, P),
    Out = list(P),
    { forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
             ( Truth is exp(-4 * Xv * Xv),
               format("x ~2f  predicted ~3f  (bump says ~3f)~n", [Xv, Yhat, Truth]) )) }.
