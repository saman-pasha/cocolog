%  numbervars/3,4, swipl 9.0.4's (cocolog 3.40.0). numbervars/4 is
%  swipl's foreign predicate, and numbervars/3 the clause boot/syspred.pl
%  writes over it, so every error names numbervars/4. The case holds:
%  - the numbering: the order term_variables/2 meets the variables in, a
%    start other than 0, a float with an integer's value, the end, and
%    cyclic and shared terms;
%  - how the writers take the terms numbervars/3 makes;
%  - the options: singletons/1, functor_name/1 and attvar/1, Name = Value,
%    a boolean's bare name, an unknown name, and the last of a name;
%  - the errors, of the start and of the options, in swipl's order;
%  - its determinism, clause/2 and its trace's neighbour, numbervars/3's
%    own clause.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.39.0 cocolog had no numbervars/3,4, and a call raised
%  existence_error.
%
%  Not here (COMPAT.md): attributed variables, which cocolog has none of
%  (attvar(Action) is only checked); a start past 64 bits; the bound of
%  the tagged integers itself, which differs (asked of the flag here); and a
%  DAG 40 levels deep under singletons(true), whose tree both walk for ever.

%% the numbered term's structure, written as it is
w(L, T) :- print(L), write(': '), write_canonical(T), nl.

%% a term with its variables named, by a walk of its own (numbervars/3 is
%% what the case asks about)
pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

%% how a goal ended, with its bindings
t(L, G) :-
    catch(( G -> R = yes ; R = no ), E, R = caught(E)),
    ( R = caught(error(F, _)) -> pv(L-caught(F)) ; pv(L-R) ), nl.

%% a copy of T numbered from S with options O, and the end
n(L, T, S, O) :-
    copy_term(T, C),
    (   catch(numbervars(C, S, E, O), Ex, true)
    ->  ( var(Ex) -> w(L, C-E) ; Ex = error(F, _), pv(L-caught(F)), nl )
    ;   print(L-failed), nl
    ).

dag(0, f(_)) :- !.
dag(N, f(T, T)) :- N1 is N - 1, dag(N1, T).

main :-
    answers, written, options, errors, determinism.

answers :-
    format("~n=== answers~n"),
    n(plain, f(X1, _Y1, X1), 0, []),
    n(ground, f(a, [b]), 0, []),
    n(var, _, 0, []),
    n(list, [A2, _B2|A2], 0, []),
    n(order, f(A3, B3, g(A3, _C3), [B3|_D3]), 0, []),
    n(depth_first, f(g(h(X4)), _Y4, g(X4, _Z4)), 0, []),
    n(start, f(_, _), 23, []),
    n(start_neg, f(_, _), -3, []),
    n(start_float, f(_), 1.0, []),
    n(start_float_neg, f(_), -2.0, []),
    n(start_neg_zero, f(_), -0.0, []),
    n(existing, f(_X5, '$VAR'(1), _Y5), 0, []),
    n(var_in_var, '$VAR'(_), 0, []),
    n(qualified, user:f(_), 0, []),
    atom_string(abc, S6),
    n(string, f(S6, _), 0, []),
    length(L7, 1000), numbervars(L7, 0, E7), print(long(E7)), nl,
    T8 = f(X8, X8, _Y8), numbervars(T8, 5, E8), w(in_place, T8-E8),
    t(end_given, numbervars(f(_, _), 0, 2)),
    t(end_wrong, numbervars(f(_, _), 0, 3)),
    t(end_atom, numbervars(f(_), 0, a)),
    t(end_compound, numbervars(f(_), 0, f(_))),
    t(end_in_term, numbervars(f(X9), 0, X9)),
    t(undone, ( \+ \+ numbervars(f(X10), 0, _), var(X10) )),
    C11 = f(V11, C11, W11), numbervars(C11, 0, E11), w(cyclic, V11-W11-E11),
    C12 = f(C12, V12), numbervars(C12, 0, E12), w(cyclic_last, V12-E12),
    C13 = g(C13), T13 = t(L13, C13, M13, M13), numbervars(T13, 0, E13), w(cyclic_inner, L13-M13-E13),
    D14 = g(_V14, _W14), T14 = f(D14, D14, _U14), numbervars(T14, 0, E14), w(shared, T14-E14),
    dag(16, T15), numbervars(T15, 0, E15), print(dag(E15)), nl.

written :-
    format("~n=== written~n"),
    T1 = f(A1, _B1, _C1, A1), numbervars(T1, 0, _), print(T1), nl, writeq(T1), nl,
    write(T1), nl, write_canonical(T1), nl,
    T2 = f(_, _, _), numbervars(T2, 24, _), print(T2), nl,
    T3 = f(_, _), numbervars(T3, 51, _), print(T3), nl,
    T4 = f(_), numbervars(T4, -1, _), print(T4), nl,
    T5 = g(X5, _Y5, X5), numbervars(T5, 0, _, [singletons(true)]), print(T5), nl,
    writeq(T5), nl, write_canonical(T5), nl,
    T6 = h(_, Z6, Z6), numbervars(T6, 0, _, [functor_name(v)]), print(T6), nl,
    format("~w ~q ~p~n", [T1, T1, T1]),
    write_term(T1, [numbervars(true)]), nl,
    write_term(T1, [numbervars(false), quoted(true)]), nl.

options :-
    format("~n=== options~n"),
    n(singletons, f(_A1, B1, B1, _C1), 0, [singletons(true)]),
    n(singletons_off, f(_, B2, B2), 0, [singletons(false)]),
    n(singletons_order, f(A3, B3, B3, A3), 0, [singletons(true)]),
    n(singletons_start, f(_, Y4, Y4), 5, [singletons(true)]),
    n(singletons_all, f(_, _), 0, [singletons(true)]),
    forall(member(B, [true, false, on, off, 1, 0]), n(bool(B), f(_), 0, [singletons(B)])),
    n(bare_singletons, f(_), 0, [singletons]),
    n(eq_singletons, f(X5, X5, _), 0, [singletons = true]),
    n(last_wins_true, f(_), 0, [singletons(false), singletons(true)]),
    n(last_wins_false, f(_), 0, [singletons(true), singletons(false)]),
    n(functor_name, g(_, _), 0, [functor_name(xx)]),
    n(functor_quoted, g(_), 0, [functor_name('a b')]),
    n(functor_nil_atom, g(_), 0, [functor_name('[]')]),
    n(functor_last, g(_), 0, [functor_name(a), functor_name(b)]),
    n(functor_singletons, g(_, A6, A6), 0, [singletons(true), functor_name(v)]),
    n(functor_var, g(_), 0, [functor_name('$VAR'), singletons(true)]),
    forall(member(Av, [skip, bind, error]), n(attvar(Av), f(_), 0, [attvar(Av)])),
    n(unknown, f(_), 0, [foo(1), bar = 2, singletons(true)]),
    n(dag_singletons, f(g(V7), g(V7), _U7), 0, [singletons(true)]),
    D8 = g(_V8, _W8), n(dag_shared, f(D8, D8, _U8), 0, [singletons(true)]),
    C9 = f(V9, C9, W9, W9, Z9), numbervars(C9, 0, E9, [singletons(true)]), w(cyclic_none, V9-W9-Z9-E9),
    C10 = g(C10), T10 = f(V10, C10, W10, W10), numbervars(T10, 0, E10, [singletons(true)]),
    w(cyclic_apart, V10-W10-E10),
    dag(12, T11), numbervars(T11, 0, E11, [singletons(true)]), print(dag_tree(E11)), nl.

errors :-
    format("~n=== errors~n"),
    t(start_unbound, numbervars(f(_), _, _)),
    t(start_atom, numbervars(f(_), a, _)),
    t(start_digits, numbervars(f(_), '1', _)),
    t(start_fraction, numbervars(f(_), 1.5, _)),
    t(start_rational, numbervars(f(_), 1r2, _)),
    t(start_huge_float, numbervars(f(_), 1.0e30, _)),
    t(start_inf, ( X1 is inf, numbervars(f(_), X1, _) )),
    t(start_nan, ( X2 is nan, numbervars(f(_), X2, _) )),
    t(start_compound, numbervars(f(_), f(1), _)),
    t(start_ground_term, numbervars(a, _, _)),
    current_prolog_flag(max_tagged_integer, Max), current_prolog_flag(min_tagged_integer, Min),
    Above is Max + 1, Below is Min - 1,
    t(start_max, ( numbervars(f(_), Max, E3), E3 =:= Max + 1 )),
    t(start_max_two, numbervars(f(_, _), Max, _)),
    t(start_max_singletons, ( numbervars(f(X4, X4, _), Max, E4, [singletons(true)]), E4 =:= Max + 1 )),
    t(start_max_singletons_two, numbervars(f(_, Y4, Y4, _, Z4, Z4), Max, _, [singletons(true)])),
    t(start_min, ( numbervars(f(_, _, _), Min, E5), E5 =:= Min + 3 )),
    t(start_above, numbervars(f(_), Above, _)),
    t(start_below, numbervars(f(_), Below, _)),
    t(start_above_ground, numbervars(a, Above, _)),
    t(range_after_list, numbervars(f(_), Above, _, foo)),
    t(range_after_option, numbervars(f(_), Above, _, [singletons(maybe)])),
    t(range_after_attvar, numbervars(f(_), Above, _, [attvar(foo)])),
    t(count_after_option, numbervars(f(_, _), Max, _, [singletons(maybe)])),
    t(start_before_options, numbervars(f(_), a, _, foo)),
    t(unbound_before_options, numbervars(f(_), _, _, foo)),
    t(options_atom, numbervars(f(_), 0, _, foo)),
    t(options_unbound, numbervars(f(_), 0, _, _)),
    t(options_partial, numbervars(f(_), 0, _, [singletons(true)|_])),
    t(options_tail, numbervars(f(_), 0, _, [singletons(true)|foo])),
    t(option_unbound, numbervars(f(_), 0, _, [_])),
    t(option_atom, numbervars(f(_), 0, _, [foo])),
    t(option_bare_functor_name, numbervars(f(_), 0, _, [functor_name])),
    t(option_bare_attvar, numbervars(f(_), 0, _, [attvar])),
    t(option_number, numbervars(f(_), 0, _, [1])),
    atom_string(singletons, S4),
    t(option_string, numbervars(f(_), 0, _, [S4])),
    t(option_two_args, numbervars(f(_), 0, _, [singletons(true, x)])),
    t(option_eq_number, numbervars(f(_), 0, _, [1 = 2])),
    t(option_eq_unbound, ( numbervars(f(_), 0, _, [_ = 2]) )),
    forall(member(B, [maybe, yes, 2, 1.0, 'True']), t(bool(B), numbervars(f(_), 0, _, [singletons(B)]))),
    t(bool_unbound, numbervars(f(_), 0, _, [singletons(_)])),
    t(bool_eq, numbervars(f(_), 0, _, [singletons = maybe])),
    t(functor_number, numbervars(f(_), 0, _, [functor_name(1)])),
    t(functor_unbound, numbervars(f(_), 0, _, [functor_name(_)])),
    atom_string(v, S5),
    t(functor_string, numbervars(f(_), 0, _, [functor_name(S5)])),
    t(attvar_number, numbervars(f(_), 0, _, [attvar(1)])),
    t(attvar_unbound, numbervars(f(_), 0, _, [attvar(_)])),
    t(attvar_domain, numbervars(f(_), 0, _, [singletons(true), attvar(foo)])),
    t(attvar_after_scan, numbervars(f(_), 0, _, [attvar(foo), singletons(maybe)])),
    t(first_error, numbervars(f(_), 0, _, [functor_name(v), singletons(maybe), foo])),
    t(arity_two, catch(numbervars(f(_), 0), error(E6, _), (print(E6), nl))),
    %% the context names numbervars/4, from /3 as well
    catch(numbervars(f(_), a, _), error(_, C7), true), pv(ctx3(C7)), nl,
    catch(numbervars(f(_), 0, _, foo), error(_, C8), true), pv(ctx4(C8)), nl.

determinism :-
    format("~n=== determinism~n"),
    t(det3, $(numbervars(f(_), 0, _))),
    t(det4, $(numbervars(f(_), 0, _, [singletons(true)]))),
    t(det_cyclic, $(( C1 = f(C1, _), numbervars(C1, 0, _) ))),
    t(clause3, ( clause(numbervars(A2, B2, C2), Body2), Body2 == numbervars(A2, B2, C2, []) )),
    t(clause4, clause(numbervars(_, _, _, _), _)),
    t(fails_undone, ( T3 = f(X3), \+ numbervars(T3, 0, 9), var(X3) )).
