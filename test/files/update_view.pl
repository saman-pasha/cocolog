%  ISO's logical update view, checked against SWI.
%  Run by BOTH systems, output compared byte for byte.
%
%  A call sees the clauses that stood when it began: an assertz or an
%  asserta made while it is open is not among them, and a clause retracted
%  while it is open still is. A NEW call sees the clauses as they are.
%
%  Every builtin here answers once (cocolog's are deterministic), so no case
%  backtracks INTO retract/1: each retract names its clause or is driven by
%  a recursion, never by a failure-driven loop over retract itself.

:- dynamic q/1, r/1, s/1, t/1, w/1, done/1, k/2, c/1, p/2, cnt/1, g/1.

s(Label, Value) :- write(Label), write(=), writeq(Value), nl.

q3 :- retractall(q(_)), assertz(q(1)), assertz(q(2)), assertz(q(3)).
all_q(L) :- findall(X, q(X), L).

%  ---- a retract ahead of an open call, and behind it ----
u01 :- q3, findall(X, ( q(X), ( X == 1 -> retract(q(2)) ; true ) ), L),
       s(u01_seen, L), all_q(A), s(u01_left, A).
u02 :- q3, findall(X, ( q(X), retract(q(X)) ), L),
       s(u02_seen, L), all_q(A), s(u02_left, A).
u03 :- q3, forall(q(X), retract(q(X))), all_q(A), s(u03_left, A).
% cocolint: R1 -- the loop backtracks into q/1, the open call the view is about, never into retract
u04 :- q3, ( q(X), retract(q(X)), fail ; true ), all_q(A), s(u04_left, A).
u05 :- q3, findall(X, ( q(X), ( X == 1 -> retract(q(3)), retract(q(2)) ; true ) ), L),
       s(u05_seen, L), all_q(A), s(u05_left, A).

%  ---- an assert while a call is open ----
u06 :- q3, findall(X, ( q(X), X < 9, assertz(q(9)) ), L),
       s(u06_seen, L), all_q(A), s(u06_left, A).
u07 :- q3, findall(X, ( q(X), ( X == 1 -> asserta(q(0)) ; true ) ), L),
       s(u07_seen, L), all_q(A), s(u07_left, A).
u08 :- q3, findall(X, ( q(X), asserta(q(0)), retract(q(0)) ), L),
       s(u08_seen, L), all_q(A), s(u08_left, A).
u09 :- q3, findall(X, ( q(X), assertz(q(X)), once(retract(q(X))) ), L),
       s(u09_seen, L), all_q(A), s(u09_left, A).

%  ---- a NEW call sees the clauses as they are now ----
u10 :- q3, findall(X-N, ( q(X), retract(q(X)), all_q(N) ), L), s(u10, L).
u11 :- q3, findall(X-N, ( q(X), ( X == 1 -> retract(q(2)) ; true ), all_q(N) ), L), s(u11, L).
u12 :- q3, findall(X-Y, ( q(X), q(Y), retract(q(Y)) ), L),
       s(u12_seen, L), all_q(A), s(u12_left, A).
u13 :- q3, findall(X-B, ( q(X), retract(q(X)), findall(H, clause(q(H), true), B) ), L),
       s(u13, L).
u14 :- q3, findall(X-N, ( q(X), retract(q(X)), aggregate_all(count, q(_), N) ), L),
       s(u14, L).

%  ---- the same clause twice, and one that was never there ----
u15 :- q3, findall(X-R, ( q(X), ( retract(q(2)) -> R = took ; R = gone ) ), L), s(u15, L).

%  ---- a cut, and a throw, through the open call ----
cut_at_2 :- q(X), retract(q(X)), X == 2, !.
u16 :- q3, cut_at_2, all_q(A), s(u16_left, A).
u17 :- q3, catch(( q(X), retract(q(X)), X == 2, throw(stop) ), stop, true),
       all_q(A), s(u17_left, A).

%  ---- rules: a retracted rule still runs for the call that saw it ----
u18 :- retractall(r(_)),
       assertz((r(X) :- X = one)), assertz((r(X) :- X = two)), assertz((r(X) :- X = three)),
       findall(X, ( r(X), ( X == one -> retract((r(Y) :- Y = three)) ; true ) ), L),
       s(u18_seen, L), findall(Z, r(Z), A), s(u18_left, A).

%  ---- a worklist: the recursion takes what is added, the loop does not ----
u19 :- retractall(w(_)), retractall(done(_)),
       assertz(w(1)), assertz(w(2)),
       ( w(X), retract(w(X)), assertz(done(X)), ( X < 3 -> Y is X + 10, assertz(w(Y)) ; true ), fail   % cocolint: R1 -- backtracks into w/1
       ; true ),
       findall(D, done(D), Ds), s(u19_done, Ds), findall(W, w(W), Ws), s(u19_left, Ws).
drain :- ( retract(w(X)) -> assertz(done(X)), ( X < 3 -> Y is X + 10, assertz(w(Y)) ; true ), drain ; true ).
u20 :- retractall(w(_)), retractall(done(_)),
       assertz(w(1)), assertz(w(2)), drain,
       findall(D, done(D), Ds), s(u20_done, Ds), findall(W, w(W), Ws), s(u20_left, Ws).

%  ---- a counter beside an open call (no call open on the counter) ----
bump :- retract(cnt(C)), D is C + 1, assertz(cnt(D)).
u21 :- q3, retractall(cnt(_)), assertz(cnt(0)),
       ( q(_), bump, fail ; true ), cnt(N), s(u21, N).

%  ---- an indexed table: first argument, and another argument ----
k20 :- retractall(k(_, _)), forall(between(1, 20, I), ( J is I mod 4, assertz(k(I, J)) )).
u22 :- k20, findall(I, ( k(I, _), ( I == 1 -> retract(k(20, _)), retract(k(10, _)) ; true ) ), L),
       s(u22_seen, L), findall(I2, k(I2, _), A), s(u22_left, A).
u23 :- k20, findall(I, ( k(I, 2), ( I == 2 -> retract(k(14, 2)), retract(k(18, 2)) ; true ) ), L),
       s(u23_seen, L), findall(I2, k(I2, 2), A), s(u23_left, A).
u24 :- k20, findall(I-J, ( k(I, J), I =< 3, retract(k(I, J)), assertz(k(I, J)) ), L),
       s(u24_seen, L), findall(I2, k(I2, _), A), s(u24_left, A).
u25 :- k20, findall(I, ( k(I, 0), I < 20, retract(k(I, 0)) ), L),
       s(u25_seen, L), findall(I2, k(I2, 0), A), s(u25_left, A).

%  ---- many deaths, sweeps between them, and the predicate filled again ----
u26 :- retractall(c(_)),
       forall(between(1, 300, I), assertz(c(I))),
       ( c(X), retract(c(X)), fail ; true ),   % cocolint: R1 -- the loop backtracks into c/1, never into retract
       findall(Y, c(Y), A0), length(A0, N0), s(u26_after_loop, N0),
       forall(between(1, 5, I), assertz(c(I))),
       findall(X2, ( c(X2), retract(c(X2)), assertz(c(X2)) ), L),
       s(u26_seen, L), findall(Y2, c(Y2), A1), s(u26_left, A1).
u27 :- retractall(c(_)),
       % cocolint: R1 -- the loop backtracks into c/1, the open call the view is about, never into retract
       forall(between(1, 10, R), ( assertz(c(R)), ( c(X), retract(c(X)), fail ; true ) )),
       findall(Y, c(Y), A), s(u27_left, A).

%  ---- an open call in an outer search, the change inside an inner one ----
retract_qs :- ( retract(q(_)) -> retract_qs ; true ).
u28 :- q3, findall(X, ( q(X), findall(_, ( X == 1, retract_qs ), _) ), L),
       s(u28_seen, L), all_q(A), s(u28_left, A).
u29 :- q3, findall(X, ( q(X), \+ \+ ( X == 1, retract(q(3)) ) ), L),
       s(u29_seen, L), all_q(A), s(u29_left, A).

%  ---- two arguments, a call that keys on its second ----
u30 :- retractall(p(_, _)),
       forall(between(1, 12, I), ( J is I mod 3, assertz(p(I, J)) )),
       findall(I, ( p(I, 1), ( I == 1 -> retract(p(4, 1)), assertz(p(13, 1)) ; true ) ), L),
       s(u30_seen, L), findall(I2, p(I2, 1), A), s(u30_left, A).

%  ---- a NEW call whose key leaves one candidate, and that one dead ----
u32 :- q3, findall(X-Y, ( q(X), ( X == 1 -> retract(q(2)) ; true ), ( q(2) -> Y = yes ; Y = no ) ), L),
       s(u32, L).
u33 :- k20, findall(I-Y, ( k(I, _), I =< 2, ( I == 1 -> retract(k(14, _)) ; true ),
                           ( k(14, _) -> Y = yes ; Y = no ) ), L),
       s(u33, L).

%  ---- the last clause retracted with no call open, then asked by its key ----
u34 :- q3, retract(q(3)), ( q(3) -> R = yes ; R = no ), all_q(A), s(u34, R-A).

%  ---- the call's own clause, retracted from its body ----
u31 :- retractall(g(_)),
       assertz((g(X) :- once(retract((g(_) :- _))), X = first)), assertz(g(second)),
       findall(X, g(X), L), s(u31_seen, L), findall(Y, g(Y), A), s(u31_left, A).

main :-
    forall(member(G, [u01, u02, u03, u04, u05, u06, u07, u08, u09, u10, u11, u12, u13,
                      u14, u15, u16, u17, u18, u19, u20, u21, u22, u23, u24, u25, u26,
                      u27, u28, u29, u30, u31, u32, u33, u34]),
           ( catch(G, E, ( s(G, raised(E)), fail )) -> true ; s(G, failed) )).
