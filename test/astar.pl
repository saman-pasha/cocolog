%% library(astar) -- shortest paths, held to an ORACLE and to walls.
%%
%% A pathfinder's classic failure is being almost right: a path that
%% exists, connects, and costs one more than it should. So the strong
%% check here is AGREEMENT -- on a hex grid with varied step costs, the
%% heuristic search must answer the exact cost the zero-heuristic search
%% (Dijkstra, the oracle this library also exports) answers, across a
%% batch of start/goal pairs. The rest are the laws: paths connect step
%% by step through the caller's own neighbor goal, walls force the
%% detour they force, unreachable FAILS rather than erring, and the same
%% question twice is the same path -- the pinned tiebreak, observed.
%%
%% The grid is library(hex)'s, because that is the caller this library
%% was built for and the cross-library seam is worth one suite holding.
%%
%%     cocolog -s test/astar.pl        from the checkout root
%%
%% ONE PROCESS FOR SEVEN CHECKS, where test/astar.sh spawned one per
%% check, each re-asserting the stage. The stage is this file's own
%% clauses now.

:- use_module('test/prelude.pl').
:- use_module(library(astar)).
:- use_module(library(hex)).

%% The stage every check shares: a 9x9 hex disk, step cost
%% 1 + ((Q*3+R*5) mod 3) so costs vary but are a pure function of the
%% tile, and a wall.
on_grid(H) :- hex_distance(hex(0, 0), H, D), D =< 4.
wall(hex(1, -1)).
wall(hex(1, 0)).
wall(hex(0, 1)).
cost_of(hex(Q, R), C) :- C is 1 + (Q * 3 + R * 5) mod 3.
step(A, B, C) :- hex_neighbor(A, _, B), on_grid(B), \+ wall(B), cost_of(B, C).
heur(N, H) :- hex_distance(N, hex(3, 0), H).
%% the island, for the check that must fail
island_step(A, B, C) :- step(A, B, C), hex_distance(hex(0, 0), B, D), D =< 1.

main :-
    laws, oracle, tiebreak,
    checks_done.

laws :-
    section('the laws'),
    written(astar(hex(2, 2), hex(2, 2), step, heur, P1, Cost1), P1-Cost1, G1),
    check('start equals goal answers itself at zero', G1, '[hex(2,2)]-0'),
    written(( astar(hex(-3, 0), hex(3, 0), step, heur, P2, _),
              findall(x, ( append(_, [A2, B2|_], P2), \+ step(A2, B2, _) ), Bad2),
              length(Bad2, N2) ), N2, G2),
    check('a path connects, step by step, through the caller''s goal', G2, '0'),
    written(( astar(hex(-3, 0), hex(3, 0), step, heur, P3, Cost3), P3 = [_|Rest3],
              findall(C3, ( member(H3, Rest3), cost_of(H3, C3) ), Cs3), sum_list(Cs3, Sum3),
              ( Sum3 =:= Cost3 -> X3 = agree ; X3 = differ(Cost3, Sum3) ) ), X3, G3),
    check('its cost is the sum of its steps', G3, agree),
    written(( astar(hex(0, 0), hex(2, 0), step, heur, P4, _), length(P4, N4),
              ( N4 > 3 -> X4 = detoured(N4) ; X4 = through_the_wall(N4) ) ), X4, G4),
    check('the wall forces a detour longer than the crow flies', G4, 'detoured(6)'),
    written(( astar(hex(0, 0), hex(3, 0), island_step, heur, _, _) -> X5 = reached ; X5 = no_path ), X5, G5),
    check('unreachable fails, it does not err', G5, no_path).

oracle :-
    section('the oracle: astar agrees with dijkstra on every pair'),
    written(( findall(x, ( member(A-B, [hex(-3,0)-hex(3,0), hex(0,-4)-hex(0,4),
                                        hex(-2,-2)-hex(2,2), hex(4,-4)-hex(-4,4),
                                        hex(-4,0)-hex(2,2), hex(0,0)-hex(4,-2),
                                        hex(-1,-2)-hex(1,3), hex(3,-4)-hex(-3,4),
                                        hex(2,-4)-hex(-2,4), hex(-4,4)-hex(4,-4),
                                        hex(0,-2)-hex(0,3), hex(-2,0)-hex(3,-3)]),
                           astar(A, B, step, heur, _, C1),
                           shortest_path(A, B, step, _, C2), C1 =\= C2 ), Bad),
              length(Bad, N) ), N, G),
    check('twelve varied pairs, zero disagreements', G, '0').

tiebreak :-
    section('the pinned tiebreak'),
    written(( astar(hex(-3, 2), hex(3, -2), step, heur, P1, _),
              astar(hex(-3, 2), hex(3, -2), step, heur, P2, _),
              ( P1 == P2 -> X = same ; X = differ ) ), X, G),
    check('the same question twice is the same path', G, same).
