%% 16. Two regression targets at once
%%
%% One network, two answers: a [2, 2] weight predicts the sum AND the
%% difference of its two inputs in one matmul, and mse averages over both
%% columns as it averages over rows. Multi-output is nothing special in
%% expressions -- the target tensor simply has two columns, and the model
%% is the one line
%%
%%     both(X, W, B) ::= X matmul W + B.
%%
%% which is precisely the lesson. The weight it should find is
%% [[1, 1], [1, -1]], and `predict' prints the one it found. (An earlier
%% version of this file was a model_new spec with a dense(2) head, trained
%% by model_train.)
%%
%%   train    fit both targets, 120 rows, Adam; save as t16_multiout
%%   test     reload, joint rmse under 0.05
%%   predict  reload, show sum and difference side by side
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/16-multi-output.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/16-multi-output.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/16-multi-output.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand
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

%% mo_row(+I, -Inputs, -Targets): two numbers, and their sum and difference.
mo_row(I, [A, B], [S1, S2]) :-
    noise(I, A), noise(I + 1300, B),
    S1 is A + B, S2 is A - B, !.

%% pairs(-X, -Y): 120 rows, X [120, 2] and Y [120, 2] -- two columns of target.
pairs(X, Y) -->
    { findall(R, (between(0, 119, I), mo_row(I, R, _)), XR),
      findall(R, (between(0, 119, I), mo_row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the model --------------------------------------------------------------------------
%% A DEFINED FUNCTION: both answers in one matmul, the second column of W
%% as free as the first.

both(X, W, B) ::= X matmul W + B.

parameters(W, B) :- W := parameter(glorot(2, 2)), B := parameter(zeros([1, 2])), !.

%% ---- the three goals ---------------------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(16),
    pairs(X, Y),
    { parameters(W0, B0), adam_init([W0, B0], St0),
      fit(500, [W0, B0], St0, X, Y, [W, B]) },
    S = item(sqrt(mse(both(X, W, B), Y))),
    { format("trained: joint rmse ~6f~n", [S]) },
    params_save(t16_multiout, [W, B]),
    { write(saved), nl }.

fit(0, Ps, _, _, _, Ps) :- !.
fit(K, [W, B], St, X, Y, PsF) :-
    L := mse(both(X, W, B), Y),                             % one mean over both columns
    Gs := grad(L, [W, B]),
    ( K mod 100 =:= 0 -> Lv := item(L), format("   ~w steps to go, mse ~6f~n", [K, Lv]) ; true ),
    adam_step([W, B], Gs, St, 0.05, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    [W, B] = params(t16_multiout),
    pairs(X, Y),
    S = item(sqrt(mse(both(X, W, B), Y))),
    { format("rmse ~6f~n", [S]),
      ( S < 0.05 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    [W, B] = params(t16_multiout),
    WL = list(W), BL = list(B),
    { format("the weight found: ~w  bias ~w  (the law is [[1, 1], [1, -1]] and 0)~n", [WL, BL]),
      Rows = [[0.3, 0.2], [-0.5, 0.7], [0.9, -0.9]] },
    Out = list(both(Rows, W, B)),
    { forall(( nth0(I, Out, [Sum, Diff]), nth0(I, Rows, [A, Bv]) ),
             ( TS is A + Bv, TD is A - Bv,
               format("(~1f, ~1f)  sum ~2f (truth ~2f)  diff ~2f (truth ~2f)~n",
                      [A, Bv, Sum, TS, Diff, TD]) )) }.
