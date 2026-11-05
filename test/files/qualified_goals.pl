%  What a load and an assert refuse of a clause a module qualifies, as
%  swipl's: the qualifiers on top of a clause, a head and a body taken
%  off, a goal under `M:G' walked as G, a module that is no atom named
%  itself, and a variable module over what will not do an instantiation
%  error; and a single-sided rule's guard, a cut and its body asked as one
%  body. Run by BOTH SWI-Prolog and cocolog, output compared byte for
%  byte; each clause is one of swipl 9.0.4's answers. Not here: a fresh
%  variable called (`p :- X.', swipl's compiler refuses it), a string
%  (`"s"' is codes to cocolog), a qualified rule's guard (swipl adds the
%  line of its own boot file) and a variable's name in a message.

%% a body: its qualifiers taken off, then walked
b1 :- foo:3.
b2 :- foo:bar:3.
b3 :- foo:(a, 3).
b4 :- foo:(a ; 3).
b5 :- foo:(a | 3).
b6 :- foo:[].
b7 :- foo:1.5.
b8 :- a, foo:3.
b9 :- \+ foo:3.
c1 :- ( foo:3 -> a ; b ).
c2 :- ( a -> foo:3 ; b ).
c3 :- foo:bar:a, baz:(c, 3).
c4 :- foo:(a :- b).
c5(X) :- foo:X.
c6(M) :- M:foo.
c7(M) :- M:(a, b).
c8 :- [].
c9 :- a, [].

%% a module that is no atom names itself, the walk's first fault winning
d1 :- 3:foo.
d2 :- f(1):a.
d3 :- a, 3:foo.
d4 :- \+ 3:foo.
d5 :- 3, 4:foo.
d6 :- 4:foo, 3.
d7 :- foo:(3:a).
d8 :- foo:(4:a, 3).
d9 :- (foo:a, bar:(3:b)).
e1 :- []:foo.

%% a variable module: over what will not do, on top, an instantiation
%% error (inside, the body's own fault: asserted below); a module's fault
%% wins either way
e2(M) :- M:3.
e3(M) :- M:(a, 3).
e4(M) :- M:N:3.
e5(M) :- foo:(M:3).
f1(M) :- M:(3:a).
f2(M) :- M:(a, 3:b).
f3(M) :- M:(a, M:3).

%% a head and a clause, their qualifiers taken off
foo:3.
foo:4 :- true.
3:foo.
f4:foo:3.
foo:bar:f5.
M:f6.
foo:(f7 :- 3).
foo:(3 :- a).
3:(f8 :- a).
foo:(f9 :- a).
foo:bar:(g1 :- 3).
foo:(g2 => 3).

%% a single-sided rule: its guard, a cut and its body are one body
g3, 3 => true.
g4 => 3.
g5 => foo:3.
g6, foo:3 => true.
g7, true => 3.

main :-
    forall(member(C, [ (p1 :- foo:3), (p2 :- 3:foo), (p3 :- foo:(a, 3)), (p4 :- foo:bar:3),
                       (p5 :- \+ foo:3), foo:7, (foo:8 :- true), 3:foo, (p7 :- f(1):a),
                       (p8 :- foo:[]), (p9 :- foo:(a | 3)), (q1(M1) :- M1:3), (q2(M2) :- M2:(3:a)),
                       (q3 :- a, foo:3), foo:(q4 :- 3), foo:(3 :- a), (q5 => 3), (q6 => foo:3),
                       (q7(Z) :- foo:Z), (q8(M3) :- M3:a), (q9 :- []), (r1 :- a, []), (_:r2),
                       (r3, 3 => true), (r4(M4) :- a, M4:3), (r5(M5) :- a, M5:(b, 3)),
                       (r6(M6) :- \+ M6:3), (r7(M7) :- foo:(a, M7:3)), (r8 :- a, 3:foo) ]),
           ( catch(assertz(C), error(F, _), ( shown(refused(F)), fail ))
           -> print(stored), nl
           ;  true )),
    ( catch(clause(q7(_), B1), _, fail) -> shown(B1) ; true ),
    ( catch(clause(q8(_), B2), _, fail) -> shown(B2) ; true ),
    %% a cycle of qualifiers: a clause's or a head's is no acyclic term, a
    %% body's a cyclic term the store cannot hold
    X = foo:X, catch(assertz(X), error(F1, _), true), print(F1), nl,
    Y = foo:Y, catch(assertz((Y :- true)), error(F2, _), true), print(F2), nl,
    W = foo:W, catch(assertz((s1 :- W)), error(F3, _), true), print(F3), nl.

%% a term, its variables written `_'
shown(T) :-
    copy_term(T, C), term_variables(C, Vs), maplist(=('_'), Vs),
    print(C), nl.
