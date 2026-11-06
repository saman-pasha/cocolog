%  The vendored libraries called as a program calls them: library(aggregate),
%  assoc, ordsets, pairs, ugraphs, yall, dcg/basics and dcg/high_order, each
%  through its exports, in the modes a caller uses and the ones it should
%  not, and every answer with whether it left a choice point (det or
%  nondet, by setup_call_cleanup/3's own report), or the error it raised.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  The files are swipl's own (lib/swipl/), so what is held here is the
%  engine under them: through 3.28.0 free_variables/4 raised in cocolog
%  (its var_in_term/2 walks a term with arg(_, T, A), which cocolog's
%  arg/3 refused), must_be(list, L) of a partial list was a type error
%  where swipl's is an instantiation error (ord_intersection/2's
%  power set, a lambda's parameters), and must_be(assoc, A) asked no
%  has_type/2 (test/files/error_types.pl holds must_be/2 whole).
%
%  NOT COMPARED, each in COMPAT.md: a call that enumerates without end
%  (vertices_edges_to_ugraph(_, ...), ord_memberchk(a, _), ...), where
%  swipl's stack stops at a gigabyte and cocolog's heap grows until memory
%  is refused; get_assoc/3 of a term that is no assoc, which swipl's C
%  '$btree_find_node'/5 refuses and cocolog's copy of the library's own
%  clauses answers existence_error(matching_rule, ...); a meta-argument
%  in an error's culprit, which swipl writes user:G and cocolog G; a code
%  past ASCII, which swipl classes by the process's locale; an integer past
%  64 bits; and a dcg/basics rule generating from an unbound code, whose
%  code_type/2 enumerates in swipl and raises in cocolog.

:- use_module(library(aggregate)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(assoc)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(ordsets)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(pairs)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(ugraphs)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(yall)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(dcg/basics)).
:- use_module(library(dcg/high_order)).

:- set_prolog_flag(double_quotes, codes).

pv(T) :- \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

t(G) :-
    catch(( findall(G-D, ( setup_call_cleanup(true, G, D0 = det),
                           ( D0 == det -> D = det ; D = nondet ) ), L),
            pv(G), write(' => '), pv(L), nl ),
          E, ( pv(G), write(' raised '), pv(E), nl )).

h(S) :- write('== '), write(S), nl.

main :- aggregate, assoc, ordsets, pairs, ugraphs, yall, dcg_basics, dcg_high_order.

:- dynamic p/2, e/1.
p(a, 1). p(b, 3). p(a, 2). p(c, 3). p(b, 1).

aggregate :-
    h(aggregate),
    t(aggregate_all(count, p(_, _), _)), t(aggregate_all(count, e(_), _)),
    t(aggregate_all(sum(X1), p(_, X1), _)), t(aggregate_all(sum(X2), e(X2), _)),
    t(aggregate_all(max(X3), p(_, X3), _)), t(aggregate_all(max(X4), e(X4), _)),
    t(aggregate_all(min(X5), p(_, X5), _)), t(aggregate_all(max(X6, K6), p(K6, X6), _)),
    t(aggregate_all(min(X7, K7), p(K7, X7), _)), t(aggregate_all(bag(K8), p(K8, _), _)),
    t(aggregate_all(set(K9), p(K9, _), _)),
    t(aggregate_all(r(count, sum(X10), max(X10), bag(K10)), p(K10, X10), _)),
    t(aggregate_all(count, K11, p(K11, _), _)), t(aggregate_all(sum(X12), K12, p(K12, X12), _)),
    t(aggregate_all(max(X13), K13, p(K13, X13), _)), t(aggregate_all(bag(X14), X14, p(_, X14), _)),
    t(aggregate(count, X15^p(_, X15), _)), t(aggregate(count, p(_, _), _)),
    t(aggregate(sum(X17), p(_, X17), _)), t(aggregate(max(X18), K18^p(K18, X18), _)),
    t(aggregate(bag(X19), p(_, X19), _)), t(aggregate(set(K20), X20^p(K20, X20), _)),
    t(aggregate(count, e(_), _)), t(aggregate(sum(X21), e(X21), _)),
    t(aggregate(max(X22, K22), p(K22, X22), _)), t(aggregate(min(X23, K23), p(K23, X23), _)),
    t(aggregate(count, K24, p(K24, _), _)), t(aggregate(sum(X25), K25, p(K25, X25), _)),
    t(aggregate(r(count, max(X26)), p(_, X26), _)),
    t(aggregate_all(count, fail, _)), t(aggregate_all(foo, true, _)), t(aggregate_all(_, true, _)),
    t(aggregate(foo, true, _)), t(aggregate_all(sum(a), true, _)), t(aggregate_all(max(a), true, _)),
    t(aggregate_all(sum(X27), member(X27, [1, 2.5, 3]), _)),
    t(aggregate_all(max(X28), member(X28, [1, 2.0, 2]), _)),
    t(aggregate_all(min(X29), member(X29, [3, 1.0, 1]), _)), t(aggregate_all(count, member(_, [a, b]), 2)),
    t(aggregate_all(count, member(_, [a, b]), 3)),
    t(aggregate_all(bag(X30-Y30), member(X30-Y30, [1-_, 2-_]), _)),
    t(foreach(member(X31, [1, 2, 3]), X31 > 0)), t(foreach(member(X32, [1, 2, 3]), X32 > 1)),
    t(once(foreach(member(X33, [a, b]), member(X33, _)))), t(foreach(member(_, []), fail)),
    t(foreach(between(1, 3, X34), assertz(e(X34)))), t(findall(X35, e(X35), _)),
    t(free_variables(p(_, X36), r(X36), [], _)), t(free_variables(X37^p(K37, X37), r(K37), [], _)),
    t(free_variables(setof(Y38, p(Y38, Z38), _), Z38, [], _)),
    t(free_variables(f(A39, g(B39, A39), _), B39, [], _)), t(free_variables(\+ p(_, _), x, [], _)),
    t(free_variables(_, x, [], _)), t(free_variables(f(_), x, [w], _)),
    t(aggregate_all(count, (member(X40, [1, 2, 3]), X40 > 1), _)),
    t(aggregate_all(max(X41-Y41), member(X41-Y41, [1-a, 3-b, 2-c]), _)),
    t(aggregate(count, member(_, [a, b, a]), _)), t(aggregate(bag(X43), member(X43, [c, a, b]), _)),
    t(aggregate(set(X44), member(X44, [c, a, b, a]), _)),
    t(aggregate(count, Y45^member(_-Y45, [k-1, k-2, j-3]), _)).

assoc :-
    h(assoc),
    list_to_assoc([b-2, a-1, c-3], A0),
    t(empty_assoc(_)), t(empty_assoc(t)), t(empty_assoc(t(a, 1, <, t, t))),
    t(list_to_assoc([], _)), t(list_to_assoc([a-1, a-2], _)), t(list_to_assoc(foo, _)),
    t(list_to_assoc([a-1|_], _)), t(list_to_assoc([a], _)), t(list_to_assoc(_, _)),
    t(ord_list_to_assoc([a-1, b-2], _)), t(ord_list_to_assoc([b-1, a-2], _)),
    t(ord_list_to_assoc([a-1, a-2], _)), t(ord_list_to_assoc(foo, _)),
    t(get_assoc(b, A0, _)), t(get_assoc(z, A0, _)), t(get_assoc(_, A0, _)), t(get_assoc(a, t, _)),
    t(get_assoc(b, A0, _, _, x)), t(get_assoc(z, A0, _, _, x)),
    t(put_assoc(d, A0, 4, _)), t(put_assoc(a, A0, 9, _)), t(put_assoc(a, foo, 9, _)),
    t(put_assoc(_, A0, 9, _)),
    t(gen_assoc(_, A0, _)), t(gen_assoc(b, A0, _)), t(gen_assoc(_, A0, 3)),
    t(gen_assoc(_, t, _)), t(gen_assoc(_, foo, _)), t(gen_assoc(_, _, _)),
    t(max_assoc(A0, _, _)), t(min_assoc(A0, _, _)), t(max_assoc(t, _, _)), t(min_assoc(foo, _, _)),
    t(del_assoc(b, A0, _, _)), t(del_assoc(z, A0, _, _)), t(del_assoc(_, A0, _, _)),
    t(del_min_assoc(A0, _, _, _)), t(del_max_assoc(A0, _, _, _)), t(del_min_assoc(t, _, _, _)),
    t(assoc_to_list(A0, _)), t(assoc_to_keys(A0, _)), t(assoc_to_values(A0, _)),
    t(assoc_to_list(t, _)), t(assoc_to_list(foo, _)),
    t(is_assoc(A0)), t(is_assoc(t)), t(is_assoc(foo)), t(is_assoc(_)),
    t(is_assoc(t(a, 1, <, t, t))), t(is_assoc(t(b, 1, <, t(c, 2, <, t, t), t))),
    t(map_assoc(integer, A0)), t(map_assoc(atom, A0)), t(map_assoc(integer, t)),
    t(map_assoc([X, Y]>>(Y is X * 2), A0, _)), t(map_assoc([_, _]>>fail, A0, _)),
    t(map_assoc([X1]>>(X1 > 1), A0)), t(map_assoc(succ, A0, _)), t(map_assoc(_, A0)),
    t(must_be(assoc, A0)), t(must_be(assoc, foo)), t(must_be(assoc, _)),
    t(is_of_type(assoc, A0)), t(is_of_type(assoc, foo)),
    list_to_assoc([k1-v, k2-v, k3-w], A1),
    t(gen_assoc(_, A1, v)), t(gen_assoc(k3, A1, _)),
    t(get_assoc(1, A0, _)), t(put_assoc(1, A0, x, _)),
    numlist(1, 20, L20), findall(K-K, member(K, L20), P20), list_to_assoc(P20, A20),
    t(assoc_to_keys(A20, _)), t(max_assoc(A20, _, _)), t(del_assoc(10, A20, _, _)).

ordsets :-
    h(ordsets),
    t(is_ordset([a, b, c])), t(is_ordset([b, a])), t(is_ordset([a, a])), t(is_ordset(foo)),
    t(is_ordset(_)), t(is_ordset([a|_])), t(is_ordset([])),
    t(list_to_ord_set([c, a, b, a], _)), t(list_to_ord_set(foo, _)), t(list_to_ord_set(_, _)),
    t(list_to_ord_set([a|_], _)),
    t(ord_add_element([a, c], b, _)), t(ord_add_element([a, c], a, _)),
    t(ord_del_element([a, b, c], b, _)), t(ord_del_element([a, c], b, _)),
    t(ord_selectchk(b, [a, b, c], _)), t(ord_selectchk(z, [a, b, c], _)), t(ord_selectchk(_, [a, b], _)),
    t(ord_intersect([a, b], [b, c])), t(ord_intersect([a], [b])), t(ord_intersect([a, b], [b, c], _)),
    t(ord_intersection([a, b, c], [b, c, d], _)), t(ord_intersection([a, b, c], [b, c, d], _, _)),
    t(ord_intersection([[a, b, c], [b, c], [c, d]], _)), t(ord_intersection([], _)),
    t(ord_intersection(foo, _)), t(ord_intersection([[a], foo], _)), t(ord_intersection(_, _)),
    t(ord_intersection([[a]|_], _)),
    t(ord_disjoint([a], [b])), t(ord_disjoint([a], [a])),
    t(ord_subtract([a, b, c], [b], _)), t(ord_subtract([a, b], [c], _)),
    t(ord_union([[c], [a, b], [b]], _)), t(ord_union([], _)), t(ord_union(foo, _)),
    t(ord_union([a, c], [b], _)), t(ord_union([a, c], [b, c], _, _)),
    t(ord_subset([a], [a, b])), t(ord_subset([c], [a, b])), t(ord_subset([], [])),
    t(ord_empty(_)), t(ord_empty([])), t(ord_empty([a])),
    t(ord_memberchk(b, [a, b, c])), t(ord_memberchk(z, [a, b, c])), t(ord_memberchk(_, [a, b])),
    t(ord_symdiff([a, b, c], [b, d], _)),
    t(ord_seteq([a, b], [a, b])), t(ord_seteq([a, b], [b, a])), t(ord_seteq([a], [a, b])),
    t(ord_union([a, b], [_], _)), t(ord_subtract([a, _], [a], _)),
    t(ord_union(_, [a], _)), t(ord_subtract(_, [a], _)),
    t(ord_add_element([1, 2.0, 3], 2, _)), t(ord_union([f(a)], [f(_)], _)),
    t(ord_subset(_, [a])).

pairs :-
    h(pairs),
    t(pairs_keys_values(_, [a, b], [1, 2])), t(pairs_keys_values([a-1, b-2], _, _)),
    t(pairs_keys_values(_, [a, b], [1])), t(pairs_keys_values(foo, _, _)),
    t(pairs_keys_values([a], _, _)), t(pairs_keys_values(_, [a|_], [1, 2])),
    t(pairs_values([a-1, b-2], _)), t(pairs_values(_, [1, 2])), t(pairs_values(foo, _)),
    t(pairs_keys([a-1, b-2], _)), t(pairs_keys(_, [a])), t(pairs_keys([a], _)),
    t(group_pairs_by_key([a-1, a-2, b-3, a-4], _)), t(group_pairs_by_key([], _)),
    t(group_pairs_by_key(foo, _)), t(group_pairs_by_key([a], _)), t(group_pairs_by_key([_-1, _-2], _)),
    t(transpose_pairs([a-1, b-2, c-1], _)), t(transpose_pairs([], _)), t(transpose_pairs(foo, _)),
    t(map_list_to_pairs(atom_length, [ab, c, def], _)), t(map_list_to_pairs(atom_length, [], _)),
    t(map_list_to_pairs(atom_length, _, _)), t(map_list_to_pairs(atom_length, foo, _)),
    t(map_list_to_pairs([X, Y]>>(Y = X), [a, b], _)), t(map_list_to_pairs(fail, [a], _)),
    t(map_list_to_pairs(_, [a], _)), t(map_list_to_pairs(atom_length, [ab], [2-ab])),
    t(map_list_to_pairs(atom_length, [ab], [3-_])).

ugraphs :-
    h(ugraphs),
    G = [1-[2, 3], 2-[3], 3-[], 4-[1]],
    t(vertices_edges_to_ugraph([], [1-2, 2-3, 3-1], _)), t(vertices_edges_to_ugraph([5], [1-2], _)),
    t(vertices_edges_to_ugraph([], _, _)), t(vertices_edges_to_ugraph([], [a], _)),
    t(vertices_edges_to_ugraph(foo, [], _)),
    t(vertices(G, _)), t(edges(G, _)), t(vertices(_, _)), t(edges(foo, _)),
    t(add_vertices(G, [5, 0], _)), t(del_vertices(G, [3], _)), t(add_edges(G, [3-4, 5-1], _)),
    t(del_edges(G, [1-2, 9-9], _)), t(transpose_ugraph(G, _)), t(neighbors(1, G, _)),
    t(neighbours(9, G, _)), t(neighbors(_, G, _)), t(neighbours(1, foo, _)),
    t(complement(G, _)), t(compose(G, G, _)), t(top_sort(G, _)), t(top_sort([1-[2], 2-[1]], _)),
    t(top_sort(G, _, [x])), t(transitive_closure(G, _)), t(reachable(1, G, _)),
    t(reachable(9, G, _)), t(reachable(_, G, _)), t(ugraph_union(G, [5-[1]], _)),
    t(connect_ugraph(G, _, _)), t(connect_ugraph([], _, _)), t(top_sort([], _)),
    t(transitive_closure([1-[1]], _)), t(add_edges([], [a-b, b-a, a-a], _)),
    t(del_vertices(G, [9], _)), t(del_vertices(_, [1], _)), t(add_vertices(_, [1], _)),
    t(vertices_edges_to_ugraph([], [1-_], _)), t(edges([1-[_]], _)),
    t(neighbors(1, [1-[2]|_], _)), t(top_sort([a-[b], b-[c], c-[]], [a, b, c])).

yall :-
    h(yall),
    t(maplist([X1]>>(_ = X1), [1, 2])), t(call([X2, Y2]>>(Y2 is X2 + 1), 1, _)),
    t(call(F3/[X3]>>(X3 = F3), a)), t(call(\X4^(X4 = 1), _)), t(call(\X5^Y5^(Y5 is X5 * 2), 3, _)),
    t(call([X6]>>member(X6, [a, b]), _)), t(call([X7]>>(X7 > 0), -1)),
    t(foldl([X8, A8, B8]>>(B8 is A8 + X8), [1, 2, 3], 0, _)),
    t(is_lambda([_]>>true)), t(is_lambda(\_^true)), t(is_lambda(_/[_]>>true)), t(is_lambda(foo)),
    t(is_lambda(_)), t(is_lambda(_>>true)),
    t(lambda_calls([X9]>>foo(X9), _)), t(lambda_calls([X10]>>foo(X10), [1], _)),
    t(lambda_calls(\X11^foo(X11), [1, 2], _)),
    t(call([_]>>true, 1, 2)), t(call([]>>true)), t(call(_>>true, 1)), t(call(foo>>true, 1)),
    t(call([a]>>true, b)), t(call([a]>>true, a)), t(call([_|_]>>true, 1)), t(call(\_^true)),
    t(call(\a^true, a)), t(call(\a^true, b)), t(call(_/(\X15^(X15 = 1)), _)),
    t(call(G16/[X16]>>(X16 = G16), 1)), t(call(f(G17)/[X17]>>(X17 = G17), 1)),
    t(call(_/foo, 1)), t(call([X18]>> \Y18^(Y18 = X18), 1, _)),
    t(maplist([X19, Y19]>>atom_length(X19, Y19), [ab, c], _)),
    t(call([X20]>>(X20 = _), 1)), t(call(Free21/[X21]>>(X21 = Free21), 1)),
    t(call(foo/bar, 1)), t(call(1/[_]>>true, 1)), t(call([X23, X23]>>true, 1, 2)),
    t(call([X24, X24]>>true, 1, 1)), t(call(\X25^(\Y25^(Y25 = X25)), 1, _)),
    t(copy_term([X26]>>foo(X26, _), _)), t(call([X27]>>(X27 = Y27, Y27 == 1), 1)),
    t(call([_]>>(_ = 1), 0)), t(call(Y29/[_]>>(Y29 = 1), 0)),
    t(call([X30]>>call(X30), true)), t(call([X31]>>call(X31), fail)),
    t(call([X32]>>throw(X32), oops)), t(call([X33]>>(X33 = f(_)), f(1))).

dcg_basics :-
    h(dcg_basics),
    t(phrase(white, " ")), t(phrase(white, "x")), t(phrase(whites, "  \t", _)), t(phrase(blank, "\n")),
    t(phrase(blanks, " \n x", _)), t(phrase(nonblank(_), "ab", _)), t(phrase(nonblanks(_), "ab c", _)),
    t(phrase(blanks_to_nl, "  \nx", _)), t(phrase(blanks_to_nl, "  x", _)), t(phrase(blanks_to_nl, "  ", _)),
    t(phrase(string(_), "abc", _)), t(phrase((string(_), ","), "ab,c", _)),
    t(phrase(string_without(",", _), "ab,c", _)),
    t(phrase(alpha_to_lower(_), "A")), t(phrase(alpha_to_lower(0'a), "A")), t(phrase(alpha_to_lower(_), "1")),
    t(phrase(digits(_), "123x", _)), t(phrase(digit(_), "7")), t(phrase(integer(_), "-42")),
    t(phrase(integer(_), "+42")), t(phrase(integer(_), "4x", _)), t(phrase(integer(42), _)),
    t(phrase(float(_), "1.5e3")), t(phrase(float(_), "1.5")), t(phrase(float(_), "15")),
    t(phrase(float(1.5), _)), t(phrase(number(_), "12")), t(phrase(number(_), "1.25")),
    t(phrase(number(_), "-1.0e-3")), t(phrase(number(_), "1e10")), t(phrase(number(7), _)),
    t(phrase(number(a), _)), t(phrase(xdigits(_), "ffz", _)), t(phrase(xdigit(_), "A")),
    t(phrase(xinteger(_), "1F")), t(phrase(xinteger(255), _)), t(phrase(prolog_var_name(_), "_Foo1 x", _)),
    t(phrase(prolog_var_name(_), "foo", _)), t(phrase(eol, "\n")), t(phrase(eol, "\r\n")), t(phrase(eol, "")),
    t(phrase(eos, "")), t(phrase(eos, "a", _)), t(phrase(remainder(_), "abc")), t(phrase(atom(foo), _)),
    t(phrase(atom(_), _)), t(phrase(atom(f(x)), _)), t(phrase(atom('a b'), _)),
    t(phrase(csym(_), "ab_1 x", _)), t(phrase(csyms(_), "ab_1 x", _)), t(phrase(digits(_), "", _)),
    t(phrase(integer(_), "007")), t(phrase(float(_), "1.0Inf", _)), t(phrase(number(_), "0x1F", _)),
    t(phrase(number(_), "1r3", _)), t(phrase(integer(_), "1_000", _)), t(phrase(nonblanks(_), "", _)),
    t(phrase(string_without(_, _), "ab", _)), t(phrase(blank, "")), t(phrase(whites, "")),
    t(phrase(float(_), ".5", _)), t(phrase(float(_), "1.", _)), t(phrase(number(_), "1.5e", _)),
    t(phrase(xinteger(_), "", _)), t(phrase(alpha_to_lower(0'a), _)),
    t(phrase(number(_), "1.5e+3")), t(phrase(number(_), "-0")), t(phrase(float(_), "-0.0")).

dcg_high_order :-
    h(dcg_high_order),
    t(phrase(sequence(digit, _), "123")), t(phrase(sequence(digit, _), "12a", _)),
    t(phrase(sequence(digit, ",", _), "1,2,3")), t(phrase(sequence(digit, ",", _), "")),
    t(phrase(sequence("[", digit, ",", "]", _), "[1,2]")), t(phrase(sequence("[", digit, ",", "]", _), "[]")),
    t(phrase(sequence(integer, ",", [1, 2, 3]), _)), t(phrase(sequence(digit, [0'1, 0'2]), _)),
    t(phrase(optional(integer(_), []), "12")), t(phrase(optional(integer(_), []), "x", _)),
    t(phrase(optional(integer(X1), {X1 = none}), "x", _)),
    t(phrase(foreach(member(X2, [1, 2, 3]), integer(X2)), _)),
    t(phrase(foreach(member(X3, [1, 2, 3]), integer(X3), ", "), _)),
    t(phrase(foreach(member(_, []), "x", ","), _)), t(phrase(foreach(fail, "x"), _)),
    t(phrase(sequence(_, _), "1")),
    t(phrase(sequence(digit, ",", _), "1,", _)), t(phrase(sequence(digit, ",", _), ",1", _)),
    t(phrase(foreach(member(X4, [a, b]), atom(X4), " "), _)),
    t(phrase(sequence(blank, _), "  ", _)), t(phrase(sequence(string, ",", _), "a,b")),
    t(phrase(optional(_, []), "1")).
