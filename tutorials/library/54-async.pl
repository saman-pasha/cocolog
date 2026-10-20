%% LIBRARY 54 -- library(async): green threads, Go's go and channels
%%
%%     ./cocolog run tutorials/library/54-async.pl main
%%
%% TIER 1 SINCE 2.8.0: `library(async)' is preloaded at start-up (async
%% coroutines are on by default), so there is no use_module here; its
%% clauses are in library/async.pl over the compiled-in green module
%% (lib/green.cicili, no .so to build).
%%
%%     async_run(:Goal)   async_run(:Goal, -Result)
%%     go(:Goal)          go(:Goal, -Id)
%%     yield/0            await(+Id)   await(+Id, -Result)   await_all(+Ids)
%%     async(:Goal, -Future)            future_ready(+Id)
%%     channel(-C)        channel(+Size, -C)
%%     channel_send(+C, +Term)          channel_recv(+C, -Term)   channel_close(+C)
%%
%% A GREEN THREAD IS A MACHINE OF ITS OWN, run by a world of 8 WORKERS --
%% the caller's thread and seven OS threads (2.8.0). Each worker owns a
%% store cloned from the caller's at async_run/1; a task is pinned to the
%% worker it was born on and is preempted at a 10,000-step quantum, so a
%% task that never yields cannot hold a worker. A write a task makes is
%% REPLICATED to every other worker's store before the builtin returns
%% (assertz/1, asserta/1, retract/1, dynamic/1, abolish/1 and nb_setval/2),
%% so the caller, the main thread and the host see it. Terms cross in
%% canonical text through a channel, and the answer of a goal is the goal
%% as instantiated. The caller's variables are NOT bound: the answer is a
%% copy.
%%
%% Everything runs under async_run/1,2. The world reports a deadlock
%% (every task blocked, the main one not ended) from async_run, where the
%% program can catch it; a thread that fails makes await fail, and one that
%% throws makes await throw the same ball.


spin(0) :- !.
spin(N) :- N > 0, M is N - 1, spin(M).

%% the work each green thread does, its answer in the second argument
case_value(R) :-
    go(member(X, [a,b,c]), F),
    await(F, R).

case_chan(R) :-
    channel(C),
    go((channel_send(C, hello), yield), F),
    channel_recv(C, T),
    await(F, _),
    R = T.

case_buffered(R) :-
    channel(2, C),
    channel_send(C, a),
    channel_send(C, b),
    channel_recv(C, X),
    channel_recv(C, Y),
    R = X-Y.

case_fail(R) :-
    go(fail, F),
    ( await(F, _) -> R = yes ; R = no ).

case_error :-
    go(throw(boom), F),
    await(F, _).

case_deadlock :-
    go(await(0, _), F),
    await(F, _).

case_shared(R) :-
    channel(C),
    go((assertz(q(1)), q(X), channel_send(C, X)), F),
    channel_recv(C, X),
    await(F, _),
    ( catch(q(_), _, fail) -> R = main_sees ; R = main_not ).

case_retract(R) :-
    assertz(q(2)),
    channel(C),
    go((retract(q(2)), channel_send(C, gone)), F),
    channel_recv(C, X),
    await(F, _),
    ( catch(q(2), _, fail) -> R = still ; R = gone ).

%% Eight children fill workers 1..7 and then worker 0, the main's own; H
%% shares worker 0, so after the main's yield it has been stopped at its
%% 10,000-step quantum and is not done.
case_preempt(R) :-
    go(spin(20000), A), go(spin(20000), B), go(spin(20000), C),
    go(spin(20000), D), go(spin(20000), E), go(spin(20000), F),
    go(spin(20000), G), go(spin(20000), H),
    yield,
    ( future_ready(H) -> R = done ; R = not_done ),
    await_all([A,B,C,D,E,F,G,H]).

result(Goal, R) :-
    async_run(Goal, W),
    arg(1, W, R).

main :-
    lesson_values,
    lesson_preempt,
    lesson_channels,
    lesson_failures,
    lesson_store,
    lesson_limits,
    format("done~n").

%% ---- values -------------------------------------------------------------
lesson_values :-
    format("~n-- a green thread answers its goal as instantiated~n"),
    result(case_value(R1), R1),
    must('go and await carry a value', R1, member(a, [a,b,c])),
    format("     (the caller's own X is not bound: the answer is a copy)~n"),
    async_run(spin(2000), W2),
    must('a recursion in the shared store runs to its end', W2, spin(2000)),
    result(case_fail(R3), R3),
    must('await of a failed thread fails', R3, no).

%% ---- the quantum --------------------------------------------------------
lesson_preempt :-
    format("~n-- a task that never yields is stopped at the quantum~n"),
    result(case_preempt(R1), R1),
    must('the eighth child shares worker 0 and is not done yet', R1, not_done),
    format("     (yield/0 let the main run; the child went on at 10,000 steps)~n").

%% ---- channels -----------------------------------------------------------
lesson_channels :-
    format("~n-- channels carry terms in canonical text~n"),
    result(case_chan(R1), R1),
    must('an unbuffered rendezvous hands the term over', R1, hello),
    result(case_buffered(R2), R2),
    must('a buffered channel keeps its order', R2, a-b).

%% ---- failures -----------------------------------------------------------
lesson_failures :-
    format("~n-- a throwing thread is the waiter's~n"),
    catch(async_run(case_error, _), E1, true),
    must('await rethrows the thread\'s ball', E1, boom),
    ( catch(async_run(case_deadlock, _), error(resource_error(deadlock), _), true)
    ->  W2 = caught
    ;   W2 = missed
    ),
    must('a deadlock is caught at async_run/1', W2, caught).

%% ---- the store ----------------------------------------------------------
lesson_store :-
    format("~n-- the knowledge base is shared~n"),
    result(case_shared(R1), R1),
    must('the main green thread sees a child\'s assert', R1, main_sees),
    ( catch(q(_), _, fail) -> W2 = host_sees ; W2 = host_not ),
    must('and so does the host', W2, host_sees),
    result(case_retract(R3), R3),
    must('a child\'s retract is the main\'s', R3, gone).

%% ---- the limits ---------------------------------------------------------
lesson_limits :-
    format("~n-- what this is, and what it is not~n"),
    format("   M:N: 8 workers, 1024 tasks and 64 channels a world. A task is~n"),
    format("   preempted at 10,000 steps; a foreign call holds its worker.~n"),
    format("   A SHARED STORE, CLONED: each worker has a store built from~n"),
    format("   the caller's at async_run/1; assertz, asserta, retract,~n"),
    format("   dynamic, abolish and nb_setval are replicated across the~n"),
    format("   workers before they return. b_setval, a consult or load, a~n"),
    format("   backend's fetch and a module's own C state stay the worker's.~n"),
    must('the lesson is still running', yes, yes).

%% ---- the helpers every lesson here carries -----------------------------
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
