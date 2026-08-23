%  library(yall), the vendored copy, against SWI's own.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  EVERY LAMBDA GETS ITS OWN VARIABLE NAMES. A parameter name reused by
%  two lambdas in one clause is SHARED between them as far as the clause
%  is concerned, and SWI's compile-time expansion of a lambda whose
%  parameters are shared changes its meaning -- upstream documents the
%  trap. Distinct names keep the case about the library, not the trap.

:- use_module(library(yall)).

p(X) :- writeq(X), nl.

main :-
    maplist([A1,B1]>>(B1 is A1*2), [1,2,3], D), p(D),
    maplist([A2]>>(A2 > 0), [1,2]), p(all_positive),
    N = 7, maplist({N}/[A3,B3]>>(B3 is A3+N), [1,2,3], A), p(A),
    call([A4,B4]>>(B4 is A4+1), 41, R1), p(R1),
    call([A5,B5,C5]>>(C5 is A5*B5), 6, 7, R2), p(R2),
    foldl([A6,B6,C6]>>(C6 is B6+A6), [1,2,3,4], 0, S), p(S),
    ( is_lambda([A7]>>foo(A7)) -> p(lambda-yes) ; p(lambda-no) ),
    ( is_lambda(foo(_)) -> p(plain-yes) ; p(plain-no) ),
    lambda_calls([A8,B8]>>plus(A8,B8), [1,2], G), p(G),
    include([A9]>>(A9 mod 2 =:= 0), [1,2,3,4,5,6], E), p(E),
    exclude([A10]>>(A10 > 3), [1,2,3,4,5], F), p(F),
    Prefix = pre,
    maplist({Prefix}/[In,Out]>>atom_concat(Prefix, In, Out), [a,b], C), p(C).
