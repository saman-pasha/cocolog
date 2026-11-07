%  What a determinism error names when a guarded clause's last call goes
%  into a library predicate: the frame the guard reached, as swipl's
%  pl-wam.c names it -- the predicate with its module, lists:append/3,
%  error:is_of_type/2, assoc:gen_assoc_/3, and the helper its clause called
%  last by swipl's own name, lists:append_/2, lists:reverse/4,
%  lists:find_nth0/4, '$length3'/3 -- a predicate of swipl's system named
%  with none. The library(lists) predicates cocolog writes in Prolog are
%  swipl's clauses, so the answers are swipl's too: nth0/4 of a bound index
%  is deterministic and checks it, selectchk/3 commits to the first match,
%  reverse/2 of a partial list ends. And an unknown procedure a library's
%  frame calls is named by that frame (context(lists:max_member_/4, _)).
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte; each
%  line is one of swipl 9.0.4's answers. The libraries are imported before
%  the clauses are read, and every predicate a case calls is called once
%  first (`warm'): swipl's first call of one it has not resolved yet makes
%  no last call. Not here (COMPAT.md): a library(lists) predicate cocolog
%  answers in C -- nth0/3 and nth1/3 of a bound index, last/2 of a proper
%  list -- whose failure names it, where swipl's names the helper its
%  clause reached (lists:nth0_det/3, lists:last_/3); and a system
%  predicate swipl had not resolved when the clause was read (msort/2),
%  whose error names the caller.

:- use_module(library(lists)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(error)).
:- use_module(library(assoc)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(pairs)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(ordsets)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(dcg/high_order)).

warm :-
    append([], [], _), append([[]], _), prefix([], []), select(a, [a], _),
    select(a, [a], b, _), selectchk(a, [a], _), selectchk(a, [a], b, _),
    nextto(a, b, [a, b]), same_length([], []), reverse([], _), last([a], _),
    length([], _), permutation([], _), nth0(0, [a], _, _), nth1(1, [a], _, _),
    nth0(0, [a], _), member(a, [a]), delete([], a, _), proper_length([], _),
    flatten([], _), clumped([], _), max_member(_, [a]), min_member(_, [a]),
    sum_list([], _), max_list([1], _), min_list([1], _), numlist(1, 1, _),
    is_set([]), list_to_set([], _), intersection([], [], _), union([], [], _),
    subset([], []), subtract([], [], _), is_of_type(integer, 1),
    list_to_assoc([], A), put_assoc(k, A, v, A1), get_assoc(k, A1, _),
    ignore(gen_assoc(_, A1, _)), pairs_keys_values(_, [], []),
    ord_subtract([], [], _), ord_memberchk(a, [a]), ord_union([], [], _),
    max_member(@<, _, [a]), min_member(@<, _, [a]),
    phrase(sequence(q, [x]), [], _).

q(_) --> [].

%% ---- a choice point left: the frame the guard reached --------------------
n1 :- $, append(_, _, [1, 2]).
n2 :- $, append([_, [2]], [1, 2]).
n3 :- $, prefix(_, [1, 2]).
n4 :- $, select(_, [1, 2], _).
n5 :- $, select(_, [1, 2], _, _).
n6 :- $, nextto(_, _, [1, 2, 3]).
n7 :- $, same_length(_, _).
n8 :- $, reverse(_, _).
n9 :- $, last([1|_], _).
n10 :- $, length(_, _).
n11 :- $, length([a|_], _).
n12 :- $, permutation([1, 2], _).
n13 :- $, permutation(_, [1, 2]).
n14 :- $, nth0(_, [a, b], _, _).
n15 :- $, nth1(_, [a, b], _, _).
n16 :- $, nth0(_, [a, b], _).
n17 :- $, member(_, [1, 2]).
n18 :- $, gen_assoc(_, t(k, v, <, t, t), _).
n19 :- $, between(1, 3, _).
n20 :- $, user_two.
user_two :- member(_, [1, 2]).

%% ---- a failure: the frame that failed ------------------------------------
f1 :- $, member(_, []).
f2 :- $, append([[1]], [2]).
f3 :- $, append([1], _, [2]).
f4 :- $, prefix([1], [2]).
f5 :- $, select(c, [a, b], _).
f6 :- $, select(_, [], _).
f7 :- $, selectchk(c, [a], _).
f8 :- $, select(c, [a], _, _).
f9 :- $, selectchk(c, [a], _, _).
f10 :- $, nextto(a, b, [a]).
f11 :- $, delete(a, x, _).
f12 :- $, nth0(5, [a], _, _).
f13 :- $, nth1(5, [a], _, _).
f14 :- $, nth0(2, [a, b], _, _).
f15 :- $, nth0(_, [], _).
f16 :- $, last([], _).
f17 :- $, proper_length([a|_], _).
f18 :- $, proper_length([a], 2).
f19 :- $, same_length([a], []).
f20 :- $, reverse([a], [b]).
f21 :- $, permutation([a], [b]).
f22 :- $, flatten(a, [b]).
f23 :- $, clumped([a], []).
f24 :- $, clumped([a, a, b], [a-1|_]).
f25 :- $, max_member(_, []).
f26 :- $, min_member(_, []).
f27 :- $, sum_list([1], 2).
f28 :- $, max_list([], _).
f29 :- $, max_list([1, 2], 1).
f30 :- $, min_list([1, 2], 2).
f31 :- $, numlist(3, 1, _).
f32 :- $, is_set([a, a]).
f33 :- $, list_to_set([a], [b]).
f34 :- $, intersection([a], [b], [c]).
f35 :- $, union([a], [b], [c]).
f36 :- $, subset([a], [b]).
f37 :- $, subtract([a], [b], []).
f38 :- $, is_of_type(integer, a).
f39 :- $, is_of_type(list(integer), [a]).
f40 :- $, pairs_keys_values([a-1], [b], _).
f41 :- $, list_to_assoc([a-1], t).
f42 :- $, get_assoc(b, t(a, 1, <, t, t), _).
f43 :- $, ord_subtract([a], [a], [a]).
f44 :- $, ord_memberchk(b, [a]).
f45 :- $, ord_union([a], [b], [a]).
f46 :- $, max_member(@<, _, []).
f47 :- $, reverse([a, b], [a, b]).
f48 :- $, length([a], 2).
f49 :- $, user_none.
user_none :- fail.

%% ---- no choice point left, and swipl's answers ---------------------------
d1 :- $, reverse(_, [1, 2]).
d2 :- $, nth0(1, [a, b, c], _, _).
d3 :- $, nth1(1, [a, b], _, _).
d4 :- $, prefix([1], [1, 2]).
d5 :- $, select(_, [1], _, _).
d6 :- $, list_to_set([a, b, a], _).
d7 :- $, clumped([a, a, b], _).

runs([n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16,
      n17, n18, n19, n20,
      f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, f16,
      f17, f18, f19, f20, f21, f22, f23, f24, f25, f26, f27, f28, f29, f30,
      f31, f32, f33, f34, f35, f36, f37, f38, f39, f40, f41, f42, f43, f44,
      f45, f46, f47, f48, f49,
      d1, d2, d3, d4, d5, d6, d7]).

%% each goal's answers, all of them
answers([ selectchk(_, [a, b], [a]), selectchk(b, [a, b, b], _),
          reverse(_, [1, 2]), length(L, L), length([a|T], T),
          nth0(1, [a, b, c], _, _), nth1(2, [a, b, c], _, _), nth0(_, _, x, [a]),
          nth1(_, [a, b], _, _), nth0(1, _, x, [a, b]),
          prefix(_, [1, 2]), select(_, [1, 2], _, _), select(b, _, x, [a, x]),
          list_to_set([a, b, a, c, b], _), list_to_set([X, Y, X, Y], _),
          list_to_set([1, 1.0, 1], _), clumped([a, a, b, a], _),
          is_set([a, b]), is_set([a, a]), is_set([_, _]), is_set([a|_]),
          proper_length([a, b], _), proper_length([a|_], _),
          permutation([1, 2, 3], _), permutation([1|_], [2, 1]),
          append([[1], [2, 3], []], _), append([[1], _], [1, 2]) ]).

%% each goal's error
errors([ nth0(a, [a], _, _), nth0(-1, [a], _, _), nth1(0, [a], _, _),
         nth1(a, [a], _, _), nth0(_, a, _, _), append(_, [1]), append([[1]|a], _),
         permutation(a, _), permutation(_, a), permutation([a|b], _),
         list_to_set(_, _), list_to_set([a|b], _),
         max_member(nosuch, _, [1, 2]), min_member(nosuch, _, [1, 2]),
         phrase(sequence(nosuch, _), [a], _) ]).

main :-
    warm,
    runs(Rs),
    forall(member(R, Rs), try(R)),
    answers(As),
    forall(member(G, As), ( findall(G, G, L), shown(G-L) )),
    errors(Es),
    forall(member(G, Es), catch(( G -> shown(yes(G)) ; shown(no(G)) ), E, shown(caught(E)))).

try(G) :-
    catch(( G -> shown(yes(G)) ; shown(no(G)) ), E, shown(caught(E))).

shown(T) :-
    copy_term(T, C), term_variables(C, Vs), maplist(=('_'), Vs),
    print(C), nl.
