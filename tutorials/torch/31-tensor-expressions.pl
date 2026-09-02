%% 31. Tensor expressions: operators, and the grammar that runs them
%%
%% Tutorial 30 wrote its forward pass as five tensor predicates in a row,
%% each naming its result. This file writes the same fit as ONE line,
%%
%%     L := mean((X matmul W + B - Y) ^ 2.0)
%%
%% and the five predicates are still there. A DCG, expr//2, turns the
%% expression into the LIST OF TENSOR GOALS it stands for, in dependency
%% order -- one goal per node, fresh variables for the results -- and `:='
%% runs that list and frees every result but the last. The list is the
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
%% Two rules worth stating. A float is a number and an integer is a tensor
%% handle, because a handle IS an integer, so `X * 2' names handle 2 and
%% `X * 2.0' doubles X. And a subexpression written twice is computed twice:
%% the grammar shares nothing, so name what you reuse -- `H := relu X, ... H'.
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/31-tensor-expressions.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/31-tensor-expressions.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/torch/31-tensor-expressions.pl predict

:- use_module(library(torch)).

%% ---- the operators ----------------------------------------------------------

:- op(700, xfx, :=).
:- op(400, yfx, matmul).
:- op(200, fy, relu).
:- op(200, fy, sigmoid).
:- op(200, fy, tanh).
:- op(200, fy, exp).
:- op(200, fy, log).
:- op(200, fy, sqrt).
:- op(200, fy, abs).
:- op(200, fy, transpose).
:- op(200, fy, mean).
:- op(200, fy, sum).
:- op(200, fy, max).
:- op(200, fy, min).
:- op(200, fy, std).

%% ---- the grammar: an expression to the goals it stands for ------------------
%%
%% expr(+Expr, -T)//: emits the tensor goals that make T, Expr's value, in
%% the order they must run. A handle or a number emits nothing. Every goal
%% ends in its result, which is how `:=' knows what to free. At grammar time
%% a compound's result is still a VARIABLE -- its goal has not run -- so the
%% one test the grammar makes is float or not: a float is a number, and
%% anything else on a tensor's side of an operator is a tensor.

expr(V, _) --> { var(V) }, !, { throw(error(instantiation_error, tensor_expression)) }.
expr(T, T) --> { integer(T) }, !.                     % a handle: already a tensor
expr(N, N) --> { float(N) }, !.                       % a number: stays one until an op meets it
expr(L, T) --> { is_list(L) }, !, [tensor_from_list(L, T)].
expr(A matmul B, T) --> !, expr(A, TA), expr(B, TB),
    { tensor_only(A matmul B, TA), tensor_only(A matmul B, TB) },
    [tensor_binary(matmul, TA, TB, T)].
expr(A + B, T) --> !, binary(add, A, B, T).
expr(A - B, T) --> !, binary(sub, A, B, T).
expr(A * B, T) --> !, binary(mul, A, B, T).
expr(A / B, T) --> !, binary(div, A, B, T).
expr(A ^ B, T) --> !, binary(pow, A, B, T).
expr(- A, T)         --> !, unary(neg, A, T).
expr(relu A, T)      --> !, unary(relu, A, T).
expr(sigmoid A, T)   --> !, unary(sigmoid, A, T).
expr(tanh A, T)      --> !, unary(tanh, A, T).
expr(exp A, T)       --> !, unary(exp, A, T).
expr(log A, T)       --> !, unary(log, A, T).
expr(sqrt A, T)      --> !, unary(sqrt, A, T).
expr(abs A, T)       --> !, unary(abs, A, T).
expr(transpose A, T) --> !, unary(transpose, A, T).
expr(mean A, T) --> !, agg(mean, A, T).
expr(sum A, T)  --> !, agg(sum, A, T).
expr(max A, T)  --> !, agg(max, A, T).
expr(min A, T)  --> !, agg(min, A, T).
expr(std A, T)  --> !, agg(std, A, T).
expr(zeros(S), T)   --> !, [tensor_new(S, zeros, T)].
expr(ones(S), T)    --> !, [tensor_new(S, ones, T)].
expr(randn(S), T)   --> !, [tensor_new(S, randn, T)].
expr(rand(S), T)    --> !, [tensor_new(S, rand, T)].
expr(eye(N), T)     --> !, [tensor_eye(N, T)].
expr(arange(N), T)  --> !, [tensor_arange(N, T)].
expr(full(S, V), T) --> !, [tensor_full(S, V, T)].
expr(reshape(A, S), T)     --> !, expr(A, TA), [tensor_reshape(TA, S, T)].
expr(argmax(A, Dim), T)    --> !, expr(A, TA), [tensor_argmax(TA, Dim, T)].
expr(rows(A, From, To), T) --> !, expr(A, TA), [tensor_rows(TA, From, To, T)].
expr(cols(A, From, To), T) --> !, expr(A, TA), [tensor_cols(TA, From, To, T)].
expr(standardise(A, N), T) --> !, expr(A, TA), [tensor_standardise(TA, N, T)].
expr(index_rows(A, I), T)  --> !, expr(A, TA), expr(I, TI), [tensor_index_rows(TA, TI, T)].
expr(cat(Es, Dim), T)      --> !, exprs(Es, Ts), [tensor_cat(Ts, Dim, T)].
expr(parameter(A), T)      --> !, expr(A, TA), [tensor_parameter(TA, T)].
expr(step(W, G, LR), T)    --> !, expr(W, TW), expr(G, TG), [tensor_step(TW, TG, LR, T)].
expr(E, _) --> { throw(error(domain_error(tensor_expression, E), tensor_expression)) }.

exprs([], []) --> [].
exprs([E|Es], [T|Ts]) --> expr(E, T), exprs(Es, Ts).

%% A number meeting a tensor is tensor_scalar; two numbers are arithmetic;
%% two tensors are tensor_binary. A number on the LEFT of `-' or `/' has no
%% tensor_scalar shape, so it goes through neg, or through pow -1.0.
binary(Op, A, B, T) --> expr(A, TA), expr(B, TB), combine(Op, TA, TB, T).
combine(Op, A, B, T) --> { float(A), float(B) }, !, { arith(Op, A, B, T) }.
combine(Op, A, B, T) --> { float(B) }, !, [tensor_scalar(Op, A, B, T)].
combine(Op, A, B, T) --> { float(A) }, !, scalar_left(Op, A, B, T).
combine(Op, A, B, T) --> [tensor_binary(Op, A, B, T)].
scalar_left(add, A, B, T) --> !, [tensor_scalar(add, B, A, T)].
scalar_left(mul, A, B, T) --> !, [tensor_scalar(mul, B, A, T)].
scalar_left(sub, A, B, T) --> !, [tensor_unary(neg, B, N), tensor_scalar(add, N, A, T)].
scalar_left(div, A, B, T) --> !, [tensor_scalar(pow, B, -1.0, R), tensor_scalar(mul, R, A, T)].
scalar_left(pow, A, B, _) --> { throw(error(domain_error(tensor_expression, A ^ B), tensor_expression)) }.
unary(Op, A, T) --> expr(A, TA), { tensor_only(Op, TA) }, [tensor_unary(Op, TA, T)].
agg(Op, A, T)   --> expr(A, TA), { tensor_only(Op, TA) }, [tensor_agg(Op, TA, T)].
tensor_only(E, X) :-
    ( float(X) -> throw(error(domain_error(tensor_expression, E), tensor_expression)) ; true ).
arith(add, A, B, C) :- C is A + B.
arith(sub, A, B, C) :- C is A - B.
arith(mul, A, B, C) :- C is A * B.
arith(div, A, B, C) :- C is A / B.
arith(pow, A, B, C) :- C is A ** B.

%% ---- the driver: run the list, keep the last result ------------------------

T := Expr :-
    phrase(expr(Expr, T), Goals), !,
    run(Goals),
    forall(( member(G, Goals), G =.. Args, append(_, [R], Args), integer(R), R \== T ),
           tensor_free(R)).

run([]).
run([G|Gs]) :- call(G), run(Gs).

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
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.

step(X, Y, W, B, LR, W2, B2, Loss) :-
    L := mean((X matmul W + B - Y) ^ 2.0),
    tensor_item(L, Loss),
    tensor_grad(L, [W, B], [GW, GB]),
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
    tensor_to_list(WF, [[W1], [W2]]), Ws = [W1, W2],
    tensor_to_list(BF, [Bv]).

under(Mode, Goal) :-
    torch_execution(Mode),
    call(Goal),
    tensor_graph_stats(S),
    format("   ~w: ~w~n", [Mode, S]).

train :-
    data(0, 6, X, Y),
    tensor_to_list(X, Xs), tensor_to_list(Y, Ys),
    format("six rows: x ~w~n          y ~w~n", [Xs, Ys]),
    % the expression, and the goals the grammar makes of it -- printed once,
    % before either path runs it, because the list is the same under both
    tensor_zeros([2, 1], W0), tensor_zeros([1], B0),
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
    tensor_to_list(Y, Ys),
    forall(member(Mode, [eager, graph]),
           ( torch_execution(Mode),
             model_predict(M, X, P), tensor_to_list(P, Ps),
             E := X matmul [[W1], [W2]] + [Bv], tensor_to_list(E, Es),
             format("~w: model ~w  expression ~w  (plane says ~w)~n", [Mode, Ps, Es, Ys]) )),
    torch_execution(graph),
    % the leaves are NAMED here, so `:=' keeps them: a temporary is freed at
    % the `:=', and a freed node no longer counts as pending. The counters
    % are process totals, so the demo reads `executed' before and after.
    tensor_graph_stats(stats(_, executed(E0), _, _)),
    format("~n-- a shape is known with nothing executed~n"),
    A := zeros([3, 4]), B2 := ones([4, 5]),
    C := A matmul B2,
    tensor_shape(C, Shape),
    tensor_graph_stats(stats(_, executed(E1), _, pending(P1))),
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
    tensor_to_list(C, _),
    tensor_graph_stats(stats(_, executed(E2), _, pending(P2))),
    D2 is E2 - E0,
    format("-- read once: executed ~w, pending ~w -- the pending one is the [5,6] leaf~n", [D2, P2]),
    torch_execution(eager).
