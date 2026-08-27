%% BASICS 05 -- backtracking, and the cut
%%
%%     ./cocolog run tutorials/basics/05-backtracking-and-cut.pl main
%%
%% A GOAL CAN SUCCEED MORE THAN ONCE. That is the engine's whole
%% behaviour: when a goal fails, control goes BACK to the most recent
%% choice that still has alternatives, and forward again from there. You
%% do not write the search. You write what an answer looks like.
%%
%% A CHOICE POINT is what the engine leaves behind when a goal could still
%% be answered another way -- another clause to try, another element of a
%% list. Backtracking is nothing more than returning to one.
%%
%% `!' -- THE CUT -- THROWS THOSE AWAY. Written in the body of a clause,
%% it commits to everything chosen since that clause was entered:
%%
%%     * the clauses of THIS predicate that have not been tried yet;
%%     * the choice points of the goals to its LEFT in this body.
%%
%% It does not affect goals to its right, and it does not affect the
%% caller.
%%
%% WHY IT MATTERS AND WHY IT BITES: the cut is how you say "this is the
%% answer, stop looking", which makes a program faster and often correct.
%% It is also how you write a predicate that gives a different answer
%% depending on whether its argument was bound when you called it. The
%% two shapes below -- `max_bad' and `max_good' -- are the classic
%% demonstration, and the difference is one line.

colour(red). colour(green). colour(blue).
size(small). size(large).

%% Two loose choices make every combination, and you wrote no loop.
outfit(C, S) :- colour(C), size(S).

%% THE CLASSIC TRAP. This looks right and is wrong: the cut has already
%% committed by the time the head of the second clause is even tried, so
%% asking `max_bad(3, 1, 1)' -- a CHECK rather than a computation --
%% wrongly succeeds against the first clause's head unification order.
max_bad(X, Y, X) :- X >= Y, !.
max_bad(_, Y, Y).

%% THE FIX is to keep the answer out of the head until the test has run.
%% Now the cut commits to a decision that has already been made.
max_good(X, Y, M) :- ( X >= Y -> M = X ; M = Y ).

main :-
    format("~n-- backtracking makes combinations out of nothing~n"),
    findall(C-S, outfit(C, S), Outfits),
    must('every colour with every size', Outfits,
         [red-small, red-large, green-small, green-large,
          blue-small, blue-large]),

    format("~n-- failure DRIVES it: `fail' asks for the next answer~n"),
    ( colour(_), fail ; true ),
    format("   the loop above visited every colour and left nothing behind~n"),

    format("~n-- a cut keeps only the first answer~n"),
    findall(C, colour(C), All),
    must('without a cut', All, [red, green, blue]),
    findall(C, (colour(C), !), First),
    must('with one', First, [red]),

    format("~n-- once/1 is a cut with a name, and reads better~n"),
    findall(C, once(colour(C)), Once),
    must('once(colour(C))', Once, [red]),

    format("~n-- if-then-else has a cut inside it, scoped to the condition~n"),
    ( colour(X), X == green -> Found = X ; Found = none ),
    must('the first colour that is green', Found, green),

    format("~n-- \\+ is negation as FAILURE: `I cannot prove it'~n"),
    ( \+ colour(purple) -> N = absent ; N = present ),
    must('purple is not a colour here', N, absent),
    format("   which is not the same as `purple is not a colour'.~n"),
    format("   It means this program cannot prove that it is.~n"),

    format("~n-- and now the trap, which is worth meeting once~n"),
    max_good(3, 1, GoodM),
    must('max_good(3, 1, M)', GoodM, 3),
    ( max_bad(3, 1, 1) -> Bad = wrongly_succeeded ; Bad = correctly_failed ),
    must('max_bad(3, 1, 1) -- asked as a CHECK', Bad, wrongly_succeeded),
    ( max_good(3, 1, 1) -> Good = wrongly_succeeded ; Good = correctly_failed ),
    must('max_good(3, 1, 1) -- the same check', Good, correctly_failed),
    format("   The cut in max_bad committed before the test could run.~n"),
    format("   Keep the answer OUT of the head until you have decided.~n~n"),
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
