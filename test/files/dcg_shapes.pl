%  The translator at its edges: every body shape it has a case for, in the
%  awkward positions. Run by BOTH SWI-Prolog and cocolog, compared byte for
%  byte.
%
%  These are the cases where a translation can be plausible and wrong -- an
%  empty body, a disjunction one of whose branches consumes nothing, a cut in
%  the middle, a nested body, a negation, both if-then-elses. Each is small
%  enough that a failure names the shape that broke.
:- set_prolog_flag(double_quotes, codes).

a1 --> [].
a2 --> {true}.
a3 --> {}.
a4 --> !.
a5 --> [a|T], {T = []}.

%  a disjunction does not thread: both branches run from the same input to the
%  same output, so a branch that consumes nothing must still bind the output
a6 --> ([a] ; []).
a7 --> ([] ; [a]).
a8 --> ({true} ; [a]).

%  negation consumes nothing whatever the goal inside it would have consumed
a9 --> (\+ [] , [x]).

b1 --> [a], [b], [c].
b2 --> ( [a] -> [b] ; [c] ).
b3 --> ( [a] *-> [b] ; [c] ).
b4(X) --> [X], !, [X].

nest --> ((([a])), [b]).
deep --> [a], (([b], [c]) ; [d]).

%  a recursive grammar, run in both directions
r(0) --> [].
r(N) --> [x], {N > 0, M is N - 1}, r(M).

main :-
    forall(member(G-L, [a1-[], a2-[], a3-[], a4-[], a5-[a], a6-[a], a6-[],
                        a7-[], a7-[a], a8-[], a8-[a], a9-[x],
                        b1-[a,b,c], b2-[a,b], b2-[c], b3-[a,b], b3-[c],
                        nest-[a,b], deep-[a,b,c], deep-[a,d]]),
           ( phrase(G, L) -> write(y) ; write(n) )),
    nl,
    ( phrase(b4(q), [q,q]) -> write(y) ; write(n) ), nl,
    findall(N, (between(0,3,N), phrase(r(N), Xs), length(Xs, N)), Ns), write(Ns), nl,
    ( phrase(r(3), Cs) -> write(Cs) ; write(no) ), nl,
    true.
