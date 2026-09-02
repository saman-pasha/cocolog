%% 16. Two regression targets at once
%%
%% One network, two answers: the head dense(2) predicts the sum AND the
%% difference of its two inputs in one forward pass, and mse averages over
%% both columns. Multi-output is nothing special in the framework -- the
%% target tensor simply has two columns -- which is precisely the lesson.
%%
%%   train    fit both targets, save as t16_multiout
%%   test     reload, joint rmse under 0.05
%%   predict  reload, show sum and difference side by side

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

mo_row(I, [A, B], [S1, S2]) :-
    noise(I, A), noise(I + 1300, B),
    S1 is A + B, S2 is A - B, !.

mo_data(X, Y) :-
    findall(R, (between(0, 119, I), mo_row(I, R, _)), XR),
    findall(R, (between(0, 119, I), mo_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.

train :-
    torch_seed(16),
    mo_data(X, Y),
    model_new([input(2), dense(2)], M),
    model_train(M, X, Y, [epochs(300), batch(24), lr(0.05), optimiser(adam),
                          final_loss(L)]),
    format("trained: final mse ~6f~n", [L]),
    model_save(t16_multiout, M),
    write(saved), nl.

test :-
    model_load(t16_multiout, M),
    mo_data(X, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("rmse ~6f~n", [S]),
    ( S < 0.05 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t16_multiout, M),
    Rows = [[0.3, 0.2], [-0.5, 0.7], [0.9, -0.9]],
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [Sum, Diff]), nth0(I, Rows, [A, B]) ),
           ( TS is A + B, TD is A - B,
             format("(~1f, ~1f)  sum ~2f (truth ~2f)  diff ~2f (truth ~2f)~n",
                    [A, B, Sum, TS, Diff, TD]) )).
