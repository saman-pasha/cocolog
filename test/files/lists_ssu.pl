%  sum_list/2, max_list/2, min_list/2, subtract/3, intersection/3, union/3
%  and subset/2 as swipl 9.0.4 writes them (library(lists), single-sided
%  rules): a list no rule matches -- no list, an unbound one, the end of a
%  partial one -- raises existence_error(matching_rule, lists:Name(...)) at
%  the tail the walk reached, with context(lists:Name/Arity, _), and the
%  accumulator in it is what the elements before that tail made of it;
%  an element before the tail is evaluated first, and its error is the
%  one raised. Each leaves no choice point on a proper list. Through
%  3.42.0 cocolog failed for any list but a proper one, before it read an
%  element, and the four set predicates enumerated an unbound list
%  (`subtract(L, [a], R)' gave L = []). Run by BOTH SWI-Prolog and cocolog,
%  output compared byte for byte; each line is one of swipl 9.0.4's
%  answers.
%
%  NOT COMPARED, in COMPAT.md: a list that is its own tail, which swipl's
%  rules walk for ever and cocolog's folds fail.

:- use_module(library(lists)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form

%  the goal, and what it did: its answer, `no', or the ball
t(G) :-
    copy_term(G, G0),
    (   catch(G, E, true)
    ->  ( var(E) -> R = yes(G) ; R = E )
    ;   R = no
    ),
    \+ \+ ( numbervars(G0-R, 0, _), print(G0), write(' => '), print(R) ),
    nl.

%  whether the call left a choice point
det(G) :-
    copy_term(G, G0),
    (   call_cleanup(G, Det = yes) -> true ; Det = failed ),
    ( var(Det) -> D = no ; D = Det ),
    \+ \+ ( numbervars(G0, 0, _), print(G0), write(' deterministic: '), print(D) ),
    nl.

main :- sums, extremes, sets, dets.

sums :-
    t(sum_list([1, 2, 3], _)),
    t(sum_list([1, 2.5], _)),
    t(sum_list([1+1, 2], _)),
    t(sum_list([1r2, 1r3], _)),
    t(sum_list([], _)),
    t(sum_list([1, 2], 3)),
    t(sum_list([1, 2], 4)),
    t(sum_list(foo, _)),
    t(sum_list(_, _)),
    t(sum_list([1, 2|foo], _)),
    t(sum_list([1, 2|_], _)),
    t(sum_list([1|foo], 5)),
    t(sum_list([1.5|foo], _)),
    t(sum_list([1+1|foo], _)),
    t(sum_list([a|foo], _)),
    t(sum_list([1, _|foo], _)),
    t(sum_list([1, 2|[]], _)),
    t(sumlist([1, 2], _)),
    t(sumlist(foo, _)).

extremes :-
    t(max_list([1, 3, 2], _)),
    t(max_list([1, 2.0], _)),
    t(max_list([2, 2.0], _)),
    t(max_list([a], _)),
    t(max_list([], _)),
    t(max_list(foo, _)),
    t(max_list(_, _)),
    t(max_list([1|foo], _)),
    t(max_list([1, 3|_], _)),
    t(max_list([a|foo], _)),
    t(max_list([1, a], _)),
    t(max_list([1, 1+2|foo], _)),
    t(min_list([3, 1, 2], _)),
    t(min_list([], _)),
    t(min_list(foo, _)),
    t(min_list(_, _)),
    t(min_list([3, 1|foo], _)),
    t(min_list([3, 1|_], _)),
    t(min_list([1, b], _)).

sets :-
    t(subtract([a, b, c], [b], _)),
    t(subtract([a, b], [a], [b])),
    t(subtract([a, b], [a], [c])),
    t(subtract([], foo, _)),
    t(subtract(foo, [a], _)),
    t(subtract(_, [a], _)),
    t(subtract([a, b|foo], [a], _)),
    t(subtract([a, b|_], [a], _)),
    t(subtract([a], foo, _)),
    t(intersection([a, b, c], [c, a], _)),
    t(intersection([a, b], [b], [b])),
    t(intersection([], foo, _)),
    t(intersection(foo, [a], _)),
    t(intersection(_, [a], _)),
    t(intersection([a, b|foo], [a], _)),
    t(intersection([a], foo, _)),
    t(union([a, b], [b, c], _)),
    t(union([], [x], _)),
    t(union(foo, [a], _)),
    t(union(_, [a], _)),
    t(union([a, b|foo], [a], _)),
    t(union([a, b|_], [a], _)),
    t(subset([a, b], [b, a, c])),
    t(subset([a, d], [b, a, c])),
    t(subset([], foo)),
    t(subset(foo, [a])),
    t(subset(_, [a])),
    t(subset([a|foo], [a])),
    t(subset([b|foo], [a])),
    t(subset([a|_], [a])).

dets :-
    det(sum_list([1, 2], _)),
    det(max_list([1, 2], _)),
    det(min_list([1, 2], _)),
    det(subtract([a, b], [a], _)),
    det(intersection([a, b], [a], _)),
    det(union([a, b], [a], _)),
    det(subset([a], [a, b])).
