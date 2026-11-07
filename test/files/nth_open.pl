%  nth0/3 and nth1/3 with the index given, over a list that is unbound or
%  partial, as swipl 9.0.4's '$seek_list'/4 and nth0_det/3 answer: the
%  walk's unbound tail is bound to the cells it had still to pass, fresh,
%  and the element's, then a fresh tail -- `nth0(1, L, a)' is L = [_, a|_]
%  -- once. A list that ends before the index fails, and so does an index
%  below the base. length/2 of a count no stack could hold raises
%  resource_error(stack) at once. Through 3.42.2 each nth call on such a
%  list failed, and the length call built for minutes. Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte; each line is one
%  of swipl 9.0.4's answers.
%
%  NOT COMPARED, in test/engine.pl: nth0/3 and numlist/3 past the limit,
%  which swipl builds a step at a time, for ever where its collector takes
%  the cells nobody holds, and cocolog refuses at once.

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

%  the formal of what the goal raised, or `yes', or `no'
formal(G) :-
    copy_term(G, G0),
    (   catch(G, error(F, _), true)
    ->  ( var(F) -> R = yes ; R = F )
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

main :- unbound, partial, ends, shared, nth1s, errors, dets, lengths.

unbound :-
    t(nth0(0, _, _)),
    t(nth0(1, _, a)),
    t(nth0(4, _, x)),
    t(nth0(0, _, f(_))).

partial :-
    t(nth0(0, [a|_], _)),
    t(nth0(1, [a|_], b)),
    t(nth0(3, [a|_], _)),
    t(nth0(2, [a, b|_], c)),
    t(nth0(7, [a|_], x)),
    t(nth0(1, [a, _|_], c)),
    t(nth0(1, [a, b|_], c)),
    t(nth0(0, [a, b|_], a)).

ends :-
    t(nth0(2, [a|foo], _)),
    t(nth0(1, [a|foo], _)),
    t(nth0(0, foo, _)),
    t(nth0(1, [a], _)),
    t(nth0(0, [], _)),
    t(nth0(-1, _, _)),
    t(nth0(1, [a, b], c)),
    t(nth0(9223372036854775807, [a, b], _)),
    t(nth0(1000000000000, [a|foo], _)),
    t(nth1(1000000000000, [], _)).

shared :-
    t(( nth0(1, L1, X1), X1 = z, L1 = [y|_] )),
    t(( L2 = [a|T2], nth0(2, L2, c), T2 = [b|_] )),
    t(( nth0(1, _, f(Y3)), Y3 = 1 )),
    t(( nth0(1, L4, E4), nth0(1, L4, F4), E4 == F4 )),
    t(( nth0(2, L5, e), nth0(0, L5, a) )).

nth1s :-
    t(nth1(1, _, a)),
    t(nth1(3, [a, b|_], c)),
    t(nth1(0, _, _)),
    t(nth1(2, [a|foo], _)),
    t(nth1(-1, _, _)),
    t(nth1(4, [a|_], _)),
    t(nth1(1, [a|_], b)),
    t(nth1(9223372036854775807, [a], _)).

errors :-
    t(nth0(a, _, _)),
    t(nth0(1.0, _, _)),
    t(nth1(a, [a|_], _)),
    t(nth1(f(_), _, _)).

dets :-
    det(nth0(1, _, _)),
    det(nth0(3, [a|_], _)),
    det(nth1(2, [a, b|_], _)),
    det(nth1(1, _, _)),
    det(nth0(0, [a, b], _)).

lengths :-
    formal(length(_, 1000000000000)),
    formal(length([a|_], 1000000000000)),
    t(length(_, 3)),
    t(length([a|_], 2)).
