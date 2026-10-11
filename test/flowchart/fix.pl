%% fix.pl -- what the fixed point and the call patterns must get right.

%% top(+L, -R)
top(L, R) :-
    rev(L, R0),
    size(R0, N),
    size(K, N),
    evenp(N),
    ( spin(K) -> true ; true ),
    R = R0-K.

%% rev(+L, -R): an accumulator
rev(L, R) :- rev(L, [], R).
rev([], A, A).
rev([H|T], A, R) :- rev(T, [H|A], R).

%% size(?L, ?N): called both ways
size([], 0).
size([_|T], N) :- size(T, N0), N is N0 + 1.

%% evenp(+N), oddp(+N): each through the other
evenp(0).
evenp(N) :- N > 0, M is N - 1, oddp(M).
oddp(N) :- N > 0, M is N - 1, evenp(M).

%% spin(?X): never succeeds
spin(X) :- spin(X).
