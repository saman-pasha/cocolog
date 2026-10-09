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
    forall(member(Q, [ 'anc(tom, ann)', 'sum([1,2,3], S), S > 5',
                       'classify(-3, C)', 'classify(7, C)',
                       'pick(X), fail', 'pick(b)', 'either(5)', 'either(1)', 'np(2)' ]),
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
