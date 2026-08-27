%% LIBRARY 10 -- library(aggregate): counting without a list
%%
%%     ./cocolog run tutorials/library/10-aggregate.pl main
%%
%% TIER 1: no import. SWI's own file, vendored unedited -- and the
%% `aggregate_all/3' you will actually call is cocolog's own C
%% implementation of the seven specifications that do not group.
%%
%% `findall' THEN `length' IS THE THING THIS REPLACES. Counting a
%% million solutions by building a million-element list and measuring it
%% is a lot of memory for one integer. `aggregate_all(count, Goal, N)'
%% keeps a counter.
%%
%% THE SEVEN SPECIFICATIONS:
%%
%%     count            how many solutions
%%     count(Expr)      the same, with a template (the value is ignored)
%%     sum(Expr)        add them up      -- 0 for no solutions
%%     max(Expr)        the largest      -- FAILS for no solutions
%%     min(Expr)        the smallest     -- FAILS for no solutions
%%     bag(Expr)        exactly findall/3
%%     set(Expr)        findall then sort: ordered, duplicates gone
%%
%% NOTE WHICH ONES FAIL ON NOTHING. `sum' of no numbers is 0 and that is
%% arithmetic; `max' of no numbers is not a number at all, so it fails
%% rather than inventing one. Getting that wrong is how a report shows a
%% maximum of zero for an empty table.

sale(north, apples, 10).
sale(north, pears,  5).
sale(south, apples, 7).
sale(south, pears,  3).
sale(south, plums,  4).

main :-
    format("~n-- count, without building the list~n"),
    aggregate_all(count, sale(_, _, _), N),
    must('how many sales', N, 5),
    aggregate_all(count, sale(south, _, _), SouthN),
    must('...and with the goal narrowed', SouthN, 3),

    format("~n-- sum, max, min~n"),
    aggregate_all(sum(Q), sale(_, _, Q), Total),
    must('total quantity', Total, 29),
    aggregate_all(max(Q2), sale(_, _, Q2), Max),
    must('the largest single sale', Max, 10),
    aggregate_all(min(Q3), sale(_, _, Q3), Min),
    must('and the smallest', Min, 3),

    format("~n-- bag and set~n"),
    aggregate_all(bag(P), sale(_, P, _), Bag),
    must('bag/1 is findall: order kept, duplicates kept', Bag,
         [apples, pears, apples, pears, plums]),
    aggregate_all(set(P2), sale(_, P2, _), Set),
    must('set/1 sorts and removes them', Set, [apples, pears, plums]),

    format("~n-- ON NO SOLUTIONS, and this is the part to remember~n"),
    aggregate_all(count, sale(east, _, _), NoneN),
    must('count of nothing', NoneN, 0),
    aggregate_all(sum(Q4), sale(east, _, Q4), NoneSum),
    must('sum of nothing', NoneSum, 0),
    aggregate_all(bag(P3), sale(east, P3, _), NoneBag),
    must('bag of nothing', NoneBag, []),
    ( aggregate_all(max(Q5), sale(east, _, Q5), _) -> Mx = answered ; Mx = failed ),
    must('but MAX of nothing', Mx, failed),
    format("   Which is right: the maximum of an empty set is not zero,~n"),
    format("   it does not exist. A report that printed 0 there would be~n"),
    format("   wrong in the quietest possible way.~n"),

    format("~n-- grouping is bagof/setof's job, not this one's~n"),
    findall(R-S, aggregate_all(sum(Q6), sale(R, _, Q6), S), _),
    setof(R2, P4^Q7^sale(R2, P4, Q7), Regions),
    must('the regions', Regions, [north, south]),
    findall(R3-S3,
            ( member(R3, Regions),
              aggregate_all(sum(Q8), sale(R3, _, Q8), S3) ),
            PerRegion),
    must('a total per region', PerRegion, [north-15, south-14]),
    format("   `aggregate_all/3' deliberately does NOT group -- it runs~n"),
    format("   one goal to exhaustion and answers once. Enumerate the~n"),
    format("   groups yourself with setof/3 and aggregate inside, which~n"),
    format("   is what the three lines above do and reads better than a~n"),
    format("   grouping specification would.~n~n"),
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
