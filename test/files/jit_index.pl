%  Which argument a call is keyed on when its first one cannot choose, as
%  swipl's JIT index keys it (pl-index.c, first_clause_guarded and
%  bestHash, read at 9.0.4; cocolog 3.24.0): the first argument unbound,
%  or the first two clauses it leaves both of its key, and another bound
%  argument whose assessment over the clauses promises the most -- none
%  that some clause leaves unbound past a tenth of its values. Told by $/0
%  at the exit of a clause that calls it and then `true', where a choice
%  point left is determinism_error(PI, det, nondet, guard), by $/1 around a
%  call whose body's first goal is the one asked (a call from the registers,
%  which no guard of $/0 takes), and by the answers and their order. Run by
%  BOTH SWI-Prolog and cocolog, output compared byte for byte; each line is
%  one of swipl 9.0.4's answers. Not here (COMPAT.md): swipl's deep index
%  inside a compound every clause shares, an index of two arguments
%  together, keys of floats and strings, what swipl's index kept from the
%  calls made before decides -- an argument it found unfit while a dynamic
%  predicate had one clause stays so until the count reaches a power of
%  two -- and a head with two anonymous variables in a row before the
%  argument asked, whose key there 9.0.4 reads as none (pl-comp.c's
%  skipArgs stops on the H_VOID_N that compiles them).

p(X, G) :- catch((findall(X, G, L), shown(L, S), print(S)), error(E, _), print(E)), nl.
dd(G) :- $, G, true.
d(G) :- catch((dd(G) -> shown(G, S), print(det(S)) ; print(fail)), error(E, _), print(E)), nl.
e(G) :- catch(($(G) -> shown(G, S), print(det(S)) ; print(fail)), error(E, _), (shown(E, S), print(S))), nl.
shown(T, S) :- copy_term(T, S), term_variables(S, Vs), maplist(=('_'), Vs).

q(_, []).
q(_, [_|T]) :- q(_, T).
r(a, x).
r(b, y).
t(a, x).
t(a, y).
u(a, x).
u(a, y).
u(b, z).
v(X, x) :- X = 1.
v(X, y) :- X = 2.
w([], a).
w([_|_], b).
k(1, a, x).
k(2, b, x).
k(3, c, y).
m(_, _, z).
m(_, b, _).
n3(_, a).
n3(_, b).
n3(_, c).
n7(_, a1). n7(_, a2). n7(_, a3). n7(_, a4). n7(_, a5). n7(_, a6). n7(_, a7).
one(_, a).
one(_, a).
dup(a, x, 1).
dup(a, x, 2).
dup(a, y, 3).
mixed(_, f(1)).
mixed(_, g(2)).
mixed(_, 3).
:- dynamic dy/2.
dy(a, x).
dy(b, y).
:- dynamic grow/2.
grow(a, x).
vf(_, a).
vf(_, _).
vf(_, b).
vf(_, c).
vk(k, _, x).
vk(k, a, y).
vk(k, b, y).
vk(k, c, y).
tie(_, a, x).
tie(_, a, y).
tie(_, b, x).
tie(_, b, y).
tz(a, x).
tz(a, y).
tz(b, y).
sd(_, a, x).
sd(_, b, y).
sd(_, a, x).
sd(_, a, y).
cw(X) :- w(X, b).
cq(L) :- ql(L, [1, 2]).
ql([], []).
ql([_|T], [_|U]) :- ql(T, U).

answers :-
    p(X1, q(X1, [1, 2])),
    p(X2, r(X2, x)),
    p(X3-Y3, k(X3, Y3, x)),
    p(X4-Z4, k(X4, b, Z4)),
    p(Y5, t(a, Y5)),
    p(x, t(a, z)),
    p(X6-Y6, m(X6, Y6, z)),
    p(X7, n7(X7, a4)),
    p(Z8, dup(a, x, Z8)),
    p(Y9, mixed(_, Y9)),
    p(L10, (maplist(succ, L10, [2, 3]))),
    p(L11, (maplist(=, L11, [a, b]))).

det :-
    d(q(_, [1, 2])), d(q(_, [])),
    d(r(_, x)), d(r(_, y)), d(r(_, z)),
    d(t(a, x)), d(t(a, y)),
    d(u(a, x)), d(u(a, y)), d(u(b, z)),
    d(v(_, x)), d(v(_, y)),
    d(w(_, a)), d(w(_, b)),
    d(k(_, _, x)), d(k(_, b, _)), d(k(_, _, y)), d(k(_, a, x)),
    d(m(_, _, z)), d(m(_, b, _)), d(m(_, c, z)),
    d(n3(_, a)), d(n3(_, b)), d(n3(_, c)),
    d(n7(_, a1)), d(n7(_, a4)), d(n7(_, a7)),
    d(one(_, a)),
    d(dup(a, x, _)), d(dup(a, y, _)), d(dup(a, _, 3)), d(dup(a, x, 2)),
    d(mixed(_, f(_))), d(mixed(_, 3)),
    d(dy(_, x)), d(dy(_, y)),
    d(maplist(succ, _, [2, 3])),
    d(maplist(=, _, [a, b])),
    d(maplist(succ, [1|_], [2, 3])).

changes :-
    assertz(grow(b, y)),
    d(grow(_, x)),
    assertz(grow(c, x)),
    d(grow(_, y)),
    d(grow(_, x)),
    retract(grow(a, x)),
    d(grow(_, x)),
    asserta(grow(d, x)),
    d(grow(_, y)),
    p(X1, grow(X1, x)),
    retract(dy(a, x)),
    d(dy(_, y)),
    assertz(dy(c, y)),
    d(dy(_, y)),
    p(X2, dy(X2, y)).

%  the rules of the choice: an argument some clause leaves unbound past a
%  tenth of its values (vf, vk), the first of two that promise the same (tie, and
%  the first argument against another, tz), the spread of the keys' counts
%  (sd), and a call from the registers ($/1)
rules :-
    d(vf(_, a)), d(vf(_, c)), d(vk(_, a, y)), d(vk(_, _, x)),
    d(tie(_, a, y)), d(tie(_, b, x)), d(tie(_, a, x)),
    d(tz(a, y)), d(tz(a, x)),
    d(sd(_, b, y)), d(sd(_, a, y)),
    e(cw(_)), e(w(_, b)), e(cq(_)), e(ql(_, [1])),
    e(vf(_, a)), e(tie(_, a, y)), e(sd(_, b, y)).

main :- answers, det, changes, rules.
