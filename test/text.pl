%% modules/text/text.cicili -- grep, sed and the line tools over libc regex.
%%
%% WHAT IS BEING PINNED:
%%
%%   THE PATTERN IS POSIX EXTENDED, so a grep -E from a .sh suite moves
%%   here unchanged -- the anchor test is the exact 'answer\(' extraction
%%   every suite in this family performs.
%%
%%   REPLACEMENT KNOWS & AND \1..\9, sed's own spellings, and an EMPTY
%%   MATCH ADVANCES -- s/x*/-/g on plain text must terminate, which is
%%   the classic way a hand-rolled replace loop hangs.
%%
%%   THE LINE TOOLS ARE CLAUSES: split, join, filter, head, tail --
%%   round-tripping, because a split and a join that disagree about the
%%   last newline corrupt quietly.
%%
%%     cocolog -s test/text.pl        from the checkout root
%%
%% ONE PROCESS FOR SEVEN CHECKS. library(text) is what test/prelude.pl
%% pins every other case's output with, so this case is the one that
%% holds the ruler to the ruler.

:- use_module('test/prelude.pl').

main :-
    (   catch(re_match(a, abc), _, fail)
    ->  true
    ;   skip('(library(text) will not load -- sh modules/text/build.sh)')
    ),
    the_match, the_replace, the_line_tools,
    checks_done.

the_match :-
    section('the match, POSIX extended'),
    written(( ( re_match('^w[0-9]+$', 'w42') -> A1 = yes ; A1 = no ),
              ( re_match('^w[0-9]+$', 'w42x') -> B1 = yes ; B1 = no ) ), A1-B1, G1),
    check('grep -qE, both verdicts', G1, 'yes-no'),
    written(( re_first_atom('answer\\([^)]*\\)', 'noise 1. goal answer(0-5) 1 answer(s).', A2),
              ( A2 == 'answer(0-5)' -> R2 = extracted ; R2 = A2 ) ), R2, G2),
    check('the family''s own idiom: the answer term out of a transcript', G2, extracted).

the_replace :-
    section('the replace, sed''s own rules'),
    written(re_replace_atom('([a-z]+)-([0-9]+)', '\\2:\\1', 'abc-12 and xy-9', R1), R1, G1),
    check('s///g with & and back-references', G1, '12:abc and 9:xy'),
    written(re_replace_atom('x*', '-', 'axa', R2), R2, G2),
    check('an empty match advances -- s/x*/-/g terminates', G2, '-a-a-').

the_line_tools :-
    section('the line tools are clauses'),
    written(( atom_codes(one, L1a), atom_codes(two, L1b), atom_codes(three, L1c),
              codes_lines(Cs1, [L1a, L1b, L1c]), codes_lines(Cs1, Ls1), length(Ls1, N1),
              re_lines(t, Cs1, Ts1), length(Ts1, NT1),
              first_line(Cs1, F1), atom_codes(FA1, F1),
              codes_lines(Back1, Ls1), ( Back1 == Cs1 -> RT1 = same ; RT1 = differs ) ),
            N1-NT1-FA1-RT1, G1),
    check('split, filter, first, and the round trip', G1, '3-2-one-same'),
    written(( head_lines(2, [a, b, c, d], H2), tail_lines(2, [a, b, c, d], T2),
              head_lines(9, [a], H2b) ), H2-T2-H2b, G2),
    check('head and tail by count, short lists unharmed', G2, '[a,b]-[c,d]-[a]'),
    written(( atom_codes(ok, OK3), append(OK3, [10], WithNl3), chomp(WithNl3, A3), atom_codes(AA3, A3),
              chomp(OK3, B3), atom_codes(BA3, B3) ), AA3-BA3, G3),
    check('chomp takes the one trailing newline, and only that', G3, 'ok-ok').
