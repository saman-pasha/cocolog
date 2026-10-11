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
%%               cowork_start(N, [on_start(G)], C)  nothing; G starts each worker;
%%               cowork_map(Crew, Goals, Results)   map waits for a copy of each
%%                                                  job's answer, in order
%%     httpd     httpd_serve(Port, [workers(N)])    each request on a worker of
%%                                                  the pool: httpd_page/3
%%
%% A lane is a SITE -- the place in the program a spawn stands -- so a site
%% reached from two lanes starts one lane. Its first panel is its ROOT,
%% what it proves, as the query's panel is the query: the goal as the
%% source writes it, one row, c0. cowork_map/3's root has a row for each
%% job, c1, c2, ..., each proved on its own -- one that fails is answered
%% `failed', and the next is not its retry -- and a list the source does
%% not write, or a tail it does not, is a row more: a goal known only when
%% it runs. Every panel the root reaches is drawn again in the
%% lane and numbered anew, since the same code running in two places is
%% exactly what a reader needs to see.
%%
%% WHAT CROSSES BETWEEN THEM (the links, the XML's <links>):
%%
%%     spawn     into the lane: what is copied, and what comes back --
%%               nothing, the status (run_isolated/2), or the answer
%%               (cowork_ask/2,3)
%%     join      thread_join/2 or thread_join_all/1 of the handle a spawn
%%               made, followed to it: the status only; thread_detach/1
%%               likewise, and it reads nothing
%%     channel   channel_new/1,2 names one, ch1, ch2, ... in the order the
%%               chart meets them, and the channel is followed wherever the
%%               program takes it, so each send and receive says which --
%%               and, where one lane sends and one receives, each in an
%%               order the chart can read, which send each receive takes;
%%               one the chart cannot follow is named by its variable
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
flow_spawn(cowork_map(_, Gs, _), crew, '$jobs'(Gs), [], [3], waits) :-
    (   var(Gs) -> true ; Gs = [_|_] ).
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

%% httpd_serve/2,3 serving on the caller's thread (analyse.pl): options the
%% source writes, with no workers(N) or workers(0) -- a workers(W) the
%% source does not write is neither this nor a pool
flow_serves_here(Opts) :-
    is_list(Opts),
    (   flow_opt_arg(Opts, workers, N) -> integer(N), N =< 0 ; true ).

%% what a page is handed, by the names library(httpd) gives them
flow_page_names(httpd_page(P, Rq, Rp), ['Path'=P, 'Request'=Rq, 'Reply'=Rp]).

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
        Root = panel(_, _, _, _, _, rows([row(_, _, RNames, _, _, _)|_]), _, Calls),
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

%% THE ROOT: one row, the spawned goal as analysed where it was spawned --
%% or cowork_map/3's jobs, a row each. Its key is the spawner's, so a
%% finding in it names the predicate whose clause wrote it; its rows stand
%% where the spawn does.
flow_lane_root(R, LN, Type, Key, Goal, Ns, Names0, CI0, Info, D,
               panel(R, Key, lane(Type, LN), [], D, rows(Rows), Det, Calls)) :-
    flow_lane_names(Goal, Names0, Names),
    flow_lane_ci(CI0, Info, CI),
    (   Ns = jobs(Js)
    ->  flow_job_rows(Js, 1, Names, CI, Rows, JNs),
        flow_lane_det(JNs, Det)
    ;   Rows = [row(0, none, Names, false, Ns, CI)],
        flow_lane_det(Ns, Det)
    ),
    flow_rows_calls(Rows, Calls).

%% a row for each job, c1, c2, ...; a list the source does not write is
%% the rest, a row of one goal known only when it runs, marked `rest'
flow_job_rows([], _, _, _, [], []).
flow_job_rows([J|Js], K, Names, CI, [row(K, none, Names, false, Ns, CI1)|Rows], AllNs) :-
    (   J = rest(Ns) -> CI1 = [rest|CI] ; J = job(Ns), CI1 = CI ),
    K1 is K + 1,
    flow_job_rows(Js, K1, Names, CI, Rows, AllNs1),
    append(Ns, AllNs1, AllNs).

%% a lane root of cowork_map/3's, whose rows are its jobs
flow_jobs_root(lane(_, _), [row(C, _, _, _, _, _)|_]) :- C > 0.

%% an httpd page's request is handed to it: its variables are named
%% (never by unifying: a goal may be the program's own variable, a list of
%% jobs the source does not write)
flow_lane_names(Goal, Names0, Names) :-
    flow_strip_at(Goal, G),
    (   nonvar(G), G = httpd_page(P, Rq, Rp), var(P), var(Rq), var(Rp)
    ->  flow_page_names(G, PNs),
        append(PNs, Names0, Names)
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
%%     channel(K, Made, Ops, Via, Pairs)               Ops: op(SiteId, Op, N),
%%                                                     Op new|send|recv|close,
%%                                                     N where a send or a
%%                                                     receive comes in its
%%                                                     lane's order, a list,
%%                                                     or none; Via the
%%                                                     channels it was sent
%%                                                     down; Pairs true when
%%                                                     the k-th send is the
%%                                                     k-th receive's
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
    flow_follow(Sites, LRs, Panels, Ids, Fw),
    flow_join_links(LRs, Panels, Ids, Fw, Joins),
    findall(Id-G, member(site(Id, g(G, spawn(_), _, _, _, _), _, _, _), Sites), Spawned),
    flow_channels(LRs, Panels, Ids, Fw, Spawned, Chans),
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
%% channel op), new (channel_new/1,2), join (a join or a detach)
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
flow_goal_has(join, conc(join(_)), _).
flow_goal_has(join, conc(detach(_)), _).

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

%% ---- joins: the handle followed to each join and detach ----------------
%%
%% A join or a detach is about the lane whose handle its argument holds
%% (below, "What is followed"): in the clause that spawned it, in a caller
%% that was handed it back, in a callee it was handed to, in another lane
%% it was sent to down a channel. A list of handles joins each.

flow_join_links(_, _, _, fw([], _, _, _), []) :- !.
flow_join_links(LRs, Panels, Ids, Fw, Joins) :-
    findall(join(SId, L, How),
            ( member(lr(PI, Kind, Row), LRs),
              Row = row(_, _, _, _, Nodes, _),
              flow_nodes_has(join, Nodes),
              flow_row_env(PI, Kind, Row, Panels, Ids, Fw, Env, Ss),
              member(SId-g(_, conc(Role), _, _, _, _), Ss),
              flow_join_role(Role, H, How),
              flow_term_values(H, Env, PVs),
              member(_-V-_, PVs),
              flow_handle_lane(V, L) ),
            Joins0),
    flow_uniq(Joins0, Joins).

flow_join_role(join(H), H, join).
flow_join_role(detach(H), H, detach).

flow_handle_lane(th(L), L).
flow_handle_lane(ths(L), L).

%% the variable a spawn binds to what it made
flow_spawn_handle(thread_create(_, Id), Id) :- var(Id).
flow_spawn_handle(thread_pool(_, _, Ids), Ids) :- var(Ids).

%% each once, in the order met
flow_uniq(Xs, Ys) :-
    flow_uniq_(Xs, [], Ys).

flow_uniq_([], _, []).
flow_uniq_([X|Xs], Seen, Ys) :-
    (   memberchk(X, Seen) -> Ys = Ys1 ; Ys = [X|Ys1] ),
    flow_uniq_(Xs, [X|Seen], Ys1).

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
%% What is followed: channels and thread handles
%% ======================================================================
%%
%% A clause's variables may hold what crosses between lanes: a channel,
%% ch(K) -- channel_new/1,2 at the site numbered K, in the order the chart
%% meets them -- the handle of the thread that runs lane L, th(L), or a
%% pool's list of handles, ths(L). The clause's ENVIRONMENT says which, as
%% e(Var, Path, Value, Src): Var holds Value at Path -- [] the variable
%% itself, [2, 1] the first argument of its second argument -- and Src is
%% `in' where the clause was handed it and `own' where it made it or got
%% it. It comes from
%%
%%     the head        what the callers hand each argument, at any depth
%%     the root        a lane's root holds its spawner clause's very
%%                     variables, so its environment is that clause's
%%     a maker         channel_new/1,2, thread_create/2, thread_pool/3
%%     X = T, arg/3    the value goes where the unification puts it, and
%%     member/2        a pool's list hands each element a thread's handle
%%     a call          what the callee's clauses bind in their heads --
%%                     their own values only: one handed in is not given back
%%     a receive       what every send down that channel sends, when they
%%                     agree: a channel, or a handle, sent down another
%%
%% Callers are many and recursive, so it is settled by passes until nothing
%% changes (a handful: a value is handed on, not built). Where two callers,
%% two clauses or two sends disagree the value is `unknown', and nobody
%% follows it. A program with no maker pays nothing here.
%%
%% fw(Made, Args, Rets, Carr): Made is SiteId-Value for each maker; Args
%% maps a panel to the Path-Value pairs its callers hand it, Rets a panel
%% to what its clauses give back, Carr a channel's K to what it carries.
%%
%% NO findall/3 MAY STAND BETWEEN A CLAUSE AND ITS ENVIRONMENT: it copies,
%% and an environment is about the clause's very variables. Every result
%% that leaves a findall/3 here is ground.

flow_follow(Sites, LRs, Panels, Ids, fw(Made, Args, Rets, Carr)) :-
    findall(Id, member(site(Id, g(_, conc(chan(new, _)), _, _, _, _), _, _, _), Sites), News),
    flow_number_list(News, 1, NKs),
    findall(Id-ch(K), member(Id-K, NKs), MadeC),
    findall(Id-V, ( member(site(Id, g(G, spawn(_), _, _, _, _), _, _, _), Sites),
                    flow_handle_made(G, Id, Ids, V) ),
            MadeT),
    append(MadeC, MadeT, Made),
    empty_assoc(E),
    (   Made == []
    ->  Args = E, Rets = E, Carr = E
    ;   flow_follow_panels(LRs, Ids, PIs),
        flow_callers(Panels, Ids, Callers),
        flow_passes(8, PIs, Panels, Ids, Callers, fw(Made, E, E, E), fw(_, Args, Rets, Carr))
    ).

flow_number_list([], _, []).
flow_number_list([X|Xs], K, [X-K|R]) :-
    K1 is K + 1,
    flow_number_list(Xs, K1, R).

%% the handle a spawn makes: its thread's, or its pool's list of them
flow_handle_made(thread_create(_, H), SiteId, Ids, th(L)) :-
    var(H), flow_site_lane(Ids, SiteId, L).
flow_handle_made(thread_pool(_, _, H), SiteId, Ids, ths(L)) :-
    var(H), flow_site_lane(Ids, SiteId, L).

flow_site_lane(Ids, SiteId, L) :-
    flow_site_root(Ids, SiteId, R),
    flow_panel_lane(Ids, R, L).

%% where a pass begins: the clauses anything links, and the lanes' roots
flow_follow_panels(LRs, Ids, PIs) :-
    findall(PI, member(lr(PI, _, _), LRs), Ps0),
    flow_graph_lanes(Ids, Lanes),
    findall(R, member(lane(_, _, R, _, _, _, _, _), Lanes), Rs),
    append(Ps0, Rs, Ps1),
    sort(Ps1, PIs).

%% who calls each panel, in its own lane: Q -> [P, ...]
flow_callers(Panels, Ids, Callers) :-
    findall(Q-P, ( member(panel(P, _, _, _, _, rows(_), _, Calls), Panels),
                   flow_panel_lane(Ids, P, L),
                   member(c(Key, Kind, Ms), Calls),
                   flow_panel_key(Kind, Key, Ms, PK),
                   get_assoc(L-PK, Ids, Q) ),
            QPs0),
    sort(QPs0, QPs),
    group_pairs_by_key(QPs, Groups),
    list_to_assoc(Groups, Callers).

%% A PASS looks at the panels whose clauses can hold something followed:
%% where the passes began, those handed something, and the callers of
%% those that give something back
flow_passes(0, _, _, _, _, Fw, Fw) :- !.
flow_passes(N, PIs0, Panels, Ids, Callers, Fw0, Fw) :-
    Fw0 = fw(_, A0, R0, _),
    assoc_to_keys(A0, Handed),
    assoc_to_keys(R0, Giving),
    flow_callers_of(Giving, Callers, Cs),
    append([PIs0, Handed, Cs], PIs1),
    sort(PIs1, PIs),
    findall(X, flow_contrib(PIs, Panels, Ids, Fw0, X), Xs),
    flow_fw_merge(Xs, Fw0, Fw1),
    (   Fw1 == Fw0 -> Fw = Fw0
    ;   N1 is N - 1,
        flow_passes(N1, PIs0, Panels, Ids, Callers, Fw1, Fw)
    ).

flow_callers_of([], _, []).
flow_callers_of([Q|Qs], Callers, Cs) :-
    (   get_assoc(Q, Callers, Ps) -> append(Ps, Cs1, Cs) ; Cs = Cs1 ),
    flow_callers_of(Qs, Callers, Cs1).

%% what a clause of a panel says, each a ground term: hand(Q, Path, V), a
%% call hands panel Q; ret(P, Path, V), its head gives back; carr(K, Path,
%% V), a send down channel K sends
flow_contrib(PIs, Panels, Ids, Fw, X) :-
    member(PI, PIs),
    memberchk(panel(PI, _, Kind, _, _, rows(Rows), _, _), Panels),
    flow_panel_lane(Ids, PI, L),
    member(Row, Rows),
    flow_row_env(PI, Kind, Row, Panels, Ids, Fw, Env, Ss),
    Env \== [],
    (   member(_-N, Ss),
        flow_site_contrib(N, Env, L, Ids, X)
    ;   Row = row(_, H, _, _, _, _),
        H \== none,
        flow_head_ret(H, Env, PI, X)
    ).

flow_site_contrib(g(G, Kind, Ms, _, Key, _), Env, L, Ids, X) :-
    (   Kind = conc(chan(send, Ch))
    ->  var(Ch),
        flow_env_value(Env, Ch, [], ch(K)),
        arg(2, G, T),
        flow_term_values(T, Env, PVs),
        member(P-V-_, PVs),
        X = carr(K, P, V)
    ;   flow_callable_kind(Kind),
        flow_panel_key(Kind, Key, Ms, PK),
        get_assoc(L-PK, Ids, Q),
        G =.. [_|As],
        nth1(I, As, A),
        flow_term_values(A, Env, PVs),
        member(P-V-_, PVs),
        X = hand(Q, [I|P], V)
    ).

flow_head_ret(H, Env, PI, ret(PI, [I|P], V)) :-
    H =.. [_|As],
    nth1(I, As, A),
    flow_term_values(A, Env, PVs),
    member(P-V-own, PVs).

flow_fw_merge([], Fw, Fw).
flow_fw_merge([X|Xs], Fw0, Fw) :-
    flow_fw_put(X, Fw0, Fw1),
    flow_fw_merge(Xs, Fw1, Fw).

flow_fw_put(hand(Q, P, V), fw(M, A0, R, C), fw(M, A, R, C)) :- flow_put_value(Q, P, V, A0, A).
flow_fw_put(ret(Q, P, V), fw(M, A, R0, C), fw(M, A, R, C)) :- flow_put_value(Q, P, V, R0, R).
flow_fw_put(carr(K, P, V), fw(M, A, R, C0), fw(M, A, R, C)) :- flow_put_value(K, P, V, C0, C).

%% Key's value at Path: set, kept where it agrees, `unknown' where it does
%% not -- and the assoc itself is kept when nothing changes, so a pass that
%% learns nothing is seen to by ==
flow_put_value(Key, P, V, A0, A) :-
    (   get_assoc(Key, A0, PVs) -> true ; PVs = [] ),
    (   memberchk(P-V0, PVs)
    ->  (   ( V0 == V ; V0 == unknown ) -> A = A0
        ;   flow_pv_unknown(PVs, P, PVs1), put_assoc(Key, A0, PVs1, A)
        )
    ;   put_assoc(Key, A0, [P-V|PVs], A)
    ).

flow_pv_unknown([], _, []).
flow_pv_unknown([P0-V0|R], P, [P0-V1|R1]) :-
    (   P0 == P -> V1 = unknown ; V1 = V0 ),
    flow_pv_unknown(R, P, R1).

%% ---- a clause's environment ------------------------------------------

%% its environment, and its sites in order
flow_row_env(PI, Kind, Row, Panels, Ids, Fw, Env, Ss) :-
    Row = row(C, H, _, _, Nodes, _),
    (   Kind = lane(_, _)
    ->  flow_root_env(PI, Panels, Ids, Fw, Env0)
    ;   H \== none, Fw = fw(_, Args, _, _), get_assoc(PI, Args, PVs)
    ->  H =.. [_|As],
        flow_given(PVs, As, in, [], Env0)
    ;   Env0 = []
    ),
    flow_panel_id(PI, PId),
    atomic_list_concat([PId, '.c', C], Base),
    flow_list_sites(Nodes, Base, Ss),
    flow_panel_lane(Ids, PI, L),
    flow_env_settle(3, Ss, L, Ids, Fw, Env0, Env).

%% a root's environment is its spawner clause's, where the spawn stands
flow_root_env(R, Panels, Ids, Fw, Env) :-
    (   get_assoc(lanes, Ids, Lanes),
        memberchk(lane(_, _, R, SiteId, _, _, _, _), Lanes),
        flow_site_panel(SiteId, SP),
        memberchk(panel(SP, _, SK, _, _, rows(SRows), _, _), Panels),
        flow_site_row(SiteId, SC),
        memberchk(row(SC, SH, SN, SHF, SNs, SCI), SRows)
    ->  flow_row_env(SP, SK, row(SC, SH, SN, SHF, SNs, SCI), Panels, Ids, Fw, Env, _)
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

%% A WALK OF THE SITES IN ORDER, again while it learns something: X = Y
%% may come before what makes Y
flow_env_settle(N, Ss, L, Ids, Fw, Env0, Env) :-
    flow_env_walk(Ss, L, Ids, Fw, Env0, Env1),
    (   N =< 1 -> Env = Env1
    ;   length(Env0, K0), length(Env1, K1), K1 =:= K0 -> Env = Env1
    ;   N1 is N - 1,
        flow_env_settle(N1, Ss, L, Ids, Fw, Env1, Env)
    ).

flow_env_walk([], _, _, _, Env, Env).
flow_env_walk([SId-N|Ss], L, Ids, Fw, Env0, Env) :-
    flow_env_site(N, SId, L, Ids, Fw, Env0, Env1),
    flow_env_walk(Ss, L, Ids, Fw, Env1, Env).

flow_env_site(g(G, K, Ms, _, Key, _), SId, L, Ids, Fw, Env0, Env) :- !,
    flow_env_goal(K, G, Ms, Key, SId, L, Ids, Fw, Env0, Env).
flow_env_site(meta(_, _, _, _, Info), _, _, _, Fw, Env0, Env) :- !,
    (   memberchk(chan(recv, Ch), Info), memberchk(into(T), Info)
    ->  flow_env_recv(Ch, T, Fw, Env0, Env)
    ;   Env = Env0
    ).
flow_env_site(_, _, _, _, _, Env, Env).

%% by its kind, so a goal of any other kind costs one call
flow_env_goal(conc(Role), G, _, _, SId, _, _, Fw, Env0, Env) :- !,
    flow_env_conc(Role, G, SId, Fw, Env0, Env).
flow_env_goal(spawn(_), G, _, _, SId, _, _, fw(Made, _, _, _), Env0, Env) :- !,
    (   memberchk(SId-V, Made), flow_spawn_handle(G, H)
    ->  flow_env_add(H, [], V, own, Env0, Env)
    ;   Env = Env0
    ).
flow_env_goal(unify, X = Y, _, _, _, _, _, _, Env0, Env) :- !,
    flow_env_unify(X, Y, Env0, Env).
flow_env_goal(K, G, Ms, Key, _, L, Ids, Fw, Env0, Env) :-
    flow_env_lib(G, Env0, Env1), !,
    flow_env_call(K, G, Ms, Key, L, Ids, Fw, Env1, Env).
flow_env_goal(K, G, Ms, Key, _, L, Ids, Fw, Env0, Env) :-
    flow_env_call(K, G, Ms, Key, L, Ids, Fw, Env0, Env).

flow_env_conc(chan(new, Ch), _, SId, fw(Made, _, _, _), Env0, Env) :- !,
    (   var(Ch), memberchk(SId-V, Made) -> flow_env_add(Ch, [], V, own, Env0, Env) ; Env = Env0 ).
flow_env_conc(chan(recv, Ch), G, _, Fw, Env0, Env) :- !,
    arg(2, G, T),
    flow_env_recv(Ch, T, Fw, Env0, Env).
flow_env_conc(_, _, _, _, Env, Env).

%% arg(N, T, A) takes what T holds in its N-th argument; member(X, L) and
%% memberchk/2 hand X a thread's handle when L is a pool's list
flow_env_lib(arg(N, T, A), Env0, Env) :-
    integer(N),
    flow_term_values(T, Env0, TVs),
    flow_arg_values(TVs, N, AVs),
    flow_place_all(AVs, A, Env0, Env).
flow_env_lib(member(X, Ls), Env0, Env) :-
    flow_env_pool_elem(X, Ls, Env0, Env).
flow_env_lib(memberchk(X, Ls), Env0, Env) :-
    flow_env_pool_elem(X, Ls, Env0, Env).

flow_arg_values([], _, []).
flow_arg_values([[N0|R]-V-S|TVs], N, AVs) :-
    N0 == N, !,
    AVs = [R-V-S|AVs1],
    flow_arg_values(TVs, N, AVs1).
flow_arg_values([_|TVs], N, AVs) :-
    flow_arg_values(TVs, N, AVs).

flow_env_pool_elem(X, Ls, Env0, Env) :-
    var(Ls),
    flow_env_value(Env0, Ls, [], ths(L)),
    flow_place(X, [], th(L), own, Env0, Env).

%% a call: what the callee's clauses give back, in the call's own terms
flow_env_call(K, G, Ms, Key, L, Ids, fw(_, _, Rets, _), Env0, Env) :-
    (   flow_callable_kind(K),
        flow_panel_key(K, Key, Ms, PK),
        get_assoc(L-PK, Ids, Q),
        get_assoc(Q, Rets, PVs)
    ->  G =.. [_|As],
        flow_given(PVs, As, own, Env0, Env)
    ;   Env = Env0
    ).

%% a receive: what the channel carries, placed in the term received
flow_env_recv(Ch, T, fw(_, _, _, Carr), Env0, Env) :-
    (   var(Ch), flow_env_value(Env0, Ch, [], ch(K)), get_assoc(K, Carr, PVs)
    ->  flow_given_term(PVs, T, Env0, Env)
    ;   Env = Env0
    ).

%% X = Y: what each side holds goes where it lands in the other
flow_env_unify(X, Y, Env0, Env) :-
    flow_term_values(Y, Env0, YVs),
    flow_place_all(YVs, X, Env0, Env1),
    flow_term_values(X, Env1, XVs),
    flow_place_all(XVs, Y, Env1, Env).

%% Path-Value pairs placed in a goal's arguments (Path's first step is the
%% argument) or in a term
flow_given([], _, _, Env, Env).
flow_given([[I|R]-V|PVs], As, Src, Env0, Env) :-
    (   V \== unknown, nth1(I, As, A) -> flow_place(A, R, V, Src, Env0, Env1) ; Env1 = Env0 ),
    flow_given(PVs, As, Src, Env1, Env).

flow_given_term([], _, Env, Env).
flow_given_term([P-V|PVs], T, Env0, Env) :-
    (   V \== unknown -> flow_place(T, P, V, own, Env0, Env1) ; Env1 = Env0 ),
    flow_given_term(PVs, T, Env1, Env).

flow_place_all([], _, Env, Env).
flow_place_all([P-V-S|PVs], T, Env0, Env) :-
    flow_place(T, P, V, S, Env0, Env1),
    flow_place_all(PVs, T, Env1, Env).

%% Value at Path inside T: on the variable the path reaches, with what is
%% left of the path; a path T's shape does not have places nothing
flow_place(T, P, V, Src, Env0, Env) :-
    (   var(T)
    ->  flow_env_add(T, P, V, Src, Env0, Env)
    ;   P = [J|R], compound(T), functor(T, _, Ar), J =< Ar
    ->  arg(J, T, A),
        flow_place(A, R, V, Src, Env0, Env)
    ;   Env = Env0
    ).

flow_env_add(X, P, V, Src, Env0, Env) :-
    (   flow_env_has(Env0, X, P, V) -> Env = Env0 ; Env = [e(X, P, V, Src)|Env0] ).

flow_env_has([e(X0, P0, V0, _)|R], X, P, V) :-
    (   X0 == X, P0 == P, V0 == V -> true ; flow_env_has(R, X, P, V) ).

%% what a variable holds at a path, by identity
flow_env_value([e(X0, P0, V0, _)|R], X, P, V) :-
    (   X0 == X, P0 == P -> V = V0 ; flow_env_value(R, X, P, V) ).

%% everything a term holds: Path-Value-Src, Path from the term's top
flow_term_values(T, Env, PVs) :-
    flow_term_values(T, Env, [], PVs, []).

flow_term_values(T, Env, Pre, PVs0, PVs) :-
    (   var(T) -> flow_var_values(Env, T, Pre, PVs0, PVs)
    ;   compound(T) -> T =.. [_|As], flow_args_values(As, 1, Env, Pre, PVs0, PVs)
    ;   PVs0 = PVs
    ).

flow_var_values([], _, _, PVs, PVs).
flow_var_values([e(X, P, V, S)|R], T, Pre, PVs0, PVs) :-
    (   X == T, V \== unknown
    ->  append(Pre, P, PP), PVs0 = [PP-V-S|PVs1]
    ;   PVs0 = PVs1
    ),
    flow_var_values(R, T, Pre, PVs1, PVs).

flow_args_values([], _, _, _, PVs, PVs).
flow_args_values([A|As], J, Env, Pre, PVs0, PVs) :-
    append(Pre, [J], Pre1),
    flow_term_values(A, Env, Pre1, PVs0, PVs1),
    J1 is J + 1,
    flow_args_values(As, J1, Env, Pre, PVs1, PVs).

%% ======================================================================
%% Channels
%% ======================================================================
%%
%% Each channel_new/1,2 the chart meets is a channel, ch1, ch2, ...; each
%% send, receive and close is about the channel its argument holds where
%% it stands -- or, where the chart cannot follow it, the variable that
%% names it there, var(Name). A channel sent down another says so (Via).

flow_channels(LRs, Panels, Ids, Fw, Spawned, Chans) :-
    Fw = fw(Made, _, _, Carr),
    flow_chan_ops(LRs, Panels, Ids, Fw, Ops),
    findall(channel(K, MadeAt, KOps, Via, false),
            ( member(MadeAt-ch(K), Made),
              findall(op(S, Op, none), member(op(S, Op, K), Ops), KOps),
              flow_chan_via(K, Carr, Via) ),
            Known),
    findall(Name, member(op(_, _, var(Name)), Ops), Vars0),
    sort(Vars0, Vars),
    findall(channel(var(Name), none, VOps, [], false),
            ( member(Name, Vars),
              findall(op(S, Op, none), member(op(S, Op, var(Name)), Ops), VOps) ),
            Unknown),
    append(Known, Unknown, Chans0),
    flow_chan_order(Chans0, Spawned, Panels, Ids, Chans).

%% the channels that carried channel K
flow_chan_via(K, Carr, Via) :-
    assoc_to_list(Carr, KPVs),
    findall(K2, ( member(K2-PVs, KPVs), member(_-ch(K0), PVs), K0 == K ), Via0),
    sort(Via0, Via).

%% every channel op, with the channel it is about: K, or var(Name)
flow_chan_ops(LRs, Panels, Ids, Fw, Ops) :-
    Fw = fw(Made, _, _, _),
    findall(op(SId, Op, K),
            ( member(lr(PI, Kind, Row), LRs),
              Row = row(_, _, Names, _, Nodes, _),
              flow_nodes_has(chan, Nodes),
              flow_row_env(PI, Kind, Row, Panels, Ids, Fw, Env, Ss),
              member(SId-N, Ss),
              flow_chan_op(N, Op, Ch),
              (   Op == new, memberchk(SId-ch(K0), Made) -> K = K0
              ;   var(Ch), flow_env_value(Env, Ch, [], ch(K1)) -> K = K1
              ;   flow_handle_name(Ch, Names, Nm), K = var(Nm)
              ) ),
            Ops).

flow_chan_op(g(_, conc(chan(Op, Ch)), _, _, _, _), Op, Ch).
flow_chan_op(meta(_, _, _, _, Info), recv, Ch) :- memberchk(chan(recv, Ch), Info).

%% ======================================================================
%% The order of a channel's messages
%% ======================================================================
%%
%% A channel is first in, first out. So where ONE lane sends on it and ONE
%% lane receives, each a single run, and each knows the order its own
%% sends (or receives) come in, the k-th send is what the k-th receive
%% takes -- and the chart ties those two alone (Pairs). A lane's order is
%% read by walking it as it runs, from its root: goals left to right, into
%% each call. A send or a receive whose place the walk cannot know has
%% none, and neither has any of its kind on its channel after it in its
%% lane: one a recursion repeats, one in a predicate of several clauses,
%% one inside a construct that may skip it or repeat it (if-then-else, ;,
%% \+, catch/3, findall/3, forall/2, ...), one after a goal that can be
%% redone, and every one in a lane that runs more than once -- a pool, an
%% httpd pool, a crew's on_start, cowork_map/3's jobs, or a spawn its own
%% lane's walk does not meet exactly once.

flow_chan_order(Chans0, Spawned, Panels, Ids, Chans) :-
    findall(S-K, ( member(channel(K, _, Ops, _, _), Chans0), integer(K),
                   member(op(S, Op, _), Ops), flow_msg_op(Op) ),
            SKs),
    (   SKs == []
    ->  Chans = Chans0
    ;   findall(S-x, ( member(S-_, SKs) ; member(S-_, Spawned) ), Keys0),
        sort(Keys0, Keys),
        list_to_assoc(Keys, Sites),
        flow_callers(Panels, Ids, Callers),
        flow_graph_lanes(Ids, Lanes),
        findall(L, member(lane(L, _, _, _, _, _, _, _), Lanes), Ls),
        flow_lane_walks([0|Ls], Sites, Panels, Ids, Callers, Walks),
        flow_once_lanes(Lanes, Spawned, Walks, [0], Once),
        flow_number_ops(Chans0, Walks, Once, Ids, Chans)
    ).

flow_msg_op(send).
flow_msg_op(recv).

%% each lane's walk, L-Occs: o(SiteId, Sure) for each send, receive and
%% spawn met, in the order they run
flow_lane_walks([], _, _, _, _, []).
flow_lane_walks([L|Ls], Sites, Panels, Ids, Callers, [L-Occs|Ws]) :-
    flow_relevant(L, Sites, Ids, Callers, Rel),
    (   Rel == []
    ->  Occs = []
    ;   flow_lane_start(Ids, L, Start),
        flow_recursive(Rel, L, Panels, Ids, Rec),
        flow_trav_panel(Start, true, [], tr(L, Panels, Ids, Sites, Rel, Rec), 0, _, [], Rev),
        reverse(Rev, Occs)
    ),
    flow_lane_walks(Ls, Sites, Panels, Ids, Callers, Ws).

flow_lane_start(_, 0, 0) :- !.
flow_lane_start(Ids, L, R) :-
    flow_graph_lanes(Ids, Lanes),
    memberchk(lane(L, _, R, _, _, _, _, _), Lanes).

%% the panels of lane L that hold a site, and their callers, all the way up
flow_relevant(L, Sites, Ids, Callers, Rel) :-
    assoc_to_keys(Sites, Ss),
    findall(P, ( member(S, Ss), flow_site_panel(S, P), flow_panel_lane(Ids, P, L) ), P0s),
    sort(P0s, P0),
    flow_reach_back(P0, Callers, P0, Rel).

flow_reach_back([], _, Rel, Rel).
flow_reach_back([P|Ps], Callers, Seen, Rel) :-
    (   get_assoc(P, Callers, Cs0) -> sort(Cs0, Cs) ; Cs = [] ),
    ord_subtract(Cs, Seen, New),
    ord_union(Seen, New, Seen1),
    append(Ps, New, Ps1),
    flow_reach_back(Ps1, Callers, Seen1, Rel).

%% the panels of Rel that reach themselves again
flow_recursive(Rel, L, Panels, Ids, Rec) :-
    findall(Q, ( member(Q, Rel), flow_reaches(Q, Q, Rel, L, Panels, Ids) ), Rec).

flow_reaches(From, To, Rel, L, Panels, Ids) :-
    flow_callees_in(From, L, Panels, Ids, Rel, Cs),
    flow_reach_fwd(Cs, To, Rel, L, Panels, Ids, []).

flow_reach_fwd([C|Cs], To, Rel, L, Panels, Ids, Seen) :-
    (   C =:= To -> true
    ;   memberchk(C, Seen) -> flow_reach_fwd(Cs, To, Rel, L, Panels, Ids, Seen)
    ;   flow_callees_in(C, L, Panels, Ids, Rel, Ds),
        append(Ds, Cs, Next),
        flow_reach_fwd(Next, To, Rel, L, Panels, Ids, [C|Seen])
    ).

flow_callees_in(P, L, Panels, Ids, Rel, Qs) :-
    (   memberchk(panel(P, _, _, _, _, _, _, Calls), Panels)
    ->  findall(Q, ( member(c(Key, Kind, Ms), Calls),
                     flow_panel_key(Kind, Key, Ms, PK),
                     get_assoc(L-PK, Ids, Q),
                     ord_memberchk(Q, Rel) ),
                Qs0),
        sort(Qs0, Qs)
    ;   Qs = []
    ).

%% THE WALK. A panel is sure where its call was, it has one clause, and it
%% is not recursive; a cut makes its clause sure again after a goal that
%% could be redone; a construct's lists are never sure, but once/1's,
%% with_mutex/2's and phrase/2,3's goal is where the construct stands. A
%% walk stops at 4000 panels, and what it did not meet has no place.
flow_trav_panel(P, Sure0, Stack, T, N0, N, Acc0, Acc) :-
    T = tr(_, Panels, _, _, _, Rec),
    (   N0 > 4000
    ->  N = N0, Acc = Acc0
    ;   memberchk(panel(P, _, _, _, _, rows(Rows), _, _), Panels)
    ->  N1 is N0 + 1,
        (   Sure0 == true, Rows = [_], \+ memberchk(P, Rec) -> Sure = true ; Sure = false ),
        flow_panel_id(P, PId),
        flow_trav_rows(Rows, PId, Sure, [P|Stack], T, N1, N, Acc0, Acc)
    ;   N = N0, Acc = Acc0
    ).

flow_trav_rows([], _, _, _, _, N, N, Acc, Acc).
flow_trav_rows([row(C, _, _, _, Nodes, _)|Rs], PId, Sure, Stack, T, N0, N, Acc0, Acc) :-
    atomic_list_concat([PId, '.c', C], Base),
    flow_trav_list(Nodes, Base, 1, Sure, Sure, Stack, T, N0, N1, Acc0, Acc1),
    flow_trav_rows(Rs, PId, Sure, Stack, T, N1, N, Acc1, Acc).

flow_trav_list([], _, _, _, _, _, _, N, N, Acc, Acc).
flow_trav_list([Nd|Nds], Base, K, S0, S, Stack, T, N0, N, Acc0, Acc) :-
    atomic_list_concat([Base, '.g', K], Id),
    flow_trav_node(Nd, Id, S, Stack, T, N0, N1, Acc0, Acc1),
    (   Nd == cut -> S1 = S0
    ;   flow_node_nondet(Nd) -> S1 = false
    ;   S1 = S
    ),
    K1 is K + 1,
    flow_trav_list(Nds, Base, K1, S0, S1, Stack, T, N1, N, Acc1, Acc).

flow_trav_node(g(_, Kind, Ms, _, Key, _), Id, S, Stack, T, N0, N, Acc0, Acc) :- !,
    T = tr(L, _, Ids, Sites, Rel, _),
    (   get_assoc(Id, Sites, _) -> Acc1 = [o(Id, S)|Acc0] ; Acc1 = Acc0 ),
    (   flow_callable_kind(Kind),
        flow_panel_key(Kind, Key, Ms, PK),
        get_assoc(L-PK, Ids, Q),
        ord_memberchk(Q, Rel),
        \+ memberchk(Q, Stack)
    ->  flow_trav_panel(Q, S, Stack, T, N0, N, Acc1, Acc)
    ;   N = N0, Acc = Acc1
    ).
flow_trav_node(meta(Name, _, _, Ts, _), Id, S, Stack, T, N0, N, Acc0, Acc) :- !,
    T = tr(_, _, _, Sites, _, _),
    (   get_assoc(Id, Sites, _) -> Acc1 = [o(Id, false)|Acc0] ; Acc1 = Acc0 ),
    (   memberchk(Name, [once, with_mutex, phrase]) -> SI = S ; SI = false ),
    (   Ts = [Ns] -> flow_trav_list(Ns, Id, 1, SI, SI, Stack, T, N0, N, Acc1, Acc)
    ;   N = N0, Acc = Acc1
    ).
flow_trav_node(Nd, Id, _, Stack, T, N0, N, Acc0, Acc) :-
    flow_node_goals_sub(Nd, Id, Subs),
    flow_trav_subs(Subs, Stack, T, N0, N, Acc0, Acc).

flow_trav_subs([], _, _, N, N, Acc, Acc).
flow_trav_subs([B-Ns|Subs], Stack, T, N0, N, Acc0, Acc) :-
    flow_trav_list(Ns, B, 1, false, false, Stack, T, N0, N1, Acc0, Acc1),
    flow_trav_subs(Subs, Stack, T, N1, N, Acc1, Acc).

%% the lanes that run once: the query's, and one started by a goal that
%% runs once, met exactly once and surely by a lane that runs once
flow_once_lanes([], _, _, Once, Once).
flow_once_lanes([lane(L, _, _, SiteId, From, _, _, _)|Ls], Spawned, Walks, Once0, Once) :-
    (   memberchk(From, Once0),
        memberchk(SiteId-G, Spawned),
        flow_spawn_once(G),
        memberchk(From-Occs, Walks),
        findall(S, member(o(SiteId, S), Occs), [true])
    ->  Once1 = [L|Once0]
    ;   Once1 = Once0
    ),
    flow_once_lanes(Ls, Spawned, Walks, Once1, Once).

flow_spawn_once(thread_create(_, _)).
flow_spawn_once(run_isolated(_, _)).
flow_spawn_once(cowork_ask(_, _)).
flow_spawn_once(cowork_ask(_, _, _)).
flow_spawn_once(cowork_post(_, _)).

%% each send and receive of a channel, numbered in its lane's order
flow_number_ops([], _, _, _, []).
flow_number_ops([channel(K, M, Ops0, Via, _)|Cs0], Walks, Once, Ids, [channel(K, M, Ops, Via, Pairs)|Cs]) :-
    (   integer(K)
    ->  flow_chan_seqs(Ops0, Walks, Once, Ops),
        flow_chan_pairs(Ops, Ids, Pairs)
    ;   Ops = Ops0, Pairs = false
    ),
    flow_number_ops(Cs0, Walks, Once, Ids, Cs).

flow_chan_seqs(Ops0, Walks, Once, Ops) :-
    findall(S-N, ( flow_msg_op(Op),
                   findall(S1, member(op(S1, Op, _), Ops0), Ss),
                   Ss \== [],
                   member(L-Occs, Walks),
                   findall(o(S2, Sure), ( member(o(S2, Sure), Occs), memberchk(S2, Ss) ), Os0),
                   Os0 \== [],
                   (   memberchk(L, Once) -> Os = Os0 ; flow_all_unsure(Os0, Os) ),
                   flow_count_occs(Os, 1, false, SNs),
                   member(S-N, SNs) ),
            SNs0),
    flow_op_seqs(Ops0, SNs0, Ops).

flow_all_unsure([], []).
flow_all_unsure([o(S, _)|Os], [o(S, false)|Rs]) :- flow_all_unsure(Os, Rs).

%% the k-th of its kind, until one whose place is not known
flow_count_occs([], _, _, []).
flow_count_occs([o(S, Sure)|Os], N, Broken, [S-Num|SNs]) :-
    (   Broken == false, Sure == true
    ->  Num = N, N1 is N + 1, B1 = false
    ;   Num = unsure, N1 = N, B1 = true
    ),
    flow_count_occs(Os, N1, B1, SNs).

%% a site's places, or none where any is not known
flow_op_seqs([], _, []).
flow_op_seqs([op(S, Op, _)|Os], SNs, [op(S, Op, Seq)|Rs]) :-
    findall(N, member(S-N, SNs), Ns),
    (   Ns \== [], \+ memberchk(unsure, Ns) -> Seq = Ns ; Seq = none ),
    flow_op_seqs(Os, SNs, Rs).

%% one lane sends, one receives, and every send and receive has its place
flow_chan_pairs(Ops, Ids, Pairs) :-
    findall(L, ( member(op(S, send, _), Ops), flow_site_in_lane(Ids, S, L) ), SL0),
    sort(SL0, SL),
    findall(L, ( member(op(S, recv, _), Ops), flow_site_in_lane(Ids, S, L) ), RL0),
    sort(RL0, RL),
    (   SL = [_], RL = [_],
        \+ ( member(op(_, Op, none), Ops), flow_msg_op(Op) )
    ->  Pairs = true
    ;   Pairs = false
    ).

%% the lane a site stands in
flow_site_in_lane(Ids, S, L) :-
    flow_site_panel(S, P),
    flow_panel_lane(Ids, P, L).
