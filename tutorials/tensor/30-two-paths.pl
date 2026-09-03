%% 30. One program, two execution paths -- on a GPU
%%
%% Tutorial 31 makes the claim on six rows: the same expressions, run once
%% under tensor_execution(eager) and once under tensor_execution(graph),
%% give the SAME numbers, to the digit, because on a CPU the graph path
%% forces through the very workers eager calls. This file is the same fit
%% on data too large to print, on a CUDA device, where the claim is a
%% different one: eager's handles never leave the CPU, and the graph path
%% moves its leaves to the device and computes there, so the same program
%% runs on two pieces of silicon and the numbers agree to about six
%% decimals and no further. The check is a tolerance, and the run says
%% which device did what.
%%
%% The clauses that build the data, take the loss, ask for a gradient and
%% step the parameters are written once, as tensor expressions, and cannot
%% tell which path is in force -- that is the rule DESIGN-lazy-graph.md is
%% built on: same goals, same arguments, same answers. A path is named only
%% where the lesson is the path -- under//2, each_path//4 and the goals --
%% and only as tensor_execution(Mode), which moves the path and keeps the
%% library; the device is named once, by the guard, with the third argument
%% of tensor_execution/3 -- `cuda' -- and the backend is read back rather
%% than written, so the file runs under library(tensorflow) too.
%%
%% `train' runs the fit twice in one process, eager then graph, prints both,
%% and refuses to save unless they agree within 1e-5. `test' reloads the
%% parameters under the graph path; `predict' answers under each path, then
%% shows the one thing the graph path can do that eager cannot: know a shape,
%% and refuse a shape error, with nothing executed.
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/30-two-paths.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/30-two-paths.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/30-two-paths.pl predict
%%
%% A GPU TUTORIAL, and only that: every goal begins with gpu/0, which puts
%% the process on the CUDA device, and where there is none the goal says so
%% and stops, ending 0 without having run -- this file never runs on a CPU.
%% Its CPU twin is tutorial 31, and that is the one test/torch-graph.sh runs
%% here; this one runs on the Colab T4.

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the program: a plane fitted by SGD, written once ----------------------
%% THE LOSS IS A DEFINED FUNCTION, used by name in the step's expression.

loss(X, Y, W, B) ::= mean((X matmul W + B - Y) ^ 2.0).

noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S), !.

row(I, [X1, X2], [Y]) :-
    noise(I, X1), J is I + 1000, noise(J, X2),
    Y is 2*X1 - 3*X2 + 0.5, !.

data(From, N, X, Y) -->
    { To is From + N - 1,
      findall(R, (between(From, To, I), row(I, R, _)), XR),
      findall(R, (between(From, To, I), row(I, _, R)), YR) },
    X = XR, Y = YR, !.

%% THE STEP IS A PROCEDURE: a DCG rule whose body is bindings, each run
%% through `:=', and whose output list is every tensor made inside -- L, GW,
%% GB and the two new leaves.
step(X, Y, W, B, LR, W2, B2, Loss) -->
    L = loss(X, Y, W, B),
    Loss = item(L),
    [GW, GB] = grad(L, [W, B]),
    W2 = step(W, GW, LR),
    B2 = step(B, GB, LR).

%% THE LOOP IS A PROCEDURE TOO: each step's tensors thread up into the loop's
%% list and exec/1 frees them all when the fit returns. A hundred steps hold
%% five hundred handles until then, which is fine here; a loop of thousands
%% of steps stays a predicate that frees as it goes, as tutorial 29's does.
sgd(0, _, _, W, B, _, W, B, Loss, Loss) --> !.
sgd(K, X, Y, W, B, LR, WF, BF, _, LossF) -->
    step(X, Y, W, B, LR, W2, B2, Loss),
    { K1 is K - 1 },
    sgd(K1, X, Y, W2, B2, LR, WF, BF, Loss, LossF).

%% fit(+X, +Y, -Loss, -Ws, -Bv): a hundred steps from a random start. The
%% random start is the point: under `graph' the randn is a leaf and draws at
%% record time, so both paths see the same start from the same seed. The
%% head names only numbers, so every tensor the fit made is freed when it
%% returns.
fit(X, Y, Loss, Ws, Bv) -->
    seed(30),
    W = parameter(randn([2, 1])),
    B = parameter(zeros([1])),
    sgd(100, X, Y, W, B, 0.2, WF, BF, none, Loss),
    [[W1], [W2]] = list(WF), { Ws = [W1, W2] },
    [Bv] = list(BF).

%% ---- the device: this file runs on a GPU or not at all ---------------------
%% gpu/0 puts the process on the CUDA device, and does nothing else:
%% tensor_execution/3's third argument, on whichever backend and path are
%% already selected. Where there is no CUDA device it FAILS, silently -- the
%% store holds one copy of it per consult, and a guard that printed as it
%% failed would print once per copy -- and each goal below is
%% `( gpu -> exec(...) ; no_gpu )': the notice, once, and the run ends 0
%% without having run.

gpu :-
    torch_cuda_available(true),
    tensor_execution(Backend, Mode), tensor_execution(Backend, Mode, cuda).
no_gpu :- write('30 is a GPU tutorial: no CUDA device here, not running'), nl.

%% ---- the switch, and the comparison ---------------------------------------

%% under(+Mode, +Goal): set the path, run the goal, report what the path did.
%% Under `eager' the stats are all zero -- eager records nothing -- and under
%% `graph' recorded equals executed with nothing pending, because every node
%% was read by item or grad before the goal ended.
under(Mode, Goal) -->
    tensor_execution(Mode),                                  % the path, on whichever backend is selected
    call(Goal),
    S = stats,
    { format("   ~w: ~w~n", [Mode, S]) }.

%% THE THREE GOALS ARE RULES, run by exec/1 through the guarded one-liners
%% the runner calls, so every tensor a goal makes is freed when it ends.
train :- ( gpu -> exec(train) ; no_gpu ), !.
test :- ( gpu -> exec(test) ; no_gpu ), !.
predict :- ( gpu -> exec(predict) ; no_gpu ), !.

train -->
    data(0, 64, X, Y),
    under(eager, fit(X, Y, LE, WE, BE)),
    under(graph, fit(X, Y, LG, WG, BG)),
    torch_current_device(Dev),
    { format("eager: loss ~8f  w ~w  b ~w~n", [LE, WE, BE]),
      format("graph: loss ~8f  w ~w  b ~w~n", [LG, WG, BG]),
      WE = [WE1, WE2], WG = [WG1, WG2],
      Diff is max(max(abs(LE - LG), abs(BE - BG)), max(abs(WE1 - WG1), abs(WE2 - WG2))),
      (   Diff < 1.0e-5
      ->  format("agree within ~e: eager on the CPU, where its handles live, graph on ~w~n", [Diff, Dev])
      ;   format("DIFFER by ~e~n", [Diff]), halt(1)
      ) },
    % the graph path's numbers travel as a parameter list, two tensors made from them
    W = [[WG1], [WG2]], B = [BG],
    params_save(t30_two_paths, [W, B]),
    tensor_execution(eager),
    { write(saved), nl }.

test -->
    tensor_execution(graph),
    [W, B] = params(t30_two_paths),
    data(5000, 32, X, Y),
    S = item(sqrt(loss(X, Y, W, B))),                        % the rmse, through the defined loss
    { format("test rmse ~6f under the graph path~n", [S]),
      ( S < 0.01 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

%% ---- what only the graph path can do --------------------------------------
predict -->
    [W, B] = params(t30_two_paths),
    data(9000, 2, X, Y),
    Ys = list(Y),
    each_path(X, W, B, Ys),
    tensor_execution(graph),
    % the leaves are NAMED here and made by the rule, so nothing is freed
    % until the rule ends: a freed node no longer counts as pending. The
    % counters are process totals, so the demo reads `executed' before and after.
    St0 = stats, { St0 = stats(_, executed(E0), _, _),
                   format("~n-- a shape is known with nothing executed~n") },
    A = zeros([3, 4]), B2 = ones([4, 5]),
    C = A matmul B2,
    Shape = shape(C),
    St1 = stats, { St1 = stats(_, executed(E1), _, pending(P1)), D1 is E1 - E0,
                   format("   matmul of [3,4] by [4,5] has shape ~w; executed ~w, pending ~w~n", [Shape, D1, P1]),
                   format("-- and a shape error is refused at the `:=', as eager refuses it~n") },
    Bad = ones([5, 6]),
    { catch(( _ := A matmul Bad, write('   accepted?!'), nl ),
            error(Err, _),
            format("   refused: ~w~n", [Err])) },
    _ = list(C),
    St2 = stats, { St2 = stats(_, executed(E2), _, pending(P2)), D2 is E2 - E0,
                   format("-- read once: executed ~w, pending ~w -- the pending one is the [5,6] leaf~n", [D2, P2]),
                   format("   the refused matmul never needed; a leaf nobody reads is never made~n") },
    tensor_execution(eager).

%% each_path(+X, +W, +B, +Ys): the expression's answer under each path, for
%% the same rows -- a rule recursing over the modes.
each_path(X, W, B, Ys) --> each_path([eager, graph], X, W, B, Ys).
each_path([], _, _, _, _) --> [].
each_path([Mode|Modes], X, W, B, Ys) -->
    tensor_execution(Mode),
    Ps = list(X matmul W + B),
    { format("~w: predicted ~w  (plane says ~w)~n", [Mode, Ps, Ys]) },
    each_path(Modes, X, W, B, Ys).
