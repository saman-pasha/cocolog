%% Rational numbers where cocolog's 64-bit policy meets SWI's bignums, and
%% the places a term travels: a clause head and body, findall/3, a global,
%% a copy, the collector, and the reader's refusals.
%%
%% The arithmetic itself is test/files/rationals.pl, run under BOTH systems
%% and compared byte for byte. This case holds what only one system can
%% have: the overflow it raises where SWI goes on in a bignum, and the
%% engine's own paths.
%%
%%     cocolog -s test/rationals.pl        from the checkout root

:- use_module('test/prelude.pl').

:- dynamic p/1.

main :-
    overflow, reader, storage, heads, guards, collector,
    checks_done.

%% ---- where SWI bignums, cocolog refuses by name -------------------------
formal(Goal, F) :-
    ( catch((call(Goal), F = none), E, (E = error(F0, _) -> F = F0 ; F = E)) ).

overflow :-
    section('the 64-bit policy: a result past 64 bits raises int_overflow'),
    formal(_ is 1r2 ** 100, F1),
    check('1r2 ** 100', F1, evaluation_error(int_overflow)),
    formal(_ is 1r2 + 9223372036854775807, F2),
    check('1r2 + the largest integer', F2, evaluation_error(int_overflow)),
    formal(_ is rdiv(9223372036854775807, 2) * 2 + 1, F3),
    check('an exact rdiv taken one past 64 bits', F3, evaluation_error(int_overflow)),
    formal(_ is lcm(9223372036854775807, 2), F4),
    check('lcm past 64 bits', F4, evaluation_error(int_overflow)),
    formal(_ is rational(1.0e308), F5),
    check('rational/1 of 1e308', F5, evaluation_error(int_overflow)),
    formal(_ is rational(1.0Inf), F6),
    check('rational/1 of an infinity', F6, evaluation_error(rational_overflow)),
    formal(_ is rational(1.5NaN), F7),
    check('rational/1 of a NaN', F7, evaluation_error(undefined)),
    formal(_ is rationalize(1.0Inf), F8),
    check('rationalize/1 of an infinity', F8, evaluation_error(rational_overflow)).

%% ---- the reader's refusals ---------------------------------------------
reader :-
    section('the reader: 1r0 is no number, and a denominator is a token'),
    formal(atom_to_term('1r0', _, _), F1),
    check('1r0 is illegal_number in atom_to_term/3', F1, syntax_error(illegal_number)),
    formal(atom_to_term('1r2x', _, _), F2),
    check('1r2x leaves a token', F2, syntax_error(operator_expected)),
    formal(number_codes(_, "1r0"), F3),
    check('1r0 is illegal_number in number_codes/2', F3, syntax_error(illegal_number)),
    formal(number_codes(_, "1r2 "), F4),
    check('1r2 with a trailing space is illegal_number', F4,
          syntax_error(illegal_number)).

%% ---- a rational kept and read back -------------------------------------
storage :-
    section('a rational through the store, a global and a copy'),
    assertz(p(1r2)),
    p(A1),
    check('a clause head keeps it', A1, 1r2),
    p(A2),
    check('and reads it back', A2, 1r2),
    (   p(0.5) -> A3 = unified ; A3 = refused ),
    check('a float is not the rational', A3, refused),
    findall(X, p(X), L4),
    check('findall/3 copies it', L4, [1r2]),
    copy_term(p(5r6), C5),
    C5 = p(A5),
    check('copy_term/2 copies it', A5, 5r6),
    nb_setval(rat, 7r3),
    nb_getval(rat, A6),
    check('a global keeps it', A6, 7r3),
    (   nb_getval(rat, 7r3) -> A7 = yes ; A7 = no ),
    check('a rational is one term by its pair', A7, yes),
    retract(p(_)),
    (   p(_) -> A8 = present ; A8 = gone ),
    check('and a retract takes it out', A8, gone),
    atom_to_term('a(1r2, -3r4)', T9, B9),
    check('a compound of rationals reads back', T9, a(1r2, -3r4)),
    check('with no bindings', B9, []).

%% ---- compiled heads and bodies -----------------------------------------
heads :-
    section('a rational as a compiled constant'),
    (   h1(1r2) -> A1 = matched ; A1 = missed ),
    check('a clause head of 1r2 matches 1r2', A1, matched),
    (   h1(2r4) -> A2 = matched ; A2 = missed ),
    check('and 2r4, which is the same pair', A2, matched),
    (   h1(0.5) -> A3 = matched ; A3 = missed ),
    check('but not the float', A3, missed),
    h2(X4),
    check('a body hands the rational on', X4, 3r4).

h1(1r2).
h2(X) :- Y = 3r4, X = Y.

%% ---- the guards decline a rational, and the step answers ---------------
guards :-
    section('a guard that cannot decide a rational leaves it to the step'),
    (   g(1r2, X1), X1 == 1 -> A1 = yes ; A1 = no ),
    check('number(X) accepts it and the sum is exact', A1, yes),
    (   g(2, X2), X2 == 5r2 -> A2 = yes ; A2 = no ),
    check('and an integer takes the same road', A2, yes).

g(X, Y) :- number(X), Y is X + 1r2.

%% ---- the collector keeps the table entry it names ----------------------
collector :-
    section('a rational on the heap survives the collector'),
    A1 = 11r7,
    garbage_collect,
    make_garbage(20000),
    garbage_collect,
    (   A1 == 11r7 -> A2 = kept ; A2 = lost ),
    check('the pair is still there', A2, kept),
    B1 = 22r7,
    check('and a second one is its own', B1, 22r7).

make_garbage(0) :- !.
make_garbage(N) :- _ = f(N, a, [N]), M is N - 1, make_garbage(M).
