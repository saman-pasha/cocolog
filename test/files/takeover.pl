%  A program file's own definition of a system predicate of no arguments,
%  of not/1, ignore/1, trace/0 and notrace/0, and of an ISO one after
%  redefine_system_predicate/1, run by BOTH SWI-Prolog and cocolog and the
%  output compared byte for byte, the load's report included: the
%  program's clauses answer every call of the name -- a goal, a clause's
%  body, call/N, a search's goal -- as swipl calls a user file's definition
%  of a system predicate that is not ISO, and redefine_system_predicate/1
%  lets an ISO one be defined. (Through 3.0.4 a name of no arguments, the
%  constructs and redefine_system_predicate/1 were the engine's whatever
%  the file said; the clauses loaded and nothing called them.)

garbage_collect :- write(my_gc), nl.
trace :- write(my_trace), nl.
notrace :- write(my_notrace), nl.
not(G) :- write(my_not(G)), nl.
ignore(G) :- write(my_ignore(G)), nl.

:- redefine_system_predicate(atom_length(_, _)).
atom_length(_, 99).
:- redefine_system_predicate(is(_, _)).
is(my_is, _).
:- redefine_system_predicate(<(_, _)).
<(_, _) :- write(my_less), nl.

t(G) :- catch((G -> R = yes ; R = no), E, R = ex(E)), show(G-R).
show(T) :- copy_term(T, C), term_variables(C, Vs), bindv(Vs), print(C), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

%  bodies that call each, compiled with the rest of the file
body_gc :- garbage_collect.
body_not :- not(fail).
body_ignore :- ignore(fail), write(after), nl.
body_len(N) :- atom_length(abc, N).
body_both(N) :- not(true), atom_length(x, N).
body_late :- atom_length(x, _), not(fail), ignore(fail).
body_is(Y) :- Y is 1 + 2.
body_is_late(Y) :- atom_length(ab, _), Y is 1 + 2.
body_less :- 2 < 1, write(after_less), nl.
body_less_late :- atom_length(ab, _), 2 < 1, write(after_less), nl.

main :-
    t(garbage_collect), t(body_gc), t(call(garbage_collect)),
    t(findall(x, garbage_collect, _)),
    t(trace), t(notrace),
    t(not(true)), t(not(fail)), t(body_not), t(call(not, true)),
    t(ignore(fail)), t(body_ignore), t(\+ not(fail)),
    t(forall(member(X, [1, 2]), not(X))),
    t(atom_length(abc, _)), t(body_len(_)), t(call(atom_length(xy), _)),
    t(body_both(_)), t(body_late),
    t(body_is(_)), t(body_is_late(_)), t(body_less), t(body_less_late),
    t(call(is, _, 1 + 2)), t(_ is 1 + 2),
    t(system:not(fail)), t(system:garbage_collect), t(system:atom_length(abc, _)),
    t(system:ignore(garbage_collect)), t(system:not(not(true))),
    t(predicate_property(not(_), number_of_clauses(_))),
    t(predicate_property(atom_length(_, _), built_in)),
    t(predicate_property(atom_codes(_, _), built_in)),
    t(redefine_system_predicate(foo(_))),
    t(redefine_system_predicate(user:atom_codes(_, _))),
    t(atom_codes(ab, _)),
    t(redefine_system_predicate(_)),
    t(redefine_system_predicate(3)).
