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
                       'ag1(N), fail', 'ag2(X)', 'ag3', 'ag4(N), fail', 'ag1(N)' ]),
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
                       'rt(X)', 'ct(X)', 'ur(X)', 'at(X)', 'ua(X)' ]),
           traced_in(Swipl, [Library], Q, Q)),
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
    td_ports(Swi0, Swi), td_ports(Coco0, Coco),
    ( td_compare(Swi, Coco, 1, Q) -> R = identical ; R = differs ),
    check(Name, R, identical).

%% a fixture each, traced from inside the goal, and a line it must print or
%% must not. A program's clause joins a library's predicate (card row N1):
%% member/2 is the program's then as much as the library's, and what it calls
%% is printed, the library's helper among it -- swipl's program's member/2 is
%% user's, the library's out of sight. with_output_to/2 runs its goal as a
%% query of its own, as swipl's C does, so a library call in it is printed --
%% swipl puts a frame of the goal between. call_limited/3's goal is in its
%% context, as call_with_inference_limit/3's clause has it. print_message/2
%% and async_workers/1 are a library's that says generate_debug_info false
own_lines :-
    scratch(D),
    own(D, joined, [ 'j(X) :- member(X, [1]).', 'member(z, [z]).' ], 'j(X)',
        p('Call', 3, '''$member_''([],_,1)'), printed,
        'a program''s clause for member/2 prints what the library''s clause calls'),
    %% the same read after the library's (a `run' file's first directive
    %% reads the libraries): the program's clause decides again, where the
    %% one above is member/2's first and the library's joins it
    own(D, joined2, [ ':- true.', 'j(X) :- member(X, [1]).', 'member(z, [z]).' ], 'j(X)',
        p('Call', 3, '''$member_''([],_,1)'), printed,
        'and so does one read after the library''s, a directive having read it'),
    own(D, wo, [ 'wo(S) :- with_output_to(string(S), (member(X, [1]), write(X))).' ], 'wo(S)',
        p('Call', 3, 'member(_,[1])'), printed,
        'with_output_to/2''s goal is a query of its own: a library call in it is printed'),
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
    shl(['rm -rf ', D]).

own(D, Base, Lines, Q, Line, Expect, Name) :-
    atomic_list_concat([D, '/', Base, '.pl'], F),
    fixture(F, Lines),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' run ', F, ' "trace, ( ', Q, ' -> true ; true ), notrace" 2>&1 >/dev/null'], Cmd),
    proc_run(Cmd, 30000, Out, _),
    td_ports(Out, Rows),
    ( memberchk(Line, Rows) -> R = printed ; R = hidden ),
    check(Name, R, Expect).

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
