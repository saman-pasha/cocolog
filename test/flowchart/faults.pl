%% faults.pl -- one of each thing library(flow/chart) finds, and near misses
%% it must not. Each predicate's comment says which.

:- dynamic seen/1.

%% check(+L): every case, each on a branch of its own, so a case that
%% never succeeds leaves the others reached
check(L) :-
    (   total(L, _)
    ;   ok_total(L, _)
    ;   maybe(L, _)
    ;   name_size(3)
    ;   run_it
    ;   phrase(xs, L)
    ;   spin(L)
    ;   ping(L)
    ;   count(L, _)
    ;   kind(L, _)
    ;   kind2(L, _)
    ;   first_pos(L, _)
    ;   pick_one(L, _)
    ;   safe_first(L, _)
    ;   helper(L)
    ;   seen(L)
    ;   percent(_)
    ;   ( L == [] -> Q = '5%' ; true ), percent(Q)
    ;   build(atom, _)
    ;   which(L, _)
    ;   same(L, [])
    ;   wrapped(_)
    ).

%% total(+L, -T): S is used before it is bound -- instantiation
total(L, T) :-
    T is S + 1,
    sum_list(L, S).

%% ok_total(+L, -T): the same, in the right order -- nothing
ok_total(L, T) :-
    sum_list(L, S),
    T is S + 1.

%% maybe(+L, -T): Y is bound on one path only -- nothing: the chart says
%% only what holds on every path
maybe(L, T) :-
    (   L == [] -> Y = 0 ; true ),
    T is Y + 1.

%% name_size(+N): atom_length/2 handed an unbound atom -- instantiation
name_size(N) :-
    atom_length(A, N),
    atom(A).

%% run_it: a closure with no goal in it -- instantiation
run_it :-
    call(G),
    write(G).

%% xs//0: calls itself before reading anything -- left recursion
xs --> xs, [x].
xs --> [].

%% spin(+X): calls itself with what it was given -- left recursion
spin(X) :- spin(X).

%% ping(+X), pong(+X): the same, through each other -- left recursion
ping(X) :- pong(X).
pong(X) :- ping(X).

%% count(+L, -N): recursion on the tail -- nothing
count([], 0).
count([_|T], N) :- count(T, N0), N is N0 + 1.

%% kind(+X, -K): the first clause takes every call -- unreachable clause
kind(_, any) :- !.
kind(1, one).

%% kind2(+X, -K): a test before the cut -- nothing
kind2(X, small) :- X < 10, !.
kind2(_, big).

%! first_pos(+L, -X) is det.
%  The first positive number of L -- which can fail: det promise
first_pos(L, X) :- member(X, L), X > 0, !.

%! pick_one(+L, -X) is det.
%  Any element -- which can answer again: det promise
pick_one(L, X) :- member(X, L).

%! safe_first(+L, -X) is semidet.
%  Kept: semidet -- nothing
safe_first([X|_], X).

%% helper(+L): length/2 misspelt -- unknown procedure, and a near name
helper(L) :- lenght(L, _).

%% THREE NEAR MISSES THE TRANSLATOR TAUGHT, each once a false finding there.
%% percent(?W): atom/1 holds only of a bound W, so atom_concat/3 is handed
%% one -- and called with W free, nothing past atom/1 ever runs -- nothing
percent(W) :- atom(W), atom_concat(N, '%', W), atom_length(N, _).

%% build(+C, ?W): =.. makes G from a list whose W may be free -- nothing
build(C, W) :- G =.. [C, W], call(G).

%% which(+A, -B): =.. against a list with a pattern in it tests A, and can
%% fail, so the second clause is reached -- nothing
which(A, B) :- A =.. [_, w(X)], !, B = X.
which(A, A).

%% same(+X, +Y): one variable in two inputs, so the first head can fail and
%% the second clause is reached -- nothing
same(X, X) :- !.
same(_, _).

%% wrapped(-W): wrap/1 binds W to a box, so functor/3 is handed one --
%% nothing
wrapped(W) :- wrap(W), functor(W, _, _).
wrap(box(_)).
