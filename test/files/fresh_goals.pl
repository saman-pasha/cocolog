%  What a load and an assert refuse of a variable where a goal or a module
%  stands, as swipl's compiler does: a variable goal its count of the
%  clause takes for a singleton -- a disjunction counting its branches'
%  new variables as the larger of the two, `|' as their sum, a \+ inside
%  one leaving them its own -- is no goal, and a variable module no goal
%  before it set is an instantiation error; ==/2 and \==/2 of a variable
%  and a variable or an atom set nothing. Run by BOTH SWI-Prolog and
%  cocolog, output compared byte for byte; each clause is one of swipl
%  9.0.4's answers. Not here: a load's type error, which writes a
%  variable's number (asserted below), and two warnings cocolog does not
%  give: of a test of a variable no goal set (`var(X), X.'), and of a
%  branch's singleton the other branch names inside a goal (`p :- (X ;
%  foo((X ; X))).', asserted below).

%% a variable goal or module that will not do: an instantiation error
r1 :- X.
r2 :- foo:X.
r3 :- foo:bar:X.
r4 :- M:foo.
r5(M) :- M:X.
r6(M) :- M:(X ; true).
r7 :- foo:M:bar.
r8(M) :- M:N:foo.
r9 :- M:foo, M = a.
s1 :- M == a, M:foo.
s2 :- (M = a ; M:foo).
s3 :- (M = a -> true ; M:foo).
s4 :- M \== a, M:foo.
s5 :- M == [], M:foo.
s6 => X.
s7 :- (M == N, N:foo), M = 1.
s8 --> M:foo.
s9 :- M == 1, M:foo.
s10 :- X = 1, X == M, M:foo.

%% and what will: a variable another goal names, or one a goal set
t1(X) :- X.
t2 :- X, X = a.
t3 :- X = a, X.
t4 :- (X = a ; true), X.
t5 :- (X | X).
t6 :- (X, X ; true).
t7(M) :- M:foo.
t8 :- M = a, M:foo.
t9 :- foo(M), M:bar.
u1 :- (M = a ; true), M:foo.
u3 :- (M == a ; true), M:foo.
u4 :- M == f(a), M:foo.
u5 :- X = Y, Y:foo.
u6 :- M is 1+2, M:foo.
u7(Y) :- M is Y+1, M:foo.
u8 :- arg(1, f(a), M), M:foo.
u9 :- M == 3000000000, M:foo.
v1 :- M == 1.5, M:foo.
v2 :- (true ; X), (true ; X).
v3 :- ((X ; true), X ; true).
v4 :- M == N, N:foo.
v5(X) :- (true ; X).
v6 :- X, X:foo.
v7 --> X.

names([r1,r2,r3,r4,r5/1,r6/1,r7,r8/1,r9,s1,s2,s3,s4,s5,s6,s7,s8/2,s9,s10,
       t1/1,t2,t3,t4,t5,t6,t7/1,t8,t9,u1,u3,u4,u5,u6,u7/1,u8,u9,v1,v2,v3,v4,v5/1,v6,v7/2]).

main :-
    names(Ns),
    forall(member(N0, Ns),
           ( ( N0 = N/A -> true ; N = N0, A = 0 ),
             functor(H, N, A),
             ( catch(clause(H, B), _, fail) -> shown(N-B) ; print(N-none), nl ) )),
    forall(member(C, [ (q1 :- true, X1), (q2 :- (true ; X2)), (q3 :- \+ X3), (q4 :- (X4 ; X4)),
                       (q5 :- (X5 = a ; X5)), (q6 :- ((X6 ; true) ; X6)), (q7 :- (X7 ; \+ X7)),
                       (q8 :- foo:(true, X8)), (q9(M9) :- (M9:X9 ; true)), (w1(M10) :- true, M10:X10),
                       (w2 :- (X11 -> true ; true)), (w3 :- X12, true), (w4 :- (X13 *-> true ; true)),
                       (w5 :- (true | X14)), (w6 :- !, X15), (w7 :- M16:foo, 3:bar), (w8 :- 3:bar, M17:foo),
                       (w9 :- X18, M19:foo), (x1 :- M20:foo, X21), (x2 :- (X22 | X22)), (x3 :- (\+ X23 ; X23)),
                       (x4(X24) :- (true ; X24)), (x5 :- (X25, X25 ; true)), (x6 :- M26 == N26, N26:foo),
                       (x7 :- X27), (x8 :- foo:X28), (x9 :- M29 == a, M29:foo), (y1 :- (M30 = a ; M30:foo)),
                       (y2(M31) :- M31:(X31 ; X31)), (y3 :- M32 == [], M32:foo), (y4 :- \+ M33 = a, M33:foo),
                       (y5 :- (\+ X34 ; true), X34), (y6 :- \+ (X35 ; true), X35), (y7 :- ((true ; X36) ; X36)),
                       (y8 :- (true ; (true ; X37)), X37), (y9 :- ((X38 ; true) ; true), X38),
                       %% a disjunction inside a goal is no branch: X counts three
                       (z1 :- (X39 ; foo((X39 ; X39)))), (z2 :- M40:foo), (z3(M41) :- M41:foo) ]),
           ( catch(assertz(C), error(F, _), ( shown(refused(F)), fail ))
           -> print(stored), nl
           ;  true )),
    ( catch(retract((nothere :- Z)), E, (print(E), nl)) -> print(retracted(Z)), nl ; print(noretract), nl ),
    forall(member(H2, [x2, x3, x4(_), x5, x6, y4, y5, y6, y8, y9, z1]),
           ( catch(clause(H2, B2), _, fail) -> shown(B2) ; true )).

%% a term, its variables written `_'
shown(T) :-
    copy_term(T, C), term_variables(C, Vs), maplist(=('_'), Vs),
    print(C), nl.
