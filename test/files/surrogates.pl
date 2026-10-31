%  Lone surrogates in text made from codes, run by BOTH SWI-Prolog and
%  cocolog and the output compared byte for byte: atom_codes(A, [0xD800])
%  makes an atom of one character, which goes back to the code it came
%  from, and a pair of surrogates stays two characters; char_code/2 takes
%  no surrogate for a character's code. Only codes and lengths are shown:
%  a quoted write of such a character is the locale's in swipl.

r(Label, Goal, Show) :-
    catch(( Goal -> R = Show ; R = no ), E, R = ex(E)),
    copy_term(Label-R, C), term_variables(C, Vs), bindv(Vs), print(C), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

main :- atoms, strings, refused.

atoms :-
    r(one, (atom_codes(A1, [0xD800]), atom_length(A1, N1), atom_codes(A1, C1)), N1-C1),
    r(middle, (atom_codes(A2, [0x61, 0xDFFF, 0x62]), atom_length(A2, N2), atom_codes(A2, C2)), N2-C2),
    r(pair, (atom_codes(A3, [0xD83D, 0xDE00]), atom_length(A3, N3), atom_codes(A3, C3)), N3-C3),
    r(escaped_byte, (atom_codes(A4, [0xDC80]), atom_length(A4, N4), atom_codes(A4, C4)), N4-C4),
    r(last_escaped, (atom_codes(A5, [0xDCFF]), atom_length(A5, N5), atom_codes(A5, C5)), N5-C5),
    r(around_escaped, (atom_codes(A6, [0xDC7F, 0xDD00]), atom_length(A6, N6), atom_codes(A6, C6)), N6-C6),
    r(chars, (atom_codes(A7, [0xD800, 0x61]), atom_chars(A7, L7), length(L7, N7),
              L7 = [F7|_], char_code(F7, K7)), N7-K7),
    r(from_chars, (atom_codes(A8, [0xDBFF]), atom_chars(A8, L8), atom_chars(B8, [x|L8]),
                   atom_codes(B8, C8)), C8),
    r(sub_first, (atom_codes(A9, [0xD800, 0x61]), sub_atom(A9, 0, 1, After9, S9), atom_codes(S9, C9)), After9-C9),
    r(sub_second, (atom_codes(A10, [0xD800, 0x61]), sub_atom(A10, 1, 1, _, S10), atom_codes(S10, C10)), C10),
    r(concat, (atom_codes(A11, [0x61, 0xD800]), atom_concat(A11, b, R11), atom_codes(R11, C11)), C11),
    %  atom_concat/3 splitting such an atom, and sub_string/5 over such a
    %  string, raise representation_error(code_point) in swipl 9.0.4 (the
    %  first "did not clear exception"): not asked
    r(equal, (atom_codes(A13, [0xD800]), atom_codes(B13, [0xD800]), A13 == B13), yes),
    r(apart, (atom_codes(A14, [0xD800]), atom_codes(B14, [0xD801]), compare(O14, A14, B14)), O14),
    r(order, (atom_codes(D15, [0xD800]), atom_codes(E15, [0x1F600]), atom_codes(F15, [0xE000]),
              msort([D15, a, E15, z, F15], L15), maplist(atom_codes, L15, C15)), C15),
    r(codes_back, (numlist(0xD7FE, 0xE001, L16), atom_codes(A16, L16), atom_codes(A16, C16), C16 == L16,
                   atom_length(A16, N16)), N16).

strings :-
    r(string, (string_codes(S1, [0xDC00]), string_length(S1, N1), string_codes(S1, C1)), N1-C1),
    r(string_atom, (atom_codes(A2, [0xD800]), atom_string(A2, S2), string_codes(S2, C2)), C2),
    r(string_code, (string_codes(S3, [0x61, 0xDABC]), string_code(2, S3, K3)), K3),
    r(split_string, (string_codes(S4, [0x61, 0xD800, 0x62]), string_codes(Sep4, [0xD800]),
                     split_string(S4, Sep4, "", P4), maplist(string_codes, P4, C4)), C4),
    r(string_concat, (string_codes(S6, [0xDFFF]), string_concat(S6, S6, T6), string_length(T6, N6),
                      string_codes(T6, C6)), N6-C6).

refused :-
    r(char_code_d800, char_code(_, 0xD800), yes),
    r(char_code_dc80, char_code(_, 0xDC80), yes),
    r(char_code_dfff, char_code(_, 0xDFFF), yes),
    r(char_code_d7ff, (char_code(C1, 0xD7FF), char_code(C1, K1)), K1),
    r(char_code_e000, (char_code(C2, 0xE000), char_code(C2, K2)), K2),
    r(number_codes, number_codes(_, [0xD800]), yes),
    r(atom_number, (atom_codes(A3, [0x31, 0xD800]), atom_number(A3, _)), yes).
