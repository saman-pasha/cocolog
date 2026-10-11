%% library(flow/chart), part: the graph as XML, for an agent to read.
%%
%% THE SAME GRAPH AS THE SVG, AND THE SAME NAMES. A panel is p3, its second
%% clause p3.c2, that clause's fourth goal p3.c2.g4; inside a construct the
%% list a goal stands in comes next -- X.a1.if and X.a1 for an
%% if-then-else's first condition and its then, X.else, X.b2 for a
%% disjunction's second branch, X.try and X.recover for catch/3, X itself
%% for \+ and a meta-call -- and the box drawn for each goal carries the
%% same id. So whatever an agent finds here it can point at in the picture.
%%
%% WHAT A GOAL SAYS: what it is (text, pred, kind, and its file, line and
%% column), the mode of each argument, whether it can fail (can_fail) and
%% whether it can leave a choice point (choice), the panel it calls, and
%% where control goes when it fails (on_fail). Its kind is one of
%%
%%     user        the program's own predicate
%%     dynamic     one whose clauses the program makes and unmakes as it
%%                 runs (declared dynamic): drawn with the clauses the file
%%                 starts it with, if any, and it may fail or answer again
%%     library     a library predicate, with library="..."
%%     c           a C function of a module (a portal), with module="..."
%%     builtin, test, unify    what the engine answers in C
%%     closure     a goal known only when it runs: a variable, or call/N
%%                 with a closure the source does not name
%%     unknown     defined nowhere the chart can see: calling it raises
%%                 existence_error
%%
%% and where control goes when it fails (on_fail) is
%%
%%     an id                the goal that is tried again
%%     next_clause          the next clause of the predicate
%%     fail                 the whole call fails -- with past_cut naming
%%                          the cut when a cut is why
%%     X.a2.if, X.else      a condition failed: the next arm, or the else
%%     X.b2                 a branch failed: the next branch
%%     X:done               the construct X is done with its goal: \+
%%                          succeeds, findall has every solution
%%     X:wait               cond_wait_until/3 waits for a signal, and
%%                          tries its goal again
%%     X:next               httpd_serve/2,3, serving on the caller's own
%%                          thread, answers the request 404 and waits for
%%                          the next one
%%
%% and a clause says where backtracking into it goes once it has exited
%% (redo), by the same words. A goal past a call that never succeeds says
%% reached="false": it is drawn, and nothing it calls has a panel.
%%
%% THE FINDINGS COME FIRST, before the panels, so an agent reading the head
%% of the file meets them: <findings count errors warnings>, then one
%% <finding n kind severity at in file line col text> each, with a <see
%% ref=...> for each other place it involves -- ref, not id: an id names one
%% element of the document, and at= and ref= point at it (library/flow/
%% findings.pl has the eight kinds). n is the number on its disc in the
%% picture.
%%
%% THEN WHERE THE CODE RUNS (F2, lanes.pl): <lanes>, one <lane> for the
%% query's thread, l0, and one for each place a spawn sends a goal -- its
%% kind (thread, pool, isolated, crew, httpd), its root panel, the spawn's
%% site and the lane it stands in, the goal, what is copied and what comes
%% back -- and <links>, what crosses between them, each an element with an
%% id: <spawn>, <join> (a join carries the lane's status, a detach
%% nothing), <channel> with its <send>, <receive> and <close> ends -- via=
%% the channels it was sent down, n= where a send or a receive comes in its
%% lane's order, and pairs="true" where one lane sends and one receives, so
%% the k-th send is the k-th receive's -- <lock>, <process> (a child
%% process: its command, and the file whose chart is its own when it runs
%% cocolog on one) and <write> (to the knowledge base). Every panel says
%% its lane; a lane's root holds its goals, or a <job n> for each of
%% cowork_map/3's (rest="true" for a list the source does not write). A
%% goal of library(thread) says kind="thread" and its role -- send, recv,
%% close, new, lock, unlock, trylock, wait, signal, broadcast, join, detach
%% -- with the channel, the mutex or the lane it is about; a spawn says
%% kind="spawn", its type and its lane; a child process kind="process". An
%% httpd server with no pool is a <meta name="httpd_serve"> whose goal is
%% the page, called here.
%%
%% The schema is version 4 (version 1 had no findings, version 2 no lanes,
%% version 3 no jobs, no message order and no channel carried by another):
%% changing it changes the number.

:- use_module(library(xml)).

flow_xml_version(4).

flow_xml(Graph, Xml) :-
    flow_findings(Graph, Fs),
    flow_xml(Graph, Fs, Xml).

flow_xml(Graph, Fs, element(flow, As, [FE, LE, KE|Cs])) :-
    Graph = graph(Title, Src, Panels, Ids, Docs),
    flow_xml_version(V),
    memberchk(panel(0, _, _, CM, _, rows([row(_, _, _, _, [g(_, _, _, _, N/A, _)], _)]), _, _), Panels),
    functor(SG, N, A),
    SG =.. [_|Ms0],
    flow_x_modes_args(Ms0, CM),
    format(atom(Spec), '~q', [SG]),
    As = [version=V, tool='library(flow/chart)', title=Title, spec=Spec, source=Src],
    flow_x_findings(Fs, FE),
    flow_x_lanes(Ids, Panels, LE),
    flow_x_links(Ids, KE),
    findall(E, ( member(P, Panels), flow_x_panel(P, Ids, Docs, E) ), Cs).

%% ---- where the code runs, and what crosses between ---------------------

flow_x_lanes(Ids, Panels, element(lanes, [count=N], [L0|Ls])) :-
    flow_graph_lanes(Ids, Lanes),
    length(Lanes, N0),
    N is N0 + 1,
    L0 = element(lane, [id=l0, kind=query, root=query], []),
    findall(E, ( member(Ln, Lanes), flow_x_lane(Ln, Ids, Panels, E) ), Ls).

flow_x_lane(lane(L, Type, R, SiteId, From, Back, Goal, Names), Ids, Panels, element(lane, As, [])) :-
    flow_lane_atom(L, LA),
    flow_lane_atom(From, FA),
    flow_panel_id(R, RP),
    flow_term_full(Goal, Names, 999, GT),
    flow_graph_links(Ids, links(Spawns, _, _, _, _, _)),
    (   memberchk(spawn(SiteId, _, _, _, _, CT0), Spawns) -> CT = CT0 ; CT = nothing ),
    flow_x_returns(Type, Back, RT),
    (   memberchk(panel(R, _, _, _, _, rows([row(_, _, _, _, _, CI)|_]), _, _), Panels)
    ->  flow_x_where(CI, WAs)
    ;   WAs = []
    ),
    append([[id=LA, kind=Type, root=RP, site=SiteId, from=FA, goal=GT, copies=CT, returns=RT], WAs], As).

flow_lane_atom(L, A) :- format(atom(A), 'l~w', [L]).

%% what comes back from a lane to the goal that sent it
flow_x_returns(_, none, nothing) :- !.
flow_x_returns(isolated, waits, status) :- !.
flow_x_returns(_, waits, copy) :- !.
flow_x_returns(_, back, unified).

flow_x_links(Ids, element(links, [], Els)) :-
    flow_graph_links(Ids, links(Spawns, Joins, Chans, Locks, Procs, Writes)),
    flow_graph_lanes(Ids, Lanes),
    flow_x_numbered(Spawns, s, Lanes, SEs),
    flow_x_numbered(Joins, j, Lanes, JEs),
    findall(E, ( member(C, Chans), flow_x_channel(C, E) ), CEs),
    flow_x_numbered(Locks, k, Lanes, KEs),
    flow_x_numbered(Procs, x, Lanes, PEs),
    flow_x_numbered(Writes, w, Lanes, WEs),
    append([SEs, JEs, CEs, KEs, PEs, WEs], Els).

flow_x_numbered(Ls, P, Lanes, Es) :-
    findall(E, ( nth1(I, Ls, Lk), atomic_list_concat([P, I], Id), flow_x_link(Lk, Id, Lanes, E) ), Es).

flow_x_link(spawn(At, L, R, Type, Back, CT), Id, _, element(spawn, As, [])) :-
    flow_lane_atom(L, LA),
    flow_panel_id(R, RP),
    flow_x_returns(Type, Back, RT),
    As = [id=Id, at=At, lane=LA, root=RP, type=Type, copies=CT, returns=RT].
flow_x_link(join(At, L, How), Id, _, element(join, [id=Id, at=At, lane=LA, how=How, carries=C], [])) :-
    flow_lane_atom(L, LA),
    (   How == detach -> C = nothing ; C = status ).
flow_x_link(lock(At, Op, Name), Id, _, element(lock, [id=Id, at=At, op=Op, name=Name], [])).
flow_x_link(process(At, Cmd, Chart), Id, _, element(process, As, [])) :-
    (   Cmd == none -> CAs = [] ; CAs = [command=Cmd] ),
    (   Chart == none -> HAs = [] ; HAs = [chart=Chart] ),
    append([[id=Id, at=At], CAs, HAs], As).
flow_x_link(write(At, Op, Pred), Id, _, element(write, As, [])) :-
    (   Pred = N/A -> format(atom(PA), '~q/~w', [N, A]), PAs = [pred=PA] ; PAs = [] ),
    append([[id=Id, at=At, op=Op], PAs], As).

flow_x_channel(channel(K, Made, Ops, Via, Pairs), element(channel, As, Els)) :-
    flow_chan_label(K, KA),
    (   integer(K)
    ->  findall(VA, ( member(V, Via), flow_chan_label(V, VA) ), VAs),
        (   VAs == [] -> ViaAs = [] ; atomic_list_concat(VAs, ' ', VT), ViaAs = [via=VT] ),
        (   Pairs == true -> PAs = [pairs=true] ; PAs = [] ),
        append([[id=KA, made=Made], ViaAs, PAs], As)
    ;   As = [id=KA, followed=false]
    ),
    findall(element(E, EAs, []),
            ( member(op(At, Op, N), Ops), Op \== new, flow_x_end(Op, E),
              (   N = [_|_] -> atomic_list_concat(N, ' ', NT), EAs = [at=At, n=NT] ; EAs = [at=At] ) ),
            Els).

flow_x_end(send, send).
flow_x_end(recv, receive).
flow_x_end(close, close).

%% ---- the findings, first, so an agent meets them before the panels ------

flow_x_findings(Fs, element(findings, [count=N, errors=NE, warnings=NW], Els)) :-
    length(Fs, N),
    findall(x, member(finding(_, _, error, _, _, _, _, _), Fs), Es), length(Es, NE),
    NW is N - NE,
    findall(E, ( member(F, Fs), flow_x_finding(F, E) ), Els).

flow_x_finding(finding(N, Kind, Sev, At, In, Where, Text, See), element(finding, As, Els)) :-
    (   Where = where(F, L, C) -> WAs = [file=F, line=L, col=C] ; WAs = [] ),
    append([[n=N, kind=Kind, severity=Sev, at=At, in=In], WAs, [text=Text]], As),
    findall(element(see, [ref=Id], []), member(Id, See), Els).

flow_x_modes_args([], []).
flow_x_modes_args([M|Ms], [M|CMs]) :- flow_x_modes_args(Ms, CMs).

%% ---- a panel ------------------------------------------------------------

flow_x_panel(panel(0, _, _, CM, D, rows([row(_, _, Names, _, [GN], _)]), Det, _), Ids, _,
             element(panel, [id=query, kind=query, lane=l0, modes=MA, det=Det, depth=D], [GE])) :- !,
    flow_x_modes(CM, MA),
    flow_x_items([GN], query, x(Names, Ids, 0-none), fail, true, [GE]).
%% a lane's root: what the spawned goal proves, where it was spawned --
%% its goals, or a <job> for each of cowork_map/3's
flow_x_panel(panel(Id, _, lane(Type, L), _, D, rows(Rows), Det, _), Ids, _,
             element(panel, As, Items)) :- !,
    Rows = [row(C1, _, _, _, _, CI)|_],
    flow_panel_id(Id, PId),
    flow_lane_atom(L, LA),
    flow_graph_lanes(Ids, Lanes),
    (   memberchk(lane(L, _, _, SiteId, _, _, _, _), Lanes) -> true ; SiteId = none ),
    flow_x_where(CI, WAs),
    append([[id=PId, kind=lane, lane=LA, type=Type, site=SiteId], WAs, [det=Det, depth=D]], As),
    Self = L-root(Id),
    (   C1 =:= 0
    ->  Rows = [row(_, _, Names, _, Nodes, _)],
        atom_concat(PId, '.c0', Base),
        flow_x_items(Nodes, Base, x(Names, Ids, Self), fail, true, Items)
    ;   findall(E, ( member(Row, Rows), flow_x_job(Row, PId, Ids, Self, E) ), Items)
    ).

%% one of cowork_map/3's jobs, proved on its own: a failure in it is its
%% answer, failed, and never the next job; rest="true" for the jobs of a
%% list the source does not write
flow_x_job(row(K, _, Names, _, Nodes, CI), PId, Ids, Self, element(job, As, Items)) :-
    atomic_list_concat([PId, '.c', K], Base),
    (   memberchk(rest, CI) -> RAs = [rest=true] ; RAs = [] ),
    append([[id=Base, n=K], RAs], As),
    flow_x_items(Nodes, Base, x(Names, Ids, Self), fail, true, Items).
flow_x_panel(panel(Id, N/A, portal(Mod), _, D, portal(info(CFun, File, Line, Modes, Names)), Det, _), Ids, _,
             element(panel, [id=PId, pred=Pred, kind=c, lane=LA, module=Mod, cfun=CFun, file=File, line=Line,
                             modes=MA, det=Det, head=Head, depth=D], [])) :- !,
    flow_panel_id(Id, PId),
    flow_panel_lane(Ids, Id, L),
    flow_lane_atom(L, LA),
    flow_x_pred(N, A, Pred),
    flow_x_modes(Modes, MA),
    functor(G, N, A),
    G =.. [_|Vs],
    (   flow_pair_names(Names, Vs, NVs) -> true ; flow_gen_names(G, NVs) ),
    flow_moded_head(G, Modes, NVs, Segs),
    flow_segs_atom(Segs, Head).
flow_x_panel(panel(Id, Key, Kind, CM, D, rows(Rows), Det, _), Ids, Docs,
             element(panel, PAs, RCs)) :-
    Key = N/A,
    flow_panel_id(Id, PId),
    flow_x_pred(N, A, Pred),
    flow_x_modes(CM, MA),
    flow_panel_head(Key, CM, Rows, Docs, HSegs),
    flow_segs_atom(HSegs, Head),
    length(Rows, NC),
    flow_x_kind(Kind, KA, KAs),
    flow_panel_lane(Ids, Id, L),
    flow_lane_atom(L, LA),
    append([[id=PId, pred=Pred, kind=KA], KAs,
            [lane=LA, modes=MA, det=Det, head=Head, depth=D, clauses=NC]], PAs),
    flow_doc_rows(Key, Kind, Docs, Rows, DRows),
    flow_panel_key(Kind, Key, CM, PK),
    Self = L-PK,
    findall(E, ( member(R, DRows), flow_x_clause(R, PId, NC, CM, Ids, Self, E) ), RCs).

flow_x_kind(user, user, []) :- !.
flow_x_kind(library(L), library, [library=LN]) :- !, flow_lib_name(L, LN).
flow_x_kind(K, K, []).

flow_x_pred(N, A, Pred) :- format(atom(Pred), '~q/~w', [N, A]).

flow_x_modes(Ms, A) :- atomic_list_concat(Ms, ' ', A).

%% ---- a clause -----------------------------------------------------------

flow_x_clause(row(I, H, Names, HF, Nodes, CI), PId, NC, CM, Ids, Self, element(clause, As, Cs)) :-
    atomic_list_concat([PId, '.c', I], Base),
    (   I < NC -> Default = next_clause ; Default = fail ),
    flow_term_full(H, Names, 1200, HT),
    flow_x_where(CI, WAs),
    (   memberchk(dcg, CI) -> DAs = [dcg=true] ; DAs = [] ),
    X = x(Names, Ids, Self),
    flow_x_items(Nodes, Base, X, Default, true, Items),
    flow_x_index(Nodes, Base, 1, Indexed),
    reverse(Indexed, Rev),
    flow_x_target(Rev, Default, true, Redo),
    flow_x_target_attrs(redo, Redo, RAs),
    flow_x_head_modes(H, CM, Names, HArgs),
    append([[id=Base, n=I], WAs, DAs, [head=HT, head_can_fail=HF], RAs], As),
    (   memberchk(text(Codes), CI) -> atom_codes(TA, Codes), TCs = [element(text, [], [TA])] ; TCs = [] ),
    append([HArgs, TCs, Items], Cs).

flow_x_where(CI, As) :-
    (   memberchk(file(F), CI) -> A1 = [file=F] ; A1 = [] ),
    (   memberchk(at(L, K), CI) -> A2 = [line=L, col=K] ; A2 = [] ),
    append(A1, A2, As).

flow_x_head_modes(H, CM, Names, Els) :-
    (   H == none -> Els = []
    ;   H =.. [_|Args],
        flow_x_args(Args, CM, Names, 1, Els)
    ).

flow_x_args([], _, _, _, []).
flow_x_args([A|As], [M|Ms], Names, I, [element(arg, [n=I, mode=M, text=T], [])|Es]) :-
    flow_term_full(A, Names, 999, T),
    I1 is I + 1,
    flow_x_args(As, Ms, Names, I1, Es).

%% ---- the items of a list, and where each one's failure goes ------------
%%
%% Default is where a failure goes when nothing to its left can redo;
%% Transp says whether a cut to its left cuts the clause (a clause's own
%% list, a branch of if-then-else or of a disjunction) or only the
%% construct it stands in (\+, a meta-call, catch/3).

flow_x_items(Nodes, Base, X, Default, Transp, Els) :-
    flow_x_index(Nodes, Base, 1, Indexed),
    flow_x_items_(Indexed, [], X, Default, Transp, Els).

flow_x_index([], _, _, []).
flow_x_index([N|Ns], Base, K, [Id-N|R]) :-
    atomic_list_concat([Base, '.g', K], Id),
    K1 is K + 1,
    flow_x_index(Ns, Base, K1, R).

flow_x_items_([], _, _, _, _, []).
flow_x_items_([Id-N|Rest], Left, X, Default, Transp, [E|Es]) :-
    flow_x_target(Left, Default, Transp, T),
    flow_x_item(N, Id, X, T, Transp, E),
    flow_x_items_(Rest, [Id-N|Left], X, Default, Transp, Es).

%% the nearest item to the left that can redo; a cut first means the
%% call fails (or, in an opaque list, the list's own way out)
flow_x_target([], Default, _, Default).
flow_x_target([Id-N|Left], Default, Transp, T) :-
    (   N == cut
    ->  (   Transp == true -> T = cut(Id) ; T = Default )
    ;   flow_node_nondet(N)
    ->  T = Id
    ;   flow_x_target(Left, Default, Transp, T)
    ).

flow_x_target_attrs(Name, cut(C), [Name=fail, past_cut=C]) :- !.
flow_x_target_attrs(Name, T, [Name=T]).

flow_x_flags(N, CF, ND) :-
    (   flow_node_total(N) -> CF = false ; CF = true ),
    (   flow_node_nondet(N) -> ND = true ; ND = false ).

%% ---- one item -----------------------------------------------------------

flow_x_item(g(G, Kind, Ms, Det, Key, Info), Id, x(Names, Ids, Self), T, _, element(goal, As, Args)) :- !,
    flow_term_full(G, Names, 1200, Text),
    functor(G, N, A),
    flow_x_pred(N, A, Pred),
    flow_x_goal_kind(Kind, KA, KAs),
    flow_x_modes(Ms, MA),
    flow_x_flags(g(G, Kind, Ms, Det, Key, Info), CF, ND),
    Self = L-_,
    (   flow_callable_kind(Kind), flow_panel_key(Kind, Key, Ms, PK),
        (   L-PK == Self -> CallsAs = [calls=self]
        ;   get_assoc(L-PK, Ids, CId) -> flow_panel_id(CId, CP), CallsAs = [calls=CP]
        )
    ->  true
    ;   Kind = spawn(_), flow_site_root(Ids, Id, R)
    ->  flow_panel_id(R, RP), CallsAs = [calls=RP]
    ;   CallsAs = []
    ),
    flow_x_link_attrs(Kind, G, Id, Names, Ids, LkAs),
    flow_x_target_attrs(on_fail, T, FAs),
    flow_x_info(Info, IAs),
    append([[id=Id, kind=KA], KAs, LkAs, [pred=Pred, text=Text, modes=MA, det=Det, can_fail=CF, choice=ND],
            CallsAs, FAs, IAs], As),
    G =.. [_|GArgs],
    flow_x_args(GArgs, Ms, Names, 1, Args).
flow_x_item(cut, Id, _, _, _, element(cut, [id=Id], [])) :- !.
flow_x_item(failn, Id, _, T, _, element(fail, [id=Id|FAs], [])) :- !,
    flow_x_target_attrs(on_fail, T, FAs).
flow_x_item(thrown(E), Id, x(Names, _, _), _, _, element(throw, [id=Id, ball=BT], [])) :- !,
    flow_term_full(E, Names, 999, BT).
flow_x_item(ite(Soft, Arms, Else), Id, X, T, Transp, element(if, As, Cs)) :- !,
    flow_x_flags(ite(Soft, Arms, Else), CF, ND),
    flow_x_target_attrs(on_fail, T, FAs),
    (   Soft == soft -> SA = true ; SA = false ),
    flow_x_at(ite(Soft, Arms, Else), PAs),
    append([[id=Id, soft=SA, can_fail=CF, choice=ND], FAs, PAs], As),
    length(Arms, NA),
    flow_x_arms(Arms, 1, NA, Else, Id, X, T, Transp, ACs),
    (   Else == none -> ECs = []
    ;   atom_concat(Id, '.else', EId),
        flow_x_items(Else, EId, X, T, Transp, EIs),
        ECs = [element(else, [id=EId], EIs)]
    ),
    append(ACs, ECs, Cs).
flow_x_item(or(Bs), Id, X, T, Transp, element(or, As, Cs)) :- !,
    flow_x_flags(or(Bs), CF, ND),
    flow_x_target_attrs(on_fail, T, FAs),
    flow_x_at(or(Bs), PAs),
    append([[id=Id, can_fail=CF, choice=ND], FAs, PAs], As),
    length(Bs, NB),
    flow_x_branches(Bs, 1, NB, Id, X, T, Transp, Cs).
flow_x_item(not(Ns), Id, X, T, _, element(not, As, Is)) :- !,
    flow_x_flags(not(Ns), CF, ND),
    flow_x_target_attrs(on_fail, T, FAs),
    flow_x_at(not(Ns), PAs),
    append([[id=Id, can_fail=CF, choice=ND], FAs, PAs], As),
    atom_concat(Id, ':done', Done),
    flow_x_items(Ns, Id, X, Done, false, Is).
flow_x_item(meta(Name, Head, Ms, Ts, Info), Id, X, T, _, element(meta, As, Is)) :- !,
    X = x(Names, Ids, Self),
    flow_term_full(Head, Names, 1200, HT),
    flow_x_modes(Ms, MA),
    flow_x_flags(meta(Name, Head, Ms, Ts, Info), CF, ND),
    flow_x_target_attrs(on_fail, T, FAs),
    flow_x_info(Info, IAs),
    flow_x_meta_links(Info, Id, Names, Ids, MLs),
    append([[id=Id, name=Name, text=HT, modes=MA, can_fail=CF, choice=ND], MLs, FAs, IAs], As),
    (   memberchk(Name, [once, phrase, with_mutex, channel_forall]) -> D = T
    ;   Name == cond_wait_until -> atom_concat(Id, ':wait', D)
    ;   Name == httpd_serve -> atom_concat(Id, ':next', D)
    ;   atom_concat(Id, ':done', D)
    ),
    (   Ts = [Ns] -> true ; Ns = [] ),
    (   memberchk(names(NL), Info) -> append(NL, Names, Names1) ; Names1 = Names ),
    flow_x_items(Ns, Id, x(Names1, Ids, Self), D, false, Is).
flow_x_item(catchc(G, Ball, R), Id, X, T, _, element(catch, As, [element(try, [id=TId], GIs),
                                                                  element(recover, [id=RId], RIs)])) :- !,
    X = x(Names, _, _),
    flow_term_full(Ball, Names, 999, BT),
    flow_x_flags(catchc(G, Ball, R), CF, ND),
    flow_x_target_attrs(on_fail, T, FAs),
    flow_x_at(catchc(G, Ball, R), PAs),
    append([[id=Id, ball=BT, can_fail=CF, choice=ND], FAs, PAs], As),
    atom_concat(Id, '.try', TId),
    atom_concat(Id, '.recover', RId),
    flow_x_items(G, TId, X, T, false, GIs),
    flow_x_items(R, RId, X, T, false, RIs).
flow_x_item(_, Id, _, _, _, element(item, [id=Id], [])).

%% a condition that fails goes to the next arm's condition, or to the else,
%% or out; the then goes on as the list around the if-then-else does
flow_x_arms([], _, _, _, _, _, _, _, []).
flow_x_arms([arm(C, Th)|As], K, NA, Else, Id, X, T, Transp,
            [element(arm, [n=K], [element(cond, [id=CId], CIs), element(then, [id=AId], TIs)])|Es]) :-
    atomic_list_concat([Id, '.a', K], AId),
    atom_concat(AId, '.if', CId),
    (   K < NA -> K1 is K + 1, atomic_list_concat([Id, '.a', K1, '.if'], CD)
    ;   Else \== none -> atom_concat(Id, '.else', CD)
    ;   CD = T
    ),
    flow_x_items(C, CId, X, CD, false, CIs),
    flow_x_items(Th, AId, X, T, Transp, TIs),
    K2 is K + 1,
    flow_x_arms(As, K2, NA, Else, Id, X, T, Transp, Es).

flow_x_branches([], _, _, _, _, _, _, []).
flow_x_branches([B|Bs], K, NB, Id, X, T, Transp, [element(branch, [n=K, id=BId], Is)|Es]) :-
    atomic_list_concat([Id, '.b', K], BId),
    (   K < NB -> K1 is K + 1, atomic_list_concat([Id, '.b', K1], D) ; D = T ),
    flow_x_items(B, BId, X, D, Transp, Is),
    K2 is K + 1,
    flow_x_branches(Bs, K2, NB, Id, X, T, Transp, Es).

flow_x_goal_kind(portal(M), c, [module=M]) :- !.
flow_x_goal_kind(library(L), library, [library=LN]) :- !, flow_lib_name(L, LN).
flow_x_goal_kind(spawn(Type), spawn, [type=Type]) :- !.
flow_x_goal_kind(conc(Role), thread, [role=R]) :- !, flow_x_role(Role, R).
flow_x_goal_kind(process(_), process, []) :- !.
flow_x_goal_kind(K, K, []).

flow_x_role(chan(Op, _), Op).
flow_x_role(lock(Op, _), Op).
flow_x_role(cond(Op, _, _), Op).
flow_x_role(join(_), join).
flow_x_role(detach(_), detach).

%% what the links say of a goal: the lane a spawn or a join is about, the
%% channel a send or a receive is, the mutex a lock takes, the command a
%% process runs, and that a write to the knowledge base is one
flow_x_link_attrs(spawn(_), _, Id, _, Ids, As) :- !,
    (   flow_site_root(Ids, Id, R), flow_panel_lane(Ids, R, L)
    ->  flow_lane_atom(L, LA), As = [lane=LA]
    ;   As = []
    ).
flow_x_link_attrs(conc(chan(_, Ch)), _, Id, Names, Ids, [channel=KA]) :- !,
    flow_site_channel(Ids, Id, Ch, Names, K),
    flow_chan_label(K, KA).
flow_x_link_attrs(conc(lock(_, M)), _, _, Names, _, [mutex=MA]) :- !,
    flow_handle_name(M, Names, MA).
flow_x_link_attrs(conc(cond(_, C, M)), _, _, Names, _, As) :- !,
    flow_handle_name(C, Names, CA),
    (   M == none -> As = [condition=CA]
    ;   flow_handle_name(M, Names, MA), As = [condition=CA, mutex=MA]
    ).
flow_x_link_attrs(conc(J), _, Id, _, Ids, As) :-
    ( J = join(_) ; J = detach(_) ), !,
    flow_graph_links(Ids, links(_, Joins, _, _, _, _)),
    (   memberchk(join(Id, L, _), Joins) -> flow_lane_atom(L, LA), As = [joins=LA] ; As = [] ).
flow_x_link_attrs(process(Cmd), _, _, _, _, As) :- !,
    (   flow_proc_command(Cmd, T)
    ->  (   flow_proc_chart(T, F) -> As = [command=T, chart=F] ; As = [command=T] )
    ;   As = []
    ).
flow_x_link_attrs(builtin, G, _, _, _, As) :- !,
    flow_x_kb(G, As).
flow_x_link_attrs(library(builtins), G, _, _, _, As) :- !,
    flow_x_kb(G, As).
flow_x_link_attrs(_, _, _, _, _, []).

flow_x_kb(G, As) :-
    (   flow_kb_write(G, _, _) -> As = [kb=write] ; As = [] ).

flow_x_meta_links(Info, Id, Names, Ids, As) :-
    (   memberchk(lock(_, M), Info) -> flow_handle_name(M, Names, MA), A1 = [mutex=MA] ; A1 = [] ),
    (   memberchk(cond(_, C, _), Info) -> flow_handle_name(C, Names, CA), A2 = [condition=CA] ; A2 = [] ),
    (   memberchk(chan(_, Ch), Info)
    ->  flow_site_channel(Ids, Id, Ch, Names, K), flow_chan_label(K, KA), A3 = [channel=KA]
    ;   A3 = []
    ),
    append([A1, A2, A3], As).

flow_x_info(Info, As) :-
    (   memberchk(at(L, K), Info) -> A1 = [line=L, col=K] ; A1 = [] ),
    (   memberchk(dcg(F), Info) -> flow_x_dcg(F, FA), A2 = [dcg=FA] ; A2 = [] ),
    (   memberchk(unreached, Info) -> A3 = [reached=false] ; A3 = [] ),
    append([A1, A2, A3], As).

flow_x_dcg(nonterminal(N//A), F) :- !, format(atom(F), 'nonterminal ~q//~w', [N, A]).
flow_x_dcg(F, F).

%% a construct stands where its first goal does
flow_x_at(N, [line=L, col=K]) :- flow_x_node_at(N, L, K), !.
flow_x_at(_, []).

flow_x_node_at(g(_, _, _, _, _, I), L, K) :- !, memberchk(at(L, K), I).
flow_x_node_at(meta(_, _, _, Ts, I), L, K) :- !,
    (   memberchk(at(L, K), I) -> true
    ;   member(T, Ts), member(N, T), flow_x_node_at(N, L, K) -> true
    ).
flow_x_node_at(ite(_, Arms, Else), L, K) :- !,
    (   member(arm(C, T), Arms), ( member(N, C) ; member(N, T) ), flow_x_node_at(N, L, K) -> true
    ;   Else \== none, member(N, Else), flow_x_node_at(N, L, K) -> true
    ).
flow_x_node_at(or(Bs), L, K) :- !,
    member(B, Bs), member(N, B), flow_x_node_at(N, L, K), !.
flow_x_node_at(not(Ns), L, K) :- !,
    member(N, Ns), flow_x_node_at(N, L, K), !.
flow_x_node_at(catchc(G, _, R), L, K) :-
    ( member(N, G) ; member(N, R) ), flow_x_node_at(N, L, K), !.
