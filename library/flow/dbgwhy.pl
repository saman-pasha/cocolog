%% library(flow/debug), part: why a run failed, read back from the recorded
%% window (DESIGN-flow.md 9.5, D4) -- the last failure and the failures it
%% came from.
%%
%%     flow_why(+Run, -Whys)
%%     flow_why(+Run, -Whys, +Options)
%%     flow_why_call(+Run, +S, -Why)           one call's why (1.11.4)
%%     flow_why_call(+Run, +S, -Why, +Options)
%%     flow_why_furthest(+Whys, -Path)         where it got furthest (below)
%%     flow_why_raised(+Run, -Raised)          why a run raised (below)
%%     flow_why_raised(+Run, -Raised, +Options)
%%
%% Run is what flow_debug/4 hands back. Whys has a node for each call the
%% window saw begin at its top (the query, when it saw the whole run):
%%
%%     why(S, Name/Arity, In, Tries)   a call of the program's own that FAILED:
%%                                     each clause it tried, in order --
%%                                     nohead(K), its head did not unify, or
%%                                     entered(K, Goals), its body entered and
%%                                     the calls it made, the one it failed at
%%                                     last among them -- or [] when it tried
%%                                     none: no clause has a head these
%%                                     arguments could unify with, and the
%%                                     index passed over every one (a window
%%                                     records only the heads a call tried,
%%                                     1.11.2)
%%     failed(S, Name/Arity, In)       a call that failed with nothing of its
%%                                     own to say why: a builtin, a library's
%%     exited(S, Name/Arity, In, Out)  a call that exited, as it left its
%%                                     arguments
%%     ended(S, Name/Arity, In, Fate)  one still running when the window
%%                                     closed (open, redo), or ended by an
%%                                     exception (raised, unwound)
%%
%% S is the inference of the call -- the n= of its <call> in the XML -- and
%% In and Out its arguments as written. A call of the program's own is one
%% with a panel on the chart. So `basket_total([apple, banana, pear], T)'
%% failed because its second clause's body failed at `basket_total([banana,
%% pear], T0)', whose second clause's failed at `price(banana, P)', which
%% tried no clause at all, no head of price/2 being for a banana: the
%% price of a banana is nowhere -- found by reading, not by stepping.
%%
%% WHOSE CALLS ARE EXPLAINED (1.11.4, from cicili-lang's report). Options:
%%
%%     own(chart)    the default: a call with a panel on the chart
%%     own(all)      every call of a predicate with clauses: a program of
%%                   several files debugged from a small top file has no
%%                   panel but the top's, and its tree was empty
%%     own(Files)    a call with a panel, or of a predicate those files (a
%%                   file or a list) hold clauses of
%%
%% A C builtin, a module's C predicate or a control construct is never one:
%% it has no clauses to have tried. flow_why_call/3,4 is the why of the
%% call made at inference S, whoever's it is -- its own clauses explained
%% whenever it has any, and the calls below it as the options say; it
%% fails for an S the window did not see.

flow_why(Run, Whys) :-
    flow_why(Run, Whys, []).

flow_why(Run, Whys, Opts) :-
    Run = run(_, _, _, _, Calls, _, _, _),
    flow_why_own_opt(Opts, Own),
    flow_dbg_why(Calls, Own, Whys).

flow_why_call(Run, S, Why) :-
    flow_why_call(Run, S, Why, []).

flow_why_call(Run, S, Why, Opts) :-
    Run = run(_, _, _, _, Calls, _, _, _),
    flow_why_own_opt(Opts, Own),
    flow_dbg_why_index(Calls, ByS, Kids),
    get_assoc(S, ByS, call(S, Pred, _, _, _, _, Clauses, _, _, Fate)),
    (   Fate == fail, flow_why_own(all, none, Pred, Clauses)
    ->  flow_dbg_why_root(S, ByS, Kids, Own, Why)
    ;   flow_dbg_why_node(S, ByS, Kids, Own, Why)
    ).

%% own(chart), own(all) or own(Files): chart, all, or preds(Keys), the
%% predicates the files hold clauses of
flow_why_own_opt(Opts, Own) :-
    (   memberchk(own(O), Opts) -> true ; O = chart ),
    (   O == chart -> Own = chart
    ;   O == all -> Own = all
    ;   (   is_list(O) -> Fs = O ; Fs = [O] ),
        findall(K-x, ( member(F, Fs), flow_scan_file(F, Cls, _), member(c(K, _, _, _), Cls) ), KXs0),
        sort(KXs0, KXs),
        list_to_assoc(KXs, Keys),
        Own = preds(Keys)
    ).

%% is a call one whose clauses are explained?
flow_why_own(chart, Panel, _, _) :- Panel \== none.
flow_why_own(all, _, Pred, Clauses) :-
    (   Clauses \== [] -> true ; \+ flow_why_c(Pred) ).
flow_why_own(preds(Keys), Panel, Pred, _) :-
    (   Panel \== none -> true ; get_assoc(Pred, Keys, _) ).

%% a predicate answered in C, or a construct: it has no clauses to try
flow_why_c(N/A) :-
    (   flow_t_c(N, A, _) ; flow_t_construct(N, A, _) ; flow_portal_row(_, N, A, _) ), !.

%% the nodes for the window's top calls, from its calls
flow_dbg_why(Calls, Whys) :-
    flow_dbg_why(Calls, chart, Whys).

flow_dbg_why(Calls, Own, Whys) :-
    flow_dbg_why_index(Calls, ByS, Kids),
    (   get_assoc(0, Kids, Tops) -> true ; Tops = [] ),
    findall(W, ( member(S, Tops), flow_dbg_why_node(S, ByS, Kids, Own, W) ), Whys).

%% each call by its inference, and each call's calls
flow_dbg_why_index(Calls, ByS, Kids) :-
    findall(S-C, ( member(C, Calls), arg(1, C, S) ), SC),
    list_to_assoc(SC, ByS),
    findall(P-S, member(call(S, _, _, P, _, _, _, _, _, _), Calls), PS0),
    keysort(PS0, PS),
    flow_dbg_why_kids(PS, Kids).

%% parent -> its calls in the order made
flow_dbg_why_kids(PS, Kids) :-
    empty_assoc(K0),
    reverse(PS, Rev),
    flow_dbg_why_kids_(Rev, K0, Kids).

flow_dbg_why_kids_([], K, K).
flow_dbg_why_kids_([P-S|T], K0, K) :-
    (   get_assoc(P, K0, L) -> true ; L = [] ),
    put_assoc(P, K0, [S|L], K1),
    flow_dbg_why_kids_(T, K1, K).

flow_dbg_why_node(S, ByS, Kids, W) :-
    flow_dbg_why_node(S, ByS, Kids, chart, W).

flow_dbg_why_node(S, ByS, Kids, Own, W) :-
    get_assoc(S, ByS, call(S, Pred, _, _, _, Panel, Clauses, In, Out, Fate)),
    (   Fate == exit
    ->  W = exited(S, Pred, In, Out)
    ;   Fate == fail, flow_why_own(Own, Panel, Pred, Clauses)
    ->  flow_dbg_why_root(S, ByS, Kids, Own, W)
    ;   Fate == fail
    ->  W = failed(S, Pred, In)
    ;   W = ended(S, Pred, In, Fate)
    ).

%% a failed call explained by its clauses, whoever's it is
flow_dbg_why_root(S, ByS, Kids, Own, why(S, Pred, In, Tries)) :-
    get_assoc(S, ByS, call(S, Pred, _, _, _, _, Clauses, In, _, _)),
    (   get_assoc(S, Kids, Ks) -> true ; Ks = [] ),
    flow_dbg_why_tries(Clauses, Ks, ByS, Kids, Own, Tries).

%% each clause tried: its head did not unify, or its body was entered and
%% made the calls after it, up to and with the one whose failure tried the
%% next clause: a retry takes no inference, so the next clause is entered
%% at the inference of that call, and its own calls come after it
flow_dbg_why_tries([], _, _, _, _, []).
flow_dbg_why_tries([nohead(K, _)|Cs], Ks, ByS, Kids, Own, [nohead(K)|Ts]) :- !,
    flow_dbg_why_tries(Cs, Ks, ByS, Kids, Own, Ts).
flow_dbg_why_tries([thrown(_, _)|Cs], Ks, ByS, Kids, Own, Ts) :- !,
    flow_dbg_why_tries(Cs, Ks, ByS, Kids, Own, Ts).
flow_dbg_why_tries([c(K, At)|Cs], Ks, ByS, Kids, Own, [entered(K, Goals)|Ts]) :-
    (   flow_dbg_why_next(Cs, Next) -> true ; Next = inf ),
    findall(G, ( member(S2, Ks), S2 > At, ( Next == inf -> true ; S2 =< Next ),
                 flow_dbg_why_node(S2, ByS, Kids, Own, G) ),
            Goals),
    flow_dbg_why_tries(Cs, Ks, ByS, Kids, Own, Ts).

%% the inference of the next clause entered (a head that did not unify is
%% tried on the way to it, at the same inference)
flow_dbg_why_next([c(_, At)|_], At) :- !.
flow_dbg_why_next([_|Cs], At) :-
    flow_dbg_why_next(Cs, At).

%% ---- the furthest progress ---------------------------------------------
%%
%%     flow_why_furthest(+Whys, -Path)
%%
%% WHERE A SEARCH GOT FURTHEST, the one path through the tree a reader of a
%% failed search wants first. Following the LAST failure at each level leads
%% to the last alternative tried, which in a reader that backtracks is its
%% fallback (the translator's tr_byline/3), not the cause. So at each failed
%% call this takes the clause that got furthest: the most calls of its body
%% that exited, then the most inferences spent before it gave up (its span,
%% from its first call to the last inference under its last), then the
%% earlier clause -- and goes down into the call that clause failed at.
%%
%% Path is a step(S, Name/Arity, In, K, Done, Tried) for each failed call on
%% the way -- clause K was the furthest, Done of its body's calls exited,
%% Tried clauses were tried -- ending in failed(S, Name/Arity, In) (nothing of
%% the program's to say why), nohead(S, Name/Arity, In) (no head unified),
%% ended(S, Name/Arity, In, Fate), or nothing when a clause whose every call
%% exited failed at something that is not a call (a unification in its
%% body). [] when no call of the window's top failed.
%%
%% AN EXPLICIT fail/0 OR false/0 IS NOT WHERE A CLAUSE FAILED (1.11.4, from
%% cicili-lang's report): `( Cond -> ... ; trace(...), fail )' fails because
%% Cond did, and the path went down into the fail. When the call a clause
%% failed at is one of the two, the path goes into the last call before it
%% that failed having tried a clause, else the last that failed, else the
%% fail itself.
flow_why_furthest(Whys, Path) :-
    (   flow_why_last_failed(Whys, W) -> flow_why_path(W, Path) ; Path = [] ).

flow_why_last_failed(Whys, W) :-
    reverse(Whys, Rev),
    member(W, Rev),
    ( W = why(_, _, _, _) ; W = failed(_, _, _) ), !.

flow_why_path(why(S, P, In, Tries), Path) :- !,
    length(Tries, NT),
    findall(o(ND, NSpan, K)-entered(K, Gs),
            ( member(entered(K, Gs), Tries),
              findall(x, member(exited(_, _, _, _), Gs), Xs), length(Xs, Done),
              flow_why_span(Gs, Span),
              ND is -Done, NSpan is -Span ),
            Os0),
    (   Os0 == []
    ->  Path = [nohead(S, P, In)]
    ;   msort(Os0, [o(ND1, _, _)-entered(K1, Gs1)|_]),
        Done1 is -ND1,
        Path = [step(S, P, In, K1, Done1, NT)|Rest],
        (   flow_why_failed_at(Gs1, G) -> flow_why_path(G, Rest) ; Rest = [] )
    ).
flow_why_path(failed(S, P, In), [failed(S, P, In)]) :- !.
flow_why_path(ended(S, P, In, F), [ended(S, P, In, F)]) :- !.
flow_why_path(_, []).

%% the inferences a clause's calls spent: from its first call to the last
%% inference under its last (the most a span can say: spans of 1 call)
flow_why_span([], 0).
flow_why_span([G|Gs], Span) :-
    arg(1, G, S0),
    last([G|Gs], L),
    flow_why_maxs(L, M),
    Span is M - S0 + 1.

flow_why_maxs(why(S, _, _, Tries), M) :- !,
    findall(M1, ( member(entered(_, Gs), Tries), member(G, Gs), flow_why_maxs(G, M1) ), Ms),
    max_list([S|Ms], M).
flow_why_maxs(G, S) :-
    arg(1, G, S).

flow_why_last_unexited(Gs, G) :-
    reverse(Gs, Rev),
    member(G, Rev),
    \+ G = exited(_, _, _, _), !.

%% the call a clause failed at: the last that did not exit -- past an
%% explicit fail/0 or false/0, to the failure it stands for
flow_why_failed_at(Gs, G) :-
    flow_why_last_unexited(Gs, G0),
    (   flow_why_explicit_fail(G0)
    ->  reverse(Gs, Rev),
        append(_, [G0|Before], Rev),
        (   member(G1, Before), G1 = why(_, _, _, [_|_]) -> G = G1
        ;   member(G1, Before), ( G1 = why(_, _, _, _) ; G1 = failed(_, _, _) ) -> G = G1
        ;   G = G0
        )
    ;   G = G0
    ).

flow_why_explicit_fail(failed(_, fail/0, _)).
flow_why_explicit_fail(failed(_, false/0, _)).

%% ---- why a run raised ---------------------------------------------------
%%
%%     flow_why_raised(+Run, -Raised)
%%     flow_why_raised(+Run, -Raised, +Options)
%%
%% A RUN THAT ENDED IN AN EXCEPTION has a why of its own (1.11.4, from
%% cicili-lang's report): the calls the exception unwound, from the
%% window's top down to the deepest -- the call whose body raised it, or the
%% builtin that did -- and what the raise answered.
%%
%% Raised is raised(Chain, Answered): Chain an ended(S, Name/Arity, In,
%% Fate) for each call on the way down (Fate raised or unwound -- or open
%% and redo, for a body the window saw no throw in), Answered none or a
%% failed call's why node, its clauses explained whoever's it is, the calls
%% under it as the options say (own(...), as flow_why/3's);
%% flow_why_furthest([Answered], Path) is where it got furthest. It fails
%% for a run that did not end in an exception.
%%
%% WHERE A CHOICE MADE THE RAISE (1.11.7, from cicili-lang's report). A
%% program gives up with an error in a branch a condition chose:
%%
%%     cpp_not_abstract(C) :- ( catch(nb_getval(K, yes), _, fail) -> true
%%                            ; cpp_abstract_class(C) -> cpp_refuse(...)
%%                            ; true ).
%%
%% raised from cpp_refuse/2 because the first condition failed and the
%% second HELD. Through 1.11.4 the answered failure was the last call that
%% failed having tried a clause, and nb_getval/2 tried none and
%% cpp_abstract_class/1 exited, so the search went on outwards and named an
%% older, unrelated failure. From the deepest body outwards, the first body
%% where the raise stands in a branch a choice took -- the then of an
%% if-then-else whose condition held, its else, every condition having
%% failed, or a disjunction's later branch -- is where the raise was
%% chosen, and the search stops there: the conditions it ran, builtins
%% included, are the answer, and Answered is the last of them that failed
%% having tried a clause, or none. A body with no such choice answers as
%% before: the last call before the raise that failed having tried a
%% clause, now one not inside a construct that the raise is outside of (an
%% if-then-else already settled says nothing of a later raise).
%%
%% WHERE A CATCH'S RECOVERY RAISED (1.11.7): a driver that catches an
%% error, reports it and throws again -- or whose report raises an error
%% of its own -- ends the run in its recovery, and the path of that raise
%% is the report's. The exception the catch took is then explained too,
%% as a raise of its own: its calls (unwound, made in the catch's goal),
%% the choice that made it and the failure it answered. A call of the
%% catch's goal that the catch's recovery came after is never on the
%% chain: that exception was taken, and the run went on.
%%
%% A raise is placed in its clause by a box: the box of the call the chain
%% goes on into, or, where the body raised by itself, the box of its throw
%% -- a throw/1 makes no call, and the matcher places the throw the run
%% recorded on the chart's throw box, thrown(Box, At) among its call's
%% clauses (dbgmatch.pl). The boxes are the chart's, or, for a clause the
%% chart does not draw, the places library(flow/debug) read for the calls
%% an exception ended. A raise whose place is not known -- a body whose
%% clause has no plan -- is placed in no branch: after a then's last call
%% the raise may be in the then or past the whole if-then-else, and the
%% first build of this, which read it from the last call, called the second
%% the first. Two more answers, options that are answers and not choices
%% (as flow_debug/4's places(P)):
%%
%%     chose(C)    none, or chose(S, Name/Arity, In, At, Branch, Conds):
%%                 the call whose clause chose the branch the raise is in,
%%                 the construct's box At, Branch then(J) (the J-th
%%                 condition held), else (every one failed) or branch(J)
%%                 (a disjunction's J-th, the ones before it failed), and
%%                 Conds the conditions it ran, in order, each a why node:
%%                 failed(...) and why(...) for those that failed, ended(...)
%%                 for one an exception ended inside it, exited(...) for the
%%                 one that held
%%     caught(K)   none, or caught(S, Name/Arity, In, At, Raised1, Chose1,
%%                 Caught1): the call whose clause holds the catch/3 at
%%                 box At whose recovery the raise came from, and the
%%                 exception it took, as this predicate answers for a run
%%                 (Raised1 raised([], none) when it ended no call)
flow_why_raised(Run, Raised) :-
    flow_why_raised(Run, Raised, []).

flow_why_raised(Run, Raised, Opts) :-
    Run = run(How, _, _, _, Calls, _, _, _),
    How = exception(_),
    flow_why_own_opt(Opts, Own),
    flow_dbg_raised(Calls, Own, Raised, Chose, Caught),
    (   memberchk(chose(C), Opts) -> C = Chose ; true ),
    (   memberchk(caught(K), Opts) -> K = Caught ; true ).

flow_dbg_raised(Calls, Own, Raised) :-
    flow_dbg_raised(Calls, Own, Raised, _, _).

flow_dbg_raised(Calls, Own, Raised, Chose, Caught) :-
    flow_dbg_why_index(Calls, ByS, Kids),
    flow_dbg_raise_chain(0, ByS, Kids, Ss),
    flow_dbg_raise_levels(0, Ss, none, Levels),
    flow_dbg_raise_why(Ss, Levels, ByS, Kids, Own, Raised, Chose, Caught).

%% at each level the last call the exception ended -- the raise is the
%% latest thing the run did, so on every level of its chain it is the
%% call made last -- but not a call of a catch's goal the catch's recovery
%% came after (a call made in it, or a throw it made): that exception was
%% taken
flow_dbg_raise_chain(P, ByS, Kids, Chain) :-
    (   get_assoc(P, Kids, Ks),
        flow_dbg_throws_of(P, ByS, Ths),
        reverse(Ks, Rev),
        once(( member(S, Rev), get_assoc(S, ByS, C), arg(10, C, Fate),
               memberchk(Fate, [raised, unwound, open, redo]),
               \+ flow_dbg_taken(S, C, Ks, Ths, ByS) ))
    ->  Chain = [S|Rest],
        flow_dbg_raise_chain(S, ByS, Kids, Rest)
    ;   Chain = []
    ).

flow_dbg_taken(S, C, Ks, Ths, ByS) :-
    arg(5, C, Box),
    flow_box_steps(Box, Steps),
    member(s(Cid, try), Steps),
    atom_concat(Cid, '.recover.', RPre),
    (   member(S2, Ks), S2 > S,
        get_assoc(S2, ByS, C2), arg(5, C2, B2), atom(B2),
        sub_atom(B2, 0, _, _, RPre)
    ;   member(B2-A2, Ths), A2 > S, sub_atom(B2, 0, _, _, RPre)
    ), !.

%% the throws a call's own body made, Box-At, in order (none for the root)
flow_dbg_throws_of(P, ByS, Ths) :-
    (   P =\= 0, get_assoc(P, ByS, C)
    ->  arg(7, C, Cl), findall(B-A, member(thrown(B, A), Cl), Ths)
    ;   Ths = []
    ).

%% the levels a raise passed through, deepest first: l(P, X, Floor) for the
%% root and each call P on its chain, X the call P's body made next on the
%% chain (none where P's own body raised), Floor none -- or, at the root of
%% an exception a catch took, the catch's goal, which bounds what counts
flow_dbg_raise_levels(Root, Ss, Floor, Levels) :-
    append(Ss, [none], Xs),
    Xs = [X1|Xs1],
    flow_dbg_levels_zip(Ss, Xs1, Ls),
    reverse([l(Root, X1, Floor)|Ls], Levels).

flow_dbg_levels_zip([], [], []).
flow_dbg_levels_zip([P|Ps], [X|Xs], [l(P, X, none)|Ls]) :-
    flow_dbg_levels_zip(Ps, Xs, Ls).

flow_dbg_raise_why(Ss, Levels, ByS, Kids, Own, raised(Chain, Answered), Chose, Caught) :-
    findall(ended(S, P, In, F), ( member(S, Ss), get_assoc(S, ByS, call(S, P, _, _, _, _, _, In, _, F)) ), Chain),
    flow_dbg_raise_walk(Levels, ByS, Kids, Own, none, Why, none, Caught),
    (   Why = w(A, Chose)
    ->  (   A == none -> Answered = none ; flow_dbg_why_root(A, ByS, Kids, Own, Answered) )
    ;   Answered = none, Chose = none
    ).

%% outwards from the deepest level: the first level with a choice, a
%% recovery or a failure in scope gives the why (w(Answered, Chose)), and
%% the first recovery the exception the catch took -- past which nothing
%% further out is this raise's
flow_dbg_raise_walk([], _, _, _, Why, Why, Caught, Caught).
flow_dbg_raise_walk([L|Ls], ByS, Kids, Own, Why0, Why, Caught0, Caught) :-
    flow_dbg_level_marks(L, ByS, Kids, Pos, Marks),
    (   Why0 \== none -> Why1 = Why0
    ;   Marks = [M|_] -> flow_dbg_mark_why(M, L, Pos, ByS, Kids, Own, Why1)
    ;   flow_dbg_scoped_failure(L, Pos, ByS, Kids, F) -> Why1 = w(F, none)
    ;   Why1 = none
    ),
    (   member(recovery(Cid), Marks)
    ->  flow_dbg_caught(L, Cid, Pos, ByS, Kids, Own, Caught),
        Why = Why1
    ;   flow_dbg_raise_walk(Ls, ByS, Kids, Own, Why1, Why, Caught0, Caught)
    ).

%% where the raise stands at a level: pos(Box, Max, Way), the box of the
%% call the chain goes on into or of the throw P's own body made (Way
%% call: the calls before it are P's up to Max) -- or, where P's own body
%% raised at no place the plan knows, of the last call P made (Way
%% after(Fate): the raise came after it, and where is not known); and the
%% marks its constructs make, innermost first, inside Floor. Only a place
%% makes a mark (above)
flow_dbg_level_marks(l(P, X, Floor), ByS, Kids, Pos, Marks) :-
    (   X \== none
    ->  get_assoc(X, ByS, CX), arg(5, CX, Box), Max is X - 1, Pos = pos(Box, Max, call)
    ;   flow_dbg_own_throw(P, ByS, Kids, Floor, TBox, TAt)
    ->  Pos = pos(TBox, TAt, call)
    ;   flow_dbg_kids_upto(P, Kids, inf, Ks), last(Ks, Y)
    ->  get_assoc(Y, ByS, CY), arg(5, CY, Box), arg(10, CY, F), Pos = pos(Box, Y, after(F))
    ;   Pos = none
    ),
    (   Pos = pos(B, _, call), flow_box_steps(B, Steps0)
    ->  flow_dbg_floor_steps(Steps0, Floor, Steps),
        reverse(Steps, Inner),
        findall(M, ( member(s(Id, K), Inner), flow_dbg_mark(K, Id, M) ), Marks)
    ;   Marks = []
    ).

%% the throw P's own body raised the exception by: its last, inside Floor,
%% with no call of P's inside Floor made after it
flow_dbg_own_throw(P, ByS, Kids, Floor, TBox, TAt) :-
    flow_dbg_throws_of(P, ByS, Ths0),
    findall(B-A, ( member(B-A, Ths0), flow_dbg_in_floor(B, Floor) ), Ths),
    last(Ths, TBox-TAt),
    flow_dbg_kids_upto(P, Kids, inf, Ks),
    \+ ( member(K, Ks), K > TAt, get_assoc(K, ByS, CK), arg(5, CK, KB), flow_dbg_in_floor(KB, Floor) ).

flow_dbg_floor_steps(Steps, none, Steps) :- !.
flow_dbg_floor_steps(Steps0, Floor, Steps) :-
    atom_concat(Floor, '.', FP),
    findall(s(Id, K), ( member(s(Id, K), Steps0), sub_atom(Id, 0, _, _, FP) ), Steps).

%% a construct the raise stands in: a branch a choice took, or a recovery
flow_dbg_mark(arm(J, then), Id, decision(Id, then(J))).
flow_dbg_mark(else, Id, decision(Id, else)).
flow_dbg_mark(branch(J), Id, decision(Id, branch(J))) :- J > 1.
flow_dbg_mark(recover, Id, recovery(Id)).

%% the why a mark gives: a choice, its conditions and the last that failed
%% having tried a clause; a recovery, the last such call in it
flow_dbg_mark_why(decision(Id, Branch), l(P, _, _), pos(_, Max, _), ByS, Kids, Own,
                  w(A, chose(P, Pred, In, Id, Branch, Conds))) :-
    flow_dbg_pred_in(P, ByS, Pred, In),
    flow_dbg_kids_upto(P, Kids, Max, Ks),
    reverse(Ks, Rev),
    atom_concat(Id, '.', Under),
    flow_dbg_block(Rev, Under, ByS, Block),
    findall(S, ( member(S, Block), get_assoc(S, ByS, C), arg(5, C, B),
                 flow_dbg_cond_of(Branch, Id, B) ), CSs),
    findall(N, ( member(S, CSs), flow_dbg_why_node(S, ByS, Kids, Own, N) ), Conds),
    (   flow_dbg_last_tried(CSs, ByS, A0) -> A = A0 ; A = none ).
flow_dbg_mark_why(recovery(Cid), l(P, _, _), pos(_, Max, _), ByS, Kids, _, w(A, none)) :-
    flow_dbg_kids_upto(P, Kids, Max, Ks),
    atom_concat(Cid, '.recover.', RPre),
    findall(S, ( member(S, Ks), get_assoc(S, ByS, C), arg(5, C, B), atom(B), sub_atom(B, 0, _, _, RPre) ), Ss),
    (   flow_dbg_last_tried(Ss, ByS, A0) -> A = A0 ; A = none ).

%% the last of the calls that failed having tried a clause
flow_dbg_last_tried(Ss, ByS, A) :-
    reverse(Ss, Rev),
    member(A, Rev), get_assoc(A, ByS, C), arg(10, C, fail), arg(7, C, [_|_]), !.

%% back from the raise, the calls under the construct, in the order made: a
%% call outside it ends the block, one with no box (true/0) is passed
flow_dbg_block(Rev, Under, ByS, Block) :-
    flow_dbg_block_(Rev, Under, ByS, [], Block).

flow_dbg_block_([], _, _, B, B).
flow_dbg_block_([S|Ss], Under, ByS, B0, B) :-
    get_assoc(S, ByS, C), arg(5, C, Box),
    (   atom(Box), sub_atom(Box, 0, _, _, Under) -> flow_dbg_block_(Ss, Under, ByS, [S|B0], B)
    ;   atom(Box), Box \== none -> B = B0
    ;   flow_dbg_block_(Ss, Under, ByS, B0, B)
    ).

%% is a box one of the conditions a branch was chosen by: the conditions
%% of arms 1 to J for then(J), of every arm for else, branches 1 to J-1 for
%% branch(J)
flow_dbg_cond_of(Branch, Id, B) :-
    atom(B),
    (   Branch = branch(J)
    ->  atom_concat(Id, '.b', Pre), atom_concat(Pre, Rest, B),
        once(sub_atom(Rest, Bf, _, _, '.')), sub_atom(Rest, 0, Bf, _, KA),
        atom_number(KA, K), K < J
    ;   atom_concat(Id, '.a', Pre), atom_concat(Pre, Rest, B),
        once(sub_atom(Rest, Bf, _, _, '.if.')), sub_atom(Rest, 0, Bf, _, KA),
        atom_number(KA, K),
        ( Branch = then(J) -> K =< J ; true )
    ).

%% no choice at a level: the last call before the raise that failed having
%% tried a clause, in the raise's scope -- not inside a construct the raise
%% is outside of -- and, at the root of an exception a catch took, in its goal
flow_dbg_scoped_failure(l(P, _, Floor), pos(PBox, Max, _), ByS, Kids, F) :-
    flow_dbg_kids_upto(P, Kids, Max, Ks),
    reverse(Ks, Rev),
    member(F, Rev), get_assoc(F, ByS, C), arg(10, C, fail), arg(7, C, [_|_]),
    arg(5, C, FBox),
    flow_dbg_in_floor(FBox, Floor),
    flow_dbg_in_scope(FBox, PBox), !.

flow_dbg_in_floor(_, none) :- !.
flow_dbg_in_floor(Box, Floor) :-
    atom(Box), atom_concat(Floor, '.', FP), sub_atom(Box, 0, _, _, FP).

%% a failure of another clause of the call is in scope -- that clause's
%% failure is why the raise's clause ran -- and in the raise's own clause
%% one is unless a construct it is inside does not hold the raise
flow_dbg_in_scope(FBox, PBox) :-
    (   \+ flow_dbg_placed(FBox) -> true
    ;   \+ flow_dbg_placed(PBox) -> true
    ;   flow_box_parts(FBox, FPre, _), flow_box_parts(PBox, PPre, _), FPre \== PPre -> true
    ;   flow_box_steps(FBox, Steps),
        forall(member(s(Id, K), Steps),
               ( flow_step_prefix(Id, K, Pre), atom_concat(Pre, '.', P2), sub_atom(PBox, 0, _, _, P2) ))
    ).

flow_dbg_placed(B) :- atom(B), B \== none.

%% the box prefix of the branch a step is: what a box in that branch
%% begins with
flow_step_prefix(Id, arm(J, cond), Pre) :- !, format(atom(Pre), '~w.a~w.if', [Id, J]).
flow_step_prefix(Id, arm(J, then), Pre) :- !, format(atom(Pre), '~w.a~w', [Id, J]).
flow_step_prefix(Id, else, Pre) :- !, atom_concat(Id, '.else', Pre).
flow_step_prefix(Id, branch(J), Pre) :- !, format(atom(Pre), '~w.b~w', [Id, J]).
flow_step_prefix(Id, try, Pre) :- !, atom_concat(Id, '.try', Pre).
flow_step_prefix(Id, recover, Pre) :- !, atom_concat(Id, '.recover', Pre).
flow_step_prefix(Id, inner, Id).

%% the exception a catch took, explained as a raise of its own: from the
%% last call of the catch's goal it ended, down -- or, when the goal's own
%% throw raised it, from that throw
flow_dbg_caught(l(P, _, _), Cid, pos(_, Max, _), ByS, Kids, Own,
                caught(P, Pred, In, Cid, Raised1, Chose1, Caught1)) :-
    flow_dbg_pred_in(P, ByS, Pred, In),
    flow_dbg_kids_upto(P, Kids, Max, Ks),
    atom_concat(Cid, '.try.', TPre),
    (   reverse(Ks, Rev), member(T, Rev), get_assoc(T, ByS, C), arg(5, C, B), atom(B),
        sub_atom(B, 0, _, _, TPre), arg(10, C, F), memberchk(F, [raised, unwound, open, redo])
    ->  flow_dbg_raise_chain(T, ByS, Kids, Below),
        Ss = [T|Below]
    ;   Ss = []
    ),
    atom_concat(Cid, '.try', Floor),
    flow_dbg_raise_levels(P, Ss, Floor, Levels1),
    flow_dbg_raise_why(Ss, Levels1, ByS, Kids, Own, Raised1, Chose1, Caught1).

flow_dbg_pred_in(0, _, none, []) :- !.
flow_dbg_pred_in(P, ByS, Pred, In) :-
    get_assoc(P, ByS, call(P, Pred, _, _, _, _, _, In, _, _)).

%% the calls P's body made, up to Max (inf: all of them) -- in every
%% clause it entered: a clause that failed is why the next ran
flow_dbg_kids_upto(P, Kids, Max, Ks) :-
    (   get_assoc(P, Kids, Ks0) -> true ; Ks0 = [] ),
    findall(K, ( member(K, Ks0), ( Max == inf -> true ; K =< Max ) ), Ks).

%% ---- a box, read ---------------------------------------------------------
%%
%% A box id names its clause and the way down to it: p5.c1.g1.a2.if.g1 is
%% the first goal of the condition of the second arm of the if-then-else
%% that is the first goal of clause 1 of panel 5; query.g1 the query's
%% goal; cpp_not_abstract/1#c1.g1.a2.g1, in a clause the chart does not
%% draw (dbgmatch.pl), the first goal of that arm's then. Steps are the
%% constructs it is inside, outermost first: s(Id, Kind), Id the construct's
%% own box and Kind arm(J, cond), arm(J, then), else, branch(J), try,
%% recover or inner (\+, once/1, ignore/1, a meta-call's goal).
flow_box_steps(Box, Steps) :-
    flow_box_parts(Box, Pre, Comps),
    flow_box_steps_(Comps, Pre, Steps).

flow_box_parts(Box, Pre, Comps) :-
    atom(Box), Box \== none,
    (   flow_box_hash(Box, H)
    ->  sub_atom(Box, 0, H, _, Name),
        H1 is H + 1,
        sub_atom(Box, H1, _, 0, Rest),
        atomic_list_concat([CK|Comps], '.', Rest),
        atomic_list_concat([Name, '#', CK], Pre)
    ;   atomic_list_concat(Parts, '.', Box),
        (   Parts = [query|Comps] -> Pre = query
        ;   Parts = [P, CK|Comps], atomic_list_concat([P, '.', CK], Pre)
        )
    ).

%% the last `#' of a box, whose name part may hold one
flow_box_hash(Box, H) :-
    findall(B, sub_atom(Box, B, 1, _, '#'), Bs),
    last(Bs, H).

flow_box_steps_([], _, []).
flow_box_steps_([G|Cs], Id0, Steps) :-
    atomic_list_concat([Id0, '.', G], Id),
    (   Cs = [A, if|Cs1], flow_box_num(a, A, J)
    ->  Steps = [s(Id, arm(J, cond))|Ss], atomic_list_concat([Id, '.', A, '.if'], Id1),
        flow_box_steps_(Cs1, Id1, Ss)
    ;   Cs = [A|Cs1], flow_box_num(a, A, J)
    ->  Steps = [s(Id, arm(J, then))|Ss], atomic_list_concat([Id, '.', A], Id1),
        flow_box_steps_(Cs1, Id1, Ss)
    ;   Cs = [else|Cs1]
    ->  Steps = [s(Id, else)|Ss], atom_concat(Id, '.else', Id1),
        flow_box_steps_(Cs1, Id1, Ss)
    ;   Cs = [Bj|Cs1], flow_box_num(b, Bj, J)
    ->  Steps = [s(Id, branch(J))|Ss], atomic_list_concat([Id, '.', Bj], Id1),
        flow_box_steps_(Cs1, Id1, Ss)
    ;   Cs = [try|Cs1]
    ->  Steps = [s(Id, try)|Ss], atom_concat(Id, '.try', Id1),
        flow_box_steps_(Cs1, Id1, Ss)
    ;   Cs = [recover|Cs1]
    ->  Steps = [s(Id, recover)|Ss], atom_concat(Id, '.recover', Id1),
        flow_box_steps_(Cs1, Id1, Ss)
    ;   Cs = [_|_]
    ->  Steps = [s(Id, inner)|Ss],
        flow_box_steps_(Cs, Id, Ss)
    ;   Steps = []
    ).

flow_box_num(L, A, J) :-
    atom_concat(L, JA, A), JA \== '',
    atom_codes(JA, Cs), Cs = [C|_], C >= 0'0, C =< 0'9,
    atom_number(JA, J), integer(J).
