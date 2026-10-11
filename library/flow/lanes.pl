%% library(flowchart), part: threads and processes -- each place code runs
%% is a LANE of the chart, and what crosses between lanes is drawn (F2,
%% DESIGN-flow.md section 7).
%%
%% A THREAD SHARES NOTHING (modules/thread): its goal is COPIED to a
%% machine, store and engine of its own as canonical text, so what is bound
%% where it is spawned goes with it, what is free is a fresh variable there,
%% and none of its bindings come back -- thread_join/2 answers a status. So
%% the analysis proves a spawned goal with what was bound at the spawn and
%% keeps its bindings out of the caller (analyse.pl), and the chart draws
%% it in a lane of its own.
%%
%% THE LANES. The query's is l0. Each place a goal is sent to run
%% elsewhere is another:
%%
%%     thread    thread_create(Goal, Id)            a thread of its own
%%     pool      thread_pool(N, Goal, Ids)          N threads, each proving Goal
%%     isolated  run_isolated(Goal, Status)         a fresh machine and store,
%%                                                  here: the caller waits
%%     crew      cowork_ask(Crew, Goal)             a worker of a cowork crew;
%%               cowork_ask(Crew, Goal, Answer)     /2 unifies the answer back,
%%               cowork_post(Crew, Goal)            /3 copies it, post waits for
%%               cowork_start(N, [on_start(G)], C)  nothing; G starts each worker
%%     httpd     httpd_serve(Port, [workers(N)])    each request on a worker of
%%                                                  the pool: httpd_page/3
%%
%% A lane is a SITE -- the place in the program a spawn stands -- so a site
%% reached from two lanes starts one lane. Its first panel is its ROOT,
%% what it proves, as the query's panel is the query: the goal as the
%% source writes it. Every panel the root reaches is drawn again in the
%% lane and numbered anew, since the same code running in two places is
%% exactly what a reader needs to see.
%%
%% WHAT CROSSES BETWEEN THEM (the links, the XML's <links>):
%%
%%     spawn     into the lane: what is copied, and what comes back --
%%               nothing, the status (run_isolated/2), or the answer
%%               (cowork_ask/2,3)
%%     join      thread_join/2 or thread_join_all/1 of what a spawn in the
%%               same clause made: the status only; thread_detach/1
%%               likewise, and it reads nothing
%%     channel   channel_new/1,2 names one, ch1, ch2, ... in the order the
%%               chart meets them, and the channel is followed into the
%%               goals and the arguments it is handed, so each send and
%%               receive says which; one the chart cannot follow is named
%%               by its variable
%%     lock      with_mutex/2 (a construct: its goal once, under the lock),
%%               mutex_lock/1, mutex_unlock/1, mutex_trylock/1, and the
%%               condition variables' wait, signal and broadcast
%%     process   a child process (library(process)): a PORTAL, like C, the
%%               end of the chart, with its command when the source writes
%%               it; a command that runs cocolog on a file names that file,
%%               whose chart is its own and is never merged into this one
%%     write     assertz/1, asserta/1, assert/1, retract/1, retractall/1,
%%               abolish/1: under --kb or --embed, other processes see it
%%               when the turn commits
%%
%% Only the libraries' own predicates are any of this: a program's own
%% thread_create/2 is the program's.

%% ======================================================================
%% What a goal does between threads
%% ======================================================================

%% flow_spawn(+G, -Type, -Goal, -Bound, -Outs, -Back): G sends Goal to run
%% in a lane of Type. Bound are variables of Goal bound THERE though not
%% here (the request an httpd page is handed), Outs the arguments of G it
%% binds here, Back what comes back: none, waits (a status or a copy, in an
%% argument of Outs) or back (cowork_ask/2: the answer unified into Goal).
flow_spawn(thread_create(G, _), thread, G, [], [2], none) :- flow_written_goal(G).
flow_spawn(thread_pool(_, G, _), pool, G, [], [3], none) :- flow_written_goal(G).
flow_spawn(run_isolated(G, _), isolated, G, [], [2], waits) :- flow_written_goal(G).
flow_spawn(cowork_ask(_, G), crew, G, [], [], back) :- flow_written_goal(G).
flow_spawn(cowork_ask(_, G, _), crew, G, [], [3], waits) :- flow_written_goal(G).
flow_spawn(cowork_post(_, G), crew, G, [], [], none) :- flow_written_goal(G).
flow_spawn(cowork_start(_, Opts, _), crew, G, [], [3], none) :-
    flow_opt_arg(Opts, on_start, G),
    flow_written_goal(G).
flow_spawn(httpd_serve(_, Opts), httpd, httpd_page(P, R, _), [P, R], [], none) :-
    flow_pool_opts(Opts).
flow_spawn(httpd_serve(_, Opts, _), httpd, httpd_page(P, R, _), [P, R], [], none) :-
    flow_pool_opts(Opts).

%% the libraries that spawn; the program's own predicate of one of these
%% names is not one
flow_spawn_kind(portal(thread)).
flow_spawn_kind(library(thread)).
flow_spawn_kind(library(cowork)).
flow_spawn_kind(library(httpd)).

flow_written_goal(G) :-
    nonvar(G),
    flow_strip_at(G, G1),
    callable(G1).

%% an option of a list the source writes -- never unifying a variable of
%% the program's clause with it
flow_opt_arg(Opts, Name, Arg) :-
    is_list(Opts),
    member(E, Opts),
    nonvar(E),
    functor(E, Name, 1), !,
    arg(1, E, Arg).

flow_pool_opts(Opts) :-
    flow_opt_arg(Opts, workers, N),
    integer(N),
    N > 0.

%% The reader wraps the goals inside a meta-call's arguments in '$at'/2 to
%% say where they stand (read.pl); the goal as written has none of it
flow_strip_at(T, T) :- var(T), !.
flow_strip_at('$at'(G, _), S) :- !, flow_strip_at(G, S).
flow_strip_at(T, S) :-
    compound(T), !,
    T =.. [F|As],
    flow_strip_at_list(As, Bs),
    S =.. [F|Bs].
flow_strip_at(T, T).

flow_strip_at_list([], []).
flow_strip_at_list([A|As], [B|Bs]) :-
    flow_strip_at(A, B),
    flow_strip_at_list(As, Bs).

%% flow_conc_role(+G, -Role): what one of library(thread)'s goals does
%% between threads
flow_conc_role(channel_new(C), chan(new, C)).
flow_conc_role(channel_new(_, C), chan(new, C)).
flow_conc_role(channel_send(C, _), chan(send, C)).
flow_conc_role(channel_recv(C, _), chan(recv, C)).
flow_conc_role(channel_recv(C, _, _), chan(recv, C)).
flow_conc_role(channel_close(C), chan(close, C)).
flow_conc_role(mutex_lock(M), lock(lock, M)).
flow_conc_role(mutex_unlock(M), lock(unlock, M)).
flow_conc_role(mutex_trylock(M), lock(trylock, M)).
flow_conc_role(cond_wait(C, M), cond(wait, C, M)).
flow_conc_role(cond_wait(C, M, _), cond(wait, C, M)).
flow_conc_role(cond_signal(C), cond(signal, C, none)).
flow_conc_role(cond_broadcast(C), cond(broadcast, C, none)).
flow_conc_role(thread_join(I, _), join(I)).
flow_conc_role(thread_join_all(Is), join(Is)).
flow_conc_role(thread_detach(I), detach(I)).

flow_conc_kind(portal(thread)).
flow_conc_kind(library(thread)).

%% flow_proc_goal(+G, -Cmd): a child process, by library(process)
flow_proc_goal(sh(C), cmd(C)).
flow_proc_goal(sh(C, _), cmd(C)).
flow_proc_goal(sh_exit(C, _), cmd(C)).
flow_proc_goal(sh_atom(C, _), cmd(C)).
flow_proc_goal(shl(Ps), parts(Ps)).
flow_proc_goal(shl(Ps, _), parts(Ps)).
flow_proc_goal(proc_run(C, _, _, _), cmd(C)).
flow_proc_goal(proc_spawn(C, _), cmd(C)).

flow_proc_kind(portal(process)).
flow_proc_kind(library(process)).

%% the command, when the source writes it -- an atom, a string, or codes,
%% which is what "..." reads as by default; parts are joined as shl/1 does
%% for words, and a part that is a variable leaves it unknown
flow_proc_command(cmd(C), T) :-
    flow_text_atom(C, T).
flow_proc_command(parts(Ps), T) :-
    is_list(Ps),
    flow_text_atoms(Ps, As),
    atomic_list_concat(As, T).

flow_text_atoms([], []).
flow_text_atoms([P|Ps], [A|As]) :-
    flow_text_atom(P, A),
    flow_text_atoms(Ps, As).

flow_text_atom(X, A) :-
    (   atom(X) -> A = X
    ;   string(X) -> atom_string(A, X)
    ;   number(X) -> atom_number(A, X)
    ;   is_list(X), X \== [], flow_all_codes(X) -> atom_codes(A, X)
    ).

flow_all_codes([]).
flow_all_codes([C|Cs]) :-
    integer(C), C > 0,
    flow_all_codes(Cs).

%% a command that runs cocolog on a file: its chart is that file's own
flow_proc_chart(Cmd, File) :-
    atomic_list_concat(Words, ' ', Cmd),
    member(W, Words),
    ( W == cocolog ; atom_concat(_, '/cocolog', W) ), !,
    member(F, Words),
    atom_concat(_, '.pl', F), !,
    File = F.

%% flow_kb_write(+G, -Op, -Pred): a write to the knowledge base, of Pred
%% (Name/Arity) when the source says which
flow_kb_write(G, Op, Pred) :-
    flow_kb_op(G, Op, C),
    (   flow_kb_pred(Op, C, P) -> Pred = P ; Pred = none ).

flow_kb_op(assertz(C), assertz, C).
flow_kb_op(asserta(C), asserta, C).
flow_kb_op(assert(C), assert, C).
flow_kb_op(retract(C), retract, C).
flow_kb_op(retractall(H), retractall, H).
flow_kb_op(abolish(PI), abolish, PI).

flow_kb_pred(abolish, PI, N/A) :- !,
    nonvar(PI), PI = N/A, atom(N), integer(A).
flow_kb_pred(_, C, N/A) :-
    nonvar(C),
    (   C = (H :- _) -> nonvar(H) ; H = C ),
    callable(H),
    functor(H, N, A).

flow_kb_kind(builtin).
flow_kb_kind(library(builtins)).

%% ======================================================================
%% The lanes: found in the panels, each with its root and its own panels
%% ======================================================================
%%
%% Every panel is scanned for spawns in order, the lanes' own panels as
%% they are made, so a spawn inside a lane starts a lane of its own. A site
%% met again -- the same predicate's panel in another lane -- goes to the
%% lane it started. The index (the graph's Ids) says which panel each call
%% of a lane goes to, L-PK -> Id; lane_of(Id) -> L for a panel of a lane
%% other than l0; site(SiteId) -> the root a spawn goes to; lanes -> each
%% lane(L, Type, Root, SiteId, FromLane, Back, Goal, Names); and links ->
%% what crosses between them.

flow_lanes(Panels0, Ctx, PM, I0, Next0, Panels, Ids) :-
    flow_keyed(Panels0, 0, Q0),
    empty_assoc(S0),
    flow_lane_scan(Q0, Ctx, PM, st(I0, Next0, 1, S0, [], [], []), St, Extra),
    St = st(I1, _, _, _, Ls0, SIs, PLs),
    reverse(Ls0, Lanes),
    append(Panels0, Extra, Panels),
    put_assoc(lanes, I1, Lanes, I2),
    flow_index_put(SIs, site, I2, I3),
    flow_index_put(PLs, lane_of, I3, I4),
    flow_link_rows(Panels, LRs),
    put_assoc(link_rows, I4, LRs, I5),
    flow_links(LRs, Panels, I5, Links),
    put_assoc(links, I5, Links, Ids).

flow_index_put([], _, I, I).
flow_index_put([K-V|KVs], F, I0, I) :-
    Key =.. [F, K],
    put_assoc(Key, I0, V, I1),
    flow_index_put(KVs, F, I1, I).

%% a panel's lane, l0 unless the index says another
flow_panel_lane(Ids, Id, L) :-
    (   get_assoc(lane_of(Id), Ids, L0) -> L = L0 ; L = 0 ).

flow_graph_lanes(Ids, Lanes) :-
    (   get_assoc(lanes, Ids, Ls) -> Lanes = Ls ; Lanes = [] ).

flow_graph_links(Ids, Links) :-
    (   get_assoc(links, Ids, Ls) -> Links = Ls ; Links = links([], [], [], [], [], []) ).

%% the root a spawn standing at SiteId goes to
flow_site_root(Ids, SiteId, Root) :-
    get_assoc(site(SiteId), Ids, Root).

%% st(Ids, Next, NextLane, Sites, Lanes, SiteIds, PanelLanes). The queue
%% and the panels made hold the SAME terms, never copies (no findall/3
%% here): a lane's root is made from the spawner's panel as it is queued,
%% and the channel a variable holds is found by that variable
flow_lane_scan([], _, _, St, St, []).
flow_lane_scan([L-P|Q], Ctx, PM, St0, St, Extra) :-
    flow_panel_spawns(P, Spawns),
    (   Spawns == []
    ->  St1 = St0, Q1 = Q, Extra = Extra1
    ;   flow_lane_sites(Spawns, L, P, Ctx, PM, St0, St1, New),
        append(Q, New, Q1),
        pairs_values(New, NPs),
        append(NPs, Extra1, Extra)
    ),
    flow_lane_scan(Q1, Ctx, PM, St1, St, Extra1).

%% each X as K-X
flow_keyed([], _, []).
flow_keyed([X|Xs], K, [K-X|KXs]) :-
    flow_keyed(Xs, K, KXs).

%% the spawns a panel's clauses make: sp(SiteId, SiteKey, Node, Names, CI).
%% NOT BY findall/3, which would copy them: a root's goal must hold the
%% very variables of the clause that spawns it, so that what the clause
%% knows of them -- which channel each holds -- is known in the lane too
flow_panel_spawns(panel(Id, Key, Kind, CM, _, rows(Rows), _, _), Spawns) :- !,
    flow_rows_spawns(Rows, panel(Id, Key, Kind, CM), Spawns).
flow_panel_spawns(_, []).

%% a clause with no spawn in it is passed over before an id is made
flow_rows_spawns([], _, []).
flow_rows_spawns([row(C, _, Names, _, Nodes, CI)|Rs], P, Spawns) :-
    (   flow_nodes_has(spawn, Nodes)
    ->  P = panel(Id, Key, Kind, CM),
        flow_panel_id(Id, PId),
        (   Kind = lane(_, _) -> PK = lane(Id) ; flow_panel_key(Kind, Key, CM, PK) ),
        atomic_list_concat([PId, '.c', C], Base),
        flow_list_goals(Nodes, Base, Gs),
        flow_goals_spawns(Gs, Base, PK, C, Names, CI, S1),
        append(S1, S2, Spawns)
    ;   Spawns = S2
    ),
    flow_rows_spawns(Rs, P, S2).

flow_goals_spawns([], _, _, _, _, _, []).
flow_goals_spawns([SiteId-Node|Gs], Base, PK, C, Names, CI, Spawns) :-
    (   Node = g(_, spawn(_), _, _, _, Info),
        memberchk(spawn(_, _, _, _, _), Info)
    ->  atom_concat(Base, Suffix, SiteId),
        Spawns = [sp(SiteId, s(PK, C, Suffix), Node, Names, CI)|Spawns1]
    ;   Spawns = Spawns1
    ),
    flow_goals_spawns(Gs, Base, PK, C, Names, CI, Spawns1).

flow_lane_sites([], _, _, _, _, St, St, []).
flow_lane_sites([sp(SiteId, SK, Node, Names, CI)|Ss], L, P, Ctx, PM, St0, St, New) :-
    St0 = st(I0, N0, LN0, Sites0, Ls0, SIs0, PLs0),
    (   get_assoc(SK, Sites0, R)
    ->  St1 = st(I0, N0, LN0, Sites0, Ls0, [SiteId-R|SIs0], PLs0),
        New = New1
    ;   R = N0,
        LN = LN0,
        LN1 is LN0 + 1,
        N1 is N0 + 1,
        P = panel(_, PKey, _, _, D, _, _, _),
        D1 is D + 1,
        Node = g(_, spawn(Type), _, _, _, Info),
        memberchk(spawn(Type, Goal, Ns, Back, _), Info),
        flow_lane_root(R, LN, Type, PKey, Goal, Ns, Names, CI, Info, D1, Root),
        Root = panel(_, _, _, _, _, rows([row(_, _, RNames, _, _, _)]), _, Calls),
        flow_enqueue(Calls, D1, LN, Ctx, PM, I0, I1, N1, N2, Todos),
        flow_bfs(Todos, LN, Ctx, PM, I1, N2, LPs, I2, N3),
        put_assoc(SK, Sites0, R, Sites1),
        findall(Pid-LN, member(panel(Pid, _, _, _, _, _, _, _), [Root|LPs]), PLs1),
        append(PLs1, PLs0, PLs2),
        St1 = st(I2, N3, LN1, Sites1, [lane(LN, Type, R, SiteId, L, Back, Goal, RNames)|Ls0],
                 [SiteId-R|SIs0], PLs2),
        flow_keyed([Root|LPs], LN, Here),
        append(Here, New1, New)
    ),
    flow_lane_sites(Ss, L, P, Ctx, PM, St1, St, New1).

%% THE ROOT: one row, the spawned goal as analysed where it was spawned. Its
%% key is the spawner's, so a finding in it names the predicate whose
%% clause wrote it; its row stands where the spawn does.
flow_lane_root(R, LN, Type, Key, Goal, Ns, Names0, CI0, Info, D,
               panel(R, Key, lane(Type, LN), [], D, rows([Row]), Det, Calls)) :-
    flow_lane_names(Goal, Names0, Names),
    flow_lane_ci(CI0, Info, CI),
    Row = row(0, none, Names, false, Ns, CI),
    flow_lane_det(Ns, Det),
    flow_rows_calls([Row], Calls).

%% an httpd page's request is handed to it: its variables are named
flow_lane_names(Goal, Names0, Names) :-
    flow_strip_at(Goal, G),
    (   G = httpd_page(P, Rq, Rp), var(P), var(Rq), var(Rp)
    ->  Names = ['Path'=P, 'Request'=Rq, 'Reply'=Rp|Names0]
    ;   Names = Names0
    ).

flow_lane_ci(CI0, Info, CI) :-
    (   memberchk(file(F), CI0) -> CF = [file(F)] ; CF = [] ),
    (   memberchk(at(L, K), Info) -> CA = [at(L, K)]
    ;   memberchk(at(L, K), CI0) -> CA = [at(L, K)]
    ;   CA = []
    ),
    append(CF, CA, CI).

flow_lane_det(Ns, Det) :-
    (   flow_nodes_total(Ns) -> Det = det
    ;   flow_nodes_nondet(Ns) -> Det = nondet
    ;   Det = semidet
    ).

%% the words a lane's kind is said in
flow_lane_word(thread, 'a thread of its own').
flow_lane_word(pool, 'each thread of a pool').
flow_lane_word(isolated, 'a fresh machine and store, the caller waiting').
flow_lane_word(crew, 'a worker of a cowork crew').
flow_lane_word(httpd, 'each request, on a worker of the httpd pool').

%% ======================================================================
%% The links: what crosses between the lanes
%% ======================================================================
%%
%%     links(Spawns, Joins, Channels, Locks, Processes, Writes)
%%
%%     spawn(SiteId, Lane, Root, Type, Back, Copied)   Copied: the names of
%%                                                     what is bound and goes,
%%                                                     as one atom
%%     join(SiteId, Lane, How)                         How: join | detach
%%     channel(K, Made, Ops)                           Ops: op(SiteId, Op),
%%                                                     Op new|send|recv|close
%%     lock(SiteId, Op, Name)                          Op with|lock|unlock|
%%                                                     trylock|wait|signal|
%%                                                     broadcast; Name the
%%                                                     mutex or condition
%%     process(SiteId, Command, Chart)                 none where not written
%%     write(SiteId, Op, Pred)
%%
%% A channel's ops that cannot be followed have K = var(Name): the variable
%% they name it by, in its clause.

flow_links(LRs, Panels, Ids, links(Spawns, Joins, Chans, Locks, Procs, Writes)) :-
    findall(S, flow_link_site(LRs, S), Sites),
    findall(X, ( member(site(Id, Node, Names, _, _), Sites),
                 flow_spawn_link(Id, Node, Names, Ids, X) ), Spawns),
    findall(X, flow_join_link(LRs, Ids, X), Joins),
    flow_channels(LRs, Panels, Ids, Chans),
    findall(X, ( member(site(Id, Node, Names, _, _), Sites), flow_lock_link(Id, Node, Names, X) ), Locks),
    findall(X, ( member(site(Id, Node, _, _, _), Sites), flow_proc_link(Id, Node, X) ), Procs),
    findall(X, ( member(site(Id, Node, _, _, _), Sites), flow_write_link(Id, Node, X) ), Writes).

%% ---- the clauses anything links -----------------------------------------
%%
%% A link is about a spawn, a goal of library(thread), a child process, a
%% write to the knowledge base, or a construct that locks, waits or
%% receives. The clauses that hold one are found by ONE walk of every goal
%% (lr(PanelId, Kind, Row), kept in the index as link_rows), indexed on the
%% node and then on its kind -- a plain goal is three calls -- and every
%% later pass reads those alone: a program with no thread in it pays that
%% walk and the spawn scan's, and nothing else.

flow_link_rows([], []).
flow_link_rows([panel(PI, _, Kind, _, _, rows(Rows), _, _)|Ps], LRs) :- !,
    flow_link_rows_(Rows, PI, Kind, LRs, LRs1),
    flow_link_rows(Ps, LRs1).
flow_link_rows([_|Ps], LRs) :-
    flow_link_rows(Ps, LRs).

flow_link_rows_([], _, _, LRs, LRs).
flow_link_rows_([Row|Rows], PI, Kind, LRs0, LRs) :-
    Row = row(_, _, _, _, Nodes, _),
    (   flow_nodes_has(link, Nodes) -> LRs0 = [lr(PI, Kind, Row)|LRs1] ; LRs0 = LRs1 ),
    flow_link_rows_(Rows, PI, Kind, LRs1, LRs).

%% the clauses anything links, as the index keeps them
flow_graph_link_rows(Ids, LRs) :-
    (   get_assoc(link_rows, Ids, LRs0) -> LRs = LRs0 ; LRs = [] ).

%% flow_nodes_has(+What, +Nodes): a node of the list, at any depth inside a
%% construct, is one What is about -- link (anything above), spawn, chan (a
%% channel op), new (channel_new/1,2)
flow_nodes_has(W, [N|Ns]) :-
    (   flow_node_has(N, W) -> true ; flow_nodes_has(W, Ns) ).

flow_node_has(g(G, K, _, _, _, _), W) :-
    flow_goal_has(W, K, G).
flow_node_has(meta(_, _, _, Ts, Info), W) :-
    (   flow_info_has(W, Info) -> true ; Ts = [Ns], flow_nodes_has(W, Ns) ).
flow_node_has(ite(_, Arms, Else), W) :-
    (   member(arm(C, T), Arms), ( flow_nodes_has(W, C) -> true ; flow_nodes_has(W, T) )
    ->  true
    ;   Else \== none, flow_nodes_has(W, Else)
    ).
flow_node_has(or(Bs), W) :-
    member(B, Bs), flow_nodes_has(W, B), !.
flow_node_has(not(Ns), W) :-
    flow_nodes_has(W, Ns).
flow_node_has(catchc(G, _, R), W) :-
    (   flow_nodes_has(W, G) -> true ; flow_nodes_has(W, R) ).

flow_goal_has(link, K, G) :- flow_kind_link(K, G).
flow_goal_has(spawn, spawn(_), _).
flow_goal_has(chan, conc(chan(_, _)), _).
flow_goal_has(new, conc(chan(new, _)), _).

flow_kind_link(spawn(_), _).
flow_kind_link(conc(_), _).
flow_kind_link(process(_), _).
flow_kind_link(builtin, G) :- flow_kb_op(G, _, _).
flow_kind_link(library(builtins), G) :- flow_kb_op(G, _, _).

flow_info_has(link, Info) :- flow_info_link(Info).
flow_info_has(chan, Info) :- memberchk(chan(_, _), Info).

flow_info_link([X|Xs]) :-
    (   flow_info_link1(X) -> true ; flow_info_link(Xs) ).

flow_info_link1(lock(_, _)).
flow_info_link1(cond(_, _, _)).
flow_info_link1(chan(_, _)).

%% every goal and construct of the clauses anything links, with its id:
%% site(Id, Node, Names, PanelId, Context)
flow_link_site(LRs, site(Id, Node, Names, PI, row(PI, C))) :-
    member(lr(PI, _, row(C, _, Names, _, Nodes, _)), LRs),
    flow_panel_id(PI, PId),
    atomic_list_concat([PId, '.c', C], Base),
    flow_list_sites(Nodes, Base, Ss),
    member(Id-Node, Ss).

%% like flow_list_goals/3, and the constructs too, before what they hold
flow_list_sites(Ns, Base, Ss) :-
    flow_list_sites_(Ns, Base, 1, Ss, []).

flow_list_sites_([], _, _, Ss, Ss).
flow_list_sites_([N|Ns], Base, K, Ss0, Ss) :-
    atomic_list_concat([Base, '.g', K], Id),
    flow_node_sites(N, Id, Ss0, Ss1),
    K1 is K + 1,
    flow_list_sites_(Ns, Base, K1, Ss1, Ss).

flow_node_sites(N, Id, [Id-N|Ss], Ss) :- N = g(_, _, _, _, _, _), !.
flow_node_sites(N, Id, [Id-N|Ss0], Ss) :- N = meta(_, _, _, Ts, _), !,
    (   Ts = [Ns] -> flow_list_sites_(Ns, Id, 1, Ss0, Ss) ; Ss = Ss0 ).
flow_node_sites(N, Id, Ss0, Ss) :-
    flow_node_goals_sub(N, Id, Subs),
    flow_sub_sites(Subs, Ss0, Ss).

%% the lists inside a construct, each with its base
flow_node_goals_sub(ite(_, Arms, Else), Id, Subs) :- !,
    findall(B-L, ( nth1(K, Arms, arm(C, T)),
                   atomic_list_concat([Id, '.a', K], AId),
                   (   atom_concat(AId, '.if', B), L = C
                   ;   B = AId, L = T
                   ) ),
            Subs0),
    (   Else == none -> Subs = Subs0
    ;   atom_concat(Id, '.else', EId), append(Subs0, [EId-Else], Subs)
    ).
flow_node_goals_sub(or(Bs), Id, Subs) :- !,
    findall(B-L, ( nth1(K, Bs, L), atomic_list_concat([Id, '.b', K], B) ), Subs).
flow_node_goals_sub(not(Ns), Id, [Id-Ns]) :- !.
flow_node_goals_sub(catchc(G, _, R), Id, [TId-G, RId-R]) :- !,
    atom_concat(Id, '.try', TId),
    atom_concat(Id, '.recover', RId).
flow_node_goals_sub(_, _, []).

flow_sub_sites([], Ss, Ss).
flow_sub_sites([B-L|Subs], Ss0, Ss) :-
    flow_list_sites_(L, B, 1, Ss0, Ss1),
    flow_sub_sites(Subs, Ss1, Ss).

flow_spawn_link(Id, g(_, spawn(Type), _, _, _, Info), Names, Ids, spawn(Id, L, R, Type, Back, CT)) :-
    memberchk(spawn(_, _, _, Back, Copied), Info),
    flow_site_root(Ids, Id, R),
    flow_panel_lane(Ids, R, L),
    flow_var_names(Copied, Names, CT).

%% ---- joins: what a spawn in the same clause made ----------------------

flow_join_link(LRs, Ids, join(JId, L, How)) :-
    member(lr(PI, _, row(C, _, _, _, Nodes, _)), LRs),
    flow_nodes_has(spawn, Nodes),
    flow_panel_id(PI, PId),
    atomic_list_concat([PId, '.c', C], Base),
    flow_list_sites(Nodes, Base, Ss),
    append(_, [SId-g(SG, spawn(_), _, _, _, _)|After], Ss),
    flow_site_root(Ids, SId, R),
    flow_panel_lane(Ids, R, L),
    flow_spawn_handle(SG, Handle),
    member(JId-g(JG, conc(Role), _, _, _, _), After),
    flow_joins(Role, Handle, How).

%% the variable a spawn binds to what it made
flow_spawn_handle(thread_create(_, Id), Id) :- var(Id).
flow_spawn_handle(thread_pool(_, _, Ids), Ids) :- var(Ids).

flow_joins(join(H), Handle, join) :- H == Handle.
flow_joins(detach(H), Handle, detach) :- H == Handle.

%% ---- locks ------------------------------------------------------------

flow_lock_link(Id, Node, Names, lock(Id, Op, Name)) :-
    (   Node = g(_, conc(lock(Op, M)), _, _, _, _) -> true
    ;   Node = g(_, conc(cond(Op, M, _)), _, _, _, _) -> true
    ;   Node = meta(_, _, _, _, Info), memberchk(lock(Op, M), Info) -> true
    ;   Node = meta(_, _, _, _, Info), memberchk(cond(Op, M, _), Info)
    ),
    flow_handle_name(M, Names, Name).

%% a mutex, a condition or a channel, as the source names it
flow_handle_name(M, Names, Name) :-
    (   var(M), flow_var_name(M, Names, N) -> Name = N
    ;   var(M) -> Name = '_'
    ;   atom(M) -> Name = M
    ;   format(atom(Name), '~q', [M])
    ).

%% ---- processes and writes ----------------------------------------------

flow_proc_link(Id, g(_, process(Cmd), _, _, _, _), process(Id, T, F)) :-
    (   flow_proc_command(Cmd, T0) -> T = T0 ; T = none ),
    (   T \== none, flow_proc_chart(T, F0) -> F = F0 ; F = none ).

flow_write_link(Id, g(G, K, _, _, _, _), write(Id, Op, Pred)) :-
    flow_kb_kind(K),
    flow_kb_write(G, Op, Pred).

%% ======================================================================
%% Channels, followed
%% ======================================================================
%%
%% channel_new/1,2 makes one, numbered by the order the chart meets the
%% sites. A clause's ENVIRONMENT says which channel each of its variables
%% holds: from its head, by what the callers hand each argument, and from
%% the channel_new it runs, and from X = Y. A call hands its callee's panel
%% what it holds in each argument; a spawn hands its root the clause's own
%% environment, since the root's goal IS the clause's term. Callers are
%% many and recursive, so the arguments are settled by passes until none
%% changes (a handful: a channel is handed on, not built). An argument two
%% callers hand different channels is one nobody can follow.

flow_channels(LRs, Panels, Ids, Chans) :-
    findall(Id, flow_link_site(LRs, site(Id, g(_, conc(chan(new, _)), _, _, _, _), _, _, _)), News),
    flow_number_list(News, 1, Made),
    empty_assoc(A0),
    (   Made == [] -> Args = A0
    ;   flow_chan_panels(Ids, Made, PIs),
        flow_chan_passes(5, PIs, Panels, Ids, Made, A0, Args)
    ),
    flow_chan_ops(LRs, Panels, Ids, Made, Args, Ops),
    findall(channel(K, MadeAt, KOps),
            ( member(MadeAt-K, Made),
              findall(op(S, Op), member(op(S, Op, K), Ops), KOps) ),
            Known),
    findall(Name, member(op(_, _, var(Name)), Ops), Vars0),
    sort(Vars0, Vars),
    findall(channel(var(Name), none, VOps),
            ( member(Name, Vars),
              findall(op(S, Op), member(op(S, Op, var(Name)), Ops), VOps) ),
            Unknown),
    append(Known, Unknown, Chans).

flow_number_list([], _, []).
flow_number_list([X|Xs], K, [X-K|R]) :-
    K1 is K + 1,
    flow_number_list(Xs, K1, R).

%% Args: PanelId -> [I-K, ...], an argument position and the channel it
%% holds, or I-unknown where two callers disagree. A pass looks at the
%% panels whose clauses can hold a channel: the lanes' roots, the panels
%% that make one, and those handed one by the passes before
flow_chan_passes(0, _, _, _, _, A, A) :- !.
flow_chan_passes(N, PIs0, Panels, Ids, Made, A0, A) :-
    assoc_to_keys(A0, Handed),
    append(PIs0, Handed, PIs1),
    sort(PIs1, PIs),
    findall(Q-(I-K), flow_chan_handed(PIs, Panels, Ids, Made, A0, Q, I, K), Hs),
    flow_chan_merge(Hs, A0, A1),
    (   A1 == A0 -> A = A0
    ;   N1 is N - 1,
        flow_chan_passes(N1, PIs0, Panels, Ids, Made, A1, A)
    ).

%% the lanes' roots and the panels that make a channel
flow_chan_panels(Ids, Made, PIs) :-
    flow_graph_lanes(Ids, Lanes),
    findall(R, member(lane(_, _, R, _, _, _, _, _), Lanes), Rs),
    findall(P, ( member(SId-_, Made), flow_site_panel(SId, P) ), Ms),
    append(Rs, Ms, PIs).

%% what each call hands: the panel it goes to, an argument, a channel
flow_chan_handed(PIs, Panels, Ids, Made, Args, Q, I, K) :-
    member(PI, PIs),
    memberchk(panel(PI, _, Kind, _, _, rows(Rows), _, _), Panels),
    member(Row, Rows),
    Row = row(C, _, _, _, Nodes, _),
    flow_chan_env(PI, Kind, Row, Panels, Ids, Made, Args, Env),
    Env \== [],
    flow_panel_lane(Ids, PI, L),
    flow_panel_id(PI, PId),
    atomic_list_concat([PId, '.c', C], Base),
    flow_list_sites(Nodes, Base, Ss),
    member(SId-Node, Ss),
    flow_chan_hand(Node, SId, L, Ids, Env, Q, I, K).

%% a call to a panel of the lane: its arguments
flow_chan_hand(g(G, Kind, Ms, _, Key, _), _, L, Ids, Env, Q, I, K) :-
    flow_callable_kind(Kind),
    flow_panel_key(Kind, Key, Ms, PK),
    get_assoc(L-PK, Ids, Q),
    G =.. [_|As],
    nth1(I, As, A),
    var(A),
    flow_env_get(Env, A, K).
%% a spawn: the root holds the clause's own variables -- nothing to hand
%% by position; flow_chan_env/8 reads the spawner's environment instead

flow_chan_merge([], A, A).
flow_chan_merge([Q-(I-K)|Hs], A0, A) :-
    (   get_assoc(Q, A0, IKs) -> true ; IKs = [] ),
    (   memberchk(I-K0, IKs)
    ->  (   K0 == K -> A1 = A0
        ;   K0 == unknown -> A1 = A0
        ;   flow_ik_set(IKs, I, unknown, IKs1), put_assoc(Q, A0, IKs1, A1)
        )
    ;   put_assoc(Q, A0, [I-K|IKs], A1)
    ),
    flow_chan_merge(Hs, A1, A).

flow_ik_set([], _, _, []).
flow_ik_set([I0-K0|R], I, K, [I0-K1|R1]) :-
    (   I0 == I -> K1 = K ; K1 = K0 ),
    flow_ik_set(R, I, K, R1).

%% a clause's environment: Var-K pairs, by identity
flow_chan_env(PI, Kind, row(C, H, _, _, Nodes, _), Panels, Ids, Made, Args, Env) :-
    (   Kind = lane(_, _)
    ->  flow_root_env(PI, Panels, Ids, Made, Args, Env0)
    ;   H \== none, get_assoc(PI, Args, IKs)
    ->  H =.. [_|As],
        flow_head_env(IKs, As, Env0)
    ;   Env0 = []
    ),
    flow_panel_id(PI, PId),
    atomic_list_concat([PId, '.c', C], Base),
    flow_list_sites(Nodes, Base, Ss),
    flow_env_walk(Ss, Made, Env0, Env).

%% the head's arguments a channel was handed in, by the clause's own
%% variables (a findall/3 would copy them, and nothing would match)
flow_head_env([], _, []).
flow_head_env([I-K|IKs], As, Env) :-
    (   K \== unknown, nth1(I, As, V), var(V) -> Env = [V-K|Env1] ; Env = Env1 ),
    flow_head_env(IKs, As, Env1).

%% a root's environment is its spawner clause's, where the spawn stands
flow_root_env(R, Panels, Ids, Made, Args, Env) :-
    (   get_assoc(lanes, Ids, Lanes),
        memberchk(lane(_, _, R, SiteId, _, _, _, _), Lanes),
        flow_site_panel(SiteId, SP),
        memberchk(panel(SP, _, SK, _, _, rows(SRows), _, _), Panels),
        flow_site_row(SiteId, SC),
        memberchk(row(SC, SH, SN, SHF, SNs, SCI), SRows),
        SK \= lane(_, _)
    ->  flow_chan_env(SP, SK, row(SC, SH, SN, SHF, SNs, SCI), Panels, Ids, Made, Args, Env)
    ;   Env = []
    ).

%% 'p12.c3.g4' -> 12 and 3
flow_site_panel(SiteId, P) :-
    atomic_list_concat([PA|_], '.', SiteId),
    atom_concat(p, NA, PA),
    atom_number(NA, P).

flow_site_row(SiteId, C) :-
    atomic_list_concat([_, CA|_], '.', SiteId),
    atom_concat(c, NA, CA),
    atom_number(NA, C).

flow_env_walk([], _, Env, Env).
flow_env_walk([SId-N|Ss], Made, Env0, Env) :-
    (   N = g(_, conc(chan(new, Ch)), _, _, _, _), var(Ch), memberchk(SId-K, Made)
    ->  Env1 = [Ch-K|Env0]
    ;   N = g(X = Y, unify, _, _, _, _), var(X), var(Y), flow_env_get(Env0, Y, K)
    ->  Env1 = [X-K|Env0]
    ;   N = g(X = Y, unify, _, _, _, _), var(X), var(Y), flow_env_get(Env0, X, K)
    ->  Env1 = [Y-K|Env0]
    ;   Env1 = Env0
    ),
    flow_env_walk(Ss, Made, Env1, Env).

flow_env_get([V0-K0|R], V, K) :-
    (   V0 == V -> K = K0 ; flow_env_get(R, V, K) ).

%% every channel op, with the channel it is about: K, or var(Name)
flow_chan_ops(LRs, Panels, Ids, Made, Args, Ops) :-
    findall(op(SId, Op, K),
            ( member(lr(PI, Kind, Row), LRs),
              Row = row(C, _, Names, _, Nodes, _),
              flow_nodes_has(chan, Nodes),
              flow_panel_id(PI, PId),
              flow_chan_env(PI, Kind, Row, Panels, Ids, Made, Args, Env),
              atomic_list_concat([PId, '.c', C], Base),
              flow_list_sites(Nodes, Base, Ss),
              member(SId-N, Ss),
              flow_chan_op(N, Op, Ch),
              (   memberchk(SId-K0, Made), Op == new -> K = K0
              ;   var(Ch), flow_env_get(Env, Ch, K1) -> K = K1
              ;   flow_handle_name(Ch, Names, Nm), K = var(Nm)
              ) ),
            Ops).

flow_chan_op(g(_, conc(chan(Op, Ch)), _, _, _, _), Op, Ch).
flow_chan_op(meta(_, _, _, _, Info), recv, Ch) :- memberchk(chan(recv, Ch), Info).
