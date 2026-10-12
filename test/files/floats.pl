%  A float as it is written, and read back.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  SWI writes the fewest digits that read back as the same double, set out
%  its own way: 0.30000000000000004 for 0.1+0.2, 1.0e22, 1.0e-5,
%  100000000000000.0, an infinity 1.0Inf and a NaN 1.5NaN. Through 1.10.27
%  cocolog wrote %.15g with a ".0" put back: 0.3, which reads back as another
%  number, 1e+22, 1e-05, inf.0 -- and read -0.0 as 0.0, and could not read
%  1.0Inf at all (reported from cicili-lang). The powers of two are the
%  hard case: the gap below one is half the gap above, so the decimal
%  nearest it can miss and the next one up is the answer (2.0 ** -549).

v(X) :- X is 0.1 + 0.2.
v(X) :- X is 1 / 3.0.
v(X) :- X is 2 / 3.0.
v(X) :- X is 33.0 / 7.
v(X) :- X is 2.0 ** 0.5.
v(X) :- X is pi.
v(X) :- X is e.
v(1.0e22).
v(1.0e21).
v(1.0e16).
v(1.0e15).
v(1.0e14).
v(123456789012345680.0).
v(1234567890123456.7).
v(9007199254740993.0).
v(1.0e-4).
v(1.0e-5).
v(0.0001234).
v(-2.5e-7).
v(X) :- X is 1.0e-7 * 3.
v(1.0e100).
v(1.0e-300).
v(5.0e-324).
v(2.2250738585072014e-308).
v(1.7976931348623157e308).
v(100.0).
v(1.5).
v(0.1).
v(123.456).
v(X) :- X is 2.0 ** -549.
v(X) :- X is -(2.0 ** -549).
v(X) :- X is -(2.0 ** -1017).
v(X) :- X is 2.0 ** -1022.
v(X) :- X is 2.0 ** 1023.
v(X) :- X is 2.0 ** 60.
v(X) :- X is 2.0 ** -60.
v(-0.0).
v(X) :- X is -(0.0).
v(X) :- Y = 0.0, X is -Y.
v(X) :- X is -1.0 * 0.0.

%  written four ways, and its text read back as the same float
show(X) :-
    write(X), write(' '), writeq(X), write(' '), print(X), write(' '),
    format("~w", [X]), write(' '),
    term_to_atom(X, A), term_to_atom(Y, A),
    ( Y == X -> write(same) ; write(differs) ), nl.

%  the two values no digits say, read from SWI's spelling and written back
special(A) :-
    term_to_atom(X, A),
    ( float(X) -> write(float) ; write(other) ), write(' '),
    writeq(X), nl.

main :-
    forall(v(X), show(X)),
    forall(member(A, ['1.0Inf', '-1.0Inf', '2.5Inf', '1.5NaN', '0.0Inf']), special(A)).
