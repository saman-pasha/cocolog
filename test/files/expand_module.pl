%  goal_expansion/2 of a file read as a module, as swipl 9.0.4 asks it.
%  Run by BOTH systems, output compared byte for byte; its two modules are
%  fixtures (test/files.pl, `expand_module').
%
%  A MODULE'S OWN HOOK IS ASKED OF ITS CLAUSES: xm.pl defines
%  goal_expansion(xfoo(X), xbar(X)), and its `xm_t :- xfoo(1), \+ xfoo(0).'
%  is stored as `xbar(1), \+ xbar(0)'. THE PROGRAM'S HOOK IS ASKED OF A
%  MODULE READ AFTER IT: this file's goal_expansion(ufoo(X), ubar(X))
%  rewrites xu.pl's `xu_t :- ufoo(2).', as a module's goals inherit user's
%  expansion in swipl.
%
%  Through cocolog 3.49.0 the first was never asked: library(yall)'s
%  clause of goal_expansion/2, read at start-up, made the predicate a
%  library's, and a clause a file read as a module gave it after that was
%  no hook, so xm_t called xfoo/1, an unknown procedure.
%
%  Not asked here, being one namespace's (COMPAT.md): xm's hook is asked
%  in cocolog of every file read after xm.pl, where swipl asks it of xm's
%  clauses alone.

%  xm.pl is read before this file has a hook of its own, so that its
%  clauses meet xm's hook alone: a program's hook read first would have
%  turned the expansion on for them in 3.49.0 too.

:- use_module(xm).

% cocolint: N1 -- the program's hook, which joins yall's clause of it as swipl's multifile user:goal_expansion/2 does
goal_expansion(ufoo(X), ubar(X)).

ubar(X) :- format("ubar ~w~n", [X]).

:- use_module(xu).

main :-
    catch(xm_t, E1, (print_message(error, E1), fail)),
    xm_body(B1), print(B1), nl,
    catch(xu_t, E2, (print_message(error, E2), fail)),
    xu_body(B2), print(B2), nl.
