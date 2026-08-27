%% BASICS 02 -- unification: the one operation underneath everything
%%
%%     ./cocolog run tutorials/basics/02-unification.pl main
%%
%% `=' IS NOT ASSIGNMENT AND IT IS NOT COMPARISON. It asks: can these two
%% terms be made identical, and if so, what must the variables be? That
%% question is the whole engine. Calling a predicate is unification
%% against a clause head; returning a value is unification with an
%% argument that happened to be a variable.
%%
%% A VARIABLE IS A HOLE, NOT A BOX. `X = 1' does not put 1 into X; it
%% observes that X can only be 1 from here on. Which is why a variable
%% cannot be changed afterwards -- there is nothing to overwrite -- and
%% why the same `X' means the same thing everywhere in one clause and
%% nothing at all in the next.
%%
%% `_' IS A HOLE YOU DO NOT NAME, and every `_' is a DIFFERENT hole.
%% `f(_, _)' matches `f(1, 2)`; `f(X, X)' does not.
%%
%% THREE COMPARISONS THAT ARE NOT THE SAME, and mixing them up is the
%% commonest beginner's bug in any Prolog:
%%
%%     X = Y      unify: make them the same if you can, binding as needed
%%     X == Y     identical ALREADY: no binding, just a question
%%     X =:= Y    arithmetic: evaluate both sides and compare NUMBERS
%%
%% `1 + 1 == 2' is FALSE -- the term `+(1,1)' is not the term `2'.
%% `1 + 1 =:= 2' is true. `X = 1 + 1' binds X to the TERM.

main :-
    format("~n-- unification binds, and it goes both ways~n"),
    ( X = hello -> true ; true ),
    must('X = hello', X, hello),
    ( point(3, 4) = point(A, B) -> true ; true ),
    must('A from point(3,4) = point(A,B)', A, 3),
    must('B', B, 4),

    format("~n-- a variable is a hole: two holes can be joined~n"),
    P = Q, Q = 7,
    must('P after P = Q, Q = 7', P, 7),

    format("~n-- the same name means the same hole IN ONE CLAUSE~n"),
    ( f(1, 1) = f(S, S) -> M1 = matched ; M1 = refused ),
    must('f(1,1) = f(S,S)', M1, matched),
    ( f(1, 2) = f(T, T) -> M2 = matched ; M2 = refused ),
    must('f(1,2) = f(T,T)', M2, refused),

    format("~n-- but every _ is a different hole~n"),
    ( f(1, 2) = f(_, _) -> M3 = matched ; M3 = refused ),
    must('f(1,2) = f(_,_)', M3, matched),

    format("~n-- =, == and =:= are three different questions~n"),
    ( 1 + 1 == 2 -> E1 = true ; E1 = false ),
    must('1 + 1 == 2', E1, false),
    ( 1 + 1 =:= 2 -> E2 = true ; E2 = false ),
    must('1 + 1 =:= 2', E2, true),
    Term = 1 + 1,
    must('X = 1 + 1 leaves the TERM', Term, 1+1),
    Sum is 1 + 1,
    must('X is 1 + 1 evaluates it', Sum, 2),

    format("~n-- == does not bind, which is what makes it safe in a guard~n"),
    ( Free == anything -> G = bound ; G = left_alone ),
    must('an unbound variable == atom', G, left_alone),
    ( var(Free) -> V = still_a_hole ; V = filled ),
    must('and the variable afterwards', V, still_a_hole),

    format("~n-- unification is STRUCTURAL, so it works to any depth~n"),
    tree(node(1, node(2, leaf, leaf), leaf)) = tree(node(_, node(Deep, _, _), _)),
    must('the 2 dug out of a nested term', Deep, 2),

    format("~n-- and it is how a LIST is taken apart~n"),
    [Head|Tail] = [a, b, c],
    must('head', Head, a),
    must('tail', Tail, [b, c]),
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
