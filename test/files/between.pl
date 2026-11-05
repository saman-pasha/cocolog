%  between/3, which swipl writes in C and cocolog as clauses: its answers
%  and its errors, the bounds of 64 bits, `inf' and `infinite', a bound X
%  decided at once, and WHICH ANSWER LEAVES NO CHOICE POINT -- the last,
%  as swipl's (cocolog 3.22.0), told by $/0 at the exit of a clause that
%  calls it and then `true', where a choice point left is
%  determinism_error(PI, det, nondet, guard). A range whose count passes
%  64 bits (L < 0 =< H) is enumerated from its lower bound on and across
%  0. Run by BOTH SWI-Prolog and cocolog, output compared byte for
%  byte; each line is one of swipl 9.0.4's answers. Not here: the
%  determinism error a last call into between/3 raises
%  (test/files/det_guard.pl), and the error's context, a variable swipl
%  writes by its number.

p(X, G) :- catch((findall(X, G, L), print(L)), error(E, _), print(E)), nl.
dd(G) :- $, G, true.
d(G) :- catch((dd(G) -> print(det(G)) ; print(fail)), error(E, _), print(E)), nl.

answers :-
    p(X1, between(1, 5, X1)),
    p(X2, between(3, 3, X2)),
    p(X3, between(4, 3, X3)),
    p(X5, between(-2, 2, X5)),
    p(X4, (between(1, inf, X4), X4 > 3, !)),
    p(X6, (between(1, infinite, X6), X6 > 2, !)),
    p(X8, between(9223372036854775805, 9223372036854775807, X8)),
    p(X9, between(-9223372036854775808, -9223372036854775806, X9)),
    p(X7, (between(-1, 9223372036854775807, X7), X7 >= 1, !)),
    p(X10, (between(-9223372036854775808, 9223372036854775807, X10), X10 >= -9223372036854775806, !)),
    p(X12, (between(-2, 9223372036854775807, X12), X12 >= 2, !)),
    p(X13, (between(-3, 9223372036854775806, X13), X13 >= 1, !)).

bound :-
    p(x, between(1, 3, 2)),
    p(x, between(1, 3, 1)),
    p(x, between(1, 3, 3)),
    p(x, between(1, 3, 4)),
    p(x, between(1, 3, 0)),
    p(x, between(1, inf, 0)),
    p(x, between(1, inf, 7)),
    p(x, between(1, infinite, 7)),
    p(x, between(5, 3, 4)),
    p(x, between(1, 9223372036854775807, 9223372036854775806)),
    p(x, between(-9223372036854775808, 9223372036854775807, 0)),
    p(x, between(-9223372036854775808, -1, 0)).

errors :-
    p(x, between(a, 3, _)),
    p(x, between(1, a, _)),
    p(x, between(1, 3, a)),
    p(x, between(_, 3, _)),
    p(x, between(1, _, _)),
    p(x, between(_, a, _)),
    p(x, between(1, 3, 1.0)),
    p(x, between(1.0, 3, _)),
    p(x, between(1, 3.0, _)),
    p(x, between(1, foo, _)),
    p(x, between(5, 3, a)),
    p(x, between(1, 3, f(x))).

det :-
    d(between(1, 1, _)),
    d(between(1, 3, _)),
    d(between(1, 3, 3)),
    d(between(1, 3, 2)),
    d(between(5, 3, _)),
    d((between(1, 3, X1), X1 >= 3)),
    d((between(1, 3, X2), X2 >= 2)),
    d((between(-1, 9223372036854775807, X3), X3 >= 0)),
    d(between(9223372036854775806, 9223372036854775807, 9223372036854775807)),
    d((between(9223372036854775806, 9223372036854775807, X4), X4 > 9223372036854775806)),
    d((between(-9223372036854775808, -9223372036854775807, X5), X5 > -9223372036854775808)),
    d((between(1, inf, X7), X7 > 3)).

main :- answers, bound, errors, det.
