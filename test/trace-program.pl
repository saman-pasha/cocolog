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

%% switches the tracer on from inside its own body, so its disjunction is
%% reached from an environment written untraced (trace.pl's `env_late')
lt(X) :- trace, ( pick(X) ; X = c ).

%% a type test, a builtin and a comparison inside a construct, which an
%% untraced call runs in place from its environment (Stage 7): traced,
%% each is a goal with its ports again
len3(X) :- ( atom(X) -> atom_length(X, N), N > 2 ; fail ).

%% the same kinds and `=/2', reached from an environment written untraced
%% and taken traced (trace.pl's `env_late')
lb(X, N) :- trace, ( X = abc -> atom_length(X, N) ; N = 0 ), N > 2.

%% A CALL WHOSE CLAUSE CUTS AND THEN FAILS (1.10.24): its Fail comes from
%% the frame its cut kept. Through 1.10.22 the cut took the frame and the
%% call ended with no Fail -- and with no end at all in a window, the
%% `fate="open"' of library(flow/debug). Cut and then fail; cut on a
%% guard; cut, then a call redone inside the body; cut, then a disjunction
%% redone; one such call inside another.
cutfail :- !, fail.
cpos(X) :- X > 0, !, fail.
cpos(_).
cmem(X) :- !, memb(X, [1,2]).
cor(X) :- !, ( X = a ; X = b ), X == b.
cin(X) :- cpos(X).

%% A REDO OPENS THE CALLS IT IS INSIDE, and only those: `det0' and `cut0'
%% exited before `memb/2' was called, and SWI fails neither when the
%% failure crosses them. Through 1.10.22 every shallower frame below a
%% redo was opened again, and `det0' was failed.
det0.
cut0 :- !.
sib :- det0, memb(X, [1,2]), X > 5.
csib :- cut0, memb(X, [1,2]), X > 5.
