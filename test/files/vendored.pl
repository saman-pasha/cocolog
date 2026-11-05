%  The vendored libraries' single-sided rules, and swipl's own predicates
%  they call, as swipl's. Run by BOTH SWI-Prolog and cocolog, output
%  compared byte for byte.
%
%  Through 3.18.0 a `Head => Body' rule was `Head :- !, Body': a head that
%  could bind a call's variable bound it, and a call no head matched failed,
%  where swipl's head matches without binding and raises
%  existence_error(matching_rule, M:G) when none does. ordsets.pl's
%  ord_intersection/2 called '$skip_list'/3 and aggregate.pl's foreach/2
%  '$unbind_template'/1, neither of them there; and lib/lists.cicili kept
%  two stand-ins of ord_intersection/3 and ord_subtract/3 beside
%  library(ordsets)'s, so each answered more than once. A variable in an
%  answer is written `_', as swipl's names are its own. Not compared:
%  '$unbind_template'/1 of a template a clause's body wrote with a constant
%  argument, swipl's type_error(template, T): the constant stands in a cell
%  after the template's, as the value of an argument that was a variable
%  and was bound since does, and cocolog unbinds it (one =../2 made raises).

:- use_module(library(ordsets)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(aggregate)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(dcg/high_order)).

p([], R) => R = empty.
p([H|_], R) => R = first(H).
q(X, Y), X > 0 => Y = pos.
q(_, Y) => Y = other.
r(X, X) => true.
s(f(a), Y) => Y = 1.
t(a, b) => true.
w(f(X, X)) => true.
w2(f(g(a))) => true.
%% named as listing/1 names a clause's variables, so that swipl's, which
%% writes the source's names, and cocolog's, which numbers them, agree
lr(A, B), A > 0 => B = pos.
lr(_, A) => A = other.

main :-
    single_sided,
    swipl_own,
    answers,
    nested,
    asserted.

%% every answer of G, or the error's formal, its variables written `_'
all(Label, T, G) :-
    catch(( findall(T, G, Ts), R = Ts ), error(E, _), R = error(E)),
    shown(Label-R).

shown(T) :-
    copy_term(T, C), term_variables(C, Vs), maplist(=('_'), Vs),
    print(C), nl.

%% a head matches a call without binding it, a guard runs after the match,
%% and a call no head matches raises, in the module the rule's file named
single_sided :-
    all(var_list, L-R, p(L, R)),
    all(partial_list, T-R, p([x|T], R)),
    all(no_rule, R, p(foo, R)),
    all(guard_yes, Y, q(5, Y)),
    all(guard_no, Y, q(-1, Y)),
    all(repeated_var, A-B, r(A, B)),
    all(repeated_same, x, r(c, c)),
    all(repeated_other, x, r(c, d)),
    all(inner_var, Z-W, s(f(Z), W)),
    all(inner_bound, W, s(f(a), W)),
    all(bound_output, x, p([], k)),
    all(atom_args, x, t(a, b)),
    all(atom_arg_var, X, t(X, b)),
    all(inner_repeated, A-B, w(f(A, B))),
    all(inner_repeated_same, x, w(f(c, c))),
    all(nested_var, A-B, w2(f(A))),
    all(nested_inner_var, A, w2(f(g(A)))),
    all(nested_match, x, w2(f(g(a)))),
    all(library_module, U, ord_union(x, [a], U)),
    all(library_module2, D, ord_subtract(x, [a], D)),
    catch(p(_, _), E1, true), shown(E1),
    catch(ord_union(x, [a], _), E2, true), shown(E2),
    catch(p(foo, k), E3, true), print_message(error, E3).

%% '$skip_list'/3 and '$unbind_template'/1, and what the libraries make of
%% them
swipl_own :-
    all(skip_partial, N-R-T, '$skip_list'(N, [a,b|T], R)),
    all(skip_proper, N-R, '$skip_list'(N, [a,b,c], R)),
    all(skip_improper, N-R, '$skip_list'(N, [a|foo], R)),
    all(skip_atom, N-R, '$skip_list'(N, foo, R)),
    L = [a,b,c|L], '$skip_list'(N2, L, R2),
    ( R2 == L -> Same = same ; Same = other ), shown(skip_cyclic-N2-Same),
    all(unbind_value, x, ( T1 =.. [f, a], '$unbind_template'(T1) )),
    all(unbind_mixed, x, ( T2 =.. [g, _, b], '$unbind_template'(T2) )),
    all(unbind_none, x, '$unbind_template'(f)),
    all(inter2_power, I, ord_intersection([[a,b,c],[b,c,d],[c,d]], I)),
    all(inter2_one, I, ord_intersection([[a,b]], I)),
    all(inter2_empty, I, ord_intersection([], I)),
    all(foreach_ok, x, foreach(member(X, [1,2]), integer(X))),
    all(foreach_fail, x, foreach(member(X2, [1,a]), integer(X2))),
    all(foreach_bind, L3, (length(L3, 2), foreach(nth1(I3, [a,b], E3), nth1(I3, L3, E3)))),
    all(foreach_none, x, foreach(fail, true)).

%% each answer once: ord_intersection/3 and ord_subtract/3 are
%% library(ordsets)'s alone, and dcg/high_order's foreach//2 calls both
answers :-
    all(intersection, I, ord_intersection([a,b,c], [b,c,d], I)),
    all(intersection_empty, I, ord_intersection([], [b], I)),
    all(subtract, D, ord_subtract([a,b,c], [b], D)),
    all(subtract_rest, D, ord_subtract([a,b], [], D)),
    all(dcg_foreach, x, phrase(foreach(member(C, [0'a,0'b]), [C]), [0'a,0'b])),
    all(dcg_foreach_sep, S, phrase(foreach(member(C2, [0'a,0'b]), [C2], [0',]), S)).

%% a read's own rules: a file's rules on both sides of a load directive are
%% one predicate's, and each read's end puts the last clause after its own
%% (vs.pl, vsub.pl), so a goal no rule matches raises in either; and the
%% error a directive catches is reported where it stands (vs2.pl)
nested :-
    consult('vs.pl'),
    all(nested_after, x, vs(b)),
    all(nested_none, x, vs(c)),
    all(nested_inner, x, vsub(x)),
    all(nested_inner_none, x, vsub(y)),
    consult('vs2.pl').

%% a rule a program asserts: the predicate's last clause is kept last, so a
%% call no rule matches raises, and clause/2, predicate_property/2 and
%% listing/1 show the rules alone, the file's guards as they were written; a
%% guard is a file's alone, and an asserted one a clause of `,'/2, refused
asserted :-
    assertz((va(x) => true)),
    assertz((va(y) => true)),
    asserta((va(w) => true)),
    all(asserted_w, x, va(w)),
    all(asserted_y, x, va(y)),
    all(asserted_none, x, va(z)),
    all(asserted_clauses, H-B, ( H = va(_), clause(H, B) )),
    all(asserted_count, N, predicate_property(va(_), number_of_clauses(N))),
    all(asserted_guard, x, assertz((vb(Y), Y == y => true))),
    listing(va/1),
    listing(lr/2).
