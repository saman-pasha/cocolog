%% BASICS 11 -- the knowledge base: what makes this Prolog different
%%
%%     ./cocolog run tutorials/basics/11-the-knowledge-base.pl main
%%
%% EVERY OTHER LESSON HERE IS TRUE OF ANY PROLOG. This one is not.
%%
%% In cocolog the clause store has a BACKEND, and which backend is a
%% RUNTIME CHOICE -- never a build. The same binary and the same program
%% run four ways:
%%
%%     (nothing)         --local: the clauses live in this process and die
%%                       with it. The default, and what this file uses.
%%     --kb NAME --host  a Zigurat server: clauses are ROWS, and another
%%                       process asking the same question gets your answer
%%     --embed DIR       the same storage engine, in this process, over a
%%                       directory
%%     --http            a Zeytun edge, read-only, over HTTP
%%
%% NOTHING ABOVE THE STORE KNOWS WHICH. `assertz/1' is `assertz/1' in all
%% four; the difference is whether the clause outlives the process and who
%% else can see it. That is the seam this whole interpreter is built
%% around, and the reason a Prolog program here can be a SERVICE rather
%% than a script.
%%
%% WHY THAT IS INTERESTING: a rule is data. Consult a rule into a shared
%% knowledge base and every process that asks now reasons with it -- you
%% deployed a policy by asserting a clause. The Coco (the repository next
%% door) is built entirely on that: consensus rules, contracts and fork
%% choice are clauses in a database, and a node is a cocolog asking.
%%
%% RUN THIS FILE AGAINST A SERVER TO SEE THE OTHER HALF:
%%
%%     ./cocolog --kb demo --host 127.0.0.1 --port 2160 \
%%               run tutorials/basics/11-the-knowledge-base.pl main
%%
%% then ask a SECOND process, which consulted nothing:
%%
%%     ./cocolog --kb demo --host 127.0.0.1 --port 2160 \
%%               query "policy(gold, D), write(D), nl"
%%
%% Under --local the second command answers nothing, because the first
%% process took its store with it. That difference IS the feature.

:- dynamic policy/2.
:- dynamic visit/1.

%% A RULE, not a fact: what a discount IS, rather than what it happens to
%% be today. Stored in a knowledge base, this is a policy every process
%% shares -- and changing it is an assert, not a deployment.
discount(Customer, D) :- tier(Customer, T), policy(T, D).
discount(_, 0).

tier(alice, gold).
tier(bob, silver).

main :-
    format("~n-- the store is a seam, and this run is using --local~n"),
    format("   (nothing you assert below will outlive this process)~n"),

    format("~n-- a policy is a CLAUSE, so changing it is an assert~n"),
    assertz(policy(gold, 20)),
    assertz(policy(silver, 10)),
    discount(alice, DA),
    must('alice, who is gold', DA, 20),
    discount(bob, DB),
    must('bob, who is silver', DB, 10),
    discount(carol, DC),
    must('carol, who is nobody', DC, 0),

    format("~n-- and re-deciding it is a retract and an assert~n"),
    retract(policy(gold, 20)),
    assertz(policy(gold, 25)),
    discount(alice, DA2),
    must('alice again', DA2, 25),
    format("   Against a server that edit is a ROW, and every other~n"),
    format("   process reasoning about gold customers now uses 25.~n"),

    format("~n-- a counter across a run: assert is how state persists~n"),
    assertz(visit(1)), assertz(visit(2)), assertz(visit(3)),
    aggregate_all(count, visit(_), Visits),
    must('visits recorded', Visits, 3),

    format("~n-- listing/1 shows a predicate as clauses, wherever it lives~n"),
    format("   policy/2 right now:~n"),
    listing(policy/2),

    format("-- and clean up, because these MAY be database rows~n"),
    retractall(policy(_, _)),
    retractall(visit(_)),
    aggregate_all(count, policy(_, _), Left),
    must('policies left', Left, 0),

    format("~n-- WHAT TO TAKE AWAY~n"),
    format("   `:- dynamic p/1.' makes an empty predicate FAIL rather than~n"),
    format("   raise, which is what lets a program ask about something~n"),
    format("   nobody has written yet.~n"),
    format("   `cocolog forget' empties a knowledge base; `consult'~n"),
    format("   ADDS to it, so consulting twice answers twice.~n"),
    format("   `cocolog list' names the knowledge bases a server holds.~n"),
    format("   And a machine can be FROZEN mid-proof and thawed in~n"),
    format("   another process -- see README's `twelve interpreters'.~n~n"),
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
