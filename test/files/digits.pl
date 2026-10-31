%  Digit groups and radix numbers (cocolog 3.1.0), run by BOTH SWI-Prolog
%  and cocolog and the output compared byte for byte. A group is `_' and
%  any layout after it, comments too, or -- for a radix of ten or less --
%  exactly one space, each between two digits: in an integer, the integer
%  part of a float, both sides of a rational, a radix number and after
%  0x, 0o and 0b, never in a fraction or an exponent, and an integer that
%  came in groups takes no exponent without a fraction. `R'DIGITS' is a
%  number in radix R, from 2 to 36. Asked in this file's own text, in the
%  text term_to_atom/2 reads, and of the number readers: atom_number/2,
%  number_codes/2, name/2 and number_string/2 take groups and a radix and
%  refuse a character code with an escape. A syntax error is shown as
%  `syntax_error' alone, as the two word its reason apart.

main :- in_file, read_text, number_text.

%  a float with groups is asked of term_to_atom/2 alone: in a clause body
%  swipl 9.0.4 reads `1_0.5' as a dict's key on 10, a type error when it runs
in_file :-
    X1 = 1_000_000, print(underscore-X1), nl,
    X2 = 1 000 000, print(space-X2), nl,
    X3 = 1_000 000, print(mixed-X3), nl,
    X4 = 1_   000, print(underscore_spaces-X4), nl,
    X5 = 1_
         000, print(underscore_newline-X5), nl,
    X6 = 1_/* a comment */000, print(underscore_comment-X6), nl,
    X7 = 1_% a comment to the end of the line
         000, print(underscore_line_comment-X7), nl,
    X8 = 16'ff, print(radix16-X8), nl,
    X9 = 36'Zz, print(radix36-X9), nl,
    X10 = 2'1 0 1, print(radix2_spaced-X10), nl,
    X11 = 16'f_f, print(radix16_grouped-X11), nl,
    X12 = 0x1_f, print(hex_grouped-X12), nl,
    X14 = 1 000r3, print(rational_grouped-X14), nl,
    X15 = f(1 000, [2 000, 3_000]), print(in_a_term-X15), nl,
    X16 = 9 223 372 036 854 775 807, print(largest-X16), nl.

r(Text) :-
    catch(term_to_atom(X, Text), error(E, _), true),
    (   var(E) -> print(Text-X)
    ;   E = syntax_error(_) -> print(Text-syntax_error)
    ;   print(Text-E)
    ),
    nl.

read_text :-
    forall(member(T, ['1_000', '1 000', '1_ 000', '1_\n000', '1_%c\n000', '1_000_000', '1 000 000',
                      '1_00', '10 0', '0_1', '0 1', '1_000 000', '- 1_000', '-1_000',
                      '1_0.5', '1 0.5', '1_000.0', '1 0r3', '1_0r3', '1r3_0', '1r3 0', '1_000r3',
                      '16\'ff', '16\'FF', '2\'1010', '36\'zz', '8\'777', '10\'99', '10\'9 9',
                      '16\'f_f', '2\'1 0', '0x1_f', '0b1_0', '0b1 0', '0o7_7', '0o7 7',
                      '9 223 372 036 854 775 807', 'f(1 000)', '[1 000, 2]', 'a(0\'\\s)',
                      %% no group
                      '1  000', '1__000', '1_', '1 _000', '1_000_', '1_ _000', '1.5_0', '1.5 0',
                      '1.0e1_0', '1.0e1 0', '1e1_0', '1.5e+1_0', '1_0e2', '0x1 f', '0x_1',
                      %% no radix
                      '16\'f f', '11\'a a', '37\'1', '1\'1', '16\'g', '16\'', '00\'a', '0_\'a',
                      '2 \'10', '16 \'ff', '1_6\'ff', '1 6\'ff']),
           r(T)).

n(Label, Goal, X) :-
    catch(( Goal -> R = X ; R = no ), error(E, _),
          ( E = syntax_error(_) -> R = syntax_error ; R = E )),
    print(Label-R), nl.

number_text :-
    forall(member(T, ['1_000', '1 000', '16\'ff', '2\'1 0', '0x1_f', '0\'a', '0\'\'', '0\'\'\'',
                      '0\'\\n', '0\'\\x41\\', '-0\'\\e', ' 1_000', '1_000 ', '1_', '1.0_0']),
           ( atom_codes(T, Cs), string_codes(S, Cs),
             n(atom_number(T), atom_number(T, A), A),
             n(number_codes(T), number_codes(B, Cs), B),
             n(name(T), name(C, Cs), C),
             n(number_string(T), number_string(D, S), D) )).
