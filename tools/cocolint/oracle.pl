%% oracle.pl -- the collision oracle: which of a program's predicates the
%% knowledge base actually calls its own.
%%
%% TIER 1 ONLY, and it NEVER CALLS THE CANDIDATE. It is consulted after the
%% file under test and asks the store one question, so a program that loops,
%% throws or reads a file cannot affect the answer.
%%
%%     cocolog --local run CANDIDATE.pl tools/cocolint/oracle.pl coco_oracle
%%
%% HOW IT SEES A COLLISION. `'$predicates'/1' skips every predicate record
%% whose library flag is set (lib/builtins.cicili:1731-1753), and that flag is
%% set on any clause asserted while the store was muted (lib/kb.cicili:1052) --
%% which is how every module's Prolog half and all eight vendored SWI libraries
%% load. coco_pred_make returns the EXISTING record when the name/arity is
%% already interned (lib/kb-pred.cicili), so a user's step/4 lands in
%% aggregate.pl's record, inherits its flag, and is ABSENT from the answer.
%% A name nobody else had is present.
%%
%% THE SET DIFFERENCE GOES IN THE SAFE DIRECTION: collisions are DECLARED
%% minus VISIBLE, so an extra visible name can never hide one.
%%
%% THE BLIND SPOT, STATED. A collision with a loaded module's C name or a
%% control construct the step runs in place creates a record with library =
%% 0, so it is VISIBLE here while the clauses are dead. That is what lint.pl's
%% N2 and N3 are for; neither mechanism is sound alone. (A name of the
%% engine's own is no blind spot since 3.1.0: a program file's clauses take a
%% non-ISO one over, so `own' is the truth, and an ISO one's are refused at
%% load, loudly.)
%%
%% EVERY CALL HERE IS `system:' QUALIFIED (3.1.0), because the candidate is
%% consulted into the same program: a candidate that defines format/2 or
%% msort/2 takes the name over, and an unqualified call would run the
%% candidate's clauses -- which this file promises never to do -- and print
%% nothing. `system:G' is the builtin whoever defined G, as swipl's is; the
%% walk over the list is a predicate of the oracle's own for the same reason
%% (a candidate's member/2 merges into library(lists)'s, row N1).
%%
%% AND IT IS --local ONLY. coco_b_predicates warms the store before
%% enumerating, so under --kb or --embed every predicate any other process
%% wrote to that base joins the answer and the difference stops being about
%% this file.

coco_oracle :-
    system:findall(N/A, system:current_predicate(N/A), L0),
    system:msort(L0, L),
    coco_oracle_names(L),
    system:write(coco_oracle_end), system:nl.

coco_oracle_names([]).
coco_oracle_names([N/A|T]) :-
    system:format("coco_oracle_name ~q ~w~n", [N, A]),
    coco_oracle_names(T).
