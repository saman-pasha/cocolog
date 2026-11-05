%  The compiler's load-time warnings, after the reader's singleton list:
%  a singleton-marked variable named twice, a variable a branch or a \+
%  meets first at its last occurrence, one a \+ names once though the
%  clause names it after, and a test of two variables, one of them met
%  first. Run by BOTH SWI-Prolog and cocolog, output compared byte for
%  byte; each clause is one of swipl 9.0.4's answers, probed one by one.

%% a variable marked singleton, named twice: `_X' and `__x' are marked,
%% `_x' is not, and the two blocks stand apart
m1(_X, _X).
m2(_x, _x).
m3(__x, __x).
m4(_X, _X, _Y, _Y, Z).
m5(__, __).

%% a branch: the variable first met at its last occurrence in it
b1(X) :- ( X = 1, Y = 2 ; Z = 3 ).
b2(X) :- ( X = 1 -> Y = 2 ; true ).
b3(X) :- ( X = 1, Y = 2 ; Y = 3 ).
b4(X) :- ( a, Y = 1 ; b ), Y == 2.
b5(X) :- ( X = 1 -> ( Y = 1 ; Z = 2 ) ; true ).
b6(X, Y) :- ( Y = 1 ; true ), Z = 1.
b7(X) :- ( X -> Y = 1 ).
b8(X) :- ( X *-> Y = 1 ; true ).
b9(X) :- ( X | Y = 1 ).
c0(Z) :- ( Y = 1 ; true ), ( Y = 2 ; true ), Z = 1.
c1(A) :- ( B = 1, B = 2 ; true ), A = 1.
c2(A) :- ( true ; B = 1 ), ( B = 2 ; true ), A = 1.
c3(X) :- ( Y = 1, Y = 2 ; Y = 3 ), X = 1.
c4(Z) :- ( ( Y = 1 ; true ) ; Y = 2 ), Z = 1.
c5(Z) :- ( Y = 1 -> true ; true ), Z = 1.
c6(Z) :- ( Y = 1 -> Y = 2 ; true ), Z = 1.
c7(Z) :- ( true -> true ; Y = 1 ), Y = 2, Z = 1.
c8(Z) :- ( Y = 1 ; true ; Y = 2 ), Z = 1.
c9(Z) :- ( Y = 1 ; W = 1 ; V = 2 ), Z = 1.
d1(Z) :- ( W = 1 ; true ), ( Y = 1 ; true ), Z = 1.
d2(Z) :- ( Y = 1, ( Y = 2 ; true ) ; true ), Z = 1.
d3(Z) :- Z = 1 ; Y = 1.
d4(Z) :- m:( Y = 1 ; true ), Z = 1.
d5(Z) :- ( ( Y = 1 ; true ), Y = 2 ; true ), Z = 1.
d6(Z) :- ( ( Y = 1 ; true ) ; true ), Y = 2, Z = 1.
d7(Z) :- ( ( Y = 1 ; true ) -> Y = 2 ; true ), Z = 1.
d8(Z) :- ( true -> ( Y = 1 ; true ) ; Y = 2 ), Z = 1.
d9(Z) :- ( Y = 1 ; true ), Y, Z = 1.
e1(_X, _X) :- ( Y = 1 ; true ), W = 1.
e2(_B) :- ( _C = 1 ; true ).
e3(Z) :- ( _Y = 1, _Y = 2 ; true ), Z = 1.

%% a meta-call's goal is only its occurrences
f1(L) :- findall(X, ( Y = 1 ; true ), L).
f2(Z) :- once(( Y = 1 ; true )), Z = 1.
f3(Z) :- call(( Y = 1 ; true )), Z = 1.
f4(Z) :- not(( Y = 1 ; true )), Z = 1.
f5(Z) :- ( findall(Y, true, _) ; true ), Z = 1.
f6(Z) :- ( Y = 1 ; true ), findall(Y, true, _), Z = 1.

%% a \+: met first and named once in it, whatever comes after
g1(X) :- \+ ( Y = X ).
g2(X) :- \+ \+ ( Y = X ).
g3(Z) :- \+ ( Y = 1 ), \+ ( Y = 2 ), Z = 1.
g4(Z) :- ( \+ Y = 1 ; true ), Z = 1.
g5(Z) :- \+ Y = 1, Y = 2, Z = 1.
g6(Z) :- \+ ( ( Y = 1 ; true ) ), Y = 2, Z = 1.
g7(Z) :- \+ ( ( Y = 1 ; true ) ), Z = 1.
g8(Z) :- \+ ( Y = 1, Y = 2 ), ( Y = 3 ; true ), Z = 1.
g9(Z) :- ( Y = 1 ; true ), \+ Y = 2, Z = 1.
h1(Z) :- ( \+ Y = 1, Y = 2 ; true ), Z = 1.
h2(Z) :- ( Y = 1 ; true ), \+ W = 1, Z = 1.
h3 :- \+ Y = 1.
h4(Z) :- \+ ( _Y = 1 ), _Y = 2, Z = 1.
h5(Z) :- ( \+ Y = 1 ; \+ Y = 2 ), Z = 1.

%% a test of two variables, one of them met first
t1(X) :- X == X.
t2(X) :- X == Y.
t3(X) :- Y == X.
t4(X) :- X \== Y.
t5(X) :- X == Y, Y = 1.
t6 :- X == Y.
t7(X) :- X == f(Y).
t8(X) :- ( X == Y ; true ).
t9(X) :- \+ X == Y.
u1(X) :- p(Y), X == Y.
u2(X) :- X == _Y.
u3(X) :- X == Y, Y == X.
u4(X, Y) :- X == Y.
u5(Z) :- findall(_, Z == Y, _).
u6(X) :- ( Y = 1 ; X == Y ).
u7 :- X == X.
u8 :- X \== X.
u9 :- X == X, ( X = 1 ; true ).
x1 :- X == Y, ( Y = 1 ; true ), X = 2.
x2(A) :- X == X, A == X.

%% a grammar rule, a single-sided rule and its guard
v1 --> [a], ( {X = 1} ; [] ).
v2 --> \+ [X], [a].
v3 --> { Y = 1 ; true }, [a].
v4 --> call(foo, X), ( [X] ; [] ).
v5 --> {X == Y}, [X].
v6 --> ( [a], {Y = 1} | [b] ).
v7 --> [X], ( [X] | [] ).
v8 --> X == Y, [X].
w1(X), X > 0 => ( Y = 1 ; true ).
w2(X), ( Y = 1 ; true ) => X = 1.

%% a directive has the reader's block alone
:- X = 1, ( Y = 2 ; true ).
:- ( Y = 1 ; true ), Y = 2.
:- _X = 1, _X == 1.

%% the compiler's block comes after the not-together warning, of a clause
%% stored: none for a clause refused, nor for one an expansion replaced
p(a).
q(a).
p(Z) :- ( Y = 1 ; true ), Z = 1.
3 :- ( Y = 1 ; true ).
term_expansion((ty :- _), (ty :- true)).
ty :- ( Y = 1 ; true ).

main :- writeln(loaded).
