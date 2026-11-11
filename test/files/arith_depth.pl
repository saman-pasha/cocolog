%  Arithmetic as swipl 9.0.4's valueExpression() evaluates it (cocolog
%  3.61.0): a compound's arguments from its LAST, an expression of any
%  depth, and at its 101st compound -- of an argument or more, and no list
%  of one character -- the one question whether the WHOLE expression is
%  cyclic, type_error(expression, E) of it when it is. Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte.
%
%  Through 3.60.0 cocolog evaluated the first argument first, so an
%  expression with two faults named the other one (`X is a + b' said a/0,
%  `tab(a+b)' too), asked about a cycle 1 024 levels down of the subterm
%  there, and called itself for each argument: some 43 000 levels were a
%  SIGSEGV.
%
%  What is held: each value, or each error's formal and the predicate it
%  names, a cyclic culprit said as one -- never its text. Not held: an
%  integer past 64 bits, which swipl makes a bignum where cocolog raises
%  int_overflow (COMPAT.md).

:- set_prolog_flag(double_quotes, codes).

main :- forall(member(S, [order, depth, cycles, errors, others]), run(S)).

run(S) :- write(S), nl, forall(nth1_c(S, N, G), (write(N), write(': '), case(G), nl)).

nth1_c(S, N, G) :- findall(G0, c(S, G0), Gs), nth1(N, Gs, G).

case(G) :- catch(( G -> true ; write(failed) ), E, report(E)).

report(error(type_error(T, C), Ctx)) :- cyclic_term(C), !,
    write('error type_error('), print(T), write(', a cycle)'), ctx(Ctx).
report(error(F, Ctx)) :- !, write('error '), print(F), ctx(Ctx).
report(E) :- write('caught '), print(E).

ctx(context(P, _)) :- nonvar(P), !, write(' in '), writeq(P).
ctx(_).

%  the expressions: N levels of `1 + E' (right), `E + 1' (left), F(E)
%  (one), and of `E + 3 - 2 * 1' (mixed); built by recursions on nothing
right(0, T, T) :- !.
right(N, T0, T) :- N1 is N - 1, right(N1, 1 + T0, T).

left(0, T, T) :- !.
left(N, T0, T) :- N1 is N - 1, left(N1, T0 + 1, T).

one(0, _, T, T) :- !.
one(N, F, T0, T) :- N1 is N - 1, G =.. [F, T0], one(N1, F, G, T).

halves(0, T, T) :- !.
halves(N, T0, T) :- N1 is N - 1, halves(N1, 0.5 + T0, T).

tenths(0, T, T) :- !.
tenths(N, T0, T) :- N1 is N - 1, tenths(N1, T0 + 0.1, T).

thirds(0, T, T) :- !.
thirds(N, T0, T) :- N1 is N - 1, thirds(N1, 1r3 + T0, T).

mixed(0, T, T) :- !.
mixed(N, T0, T) :- N1 is N - 1, mixed(N1, T0 + 3 - 2 * 1, T).

ones(0, T, T) :- !.
ones(N, T0, T) :- N1 is N - 1, ones(N1, 1 * T0, T).

%  a DAG: N levels of `E + E', each level one compound sharing the one
%  below, so its tree has 2^N - 1 compounds where the heap holds N
dag(0, T, T) :- !.
dag(N, T0, T) :- N1 is N - 1, dag(N1, T0 + T0, T).

%  N levels of `(1 * 1) + E': a compound beside the chain at every level
pairs(0, T, T) :- !.
pairs(N, T0, T) :- N1 is N - 1, pairs(N1, (1 * 1) + T0, T).

%  N levels of roundtoward(E, Mode), each one its own compound and its own
%  mode put back
rts(0, _, T, T) :- !.
rts(N, M, T0, T) :- N1 is N - 1, rts(N1, M, roundtoward(T0, M), T).

%  1/3 rounds up under to_positive and 0.1 + 0.2 down under to_negative:
%  the two together say which mode is set
modes :- X is 1.0 / 3.0, Y is 0.1 + 0.2, print(X/Y).

v(E) :- X is E, print(X).

%  ---- order: the last argument first, at every depth ----------------------

c(order, v(a + b)).
c(order, v(a - b)).
c(order, v(a * b)).
c(order, v(foo(1) + bar(2))).
c(order, v((1/0) + b)).
c(order, v(b + (1/0))).
c(order, v(_ + a)).
c(order, v(a + _)).
c(order, v(max(a, b))).
c(order, v(atan2(a, b))).
%  (powm/3 of a float is not held: swipl 9.0.4's ar_powm() raises
%  type_error(integer, F) and answers a value all the same, `foreign
%  predicate system:is/2 did not clear exception', where cocolog raises)
c(order, v(powm(a, b, c))).
c(order, v(foo(a, b, c))).
c(order, v(foo(a, b))).
c(order, v(foo(1, 2))).
c(order, v(1 + (a + b))).
c(order, v((a + b) + c)).
c(order, v((a + b) * (c + d))).
c(order, v(sqrt(a) + sqrt(b))).
c(order, v(-(a) + -(b))).
c(order, v(roundtoward(a, foo))).
c(order, v(roundtoward(a + b, to_nearest))).
c(order, v(roundtoward(a, 3))).
c(order, v(roundtoward(a, f(x)))).
c(order, v(roundtoward(a, 1.5))).
c(order, v(roundtoward(a, []))).
c(order, v(1.0Inf + a)).
c(order, v(a + 1.0Inf * 2)).
c(order, (1 + a < b + 1)).
c(order, (a < b)).
c(order, v([a] + b)).
c(order, v(b + [a])).
c(order, v("ab" + c)).
c(order, v(c + "ab")).
c(order, v(f())).
c(order, v(1 + f())).
c(order, v(f() + a)).
c(order, v(2 - 3 - 4)).
c(order, v(2 ^ 3 ^ 2)).
c(order, v((2 ** 3) ** 2)).
c(order, v(7 mod 3 - 10 // 4)).
c(order, (write(x), tab(a + b))).
c(order, format("~2f", [a + b])).
c(order, format("~d", [3 - a])).

%  ---- depth: expressions of any depth, either way nested ------------------

c(depth, (right(200000, 0, T), v(T))).
c(depth, (left(200000, 0, T), v(T))).
c(depth, (one(200000, -, 7, T), v(T))).
c(depth, (one(200001, -, 7, T), v(T))).
c(depth, (one(100000, abs, -5, T), v(T))).
c(depth, (mixed(60000, 0, T), v(T))).
c(depth, (halves(100000, 0.0, T), v(T))).
c(depth, (tenths(100000, 0.0, T), v(T))).
c(depth, (tenths(100000, 0.0, T), v(roundtoward(T, to_positive)))).
c(depth, (tenths(100000, 0.0, T), v(roundtoward(T, to_negative)))).
c(depth, (tenths(100000, roundtoward(0.1 + 0.2, to_positive), T), v(T))).
c(depth, (ones(200, roundtoward(1.0 / 3.0, to_positive), T), v(T), write(' '), modes)).
c(depth, (ones(200, roundtoward(0.1 + 0.2, to_negative), T), v(T), write(' '), modes)).
c(depth, (ones(200, roundtoward(1.0 / 3.0, to_positive), I), ones(200, roundtoward(I, to_negative), T),
          v(T), write(' '), modes)).
c(depth, (right(200, powm(2, 10, 1000), T), v(T))).
c(depth, (right(200, max(1, 2) + min(3, 4) - abs(-5), T), v(T))).
%  the same a thousand levels down, where the compounds are evaluated on
%  stacks of the evaluator's own: a function of one, of two and of three
%  arguments, a list and a string of one character, a constant
c(depth, (right(1000, powm(2, 10, 1000), T), v(T))).
c(depth, (right(1000, max(1, 2) + min(3, 4) - abs(-5), T), v(T))).
c(depth, (right(1000, sqrt(16) + [0'a] - "b" * e, T), v(T))).
c(depth, (right(1000, powm(2, 10, 1000), I), left(1000, powm(I, 1, 7), T), v(T))).
c(depth, (ones(1000, roundtoward(1.0 / 3.0, to_positive), T), v(T), write(' '), modes)).
c(depth, (ones(1000, roundtoward(1.0 / 3.0, to_positive), I), ones(1000, roundtoward(I, to_negative), T),
          v(T), write(' '), modes)).
c(depth, (thirds(3000, 0, T), v(T))).
c(depth, (thirds(3001, 0, T), v(T))).
c(depth, (right(200000, 0, T), v(powm(2, T, 1000)))).
c(depth, (right(1000, 0, A), right(2000, 0, B), right(150, 0, C), v(powm(A, B, C)))).
c(depth, (right(200000, 0, T), v(max(T, 3) - min(T, 3)))).
c(depth, (right(200000, 0, T), right(1000, 0, U), v(T // U + T mod U))).
c(depth, (right(200000, [0'b], T), v(T))).
c(depth, (right(200000, "c", T), v(T))).
c(depth, (right(200000, 1.0Inf - 1.0Inf * 0, T), v(T))).
c(depth, (member(K, [99, 100, 101, 102, 1023, 1024, 1025]), right(K, 0, T),
          X is T, write(K = X), write(' '), fail ; true)).
%  the cycle question walks 4 096 compounds as a tree, then meets each once
c(depth, (member(K, [4094, 4095, 4096, 4097, 4098]), right(K, 0, T),
          X is T, write(K = X), write(' '), fail ; true)).
c(depth, (dag(13, 1, T), right(5000, T, R), v(R))).
c(depth, (dag(20, 1, T), v(T))).
c(depth, (dag(20, 1, T), right(150, T, R), v(R))).
c(depth, (dag(20, a, T), v(T))).
%  a wide expression over deep ones and a deep one over a wide one: the
%  evaluation goes down, across and down again
c(depth, (right(300, 0, R), dag(12, R, T), v(T))).
c(depth, (dag(16, 1, T), right(1000, T, R), v(R))).
c(depth, (left(700, 0, L), right(700, L, R), dag(6, R, T), left(700, T, U), v(U))).
c(depth, (pairs(300, 0, T), v(T))).
c(depth, (pairs(300, 0, P), left(300, P, L), pairs(300, L, T), v(T))).
%  every depth from 90 to 700, each way nested and a fault at the bottom
c(depth, (forall(between(90, 700, K), (right(K, 0, T), left(K, 0, U), T =:= K, U =:= K)), write(ok))).
c(depth, (forall(between(90, 700, K),
                 ( right(K, a, T), catch(_ is T, error(E, _), true), E == type_error(evaluable, a/0) )),
          write(ok))).
%  roundtoward/2 a hundred thousand deep, its mode put back at each level
c(depth, (rts(100000, to_positive, 1.0 / 3.0, T), v(T), write(' '), modes)).
c(depth, (rts(100000, to_negative, 0.1, I), right(1000, I, R), rts(1000, to_positive, R, T),
          v(T), write(' '), modes)).
c(depth, (right(200000, 0, T), T =:= 200000)).
c(depth, (right(200000, 0, T), left(200001, 0, U), T < U)).
c(depth, (right(200000, 0, T), 1 + T > T, T >= T, T =< T, T =\= 1 + T)).

%  ---- cycles: the 101st compound asks whether the whole is cyclic --------

c(cycles, (X = 1 + X, v(X))).
c(cycles, (X = 1 + X, member(K, [0, 98, 99, 100, 101, 1023, 1024, 1025]), right(K, a + X, R),
           write(K), write(' '), case(v(R)), write('; '), fail ; true)).
c(cycles, (X = 1 + X, member(K, [0, 98, 99, 100, 101, 1023, 1024, 1025]), left(K, a + X, R),
           write(K), write(' '), case(v(R)), write('; '), fail ; true)).
c(cycles, (X = 1 + X, member(K, [0, 98, 99, 100, 101, 1023, 1024, 1025]), right(K, X + a, R),
           write(K), write(' '), case(v(R)), write('; '), fail ; true)).
c(cycles, (X = 1 + X, right(200, a, R), v(X + R))).
c(cycles, (X = 1 + X, right(200, 7, R), v(X + R))).
c(cycles, (X = 1 + X, right(50, 7, R), v(X + R))).
c(cycles, (X = 1 + X, left(200, 7, L), v(X + L))).
c(cycles, (X = 1 + X, left(200, 7, L), v(L + X))).
%  a cycle past the 4 096 compounds the question walks as a tree, one under
%  a DAG and beside one, and a DAG with a fault and no cycle
c(cycles, (X = 1 + X, member(K, [4095, 4096, 4097, 200000]), right(K, X, R),
           write(K), write(' '), case(v(R)), write('; '), fail ; true)).
c(cycles, (X = 1 + X, dag(14, X, D), v(D))).
c(cycles, (X = 1 + X, dag(14, 1, D), v(D + X))).
c(cycles, (X = 1 + X, dag(14, 1, D), right(300, D, R), v(X * R))).
c(cycles, (dag(14, a, D), right(300, D, R), v(R))).
%  the cycle beside 300 levels that each hold a compound more
c(cycles, (X = 1 + X, pairs(300, 0, T), v(X + T))).
c(cycles, (X = 1 + X, pairs(300, a, T), v(X + T))).
c(cycles, (X = 1 + X, W = 2 * (3 * X), catch(_ is W, error(type_error(_, C), _), true), C == W)).
c(cycles, (X = 1 + X, member(K, [98, 99, 100]), member(L, [f(), roundtoward(a, to_nearest),
           roundtoward(a, foo), [foo], [0'a] + b, - a, a + 2, 1 + 2 + a, foo(1, 2, a)]),
           right(K, L, R), write(K), write(' '), case(v(X + R)), write('; '), fail ; true)).
%  a list of one character is no compound the count takes: beside the
%  hundredth compound it moves the question one compound on
c(cycles, (X = 1 + X, member(K, [97, 98, 99]), right(K, a, R), write(K), write(' '),
           case(v(X + (R + [0'a]))), write('; '), fail ; true)).
c(cycles, (Y = f(Y), v(Y))).
c(cycles, (Y = f(Y), v(1 + Y))).
c(cycles, (Z = -(Z), v(Z))).
c(cycles, (W = [W], v(W))).
c(cycles, (X = 1 + X, right(2000, X, Q), Q =:= 1)).
c(cycles, (X = 1 + X, right(2000, X, Q), 1 < Q)).
c(cycles, (X = 1 + X, right(2000, X, Q), tab(Q))).
c(cycles, (X = 1 + X, right(200, 0, T), T < X)).
c(cycles, (X = 1 + X, right(200, 0, T), _ is T, format("~d", [X]))).
c(cycles, (X = 1 + X, right(200, 0, T), _ is T, sum_list([1, X], _))).

%  ---- errors: a fault at the bottom of a deep expression ------------------

c(errors, (right(200000, a, T), v(T))).
c(errors, (left(200000, a, T), v(T))).
c(errors, (right(200000, _, T), v(T))).
c(errors, (left(200000, foo(1), T), v(T))).
c(errors, (right(200000, foo(1, a), T), v(T))).
c(errors, (one(200000, -, a, T), v(T))).
c(errors, (one(200000, sqrt, -1, T), v(T))).
c(errors, (right(200000, 1/0, T), v(T))).
c(errors, (right(200000, 1.0e308 * 10, T), v(T))).
c(errors, (right(200000, f(), T), v(T))).
c(errors, (right(200000, [foo], T), v(T))).
c(errors, (right(200000, "ab", T), v(T))).
c(errors, (right(200000, roundtoward(1, foo), T), v(T))).
c(errors, (right(200000, roundtoward(1, _), T), v(T))).
c(errors, (right(200000, roundtoward(1, 3), T), v(T))).
c(errors, (right(200000, a, T), v(foo(T, b)))).
c(errors, (right(200000, 0, T), v(foo(a, T)))).
c(errors, (right(200000, 0, T), v(foo(1, T)))).
c(errors, (right(200000, a, T), v(T + b))).
c(errors, (right(200000, a, T), (T < b))).
c(errors, (right(200000, 0, T), (a < T))).
c(errors, (tenths(100000, a, T), catch(_ is roundtoward(T, to_negative), _, true), modes)).
c(errors, (ones(200, roundtoward(1 + a, to_negative), T), catch(_ is T, _, true), modes)).
c(errors, (ones(200, roundtoward(1 + a, to_positive), I), ones(200, roundtoward(I, to_negative), T),
           catch(_ is T, _, true), modes)).
c(errors, (ones(200, roundtoward(1 + a, to_positive), I), ones(200, roundtoward(I, to_negative), T),
           v(T))).
%  a thousand levels down, where a raise ends the evaluator's own stacks:
%  each rounding mode still pending there is put back
c(errors, (ones(1000, roundtoward(1 + a, to_negative), T), catch(_ is T, _, true), modes)).
c(errors, (right(1000, roundtoward(1 + a, to_positive), T), catch(_ is T, _, true), modes)).
c(errors, (ones(1000, roundtoward(1 + a, to_positive), I), ones(1000, roundtoward(I, to_negative), T),
           catch(_ is T, _, true), modes)).
c(errors, (ones(1000, roundtoward(1, to_positive), I), ones(1000, roundtoward(I + a, to_negative), T),
           catch(_ is T, error(E, _), true), print(E), write(' '), modes)).
c(errors, (right(1000, a, A), right(1000, b, B), right(1000, foo(A, B), T), v(T))).
c(errors, (right(1000, a, A), right(1000, b, B), right(1000, powm(A, 1, B), T), v(T))).
c(errors, (right(1000, powm(2, a, 5), T), v(T))).
c(errors, (rts(100000, to_positive, a, T), catch(_ is T, error(E, _), true), print(E), write(' '), modes)).
c(errors, (rts(100000, to_positive, 1, I), rts(3, foo, I, T), v(T))).
c(errors, (rts(3, foo, 1, I), rts(100000, to_positive, I, T), catch(_ is T, error(E, _), true),
           print(E), write(' '), modes)).
%  two faults past the hundredth compound: the last argument's first there too
c(errors, (right(200000, a + b, T), v(T))).
c(errors, (right(200000, powm(a, b, c), T), v(T))).
c(errors, (right(200000, foo(a, b, c), T), v(T))).
c(errors, (right(50, a, A), right(50, b, B), right(200, foo(A, B), T), v(T))).
c(errors, (right(50, a, A), right(50, b, B), right(200, A - B, T), v(T))).
c(errors, (right(50, a, A), right(50, b, B), right(200, powm(A, 1, B), T), v(T))).

%  ---- others: what else evaluates, each the same evaluator ----------------

c(others, (right(200000, -200000, T), write(x), tab(T), write(y))).
c(others, (right(200000, 0, T), format("~d ~2f", [T, T]))).
c(others, (right(200000, 0, T), sum_list([T, T, 1], S), print(S))).
c(others, (right(200000, 0, T), max_list([1, T, 3], S), print(S))).
c(others, (right(200000, 0, T), min_list([T, 1 + T], S), print(S))).
c(others, (right(200000, 0, T), aggregate_all(sum(E), member(E, [T, 1]), S), print(S))).
c(others, (right(200000, 0, T), aggregate_all(max(E), member(E, [1, T]), S), print(S))).
c(others, sum_list([1, a, b], _)).
c(others, max_list([a, b], _)).
c(others, aggregate_all(sum(E), member(E, [1, a + b]), _)).
c(others, aggregate_all(max(E), member(E, [a, b]), _)).
c(others, (right(200000, a, T), tab(T))).
c(others, (right(200000, 0, T), succ_or_fail(T))).

succ_or_fail(T) :- X is T + 1, succ(X, Y), print(Y).
