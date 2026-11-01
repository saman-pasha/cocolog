%% What clause/2 gives back of a clause, as swipl 9.0.4's compiler keeps
%% it (cocolog 3.15.0): a body's conjunctions made one (in the arms of the
%% constructs too, never in a goal's argument); a variable where a goal
%% stands as call/1 of it; `user:G' as G, any other qualifier said of each
%% goal under it and lost by those the compiler makes no call of; a
%% unification with a variable named nowhere else as `true'; and the
%% unifications that begin a body moved into the head, as the flag
%% `optimise_unify' says. Grammar rules, asserted clauses, retract/1 of the
%% compiled form and the flag itself too.
%%
%% Run by test/files.pl beside swipl. Variables are named by `pv/1'. Left
%% out on purpose: a head variable the body names again after a leading
%% unification, which swipl's compiler moves anyway and its clause/2 then
%% shows as another variable (`p(X) :- X = 1, X = 2' is `p(1) :- A = 2',
%% and then runs as it says) -- cocolog keeps such a clause's unification
%% (COMPAT.md).

:- set_prolog_flag(double_quotes, codes).
:- dynamic d/1, n2/1, n3/1.

%% a dynamic predicate's clauses keep their unifications, a file's too
n3(X) :- X = 1, b.
n3(X) :- X = f(Y), g(Y).

c1 :- (b, c), d.
c2 :- b, (c, (d, e)), f.
c3 :- true, b.
c4 :- b, true.
c5(X) :- X.
c6(X) :- (X, true).
c7 :- (b ; c), d.
c8 :- \+ (b, c).
c9 :- (b -> c ; d).
c10 :- (b, c -> d ; e).
c11 :- call((b, c)).
c12 :- findall(X, (p(X), (q, r)), _).
c13 :- !, b.
c14 :- b, !.
c15 :- catch((b, c), _, true).
c16(X) :- X = f(Y), g(Y).
c17(X, Y) :- Y = X, g(Y).
c18(X) :- g(Y), X = f(Y).
c19 :- 1 =:= 1, X is 1 + 2, w(X).
c20 :- (b, c).
c21 :- ((b, c), (d, e)).
c22 :- not((b, c)).
c23 :- (b *-> c ; d).
c24 :- (b, c ; d, e).
c25 :- once((b, c)).
c26(X) :- f(X) = f(1).
c27(X) :- X = 1.
c28(X, Y) :- X = Y.
c29(X) :- X = Y, h(Y).
c30 :- (true, true).
c31 :- true.
c32 :- (b | c).
c33(X) :- (X = 1 ; X = 2).
c34(X) :- a, X = f(Y), g(Y).
c35(f(X)) :- X = 1.
c36 :- forall((b, c), d).
c37(X) :- \+ X.
c38(X) :- call(X, 1).
c39(X) :- (X -> a ; b).
c40 :- (b -> true ; c).
c41 :- (b ; true).
c42 :- (b -> c).
c43(X) :- X == 1, b.
c44(X) :- Y = X, Y = 1.
c45(X) :- [] = X.
c46(X) :- X = "abc".
c47(X) :- X = 1.0.
c48 :- user:(b, c).
c49 :- user:b, c.
c50(X, X) :- true.
u1(X, Y) :- X = 1, Y = 2, b.
u3(X, X) :- X = 1.
u4(X) :- X = f(X).
u5(X, Y) :- X = f(Y).
u9(X, Y) :- Y = f(X).
u10(X) :- 1 = X.
u11(X) :- f(Y) = X, g(Y).
u12(X) :- X = _.
u14(X) :- X = 1 ; b.
u17(X) :- X = [a|T], b(T).
u18(X) :- X = 1, !.
u19(X) :- true, X = 1.
u20(X) :- X = 1, Y = 2, b(Y).
u21(X, Y) :- X = 1, _Z = 2, Y = 3.
u22(X) :- X = f(Z), Z = 1.
u24(X) :- X = "abc".
u26(X) :- X = 12345678901234567.
u27(X) :- X = f(_).
u29(X, Y) :- X = f(A), Y = g(A).
u33(a, X) :- X = 1.
u34(X, f(X)) :- X = 1.
u36(X) :- (X = 1, b), c.
u37(X) :- ((X = 1, b), c).
u38(X, Y) :- (X = 1, Y = 2), b.
u39(X) :- X = Y, Y = 1.
u40(X) :- X = 1.0e10.
u41(X) :- X = 'hello world'.
u42(X) :- X = [].
u43(X) :- X = '[]'.
u44(X) :- X = {a}.
u45(X) :- X = (a :- b).
u46(X, Y, Z) :- Z = 1, X = Y.
u48(X) :- X = a, write(x).
u49([X]) :- X = 1.
u50(X, Y) :- f(X) = f(Y).
u51(X) :- X = 1r3.
u52(X) :- X = "".
u53(X) :- \+ X = 1.
u54(X) :- X = f(Y, Y).
u57(_, X) :- X = 1.
w1 :- b, _Z = 2, d.
w2 :- _ = 2, b.
w3(X) :- X = 1, _ = f(_), b.
w4(X, Y) :- Y = Z, X = 1, b(Z).
w5(X) :- !, X = 1.
w6(X) :- (true, X = 1), b.
w7(X) :- X = 1, true, b.
w8(X, Y) :- true, X = 1, true, Y = 2.
w9(X) :- _Z = 1, X = 2.
w10(X, Y) :- Y = _, X = 1.
w11(X) :- X = Y, b(Y).
w12(X, Y) :- Z = Y, X = 1, b(Z).
w13(X) :- X = f(Y), b(Y), c.
w14(X) :- X = f(_), b.
w15 :- (b, c), (d ; e), \+ ((f, g), h), (((i, j), k) -> l ; m), call(((n, o), p)), findall(_, ((q, r), s), _), catch(((t, u), v), _, true), not(((w, x), y)), forall(((a1, a2), a3), a4).
w16 :- system:b, lists:append(_, _, _), user:c, foo:d.
w17(X) :- user:X.
w18(M) :- M:(b, c).
w19 :- user:(user:b, c).
w20 :- (b ; (c, d), e).
w21(X) :- (X = 1 -> b ; c).
w22(X) :- X = 1, (b, c).
x1 :- foo:(b, c).
x2 :- foo:(b ; c).
x3 :- foo:(b -> c ; d).
x4 :- foo:(\+ b).
x6(M) :- M:b.
x7 :- lists:(append(_,_,_), b).
x8 :- user:foo:b.
x9 :- foo:user:b.
x11 :- foo:!.
x12 :- user:!.
x13 :- foo:true.
x14 :- user:true, b.
x15(X) :- user:(X = 1), b.
x16 :- system:(b, c).
x17(X) :- foo:(X = 1), b.
x18 :- foo:(b, (c, d)).
x19 :- ((b, c) ; d).
x20 :- \+ \+ (b, c).
x21(X) :- X = 1 ; X = 2.
x22(X) :- (X = 1, b ; c).
x23 :- (b, c) -> d.
x24(X) :- (X, b).
x25(X, Y) :- (X ; Y).
x26(X) :- (X -> b ; c).
x27(X) :- \+ (X, b).
x28(X) :- foo:X.
x29(M, X) :- M:X.
x30 :- (b *-> (c, d) ; e).
x31 :- ((b, c) *-> d ; e).
x32(X) :- X = f(Y), (Y = 1 ; Y = 2).
x33 :- a, (true, b).
x34 :- true.
x35 :- (true, (true, true)).
x36 :- call(true).
x37 :- (b ; c ; d).
x38 :- ((b ; c) ; d).
x39 :- ((b -> c) ; d).
x40 :- (b -> (c -> d ; e) ; f).
y1 :- foo:write(x).
y3 :- foo:false.
y4(M) :- M:(\+ b).
y5(M) :- M:(b ; c).
y6(M) :- M:(b -> c ; d).
y7 :- b, 2 = _Z, d.
y8 :- b, _Z = _W, d.
y9 :- b, _Z = f(Y), c(Y).
y10 :- (b ; _Z = 1).
y12(X, X, Y) :- X = 1, Y = 2.
y13(Y) :- f(_Z) = f(1), Y = 2.
y14(X, Y) :- Z = 1, Y = 2, b(Z), X = 3.
y15(X) :- X = 1.
y17(X, Y) :- X = f(Y), b.
y18 :- \+ _Z = 1.
y19(X) :- X == 1.
y20(X) :- (true ; X = 1).
y21(X) :- X = 1, (b ; c).
y22(X) :- (X = 1 ; b), c.
y23(X) :- (X = 1, b ; c).
y24 :- foo:(user:b).
y25 :- foo:(lists:b, c).
y26 :- foo:call(b).
y27 :- foo:(b, !).
y28 :- foo:call(_).
y29(X) :- foo:(X = 1).
y30(X) :- X = 1, foo:b.
z1(M) :- M:!.
z2(M) :- M:true.
z3(M) :- M:(user:b).
z5(X) :- foo:(\+ X).
z6(X) :- foo:(X, b).
z7(X) :- b(X), foo:var(X), foo:nonvar(X), foo:atom(X), foo:fail.
z8(X) :- X = _, b.
z9(X) :- _ = X, b.
z10(X, Y) :- X = Y, Y = _, b.
z11(X) :- (X *-> a ; b).
z12(X) :- foo:(X = 1, b).
z13(M, X) :- M:(X = 1).
z14 :- foo:(b *-> c ; d).
z15 :- foo:(b | c).
z16(X) :- X = f(Y), Y = Z, b(Z).
z17 :- user:(b | c).
z18(X) :- X = 1, b.
z18(X) :- X = 2, c.
z18(X) :- X = f(Y), d(Y).
k(X, Y) :- b(X, Y), foo:(integer(X), float(X), number(X), atomic(X), callable(X), compound(X), is_list(X), string(X), ground(X), blob(X, _), rational(X), is_dict(X), X @< Y, X \= Y, X =@= Y, X is Y, X < Y, X =:= Y, false, otherwise, call(X), not(X), \+ X, halt, repeat, catch(X, _, true), findall(_, X, _), member(X, Y), atom(X), var(X), nonvar(X), atom_length(X, Y), functor(X, Y, 1), arg(1, X, Y), X =.. Y, copy_term(X, Y), succ_or_fail).
g1 --> (a, b), c.
g2 --> [x], a.
g3 --> a, [x].
g4 --> {X = 1}, b(X).
g5 --> !, [x].
g6 --> [].
g7 --> {}.
g8 --> (a ; [x]), b.
g9 --> \+ a, b.
g10 --> call(foo), b.
g11, [p] --> a.
g12 --> "ab", a.
g13(X) --> {X = f(Y)}, b(Y).
g14 --> a, {true}, b.
g15 --> ([] ; a), b.
g16 --> a -> b ; c.
g17 --> {a}, !, {b}.
g18(X) --> [X].
g19 --> foo:a.

q.
t1 :- user:(member(X, [1, 2, 3]), !), write(X), nl, fail.
t1 :- write(second), nl.
t2(M) :- M:(member(X, [1, 2]), !), write(X), nl, fail.
t2(_) :- write(second), nl.

pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

show(N/A) :-
    functor(H, N, A),
    forall(clause(H, B), ( pv(H-B), nl )).

t(G) :- catch(( G -> R = yes ; R = no ), E, R = E), pv(R), nl.

main :-
    forall(member(P, [c1/0,c2/0,c3/0,c4/0,c5/1,c6/1,c7/0,c8/0,c9/0,c10/0,c11/0,c12/0,c13/0,c14/0,c15/0,c16/1,c17/2,c18/1,c19/0,c20/0,c21/0,c22/0,c23/0,c24/0,c25/0,c26/1,c27/1,c28/2,c29/1,c30/0,c31/0,c32/0,c33/1,c34/1,c35/1,c36/0,c37/1,c38/1,c39/1,c40/0,c41/0,c42/0,c43/1,c44/1,c45/1,c46/1,c47/1,c48/0,c49/0,c50/2,u1/2,u3/2,u4/1,u5/2,u9/2,u10/1,u11/1,u12/1,u14/1,u17/1,u18/1,u19/1,u20/1,u21/2,u22/1,u24/1,u26/1,u27/1,u29/2,u33/2,u34/2,u36/1,u37/1,u38/2,u39/1,u40/1,u41/1,u42/1,u43/1,u44/1,u45/1,u46/3,u48/1,u49/1,u50/2,u51/1,u52/1,u53/1,u54/1,u57/2,w1/0,w2/0,w3/1,w4/2,w5/1,w6/1,w7/1,w8/2,w9/1,w10/2,w11/1,w12/2,w13/1,w14/1,w15/0,w16/0,w17/1,w18/1,w19/0,w20/0,w21/1,w22/1,x1/0,x2/0,x3/0,x4/0,x6/1,x7/0,x8/0,x9/0,x11/0,x12/0,x13/0,x14/0,x15/1,x16/0,x17/1,x18/0,x19/0,x20/0,x21/1,x22/1,x23/0,x24/1,x25/2,x26/1,x27/1,x28/1,x29/2,x30/0,x31/0,x32/1,x33/0,x34/0,x35/0,x36/0,x37/0,x38/0,x39/0,x40/0,y1/0,y3/0,y4/1,y5/1,y6/1,y7/0,y8/0,y9/0,y10/0,y12/3,y13/1,y14/2,y15/1,y17/2,y18/0,y19/1,y20/1,y21/1,y22/1,y23/1,y24/0,y25/0,y26/0,y27/0,y28/0,y29/1,y30/1,z1/1,z2/1,z3/1,z5/1,z6/1,z7/1,z8/1,z9/1,z10/2,z11/1,z12/1,z13/2,z14/0,z15/0,z16/1,z17/0,z18/1,k/2,g1/2,g2/2,g3/2,g4/2,g5/2,g6/2,g7/2,g8/2,g9/2,g10/2,g11/2,g12/2,g13/3,g14/2,g15/2,g16/2,g17/2,g18/3,g19/2]),
           show(P)),
    %% asserted clauses are compiled as consulted ones
    assertz((d(X) :- (b, c), X = f(Y), g(Y))), show(d/1),
    assertz((d2 :- (b, c), d)), show(d2/0),
    assertz((v1(X1) :- X1 = 1, b)), show(v1/1),
    assertz((v2(X2) :- X2 = f(Y2), g(Y2))), show(v2/1),
    assertz((v3(X3) :- (X3 = 1, b), c)), show(v3/1),
    asserta((v4(X4, Y4) :- X4 = Y4)), show(v4/2),
    assertz((v5(X5) :- X5 = 1)),
    t(clause(v5(2), _)),
    t(clause(u27(f(q)), _)),
    t(clause(u27(g), _)),
    %% retract/1 matches the compiled clause
    t(retract((v1(1) :- b))),
    t(retract((v2(X6) :- X6 = f(Y6), g(Y6)))),
    t(retract((v2(f(Y7)) :- g(Y7)))),
    %% the cut under user: is the clause's, as is one under a module
    t(t1), t(t2(user)),
    %% the counts of a fact and a rule
    assertz((f3 :- true)), assertz(f4),
    forall(member(P8, [q, f3, f4, c13, k(_, _)]),
           ( predicate_property(P8, number_of_rules(R8)),
             predicate_property(P8, number_of_clauses(C8)),
             pv(P8-R8-C8), nl )),
    %% the flag
    t(current_prolog_flag(optimise_unify, true)),
    t(set_prolog_flag(optimise_unify, foo)),
    t(set_prolog_flag(optimise_unify, _)),
    t(( current_prolog_flag(F11, _), F11 == optimise_unify )),
    t(set_prolog_flag(optimise_unify, on)),
    t(set_prolog_flag(optimise_unify, false)),
    t(current_prolog_flag(optimise_unify, false)),
    assertz((o1(X9) :- X9 = 1, b)), show(o1/1),
    assertz((o2 :- (b, c), d)), show(o2/0),
    t(set_prolog_flag(optimise_unify, off)),
    t(set_prolog_flag(optimise_unify, true)),
    assertz((o3(X10) :- X10 = 1, b)), show(o3/1),
    %% only a static predicate's clauses are moved: the first assert to
    %% a predicate with none, never a later one, a declared one's or one
    %% that retractall/1 made dynamic
    assertz((n1(A1) :- A1 = 1, b)), assertz((n1(B1) :- B1 = 2, c)), show(n1/1),
    assertz((n2(A2) :- A2 = 1, b)), show(n2/1),
    show(n3/1),
    t(retractall(n4(_))), t(predicate_property(n4(_), dynamic)),
    t(current_predicate(n4/1)),
    assertz((n4(A4) :- A4 = 1, b)), show(n4/1),
    t(retractall(n5(f(_)))), t(predicate_property(n5(_), dynamic)),
    t(retractall(foo:n6(_))), t(predicate_property(foo:n6(_), dynamic)),
    %% a cyclic clause is refused at its put, a `=/2' in its body counted
    %% first: the count gives up past twice the heap's length
    X12 = f(X12), tf(assertz((cy(X12) :- Y12 = X12, Y12 == 1))),
    Z12 = g(Z12), tf(assertz((cz :- W12 = Z12, W12 == 1))).

tf(G) :- catch(( G -> R = yes ; R = no ), error(F, _), R = F), pv(R), nl.
