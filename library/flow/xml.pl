%% library(flowchart), part: the graph as XML, for an agent to read.
%%
%% THE SAME GRAPH AS THE SVG, AND THE SAME NAMES. A panel is p3, its second
%% clause p3.c2, that clause's fourth goal p3.c2.g4; inside a construct the
%% list a goal stands in comes next -- X.a1.if and X.a1 for an
%% if-then-else's first condition and its then, X.else, X.b2 for a
%% disjunction's second branch, X.try and X.recover for catch/3, X itself
%% for \+ and a meta-call -- and the box drawn for each goal carries the
%% same id; a goal folded into a box of builtin work (builtins(fold), the
%% picture's default) is an empty element of that id inside the box. So
%% whatever an agent finds here it can point at in the picture.
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
%% findings.pl has the five kinds). n is the number on its disc in the
%% picture.
%%
%% The schema is version 2 (version 1 had no findings): changing it changes
%% the number.

:- use_module(library(xml)).

flow_xml_version(2).

flow_xml(Graph, Xml) :-
    flow_findings(Graph, Fs),
    flow_xml(Graph, Fs, Xml).

flow_xml(Graph, Fs, element(flow, As, [FE|Cs])) :-
    Graph = graph(Title, Src, Panels, Ids, Docs),
    flow_xml_version(V),
    memberchk(panel(0, _, _, CM, _, rows([row(_, _, _, _, [g(_, _, _, _, N/A, _)], _)]), _, _), Panels),
    functor(SG, N, A),
    SG =.. [_|Ms0],
    flow_x_modes_args(Ms0, CM),
    format(atom(Spec), '~q', [SG]),
    As = [version=V, tool='library(flowchart)', title=Title, spec=Spec, source=Src],
    flow_x_findings(Fs, FE),
    findall(E, ( member(P, Panels), flow_x_panel(P, Ids, Docs, E) ), Cs).

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
             element(panel, [id=query, kind=query, modes=MA, det=Det, depth=D], [GE])) :- !,
    flow_x_modes(CM, MA),
    flow_x_items([GN], query, x(Names, Ids, none), fail, true, [GE]).
flow_x_panel(panel(Id, N/A, portal(Mod), _, D, portal(info(CFun, File, Line, Modes, Names)), Det, _), _, _,
             element(panel, [id=PId, pred=Pred, kind=c, module=Mod, cfun=CFun, file=File, line=Line,
                             modes=MA, det=Det, head=Head, depth=D], [])) :- !,
    flow_panel_id(Id, PId),
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
    append([[id=PId, pred=Pred, kind=KA], KAs,
            [modes=MA, det=Det, head=Head, depth=D, clauses=NC]], PAs),
    flow_doc_rows(Key, Kind, Docs, Rows, DRows),
    flow_panel_key(Kind, Key, CM, Self),
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
    (   flow_callable_kind(Kind), flow_panel_key(Kind, Key, Ms, PK),
        (   PK == Self -> CallsAs = [calls=self]
        ;   get_assoc(PK, Ids, CId) -> flow_panel_id(CId, CP), CallsAs = [calls=CP]
        )
    ->  true
    ;   CallsAs = []
    ),
    flow_x_target_attrs(on_fail, T, FAs),
    flow_x_info(Info, IAs),
    append([[id=Id, kind=KA], KAs, [pred=Pred, text=Text, modes=MA, det=Det, can_fail=CF, choice=ND],
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
    X = x(Names, _, _),
    flow_term_full(Head, Names, 1200, HT),
    flow_x_modes(Ms, MA),
    flow_x_flags(meta(Name, Head, Ms, Ts, Info), CF, ND),
    flow_x_target_attrs(on_fail, T, FAs),
    flow_x_info(Info, IAs),
    append([[id=Id, name=Name, text=HT, modes=MA, can_fail=CF, choice=ND], FAs, IAs], As),
    (   memberchk(Name, [once, phrase]) -> D = T ; atom_concat(Id, ':done', D) ),
    (   Ts = [Ns] -> true ; Ns = [] ),
    flow_x_items(Ns, Id, X, D, false, Is).
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
flow_x_goal_kind(K, K, []).

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
