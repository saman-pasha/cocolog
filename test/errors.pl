%% What cocolog RAISES, and what it no longer loses on the way.
%%
%% Four defects, all of the same shape: the interpreter knew something had
%% gone wrong and the program could not find out. Each is checked here in
%% the arrangement that showed it, because three of the four are invisible
%% under `--local' -- there is nothing behind the clauses to refuse them.
%%
%%     cocolog -s test/errors.pl        from the checkout root
%%
%% * A `catch/3' WHOSE GOAL SUCCEEDED went on catching. The frame was
%%   pushed and never taken down, so a `throw/1' AFTER the catch ran that
%%   catch's recovery and carried on from after it -- and the outer catch,
%%   the one the program wrote for exactly that ball, never heard. Found in
%%   cicili-lang, which worked around it by wrapping every catch in
%%   `once/1'. The fix is a marker goal after the catch's own goal and a
%%   retry frame above the goal's alternatives; see COCO_CH_CATCH_RETRY in
%%   lib/solve.cicili.
%%
%% * A `throw/1' INSIDE findall/3, forall/2 or aggregate_all/3 escaped the
%%   catch around it. Those three run the goal on a sub-engine with a
%%   choice stack of its own, so the ball found no catch frame there and
%%   came back as an error every caller turned into "end the query".
%%
%% * `atomic_list_concat/2,3' had an 8 KB output buffer and FAILED, with no
%%   error term at all, once the join outran it -- and its error path read
%%   the culprit out of an array it had already freed, so an unbound
%%   element named the wrong term or crashed outright.
%%
%% * A CLAUSE TOO LONG FOR A ROW took every other clause of the transaction
%%   with it. Zigurat fits a row in one page and throws `allocation
%%   overflow' at COMMIT, by which time the process had already asserted
%%   everything else and answered about it. It is refused on the way in
%%   now, one clause at a time and named.

:- use_module('test/prelude.pl').

main :-
    catch_frame,
    all_solutions_throw,
    join_and_split,
    clause_too_long,
    checks_done.

%% ---- a catch that has finished catching ---------------------------------

:- dynamic ran/1.

catch_frame :-
    section('a catch/3 whose goal exited stops catching'),

    retractall(ran(_)),
    answer(( catch(( catch(true, _, assertz(ran(inner))), throw(b1) ), B1, true),
             findall(R1, ran(R1), L1) ), B1-L1, G1),
    check('a throw after the inner catch reaches the OUTER one', G1, b1-[]),

    retractall(ran(_)),
    answer(( catch(( catch(catch(true, _, assertz(ran(a2))), _, assertz(ran(b2))),
                     throw(c2) ), B2, true),
             findall(R2, ran(R2), L2) ), B2-L2, G2),
    check('and two nested exited catches stay out of the way', G2, c2-[]),

    %% the frame must come BACK when the goal is re-entered, or a catch
    %% around a nondeterministic goal would stop working on the second
    %% solution -- which is what a plain `mark it dead' would have done
    retractall(ran(_)),
    answer(( catch(( catch(member(_, [1,2]), _, assertz(ran(r3))), throw(z3) ), B3, true),
             findall(R3, ran(R3), L3) ), B3-L3, G3),
    check('a goal with alternatives left behind it, likewise', G3, z3-[]),

    answer(( member(X4, [1,2,3]),
             catch(( catch(throw(in4), in4, true), X4 > 2, throw(out4) ), B4, true)
           ), B4-X4, G4),
    check('and failing back INTO the goal makes the frame live again', G4, out4-3),

    answer(catch(throw(x5), E5, R5 = ran), E5-R5, G5),
    check('a goal that throws still runs its own recovery', G5, x5-ran),

    answer(( catch(p6(Y6), _, Y6 = caught), Y6 == 1 ), Y6, G6),
    check('and a catch that succeeded still hands its bindings out', G6, 1).

p6(1).
p6(2).

%% ---- a throw out of the three all-solutions predicates ------------------

all_solutions_throw :-
    section('a throw inside findall/forall/aggregate_all is catchable'),

    answer(catch(findall(_, (member(X1, [1,2]), throw(f(X1))), _), E1, true), E1, G1),
    check('findall/3 lets the ball out to the catch around it', G1, f(1)),

    answer(catch(forall(member(X2, [1,2,3]), (X2 < 3 -> true ; throw(t(X2)))), E2, true),
           E2, G2),
    check('forall/2, the same', G2, t(3)),

    answer(catch(aggregate_all(count, (member(X3, [1,2]), throw(a(X3))), _), E3, true),
           E3, G3),
    check('aggregate_all/3, the same', G3, a(1)),

    %% and the goals that DON'T throw are unaffected: the whole point of a
    %% sub-engine is that the outer machine comes back as it was
    answer(findall(X4, member(X4, [1,2,3]), L4), L4, G4),
    check('and an ordinary findall still collects', G4, [1,2,3]),
    answer(forall(member(X5, [1,2,3]), X5 > 0), yes, G5),
    check('an ordinary forall still holds', G5, yes),
    answer(aggregate_all(sum(X6), member(X6, [1,2,3]), S6), S6, G6),
    check('an ordinary aggregate_all still sums', G6, 6).

%% ---- atomic_list_concat, past the buffer and past the errors ------------

join_and_split :-
    section('atomic_list_concat/2,3 has no 8 KB ceiling and names its culprit'),

    %% 6400 answered and 8320 did not, measured on the old buffer. The
    %% sizes here straddle it and go well past, because the ceiling was a
    %% `return 0' -- a FAILURE, indistinguishable from "these do not join"
    long_atom(3000, A1), atomic_list_concat([A1, A1, A1], '-', J1), atom_length(J1, N1),
    check('a 9002-character join answers', N1, 9002),
    long_atom(30000, A2), atomic_list_concat([A2, A2], '+', J2), atom_length(J2, N2),
    check('and so does a 60001-character one', N2, 60001),

    %% the split half had the same ceiling on its INPUT
    long_atom(20000, A3), atomic_list_concat([A3, A3, A3], '|', J3),
    atomic_list_concat(P3, '|', J3), length(P3, N3),
    check('a 60002-character atom splits into its three parts', N3, 3),
    nth0(0, P3, F3), atom_length(F3, FN3),
    check('and the first part is the whole 20000 characters', FN3, 20000),

    %% AN UNBOUND ELEMENT IS AN instantiation_error. It used to read the
    %% culprit out of a freed array, so the ball named the first element
    answer(catch(atomic_list_concat([a, _, c], '-', _), error(F4, _), true), F4, G4),
    check('an unbound element raises instantiation_error', G4, instantiation_error),
    answer(catch(atomic_list_concat([a, foo(1), c], '-', _), error(F5, _), true), F5, G5),
    check('and a compound names ITSELF, not the first element', G5,
          type_error(atomic, foo(1))),

    %% the small cases the fix must not have moved
    answer(atomic_list_concat([], '-', Z6), Z6, G6),
    check('the empty list still joins to the empty atom', G6, ''),
    answer(atomic_list_concat([one], '-', O7), O7, G7),
    check('one element still joins to itself', G7, one),
    answer(atomic_list_concat([a,b,c], '-', T8), T8, G8),
    check('three still join with the separator between them', G8, 'a-b-c'),
    answer(atomic_list_concat(S9, '-', 'a-b-c'), S9, G9),
    check('and the same atom splits back', G9, [a,b,c]).

long_atom(N, A) :- length(L, N), maplist(=(0'x), L), atom_codes(A, L).

%% ---- a clause too long for a row ----------------------------------------
%%
%% A SECOND PROCESS IS THE CHECK, and it has to be: the defect was that the
%% writing process saw everything it had asserted and the reader saw none of
%% it. `--embed' is the arrangement that has a row at all -- under `--local'
%% there is nothing behind the clauses and no length to exceed.

clause_too_long :-
    section('a clause too long for a row is refused, and takes nothing with it'),
    scratch(D),
    atom_concat(D, '/KB', KB),
    atom_concat(D, '/big.pl', Prog),

    %% asserted: the oversized one raises, the two beside it survive
    fixture(Prog,
            [ ':- dynamic unit/2.',
              'main :- assertz(unit(before, small)),',
              '        numlist(1, 4000, L),',
              '        catch(assertz(unit(big, L)), E, true),',
              '        format("raised ~q~n", [E]),',
              '        assertz(unit(after, small)).' ]),
    atomic_list_concat(['--embed ', KB, ' run ', Prog, ' main 2>&1'], A1),
    cocolog_run(A1, T1, X1),
    check('the writing process exits 0 -- the error was catchable', X1, 0),
    has('and the ball is resource_error(clause_length)',
        'raised error(resource_error(clause_length)', T1),

    atomic_list_concat(['--embed ', KB,
                        ' query "findall(K, unit(K,_), Ks), write(back(Ks)), nl" 2>&1'], A2),
    cocolog_run(A2, T2, _),
    has('and a SECOND process reads back the clauses beside it',
        'back([before,after])', T2),

    %% consulted: the file's other clauses still land, and the report names
    %% the file, the line, the predicate and both numbers
    atom_concat(D, '/KB2', KB2),
    atom_concat(D, '/wide.pl', Prog2),
    long_atom(9000, Big),
    atomic_list_concat(['p(big(', Big, ')).'], BigClause),
    fixture(Prog2, ['p(small1).', BigClause, 'p(small2).']),
    atomic_list_concat(['--embed ', KB2, ' run ', Prog2, ' true 2>&1'], A3),
    cocolog_run(A3, T3, _),
    has('the consult reports the refusal in SWI\'s shape', 'ERROR: ', T3),
    has('names the predicate and both numbers', 'p/1: a clause of ', T3),
    has('and says what to do about it', 'store it as several clauses', T3),

    atomic_list_concat(['--embed ', KB2,
                        ' query "findall(X, p(X), L), write(back(L)), nl" 2>&1'], A4),
    cocolog_run(A4, T4, _),
    has('and the rest of the file is in the store', 'back([small1,small2])', T4),

    shl(['rm -rf ', D]).
