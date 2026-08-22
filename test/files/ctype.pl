%  code_type/2 and char_type/2, every category, every ASCII code.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  THIS EXISTS BECAUSE THE MANUAL AND THE IMPLEMENTATION DISAGREE. SWI's
%  documentation calls `alpha' "a letter or digit"; the implementation says
%  letters only. `to_upper(L)' reads as though L were the uppercase and it is
%  the lowercase. Neither could be got right by reading, so neither was: the
%  table below is what a running SWI answers, and this file is what keeps it
%  answering the same thing here.

plain([alnum, alpha, csym, csymf, ascii, white, cntrl, digit, graph, print,
       punct, space, end_of_line, newline, period, quote, lower, upper,
       prolog_var_start, prolog_atom_start, prolog_identifier_continue,
       prolog_symbol]).

%  Every code in 0..127 that is of type T, as one line.
codes_of(T) :-
    findall(C, (between(0, 127, C), code_type(C, T)), L),
    write(T), write(=), write(L), nl.

%  The categories that carry a value out. Only the codes that succeed appear,
%  so a category that matches nothing prints an empty list rather than failing.
pairs_of(T) :-
    findall(C-V, (between(0, 127, C), G =.. [T, V], code_type(C, G)), L),
    write(T), write(=), write(L), nl.

%  char_type/2 sees the same world through one-character atoms. Checked over
%  the printable range only, because a control character as an atom is not
%  something two systems have to agree on the spelling of.
chars_of(T) :-
    findall(Ch, (between(33, 126, C), char_code(Ch, C), char_type(Ch, T)), L),
    write(c(T)), write(=), write(L), nl.

main :-
    plain(Ts),
    forall(member(T, Ts), codes_of(T)),
    forall(member(T, [upper, lower, to_upper, to_lower, digit, xdigit]), pairs_of(T)),
    forall(member(T, [alpha, digit, punct, csym]), chars_of(T)),
    %  char_type/2 hands back a CHARACTER where code_type hands back a code
    ( char_type(a, to_upper(U)) -> write(a_to_upper(U)) ; write(no) ), nl,
    ( char_type('A', to_lower(L)) -> write(bigA_to_lower(L)) ; write(no) ), nl,
    ( char_type('7', digit(W)) -> write(seven_weight(W)) ; write(no) ), nl,
    %  and a category nobody has heard of is an error, not a quiet failure
    catch(code_type(0'a, no_such_type), error(E, _), true),
    ( var(E) -> write(no_error) ; write(E) ), nl.
