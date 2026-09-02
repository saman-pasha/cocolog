%% 31. Tensor expressions: operators, and the grammar that runs them
%%
%% Tutorial 30 wrote its forward pass as five tensor predicates in a row,
%% each naming its result. This file writes the same fit as ONE line,
%%
%%     L := mean((X matmul W + B - Y) ^ 2.0)
%%
%% and the five predicates are still there. A DCG, expr//2 in
%% library(tensor_expr), turns the expression into the LIST OF TENSOR GOALS
%% it stands for, in dependency order -- one goal per node, fresh variables
%% for the results -- and `:=' runs that list and frees every result but
%% the last. The list is the
%% program: under torch_execution(eager) each goal computes as it runs, under
%% torch_execution(graph) each records a node and the numbers come at the
%% first read, and the grammar cannot tell which, which is why it is named
%% for what it does and not for a path. `train' proves the point the way
%% tutorial 30 did, eager then graph in one process, IDENTICAL or halt(1),
%% and on data small enough to print: six rows.
%%
%% THE OPERATORS -- infix `matmul' at the priority of `*', the arithmetic
%% ones Prolog already has, and one prefix operator per unary predicate, so
%% a function is written before its argument the way it is said:
%%
%%   X matmul W          tensor_binary(matmul, X, W, T)      A + B  A - B  A * B  A / B  tensor_binary
%%   A + 1.5   A ^ 2.0   tensor_scalar(add|sub|mul|div|pow)  a FLOAT is a number, an INTEGER is a handle
%%   - A                 tensor_unary(neg, A, T)             relu A  sigmoid A  tanh A  exp A  log A  sqrt A  abs A  transpose A
%%   mean A              tensor_agg(mean, A, T)              sum A  max A  min A  std A -- a one-element TENSOR, so it differentiates
%%   [[1.0],[2.0]]       tensor_from_list                    zeros(S) ones(S) randn(S) rand(S) eye(N) arange(N) full(S, V)
%%   reshape(A, S)  cat([A, B], Dim)  argmax(A, Dim)  rows(A, From, To)  cols(A, From, To)  standardise(A, N)  index_rows(A, I)
%%   parameter(A)        tensor_parameter: a fresh leaf that requires gradient
%%   step(W, G, LR)      tensor_step: W - LR*G as a NEW leaf -- a function, not a `-', because a step makes a parameter, not a node
%%
%% AND THE ANSWERS, outermost on the right of `:=', each a Prolog term the driver never frees:
%%   V := item(E)   L := list(E)   S := shape(E)   V := reduce(mean, E)   Gs := grad(E, Ps)   Tr-Te := split(E, N)   S := stats
%%
%% Two rules worth stating. A float is a number and an integer is a tensor
%% handle, because a handle IS an integer, so `X * 2' names handle 2 and
%% `X * 2.0' doubles X. And a subexpression written twice is computed twice:
%% the grammar shares nothing, so name what you reuse -- `H := relu X, ... H'.
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/31-tensor-expressions.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/31-tensor-expressions.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/31-tensor-expressions.pl predict

:- use_module(library(torch)).

%% ---- the grammar lives in library(tensor_expr) ------------------------------
%%
%% expr//2, `:=', the composites and the optimisers are the library's; this
%% file is the lesson. THE OPERATORS ARE DECLARED WHERE THEY ARE READ:
%% cocolog's reader applies op/3 to the file it is reading, and a library's
%% clauses are consulted after the file that names it has been read, so a
%% file that writes expressions declares the two it needs before its first
%% clause. The functional forms -- relu(X), mean(X) -- need nothing.

:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(400, yfx, matmul).

%% ---- the program: tutorial 30's plane, six rows, one expression per step ---

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

row(I, [X1, X2], [Y]) :-
    noise(I, X1), J is I + 1000, noise(J, X2),
    Y is 2*X1 - 3*X2 + 0.5, !.

data(From, N, X, Y) :-
    To is From + N - 1,
    findall(R, (between(From, To, I), row(I, R, _)), XR),
    findall(R, (between(From, To, I), row(I, _, R)), YR),
    X := XR, Y := YR, !.

step(X, Y, W, B, LR, W2, B2, Loss) :-
    L := mean((X matmul W + B - Y) ^ 2.0),
    Loss := item(L),
    [GW, GB] := grad(L, [W, B]),
    W2 := step(W, GW, LR),
    B2 := step(B, GB, LR),
    tensor_free(L), tensor_free(GW), tensor_free(GB),
    tensor_free(W), tensor_free(B).

sgd(0, _, _, W, B, _, W, B, Loss, Loss) :- !.
sgd(K, X, Y, W, B, LR, WF, BF, _, LossF) :-
    step(X, Y, W, B, LR, W2, B2, Loss),
    K1 is K - 1,
    sgd(K1, X, Y, W2, B2, LR, WF, BF, Loss, LossF).

fit(X, Y, Loss, Ws, Bv) :-
    torch_seed(31),
    W := parameter(randn([2, 1])),
    B := parameter(zeros([1])),
    sgd(200, X, Y, W, B, 0.2, WF, BF, none, Loss),
    [[W1], [W2]] := list(WF), Ws = [W1, W2],
    [Bv] := list(BF).

under(Mode, Goal) :-
    torch_execution(Mode),
    call(Goal),
    S := stats,
    format("   ~w: ~w~n", [Mode, S]).

train :-
    data(0, 6, X, Y),
    Xs := list(X), Ys := list(Y),
    format("six rows: x ~w~n          y ~w~n", [Xs, Ys]),
    % the expression, and the goals the grammar makes of it -- printed once,
    % before either path runs it, because the list is the same under both
    W0 := zeros([2, 1]), B0 := zeros([1]),
    phrase(expr(mean((X matmul W0 + B0 - Y) ^ 2.0), _), Goals),
    format("the loss, as goals: ~w~n", [Goals]),
    tensor_free(W0), tensor_free(B0),
    under(eager, fit(X, Y, LE, WE, BE)),
    under(graph, fit(X, Y, LG, WG, BG)),
    format("eager: loss ~8f  w ~w  b ~w~n", [LE, WE, BE]),
    format("graph: loss ~8f  w ~w  b ~w~n", [LG, WG, BG]),
    (   LE =:= LG, WE == WG, BE =:= BG
    ->  write('identical -- the same expression, the same numbers'), nl
    ;   write('DIFFER'), nl, halt(1)
    ),
    WG = [W1, W2],
    model_new([input(2), dense(1)], M),
    model_set_params(M, [W1, W2, BG]),
    model_save(t31_expressions, M),
    torch_execution(eager),
    write(saved), nl.

test :-
    torch_execution(graph),
    model_load(t31_expressions, M),
    data(5000, 32, X, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("test rmse ~6f under the graph path~n", [S]),
    ( S < 0.01 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

%% predict answers twice for the same rows: through the model, and through
%% the expression the model IS -- its weights as list literals, which the
%% grammar makes leaves of -- under each path.
predict :-
    model_load(t31_expressions, M),
    model_params(M, [W1, W2, Bv]),
    data(9000, 2, X, Y),
    Ys := list(Y),
    forall(member(Mode, [eager, graph]),
           ( torch_execution(Mode),
             model_predict(M, X, P), Ps := list(P),
             E := X matmul [[W1], [W2]] + [Bv], Es := list(E),
             format("~w: model ~w  expression ~w  (plane says ~w)~n", [Mode, Ps, Es, Ys]) )),
    torch_execution(graph),
    % the leaves are NAMED here, so `:=' keeps them: a temporary is freed at
    % the `:=', and a freed node no longer counts as pending. The counters
    % are process totals, so the demo reads `executed' before and after.
    St0 := stats, St0 = stats(_, executed(E0), _, _),
    format("~n-- a shape is known with nothing executed~n"),
    A := zeros([3, 4]), B2 := ones([4, 5]),
    C := A matmul B2,
    Shape := shape(C),
    St1 := stats, St1 = stats(_, executed(E1), _, pending(P1)),
    D1 is E1 - E0,
    format("   zeros([3,4]) matmul ones([4,5]) has shape ~w; executed ~w, pending ~w~n", [Shape, D1, P1]),
    format("-- and a shape error is refused at the `:=', as eager refuses it~n"),
    Bad := ones([5, 6]),
    catch(( _ := A matmul Bad, write('   accepted?!'), nl ),
          error(Err, _),
          format("   refused: ~w~n", [Err])),
    format("-- and a number on the wrong side of a power is refused by the grammar~n"),
    catch(( _ := 2.0 ^ C, write('   accepted?!'), nl ),
          error(Err2, _),
          format("   refused: ~w~n", [Err2])),
    _ := list(C),
    St2 := stats, St2 = stats(_, executed(E2), _, pending(P2)),
    D2 is E2 - E0,
    format("-- read once: executed ~w, pending ~w -- the pending one is the [5,6] leaf~n", [D2, P2]),
    torch_execution(eager).
