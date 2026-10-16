%  A float result that is a NaN or infinite raises, as SWI's float flags
%  float_undefined, float_overflow and float_zero_div say at their default
%  (error); ** and ^ answer the integer 1 where SWI does; truncate/1 and its
%  kin hand a NaN or an infinity back. Checked against SWI: run by BOTH
%  systems, output compared byte for byte.
%
%  Each case is a clause of its own, so no two share a variable. An error is
%  printed as its formal term alone, the context being each system's own.
%  Left out: an integer past 64 bits, which SWI makes a bignum of. The
%  comparisons, max/2, min/2 and sign/1 over a NaN are float_arith.pl's.

s(Label, Value) :- write(Label), write(=), writeq(Value), nl.
r(Label) :- catch(( c(Label, V) -> s(Label, V) ; s(Label, no) ), error(E, _), s(Label, E)).

%  an expression evaluated with its operands in the head, and later in a
%  body that makes an environment
ev(E, X) :- X is E.
eve(E, X) :- atom(x), ( atom(y) -> X is E ; X = none ).
divh(A, B, X) :- X is A / B.
powh(A, B, X) :- X is A ** B.

%  ---- a result that is no number: evaluation_error(undefined) ----
c(u01, X) :- X is 0.0 / 0.0.
c(u02, X) :- X is 0 / 0.0.
c(u03, X) :- X is 1.5NaN + 1.
c(u04, X) :- X is 1 + 1.5NaN.
c(u05, X) :- X is 1.5NaN - 1.
c(u06, X) :- X is 1.5NaN * 2.
c(u07, X) :- X is 1.5NaN * 0.
c(u08, X) :- X is 1.5NaN / 2.
c(u09, X) :- X is 2 / 1.5NaN.
c(u10, X) :- X is 1.5NaN / 1.5NaN.
c(u11, X) :- X is 1.0Inf - 1.0Inf.
c(u12, X) :- X is 1.0Inf * 0.
c(u13, X) :- X is 0 * 1.0Inf.
c(u14, X) :- X is 1.0Inf * 0.0.
c(u15, X) :- X is 1.0Inf / 1.0Inf.
c(u16, X) :- X is 1.5NaN / 1.0Inf.
c(u17, X) :- X is sqrt(-1.0).
c(u18, X) :- X is sqrt(-1).
c(u19, X) :- X is asin(2.0).
c(u20, X) :- X is acos(-2).
c(u21, X) :- X is log(-1.0).
c(u22, X) :- X is sqrt(1.5NaN).
c(u23, X) :- X is sin(1.5NaN).
c(u24, X) :- X is exp(1.5NaN).
c(u25, X) :- X is atan(1.5NaN).
c(u26, X) :- X is float(1.5NaN).
c(u27, X) :- X is 1.5NaN ** 2.
c(u28, X) :- X is 2 ** 1.5NaN.
c(u29, X) :- X is 1.0 ** 1.5NaN.
c(u30, X) :- X is -1 ** 1.5NaN.
c(u31, X) :- X is -8.0 ** (1 / 3).
c(u32, X) :- X is 0 ** 1.5NaN.
c(u33, X) :- X is 1.5NaN + 0.0.
c(u34, X) :- X is 1.5NaN - 1.5NaN.
c(u35, X) :- X is 1.5NaN * 1.5NaN.

%  ---- an infinite result: evaluation_error(float_overflow) ----
c(o01, X) :- X is 1.0e308 * 10.
c(o02, X) :- X is 10.0 ** 400.
c(o03, X) :- X is exp(1000).
c(o04, X) :- X is 1.0Inf + 1.
c(o05, X) :- X is 1 + 1.0Inf.
c(o06, X) :- X is 1.0Inf - 1.
c(o07, X) :- X is 1.0Inf * 2.
c(o08, X) :- X is -1.0Inf * 2.
c(o09, X) :- X is 1.0Inf / 2.
c(o10, X) :- X is log(0.0).
c(o11, X) :- X is log(-0.0).
c(o12, X) :- X is log(0).
c(o13, X) :- X is sqrt(1.0Inf).
c(o14, X) :- X is sin(1.0Inf).
c(o15, X) :- X is exp(1.0Inf).
c(o16, X) :- X is atan(1.0Inf).
c(o17, X) :- X is float(1.0Inf).
c(o18, X) :- X is 1.0Inf ** 2.
c(o19, X) :- X is 2 ** 1.0Inf.
c(o20, X) :- X is 2.0 ** 2000.
c(o21, X) :- X is 1.0e200 * 1.0e200.
c(o22, X) :- X is -1.0e308 - 1.0e308.
c(o23, X) :- X is 1.0e308 + 1.0e308.
c(o24, X) :- X is 2 ** 2000.0.
c(o25, X) :- X is 1.0e308 / 0.1.

%  ---- a float divided by zero: evaluation_error(zero_divisor) ----
c(z01, X) :- X is 2 / 0.0.
c(z02, X) :- X is 2 / -0.0.
c(z03, X) :- X is -2 / 0.0.
c(z04, X) :- X is 2.0 / 0.
c(z05, X) :- X is 1.0 / 0.0.
c(z06, X) :- X is 1.0Inf / 0.0.
c(z07, X) :- X is 0.0 ** -1.
c(z08, X) :- X is 0 ** -1.
c(z09, X) :- X is 0 ** -1.5.
c(z10, X) :- X is 0.0 ** -1.5.
c(z11, X) :- X is 0 / 0.
c(z12, X) :- X is 1 / 0.
c(z13, X) :- X is -0.0 ** -1.

%  ---- a division by an infinity ----
c(d01, X) :- X is 2 / 1.0Inf.
c(d02, X) :- X is 2.0 / 1.0Inf.
c(d03, X) :- X is -2.0 / 1.0Inf.
c(d04, X) :- X is 2.0 / -1.0Inf.
c(d05, X) :- X is 0.0 / 1.0Inf.
c(d06, X) :- X is -0.0 / 1.0Inf.
c(d07, X) :- X is 2 / -1.0Inf.
c(d08, X) :- X is -2 / 1.0Inf.

%  ---- ** and ^: the integer 1 for a zero exponent and for the base 1 ----
c(p01, X) :- X is 2.0 ** 0.
c(p02, X) :- X is 2.0 ** 0.0.
c(p03, X) :- X is 2 ** 0.0.
c(p04, X) :- X is 2 ** -0.0.
c(p05, X) :- X is 1.5NaN ** 0.
c(p06, X) :- X is 1.0Inf ** 0.
c(p07, X) :- X is 1.5NaN ** 0.0.
c(p08, X) :- X is 1 ** 2.5.
c(p09, X) :- X is 1 ** -1.
c(p10, X) :- X is 1 ** 1.5NaN.
c(p11, X) :- X is 1 ** 1.0Inf.
c(p12, X) :- X is 0 ** 2.
c(p13, X) :- X is 0 ** 2.5.
c(p14, X) :- X is 0 ** 1.0Inf.
c(p15, X) :- X is -1 ** 3.
c(p16, X) :- X is -1 ** 4.
c(p17, X) :- X is -1 ** -3.
c(p18, X) :- X is -1 ** 2.0.
c(p19, X) :- X is 1.0 ** 2.5.
c(p20, X) :- X is 2 ** -1.
c(p21, X) :- X is 2 ** 3.
c(p22, X) :- X is 2.0 ** 3.
c(p23, X) :- X is 4 ** 0.5.
c(p24, X) :- X is 2 ** 1.0.
c(p25, X) :- X is 0.0 ** 0.
c(p26, X) :- X is 0 ** 0.
c(p27, X) :- X is 0.0 ** 0.0.
c(p28, X) :- X is 0.0 ** 2.
c(p29, X) :- X is -2 ** 3.
c(p30, X) :- X is -2.0 ** 3.
c(p31, X) :- X is 2.0 ^ 0.
c(p32, X) :- X is 2 ^ 0.0.
c(p33, X) :- X is 1 ^ 2.5.
c(p34, X) :- X is 2 ^ 3.
c(p35, X) :- X is 2.5 ^ 2.
c(p36, X) :- X is 1.5NaN ^ 0.
c(p37, X) :- X is -1 ^ -3.
c(p38, X) :- X is 1 ^ -2.
%  an operand that is no finite number raises though pow() would answer
c(p39, X) :- X is 1.0Inf ** -1.
c(p40, X) :- X is 2.0 ** -1.0Inf.
c(p41, X) :- X is 0.5 ^ 1.0Inf.

%  ---- truncate/1 and its kin hand a NaN or an infinity back ----
c(t01, X) :- X is truncate(1.0Inf).
c(t02, X) :- X is integer(-1.0Inf).
c(t03, X) :- X is round(1.5NaN).
c(t04, X) :- X is floor(1.0Inf).
c(t05, X) :- X is ceiling(1.5NaN).
c(t06, X) :- X is truncate(-1.0Inf).
c(t07, X) :- X is floor(-1.0Inf).
c(t08, yes) :- X is integer(-1.5NaN), X == -1.5NaN.
c(t09, X) :- X is truncate(1.0Inf) + 1.
c(t10, X) :- X is truncate(2.5).

%  ---- what checks nothing: a literal, -, abs, sign, max, min, compare ----
c(n01, X) :- X is 1.0Inf.
c(n02, X) :- X is 1.5NaN.
c(n03, X) :- X is -(1.0Inf).
c(n04, X) :- X is abs(-1.0Inf).
c(n05, X) :- X is sign(-1.0Inf).
c(n06, X) :- X is max(1.0Inf, 1).
c(n07, X) :- X is min(-1.0Inf, 1.5NaN).
c(n08, yes) :- 1.0Inf > 1.0e308.
c(n09, X) :- X is abs(1.5NaN).
c(n10, X) :- X is -(1.5NaN).

%  ---- the small and the finite stay as they were ----
c(f01, X) :- X is 1.0e-308 / 1.0e10.
c(f02, X) :- X is 4.9e-324 / 2.
c(f03, X) :- X is 1.0e308 * 1.5.
c(f04, X) :- X is exp(709).
c(f05, X) :- X is log(1.0e-320).
c(f06, X) :- X is 1.0 / 3.
c(f07, X) :- X is -0.0 * 1.
c(f08, X) :- X is 0.0 / 1.
c(f09, X) :- X is sqrt(-0.0).
c(f10, X) :- X is 2 / 4.

%  ---- the same through a clause's head, an environment's branch, and
%  the list and aggregate predicates that add ----
c(g01, X) :- divh(1, 0.0, X).
c(g02, X) :- divh(0.0, 0.0, X).
c(g03, X) :- divh(2, 1.0Inf, X).
c(g04, X) :- powh(2.0, 0, X).
c(g05, X) :- powh(1, 1.5NaN, X).
c(g06, X) :- ev(1.0Inf + 1, X).
c(g07, X) :- eve(1.0Inf + 1, X).
c(g08, X) :- eve(0.0 / 0.0, X).
c(g09, X) :- eve(2.0 ** 0, X).
c(g10, X) :- eve(truncate(1.0Inf), X).
c(g11, S) :- sum_list([1.0, 1.0Inf], S).
c(g12, S) :- sum_list([1.5NaN], S).
c(g13, S) :- sum_list([1.0e308, 1.0e308], S).
c(g14, S) :- aggregate_all(sum(X), member(X, [1.0e308, 1.0e308]), S).
c(g15, S) :- aggregate_all(sum(X), member(X, [1, 1.5NaN]), S).
c(g16, M) :- max_list([1.0Inf, 1], M).
c(g17, M) :- aggregate_all(max(X), member(X, [1.0Inf, 1]), M).
c(g18, X) :- catch(X is 1.0Inf + 1, error(E, _), X = caught(E)).

%  ---- max/2 and min/2 of two equal infinities: SWI makes the two one type,
%  a float checked as it is made ----
c(e01, X) :- X is max(1.0Inf, 1.0Inf).
c(e02, X) :- X is min(-1.0Inf, -1.0Inf).
c(e03, X) :- X is max(-1.0Inf, -1.0Inf).
c(e04, X) :- X is max(1.0Inf, -1.0Inf).
c(e05, X) :- X is min(1.0Inf, 1).
c(e06, M) :- max_list([1.0Inf], M).
c(e07, M) :- max_list([1.0Inf, 1.0Inf], M).
c(e08, M) :- min_list([1, -1.0Inf, -1.0Inf], M).
c(e09, M) :- aggregate_all(max(X), member(X, [1.0Inf]), M).
c(e10, M) :- aggregate_all(min(X), member(X, [1, -1.0Inf]), M).
c(e11, M) :- aggregate_all(max(X), member(X, [1, 1.0Inf]), M).
c(e12, M) :- aggregate_all(max(X, W), member(X-W, [1.0Inf-a, 1-b]), M).
c(e13, S) :- sum_list([1.0Inf], S).
c(e14, S) :- sum_list([], S).
c(e15, X) :- X is 2 ^ -1.
c(e16, X) :- X is 2 ^ 0.5.
c(e17, X) :- X is 1.0Inf * -1.
c(e18, X) :- X is -(-1.0Inf).
c(e19, X) :- X is integer(1.0Inf) + 0.
c(e20, X) :- X is 1.0e-320 * 1.0e-10.
c(e21, X) :- X is cos(1.0e308).
c(e22, M) :- aggregate_all(max(X), member(X, [1.5NaN, 1.0Inf]), M).
c(e23, M) :- aggregate_all(max(X), member(X, [1, 1.0Inf, 1.0Inf]), M).
c(e24, M) :- aggregate_all(min(X), member(X, [0, -1.0Inf, -1.0Inf]), M).

labels([u01, u02, u03, u04, u05, u06, u07, u08, u09, u10, u11, u12, u13, u14, u15,
        u16, u17, u18, u19, u20, u21, u22, u23, u24, u25, u26, u27, u28, u29, u30,
        u31, u32, u33, u34, u35,
        o01, o02, o03, o04, o05, o06, o07, o08, o09, o10, o11, o12, o13, o14, o15,
        o16, o17, o18, o19, o20, o21, o22, o23, o24, o25,
        z01, z02, z03, z04, z05, z06, z07, z08, z09, z10, z11, z12, z13,
        d01, d02, d03, d04, d05, d06, d07, d08,
        p01, p02, p03, p04, p05, p06, p07, p08, p09, p10, p11, p12, p13, p14, p15,
        p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30,
        p31, p32, p33, p34, p35, p36, p37, p38, p39, p40, p41,
        t01, t02, t03, t04, t05, t06, t07, t08, t09, t10,
        n01, n02, n03, n04, n05, n06, n07, n08, n09, n10,
        f01, f02, f03, f04, f05, f06, f07, f08, f09, f10,
        g01, g02, g03, g04, g05, g06, g07, g08, g09, g10, g11, g12, g13, g14, g15,
        g16, g17, g18,
        e01, e02, e03, e04, e05, e06, e07, e08, e09, e10, e11, e12, e13, e14, e15,
        e16, e17, e18, e19, e20, e21, e22, e23, e24]).

main :- labels(Ls), forall(member(L, Ls), r(L)).
