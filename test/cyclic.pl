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
    questions, arithmetic(D), walks(D), c_stack(D),
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
      '  atom_length(A5, N5), writeq(N5), nl,',
      '  numlist(1, 3000, L6), append(L6, T6, C6), T6 = C6,',
      '  with_output_to(atom(A6), write_term(C6, [dotlists(true), numbervars(true)])), atom_length(A6, N6),',
      '  sub_atom(A6, 0, 18, _, P6), sub_atom(A6, _, 12, 0, S6), writeq(N6-P6-S6), nl,',
      '  with_output_to(atom(A7), write_term(C6, [no_lists(true), quoted(true), numbervars(true)])),',
      '  atom_length(A7, N7), sub_atom(A7, 0, 22, _, P7), writeq(N7-P7), nl.']),
    sh_join(['-s ', F], A), child(A, Out, Rc),
    atomic_list_concat(Got, '\n', Out),
    each_line([
      'a list of 3000 that is its own tail' - '13911-''@(S_1,[S_1=[1,2,3,4,5,''-''999,3000|S_1]])''',
      'a cycle at the end of a list of 2000' - '''2000|S_1],[S_1=[x,y|S_1]])''',
      'a cycle 3000 levels down, every level written once' - '3000-''@(g(g(''-'')))))))),[S_1=f(S_1)])''',
      'a tree 2000 deep is no cycle' - '6001-0',
      'a list of 100000 is written whole' - '588896',
      %% and written as the compounds it is (3.53.0): the tail's cycle found
      %% as the list's own walk finds it, its factor S_1 under numbervars
      %% (3.55.0: a write with none names it as the variable it is)
      'a list of 3000 its own tail, dotlists(true)' -
          '22914-''@(S_1,.(S_1= .(1,.''-''))))))),[]))''',
      'and no_lists(true)' - '34917-''@(S_1,\\''[|]\\''(S_1=\\''[|]\\''('''
    ], Got),
    check('...and the program ends', Rc, 0).

%% Which writer names the cycles: write/1, print/1, writeq/1, format/2's
%% ~w ~p ~q, with_output_to/2 -- S_1, S_2, ..., every write under numbervars,
%% as swipl binds them to '$VAR'('S_1') only then; write_canonical/1,
%% term_to_atom/2 (3.55.0: through 3.54.0 S_1) and write_term/2 with no
%% numbervars, the variables as they are
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
      '  catch(atom_length(X, _), error(type_error(T, _), _), true), writeq(T), nl.']),
    sh_join(['-s ', F], A), child(A, Out, Rc),
    atomic_list_concat(Got, '\n', Out),
    each_line([
      'write/1' - '@(S_1,[S_1=f(S_1)])',
      'print/1' - '@(S_1,[S_1=f(S_1)])',
      'format/2: ~w, ~q, ~p' - '@(S_1,[S_1=f(S_1)])|@(S_1,[S_1=f(S_1)])|@(S_1,[S_1=f(S_1)])',
      'term_to_atom/2: the variables as they are, as swipl''s PL_WRT_QUOTED writes them (3.55.0; through 3.54.0 S_1)' - '''@(_G,[_G=f(_G)])''',
      'with_output_to/2' - '"@(S_1,[S_1=f(S_1)])"',
      'write_canonical/1: the variable as it is, `='' as the compound (3.1.0, swipl''s; through 3.0.0 `_G=f(_G)'')' - '@(_G,[=(_G,f(_G))])',
      'write_term/2 with no numbervars: no S_1 among them' - '@(g(V,_G),[_G=f(_G)])',
      'atom_length/2: no text, a compound, as swipl''s (2.16.1; through 2.16.0 the length of its writing, 19)' - 'text'
    ], Got),
    check('...and the program ends', Rc, 0).

%% The message of an error over one, where it was raised, and exit 2
errors(D) :-
    section('an error over a cyclic term: its message, where, and exit status 2'),
    atom_concat(D, '/e1.pl', F1),
    fixture(F1, ['main :- X = f(X), g(X), write(after), nl.',
                 'g(X) :- arg(X, f(a), _), write(no), nl.']),
    sh_join(['-s ', F1], A1), child_err(D, A1, E1, Rc1),
    lines(['ERROR: -s main: arg/3: Type error: `integer'' expected, found `@(S_1,[S_1=f(S_1)])'' (a cyclic)',
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
    lines(['ERROR: -s main: arg/3: Type error: `integer'' expected, found `@(S_1,[S_1=f(S_1)])'' (a cyclic)',
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
    child_err(D, '--no-backtrace query "X = f(X), Y = g(X), term_to_atom(Y, _), throw(Y)"', E4, Rc4),
    check('cocolog query: the same', E4,
          'ERROR: ?-: Unknown message: @(g(S_1),[S_1=f(S_1)])'),
    check('...and query''s status for an error, 1', Rc4, 1).

%% THE CATCHER GETS THE CYCLIC TERM ITSELF, as SWI's does: the ball is
%% stored as its factors and made cyclic again where it is read. `C == B'
%% asks of one cell, so it is no walk of a cycle (`==' of two different
%% cyclic terms is one, and `walks' below holds it).
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

%% THE WALKS OVER A CYCLIC TERM (1.10.19), each held to swipl 9.0.4's
%% answer: copy_term/2, findall/3's results and nb_setval/2 keep the
%% cycle; assert refuses it (`representation_error(cyclic_term)'); unify,
%% compare, `==' and sort/2 of two cyclic terms end -- SWI's order, its
%% links included; ground/1, term_variables/2 and unify_with_occurs_check/2
%% answer; length/2, memberchk/2 and the list builtins raise
%% `type_error(list, L)' over a list that is its own tail, a format's text
%% and term_to_atom/2 `type_error(text, L)', and sort/2 takes one as the set
%% of its elements, as SWI does. Through 1.10.18 every part looped
%% (copy_term, the store, unify, compare, the occurs check, length,
%% memberchk, string_chars, a format) or overflowed the C stack (ground/1,
%% a grammar rule's translation). A DAG that doubles at each of 40 levels is in each
%% part: 2^40 nodes as a tree, which only a walk that meets a compound
%% once can finish.
%%
%% ONE ANSWER IS NOT SWI'S, on purpose: P = f(h(P), b) against
%% Q = f(h(f(h(P), c)), z). SWI links each pair of compounds it compares
%% from the first, and the link turns the third pair into another, so it
%% answers > both ways -- no order. cocolog's walk links nothing until it
%% has met more pairs than the heap holds cells (a cycle, or a DAG walked
%% as a tree), and only then asks again from the first pair, linking as
%% SWI does; these two differ well within that, so it answers the order of
%% the two trees, < and >.
walks(D) :-
    section('the walks over a cyclic term: copy, store, assert, unify, compare, variables, lists'),
    atom_concat(D, '/walks.pl', F),
    walks_fixture(F),
    walks_parts(F).

%% the fixture, a clause of its own: with the checks it was over a page
walks_fixture(F) :-
    fixture(F, [
      'r(G) :- catch((G -> R = yes ; R = no), E, (E = error(F, _), F =.. [K, A|_] -> R = K-A ; R = ball)), print(R), nl.',
      'same(T) :- ( T = f(C), C == T -> write(same) ; write(differs) ), nl.',
      'h(Z, Z).',
      'eq(A, B) :- ( true ; true ), A == B, !.',
      'deep(0, a) :- !.',
      'deep(N, g(T)) :- N1 is N - 1, deep(N1, T).',
      'dag(0, a) :- !.',
      'dag(N, d(T, T)) :- N1 is N - 1, dag(N1, T).',
      'deepv(0, V, V) :- !.',
      'deepv(N, V, g(T)) :- N1 is N - 1, deepv(N1, V, T).',
      'main :- current_prolog_flag(argv, A), last(A, P), part(P).',
      'part(copy) :-',
      '  X = f(X),',
      '  copy_term(X, Y), same(Y), r(X == Y),',
      '  copy_term(k(X, V0, V0), K), K = k(KX, KA, KB), same(KX), r(KA == KB), r(var(KA)),',
      '  r(K \\== k(X, V0, V0)),',
      '  findall(X, true, [F1]), same(F1),',
      '  findall(t(X, Z0), member(Z0, [1, 2]), [t(F2, 1), t(F3, 2)]), same(F2), same(F3),',
      '  findall(W-X, member(W, [a]), [_-F4]), same(F4),',
      '  nb_setval(k, X), nb_getval(k, V1), same(V1),',
      '  nb_setval(k, g(X, X)), nb_getval(k, g(V2, V3)), same(V2), r(V2 == V3),',
      '  dag(40, D), copy_term(D, DC), r(D == DC),',
      '  write(done), nl.',
      'part(assert) :-',
      '  X = f(X),',
      '  r(assertz(p(X))),',
      '  B = (a, B), r(assertz((q :- B))),',
      '  L = (L, a), r(assertz((s :- L))),',
      '  G = [x|G], r(assertz((g --> G))),',
      '  C = (x, C), r(assertz((c --> C))), I = (I ; [x]), r(asserta((i --> y, I))),',
      '  D = (x, D), r(dcg_translate_rule((d --> D), _)), r(phrase(D, [x])),',
      '  r(asserta(p(X))),',
      '  r(catch(p(_), error(existence_error(_, _), _), fail)),',
      '  dag(14, DB), r(assertz(big(DB))), big(BB), r(BB == DB),',
      '  write(done), nl.',
      'part(unify) :-',
      '  A1 = f(A1), A2 = f(A2), r(A1 = A2), r(A1 == A2), compare(O1, A1, A2), print(O1), nl,',
      '  C1 = f(C1, a), C2 = f(C2, b), compare(O2, C1, C2), print(O2), nl, r(C1 = C2), r(C1 == C2),',
      '  D1 = g(D1, 1), D2 = g(D2, 2), r(D1 @< D2), r(D2 @< D1),',
      '  X = f(X), sort([X, A1, C1], S1), length(S1, NS1), print(NS1), nl,',
      '  r(h(A1, A2)), r(eq(A1, A2)), r(eq(C1, C2)),',
      '  B1 = [1, 2|B1], B2 = [1, 2, 1, 2|B2], r(B1 = B2), r(B1 == B2),',
      '  E1 = f(E1, V), E2 = f(E2, b), r(E1 = E2), print(V), nl,',
      '  P = f(S, b), S = h(P), Q = f(S2, z), S2 = h(R), R = f(S, c),',
      '  compare(O4, P, Q), compare(O5, Q, P), print(O4/O5), nl,',
      '  X3 = f(X3, a), Z3 = f(W3, b), W3 = f(Z3, a),',
      '  findall(O6, (member(K6, [0, 1, 2, 3]), length(_, K6), compare(O6, X3, Z3)), Os6), print(Os6), nl,',
      '  dag(40, G1), dag(40, G2), r(G1 = G2), r(G1 == G2), compare(O3, G1, G2), print(O3), nl,',
      '  write(done), nl.',
      'part(vars) :-',
      '  X = f(X), r(ground(X)), E1 = f(E1, _), r(ground(E1)),',
      '  T1 = f(T1, P, Q, P), term_variables(T1, TV), r(TV == [P, Q]),',
      '  T2 = f(A2, T3, B2), T3 = g(T2, C2), term_variables(T2, TV2), r(TV2 == [A2, C2, B2]),',
      '  T4 = f(U4, B4), U4 = g(T4, C4), term_variables(T4, TV5), r(TV5 == [C4, B4]),',
      '  dag(40, D), r(ground(D)), dag(40, D2), term_variables(h(D2, Z), TV3), r(TV3 == [Z]),',
      '  numlist(1, 300000, NL), r(ground(NL)), term_variables(f(NL, W), TV4), r(TV4 == [W]),',
      '  write(done), nl.',
      'part(occurs) :-',
      '  X = f(X),',
      '  r(unify_with_occurs_check(U1, f(U1))), r(unify_with_occurs_check(X, X)),',
      '  r(unify_with_occurs_check(f(Y1, Y1), f(Z1, g(Z1)))),',
      '  A1 = f(A1), A2 = f(A2), r(unify_with_occurs_check(A1, A2)),',
      '  r(unify_with_occurs_check(g(X, V), g(X, h(V)))),',
      '  r(unify_with_occurs_check(g(X, _V2), g(X, h(X)))),',
      '  deep(6000, DT), r(unify_with_occurs_check(DU, DT)), r(DU == DT),',
      '  deep(6000, DT2), r(unify_with_occurs_check(V5, f(DT2, V5))),',
      '  deepv(100, V6, T6), r(unify_with_occurs_check(V6, f(T6))),',
      '  dag(40, DG), r(unify_with_occurs_check(_, DG)),',
      '  write(done), nl.',
      'part(lists) :-',
      '  L = [a|L],',
      '  r(length(L, _)), r(msort(L, _)), r(atom_codes(_, L)), r(atomic_list_concat(L, _)), r(is_list(L)),',
      '  numlist(1, 3000, NL0), append(NL0, LT, LL), LT = LL, r(length(LL, _)), r(is_list(LL)),',
      '  r(length(L, 3)), sort(L, SL), print(SL), nl,',
      '  L3 = [b, a, c|L3], sort(L3, SL3), print(SL3), nl,',
      '  r(sort(0, @>=, L3, _)), r(sort(0, @<, L3, _)),',
      '  r(proper_length(L, _)), r(is_set(L)),',
      '  r(memberchk(z, L3)), r(memberchk(c, L3)),',
      '  r(atom_chars(_, L)), r(number_chars(_, L)), r(string_chars(_, L)), r(string_codes(_, L)),',
      '  r(format(atom(_), L, [])), r(term_to_atom(_, L)),',
      '  catch(format(atom(_), "~s", [L]), error(S1, _), true), functor(S1, N1, A1),',
      '  catch(format(atom(_), "~s", [f(x)]), error(S2, _), true), functor(S2, N2, A2), r(N1/A1 == N2/A2),',
      '  N3 = [1, 2|N3], r(sum_list(N3, _)), r(max_list(N3, _)), r(min_list(N3, _)),',
      '  write(done), nl.']).

walks_parts(F) :-
    walk_part(F, copy, [
      'copy_term/2 keeps the cycle' - same,
      '...and the copy is == the original' - yes,
      'a cycle beside a variable met twice' - same,
      '...the variable copied once' - yes,
      '...as a fresh one' - yes,
      '...not the original''s' - yes,
      'findall/3''s result' - same,
      'two results, the first' - same,
      '...and the second' - same,
      'a cycle inside a result' - same,
      'nb_setval/2 and nb_getval/2' - same,
      'a global that holds one twice' - same,
      '...as one term, twice' - yes,
      'a DAG of 40 levels copied, and == its copy' - yes,
      '...done' - done]),
    walk_part(F, assert, [
      'assertz/1 of a cyclic head: representation_error(cyclic_term)' - 'representation_error-cyclic_term',
      'a body that is its own tail' - 'representation_error-cyclic_term',
      'a body that is its own first goal' - 'representation_error-cyclic_term',
      'a grammar rule whose body is a cyclic list, stored as the clause of -->/2 it is' - 'representation_error-cyclic_term',
      '...a cyclic conjunction' - 'representation_error-cyclic_term',
      '...a cyclic disjunction after a call, by asserta/1' - 'representation_error-cyclic_term',
      'dcg_translate_rule/2 of a cyclic body: type_error(acyclic_term), refused before it is translated' - 'type_error-acyclic_term',
      '...and phrase/2 of one' - 'type_error-acyclic_term',
      'asserta/1' - 'representation_error-cyclic_term',
      '...and nothing was stored' - no,
      'a DAG of 14 levels is no cycle: asserted whole' - yes,
      '...and read back ==' - yes,
      '...done' - done]),
    walk_part(F, unify, [
      'two cyclic terms unify' - yes,
      '...are ==' - yes,
      '...and compare =' - '=',
      'compare/3 of two that differ past the cycle' - '<',
      '...which do not unify' - no,
      '...and are not ==' - no,
      '@< one way' - yes,
      '...and not the other' - no,
      'sort/2 of three, two of them equal' - '2',
      'a head that names its variable twice' - yes,
      '== in a body that holds a construct' - yes,
      '...and its no' - no,
      'two cyclic lists of different periods unify' - yes,
      '...and are ==' - yes,
      'a variable inside a cycle is bound' - yes,
      '...to what the other holds there' - b,
      'two that SWI orders > both ways: the order of the trees they unfold to' - '(<)/(>)',
      'asked again from the first pair, whatever the heap''s length' - '[>,>,>,>]',
      'two DAGs of 40 levels unify' - yes,
      '...are ==' - yes,
      '...and compare =' - '=',
      '...done' - done]),
    walk_part(F, vars, [
      'ground/1 of a cyclic term' - yes,
      '...and of one with a variable in it' - no,
      'term_variables/2 of a cycle' - yes,
      '...through two compounds, in the order first met' - yes,
      '...and in SWI''s order where a cycle has two of them' - yes,
      'ground/1 of a DAG of 40 levels' - yes,
      'term_variables/2 of one' - yes,
      'ground/1 of a list of 300000' - yes,
      '...and term_variables/2 of it' - yes,
      '...done' - done]),
    walk_part(F, occurs, [
      'unify_with_occurs_check/2 refuses X = f(X)' - no,
      '...takes a cyclic term unified with itself' - yes,
      '...refuses a cycle made through two bindings' - no,
      '...takes two cyclic terms' - yes,
      '...refuses a binding into one''s neighbour' - no,
      '...takes a binding to a cyclic term' - yes,
      '...takes a tree 6000 deep' - yes,
      '...binding it whole' - yes,
      '...refuses a variable beside a tree 6000 deep' - no,
      '...and one 100 compounds down, past the quick walk''s 64' - no,
      '...and a DAG of 40 levels' - yes,
      '...done' - done]),
    walk_part(F, lists, [
      'length/2 of a list that is its own tail' - 'type_error-list',
      'msort/2' - 'type_error-list',
      'atom_codes/2' - 'type_error-list',
      'atomic_list_concat/2' - 'type_error-list',
      'is_list/1' - no,
      'length/2 of a list of 3000 that comes back to its start' - 'type_error-list',
      '...is_list/1' - no,
      'length/2 asked for a length' - 'type_error-list',
      'sort/2 takes it as the set of its elements' - '[a]',
      '...three of them' - '[a,b,c]',
      'sort/4 keeping duplicates refuses it' - 'type_error-list',
      'sort/4 dropping them takes it' - yes,
      'proper_length/2' - no,
      'is_set/1' - no,
      'memberchk/2 of what is not in it' - 'type_error-list',
      '...and of what is' - yes,
      'atom_chars/2' - 'type_error-list',
      'number_chars/2' - 'type_error-list',
      'string_chars/2' - 'type_error-list',
      'string_codes/2' - 'type_error-list',
      'format/3''s format' - 'type_error-text',
      'term_to_atom/2 reading it' - 'type_error-text',
      'format/3''s ~s raises what it raises over any term that is not text' - yes,
      %% the folds' C walks (3.42.1): past as many steps as the heap has
      %% cells, a list is its own tail, and they fail as through 3.42.0,
      %% where swipl's single-sided rules walk it for ever
      'sum_list/2 of numbers that are their own tail' - no,
      '...max_list/2' - no,
      '...min_list/2' - no,
      '...done' - done]).

%% one part of the walks fixture, a child of its own: a part that loops
%% takes no other part's lines with it
walk_part(F, Part, Want) :-
    sh_join(['-s ', F, ' -- ', Part], A), child(A, Out, Rc),
    atomic_list_concat(Got, '\n', Out),
    each_line(Want, Got),
    atom_concat(Part, ': ...and the program ends', Label),
    check(Label, Rc, 0).

%% A WRITE TOO DEEP FOR THE C STACK (3.59.0): past 1024 levels, and before
%% each portray goal, the writer asks how much of its thread's C stack is
%% left, and stops where too little is: the write in hand puts out nothing
%% and its builtin raises resource_error(c_stack). Through 3.58.2 a SIGSEGV,
%% past some 45 000 levels of f(...) on 8 MB. What swipl holds is
%% test/files/cyclic_depth.pl's; these are cocolog's own -- a portray goal at
%% each level, which swipl does not end in five minutes; stdout, where
%% swipl's stream keeps what its C stack had room for and cocolog's nothing
%% (COMPAT.md); statistics(c_stack); a stack of 1 MB; a library(thread)
%% thread and a green task, each on a C stack of its own; the uncaught
%% message; a row a store cannot write.
c_stack(D) :-
    section('a write too deep for the C stack: resource_error(c_stack), in every thread'),
    atom_concat(D, '/cstack.pl', F),
    c_stack_fixture(F),
    c_stack_parts(D, F).

c_stack_fixture(F) :-
    fixture(F, [
      ':- use_module(library(thread)).',
      'deep(0, a) :- !.',
      'deep(N, f(T)) :- N1 is N - 1, deep(N1, T).',
      'pg(zz, _) :- write(''ZZ'').',
      'pw(_, _) :- deep(500, D), with_output_to(string(_), write(D)), fail.',
      'portray(zz) :- write(''ZZ'').',
      'r(G) :- catch((G -> R = yes ; R = no), E, (E = error(F, C) -> R = F-C ; R = ball(E))), print(R), nl.',
      'w(_).',
      'main :- current_prolog_flag(argv, A), last(A, P), part(P).',
      'part(portray) :-',
      '  deep(200000, T),',
      '  r(with_output_to(string(_), write_term(T, [portray_goal(pg)]))),',
      '  r(with_output_to(string(_), print(T))), r(format(atom(_), "~p", [T])),',
      '  with_output_to(string(S), print(f(zz))), print(S), nl,',
      '  write(done), nl.',
      'part(stdout) :-',
      '  deep(200000, T), write(before),',
      '  catch(write(T), error(E, _), true), write(after), nl, print(E), nl,',
      '  X = g(T, X), write(before),',
      '  catch(write(X), error(E2, _), true), write(after), nl, print(E2), nl,',
      '  write(before), catch(print(X), error(E3, _), true), write(after), nl, print(E3), nl,',
      '  write(before), catch(portray_clause(T), error(E4, _), true), write(after), nl, print(E4), nl,',
      '  portray_clause(after(f(g(x)))),',
      '  write(done), nl.',
      'part(stats) :-',
      '  statistics(c_stack, L), ( integer(L), L > 1048576 -> print(yes) ; print(L) ), nl,',
      '  write(done), nl.',
      'part(small) :-',
      '  statistics(c_stack, L), ( L =< 1048576, L >= 524288 -> print(yes) ; print(L) ), nl,',
      '  deep(20000, T), r(with_output_to(string(_), write(T))),',
      '  deep(2000, T2), with_output_to(string(S2), write(T2)), string_length(S2, N2), print(N2), nl,',
      '  r(with_output_to(string(_), write_term(T, [portray_goal(pw)]))),',
      '  write(done), nl.',
      'part(thread) :-',
      '  thread_create((deep(200000, T), catch(with_output_to(string(_), write(T)), error(E, _), true),',
      '                 print(E), nl), I1),',
      '  thread_join(I1, S1), print(S1), nl,',
      '  thread_create((deep(200000, T2), with_output_to(string(_), write(T2))), I2),',
      '  thread_join(I2, S2),',
      '  ( S2 = error(M2), sub_atom(M2, _, _, _, ''resource_error(c_stack)'') -> print(c_stack) ; print(S2) ), nl,',
      '  write(done), nl.',
      'part(green) :-',
      '  async_run((go(\\+ \\+ (deep(200000, T), r(with_output_to(string(_), write(T)))), G1), await(G1))),',
      '  async_run((go(deep(200000, _), G2), r(await(G2)))),',
      '  async_run(\\+ \\+ (deep(200000, T3), r(go(w(T3), _)))),',
      '  async_run(\\+ \\+ (deep(200000, T4), channel(C4), r(channel_send(C4, T4)))),',
      '  r(async_run(deep(200000, _))),',
      '  deep(200000, T5), r(async_run(w(T5))),',
      '  write(done), nl.',
      'part(store) :-',
      '  deep(200000, T), r(assertz(dp(T))), r(current_predicate(dp/1)),',
      '  deep(2000, T2), r(assertz(dq(T2))), r(dq(T2)),',
      '  write(done), nl.',
      'part(consult) :-',
      '  current_prolog_flag(argv, A), append(_, [X, consult], A), consult(X),',
      '  write(after), nl, r(current_predicate(dx/1)), write(done), nl.',
      'part(uncaught) :-',
      '  deep(200000, T), write(before), write(T).',
      'part(message) :-',
      '  print_message(error, error(resource_error(c_stack), _)).']).

c_stack_parts(D, F) :-
    c_stack_part(F, '', portray, [
      'a portray goal asked at each of 200000 levels: stopped before the goal'
          - 'resource_error(c_stack)-context(system:write_term/2,_G)',
      'print/1 asking portray/1 at each' - 'resource_error(c_stack)-context(system:print/1,_G)',
      '...and format/3''s ~p' - 'resource_error(c_stack)-context(system:format/3,_G)',
      'and the next portray goal is asked as before' - '"f(ZZ)"',
      '...done' - done]),
    c_stack_part(F, '', stdout, [
      'a write to stdout puts out nothing of the term' - beforeafter,
      '...and raises' - 'resource_error(c_stack)',
      'nor of a cyclic term whose factors run out' - beforeafter,
      '...raising it' - 'resource_error(c_stack)',
      '...by print/1 asking portray/1 of the factors' - beforeafter,
      '...raising it' - 'resource_error(c_stack)',
      '...nor of a clause by portray_clause/1' - beforeafter,
      '...raising it' - 'resource_error(c_stack)',
      '...and the next clause it lays out is whole' - 'after(f(g(x))).',
      '...done' - done]),
    c_stack_part(F, '', stats, [
      'statistics(c_stack, L): the thread''s C stack, in bytes' - yes,
      '...done' - done]),
    c_stack_part(F, 'ulimit -s 1024 && ', small, [
      'under ulimit -s 1024, statistics(c_stack) says so' - yes,
      'a tree 20000 deep is too deep there' - 'resource_error(c_stack)-context(system:write/1,_G)',
      '...and one 2000 deep is written whole' - '6001',
      'a portray goal that writes 500 levels of its own: stopped short of it'
          - 'resource_error(c_stack)-context(system:write_term/2,_G)',
      '...done' - done]),
    c_stack_part(F, '', thread, [
      'a library(thread) thread asks its own C stack' - 'resource_error(c_stack)',
      '...and goes on to its end' - true,
      'uncaught there, the thread''s status names it' - c_stack,
      '...done' - done]),
    c_stack_part(F, '', green, [
      'a green task asks its worker''s C stack' - 'resource_error(c_stack)-context(system:write/1,_G)',
      'a task''s answer too deep to hand back: await/1 raises it' - 'resource_error(c_stack)-_G',
      'go/2 of a goal too deep to hand over' - 'resource_error(c_stack)-_G',
      'channel_send/2 of a term too deep' - 'resource_error(c_stack)-_G',
      'async_run/1 whose answer is too deep to hand back' - 'resource_error(c_stack)-_G',
      'async_run/1 of a goal too deep' - 'resource_error(c_stack)-_G',
      '...done' - done]),
    atom_concat(D, '/kb', KB),
    sh_join(['--embed ', KB, ' '], Embed),
    c_stack_part(F, Embed, store, [
      'a clause too deep for the store to write as a row'
          - 'resource_error(c_stack)-context(system:assertz/1,_G)',
      '...is not asserted' - no,
      'one 2000 deep is' - yes,
      '...and read back' - yes,
      '...done' - done]),
    c_stack_consult(D, F),
    sh_join(['--no-backtrace -s ', F, ' -- uncaught'], A1), child_err(D, A1, E1, Rc1),
    re_replace_atom('[0-9][0-9,]*[0-9]', 'N', E1, E1n),
    lines(['', 'ERROR: -s main: write/1: C-stack limit (N bytes) exceeded.',
           'ERROR: Use the shell command ulimit -s size to enlarge the limit.'], W1),
    check('uncaught: swipl''s message, the bytes the thread''s', E1n, W1),
    check('...and the exit status is 2', Rc1, 2),
    sh_join(['-s ', F, ' -- message'], A2), child_err(D, A2, E2, Rc2),
    re_replace_atom('[0-9][0-9,]*[0-9]', 'N', E2, E2n),
    lines(['ERROR: C-stack limit (N bytes) exceeded.',
           'ERROR: Use the shell command ulimit -s size to enlarge the limit.'], W2),
    check('print_message/2 of it', E2n, W2),
    check('...and the program ends', Rc2, 0).

%% A CONSULT UNDER A STORE of a clause too deep for the C stack to write
%% as a row (a term_expansion/2 makes it): reported and passed over, and
%% the writes after it whole -- the refusal leaves the writer's flag set
%% for no builtin to clear, and each write begins by clearing it
c_stack_consult(D, F) :-
    atom_concat(D, '/xpand.pl', X),
    fixture(X, [
      'xdeep(0, a) :- !.',
      'xdeep(N, f(T)) :- N1 is N - 1, xdeep(N1, T).',
      'term_expansion(go, dx(T)) :- xdeep(200000, T).',
      'go.',
      ':- write(read), nl.',
      'go.',
      ':- portray_clause(f(x)).']),
    atom_concat(D, '/kb2', KB),
    sh_join(['--embed ', KB, ' -s ', F, ' -- ', X, ' consult'], A),
    atom_concat(A, ' 2>/dev/null', A0),
    child(A0, Out, Rc), atomic_list_concat(Got, '\n', Out),
    each_line([
      'a consult under a store: the file read on past the clause' - read,
      '...and past it again, portray_clause/1 the first write after it' - 'f(x).',
      '...and the program after it' - after,
      '...the clause not in the store' - no,
      '...done' - done], Got),
    check('consult: ...and the program ends', Rc, 0),
    child_err(D, A, E, _),
    lines(['ERROR: xpand.pl:4:',
           'ERROR:    dx/1: a clause too deep for the C stack to write',
           'ERROR: xpand.pl:6:',
           'ERROR:    dx/1: a clause too deep for the C stack to write'], W),
    check('...reported where it stands', E, W).

%% one part of the fixture, a child of its own, PRE before the binary (a
%% ulimit) and ARGS before -s (a store)
c_stack_part(F, Pre, Part, Want) :-
    (   sub_atom(Pre, 0, _, _, ulimit)
    ->  cocolog(C), sh_join([Pre, C, ' -s ', F, ' -- ', Part], Cmd),
        proc_run(Cmd, 120000, Raw0, Rc), chomp(Raw0, Body), atom_codes(Raw, Body),
        re_replace_atom('_G[0-9]+', '_G', Raw, Out)
    ;   sh_join([Pre, '-s ', F, ' -- ', Part], A), child(A, Out, Rc)
    ),
    atomic_list_concat(Got, '\n', Out),
    each_line(Want, Got),
    atom_concat(Part, ': ...and the program ends', Label),
    check(Label, Rc, 0).
