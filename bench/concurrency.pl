%% bench/concurrency.pl -- the cocolog lanes of the concurrency benchmark:
%% real threads (library(thread)), green threads (library(async)) and a
%% serial baseline, on the same spin/1 work -- and the light lanes: many
%% short tasks (spawn/join true) and the same with a yield each round.
%%
%%     ./cocolog -s bench/concurrency.pl -- serial 8 200000
%%     ./cocolog -s bench/concurrency.pl -- real   8 200000
%%     ./cocolog -s bench/concurrency.pl -- green  8 200000
%%     ./cocolog -s bench/concurrency.pl -- light_real 1000
%%     ./cocolog -s bench/concurrency.pl -- light_real_yield 1000 100
%%     ./cocolog -s bench/concurrency.pl -- light_green 10000
%%     ./cocolog -s bench/concurrency.pl -- light_green_yield 10000 100
%%
%% Every lane prints `answer(done)'; bench/concurrency.sh refuses a lane
%% whose answer differs and throws the first run of each away.
%%
%% A GREEN SCHEDULER HOLDS 64 THREADS, so the green light lanes run in
%% batches of 64, each batch one async_run: every spawn pays its store
%% snapshot. A REAL thread's goal sees the process-wide module registry,
%% not the `-s' program, so the yielding real lane builds its mutex
%% handoffs as a goal term; a green child sees the `-s' program through
%% the snapshot, so its yield goal can be a term too.

:- use_module('bench/spin.pl').
:- use_module(library(thread)).

main :-
    current_prolog_flag(argv, [_, Mode|Rest]),
    (   Mode == serial -> two(Rest, N1, M1), serial(N1, M1)
    ;   Mode == real   -> two(Rest, N2, M2), real(N2, M2)
    ;   Mode == green  -> two(Rest, N3, M3), green(N3, M3)
    ;   Mode == light_real -> one(Rest, N4), light_real(N4)
    ;   Mode == light_real_yield -> two(Rest, N5, K5), light_real_yield(N5, K5)
    ;   Mode == store_green -> three(Rest, N8, K8, M8), store_green(N8, K8, M8)
    ;   Mode == store_seed -> one(Rest, K9), store_build(K9)
    ;   Mode == store_run -> three(Rest, N9, K9b, M9), store_run(N9, K9b, M9)
    ;   Mode == light_green -> one(Rest, N6), light_green(N6)
    ;   Mode == light_green_yield -> two(Rest, N7, K7), light_green_yield(N7, K7)
    ;   fail
    ),
    write(answer(done)), nl.

one([A], N) :- atom_number(A, N).
two([A,B], N, M) :- atom_number(A, N), atom_number(B, M).
three([A,B,C], N, K, M) :-
    atom_number(A, N), atom_number(B, K), atom_number(C, M).

%% ---- the serial baseline ------------------------------------------------
serial(0, _) :- !.
serial(N, M) :-
    N > 0,
    spin(M),
    N1 is N - 1,
    serial(N1, M).

%% ---- real threads -------------------------------------------------------
real(N, M) :-
    numlist(1, N, Units),
    real_start(M, Units, Ids),
    real_join(Ids).

real_start(_, [], []).
real_start(M, [_|Units], [Id|Ids]) :-
    thread_create(spin(M), Id),
    real_start(M, Units, Ids).

real_join([]).
real_join([Id|Ids]) :-
    thread_join(Id, _),
    real_join(Ids).

%% ---- green threads ------------------------------------------------------
green(N, M) :-
    numlist(1, N, Units),
    async_run(( green_start(M, Units, Ids),
                await_all(Ids) ), _).

green_start(_, [], []).
green_start(M, [_|Units], [Id|Ids]) :-
    go(spin(M), Id),
    green_start(M, Units, Ids).

%% ---- light real: spawn/join true, and a mutex handoff each round --------
light_real(N) :-
    numlist(1, N, Units),
    light_real_start(true, Units, Ids),
    real_join(Ids).

light_real_yield(N, K) :-
    numlist(1, N, Units),
    yield_real_goal(K, Goal),
    light_real_start(Goal, Units, Ids),
    real_join(Ids).

light_real_start(_, [], []).
light_real_start(Goal, [_|Units], [Id|Ids]) :-
    thread_create(Goal, Id),
    light_real_start(Goal, Units, Ids).

%% The goal term is built in the host; the mutex is named process-wide, so
%% the threads share it. A real thread does not see this file's clauses.
yield_real_goal(0, true) :- !.
yield_real_goal(K, (mutex_lock(bench_light_mutex),
                    mutex_unlock(bench_light_mutex),
                    Rest)) :-
    K > 0,
    K1 is K - 1,
    yield_real_goal(K1, Rest).

%% ---- light green: 1023 children + the main to a world, in batches ------
light_green(N) :-
    light_green_batches(N, true).

light_green_yield(N, K) :-
    yield_green_goal(K, Goal),
    light_green_batches(N, Goal).

light_green_batches(0, _) :- !.
light_green_batches(N, Goal) :-
    N > 0,
    ( N > 1023 -> B = 1023 ; B = N ),
    numlist(1, B, Units),
    async_run(( light_green_start(Goal, Units, Ids),
                await_all(Ids) ), _),
    N1 is N - B,
    light_green_batches(N1, Goal).

light_green_start(_, [], []).
light_green_start(Goal, [_|Units], [Id|Ids]) :-
    go(Goal, Id),
    light_green_start(Goal, Units, Ids).

yield_green_goal(0, true) :- !.
yield_green_goal(K, (yield, Rest)) :-
    K > 0,
    K1 is K - 1,
    yield_green_goal(K1, Rest).

%% ---- green over the embedded store -------------------------------------
%%
%% The store lanes of bench/langs.sh in the world: K keyed facts built
%% once, then M keys probed by each of N green threads at once, over the
%% one store they share (the 2.9.0 model -- the reads take no lock).
%% bench/concurrency_store.go runs the same probes as N goroutines over
%% SQLite, the key arithmetic and the answer's sum identical, so the two
%% walls are one question: the store against a file. The world's writes
%% (the build) stop it, the reads do not; SQLite's PRIMARY KEY is an
%% index, cocolog's first argument an index.
%%
%%   run bench/concurrency.pl "store_green(N, K, M)"   under --embed DIR

store_green(N, K, M) :-
    store_build(K),
    store_run(N, K, M).

store_run(N, K, M) :-
    store_warm,
    numlist(1, N, Units),
    async_run(( store_start(K, M, Units, Ids),
                store_sum(Ids, 0, Total),
                format("total(~w)~n", [Total]) ), _).

%% THE PREDICATE IS LOADED BEFORE THE WORLD STARTS, so the timed wall is
%% the probes alone rather than one task's fetch of 10,000 rows. A
%% worker's first fetch works since 2.9.1 (the client keeps a session per
%% thread; before, it crashed in MVCCS's `visible()'); a host call here
%% reads the rows once and the world's tasks find them in memory, the
%% shape httpd's `prewarm' gives its pool. EVERY solution is taken
%% (`forall', not `ignore'): one solution compiles one clause, and the
%% other 9,999 would be compiled by the first task that selects them,
%% each under the write barrier with every worker acknowledging -- a cost
%% that grows with the worker count and is no part of a lookup.
store_warm :-
    catch(forall(skv(_, _), true), _, true).

store_build(0) :- !.
store_build(K) :-
    V is (K * 7) mod 1000,
    assertz(skv(K, V)),
    K1 is K - 1,
    store_build(K1).

store_start(_, _, [], []).
store_start(K, M, [_|Units], [Id|Ids]) :-
    go(store_probe(M, K, 0, _), Id),
    store_start(K, M, Units, Ids).

store_sum([], A, A).
store_sum([Id|Ids], A0, A) :-
    await(Id, G),
    arg(4, G, S),
    A1 is A0 + S,
    store_sum(Ids, A1, A).

store_probe(0, _, A, A) :- !.
store_probe(M, K, A0, A) :-
    Key is ((M * 37) mod K) + 1,
    ( skv(Key, V) -> A1 is A0 + V ; A1 = A0 ),
    M1 is M - 1,
    store_probe(M1, K, A1, A).
