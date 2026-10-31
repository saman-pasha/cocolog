%  A library's call of a name a program file defines stays the system's,
%  run by BOTH SWI-Prolog and cocolog and the output compared byte for
%  byte: the program's own succ/2, msort/2 and memberchk/2 answer the
%  program's goals, and the libraries -- library(aggregate)'s count,
%  library(ugraphs)'s add_vertices/3 and transitive_closure/2,
%  library(dcg/basics)'s string_without//2 -- still have the builtins, as
%  a swipl library module calls system's. And M:G as a goal: system:G is
%  the builtin, any other module's the program's definition, with the cut
%  of the clause it is written in, and its errors swipl's.

:- use_module(library(aggregate)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(ugraphs)).     % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(dcg/basics)).

succ(X, Y) :- Y is X + 100.
msort(L, L).
memberchk(_, _) :- fail.

t(G) :- catch((G -> R = yes ; R = no), E, R = ex(E)), show(G-R).
show(T) :- copy_term(T, C), term_variables(C, Vs), bindv(Vs), print(C), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

cut_through :- user:(!, fail).
cut_through :- write(not_cut), nl.
mod_var(M) :- M:foo.
goal_var(G) :- m:G.
f(1).

main :-
    %% the program's own
    t(succ(1, _)), t(msort([b, a], _)), t(memberchk(a, [a])),
    %% the libraries', the builtins
    t(aggregate_all(count, member(_, [a, b, c]), _)),
    t(aggregate(count, member(_, [a, b, c]), _)),
    t(aggregate(bag(A)-count, member(A, [p, q]), _)),
    t(add_vertices([1-[3, 5], 2-[]], [9, 0, 1], _)),
    t(transitive_closure([1-[2], 2-[3], 3-[]], _)),
    t(phrase(string_without([0'x], _), [0'a, 0'b, 0'x, 0'c], _)),
    %% system:G is the builtin
    t(system:succ(1, _)), t(system:msort([b, a], _)), t(system:memberchk(a, [a])),
    t(call(system:succ, 1, _)), t(call(system:msort, [c, a], _)),
    t((G = system:succ(2, _), call(G))),
    t(system:(succ(3, _), true)),
    %% another module's is the program's
    t(user:succ(1, _)), t(lists:succ(1, _)), t(a:b:succ(1, _)),
    t(call(m:f, _)), t(m:f(_)),
    %% the cut of its clause
    t(cut_through),
    %% its errors
    t(mod_var(_)), t(goal_var(_)), t(mod_var(3)), t(goal_var(3)),
    t(mod_var(nomod)), t(goal_var(nobar)), t(user:nobar), t(system:nobaz),
    t(call(m:3, a)).
