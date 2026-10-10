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
    in_registers, guards, environments(D), in_place(D), fused(D),
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

%% family F's clause of kind K over ARGS -- gd_bin/4 or ip_bin/4 (Stage 7,
%% below), and so on -- against the step's answer
gd_call(F, K, Args, G) :- atomic_list_concat([F, '_', K], P), G =.. [P|Args].

gd_mismatch(F, Kind, Name, X, Y) :-
    gd_values(Vs), member(X, Vs), member(Y, Vs),
    (   Kind = bin, gd_expr(Name, X, Y, E), gd_call(F, bin, [Name, X, Y, R1], G1),
        gd_out(G1, R1, O1), gd_out(gd_ref(E, R2), R2, O2)
    ;   Kind = cmp, gd_cexpr(Name, X, Y, E), gd_call(F, cmp, [Name, X, Y], G1),
        gd_out(G1, yes, O1), gd_out(gd_test(E), yes, O2)
    ),
    O1 \== O2.
gd_mismatch(F, un, Name, X, none) :-
    gd_values(Vs), member(X, Vs), gd_uexpr(Name, X, E), gd_call(F, un, [Name, X, R1], G1),
    gd_out(G1, R1, O1), gd_out(gd_ref(E, R2), R2, O2),
    O1 \== O2.
gd_mismatch(F, type, Name, X, none) :-
    member(X, [_, 3, 2.5, foo, "s", [], [a], f(x)]),
    member(Name, [var, nonvar, atom, integer, number, atomic, compound]),
    gd_call(F, type, [Name, X], G1),
    gd_out(G1, yes, O1), G =.. [Name, X], gd_out(gd_test(G), yes, O2),
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
    findall(K-N-X-Y, ( member(K, [bin, cmp, un, type]), gd_mismatch(gd, K, N, X, Y) ), L1),
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

%% ENVIRONMENTS (Stages 5 and 6). A body with a construct among its goals
%% -- an if-then-else, `\+', `once/1', `ignore/1', a disjunction, a `,'
%% inside one -- writes ONE environment when it is entered, after its
%% guards and its first goal, and the goals from there on are reached from
%% it: a call written into the registers from the environment's slots, a
%% cut cut to its barrier, a construct taken apart by the step its goal
%% was, the rest built at entry as they always were. The environment names
%% the clause's compiled code, so a clause retracted while its body runs
%% goes on running the code it was entered with -- the logical update view
%% the copied body gave -- and a compaction of the store keys that code
%% again rather than freeing it.
:- dynamic ev_r/1.
:- dynamic ev_big/0.
ev_s(1, 2).
ev_t(2, 1).
ev_a(1).
ev_d(_).
ev_e(X) :- throw(boom(X)).
ev_c(R) :- ev_a(X), ( ev_d(X) -> catch(ev_e(X), E, R = caught(E)) ; R = none ).
ev_c2(R) :- ev_a(X), ( ev_e(X) ; true ), R = no.
ev_c3(R) :- ev_a(X), catch(ev_e(X), boom(Y), true), ( ev_d(Y) -> R = Y ; R = none ).
ev_k(X) :- ev_m(X), !, ( ev_d(X) -> true ; true ).
ev_k(none).
ev_m(1). ev_m(2).
ev_n.
ev_body(1, ( ev_n -> true ; true )) :- !.
ev_body(N, (ev_n, B)) :- N1 is N - 1, ev_body(N1, B).
%% THE CONSTRUCTS AS UNITS (Stage 6): a cut in a condition cuts the
%% condition alone, one in a branch the clause; a disjunction leaves its
%% other arm; `\+', `once/1' and `ignore/1' are if-then-elses; and a body
%% that starts with guards makes its environment after them.
ev_o(X) :- ev_a(_), ( ev_m(X), !, X > 1 -> true ; X = none ).
ev_p(X) :- ev_a(_), ( ev_d(x) -> ev_m(X), ! ; true ).
ev_p(other).
ev_q(X) :- ev_a(_), ( ev_m(X) ; X = 3 ), X > 0.
ev_u(X, Y) :- ev_m(X), \+ X = 2, once(ev_m(Y)), ignore(fail).
ev_g(X, Y) :- X > 0, Z is X * 2, ( Z > 2 -> Y = big(Z) ; Y = small(Z) ).

%% the same program run with environments and without (`COCOLOG_ENV=0',
%% the stage's arm): backtracking into a choice the environment's goals
%% follow, a cut and an if-then-else after the first goal, a term built
%% from variables the later goals made, and the inference count at the end
ev_both([ 'q(1). q(2). q(3). q(4). q(5). q(6).',
          'w(X, Y) :- Y is X * 10.',
          'add1(A, B) :- B is A + 1.',
          'id(A, A).',
          'v(Y, Z) :- add1(Y, Z0), id(Z0, Z).',
          'p(X, Z) :- q(X), w(X, Y), v(Y, Z), Z > 15.',
          's(X) :- q(X), X > 2, !, id(X, _).',
          't(X, Y) :- q(X), ( X > 3 -> id(X, Y) ; Y = small ).',
          'f(T) :- id(T, f(A, B)), A = 1, id(B, 2).',
          'main :- findall(X-Z, p(X, Z), L1), write(L1), nl, s(X2), write(X2), nl,',
          '        findall(X-Y, t(X, Y), L3), write(L3), nl, f(T4), write(T4), nl,',
          '        statistics(inferences, I), write(I), nl.' ]).

%% and one whose bodies start with guards (Stage 6): an environment after
%% them, a guard that cannot decide -- `2.5 > 1' -- building the body from
%% itself as it always did, a cut inside a disjunction, and a stop at every
%% ceiling to thirty in a recursion like the lookup benchmark's
ev_both6([ 'r(1). r(2). r(3). r(4). r(5).',
           'id(A, A).',
           'g1(X, Y) :- X > 2, ( r(X) -> Y = yes ; Y = no ).',
           'g2(X, L) :- X1 is X + 1, X1 > 0, ( id(X1, L) ; L = alt(X1) ).',
           'g4(X, Y) :- X > 1, ( X > 2 -> Y = a ; Y = b ).',
           'g5(X, Y) :- X >= 0, \\+ X =:= 3, ( r(X), ! ; Y = none ), id(X, Y).',
           'g9(X, Y) :- X > 0, Z is X * 3, ( Z > 9, !, Y = big ; Y = small(Z) ).',
           'g9(_, other).',
           'probe(0, _, A, A) :- !.',
           'probe(M, N, A0, A) :- K is ((M * 37) mod N) + 1, ( r(K) -> A1 is A0 + K ; A1 = A0 ),',
           '                      M1 is M - 1, probe(M1, N, A1, A).',
           'main :- findall(X-Y, (r(X), g1(X, Y)), L1), write(L1), nl,',
           '        findall(L, g2(3, L), L2), write(L2), nl,',
           '        findall(Y, g4(2.5, Y), L4), write(L4), nl,',
           '        findall(X-Y, (member(X, [0,1,2,3,4,7]), g5(X, Y)), L5), write(L5), nl,',
           '        findall(X-Y, (member(X, [0, 1, 5]), g9(X, Y)), L9), write(L9), nl,',
           '        probe(50, 7, 0, P), write(P), nl,',
           '        findall(Lm-U, (between(1, 30, Lm), call_metered(probe(3, 7, 0, _), Lm, U, _)), M),',
           '        write(M), nl, statistics(inferences, I), write(I), nl.' ]).

%% FILE run both ways, its two outputs into ON and OFF
ev_run_both(File, On, Off) :-
    cocolog(C),
    sh_join([C, ' -s ', File, ' 2>&1'], OnCmd), proc_run(OnCmd, 120000, OnOut, _),
    sh_join(['COCOLOG_ENV=0 ', C, ' -s ', File, ' 2>&1'], OffCmd), proc_run(OffCmd, 120000, OffOut, _),
    atom_codes(On, OnOut), atom_codes(Off, OffOut).

environments(D) :-
    section('environments: the goals after a body\'s first, reached from one record'),
    assertz((ev_r(X1) :- retract((ev_r(_) :- _)), garbage_collect,
                         ( ev_s(X1, Y1) -> ev_t(Y1, X1) ; X1 = none ))),
    ev_r(R1),
    check('a body whose clause is retracted as it runs, the store compacted, runs on', R1, 1),
    ( clause(ev_r(_), _) -> T1 = still ; T1 = gone ),
    check('...and the clause is gone', T1, gone),
    ev_c(R2),
    check('a catch after a goal reached from the environment catches', R2, caught(boom(1))),
    catch(ev_c2(_), E3, true),
    check('a throw from a call reached from it reaches the catch outside', E3, boom(1)),
    ev_c3(R4),
    check('the goals after a catch that recovered are reached from it', R4, 1),
    findall(X5, ev_k(X5), L5),
    check('a cut among them cuts to the clause\'s barrier', L5, [1]),
    %% 1.9.2's counts, goal by goal: a body of more than 64 goals keeps the
    %% one `,' step its overflow was
    ev_body(65, B6), assertz((ev_big :- B6)),
    gd_inferences(ev_big, I6), gd_inferences(ev_big, I6b),
    check('a body of 65 goals counts the inferences it counted', I6-I6b, 72-72),
    gd_inferences(findall(X7, ev_k(X7), _), I7),
    check('...a cut reached from the environment too', I7, 11),
    gd_inferences(ev_c3(_), I8),
    check('...and a catch', I8, 12),
    findall(X10, ev_o(X10), L10),
    check('a cut in a condition cuts the condition, not the clause', L10, [none]),
    findall(X11, ev_p(X11), L11),
    check('a cut in a branch cuts the clause', L11, [1]),
    findall(X12, ev_q(X12), L12),
    check('a disjunction leaves its other arm to come back to', L12, [1, 2, 3]),
    findall(X13-Y13, ev_u(X13, Y13), L13),
    check('\\+, once/1 and ignore/1 answer as they did', L13, [1-1]),
    findall(X14-Y14, ( member(X14, [0, 1, 2]), ev_g(X14, Y14) ), L14),
    check('a body that starts with guards makes its environment after them', L14,
          [1-small(2), 2-big(4)]),
    gd_inferences(findall(X15, ev_o(X15), _), I15a),
    gd_inferences(findall(X15b, ev_p(X15b), _), I15b),
    gd_inferences(findall(X15c, ev_q(X15c), _), I15c),
    gd_inferences(findall(X15d-Y15d, ev_u(X15d, Y15d), _), I15d),
    gd_inferences(findall(X15e-Y15e, ( member(X15e, [0, 1, 2]), ev_g(X15e, Y15e) ), _), I15e),
    check('each construct counts the inferences it counted, its own step among them',
          [I15a, I15b, I15c, I15d, I15e], [12, 12, 14, 20, 25]),
    %% an inference limit stops at the same goal whether it falls among the
    %% guards, at a construct or inside one of its arms: 1.9.2's answers
    findall(L16-U16-R16, ( between(1, 9, L16), call_metered(ev_g(2, _), L16, U16, R16) ), M16),
    findall(L16e-U16e-inference_limit_exceeded, ( between(1, 7, L16e), U16e is L16e + 1 ), E16a),
    append(E16a, [8-8-true, 9-8-true], E16),
    check('an inference limit stops where it always stopped, among guards and constructs', M16, E16),
    findall(L17-U17-R17, ( between(1, 12, L17), call_metered(ev_q(_), L17, U17, R17) ), M17),
    findall(L17e-U17e-inference_limit_exceeded, ( between(1, 5, L17e), U17e is L17e + 1 ), E17a),
    findall(L17t-6-true, between(6, 12, L17t), E17b),
    append(E17a, E17b, E17),
    check('...and in a disjunction that leaves a choice', M17, E17),
    atom_concat(D, '/both.pl', F9),
    ev_both(Lines9), fixture(F9, Lines9),
    ev_run_both(F9, A9, B9),
    check('a program answers and counts the same with environments and without', A9, B9),
    atom_codes(W9, "[2-21,3-31,4-41,5-51,6-61]\n3\n[1-small,2-small,3-small,4-4,5-5,6-6]\nf(1,2)\n"),
    ( atom_concat(W9, _, A9) -> T9 = yes ; T9 = A9 ),
    check('...and the answers are the ones it gave', T9, yes),
    atom_concat(D, '/both6.pl', F18),
    ev_both6(Lines18), fixture(F18, Lines18),
    ev_run_both(F18, A18, B18),
    check('so does one whose bodies start with guards', A18, B18),
    atom_codes(W18, "[3-yes,4-yes,5-yes]\n[4,alt(4)]\n[a]\n[1-1,2-2,4-4]\n[0-other,1-small(3),1-other,5-big]\n108\n[1-2,2-3,3-4,4-5,5-6,6-7,7-8,8-9,9-10,10-11,11-12,12-13,13-14,14-15,15-16,16-17,17-18,18-19,19-20,20-21,21-22,22-23,23-23,24-23,25-23,26-23,27-23,28-23,29-23,30-23]\n1166\n"),
    check('...and its answers, stops and count are 1.9.2\'s', A18, W18).

%% THE BUILTINS IN PLACE (Stage 7). A later goal of a body that makes an
%% environment, when it is a core builtin, is done where it stands: `is/2',
%% the six comparisons and the type tests run as Stage 4's guard program
%% over the environment's slots, `=/2', `==/2' and `\==/2' read their two
%% sides out of the slots, and any other builtin is called by its row on
%% the term built at entry -- each the one step its goal was. The guards'
%% families again, each goal after a construct so that it is one of its
%% environment's units, held to the step goal by goal, errors included.
ip_bin(plus, X, Y, R) :- once(true), R is X + Y.
ip_bin(minus, X, Y, R) :- once(true), R is X - Y.
ip_bin(times, X, Y, R) :- once(true), R is X * Y.
ip_bin(intdiv, X, Y, R) :- once(true), R is X // Y.
ip_bin(div, X, Y, R) :- once(true), R is X div Y.
ip_bin(mod, X, Y, R) :- once(true), R is X mod Y.
ip_bin(rem, X, Y, R) :- once(true), R is X rem Y.
ip_bin(min, X, Y, R) :- once(true), R is min(X, Y).
ip_bin(max, X, Y, R) :- once(true), R is max(X, Y).
ip_bin(shr, X, Y, R) :- once(true), R is X >> Y.
ip_bin(shl, X, Y, R) :- once(true), R is X << Y.
ip_bin(and, X, Y, R) :- once(true), R is X /\ Y.
ip_bin(or, X, Y, R) :- once(true), R is X \/ Y.
ip_bin(xor, X, Y, R) :- once(true), R is X xor Y.
ip_bin(nest, X, Y, R) :- once(true), R is (X * 31 + Y) mod 1000003 - min(X, -Y).

ip_un(neg, X, R) :- once(true), R is -X.
ip_un(pos, X, R) :- once(true), R is +(X).
ip_un(not, X, R) :- once(true), R is \X.
ip_un(abs, X, R) :- once(true), R is abs(X).
ip_un(sign, X, R) :- once(true), R is sign(X).

ip_cmp(lt, X, Y) :- once(true), X < Y.
ip_cmp(gt, X, Y) :- once(true), X > Y.
ip_cmp(le, X, Y) :- once(true), X =< Y.
ip_cmp(ge, X, Y) :- once(true), X >= Y.
ip_cmp(eq, X, Y) :- once(true), X =:= Y.
ip_cmp(ne, X, Y) :- once(true), X =\= Y.
ip_cmp(sum, X, Y) :- once(true), X + 1 > Y - 1.

ip_type(var, X) :- once(true), var(X).
ip_type(nonvar, X) :- once(true), nonvar(X).
ip_type(atom, X) :- once(true), atom(X).
ip_type(integer, X) :- once(true), integer(X).
ip_type(number, X) :- once(true), number(X).
ip_type(atomic, X) :- once(true), atomic(X).
ip_type(compound, X) :- once(true), compound(X).

%% the two sides, in place and through the step, over every pair of
%% values and the pairs that share a variable; what they bound is
%% compared as a variant, its variables numbered in order
ip_sides(eq, X, Y) :- once(true), X = Y.
ip_sides(same, X, Y) :- once(true), X == Y.
ip_sides(diff, X, Y) :- once(true), X \== Y.
ip_sref(eq, X, Y) :- gd_test(X = Y).
ip_sref(same, X, Y) :- gd_test(X == Y).
ip_sref(diff, X, Y) :- gd_test(X \== Y).

ip_svalues([_, 1, a, 2.5, "s", [], f(_), f(1), f(_, a), [1, 2], [_|_], g(f(a))]).

ip_spair(X-Y) :- ip_svalues(Vs), member(X, Vs), member(Y, Vs).
ip_spair(P) :- member(P, [A-A, f(A)-f(A), f(A, B)-f(B, A), f(A, A)-f(1, B), [A|B]-[1, 2]]).

ip_bound(G, T, Out) :-
    (   call(G)
    ->  copy_term(T, C), term_variables(C, Vs), ip_number(Vs, 0), Out = yes(C)
    ;   Out = no
    ).
ip_number([], _).
ip_number([v(N)|T], N) :- N1 is N + 1, ip_number(T, N1).

ip_sides_mismatch(Op, P) :-
    ip_spair(P), member(Op, [eq, same, diff]),
    copy_term(P, X1-Y1), copy_term(P, X2-Y2),
    ip_bound(ip_sides(Op, X1, Y1), X1-Y1, O1), ip_bound(ip_sref(Op, X2, Y2), X2-Y2, O2),
    O1 \== O2.

%% a variable a guard makes, and two a unification makes, read by the
%% goals after them; a guard that fails sending the call on; a loop
ip_fresh(X, L) :- once(true), Y is X * 2, Z is Y + 1, L = [Y, Z].
ip_struct(T, L) :- once(true), T = f(A, B), L = [B, A].
ip_cls(X, small) :- once(true), X < 10.
ip_cls(X, medium) :- once(true), X < 100.
ip_cls(_, large).
ip_loop(0) :- !.
ip_loop(N) :- once(true), N > 0, N1 is N - 1, ip_loop(N1).
ip_len(X, N) :- once(true), atom_length(X, N).

%% a program run with the builtins in place and without (`COCOLOG_INPLACE=0',
%% the stage's arm): guards that pass, fail and cannot decide -- a float,
%% an unbound variable, an atom -- two sides over a structure a guard
%% reads, builtins called by their row and raising, a stop at every ceiling
%% to forty, the count, and an error nothing catches
ip_both([ 'q(1). q(2). q(3). q(4).',
          'g(X, Y) :- q(X), ( X > 1 -> Y is X * 10 ; Y = small ), Y \\== 20.',
          's(T, L) :- once(true), T = f(A, B), A == 1, ( B = 2 -> L = yes(A, B) ; L = no ).',
          'l(A, N) :- once(true), atom_length(A, N), N >= 3.',
          'd(X, R) :- once(true), R is X / 2, R > 1.',
          'c(X, R) :- once(true), X = [H|T], atom(H), functor(R, H, 2), arg(1, R, T), arg(2, R, z).',
          'e(G, F) :- catch(G, error(F, _), true), ( var(F) -> F = none ; true ).',
          'main :- findall(X-Y, g(X, Y), L1), write(L1), nl,',
          '        findall(T-L, ( member(T, [f(1, 2), f(1, 3), f(2, 2), g(1)]), s(T, L) ), L2), write(L2), nl,',
          '        findall(A-N, ( member(A, [ab, abc, abcd]), l(A, N) ), L3), write(L3), nl,',
          '        findall(X-R, ( member(X, [1, 3, 4.0, 5]), d(X, R) ), L4), write(L4), nl,',
          '        findall(R, c([k, a, b], R), L5), write(L5), nl,',
          '        findall(F, ( member(G, [l(_, _), d(_, _), d(foo, _), c(_, _), c([1], _)]), e(G, F) ), L6),',
          '        write(L6), nl,',
          '        findall(Lm-U-Rm, ( between(1, 40, Lm), call_metered(findall(X-Y, g(X, Y), _), Lm, U, Rm) ), M),',
          '        write(M), nl,',
          '        statistics(inferences, I), write(I), nl,',
          '        l(_, _).' ]).

in_place(D) :-
    section('builtins in place: a later goal\'s arithmetic, tests and unification'),
    findall(K-N-X-Y, ( member(K, [bin, cmp, un, type]), gd_mismatch(ip, K, N, X, Y) ), L1),
    check('every operator and test at a later position answers as the step answers, errors included', L1, []),
    findall(Op-P, ip_sides_mismatch(Op, P), L2),
    check('=, == and \\== from the slots bind and answer as the step', L2, []),
    ip_fresh(3, L3), ip_struct(T3, L3b), T3 = f(1, 2),
    check('the variables they make are read by the goals after them', L3-L3b, [6, 7]-[2, 1]),
    findall(C4, ( member(X4, [5, 50, 500]), ip_cls(X4, C4) ), L4),
    check('a guard in place that fails sends the call on to the next clause', L4,
          [small, medium, large, medium, large, large]),
    catch(ip_len(_, _), error(E5, _), true),
    check('a builtin called in place raises as it did, to the catch outside', E5, instantiation_error),
    %% 1.9.4 counted these, unit by unit, and so does this engine
    gd_inferences(ip_loop(1000), I6), gd_inferences(ip_loop(1000), I6b),
    check('each one is still an inference', I6-I6b, 7004-7004),
    gd_inferences(findall(C7, ( member(X7, [5, 50, 500]), ip_cls(X7, C7) ), _), I7),
    gd_inferences(ip_fresh(3, _), I7b), gd_inferences(ip_struct(_, _), I7c),
    gd_inferences(ip_len(abc, _), I7d),
    check('the one that fails too, and the unifications and the builtins', [I7, I7b, I7c, I7d], [47, 10, 9, 8]),
    findall(L8-U8-R8, ( between(1, 18, L8), call_metered(ip_loop(2), L8, U8, R8) ), M8),
    findall(L8e-U8e-inference_limit_exceeded, ( between(1, 16, L8e), U8e is L8e + 1 ), E8a),
    append(E8a, [17-17-true, 18-17-true], E8),
    check('an inference limit stops where it always stopped', M8, E8),
    atom_concat(D, '/both7.pl', F9),
    ip_both(Lines9), fixture(F9, Lines9),
    cocolog(C),
    sh_join([C, ' -s ', F9, ' 2>&1; echo "exit $?"'], OnCmd), proc_run(OnCmd, 120000, OnOut, _),
    sh_join(['COCOLOG_INPLACE=0 ', C, ' -s ', F9, ' 2>&1; echo "exit $?"'], OffCmd), proc_run(OffCmd, 120000, OffOut, _),
    atom_codes(A9, OnOut), atom_codes(B9, OffOut),
    check('a program answers, raises, stops and counts the same in place and not', A9, B9),
    atom_codes(W9, "[1-small,3-30,4-40]\n[f(1,2)-yes(1,2),f(1,3)-no]\n[abc-3,abcd-4]\n[3-1.5,4.0-2.0,5-2.5]\n[k([a,b],z)]\n[instantiation_error,instantiation_error,type_error(evaluable,foo)]\n"),
    ( atom_concat(W9, _, A9) -> T9 = yes ; T9 = A9 ),
    check('...and its answers are 1.9.4\'s', T9, yes),
    W9e = '1252\nERROR: -s main: Arguments are not sufficiently instantiated\nexit 2\n',
    ( atom_concat(_, W9e, A9) -> T9e = yes ; T9e = A9 ),
    check('...as are its count and the error nothing caught', T9e, yes).

%% THE FUSED GUARD WORDS (1.9.6). A guard in place whose two operands are
%% each a slot or an integer constant -- `X is A op B' over `+', `-' and
%% `*', and the six comparisons -- is one word and its two operands
%% (AG_ISX, AG_CMPX), its unit a GUARDX, where the stack program dispatched
%% four. Held to the step as Stage 7's families are, errors included, with
%% a constant on either side and on both, the same variable twice and the
%% integers' edges, where the arithmetic wraps as the step's does; what it
%% cannot decide -- a float, an atom, an unbound variable -- it hands to the
%% step as its term. The arm is `COCOLOG_FUSE=0'.
fx_bin(plus, X, Y, R) :- once(true), R is X + Y.
fx_bin(minus, X, Y, R) :- once(true), R is X - Y.
fx_bin(times, X, Y, R) :- once(true), R is X * Y.
fx_bin(addc, X, _, R) :- once(true), R is X + 7.
fx_bin(subc, X, _, R) :- once(true), R is 7 - X.
fx_bin(mulc, _, Y, R) :- once(true), R is -3 * Y.
fx_bin(negc, X, _, R) :- once(true), R is X - -5.
fx_bin(bigc, X, _, R) :- once(true), R is X + 1152921504606846975.
fx_bin(cc, _, _, R) :- once(true), R is 6 * 7.
fx_bin(same, X, _, R) :- once(true), R is X + X.
fx_bin(sq, _, Y, R) :- once(true), R is Y * Y.
fx_bin(flt, X, _, R) :- once(true), R is X + 2.5.

fx_expr(plus, X, Y, X + Y).        fx_expr(minus, X, Y, X - Y).
fx_expr(times, X, Y, X * Y).       fx_expr(addc, X, _, X + 7).
fx_expr(subc, X, _, 7 - X).        fx_expr(mulc, _, Y, -3 * Y).
fx_expr(negc, X, _, X - -5).       fx_expr(bigc, X, _, X + 1152921504606846975).
fx_expr(cc, _, _, 6 * 7).          fx_expr(same, X, _, X + X).
fx_expr(sq, _, Y, Y * Y).          fx_expr(flt, X, _, X + 2.5).

fx_cmp(lt, X, Y) :- once(true), X < Y.
fx_cmp(gt, X, Y) :- once(true), X > Y.
fx_cmp(le, X, Y) :- once(true), X =< Y.
fx_cmp(ge, X, Y) :- once(true), X >= Y.
fx_cmp(eq, X, Y) :- once(true), X =:= Y.
fx_cmp(ne, X, Y) :- once(true), X =\= Y.
fx_cmp(ltc, X, _) :- once(true), X < 3.
fx_cmp(gtc, _, Y) :- once(true), 3 > Y.
fx_cmp(lec, X, _) :- once(true), X =< -7.
fx_cmp(gec, _, Y) :- once(true), -7 >= Y.
fx_cmp(eqc, X, _) :- once(true), X =:= 7.
fx_cmp(nec, _, Y) :- once(true), 7 =\= Y.
fx_cmp(cc, _, _) :- once(true), 3 >= 3.
fx_cmp(ccf, _, _) :- once(true), 3 < 2.
fx_cmp(same, X, _) :- once(true), X < X.
fx_cmp(sameq, _, Y) :- once(true), Y =:= Y.
fx_cmp(flt, X, _) :- once(true), X < 2.5.

fx_cexpr(lt, X, Y, X < Y).         fx_cexpr(gt, X, Y, X > Y).
fx_cexpr(le, X, Y, X =< Y).        fx_cexpr(ge, X, Y, X >= Y).
fx_cexpr(eq, X, Y, X =:= Y).       fx_cexpr(ne, X, Y, X =\= Y).
fx_cexpr(ltc, X, _, X < 3).        fx_cexpr(gtc, _, Y, 3 > Y).
fx_cexpr(lec, X, _, X =< -7).      fx_cexpr(gec, _, Y, -7 >= Y).
fx_cexpr(eqc, X, _, X =:= 7).      fx_cexpr(nec, _, Y, 7 =\= Y).
fx_cexpr(cc, _, _, 3 >= 3).        fx_cexpr(ccf, _, _, 3 < 2).
fx_cexpr(same, X, _, X < X).       fx_cexpr(sameq, _, Y, Y =:= Y).
fx_cexpr(flt, X, _, X < 2.5).

%% a left side already bound -- compared, as unification compares -- and
%% one the guard binds that is also an operand
fx_left(eq, X, Y) :- once(true), X is Y + 1.
fx_left(self, X, _) :- once(true), X is X * 1.
fx_left(four, _, Y) :- once(true), 4 is Y + 1.
fx_lexpr(eq, X, Y, X is Y + 1).
fx_lexpr(self, X, _, X is X * 1).
fx_lexpr(four, _, Y, 4 is Y + 1).

fx_values([-7, 0, 3, 7, 1099511627776, 1152921504606846975, -1152921504606846976, 2.5, foo, _]).

fx_out(G, T, Out) :- catch(ip_bound(G, T, Out), error(F, _), Out = error(F)).

fx_mismatch(bin, Name, X, Y) :-
    fx_values(Vs), member(X, Vs), member(Y, Vs), fx_expr(Name, X, Y, E),
    gd_out(fx_bin(Name, X, Y, R1), R1, O1), gd_out(gd_ref(E, R2), R2, O2),
    O1 \== O2.
fx_mismatch(cmp, Name, X, Y) :-
    fx_values(Vs), member(X, Vs), member(Y, Vs), fx_cexpr(Name, X, Y, E),
    gd_out(fx_cmp(Name, X, Y), yes, O1), gd_out(gd_test(E), yes, O2),
    O1 \== O2.
fx_mismatch(left, Name, X0, Y0) :-
    fx_values(Vs), member(X0, Vs), member(Y0, Vs),
    copy_term(X0-Y0, X1-Y1), copy_term(X0-Y0, X2-Y2), fx_lexpr(Name, X2, Y2, E),
    fx_out(fx_left(Name, X1, Y1), X1-Y1, O1), fx_out(gd_test(E), X2-Y2, O2),
    O1 \== O2.

%% a body of four fused guards, and a loop that calls it
fx_k(X, R) :- once(true), 3 < X, R is 6 * 7, X =< 100, R =:= 42.
fx_kl(3) :- !.
fx_kl(N) :- fx_k(N, _), N1 is N - 1, fx_kl(N1).

%% a program run fused and not: guards that pass, fail and cannot decide,
%% a bound left side, the step's errors, a stop at every ceiling to thirty,
%% the count, and an error nothing catches
fx_both([ 'q(1). q(2). q(3). q(4).',
          'a(X, R) :- q(X), ( X > 2 -> R is 7 - X ; R is X * 3 ), R =\\= 6.',
          'b(X, Y, R) :- once(true), R is X + Y, 3 < R, R =< 1000000.',
          'c(X) :- once(true), R = 10, R is X + 6.',
          'k(R) :- once(true), R is 6 * 7, 42 =:= R.',
          'w(X, R) :- once(true), R is X * X.',
          'e(G, F) :- catch(G, error(F, _), true), ( var(F) -> F = none ; true ).',
          'main :- findall(X-R, a(X, R), L1), write(L1), nl,',
          '        findall(X-Y-R, ( member(X-Y, [1-1, 2-3, 2.5-1, 999999-2]), b(X, Y, R) ), L2), write(L2), nl,',
          '        findall(X, ( member(X, [4, 5, 4.0]), c(X) ), L3), write(L3), nl,',
          '        k(R4), write(R4), nl,',
          '        findall(R, ( member(X, [1000, -3, 7]), w(X, R) ), L5), write(L5), nl,',
          '        findall(F, ( member(G, [b(_, 1, _), b(foo, 1, _), c(_), w(a, _)]), e(G, F) ), L6), write(L6), nl,',
          '        findall(Lm-U-Rm, ( between(1, 30, Lm), call_metered(findall(X-R, a(X, R), _), Lm, U, Rm) ), M),',
          '        write(M), nl,',
          '        statistics(inferences, I), write(I), nl,',
          '        b(_, 2, _).' ]).

fused(D) :-
    section('fused guard words: a guard in place over two slots or constants, as one word'),
    findall(K-N-X-Y, ( member(K, [bin, cmp, left]), fx_mismatch(K, N, X, Y) ), L1),
    check('every fused operator and comparison answers as the step answers, errors included', L1, []),
    findall(T2, ( member(A2-B2, [4-3, 5-3, 4.0-3, a-3, f(x)-3]), ( fx_left(eq, A2, B2) -> T2 = yes ; T2 = no ) ), L2),
    check('a fused is/2 whose left is bound compares, as unification does', L2, [yes, no, no, no, no]),
    findall(T3, ( member(B3, [3, 2]), ( fx_left(four, _, B3) -> T3 = yes ; T3 = no ) ), L3),
    check('...and one with an integer on its left, which is not fused, the same', L3, [yes, no]),
    gd_inferences(fx_k(5, _), I4), gd_inferences(fx_kl(100), I4b),
    check('each fused word is still an inference', I4-I4b, 11-1071),
    findall(L5-U5-R5, ( between(1, 12, L5), call_metered(fx_k(5, _), L5, U5, R5) ), M5),
    findall(L5e-U5e-inference_limit_exceeded, ( between(1, 9, L5e), U5e is L5e + 1 ), E5a),
    append(E5a, [10-10-true, 11-10-true, 12-10-true], E5),
    check('an inference limit stops where it always stopped', M5, E5),
    findall(L6-U6-R6, ( between(1, 12, L6), call_metered(fx_k(200, _), L6, U6, R6) ), M6),
    findall(L6e-U6e-inference_limit_exceeded, ( between(1, 7, L6e), U6e is L6e + 1 ), E6a),
    findall(L6f-8-failed, between(8, 12, L6f), E6b),
    append(E6a, E6b, E6),
    check('...and where a fused guard fails', M6, E6),
    atom_concat(D, '/both8.pl', F7),
    fx_both(Lines7), fixture(F7, Lines7),
    cocolog(C),
    sh_join([C, ' -s ', F7, ' 2>&1; echo "exit $?"'], OnCmd), proc_run(OnCmd, 120000, OnOut, _),
    sh_join(['COCOLOG_FUSE=0 ', C, ' -s ', F7, ' 2>&1; echo "exit $?"'], OffCmd), proc_run(OffCmd, 120000, OffOut, _),
    atom_codes(A7, OnOut), atom_codes(B7, OffOut),
    check('a program answers, raises, stops and counts the same fused and not', A7, B7),
    atom_codes(W7, "[1-3,3-4,4-3]\n[2-3-5,2.5-1-3.5]\n[4]\n42\n[1000000,9,49]\n[instantiation_error,type_error(evaluable,foo),instantiation_error,type_error(evaluable,a)]\n"),
    ( atom_concat(W7, _, A7) -> T7 = yes ; T7 = A7 ),
    check('...and its answers are 1.9.5\'s', T7, yes),
    W7e = '890\nERROR: -s main: Arguments are not sufficiently instantiated\nexit 2\n',
    ( atom_concat(_, W7e, A7) -> T7e = yes ; T7e = A7 ),
    check('...as are its count and the error nothing caught', T7e, yes).
