%  Arithmetic over a NaN and the two zeros: the six comparisons, max/2,
%  min/2 and sign/1 in is/2, max_list/2 and min_list/2, aggregate_all/3's
%  and aggregate/3's numeric forms, checked against SWI. Run by BOTH
%  systems, output compared byte for byte.
%
%  Each case is a clause of its own, so no two share a variable. Left out,
%  because the two differ there by design (COMPAT.md): a float result that
%  is a NaN or an infinity, which SWI raises for (`1.5NaN + 1', `0.0 / 0.0',
%  `2 / 0.0'), and an integer past 64 bits, which SWI makes a bignum of.
%  The terms -- 0.0 \== -0.0, a NaN unifying with itself, the order -- are
%  test/files/float_order.pl's.

s(Label, Value) :- write(Label), write(=), writeq(Value), nl.
r(Label) :- ( catch(c(Label, V), error(E, _), (s(Label, E), fail)) -> s(Label, V) ; s(Label, no) ).

%  the six with their operands in the head: a clause whose first goal is a
%  comparison runs it as a guard where it can (integers only)
lt(X, Y) :- X < Y.
gt(X, Y) :- X > Y.
le(X, Y) :- X =< Y.
ge(X, Y) :- X >= Y.
eq(X, Y) :- X =:= Y.
ne(X, Y) :- X =\= Y.
six(X, Y, L) :-
    findall(P-R, ( member(P, [lt, gt, le, ge, eq, ne]), G =.. [P, X, Y],
                   ( call(G) -> R = yes ; R = no ) ), L).
%  ... and later in a body that has a construct, which makes an environment
envcmp(X, Y, R) :-
    atom(x),
    ( X < Y -> R = lt ; X > Y -> R = gt ; X =:= Y -> R = eq ; R = none ).
%  max and min with their operands in the head, as a guard and in a branch
mx(A, B, X) :- X is max(A, B).
mn(A, B, X) :- X is min(A, B).
mxe(A, B, X) :- atom(x), ( atom(y) -> X is max(A, B) ; X = none ).
mne(A, B, X) :- atom(x), ( atom(y) -> X is min(A, B) ; X = none ).
pairs([p(0.0, -0.0), p(-0.0, 0.0), p(0, -0.0), p(-0.0, 0), p(1, 1.0), p(1.0, 1),
       p(2, 1.5), p(1, 1.5), p(1.0, 1.5NaN), p(1.5NaN, 1), p(3, 4)]).
fold(P, L) :- pairs(Ps), findall(X, ( member(p(A, B), Ps), call(P, A, B, X) ), L).

%  ---- the six comparisons over a NaN: only =\= holds ----
c(a01, yes) :- 1.5NaN =:= 1.5NaN.
c(a02, yes) :- 1.5NaN =\= 1.5NaN.
c(a03, yes) :- 1.5NaN < 1.5NaN.
c(a04, yes) :- 1.5NaN > 1.5NaN.
c(a05, yes) :- 1.5NaN =< 1.5NaN.
c(a06, yes) :- 1.5NaN >= 1.5NaN.
c(a07, yes) :- X = 1.5NaN, X =:= X.
c(a08, yes) :- X = 1.5NaN, X =\= X.
c(a09, yes) :- X = 1.5NaN, X =< X.
c(a10, yes) :- X = 1.5NaN, X >= X.
c(a11, yes) :- 1.5NaN < 1.
c(a12, yes) :- 1.5NaN > 1.
c(a13, yes) :- 1 =< 1.5NaN.
c(a14, yes) :- 1 >= 1.5NaN.
c(a15, yes) :- 1.0 =:= 1.5NaN.
c(a16, yes) :- 1.0 =\= 1.5NaN.
c(a17, yes) :- 1.5NaN =< 1.0Inf.
c(a18, yes) :- -1.0Inf >= 1.5NaN.
c(a19, yes) :- 1.5NaN < 9223372036854775807.
c(a20, yes) :- -9223372036854775808 =\= 1.5NaN.
c(a21, yes) :- -1.5NaN =:= -1.5NaN.
c(a22, yes) :- 1.5NaN =\= -1.5NaN.
c(a23, yes) :- max(1.5NaN, 2) =:= 2.
c(a24, yes) :- call(<, 1.5NaN, 1.0).
c(a25, yes) :- call(=\=, 1.0, 1.5NaN).
c(a26, yes) :- \+ 1.5NaN >= 0.
c(a27, V) :- ( 1.5NaN < 0 -> V = lt ; 1.5NaN >= 0 -> V = ge ; V = neither ).
c(a28, L) :- six(1.5NaN, 1.5NaN, L).
c(a29, L) :- six(1.5NaN, 1, L).
c(a30, L) :- six(1.0, 1.5NaN, L).
c(a31, L) :- six(1, 2, L).
c(a32, L) :- six(2.5, 2.5, L).
c(a33, R) :- envcmp(1.5NaN, 1.5NaN, R).
c(a34, R) :- envcmp(1.5NaN, 0, R).
c(a35, R) :- envcmp(1, 1.5NaN, R).
c(a36, R) :- envcmp(1, 2, R).
c(a37, R) :- envcmp(2.0, 2, R).

%  ---- the zeros, the infinities and integers past a double's 53 bits ----
c(z01, yes) :- 0.0 =:= -0.0.
c(z02, yes) :- -0.0 < 0.0.
c(z03, yes) :- -0.0 =< 0.0.
c(z04, yes) :- 0 =:= -0.0.
c(z05, yes) :- 0.0 =\= -0.0.
c(z06, L) :- six(-0.0, 0.0, L).
c(z07, yes) :- 1.0Inf =:= 1.0Inf.
c(z08, yes) :- -1.0Inf < 1.0Inf.
c(z09, yes) :- 1.0Inf > 9223372036854775807.
c(z10, yes) :- 1.0e308 < 1.0Inf.
c(z11, yes) :- 9007199254740993 =:= 9007199254740992.0.
c(z12, yes) :- 9007199254740993 > 9007199254740992.0.
c(z13, yes) :- 9007199254740993 > 9007199254740992.
c(z14, yes) :- 9223372036854775807 =:= 9.223372036854776e18.

%  ---- max/2 and min/2: -0.0 is the smaller zero, an integer and a float
%  that are equal give the float, and a winner keeps its type ----
c(m01, X) :- X is max(0.0, -0.0).
c(m02, X) :- X is max(-0.0, 0.0).
c(m03, X) :- X is min(0.0, -0.0).
c(m04, X) :- X is min(-0.0, 0.0).
c(m05, X) :- X is max(-0.0, -0.0).
c(m06, X) :- X is min(0.0, 0.0).
c(m07, X) :- X is max(0, -0.0).
c(m08, X) :- X is max(-0.0, 0).
c(m09, X) :- X is min(0, -0.0).
c(m10, X) :- X is min(-0.0, 0).
c(m11, X) :- X is max(0, 0.0).
c(m12, X) :- X is max(0.0, 0).
c(m13, X) :- X is min(0, 0.0).
c(m14, X) :- X is min(0.0, 0).
c(m15, X) :- X is max(1, 1.0).
c(m16, X) :- X is max(1.0, 1).
c(m17, X) :- X is min(1, 1.0).
c(m18, X) :- X is min(1.0, 1).
c(m19, X) :- X is max(2, 1.5).
c(m20, X) :- X is min(2, 1.5).
c(m21, X) :- X is max(1, 1.5).
c(m22, X) :- X is min(1, 1.5).
c(m23, X) :- X is max(-1, -1.0).
c(m24, X) :- X is min(-1, -1.0).
c(m25, X) :- X is max(9007199254740993, 9007199254740992.0).
c(m26, X) :- X is max(9007199254740992.0, 9007199254740993).
c(m27, X) :- X is min(9007199254740993, 9007199254740992.0).
c(m28, X) :- X is max(9007199254740993, 9007199254740992).
c(m29, X) :- X is max(9223372036854775807, 9.0e18).
c(m30, X) :- X is min(-9223372036854775808, -1.0e19).
c(m31, X) :- X is max(2, 1.5) * 3.
c(m32, X) :- X is min(-0.0, 0) * 1.
c(m33, X) :- X is max(1.0Inf, 7).
c(m34, X) :- X is min(-1.0Inf, 7).

%  ---- max/2 and min/2 pass a NaN over, either way round ----
c(m40, X) :- X is max(1.0, 1.5NaN).
c(m41, X) :- X is max(1.5NaN, 1.0).
c(m42, X) :- X is min(1.0, 1.5NaN).
c(m43, X) :- X is min(1.5NaN, 1.0).
c(m44, X) :- X is max(1, 1.5NaN).
c(m45, X) :- X is max(1.5NaN, 1).
c(m46, X) :- X is min(1, 1.5NaN).
c(m47, X) :- X is min(1.5NaN, 1).
c(m48, X) :- X is max(1.5NaN, 1.5NaN).
c(m49, X) :- X is min(1.5NaN, 1.5NaN).
c(m50, X) :- X is max(1.5NaN, -1.0Inf).
c(m51, X) :- X is min(1.0Inf, 1.5NaN).
c(m52, X) :- X is max(1, 1.5NaN) + 1.
c(m53, X) :- X is max(-0.0, 1.5NaN).
c(m54, yes) :- X is max(1.5NaN, -1.5NaN), X == -1.5NaN.
c(m55, yes) :- X is max(-1.5NaN, 1.5NaN), X == 1.5NaN.
c(m56, yes) :- X is min(1.5NaN, -1.5NaN), X == -1.5NaN.

%  ---- the same, as a clause's guard and in an environment's branch ----
c(g01, L) :- fold(mx, L).
c(g02, L) :- fold(mn, L).
c(g03, L) :- fold(mxe, L).
c(g04, L) :- fold(mne, L).

%  ---- sign/1 of a NaN is a NaN, SWI's one; abs/1 and -/1 for the record ----
c(n01, X) :- X is sign(1.5NaN).
c(n02, yes) :- X is sign(-1.5NaN), X == 1.5NaN.
c(n03, X) :- X is sign(-0.0).
c(n04, X) :- X is sign(-1.0Inf).
c(n05, yes) :- X is sign(1.5NaN), X =\= X.
c(n06, yes) :- X is abs(-1.5NaN), X == 1.5NaN.
c(n07, yes) :- X is -(1.5NaN), X == -1.5NaN.
c(n08, X) :- X is abs(-0.0).

%  ---- max_list/2 and min_list/2: `M is max(H, M0)' along the list ----
c(l01, M) :- max_list([1.5NaN, 1.0], M).
c(l02, M) :- max_list([1.0, 1.5NaN], M).
c(l03, M) :- min_list([1.5NaN, 1.0], M).
c(l04, M) :- min_list([1.0, 1.5NaN], M).
c(l05, M) :- max_list([1, 1.0], M).
c(l06, M) :- max_list([1.0, 1], M).
c(l07, M) :- min_list([1, 1.0], M).
c(l08, M) :- max_list([0.0, -0.0], M).
c(l09, M) :- max_list([-0.0, 0.0], M).
c(l10, M) :- min_list([0.0, -0.0], M).
c(l11, M) :- min_list([-0.0, 0.0], M).
c(l12, M) :- max_list([0, -0.0], M).
c(l13, M) :- min_list([0, -0.0], M).
c(l14, M) :- max_list([2, 1.5], M).
c(l15, M) :- min_list([1, 1.5], M).
c(l16, M) :- max_list([1.5NaN], M).
c(l17, M) :- max_list([3, 1.5NaN, 2], M).
c(l18, M) :- min_list([1.5NaN, 1.5NaN, 2, 1], M).
c(l19, M) :- max_list([9007199254740992, 9007199254740993], M).
c(l20, M) :- max_list([9007199254740993, 9007199254740992.0], M).
c(l21, yes) :- max_list([1.5NaN, -1.5NaN], M), M == 1.5NaN.
c(l22, yes) :- min_list([-1.5NaN, 1.5NaN], M), M == -1.5NaN.

%  ---- aggregate_all/3: `M is max(M0, X)', `S is S0 + X' ----
c(h01, M) :- aggregate_all(max(X), member(X, [1.5NaN, 1.0]), M).
c(h02, M) :- aggregate_all(max(X), member(X, [1.0, 1.5NaN]), M).
c(h03, M) :- aggregate_all(min(X), member(X, [1.5NaN, 1.0]), M).
c(h04, M) :- aggregate_all(max(X), member(X, [1, 1.0]), M).
c(h05, M) :- aggregate_all(max(X), member(X, [1.0, 1]), M).
c(h06, M) :- aggregate_all(max(X), member(X, [-0.0, 0.0]), M).
c(h07, M) :- aggregate_all(min(X), member(X, [0.0, -0.0]), M).
c(h08, M) :- aggregate_all(max(X), member(X, [9007199254740992, 9007199254740993]), M).
c(h09, M) :- aggregate_all(min(X), member(X, [9007199254740993, 9007199254740992]), M).
c(h10, M) :- aggregate_all(max(X), member(X, [2, 1.5]), M).
c(h11, M) :- aggregate_all(min(X), member(X, [1.5NaN]), M).
c(h12, M) :- aggregate_all(max(X), member(X, []), M).
c(h13, yes) :- aggregate_all(max(X), member(X, [1.5NaN, -1.5NaN]), M), M == -1.5NaN.
c(h14, S) :- aggregate_all(sum(X), member(X, [9007199254740993, 0]), S).
c(h15, S) :- aggregate_all(sum(X), member(X, [9007199254740993, 1, 0.5]), S).
c(h16, S) :- aggregate_all(sum(X), member(X, [4611686018427387904, 4611686018427387903]), S).
c(h17, S) :- aggregate_all(sum(X), member(X, [-9223372036854775807, -1]), S).
c(h18, S) :- aggregate_all(sum(X), member(X, [1, 2.5]), S).
c(h19, S) :- aggregate_all(sum(X), member(X, [-0.0]), S).
c(h20, S) :- aggregate_all(sum(X), member(X, []), S).
c(h21, M) :- aggregate_all(max(X, W), member(X-W, [9007199254740992-b, 9007199254740993-a]), M).
c(h22, M) :- aggregate_all(min(X, W), member(X-W, [9007199254740993-a, 9007199254740992-b]), M).
c(h23, M) :- aggregate_all(max(X, W), member(X-W, [1.5NaN-a, 1.0-b]), M).
c(h24, M) :- aggregate_all(max(X, W), member(X-W, [1.0-b, 1.5NaN-a]), M).
c(h25, M) :- aggregate_all(min(X, W), member(X-W, [1-a, 1.0-b]), M).
c(h26, M) :- aggregate_all(max(X, W), member(X-W, [-0.0-a, 0.0-b]), M).

%  ---- aggregate/3, SWI's own clauses over max_list/2 and `>' ----
c(j01, M) :- aggregate(max(X), member(X, [1.5NaN, 1.0]), M).
c(j02, M) :- aggregate(min(X), member(X, [0.0, -0.0]), M).
c(j03, M) :- aggregate(max(X, W), member(X-W, [1.5NaN-a, 2.0-b]), M).
c(j04, M) :- aggregate(min(X, W), member(X-W, [2-a, 1.5NaN-c, 1-b]), M).

labels([a01, a02, a03, a04, a05, a06, a07, a08, a09, a10, a11, a12, a13, a14, a15,
        a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30,
        a31, a32, a33, a34, a35, a36, a37,
        z01, z02, z03, z04, z05, z06, z07, z08, z09, z10, z11, z12, z13, z14,
        m01, m02, m03, m04, m05, m06, m07, m08, m09, m10, m11, m12, m13, m14, m15,
        m16, m17, m18, m19, m20, m21, m22, m23, m24, m25, m26, m27, m28, m29, m30,
        m31, m32, m33, m34,
        m40, m41, m42, m43, m44, m45, m46, m47, m48, m49, m50, m51, m52, m53, m54,
        m55, m56,
        g01, g02, g03, g04,
        n01, n02, n03, n04, n05, n06, n07, n08,
        l01, l02, l03, l04, l05, l06, l07, l08, l09, l10, l11, l12, l13, l14, l15,
        l16, l17, l18, l19, l20, l21, l22,
        h01, h02, h03, h04, h05, h06, h07, h08, h09, h10, h11, h12, h13, h14, h15,
        h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26,
        j01, j02, j03, j04]).

main :- labels(Ls), forall(member(L, Ls), r(L)).
