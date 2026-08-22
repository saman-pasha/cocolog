%  library(error)'s must_be/2 and is_of_type/2.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  WHAT IS COMPARED IS THE FORMAL PART ONLY, and never a variable. An unbound
%  value prints with a name each system numbers its own way, so the cases that
%  pass one are named rather than shown.

r(Label, Type, V) :-
    ( catch(must_be(Type, V), error(E, _), true)
    ->  ( var(E) -> R = ok ; R = E )
    ;   R = failed ),
    write(Label), write(' -> '), write(R), nl.

t(Type, V) :- r(Type/V, Type, V).

%  the three cases whose value is a variable, labelled instead of printed
unbound :-
    r('integer/_', integer, _),
    r('var/_', var, _),
    r('ground/f(_)', ground, f(_)),
    r('list/_', list, _).

main :-
    t(integer, 1), t(integer, a),
    t(atom, foo), t(atom, 1),
    t(atomic, 1), t(atomic, f(a)),
    t(boolean, true), t(boolean, false), t(boolean, maybe),
    t(callable, foo), t(callable, f(a)), t(callable, 1),
    t(compound, f(a)), t(compound, a),
    t(float, 1.5), t(float, 1),
    t(number, 1.5), t(number, a),
    t(nonneg, 0), t(nonneg, -1),
    t(positive_integer, 1), t(positive_integer, 0),
    t(negative_integer, -1), t(negative_integer, 0),
    t(list, [a]), t(list, a), t(list, [a|b]),
    t(chars, [a,b]), t(chars, [97]), t(chars, [ab]), t(chars, [-1]),
    t(codes, [97,98]), t(codes, [a]), t(codes, [-1]),
    t(text, abc), t(text, 1),
    t(oneof([a,b]), a), t(oneof([a,b]), c),
    t(between(1,3), 2), t(between(1,3), 9),
    t(ground, f(a)),
    t(var, a),
    t(nonvar, a),
    t(any, a),
    unbound,
    %  is_of_type/2 answers rather than raising, which is the whole difference
    ( is_of_type(integer, 1) -> write(iot_yes) ; write(iot_no) ), nl,
    ( is_of_type(integer, a) -> write(iot_yes) ; write(iot_no) ), nl.
