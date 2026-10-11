%  write_term/2's options.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  variable_names(['X'=V, ...]) writes each named variable still unbound as
%  its name. Through 1.10.5 cocolog read past the option, and every variable
%  came out `_G' and a number. A variable left unnamed is not written here:
%  every Prolog numbers those its own way.

main :-
    T = f(A, g(B, A)),
    write_term(T, [variable_names(['A'=A, 'B'=B])]), nl,
    write_term(p(X), [quoted(true), variable_names(['Abc'=X])]), nl,
    Y = 1, write_term(q(Y), [variable_names(['Y'=Y])]), nl,
    write_term('hello world'(Z), [quoted(true), variable_names(['Z'=Z])]), nl,
    write_term([A, B|C], [variable_names(['A'=A, 'B'=B, 'Rest'=C])]), nl,
    write_term(A + B * A, [variable_names(['A'=A, 'B'=B])]), nl,
    write_term(r(A), [variable_names(['First'=A, 'Second'=A])]), nl,
    write_term(s(A), [ignore_ops(true), variable_names(['A'=A])]), nl.
