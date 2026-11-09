%  A cyclic term under write_term/2's max_depth(D) past 1024 levels, and a
%  write too deep for the C stack, as swipl 9.0.4's writeTopTerm() writes
%  them (cocolog 3.59.0). With max_depth set, and cycles not false, a term
%  is written as it stands, cyclic or not: the tree a cyclic term stands
%  for, to the limit. A write that runs out of C stack raises
%  error(resource_error(c_stack), context(system:P/N, _)), P/N the builtin
%  that wrote -- portray_clause/1's and listing/1's write_term/3, written
%  over it in Prolog -- and binds nothing. Run by BOTH SWI-Prolog and
%  cocolog, output compared byte for byte.
%
%  Through 3.58.2 a cyclic term met past 1024 levels under a depth limit
%  was written in its factors, `@(_G1,[_G1=f(_G1)])', and a deep tree, or
%  a deep limit's cyclic term, was a SIGSEGV past some 45 000 levels.
%
%  What is held: each write's length and its first and last 30
%  characters, and for a write that runs out its error alone, after the
%  write is caught with nothing of it shown. A write is made at 5 000
%  levels or less, a write that runs out at 200 000: swipl's C stack holds
%  some 25 000 of its writer's levels, cocolog's some 45 000, on 8 MB.
%  Not held: what a stream holds of a write that ran out, which in swipl
%  is what its C stack had room for and in cocolog none (COMPAT.md); the
%  C stack's size, the machine's; a variable's name, `_123' in swipl and
%  `_G123' in cocolog; and a portray goal asked at each of 200 000 levels,
%  which swipl does not end in five minutes (test/cyclic.pl holds it).

main :- forall(member(S, [cyclic, trees, portray, refused, stack]), run(S)).

run(S) :- write(S), nl, forall(nth1_c(S, N, G), (write(N), write(': '), case(G), nl)).

nth1_c(S, N, G) :- findall(G0, c(S, G0), Gs), nth1(N, Gs, G).

case(G) :- catch(( G -> true ; write(failed) ), E, report(E)).

% cocolint: C2 -- the context printed, of errors both systems name alike
report(error(F, context(P, _))) :- !, write('error '), print(F), write(' in '), writeq(P).
report(error(F, _)) :- !, write('error '), print(F).
report(E) :- write('caught '), print(E).

%  a write's text: its length, and its first and last 30 characters
show(G) :-
    with_output_to(string(S), G),
    string_length(S, N), K is min(N, 30),
    sub_string(S, 0, K, _, P), sub_string(S, _, K, 0, Q),
    format("~d ~s ... ~s", [N, P, Q]).

%  a tree N deep: f(f(...)), [[...]], a+(a+(...))
deep(0, a) :- !.
deep(N, f(T)) :- N1 is N - 1, deep(N1, T).

nest(0, []) :- !.
nest(N, [T]) :- N1 is N - 1, nest(N1, T).

ops(0, a) :- !.
ops(N, a+T) :- N1 is N - 1, ops(N1, T).

%  a portray goal that writes the one term it knows
pg(zz, _) :- write('ZZ').

:- dynamic dp/1, dq/1, dr/1.

%  ---- a cyclic term under a limit past 1024: the tree, to the limit
c(cyclic, (X = f(X), show(write_term(X, [max_depth(1025)])))).
c(cyclic, (X = f(X), show(write_term(X, [max_depth(5000)])))).
c(cyclic, (X = f(a, X), show(write_term(X, [max_depth(3000)])))).
c(cyclic, (X = [a|X], show(write_term(X, [max_depth(3000)])))).
c(cyclic, (X = [X], show(write_term(X, [max_depth(2000)])))).
c(cyclic, (X = -X, show(write_term(X, [max_depth(2000)])))).
c(cyclic, (X = a+X, show(write_term(X, [max_depth(2000)])))).
c(cyclic, (X = (X:-a), show(write_term(X, [max_depth(2000)])))).
c(cyclic, (X = {X}, show(write_term(X, [max_depth(2000)])))).
c(cyclic, (X = f(Y), Y = g(X), show(write_term(X, [max_depth(1500)])))).
c(cyclic, (X = 'a b'(X), show(write_term(X, [max_depth(2000), quoted(true)])))).
c(cyclic, (X = f(X), show(write_term(X, [max_depth(1500), cycles(true)])))).
c(cyclic, (X = f(X), show(format("~W", [X, [max_depth(3000)]])))).
%  no limit: the factors, as before
c(cyclic, (X = f(a, X), show(print(X)))).

%  ---- a deep tree, written, and under a limit
c(trees, (deep(5000, T), show(write(T)))).
c(trees, (deep(5000, T), show(write_term(T, [max_depth(3000)])))).
c(trees, (deep(5000, T), show(print(T)))).
c(trees, (nest(5000, T), show(write(T)))).
c(trees, (ops(5000, T), show(writeq(T)))).
c(trees, (deep(5000, T), show(format("~q", [T])))).
c(trees, (deep(5000, T), term_to_atom(T, A), atom_length(A, N), write(N))).

%  ---- a portray goal under a limit past 1024
c(portray, (X = f(zz, X), show(write_term(X, [max_depth(1500), portray_goal(pg)])))).
c(portray, (X = [zz|X], show(write_term(X, [max_depth(1500), portray_goal(pg)])))).

%  ---- cycles(false) under a limit refuses the cyclic term
c(refused, (X = f(X), write_term(X, [max_depth(2000), cycles(false)]))).

%  ---- a write that runs out of C stack
c(stack, (deep(200000, T), with_output_to(string(_), write(T)))).
c(stack, (deep(200000, T), with_output_to(string(_), print(T)))).
c(stack, (deep(200000, T), with_output_to(string(_), writeq(T)))).
c(stack, (deep(200000, T), with_output_to(string(_), write_canonical(T)))).
c(stack, (deep(200000, T), with_output_to(string(_), writeln(T)))).
c(stack, (deep(200000, T), with_output_to(string(_), write_term(T, [quoted(true)])))).
c(stack, (X = f(X), with_output_to(string(_), write_term(X, [max_depth(200000)])))).
c(stack, (deep(200000, T), with_output_to(string(_), format("~w", [T])))).
c(stack, (deep(200000, T), format(atom(_), "~q", [T]))).
c(stack, (deep(200000, T), format(string(_), "~p", [T]))).
c(stack, (deep(200000, T), format(codes(_), "~k", [T]))).
c(stack, (X = f(X), format(atom(_), "~W", [X, [max_depth(200000)]]))).
c(stack, (deep(200000, T), term_to_atom(T, _))).
c(stack, (deep(200000, T), term_string(T, _))).
c(stack, (deep(200000, T), with_output_to(string(_), portray_clause(T)))).
c(stack, (nest(200000, T), with_output_to(string(_), write(T)))).
c(stack, (ops(200000, T), with_output_to(string(_), write(T)))).
c(stack, (deep(200000, T), assertz(dp(T)), with_output_to(string(_), listing(dp/1)))).
%  a cyclic term with a deep tree in it: its factors' write runs out
c(stack, (deep(200000, T), X = g(T, X), with_output_to(string(_), write(X)))).
c(stack, (deep(200000, T), X = [T|X], format(atom(_), "~q", [X]))).
%  it binds nothing, and the next write is whole
c(stack, (deep(200000, T), catch(term_to_atom(T, A), _, true), ( var(A) -> write(unbound) ; write(bound) ))).
c(stack, (deep(200000, T), catch(with_output_to(string(_), write(T)), _, true), write(after(f(g(x)))))).
c(stack, (X = f(X), catch(with_output_to(string(_), write_term(X, [max_depth(200000)])), _, true),
          show(print(X)))).
c(stack, (deep(200000, T), X = g(T, X), catch(with_output_to(string(_), write(X)), _, true),
          Y = h(Y), print(Y))).
c(stack, (deep(200000, T), catch(with_output_to(string(_), portray_clause(T)), _, true),
          portray_clause(after(f(g(x)))))).
c(stack, (deep(200000, T), assertz(dq(T)), catch(with_output_to(string(_), listing(dq/1)), _, true),
          assertz(dr(x)), listing(dr/1))).
