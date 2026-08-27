%% BASICS 07 -- changing the program while it runs
%%
%%     ./cocolog run tutorials/basics/07-assert-and-retract.pl main
%%
%% A PROLOG PROGRAM CAN ADD TO ITSELF. `assertz/1' puts a clause at the
%% end of its predicate, `asserta/1' at the front, and `retract/1' takes
%% the first one that unifies away again. There is no separate notion of
%% "data" -- a fact you asserted is a clause exactly like one you wrote.
%%
%% `:- dynamic p/1.' SAYS SO IN ADVANCE, and it matters: without it, a
%% predicate with no clauses is UNDEFINED and calling it raises
%% `existence_error'. Declared dynamic, it simply has no solutions and
%% fails. "I do not know this predicate" and "I know it and there is
%% nothing in it" are different answers, and the declaration is how you
%% choose the second.
%%
%% IN COCOLOG THIS IS ALSO A DATABASE WRITE. Under `--local' the clause
%% lives in this process and dies with it; against a knowledge base it is
%% written through, and another process asking the same question gets it.
%% That is the whole point of this interpreter, and basics 11 is about it.
%%
%% WHAT TO BE CAREFUL OF: asserting inside a loop over the same predicate
%% you are asserting to. Prolog's "logical update view" says a goal sees
%% the clauses that existed when it STARTED, so `findall' will not chase
%% its own tail -- but the code reads as though it might, and the next
%% reader has to work that out.

:- dynamic seen/1.
:- dynamic counter/1.

main :-
    format("~n-- a declared dynamic predicate is empty, not unknown~n"),
    findall(X, seen(X), Empty),
    must('nothing seen yet', Empty, []),

    format("~n-- assertz adds at the end, asserta at the front~n"),
    assertz(seen(first)),
    assertz(seen(second)),
    asserta(seen(zeroth)),
    findall(X2, seen(X2), Order),
    must('the order they are tried in', Order, [zeroth, first, second]),

    format("~n-- retract takes the FIRST clause that unifies~n"),
    retract(seen(first)),
    findall(X3, seen(X3), Left),
    must('after retracting first', Left, [zeroth, second]),

    format("~n-- retracting what is not there simply FAILS~n"),
    ( retract(seen(nothing)) -> R = removed ; R = failed ),
    must('retract(seen(nothing))', R, failed),

    format("~n-- a counter is a fact you replace~n"),
    assertz(counter(0)),
    bump, bump, bump,
    counter(N),
    must('after three bumps', N, 3),

    format("~n-- the logical update view: a goal sees the clauses it STARTED with~n"),
    findall(S, seen(S), Before),
    must('before', Before, [zeroth, second]),
    forall(member(_, Before), assertz(seen(copied))),
    findall(S2, seen(S2), After),
    must('after copying each one once', After,
         [zeroth, second, copied, copied]),
    format("   The forall did not chase its own additions. If it saw the~n"),
    format("   clauses as they grew, it would never have stopped.~n"),

    format("~n-- A DIFFERENCE WORTH KNOWING: builtins here answer ONCE~n"),
    format("   The classic `retract(X), fail' loop iterates by BACKTRACKING~n"),
    format("   into retract, so it needs one that answers many times. Every~n"),
    format("   builtin in cocolog is deterministic, on purpose -- one that~n"),
    format("   left a choice point behind would need the engine's choice~n"),
    format("   stack in its hands. So that loop removes exactly ONE clause.~n"),
    findall(S4, seen(S4), WasThere),
    ( retract(seen(_)), fail ; true ),
    findall(S5, seen(S5), StillThere),
    length(WasThere, WasN), length(StillThere, StillN),
    Removed is WasN - StillN,
    must('clauses the failure-driven loop removed', Removed, 1),
    format("   Write the recursion instead -- empty_seen/0, at the bottom.~n"),

    format("~n-- and clean up, because in cocolog these may be a DATABASE~n"),
    empty_seen,
    findall(S3, seen(S3), Gone),
    must('emptied', Gone, []),
    retract(counter(_)),
    format("~ndone~n").

bump :- retract(counter(C)), D is C + 1, assertz(counter(D)).

%% RECURSION, because a failure-driven loop cannot iterate a deterministic
%% retract -- the lesson above counts what it actually removed.
%%
%% `retractall/1' does exactly this and is the one to reach for; it is
%% spelt out here so you can see there is nothing in it. It was ITSELF
%% written as the failure-driven loop until this tutorial counted, and had
%% been quietly removing one clause of three.
empty_seen :- ( retract(seen(_)) -> empty_seen ; true ).

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
