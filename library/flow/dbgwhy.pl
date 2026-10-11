%% library(flow/debug), part: why a run failed, read back from the recorded
%% window (DESIGN-flow.md 9.5, D4) -- the last failure and the failures it
%% came from.
%%
%%     flow_why(+Run, -Whys)
%%
%% Run is what flow_debug/4 hands back. Whys has a node for each call the
%% window saw begin at its top (the query, when it saw the whole run):
%%
%%     why(S, Name/Arity, In, Tries)   a call of the program's own that FAILED:
%%                                     each clause it tried, in order --
%%                                     nohead(K), its head did not unify, or
%%                                     entered(K, Goals), its body entered and
%%                                     the calls it made, the one it failed at
%%                                     last among them
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
%% pear], T0)', whose second clause's failed at `price(banana, P)', neither
%% of whose heads unified: the price of a banana is nowhere -- found by
%% reading, not by stepping.

flow_why(Run, Whys) :-
    Run = run(_, _, _, _, Calls, _, _, _),
    flow_dbg_why(Calls, Whys).

%% the nodes for the window's top calls, from its calls
flow_dbg_why(Calls, Whys) :-
    findall(S-C, ( member(C, Calls), arg(1, C, S) ), SC),
    list_to_assoc(SC, ByS),
    findall(P-S, member(call(S, _, _, P, _, _, _, _, _, _), Calls), PS0),
    keysort(PS0, PS),
    flow_dbg_why_kids(PS, Kids),
    (   get_assoc(0, Kids, Tops) -> true ; Tops = [] ),
    findall(W, ( member(S, Tops), flow_dbg_why_node(S, ByS, Kids, W) ), Whys).

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
    get_assoc(S, ByS, call(S, Pred, _, _, _, Panel, Clauses, In, Out, Fate)),
    (   Fate == exit
    ->  W = exited(S, Pred, In, Out)
    ;   Fate == fail, Panel \== none, Clauses \== []
    ->  (   get_assoc(S, Kids, Ks) -> true ; Ks = [] ),
        flow_dbg_why_tries(Clauses, Ks, ByS, Kids, Tries),
        W = why(S, Pred, In, Tries)
    ;   Fate == fail
    ->  W = failed(S, Pred, In)
    ;   W = ended(S, Pred, In, Fate)
    ).

%% each clause tried: its head did not unify, or its body was entered and
%% made the calls after it, up to and with the one whose failure tried the
%% next clause: a retry takes no inference, so the next clause is entered
%% at the inference of that call, and its own calls come after it
flow_dbg_why_tries([], _, _, _, []).
flow_dbg_why_tries([nohead(K, _)|Cs], Ks, ByS, Kids, [nohead(K)|Ts]) :- !,
    flow_dbg_why_tries(Cs, Ks, ByS, Kids, Ts).
flow_dbg_why_tries([c(K, At)|Cs], Ks, ByS, Kids, [entered(K, Goals)|Ts]) :-
    (   flow_dbg_why_next(Cs, Next) -> true ; Next = inf ),
    findall(G, ( member(S2, Ks), S2 > At, ( Next == inf -> true ; S2 =< Next ),
                 flow_dbg_why_node(S2, ByS, Kids, G) ),
            Goals),
    flow_dbg_why_tries(Cs, Ks, ByS, Kids, Ts).

%% the inference of the next clause entered (a head that did not unify is
%% tried on the way to it, at the same inference)
flow_dbg_why_next([c(_, At)|_], At) :- !.
flow_dbg_why_next([_|Cs], At) :-
    flow_dbg_why_next(Cs, At).
