%% test/flowchart/crossing.pl -- what crosses between lanes, the cases F2
%% left for later: a crew handed a list of jobs, an httpd server on the
%% caller's own thread, a thread joined in another clause than the one that
%% made it, a channel inside a term and one sent down another, and the
%% order a channel's messages are taken in. It is charted, never run, and
%% each predicate below is charted on its own, so its ids stay small.
%% test/flowchart.pl requires what each draws -- and job 1 of jobs/3 is
%% wrong on purpose: each job is proved on its own, so the A it halves is
%% free there, whatever job 2 binds.

:- use_module(library(thread)).
:- use_module(library(cowork)).
:- use_module(library(httpd)).

:- dynamic hits/1.
hits(0).

%% jobs(-Rs, -Ts, -Us): a crew handed jobs the source writes, a list it
%% writes only the head of, and one it does not write
jobs(Rs, Ts, Us) :-
    cowork_start(2, [], C),
    X = 7,
    cowork_map(C, [(half(A, H), H > 1), double(X, A), double(2, B)], Rs),
    listed(Gs),
    cowork_map(C, [double(5, _)|Gs], Ts),
    cowork_map(C, Gs, Us),
    cowork_stop(C),
    format("~w ~w ~w~n", [A, B, H]).

listed([double(1, _), double(2, _)]).

double(X, Y) :- Y is X * 2.
half(X, Y) :- Y is X // 2.

%% serve: the pages on this thread, then on a pool of two
serve :-
    count,
    httpd_serve(8080, [root(www)]),
    httpd_serve(8081, [workers(2)]).

count :-
    retract(hits(N)),
    N1 is N + 1,
    assertz(hits(N1)).

httpd_page('/hits', _, reply(200, [], N)) :- hits(N).

%% handles: a thread joined where its handle was handed back, or handed
%% on; two joined by one join; a pool joined one by one
handles :-
    spawned(Id),
    wait_for(Id),
    two(A, B),
    thread_join_all([A, B]),
    thread_pool(3, work(5), Is),
    forall(member(I, Is), thread_join(I, _)).

spawned(Id) :- thread_create(work(1), Id).
wait_for(Id) :- thread_join(Id, _).
two(I1, I2) :- thread_create(work(3), I1), thread_create(work(4), I2).

work(N) :- format("~w~n", [N]).

%% terms: a channel inside a term, taken out by the head, by =/2, by arg/3
terms :-
    channel_new(Ch),
    thread_create(by_head(cfg(Ch, 3)), T1),
    thread_create(by_unify(cfg(Ch, 3)), T2),
    thread_create(by_arg(cfg(Ch, 3)), T3),
    channel_send(Ch, hello),
    channel_close(Ch),
    thread_join(T1, _),
    thread_join(T2, _),
    thread_join(T3, _).

by_head(cfg(C, _)) :- channel_recv(C, M), work(M).
by_unify(Cfg) :- Cfg = cfg(C, _), channel_recv(C, M), work(M).
by_arg(Cfg) :- arg(1, Cfg, C), channel_recv(C, M), work(M).

%% reply: a channel sent down another, and answered on
reply :-
    channel_new(Req),
    thread_create(server(Req), T),
    channel_new(Back),
    channel_send(Req, ask(Back)),
    channel_recv(Back, A),
    work(A),
    thread_join(T, _).

server(Req) :- channel_recv(Req, ask(B)), channel_send(B, answer).

%% order: three messages in order -- two from one helper called twice --
%% and a thread that takes them in order
order :-
    channel_new(Ch),
    thread_create(take(Ch), T),
    channel_send(Ch, first),
    put(Ch, second),
    put(Ch, third),
    channel_close(Ch),
    thread_join(T, _).

put(Ch, X) :- channel_send(Ch, X).

take(Ch) :-
    channel_recv(Ch, A),
    channel_recv(Ch, B),
    one(Ch, C),
    format("~w ~w ~w~n", [A, B, C]).

one(Ch, C) :- channel_recv(Ch, C).

%% maybe, spin, pooled, choose: no send has its place -- one clause of two
%% sends, a recursion sends, a pool of two receives, a send comes after a
%% goal that can be redone
maybe :-
    channel_new(Ch),
    thread_create(one(Ch, _), T),
    either(Ch, a),
    thread_join(T, _).

either(Ch, X) :- X == a, !, channel_send(Ch, X).
either(_, _).

spin :-
    channel_new(Ch),
    thread_create(one(Ch, _), T),
    spin(Ch, 1),
    thread_join(T, _).

spin(Ch, N) :- channel_send(Ch, N), N < 3, N1 is N + 1, spin(Ch, N1).

pooled :-
    channel_new(Ch),
    thread_pool(2, one(Ch, _), Ids),
    channel_send(Ch, a),
    channel_send(Ch, b),
    thread_join_all(Ids).

choose :-
    channel_new(Ch),
    thread_create(one(Ch, _), T),
    member(X, [a, b]),
    channel_send(Ch, X),
    X == b, !,
    thread_join(T, _).

%% once_root: a thread's root is proved once, and nothing backtracks into it
once_root :-
    thread_create(work(0), Id),
    thread_join(Id, _).
