%% 30. One program, two execution paths
%%
%% NOTHING BELOW MENTIONS THE MODE. The clauses that build the data, run a
%% forward pass, take a loss, ask for a gradient and step the parameters are
%% written once, with the ordinary tensor predicates. tensor_execution/1 is
%% module state, set before the clauses run; `eager' computes every tensor at
%% the predicate that names it, `graph' records a node there and computes it
%% at the first predicate that needs its numbers. The clauses cannot tell
%% which is in force, and that is the rule DESIGN-lazy-graph.md is built on:
%% same predicates, same arguments, same answers.
%%
%% `train' runs the same fit twice in this one process, eager then graph,
%% prints both, and refuses to save unless they agree. On a CPU they are
%% IDENTICAL, because the graph path forces through the very workers eager
%% calls and random leaves draw at record time, in program order -- that is
%% what tutorial 31 shows. On a CUDA device, where this file lives, they are
%% NOT: eager's handles never leave the CPU, and the graph path moves its
%% leaves to the device and computes there, so the same program runs on two
%% pieces of silicon and the numbers agree to about six decimals and no
%% further. The check is a tolerance, and the run says which device did what. `test' reloads under the graph path;
%% `predict' shows the one thing the graph path can do that eager cannot:
%% know a shape, and refuse a shape error, with nothing executed.
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/30-two-paths.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/30-two-paths.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/30-two-paths.pl predict
%%
%% A GPU TUTORIAL, and only that: every goal begins with gpu/0, which puts
%% the process on the CUDA device or, where there is none, says so and
%% stops without failing -- this file never runs on a CPU. Its CPU twin is
%% tutorial 31, the same fit on six rows in the expression syntax, and that
%% is the one test/torch-graph.sh runs here; this one runs on the Colab T4.
%%
%% And the other way to choose a path, from outside the file, is a goal
%% prefix -- this is how test/torch-graph.sh runs every tutorial twice:
%%
%%   ./cocolog run tutorials/tensor/30-two-paths.pl "tensor_execution(torch, graph), train"

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand

%% ---- the program: a plane fitted by SGD, written once ----------------------

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
    tensor_binary(matmul, X, W, XW),
    tensor_binary(add, XW, B, P),
    tensor_binary(sub, P, Y, D),
    tensor_binary(mul, D, D, D2),
    tensor_agg(mean, D2, L),
    tensor_item(L, Loss),
    tensor_grad(L, [W, B], [GW, GB]),
    tensor_step(W, GW, LR, W2),
    tensor_step(B, GB, LR, B2),
    tensor_free(XW), tensor_free(P), tensor_free(D), tensor_free(D2),
    tensor_free(L), tensor_free(GW), tensor_free(GB),
    tensor_free(W), tensor_free(B).

sgd(0, _, _, W, B, _, W, B, Loss, Loss) :- !.
sgd(K, X, Y, W, B, LR, WF, BF, _, LossF) :-
    step(X, Y, W, B, LR, W2, B2, Loss),
    K1 is K - 1,
    sgd(K1, X, Y, W2, B2, LR, WF, BF, Loss, LossF).

%% fit(+X, +Y, -Loss, -Ws, -Bv): a hundred steps from a random start. The
%% random start is the point: under `graph' the randn is a leaf and draws at
%% record time, so both paths see the same start from the same seed.
fit(X, Y, Loss, Ws, Bv) :-
    torch_seed(30),
    tensor_randn([2, 1], W0), tensor_parameter(W0, W),
    tensor_zeros([1], B0),    tensor_parameter(B0, B),
    sgd(100, X, Y, W, B, 0.2, WF, BF, none, Loss),
    tensor_to_list(WF, [[W1], [W2]]), Ws = [W1, W2],
    tensor_to_list(BF, [Bv]).

%% ---- the device: this file runs on a GPU or not at all ---------------------

gpu :-
    (   torch_cuda_available(true)
    ->  torch_device(cuda)
    ;   write('30 is a GPU tutorial: no CUDA device here, not running'), nl,
        halt(0)
    ).

%% ---- the switch, and the comparison ---------------------------------------

%% under(+Mode, +Goal): set the path, run the goal, report what the path did.
%% Under `eager' the stats are all zero -- eager records nothing -- and under
%% `graph' recorded equals executed with nothing pending, because every node
%% was read by tensor_item/2 or tensor_grad/3 before the goal ended.
under(Mode, Goal) :-
    tensor_execution(torch, Mode),
    call(Goal),
    tensor_graph_stats(S),
    format("   ~w: ~w~n", [Mode, S]).

train :-
    gpu,
    data(0, 64, X, Y),
    under(eager, fit(X, Y, LE, WE, BE)),
    under(graph, fit(X, Y, LG, WG, BG)),
    format("eager: loss ~8f  w ~w  b ~w~n", [LE, WE, BE]),
    format("graph: loss ~8f  w ~w  b ~w~n", [LG, WG, BG]),
    WE = [WE1, WE2], WG = [WG1, WG2],
    Diff is max(max(abs(LE - LG), abs(BE - BG)), max(abs(WE1 - WG1), abs(WE2 - WG2))),
    torch_current_device(Dev),
    (   Diff < 1.0e-5
    ->  format("agree within ~e: eager on the CPU, where its handles live, graph on ~w~n", [Diff, Dev])
    ;   format("DIFFER by ~e~n", [Diff]), halt(1)
    ),
    WG = [W1, W2],
    model_new([input(2), dense(1)], M),
    model_set_params(M, [W1, W2, BG]),
    model_save(t30_two_paths, M),
    tensor_execution(torch, eager),
    write(saved), nl.

test :-
    gpu,
    tensor_execution(torch, graph),
    model_load(t30_two_paths, M),
    data(5000, 32, X, Y),
    model_evaluate(M, X, Y, rmse, S),
    format("test rmse ~6f under the graph path~n", [S]),
    ( S < 0.01 -> write(ok), nl ; write('FAIL'), nl, halt(1) ).

%% ---- what only the graph path can do --------------------------------------
predict :-
    gpu,
    model_load(t30_two_paths, M),
    data(9000, 2, X, Y),
    forall(member(Mode, [eager, graph]),
           ( tensor_execution(Mode),
             model_predict(M, X, P), tensor_to_list(P, Ps), tensor_to_list(Y, Ys),
             format("~w: predicted ~w  (plane says ~w)~n", [Mode, Ps, Ys]) )),
    tensor_execution(torch, graph),
    format("~n-- a shape is known with nothing executed~n"),
    tensor_zeros([3, 4], A), tensor_ones([4, 5], B2),
    tensor_binary(matmul, A, B2, C),
    tensor_shape(C, Shape),
    tensor_graph_stats(stats(_, executed(E0), _, pending(P0))),
    format("   matmul of [3,4] by [4,5] has shape ~w; executed ~w, pending ~w~n", [Shape, E0, P0]),
    format("-- and a shape error is refused at the goal, as eager refuses it~n"),
    tensor_ones([5, 6], Bad),
    catch(( tensor_binary(matmul, A, Bad, _), write('   accepted?!'), nl ),
          error(Err, _),
          format("   refused: ~w~n", [Err])),
    tensor_to_list(C, _),
    tensor_graph_stats(stats(_, executed(E1), _, pending(P1))),
    format("-- read once: executed ~w, pending ~w -- the pending one is the [5,6] leaf~n", [E1, P1]),
    format("   the refused matmul never needed; a leaf nobody reads is never made~n"),
    tensor_execution(torch, eager).
