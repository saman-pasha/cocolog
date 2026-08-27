%% BASICS 03 -- lists, and predicates that run backwards
%%
%%     ./cocolog run tutorials/basics/03-lists.pl main
%%
%% A LIST IS A TERM, not a data structure the language knows about.
%% `[a, b]' is exactly `'.'(a, '.'(b, []))' -- a chain of two-argument
%% terms ending in the atom `[]'. Everything below follows from that and
%% from unification; nothing here is a builtin doing something special.
%%
%% `[H|T]' IS THE WHOLE TRICK. It unifies with any non-empty list, binding
%% H to the first element and T to the rest. An empty list does not match
%% it, which is how recursion over a list ends without a test.
%%
%% THE BIG IDEA IN THIS FILE IS THAT `append/3' RUNS BACKWARDS. It is one
%% two-clause definition, and it concatenates, splits, tests for a prefix,
%% tests for a suffix, and enumerates every way to cut a list in two --
%% because it does not say what is input and what is output. Nothing in
%% the definition mentions direction, so it has none.

%% Our own, so you can see there is no magic in it.
my_append([], Ys, Ys).
my_append([X|Xs], Ys, [X|Zs]) :- my_append(Xs, Ys, Zs).

my_length([], 0).
my_length([_|T], N) :- my_length(T, M), N is M + 1.

%% `member/2' answers MANY TIMES -- once per element that matches -- which
%% is why it is a generator as much as a test.
my_member(X, [X|_]).
my_member(X, [_|T]) :- my_member(X, T).

main :-
    format("~n-- a list is a term, and [H|T] takes it apart~n"),
    [H|T] = [a, b, c],
    must('head', H, a),
    must('tail', T, [b, c]),
    must('the term behind the sugar', '.'(a, '.'(b, [])), [a, b]),

    format("~n-- append/3 forwards: the use everybody knows~n"),
    my_append([1, 2], [3, 4], Joined),
    must('append([1,2], [3,4], X)', Joined, [1, 2, 3, 4]),

    format("~n-- BACKWARDS: the same clauses, asked the other way~n"),
    my_append(Front, [3, 4], [1, 2, 3, 4]),
    must('what goes BEFORE [3,4]', Front, [1, 2]),

    format("~n-- and sideways: every way to cut a list in two~n"),
    findall(A-B, my_append(A, B, [1, 2, 3]), Splits),
    must('all splits of [1,2,3]', Splits,
         [[]-[1, 2, 3], [1]-[2, 3], [1, 2]-[3], [1, 2, 3]-[]]),

    format("~n-- which makes prefix/suffix free, with no new code~n"),
    ( my_append([1, 2], _, [1, 2, 3]) -> Pre = yes ; Pre = no ),
    must('is [1,2] a prefix of [1,2,3]', Pre, yes),
    ( my_append(_, [9], [1, 2, 3]) -> Suf = yes ; Suf = no ),
    must('does [1,2,3] end in 9', Suf, no),

    format("~n-- member/2 is a test AND a generator~n"),
    ( my_member(2, [1, 2, 3]) -> In = yes ; In = no ),
    must('2 in [1,2,3]', In, yes),
    findall(X, my_member(X, [a, b, c]), Each),
    must('every element, one at a time', Each, [a, b, c]),

    format("~n-- the library has these and more; see library/01-lists~n"),
    my_length([a, b, c], Len),
    must('length', Len, 3),
    length(BlankList, 3),
    length(BlankList, HowMany),
    must('length/2 can also MAKE a list of 3 holes', HowMany, 3),

    format("~n-- sorting: msort/2 keeps duplicates, sort/2 removes them~n"),
    msort([c, a, b, a], Msorted),
    must('msort([c,a,b,a])', Msorted, [a, a, b, c]),
    sort([c, a, b, a], Sorted),
    must('sort([c,a,b,a])', Sorted, [a, b, c]),
    format("~ndone~n").

%% ---- the two helpers every lesson here carries ------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth six duplicated lines; a tutorial that needs a support
%% library beside it is a tutorial that stops working the moment it is
%% moved.
show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers. A tutorial that prints whatever it computed is a tutorial
%% that goes quietly wrong the day the language changes underneath it.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
