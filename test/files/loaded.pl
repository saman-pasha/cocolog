%  current_predicate/1 and predicate_property/2 over a file the program
%  loads. Run by BOTH SWI-Prolog and cocolog, output compared byte for byte;
%  test/files.pl writes sib.pl into the sandbox first.
%
%  Through 1.10.27 a file loaded by ensure_loaded/1 or use_module/1 of a path
%  -- and `-s FILE' is one -- was a module whose predicates were the
%  library's, so current_predicate(sib_a/1) said no where SWI says yes, and
%  predicate_property/2 did not exist (reported from cicili-lang).

:- ensure_loaded(sib).
:- dynamic(dyn/1).

own(1).
own(2) :- own(1).

t(PI) :- ( current_predicate(PI) -> R = yes ; R = no ), write(PI-R), nl.
p(H, P) :- ( predicate_property(H, P) -> R = yes ; R = no ), write(P-R), nl.

main :-
    t(sib_a/1), t(sib_b/1), t(own/1), t(dyn/1), t(nope/0),
    p(sib_a(_), defined), p(sib_a(_), static), p(sib_a(_), dynamic),
    p(sib_a(_), number_of_clauses(1)), p(sib_a(_), number_of_rules(0)),
    p(sib_b(_), number_of_rules(1)),
    p(own(_), number_of_clauses(2)), p(own(_), number_of_rules(1)),
    p(dyn(_), dynamic), p(dyn(_), number_of_clauses(0)),
    p(nope, defined),
    p(user:own(_), defined),
    p(atom_length(_, _), built_in), p(format(_, _), built_in), p((_, _), built_in),
    p(msort(_, _), defined), p(atom_length(_, _), dynamic),
    %  a control construct by its name AND arity; the engine's markers are
    %  no predicates
    p(call(_, _, _), built_in), p(call(_, _, _, _, _, _, _, _, _, _), defined),
    p(true(_), defined), p([], defined), p((a :- b), defined), p('$k'(_, _, _), defined),
    ( predicate_property(own(_), number_of_clauses(N)) -> write(n(N)) ; write(none) ), nl,
    findall(X, (predicate_property(H, dynamic), functor(H, X, 1), X == dyn), Ds), write(Ds), nl,
    findall(X2, (predicate_property(user:H2, dynamic), functor(H2, X2, 1), X2 == dyn), Ds2),
    write(Ds2), nl.
