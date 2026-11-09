%  A term too deep for the C stack to read, and a chain of operators, as
%  swipl 9.0.4's reader reads them (cocolog 3.60.0). swipl's complex_term()
%  reads a term's operators with a stack of its own and calls itself for
%  each bracket's term, its C stack guarded: a bracket some 17 000 deep
%  raises error(resource_error(c_stack), context(P, _)), P the builtin that
%  read -- read_clause/3 in a load, which ends the load there with the
%  clauses before it kept -- and a chain of 200 000 operators, prefix or
%  infix, reads. Run by BOTH SWI-Prolog and cocolog, output compared byte
%  for byte.
%
%  Through 3.59.0 each operator's operand was a call of cocolog's reader,
%  and a chain of some 15 000 prefix operators or 20 000 `,', or a bracket
%  some 15 000 deep, was a SIGSEGV.
%
%  What is held: what a read gives, counted by a walk that recurses on
%  nothing, or its error alone -- a syntax error's id and place, never its
%  text of 400 000 characters. A read is made at 5 000 levels of brackets,
%  a read that runs out at 200 000: swipl's C stack holds some 16 800 of
%  its reader's levels on 8 MB, and cocolog's some 14 000 of `f(' and
%  18 400 of `[', `(' or `{'. Not held: the C stack's size, the machine's;
%  a variable's name, `_123' in swipl and `_G123' in cocolog.

:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

main :- forall(member(S, [texts, chains, errors, loads, streams]), run(S)).

run(S) :- write(S), nl, forall(nth1_c(S, N, G), (write(N), write(': '), case(G), nl)).

nth1_c(S, N, G) :- findall(G0, c(S, G0), Gs), nth1(N, Gs, G).

case(G) :- catch(( G -> true ; write(failed) ), E, report(E)).

report(error(syntax_error(Id), string(_, Pos))) :- !,
    write('syntax '), print(Id), write(' at '), print(Pos).
report(error(syntax_error(Id), file(_, L, LP, C))) :- !,
    write('syntax '), print(Id), write(' at '), print(L/LP/C).
% cocolint: C2 -- the context printed, of errors both systems name alike
report(error(F, context(P, _))) :- !, write('error '), print(F), write(' in '), writeq(P).
report(error(F, _)) :- !, write('error '), print(F).
report(E) :- write('caught '), print(E).

%  the text of N brackets about MID, and of N operands joined by OP
nest(N, Open, Mid, Close, A) :-
    length(Os, N), maplist(=(Open), Os), atomic_list_concat(Os, A1),
    length(Cs, N), maplist(=(Close), Cs), atomic_list_concat(Cs, A2),
    atomic_list_concat([A1, Mid, A2], A).

chain(N, Op, A) :- length(L, N), maplist(=(a), L), atomic_list_concat(L, Op, A).

prefix(N, Op, A) :- length(L, N), maplist(=(Op), L), atomic_list_concat(L, A0), atom_concat(A0, a, A).

%  how deep a term is down its first argument, how long a chain is down
%  its last: walks that recurse on nothing
down(T, N0, N) :- compound(T), !, arg(1, T, A), N1 is N0 + 1, down(A, N1, N).
down(_, N, N).

right(T, Op, N0, N) :- compound(T), functor(T, Op, 2), !, arg(2, T, R), N1 is N0 + 1, right(R, Op, N1, N).
right(_, _, N0, N) :- N is N0 + 1.

left(T, Op, N0, N) :- compound(T), functor(T, Op, 2), !, arg(1, T, L), N1 is N0 + 1, left(L, Op, N1, N).
left(_, _, N0, N) :- N is N0 + 1.

%  what a read gave: its functor -- `list' for a list, whose functor is
%  '[|]' in swipl and '.' in cocolog -- and how deep it is down its first
%  argument
said(T) :- ( T = [_|_] -> write(list) ; compound(T) -> functor(T, F, A), writeq(F/A) ; writeq(T) ),
    write(' '), down(T, 0, D), write(D).

%  a file of three clauses, the second TEXT, the others aK(1) and zK(2): a
%  predicate of its own each, so no load warns of clauses apart or redefined
three(F, K, Text) :-
    atom_concat(a, K, A), atom_concat(z, K, Z),
    open(F, write, S), format(S, "~w(1).~n~w.~n~w(2).~n", [A, Text, Z]), close(S).

lines(F, Ls) :- open(F, write, S), forall(member(L, Ls), (write(S, L), nl(S))), close(S).

the_a(K) :- atom_concat(a, K, A), atom_concat(z, K, Z),
    findall(X, catch(call(A, X), _, fail), Xs), findall(X, catch(call(Z, X), _, fail), Ys),
    write(A = Xs), write(' '), write(Z = Ys).

%  ---- texts: each text builder at 5 000 brackets and at 200 000 ----------

c(texts, (nest(5000, 'f(', x, ')', A), term_to_atom(T, A), said(T))).
c(texts, (nest(200000, 'f(', x, ')', A), term_to_atom(_, A))).
c(texts, (nest(5000, '[', x, ']', A), atom_to_term(A, T, _), said(T))).
c(texts, (nest(200000, '[', x, ']', A), atom_to_term(A, _, _))).
c(texts, (nest(5000, '(', x, ')', A), term_string(T, A), said(T))).
c(texts, (nest(200000, '(', x, ')', A), term_string(_, A))).
c(texts, (nest(5000, '{', x, '}', A), read_term_from_atom(A, T, []), said(T))).
c(texts, (nest(200000, '{', x, '}', A), read_term_from_atom(A, _, []))).
c(texts, (nest(200000, 'g(a, ', x, ')', A), term_string(_, A, []))).
c(texts, (nest(2000, 'f([({', x, '})])', A), term_to_atom(T, A), said(T))).
c(texts, (nest(100000, 'f([({', x, '})])', A), term_to_atom(_, A))).
c(texts, (nest(5000, '- (', x, ')', A), term_to_atom(T, A), said(T))).
c(texts, (nest(200000, '- (', x, ')', A), term_to_atom(_, A))).

%  ---- chains: 200 000 operators, infix and prefix ------------------------

c(chains, (chain(200000, ',', A), term_to_atom(T, A), right(T, ',', 0, N), write(N))).
c(chains, (chain(200000, ';', A), term_to_atom(T, A), right(T, ';', 0, N), write(N))).
c(chains, (chain(200000, '->', A), term_to_atom(T, A), right(T, '->', 0, N), write(N))).
c(chains, (chain(200000, ' | ', A), term_to_atom(T, A), right(T, ';', 0, N), write(N))).
c(chains, (chain(200000, ':', A), term_to_atom(T, A), right(T, ':', 0, N), write(N))).
c(chains, (chain(200000, '^', A), term_to_atom(T, A), right(T, '^', 0, N), write(N))).
c(chains, (chain(200000, '+', A), term_to_atom(T, A), left(T, '+', 0, N), write(N))).
c(chains, (chain(200000, ' * ', A), term_to_atom(T, A), left(T, '*', 0, N), write(N))).
c(chains, (prefix(200000, '- ', A), term_to_atom(T, A), said(T))).
c(chains, (prefix(200000, '\\+ ', A), term_to_atom(T, A), said(T))).
c(chains, (prefix(100000, '- a + ', A), term_to_atom(T, A), left(T, '+', 0, N), write(N))).
c(chains, (chain(100000, ' ; b -> ', A), term_to_atom(T, A), right(T, ';', 0, N), write(N))).
c(chains, (chain(100000, ', - ', A), term_to_atom(T, A), right(T, ',', 0, N), write(N))).
c(chains, (chain(200000, ',', A0), atomic_list_concat(['f((', A0, '), b)'], A), term_to_atom(T, A),
           arg(1, T, C), right(C, ',', 0, N), write(N))).
c(chains, (chain(100, ',', A0), atomic_list_concat(['(', A0, ')'], C), nest(2000, 'f(', C, ')', A),
           term_to_atom(T, A), said(T))).
c(chains, (chain(200000, ',', A0), atom_concat(A0, ' = b', A), term_to_atom(T, A), right(T, ',', 0, N),
           write(N))).

%  ---- errors: a syntax error at the end of a long chain ------------------

c(errors, (chain(200000, ',', A0), atom_concat(A0, ' ;', A), term_to_atom(_, A))).
c(errors, (chain(200000, ',', A0), atom_concat(A0, ')', A), term_to_atom(_, A))).
c(errors, (chain(200000, ',', A0), atom_concat(A0, ' = b = c', A), term_to_atom(_, A))).
c(errors, (prefix(200000, '- ', A0), atom_concat(A0, ' )', A), term_to_atom(_, A))).
c(errors, (prefix(200000, '\\+ ', A0), atom_concat(A0, ' :- b', A), term_to_atom(_, A))).
c(errors, (chain(200000, ' ; ', A0), atom_concat(A0, ' a', A), term_to_atom(_, A))).
c(errors, (nest(200000, 'f(', x, '', A), term_to_atom(_, A))).
c(errors, (nest(5000, 'f(', x, '', A), term_to_atom(_, A))).

%  ---- loads: a clause too deep ends the load, a long chain reads ---------

c(loads, (nest(200000, 'deep1(f(', x, '))', T), three('d1.pl', 1, T), consult(d1))).
c(loads, the_a(1)).
c(loads, (catch(deep1(_), error(E, _), true), print(E))).
c(loads, (nest(5000, 'deep2(f(', x, '))', T), three('d2.pl', 2, T), consult(d2), the_a(2), write(' '),
          deep2(X), said(X))).
c(loads, (length(L, 200000), maplist(=(true), L), atomic_list_concat(L, ', ', B),
          atom_concat('p3 :- ', B, T), three('d3.pl', 3, T), consult(d3), the_a(3), write(' '), p3,
          write(p3))).
c(loads, (prefix(200000, '- ', A0), atomic_list_concat(['q4(', A0, ')'], T), three('d4.pl', 4, T),
          consult(d4), the_a(4), write(' '), q4(X), said(X))).
c(loads, (nest(200000, 'deep5(f(', x, '))', T), three('inner.pl', 5, T),
          lines('outer.pl', ['b5(1).', ':- include(inner).', 'b5(2).']), consult(outer))).
c(loads, (findall(X, catch(b5(X), _, fail), Xs), write(b5 = Xs), write(' '), the_a(5))).
c(loads, (nest(200000, 'deep7(f(', x, '))', T0), atom_concat(T0, '.', T),
          lines('d7.pl', [':- initialization((write(init_ran), write(\' \'))).',
                          ':- write(directive_ran), write(\' \').', 'a7(1).', T, 'z7(2).']),
          consult(d7))).
c(loads, the_a(7)).

%  ---- streams: the stream readers, the stream after the clause -----------

c(streams, (nest(200000, 'deep(f(', x, '))', T), three('s.pl', s, T), open('s.pl', read, S),
            nb_setval(rd_s, S), read_term(S, T1, []), print(T1))).
c(streams, (nb_getval(rd_s, S), read_term(S, _, []))).
c(streams, (nb_getval(rd_s, S), read_term(S, T, []), print(T))).
c(streams, (nb_getval(rd_s, S), read(S, T), print(T), close(S))).
c(streams, (open('s.pl', read, S), read(S, _), catch(read(S, _), E, (close(S), throw(E))))).
c(streams, (open('s.pl', read, S), read(S, _),
            catch(read_term(S, _, [subterm_positions(_)]), E, (close(S), throw(E))))).
c(streams, (open('s.pl', read, S), read(S, _), current_input(I), set_input(S),
            catch(read(_), E, (set_input(I), close(S), throw(E))))).
c(streams, (open('s.pl', read, S), read(S, _), current_input(I), set_input(S),
            catch(read_term(_, []), E, (set_input(I), close(S), throw(E))))).
c(streams, (chain(200000, ',', A), lines('c.pl', [A, '.']), open('c.pl', read, S),
            read_term(S, T, [subterm_positions(P)]), close(S), right(T, ',', 0, N), write(N), write(' '),
            P = term_position(F, To, OF, OT, _), print(F-To-OF-OT))).
