%  library(aggregate), the vendored copy, against SWI's own.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  aggregate_all/3 is NATIVE in cocolog (lib/builtins.cicili) and vendored
%  under SWI -- comparing them is the point: the native one has to answer
%  what the library answers. aggregate/3,4 and aggregate_all/4 run the
%  vendored clauses on both systems.
%
%  Since 3.75.0 the native one declines what swipl's specific clauses do
%  not answer to the library's general clause, as swipl's own does: a
%  count(T) is a term of templates there -- an unbound T is sum(_), and
%  the answer count(Sum) -- and a bag(T) or a set(T) over a goal T^G has
%  the `^' taken off before its findall/3 (`counts' and `hats' below).
%  Through 3.74.0 cocolog counted count(T)'s solutions, and ran T^G as a
%  goal, an unknown procedure (^)/2.

:- use_module(library(aggregate)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form

p(X) :- writeq(X), nl.

%% a term with its variables named, and how a goal ended: its answer, a
%% failure, or its ball by its formal and its context
pv(T) :- \+ \+ ( numbervars(T, 0, _), print(T) ).
t(L, G) :-
    catch(( G -> R = yes(G) ; R = no ), E, R = caught(E)),
    ( R = caught(error(F, C)) -> pv(L-caught(F, C)) ; pv(L-R) ),
    nl.

item(a, 1). item(b, 2). item(c, 3). item(b, 4).
q(1). q(2). q(1).

main :-
    aggregate_all(count, item(_, _), N), p(N),
    aggregate_all(sum(V1), item(_, V1), S), p(S),
    aggregate_all(max(V2), item(_, V2), Mx), p(Mx),
    aggregate_all(min(V3), item(_, V3), Mn), p(Mn),
    aggregate_all(max(V4, K4), item(K4, V4), MW), p(MW),
    aggregate_all(min(V5, K5), item(K5, V5), NW), p(NW),
    aggregate_all(bag(K6-V6), item(K6, V6), B), p(B),
    aggregate_all(set(K7), item(K7, _), St), p(St),
    ( aggregate_all(max(V8), fail, V8) -> p(bad) ; p(empty_max-failed) ),
    aggregate_all(sum(_), fail, Z), p(Z),
    aggregate_all(count(K8), K8, item(K8, _), C4), p(C4),
    aggregate_all(sum(V9), K9, item(K9, V9), S4), p(S4),
    aggregate(count, item(_, _), AC), p(AC),
    aggregate(sum(V10), K10, item(K10, V10), AS), p(AS),
    aggregate(bag(V11), K11^item(K11, V11), AB), p(AB),
    aggregate(max(V12), K12^item(K12, V12), AM), p(AM),
    counts,
    hats.

%% count(T) through the general clause: a term named count of templates
counts :-
    t(c1, aggregate_all(count(X1), member(X1, [a, b, a]), _)),
    t(c2, aggregate_all(count(_), fail, _)),
    t(c3, aggregate_all(count(1), member(_, [a, b]), _)),
    t(c4, aggregate_all(count(X4), X4^member(X4, [a, b]), _)),
    t(c5, aggregate_all(count, X5^member(X5, [a, b]), _)),
    t(c6, aggregate_all(count(a, b), true, _)),
    t(c7, aggregate_all(count(_), 3, _)),
    t(c8, aggregate_all(count(_), _, _)),
    t(c9, aggregate_all(count(X9), member(X9, [1, 2]), a)),
    t(c10, aggregate_all(count(X10), member(X10, [1, 2]), 2)),
    t(c11, aggregate_all(count(X11), q(X11), count(0))),
    t(c12, aggregate_all(count(X12), q(X12), count(_))),
    t(c13, aggregate_all(r(count(X13), sum(X13)), q(X13), _)),
    t(c14, aggregate_all(count(X14), user:member(X14, [a]), _)),
    t(c15, aggregate_all(count(X15), _:member(X15, [a]), _)),
    t(c16, aggregate_all(count(X16), call(member(X16), [a]), _)),
    t(c17, aggregate_all(count(X17), undefined_pred(X17), _)),
    t(c18, aggregate_all(count(X18), (member(X18, [1, 2]), X18 > 1), _)),
    t(c19, aggregate_all(count(X19), lists:member(X19, [a, b]), _)),
    t(c20, aggregate_all(count(X20), (X20 = 1 ; X20 = 2), _)),
    t(c21, aggregate_all(count(X21), \+ member(X21, [a]), _)),
    t(c22, aggregate_all(count(X22), Y22^member(X22-Y22, [1-a, 2-b]), _)),
    t(c23, aggregate_all(count(f(X23)), member(X23, [1, 2]), _)),
    t(c24, aggregate_all(count([]), member(_, [1, 2]), _)),
    t(c25, aggregate_all(count(1.5), member(_, [1, 2]), _)),
    t(c26, aggregate_all(count(_), q(_), _)),
    t(c27, aggregate_all(count(q), q(_), _)),
    t(c28, aggregate_all(count(count), q(_), _)),
    t(c29, aggregate_all(count(sum(X29)), q(X29), _)),
    t(c30, aggregate_all(count(max(X30)), q(X30), _)),
    t(c31, aggregate_all(count(bag(X31)), q(X31), _)),
    t(c32, aggregate_all(count(X32, Y32), q(X32), Y32)).

%% a goal T^G: the general clause takes the `^' off, a bag's and a set's;
%% the specific clauses call it as it stands
hats :-
    t(h1, aggregate_all(bag(X1), X1^member(X1, [1, 2]), _)),
    t(h2, aggregate_all(set(X2), Y2^member(X2-Y2, [1-a, 1-b]), _)),
    t(h3, aggregate_all(bag(X3), user:(X3^member(X3, [1, 2])), _)),
    t(h4, aggregate_all(set(X4), lists:(Y4^member(X4-Y4, [b-1, a-2, b-3])), _)),
    t(h5, aggregate_all(bag(X5), X5^user:member(X5, [1, 2]), _)),
    t(h6, aggregate_all(bag(X6), X6^_, _)),
    t(h7, aggregate_all(bag(X7), _^X7, _)),
    t(h8, aggregate_all(bag(X8), X8^q(X8), [1, 2, 1])),
    t(h9, aggregate_all(bag(X9), X9^q(X9), [1, 2])),
    t(h10, aggregate_all(set(X10), X10^q(X10), [1, 2])),
    t(h11, aggregate_all(bag(X11-Y11), Y11^q(X11), _)),
    t(h12, aggregate_all(set(X12), X12^Y12^Z12^member(X12-Y12-Z12, [c-1-x, a-2-y]), _)),
    t(h13, aggregate_all(bag(X13), X13^3, _)),
    t(h14, aggregate_all(bag(X14), X14^undefined_q(X14), _)),
    t(h15, aggregate_all(bag(_), 1^q(_), _)),
    t(h16, aggregate_all(bag(X16), X16^(q(X16), X16 > 1), _)),
    t(h17, aggregate_all(set(X17), _:(X17^q(X17)), _)),
    t(h18, aggregate_all(sum(X18), X18^member(X18, [1, 2]), _)),
    t(h19, aggregate_all(sum(X19), user:(X19^q(X19)), _)),
    t(h20, aggregate_all(max(X20), X20^member(X20, [1, 2]), _)),
    t(h21, aggregate_all(max(X21, W21), W21^q(X21), _)),
    t(h22, aggregate_all(count, user:(X22^q(X22)), _)),
    t(h23, aggregate_all(min(X23, W23), member(X23-W23, [2-a, 1-b]), _)).
