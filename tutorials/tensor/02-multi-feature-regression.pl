%% 2. Regression over three features, with a held-out test set
%%
%% y = 2a - b + 0.5c + 1: three inputs, one output, and the tutorial habit
%% worth keeping -- the test rows are NEVER shown to the optimiser. The
%% network is the same one expression as tutorial 1 with a [3, 1] weight,
%%
%%     loss(X, Y, W, B) ::= mse(X matmul W + B, Y).
%%
%% the split is the answer form `Tr-Te = split(X, 96)', which cuts a tensor
%% into its first 96 rows and the rest, the optimiser is Adam -- adam_init/2
%% and adam_step/6 from library(tensor_expr), each step answering NEW
%% parameters -- and the judgment is rmse on the held-out fifth. An earlier
%% version of this file used model_new and model_train; that API is still
%% taught in tutorials/library/22-torch.pl.
%%
%%   train    fit on the first 96 of 120 rows, save the parameters as t02_multi
%%   test     reload, judge on the held-out 24, pass under 0.15
%%   predict  reload, answer for a few hand-picked feature rows
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/02-multi-feature-regression.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/02-multi-feature-regression.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/02-multi-feature-regression.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the data ---------------------------------------------------------------
%% Deterministic noise in (-1, 1), the sin-hash; every predicate ends in a
%% cut, since the store keeps every consult and a generator without one
%% would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

mlin_row(I, [A, B, C], [Y]) :-
    noise(I, A), noise(I + 1000, B), noise(I + 2000, C), noise(I + 3000, E),
    Y is 2 * A - B + 0.5 * C + 1 + 0.05 * E, !.

%% mlin_data(-X, -Y): all 120 rows as two tensors, [120, 3] and [120, 1].
mlin_data(X, Y) -->
    { findall(R, (between(0, 119, I), mlin_row(I, R, _)), XR),
      findall(R, (between(0, 119, I), mlin_row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the network ------------------------------------------------------------

loss(X, Y, W, B) ::= mse(X matmul W + B, Y).

%% a PREDICATE, not a rule: the optimiser frees these, and a rule must not
%% emit what something else frees.
parameters([W, B]) :-
    W := parameter(randn([3, 1])),
    B := parameter(zeros([1])), !.

%% ---- the three goals ----------------------------------------------------------
%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(2),
    mlin_data(X0, Y0),
    XTr-_ = split(X0, 96),                     % the first 96 rows train; the 24 behind them are never seen here
    YTr-_ = split(Y0, 96),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(300, Ps0, St0, XTr, YTr, [W, B]) },
    L = item(loss(XTr, YTr, W, B)),
    { format("trained: final mse ~4f~n", [L]) },
    params_save(t02_multi, [W, B]),
    { write(saved), nl }.

%% fit(+K, +Ps, +State, +X, +Y, -PsF): K full-batch steps of Adam at 0.05.
fit(0, Ps, _, _, _, Ps) :- !.
fit(K, [W, B], St, X, Y, PsF) :-
    L := loss(X, Y, W, B),
    Gs := grad(L, [W, B]),
    ( K mod 100 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~4f~n", [K, Lv]) ; true ),
    adam_step([W, B], Gs, St, 0.05, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    [W, B] = params(t02_multi),
    mlin_data(X0, Y0),
    _-XTe = split(X0, 96),                     % the held-out 24
    _-YTe = split(Y0, 96),
    S = item(sqrt(loss(XTe, YTe, W, B))),
    { format("held-out rmse ~4f~n", [S]),
      ( S < 0.15 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    [W, B] = params(t02_multi),
    { Rows = [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.5, -0.5, 1.0]] },
    Out = list(Rows matmul W + B),
    { forall(( nth0(I, Out, [Yhat]), nth0(I, Rows, [A, B2, C]) ),
             ( Truth is 2 * A - B2 + 0.5 * C + 1,
               format("f(~1f, ~1f, ~1f)  predicted ~2f  (law says ~2f)~n",
                      [A, B2, C, Yhat, Truth]) )) }.
