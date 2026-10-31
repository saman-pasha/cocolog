%  The bar, as swipl 9.0.4 has it (cocolog 3.2.0). Run by BOTH SWI-Prolog
%  and cocolog, output compared byte for byte.
%
%  `a | b' IS '|'(a, b), AN OPERATOR AT 1105 xfy -- a term like any other,
%  written `a|b' -- and in a clause's body, a goal's, a grammar rule's or a
%  meta-call's it is the disjunction: the body is stored with `;' (clause/2
%  hands back `;'), a call of '|'/2 is `;''s, cut and all, and a program's
%  own clause for '|'/2 is kept and never called. Through 3.1.0 cocolog read
%  the bar as `;' wherever it stood.

g --> [a] | [b].
h --> ( [x] | [y] ), [z].
k(X) :- ( X = 1 | X = 2 ).
c(X) :- ( X = 1, ! | X = 2 ).
m(X) :- X = (a | b).
'|'(x, y).   % cocolint: N3 -- on purpose: swipl keeps it and never calls it, and so does cocolog

s(Label, Value) :- write(Label), write(=), writeq(Value), nl.
yn(Label, G) :- ( catch(G, _, fail) -> s(Label, yes) ; s(Label, no) ).

%  an error with its variables left out, which the two systems name
%  differently
w(E) :-
    copy_term(E, error(F, C)),
    term_variables(F, Vs), maplist(=('_'), Vs),
    (   var(C) -> C1 = '_'
    ;   C = context(X, _) -> C1 = context(X)
    ;   C1 = C
    ),
    writeq(F-C1), nl.
t(G) :- catch(( call(G) -> writeln(yes) ; writeln(no) ), E, w(E)).

main :-
    %  ---- a term ----
    writeq('|'(a, b)), nl,
    print('|'(a, b)), nl,
    write_canonical('|'(a, b)), nl,
    write('|'(a, b)), nl,
    writeq(f((a|b))), nl,
    writeq([(a|b)]), nl,
    writeq((a:-b|c)), nl,
    writeq(((a,b)|c)), nl,
    writeq((a|b,c)), nl,
    writeq('|'(a, '|'(b, c))), nl,
    writeq('|'('|'(a, b), c)), nl,
    writeq(- (a|b)), nl,
    writeq((a;b|c)), nl,
    writeq((a|b;c)), nl,
    m(T1), T1 =.. U1, s(univ, U1),
    current_op(P2, Ty2, '|'), s(op, P2-Ty2),
    %  ---- a goal ----
    findall(X3, k(X3), L3), s(body, L3),
    findall(X4, c(X4), L4), s(cut, L4),
    clause(k(_), B5), B5 =.. [F5|_], s(stored, F5),
    G6 = (fail | true), yn(called, G6),
    yn(inline, (fail | true)),
    yn(negated, \+ (fail | fail)),
    findall(X7, (X7 = 1 | X7 = 2), L7), s(findall, L7),
    yn(direct, '|'(fail, true)),
    yn(once, once((fail | true))),
    assertz((p8 :- (fail | true))), yn(asserted, p8),
    clause(p8, B8), B8 =.. [F8|_], s(asserted_stored, F8),
    yn(own_clause, '|'(x, y)),
    ( predicate_property('|'(_, _), P9) -> s(property, P9) ; s(property, none) ),
    %  ---- a meta-call's structure, compiled whole as swipl's is ----
    t((fail | 1)), t((true | 1)), t(call((fail | 1))),
    t((nope_x | true)), t(call((nope_y | true))),
    t(findall(x, (nope_f | true), _)), t(forall((nope_g | true), true)),
    t(aggregate_all(count, (true, (nope_h | true)), _)),
    t(call((!, fail | true))),
    t(findall(Y10, call((Y10 = 1, ! | Y10 = 2)), [1])),
    t(assertz((p11 :- (a | 1)))),
    t(assertz((p12 :- \+ (a | b)))), t(( clause(p12, B12), B12 = (\+ (_ ; _)) )),
    %  ---- a grammar rule ----
    yn(grammar, phrase(g, [b])),
    yn(grammar_nested, phrase(h, [y, z])),
    yn(phrase_body, phrase(([a] | [b]), [b])).
