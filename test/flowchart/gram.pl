%% gram.pl -- grammar rules drawn as the predicates they are.

%% sum(+Codes, -Value): the value of an expression like "1+22+3"
sum(Codes, V) :-
    phrase(expr(V), Codes).

%% expr(-V)//
expr(V) --> term(A), rest(A, V).

%% rest(+Acc, -V)//
rest(A, V) --> "+", !, term(B), { C is A + B }, rest(C, V).
rest(V, V) --> [].

%% term(-N)//: one figure or more
term(N) --> figure(D), figures(Ds), { number_codes(N, [D|Ds]) }.

%% figures(-Ds)//
figures([D|Ds]) --> figure(D), !, figures(Ds).
figures([]) --> \+ figure(_).

%% figure(-D)//: a decimal digit -- named so as not to join dcg_basics'
%% digit//1, which is always loaded
figure(D) --> [D], { D >= 0'0, D =< 0'9 }.

%% peek(-C)//: the next code, left where it was
peek(C), [C] --> [C].
