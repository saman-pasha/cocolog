% A family tree, and the transitive closure over it.
%
% Small enough to read and big enough that `ancestor/2' has real choice points
% at more than one depth -- which is what makes a machine suspended in the
% middle of it interesting rather than trivial.

parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).
parent(pat, jim).
parent(jim, zoe).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

% Something with enough work in it to need several turns of the scheduler.
count(0) :- !.
count(N) :- N > 0, M is N - 1, count(M).

nat(0).
nat(N) :- nat(M), N is M + 1.
