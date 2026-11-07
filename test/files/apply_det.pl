%  library(apply), which cocolog writes as swipl writes it (cocolog
%  3.23.0): maplist/2..5, include/3, exclude/3, partition/4,5, convlist/3,
%  foldl/4..7, scanl/4..7 and apply/2 -- their answers, the frame each
%  error names (apply:maplist_/2, '$apply':apply/2), what partition/5 does
%  with an order that is none, and WHICH CALLS LEAVE NO CHOICE POINT: with
%  the first list given, none of the elements does, the list being the
%  first argument of a helper, told by $/0 at the exit of a clause that
%  calls it and then `true', where a choice point left is
%  determinism_error(PI, det, nondet, guard); and a guarded clause's last
%  call of one drops its guard, swipl marking them transparent. Run by
%  BOTH SWI-Prolog and cocolog, output compared byte for byte; each line is
%  one of swipl 9.0.4's answers. Not here: a call with the first list
%  unbound and another one given, which swipl's index on that list leaves
%  deterministic and cocolog's does not (COMPAT.md); and the variable an
%  error's context ends on, which swipl writes by its number.

p(X, G) :- catch((findall(X, G, L), print(L)), error(E, C), pe(E, C)), nl.
pe(E, C) :- ( nonvar(C), C = context(P, _), nonvar(P) -> print(E-P) ; print(E) ).
dd(G) :- $, G, true.
d(G) :- catch((dd(G) -> print(det(G)) ; print(fail)), error(E, _), print(E)), nl.
l(G) :- catch((G -> print(yes(G)) ; print(no)), error(E, _), print(E)), nl.

inc(X, Y) :- Y is X + 1.
add3(X, Y, Z) :- Z is X + Y.
add4(X, Y, Z, W) :- W is X + Y + Z.
cmp(X, O) :- compare(O, X, 2).
bad(_, foo).
bad2(1, <).
bad2(2, foo).
unb(_, _).
two(_, O) :- member(O, [<, >]).
sum(X, A0, A) :- A is A0 + X.
sum2(X, Y, A0, A) :- A is A0 + X * Y.
sum3(X, Y, Z, A0, A) :- A is A0 + X + Y + Z.
sum4(X, Y, Z, W, A0, A) :- A is A0 + X + Y + Z + W.
dbl(X, Y) :- integer(X), Y is 2 * X.
foo.
foo(X) :- X = 1.

answers :-
    p(L1, maplist(inc, [1, 2, 3], L1)),
    p(L2, maplist(add3, [1, 2], [10, 20], L2)),
    p(L3, maplist(add4, [1, 2], [10, 20], [100, 200], L3)),
    p(L5, (maplist(=(a), L5), length(L5, N5), N5 >= 2, !)),
    p(X6, maplist(member, X6, [[1, 2], [3]])),
    p(x, maplist(atom, [a, 1])),
    p(x, maplist(atom, [])),
    p(x, maplist(atom, foo)),
    p(L7-T7, (maplist(=(a), [X7|T7]), L7 = [X7|T7], length(T7, 1), !)),
    p(X8, include(atom, [a, 1, b], X8)),
    p(X9, exclude(atom, [a, 1, b], X9)),
    p(x, include(atom, [a, 1], [a])),
    p(x, include(atom, [a, 1], [b])),
    p(X10, include(atom, [], X10)),
    p(R11-T11, (include(atom, [a|T11], R11), !)),
    p(I12-E12, partition(atom, [a, 1, b], I12, E12)),
    p(x, partition(atom, [a, 1], [a], [1])),
    p(x, partition(atom, [a, 1], [], _)),
    p(L13-E13-G13, partition(cmp, [1, 2, 3, 2], L13, E13, G13)),
    p(x, partition(cmp, [1, 2, 3], [1], [2], [3])),
    p(L14-E14-G14, partition(two, [1], L14, E14, G14)),
    p(X15, convlist(dbl, [a, 1, b, 2], X15)),
    p(X16, convlist([X, Y]>>member(Y, [X, X]), [1], X16)),
    p(x, convlist(dbl, [1, 2], [2])),
    p(A17, foldl(sum, [1, 2, 3], 0, A17)),
    p(A18, foldl(sum2, [1, 2], [3, 4], 0, A18)),
    p(A19, foldl(sum3, [1], [2], [3], 10, A19)),
    p(A20, foldl(sum4, [1], [2], [3], [4], 10, A20)),
    p(S21, scanl(sum, [1, 2, 3], 0, S21)),
    p(S22, scanl(sum2, [1, 2], [3, 4], 0, S22)),
    p(S23, scanl(sum3, [1], [2], [3], 10, S23)),
    p(S24, scanl(sum4, [1], [2], [3], [4], 10, S24)),
    p(X25, apply(foo, [X25])),
    p(x, apply(foo, [])),
    p(X26, apply(m:foo, [X26])),
    p(X27, apply(succ(1), [X27])),
    p(X28, apply(foo(), [X28])).

errors :-
    p(x, maplist(nope, [1, 2])),
    p(x, maplist(nope, [1], [2])),
    p(x, maplist(nope, [1], [2], [3])),
    p(x, maplist(nope, [1], [2], [3], [4])),
    p(x, include(nope, [1], _)),
    p(x, exclude(nope, [1], _)),
    p(x, partition(nope, [1], _, _)),
    p(x, partition(nope, [1], _, _, _)),
    p(x, convlist(nope, [1], _)),
    p(x, foldl(nope, [1], 0, _)),
    p(x, foldl(nope, [1], [2], 0, _)),
    p(x, foldl(nope, [1], [2], [3], 0, _)),
    p(x, foldl(nope, [1], [2], [3], [4], 0, _)),
    p(x, scanl(nope, [1], 0, _)),
    p(x, scanl(nope, [1], [2], 0, _)),
    p(x, scanl(nope, [1], [2], [3], 0, _)),
    p(x, scanl(nope, [1], [2], [3], [4], 0, _)),
    p(x, maplist(1, [a])),
    p(x, maplist(_, [a])),
    p(x, include(1, [a], _)),
    p(x, exclude(_, [a], _)),
    p(x, partition(1, [a], _, _)),
    p(x, partition(1, [a], _, _, _)),
    p(x, convlist(1, [a], _)),
    p(x, foldl(1, [a], 0, _)),
    p(x, scanl(1, [a], 0, _)),
    p(x, maplist(inc, [a], _)),
    p(x, partition(bad, [1], _, _, _)),
    p(L1, partition(bad2, [1, 2], L1, _, _)),
    p(L2-E2-G2, partition(unb, [1, 2], L2, E2, G2)),
    p(x, apply(f(a), [b])),
    p(x, apply(1, [a])),
    p(x, apply(_, [a])),
    p(x, apply([], [a])),
    p(x, (atom_string(foo, S), apply(S, [1]))),
    p(x, apply(foo, bar)),
    p(x, apply(foo, [a|_])),
    p(x, apply(f(a), [b|c])).

det :-
    d(maplist(atom, [])),
    d(maplist(atom, [a])),
    d(maplist(atom, [a, b])),
    d(maplist(inc, [1, 2], _)),
    d(maplist(=, [a, b], _)),
    d(maplist(add3, [1, 2], [3, 4], _)),
    d(maplist(add4, [1], [2], [3], _)),
    d(include(atom, [a, 1], _)),
    d(include(atom, [], _)),
    d(exclude(atom, [a, 1], _)),
    d(partition(atom, [a, 1], _, _)),
    d(partition(cmp, [1, 2, 3], _, _, _)),
    d(partition(cmp, [], _, _, _)),
    d(partition(unb, [1, 2], _, _, _)),
    d(convlist(dbl, [1, a], _)),
    d(foldl(sum, [1, 2], 0, _)),
    d(scanl(sum, [1, 2], 0, _)),
    d(apply(foo, [_])),
    d(maplist(=(a), _)),
    d(maplist(member, [_], [[1, 2]])),
    d(partition(two, [1], _, _, _)),
    d(apply(member, [_, [1, 2]])).

lc1 :- $, maplist(atom, [a, b]).
lc2 :- $, maplist(=(a), _).
lc3 :- $, include(atom, [a, 1], _).
lc4 :- $, partition(cmp, [1, 2, 3], _, _, _).
lc5 :- $, convlist(dbl, [1, 2], _).
lc6 :- $, foldl(sum, _, 0, _).
lc7 :- $, maplist(member, [_], [[1, 2]]).
lc8 :- $, maplist(=(a), _, _).
lc9 :- $, scanl(sum, _, 0, _).
lc10 :- $, apply(member, [_, [1, 2]]).
lc11 :- $, partition(two, [1], _, _, _).

transparent :-
    l(lc1), l(lc2), l(lc3), l(lc4), l(lc5), l(lc6), l(lc7), l(lc8), l(lc9),
    l(lc10), l(lc11).

main :- answers, errors, det, transparent.
