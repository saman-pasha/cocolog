%% test/flowchart/threads.pl -- threads, channels, locks and processes:
%% library(flow/chart)'s F2 fixture. It is charted, never run: every place
%% code runs is a lane, and what crosses between lanes is a link. Four of
%% its predicates are wrong on purpose -- fire/1 never joins its thread,
%% locked/1 keeps its lock when check/1 fails, lost/1 reads what only its
%% thread bound, and peek/0 and the page read a tally only the query's lane
%% writes, from a pool, an isolated proof and an httpd worker -- and
%% test/flowchart.pl requires those six findings and no other: the
%% detached, the handed-back and the joined thread, the lock round a goal
%% that cannot fail, the answer cowork_ask/2 unifies back and the dynamic
%% predicate nobody writes are near misses.

:- use_module(library(thread)).
:- use_module(library(process)).
:- use_module(library(cowork)).
:- use_module(library(httpd)).

:- dynamic tally/1.
tally(0).

:- dynamic limit/1.
limit(3).

%% go(+Jobs, -Status): a worker thread fed down a channel, then joined
% cocolint: N1 -- charted, never run, so nothing joins library(async)'s go/2; the case names this lane
go(Jobs, Status) :-
    channel_new(Ch),
    thread_create(worker(Ch), Id),
    send_all(Jobs, Ch),
    channel_close(Ch),
    thread_join(Id, Status),
    bump(1).

send_all([], _).
send_all([J|Js], Ch) :-
    channel_send(Ch, J),
    send_all(Js, Ch).

%% the worker: what the channel brings, one at a time, reported under a lock
worker(Ch) :-
    channel_recv(Ch, J), !,
    with_mutex(log, report(J)),
    worker(Ch).
worker(_).

report(J) :- format("job ~w~n", [J]).

bump(N) :-
    retract(tally(T)),
    T1 is T + N,
    assertz(tally(T1)).

%% pool(-Ids): four threads, each reading the tally the parent writes
pool(Ids) :-
    thread_pool(4, peek, Ids),
    thread_join_all(Ids).

peek :- tally(N), N > 0.

%% fire(+X): a thread nobody joins
fire(X) :-
    thread_create(report(X), _).

%% detached and spawned(-Id): a thread that cleans up after itself, and one
%% whose caller is handed the id to join
detached :-
    thread_create(report(d), Id),
    thread_detach(Id).
spawned(Id) :-
    thread_create(report(s), Id).

%% locked(+J): a lock taken by hand, and a way out that keeps it
locked(J) :-
    mutex_lock(log),
    check(J),
    mutex_unlock(log).

check(J) :- integer(J).

%% logged(+J): the same, round a goal that cannot fail
logged(J) :-
    mutex_lock(log),
    report(J),
    mutex_unlock(log).

%% lost(-B): nothing a thread binds comes back, so A is free after it
lost(B) :-
    thread_create(double(21, A), Id),
    thread_join(Id, _),
    B is A + 1.

%% watch: a thread reading a dynamic predicate nobody writes
watch :-
    thread_create(limit_ok, Id),
    thread_join(Id, _).

limit_ok :- limit(N), N > 0.

%% isolated(-S): a proof on a machine of its own, here, waited for
isolated(S) :-
    run_isolated(peek, S).

%% ls_dir(-Out) and again(-E): child processes, one of them cocolog
ls_dir(Out) :-
    sh('ls -l', Out).
again(E) :-
    sh_exit('./cocolog -s test/flowchart/demo.pl', E).

%% crew(-B): a job on a crew, its answer unified back and used
crew(B) :-
    cowork_start(2, [], C),
    cowork_ask(C, double(21, A)),
    cowork_stop(C),
    B is A + 1.

double(X, Y) :- Y is X * 2.

%% serve: each request on a worker of a pool of two
serve :-
    httpd_serve(8080, [workers(2)]).

httpd_page('/tally', _, reply(200, [], T)) :- tally(T).

%% all: every one of them, for one chart -- lost/1 last, as it always
%% raises and nothing after it would be reached
all :-
    go([1, 2, 3], _),
    pool(_),
    fire(x),
    detached,
    spawned(_),
    locked(1),
    logged(2),
    watch,
    isolated(_),
    ls_dir(_),
    again(_),
    crew(_),
    serve,
    lost(_).
