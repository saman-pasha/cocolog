%% 24. Reinforcement learning: Q-learning on a gridworld
%%
%% The first RL tutorial everywhere: a 4x4 grid, start in one corner, a
%% goal worth +1 in the other, a pit worth -1 in the way, every step
%% costing a little. The agent learns Q(state, action) -- what each move
%% is worth in the long run -- and the greedy policy over Q walks the
%% optimal path around the pit.
%%
%% The method is FITTED Q-ITERATION, which is the DQN idea with the
%% training loop turned inside out. The Q-network is ONE EXPRESSION, a
%% function the file defines,
%%
%%     q([W1, B1, W2, B2], X) ::= relu(X matmul W1 + B1) matmul W2 + B2.
%%
%% over one-hot states. A sweep reads the whole table at once --
%% `list(q(Ps, Xall))' over the sixteen states -- and builds the Bellman
%% targets
%%
%%     target(s, a)  =  reward(s')  +  gamma * max_a' Q(s', a')
%%
%% in Prolog, then regresses the network onto them: forty Adam steps on
%% `mse(q(Ps, Xs), Y)', the gradient of the expression by grad/2. Repeating
%% that sweep is the whole algorithm, and the sweep loop is a predicate in
%% braces, since a step frees the old parameters. The greedy policy is
%% `argmax(q(Ps, [Row]), 1)': one state in, the best move out. No replay
%% buffer, no exploration schedule: the world here is small enough to sweep
%% exhaustively, which is also what makes the run deterministic and the
%% test exact. An earlier version of this file held the same network in a
%% model_new model; that layer API is still taught in
%% tutorials/library/22-torch.pl.
%%
%% The grid (row 0 at the top, cell = 4 * Row + Col):
%%
%%       0   1   2   3        start = 0
%%       4  [5]  6   7        pit   = 5   (reward -1, ends the episode)
%%       8   9  10  11        goal  = 15  (reward +1, ends the episode)
%%      12  13  14  15        every other step: -0.04, gamma 0.9
%%
%%   train    30 Bellman sweeps of 40 Adam steps each; the parameters saved as t24_qlearn
%%   test     reload, walk greedily from the start: must reach the goal
%%            in the optimal six steps and never touch the pit
%%   predict  reload, print the greedy route and the value of the start
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/24-q-learning.pl train
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/24-q-learning.pl test
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/24-q-learning.pl predict

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- op(700, xfx, :=).
:- op(700, xfx, ::=).
:- op(400, yfx, matmul).

%% ---- the world --------------------------------------------------------------
%% Every predicate here ends in a cut: the store keeps every consult of this
%% file, and a clause without one would answer once per copy.

goal(15) :- !.
pit(5) :- !.
terminal(S) :- ( goal(S) ; pit(S) ), !.

reward(S, 1.0)    :- goal(S), !.
reward(S, -1.0)   :- pit(S), !.
reward(_, -0.04) :- !.

% Actions: 0 up, 1 down, 2 left, 3 right; walking into a wall stays put.
move(S, 0, S2) :- R is S // 4, ( R =:= 0 -> S2 = S ; S2 is S - 4 ), !.
move(S, 1, S2) :- R is S // 4, ( R =:= 3 -> S2 = S ; S2 is S + 4 ), !.
move(S, 2, S2) :- C is S mod 4, ( C =:= 0 -> S2 = S ; S2 is S - 1 ), !.
move(S, 3, S2) :- C is S mod 4, ( C =:= 3 -> S2 = S ; S2 is S + 1 ), !.

%% state_row(+S, -Row): a cell as its one-hot, sixteen floats.
state_row(S, Row) :-
    findall(V, ( between(0, 15, J), ( J =:= S -> V = 1.0 ; V = 0.0 ) ), Row), !.

%% ---- the Q-network ----------------------------------------------------------
%% A DEFINED FUNCTION: sixteen in, a hidden layer of 32 with relu, four out
%% -- one value per action. Used by name in every expression below.

q([W1, B1, W2, B2], X) ::= relu(X matmul W1 + B1) matmul W2 + B2.

parameters([W1, B1, W2, B2]) :-
    W1 := parameter(glorot(16, 32)), B1 := parameter(zeros([1, 32])),
    W2 := parameter(glorot(32, 4)),  B2 := parameter(zeros([1, 4])), !.

%% q_table(+Ps, +Xall, -Q): all sixteen Q rows under the current parameters,
%% as lists -- one expression, its answer a Prolog term.
q_table(Ps, Xall, Q) :- Q := list(q(Ps, Xall)), !.

%% ---- the Bellman sweep ------------------------------------------------------

max_of([X], X) :- !.
max_of([X|Xs], M) :- max_of(Xs, M0), ( X > M0 -> M = X ; M = M0 ), !.

% One target row: for each action from S, reward at the landing square plus
% the discounted value of the best move from there -- zero beyond a terminal,
% because the episode is over and there is nothing left to collect.
target_row(S, Q, Row) :-
    findall(T, ( between(0, 3, A),
                 move(S, A, S2),
                 reward(S2, R),
                 ( terminal(S2) -> T = R
                 ; nth0(S2, Q, QRow), max_of(QRow, Best), T is R + 0.9 * Best ) ),
            Row), !.

% One sweep: read the table, build targets for the non-terminal states,
% regress the network onto them. A step answers NEW parameters and frees
% the old, so the parameters and the optimiser's state thread through.
sweep(Ps, St, Xall, Xnt, Ps2, St2) :-
    q_table(Ps, Xall, Q),
    findall(Row, ( between(0, 15, S), \+ terminal(S), target_row(S, Q, Row) ), YR),
    Y := YR,
    fit(40, Ps, St, Xnt, Y, Ps2, St2),
    tensor_free(Y), !.

fit(0, Ps, St, _, _, Ps, St) :- !.
fit(K, Ps, St, X, Y, PsF, StF) :-
    L := mse(q(Ps, X), Y),
    Gs := grad(L, Ps),
    adam_step(Ps, Gs, St, 0.01, Ps2, St2),
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, St2, X, Y, PsF, StF).

sweeps(0, Ps, St, _, _, Ps, St) :- !.
sweeps(K, Ps, St, Xall, Xnt, PsF, StF) :-
    sweep(Ps, St, Xall, Xnt, Ps2, St2),
    ( K mod 10 =:= 0
    -> q_table(Ps2, Xall, Q), nth0(0, Q, Q0), max_of(Q0, V0),
       format("   ~w sweeps to go, the start worth ~4f~n", [K, V0])
    ;  true ),
    K1 is K - 1,
    sweeps(K1, Ps2, St2, Xall, Xnt, PsF, StF).

%% ---- the greedy walk --------------------------------------------------------
%% The policy is argmax over the network's row for one state -- a predicate,
%% since it frees as it goes: `:=' frees the one-hot leaf and the argmax.

greedy_path(_, S, _, [S]) :- terminal(S), !.
greedy_path(_, _, 0, []) :- !.               % out of patience: not a path
greedy_path(Ps, S, Fuel, [S|Rest]) :-
    state_row(S, Row),
    [A0] := list(argmax(q(Ps, [Row]), 1)),
    A is round(A0),
    move(S, A, S2),
    Fuel1 is Fuel - 1,
    greedy_path(Ps, S2, Fuel1, Rest), !.

%% ---- the three goals ----------------------------------------------------------

%% THE THREE GOALS ARE RULES, run by exec/1 through the one-liners the runner
%% calls; the one-hot states are the library's nonterminal, so exec/1 frees
%% them when a goal ends; the sweeps stay a predicate in braces.
train :- exec(train).
test :- exec(test).
predict :- exec(predict).

train -->
    seed(24),
    { findall(S, between(0, 15, S), All),
      findall(S, ( between(0, 15, S), \+ terminal(S) ), Live) },
    one_hot(All, 16, Xall), one_hot(Live, 16, Xnt),
    { parameters(Ps0), adam_init(Ps0, St0),
      sweeps(30, Ps0, St0, Xall, Xnt, Ps, _),
      q_table(Ps, Xall, Q), nth0(0, Q, Q0), max_of(Q0, V0),
      format("trained: 30 sweeps, value of the start ~4f~n", [V0]) },
    params_save(t24_qlearn, Ps),
    { write(saved), nl }.

test -->
    Ps = params(t24_qlearn),
    { greedy_path(Ps, 0, 10, Path),
      format("greedy path ~w~n", [Path]),
      ( Path = [] -> write('FAIL never reached a terminal'), nl, halt(1) ; true ),
      last(Path, End),
      ( End =:= 15 -> true ; write('FAIL did not reach the goal'), nl, halt(1) ),
      ( member(5, Path) -> write('FAIL walked into the pit'), nl, halt(1) ; true ),
      length(Path, Len),
      % six moves is optimal: Manhattan distance from corner to corner
      ( Len =:= 7 -> write('ok optimal in six moves'), nl
      ; L2 is Len - 1, format("FAIL took ~w moves~n", [L2]), halt(1) ) }.

predict -->
    Ps = params(t24_qlearn),
    { findall(S, between(0, 15, S), All) },
    one_hot(All, 16, Xall),
    { greedy_path(Ps, 0, 10, Path),
      format("the greedy route: ~w~n", [Path]),
      forall(member(S, Path),
             ( R is S // 4, C is S mod 4,
               ( goal(S) -> W = ' (the goal)' ; pit(S) -> W = ' (the pit!)' ; W = '' ),
               format("  cell ~w = row ~w col ~w~w~n", [S, R, C, W]) )),
      q_table(Ps, Xall, Q),
      nth0(0, Q, Q0), max_of(Q0, V0),
      format("the start is worth ~4f under the learned policy~n", [V0]) }.
