%% modules/regex/regex.cicili -- PCRE2, the full Perl-compatible engine.
%%
%% WHAT IS BEING PINNED:
%%
%%   THE SYNTAX IS PCRE2's, which is the point of the library: a
%%   lookbehind, a named group and \p{L} are things POSIX regcomp -- what
%%   library(text) binds -- cannot do at all.
%%
%%   A MATCH IS CODES AND AN UNSET GROUP IS null, so a program can tell
%%   "took the empty string" from "did not take". The atom spellings are
%%   the Prolog half.
%%
%%   REPLACEMENT takes both spellings people bring: Perl's $1 and
%%   ${name}, sed's \1 and &, and $$ for a dollar. An empty match
%%   ADVANCES BY ONE CHARACTER, so s/x*/-/g terminates and gives sed's
%%   own -a-a-.
%%
%%   UTF-8 AND UCP ARE THE DEFAULT when the program counts characters
%%   (2.0.0's default), and [bytes] is the way back to PCRE2's byte
%%   semantics. That is a real difference, not a spelling: '.' on "é" is
%%   one character here and two bytes there.
%%
%%   A COMPILE ERROR IS A BALL WITH PCRE2'S OWN WORDS, catchable by the
%%   portable error(cocolog_error(Message), _).
%%
%%     cocolog -s test/regex.pl        from the checkout root
%%
%% ONE PROCESS FOR SEVEN SECTIONS. The module needs libpcre2-8, so a
%% checkout without it SKIPs the case rather than failing it: "not built
%% here" and "wrong" are different findings.

:- use_module('test/prelude.pl').

main :-
    (   catch(( use_module(library(regex)), rx_version(_) ), _, fail)
    ->  true
    ;   skip('(library(regex) will not load -- sh modules/regex/build.sh)')
    ),
    the_match, the_groups, the_replacement, the_split, the_options,
    the_errors, beside_text,
    checks_done.

the_match :-
    section('the match: PCRE2, not POSIX'),
    answer(( rx_first_atom('(?<=user=)[a-z]+', 'id user=alice!', M1) ), M1, G1),
    check('lookbehind, which POSIX has not got', G1, alice),
    answer(( ( rx_match('^w[0-9]+$', 'W42', [caseless]) -> R2 = yes ; R2 = no ) ), R2, G2),
    check('caseless on a pattern that is anchored at both ends', G2, yes),
    answer(( rx_all_atoms('[A-Za-z]+', 'one two three', As3) ), As3, G3),
    check('every non-overlapping match', G3, [one, two, three]),
    answer(( ( rx_match('b', 'abc', [start(1)]) -> R4 = yes ; R4 = no ) ), R4, G4),
    check('start(N) begins the search at byte N', G4, yes),
    answer(( ( rx_match('b', 'abc', [start(3)]) -> R5 = yes ; R5 = no ) ), R5, G5),
    check('and a search past the end is no match', G5, no),
    answer(( ( rx_match('z', 'abc') -> R6 = yes ; R6 = no ) ), R6, G6),
    check('no match is failure, never an error', G6, no).

the_groups :-
    section('groups: captures and names'),
    answer(( rx_captures_atoms('(a)(b)?(c)?', 'a', Gs1) ), Gs1, G1),
    check('the whole match, then each group; null where it did not take',
          G1, [a, a, null, null]),
    answer(( rx_named_atoms('(?<year>\\d{4})-(?<month>\\d{2})', '2026-10',
                            Ns2, Vs2) ), Ns2-Vs2, G2),
    check('named groups, PCRE2\'s alphabetical order, values parallel',
          G2, [month, year]-['10', '2026']),
    answer(( rx_capture_atom('(\\d{4})-(\\d{2})', '2026-10', 2, M3) ), M3, G3),
    check('one capture by number, 0 being the whole match', G3, '10'),
    answer(( rx_all_captures_atoms('(\\w)(\\d)', 'a1 b2', Css4) ), Css4, G4),
    check('every match with its groups', G4, [[a1, a, '1'], [b2, b, '2']]),
    answer(( rx_named_atoms('a', 'a', Ns5, Vs5) ), Ns5-Vs5, G5),
    check('a pattern with no names answers two empty lists', G5, []-[]).

the_replacement :-
    section('replacement: Perl and sed together'),
    answer(( rx_replace_atom('(\\w+)-(\\w+)', '\\2:\\1', 'abc-12 xy-9', R1) ),
           R1, G1),
    check('numbered groups, \\N and $N alike', G1, '12:abc 9:xy'),
    answer(( rx_replace_atom('(?<w>\\w+)', '[${w}]', 'one two', R2) ), R2, G2),
    check('a named group as ${name}', G2, '[one] [two]'),
    answer(( rx_replace_atom('(a)', '<$0|$&|&|\\1|$$>', 'a', R3) ), R3, G3),
    check('$0 $& & \\1 and $$', G3, '<a|a|a|a|$>'),
    answer(( rx_replace_first_atom('x*', '-', 'axa', R4) ), R4, G4),
    check('[first] stops after the first match', G4, '-axa'),
    answer(( rx_replace_atom('x*', '-', 'axa', R5) ), R5, G5),
    check('all matches, with sed\'s empty-match rule', G5, '-a-a-'),
    answer(( rx_replace_atom('z', 'x', 'abc', R6) ), R6, G6),
    check('no match leaves the text alone', G6, abc).

the_split :-
    section('split and escape'),
    answer(( rx_split_atoms(',', 'a,b,,c', Ps1) ), Ps1, G1),
    check('split keeps the empty segment between two commas',
          G1, [a, b, '', c]),
    answer(( rx_split_atoms(',', 'a,b,', Ps2) ), Ps2, G2),
    check('and the one after a trailing comma', G2, [a, b, '']),
    answer(( rx_split_atoms(',', '', Ps3) ), Ps3, G3),
    check('an empty text is one empty part', G3, ['']),
    answer(( rx_escape('a.b[c]', Q4), atom_codes(A4, Q4) ), A4, G4),
    check('escape makes every metacharacter literal', G4, 'a\\.b\\[c\\]'),
    answer(( ( rx_match(Q4, 'a.b[c]') -> R5 = yes ; R5 = no ) ), R5, G5),
    check('the escaped pattern matches its own text', G5, yes),
    answer(( ( rx_match(Q4, 'axb[c]') -> R6 = yes ; R6 = no ) ), R6, G6),
    check('and not a near miss', G6, no).

the_options :-
    section('options: UTF-8, UCP, bytes, multiline, dotall'),
    answer(( rx_all_atoms('\\p{L}+', 'café au lait', Us1) ), Us1, G1),
    check('UTF-8 and Unicode classes are the default', G1, ['café', au, lait]),
    answer(( atom_codes('é', Cs2),
              ( rx_match('^.$', Cs2) -> R2 = yes ; R2 = no ) ), R2, G2),
    check('one character, not one byte', G2, yes),
    answer(( atom_codes('é', Cs3),
              ( rx_match('^..$', Cs3) -> R3 = yes ; R3 = no ) ), R3, G3),
    check('two dots do not match one character', G3, no),
    answer(( atom_codes('é', Cs4),
              ( rx_match('^..$', Cs4, [bytes]) -> R4 = yes ; R4 = no ) ), R4, G4),
    check('[bytes] is PCRE2\'s byte semantics', G4, yes),
    answer(( ( rx_match('^b', 'a\nb', [multiline]) -> R5 = yes ; R5 = no ) ), R5, G5),
    check('multiline puts ^ at a line start', G5, yes),
    answer(( ( rx_match('a.b', 'a\nb', [dotall]) -> R6 = yes ; R6 = no ) ), R6, G6),
    check('dotall lets . cross a newline', G6, yes),
    answer(( ( rx_match('a.b', 'a\nb') -> R7 = yes ; R7 = no ) ), R7, G7),
    check('and without it . does not', G7, no),
    answer(( ( rx_match('a.c', 'a.c', [literal]) -> R8 = yes ; R8 = no ) ), R8, G8),
    check('literal matches the metacharacter as itself', G8, yes),
    answer(( ( rx_match('a.c', 'abc', [literal]) -> R9 = yes ; R9 = no ) ), R9, G9),
    check('and stops being a pattern', G9, no).

the_errors :-
    section('refusals are balls, and they name PCRE2\'s reason'),
    answer(( catch(rx_match('(', x),
                   error(cocolog_error(M1), _), true),
              sub_atom(M1, 0, _, _, 'regex compile:') ), yes, G1),
    check('a pattern that will not compile raises, with its message', G1, yes),
    answer(( catch(rx_match(_, _), error(Formal2, _), true) ), Formal2, G2),
    check('an unbound pattern is instantiation_error', G2, instantiation_error),
    answer(( catch(rx_match(a, a, [nonsense]),
                   error(Formal3, _), true) ), Formal3, G3),
    check('an unknown option is a domain error', G3,
          domain_error(regex_option, nonsense)),
    answer(( catch(rx_match(a, a, [start(-1)]),
                   error(Formal4, _), true) ), Formal4, G4),
    check('a negative start is a domain error', G4,
          domain_error(regex_offset, start(-1))),
    answer(( catch(rx_match(1.5, a), error(Formal5, _), true) ), Formal5, G5),
    check('a float is not text', G5, type_error(text, 1.5)).

beside_text :-
    section('beside library(text), which is a different engine'),
    answer(( ( re_match('^a.c$', 'abc'), rx_match('^a.c$', 'abc') ) ), yes, G1),
    check('both libraries are loaded and both answer', G1, yes),
    answer(( ( re_match('(?<=a)b', 'ab') -> R2 = yes ; R2 = no ) ), R2, G2),
    check('and POSIX still refuses a PCRE construct', G2, no).
