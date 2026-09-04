%% The toplevel, piped: bare `cocolog` with goals on stdin.
%%
%% WHAT IT IS CHECKING, and why each part is there:
%%
%%   ANSWERS WEAR THE QUERY'S OWN NAMES. `X = 41 + 1, Y is X.` answers
%%   `X = 41+1, Y = 42.` -- the reader's variable-name table survives into
%%   the printing, which is the one thing `query` (whose machine may have
%%   been thawed from a store that never had the names) cannot promise.
%%
%%   THE ALIAS RULES ARE SWI'S, taken from a live SWI toplevel and held to:
%%   a still-unbound shared cell is named for the LAST variable standing on
%%   it (`X = Y.` answers `X = Y.`; `f(A,B) = f(B,A).` answers `A = B.`),
%%   a value shows the name and not the writer's `_G` cell (`X = f(Z), Y =
%%   Z.` answers `X = f(Y), Z = Y.`), and a `_'-named variable names cells
%%   without ever getting a line (`X = f(_Q).` answers `X = f(_Q).`).
%%
%%   THE PUNCTUATION IS HONEST. A determinate answer ends `.` with nobody
%%   asked; one that left a choice point waits for `;`, and the `;` a
%%   terminal would have echoed is restored to piped output, so `member`
%%   reads `X = a ;` `X = b ;` `false.`
%%
%%   ONE SESSION IS ONE WORLD. What a goal asserts or consults, the next
%%   goal sees; a syntax error costs the goal and not the session; `halt.`
%%   leaves with 0.
%%
%%   THE STORE ARRANGEMENTS ARE THE SAME TOPLEVEL. Against the embedded
%%   store and the server, a piped session's writes must be read by a
%%   SECOND process that consulted nothing -- the claim the project exists
%%   to make. The wire half is skipped without a server.
%%
%%     cocolog -s test/repl.pl        from the checkout root
%%
%% Every check IS a child: a toplevel is a process on a pipe.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    local(D), terminal(D), embed(D), wire,
    shl(['rm -rf ', D]),
    checks_done.

%% `printf INPUT | cocolog 2>/dev/null', as text. INPUT is the printf
%% format the .sh used, escapes and all, inside single quotes.
piped(Input, Got) :- piped(Input, '', Got).
piped(Input, Args, Got) :-
    cocolog(C),
    sh_join(['printf ''', Input, ''' | ', C, ' ', Args, ' 2>/dev/null'], Cmd),
    shell(Cmd, Got, _).

local(D) :-
    section('local: names, aliases, punctuation, the session'),
    piped('X = 41 + 1, Y is X.\\n', G1),
    check('names survive into the answer', G1, 'X = 41+1,\nY = 42.'),
    piped('member(X, [a,b]).\\n;\\n;\\n', G2),
    check('; asks again, the echo restored, false closes', G2, 'X = a ;\nX = b ;\nfalse.'),
    piped('true.\\n', G3),
    check('no variables says true', G3, 'true.'),
    piped('fail.\\n', G4),
    check('no solutions says false', G4, 'false.'),
    piped('X = Y.\\n', G5),
    check('a shared cell is named for its last variable', G5, 'X = Y.'),
    piped('X = f(Z), Y = Z.\\n', G6),
    check('a value shows the name, not the _G cell', G6, 'X = f(Y),\nZ = Y.'),
    piped('f(A,B) = f(B,A).\\n', G7),
    check('swapped pairs collapse as SWI collapses them', G7, 'A = B.'),
    piped('X = f(_Q).\\n', G8),
    check('_named variables name cells but get no line', G8, 'X = f(_Q).'),
    piped('_ = 1.\\n', G9),
    check('a binding all underscores is just true', G9, 'true.'),
    piped('X =\\n[a,\\nb].\\n', G10),
    check('a goal is read to its full stop, lines apart', G10, 'X = [a,b].'),
    piped('foo(.\\nX = ok.\\n', G11),
    check('a syntax error costs the goal, not the session', G11, 'X = ok.'),
    piped('mystery(9).\\nX = still_here.\\n', G12),
    check('an unknown procedure costs the goal, not the session', G12, 'X = still_here.'),
    %% THE BALL AS A SENTENCE, not as a term. The toplevel used to print
    %% `uncaught exception: error(existence_error(procedure, mystery/1),
    %% _G12)' and now prints what SWI prints -- `Unknown procedure:
    %% mystery/1' -- so what is checked here is the name and arity, which is
    %% the part a person reads either way.
    cocolog(C),
    sh_join(['printf ''mystery(9).\\n'' | ', C, ' 2>&1 >/dev/null'], Cmd13),
    shell(Cmd13, G13, _),
    has('and names the unknown procedure on stderr', 'Unknown procedure: mystery/1', G13),
    %% fact/1's second answer is determinate -- the store knows its last
    %% clause -- so it closes with `.' where member/2, whose alternatives
    %% live in a recursive clause body, waits a third time and closes with
    %% false
    piped('assertz(fact(one)).\\nassertz(fact(two)).\\nfact(X).\\n;\\n', G14),
    check('what one goal asserts the next goal sees', G14, 'true.\ntrue.\nX = one ;\nX = two.'),
    %% retract respects the body (the shorthand IS (H :- true), so a
    %% same-headed rule survives a fact's retract -- kb.cicili, a CivV
    %% capture's finding) while retractall keeps SWI's wider head-only
    %% contract and takes the rule too. The transcript is a live SWI's.
    piped('assertz(f(a)), assertz((f(X) :- X == b)), assertz(f(c)).\\nretract(f(a)).\\nf(b), !.\\nf(a).\\nretractall(f(_)).\\nf(b).\\n', G15),
    check('retract minds the body; retractall removes rules too', G15, 'true.\ntrue.\ntrue.\nfalse.\ntrue.\nfalse.'),
    atom_concat(D, '/fam.pl', Fam),
    fixture(Fam, ['p(1).', 'p(2).', 'q(X) :- p(X), X > 1.']),
    %% the goals from a FILE this time: a path in quotes inside printf's
    %% quotes is the kind of thing a shell suite spends its evenings on
    atom_concat(D, '/goals.txt', Goals),
    sh_join(['[''', D, '/fam''].'], Load16),
    sh_join(['consult(''', D, '/fam.pl'').'], Consult16),
    fixture(Goals, [Load16, 'q(X).', Consult16]),
    sh_join([C, ' < ', Goals, ' 2>/dev/null'], Cmd16),
    shell(Cmd16, G16, _),
    check('[file] and consult(file), .pl found for itself', G16, 'true.\nX = 2.\ntrue.'),
    sh_join(['printf ''halt.\\n'' | ', C, ' >/dev/null 2>&1'], Cmd17),
    shell(Cmd17, _, Rc17),
    check('halt. leaves with 0', Rc17, 0).

terminal(D) :-
    section('the terminal: the line editor and the history'),
    %% Through a pseudo-terminal from script(1), so isatty is true and the
    %% editor runs; the editing is proven by what the READER got -- an answer
    %% can only say `X = 1.' if the backspaces really deleted -- and the
    %% history by a second session recalling the first one's goal with C-p.
    (   sh_exit('command -v script >/dev/null 2>&1 && script -qec true /dev/null >/dev/null 2>&1', 0)
    ->  cocolog(C),
        atom_concat(D, '/hist', H), make_directory(H),
        sh_join(['printf ''X = abcX\\b\\b\\b\\b1.\\nhalt.\\n'' | HOME=', H, ' script -qec "', C, '" /dev/null | tr -d ''\\r'' | grep -c ''^X = 1\\.$'''], Cmd1),
        shell(Cmd1, G1, _),
        check('tty: backspace edits the line the reader gets', G1, '1'),
        sh_join(['printf ''X = 13\\033[D2\\005.\\nhalt.\\n'' | HOME=', H, ' script -qec "', C, '" /dev/null | tr -d ''\\r'' | grep -c ''^X = 123\\.$'''], Cmd2),
        shell(Cmd2, G2, _),
        check('tty: left arrow inserts, C-e goes to the end', G2, '1'),
        sh_join(['grep -c ''^X = 1\\.$'' ', H, '/.cocolog_history 2>/dev/null'], Cmd3),
        shell(Cmd3, G3, _),
        check('tty: the goal as edited lands in the history file', G3, '1'),
        atom_concat(D, '/hist2', H2), make_directory(H2),
        sh_join(['printf ''X = recall_probe.\\nhalt.\\n'' | HOME=', H2, ' script -qec "', C, '" /dev/null >/dev/null 2>&1'], Cmd4a),
        shell(Cmd4a, _, _),
        sh_join(['printf ''\\020\\020\\n'' | HOME=', H2, ' script -qec "', C, '" /dev/null | tr -d ''\\r'' | grep -c ''^X = recall_probe\\.$'''], Cmd4),
        shell(Cmd4, G4, _),
        check('tty: C-p recalls a previous session''s goal', G4, '1')
    ;   format("     (skipped: tty -- no script(1) for a pseudo-terminal)~n", [])
    ).

embed(D) :-
    section('embed: a piped session writes, a second process reads'),
    atom_concat(D, '/KB', KB),
    sh_join(['--embed ', KB, ' --kb repl_test >/dev/null'], Args1),
    piped('assertz(kept(embed_round_trip)).\\nhalt.\\n', Args1, _),
    sh_join(['--embed ', KB, ' --kb repl_test query ''kept(X)'' 2>/dev/null | head -1'], Args2),
    cocolog_run(Args2, G2, _),
    check('embed: the session''s assert reaches a second process', G2, '  1. kept(embed_round_trip)').

wire :-
    section('wire: the same, through a server'),
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    cocolog(C),
    sh_join(['--kb repl_test --host ', Host, ' --tcp ', Port, ' --timeout 10'], W),
    sh_join(['timeout 20 ', C, ' ', W, ' list >/dev/null 2>&1'], Probe),
    (   sh_exit(Probe, 0)
    ->  sh_join([W, ' >/dev/null'], Args1),
        piped('assertz(kept(wire_round_trip)).\\nhalt.\\n', Args1, _),
        sh_join([W, ' query ''kept(X)'' 2>/dev/null | head -1'], Args2),
        cocolog_run(Args2, G2, _),
        check('wire: the session''s assert reaches a second process', G2, '  1. kept(wire_round_trip)'),
        sh_join([W, ' forget >/dev/null 2>&1'], Forget),
        cocolog_run(Forget, _, _)
    ;   format("     (skipped: wire -- no Zigurat server at ~w:~w)~n", [Host, Port])
    ).
