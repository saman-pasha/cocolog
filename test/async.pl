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
%%   text. shared_store_concurrent is the predicate-creation race, made
%%   likely by shape: a writer's first assert and a call both intern a
%%   predicate. The last six sections are what a task holds across a
%%   write barrier while another writes (3.64.0).
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
    foreign_waits,
    table_growth,
    private_reads,
    channels,
    failures,
    shared_store,
    shared_store_concurrent,
    cleanups,
    retract_walks,
    global_deletes,
    retired_codes,
    world_end,
    halts,
    waiters,
    send_status,
    names,
    foreign_ack,
    foreign_begin,
    rehash,
    same_names,
    rehash_functors,
    stacked,
    live_waiters,
    gave_up,
    dead_nested,
    beside,
    narrow,
    ceiling,
    refusals,
    channel_room,
    no_status,
    dead_running,
    quantum_block,
    moved_preds,
    table_count,
    deep_build,
    deep_unbuild,
    reindex_barrier,
    retry_walks,
    portray_worlds,
    portray_wait,
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

%% A WAIT THAT TOUCHES NO STORE HOLDS NO WRITE (3.64.4). A task makes ready
%% what it waits on, says `go' and waits a second and a half in one of the
%% calls below; a task on another worker hears it, waits 300 ms in a
%% declared foreign call, so that the first is well inside its wait, and
%% times an assertz/1 from the word. Through 3.64.3 none of these waits was
%% declared foreign: each held the write, and every write in the world, for
%% as long as it waited -- the assertz took 1.2 s and more -- and where the
%% task that was to end the wait (an accept, a close) came back from its own
%% foreign call into the write still in flight, for ever. The writer's
%% clauses are warm before the world (a first call compiles, and a compile
%% is a write), so the one write it times is its assertz. Each kind is a
%% child process with a ceiling of 20 s in a world of four workers: the
%% main, the waiter, the writer and the task that ends the wait where
%% somebody must.
foreign_waits :-
    section('a wait that touches no store holds no write'),
    scratch(D),
    (   getenv('ZIGURATIP', Z) -> true
    ;   getenv('HOME', H), atom_concat(H, '/ZiguratIP', Z)
    ),
    atom_concat(Z, '/home/etc/cert', Cert),
    shell('uname -s', Sys, _),
    forall(fw_kind(K, Label, Needs, Lines),
           fw_case(D, Cert, Sys, K, Label, Needs, Lines)),
    shl(['rm -rf ', D]).

fw_case(D, Cert, Sys, K, Label, Needs, Lines) :-
    (   fw_missing(Needs, Cert, Sys, Why)
    ->  format("     (skipped: ~w, ~w)~n", [Label, Why])
    ;   sh_join([D, '/', K, '.pl'], Path),
        sh_join([D, '/', K, '.sock'], Sock),
        sh_join([D, '/', K, '.fifo'], Fifo),
        fw_common(Common),
        append(Lines, Common, All),
        fixture(Path, All),
        cocolog(C),
        (   K == stdin
        ->  Feed = '(sleep 1.5; echo ''x.'') | ', In = ''
        ;   Feed = '', In = ' < /dev/null'
        ),
        sh_join(['rm -f ', Fifo, '; mkfifo ', Fifo, '; ', Feed, 'W_SOCK=', Sock, ' W_FIFO=', Fifo,
                 ' W_CERT=', Cert, ' COCOLOG_GREEN_WORKERS=4 ', C, ' run ', Path, ' main 2>&1', In], Cmd),
        shell(Cmd, Out, Exit, 20000),
        sh_join(['a write is not held by ', Label], Check),
        check(Check, Out-Exit, free-0)
    ).

%% why a kind cannot run here, if it cannot
fw_missing(Needs, Cert, Sys, Why) :-
    member(N, Needs),
    fw_lacks(N, Cert, Sys, Why), !.

fw_lacks(linux, _, Sys, 'a unix connect past a full backlog is refused at once there') :-
    Sys \== 'Linux'.
fw_lacks(cert, Cert, _, Why) :-
    atom_concat(Cert, '/dont-use-certificate.crt', Crt),
    \+ exists_file(Crt),
    sh_join(['no ', Crt], Why).
fw_lacks(M, _, _, Why) :-
    M \== linux, M \== cert,
    sh_join(['library/', M, '.so'], So),
    \+ exists_file(So),
    sh_join(['no ', So], Why).

%% the writer, the waiter, the task that ends the wait and the world: the
%% writer's clauses run once before the world's tasks are made, and its
%% one timed write is its assertz; the waiter's `go' goes to the writer and
%% to the ender, which acts once the waiter is inside its wait (a close
%% made before a send of four megabytes began is no wait ended); `free'
%% when the write took less than a second
fw_common([
    ':- dynamic(w_fact/1).',
    'w_writer(C, Ms, T) :- channel_recv(C, _), get_time(T0), ''$green_foreign_sleep''(Ms), assertz(w_fact(1)), get_time(T1), T is T1 - T0.',
    'w_blocker(C) :- w_prep(P), channel_send(C, go), channel_send(C, go), w_block(P).',
    'w_ender(C) :- channel_recv(C, _), w_after.',
    'w_world(T) :- channel(1, C0), channel_send(C0, warm), w_writer(C0, 0, _), channel(1, C), go(w_blocker(C), F1), go(w_writer(C, 300, _), F2), go(w_ender(C), F3), await(F2, w_writer(_, _, T)), await(F3), await(F1).',
    'main :- async_run(w_world(T), W), W = w_world(T), ( T < 1.0 -> R = free ; R = held(T) ), write(R), nl.' ]).

%% fw_kind(Kind, Label, Needs, Lines): what the waiter makes ready (w_prep),
%% the wait (w_block) and what ends it where somebody must (w_after)
fw_kind(sleep, 'sleep/1', [],
        [ 'w_prep(_).', 'w_block(_) :- sleep(1.5).', 'w_after.' ]).
fw_kind(accept, 'tcp_accept/4', [tcp],
        [ ':- use_module(library(tcp)).',
          'w_prep(S) :- getenv(''W_SOCK'', P), tcp_listen(unix(P), S).',
          'w_block(S) :- ( tcp_accept(S, 1500, _, _) -> true ; true ), tcp_close(S).',
          'w_after.' ]).
fw_kind(read, 'tcp_read/4', [tcp],
        [ ':- use_module(library(tcp)).',
          'w_prep(C-A-S) :- getenv(''W_SOCK'', P), tcp_listen(unix(P), S), tcp_connect(unix(P), C), tcp_accept(S, 2000, A, _).',
          'w_block(C-A-S) :- ( tcp_read(C, 100, 1500, _) -> true ; true ), tcp_close(A), tcp_close(C), tcp_close(S).',
          'w_after.' ]).
fw_kind(write, 'tcp_write/2 to a peer that reads nothing', [tcp],
        [ ':- use_module(library(tcp)).',
          'w_prep(C-L) :- getenv(''W_SOCK'', P), tcp_listen(unix(P), S), tcp_connect(unix(P), C), tcp_accept(S, 2000, A, _), nb_setval(w_peer, A), length(L, 4000000), maplist(=(97), L).',
          'w_block(C-L) :- ( tcp_write(C, L) -> true ; true ), tcp_close(C).',
          'w_after :- ''$green_foreign_sleep''(1500), nb_getval(w_peer, A), tcp_close(A).' ]).
fw_kind(dial, 'tcp_connect/2 past a full backlog', [tcp, linux],
        [ ':- use_module(library(tcp)).',
          'w_fill(_, 0) :- !.',
          'w_fill(P, N) :- tcp_connect(unix(P), _), N1 is N - 1, w_fill(P, N1).',
          'w_prep(P) :- getenv(''W_SOCK'', P), tcp_listen(unix(P), S), nb_setval(w_sock, S), w_fill(P, 65).',
          'w_block(P) :- ( tcp_connect(unix(P), C) -> tcp_close(C) ; true ).',
          'w_after :- ''$green_foreign_sleep''(1500), nb_getval(w_sock, S), tcp_accept(S, 2000, A, _), tcp_close(A).' ]).
fw_kind(run, 'proc_run/4', [process],
        [ ':- use_module(library(process)).',
          'w_prep(_).', 'w_block(_) :- proc_run(''sleep 1.5'', 10000, _, _).', 'w_after.' ]).
fw_kind(wait, 'proc_wait/3', [process],
        [ ':- use_module(library(process)).',
          'w_prep(P) :- proc_spawn(''sleep 1.5'', P).', 'w_block(P) :- proc_wait(P, 10000, _).', 'w_after.' ]).
fw_kind(psleep, 'proc_sleep/1', [process],
        [ ':- use_module(library(process)).',
          'w_prep(_).', 'w_block(_) :- proc_sleep(1500).', 'w_after.' ]).
fw_kind(join, 'thread_join/2', [thread],
        [ ':- use_module(library(thread)).',
          'w_prep(Id) :- thread_create(sleep(1.5), Id).', 'w_block(Id) :- thread_join(Id, _).', 'w_after.' ]).
fw_kind(stdin, 'read/2 of user_input from a pipe', [stream],
        [ ':- use_module(library(stream)).',
          'w_prep(_).', 'w_block(_) :- read(user_input, _).', 'w_after.' ]).
%% a FIFO's three waits apart: the open of one nobody writes to yet, the
%% BOM a text read looks for at the open, and a read
fw_kind(fifo_open, 'open/4 of a FIFO', [stream, process],
        [ ':- use_module(library(stream)).', ':- use_module(library(process)).',
          'w_prep(F) :- getenv(''W_FIFO'', F), atom_concat(''sleep 1.5; echo x. > '', F, Cmd), proc_spawn(Cmd, _).',
          'w_block(F) :- open(F, read, S, [bom(false)]), read(S, _), close(S).',
          'w_after.' ]).
fw_kind(fifo_bom, 'the BOM open/3 of a FIFO looks for', [stream, process],
        [ ':- use_module(library(stream)).', ':- use_module(library(process)).',
          'w_prep(F) :- getenv(''W_FIFO'', F), atom_concat(''exec 3>'', F, C1), atom_concat(C1, ''; sleep 1.5; echo x. >&3'', Cmd), proc_spawn(Cmd, _).',
          'w_block(F) :- open(F, read, S), read(S, _), close(S).',
          'w_after.' ]).
fw_kind(fifo_read, 'read/2 of a FIFO', [stream, process],
        [ ':- use_module(library(stream)).', ':- use_module(library(process)).',
          'w_prep(S) :- getenv(''W_FIFO'', F), atom_concat(''exec 3>'', F, C1), atom_concat(C1, ''; sleep 1.5; echo x. >&3'', Cmd), proc_spawn(Cmd, _), open(F, read, S, [bom(false)]).',
          'w_block(S) :- read(S, _), close(S).',
          'w_after.' ]).
fw_kind(curl, 'curl_get/4 of a server slow to answer', [tcp, curl],
        [ ':- use_module(library(tcp)).', ':- use_module(library(curl)).',
          'w_prep(P) :- getenv(''W_SOCK'', P), tcp_listen(unix(P), S), nb_setval(w_sock, S).',
          'w_block(P) :- ( catch(curl_get(''http://localhost/x'', [unix_socket(P), timeout(10)], _, _), _, true) -> true ; true ).',
          'w_after :- nb_getval(w_sock, S), tcp_accept(S, 2000, A, _), ''$green_foreign_sleep''(1500), atom_codes(''HTTP/1.0 200 OK\\r\\nContent-Length: 2\\r\\n\\r\\nok'', Cs), ( tcp_write(A, Cs) -> true ; true ), tcp_close(A).' ]).
fw_kind(tls, 'tls_accept/5', [tls, cert],
        [ ':- use_module(library(tls)).',
          'w_prep(S-Cs) :- getenv(''W_CERT'', D), atom_concat(D, ''/dont-use-certificate.crt'', Crt), atom_concat(D, ''/dont-use-private.key'', Key), Cs = [certificate(Crt), key(Key)], tls_listen(19473, S).',
          'w_block(S-Cs) :- ( tls_accept(S, 1500, Cs, _, _) -> true ; true ), tls_close(S).',
          'w_after.' ]).

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

%% A DELETE OF A GLOBAL STOPS THE WORLD (3.68.0): nb_delete/1 moves the
%% store's entries after the one it takes down and puts the hash back from
%% them, and a task reading a global meanwhile probes that hash. Five
%% thousand globals are made before the world, one task sets and deletes a
%% key of its own two thousand times, and three tasks read the five
%% thousand until it is done: with no barrier around the delete, a read
%% found no entry for a global that was there all along (existence_error,
%% three runs in three). A child with a ceiling, as a hang would be.
global_deletes :-
    section('a delete of a global under reads in other tasks'),
    scratch(D),
    atom_concat(D, '/gd.pl', Path),
    fixture(Path,
            [ 'gd_make :- forall(between(1, 5000, I), ( atom_concat(gd_s, I, K), nb_setval(K, s(I)) )).',
              'gd_writer(0) :- !, nb_setval(gd_done, 1).',
              'gd_writer(N) :- nb_setval(gd_c, c(N)), nb_delete(gd_c), N1 is N - 1, gd_writer(N1).',
              'gd_reader(I) :-',
              '    (   nb_current(gd_done, _) -> true',
              '    ;   atom_concat(gd_s, I, K), nb_getval(K, s(I)),',
              '        I1 is I mod 5000 + 1, gd_reader(I1)',
              '    ).',
              'gd_world :-',
              '    go(gd_writer(2000), W), go(gd_reader(1), R1), go(gd_reader(1700), R2),',
              '    go(gd_reader(3400), R3), await_all([W, R1, R2, R3]).',
              'main :-',
              '    gd_make,',
              '    catch(( async_run(gd_world) -> R = done ; R = failed ), E, R = caught(E)),',
              '    print(R), nl.' ]),
    cocolog(C),
    sh_join([C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit),
    check('every read finds its global while another task deletes one of its own', Out-Exit, done-0),
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

%% A LOCK-FREE LOOK TAKES NO ENTRY PAST WHAT ITS MACHINE SYNCED (3.64.3).
%% The bucket array is the world's, and another task's insert writes a
%% slot into it while this task's probe reads it with no lock: the id there
%% names an atom this task's tables do not hold yet, and through 3.64.2 the
%% probe answered it -- atom_length/2 of an atom the task had just made
%% read `<bad-atom>', six runs in six, since 2.9.2's lock-free hit. Four
%% tasks intern the same 200,000 new atoms in step and read each length
%% back; then make the same 200,000 new functors in step (3.64.3's
%% lock-free functor hit, its atoms made first), read each name and arity
%% back and look each up a second time, which must be the same functor.
%% Each functor is made ONCE: the world adds 200,001 to the table, the
%% names and the environment of sf_loop/3's second clause ('$e'/N), which
%% its first selection compiles. A look that missed and inserted without
%% looking again under the lock made a functor again where another task had
%% made it since: four tasks, a task a worker, did so six runs in six, where
%% three did in half the runs.
same_names :-
    section('four tasks make the same new atoms and functors in step'),
    scratch(D),
    atom_concat(D, '/same.pl', Path),
    fixture(Path,
            [ 'sn_loop(K, K, ok) :- !.',
              'sn_loop(I, K, R) :-',
              '    atom_concat(sn_, I, A), atom_length(A, L), atom_length(I, LI),',
              '    ( L =:= LI + 3 -> I1 is I + 1, sn_loop(I1, K, R) ; R = bad(I, L) ).',
              'sn_atoms(K, K) :- !.',
              'sn_atoms(I, K) :- atom_concat(sf_, I, A), atom_length(A, _), I1 is I + 1, sn_atoms(I1, K).',
              'sf_loop(K, K, ok) :- !.',
              'sf_loop(I, K, R) :-',
              '    atom_concat(sf_, I, A), functor(T, A, 1), functor(T, N, Ar), arg(1, T, x), T2 =.. [A, x],',
              '    ( N == A, Ar == 1, T == T2 -> I1 is I + 1, sf_loop(I1, K, R) ; R = bad(I) ).',
              'sn_world(P, R1, R2, R3, R4) :-',
              '    go(call(P, 0, 200000, _), F1), go(call(P, 0, 200000, _), F2),',
              '    go(call(P, 0, 200000, _), F3), call(P, 0, 200000, R4),',
              '    await(F1, call(_, _, _, R1)), await(F2, call(_, _, _, R2)), await(F3, call(_, _, _, R3)).',
              'main :- async_run(sn_world(sn_loop, _, _, _, _), W1), W1 = sn_world(_, A1, A2, A3, A4),',
              '        sn_atoms(0, 200000), statistics(functors, F0),',
              '        async_run(sn_world(sf_loop, _, _, _, _), W2), W2 = sn_world(_, B1, B2, B3, B4),',
              '        statistics(functors, F1), N is F1 - F0,',
              '        write(atoms(A1, A2, A3, A4)-functors(B1, B2, B3, B4, N)), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit, 120000),
    check('each name read back right, each functor found again the same, made once',
          Out-Exit, 'atoms(ok,ok,ok,ok)-functors(ok,ok,ok,ok,200001)'-0),
    shl(['rm -rf ', D]).

%% THE FUNCTOR TABLE'S BUCKETS ARE NOT FREED UNDER A PROBE (3.64.3), as the
%% atom table's are not (3.62.1, `rehash'): a functor's lookup probes the
%% bucket array its machine synced with no lock, and a rehash under the
%% names' lock by the task whose insert filled the table freed it. One task
%% makes 200,000 new functors, three look up an old one.
rehash_functors :-
    section('the functor table rehashes under lock-free lookups'),
    scratch(D),
    atom_concat(D, '/rehashf.pl', Path),
    fixture(Path,
            [ 'rf_new(K, K) :- !.',
              'rf_new(I, K) :- atom_concat(rf_, I, A), functor(_, A, 2), I1 is I + 1, rf_new(I1, K).',
              'rf_hit(F) :- future_ready(F), !.',
              'rf_hit(F) :- rf_hits(200), rf_hit(F).',
              'rf_hits(0) :- !.',
              'rf_hits(K) :- functor(T, rf_hit, 2), functor(T, rf_hit, 2), K1 is K - 1, rf_hits(K1).',
              'rf_world :-',
              '    go(rf_new(0, 200000), F), go(rf_hit(F), G1), go(rf_hit(F), G2), rf_hit(F),',
              '    await(F), await(G1), await(G2).',
              'main :- async_run(rf_world), write(done), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit, 60000),
    check('200,000 new functors on one worker, lookups of an old one on three',
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

%% A WORLD SHORT OF MEMORY SAYS SO (3.62.3). Every text that crosses between
%% tasks is written into a buffer and read out of one, and through 3.62.2 a
%% buffer the allocator refused was a buffer left as it stood: the writer
%% went on, the text came out short of a piece, and it was sent. What came
%% of it depended on where the piece was missing -- a status that did not
%% read (system_error for the awaiter), one that read as another term, a
%% task run on a goal that was not the goal it was given, an await that
%% succeeded with nothing bound; and beside the texts, a write's record, a
%% token's buffer, a machine's first heap cell and its construct mask were
%% each written through, or used, where the allocator had answered nothing
%% (a SIGSEGV, or existence_error(procedure, !/0) for a task whose machine
%% knew no construct). Now a task there is no memory for ends with
%% error(resource_error(memory), _) for its status, a text that could not be
%% written or read is that error where it is asked, and nothing is written
%% through a null.
%%
%% THE CEILING IS THE ADDRESS SPACE'S (`ulimit -v'), and one ceiling proves
%% little: which allocation is the one refused moves with every kilobyte.
%% So each fixture is run under a row of ceilings, from the least at which
%% a small world runs (found first, 2 MB at a time) upwards, and at EVERY
%% one it must print the right answer or `memory' and exit 0 -- or end the
%% way a host out of memory ends, exit 2 and nothing printed. A signal, a
%% ceiling of time, or any other answer is the fault; and both answers
%% must be seen, or the row was no test.
%%
%%   text    one task whose goal carries an atom of four megabytes: its
%%           goal's text, its status and the main task's status are each
%%           that long, so the buffer is what the ceiling refuses
%%   tasks   a thousand tasks that each wait on one channel, closed under
%%           them: what is refused is a machine, a mask, a token, a record
%%   leak    two million sends and receives through a channel with room,
%%           then two million receives from it closed, in the memory a
%%           hundred thousand take and 16 MB: each of the three answers a
%%           send or a closed receive gives at once was a copy never freed,
%%           some 60 bytes a round (116 MB resident where 61 were, between
%%           300,000 rounds and 1.2 million; 44 MB at both now)
%%
%% The three fixtures are fx_text/1, fx_tasks/1 and fx_rounds/1, below, which
%% `refusals' runs too. macOS does not enforce `ulimit -v'.
ceiling :-
    section('a world under a memory ceiling'),
    shell('uname -s', Sys, _),
    (   Sys == 'Darwin'
    ->  format("   SKIP (macOS does not enforce ulimit -v)~n", [])
    ;   scratch(D),
        atom_concat(D, '/ceiling.sh', Sweep),
        fixture(Sweep,
                [ '# ceiling.sh COCOLOG WORKERS FILE SMALL BIG FIRST N STEP: FILE -- BIG',
                  '# under N + 1 address-space ceilings STEP kB apart, the first FIRST kB',
                  '# over the least at which FILE -- SMALL prints ok',
                  'c=$1; w=$2; f=$3; small=$4; big=$5; first=$6; n=$7; step=$8',
                  'run() {',
                  '  o=$( ulimit -v $1; COCOLOG_GREEN_WORKERS=$w timeout 60 $c -s $f -- $2 2>/dev/null )',
                  '  r="$o $?"',
                  '}',
                  'v=16000',
                  'while [ $v -lt 400000 ]; do',
                  '  run $v $small',
                  '  [ "$r" = "ok 0" ] && break',
                  '  v=$((v + 2000))',
                  'done',
                  '[ $v -lt 400000 ] || { echo nofloor; exit 0; }',
                  'bad=""; mem=0; ok=0; i=0',
                  'while [ $i -le $n ]; do',
                  '  run $((v + first + i * step)) $big',
                  '  case "$r" in',
                  '    "ok 0") ok=1;;',
                  '    "memory 0"|" 2") mem=1;;',
                  '    "setup 0") ;;',
                  '    *) bad="$bad +$(( (first + i * step) / 1000 ))MB:$r";;',
                  '  esac',
                  '  i=$((i + 1))',
                  'done',
                  'if [ -n "$bad" ]; then echo "wrong:$bad"',
                  'elif [ $ok = 1 ] && [ $mem = 1 ]; then echo clean',
                  'elif [ $ok = 1 ]; then echo ok',
                  'elif [ $mem = 1 ]; then echo memory',
                  'else echo setup; fi' ]),
        atom_concat(D, '/text.pl', Text), fx_text(Text),
        atom_concat(D, '/tasks.pl', Tasks), fx_tasks(Tasks),
        atom_concat(D, '/leak.pl', Leak), fx_rounds(Leak),
        cocolog(C),
        sh_join(['sh ', Sweep, ' ', C, ' 2 ', Text, ' 4 22 0 24 4000'], Cmd1),
        shell(Cmd1, Out1, _, 600000),
        check('a status of four megabytes under 25 ceilings: its answer or resource_error(memory)',
              Out1, clean),
        sh_join(['sh ', Sweep, ' ', C, ' 2 ', Tasks, ' 4 1000 0 12 3000'], Cmd2),
        shell(Cmd2, Out2, _, 600000),
        check('a thousand tasks under 13 ceilings: every await fails or raises resource_error(memory)',
              Out2, clean),
        sh_join(['sh ', Sweep, ' ', C, ' 1 ', Leak, ' 100000 2000000 16000 0 1'], Cmd3),
        shell(Cmd3, Out3, _, 600000),
        check('two million sends and closed receives in the memory of a hundred thousand and 16 MB',
              Out3, ok),
        shl(['rm -rf ', D])
    ).

%% THE FIXTURES OF `ceiling' AND `refusals'. Each brackets its world with two
%% marks, a getenv/2 of a name nobody set: nothing to a run under a ceiling,
%% and to test/refuse.c where its count begins and ends. The end is marked
%% three times over, because the mark asks for memory itself (the name's
%% text) and may be refused it, twice where two requests in a row are.

%% the atom is made, and measured, BEFORE the world: a text builtin short
%% of memory is another fixture's matter (`texts'), not this one's
%% (`setup')
fx_text(Path) :-
    fixture(Path,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'tx_atom(0, A, A) :- !.',
              'tx_atom(D, A0, A) :- atom_concat(A0, A0, A1), D1 is D - 1, tx_atom(D1, A1, A).',
              'tx_task(A, A).',
              'tx_world(A, R) :-',
              '    (   catch(go(tx_task(A, _), F), E0, true)',
              '    ->  (   nonvar(E0) -> tx_error(E0, R)',
              '        ;   catch(await(F, T), E, true)',
              '        ->  (   nonvar(E) -> tx_error(E, R)',
              '            ;   T = tx_task(_, B), B == A -> R = ok',
              '            ;   R = bad',
              '            )',
              '        ;   R = failed',
              '        )',
              '    ;   R = failed',
              '    ).',
              'tx_error(error(resource_error(memory), _), memory) :- !.',
              'tx_error(error(E, _), E).',
              'main :- current_prolog_flag(argv, [_, DA|_]), atom_number(DA, D),',
              '        (   catch(tx_atom(D, a, A), _, fail), atom_length(A, L), L =:= 1 << D',
              '        ->  rf_mark(''REFUSE_ON''),',
              '            ( catch(async_run(tx_world(A, _), W), E, W = raised(E)) -> true ; W = failed ),',
              '            rf_off,',
              '            (   var(W) -> R = lost',
              '            ;   W = tx_world(_, R) -> true',
              '            ;   W = raised(E1) -> tx_error(E1, R)',
              '            ;   R = W',
              '            )',
              '        ;   R = setup',
              '        ),',
              '        write(R), nl.' ]).

%% a task whose receive finds the channel closed FAILS, and so does its
%% await: an await that succeeds was handed no status, and one that raises
%% anything but memory was handed a wrong one
fx_tasks(Path) :-
    fixture(Path,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'tk_task(N, C) :- numlist(1, N, L), channel_recv(C, _), length(L, _).',
              'tk_spawn(0, _, _, []) :- !.',
              'tk_spawn(K, N, C, [F|Fs]) :- go(tk_task(N, C), F), K1 is K - 1, tk_spawn(K1, N, C, Fs).',
              'tk_world(K, N, R) :- channel(C), tk_spawn(K, N, C, Fs), yield, channel_close(C),',
              '    tk_wait(Fs, 0-0-0, R).',
              'tk_wait([], R, R).',
              'tk_wait([F|Fs], Ok-Mem-Err, R) :-',
              '    (   catch(await(F), E, true)',
              '    ->  (   var(E) -> Ok1 is Ok + 1, A = Ok1-Mem-Err',
              '        ;   E = error(resource_error(memory), _) -> Mem1 is Mem + 1, A = Ok-Mem1-Err',
              '        ;   Err1 is Err + 1, A = Ok-Mem-Err1',
              '        )',
              '    ;   A = Ok-Mem-Err',
              '    ),',
              '    tk_wait(Fs, A, R).',
              'main :- current_prolog_flag(argv, [_, KA|_]), atom_number(KA, K),',
              '        rf_mark(''REFUSE_ON''),',
              '        ( catch(async_run(tk_world(K, 60, _), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   var(W) -> R = lost',
              '        ;   W = tk_world(_, _, 0-0-0) -> R = ok',
              '        ;   W = tk_world(_, _, 0-_-0) -> R = memory',
              '        ;   W = raised(error(resource_error(memory), _)) -> R = memory',
              '        ;   W = tk_world(_, _, R0) -> R = answered(R0)',
              '        ;   R = W',
              '        ),',
              '        write(R), nl.' ]).

%% the world answers the count it was given, which it binds last: a world
%% that says it succeeded and bound nothing is `lost', not ok
fx_rounds(Path) :-
    fixture(Path,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'lk_fill(0, _) :- !.',
              'lk_fill(K, C) :- channel_send(C, m(K)), channel_recv(C, m(K)), K1 is K - 1, lk_fill(K1, C).',
              'lk_drain(0, _) :- !.',
              'lk_drain(K, C) :- \\+ channel_recv(C, _), K1 is K - 1, lk_drain(K1, C).',
              'lk_world(K, D) :- channel(1, C), lk_fill(K, C), channel_close(C), lk_drain(K, C), D = K.',
              'main :- current_prolog_flag(argv, [_, KA|_]), atom_number(KA, K),',
              '        rf_mark(''REFUSE_ON''),',
              '        ( catch(async_run(lk_world(K, _), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   var(W) -> R = lost',
              '        ;   W = lk_world(_, D), D == K -> R = ok',
              '        ;   W = raised(error(resource_error(memory), _)) -> R = memory',
              '        ;   R = W',
              '        ),',
              '        write(R), nl.' ]).

%% EVERY ALLOCATION OF A WORLD, REFUSED IN TURN (3.62.3). A ceiling refuses
%% what is big -- a buffer, a machine's arrays, a thread's stack -- and
%% seldom the thirty-two bytes of a status's copy or a variable map's first
%% table, which the allocator hands out of memory it already holds.
%% test/refuse.c is a shim put before glibc's allocator (LD_PRELOAD) that
%% counts the requests a program makes between two marks and answers the
%% N-th with nothing: each fixture is run once to count, and then once for
%% EVERY request it made, that one refused. Each run must print its answer
%% or `memory' and exit 0, or end as a host out of memory ends, exit 2 and
%% nothing printed. Anything else is the fault, and both answers must be
%% seen, or the row was no test. With one worker the N-th request is the
%% same request in every run; with two it is whichever thread asked N-th.
%%
%% AND TWO IN A ROW. An array of the machine's or the store's that is
%% refused its doubling asks again for less and is given it
%% (`coco_grow_short', `coco_store_grow'), so one refusal never refuses
%% such a growth outright: the engine is stopped, and raises
%% resource_error(memory), with every array whole. The N-th request and
%% the one after it refused is the growth refused, a machine or a store
%% with no room at all -- where a put must be all of its term or none, and
%% a machine that could not grow is finished, not wrong. (A walk's stack
%% and a builtin's own scratch ask once: one refusal finishes the machine
%% there, which is the end of a host's run.)
%%
%% What the rows found that the ceilings had not, each in the ENGINE and
%% each a wrong answer with no error: a clause compiled with one variable
%% numbered twice where the compiler's map had no room (`lk_world(50, 0)'
%% of a world that counted fifty), a copy and a stored term the same, a put
%% that linked half a term into the one store, nb_setval/2 failing where
%% its table could not grow; and with two in a row, assertz/1 failing where
%% its predicate had no room for a clause, and a unification failing where
%% it had none for its pairs -- a clause that was there not matched, a
%% program's other branch taken. A machine that lost a variable, or that
%% could not unify or assert for want of memory, is finished now (out of
%% memory), a clause the compiler has no map for is matched in the store,
%% and a put is all of its term or none.
%%
%% AND A TEXT SHORT OF A PIECE. A character buffer that was refused room
%% kept what it had and its builtin went on: atom_concat/3 made the atom
%% of a text short of its second half, atom_length/2 and string_length/2
%% counted it, and a task's goal failed for it with nothing said (the
%% walks: one refusal was enough). A buffer asks again for what it needs
%% now, as an array does -- the text whole and resource_error(memory)
%% raised -- and one refused that too finishes the machine it was written
%% on.
%%
%%   tasks   four tasks waiting on a channel closed under them
%%   text    a task whose goal and status carry an atom of 64 characters
%%   rounds  four sends and receives through a channel with room, and four
%%           receives from it closed
%%   store   three tasks that each assert, set a global, collect, copy and
%%           throw a term with a variable written twice, which must come
%%           back ONE variable -- to the task, and in the store afterwards
%%   mix     a receiver served and a sender taken, a task that throws and
%%           one that fails, a wait inside findall/3 on a task and on a
%%           channel. A task there is no memory for can leave the others
%%           waiting for ever, which the world reports: `deadlock' is an
%%           answer of this row.
%%   walks   tasks that copy, collect, assert and read back a list of
%%           hundreds, take the variables of as many, and make names of
%%           text: atom_concat/3 three ways, atom_number/2, atom_codes/2,
%%           atom_length/2, string_concat/3, string_length/2 and functor/3
%%           of each, every answer held to the others
%%   texts   a task that makes names of text past a buffer's first 64
%%           characters and catches what it is refused
%%   reads   a task that reads terms from text, variables written twice
%%           among them, nine in one term
%%   big     a goal, a status and a status read back of ten thousand
%%           characters, one mode a run
%%   consult a file the HOST consults between the marks: clauses with a
%%           variable written twice, nine variables, a first name of a
%%           hundred characters
%%   host    the walks on the HOST's own machine, and before them a
%%           thousand bindings made and undone, a term nested a thousand
%%           deep copied, unified and compared
%%   resume  a waiter handed a status of two thousand numbers, which
%%           its heap has to grow to read: the status or memory, never a
%%           term that is not the status
%%   first   a task that sets three globals -- fifty thousand variables
%%           in one term, and two terms nested hundreds of thousands deep
%%           -- into the ONE store, from a file whose first clause is the
%%           store's first term (below, at the fixture)
%%   ball    a ball its catcher does not take, put a second time into a
%%           store with no room for it (a named run, below)
%%   chan    a message sent and received through a library(thread)
%%           channel by the host: the seam's reader, which has no reader
%%           in hand to ask and no world to watch for it. A message read
%%           across a refusal is `what came back would not read'
%%           (`unread': the module's own error), never another term
%%
%% WHY A HOST'S RUN. A task whose machine was marked out of memory ends
%% with resource_error(memory) for its status whatever its engine did
%% after the mark (`coco_g_run' asks), so no world can show an engine that
%% RAN ON: a binding the trail had no room to record, not undone; a
%% unification that failed for want of its pairs; an atom whose name had
%% no memory for its copy. The host's run shows each -- `failed', or a
%% crash -- where a machine that is finished stops and the run ends.
%%
%% The shim interposes glibc's allocator, so the section is Linux's, and it
%% is skipped by name where there is no C compiler for it.
refusals :-
    section('a world with each of its allocations refused in turn'),
    shell('uname -s', Sys, _),
    shell('getconf GNU_LIBC_VERSION 2>/dev/null', Libc, _),
    (   ( Sys == 'Darwin' ; \+ sub_atom(Libc, 0, _, _, glibc) )
    ->  format("   SKIP (test/refuse.c interposes glibc's allocator)~n", [])
    ;   scratch(D),
        atom_concat(D, '/refuse.so', Shim),
        ( exists_file('tools/cc/cc') -> Compiler = 'tools/cc/cc' ; Compiler = clang ),
        (   sh_join(['command -v ', Compiler, ' >/dev/null 2>&1 || test -x ', Compiler], HaveCc),
            sh_exit(HaveCc, 0)
        ->  sh_join([Compiler, ' -shared -fPIC -O3 -o ', Shim, ' test/refuse.c 2>&1'], Cc),
            shell(Cc, Why, CcExit),
            check('test/refuse.c compiles', CcExit-Why, 0-''),
            ( CcExit =:= 0 -> refusal_rows(D, Shim) ; true )
        ;   format("   SKIP (no C compiler for test/refuse.c)~n", [])
        ),
        shl(['rm -rf ', D])
    ).

refusal_rows(D, Shim) :-
    atom_concat(D, '/refusals.sh', Sweep), fx_sweep(Sweep),
    atom_concat(D, '/tasks.pl', Tasks), fx_tasks(Tasks),
    atom_concat(D, '/text.pl', Text), fx_text(Text),
    atom_concat(D, '/rounds.pl', Rounds), fx_rounds(Rounds),
    atom_concat(D, '/store.pl', Store), fx_store(Store),
    atom_concat(D, '/mix.pl', Mix), fx_mix(Mix),
    atom_concat(D, '/walks.pl', Walks), fx_walks(Walks),
    atom_concat(D, '/texts.pl', Texts), fx_texts(Texts),
    atom_concat(D, '/reads.pl', Reads), fx_reads(Reads),
    atom_concat(D, '/big.pl', Big), fx_big(Big),
    atom_concat(D, '/consult.pl', Consult), fx_consult(Consult),
    atom_concat(D, '/host.pl', Host), fx_host(Host),
    atom_concat(D, '/chan.pl', Chan), fx_chan(Chan),
    atom_concat(D, '/first.pl', First), fx_first(First),
    atom_concat(D, '/resume.pl', Resume), fx_resume(Resume),
    atom_concat(D, '/ball.pl', Ball), fx_ball(Ball),
    refusal_row(Sweep, Shim, 1, Tasks, 4, 1, ok,
                'tasks waiting on a closed channel, one worker: each allocation refused in turn'),
    refusal_row(Sweep, Shim, 2, Tasks, 4, 1, ok,
                'tasks waiting on a closed channel, two workers'),
    refusal_row(Sweep, Shim, 1, Text, 6, 1, ok,
                'a goal and a status of 64 characters, one worker'),
    refusal_row(Sweep, Shim, 2, Text, 6, 1, ok,
                'a goal and a status of 64 characters, two workers'),
    refusal_row(Sweep, Shim, 1, Rounds, 4, 1, ok,
                'sends, receives and closed receives through a channel with room'),
    refusal_row(Sweep, Shim, 1, Store, 3, 1, ok,
                'tasks that assert, set, collect, copy and throw, one worker: a variable written twice stays one'),
    refusal_row(Sweep, Shim, 2, Store, 3, 1, ok,
                'tasks that assert, set, collect, copy and throw, two workers: and the one store sound'),
    refusal_row(Sweep, Shim, 1, Mix, x, 1, deadlock,
                'served, taken, thrown, failed and nested waits, one worker: an answer, memory or a deadlock said'),
    refusal_row(Sweep, Shim, 2, Mix, x, 1, deadlock,
                'served, taken, thrown, failed and nested waits, two workers'),
    refusal_row(Sweep, Shim, 1, Walks, '''1 1200 8''', 1, ok,
                'a task that copies, collects, asserts and makes names of text, one worker: every text whole'),
    refusal_row(Sweep, Shim, 2, Walks, '''2 600 4''', 1, ok,
                'two such tasks, two workers'),
    refusal_row(Sweep, Shim, 1, Texts, 3, 1, died,
                'a task that makes names of text and catches what it is refused: caught, or its machine finished'),
    refusal_row(Sweep, Shim, 1, Reads, 3, 1, died,
                'a task that reads terms from text: a variable written twice is one, or memory said'),
    refusal_row(Sweep, Shim, 1, Consult, x, 1, ok, host,
                'a file the host consults: every clause as written, or its load ended where it was refused, saying so'),
    refusal_row(Sweep, Shim, 1, Host, x, 1, ok, host,
                'the host itself binding and undoing, unifying, copying, collecting and making names: an answer, memory or the end of its run'),
    refusal_row(Sweep, Shim, 1, Tasks, 4, 2, ok,
                'two requests in a row refused: tasks waiting on a closed channel'),
    refusal_row(Sweep, Shim, 1, Text, 6, 2, ok,
                'two in a row: a goal and a status of 64 characters'),
    refusal_row(Sweep, Shim, 1, Rounds, 4, 2, ok,
                'two in a row: sends, receives and closed receives'),
    refusal_row(Sweep, Shim, 1, Store, 3, 2, ok,
                'two in a row: tasks that assert, set, collect, copy and throw'),
    refusal_row(Sweep, Shim, 2, Store, 3, 2, ok,
                'two in a row: the same on two workers'),
    refusal_row(Sweep, Shim, 1, Mix, x, 2, deadlock,
                'two in a row: served, taken, thrown, failed and nested waits'),
    refusal_row(Sweep, Shim, 1, Walks, '''1 1200 8''', 2, ok,
                'two in a row: a task that copies, collects, asserts and makes names of text'),
    refusal_row(Sweep, Shim, 1, Reads, 3, 2, died,
                'two in a row: a task that reads terms from text'),
    refusal_row(Sweep, Shim, 1, Consult, x, 2, ok, host,
                'two in a row: a file the host consults, a clause whose first name is a hundred characters among them'),
    refusal_row(Sweep, Shim, 1, Host, x, 2, ok, host,
                'two in a row: the host itself, a trail with no room to record a binding among them'),
    refusal_row(Sweep, Shim, 1, First, x, 2, ok, host,
                'two in a row: a task whose wide and deep terms the one store has no room for, and the store''s first clause as it was written'),
    refusal_row(Sweep, Shim, 1, Resume, 2000, 2, ok,
                'two in a row: a waiter whose heap has no room to read the status it is handed: memory, never another term'),
    %% THREE, AND FOUR. Three in a row is a cell the store refused and then
    %% a growth given short: the put is still none of its term (`memreq'
    %% keeps the refusal). Four is a text refused its read and the error
    %% named in its place refused its read too, a buffer's two requests
    %% each: nothing can be put in the status cell, and the builtin that
    %% asked raises, a task that cannot be handed its text ends with memory
    %% for its status, and async_run/2 raises -- where each went on with the
    %% cell unbound, which library(async) reads as error(system_error, _).
    refusal_row(Sweep, Shim, 1, First, x, 3, ok, host,
                'three in a row: a cell the one store refused and a growth given short after it: the global all of its term or not there'),
    refusal_row(Sweep, Shim, 1, Tasks, 4, 4, ok,
                'four in a row: a status and the error named in its place both refused their read: memory, never a status unbound'),
    refusal_chan_rows(Sweep, Shim, Chan),
    %% ONE REFUSAL, NAMED. The rows above take whatever a run answers; these
    %% say which answer. A buffer's first request refused is given what it
    %% asks next, so the text is whole and resource_error(memory) is the
    %% task's to catch (`memory'); that one refused too and the machine is
    %% finished, which the task cannot catch (`died') -- and never a goal
    %% that failed on a text short of a piece, 3.62.2's answer to both.
    refusal_one(Shim, 'REFUSE_N=1', Texts, 3, memory,
                'a buffer refused its first request: the text whole, and memory raised where a catch takes it'),
    refusal_one(Shim, 'REFUSE_N=1 REFUSE_RUN=2', Texts, 3, died,
                'a buffer refused what it needed too: the machine it was written on is finished'),
    %% AND A TEXT OF THE WORLD'S OWN THERE IS NO ROOM FOR: every request of
    %% a page or more refused (REFUSE_MIN), a goal, a status and a status
    %% read back of ten thousand characters. The builtin that asked raises
    %% resource_error(memory) and the machine it ran on goes on: the count
    %% is read there, so nothing is finished for it. EVERY ENGINE OF THE
    %% FIXTURE HAS PUSHED A CHOICE POINT BEFORE THE MARK (bg_warm): an
    %% engine's first choice frames are a page too (64 of them, 4 608
    %% bytes), and refused that page a task ends with memory for its status
    %% by another road -- the three checks were green so on a build whose
    %% status writer watched nothing.
    refusal_one(Shim, 'REFUSE_MIN=4096 REFUSE_N=1 REFUSE_RUN=0', Big, write, memory,
                'a goal there is no room to write: go/2 raises memory, and its task goes on'),
    refusal_one(Shim, 'REFUSE_MIN=4096 REFUSE_N=1 REFUSE_RUN=0', Big, status, memory,
                'a status there is no room to write: its await raises memory, and the world goes on'),
    refusal_one(Shim, 'REFUSE_MIN=4096 REFUSE_N=1 REFUSE_RUN=0', Big, read, memory,
                'a status there is no room to read back: its await raises memory, and its task goes on'),
    %% A BALL ITS CATCHER DOES NOT TAKE IS PUT TWICE: into its engine's own
    %% store for the catch to read, and, nothing there taking it, into the
    %% one store for whoever is outside. The second put refused (every
    %% request of 400 KB or more: the one store's growth, which the fixture
    %% has filled to within six hundred cells of), the host must say out of
    %% memory -- through 3.62.2 it read the ball back from where the put was
    %% not, and reported one that nobody threw, `bl_ball([1, ..., 74,
    %% _G1|_G1])'.
    refusal_host(Shim, 'REFUSE_MIN=400000 REFUSE_N=1 REFUSE_RUN=0', Ball, 'ERROR: -g main: out of memory', 2,
                 'a ball its catcher does not take, and no room for it in the one store: out of memory, never a ball nobody threw').

fx_host(Path) :-
    fixture(Path,
            [ ':- dynamic wf/2.',
              'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'hw_list(0, []) :- !.',
              'hw_list(N, [N|T]) :- N1 is N - 1, hw_list(N1, T).',
              'hw_vars(0, []) :- !.',
              'hw_vars(N, [_|T]) :- N1 is N - 1, hw_vars(N1, T).',
              'hw_names(_, 0) :- !.',
              'hw_names(I, J) :-',
              '    atom_concat(I, x, P), atom_concat(P, J, A), atom_concat(P, JA, A), atom_number(JA, J),',
              '    atom_codes(A, Cs), length(Cs, Len), atom_length(A, Len),',
              '    string_concat(s, A, S), string_length(S, SL), SL =:= Len + 1,',
              '    functor(T, A, 2), functor(T, A1, 2), A1 == A,',
              '    X is J * 1.5, X > J,',
              '    J1 is J - 1, hw_names(I, J1).',
              'hw_bind([]).',
              'hw_bind([X|T]) :- X = a, hw_bind(T).',
              'hw_free([]).',
              'hw_free([X|T]) :- var(X), hw_free(T).',
              'hw_deep(0, x) :- !.',
              'hw_deep(N, g(T, N)) :- N1 is N - 1, hw_deep(N1, T).',
              'hw_pass(I, N, M) :-',
              '    hw_deep(N, D), copy_term(D, D2), D = D2, D == D2, compare(=, D, D2),',
              '    hw_list(N, L),',
              '    copy_term(L, C), C == L,',
              '    findall(X, X = L, [F]), F == L,',
              '    assertz(wf(I, L)), wf(I, S), S == L,',
              '    hw_vars(N, Vs), copy_term(Vs-Vs, Cs-Ds), Cs == Ds,',
              '    ( hw_bind(Vs), fail ; true ), hw_free(Vs),',
              '    term_variables(Vs, Ws), length(Ws, N),',
              '    term_variables(Cs, Xs), length(Xs, N),',
              '    ground(L), L = C,',
              '    hw_names(I, M).',
              'main :- \\+ \\+ catch(hw_pass(0, 4, 2), _, true),',
              '        rf_mark(''REFUSE_ON''),',
              '        (   catch(hw_pass(1, 1200, 8), error(resource_error(memory), _), R = memory)',
              '        ->  ( var(R) -> R = ok ; true )',
              '        ;   R = failed',
              '        ),',
              '        rf_off,',
              '        write(R), nl.' ]).

fx_chan(Path) :-
    fixture(Path,
            [ ':- use_module(library(thread)).',
              'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'tc_round(C) :-',
              '    channel_send(C, m(a_name_long_enough_to_pass_the_first_sixty_four_characters_of_a_token_buffer,',
              '                      X, Y, X, Y, [Z|Z], p(V1, _, _, _, _, _, _, _, V9, V1, V9))),',
              '    channel_recv(C, M),',
              '    M = m(A, X1, Y1, X2, Y2, [Z1|Z2], p(B1, _, _, _, _, _, _, _, B9, C1, C9)),',
              '    atom_length(A, 76), X1 == X2, Y1 == Y2, X1 \\== Y1, Z1 == Z2, B1 == C1, B9 == C9, B1 \\== B9.',
              'main :- channel_new(C),',
              '        \\+ \\+ catch(tc_round(C), _, true),',
              '        rf_mark(''REFUSE_ON''),',
              '        (   catch(tc_round(C), E, true)',
              '        ->  (   var(E) -> R = ok',
              '            ;   E = error(resource_error(memory), _) -> R = memory',
              '            ;   E = error(cocolog_error(_), _) -> R = unread',
              '            ;   R = E',
              '            )',
              '        ;   R = failed',
              '        ),',
              '        rf_off,',
              '        write(R), nl.' ]).

%% THE ONE STORE'S FIRST CELLS, AFTER A PUT IT HAD NO ROOM FOR. A compound
%% the store is refused room for leaves no frame (`coco_store_put_node',
%% 3.62.3). Through 3.62.2 its header's push answered 0 and the frame was
%% pushed all the same, its slots at 1: the walk wrote the compound's
%% arguments over the store's cells 1 to N -- another term's -- before the
%% put's end wound the store back. The task that put it is finished; in a
%% world the store is everybody's, and the world goes on with its first
%% term changed.
%%
%% So the fixture is consulted by the host (`cocolog run FILE main': its
%% clauses are in the store before the libraries are read into it), its
%% first clause a fact whose arguments are the store's cells 1 to 8, and a
%% task puts two terms of 150,000 and 300,000 levels, two cells a level,
%% into the one store, which has to grow for each. A header stands at
%% every other cell and a growth falls on an even one, so it falls on a
%% header in the first term or in the second, the two beginning an odd
%% number of cells apart. The task must end with memory for its status,
%% and the fact must read as it was written (`broken' is the row's red).
%%
%% AND A CELL OF ITS OWN. Before them the task puts one term of fifty
%% thousand variables: a header and its slots in one growth, and then a
%% cell a variable, one of which is the cell the store has to grow for.
%% A variable is written in the one push; through 3.62.2 a 0 was pushed
%% and the cell written after by the index the push answered -- 0 for a
%% push refused, so the store's FIRST cell became a variable, and the fact
%% above read back `ff(_, _, ...)' (clause/2 of it still answered, which
%% is why the fixture holds its arguments to what was written). Three in
%% a row is that cell refused and the next growth given short: the put
%% keeps the refusal (`memreq'), where a put that forgot it left the
%% global in the store with one argument naming the store's first cell.
fx_first(Path) :-
    fixture(Path,
            [ 'ff(a1, a2, a3, a4, a5, a6, a7, a8).',
              'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'ff_deep(0, z) :- !.',
              'ff_deep(K, s(T)) :- K1 is K - 1, ff_deep(K1, T).',
              'ff_wide(N, T) :- length(L, N), T =.. [ff_w|L].',
              'ff_task :- ff_wide(50000, T0), nb_setval(ff_c, T0),',
              '    ff_deep(150000, T1), nb_setval(ff_a, T1), ff_deep(300000, T2), nb_setval(ff_b, T2).',
              'ff_world(R) :- go(ff_task, F),',
              '    (   catch(await(F), E, true)',
              '    ->  ( var(E) -> R = ok ; E = error(resource_error(memory), _) -> R = memory ; R = E )',
              '    ;   R = no',
              '    ).',
              'ff_whole :- clause(ff(A, B, C, D, E, F, G, H), true),',
              '    [A, B, C, D, E, F, G, H] == [a1, a2, a3, a4, a5, a6, a7, a8],',
              '    (   nb_current(ff_c, T)',
              '    ->  T =.. [ff_w|As], length(As, 50000), term_variables(As, Vs), length(Vs, 50000)',
              '    ;   true',
              '    ).',
              'main :- rf_mark(''REFUSE_ON''),',
              '        ( catch(async_run(ff_world(_), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   \\+ catch(ff_whole, _, fail) -> R = broken',
              '        ;   W = ff_world(ok) -> R = ok',
              '        ;   W = ff_world(memory) -> R = memory',
              '        ;   W = raised(error(resource_error(memory), _)) -> R = memory',
              '        ;   R = W',
              '        ),',
              '        write(R), nl.' ]).

%% the two rows of a library(thread) channel, where there is the module
refusal_chan_rows(Sweep, Shim, Chan) :-
    (   catch(use_module(library(thread)), _, fail)
    ->  refusal_row(Sweep, Shim, 1, Chan, x, 1, unread,
                    'a message through a library(thread) channel: read whole, or said not to read'),
        refusal_row(Sweep, Shim, 1, Chan, x, 2, unread,
                    'two in a row: a message through a library(thread) channel')
    ;   format("     (skipped: no thread module, a message through its channel)~n")
    ).

%% A WAITER RESUMED WITH A STATUS ITS HEAP HAS NO ROOM TO READ. The main
%% task awaits a task whose answer is a list of N numbers; it blocks, the
%% task ends, and the status is read into the main's machine as the main
%% is run again -- no engine is running on it, so a growth of its heap
%% refused outright marks the machine and stops nothing. The term read
%% across that refusal is built over the heap's first cell; the resume
%% asks the machine before it uses it (`coco_g_resume'), and the task ends
%% with memory for its status. A waiter handed that term instead prints
%% here before its machine is asked: `wrong', or `failed' for an await
%% that no clause of library(async) could read.
fx_resume(Path) :-
    fixture(Path,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'rr_task(N, L) :- numlist(1, N, L).',
              'rr_whole([], K, N) :- K =:= N + 1.',
              'rr_whole([K|T], K, N) :- K1 is K + 1, rr_whole(T, K1, N).',
              'rr_world(N, R) :-',
              '    go(rr_task(N, _), F),',
              '    (   catch(await(F, T), E, true)',
              '    ->  (   nonvar(E) -> ( E = error(resource_error(memory), _) -> R = memory ; R = E )',
              '        ;   T = rr_task(_, L), rr_whole(L, 1, N) -> R = ok',
              '        ;   write(wrong), nl, R = wrong',
              '        )',
              '    ;   write(failed), nl, R = failed',
              '    ).',
              'main :- current_prolog_flag(argv, [_, NA|_]), atom_number(NA, N),',
              '        rf_mark(''REFUSE_ON''),',
              '        ( catch(async_run(rr_world(N, _), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   var(W) -> R = lost',
              '        ;   W = rr_world(_, R0) -> R = R0',
              '        ;   W = raised(error(resource_error(memory), _)) -> R = memory',
              '        ;   R = W',
              '        ),',
              '        write(R), nl.' ]).

%% the one store filled to within six hundred cells of its room, the heap
%% given room to spare, and then a ball of three thousand cells that the
%% catch around it does not take
fx_ball(Path) :-
    fixture(Path,
            [ ':- dynamic bl_pad/1.',
              'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'bl_room(R) :- statistics(store_used, U), statistics(store_cap, C), R is (C - U) // 8.',
              'bl_fill :- bl_room(R),',
              '    (   R < 600 -> true',
              '    ;   N is min(5000, (R - 300) // 4), numlist(1, N, L), assertz(bl_pad(L)), bl_fill',
              '    ).',
              'main :- \\+ \\+ bl_fill, \\+ \\+ numlist(1, 20000, _), numlist(1, 750, L),',
              '        rf_mark(''REFUSE_ON''),',
              '        catch(throw(bl_ball(L)), bl_other, true),',
              '        rf_off,',
              '        write(passed), nl.' ]).

fx_sweep(Path) :-
    fixture(Path,
            [ '# refusals.sh COCOLOG SHIM WORKERS FILE ARG RUN [ALSO] [host]: FILE -- ARG',
              '# once for each allocation it makes between its marks, that one and the',
              '# RUN - 1 after it refused (test/refuse.c). Every run must print ok,',
              '# memory or ALSO and exit 0, or end as a host out of memory ends: exit 2',
              '# and nothing printed. With `host'' FILE is consulted by the host and its',
              '# main/0 run (`cocolog run FILE main''), where no engine runs while it is',
              '# read, and a load refused memory ends where it stands (3.63.2): nothing',
              '# printed, exit 1, `Not enough resources: memory'' its last line -- memory.',
              'c=$1; shim=$2; w=$3; f=$4; a=$5; run=$6; also=${7:-ok}; e=$f.err',
              'if [ "${8:-}" = host ]; then tail="run $f main"; else tail="-s $f -- $a"; fi',
              'n=$( COCOLOG_GREEN_WORKERS=$w REFUSE_REPORT=1 LD_PRELOAD=$shim $c $tail 2>&1 >/dev/null | sed -n ''s/^REFUSE count //p'' )',
              '[ -n "$n" ] && [ "$n" -gt 0 ] || { echo nocount; exit 0; }',
              'bad=""; mem=0; ok=0; i=1',
              'while [ $i -le $((n + 8)) ]; do',
              '  o=$( COCOLOG_GREEN_WORKERS=$w timeout 30 env REFUSE_N=$i REFUSE_RUN=$run LD_PRELOAD=$shim $c $tail 2>$e )',
              '  r="$o $?"',
              '  if [ "$r" = " 1" ] && [ "${8:-}" = host ] && [ "$(tail -n 1 $e)" = "ERROR: Not enough resources: memory" ]; then r=" 2"; fi',
              '  case "$r" in',
              '    "ok 0") ok=1;;',
              '    "memory 0"|" 2") mem=1;;',
              '    "$also 0") ;;',
              '    *) bad="$bad #$i:$r";;',
              '  esac',
              '  i=$((i + 1))',
              'done',
              'if [ -n "$bad" ]; then echo "wrong of $n:$bad" | cut -c1-300',
              'elif [ $ok = 1 ] && [ $mem = 1 ]; then echo clean',
              'elif [ $ok = 1 ]; then echo ok',
              'else echo memory; fi' ]).

fx_store(Path) :-
    fixture(Path,
            [ ':- dynamic sf/3.',
              'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'st_task(I) :- (   I mod 2 =:= 0',
              '              ->  assertz(sf(I, X, X)), nb_setval(st_g, g(Y, Y, I))',
              '              ;   nb_setval(st_g, g(Y, Y, I)), assertz(sf(I, X, X))',
              '              ),',
              '              findall(P-P, member(_, [a, b]), Ps), Ps = [A1-A2, B1-B2], A1 == A2, B1 == B2,',
              '              copy_term(h(Z, Z), h(C1, C2)), C1 == C2,',
              '              findall(Q, member(Q, [_]), [Q1]), var(Q1),',
              '              catch(throw(ball(V, V)), ball(E1, E2), true), E1 == E2,',
              '              sf(I, S1, S2), S1 == S2.',
              'st_spawn(0, []) :- !.',
              'st_spawn(K, [F|Fs]) :- go(st_task(K), F), K1 is K - 1, st_spawn(K1, Fs).',
              'st_world(K, R) :- st_spawn(K, Fs), st_wait(Fs, 0-0-0-0, R).',
              'st_wait([], R, R).',
              'st_wait([F|Fs], Ok-Mem-Err-No, R) :-',
              '    (   catch(await(F), E, true)',
              '    ->  (   var(E) -> Ok1 is Ok + 1, A = Ok1-Mem-Err-No',
              '        ;   E = error(resource_error(memory), _) -> Mem1 is Mem + 1, A = Ok-Mem1-Err-No',
              '        ;   Err1 is Err + 1, A = Ok-Mem-Err1-No',
              '        )',
              '    ;   No1 is No + 1, A = Ok-Mem-Err-No1',
              '    ),',
              '    st_wait(Fs, A, R).',
              'st_sound :- findall(I, clause(sf(I, _, _), true), Is), msort(Is, Sorted), sort(Is, Sorted),',
              '            forall(clause(sf(_, A, B), true), A == B),',
              '            predicate_property(sf(_, _, _), number_of_clauses(N)), length(Is, N),',
              '            ( nb_current(st_g, G) -> G = g(P, Q, _), P == Q ; true ).',
              'main :- current_prolog_flag(argv, [_, KA|_]), atom_number(KA, K),',
              '        rf_mark(''REFUSE_ON''),',
              '        ( catch(async_run(st_world(K, _), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   \\+ st_sound -> R = broken',
              '        ;   var(W) -> R = lost',
              '        ;   W = st_world(_, _-0-0-0) -> R = ok',
              '        ;   W = st_world(_, _-_-0-0) -> R = memory',
              '        ;   W = raised(error(resource_error(memory), _)) -> R = memory',
              '        ;   W = st_world(_, R0) -> R = answered(R0)',
              '        ;   R = W',
              '        ),',
              '        write(R), nl.' ]).

fx_mix(Path) :-
    fixture(Path,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'mx_recv(_, 0) :- !.',
              'mx_recv(C, N) :- channel_recv(C, _), N1 is N - 1, mx_recv(C, N1).',
              'mx_send(_, 0) :- !.',
              'mx_send(C, N) :- channel_send(C, s(N)), N1 is N - 1, mx_send(C, N1).',
              'mx_val(V, V).',
              'mx_pair(_, _).',
              'mx_world(R) :-',
              '    channel(C),',
              '    go(mx_recv(C, 3), F1),',
              '    channel_send(C, a(1)), channel_send(C, b(2)), channel_send(C, c(3)),',
              '    await(F1, mx_recv(_, 3)),',
              '    go(mx_send(C, 2), F2),',
              '    yield,',
              '    channel_recv(C, s(2)), channel_recv(C, s(1)),',
              '    await(F2),',
              '    go(throw(oops(x)), F3), catch(await(F3), oops(X), true), X == x,',
              '    go(fail, F4), \\+ await(F4),',
              '    findall(V, ( go(mx_val(7, _), F5), await(F5, mx_val(_, V)) ), [7]),',
              '    channel(2, D), go(mx_recv(D, 1), F6),',
              '    findall(k, channel_send(D, z(1)), [k]), await(F6),',
              '    go(mx_pair(Z, Z), F7), await(F7, mx_pair(P7, Q7)), P7 == Q7,',
              '    await_all([F1, F2]),',
              '    R = done.',
              'main :- rf_mark(''REFUSE_ON''),',
              '        ( catch(async_run(mx_world(_), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   var(W) -> R = lost',
              '        ;   W = mx_world(D), D == done -> R = ok',
              '        ;   W = raised(error(resource_error(memory), _)) -> R = memory',
              '        ;   W = raised(error(resource_error(deadlock), _)) -> R = deadlock',
              '        ;   R = W',
              '        ),',
              '        write(R), nl.' ]).

fx_walks(Path) :-
    fixture(Path,
            [ ':- dynamic wf/2.',
              'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'wk_list(0, []) :- !.',
              'wk_list(N, [N|T]) :- N1 is N - 1, wk_list(N1, T).',
              'wk_vars(0, []) :- !.',
              'wk_vars(N, [_|T]) :- N1 is N - 1, wk_vars(N1, T).',
              'wk_names(_, 0) :- !.',
              'wk_names(I, J) :-',
              '    atom_concat(I, x, P), atom_concat(P, J, A), atom_concat(P, JA, A), atom_number(JA, J),',
              '    atom_codes(A, Cs), length(Cs, Len), atom_length(A, Len),',
              '    string_concat(s, A, S), string_length(S, SL), SL =:= Len + 1,',
              '    functor(T, A, 2), functor(T, A1, 2), A1 == A,',
              '    X is J * 1.5, X > J,',
              '    J1 is J - 1, wk_names(I, J1).',
              'wk_task(I, N, M) :-',
              '    wk_list(N, L),',
              '    copy_term(L, C), C == L,',
              '    findall(X, X = L, [F]), F == L,',
              '    assertz(wf(I, L)), wf(I, S), S == L,',
              '    wk_vars(N, Vs), term_variables(Vs, Ws), length(Ws, N),',
              '    copy_term(Vs, Cs), term_variables(Cs, Xs), length(Xs, N),',
              '    ground(L), L = C,',
              '    wk_names(I, M).',
              'wk_spawn(0, _, _, []) :- !.',
              'wk_spawn(K, N, M, [F|Fs]) :- go(wk_task(K, N, M), F), K1 is K - 1, wk_spawn(K1, N, M, Fs).',
              'wk_world(K, N, M, R) :- wk_spawn(K, N, M, Fs), wk_wait(Fs, 0-0-0-0, R).',
              'wk_wait([], R, R).',
              'wk_wait([F|Fs], Ok-Mem-Err-No, R) :-',
              '    (   catch(await(F), E, true)',
              '    ->  (   var(E) -> Ok1 is Ok + 1, A = Ok1-Mem-Err-No',
              '        ;   E = error(resource_error(memory), _) -> Mem1 is Mem + 1, A = Ok-Mem1-Err-No',
              '        ;   Err1 is Err + 1, A = Ok-Mem-Err1-No',
              '        )',
              '    ;   No1 is No + 1, A = Ok-Mem-Err-No1',
              '    ),',
              '    wk_wait(Fs, A, R).',
              'wk_sound(N) :- wk_list(N, L), forall(clause(wf(_, S), true), S == L).',
              'main :- current_prolog_flag(argv, [_, KA, NA, MA|_]),',
              '        atom_number(KA, K), atom_number(NA, N), atom_number(MA, M),',
              '        rf_mark(''REFUSE_ON''),',
              '        ( catch(async_run(wk_world(K, N, M, _), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   \\+ wk_sound(N) -> R = broken',
              '        ;   var(W) -> R = lost',
              '        ;   W = wk_world(_, _, _, _-0-0-0) -> R = ok',
              '        ;   W = wk_world(_, _, _, _-_-0-0) -> R = memory',
              '        ;   W = raised(error(resource_error(memory), _)) -> R = memory',
              '        ;   W = wk_world(_, _, _, R0) -> R = answered(R0)',
              '        ;   R = W',
              '        ),',
              '        write(R), nl.' ]).

fx_texts(Path) :-
    fixture(Path,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'tx_names(0) :- !.',
              'tx_names(J) :-',
              '    P = tx_a_name_long_enough_to_pass_the_first_sixty_four_characters_of_a_buffer_,',
              '    atom_concat(P, J, A), atom_concat(P, JA, A), atom_length(JA, 1),',
              '    atom_length(A, Len), atom_codes(A, Cs), length(Cs, Len),',
              '    string_concat(s, A, S), string_length(S, SL), SL =:= Len + 1,',
              '    term_to_atom(f(A, J), T), atom_length(T, TL), TL =:= Len + 5,',
              '    J1 is J - 1, tx_names(J1).',
              'tx_task(M, R) :-',
              '    \\+ \\+ catch(tx_names(M), _, true),',
              '    rf_mark(''REFUSE_ON''),',
              '    catch(( tx_names(M), R = ok ), error(resource_error(memory), _), R = caught),',
              '    rf_off.',
              'tx_world(M, R) :-',
              '    go(tx_task(M, _), F),',
              '    (   catch(await(F, tx_task(_, R0)), E, true)',
              '    ->  ( var(E) -> R = R0 ; E = error(resource_error(memory), _) -> R = died ; R = E )',
              '    ;   R = failed',
              '    ).',
              'main :- current_prolog_flag(argv, [_, MA|_]), atom_number(MA, M),',
              '        ( catch(async_run(tx_world(M, _), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   var(W) -> O = lost',
              '        ;   W = tx_world(_, R), R == ok -> O = ok',
              '        ;   W = tx_world(_, R), R == caught -> O = memory',
              '        ;   W = tx_world(_, R) -> O = R',
              '        ;   W = raised(error(resource_error(memory), _)) -> O = died',
              '        ;   O = W',
              '        ),',
              '        write(O), nl.' ]).

fx_reads(Path) :-
    fixture(Path,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'rd_terms(0) :- !.',
              'rd_terms(J) :-',
              '    term_to_atom(T, ''r(a_name_long_enough_to_pass_the_first_sixty_four_characters_of_a_token_buffer, X, Y, X, Y, [Z|Z], "s")''),',
              '    T = r(A, X1, Y1, X2, Y2, [Z1|Z2], _), atom_length(A, 76),',
              '    X1 == X2, Y1 == Y2, X1 \\== Y1, Z1 == Z2,',
              '    atom_to_term(''p(V1, V2, V3, V4, V5, V6, V7, V8, V9, V1, V9)'', P, Bs), length(Bs, 9),',
              '    P = p(B1, _, _, _, _, _, _, _, B9, C1, C9), B1 == C1, B9 == C9, B1 \\== B9,',
              '    J1 is J - 1, rd_terms(J1).',
              'rd_task(M, R) :-',
              '    \\+ \\+ catch(rd_terms(M), _, true),',
              '    rf_mark(''REFUSE_ON''),',
              '    catch(( rd_terms(M), R = ok ), error(resource_error(memory), _), R = caught),',
              '    rf_off.',
              'rd_world(M, R) :-',
              '    go(rd_task(M, _), F),',
              '    (   catch(await(F, rd_task(_, R0)), E, true)',
              '    ->  ( var(E) -> R = R0 ; E = error(resource_error(memory), _) -> R = died ; R = E )',
              '    ;   R = failed',
              '    ).',
              'main :- current_prolog_flag(argv, [_, MA|_]), atom_number(MA, M),',
              '        ( catch(async_run(rd_world(M, _), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   var(W) -> O = lost',
              '        ;   W = rd_world(_, R), R == ok -> O = ok',
              '        ;   W = rd_world(_, R), R == caught -> O = memory',
              '        ;   W = rd_world(_, R) -> O = R',
              '        ;   W = raised(error(resource_error(memory), _)) -> O = died',
              '        ;   O = W',
              '        ),',
              '        write(O), nl.' ]).

fx_big(Path) :-
    fixture(Path,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'bg_codes(0, []) :- !.',
              'bg_codes(N, [0''a|T]) :- N1 is N - 1, bg_codes(N1, T).',
              'bg_atom(A) :- bg_codes(10000, L), atom_codes(A, L).',
              'bg_warm :- catch(( member(_, [a, b, c]), fail ; true ), _, true).',
              'bg_echo(_) :- bg_warm.',
              'bg_wait(C, _) :- bg_warm, channel_recv(C, _).',
              'bg_world(write, R) :-',
              '    bg_atom(A), rf_off,',
              '    bg_warm, rf_mark(''REFUSE_ON''),',
              '    ( catch(go(bg_echo(A), _), error(resource_error(memory), _), fail) -> R = spawned ; R = caught ),',
              '    rf_off.',
              'bg_world(status, R) :-',
              '    bg_atom(A), channel(C), go(bg_wait(C, A), F), yield, rf_off,',
              '    bg_warm, rf_mark(''REFUSE_ON''),',
              '    channel_send(C, x),',
              '    ( catch(await(F), error(resource_error(memory), _), fail) -> R = awaited ; R = caught ),',
              '    rf_off.',
              'bg_world(read, R) :-',
              '    bg_atom(A), go(bg_echo(A), F), yield, yield, rf_off,',
              '    bg_warm, rf_mark(''REFUSE_ON''),',
              '    ( catch(await(F, bg_echo(_)), error(resource_error(memory), _), fail) -> R = awaited ; R = caught ),',
              '    rf_off.',
              'main :- current_prolog_flag(argv, [_, Mode|_]),',
              '        ( catch(async_run(bg_world(Mode, _), W), E, W = raised(E)) -> true ; W = failed ),',
              '        rf_off,',
              '        (   W = bg_world(_, R), R == caught -> O = memory',
              '        ;   W = bg_world(_, R), nonvar(R) -> O = R',
              '        ;   W = raised(error(resource_error(memory), _)) -> O = died',
              '        ;   O = W',
              '        ),',
              '        write(O), nl.' ]).

refusal_row(Sweep, Shim, Workers, File, Arg, Run, Also, Title) :-
    refusal_row(Sweep, Shim, Workers, File, Arg, Run, Also, task, Title).

refusal_row(Sweep, Shim, Workers, File, Arg, Run, Also, How, Title) :-
    cocolog(C),
    sh_join(['sh ', Sweep, ' ', C, ' ', Shim, ' ', Workers, ' ', File, ' ', Arg, ' ', Run, ' ', Also, ' ', How],
            Cmd),
    shell(Cmd, Out, _, 600000),
    check(Title, Out, clean).

%% one run of FILE -- ARG on one worker under the shim's ENV: what it
%% prints, and that it ends with 0
refusal_one(Shim, Env, File, Arg, Want, Title) :-
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=1 ', Env, ' LD_PRELOAD=', Shim, ' timeout 30 ', C, ' -s ', File, ' -- ', Arg,
             ' 2>/dev/null'], Cmd),
    shell(Cmd, Out, Exit),
    check(Title, Out-Exit, Want-0).

%% one run of FILE's main/0 by the host under the shim's ENV: what it
%% says, on either stream, and what it ends with
refusal_host(Shim, Env, File, Want, Exit, Title) :-
    cocolog(C),
    sh_join([Env, ' LD_PRELOAD=', Shim, ' timeout 30 ', C, ' run ', File, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Got),
    check(Title, Out-Got, Want-Exit).

%% THE FILE A HOST CONSULTS: clauses whose variables are written twice,
%% one with nine of them (the reader's table of variables grows at the
%% ninth; seven are written once, and the load's warning of them is made
%% between the marks too), and one whose first name is a hundred
%% characters, which the token's buffer grows for as the clause before it
%% ends. main/0 answers ok for every clause as written, memory for one
%% left out (the reader said so), and names anything else: a clause that
%% is not the text's, a predicate of a name cut short.
fx_consult(Path) :-
    length(As, 99), maplist(=(0'a), As), atom_codes(Long, [0'c|As]),
    atom_concat(Long, '(k, X, X).', LongClause),
    atomic_list_concat(['cf_long(1) :- clause(', Long, '(k, X, Y), true), !, X == Y.'], LongRight),
    atomic_list_concat(['cf_stray :- current_predicate(P/3), P \\== ', Long, ', sub_atom(P, 0, 4, _, caaa).'],
                       Stray),
    fixture(Path,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              ':- dynamic cf/2.',
              ':- rf_mark(''REFUSE_ON'').',
              'cf(1, t(X, X)).',
              'cf(2, t(A1, A2, A3, A4, A5, A6, A7, A8, A9, A1, A9)).',
              'cf(3, t(Y, Z, Y)).',
              LongClause,
              ':- rf_off.',
              'cf_right(1, t(X, Y)) :- X == Y.',
              'cf_right(2, t(A1, _, _, _, _, _, _, _, A9, B1, B9)) :- A1 == B1, A9 == B9, A1 \\== A9.',
              'cf_right(3, t(Y, Z, Y2)) :- Y == Y2, Y \\== Z.',
              LongRight,
              'cf_long(0).',
              Stray,
              'main :- rf_off,',
              '        findall(I, clause(cf(I, _), true), Is),',
              '        (   \\+ forall(clause(cf(I, T), true), cf_right(I, T)) -> O = wrong',
              '        ;   cf_stray -> O = stray',
              '        ;   \\+ cf_long(_) -> O = wronglong',
              '        ;   Is == [1, 2, 3], cf_long(1) -> O = ok',
              '        ;   msort(Is, Is), sort(Is, Is) -> O = memory',
              '        ;   O = order(Is)',
              '        ),',
              '        write(O), nl.' ]).

%% A CHANNEL'S ROOM IS ASKED FOR (3.62.3). The buffer of channel/2 was a
%% `calloc' nobody asked the answer of, and its size an integer cut to an
%% int: a channel of a million million had room for whatever the low 32
%% bits said, none as often as not, and one the allocator refused had a
%% null for its buffer, which the first send wrote through. Both are
%% error(resource_error(memory), _) at channel/2 now.
channel_room :-
    section('a channel with more room than there is'),
    answer(( catch(async_run(channel(1000000000000, _)), error(E1, _), true) ), E1, G1),
    check('channel/2 of a million million: no room, and it says so', G1, resource_error(memory)),
    answer(( async_run(( channel(3, C2), channel_send(C2, a), channel_send(C2, b),
                          channel_recv(C2, _), channel_recv(C2, _) ), W2),
             W2 = ( _, _, _, channel_recv(_, X2), channel_recv(_, Y2) ) ),
           X2-Y2, G2),
    check('a channel with room for three still holds what it is sent', G2, a-b),
    shell('uname -s', Sys, _),
    (   Sys == 'Darwin'
    ->  format("   SKIP (macOS does not enforce ulimit -v)~n", [])
    ;   scratch(D),
        atom_concat(D, '/room.pl', Path),
        fixture(Path,
                [ 'main :- (   catch(async_run(( channel(100000000, C), channel_send(C, x) )),',
                  '                  error(E, _), true)',
                  '        ->  ( var(E) -> R = sent ; E = resource_error(memory) -> R = memory ; R = E )',
                  '        ;   R = failed ),',
                  '        write(R), nl.' ]),
        cocolog(C),
        sh_join(['ulimit -v 500000; COCOLOG_GREEN_WORKERS=2 ', C, ' run ', Path, ' main 2>&1'], Cmd),
        shell(Cmd, Out, Exit, 60000),
        check('a buffer of 800 MB under a ceiling of 500: refused at channel/2, not written through',
              Out-Exit, memory-0),
        shl(['rm -rf ', D])
    ).

%% A STATUS IS NEVER UNBOUND, AND ONE THAT IS IS AN ERROR (3.62.3).
%% library(async) reads what a wait answered with clauses, and each reader's
%% first clause matched an unbound status: an await that was handed nothing
%% SUCCEEDED, its result whatever the caller's variable was; a send read as
%% sent; a receive as a message nobody sent. That is how every fault that
%% lost a status stayed silent -- a blocked send's (3.62.1), a text that did
%% not read. The engine answers a status or raises now, and the readers
%% refuse an unbound one by name.
no_status :-
    section('a status that is none'),
    answer(( catch(async_done(_, _), error(E1, _), true) ), E1, G1),
    check('async_done/2 of an unbound status raises system_error', G1, system_error),
    answer(( catch(async_sent(_), error(E2, _), true) ), E2, G2),
    check('async_sent/1 of an unbound status raises system_error', G2, system_error),
    answer(( catch(async_recv(_, _), error(E3, _), true) ), E3, G3),
    check('async_recv/2 of an unbound status raises system_error', G3, system_error),
    answer(async_done('$async'(ok, v), R4), R4, G4),
    check('and a status still reads as it did', G4, v).

%% A TASK IS NOT BLOCKED WHILE ITS WORKER IS STILL INSIDE ITS RUN (3.62.3).
%% A blocking builtin marks its task blocked under the world's lock and
%% returns into the engine; the task's worker comes back out of the step a
%% moment later. A worker with nothing to run, asking in that moment
%% whether the world can still move, saw every task blocked or done and
%% called the world dead -- which it was -- and FINISHED the main task for
%% it, its machine freed under the worker still returning through it. That
%% worker then finished the task a second time: `failed' where the status
%% said deadlock, a status freed twice, or a SIGSEGV (since 2.8.1; in 3 runs
%% of 4 on four workers, and whatever else answered wrong in the fourth).
%% The check passes by a blocked task whose own worker has not come back
%% from its run, and that worker asks again when it has.
%%
%% The fixture is two thousand worlds that are dead the moment their one
%% other task ends: the main task blocks on a channel nobody sends to, some
%% turns of a spin after it started the task, so that across the spins the
%% task's end and the main's block fall together. Each must be a deadlock.
%%
%% AND THE SHAPE THAT FALLS IN THE WINDOW NEARLY EVERY TIME: the one task
%% writes the store and then waits. The write wakes every idle worker, each
%% acknowledges it and then asks whether the world can still move -- with
%% the world's lock, which the waiting task is just then setting its state
%% under. On 3.62.2 four runs of four end in a SIGSEGV on four workers
%% (three worlds of 500 answer something else on two), whatever else the
%% machine is doing; the first shape shows the fault one run in four on a
%% busy box.
dead_running :-
    section('a world found dead while its main task is still leaving its step'),
    scratch(D),
    atom_concat(D, '/dead.pl', Path),
    fixture(Path,
            [ 'dl_spin(0) :- !.',
              'dl_spin(N) :- N1 is N - 1, dl_spin(N1).',
              'dl_world(child, S) :- channel(C), go(true, _), dl_spin(S), channel_recv(C, _).',
              'dl_world(write, S) :- channel(C), nb_setval(dl, S), channel_recv(C, _).',
              'dl_runs(_, 0, D, D, O, O) :- !.',
              'dl_runs(How, K, D0, D, O0, O) :-',
              '    S is K mod 64,',
              '    (   catch(async_run(dl_world(How, S)), error(E, _), true)',
              '    ->  ( nonvar(E), E = resource_error(deadlock) -> D1 is D0 + 1, O1 = O0 ; D1 = D0, O1 is O0 + 1 )',
              '    ;   D1 = D0, O1 is O0 + 1',
              '    ),',
              '    K1 is K - 1, dl_runs(How, K1, D1, D, O1, O).',
              'main :- current_prolog_flag(argv, [_, How, KA|_]), atom_number(KA, K),',
              '        dl_runs(How, K, 0, D, 0, O), write(D-O), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' -s ', Path, ' -- child 2000 2>/dev/null'], Cmd),
    shell(Cmd, Out, Exit, 120000),
    check('2000 worlds that die as their one task ends: each a deadlock, said once',
          Out-Exit, '2000-0'-0),
    sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' -s ', Path, ' -- write 500 2>/dev/null'], Cmd2),
    shell(Cmd2, Out2, Exit2, 120000),
    check('500 worlds whose one task writes the store and then waits: the workers the write woke find each dead, once',
          Out2-Exit2, '500-0'-0),
    shl(['rm -rf ', D]).

%% A BLOCK ON THE LAST STEP OF A QUANTUM (3.62.3). A task runs ten thousand
%% steps and is stopped; the engine's loop asks that limit before it asks
%% whether a builtin asked for a stop. So a task whose receive, send,
%% await or yield was the ten-thousandth step of its run had its block
%% unread when the quantum ended the run: it was made ready, its next run
%% stopped at once on the stale block with nothing to wait for, and that
%% was read as a goal that failed -- an await of the task failed, and the
%% world whose sender it was went dead. One block in ten thousand of a
%% task that ran its quantum out, since 2.8.0; an arm that would not go
%% red found it (STATUS.md).
%%
%% A step cannot be aimed at from Prolog, so the fixture walks across it:
%% a task counts down from K and then blocks, for every K from 4900 to
%% 5100 -- two steps a count, so its block falls before the quantum's end
%% at the first and after it at the last -- with none, one or two steps
%% before the count, which puts the block on either parity. 2412 worlds on
%% one worker, where the steps are the same steps in every run; main/0
%% says first what a count costs, which the range stands on.
quantum_block :-
    section('a receive, a send, an await and a yield on the last step of a quantum'),
    scratch(D),
    atom_concat(D, '/quantum.pl', Path),
    fixture(Path,
            [ 'qb_spin(0) :- !.',
              'qb_spin(N) :- N1 is N - 1, qb_spin(N1).',
              'qb_one.',
              'qb_pre(0).',
              'qb_pre(1) :- qb_one.',
              'qb_pre(2) :- qb_one, qb_one.',
              'qb_task(recv, P, K, C) :- qb_pre(P), qb_spin(K), channel_recv(C, X), X == hello.',
              'qb_task(send, P, K, C) :- qb_pre(P), qb_spin(K), channel_send(C, hello).',
              'qb_task(yield, P, K, _) :- qb_pre(P), qb_spin(K), yield.',
              'qb_task(await, P, K, G) :- qb_pre(P), qb_spin(K), await(G).',
              'qb_world(recv, P, K, R) :- channel(1, C), go(qb_task(recv, P, K, C), F), yield, yield,',
              '    channel_send(C, hello), qb_end(F, R).',
              'qb_world(send, P, K, R) :- channel(C), go(qb_task(send, P, K, C), F), yield, yield,',
              '    channel_recv(C, X), ( X == hello -> qb_end(F, R) ; R = got(X) ).',
              'qb_world(yield, P, K, R) :- go(qb_task(yield, P, K, _), F), yield, yield, qb_end(F, R).',
              'qb_world(await, P, K, R) :- channel(C), go(channel_recv(C, _), G),',
              '    go(qb_task(await, P, K, G), F), yield, yield, channel_send(C, x), qb_end(F, R).',
              'qb_end(F, R) :- ( catch(await(F), E, true) -> ( var(E) -> R = ok ; R = E ) ; R = await_failed ).',
              'qb_try(Kind, P, K) :-',
              '    (   catch(async_run(qb_world(Kind, P, K, _), qb_world(_, _, _, R)), E, R = raised(E))',
              '    ->  ( R == ok -> true ; write(Kind-P-K-R), nl )',
              '    ;   write(Kind-P-K-run_failed), nl',
              '    ).',
              'main :- statistics(inferences, I0), qb_spin(1000), statistics(inferences, I1),',
              '        Cost is I1 - I0,',
              '        ( Cost =:= 2003 -> true ; write(count_costs(Cost)), nl ),',
              '        forall(( member(Kind, [recv, send, yield, await]), member(P, [0, 1, 2]),',
              '                 between(4900, 5100, K) ),',
              '               qb_try(Kind, P, K)),',
              '        write(done), nl.' ]),
    cocolog(C),
    sh_join(['COCOLOG_GREEN_WORKERS=1 ', C, ' -s ', Path, ' 2>/dev/null'], Cmd),
    shell(Cmd, Out, Exit, 120000),
    check('2412 worlds, a task of each blocking on a step about its quantum''s last: every one answers',
          Out-Exit, done-0),
    shl(['rm -rf ', D]).

%% ---- what a task holds across a write barrier (3.64.0) -----------------
%%
%% A WORKER WAITING AT A WRITE BARRIER ANSWERS THE OTHER WORKERS' WRITES
%% (`coco_g_write_begin'), so what it read before the barrier may have
%% changed by the time it holds the barrier: nothing read before one is
%% used after it. Each section below is one way to break that rule, one
%% task writing while another calls, in a child process of four workers
%% under a ceiling of time and of memory (a run that broke the rule took
%% the box's memory once). Each fails on 3.63.2 but the third, whose deep
%% index 3.63.2 does not have; it fails with its node's build taken from
%% under its barrier.

%% A PREDICATE HELD ACROSS A BARRIER STAYS WHERE IT WAS. A task's first
%% call of a rule compiles its clause under the barrier; an assertz
%% acknowledged in that wait made a new predicate past the store's room,
%% the array of predicates grew by realloc, and the caller's pointer named
%% freed memory -- a SIGSEGV, six runs in six of 3.63.2. Each predicate is
%% in a chunk of 256 that never moves now, the store's table a pointer
%% each (`coco-pred-at'). One task asserts a rule of a new name 12,000
%% times, another calls each one as it appears.
moved_preds :-
    section('a predicate held across a barrier while another task makes new ones'),
    scratch(D),
    atom_concat(D, '/moved.pl', Path),
    fixture(Path,
            [ 'mv_name(R, N) :- atom_concat(mv_, R, N).',
              'mv_writer(R, R) :- !.',
              'mv_writer(R0, R) :- mv_name(R0, N), H =.. [N, X], assertz((H :- X = R0, true)),',
              '    R1 is R0 + 1, mv_writer(R1, R).',
              'mv_reader(R, R) :- !.',
              'mv_reader(R0, R) :- mv_name(R0, N),',
              '    ( current_predicate(N/1) -> G =.. [N, X], ( call(G) -> X == R0 ; true ), R1 is R0 + 1',
              '    ; R1 = R0 ),',
              '    mv_reader(R1, R).',
              'main :- async_run(( go(mv_writer(0, 12000), A), go(mv_reader(0, 12000), B),',
              '                    await(A), await(B) )),',
              '    write(done), nl.' ]),
    barrier_run(Path, Out-Exit),
    check('12,000 new predicates beside the first calls of each', Out-Exit, done-0),
    shl(['rm -rf ', D]).

%% AN ARGUMENT'S TABLE IS BUILT FROM THE CLAUSES THE BARRIER LEAVES. A
%% call keyed on its second argument builds that argument's table under
%% the barrier; through 3.63.2 the clause count was read before it, and a
%% fact an assertz acknowledged in the wait put there had no row in the
%% table, so no call found it again (218 to 278 rounds of 2,000 lost, and
%% a SIGSEGV). One task asserts twelve facts of a new name a round; another
%% waits for each name's second fact and then calls the name keyed on its
%% second argument, which builds the table while the round's other facts
%% are being asserted (a call over one clause builds none); the writer
%% waits for the reader at each round's end (a channel), or a reader that
%% fell behind met only rounds written whole. Every fact is found after.
table_count :-
    section('an argument''s table built while another task asserts'),
    scratch(D),
    atom_concat(D, '/count.pl', Path),
    fixture(Path,
            [ 'tc_name(R, N) :- atom_concat(tc_, R, N).',
              'tc_writer(R, R, _) :- !.',
              'tc_writer(R0, R, C) :- tc_name(R0, N),',
              '    forall(between(1, 12, I), ( G =.. [N, I, k], assertz(G) )),',
              '    channel_recv(C, _), R1 is R0 + 1, tc_writer(R1, R, C).',
              'tc_reader(R, R, _) :- !.',
              'tc_reader(R0, R, C) :- tc_name(R0, N),',
              '    (   current_predicate(N/2), G2 =.. [N, 2, k], call(G2)',
              '    ->  G =.. [N, _, k], ( call(G) -> true ; true ), channel_send(C, R0), R1 is R0 + 1',
              '    ;   R1 = R0',
              '    ),',
              '    tc_reader(R1, R, C).',
              'tc_lost(R) :- tc_name(R, N), G =.. [N, I, k], findall(I, G, Is), length(Is, C), C < 12.',
              'main :- async_run(( channel(C), go(tc_writer(0, 2000, C), A), go(tc_reader(0, 2000, C), B),',
              '                    await(A), await(B) )),',
              '    findall(R, ( between(0, 1999, R), tc_lost(R) ), Ls), length(Ls, K),',
              '    write(lost_rounds(K)), nl.' ]),
    barrier_run(Path, Out-Exit),
    check('2,000 rounds of twelve facts, every one found by its second argument', Out-Exit,
          'lost_rounds(0)'-0),
    shl(['rm -rf ', D]).

%% A NODE OF THE DEEP INDEX IS BUILT FROM WHAT THE BARRIER LEAVES: the
%% level above, its keys and its count all read under the one barrier
%% (`coco_dnode_ensure'), as an assertz acknowledged in the wait grows the
%% keys and may leave the level above to be built again. One task asserts
%% twelve facts f(I, a_I) of a new name a round; another waits for each
%% name's f(2, a_2), whose call builds the node while the round goes on,
%% and calls the name keyed inside the compound, the two in step a round
%% at a time; every fact is found after.
deep_build :-
    section('a node of the deep index built while another task asserts'),
    scratch(D),
    atom_concat(D, '/deep.pl', Path),
    fixture(Path,
            [ 'db_name(R, N) :- atom_concat(db_, R, N).',
              'db_key(I, K) :- atom_concat(a_, I, K).',
              'db_writer(R, R, _) :- !.',
              'db_writer(R0, R, C) :- db_name(R0, N),',
              '    forall(between(1, 12, I), ( db_key(I, K), G =.. [N, f(I, K)], assertz(G) )),',
              '    channel_recv(C, _), R1 is R0 + 1, db_writer(R1, R, C).',
              'db_reader(R, R, _) :- !.',
              'db_reader(R0, R, C) :- db_name(R0, N),',
              '    (   current_predicate(N/1), G2 =.. [N, f(2, a_2)], call(G2)',
              '    ->  G =.. [N, f(_, a_5)], ( call(G) -> true ; true ), channel_send(C, R0), R1 is R0 + 1',
              '    ;   R1 = R0',
              '    ),',
              '    db_reader(R1, R, C).',
              'db_lost(R) :- db_name(R, N), between(1, 12, I), db_key(I, K), G =.. [N, f(_, K)], \\+ call(G), !.',
              'main :- async_run(( channel(C), go(db_writer(0, 2000, C), A), go(db_reader(0, 2000, C), B),',
              '                    await(A), await(B) )),',
              '    findall(R, ( between(0, 1999, R), db_lost(R) ), Ls), length(Ls, K),',
              '    write(lost_rounds(K)), nl.' ]),
    barrier_run(Path, Out-Exit),
    check('2,000 rounds of twelve facts, every one found inside its compound', Out-Exit,
          'lost_rounds(0)'-0),
    shl(['rm -rf ', D]).

%% A WRITE THAT LEAVES THE DEEP INDEX TO BE BUILT AGAIN while a task is
%% between a node and its table: the table's build asks the node again
%% under its barrier (`coco_dtab_get'). And a
%% clause's program goes into its slot only where the slot still holds
%% that clause (`coco_pred_code_set'): an asserta acknowledged while the
%% program was made had moved every clause up one, and through 3.63.2 the
%% program went to its neighbour's slot -- that call ran the other
%% clause's code, and at the neighbour's death the program was freed
%% twice. One task puts a clause in front of twelve and takes it out
%% again, 20,000 times; another calls the predicate keyed inside the
%% compound 60,000 times.
deep_unbuild :-
    section('the deep index left to be built again under a task''s call'),
    scratch(D),
    atom_concat(D, '/unbuild.pl', Path),
    fixture(Path,
            [ ':- dynamic ub_d/1.',
              'ub_fill :- forall(between(1, 12, I), ( atom_concat(a_, I, K), assertz(ub_d(f(I, K))) )).',
              'ub_writer(0, M, M) :- !.',
              'ub_writer(N, M0, M) :- asserta(ub_d(f(z, zz))),',
              '    ( retract(ub_d(f(z, zz))) -> M1 = M0 ; M1 is M0 + 1 ),',
              '    N1 is N - 1, ub_writer(N1, M1, M).',
              'ub_reader(0, B, B) :- !.',
              'ub_reader(N, B0, B) :- K is N mod 12 + 1, atom_concat(a_, K, A),',
              '    findall(X, ub_d(f(X, A)), L),',
              '    ( L == [K] -> B1 = B0 ; B1 is B0 + 1 ),',
              '    N1 is N - 1, ub_reader(N1, B1, B).',
              'ub_world(M, B) :- go(ub_writer(20000, 0, _), W), go(ub_reader(60000, 0, _), R),',
              '    await(W, ub_writer(_, _, M)), await(R, ub_reader(_, _, B)).',
              'main :- ub_fill, async_run(ub_world(_, _), ub_world(M, B)),',
              '    findall(C, ub_d(C), Cs), length(Cs, Len), write(M-B-Len), nl.' ]),
    barrier_run(Path, Out-Exit),
    check('20,000 clauses put in front and taken out, 60,000 calls each finding its one: none left, none wrong, twelve after',
          Out-Exit, '0-0-12'-0),
    shl(['rm -rf ', D]).

%% THE FIRST ARGUMENT'S INDEX IS REBUILT UNDER THE BARRIER
%% (`coco_pred_reindex'). A write leaves the index to be rebuilt by the
%% next call that wants it, and through 3.63.2 that took no barrier:
%% three tasks' first calls after a write rebuilt its slots and chains at
%% once -- wrong answers, and a slot array that grew until memory ran
%% out. One task puts a clause in front of forty and takes it out, 20,000
%% times; three call the predicate by its first argument, 30,000 times
%% each.
reindex_barrier :-
    section('three tasks'' first calls after a write rebuild one index'),
    scratch(D),
    atom_concat(D, '/reindex.pl', Path),
    fixture(Path,
            [ ':- dynamic ri_q/2.',
              'ri_fill :- forall(between(1, 40, I), ( atom_concat(k_, I, K), assertz(ri_q(K, I)) )).',
              'ri_writer(0) :- !.',
              'ri_writer(N) :- asserta(ri_q(zz, 0)), retract(ri_q(zz, 0)), N1 is N - 1, ri_writer(N1).',
              'ri_reader(0, B, B) :- !.',
              'ri_reader(N, B0, B) :- I is N mod 40 + 1, atom_concat(k_, I, K),',
              '    findall(X, ri_q(K, X), L), ( L == [I] -> B1 = B0 ; B1 is B0 + 1 ),',
              '    N1 is N - 1, ri_reader(N1, B1, B).',
              'ri_world(B1, B2, B3) :- go(ri_writer(20000), W),',
              '    go(ri_reader(30000, 0, _), R1), go(ri_reader(30000, 0, _), R2),',
              '    go(ri_reader(30000, 0, _), R3), await(W),',
              '    await(R1, ri_reader(_, _, B1)), await(R2, ri_reader(_, _, B2)),',
              '    await(R3, ri_reader(_, _, B3)).',
              'main :- ri_fill, async_run(ri_world(_, _, _), ri_world(B1, B2, B3)),',
              '    findall(C, ri_q(C, _), Cs), length(Cs, Len), write(B1-B2-B3-Len), nl.' ]),
    barrier_run(Path, Out-Exit),
    check('20,000 writes beside three readers'' 90,000 calls: none wrong, forty after',
          Out-Exit, '0-0-0-40'-0),
    shl(['rm -rf ', D]).

%% A RETRY IN A WORLD BUILDS NO INDEX (`coco_pred_next_clause',
%% `coco_aix_walk', `coco_deep_next'). A write leaves an index to be built
%% again, and a retry that built it waited at the barrier, where an
%% asserta could land and move every clause on by one -- the frame's place
%% with it, not the place the retry had read: it tried the clause it had
%% just tried again. A retry walks an index it finds dropped as none now,
%% as it would walk a small predicate. Three readers walk a key's four
%% clauses -- by the first argument, by the second, inside a compound --
%% yielding at each answer, so the writer's asserta and retract of a
%% clause in front land between their retries. 3.63.2 corrupts its heap
%% here every run (`double free or corruption', the program slot's fault
%% above); with that one fixed, the first cut of 3.64.0 had 1 to 14 walks
%% of the 12 000 of each kind wrong, every run.
retry_walks :-
    section('retries along one key while another task writes in front'),
    scratch(D),
    atom_concat(D, '/retry.pl', Path),
    fixture(Path,
            [ ':- dynamic rw1/2, rw2/2, rw3/1.',
              'rw_fill :- forall(between(1, 40, I),',
              '                  ( K is (I - 1) // 4, atom_concat(k_, K, A),',
              '                    assertz(rw1(A, I)), assertz(rw2(I, A)), assertz(rw3(f(I, A))) )).',
              'rw_writer(0) :- !.',
              'rw_writer(N) :- asserta(rw1(zz, 0)), retract(rw1(zz, 0)),',
              '    asserta(rw2(0, zz)), retract(rw2(0, zz)),',
              '    asserta(rw3(f(0, zz))), retract(rw3(f(0, zz))),',
              '    N1 is N - 1, rw_writer(N1).',
              'rw_goal(1, A, X, rw1(A, X)).',
              'rw_goal(2, A, X, rw2(X, A)).',
              'rw_goal(3, A, X, rw3(f(X, A))).',
              'rw_walk(G, X, N, S) :- T = c(0, 0),',
              '    (   call(G), arg(1, T, N0), N1 is N0 + 1, nb_setarg(1, T, N1),',
              '        arg(2, T, S0), S1 is S0 + X, nb_setarg(2, T, S1), yield, fail',
              '    ;   true',
              '    ),',
              '    T = c(N, S).',
              'rw_reader(0, B, B) :- !.',
              'rw_reader(N, w(B1, B2, B3), B) :- K is N mod 10, atom_concat(k_, K, A),',
              '    rw_one(1, A, K, B1, C1), rw_one(2, A, K, B2, C2), rw_one(3, A, K, B3, C3),',
              '    N1 is N - 1, rw_reader(N1, w(C1, C2, C3), B).',
              'rw_one(W, A, K, B0, B) :- rw_goal(W, A, X, G), rw_walk(G, X, C, S),',
              '    ( C =:= 4, S =:= 16 * K + 10 -> B = B0 ; B is B0 + 1 ).',
              'rw_world(B1, B2, B3) :- go(rw_writer(20000), W),',
              '    go(rw_reader(4000, w(0, 0, 0), _), R1), go(rw_reader(4000, w(0, 0, 0), _), R2),',
              '    go(rw_reader(4000, w(0, 0, 0), _), R3), await(W),',
              '    await(R1, rw_reader(_, _, B1)), await(R2, rw_reader(_, _, B2)),',
              '    await(R3, rw_reader(_, _, B3)).',
              'rw_sum(w(A1, A2, A3), w(B1, B2, B3), w(C1, C2, C3), W1-W2-W3) :-',
              '    W1 is A1 + B1 + C1, W2 is A2 + B2 + C2, W3 is A3 + B3 + C3.',
              'main :- rw_fill, async_run(rw_world(_, _, _), rw_world(B1, B2, B3)),',
              '    rw_sum(B1, B2, B3, W),',
              '    findall(x, ( rw1(_, _) ; rw2(_, _) ; rw3(_) ), L), length(L, Len),',
              '    write(W-Len), nl.' ]),
    barrier_run(Path, Out-Exit),
    check('36 000 walks of four answers each beside 120 000 writes: none wrong, 120 clauses after',
          Out-Exit, '0-0-0-120'-0),
    shl(['rm -rf ', D]).

%% A PORTRAY GOAL'S CAPTURE IS ITS THREAD'S (3.64.1, `coco_out_tl' in
%% lib/term.cicili): what the goal writes goes to a FILE in memory that
%% this thread's writes reach and no other thread's. Through 3.64.0 a
%% portray goal captured fd 1, the process's: in a world of four workers a
%% task's portray text went into another task's capture or onto the
%% console, and two captures that ended out of their order left fd 1 on a
%% deleted file, which took the line after the world (two runs of four).
%% Eight tasks write a list of 300 through format's ~p to an atom, 200
%% times each, a portray/1 hook asked of every element and every third
%% writing a fresh line, 4 000 characters and a column stop at 4 010 -- a
%% capture's line and column are its thread's too, and one another thread
%% moved puts a newline in or pads wrong --
%% and each holds every text to the one the host wrote before the world:
%% a task whose capture took in another's text fails, and the world with
%% it. Four runs; the console shows the line after the world and nothing
%% else. (The parent reads 4 096 bytes at most: a capture that leaks puts
%% hundreds of megabytes on the console.)
portray_worlds :-
    section('portray goals in eight tasks at once: each its own text, the console nothing'),
    scratch(D),
    atom_concat(D, '/portray.pl', Path),
    fixture(Path,
            [ 'portray(f(I)) :- 0 =:= I mod 3, nb_getval(long, A), format("~N~a~t~4010|", [A]).',
              'pw_task(L, W) :- forall(between(1, 200, _), format(atom(W), "~p", [L])).',
              'main :- length(Cs, 4000), maplist(=(0\'x), Cs), atom_codes(A, Cs), nb_setval(long, A),',
              '    findall(f(I), between(1, 300, I), L), format(atom(W), "~p", [L]), length(Ts, 8),',
              '    async_run(( maplist([T]>>go(pw_task(L, W), T), Ts), maplist(await, Ts) )),',
              '    write(done), nl.' ]),
    findall(R, ( between(1, 4, _), portray_world_run(Path, R) ), Runs),
    check('480 000 portray goals in eight tasks, four runs: each task its own texts, the console the line after',
          Runs, [clean, clean, clean, clean]),
    shl(['rm -rf ', D]).

%% A TASK ANOTHER TASK'S WAIT RUNS WRITES NOTHING INTO THE WAITER'S
%% CAPTURE (3.64.1, `coco_g_run_aside' in lib/green.cicili): in a world of
%% one worker the main task's portray goal waits on a channel, and its wait
%% runs the task that sends, which writes a line first. The line is on the
%% console and the portray text is the goal's alone; through 3.64.0 the
%% capture of fd 1 took the line into the text.
portray_wait :-
    section('a task a portray goal\'s wait runs writes to the console, not the capture'),
    scratch(D),
    atom_concat(D, '/pwait.pl', Path),
    fixture(Path,
            [ 'portray(w(C)) :- channel_recv(C, X), write(got(X)).',
              'sender(C) :- write(sender_line), nl, channel_send(C, 42).',
              'main :- async_run(( channel(C), go(sender(C), _), format(atom(_), "~p", [w(C)]) ), R),',
              '    R = (_, _, format(atom(T), _, _)), writeq(T), nl.' ]),
    cocolog(Co),
    sh_join(['COCOLOG_GREEN_WORKERS=1 ', Co, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit, 60000),
    check('the sender\'s line on the console, then the portray text alone',
          Out-Exit, 'sender_line\n\'got(42)\''-0),
    shl(['rm -rf ', D]).

%% a run of the fixture as barrier_run/2's, its console read to 4 096
%% bytes and its exit after it: `clean', or its length and how it starts
portray_world_run(Path, R) :-
    cocolog(C),
    sh_join(['{ ulimit -v 4194304; COCOLOG_GREEN_WORKERS=4 ', C, ' run ', Path,
             ' main 2>&1; echo "exit $?"; } | head -c 4096'], Cmd),
    shell(Cmd, Out, _, 60000),
    (   Out == 'done\nexit 0'
    ->  R = clean
    ;   atom_length(Out, N),
        ( N > 60 -> sub_atom(Out, 0, 60, _, Start) ; Start = Out ),
        R = other(N, Start)
    ).

%% Each of the six in a world of four workers, under four gigabytes of
%% address space and a minute
barrier_run(Path, Out-Exit) :-
    cocolog(C),
    sh_join(['ulimit -v 4194304; COCOLOG_GREEN_WORKERS=4 ', C, ' run ', Path, ' main 2>&1'], Cmd),
    shell(Cmd, Out, Exit, 60000).
