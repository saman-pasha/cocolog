%  The reader, where an atom that is a prefix operator meets another operator.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  THE RULE IS WHETHER THE NEXT TOKEN COULD START A TERM. `- - a' is prefix
%  `-' applied to `-a', because the second `-' can begin one. `- = a' is infix
%  `=' with the atom `-' on its left, because `=' is only ever infix and begins
%  nothing. And a QUOTED atom is never a prefix operator, which is the whole
%  difference between `- - a' and `'-' - a'.
%
%  Each term is taken apart with =.. and the pieces written one to a line: the
%  shape is what is being checked, and printing the term would only compare the
%  writer with itself.

s(Label, Value) :- write(Label), write(=), write(Value), nl.

shape(Label, T) :- T =.. L, length(L, N), s(Label, N), tell_args(Label, L).
tell_args(_, []).
tell_args(Label, [H|T]) :- ( atomic(H) -> s(Label, H) ; s(Label, compound) ),
                           tell_args(Label, T).

main :-
    shape(prefix_then_plain, - a),
    shape(prefix_then_prefix, - - a),
    shape(quoted_is_an_atom, '-' - a),
    shape(bracketed_is_an_atom, (-) - a),
    shape(prefix_then_infix_only, - = a),
    shape(prefix_then_times, - * a),
    shape(prefix_then_mod, - mod a),
    shape(infix_then_prefix, a - - b),
    shape(operator_as_argument, f(-, a)),
    %  the HEAD only, not the functor: SWI 7 names a list cell '[|]' where
    %  this uses the traditional '.', which is a design difference and not a
    %  reader one.
    ( [-|_] = [HL|_], atom(HL) -> s(operator_in_a_list_head, HL) ; s(operator_in_a_list_head, no) ),
    shape(negation_of_prefix, \+ - a),
    shape(minus_of_number, - (1)),
    %  NOT `dynamic foo' as an argument: `dynamic' is fx 1150 and an argument
    %  is read at 999, so it needs brackets. SWI is lenient about that and this
    %  reader is not, which is a priority rule and not the lookahead this file
    %  is about.
    shape(alpha_prefix, (dynamic foo)),
    ( X = -, atom(X) -> s(bare_at_end, yes) ; s(bare_at_end, no) ),
    ( T = [-], T = [E], atom(E) -> s(sole_list_element, yes) ; s(sole_list_element, no) ),
    true.
