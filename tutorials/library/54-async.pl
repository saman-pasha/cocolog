%% LIBRARY 54 -- library(async): green threads, Go's go and channels
%%
%%     ./cocolog run tutorials/library/54-async.pl main
%%
%% TIER 2: `use_module(library(async))', clauses in library/async.pl over
%% the compiled-in green module (lib/green.cicili, no .so to build).
%%
%%     async_run(:Goal)   async_run(:Goal, -Result)
%%     go(:Goal)          go(:Goal, -Id)
%%     yield/0            await(+Id)   await(+Id, -Result)   await_all(+Ids)
%%     async(:Goal, -Future)            future_ready(+Id)
%%     channel(-C)        channel(+Size, -C)
%%     channel_send(+C, +Term)          channel_recv(+C, -Term)   channel_close(+C)
%%
%% A GREEN THREAD IS A MACHINE OF ITS OWN, run by a scheduler in the
%% process: no OS thread, no preemption (it runs until it yields, awaits,
%% blocks on a channel, or ends). It shares the caller's KNOWLEDGE BASE:
%% its atom and functor tables are the caller's, and a write one thread
%% makes is seen by every thread and the host when the scheduler runs it.
%% Terms cross in canonical text through a channel, and the answer of a
%% goal is the goal as instantiated. The caller's variables are NOT bound:
%% the answer is a copy.
%%
%% Everything runs under async_run/1,2. The scheduler reports a deadlock
%% (every thread blocked, the main one not ended) from async_run, where the
%% program can catch it; a thread that fails makes await fail, and one that
%% throws makes await throw the same ball.

:- use_module(library(async)).

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

result(Goal, R) :-
    async_run(Goal, W),
    arg(1, W, R).

main :-
    lesson_values,
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
    must('and so does the host', W2, host_sees).

%% ---- the limits ---------------------------------------------------------
lesson_limits :-
    format("~n-- what this is, and what it is not~n"),
    format("   COOPERATIVE: a thread runs until yield/0, await/2, a channel~n"),
    format("   block or its end. A tight loop holds the scheduler.~n"),
    format("   A SHARED STORE: a spawn copies no knowledge base, and a~n"),
    format("   write is seen by every thread and the host. The machine is~n"),
    format("   a heap, trail and engine over the caller's tables.~n"),
    format("   SMALL: 64 threads and 64 channels a scheduler.~n"),
    must('the lesson is still running', yes, yes).

%% ---- the helpers every lesson here carries -----------------------------
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
