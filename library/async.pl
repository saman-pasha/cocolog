%% library(async) -- Go's go, yield and channels, as green threads inside
%% one cocolog process.
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
%%
%% A GREEN THREAD IS NOT library(thread)'s. This one is a machine of its
%% own, stepped for a quantum by a cooperative scheduler in the engine
%% (lib/green.cicili): go/2 starts one, yield/0 and await/2 give way, and
%% a thread that blocks on a channel gives way too. The knowledge base it
%% reads is a SNAPSHOT of the caller's at async_run/1, taken into its own
%% store at spawn -- the store belongs to one machine, and the freeze/thaw
%% scheduler of `cocolog step' empties the store on every thaw, so a
%% shared one is not a choice. What one green thread asserts another does
%% not see; a term crosses in canonical text through a channel, and the
%% result of a goal is the goal itself, instantiated:
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
%% THE LIMITS: 64 threads and 64 channels a scheduler; a spawn pays for a
%% snapshot of the knowledge base (each thread's store is filled from it);
%% the scheduler reports a deadlock when every thread is blocked and the
%% main one has not ended; and a goal is read in the new machine's module,
%% so a module-qualified goal is not carried as one.
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
