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
%% ONE PROCESS FOR NINE CHECKS, where test/astar.sh spawned one per
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

%% The caller's closed set: dynamic rows, first argument indexed, as the
%% game has them. `astar/7' calls these; it never clears them, so the
%% test does.
:- dynamic astar_seen/1.
seen_mark(Node) :- assertz(astar_seen(Node)).
seen_there(Node) :- astar_seen(Node).
seen_reset :- retractall(astar_seen(_)).

%% AN ADMISSIBLE HEURISTIC THAT IS NOT CONSISTENT (2.11.1). s -3-> a -2-> g
%% and s -1-> b -1-> a: the cheapest way is s-b-a-g, at 4. h(b) = 3 never
%% overestimates (b is 3 from g) and is not consistent (h(b) = 3 is more
%% than b's step to a plus h(a)), so a is reached first by s-a at 3 and
%% expanded, and only then by s-b-a at 2. Through 2.11.0 the expanded a
%% was closed for good and the answer was s-a-g at 5 (an outside review's
%% graph); b also has a dear way out, so a node the caller marks before
%% the search can force it.
ab_edge(s, a, 3).
ab_edge(a, g, 2).
ab_edge(s, b, 1).
ab_edge(b, a, 1).
ab_edge(b, g, 10).
ab_h(s, 0).
ab_h(a, 0).
ab_h(b, 3).
ab_h(g, 0).
%% a cycle that costs nothing, which a search that reopens must not go
%% round for ever
zc_edge(x, y, 0).
zc_edge(y, x, 0).
zc_edge(x, z, 5).
zc_edge(y, z, 1).

main :-
    laws, oracle, tiebreak, seen_pair, reopened,
    checks_done.

reopened :-
    section('a node reached more cheaply after it was expanded is expanded again'),
    written(astar(s, g, ab_edge, ab_h, P1, C1), P1-C1, G1),
    check('an admissible heuristic that is not consistent finds the cheapest', G1, '[s,b,a,g]-4'),
    written(shortest_path(s, g, ab_edge, P2, C2), P2-C2, G2),
    check('which is the oracle''s answer', G2, '[s,b,a,g]-4'),
    seen_reset,
    written(astar(s, g, ab_edge, ab_h, seen_mark-seen_there, P3, C3), P3-C3, G3),
    check('astar/7 finds it too', G3, '[s,b,a,g]-4'),
    written(( findall(N4, astar_seen(N4), Ns4), msort(Ns4, S4) ), S4, G4),
    check('and marks each node it expanded once, though it expanded a twice', G4, '[a,b,s]'),
    seen_reset,
    assertz(astar_seen(a)),
    written(astar(s, g, ab_edge, ab_h, seen_mark-seen_there, P5, C5), P5-C5, G5),
    check('a node the caller marked first is never searched, however cheap', G5, '[s,b,g]-11'),
    seen_reset,
    written(astar(x, z, zc_edge, astar_zero, P6, C6), P6-C6, G6),
    check('a cycle that costs nothing ends, at the cheapest way out', G6, '[x,y,z]-1').

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

seen_pair :-
    section('the caller supplies the closed set'),
    seen_reset,
    written(( astar(hex(-3, 2), hex(3, -2), step, heur,
                    seen_mark-seen_there, P1, C1),
              astar(hex(-3, 2), hex(3, -2), step, heur, P0, C0),
              ( P1 == P0, C1 =:= C0 -> X = agree ; X = differ ) ), X, G1),
    check('astar/7 answers what astar/6 answers', G1, agree),
    seen_reset,
    assertz(astar_seen(hex(0, 0))),
    written(( astar(hex(0, 0), hex(3, 0), step, heur,
                    seen_mark-seen_there, _, _)
              -> X2 = reached ; X2 = blocked ), X2, G2),
    check('a pre-seen node is not searched again', G2, blocked),
    seen_reset.
