%% Lesson 55 -- library(regex): PCRE2, the full Perl-compatible engine.
%%
%% TIER 2. Build it first:   sh modules/regex/build.sh
%% then run:                 COCOLOG_LIBRARY=library ./cocolog run tutorials/library/55-regex.pl main
%%
%% The surface this walks:
%%
%%   rx_match(+Pat, +Text [, +Options])         any match, like grep -qP
%%   rx_first(+Pat, +Text, -Match [, +Options]) the first match, as codes
%%   rx_captures(+Pat, +Text, -Groups [, +Options])
%%   rx_named(+Pat, +Text, -Names, -Values [, +Options])
%%   rx_all(+Pat, +Text, -Matches [, +Options])
%%   rx_replace(+Pat, +Rep, +Text, -Out [, +Options])
%%   rx_split(+Pat, +Text, -Parts [, +Options])
%%   rx_escape(+Text, -Quoted)
%%
%% and the atom spellings: rx_first_atom/3,4, rx_captures_atoms/3,
%% rx_named_atoms/4, rx_all_atoms/3, rx_replace_atom/4,5,
%% rx_replace_first_atom/4,5, rx_capture_atom/4, rx_split_atoms/3.
%%
%% WHY THIS LIBRARY AND NOT library(text): text is grep -E and sed -E,
%% POSIX extended regular expressions. PCRE2 is the syntax people mean
%% when they say "regular expression" -- lookbehind, backreferences,
%% named groups, Unicode properties. Both can be loaded at once; their
%% names never meet (re_* and rx_*).

:- use_module(library(regex)).

main :-
    %% PCRE2 answers its own version -- there is no number of ours here.
    rx_version(V1), atom_length(V1, N1),
    ( N1 > 3 -> M1 = true ; M1 = false ),
    must('PCRE2 says which PCRE2 it is', M1, true),

    %% A LOOKBEHIND is the first thing POSIX cannot do. It checks what is
    %% BEFORE the match without consuming it.
    rx_first_atom('(?<=user=)[a-z]+', 'id user=alice!', U2),
    must('lookbehind: the name after user=', U2, alice),

    %% NAMED GROUPS, in PCRE2's alphabetical order, Values parallel.
    rx_named_atoms('(?<year>\\d{4})-(?<month>\\d{2})', 'date: 2026-10',
                   Ns3, Vs3),
    must('named groups, names alphabetical', Ns3, [month, year]),
    must('and their values in the same order', Vs3, ['10', '2026']),

    %% CAPTURES: group 0 is the whole match, and a group that did not
    %% take is null -- not the empty string, which is a different answer.
    rx_captures_atoms('(a)(b)?(c)?', 'a', Gs4),
    must('captures, null for a group that did not take',
         Gs4, [a, a, null, null]),
    rx_capture_atom('(\\d{4})-(\\d{2})', '2026-10', 2, M4),
    must('one capture by number', M4, '10'),

    %% EVERY MATCH, non-overlapping, in order.
    rx_all_atoms('[A-Za-z]+', 'one two three', As5),
    must('every word', As5, [one, two, three]),

    %% REPLACEMENT understands both spellings: Perl's $1 and ${name},
    %% sed's \1 and &, and $$ for a literal dollar.
    rx_replace_atom('(\\w+)-(\\w+)', '\\2:\\1', 'abc-12 xy-9', R6),
    must('numbered groups, sed spelling', R6, '12:abc 9:xy'),
    rx_replace_atom('(?<w>\\w+)', '[${w}]', 'one two', R7),
    must('a named group as ${name}', R7, '[one] [two]'),
    rx_replace_atom('(a)', '<$0|$&|&|\\1|$$>', 'a', R8),
    must('$0 $& & \\1 and $$ together', R8, '<a|a|a|a|$>'),

    %% AN EMPTY MATCH ADVANCES BY ONE CHARACTER. This is the loop that
    %% hangs when it advances by zero; sed's rule also means an empty
    %% match touching the last one is not a match.
    rx_replace_first_atom('x*', '-', 'axa', R9),
    must('first only: x* on axa', R9, '-axa'),
    rx_replace_atom('x*', '-', 'axa', R10),
    must('all matches, sed\'s empty-match rule', R10, '-a-a-'),

    %% SPLIT keeps every segment, including the empty ones.
    rx_split_atoms(',', 'a,b,,c', Ps11),
    must('split, empty segment and all', Ps11, [a, b, '', c]),

    %% ESCAPE turns literal text into a pattern, and the round trip is
    %% the test: what it makes matches the text it was made from.
    rx_escape('a.b[c]', Q12), atom_codes(A12, Q12),
    must('every metacharacter escaped', A12, 'a\\.b\\[c\\]'),
    ( rx_match(Q12, 'a.b[c]') -> M12 = yes ; M12 = no ),
    must('the escaped pattern matches its own text', M12, yes),
    ( rx_match(Q12, 'axb[c]') -> M13 = yes ; M13 = no ),
    must('and not a near miss', M13, no),

    %% UTF-8 AND UCP ARE THE DEFAULT when the program counts characters:
    %% '.' is one character and \p{L} is a Unicode letter. [bytes] is
    %% PCRE2's byte semantics, where the same text is two bytes.
    rx_all_atoms('\\p{L}+', 'café au lait', Us14),
    must('UTF-8 and Unicode classes by default', Us14, ['café', au, lait]),
    atom_codes('é', Cs15),
    ( rx_match('^.$', Cs15) -> M15 = yes ; M15 = no ),
    must('one character, not one byte', M15, yes),
    ( rx_match('^..$', Cs15, [bytes]) -> M16 = yes ; M16 = no ),
    must('[bytes] counts bytes', M16, yes),

    %% OPTIONS are a list. multiline moves ^ and $ to line ends; dotall
    %% lets . cross a newline; caseless folds case.
    ( rx_match('^b', 'a\nb', [multiline]) -> M17 = yes ; M17 = no ),
    must('multiline', M17, yes),
    ( rx_match('a.b', 'a\nb', [dotall]) -> M18 = yes ; M18 = no ),
    must('dotall', M18, yes),
    ( rx_match('^w[0-9]+$', 'W42', [caseless]) -> M19 = yes ; M19 = no ),
    must('caseless', M19, yes),

    %% start(N) is a BYTE offset; past the end there is no match, which
    %% is a failure, not an error.
    ( rx_match('b', 'abc', [start(1)]) -> M20 = yes ; M20 = no ),
    must('start(1) finds the b', M20, yes),
    ( rx_match('b', 'abc', [start(3)]) -> M21 = yes ; M21 = no ),
    must('start(3) is past it', M21, no),

    %% A PATTERN THAT WILL NOT COMPILE is a catchable ball carrying
    %% PCRE2's own words and the byte offset.
    (   catch(rx_match('(', x), error(cocolog_error(Msg22), _), true)
    ->  sub_atom(Msg22, 0, _, _, 'regex compile:'), M22 = raised
    ;   M22 = not_raised
    ),
    must('a bad pattern raises PCRE2\'s reason', M22, raised),

    format("~nlesson 55: every claim held~n", []),
    write(done), nl.

show(Label, Value) :-
    format("   ~w = ~q~n", [Label, Value]).

must(Label, Got, Want) :-
    (   Got == Want
    ->  show(Label, Got)
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
