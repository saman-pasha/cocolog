%  $/1 and @/2, swipl's control constructs: $(G) is G, which must succeed
%  and leave no choice point -- determinism_error(G, det, fail|nondet,
%  goal) where it does not, named by the clause $/1 is written in or by
%  '<meta-call>'/1, its cut G's own -- and G@M is G called with M its
%  context module, its cut the clause's. What a clause stores of them, as
%  swipl's compiler keeps it (G an arm of $/1, G@M said of each goal under
%  it), what a load and an assert refuse, what a meta-call asks of them
%  before it runs, and how listing/1 lays $/1 out. Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte; each line is one
%  of swipl 9.0.4's answers. Not here: $/0 (test/files/det_guard.pl); a
%  variable of G its clause names nowhere else, which G binds and the
%  error's G shows bound, where swipl's decompiled goal has a fresh one;
%  context_module/1, which cocolog has not; and a load's refusal whose
%  culprit holds a variable, whose number swipl writes (asserted below).

p(1).
p(2).
q(1).
w(0) :- !.
w(N) :- N1 is N - 1, w(N1).

%% ---- $(G) run ----------------------------------------------------------
a1 :- $(q(X)), writeln(X).
a2 :- $(p(X)), writeln(X).
a3 :- $(fail).
a4 :- $(throw(ball)).
a5 :- G = p(X), $(G), writeln(X).
a6 :- $((p(X), X > 1)), writeln(X).
a7 :- $(\+ fail).
a8 :- $(!), fail.
a8 :- writeln(a8_second).
a9 :- $((p(X), !)), writeln(X).
b1 :- \+ ( $(p(X)), X == 2 ).
b2 :- ( $(p(X)) -> writeln(X) ; true ).
b3 :- $($(q(X))), writeln(X).
b4 :- $(setup_call_cleanup(true, q(X), writeln(cleaned))), writeln(X).
b5 :- forall(member(X, [1]), $(p(X))).
b6 :- $((w(3), q(X), w(2))), writeln(X).
b7 :- $((q(X) ; true)), writeln(X).
b8 :- $(catch(p(X), E, true)), writeln(X-E).
b9 :- $(p(X)), X > 5.

%% ... meta-called: a '<meta-call>'/1 names it
c1 :- call($(p(X))), writeln(X).
c2 :- findall(X, $(p(X)), L), writeln(L).
c3 :- once($(p(X))), writeln(X).
c4 :- catch($(p(X)), E, (shown(caught(E)), X = none)), writeln(X).
c5 :- G = ($(fail) -> true ; true), call(G).
c6 :- once($(fail)).
c7 :- \+ $(fail).
c8 :- findall(x, $(fail), L), writeln(L).

%% ---- G@M run -----------------------------------------------------------
d1 :- @(q(X), m), writeln(X).
d2 :- @(!, m), fail.
d2 :- writeln(d2_second).
d3 :- @((p(X) ; X = 3), m), writeln(X).
d4(M) :- @(q(X), M), writeln(X).
d5 :- @(undefined_xyz, foo).
d6 :- G = writeln(hi), @(G, user).
d7 :- call(@(writeln(x), foo)).
d8 :- M = foo, call(@(writeln(y), M)).
d9 :- @(p(X), foo), writeln(X).

%% ... meta-called: its module and its goal asked first, in the caller's
%% frame; inside a structure an unbound module raises as it runs
e1 :- call(@(writeln(z), _)).
e2 :- call(@(writeln(z), 3)).
e3 :- call(@(undefined_xyz, m)).
e4 :- call(@((true, undefined_xyz), m)).
e5 :- once(@(foo, _)).
e6 :- findall(x, @(foo, _), _).
e7 :- catch(@(foo, 3), E, true), shown(E).
e8 :- G = @(@(foo, _), m), call(G).
e9 :- G = (true, @(foo, _)), call(G).
f1 :- G = (true, @(foo, 3)), call(G).
f2 :- G = (fail, $(1)), call(G).
f3 :- G = $(1), call(G).
f4 :- G = @(1, m), call(G).
f5 :- G = @(_, _), call(G).
f6 :- G = @(3, f(x)), call(G).
f7 :- G = (1, @(foo, 3)), call(G).
f8 :- G = (@(foo, 3), 1), call(G).
f9 :- G = $(_), call(G).
g1 :- G = (fail, $(_)), call(G).
g2 :- G = @(_:bar, m), call(G).
g3 :- G = @(3:bar, m), call(G).
g4 :- once($(3)).
g5 :- findall(x, $(3), _).
g6 :- G = $((fail, 1)), call(G).
g7 :- G = @((fail, 1), m), call(G).
g8 :- G = @(foo, []), call(G).
g9 :- G = (fail ; @(_, m)), call(G).
h1 :- G = (fail, @(1, m)), call(G).
h2 :- findall(x, @(_, m), _).
h3 :- findall(x, @(foo, 3), _).
h4 :- once(@(foo, 3)).
h5 :- once(@(1, m)).
h6 :- $(q(X)), X == 2.
h7 :- G = (true ; @(foo, _)), call(G).
h8 :- G = @(true, m), call(G), writeln(h8_ok).
h9 :- catch(once(@(_, m)), E, true), shown(E).
i1 :- findall(x, (true, @(foo, _)), _).
i2 :- G = @(_, 3), call(G).
i3 :- G = @(foo:_, m), call(G).
i4 :- predicate_property($(_), built_in), predicate_property(@(_, _), built_in).
%% neither is an inference of its own: what is counted is G's
i5 :- statistics(inferences, A0), q(_), statistics(inferences, A1),
      $(q(_)), statistics(inferences, A2), @(q(_), m), statistics(inferences, A3),
      N0 is A1 - A0, N1 is A2 - A1, N2 is A3 - A2, N1 == N0, N2 == N0.
%% ... and what a message says of the determinism errors, $/1's two and
%% swipl's three of another kind
i6 :- message_to_string(error(determinism_error(p(1), det, fail, goal), _), S1), writeln(S1),
      message_to_string(error(determinism_error('A'(x), det, nondet, goal), context(foo/0, _)), S2),
      writeln(S2),
      forall(member(K-F, [property-fail, property-nondet, guard-fail, guard_in_caller-fail]),
             ( message_to_string(error(determinism_error(foo/0, det, F, K), _), S3), writeln(S3) )),
      catch($(fail), E, true), print_message(error, E).
i7 :- once(@(undefined_xyz, m)).
i8 :- G = (true, @(foo, [])), call(G).
i9 :- G = @([]:bar, m), call(G).
i10 :- once(@(foo, [])).
i11 :- findall(x, @(foo, []), _).
%% a once/1 asks its goal before any of it runs
i12 :- once((writeln(a), @(foo, 3))).
i13 :- once((writeln(a), @(foo, []))).
%% a soft cut's else is no choice point, and a disjunction's is one
j1 :- $((q(X) *-> true ; true)), writeln(X).
j2 :- $((true ; true)).

%% ---- what a clause stores ----------------------------------------------
s1 :- $((p(X), (p(Y), X = Y))).
s2(G) :- $(G).
s3 :- $(foo:p).
s4 :- @(foo:p, m).
s5 :- @(@(p, a), b).
s6 :- @((p ; q), m).
s7 :- @((p -> q ; r), m).
s8 :- @(\+ p, m).
s9 :- @(true, m).
t1 :- @(!, m).
t2(M) :- @(p, M).
t3(M) :- @((p, q), M).
t4 :- @($(p), m).
t5 :- $(@(p, m)).
t6 :- @(findall(X, p(X), _), m).
t7 :- @(call(p), m).
t8 :- $((a ; b)).
t9 :- $(\+ a).
u1 :- @(user:p, m).
u2 :- $(true).
u3 :- $(!).
u4 :- @(X = 1, m), X == 1.
u5 :- $(X = 1), X == 1.
u6 :- @(p(X), user), X == 1.
u7 :- $((true, true)).
u8(M) :- $(M:p).
u9 :- foo: $(p).
v1 :- foo: @(p, m).
v2 :- foo:(@(p, m), q).
v3 :- @(foo:(a, b), m).
v4 :- @(foo:(a ; _ = 1), m).
v5(M) :- M: @(p, m).
v6(M) :- @(M:(a, b), m).
v7 :- @((a, X), m), X = 1.
v8 :- @(foo: !, m).
v9 :- foo: $((a, b)).
x1 :- @((a | b), m).
x2 :- @((a *-> b ; c), m).
x3(G) :- @((a, G), m).
x4 :- @((a, call(b)), m).
x5 :- @(foo:bar:p, m).
x6 :- @(@((a, b), x), y).
x7(M) :- M:(a, X), X = 1.
x8 :- foo:(a, X), X = 1.
x9 :- @(foo:X, m), X = 1.
y1 :- $(foo:X), X = 1.
y2(M) :- $(M:X), X = 1.
y3(M) :- @(foo, M).
y4 :- X = m, @(foo, X).

%% ---- what a load refuses -----------------------------------------------
n1 :- $(3).
n2 :- @(3, m).
n3 :- @(foo, 3).
n4 :- @((a, 3), m).
n5 :- $((a, 3)).
n6 :- @(foo, M), M = a.
n7 :- @(foo, []).
n8 :- @(foo, f(x)).
n9 :- @(!, M), M = a.
o1 :- @(true, 3).
o2 :- @((a ; 3), m).
o3 :- $(foo:3).
o4 :- @(foo:3, m).
o5 :- @(3, 3).
o6 :- b, @((a, 3), m).
o7 :- @($(3), m).
o8 :- $(@(3, m)).
o9 :- @(@(3, m), n).
o10 :- @(foo, _).
o11 :- @(_:foo, m).
o12 :- $(_:foo).
o13 :- @(foo, M), true, M = a.
o14 :- @(foo, m:n).

%% ---- listing/1 ---------------------------------------------------------
l1 :- $((a, b)).
l2 :- $((a ; b)).
l3 :- $((a -> b ; c)).
l4 :- x, $(a), y.

names([s1,s2/1,s3,s4,s5,s6,s7,s8,s9,t1,t2/1,t3/1,t4,t5,t6,t7,t8,t9,u1,u2,u3,u4,u5,u6,u7,u8/1,u9,
       v1,v2,v3,v4,v5/1,v6/1,v7,v8,v9,x1,x2,x3/1,x4,x5,x6,x7/1,x8,x9,y1,y2/1,y3/1,y4,
       n1,n2,n3,n4,n5,n6,n7,n8,n9,o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13,o14]).

runs([a1,a2,a3,a4,a5,a6,a7,a8,a9,b1,b2,b3,b4,b5,b6,b7,b8,b9,c1,c2,c3,c4,c5,c6,c7,c8,
      d1,d2,d3,d4(_),d4(3),d4([]),d5,d6,d7,d8,d9,e1,e2,e3,e4,e5,e6,e7,e8,e9,f1,f2,f3,f4,f5,f6,f7,f8,f9,
      g1,g2,g3,g4,g5,g6,g7,g8,g9,h1,h2,h3,h4,h5,h6,h7,h8,h9,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,j1,j2]).

main :-
    runs(Rs),
    forall(member(R, Rs), try(R)),
    names(Ns),
    forall(member(N0, Ns),
           ( ( N0 = N/A -> true ; N = N0, A = 0 ),
             functor(H, N, A),
             ( catch(clause(H, B), _, fail) -> shown(N-B) ; print(N-none), nl ) )),
    forall(member(C, [ (ap :- $(3)), (ap :- @(3, m)), (ap :- @(foo, 3)), (ap :- @(foo, _)),
                       (ap :- $(_)), (ap :- @(_, m)), (ap :- @(!, _)), (ap :- @(true, 3)),
                       (ap :- @(3, 3)), (ap :- @(3, _)), (ap :- @(_, 3)), (ap :- b, @((a, 3), m)),
                       (ap :- @($(3), m)), (ap :- $(@(3, m))), (ap :- @(foo:_, m)), (ap :- @(_:foo, m)),
                       (ap :- $(_:foo)), (ap :- @(foo, m:n)), (ap :- @((a, _), m)), (ap :- $(foo:_)),
                       (ap :- @(foo, M2), M2 = a), (ap :- $((a, X3)), X3 = 1), (ap(M4) :- @(foo, M4)),
                       (ap :- $((X5 ; X5))), (ap :- @((X6 ; X6), m)), (ap :- $((a ; _))), (ap :- @(\+ 3, m)) ]),
           ( catch(assertz(C), error(F, _), ( shown(refused(F)), fail ))
           -> print(stored), nl
           ;  true )),
    ( catch(clause(ap(_), B5), _, fail) -> shown(B5) ; true ),
    ( catch(clause(ap, B6), _, fail) -> shown(B6) ; true ),
    listing(l1), listing(l2), listing(l3), listing(l4),
    portray_clause((x :- @((a, b), m))), portray_clause((x :- $((a -> b ; c)), @(\+ a, m))).

try(G) :-
    catch(( G -> shown(yes(G)) ; shown(no(G)) ), E, shown(caught(E))).

%% a term, its variables written `_'
shown(T) :-
    copy_term(T, C), term_variables(C, Vs), maplist(=('_'), Vs),
    print(C), nl.
