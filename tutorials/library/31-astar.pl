%% LIBRARY 31 -- library(astar): shortest paths over a graph of goals
%%
%%     ./cocolog run tutorials/library/31-astar.pl main
%%
%% TIER 2: `use_module(library(astar))', clauses only. Textbook A* whose
%% graph is TWO GOALS THE CALLER SUPPLIES -- the search never sees a
%% map:
%%
%%     astar(+Start, +Goal, :Neighbor, :Heuristic, -Path, -Cost)
%%         call(Neighbor, Node, Next, StepCost)   enumerates edges
%%         call(Heuristic, Node, H)               admissible estimate
%%     shortest_path(+Start, +Goal, :Neighbor, -Path, -Cost)
%%         the zero heuristic -- Dijkstra, and the oracle astar's
%%         answers are held to in test/astar.pl
%%
%%     astar(+Start, +Goal, :Neighbor, :Heuristic, +Mark-Seen, -Path, -Cost)
%%         the same with a closed set the caller can see: Mark(Node)
%%         records each node expanded, once; Seen(Node) tests, and a node
%%         the caller recorded before the search is never searched -- a
%%         wall kept in the game's own rows. The set is not reset by the
%%         search, so the caller clears it first.
%%
%% Path carries both endpoints, Start first; Cost is the sum of the
%% steps; Start == Goal answers [Start] and 0; unreachable FAILS, an
%% ordinary no. Ties in the open list break by the standard order of
%% terms, so the same question is always the same path. The cost is the
%% least whenever the heuristic never overestimates: a node reached more
%% cheaply after it was expanded is expanded again (since cocolog 2.11.1).
%%
%% The neighbor goal is where this belongs to Prolog: it is
%% NONDETERMINISTIC, and for a game it is the game's own movement rule
%% -- a hex neighbor that is on the map, not a wall, with the terrain's
%% cost. This lesson builds exactly that, in miniature.

:- use_module(library(astar)).
:- use_module(library(hex)).

%% A tiny world: a 3-radius hex disk, a wall across the middle, every
%% step costing 1.
on_map(H) :- hex_distance(hex(0, 0), H, D), D =< 3.
wall(hex(0, -1)).
wall(hex(1, -1)).
wall(hex(-1, 0)).

step(A, B, 1) :- hex_neighbor(A, _, B), on_map(B), \+ wall(B).
toward_goal(N, H) :- hex_distance(N, hex(0, -3), H).

%% A graph where the estimate never overestimates and still misleads: h(b)
%% is the true 3, and it makes b look worse than it is on the way to a.
road(s, a, 3).
road(a, g, 2).
road(s, b, 1).
road(b, a, 1).
guess(b, 3).
guess(N, 0) :- N \== b.

main :-
    format("~n-- a path, around the wall~n"),
    astar(hex(0, 3), hex(0, -3), step, toward_goal, Path, Cost),
    length(Path, N),
    must('the path arrives', Cost, 8),
    must('with both endpoints aboard', N, 9),
    Path = [First|_],
    last(Path, Last),
    must('start first', First, hex(0, 3)),
    must('goal last', Last, hex(0, -3)),
    show('the way', Path),

    format("~n-- dijkstra is the same answer without the hint~n"),
    shortest_path(hex(0, 3), hex(0, -3), step, _, Cost2),
    must('the zero heuristic agrees on cost', Cost2, Cost),

    format("~n-- the ordinary answers~n"),
    astar(hex(2, 0), hex(2, 0), step, toward_goal, Self, SelfCost),
    must('start equals goal', Self-SelfCost, [hex(2, 0)]-0),
    (   astar(hex(0, 3), hex(9, 9), step, toward_goal, _, _)
    ->  must('unreachable fails', reached, no_path)
    ;   must('unreachable fails', no_path, no_path)
    ),

    format("~n-- an estimate that never overestimates is enough~n"),
    %% s-a is reached first (3 + 0 looks better than 1 + 3), and a is only
    %% later reached more cheaply through b -- so a is expanded again
    astar(s, g, road, guess, Way, WayCost),
    must('the cheapest way, though a was expanded first the dear way', Way-WayCost, [s, b, a, g]-4),

    format("~ndone~n").

show(What, Value) :- format("     ~w: ~w~n", [What, Value]).

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~w~n", [What, Got])
    ;   format("     FAILED: ~w~n        got  ~w~n        want ~w~n", [What, Got, Want]),
        halt(1)
    ).
