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
%%   THE SCHEDULER is the world's: one worker a core (2.9.3; the caller's
%%   thread is worker 0), one store shared by all (2.9.0); a task is pinned
%%   to the worker it was born on and gives way when it yields, awaits,
%%   blocks on a channel or spends its 10,000-step quantum. A thread that
%%   fails makes await/2 fail; one that throws makes it throw the same
%%   ball; the scheduler reports a deadlock when every task is blocked and
%%   the main has not ended).
%%
%%   THE STORE IS THE CALLER'S OWN (2.9.0): a child asserts into the
%%   knowledge base, and the main green thread and the host see the clause
%%   because it is their store; a write stops the world before it lands and
%%   releases it after. Terms still cross between threads in canonical
%%   text. The last section is the predicate-creation race, made likely by
%%   shape: a writer's first assert and a call both intern a predicate.
%%
%%     cocolog -s test/async.pl        from the checkout root
%%
%% The work is a recursion (spin/1), not between/3: a library predicate
%% with a choice point per answer is slow (recorded in bench/README.md),
%% and this case is about the scheduler.

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

%% A JOINED TASK IS READY. What a bare `future_ready' says right after a
%% go/2 is a race in the M:N world -- the child may be on another worker.
case_future(R) :-
    go(spin(1000), F),
    await(F, _),
    ( future_ready(F) -> R = ready ; R = waiting ).

%% THE QUANTUM. Children take the workers beside the host round robin
%% (1, 2, ... and, past the last, 0, the main's own); each spins 20,000
%% steps, so after the main's yield the last is stopped at its
%% 10,000-step quantum -- a task that never yields cannot hold its
%% worker.
case_quantum(R) :-
    go(spin(20000), A), go(spin(20000), B), go(spin(20000), C),
    go(spin(20000), D), go(spin(20000), E), go(spin(20000), F),
    go(spin(20000), G), go(spin(20000), H),
    yield,
    ( future_ready(H) -> R = done ; R = not_done ),
    await_all([A,B,C,D,E,F,G,H]).

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

case_shared(R) :-
    channel(C),
    go((assertz(q(1)), q(X), channel_send(C, X)), F),
    channel_recv(C, X),
    await(F, _),
    ( catch(q(_), _, fail) -> R = main_sees ; R = main_not ).

%% AND A RETRACT CROSSES THE OTHER WAY: the main asserts q(2) on worker 0,
%% the child (worker 1) retracts it, and the main no longer has it.
case_retract(R) :-
    assertz(q(2)),
    channel(C),
    go((retract(q(2)), channel_send(C, gone)), F),
    channel_recv(C, X),
    await(F, _),
    ( catch(q(2), _, fail) -> R = still ; R = gone ),
    X = gone.

result(Goal, R) :-
    async_run(Goal, W),
    arg(1, W, R).

main :-
    catch(use_module(library(async)), _, fail),
    values,
    joining,
    channels,
    failures,
    shared_store,
    shared_store_concurrent,
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
    check('a recursion in the shared store runs to its end', G3, spin(2000)).

%% ---- go and await -------------------------------------------------------
joining :-
    section('go starts, await joins'),
    answer(result(case_all(R1), R1), R1, G1),
    check('await_all waits for each', G1, done),
    answer(result(case_future(R2), R2), R2, G2),
    check('a joined thread is ready', G2, ready),
    answer(result(case_quantum(R3), R3), R3, G3),
    check('a task that never yields is stopped at the quantum', G3, not_done).

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

%% ---- the shared store ----------------------------------------------------
shared_store :-
    section('the knowledge base is shared'),
    answer(result(case_shared(R1), R1), R1, G1),
    check('the main green thread sees a child\'s assert', G1, main_sees),
    answer(( catch(q(_), _, fail) -> W2 = host_sees ; W2 = host_not ), W2, G2),
    check('and so does the host', G2, host_sees),
    answer(result(case_retract(R3), R3), R3, G3),
    check('a child\'s retract is the main\'s', G3, gone).

%% ---- the one store: a writer and a call create the same predicate -------
%%
%% THE CREATE RACE. Both an assert and a CALL intern a predicate
%% (`coco_pred_make'): a call to a name the store does not have creates the
%% entry, so `coco_pred_of' may find it absent. `coco_pred_make' is a
%% double-checked lock -- a lock-free find, then the barrier, then the
%% create -- and it had no second find: a writer and a call could both see
%% the name absent, and the second creation overwrote the bucket slot,
%% hiding the first and every clause already attached to it. The build
%% that made the one store lost each writer's first one or two asserts to
%% it in a stress of eight tasks, about once in four runs.
%%
%% THIS SHAPE MAKES THE RACE LIKELY rather than leaving it to timing: the
%% writer's barrier must wait for four spinners to reach their quantum, and
%% two readers woken by a channel call the name during that wait. Without
%% the recheck the reader's entry is the one the bucket keeps and the
%% writer's clause is on the hidden one; the call below then raises, or
%% sees nothing, and the checks go red on every run of the arm.

gsc_spin(0) :- !.
gsc_spin(N) :- M is N - 1, gsc_spin(M).

gsc_writer(P) :- G =.. [P, writer], assertz(G).

gsc_reader(0, _) :- !.
gsc_reader(N, P) :-
    catch(( call(P, _) -> true ; true ), _, true),
    M is N - 1, gsc_reader(M, P).

gsc_round(P, L) :-
    channel(2, C),
    go(gsc_spin(20000), S1), go(gsc_spin(20000), S2),
    go(gsc_spin(20000), S3), go(gsc_spin(20000), S4),
    go(gsc_writer(P), A),
    go(( channel_recv(C, go), gsc_reader(200, P) ), R1),
    go(( channel_recv(C, go), gsc_reader(200, P) ), R2),
    channel_send(C, go), channel_send(C, go),
    await_all([S1,S2,S3,S4,A,R1,R2]),
    findall(X, call(P, X), L).

gsc_go(P, L) :-
    async_run(gsc_round(P, L), W),
    arg(2, W, L).

shared_store_concurrent :-
    section('the one store: a writer and a call create the same predicate'),
    answer(gsc_go(gsc_f1, L1), L1, G1),
    check('the clause the writer asserted is the predicate the call sees',
          G1, [writer]),
    answer(gsc_go(gsc_f2, L2), L2, G2),
    check('... in a second world', G2, [writer]),
    answer(gsc_go(gsc_f3, L3), L3, G3),
    check('... and a third', G3, [writer]).
