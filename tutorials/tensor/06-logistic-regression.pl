%% 6. Logistic regression: one sigmoid unit, binary cross-entropy
%%
%% The linear classifier: which side of the line a + b = 0 a point falls.
%% The network is `sigmoid(X matmul W + B)' -- a probability, not a score --
%% and the loss is bce/2, which expects exactly that:
%%
%%     prob(X, W, B) ::= sigmoid(X matmul W + B).
%%     loss(X, Y, W, B) ::= bce(prob(X, W, B), Y).
%%
%% Adam steps the two parameters. Accuracy is counted BY HAND here: the
%% library's accuracy/3 takes an argmax across columns, and a one-column
%% argmax is always zero, a small trap every framework has -- so the test
%% reads the probabilities as a list and counts the ones on the right side
%% of 0.5. An earlier version of this file used model_new and model_train;
%% that API is still taught in tutorials/library/22-torch.pl.
%%
%%   train    fit the boundary, save the parameters as t06_logistic
%%   test     reload, count hits over the plane, pass at 95%
%%   predict  reload, give the probability for a few points
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/06-logistic-regression.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/06-logistic-regression.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/06-logistic-regression.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).

%% ---- the data ---------------------------------------------------------------
%% Deterministic noise in (-1, 1), the sin-hash; every predicate ends in a
%% cut, since the store keeps every consult and a generator without one
%% would answer once per copy.

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

logi_row(I, [A, B], [L]) :-
    noise(I, A), noise(I + 500, B),
    ( A + B > 0 -> L = 1.0 ; L = 0.0 ), !.

%% logi_data(-X, -Y, -Labels): 160 points as [160, 2], their labels as a
%% [160, 1] tensor of 0.0 and 1.0, and the same labels as a list, for counting.
logi_data(X, Y, YR) -->
    { findall(R, (between(0, 159, I), logi_row(I, R, _)), XR),
      findall(R, (between(0, 159, I), logi_row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% ---- the network ------------------------------------------------------------

prob(X, W, B) ::= sigmoid(X matmul W + B).
loss(X, Y, W, B) ::= bce(prob(X, W, B), Y).

%% a PREDICATE, not a rule: the optimiser frees these, and a rule must not
%% emit what something else frees.
parameters([W, B]) :-
    W := parameter(randn([2, 1])),
    B := parameter(zeros([1])), !.

%% hits(+Probs, +Labels, -K): how many probabilities fall on their label's
%% side of 0.5 -- the accuracy count, by hand.
hits(Probs, Labels, K) :-
    findall(x, ( nth0(I, Probs, [P]), nth0(I, Labels, [L]),
                 ( P > 0.5 -> C = 1.0 ; C = 0.0 ), C =:= L ), Hs),
    length(Hs, K), !.

%% ---- the three goals ----------------------------------------------------------
%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the fit loop stays a predicate in braces, since it steps an
%% optimiser that frees the old parameters itself.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(6),
    logi_data(X, Y, _),
    { parameters(Ps0), adam_init(Ps0, St0),
      fit(300, Ps0, St0, X, Y, [W, B]) },
    L = item(loss(X, Y, W, B)),
    { format("trained: final bce ~4f~n", [L]) },
    params_save(t06_logistic, [W, B]),
    { write(saved), nl }.

%% fit(+K, +Ps, +State, +X, +Y, -PsF): K full-batch steps of Adam at 0.1.
fit(0, Ps, _, _, _, Ps) :- !.
fit(K, [W, B], St, X, Y, PsF) :-
    L := loss(X, Y, W, B),
    Gs := grad(L, [W, B]),
    ( K mod 100 =:= 0 -> Lv := item(L), format("   ~w steps to go, bce ~4f~n", [K, Lv]) ; true ),
    adam_step([W, B], Gs, St, 0.1, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF).

test -->
    [W, B] = params(t06_logistic),
    logi_data(X, _, Labels),
    Probs = list(prob(X, W, B)),
    { hits(Probs, Labels, K),
      length(Labels, N), Pct is K * 100 // N,
      format("accuracy ~w%~n", [Pct]),
      ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

predict -->
    [W, B] = params(t06_logistic),
    { Rows = [[0.8, 0.8], [-0.8, -0.8], [0.1, -0.05], [-0.3, 0.4]] },
    Out = list(prob(Rows, W, B)),
    { forall(( nth0(I, Out, [P]), nth0(I, Rows, [A, B2]) ),
             ( ( A + B2 > 0 -> Side = 1 ; Side = 0 ),
               format("(~2f, ~2f)  p(class 1) ~2f  (the line says ~w)~n", [A, B2, P, Side]) )) }.
