%% setup_call_cleanup/3 under trace (3.78.3), for test/trace.pl: what each
%% query prints is held to swipl's, port for port. The setup is four levels
%% below the setup_call_cleanup/3 call, the goal two, a cleanup three where
%% the goal exits, fails or raises, and two below the clause whose cut takes
%% the frame -- and nothing between them is a port: swipl's machinery is its
%% VM's (I_CALLCLEANUP, frameFinished()), cocolog's the clauses of its
%% builtins' Prolog half, whose bodies the printer runs at the levels
%% swipl's frames stand at.
%%
%% Each goal, setup and cleanup is a predicate of the program's: a setup or
%% a cleanup that is a control structure is swipl's `','/2' predicate, a
%% port cocolog has no frame for (a goal that is one stands in the
%% meta-call frame of both since 3.78.4, test/trace-meta.pl), and a cleanup
%% whose body is `true' alone prints that `true' (COMPAT.md, the trace rows).

sc_g(1).
sc_g(2).
sc_g3(1).
sc_g3(2).
sc_g3(3).
sc_one(a).
sc_cl :- sc_one(_).
sc_su :- sc_one(_).
sc_su2 :- sc_g(_).
sc_clc(C) :- atom(C).
sc_fl :- sc_one(b).

%% the goal's last answer is its exit, a retry and a failure before it
sc1 :- setup_call_cleanup(sc_su, sc_g(X), sc_cl), X > 1.
%% a cut takes the frame: the cleanup two below the clause that cut
sc2 :- setup_call_cleanup(true, sc_g(X), sc_cl), !, X == 1.
%% the goal fails
sc3 :- setup_call_cleanup(true, fail, sc_cl).
%% the caller's cut
sc4 :- sc4b, !.
sc4b :- setup_call_cleanup(true, sc_g(_), sc_cl).
%% setup_call_catcher_cleanup/4 called itself, its catcher
sc5 :- setup_call_catcher_cleanup(true, sc_g(X), C, sc_clc(C)), X == 2.
%% call_cleanup/2 and a cut
sc6 :- call_cleanup(sc_g(_), sc_cl), !.
%% in forall/2's condition, its action beside it
sc7 :- forall(setup_call_cleanup(true, sc_g(_), sc_cl), sc_one(_)).
%% a cut with a choice of the goal's left
sc8 :- setup_call_cleanup(true, sc_g3(X), sc_cl), X == 2, !.
%% the frame open when the query's cut takes it
sc9 :- setup_call_cleanup(true, sc_g(_), sc_cl).
%% a cleanup that fails
sc10 :- setup_call_cleanup(true, sc_g(X), sc_fl), X > 1.
%% a library goal: its retry is setup_call_cleanup/3's Redo
sc11 :- setup_call_cleanup(true, member(X, [1, 2]), sc_cl), X > 1.
%% a setup that leaves a choice, which the setup's cut takes
sc12 :- setup_call_cleanup(sc_su2, sc_one(_), sc_cl).
%% a cleanup inside another's goal: the query's cut runs both, the inner first
sc13 :- setup_call_cleanup(true, sc4b, sc_cl).
%% a setup and a cleanup are queries of their own, as swipl's callProlog()
%% runs them: a builtin's call, a library's, is shown -- and a goal's is not
sc14 :- setup_call_cleanup(atom(a), sc_g(_), atom(b)), !.
sc15 :- setup_call_cleanup(member(_, [1]), sc_g(X), atom(c)), X > 1.
sc16 :- setup_call_cleanup(true, atom(x), atom(d)).
sc17 :- setup_call_cleanup(true, fail, atom(e)).
%% and a retry inside one is its own call's Redo
sc18 :- setup_call_cleanup(sc_su3, sc_one(_), sc_cl).
sc_su3 :- member(X, [1, 2]), X > 1.
%% swipl's sig_atomic/1 runs a setup `true' as nothing, no port -- but a
%% setup `fail', and a cleanup's `true' or `fail', are ports
sc19 :- setup_call_cleanup(fail, sc_g(_), atom(b)).
sc20 :- setup_call_cleanup(true, sc_g(_), fail).
sc21 :- call_cleanup(sc_g(_), true).

%% a raise: from the goal, and after the goal exited -- held from the
%% setup_call_cleanup/3 call on (test/trace.pl's `traced_from'), as swipl's
%% catch/3 is a frame and cocolog's none
sx1 :- setup_call_cleanup(true, atom_length(_, _), sc_cl).
sx2 :- setup_call_cleanup(true, sc_g(_), sc_cl), atom_length(_, _).
