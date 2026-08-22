%  SWI's library(dcg/high_order), run UNMODIFIED under both systems.
%  Its `sequence//5' is the one place in either vendored file that uses the
%  soft cut, so this is also what holds `*->' to SWI's behaviour.
:- set_prolog_flag(double_quotes, codes).
:- use_module(library(dcg/high_order)).
:- use_module(library(dcg/basics)).

digit_(D) --> [D], { code_type(D, digit) }.
comma --> ",".

main :-
    ( phrase(sequence(digit_, Ds), "123") -> write(Ds) ; write(no) ), nl,
    ( phrase(sequence(digit_, comma, Ds2), "1,2,3") -> write(Ds2) ; write(no) ), nl,
    ( phrase(sequence(digit_, comma, Ds3), "1") -> write(Ds3) ; write(no) ), nl,
    ( phrase(sequence(digit_, comma, Ds4), "") -> write(Ds4) ; write(no) ), nl,
    ( phrase(sequence("(", digit_, comma, ")", Ds5), "(1,2)") -> write(Ds5) ; write(no) ), nl,
    ( phrase(sequence("(", digit_, comma, ")", _), "1,2") -> write(y) ; write(n) ), nl,

    %  and the same predicates generating rather than parsing
    ( phrase(sequence(digit_, [0'7,0'8]), G1, []) -> write(gen(G1)) ; write(no) ), nl,
    ( phrase(sequence(digit_, comma, [0'7,0'8]), G2, []) -> write(gen(G2)) ; write(no) ), nl,

    ( phrase(optional(digit_(D1), {D1 = 0'z}), "5") -> write(opt(D1)) ; write(no) ), nl,
    ( phrase(optional(digit_(D2), {D2 = 0'z}), "a", R2) -> write(opt(D2)-R2) ; write(no) ), nl,

    ( phrase(foreach(member(X, [0'a,0'b]), [X]), "ab") -> write(fe_y) ; write(fe_n) ), nl,
    ( phrase(foreach(member(Y, [0'a,0'b]), [Y]), "ac") -> write(fe_y) ; write(fe_n) ), nl,
    true.
