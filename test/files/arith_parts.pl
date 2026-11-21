%  divmod/4, nth_integer_root_and_remainder/4, float_class/2,
%  float_parts/4 and bounded_number/3, swipl 9.0.4's (cocolog 3.69.0):
%  COMPAT.md's third group of small built-ins, each foreign in swipl's
%  system module. The case holds:
%  - divmod/4: the quotient floored and the remainder of the divisor's
%    sign, the checks in swipl's order, the zero divisor named divmod/2;
%  - nth_integer_root_and_remainder/4: the root truncated and the
%    remainder of I's sign, a whole float for N, the checks in swipl's
%    order, every root of the powers up to 20^12 and their neighbours;
%  - float_class/2 and float_parts/4: the five classes, frexp's parts, an
%    integer or a rational taken as the float it rounds to;
%  - bounded_number/3: the bounds made, an integer's and a float's
%    neighbours and a rational's float's, a bound compared or refused;
%  - a rational against a float, compared as floats, the rational rounded
%    once, in the comparisons, max/min, the folds and the standard order,
%    and made a float rounded once, under every rounding mode;
%  - the five as predicate_property/2, listing/1 and clause/2 see them.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.68.0 cocolog had none of the five, and a call raised
%  existence_error; a rational and a float were compared exactly, and a
%  rational was made a float by dividing two doubles. Not here, cocolog's
%  own: the integers past 64 bits swipl makes (divmod(-2^63, -1, Q, R)'s
%  quotient, bounded_number/3's neighbours of the two extremes), and
%  bounded_number/3's error for a Num that is no number (COMPAT.md).

%% the goals below name a variable to see what a call bound it to
:- style_check(-singleton).

%% a term with its variables named, by a walk of its own
pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

%% how a goal ended, with its bindings; an error by its formal and the
%% predicate its context names
t(L, G) :-
    catch(( G -> R = yes(G) ; R = no ), E, R = caught(E)),
    % cocolint: C2 -- each ball here is a builtin's, whose context names it as swipl's
    (   R = caught(error(F, context(C, _)))
    ->  pv(L-caught(F, C))
    ;   pv(L-R)
    ),
    nl.

%% the properties swipl's predicate_property/2 gives a system predicate,
%% less those that move with the build
pp(H) :-
    findall(P, ( predicate_property(H, P),
                 \+ memberchk(P, [defined, size(_), last_modified_generation(_),
                                  number_of_clauses(_), number_of_rules(_)]) ), Ps),
    functor(H, N, A), print(N/A-Ps), nl.

main :-
    divmods,
    roots,
    classes,
    parts,
    bounds,
    rationals,
    seen.

divmods :-
    t(d1, divmod(7, 2, Q1, R1)),
    t(d2, divmod(-7, 2, Q2, R2)),
    t(d3, divmod(7, -2, Q3, R3)),
    t(d4, divmod(-7, -2, Q4, R4)),
    t(d5, divmod(7, 0, _, _)),
    t(d6, divmod(0, 0, _, _)),
    t(d7, divmod(7.0, 2, _, _)),
    t(d8, divmod(a, 2, _, _)),
    t(d9, divmod(_, 2, _, _)),
    t(d10, divmod(7, _, _, _)),
    t(d11, divmod(_, a, _, _)),
    t(d12, divmod(a, _, _, _)),
    t(d13, divmod(7, 2, 3, 1)),
    t(d14, divmod(7, 2, 4, _)),
    t(d15, divmod(7, 2.0, _, _)),
    t(d16, divmod(1r2, 2, _, _)),
    t(d17, divmod(7, 2, a, _)),
    t(d18, divmod(7, 2, _, a)),
    t(d19, divmod(7, 2, 3.0, _)),
    t(d20, divmod(a, 0, _, _)),
    t(d21, divmod(7, 0, a, _)),
    t(d22, divmod(9223372036854775807, -1, Q22, R22)),
    t(d23, divmod(-9223372036854775808, 2, Q23, R23)),
    t(d24, divmod(-9223372036854775808, 3, Q24, R24)),
    t(d25, divmod(-5, 9223372036854775807, Q25, R25)),
    t(d26, divmod(-9223372036854775808, 9223372036854775807, Q26, R26)),
    t(d27, divmod(9223372036854775807, -9223372036854775808, Q27, R27)),
    t(d28, divmod(-9223372036854775808, -9223372036854775808, Q28, R28)),
    t(d29, divmod(7, 2, Q29, Q29)),
    t(d30, divmod(-6, 4, Q30, R30)),
    t(d31, divmod(6, -4, Q31, R31)),
    t(d32, divmod(0, -5, Q32, R32)),
    t(d33, divmod(5, -1, Q33, R33)),
    t(d34, divmod(f(x), 1, _, _)),
    t(d35, divmod(1, f(x), _, _)),
    %% the two answers are div/2's and mod/2's
    t(d36, forall(( member(X36, [-9, -7, -1, 0, 1, 7, 9]), member(Y36, [-4, -3, -1, 1, 3, 4]) ),
                  ( divmod(X36, Y36, Q36, R36), Q36 =:= X36 div Y36, R36 =:= X36 mod Y36 ))),
    nl.

roots :-
    t(r1, nth_integer_root_and_remainder(2, 10, A1, B1)),
    t(r2, nth_integer_root_and_remainder(3, 27, A2, B2)),
    t(r3, nth_integer_root_and_remainder(3, -27, A3, B3)),
    t(r4, nth_integer_root_and_remainder(3, -28, A4, B4)),
    t(r5, nth_integer_root_and_remainder(3, -26, A5, B5)),
    t(r6, nth_integer_root_and_remainder(2, -4, _, _)),
    t(r7, nth_integer_root_and_remainder(0, 4, _, _)),
    t(r8, nth_integer_root_and_remainder(1, 4, A8, B8)),
    t(r9, nth_integer_root_and_remainder(1, -4, A9, B9)),
    t(r10, nth_integer_root_and_remainder(2, 0, A10, B10)),
    t(r11, nth_integer_root_and_remainder(-1, 4, _, _)),
    t(r12, nth_integer_root_and_remainder(2, 4.0, _, _)),
    t(r13, nth_integer_root_and_remainder(2.0, 4, A13, B13)),
    t(r14, nth_integer_root_and_remainder(2.5, 4, _, _)),
    t(r15, nth_integer_root_and_remainder(0.0, 4, _, _)),
    t(r16, nth_integer_root_and_remainder(-0.0, 4, _, _)),
    t(r17, nth_integer_root_and_remainder(-1.0, 4, _, _)),
    t(r18, nth_integer_root_and_remainder(1.0e30, 4, _, _)),
    t(r19, nth_integer_root_and_remainder(1.0Inf, 4, _, _)),
    t(r20, nth_integer_root_and_remainder(1.5NaN, 4, _, _)),
    t(r21, nth_integer_root_and_remainder(1r2, 4, _, _)),
    t(r22, nth_integer_root_and_remainder(9.0e18, 4, A22, B22)),
    t(r23, nth_integer_root_and_remainder(9.3e18, 4, _, _)),
    t(r24, nth_integer_root_and_remainder(3.0, -27, A24, B24)),
    t(r25, nth_integer_root_and_remainder(2.0, -4, _, _)),
    t(r26, nth_integer_root_and_remainder(a, 4, _, _)),
    t(r27, nth_integer_root_and_remainder(_, 4, _, _)),
    t(r28, nth_integer_root_and_remainder(2, _, _, _)),
    t(r29, nth_integer_root_and_remainder(_, a, _, _)),
    t(r30, nth_integer_root_and_remainder(0, a, _, _)),
    t(r31, nth_integer_root_and_remainder(0, _, _, _)),
    t(r32, nth_integer_root_and_remainder(0, -4, _, _)),
    t(r33, nth_integer_root_and_remainder(-2, -4, _, _)),
    t(r34, nth_integer_root_and_remainder(2, 1r2, _, _)),
    t(r35, nth_integer_root_and_remainder(f(x), 4, _, _)),
    t(r36, nth_integer_root_and_remainder(64, 9223372036854775807, A36, B36)),
    t(r37, nth_integer_root_and_remainder(63, 9223372036854775807, A37, B37)),
    t(r38, nth_integer_root_and_remainder(62, 9223372036854775807, A38, B38)),
    t(r39, nth_integer_root_and_remainder(2, 9223372036854775807, A39, B39)),
    t(r40, nth_integer_root_and_remainder(3, 9223372036854775807, A40, B40)),
    t(r41, nth_integer_root_and_remainder(3, -9223372036854775808, A41, B41)),
    t(r42, nth_integer_root_and_remainder(63, -9223372036854775808, A42, B42)),
    t(r43, nth_integer_root_and_remainder(65, -9223372036854775808, A43, B43)),
    t(r44, nth_integer_root_and_remainder(1, -9223372036854775808, A44, B44)),
    t(r45, nth_integer_root_and_remainder(1000, 1, A45, B45)),
    t(r46, nth_integer_root_and_remainder(1000, 0, A46, B46)),
    t(r47, nth_integer_root_and_remainder(1001, -1, A47, B47)),
    t(r48, nth_integer_root_and_remainder(1000, -1, _, _)),
    t(r49, nth_integer_root_and_remainder(9223372036854775807, 5, A49, B49)),
    t(r50, nth_integer_root_and_remainder(2, 4611686014132420609, A50, B50)),
    t(r51, nth_integer_root_and_remainder(2, 4611686014132420608, A51, B51)),
    t(r52, nth_integer_root_and_remainder(2, 3, 1, 2)),
    t(r53, nth_integer_root_and_remainder(2, 3, 2, _)),
    t(r54, nth_integer_root_and_remainder(2, 10, R54, R54)),
    t(r55, nth_integer_root_and_remainder(5, -3126, A55, B55)),
    t(r56, nth_integer_root_and_remainder(2, 99999999999999999, A56, B56)),
    t(r57, nth_integer_root_and_remainder(3, 999999999999999999, A57, B57)),
    t(r58, nth_integer_root_and_remainder(7, 9223372036854775807, A58, B58)),
    t(r59, nth_integer_root_and_remainder(40, 9223372036854775807, A59, B59)),
    t(r60, nth_integer_root_and_remainder(-9223372036854775808, 4, _, _)),
    %% the root of each power up to 20^12 and of its two neighbours is the
    %% largest whose power does not pass the number
    t(r61, forall(( between(2, 12, N61), between(1, 20, B61), P61 is B61 ** N61,
                    member(D61, [-1, 0, 1]), I61 is P61 + D61 ),
                  ( nth_integer_root_and_remainder(N61, I61, Q61, M61),
                    Q61 ** N61 =< I61, (Q61 + 1) ** N61 > I61, M61 =:= I61 - Q61 ** N61 ))),
    nl.

classes :-
    t(c1, float_class(1.0, C1)),
    t(c2, float_class(0.0, C2)),
    t(c3, float_class(-0.0, C3)),
    t(c4, float_class(1.0Inf, C4)),
    t(c5, float_class(-1.0Inf, C5)),
    t(c6, float_class(1.5NaN, C6)),
    t(c7, float_class(5.0e-324, C7)),
    t(c8, float_class(-5.0e-324, C8)),
    t(c9, float_class(2.2250738585072014e-308, C9)),
    t(c10, float_class(2.225073858507201e-308, C10)),
    t(c11, float_class(-2.2250738585072014e-308, C11)),
    t(c12, float_class(1.7976931348623157e308, C12)),
    t(c13, float_class(1, _)),
    t(c14, float_class(_, _)),
    t(c15, float_class(a, _)),
    t(c16, float_class(1r2, _)),
    t(c17, float_class(f(1.0), _)),
    t(c18, float_class(1.0, foo)),
    t(c19, float_class(1.0, normal)),
    t(c20, float_class(1.0, zero)),
    t(c21, float_class(1.0, 3)),
    t(c22, float_class(9223372036854775807, _)),
    t(c23, float_class(_, normal)),
    t(c24, float_class(1, foo)),
    t(c25, ( X25 is nan, float_class(X25, C25) )),
    t(c26, ( X26 is inf, float_class(X26, C26) )),
    t(c27, ( X27 is 2.0 ** -1074, float_class(X27, C27) )),
    t(c28, ( X28 is epsilon, float_class(X28, C28) )),
    nl.

parts :-
    t(p1, float_parts(1.0, M1, B1, E1)),
    t(p2, float_parts(0.0, M2, B2, E2)),
    t(p3, float_parts(-0.0, M3, B3, E3)),
    t(p4, float_parts(8.0, M4, B4, E4)),
    t(p5, float_parts(-3.5, M5, B5, E5)),
    t(p6, float_parts(1.0Inf, M6, B6, E6)),
    t(p7, float_parts(-1.0Inf, M7, B7, E7)),
    t(p8, float_parts(1.5NaN, M8, B8, E8)),
    t(p9, float_parts(5.0e-324, M9, B9, E9)),
    t(p10, float_parts(1.7976931348623157e308, M10, B10, E10)),
    t(p11, float_parts(0.1, M11, B11, E11)),
    t(p12, float_parts(1, M12, B12, E12)),
    t(p13, float_parts(-7, M13, B13, E13)),
    t(p14, float_parts(0, M14, B14, E14)),
    t(p15, float_parts(9223372036854775807, M15, B15, E15)),
    t(p16, float_parts(1r2, M16, B16, E16)),
    t(p17, float_parts(-1r3, M17, B17, E17)),
    t(p18, float_parts(_, _, _, _)),
    t(p19, float_parts(a, _, _, _)),
    t(p20, float_parts(f(x), _, _, _)),
    t(p21, float_parts(1.0, 0.5, 2, 1)),
    t(p22, float_parts(1.0, 0.5, 2, 2)),
    t(p23, float_parts(1.0, a, _, _)),
    t(p24, float_parts(1.0, _, 3, _)),
    t(p25, float_parts(1.0, M25, B25, B25)),
    t(p26, float_parts(1.0, 0.5, 2.0, 1)),
    t(p27, float_parts(1+1, _, _, _)),
    t(p28, float_parts(pi, _, _, _)),
    t(p29, float_parts(2.0e-310, M29, B29, E29)),
    t(p30, float_parts(-1.0e-320, M30, B30, E30)),
    t(p31, float_parts(4.0e15, M31, B31, E31)),
    t(p32, float_parts(1r9007199254740993, M32, B32, E32)),
    %% the parts make the float again
    t(p33, forall(member(F33, [1.0, -2.5, 0.1, 1.0e300, 1.0e-300, 5.0e-324, 123456.789]),
                  ( float_parts(F33, M33, B33, E33), F33 =:= M33 * 2.0 ** E33 ))),
    nl.

bounds :-
    t(b1, bounded_number(0, 10, 1)),
    t(b2, bounded_number(0.0, 1.0, 1r2)),
    t(b3, bounded_number(L3, H3, 1.0)),
    t(b4, bounded_number(L4, H4, -1)),
    t(b5, bounded_number(0, 1r2, 1)),
    t(b6, bounded_number(_, _, 1.0Inf)),
    t(b7, bounded_number(_, _, -1.0Inf)),
    t(b8, bounded_number(_, _, 1.5NaN)),
    t(b9, bounded_number(L9, H9, 1r3)),
    t(b10, bounded_number(1, 1, 1)),
    t(b11, bounded_number(0, 2, 1.0)),
    t(b12, bounded_number(L12, 5, 3)),
    t(b13, bounded_number(1, H13, 3)),
    t(b14, bounded_number(a, 5, 3)),
    t(b15, bounded_number(L15, H15, 0.0)),
    t(b16, bounded_number(L16, H16, -0.0)),
    t(b17, bounded_number(L17, H17, 9223372036854775806)),
    t(b18, bounded_number(L18, H18, -9223372036854775807)),
    t(b19, bounded_number(L19, H19, 5.0e-324)),
    t(b20, bounded_number(L20, H20, 1.7976931348623157e308)),
    t(b21, bounded_number(L21, H21, -1.7976931348623157e308)),
    t(b22, bounded_number(0, 10, 10)),
    t(b23, bounded_number(0, 10, 0)),
    t(b24, bounded_number(0.5, 1.5, 1)),
    t(b25, bounded_number(1r2, 3r2, 1)),
    t(b26, bounded_number(L26, H26, 1r2)),
    t(b27, bounded_number(0, 5, 1r3)),
    t(b28, bounded_number(0, a, 1)),
    t(b29, bounded_number(3, 0, 1)),
    t(b30, bounded_number(L30, H30, 1.0e-320)),
    t(b31, bounded_number(L31, H31, 2.0)),
    t(b32, bounded_number(L32, H32, -2.0)),
    t(b33, bounded_number(1.0, 3.0, 2)),
    t(b34, bounded_number(L34, 3.0, 2)),
    t(b35, bounded_number(1.0, H35, 2)),
    t(b36, bounded_number(1.0Inf, 2, 1)),
    t(b37, bounded_number(0, 1.0Inf, 1)),
    t(b38, bounded_number(-1.0Inf, 1.0Inf, 1)),
    t(b39, bounded_number(1.5NaN, 2, 1)),
    t(b40, bounded_number(0, 1.5NaN, 1)),
    t(b41, bounded_number(0, 2, 1.5NaN)),
    t(b42, bounded_number(1.0, 1.0, 1)),
    t(b43, bounded_number(1, 2, 1.0)),
    t(b44, bounded_number(0.9999999999999999, 2, 1)),
    t(b45, bounded_number(1, 2, 1.0000000000000002)),
    t(b46, bounded_number(9223372036854775806, 9223372036854775807, 9223372036854775807.0)),
    t(b47, bounded_number(9223372036854775806.0, 9223372036854775808.0, 9223372036854775807)),
    t(b48, bounded_number(f(x), 5, 3)),
    t(b49, bounded_number(0, f(x), 3)),
    t(b50, bounded_number(L50, L50, 1)),
    t(b51, bounded_number(1r3, 1r2, 2r5)),
    t(b52, bounded_number(1r3, 1r2, 0.4)),
    t(b53, bounded_number(0.3, 0.5, 2r5)),
    t(b54, bounded_number(L54, H54, -1r3)),
    t(b55, bounded_number(L55, H55, 9007199254740993)),
    t(b56, bounded_number(9007199254740992.0, 9007199254740994.0, 9007199254740993)),
    t(b57, bounded_number(L57, H57, 1r10)),
    t(b58, bounded_number(0.3333333333333333, 1, 1r3)),
    t(b59, bounded_number(0, 0.3333333333333333, 1r3)),
    t(b60, bounded_number(1r3, 1, 0.3333333333333333)),
    t(b61, bounded_number(L61, H61, 1r9007199254740993)),
    t(b62, bounded_number(L62, H62, 2.5e-310)),
    t(b63, bounded_number(L63, H63, 22r7)),
    nl.

rationals :-
    t(q1, compare(O1, 1r10, 0.1)),
    t(q2, compare(O2, 0.1, 1r10)),
    t(q3, compare(O3, 1r3, 0.3333333333333333)),
    t(q4, compare(O4, 1r3, 0.33333333333333337)),
    t(q5, compare(O5, 1r9007199254740993, 1.1102230246251564e-16)),
    t(q6, compare(O6, 1r9007199254740993, 1.1102230246251565e-16)),
    t(q7, msort([1r10, 0.1, 1r3, 0.3333333333333333, 1, 1.0, 1r2, 0.5], L7)),
    t(q8, sort(0, @>=, [1r10, 0.1, 1r3, 0.3333333333333333], L8)),
    t(q9, 1r10 < 0.1),
    t(q10, 1r10 =:= 0.1),
    t(q11, 1r3 =:= 0.3333333333333333),
    t(q12, 1r3 > 0.3333333333333333),
    t(q13, 1r9007199254740993 =:= 1.1102230246251564e-16),
    t(q14, 1r9007199254740993 < 1.1102230246251565e-16),
    t(q15, 1r2 < nan),
    t(q16, 1r2 =\= nan),
    t(q17, X17 is max(1r10, 0.1)),
    t(q18, X18 is min(1r10, 0.1)),
    t(q19, X19 is max(0.1, 1r10)),
    t(q20, X20 is max(1r3, 0.3333333333333333)),
    t(q21, X21 is min(1r3, 0.3333333333333333)),
    t(q22, X22 is max(1r2, nan)),
    t(q23, X23 is max(nan, 1r2)),
    t(q24, X24 is min(1r2, nan)),
    t(q25, X25 is min(nan, 1r2)),
    t(q26, X26 is float(1r10)),
    t(q27, X27 is float(1r9007199254740993)),
    t(q28, X28 is float(-1r9007199254740993)),
    t(q29, X29 is float(9007199254740993r9007199254740992)),
    t(q30, X30 is float(9223372036854775807r9223372036854775806)),
    t(q31, X31 is float(1r9223372036854775807)),
    t(q32, X32 is float(9223372036854775807r3)),
    t(q33, X33 is 1.0 - 1r9007199254740993),
    t(q34, X34 is 1r10 + 0.0),
    t(q35, X35 is sqrt(1r9007199254740993)),
    t(q36, X36 is roundtoward(float(1r3), to_positive)),
    t(q37, X37 is roundtoward(float(1r3), to_negative)),
    t(q38, X38 is roundtoward(float(-1r3), to_positive)),
    t(q39, X39 is roundtoward(float(-1r3), to_negative)),
    t(q40, X40 is roundtoward(float(1r10), to_zero)),
    t(q41, X41 is atan2(1r3, 1r7)),
    t(q42, X42 is nexttoward(1r3, 1)),
    t(q43, X43 is 1r3 ** 2.0),
    t(q44, aggregate_all(max(X44), member(X44, [1r10, 0.1]), M44)),
    t(q45, aggregate_all(min(X45), member(X45, [0.1, 1r10]), M45)),
    t(q46, max_list([1r3, 0.3333333333333333], M46)),
    t(q47, min_list([0.3333333333333333, 1r3], M47)),
    t(q48, aggregate_all(max(X48, W48), member(X48-W48, [1r10-a, 0.1-b]), M48)),
    t(q49, max_member(M49, [1r10, 0.1])),
    t(q50, min_member(M50, [0.1, 1r10])),
    t(q51, format(atom(A51), '~e ~g ~4f', [1r9007199254740993, 1r10, 1r3])),
    %% a quotient whose bits past the double's run 100... and a remainder
    %% after them rounds up: the remainder is no tie
    t(q52, X52 is float(9r7)),
    t(q53, X53 is float(-25r7)),
    t(q54, X54 is float(1000000r999999937)),
    nl.

seen :-
    forall(member(H, [divmod(_, _, _, _), nth_integer_root_and_remainder(_, _, _, _),
                      float_class(_, _), float_parts(_, _, _, _), bounded_number(_, _, _)]),
           pp(H)),
    listing(divmod/4),
    listing(bounded_number/3),
    t(s1, clause(float_class(_, _), _)),
    t(s2, clause(divmod(_, _, _, _), _)).
