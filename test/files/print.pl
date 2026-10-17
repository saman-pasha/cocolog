%  print/1 and format/2's ~p, which calls it: quoted, as writeq/1 is, and
%  with numbervars, so '$VAR'(N) is written as the variable it names. Run
%  by BOTH systems, output compared byte for byte.
%
%  An integer N of 0 or more is the letter N mod 26 and, past the first 26,
%  N // 26 after it; a negative one is S_ and its magnitude; an atom that
%  reads as a variable is itself, unquoted; anything else is the compound it
%  is. Through cocolog 2.2.3 print/1 and ~p were write/1 and ~w, and
%  print('a b') read back as two words. Left out: an atom with a quote in
%  it, which test/files/write.pl holds (print/1 writes 'don\'t' since
%  cocolog 2.2.5, 'don''t' through 2.2.4), non-ASCII text, a portray/1
%  hook, which cocolog's print/1 does not call, and print/2, which needs
%  library(stream) here.

t('a b'). t('X'). t({}). t(hello). t('Hello'). t('\n'). t(''). t('$VAR').
t('a b' + 'c d'). t(f(',', '|')). t(f(;)). t(f(:-)). t((a :- b)). t((a ; b)).
t([a|b]). t({a, b}). t(f('A')). t('{}'(x)). t(['A', b, 'c d']). t(\+ a).
t('/*'). t('.'(a)). t('.'). t(a = \+). t(- (-)). t(f(a, -)). t([-]).
t(- 1). t(+(1)). t(a - (-1)). t(1 - 2 - 3). t(1 - (2 - 3)). t(2 ** -1).
t(1.0). t(-0.0). t(1.0Inf). t(1.5NaN). t(0'a). t(9223372036854775807).
t('$VAR'(0)). t('$VAR'(1)). t('$VAR'(25)). t('$VAR'(26)). t('$VAR'(27)).
t('$VAR'(52)). t('$VAR'(1000000)). t('$VAR'(9223372036854775807)).
t('$VAR'(-1)). t('$VAR'(-5)). t('$VAR'(-9223372036854775807)). t('$VAR'(-9223372036854775808)).
t('$VAR'('Foo')). t('$VAR'('X1_y')). t('$VAR'('_')). t('$VAR'('_x')).
t('$VAR'('_G1')). t('$VAR'(x)). t('$VAR'('Foo bar')). t('$VAR'('1A')).
t('$VAR'('F-o')). t('$VAR'(1.5)). t('$VAR'(f(x))). t('$VAR'([])).
t('$VAR'(1, 2)). t('$VAR'('$VAR'(1))).
t(f('$VAR'(0), '$VAR'(1))). t('$VAR'(0) + '$VAR'(1)). t(- '$VAR'(1)).
t('$VAR'(1) - '$VAR'(2)). t('$VAR'(1) ^ 2). t(['$VAR'(0), '$VAR'(1)]).
t(f('$VAR'(3))). t({'$VAR'(0)}). t(('$VAR'(0) :- '$VAR'(1))).
t('$VAR'('Foo') + 'a b'). t(- '$VAR'('Foo')). t(\+ '$VAR'(0)).
t(a - '$VAR'(-1)). t('$VAR'(-1) - a). t(- '$VAR'(-1)). t(['$VAR'(0)|'$VAR'(1)]).

s(T) :-
    print(T), write('  '), format("~p", [T]), write('  '),
    with_output_to(string(S), print(T)), string_length(S, N), write(N), nl.

main :-
    forall(t(T), s(T)),
    X = f(X, '$VAR'(1), 'a b'), print(X), nl, format("~p~n", [X]),
    Y = [a, 'B'|Y], print(Y), nl,
    atom_string(abc, Str), print(Str), nl.
