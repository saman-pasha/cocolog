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
%%   astar(+Start, +Goal, :Neighbor, :Heuristic, +Mark-Seen, -Path, -Cost)
%%       the same search with the caller's closed set: call(Mark, Node)
%%       records an expanded node, call(Seen, Node) succeeds when it is
%%       already recorded. The caller resets that state before a search;
%%       astar never clears it. A game can then use the same indexed rows
%%       it uses for its map instead of the ordered list astar/6 keeps.
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
%% HONEST LIMITS: the open list is a sorted LIST (insertion is linear).
%% astar/6's closed set is an ordset (membership linear too); astar/7
%% takes the caller's Mark-Seen pair, which can be indexed, but the
%% caller owns its lifetime and must reset it. For maps of thousands of
%% nodes the list is fine and simple; for millions it is not, and a heap
%% would be the day-two change. No node in the graph may be unifiable
%% with another (use ground nodes), and step costs must be non-negative
%% -- A* is not Bellman-Ford.

astar(Start, Goal, Neighbor, Heuristic, Path, Cost) :-
    call(Heuristic, Start, H0),
    astar_loop([f(H0, 0, Start, [Start])], [], Goal, Neighbor, Heuristic,
               RevPath, Cost),
    reverse(RevPath, Path).

%% THE CALLER'S CLOSED SET. Mark-Seen is a pair of callable terms, not
%% a state threaded through the search: call(Mark, Node) records the
%% node and call(Seen, Node) asks whether one was recorded. The open
%% list, the tiebreak and the answer are exactly astar/6's; only the
%% membership test and the insert are the caller's. The caller resets
%% the set between searches.
astar(Start, Goal, Neighbor, Heuristic, Mark-Seen, Path, Cost) :-
    call(Heuristic, Start, H0),
    astar_loop_seen([f(H0, 0, Start, [Start])], Goal, Neighbor, Heuristic,
                    Mark, Seen, RevPath, Cost),
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

%% The same loop over a caller-supplied closed set. The goal test comes
%% first, as in astar/6: a goal already marked by the caller is still
%% allowed to end the search if it is the start node.
astar_loop_seen([f(_, G, Node, Rev)|_], Goal, _, _, _, _,
                Rev, G) :-
    Node == Goal, !.
astar_loop_seen([f(_, _, Node, _)|Open], Goal, Neighbor, Heuristic,
                Mark, Seen, Path, Cost) :-
    call(Seen, Node), !,
    astar_loop_seen(Open, Goal, Neighbor, Heuristic, Mark, Seen, Path, Cost).
astar_loop_seen([f(_, G, Node, Rev)|Open], Goal, Neighbor, Heuristic,
                Mark, Seen, Path, Cost) :-
    call(Mark, Node),
    findall(f(F2, G2, Next, [Next|Rev]),
            ( call(Neighbor, Node, Next, Step),
              \+ call(Seen, Next),
              G2 is G + Step,
              call(Heuristic, Next, H),
              F2 is G2 + H ),
            Kids),
    insert_all(Kids, Open, Open1),
    astar_loop_seen(Open1, Goal, Neighbor, Heuristic, Mark, Seen, Path, Cost).

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
