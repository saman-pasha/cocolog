%% Lesson 35 -- library(os): which system, who am I, cores, environment,
%% and where a tool is -- without starting a shell to ask.
%%
%% Run it:
%%   COCOLOG_LIBRARY=library ./cocolog run tutorials/library/35-os.pl main
%%
%% The day this family's suites first ran on a Mac, every script that
%% needed to know where it was shelled out: `uname -s', `command -v
%% Xvfb', `$TMPDIR' with its trailing slash. Each is a fact the process
%% already holds. This lesson asks library(os) instead, and every claim
%% below is true on Linux AND on macOS -- which is the point.

:- use_module(library(os)).

main :-
    %% the one branch a portable script needs
    os_name(Sys),
    (   memberchk(Sys, [linux, darwin, freebsd, openbsd, netbsd])
    ->  must('a system this lesson has heard of', known, known)
    ;   must('a system this lesson has heard of', Sys, known)
    ),
    os_arch(Arch), os_cpus(Cpus),
    format("   running on ~w ~w, ~w cpus~n", [Sys, Arch, Cpus]),
    ( Cpus >= 1 -> must('at least one cpu', yes, yes) ; must('at least one cpu', Cpus, yes) ),

    %% who am I, as numbers the kernel hands out
    os_pid(Pid), os_ppid(PPid),
    ( Pid \== PPid -> must('a process is not its parent', yes, yes)
    ;               must('a process is not its parent', Pid-PPid, yes) ),

    %% the environment: read, default, set, unset
    os_home(Home), atom(Home),
    must('HOME is an atom', yes, yes),
    os_env('COCOLOG_LESSON_35', D, absent),
    must('an unset name answers its default', D, absent),
    os_setenv('COCOLOG_LESSON_35', set_here),
    os_env('COCOLOG_LESSON_35', V),
    must('and a set one answers its value', V, set_here),
    os_unsetenv('COCOLOG_LESSON_35'),
    ( os_env('COCOLOG_LESSON_35', _) -> U = still ; U = gone ),
    must('unset takes it back', U, gone),
    os_environ(Pairs),
    ( memberchk('HOME'-Home, Pairs) -> E = listed ; E = missing ),
    must('os_environ lists HOME with the same value', E, listed),

    %% a temporary directory you can join a name onto
    os_tmp(Tmp),
    ( atom_concat(_, '/', Tmp) -> Slash = trailing ; Slash = none ),
    must('os_tmp carries no trailing slash', Slash, none),

    %% a tool, found along PATH
    ( os_which(sh, ShPath) -> true ; ShPath = none ),
    ( atom_concat(_, '/sh', ShPath) -> Sh = found ; Sh = ShPath ),
    must('sh is on the path', Sh, found),
    ( os_has(no_such_tool_for_lesson_35) -> N = found ; N = absent ),
    must('and a tool that is not there is absent', N, absent),

    %% the two names that differ between systems, said once
    os_lib_path_var(LibVar),
    (   Sys == darwin
    ->  must('the linker variable on macOS', LibVar, 'DYLD_LIBRARY_PATH')
    ;   must('the linker variable elsewhere', LibVar, 'LD_LIBRARY_PATH')
    ),
    os_describe(Line),
    format("   ~w~n", [Line]),
    format("~nlesson 35: every claim held~n", []),
    write(done), nl.

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
