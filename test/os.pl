%% library(os) -- which system, who am I, how many cores, the environment,
%% where a tool is: the questions every suite used to ask a shell.
%%
%% WHAT IS CHECKED, and why it is checkable at all: nearly everything here
%% is a fact the shell can also state, so each answer is held against the
%% shell's own -- `uname -s', `id -u', `hostname', `$HOME' -- and the two
%% must agree. That is the whole promise: a script that asks library(os)
%% gets what it would have got by shelling out, on either system, without
%% the shell. The platform branch is pinned to what THIS machine is, so the
%% same file is green on Linux and on macOS and says which it ran on.
%%
%%     cocolog -s test/os.pl        from the checkout root
%%
%% ONE PROCESS FOR TWENTY-THREE CHECKS, where test/os.sh spawned one per
%% check (5.0 s on this machine). The shell's own answers still come from
%% the shell -- that is the point -- through library(process), which is a
%% fork each but no interpreter start-up; the one check that needs a
%% VARIABLE IN A CHILD'S ENVIRONMENT still runs a child cocolog.

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(os)), _, fail)
    ->  true
    ;   skip('(no library/os.so -- sh modules/os/build.sh)')
    ),
    which_system, who_am_i, environment, a_tool, two_names,
    checks_done.

which_system :-
    section('which system, held to uname'),
    shl_atom(['uname -s | tr A-Z a-z'], Sys),
    written(os_name(N1), N1, G1),
    check('os_name is uname -s, folded', G1, Sys),
    written(( os_is(Sys) -> W2 = here ; W2 = elsewhere ), W2, G2),
    check('and os_is branches on it', G2, here),
    shl_atom(['uname -m'], Arch),
    written(os_arch(M3), M3, G3),
    check('os_arch is uname -m', G3, Arch),
    shl_atom(['uname -r'], Rel),
    written(os_uname(_, _, R4, _, _), R4, G4),
    check('the five-field uname carries the release', G4, Rel),
    shl_atom(['hostname'], Host),
    written(os_hostname(H5), H5, G5),
    check('os_hostname is hostname', G5, Host).

who_am_i :-
    section('who am I, held to id'),
    shl_atom(['id -u'], Uid),
    written(os_uid(U1), U1, G1),
    check('os_uid is id -u', G1, Uid),
    shl_atom(['id -g'], Gid),
    written(os_gid(G2v), G2v, G2),
    check('os_gid is id -g', G2, Gid),
    written(( os_pid(P3), os_ppid(PP3),
              ( P3 > 1, PP3 > 0, P3 =\= PP3 -> W3 = distinct ; W3 = P3-PP3 ) ), W3, G3),
    check('os_pid is a live process, and not its parent', G3, distinct),
    written(( os_cpus(N4), ( integer(N4), N4 >= 1 -> W4 = ok ; W4 = N4 ) ), W4, G4),
    check('os_cpus is at least one, and an integer', G4, ok).

environment :-
    section('the environment'),
    shl_atom(['echo "$HOME"'], Home),
    written(os_home(H1), H1, G1),
    check('os_home is $HOME', G1, Home),
    written(( ( os_env('COCOLOG_NO_SUCH_VAR', _) -> A2 = set ; A2 = unset ),
              os_env('COCOLOG_NO_SUCH_VAR', D2, fallback) ), A2-D2, G2),
    check('os_env fails on an unset name, os_env/3 answers the default', G2, 'unset-fallback'),
    written(( os_environ(Ps3), memberchk('HOME'-H3, Ps3) ), H3, G3),
    check('os_environ lists every NAME-Value pair, HOME among them', G3, Home),
    %% A value may carry `=' of its own; the split is on the FIRST one. The
    %% variable has to be in the CHILD's environment before it starts, so
    %% this one is a child cocolog under an env the shell set.
    cocolog(C),
    shl_atom(['COCOLOG_OS_EQ=''a=b=c'' timeout 60 ', C,
              ' query "use_module(library(os)), os_environ(Ps), memberchk(''COCOLOG_OS_EQ''-V, Ps), write(answer(V)), nl" 2>/dev/null | grep -aE ''^answer'' | sed ''s/^answer(//; s/)$//'''], G4),
    check('a value with an equals sign in it survives the split', G4, 'a=b=c'),
    written(( os_setenv('COCOLOG_OS_PROBE', 'from-prolog'), os_env('COCOLOG_OS_PROBE', V5),
              os_unsetenv('COCOLOG_OS_PROBE'),
              ( os_env('COCOLOG_OS_PROBE', _) -> W5 = still ; W5 = gone ) ), V5-W5, G5),
    check('os_setenv is seen by os_env and by a child; os_unsetenv takes it back', G5, 'from-prolog-gone'),
    %% macOS's TMPDIR ends in a slash; a path joined onto it would carry `//'.
    written(( os_tmp(T6), ( atom_concat(_, '/', T6) -> W6 = slash ; W6 = clean ) ), W6, G6),
    check('os_tmp has no trailing slash', G6, clean),
    shl_atom(['echo "$PATH" | tr : "\\n" | wc -l | tr -d " "'], PathN),
    written(( os_path(Ds7), length(Ds7, N7) ), N7, G7),
    check('os_path is PATH, split', G7, PathN).

a_tool :-
    section('a tool, found without a shell'),
    shl_atom(['command -v sh'], Sh),
    written(os_which(sh, P1), P1, G1),
    check('os_which finds sh where command -v does', G1, Sh),
    written(os_which('/bin/sh', P2), P2, G2),
    check('an absolute name is answered as itself, if executable', G2, '/bin/sh'),
    written(( os_has(cocolog_no_such_tool_x) -> W3 = found ; W3 = absent ), W3, G3),
    check('a tool that is not there fails, and os_has says so', G3, absent),
    written(( findall(P4, os_which(sh, P4), Ps4), length(Ps4, N4) ), N4, G4),
    check('os_which is deterministic: one answer, no choice point left', G4, '1').

two_names :-
    section('the two names that differ between the systems'),
    shl_atom(['uname -s | tr A-Z a-z'], Sys),
    ( Sys == darwin -> WantLib = 'DYLD_LIBRARY_PATH' ; WantLib = 'LD_LIBRARY_PATH' ),
    written(os_lib_path_var(V1), V1, G1),
    check('os_lib_path_var names this system''s linker variable', G1, WantLib),
    shl_atom(['command -v setsid >/dev/null 2>&1 && echo 7 || echo 0'], WantLen),
    written(( os_setsid_prefix(P2), atom_length(P2, L2) ), L2, G2),
    check('os_setsid_prefix is ''setsid '' exactly where setsid exists', G2, WantLen),
    written(( os_describe(D3), ( sub_atom(D3, _, _, 0, ' cpus') -> W3 = shaped ; W3 = D3 ) ), W3, G3),
    check('os_describe is one line naming system, arch and cpus', G3, shaped).
