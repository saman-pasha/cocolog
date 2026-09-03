%% 13. Outliers in training, judged by mean absolute error
%%
%% Every tenth training target is shoved six units off the line -- the
%% corrupted-labels setup. Mean squared error SQUARES those misses, so a
%% fit by mse is dragged toward them: twelve misses of six among 120 rows
%% lift the line by their share, 0.6, and the honest judgment on clean
%% data -- the mean absolute error, which weighs every miss linearly --
%% says exactly that. A fit BY mae is not dragged at all: the same line,
%% the same data, and the loss is the only difference. Each loss is one
%% expression, a DEFINED FUNCTION used by name:
%%
%%     mse_loss(X, Y, W, B) ::= mean((line(X, W, B) - Y) ^ 2.0).
%%     mae_loss(X, Y, W, B) ::= mean(abs(line(X, W, B) - Y)).
%%
%% `train' fits the line by each in turn, prints the clean mae of each --
%% about 0.6, then a few hundredths -- and saves the second. The point is
%% the measure, twice over: the loss you fit by decides what the outliers
%% can do to you, and the metric you judge by decides whether you notice.
%% (An earlier version of this file fitted by mse through the torch
%% module's model_train and judged by mae; that fit passed the threshold
%% below by two thousandths.)
%%
%%   train    fit the line by mse, then by mae, through the outliers; save the mae fit as t13_mae
%%   test     reload, mae against the CLEAN line, pass under 0.6
%%   predict  reload, compare a few answers with the clean law
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/13-robust-mae.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/13-robust-mae.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/13-robust-mae.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the data ---------------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a generator without a cut would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

out_row(I, [X], [Y]) :-
    X is -1 + 2 * I / 119,
    noise(I, E),
    Y0 is 2 * X + 1 + 0.05 * E,
    ( I mod 10 =:= 0 -> Y is Y0 + 6 ; Y = Y0 ), !.

clean_row(I, [X], [Y]) :- X is -1 + 2 * I / 39, Y is 2 * X + 1, !.

%% training(-X, -Y): the 120 rows with the outliers in them; clean(-X, -Y):
%% 40 rows of the law itself. Each side a [N, 1] tensor.
training(X, Y) -->
    { findall(R, (between(0, 119, I), out_row(I, R, _)), XR),
      findall(R, (between(0, 119, I), out_row(I, _, R)), YR) },
    X = XR, Y = YR, !.
clean(X, Y) -->
    { findall(R, (between(0, 39, I), clean_row(I, R, _)), XR),
      findall(R, (between(0, 39, I), clean_row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the line, and the two ways to judge it ------------------------------------------
%% DEFINED FUNCTIONS: a clause `Head ::= Body', used by name in any
%% expression, the way the two losses use the line.

line(X, W, B) ::= X matmul W + B.
mse_loss(X, Y, W, B) ::= mean((line(X, W, B) - Y) ^ 2.0).
mae_loss(X, Y, W, B) ::= mean(abs(line(X, W, B) - Y)).

parameters(W, B) :- W := parameter(randn([1, 1])), B := parameter(zeros([1, 1])), !.

%% fit(+Loss, +K, +X, +Y, +W, +B, -WF, -BF): K steps of Adam on the loss
%% NAMED -- mse_loss or mae_loss, built as a term from its name and run
%% through `:='. A predicate, not a rule: adam_step frees the old
%% parameters itself, and a rule must not emit what something else frees.
fit(Loss, K, X, Y, W, B, WF, BF) :-
    adam_init([W, B], St),
    fit(Loss, K, X, Y, [W, B], St, [WF, BF]), !.
fit(_, 0, _, _, Ps, _, Ps) :- !.
fit(Loss, K, X, Y, [W, B], St, PsF) :-
    E =.. [Loss, X, Y, W, B], L := E,
    Gs := grad(L, [W, B]),
    ( K mod 100 =:= 0 -> Lv := item(L), format("   ~w: ~w steps to go, loss ~4f~n", [Loss, K, Lv]) ; true ),
    adam_step([W, B], Gs, St, 0.05, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(Loss, K1, X, Y, Ps2, St2, PsF).

%% ---- the three goals ---------------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls: the data, the measures and params_save are nonterminals in them,
%% and every tensor a goal makes is freed when it ends. The fits stay in
%% braces, since they step an optimiser.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(13),
    training(X, Y), clean(Xc, Yc),
    { parameters(W0, B0), fit(mse_loss, 300, X, Y, W0, B0, Wm, Bm) },
    Dm = item(mae_loss(Xc, Yc, Wm, Bm)),
    { format("fit by mse: clean mae ~4f -- lifted by the outliers' share~n", [Dm]),
      parameters(W1, B1), fit(mae_loss, 300, X, Y, W1, B1, Wa, Ba) },
    Da = item(mae_loss(Xc, Yc, Wa, Ba)),
    { format("fit by mae: clean mae ~4f~n", [Da]) },
    params_save(t13_mae, [Wa, Ba]),
    { write(saved), nl }.

test -->
    [W, B] = params(t13_mae),
    clean(X, Y),
    S = item(mae_loss(X, Y, W, B)),                          % judged by the measure that matches the question
    { format("clean mae ~4f~n", [S]),
      ( S < 0.6 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    [W, B] = params(t13_mae),
    [[Wv]] = list(W), [[Bv]] = list(B),
    { format("the line found: y = ~3f x + ~3f  (the clean law is y = 2 x + 1)~n", [Wv, Bv]),
      Points = [-1.0, 0.0, 1.0], findall([Xv], member(Xv, Points), Rows) },
    Out = list(line(Rows, W, B)),
    { forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
             ( Truth is 2 * Xv + 1,
               format("x ~2f  predicted ~2f  (clean law says ~2f)~n", [Xv, Yhat, Truth]) )) }.
