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
%% builtin that did -- and the failure it answered. A program that gives up
%% with an error, `( Cond -> ... ; throw(...) )', a compiler's driver, raises
%% because something failed just before: the last call that failed having
%% tried a clause, made in the deepest body before the raise, else in the
%% body above before the call on the chain there, and so outwards.
%%
%% Raised is raised(Chain, Answered): Chain an ended(S, Name/Arity, In,
%% Fate) for each call on the way down (Fate raised or unwound -- or open
%% and redo, for a body the window saw no throw in), Answered none or that
%% failed call's why node, its clauses explained whoever's it is, the calls
%% under it as the options say (own(...), as flow_why/3's);
%% flow_why_furthest([Answered], Path) is where it got furthest. It fails
%% for a run that did not end in an exception.
flow_why_raised(Run, Raised) :-
    flow_why_raised(Run, Raised, []).

flow_why_raised(Run, Raised, Opts) :-
    Run = run(How, _, _, _, Calls, _, _, _),
    How = exception(_),
    flow_why_own_opt(Opts, Own),
    flow_dbg_raised(Calls, Own, Raised).

flow_dbg_raised(Calls, Own, raised(Chain, Answered)) :-
    flow_dbg_why_index(Calls, ByS, Kids),
    flow_dbg_raise_chain(0, ByS, Kids, Ss),
    findall(ended(S, P, In, F), ( member(S, Ss), get_assoc(S, ByS, call(S, P, _, _, _, _, _, In, _, F)) ), Chain),
    reverse([0|Ss], Up),
    (   flow_dbg_answered(Up, none, ByS, Kids, A)
    ->  flow_dbg_why_root(A, ByS, Kids, Own, Answered)
    ;   Answered = none
    ).

%% at each level the last call the exception ended -- the raise is the
%% latest thing the run did, so on every level of its chain it is the
%% call made last
flow_dbg_raise_chain(P, ByS, Kids, Chain) :-
    (   get_assoc(P, Kids, Ks),
        reverse(Ks, Rev),
        once(( member(S, Rev), get_assoc(S, ByS, C), arg(10, C, Fate),
               memberchk(Fate, [raised, unwound, open, redo]) ))
    ->  Chain = [S|Rest],
        flow_dbg_raise_chain(S, ByS, Kids, Rest)
    ;   Chain = []
    ).

%% the last call that failed having tried a clause, in a body on the chain
%% before the chain's call there, from the deepest body outwards
flow_dbg_answered([L|Ls], Child, ByS, Kids, A) :-
    (   get_assoc(L, Kids, Ks0) -> true ; Ks0 = [] ),
    (   Child == none -> Ks = Ks0 ; findall(K, ( member(K, Ks0), K < Child ), Ks) ),
    reverse(Ks, Rev),
    (   member(A0, Rev), get_assoc(A0, ByS, C), arg(10, C, fail), arg(7, C, [_|_])
    ->  A = A0
    ;   flow_dbg_answered(Ls, L, ByS, Kids, A)
    ).
