%% demo.pl -- test/flowchart.pl's first fixture, and lesson 50's.
%%
%% report/3 reaches user code, a library predicate, builtins, tests, a
%% cut, an if-then-else chain, a negation, a findall, a recursive
%% nondeterministic predicate, and one C function: re_match/2, which
%% library(text) answers from libc's regex.

:- use_module(library(text)).

%% report(+Pat, +Text, +Nums): how many lines of Text match Pat, what
%% kind of number that is, and the first of Nums over 2.
report(Pat, Text, Nums) :-
    grep_count(Pat, Text, N),
    classify(N, Class),
    \+ Class == negative,
    (   first_big(Nums, Big) -> true ; Big = none ),
    format("~w lines (~w), first big: ~w~n", [N, Class, Big]).

%% grep_count(+Pat, +Text, -N)
grep_count(Pat, Text, N) :-
    codes_lines(Text, Lines),
    findall(L, ( member(L, Lines), re_match(Pat, L) ), Hits),
    length(Hits, N).

%% classify(+N, -Class)
classify(N, Class) :-
    (   N < 0 -> Class = negative
    ;   N =:= 0 -> Class = zero
    ;   Class = positive
    ).

%% first_big(+List, -X): the first element over 2.
first_big(L, X) :- pick(X, L), X > 2, !.

%% pick(-X, +List): each element in turn.
pick(X, [X|_]).
pick(X, [_|T]) :- pick(X, T).
