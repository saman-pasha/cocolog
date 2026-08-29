%% Lesson 33 -- library(text): grep, sed and the line tools, as clauses
%% over libc's own POSIX regex.
%%
%% Run it:   COCOLOG_LIBRARY=library ./cocolog run tutorials/library/33-text.pl main

:- use_module(library(text)).

main :-
    %% re_match/2 is grep -qE: POSIX extended, so a pattern moves
    %% here from a shell suite unchanged.
    ( re_match('^w[0-9]+$', 'w42') -> M1 = yes ; M1 = no ),
    must('a pattern matches', M1, yes),
    ( re_match('^w[0-9]+$', nope) -> M2 = yes ; M2 = no ),
    must('and refuses honestly', M2, no),

    %% re_first/3 is grep -oE | head -1 -- the family's own idiom,
    %% pulling the answer term out of a transcript.
    re_first_atom('answer\\([^)]*\\)', 'noise answer(0-5) more', A),
    must('the answer line extracted', A, 'answer(0-5)'),

    %% re_replace/4 is sed -E s///g, with & and \1..\9 -- and sed's
    %% own empty-match rule, so s/x*/-/g terminates.
    re_replace_atom('([a-z]+)-([0-9]+)', '\\2:\\1', 'abc-12 xy-9', R),
    must('sed with back-references', R, '12:abc 9:xy'),

    %% the line tools are clauses: split and join are one relation,
    %% and the filter is findall over re_match.
    atom_codes(one, L1), atom_codes(two, L2), atom_codes(three, L3),
    codes_lines(Cs, [L1, L2, L3]),
    re_lines(t, Cs, Ts), length(Ts, NT),
    must('grep as a filter over lines', NT, 2),
    first_line(Cs, F), atom_codes(FA, F),
    must('head -1 is one word', FA, one),
    append(L1, [10], WithNl), chomp(WithNl, Ch),
    must('chomp takes the trailing newline', Ch, L1),

    format("~nlesson 33: every claim held~n", []),
    write(done), nl.

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
