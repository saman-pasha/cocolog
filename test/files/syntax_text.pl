%% A text that will not read, held to swipl 9.0.4 (cocolog 3.10.0).
%%
%% term_to_atom/2, term_string/2, atom_to_term/3 and read_term_from_atom/3
%% read one term from a text as swipl's pl-read.c reads it: first a raw
%% read of the clause's text (raw_read2), which refuses a text that ends in
%% a quoted item or a block comment, `0'' at the end, and a full stop with
%% nothing before it; then the parse. What will not read raises
%% error(syntax_error(Id), string(Raw, Pos)): Id swipl's -- one of its
%% atoms, punct(Op, Next), undefined_char_escape(C) or
%% end_of_file_in_quoted(Q) -- Raw the text as the raw read made it (layout
%% before the term gone, each comment a space a character, a full stop put
%% at the end of a text that has none: `a b' is "a b . "), and Pos the
%% characters of Raw before the token the read failed at, less one. A full
%% stop ends the read: `a. b' is a, what follows not read. Through 3.9.0
%% the ball was syntax_error(Id) with the predicate's context, Id one of
%% three, and `a. b' was operator_expected.
%%
%% print_message/2 of such an error says swipl's sentence and then the text
%% before Pos, `** here **' and the rest, a line each.
%%
%% Each line is r(Text, What): ok(Term) for a ground term, ok_var for one
%% with a variable (the two systems name variables apart), or the ball.
%% Left out, stated in COMPAT.md: a letter past ASCII outside quotes,
%% swipl's dicts (`a.b', `1.e'), `[|]', an integer past 64 bits, and
%% `\+ = a' and `dynamic ; a', which both refuse with the id, at another
%% place.

:- set_prolog_flag(double_quotes, codes).

r(T) :-
    catch(( term_to_atom(X, T), ( ground(X) -> E = ok(X) ; E = ok_var ) ), E, true),
    print(r(T, E)), nl.

msg(T) :-
    catch(term_to_atom(_, T), E, true),
    flush_output,
    print_message(error, E).

texts([ 'foo(', 'a b', 'f(,)', '1 +', ')', '"abc', '0\'', 'f(a', '[1,2', '{a',
        'a)', 'f(a b)', '- - -', 'X = ', '\'abc', 'f(a)) ', 'a :- :- b',
        '[a|b|c]', '0x', '1e', '\'\\q\'', 'a,', '"', '(', '[', 'f(a,)',
        'p :- ', ':- :-', 'a = = b',
        %% layout and comments in the raw text
        'a  b', 'a\tb', 'a % c\n b', 'a /* c */ b', 'f(  a', 'f(\na b', '  a b',
        'a b  ', 'a b.', 'a b. ', 'foo(.', 'a b.c', '"a  b" c', 'x(\'a  b\' c)',
        'a b % x', 'f(a,\n\n b c)', 'e(4) % comment\n f', 'e(4) %c\nf',
        'e(4)\n f', 'e(4) /* c */ f', 'e(4) %\n', 'a /* c\n d */ b',
        'f(a /* x\ny */ b c)',
        %% where a term stops, and what may follow it
        'f(a,', '[a,', '{a,', 'a |', 'f(a]', 'f(a}', '[a)', '(a', '(a]',
        '[a|b,c]', '[a|]', 'f(a,,b)', 'f(|)', 'a. b', 'f("abc', 'a \'bc',
        'x `bc', '% c\na b', '/* c */ a b', '0\'\\q', '0b2', '0o9', '0\'ab',
        '1.0e', '1.0ex', 'a.', '.', ' ', '', 'f(a)b', '[a]b', '{a}b', '"s"b',
        '- (', 'f(- )', '\\+', 'a :- b :- c', '- - a b', 'X Y', '_ a', '1 2',
        '1.5 a', '"a" "b"', 'a(', 'a , b', 'a , ', ', a', '| a', 'a ;', '[a,]',
        '{}x', 'f(a)(b)', 'a + + b', 'a - b c', 'f(;)', '[;]', '0\' ', '0\'\\',
        '\'\\', '"\\', '1 r 2', '1r', '"a\\qb"', '`a\\qb`', 'a. b c', 'a.  ',
        'a.%x', 'a./*x*/b',
        %% the raw read's refusals
        '/* abc', 'a /* abc', 'a b "c', 'a b /* c', 'ab "c', '  "abc', 'ab \'c d',
        'f(0\'', '16\'', '16\'g', '36\'',
        %% operators
        'a = b = c', 'x :- a = b = c', 'a :- b ,', 'a :- b ;', '(a ;)', '(a,)',
        'f((a;))', '- - - a :- b :- c', 'a b.%x', 'a - - - b c', 'a := b',
        'a | b', '- a b', '\\+ a b', 'f(a :- b :- c)', '[a :- b :- c]',
        'a = (b :- c :- d)', 'f(a = ', '(a ,', '[a = ', 'f(a = , b)', '- | a',
        '()', '{,}', 'f(a :- b , )', '(a :- b ;)', '[a ;]', '{a ;}', '[a|b ;]',
        'f(a ; b ,)', 'a =. ', 'a =..', 'x :- a =.. ', 'a = \\+ b', 'a = - b',
        'f(:- a)', '[:- a]', 'a :- \\+ b :- c', 'x = f(a + b) = c',
        'a - (b :- c :- d)', '- - :- a', 'a , :- b', 'a :- (:- b)', '- 1 2',
        'f(:- a ; )', '(:- a , )', 'f(dynamic a ; )', 'f(?- a , b ; )',
        '[a = )', 'f(a = ]', '{a ; )', '(a , ]',
        %% numbers
        '1.0e400', '1.0e-400', '-1.0e400', '1.0NaN', '2.5NaN', '0.5NaN',
        '1.99NaN', '2.0NaN', '1.0Inf', '2.0Inf', '0.5Inf', '-1.0Inf',
        '1.0e10Inf', '1.5e3NaN', '1e5', '1.0e+', '1_', '1__0', '1.5e', '1r0',
        'f(2r0)', '- 3r0',
        %% quoted items and escapes
        '\'\\x\'', '\'\\xZ\\\'', '\'\\u12\'', '\'\\uD800\'', '\'\\x110000\\\'',
        '\'\\777777777\\\'', '\'a\nb\'', '"a\nb"', '\'\\\nb\'', 'a\\', 'a\x01\b',
        '\'\\e\\z\'', '\'a\\', '"\\x41"', '\'\\x4g\\\'', 'f(a)%c', 'a\nb',
        'a.\nb', '- (a', 'f(a.', 'a (b', 'f(a, b', '[a, b', 'f(a) .', '"abc"x',
        '0\'\\n', '0\'\'', '0\'\'\'', '0\'\'\' a', 'f(0\'\'\', a b)', '0\'\\c','0\'\\c x', '0\'\\c  ',
        '0\'\\s', '0\'\\e', '0\'\\x41\\', '0\'\\101\\', '0\'\\x41', '0\'\\\n',
        '0\'\\c\n', 'f(0\'\\c)', '0\'\\d', '0\'\\v', '0\'\\0\\', '0\'\\z',
        'f(a', 'f(a,b', 'f(\n\na', '[1,2|3', '[a|b', '{a,b', '(a,b',
        'f(0x)', '0\'\\c\n',
        %% the raw read's 0' and radix quotes, a backslash closing nothing
        'f(0\'\\\')', '16\'ff', 'f(16\'ff)', 'x16\'ff\'', '..', 'f(.., a)', 'a ..b',
        'f(0\'\\\'x)', '0\'\\\'', '\'a\\c  b\'', '\'a\\c\'', '\'a\\\n\'',
        '\'\\x41\\\'', 'f(\'\\101\\\')', '"\\x41\\"', '2\'01', '2\'2', 'a2\'01' ]).

%% A CHARACTER PAST ASCII IS ONE, in Pos and as a comment's space. The
%% texts are written with escapes and the raw text said as its codes: the
%% swipl this case runs reads and writes no UTF-8 (a POSIX locale), where
%% swipl under C.UTF-8 says the same.
rc(T) :-
    catch(term_to_atom(_, T), E, true),
    (   E = error(syntax_error(Id), string(S, P))
    ->  string_codes(S, Cs), print(rc(Id, Cs, P))
    ;   print(rc(E))
    ),
    nl.

wide([ 'f(\'\xE9\\' b)', 'a /* \xE9\ */ b', 'a % \xE9\\n b', 'f(\'\xE9\\xE9\\',\n x y)',
       '"\xE9\" x', '\'\xE9\' ]).

main :-
    texts(Ts),
    forall(member(T, Ts), r(T)),
    wide(Ws), forall(member(W, Ws), rc(W)),
    %% the other three readers, the same raise
    catch(term_string(_, "a  b"), E2, true), print(E2), nl,
    catch(read_term_from_atom('a  b', _, []), E3, true), print(E3), nl,
    catch(atom_to_term('a  b', _, _), E4, true), print(E4), nl,
    catch(term_to_atom(_, "a b"), E5, true), print(E5), nl,
    catch(( term_string(X6, "a. b"), E6 = ok(X6) ), E6, true), print(E6), nl,
    catch(( read_term_from_atom('a. b', X7, []), E7 = ok(X7) ), E7, true), print(E7), nl,
    catch(( atom_to_term('f(X, Y). b', T8, B8), length(B8, N8), E8 = ok(T8, N8) ), E8, true),
    ( E8 = ok(f(P8, Q8), 2), var(P8), var(Q8), P8 \== Q8 -> print(atom_to_term_binds) ; print(E8) ), nl,
    %% and each said as swipl says it
    forall(member(T, [ 'a b', 'f(,)', 'a :- :- b', '"abc', '\'abc', 'a /* c', 'a,',
                       ')', '[a|b|c]', 'f(\n\na b', 'a = b = c', '\'\\q\'',
                       '\'\\u12\'', '0\'', '1.0e400', '.', 'a b "c' ]),
           msg(T)).
