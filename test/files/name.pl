%  name/2, run by BOTH SWI-Prolog and cocolog and the output compared byte
%  for byte: a bound first argument's codes, a list's number or atom, and
%  the errors of each. A term is shown with its variables bound to `v'
%  (`show/1'), and no "..." text is written: a string in swipl is a list of
%  codes in cocolog.

t(G) :- catch((G -> R = yes ; R = no), E, R = ex(E)), show(G-R).
show(T) :- copy_term(T, C), term_variables(C, Vs), bindv(Vs), print(C), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

main :- given, read_back, refused.

%  a bound first argument: its text's codes, or, where they do not unify,
%  the second read and compared -- unless an unbound element comes first
given :-
    t(name(abc, _)), t(name(42, _)), t(name(-3, _)), t(name(1.5, _)),
    t(name('', _)), t(name('[]', _)), t(name(1r3, _)),
    t(name(abc, [0'a, 0'b, 0'c])), t(name(abc, [0'a])), t(name(abc, [a, b, c])),
    t(name(abc, foo)), t(name(42, [0'4, 0'2])), t(name(abc, [0'a|_])),
    t(name(1.0e10, _)), t(name(-0.0, _)), t(name('hello world', _)),
    t(name(abc, [_])), t(name(abc, [_, _])), t(name(abc, [_, _, _, _])), t(name(abc, [0'x|_])),
    t(name(abc, [f(x)])), t(name(abc, [0'a, f(x)])), t(name(abc, [f(x), _])), t(name(abc, [_, f(x)])),
    t(name(42, [a, b])), t(name(42, [0'4, 0'2, 0' ])), t(name(42, [0'+, 0'4, 0'2])),
    t(name(42, [0'0, 0'x, 0'2, 0'a])), t(name(42, [52, 50.0])), t(name('42', [0'4, 0'2])),
    t(name(42.0, [0'4, 0'2])), t(name(abc, [0'a, 0'b, 0'c|_])), t(name(abc, [0'a, 0'b|foo])),
    t(name(4, [0' , 0'4])), t(name(' 4', [0' , 0'4])), t(name(abc, [-1])), t(name(abc, 42)).

%  an unbound first argument: the number the whole text is, or its atom
read_back :-
    t(name(_, [0'a, 0'b])), t(name(_, [0'4, 0'2])), t(name(_, [0'-, 0'4])),
    t(name(_, [0'+, 0'4])), t(name(_, [0' , 0'4])), t(name(_, [0'4, 0' ])),
    t(name(_, [0'0, 0'x, 0'f])), t(name(_, [0'0, 0'o, 0'7])), t(name(_, [0'0, 0'b, 0'1, 0'0])),
    t(name(_, [0'1, 0'., 0'5])), t(name(_, [0'1, 0'e, 0'2])), t(name(_, [0'1, 0'., 0'0, 0'e, 0'2])),
    t(name(_, [0'4, 0'2, 0'r, 0'3])), t(name(_, [0'1, 0'r, 0'2])),
    t(name(_, [0'0, 0''', 0'a])), t(name(_, [0'i, 0'n, 0'f])),
    t(name(_, [0'1, 0'., 0'0, 0'I, 0'n, 0'f])), t(name(_, [0'1, 0'., 0'5, 0'N, 0'a, 0'N])),
    t(name(_, [])), t(name(_, [a, b])), past_ascii,
    t(name(_, [0'/, 0'*])), t(name(_, [0'%, 0'1])), t(name(_, [0'-])),
    t(name(_, [0'-, 0' , 0'4])), t(name(_, [0'1, 0'.])), t(name(_, [0'., 0'5])),
    t(name(_, [0'0, 0'0, 0'7])), t(name(_, [0'-, 0'0])), t(name(_, [0'A, 0'b])),
    t(name(_, [0'4, 0'2, 0'., 0'0])), t(name(_, [0'1, 0'e])),
    t(name(X1, [0'4, 0'2])), Y1 is X1 + 1, show(Y1).

%  text past ASCII, shown as its codes: a quoted write of it is the
%  locale's in swipl (an escape where it cannot be written)
past_ascii :-
    ( name(A, [0'a, 0x10FFFF]) -> atom_length(A, N), atom_codes(A, Cs), show(N-Cs) ; show(no) ).

%  what is refused, and how swipl names it
refused :-
    t(name([], _)), t(name(f(x), _)), t(name([a], _)),
    t(name(_, _)), t(name(_, [0'a|_])), t(name(_, foo)), t(name(_, 42)),
    t(name(_, [0'a, b])), t(name(_, [a, 0'b])), t(name(_, [-1])),
    t(name(_, [0x110000])), t(name(_, [f(x)])), t(name(_, [0'a|b])).
