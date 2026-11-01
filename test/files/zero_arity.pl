%  Compounds of no arguments, `f()', as swipl 7 has them.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  Through 3.11.0 cocolog read `f()' as a syntax error (cannot_start_term)
%  and had no such term: compound_name_arity(T, f, 0) failed. swipl 7 makes
%  one, a compound whose functor is the name and 0 -- no atom, though it
%  calls f/0 -- and functor/3 and =../2 refuse it (domain_error
%  compound_non_zero_arity), so compound_name_arity/3 and
%  compound_name_arguments/3 take it apart and make it. A clause's head or
%  a body's goal written `f()' is f/0's, kept and shown as the atom.
%
%  On the way: `[](a)' is a compound named by the list's end and the quoted
%  `'[]'(a)' one named by the atom of those two characters; through 3.11.0
%  cocolog read `[](a)' as nothing and `'[]'(a)' as the first.

f :- write(called(f)), nl.
g(X) :- write(called(g(X))), nl.

%  a head and a body goal written with no arguments
h() :- f().
k :- \+ \+ f(), f().
%  a grammar rule of no arguments
nt() --> [a].
%  a fact whose argument is one
p(f()).

t(G) :- a(G, yes(G)).

%  the goal, and R written when it holds: R names no variable that a
%  system would write by a name of its own
a(G, R) :-
    (   catch(G, error(E, _), (writeq(caught(E)), nl, fail))
    ->  writeq(R)
    ;   write(no)
    ),
    nl.

terms :-
    X = f(),
    t(compound(X)), t(atom(X)), t(atomic(X)), t(callable(X)), t(is_list(X)),
    t(X == f), t(X = f), t(X == f()), t(X \== f),
    t(compare(_, X, f)), t(compare(_, X, g(a))), t(compare(_, X, e)),
    t(compare(_, X, e(a))), t(compare(_, X, g())), t(compare(_, X, f())),
    t(msort([f(), f, f(a), 1, g(), e(), 'x y'()], _)),
    t(sort(0, @>=, [a(), b, a, a()], _)),
    t(copy_term(X, _)), t(ground(X)), t(term_variables(X, _)),
    t(X =@= f()), t(subsumes_term(f(), X)),
    a(findall(Y, Y = f(), L1), L1),
    a(setof(K, member(K, [f(), f, f()]), L2), L2),
    t(nb_setval(zero_k, f())), t(nb_getval(zero_k, _)).

parts :-
    t(functor(f(), _, _)), t(f() =.. _), t(_ =.. [f]), t(functor(_, f, 0)),
    t(compound_name_arity(f(), _, _)), t(compound_name_arguments(f(), _, _)),
    t(compound_name_arity(_, f, 0)), t(compound_name_arguments(_, f, [])),
    t(compound_name_arity(_, [], 0)), t(compound_name_arity(_, '[]', 0)),
    t(compound_name_arity(_, 'a b', 0)),
    t(compound_name_arity(g(1, 2), _, _)), t(compound_name_arguments(g(1, 2), _, _)),
    a((compound_name_arity(C, g, 2), C = g(x, y)), C), t(compound_name_arguments(_, g, [1, 2])),
    t(compound_name_arity(_, _, 0)), t(compound_name_arity(_, 1, 0)),
    t(compound_name_arguments(_, f, [a|_])),
    t(arg(1, f(), _)), t(setarg(1, f(), a)), t(length(f(), _)),
    t(atom_length(f(), _)).

written :-
    forall(member(T, [f(), 'hello world'(), -(), +(), '\\+'(), {}(), [](), '[]'(),
                      [](a), '[]'(a), [](a, b), '{}'(a, b), f(g(), [h()]), - f(), -(-())]),
           ( writeq(T), write(' '), print(T), write(' '), write(T), write(' '),
             write_canonical(T), nl )).

read_back :-
    forall(member(A, ['f()', 'f( )', '[]()', '[ ]()', '{}()', '\'[]\'()', '-()',
                      '\'hello world\'()', '[](a)', '[ ](a, b)', '\'[]\'(a)',
                      'g([](a), \'[]\'(b), \'[]\'())',
                      'X()', '1()', 'f ()', '- ()', 'f(a)()', '"s"()']),
           ( catch(( term_to_atom(T, A), writeq(A-T),
                     ( compound(T) -> compound_name_arity(T, N, Ar), write(' '), writeq(N/Ar) ; true ) ),
                   error(E, _), writeq(A-E)),
             nl )).

calls :-
    t(call(f())), t(f()), t(\+ f()), t(not(f())),
    t(call(g())), t(call(f(), 1)), t(call(g(), 1)),
    t((G = f(), call(G))),
    t(phrase(nt, [a])), t(phrase(nt(), [a])),
    t(p(_)), t(p(f())), t(p(f)),
    t(clause(h, _)), t(clause(h(), _)), t(clause(k, _)),
    t(predicate_property(h(), number_of_clauses(_))),
    t(assertz(d())), t(clause(d, _)), t(clause(d(), _)), t(d), t(d()),
    %  swipl 9.0.4's retract/1 unifies the clause it keeps, the atom, with
    %  the term given: `d()' is no `d', and the clause stays
    t(retract(d())), t(d), t(retract(d)), t(d).

:- dynamic d/0.

main :-
    terms, parts, written, read_back, calls.
