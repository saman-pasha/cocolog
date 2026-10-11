%% runtime.pl -- what a program makes, or picks, as it runs: dynamic
%% predicates, and goals called through call/N.
%%
%% seen/1 is declared here and has no clause; tally/1 is declared here and
%% starts with one; note/1 is declared by notes.pl, which this file loads.
%% apply_to/3 and try/1 call a goal the source does not name; twice/2 names
%% it, so the chart follows it to double/2. nosuch/1 is defined nowhere.

:- use_module('test/flowchart/notes.pl').

:- dynamic seen/1.
:- dynamic tally/1.

tally(0).

%% run(+X, -Y)
run(X, Y) :-
    visit(X),
    apply_to(double, X, _),
    twice(X, Y),
    try(seen(X)),
    ( note(X) -> true ; true ),
    broken(X).

%% visit(+X): remember X once, and count the visits
visit(X) :-
    (   seen(X) -> true ; assertz(seen(X)) ),
    tally(N),
    retract(tally(N)),
    N1 is N + 1,
    assertz(tally(N1)).

%% apply_to(:Goal, +X, -Y): Goal called with two arguments more
apply_to(Goal, X, Y) :- call(Goal, X, Y).

%% twice(+X, -Y)
twice(X, Y) :- call(double, X, Y0), call(double(Y0), Y).

%% double(+X, -Y)
double(X, Y) :- Y is X * 2.

%% try(:Goal): Goal, or nothing
try(Goal) :- ( call(Goal) -> true ; true ).

%% broken(+X)
broken(X) :- nosuch(X).
