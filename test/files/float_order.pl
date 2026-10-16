%  Floats as terms: 0.0 against -0.0, and a NaN, under unify, ==/2,
%  compare/3, the sorts, a clause head and the store, checked against SWI.
%  Run by BOTH systems, output compared byte for byte.
%
%  Each case is a clause of its own, so no two share a variable. Left out:
%  arithmetic, which compares numbers and not terms (`0.0 =:= -0.0').

:- dynamic u/1, v/2, w/2.

s(Label, Value) :- write(Label), write(=), writeq(Value), nl.
r(Label) :- ( catch(c(Label, V), E, (s(Label, E), fail)) -> s(Label, V) ; s(Label, no) ).

%  a compiled clause's float constants, several under one first argument
p(0.0).
q(-0.0).
k(0.0, zero).
k(-0.0, negzero).
k(1.0, one).
k(1.5NaN, nan).

%  ---- unify, ==/2 and their negations ----
c(u01, yes) :- 0.0 = -0.0.
c(u02, yes) :- -0.0 = -0.0.
c(u03, yes) :- 1.5NaN = 1.5NaN.
c(u04, yes) :- X = 1.5NaN, X = X.
c(u05, yes) :- f(0.0) = f(-0.0).
c(u06, yes) :- f(g(1.5NaN), 1.0) = f(g(1.5NaN), 1.0).
c(u07, yes) :- 0.0 \= -0.0.
c(u08, yes) :- 0.0 == -0.0.
c(u09, yes) :- 1.5NaN == 1.5NaN.
c(u10, yes) :- 0.0 \== -0.0.
c(u11, yes) :- f(g(-0.0)) == f(g(0.0)).
c(u12, yes) :- unify_with_occurs_check(0.0, -0.0).
c(u13, yes) :- unify_with_occurs_check(1.5NaN, 1.5NaN).
c(u14, yes) :- memberchk(-0.0, [0.0, 1.0]).
c(u15, yes) :- memberchk(0.0, [-0.0, 0.0]).
c(u16, yes) :- memberchk(1.5NaN, [1.0, 1.5NaN]).
c(u17, yes) :- subsumes_term(0.0, -0.0).
c(u18, yes) :- subsumes_term(-0.0, -0.0).
c(u19, yes) :- 0.0 =@= -0.0.
c(u20, yes) :- 1.5NaN =@= 1.5NaN.

%  ---- unify past its count, where it links the pairs it enters ----
c(l01, yes) :- X = f(X, 0.0), Y = f(Y, -0.0), X = Y.
c(l02, yes) :- X = f(X, 1.5NaN), Y = f(Y, 1.5NaN), X = Y.
c(l03, yes) :- X = f(X, -0.0), Y = f(Y, -0.0), X = Y.
c(l04, yes) :- X = f(X, 0.0), Y = f(Y, -0.0), X == Y.

%  ---- the standard order ----
c(o01, O) :- compare(O, -0.0, 0.0).
c(o02, O) :- compare(O, 0.0, -0.0).
c(o03, O) :- compare(O, 1.5NaN, -1.0Inf).
c(o04, O) :- compare(O, 1.5NaN, 1.0).
c(o05, O) :- compare(O, 1.0, 1.5NaN).
c(o06, O) :- compare(O, 1.5NaN, 1.5NaN).
c(o07, O) :- compare(O, 1.5NaN, 1).
c(o08, O) :- compare(O, 0, -0.0).
c(o09, O) :- compare(O, -0.0, 0).
c(o10, O) :- compare(O, f(-0.0), f(0.0)).
c(o11, yes) :- -0.0 @< 0.0.
c(o12, yes) :- 0.0 @< -0.0.
c(o13, yes) :- 1.5NaN @< -1.0Inf.
c(o14, L) :- msort([0.0, -0.0, 0, 1.5NaN, -1.0Inf, 1.0Inf, 1, -1, 0.5, -0.5], L).
c(o15, L) :- sort([0.0, -0.0, 0.0, -0.0], L).
c(o16, L) :- msort([2, 1.5NaN, 1.0, -1, 1.5NaN, 9223372036854775807], L).
c(o17, L) :- sort(0, @>=, [0.0, -0.0, 1.5NaN, 1.0], L).
c(o18, L) :- sort(0, @=<, [0.0, -0.0, 0.0, -0.0, 0], L).
c(o19, L) :- keysort([0.0-a, -0.0-b, 0.0-c, -0.0-d], L).
c(o20, L) :- sort(1, @<, [k(0.0, a), k(-0.0, b), k(0.0, c)], L).
c(o21, L) :- setof(X, member(X, [0.0, -0.0, 0.0, 1.5NaN]), L).
c(o22, L) :- findall(X, member(X, [0.0, -0.0]), L0), sort(L0, L).
c(o23, L) :- list_to_ord_set([0.0, 1.0, -0.0, 0.0], L).
c(o24, L) :- msort([0, 0.0, -0.0, 0], L).

%  ---- a compiled head's constant, and its index ----
c(h01, yes) :- p(-0.0).
c(h02, yes) :- p(0.0).
c(h03, yes) :- q(0.0).
c(h04, X) :- q(X).
c(h05, L) :- findall(N, k(-0.0, N), L).
c(h06, L) :- findall(N, k(0.0, N), L).
c(h07, L) :- findall(N, k(1.5NaN, N), L).
c(h08, L) :- findall(F-N, k(F, N), L).

%  ---- the store: an asserted clause, and retract/1 ----
c(d01, yes) :- assertz(u(0.0)), u(-0.0).
c(d02, yes) :- u(0.0).
c(d03, yes) :- retract(u(-0.0)).
c(d04, yes) :- retract(u(0.0)).
c(d05, yes) :- assertz(v(X, X)), retract(v(0.0, -0.0)).
c(d06, yes) :- retract(v(-0.0, -0.0)).
c(d07, yes) :- assertz(w(1.5NaN, n)), w(1.5NaN, n).
c(d08, yes) :- retract(w(1.5NaN, n)).

%  ---- the text of a float, and its copies ----
c(t01, yes) :- copy_term(-0.0, X), X == -0.0.
c(t02, yes) :- term_to_atom(T, '-0.0'), T == -0.0.
c(t03, yes) :- atom_number('-0.0', N), N == -0.0.
c(t04, yes) :- number_codes(N, "-0.0"), N == -0.0.
c(t05, yes) :- nb_setval(fz, f(-0.0, 0.0)), nb_getval(fz, f(A, B)), A == -0.0, B == 0.0.
c(t06, L) :- findall(X, member(X, [-0.0, 0.0]), L).
c(t07, yes) :- X is -0.0, X == -0.0.
c(t08, yes) :- X is 0.0 * -1, X == -0.0, X \== 0.0.

main :-
    forall(member(L, [u01, u02, u03, u04, u05, u06, u07, u08, u09, u10,
                      u11, u12, u13, u14, u15, u16, u17, u18, u19, u20,
                      l01, l02, l03, l04,
                      o01, o02, o03, o04, o05, o06, o07, o08, o09, o10, o11, o12,
                      o13, o14, o15, o16, o17, o18, o19, o20, o21, o22, o23, o24,
                      h01, h02, h03, h04, h05, h06, h07, h08,
                      d01, d02, d03, d04, d05, d06, d07, d08,
                      t01, t02, t03, t04, t05, t06, t07, t08]),
           r(L)).
