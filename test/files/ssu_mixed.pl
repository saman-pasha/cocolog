%% One kind of clause to a predicate, as swipl 9.0.4 has it (cocolog
%% 3.65.0). Run by test/files.pl beside swipl, the two outputs compared
%% byte for byte.
%%
%% A predicate is single-sided rules (`Head => Body') or clauses (`Head :-
%% Body', facts among them), as its live clauses say: a clause of the other
%% kind is refused while it has any, a load's in its words at the clause's
%% line (the load goes on without it), an assert's as permission_error(
%% assert, procedure, PI) in assertz/1's or asserta/1's context. Emptied --
%% by retract/1, retractall/1 or abolish/1 -- a predicate takes either kind
%% again, and a file read again takes the kind of its new text. Through
%% 3.64.8 cocolog kept both kinds in the order given.

mx(1).
mx(X) => X = 2.
ru(a) => true.
ru(b).

said(G) :- catch((G -> R = yes ; R = no), error(F, C), ( nonvar(C), C = context(P, _) -> R = F-P ; R = F )), print(R), nl.

t1 :- assertz(d(1)), said(assertz((d(2) => true))), said(asserta((d(0) => true))).
t2 :- assertz((e(1) => true)), said(assertz(e(2))), said(asserta(e(0))),
      said(assertz((e(3) :- true))), said(assertz((e(4) => true))).
t3 :- assertz(g(1)), retract(g(1)), said(assertz((g(2) => true))), said(g(2)), said(g(3)).
t4 :- assertz(h(1)), retractall(h(_)), said(assertz((h(2) => true))).
t5 :- assertz(k(1)), abolish(k/1), said(assertz((k(2) => true))).
t6 :- assertz((t(a) => true)), retractall(t(_)), said(assertz(t(b))), said(t(c)).
t7 :- assertz(w(1)), forall(w(_), said(assertz((w(2) => true)))).
t8 :- assertz((u(a) => true)), forall(u(a), said(assertz(u(b)))).
%% a file read again, its versions from test/files.pl's fixture: each read
%% takes the old text's clauses out before its own first clause, so the new
%% text's first clause decides the kind and a clause of the other kind after
%% it is refused at its line
t9 :- consult(sw), sps, swap(v2), consult(sw), sps, swap(v3), consult(sw), sps,
      swap(v4), consult(sw), sps.

%% a clause retracted under a call still open on it is no clause of the
%% predicate's kind: the predicate is empty once its last live one goes
t10 :- assertz(gg(1)), forall(gg(X), ( retract(gg(X)), said(assertz((gg(2) => true))) )), said(gg(2)).
t11 :- assertz((hh(a) => true)), forall(hh(a), ( retractall(hh(_)), said(assertz(hh(b))) )), said(hh(b)).
t12 :- assertz(ii(1)), assertz(ii(2)), forall(ii(X), ( retract(ii(X)), said(assertz((ii(9) => true))) )).
%% and so is one retracted while the call that holds it is open on a second
%% candidate: dead in place, still the call's (the logical update view). A
%% call no rule matches after such a switch is left out: swipl keeps the
%% retracted clauses in its list until its clause garbage collection and
%% decides by that list whether it raises (COMPAT.md's row on rules)
t13 :- assertz(jj(1)), assertz(jj(2)),
       ( jj(X), X == 1, retract(jj(1)), retract(jj(2)), said(assertz((jj(9) => true))), fail ; true ),
       said(jj(9)).
t14 :- assertz((kk(a) => true)), assertz((kk(b) => true)),
       ( kk(a), retract((kk(a) :- _)), fail ; true ), said(assertz(kk(c))).
t15 :- assertz((ll(a) => true)), assertz((ll(b) => true)),
       ( clause(ll(X), _), X == a, retractall(ll(_)), said(assertz(ll(c))), fail ; true ), said(ll(c)).

sps :- findall(X, catch(sp(X), _, fail), L), print(L), nl.
swap(V) :- atomic_list_concat(['sw.', V, '.pl'], From), rename_file(From, 'sw.pl').

main :-
    findall(X, catch(mx(X), _, fail), L1), print(L1), nl,
    said(ru(a)), said(ru(b)),
    t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15.
