%% modules/process/process.cicili -- run, capture, spawn, wait, kill.
%%
%% WHAT IS BEING PINNED:
%%
%%   A TIMEOUT KILLS AND ANSWERS 124, coreutils' own number, with the
%%   partial output kept -- a timed-out test's half-log is the
%%   diagnosis, and a suite that hangs is the one outcome with no
%%   information in it.
%%
%%   OUTPUT CARRIES EVERY BYTE. Codes, not an atom -- an atom stops at
%%   the first NUL and a captured log is exactly the text that carries
%%   one. The test pushes a NUL through and counts.
%%
%%   A SPAWNED CHILD HAS ITS OWN SESSION and dies on proc_stop/1 --
%%   fifteen first, nine after -- leaving no zombie, which proc_wait
%%   inside proc_stop is for.
%%
%%   THE CHECK HARNESS TELLS THE TRUTH: check/3 says ok or FAIL and
%%   remembers; checks_done says GREEN or RED and FAILS on red, so a
%%   .pl suite's exit status carries its verdict -- this file's own
%%   verdict among them.
%%
%%   AND ACROSS PROCESSES, the only version worth making here: one
%%   cocolog runs ANOTHER cocolog through sh/2 and reads its answer --
%%   the exact choreography every .sh suite in this family performed,
%%   and every .pl case in test/ performs now.
%%
%%     cocolog -s test/process.pl        from the checkout root
%%
%% ONE PROCESS FOR SEVEN CHECKS. This is the module every other .pl case
%% stands on, so this case is the one that holds the ruler to the ruler
%% (test/text.pl is the other).

:- use_module('test/prelude.pl').

main :-
    (   catch(proc_sleep(1), _, fail)
    ->  true
    ;   skip('(library(process) will not load -- sh modules/process/build.sh)')
    ),
    run_and_capture, spawn_watch_stop, harness_and_choreography,
    checks_done.

run_and_capture :-
    section('run and capture'),
    written(( sh_atom('printf hello', A1), sh_exit('exit 7', E1),
              ( sh('false') -> F1 = ran ; F1 = refused ) ), A1-E1-F1, G1),
    check('sh/2 captures, sh_exit/2 reports, sh/1 demands zero', G1, 'hello-7-refused'),
    written(( proc_run('echo kept; sleep 30', 500, Out2, E2), atom_codes(A2, Out2),
              ( A2 == 'kept\n' -> K2 = kept ; K2 = lost ) ), E2-K2, G2),
    check('a timeout kills the group and answers 124, output kept', G2, '124-kept'),
    written(( proc_run('head -c 3 /dev/zero', 5000, Out3, 0),
              ( Out3 == [0, 0, 0] -> R3 = nuls ; R3 = Out3 ) ), R3, G3),
    check('every byte crosses, NUL included', G3, nuls).

spawn_watch_stop :-
    section('spawn, watch, stop'),
    written(( proc_spawn('sleep 30', P1), ( proc_running(P1) -> R1a = up ; R1a = down ),
              proc_stop(P1), ( proc_running(P1) -> R1b = up ; R1b = down ) ), R1a-R1b, G1),
    check('a spawned child lives, is stopped, and is gone', G1, 'up-down'),
    written(( proc_spawn('sleep 1', P2),
              ( proc_until(proc_wait(P2, 0, _), 5000, 100) -> R2 = ended ; R2 = still ) ), R2, G2),
    check('proc_until polls a condition to its answer', G2, ended).

harness_and_choreography :-
    section('the harness, and the choreography across processes'),
    %% the deliberate red is TAKEN BACK afterwards -- this case's own
    %% checks_done reads the same counter
    check(good, x, x), check(bad, x, y),
    ( checks_done -> V1 = green ; V1 = red ),
    retractall('$check_failed'(bad)),
    check('check/3 remembers and checks_done says RED by failing', V1, red),
    cocolog(C),
    sh_join(['"', C, '" query "X is 6*7, write(X), nl" 2>/dev/null | head -1'], Cmd),
    written(( sh(Cmd, Cs2), append(D2, [10], Cs2), atom_codes(A2, D2) ), A2, G2),
    check('one cocolog runs another and reads its answer', G2, '42').
