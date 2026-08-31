%% oracle.pl -- the collision oracle: which of a program's predicates the
%% knowledge base actually calls its own.
%%
%% TIER 1 ONLY, and it NEVER CALLS THE CANDIDATE. It is consulted after the
%% file under test and asks the store one question, so a program that loops,
%% throws or reads a file cannot affect the answer.
%%
%%     cocolog --local run CANDIDATE.pl tools/coco-agent/oracle.pl coco_oracle
%%
%% HOW IT SEES A COLLISION. `'$predicates'/1' skips every predicate record
%% whose library flag is set (lib/builtins.cicili:1731-1753), and that flag is
%% set on any clause asserted while the store was muted (lib/kb.cicili:1052) --
%% which is how every module's Prolog half and all eight vendored SWI libraries
%% load. coco_pred_make returns the EXISTING record when the name/arity is
%% already interned (lib/kb.cicili:566-577), so a user's step/4 lands in
%% aggregate.pl's record, inherits its flag, and is ABSENT from the answer.
%% A name nobody else had is present.
%%
%% THE SET DIFFERENCE GOES IN THE SAFE DIRECTION: collisions are DECLARED
%% minus VISIBLE, so an extra visible name can never hide one.
%%
%% THE BLIND SPOT, STATED. A collision with a C-dispatched builtin or a control
%% construct creates a record with library = 0, so it is VISIBLE here while the
%% clauses are dead. That is what lint.py's N2 and N3 are for; neither
%% mechanism is sound alone.
%%
%% AND IT IS --local ONLY. coco_b_predicates warms the store before
%% enumerating, so under --kb or --embed every predicate any other process
%% wrote to that base joins the answer and the difference stops being about
%% this file.

coco_oracle :-
    findall(N/A, current_predicate(N/A), L0),
    msort(L0, L),
    forall(member(N/A, L), format("coco_oracle_name ~q ~w~n", [N, A])),
    write(coco_oracle_end), nl.
