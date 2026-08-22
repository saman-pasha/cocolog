%  The core builtins cocolog was missing, checked against SWI.
%  Run by BOTH systems, output compared byte for byte.

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

p(1). p(2). p(3).
q(X) :- p(X), X > 1.
r(a, 1). r(b, 2).

main :-
    %  ---- findall and what is built on it ----
    ( findall(X1, p(X1), A1) -> s(findall, A1) ; s(findall, no) ),
    ( findall(X2, (p(X2), X2 > 1), A2) -> s(findall_filtered, A2) ; true ),
    ( findall(_X3, fail, A3) -> s(findall_none, A3) ; true ),
    ( findall(Y1-Z1, r(Y1,Z1), A4) -> s(findall_pairs, A4) ; true ),
    ( findall(X4, p(X4), A5, [tail]) -> s(findall4, A5) ; true ),
    yn(forall(p(N1), N1 > 0), forall_yes),
    yn(forall(p(N2), N2 > 1), forall_no),
    yn(forall(fail, fail), forall_vacuous),

    %  ---- aggregate_all ----
    ( aggregate_all(count, p(_), B1) -> s(agg_count, B1) ; true ),
    ( aggregate_all(count, fail, B2) -> s(agg_count_zero, B2) ; true ),
    ( aggregate_all(sum(X5), p(X5), B3) -> s(agg_sum, B3) ; true ),
    ( aggregate_all(sum(_X6), fail, B4) -> s(agg_sum_empty, B4) ; true ),
    ( aggregate_all(max(X7), p(X7), B5) -> s(agg_max, B5) ; true ),
    ( aggregate_all(min(X8), p(X8), B6) -> s(agg_min, B6) ; true ),
    ( aggregate_all(bag(X9), p(X9), B7) -> s(agg_bag, B7) ; true ),
    ( aggregate_all(set(XA), (p(XA) ; p(XA)), B8) -> s(agg_set, B8) ; true ),
    yn(aggregate_all(max(_), fail, _), agg_max_empty),

    %  ---- between, succ, plus ----
    ( findall(C1, between(1,4,C1), C2) -> s(between_all, C2) ; true ),
    yn(between(1, 5, 3), between_check),
    yn(between(1, 5, 9), between_out),
    ( succ(3, D1) -> s(succ_up, D1) ; true ),
    ( succ(D2, 4) -> s(succ_down, D2) ; true ),
    yn(succ(_, 0), succ_zero),
    ( plus(2, 3, E1) -> s(plus_c, E1) ; true ),
    ( plus(2, E2, 5) -> s(plus_b, E2) ; true ),
    ( plus(E3, 3, 5) -> s(plus_a, E3) ; true ),

    %  ---- terms ----
    yn(ground(f(a,b)), ground_yes),
    yn(ground(f(a,_)), ground_no),
    ( term_variables(f(F1,g(F2),F1), F3) -> ( F3 == [F1,F2] -> s(term_vars, ok) ; s(term_vars, F3) ) ; true ),
    ( term_variables(f(a), F4) -> s(term_vars_none, F4) ; true ),
    yn(unify_with_occurs_check(_G1, f(a)), occurs_ok),
    yn(unify_with_occurs_check(G2, f(G2)), occurs_cyclic),

    %  ---- atoms ----
    ( atom_chars(abc, H1) -> s(atom_chars, H1) ; true ),
    ( atom_chars(H2, [x,y]) -> s(atom_chars_back, H2) ; true ),
    ( atom_chars('', H3) -> s(atom_chars_empty, H3) ; true ),
    ( char_code(a, I1) -> s(char_code, I1) ; true ),
    ( char_code(I2, 98) -> s(char_code_back, I2) ; true ),
    ( number_chars(12, J1) -> s(number_chars, J1) ; true ),
    ( number_chars(J2, ['4','2']) -> s(number_chars_back, J2) ; true ),
    ( atom_number('42', K1) -> s(atom_number, K1) ; true ),
    ( atom_number('3.5', K2) -> s(atom_number_float, K2) ; true ),
    yn(atom_number(abc, _), atom_number_not),
    ( atom_number(K3, 7) -> s(atom_number_back, K3) ; true ),
    ( upcase_atom('aBc', L1) -> s(upcase, L1) ; true ),
    ( downcase_atom('aBc', L2) -> s(downcase, L2) ; true ),
    %  a GROUND term: an unbound one would print its variable's name, and
    %  those are numbered differently by every Prolog and always will be
    ( term_to_atom(f(a,b), M1) -> s(term_to_atom, M1) ; true ),
    ( term_to_atom(M2, 'g(1,2)') -> s(term_to_atom_back, M2) ; true ),
    ( atomic_list_concat([a,b,c], N3) -> s(alc2, N3) ; true ),
    ( atomic_list_concat([a,b,c], '-', N4) -> s(alc3, N4) ; true ),
    ( atomic_list_concat(N5, '-', 'a-b-c') -> s(alc_split, N5) ; true ),
    ( atomic_list_concat([1,2], '', N6) -> s(alc_numbers, N6) ; true ),

    %  ---- sub_atom ----
    ( findall(O1, sub_atom(abc, 0, 1, _, O1), O2) -> s(sub_first, O2) ; true ),
    ( findall(O3, sub_atom(abc, _, 2, _, O3), O4) -> s(sub_len2, O4) ; true ),
    ( sub_atom(hello, 1, 3, O5, O6) -> s(sub_after, O5), s(sub_text, O6) ; true ),
    ( findall(O7-O8, sub_atom(banana, O7, _, O8, an), O9) -> s(sub_search, O9) ; true ),
    ( findall(OA, sub_atom(ab, _, _, _, OA), OB) -> s(sub_all, OB) ; true ),

    %  ---- the clause database ----
    ( findall(P1-P2, clause(p(P1), P2), P3) -> s(clause_facts, P3) ; true ),
    %  the body's SHAPE rather than its text, for the same reason
    ( clause(q(_), P4) -> ( P4 = (p(_), _ > 1) -> s(clause_rule, ok) ; s(clause_rule, P4) ) ; true ),
    yn(current_predicate(p/1), current_pred_yes),
    yn(current_predicate(nosuch/9), current_pred_no),

    %  ---- writing ----
    write(quoted_next), nl, writeq('hello world'), nl,
    write_term(f('A b'), [quoted(true)]), nl,
    write_term(1+2, [ignore_ops(true)]), nl,
    tab(3), write(indented), nl,
    true.
