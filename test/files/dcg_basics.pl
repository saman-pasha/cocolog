%  SWI's library(dcg/basics), run UNMODIFIED under both systems.
%
%  Under SWI the library is loaded from its own installation; under cocolog the
%  copy in lib/swipl/ is consulted first (see test/files/run.sh). If the
%  two ever disagree, either the copy has drifted from upstream or cocolog is
%  not running it faithfully -- and this file is the only thing that would say
%  so.
:- set_prolog_flag(double_quotes, codes).

%  SWI loads the library from its own installation; cocolog accepts this
%  directive and ignores it, because the vendored copy has already been
%  consulted from the command line. One line, honoured by one and tolerated by
%  the other, is what lets the rest of the file be identical.
:- use_module(library(dcg/basics)).

p(Label, G, Input) :-
    ( phrase(G, Input, Rest)
    ->  write(Label), write(' -> '), write(Rest), nl
    ;   write(Label), write(' -> no'), nl ).

v(Label, G, Input) :-
    ( phrase(G, Input, [])
    ->  write(Label), write(' = '), write(G), nl
    ;   write(Label), write(' -> no'), nl ).

main :-
    %  ---- whitespace ----
    p(white,   white,   " x"),
    p(whites,  whites,  "   x"),
    p(blanks,  blanks,  " \n\t x"),
    p(blank,   blank,   "\tx"),
    p(nonblanks, nonblanks(_), "abc def"),
    p(blanks_to_nl, blanks_to_nl, "   \n rest"),

    %  ---- numbers ----
    v(digits,  digits([0'1,0'2,0'3]), "123"),
    v(digit,   digit(0'7), "7"),
    v(integer, integer(42), "42"),
    v(integer_neg, integer(-42), "-42"),
    v(float,   float(3.5), "3.5"),
    v(number,  number(17), "17"),
    v(number_f, number(2.5), "2.5"),
    v(xdigit,  xdigit(15), "f"),
    v(xdigits, xdigits([1,10]), "1a"),
    v(xinteger, xinteger(255), "ff"),

    %  the same predicates read back OUT, which is what makes them bidirectional
    ( phrase(integer(123), C1, []) -> write(gen_integer(C1)) ; write(no) ), nl,
    ( phrase(number(4.5), C2, []) -> write(gen_number(C2)) ; write(no) ), nl,

    %  ---- strings ----
    ( phrase(string(S1), "ab", []) -> write(string(S1)) ; write(no) ), nl,
    ( phrase((string(S2), ":", remainder(R2)), "key:value") -> write(S2-R2) ; write(no) ), nl,
    ( phrase(string_without(":", S3), "key:value", _) -> write(without(S3)) ; write(no) ), nl,
    ( phrase(prolog_var_name(N1), "Foo", []) -> write(varname(N1)) ; write(no) ), nl,
    ( phrase(prolog_var_name(_), "foo", []) -> write(varname_lower_y) ; write(varname_lower_n) ), nl,
    ( phrase(alpha_to_lower(A1), "A", []) -> write(lowered(A1)) ; write(no) ), nl,

    %  ---- end of line ----
    p(eol_n,  eol, "\nrest"),
    p(eol_rn, eol, "\r\nrest"),
    ( phrase(eos, [], []) -> write(eos_y) ; write(eos_n) ), nl,

    %  ---- one real grammar built out of them ----
    ( phrase(pairs(Ps), "a=1,b=22,c=333") -> write(Ps) ; write(no) ), nl,
    true.

%  key=value pairs, the sort of thing the library exists for
pairs([K-V|T]) --> key(K), "=", integer(V), ( "," -> pairs(T) ; { T = [] } ).
key(K) --> string_without("=", Cs), { atom_codes(K, Cs) }.
