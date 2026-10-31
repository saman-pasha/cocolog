%  dynamic, discontiguous and multifile as DIRECTIVES, run by BOTH
%  SWI-Prolog and cocolog and the output compared byte for byte, stderr
%  with it: a spec whose every part is a plain indicator declares them
%  all; any other reports each part that is none in swipl's two lines, the
%  first naming the directive's place, `Kind/1: ' before the message, and
%  declares the rest, as swipl's directive does -- and the load goes on.
%  An ISO predicate is refused by name; a system predicate that is not
%  ISO is the program's from the declaration on. (`:- multifile(_).' is
%  left out: it ends swipl's load. A control construct is left out too:
%  swipl names where it defines one, in its own boot files.)

:- dynamic(foo).
:- dynamic(_/1).
:- dynamic(foo/_).
:- dynamic(foo/(-1)).
:- dynamic(1/1).
:- dynamic(atom_length/2).
:- discontiguous(atom_length/2).
:- multifile(atom_length/2).
:- discontiguous(foo/a).
:- multifile(f(x)).
:- dynamic([a1/1, b]).
:- dynamic([atom_length/2, c]).
:- dynamic((a2/1, atom_codes/2)).
:- dynamic(foo//a).
:- dynamic(foo//_).
:- dynamic(e1//f(x)).
:- dynamic(e2//1.5).
:- dynamic(e3//(1+1)).
:- dynamic(1/0).
:- dynamic(_/0).
:- discontiguous([d1/1, d2/1, 3, d3/1]).
:- multifile m1/1, m2/2.
:- discontiguous user:d4/1.
:- dynamic(succ/2).
:- discontiguous(msort/2).

d4(1).
d4(2).

r(Label, Goal, Show) :-
    catch(( Goal -> R = Show ; R = no ), E, R = ex(E)),
    copy_term(Label-R, C), term_variables(C, Vs), bindv(Vs), print(C), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

main :-
    r(before_bad, a1(_), yes),
    r(before_iso, a2(_), yes),
    r(all_the_good, (d1(_) ; d2(_) ; d3(_)), yes),
    r(multi, (m1(_) ; m2(_, _)), yes),
    r(discontiguous_clauses, findall(X, d4(X), L), L),
    r(current, findall(N, (member(N, [d1, d2, d3, m1, a1, a2]), current_predicate(N/_)), Ns), Ns),
    r(evaluated, current_predicate(e3/4), yes),
    r(taken_dynamic, succ(1, _), yes),
    r(taken_discontiguous, msort([b, a], _), yes),
    r(not_taken_iso, atom_length(abc, N3), N3).
