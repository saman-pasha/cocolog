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
    go(member(_X, [a,b,c]), F),
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
%% (1, 2, ... and, past the last, 0, the main's own), so with one child a
%% worker the last is worker 0's whatever the world's size, which the
%% world answers itself (async_workers/1); it spins 60,000 steps, so after
%% the main's yield it is stopped at its 10,000-step quantum -- a task
%% that never yields cannot hold its worker. EIGHT CHILDREN, the case's
%% first shape, put the last on worker 0 only in a world whose size
%% divides eight: on GitHub's three-core Mac it was worker 2's, and
%% whether it had finished was a race -- squeezed onto two CPUs here,
%% worlds of 3, 5, 6 and 7 answered done two to six times in 300, a world
%% of 8 never, and this shape never in worlds of 1 to 9.
case_quantum(R) :-
    async_workers(N),
    N1 is N - 1,
    beside(N1, Fs),
    go(spin(20000), H),
    yield,
    ( future_ready(H) -> R = done ; R = not_done ),
    await_all([H|Fs]).

%% the N-1 children that fill the workers beside the main's
beside(0, []) :- !.
beside(K, [F|Fs]) :- go(true, F), K1 is K - 1, beside(K1, Fs).

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
    world_size,
    nested_engines,
    one_worker,
    foreign_write,
    foreign_thread,
    table_growth,
    private_reads,
    channels,
    failures,
    shared_store,
    shared_store_concurrent,
    cleanups,
    retract_walks,
    retired_codes,
    world_end,
    halts,
    waiters,
    send_status,
    names,
    foreign_ack,
    foreign_begin,
    rehash,
    stacked,
    live_waiters,
    gave_up,
    dead_nested,
    beside,
    narrow,
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

%% ---- the world's size ----------------------------------------------------
%%
%% async_workers/1 (2.15.0): outside a world the workers the next
%% async_run/1 would start, COCOLOG_GREEN_WORKERS if it gives a positive
%% count and the cores otherwise, 256 at most; inside a world the workers
%% it has, whatever the variable says since. The variable is the process's,
%% so each setting is a child process. The fixture prints the answer
%% outside, inside, inside after the world set the variable to 5, and
%% outside after the world.
world_size :-
    section('the world\'s size: async_workers/1'),
    answer(( async_workers(N1), integer(N1), N1 >= 1, N1 =< 256 -> W1 = yes ; W1 = no ),
           W1, G1),
    check('outside a world: a count of 1 to 256', G1, yes),
    answer(( async_workers(N2a), result(async_workers(N2b), N2b), N2b == N2a -> W2 = yes ; W2 = no ),
           W2, G2),
    check('inside a world: the workers it has, the count outside said', G2, yes),
    scratch(D),
    atom_concat(D, '/size.pl', Path),
    fixture(Path,
            [ 'main :- async_workers(A), async_run((async_workers(_B), setenv(''COCOLOG_GREEN_WORKERS'', 5), async_workers(_C)), R), R = (async_workers(B1), _, async_workers(C1)), async_workers(E), ( catch((use_module(library(os)), os_cpus(K)), _, fail) -> M is min(256, K) ; M = none ), ( A == M -> S = cores ; S = A ), write(S-B1-C1-E), nl.' ]),
    cocolog(C),
    size_run(['COCOLOG_GREEN_WORKERS=2 ', C], Path, G3),
    check('COCOLOG_GREEN_WORKERS=2: 2 out and in, the world\'s 2 after it says 5, 5 after', G3, '2-2-2-5'-0),
    size_run(['COCOLOG_GREEN_WORKERS=300 ', C], Path, G4),
    check('COCOLOG_GREEN_WORKERS=300: 256, the ceiling', G4, '256-256-256-5'-0),
    size_run(['env -u COCOLOG_GREEN_WORKERS ', C], Path, G5),
    ( G5 = Out5-0, atomic_list_concat([cores, B5, C5, '5'], '-', Out5), B5 == C5 -> W5 = yes ; W5 = G5 ),
    check('unset: the cores online, os_cpus/1\'s count, inside as outside', W5, yes),
    size_run(['COCOLOG_GREEN_WORKERS=0 ', C], Path, G6),
    check('COCOLOG_GREEN_WORKERS=0 is no count: the cores, as unset', G6, G5),
    size_run(['COCOLOG_GREEN_WORKERS=abc ', C], Path, G7),
    check('COCOLOG_GREEN_WORKERS=abc is no count: the cores, as unset', G7, G5),
    shl(['rm -rf ', D]).

size_run(Env, Path, Out-Exit) :-
    append(Env, [' run ', Path, ' main 2>&1'], Parts),
    sh_join(Parts, Cmd),
    shell(Cmd, Out, Exit).

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

%% A FINDALL'S SOLUTIONS AND A CAUGHT BALL ARE THE TASK'S OWN. Before
%% 2.11.4 they were copied into the one shared store, and each copy was a
%% write that stopped the other workers: 200,000 solutions cost 1.4 s at
%% two workers and 18 s at sixteen, against 64 ms on one. A caught raise
%% paid the same at 15/198 ms. They now live in private per-engine stores
%% (`coco_engine_pstore'/`bst'); this is the ASK 4 ceiling, loose enough
%% for a slow box and impossible for the shared-store path.
private_reads :-
    section('reads and caught raises stay local to the task'),
    scratch(D),
    atom_concat(D, '/private-reads.pl', Path),
    fixture(Path,
            [ 'main :- async_run(probe, _).',
              'probe :- get_time(T0), forall(between(1, 2000, _), findall(X, between(1, 100, X), _)), get_time(T1), Ms is round((T1-T0)*1000), ( Ms < 1000 -> F = fast ; F = slow(Ms) ), get_time(T2), forall(between(1, 2000, _), (catch(nope_undefined(_), _, fail) -> true ; true)), get_time(T3), Es is round((T3-T2)*1000), ( Es < 1000 -> E = fast ; E = slow(Es) ), findall(V, (between(1, 20000, I), V is I * 1.5, (I mod 5000 =:= 0 -> garbage_collect ; true)), Vs), length(Vs, VL), last(Vs, VLast), ( VL =:= 20000, VLast =:= 30000.0 -> V = floats_ok ; V = floats_bad ), write(answer(F-E-V)), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=2 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit),
    check('200,000 findall solutions, 2,000 caught raises and 20,000 floats at two workers',
          Out-Exit, 'answer(fast-fast-floats_ok)'-0),
    shl(['rm -rf ', D]).

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

%% A TASK THAT LEAVES A CLEANUP PENDING (3.1.0): setup_call_cleanup/3's
%% frame is on the task's choice stack when its goal answers, and the
%% worker cuts it as the task ends -- the catcher `!', the cleanup run on
%% the task's own machine before the world goes on. Its write is a store
%% write like any other, so the barrier takes it.

:- dynamic acl_done/2.

acl_task(N) :-
    setup_call_catcher_cleanup(true, member(_, [1, 2]), C, assertz(acl_done(N, C))).

acl_world :- go(acl_task(a), A), go(acl_task(b), B), await_all([A, B]).

acl_go(S) :-
    retractall(acl_done(_, _)),
    async_run(acl_world),
    findall(N-C, acl_done(N, C), L),
    msort(L, S).

cleanups :-
    section('a task that leaves a cleanup pending'),
    answer(acl_go(S1), S1, G1),
    check('each task''s cleanup ran as it ended, its catcher the cut', G1, [a-!, b-!]).

%% A WALK OF retract/1's LIVES THROUGH THE DEATHS IT MAKES (3.28.0): its
%% retry over a clause retracted since is an answer and takes nothing
%% again. A second death would give the clause a later number, and a call
%% another task began after the first one, and has open across the second,
%% would see the clause come back. The walker takes rd(0), then rd(2) in
%% its own goals, and lets the caller begin a call of rd/1 then -- rd(2)
%% dead before it began, rd(1) and rd(3) its answers; it takes rd(1) under
%% the caller's open call, so the caller lives through a death, and walks
%% on to rd(2) and rd(3) while the caller waits on its first answer.

%% One worker is the world where the caller's task starts after the walker
%% has blocked: through 3.27.0 its query start swept the dead under the
%% walker's open call (`coco_tomb_sweep_all'), which then went on from a
%% place that had moved -- a plain call of rd/1 there answered [0,3] for
%% [0,1,3]. Two workers start both tasks at once. Each world is a child.
retract_walks :-
    section('a retract walk and another task\'s call share the logical update view'),
    scratch(D),
    atom_concat(D, '/rd.pl', Path),
    fixture(Path,
            [ ':- dynamic rd/1, rd_walked/1, rd_seen/1.',
              'rd_walker(C1, C2) :-',
              '    (   retract(rd(X)), assertz(rd_walked(X)),',
              '        ( X == 0 -> retract(rd(2)), channel_send(C1, go), channel_recv(C2, _) ; true ),',
              '        fail',
              '    ;   true',
              '    ),',
              '    channel_send(C1, done).',
              'rd_walker2(C1, C2) :-',
              '    (   rd(X), retract(rd(X)), assertz(rd_walked(X)),',
              '        ( X == 0 -> retract(rd(2)), channel_send(C1, go), channel_recv(C2, _) ; true ),',
              '        fail',
              '    ;   true',
              '    ),',
              '    channel_send(C1, done).',
              'rd_caller(C1, C2) :-',
              '    channel_recv(C1, go),',
              '    (   rd(Y), assertz(rd_seen(Y)),',
              '        ( Y == 1 -> channel_send(C2, first), channel_recv(C1, done) ; true ),',
              '        fail',
              '    ;   true',
              '    ).',
              'rd_world(Walker) :-',
              '    channel(C1), channel(C2),',
              '    go(call(Walker, C1, C2), W), go(rd_caller(C1, C2), K),',
              '    await_all([W, K]).',
              'rd_go(Walker) :-',
              '    retractall(rd(_)), retractall(rd_walked(_)), retractall(rd_seen(_)),',
              '    forall(between(0, 3, I), assertz(rd(I))),',
              '    async_run(rd_world(Walker)),',
              '    findall(X, rd_walked(X), Walked), findall(Y, rd_seen(Y), Seen),',
              '    write(Walked-Seen), nl.',
              'main :- rd_go(rd_walker), rd_go(rd_walker2).' ]),
    cocolog(C),
    forall(member(N-Label, [1-'one worker', 2-'two workers']),
           ( sh_join(['COCOLOG_GREEN_WORKERS=', N, ' ', C, ' run ', Path, ' main 2>&1'], Cmd),
             shell(Cmd, Out, Exit),
             atom_concat(Label, ': the walk answers every clause it began with, the call no clause dead when it began, and a plain call of the walker is on its place', Says),
             check(Says, Out-Exit, '[0,1,2,3]-[1,3]\n[0,1,3]-[1,3]'-0) )),
    shl(['rm -rf ', D]).

%% A DEAD CLAUSE'S CODE THAT ANOTHER TASK'S ENVIRONMENT IS PART WAY
%% THROUGH IS NOT FREED (3.28.0). Task A enters a clause whose body has an
%% environment (its `;') and waits in it; task B retracts the clause, whose
%% code the store retires, and then collects its heap, or starts a task of
%% its own. Through 3.27.0 each freed the code -- B's mark finds B's heap's
%% environments alone, and a query start took every retired code -- and A
%% went on in freed memory: valgrind's memcheck reported twelve invalid
%% reads and writes either way. Where the box has no valgrind the section
%% says so.
retired_codes :-
    section('a retired clause code outlives another task\'s collection and start'),
    (   sh_exit('command -v valgrind >/dev/null 2>&1', 0)
    ->  scratch(D),
        atom_concat(D, '/uaf.pl', Path),
        fixture(Path,
                [ ':- dynamic ra/2, ra_done/0.',
                  'ra(C1, C2) :- channel_send(C1, entered), channel_recv(C2, _), ( true ; true ), !, assertz(ra_done).',
                  'killer(C1, C2, How) :-',
                  '    channel_recv(C1, entered),',
                  '    retract((ra(_, _) :- _)),',
                  '    ( How == gc -> garbage_collect ; How == start -> go(true, F), await(F, _) ; true ),',
                  '    channel_send(C2, go).',
                  'world(How) :- channel(C1), channel(C2), go(ra(C1, C2), A), go(killer(C1, C2, How), K), await_all([A, K]).',
                  'main :- current_prolog_flag(argv, [_, How|_]),',
                  '        async_run(world(How)), ( ra_done -> write(done) ; write(not_done) ), nl.' ]),
        cocolog(C),
        forall(member(How, [gc, start]),
               ( sh_join(['COCOLOG_GREEN_WORKERS=2 valgrind -q --error-exitcode=9 ', C,
                          ' -s ', Path, ' -- ', How, ' 2>&1'], Cmd),
                 shell(Cmd, Out, Exit),
                 atom_concat('memcheck reads no freed code after the other task\'s ', How, Says),
                 check(Says, Out-Exit, done-0) )),
        shl(['rm -rf ', D])
    ;   format("   SKIP (no valgrind here)~n", [])
    ).

%% ---- the world's end (3.62.1) --------------------------------------------
%%
%% WHEN THE MAIN TASK ENDS THE WORLD STOPS, as a Go program ends when main
%% returns: every worker leaves at its next safe point, whatever is still
%% ready, running or waiting. Three shapes did not end through 3.62.0, so
%% each is a child with a ceiling, and a red run is an exit of 124:
%%
%%   all     a task that never ends on EVERY worker, the main's own among
%%           them: the main's worker went on running what was ready on it,
%%           and async_run/1 never returned (three runs in three);
%%   beside  a task that WRITES for ever on each worker beside the
%%           main's, twelve worlds: a write asked `main_done' with no lock
%%           and was published as the world ended, counting workers
%%           already gone, the host in pthread_join among them -- nobody
%%           was left to acknowledge it (eight runs in eight: five hung,
%%           three were a SIGSEGV, a write still running as the host took
%%           the world's tables back);
%%   nested  a task waiting inside findall/3 for one that never ends: the
%%           wait saw the other still marked ready, its worker gone, and
%%           slept for ever (three in three).
%%
%% Four workers whatever the box has, so the shapes are the same anywhere.
world_end :-
    section('when the main task ends the world stops'),
    scratch(D),
    atom_concat(D, '/end.pl', Path),
    fixture(Path,
            [ 'we_spin :- we_spin.',
              'we_write :- nb_setval(we_k, 1), we_write.',
              'we_children(0, _) :- !.',
              'we_children(K, G) :- go(G), K1 is K - 1, we_children(K1, G).',
              'we_wait(F) :- findall(R, await(F, R), _).',
              'we(all) :- async_workers(N), async_run(( we_children(N, we_spin), true )).',
              'we(beside) :- async_workers(N), N1 is N - 1,',
              '    forall(between(1, 12, _), async_run(( we_children(N1, we_write), true ))).',
              'we(nested) :- async_run(( go(we_spin, F), go(we_wait(F)), ''$green_foreign_sleep''(100), true )).',
              'main :- current_prolog_flag(argv, [_, How|_]), we(How), write(done), nl.' ]),
    cocolog(C),
    forall(member(How-Says,
                  [ all-'a task that never ends on every worker, the main\'s own too',
                    beside-'tasks that write for ever as the world ends, twelve worlds',
                    nested-'a task waiting inside findall/3 for one that never ends' ]),
           ( sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' -s ', Path, ' -- ', How, ' 2>&1'], Cmd),
             shell(Cmd, Out, Exit, 30000),
             check(Says, Out-Exit, done-0) )),
    shl(['rm -rf ', D]).

%% A HALT IN A TASK IS THE PROCESS'S (3.62.1), as swipl's halt/1 ends the
%% process from whatever called Prolog and as a nested search hands one up
%% (3.57.0). Through 3.62.0 the task was read as failed, async_run/1
%% failed, and the program went on: each of these exited 1.
halts :-
    section('halt/1 in a green task halts the process'),
    scratch(D),
    atom_concat(D, '/halt.pl', Path),
    fixture(Path,
            [ 'hl_spin :- hl_spin.',
              'hl(main) :- async_run(( write(a), nl, halt(3) )).',
              'hl(child) :- async_run(( go(halt(4), F), await(F, _) )).',
              'hl(nested) :- async_run(findall(x, halt(5), _)).',
              'hl(beside) :- async_run(( go(hl_spin), go(hl_spin), go(hl_spin), go(hl_spin), halt(6) )).',
              'main :- current_prolog_flag(argv, [_, How|_]), ( hl(How) -> true ; true ), write(after), nl.' ]),
    cocolog(C),
    forall(member(How-(Says-Want),
                  [ main-('the main task\'s halt(3): its output, then the code'-(a-3)),
                    child-('a child\'s halt(4), the main awaiting it'-(''-4)),
                    nested-('halt(5) inside findall/3 inside a task'-(''-5)),
                    beside-('halt(6) beside tasks that never end'-(''-6)) ]),
           ( sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' -s ', Path, ' -- ', How, ' 2>&1'], Cmd),
             shell(Cmd, Out, Exit, 30000),
             check(Says, Out-Exit, Want) )),
    shl(['rm -rf ', D]).

%% EVERY TASK OF A WORLD MAY WAIT ON ONE CHANNEL (3.62.1). A channel's two
%% lists of waiters held 64 ids: the 65th waiter's was written over the
%% count beside the array, the waiters were lost, and the world called
%% itself dead -- resource_error(deadlock), three runs in three, and 64
%% waiters answered. ONE WORKER makes the shape exact: the main's yield
%% runs each child once, and each blocks, before the main serves any.
waiters :-
    section('a hundred tasks wait on one channel'),
    scratch(D),
    atom_concat(D, '/waiters.pl', Path),
    fixture(Path,
            [ 'wt_tx(0, _, []) :- !.',
              'wt_tx(K, C, [F|Fs]) :- go(channel_send(C, K), F), K1 is K - 1, wt_tx(K1, C, Fs).',
              'wt_rx(0, _, []) :- !.',
              'wt_rx(K, C, [F|Fs]) :- go(channel_recv(C, _), F), K1 is K - 1, wt_rx(K1, C, Fs).',
              'wt_take(0, _, 0) :- !.',
              'wt_take(K, C, S) :- channel_recv(C, V), K1 is K - 1, wt_take(K1, C, S1), S is S1 + V.',
              'wt_give(0, _) :- !.',
              'wt_give(K, C) :- channel_send(C, K), K1 is K - 1, wt_give(K1, C).',
              'wt_got([], 0).',
              'wt_got([F|Fs], S) :- await(F, channel_recv(_, V)), wt_got(Fs, S1), S is S1 + V.',
              'wt_world(S, R) :-',
              '    channel(C1), wt_tx(100, C1, Txs), yield, wt_take(100, C1, S), await_all(Txs),',
              '    channel(C2), wt_rx(100, C2, Rxs), yield, wt_give(100, C2), wt_got(Rxs, R).',
              'main :- catch(( async_run(wt_world(_, _), W), W = wt_world(S, R) ),',
              '              error(E, _), ( S = E, R = E )),',
              '        write(S-R), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=1 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit, 60000),
    check('100 blocked senders and 100 blocked receivers, each served once',
          Out-Exit, '5050-5050'-0),
    shl(['rm -rf ', D]).

%% A SEND THAT BLOCKED HEARS HOW IT ENDED (3.62.1). A send with nobody
%% to take it suspends its task, and what becomes of it -- taken, or the
%% channel closed under it -- is read into the cell the send left for it.
%% The send that blocked inside a nested search left one; the plain one
%% did not, and its answer went to the cell of the task's LAST wait, or,
%% a task that had not waited yet, to its heap's first cell -- for a goal
%% read from text, the goal's first variable. So a world whose main task
%% blocked in channel_send/2 came back with that variable bound to
%% `'$async'(ok)' (and failed where it meant to bind it), and a send on a
%% channel closed under it heard nothing, which reads as sent. The
%% receiver and the closer sleep first, so the send does block.
send_status :-
    section('a send that blocked hears how it ended'),
    scratch(D),
    atom_concat(D, '/send.pl', Path),
    fixture(Path,
            [ 'ss_recv(C) :- ''$green_foreign_sleep''(20), channel_recv(C, _).',
              'ss_close(C) :- ''$green_foreign_sleep''(20), channel_close(C).',
              'ss_taken(R) :- channel(C), go(ss_recv(C)), channel_send(C, hello), R = sent.',
              'ss_closed(R) :- channel(C), go(ss_close(C)),',
              '    catch(( channel_send(C, hello), R = sent ),',
              '          error(permission_error(send, channel, closed), _), R = closed).',
              'main :- current_prolog_flag(argv, [_, How|_]), G =.. [How, _],',
              '        ( catch(async_run(G, W), E, W = raised(E)) -> true ; W = failed ),',
              '        write(W), nl.' ]),
    cocolog(C),
    forall(member(How-(Says-Want),
                  [ ss_taken-('taken by a receiver that came later: the goal\'s own variable is the goal\'s'-'ss_taken(sent)'),
                    ss_closed-('the channel closed under it: the send raises'-'ss_closed(closed)') ]),
           ( sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' -s ', Path, ' -- ', How, ' 2>&1'], Cmd),
             shell(Cmd, Out, Exit, 30000),
             check(Says, Out-Exit, Want-0) )),
    shl(['rm -rf ', D]).

%% WHAT ANOTHER TASK WROTE IS READ WITH THE NAMES IT WAS WRITTEN WITH
%% (3.62.1). A task's machine syncs the world's name and value tables when
%% its quantum begins; inside one it went on unsynced past two points where
%% another task's write had landed:
%%
%%   a write of its own   it acknowledged the other's write while it
%%                        waited for its turn, then read on: the other's
%%                        new atom was `<bad-atom>', its float and its big
%%                        integer whatever a stale array held (six runs in
%%                        six; one in six of the numbers a SIGSEGV);
%%   a foreign call       in the MAIN task, whose sync after one synced the
%%                        host's machine and not its own (six in six).
%%
%% The maker interns an atom, makes a float, a string and an integer past
%% the cell's sixty bits, and puts the four in a global; the writer writes
%% a global of its own and reads the maker's; the main task sleeps in a
%% foreign call and reads it. Three workers: one each.
names :-
    section('a task reads the names another task wrote'),
    scratch(D),
    atom_concat(D, '/names.pl', Path),
    fixture(Path,
            [ 'nm_make(K, K) :- !.',
              'nm_make(I, K) :-',
              '    atom_concat(nm_, I, A), X is I * 1.5, B is 4611686018427387904 + I,',
              '    number_codes(I, Ds), string_codes(S, [0''s|Ds]),',
              '    nb_setval(nm_latest, v(I, A, X, B, S)), I1 is I + 1, nm_make(I1, K).',
              'nm_ok(v(I, A, X, B, S)) :-',
              '    atom_codes(A, [0''n, 0''m, 0''_|Ds]), number_codes(I, Ds),',
              '    X =:= I * 1.5, B - 4611686018427387904 =:= I,',
              '    string_codes(S, [0''s|Ds]).',
              'nm_writer(0, ok) :- !.',
              'nm_writer(K, R) :-',
              '    nb_setval(nm_tick, K), nb_getval(nm_latest, V),',
              '    ( nm_ok(V) -> K1 is K - 1, nm_writer(K1, R) ; R = bad ).',
              'nm_sleeper(0, ok) :- !.',
              'nm_sleeper(K, R) :-',
              '    ''$green_foreign_sleep''(1), nb_getval(nm_latest, V),',
              '    ( nm_ok(V) -> K1 is K - 1, nm_sleeper(K1, R) ; R = bad ).',
              'nm_world(RW, RS) :-',
              '    go(nm_make(1, 4000), F), go(nm_writer(4000, _), G),',
              '    nm_sleeper(100, RS), await(F), await(G, nm_writer(_, RW)).',
              'main :- string_codes(S0, [0''s, 0''0]),',
              '        nb_setval(nm_latest, v(0, nm_0, 0.0, 4611686018427387904, S0)), nb_setval(nm_tick, 0),',
              '        async_run(nm_world(_, _), W), W = nm_world(RW, RS),',
              '        write(RW-RS), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=3 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit, 60000),
    check('a writer, and the main task after a foreign call, read atom, float, big and string right',
          Out-Exit, 'ok-ok'-0),
    shl(['rm -rf ', D]).

%% A WRITE BEGINS WHEN THE WORKERS IT COUNTED HAVE STOPPED, AND NOT BEFORE
%% (3.62.1). A worker inside a foreign call is left out of a write's count
%% and, back from the call, waits for the write to clear. It also ADDED AN
%% ACKNOWLEDGEMENT, which the writer took for a counted worker's: with one
%% worker counted and still running, the returning one made the count and
%% the write began under a task that had not stopped -- which then read
%% the store as it changed, and read what the write stored with tables
%% that did not yet know its names. The main task goes in and out of a
%% foreign call as fast as it can; the maker interns an atom and stores
%% it; the reader, a writer too, reads what is stored: `<bad-atom>',
%% eighteen runs in twenty (and ten in ten of 3.62.0).
foreign_ack :-
    section('a worker back from a foreign call adds no acknowledgement'),
    scratch(D),
    atom_concat(D, '/ack.pl', Path),
    fixture(Path,
            [ 'fa_make(K, K) :- !.',
              'fa_make(I, K) :-',
              '    atom_concat(fa_, I, A), nb_setval(fa_latest, I-A), I1 is I + 1, fa_make(I1, K).',
              'fa_ok(I-A) :- atom_codes(A, [0''f, 0''a, 0''_|Ds]), number_codes(I, Ds).',
              'fa_reader(0, ok) :- !.',
              'fa_reader(K, R) :-',
              '    nb_setval(fa_tick, K), nb_getval(fa_latest, V),',
              '    ( fa_ok(V) -> K1 is K - 1, fa_reader(K1, R) ; R = bad ).',
              'fa_foreign(F) :- future_ready(F), !.',
              'fa_foreign(F) :- ''$green_foreign_sleep''(0), fa_foreign(F).',
              'fa_world(R) :-',
              '    go(fa_make(1, 20000), F), go(fa_reader(20000, _), G),',
              '    fa_foreign(G), await(F), await(G, fa_reader(_, R)).',
              'main :- nb_setval(fa_latest, 0-fa_0), nb_setval(fa_tick, 0),',
              '        async_run(fa_world(_), W), W = fa_world(R), write(R), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=3 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit, 60000),
    check('20,000 writes read by a second writer, the main task in and out of a foreign call',
          Out-Exit, ok-0),
    shl(['rm -rf ', D]).

%% A WORKER LEAVING FOR A FOREIGN CALL ANSWERS EVERY WRITE THAT COUNTED IT
%% (3.62.1). It answered the one in flight and waited for it to clear --
%% and the next writer in line published in that moment, counting the
%% worker, which then left for its call with that write unanswered. The
%% writer waited for the call to return; where the call waits for the
%% writer, for ever: the writer holds a mutex across its write, and the
%% call is mutex_lock/1 of that mutex (six runs in six). Three tasks on
%% three workers -- one writes under the mutex, one takes and gives the
%% mutex, one writes all the time -- and the main task waiting for the
%% first two.
foreign_begin :-
    section('a worker leaving for a foreign call answers every write that counted it'),
    (   catch(use_module(library(thread)), _, fail)
    ->  scratch(D),
        atom_concat(D, '/fbegin.pl', Path),
        fixture(Path,
                [ ':- use_module(library(thread)).',
                  'fb_b(_, 0) :- !.',
                  'fb_b(M, N) :- mutex_lock(M), nb_setval(fb_k, N), mutex_unlock(M), N1 is N - 1, fb_b(M, N1).',
                  'fb_a(_, 0) :- !.',
                  'fb_a(M, N) :- mutex_lock(M), mutex_unlock(M), N1 is N - 1, fb_a(M, N1).',
                  'fb_c(_, FB, FA) :- future_ready(FB), future_ready(FA), !.',
                  'fb_c(I, FB, FA) :- nb_setval(fb_c, I), I1 is I + 1, fb_c(I1, FB, FA).',
                  'fb_world(R) :- mutex_create(M),',
                  '    go(fb_b(M, 3000), FB), go(fb_a(M, 3000), FA), go(fb_c(0, FB, FA), FC),',
                  '    await(FB), await(FA), await(FC), R = done.',
                  'main :- ( catch(async_run(fb_world(_), W), E, W = raised(E)) -> true ; W = failed ),',
                  '        ( W = fb_world(R) -> true ; R = W ), write(R), nl.' ]),
        cocolog(C),
        sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' -s ', Path, ' 2>&1'], Cmd),
        shell(Cmd, Out, Exit, 30000),
        check('3,000 writes under a mutex another task takes 3,000 times, beside a third writer',
              Out-Exit, done-0),
        shl(['rm -rf ', D])
    ;   format("     (skipped: no thread module)~n")
    ).

%% THE ATOM TABLE'S BUCKETS ARE NOT FREED UNDER A PROBE (3.62.1). An
%% intern looks its name up with no lock (2.9.2), in the bucket array its
%% machine last synced; a rehash, made under the names' lock by whichever
%% task interned the name that filled the table, FREED that array -- the
%% one table of the shared six that did -- and the other workers' probes
%% read freed memory, an unmapped page once the array was big enough for
%% the allocator to map it: a SIGSEGV, ten runs in ten. One task interns
%% 200,000 new atoms, three intern one that is there.
rehash :-
    section('the atom table rehashes under lock-free lookups'),
    scratch(D),
    atom_concat(D, '/rehash.pl', Path),
    fixture(Path,
            [ 'rh_new(K, K) :- !.',
              'rh_new(I, K) :- atom_concat(rh_, I, A), atom_length(A, _), I1 is I + 1, rh_new(I1, K).',
              'rh_hit(F) :- future_ready(F), !.',
              'rh_hit(F) :- rh_hits(200), rh_hit(F).',
              'rh_hits(0) :- !.',
              'rh_hits(K) :- atom_concat(rh_, hit, A), atom_length(A, _), K1 is K - 1, rh_hits(K1).',
              'rh_world :-',
              '    go(rh_new(0, 200000), F), go(rh_hit(F), G1), go(rh_hit(F), G2), rh_hit(F),',
              '    await(F), await(G1), await(G2).',
              'main :- async_run(rh_world), write(done), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit, 60000),
    check('200,000 new atoms on one worker, lookups of an old one on three',
          Out-Exit, done-0),
    shl(['rm -rf ', D]).

%% A TASK SERVED INSIDE A NESTED WAIT IS NOBODY ELSE'S TO RUN (3.62.1). On
%% one worker the first waiter runs the second from inside its own wait,
%% and the second waits in turn, stacked on the first on the one C stack.
%% A third task then serves the FIRST: it was marked ready, the second's
%% wait picked it and ran its engine again under the call still open on
%% it, finished it and freed its machine -- a SIGSEGV, three runs in three.
%% It stays the waiter's own now. The second's wait can then be answered
%% by nobody (the first cannot go on until the second returns), which is
%% the nested wait's stated limit and its error: resource_error(deadlock)
%% in the second, and the first answers.
stacked :-
    section('a nested wait stacked on another on one worker'),
    scratch(D),
    atom_concat(D, '/stacked.pl', Path),
    fixture(Path,
            [ ':- dynamic st_done/2.',
              'st_wait(K, C) :- findall(X, channel_recv(C, X), L), assertz(st_done(K, L)).',
              'st_world :-',
              '    channel(C1), channel(C2),',
              '    go(st_wait(1, C1), F1), go(st_wait(2, C2), F2), go(channel_send(C1, a), _),',
              '    await(F1, _),',
              '    ( catch(await(F2, _), error(resource_error(W), _), true) -> true ; W = failed ),',
              '    findall(K-L, st_done(K, L), Ds), write(Ds-W), nl.',
              'main :- async_run(st_world).' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=1 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit, 30000),
    check('the first waiter answers once, the second is told it cannot be answered',
          Out-Exit, '[1-[a]]-deadlock'-0),
    shl(['rm -rf ', D]).

%% A WAITER THAT HAS ITS ANSWER AND HAS NOT WOKEN IS NOT A DEAD ONE
%% (3.62.1). Two tasks wait inside findall/3 on two workers: the main for
%% a task to end, a child for the message the main sends once it has. The
%% third task ends, both waiters wake, and the child, first to the lock,
%% asked whether anything could still move: a task done, and a waiter --
%% which read as nothing, so the child was told it could never be
%% answered and the world died of it (twelve runs in thirty: a deadlock
%% raised, or no answer at all). A waiter whose wait is over counts as
%% alive (`coco_g_live'); so does one already handed a message.
live_waiters :-
    section('a waiter with its answer, not yet awake, is alive'),
    scratch(D),
    atom_concat(D, '/live.pl', Path),
    fixture(Path,
            [ 'lv_y(C, R) :- findall(V, channel_recv(C, V), R).',
              'lv_t :- ''$green_foreign_sleep''(30).',
              'lv_send(C) :- ''$green_foreign_sleep''(30), channel_send(C, go).',
              'lv_await(R) :- channel(C2), go(lv_y(C2, _), FY), go(lv_t, FT),',
              '    findall(done, await(FT), X), channel_send(C2, X), await(FY, lv_y(_, R)).',
              'lv_recv(R) :- channel(C1), channel(C2), go(lv_y(C2, _), FY), go(lv_send(C1)),',
              '    findall(V, channel_recv(C1, V), X), channel_send(C2, X), await(FY, lv_y(_, R)).',
              'lv_worlds(_, 0, ok) :- !.',
              'lv_worlds(How, K, R) :- G =.. [How, _],',
              '    (   catch(async_run(G, W), E, W = raised(E)) -> true ; W = failed ),',
              '    (   arg(1, W, [[_]]) -> K1 is K - 1, lv_worlds(How, K1, R) ; R = W ).',
              'main :- current_prolog_flag(argv, [_, How|_]), lv_worlds(How, 12, R), write(R), nl.' ]),
    cocolog(C),
    forall(member(How-Says,
                  [ lv_await-'the awaited task ended: twelve worlds',
                    lv_recv-'the message was handed over: twelve worlds' ]),
           ( sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' -s ', Path, ' -- ', How, ' 2>&1'], Cmd),
             shell(Cmd, Out, Exit, 60000),
             check(Says, Out-Exit, ok-0) )),
    shl(['rm -rf ', D]).

%% A NESTED WAIT THAT GAVE UP HAS LEFT ITS CHANNEL (3.62.1). A receive
%% inside findall/3 that nobody can answer raises the deadlock, and the
%% task that catches it goes on. Its id stayed in the channel's list of
%% receivers: the next send found it there and handed it the message --
%% a task that was waiting for none. Here it is waiting for the SENDER to
%% end, on a channel with room for one: the message was read into the
%% await's answer, the await made nothing of it, and the receive after it
%% found an empty channel (resource_error(deadlock) out of async_run/2,
%% twelve runs in twelve).
gave_up :-
    section('a nested wait that gave up has left its channel'),
    scratch(D),
    atom_concat(D, '/gave.pl', Path),
    fixture(Path,
            [ 'gu_a(C, R) :-',
              '    catch(findall(X, channel_recv(C, X), _), error(resource_error(W), _), true),',
              '    go(channel_send(C, 1), S), await(S), channel_recv(C, Y), R = W-Y.',
              'gu_world(R) :- channel(1, C), go(gu_a(C, _), F), await(F, gu_a(_, R)).',
              'main :- ( catch(( async_run(gu_world(_), Out), Out = gu_world(R) ),',
              '                error(E, _), R = raised(E)) -> true ; R = failed ),',
              '        write(R), nl.' ]),
    cocolog(C),
    forall(member(N, [1, 4]),
           ( sh_join(['COCOLOG_GREEN_WORKERS=', N, ' ', C, ' run ', Path, ' main 2>&1'], Cmd),
             shell(Cmd, Out, Exit, 30000),
             sh_join(['workers ', N, ': the deadlock is caught, and the next message waits for the real receive'], Says),
             check(Says, Out-Exit, 'deadlock-1'-0) )),
    shl(['rm -rf ', D]).

%% A DEAD WORLD SAYS SO THOUGH A NESTED WAIT IS IN IT (3.62.1). A nested
%% waiter sleeps while anything else can still move, and the world's own
%% deadlock check leaves a world with a nested waiter to that waiter. But
%% nothing woke it: when the last task that could move blocked, the check
%% saw the waiter and returned, the waiter slept on, and every worker with
%% it -- async_run/1 never came back (three runs in four). The main task
%% is still running when the waiter first looks, and blocks on it after.
dead_nested :-
    section('a dead world with a nested wait in it'),
    scratch(D),
    atom_concat(D, '/dead.pl', Path),
    fixture(Path,
            [ 'dn_a(C, W) :- catch(findall(X, channel_recv(C, X), _), error(resource_error(W), _), true).',
              'dn_world(W) :- channel(C), go(dn_a(C, _), F), ''$green_foreign_sleep''(50), await(F, dn_a(_, W)).',
              'main :- ( catch(( async_run(dn_world(_), Out), Out = dn_world(R) ),',
              '                error(E, _), R = raised(E)) -> true ; R = failed ),',
              '        write(R), nl.' ]),
    cocolog(C),
    forall(member(N, [1, 4]),
           ( sh_join(['COCOLOG_GREEN_WORKERS=', N, ' ', C, ' run ', Path, ' main 2>&1'], Cmd),
             shell(Cmd, Out, Exit, 20000),
             sh_join(['workers ', N, ': the waiter is woken and raises the deadlock'], Says),
             check(Says, Out-Exit, deadlock-0) )),
    shl(['rm -rf ', D]).

%% A THREAD BESIDE A WORLD SHARES NOTHING WITH IT (3.62.1). The lock on
%% the world's name tables was one pointer for the whole process: a
%% library(thread) thread, whose machine is its own, took the world's mutex
%% at its next intern, and a world that began or ended between that
%% thread's lock and its unlock left it unlocking a mutex it never took, or
%% one destroyed and freed -- a SIGSEGV, four runs in four; two worlds in
%% two threads took each other's (three in four, the fourth a hang). The
%% lock is each world's threads' own.
beside :-
    section('an OS thread, and a second world, beside a world'),
    (   catch(use_module(library(thread)), _, fail)
    ->  scratch(D),
        atom_concat(D, '/beside.pl', Path),
        fixture(Path,
                [ ':- use_module(library(thread)).',
                  'bs_atoms(K, K) :- !.',
                  'bs_atoms(I, K) :- atom_concat(bs_, I, A), atom_length(A, _), I1 is I + 1, bs_atoms(I1, K).',
                  'bs_worlds(0) :- !.',
                  'bs_worlds(K) :- async_run(( go(bs_atoms(0, 300), F), go(bs_atoms(0, 300), G), await(F), await(G) )),',
                  '    K1 is K - 1, bs_worlds(K1).',
                  'bs(thread, S) :- thread_create(bs_atoms(0, 300000), Id), bs_worlds(200), thread_join(Id, S).',
                  'bs(worlds, S) :- thread_create(bs_worlds(60), Id), bs_worlds(60), thread_join(Id, S).',
                  'main :- current_prolog_flag(argv, [_, How|_]), bs(How, S), write(S), nl.' ]),
        cocolog(C),
        forall(member(How-Says,
                      [ thread-'a thread makes 300,000 atoms beside 200 worlds that start and end',
                        worlds-'two threads run sixty worlds each at once' ]),
               ( sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' -s ', Path, ' -- ', How, ' 2>&1'], Cmd),
                 shell(Cmd, Out, Exit, 120000),
                 check(Says, Out-Exit, true-0) )),
        shl(['rm -rf ', D])
    ;   format("     (skipped: no thread module)~n")
    ).

%% THE WORLD IS AS WIDE AS THE THREADS IT WAS GIVEN (3.62.1). A worker the
%% system refuses a thread for ended nothing: tasks were pinned to workers
%% that did not exist and never ran, and the join waited on a thread never
%% made (a hang, three runs in three). The count stops at the first
%% refusal, and async_workers/1 answers what the world got.
%%
%% THE REFUSAL IS MADE OF STACKS ALONE: a worker's stack is the soft stack
%% limit, 512 MB here, under an address-space ceiling of 1.5 GB -- two
%% workers fit beside the caller's thread, the third is refused, and some
%% 400 MB are left for the 300 tasks. (The first cut ran 8 MB stacks into
%% a ceiling of 700 MB: 84 workers and nothing left, and whatever asked
%% for memory next wrote through a null -- the reader's buffer, a write's
%% record, a task's first heap cell. A program out of memory is another
%% matter than a world out of threads.) macOS does not enforce `ulimit
%% -v', and a box that cannot raise its stack limit is skipped by name.
narrow :-
    section('a world narrower than it asked for'),
    shell('uname -s', Sys, _),
    (   Sys == 'Darwin'
    ->  format("   SKIP (macOS does not enforce ulimit -v)~n", [])
    ;   scratch(D),
        atom_concat(D, '/narrow.pl', Path),
        fixture(Path,
                [ 'nr_children(0, []) :- !.',
                  'nr_children(K, [F|Fs]) :- go(atom_length(abc, _), F), K1 is K - 1, nr_children(K1, Fs).',
                  'nr_world(N) :- async_workers(N), nr_children(300, Fs), await_all(Fs).',
                  'main :- async_run(nr_world(_), W), W = nr_world(N),',
                  '        ( N < 256 -> write(narrow) ; write(full) ), nl.' ]),
        cocolog(C),
        sh_join(['ulimit -s 524288 2>/dev/null || { echo nostack; exit 0; }; ',
                 'ulimit -v 1500000; COCOLOG_GREEN_WORKERS=256 ', C, ' run ', Path, ' main 2>&1'], Cmd),
        shell(Cmd, Out, Exit, 30000),
        (   Out == nostack
        ->  format("   SKIP (the stack limit cannot be raised to 512 MB)~n", [])
        ;   check('256 workers asked, the third refused its stack: the world it got runs 300 tasks',
                  Out-Exit, narrow-0)
        ),
        shl(['rm -rf ', D])
    ).
