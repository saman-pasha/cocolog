%  library(aggregate), the vendored copy, against SWI's own.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  aggregate_all/3 is NATIVE in cocolog (lib/builtins.cicili) and vendored
%  under SWI -- comparing them is the point: the native one has to answer
%  what the library answers. aggregate/3,4 and aggregate_all/4 run the
%  vendored clauses on both systems.
%
%  NOT COMPARED: aggregate_all(count(Expr), ...). SWI 9.0.4 reads a
%  compound template through its nested-template rules and answers
%  count(0); cocolog's native builtin reads it as "count the solutions"
%  and answers their number, which is what SWI's own documentation says.
%  See lib/swipl/README.md.

:- use_module(library(aggregate)).

p(X) :- writeq(X), nl.

item(a, 1). item(b, 2). item(c, 3). item(b, 4).

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
    aggregate(max(V12), K12^item(K12, V12), AM), p(AM).
