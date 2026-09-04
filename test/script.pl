%% `-s SCRIPT': load a script as a module, prove main, and SAY SO IN THE
%% EXIT CODE.
%%
%% WHY THE FLAG EXISTS when `query "use_module('f'), main"` already runs
%% a file: `query` answers 0 for "the engine ran", so a goal that merely
%% FAILED -- a red test suite, say -- exits 0 and every shell driver above
%% it must grep the transcript for a verdict line. `-s' is the same load
%% with the honest exit: 0 exactly when `main' PROVED, 1 when it failed,
%% raised, or the file would not consult. A test case in cocolog is then
%% `cocolog -s test/case.pl` and the exit code IS the verdict -- which is
%% what this very file stands on.
%%
%% The one syntactic wrinkle is pinned here too: `-s' begins with a dash
%% and is a COMMAND, chosen to read as every interpreter's script flag,
%% so the option loop must hand it through rather than die on it as an
%% unknown option -- with options before it still parsed (`--local -s f').
%%
%%     cocolog -s test/script.pl        from the checkout root
%%
%% Every check here IS a child: what is pinned is a process's exit status.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    green(D), red(D), thrown(D), missing(D), options_first(D),
    shl(['rm -rf ', D]),
    checks_done.

green(D) :-
    section('a green main: the output is the script''s, the exit is 0'),
    atom_concat(D, '/green.pl', F),
    fixture(F, ['greeting(hello).', 'main :- greeting(G), write(G), nl.']),
    sh_join(['-s ', F, ' 2>&1'], Args),
    cocolog_run(Args, Got, Rc),
    check('a proved main exits 0', Rc, 0),
    check('and the output is the script''s own', Got, hello).

red(D) :-
    section('a red main: PLAIN FAILURE is exit 1, the fix over `query'''),
    atom_concat(D, '/red.pl', F),
    fixture(F, ['main :- 1 =:= 2.']),
    sh_join(['-s ', F, ' >/dev/null 2>&1'], Args),
    cocolog_run(Args, _, Rc),
    check('a failed main exits 1 -- where query says 0', Rc, 1).

thrown(D) :-
    section('an exception is 2, said on stderr'),
    atom_concat(D, '/throw.pl', F),
    fixture(F, ['main :- throw(sorrow).']),
    %% TWO, NOT ONE, and it is SWI's two: `swipl -q -g main -t halt' answers
    %% 0 proved, 1 failed and 2 threw, so a caller can tell the goal that
    %% said no from the goal that broke. This used to be 1 either way.
    sh_join(['-s ', F, ' 2>&1 >/dev/null'], Args),
    cocolog_run(Args, Err, Rc),
    check('an uncaught exception exits 2, as swipl does', Rc, 2),
    has('and names the ball on stderr', sorrow, Err).

missing(D) :-
    section('a file that is not there, and a missing argument'),
    atom_concat(D, '/nosuch.pl', F),
    sh_join(['-s ', F, ' >/dev/null 2>&1'], Args1),
    cocolog_run(Args1, _, Rc1),
    check('a missing file exits 1', Rc1, 1),
    cocolog_run('-s >/dev/null 2>&1', _, Rc2),
    check('-s with no file exits 1', Rc2, 1).

options_first(D) :-
    section('options before the flag still parse'),
    atom_concat(D, '/green.pl', F),
    sh_join(['--local -s ', F, ' 2>&1'], Args),
    cocolog_run(Args, Got, Rc),
    sh_join([Rc, '-', Got], Both),
    check('--local -s parses: the dash verb ends the options', Both, '0-hello').
