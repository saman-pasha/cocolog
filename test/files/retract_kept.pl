%% A retract with no call open on a predicate of nine clauses or more, as
%% swipl 9.0.4's (cocolog 3.78.15). Run by test/files.pl beside swipl, the
%% two outputs compared byte for byte; a term's variables are named by
%% pv/1.
%%
%% Since 3.78.15 such a retract leaves its clause dead in place, as one
%% under an open call does, and the dead are swept only once they pass an
%% eighth of the live (`coco-tomb-many'); through 3.78.14 each one went at
%% once, the arrays shifted and every index dropped. What a program sees
%% must not move: the answers and their order, the choice points a call
%% leaves, what a call open at a later death goes on seeing while an
%% earlier death stays out of it, an asserta or an assertz beside the dead,
%% clause/2, listing/1 and the count of clauses, a set of rules
%% retractall/1 emptied, and each of these across the sweep the dead's
%% number calls. The predicates hold twenty clauses or more, so the dead
%% wait; test/files/retract_view.pl and update_view.pl hold the small ones.

:- dynamic p/2, q/1, u/2, r/1.

pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

s(Label, Value) :- write(Label), write(=), pv(Value), nl.
t(G) :- catch(( G -> R = yes ; R = no ), E, R = E), pv(R), nl.

fill(N) :- retractall(p(_, _)), forall(between(1, N, I), assertz(p(I, x))).
fillq(N) :- retractall(q(_)), forall(between(1, N, I), assertz(q(I))).
all_p(L) :- findall(A-B, p(A, B), L).
all_q(L) :- findall(X, q(X), L).
keys(L) :- findall(A, p(A, _), L).
%% how many, the first and the last
shape(L, N-F-Z) :- length(L, N), ( L = [F|_], last(L, Z) -> true ; F = none, Z = none ).

%% whether each answer of G left a choice point
dets(G, Ds) :-
    findall(D, ( setup_call_cleanup(true, G, D0 = det), ( D0 == det -> D = det ; D = nondet ) ), Ds).

%% ---- one death, no call open ----
k01 :- fill(20), retract(p(5, _)), keys(L), s(k01, L),
       aggregate_all(count, p(_, _), N), s(k01_count, N),
       predicate_property(p(_, _), number_of_clauses(C)), s(k01_clauses, C),
       findall(A, clause(p(A, _), true), CL), s(k01_clause, CL),
       assertz(p(21, y)), keys(L2), s(k01_assertz, L2),
       asserta(p(0, z)), keys(L3), s(k01_asserta, L3).
%% the calls after it: a key, the dead one, every clause
k02 :- fill(20), retract(p(5, _)),
       dets(p(7, _), D1), s(k02_key, D1),
       dets(p(5, _), D2), s(k02_dead, D2),
       dets(p(20, _), D3), s(k02_last, D3),
       dets(p(_, _), D4), length(D4, N4), last(D4, Z4), s(k02_all, N4-Z4).
%% one key, the second argument choosing
k03 :- retractall(p(_, _)), forall(between(1, 20, I), assertz(p(a, I))), retract(p(a, 5)),
       dets(p(a, 7), D1), s(k03_second, D1),
       dets(p(a, 5), D2), s(k03_dead, D2),
       dets(p(a, _), D3), length(D3, N3), s(k03_all, N3),
       findall(V, p(a, V), L), s(k03, L).
%% ---- an update: a retract of the old row, an assertz of the new ----
k04 :- retractall(u(_, _)), forall(between(1, 30, I), assertz(u(I, 0))),
       forall(between(1, 40, J), ( K is (J * 7) mod 30 + 1, retract(u(K, V)), W is V + 1, assertz(u(K, W)) )),
       findall(K-V, u(K, V), L), s(k04, L),
       aggregate_all(sum(V), u(_, V), S), s(k04_sum, S),
       dets(u(8, _), D), s(k04_det, D).
%% ---- a drain from the front, one retract/1 a call ----
k05 :- fillq(25), drain(L), s(k05, L), all_q(R), s(k05_left, R).
drain([X|Xs]) :- retract(q(X)), !, drain(Xs).
drain([]).
%% ---- the logical update view across an earlier death ----
%% the call open at the second death sees its clause, never the first's
k06 :- fillq(20), retract(q(3)),
       findall(X, ( q(X), ( X == 10 -> retract(q(12)) ; true ) ), L), s(k06, L),
       all_q(R), s(k06_after, R),
       %% and the earlier death ahead of the walk, the later one behind it
       fillq(20), retract(q(15)),
       findall(X, ( q(X), ( X == 2 -> retract(q(5)) ; true ) ), L2), s(k06_ahead, L2),
       all_q(R2), s(k06_ahead_after, R2).
%% and an asserta under it after the death stands out of its view
k07 :- fillq(20), retract(q(2)),
       findall(X, ( q(X), ( X == 5 -> asserta(q(0)) ; true ) ), L), s(k07, L),
       all_q(R), s(k07_after, R).
%% a death under the call and one before it, each walk opened between
k08 :- fillq(30), retract(q(4)),
       findall(X-Y, ( q(X), X < 8, ( X == 6 -> retract(q(7)), retract(q(25)) ; true ),
                      q(Y), Y > 23 ), L), s(k08, L),
       all_q(R), s(k08_after, R).
%% ---- across the sweep the dead's number calls ----
k09 :- fill(90),
       forall(between(1, 12, I), retract(p(I, _))), keys(L1), shape(L1, S1), s(k09_12, S1),
       forall(between(13, 20, I), retract(p(I, _))), keys(L2), shape(L2, S2), s(k09_20, S2),
       forall(between(91, 95, I), assertz(p(I, w))), keys(L3), shape(L3, S3), s(k09_95, S3),
       dets(p(21, _), D1), s(k09_det21, D1), dets(p(95, _), D2), s(k09_det95, D2),
       dets(p(10, _), D3), s(k09_det10, D3),
       retract(p(50, _)), asserta(p(50, v)), keys(L4), shape(L4, S4), s(k09_50, S4),
       predicate_property(p(_, _), number_of_clauses(C)), s(k09_clauses, C).
%% ---- retractall/1: one match, two, a key ----
k10 :- fill(30), retractall(p(4, _)), assertz(p(4, y)), assertz(p(4, z)), retractall(p(4, y)),
       all_p(L), shape(L, S), s(k10, S), findall(B, p(4, B), L4), s(k10_4, L4),
       retractall(p(_, x)), all_p(L5), s(k10_x, L5).
%% ---- listing/1 and clause/2 beside the dead ----
k11 :- fill(12), retract(p(3, _)), retract(p(9, _)), assertz(p(13, y)), listing(p/2),
       findall(A-B, clause(p(A, B), true), L), s(k11_clause, L).
%% ---- a set of rules retractall/1 emptied a rule of ----
k12 :- retractall(r(_)), forall(between(1, 14, I), assertz((r(I) => true))),
       retractall(r(5)), t(r(5)), t(r(6)),
       assertz((r(15) => true)), t(r(15)), t(r(16)),
       findall(X, ( between(1, 16, X), catch(r(X), _, fail) ), L), s(k12, L).
%% ---- a retract inside a walk of another predicate ----
k13 :- fill(40), fillq(10), forall(q(I), retract(p(I, _))), keys(L), shape(L, S), s(k13, S),
       dets(p(11, _), D), s(k13_det, D), dets(p(3, _), D3), s(k13_dead, D3).
%% ---- a walk begun after a death under another open call ----
%% clause/2's and retract/1's walk never meets a clause that died before it
%% began, at its first candidate or at a retry: through 3.78.14 a retry
%% tried the place one past its last answer as it stood, and showed q(3)
%% (taken again by retract/1). Five clauses, so the death is one under the
%% open call q(A), as it always was, and twenty, so it is one of the dead
%% that wait since 3.78.15
k14 :- fillq(5), ( q(A), A == 1, retract(q(3)), findall(X, clause(q(X), true), L), s(k14_clause, L), fail ; true ),
       fillq(5), ( q(B), B == 1, retract(q(3)), findall(X, retract(q(X)), L2), s(k14_retract, L2), fail ; true ),
       all_q(R), s(k14_left, R),
       fillq(5), ( q(C), C == 1, retract(q(2)), retract(q(4)),
                   findall(X, clause(q(X), true), L3), s(k14_two, L3), fail ; true ),
       fillq(20), retract(q(3)), retract(q(9)), findall(X, clause(q(X), true), L4), s(k14_kept, L4),
       findall(X, ( retract(q(X)), X > 15 ), L5), s(k14_kept_retract, L5), all_q(R5), s(k14_kept_left, R5).
%% ---- across the sweep the calls pay for ----
%% thirty dead at the front of three hundred clauses, fewer than an eighth,
%% and calls that pass them: the sweep they pay for is tried under the
%% open call p(A, _), which keeps the dead, and made after it
k15 :- fill(300), forall(between(1, 30, I), retract(p(I, _))),
       findall(A, ( p(A, _), A < 40,
                    ( A == 31 -> forall(between(1, 50, _), once(p(_, _))), retract(p(35, _)) ; true ) ), L1),
       s(k15_open, L1),
       forall(between(1, 50, _), once(p(_, _))), keys(L2), shape(L2, S2), s(k15_after, S2),
       dets(p(36, _), D1), s(k15_det, D1), dets(p(300, _), D2), s(k15_last, D2),
       dets(p(_, _), D3), length(D3, N3), last(D3, Z3), s(k15_all, N3-Z3),
       predicate_property(p(_, _), number_of_clauses(C)), s(k15_clauses, C).

main :-
    k01, k02, k03, k04, k05, k06, k07, k08, k09, k10, k11, k12, k13, k14, k15.
