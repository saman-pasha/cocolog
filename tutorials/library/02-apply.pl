%% LIBRARY 02 -- library(apply)
%%
%%     ./cocolog run tutorials/library/02-apply.pl main
%%
%% TIER 1: always there, no import.
%%
%% NO C HALF AT ALL, which is the cleanest demonstration the module seam
%% gets: `coco-defmodule' takes `nil' for the dispatcher and the whole
%% library is clauses. Nothing in it needs the outside world -- applying a
%% goal to a list is `call/N' and nothing else.
%%
%% `call/N' IS THE WHOLE IDEA. `call(foo(A), B)' calls `foo(A, B)': a goal
%% with some arguments already filled in, and the rest supplied at the
%% call. That is a closure, and it is why none of these need a lambda --
%% though `library(yall)' gives you one when the argument order does not
%% line up.

double(X, Y) :- Y is X * 2.

%% ONE UNIFICATION, SO NO DIRECTION -- which is what makes the maplist
%% below work both ways. Compare `double/2' above, which calls `is/2'.
wrap(X, item(X)).
add(A, B, C) :- C is A + B.
positive(X) :- X > 0.

main :-
    format("~n-- call/N: a goal with its first arguments already there~n"),
    call(double, 4, D),
    must('call(double, 4, D)', D, 8),
    call(add(10), 5, Sum),
    must('call(add(10), 5, S) -- 10 is already in', Sum, 15),

    format("~n-- maplist/2: a test over every element~n"),
    ( maplist(positive, [1, 2, 3]) -> All = yes ; All = no ),
    must('are they all positive', All, yes),
    ( maplist(positive, [1, -2, 3]) -> All2 = yes ; All2 = no ),
    must('and with a negative in it', All2, no),

    format("~n-- maplist/3: one list into another~n"),
    maplist(double, [1, 2, 3], Doubled),
    must('maplist(double, In, Out)', Doubled, [2, 4, 6]),

    format("~n-- ...and it runs BACKWARDS exactly when the GOAL does~n"),
    maplist(wrap, [1, 2, 3], Wrapped),
    must('maplist(wrap, In, Out)', Wrapped, [item(1), item(2), item(3)]),
    maplist(wrap, Unwrapped, [item(4), item(5)]),
    must('maplist(wrap, In, [item(4), item(5)])', Unwrapped, [4, 5]),
    format("   `wrap/2' is one unification and has no direction, so~n"),
    format("   maplist/3 has none either.~n"),
    ( catch(maplist(double, _, [2, 4, 6]), _, fail) -> B = worked ; B = refused ),
    must('but maplist(double, In, [2,4,6])', B, refused),
    format("   ...because `Y is X * 2' needs X. maplist chose no~n"),
    format("   direction; `is/2' did, and that is the one place in this~n"),
    format("   language that has one. Nothing you can do to maplist fixes~n"),
    format("   a goal that only goes one way.~n"),

    format("~n-- maplist/4 and /5: two and three lists in step~n"),
    maplist(add, [1, 2, 3], [10, 20, 30], Sums),
    must('maplist(add, A, B, C)', Sums, [11, 22, 33]),

    format("~n-- foldl/4: carry an accumulator along~n"),
    foldl([X, A0, A1]>>(A1 is A0 + X), [1, 2, 3, 4], 0, Total),
    must('sum by fold', Total, 10),
    foldl([X2, A2, A3]>>(A3 is A2 * X2), [1, 2, 3, 4], 1, Product),
    must('product by fold', Product, 24),
    foldl([X3, A4, A5]>>(A5 = [X3|A4]), [1, 2, 3], [], Reversed),
    must('and reverse, by folding onto a list', Reversed, [3, 2, 1]),

    format("~n-- include/exclude/partition, which live here too~n"),
    include(positive, [1, -2, 3], Pos),
    must('include/3', Pos, [1, 3]),
    exclude(positive, [1, -2, 3], NonPos),
    must('exclude/3', NonPos, [-2]),
    partition(positive, [1, -2, 3], P, N),
    must('partition/4', P-N, [1, 3]-[-2]),

    format("~n-- forall/2 is a CHECK and belongs beside these~n"),
    ( forall(member(X4, [2, 4, 6]), 0 is X4 mod 2) -> Even = yes ; Even = no ),
    must('all even', Even, yes),
    format("   It is \\\\+ (Cond, \\\\+ Action): it stops at the first~n"),
    format("   counterexample and builds no list. maplist/2 would too --~n"),
    format("   the difference is that forall takes a GOAL to generate~n"),
    format("   from, not a list.~n~n"),
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
