%% The four-port tracer, held to SWI-Prolog: both are asked the same
%% queries over test/trace-program.pl with the tracer on, and the port
%% lines are compared one for one -- Call, Exit, Redo and Fail, in order,
%% at the same relative depths, over the same goals.
%%
%% Normalised before comparing: the depth base (SWI's toplevel starts
%% around ten frames deep, cocolog at one), the names of unbound
%% variables (_438 there, _G34 here), and the writers' spacing -- all of
%% it test/trace-diff.pl's, which this case loads and calls in-process
%% where trace.sh ran it as a third process per query.
%%
%% SKIPs without swipl, because "no SWI here" and "the tracer is wrong"
%% are different findings.
%%
%%     cocolog -s test/trace.pl        from the checkout root
%%
%% The two traced runs are children by definition: one of them is another
%% Prolog, and the other is this binary with its tracer on.

:- use_module('test/prelude.pl').
:- use_module('test/trace-diff.pl').

main :-
    ( getenv('SWIPL', Swipl) -> true ; Swipl = swipl ),
    sh_join(['command -v ', Swipl, ' >/dev/null 2>&1'], Have),
    (   sh_exit(Have, 0)
    ->  true
    ;   skip('(no swipl on PATH; apt-get install swi-prolog-nox)')
    ),
    working_directory(Root, Root),
    atom_concat(Root, '/test/trace-program.pl', Program),
    forall(member(Q, [ 'anc(tom, X), fail', 'anc(tom, ann)', 'anc(ann, X)',
                       'sum([1,2], S)', 'sum([1,2,3], S), S > 5',
                       'pick(X), fail', 'pick(b)', 'fst(X, [7,8])',
                       'memb(X, [1,2]), X > 1', 'memb(9, [1,2])',
                       'classify(-3, C)', 'classify(0, C)', 'classify(7, C)',
                       'either(5)', 'either(1)', '3 < 2', 'X = f(Y)', 'atom(foo)',
                       'X is 2 + 2, X > 3', 'np(2)', 'np(1)', 'len3(abc)', 'len3(ab)',
                       %% a cut and then a failure: the call's Fail from the
                       %% frame its cut kept (1.10.24) -- and `cutfail' and
                       %% `sib' are the query's first term, heap cell 0, which
                       %% through 1.10.22 the tracer took for "no call" and
                       %% printed no Fail for
                       'cutfail', 'cpos(5)', 'cpos(-1)', 'cmem(X), fail', 'cmem(X), X > 1',
                       'cor(X), fail', 'cin(5)', 'cutfail ; true',
                       %% a redo opens only the calls it is inside
                       'sib', 'csib',
                       %% arg/3's walk of its places (3.29.0)
                       'ag1(N), fail', 'ag2(X)', 'ag3', 'ag4(N), fail', 'ag1(N)',
                       %% char_type/2's and code_type/2's walks of the codes and the
                       %% classes (3.30.0)
                       'ct1(T)', 'ct2(C)', 'ct2(C), fail', ct3, 'ct4(T)',
                       %% repeat/0's answers at every retry, and a cut that
                       %% takes its frame (3.39.0)
                       'rp(K)', rq, 'repeat, !',
                       %% numbervars/3 over numbervars/4, and a goal written as
                       %% print/1 writes it (3.40.0)
                       'nv(f(X, _, X))', nw, nq, 'nr(X)', 'ns(X)',
                       %% a meta-predicate's argument said of user (3.45.0)
                       'mp(atom(foo))', 'mp(fail)', mq,
                       %% a goal written with portray/1, whose goals run untraced
                       %% (3.54.0)
                       pq ]),
           traced(Swipl, Program, Q)),
    %% LIBRARY CALLS (3.27.0, test/trace-library.pl): a library predicate a
    %% program's clause calls is a port, and what it calls is none -- its
    %% helpers and the builtins they call -- but the program's predicates
    %% it calls back, as swipl's isDebugFrame says; a retry inside one is
    %% the Redo of the library call the program made, once that has exited
    %% (swipl's dbgRedoFrame), and a file's own generate_debug_info false
    %% hides what follows it the same way. Through 3.26 every helper's
    %% ports were printed ('$member_'/3, '$nth_gen'/5, '$between_n'/3, ...)
    atom_concat(Root, '/test/trace-library.pl', Library),
    forall(member(Q, [ 'p(X)', 'q(L)', 'r(N)', 's(L)', 't(L)', 'u(X)', 'v(S)',
                       'a(X)', 'b(M)', 'c', 'e(L)', 'f(S)', 'g(P)', 'h(X)', 'w(B)', ld,
                       m5, a5, b5, n5, s5, u5, 'xm(X)', 'nd(X)', 'ud(X)', 'kd(X)', 'gd(X)',
                       'vd(X)', nt, 'nq(X)', nn, 'member(X, [1, 2]), X > 1',
                       'rt(X)', 'ct(X)', 'ur(X)', 'at(X)', 'ua(X)', 'uk(C)',
                       'mt1(atom(a))', 'mt2(atom(a))' ]),
           traced_in(Swipl, [Library], Q, Q)),
    %% `SYSTEM:G' OF A NAME A PROGRAM FILE TOOK OVER (3.58.1,
    %% test/trace-taken.pl): the system's definition, one call with its
    %% ports and its Redo on the call itself, and none of what its own
    %% clauses call -- its C's answer and the clauses the C turns its
    %% arguments down to alike. Through 3.58.0 a module's answer had no
    %% port, and a goal it turned down ran for ever
    atom_concat(Root, '/test/trace-taken.pl', Taken),
    forall(member(Q, [ 'tk1(X)', 'tk2(P)', 'tk3(X)', 'tk4(P)', 'tk5(P)', 'tk6(N)', 'tk7(X)',
                       'tk8(X)', 'tk9(P)' ]),
           traced_in(Swipl, [Taken], Q, Q)),
    %% A META-PREDICATE'S ARGUMENT AS ITS EXIT AND ITS FAIL SHOW IT (3.45.0),
    %% compared with the qualifiers the comparison above takes off: said of
    %% user where the declaration came first, as it was written where a call
    %% came before the declaration
    forall(member(Q, [ 'mt1(atom(a))', 'mt1(fail)', 'mt2(atom(a))', 'mt2(fail)' ]),
           qualified_ports(Swipl, [Library], Q)),
    %% FINDNSOLS/4'S OWN PORTS (3.72.0), as swipl's: its Call, each chunk's
    %% Exit with its goal said of user, a chunk's Redo -- and since 3.78.3
    %% its whole trace, its goal at swipl's depth and its bag's setup and
    %% cleanup no ports (`$' names), where through 3.78.2
    %% setup_call_cleanup/3's frames stood between it and its goal
    forall(member(Q, [ 'fn(L)', 'fm(L)' ]),
           own_ports(Swipl, [Library], Q, "findnsols(")),
    forall(member(Q, [ 'fn(L)', 'fm(L)' ]),
           traced_in(Swipl, [Library], Q, Q)),
    %% CALL_WITH_INFERENCE_LIMIT/3'S OWN PORTS (3.73.0), as swipl's -- and
    %% since 3.78.7 its goal's, which its catch/3 puts a frame deeper, as
    %% swipl's (through 3.78.6 cocolog's catch/3 was no frame)
    forall(member(Q, [ 'il(R)', 'ig(R)' ]),
           own_ports(Swipl, [Library], Q, "call_with_inference_limit(")),
    forall(member(Q, [ 'il(R)', 'ig(R)' ]),
           traced_in(Swipl, [Library], Q, Q)),
    %% A GOAL ANSWERS UNDER TRACE AS IT DOES UNTRACED (3.72.0): a clause
    %% frame the tracer keeps at its last candidate is no choice point to
    %% setup_call_cleanup/3's exit, so call_cleanup/2's cleanup runs at its
    %% goal's last answer and findnsols/4's last chunk is the last. Through
    %% 3.71.0 the cleanup waited for a cut, and findnsols/4 gave one more
    forall(member(Q, [ cd, fa ]),
           traced_answers(Swipl, [Library], Q)),
    %% SETUP_CALL_CLEANUP/3 (3.78.3, test/trace-cleanup.pl): its setup,
    %% goal and cleanup where swipl's stand -- four, two and three below the
    %% call, the cleanup a cut runs two below the clause that cut -- and none
    %% of its machinery a port. Through 3.78.2 the goal was three below, a
    %% cleanup four or five, a cut printed `'$cleanup_call'(!, _, C)''s Call
    %% and Exit in the program's clause, and a raise in the goal a Redo of
    %% `'$scc_raised'/4'. A raise under a catch/3 is held whole since 3.78.7
    %% (`traced_nx'), the catch/3 a frame in both; through 3.78.6 from the
    %% call on, cocolog's catch/3 no frame. The machinery's own catch/3 is
    %% none, as swipl has none (`coco_trace_cpred_quiet')
    atom_concat(Root, '/test/trace-cleanup.pl', Cleanup),
    forall(member(Q, [ sc1, sc2, sc3, sc4, sc5, sc6, sc7, sc8, sc9, sc10, sc11, sc12, sc13,
                       sc14, sc15, sc16, sc17, sc18, sc19, sc20, sc21 ]),
           traced_in(Swipl, [Cleanup], Q, Q)),
    forall(member(Q, [ 'catch(sx1, _, true)', 'catch(sx2, _, true)' ]),
           traced_nx(Swipl, [Cleanup], Q, Q)),
    %% A PREDICATE WHOSE NAME BEGINS WITH `$' IS NO PORT (3.78.3,
    %% test/trace-dollar.pl), as none of swipl's is, a program's own too:
    %% what it calls is asked as any call's, and a retry inside it is the
    %% Redo of the library call it is in, none where its caller hides
    %% nothing. Through 3.78.2 each was a port and its retry its own Redo
    atom_concat(Root, '/test/trace-dollar.pl', Dollar),
    forall(member(Q, [ dl1, dl2, dl3, dl4, dl5, dl6, dl7, dl8, dl9, dl10 ]),
           traced_in(Swipl, [Dollar], Q, Q)),
    %% CALL/1 OF A CONTROL STRUCTURE (3.78.4, test/trace-meta.pl) stands in
    %% swipl's `'<meta-call>'/1' frame, which I_USERCALL compiles it into --
    %% a level below the call, no port and hiding nothing -- so its parts
    %% are a level deeper, a builtin among them is a port in a library's
    %% clause too, and a `;' retried in it is no Redo; under its
    %% qualifiers, as a variable goal, as forall/2's condition and action
    %% and as setup_call_cleanup/3's goal alike. Through 3.78.3 the parts
    %% stood at the call's level, and a library's clause hid their builtins
    atom_concat(Root, '/test/trace-meta.pl', Meta),
    forall(between(1, 43, I),
           ( atom_concat(mt, I, Q), traced_in(Swipl, [Meta], Q, Q) )),
    %% A SHALLOW BACKTRACK (3.78.5, test/trace-shallow.pl) prints no Redo:
    %% `\+''s own fail is swipl's C_FAIL, and where the newest choice point
    %% is a jump of its clause -- a `;', an else, another `\+''s -- swipl
    %% takes it with no port, as a bare if-then and a bare soft cut, which
    %% make no choice point, print none for their condition's failure; a
    %% call's choice point, or a port printed first, is a deep backtrack and
    %% its Redo. Through 3.78.4 `\+ \+ atom(a)' printed a Redo of its clause
    atom_concat(Root, '/test/trace-shallow.pl', Shallow),
    forall(between(1, 49, I),
           ( atom_concat(sh, I, Q), traced_in(Swipl, [Shallow], Q, Q) )),
    %% THE CONTROL PREDICATES SWIPL CALLS AS PREDICATES (3.78.6,
    %% test/trace-ctlpred.pl): call/N's closure, a setup, a cleanup,
    %% with_output_to/2's and `~@''s goal is boot/init.pl's ','/2 and its
    %% kin, a port whose clause meta-calls the structure, its parts a
    %% `'<meta-call>'/1' below it; a goal C runs two below its builtin.
    %% Through 3.78.5 call/N ran the structure in place, a setup's and a
    %% cleanup's frame was no port, and with_output_to/2's goal stood one
    %% below. Then the helper's own ports, its goal as each shows it -- at the
    %% Call as the caller gave it, at the Exit said of user -- with the
    %% qualifiers the comparison above takes off
    atom_concat(Root, '/test/trace-ctlpred.pl', Ctl),
    forall(between(1, 52, I),
           ( atom_concat(ct, I, Q), traced_in(Swipl, [Ctl], Q, Q) )),
    forall(member(Q-Dp, [ ct2-2, ct14-2, ct17-2, ct21-2, ct26-6, ct27-6, ct28-5, ct30-5,
                          ct39-4, ct40-4, ct41-4, ct53-6, ct54-5 ]),
           ports_at(Swipl, [Ctl], Q, Dp)),
    %% ONCE/1, IGNORE/1, NOT/1 AND CATCH/3 ARE PORTS (3.78.7,
    %% test/trace-ctlframe.pl), as swipl's transparent predicates: the goal a
    %% level below, a structure in a `'<meta-call>'/1' frame there, what a
    %% program defines shown and what the system does hidden; catch/3's
    %% recovery a level below it, and no Fail after a ball it took. Through
    %% 3.78.6 the four ran in place, no port and no level. Held with swipl's
    %% Exception port not shown (`traced_nx'), which cocolog has none of; then
    %% the four's own ports, the goal as the Call gives it and the Exit, Fail
    %% and Redo say it of user, with the qualifiers the comparison takes off
    atom_concat(Root, '/test/trace-ctlframe.pl', Frame),
    forall(between(1, 82, I),
           ( atom_concat(cf, I, Q), traced_nx(Swipl, [Frame], Q, Q) )),
    forall(member(Q-Dp, [ cf1-2, cf2-2, cf5-2, cf9-2, cf16-2, cf22-2, cf23-2, cf33-2, cf38-2,
                          cf41-2, cf42-2, cf48-2, cf66-2, cf72-2 ]),
           ports_at(Swipl, [Frame], Q, Dp)),
    %% ...and not/1 and ignore/1 a program took over are its predicates,
    %% which hide nothing (test/trace-taken.pl's tk10 to tk12)
    forall(member(Q, [ tk10, tk11, tk12 ]), traced_in(Swipl, [Taken], Q, Q)),
    %% THE FLAG IS THE FILE'S: test/trace-library.pl ends with it false, and
    %% the file read after it is the program's again (swipl's load puts the
    %% flag back at a file's end)
    traced_in(Swipl, [Library, Program], 'anc(tom, ann)',
              'a file read after one that ends with generate_debug_info false'),
    %% HELD TO COCOLOG'S OWN LINES: what swipl prints otherwise, or has none
    %% of (`own_lines')
    own_lines,
    %% TRACED AFTER AN UNTRACED CALL. The first call resolves every functor
    %% it meets and stamps the plain predicates (`fgen', 1.8.55), whose
    %% goals then skip the questions a traced call has to ask; `trace/0'
    %% switched on afterwards must still bring every port of the second
    %% call back. And `classify/2' starts with a guard, `N < 0', which the
    %% untraced call compiles and runs as the clause is entered (1.9.1):
    %% traced, it must be a goal with its ports again. And `pick/1',
    %% `either/1' and `np/1' are bodies of constructs, which the untraced
    %% call compiles into environments (Stage 6): traced, each is built as
    %% the terms it was written as, and the Redo of a written `;' comes back.
    %% And in `len3/1' a type test, a builtin and a comparison run in place
    %% from that environment (Stage 7): traced, each is a goal with its ports.
    forall(member(Q, [ 'anc(tom, ann)', 'sum([1,2,3], S), S > 5',
                       'classify(-3, C)', 'classify(7, C)',
                       'pick(X), fail', 'pick(b)', 'either(5)', 'either(1)', 'np(2)',
                       'len3(abc)', 'len3(ab)' ]),
           traced_late(Swipl, Program, Q)),
    %% A DISJUNCTION FROM AN ENVIRONMENT WRITTEN UNTRACED, TAKEN TRACED
    %% (Stage 6): `lt/1' switches the tracer on as its first goal, so its
    %% `;' -- and the call to `pick/1' inside it -- are reached from the
    %% environment its untraced entry wrote, and each is handed over as the
    %% term it was written as. `pick/1' is called once untraced first, so it
    %% is stamped a plain predicate and its call could go into the
    %% registers, which skip the tracer's ports: taken without the tracer's
    %% test, its Call, Exit and Redo went missing. SWI shows the `lt/1'
    %% call it finds in its frames and this engine never has, so the run is
    %% held to itself with no environments at all (`COCOLOG_ENV=0').
    env_late(Program, 'pick(_), lt(X), X == c'),
    %% AND THE UNITS RUN IN PLACE (Stage 7): in `lb/2' a `=/2', a builtin
    %% and a comparison are reached the same way, and each is handed over as
    %% the term it was written as, whichever branch is taken.
    env_late(Program, 'lb(abc, N)'),
    env_late(Program, 'lb(x, N)'),
    checks_done.

%% every query is wrapped in ( Q -> true ; true ) on BOTH sides, so a
%% failing query is a traced failure rather than a differing toplevel
traced(Swipl, Program, Q) :-
    sh_join(['yes '''' | timeout 20 ', Swipl, ' -q -g "leash(-all), consult(''', Program,
             '''), trace, ( ', Q, ' -> true ; true ), notrace, halt" -t halt 2>&1'], SwiCmd),
    proc_run(SwiCmd, 30000, Swi0, _),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' --trace run ', Program, ' "( ', Q, ' -> true ; true )" 2>&1 >/dev/null'], CocoCmd),
    proc_run(CocoCmd, 30000, Coco0, _),
    td_ports(Swi0, Swi), td_ports(Coco0, Coco),
    ( td_compare(Swi, Coco, 1, Q) -> R = identical ; R = differs ),
    check(Q, R, identical).

%% the files read, then the query traced from `trace/0' switched on inside
%% the goal -- test/trace-library.pl has a directive's goal, which --trace
%% would print as the file is read, and swipl's run switches the tracer on
%% after its consults
traced_in(Swipl, Files, Q, Name) :-
    traced_in(Swipl, Files, Q, Name, '').

%% ...and with swipl's Exception port not shown (3.78.7: through 3.78.6
%% `traced_from/4' held such a trace from a call on), which cocolog has
%% none of: a ball's port, leashed, takes no newline before the port after
%% it, and the line is no port of either trace
traced_nx(Swipl, Files, Q, Name) :-
    traced_in(Swipl, Files, Q, Name, 'visible(-exception), ').

traced_in(Swipl, Files, Q, Name, Vis) :-
    findall(S1, ( member(F1, Files), sh_join(['consult(''', F1, '''), '], S1) ), Cs),
    sh_join(Cs, Consults),
    sh_join(['yes '''' | timeout 20 ', Swipl, ' -q -g "leash(-all), ', Vis, Consults,
             'trace, ( ', Q, ' -> true ; true ), notrace, halt" -t halt 2>&1'], SwiCmd),
    proc_run(SwiCmd, 30000, Swi0, _),
    cocolog(C),
    findall(S2, ( member(F2, Files), sh_join([F2, ' '], S2) ), Fs),
    sh_join(Fs, Paths),
    sh_join(['timeout 20 ', C, ' run ', Paths, '"trace, ( ', Q, ' -> true ; true ), notrace" 2>&1 >/dev/null'],
            CocoCmd),
    proc_run(CocoCmd, 30000, Coco0, _),
    td_ports(Swi0, Swi), td_ports(Coco0, Coco),
    ( td_compare(Swi, Coco, 1, Q) -> R = identical ; R = differs ),
    check(Name, R, identical).

%% the Exit and the Fail ports of Q traced as `traced_in/4' traces it, each
%% goal as it was printed, its qualifiers on (3.45.0)
qualified_ports(Swipl, Files, Q) :-
    findall(S1, ( member(F1, Files), sh_join(['consult(''', F1, '''), '], S1) ), Cs),
    sh_join(Cs, Consults),
    sh_join(['yes '''' | timeout 20 ', Swipl, ' -q -g "leash(-all), ', Consults,
             'trace, ( ', Q, ' -> true ; true ), notrace, halt" -t halt 2>&1'], SwiCmd),
    proc_run(SwiCmd, 30000, Swi0, _),
    cocolog(C),
    findall(S2, ( member(F2, Files), sh_join([F2, ' '], S2) ), Fs),
    sh_join(Fs, Paths),
    sh_join(['timeout 20 ', C, ' run ', Paths, '"trace, ( ', Q, ' -> true ; true ), notrace" 2>&1 >/dev/null'],
            CocoCmd),
    proc_run(CocoCmd, 30000, Coco0, _),
    qp_goals(Swi0, Swi), qp_goals(Coco0, Coco),
    atom_concat('the qualified ports of ', Q, Name),
    check(Name, Coco, Swi).

qp_goals(Codes, Gs) :-
    td_lines(Codes, Lines),
    findall(P-G, ( member(L, Lines), td_port(L, P, _, G0),
                   memberchk(P, ['Exit', 'Fail']), atom_codes(G, G0) ),
            Gs).

%% the ports of Q's trace at depth DEPTH, each trace rebased as
%% `traced_in/4' rebases it, each goal its variables and spaces taken out
%% and its qualifiers left (3.78.6): a control predicate's frame as its
%% Call and its Exit show its goal
ports_at(Swipl, Files, Q, Depth) :-
    findall(S1, ( member(F1, Files), sh_join(['consult(''', F1, '''), '], S1) ), Cs),
    sh_join(Cs, Consults),
    sh_join(['yes '''' | timeout 20 ', Swipl, ' -q -g "leash(-all), ', Consults,
             'trace, ( ', Q, ' -> true ; true ), notrace, halt" -t halt 2>&1'], SwiCmd),
    proc_run(SwiCmd, 30000, Swi0, _),
    cocolog(C),
    findall(S2, ( member(F2, Files), sh_join([F2, ' '], S2) ), Fs),
    sh_join(Fs, Paths),
    sh_join(['timeout 20 ', C, ' run ', Paths, '"trace, ( ', Q, ' -> true ; true ), notrace" 2>&1 >/dev/null'],
            CocoCmd),
    proc_run(CocoCmd, 30000, Coco0, _),
    pa_goals(Swi0, Depth, Swi), pa_goals(Coco0, Depth, Coco),
    format(atom(Name), 'the ports of ~w at depth ~w', [Q, Depth]),
    %% none from swipl is no ports to hold: the check is red
    ( Swi == [] -> Got = none ; Got = Coco ),
    check(Name, Got, Swi).

pa_goals(Codes, Depth, Gs) :-
    td_lines(Codes, Lines),
    findall(D0-P-G, ( member(L, Lines), td_port(L, P, D0, G0),
                      td_strip_var(G0, G1), td_strip_space(G1, G2), atom_codes(G, G2) ),
            Raw),
    ( Raw = [B0-_-_|_] -> Base is B0 - 1 ; Base = 0 ),
    findall(P-G, ( member(D1-P-G, Raw), Depth =:= D1 - Base ), Gs).

%% every port of Q's trace whose goal begins with PREFIX, its variables and
%% spaces taken out and its qualifiers left (3.72.0)
own_ports(Swipl, Files, Q, Prefix) :-
    findall(S1, ( member(F1, Files), sh_join(['consult(''', F1, '''), '], S1) ), Cs),
    sh_join(Cs, Consults),
    sh_join(['yes '''' | timeout 20 ', Swipl, ' -q -g "leash(-all), ', Consults,
             'trace, ( ', Q, ' -> true ; true ), notrace, halt" -t halt 2>&1'], SwiCmd),
    proc_run(SwiCmd, 30000, Swi0, _),
    cocolog(C),
    findall(S2, ( member(F2, Files), sh_join([F2, ' '], S2) ), Fs),
    sh_join(Fs, Paths),
    sh_join(['timeout 20 ', C, ' run ', Paths, '"trace, ( ', Q, ' -> true ; true ), notrace" 2>&1 >/dev/null'],
            CocoCmd),
    proc_run(CocoCmd, 30000, Coco0, _),
    op_goals(Swi0, Prefix, Swi), op_goals(Coco0, Prefix, Coco),
    atom_concat('the own ports of ', Q, Name),
    check(Name, Coco, Swi).

op_goals(Codes, Prefix, Gs) :-
    td_lines(Codes, Lines),
    findall(P-G, ( member(L, Lines), td_port(L, P, _, G0),
                   td_strip_var(G0, G1), td_strip_space(G1, G2),
                   append(Prefix, _, G2), atom_codes(G, G2) ),
            Gs).

%% what Q prints traced, swipl's and cocolog's, and what cocolog's prints
%% untraced: one text (3.72.0)
traced_answers(Swipl, Files, Q) :-
    findall(S1, ( member(F1, Files), sh_join(['consult(''', F1, '''), '], S1) ), Cs),
    sh_join(Cs, Consults),
    sh_join(['yes '''' | timeout 20 ', Swipl, ' -q -g "leash(-all), ', Consults,
             'trace, ( ', Q, ' -> true ; true ), notrace, halt" -t halt 2>/dev/null'], SwiCmd),
    proc_run(SwiCmd, 30000, Swi, _),
    cocolog(C),
    findall(S2, ( member(F2, Files), sh_join([F2, ' '], S2) ), Fs),
    sh_join(Fs, Paths),
    sh_join(['timeout 20 ', C, ' run ', Paths, '"trace, ( ', Q, ' -> true ; true ), notrace" 2>/dev/null'],
            TracedCmd),
    proc_run(TracedCmd, 30000, Traced, _),
    sh_join(['timeout 20 ', C, ' run ', Paths, '"( ', Q, ' -> true ; true )" 2>/dev/null'], PlainCmd),
    proc_run(PlainCmd, 30000, Plain, _),
    atom_codes(SwiA, Swi), atom_codes(TracedA, Traced), atom_codes(PlainA, Plain),
    atom_concat('traced as swipl: ', Q, N1),
    check(N1, TracedA, SwiA),
    atom_concat('traced as untraced: ', Q, N2),
    check(N2, TracedA, PlainA).

%% a fixture each, traced from inside the goal, and a line it must print or
%% must not. A program's clause joins a library's predicate (card row N1):
%% sumlist/2 is the program's then as much as the library's, and what it
%% calls is printed, the library's sum_list/2 -- swipl's program's sumlist/2
%% is user's, the library's out of sight -- but a helper whose name begins
%% with `$' is no port by its name (3.78.3), member/2's `'$member_'/3' among
%% them, which through 3.78.2 this case held printed. call_limited/3's goal
%% is in its context, as call_with_inference_limit/3's clause has it.
%% print_message/2 and async_workers/1 are a library's that says
%% generate_debug_info false. (with_output_to/2's goal, a query of its own
%% whose library call is printed, is held line for line since 3.78.6:
%% test/trace-ctlpred.pl's ct47)
own_lines :-
    scratch(D),
    own(D, joined0, [ 'j(S) :- sumlist([1], S).' ], 'j(S)',
        p('Call', 3, 'sum_list([1],_)'), hidden,
        'a library''s sumlist/2 hides what its clause calls'),
    own(D, joined, [ 'j(S) :- sumlist([1], S).', 'sumlist(z, z).' ], 'j(S)',
        p('Call', 3, 'sum_list([1],_)'), printed,
        'a program''s clause for sumlist/2 prints what the library''s clause calls'),
    %% the same read after the library's (a `run' file's first directive
    %% reads the libraries): the program's clause decides again, where the
    %% one above is sumlist/2's first and the library's joins it
    own(D, joined2, [ ':- true.', 'j(S) :- sumlist([1], S).', 'sumlist(z, z).' ], 'j(S)',
        p('Call', 3, 'sum_list([1],_)'), printed,
        'and so does one read after the library''s, a directive having read it'),
    own(D, joined3, [ 'j(X) :- member(X, [1]).', 'member(z, [z]).' ], 'j(X)',
        p('Call', 3, '''$member_''([],_,1)'), hidden,
        'but member/2''s `$'' helper is no port by its name, joined or not'),
    own(D, cl, [ 'cl(R) :- call_limited(member(_, [1]), 100, R).' ], 'cl(R)',
        p(_, 3, _), hidden,
        'call_limited/3''s goal is in its context: a library call in it is not printed'),
    %% and the program's predicate in it is, one deeper (swipl's exceeds the
    %% limit under its tracer: its trace costs it inferences)
    own(D, cl2, [ 'cl2(R) :- call_limited(cp(_), 100, R).', 'cp(X) :- member(X, [1]).' ], 'cl2(R)',
        p('Call', 3, 'cp(_)'), printed,
        'and a program predicate in call_limited/3''s goal is printed'),
    own(D, pm, [ 'pm :- print_message(silent, format("x", [])).' ], pm,
        p(_, 3, _), hidden,
        'print_message/2''s clauses call nothing the printer shows'),
    own(D, aw, [ 'aw(N) :- async_workers(N).' ], 'aw(N)',
        p(_, 3, _), hidden,
        'async_workers/1''s clause calls nothing the printer shows'),
    %% A `;' WRITTEN IN A BUILTIN'S GOAL (3.78.3): its retry is no Redo, as
    %% swipl's prints none -- the goal's call is no frame of the search's
    %% own. Through 3.78.2 it was the Redo of the builtin's own call, and in
    %% with_output_to/2's of the heap's first term (`Redo: (2) trace').
    %% (swipl's findall/3 runs its goal frames deeper than cocolog's search
    %% does: those traces are not held line for line; with_output_to/2's,
    %% its ';'/2 predicate's frame, is since 3.78.6, test/trace-ctlpred.pl)
    own(D, br1, [ 'br1 :- findall(X, (fail ; X = 1), _).' ], br1,
        p('Redo', _, _), hidden,
        'a `;'' in findall/3''s goal is no Redo of findall/3'),
    own(D, br2, [ 'br2 :- forall((fail ; X = 1), integer(X)).' ], br2,
        p('Redo', _, _), hidden,
        'a `;'' in forall/2''s condition is no Redo of forall/2'),
    own(D, br3, [ 'br3 :- with_output_to(string(_), (fail ; true)).' ], br3,
        p('Redo', _, _), hidden,
        'a `;'' in with_output_to/2''s goal is no Redo of the heap''s first term'),
    %% (A SETUP OR A CLEANUP THAT IS A CONTROL STRUCTURE is the ','/2 port
    %% swipl's callProlog() calls since 3.78.6, held line for line by
    %% test/trace-ctlpred.pl, ct36 the shape these lines held through 3.78.5:
    %% its frame no port, its parts six below)
    %% A STRUCTURE IN FINDALL/3'S, AGGREGATE_ALL/3'S OR CALL_LIMITED/3'S GOAL
    %% (3.78.4) stands in a `'<meta-call>'/1' frame, as swipl's clauses
    %% meta-call it: a builtin in it is a port, two below the builtin's call
    %% -- swipl's findall/3 runs it six below, through findall_loop/4 and
    %% its cleanup's frames, where cocolog's search is one -- and a plain
    %% goal there is in the builtin's context, hidden as swipl's is.
    %% Through 3.78.3 the structure's builtins were hidden too
    own(D, fa1, [ 'fa1 :- findall(x, (atom(a) ; atom(b)), _).' ], fa1,
        p('Call', 4, 'atom(a)'), printed,
        'a structure in findall/3''s goal is meta-called: a builtin in it a port'),
    own(D, fa2, [ 'fa2 :- aggregate_all(count, (atom(a), atom(b)), _).' ], fa2,
        p('Call', 4, 'atom(b)'), printed,
        'and in aggregate_all/3''s'),
    own(D, fa3, [ 'fa3(R) :- call_limited((atom(a), atom(b)), 100, R).' ], 'fa3(R)',
        p('Call', 4, 'atom(a)'), printed,
        'and in call_limited/3''s'),
    own(D, fa4, [ 'fa4 :- findall(x, atom(a), _).' ], fa4,
        p('Call', _, 'atom(a)'), hidden,
        'a plain goal in findall/3''s goal is in its context: a builtin no port'),
    %% a fact the program asserts under a compiled-in module's name is no
    %% predicate the call reaches -- files' C answers '$path_base'/2 -- so
    %% the store is asked after the modules, as the step dispatches
    own(D, fb, [ ':- assertz(''$path_base''(x, y)).', 'fb(B) :- file_base_name(''a/b.pl'', B).' ],
        'fb(B)', p(_, 3, _), hidden,
        'a fact under a module''s name leaves the module''s call hidden'),
    %% and a library's call of a name the program took over is the system's
    %% (`system:is_list/1', the builtin kept): hidden as the builtin's is
    own(D, tk, [ 'is_list(x).', 'tk :- must_be(list, [a]).' ], tk,
        p(_, _, 'is_list([a])'), hidden,
        'a library''s call of a name the program took over is hidden as the builtin''s'),
    %% A PORTRAY GOAL THAT THROWS AS THE TRACER WRITES A PORT (3.54.0): the
    %% line cut where it threw, as swipl's is, and the ball given back
    %% unraised, where swipl's goes up into the program at a later port --
    %% kept, write_term/2 would raise it as a portray goal's of its own
    own(D, tz, [ 'portray(pz) :- throw(oops).', 'tz :- atom(pz), write_term(ok, []).' ], tz,
        p('Call', 2, 'atom('), printed,
        'a portray goal that throws cuts the tracer''s line where it threw'),
    own(D, tz2, [ 'portray(pz) :- throw(oops).', 'tz :- atom(pz), write_term(ok, []).' ], tz,
        p('Exit', 2, 'write_term(ok,[])'), printed,
        'and its ball is given back: the program goes on'),
    %% A HALT HAS NO EXIT PORT (3.57.0): the process ends at its Call, as
    %% swipl's; and a builtin whose search halted (with_output_to/2's goal)
    %% has no Fail port, as nothing failed -- the process ended in it
    own(D, ht, [ 'ht :- halt(28).' ], ht,
        p('Call', _, 'halt(28)'), printed,
        'halt/1''s Call is printed'),
    own(D, ht2, [ 'ht :- halt(28).' ], ht,
        p('Exit', _, 'halt(28)'), hidden,
        'and it has no Exit port: the process ends at its Call, as swipl''s'),
    %% a name a program file took over, called through `system:', is run
    %% by the `:' construct's own call of its row (`coco_colon_run')
    own(D, hc, [ ':- redefine_system_predicate(halt).', 'halt :- write(mine).', 'hc :- system:halt.' ], hc,
        p('Call', _, halt), printed,
        'the system''s halt/0, called through a qualifier over a program''s, has its Call'),
    own(D, hc2, [ ':- redefine_system_predicate(halt).', 'halt :- write(mine).', 'hc :- system:halt.' ], hc,
        p('Exit', _, halt), hidden,
        'and no Exit either: the `:'' construct''s call of the row'),
    own(D, hw, [ 'hw :- with_output_to(string(_), halt(28)).' ], hw,
        p('Fail', _, _), hidden,
        'with_output_to/2 whose goal halts has no Fail port'),
    %% A QUALIFIED GOAL HAS THE PORTS AN UNQUALIFIED ONE HAS (3.58.1): a name
    %% nothing defines has its Call, as swipl prints it, in a clause that
    %% hides its children too -- the system's G hides its children, any
    %% other is asked as the step asks it (`coco_colon_run'). Through 3.58.0
    %% it had none. (Since 3.78.7 the whole trace is held to swipl's too,
    %% test/trace-ctlframe.pl's cf81: catch/3 is a frame in both)
    own(D, uq, [ ':- set_prolog_flag(generate_debug_info, false).',
                 'hq :- catch(lists:nosuch_xyz, _, true).',
                 ':- set_prolog_flag(generate_debug_info, true).' ], hq,
        p('Call', _, nosuch_xyz), printed,
        'a qualified goal nothing defines has its Call, in a clause that hides its children'),
    %% A KEPT FRAME'S RETRY RUNS THE NEXT CLAUSE'S BODY AS THE KEPT FRAME'S
    %% (3.58.1): aggregate_all/3's first clause tests its spec with var/1,
    %% and the clause that answers a template of templates calls
    %% template_to_pattern/6, findall/3 and aggregate_list/3, hidden as the
    %% kept predicate hides its children -- the retry's context is the
    %% frame's call, the kept head, where the goal printed names the
    %% program's aggregate_all/3. swipl hides them too; the two traces are
    %% not held line for line, as both show what aggregate_list/3's maplist/4
    %% calls and swipl names its helper apply:maplist_/4
    own(D, kr, [ 'aggregate_all(_, _, mine).',
                 'kr(R) :- system:aggregate_all(r(count), member(_, [a]), R).' ], 'kr(R)',
        p(_, 3, _), hidden,
        'a kept frame''s retry runs the next clause''s body hidden'),
    %% A SHALLOW BACKTRACK BY ONCE/1, NOT/1, IGNORE/1 AND CATCH/3 (3.78.5):
    %% once/1's else is no choice point of swipl's, so its failure prints no
    %% Redo of its clause; not/1's own fail leaves its frame, deep, and the
    %% caller's Redo is printed; and a `\+' in the goal one of the four runs
    %% fails back into that goal's `;' with no Redo. (The four are frames
    %% since 3.78.7, as swipl's, their goal a meta-call's, and the whole
    %% traces are held to swipl's too: test/trace-ctlframe.pl's cf74 to cf80)
    own(D, on, [ 'on :- once(fail).' ], on,
        p('Redo', _, on), hidden,
        'once/1''s failure prints no Redo of its clause'),
    own(D, on2, [ 'on2 :- once(fail) ; true.' ], on2,
        p('Redo', _, on2), times(1),
        'and its clause''s `;'' prints one Redo, not two'),
    own(D, nt, [ 'nt :- ( not(atom(a)) ; true ).' ], nt,
        p('Redo', _, nt), printed,
        'not/1''s own fail is deep: its caller''s Redo is printed'),
    own(D, nt2, [ 'nt2 :- ( not(( \\+ atom(a) ; true )) ; true ).' ], nt2,
        p('Redo', _, nt2), times(1),
        'and a `\\+'' in its goal fails back into the goal''s `;'' with no Redo'),
    own(D, ct, [ 'ct :- catch(( \\+ atom(a) ; true ), _, true).' ], ct,
        p('Redo', _, _), hidden,
        'as a `\\+'' in catch/3''s goal does'),
    own(D, oc, [ 'oc :- once(( \\+ atom(a) ; true )).' ], oc,
        p('Redo', _, _), hidden,
        'and in once/1''s'),
    own(D, ig, [ 'ig :- ignore(( \\+ atom(a) ; true )).' ], ig,
        p('Redo', _, _), hidden,
        'and in ignore/1''s'),
    own(D, ng, [ 'ng :- not(atom(a)).', 'ng.' ], ng,
        p('Redo', _, ng), printed,
        'not/1''s own fail is deep into its clause''s next clause too'),
    %% a call past call_with_depth_limit/3's limit fails its frame, deep,
    %% as swipl's `Fail: [depth-limit exceeded]' does: the Redo of the
    %% clause it stood in is printed (cocolog says no Fail line: COMPAT.md)
    own(D, dl1, [ 'dl1 :- call_with_depth_limit(dl_a, 1, _).',
                  'dl_a :- ( dl_b ; true ).', 'dl_b.' ], dl1,
        p('Redo', _, dl_a), printed,
        'a call past the depth limit fails deep into its clause''s `;'''),
    own(D, dl2, [ 'dl2 :- call_with_depth_limit(dl_c, 1, _).',
                  'dl_c :- dl_b.', 'dl_c.', 'dl_b.' ], dl2,
        p('Redo', _, dl_c), printed,
        'and into its clause''s next clause'),
    %% a frame a shallow backtrack resumed with no Redo ends it, a `;' or
    %% the clause's next clause: a depth failure in what it runs next,
    %% which prints no port, is deep, its Redo printed -- memberchk/2 past
    %% a limit of 2 where atom/1 is within it, as in swipl
    own(D, dl3, [ 'dl3 :- call_with_depth_limit(dl_f, 2, _).',
                  'dl_f :- ( ( \\+ atom(a) ; memberchk(a, [a]) ) ; true ).' ], dl3,
        p('Redo', _, dl_f), times(1),
        'a `;'' a shallow backtrack took ends it: a depth failure after it is deep'),
    own(D, dl4, [ 'dl4 :- call_with_depth_limit(dl_g, 2, _).',
                  'dl_g :- \\+ atom(a).', 'dl_g :- ( memberchk(a, [a]) ; true ).' ], dl4,
        p('Redo', _, dl_g), times(1),
        'and so does the next clause a shallow backtrack took'),
    %% the frame a shallow backtrack resumes ends it whatever it is: a
    %% retry whose remaining heads all fail, and a frame pushed untraced
    %% (after notrace/0) -- a deep backtrack into the clause's `;' after it
    %% prints the clause's Redo, as swipl's does (the first cut of 3.78.5
    %% printed none). Not held line for line: such a retry prints no Redo
    %% and no Fail of its own, and an untraced frame no port retried, where
    %% swipl prints them (COMPAT.md)
    own(D, hr1, [ 'hr_r(1, 1).', 'hr_r(2, 3).',
                  'hr1 :- ( hr_r(A, A), \\+ atom(a) ; true ).' ], hr1,
        p('Redo', _, hr1), times(1),
        'a retry whose heads all fail ends a shallow backtrack'),
    own(D, hr2, [ 'hr_r(1, 1).', 'hr_r(2, 3).',
                  'hr2 :- notrace, hr_r(A, B), trace, ( B == 3 -> ( true ; true ), fail ; \\+ atom(a) ), A > 0.' ], hr2,
        p('Redo', _, hr2), times(2),
        'and so does the retry of a frame pushed untraced'),
    shl(['rm -rf ', D]).

own(D, Base, Lines, Q, Line, Expect, Name) :-
    atomic_list_concat([D, '/', Base, '.pl'], F),
    fixture(F, Lines),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' run ', F, ' "trace, ( ', Q, ' -> true ; true ), notrace" 2>&1 >/dev/null'], Cmd),
    proc_run(Cmd, 30000, Out, _),
    td_ports(Out, Rows),
    own_seen(Expect, Line, Rows, R),
    check(Name, R, Expect).

%% printed or hidden, or times(N): how many of the rows the line is
own_seen(times(_), Line, Rows, times(N)) :- !,
    aggregate_all(count, member(Line, Rows), N).
own_seen(_, Line, Rows, R) :-
    ( memberchk(Line, Rows) -> R = printed ; R = hidden ).

%% the query run once untraced, then again with `trace/0' switched on
%% between the two -- on both sides, and without --trace on this one
traced_late(Swipl, Program, Q) :-
    sh_join(['yes '''' | timeout 20 ', Swipl, ' -q -g "leash(-all), consult(''', Program,
             '''), ( ', Q, ' -> true ; true ), trace, ( ', Q, ' -> true ; true ), notrace, halt" -t halt 2>&1'], SwiCmd),
    proc_run(SwiCmd, 30000, Swi0, _),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' run ', Program, ' "( ', Q, ' -> true ; true ), trace, ( ', Q,
             ' -> true ; true ), notrace" 2>&1 >/dev/null'], CocoCmd),
    proc_run(CocoCmd, 30000, Coco0, _),
    td_ports(Swi0, Swi), td_ports(Coco0, Coco),
    atom_concat('traced after an untraced call: ', Q, Name),
    ( td_compare(Swi, Coco, 1, Name) -> R = identical ; R = differs ),
    check(Name, R, identical).

%% the query run with environments and without, both through `trace/0'
%% switched on inside it: the port lines must be the same lines
env_late(Program, Q) :-
    cocolog(C),
    sh_join(['timeout 20 ', C, ' run ', Program, ' "( ', Q, ' -> true ; true ), notrace" 2>&1 >/dev/null'], OnCmd),
    proc_run(OnCmd, 30000, On, _),
    sh_join(['COCOLOG_ENV=0 timeout 20 ', C, ' run ', Program, ' "( ', Q, ' -> true ; true ), notrace" 2>&1 >/dev/null'],
            OffCmd),
    proc_run(OffCmd, 30000, Off, _),
    atom_concat('traced from inside, through an environment: ', Q, Name),
    ( On == Off, On \== [] -> R = identical ; R = differs ),
    check(Name, R, identical).
