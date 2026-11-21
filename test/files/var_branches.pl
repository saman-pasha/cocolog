%  style_check(+var_branches) (cocolog 3.67.0), as swipl 9.0.4's count of a
%  clause's variables says it: a variable a disjunction introduces in one
%  of its branches and not in another -- the left of `;', an if-then-else's
%  condition and then, a `*->' -- named again after the disjunction, where
%  `Variable not introduced in all branches: X' is said, once, in the
%  compiler's block, ahead of its other lines and in the order the names
%  are met; a `\+' introduces nothing, and what a disjunction in one of
%  its branches left so is no warning in another. Run by BOTH SWI-Prolog
%  and cocolog, output compared byte for byte; each clause is one of
%  swipl 9.0.4's answers, probed one by one. The reader's singletons and
%  the compiler's other lines stay on, so their order beside the new line
%  is held too.

:- style_check(+var_branches).

%% one branch introduces it, and the clause names it after
a1 :- ( true ; Z = 1 ), print(Z).
a2 :- ( Z = 2 ; true ), ( W = Z ; true ), print(W).
a3 :- ( a -> Z = 1 ; true ), print(Z).
a4 :- ( Z = 1 ; true ), Z == 1.
a5 :- ( true ; Z = 1 ; W = 2 ), print(Z-W).
a6 :- ( true *-> Z = 1 ; true ), print(Z).
a7 :- ( Z = 1 ; true ), ( Z = 2 ; true ).
a8 :- ( Z = 1 ; true ), print(Z), print(Z).
a9 :- ( Z = 1 ; Z = 2 ; true ), print(Z).
b1 :- ( true ; ( Z = 1 ; true ) ), print(Z).
b2 :- ( a, Z = 1 ; b ), print(Z).
b3 :- ( Z = 1 ; true ), ( Q = 2 ; true ), print(Z-Q).
b4 :- ( print(Z) ; true ), print(Z).
b5 :- ( call(Z) ; true ), print(Z).
b6 :- ( Z == 1 ; true ), print(Z).
b7 :- ( var(Z) ; true ), print(Z).
b8 :- ( Z = f(Q) ; true ), print(Z-Q).
b9 :- ( true ; Z = 1 ), ( true ; Z = 2 ), print(Z).

%% none: both branches introduce it, a head names it, no branch does, it
%% is named nowhere after, or the disjunction is an argument, not code
c1 :- ( Z = 2 ; Z = 1 ), print(Z).
c2(Z) :- ( true ; Z = 1 ).
c3 :- ( true ; Z = 1, print(Z) ).
c4 :- ( Z = 1, print(Z) ; true ).
c5 :- ( a -> Z = 1 ), print(Z).
c6 :- findall(Z, ( Z = 1 ; true ), _).
c7 :- ( Z = 1 ; Z = 2 ), print(Z).
c8 :- catch(( Z = 1 ; true ), _, true), print(Z).
c9 :- G = ( Z = 1 ; true ), call(G), print(Z).
d1 :- once(( Z = 1 ; true )), print(Z).
d2 :- ignore(( Z = 1 ; true )), print(Z).
d3 :- ( a ; b ), print(Z).
d4 :- ( Z = 1 ; true ), print(_).
d5 :- ( Z = 1 -> true ; Z = 2 ), print(Z).
d6 :- ( Z = 1 *-> true ), print(Z).
d7 :- not(Z = 1), print(Z).
d8 :- ( Z = 1 | true ), print(Z).

%% named after, wherever: a later disjunction, a \+, a test, a qualified
%% goal, a meta-call's argument
e1 :- ( true ; Z = 1 ), ( print(Z) ; true ).
e2 :- ( Z = 1 ; true ), \+ print(Z).
e3 :- ( ( Z = 1 ; true ), print(Z) ; true ).
e4 :- ( ( Z = 1 ; true ) ; true ), print(Z).
e5 :- ( Z = 1 ; ( true ; true ) ), print(Z).
e6 :- ( true ; ( Z = 1 ; Z = 2 ) ), print(Z).
e7(X) :- ( X = 1 -> Z = 1 ; X = 2 -> Z = 2 ; true ), print(Z).
e8 :- ( true ; Z = 1 ), Z = 2.
e9 :- ( Z = 1 ; fail ), print(Z).
f1 :- ( Z = 1 ; ! ), print(Z).
f2 :- ( Z = 1 ; throw(x) ), print(Z).
f3 :- ( Z = 1 ; Y = 2 ), print(Z-Y).
f4 :- ( Y = 2 ; Z = 1 ), print(Z-Y).
f5 :- ( Y = 2 ; Z = 1 ), print(Y), print(Z).
f6 :- ( Z = 1 ; true ), _ = Z.
f7 :- ( Z = 1 ; true ), call(print, Z).
f8 :- ( Z = 1 ; true ), ( Z = 2 ; W = 3 ), print(W).
f9 :- ( Z = 1 , ! ; true ), print(Z).
g1 :- ( Z = 1 ; true ), ( print(Z) ; print(Z) ).
g2 :- ( Z = 1 ; true ), \+ \+ print(Z), print(Z).
g3 :- ( true ; Z = 1 ), X = Z, print(X).
g4 :- ( true ; Z = 1 ), Z = _.
g5(A) :- ( A = 1, Z = 1 ; A = 2 ), Z = A.
g6 :- ( Z = 1 ; true ), $, print(Z).
g7 :- ( Z = 1 ; true ), user:print(Z).
g8 :- ( user:(Z = 1) ; true ), print(Z).
g9 :- ( Z = 1 ; true ), call((print(Z) ; true)).
h1 :- ( Z = 1 ; true ), findall(Z, true, _).
h2 :- ( Z = 1 ; true ), \+ Z = 2.
h3 :- ( Z = 1 ; true ), print(Z), ( W = 2 ; true ), print(W).
h4 :- ( Z = 1 ; true ), ( Q = 1 ; true ), print(Q), print(Z).
h5 :- ( true ; Z = 1 ; Q = 2 ), print(Q), print(Z).
h6(A) :- ( A == 1, Z = 1 ; true ), print(Z).
h7 :- ( Z = 1 ; Q = 1 ), ( P = 1 ; true ), print(Q-Z-P).
h8 :- ( Z = 1 ; true ), ( Z = 1 ; true ), ( Z = 1 ; true ).
h9 :- ( X = 1, Y = 2 ; true ), print(Y), print(X).
i1 :- ( X = Y ; true ), print(Y-X).

%% the order of the compiler's lines: this one first, a test's after it,
%% and the count's own after it
i2 :- ( Z = 1 ; true ), X == Y, print(Z), print(X-Y).
i3 :- X == Y, ( Z = 1 ; true ), print(Z), print(X-Y).
i4 :- ( Z = 1 ; true ), ( W = 2 ; true ), X == Y, print(W), print(Z), print(X-Y).
i5 :- ( _Z = 1 ; true ), print(_Z).
i6 :- ( Z = [Q|_] ; true ), print(Q).
i7 :- ( Z = 1 ; true ), _A = 1, _A = 2, print(Z).

%% any name the clause gives it, marked singleton or not
i8 :- ( _1 = 1 ; true ), print(_1).
i9 :- ( _x = 1 ; true ), print(_x).

%% a \+ introduces nothing, and its own disjunction's is said after it
j1 :- \+ ( Z = 1 ; true ), print(Z).
j2 :- ( \+ Z = 1 ; true ), print(Z).
j3 :- \+ Z = 1, print(Z).
j4 :- ( Z = 1 ; \+ Z = 2 ), print(Z).
j5 :- ( \+ Z = 1 ; Z = 2 ), print(Z).
j6 :- ( Z = 1 ; \+ \+ Z = 2 ), print(Z).
j7 :- ( \+ Z = 1, Z = 2 ; true ), print(Z).
j8 :- ( true ; \+ Z = 1, Z = 2 ), print(Z).
j9 :- ( Z = 1 ; ( \+ Z = 2 ; true ) ), print(Z).
k1 :- ( Z = 1 ; \+ ( Z = 2 ; true ) ), print(Z).

%% a disjunction inside a branch: what it leaves is the branch's, and no
%% warning in the other branch
k2 :- ( Z = 1 ; ( Z = 2 ; true ) ), print(Z).
k3 :- ( ( Z = 1 ; Z = 2 ), Z = 3 ; Z = 4 ), print(Z).
k4 :- ( ( Z = 1 ; Z = 2 ) ; true ), true.
k5 :- ( Z = 1 ; ( Z = 2 ; Z = 3 ) ), print(Z).
k6 :- ( Z = 1, ( Z = 2 ; true ) ; true ), print(Z).
k7 :- ( Z = 1 ; ( Z = 2 ; ( Z = 3 ; true ) ) ), print(Z).
k8(A) :- ( A = 1, Z = 1 ; ( A = 2, print(Z) ; true ) ), print(Z).
k9 :- ( Z = 1 ; ( Z = 2 -> true ; true ) ), print(Z).
l1 :- ( Z = 1 ; ( true -> Z = 2 ; true ) ), print(Z).
l2 :- ( ( Z = 1 ; true ) ; print(Z) ), true.
l3 :- ( ( Z = 1 ; true ) ; print(Z) ), print(Z).
l4 :- ( ( Z = 1 ; true ) ; true ), print(Z).
l5 :- ( ( Z = 1 ; true ) ; Z = 2 ), print(Z).
l6 :- ( ( Z = 1 ; true ), true ; print(Z), print(Z) ), print(Z).

%% a grammar rule's, by its translation
m1 --> ( [X] ; [] ), { print(X) }.
m2 --> ( [X] ; [] ), m3(X).
m3(_) --> [].
m4(X) --> ( { X = 1 }, [Y] ; [] ), [Y].

main :- writeln(loaded).
