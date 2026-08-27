%% BASICS 06 -- collecting answers: findall, bagof, setof, aggregate_all
%%
%%     ./cocolog run tutorials/basics/06-findall-and-friends.pl main
%%
%% BACKTRACKING GIVES YOU ANSWERS ONE AT A TIME. Often you want them all
%% at once, as a list, and that is a different act: it runs the goal to
%% exhaustion in a nested engine and collects what each solution made of
%% a template.
%%
%% `findall(Template, Goal, List)' IS THE ONE TO REACH FOR. It is
%% deterministic, it succeeds with `[]' when the goal has no solutions,
%% and it COPIES -- so the terms in the list survive the backtracking
%% that produced them and share nothing with the goal's variables.
%%
%% `bagof/3' AND `setof/3' ARE DIFFERENT, and the difference catches
%% people: they FAIL rather than answering `[]', and they treat a variable
%% that is free in the goal as something to GROUP BY -- one solution per
%% distinct value of it. `^' says "do not group by this one". `setof/3'
%% is `bagof/3' sorted with duplicates removed.
%%
%% Fail-on-empty is not a wart. `bagof' answers "here are the solutions
%% for this group", and a group with no solutions is not a group.

age(ann, 34).  age(bob, 34).  age(cyd, 41).
likes(ann, tea).  likes(ann, cake).  likes(bob, tea).

main :-
    format("~n-- findall: every answer, in order, as a list~n"),
    findall(N, age(N, _), Names),
    must('every name', Names, [ann, bob, cyd]),
    findall(N-A, age(N, A), Pairs),
    must('as pairs', Pairs, [ann-34, bob-34, cyd-41]),

    format("~n-- the template can be anything, and it is COPIED~n"),
    findall(person(N), age(N, _), People),
    must('a term per answer', People, [person(ann), person(bob), person(cyd)]),

    format("~n-- findall on no solutions is [], and that is often what you want~n"),
    findall(N, age(N, 99), Nobody),
    must('nobody is 99', Nobody, []),

    format("~n-- bagof FAILS instead, which is a different claim~n"),
    ( bagof(N, age(N, 99), _) -> B = answered ; B = failed ),
    must('bagof over no solutions', B, failed),

    format("~n-- and bagof GROUPS by whatever is left free~n"),
    findall(A-G, bagof(N, age(N, A), G), Groups),
    must('one group per age', Groups, [34-[ann, bob], 41-[cyd]]),

    format("~n-- ^ says do not group by that one~n"),
    bagof(N, A^age(N, A), Everyone),
    must('all of them, ungrouped', Everyone, [ann, bob, cyd]),

    format("~n-- setof is bagof, sorted, without duplicates~n"),
    setof(A, N^age(N, A), Ages),
    must('the distinct ages', Ages, [34, 41]),
    findall(L, likes(_, L), WithDups),
    must('findall keeps duplicates', WithDups, [tea, cake, tea]),
    setof(L, W^likes(W, L), Distinct),
    must('setof does not', Distinct, [cake, tea]),

    format("~n-- aggregate_all counts and sums without building a list~n"),
    aggregate_all(count, age(_, _), Count),
    must('how many people', Count, 3),
    aggregate_all(sum(A2), age(_, A2), Total),
    must('total age', Total, 109),
    aggregate_all(max(A3), age(_, A3), Oldest),
    must('the oldest', Oldest, 41),
    aggregate_all(bag(N2), age(N2, _), Bag),
    must('bag is findall', Bag, [ann, bob, cyd]),

    format("~n-- forall/2 is a CHECK, not a collection~n"),
    ( forall(age(_, A4), A4 > 30) -> All = yes ; All = no ),
    must('is everybody over 30', All, yes),
    format("   It is \\+ (Cond, \\+ Action) underneath: it stops at the~n"),
    format("   first counterexample and builds no list at all.~n~n"),
    format("done~n").

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
