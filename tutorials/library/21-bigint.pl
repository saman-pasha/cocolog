%% LIBRARY 21 -- library(bigint): integers that do not wrap
%%
%%     ./cocolog run tutorials/library/21-bigint.pl main
%%
%% TIER 2: `use_module(library(bigint))', a `.so' from `modules/bigint'.
%% It needs a BUILT ZiguratIP -- the arithmetic is ZiguratIP's `BigInt',
%% reached through Cicili: `sh modules/bigint/build.sh'.
%%
%% ---- WHY THIS EXISTS, IN ONE NUMBER ----------------------------------
%%
%% cocolog's integers are 64 bits and they WRAP IN SILENCE:
%%
%%     1000000000000000000 * 997  =  875820019684212736
%%
%% That is not an error, a warning or a saturation. It is a wrong answer,
%% returned confidently, and it is the first product a token swap
%% computes at ordinary scale. Anything doing money, cryptography or a
%% hash needs arithmetic that does not do that.
%%
%% A BIGINT IS AN ATOM OF DIGITS here, which is worth knowing: they are
%% not Prolog integers and `is/2' knows nothing about them. You call the
%% predicates.
%%
%% THE OTHER ONE: The Coco's `library(u256)' is 256-bit fixed width and
%% RAISES rather than wrapping when an answer will not fit. Two different
%% answers to the same problem -- arbitrary precision here, a fixed width
%% that refuses to be wrong there -- and which you want depends on whether
%% "too big" is a bug or a fact.

:- use_module(library(bigint)).

main :-
    format("~n-- FIRST, the thing this is for~n"),
    Wrapped is 1000000000000000000 * 997,
    show('1000000000000000000 * 997, in plain 64-bit', Wrapped),
    ( Wrapped < 1000000000000000000 -> W = wrapped ; W = fine ),
    must('...which is', W, wrapped),
    format("   Silently. Nothing raised, nothing was logged, and the~n"),
    format("   answer is smaller than one of its own factors.~n"),

    format("~n-- and the same product, done properly~n"),
    bigint_mul('1000000000000000000', '997', Product),
    must('bigint_mul/3', Product, '997000000000000000000'),

    format("~n-- the arithmetic~n"),
    bigint_add('9007199254740993', '1', Sum),
    must('bigint_add/3', Sum, '9007199254740994'),
    bigint_sub('100', '1', Diff),
    must('bigint_sub/3', Diff, '99'),
    bigint_div('1000', '7', Q),
    must('bigint_div/3 truncates', Q, '142'),
    bigint_mod('1000', '7', M),
    must('bigint_mod/3', M, '6'),
    bigint_pow('2', 128, Pow),
    must('2^128, which 64 bits cannot hold at all', Pow,
         '340282366920938463463374607431768211456'),

    format("~n-- comparison, because you cannot use < on atoms of digits~n"),
    bigint_cmp('100', '99', C1), must('100 vs 99', C1, >),
    bigint_cmp('99', '100', C2), must('99 vs 100', C2, <),
    bigint_cmp('42', '42', C3), must('42 vs 42', C3, =),
    format("   `<', `=' and `>' -- the same three atoms `compare/3'~n"),
    format("   answers with, so a caller that already branches on the~n"),
    format("   standard order branches the same way here.~n"),

    format("~n-- and the standard order would NOT have helped~n"),
    ( '100' @< '99' -> O = wrong_way ; O = right_way ),
    must('comparing the ATOMS 100 and 99 alphabetically', O, wrong_way),
    format("   '100' @< '99' is TRUE, because that is string order and~n"),
    format("   these are strings. Use bigint_cmp/3 and nothing else.~n"),

    format("~n-- negative numbers~n"),
    bigint_sub('1', '10', Neg),
    must('1 - 10', Neg, '-9'),
    bigint_mul('-3', '4', NegProd),
    must('-3 * 4', NegProd, '-12'),

    format("~n-- and the ones a chain actually needs~n"),
    bigint_gcd('12', '18', G), must('bigint_gcd/3', G, '6'),
    bigint_lcm('4', '6', LCM), must('bigint_lcm/3', LCM, '12'),
    bigint_sqrt('144', Root), must('bigint_sqrt/3 -- integer root', Root, '12'),
    bigint_mod_pow('2', '10', '1000', MP),
    must('bigint_mod_pow/4 -- 2^10 mod 1000', MP, '24'),
    format("   `bigint_mod_pow/4' is the one that makes RSA and~n"),
    format("   Diffie-Hellman possible at all: computing 2^10 and THEN~n"),
    format("   taking the modulus works for ten, and not for two~n"),
    format("   thousand bits.~n"),
    bigint_hex('255', Hex), must('bigint_hex/2', Hex, ff),
    bigint_int('42', Int), must('bigint_int/2 back to a Prolog integer', Int, 42),

    format("~n-- WHEN TO USE WHICH~n"),
    format("   library(bigint)  arbitrary precision, an atom of digits,~n"),
    format("                    grows as far as it needs to~n"),
    format("   library(u256)    The Coco's: 256 bits, fixed, and an~n"),
    format("                    operation that cannot represent its~n"),
    format("                    answer RAISES~n"),
    format("   plain integers   64 bits, fast, and WRONG past that with~n"),
    format("                    no warning at all~n"),
    format("~n"),
    format("   The fixed-width one is what a chain wants, because `too~n"),
    format("   big' is a rule violation there rather than a number you~n"),
    format("   have not got enough room for.~n~n"),
    format("done~n").

%% ---- the two helpers every lesson here carries ------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth six duplicated lines; a tutorial that needs a support
%% library beside it is a tutorial that stops working the moment it is
%% moved.
show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers. A tutorial that prints whatever it computed is a tutorial
%% that goes quietly wrong the day the language changes underneath it.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
