%% The engine's COMPLEXITY, which no other case here checks.
%%
%% Every other test asks whether an answer is right. These ask whether it
%% arrives in the time the algorithm says it should -- and they exist because
%% a term representation can be perfectly correct and quadratic, which is
%% exactly what this one was until `coco_make' started dereferencing the
%% arguments it stores.
%%
%% THE GUARD IS A TIMEOUT WITH A HUNDRED-FOLD MARGIN, not a stopwatch with a
%% threshold. `between(1, 100000, _), fail' takes about 230ms here and took
%% MINUTES before the fix; a limit of 30 seconds passes on any machine that
%% can run the suite at all and fails the moment the chain comes back. A
%% ratio test between two sizes would be more precise and would also fail on
%% a loaded CI box, which is a worse trade for a property this coarse.
%%
%% WHAT WENT WRONG, so the next person recognises it: a compound's argument
%% was stored as a REF cell pointing at whatever index it was handed, and
%% `coco_arg' hands back a REF. So every structure built on a previous one --
%% the continuation `$k(Goal, Barrier, Rest)' above all -- added a link, and
%% `coco_deref' walked the whole chain on every engine step. A recursion
%% 3000 deep left a chain 8999 links long and 85% of the program's
%% instructions were in deref.
%%
%%     cocolog -s test/engine.pl        from the checkout root
%%
%% THE FOUR TIMED RUNS ARE STILL CHILDREN, on purpose: a goal that may never
%% return has to be run under something that can kill it, and proc_run/4's
%% timeout is that something -- in-process there would be nothing to stop a
%% quadratic engine but run.sh's hour. The four answer checks are in-process.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    linear_backtracking(D), deep_recursion(D), still_the_answers,
    shl(['rm -rf ', D]),
    checks_done.

%% a child `cocolog run FILE main' under a timeout, its last line
last_line_of(File, Goal, TimeoutMs, Last) :-
    cocolog(C),
    sh_join([C, ' run ', File, ' ', Goal, ' 2>/dev/null'], Cmd),
    proc_run(Cmd, TimeoutMs, Out, _),
    (   chomp(Out, Body), codes_lines(Body, Lines), Lines \== [], last(Lines, L), atom_codes(Last, L)
    ->  true
    ;   Last = nothing
    ).

%% milliseconds a child run took
ms_of(File, Goal, TimeoutMs, Ms) :-
    get_time(T0), last_line_of(File, Goal, TimeoutMs, _), get_time(T1),
    Ms is round((T1 - T0) * 1000).

linear_backtracking(D) :-
    section('deep backtracking stays linear'),
    atom_concat(D, '/between.pl', F1),
    fixture(F1, ['main :- ( between(1, 100000, _), fail ; true ), write(done), nl.']),
    last_line_of(F1, main, 30000, G1),
    check('100000 solutions from between/3 finish at all', G1, done),
    %% findall over the same range: the collection walks the continuation too,
    %% and was 9.2 SECONDS at 20000 where it is now 53ms.
    atom_concat(D, '/findall.pl', F2),
    fixture(F2, ['main :- findall(X, between(1, 100000, X), L), length(L, 100000), write(done), nl.']),
    last_line_of(F2, main, 30000, G2),
    check('and findall over 100000 collects them', G2, done),
    %% THE SHAPE, not just the total. Ten times the work in far less than a
    %% hundred times the time is the difference between linear and quadratic,
    %% and the bound is loose enough that only the quadratic case can fail it.
    atom_concat(D, '/s.pl', FS), fixture(FS, ['main :- ( between(1, 10000, _), fail ; true ).']),
    atom_concat(D, '/b.pl', FB), fixture(FB, ['main :- ( between(1, 100000, _), fail ; true ).']),
    ms_of(FS, main, 60000, Small), ms_of(FB, main, 120000, Big),
    format("     10000 in ~wms, 100000 in ~wms~n", [Small, Big]),
    ( Small > 0, Big < Small * 25 -> Shape = 'linear-ish' ; Shape = quadratic ),
    check('ten times the range costs well under ten times squared', Shape, 'linear-ish').

deep_recursion(D) :-
    section('deep recursion without backtracking'),
    %% This was always fast, and is here so a future fix to the above cannot
    %% quietly trade it away.
    atom_concat(D, '/deep.pl', F),
    fixture(F, [ 'count(0) :- !.',
                 'count(N) :- M is N - 1, count(M).',
                 'main :- count(500000), write(done), nl.' ]),
    last_line_of(F, main, 30000, G),
    check('500000 deep deterministic recursion still finishes', G, done).

still_the_answers :-
    section('and the answers are still the answers'),
    %% A representation change that made everything fast and one thing wrong
    %% would pass every case above. sub_atom/5 and findall/3 both build terms
    %% on terms, which is where the dereferencing happens.
    written(( X1 = f(Y1), Y1 = 7, X1 = f(Z1) ), Z1, G1),
    check('a shared variable is still shared after building', G1, '7'),
    written(( T2 = p(A2, A2), T2 = p(1, B2) ), B2, G2),
    check('an unbound variable in a structure still binds later', G2, '1'),
    written(( member(X3, [1,2,3]), T3 = q(X3), T3 = q(2) -> R3 = X3 ; R3 = none ), R3, G3),
    check('and backtracking still unbinds through a structure', G3, '2'),
    written(findall(A4-B4, member(A4-B4, [1-x, 2-y]), L4), L4, G4),
    check('findall copies, so its answers outlive the search', G4, '[1-x,2-y]').
