%  repeat/0, swipl 9.0.4's ISO builtin (cocolog 3.39.0). It answers at
%  every retry and keeps its choice point for ever, so a cut is what ends
%  it. The case holds:
%  - its answers, and the control constructs around it;
%  - what a determinism guard makes of it, and of the other walks a
%    guarded frame's last call may leave, arg/3's and char_type/2's;
%  - what clause/2, predicate_property/2, current_predicate/1 and
%    listing/1 say of it;
%  - the program's own clause for it, refused at its load as any ISO
%    predicate's is.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.38.0 cocolog had no repeat/0, and every call raised
%  existence_error.
%
%  Not here (COMPAT.md): predicate_property/2's `iso', `nodebug',
%  `imported_from(system)' and `size(N)', which cocolog gives no builtin.

repeat :- true.

:- dynamic n/1.

pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

%% how G ended
t(L, G) :-
    catch(( G -> R = yes ; R = no ), E, R = caught(E)),
    pv(L-R), nl.

%% a counter that a retry of repeat/0 moves on: up to N, then on
count(N, K) :-
    nb_setval(rk, 0),
    repeat,
    nb_getval(rk, K0), K is K0 + 1, nb_setval(rk, K),
    K >= N, !.

%% the ISO idiom: read until the end, the database the input
drain(L) :-
    retractall(n(_)), assertz(n(3)), assertz(n(2)), assertz(n(1)),
    findall(X, ( repeat, ( retract(n(X)) -> true ; !, fail ) ), L).

p_guard_cut :- $, repeat, !.
p_guard_last :- $, repeat.
p_guard_after :- repeat, $, true.
p_guard_not_last :- $, repeat, true.
p_guard_younger :- $, member(_, [1, 2]), repeat.
p_guard_unified(X) :- $, X = 1, repeat.
p_guard_through :- p_guard_last.
p_guard_nested :- $, p_guard_last.
p_plain :- repeat.

%% the other walks a guarded frame's last call may leave: arg/3's index
%% unbound, char_type/2's character
p_arg :- $, arg(_, f(a, b), _).
p_arg_one :- $, arg(_, f(a), _).
p_arg_last :- $, arg(N, f(a, b), b), N == 2.
p_ctype :- $, char_type(_, to_lower(a)).

main :-
    answers, controls, guards, introspection, errors.

answers :-
    format("~n=== answers~n"),
    t(once, (repeat, !)),
    t(count, (count(5, K1), K1 == 5)),
    t(findall_cut, (findall(x, (repeat, !), L2), L2 == [x])),
    t(first_three, (findall(I, (count(3, I)), L3), L3 == [3])),
    t(drain, (drain(L4), L4 == [3, 2, 1])),
    t(bindings_undone, (nb_setval(rb, 0), repeat, nb_getval(rb, B0), B1 is B0 + 1,
                        nb_setval(rb, B1), X5 = B1, B1 >= 2, !, X5 == 2)),
    t(ten, (nb_setval(rt, 0), repeat, nb_getval(rt, T0), T1 is T0 + 1, nb_setval(rt, T1),
            T1 >= 10, !, T1 == 10)),
    t(plain, (p_plain, !)).

controls :-
    format("~n=== controls~n"),
    t(call, call(repeat)),
    t(once, once(repeat)),
    t(not_not, \+ \+ repeat),
    t(if_then, (repeat -> true ; fail)),
    t(if_then_else, (repeat -> R6 = then ; R6 = else)), print(R6), nl,
    t(soft_cut, ((repeat *-> true ; fail), !)),
    t(meta_cut, (call((repeat, !)))),
    t(catch, (catch(repeat, _, true), !)),
    t(findall_limit, (nb_setval(rf, 0),
                      findall(F, ( repeat, nb_getval(rf, F0), F is F0 + 1, nb_setval(rf, F),
                                   ( F >= 4 -> ! ; true ) ), L7), L7 == [1, 2, 3, 4])),
    t(forall_cut, forall((repeat, !), true)).

guards :-
    format("~n=== guards~n"),
    t(goal, $(repeat)),
    t(goal_cut, $((repeat, !))),
    t(goal_conj, ($(repeat), true)),
    t(clause_cut, p_guard_cut),
    t(clause_last, p_guard_last),
    t(clause_after, p_guard_after),
    t(clause_not_last, p_guard_not_last),
    t(clause_younger, p_guard_younger),
    t(clause_unified, p_guard_unified(_)),
    t(clause_through, p_guard_through),
    t(clause_nested, p_guard_nested),
    t(arg, p_arg),
    t(arg_one, p_arg_one),
    t(arg_one_below, (member(X1, [1, 2]), p_arg_one, X1 == 2)),
    t(arg_last, p_arg_last),
    t(ctype, p_ctype).

introspection :-
    format("~n=== introspection~n"),
    t(clause, clause(repeat, _)),
    t(built_in, predicate_property(repeat, built_in)),
    t(foreign, predicate_property(repeat, foreign)),
    t(static, predicate_property(repeat, static)),
    t(defined, predicate_property(repeat, defined)),
    t(dynamic, predicate_property(repeat, dynamic)),
    t(current, current_predicate(repeat/0)),
    t(callable, callable(repeat)),
    t(listing, listing(repeat/0)),
    t(listing_name, listing(repeat)).

errors :-
    format("~n=== errors~n"),
    t(abolish, abolish(repeat/0)),
    t(arity_one, catch(repeat(1), error(E, _), (pv(E), nl))),
    t(call_extra, catch(call(repeat, x), error(E2, _), (pv(E2), nl))).
