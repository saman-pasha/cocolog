%  The arithmetic folds evaluate what they fold, as SWI's own clauses do
%  (cocolog 2.15.1), and term_to_atom/2 reads a bound text.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  sum_list/2 is SWI's `Sum1 is Sum0 + X' and max_list/2 `Max1 is max(H,
%  Max0)' (the first element taken as it is); aggregate_all/3's sum is
%  `S is S0 + X', its max `M is max(M0, X)' from `max(X, X)', and its witness
%  form asks number/1 of the first solution and `X > Max0' of the rest. So
%  an expression is evaluated, a rational is exact, an atom raises is/2's
%  type_error(evaluable, a/0) and an unbound element its
%  instantiation_error. Through 2.15.0 cocolog took plain numbers alone and
%  raised type_error(number, X) or type_error(evaluable, X) for the rest,
%  and term_to_atom/2 with both arguments bound wrote the term and compared
%  the texts. Found by the token benchmark (bench/tokens/README.md).

:- use_module(library(aggregate)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(lists)).       % cocolint: T1 -- swipl runs this file too, and the import is its portable form

%% Name-Result: the value the goal bound, `failed', or raised(Formal)
fd_show(Name, Goal, Value) :-
    catch(( call(Goal) -> R = Value ; R = failed ), error(F, _), R = raised(F)),
    writeq(Name-R), nl.

main :-
    fd_lists,
    fd_aggregates,
    fd_witnesses,
    fd_term_to_atom.

fd_lists :-
    fd_show(sum_expressions, sum_list([1+1, 2*3], S1), S1),
    fd_show(sum_rationals, sum_list([1r2, 1r3], S2), S2),
    fd_show(sum_mixed, sum_list([1, 2.5, 1r2], S3), S3),
    fd_show(sum_empty, sum_list([], S4), S4),
    fd_show(sum_atom, sum_list([1, a], S5), S5),
    fd_show(sum_unbound, sum_list([1, _], S6), S6),
    fd_show(max_expressions, max_list([1+1, 3*1, 2], M1), M1),
    fd_show(max_first_as_it_is, max_list([1+1], M2), M2),
    fd_show(max_lone_atom, max_list([a], M3), M3),
    fd_show(max_atom_later, max_list([2, a], M4), M4),
    fd_show(min_expressions, min_list([2*3, 4], M5), M5),
    fd_show(max_rationals, max_list([1r2, 1r3], M6), M6),
    fd_show(min_rationals, min_list([1r2, 1r3], M7), M7),
    fd_show(max_the_element, max_list([1, 2.0], M8), M8),
    fd_show(min_unbound, min_list([3, _], M9), M9).

fd_aggregates :-
    fd_show(agg_sum_expression, aggregate_all(sum(X1*2), member(X1, [1, 2, 3]), A1), A1),
    fd_show(agg_sum_rationals, aggregate_all(sum(X2), member(X2, [1r2, 1r2]), A2), A2),
    fd_show(agg_sum_mixed, aggregate_all(sum(X3), member(X3, [1, 2.5, 1r2]), A3), A3),
    fd_show(agg_sum_constant, aggregate_all(sum(X4), member(X4, [pi]), A4), A4),
    fd_show(agg_sum_atom, aggregate_all(sum(X5), member(X5, [a]), A5), A5),
    fd_show(agg_sum_unbound, aggregate_all(sum(X6), member(X6, [_]), A6), A6),
    fd_show(agg_max_expression, aggregate_all(max(X7-1), member(X7, [1, 5, 3]), A7), A7),
    fd_show(agg_min_expression, aggregate_all(min(X8*X8), member(X8, [-3, 2, 4]), A8), A8),
    fd_show(agg_max_rationals, aggregate_all(max(X9), member(X9, [1r2, 1r3]), A9), A9),
    fd_show(agg_max_lone_atom, aggregate_all(max(X10), member(X10, [a]), A10), A10),
    fd_show(agg_max_atom_later, aggregate_all(max(X11), member(X11, [1, b]), A11), A11),
    fd_show(agg_count, aggregate_all(count, member(_, [a, b, c]), A12), A12).

fd_witnesses :-
    fd_show(witness_expression_wins,
            aggregate_all(max(X1, W1), member(X1-W1, [1-a, 2+3-b, 4-c]), M1), M1),
    fd_show(witness_first_not_a_number,
            aggregate_all(max(X2, W2), member(X2-W2, [a-b]), M2), M2),
    fd_show(witness_atom_later,
            aggregate_all(max(X3, W3), member(X3-W3, [1-a, foo-b]), M3), M3),
    fd_show(witness_tie_keeps_first,
            aggregate_all(min(X4, W4), member(X4-W4, [3-a, 2-b, 2-c]), M4), M4),
    fd_show(witness_rationals,
            aggregate_all(max(X5, W5), member(X5-W5, [1r2-a, 1r3-b]), M5), M5),
    fd_show(witness_nan_never_wins,
            aggregate_all(max(X6, W6), member(X6-W6, [1-a, 1.5NaN-b, 2-c]), M6), M6),
    fd_show(witness_min_expression,
            aggregate_all(min(X7, W7), member(X7-W7, [5-a, 1+1-b, 3-c]), M7), M7).

fd_term_to_atom :-
    fd_show(both_bound_binds, term_to_atom(answer(K1, E1), 'answer(cost,24.0)'), K1/E1),
    fd_show(both_bound_layout, term_to_atom(f(a), 'f( a )'), true),
    fd_show(both_bound_differ, term_to_atom(f(a), 'f(b)'), true),
    fd_show(text_bound, term_to_atom(T4, 'g(1, 2)'), T4),
    fd_show(term_bound, term_to_atom(f(x, 'A'), A5), A5),
    fd_show(both_unbound_writes, ( term_to_atom(_, A6), atom(A6) ), true).
