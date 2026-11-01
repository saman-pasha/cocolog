%  A program file's own definition of a system predicate, run by BOTH
%  SWI-Prolog and cocolog and the output compared byte for byte, the load's
%  report included: a predicate that is not ISO is the program's from its
%  first clause on (swipl calls a user file's definition of it), whatever
%  calls it -- a goal, a clause's body, call/N -- and a clause of an ISO
%  one is refused at load ("No permission to modify static procedure"),
%  the builtin answering as before.

name(x, y).
msort(a, b).
last(a, b).
format(a, b).
writeln(z) :- write(my_writeln), nl.
term_to_atom(a, b).
succ(dos, tres).
atom_length(x, y).
atomic_list_concat(a, b, c).

t(G) :- catch((G -> R = yes ; R = no), E, R = ex(E)), show(G-R).
show(T) :- copy_term(T, C), term_variables(C, Vs), bindv(Vs), print(C), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

%  a body that calls each, compiled with the rest of the file
via_body(Y) :- name(x, Y).
via_body2(Y) :- msort(a, Y), true.
via_body3(L, Y) :- length(L, _), last(L, Y).

main :-
    t(name(x, _)), t(name(abc, _)), t(msort(a, _)), t(msort([b, a], _)),
    t(last(a, _)), t(last([1, 2], _)), t(format(a, b)), t(writeln(z)),
    t(term_to_atom(a, _)), t(succ(dos, _)), t(succ(1, _)),
    t(atom_length(x, _)), t(atomic_list_concat(a, b, _)),
    t(via_body(_)), t(via_body2(_)), t(via_body3(a, _)),
    t(call(name, x, _)), t(call(msort(a), _)),
    t(findall(Y, name(x, Y), _)),
    t(atom_length(abc, _)), t(atom_codes(abc, _)).
