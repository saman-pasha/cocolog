:- use_module(library(dcg/basics)).

%% conformance.pl -- a small program the engine and SWI-Prolog are both
%% asked about, so that `make swipl' can compare their answers.
%% Plain Prolog on purpose: no colours, nothing of the mode in it.

parent(tom, bob).   parent(tom, liz).
parent(bob, ann).   parent(bob, pat).
parent(pat, jim).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

first_parent(X, P) :- parent(P, X), !.

sum([], 0).
sum([H|T], S) :- sum(T, S0), S is S0 + H.

classify(N, negative) :- N < 0, !.
classify(0, zero) :- !.
classify(_, positive).

greet --> [hello], greeted.
greeted --> [world].
greeted --> [prolog].

ab --> [].
ab --> [a], ab, [b].

swap(A, B), [B], [A] --> [A], [B].

digit(D) --> [C], { C >= 0'0, C =< 0'9, D is C - 0'0 }.
digits([D|T]) --> digit(D), digits(T).
digits([D]) --> digit(D).

%% The tokenizer of examples/grammar.colog, so that the answers the
%% example shows are held to SWI's own dcg/basics rather than to ours.
tokens(Ts) -->
    blanks,
    more_tokens(Ts).

more_tokens([]) --> eos, !.
more_tokens(Ts) -->
    "%", string(_), ( eol ; eos ), !,
    blanks,
    more_tokens(Ts).
more_tokens([Token|Ts]) -->
    nonblanks(Cs),
    { Cs \= [], atom_codes(Token, Cs) },
    blanks,
    more_tokens(Ts).
