%  current_op/3, current_predicate/1, predicate_property/2 and sub_atom/5
%  with the text it looks for given: where their last answer leaves no
%  choice point, as swipl 9.0.4's C predicates leave none (cocolog 3.25.0),
%  and the order current_op/3 answers a name's definitions in -- the
%  program's first, then the system's, each prefix before infix. Told by
%  $/0 at the exit of a clause that calls it and then `true', where a choice
%  point left is determinism_error(dd/1, det, nondet, guard), and at the
%  K-th answer of a goal (dk/2). Run by BOTH SWI-Prolog and cocolog, output
%  compared byte for byte. Not here (COMPAT.md): current_op/3 with its name
%  unbound, whose answers swipl gives in its hash tables' order, the last
%  one leaving a choice point or not by where its tables put it; postfix
%  operators, which cocolog has none of.

:- op(700, xfx, ===>).
:- op(200, fy, ===>).
:- op(700, xfx, volatile).

:- dynamic foo/1.
foo(1).
bar(1).
bar(1, 2).

dd(G) :- $, G, true.
d(G) :- catch((dd(G) -> shown(G, S), print(det(S)) ; print(fail)), error(E, _), (shown(E, S), print(S))), nl.
%% the K-th answer of G, in a guarded clause: no choice point left at it, or one
dk(G, K) :- $, nb_setval(cd_k, 0), G, nb_getval(cd_k, C), C1 is C + 1, nb_setval(cd_k, C1), C1 == K, true.
k(G, K) :- catch((dk(G, K) -> shown(G, S), print(det(K, S)) ; print(fail)), error(E, _), (shown(E, S), print(S))), nl.
%% the same, printing only whether: the answer, and its K, differ between the systems
kq(G, K) :- catch((dk(G, K) -> print(det) ; print(fail)), error(E, _), (shown(E, S), print(S))), nl.
o(G) :- findall(G, G, L), print(L), nl.
shown(T, S) :- copy_term(T, S), term_variables(S, Vs), maplist(=('_'), Vs).

ops :-
    d(current_op(700, xfx, is)), d(current_op(_, xfx, is)), d(current_op(_, _, is)),
    d(current_op(_, _, mod)), d(current_op(_, _, dynamic)), d(current_op(_, _, '|')),
    d(current_op(_, _, ',')), d(current_op(1000, xfy, ',')),
    d(current_op(_, _, nosuchop)), d(current_op(700, _, mod)),
    %% two definitions: the first leaves a choice point, the last none
    d(current_op(_, _, -)), k(current_op(_, _, -), 2), d(current_op(500, _, -)),
    d(current_op(_, fy, -)), k(current_op(_, _, +), 2), k(current_op(_, _, :-), 2),
    %% and their order
    o(current_op(_, _, -)), o(current_op(_, _, +)), o(current_op(_, _, :-)),
    ( current_op(P1, T1, -) -> print(P1-T1) ; print(none) ), nl,
    %% the program's: its prefix before its infix, whatever order they were
    %% declared in, and the program's before the system's
    o(current_op(_, _, ===>)), k(current_op(_, _, ===>), 2), d(current_op(200, _, ===>)),
    o(current_op(_, _, volatile)), k(current_op(_, _, volatile), 2),
    d(current_op(_, xfx, volatile)), d(current_op(1150, _, volatile)).

preds :-
    d(current_predicate(foo/1)), d(current_predicate(bar/2)), d(current_predicate(bar/1)),
    d(current_predicate(nosuch/1)), d(current_predicate(foo/2)),
    %% an arity unbound: swipl's leaves a choice point at every answer, the last too
    k(current_predicate(bar/_), 1), k(current_predicate(bar/_), 2),
    d(predicate_property(foo(_), dynamic)), d(predicate_property(foo(_), number_of_clauses(_))),
    d(predicate_property(bar(_), number_of_clauses(_))), d(predicate_property(foo(_), defined)),
    d(predicate_property(foo(_), static)), d(predicate_property(bar(_), dynamic)),
    findall(x, predicate_property(foo(_), _), L1), length(L1, N1), kq(predicate_property(foo(_), _), N1),
    findall(x, predicate_property(bar(_), _), L2), length(L2, N2), kq(predicate_property(bar(_), _), N2).

subs :-
    d(sub_atom(abc, _, 1, _, c)), d(sub_atom(abc, _, _, _, abc)), d(sub_atom(abc, _, _, 0, c)),
    d(sub_atom(abc, _, _, _, x)), d(sub_atom(abc, 1, _, _, c)),
    d(sub_atom(abcabc, _, _, _, c)), k(sub_atom(abcabc, _, _, _, c), 2),
    d(sub_atom(abcabc, 2, _, _, c)), d(sub_atom(abcabc, 5, _, _, c)),
    d(sub_atom(abcabc, _, 1, 0, c)), d(sub_atom(abcabc, 1, _, _, bc)),
    k(sub_atom(abcabc, _, _, _, bc), 2), o(sub_atom(abcabc, _, _, _, bc)).

main :- ops, preds, subs.
