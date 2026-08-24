%% 5. Function approximation: a gaussian bump through relu layers
%%
%% The counterpart of tutorial 4: relu units are hinges, and two layers of
%% them assemble a piecewise-linear tent that hugs exp(-4 x^2). Depth is
%% doing the work here that tanh smoothness did there -- one relu layer
%% needs many more units for the same curve than two need together.
%%
%%   train    fit the bump, save as t05_bump
%%   test     reload, rmse over [-2, 2], pass under 0.1
%%   predict  reload, sample the tent beside the true bump

bump_row(I, [X], [Y]) :- X is -2 + 4 * I / 159, Y is exp(-4 * X * X), !.

train :-
    torch_seed(5),
    findall(R, (between(0, 159, I), bump_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), bump_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(24, relu), dense(24, relu), dense(1)], M),
    model_train(M, X, Y, [epochs(500), batch(32), lr(0.02), optimiser(adam),
                          final_loss(L)]),
    format("trained: final mse ~4f~n", [L]),
    model_save(t05_bump, M),
    write(saved), nl.

test :-
    model_load(t05_bump, M),
    findall(R, (between(0, 159, I), bump_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), bump_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("rmse ~4f~n", [S]),
    ( S < 0.1 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

predict :-
    model_load(t05_bump, M),
    Points = [-2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0],
    findall([Xv], member(Xv, Points), Rows),
    tensor_from_list(Rows, X),
    model_predict(M, X, P),
    tensor_to_list(P, Out),
    forall(( nth0(I, Out, [Yhat]), nth0(I, Points, Xv) ),
           ( Truth is exp(-4 * Xv * Xv),
             format("x ~2f  predicted ~3f  (bump says ~3f)~n", [Xv, Yhat, Truth]) )).
