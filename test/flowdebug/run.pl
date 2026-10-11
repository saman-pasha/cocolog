%% test/flowdebug.pl's program: each way control moves through a clause, to
%% be run, recorded and matched to its chart -- an if-then-else both ways,
%% a disjunction's second branch, \+, findall/3, one predicate called twice
%% in a clause, a redo, an exception caught, a run that fails, a recursion
%% deep enough to be seen through a window, and a run that is not the same
%% twice.

:- use_module(library(stream)).

top(X, Y) :- ( X > 0 -> pos(X, Y) ; neg(X, Y) ), \+ bad(Y), findall(Z, member(Z, [1,2]), _).
top(_, none).

pos(X, X).

neg(X, Y) :- ( X =:= 0, Y = zero ; Y is -X ).

bad(b).

twice(A, B) :- inc(1, A), inc(A, B).

inc(X, Y) :- Y is X + 1.

%% the then and the else call one predicate: a call made after the
%% condition failed is the else's, though the then's comes first
choose(X) :- ( X > 0 -> inc(X, _) ; inc(0, _) ), inc(X, _).

pick(X) :- member(X, [1,2,3]), X > 1.

safe(E) :- catch(oops(_), E, noted(E)).

oops(X) :- X is foo + 1.

noted(_).

find(K, V) :- lookup(K, V), V > 1.

lookup(K, V) :- pairs(Ps), member(K-V, Ps).

pairs([a-1, b-2, c-3]).

app([], L, L).
app([H|T], L, [H|R]) :- app(T, L, R).

nrev([], []).
nrev([H|T], R) :- nrev(T, RT), app(RT, [H], R).

go(N, R) :- numlist(1, N, L), nrev(L, R).

%% each run adds a byte to the file F, and answers only when the file then
%% holds an odd number of them: a probe on a fresh file answers, and the
%% replay that follows it fails
flip(F) :-
    open(F, append, S), write(S, x), close(S),
    read_file_to_codes(F, Cs), length(Cs, N),
    N mod 2 =:= 1.

%% loads F -- what a load reads is the program's own clauses, read again by
%% every run, and no journal answers it -- and then adds a clause to F unless
%% F had one: the replay's load reads what the probe added, takes the other
%% way, and leaves the journal where the probe appended
grow(F) :-
    use_module(F),
    (   catch(grown(x), _, fail) -> true ; append_file_from_codes(F, "grown(x).\n") ),
    getenv('HOME', _).
