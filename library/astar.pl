%% cocolog -- library(astar): shortest paths over a graph of GOALS.
%%
%% EVERY GAME WITH A MAP NEEDS THIS AND NONE OF IT IS ABOUT ANY GAME --
%% the same argument that put library(hex) here (CivV's movement rung
%% asked; the library answers for everybody). It is textbook A* with a
%% caller-supplied graph: the search never sees a map, only two goals --
%%
%%   astar(+Start, +Goal, :Neighbor, :Heuristic, -Path, -Cost)
%%       call(Neighbor, Node, Next, StepCost)  enumerates edges
%%       call(Heuristic, Node, H)              admissible estimate to Goal
%%
%%   shortest_path(+Start, +Goal, :Neighbor, -Path, -Cost)
%%       the same with the zero heuristic -- Dijkstra, and the oracle
%%       the tests hold astar's costs to.
%%
%% Path includes BOTH endpoints, Start first; Cost is the sum of the
%% step costs. Start == Goal answers [Start] and 0. No path FAILS --
%% unreachable is an ordinary no, not an error.
%%
%% WHY CLAUSES, one more time: the neighbor relation is the caller's
%% NONDETERMINISTIC goal -- for a hex map it is hex_neighbor/3 plus a
%% passability rule, exactly the kind of thing a game states as clauses
%% -- and a C half could not call back into it. The engine's findall
%% drives the expansion; the open list is plain sorted terms.
%%
%% THE ORDER IS PINNED. The open list is kept sorted by f(F, G, Node)
%% under the STANDARD ORDER OF TERMS, so ties break the same way every
%% run and the answered path is a function of the graph -- determinism
%% is not optional in this family. With an admissible heuristic the
%% cost is optimal; with a consistent one (a metric like hex_distance
%% is) the first pop of a node is its cheapest, which is what the
%% closed-set skip relies on.
%%
%% HONEST LIMITS: the open list is a sorted LIST (insertion is linear),
%% the closed set an ordset (membership is linear too). For maps of
%% thousands of nodes that is fine and simple; for millions it is not,
%% and a heap would be the day-two change. No node in the graph may be
%% unifiable with another (use ground nodes), and step costs must be
%% non-negative -- A* is not Bellman-Ford.

:- use_module(library(ordsets)).

astar(Start, Goal, Neighbor, Heuristic, Path, Cost) :-
    call(Heuristic, Start, H0),
    astar_loop([f(H0, 0, Start, [Start])], [], Goal, Neighbor, Heuristic,
               RevPath, Cost),
    reverse(RevPath, Path).

shortest_path(Start, Goal, Neighbor, Path, Cost) :-
    astar(Start, Goal, Neighbor, astar_zero, Path, Cost).

astar_zero(_, 0).

%% ---- the loop ---------------------------------------------------------
%%
%% Pop the least f; the goal ends it, a node already expanded is
%% skipped (its first pop was its cheapest -- consistency), anything
%% else is expanded and its children inserted in order.
astar_loop([f(_, G, Node, Rev)|_], _, Goal, _, _, Rev, G) :-
    Node == Goal, !.
astar_loop([f(_, _, Node, _)|Open], Closed, Goal, Neighbor, Heuristic,
           Path, Cost) :-
    ord_memberchk(Node, Closed), !,
    astar_loop(Open, Closed, Goal, Neighbor, Heuristic, Path, Cost).
astar_loop([f(_, G, Node, Rev)|Open], Closed, Goal, Neighbor, Heuristic,
           Path, Cost) :-
    ord_add_element(Closed, Node, Closed1),
    findall(f(F2, G2, Next, [Next|Rev]),
            ( call(Neighbor, Node, Next, Step),
              \+ ord_memberchk(Next, Closed1),
              G2 is G + Step,
              call(Heuristic, Next, H),
              F2 is G2 + H ),
            Kids),
    insert_all(Kids, Open, Open1),
    astar_loop(Open1, Closed1, Goal, Neighbor, Heuristic, Path, Cost).

insert_all([], Open, Open).
insert_all([K|Ks], Open, Out) :-
    insert_open(Open, K, Open1),
    insert_all(Ks, Open1, Out).

%% Ordered insertion under the standard order of f/4 terms: F first,
%% then G, then the node itself -- the pinned tiebreak.
insert_open([], K, [K]).
insert_open([E|Es], K, Out) :-
    (   K @< E
    ->  Out = [K, E|Es]
    ;   Out = [E|Rest],
        insert_open(Es, K, Rest)
    ).
