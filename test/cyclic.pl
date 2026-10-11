%% A CYCLIC TERM -- `X = f(X)' -- is written, raised, caught and asked
%% about without taking the process down (1.10.18). Through 1.10.17 the
%% writer recursed into it until the C stack ran out (SIGSEGV, exit 139):
%% write/1 of one, the message of an error over one, the backtrace line of
%% a goal holding one, atom_length/2 of one, `is/2' over one; a throw of
%% one never ended (the store's copy of the ball went round the cycle for
%% ever); and acyclic_term/1 said yes of it.
%%
%% Now it is written as SWI writes one, in factors:
%%
%%     ?- X = f(X), writeq(X).
%%     @(S_1,[S_1=f(S_1)])
%%
%% each compound a left-to-right walk reaches a second time made a
%% variable, in the order of those second arrivals, and every one whose
%% term holds no cycle put back in its place -- so a shared subterm that
%% is no cycle stays written out (`f(S_1,g(a),g(a))'). The texts below are
%% swipl 9.0.4's, letter for letter.
%%
%%     cocolog -s test/cyclic.pl        from the checkout root
%%
%% EVERY CHECK THAT COULD CRASH IS A CHILD, so the case reports a crash as
%% a red check rather than dying with it -- which is how it went red over
%% 1.10.17 before the fix. A variable's `_G' number is taken out before a
%% comparison.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    shapes(D), long_and_deep(D), entries(D), errors(D), caught(D),
    questions, arithmetic(D),
    shl(['rm -rf ', D]),
    checks_done.

%% stdout of `cocolog ARGS', the `_G' numbers taken out, and the exit
%% status; stderr apart (ERR) when asked for
child(Args, Out, Rc) :-
    cocolog_run(Args, Raw, Rc, 60000),
    re_replace_atom('_G[0-9]+', '_G', Raw, Out).

child_err(D, Args, Err, Rc) :-
    sh_join([Args, ' 2>&1 >/dev/null'], A),
    cocolog_run(A, Raw, Rc, 60000),
    atom_concat(D, '/', Prefix),
    re_replace_atom(Prefix, '', Raw, R1),
    re_replace_atom('_G[0-9]+', '_G', R1, Err).

lines(Ls, Text) :- atomic_list_concat(Ls, '\n', Text).

%% one line of a child's output each: the label, then what it should say
each_line([], _).
each_line([Label-Want|Ws], [Got|Gs]) :- !,
    check(Label, Got, Want), each_line(Ws, Gs).
each_line([Label-Want|Ws], []) :-
    check(Label, missing, Want), each_line(Ws, []).

%% THE SHAPES, each written by writeq/1 on a line of its own. The labels
%% say what each one is about; the second column is swipl's text.
shapes(D) :-
    section('a cyclic term written as SWI writes it: @(Template, Substitutions)'),
    atom_concat(D, '/shapes.pl', F),
    fixture(F, [
      'w(T) :- writeq(T), nl.',
      'main :-',
      '  X1 = f(X1), w(X1),',
      '  X2 = f(Y2), Y2 = g(X2), w(X2),',
      '  X3 = f(X3, Y3), Y3 = g(Y3), w(X3),',
      '  X4 = f(X4), Z4 = g(Z4), w(t(X4, Z4)),',
      '  X5 = f(X5), w(h(X5, X5)),',
      '  A6 = g(a), X6 = f(X6, A6, A6), w(X6),',
      '  X7 = f(X7, _), w(X7),',
      '  L8 = [L8], w(L8),',
      '  X9 = [1,2|X9], w(X9),',
      '  X10 = f(X10), w([a, b, X10]),',
      '  T11 = [4|T11], w([1,2,3|T11]),',
      '  X12 = ''A''(X12), w(X12), write(X12), nl,',
      '  X13 = - X13, w(X13),',
      '  X14 = (a :- X14), w(X14),',
      '  X15 = {X15}, w(X15),',
      '  X16 = f(X16), w(X16-X16),',
      '  X17 = [a|X17], w(f(X17, X17)),',
      '  X18 = f(Y18), Y18 = g(Y18), w(X18),',
      '  X19 = f(Y19), Y19 = g(Y19, X19), w(X19),',
      '  X20 = f(Y20, Z20), Y20 = g(Z20), Z20 = h(Y20), w(X20),',
      '  X21 = f(A21, B21), A21 = a(B21), B21 = b(A21, X21), w(X21),',
      '  X22 = [a, Y22 | X22], Y22 = y(Y22), w(X22),',
      '  X23 = f(Y23, Z23), Z23 = z(Y23), Y23 = y(Z23, X23), w(X23),',
      '  X24 = f(Y24, X24), Y24 = f(X24, Y24), w(X24),',
      '  X25 = f(X25, Y25, X25), Y25 = g(X25), w(X25),',
      '  X26 = f(X26, X26), w(X26),',
      '  X27 = ''S_1''(X27), w(X27).']),
    sh_join(['-s ', F], A), child(A, Out, Rc),
    atomic_list_concat(Got, '\n', Out),
    each_line([
      'the simplest: the term is its own argument' - '@(S_1,[S_1=f(S_1)])',
      'a cycle through two compounds' - '@(S_1,[S_1=f(g(S_1))])',
      'two cycles, numbered as they are met' - '@(S_1,[S_1=f(S_1,S_2),S_2=g(S_2)])',
      'cycles below a term that is none' - '@(t(S_1,S_2),[S_1=f(S_1),S_2=g(S_2)])',
      'one cycle met twice' - '@(h(S_1,S_1),[S_1=f(S_1)])',
      'a shared subterm that is no cycle stays written out' - '@(S_1,[S_1=f(S_1,g(a),g(a))])',
      'an unbound variable inside' - '@(S_1,[S_1=f(S_1,_G)])',
      'a list that is its own element' - '@(S_1,[S_1=[S_1]])',
      'a list that is its own tail' - '@(S_1,[S_1=[1,2|S_1]])',
      'a cycle as a list''s element' - '@([a,b,S_1],[S_1=f(S_1)])',
      'a cycle as a list''s tail' - '@([1,2,3|S_1],[S_1=[4|S_1]])',
      'quoted where writeq quotes' - '@(S_1,[S_1=''A''(S_1)])',
      '...and not by write/1' - '@(S_1,[S_1=A(S_1)])',
      'a prefix operator, spaced from the =' - '@(S_1,[S_1= -S_1])',
      'an operator above 699, bracketed' - '@(S_1,[S_1=(a:-S_1)])',
      'a curly term' - '@(S_1,[S_1={S_1}])',
      'an operator around two of it' - '@(S_1-S_1,[S_1=f(S_1)])',
      'a cyclic list twice' - '@(f(S_1,S_1),[S_1=[a|S_1]])',
      'a cycle below the root' - '@(f(S_1),[S_1=g(S_1)])',
      'the one met second stays, the root is put back' - '@(f(S_1),[S_1=g(S_1,f(S_1))])',
      'a cycle the root is not on' - '@(f(g(S_1),S_1),[S_1=h(g(S_1))])',
      'three met twice, two put back' - '@(f(a(S_1),S_1),[S_1=b(a(S_1),f(a(S_1),S_1))])',
      'kept in the order they were met' - '@(S_2,[S_1=y(S_1),S_2=[a,S_1|S_2]])',
      'the first met put back, the other two kept' - '@(S_1,[S_1=f(y(S_2,S_1),S_2),S_2=z(y(S_2,S_1))])',
      'two that hold each other' - '@(S_1,[S_1=f(S_2,S_1),S_2=f(S_1,S_2)])',
      'a compound on the cycle met once' - '@(S_1,[S_1=f(S_1,g(S_1),S_1)])',
      'a term that branches into itself' - '@(S_1,[S_1=f(S_1,S_1)])',
      'an atom named S_1 is quoted, as writeq quotes it' - '@(S_1,[S_1=''S_1''(S_1)])'
    ], Got),
    check('...and the program ends', Rc, 0).

%% Past the writer's depth guard (1024) and Brent's first window (1024
%% elements), each with something on either side of it
long_and_deep(D) :-
    section('long and deep: a cyclic tail past 1024 elements, a cycle past 1024 levels'),
    atom_concat(D, '/long.pl', F),
    fixture(F, [
      'deep(0, X, X) :- !.',
      'deep(N, X, g(T)) :- N1 is N - 1, deep(N1, X, T).',
      'count(S, Sub, N) :- aggregate_all(count, sub_atom(S, _, _, _, Sub), N).',
      'main :-',
      '  numlist(1, 3000, L1), append(L1, T1, C1), T1 = C1,',
      '  with_output_to(atom(A1), writeq(C1)), atom_length(A1, N1),',
      '  sub_atom(A1, 0, 22, _, P1), sub_atom(A1, _, 15, 0, S1),',
      '  writeq(N1-P1-S1), nl,',
      '  numlist(1, 2000, L2), T2 = [x, y | T2], append(L2, T2, C2),',
      '  with_output_to(atom(A2), writeq(C2)), sub_atom(A2, _, 26, 0, S2),',
      '  writeq(S2), nl,',
      '  X3 = f(X3), deep(3000, X3, T3),',
      '  with_output_to(atom(A3), writeq(T3)), count(A3, ''g('', G3),',
      '  sub_atom(A3, 0, 6, _, P3), sub_atom(A3, _, 22, 0, S3),',
      '  writeq(G3-P3-S3), nl,',
      '  deep(2000, a, T4), with_output_to(atom(A4), writeq(T4)),',
      '  atom_length(A4, N4), count(A4, ''@'', At4), writeq(N4-At4), nl,',
      '  numlist(1, 100000, L5), with_output_to(atom(A5), writeq(L5)),',
      '  atom_length(A5, N5), writeq(N5), nl.']),
    sh_join(['-s ', F], A), child(A, Out, Rc),
    atomic_list_concat(Got, '\n', Out),
    each_line([
      'a list of 3000 that is its own tail' - '13911-''@(S_1,[S_1=[1,2,3,4,5,''-''999,3000|S_1]])''',
      'a cycle at the end of a list of 2000' - '''2000|S_1],[S_1=[x,y|S_1]])''',
      'a cycle 3000 levels down, every level written once' - '3000-''@(g(g(''-'')))))))),[S_1=f(S_1)])''',
      'a tree 2000 deep is no cycle' - '6001-0',
      'a list of 100000 is written whole' - '588896'
    ], Got),
    check('...and the program ends', Rc, 0).

%% Which writer names the cycles: write/1, print/1, writeq/1, format/2's
%% ~w ~p ~q, term_to_atom/2, with_output_to/2 -- S_1, S_2, ...;
%% write_canonical/1, and write_term/2 given names of its own, the
%% variables as they are
entries(D) :-
    section('every writer: S_1 where SWI says S_1, a variable where it says one'),
    atom_concat(D, '/entries.pl', F),
    fixture(F, [
      'main :-',
      '  X = f(X),',
      '  write(X), nl, print(X), nl,',
      '  format("~w|~q|~p~n", [X, X, X]),',
      '  term_to_atom(X, A), writeq(A), nl,',
      '  with_output_to(string(S), print(X)), writeq(S), nl,',
      '  write_canonical(X), nl,',
      '  write_term(g(V, X), [variable_names([''V''=V])]), nl,',
      '  atom_length(X, L), writeq(L), nl.']),
    sh_join(['-s ', F], A), child(A, Out, Rc),
    atomic_list_concat(Got, '\n', Out),
    each_line([
      'write/1' - '@(S_1,[S_1=f(S_1)])',
      'print/1' - '@(S_1,[S_1=f(S_1)])',
      'format/2: ~w, ~q, ~p' - '@(S_1,[S_1=f(S_1)])|@(S_1,[S_1=f(S_1)])|@(S_1,[S_1=f(S_1)])',
      'term_to_atom/2' - '''@(S_1,[S_1=f(S_1)])''',
      'with_output_to/2' - '"@(S_1,[S_1=f(S_1)])"',
      'write_canonical/1: the variable as it is' - '@(_G,[_G=f(_G)])',
      'write_term/2 naming variables of its own: no S_1 among them' - '@(g(V,_G),[_G=f(_G)])',
      'atom_length/2: the length of that text' - '19'
    ], Got),
    check('...and the program ends', Rc, 0).

%% The message of an error over one, where it was raised, and exit 2
errors(D) :-
    section('an error over a cyclic term: its message, where, and exit status 2'),
    atom_concat(D, '/e1.pl', F1),
    fixture(F1, ['main :- X = f(X), g(X), write(after), nl.',
                 'g(X) :- arg(X, f(a), _), write(no), nl.']),
    sh_join(['-s ', F1], A1), child_err(D, A1, E1, Rc1),
    lines(['ERROR: -s main: Type error: `integer'' expected, found `@(S_1,[S_1=f(S_1)])''',
           'ERROR: In:',
           'ERROR:   @(arg(S_1,f(a),_G),[S_1=f(S_1)])',
           'ERROR:   then write(no)',
           'ERROR:   then nl',
           'ERROR:   then write(after)',
           'ERROR:   then nl',
           'ERROR: Note: what each goal had left to run, not the calls it was made in;',
           'ERROR: run with --backtrace to see those.'], W1),
    check('a builtin''s type error over one: the message and where', E1, W1),
    check('...and the exit status is 2', Rc1, 2),
    sh_join(['--backtrace -s ', F1], A2), child_err(D, A2, E2, Rc2),
    lines(['ERROR: -s main: Type error: `integer'' expected, found `@(S_1,[S_1=f(S_1)])''',
           'ERROR: In:',
           'ERROR:   [3] @(arg(S_1,f(a),_G),[S_1=f(S_1)])',
           'ERROR:   [2] @(g(S_1),[S_1=f(S_1)])',
           'ERROR:   [1] main'], W2),
    check('...under --backtrace, every call it was raised in', E2, W2),
    check('...and the exit status is 2', Rc2, 2),
    atom_concat(D, '/e2.pl', F3),
    fixture(F3, ['main :- X = f(X), throw(X).']),
    sh_join(['--no-backtrace -s ', F3], A3), child_err(D, A3, E3, Rc3),
    check('a throw/1 of one: SWI''s Unknown message', E3,
          'ERROR: -s main: Unknown message: @(S_1,[S_1=f(S_1)])'),
    check('...and the exit status is 2', Rc3, 2),
    child_err(D, '--no-backtrace query "X = f(X), Y = g(X), atom_length(Y, _), throw(Y)"', E4, Rc4),
    check('cocolog query: the same', E4,
          'ERROR: ?-: Unknown message: @(g(S_1),[S_1=f(S_1)])'),
    check('...and query''s status for an error, 1', Rc4, 1).

%% THE CATCHER GETS THE CYCLIC TERM ITSELF, as SWI's does: the ball is
%% stored as its factors and made cyclic again where it is read. `C == B'
%% asks of one cell, so it is no walk of a cycle (`==' of two different
%% cyclic terms still is: the walks other than the writer's are not
%% guarded yet).
caught(D) :-
    section('a cyclic ball caught is the cyclic term, through every engine that throws one again'),
    atom_concat(D, '/caught.pl', F),
    fixture(F, [
      'same(B) :- ( B = f(C), C == B -> write(same) ; write(differs) ), nl.',
      'main :-',
      '  X = f(X),',
      '  catch(throw(X), B1, true), same(B1),',
      '  catch(arg(X, f(a), _), error(type_error(T2, B2), _), true), write(T2), nl, same(B2),',
      '  catch(findall(Y, (Y = 1, throw(X)), _), B3, true), same(B3),',
      '  catch(with_output_to(string(_), throw(X)), B4, true), same(B4),',
      '  catch(call_metered(throw(X), 1000, _, _), B5, true), same(B5),',
      '  catch(forall(member(_, [a]), throw(X)), B6, true), same(B6),',
      '  catch(throw(cyclic_ball(X, plain)), cyclic_ball(B7, P7), true), write(P7), nl, same(B7),',
      '  catch(throw(''$cyclic''(a, b)), B8, true), writeq(B8), nl.']),
    sh_join(['-s ', F], A), child(A, Out, Rc),
    atomic_list_concat(Got, '\n', Out),
    each_line([
      'throw/1 and catch/3' - same,
      'a builtin''s error: its formal...' - integer,
      '...and its culprit' - same,
      'thrown again by findall/3' - same,
      '...by with_output_to/2' - same,
      '...by call_metered/4' - same,
      '...by forall/2' - same,
      'a cycle inside the ball, the rest of it as it was' - plain,
      '...the cycle' - same,
      'a ball that only looks like a stored one is left as it is' - '''$cyclic''(a,b)'
    ], Got),
    check('...and the program ends', Rc, 0).

%% Asked in this process: through 1.10.17 the two were a fact and a fail
questions :-
    section('acyclic_term/1 and cyclic_term/1 answer the question'),
    X1 = f(X1), yes_no(cyclic_term(X1), C1), check('cyclic_term/1 of f(X) where X = f(X)', C1, yes),
    yes_no(acyclic_term(X1), A1), check('acyclic_term/1 of it', A1, no),
    yes_no(acyclic_term(f(a, g(b), [c])), A2), check('a tree is acyclic', A2, yes),
    yes_no(cyclic_term(f(a, g(b), [c])), C2), check('...and not cyclic', C2, no),
    G3 = g(a), yes_no(acyclic_term(f(G3, G3, [G3])), A3),
    check('a subterm met three times is no cycle', A3, yes),
    yes_no(acyclic_term(_), A4), check('a variable is acyclic', A4, yes),
    yes_no(cyclic_term(_), C4), check('...and not cyclic', C4, no),
    yes_no(acyclic_term(abc), A5), check('an atom is acyclic', A5, yes),
    numlist(1, 200000, L6), yes_no(acyclic_term(L6), A6), check('a list of 200000 is acyclic', A6, yes),
    numlist(1, 5000, L7), append(L7, T7, C7), T7 = C7, yes_no(cyclic_term(C7), C7a),
    check('a list of 5000 that is its own tail is cyclic', C7a, yes),
    X8 = [a|X8], yes_no(cyclic_term(g(b, [X8])), C8), check('a cycle deep inside', C8, yes),
    dag(40, D9), yes_no(acyclic_term(D9), A9),
    check('a DAG that doubles at each of 40 levels is walked once per compound', A9, yes).

%% d(T, T) forty levels down: 2^40 nodes as a tree, 41 compounds -- past
%% the quick walk's 64, so the exact one meets every compound a second time
dag(0, e) :- !.
dag(N, d(T, T)) :- N1 is N - 1, dag(N1, T).

%% `is/2' and the comparisons raise SWI's type_error(expression, E) over a
%% cyclic expression, E the side it is
arithmetic(D) :-
    section('is/2 and the comparisons over a cyclic expression: type_error(expression, E)'),
    atom_concat(D, '/arith.pl', F),
    fixture(F, [
      'r(G, E) :- catch((G, E = none), error(E0, _), (E0 = type_error(K, C) -> E = K-C ; E = E0)).',
      'deep(0, 1) :- !.',
      'deep(N, T+1) :- N1 is N - 1, deep(N1, T).',
      'main :-',
      '  X = 1+X, r(_ is X, E1), print(E1), nl,',
      '  Y = f(Y), r(_ is Y + 1, E2), print(E2), nl,',
      '  r(X > 1, E3), print(E3), nl,',
      '  r(1 < X, E4), print(E4), nl,',
      '  r(X =:= Y, E5), print(E5), nl,',
      '  deep(3000, T), V is T, print(V), nl,',
      '  r(_ is foo(1) + 1, E6), print(E6), nl.']),
    sh_join(['-s ', F], A), child(A, Out, Rc),
    atomic_list_concat(Got, '\n', Out),
    each_line([
      'is/2 over X = 1+X' - '@(expression-S_1,[S_1=1+S_1])',
      'is/2 over a cycle under +: the whole expression is named' - '@(expression-(S_1+1),[S_1=f(S_1)])',
      'X > 1: the side that is cyclic' - '@(expression-S_1,[S_1=1+S_1])',
      '1 < X: the same' - '@(expression-S_1,[S_1=1+S_1])',
      'X =:= Y, both cyclic: the first' - '@(expression-S_1,[S_1=1+S_1])',
      'an expression 3000 deep is no cycle, and is evaluated' - '3001',
      'a functor that is no function is still type_error(evaluable)' - 'evaluable-foo/1'
    ], Got),
    check('...and the program ends', Rc, 0).
