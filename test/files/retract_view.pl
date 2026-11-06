%% retract/1 and clause/2 under ISO's logical update view, as swipl 9.0.4's
%% (cocolog 3.28.0). Run by test/files.pl beside swipl, the two outputs
%% compared byte for byte; a term's variables are named by pv/1.
%%
%% retract/1 is re-executable: each answer takes the next clause of the
%% ones that stood when it began, a clause asserted since is none of them,
%% and one retracted since is still an answer, retracted already. clause/2
%% walks the clauses that stood when it began, whatever its own goals do to
%% the predicate. Both are keyed as a call of the predicate is, on its first
%% argument or another (swipl's JIT index), and leave no choice point at
%% their last candidate. `retract(H)' takes a fact and `retract((H :- B))' a
%% fact or a rule; neither takes a single-sided rule, which swipl 9.0.4's
%% retract/1 never matches, and clause/2 shows one as swipl's does.
%% Left out on purpose (COMPAT.md): a retract of a static predicate's
%% clause, or of a library predicate's, which swipl refuses and cocolog
%% takes; clause/2 of a predicate swipl defines in C.

:- dynamic q/1, r/1, k/2, m/2, z/0, h/1, e/1, tt/1, w/1, sy/1, cnt/1, fz/0.

pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

s(Label, Value) :- write(Label), write(=), pv(Value), nl.
q3 :- retractall(q(_)), assertz(q(1)), assertz(q(2)), assertz(q(3)).
all_q(L) :- findall(X, q(X), L).
k20 :- retractall(k(_, _)), forall(between(1, 20, I), ( J is I mod 4, assertz(k(I, J)) )).
m6 :- retractall(m(_, _)), assertz(m(a, 1)), assertz(m(b, 2)), assertz(m(a, 3)), assertz(m(c, 4)),
      assertz(m(_, 5)), assertz(m(b, 6)).

%% whether each answer of G left a choice point: the cleanup has run by an
%% answer's exit only where it was the last
dets(G, Ds) :-
    findall(D, ( setup_call_cleanup(true, G, D0 = det), ( D0 == det -> D = det ; D = nondet ) ), Ds).
t(G) :- catch(( G -> R = yes ; R = no ), E, R = E), pv(R), nl.

%% ---- every answer ----
r01 :- q3, findall(X, retract(q(X)), L), s(r01, L), all_q(A), s(r01_left, A).
r02 :- q3, ( retract(q(X)), write(X), fail ; true ), nl, all_q(A), s(r02_left, A).
r03 :- retractall(z), assertz(z), assertz(z), assertz(z), findall(x, retract(z), L), s(r03, L).
r04 :- retractall(e(_)), assertz(e(f(_))), assertz(e(f(a))), assertz(e(g)),
       findall(X, retract(e(f(X))), L), s(r04, L), findall(Y, e(Y), A), s(r04_left, A).
r05 :- q3, forall(retract(q(_)), true), all_q(A), s(r05, A).
r06 :- retractall(tt(_)), forall(between(1, 2000, I), assertz(tt(I))),
       findall(X, retract(tt(X)), L), length(L, N), last(L, Z), s(r06, N-Z),
       forall(between(1, 2000, I), assertz(tt(I))),
       findall(X, ( clause(tt(X), true), X mod 500 =:= 0 ), L2), s(r06_clause, L2).

%% ---- a fact, a rule ----
r07 :- retractall(r(_)), assertz(r(1)), assertz((r(X) :- X > 5)), assertz(r(2)), assertz((r(_) :- fail)),
       findall(X-B, retract((r(X) :- B)), L), s(r07, L).
r08 :- retractall(r(_)), assertz(r(1)), assertz((r(X) :- X > 5)), assertz(r(2)),
       findall(X, retract(r(X)), L), s(r08, L), findall(Y-B, clause(r(Y), B), A), s(r08_left, A).
r09 :- q3, findall(X, retract((q(X) :- true)), L), s(r09, L).
r10 :- retractall(h(_)), assertz((h(X) :- X = 1, true)), assertz((h(X) :- member(X, [a, b]))),
       assertz(h(c)),
       findall(B, retract((h(_) :- B)), L), s(r10, L).
r11 :- retractall(r(_)), assertz((r(X) :- X = one)), assertz((r(X) :- X = two)),
       findall(X, retract((r(X) :- X = two)), L), s(r11, L), findall(Y-B, clause(r(Y), B), A), s(r11_left, A).

%% ---- the last candidate leaves no choice point ----
r12 :- q3, dets(retract(q(3)), D1), s(r12a, D1),
       q3, dets(retract(q(1)), D2), s(r12b, D2),
       q3, dets(retract(q(_)), D3), s(r12c, D3),
       retractall(q(_)), assertz(q(7)), dets(retract(q(_)), D4), s(r12d, D4).
r13 :- k20, dets(retract(k(_, 3)), D1), s(r13a, D1),
       k20, dets(retract(k(19, _)), D2), s(r13b, D2),
       k20, dets(retract(k(_, _)), D3), length(D3, N3), last(D3, L3), s(r13c, N3-L3),
       k20, findall(I, retract(k(I, 2)), L4), s(r13d, L4).
r14 :- m6, dets(retract(m(a, _)), D1), s(r14a, D1),
       m6, dets(retract(m(b, _)), D2), s(r14b, D2),
       m6, dets(retract(m(_, 4)), D3), s(r14c, D3),
       m6, findall(X, retract(m(X, 5)), L4), s(r14d, L4).
r15 :- q3, dets(clause(q(3), true), D1), s(r15a, D1),
       dets(clause(q(1), true), D2), s(r15b, D2),
       dets(clause(q(_), true), D3), s(r15c, D3),
       k20, dets(clause(k(_, 3), true), D4), s(r15d, D4),
       m6, dets(clause(m(c, _), true), D5), s(r15e, D5),
       dets(clause(m(_, 6), true), D6), s(r15f, D6).

%% ---- what the walk sees of what its own goals do ----
r16 :- q3, findall(X, ( retract(q(X)), ( X == 1 -> retract(q(2)) ; true ) ), L), s(r16, L), all_q(A), s(r16_left, A).
r17 :- q3, findall(X, ( retract(q(X)), ( X == 1 -> retractall(q(_)) ; true ) ), L), s(r17, L), all_q(A), s(r17_left, A).
r18 :- q3, findall(X, ( retract(q(X)), assertz(q(9)) ), L), s(r18, L), all_q(A), s(r18_left, A).
r19 :- q3, findall(X, ( retract(q(X)), asserta(q(0)) ), L), s(r19, L), all_q(A), s(r19_left, A).
r20 :- q3, findall(X-L1, ( retract(q(X)), findall(Y, retract(q(Y)), L1) ), L), s(r20, L).
r21 :- q3, findall(X, ( retract(q(X)), \+ \+ retract(q(_)) ), L), s(r21, L), all_q(A), s(r21_left, A).
r22 :- q3, findall(X-Y, ( retract(q(X)), clause(q(Y), true) ), L), s(r22, L).
r23 :- q3, findall(X-Y, ( clause(q(X), true), retract(q(Y)) ), L), s(r23, L), all_q(A), s(r23_left, A).
r24 :- q3, findall(X, ( retract(q(X)), assertz(q(X)) ), L), s(r24, L), all_q(A), s(r24_left, A).
r25 :- q3, findall(X, ( q(X), retract(q(_)) ), L), s(r25, L), all_q(A), s(r25_left, A).
r26 :- q3, findall(X, ( clause(q(X), true), ( X == 1 -> retract(q(1)) ; true ) ), L), s(r26a, L),
       q3, findall(X2, ( clause(q(X2), true), ( X2 == 1 -> asserta(q(0)) ; true ) ), L2), s(r26b, L2),
       q3, findall(X3, ( clause(q(X3), true), assertz(q(4)) ), L3), s(r26c, L3),
       q3, findall(X4, ( clause(q(X4), true), retract(q(X4)) ), L4), s(r26d, L4), all_q(A), s(r26_left, A).
r27 :- q3, findall(X-Y, ( retract(q(X)), retract(q(Y)) ), L), s(r27, L), all_q(A), s(r27_left, A).
r28 :- k20, findall(I, ( retract(k(I, 1)), ( I == 1 -> retract(k(13, 1)), asserta(k(0, 1)) ; true ) ), L),
       s(r28, L), findall(I2, k(I2, 1), A), s(r28_left, A).
r29 :- retractall(w(_)), assertz(w(1)), assertz(w(2)),
       ( retract(w(X)), ( X < 3 -> Y is X + 10, assertz(w(Y)) ; true ), fail ; true ),
       findall(W, w(W), Ws), s(r29_left, Ws).
bump :- retract(cnt(C)), D is C + 1, assertz(cnt(D)).
r30 :- q3, retractall(cnt(_)), assertz(cnt(0)),
       ( retract(q(_)), bump, fail ; true ), cnt(N), s(r30, N), all_q(A), s(r30_left, A).

%% ---- a cut, a throw, once/1 ----
r31 :- q3, ( retract(q(X)), ! ; true ), s(r31, X), all_q(A), s(r31_left, A).
r32 :- q3, catch(( retract(q(X)), X == 2, throw(found(X)) ), found(Y), true), s(r32, Y), all_q(A), s(r32_left, A).
r33 :- q3, once(retract(q(X))), s(r33, X), all_q(A), s(r33_left, A).
cut2 :- retract(q(X)), X == 2, !.
r34 :- q3, cut2, all_q(A), s(r34, A).

%% ---- single-sided rules ----
r35 :- retractall(sy(_)), assertz((sy(1) => true)), assertz((sy(X) => X = 2)),
       findall(Y-B, clause(sy(Y), B), L), s(r35_clause, L),
       findall(Z, retract(sy(Z)), L2), s(r35a, L2),
       findall(Z2-B2, retract((sy(Z2) :- B2)), L3), s(r35b, L3),
       findall(Z3, retract((sy(Z3) => true)), L4), s(r35c, L4),
       findall(Z4-B4, retract((sy(Z4) => B4)), L5), s(r35d, L5),
       findall(Y5-B5, clause(sy(Y5), B5), L6), s(r35_left, L6).

%% ---- a predicate nobody defined, and what will not do ----
r36 :- t(retract(nosuch(_))),
       ( predicate_property(nosuch(_), dynamic) -> P = dyn ; P = none ), s(r36, P),
       t(clause(nosuch(_), _)).
r37 :- t(retract(_)), t(retract((_ :- true))), t(retract(3)), t(retract((_ :- _))),
       t(retract((foo :- 3))), q3, t(retract((q(_) :- 3))), t(retract((q(_) :- (true, 3)))),
       t(retract(q)).
r38 :- t(clause(_, _)), t(clause(3, _)), q3, t(clause(q(_), 3)), t(clause(q(_), (true, 3))),
       t(clause(q(_), foo:bar)), t(clause(q, _)), t(clause(f(), _)), t(retract(f())).

%% ---- a call of the predicate open around the walk, and a qualifier ----
r39 :- q3, findall(X, ( q(X), retract(q(_)) ), L), s(r39, L), all_q(A), s(r39_left, A).
r40 :- q3, findall(X, retract(user:q(X)), L), s(r40a, L),
       q3, findall(X2-B2, retract((user:q(X2) :- B2)), L2), s(r40b, L2),
       q3, findall(X3, clause(user:q(X3), true), L3), s(r40c, L3).

%% ---- the count after a walk whose own goals retracted what it came to next ----
r41 :- q3, findall(X, ( retract(q(X)), ( X == 1 -> retract(q(2)) ; true ) ), L), s(r41a, L),
       assertz(q(7)), predicate_property(q(_), number_of_clauses(N)), s(r41a_count, N), all_q(A), s(r41a_left, A),
       q3, findall(X2, ( retract(q(X2)), ( X2 == 1 -> retractall(q(_)) ; true ) ), L2), s(r41b, L2),
       assertz(q(8)), assertz(q(9)), predicate_property(q(_), number_of_clauses(N2)), s(r41b_count, N2).
%% a compound of no arguments: clause/2 asks the atom's predicate, retract/1 takes nothing
r42 :- retractall(fz), assertz(fz), t(clause(fz(), true)), t(retract(fz())), t(fz).

main :-
    forall(member(G, [r01, r02, r03, r04, r05, r06, r07, r08, r09, r10, r11, r12, r13, r14, r15,
                      r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26, r27, r28, r29, r30,
                      r31, r32, r33, r34, r35, r36, r37, r38, r39, r40, r41, r42]),
           ( catch(G, E, ( s(G, raised(E)), fail )) -> true ; s(G, failed) )).
