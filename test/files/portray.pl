%  print/1, print/2, format's ~p and write_term/2's portray(true) and
%  portray_goal(G), with the portray/1 hook, as swipl 9.0.4's pl-write.c
%  calls it. Run by BOTH systems, output compared byte for byte.

:- set_prolog_flag(double_quotes, codes).
:- dynamic portray/1, seen/1.

portray(x) :- write(xx).
portray(y) :- write(-1).
portray(p) :- write('(a)').
portray(q) :- write(-).
portray(z) :- assertz(seen(z)), fail.
portray(w) :- write(partial), fail.
portray(v) :- write('9'), fail.
portray(t) :- write(before), throw(boom).
portray(t2) :- write(after), throw(boom2).
portray(b(X)) :- X = 1, write(b1).
portray(n) :- true.
portray(f(X)) :- X == q, write(fq).
portray(s(X)) :- X = 1, fail.
portray('$VAR'(7)) :- write(var7).
portray([]) :- write(nil).
portray(S) :- string(S), write(str).
portray(k(A)) :- write('k<'), print(A), write('>').
portray(1.5) :- write(onehalf).
portray(nest(T)) :- write_term(T, [portray_goal(pg2)]).
portray(deep(T)) :- print(T).
portray(deepn(N)) :- N1 is N + 1, print(deepn(N1)).
portray(deepf(N)) :- N1 is N + 1, format("~p", [deepf(N1)]).
portray(deepw(N)) :- N1 is N + 1, write_term(deepw(N1), [portray(true)]).

pg2(T, O) :- T == x, write(O).
pg3(T, _) :- T == t, throw(pgboom).
pg4(T, O) :- write(O), write('/'), write(T), nl, fail.
pg5(T, _) :- T == x, write(pg5).

p(T) :- print(T), write('|'), nl.
w(T, Os) :- write_term(T, Os), write('|'), nl.

%  each non-variable subterm asked, the term first: arguments, elements,
%  a tail that is no list, operands, a curly term's, a number, a string
t(1) :- p(f(x, a)).
t(2) :- p([x, a | x]).
t(3) :- p(1+x).
t(4) :- p(x+x).
t(5) :- p(a mod x).
t(6) :- p(-(x)).
t(7) :- p({x}).
t(8) :- p(f(q)).
t(9) :- p(f(n, n)).
t(10) :- string_concat(ab, c, S), p(S), p(f(S)).
t(11) :- p(1.5).
t(12) :- p(- 1.5).
t(13) :- p(1 - 1.5).
t(14) :- p(a = x).
t(15) :- p(x = a).
t(16) :- p((f(x) :- x)).
t(17) :- p((a, x)).
t(18) :- p([x|y]).
t(19) :- p(f(x)-a).
t(20) :- p(\+ x).
t(21) :- p('$VAR'(x)).
t(22) :- p(f('A')).
t(23) :- p('hello world').
%  the list's end is never asked, a `[]' anywhere else is
t(24) :- p([]).
t(25) :- p([a]).
t(26) :- p(h([])).
t(27) :- p([[]]).
%  '$VAR'(N) is asked before numbervars writes it
t(28) :- p('$VAR'(7)).
t(29) :- p('$VAR'(8)).
%  no gap before portrayed text, as each write of swipl's starts afresh
t(30) :- p(1+y).
t(31) :- p(1-y).
t(32) :- p(-(y)).
t(33) :- p(- (-(y))).
t(34) :- p(a- y).
t(35) :- p(a:y).
t(36) :- p(y=y).
t(37) :- p([y, -y]).
t(38) :- p({y}).
t(39) :- p(f(y)).
t(40) :- p(dynamic x).
t(41) :- p(- p).
t(42) :- p(a- p).
t(43) :- p(p:p).
t(44) :- p((x :- y, x)).
t(45) :- p(- (x, y)).
t(46) :- p([- x]).
t(47) :- p(1 - x - y).
t(48) :- p(x - (y - x)).
t(49) :- p(x - (- 1)).
t(50) :- p(- (1) - x).
%  but the spaces swipl writes whatever follows stay: a space before an
%  infix operator is one after it too, next_argument's after a comma
t(51) :- p(a mod y).
t(52) :- p(x mod y).
t(53) :- p(x mod a).
t(54) :- p(+- = y).
t(55) :- p(+- = x).
t(56) :- w((a,x), [portray(true), spacing(next_argument)]).
t(57) :- w((a,y), [portray(true), spacing(next_argument)]).
t(58) :- w('|'(a,y), [portray(true), spacing(next_argument)]).
t(59) :- p('|'(x,y)).
%  and after portrayed text the next token's gap is as ever
t(60) :- p(q-a).
t(61) :- p(a-q).
t(62) :- p(q-q).
t(63) :- p(- q).
t(64) :- p(- (- x)).
t(65) :- p(\+ (- x)).
%  a portray that fails: its text stays, the term after it, a gap between
t(66) :- p(g(w)).
t(67) :- p(w+a).
t(68) :- p(f(w)).
t(69) :- p(1-w).
t(70) :- p(- w).
t(71) :- p(- v).
t(72) :- p([w]).
%  one that has no clause for the term: the term as ever
t(73) :- p(f(z, z)), findall(Z, seen(Z), L), p(L).
t(74) :- p(-(z)).
%  its bindings undone, its other work kept
t(75) :- S = s(V), with_output_to(codes(_), print(S)), ( var(V) -> write(unbound) ; write(bound) ), nl.
%  nested: print/1 inside portray/1, and a write of portray_goal inside
t(76) :- p(k(x)).
t(77) :- p(k(k(x))).
t(78) :- p(1 - k(x)).
t(79) :- p(f(nest(g(x)))).
t(80) :- p(deep(f(x, deep(x)))).
%  the outer write's own state after a nested one: its names, its depth
t(81) :- w(f(X, k(x), X), [variable_names(['X'=X]), portray(true)]).
t(82) :- w(f(k(x), g(h(i(j)))), [portray(true), max_depth(3)]).
t(83) :- w(f(nest(x), h(x)), [portray(true), quoted(true)]).
%  a throw: what came before stays, portray's own text too, and nothing more
t(84) :- p(g(a, t, b)).
t(85) :- p([a, t, b]).
t(86) :- p(1 + t).
t(87) :- p([x|t]).
t(88) :- p(f(k(t))).
t(89) :- p(k(k(t))).
t(90) :- p(- t).
t(91) :- p(a - t - b).
t(92) :- p(f(a - t, b)).
t(93) :- format("ab ~p cd~n", [f(t)]).
t(94) :- with_output_to(codes(C), catch(print(f(t)), E, true)), atom_codes(A, C), writeq(A-E), nl.
t(95) :- w(f(t), [portray_goal(pg3)]).
%  write_term/2's portray(true), with numbervars(true) unless it says
t(96) :- w(f(x), [portray(true)]).
t(97) :- w('$VAR'(8), [portray(true)]).
t(98) :- w('$VAR'(8), [portray(true), numbervars(false)]).
t(99) :- w(f(x), [portray(false)]).
t(100) :- w(f(x), [portray(1)]).
t(101) :- w(f('A b', x), [portray(true), quoted(true)]).
%  portray_goal(G): call(G, Term, Options), the options the write's with
%  every priority(_) dropped and the term's priority last
t(102) :- w(f(x), [portray_goal(pg2)]).
t(103) :- w(f(x), [portray_goal(pg2), quoted(true)]).
t(104) :- w(f(x, 1+x, [x], {x}, -x, - (x)), [portray_goal(pg2)]).
t(105) :- w(f(x), [portray_goal(pg2), max_depth(3), spacing(next_argument)]).
t(106) :- w(f(x), [priority(100), portray_goal(pg2), quoted(true), priority(50)]).
t(107) :- w(x, [portray_goal(pg2), priority(100)]).
t(108) :- w(x, [portray_goal(pg2)]).
t(109) :- w(f(x), [portray_goal(pg2), portray(false)]).
t(110) :- w(f(x), [portray(true), portray_goal(pg2)]).
t(111) :- w([x], [portray_goal(pg4)]).
t(112) :- w(f(x) - g, [portray_goal(pg4), max_depth(2)]).
t(113) :- w('$VAR'(1), [portray_goal(pg4)]).
t(114) :- string_concat(s, '', S), w(S, [portray_goal(pg4)]).
t(115) :- w(f(x, y), [portray_goal(pg5)]).
t(116) :- catch(w(f(x), [portray_goal(nosuch)]), error(F, _), (print(F), nl)).
%  ~p, ~W and print/2; and writes that portray nothing
t(117) :- format("~p and ~w and ~q~n", [f(x), f(x), f(x)]).
t(118) :- format("~W~n", [f(x), [portray(true)]]).
t(119) :- format("~W~n", [f(x), [portray_goal(pg5)]]).
t(120) :- format(user_output, "~p ~a~n", [f(x), x]), format(atom(A), "~p", [g(x)]), writeq(A), nl.
t(121) :- writeq(f(x)), write(' '), write(f(x)), write(' '), write_canonical(f(x)), write(' '),
          write_term(f(x), []), nl.
t(122) :- portray_clause(f(x)).
%  a depth limit is asked before portray/1
t(123) :- w(g(h(i(x))), [portray(true), max_depth(2)]).
t(124) :- w([x, x, x, x], [portray(true), max_depth(3)]).
%  a cyclic term, in its factors
t(125) :- X = f(X, x), p(X).
%  with no clause for portray/1 nothing is asked
t(126) :- findall(H-B, clause(portray(H), B), L), retractall(portray(_)), p(f(x)),
          w(f(x), [portray(true)]), forall(member(H-B, L), assertz((portray(H) :- B))), p(f(x)).

%  no deeper than swipl's MAX_PORTRAY_NESTING, 100: past it the innermost
%  write raises resource_error(portray_nesting), in its own context
% cocolint: C2 -- the context printed, a builtin's both systems name alike
t(127) :- catch(print(deepn(0)), error(F, context(C, _)), (write(F-C), nl)).
% cocolint: C2 -- the same, of format/2
t(128) :- catch(format("~p", [deepf(0)]), error(F, context(C, _)), (write(F-C), nl)).
% cocolint: C2 -- the same, of write_term/2
t(129) :- catch(write_term(deepw(0), [portray(true)]), error(F, context(C, _)), (write(F-C), nl)).

%  the depth limit cuts a term portray/1 would have written, the goal of
%  portray_goal(G) too
t(130) :- w(f(x), [portray(true), max_depth(1)]).
t(131) :- w(f(x), [portray_goal(pg2), max_depth(1)]).
%  a cyclic term is asked once, in its factors: none of its goals is asked
%  of the term unwound
t(132) :- retractall(seen(_)), X = f(X, z), p(X), findall(Z, seen(Z), L), length(L, N), write(N), nl.
%  a throw inside ~W: the text before it stays, and the ball is raised
t(133) :- format("ab ~W cd~n", [f(t), [portray(true)]]).
t(134) :- format("ab ~W cd~n", [g(x, t, y), [portray(true), quoted(true)]]).
%  a throw inside a bracketed operand: nothing after it, the closing
%  brackets of the operators around it neither
t(135) :- p(f((:- t))).
t(136) :- p(- (:- t)).
t(137) :- p(\+ (a, t)).
t(138) :- p(f((:- x), (:- t), y)).
t(139) :- p([(:- t), x]).
t(140) :- p((- t) + a).
%  ... where the term unwound would ask a goal at each level: a part
%  before the cycle's (the writer walks its first argument down first,
%  so t(132)'s z is no part a level asks), and a list's element; a depth
%  limit cuts the term first, as swipl's
t(141) :- retractall(seen(_)), X = f(z, X), p(X), findall(Z, seen(Z), L), length(L, N), write(N), nl.
t(142) :- retractall(seen(_)), X = [z|X], p(X), findall(Z, seen(Z), L), length(L, N), write(N), nl.
t(143) :- retractall(seen(_)), X = f(z, X), w(X, [portray(true), max_depth(5)]),
          findall(Z, seen(Z), L), length(L, N), write(N), nl.
%  a write a goal stopped asks no goal after it: no z is seen, and the
%  ball is the first goal's
t(144) :- retractall(seen(_)), catch(p(g(t, z)), E, true), nl,
          findall(Z, seen(Z), L), length(L, N), write(E-N), nl.
t(145) :- catch(p(g(t, t2)), E, true), nl, write(E), nl.
t(146) :- retractall(seen(_)), catch(p([t, z, z]), E, true), nl,
          findall(Z, seen(Z), L), length(L, N), write(E-N), nl.
t(147) :- retractall(seen(_)), catch(p(t - z), E, true), nl,
          findall(Z, seen(Z), L), length(L, N), write(E-N), nl.
%  a goal that succeeded leaves no binding behind it
t(148) :- p(f(b(Y))), ( var(Y) -> write(unbound) ; write(bound(Y)) ), nl.
t(149) :- w(f(b(V)), [portray(true)]), ( var(V) -> write(unbound) ; write(bound(V)) ), nl.
t(150) :- format("~p~n", [k(b(W))]), ( var(W) -> write(unbound) ; write(bound(W)) ), nl.

main :- forall(( between(1, 150, N), clause(t(N), _) ),
               ( write(N), write(': '), ( catch(t(N), E, (nl, print(caught(E)), nl)) -> true ; write(failed), nl ) )).
