%% library(flow/chart), part: the findings -- what is wrong, and where.
%%
%% THE ANALYSIS ALREADY KNOWS THINGS A PROGRAMMER WANTS TO BE TOLD, and a
%% finding is one only the flow analysis can see (cocolint stays the
%% linter). Each is about one place, named by the id the XML and the SVG
%% give it, and says what will happen there in a sentence:
%%
%%   unknown_procedure  error    a call nothing answers -- no clause,
%%                               builtin, module or dynamic declaration --
%%                               raises existence_error; a near name is
%%                               offered
%%   instantiation      error    a call the engine refuses with an
%%                               argument free on every path to it
%%                               (modes.pl, flow_raises_unbound/4), an
%%                               expression arithmetic evaluates with such
%%                               a variable in it, or a closure with no
%%                               goal to call
%%   left_recursion     error    a predicate whose first call reaches
%%                               itself again with the same inputs -- a
%%                               grammar rule that calls itself before
%%                               reading any input -- loops for ever
%%   unreachable_clause warning  an earlier clause matches every call of
%%                               this pattern and cuts before anything
%%                               can fail
%%   det_promise        warning  a `%! p(...) is det' (or semidet) comment
%%                               the analysis says the code does not keep,
%%                               and the goals that break it
%%   discontiguous      warning  the clauses of a predicate are not together
%%                               in the file, and it is not declared
%%                               discontiguous: cocolog joins them without a
%%                               word where SWI warns, so a helper given a
%%                               name already taken joins that predicate
%%   defined_twice      error    a later place of a predicate's clauses
%%                               repeats a clause of an earlier one, or holds
%%                               one an earlier fact covers: a second
%%                               definition, joined to the first, whose
%%                               answers all come again on backtracking
%%
%% and three about threads (F2, lanes.pl), each about one goal:
%%
%%   thread_visibility  warning  a call, in a lane of its own, to a dynamic
%%                               predicate only another lane writes: a
%%                               thread's store starts with what the modules
%%                               hold and none of what was asserted, and an
%%                               isolated proof's sees no write of a turn
%%                               still running
%%   lock_held          warning  mutex_lock/1 with a goal after it that can
%%                               fail before the clause's mutex_unlock/1:
%%                               that way out keeps the lock
%%   thread_unjoined    warning  thread_create/2 whose Id nothing else in the
%%                               clause or its head names: neither joined
%%                               nor detached, the thread's slot is never
%%                               given back
%%
%% Only the program's own panels are looked at: a library's clauses are
%% not the program's to fix. A goal past a call that never succeeds is
%% never reached, and has no finding. A lane's root is the program's own
%% goal, so its goals are looked at too; a predicate drawn again in another
%% lane is looked at once, where the chart first meets it.
%%
%%     finding(N, Kind, Severity, At, In, Where, Text, See)
%%
%% N numbers them in document order; At is the id; In the predicate whose
%% panel holds it; Where where(File, Line, Col) or none; See the ids of the
%% other places it involves.

:- use_module(library(stream)).

flow_findings(graph(_, Src, Panels, Ids, Docs), Fs) :-
    findall(P, ( member(P, Panels), P = panel(I, _, K, _, _, rows(_), _, _), I > 0,
                 memberchk(K, [user, dynamic]) ), Own0),
    (   flow_graph_lanes(Ids, []) -> Own = Own0
    ;   empty_assoc(Seen0), flow_first_pairs(Own0, Seen0, Own)
    ),
    findall(P, ( member(P, Panels), P = panel(_, _, lane(_, _), _, _, rows(_), _, _) ), Roots),
    findall(Key-F, ( member(P, Own), flow_panel_finding(P, Src, Docs, Key, F) ), KFs0),
    findall(Key-F, ( member(P, Roots), flow_goal_findings(P, Key, F) ), KFsR),
    flow_left_recursion(Own, Ids, KFs1),
    append(Own, Roots, Mine),
    flow_thread_findings(Mine, Panels, Ids, KFs2),
    flow_discontiguous(Own, Src, KFsD),
    append([KFs0, KFsR, KFs1, KFs2, KFsD], KFs3),
    keysort(KFs3, KFs),
    flow_number_findings(KFs, 1, Fs).

%% a predicate and call pattern drawn in two lanes is the same code: the
%% first panel speaks for it
flow_first_pairs([], _, []).
flow_first_pairs([P|Ps], Seen, Out) :-
    P = panel(_, Key, _, CM, _, _, _, _),
    (   get_assoc(Key-CM, Seen, _) -> Out = Out1, Seen1 = Seen
    ;   Out = [P|Out1], put_assoc(Key-CM, Seen, x, Seen1)
    ),
    flow_first_pairs(Ps, Seen1, Out1).

flow_number_findings([], _, []).
flow_number_findings([_-f(Kind, Sev, At, In, Where, Text, See)|KFs], N,
                     [finding(N, Kind, Sev, At, In, Where, Text, See)|Fs]) :-
    N1 is N + 1,
    flow_number_findings(KFs, N1, Fs).

%% what a finding is: its kind's severity
flow_severity(unknown_procedure, error).
flow_severity(instantiation, error).
flow_severity(left_recursion, error).
flow_severity(unreachable_clause, warning).
flow_severity(discontiguous, warning).
flow_severity(defined_twice, error).
flow_severity(det_promise, warning).
flow_severity(thread_visibility, warning).
flow_severity(lock_held, warning).
flow_severity(thread_unjoined, warning).

%% ---- each panel's own findings, keyed k(Panel, Clause, Seq) -------------

flow_panel_finding(P, Src, Docs, k(I, 0, 0), F) :-
    flow_det_promise(P, Src, Docs, F),
    P = panel(I, _, _, _, _, _, _, _).
flow_panel_finding(P, _, _, k(I, C, 0), F) :-
    flow_unreachable(P, C, F),
    P = panel(I, _, _, _, _, _, _, _).
flow_panel_finding(P, _, _, K, F) :-
    flow_goal_findings(P, K, F).

flow_goal_findings(P, k(I, C, S), F) :-
    P = panel(I, Key, _, _, _, rows(Rows), _, _),
    flow_panel_id(I, PId),
    flow_pred_atom(Key, In),
    member(row(C, _, Names, _, Nodes, CI), Rows),
    atomic_list_concat([PId, '.c', C], Base),
    flow_list_goals(Nodes, Base, Gs),
    nth1(S, Gs, Id-g(G, Kind, _, _, _, Info)),
    \+ memberchk(unreached, Info),
    flow_goal_finding(Kind, G, Info, Names, Fd),
    flow_goal_where(Info, CI, Where),
    Fd = f(FK, Text, See),
    flow_severity(FK, Sev),
    F = f(FK, Sev, Id, In, Where, Text, See).

flow_goal_finding(unknown, G, Info, _, f(unknown_procedure, Text, [])) :-
    functor(G, N, A),
    flow_pred_atom(N/A, PA),
    (   memberchk(near(N2/A2), Info)
    ->  (   N2 == N
        ->  format(atom(Hint), ' (~q/~w is defined)', [N2, A2])
        ;   format(atom(Hint), '; did you mean ~q/~w?', [N2, A2])
        )
    ;   Hint = ''
    ),
    format(atom(Text), '~w is defined nowhere: no clause, builtin, module or dynamic declaration answers it, so this call raises existence_error~w',
           [PA, Hint]).
flow_goal_finding(_, G, Info, Names, f(instantiation, Text, [])) :-
    memberchk(inst(_, Vs), Info),
    flow_var_list(Vs, Names, VT, Plural),
    functor(G, N, A),
    (   N == call
    ->  format(atom(Text), '~w ~w free on every path to here, so there is no goal to call: this raises an instantiation error',
               [VT, Plural])
    ;   flow_evaluates(N, A, _)
    ->  flow_pred_atom(N/A, PA),
        (   Plural == is -> It = it ; It = them ),
        format(atom(Text), '~w ~w free on every path to here, and ~w evaluates ~w: this call raises an instantiation error',
               [VT, Plural, PA, It])
    ;   flow_pred_atom(N/A, PA),
        (   Plural == is -> It = it ; It = 'them all' ),
        format(atom(Text), '~w ~w free on every path to here, and ~w will not take ~w unbound: this call raises an error',
               [VT, Plural, PA, It])
    ).

%% where a goal stands: its own place, in its clause's file
flow_goal_where(Info, CI, Where) :-
    (   memberchk(file(F), CI) -> true ; F = none ),
    (   memberchk(at(L, K), Info) -> Where = where(F, L, K)
    ;   memberchk(at(L, K), CI) -> Where = where(F, L, K)
    ;   Where = none
    ).

flow_clause_where(CI, Where) :-
    (   memberchk(file(F), CI) -> true ; F = none ),
    (   memberchk(at(L, K), CI) -> Where = where(F, L, K) ; Where = none ).

%% `Y', `Y and Z', `A, B and C' -- by the names the source gives them
flow_var_list(Vs, Names, Text, Verb) :-
    findall(Nm, ( member(V, Vs), ( flow_var_name(V, Names, Nm0) -> Nm = Nm0 ; Nm = '_' ) ), Ns),
    (   Ns = [One] -> Text = One, Verb = is
    ;   append(Init, [Last], Ns),
        atomic_list_concat(Init, ', ', IT),
        format(atom(Text), '~w and ~w', [IT, Last]),
        Verb = are
    ).

flow_pred_atom(N/A, PA) :- format(atom(PA), '~q/~w', [N, A]).

%% ---- every goal of a list, with the XML's id, in document order ---------

flow_list_goals(Ns, Base, Gs) :-
    flow_list_goals_(Ns, Base, 1, Gs, []).

flow_list_goals_([], _, _, Gs, Gs).
flow_list_goals_([N|Ns], Base, K, Gs0, Gs) :-
    atomic_list_concat([Base, '.g', K], Id),
    flow_node_goals(N, Id, Gs0, Gs1),
    K1 is K + 1,
    flow_list_goals_(Ns, Base, K1, Gs1, Gs).

flow_node_goals(N, Id, [Id-N|Gs], Gs) :- N = g(_, _, _, _, _, _), !.
flow_node_goals(ite(_, Arms, Else), Id, Gs0, Gs) :- !,
    flow_arms_goals(Arms, 1, Id, Gs0, Gs1),
    (   Else == none -> Gs1 = Gs
    ;   atom_concat(Id, '.else', EId), flow_list_goals_(Else, EId, 1, Gs1, Gs)
    ).
flow_node_goals(or(Bs), Id, Gs0, Gs) :- !,
    flow_branches_goals(Bs, 1, Id, Gs0, Gs).
flow_node_goals(not(Ns), Id, Gs0, Gs) :- !,
    flow_list_goals_(Ns, Id, 1, Gs0, Gs).
flow_node_goals(meta(_, _, _, Ts, _), Id, Gs0, Gs) :- !,
    (   Ts = [Ns] -> flow_list_goals_(Ns, Id, 1, Gs0, Gs) ; Gs = Gs0 ).
flow_node_goals(catchc(G, _, R), Id, Gs0, Gs) :- !,
    atom_concat(Id, '.try', TId),
    atom_concat(Id, '.recover', RId),
    flow_list_goals_(G, TId, 1, Gs0, Gs1),
    flow_list_goals_(R, RId, 1, Gs1, Gs).
flow_node_goals(_, _, Gs, Gs).

flow_arms_goals([], _, _, Gs, Gs).
flow_arms_goals([arm(C, T)|As], K, Id, Gs0, Gs) :-
    atomic_list_concat([Id, '.a', K], AId),
    atom_concat(AId, '.if', CId),
    flow_list_goals_(C, CId, 1, Gs0, Gs1),
    flow_list_goals_(T, AId, 1, Gs1, Gs2),
    K1 is K + 1,
    flow_arms_goals(As, K1, Id, Gs2, Gs).

flow_branches_goals([], _, _, Gs, Gs).
flow_branches_goals([B|Bs], K, Id, Gs0, Gs) :-
    atomic_list_concat([Id, '.b', K], BId),
    flow_list_goals_(B, BId, 1, Gs0, Gs1),
    K1 is K + 1,
    flow_branches_goals(Bs, K1, Id, Gs1, Gs).

%% ---- a near name, for a call nothing answers ----------------------------
%%
%% The same name at another arity first -- the commonest slip -- then a name
%% one edit away at the same arity (two for a name of eight letters or
%% more), among the program's own predicates, the engine's builtins and the
%% libraries' predicates. The analysis asks it of an unknown goal, where the
%% program is at hand, and the node carries near(Name/Arity).
%%
%% KEPT ONCE A CHART: the analysis asks it of every unknown goal at every
%% analysis of the goal's pair, and the answer depends on the name and
%% arity alone while the program stays the chart's. Each search walks every
%% name the program, the engine and the libraries know -- some 3,700 -- and
%% through 1.10.27 a file that calls into siblings it does not load spent
%% most of its chart in it (cicili-lang's ccl_cpp.pl, 8,764 lines: see
%% STATUS.md). flow_graph/3 starts a generation, and an answer of another
%% generation is asked again.
flow_near_name(N, A, Prog, Near) :-
    (   catch(nb_getval('$flow_near_gen', G), _, fail)
    ->  atomic_list_concat(['$flow_near|', N, '/', A], K),
        (   catch(nb_getval(K, gen(G0, V0)), _, fail), G0 == G
        ->  V = V0
        ;   ( flow_near_name_(N, A, Prog, Near0) -> V = near(Near0) ; V = none ),
            nb_setval(K, gen(G, V))
        ),
        V = near(Near)
    ;   flow_near_name_(N, A, Prog, Near)
    ).

flow_near_gen :-
    (   catch(nb_getval('$flow_near_gen', G0), _, fail) -> G is G0 + 1 ; G = 1 ),
    nb_setval('$flow_near_gen', G).

flow_near_name_(N, A, Prog, Near) :-
    assoc_to_keys(Prog, Keys),
    (   ( member(N/A2, Keys) ; flow_lib_pred(N, A2) ), A2 =\= A
    ->  Near = N/A2
    ;   atom_length(N, Len), Len >= 4,
        ( Len >= 8 -> Max = 2 ; Max = 1 ),
        atom_codes(N, Cs),
        findall(D-N2, ( ( member(N2/A, Keys) ; flow_lib_pred(N2, A) ), N2 \== N,
                        atom(N2), atom_length(N2, L2), abs(L2 - Len) =< Max,
                        atom_codes(N2, Cs2), flow_near_dist(Cs, Cs2, D), D =< Max ), DNs),
        DNs \== []
    ->  keysort(DNs, [_-Best|_]),
        Near = Best/A
    ).

%% a predicate the engine or a library answers
flow_lib_pred(N, A) :- flow_t_c(N, A, _).
flow_lib_pred(N, A) :- flow_t_lib(N, A, _, _).
flow_lib_pred(N, A) :- flow_t_portal(_, N, A, _, _, _, _, _).

%% two letters swapped -- lenght for length -- is one slip, not two edits
flow_near_dist(Xs, Ys, D) :-
    (   flow_swapped(Xs, Ys) -> D = 1 ; flow_edits(Xs, Ys, D) ).

flow_swapped([A, B|T], [B, A|T]) :- A =\= B, !.
flow_swapped([A|T1], [A|T2]) :- flow_swapped(T1, T2).

%% edit distance, one row at a time
flow_edits(Xs, Ys, D) :-
    length(Ys, LY),
    numlist(0, LY, Row0),
    flow_edit_rows(Xs, Ys, 1, Row0, Row),
    last(Row, D).

flow_edit_rows([], _, _, Row, Row).
flow_edit_rows([X|Xs], Ys, I, Prev, Row) :-
    flow_edit_row(Ys, X, Prev, I, Next),
    I1 is I + 1,
    flow_edit_rows(Xs, Ys, I1, Next, Row).

flow_edit_row(Ys, X, [P0|Ps], I, [I|Row]) :-
    flow_edit_cells(Ys, X, P0, Ps, I, Row).

flow_edit_cells([], _, _, _, _, []).
flow_edit_cells([Y|Ys], X, Diag, [Up|Ups], Left, [C|Cs]) :-
    (   X =:= Y -> Cost = 0 ; Cost = 1 ),
    C is min(min(Up + 1, Left + 1), Diag + Cost),
    flow_edit_cells(Ys, X, Up, Ups, C, Cs).

%% ---- a clause never reached ----------------------------------------------
%%
%% Clause J's head matches every call of this pattern and every goal before
%% its first cut succeeds: the cut is always reached, and no clause after J
%% is ever tried.

flow_unreachable(panel(I, Key, _, CM, _, rows(Rows), _, _), C,
                 f(unreachable_clause, warning, At, In, Where, Text, See)) :-
    append(Before, [row(J, _, _, false, Nodes, _)|After], Rows),
    After = [row(C, _, _, _, _, CI)|_],
    append(Pre, [cut|_], Nodes),
    \+ memberchk(cut, Pre),
    forall(member(N, Pre), flow_node_total(N)),
    \+ ( member(row(_, _, _, false, Ns0, _), Before), flow_always_cuts(Ns0) ),
    !,
    flow_panel_id(I, PId),
    atomic_list_concat([PId, '.c', C], At),
    flow_pred_atom(Key, In),
    flow_clause_where(CI, Where),
    length(Pre, NPre),
    K is NPre + 1,
    atomic_list_concat([PId, '.c', J, '.g', K], CutId),
    findall(Id, ( member(row(C2, _, _, _, _, _), After), C2 =\= C,
                  atomic_list_concat([PId, '.c', C2], Id) ), Others),
    length(After, NA),
    flow_call_pattern(Key, CM, Pat),
    (   NA =:= 1
    ->  format(atom(Text), 'clause ~d of ~w is never tried for ~w: clause ~d matches every such call and cuts before anything in it can fail',
               [C, In, Pat, J])
    ;   last(After, row(CL, _, _, _, _, _)),
        format(atom(Text), 'clauses ~d to ~d of ~w are never tried for ~w: clause ~d matches every such call and cuts before anything in it can fail',
               [C, CL, In, Pat, J])
    ),
    See = [CutId|Others].

flow_always_cuts(Nodes) :-
    append(Pre, [cut|_], Nodes),
    \+ memberchk(cut, Pre),
    forall(member(N, Pre), flow_node_total(N)).

%% first(+, -), the call pattern a panel stands for
flow_call_pattern(N/_, CM, Pat) :-
    atomic_list_concat(CM, ', ', MA),
    format(atom(Pat), '~q(~w)', [N, MA]).

%% ---- a determinism promise the code does not keep ------------------------
%%
%% `%! first(+L, -X) is det.' promises det for calls whose `+' arguments
%% are bound and whose `-' ones are free; a panel of that call pattern the
%% analysis calls semidet, nondet or never-succeeding breaks it -- and so
%% does a nondet one, against semidet. The goals that break it are named.

flow_det_promise(panel(I, Key, user, CM, _, rows(Rows), Det, _), Src, Docs,
                 f(det_promise, warning, PId, In, where(Src, Line, 1), Text, See)) :-
    get_assoc(Key, Docs, sig(DMs, _, promise(PDet, Line))),
    flow_promise_applies(DMs, CM),
    flow_promise_broken(PDet, Det, How),
    flow_panel_id(I, PId),
    flow_pred_atom(Key, In),
    flow_promise_why(How, PId, Rows, Why, See),
    format(atom(Text), '~w is documented as ~w (line ~d) but ~w', [In, PDet, Line, Why]).

flow_promise_applies([], []).
flow_promise_applies([D|Ds], [M|Ms]) :-
    (   D == '+' -> M == '+'
    ;   D == '-' -> M == '-'
    ;   true
    ),
    flow_promise_applies(Ds, Ms).

flow_promise_broken(det, semidet, fails).
flow_promise_broken(det, nondet, choice).
flow_promise_broken(det, failure, never).
flow_promise_broken(semidet, nondet, choice).

%% why, and where: the goals that leave the choice or can fail
flow_promise_why(never, PId, Rows, 'never succeeds: no clause gets to its end', See) :-
    findall(Id, ( member(row(C, _, _, _, _, _), Rows), atomic_list_concat([PId, '.c', C], Id) ), See).
flow_promise_why(choice, PId, Rows, Why, See) :-
    (   flow_late_choice_goal(Rows, PId, Id, Node, Names)
    ->  flow_node_text(Node, Names, T),
        format(atom(Why), 'can leave a choice point: ~w can answer again', [T]),
        See = [Id]
    ;   findall(Id, ( member(row(C, _, _, _, _, _), Rows), atomic_list_concat([PId, '.c', C], Id) ), See),
        flow_rows_numbers(Rows, CNs),
        format(atom(Why), 'can leave a choice point: clauses ~w can each match a call', [CNs])
    ).
flow_promise_why(fails, PId, Rows, Why, See) :-
    last(Rows, row(CL, _, _, HF, _, _)),
    (   flow_failing_goal(Rows, PId, Id, Node, Names)
    ->  flow_node_text(Node, Names, T),
        format(atom(Why), 'can fail: when ~w fails, so does the whole call', [T]),
        See = [Id]
    ;   HF == true
    ->  atomic_list_concat([PId, '.c', CL], Id),
        format(atom(Why), 'can fail: a call that no clause head matches fails, clause ~d''s included', [CL]),
        See = [Id]
    ;   findall(Id, ( member(row(C, _, _, _, _, _), Rows), atomic_list_concat([PId, '.c', C], Id) ), See),
        Why = 'can fail'
    ).

flow_rows_numbers(Rows, A) :-
    findall(C, member(row(C, _, _, _, _, _), Rows), Cs),
    atomic_list_concat(Cs, ', ', A).

%% a top-level item after a clause's last cut that can leave a choice
flow_late_choice_goal(Rows, PId, Id, N, Names) :-
    member(row(C, _, Names, _, Nodes, _), Rows),
    flow_after_last_cut(Nodes, 1, K0, After),
    nth0(J, After, N),
    flow_node_nondet(N), !,
    K is K0 + J,
    atomic_list_concat([PId, '.c', C, '.g', K], Id).

%% a top-level item that can fail where no clause takes over: anywhere in
%% the last clause, or after the cut of an earlier one
flow_failing_goal(Rows, PId, Id, N, Names) :-
    append(_, [row(C, _, Names, _, Nodes, _)], Rows),
    nth1(K, Nodes, N),
    N \== cut,
    \+ flow_node_total(N), !,
    atomic_list_concat([PId, '.c', C, '.g', K], Id).
flow_failing_goal(Rows, PId, Id, N, Names) :-
    member(row(C, _, Names, _, Nodes, _), Rows),
    memberchk(cut, Nodes),
    flow_after_last_cut(Nodes, 1, K0, After),
    nth0(J, After, N),
    \+ flow_node_total(N), !,
    K is K0 + J,
    atomic_list_concat([PId, '.c', C, '.g', K], Id).

%% how an item reads in a sentence: a goal or a meta-call by its text, a
%% construct by what it is
flow_node_text(g(G, _, _, _, _, _), Names, T) :- !, flow_term_full(G, Names, 1200, T).
flow_node_text(meta(_, H, _, _, _), Names, T) :- !, flow_term_full(H, Names, 1200, T).
flow_node_text(ite(_, _, _), _, 'the if-then-else') :- !.
flow_node_text(or(_), _, 'the disjunction') :- !.
flow_node_text(not(_), _, 'the negation') :- !.
flow_node_text(catchc(_, _, _), _, 'the catch/3') :- !.
flow_node_text(failn, _, fail) :- !.
flow_node_text(_, _, 'a goal').

%% the goals after the last top-level cut, and the number of the first
flow_after_last_cut(Nodes, K0, K, After) :-
    (   append(Pre, [cut|Rest], Nodes), \+ memberchk(cut, Rest)
    ->  length(Pre, NP), K is K0 + NP + 1, After = Rest
    ;   K = K0, After = Nodes
    ).

%% ---- left recursion -------------------------------------------------------
%%
%% A clause's FIRST CALL -- past cuts, tests and unifications that only pass
%% a variable on -- is a left edge to the panel it calls, and it CARRIES the
%% inputs when each input argument of the call is one of the clause's own
%% input variables, unchanged. A cycle of carrying edges that comes back to
%% a panel with its inputs as they were (each input in some input's place)
%% calls the same thing again with nothing gained, so the search for its
%% answers never ends, before the first or after the last: for a grammar,
%% the list it reads is the one it was given -- it calls itself before
%% reading anything. With NOTHING bound it is a loop only when no clause can
%% succeed: size(L, N) of free L and N is a generator, lists of every length,
%% as length/2 is. Reported once, at the cycle's first panel.

%% The edges are kept by the panel they leave (Es: P -> its edges): a walk
%% asks each panel's edges by its number. Through 1.10.27 every step of
%% every walk scanned every edge, and a root that calls each of a file's
%% 1,521 predicates spent 50 s and 335 M inferences here (cicili-lang's
%% ccl_cpp.pl; 6,682 panels).
flow_left_recursion(Own, Ids, KFs) :-
    findall(P-e(P, Q, Map, GId, CI), ( member(Pn, Own), flow_left_edge(Pn, Ids, P, Q, Map, GId, CI) ), PEs0),
    keysort(PEs0, PEs),
    flow_group(PEs, Grouped),
    list_to_assoc(Grouped, Es),
    findall(K-F, ( member(panel(P, _, _, _, _, _, _, _), Own),
                   get_assoc(P, Es, _),
                   flow_lr_cycle(P, Es, Own, K, F) ), KFs).

flow_lr_edges(X, Es, XEs) :-
    (   get_assoc(X, Es, XEs0) -> XEs = XEs0 ; XEs = [] ).

flow_left_edge(panel(P, _, _, CM, _, rows(Rows), _, _), Ids, P, Q, Map, GId, CI) :-
    flow_panel_lane(Ids, P, L),
    member(row(C, H, _, _, Nodes, CI), Rows),
    H =.. [_|HArgs],
    flow_lr_inputs(HArgs, CM, 1, Alias0),
    flow_lr_walk(Nodes, 1, Alias0, K, g(G, Kind, Ms, _, Key2, _), Alias),
    flow_panel_key(Kind, Key2, Ms, PK),
    get_assoc(L-PK, Ids, Q),
    G =.. [_|GArgs],
    flow_lr_map(GArgs, Ms, 1, Alias, Map),
    flow_panel_id(P, PId),
    atomic_list_concat([PId, '.c', C, '.g', K], GId).

%% the clause's own input variables, each with the place it came in at
flow_lr_inputs([], [], _, []).
flow_lr_inputs([A|As], [M|Ms], I, Alias) :-
    (   M \== '-', var(A) -> Alias = [A-I|Alias1] ; Alias = Alias1 ),
    I1 is I + 1,
    flow_lr_inputs(As, Ms, I1, Alias1).

%% to the first call, past what changes nothing it was given; KG is the
%% call's place in the clause, as the XML numbers it
flow_lr_walk([N|Ns], K, Alias0, KG, G, Alias) :-
    (   N == cut
    ->  K1 is K + 1, flow_lr_walk(Ns, K1, Alias0, KG, G, Alias)
    ;   N = g(_, test, _, _, _, _)
    ->  K1 is K + 1, flow_lr_walk(Ns, K1, Alias0, KG, G, Alias)
    ;   N = g(X = Y, unify, _, _, _, _)
    ->  flow_lr_unify(X, Y, Alias0, Alias1),
        K1 is K + 1, flow_lr_walk(Ns, K1, Alias1, KG, G, Alias)
    ;   N = g(_, Kind, _, _, _, _), memberchk(Kind, [user, dynamic])
    ->  KG = K, G = N, Alias = Alias0
    ).

%% X = Y with one side an input and the other a variable not yet seen
%% passes the input on; one that touches no input changes none; anything
%% else stops the walk
flow_lr_unify(X, Y, Alias0, Alias) :-
    (   var(X), var(Y), flow_lr_pos(X, Alias0, I), \+ flow_lr_pos(Y, Alias0, _)
    ->  Alias = [Y-I|Alias0]
    ;   var(X), var(Y), flow_lr_pos(Y, Alias0, I), \+ flow_lr_pos(X, Alias0, _)
    ->  Alias = [X-I|Alias0]
    ;   term_variables(X-Y, Vs), \+ ( member(V, Vs), flow_lr_pos(V, Alias0, _) )
    ->  Alias = Alias0
    ).

flow_lr_pos(V, [W-I|Ws], P) :-
    (   V == W -> P = I ; flow_lr_pos(V, Ws, P) ).

%% each input place of the call, from the clause input it carries; a call
%% with an input the clause made itself carries nothing
flow_lr_map([], [], _, _, []).
flow_lr_map([A|As], [M|Ms], J, Alias, Map) :-
    (   M == '-'
    ->  Map = Map1
    ;   var(A), flow_lr_pos(A, Alias, I)
    ->  Map = [J-I|Map1]
    ),
    J1 is J + 1,
    flow_lr_map(As, Ms, J1, Alias, Map1).

%% a cycle of carrying edges from P back to P, its inputs back in each
%% other's places, P the lowest panel on it
flow_lr_cycle(P, Es, Own, k(P, C, S), f(left_recursion, error, GId, In, Where, Text, See)) :-
    flow_lr_edges(P, Es, PEs),
    member(e(P, Q, Map0, GId, CI), PEs),
    flow_lr_path(Q, P, Map0, Es, [P], 6, Steps, MapEnd),
    \+ ( member(X-_, Steps), X < P ),
    memberchk(panel(P, Key, _, CM, _, _, Det, _), Own),
    flow_lr_inputs_of(CM, Ins),
    flow_lr_bijection(MapEnd, Ins),
    (   Ins == [] -> Det == failure ; true ),
    !,
    findall(G2, member(_-G2, Steps), See),
    flow_pred_atom(Key, In),
    findall(X, member(X-_, Steps), Xs),
    flow_lr_text(Key, CM, CI, Xs, Own, Text),
    flow_goal_place(GId, P, Own, C, S, Where).

%% from X round to P along carrying edges, composing the map from each
%% panel's input places back to P's; Steps are the edges taken, X-GoalId
flow_lr_path(P, P, Map, _, _, _, [], Map) :- !.
flow_lr_path(X, P, Map0, Es, Seen, D, [X-G|Steps], Map) :-
    D > 0,
    \+ memberchk(X, Seen),
    flow_lr_edges(X, Es, XEs),
    member(e(X, Y, M1, G, _), XEs),
    flow_lr_compose(M1, Map0, Map1),
    D1 is D - 1,
    flow_lr_path(Y, P, Map1, Es, [X|Seen], D1, Steps, Map).

%% M1 maps the callee's places to X's; Map0 maps X's places to P's
flow_lr_compose([], _, []).
flow_lr_compose([J-I|M1], Map0, [J-O|Map]) :-
    memberchk(I-O, Map0),
    flow_lr_compose(M1, Map0, Map).

flow_lr_inputs_of(CM, Ins) :-
    findall(I, ( nth1(I, CM, M), M \== '-' ), Ins).

flow_lr_bijection(Map, Ins) :-
    findall(J, member(J-_, Map), Js0), msort(Js0, Js),
    findall(I, member(_-I, Map), Is0), msort(Is0, Is),
    Js == Ins, Is == Ins.

flow_lr_text(Key, CM, CI, [], _, Text) :- !,
    flow_lr_name(Key, CI, Name),
    (   memberchk(dcg, CI)
    ->  format(atom(Text), '~w calls itself before reading any input: parsing with it loops for ever', [Name])
    ;   flow_lr_inputs_of(CM, [])
    ->  format(atom(Text), '~w calls itself first, with nothing bound, and no clause of it can succeed: it repeats for ever', [Name])
    ;   format(atom(Text), '~w calls itself first, with the inputs it was given: once this clause is reached it repeats for ever', [Name])
    ).
flow_lr_text(Key, _, CI, Xs, Own, Text) :-
    flow_lr_name(Key, CI, Name),
    findall(N2, ( member(X, Xs), memberchk(panel(X, K2, _, _, _, rows([row(_, _, _, _, _, CI2)|_]), _, _), Own),
                  flow_lr_name(K2, CI2, N2) ), Ns),
    append([Name|Ns], [Name], Chain0),
    atomic_list_concat(Chain0, ' -> ', Chain),
    (   memberchk(dcg, CI)
    ->  format(atom(Text), '~w reaches itself again before reading any input (~w): parsing with it loops for ever', [Name, Chain])
    ;   format(atom(Text), '~w reaches itself again first, with the inputs it was given (~w): once this clause is reached it repeats for ever', [Name, Chain])
    ).

%% where a goal of the program stands, and its place among its clause's
%% goals in document order
flow_goal_place(GId, P, Own, C, S, Where) :-
    memberchk(panel(P, _, _, _, _, rows(Rows), _, _), Own),
    flow_panel_id(P, PId),
    member(row(C, _, _, _, Nodes, CI), Rows),
    atomic_list_concat([PId, '.c', C], Base),
    flow_list_goals(Nodes, Base, Gs),
    nth1(S, Gs, GId-g(_, _, _, _, _, Info)), !,
    flow_goal_where(Info, CI, Where).

%% a grammar rule by its nonterminal: expr//1
flow_lr_name(N/A, CI, Name) :-
    (   memberchk(dcg, CI), A >= 2
    ->  A2 is A - 2, format(atom(Name), '~q//~w', [N, A2])
    ;   format(atom(Name), '~q/~w', [N, A])
    ).

%% ======================================================================
%% Threads (F2): what is seen where, a lock kept, a thread let go
%% ======================================================================

flow_thread_findings(Mine, Panels, Ids, KFs) :-
    flow_graph_link_rows(Ids, LRs),
    findall(K-F, ( member(lr(I, _, Row), LRs), flow_mine(I, Mine, P),
                   flow_unjoined(P, Row, Panels, K, F) ), K1),
    findall(K-F, ( member(lr(I, _, Row), LRs), flow_mine(I, Mine, P),
                   flow_lock_held(P, Row, Panels, K, F) ), K2),
    findall(K-F, flow_unseen_write(Panels, Ids, K, F), K3),
    append([K1, K2, K3], KFs).

%% the panel of that id, when it is one the findings look at
flow_mine(I, Mine, P) :-
    P = panel(I, _, _, _, _, _, _, _),
    memberchk(P, Mine).

%% thread_create(G, Id) with Id named nowhere else: in the clause's head,
%% or any other goal of it
flow_unjoined(P, Row, Panels, k(I, C, S), f(thread_unjoined, warning, GId, In, Where, Text, [])) :-
    P = panel(I, Key, _, _, _, _, _, _),
    Row = row(C, H, _, _, Nodes, _),
    flow_nodes_has(spawn, Nodes),
    flow_panel_id(I, PId),
    atomic_list_concat([PId, '.c', C], Base),
    flow_list_sites(Nodes, Base, Ss),
    member(GId-g(thread_create(_, Id), spawn(thread), _, _, _, Info), Ss),
    \+ memberchk(unreached, Info),
    var(Id),
    \+ ( H \== none, term_variables(H, HVs), flow_var_in(Id, HVs) ),
    \+ ( member(OId-N, Ss), OId \== GId, flow_site_term(N, T),
          term_variables(T, TVs), flow_var_in(Id, TVs) ),
    flow_pred_atom(Key, In),
    flow_goal_place(GId, I, Panels, C, S, Where),
    Text = 'the thread started here is neither joined nor detached: when it ends it keeps its slot, one of 256, and its pthread until the process does -- thread_join/2 reads its status, thread_detach/1 lets it clean up after itself'.

%% what a site holds, to look for a variable in
flow_site_term(g(G, _, _, _, _, _), G).
flow_site_term(meta(_, H, _, _, _), H).

%% mutex_lock(M), then a goal that can fail, then mutex_unlock(M): all in
%% the clause's own line
flow_lock_held(P, Row, Panels, k(I, C, S), f(lock_held, warning, GId, In, Where, Text, [FId])) :-
    P = panel(I, Key, _, _, _, _, _, _),
    Row = row(C, _, Names, _, Nodes, _),
    memberchk(g(_, conc(lock(lock, _)), _, _, _, _), Nodes),
    flow_panel_id(I, PId),
    atomic_list_concat([PId, '.c', C], Base),
    flow_x_index(Nodes, Base, 1, Indexed),
    append(_, [GId-g(LG, conc(lock(lock, M)), _, _, _, Info)|After], Indexed),
    \+ memberchk(unreached, Info),
    once(( append(Between, [_-g(_, conc(lock(unlock, M2)), _, _, _, _)|_], After),
           flow_same_handle(M, M2) )),
    once(( member(FId-FN, Between), \+ flow_node_total(FN) )),
    flow_pred_atom(Key, In),
    flow_goal_place(GId, I, Panels, C, S, Where),
    flow_term_full(LG, Names, 999, LT),
    flow_handle_name(M, Names, MN),
    (   FN = g(FG, _, _, _, _, _) -> flow_term_full(FG, Names, 999, FT) ; FT = 'the construct after it' ),
    format(atom(Text), '~w is not released on every way out: when ~w fails, the clause leaves holding the lock, and the next mutex_lock(~w) waits for ever -- with_mutex(~w, Goal) releases it on success, on failure and on an exception alike',
           [LT, FT, MN, MN]).

flow_same_handle(A, B) :-
    (   var(A) -> A == B ; A == B ).

%% a dynamic predicate called in a lane that does not write it, where
%% another lane does: the lane's store never sees those writes
flow_unseen_write(Panels, Ids, k(I, C, S), f(thread_visibility, warning, GId, In, Where, Text, [WId])) :-
    flow_graph_links(Ids, links(_, _, _, _, _, Writes)),
    Writes \== [],
    member(P, Panels),
    P = panel(I, Key, _, _, _, rows(Rows), _, _),
    flow_panel_lane(Ids, I, L),
    L > 0,
    flow_panel_id(I, PId),
    member(row(C, _, _, _, Nodes, _), Rows),
    atomic_list_concat([PId, '.c', C], Base),
    flow_list_goals(Nodes, Base, Gs),
    member(GId-g(_, dynamic, _, _, DKey, Info), Gs),
    \+ memberchk(unreached, Info),
    \+ ( member(write(W0, _, DKey), Writes), flow_site_panel(W0, WP0), flow_panel_lane(Ids, WP0, L) ),
    once(( member(write(WId, Op, DKey), Writes),
           flow_site_panel(WId, WP),
           flow_panel_lane(Ids, WP, WL),
           WL =\= L )),
    flow_pred_atom(Key, In),
    flow_goal_place(GId, I, Panels, C, S, Where),
    flow_pred_atom(DKey, DA),
    flow_graph_lanes(Ids, Lanes),
    memberchk(lane(L, Type, _, _, _, _, _, _), Lanes),
    flow_lane_word(Type, LW),
    flow_lane_store(Type, Store),
    format(atom(Text), '~w is written in lane l~w (~w/1 at ~w), and this goal runs in lane l~w, ~w: ~w',
           [DA, WL, Op, WId, L, LW, Store]).

%% what a lane's store starts with (modules/thread): a thread has no
%% connection; run_isolated/2, and so an httpd worker's request, has one
%% of its own, a turn that sees what was committed when it began
flow_lane_store(Type, Text) :-
    (   memberchk(Type, [isolated, httpd])
    ->  Text = 'its proof has a connection of its own, and its store holds the modules'' clauses and, under --kb or --embed, what was committed when it began -- never a write of a turn still running -- so it does not see that write while the turn that made it runs'
    ;   Text = 'a thread has no connection to the knowledge base, and its store starts with the clauses of the modules loaded before it and none of what was asserted, so it never sees that write'
    ).

%% ---- clauses of one predicate not together ----------------------------------
%%
%% The file is read once more for where each clause stands -- its line and
%% its predicate, a grammar rule's two arguments counted -- and for its
%% `:- discontiguous' declarations, which exempt a predicate as they do in
%% SWI. A predicate the chart has a panel for whose clauses stand in more
%% than one place has ONE finding, at the first clause that stands apart:
%% the clause of another predicate just before it, and in how many places
%% its clauses are. The first panel of a predicate speaks for it.

flow_discontiguous(Own, Src, KFs) :-
    findall(K-I, member(panel(I, K, _, _, _, _, _, _), Own), KIs0),
    keysort(KIs0, KIs),
    flow_first_panels(KIs, Firsts),
    (   Firsts == [] -> KFs = []
    ;   flow_clause_seq(Src, Seq, Decl),
        flow_clause_index(Seq, Ix),
        findall(k(I, J, 0)-F,
                ( member(K-I, Firsts),
                  get_assoc(K, Ix, Cls),
                  flow_disc_runs(K, Cls, Runs),
                  Runs = [_, _|_],
                  (   flow_twice_finding(K, I, Own, Cls, Runs, J, F)
                  ->  true
                  ;   \+ memberchk(K, Decl),
                      flow_disc_finding(K, I, Own, Runs, J, F)
                  ) ),
                KFs)
    ).

%% EVERY PREDICATE'S CLAUSES, read off the file once: Name/Arity -> its
%% clauses in file order, cl(N, Line, Before, BLine, Term) -- N its number
%% among them, Before-BLine the predicate of the clause just before it in
%% the file and that clause's line (none-0 at the top). Through 1.10.27 the
%% whole file was walked again for each predicate charted, twice: 4.7 s of
%% a chart of the 1,521 of cicili-lang's ccl_cpp.pl.
flow_clause_index(Seq, Ix) :-
    empty_assoc(N0),
    flow_clause_index_(Seq, none, 0, N0, Pairs0),
    keysort(Pairs0, Pairs),
    flow_group(Pairs, Grouped),
    list_to_assoc(Grouped, Ix).

flow_clause_index_([], _, _, _, []).
flow_clause_index_([c(L, K, T)|Seq], PK, PL, Ns0, [K-cl(N, L, PK, PL, T)|Ps]) :-
    (   get_assoc(K, Ns0, N0) -> true ; N0 = 0 ),
    N is N0 + 1,
    put_assoc(K, Ns0, N, Ns),
    flow_clause_index_(Seq, K, L, Ns, Ps).

%% each predicate with its first panel
flow_first_panels([], []).
flow_first_panels([K-I|KIs], [K-I|Fs]) :-
    flow_first_panels_skip(KIs, K, Rest),
    flow_first_panels(Rest, Fs).

flow_first_panels_skip([K1-_|KIs], K, Rest) :-
    K1 == K, !,
    flow_first_panels_skip(KIs, K, Rest).
flow_first_panels_skip(KIs, _, KIs).

flow_disc_finding(K, I, Own, Runs, J, f(discontiguous, warning, At, In, Where, Text, [Prev])) :-
    Runs = [_, run(J, Line, Other, OLine)|_],
    length(Runs, NR),
    memberchk(panel(I, K, _, _, _, rows(Rows), _, _), Own),
    memberchk(row(J, _, _, _, _, CI), Rows),
    flow_panel_id(I, PId),
    atomic_list_concat([PId, '.c', J], At),
    J0 is J - 1,
    atomic_list_concat([PId, '.c', J0], Prev),
    flow_pred_atom(K, In),
    flow_pred_atom(Other, OA),
    flow_clause_where(CI, Where),
    format(atom(Text), 'the clauses of ~w are not together: clause ~d (line ~d) comes after ~w at line ~d, and its clauses stand in ~d places; cocolog joins them without a word where SWI warns -- move them together, or declare :- discontiguous(~w)',
           [In, J, Line, OA, OLine, NR, In]).

%% ---- a predicate defined twice ------------------------------------------
%%
%% A predicate whose clauses stand in more than one place and whose later
%% place REPEATS a clause of an earlier one -- head and body the same, up to
%% the names of the variables -- or holds a clause an earlier FACT covers
%% (the fact's head is at least as general): the later place starts a
%% definition the earlier one already gave, and cocolog joins the two into
%% one predicate. That clause never answers first, and every answer it gives
%% the earlier one gave already, so on backtracking each comes again -- for
%% a recursion, at every level. An ERROR, one per predicate, at the first
%% such clause, and it speaks for the predicate's split as well: no
%% `discontiguous' warning beside it. A declaration of discontiguous does
%% not excuse it. Over cicili-lang's library (9,476 clauses) it names the
%% two its session found by hand, cpp_thunk_params/4 and cpp_param_types/2,
%% and over cocolog's own libraries tr_cap_run/3, "two predicates under one
%% name" -- and nothing else.

flow_twice_finding(K, I, Own, Cls, Runs, J, f(defined_twice, error, At, In, Where, Text, [Prev])) :-
    flow_twice_pair(Runs, Cls, I0, L0, J, L, How), !,
    memberchk(panel(I, K, _, _, _, rows(Rows), _, _), Own),
    memberchk(row(J, _, _, _, _, CI), Rows),
    flow_panel_id(I, PId),
    atomic_list_concat([PId, '.c', J], At),
    atomic_list_concat([PId, '.c', I0], Prev),
    flow_pred_atom(K, In),
    flow_clause_where(CI, Where),
    length(Runs, NR),
    (   How == repeats
    ->  format(atom(Text), '~w is defined twice: clause ~d (line ~d) repeats clause ~d (line ~d), and its clauses stand in ~d places; cocolog joins the two definitions into one predicate, so the second never answers first and every answer it gives comes again on backtracking -- keep one of them',
               [In, J, L, I0, L0, NR])
    ;   format(atom(Text), '~w is defined twice: clause ~d (line ~d) is covered by the fact at line ~d (clause ~d), and its clauses stand in ~d places; cocolog joins the two definitions into one predicate, so the clause never answers first and every answer it gives the fact gave already -- keep one of them',
               [In, J, L, L0, I0, NR])
    ).

%% a clause of a later place, and the earlier clause it repeats or the
%% earlier fact that covers it: the first such in the file. The clauses are
%% walked once, a place at a time: Seen maps the canonical form of every
%% clause of the places before -- its variables numbered in order, so two
%% clauses are the same up to renaming exactly when their forms are equal
%% -- to its number and line, and Facts holds their facts with a variable
%% in them (a ground fact covers only its own copy, which Seen finds). A
%% fact table of thousands split in two is a walk, not a product.
flow_twice_pair(Runs, Cls, I0, L0, J, L, How) :-
    findall(S, member(run(S, _, _, _), Runs), [_|Starts]),
    empty_assoc(Seen0),
    flow_twice_walk(Cls, Starts, Seen0, [], [], I0, L0, J, L, How).

flow_twice_walk([cl(N, L1, _, _, T)|Cls], Starts0, Seen0, Facts0, Pend0, I0, L0, J, L, How) :-
    (   Starts0 = [S|Starts], N >= S
    ->  flow_twice_commit(Pend0, Seen0, Seen, Facts0, Facts), Pend = []
    ;   Starts = Starts0, Seen = Seen0, Facts = Facts0, Pend = Pend0
    ),
    flow_canon(T, Key),
    (   get_assoc(Key, Seen, I1-L2)
    ->  I0 = I1, L0 = L2, J = N, L = L1, How = repeats
    ;   flow_clause_head(T, H),
        member(f(I1, L2, H0), Facts), flow_subsumes(H0, H)
    ->  I0 = I1, L0 = L2, J = N, L = L1, How = covers
    ;   flow_twice_walk(Cls, Starts, Seen, Facts, [p(Key, N, L1, T)|Pend], I0, L0, J, L, How)
    ).

%% a place ends: its clauses join Seen, the first of each form kept
flow_twice_commit(Pend, Seen0, Seen, Facts0, Facts) :-
    reverse(Pend, Ps),
    flow_twice_commit_(Ps, Seen0, Seen, Facts0, Facts).

flow_twice_commit_([], Seen, Seen, Facts, Facts).
flow_twice_commit_([p(Key, N, L, T)|Ps], Seen0, Seen, Facts0, Facts) :-
    (   get_assoc(Key, Seen0, _) -> Seen1 = Seen0 ; put_assoc(Key, Seen0, N-L, Seen1) ),
    (   flow_fact(T), \+ ground(T) -> append(Facts0, [f(N, L, T)], Facts1) ; Facts1 = Facts0 ),
    flow_twice_commit_(Ps, Seen1, Seen, Facts1, Facts).

flow_canon(T, Key) :-
    copy_term(T, Key),
    term_variables(Key, Vs),
    flow_canon_vars(Vs, 0).

flow_fact(T) :- \+ T = (_ :- _), \+ T = (_ --> _).

flow_clause_head((H :- _), H) :- !.
flow_clause_head((H --> _), H) :- !.
flow_clause_head(H, H).

%% G is at least as general as S: S's variables made distinct constants,
%% and G still unifies with it
flow_subsumes(G, S) :-
    \+ \+ ( copy_term(S, S1), term_variables(S1, Vs), flow_canon_vars(Vs, 0),
            copy_term(G, G1), G1 = S1 ).

flow_canon_vars([], _).
flow_canon_vars(['$VAR'(N)|Vs], N) :- N1 is N + 1, flow_canon_vars(Vs, N1).


%% the places K's clauses stand: run(J, Line, Before, BLine), J its first
%% clause there (counted from 1 in the file), Line its line, and the clause
%% of another predicate just before it (none-0 at the top of the file): a
%% place begins at each clause the one before which is another predicate's
flow_disc_runs(K, Cls, Runs) :-
    findall(run(N, L, B, BL), ( member(cl(N, L, B, BL, _), Cls), B \== K ), Runs).

%% every clause of the file in order, c(Line, Name/Arity, Term), and the
%% predicates it declares discontiguous
flow_clause_seq(Src, Seq, Decl) :-
    open(Src, read, S),
    catch(flow_clause_seq_(S, Seq, Decl0), _, ( Seq = [], Decl0 = [] )),
    close(S),
    sort(Decl0, Decl).

flow_clause_seq_(S, Seq, Decl) :-
    read_term(S, T, [term_position(P)]),
    (   T == end_of_file
    ->  Seq = [], Decl = []
    ;   arg(2, P, Line),
        (   nonvar(T), T = (:- D)
        ->  Seq = Seq1,
            (   nonvar(D), D = discontiguous(Spec)
            ->  flow_dynamic_keys(Spec, Ks), append(Ks, Decl1, Decl)
            ;   Decl = Decl1
            )
        ;   flow_clause_key(T, K)
        ->  Seq = [c(Line, K, T)|Seq1], Decl = Decl1
        ;   Seq = Seq1, Decl = Decl1
        ),
        flow_clause_seq_(S, Seq1, Decl1)
    ).

flow_clause_key(T, _) :- var(T), !, fail.
flow_clause_key((H0 --> _), N/A) :- !,
    (   nonvar(H0), H0 = (H1, _) -> H = H1 ; H = H0 ),
    callable(H), functor(H, N, A0), A is A0 + 2.
flow_clause_key((H :- _), N/A) :- !,
    callable(H), functor(H, N, A).
flow_clause_key(H, N/A) :-
    callable(H), functor(H, N, A).
