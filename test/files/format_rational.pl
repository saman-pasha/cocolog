%  format/2's ~e, ~E, ~f, ~g and ~G of a rational, swipl 9.0.4's
%  (cocolog 3.69.1): the rational's own decimal digits, where cocolog
%  through 3.69.0 wrote the digits of the double the rational rounds to
%  (~20f of 1r3 was 0.33333333333333331483). The case holds:
%  - ~f: its last place rounded half away from zero, the sign of a value
%    that rounds to 0 kept (-0.0), as pl-fmt.c's (n*10^d + m//2)//m;
%  - ~e: the same rounding, but for a value of 1 or more whose exponent
%    passes the places, where swipl cuts the numerator by the power of ten
%    before it divides, truncated (987654321987r5 ~2e is 1.97e+11), and a
%    carry that moves the exponent;
%  - ~g: the digits of the GMP float swipl truncates the rational to, an
%    exact half at its last place read as the digit under it unless the
%    denominator is a power of two (3r20 ~1g is 0.1, 1r8 ~2g 0.13), in C's
%    %g style, its trailing zeros taken off;
%  - an integer written as the float it is, as before, and ~d's refusal;
%  - every directive over a grid of rationals, 64 bits' ends among them.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte. The
%  format strings are atoms: a double-quoted one is codes under cocolog's
%  default and a string under swipl's.

%% a directive of one argument, the value written as it was given
case(F, X) :-
    V is X,
    catch(( format(atom(A), F, [V]) -> R = A ; R = failed ),
          error(E, _), R = caught(E)),
    format('~w ~q -> ~q~n', [F, V, R]).

cases :-
    forall(member(F-X,
                  [ '~0f'-(1 rdiv 2), '~0f'-(3 rdiv 2), '~0f'-(5 rdiv 2),
                    '~0f'-(-1 rdiv 2), '~0f'-(-3 rdiv 2),
                    '~1f'-(1 rdiv 4), '~1f'-(3 rdiv 4), '~1f'-(-1 rdiv 4),
                    '~2f'-(1 rdiv 8), '~2f'-(-1 rdiv 8),
                    '~f'-(1 rdiv 3), '~30f'-(1 rdiv 3), '~20f'-(-1 rdiv 3),
                    '~3f'-(2 rdiv 3), '~3f'-(1000001 rdiv 1000),
                    '~0f'-(1 rdiv 3), '~0f'-(-1 rdiv 3), '~0f'-(-2 rdiv 3),
                    '~1f'-(-1 rdiv 30), '~2f'-(-1 rdiv 300), '~4f'-(-1 rdiv 20000),
                    '~1f'-(5 rdiv 100), '~1f'-(15 rdiv 100), '~1f'-(25 rdiv 100),
                    '~1f'-(35 rdiv 100), '~2f'-(5 rdiv 1000),
                    '~4f'-(1 rdiv 10000000), '~f'-(1 rdiv 10000000),
                    '~1f'-(999 rdiv 100), '~0f'-(19 rdiv 2),
                    '~25f'-(9223372036854775807 rdiv 3),
                    '~20e'-(1 rdiv 3), '~e'-(-1 rdiv 3), '~0e'-(1 rdiv 3),
                    '~0e'-(1 rdiv 2), '~e'-(5 rdiv 2), '~0e'-(5 rdiv 2),
                    '~0e'-(-5 rdiv 2), '~0e'-(15 rdiv 2), '~3e'-(999999 rdiv 1000),
                    '~E'-(1 rdiv 3), '~2e'-(1 rdiv 9223372036854775807),
                    '~2e'-(9223372036854775807 rdiv 2),
                    '~25e'-(1 rdiv 9223372036854775807),
                    '~2e'-(987654321987 rdiv 5), '~15e'-(9223372036854775807 rdiv 3),
                    '~0e'-(-9223372036854775808 rdiv 6), '~1e'-(987654321987 rdiv 25),
                    '~20g'-(1 rdiv 3), '~5g'-(1 rdiv 2), '~g'-(1 rdiv 2),
                    '~3g'-(1000 rdiv 3), '~3g'-(1 rdiv 30000), '~g'-(1 rdiv 30000),
                    '~G'-(1 rdiv 30000), '~0g'-(1 rdiv 3), '~1g'-(5 rdiv 2),
                    '~1g'-(-5 rdiv 2), '~2g'-(95 rdiv 1000),
                    '~g'-(123456789 rdiv 1000), '~g'-(-123456789 rdiv 1000),
                    '~1g'-(3 rdiv 20), '~0g'-(11 rdiv 20), '~2g'-(-21 rdiv 20),
                    '~3G'-(999 rdiv 20), '~3G'-(1001 rdiv 20), '~3G'-(99 rdiv 40),
                    '~g'-(99999 rdiv 40), '~20g'-(9223372036854775807 rdiv 40),
                    '~2g'-(1 rdiv 8), '~1g'-(1 rdiv 4), '~1g'-(3 rdiv 4),
                    '~3g'-(99999 rdiv 100), '~2g'-(-99999 rdiv 100000),
                    '~f'-7, '~20f'-7, '~2f'-9223372036854775807, '~e'-7,
                    '~2f'-(1 rdiv 2 + 1 rdiv 3), '~3f'-(2 rdiv 3 * 3 rdiv 7),
                    '~2d'-(1 rdiv 2), '~D'-(1 rdiv 2)
                  ]),
           case(F, X)),
    format(atom(A1), '~a~2f', [x, 1 rdiv 3]), writeq(A1), nl,
    format(atom(A2), '~t~2f~10|', [1 rdiv 3]), writeq(A2), nl,
    format(atom(A3), '~2f ~2f ~2f', [1 rdiv 3, 2 rdiv 3, -1 rdiv 3]), writeq(A3), nl.

%% every directive over a grid of rationals, the large ones at 64 bits'
%% ends among them
dens([2,3,4,5,6,7,8,9,11,12,16,20,25,40,64,125,999,1000,1024,3125,65536,
      999999937,9007199254740993,9223372036854775807]).
nums([-30,-25,-21,-20,-19,-15,-13,-12,-10,-9,-7,-5,-3,-2,-1,1,2,3,5,7,9,10,11,
      13,15,19,20,21,25,30,99,100,101,999,1000,1001,99999,100000,123456789,
      987654321987,4611686018427387903,9223372036854775807,
      -9223372036854775807,-9223372036854775808]).
fmts(['~0f','~1f','~2f','~3f','~6f','~f','~20f','~0e','~1e','~2e','~e','~15e',
      '~0g','~1g','~2g','~3g','~g','~10g','~20g','~E','~G','~3G']).

grid :-
    dens(Ds), nums(Ns), fmts(Fs),
    forall(( member(D, Ds), member(N, Ns), R is N rdiv D, \+ integer(R),
             member(F, Fs) ),
           ( format(atom(A), F, [R]), format('~w ~w ~w ~w~n', [F, N, D, A]) )).

main :- cases, grid.
