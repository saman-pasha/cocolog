%  SWI's rational numbers, checked against SWI: the literal and its
%  canonical form, the type tests, the arithmetic matrix, the roundings,
%  the standard order, the writer and the text conversions.
%  Run by BOTH systems, output compared byte for byte.
%
%  Each case is a clause of its own, so no two share a variable. Left out:
%  anything SWI answers with a bignum, which this cocolog raises as
%  int_overflow (test/rationals.pl holds that side), and max/min over a NaN,
%  where SWI 9 and SWI 10 differ.

:- discontiguous c/2.

s(Label, Value) :- write(Label), write(=), writeq(Value), nl.
r(Label) :-
    catch(( c(Label, V) -> s(Label, V) ; s(Label, no) ),
          error(F, _), s(Label, error(F))).

%  ---- the literal, and its canonical form ----
c(l01, X) :- X = 1r2.
c(l02, X) :- X = 2r4.
c(l03, X) :- X = -2r4.
c(l04, X) :- X = 01r002.
c(l05, X) :- X = 4r2.
c(l06, yes) :- 1r2 == 2r4.
c(l07, yes) :- \+ 1r2 == 0.5.
c(l08, yes) :- 1r2 =:= 0.5.
c(l09, yes) :- 1r2 =:= 2r4.
c(l10, X) :- X = -1r2.

%  ---- the type tests ----
c(t01, yes) :- number(1r2).
c(t02, yes) :- rational(1r2).
c(t03, yes) :- rational(3).
c(t04, yes) :- \+ rational(0.5).
c(t05, yes) :- \+ integer(1r2).
c(t06, yes) :- \+ float(1r2).
c(t07, yes) :- atomic(1r2).
c(t08, yes) :- callable(1r2).
c(t09, yes) :- \+ compound(1r2).
c(t10, N-D) :- rational(5r6, N, D).
c(t11, N-D) :- rational(7, N, D).
c(t12, yes) :- \+ rational(0.5, _, _).

%  ---- arithmetic ----
c(a01, X) :- X is 1r2 + 1r3.
c(a02, X) :- X is 1r2 - 1r3.
c(a03, X) :- X is 1r2 * 2r3.
c(a04, X) :- X is 1r2 / 1r3.
c(a05, X) :- X is 1r2 / 2.
c(a06, X) :- X is 1 / 1r2.
c(a07, X) :- X is 1r2 rdiv 1r3.
c(a08, X) :- X is 4 rdiv 2.
c(a09, X) :- X is 1r2 + 0.5.
c(a10, X) :- X is 0.5 + 1r2.
c(a11, X) :- X is 7/2.
c(a12, X) :- X is 4/2.
c(a13, X) :- X is 3 * 1r3 + 1r3.
c(a14, X) :- X is 1r2 ** 2.
c(a15, X) :- X is 1r2 ** -1.
c(a16, X) :- X is 2 ** 1r2.
c(a17, X) :- X is 1r2 ** 1r2.
c(a18, X) :- X is abs(-1r2).
c(a19, X) :- X is sign(-1r2).
c(a20, X) :- X is min(1r2, 1r3).
c(a21, X) :- X is max(1r2, 1r3).
c(a22, X) :- X is min(1r2, 0.4).
c(a23, X) :- X is max(1r2, 0.5).
c(a24, X) :- X is float(1r2).
c(a25, X) :- X is 2 * 3r4 - 1r4.
c(a26, X) :- X is 1r3 + 2r3.
c(a27, X) :- X is 1r2 * 1r2.
c(a28, X) :- X is -1r2 - -1r2.
c(a29, X) :- X is 10 rdiv 4.
c(a30, X) :- X is sqrt(4r9).

%  ---- the roundings, and a rational's parts ----
c(r01, X) :- X is integer(3r2).
c(r02, X) :- X is integer(-3r2).
c(r03, X) :- X is round(3r2).
c(r04, X) :- X is round(-3r2).
c(r05, X) :- X is truncate(-3r2).
c(r06, X) :- X is floor(-3r2).
c(r07, X) :- X is ceiling(-3r2).
c(r08, X) :- X is ceil(-3r2).
c(r09, X) :- X is float_integer_part(7r2).
c(r10, X) :- X is float_integer_part(-7r2).
c(r11, X) :- X is float_fractional_part(7r2).
c(r12, X) :- X is float_fractional_part(-7r2).
c(r13, X) :- X is float_integer_part(2).
c(r14, X) :- X is float_fractional_part(2).
c(r15, X) :- X is numerator(5r6).
c(r16, X) :- X is denominator(5r6).
c(r17, X) :- X is rational(0.5).
c(r18, X) :- X is rationalize(0.1).
c(r19, X) :- X is rational(2).
c(r20, X) :- X is rationalize(-0.1).
c(r21, X) :- X is rationalize(2.5).

%  ---- the integer operations added with them ----
c(i01, X) :- X is lcm(4, 6).
c(i02, X) :- X is lcm(0, 0).
c(i03, X) :- X is lcm(-4, 6).
c(i04, X) :- X is gcd(12, 18).
c(i05, X) :- X is lsb(12).
c(i06, X) :- X is popcount(12).
c(i07, X) :- X is getbit(12, 2).
c(i08, X) :- X is getbit(12, 64).
c(i09, X) :- X is getbit(-1, 64).
c(i10, X) :- X is powm(2, 10, 1000).
c(i11, X) :- X is powm(0, 0, 7).
c(i12, X) :- X is 3 // 2.
c(i13, X) :- X is 1 << 4.
c(i14, X) :- X is -1 >> 1.

%  ---- the float functions added with them ----
c(f01, X) :- X is sinh(0.0).
c(f02, X) :- X is log10(100.0).
c(f03, X) :- X is lgamma(5.0).
c(f04, X) :- X is erf(0.5).
c(f05, X) :- X is atan(1.0, 2.0).
c(f06, X) :- X is atan2(1.0, 2.0).
c(f07, X) :- X is copysign(1r2, -1).
c(f08, X) :- X is copysign(1, -2).
c(f09, X) :- X is copysign(0.0, -1).
c(f10, X) :- X is nexttoward(1.0, 2.0).
c(f11, X) :- X is nexttoward(1, 2).
c(f12, X) :- X is eval(1 + 2).
c(f13, X) :- X is eval(1r2).
c(f14, X) :- X is roundtoward(2.5, to_negative).
c(f15, X) :- X is roundtoward(1.0/3.0, to_positive).
c(f16, X) :- X is roundtoward(1r2, to_zero).

%  ---- the standard order ----
c(o01, O) :- compare(O, 0.5, 1r2).
c(o02, O) :- compare(O, 1r2, 0.5).
c(o03, O) :- compare(O, 1, 1r2).
c(o04, O) :- compare(O, 1r2, 1).
c(o05, O) :- compare(O, 1r2, 2r4).
c(o06, O) :- compare(O, 1r3, 0.3333333333333333).
c(o07, L) :- msort([1.0, 1r2, 1, 0.5, -1r2], L).
c(o08, L) :- sort([1r2, 2r4, 1, 1.0], L).
c(o09, yes) :- 1r2 @< 1.
c(o10, yes) :- 1 @> 1r2.
c(o11, yes) :- 0.5 @< 1r2.
c(o12, yes) :- 1r2 @> 0.5.

%  ---- the writer, in every mode ----
c(w01, X) :- X = 1r2, writeq(X), nl.
c(w02, X) :- X = -1r2, write_term(X, [ignore_ops(true)]), nl.
c(w03, X) :- X = 1r2, print(X), nl.
c(w04, X) :- X = 1r2, format("~w~n", [X]).
c(w05, X) :- X = 5r6, format("~q~n", [X]).
c(w06, A) :- term_to_atom(1r2, A).

%  ---- errors, by their formal term ----
c(e01, X) :- X is 1r2 // 2.
c(e02, X) :- X is 2 // 1r2.
c(e03, X) :- X is 1r2 >> 1.
c(e04, X) :- X is 1r2 / 0.
c(e05, X) :- X is 1r2 rdiv 0.
c(e06, X) :- X is 1.0 rdiv 2.
c(e07, X) :- X is 1r2 mod 2.
c(e08, X) :- X is random(1r2).
c(e09, X) :- X is lsb(0).
c(e10, X) :- X is popcount(-1).
c(e11, X) :- X is getbit(12, -1).
c(e12, X) :- X is powm(2, -1, 5).

%  ---- text conversions ----
c(x01, N) :- atom_number('1r2', N).
c(x02, N) :- number_codes(N, "1r2").
c(x03, N) :- number_chars(N, "1r2").
c(x04, T) :- atom_to_term('1r2', T, []).
c(x05, S) :- number_string(1r2, S).

main :-
    forall(member(L,
                  [l01, l02, l03, l04, l05, l06, l07, l08, l09, l10,
                   t01, t02, t03, t04, t05, t06, t07, t08, t09, t10, t11, t12,
                   a01, a02, a03, a04, a05, a06, a07, a08, a09, a10,
                   a11, a12, a13, a14, a15, a16, a17, a18, a19, a20,
                   a21, a22, a23, a24, a25, a26, a27, a28, a29, a30,
                   r01, r02, r03, r04, r05, r06, r07, r08, r09, r10,
                   r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21,
                   i01, i02, i03, i04, i05, i06, i07, i08, i09, i10,
                   i11, i12, i13, i14,
                   f01, f02, f03, f04, f05, f06, f07, f08, f09, f10,
                   f11, f12, f13, f14, f15, f16,
                   o01, o02, o03, o04, o05, o06, o07, o08, o09, o10, o11, o12,
                   w01, w02, w03, w04, w05, w06,
                   e01, e02, e03, e04, e05, e06, e07, e08, e09, e10, e11, e12,
                   x01, x02, x03, x04, x05]),
           r(L)).
