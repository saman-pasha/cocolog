:- use_module(library(stream)).

main :-
    read_stream_to_codes(user_input, Cs),
    split_string(Cs, "\n", "", Lines),
    forall(( member(L, Lines), string_codes(L, Codes), Codes \== [] ), cl_line(Codes)).

cl_line(Codes) :-
    (   catch(( cl_tokens(Codes, Ts), phrase(cl_expr(V), Ts) ),
              error(evaluation_error(zero_divisor), _), fail)
    ->  format("~d~n", [V])
    ;   format("error~n")
    ).

cl_tokens([], []).
cl_tokens([32|Cs], Ts) :- !, cl_tokens(Cs, Ts).
cl_tokens([C|Cs], [n(N)|Ts]) :-
    cl_digit(C), !,
    cl_digits(Cs, Ds, Rest),
    number_codes(N, [C|Ds]),
    cl_tokens(Rest, Ts).
cl_tokens([C|Cs], [C|Ts]) :- memberchk(C, "+-*/()"), cl_tokens(Cs, Ts).

cl_digits([C|Cs], [C|Ds], Rest) :- cl_digit(C), !, cl_digits(Cs, Ds, Rest).
cl_digits(Rest, [], Rest).

cl_digit(C) :- C >= 0'0, C =< 0'9.

cl_expr(V) --> cl_term(T), cl_expr_rest(T, V).

cl_expr_rest(A, V) --> [0'+], !, cl_term(T), { B is A + T }, cl_expr_rest(B, V).
cl_expr_rest(A, V) --> [0'-], !, cl_term(T), { B is A - T }, cl_expr_rest(B, V).
cl_expr_rest(V, V) --> [].

cl_term(V) --> cl_unary(F), cl_term_rest(F, V).

cl_term_rest(A, V) --> [0'*], !, cl_unary(F), { B is A * F }, cl_term_rest(B, V).
cl_term_rest(A, V) --> [0'/], !, cl_unary(F), { B is A // F }, cl_term_rest(B, V).
cl_term_rest(V, V) --> [].

cl_unary(V) --> [0'-], !, cl_unary(U), { V is -U }.
cl_unary(V) --> [0'(], !, cl_expr(V), [0')].
cl_unary(N) --> [n(N)].
