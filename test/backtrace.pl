%% An error nothing caught is followed, on stderr, by WHERE IT WAS RAISED
%% (1.10.17): the goal that raised it, and then -- at full speed -- the
%% goals each engine had left to run, or -- under `--backtrace', a trace
%% that prints nothing, or `--trace' -- every call it was made in, as SWI
%% writes a frame:
%%
%%     ERROR: -s main: Arithmetic: evaluation error: `zero_divisor'
%%     ERROR: In:
%%     ERROR:   [5] _G66 is 2/(1-1)
%%     ERROR:   [4] oops(2,1,_G66)
%%
%% The lines are written by `coco_throw' before it unwinds, and only for a
%% ball no catch on the chain would take (lib/solve.cicili,
%% `coco_bt_capture'); the host that reports the error prints them after
%% its message: the CLI's goal (`-s', `run', `query', the REPL), a
%% directive, an initialization goal.
%%
%%     cocolog -s test/backtrace.pl        from the checkout root
%%
%% Every check is a child: what is pinned is another process's stderr. A
%% variable's `_G' number is a heap position and is taken out before a
%% comparison.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    untraced(D), traced(D), quiet(D), caught(D), nested(D), environment(D),
    deep(D), loads(D), queries(D), cut(D),
    shl(['rm -rf ', D]),
    checks_done.

%% stderr of `cocolog ARGS', the scratch directory and the `_G' numbers
%% taken out, and the exit status
bt_err(D, Args, Err, Rc) :-
    sh_join([Args, ' 2>&1 >/dev/null'], A),
    cocolog_run(A, Raw, Rc),
    atom_concat(D, '/', Prefix),
    re_replace_atom(Prefix, '', Raw, R1),
    re_replace_atom('_G[0-9]+', '_G', R1, Err).

lines(Ls, Text) :- atomic_list_concat(Ls, '\n', Text).

note(['ERROR: Note: what each goal had left to run, not the calls it was made in;',
      'ERROR: run with --backtrace to see those.']).

%% the program the shapes are shown on
bt1(D, F) :-
    atom_concat(D, '/bt1.pl', F),
    fixture(F, ['main :- step1(3), write(done), nl.',
                'step1(N) :- N1 is N - 1, step2(N1, R), write(R), nl.',
                'step2(N, R) :- member(X, [1,2]), oops(N, X, R).',
                'oops(N, X, R) :- R is N / (X - X).']).

untraced(D) :-
    section('at full speed: the goal that raised, and what was left to run'),
    bt1(D, F),
    sh_join(['-s ', F], A1), bt_err(D, A1, E1, Rc1),
    note(N1),
    append(['ERROR: -s main: Arithmetic: evaluation error: `zero_divisor''',
            'ERROR: In:',
            'ERROR:   _G is 2/(1-1)',
            'ERROR:   then write(_G)',
            'ERROR:   then nl',
            'ERROR:   then write(done)',
            'ERROR:   then nl'], N1, W1), lines(W1, T1),
    check('the message, then the goal that raised and the goals after it', E1, T1),
    check('...and the exit status is still 2', Rc1, 2).

traced(D) :-
    section('--backtrace: every call it was raised in, as [Depth] Goal'),
    bt1(D, F),
    Stack = ['ERROR: In:',
             'ERROR:   [5] _G is 2/(1-1)',
             'ERROR:   [4] oops(2,1,_G)',
             'ERROR:   [3] step2(2,_G)',
             'ERROR:   [2] step1(3)',
             'ERROR:   [1] main'],
    sh_join(['--backtrace -s ', F], A1), bt_err(D, A1, E1, Rc1),
    lines(['ERROR: -s main: Arithmetic: evaluation error: `zero_divisor'''|Stack], T1),
    check('the stack SWI writes, depth by depth, and nothing traced on the way', E1, T1),
    check('...and the exit status is still 2', Rc1, 2),
    %% the trace that prints keeps the same markers
    sh_join(['--trace -s ', F], A2), bt_err(D, A2, E2, _),
    lines(Stack, T2), atom_concat('\n', T2, T2n),
    ( atom_concat(_, T2n, E2) -> V2 = yes ; V2 = E2 ),
    check('--trace: the trace, then the same stack after the error', V2, yes),
    %% a run that raises nothing is the run it was
    atom_concat(D, '/fine.pl', G),
    fixture(G, ['main :- findall(X, member(X, [a,b]), L), with_output_to(atom(A), write(L)), write(A), nl.']),
    sh_join(['--backtrace -s ', G, ' 2>&1'], A3), cocolog_run(A3, O3, Rc3),
    check('--backtrace changes nothing of a run that does not raise', Rc3-O3, 0-'[a,b]').

quiet(D) :-
    section('--no-backtrace: the message alone'),
    bt1(D, F),
    sh_join(['--no-backtrace -s ', F], A1), bt_err(D, A1, E1, Rc1),
    check('only the message', E1, 'ERROR: -s main: Arithmetic: evaluation error: `zero_divisor'''),
    check('...and the exit status is still 2', Rc1, 2).

caught(D) :-
    section('a ball a catch takes writes nothing; the one nothing caught names itself'),
    atom_concat(D, '/caught.pl', F),
    %% the second catch takes its ball only once X is unbound again: the
    %% throw's question, asked before anything unwinds, says nobody would,
    %% and the lines it writes must never be printed
    %% and the unknown procedure is met twice: the second call is stamped
    %% a plain predicate and goes to the store without the module walk
    %% that named the first
    fixture(F, ['main :- catch(atom_length(_, _), _, true),',
                '        catch(( X = 1, throw(f(2)) ), f(X), true),',
                '        write(ok), nl, a(1).',
                'a(N) :- write(N), nl, catch(nosuch(0), _, true), atom_length(abc, _),',
                '        nosuch(N), write(never).']),
    sh_join(['-s ', F], A1), bt_err(D, A1, E1, _),
    note(N1),
    append(['ERROR: -s main: Unknown procedure: nosuch/1',
            'ERROR: In:',
            'ERROR:   nosuch(1)',
            'ERROR:   then write(never)'], N1, W1), lines(W1, T1),
    check('the unknown procedure is the goal that raised, once, and not the caught ones', E1, T1),
    atom_concat(D, '/thrown.pl', G),
    fixture(G, ['main :- write(x), nl, throw(my_ball), write(y).']),
    sh_join(['-s ', G], A2), bt_err(D, A2, E2, _),
    append(['ERROR: -s main: Unknown message: my_ball',
            'ERROR: In:',
            'ERROR:   throw(my_ball)',
            'ERROR:   then write(y)'], N1, W2), lines(W2, T2),
    check('a throw/1 of the program\'s is the goal that raised', E2, T2),
    %% the dispatch's own raises, each after a builtin that left its goal
    %% as the one in flight
    forall(member(Name-Body-Msg-Culprit,
                  [unbound-'p(_)'-'Arguments are not sufficiently instantiated'-'_G',
                   number-'p(1)'-'Type error: `callable\' expected, found `1\''-'1',
                   closure-'call(1, x)'-'Type error: `callable\' expected, found `1\''-'call(1,x)']),
           ( atom_concat(D, '/', D1), atomic_list_concat([D1, Name, '.pl'], Fx),
             atomic_list_concat(['main :- write(a), nl, atom_length(abc, _), ', Body, ', write(b).'], M),
             fixture(Fx, [M, 'p(G) :- atom_length(abc, _), G, write(c).']),
             sh_join(['-s ', Fx], Ax), bt_err(D, Ax, Ex, _),
             (   Name == closure
             ->  After = ['ERROR:   then write(b)']
             ;   After = ['ERROR:   then write(c)', 'ERROR:   then write(b)']
             ),
             atomic_list_concat(['ERROR: -s main: ', Msg], L1),
             atomic_list_concat(['ERROR:   ', Culprit], L3),
             append([[L1, 'ERROR: In:', L3], After, N1], Wx), lines(Wx, Tx),
             atomic_list_concat(['a goal that is ', Name, ' is the goal that raised'], Lx),
             check(Lx, Ex, Tx) )).

nested(D) :-
    section('inside a builtin\'s engine: its goals, then the builtin and the goals after it'),
    atom_concat(D, '/fa.pl', F),
    fixture(F, ['main :- run(3, L), write(L), nl.',
                'run(N, L) :- findall(Y, gen(N, Y), L0), length(L0, K), L = K-L0.',
                'gen(N, Y) :- between(1, N, X), check(X, Y).',
                'check(X, Y) :- X > 2, !, Y is foo + X.',
                'check(X, X).']),
    sh_join(['-s ', F], A1), bt_err(D, A1, E1, _),
    note(N1),
    append(['ERROR: -s main: Arithmetic: `foo/0'' is not a function',
            'ERROR: In:',
            'ERROR:   _G is foo+3',
            'ERROR:   findall(_G,gen(3,_G),_G)',
            'ERROR:   then length(_G,_G)',
            'ERROR:   then _G=_G-_G',
            'ERROR:   then write(_G)',
            'ERROR:   then nl'], N1, W1), lines(W1, T1),
    check('findall/3: the goal inside that raised, then the findall and its caller\'s goals', E1, T1),
    sh_join(['--backtrace -s ', F], A2), bt_err(D, A2, E2, _),
    lines(['ERROR: -s main: Arithmetic: `foo/0'' is not a function',
           'ERROR: In:',
           'ERROR:   [5] _G is foo+3',
           'ERROR:   [4] check(3,_G)',
           'ERROR:   [3] gen(3,_G)',
           'ERROR:   [3] findall(_G,gen(3,_G),_G)',
           'ERROR:   [2] run(3,_G)',
           'ERROR:   [1] main'], T2),
    check('...and traced, the calls inside it and outside it', E2, T2),
    atom_concat(D, '/wo.pl', G),
    fixture(G, ['main :- with_output_to(codes(C), inner), atom_codes(A, C), write(A), nl.',
                'inner :- write(hi), mid(2), write(bye).',
                'mid(N) :- N1 is N * 2, atom_length(_, N1), write(N1).']),
    sh_join(['--backtrace -s ', G], A3), bt_err(D, A3, E3, _),
    lines(['ERROR: -s main: Arguments are not sufficiently instantiated',
           'ERROR: In:',
           'ERROR:   [4] atom_length(_G,4)',
           'ERROR:   [3] mid(2)',
           'ERROR:   [2] inner',
           'ERROR:   [2] with_output_to(codes(_G),inner)',
           'ERROR:   [1] main'], T3),
    check('with_output_to/2: its goal traced at the depth it is called from', E3, T3),
    atom_concat(D, '/me.pl', H),
    fixture(H, ['main :- call_metered(loop(2), 1000, U, R), write(U-R), nl.',
                'loop(0) :- atom_codes(_, _).',
                'loop(N) :- N1 is N - 1, loop(N1), write(N).']),
    sh_join(['-s ', H], A4), bt_err(D, A4, E4, _),
    append(['ERROR: -s main: Arguments are not sufficiently instantiated',
            'ERROR: In:',
            'ERROR:   atom_codes(_G,_G)',
            'ERROR:   then write(1)',
            'ERROR:   then write(2)',
            'ERROR:   call_metered(loop(2),1000,_G,_G)',
            'ERROR:   then write(_G-_G)',
            'ERROR:   then nl'], N1, W4), lines(W4, T4),
    check('call_metered/4: the same', E4, T4).

environment(D) :-
    section('a goal left in an environment names its clause'),
    atom_concat(D, '/env.pl', F),
    fixture(F, ['main :- len([a,b|_], N), write(N), nl.',
                'len(L, N) :- var(L), !, atom_length(L, N).',
                'len(L, N) :- ( L = [_|T] -> len(T, N0), N is N0 + 1 ; N = 0 ).']),
    sh_join(['-s ', F], A1), bt_err(D, A1, E1, _),
    note(N1),
    append(['ERROR: -s main: Arguments are not sufficiently instantiated',
            'ERROR: In:',
            'ERROR:   atom_length(_G,_G)',
            'ERROR:   then _G is _G+1   (clause 2 of len/2)',
            'ERROR:   then _G is _G+1   (clause 2 of len/2)',
            'ERROR:   then write(_G)',
            'ERROR:   then nl'], N1, W1), lines(W1, T1),
    check('each activation of the clause, named', E1, T1).

deep(D) :-
    section('a deep recursion: the first eight, a count, the last four'),
    atom_concat(D, '/deep.pl', F),
    fixture(F, ['main :- count(30).',
                'count(0) :- X is 1/0, write(X).',
                'count(N) :- N1 is N - 1, count(N1), write(N), nl.']),
    sh_join(['-s ', F], A1), bt_err(D, A1, E1, _),
    note(N1),
    append(['ERROR: -s main: Arithmetic: evaluation error: `zero_divisor''',
            'ERROR: In:',
            'ERROR:   _G is 1/0',
            'ERROR:   then write(_G)',
            'ERROR:   then write(1)', 'ERROR:   then nl',
            'ERROR:   then write(2)', 'ERROR:   then nl',
            'ERROR:   then write(3)', 'ERROR:   then nl',
            'ERROR:   then write(4)',
            'ERROR:   ... 49 more ...',
            'ERROR:   then write(29)', 'ERROR:   then nl',
            'ERROR:   then write(30)', 'ERROR:   then nl'], N1, W1), lines(W1, T1),
    check('at full speed', E1, T1),
    sh_join(['--backtrace -s ', F], A2), bt_err(D, A2, E2, _),
    lines(['ERROR: -s main: Arithmetic: evaluation error: `zero_divisor''',
           'ERROR: In:',
           'ERROR:   [33] _G is 1/0',
           'ERROR:   [32] count(0)', 'ERROR:   [31] count(1)', 'ERROR:   [30] count(2)',
           'ERROR:   [29] count(3)', 'ERROR:   [28] count(4)', 'ERROR:   [27] count(5)',
           'ERROR:   [26] count(6)', 'ERROR:   [25] count(7)',
           'ERROR:   ... 20 more ...',
           'ERROR:   [4] count(28)', 'ERROR:   [3] count(29)', 'ERROR:   [2] count(30)',
           'ERROR:   [1] main'], T2),
    check('...and traced', E2, T2).

loads(D) :-
    section('a load\'s reports: a directive, an initialization goal'),
    note(N0),
    atom_concat(D, '/dir.pl', F1),
    fixture(F1, ['go :- helper(1).',
                 'helper(X) :- Y is X / 0, write(Y).',
                 ':- go.',
                 'main :- write(loaded), nl.']),
    sh_join(['-s ', F1], A1), bt_err(D, A1, E1, _),
    append(['ERROR: dir.pl:3:',
            'ERROR:    Arithmetic: evaluation error: `zero_divisor''',
            'ERROR: In:',
            'ERROR:   _G is 1/0',
            'ERROR:   then write(_G)'], N0, W1), lines(W1, T1),
    check('a directive that raised: its message, then where', E1, T1),
    atom_concat(D, '/undef.pl', F2),
    fixture(F2, [':- nosuch_directive.', 'main.']),
    sh_join(['-s ', F2], A2), bt_err(D, A2, E2, _),
    lines(['ERROR: undef.pl:1:', 'ERROR:    Unknown procedure: nosuch_directive/0'], T2),
    check('a directive that is the goal that raised says nothing the message does not', E2, T2),
    atom_concat(D, '/init.pl', F3),
    fixture(F3, [':- initialization(main, main).',
                 'main :- write(hello), nl, deep(2).',
                 'deep(0) :- throw(bottom).',
                 'deep(N) :- N1 is N - 1, deep(N1), write(N), nl.']),
    sh_join(['-s ', F3], A3), bt_err(D, A3, E3, Rc3),
    append(['ERROR: init.pl:1: main: raised exception:',
            'ERROR: Unknown message: bottom',
            'ERROR: In:',
            'ERROR:   throw(bottom)',
            'ERROR:   then write(1)', 'ERROR:   then nl',
            'ERROR:   then write(2)', 'ERROR:   then nl'], N0, W3), lines(W3, T3),
    check('initialization(main, main): the same after its two lines', E3, T3),
    check('...and the exit status is 2', Rc3, 2),
    %% a load under a catch reports its directive's error itself: no catch
    %% outside it can take the ball, so its throw writes the lines
    atom_concat(D, '/under.pl', F4),
    sh_join(['main :- catch(use_module(''', F1, '''), _, true), write(after), nl.'], M4),
    fixture(F4, [M4]),
    sh_join(['-s ', F4], A4), bt_err(D, A4, E4, _),
    lines(W1, T4),
    check('a load under a catch still says where its directive raised', E4, T4),
    %% lines a catch made unprintable are never printed by a report after
    atom_concat(D, '/stale1.pl', F5),
    fixture(F5, [':- catch(( X = 1, throw(f(2)) ), f(X), true).',
                 ':- initialization(foo, bogus).',
                 'main.']),
    sh_join(['-s ', F5], A5), bt_err(D, A5, E5, _),
    ( sub_atom(E5, _, _, _, 'In:') -> V5 = E5 ; V5 = none ),
    check('...not by the next directive\'s report', V5, none),
    atom_concat(D, '/stale2.pl', F6), atom_concat(D, '/stale2b.pl', F6b),
    fixture(F6b, [':- initialization(foo, bogus).']),
    sh_join(['main :- catch(( X = 1, throw(f(2)) ), f(X), true), use_module(''', F6b, '''), write(done), nl.'], M6),
    fixture(F6, [M6]),
    sh_join(['-s ', F6], A6), bt_err(D, A6, E6, _),
    ( sub_atom(E6, _, _, _, 'In:') -> V6 = E6 ; V6 = none ),
    check('...nor by a load the program starts after', V6, none),
    %% nor after an error that is no ball -- call/N past 255 arguments
    %% stops the run where no catch sees it -- in a directive, or in the
    %% program
    Stop = 'length(L, 300), G =.. [foo|L], call(G, a)',
    atom_concat(D, '/stale3.pl', F7),
    sh_join([':- catch(( X = 1, throw(f(2)) ), f(X), true), ', Stop, '.'], M7),
    fixture(F7, [M7, 'main.']),
    sh_join(['-s ', F7], A7), bt_err(D, A7, E7, _),
    lines(['ERROR: stale3.pl:1:', 'ERROR:    call/N: too many arguments'], T7),
    check('...nor after a directive\'s error that is no ball', E7, T7),
    atom_concat(D, '/stale4.pl', F8),
    sh_join(['main :- catch(( X = 1, throw(f(2)) ), f(X), true), ', Stop, '.'], M8),
    fixture(F8, [M8]),
    sh_join(['-s ', F8], A8), bt_err(D, A8, E8, _),
    check('...nor after the program\'s', E8, 'ERROR: -s main: call/N: too many arguments').

queries(D) :-
    section('cocolog query'),
    bt_err(D, 'query ''X is 1/0''', E1, _),
    check('a query that is itself the goal that raised: the message alone', E1,
          'ERROR: ?-: Arithmetic: evaluation error: `zero_divisor'''),
    bt_err(D, 'query ''atom_length(X, Y), write(Y)''', E2, _),
    note(N2),
    append(['ERROR: ?-: Arguments are not sufficiently instantiated',
            'ERROR: In:',
            'ERROR:   atom_length(_G,_G)',
            'ERROR:   then write(_G)'], N2, W2), lines(W2, T2),
    check('...and one with more in it, the backtrace', E2, T2).

cut(D) :-
    section('a goal past 240 characters is cut'),
    atom_concat(D, '/long.pl', F),
    fixture(F, ['main :- length(L, 200), maplist(=(abc), L), atom_length(_, L).']),
    sh_join(['-s ', F, ' 2>&1 >/dev/null'], A1), cocolog_run(A1, Raw, _),
    atomic_list_concat(Ls, '\n', Raw),
    (   member(Line, Ls), sub_atom(Line, 0, _, _, 'ERROR:   atom_length(')
    ->  atom_length(Line, N), ( atom_concat(_, ' ...', Line) -> End = cut ; End = Line )
    ;   N = 0, End = Raw
    ),
    check('the goal\'s line is 240 characters of it and an ellipsis', N-End, 253-cut).
