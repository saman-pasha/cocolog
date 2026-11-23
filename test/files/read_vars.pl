:- encoding(utf8).

%% The reader's variables -- held to swipl 9.0.4 (cocolog 3.78.9).
%%
%% A variable is found by its name within the clause being read, `_' alone
%% anonymous. Since 3.78.9 the reader asks each recorded name by its key,
%% its length and its first two bytes, and compares the name only where the
%% key is the token's and the name is longer than the key holds: names that
%% share a key, a length and a first two bytes (`Xab', `Xac'; `Été', `Étè',
%% whose first character is two bytes) are told apart by the rest of them.
%% Each text is read with term_string/3, its named variables bound to their
%% places in variable_names (v(1), v(2), ...) and the rest to `_', so a name
%% taken for another shows as the other's; then the count of names, and a
%% clause of 100 variables read twice over, which its second half must share
%% with its first.

main :-
    forall(t(S), e(S)),
    many(100).

e(S) :-
    term_string(T, S, [variable_names(Vs)]),
    length(Vs, N),
    places(Vs, 1),
    term_variables(T, Rest),
    maplist(=('_'), Rest),
    print(N-T), nl.

places([], _).
places([_=v(I)|Vs], I) :- I1 is I + 1, places(Vs, I1).

t("f(X, Y, X)").
t("f(Xab, Xac, Xab, Xac)").
t("f(Xa, Xb, Xa, Xb, X)").
t("f(Ab, Ab, Ac, A, B)").
t("f(_, _, _A, _A, __, __)").
t("f(_ab, _ac, _ab)").
t("f(Abcdef1, Abcdef2, Abcdef1, Abcdef12)").
t("f(A, AB, ABC, A, AB, ABC)").
t("f(Été, Étè, Été, Étè)").
t("f(Éa, Éb, É, Éa)").
t("f(X1, X2, X10, X1, X2, X10)").
t("[H|T] = [T, H]").
t("p(X) :- q(X, Y), r(Y, Z), s(Z)").

%% a clause of N variables, each named twice
many(N) :-
    N1 is N - 1,
    numlist(0, N1, Is),
    maplist(vname, Is, As),
    atomic_list_concat(As, ',', S1),
    format(atom(S), 'f(~w,~w)', [S1, S1]),
    term_string(T, S, [variable_names(Vs)]),
    length(Vs, Count),
    T =.. [f|Args],
    length(Front, N),
    append(Front, Back, Args),
    ( Front == Back -> Shared = shared ; Shared = apart ),
    term_variables(T, Distinct),
    length(Distinct, D),
    print(many(Count, D, Shared)), nl.

vname(I, A) :- format(atom(A), 'V~d', [I]).
