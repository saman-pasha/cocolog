%  The tests whose answer swipl's compiler knows, as it warns of them at a
%  load: a type test (var, nonvar, integer, rational, float, number,
%  atomic, atom, string, compound, callable) of a variable no goal set --
%  void, or met first -- or of a bound term; and ==/2 and \==/2 with a void
%  operand, or of two variables one of them unset. Each is a `Test is
%  always true' or `... false' line of the compiler's block, said only where
%  the test names a variable. Run by BOTH SWI-Prolog and cocolog, output
%  compared byte for byte; each clause is one of swipl 9.0.4's answers.
%  Not here: a test that names a variable and an anonymous one, whose `_'
%  swipl writes by a number of its own (`X==_552') where cocolog writes its
%  cell.

%% a type test of a variable no goal set: always var, never the others
a1 :- var(X).
a2 :- var(X), X = 1.
a3(X) :- var(X).
a4 :- X = 1, var(X).
a5 :- nonvar(X), X = 1.
a6 :- atom(X), X = a.
a7 :- integer(X), X = 1.
a8 :- float(X), X = 1.
a9 :- number(X), X = 1.
b1 :- atomic(X), X = 1.
b2 :- string(X), X = 1.
b3 :- compound(X), X = 1.
b4 :- callable(X), X = 1.
b5 :- rational(X), X = 1.
b6 :- is_list(X), X = 1.
b7 :- ground(X), X = 1.
b8 :- var(_).

%% a test is a call: it sets what it names
c1 :- var(X), var(X).
c2 :- var(X), var(Y), X = Y.
c3 :- nonvar(X), var(X), X = 1.
c4 :- X = f(Y), var(Y), X = 1.
c5 :- X = Y, var(X), var(Y).
c6(X) :- var(X), var(Y), Y = X.
c7 :- var(X), ( X = 1 ; X = 2 ).

%% of a bound term, its answer: said only where it names a variable
d0 :- atom(f(1)), callable(g(a)).
d1 :- atom(a).
d2 :- atom(f(X)), X = 1.
d3 :- callable(f(X)), X = 1.
d4 :- var(f(X)), X = 1.
d5 :- nonvar(f(X)), X = 1.
d6 :- integer(f(X)), X = 1.
d7 :- atom(f(X, Y)), X = Y.
d8 :- atomic(f(X)), compound(f(X)), string(f(X)), X = 1.
d9 :- callable(f(X)), callable(X), X = 1.
e1 :- callable(a), callable(1), atom([]), atomic([]), var(1.5).
e2 :- number(1r3), rational(1r3), rational(1), integer(1.0), float(1.0).
e3 :- ( X = 1 ; true ), atom(f(X)).
e4 :- atom(f(_X)), _X = 1.
e5(X) :- atom(f(1)), var(1.5), X = 1.
e6(X) :- atom(f(_)), X = 1.
e7(X) :- callable(a), atom(f(X)).

%% in the control constructs, and under a module
f1 :- ( var(X) ; true ), X = 1.
f2 :- ( var(X) -> true ; true ), X = 1.
f3 :- ( true ; var(X) ), X = 1.
f4 :- ( X = 1 ; var(X) ).
f5 :- \+ var(X), X = 1.
f6 :- \+ \+ var(X), X = 1.
f7 :- ( atom(X), X = a ; true ).
f8 :- ( var(X) ; var(X) ).
f9 :- ( X = 1 | var(X) ).
g1 :- ( var(X), X = 1 ; X = 2 ), var(X).
g2 :- ( a -> var(X) ; true ), X = 1.
g3 :- ( X = 1 ; Y = 2 ), var(X), var(Y).
g4 :- foo:var(X), X = 1.
g5 :- user:var(X), X = 1.
g6(M) :- M:var(X), X = 1.
g7(X) :- atom(Y), X = Y.

%% a branch starts from what was set before its disjunction, and a \+
%% keeps what it set
g8 :- ( X = 1 ; var(X) ), X = 2.
g9 :- \+ X = 1, var(X), X = 2.

%% `$/1' and `@/2' compile their goal in place; in a grammar rule they are
%% non-terminals
m1 :- $(var(X)), X = 1.
m2 :- @(var(X), m), X = 1.
m3 :- @(X == Y, m), Y = 1.
m4 :- $(( X = 1 ; var(X) )), X = 2.
m5 :- $((var(X), var(Y))), X = Y.
m6 --> $(var(X)), [X].
m7 --> @(var(X), m), [X].
m8 --> { $(var(X)) }, [X].
m9 --> $({ X == Y }), { var(Y) }, [X].

%% a qualified clause is the clause; a qualified grammar rule is no rule
foo:(o4 :- var(X), X = 1).
foo:(o5 --> { var(X) }, [X]).

%% a meta-call's goal is not compiled
h1 :- findall(Y, var(Y), _).

%% ==/2 and \==/2: a void operand, or two variables one of them unset
i1 :- X == a, X = 1.
i2 :- X == f(Y), X = Y.
i3 :- X == Y, var(Y), Y = 1.
i4 :- f(Y) == X, X = Y.
i5 :- X == 1.5, X = 1.
i6 :- X \== a, X = 1.
i7 :- X \== f(Y), X = Y.
i8(Y) :- X == Y.
i9(Y) :- f(X) == Y.
j1 :- X == X, X = 1.
j2 :- X == Y, var(X), Y = 1.
j3 :- X == a, var(X), X = 1.

%% a single-sided rule's guard, and a grammar rule's goals
k1(X), var(Y) => X = Y.
k2(X), atom(X) => true.
k3 --> { var(X) }, [X].
k4 --> [X], { atom(X) }, ( [Y] | { var(Y) } ).
k5 --> { X == Y }, [X, Y].
k6 --> var(X), [X].
k7 --> var(X), { atom(Y) }, [X, Y].
k8 --> X == Y, { atom(Z) }, [X, Y, Z].

%% a directive is no clause
:- var(X), X = 1.

main :- writeln(loaded).
