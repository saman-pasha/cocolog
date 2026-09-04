%% library(bigint) -- Zigurat's arbitrary-precision integers as predicates.
%%
%% WHY THE CASE EXISTS, and it is not hypothetical: cocolog's own integers
%% are 64 bits and they WRAP IN SILENCE. The first check asks `is/2' for
%% the first product a decentralised exchange computes at the scale tokens
%% actually use, and PINS THE WRONG ANSWER it gives. That check passing is
%% the reason for every other check in the file; if a future cocolog grows
%% wide integers it will fail, and this file should be read rather than
%% patched.
%%
%% WHAT IS PINNED:
%%
%%   THE ARITHMETIC IS ZIGURAT'S, NOT A SECOND COPY. libCore is already
%%   linked into cocolog for the embedded engine, so BigInt was in the
%%   process before library(bigint) existed. These checks are that the
%%   Prolog surface reaches it correctly, not that bignum arithmetic
%%   works -- ZiguratIP's own suite covers that.
%%
%%   THE NUMBERS COME FROM OUTSIDE. 2^256 is a constant anyone can look
%%   up; gcd(462,1071)=21 and 3*4=1 (mod 11) are school arithmetic;
%%   2^1000 mod 1000007 = 783922 is reproducible in any language with
%%   wide integers. Nothing here was computed by the thing being tested.
%%
%%   ARBITRARY PRECISION IS ARBITRARY COST, and the refusal must come
%%   BEFORE the cost. bigint_pow(2,20000) is refused for naming a 6021
%%   digit number; bigint_pow(2,10000) is allowed and answers 3011
%%   digits. The first version of that guard estimated the size as
%%   digits(base)*exponent, read 10000 for base 2 where the truth is
%%   3011, and refused work it could easily have done -- so the estimate
%%   is a logarithm now, and both sides of the line are checked here.
%%
%%   AND IT REFUSES TO TRUNCATE. bigint_int/2 gives a cocolog integer
%%   back only when one can hold the value; above that it raises, because
%%   the silent version of that conversion is the bug the whole library
%%   exists to avoid.
%%
%%     cocolog -s test/bigint.pl        from the checkout root
%%
%% ONE PROCESS FOR TWENTY-FOUR CHECKS, where test/bigint.sh spawned one
%% per check (4.5 s on this machine). A refusal is caught as the ball it
%% is and its message read out of the written ball, where the .sh read
%% the same words off the child's stderr.

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(bigint)), _, fail)
    ->  true
    ;   skip('(no library/bigint.so -- sh modules/bigint/build.sh)')
    ),
    the_reason, arithmetic, number_theory, cost_guard, spelling,
    checks_done.

%% the message a refusal carries, as the .sh grepped it off stderr
err(Goal, Msg) :-
    written(catch(Goal, E, true), E, Text),
    (   re_first_atom('bigint [a-z ]+|bigint does not fit an integer', Text, Msg)
    ->  true
    ;   Msg = Text
    ).

the_reason :-
    section('the reason'),
    written(X1 is 1000000000000000000*997, X1, G1),
    check('cocolog''s 64-bit is/2 wraps, silently', G1, '875820019684212736'),
    written(bigint_mul('1000000000000000000', 997, X2), X2, G2),
    check('bigint gets it right', G2, '997000000000000000000').

arithmetic :-
    section('arithmetic, against numbers from the world'),
    written(bigint_pow(2, 256, X1), X1, G1),
    check('2^256, a constant anyone can look up', G1,
          '115792089237316195423570985008687907853269984665640564039457584007913129639936'),
    written(( bigint_pow(2, 256, P2), bigint_sub(P2, 1, X2) ), X2, G2),
    check('and one less is 2^256-1', G2,
          '115792089237316195423570985008687907853269984665640564039457584007913129639935'),
    written(bigint_add('99999999999999999999', 1, X3), X3, G3),
    check('add', G3, '100000000000000000000'),
    written(bigint_sub(5, 12, X4), X4, G4),
    check('a negative difference is negative', G4, '-7'),
    written(bigint_div(7, 2, X5), X5, G5),
    check('div is the floor', G5, '3'),
    written(bigint_mod(7, 2, X6), X6, G6),
    check('mod', G6, '1'),
    err(bigint_div(5, 0, _), G7),
    check('div by zero raises', G7, 'bigint division by zero').

number_theory :-
    section('the number theory Zigurat brought with it'),
    written(bigint_gcd(462, 1071, X1), X1, G1),
    check('gcd(462, 1071)', G1, '21'),
    written(bigint_lcm(4, 6, X2), X2, G2),
    check('lcm(4, 6)', G2, '12'),
    written(bigint_inverse(3, 11, X3), X3, G3),
    check('3 * 4 = 1 (mod 11), so the inverse is 4', G3, '4'),
    err(bigint_inverse(4, 8, _), G4),
    check('no inverse when not coprime, and it says so', G4, 'bigint has no inverse'),
    written(bigint_mod_pow(2, 1000, 1000007, X5), X5, G5),
    check('2^1000 mod 1000007', G5, '783922'),
    written(bigint_sqrt('1000000000000000000000000000000000000', X6), X6, G6),
    check('sqrt(10^36) is 10^18 exactly', G6, '1000000000000000000'),
    written(bigint_sqrt('999999999999999999999999999999999999', X7), X7, G7),
    check('sqrt(10^36 - 1) is one less', G7, '999999999999999999').

cost_guard :-
    section('the cost guard, on both sides of its line'),
    written(( bigint_pow(2, 10000, X1), atom_length(X1, L1) ), len(L1), G1),
    check('2^10000 is allowed, and is 3011 digits', G1, 'len(3011)'),
    err(bigint_pow(2, 20000, _), G2),
    check('2^20000 would be 6021, and is refused', G2, 'bigint result too large').

spelling :-
    section('spelling'),
    written(bigint_dec('0xff', X1), X1, G1),
    check('hex in, decimal out', G1, '255'),
    written(bigint_hex(255, X2), X2, G2),
    check('decimal in, hex out', G2, ff),
    written(bigint_cmp('99999999999999999999', '100000000000000000000', X3), X3, G3),
    check('cmp <', G3, <),
    written(bigint_cmp('12345678901234567890123', '12345678901234567890123', X4), X4, G4),
    check('cmp = at width', G4, =),
    written(( bigint_int('42', X5), Y5 is X5 + 1 ), Y5, G5),
    check('an integer comes back an integer', G5, '43'),
    err(bigint_int('18446744073709551616', _), G6),
    check('2^64 will not fit one, and refuses to truncate', G6, 'bigint does not fit an integer').
