%% library(flowchart), part: the analysis -- what each goal is, which
%% variables are bound when it runs, how it can end, and the panels.

%% ======================================================================
%% What a goal is
%% ======================================================================
%%
%% Dispatch is construct, C builtin, module, store -- so is this, in that
%% order: a name the engine answers in C is a builtin whatever a file
%% defines under it.
%%
%% A DYNAMIC predicate is one whose clauses the program makes and unmakes
%% as it runs: one the file declares dynamic, drawn with whatever clauses
%% the file gives it, and one the store knows that has no clause at all --
%% declared dynamic by a file the program loads, or asserted and retracted
%% (current_predicate/1 answers about the store). A call to it fails when
%% it has no clauses; a call to an UNKNOWN predicate is an existence error.

flow_kind(G, Ctx, Kind) :-
    functor(G, N, A),
    Ctx = ctx(Prog, _, _),
    (   flow_test(N, A)                 -> Kind = test
    ;   N == (=), A =:= 2               -> Kind = unify
    ;   flow_t_c(N, A, _)               -> Kind = builtin
    ;   flow_portal_row(Mod, N, A, _)    -> Kind = portal(Mod)
    ;   get_assoc(N/A, Prog, V)         -> ( V = dyn(_) -> Kind = dynamic ; Kind = user )
    ;   flow_t_lib(N, A, L, _)          -> Kind = library(L)
    ;   flow_has_clauses(N, A)          -> Kind = library(loaded)
    ;   catch(current_predicate(N/A), _, fail) -> Kind = dynamic
    ;   Kind = unknown
    ).

%% the clauses the file holds, of a predicate of its own or a dynamic one
flow_prog_clauses(dyn(Cls), Cls) :- !.
flow_prog_clauses(Cls, Cls).

flow_has_clauses(N, A) :-
    functor(H, N, A),
    catch(clause(H, _), _, fail), !.

flow_callable_kind(user).
flow_callable_kind(dynamic).
flow_callable_kind(library(_)).
flow_callable_kind(portal(_)).

%% ======================================================================
%% A C function, from the generated tables
%% ======================================================================
%%
%% Each module dispatches through rows like
%%     ("re_first"   3 coco_x_first)     ; re_first(+Pat, +Text, -MatchCodes)
%% so the row says which C function answers the name and arity, and its
%% comment says the modes. tools/flow/tables.pl read them all at build time.

flow_portal(Mod, N, A, _, Info) :-
    flow_portal_row(Mod, N, A, Info).

%% A dispatcher written by hand (torch, bigint) answers a name at any
%% arity, and the table says so with arity -1: every argument is `?'.
flow_portal_row(Mod, N, A, info(CFun, Rel, Line, Modes, Names)) :-
    (   flow_t_portal(Mod, N, A, CFun, Rel, Line, Modes, Names) -> true
    ;   flow_t_portal(Mod, N, -1, CFun, Rel, Line, _, _)
    ->  length(Modes, A), flow_fill(Modes, '?'), flow_gen_arg_names(A, Names)
    ).

%% ======================================================================
%% The analysis, to a fixed point
%% ======================================================================
%%
%% A PAIR is a predicate and a call pattern: grep_count/3 called (+, +, -).
%% A pair's clauses are analysed against what the pairs THEY call are known
%% to do -- which arguments a call binds (its success pattern) and how it
%% can end (det, semidet, nondet) -- starting from knowing nothing: a call
%% not yet known to succeed binds nothing, and a clause past it does not
%% count towards the answer. A pair is analysed again whenever the answer
%% of a pair it calls changes, until none changes, so recursion is exactly
%% as precise as its base cases allow.
%%
%% A WORKLIST, not rounds: a pair is analysed again only when an answer it
%% read has changed. A pair met for the first time goes to the front, so
%% callees settle before their callers come round again; a pair to be
%% analysed again goes to the back. Rounds that analysed every pair each
%% time took 26 of them, 2.1 G inferences and 6.6 GB on the translator. A
%% call past one not known to succeed makes no pair: nothing there runs
%% yet, and what it would be called with is not known either.
%%
%% A pair whose answer has changed flow_cap/1 times is widened to the
%% answer that says least -- it may bind any argument partly, and leave a
%% choice -- so the analysis ends whatever the program.
%%
%% Ctx is ctx(Prog, Memo, How): the program's clauses, the answers known so
%% far (Key-CM -> sp(SuccessPattern, Det)), and the libraries option.

flow_cap(16).

flow_analyse(ctx(Prog, _, How), Root, Pairs, ctx(Prog, Memo, How)) :-
    Root = need(RK, RCM, RKind),
    P0 = RK-RCM,
    empty_assoc(E),
    put_assoc(P0, E, r(RKind, bot, det, [], [], 0, 0), T0),
    put_assoc(P0, E, true, In0),
    flow_work(q([P0], []), In0, T0, E, E, Prog, How, T, Memo),
    flow_reached(P0, T, Pairs).

%% T: Key-CM -> r(Kind, SP, Det, Rows, Needs, Analyses, Changes), every
%% pair met; Memo: the answers alone, which flow_memo/5 reads; Deps:
%% Key-CM -> the pairs that read its answer; In: which pairs are queued
flow_work(Q0, In0, T0, M0, D0, Prog, How, T, M) :-
    (   flow_q_pop(Q0, P, Q1)
    ->  put_assoc(P, In0, false, In1),
        get_assoc(P, T0, r(Kind, SP0, Det0, _, _, N0, C0)),
        P = Key-CM,
        flow_pair(Key, CM, Kind, ctx(Prog, M0, How), SP1, Det1, Rows, Needs),
        flow_settle(N0, C0, SP0, Det0, SP1, Det1, SP, Det, C, Changed),
        N is N0 + 1,
        put_assoc(P, T0, r(Kind, SP, Det, Rows, Needs, N, C), T1),
        flow_note_needs(Needs, P, T1, T2, D0, D1, In1, In2, New),
        flow_q_front(New, Q1, Q2),
        (   Changed == true
        ->  put_assoc(P, M0, sp(SP, Det), M1),
            (   get_assoc(P, D1, Ds) -> true ; Ds = [] ),
            flow_q_back(Ds, Q2, Q3, In2, In3)
        ;   M1 = M0, Q3 = Q2, In3 = In2
        ),
        flow_work(Q3, In3, T2, M1, D1, Prog, How, T, M)
    ;   T = T0, M = M0
    ).

%% has the answer changed? The first one always has: the callers read
%% `bot' for a pair nobody had analysed
flow_settle(N0, C0, SP0, Det0, SP1, Det1, SP, Det, C, Changed) :-
    flow_cap(Cap),
    (   C0 >= Cap
    ->  SP = SP0, Det = Det0, C = C0, Changed = false
    ;   N0 > 0, SP1 == SP0, Det1 == Det0
    ->  SP = SP0, Det = Det0, C = C0, Changed = false
    ;   C is C0 + 1,
        (   C >= Cap -> SP = any, Det = nondet ; SP = SP1, Det = Det1 ),
        Changed = true
    ).

%% each pair a call needs: P now reads its answer, and one met for the
%% first time is queued, in reading order
flow_note_needs([], _, T, T, D, D, I, I, []).
flow_note_needs([need(K, Ms, Kd)|Ns], P, T0, T, D0, D, I0, I, New) :-
    Pk = K-Ms,
    (   get_assoc(Pk, D0, Ds0) -> true ; Ds0 = [] ),
    (   memberchk(P, Ds0) -> D1 = D0 ; put_assoc(Pk, D0, [P|Ds0], D1) ),
    (   get_assoc(Pk, T0, _)
    ->  T1 = T0, I1 = I0, New = New1
    ;   put_assoc(Pk, T0, r(Kd, bot, det, [], [], 0, 0), T1),
        put_assoc(Pk, I0, true, I1),
        New = [Pk|New1]
    ),
    flow_note_needs(Ns, P, T1, T, D1, D, I1, I, New1).

%% the queue: a front list and a back list kept reversed
flow_q_pop(q([P|F], B), P, q(F, B)) :- !.
flow_q_pop(q([], B), P, q(F, [])) :-
    B \== [],
    reverse(B, [P|F]).

flow_q_front(New, q(F0, B), q(F, B)) :-
    append(New, F0, F).

flow_q_back([], Q, Q, I, I).
flow_q_back([P|Ps], q(F, B), Q, I0, I) :-
    (   get_assoc(P, I0, true)
    ->  Q1 = q(F, B), I1 = I0
    ;   Q1 = q(F, [P|B]), put_assoc(P, I0, true, I1)
    ),
    flow_q_back(Ps, Q1, Q, I1, I).

%% the pairs the root reaches through the calls each one makes in the end;
%% a pair only an earlier answer led to is not among them
flow_reached(P0, T, Pairs) :-
    empty_assoc(E),
    put_assoc(P0, E, true, S0),
    flow_reach([P0], T, S0, Pairs).

flow_reach([], _, _, []).
flow_reach([P|Ps], T, S0, [pi(K, CM, Kind, SP, Det, Rows)|Out]) :-
    P = K-CM,
    get_assoc(P, T, r(Kind, SP, Det, Rows, Needs, _, _)),
    flow_reach_new(Needs, S0, S1, New),
    append(New, Ps, Q),
    flow_reach(Q, T, S1, Out).

flow_reach_new([], S, S, []).
flow_reach_new([need(K, Ms, _)|Ns], S0, S, New) :-
    (   get_assoc(K-Ms, S0, _)
    ->  S1 = S0, New = New1
    ;   put_assoc(K-Ms, S0, true, S1), New = [K-Ms|New1]
    ),
    flow_reach_new(Ns, S1, S, New1).

%% a pair's clauses, analysed against the memo: its rows, its success
%% pattern (`bot' when no clause can succeed yet, `any' when its clauses
%% cannot be seen at all), its determinism, and the pairs it needs. The
%% clauses a file gives a dynamic predicate are only where it starts: it
%% may bind anything, fail, or answer again, whatever they say
flow_pair(Key, CM, Kind, Ctx, SP, Det, Rows, Needs) :-
    flow_clauses(Key, Kind, Ctx, Cls),
    flow_rows(Cls, 1, CM, Ctx, [], Needs0, Rows, SPs),
    length(CM, Ar),
    (   Kind == dynamic -> SP = any, Det = nondet
    ;   Cls == [], Kind \== user -> SP = any, Det = semidet
    ;   flow_combine_sps(SPs, Ar, SP),
        (   SP == bot
        ->  Det = failure               % no clause can succeed: it never does
        ;   flow_rows_nodes(Rows, NLs),
            flow_pred_det(Cls, NLs, CM, Det)
        )
    ),
    reverse(Needs0, Needs).

flow_memo(ctx(_, Memo, _), Key, CM, SP, Det) :-
    (   get_assoc(Key-CM, Memo, sp(SP0, Det0)) -> SP = SP0, Det = Det0
    ;   SP = bot, Det = det
    ).

%% ======================================================================
%% The panels: what the query reaches that is worth drawing
%% ======================================================================
%%
%% A predicate gets a panel for each call pattern it is met with -- its
%% modes, its determinism and its lanes differ -- and a C function one
%% panel, since nothing inside it does. A library predicate is a box the
%% chart does not go inside (libraries(none), the default) unless asked:
%% libraries(reach) opens one that stands on a path to C, libraries(all)
%% every one. Its clauses are analysed all the same, for what it binds.

%% The query's lane, l0, first; then each lane a spawn starts, with its own
%% panels (lanes.pl). A call's panel is looked up by its lane and its key,
%% L-PK, in the index the graph carries as its Ids.
flow_build(Ctx0, Key, CM, Panels, Ids) :-
    Key = N/A,
    functor(G, N, A),
    flow_kind(G, Ctx0, Kind),
    flow_analyse(Ctx0, need(Key, CM, Kind), Pairs, Ctx),
    flow_pair_map(Pairs, PM),
    flow_panel_key(Kind, Key, CM, PK),
    empty_assoc(I0),
    put_assoc(0-PK, I0, 1, I1),
    flow_bfs([todo(1, Key, Kind, CM, 1)], 0, Ctx, PM, I1, 2, Panels0, I2, Next),
    flow_query_panel(Key, Kind, CM, Ctx, Panels0, Q),
    flow_lanes([Q|Panels0], Ctx, PM, I2, Next, Panels, Ids).

flow_pair_map(Pairs, PM) :-
    findall((Key-CM)-pi(Key, CM, Kind, SP, Det, Rows), member(pi(Key, CM, Kind, SP, Det, Rows), Pairs), KVs),
    list_to_assoc(KVs, PM).

%% the key of the panel a call is drawn going to
flow_panel_key(portal(_), Key, _, Key-c) :- !.
flow_panel_key(_, Key, CM, Key-CM).

%% the panels of lane L, breadth first, numbered from Next0 on
flow_bfs([], _, _, _, Ids, Next, [], Ids, Next).
flow_bfs([todo(Id, Key, Kind, CM, D)|Q], L, Ctx, PM, I0, Next0, [P|Ps], Ids, Next) :-
    flow_make_panel(Id, Key, Kind, CM, D, Ctx, PM, P),
    P = panel(_, _, _, _, _, _, _, Calls),
    flow_enqueue(Calls, D, L, Ctx, PM, I0, I1, Next0, Next1, New),
    append(Q, New, Q1),
    flow_bfs(Q1, L, Ctx, PM, I1, Next1, Ps, Ids, Next).

%% a call gets a panel when what it calls is worth drawing and, unless it
%% is C, the fixed point reached it: a call it never reached cannot run
flow_enqueue([], _, _, _, _, I, I, N, N, []).
flow_enqueue([c(Key, Kind, CMs)|Cs], D, L, Ctx, PM, I0, I, N0, N, New) :-
    flow_panel_key(Kind, Key, CMs, PK),
    (   get_assoc(L-PK, I0, _)
    ->  I1 = I0, N1 = N0, New = New1
    ;   flow_panel_worthy(Key, Kind, Ctx),
        ( Kind = portal(_) -> true ; get_assoc(Key-CMs, PM, _) )
    ->  put_assoc(L-PK, I0, N0, I1),
        N1 is N0 + 1,
        D1 is D + 1,
        New = [todo(N0, Key, Kind, CMs, D1)|New1]
    ;   I1 = I0, N1 = N0, New = New1
    ),
    flow_enqueue(Cs, D, L, Ctx, PM, I1, I, N1, N, New1).

flow_panel_worthy(_, user, _) :- !.
flow_panel_worthy(_, portal(_), _) :- !.
flow_panel_worthy(Key, dynamic, ctx(Prog, _, _)) :- !,
    get_assoc(Key, Prog, dyn([_|_])).
flow_panel_worthy(Key, library(_), ctx(_, _, How)) :-
    (   How == all -> true
    ;   How == reach -> flow_reaches_c(Key, [], 0)
    ;   fail
    ).

%% A library predicate earns a panel by standing between the query and C.
flow_reaches_c(N/A, Seen, D) :-
    D < 6,
    functor(H, N, A),
    findall(B, catch(clause(H, B), _, fail), Bodies),
    flow_bodies_goals(Bodies, Goals),
    D1 is D + 1,
    member(G, Goals),
    callable(G),
    functor(G, GN, GA),
    (   flow_portal_row(_, GN, GA, _) -> true
    ;   \+ memberchk(GN/GA, Seen),
        flow_t_lib(GN, GA, _, _),
        flow_reaches_c(GN/GA, [N/A|Seen], D1)
    ), !.

flow_bodies_goals([], []).
flow_bodies_goals([B|Bs], Gs) :-
    flow_goals_in(B, G1),
    flow_bodies_goals(Bs, G2),
    append(G1, G2, Gs).

flow_goals_in(V, []) :- var(V), !.
flow_goals_in((A, B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in((A ; B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in((A -> B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in((A *-> B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in(\+ A, Gs) :- !, flow_goals_in(A, Gs).
flow_goals_in(findall(_, G, _), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(findall(_, G, _, _), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(forall(A, B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in(aggregate_all(_, G, _), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(once(G), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(ignore(G), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(catch(G, _, R), Gs) :- !, flow_goals_in2(G, R, Gs).
flow_goals_in(_:G, Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(G, [G]).

flow_goals_in2(A, B, Gs) :-
    flow_goals_in(A, Ga),
    flow_goals_in(B, Gb),
    append(Ga, Gb, Gs).

flow_make_panel(Id, Key, portal(Mod), CM, D, _, _,
                panel(Id, Key, portal(Mod), CM, D, portal(Info), semidet, [])) :- !,
    Key = N/A,
    (   flow_portal(Mod, N, A, none, Info) -> true
    ;   length(Ms, A), flow_fill(Ms, '?'), flow_gen_arg_names(A, Ns),
        Info = info(unknown, unknown, 0, Ms, Ns)
    ).
flow_make_panel(Id, Key, Kind, CM, D, Ctx, PM,
                panel(Id, Key, Kind, CM, D, rows(Rows), Det, Calls)) :-
    (   get_assoc(Key-CM, PM, pi(_, _, _, _, Det0, Rows0))
    ->  Rows = Rows0, Det = Det0
    ;   flow_pair(Key, CM, Kind, Ctx, _, Det, Rows, _)
    ),
    flow_rows_calls(Rows, Calls).

flow_rows_nodes([], []).
flow_rows_nodes([row(_, _, _, _, Ns, _)|Rs], [Ns|NLs]) :- flow_rows_nodes(Rs, NLs).

flow_clauses(Key, user, ctx(Prog, _, _), Cls) :- !,
    get_assoc(Key, Prog, Cls).
flow_clauses(Key, dynamic, ctx(Prog, _, _), Cls) :- !,
    (   get_assoc(Key, Prog, dyn(Cls0)) -> Cls = Cls0 ; Cls = [] ).
flow_clauses(N/A, _, _, Cls) :-
    functor(H, N, A),
    findall(cl(H, B, Vs, []), ( catch(clause(H, B), _, fail), flow_gen_names(H-B, Vs) ), Cls).

%% each clause analysed: its row, and its success pattern unless it cannot
%% succeed (it fails outright, or calls what is not known to succeed)
flow_rows([], _, _, _, N, N, [], []).
flow_rows([cl(H, B, Vs, CI)|Cs], I, CM, Ctx, N0, N, [row(I, H, Vs, HF, Nodes, CI)|Rs], SPs) :-
    flow_head_state(H, CM, St0),
    flow_head_can_fail(H, CM, HF),
    flow_an_seq(B, St0, St, Ctx, N0, N1, Nodes),
    (   ( memberchk(failn, Nodes) ; flow_dead(St) )
    ->  SPs = SPs1
    ;   flow_clause_sp(H, St, SP), SPs = [SP|SPs1]
    ),
    I1 is I + 1,
    flow_rows(Cs, I1, CM, Ctx, N1, N, Rs, SPs1).

%% the calls a panel makes, the first of each panel they go to, in reading
%% order
flow_rows_calls(Rows, Calls) :-
    flow_rows_calls_(Rows, [], Rev),
    reverse(Rev, Calls).

flow_rows_calls_([], Acc, Acc).
flow_rows_calls_([row(_, _, _, _, Ns, _)|Rs], Acc0, Acc) :-
    flow_nodes_calls(Ns, Acc0, Acc1),
    flow_rows_calls_(Rs, Acc1, Acc).

flow_nodes_calls([], Acc, Acc).
flow_nodes_calls([N|Ns], Acc0, Acc) :-
    flow_node_calls(N, Acc0, Acc1),
    flow_nodes_calls(Ns, Acc1, Acc).

flow_node_calls(g(_, Kind, Ms, _, Key, _), Acc0, Acc) :- !,
    (   flow_callable_kind(Kind),
        flow_panel_key(Kind, Key, Ms, PK),
        \+ ( member(c(K1, Kd1, Ms1), Acc0), flow_panel_key(Kd1, K1, Ms1, PK1), PK1 == PK )
    ->  Acc = [c(Key, Kind, Ms)|Acc0]
    ;   Acc = Acc0
    ).
flow_node_calls(ite(_, Arms, Else), Acc0, Acc) :- !,
    flow_arms_calls(Arms, Acc0, Acc1),
    (   Else == none -> Acc = Acc1 ; flow_nodes_calls(Else, Acc1, Acc) ).
flow_node_calls(or(Bs), Acc0, Acc) :- !, flow_lists_calls(Bs, Acc0, Acc).
flow_node_calls(not(Ns), Acc0, Acc) :- !, flow_nodes_calls(Ns, Acc0, Acc).
flow_node_calls(meta(_, _, _, Ts, _), Acc0, Acc) :- !, flow_lists_calls(Ts, Acc0, Acc).
flow_node_calls(catchc(G, _, R), Acc0, Acc) :- !, flow_lists_calls([G, R], Acc0, Acc).
flow_node_calls(_, Acc, Acc).

flow_arms_calls([], Acc, Acc).
flow_arms_calls([arm(C, T)|As], Acc0, Acc) :-
    flow_nodes_calls(C, Acc0, A1),
    flow_nodes_calls(T, A1, A2),
    flow_arms_calls(As, A2, Acc).

flow_lists_calls([], Acc, Acc).
flow_lists_calls([L|Ls], Acc0, Acc) :-
    flow_nodes_calls(L, Acc0, A1),
    flow_lists_calls(Ls, A1, Acc).

%% the query, drawn as a panel of its own: ?- report(+Pat, +Text, +Nums).
flow_query_panel(Key, Kind, CM, ctx(Prog, _, _), Panels,
                 panel(0, query, query, CM, 0,
                       rows([row(0, none, Names, false, [g(Goal, Kind, CM, Det, Key, [])], [])]),
                       Det, [c(Key, Kind, CM)])) :-
    Key = N/A,
    functor(Goal, N, A),
    (   get_assoc(Key, Prog, V), flow_prog_clauses(V, [cl(H, _, Vs, _)|_])
    ->  flow_arg_names(H, Vs, Goal, 1, A, Names)
    ;   flow_gen_names(Goal, Names)
    ),
    (   memberchk(panel(1, _, _, _, _, _, Det0, _), Panels) -> Det = Det0 ; Det = semidet ).

flow_default_title(Panels, Docs, Title) :-
    memberchk(panel(0, _, _, CM, _, rows([row(_, _, _, _, [g(_, _, _, _, Key, _)], _)]), _, _), Panels),
    memberchk(panel(1, _, _, _, _, Body, _, _), Panels),
    (   Body = rows(Rows) -> true ; Rows = [] ),
    flow_names_for(Key, Docs, Rows, G, Names),
    flow_moded_head(G, CM, Names, Segs),
    flow_segs_atom(Segs, Title).

flow_segs_atom(Segs, A) :-
    findall(T, member(s(T, _), Segs), Ts),
    atomic_list_concat(Ts, A).

%% ======================================================================
%% Modes: which variables are bound when each goal runs
%% ======================================================================
%%
%% A variable is f (free), p (partly bound) or b (bound). A head enters
%% with its + arguments bound; each goal then binds what its modes say it
%% binds -- a builtin's from the table, a C function's from its row, a
%% predicate's from the success pattern the analysis has found for that
%% call pattern so far (the fixed point above). After a call not yet known
%% to succeed the state is DEAD: the clause runs on in the drawing, and
%% counts for nothing in its predicate's answer.

flow_dead(St) :-
    flow_st_find(St, dead, _).

flow_st_get(St, V, S) :-
    (   flow_st_find(St, V, S0) -> S = S0 ; S = f ).

flow_st_find([V0-S0|R], V, S) :-
    (   V0 == V -> S = S0 ; flow_st_find(R, V, S) ).

flow_st_del([], _, []).
flow_st_del([V0-S0|R], V, Out) :-
    (   V0 == V -> Out = R ; Out = [V0-S0|Out1], flow_st_del(R, V, Out1) ).

flow_raise_list([], _, St, St).
flow_raise_list([V|Vs], S, St0, St) :-
    flow_st_get(St0, V, Old),
    flow_max_state(Old, S, New),
    (   New == Old -> St1 = St0 ; flow_st_del(St0, V, St2), St1 = [V-New|St2] ),
    flow_raise_list(Vs, S, St1, St).

flow_raise_term(T, S, St0, St) :-
    term_variables(T, Vs),
    flow_raise_list(Vs, S, St0, St).

flow_max_state(A, B, M) :-
    flow_rank(A, RA),
    flow_rank(B, RB),
    (   RA >= RB -> M = A ; M = B ).

flow_rank(f, 0).
flow_rank(p, 1).
flow_rank(b, 2).

flow_all_state([], _, _).
flow_all_state([V|Vs], St, S) :-
    flow_st_get(St, V, S0),
    S0 == S,
    flow_all_state(Vs, St, S).

flow_any_not_free([V|Vs], St) :-
    (   flow_st_get(St, V, S), S \== f -> true ; flow_any_not_free(Vs, St) ).

flow_arg_modes([], _, []).
flow_arg_modes([A|As], St, [M|Ms]) :-
    flow_arg_mode(A, St, M),
    flow_arg_modes(As, St, Ms).

flow_arg_mode(A, St, M) :-
    term_variables(A, Vs),
    (   Vs == [] -> M = '+'
    ;   flow_all_state(Vs, St, b) -> M = '+'
    ;   var(A), flow_st_get(St, A, f) -> M = '-'
    ;   M = '?'
    ).

flow_head_state(H, CM, St) :-
    H =.. [_|Args],
    flow_head_pass(Args, CM, '+', b, [], St1),
    flow_head_pass(Args, CM, ':', b, St1, St2),
    flow_head_pass(Args, CM, '?', p, St2, St).

flow_head_pass([], _, _, _, St, St).
flow_head_pass([A|As], [M|Ms], Which, S, St0, St) :-
    (   M == Which -> flow_raise_term(A, S, St0, St1) ; St1 = St0 ),
    flow_head_pass(As, Ms, Which, S, St1, St).

%% a head can fail to unify when an input position holds a pattern, or one
%% variable stands in two input positions: p(X, X) called (+, +) fails on
%% two different values
flow_head_can_fail(H, CM, HF) :-
    H =.. [_|Args],
    (   flow_pattern_input(Args, CM) -> HF = true
    ;   flow_input_vars(Args, CM, Vs), flow_repeats(Vs) -> HF = true
    ;   HF = false
    ).

flow_pattern_input([A|As], [M|Ms]) :-
    (   M \== '-', nonvar(A) -> true ; flow_pattern_input(As, Ms) ).

flow_input_vars([], [], []).
flow_input_vars([A|As], [M|Ms], Vs) :-
    (   M \== '-' -> Vs = [A|Vs1] ; Vs = Vs1 ),
    flow_input_vars(As, Ms, Vs1).

flow_repeats([V|Vs]) :-
    (   flow_var_in(V, Vs) -> true ; flow_repeats(Vs) ).

%% two ways through join; a dead one contributes nothing
flow_join(S1, S2, S) :- flow_dead(S1), !, S = S2.
flow_join(S1, S2, S) :- flow_dead(S2), !, S = S1.
flow_join(S1, S2, S) :-
    flow_keys(S1, K1),
    flow_keys(S2, K2),
    flow_union_vars(K1, K2, Ks),
    flow_join_vars(Ks, S1, S2, S).

flow_keys([], []).
flow_keys([V-_|T], [V|Vs]) :- flow_keys(T, Vs).

flow_union_vars(A, [], A).
flow_union_vars(A, [V|Vs], U) :-
    (   flow_var_in(V, A) -> flow_union_vars(A, Vs, U) ; flow_union_vars([V|A], Vs, U) ).

flow_var_in(V, [W|Ws]) :-
    (   V == W -> true ; flow_var_in(V, Ws) ).

flow_join_vars([], _, _, []).
flow_join_vars([V|Vs], S1, S2, [V-S|R]) :-
    flow_st_get(S1, V, A),
    flow_st_get(S2, V, B),
    (   A == B -> S = A ; S = p ),
    flow_join_vars(Vs, S1, S2, R).

flow_join_all([], St, St).
flow_join_all([S|Ss], _, St) :- flow_join_all_(Ss, S, St).

flow_join_all_([], St, St).
flow_join_all_([S|Ss], Acc, St) :- flow_join(Acc, S, Acc1), flow_join_all_(Ss, Acc1, St).

%% ---- the body, goal by goal ------------------------------------------

flow_an_seq(B, St0, St, Ctx, M0, M, Nodes) :-
    flow_conj(B, Goals),
    flow_an_goals(Goals, St0, St, Ctx, M0, M, Nodes).

flow_conj(V, [V]) :- var(V), !.
flow_conj((A, B), Gs) :- !,
    flow_conj(A, Ga),
    flow_conj(B, Gb),
    append(Ga, Gb, Gs).
flow_conj(true, []) :- !.
flow_conj(G, [G]).

flow_an_goals([], St, St, _, M, M, []).
flow_an_goals([G|Gs], St0, St, Ctx, M0, M, Nodes) :-
    flow_an_item(G, St0, St1, Ctx, M0, M1, Ns),
    flow_an_goals(Gs, St1, St, Ctx, M1, M, Rest),
    append(Ns, Rest, Nodes).

%% A GOAL KNOWN ONLY WHEN IT RUNS -- a variable in a body, catch(G, ...),
%% call(G), call(G, X): a CLOSURE, which may fail, may leave a choice, and
%% may bind what it is handed
flow_an_item(V, St, St, _, M, M, [g(call(V), closure, [':'], nondet, none, I)]) :- var(V), !,
    flow_closure_info(V, St, I).
%% a goal the reader placed: its place and grammar form go onto its node
flow_an_item('$at'(G, Info), St0, St, Ctx, M0, M, Ns) :- !,
    flow_an_item(G, St0, St, Ctx, M0, M, Ns0),
    flow_attach(Ns0, Info, Ns).
%% phrase/2,3 and call_dcg/3 run the grammar body as phrase/3 translates it,
%% and that is what is drawn inside them
flow_an_item(P, St0, St, Ctx, M0, M, [meta(phrase, Head, [':'|Ms], [Ns], [])]) :-
    flow_phrase_call(P, G, L, R, Rest),
    nonvar(G),
    catch('$dcg_goal'(G, L, R, Goal), _, fail), !,
    flow_an_seq(Goal, St0, St, Ctx, M0, M, Ns),
    flow_arg_modes(Rest, St0, Ms),
    P =.. [F|_],
    Head =.. [F, G|Rest].
flow_an_item(_:G, St0, St, Ctx, M0, M, Ns) :- !,
    flow_an_item(G, St0, St, Ctx, M0, M, Ns).
flow_an_item(!, St, St, _, M, M, [cut]) :- !.
%% nothing after fail or throw runs: the state is dead past them
flow_an_item(fail, St, [dead-dead|St], _, M, M, [failn]) :- !.
flow_an_item(false, St, [dead-dead|St], _, M, M, [failn]) :- !.
flow_an_item(throw(E), St, [dead-dead|St], _, M, M, [thrown(E)]) :- !.
flow_an_item((C -> T ; E), St0, St, Ctx, M0, M, [ite(hard, Arms, Else)]) :- !,
    flow_an_ite((C -> T ; E), St0, St, Ctx, M0, M, Arms, Else).
flow_an_item((C *-> T ; E), St0, St, Ctx, M0, M, [ite(soft, [arm(Cn, Tn)], En)]) :- !,
    flow_an_seq(C, St0, St1, Ctx, M0, M1, Cn),
    flow_an_seq(T, St1, StT, Ctx, M1, M2, Tn),
    flow_an_seq(E, St0, StE, Ctx, M2, M, En),
    flow_join(StT, StE, St).
flow_an_item((A ; B), St0, St, Ctx, M0, M, [or(Branches)]) :- !,
    flow_disj((A ; B), Ds),
    flow_an_branches(Ds, St0, Sts, Ctx, M0, M, Branches),
    flow_join_all(Sts, St0, St).
flow_an_item((C -> T), St0, St, Ctx, M0, M, [ite(hard, [arm(Cn, Tn)], none)]) :- !,
    flow_an_seq(C, St0, St1, Ctx, M0, M1, Cn),
    flow_an_seq(T, St1, St, Ctx, M1, M, Tn).
flow_an_item(\+ G, St, St, Ctx, M0, M, [not(Ns)]) :- !,
    flow_an_seq(G, St, _, Ctx, M0, M, Ns).
flow_an_item(not(G), St, St, Ctx, M0, M, [not(Ns)]) :- !,
    flow_an_seq(G, St, _, Ctx, M0, M, Ns).
flow_an_item(findall(T, G, L), St0, St, Ctx, M0, M, [meta(findall, findall(T, '…', L), [MT, ':', ML], [Ns], [])]) :- !,
    flow_an_seq(G, St0, _, Ctx, M0, M, Ns),
    flow_arg_mode(T, St0, MT0), flow_meta_template(MT0, MT),
    flow_arg_mode(L, St0, ML),
    flow_raise_term(L, b, St0, St).
flow_an_item(findall(T, G, L, R), St0, St, Ctx, M0, M, [meta(findall, findall(T, '…', L, R), [MT, ':', ML, MR], [Ns], [])]) :- !,
    flow_an_seq(G, St0, _, Ctx, M0, M, Ns),
    flow_arg_mode(T, St0, MT0), flow_meta_template(MT0, MT),
    flow_arg_mode(L, St0, ML),
    flow_arg_mode(R, St0, MR),
    flow_raise_term(L, p, St0, St).
flow_an_item(aggregate_all(Spec, G, R), St0, St, Ctx, M0, M, [meta(aggregate_all, aggregate_all(Spec, '…', R), ['?', ':', MR], [Ns], [])]) :- !,
    flow_an_seq(G, St0, _, Ctx, M0, M, Ns),
    flow_arg_mode(R, St0, MR),
    flow_raise_term(R, b, St0, St).
flow_an_item(forall(C, A), St, St, Ctx, M0, M, [meta(forall, forall('…', '…'), [':', ':'], [Ns], [])]) :- !,
    flow_an_seq((C, A), St, _, Ctx, M0, M, Ns).
flow_an_item(once(G), St0, St, Ctx, M0, M, [meta(once, once('…'), [':'], [Ns], [])]) :- !,
    flow_an_seq(G, St0, St, Ctx, M0, M, Ns).
flow_an_item(ignore(G), St0, St, Ctx, M0, M, [meta(ignore, ignore('…'), [':'], [Ns], [])]) :- !,
    flow_an_seq(G, St0, St1, Ctx, M0, M, Ns),
    flow_join(St0, St1, St).
flow_an_item(catch(G, Ball, R), St0, St, Ctx, M0, M, [catchc(Gn, Ball, Rn)]) :- !,
    flow_an_seq(G, St0, St1, Ctx, M0, M1, Gn),
    flow_an_seq(R, St0, St2, Ctx, M1, M, Rn),
    flow_join(St1, St2, St).
%% THREADS (lanes.pl). with_mutex(M, G) is G once, under the lock;
%% cond_wait_until(C, M, G) waits until G holds, and leaves its bindings;
%% channel_forall(Ch, G) calls G with each term the channel brings, and
%% none of what it binds stays
flow_an_item(with_mutex(Mx, G), St0, St, Ctx, M0, M,
             [meta(with_mutex, with_mutex(Mx, '…'), [MM, ':'], [Ns], [lock(with, Mx)])]) :-
    flow_conc_lib(with_mutex(Mx, G), Ctx), !,
    flow_arg_mode(Mx, St0, MM),
    flow_an_seq(G, St0, St, Ctx, M0, M, Ns).
flow_an_item(cond_wait_until(C, Mx, G), St0, St, Ctx, M0, M,
             [meta(cond_wait_until, cond_wait_until(C, Mx, '…'), [MC, MM, ':'], [Ns], [cond(wait, C, Mx)])]) :-
    flow_conc_lib(cond_wait_until(C, Mx, G), Ctx), !,
    flow_arg_mode(C, St0, MC),
    flow_arg_mode(Mx, St0, MM),
    flow_an_seq(G, St0, St, Ctx, M0, M, Ns).
flow_an_item(channel_forall(Ch, G), St0, St0, Ctx, M0, M,
             [meta(channel_forall, channel_forall(Ch, '…'), [MC, ':'], [Ns], [chan(recv, Ch), into(T)])]) :-
    flow_conc_lib(channel_forall(Ch, G), Ctx), !,
    flow_arg_mode(Ch, St0, MC),
    (   flow_closure_goal(G, [T], Goal)
    ->  flow_raise_term(T, b, St0, St1),
        flow_an_seq(Goal, St1, _, Ctx, M0, M, Ns)
    ;   M = M0,
        flow_closure_info(G, St0, I),
        Ns = [g(call(G, T), closure, [':', '+'], nondet, none, I)]
    ).
%% httpd_serve/2,3 with no pool of workers serves on the caller's own
%% thread: each request is httpd_page/3 called HERE, once, with its path
%% and its request, and a page that fails is a 404 -- the server goes on to
%% the next request, and never fails. Nothing a page binds comes back.
%% (Its own heads, so the index passes them by for any other goal.)
flow_an_item(httpd_serve(P, O), St0, St, Ctx, M0, M, Ns) :-
    flow_serves_here(O),
    flow_kind(httpd_serve(P, O), Ctx, library(httpd)), !,
    flow_an_here(httpd_serve(P, O), St0, St, Ctx, M0, M, Ns).
flow_an_item(httpd_serve(P, O, C), St0, St, Ctx, M0, M, Ns) :-
    flow_serves_here(O),
    flow_kind(httpd_serve(P, O, C), Ctx, library(httpd)), !,
    flow_an_here(httpd_serve(P, O, C), St0, St, Ctx, M0, M, Ns).
%% A SPAWN: the goal it sends is proved where it goes, with what is bound
%% here -- a copy -- and nothing it binds comes back but what the spawn
%% itself hands back. Past a call that never succeeds nothing is sent.
flow_an_item(G0, St0, St, Ctx, M0, M, [g(G, spawn(Type), Ms, Det, N/A, I)]) :-
    compound(G0),
    flow_spawn(G0, Type, Goal, Bound, Outs, Back),
    flow_kind(G0, Ctx, K0),
    flow_spawn_kind(K0), !,
    flow_strip_at(G0, G),
    functor(G, N, A),
    G =.. [_|Args],
    flow_arg_modes(Args, St0, Ms),
    flow_raise_at(Outs, Args, St0, St1),
    (   flow_dead(St0)
    ->  St = St1, M = M0, Det = det, I = [unreached]
    ;   flow_raise_list(Bound, b, St0, StIn),
        term_variables(Goal, GVs),
        flow_copied_vars(GVs, St0, Copied0),
        flow_an_sent(Goal, StIn, StOut, Ctx, M0, M, Ns),
        (   Back == back
        ->  (   flow_dead(StOut) -> St = [dead-dead|St1]
            ;   flow_back_vars(GVs, StOut, St1, St)
            ),
            (   flow_nodes_total(Ns) -> Det = det ; Det = semidet )
        ;   St = St1, Det = det
        ),
        flow_strip_at(Goal, GoalS0),
        (   GoalS0 = '$jobs'(GoalS) -> true ; GoalS = GoalS0 ),
        I = [spawn(Type, GoalS, Ns, Back, Copied0)]
    ).
%% call/N runs the goal its closure makes with N-1 arguments more, and
%% that goal is what is analysed: call(double, X, Y) is double(X, Y). A
%% closure the source does not bind is known only when it runs
flow_an_item(C, St0, St, Ctx, M0, M, Ns) :-
    compound(C), functor(C, call, _), !,
    C =.. [call, G|Extra],
    (   flow_closure_goal(G, Extra, Goal)
    ->  flow_an_seq(Goal, St0, St, Ctx, M0, M, Ns)
    ;   Extra == []
    ->  flow_an_item(G, St0, St, Ctx, M0, M, Ns)
    ;   M = M0,
        flow_arg_modes(Extra, St0, EMs),
        flow_raise_args(Extra, p, St0, St),
        flow_closure_info(G, St0, I),
        Ns = [g(C, closure, [':'|EMs], nondet, none, I)]
    ).
flow_an_item(G, St0, St, Ctx, M0, M, [g(G, Kind, Ms, Det, N/A, I)]) :-
    flow_kind(G, Ctx, Kind0),
    functor(G, N, A),
    G =.. [_|Args],
    flow_arg_modes(Args, St0, Ms),
    flow_effect(Kind0, N/A, Args, Ms, St0, St1, Ctx, M0, M, Det),
    flow_relabel(Kind0, G, Kind),
    (   flow_dead(St0) -> I = [unreached], St = St1
    ;   Kind == unknown
    ->  Ctx = ctx(Prog, _, _),
        (   flow_near_name(N, A, Prog, Near) -> I = [near(Near)] ; I = [] ),
        St = St1
    ;   flow_refused(Kind0, N, A, Args, St0, Ps, Vs)
    ->  I = [inst(Ps, Vs)],
        St = [dead-dead|St1]                    % it raises: nothing after it runs
    ;   I = [], St = St1
    ).

%% httpd_serve/2,3 here: a construct whose goal is the page, its Path and
%% Request bound, its Reply free; the caller's state is the page's to read
%% and nothing the page binds comes back
flow_an_here(G0, St0, St0, Ctx, M0, M, [meta(httpd_serve, G, Ms, [Ns], [names(Names)])]) :-
    flow_strip_at(G0, G),
    G =.. [_|Args],
    flow_arg_modes(Args, St0, Ms),
    Page = httpd_page(Path, Request, _),
    flow_page_names(Page, Names),
    flow_raise_list([Path, Request], b, St0, St1),
    flow_an_seq(Page, St1, _, Ctx, M0, M, Ns).

%% what a spawn sends, analysed where it goes: its goal, or cowork_map/3's
%% jobs, jobs(Js), each proved on its own with what is bound at the spawn.
%% A list the source does not write is rest(Ns): a goal known only when it
%% runs, and no finding -- the list may well be bound by then.
flow_an_sent('$jobs'(L), St, St, Ctx, M0, M, jobs(Js)) :- !,
    flow_an_jobs(L, St, Ctx, M0, M, Js).
flow_an_sent(Goal, StIn, StOut, Ctx, M0, M, Ns) :-
    flow_an_seq(Goal, StIn, StOut, Ctx, M0, M, Ns).

flow_an_jobs(L, _, _, M, M, [rest([g(call(L), closure, [':'], nondet, none, [])])]) :-
    var(L), !.
flow_an_jobs([G|Gs], St, Ctx, M0, M, [job(Ns)|Js]) :- !,
    flow_an_seq(G, St, _, Ctx, M0, M1, Ns),
    flow_an_jobs(Gs, St, Ctx, M1, M, Js).
flow_an_jobs(_, _, _, M, M, []).

%% What a goal is, said as the chart says it: library(thread)'s goals by
%% what they do between threads, and a child process as a portal of its
%% own (lanes.pl). What the goal binds and how it ends were read from what
%% it is underneath.
%% (by clause, so a goal of any other kind costs one call)
flow_relabel(portal(thread), G, K) :- !,
    flow_relabel_conc(G, portal(thread), K).
flow_relabel(library(thread), G, K) :- !,
    flow_relabel_conc(G, library(thread), K).
flow_relabel(portal(process), G, K) :- !,
    flow_relabel_proc(G, portal(process), K).
flow_relabel(library(process), G, K) :- !,
    flow_relabel_proc(G, library(process), K).
flow_relabel(K, _, K).

flow_relabel_conc(G, K0, K) :-
    (   flow_conc_role(G, Role) -> K = conc(Role) ; K = K0 ).

flow_relabel_proc(G, K0, K) :-
    (   flow_proc_goal(G, Cmd) -> K = process(Cmd) ; K = K0 ).

%% one of the threads library's own, not the program's of the same name
flow_conc_lib(G, Ctx) :-
    flow_kind(G, Ctx, K),
    flow_conc_kind(K).

%% the arguments a spawn binds here
flow_raise_at([], _, St, St).
flow_raise_at([P|Ps], Args, St0, St) :-
    nth1(P, Args, A),
    flow_raise_term(A, b, St0, St1),
    flow_raise_at(Ps, Args, St1, St).

%% what a spawn copies: the goal's variables something here may have bound,
%% read against the state before the spawn (what the place it goes to binds
%% -- a request's path -- is not a copy). Kept by identity, so no findall/3
flow_copied_vars([], _, []).
flow_copied_vars([V|Vs], St, Out) :-
    (   flow_st_get(St, V, f) -> Out = Out1 ; Out = [V|Out1] ),
    flow_copied_vars(Vs, St, Out1).

%% cowork_ask/2 unifies its answer back: the goal's variables are bound as
%% the job left them
flow_back_vars([], _, St, St).
flow_back_vars([V|Vs], StOut, St0, St) :-
    flow_st_get(StOut, V, S),
    (   S == f -> St1 = St0 ; flow_raise_list([V], S, St0, St1) ),
    flow_back_vars(Vs, StOut, St1, St).

%% A CALL THE ENGINE REFUSES: an argument it will not take unbound
%% (modes.pl, flow_raises_unbound/4) free on every path to the call, or a
%% variable free on every path inside an expression arithmetic evaluates.
%% A state says f only where no goal before could have bound the variable,
%% on any path, so this is certain whenever the call is reached; the node
%% carries inst(Positions, Variables), and findings.pl words it.
%% (No findall/3 here: it would copy the variables, and the finding names
%% them by the clause's own.)
flow_refused(Kind, N, A, Args, St, Ps, Vs) :-
    flow_refusing_kind(Kind),
    (   flow_evaluates(N, A, EPs)
    ->  flow_args_at(EPs, Args, Xs),
        term_variables(Xs, XVs),
        flow_free_in(XVs, St, Vs),
        Vs \== [],
        flow_places_of(EPs, Args, Vs, Ps)
    ;   flow_raises_unbound(N, A, Ps, _),
        forall(member(P, Ps), ( nth1(P, Args, X), var(X), flow_st_get(St, X, f) ))
    ->  flow_args_at(Ps, Args, Vs)
    ).

flow_args_at([], _, []).
flow_args_at([P|Ps], Args, [X|Xs]) :-
    nth1(P, Args, X),
    flow_args_at(Ps, Args, Xs).

%% the variables free on every path to here
flow_free_in([], _, []).
flow_free_in([V|Vs], St, Fs) :-
    (   flow_st_get(St, V, f) -> Fs = [V|Fs1] ; Fs = Fs1 ),
    flow_free_in(Vs, St, Fs1).

%% the places whose argument holds one of Vs
flow_places_of([], _, _, []).
flow_places_of([P|Ps], Args, Vs, Out) :-
    nth1(P, Args, X),
    term_variables(X, XVs),
    (   member(V, XVs), flow_var_in(V, Vs) -> Out = [P|Out1] ; Out = Out1 ),
    flow_places_of(Ps, Args, Vs, Out1).

%% only the engine's own predicates: the program's own of one of these
%% names would be called instead
flow_refusing_kind(builtin).
flow_refusing_kind(test).
flow_refusing_kind(library(_)).

%% a closure whose goal is free on every path to it cannot be called
flow_closure_info(G, St, I) :-
    (   flow_dead(St) -> I = [unreached]
    ;   var(G), flow_st_get(St, G, f) -> I = [inst([1], [G])]
    ;   I = []
    ).

flow_meta_template('+', '+') :- !.
flow_meta_template(_, '?').

%% the goal a closure makes with arguments more: double and [X, Y] make
%% double(X, Y), and m:p(a) and [X] make p(a, X)
flow_closure_goal(G, Extra, Goal) :-
    nonvar(G),
    (   G = _:G1
    ->  flow_closure_goal(G1, Extra, Goal)
    ;   callable(G),
        G =.. L0,
        append(L0, Extra, L),
        Goal =.. L
    ).

flow_phrase_call(phrase(G, L), G, L, [], [L]).
flow_phrase_call(phrase(G, L, R), G, L, R, [L, R]).
flow_phrase_call(call_dcg(G, L, R), G, L, R, [L, R]).

%% what the node already knows -- an inner goal's own place -- stands; the
%% rest of what the reader found is added
flow_attach([g(G, K, Ms, D, Key, I0)], Info, [g(G, K, Ms, D, Key, I)]) :- !,
    flow_merge_info(I0, Info, I).
flow_attach([meta(N, H, Ms, Ts, I0)], Info, [meta(N, H, Ms, Ts, I)]) :- !,
    flow_merge_info(I0, Info, I).
flow_attach(Ns, _, Ns).

flow_merge_info(I0, Info, I) :-
    findall(X, ( member(X, Info), functor(X, F, A),
                 \+ ( member(Y, I0), functor(Y, F, A) ) ), New),
    append(I0, New, I).

flow_an_ite((C -> T ; E), St0, St, Ctx, M0, M, [arm(Cn, Tn)|Arms], Else) :-
    flow_an_seq(C, St0, St1, Ctx, M0, M1, Cn),
    flow_an_seq(T, St1, StT, Ctx, M1, M2, Tn),
    (   nonvar(E), E = (C2 -> T2 ; E2)
    ->  flow_an_ite((C2 -> T2 ; E2), St0, StE, Ctx, M2, M, Arms, Else)
    ;   Arms = [],
        flow_an_seq(E, St0, StE, Ctx, M2, M, Else)
    ),
    flow_join(StT, StE, St).

flow_disj(V, [V]) :- var(V), !.
flow_disj((A ; B), Ds) :-
    \+ ( nonvar(A), A = (_ -> _) ),
    \+ ( nonvar(A), A = (_ *-> _) ), !,
    flow_disj(A, Da),
    flow_disj(B, Db),
    append(Da, Db, Ds).
flow_disj(G, [G]).

flow_an_branches([], _, [], _, M, M, []).
flow_an_branches([D|Ds], St0, [S|Ss], Ctx, M0, M, [Ns|Nss]) :-
    flow_an_seq(D, St0, S, Ctx, M0, M1, Ns),
    flow_an_branches(Ds, St0, Ss, Ctx, M1, M, Nss).

%% what a goal binds, and how it can end -- a test binds nothing, and what
%% it says when it succeeds is still news
flow_effect(test, N/A, Args, _, St0, St, _, M, M, semidet) :- !,
    flow_test_effect(N, A, Args, St0, St).
flow_effect(unify, _, [X, Y], _, St0, St, _, M, M, Det) :- !,
    (   flow_fresh_side(X, Y, St0) -> Det = det ; Det = semidet ),
    flow_unify_effect(X, Y, St0, St).
flow_effect(portal(Mod), N/A, Args, _, St0, St, _, M, M, semidet) :- !,
    (   flow_portal(Mod, N, A, none, info(_, _, _, DMs, _)) -> true
    ;   length(DMs, A), flow_fill(DMs, '?')
    ),
    flow_apply_modes(Args, DMs, St0, St).
%% a predicate's own clauses answer it: the pair is needed, and the memo
%% says what is known of it so far
flow_effect(user, Key, Args, Ms, St0, St, Ctx, M0, M, Det) :- !,
    flow_call_effect(user, Key, Args, Ms, St0, St, Ctx, M0, M, Det).
flow_effect(dynamic, Key, Args, Ms, St0, St, Ctx, M0, M, Det) :- !,
    flow_call_effect(dynamic, Key, Args, Ms, St0, St, Ctx, M0, M, Det).
flow_effect(_, N/A, Args, Ms, St0, St, _, M, M, Det) :-
    flow_mode_for(N, A, Ms, DMs, Det), !,
    flow_apply_modes(Args, DMs, St0, St).
flow_effect(library(L), Key, Args, Ms, St0, St, Ctx, M0, M, Det) :- !,
    flow_call_effect(library(L), Key, Args, Ms, St0, St, Ctx, M0, M, Det).
flow_effect(_, _, Args, _, St0, St, _, M, M, semidet) :-
    flow_raise_args(Args, p, St0, St).

%% A TEST THAT SUCCEEDS SAYS SOMETHING. atom(X) past means X is bound, and
%% nonvar(X) that it is at least partly; neither ever holds of a variable
%% free on every path, so nothing after one runs. X < Y past means both
%% sides were numbers. var(X) never holds of a bound one.
flow_test_effect(N, 1, [X], St0, St) :-
    flow_type_test(N, How), !,
    (   var(X), flow_st_get(St0, X, f) -> St = [dead-dead|St0]
    ;   flow_raise_term(X, How, St0, St)
    ).
flow_test_effect(var, 1, [X], St0, St) :- !,
    (   var(X), flow_st_get(St0, X, b) -> St = [dead-dead|St0]
    ;   nonvar(X) -> St = [dead-dead|St0]
    ;   St = St0
    ).
flow_test_effect(N, 2, [X, Y], St0, St) :-
    flow_evaluates(N, 2, _), !,
    flow_raise_term(X-Y, b, St0, St).
flow_test_effect(_, _, _, St, St).

%% what a type test says of what it holds of: b bound, p partly
flow_type_test(atom, b).
flow_type_test(number, b).
flow_type_test(integer, b).
flow_type_test(float, b).
flow_type_test(atomic, b).
flow_type_test(string, b).
flow_type_test(ground, b).
flow_type_test(nonvar, p).
flow_type_test(compound, p).
flow_type_test(callable, p).
flow_type_test(is_list, p).

%% past a call not known to succeed nothing runs, so no pair is made and
%% no answer is read: the goal is drawn, unreached, and leaves no choice
flow_call_effect(_, _, _, _, St0, St0, _, M, M, det) :-
    flow_dead(St0), !.
flow_call_effect(Kind, Key, Args, Ms, St0, St, Ctx, M0, [need(Key, Ms, Kind)|M0], Det) :-
    flow_memo(Ctx, Key, Ms, SP, Det),
    flow_apply_sp(Args, SP, St0, St).

%% X = Y cannot fail when one side is a variable nothing has touched yet
flow_fresh_side(X, Y, St) :-
    (   var(X), flow_st_get(St, X, f), \+ flow_occurs(X, Y) -> true
    ;   var(Y), flow_st_get(St, Y, f), \+ flow_occurs(Y, X)
    ).

flow_occurs(V, T) :-
    term_variables(T, Vs),
    flow_var_in(V, Vs).

flow_unify_effect(X, Y, St0, St) :-
    term_variables(X, VX),
    term_variables(Y, VY),
    (   flow_all_state(VY, St0, b) -> flow_raise_list(VX, b, St0, St)
    ;   flow_all_state(VX, St0, b) -> flow_raise_list(VY, b, St0, St)
    ;   append(VX, VY, V), flow_raise_list(V, p, St0, St)
    ).

flow_apply_modes([], _, St, St).
flow_apply_modes([A|As], [M|Ms], St0, St) :-
    (   ( M == '-' ; M == '?' ) -> flow_raise_term(A, b, St0, St1) ; St1 = St0 ),
    flow_apply_modes(As, Ms, St1, St).

%% bot: not known to succeed, so the clause is dead past it; any: its
%% clauses cannot be seen, so it may bind anything it is given
flow_apply_sp(_, bot, St, [dead-dead|St]) :- !.
flow_apply_sp(Args, any, St0, St) :- !,
    flow_raise_args(Args, p, St0, St).
flow_apply_sp([], _, St, St).
flow_apply_sp([A|As], [S|Ss], St0, St) :-
    (   S == f -> St1 = St0 ; flow_raise_term(A, S, St0, St1) ),
    flow_apply_sp(As, Ss, St1, St).

flow_raise_args([], _, St, St).
flow_raise_args([A|As], S, St0, St) :-
    flow_raise_term(A, S, St0, St1),
    flow_raise_args(As, S, St1, St).

flow_combine_sps([], _, bot).
flow_combine_sps([S|Ss], _, SP) :- flow_meet_all(Ss, S, SP).

flow_meet_all([], S, S).
flow_meet_all([S|Ss], Acc, SP) :- flow_meet(S, Acc, Acc1), flow_meet_all(Ss, Acc1, SP).

flow_meet([], [], []).
flow_meet([A|As], [B|Bs], [C|Cs]) :-
    (   A == B -> C = A ; C = p ),
    flow_meet(As, Bs, Cs).

flow_clause_sp(H, St, SP) :-
    H =.. [_|Args],
    flow_args_final(Args, St, SP).

%% a head argument that is a structure binds the caller's variable to it,
%% whatever its own variables are: get(foo(Y)) leaves the X of get(X) at
%% least partly bound
flow_args_final([], _, []).
flow_args_final([A|As], St, [S|Ss]) :-
    term_variables(A, Vs),
    flow_vars_final(Vs, St, S0),
    (   S0 == f, nonvar(A) -> S = p ; S = S0 ),
    flow_args_final(As, St, Ss).

flow_vars_final([], _, b) :- !.
flow_vars_final(Vs, St, S) :-
    (   flow_all_state(Vs, St, b) -> S = b
    ;   flow_any_not_free(Vs, St) -> S = p
    ;   S = f
    ).

%% ---- determinism: does a call leave a choice point? -------------------

%% Read off the clauses' analysed goals (NLs, a node list per clause): a
%% choice left after a clause's last cut makes it nondet, and it is det
%% when no clause that can be reached can fail.
flow_pred_det([], _, _, semidet) :- !.
flow_pred_det(Cls, NLs, CM, Det) :-
    (   flow_alternatives(Cls, CM) -> Det = nondet
    ;   flow_late_choice(NLs) -> Det = nondet
    ;   flow_pred_total(Cls, NLs, CM) -> Det = det
    ;   Det = semidet
    ).

%% one clause that cannot fail; or clauses committed by their cuts, each
%% unable to fail once past its cut, and a last that cannot fail at all
flow_pred_total(Cls, NLs, CM) :-
    append(Init, [cl(H, _, _, _)], Cls),
    append(InitNs, [LastNs], NLs),
    flow_head_can_fail(H, CM, false),
    flow_nodes_total(LastNs),
    (   Init == [] -> true ; flow_committed(Cls) ),
    forall(member(Ns, InitNs), ( flow_after_cut(Ns, After), flow_nodes_total(After) )).

flow_late_choice(NLs) :-
    member(Ns, NLs),
    flow_after_cut(Ns, After),
    member(N, After),
    flow_node_nondet(N), !.

flow_after_cut(Ns, After) :-
    (   append(_, [cut|R], Ns), \+ memberchk(cut, R) -> After = R ; After = Ns ).

flow_nodes_total(Ns) :-
    forall(member(N, Ns), flow_node_total(N)).

%% a goal that cannot fail the first time it runs -- the drawing's CF false
flow_node_total(g(_, _, _, det, _, _)) :- !.
flow_node_total(cut) :- !.
flow_node_total(thrown(_)) :- !.
flow_node_total(meta(Name, Head, Ms, Ts, _)) :- !,
    flow_meta_can_fail(Name, Head, Ms, Ts, false).
flow_node_total(ite(_, Arms, Else)) :- !,
    Else \== none,
    flow_nodes_total(Else),
    forall(member(arm(_, T), Arms), flow_nodes_total(T)).
flow_node_total(or(Bs)) :- !,
    member(B, Bs), flow_nodes_total(B), !.
flow_node_total(catchc(G, _, R)) :-
    flow_nodes_total(G),
    flow_nodes_total(R).

flow_nodes_nondet(Ns) :-
    member(N, Ns), flow_node_nondet(N), !.

%% a goal that can leave a choice point behind
flow_node_nondet(g(_, _, _, nondet, _, _)) :- !.
flow_node_nondet(or(_)) :- !.
flow_node_nondet(ite(soft, [arm(C, _)], _)) :- flow_nodes_nondet(C), !.
flow_node_nondet(ite(_, Arms, Else)) :- !,
    (   member(arm(_, T), Arms), flow_nodes_nondet(T) -> true
    ;   Else \== none, flow_nodes_nondet(Else)
    ).
flow_node_nondet(meta(phrase, _, _, [Ns], _)) :- !, flow_nodes_nondet(Ns).
flow_node_nondet(catchc(G, _, R)) :-
    (   flow_nodes_nondet(G) -> true ; flow_nodes_nondet(R) ).

%% findall/3,4 fails only on a list it is handed; aggregate_all/3 on a
%% result it is handed, or for max or min of nothing; forall/2 on a
%% counter-example; ignore/1 never; once/1 as its goal does
flow_meta_can_fail(findall, _, Ms, _, CF) :- !,
    (   Ms = [_, _, '-'|_] -> CF = false ; CF = true ).
flow_meta_can_fail(aggregate_all, aggregate_all(Spec, _, _), [_, _, MR], _, CF) :- !,
    (   MR == '-', nonvar(Spec), \+ flow_agg_partial(Spec) -> CF = false ; CF = true ).
flow_meta_can_fail(forall, _, _, _, true) :- !.
flow_meta_can_fail(ignore, _, _, _, false) :- !.
flow_meta_can_fail(cond_wait_until, _, _, _, false) :- !.    % it waits until the goal holds
flow_meta_can_fail(httpd_serve, _, _, _, false) :- !.        % a page that fails is a 404
flow_meta_can_fail(_, _, _, [Ns], CF) :-
    (   flow_nodes_total(Ns) -> CF = false ; CF = true ).

flow_agg_partial(max(_)).
flow_agg_partial(min(_)).
flow_agg_partial(max(_, _)).
flow_agg_partial(min(_, _)).

flow_alternatives(Cls, CM) :-
    Cls = [_, _|_],
    \+ flow_indexed(Cls, CM),
    \+ flow_committed(Cls).

%% every clause but the last cuts: once one passes its cut, none is left
flow_committed(Cls) :-
    append(Init, [_], Cls),
    Init \== [],
    forall(member(cl(_, B, _, _), Init), flow_has_cut(B)).

flow_has_cut(B) :-
    flow_conj(B, Gs),
    memberchk(!, Gs).

%% a bound argument whose patterns all differ picks at most one clause
flow_indexed(Cls, CM) :-
    nth1(I, CM, '+'),
    flow_arg_keys(Cls, I, Keys),
    length(Keys, N),
    sort(Keys, Set),
    length(Set, N), !.

flow_arg_keys([], _, []).
flow_arg_keys([cl(H, _, _, _)|Cs], I, [K|Ks]) :-
    arg(I, H, A),
    nonvar(A),
    flow_key(A, K),
    flow_arg_keys(Cs, I, Ks).

flow_key(A, K) :-
    (   compound(A) -> functor(A, N, Ar), K = N/Ar ; K = A ).



%% a panel's name in both outputs: query, p1, p2, ...
flow_panel_id(0, query) :- !.
flow_panel_id(N, P) :- atomic_list_concat([p, N], P).
