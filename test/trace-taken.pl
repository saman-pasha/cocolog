%% Names a program file takes over, called through `system:' -- the
%% system's own definition, its ports as swipl prints them (test/trace.pl,
%% 3.58.1): one call, its Exit, its Redo on the call itself, and none of
%% what the system's clauses call. last/2 and reverse/2 are taken before
%% the file's first directive reads the libraries, length/2, nth0/3 and
%% msort/2 after it.

last(_, mine).
reverse(_, mine).
:- redefine_system_predicate(length(_, _)).
length(_, mine).
nth0(_, _, mine).
:- redefine_system_predicate(msort(_, _)).
msort(_, mine).

tk1(X) :- system:last([a, b, c], X).
tk2(L-X) :- L = [a|_], system:last(L, X).
tk3(X) :- system:reverse(X, [a, b]).
tk4(L-N) :- system:length(L, N), N >= 1, !.
tk5(I-E) :- system:nth0(I, [a, b], E), I > 0.
tk6(N) :- system:length([a, b], N).
tk7(X) :- system:msort([b, a], X).
tk8(X) :- system:nth0(X, [a, b], c).
tk9(M-N) :- length([a], M), system:length([a], N).
