%% library(async) -- Go's go, yield and channels, as green threads inside
%% one cocolog process.
%%
%% TIER 1 SINCE 2.8.0: lib/library.cicili preloads this file at start-up, so
%% ASYNC COROUTINES ARE ON BY DEFAULT -- async_run/1,2, go/2, yield/0,
%% await/2, the futures and the channels are there without a use_module,
%% and `use_module(library(async))' is a no-op.
%%
%%     async_run(:Goal)                 run Goal as green thread 0
%%     async_run(:Goal, -Result)        ... and answer the goal as instantiated
%%     go(:Goal) / go(:Goal, -Id)       start a green thread
%%     yield/0                          give the scheduler its turn now
%%     await(+Id) / await(+Id, -Result) join, rethrowing its exception
%%     await_all(+Ids)
%%     async(:Goal, -Future)            go/2's future spelling
%%     future_ready(+Id)
%%     channel(-C) / channel(+Size, -C) a rendezvous (0) or a buffered queue
%%     channel_send(+C, +Term)          blocks when full
%%     channel_recv(+C, -Term)          blocks when empty; fails when closed
%%     channel_close(+C)
%%     async_workers(-N)                the workers a world has, or would start
%%
%% A GREEN THREAD IS NOT library(thread)'s. This one is a machine of its
%% own, run by a world of one worker a CORE (2.9.3, as Go's GOMAXPROCS
%% defaults to NumCPU; COCOLOG_GREEN_WORKERS overrides it): the caller's
%% thread is worker 0 and the others are OS threads, 1..N-1. async_workers/1
%% (2.15.0) answers N: inside a world the workers it has, outside one the
%% workers the next async_run/1 would start, so a pool is sized from the
%% world rather than from a number or the rule worked out again. THE WORLD
%% RUNS OVER THE
%% CALLER'S OWN STORE (2.9.0): a write a task makes -- assertz/1,
%% asserta/1, retract/1, dynamic/1, abolish/1, nb_setval/2 -- is seen by
%% every other task and by the host as soon as it lands, because it IS
%% their store; before it lands the world is stopped for it (the barrier in
%% lib/green.cicili). A task is pinned to the worker it was born on,
%% aliases the caller's name and value tables, and is preempted at a
%% 10,000-step quantum; a foreign call holds its worker. A term crosses in
%% canonical text through a channel, and the result of a goal is the goal
%% itself, instantiated:
%%
%%     ?- async_run((go(member(X, [a,b,c]), F), await(F, R)), Answer).
%%     Answer = (go(member(a,[a,b,c]),0), await(0,member(a,[a,b,c]))).
%%
%% (`X` is not bound in the caller: the result carries the binding.)
%%
%% A thread that fails makes await/2 fail; a thread that throws makes it
%% throw the same ball; an unawaited thread's failure or exception is its
%% own and is not reported. Everything must run under async_run/1,2 -- a
%% go/1 outside it says so by name.
%%
%% THE LIMITS: 1024 threads and 64 channels a world; a task is preempted
%% at a 10,000-step quantum (a foreign call holds its worker); a consult or
%% load, b_setval/2, a backend's fetch and a module's own C state belong to
%% the worker that ran them; the world reports a deadlock when every task
%% is blocked and the main one has not ended; and a goal is read in the
%% new machine's module, so a module-qualified goal is not carried as one.
%%
%% library/async/README.md has the model, the benchmark against OS threads,
%% Go goroutines and asyncio, and the shared-heap design note.

async_run(Goal) :-
    async_run(Goal, _).

async_run(Goal, Result) :-
    '$async_run'(Goal, S),
    async_done(S, Result).

go(Goal) :-
    go(Goal, _).

go(Goal, Id) :-
    '$async_go'(Goal, Id).

yield :-
    '$async_yield'.

await(Id) :-
    await(Id, _).

await(Id, Result) :-
    '$async_await'(Id, S),
    async_done(S, Result).

await_all([]).
await_all([F|Fs]) :-
    await(F, _),
    await_all(Fs).

async(Goal, Future) :-
    go(Goal, Future).

future_ready(Id) :-
    '$async_ready'(Id).

channel(C) :-
    '$async_channel'(0, C).

channel(Size, C) :-
    '$async_channel'(Size, C).

channel_send(C, Term) :-
    '$async_send'(C, Term, S),
    async_sent(S).

channel_recv(C, Term) :-
    '$async_recv'(C, S),
    async_recv(S, Term).

channel_close(C) :-
    '$async_close'(C).

async_workers(N) :-
    '$async_workers'(N).

%% The three answers a thread's or a channel's status can carry.
async_done('$async'(ok, Result), Result) :- !.
async_done('$async'(failed), _) :- !, fail.
async_done('$async'(error, Ball), _) :- throw(Ball).
async_done('$async'(closed), _) :- !, fail.

async_sent('$async'(ok)) :- !.
async_sent('$async'(error, Ball)) :- throw(Ball).

async_recv('$async'(ok, Term), Term) :- !.
async_recv('$async'(closed), _) :- !, fail.
async_recv('$async'(error, Ball), _) :- throw(Ball).
