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
%%     flow_dbg_match(+Graph, +Events, -Calls)
%%
%% Calls is a list, in the order the calls were made, of
%%
%%     call(S, Pred, Depth, Parent, Box, Panel, Clauses, In, Out, Fate)
%%
%% S the inference of the Call (a call's own name from here on), Pred N/A,
%% Parent the S of the call it is in (0: none in the window), Box the
%% chart's id for it or none, Panel the panel it entered (p3) or none,
%% Clauses the clauses it entered as c(N, At) and the heads that did not
%% match as nohead(N, At), In and Out the argument texts at its Call and at
%% its last Exit (none), and Fate exit, fail, open (still running when the
%% window closed) or redo (re-entered and not done when it closed).

%% ======================================================================
%% The calls the events make
%% ======================================================================
%%
%% A cell names one call at a time: a cell is used again only once
%% backtracking has gone back past every call made after it, so an Exit,
%% a Fail or a Redo is about the latest Call of its cell.

flow_dbg_match(graph(_, _, Panels, Ids, _), Events, Calls) :-
    flow_dbg_index(Events, Calls0, Streams),
    flow_dbg_rows(Panels, Rows),
    flow_dbg_place(Calls0, Streams, Rows, Panels, Ids, Calls).

%% one pass: the calls, each with its own facts, and for each call the
%% stream of what happened inside it -- its children's ports and its own
%% clauses, Redos and catches, in order
flow_dbg_index(Events, Calls, Streams) :-
    empty_assoc(Cells0),
    empty_assoc(Facts0),
    empty_assoc(Str0),
    flow_dbg_index_(Events, Cells0, Facts0, Facts, Str0, Str1, [], RevOrder),
    reverse(RevOrder, Order),
    findall(C, ( member(S, Order), get_assoc(S, Facts, C) ), Calls),
    Streams = Str1.

flow_dbg_index_([], _, F, F, St, St, O, O).
flow_dbg_index_([E|Es], Cells0, F0, F, St0, St, O0, O) :-
    flow_dbg_event(E, Cells0, Cells1, F0, F1, St0, St1, O0, O1),
    flow_dbg_index_(Es, Cells1, F1, F, St1, St, O1, O).

%% a Call: a new call, whose parent is the latest call of the parent cell
flow_dbg_event(call(I, D, C, PC, N, As), Cells0, Cells, F0, F, St0, St, O, [I|O]) :- !,
    length(As, A),
    (   PC =\= 0, get_assoc(PC, Cells0, P) -> true ; P = 0 ),
    put_assoc(C, Cells0, I, Cells),
    put_assoc(I, F0, c(I, N/A, D, P, [], As, none, open), F),
    flow_dbg_stream_add(P, ccall(I, N/A), St0, St).
flow_dbg_event(exit(_, _, C, _, As), Cells, Cells, F0, F, St0, St, O, O) :- !,
    (   get_assoc(C, Cells, S), get_assoc(S, F0, c(S, Pr, D, P, Cl, In, _, _))
    ->  put_assoc(S, F0, c(S, Pr, D, P, Cl, In, As, exit), F),
        flow_dbg_stream_add(P, cexit(S), St0, St)
    ;   F = F0, St = St0
    ).
flow_dbg_event(fail(_, _, C, _, _), Cells, Cells, F0, F, St0, St, O, O) :- !,
    (   get_assoc(C, Cells, S), get_assoc(S, F0, c(S, Pr, D, P, Cl, In, Out, _))
    ->  put_assoc(S, F0, c(S, Pr, D, P, Cl, In, Out, fail), F),
        flow_dbg_stream_add(P, cfail(S), St0, St)
    ;   F = F0, St = St0
    ).
flow_dbg_event(redo(_, _, C, _, _), Cells, Cells, F0, F, St0, St, O, O) :- !,
    (   get_assoc(C, Cells, S), get_assoc(S, F0, c(S, Pr, D, P, Cl, In, Out, _))
    ->  put_assoc(S, F0, c(S, Pr, D, P, Cl, In, Out, redo), F),
        flow_dbg_stream_add(P, credo(S), St0, St1),
        %% and inside the call itself: an alternative of its body is taken,
        %% or its next clause is tried
        flow_dbg_stream_add(S, sredo, St1, St)
    ;   F = F0, St = St0
    ).
flow_dbg_event(clause(I, _, C, K), Cells, Cells, F0, F, St0, St, O, O) :- !,
    (   get_assoc(C, Cells, S), get_assoc(S, F0, c(S, Pr, D, P, Cl, In, Out, Fa))
    ->  append(Cl, [c(K, I)], Cl1),
        put_assoc(S, F0, c(S, Pr, D, P, Cl1, In, Out, Fa), F),
        flow_dbg_stream_add(S, sclause(K), St0, St)
    ;   F = F0, St = St0
    ).
flow_dbg_event(nohead(I, _, C, K), Cells, Cells, F0, F, St, St, O, O) :- !,
    (   get_assoc(C, Cells, S), get_assoc(S, F0, c(S, Pr, D, P, Cl, In, Out, Fa))
    ->  append(Cl, [nohead(K, I)], Cl1),
        put_assoc(S, F0, c(S, Pr, D, P, Cl1, In, Out, Fa), F)
    ;   F = F0
    ).
flow_dbg_event(catch(_, _, C), Cells, Cells, F, F, St0, St, O, O) :- !,
    (   get_assoc(C, Cells, S) -> flow_dbg_stream_add(S, scatch, St0, St) ; St = St0 ).
flow_dbg_event(_, Cells, Cells, F, F, St, St, O, O).

%% a stream is kept reversed and turned the right way round when it is read
flow_dbg_stream_add(S, X, St0, St) :-
    (   get_assoc(S, St0, Xs) -> true ; Xs = [] ),
    put_assoc(S, St0, [X|Xs], St).

flow_dbg_stream(S, Streams, Xs) :-
    (   get_assoc(S, Streams, R) -> reverse(R, Xs) ; Xs = [] ).

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
flow_dbg_plan_item(thrown(_), _, _, _, [], wait) :- !.
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

flow_dbg_place(Calls0, Streams, Rows, Panels, Ids, Calls) :-
    empty_assoc(Where0),
    %% the query's own goal: the box query.g1 and the panel it calls
    flow_dbg_query_panel(Panels, Ids, QPanel),
    flow_dbg_place_all(Calls0, Streams, Rows, Panels, Ids, QPanel, Where0, Where),
    findall(call(S, Pr, D, P, Box, Panel, Cl, In, Out, Fa),
            ( member(c(S, Pr, D, P, Cl, In, Out, Fa), Calls0),
              (   get_assoc(S, Where, at(Box, Panel)) -> true ; Box = none, Panel = none ) ),
            Calls).

flow_dbg_query_panel(Panels, Ids, PId) :-
    (   memberchk(panel(0, _, _, _, _, rows([row(_, _, _, _, [g(_, Kind, Ms, _, Key, _)], _)]), _, _), Panels),
        flow_callable_kind(Kind), flow_panel_key(Kind, Key, Ms, PK),
        get_assoc(0-PK, Ids, CId)
    ->  flow_panel_id(CId, PId)
    ;   PId = none
    ).

%% calls in the order they were made, so a call's own place is known
%% before its children are matched in its clauses
flow_dbg_place_all([], _, _, _, _, _, W, W).
flow_dbg_place_all([c(S, Pr, _, P, _, In, _, _)|Cs], Streams, Rows, Panels, Ids, QPanel, W0, W) :-
    (   get_assoc(S, W0, _)
    ->  W1 = W0
    ;   P =:= 0, flow_dbg_is_query(S, Pr, QPanel, Panels)
    ->  put_assoc(S, W0, at('query.g1', QPanel), W1)
    ;   flow_dbg_panel_for(Pr, In, Panels, PId),
        put_assoc(S, W0, at(none, PId), W1)
    ),
    get_assoc(S, W1, at(_, MyPanel)),
    flow_dbg_stream(S, Streams, Xs),
    flow_dbg_walk(Xs, MyPanel, Rows, Panels, Ids, W1, W2),
    flow_dbg_place_all(Cs, Streams, Rows, Panels, Ids, QPanel, W2, W).

%% the window's first call, with no parent in it, is the query's goal when
%% the window began at the first inference -- the goal's own predicate
flow_dbg_is_query(S, Pr, QPanel, Panels) :-
    S =:= 1,
    QPanel \== none,
    memberchk(panel(0, _, _, _, _, rows([row(_, _, _, _, [g(_, _, _, _, Pr, _)], _)]), _, _), Panels).

%% a call with no clause of its caller to be matched in: a panel of its
%% predicate, the one whose call pattern its arguments fit best
flow_dbg_panel_for(Pr, In, Panels, PId) :-
    findall(Score-Id, ( member(panel(Id, Pr, Kind, CM, _, rows(_), _, _), Panels), Id \== 0,
                        Kind \= lane(_, _),
                        flow_dbg_fit(CM, In, Score) ),
            Cands),
    (   Cands == [] -> PId = none
    ;   keysort(Cands, Sorted), last(Sorted, _-Id), flow_panel_id(Id, PId)
    ).

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
%% State: the row being run (PId-K), the boxes a call is expected at next,
%% and the last box a call landed on (for the fallback).

flow_dbg_walk(Xs, PId, Rows, Panels, Ids, W0, W) :-
    flow_dbg_walk_(Xs, PId, none, [], none, Rows, Panels, Ids, W0, W).

flow_dbg_walk_([], _, _, _, _, _, _, _, W, W).
flow_dbg_walk_([X|Xs], PId, Row, Exp, Last, Rows, Panels, Ids, W0, W) :-
    flow_dbg_step(X, PId, Row, Exp, Last, Rows, Panels, Ids, W0, Row1, Exp1, Last1, W1),
    flow_dbg_walk_(Xs, PId, Row1, Exp1, Last1, Rows, Panels, Ids, W1, W).

%% the activation entered a clause: its first goal is next
flow_dbg_step(sclause(K), PId, _, _, _, Rows, _, _, W, Row, Exp, none, W) :- !,
    (   PId \== none, get_assoc(PId-K, Rows, Row) -> Row = row(First, _, _), flow_dbg_target(First, Exp)
    ;   Row = none, Exp = []
    ).
flow_dbg_step(sredo, _, Row, Exp, Last, _, _, _, W, Row, Exp, Last, W) :- !.
flow_dbg_step(scatch, _, Row, _, Last, _, _, _, W, Row, Exp, Last, W) :- !,
    (   Row = row(_, Es, _), flow_dbg_catch_of(Es, Last, RFirst) -> flow_dbg_target(RFirst, Exp)
    ;   Exp = []
    ).
%% a child's Call: the box it is at
flow_dbg_step(ccall(C, Pr), PId, Row, Exp, Last, _, Panels, Ids, W0, Row, Exp1, Last1, W) :- !,
    (   Row = row(_, Es, Plan),
        flow_dbg_choose(Exp, Pr, Last, Es, Plan, Box)
    ->  get_assoc(Box, Plan, E),
        flow_dbg_callee(Box, PId, Panels, Ids, Panel),
        put_assoc(C, W0, at(Box, Panel), W),
        Last1 = Box,
        (   E = e(_, _, _, _, Inner), Inner \== none -> flow_dbg_target(Inner, Exp1) ; Exp1 = [] )
    ;   W = W0, Last1 = Last, Exp1 = []
    ).
flow_dbg_step(cexit(C), _, Row, _, Last, _, _, _, W, Row, Exp, Last, W) :- !,
    flow_dbg_after(C, Row, W, succ, Exp).
flow_dbg_step(cfail(C), _, Row, _, Last, _, _, _, W, Row, Exp, Last, W) :- !,
    flow_dbg_after(C, Row, W, fail, Exp).
flow_dbg_step(credo(C), _, Row, _, _, _, _, _, W, Row, [], Last, W) :- !,
    (   get_assoc(C, W, at(Box, _)), Box \== none -> Last = Box ; Last = none ).
flow_dbg_step(_, _, Row, Exp, Last, _, _, _, W, Row, Exp, Last, W).

%% where a call goes after a child's exit or failure
flow_dbg_after(C, Row, W, Way, Exp) :-
    (   Row = row(_, _, Plan),
        get_assoc(C, W, at(Box, _)), Box \== none,
        get_assoc(Box, Plan, e(_, _, S, F, _))
    ->  ( Way == succ -> flow_dbg_target(S, Exp) ; flow_dbg_target(F, Exp) )
    ;   Exp = []
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

%% the panel a box's goal calls in the chart, as the XML says calls=
flow_dbg_callee(Box, PId, Panels, Ids, Panel) :-
    (   flow_dbg_box_node(Box, PId, Panels, g(_, Kind, Ms, _, Key, _)),
        flow_callable_kind(Kind),
        flow_panel_key(Kind, Key, Ms, PK),
        flow_dbg_lane_of(PId, Ids, L),
        get_assoc(L-PK, Ids, CId)
    ->  flow_panel_id(CId, Panel)
    ;   Panel = none
    ).

flow_dbg_lane_of(query, _, 0) :- !.
flow_dbg_lane_of(PId, Ids, L) :-
    atom_concat(p, NA, PId), atom_number(NA, N),
    flow_panel_lane(Ids, N, L).

%% the node a box id names, found again by walking the ids the plan made
flow_dbg_box_node(Box, PId, Panels, Node) :-
    (   PId == query
    ->  memberchk(panel(0, _, _, _, _, rows([row(_, _, _, _, Nodes, _)]), _, _), Panels),
        Base = query, Rest = Box
    ;   atom_concat(p, NA, PId), atom_number(NA, N),
        memberchk(panel(N, _, _, _, _, rows(Rows), _, _), Panels),
        atom_concat(PId, '.c', Pre),
        atom_concat(Pre, After, Box),
        atomic_list_concat([KA|_], '.', After), atom_number(KA, K),
        memberchk(row(K, _, _, _, Nodes, _), Rows),
        atomic_list_concat([PId, '.c', K], Base),
        Rest = Box
    ),
    flow_dbg_find(Nodes, Base, Rest, Node).

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
