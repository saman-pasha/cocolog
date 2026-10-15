%% library(flow/debug), part: a recorded window matched to the chart.
%%
%% The events '$trace_window'/4 records name calls by their goal's cell and
%% say nothing of the source; the chart names boxes and says nothing of a
%% run. This part joins them: each CALL the window saw is given the box it
%% is in the chart -- query.g1 for the goal, p3.c2.g4 for the fourth goal of
%% the third panel's second clause -- and the panel it entered, by walking
%% each clause activation's events against the clause's goals in the order
%% they can run (DESIGN-flow.md 9.5):
%%
%%     a call made after the activation entered a clause is the clause's
%%     first goal; one made after a goal exited is the goal after it; one
%%     made after a goal failed is where that failure goes -- the next
%%     arm's condition, the else, the next branch, past a \+ that holds --
%%     and a call no such place expects goes to the next box of its
%%     predicate in the clause, in the order the source writes them.
%%
%% A call whose own caller began before the window opened has no clause to
%% be matched in: it is placed in a panel of its predicate, as near its
%% call pattern as the chart has one, and no box.
%%
%% A CLAUSE THE CHART DOES NOT DRAW is matched too when the caller hands
%% its body over (1.11.7, from cicili-lang's report): a program debugged
%% from a small top file calls into files the chart has no panel for, and
%% the reasons an exception was raised are in those clauses. Its calls are
%% placed by the same walk, against the clause's own goals, and each gets
%% the place it has there for its box -- `cpp_not_abstract/1#c1.g1.a2.g1',
%% the predicate, `#', the clause and the path the chart's ids would have
%% -- an id no box of the chart has (a chart's never holds a `/').
%%
%%     flow_dbg_match(+Graph, +Events, -Calls)
%%     flow_dbg_match(+Graph, +Events, +Bodies, -Calls)
%%
%% Bodies none, or a goal called as call(Bodies, Needed, Found): Needed is
%% Name/Arity-K for each clause entered by a call no end port ended (an
%% exception, or the window closing on it) and with no panel, Found
%% (Name/Arity-K)-Body for each that it can read (debug.pl reads the
%% program's own files).
%%
%% Calls is a list, in the order the calls were made, of
%%
%%     call(S, Pred, Depth, Parent, Box, Panel, Clauses, In, Out, Fate)
%%
%% S the inference of the Call (a call's own name from here on), Pred N/A,
%% Parent the S of the call it is in (0: none in the window), Box the
%% chart's id for it or none, Panel the panel it entered (p3) or none,
%% Clauses the clauses it entered as c(N, At) and the heads it tried that
%% did not match as nohead(N, At) -- a clause the index passed over is
%% not one (1.11.2) -- and, in the order of their inferences with them,
%% thrown(Box, At) for each exception its own body raised where no call
%% of it was running (1.11.7): a throw/1, which makes no call, at the box
%% the chart draws it as -- In and Out the argument texts at its Call and
%% at its last Exit (none), and Fate exit, fail, open (still running when
%% the window closed) or redo (re-entered and not done when it closed).

%% ======================================================================
%% The calls the events make
%% ======================================================================
%%
%% A cell names one call at a time: a cell is used again only once
%% backtracking has gone back past every call made after it, so an Exit,
%% a Fail or a Redo is about the latest Call of its cell.

flow_dbg_match(Graph, Events, Calls) :-
    flow_dbg_match(Graph, Events, none, Calls).

flow_dbg_match(graph(_, _, Panels, Ids, _), Events, Bodies, Calls) :-
    flow_dbg_index(Events, Calls0, Streams),
    flow_dbg_rows(Panels, Rows0),
    flow_dbg_undrawn(Bodies, Calls0, Rows0, Rows, VAt),
    flow_dbg_place(Calls0, Streams, Rows, Panels, Ids, VAt, Calls).

%% THE CALLS, each with its own facts, and for each call the STREAM of what
%% happened inside it -- its children's ports and its own clauses, Redos,
%% catches and throws, in order -- BY SORTING (1.11.10). Each event is keyed
%% and the keys are sorted, keysort/2 being the engine's and stable: which
%% call a cell names at each event (flow_dbg_owners/2), then each call's
%% events, then each stream's items, each a walk down a sorted list.
%% Through 1.11.9 one pass kept three AVL trees -- the cells, the calls,
%% the streams -- and put into them at every event: a window of 100 000
%% inferences of the translator, 268 339 events, took 14 s here (the
%% reasoning session's point 8). A call's clauses and heads come in the
%% order they were tried (through 1.11.1 each was appended to the list
%% before it, and a call with n heads cost n * n / 2 cells).
flow_dbg_index(Events, Calls, Streams) :-
    flow_dbg_owners(Events, Owners),
    flow_dbg_owner_items(Events, 1, Owners, Items0),
    keysort(Items0, Items),
    flow_dbg_calls_of(Items, Calls, SIs0, []),
    keysort(SIs0, SIs),
    flow_dbg_stream_groups(SIs, Groups),
    list_to_assoc(Groups, Streams).

%% WHICH CALL A CELL NAMES AT EACH EVENT: the latest Call made with it. The
%% events that name a cell keyed by it -- its Calls, and the events that
%% ask (an Exit, a Fail, a Redo, a clause, a head, a catch, a throw; and a
%% Call, of its parent's cell) -- and sorted keep their order, so each
%% asker comes after the Calls before it. Owners is Pos-S for each asker,
%% in the order of the events (Pos, from 1), S 0 for a cell that named no
%% call the window saw
flow_dbg_owners(Events, Owners) :-
    flow_dbg_cell_items(Events, 1, CIs),
    keysort(CIs, SCIs),
    flow_dbg_cell_walk(SCIs, none, 0, Asked),
    keysort(Asked, Owners).

flow_dbg_cell_items([], _, []).
flow_dbg_cell_items([E|Es], Pos, Items) :-
    flow_dbg_cell_item(E, Pos, Items, Items1),
    Pos1 is Pos + 1,
    flow_dbg_cell_items(Es, Pos1, Items1).

%% a Call asks of its parent's cell BEFORE it names its own: a last call
%% can be made with its caller's cell (append/3's recursion), and is then
%% its caller's child, not its own
flow_dbg_cell_item(call(I, _, C, PC, _, _), Pos, Items, T) :- !,
    (   PC =\= 0 -> Items = [PC-(Pos-ask), C-(Pos-I)|T] ; Items = [C-(Pos-I)|T] ).
flow_dbg_cell_item(E, Pos, [C-(Pos-ask)|T], T) :-
    flow_dbg_event_cell(E, C), !.
flow_dbg_cell_item(_, _, T, T).

flow_dbg_event_cell(exit(_, _, C, _, _), C).
flow_dbg_event_cell(fail(_, _, C, _, _), C).
flow_dbg_event_cell(redo(_, _, C, _, _), C).
flow_dbg_event_cell(clause(_, _, C, _), C).
flow_dbg_event_cell(nohead(_, _, C, _), C).
flow_dbg_event_cell(catch(_, _, C), C).
flow_dbg_event_cell(throw(_, _, C, _), C).

flow_dbg_cell_walk([], _, _, []).
flow_dbg_cell_walk([C-(Pos-X)|Is], C0, S0, Out) :-
    (   C == C0 -> S1 = S0 ; S1 = 0 ),
    (   X == ask -> Out = [Pos-S1|Out1], S2 = S1
    ;   Out = Out1, S2 = X
    ),
    flow_dbg_cell_walk(Is, C, S2, Out1).

%% each event keyed by the call it is about, S-(Pos-What): a Call's own,
%% with its parent; an event about a call the window did not see, none
flow_dbg_owner_items([], _, _, []).
flow_dbg_owner_items([E|Es], Pos, Ow0, Items) :-
    (   Ow0 = [Pos-S|Ow1] -> true ; S = 0, Ow1 = Ow0 ),
    flow_dbg_owner_item(E, Pos, S, Items, Items1),
    Pos1 is Pos + 1,
    flow_dbg_owner_items(Es, Pos1, Ow1, Items1).

flow_dbg_owner_item(call(I, D, _, _, N, As), Pos, P, [I-(Pos-base(N/A, D, P, As))|T], T) :- !,
    length(As, A).
flow_dbg_owner_item(_, _, 0, T, T) :- !.
flow_dbg_owner_item(exit(_, _, _, _, As), Pos, S, [S-(Pos-exit(As))|T], T) :- !.
flow_dbg_owner_item(fail(_, _, _, _, _), Pos, S, [S-(Pos-fail)|T], T) :- !.
flow_dbg_owner_item(redo(_, _, _, _, _), Pos, S, [S-(Pos-redo)|T], T) :- !.
flow_dbg_owner_item(clause(I, _, _, K), Pos, S, [S-(Pos-clause(K, I))|T], T) :- !.
flow_dbg_owner_item(nohead(I, _, _, K), Pos, S, [S-(Pos-nohead(K, I))|T], T) :- !.
flow_dbg_owner_item(catch(_, _, _), Pos, S, [S-(Pos-catch)|T], T) :- !.
%% a throw, in the body it was raised in: by a call of it still running, or
%% by the body itself (throw/1, which has no port of its own)
flow_dbg_owner_item(throw(I, _, _, _), Pos, S, [S-(Pos-throw(I))|T], T) :- !.
flow_dbg_owner_item(_, _, _, T, T).

%% each call from its events, sorted by the call, its Call first; and the
%% items each event adds to a stream, (Owner-Pos)-Item: a port of a child
%% to its caller's, a clause, a Redo, a catch or a throw to its own
flow_dbg_calls_of([], [], SIs, SIs).
flow_dbg_calls_of([S-(Pos-base(Pr, D, P, In))|Is], [c(S, Pr, D, P, Cl, In, Out, Fa)|Cs], SIs0, SIs) :- !,
    flow_dbg_up_item(P, Pos, ccall(S, Pr, In), SIs0, SIs1),
    flow_dbg_call_events(Is, S, P, [], Cl0, none, Out, open, Fa, Rest, SIs1, SIs2),
    reverse(Cl0, Cl),
    flow_dbg_calls_of(Rest, Cs, SIs2, SIs).
flow_dbg_calls_of([_|Is], Cs, SIs0, SIs) :-
    flow_dbg_calls_of(Is, Cs, SIs0, SIs).

flow_dbg_call_events([S1-(Pos-X)|Is], S, P, Cl0, Cl, O0, O, F0, F, Rest, SIs0, SIs) :-
    S1 == S, !,
    flow_dbg_call_event(X, S, P, Pos, Cl0, Cl1, O0, O1, F0, F1, SIs0, SIs1),
    flow_dbg_call_events(Is, S, P, Cl1, Cl, O1, O, F1, F, Rest, SIs1, SIs).
flow_dbg_call_events(Is, _, _, Cl, Cl, O, O, F, F, Is, SIs, SIs).

flow_dbg_call_event(exit(As), S, P, Pos, Cl, Cl, _, As, _, exit, SIs0, SIs) :- !,
    flow_dbg_up_item(P, Pos, cexit(S), SIs0, SIs).
flow_dbg_call_event(fail, S, P, Pos, Cl, Cl, O, O, _, fail, SIs0, SIs) :- !,
    flow_dbg_up_item(P, Pos, cfail(S), SIs0, SIs).
%% a Redo is in the call itself too: an alternative of its body is taken,
%% or its next clause is tried
flow_dbg_call_event(redo, S, P, Pos, Cl, Cl, O, O, _, redo, SIs0, SIs) :- !,
    flow_dbg_up_item(P, Pos, credo(S), SIs0, [(S-Pos)-sredo|SIs]).
flow_dbg_call_event(clause(K, I), S, _, Pos, Cl, [c(K, I)|Cl], O, O, F, F, [(S-Pos)-sclause(K)|SIs], SIs) :- !.
flow_dbg_call_event(nohead(K, I), _, _, _, Cl, [nohead(K, I)|Cl], O, O, F, F, SIs, SIs) :- !.
flow_dbg_call_event(catch, S, _, Pos, Cl, Cl, O, O, F, F, [(S-Pos)-scatch|SIs], SIs) :- !.
flow_dbg_call_event(throw(I), S, _, Pos, Cl, Cl, O, O, F, F, [(S-Pos)-sthrow(I)|SIs], SIs) :- !.
flow_dbg_call_event(_, _, _, _, Cl, Cl, O, O, F, F, SIs, SIs).

%% an item for the caller's stream: none when the caller began before the
%% window
flow_dbg_up_item(0, _, _, SIs, SIs) :- !.
flow_dbg_up_item(P, Pos, X, [(P-Pos)-X|SIs], SIs).

%% the stream items sorted by owner and place: Owner-Items for each owner
flow_dbg_stream_groups([], []).
flow_dbg_stream_groups([(O-_)-X|Is], [O-[X|Xs]|Gs]) :-
    flow_dbg_stream_run(Is, O, Xs, Rest),
    flow_dbg_stream_groups(Rest, Gs).

flow_dbg_stream_run([(O1-_)-X|Is], O, [X|Xs], Rest) :-
    O1 == O, !,
    flow_dbg_stream_run(Is, O, Xs, Rest).
flow_dbg_stream_run(Is, _, [], Is).

flow_dbg_stream(S, Streams, Xs) :-
    (   get_assoc(S, Streams, Xs0) -> Xs = Xs0 ; Xs = [] ).

%% ======================================================================
%% A clause, planned: where each of its goals goes on
%% ======================================================================
%%
%% For every box a call can land on, e(Id, Pred, Succ, Fail, Inner):
%% Pred its predicate (`*' for a closure, which can be anything), Succ the
%% box a call is made at next when it exits and Fail when it fails --
%% goal(Id), or wait when what comes next is a Redo, the end of the
%% clause or a construct's own port, and nothing to match -- and Inner,
%% for a meta-call with ports of its own (findall/3), the first box of
%% its goal. A catch/3 is e(Id, catch, Try, Recover, none) for the box a
%% call made after it caught goes to.

flow_dbg_rows(Panels, Rows) :-
    empty_assoc(R0),
    flow_dbg_rows_(Panels, R0, Rows).

flow_dbg_rows_([], R, R).
flow_dbg_rows_([panel(Id, _, _, _, _, rows(Rs), _, _)|Ps], R0, R) :- !,
    flow_panel_id(Id, PId),
    flow_dbg_rows_of(Rs, PId, R0, R1),
    flow_dbg_rows_(Ps, R1, R).
flow_dbg_rows_([_|Ps], R0, R) :-
    flow_dbg_rows_(Ps, R0, R).

flow_dbg_rows_of([], _, R, R).
flow_dbg_rows_of([row(K, _, _, _, Nodes, _)|Rs], PId, R0, R) :-
    (   PId == query
    ->  Base = query
    ;   atomic_list_concat([PId, '.c', K], Base)
    ),
    flow_dbg_plan_list(Nodes, Base, wait, wait, Es, First),
    list_to_assoc_dups(Es, Plan),
    put_assoc(PId-K, R0, row(First, Es, Plan), R1),
    flow_dbg_rows_of(Rs, PId, R1, R).

%% the entries, keyed by box, kept in source order too
list_to_assoc_dups(Es, A) :-
    findall(Id-E, ( member(E, Es), arg(1, E, Id) ), Ps),
    list_to_assoc(Ps, A).

%% flow_dbg_plan_list(+Items, +Base, +K, +Default, -Entries, -First):
%% K is where a call goes when the whole list has exited, Default where a
%% failure goes when nothing to its left can redo; First is where a call
%% goes on entering the list. Items are named as the XML names them.
flow_dbg_plan_list(Items, Base, K, Default, Es, First) :-
    flow_dbg_index_items(Items, Base, 1, Named),
    flow_dbg_plan_items(Named, K, Default, [], Es, First).

flow_dbg_index_items([], _, _, []).
flow_dbg_index_items([N|Ns], Base, K, [Id-N|R]) :-
    atomic_list_concat([Base, '.g', K], Id),
    K1 is K + 1,
    flow_dbg_index_items(Ns, Base, K1, R).

%% left to right for the failures (the nearest item to the left that can
%% redo, or past a cut the list's way out), right to left for the exits:
%% done here by planning the rest first and the item with the rest's first
flow_dbg_plan_items([], K, _, _, [], K).
flow_dbg_plan_items([Id-N|Rest], K, Default, Left, Es, First) :-
    flow_dbg_fail_target(Left, Default, F),
    flow_dbg_plan_items(Rest, K, Default, [Id-N|Left], Es1, Next),
    flow_dbg_plan_item(N, Id, Next, F, Es0, First),
    append(Es0, Es1, Es).

flow_dbg_fail_target([], Default, Default).
flow_dbg_fail_target([_-N|Left], Default, T) :-
    (   N == cut -> T = wait
    ;   flow_node_nondet(N) -> T = wait
    ;   flow_dbg_fail_target(Left, Default, T)
    ).

%% one item: its entries and where a call goes on reaching it
flow_dbg_plan_item(g(G, Kind, _, _, Key, _), Id, K, F, [e(Id, Pred, K, F, none)], goal(Id)) :- !,
    (   Kind == closure -> Pred = '*'
    ;   Key = N/A -> Pred = N/A
    ;   functor(G, N, A), Pred = N/A
    ).
flow_dbg_plan_item(failn, Id, K, F, [e(Id, fail/0, K, F, none)], goal(Id)) :- !.
flow_dbg_plan_item(cut, _, K, _, [], K) :- !.
%% a throw/1 makes no call: no entry, and thrown(Id) where a call would be
%% expected -- no call is, and a throw the body makes there is placed on it
flow_dbg_plan_item(thrown(_), Id, _, _, [], thrown(Id)) :- !.
flow_dbg_plan_item(ite(_, Arms, Else), Id, K, F, Es, First) :- !,
    (   Else == none -> EFirst = F, EEs = []
    ;   atom_concat(Id, '.else', EBase),
        flow_dbg_plan_list(Else, EBase, K, F, EEs, EFirst)
    ),
    flow_dbg_plan_arms(Arms, 1, Id, K, F, EFirst, AEs, First),
    append(AEs, EEs, Es).
flow_dbg_plan_item(or(Bs), Id, K, F, Es, First) :- !,
    flow_dbg_plan_branches(Bs, 1, Id, K, F, Es, First).
flow_dbg_plan_item(not(Ns), Id, K, F, Es, First) :- !,
    %% the goal proved: \+ fails, as F says; the goal failed: \+ holds
    flow_dbg_plan_list(Ns, Id, F, K, Es, First).
flow_dbg_plan_item(meta(Name, Head, _, Ts, _), Id, K, F, Es, First) :- !,
    (   Ts = [Ns] -> true ; Ns = [] ),
    (   memberchk(Name, [once, ignore])
    ->  %% control constructs: no port of their own
        ( Name == ignore -> FD = K ; FD = F ),
        flow_dbg_plan_list(Ns, Id, K, FD, Es, First)
    ;   functor(Head, HN, HA),
        flow_dbg_plan_list(Ns, Id, wait, wait, IEs, IFirst),
        Es = [e(Id, HN/HA, K, F, IFirst)|IEs],
        First = goal(Id)
    ).
flow_dbg_plan_item(catchc(G, _, R), Id, K, F, Es, First) :- !,
    atom_concat(Id, '.try', TBase),
    atom_concat(Id, '.recover', RBase),
    flow_dbg_plan_list(G, TBase, K, F, TEs, First),
    flow_dbg_plan_list(R, RBase, K, F, REs, RFirst),
    append([[e(Id, catch, First, RFirst, none)], TEs, REs], Es).
flow_dbg_plan_item(_, _, K, _, [], K).

flow_dbg_plan_arms([], _, _, _, _, EFirst, [], EFirst).
flow_dbg_plan_arms([arm(C, T)|As], J, Id, K, F, EFirst, Es, First) :-
    atomic_list_concat([Id, '.a', J], TBase),
    atom_concat(TBase, '.if', CBase),
    J1 is J + 1,
    flow_dbg_plan_arms(As, J1, Id, K, F, EFirst, Es2, NextArm),
    flow_dbg_plan_list(T, TBase, K, F, TEs, TFirst),
    flow_dbg_plan_list(C, CBase, TFirst, NextArm, CEs, First),
    append([CEs, TEs, Es2], Es).

flow_dbg_plan_branches([], _, _, _, F, [], F).
flow_dbg_plan_branches([B|Bs], J, Id, K, F, Es, First) :-
    atomic_list_concat([Id, '.b', J], BBase),
    J1 is J + 1,
    flow_dbg_plan_branches(Bs, J1, Id, K, F, Es2, NextB),
    flow_dbg_plan_list(B, BBase, K, NextB, BEs, First),
    append(BEs, Es2, Es).

%% ======================================================================
%% Placing the calls
%% ======================================================================

%% DOWN THE CALL TREE (1.11.10). A call's place -- its box and the panel it
%% enters -- is its caller's walk's to give: each call that began with no
%% caller in the window is placed and walked, then each call its walk met,
%% the same way, so a call's own place is known before its children are
%% matched in its clauses -- in its panel's, or, with no panel, in the
%% clauses read for it (VAt: S -> its rows' key). Through 1.11.9 the calls
%% were taken in the order they were made and every place went into one
%% AVL tree of them all, put into and read at each port of a child: 6 of
%% the 12 seconds the matching of a window of 100 000 inferences of the
%% translator still took.
flow_dbg_place(Calls0, Streams, Rows, Panels, Ids, VAt, Calls) :-
    %% the query's own goal: the box query.g1 and the panel it calls
    flow_dbg_query_panel(Panels, Ids, QPanel),
    flow_dbg_callees(Panels, Ids, Callees),
    flow_dbg_panels_by_pred(Panels, ByPred),
    Cx = cx(Panels, ByPred, Callees, Streams, Rows, VAt, QPanel),
    findall(k(S, root, Pr, In), member(c(S, Pr, _, 0, _, In, _, _), Calls0), Roots),
    flow_dbg_place_kids(Roots, Cx, Ws0, [], Ts0, []),
    keysort(Ws0, Ws),
    keysort(Ts0, Ts),
    flow_dbg_placed(Calls0, Ws, Ts, Calls).

%% each call with its place (none, none for one nothing placed) and its
%% throws among its clauses, the places and the throws sorted by call
flow_dbg_placed([], _, _, []).
flow_dbg_placed([c(S, Pr, D, P, Cl0, In, Out, Fa)|Cs], Ws0, Ts0,
                [call(S, Pr, D, P, Box, Panel, Cl, In, Out, Fa)|Calls]) :-
    (   Ws0 = [S1-at(B, Pn)|Ws1], S1 =:= S -> Box = B, Panel = Pn ; Box = none, Panel = none, Ws1 = Ws0 ),
    (   Ts0 = [S2-Th|Ts1], S2 =:= S -> flow_dbg_with_throws(Cl0, Th, Cl) ; Cl = Cl0, Ts1 = Ts0 ),
    flow_dbg_placed(Cs, Ws1, Ts1, Calls).

%% a call's clauses and heads, and the throws its own body made, in the
%% order of their inferences
flow_dbg_with_throws(Cl0, Ts, Cl) :-
    findall(At-X, ( ( member(X, Cl0) ; member(X, Ts) ), arg(2, X, At) ), AXs),
    keysort(AXs, Sorted),
    findall(X, member(_-X, Sorted), Cl).

flow_dbg_query_panel(Panels, Ids, PId) :-
    (   memberchk(panel(0, _, _, _, _, rows([row(_, _, _, _, [g(_, Kind, Ms, _, Key, _)], _)]), _, _), Panels),
        flow_callable_kind(Kind), flow_panel_key(Kind, Key, Ms, PK),
        get_assoc(0-PK, Ids, CId)
    ->  flow_panel_id(CId, PId)
    ;   PId = none
    ).

%% the calls a walk met, each placed and walked in turn: k(S, Given, Pred,
%% In), Given its caller's place for it, at(Box, Panel); unplaced, when the
%% walk found it no box; or root, a call whose caller began before the
%% window. Ws gets S-at(Box, Panel) for each, Ts S-Throws for each whose
%% body threw
flow_dbg_place_kids([], _, Ws, Ws, Ts, Ts).
flow_dbg_place_kids([k(S, Given, Pr, In)|Ks], Cx, [S-at(Box, Panel)|Ws0], Ws, Ts0, Ts) :-
    Cx = cx(Panels, ByPred, _, Streams, _, VAt, QPanel),
    (   Given = at(B0, P0)
    ->  %% placed in a clause the chart does not draw, whose ids name no
        %% panel: a predicate the chart draws is walked in its own
        Box = B0,
        (   P0 == none, atom(B0), sub_atom(B0, _, _, _, '#'),
            flow_dbg_panel_for(Pr, In, ByPred, PId0), PId0 \== none
        ->  Panel = PId0
        ;   Panel = P0
        )
    ;   Given == root, flow_dbg_is_query(S, Pr, QPanel, Panels)
    ->  Box = 'query.g1', Panel = QPanel
    ;   Box = none,
        flow_dbg_panel_for(Pr, In, ByPred, Panel)
    ),
    (   Panel == none, get_assoc(S, VAt, VPId) -> WPanel = VPId ; WPanel = Panel ),
    flow_dbg_stream(S, Streams, Xs),
    flow_dbg_walk(Xs, S, WPanel, Cx, Kids, Thrown),
    (   Thrown == [] -> Ts1 = Ts0 ; Ts0 = [S-Thrown|Ts1] ),
    flow_dbg_place_kids(Kids, Cx, Ws0, Ws1, Ts1, Ts2),
    flow_dbg_place_kids(Ks, Cx, Ws1, Ws, Ts2, Ts).

%% ======================================================================
%% The clauses the chart does not draw
%% ======================================================================
%%
%% The calls no end port ended -- an exception ended them, or they were
%% still running when the window closed -- that entered a clause: each
%% clause they entered, read by Bodies, is planned as a row of its own,
%% keyed '#Name/Arity'-K (no panel's id begins with `#'), its ids based
%% `Name/Arity#cK'. A call that turns out to have a panel walks the
%% panel's rows as before; one with none walks these.
flow_dbg_undrawn(none, _, Rows, Rows, VAt) :- !,
    empty_assoc(VAt).
flow_dbg_undrawn(Bodies, Calls0, Rows0, Rows, VAt) :-
    findall(S-Pr-Cl, ( member(c(S, Pr, _, _, Cl, _, _, Fa), Calls0), memberchk(Fa, [open, redo]),
                       memberchk(c(_, _), Cl) ),
            Ends),
    findall(Pr-K, ( member(_-Pr-Cl, Ends), member(c(K, _), Cl) ), Needed0),
    sort(Needed0, Needed),
    (   Needed == [] -> Found = []
    ;   catch(call(Bodies, Needed, Found), _, Found = [])
    ),
    flow_dbg_undrawn_rows(Found, Rows0, Rows),
    findall(S-VPId, ( member(S-Pr-_, Ends), memberchk((Pr-_)-_, Found), flow_dbg_vpanel(Pr, VPId) ), SV),
    list_to_assoc(SV, VAt).

flow_dbg_undrawn_rows([], R, R).
flow_dbg_undrawn_rows([(Pr-K)-B|Fs], R0, R) :-
    flow_dbg_vpanel(Pr, VPId),
    Pr = N/A,
    format(atom(Base), '~w/~w#c~w', [N, A, K]),
    (   catch(flow_dbg_body_nodes(B, Nodes), _, fail)
    ->  flow_dbg_plan_list(Nodes, Base, wait, wait, Es, First),
        list_to_assoc_dups(Es, Plan),
        put_assoc(VPId-K, R0, row(First, Es, Plan), R1)
    ;   R1 = R0
    ),
    flow_dbg_undrawn_rows(Fs, R1, R).

flow_dbg_vpanel(N/A, VPId) :-
    format(atom(VPId), '#~w/~w', [N, A]).

%% A CLAUSE'S BODY AS THE NODES ITS ROW IS PLANNED FROM, read without the
%% chart's analysis: each goal by its predicate, the control constructs as
%% flow_an_item/7 draws them (analyse.pl). A grammar rule's body is
%% translated as the engine translates it, its leading terminal lifted into
%% the head as the store does.
flow_dbg_body_nodes('$flow_dcg'(B0), Ns) :- !,
    '$dcg_goal'(B0, S0, _, TB),
    flow_dcg_lift(TB, S0, B),
    flow_dbg_body_nodes(B, Ns).
flow_dbg_body_nodes(B, Ns) :-
    flow_conj(B, Gs),
    flow_dbg_goals_nodes(Gs, Ns).

flow_dbg_goals_nodes([], []).
flow_dbg_goals_nodes([G|Gs], Ns) :-
    flow_dbg_goal_nodes(G, N1),
    flow_dbg_goals_nodes(Gs, N2),
    append(N1, N2, Ns).

flow_dbg_goal_nodes(V, [g(call(V), closure, [], nondet, none, [])]) :- var(V), !.
flow_dbg_goal_nodes(_:G, Ns) :- !, flow_dbg_goal_nodes(G, Ns).
flow_dbg_goal_nodes(!, [cut]) :- !.
flow_dbg_goal_nodes(fail, [failn]) :- !.
flow_dbg_goal_nodes(false, [failn]) :- !.
flow_dbg_goal_nodes(throw(E), [thrown(E)]) :- !.
flow_dbg_goal_nodes((C -> T ; E), [ite(hard, Arms, Else)]) :- !,
    flow_dbg_ite_nodes((C -> T ; E), Arms, Else).
flow_dbg_goal_nodes((C *-> T ; E), [ite(soft, [arm(Cn, Tn)], En)]) :- !,
    flow_dbg_body_nodes(C, Cn),
    flow_dbg_body_nodes(T, Tn),
    flow_dbg_body_nodes(E, En).
flow_dbg_goal_nodes((A ; B), [or(Bs)]) :- !,
    flow_disj((A ; B), Ds),
    maplist(flow_dbg_body_nodes, Ds, Bs).
flow_dbg_goal_nodes((C -> T), [ite(hard, [arm(Cn, Tn)], none)]) :- !,
    flow_dbg_body_nodes(C, Cn),
    flow_dbg_body_nodes(T, Tn).
flow_dbg_goal_nodes(\+ G, [not(Ns)]) :- !, flow_dbg_body_nodes(G, Ns).
flow_dbg_goal_nodes(not(G), [not(Ns)]) :- !, flow_dbg_body_nodes(G, Ns).
flow_dbg_goal_nodes(findall(T, G, L), [meta(findall, findall(T, '…', L), [], [Ns], [])]) :- !,
    flow_dbg_body_nodes(G, Ns).
flow_dbg_goal_nodes(findall(T, G, L, R), [meta(findall, findall(T, '…', L, R), [], [Ns], [])]) :- !,
    flow_dbg_body_nodes(G, Ns).
flow_dbg_goal_nodes(aggregate_all(Sp, G, R), [meta(aggregate_all, aggregate_all(Sp, '…', R), [], [Ns], [])]) :- !,
    flow_dbg_body_nodes(G, Ns).
flow_dbg_goal_nodes(forall(C, A), [meta(forall, forall('…', '…'), [], [Ns], [])]) :- !,
    flow_dbg_body_nodes((C, A), Ns).
flow_dbg_goal_nodes(once(G), [meta(once, once('…'), [], [Ns], [])]) :- !,
    flow_dbg_body_nodes(G, Ns).
flow_dbg_goal_nodes(ignore(G), [meta(ignore, ignore('…'), [], [Ns], [])]) :- !,
    flow_dbg_body_nodes(G, Ns).
flow_dbg_goal_nodes(catch(G, B, R), [catchc(Gn, B, Rn)]) :- !,
    flow_dbg_body_nodes(G, Gn),
    flow_dbg_body_nodes(R, Rn).
flow_dbg_goal_nodes(C, Ns) :-
    compound(C), functor(C, call, _), !,
    C =.. [call, G|Extra],
    (   flow_closure_goal(G, Extra, Goal) -> flow_dbg_body_nodes(Goal, Ns)
    ;   Extra == [] -> flow_dbg_goal_nodes(G, Ns)
    ;   Ns = [g(C, closure, [], nondet, none, [])]
    ).
flow_dbg_goal_nodes(G, [g(G, plain, [], det, N/A, [])]) :-
    callable(G), !,
    functor(G, N, A).
flow_dbg_goal_nodes(_, []).

flow_dbg_ite_nodes((C -> T ; E), [arm(Cn, Tn)|Arms], Else) :-
    flow_dbg_body_nodes(C, Cn),
    flow_dbg_body_nodes(T, Tn),
    (   nonvar(E), E = (C2 -> T2 ; E2)
    ->  flow_dbg_ite_nodes((C2 -> T2 ; E2), Arms, Else)
    ;   Arms = [],
        flow_dbg_body_nodes(E, Else)
    ).

%% the window's first call, with no parent in it, is the query's goal when
%% the window began at the first inference -- the goal's own predicate
flow_dbg_is_query(S, Pr, QPanel, Panels) :-
    S =:= 1,
    QPanel \== none,
    memberchk(panel(0, _, _, _, _, rows([row(_, _, _, _, [g(_, _, _, _, Pr, _)], _)]), _, _), Panels).

%% a call with no clause of its caller to be matched in: a panel of its
%% predicate, the one whose call pattern its arguments fit best -- among
%% its predicate's panels alone (ByPred, 1.11.10: each such call walked
%% every panel, 2 792 of them on the translator)
flow_dbg_panel_for(Pr, In, ByPred, PId) :-
    (   get_assoc(Pr, ByPred, IdCMs) -> true ; IdCMs = [] ),
    findall(Score-Id, ( member(Id-CM, IdCMs), flow_dbg_fit(CM, In, Score) ), Cands),
    (   Cands == [] -> PId = none
    ;   keysort(Cands, Sorted), last(Sorted, _-Id), flow_panel_id(Id, PId)
    ).

%% each predicate -> its panels a call can be walked in, Id-CallPattern in
%% the order the chart has them
flow_dbg_panels_by_pred(Panels, ByPred) :-
    findall(Pr-(Id-CM), ( member(panel(Id, Pr, Kind, CM, _, rows(_), _, _), Panels), Id \== 0,
                          Kind \= lane(_, _) ),
            Ps0),
    keysort(Ps0, Ps),
    group_pairs_by_key(Ps, ByPred0),
    list_to_assoc(ByPred0, ByPred).

%% THE PANEL EACH GOAL BOX CALLS, as the XML says calls=, worked out once
%% for every box of the chart (1.11.10): through 1.11.9 each call made in a
%% clause found its box's node again, walking the chart's panels and
%% naming every item on the way -- 18 of a window's 33 seconds of matching
%% on the translator, whose chart has 2 792 panels
flow_dbg_callees(Panels, Ids, Callees) :-
    findall(Box-Panel,
            ( member(panel(N, _, _, _, _, rows(Rs), _, _), Panels),
              flow_panel_id(N, PId),
              flow_dbg_lane_of(PId, Ids, L),
              member(row(K, _, _, _, Nodes, _), Rs),
              (   PId == query -> Base = query ; atomic_list_concat([PId, '.c', K], Base) ),
              flow_dbg_list_boxes(Nodes, Base, Bs, []),
              member(Box-g(_, Kind, Ms, _, Key, _), Bs),
              flow_callable_kind(Kind),
              flow_panel_key(Kind, Key, Ms, PK),
              get_assoc(L-PK, Ids, CId),
              flow_panel_id(CId, Panel) ),
            Pairs),
    list_to_assoc(Pairs, Callees).

%% every goal box of a list of items, Box-Node, named as the plan and
%% flow_dbg_find/4 name them
flow_dbg_list_boxes(Nodes, Base, Bs0, Bs) :-
    flow_dbg_index_items(Nodes, Base, 1, Named),
    flow_dbg_named_boxes(Named, Bs0, Bs).

flow_dbg_named_boxes([], Bs, Bs).
flow_dbg_named_boxes([Id-N|Ns], Bs0, Bs) :-
    flow_dbg_node_boxes(N, Id, Bs0, Bs1),
    flow_dbg_named_boxes(Ns, Bs1, Bs).

flow_dbg_node_boxes(N, Id, [Id-N|Bs], Bs) :-
    N = g(_, _, _, _, _, _), !.
flow_dbg_node_boxes(ite(_, Arms, Else), Id, Bs0, Bs) :- !,
    flow_dbg_arm_boxes(Arms, 1, Id, Bs0, Bs1),
    (   Else == none -> Bs = Bs1
    ;   atom_concat(Id, '.else', EB),
        flow_dbg_list_boxes(Else, EB, Bs1, Bs)
    ).
flow_dbg_node_boxes(or(Brs), Id, Bs0, Bs) :- !,
    flow_dbg_branch_boxes(Brs, 1, Id, Bs0, Bs).
flow_dbg_node_boxes(not(Ns), Id, Bs0, Bs) :- !,
    flow_dbg_list_boxes(Ns, Id, Bs0, Bs).
flow_dbg_node_boxes(meta(_, _, _, [Ns], _), Id, Bs0, Bs) :- !,
    flow_dbg_list_boxes(Ns, Id, Bs0, Bs).
flow_dbg_node_boxes(catchc(G, _, R), Id, Bs0, Bs) :- !,
    atom_concat(Id, '.try', TB),
    atom_concat(Id, '.recover', RB),
    flow_dbg_list_boxes(G, TB, Bs0, Bs1),
    flow_dbg_list_boxes(R, RB, Bs1, Bs).
flow_dbg_node_boxes(_, _, Bs, Bs).

flow_dbg_arm_boxes([], _, _, Bs, Bs).
flow_dbg_arm_boxes([arm(C, T)|As], J, Id, Bs0, Bs) :-
    atomic_list_concat([Id, '.a', J], TB),
    atom_concat(TB, '.if', CB),
    flow_dbg_list_boxes(C, CB, Bs0, Bs1),
    flow_dbg_list_boxes(T, TB, Bs1, Bs2),
    J1 is J + 1,
    flow_dbg_arm_boxes(As, J1, Id, Bs2, Bs).

flow_dbg_branch_boxes([], _, _, Bs, Bs).
flow_dbg_branch_boxes([B|Brs], J, Id, Bs0, Bs) :-
    atomic_list_concat([Id, '.b', J], BB),
    flow_dbg_list_boxes(B, BB, Bs0, Bs1),
    J1 is J + 1,
    flow_dbg_branch_boxes(Brs, J1, Id, Bs1, Bs).

%% how many arguments agree with the pattern: bound where it says +,
%% unbound where it says -
flow_dbg_fit(CM, In, Score) :-
    findall(x, ( nth1(I, CM, M), nth1(I, In, T),
                 flow_dbg_text_var(T, V),
                 ( M == '+', V == false ; M == '-', V == true ; M == '?' ) ),
            Xs),
    length(Xs, Score).

%% is the text of an argument an unbound variable
flow_dbg_text_var(cut(_, _), false) :- !.
flow_dbg_text_var(T, V) :-
    (   atom(T), sub_atom(T, 0, 2, _, '_G') -> V = true
    ;   T == '_' -> V = true
    ;   V = false
    ).

%% ======================================================================
%% One activation, walked
%% ======================================================================
%%
%% State: st(Row, Exp, Last, Next) -- the row being run (PId-K), the boxes
%% a call is expected at next, the last box a call landed on (for the
%% fallback), and where the body goes next as the plan says it, unread:
%% goal(Id), thrown(Id), wait, or running(C, Before) while the child C has
%% not ended. A THROW THE BODY MAKES ITSELF (1.11.7) is where Next points
%% when it comes: the plan's throw/1, or a goal that raised before its
%% Call port (an unknown procedure, call/1 of a variable). It is kept on
%% the activation's call as thrown(Box, At), with its clauses; a throw
%% while a child runs is the child's.

%% Kids, the calls the activation made: k(C, at(Box, Panel), Pred, In), or
%% k(C, unplaced, Pred, In) for one no box held, the latest first; Thrown,
%% thrown(Box, At) for each throw its own body made
flow_dbg_walk(Xs, S, PId, Cx, Kids, Thrown) :-
    arg(5, Cx, Rows),
    flow_dbg_walk_(Xs, a(S, PId), st(none, [], none, wait), Rows, Cx, [], Kids, [], Thrown).

flow_dbg_walk_([], _, _, _, _, K, K, Th, Th).
flow_dbg_walk_([X|Xs], A, St0, Rows, Cx, K0, K, Th0, Th) :-
    flow_dbg_step(X, A, St0, Rows, Cx, K0, Th0, St1, K1, Th1),
    flow_dbg_walk_(Xs, A, St1, Rows, Cx, K1, K, Th1, Th).

%% the activation entered a clause: its first goal is next
flow_dbg_step(sclause(K), a(_, PId), _, Rows, _, Ks, Th, st(Row, Exp, none, Next), Ks, Th) :- !,
    (   PId \== none, get_assoc(PId-K, Rows, Row)
    ->  Row = row(First, _, _), flow_dbg_target(First, Exp), Next = First
    ;   Row = none, Exp = [], Next = wait
    ).
flow_dbg_step(sredo, _, St, _, _, Ks, Th, St, Ks, Th) :- !.
flow_dbg_step(scatch, _, st(Row, _, Last, _), _, _, Ks, Th, st(Row, Exp, Last, Next), Ks, Th) :- !,
    (   Row = row(_, Es, _), flow_dbg_catch_of(Es, Last, RFirst)
    ->  flow_dbg_target(RFirst, Exp), Next = RFirst
    ;   Exp = [], Next = wait
    ).
%% a child's Call: the box it is at
flow_dbg_step(ccall(C, Pr, In), _, st(Row, Exp, Last, Next), _, Cx, Ks, Th,
              st(Row, Exp1, Last1, running(C, Next)), [k(C, At, Pr, In)|Ks], Th) :- !,
    (   Row = row(_, Es, Plan),
        flow_dbg_choose(Exp, Pr, Last, Es, Plan, Box)
    ->  get_assoc(Box, Plan, E),
        arg(3, Cx, Callees),
        (   get_assoc(Box, Callees, Panel) -> true ; Panel = none ),
        At = at(Box, Panel),
        Last1 = Box,
        (   E = e(_, _, _, _, Inner), Inner \== none -> flow_dbg_target(Inner, Exp1) ; Exp1 = [] )
    ;   At = unplaced, Last1 = Last, Exp1 = []
    ).
flow_dbg_step(cexit(C), _, st(Row, _, Last, Next0), _, _, Ks, Th, st(Row, Exp, Last, Next), Ks, Th) :- !,
    flow_dbg_after(C, Row, Ks, succ, Next0, Exp, Next).
flow_dbg_step(cfail(C), _, st(Row, _, Last, Next0), _, _, Ks, Th, st(Row, Exp, Last, Next), Ks, Th) :- !,
    flow_dbg_after(C, Row, Ks, fail, Next0, Exp, Next).
flow_dbg_step(credo(C), _, st(Row, _, _, Next), _, _, Ks, Th, st(Row, [], Last, running(C, Next)), Ks, Th) :- !,
    (   flow_dbg_kid_box(C, Ks, Box) -> Last = Box ; Last = none ).
flow_dbg_step(sthrow(I), _, st(Row, Exp, Last, Next), _, _, Ks, Th0, st(Row, Exp, Last1, Next), Ks, Th) :- !,
    (   ( Next = thrown(B) ; Next = goal(B) )
    ->  Th = [thrown(B, I)|Th0],
        Last1 = B
    ;   Th = Th0, Last1 = Last
    ).
flow_dbg_step(_, _, St, _, _, Ks, Th, St, Ks, Th).

%% the box the activation's walk gave a child it made: none when it gave
%% it none
flow_dbg_kid_box(C, Ks, Box) :-
    memberchk(k(C, At, _, _), Ks),
    At = at(Box, _),
    Box \== none.

%% where a call goes after a child's exit or failure: the plan's place, or,
%% for a child no box holds, where the body was going before it was called
flow_dbg_after(C, Row, Ks, Way, Next0, Exp, Next) :-
    (   Row = row(_, _, Plan),
        flow_dbg_kid_box(C, Ks, Box),
        get_assoc(Box, Plan, e(_, _, S, F, _))
    ->  ( Way == succ -> Next = S ; Next = F ),
        flow_dbg_target(Next, Exp)
    ;   Exp = [],
        ( Next0 = running(C, Before) -> Next = Before ; Next = wait )
    ).

flow_dbg_target(goal(Id), [Id]) :- !.
flow_dbg_target(_, []).

%% the box: one expected, of the call's predicate; else the next box of it
%% after the last one a call landed on, in source order; else the first
flow_dbg_choose(Exp, Pr, Last, Es, Plan, Box) :-
    (   member(B, Exp), get_assoc(B, Plan, e(_, BP, _, _, _)), flow_dbg_pred_fits(BP, Pr)
    ->  Box = B
    ;   flow_dbg_after_last(Es, Last, After),
        member(e(B, BP, _, _, _), After), flow_dbg_pred_fits(BP, Pr)
    ->  Box = B
    ;   member(e(B, BP, _, _, _), Es), flow_dbg_pred_fits(BP, Pr)
    ->  Box = B
    ).

flow_dbg_pred_fits('*', _) :- !.
flow_dbg_pred_fits(P, P).

flow_dbg_after_last(Es, none, Es) :- !.
flow_dbg_after_last(Es, Last, After) :-
    (   append(_, [e(Last, _, _, _, _)|After], Es) -> true ; After = Es ).

%% the catch/3 whose try a box is in
flow_dbg_catch_of(Es, Last, RFirst) :-
    Last \== none,
    member(e(Id, catch, _, RFirst, _), Es),
    atom_concat(Id, '.try', Try),
    sub_atom(Last, 0, _, _, Try), !.

flow_dbg_lane_of(query, _, 0) :- !.
flow_dbg_lane_of(PId, Ids, L) :-
    atom_concat(p, NA, PId), atom_number(NA, N),
    flow_panel_lane(Ids, N, L).

%% the node a box id names in a list of items, found again by naming the
%% items as the plan does
flow_dbg_find(Nodes, Base, Box, Node) :-
    flow_dbg_index_items(Nodes, Base, 1, Named),
    member(Id-N, Named),
    (   Id == Box -> Node = N
    ;   atom_concat(Id, '.', Pre), sub_atom(Box, 0, _, _, Pre)
    ->  flow_dbg_find_in(N, Id, Box, Node)
    ), !.

flow_dbg_find_in(ite(_, Arms, Else), Id, Box, Node) :-
    (   nth1(J, Arms, arm(C, T)),
        atomic_list_concat([Id, '.a', J], TB), atom_concat(TB, '.if', CB),
        ( flow_dbg_find(C, CB, Box, Node) ; flow_dbg_find(T, TB, Box, Node) )
    ;   Else \== none, atom_concat(Id, '.else', EB), flow_dbg_find(Else, EB, Box, Node)
    ), !.
flow_dbg_find_in(or(Bs), Id, Box, Node) :-
    nth1(J, Bs, B), atomic_list_concat([Id, '.b', J], BB), flow_dbg_find(B, BB, Box, Node), !.
flow_dbg_find_in(not(Ns), Id, Box, Node) :- flow_dbg_find(Ns, Id, Box, Node).
flow_dbg_find_in(meta(_, _, _, [Ns], _), Id, Box, Node) :- flow_dbg_find(Ns, Id, Box, Node).
flow_dbg_find_in(catchc(G, _, R), Id, Box, Node) :-
    (   atom_concat(Id, '.try', TB), flow_dbg_find(G, TB, Box, Node)
    ;   atom_concat(Id, '.recover', RB), flow_dbg_find(R, RB, Box, Node)
    ), !.
