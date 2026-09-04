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
%%   spawn(+Cmd, -Pid)               a server, exec'd so the pid IS it
%%   shell(+Cmd, -Text, -Exit)       /bin/sh -c Cmd: stdout as an atom, last
%%                                   newline off, and the exit status
%%   cocolog_run(+Args, -Text, -Exit) shell/3 over `cocolog ARGS'
%%   has(+Label, +Needle, +Text)     a check that Needle occurs in Text
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

%% ONE SLASH: macOS's TMPDIR ends in one, so tmp_file/2 answers `.../T//coco...'
%% -- a path that works and that no other program prints back that way
%% (swipl names files by their real path, and a check that strips the
%% scratch prefix from both outputs then strips only ours)
scratch(Dir) :-
    tmp_file(cocolog_test, Raw),
    re_replace_atom('//', '/', Raw, Dir),
    make_directory(Dir).

%% JOINED AS CODES, never as one atom: a fixture of a hundred CSV rows is
%% thirty kilobytes, and an atom that size is a buffer somewhere waiting
%% to be overrun
fixture(Path, Lines) :-
    findall(Cs, ( member(L, Lines), atom_codes(L, LCs), append(LCs, [10], Cs) ), Rows),
    append(Rows, Codes),
    write_file_from_codes(Path, Codes).

cocolog(C) :- current_prolog_flag(executable, C).

%% the checkout root, WITHOUT the trailing slash working_directory/2 answers
%% with: `ROOT/test/x' built on the raw answer is `.../cocolog//test/x', and
%% Cicili, handed such a target, put its output somewhere it did not then
%% find
root(Root) :-
    working_directory(Raw, Raw),
    (   atom_concat(Root, '/', Raw), Root \== '' -> true ; Root = Raw ).

cocolog_out(Args, Out) :-
    cocolog(C),
    sh_join([C, ' ', Args, ' 2>&1'], Cmd),
    proc_run(Cmd, 120000, Out, _).

%% spawn(+Cmd, -Pid): proc_spawn/2 with `exec' in front, for the ONE case a
%% test spawns -- a server it will stop again.
%%
%% THE PID MUST BE THE SERVER, NOT A SHELL THAT FORKED IT. proc_spawn runs
%% /bin/sh -c CMD, and this /bin/sh FORKS for a command carrying
%% redirections rather than execing it -- measured: proc_stop said `gone'
%% of the pid it was given while the port was still held, by a pid two
%% higher. The orphan goes on listening, and the next run of that case
%% meets its own port taken: the suite's first end-to-end run lost `tunnel'
%% and `zigurat-tls' that way, to servers a standalone run of the same two
%% cases had left behind an hour earlier. `exec' makes the shell replace
%% itself, so the pid proc_spawn answers is the thing to kill.
%%
%% ONLY FOR A SINGLE COMMAND. A shell LOOP cannot be exec'd, so a case that
%% spawns one (test/ruler.pl's queriers) keeps proc_spawn and lets the loop
%% end on its own.
spawn(Cmd, Pid) :- sh_join(['exec ', Cmd], Exec), proc_spawn(Exec, Pid).

%% shell(+Cmd, -Text, -Exit): /bin/sh -c Cmd with two minutes' grace, its
%% stdout (and whatever Cmd redirected into it) as an atom with the last
%% newline taken off -- what `$(...)' handed a .sh -- and the exit status,
%% never failed on. cocolog_run/3 is the same over `cocolog ARGS'.
shell(Cmd, Text, Exit) :-
    proc_run(Cmd, 120000, Out, Exit),
    chomp(Out, Body),
    atom_codes(Text, Body).

cocolog_run(Args, Text, Exit) :- cocolog_run(Args, Text, Exit, 120000).

%% the same with a ceiling of its own, for a child that trains: `timeout N'
%% cannot go in ARGS, since ARGS come after the binary
cocolog_run(Args, Text, Exit, Ms) :-
    cocolog(C),
    sh_join([C, ' ', Args], Cmd),
    proc_run(Cmd, Ms, Out, Exit),
    chomp(Out, Body),
    atom_codes(Text, Body).

%% answer_text(+Args, -Text): the .sh suites' `q()' -- a child `cocolog ARGS',
%% stderr dropped, and the inside of the first `answer(...)' on a line of
%% its own, greedy to that line's last `)'; '' when there is none
answer_text(Args, Text) :-
    cocolog(C),
    sh_join([C, ' ', Args, ' 2>/dev/null'], Cmd),
    proc_run(Cmd, 300000, Out, _),
    (   re_first_atom('answer\\([^\n]*\\)', Out, A)
    ->  sub_atom(A, 7, _, 1, Text)
    ;   Text = ''
    ).

%% maxdiff(+Text, -D): the largest |a - b| over two flat lists written as
%% `[a1,a2,...]/[b1,b2,...]' -- `/', because `-' is also a minus sign. A
%% text that is not that shape answers `inf', so a missing answer is off
%% by infinity rather than within anything.
maxdiff(Text, D) :-
    (   atomic_list_concat(Parts, '/', Text), Parts = [LA, LB],
        numbers_of(LA, As), numbers_of(LB, Bs),
        length(As, N), length(Bs, N)
    ->  findall(Ab, ( nth0(I, As, A), nth0(I, Bs, B), Ab is abs(A - B) ), Ds),
        max_list([0|Ds], D)
    ;   D = inf
    ).

numbers_of(Text, Ns) :-
    re_replace_atom('[][]', '', Text, Bare),
    atomic_list_concat(Parts, ',', Bare),
    findall(N, ( member(P, Parts), P \== '', atom_number(P, N) ), Ns).

%% has(+Label, +Needle, +Text): the .sh's `case "$3" in *"$2"*)' -- a
%% check that Needle occurs in Text, the FAIL line showing both
has(Label, Needle, Text) :-
    (   sub_atom(Text, _, _, _, Needle)
    ->  check(Label, found, found)
    ;   check(Label, Text, Needle)
    ).

%% ONE LINE, not the rest of the transcript: libc's `.' matches a newline,
%% so `answer\(.*\)' ran on to the last `)' of the child's `1 answer(s).'
cocolog_answer(Args, Term) :-
    cocolog_out(Args, Out),
    (   re_first_atom('answer\\([^\n]*\\)', Out, A)
    ->  term_to_atom(Term, A)
    ;   Term = none
    ).
