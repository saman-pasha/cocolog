%  library(error)'s must_be/2 and is_of_type/2 over every type swipl 9.0.4's
%  has_type/2 names, and a library's own: library(assoc) extends
%  error:has_type/2 with `assoc'. Run by BOTH SWI-Prolog and cocolog,
%  output compared byte for byte.
%
%  Each goal's every answer with its determinism, or its error. A type is a
%  clause of has_type/2; must_be/2 asks it and then says why not -- an
%  unbound value, and a partial list, an instantiation error; a list of the
%  wrong things its first wrong element's error; an improper list a type
%  error naming list(Of); var an uninstantiation error; cyclic and acyclic
%  domain errors; a value a ground type holds unbound an instantiation
%  error; a type no clause names existence_error(type, T). Through 3.28.0
%  cocolog's own table: must_be(assoc, A) raised type_error(assoc, A) of an
%  assoc, a partial list type_error(list, L) -- which ordsets.pl's
%  ord_intersection/2 and yall.pl's parameters met -- an unknown type
%  type_error(T, X), and an unbound type was read as `any'.
%
%  A stream is library(stream)'s, loaded where swipl has no open/4 of its
%  own. NOT COMPARED: dict, which cocolog has none of (COMPAT.md), and text
%  of a string, whose "..." swipl reads as a string.

:- use_module(library(assoc)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

pv(T) :- \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

t(G) :-
    catch(( findall(G-D, ( setup_call_cleanup(true, G, D0 = det),
                           ( D0 == det -> D = det ; D = nondet ) ), L),
            pv(G), write(' => '), pv(L), nl ),
          E, ( pv(G), write(' raised '), pv(E), nl )).

main :-
    forall(mb(T, V), t(must_be(T, V))),
    forall(iot(T, V), t(is_of_type(T, V))).

mb(integer, a). mb(integer, _). mb(_, a). mb(foo, a). mb(foo, _). mb(positive_integer, a).
mb(positive_integer, 0). mb(nonneg, -1). mb(nonneg, a). mb(negative_integer, 0).
mb(list, [a|_]). mb(list, [a|b]). mb(list, foo). mb(list, _). mb(list(integer), [1, a]).
mb(list(integer), [1|_]). mb(list(integer), [1|b]). mb(list(integer), foo). mb(list(_), [1]).
mb(list(foo), [1]). mb(list(atom), [a]). mb(list(list(atom)), [[a], [1]]).
mb(proper_list, [a|_]). mb(proper_list, foo). mb(list_or_partial_list, [a|b]). mb(list_or_partial_list, [a|_]).
mb(chars, [a|_]). mb(chars, [a, 1]). mb(chars, foo). mb(chars, [ab]). mb(codes, [97|_]). mb(codes, [-1]).
mb(codes, [a]). mb(codes, foo). mb(code, 1114111). mb(code, 1114112). mb(code, -1). mb(code, a). mb(code, _).
mb(char, ab). mb(char, ''). mb(char, 1). mb(char, a).
mb(text, f(x)). mb(text, f(_)). mb(text, [a, 1]). mb(text, abc). mb(text, [0'a]).
mb(boolean, maybe). mb(boolean, _). mb(boolean, true).
mb(oneof([a, b]), c). mb(oneof([a, b]), _). mb(oneof([a, b]), f(_)). mb(oneof(_), a).
mb(between(1, 3), 0). mb(between(1, 3), a). mb(between(1, 3), 2.0). mb(between(1.0, 3.0), 2).
mb(between(1, 3), _). mb(between(1, inf), 5). mb(between(_, 3), 2).
mb(cyclic, a). mb(acyclic, a). mb(var, a). mb(var, _). mb(nonvar, _). mb(ground, f(_)). mb(any, _).
mb(atom, 1). mb(atomic, f(a)). mb(callable, 3). mb(callable, _). mb(compound, a). mb(float, 1).
mb(number, a). mb(rational, 1). mb(rational, 1.5). mb(rational, _). mb(pair, a-b). mb(pair, a).
mb(pair, _). mb(symbol, a). mb(symbol, 1). mb(constant, a). mb(constant, f(a)).
mb(encoding, utf8). mb(encoding, foo). mb(encoding, _).
mb(type, integer). mb(type, foo). mb(type, _). mb(type, list(integer)).
mb(assoc, t). mb(assoc, t(k, v, <, t, t)). mb(assoc, foo). mb(assoc, _).
mb(order, <). mb(string, abc). mb(atom, _).
mb(stream, user_input). mb(stream, user_error). mb(stream, foo). mb(stream, _). mb(stream, 3).
iot(integer, 1). iot(integer, a). iot(_, a). iot(foo, a). iot(list(integer), [1]). iot(list(integer), [a]).
iot(list(_), [1]). iot(assoc, t). iot(assoc, foo). iot(type, integer). iot(type, foo).
iot(oneof(_), a). iot(between(1, 3), 2). iot(char, a). iot(code, 1114112). iot(text, abc).
iot(list_or_partial_list, [a|_]). iot(list_or_partial_list, [a|b]). iot(boolean, _).
iot(encoding, _). iot(cyclic, a). iot(acyclic, f(x)). iot(pair, _-_). iot(chars, [a|_]).
