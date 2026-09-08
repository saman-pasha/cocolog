%% LIBRARY 42 -- library(cowork): a crew that outlives the turn
%%
%%     ./cocolog run tutorials/library/42-cowork.pl main
%%
%% TIER 2: `use_module(library(cowork))', clauses only, over
%% `library(thread)' -- so it needs `sh modules/thread/build.sh' and nothing
%% else. There is no C in it.
%%
%% WHY A CREW AND NOT A PARALLEL MAP. A worker thread's store starts EMPTY
%% and is filled from the process-wide module registry on its first goal, so
%% starting one costs what your PROGRAM costs, not what the job costs:
%% measured at 3.1ms with the default modules and 23.8ms once a
%% 3 000-clause module is registered. A game with several thousand clauses
%% is then tens of milliseconds a thread -- several frames -- and a library
%% that spawned a thread per job would spend its life starting them.
%%
%% So a crew is started ONCE, at load, and lives for the session. That one
%% decision is the whole design; `library/cowork/DESIGN.md' carries the
%% measurements and the plan.
%%
%% WHAT IS FREE AND WHAT IS METERED:
%%
%%   * every registered MODULE is already in every worker -- rules, terrain,
%%     a tech tree, all of it, for nothing;
%%   * mutable state crosses as canonical TEXT, about 1.1ms per 1 000
%%     five-argument facts, which is a per-TURN budget and not a per-frame
%%     one;
%%   * the caller's own asserted clauses cross NOT AT ALL. This lesson
%%     proves that on itself, below.
%%
%% THE SURFACE:
%%
%%     cowork_start(+N, +Options, -Crew)     Options: on_start(Goal)
%%     cowork_stop(+Crew)    cowork_size(+Crew, -N)
%%     cowork_tell(+Crew, +Clauses)          every worker asserts its own copy
%%     cowork_forget(+Crew, +Heads)          and drops it again
%%     cowork_ask(+Crew, ?Goal)              one job, unified back
%%     cowork_ask(+Crew, +Goal, -Answer)     ... or as a copy
%%     cowork_map(+Crew, +Goals, -Results)   ok(G) | failed | error(Ball)
%%     cowork_post(+Crew, +Goal)             fire and forget -- nothing waits
%%     cowork_poll(+Crew, -Result)           an answer if one is ready, else FAILS
%%     cowork_poll(+Crew, +Timeout, -Result) ... or wait that long

:- use_module(library(cowork)).

:- dynamic tutorial_only/1.

main :-
    format("~n-- a crew is started once, and answers many times~n"),
    cowork_start(4, [], Crew),
    cowork_size(Crew, N),
    must('four workers', N, 4),

    format("~n-- the answer is the goal as the worker proved it~n"),
    cowork_map(Crew, [atom_length(hello, _), msort([3,1,2], _)], Rs),
    must('two jobs, two answers', Rs,
         [ok(atom_length(hello, 5)), ok(msort([3,1,2], [1,2,3]))]),
    format("   A goal is COPIED to a worker and its answer copied back, so~n"),
    format("   the caller's own variable is not the one the worker bound.~n"),
    format("   `cowork_ask/2' unifies the copy back for you:~n"),
    cowork_ask(Crew, atom_length(cowork, Len)),
    must('cowork_ask/2 binds', Len, 6),

    format("~n-- and the answers are in INPUT order, always~n"),
    numlist(1, 8, Ns),
    findall(numlist(1, K, _), member(K, Ns), Jobs),
    cowork_map(Crew, Jobs, Lists),
    findall(L, member(ok(numlist(1, _, L)), Lists), Got),
    last(Got, Longest),
    must('eight jobs over four workers, still in order', Longest, [1,2,3,4,5,6,7,8]),
    format("   Whoever finishes first, the list comes back in the order you~n"),
    format("   asked. That is not tidiness: everything this family claims~n"),
    format("   about deterministic REPLAY depends on parallelism being~n"),
    format("   invisible in the answer.~n"),

    format("~n-- proved, failed and threw are three different answers~n"),
    cowork_map(Crew, [atom_length(ab, _), fail, throw(too_big(5))], Outcomes),
    must('each outcome in its own slot', Outcomes,
         [ok(atom_length(ab, 2)), failed, error(too_big(5))]),
    format("   A crew that folded these together would turn a bug in a~n"),
    format("   worker into a city that quietly has no yield. The ball comes~n"),
    format("   back whole, and the worker that threw it stays in the crew.~n"),

    format("~n-- a worker sees MODULES, never the caller's store~n"),
    assertz(tutorial_only(1)),
    cowork_map(Crew, [tutorial_only(_)], [Invisible]),
    (   Invisible = error(error(existence_error(procedure, Missing), _))
    ->  true
    ;   Missing = Invisible
    ),
    must('a clause this file asserted is not even a predicate there',
         Missing, tutorial_only/1),
    format("   NOT `failed' -- there is no such predicate in that worker at~n"),
    format("   all, and an undefined procedure raises. Which is the honest~n"),
    format("   answer: `the snapshot never arrived' and `this tile has no~n"),
    format("   yield' are different things, and a crew that answered `no' to~n"),
    format("   both would hide the first behind the second.~n"),
    format("   A worker's store is filled from the process-wide module~n"),
    format("   registry, and this file was CONSULTED rather than loaded as a~n"),
    format("   module. So the jobs a real program sends must be predicates~n"),
    format("   from a `use_module' done BEFORE the crew started, and the~n"),
    format("   turn's changing facts must be sent:~n"),
    format("   (`cowork_start(N, [on_start(dynamic(tile/3))], C)' declares~n"),
    format("   them in each worker, if you would rather absence FAILED.)~n"),

    format("~n-- cowork_tell/2 is the one way state crosses~n"),
    cowork_tell(Crew, [tile(a, 2, 1), tile(b, 3, 4)]),
    cowork_map(Crew, [tile(a, _, _), tile(b, _, _)], Told),
    must('every worker got its own copy', Told,
         [ok(tile(a, 2, 1)), ok(tile(b, 3, 4))]),
    cowork_forget(Crew, [tile(_, _, _)]),
    cowork_map(Crew, [tile(a, _, _)], Gone),
    must('and forgetting takes it out of all of them', Gone, [failed]),
    format("   `tell' waits for every worker to acknowledge, so the job you~n"),
    format("   send next cannot arrive before the snapshot it asks about.~n"),

    format("~n-- and work can leave a frame that has a deadline~n"),
    format("   `cowork_map/3' WAITS, so a frame that calls it has not moved~n"),
    format("   the work -- only where the time is spent. `cowork_post/2'~n"),
    format("   does not wait, and `cowork_poll/2' asks without blocking:~n"),
    ( cowork_poll(Crew, _) -> Empty = something ; Empty = nothing_yet ),
    must('a poll with nothing posted fails', Empty, nothing_yet),
    cowork_post(Crew, atom_length(pipelined, _)),
    cowork_poll(Crew, 5000, Posted),
    must('and a posted job comes back later', Posted, ok(atom_length(pipelined, 9))),
    format("   Measured on forty frames: a loop computing its own derived~n"),
    format("   state cost 35.4ms a frame, and the same loop posting it cost~n"),
    format("   3.7ms -- with the worst frame down from 46ms to 5.~n"),
    format("   BUT PACE IT. Posting every frame regardless is a queue that~n"),
    format("   grows: forty frames posted forty jobs, collected twelve, and~n"),
    format("   left twenty-eight stale ones waiting. Post when the last~n"),
    format("   answer has come back, which is what poll/2 tells you.~n"),

    format("~n-- and the crew is stopped when the program is done~n"),
    cowork_stop(Crew),
    format("   Every inbox is told to stop and every thread joined, so a~n"),
    format("   stopped crew has left nothing running.~n"),

    format("~n-- what this buys, said honestly~n"),
    format("   Not `the game runs faster'. A 16ms frame cannot wait for~n"),
    format("   work it moved off the loop. What it buys is that a frame~n"),
    format("   stops paying for answers it does not need YET, and a turn's~n"),
    format("   independent work divides by the cores. Drawing never moves:~n"),
    format("   the GL context belongs to the thread that opened the window.~n"),

    format("~ndone~n").

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
