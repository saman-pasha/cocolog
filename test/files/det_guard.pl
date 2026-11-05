%  $/0, swipl's determinism guard: `$' cuts as `!' does and guards the
%  frame it runs in -- the clause it is written in, or the '<meta-call>'/1
%  a goal holding it is called in -- which must then succeed and leave no
%  choice point, else determinism_error(PI, det, fail|nondet, KIND). A
%  last call takes the guard on: over the caller's frame where no choice
%  point is younger than it (swipl's last-call optimisation), the callee's
%  `$' then no longer its own (guard_in_caller, PI the first frame down the
%  guards whose `$' set its guard, else the frame's own), else in a frame
%  of its own; a transparent predicate taking the frame over drops the
%  guard. A goal swipl compiles in place is no call, and call/N's goal, a
%  disjunction's left arm and catch/3's goal no last call. Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte; each line is one
%  of swipl 9.0.4's answers. Every library predicate a case calls is called
%  once first (`warm'): swipl's first call of one it has not resolved yet
%  makes no last call. Not here: a guarded last call into member/2,
%  maplist/2 and the other library predicates swipl writes in Prolog,
%  whose errors name swipl's own helpers (lists:member_/3); a $/1 whose
%  goal holds $/0; and `\+ \+ ($, G)', which stops swipl 9.0.4 on an
%  assertion.

:- use_module(library(lists)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(apply)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form

p(1).
p(2).
q(1).
f1 :- fail.
f2(_) :- fail.

warm :-
    catch(true, _, true), once(true), ignore(true), forall(fail, true),
    findall(_, fail, _), setup_call_cleanup(true, true, true),
    aggregate_all(count, fail, _), not(fail), between(1, 1, _),
    atom_length(a, _), succ_or_zero(1).

succ_or_zero(_).

%% ---- the frame's own guard ---------------------------------------------
a1 :- $, p(_).
a2 :- $, q(_).
a3 :- $, f1.
a4 :- p(_), $, q(_).
a5 :- $, p(_), q(_).
a6 :- $, q(_), p(_).
a7 :- $, p(X), X > 1.
a8 :- $, p(X), q(X).
a9 :- $, p(X), r9(X).
r9(2).
b1 :- $, (p(_) ; true).
b2 :- $, (fail ; p(_)).
b3 :- $, (q(_) -> p(_) ; true).
b4 :- $, (fail -> true ; f1).
b5 :- $, (f1 ; q(_)).
b6 :- $, \+ fail.
b7 :- $, call(p(_)).
b8 :- $, call(f1).
b9 :- $, !, p(_).
c1 :- $, p(_), !.
c2 :- $, atom_length(abc, 4).
c3 :- $, between(1, 3, _).
c5 :- $, findall(X, p(X), _).
c7 :- $, catch(p(_), _, true).
c8 :- $, catch(f1, _, true).
c9 :- $, throw(ball).
d1 :- $, $, q(_).
d2 :- p(X), $, X > 1.
d2 :- writeln(d2_second).
d3 :- $, d3b.
d3b :- p(_), $, q(_).
d4 :- $, d4b.
d4b :- fail.
d4b :- true.
d5 :- top5.
top5 :- $, mid5, x5.
mid5 :- $, f1.
x5.
d6 :- $, p(_), mid6.
mid6 :- f1.
d7 :- $, p(_), mid7.
mid7 :- p(_).
d8 :- $, p(_), mid8.
mid8 :- q(_).
d9 :- $, nested9.
nested9 :- inner9.
inner9 :- p(_).

%% ---- transparent predicates, a last call over the frame -----------------
e1 :- $, once(fail).
e2 :- $, once(p(_)).
e3 :- $, ignore(fail).
e4 :- $, not(fail).
e5 :- $, not(true).
e6 :- $, \+ true.
e7 :- $, forall(fail, true).
e8 :- $, forall(true, fail).
e9 :- $, findall(_, fail, _).
g5 :- $, aggregate_all(count, p(_), _).
g6 :- $, p(_), once(fail).
g7 :- $, p(_), catch(fail, _, true).
k1 :- $, p(_), catch(p(_), _, true).
k2 :- $, p(_), catch(q(_), _, true).
k3 :- $, p(_), cc3.
cc3 :- catch(p(_), _, true).
k5 :- $, catch(p(_), _, true).
k6 :- $, setup_call_cleanup(true, p(_), true).
k7 :- $, setup_call_cleanup(true, fail, true).
m4 :- $, p(_), once(p(_)).
m5 :- $, p(_), ignore(p(_)).
m6 :- $, p(_), forall(p(_), true).
m7 :- $, p(_), findall(_, p(_), _).
m8 :- $, p(_), setup_call_cleanup(true, p(_), true).
m9 :- $, p(_), not(fail).
n1 :- $, p(_), \+ fail.
n2 :- $, p(_), between(1, 2, _).
n3 :- $, between(1, 2, _).
n5 :- $, p(_), atom_length(abc, 4).

%% ---- what swipl compiles in place, and what it calls -------------------
h1 :- $, X = 1, X == 1.
h2 :- $, X = 1, X == 2.
h3 :- $, atom(1).
h4 :- $, X is 1 + 1, X =:= 3.
h5 :- $, _ is foo + 1.
h6 :- $, arg(1, f(a), b).
h7 :- $, var(a).
h8 :- $, p(X), X == 2.
h9 :- $, p(X), X > 1.
i1 :- $, q(X), X == 2.
i3 :- $, @(p(_), user).
i4 :- $, call(p(_)).
i5 :- G = p(_), $, G.
i6 :- G = f1, $, G.
i7 :- $, call(f1).
i8 :- $, p(_), call(f1).
i9 :- $, p(_), G = f1, G.
j1(X) :- $, atom(X).
j2 :- $, j3(1).
j3(X) :- atom(X).
j4 :- $, j5.
j5 :- atom(1).
j6(X) :- $, X \== 1.
j7 :- $, j8(1).
j8(X) :- X = 2.

%% ---- in a goal it is called with ---------------------------------------
w1 :- \+ ($, fail).
w2 :- \+ ($, fail), writeln(after).
w3 :- ( $, q(_) -> true ; true ).
w4 :- ( $, fail -> true ; writeln(else) ).
w5 :- ( q(_) -> $, p(_) ; true ).
w6 :- ( q(_) -> $ ; true ), p(_).
w7 :- ( fail ; $ ), p(_).
w8 :- ( $ ; true ), q(_).
w9 :- once(($, p(_))).
w10 :- G = ($, p(_)), once(G).
x1 :- call(($, p(_))).
x2 :- findall(X, ($, p(X)), L), writeln(L).
x3 :- catch(($, p(_)), E, (shown(E))).
x4 :- call(($, fail)).
x10 :- forall(member(X, [1]), ($, p(X))).
x6 :- G = ($, p(_)), G.
x7 :- G = ($, fail), G.
x9 :- ignore(($, fail)).
y1 :- $, y1b(_).
y1b(X) :- X = 1.
y1b(2).
y2 :- $, y2b.
y2b :- q(_), !, p(_).
y3 :- $, y3b.
y3b :- p(X), !, X > 1.
y4 :- p(X), $, X > 0.
y5 :- $, true, !.
y6 :- y6b(X), writeln(X).
y6b(X) :- $, p(X).
z1 :- call($).
z2 :- once($).
z3 :- G = $, G.
z4 :- findall(x, $, L), writeln(L).
z5 :- call(($, p(_))), true.
z6 :- z6a.
z6a :- $, catch(z6b, _, true).
z6b :- $, z6c.
z6c :- fail.
z7 :- z7a.
z7a :- $, once(z7b).
z7b :- $, z6c.
z8 :- z8a.
z8a :- $, catch(z8b, _, true).
z8b :- z8c.
z8c :- $, p(_).
z9 :- $, q(_), z9b.
z9b :- $, fail.
o1 :- $, o1b.
o1b :- p(_), o1c.
o1c :- $, fail.
o2 :- \+ ($, true).
o3 :- forall(p(X), ($, X > 0)).
o4 :- forall(p(X), ($, X > 1)).
o5 :- catch(($, fail), E, (shown(E))).
o6 :- $, catch(f1, _, true).
o7 :- $, p(_), call(($, p(_))).
o8 :- $, catch(p(_), E, (shown(caught(E)))).
o9 :- $, p(_), catch(p(_), E, (shown(caught(E)))), writeln(after).
%% neither `$' nor its exit is an inference
o10 :- $, statistics(inferences, I0), statistics(inferences, I1), D is I1 - I0, writeln(D).
o11 :- statistics(inferences, I0), $, statistics(inferences, I1), D is I1 - I0, writeln(D).
o12 :- statistics(inferences, I0), a2, statistics(inferences, I1), D is I1 - I0, writeln(D).
%% a guard a transparent last call took off leaves the choice points it
%% made where they were
o13 :- findall(X, ($, setup_call_cleanup(true, p(X), true)), L), writeln(L).
o14 :- findall(X, o14b(X), L), writeln(L).
o14b(X) :- $, setup_call_cleanup(true, p(X), true).
o15 :- findall(X-Y, (o15b(X), p(Y)), L), writeln(L).
o15b(X) :- $, once(p(X)).
%% a catch's goal that leaves no choice point raises nothing inside it
o16 :- $, p(_), catch(q(_), E, shown(caught(E))).
%% the guard on across a collection
o17 :- $, numlist(1, 3000, _), p(_).
%% neither `$', the exit nor a disjunction's hidden arm is an inference:
%% each body costs what the same body without `$' costs
cnt(G, D) :- statistics(inferences, I0), G, statistics(inferences, I1), D is I1 - I0.
o18b :- $, (q(_), ! ; true).
o19b :- (q(_), ! ; true).
o20b :- $, o20c.
o20c :- q(_).
o21b :- o20c.
o18 :- cnt(o18b, A), cnt(o19b, B), cnt(o20b, C), cnt(o21b, D), A == B, C == D.
%% a last call into a clause whose body is a comparison it runs as it is
%% entered, or whose disjunction an environment would run
t33 :- $, u33(0).
u33(X) :- X > 0.
t34 :- $, u34.
u34 :- q(_), (fail ; p(_)).
t35 :- $, u35.
u35 :- q(_), (q(_) -> p(_) ; true).
%% ...and a builtin an environment would run in place, the disjunction's
%% right arm its last call
t36 :- $, u36.
u36 :- q(_), (fail ; atom_length(abc, 4)).
t37 :- $, u37.
u37 :- q(X), (fail ; X > 1).
%% =/2 with a variable is compiled in place, of two compounds a call
t40(X) :- $, X = 1.
t41(X, Y) :- $, f(X) = f(Y).

%% ---- a recursion each turn of which is guarded -------------------------
len([], 0).
len([_|T], N) :- $, len(T, N0), N is N0 + 1.
r1 :- numlist(1, 2000, L), len(L, N), writeln(N).
cnt(0) :- !.
cnt(N) :- $, N1 is N - 1, cnt(N1).
r2 :- cnt(5000), writeln(done).

runs([a1,a2,a3,a4,a5,a6,a7,a8,a9,b1,b2,b3,b4,b5,b6,b7,b8,b9,c1,c2,c3,c5,c7,c8,c9,
      d1,d2,d3,d4,d5,d6,d7,d8,d9,e1,e2,e3,e4,e5,e6,e7,e8,e9,g5,g6,g7,k1,k2,k3,k5,k6,k7,
      m4,m5,m6,m7,m8,m9,n1,n2,n3,n5,h1,h2,h3,h4,h5,h6,h7,h8,h9,i1,i3,i4,i5,i6,i7,i8,i9,
      j1(a),j1(1),j2,j4,j6(1),j6(2),j7,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,x1,x2,x3,x4,x10,x6,x7,x9,
      y1,y2,y3,y4,y5,y6,z1,z2,z3,z4,z5,z6,z7,z8,z9,o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13,o14,o15,o16,o17,o18,t33,t34,t35,t36,t37,t40(2),t41(1,2),r1,r2]).

main :-
    warm,
    runs(Rs),
    forall(member(R, Rs), try(R)),
    %% what a message says of each kind, swipl's printer and message_to_string/2
    forall(( member(W, [fail, nondet]), member(K, [guard, guard_in_caller]) ),
           ( message_to_string(error(determinism_error(foo/0, det, W, K), _), S),
             writeln(S) )),
    catch(a3, E1, true), print_message(error, E1),
    catch(a1, E2, true), print_message(error, E2).

try(G) :-
    catch(( G -> shown(yes(G)) ; shown(no(G)) ), E, shown(caught(E))).

%% a term, its variables written `_'
shown(T) :-
    copy_term(T, C), term_variables(C, Vs), maplist(=('_'), Vs),
    print(C), nl.
