%% The predicate a body goal's error names -- held to swipl 9.0.4 (cocolog
%% 3.1.0).
%%
%% swipl raises an error a clause's body meets as error(Formal,
%% context(Pred, _)), Pred the frame the goal ran in. An unknown procedure
%% names the clause's own predicate, or the predicate that called it when
%% the clause's frame went at its last call (the last-call optimisation,
%% which a choice point younger than the clause stops); a goal that is no
%% goal names the clause it stands in; a goal handed to once/1, ignore/1,
%% not/1, call/N or catch/3 names that predicate, a system frame of its
%% own; and a control construct called as a term -- a variable bound to
%% (A, B), a disjunction, an if-then-else, \+ -- runs whole as
%% '<meta-call>'/1, which names its own goals' errors, after it has
%% refused the whole term if any part of it is no goal. Through 3.0.0
%% cocolog left an unknown procedure's context unbound in a body and named
%% '<meta-call>'/1 for every body goal that was no goal.
%%
%% Each probe is called under catch/3 and printed as the goal, then yes,
%% no or the ball, every variable written `_'. Left out, and why (stated
%% in STATUS.md, 3.1.0): call/1 or a variable goal as the last goal of a
%% clause whose own last call is the unknown one (swipl keeps the call's
%% frame, and names the predicate the call reached); a clause whose head
%% hands a goal to a variable goal of its body (d(X) :- X); a qualified
%% goal; and "..." as a goal, which the double_quotes flag reads.

e(G) :-
    (   catch(( G -> R = yes ; R = no ), E, R = E) -> true ; R = failed ),
    copy_term(G-R, G2-R2),
    term_variables(G2-R2, Vs), maplist(=('$VAR'('_')), Vs),
    print(G2), write('  ==>  '), print(R2), nl.

%% the same, with the goal handed straight to catch/3, a system frame
w(G) :-
    (   catch(G, E, true) -> ( var(E) -> R = yes ; R = E ) ; R = no ),
    copy_term(G-R, G2-R2),
    term_variables(G2-R2, Vs), maplist(=('$VAR'('_')), Vs),
    print(w(G2)), write('  ==>  '), print(R2), nl.

main :- forall(p(G), e(G)), forall(p(G), w(G)).

%% a clause whose last call is an unknown procedure, and one that goes on
p5 :- foo_undefined.
p5b :- G = 1, G.

%% the unknown procedure, by where it stands
c1 :- G = (true, foo_undef), G.
c3 :- G = (true, foo_undef), G, true.
c4 :- G = (true, p5), G, true.
c5 :- G = (foo_undef, true), G.
c6 :- G = foo_undef, G.
c7 :- p5.
c8 :- foo_undef.
c9 :- true, foo_undef.
c10 :- G = (true, (true, foo_undef)), G.
c11 :- G = (true ; foo_undef), G, fail.
c12 :- G = (fail ; foo_undef), G.
c13 :- G = (true -> foo_undef ; true), G.
c14 :- G = (\+ foo_undef), G.
c15 :- X = 1, G = (true, X), G.
c16 :- once((true, foo_undef)).
c17 :- call((true, foo_undef)).

d1 :- member(_, [1, 2]), foo_undef.
d2 :- foo_undef.
d2 :- true.
d3(1) :- foo_undef.
d3(2).
d4 :- G = (true, _), G.
d5 :- once((true, foo_undef)).
d6 :- ignore((true, foo_undef)).
d7 :- not((true, foo_undef)).
d8 :- \+ (true, foo_undef).
d9 :- (true ; foo_undef), fail.
d10 :- (foo_undef ; true).
d11 :- G = foo_undef, call(G), true.
d12 :- forall(foo_undef, true).
d13 :- forall(true, foo_undef).
d14 :- forall(p5, true).
d15 :- G = (true, (fail, 1)), G.
d16 :- call((fail, 1)).
d17 :- once((fail, 1)).
d18 :- findall(x, (fail, 1), _).
d19 :- G = 1, G.
d20 :- once(foo_undef).
d21 :- call(once(foo_undef)).
d22 :- (true -> foo_undef ; true).
d23 :- (fail -> true ; foo_undef).
d24 :- p5, !.
d25 :- !, foo_undef.
d26 :- G = foo_undef, \+ G.
d27 :- G = (true, foo_undef), \+ G.
d28 :- call(foo_undef, 1).
d29 :- G = foo_undef, call(G, 1).

%% a goal that is no goal, by where it stands
b1 :- G = 1, once(G).
b2 :- G = 1, ignore(G).
b3 :- G = 1, \+ G.
b4 :- G = 1, not(G).
b5 :- G = 1, call(G), true.
b6 :- G = (true, 1), call(G).
b7 :- G = (fail, 1), G.
b8 :- G = (true ; 1), G.
b9 :- G = (1 -> true ; true), G.
b10 :- G = (\+ 1), G.
b11 :- G = (true, foo_undef), G.
b12 :- G = foo_undef9, call(G).
b13 :- G = foo_undef10, once(G).
b14 :- G = (true, X), X = 1, G.
b15 :- findall(x, 1, _).
b16 :- G = 1, findall(x, G, _).
b17 :- catch(1, _, true).
b18 :- G = 1, catch(G, _, true).
b20 :- G = [a], G.
b21 :- G = (a :- b), G.

%% a search's goal, and the frames above an unknown procedure
q1 :- catch(p5, _, true).
q2 :- findall(x, p5, _).
q3 :- once(p5).
q4 :- \+ p5.
q5 :- forall(p5, true).
q8 :- p5, true.
q9 :- ( p5 -> true ; true ).
q10 :- catch(p5b, _, true).
q11 :- G = p5, call(G), true.
q12 :- aggregate_all(count, p5, _).
q13 :- G = p5, once(G).

%% call/N by where it is written: in a clause or a structure swipl
%% compiles it inline, and the frame it is written in names its goal's
%% errors; reached any other way -- a variable, once/1, findall/3 -- it is
%% a frame of its own
e1 :- once(call(1)).
e2 :- \+ call(1).
e3 :- findall(x, call(1), _).
e4 :- G = call(1), G.
e5 :- G = call(1), once(G).
e6 :- call(call(1)).
e7 :- call(call(foo_undef)).
e8 :- once(call(foo_undef)).
e9 :- G = (call(1), true), G.
e10 :- G = (call(foo_undef), true), G.
e11 :- call((call(foo_undef), true)).
e12 :- call(foo_undef), true.
e13 :- forall(call(1), true).
e14 :- G = call(foo_undef), G, true.
e15 :- G = call(foo_undef, 1), G, true.
e16 :- ( call(1) -> true ; true ).
e17 :- ( call(foo_undef) -> true ; true ).
e18 :- catch(call(1), x, true).
e19 :- G = foo_undef, (G, true).
e20 :- call((G = call(1), G)).
e21 :- call((G = call(foo_undef), G, true)).

p(e1). p(e2). p(e3). p(e4). p(e5). p(e6). p(e7). p(e8). p(e9). p(e10).
p(e11). p(e12). p(e13). p(e14). p(e15). p(e16). p(e17). p(e18). p(e19).
p(e20). p(e21).
p(once(call(1))). p(once(call(foo_undef))). p(ignore(call(1))).
p(\+ call(1)). p(\+ call(foo_undef)).
p(findall(x, call(1), _)). p(findall(x, call(foo_undef), _)).
p(forall(call(1), true)). p((call(1), true)). p((call(foo_undef), true)).
p(call(call(1))). p(call(call(foo_undef))).
p(catch(call(1), x, true)). p(catch(call(foo_undef), x, true)).
p((call(1) -> true ; true)). p(call((call(1), true))).
p(call(call, 1)). p(call(call, foo_undef)). p(call(once, 1)).
p(c1). p(c3). p(c4). p(c5). p(c6). p(c7). p(c8). p(c9). p(c10). p(c11).
p(c12). p(c13). p(c14). p(c15). p(c16). p(c17).
p(d1). p(d2). p(d3(1)). p(d4). p(d5). p(d6). p(d7). p(d8). p(d9). p(d10).
p(d11). p(d12). p(d13). p(d14). p(d15). p(d16). p(d17). p(d18). p(d19).
p(d20). p(d21). p(d22). p(d23). p(d24). p(d25). p(d26). p(d27). p(d28).
p(d29).
p(b1). p(b2). p(b3). p(b4). p(b5). p(b6). p(b7). p(b8). p(b9). p(b10).
p(b11). p(b12). p(b13). p(b14). p(b15). p(b16). p(b17). p(b18). p(b20).
p(b21).
p(q1). p(q2). p(q3). p(q4). p(q5). p(q8). p(q9). p(q10). p(q11). p(q12).
p(q13).
p(p5). p(p5b).
p((true, foo_undef)). p((true, p5)). p((foo_undef, true)). p((p5, true)).
p(foo_undef). p(call(foo_undef)). p(call((true, foo_undef))).
p(once(p5)). p(\+ p5). p(findall(x, (true, p5), _)).
p(once((true, 1))). p(ignore((true, 1))). p(not((true, 1))).
p(call((true, 1))). p(forall((true, 1), true)).
p(forall(foo_undef, true)). p(forall(true, foo_undef)).
p(aggregate_all(count, (true, foo_undef), _)).
p(aggregate_all(count, (true, 1), _)).
p(findall(x, (true, foo_undef), _)). p(findall(x, (foo_undef, true), _)).
p(call(foo_undef, 1)). p(call(1, 2)).
p(once(1)). p(ignore(1)). p(\+ 1). p(not(1)). p(call(1)). p(1).
p((true, 1)). p(call((fail, 1))). p(findall(x, (true, 1), _)).
p(forall(1, true)). p(forall(true, 1)).
