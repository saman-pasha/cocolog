%  format/1,2,3.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
:- set_prolog_flag(double_quotes, codes).

f(F, A) :- format(F, A), nl.
s(F, A) :- format(atom(X), F, A), write(a(X)), nl.
c(F, A) :- format(codes(X), F, A), write(c(X)), nl.
d(F, A) :- format(codes(X, [0'!]), F, A), write(d(X)), nl.

main :-
    f("plain", []),
    f("~w", [foo(1)]),
    f("~q", ['hello world']),
    f("~w", ['hello world']),
    f("~a", [abc]),
    f("~s", [[104,105]]),
    f("~d", [1234]),
    f("~2d", [1234]),
    f("~4d", [7]),
    f("~D", [1234567]),
    f("~D", [-1234567]),
    f("~q", [[1,2,3]]),
    f("~w and ~w", [a,b]),
    f("~a", ['it''s']),
    f("~~", []),
    f("~e", [1.5]),
    f("~2f", [3.14159]),
    f("~g", [0.5]),
    f("~8r", [255]),
    f("~16r", [255]),
    f("~16R", [255]),
    f("~c", [65]),
    f("~3c", [65]),
    f("~*c", [3, 66]),
    f("~2n", []),
    f("~i~w", [skipped, shown]),
    %  a bare term where a list was expected is ONE argument
    f("~w", foo),

    %  ---- the three sinks ----
    s("~w-~w", [a,b]),
    c("hi", []),
    %  codes(H, T) is a DIFFERENCE list: the tail is what follows, not []
    d("hi", []),
    ( format(chars(Ch), "hi", []) -> write(ch(Ch)) ; write(no) ), nl,

    %  ---- errors ----
    ( catch(format("~w ~w", [only_one]), error(E1,_), true) -> true ; E1 = failed ),
    ( var(E1) -> write(no_error) ; write(caught) ), nl,
    true.
