%% Lesson 32 -- library(process): run, capture, spawn, wait, kill.
%%
%% Run it:   COCOLOG_LIBRARY=library ./cocolog run tutorials/library/32-process.pl main
%%
%% Every test suite in this family is a shell file whose whole
%% vocabulary is `timeout N cmd | grep | sed`, a check function, a
%% background server and a sleep-poll loop. library(process) is that
%% vocabulary as predicates, so a suite can be a .pl file: the C half
%% runs one child and answers its output and exit status; the harness,
%% the pins and the polling are clauses.

:- use_module(library(process)).

main :-
    %% sh/2 runs through /bin/sh -c and captures stdout as CODES --
    %% codes, not an atom, because an atom stops at the first NUL and
    %% a captured log is exactly the text that carries one.
    sh('printf hello', Cs),
    atom_codes(Hello, Cs),
    must('sh/2 captures stdout', Hello, hello),

    %% sh/1 demands exit 0, the way `set -e` does; sh_exit/2 asks the
    %% code and never fails on it.
    ( sh('false') -> F = ran ; F = refused ),
    must('sh/1 refuses a failing command', F, refused),
    sh_exit('exit 7', E7),
    must('sh_exit/2 reports the code', E7, 7),

    %% proc_run/4 is the general form: a timeout in milliseconds, and
    %% a child that outlives it is killed -- whole process group --
    %% and answers 124, coreutils' own number, with the output that
    %% had arrived kept. A timed-out test's half-log is the diagnosis.
    proc_run('echo kept; sleep 30', 500, Out, E),
    must('the timeout answers 124', E, 124),
    atom_codes(Kept, Out),
    must('with the partial output kept', Kept, 'kept\n'),

    %% A background process: its own session (it outlives the turn
    %% that started it -- the server case), a pid you can watch, and
    %% proc_stop/1 to tear it down: 15 first, 9 after, always reaped.
    proc_spawn('sleep 30', P),
    ( proc_running(P) -> R1 = up ; R1 = down ),
    must('a spawned child runs', R1, up),
    proc_stop(P),
    ( proc_running(P) -> R2 = up ; R2 = down ),
    must('and proc_stop ends it', R2, down),

    %% proc_until/3 is the sleep-poll loop as one goal: retry a
    %% condition every StepMs until it proves or the budget runs out.
    proc_spawn('sleep 1', Q),
    ( proc_until(proc_wait(Q, 0, _), 5000, 100) -> U = ended ; U = still ),
    must('proc_until polls to the answer', U, ended),

    %% And the harness a suite writes its pins with: check/3 compares,
    %% says ok or FAIL with both values, and remembers; checks_done
    %% says GREEN or RED and FAILS on red, so a script's exit status
    %% carries the verdict. (This lesson's own must/3 predates it and
    %% stays -- a tutorial that can run anywhere carries its own.)
    check('six sevens', 42, 42),
    checks_done,

    format("~nlesson 32: every claim held~n", []).

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
