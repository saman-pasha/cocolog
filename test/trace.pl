%% trace.pl -- the program the four-port tracer is held to SWI over.
%% Plain Prolog, no libraries: SWI would qualify a library predicate with
%% its module (lists:member) and cocolog has no modules to agree with.

parent(tom, bob).   parent(tom, liz).
parent(bob, ann).

anc(X, Y) :- parent(X, Y).
anc(X, Y) :- parent(X, Z), anc(Z, Y).

sum([], 0).
sum([H|T], S) :- sum(T, S0), S is S0 + H.

pick(X) :- ( X = a ; X = b ).

memb(X, [X|_]).
memb(X, [_|T]) :- memb(X, T).

fst(X, L) :- memb(X, L), !.

classify(N, negative) :- N < 0, !.
classify(0, zero) :- !.
classify(_, positive).

either(X) :- ( X > 3 -> big(X) ; small(X) ).
big(_).
small(_).

np(X) :- \+ q0(X), r0(X).
q0(1).
r0(_).
