%% cocolog tutorial 38 -- library(main): argv, and options as terms.
%%
%% TIER 2: `use_module(library(main))', from library/main.pl. Clauses only.
%%
%%     cocolog -s tutorials/library/38-main.pl -- -v --count=3
%%
%% `-s' RATHER THAN `run ... main', and the difference is not brevity. `-s'
%% is `use_module(FILE), main': the program's clauses are muted like any
%% module's, and `main' is named for you. `run' CONSULTS, and consulting
%% writes through -- so a tool run that way against a real knowledge base
%% leaves its own source in the database. Measured:
%%
%%     cocolog --embed KB -s  tool.pl      -> tool_private_fact/1 absent
%%     cocolog --embed KB run tool.pl main -> tool_private_fact(1) stored
%%
%% (This lesson still runs under either, and test/tutorials.pl uses `run'
%% for all seventy-seven files. A lesson has nothing private to leak.)
%%
%% `--' IS THE WHOLE ARRANGEMENT AND IT IS NOT OPTIONAL. Everything before it
%% belongs to cocolog; everything after belongs to your program and arrives as
%% `current_prolog_flag(argv, V)'. There has to be a separator because `run
%% FILE GOAL' reads the LAST argument as the goal -- without one,
%% `run p.pl main --check' would try to prove `--check'.
%%
%% THIS IS NOT SWI'S library(main), and the header of library/main.pl says so
%% at length. It is the same INTERFACE, implemented here, because SWI's own
%% file draws 31 HARD findings from cocolint. Section 8 below is that
%% argument, run rather than asserted. (Eleven of the thirty-one were string
%% predicates when this was written, and are not any more -- the type landed
%% after it. The other twenty stand, which is why this file still does.)
%%
%% WHAT THIS LESSON CLAIMS. Eight sections, every claim a must/3:
%%
%%     1  the argv flag, and what is at its head
%%     2  main/0 hands main/1 the arguments and not the executable
%%     3  long, short, --name=value, and a bundle
%%     4  types, and what a bad value does
%%     5  a boolean's Default is for when the flag IS given
%%     6  `--' again, inside your own arguments
%%     7  unguided parsing, when you define no opt_type/3
%%     8  the usage table, with no column directives to build it

:- use_module(library(main)).

%% ---- the option table this lesson parses against ---------------------
%%
%% ONE CLAUSE PER SPELLING. `-v' and `--verbose' are two entries, not one
%% with an alias, which is SWI's rule too: opt_type/3's first argument IS the
%% spelling, and a single character means a short option.
opt_type(v,       verbose, boolean).
opt_type(verbose, verbose, boolean).
opt_type(n,       count,   integer).
opt_type(count,   count,   integer).
opt_type(o,       out,     atom).
opt_type(out,     out,     atom).
opt_type(l,       level,   oneof([low,mid,high])).
opt_type(level,   level,   oneof([low,mid,high])).
opt_type(q,       quiet,   boolean(false)).
opt_type(quiet,   quiet,   boolean(false)).

opt_help(verbose, 'say more').
opt_help(count,   'how many times').
opt_help(out,     'where to write').
opt_help(level,   'one of low, mid, high').
opt_help(quiet,   'say nothing').
opt_meta(out, 'FILE').

%% THE ENTRY POINT IS main/1, WHICH IS THE POINT. library(main) supplies
%% main/0; you supply main/1. `run FILE main' proves main/0, which is the
%% library's, which strips the executable off the argv flag and calls this.
%% DEFINING main/0 HERE INSTEAD WOULD COLLIDE: cocolog has one namespace and
%% consult APPENDS, so there would be two main/0 and the answer would depend
%% on which was tried first. That is the N1 trap, and this is how to not
%% meet it -- define the arity the library asks you for.
main(_Argv) :-
    format("~n-- 1. the argv flag ------------------------------------~n"),
    s1,
    format("~n-- 2. main/0 and main/1 --------------------------------~n"),
    s2,
    format("~n-- 3. the four spellings -------------------------------~n"),
    s3,
    format("~n-- 4. types --------------------------------------------~n"),
    s4,
    format("~n-- 5. a boolean's Default ------------------------------~n"),
    s5,
    format("~n-- 6. -- inside your own arguments ---------------------~n"),
    s6,
    format("~n-- 7. unguided parsing ---------------------------------~n"),
    s7,
    format("~n-- 8. the usage table ----------------------------------~n"),
    s8,
    format("~ndone~n").

%% ---- 1. the flag ------------------------------------------------------
%%
%% THREE FLAGS ANSWER AND EVERY OTHER ONE FAILS: executable, argv and
%% os_argv. Each is a question about the PROCESS that nothing else in the
%% language can answer; a flag like `bounded' is a question about the
%% LANGUAGE, and cocolog has no flag table to answer those from.
s1 :-
    current_prolog_flag(argv, Argv),
    ( is_list(Argv) -> L = yes ; L = no ),
    must('argv is a list', L, yes),
    Argv = [Exe|_],
    current_prolog_flag(executable, Exe2),
    ( Exe == Exe2 -> H = yes ; H = no ),
    must('its head IS the executable flag', H, yes),
    %% os_argv is the LITERAL command line -- cocolog's own options, the
    %% verb, the file, the goal and the separator all still in it.
    current_prolog_flag(os_argv, Os),
    length(Os, NOs), length(Argv, NAv),
    ( NOs >= NAv -> G = yes ; G = no ),
    must('os_argv is at least as long', G, yes),
    ( current_prolog_flag(bounded, _) -> F = yes ; F = no ),
    must('an invented flag FAILS', F, no),
    show('argv', Argv).

%% ---- 2. main/0 --------------------------------------------------------
%%
%% main/0 STRIPS THE HEAD. SWI's own worked example is `main([Arg])' for a
%% program run with one argument, so main/1 must not see the executable.
%% cocolog keeps it in the flag, because the flag means "the application name
%% and the arguments", and takes it off here.
s2 :-
    current_prolog_flag(argv, [_Exe|Args]),
    cli_arguments(Also),
    ( Also == Args -> S = yes ; S = no ),
    must('cli_arguments/1 is argv without its head', S, yes),
    show('what main/1 was given', Args).

%% ---- 3. the four spellings -------------------------------------------
%%
%% argv_options/3 TAKES A LIST, so a lesson can hand it one and no process
%% has to be spawned to demonstrate a command line.
s3 :-
    argv_options(['-v', '--count=3', '-o', 'out.txt', 'a.pl'], P1, O1),
    must('positional', P1, ['a.pl']),
    ( memberchk(verbose(true), O1) -> V = yes ; V = no ),
    must('-v', V, yes),
    ( memberchk(count(3), O1) -> C = yes ; C = no ),
    must('--count=3', C, yes),
    ( memberchk(out('out.txt'), O1) -> U = yes ; U = no ),
    must('-o out.txt', U, yes),
    %% A BUNDLE IS BOOLEANS THEN AT MOST ONE VALUED OPTION: -vn 5 is -v -n 5.
    argv_options(['-vn', '5', 'rest.pl'], P2, O2),
    must('bundle: positional', P2, ['rest.pl']),
    ( memberchk(verbose(true), O2) -> BV = yes ; BV = no ),
    must('bundle: -v', BV, yes),
    ( memberchk(count(5), O2) -> BN = yes ; BN = no ),
    must('bundle: -n 5', BN, yes),
    %% A NEGATIVE NUMBER IS NOT A BUNDLE OF OPTIONS NAMED 1, 2, 3.
    argv_options(['-3'], P3, O3),
    must('-3 is positional', P3, ['-3']),
    must('and no options', O3, []).

%% ---- 4. types ---------------------------------------------------------
%%
%% NO `string' TYPE, because there is no string. `codes' is the answer and is
%% named for what it gives you, which is what every reader here takes.
s4 :-
    argv_options(['--count', '7'], _, [count(N)]),
    must('integer converts', N, 7),
    ( integer(N) -> I = yes ; I = no ),
    must('and it IS an integer', I, yes),
    argv_options(['--level', 'mid'], _, [level(L)]),
    must('oneof accepts a member', L, mid),
    %% A BAD VALUE THROWS, and the term names the option and the type. A
    %% command line that is wrong is wrong before the program has done
    %% anything, and carrying on with an option the user did not mean is the
    %% one outcome worse than stopping.
    catch(argv_options(['--level', 'nope'], _, _), error(E1, _), true),
    must('a stranger is a type_error', E1, type_error(oneof([low,mid,high]), nope)),
    catch(argv_options(['--count'], _, _), error(E2, _), true),
    must('a missing value names the option', E2, existence_error(cli_option_value, count)),
    catch(argv_options(['--wat'], _, _), error(E3, _), true),
    must('an unknown option is a domain_error', E3, domain_error(cli_option, wat)).

%% ---- 5. a boolean's Default -------------------------------------------
%%
%% `boolean(Default)' IS THE VALUE USED WHEN THE FLAG IS GIVEN -- so
%% boolean(false) means the flag turns something OFF -- and it is NOT a
%% fallback for absence. An option nobody passed is ABSENT, and the program
%% supplies its own fallback. A library that invented one would make
%% `memberchk(verbose(true), Opts)' true for every run of a program nobody
%% passed -v to, which is worse than useless because it looks like it works.
s5 :-
    argv_options(['-q'], _, O1),
    must('boolean(false): -q gives false', O1, [quiet(false)]),
    argv_options(['--no-quiet'], _, O2),
    must('--no-quiet inverts it', O2, [quiet(true)]),
    argv_options(['--noquiet'], _, O3),
    must('--noquiet too', O3, [quiet(true)]),
    argv_options([], _, O4),
    must('and absence is ABSENCE', O4, []),
    %% which is how a program tells "not given" from "given the default":
    (   memberchk(count(C), O4) -> true ; C = 1 ),
    must('your own fallback', C, 1).

%% ---- 6. the separator, again ------------------------------------------
%%
%% `--' INSIDE YOUR ARGUMENTS stops option parsing, so a positional argument
%% that begins with a dash can still be passed. This is the second `--' on a
%% command line and it has nothing to do with the first: the first divides
%% cocolog from your program, this one divides your options from your files.
s6 :-
    argv_options(['-v', '--', '--count=9'], P, O),
    must('after -- it is positional', P, ['--count=9']),
    must('and the -v before it still parsed', O, [verbose(true)]).

%% ---- 7. unguided ------------------------------------------------------
%%
%% WITH NO opt_type/3 THERE IS STILL A PARSE, and it is the obvious one:
%% --name=value and --name value become name(Value), --flag becomes
%% flag(true), --no-x becomes x(false). A number stays a number and
%% everything else stays the atom it was -- NOT read as a term, because
%% `--name foo(1' would then raise where the user plainly meant an atom.
%%
%% This lesson DOES define opt_type/3, so it cannot show the mode by calling
%% argv_options/3 here. tutorials/library/38-main-unguided.pl is not a file;
%% the claim is checked in test/argv.pl, which runs a program that defines no
%% opt_type/3 at all. What IS shown here is the switch itself.
s7 :-
    ( opt_types_defined -> D = yes ; D = no ),
    must('this lesson is guided', D, yes).

%% ---- 8. the usage table -----------------------------------------------
%%
%% NO ~t, ~| OR ~+ ANYWHERE IN IT. cocolog refuses the three column
%% directives by name -- F1 in the dialect card -- and this is what the
%% documented fix looks like: measure the widest left column, compute the
%% padding, write it. SWI's own argv_usage/1 uses ~t twice and is two of the
%% 31 reasons its file cannot be vendored here.
s8 :-
    with_output_to(codes(Cs), argv_usage(0)),
    atom_codes(A, Cs),
    ( sub_atom(A, _, _, _, '--count')     -> T1 = yes ; T1 = no ),
    must('the table names --count', T1, yes),
    ( sub_atom(A, _, _, _, 'INTEGER')     -> T2 = yes ; T2 = no ),
    must('and its INTEGER placeholder', T2, yes),
    ( sub_atom(A, _, _, _, 'FILE')        -> T3 = yes ; T3 = no ),
    must('and opt_meta''s FILE overrides it', T3, yes),
    ( sub_atom(A, _, _, _, 'how many times') -> T4 = yes ; T4 = no ),
    must('and the help text', T4, yes),
    format("~n~w", [A]).

%% ---- the two helpers every lesson repeats ----------------------------
%% Duplicated at the foot of every tutorial on purpose: one you can copy
%% anywhere and run is worth six repeated lines, and one that needs a support
%% file beside it stops working the moment it moves.

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
