%% BASICS 01 -- facts, rules, and the question mark
%%
%%     ./cocolog run tutorials/basics/01-facts-and-rules.pl main
%%
%% A PROLOG PROGRAM IS NOT A LIST OF INSTRUCTIONS. It is a set of things
%% held to be true, and running it means ASKING whether something else
%% follows. There is no main loop, no assignment, and no order of
%% execution to design -- only facts, rules, and a question.
%%
%% A FACT is a statement with no conditions:
%%
%%     parent(tom, bob).
%%
%% A RULE is a statement with conditions. `:-' is read "if", and the
%% commas are "and":
%%
%%     grandparent(X, Z) :- parent(X, Y), parent(Y, Z).
%%
%% Read aloud: X is a grandparent of Z IF X is a parent of some Y AND that
%% Y is a parent of Z. Nothing says how to find Y. The engine does that.
%%
%% THE SAME RULE ANSWERS SEVERAL QUESTIONS, which is the thing to notice
%% first and the thing that makes Prolog different from every language
%% where `grandparent(tom, ann)' would be a function call with one
%% direction. Ask it with both arguments filled in and it CHECKS; ask it
%% with one blank and it SEARCHES; ask it with both blank and it
%% ENUMERATES. One definition, three uses, and you wrote none of them.

parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).
parent(pat, jim).

male(tom).   male(bob).   male(jim).
female(liz). female(ann). female(pat).

%% A rule. Note that `Y' appears twice and nowhere else: it is the
%% CONNECTION between the two conditions, and it never leaves the rule.
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).

%% Rules may stand on rules. `grandfather' says nothing about parents.
grandfather(X, Z) :- grandparent(X, Z), male(X).

%% TWO CLAUSES FOR ONE NAME ARE AN "OR". A sibling shares a parent -- and
%% the second condition is what stops everybody being their own sibling.
sibling(A, B) :- parent(P, A), parent(P, B), A \== B.

main :-
    format("~n-- a fact is a question you already know the answer to~n"),
    ( parent(tom, bob) -> R1 = yes ; R1 = no ),
    must('parent(tom, bob)', R1, yes),
    ( parent(bob, tom) -> R2 = yes ; R2 = no ),
    must('parent(bob, tom)', R2, no),

    format("~n-- leave a blank and the same fact SEARCHES~n"),
    findall(C, parent(tom, C), Children),
    must('children of tom', Children, [bob, liz]),

    format("~n-- ...in either direction, which a function cannot do~n"),
    findall(P, parent(P, ann), Parents),
    must('parents of ann', Parents, [bob]),

    format("~n-- a rule is a fact with conditions~n"),
    findall(X-Z, grandparent(X, Z), Gs),
    must('every grandparent pair', Gs, [tom-ann, tom-pat, bob-jim]),
    findall(Z, grandfather(tom, Z), TomsGrandchildren),
    must('tom is grandfather of', TomsGrandchildren, [ann, pat]),

    format("~n-- and rules stand on rules~n"),
    findall(A-B, sibling(A, B), Sibs),
    must('sibling pairs', Sibs, [bob-liz, liz-bob, ann-pat, pat-ann]),

    format("~n-- WHY BOTH DIRECTIONS APPEAR: sibling/2 is symmetric, and~n"),
    format("   nothing told it not to be. That is a design decision you~n"),
    format("   now have to make on purpose -- see basics 05 on the cut.~n~n"),
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
