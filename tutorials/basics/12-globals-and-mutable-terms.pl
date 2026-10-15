%% BASICS 12 -- state that outlives backtracking: globals and mutable terms
%%
%%     ./cocolog run tutorials/basics/12-globals-and-mutable-terms.pl main
%%
%% EVERYTHING SO FAR WAS UNDONE BY BACKTRACKING. A binding made on the way
%% into a branch that failed is taken back, which is what makes Prolog's
%% search clean. Sometimes a program wants the opposite -- a count that
%% survives the failure-driven loop that made it, a running maximum, a
%% table of what was seen -- and there are two places to keep it.
%%
%% A GLOBAL VARIABLE has a name: `nb_setval(Key, Value)' stores a copy,
%% `nb_getval(Key, Value)' hands it out, and `nb_current(Key, Value)' asks
%% whether there is one at all -- failing where `nb_getval/2' raises, and
%% naming every global with its key unbound. A GROUND value is handed out
%% as one term every read shares, as SWI's is, so `nb_setarg/3' on it
%% changes the global; a value with a variable in it is a fresh copy at
%% each read (SWI shares that too). In cocolog `b_setval/2' and
%% `b_getval/2' are the same pair: neither is undone by backtracking.
%%
%% A MUTABLE TERM is a compound whose argument you overwrite in place.
%% `setarg(N, T, V)' writes argument N of T, and backtracking puts the old
%% value back; `nb_setarg(N, T, V)' writes a COPY of V and backtracking
%% leaves it -- the counter of SWI's own `aggregate_all/3' is one.
%%
%% WHAT TO BE CAREFUL OF: the ARGUMENT is written, not a variable it names.
%% In cocolog a variable of a clause body lives in the body's environment
%% and `f(X)''s argument names it, so after `T = f(X), setarg(1, T, z)'
%% X is still unbound. SWI makes such an X in the argument itself and binds
%% it there; read the argument back with `arg/3' and the two agree.

main :-
    format("~n-- a global is read back as it was stored, and a missing one raises~n"),
    nb_setval(lesson_seen, [apple]),
    nb_getval(lesson_seen, Seen),
    must('nb_getval(lesson_seen, X)', Seen, [apple]),
    catch(nb_getval(lesson_missing, _), error(E, _), true),
    must('nb_getval of a key never set', E, existence_error(variable, lesson_missing)),

    format("~n-- nb_current/2 asks instead: a failure, and every key when unbound~n"),
    ( nb_current(lesson_missing, _) -> R1 = found ; R1 = failed ),
    must('nb_current(lesson_missing, _)', R1, failed),
    nb_setval(lesson_count, 0),
    findall(K, ( nb_current(K, _), sub_atom(K, 0, _, _, lesson_) ), Keys),
    must('the keys that start lesson_', Keys, [lesson_seen, lesson_count]),

    format("~n-- a global survives the failure-driven loop that set it~n"),
    ( member(F, [pear, plum, fig]), nb_getval(lesson_seen, S0), nb_setval(lesson_seen, [F|S0]), fail ; true ),
    nb_getval(lesson_seen, Seen2),
    must('after the loop', Seen2, [fig, plum, pear, apple]),

    format("~n-- setarg/3 is taken back by backtracking, nb_setarg/3 is not~n"),
    T1 = box(empty),
    ( setarg(1, T1, full), fail ; true ),
    must('after setarg and a failure', T1, box(empty)),
    T2 = box(empty),
    ( nb_setarg(1, T2, full), fail ; true ),
    must('after nb_setarg and a failure', T2, box(full)),

    format("~n-- the counter: arg/3 reads it, nb_setarg/3 writes it, fail moves on~n"),
    C = count(0),
    ( between(1, 10, I), arg(1, C, N0), N is N0 + I, nb_setarg(1, C, N), fail ; true ),
    must('the sum of 1..10, kept across ten failures', C, count(55)),

    format("~n-- a ground global is one term every read shares: nb_setarg/3 on it changes the global~n"),
    nb_setval(lesson_tally, tally(0)),
    ( between(1, 5, _), nb_getval(lesson_tally, Ty), arg(1, Ty, Ty0), Ty1 is Ty0 + 1, nb_setarg(1, Ty, Ty1), fail ; true ),
    nb_getval(lesson_tally, Tally),
    must('five turns of nb_getval and nb_setarg', Tally, tally(5)),
    nb_setval(lesson_pair, pair(_, b)), nb_getval(lesson_pair, P1), P1 = pair(a, _),
    nb_getval(lesson_pair, P2),
    ( P2 = pair(V2, b), var(V2) -> R2 = 'pair(_, b)' ; R2 = P2 ),
    must('a value with a variable, read again after a read bound it (SWI shares it)', R2, 'pair(_, b)'),

    format("~n-- nb_setarg/3 writes a copy; setarg/3 links what it is given~n"),
    T3 = box(empty), nb_setarg(1, T3, pair(A3, b)), A3 = a,
    ( T3 = box(pair(V3, b)), var(V3) -> R3 = 'box(pair(_, b))' ; R3 = T3 ),
    must('a binding made after nb_setarg', R3, 'box(pair(_, b))'),
    T4 = box(empty), setarg(1, T4, pair(A4, b)), A4 = a,
    must('a binding made after setarg', T4, box(pair(a, b))),

    format("~n-- the argument is written, not a variable it names~n"),
    T5 = f(X5), setarg(1, T5, z),
    arg(1, T5, Arg5),
    must('arg(1, T, A) after setarg(1, T, z)', Arg5, z),
    ( var(X5) -> R5 = unbound ; R5 = X5 ),
    must('X of T = f(X), here (SWI binds it to z)', R5, unbound),
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
