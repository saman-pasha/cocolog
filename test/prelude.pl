%% cocolog -- test/prelude.pl: what every .pl case shares.
%%
%% A CASE IS ONE PROCESS. The .sh suite spawned a cocolog per check --
%% `timeout 60 cocolog query ... | grep -aoE 'answer(...)' | sed', forty
%% times in test/string.sh alone, ~120 ms each on this machine and most
%% of it start-up and pipe plumbing -- so a case that asked forty
%% questions paid five seconds to hear forty answers it could have had
%% from one proof. A .pl case is `cocolog -s test/<case>.pl' from the
%% checkout root: main/0 runs every check in the one process,
%% checks_done/0 says GREEN or RED, and THE EXIT CODE IS THE VERDICT --
%% 0 exactly when main proved, which checks_done withholds on any red
%% check. CivV's suite made the same move first; its test/prelude.pl is
%% this file's model, and test/run.sh reads a .pl case the way CivV's
%% does: exit status for the colour, a `SKIP' line for a skip.
%%
%% THE VOCABULARY IS COCOLOG'S OWN. library(process) owns check/3 and
%% checks_done/0 -- the harness every .sh re-implemented -- and running
%% a child where a check genuinely IS a second process: a file whose
%% directives report on stderr, a store read back by another cocolog.
%% library(text) is grep as a clause, for pins on captured output.
%% What this file adds is the handful of shapes every case needs:
%%
%%   answer(+Goal, ?Template, -Got)  Goal proved ONCE; Got is Template's
%%                                   value, `failed', or error(Ball) -- so
%%                                   a check whose goal fails or throws is
%%                                   a FAIL line naming what happened, not
%%                                   the end of the case
%%   yes_no(+Goal, -YesOrNo)         the checks that ask a question
%%   written(+Goal, ?Template, -Atom) answer/3, then the value as write/1
%%                                   spells it -- for a pin the .sh made
%%                                   against a written term, kept byte for
%%                                   byte rather than re-guessed as a term
%%   section(+Title)                 the `-- ...' line between groups
%%   skip(+Why)                      prints `SKIP Why' and halts 0
%%   scratch(-Dir)                   a fresh directory for fixtures
%%   fixture(+Path, +Lines)          writes the lines, newline-terminated
%%   cocolog(-Path)                  the binary running this case
%%   cocolog_out(+Args, -Codes)      a child `cocolog ARGS' -- local unless
%%                                   ARGS say otherwise -- its stdout AND
%%                                   stderr, two minutes' grace
%%   cocolog_answer(+Args, -Term)    the child's `answer(...)' line read
%%                                   back as a term, or `none'
%%
%% A `SKIP' AT COLUMN 0 SKIPS THE WHOLE CASE -- run.sh greps for it, the
%% way CivV's does -- so a SECTION that cannot run says so indented:
%% `     (skipped: no python3 with numpy on the path)'. The line is still
%% in the case's output for whoever counts the skips.
%%
%% ISOLATION IS THE CASE'S OWN BUSINESS. The .sh suite got a clean slate
%% per check for free, by spawning; here a check that would leave state
%% behind -- a flag set, a clause asserted, a module registered -- either
%% puts it back or takes a child process on purpose, and says which.

:- use_module(library(process)).
:- use_module(library(text)).

answer(Goal, Template, Got) :-
    (   catch(Goal, Ball, Caught = caught(Ball))
    ->  (   nonvar(Caught) -> Caught = caught(B), Got = error(B)
        ;   Got = Template
        )
    ;   Got = failed
    ).

yes_no(Goal, YN) :-
    answer(Goal, yes, A),
    (   A == yes -> YN = yes
    ;   A == failed -> YN = no
    ;   YN = A
    ).

written(Goal, Template, Atom) :-
    answer(Goal, Template, Got),
    format(atom(Atom), "~w", [Got]).

section(Title) :- format("-- ~w~n", [Title]).

skip(Why) :- format("SKIP ~w~n", [Why]), halt(0).

scratch(Dir) :- tmp_file(cocolog_test, Dir), make_directory(Dir).

fixture(Path, Lines) :-
    atomic_list_concat(Lines, '\n', Body),
    atom_concat(Body, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(Path, Codes).

cocolog(C) :- current_prolog_flag(executable, C).

cocolog_out(Args, Out) :-
    cocolog(C),
    sh_join([C, ' ', Args, ' 2>&1'], Cmd),
    proc_run(Cmd, 120000, Out, _).

%% ONE LINE, not the rest of the transcript: libc's `.' matches a newline,
%% so `answer\(.*\)' ran on to the last `)' of the child's `1 answer(s).'
cocolog_answer(Args, Term) :-
    cocolog_out(Args, Out),
    (   re_first_atom('answer\\([^\n]*\\)', Out, A)
    ->  term_to_atom(Term, A)
    ;   Term = none
    ).
