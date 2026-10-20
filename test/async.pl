%% library(async) -- green threads: go, await, yield and channels, run by
%% the cooperative scheduler in lib/green.cicili.
%%
%% WHAT IS CHECKED, and why each part needs its own shape:
%%
%%   A RESULT IS A TERM. A green thread answers its goal as instantiated,
%%   so each case is a helper predicate whose SECOND argument is the
%%   answer -- case_values(go(member(a, [a,b,c]), ...)) -- and the test
%%   reads that argument from the whole term async_run/1 answers. The
%%   caller's own variables are not bound: the term is a copy.
%%
%%   THE SCHEDULER is the thread that runs: go/2 starts one, await/2 joins
%%   it, yield/0 gives way, and a channel send or receive blocks. A thread
%%   that fails makes await/2 fail; one that throws makes it throw the same
%%   ball; the scheduler reports a deadlock from async_run/1, not from
%%   inside the main goal (the main goal is not running then).
%%
%%   THE SNAPSHOT is the boundary: a child can assert and read its own
%%   predicate, and neither the main green thread nor the host sees it.
%%
%%     cocolog -s test/async.pl        from the checkout root
%%
%% The work is a recursion (spin/1), not between/3: a library predicate
%% with a choice point per answer is slow in a green store (recorded in
%% bench/README.md), and this case is about the scheduler.

:- use_module('test/prelude.pl').

spin(0) :- !.
spin(N) :- N > 0, M is N - 1, spin(M).

case_values(R) :-
    go(member(X, [a,b,c]), F),
    await(F, R).

case_all(R) :-
    go(spin(1000), A),
    go(spin(2000), B),
    await_all([A,B]),
    R = done.

case_future(R) :-
    go(spin(1000), F),
    ( future_ready(F) -> R = ready ; R = waiting ).

case_yielded(R) :-
    go(spin(1000), F),
    yield,
    ( future_ready(F) -> R = ready ; R = waiting ).

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

case_compound(R) :-
    channel(C),
    go(channel_send(C, t(1,2)), _),
    channel_recv(C, T),
    R = T.

case_closed(R) :-
    channel(C),
    channel_close(C),
    ( channel_recv(C, _) -> R = got ; R = closed ).

case_fail(R) :-
    go(fail, F),
    ( await(F, _) -> R = yes ; R = no ).

case_error :-
    go(throw(boom), F),
    await(F, _).

case_deadlock :-
    go(await(0, _), F),
    await(F, _).

case_private(R) :-
    channel(C),
    go((assertz(q(1)), q(X), channel_send(C, X)), F),
    channel_recv(C, X),
    await(F, _),
    ( catch(q(_), _, fail) -> R = main_sees ; R = main_not ).

result(Goal, R) :-
    async_run(Goal, W),
    arg(1, W, R).

main :-
    catch(use_module(library(async)), _, fail),
    values,
    joining,
    channels,
    failures,
    private_store,
    checks_done.

%% ---- values ------------------------------------------------------------
values :-
    section('a green thread answers its goal as instantiated'),
    answer(result(case_values(R1), R1), R1, G1),
    check('async_run/2 carries the helper\'s answer', G1, member(a, [a,b,c])),
    answer(( async_run(member(X, [a,b,c]), _), (var(X) -> W2 = unbound ; W2 = bound) ),
           W2, G2),
    check('the caller\'s own variables are not bound by it', G2, unbound),
    answer(async_run(spin(2000), R3), R3, G3),
    check('a recursion in the snapshot runs to its end', G3, spin(2000)).

%% ---- go and await -------------------------------------------------------
joining :-
    section('go starts, await joins'),
    answer(result(case_all(R1), R1), R1, G1),
    check('await_all waits for each', G1, done),
    answer(result(case_future(R2), R2), R2, G2),
    check('future_ready is not ready before the scheduler ran it', G2, waiting),
    answer(result(case_yielded(R3), R3), R3, G3),
    check('after a yield it has been run', G3, ready).

%% ---- channels ------------------------------------------------------------
channels :-
    section('channels carry terms between threads'),
    answer(result(case_chan(R1), R1), R1, G1),
    check('an unbuffered rendezvous', G1, hello),
    answer(result(case_buffered(R2), R2), R2, G2),
    check('a buffered channel keeps its order', G2, a-b),
    answer(result(case_compound(R3), R3), R3, G3),
    check('a compound crosses whole', G3, t(1,2)),
    answer(result(case_closed(R4), R4), R4, G4),
    check('a closed empty channel fails a receive', G4, closed).

%% ---- failures and exceptions --------------------------------------------
failures :-
    section('a failed or throwing thread is the waiter\'s'),
    answer(result(case_fail(R1), R1), R1, G1),
    check('await of a failed thread fails', G1, no),
    answer(catch(async_run(case_error, _), E2, true), E2, G2),
    check('await of a throwing thread throws the same ball', G2, boom),
    answer(catch(async_run(case_deadlock, _),
                 error(resource_error(deadlock), _), true), yes, G3),
    check('a deadlock is the scheduler\'s, caught at async_run/1', G3, yes).

%% ---- the snapshot ---------------------------------------------------------
private_store :-
    section('a green thread\'s store is its own'),
    answer(result(case_private(R1), R1), R1, G1),
    check('the main green thread does not see a child\'s assert', G1, main_not),
    answer(( catch(q(_), _, fail) -> W2 = host_sees ; W2 = host_not ), W2, G2),
    check('nor does the host', G2, host_not).
