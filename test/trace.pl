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
                       'X is 2 + 2, X > 3', 'np(2)', 'np(1)' ]),
           traced(Swipl, Program, Q)),
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
