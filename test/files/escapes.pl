%  Escapes in quoted text (cocolog 3.1.0), run by BOTH SWI-Prolog and
%  cocolog and the output compared byte for byte: `\xHEX\' and `\OCTAL\'
%  with any number of digits and the closing backslash optional, `\uXXXX',
%  `\UXXXXXXXX', `\e', `\s', a backquote, a backslash before a newline and
%  `\c' -- in this file's own text and in the text term_to_atom/2 reads --
%  text in backquotes, which is codes, and what a quoted write escapes and
%  how. Text is shown as its codes, so that nothing past ASCII is written:
%  past it swipl's quoted write is the locale's. A syntax error is shown as
%  `syntax_error' alone, as the two word its reason apart. NUL is not
%  asked: an atom here is a C string.

main :- in_file, read_text, backquoted, written.

%  X's codes when it is text, else X itself: a string in swipl, where
%  `"..."' is one, and a list of codes here
show(Label, X) :-
    (   atom(X) -> atom_codes(X, C)
    ;   string(X) -> string_codes(X, C)
    ;   C = X
    ),
    print(Label-C), nl.

in_file :-
    show(hex, 'a\x41\b'),
    show(hex_open, 'a\x41'),
    show(hex_long, '\x0041\'),
    show(hex_lower, '\xab\'),
    show(hex_upper, '\xAB\'),
    show(hex_top, '\x10FFFF\'),
    show(hex_emoji, '\x1F600\'),
    show(octal, '\101\'),
    show(octal_open, '\101'),
    show(octal_long, '\777\'),
    show(octal_one, '\1\'),
    show(octal_short, '\7'),
    show(del, '\x7f\'),
    show(esc, '\e'),
    show(space, '\s'),
    show(backquote, '\`'),
    show(u4, '\u0041'),
    show(u8, '\U0001F600'),
    show(lettered, '\a\b\f\n\r\t\v'),
    show(continued, 'a\
b'),
    show(skip_layout, 'c\c    d'),
    show(skip_lines, 'e\c
f'),
    show(string, "s\x41\t"),
    show(code_hex, 0'\x41\),
    show(code_octal, 0'\101\),
    show(code_esc, 0'\e),
    show(code_space, 0'\s),
    show(code_u, 0'\u0041),
    show(code_backslash, 0'\\).

r(Label, Text) :-
    catch(term_to_atom(X, Text), error(E, _), true),
    (   var(E) -> show(Label, X)
    ;   E = syntax_error(_) -> print(Label-syntax_error), nl
    ;   print(Label-E), nl
    ).

read_text :-
    r(t_hex, '\'\\x41\\\''),
    r(t_hex_open, '\'\\x41\''),
    r(t_hex_none, '\'\\x\\\''),
    r(t_hex_then_letter, '\'\\x4g\\\''),
    r(t_hex_past, '\'\\x110000\\\''),
    r(t_hex_surrogate, '\'\\xD800\\\''),
    r(t_octal, '\'\\101\\\''),
    r(t_octal_stops, '\'\\18\''),
    r(t_u_short, '\'\\u004\''),
    r(t_u_surrogate, '\'\\uD800\''),
    r(t_u_escaped_byte, '\'\\uDC80\''),
    r(t_u8_past, '\'\\U00110000\''),
    r(t_z, '\'\\z\''),
    r(t_d, '\'\\d\''),
    r(t_capital_n, '\'\\N\''),
    r(t_capital_x, '\'\\X41\\\''),
    r(t_continued, '\'a\\\nb\''),
    r(t_skip, '\'c\\c \n d\''),
    r(t_code_hex, '0\'\\x41\\'),
    r(t_code_newline, '0\'\\\n'),
    r(t_code_quote, '0\'\''),
    r(t_code_quote3, '0\'\'\''),
    r(t_code_in_term, 'f(0\'\\s, 0\'\\e)'),
    r(t_string, '"\\x41\\\\u0042\\103\\"').

backquoted :-
    show(bq, `abc`),
    show(bq_escaped, `a\x41\b`),
    show(bq_doubled, `it``s`),
    show(bq_empty, ``),
    ( `abc` == [97, 98, 99] -> show(bq_codes, yes) ; show(bq_codes, no) ),
    under_atom_flag(D, B),
    ( atom(D) -> show(dq_atom_flag, yes) ; show(dq_atom_flag, no) ),
    ( B == [97, 98] -> show(bq_atom_flag, yes) ; show(bq_atom_flag, no) ),
    r(t_bq, '`x\\`y`'),
    r(t_bq_term, 'f(`ab`, c)').

%  each code after an `a', in each quoted writer: the ones with a letter,
%  and the ones escaped by their code in every locale -- a control with no
%  letter, DEL, a C1 control and a surrogate
written :-
    forall(member(C, [1, 7, 8, 9, 10, 11, 12, 13, 27, 31, 32, 39, 92, 127,
                      0x80, 0x85, 0x9F, 0xD800, 0xDC80, 0xDFFF]),
           ( atom_codes(A, [0x61, C]), string_codes(S, [C]),
             format("~d: ", [C]),
             writeq(A), write(' '), print(A), write(' '), write_canonical(A), write(' '),
             format("~q ~p", [A, A]), write(' '), write_term(A, [quoted(true)]), write(' '),
             writeq(S), write(' '), print(S), write(' '), write_canonical(S), write(' '),
             format("~q", [S]), nl )),
    atom_codes(F, [0x66, 1]), T = f(F, [F], 'x y'),
    writeq(T), nl, print(T), nl.

%  text in backquotes is codes whatever the double_quotes flag says: from
%  here to the end of the file `"..."' is an atom, and `...` codes still
:- set_prolog_flag(double_quotes, atom).

under_atom_flag("ab", `ab`).
