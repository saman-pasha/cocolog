%% LIBRARY 05 -- library(dcg), and SWI's dcg/basics
%%
%%     ./cocolog run tutorials/library/05-dcg.pl main
%%
%% TIER 1, BOTH OF THEM: `dcg' is compiled in, and `dcg/basics' and
%% `dcg/high_order' are SWI's own files, vendored unedited under their
%% own BSD-2 headers and read at start-up. No import for either.
%%
%% THE TRANSLATION IS WRITTEN, NOT COPIED. SWI's `boot/dcg.pl' is half
%% source-position terms and module qualification -- machinery for a
%% module system cocolog does not have -- and what is left once both are
%% removed is short enough to write. Writing it keeps third-party code out
%% of the core.
%%
%% IT RUNS INSIDE `coco_assert', the one function every clause passes
%% through, which is the detail that matters here: a grammar rule means
%% the same thing consulted from a file, asserted by a running program, or
%% ARRIVING FROM THE DATABASE. A DCG stored in a knowledge base is a DCG.
%%
%% `library(dcg/basics)' IS THE ONE YOU WILL ACTUALLY USE -- integer//1,
%% number//1, string//1, blanks//0, and the rest. The things it needed
%% were built here rather than worked around: the soft cut `*->',
%% `code_type/2', `must_be/2', `format/1,2,3' with its `codes(H,T)' sink,
%% `with_output_to/2', and acceptance of the `:- module' line a library
%% file starts with.
%%
%% See tutorials/basics/10 for what `-->' desugars to. This file is about
%% what comes with it.

%% A tiny INI-ish line parser, built on dcg/basics.
setting(Key-Value) -->
    blanks, key(Key), blanks, "=", blanks, value(Value), blanks.

key(K)   --> string_without("= \t\n", Cs), { Cs \== [], atom_codes(K, Cs) }.
value(V) --> integer(V), !.
value(V) --> string_without("\n", Cs), { atom_codes(V, Cs) }.

main :-
    format("~n-- the numbers, from dcg/basics~n"),
    phrase(integer(I), "-42"),
    must('integer//1', I, -42),
    phrase(number(N), "3.5"),
    must('number//1', N, 3.5),
    phrase(digits(Ds), "123"),
    must('digits//1 gives CODES', Ds, [49, 50, 51]),

    format("~n-- whitespace, which is most of what a parser does~n"),
    phrase((blanks, integer(J)), "   7"),
    must('blanks//0 then a number', J, 7),
    phrase((integer(_), blanks_to_nl), "9   \n"),
    format("   blanks_to_nl//0 eats to the end of the line~n"),

    format("~n-- string//1 and string_without//2~n"),
    phrase(string_without("=", K), "name=x", Rest),
    atom_codes(KA, K), atom_codes(RA, Rest),
    must('string_without stops before its delimiter', KA, name),
    must('and leaves the rest', RA, '=x'),

    format("~n-- put together, that is a configuration file line~n"),
    phrase(setting(S1), "  port = 8080"),
    must('a numeric setting', S1, port-8080),
    phrase(setting(S2), "host=example.org"),
    must('and a textual one', S2, host-'example.org'),

    format("~n-- eos//0 is why an ANCHORED grammar matters~n"),
    ( phrase((integer(_), eos), "12x") -> Anchor = matched ; Anchor = refused ),
    must('integer then end-of-input against "12x"', Anchor, refused),
    format("   A vendored `eol//0' once matched END OF INPUT, and a~n"),
    format("   truncated HTTP request parsed as a complete one. That is~n"),
    format("   the shape of a request-smuggling bug, and it is why every~n"),
    format("   library here prefixes its private names.~n"),

    format("~n-- and a grammar can be built at run time, like any clause~n"),
    assertz((greeting --> "hi")),
    ( phrase(greeting, "hi") -> Built = works ; Built = no ),
    must('a DCG rule asserted while running', Built, works),
    format("   The translation happens in coco_assert, so it applies to a~n"),
    format("   rule that arrives from anywhere -- including the database.~n"),
    format("   Which also means the STORED clause is the translated one:~n"),
    format("   greeting/2, not greeting//0. Retract it under that name.~n"),
    retractall(greeting(_, _)),
    ( catch(phrase(greeting, "hi"), _, fail) -> Left = still ; Left = gone ),
    must('after retractall(greeting(_, _))', Left, gone),
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
