%  write_term/2,3's max_depth(D), and format's ~W with it, as swipl 9.0.4's
%  pl-write.c applies it. Run by BOTH systems, output compared byte for
%  byte.
%
%  THE DEPTH: the term written is at depth 1 and each argument one deeper
%  -- a compound's, an operator's operands, a curly term's -- and a term
%  past D is `...'. A list's elements go one deeper each: the K-th of a
%  list at depth L is at L + K, and a list that would go past D ends
%  `|...]'. D of 0 is no limit; a negative D elides the term itself.
%  `...' is a token of symbol characters, so it takes the spaces an atom
%  of them would: `... + ...', `- ...', `a: ... : ...', and after an
%  infix operator that took a space before it one after it too.
%
%  A CYCLIC TERM under a limit is written to the limit, where without one
%  it is written as its factors, `@(S_1,[S_1=f(S_1)])'.
%
%  Through cocolog 3.48.3 the option was checked and read past, and every
%  term was written whole.

:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

w(T, D) :- write_term(T, [max_depth(D)]), nl.

terms([ [1,2,3,4,5,6,7,8,9,10],
        f(g(h(i(j(k))))),
        f(a,b,c,d,e),
        [a,[b,[c,[d]]]],
        f([1,2,3],[4,5,6]),
        1+2+3+4+5+6,
        1+(2+(3+(4+5))),
        - - - - a,
        \+ \+ \+ a,
        -(1),
        - (- (1)),
        1 - (-1),
        a = (b = c),
        (a :- b, c, d),
        (a , b , c , d),
        (a ; b -> c ; d),
        a mod (b mod (c mod d)),
        X is Y + 1 + 2,
        dynamic(f(x)),
        a:b:c:d,
        'hello world',
        [a|b],
        [a,b|c],
        [a|f(b)],
        [f(g(x))|y],
        {a,b,c},
        {f(g(h))},
        [[1,2,3],[4,5,6],[7,8,9]],
        '$VAR'(1),
        f('$VAR'(1)),
        f(1.5, -2, 3r4, "ab"),
        [],
        '[]',
        {},
        f(-),
        - (-),
        [-],
        @ + @,
        f(X, Y, X)
      ]) :- X = x, Y = y.

main :-
    terms(Ts),
    forall(member(D, [0, 1, 2, 3, 4, 5, 6, 10, -1, -5]),
           ( format("-- ~w~n", [D]),
             forall(member(T, Ts), w(T, D)) )),
    format("-- the other options~n"),
    write_term(['A'-'b c', "x"], [max_depth(2), quoted(true)]), nl,
    write_term(['A'-'b c', "x"], [max_depth(3), quoted(true)]), nl,
    write_term(f(1+2, [3,4,5]), [max_depth(3), ignore_ops(true)]), nl,
    write_term(f(1+2, [3,4,5]), [max_depth(3), spacing(next_argument)]), nl,
    write_term([1,2,3,4], [max_depth(3), spacing(next_argument)]), nl,
    write_term(f('$VAR'(1), g('$VAR'(27))), [max_depth(2), numbervars(true)]), nl,
    write_term(f('$VAR'(1), g('$VAR'(27))), [max_depth(3), numbervars(true)]), nl,
    write_term(a+b+c, [max_depth(2), priority(200)]), nl,
    write_term([1,2,3], [max_depth(2), max_depth(0)]), nl,
    write_term([1,2,3], [max_depth(0), max_depth(2)]), nl,
    format("-- ~~W~n"),
    format("~W~n", [[1,2,3,4], [max_depth(3)]]),
    format("<~W>~n", [f(g(h)), [max_depth(2)]]),
    format("-- a stream~n"),
    write_term(user_output, f(g(h(i))), [max_depth(2)]), nl(user_output),
    format("-- cycles~n"),
    C1 = f(C1), write_term(C1, [max_depth(4)]), nl,
    C2 = [a|C2], write_term(C2, [max_depth(5)]), nl,
    C3 = g(C3, [C3]), write_term(C3, [max_depth(3)]), nl,
    C4 = f(C4), write(C4), nl,
    format("-- the option's errors~n"),
    forall(member(O, [max_depth(a), max_depth(1.5), max_depth(_), max_depth(f(1)),
                      max_depth(2147483648), max_depth(-2147483649), priority(2147483648),
                      max_depth(2147483647), max_depth(-2147483648)]),
           ( catch(write_term(x, [O]), E, true),
             ( var(E) -> nl, writeln(no_error)
             ; E = error(F, _), print_message_formal(F) ) )),
    %% the first option that is wrong is the error, as swipl's scan_options()
    catch(write_term(x, [max_depth(10000000000), max_depth(a)]), error(F2, _), true),
    print_message_formal(F2),
    catch(format("~W", [x, [max_depth(10000000000)]]), error(F3, _), true),
    print_message_formal(F3),
    format("-- write/1 and print/1 have no limit~n"),
    write([1,2,3,4,5,6,7,8,9,10,11,12]), nl,
    print(f(g(h(i(j(k(l))))))), nl.

print_message_formal(F) :- writeq(F), nl.
