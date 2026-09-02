%% 24. Reinforcement learning: Q-learning on a gridworld
%%
%% The first RL tutorial everywhere: a 4x4 grid, start in one corner, a
%% goal worth +1 in the other, a pit worth -1 in the way, every step
%% costing a little. The agent learns Q(state, action) -- what each move
%% is worth in the long run -- and the greedy policy over Q walks the
%% optimal path around the pit.
%%
%% The method is FITTED Q-ITERATION, which is the DQN idea with the
%% training loop turned inside out, and it needs nothing the module does
%% not already have: model_predict computes the Bellman targets
%%
%%     target(s, a)  =  reward(s')  +  gamma * max_a' Q(s', a')
%%
%% over every state at once, model_train regresses the network onto
%% those targets with plain mse, and repeating that sweep is the whole
%% algorithm. No replay buffer, no exploration schedule: the world here
%% is small enough to sweep exhaustively, which is also what makes the
%% run deterministic and the test exact.
%%
%% The grid (row 0 at the top, cell = 4 * Row + Col):
%%
%%       0   1   2   3        start = 0
%%       4  [5]  6   7        pit   = 5   (reward -1, ends the episode)
%%       8   9  10  11        goal  = 15  (reward +1, ends the episode)
%%      12  13  14  15        every other step: -0.04, gamma 0.9
%%
%%   train    30 Bellman sweeps, save the Q-network as t24_qlearn
%%   test     reload, walk greedily from the start: must reach the goal
%%            in the optimal six steps and never touch the pit
%%   predict  reload, print the greedy route and the value of the start

% ---- the world --------------------------------------------------------------

%% libtorch is a LOADABLE module now, under modules/torch, so it is
%% asked for like any other library. It used to be compiled into the
%% binary and always present.
:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend, Linux; tensor_execution(tensorflow, _) loads it on demand

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

one_hot(S, Row) :-
    findall(V, (between(0, 15, J), ( J =:= S -> V = 1.0 ; V = 0.0 )), Row), !.

% ---- the Bellman sweep ------------------------------------------------------

max_of([X], X) :- !.
max_of([X|Xs], M) :- max_of(Xs, M0), ( X > M0 -> M = X ; M = M0 ), !.

argmax_of(Xs, I) :- max_of(Xs, M), nth0(I, Xs, V), V =:= M, !.

% One target row: for each action from S, reward at the landing square plus
% the discounted value of the best move from there -- zero beyond a terminal,
% because the episode is over and there is nothing left to collect.
target_row(S, Q, Row) :-
    findall(T, (between(0, 3, A),
                move(S, A, S2),
                reward(S2, R),
                ( terminal(S2) -> T = R
                ; nth0(S2, Q, QRow), max_of(QRow, Best), T is R + 0.9 * Best )),
            Row), !.

% All sixteen Q rows under the current network, as one predict.
q_table(M, Q) :-
    findall(Row, (between(0, 15, S), one_hot(S, Row)), All),
    tensor_from_list(All, X),
    model_predict(M, X, P),
    tensor_to_list(P, Q),
    tensor_free(X), tensor_free(P), !.

% One sweep: read the table, build targets for the non-terminal states,
% regress the network onto them.
sweep(M) :-
    q_table(M, Q),
    findall(Row, (between(0, 15, S), \+ terminal(S), one_hot(S, Row)), XR),
    findall(Row, (between(0, 15, S), \+ terminal(S), target_row(S, Q, Row)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_train(M, X, Y, [epochs(40), batch(14), lr(0.01), optimiser(adam)]),
    tensor_free(X), tensor_free(Y), !.

sweeps(0, _) :- !.
sweeps(K, M) :- sweep(M), K1 is K - 1, sweeps(K1, M).

% ---- the greedy walk --------------------------------------------------------

greedy_path(_, S, _, [S]) :- terminal(S), !.
greedy_path(_, _, 0, []) :- !.               % out of patience: not a path
greedy_path(M, S, Fuel, [S|Rest]) :-
    one_hot(S, Row),
    tensor_from_list([Row], X),
    model_predict(M, X, P),
    tensor_to_list(P, [QRow]),
    tensor_free(X), tensor_free(P),
    argmax_of(QRow, A),
    move(S, A, S2),
    Fuel1 is Fuel - 1,
    greedy_path(M, S2, Fuel1, Rest), !.

% ---- the goals --------------------------------------------------------------

train :-
    torch_seed(24),
    model_new([input(16), dense(32, relu), dense(4)], M),
    sweeps(30, M),
    q_table(M, Q),
    nth0(0, Q, Q0), max_of(Q0, V0),
    format("trained: 30 sweeps, value of the start ~4f~n", [V0]),
    model_save(t24_qlearn, M),
    write(saved), nl.

test :-
    model_load(t24_qlearn, M),
    greedy_path(M, 0, 10, Path),
    format("greedy path ~w~n", [Path]),
    ( Path = [] -> write('FAIL never reached a terminal'), nl, halt(1) ; true ),
    last(Path, End),
    ( End =:= 15 -> true ; write('FAIL did not reach the goal'), nl, halt(1) ),
    ( member(5, Path) -> write('FAIL walked into the pit'), nl, halt(1) ; true ),
    length(Path, Len),
    % six moves is optimal: Manhattan distance from corner to corner
    ( Len =:= 7 -> write('ok optimal in six moves'), nl
    ; L2 is Len - 1, format("FAIL took ~w moves~n", [L2]), halt(1) ).

predict :-
    model_load(t24_qlearn, M),
    greedy_path(M, 0, 10, Path),
    format("the greedy route: ~w~n", [Path]),
    forall(member(S, Path),
           ( R is S // 4, C is S mod 4,
             ( goal(S) -> W = ' (the goal)' ; pit(S) -> W = ' (the pit!)' ; W = '' ),
             format("  cell ~w = row ~w col ~w~w~n", [S, R, C, W]) )),
    q_table(M, Q),
    nth0(0, Q, Q0), max_of(Q0, V0),
    format("the start is worth ~4f under the learned policy~n", [V0]).
