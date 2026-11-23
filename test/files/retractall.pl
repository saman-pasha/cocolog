%% retractall/1 as swipl 9.0.4's (cocolog 3.78.11). Run by test/files.pl
%% beside swipl, the two outputs compared byte for byte; a term's variables
%% are named by pv/1.
%%
%% retractall(H) takes every clause whose head unifies with H, whatever its
%% body, and binds nothing of H. Since 3.78.11 it is one walk of the clauses
%% that stood when it began (swipl's pl_retractall), where through 3.78.10
%% it took the first match and walked again from the predicate's first
%% clause, so the shapes here are where the matches stand -- late, early,
%% between others, keyed on an argument or none, in a predicate big enough
%% to be indexed -- and what an open call goes on seeing: a call of the
%% predicate open when retractall/1 ran sees every clause that stood when it
%% began, as ISO's logical update view says, and a later call none of them.
%% Left out on purpose: a single-sided rule's predicate, whose last clause
%% cocolog's retractall/1 takes along (backlog #335), and a builtin's name,
%% whose facts cocolog keeps where swipl refuses them (COMPAT.md).

:- dynamic p/2, q/1, w/1, nd2/1, zz/0, c/2.

pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

s(Label, Value) :- write(Label), write(=), pv(Value), nl.
t(G) :- catch(( G -> R = yes ; R = no ), E, R = E), pv(R), nl.

q5 :- retractall(q(_)), forall(between(1, 5, I), assertz(q(I))).
all_q(L) :- findall(X, q(X), L).
all_p(L) :- findall(A-B, p(A, B), L).
%% the clauses as clause/2 sees them, a rule's body too
all_pc(L) :- findall((A-B :- Body), clause(p(A, B), Body), L).
fill(Tag, From, To) :- forall(between(From, To, I), assertz(p(I, Tag))).
%% how many clauses, and the first and the last
shape(L, N-F-Z) :- length(L, N), ( L = [F|_], last(L, Z) -> true ; F = none, Z = none ).

%% whether each answer of G left a choice point
dets(G, Ds) :-
    findall(D, ( setup_call_cleanup(true, G, D0 = det), ( D0 == det -> D = det ; D = nondet ) ), Ds).

%% ---- where the matches stand ----
ra01 :- retractall(p(_, _)), fill(a, 1, 30), fill(b, 31, 40), retractall(p(_, b)),
        all_p(L), shape(L, S), s(ra01, S).
ra02 :- retractall(p(_, _)), fill(b, 1, 10), fill(a, 11, 40), retractall(p(_, b)),
        all_p(L), shape(L, S), s(ra02, S).
ra03 :- retractall(p(_, _)), forall(between(1, 30, I), ( K is I mod 3, assertz(p(I, K)) )),
        retractall(p(_, 0)), all_p(L), s(ra03, L).
ra04 :- retractall(p(_, _)), forall(between(1, 40, I), ( K is I mod 4, assertz(p(K, I)) )),
        retractall(p(2, _)), all_p(L), s(ra04, L).
%% big enough to be indexed, the matches late and early
ra05 :- retractall(p(_, _)), fill(a, 1, 2000), fill(b, 2001, 2500), retractall(p(_, b)),
        all_p(L), shape(L, S), s(ra05, S),
        retractall(p(_, _)), fill(b, 1, 500), fill(a, 501, 2500), retractall(p(_, b)),
        all_p(L2), shape(L2, S2), s(ra05_early, S2).
ra06 :- retractall(p(_, _)), forall(between(1, 1000, I), ( K is I mod 10, assertz(p(K, I)) )),
        retractall(p(3, _)), all_p(L), shape(L, S), s(ra06, S),
        findall(I, p(3, I), L3), s(ra06_left3, L3), retractall(p(_, 500)), all_p(L4), shape(L4, S4), s(ra06_500, S4).
%% every clause
ra07 :- retractall(p(_, _)), fill(a, 1, 50), retractall(p(_, _)), all_p(L), s(ra07, L),
        assertz(p(1, x)), assertz(p(2, y)), all_p(L2), s(ra07_again, L2).

%% ---- what a head is matched by ----
ra08 :- retractall(p(_, _)), assertz(p(f(a), 1)), assertz(p(f(b), 2)), assertz(p(g(a), 3)),
        assertz(p(_, 4)), assertz(p(f(_), 5)), assertz(p(f(a), 6)),
        retractall(p(f(a), _)), all_pc(L), s(ra08, L).
ra09 :- retractall(p(_, _)), assertz(p(1, 1)), assertz(p(1, 2)), assertz(p(2, 2)), assertz(p(_, _)),
        assertz(p(X, X)), assertz(p(3, 4)), retractall(p(Y, Y)), all_pc(L), s(ra09, L), s(ra09_unbound, X-Y).
ra10 :- retractall(p(_, _)), assertz((p(X, r) :- X > 1)), assertz(p(1, r)), assertz((p(_, s) :- fail)),
        assertz(p(2, s)), retractall(p(_, r)), all_pc(L), s(ra10, L).
ra11 :- retractall(p(_, _)), fill(a, 1, 5), retractall(p(X, a)), s(ra11, X), all_p(L), s(ra11_left, L).
ra12 :- retractall(p(_, _)), fill(a, 1, 5), fill(b, 1, 5), X = 3, retractall(p(X, _)), all_p(L), s(ra12, L).
ra13 :- retractall(zz), assertz(zz), assertz(zz), assertz((zz :- fail)), retractall(zz),
        findall(B, clause(zz, B), L), s(ra13, L).

%% ---- a call open on the predicate ----
ra14 :- q5, findall(X, ( q(X), ( X == 2 -> retractall(q(_)) ; true ) ), L), s(ra14, L), all_q(A), s(ra14_left, A).
ra15 :- q5, findall(X, ( q(X), ( X == 1 -> retractall(q(3)) ; true ) ), L), s(ra15, L), all_q(A), s(ra15_left, A).
ra16 :- q5, findall(X, ( q(X), ( X == 1 -> retractall(q(2)), retractall(q(4)) ; true ) ), L), s(ra16, L),
        all_q(A), s(ra16_left, A).
ra17 :- q5, findall(X-Y, ( q(X), q(Y), ( X == 1, Y == 1 -> retractall(q(_)) ; true ) ), L), s(ra17, L),
        all_q(A), s(ra17_left, A).
%% a clause dead under the open call already, and taken again
ra18 :- q5, findall(X, ( q(X), ( X == 1 -> retract(q(2)), retractall(q(_)) ; true ) ), L), s(ra18, L),
        all_q(A), s(ra18_left, A), assertz(q(9)), all_q(B), s(ra18_after, B).
%% the dead of an earlier change waiting, and a retractall with no call open
ra19 :- q5, forall(q(X), ( X == 2 -> retract(q(4)) ; true )), all_q(A0), s(ra19_dead, A0),
        retractall(q(5)), all_q(A), s(ra19, A), retractall(q(_)), all_q(B), s(ra19_all, B).
%% retract/1's walk open on the predicate goes on to the clauses retractall/1 took
ra20 :- q5, findall(X, ( retract(q(X)), ( X == 1 -> retractall(q(_)) ; true ) ), L), s(ra20, L),
        all_q(A), s(ra20_left, A).
ra21 :- retractall(w(_)), forall(between(1, 3000, I), assertz(w(I))),
        findall(X, ( w(X), ( X == 1 -> retractall(w(_)) ; true ) ), L), shape(L, S), s(ra21, S),
        findall(Y, w(Y), A), s(ra21_left, A).

%% ---- none, and what will not do ----
ra22 :- q5, retractall(q(9)), all_q(A), s(ra22, A), t(retractall(q(9))).
ra23 :- t(retractall(nd2(_))), ( predicate_property(nd2(_), dynamic) -> P = (dynamic) ; P = none ), s(ra23, P).
ra24 :- q5, dets(retractall(q(_)), D), s(ra24, D), q5, dets(retractall(q(3)), D2), s(ra24_one, D2).
ra25 :- t(retractall(_)), t(retractall(3)), t(retractall(foo:3)), t(retractall((_ :- true))).
%% the same clause twice, and clauses that differ in their bodies alone
ra26 :- retractall(c(_, _)), assertz(c(1, a)), assertz(c(1, a)), assertz((c(1, a) :- true)),
        assertz((c(1, a) :- c(2, b))), assertz(c(2, b)), retractall(c(1, a)),
        findall(A-B-Body, clause(c(A, B), Body), L), s(ra26, L).

main :-
    forall(member(G, [ra01, ra02, ra03, ra04, ra05, ra06, ra07, ra08, ra09, ra10, ra11, ra12, ra13,
                      ra14, ra15, ra16, ra17, ra18, ra19, ra20, ra21, ra22, ra23, ra24, ra25, ra26]),
           ( catch(G, E, ( s(G, raised(E)), fail )) -> true ; s(G, failed) )).
