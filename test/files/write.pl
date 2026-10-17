%  write/1 and writeq/1, and what writes as they do: format's ~w and ~q,
%  writeln/1, print/1 and ~p, write_canonical/1 and write_term/2's
%  numbervars(true) and quoted(true). Run by BOTH systems, output compared
%  byte for byte.
%
%  NUMBERVARS: write/1, writeq/1, writeln/1, print/1 and their format
%  directives write '$VAR'(N) as the variable it names, by the rules
%  test/files/print.pl holds; write_canonical/1, and write_term/2 without
%  numbervars(true), write it as the compound it is. Through cocolog 2.2.4
%  only print/1 and ~p did, and write('$VAR'(1)) was $VAR(1).
%
%  CHARACTER ESCAPES: a quoted write a program asks for -- writeq/1,
%  print/1, write_canonical/1, ~q, ~p and write_term/2's quoted(true) --
%  writes a quote inside an atom as \' and a control character that has a
%  letter as the letter (\a \b \v \f, and \r in a string as in an atom).
%  Through 2.2.4 cocolog doubled the quote, 'don''t', which reads back as
%  the same atom, and wrote the four as they are. term_to_atom/2 doubles
%  the quote in both systems, and is held to it here. Left out: a newline
%  or a tab through term_to_atom/2, which swipl writes as it is and cocolog
%  as \n and \t; write_canonical/1 of an operator, which cocolog writes
%  with the operator (cocolint W1); and a control character with no letter,
%  which swipl writes \x1\ and cocolog as it is (its reader has no \x..\
%  escape to read one back).
%
%  AN OPERATOR WHOSE NAME HOLDS A QUOTE is escaped where it is the operator
%  and where it is an operand in brackets. The prefix one is built with
%  =../2, because cocolog's reader takes no quoted atom as a prefix
%  operator; left out, an integer before a quoted infix operator, which
%  swipl spaces (1 'x\'y' 2) and cocolog does not.

:- op(700, xfx, 'x''y').
:- op(200, fy, 'p''q').

v('$VAR'(0)). v('$VAR'(1)). v('$VAR'(27)). v('$VAR'(-1)). v('$VAR'('Foo')).
v('$VAR'('_x')). v('$VAR'(x)). v('$VAR'('Foo bar')). v('$VAR'(1.5)).
v(f('$VAR'(0), '$VAR'(1))). v('$VAR'(0) + 'a b'). v(['$VAR'(0)|'$VAR'(1)]).
v(- '$VAR'(1)). v('$VAR'(1, 2)). v({'$VAR'(2)}). v('$VAR'(0) - '$VAR'(-2)).
v(g('$VAR'('Foo'), 'Foo', s)). v(- '$VAR'(-1)). v(\+ '$VAR'(25)).

a('don''t'). a(''''). a('a\\b'). a('a\nb'). a('a\tb'). a('a\rb').
a('\a'). a('\b'). a('\v'). a('\f'). a('a b'). a('it''s'(x)). a('x''' + y).
a(- 'a''b'). a(['q''', 'r']). a('\\'). a('\''). a('a\\\'b'). a('''''').
a(f('\a', 'b''c', d)). a('A''s' = '\f').

c('$VAR'(0)). c('$VAR'('Foo')). c(f('$VAR'(0), '$VAR'(1))). c(['$VAR'(0)|x]).
c('don''t'). c(f('it''s', '\b')). c(['q''', 'a\\b', '\v']). c('x''y'(z)).

q('don''t'). q(''''). q(f('it''s', '$VAR'(1))). q(['q''', 'a\\b']).

o(T) :- T =.. ['x''y', a, b].
o(T) :- T =.. ['x''y', f('$VAR'(1)), [b]].
o(T) :- T =.. ['p''q', z].
o(a - 'p''q').
o('x''y' - 1).
o(f('x''y', 'p''q')).

s([0'a, 0'", 0'b]). s([0'a, 0'', 0'b]). s([0'a, 92, 0'b]). s([0'a, 10, 0'b]).
s([0'a, 9, 0'b]). s([0'a, 13, 0'b]). s([7]). s([8]). s([11]). s([12]).
s([0'x, 7, 0'', 12, 0'y]).

wv(T) :-
    write(T), write(' | '), writeq(T), write(' | '), print(T), write(' | '),
    format("~w ~q ~p", [T, T, T]), write(' | '),
    write_term(T, [numbervars(true)]), write(' '),
    write_term(T, [quoted(true), numbervars(true)]), write(' '),
    write_term(T, [quoted(true)]), write(' '), write_term(T, []), write(' | '),
    format(atom(A), "~q", [T]), write(A), write(' | '),
    with_output_to(string(S), write(T)), string_length(S, N), write(N), write(' | '),
    writeln(T).

wa(T) :-
    write(T), write(' | '), writeq(T), write(' | '), print(T), write(' | '),
    format("~w ~q ~p", [T, T, T]), write(' | '),
    write_term(T, [quoted(true)]), write(' '), write_term(T, [quoted(false)]),
    write(' | '), with_output_to(string(S), writeq(T)), string_length(S, N),
    write(N), nl.

wc(T) :- write_canonical(T), nl.   % cocolint: W1 -- c/1 holds no operator, which both write alike

wq(T) :- term_to_atom(T, A), write(A), nl.

wo(T) :- writeq(T), write(' | '), print(T), write(' | '), write(T), write(' | '),
         format("~q ~w", [T, T]), write(' | '), write_term(T, [quoted(true)]), nl.

ws(Cs) :-
    string_codes(S, Cs), writeq(S), write(' | '), print(S), write(' | '),
    write(S), write(' | '), format("~q ~w", [S, S]), write(' | '),
    write_term(S, [quoted(true)]), nl.

main :-
    forall(v(T), wv(T)),
    forall(a(T), wa(T)),
    forall(c(T), wc(T)),
    forall(q(T), wq(T)),
    forall(o(T), wo(T)),
    forall(s(Cs), ws(Cs)),
    X = f(X, '$VAR'(1), 'a''b'), write(X), nl, writeq(X), nl,
    format("~w ~q~n", [X, X]),
    Y = [p, '$VAR'(3)|Y], write(Y), nl, writeq(Y), nl.
