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

%% A NESTED ENGINE CANNOT BE SUSPENDED (2.10.1): findall/3, forall/2 and
%% the rest run a goal on a sub-engine whose search lives on a C stack a
%% green yield does not carry. await inside one used to come back as "no
%% more solutions"; it waits inside the builtin now. The same for a
%% channel that blocks, and yield is a no-op there.
case_findall_awaits(R) :-
    findall(F, (between(1, 40, _), go(true, F)), Fs),
    findall(F, (member(F, Fs), await(F, _)), Done),
    length(Done, R).

case_forall_awaits(R) :-
    findall(F, (between(1, 40, _), go(true, F)), Fs),
    forall(member(F, Fs), await(F, true)),
    R = done.

case_findall_recv(R) :-
    channel(C),
    go((spin(1000), channel_send(C, hello)), F),
    findall(X, channel_recv(C, X), Xs),
    await(F, _),
    R = Xs.

case_findall_send(R) :-
    channel(C),
    go((spin(1000), channel_recv(C, X), channel_send(C, X-ack)), F),
    findall(ok, channel_send(C, hello), L),
    channel_recv(C, Back),
    await(F, _),
    R = L-Back.

case_findall_yield(R) :-
    findall(X, (member(X, [a,b,c]), yield), Xs),
    R = Xs.

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
    nested_engines,
    one_worker,
    foreign_write,
    foreign_thread,
    table_growth,
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

%% ---- a blocking call inside findall/forall -------------------------------
%%
%% THE NESTED ENGINE has no yield: its search is a C stack. A block there
%% used to truncate the search and lose the answer; the answer is waited
%% for inside the builtin now, with the worker's own ready tasks run.
nested_engines :-
    section('awaits and channels inside findall/forall'),
    answer(result(case_findall_awaits(R1), R1), R1, G1),
    check('await inside findall joins every one', G1, 40),
    answer(result(case_forall_awaits(R2), R2), R2, G2),
    check('await inside forall joins every one', G2, done),
    answer(result(case_findall_recv(R3), R3), R3, G3),
    check('a blocking receive inside findall gets its term', G3, [hello]),
    answer(result(case_findall_send(R4), R4), R4, G4),
    check('a blocking send inside findall moves its term', G4, [ok]-(hello-ack)),
    answer(result(case_findall_yield(R5), R5), R5, G5),
    check('yield there is a no-op, not a lost answer', G5, [a,b,c]).

%% A WORLD OF ONE WORKER is the case a container has. The first child used
%% to be placed on worker 1, which does not exist there: a crash, not a
%% slow path. One child needs that world, so it is a child process.
one_worker :-
    section('a world of one worker'),
    scratch(D),
    atom_concat(D, '/one.pl', Path),
    fixture(Path,
            [ 'main :- async_run(probe, _).',
              'probe :- findall(F, (between(1, 8, _), go(true, F)), Fs), forall(member(F, Fs), await(F, true)), write(done), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=1 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit),
    check('one worker: go, await and done', Out-Exit, done-0),
    shl(['rm -rf ', D]).

%% A WRITE MUST NOT WAIT FOR A WORKER IN A FOREIGN CALL. The main task is
%% asleep in a declared non-store call; a child on worker 1 writes a
%% global. Before the handshake the child waited for the main to leave the
%% call, so the main read the old value. Two workers are enough, and a
%% container has one, so it is a child process.
foreign_write :-
    section('a write does not wait for a foreign call'),
    scratch(D),
    atom_concat(D, '/foreign.pl', Path),
    fixture(Path,
            [ 'main :- async_run(probe, _).',
              'probe :- nb_setval(green_sync, no), channel(C), go((channel_send(C, ready), nb_setval(green_sync, yes)), F), channel_recv(C, ready), ''$green_foreign_sleep''(100), nb_getval(green_sync, V), await(F, _), write(V), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=2 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit),
    check('the write lands during the call', Out-Exit, yes-0),
    shl(['rm -rf ', D]).

%% THE SAME SHAPE WITH library(thread)'s channel, which is what CivV
%% measured: the main task waits in channel_recv/3, a child writes a global,
%% and a writer that waited for the wait would time out first. Two workers.
foreign_thread :-
    section('a thread channel wait does not hold a write'),
    (   catch(use_module(library(thread)), _, fail)
    ->  scratch(D),
        atom_concat(D, '/thread-wait.pl', Path),
        fixture(Path,
                [ ':- use_module(library(thread)).',
                  'main :- async_run(probe, _).',
                  'probe :- nb_setval(green_sync, no), channel_new(Start), channel_new(Done), go((channel_recv(Start, ready), ''$green_foreign_sleep''(20), nb_setval(green_sync, yes), channel_send(Done, done)), F), channel_send(Start, ready), ( channel_recv(Done, 200, _) -> R = got ; R = timeout ), nb_getval(green_sync, V), await(F, _), write(R-V), nl.' ]),
        cocolog(C),
        sh_join(['COCOLOG_GREEN_WORKERS=2 ', C, ' run ', Path, ' main 2>&1'], Cmd),
        shell(Cmd, Out, Exit),
        check('the write lands while the channel waits', Out-Exit, 'got-yes'-0),
        shl(['rm -rf ', D])
    ;   format("     (skipped: no thread module)~n")
    ).

%% A SHARED TABLE GROWS BY DOUBLING, NOT BY COPYING EVERY ENTRY. The float
%% table took the green world's shared-growth path at every new float, and
%% that path lacked the ordinary "the room is already there" test: each
%% entry allocated and copied the whole table, so 20,000 floats were
%% quadratic. CivV measured 21.5 s for float_new and 21.6 s for float_same
%% in a green child; the fixed case is ~10 ms, and the 5 s bound leaves a
%% slow machine plenty of room while still failing the copy-every-entry
%% path.
table_growth :-
    section('a shared table grows by doubling'),
    get_time(T0),
    ( async_run(forall(between(1, 20000, I), _ is I * 2.5 + 1), _)
    ->  Ran = yes
    ;   Ran = no
    ),
    get_time(T1),
    Ms is round((T1 - T0) * 1000),
    format("     (~w ms)~n", [Ms]),
    ( Ms < 5000 -> Speed = fast ; Speed = slow ),
    check('20,000 floats in a green task', Ran, yes),
    check('the table did not copy itself at every float', Speed, fast).

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
