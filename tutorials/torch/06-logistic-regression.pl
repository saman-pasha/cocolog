%% 6. Logistic regression: one sigmoid unit, binary cross-entropy
%%
%% The linear classifier: which side of the line a + b = 0 a point falls.
%% The head is dense(1, sigmoid) -- a probability, not a score -- and the
%% loss is bce, which expects exactly that. Accuracy is counted BY HAND
%% here: the module's accuracy metric takes an argmax across columns, and
%% a one-column argmax is always zero, a small trap every framework has.
%%
%%   train    fit the boundary, save as t06_logistic
%%   test     reload, count hits over the plane, pass at 95%
%%   predict  reload, give the probability for a few points

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

logi_row(I, [A, B], [L]) :-
    noise(I, A), noise(I + 500, B),
    ( A + B > 0 -> L = 1.0 ; L = 0.0 ), !.

logi_data(X, Y, YR) :-
    findall(R, (between(0, 159, I), logi_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), logi_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.

count_eq([], [], 0).
count_eq([P|Ps], [L|Ls], K) :-
    count_eq(Ps, Ls, K0),
    ( P =:= L -> K is K0 + 1 ; K = K0 ).

train :-
    torch_seed(6),
    logi_data(X, Y, _),
    model_new([input(2), dense(1, sigmoid)], M),
    model_train(M, X, Y, [epochs(300), batch(32), lr(0.1), optimiser(adam),
                          loss(bce), final_loss(L)]),
    format("trained: final bce ~4f~n", [L]),
    model_save(t06_logistic, M),
    write(saved), nl.

test :-
    model_load(t06_logistic, M),
    logi_data(X, _, YR),
    model_predict(M, X, P),
    tensor_to_list(P, Rows),
    findall(C, (member([V], Rows), ( V > 0.5 -> C = 1.0 ; C = 0.0 )), Pred),
    findall(L, member([L], YR), Lab),
    count_eq(Pred, Lab, K),
    length(Lab, N), Pct is K * 100 // N,
    format("accuracy ~w%~n", [Pct]),
    ( Pct >= 95 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t06_logistic, M),
    Rows = [[0.8, 0.8], [-0.8, -0.8], [0.1, -0.05], [-0.3, 0.4]],
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [Prob]), nth0(I, Rows, [A, B]) ),
           format("(~2f, ~2f)  p(class 1) ~2f~n", [A, B, Prob])).
