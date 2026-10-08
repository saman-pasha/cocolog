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
:- dynamic aix_g/3.

main :-
    scratch(D),
    linear_backtracking(D), deep_recursion(D), sorting(D), any_argument(D), still_the_answers,
    in_registers, guards,
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

%% sort/4 was an insertion sort -- "n is small in every use this has" --
%% and keysort/2 is sort/4 at key 1, so a keysort was quadratic: 20 000
%% pairs in a second, 35 000 in ten, and the reasoning tagger's judge
%% paid 42 seconds a process to build its lexicon. A merge sort since
%% 1.2.40; the guard is the same shape as the ones above, a child under
%% a timeout with a wide margin -- 60 000 pairs sort in about 20 ms and
%% took about ten seconds -- and the stability bagof/3 needs is pinned
%% in-process beside it.
sorting(D) :-
    section('sorting stays n log n'),
    atom_concat(D, '/ksort.pl', F),
    fixture(F, [ 'main :- numlist(1, 60000, L), findall(K-I, ( member(I, L), K is (I * 7919) mod 10007 ), Ps),',
                 '    keysort(Ps, S), length(S, N), S = [K1-_|_], last(S, Kn-_), ( K1 =< Kn -> write(N) ; write(unsorted) ), nl.' ]),
    last_line_of(F, main, 4000, G),
    check('60000 pairs keysort inside four seconds, the old sort needing ten', G, '60000'),
    sort(1, @=<, [b-1, a-1, b-2, a-2, c-1, a-3], Stable),
    check('and equal keys keep their arrival order', Stable, [a-1, a-2, a-3, b-1, b-2, c-1]),
    sort(1, @<, [b-1, a-1, b-2, a-2, c-1, a-3], First),
    check('without duplicates the first of a key stays', First, [a-1, b-1, c-1]),
    sort(1, @>=, [b-1, a-1, b-2, a-2, c-1, a-3], Desc),
    check('descending, still stable', Desc, [c-1, b-1, b-2, a-1, a-2, a-3]).

%% A CALL IS KEYED ON WHICHEVER BOUND ARGUMENT CHOOSES (1.9.1). The first
%% was the only one: a lookup by the second argument walked the predicate
%% head by head, and a table whose first argument most clauses share walked
%% that argument's whole chain -- from its head at every retry, so even
%% backtracking through one key's clauses was quadratic -- which once cost
%% the translator four minutes a sentence. Children under a timeout with a
%% wide margin again: 50 000 lookups by the second argument take a fraction
%% of a second and took about forty, the same through a shared first
%% argument hours, and the walk through one key's 200 000 clauses minutes.
any_argument(D) :-
    section('a call is keyed on whichever bound argument chooses'),
    atom_concat(D, '/aix.pl', F),
    fixture(F, [ ':- dynamic f/2, w/3.',
                 'fill(N) :- forall(between(1, N, I), ( atom_concat(k, I, K), assertz(f(I, K)),',
                 '    atom_concat(m, I, M), assertz(w(es, K, M)) )).',
                 'second :- fill(50000), forall(between(1, 50000, I), ( atom_concat(k, I, K), f(X, K), X =:= I )),',
                 '    write(done), nl.',
                 'shared :- fill(50000), forall(between(1, 50000, I), ( atom_concat(k, I, K), w(es, K, _) )),',
                 '    write(done), nl.',
                 'walk :- fill(200000), findall(K, w(es, K, _), Ks), length(Ks, 200000),',
                 '    findall(K, w(es, K, _), _), write(done), nl.' ]),
    last_line_of(F, second, 15000, G1),
    check('50000 lookups by the second argument of 50000 facts', G1, done),
    last_line_of(F, shared, 15000, G2),
    check('...and by the second when every first argument is the same', G2, done),
    last_line_of(F, walk, 15000, G3),
    check('backtracking through one key''s 200000 clauses stays linear', G3, done),
    %% and the answers come in the program's order whichever argument chose:
    %% a clause whose indexed argument is a variable is a candidate for every
    %% key, and asserta, retract and assertz keep every table true
    forall(between(1, 10, I4), assertz(aix_g(I4, a, x))),
    assertz(aix_g(11, _, y)),
    forall(between(12, 20, I5), assertz(aix_g(I5, b, z))),
    assertz(aix_g(21, a, last)),
    findall(I6-T6, aix_g(I6, a, T6), L6),
    check('by the second argument, a variable head among them, in order', L6,
          [1-x, 2-x, 3-x, 4-x, 5-x, 6-x, 7-x, 8-x, 9-x, 10-x, 11-y, 21-last]),
    findall(I7, aix_g(I7, c, _), L7),
    check('a key no head has finds only the variable head', L7, [11]),
    asserta(aix_g(0, a, first)), findall(I8, aix_g(I8, a, _), L8),
    check('asserta puts its clause first in every table', L8, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 21]),
    retract(aix_g(5, a, x)), findall(I9, aix_g(I9, a, _), L9),
    check('retract takes it out of every table', L9, [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 21]),
    assertz(aix_g(22, a, z)), findall(I10, aix_g(I10, a, _), L10),
    check('assertz adds it to every table', L10, [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 21, 22]),
    findall(I11, aix_g(I11, _, z), L11),
    check('and the third argument has a table of its own', L11, [12, 13, 14, 15, 16, 17, 18, 19, 20, 22]).

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

%% A CALL MADE IN REGISTERS IS THE CALL IT WAS (1.9.1). A clause whose first
%% goal is a plain predicate writes that goal's arguments into the engine's
%% registers instead of building it, and the next step tries the callee
%% from them; anything that needs the goal as a term -- a choice frame, an
%% error, a predicate with no clauses -- builds it from them first. Each
%% check below goes through one of those turns. A first goal whose callee
%% has two clauses or more with a variable first argument keeps its term
%% form (`cc_regs_worth'), so the callees here are keyed. AND ONLY A CALLEE
%% STAMPED AS A PLAIN PREDICATE is called from the registers, which its
%% first call does (`fgen'): so each goal is asked twice and the second
%% answer is the one checked (`twice/3') -- asked once, three of these
%% checks stayed green with the register path's choice frame skipping a
%% clause.
rg_p(X) :- rg_q(X).
rg_q(1).
rg_q(2).
rg_q(3).

rg_s(A, B) :- rg_t(f(A, [x|T], 2.5, "s"), T, B).
rg_t(f(1, [x, y], 2.5, S), [y], S).

rg_v(Y) :- rg_w(Z, Z, Y), Z == b.
rg_w(X, b, X).

rg_u :- rg_nowhere(1, f(x)).

rg_c(X) :- rg_d(k, X).
rg_d(k, X) :- rg_e(X), !.
rg_d(j, none).
rg_e(1).
rg_e(2).

rg_n(0, A, A) :- !.
rg_n(N, A0, A) :- rg_step(N, A0, N1, A1), rg_n(N1, A1, A).
rg_step(N, A0, N1, A1) :- N1 is N - 1, A1 is A0 + N.

%% every answer of GOAL as TEMPLATE, the second time it is asked
twice(Template, Goal, L) :- findall(Template, Goal, _), findall(Template, Goal, L).

in_registers :-
    section('a call made in registers is the call it was'),
    twice(X1, rg_p(X1), L1),
    check('a first goal with three clauses gives each answer, in order', L1, [1, 2, 3]),
    twice(A2-B2, rg_s(A2, B2), L2),
    check('nested structures, a float and a string reach the callee whole', L2, [1-"s"]),
    twice(Y3, rg_v(Y3), L3),
    check('a variable met first in the goal is one variable, bound by the callee', L3, [b]),
    catch(rg_u, error(existence_error(procedure, P4), _), true),
    catch(rg_u, error(existence_error(procedure, P5), _), true),
    check('a goal with no clauses raises naming itself', P4, rg_nowhere/2),
    check('...the second time too, when it is built from the registers', P5, rg_nowhere/2),
    twice(X6, call(rg_p, X6), L6),
    check('call/N reaches such a clause and gets every answer', L6, [1, 2, 3]),
    twice(X7, rg_c(X7), L7),
    check('a cut in the callee cuts its own choices and no more', L7, [1]),
    rg_n(100000, 0, S8),
    check('a deterministic loop through registers keeps its answer', S8, 5000050000).

%% THE GUARDS (1.9.1). The arithmetic and type tests a body starts with are
%% run as its clause is entered, over the clause's own variables, instead of
%% being built as goals and stepped through -- and they must answer exactly
%% what the step answers, including where they cannot and leave the goal to
%% it (a float, an unbound variable, a zero divisor). Each operator and each
%% test has a clause whose body is that one guard; the same goal is also
%% run through the step (`gd_ref/2', whose `is' is not the first goal, so
%% it is never a guard), and the two must agree for every pair of values,
%% errors included.
gd_bin(plus, X, Y, R) :- R is X + Y.
gd_bin(minus, X, Y, R) :- R is X - Y.
gd_bin(times, X, Y, R) :- R is X * Y.
gd_bin(intdiv, X, Y, R) :- R is X // Y.
gd_bin(div, X, Y, R) :- R is X div Y.
gd_bin(mod, X, Y, R) :- R is X mod Y.
gd_bin(rem, X, Y, R) :- R is X rem Y.
gd_bin(min, X, Y, R) :- R is min(X, Y).
gd_bin(max, X, Y, R) :- R is max(X, Y).
gd_bin(shr, X, Y, R) :- R is X >> Y.
gd_bin(shl, X, Y, R) :- R is X << Y.
gd_bin(and, X, Y, R) :- R is X /\ Y.
gd_bin(or, X, Y, R) :- R is X \/ Y.
gd_bin(xor, X, Y, R) :- R is X xor Y.
gd_bin(nest, X, Y, R) :- R is (X * 31 + Y) mod 1000003 - min(X, -Y).

gd_un(neg, X, R) :- R is -X.
gd_un(pos, X, R) :- R is +(X).
gd_un(not, X, R) :- R is \X.
gd_un(abs, X, R) :- R is abs(X).
gd_un(sign, X, R) :- R is sign(X).

gd_cmp(lt, X, Y) :- X < Y.
gd_cmp(gt, X, Y) :- X > Y.
gd_cmp(le, X, Y) :- X =< Y.
gd_cmp(ge, X, Y) :- X >= Y.
gd_cmp(eq, X, Y) :- X =:= Y.
gd_cmp(ne, X, Y) :- X =\= Y.
gd_cmp(sum, X, Y) :- X + 1 > Y - 1.

gd_type(var, X) :- var(X).
gd_type(nonvar, X) :- nonvar(X).
gd_type(atom, X) :- atom(X).
gd_type(integer, X) :- integer(X).
gd_type(number, X) :- number(X).
gd_type(atomic, X) :- atomic(X).
gd_type(compound, X) :- compound(X).

gd_expr(plus, X, Y, X + Y).        gd_expr(minus, X, Y, X - Y).
gd_expr(times, X, Y, X * Y).       gd_expr(intdiv, X, Y, X // Y).
gd_expr(div, X, Y, X div Y).       gd_expr(mod, X, Y, X mod Y).
gd_expr(rem, X, Y, X rem Y).       gd_expr(min, X, Y, min(X, Y)).
gd_expr(max, X, Y, max(X, Y)).     gd_expr(shr, X, Y, X >> Y).
gd_expr(shl, X, Y, X << Y).        gd_expr(and, X, Y, X /\ Y).
gd_expr(or, X, Y, X \/ Y).         gd_expr(xor, X, Y, X xor Y).
gd_expr(nest, X, Y, (X * 31 + Y) mod 1000003 - min(X, -Y)).
gd_uexpr(neg, X, -X).    gd_uexpr(pos, X, +(X)).    gd_uexpr(not, X, \X).
gd_uexpr(abs, X, abs(X)).    gd_uexpr(sign, X, sign(X)).
gd_cexpr(lt, X, Y, X < Y).    gd_cexpr(gt, X, Y, X > Y).
gd_cexpr(le, X, Y, X =< Y).   gd_cexpr(ge, X, Y, X >= Y).
gd_cexpr(eq, X, Y, X =:= Y).  gd_cexpr(ne, X, Y, X =\= Y).
gd_cexpr(sum, X, Y, X + 1 > Y - 1).

%% through the step: the first goal is not arithmetic, so none is a guard
gd_ref(E, R) :- true, R is E.
gd_test(G) :- true, call(G).

%% an outcome, errors included, with the error's context left out
gd_out(G, R, Out) :-
    catch(( call(G) -> Out = R ; Out = failed ), error(F, _), Out = error(F)).

gd_values([-7, -1, 0, 1, 3, 40, 1000000007, -1000000007, 1099511627776, 2.5, foo, _]).

gd_mismatch(Kind, Name, X, Y) :-
    gd_values(Vs), member(X, Vs), member(Y, Vs),
    (   Kind = bin, gd_expr(Name, X, Y, E),
        gd_out(gd_bin(Name, X, Y, R1), R1, O1), gd_out(gd_ref(E, R2), R2, O2)
    ;   Kind = cmp, gd_cexpr(Name, X, Y, E),
        gd_out(gd_cmp(Name, X, Y), yes, O1), gd_out(gd_test(E), yes, O2)
    ),
    O1 \== O2.
gd_mismatch(un, Name, X, none) :-
    gd_values(Vs), member(X, Vs), gd_uexpr(Name, X, E),
    gd_out(gd_un(Name, X, R1), R1, O1), gd_out(gd_ref(E, R2), R2, O2),
    O1 \== O2.
gd_mismatch(type, Name, X, none) :-
    member(X, [_, 3, 2.5, foo, "s", [], [a], f(x)]),
    member(Name, [var, nonvar, atom, integer, number, atomic, compound]),
    gd_out(gd_type(Name, X), yes, O1), G =.. [Name, X], gd_out(gd_test(G), yes, O2),
    O1 \== O2.

%% falling through to the next clause, a bound left side, an integer on the
%% left, a variable a guard makes and the goals after it read
gd_cls(X, small) :- X < 10.
gd_cls(X, medium) :- X < 100.
gd_cls(_, large).
gd_eq(X, Y) :- X is Y + 1.
gd_four(Y) :- 4 is Y + 1.
gd_fresh(X, L) :- Y is X * 2, Z is Y + 1, L = [Y, Z].
gd_loop(0) :- !.
gd_loop(N) :- N > 0, N1 is N - 1, gd_loop(N1).

gd_inferences(G, I) :-
    statistics(inferences, I0), call(G), statistics(inferences, I1), I is I1 - I0.

guards :-
    section('guards: the arithmetic a body starts with, run as it is entered'),
    findall(K-N-X-Y, ( member(K, [bin, cmp, un, type]), gd_mismatch(K, N, X, Y) ), L1),
    check('every operator and test answers as the step answers, errors included', L1, []),
    findall(C2, ( member(X2, [5, 50, 500]), gd_cls(X2, C2) ), L2),
    check('a guard that fails sends the call on to the next clause', L2,
          [small, medium, large, medium, large, large]),
    findall(T3, ( member(A3-B3, [4-3, 5-3, 4.0-3]), ( gd_eq(A3, B3) -> T3 = yes ; T3 = no ) ), L3),
    check('an is/2 whose left is bound compares, as unification does', L3, [yes, no, no]),
    findall(T4, ( member(B4, [3, 2]), ( gd_four(B4) -> T4 = yes ; T4 = no ) ), L4),
    check('...and an integer on its left the same', L4, [yes, no]),
    gd_fresh(3, L5), gd_fresh(3, L5b),
    check('a variable a guard makes is read by the goals after it', L5-L5b, [6, 7]-[6, 7]),
    %% 1.9.0 counted these, goal by goal, and so does this engine
    gd_inferences(gd_loop(1000), I6), gd_inferences(gd_loop(1000), I6b),
    check('each guard is still an inference', I6-I6b, 3004-3004),
    gd_inferences(findall(C7, ( member(X7, [5, 50, 500]), gd_cls(X7, C7) ), _), I7),
    check('a guard that fails is one too', I7, 23),
    %% an inference limit stops at the same goal whether it falls before,
    %% among or after the guards: 1.9.0's answers for every ceiling to 12
    findall(L8-U8-R8, ( between(1, 12, L8), call_metered(gd_loop(3), L8, U8, R8) ), M8),
    findall(L9-U9-inference_limit_exceeded, ( between(1, 11, L9), U9 is L9 + 1 ), E8a),
    append(E8a, [12-12-true], E8),
    check('an inference limit stops where it always stopped', M8, E8).
