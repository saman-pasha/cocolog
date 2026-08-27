%% LIBRARY 09 -- library(yall): lambdas, and when you need one
%%
%%     ./cocolog run tutorials/library/09-yall.pl main
%%
%% TIER 1: no import. SWI's own file, vendored unedited.
%%
%% YOU OFTEN DO NOT NEED A LAMBDA. `call/N' already gives you closures:
%% `maplist(add(10), Xs, Ys)' calls `add(10, X, Y)' for each element, and
%% that covers every case where the arguments you want to fix are the
%% FIRST ones. Reach for yall when they are not.
%%
%% THE SYNTAX IS TWO OPERATORS:
%%
%%     [X, Y]>>Goal        parameters, then the goal
%%     Free/[X]>>Goal      ...and which outer variables are SHARED
%%
%% `>>' is an ordinary operator and `[X]>>Goal' is an ordinary term. What
%% makes it a lambda is `call/N' on it: yall defines clauses for `>>' at
%% several arities, and each one COPIES the term before binding the
%% parameters.
%%
%% THAT COPY IS THE WHOLE SUBTLETY. Copying is what lets the same lambda
%% be applied to a hundred different elements without its parameters
%% getting stuck on the first. But it also copies any outer variable you
%% meant to SHARE -- so the binding happens in the copy and never reaches
%% you. `Free/Lambda' is how you say "not this one".

main :-
    format("~n-- the common case, where a lambda is the clearest thing~n"),
    maplist([X, Y]>>(Y is X * X), [1, 2, 3], Squares),
    must('maplist with a lambda', Squares, [1, 4, 9]),
    include([X2]>>(0 is X2 mod 2), [1, 2, 3, 4], Evens),
    must('include with one', Evens, [2, 4]),
    foldl([X3, A0, A1]>>(A1 is A0 + X3), [1, 2, 3], 0, Sum),
    must('foldl with one', Sum, 6),

    format("~n-- when the argument order does not line up~n"),
    maplist([X4, Y4]>>atom_concat(prefix_, X4, Y4), [a, b], Prefixed),
    must('the fixed argument is FIRST, so a closure would do', Prefixed,
         [prefix_a, prefix_b]),
    maplist([X5, Y5]>>atom_concat(X5, '_suffix', Y5), [a, b], Suffixed),
    must('...but here it is second, and only a lambda will do', Suffixed,
         [a_suffix, b_suffix]),
    format("   That is the test for `do I need yall here': can I put the~n"),
    format("   fixed arguments first? If yes, `call/N' is simpler.~n"),

    format("~n-- THE COPY, and the bug it prevents~n"),
    maplist([X6, Y6]>>(Y6 = wrapped(X6)), [1, 2], Wrapped),
    must('each element gets a FRESH X', Wrapped, [wrapped(1), wrapped(2)]),
    format("   Without the copy, X would bind to 1 on the first element~n"),
    format("   and the second would fail. The copy is what makes a~n"),
    format("   lambda reusable at all.~n"),

    format("~n-- ...and the bug it CAUSES, which is the one to know~n"),
    maplist([_]>>(Outer = bound), [a, b]),
    ( var(Outer) -> O = never_bound ; O = Outer ),
    must('an outer variable the lambda tried to bind', O, never_bound),
    format("   The lambda bound the COPY's Outer. Yours never moved.~n"),

    format("~n-- `Free/Lambda' IS THE ANSWER IN SWI, AND IT RAISES HERE~n"),
    (   catch(maplist(Shared/[_]>>(Shared = seen), [a, b]), error(FE, _), true)
    ->  true
    ;   FE = it_failed
    ),
    must('maplist(Free/[_]>>Goal, ...)', FE, instantiation_error),
    format("   SWI's `Free/Lambda' names the variables NOT to copy, and~n"),
    format("   the vendored yall raises on it here rather than working.~n"),
    format("   It is a real gap, recorded rather than papered over -- and~n"),
    format("   the file it lives in is SWI's own, unedited, so the fix~n"),
    format("   belongs upstream of this repository or in a replacement.~n"),
    format("~n"),
    format("   WHAT TO DO INSTEAD: do not bind outwards from a lambda at~n"),
    format("   all. A goal that has to produce something should RETURN~n"),
    format("   it -- that is what foldl/4's accumulator is for, and what~n"),
    format("   maplist/3's second list is for. Both are below.~n"),
    foldl([X10, A6, A7]>>(A7 is A6 + X10), [1, 2, 3], 0, Carried),
    must('foldl carries a value out, with no shared variable', Carried, 6),
    findall(Seen, member(Seen, [a, b]), Collected),
    must('...and findall/3 is the other half of the answer', Collected,
         [a, b]),

    format("~n-- reading an outer variable needs no declaration~n"),
    Factor = 10,
    maplist([X7, Y7]>>(Y7 is X7 * Factor), [1, 2, 3], Scaled),
    must('a bound outer variable is copied WITH its value', Scaled,
         [10, 20, 30]),
    format("   Copying a bound variable copies the binding, so reading~n"),
    format("   works and only WRITING needs Free/.~n"),

    format("~n-- and yall works anywhere call/N does~n"),
    G = [X8]>>(X8 > 2),
    ( call(G, 5) -> C = yes ; C = no ),
    must('call/2 on a lambda held in a variable', C, yes),
    findall(Y9, (member(X9, [1, 2, 3]), call([A, B]>>(B is A + 100), X9, Y9)),
            Applied),
    must('...and inside an ordinary goal', Applied, [101, 102, 103]),
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
