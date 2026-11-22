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
    green(D), red(D), thrown(D), missing(D), options_first(D), hooked(D),
    halted(D), halted_own(D), halted_swipl(D), at_halted(D),
    binary_verdicts,
    shl(['rm -rf ', D]),
    checks_done.

%% THE SUITE'S OTHER HALF READS ITS BINARIES THE SAME WAY (2.11.1): a
%% test/*.cicili binary's last line says GREEN or SKIP, and that counts only
%% when it also exited 0 -- `binary_verdict/3' in the prelude, which
%% test/run.pl asks. Through 2.11.0 the runner read the line alone, so a
%% binary that printed GREEN and then crashed on its way out was green. The
%% child here is a shell that does exactly that, so what is pinned is also
%% that a death by a signal reaches the verdict as a status that is not 0.
binary_verdicts :-
    section('a test binary is green only when it also exits 0'),
    binary_verdict('ok   one\nGREEN: 0 failure(s)', 0, V1),
    check('GREEN and exit 0 is green', V1, green),
    binary_verdict('ok   one\nGREEN: 0 failure(s)', 139, V2),
    check('GREEN and then a crash is red', V2, red),
    binary_verdict('SKIP no Zigurat server at 127.0.0.1:2160 (refused)', 0, V3),
    check('a SKIP that exits 0 skips', V3, skip),
    binary_verdict('SKIP no Zigurat server at 127.0.0.1:2160 (refused)', 1, V4),
    check('a SKIP that exits 1 is red', V4, red),
    binary_verdict('FAIL one\n\nRED: 1 failure(s)', 1, V5),
    check('RED is red', V5, red),
    shell('sh -c \'echo "GREEN: 0 failure(s)"; kill -SEGV $$\'', Out, Exit),
    binary_verdict(Out, Exit, V6),
    check('a child that says GREEN and dies by a signal is red', V6, red).

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
    check('a failed main exits 1 -- where query says 0', Rc, 1),
    %% AND SAYS SO AS SWIPL'S DOES (3.63.0): `swipl -g main -t halt' says
    %% `ERROR: -g main: false', and -q nothing, as `swipl -q''s; through
    %% 3.62.7 cocolog was always -q's
    sh_join(['-s ', F, ' 2>&1 >/dev/null'], Args1),
    cocolog_run(Args1, Err1, _),
    check('a failed main says so on stderr, as swipl''s -g', Err1, 'ERROR: -s main: false'),
    sh_join(['-q -s ', F, ' 2>&1 >/dev/null'], Args2),
    cocolog_run(Args2, Err2, Rc2),
    check('...and under -q says nothing, as swipl -q, and exits 1', Err2-Rc2, ''-1),
    sh_join(['run ', F, ' main 2>&1 >/dev/null'], Args3),
    cocolog_run(Args3, Err3, Rc3),
    check('run FILE GOAL names the goal asked, -g GOAL, as swipl''s', Err3-Rc3, 'ERROR: -g main: false'-1),
    sh_join(['--quiet run ', F, ' main 2>&1 >/dev/null'], Args4),
    cocolog_run(Args4, Err4, _),
    check('...and --quiet is -q', Err4, ''),
    cocolog_run('-q query "current_prolog_flag(verbose, V), write(V), nl" 2>/dev/null', Out5, _),
    has('-q is the verbose flag silent, as swipl -q''s', silent, Out5),
    atom_concat(D, '/halt1.pl', F6),
    fixture(F6, ['main :- halt(1).']),
    sh_join(['-s ', F6, ' 2>&1 >/dev/null'], Args6),
    cocolog_run(Args6, Err6, Rc6),
    check('a main that halts is no failure: halt(1) says nothing', Err6-Rc6, ''-1).

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

%% A SCRIPT'S OWN EXPANSION HOOKS ARE ASKED OF ITS CLAUSES (3.49.1), as
%% `swipl script.pl' asks them: the clauses after a goal_expansion/2 clause
%% are read with their goals rewritten, and term_expansion/2's terms are
%% read in the term's place. Through 3.49.0 the script's goal_expansion/2
%% was never asked: library(yall)'s clause, read at start-up, made the
%% predicate a library's, and the script, read as a module, gave it only
%% muted clauses, which counted where a program file gave the first. So
%% `t :- foo(1).' called foo/1, an unknown procedure, and the run threw.
hooked(D) :-
    section('a script''s goal_expansion/2 and term_expansion/2 are asked of it'),
    atom_concat(D, '/hooked.pl', F),
    fixture(F, ['goal_expansion(foo(X), bar(X)).',
                'term_expansion(gen(N), [num(N), num2(N)]).',
                'bar(X) :- write(bar(X)), nl.',
                'gen(7).',
                't :- foo(1).',
                'main :- t, num(N), num2(M), write(N-M), nl, clause(t, B), write(B), nl.']),
    sh_join(['-s ', F, ' 2>&1'], Args),
    cocolog_run(Args, Got, Rc),
    check('the script proves main', Rc, 0),
    check('foo(1) was read as bar(1), and gen(7) as its two facts', Got,
          'bar(1)\n7-7\nbar(1)'),
    %% and library(yall)'s clause of goal_expansion/2, read at start-up, is
    %% no hook: counted, every load would ask goal_expansion/2 of every goal
    atom_concat(D, '/nohook.pl', F2),
    fixture(F2, ['main :- predicate_property(goal_expansion(_, _), number_of_clauses(N)),',
                 '        \'$xhooks\'(T, G), write(N-T-G), nl.']),
    sh_join(['-s ', F2, ' 2>&1'], Args2),
    cocolog_run(Args2, Got2, _),
    check('yall''s clause is there, and a script with no hook has none', Got2, '1-0-0').

options_first(D) :-
    section('options before the flag still parse'),
    atom_concat(D, '/green.pl', F),
    sh_join(['--local -s ', F, ' 2>&1'], Args),
    cocolog_run(Args, Got, Rc),
    sh_join([Rc, '-', Got], Both),
    check('--local -s parses: the dash verb ends the options', Both, '0-hello').

%% A HALT IN A NESTED SEARCH IS THE PROCESS'S (3.57.0), as swipl's halt/1
%% ends the process from whatever C called Prolog: findall/3, forall/2,
%% aggregate_all/3 and what is built on them, with_output_to/2, `~@', a
%% portray goal, a cleanup a cut ran, a directive's search. Through 3.56.0
%% the halt ended the search alone -- findall/3 went on with the answers it
%% had, and the program exited 0 -- and failed with_output_to/2's and
%% `~@''s goal, exit 1. What swipl has put out before the end is put out:
%% the text a write or a format made before its goal halted, a portray
%% goal's own, a `~@' goal's where format holds no text for a column, and
%% never a capture's. Each check is a child, `run FILE "h(N)"' with its
%% stderr in its stdout, and what it wants is swipl 9.0.4's, under `swipl
%% -q -g "h(N)" -t halt FILE', which the last section asks of the reference
%% swipl where there is one.
halt_prog(['h(1) :- findall(X, (member(X, [1,2,3]), X >= 2, write(x(X)), nl, halt(3)), L), write(L), nl.',
           'h(2) :- forall(member(X, [1,2]), (write(X), nl, halt(4))), write(after), nl.',
           'h(3) :- aggregate_all(count, (member(_, [1,2]), halt(5)), C), write(C), nl.',
           'h(4) :- findall(Y, findall(X, (X = 1, halt(12)), Y), L), write(L), nl.',
           'h(5) :- catch(findall(_, halt(26), _), E, (write(caught(E)), nl)), write(after), nl.',
           'h(6) :- setup_call_cleanup(true, findall(_, halt(25), _), (write(cleanup), nl)), write(after), nl.',
           'h(7) :- setof(X, (member(X, [b,a]), halt(30)), L), write(L), nl.',
           'h(8) :- findall(_, setup_call_cleanup(true, member(_, [1,2]), (write(cl), halt(9))), _), write(after), nl.',
           'h(9) :- write(out1), with_output_to(string(_), (write(in), halt(28))).',
           'h(10) :- with_output_to(string(S), findall(_, (write(in), halt(27)), _)), write(S), nl.',
           'h(11) :- format("a~@b~n", [halt(7)]), write(after), nl.',
           'h(12) :- format("x~@y~n", [(write(in), halt(3))]).',
           'h(13) :- format("~a~t~@~10|~w~n", [ab, (write(in), halt(13)), cd]).',
           'h(14) :- format(atom(_), "~a~@", [ab, halt(14)]), write(after), nl.',
           'h(15) :- assertz((portray(x) :- halt(4))), print(f(a, x, b)), write(after), nl.',
           'h(16) :- assertz((portray(x) :- write(px), halt(5))), print([a, x]), write(after), nl.',
           'h(17) :- assertz((portray(x) :- print(g(y)))), assertz((portray(y) :- halt(6))), print(f(x)), write(after), nl.',
           'h(18) :- write(w1), assertz((portray(x) :- halt(6))), format("~w ~p ~w~n", [a, x, b]), write(after), nl.',
           'h(19) :- assertz((portray(x) :- write(px), halt(11))), print_message(error, format("~p", [x])), write(after), nl.',
           'h(20) :- with_output_to(string(S), setup_call_cleanup(true, member(_, [1,2]), (write(cl), halt(4)))), write(S), nl.',
           'h(21) :- setup_call_cleanup(true, member(_, [1,2]), (write(cl), halt(5))).',
           'h(22) :- setup_call_cleanup(true, setup_call_cleanup(true, member(_, [1,2]), (write(c1), halt(5))), (write(c2), halt(6))).',
           'c(1) :- call_limited((write(a), halt(5)), 100, R), write(R), nl.',
           'c(2) :- call_metered((write(b), halt(6)), 100, U, R), write(U-R), nl.']).

%% halt_want(N, What, Text, Status): h(N)'s, swipl 9.0.4's
halt_want(1, 'findall/3 ends at the halt, its answers unmade', 'x(2)', 3).
halt_want(2, 'forall/2''s action halts', '1', 4).
halt_want(3, 'aggregate_all/3''s count halts', '', 5).
halt_want(4, 'findall/3 inside findall/3', '', 12).
halt_want(5, 'catch/3 takes no halt from a findall/3', '', 26).
halt_want(6, 'and no cleanup runs for one', '', 25).
halt_want(7, 'setof/3, over findall/3', '', 30).
halt_want(8, 'a cleanup findall/3''s search ran halts', 'cl', 9).
halt_want(9, 'with_output_to/2''s goal halts: its text goes with it', 'out1', 28).
halt_want(10, 'a findall/3 in with_output_to/2''s goal', '', 27).
halt_want(11, '`~@'' halts: format''s text before it is out', 'a', 7).
halt_want(12, 'and the goal''s own, held for no column', 'xin', 3).
halt_want(13, 'a fill point holds both, and only format''s comes out', 'ab', 13).
halt_want(14, 'a term sink gets nothing', '', 14).
halt_want(15, 'a portray goal halts: print/1''s text before it is out', 'f(a,', 4).
halt_want(16, 'and the goal''s own', '[a,px', 5).
halt_want(17, 'a portray goal''s print/1 whose portray goal halts', 'f(g(', 6).
halt_want(18, 'format''s `~p'' of a portray goal that halts', 'w1a ', 6).
halt_want(19, 'print_message/2''s, its line on stderr', 'ERROR: px', 11).
halt_want(20, 'with_output_to/2''s cut runs a cleanup that halts', '', 4).
halt_want(21, 'the host''s cut of a goal that left a choice runs one', 'cl', 5).
halt_want(22, 'the first of two that halts ends it: the one below runs no more', 'c1', 5).

halt_file(D, F) :-
    atom_concat(D, '/halt.pl', F),
    halt_prog(Lines),
    fixture(F, [':- dynamic portray/1.'|Lines]).

halt_coco(F, Goal, Text, Status) :-
    sh_join(['--local run ', F, ' "', Goal, '" 2>&1'], Args),
    cocolog_run(Args, Text, Status).

halted(D) :-
    section('a halt in a nested search ends the process, as swipl''s'),
    halt_file(D, F),
    forall(halt_want(N, What, Want, Rc),
           ( format(atom(Goal), 'h(~w)', [N]),
             halt_coco(F, Goal, Got, GotRc),
             format(atom(Label), 'h(~w): ~w', [N, What]),
             check(Label, Got-GotRc, Want-Rc) )).

%% cocolog's own: call_limited/3 and call_metered/4, which swipl has not,
%% and the toplevel, whose cut of an answer taken runs a cleanup; and a
%% directive's findall/3, which ends the load and its process
halted_own(D) :-
    section('call_limited/3, call_metered/4, the toplevel and a load'),
    halt_file(D, F),
    halt_coco(F, 'c(1)', Got1, Rc1),
    check('call_limited/3''s goal halts', Got1-Rc1, a-5),
    halt_coco(F, 'c(2)', Got2, Rc2),
    check('call_metered/4''s goal halts', Got2-Rc2, b-6),
    cocolog(C),
    sh_join(['printf ''setup_call_cleanup(true, member(_, [1,2]), (write(cl), halt(5))).\\nwrite(next).\\n'' | ',
             C, ' --local 2>&1'], Repl),
    shell(Repl, Got3, Rc3),
    check('the toplevel''s cut of an answer runs a cleanup that halts: the session ends with its code',
          Got3-Rc3, 'true .\ncl'-5),
    atom_concat(D, '/halt_load.pl', L),
    fixture(L, [':- findall(_, halt(3), _).', 'never :- true.']),
    halt_coco(L, 'write(ran)', Got4, Rc4),
    check('a directive''s findall/3 halts: the load ends, and the process', Got4-Rc4, ''-3).

%% THE WANTS ARE THE REFERENCE'S: each h(N) asked of swipl 9.0.4, where
%% there is one (`SWIPL' may name it), as test/files.pl asks it
halted_swipl(D) :-
    section('... and the wants are swipl 9.0.4''s'),
    (   halt_swipl(Swi)
    ->  halt_file(D, F),
        forall(halt_want(N, What, Want, Rc),
               ( format(atom(Cmd), '~w -q -g "h(~w)" -t halt ~w 2>&1', [Swi, N, F]),
                 shell(Cmd, Got, GotRc),
                 format(atom(Label), 'swipl''s h(~w): ~w', [N, What]),
                 check(Label, Got-GotRc, Want-Rc) )),
        atom_concat(D, '/halt_load.pl', L),
        format(atom(Cmd5), '~w -q -g "write(ran)" -t halt ~w 2>&1', [Swi, L]),
        shell(Cmd5, Got5, Rc5),
        check('swipl''s load of the directive', Got5-Rc5, ''-3)
    ;   format("   SKIP (no reference swipl 9.0.4 here)~n", [])
    ).

%% THE at_halt/1 HOOKS RUN AT EACH END A PROCESS HAS (3.71.0): swipl runs
%% them at halt/0,1 and at its toplevel's end, which test/files/at_halt.pl
%% holds to it, and cocolog's hosts end in more ways -- -s, run, query, the
%% REPL, a load that halts or whose initialization(main, main) does -- each
%% running what is left with the status the process ends with in
%% exit_status, after the line that says a goal failed or threw and before
%% the store's commit, so that what a hook writes is kept. A cancel at the
%% program's end is said and not honoured, where swipl's toplevel asks again
%% (COMPAT.md); a thread's share is test/thread.pl's
at_halted(D) :-
    section('the at_halt/1 hooks at each end of a process'),
    atom_concat(D, '/ah_s.pl', F1),
    fixture(F1, [':- at_halt((write(bye), nl)).', 'main :- write(main), nl.']),
    sh_join(['-s ', F1, ' 2>&1'], A1),
    cocolog_run(A1, Got1, Rc1),
    check('-s: a directive''s hook runs after main', Got1-Rc1, 'main\nbye'-0),
    atom_concat(D, '/ah_st.pl', F2),
    fixture(F2, ['st :- current_prolog_flag(exit_status, S), write(status(S)), nl.',
                 'main :- at_halt(st), fail.']),
    sh_join(['-s ', F2, ' 2>&1'], A2),
    cocolog_run(A2, Got2, Rc2),
    check('a failed main: its line, then the hooks, exit_status 1', Got2-Rc2,
          'ERROR: -s main: false\nstatus(1)'-1),
    atom_concat(D, '/ah_th.pl', F3),
    fixture(F3, ['st :- current_prolog_flag(exit_status, S), write(status(S)), nl.',
                 'main :- at_halt(st), throw(oops).']),
    sh_join(['-s ', F3, ' 2>/dev/null'], A3),
    cocolog_run(A3, Got3, Rc3),
    check('a main that threw: exit_status 2', Got3-Rc3, 'status(2)'-2),
    atom_concat(D, '/ah_ok.pl', F4),
    fixture(F4, ['st :- current_prolog_flag(exit_status, S), write(status(S)), nl.',
                 'main :- at_halt(st), write(ok), nl.']),
    sh_join(['run ', F4, ' main 2>&1'], A4),
    cocolog_run(A4, Got4, Rc4),
    check('run FILE GOAL: after the goal, exit_status 0', Got4-Rc4, 'ok\nstatus(0)'-0),
    atom_concat(D, '/ah_cf.pl', F15),
    fixture(F15, [':- at_halt((write(consult_hook), nl)).', 'cf(1).']),
    sh_join(['consult ', F15, ' 2>&1'], A15),
    cocolog_run(A15, Got15, Rc15),
    check('consult FILE: after its report, which its commit made true', Got15-Rc15,
          'consulted 1 clause(s) into ''main''\nconsult_hook'-0),
    cocolog_run('query "at_halt((write(q_bye), nl))" 2>&1', Got5, Rc5),
    check('query: after the count of its answers', Got5-Rc5,
          '  1. at_halt((write(q_bye),nl))\n1 answer(s).\nq_bye'-0),
    cocolog(C),
    sh_join(['printf ''at_halt((write(r_bye), nl)).\\n'' | ', C, ' --local 2>&1'], R6),
    shell(R6, Got6, Rc6),
    check('the REPL: at the end of its input', Got6-Rc6, 'true.\nr_bye'-0),
    sh_join(['printf ''at_halt((write(r2), nl)).\\nhalt(6).\\n'' | ', C, ' --local 2>&1'], R7),
    shell(R7, Got7, Rc7),
    check('...and at its halt(6), the session ending 6', Got7-Rc7, 'true.\nr2'-6),
    atom_concat(D, '/ah_im.pl', F8),
    fixture(F8, [':- initialization(main, main).',
                 'main :- at_halt((write(init_main_hook), nl)), write(m), nl.']),
    sh_join(['run ', F8, ' true 2>&1'], A8),
    cocolog_run(A8, Got8, Rc8),
    check('a load''s initialization(main, main): its halt runs them', Got8-Rc8,
          'm\ninit_main_hook'-0),
    atom_concat(D, '/ah_dh.pl', F9),
    fixture(F9, [':- at_halt((write(load_hook), nl)).', ':- halt(4).', 'never.']),
    sh_join(['-s ', F9, ' 2>&1'], A9),
    cocolog_run(A9, Got9, Rc9),
    check('a directive''s halt(4) runs them and ends the load, and the process',
          Got9-Rc9, 'load_hook'-4),
    atom_concat(D, '/ah_ce.pl', F10),
    fixture(F10, ['main :- at_halt(cancel_halt(no)), at_halt((write(after_cancel), nl)), write(main), nl.']),
    sh_join(['-s ', F10, ' 2>/dev/null'], A10),
    cocolog_run(A10, Got10, Rc10),
    check('a cancel at the program''s end: the hooks before it run, and it ends 0',
          Got10-Rc10, 'main\nafter_cancel'-0),
    sh_join(['-s ', F10, ' 2>&1 >/dev/null'], A11),
    cocolog_run(A11, Got11, _),
    check('...the cancel said, informational, and not honoured', Got11, '% Halt cancelled: no'),
    atom_concat(D, '/ah_cu.pl', F12),
    fixture(F12, ['main :- cancel_halt(x).']),
    sh_join(['--no-backtrace -s ', F12, ' 2>&1'], A12),
    cocolog_run(A12, Got12, Rc12),
    check('cancel_halt/1 uncaught is an error, said as swipl''s -g says it', Got12-Rc12,
          'ERROR: -s main: Halt cancelled: x'-2),
    atom_concat(D, '/ah_tr.pl', F16),
    fixture(F16, ['w :- write(hook), nl.', 'main :- at_halt(w), write(m), nl.']),
    sh_join(['--trace -s ', F16, ' 2>&1'], A16),
    cocolog_run(A16, Got16, _),
    ( sub_atom(Got16, _, _, _, ') w\n') -> Traced16 = traced ; Traced16 = untraced ),
    check('the hooks run untraced, as swipl''s run them in debugmode(false)', Traced16, untraced),
    has('...and they run', hook, Got16),
    atom_concat(D, '/ah_kb.pl', F13),
    atom_concat(D, '/ah_kb', KB),
    fixture(F13, [':- dynamic seen/1.', 'main :- at_halt(assertz(seen(from_hook))), write(main), nl.']),
    sh_join(['--embed ', KB, ' -s ', F13, ' 2>&1'], A13),
    cocolog_run(A13, Got13, Rc13),
    check('-s over a store: a hook asserts', Got13-Rc13, main-0),
    sh_join(['--embed ', KB, ' query "seen(X)" 2>&1'], A14),
    cocolog_run(A14, Got14, _),
    check('...and a second process reads it: the commit came after the hooks', Got14,
          '  1. seen(from_hook)\n1 answer(s).'),
    atom_concat(D, '/ah_ck.pl', F17),
    atom_concat(D, '/ah_ck', KB17),
    fixture(F17, [':- dynamic seen2/1.', ':- at_halt(assertz(seen2(from_consult_hook))).', 'ck(1).']),
    sh_join(['--embed ', KB17, ' consult ', F17, ' 2>&1'], A17),
    cocolog_run(A17, Got17, Rc17),
    check('consult FILE over a store: a hook asserts', Got17-Rc17,
          'consulted 1 clause(s) into ''main'''-0),
    sh_join(['--embed ', KB17, ' query "seen2(X)" 2>&1'], A18),
    cocolog_run(A18, Got18, _),
    check('...and a second process reads it: a commit of its own after the hooks', Got18,
          '  1. seen2(from_consult_hook)\n1 answer(s).').

halt_swipl(Swi) :-
    ( getenv('SWIPL', Swi) -> true ; Swi = swipl ),
    sh_join([Swi, ' --version 2>/dev/null'], Cmd),
    shell(Cmd, Ver, 0),
    sub_atom(Ver, _, _, _, ' version 9.0.4 ').
