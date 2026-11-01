%% LIBRARY 56 -- print_message/2: a message term turned into lines of text and
%% printed in the shape of its kind (cocolog 2.16.0)
%%
%%     ./cocolog run tutorials/library/56-print_message.pl main
%%
%% TIER 1: library/print_message.pl is preloaded at start-up, as swipl has
%% these predicates with no library to load, so nothing is imported here.
%%
%%     print_message(+Kind, +Term)            Term's text, printed for Kind
%%     message_to_string(+Term, -String)      the same text, as a string
%%     print_message_lines(+Stream, +Prefix, +Lines)
%%     message_hook(+Term, +Kind, +Lines)     yours: when it succeeds,
%%                                            nothing more is printed
%%     prolog:message//1                      yours: the text of your terms
%%     source_location(-File, -Line)          the directive a load runs
%%     sumlist(+List, -Sum)                   sum_list/2's old name
%%
%% THE KIND says where the text goes and how each line starts. error is
%% `ERROR: ', warning `Warning: ', informational and information `% ', and
%% every other kind -- help, query, banner, one of your own -- nothing; a
%% query goes to user_output and the rest to user_error. silent prints
%% nothing, and informational and banner print nothing while the flag
%% verbose is silent (what `swipl -q' sets). Every prefix begins a fresh
%% line (`~N'), so a message after half a line of output on either stream
%% starts on a line of its own.
%%
%% THE TERM is turned into lines first: format(Fmt, Args), message_lines(Ls),
%% every ISO error(Formal, Context) in swipl's words, a term your own
%% prolog:message//1 gives words to, and `Unknown message: T' for anything
%% else. A directive's error or warning also names the file and the line.
%%
%% Run alone, this lesson prints its messages among its checks: they are
%% the point.

%% where this directive stands, for the location section below
:- source_location(File, Line), file_base_name(File, Base),
   assertz(lesson_loaded_at(Base, Line)).

%% the text of a term of this lesson's own
:- multifile prolog:message//1.
prolog:message(lesson_greeting(Name)) --> [ 'Hello, ~w'-[Name] ].
prolog:message(lesson_two_lines(N)) --> [ 'first line ~w'-[N], nl, 'second line' ].

%% a hook that keeps what it took: lesson_seen(Term, Kind, Lines)
:- dynamic lesson_seen/3.
:- multifile user:message_hook/3.
:- dynamic user:message_hook/3.
user:message_hook(lesson_secret(X), Kind, Lines) :-
    assertz(lesson_seen(lesson_secret(X), Kind, Lines)).

main :-
    lesson_text,
    lesson_own,
    lesson_printed,
    lesson_hook,
    lesson_fresh_line,
    lesson_location,
    lesson_verbose,
    lesson_sumlist,
    format("done~n").

%% ---- the text of a term -------------------------------------------------
lesson_text :-
    format("~n-- a term's text, read back with message_to_string/2~n"),
    text_of(format('~w items', [3]), S1),
    must('format(Fmt, Args) is its own text', S1, '3 items'),
    %% "..." is a code list here and a string in swipl: text in both
    text_of(format("~w more", [4]), S1b),
    must('a format written "..."', S1b, '4 more'),
    text_of(error(type_error(integer, a), context(foo/2, _)), S2),
    must('an ISO error, its predicate first', S2,
         'foo/2: Type error: `integer\' expected, found `a\' (an atom)'),
    text_of(error(existence_error(procedure, lesson_nowhere/3), lesson_nowhere/3), S3),
    must('an unknown procedure', S3, 'Unknown procedure: lesson_nowhere/3'),
    text_of(error(evaluation_error(zero_divisor), context(system:(/)/2, _)), S4),
    %% a builtin's context names it as swipl does, here `//2'
    must('a division by zero', S4, '//2: Arithmetic: evaluation error: `zero_divisor\''),
    text_of(no_such_message(x), S5),
    must('a term with no words', S5, 'Unknown message: no_such_message(x)').

%% ---- your own terms -----------------------------------------------------
lesson_own :-
    format("~n-- prolog:message//1 gives a term of yours its words~n"),
    text_of(lesson_greeting(ann), S1),
    must('lesson_greeting(ann)', S1, 'Hello, ann'),
    text_of(lesson_two_lines(2), S2),
    must('two lines, joined by a newline', S2, 'first line 2\nsecond line').

%% ---- printed ------------------------------------------------------------
lesson_printed :-
    format("~n-- printed: each kind's prefix, on user_error~n"),
    flush_output,
    print_message(error, lesson_greeting(bob)),
    print_message(warning, lesson_two_lines(3)),
    print_message(informational, format('an informational line', [])),
    print_message(help, format('help has no prefix', [])),
    print_message(silent, format('silent prints nothing', [])),
    print_message(error, error(type_error(integer, a), context(foo/2, _))),
    print_message_lines(user_error, 'LESSON ', ['any prefix ~w'-[you], nl, 'like']),
    format(user_error, "half a line", []),
    print_message(warning, format('begins a line of its own', [])),
    must('print_message/2 succeeds after all of them', yes, yes).

%% ---- the hook -----------------------------------------------------------
lesson_hook :-
    format("~n-- message_hook/3 sees the kind and the lines, and prints~n"),
    format("   nothing more when it succeeds~n"),
    print_message(warning, lesson_secret(1)),
    print_message(silent, lesson_secret(2)),
    findall(T-K, lesson_seen(T, K, _), Seen),
    must('both were taken, the silent one too', Seen,
         [lesson_secret(1)-warning, lesson_secret(2)-silent]),
    lesson_seen(lesson_secret(1), _, Lines),
    must('the lines it was handed', Lines,
         ['Unknown message: ~p'-[lesson_secret(1)]]).

%% ---- a fresh line -------------------------------------------------------
lesson_fresh_line :-
    format("~n-- ~~N begins a line unless one has just begun~n"),
    format(atom(A1), 'abc~Ndef~N', []),
    must('after text, a newline', A1, 'abc\ndef\n'),
    format(atom(A2), '~Nfirst', []),
    must('at the start, nothing', A2, first),
    with_output_to(atom(A3), ( write(a), format('~Nb', []) )),
    must('a capture keeps its own column', A3, 'a\nb').

%% ---- where a directive stands -------------------------------------------
lesson_location :-
    format("~n-- source_location/2 answers while a directive runs~n"),
    lesson_loaded_at(Base, Line),
    must('this file', Base, '56-print_message.pl'),
    must('and the directive''s first line', Line, 36),
    (   source_location(_, _) -> Now = yes ; Now = no ),
    must('in main, after the load, there is none', Now, no).

%% ---- the verbose flag ---------------------------------------------------
lesson_verbose :-
    format("~n-- verbose: silent quiets informational and banner~n"),
    current_prolog_flag(verbose, V0),
    must('verbose, as cocolog starts', V0, normal),
    set_prolog_flag(verbose, silent),
    print_message(informational, format('not printed', [])),
    current_prolog_flag(verbose, V1),
    set_prolog_flag(verbose, normal),
    must('set to silent', V1, silent).

%% ---- sumlist/2 ----------------------------------------------------------
lesson_sumlist :-
    format("~n-- sumlist/2 is sum_list/2 by its old name~n"),
    sumlist([1, 2, 3], S1),
    must('sumlist([1, 2, 3])', S1, 6),
    sumlist([1+1, 2*3], S2),
    must('it evaluates, as sum_list/2 does', S2, 8).

%% a message term's text, as an atom: message_to_string/2 answers a string
text_of(Term, Text) :-
    message_to_string(Term, S),
    atom_string(Text, S).

%% ---- the helpers every lesson here carries -----------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth the few duplicated lines.

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
