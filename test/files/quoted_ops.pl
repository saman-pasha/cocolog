%  An operator whose name cannot be written without its quotes, read and
%  written; and the spaces swipl's writer puts around a quoted atom and
%  before an opening bracket. Run by BOTH systems, output compared byte for
%  byte.
%
%  READ: a quoted atom is an operator only where it cannot be written
%  without its quotes ('p\'q', 'Ab', 'a b', '[]', ',' and '|'): `'p\'q' a'
%  applies the prefix operator, `a 'x\'y' b' the infix one, and `'-' a',
%  `a '-' b' and `a '@@@' b' are no terms, as `'-'' and `'@@@'' need no
%  quotes. Through cocolog 3.15.0 a quoted atom was never a prefix
%  operator, and always an infix one.
%
%  WRITE: a quote after a digit and a quote after a quote take a space
%  (`x1 'x\'y' 2', `'A' 'x\'y' 'B''), and an opening parenthesis or a brace
%  after any prefix operator (`pq (a,b)', `\+ {a}', `- {}'), where through
%  3.15.0 cocolog wrote `x1'x\'y'2' (read back as a character code),
%  `'A''x\'y''B'' (one atom) and `pq(a,b)' (pq/2). term_to_atom/2 and
%  term_string/2 write a newline, a tab and a return as they are, where
%  writeq/1 escapes them; through 3.15.0 cocolog escaped them there too.
%
%  Left out: the read of `-{}', a dict to swipl and -({}) to cocolog.

:- op(700, xfx, 'x''y').
:- op(700, xfx, 'Cd').
:- op(700, xfx, '@@@').
:- op(200, fy, 'p''q').
:- op(200, fy, pq).
:- op(200, fy, 'Ab').
:- op(200, fy, 'a b').
:- op(200, fy, '[]').
:- op(700, xfx, '[]').
:- op(200, fy, 'p\nq').

t(G) :- catch((G -> true ; write(failed)), E, (E = error(F, _) -> print(F) ; print(E))), nl.

r(A) :- write(A), write('  =>  '), t((term_to_atom(T, A), write_canonical(T))).

w(T) :- writeq(T), write(' | '), print(T), write(' | '), format("~q", [T]), write(' | '),
        term_to_atom(T, A), write(A), write(' | '),
        ( term_to_atom(T2, A), T2 =@= T -> write(same) ; write(differs) ), nl.

g(F, Args) :- T =.. [F|Args], w(T).

nk(N) :- ( N == '[]' -> write(atom) ; N == [] -> write(nil) ; write(other) ).

c(Cs) :- atom_codes(A, Cs), term_to_atom(A, B), atom_codes(B, Bs), print(Bs), write(' | '),
         term_string(A, S), string_codes(S, Ss), print(Ss), write(' | '),
         string_codes(Str, Cs), term_to_atom(Str, C), atom_codes(C, Cc), print(Cc), write(' | '),
         term_string(Str, D), string_codes(D, Dc), print(Dc), write(' | '),
         format(atom(E), "~q", [A]), atom_codes(E, Ec), print(Ec), write(' | '),
         term_string(A, F, []), string_codes(F, Fc), print(Fc), write(' | '),
         ( term_to_atom(A2, B), A2 == A -> write(same) ; write(differs) ), nl.

main :-
    %  ---- read ----
    r('\'p\\\'q\' a'), r('\'p\\\'q\' (a)'), r('\'p\\\'q\' (a,b)'), r('\'p\\\'q\' \'p\\\'q\' a'),
    r('\'p\\\'q\' 1'), r('\'p\\\'q\' -1'), r('\'p\\\'q\' - 1'), r('\'p\\\'q\' -a'),
    r('\'p\\\'q\'-a'), r('(\'p\\\'q\')-a'), r('\'p\\\'q\' = a'), r('a = \'p\\\'q\''),
    r('- \'p\\\'q\''), r('- \'p\\\'q\' a'), r('\'p\\\'q\''), r('\'p\\\'q\' \'p\\\'q\''),
    r('f(\'p\\\'q\', a)'), r('[\'p\\\'q\'|a]'), r('\'p\\\'q\', a'),
    r('\'Ab\' x'), r('\'Ab\' (x)'), r('\'Ab\' (x,y)'), r('\'Ab\'(x,y)'), r('f(\'Ab\' x)'),
    r('[\'Ab\' x]'), r('\'Ab\' - x'), r('\'Ab\' \'Ab\' x'), r('\'a b\' x'), r('\'[]\' x'),
    r('[] x'), r('a \'[]\' b'), r('\'[]\'(a,b)'), r('[](a,b)'), r('\'[]\' \'[]\' x'), r('pq - a'), r('pq -a'), r('pq = a'), r('pq (a,b)'), r('pq(a,b)'),
    r('a \'x\\\'y\' b'), r('a \'x\\\'y\' \'x\\\'y\''), r('\'x\\\'y\' \'x\\\'y\''),
    r('- \'x\\\'y\' a'), r('- \'x\\\'y\''), r('f(- \'x\\\'y\')'), r('\'x\\\'y\' - a'),
    r('a \'x\\\'y\' \'p\\\'q\' b'), r('a \'Cd\' b'), r('a \',\' b'), r('a \'|\' b'),
    r('a \'-\' b'), r('\'-\' a'), r('\'-\'(a)'), r('\'-\' - a'), r('- \'-\''), r('- \'-\' a'),
    r('a \'=\' b'), r('a \'@@@\' b'), r('a @@@ b'), r('\'dynamic\' a'), r('a \'mod\' b'),
    r('\'\\\\+\' a'), r('\\+ {a}'), r('- {a}'), r('- {}'),
    %  ---- write ----
    g('x''y', [1, 2]), g('x''y', [x1, 'B']), g('x''y', ['A', 'B']), g('x''y', [0.5, a]),
    g('x''y', [1.0Inf, 2]), g('x''y', [a, 'B']), g('x''y', [1, (a:-b)]), g('x''y', [a, (b:-c)]),
    g('Cd', [1, 2]), g('Cd', ['A', 'B']), g('+', [1, 'B']), g('+', ['A', 'B']),
    g(pq, [(a,b)]), g(pq, [a+b]), g(pq, [(a:-b)]), g(pq, [-]), g(pq, [{a}]), g(pq, ['A']),
    g(pq, [[a]]), g(pq, [a]), g(pq, [-(1)]), g(dynamic, [(a:-b)]), g(dynamic, [{a}]),
    g('p''q', [(a,b)]), g('p''q', ['A']), g('p''q', [-]), g('p''q', [{a}]), g('p''q', [1]),
    g('p''q', [a]), g('p''q', ['p''q'(a)]), g('p''q', [-(a)]), g('p''q', [-(1)]),
    g(-, ['p''q', a]), g(-, [pq, a]), g(=, ['x''y', a]), g('Ab', [(x,y)]), g('Ab', ['Ab'(x)]),
    g(-, [(a,b)]), g(-, [{a}]), g(-, [{}]), g(-, [-]), g(-, [-({a})]), g(\+, [{a}]),
    g(\+, [(a:-b)]), g(-, ['x''y']), g(-, ['p''q']), g(f, ['x''y', 'p''q']), g('[]', [a, b]), g('[]', [a]), g([], [a, b]), g([], [a]),
    %  ---- term_to_atom/2 and term_string/2 write control characters as they are ----
    c([0'a, 10, 0'b]), c([0'a, 9, 0'b]), c([0'a, 13, 0'b]), c([0'a, 7, 0'b]),
    c([0'a, 0'', 0'b]), c([0'a, 92, 0'b]), c([0'x, 10, 9, 13, 0'y]),
    %  inside a compound and a list, as a functor's name and as an operand
    string_codes(S1, [0'x, 10, 0'y]),
    t((term_to_atom(f('a\nb', [S1, 'c\td']), A1), atom_codes(A1, C1), print(C1))),
    t((term_string(['a\nb'|'c\rd'], A2), string_codes(A2, C2), print(C2))),
    t((term_to_atom('a\nb'(1), A3), atom_codes(A3, C3), print(C3))),
    t((T4 =.. [-, 'p\nq'], term_to_atom(T4, A4), atom_codes(A4, C4), print(C4))),
    t((term_to_atom(f('a\nb', ['c\td', 'e\rf']), A5), term_to_atom(T5, A5),
       T5 == f('a\nb', ['c\td', 'e\rf']), write(same))),
    %  functor/3 and =../2 name a compound by the atom `'[]'' or by the list's end
    t((functor(F6, '[]', 2), F6 =.. [N6|_], nk(N6))), t((functor(F7, [], 2), F7 =.. [N7|_], nk(N7))),
    t((F8 =.. ['[]', a], F8 =.. [N8|_], nk(N8))), t((F9 =.. [[], a], F9 =.. [N9|_], nk(N9))).
