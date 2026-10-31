%  write_canonical/1 and format's ~k (cocolog 3.1.0), run by BOTH
%  SWI-Prolog and cocolog and the output compared byte for byte: a
%  variable is written `_' when the term holds it once and as a letter
%  (A .. Z, then A1 ...) by its first place when it holds it again, a
%  list keeps its notation and a curly term is written as the compound it
%  is, `{}(x)'. What write_term/2 writes with ignore_ops(true): lists and
%  curly terms in their notation. And what the reader takes back: `{}(x)'
%  is `{x}'. Nothing here is a string, as `"..."' is a string in swipl and
%  codes here, and no variable is written but by write_canonical/1: what
%  either system calls an unnamed variable is its own (`_123', `_G123').

main :- named, lists_and_curly, operators, atoms, ignore_ops, read_back.

named :-
    write_canonical(f(X, _, X)), nl,
    write_canonical(f(_)), nl,
    write_canonical(g(A, B, C, A, B, C)), nl,
    write_canonical('$VAR'(1)), nl,
    write_canonical(f('$VAR'(1), Z, Z)), nl,
    write_canonical('$VAR'('Foo')), nl,
    write_canonical('$VAR'('_')), nl,
    length(L, 30), append(L, L, LL), T =.. [h|LL], write_canonical(T), nl,
    format("~k ~k~n", [f(P, Q, P), g(Q)]),
    write_canonical(f(_V1, _V2)), nl,
    write_canonical(_), nl,
    W = w(K, K), write_canonical(W), nl,
    with_output_to(atom(S), write_canonical(f(M, M, _))),
    atom_length(S, SL), writeq(S-SL), nl,
    write_canonical(f(N, g(N, _), [N])), nl,
    write_canonical([E, F, E | F]), nl,
    write_canonical(k(Y1, Y2, Y3, Y2)), nl,
    ( var(Y1), var(Y3) -> true ; true ).

lists_and_curly :-
    write_canonical([X1, _ | X1]), nl,
    write_canonical([a|b]), nl,
    write_canonical([a, b, c]), nl,
    write_canonical([]), nl,
    write_canonical('[]'), nl,
    write_canonical('[]'(1)), nl,
    write_canonical({x}), nl,
    write_canonical({x, y}), nl,
    write_canonical({}), nl,
    write_canonical('{}'(x)), nl,
    write_canonical(f({a})), nl,
    write_canonical([(a, b)]), nl,
    write_canonical(f(;, '|', '[]', {})), nl.

operators :-
    write_canonical(- (1)), nl,
    write_canonical(-(-(1))), nl,
    write_canonical(- (-1)), nl,
    write_canonical(- - a), nl,
    write_canonical(1 - 2), nl,
    write_canonical(1 + -2), nl,
    write_canonical(a:b:c), nl,
    write_canonical((a, b)), nl,
    write_canonical((a :- b, c ; d -> e)), nl,
    write_canonical(f(-, (-))), nl,
    write_canonical(-(a)), nl,
    write_canonical(\+ a), nl,
    write_canonical(1.5), nl,
    write_canonical(-0.0), nl,
    write_canonical(1r3), nl.

atoms :-
    write_canonical('hello world'), nl,
    write_canonical(f('A', 'B')), nl,
    write_canonical('hello'(world)), nl,
    write_canonical('don''t'), nl,
    write_canonical(f('$x', [])), nl,
    write_canonical('\n'), nl.

ignore_ops :-
    write_term([a, b|c], [ignore_ops(true)]), nl,
    write_term([a, b], [ignore_ops(true), quoted(true)]), nl,
    write_term('{}'(x), [ignore_ops(true)]), nl,
    write_term({x, y}, [quoted(true), ignore_ops(true)]), nl,
    write_term(1 + 2 * 3, [ignore_ops(true)]), nl,
    write_term(f(a - b, [c - d]), [ignore_ops(true), quoted(true)]), nl,
    X = '{}'(a), print(X), nl.

read_back :-
    term_to_atom(X, '{}(x)'), print(X), nl,
    ( X == {x} -> writeln(same) ; writeln(differ) ),
    term_to_atom(Y, 'f({}(a,b))'), print(Y), nl,
    term_to_atom(Z, '{}'), print(Z), nl,
    term_to_atom(T, 'g(A,_,A)'), with_output_to(atom(S), write_canonical(T)),
    writeq(S), nl,
    term_to_atom(T2, S), ( T2 =@= T -> writeln(variant) ; writeln(other) ).
