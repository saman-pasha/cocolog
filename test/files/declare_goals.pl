%  dynamic/1, discontiguous/1 and multifile/1 called as goals, run by BOTH
%  SWI-Prolog and cocolog and the output compared byte for byte: each
%  takes a predicate indicator, a list of them or a comma sequence,
%  Name//Arity for a grammar rule, and declares each part IN TURN -- the
%  parts before a bad one stay declared -- raising swipl's error for the
%  first part that is none, a control construct's or an ISO predicate's
%  indicator among them. A declared predicate is defined: a call of it
%  with no clauses fails, current_predicate/1 names it and
%  predicate_property/2 says which declaration it had. A system predicate
%  that is not ISO is the program's once declared, and a call finds it
%  empty. (swipl also makes a predicate declared discontiguous or multifile
%  at run time static, so that an assert onto it is refused; cocolog asserts:
%  COMPAT.md.)

r(Label, Goal, Show) :-
    catch(( Goal -> R = Show ; R = no ), E, R = ex(E)),
    copy_term(Label-R, C), term_variables(C, Vs), bindv(Vs), print(C), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

main :- accepted, refused, edges, defined, in_turn, taken.

accepted :-
    r(disc_one, discontiguous(d1/1), yes),
    r(multi_one, multifile(m1/2), yes),
    r(disc_list, discontiguous([d2/1, d3/2]), yes),
    r(multi_list, multifile([m2/0, m3/1]), yes),
    r(disc_comma, discontiguous((d4/1, d5/1)), yes),
    r(multi_comma, multifile((m4/1, m5/2)), yes),
    r(disc_dcg, discontiguous(d6//1), yes),
    r(multi_dcg, multifile(m6//0), yes),
    r(disc_empty_list, discontiguous([]), yes),
    r(disc_twice, (discontiguous(d7/1), discontiguous(d7/1)), yes),
    r(dynamic_then, (dynamic(d8/1), discontiguous(d8/1), assertz(d8(a)), d8(X1)), X1),
    r(multi_dynamic, (dynamic(m7/1), multifile(m7/1), assertz(m7(b)), m7(X2)), X2),
    r(qualified, (discontiguous(user:d9/1), d9(_)), yes).

refused :-
    r(disc_unbound, discontiguous(_), yes),
    r(multi_unbound, multifile(_), yes),
    r(dyn_unbound, dynamic(_), yes),
    r(disc_atom, discontiguous(foo), yes),
    r(multi_atom, multifile(foo), yes),
    r(disc_name_unbound, discontiguous(_/1), yes),
    r(disc_arity_unbound, discontiguous(foo/_), yes),
    r(disc_arity_atom, discontiguous(foo/a), yes),
    r(multi_name_number, multifile(1/1), yes),
    r(disc_arity_negative, discontiguous(foo/(-1)), yes),
    r(disc_list_bad, discontiguous([d10/1, bar]), yes),
    r(disc_list_partial, discontiguous([d11/1|_]), yes),
    r(disc_comma_bad, discontiguous((d12/1, 3)), yes),
    r(disc_compound, discontiguous(f(x)), yes),
    r(disc_control, discontiguous((',')/2), yes),
    r(multi_control, multifile((;)/2), yes),
    r(disc_builtin, discontiguous(atom_length/2), yes),
    r(multi_builtin, multifile(atom_length/2), yes),
    r(dyn_builtin, dynamic(atom_length/2), yes),
    r(dyn_dcg_builtin, dynamic(atom_length//0), yes),
    r(dyn_dcg_atom, dynamic(foo//a), yes),
    r(dyn_dcg_unbound, dynamic(foo//_), yes).

%% an indicator's corners: an arity of 0 names nothing but the name (its
%% errors have no context), a grammar rule's arity is evaluated first
%% (`A + 2', is/2's errors), and a qualifier is any term
edges :-
    r(var_name0, dynamic(_/0), yes),
    r(num_name0, dynamic(1/0), yes),
    r(cmp_name0, dynamic(f(x)/0), yes),
    r(nil_name0, dynamic([]/0), yes),
    r(nilq_name0, dynamic('[]'/0), yes),
    r(nil_name1, dynamic([]/1), yes),
    r(flt_name1, dynamic(1.5/1), yes),
    r(dcg_float, dynamic(e1//1.5), yes),
    r(dcg_cmp, dynamic(e2//f(x)), yes),
    r(dcg_expr, (dynamic(e3//(1+1)), current_predicate(e3/4)), yes),
    r(dcg_num_name, dynamic(1//1), yes),
    r(dcg_var_name, dynamic(_//1), yes),
    r(dcg_var_both, dynamic(_//_), yes),
    r(dcg_neg, dynamic(e4//(-3)), yes),
    r(dcg_neg2, (dynamic(e5//(-2)), current_predicate(e5/0)), yes),
    r(dcg_name0, dynamic(1//(-2)), yes),
    r(slash_float, dynamic(e6/1.5), yes),
    r(slash_expr, dynamic(e7/(1+1)), yes),
    r(slash_both, dynamic(1/a), yes),
    r(slash_var_both, dynamic(_/_), yes),
    r(qual_var, dynamic(_:e8/1), yes),
    r(qual_bad, dynamic(1:e9/1), yes),
    r(list_tail_atom, dynamic([e10/1|foo]), yes).

%% a declared predicate with no clauses is defined: it fails, it is current
defined :-
    r(call_disc, (discontiguous(c1/1), c1(_)), yes),
    r(call_multi, (multifile(c2/1), c2(_)), yes),
    r(call_dcg, (discontiguous(c3//1), c3(_, _, _)), yes),
    r(clause_disc, (discontiguous(c4/1), clause(c4(_), B4)), B4),
    r(current_disc, (discontiguous(c5/1), current_predicate(c5/1)), yes),
    r(current_multi, (multifile(c6/2), current_predicate(c6/2)), yes),
    r(current_listed, (discontiguous(c7/1), findall(A7, current_predicate(c7/A7), L7)), L7),
    r(pp_disc, (discontiguous(c8/1), predicate_property(c8(_), discontiguous)), yes),
    r(pp_multi, (multifile(c9/1), predicate_property(c9(_), multifile)), yes),
    r(pp_static, (discontiguous(c10/1), predicate_property(c10(_), static)), yes),
    r(pp_defined, (multifile(c11/1), predicate_property(c11(_), defined)), yes),
    r(pp_no_count, (discontiguous(c12/1), predicate_property(c12(_), number_of_clauses(N12))), N12),
    r(pp_not_multi, (discontiguous(c13/1), predicate_property(c13(_), multifile)), yes),
    r(pp_dyn_count, (dynamic(c14/1), predicate_property(c14(_), number_of_clauses(N14))), N14),
    r(abolished, (discontiguous(c15/1), abolish(c15/1), c15(_)), yes).

%% the parts before the bad one are declared, the ones after it are not
in_turn :-
    r(before_bad, (catch(dynamic([t1/1, bad]), _, true), t1(_)), yes),
    r(after_bad, (catch(multifile([atom_codes/2, t2/1]), _, true), t2(_)), yes),
    r(comma_before, (catch(discontiguous((t3/1, 7)), _, true), t3(_)), yes).

%% a system predicate that is not ISO is the program's once declared
taken :-
    r(take_dynamic, (dynamic(succ/2), succ(1, X1)), X1),
    r(take_assert, (dynamic(plus/3), assertz(plus(1, 2, 99)), plus(1, 2, X2)), X2),
    r(take_disc, (discontiguous(msort/2), msort([b, a], X3)), X3),
    r(take_multi, (multifile(last/2), last([a, b], X4)), X4).
