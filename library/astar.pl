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
%%       the same search with a closed set the caller can see:
%%       call(Mark, Node) records each node expanded, once, and
%%       call(Seen, Node) succeeds when it is recorded -- so a node the
%%       caller recorded BEFORE the search is never searched, which is how
%%       a game keeps its walls in the same indexed rows as its map. The
%%       caller resets that state before a search; astar never clears it.
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
%% is not optional in this family.
%%
%% THE COST IS THE LEAST WITH ANY ADMISSIBLE HEURISTIC (2.11.1), one that
%% never overestimates. A node reached again more cheaply than when it was
%% expanded is expanded again, with the cheaper cost passed on to what lies
%% beyond it -- A* with reopening. Through 2.11.0 a node, once expanded,
%% was closed for good, which is right only for a CONSISTENT heuristic
%% (h(N) =< Step + h(Next) on every edge; a metric like hex_distance is
%% one), and an admissible one that was not answered a dearer path than
%% shortest_path/5 did (an outside review's finding: s-a-g at 5 where
%% s-b-a-g costs 4). With a consistent heuristic no node is ever reached
%% more cheaply after it was expanded, so the search, the path and the
%% cost are exactly 2.11.0's. The cheapest cost found for each node is
%% kept (an assoc), and a child no cheaper than the best already found for
%% its node is not put on the open list at all.
%%
%% HONEST LIMITS: the open list is a sorted LIST (insertion is linear);
%% the costs and the expanded nodes are assocs (logarithmic). For maps of
%% thousands of nodes the list is fine and simple; for millions it is not,
%% and a heap would be the day-two change. A heuristic that overestimates
%% gets no promise, and one that is admissible and not consistent can make
%% the search expand a node more than once. No node in the graph may be
%% unifiable with another (use ground nodes), and step costs must be
%% non-negative -- A* is not Bellman-Ford.

astar(Start, Goal, Neighbor, Heuristic, Path, Cost) :-
    astar_run(Start, Goal, Neighbor, Heuristic, none, Path, Cost).

%% THE CALLER'S CLOSED SET. Mark-Seen is a pair of callable terms, not
%% a state threaded through the search: call(Mark, Node) records each node
%% the search expands, once, and call(Seen, Node) asks whether one was
%% recorded -- so a node the CALLER had recorded before the search began
%% is never searched (a wall the game keeps in its own rows, say). The open
%% list, the tiebreak and the answer are exactly astar/6's. The caller
%% resets the set between searches.
astar(Start, Goal, Neighbor, Heuristic, Mark-Seen, Path, Cost) :-
    astar_run(Start, Goal, Neighbor, Heuristic, ms(Mark, Seen), Path, Cost).

shortest_path(Start, Goal, Neighbor, Path, Cost) :-
    astar(Start, Goal, Neighbor, astar_zero, Path, Cost).

astar_zero(_, 0).

%% ---- the loop ---------------------------------------------------------
%%
%% BEST is each node's cheapest cost found so far and DONE the cost each
%% expanded node was expanded at; EXT is `none', or ms(Mark, Seen) for
%% astar/7.
astar_run(Start, Goal, Neighbor, Heuristic, Ext, Path, Cost) :-
    call(Heuristic, Start, H0),
    list_to_assoc([Start-0], Best),
    empty_assoc(Done),
    astar_loop([f(H0, 0, Start, [Start])], Best, Done, Goal, Neighbor,
               Heuristic, Ext, RevPath, Cost),
    reverse(RevPath, Path).

%% Pop the least f; the goal ends it -- tested first, so a goal the caller
%% had already recorded is still the answer when it is the start. A node
%% expanded before at a cost no dearer than this one's is passed over;
%% anything else is expanded and its children inserted in order.
astar_loop([f(_, G, Node, Rev)|_], _, _, Goal, _, _, _, Rev, G) :-
    Node == Goal, !.
astar_loop([f(_, G, Node, Rev)|Open], Best, Done, Goal, Neighbor,
           Heuristic, Ext, Path, Cost) :-
    (   astar_expands(Node, G, Done, Ext)
    ->  put_assoc(Node, Done, G, Done1),
        findall(f(F2, G2, Next, [Next|Rev]),
                ( call(Neighbor, Node, Next, Step),
                  G2 is G + Step,
                  astar_wants(Next, G2, Best, Done1, Ext),
                  call(Heuristic, Next, H),
                  F2 is G2 + H ),
                Kids),
        astar_best(Kids, Best, Best1),
        insert_all(Kids, Open, Open1),
        astar_loop(Open1, Best1, Done1, Goal, Neighbor, Heuristic, Ext,
                   Path, Cost)
    ;   astar_loop(Open, Best, Done, Goal, Neighbor, Heuristic, Ext,
                   Path, Cost)
    ).

%% Whether a popped Node at cost G is expanded: again, when it was
%% expanded before at a dearer cost; for the first time, unless the caller
%% recorded it before the search (astar/7), which marks it now.
astar_expands(Node, G, Done, _) :-
    get_assoc(Node, Done, GD), !,
    G < GD.
astar_expands(_, _, _, none) :- !.
astar_expands(Node, _, _, ms(Mark, Seen)) :-
    \+ call(Seen, Node),
    call(Mark, Node).

%% Whether a child Next at cost G2 goes on the open list: not when a
%% cheaper way there is already known, nor when it was expanded at a cost
%% no dearer, nor (astar/7) when the caller recorded it before the search.
%% An equal cost is let through so the standard order picks between the
%% ways there, as it always did.
astar_wants(Next, G2, Best, Done, Ext) :-
    (   get_assoc(Next, Best, GB) -> G2 =< GB ; true ),
    (   get_assoc(Next, Done, GD) -> G2 < GD
    ;   Ext = ms(_, Seen) -> \+ call(Seen, Next)
    ;   true
    ).

%% the children's costs, each the new best of its node
astar_best([], Best, Best).
astar_best([f(_, G2, Next, _)|Ks], Best0, Best) :-
    (   get_assoc(Next, Best0, GB), GB =< G2
    ->  Best1 = Best0
    ;   put_assoc(Next, Best0, G2, Best1)
    ),
    astar_best(Ks, Best1, Best).

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
