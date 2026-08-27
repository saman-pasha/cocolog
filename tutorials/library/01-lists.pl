%% LIBRARY 01 -- library(lists)
%%
%%     ./cocolog run tutorials/library/01-lists.pl main
%%
%% TIER 1: no `use_module' needed. `lists' is compiled into the binary and
%% registered before the first goal runs, so every predicate below is
%% simply there. Asking for it with `use_module(library(lists))' succeeds
%% at once and does nothing -- see tutorials/library/00-the-library-path.
%%
%% MOSTLY PROLOG, AND ON PURPOSE. Seven of these are C and thirty-odd are
%% clauses, and the split is not about speed: `member/2', `select/3',
%% `append/3' and `permutation/2' each answer MANY TIMES, and a module's C
%% half has no access to the choice stack. Written in C they would work
%% until the first `cocolog step'; written as clauses the ENGINE provides
%% the choice points, and a machine frozen mid-backtrack can be thawed in
%% another process and go on.
%%
%% WHICH IS WHY THE NONDETERMINISTIC ONES ARE THE INTERESTING ONES. If you
%% only ever call `member/2' with both arguments bound you are using a
%% tenth of it.

main :-
    format("~n-- the ones everybody knows~n"),
    append([1, 2], [3], A), must('append/3', A, [1, 2, 3]),
    length([a, b, c], L), must('length/2', L, 3),
    reverse([1, 2, 3], R), must('reverse/2', R, [3, 2, 1]),
    nth0(0, [a, b, c], N0), must('nth0/3 counts from 0', N0, a),
    nth1(1, [a, b, c], N1), must('nth1/3 counts from 1', N1, a),
    last([1, 2, 3], Last), must('last/2', Last, 3),
    msort([c, a, b], M), must('msort/2 keeps duplicates', M, [a, b, c]),
    sort([c, a, b, a], S), must('sort/2 removes them', S, [a, b, c]),
    sum_list([1, 2, 3], Sum), must('sum_list/2', Sum, 6),
    max_list([1, 9, 3], Max), must('max_list/2', Max, 9),
    min_list([4, 1, 3], Min), must('min_list/2', Min, 1),
    numlist(1, 5, NL), must('numlist/3', NL, [1, 2, 3, 4, 5]),

    format("~n-- membership: memberchk/2 tests, member/2 GENERATES~n"),
    ( memberchk(b, [a, b, c]) -> Chk = yes ; Chk = no ),
    must('memberchk/2 -- one answer, then stop', Chk, yes),
    findall(X, member(X, [a, b, c]), Each),
    must('member/2 -- one answer per element', Each, [a, b, c]),
    format("   Use memberchk when you only want to know. Using member~n"),
    format("   leaves a choice point behind that somebody will backtrack~n"),
    format("   into later, and the bug looks like action at a distance.~n"),

    format("~n-- select/3 removes an element, and enumerates WHICH~n"),
    findall(E-Rest, select(E, [a, b, c], Rest), Selections),
    must('every element with the rest', Selections,
         [a-[b, c], b-[a, c], c-[a, b]]),
    format("   Which makes `select' the natural way to say `pick one'.~n"),

    format("~n-- permutation/2, and why the count is the point~n"),
    findall(P, permutation([1, 2, 3], P), Perms),
    length(Perms, HowMany),
    must('permutations of a 3-list', HowMany, 6),

    format("~n-- exclude, include, partition: filters over a goal~n"),
    include([X1]>>(X1 > 2), [1, 2, 3, 4], Big),
    must('include/3', Big, [3, 4]),
    exclude([X2]>>(X2 > 2), [1, 2, 3, 4], Small),
    must('exclude/3', Small, [1, 2]),
    partition([X3]>>(X3 > 2), [1, 2, 3, 4], In, Out),
    must('partition/4, the kept half', In, [3, 4]),
    must('and the rest', Out, [1, 2]),
    format("   `[X]>>Goal' is a lambda from library(yall) -- library 09.~n"),

    format("~n-- sets, as lists~n"),
    list_to_set([a, b, a, c], Set),
    must('list_to_set/2 keeps first occurrences', Set, [a, b, c]),
    subtract([1, 2, 3], [2], Sub),
    must('subtract/3', Sub, [1, 3]),
    intersection([1, 2, 3], [2, 3, 4], Int),
    must('intersection/3', Int, [2, 3]),
    union([1, 2], [2, 3], Un),
    must('union/3', Un, [1, 2, 3]),
    format("   These are O(n*m) and order-preserving. For real set work~n"),
    format("   use library(ordsets) -- library 08 -- which is O(n+m) on~n"),
    format("   sorted lists.~n"),

    format("~n-- and the ones that reshape~n"),
    exclude([_]>>fail, [[1, 2], [3]], _),
    append([[1, 2], [3], [4]], Flat),
    must('append/2 concatenates a list OF lists', Flat, [1, 2, 3, 4]),
    sumlist_or_die,
    numlist(1, 3, Three),
    maplist([X4, Y4]>>(Y4 is X4 * X4), Three, Squares),
    must('maplist/3, from library(apply)', Squares, [1, 4, 9]),
    format("~ndone~n").

%% A place to put a note rather than a predicate: `sumlist/2' is SWI's
%% deprecated spelling and is NOT here. `sum_list/2' is.
sumlist_or_die :-
    (   catch(sumlist([1], _), error(existence_error(_, _), _), fail)
    ->  format("   sumlist/2 exists~n")
    ;   format("   sumlist/2 is absent on purpose -- SWI deprecated it;~n"),
        format("   sum_list/2 is the spelling.~n")
    ).

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
