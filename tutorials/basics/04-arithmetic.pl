%% BASICS 04 -- arithmetic, and why `is' is not `='
%%
%%     ./cocolog run tutorials/basics/04-arithmetic.pl main
%%
%% ARITHMETIC IS NOT PART OF UNIFICATION, and that surprises everybody
%% once. `X = 1 + 1' succeeds and leaves X as the TERM `+(1, 1)'. Prolog
%% did exactly what it always does: it made two terms the same. It has no
%% opinion about `+' meaning addition.
%%
%% `is/2' IS THE OPINION. `X is 1 + 1' says: EVALUATE the right-hand side
%% as an arithmetic expression, then unify X with the number. Which means
%% the right-hand side must be fully instantiated -- every variable in it
%% already bound to a number -- because there is nothing to evaluate
%% otherwise.
%%
%% SO `is' HAS A DIRECTION, and it is the one place in this language that
%% does. `X is Y + 1' cannot be asked backwards to find Y. That is not an
%% oversight; solving equations is a different job (see the constraint
%% libraries in other Prologs), and pretending otherwise would make a
%% simple operation unpredictable.
%%
%% COMPARISON EVALUATES BOTH SIDES: `=:=' `=\=' `<' `>' `=<' `>='. Note
%% `=<' and not `<=' -- `<=' would read as an arrow, and Prolog keeps that
%% spelling free for one.
%%
%% INTEGERS HERE ARE 64 BITS AND THEY WRAP IN SILENCE. That is worth
%% knowing before you write anything financial: see the last section.

%% Recursion is the loop. This one is not tail recursive on purpose --
%% the multiplication happens on the way back OUT of the recursion.
factorial(0, 1) :- !.
factorial(N, F) :- N > 0, M is N - 1, factorial(M, G), F is N * G.

%% An ACCUMULATOR turns it into a loop that uses no stack: the answer is
%% built on the way IN, and the base case just hands it back.
fact_acc(N, F) :- fact_acc(N, 1, F).
fact_acc(0, Acc, Acc) :- !.
fact_acc(N, Acc, F) :- N > 0, A is Acc * N, M is N - 1, fact_acc(M, A, F).

main :-
    format("~n-- = builds a term, is/2 evaluates one~n"),
    Term = 1 + 1,
    must('X = 1 + 1', Term, 1+1),
    Value is 1 + 1,
    must('X is 1 + 1', Value, 2),
    ( compound(Term) -> K = compound ; K = number ),
    must('and the first one really is a term', K, compound),

    format("~n-- the usual operators~n"),
    A is 7 + 3,   must('7 + 3', A, 10),
    B is 7 - 3,   must('7 - 3', B, 4),
    C is 7 * 3,   must('7 * 3', C, 21),
    D is 7 / 2,   must('7 / 2   (float division)', D, 3.5),
    E is 7 // 2,  must('7 // 2  (integer division)', E, 3),
    F is 7 mod 3, must('7 mod 3', F, 1),
    %% `**' ANSWERS AN INTEGER HERE where SWI answers a float. ISO leaves
    %% `**' float-valued and `^' integer-valued; cocolog treats both as the
    %% same operation, so `2 ** 10' is 1024 and not 1024.0. Worth knowing
    %% before you port arithmetic that relied on the float.
    G is 2 ** 10, must('2 ** 10  (an INTEGER here, 1024.0 in SWI)', G, 1024),
    H is abs(-5), must('abs(-5)', H, 5),
    I is max(3, 9), must('max(3, 9)', I, 9),
    J is truncate(3.7), must('truncate(3.7)', J, 3),

    format("~n-- comparison evaluates BOTH sides~n"),
    ( 2 + 2 =:= 4 -> Eq = true ; Eq = false ),
    must('2 + 2 =:= 4', Eq, true),
    ( 2 + 2 == 4 -> Id = true ; Id = false ),
    must('2 + 2 == 4   (term identity, not arithmetic)', Id, false),
    ( 3 =< 3 -> Le = true ; Le = false ),
    must('3 =< 3   (note the spelling)', Le, true),

    format("~n-- recursion is the loop~n"),
    factorial(10, Fact),
    must('10!', Fact, 3628800),
    fact_acc(10, Fact2),
    must('10! with an accumulator', Fact2, 3628800),

    format("~n-- between/3 generates, so a `for loop' is a generator~n"),
    findall(Sq, (between(1, 5, N), Sq is N * N), Squares),
    must('the first five squares', Squares, [1, 4, 9, 16, 25]),

    format("~n-- AND THE WARNING: 64 bits, and they wrap in SILENCE~n"),
    Wrapped is 1000000000000000000 * 997,
    show('1000000000000000000 * 997', Wrapped),
    ( Wrapped < 0 ; Wrapped < 1000000000000000000 ),
    format("   ...which is not the answer, and nothing said so.~n"),
    format("   For money-sized numbers use The Coco's library(u256),~n"),
    format("   where an operation that cannot represent its answer~n"),
    format("   RAISES instead of wrapping.~n~n"),
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
