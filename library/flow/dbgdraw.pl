%% library(flow/debug), part: the run drawn over the chart, and its XML.
%%
%% What both documents say is worked out ONCE, from the calls dbgmatch.pl
%% placed (flow_dbg_facts/6), so the picture and the XML cannot disagree:
%%
%%   * each BOX the window reached: how many calls it saw, and the last one
%%     -- its inference and how it went: exit, fail, open (still running
%%     when the window closed) or redo (being tried again then);
%%   * each clause HEAD a call tried: how often, and whether the last try
%%     entered the clause or did not unify;
%%   * the PANELS a call entered;
%%   * the BINDINGS: where a value crossed into a variable the source names
%%     -- given at a Call, made by an Exit, undone by a Redo -- found by
%%     reading the argument's text back and unifying it with the argument
%%     as the source wrote it, so `foo([X|Xs])' names X and Xs; an argument
%%     cut at text(N) is a value only where the source wrote a plain
%%     variable. A value a call is given that the same clause activation
%%     already showed is not shown again. The last discs(N) are numbered;
%%   * how the run ended, its window, the last goal to fail, the last
%%     exception, and whether the replay ended where the probe did;
%%   * with a journal, its entries, and the calls of the window the replay
%%     answered from it rather than ran.
%%
%%     flow_dbg_facts(+Graph, +Run, +Calls, +Names, +Opts, -Facts)
%%     flow_dbg_svg(+Graph, +Findings, +Facts, +Opts, -Svg)
%%     flow_dbg_xml(+Graph, +Findings, +Facts, -Xml)
%%     flow_dbg_out(+Facts, -Run)        the run as flow_debug/4 hands it back
%%
%% THE PICTURE, view(flow): the chart as library(flow/chart) draws it, under
%% a banner that says how the run ended and what was recorded; every box
%% the window reached drawn heavy, red where its last call failed, and the
%% boxes it did not reach faded; a head red where its last try did not
%% unify; a panel no call entered faded with the wires into it; a disc on
%% the box for each numbered binding -- blue given at a call, green made at
%% an exit, hollow undone at a redo -- and under the chart a line for each.
%% view(tree) draws the calls instead, a row each, a call inside another
%% indented under it, and a recursion more than seven deep shown by its
%% first three levels and its last three.
%%
%% A REPLAY THAT DID NOT END WHERE THE PROBE DID is drawn all the same --
%% it is a true recording of a run of the program -- under a red line that
%% says both ends: something the program read changed between the runs
%% (the time, a file, the knowledge base). With a journal, a box whose
%% calls the journal answered carries a teal ⇄ (with a count, more than
%% one), the banner says how many calls the journal held, and a replay
%% that left the journal is stopped where it did, under a red line that
%% names the journal's call there and the replay's.

%% ======================================================================
%% The facts
%% ======================================================================
%%
%% dbg(Sum, Events, Calls, Boxes, Heads, Entered, Bindings, Discs, Goals)
%%
%% Events: ev(I, Port, S, Depth, What, Args), each event with its call's
%% inference S in place of the goal's cell -- What the predicate's name
%% (call, exit, fail, redo), the clause's number (clause, nohead), the ball
%% (throw) or none (catch). Bindings: x(I, Port, S, Name, Value, Box, Act).
%% Goals: S -> gi(Box, Goal, Names, Act), the source goal at each call's
%% box and the names of its clause's variables; Act names the activation
%% the box ran in, its caller and its clause.

flow_dbg_facts(graph(_, _, Panels, _, _), Run, Calls0, Names, Opts,
               dbg(Sum, SEs, Calls, Boxes, Heads, Entered, Xs, Discs, Goals)) :-
    Run = run(Goal, _, _, _, Events, _),
    flow_dbg_serial(Events, SEs),
    flow_dbg_thrown(SEs, Calls0, Calls, Throws),
    flow_dbg_box_states(Calls, Boxes),
    flow_dbg_head_states(Calls, Heads),
    flow_dbg_entered(Calls, Entered),
    flow_dbg_call_goals(Calls, Panels, Goal, Names, Goals),
    flow_dbg_crossings(SEs, Goals, Xs),
    flow_option(discs(ND), Opts, 24),
    flow_dbg_discs(Xs, ND, Discs),
    flow_option(text(TM), Opts, 60),
    flow_why_own_opt(Opts, Own),
    flow_dbg_summary(Run, Names, Calls, SEs, Throws, TM, Own, Sum).

%% AN EXCEPTION ENDS CALLS WITH NO PORT: the call that raised it (the last
%% one made in the body the throw was recorded in) and every call it
%% unwinds -- that body's and its callers', up to the one whose body holds
%% the catch/3 that took it, or all of them when nothing did -- are no
%% longer running, so a fate of open or redo becomes raised or unwound.
%% Throws: th(I, S, Ball, Raiser), Raiser 0 when no call raised it (a
%% throw/1 of the program's own): the raiser is the last call made in that
%% body only while it runs -- through 1.11.4 one that had exited was named
flow_dbg_thrown(SEs, Calls0, Calls, Throws) :-
    findall(S-P, member(call(S, _, _, P, _, _, _, _, _, _), Calls0), SP),
    list_to_assoc(SP, Parents),
    flow_dbg_throws(SEs, Parents, none, Throws, Marks),
    (   Marks == []
    ->  Calls = Calls0
    ;   findall(C-F, ( member(m(K, C0, Stop), Marks), flow_dbg_unwound(K, C0, Stop, Parents, C, F) ), CF),
        flow_dbg_first_marks(CF, Fates),
        findall(C1, ( member(C, Calls0), flow_dbg_refate(C, Fates, C1) ), Calls)
    ).

%% walking the events: the last call made, and at each throw its raiser
%% and the catch that follows it (the next event, when one took it)
flow_dbg_throws([], _, _, [], []).
flow_dbg_throws([ev(I, throw, S, _, B, _)|Es], Parents, Last, [th(I, S, B, R)|Ts],
                [m(raised, R, Stop), m(unwound, S, Stop)|Ms]) :- !,
    (   Last = c(R0, P), S =\= 0, P =:= S -> R = R0 ; R = 0 ),
    (   Es = [ev(_, catch, S2, _, _, _)|_] -> Stop = S2 ; Stop = 0 ),
    flow_dbg_throws(Es, Parents, Last, Ts, Ms).
flow_dbg_throws([ev(I, call, I, _, _, _)|Es], Parents, Last, Ts, Ms) :- !,
    (   get_assoc(I, Parents, P) -> Last1 = c(I, P) ; Last1 = Last ),
    flow_dbg_throws(Es, Parents, Last1, Ts, Ms).
flow_dbg_throws([ev(_, Port, S, _, _, _)|Es], Parents, Last, Ts, Ms) :-
    memberchk(Port, [exit, fail, redo]), !,
    (   Port == redo, get_assoc(S, Parents, P) -> Last1 = c(S, P)
    ;   Last = c(S, _) -> Last1 = none
    ;   Last1 = Last
    ),
    flow_dbg_throws(Es, Parents, Last1, Ts, Ms).
flow_dbg_throws([_|Es], Parents, Last, Ts, Ms) :-
    flow_dbg_throws(Es, Parents, Last, Ts, Ms).

%% the calls a mark reaches: the raiser alone; or the body's own call and
%% its callers, out to the catch's body (not included)
flow_dbg_unwound(raised, C, _, _, C, raised) :- C =\= 0.
flow_dbg_unwound(unwound, C0, Stop, Parents, C, unwound) :-
    flow_dbg_up(C0, Stop, Parents, C).

flow_dbg_up(C, Stop, Parents, X) :-
    C =\= 0, C =\= Stop,
    (   X = C
    ;   get_assoc(C, Parents, P), flow_dbg_up(P, Stop, Parents, X)
    ).

%% a call keeps the first fate an exception gave it
flow_dbg_first_marks(CF, Fates) :-
    empty_assoc(F0),
    flow_dbg_first_marks_(CF, F0, Fates).

flow_dbg_first_marks_([], F, F).
flow_dbg_first_marks_([C-F|T], F0, Fs) :-
    (   get_assoc(C, F0, _) -> F1 = F0 ; put_assoc(C, F0, F, F1) ),
    flow_dbg_first_marks_(T, F1, Fs).

flow_dbg_refate(call(S, Pr, D, P, B, Pn, Cl, In, Out, Fate), Fates, call(S, Pr, D, P, B, Pn, Cl, In, Out, Fate1)) :-
    (   memberchk(Fate, [open, redo]), get_assoc(S, Fates, F) -> Fate1 = F ; Fate1 = Fate ).

%% the events with a call's inference for its cell: an Exit, a Fail, a
%% Redo, a clause or a head is about the latest Call of its cell (one the
%% window did not see is dropped); a throw or a catch about the call whose
%% body it is in, 0 when that began before the window
flow_dbg_serial(Events, SEs) :-
    empty_assoc(C0),
    flow_dbg_serial_(Events, C0, SEs).

flow_dbg_serial_([], _, []).
flow_dbg_serial_([E|Es], C0, Out) :-
    flow_dbg_ev(E, C0, C1, X),
    (   X == none -> Out = Out1 ; Out = [X|Out1] ),
    flow_dbg_serial_(Es, C1, Out1).

flow_dbg_ev(call(I, D, C, _, N, As), C0, C1, ev(I, call, I, D, N, As)) :- !,
    put_assoc(C, C0, I, C1).
flow_dbg_ev(exit(I, D, C, N, As), C0, C0, X) :- !, flow_dbg_ev_known(C, C0, ev(I, exit, _, D, N, As), X).
flow_dbg_ev(fail(I, D, C, N, As), C0, C0, X) :- !, flow_dbg_ev_known(C, C0, ev(I, fail, _, D, N, As), X).
flow_dbg_ev(redo(I, D, C, N, As), C0, C0, X) :- !, flow_dbg_ev_known(C, C0, ev(I, redo, _, D, N, As), X).
flow_dbg_ev(clause(I, D, C, K), C0, C0, X) :- !, flow_dbg_ev_known(C, C0, ev(I, clause, _, D, K, []), X).
flow_dbg_ev(nohead(I, D, C, K), C0, C0, X) :- !, flow_dbg_ev_known(C, C0, ev(I, nohead, _, D, K, []), X).
flow_dbg_ev(throw(I, D, C, B), C0, C0, ev(I, throw, S, D, B, [])) :- !, flow_dbg_ev_of(C, C0, S).
flow_dbg_ev(catch(I, D, C), C0, C0, ev(I, catch, S, D, none, [])) :- !, flow_dbg_ev_of(C, C0, S).
flow_dbg_ev(_, C, C, none).

flow_dbg_ev_known(C, Cells, X0, X) :-
    (   get_assoc(C, Cells, S) -> flow_dbg_with_s(X0, S, X) ; X = none ).

flow_dbg_with_s(ev(I, P, _, D, W, As), S, ev(I, P, S, D, W, As)).

flow_dbg_ev_of(C, Cells, S) :-
    (   get_assoc(C, Cells, S0) -> S = S0 ; S = 0 ).

%% each box: bs(N, LastS, LastFate, NFailed); the calls come in order
flow_dbg_box_states(Calls, Boxes) :-
    empty_assoc(B0),
    flow_dbg_box_states_(Calls, B0, Boxes).

flow_dbg_box_states_([], B, B).
flow_dbg_box_states_([call(S, _, _, _, Box, _, Cl, _, _, Fate)|Cs], B0, B) :-
    flow_dbg_box_state(Box, S, Fate, B0, B1),
    %% a throw/1 the call's body made: its box raised (1.11.7)
    findall(TB-TA, member(thrown(TB, TA), Cl), Ths),
    flow_dbg_box_throws(Ths, B1, B2),
    flow_dbg_box_states_(Cs, B2, B).

flow_dbg_box_state(none, _, _, B, B) :- !.
flow_dbg_box_state(Box, S, Fate, B0, B) :-
    (   get_assoc(Box, B0, bs(N0, _, _, F0)) -> true ; N0 = 0, F0 = 0 ),
    N is N0 + 1,
    (   Fate == fail -> F is F0 + 1 ; F = F0 ),
    put_assoc(Box, B0, bs(N, S, Fate, F), B).

flow_dbg_box_throws([], B, B).
flow_dbg_box_throws([TB-TA|Ts], B0, B) :-
    flow_dbg_box_state(TB, TA, raised, B0, B1),
    flow_dbg_box_throws(Ts, B1, B).

%% each head tried: hs(N, LastAt, LastKind, NEntered), Kind entered or
%% nohead, in the order of the inferences they were tried at
flow_dbg_head_states(Calls, Heads) :-
    findall(At-(H-K), ( member(call(_, _, _, _, _, P, Cl, _, _, _), Calls), P \== none,
                        member(X, Cl), flow_dbg_head_ev(X, P, H, K, At) ),
            L0),
    keysort(L0, L1),
    empty_assoc(H0),
    flow_dbg_head_states_(L1, H0, Heads).

flow_dbg_head_ev(c(N, At), P, H, entered, At) :- atomic_list_concat([P, '.c', N, '.h'], H).
flow_dbg_head_ev(nohead(N, At), P, H, nohead, At) :- atomic_list_concat([P, '.c', N, '.h'], H).

flow_dbg_head_states_([], H, H).
flow_dbg_head_states_([At-(H-K)|T], H0, Hs) :-
    (   get_assoc(H, H0, hs(N0, _, _, E0)) -> true ; N0 = 0, E0 = 0 ),
    N is N0 + 1,
    (   K == entered -> E is E0 + 1 ; E = E0 ),
    put_assoc(H, H0, hs(N, At, K, E), H1),
    flow_dbg_head_states_(T, H1, Hs).

flow_dbg_entered(Calls, Entered) :-
    findall(P-true, ( member(call(_, _, _, _, _, P, _, _, _, _), Calls), P \== none ), Ps0),
    sort(Ps0, Ps),
    list_to_assoc(Ps, Entered).

%% the source goal at each call's box, with its clause's names: the
%% query's own goal is the goal flow_debug/3 was given, named by names(...)
flow_dbg_call_goals(Calls, Panels, QGoal, QNames, Goals) :-
    findall(S-gi(Box, G, Ns, P-Pre),
            ( member(call(S, _, _, P, Box, _, _, _, _, _), Calls), Box \== none,
              flow_dbg_box_goal(Box, Panels, QGoal, QNames, G, Ns, Pre) ),
            L),
    list_to_assoc(L, Goals).

flow_dbg_box_goal('query.g1', _, QGoal, QNames, QGoal, QNames, query) :- !.
flow_dbg_box_goal(Box, Panels, _, _, G, Ns, Pre) :-
    atomic_list_concat([PA, CA|_], '.', Box),
    atom_concat(p, NA, PA), atom_number(NA, N),
    atom_concat(c, KA, CA), atom_number(KA, K),
    memberchk(panel(N, _, _, _, _, rows(Rows), _, _), Panels),
    memberchk(row(K, _, Ns, _, Nodes, _), Rows),
    atomic_list_concat([PA, '.', CA], Pre),
    flow_dbg_find(Nodes, Pre, Box, Node),
    flow_dbg_node_goal(Node, G).

flow_dbg_node_goal(g(G, _, _, _, _, _), G).
flow_dbg_node_goal(meta(_, Head, _, _, _), Head).

%% ---- the bindings -------------------------------------------------------

flow_dbg_crossings(SEs, Goals, Xs) :-
    empty_assoc(V0),
    flow_dbg_cross(SEs, Goals, V0, Xs0),
    empty_assoc(A0),
    flow_dbg_dedupe(Xs0, A0, Xs).

%% per call: vals(AtCall, AtExit), the named values at its latest Call or
%% Redo and at its latest Exit (none)
flow_dbg_cross([], _, _, []).
flow_dbg_cross([ev(I, Port, S, _, _, As)|Es], Goals, V0, Xs) :-
    (   memberchk(Port, [call, exit, redo, fail]),
        get_assoc(S, Goals, gi(Box, G, Ns, Act)),
        flow_dbg_var_values(G, Ns, As, Vals)
    ->  flow_dbg_cross_at(Port, I, S, Box, Act, Vals, V0, V1, X1)
    ;   V1 = V0, X1 = []
    ),
    append(X1, Xs1, Xs),
    flow_dbg_cross(Es, Goals, V1, Xs1).

flow_dbg_cross_at(call, I, S, Box, Act, Vals, V0, V1, Xs) :-
    put_assoc(S, V0, vals(Vals, none), V1),
    findall(x(I, call, S, Nm, Val, Box, Act), ( member(Nm-Val, Vals), Val \== unbound ), Xs).
flow_dbg_cross_at(exit, I, S, Box, Act, Vals, V0, V1, Xs) :-
    (   get_assoc(S, V0, vals(B, _)) -> true ; B = [] ),
    put_assoc(S, V0, vals(B, Vals), V1),
    findall(x(I, exit, S, Nm, Val, Box, Act),
            ( member(Nm-Val, Vals), Val \== unbound, \+ ( memberchk(Nm-BV, B), BV == Val ) ),
            Xs).
%% a Redo of a call that has exited undoes what the Exit bound, and so
%% does its Fail when backtracking finally leaves it; a Redo of a call
%% still running (its body taking another arm: a `;', an else, the way
%% out of a failed \+) undoes nothing the call itself was given
flow_dbg_cross_at(Port, I, S, Box, Act, Vals, V0, V1, Xs) :-
    memberchk(Port, [redo, fail]),
    (   get_assoc(S, V0, vals(_, E)), E \== none
    ->  put_assoc(S, V0, vals(Vals, none), V1),
        findall(x(I, Port, S, Nm, EV, Box, Act),
                ( member(Nm-EV, E), EV \== unbound, \+ ( memberchk(Nm-RV, Vals), RV == EV ) ),
                Xs)
    ;   V1 = V0,
        Xs = []
    ).

%% a value the same activation already showed, given to a later call, is
%% no new crossing; a value undone is shown again when it comes back
flow_dbg_dedupe([], _, []).
flow_dbg_dedupe([X|Xs], A0, Out) :-
    X = x(_, Port, _, Nm, Val, _, Act),
    (   Port == call, get_assoc(Act-Nm, A0, V0), V0 == Val
    ->  Out = Out1, A1 = A0
    ;   Out = [X|Out1],
        (   memberchk(Port, [redo, fail]) -> put_assoc(Act-Nm, A0, undone, A1) ; put_assoc(Act-Nm, A0, Val, A1) )
    ),
    flow_dbg_dedupe(Xs, A1, Out1).

%% the value of each named variable of a goal, from the texts of its
%% arguments at one port: Name-Text, Name-cut(Prefix, Length) or
%% Name-unbound, each name once, in the order the arguments name them
flow_dbg_var_values(G, Ns, Texts, Vals) :-
    compound(G),
    G =.. [_|SArgs],
    length(SArgs, N),
    length(Texts, N),
    flow_dbg_arg_values(SArgs, Texts, Ns, [], Vals).

flow_dbg_arg_values([], [], _, Acc, Vals) :-
    reverse(Acc, Vals).
flow_dbg_arg_values([SA|SAs], [T|Ts], Ns, Acc0, Vals) :-
    term_variables(SA, Vs),
    flow_dbg_name_each(Vs, Ns, Named),
    (   Named \== [], flow_dbg_arg_bind(SA, Named, T, Pairs)
    ->  flow_dbg_acc(Pairs, Acc0, Acc1)
    ;   Acc1 = Acc0
    ),
    flow_dbg_arg_values(SAs, Ts, Ns, Acc1, Vals).

%% the variables the source names, each with ITS name (a walk, not a
%% findall: the pairs must hold the argument's own variables)
flow_dbg_name_each([], _, []).
flow_dbg_name_each([V|Vs], Ns, Out) :-
    (   flow_var_name(V, Ns, Nm) -> Out = [Nm-V|Out1] ; Out = Out1 ),
    flow_dbg_name_each(Vs, Ns, Out1).

flow_dbg_arg_bind(SA, Named, cut(P, L), [Nm-cut(P1, L)]) :- !,
    var(SA),
    Named = [Nm-_],
    flow_dbg_ung(P, P1).
flow_dbg_arg_bind(SA, Named, T, Pairs) :-
    atom(T),
    catch(term_to_atom(V, T), _, fail),
    copy_term(SA-Named, SA1-Named1),
    SA1 = V,
    flow_dbg_val_texts(Named1, Pairs).

flow_dbg_val_texts([], []).
flow_dbg_val_texts([Nm-V|T], [Nm-X|R]) :-
    (   var(V) -> X = unbound
    ;   format(atom(X0), '~q', [V]), flow_dbg_ung(X0, X)
    ),
    flow_dbg_val_texts(T, R).

flow_dbg_acc([], A, A).
flow_dbg_acc([Nm-V|T], A0, A) :-
    (   memberchk(Nm-_, A0) -> A1 = A0 ; A1 = [Nm-V|A0] ),
    flow_dbg_acc(T, A1, A).

%% `_G123', a variable's name in one process, is `_' on the picture
flow_dbg_ung(A, B) :-
    atom_codes(A, Cs),
    (   append(_, [0'_, 0'G|_], Cs)
    ->  flow_dbg_ung_(Cs, Ds), atom_codes(B, Ds)
    ;   B = A
    ).

flow_dbg_ung_([], []).
flow_dbg_ung_([0'_, 0'G, D|Cs], [0'_|Rs]) :-
    D >= 0'0, D =< 0'9, !,
    flow_dbg_digits(Cs, Cs1),
    flow_dbg_ung_(Cs1, Rs).
flow_dbg_ung_([C|Cs], [C|Rs]) :-
    flow_dbg_ung_(Cs, Rs).

flow_dbg_digits([D|Cs], R) :- D >= 0'0, D =< 0'9, !, flow_dbg_digits(Cs, R).
flow_dbg_digits(Cs, Cs).

%% the last N bindings, numbered from 1
flow_dbg_discs(Xs, N, Discs) :-
    length(Xs, L),
    Skip is max(0, L - N),
    flow_dbg_drop(Skip, Xs, Last),
    flow_dbg_number(Last, 1, Discs).

flow_dbg_drop(0, L, L) :- !.
flow_dbg_drop(K, [_|T], R) :-
    K1 is K - 1,
    flow_dbg_drop(K1, T, R).

flow_dbg_number([], _, []).
flow_dbg_number([X|Xs], K, [d(K, X)|Ds]) :-
    K1 is K + 1,
    flow_dbg_number(Xs, K1, Ds).

%% ---- how it ended -------------------------------------------------------
%%
%% sum(Goal, Names, Replay, Probe, From, To, Whole, Diverged, NCalls,
%%     LastFail, LastThrow, Journal, Own)
%%
%% Journal none, or jr(Entries, Answered, JBoxes, JCalls, TM): the probe's
%% entries, how many of them the replay answered, each box -> how many of
%% its calls in the window were answered, each such call's inference -> its
%% entry, and text(N)'s length, which the XML cuts an entry's values at.
%% Own whose calls the why explains (own(...), dbgwhy.pl)

flow_dbg_summary(run(Goal, Probe, Replay, window(F, T), _, Journal), Names, Calls, SEs, Throws, TM, Own,
                 sum(Goal, Names, Replay, Probe, F, T, Whole, Div, NC, LastFail, Throw, Jr, Own)) :-
    Probe = end(_, PU, _),
    (   F =:= 1, T >= PU -> Whole = true ; Whole = false ),
    flow_dbg_diverged(Probe, Replay, T, Div),
    length(Calls, NC),
    Replay = end(How, _, _),
    flow_dbg_last_fail(How, SEs, Calls, LastFail),
    (   last(Throws, Th) -> Throw = Th ; Throw = none ),
    flow_dbg_journal(Journal, Replay, Calls, TM, Jr).

%% THE CALLS THE JOURNAL ANSWERED: an entry is the call made at its
%% inference, and the replay answered every entry up to where it ended --
%% or, where it left the journal at inference I, every entry before I. A
%% portal call is often a library's own (open/3 reaches the world through
%% '$stream_open'/4), so the box it counts for is its nearest caller's
%% that has one: what the program's goal did came from the journal
flow_dbg_journal(none, _, _, _, none) :- !.
flow_dbg_journal(journal(Es), end(How, RU, _), Calls, TM, jr(Es, NA, JBoxes, JCalls, TM)) :-
    (   How = diverged(At, _, _) -> Lim is At - 1 ; Lim = RU ),
    findall(I-E, ( member(E, Es), E = j(I, _, _, _, _), I =< Lim ), IE),
    length(IE, NA),
    list_to_assoc(IE, ByI),
    findall(S-E, ( member(call(S, _, _, _, _, _, _, _, _, _), Calls), get_assoc(S, ByI, E) ), SE),
    list_to_assoc(SE, JCalls),
    findall(S-(P-B), member(call(S, _, _, P, B, _, _, _, _, _), Calls), SPB),
    list_to_assoc(SPB, Up),
    findall(B, ( member(S-_, SE), flow_dbg_boxed_up(S, Up, B) ), Bs0),
    msort(Bs0, Bs),
    flow_dbg_tally(Bs, BN),
    list_to_assoc(BN, JBoxes).

%% the box of a call, or of its nearest caller the window saw that has one
%% -- a box of the chart: a place in a clause the chart does not draw
%% (`#', dbgmatch.pl) has none to mark
flow_dbg_boxed_up(S, Up, B) :-
    get_assoc(S, Up, P-B0),
    (   B0 \== none, \+ sub_atom(B0, _, _, _, '#') -> B = B0
    ;   P =\= 0, flow_dbg_boxed_up(P, Up, B)
    ).

%% a sorted list as each element -> how many times it is there
flow_dbg_tally([], []).
flow_dbg_tally([X|Xs], [X-N|T]) :-
    flow_dbg_tally_run(Xs, X, 1, N, Rest),
    flow_dbg_tally(Rest, T).

flow_dbg_tally_run([Y|Ys], X, N0, N, Rest) :-
    Y == X, !,
    N1 is N0 + 1,
    flow_dbg_tally_run(Ys, X, N1, N, Rest).
flow_dbg_tally_run(Rest, _, N, N, Rest).

%% the replay must end as the probe did: at the probe's end, the same way
%% and with the same answers; short of it (to(J)), at the window's end
flow_dbg_diverged(Probe, Replay, T, Div) :-
    Probe = end(PH, PU, PA),
    Replay = end(RH, RU, RA),
    (   T < PU
    ->  (   RH == limit, RU =:= T -> Div = false ; Div = diverged(Probe, Replay) )
    ;   flow_dbg_how_word(PH, PW),
        flow_dbg_how_word(RH, RW),
        (   PW == RW, PU =:= RU, PA == RA -> Div = false ; Div = diverged(Probe, Replay) )
    ).

flow_dbg_how_word(exception(_), exception) :- !.
flow_dbg_how_word(halt(_), halt) :- !.
flow_dbg_how_word(error(_), error) :- !.
flow_dbg_how_word(diverged(_, _, _), diverged) :- !.
flow_dbg_how_word(H, H).

%% A RUN THAT FAILED fails its query last, so the goal worth naming is
%% where the failure began: the first goal to fail after the last call the
%% run made, the first of those that is a box of the chart (a library
%% predicate's inner calls are not); from(I, S, Pred, Box, Panel, In). In
%% any other run, the last goal to fail: lf(...), or none
flow_dbg_last_fail(false, SEs, Calls, R) :-
    reverse(SEs, Rev),
    flow_dbg_until_call(Rev, [], Tail),
    findall(I-S, member(ev(I, fail, S, _, _, _), Tail), Fs),
    (   member(I-S, Fs),
        memberchk(call(S, Pred, _, _, Box, Panel, _, In, _, _), Calls), Box \== none
    ->  R = from(I, S, Pred, Box, Panel, In)
    ;   Fs = [I-S|_],
        memberchk(call(S, Pred, _, _, Box, Panel, _, In, _, _), Calls)
    ->  R = from(I, S, Pred, Box, Panel, In)
    ;   fail
    ), !.
flow_dbg_last_fail(_, SEs, Calls, R) :-
    findall(I-S, member(ev(I, fail, S, _, _, _), SEs), L),
    (   last(L, I-S),
        memberchk(call(S, Pred, _, _, Box, Panel, _, In, _, _), Calls)
    ->  R = lf(I, S, Pred, Box, Panel, In)
    ;   R = none
    ).

%% the events after the last Call, in order
flow_dbg_until_call([], Acc, Acc).
flow_dbg_until_call([E|Es], Acc, Tail) :-
    (   E = ev(_, call, _, _, _, _) -> Tail = Acc ; flow_dbg_until_call(Es, [E|Acc], Tail) ).

%% the run as flow_debug/4 hands it back
flow_dbg_out(dbg(Sum, _, Calls, _, _, _, Xs, _, _),
             run(How, At, Answers, window(F, T), Calls, Bindings, Div, Journal)) :-
    Sum = sum(_, _, end(How, At, Answers), _, F, T, _, Div, _, _, _, Jr, _),
    findall(x(I, P, S, Nm, V, Box), member(x(I, P, S, Nm, V, Box, _), Xs), Bindings),
    (   Jr = jr(Es, _, _, _, _) -> Journal = journal(Es) ; Journal = none ).

%% ======================================================================
%% The picture
%% ======================================================================

flow_dbg_svg(Graph, Fs, Facts, Opts, Svg) :-
    flow_option(view(View), Opts, flow),
    (   View == tree
    ->  flow_dbg_tree(Facts, CW, CH, Els)
    ;   flow_dbg_flow(Graph, Fs, Facts, Opts, CW, CH, Els)
    ),
    flow_defs(Defs),
    format(atom(VB), '0 0 ~w ~w', [CW, CH]),
    flow_font(sans, Sans),
    Svg = element(svg, [xmlns='http://www.w3.org/2000/svg', width=CW, height=CH, viewBox=VB,
                        'font-family'=Sans],
                  [Defs, element(rect, [x=0, y=0, width=CW, height=CH, fill='#ffffff'], [])|Els]).

%% the chart, under the banner and over the run's own section
flow_dbg_flow(Graph, Fs, Facts, Opts, CW, CH, Els) :-
    flow_prune(Graph, Opts, Graph1, Note),
    flow_layout(Graph1, Note, Fs, canvas(CW0, CH0, Items)),
    flow_dbg_frames(Items, Frames),
    flow_dbg_items(Items, Frames, Facts, ChartEls),
    flow_dbg_banner(Facts, BannerPs, BH),
    flow_dbg_section(Facts, CW0, SecPs, SH),
    flow_lines_w(BannerPs, BW),
    flow_lines_w(SecPs, SW),
    CW is max(CW0, max(BW, SW) + 32),
    CH is BH + CH0 + SH,
    flow_dbg_els(BannerPs, BEs),
    flow_dbg_els(SecPs, SEs),
    format(atom(T1), 'translate(0,~w)', [BH]),
    Y2 is BH + CH0,
    format(atom(T2), 'translate(0,~w)', [Y2]),
    Els = [element(g, [id=run_banner], BEs),
           element(g, [transform=T1], ChartEls),
           element(g, [id=run_section, transform=T2], SEs)].

%% each panel's place and size, for the wires that come into it
flow_dbg_frames(Items, Frames) :-
    findall(fr(PId, X, Y, W, H), ( member(tr(X, Y, Ps, PId), Items),
                                   memberchk(r(0, 0, W, H, 8, _, _, _, _), Ps) ),
            Frames).

flow_dbg_items([], _, _, []).
flow_dbg_items([I|Is], Frames, Facts, Els) :-
    (   flow_dbg_item(I, Frames, Facts, E) -> Els = [E|Els1] ; Els = Els1 ),
    flow_dbg_items(Is, Frames, Facts, Els1).

flow_dbg_item(tr(X, Y, Ps, PId), _, Facts, element(g, As, Es)) :- !,
    format(atom(T), 'translate(~w,~w)', [X, Y]),
    (   flow_dbg_entered_panel(PId, Facts) -> As = [id=PId, transform=T]
    ;   As = [id=PId, transform=T, opacity='0.4']
    ),
    flow_dbg_prims(Ps, Facts, Ps1),
    flow_dbg_els(Ps1, Es0),
    flow_dbg_panel_discs(PId, Ps, Facts, DPs),
    flow_els(DPs, DEs),
    append(Es0, DEs, Es).
flow_dbg_item(l(Pts, Col, SW, Dash, Mk), Frames, Facts, E) :- !,
    flow_els([l(Pts, Col, SW, Dash, Mk)], [element(path, As0, K)]),
    (   flow_dbg_wire_target(Pts, Frames, PId), \+ flow_dbg_entered_panel(PId, Facts)
    ->  E = element(path, [opacity='0.25'|As0], K)
    ;   E = element(path, As0, K)
    ).
flow_dbg_item(I, _, _, E) :-
    flow_els([I], [E]).

%% the query's panel is where the run is, whatever the window saw
flow_dbg_entered_panel(query, _) :- !.
flow_dbg_entered_panel(PId, dbg(_, _, _, _, _, Entered, _, _, _)) :-
    get_assoc(PId, Entered, _).

%% the panel a wire comes into: either end on a panel's left border
flow_dbg_wire_target(Pts, Frames, PId) :-
    Pts = [X0-Y0|_],
    last(Pts, X1-Y1),
    (   flow_dbg_on_left(X1, Y1, Frames, PId) -> true
    ;   flow_dbg_on_left(X0, Y0, Frames, PId)
    ).

flow_dbg_on_left(X, Y, Frames, PId) :-
    member(fr(PId, FX, FY, _, FH), Frames),
    X =:= FX, Y >= FY, Y =< FY + FH, !.

%% a box and a head, restyled by what the window saw; dim(P) is drawn faded
flow_dbg_prims([], _, []).
flow_dbg_prims([P|Ps], Facts, [Q|Qs]) :-
    flow_dbg_prim(P, Facts, Q),
    flow_dbg_prims(Ps, Facts, Qs).

flow_dbg_prim(grp(tip(Tip, Id), Inner), Facts, Q) :-
    atom_concat(_, '.h', Id), !,
    Facts = dbg(_, _, _, _, Heads, _, _, _, _),
    (   get_assoc(Id, Heads, hs(N, At, Kind, NE))
    ->  flow_dbg_restyle(Inner, Kind, Inner1),
        flow_dbg_head_tip(Tip, N, At, Kind, NE, Tip1),
        Q = grp(tip(Tip1, Id), Inner1)
    ;   Q = dim(grp(tip(Tip, Id), Inner))
    ).
flow_dbg_prim(grp(tip(Tip, Id), Inner), Facts, Q) :-
    sub_atom(Id, _, _, _, '.g'), !,
    Facts = dbg(Sum, _, _, Boxes, _, _, _, _, _),
    (   get_assoc(Id, Boxes, bs(N, S, Fate, NF))
    ->  flow_dbg_fate_kind(Fate, Kind),
        flow_dbg_restyle(Inner, Kind, Inner1),
        flow_dbg_count_mark(Inner, N, NF, Mark),
        arg(12, Sum, Jr),
        flow_dbg_journal_mark(Jr, Id, Inner, JMark, NJ),
        append([Inner1, Mark, JMark], Inner2),
        flow_dbg_box_tip(Tip, N, S, Fate, NF, Tip0),
        flow_dbg_journal_tip(NJ, N, Tip0, Tip1),
        Q = grp(tip(Tip1, Id), Inner2)
    ;   Q = dim(grp(tip(Tip, Id), Inner))
    ).
flow_dbg_prim(P, _, P).

flow_dbg_restyle([S|R], Kind, [S1|R]) :-
    flow_dbg_shape(S, Kind, S1), !.
flow_dbg_restyle(I, _, I).

flow_dbg_shape(r(X, Y, W, H, Rx, Fill, _, _, _), Kind, r(X, Y, W, H, Rx, F, St, 2.6, none)) :-
    flow_dbg_paint(Kind, Fill, F, St).
flow_dbg_shape(pg(Pts, Fill, _, _), Kind, pg(Pts, F, St, 2.6)) :-
    flow_dbg_paint(Kind, Fill, F, St).

flow_dbg_fate_kind(fail, failed) :- !.
flow_dbg_fate_kind(raised, raised) :- !.
flow_dbg_fate_kind(unwound, unwound) :- !.
flow_dbg_fate_kind(_, reached).

flow_dbg_paint(reached, Fill, Fill, '#1f2933').
flow_dbg_paint(entered, Fill, Fill, '#3730a3').
flow_dbg_paint(failed, _, '#fff1f1', '#d62828').
flow_dbg_paint(nohead, _, '#fff1f1', '#d62828').
flow_dbg_paint(raised, _, '#f7f0ff', '#7e22ce').
flow_dbg_paint(unwound, Fill, Fill, '#7e22ce').

%% how many calls a box saw, over its top right corner, when more than one
flow_dbg_count_mark([S|_], N, NF, [t(XR, TY, end, 9, sans, bold, [s(A, Col)])]) :-
    N > 1,
    flow_dbg_bbox(S, X, Y, W, _), !,
    XR is X + W,
    TY is Y - 3,
    (   NF > 0 -> format(atom(A), '×~d, ~d failed', [N, NF]), Col = red
    ;   format(atom(A), '×~d', [N]), Col = ink
    ).
flow_dbg_count_mark(_, _, _, []).

%% a box whose calls reached the world through the journal: a teal ⇄ over
%% its top left corner, with how many portal calls when more than one; NJ
%% is how many, or 0
flow_dbg_journal_mark(jr(_, _, JBoxes, _, _), Id, [S|_], [t(X, TY, start, 9, sans, bold, [s(A, teal)])], NJ) :-
    get_assoc(Id, JBoxes, NJ),
    flow_dbg_bbox(S, X, Y, _, _), !,
    TY is Y - 3,
    (   NJ > 1 -> format(atom(A), '⇄ ×~d', [NJ]) ; A = '⇄' ).
flow_dbg_journal_mark(_, _, _, [], 0).

flow_dbg_journal_tip(0, _, Tip, Tip) :- !.
flow_dbg_journal_tip(NJ, _, Tip0, Tip) :-
    (   NJ =:= 1 -> W = 'it reached the world once, answered from the journal and not run'
    ;   format(atom(W), 'it reached the world ~d times, each answered from the journal and none run', [NJ])
    ),
    format(atom(Tip), '~w; ~w', [Tip0, W]).

flow_dbg_bbox(r(X, Y, W, H, _, _, _, _, _), X, Y, W, H).
flow_dbg_bbox(pg([X-_, _-T, _, XR-_, _-B|_], _, _, _), X, T, W, H) :-
    W is XR - X,
    H is B - T.

flow_dbg_box_tip(Tip, N, S, Fate, NF, Tip1) :-
    flow_dbg_fate_word(Fate, FW),
    (   N =:= 1
    ->  format(atom(R), 'in the window: called once, at inference ~d, and it ~w', [S, FW])
    ;   format(atom(R), 'in the window: called ~d times, ~d of them failed; the last, at inference ~d, ~w',
               [N, NF, S, FW])
    ),
    format(atom(Tip1), '~w  --  ~w', [Tip, R]).

flow_dbg_fate_word(exit, 'exited').
flow_dbg_fate_word(fail, 'failed').
flow_dbg_fate_word(open, 'was still running when the window closed').
flow_dbg_fate_word(redo, 'was being tried again when the window closed').
flow_dbg_fate_word(raised, 'raised an exception').
flow_dbg_fate_word(unwound, 'was ended by an exception raised inside it').

flow_dbg_head_tip(Tip, N, At, Kind, NE, Tip1) :-
    (   Kind == entered -> K = 'the clause was entered' ; K = 'it did not unify' ),
    format(atom(Tip1), '~w  --  in the window: tried ~d times, entered ~d; the last, at inference ~d: ~w',
           [Tip, N, NE, At, K]).

%% the numbered bindings of a panel's boxes, on the box's bottom edge, left
%% to right, a second row when a box has more than its width holds; a box
%% with more than two rows' worth shows the last of them, after a `+N' for
%% the earlier ones (the list under the chart has every disc)
flow_dbg_panel_discs(PId, Ps, dbg(_, _, _, _, _, _, _, Discs, _), DPs) :-
    findall(Box, ( member(d(_, x(_, _, _, _, _, Box, _)), Discs), flow_in_panel(Box, PId) ), Bs0),
    sort(Bs0, Bs),
    findall(P, ( member(Box, Bs),
                 findall(K-X, ( member(d(K, X), Discs), X = x(_, _, _, _, _, Box, _) ), Mine),
                 flow_dbg_box_discs(Box, Mine, Ps, BPs),
                 member(P, BPs) ),
            DPs).

flow_dbg_box_discs(Box, Mine, Ps, Out) :-
    (   flow_dbg_box_geo(Ps, Box, BX, BY, BW, BH)
    ->  PerRow is max(2, (BW - 4) // 17),
        Cap is 2 * PerRow,
        length(Mine, N),
        (   N > Cap
        ->  Keep is Cap - 1,
            Skip is N - Keep,
            flow_dbg_drop(Skip, Mine, Shown),
            format(atom(More), '+~d', [Skip]),
            MX is BX + 10,
            MCY is BY + BH,
            RX is MX - 8, RY is MCY - 8, TY is MCY + 3,
            format(atom(MTip), '~d earlier bindings here: the list under the chart has them', [Skip]),
            Lead = [grp(MTip, [r(RX, RY, 16, 16, 8, '#ffffff', '#8a97a5', 1, none),
                               t(MX, TY, middle, 7, sans, bold, [s(More, muted)])])],
            J0 = 1
        ;   Shown = Mine, Lead = [], J0 = 0
        ),
        flow_dbg_disc_row(Shown, J0, PerRow, BX, BY, BH, DPs),
        append(Lead, DPs, Out)
    ;   Out = []
    ).

flow_dbg_disc_row([], _, _, _, _, _, []).
flow_dbg_disc_row([K-X|T], J, PerRow, BX, BY, BH, [DP|DPs]) :-
    Col is J mod PerRow,
    Row is J // PerRow,
    CX is BX + 10 + 17 * Col,
    CY is BY + BH + 17 * Row,
    flow_dbg_disc(K, X, CX, CY, DP),
    J1 is J + 1,
    flow_dbg_disc_row(T, J1, PerRow, BX, BY, BH, DPs).

%% a box's place: its own shape, or for a construct with ports of its own
%% (findall/3), the smallest construct frame round its first goal
flow_dbg_box_geo(Ps, Box, X, Y, W, H) :-
    memberchk(grp(tip(_, Box), [S|_]), Ps), !,
    flow_dbg_bbox(S, X, Y, W, H).
flow_dbg_box_geo(Ps, Box, X, Y, W, H) :-
    atom_concat(Box, '.g1', Inner),
    memberchk(grp(tip(_, Inner), [S|_]), Ps),
    flow_dbg_bbox(S, IX, IY, _, _),
    findall(A-f(FX, FY, FW, FH), ( member(r(FX, FY, FW, FH, 7, '#f5f7fa', _, _, _), Ps),
                                   FX =< IX, FY =< IY, IX =< FX + FW, IY =< FY + FH,
                                   A is FW * FH ),
            Fr),
    msort(Fr, [_-f(X, Y, W, H)|_]).

flow_dbg_disc(K, x(I, Port, _, Nm, Val, _, _), CX, CY, grp(tip(Tip, DId), [C, T])) :-
    number_codes(K, KC),
    atom_codes(KA, KC),
    atom_concat(d, KA, DId),
    flow_dbg_disc_paint(Port, Fill, Stroke, TCol),
    C = c(CX, CY, 8, Fill, Stroke, 1.5),
    TY is CY + 3,
    T = t(CX, TY, middle, 9, sans, bold, [s(KA, TCol)]),
    flow_dbg_val_short(Val, 80, VT),
    flow_dbg_port_word(Port, PW),
    format(atom(Tip), '~w  --  ~w = ~w: ~w, at inference ~d', [KA, Nm, VT, PW, I]).

flow_dbg_disc_paint(call, '#1d4ed8', white, white).
flow_dbg_disc_paint(exit, '#15803d', white, white).
flow_dbg_disc_paint(redo, white, '#b45309', '#b45309').
flow_dbg_disc_paint(fail, white, '#b45309', '#b45309').

flow_dbg_port_word(call, 'given at the call').
flow_dbg_port_word(exit, 'bound at the exit').
flow_dbg_port_word(redo, 'undone at the redo').
flow_dbg_port_word(fail, 'undone as the call failed').

flow_dbg_val_short(cut(P, L), _, T) :- !,
    format(atom(T), '~w… (~d characters)', [P, L]).
flow_dbg_val_short(V, Max, T) :-
    flow_clip(V, Max, T).

flow_dbg_els([], []).
flow_dbg_els([dim(P)|Ps], [E|Es]) :- !,
    flow_els([P], Es0),
    (   Es0 = [element(g, As, K)] -> append(As, [opacity='0.3'], As1), E = element(g, As1, K)
    ;   E = element(g, [opacity='0.3'], Es0)
    ),
    flow_dbg_els(Ps, Es).
flow_dbg_els([P|Ps], Els) :-
    flow_els([P], Es0),
    append(Es0, Es, Els),
    flow_dbg_els(Ps, Es).

%% ---- the banner: how the run ended, and what was recorded --------------

flow_dbg_banner(dbg(Sum, _, Calls, _, _, _, _, _, _), Ps, H) :-
    Sum = sum(Goal, Names, end(How, Used, Ats), Probe, F, T, Whole, Div, NC, LastFail, Throw, Jr, _),
    flow_term_full(Goal, Names, 999, GT0),
    flow_clip(GT0, 90, GT),
    flow_dbg_end_text(How, Used, Ats, ET, Col),
    L1 = t(24, 30, start, 15, sans, bold, [s('the run of  ', muted), s(GT, ink), s('   ', ink), s(ET, Col)]),
    Probe = end(_, PU, _),
    flow_dbg_window_text(F, T, PU, Whole, NC, WT),
    flow_dbg_fail_text(LastFail, Throw, Calls, FT),
    flow_dbg_journal_text(Jr, JSegs),
    L2 = t(24, 50, start, 11, sans, normal, [s(WT, muted), s(FT, muted)|JSegs]),
    (   Div = diverged(end(PH, PU1, _), end(RH, RU, _))
    ->  flow_dbg_div_text(PH, PU1, RH, RU, Jr, DT),
        Ps = [L1, L2, t(24, 68, start, 11, sans, bold, [s(DT, red)])],
        H = 86
    ;   Ps = [L1, L2],
        H = 66
    ).

%% what the journal held, and how much of it the replay was answered from
flow_dbg_journal_text(none, []) :- !.
flow_dbg_journal_text(jr(Es, NA, _, _, _), [s(JT, teal)]) :-
    length(Es, N),
    (   NA =:= N
    ->  format(atom(JT), '  ·  ⇄ a journal of ~d portal calls, each answered from it in the replay', [N])
    ;   format(atom(JT), '  ·  ⇄ a journal of ~d portal calls, ~d of them answered from it in the replay', [N, NA])
    ).

%% a replay that left its journal says where and with what; one that ended
%% elsewhere says both ends
flow_dbg_div_text(_, _, diverged(At, W, G), _, _, DT) :- !,
    flow_dbg_side_text(W, holds, WT),
    flow_dbg_side_text(G, made, GT),
    format(atom(DT), 'THE REPLAY LEFT ITS JOURNAL at inference ~d: the journal ~w, the replay ~w -- this is the replay''s run up to there',
           [At, WT, GT]).
flow_dbg_div_text(PH, PU, RH, RU, Jr, DT) :-
    flow_dbg_end_text(PH, PU, [], PT, _),
    flow_dbg_end_text(RH, RU, [], RT, _),
    (   Jr == none -> Why = 'something the program read changed between the runs'
    ;   Why = 'something the program read that its journal does not hold changed between the runs'
    ),
    format(atom(DT), 'THE REPLAY DIVERGED: the probe ~w, the replay ~w -- ~w; this is the replay''s run',
           [PT, RT, Why]).

flow_dbg_side_text(none, holds, 'holds no call there') :- !.
flow_dbg_side_text(none, made, 'made none') :- !.
flow_dbg_side_text(portal(I, _, _, C), Verb, T) :-
    flow_clip(C, 50, C1),
    format(atom(T), '~w ~w at inference ~d', [Verb, C1, I]).

flow_dbg_end_text(diverged(At, _, _), _, _, T, red) :- !,
    format(atom(T), 'left its journal at inference ~d', [At]).
flow_dbg_end_text(answer, U, Ats, T, green) :- !,
    (   Ats = [_, _|_]
    ->  atomic_list_concat(Ats, ', ', AA),
        format(atom(T), 'answered, at inferences ~w', [AA])
    ;   format(atom(T), 'answered at inference ~d', [U])
    ).
flow_dbg_end_text(false, U, _, T, red) :- !,
    format(atom(T), 'failed at inference ~d', [U]).
flow_dbg_end_text(limit, U, _, T, amber) :- !,
    format(atom(T), 'stopped at inference ~d, where the window ends', [U]).
flow_dbg_end_text(exception(B), U, _, T, red) :- !,
    format(atom(BT0), '~q', [B]),
    flow_dbg_ung(BT0, BT1),
    flow_clip(BT1, 70, BT),
    format(atom(T), 'raised ~w at inference ~d', [BT, U]).
flow_dbg_end_text(halt(C), U, _, T, purple) :- !,
    format(atom(T), 'halted (~w) at inference ~d', [C, U]).
flow_dbg_end_text(error(M), _, _, T, red) :- !,
    format(atom(T), 'could not go on: ~w', [M]).
flow_dbg_end_text(H, U, _, T, ink) :-
    format(atom(T), '~w at inference ~d', [H, U]).

flow_dbg_window_text(F, T, _, true, NC, W) :- !,
    format(atom(W), 'recorded inferences ~d to ~d, the whole run  ·  ~d calls', [F, T, NC]).
flow_dbg_window_text(F, T, PU, false, NC, W) :-
    N is T - F + 1,
    format(atom(W), 'recorded inferences ~d to ~d of ~d, the last ~d  ·  ~d calls made in the window',
           [F, T, PU, N, NC]).

flow_dbg_fail_text(none, none, _, '') :- !.
flow_dbg_fail_text(LF, Th, Calls, T) :-
    (   LF = from(I, _, N/A, Box, Panel, _)
    ->  flow_dbg_where(Box, Panel, Wh),
        format(atom(T1), '  ·  the failure began at ~q/~w~w, inference ~d', [N, A, Wh, I])
    ;   LF = lf(I, _, N/A, Box, Panel, _)
    ->  flow_dbg_where(Box, Panel, Wh),
        format(atom(T1), '  ·  the last goal to fail: ~q/~w~w at inference ~d', [N, A, Wh, I])
    ;   T1 = ''
    ),
    (   Th = th(TI, _, _, R)
    ->  (   R =\= 0, memberchk(call(R, RN/RA, _, _, RB, RP, _, _, _, _), Calls)
        ->  flow_dbg_where(RB, RP, RW),
            format(atom(T2), '  ·  an exception raised by ~q/~w~w at inference ~d', [RN, RA, RW, TI])
        ;   format(atom(T2), '  ·  an exception raised at inference ~d', [TI])
        )
    ;   T2 = ''
    ),
    atom_concat(T1, T2, T).

flow_dbg_where(none, none, '') :- !.
flow_dbg_where(none, Panel, W) :- !, format(atom(W), ' (in ~w)', [Panel]).
flow_dbg_where(Box, _, W) :- format(atom(W), ' (~w)', [Box]).

%% ---- under the chart: what the marks mean, and each disc ---------------

flow_dbg_section(Facts, MaxW, Ps, H) :-
    Facts = dbg(Sum, _, _, _, _, _, Xs, Discs, Goals),
    Head = [t(24, 34, start, 10, sans, bold, [s('the run', muted)])],
    Max is max(MaxW, 980) - 24,
    (   arg(12, Sum, jr(_, _, _, _, _))
    ->  JL = [mark('⇄', teal, 'it reached the world through the journal: answered from it, not run')]
    ;   JL = []
    ),
    append([ box(reached, 'reached in the window'),
             box(failed, 'its last call failed, or a head did not unify'),
             box(raised, 'raised an exception (outlined: ended by one)'),
             box(dim, 'not reached in the window'),
             disc(call, 'a value given at a call'),
             disc(exit, 'a binding an exit made'),
             disc(redo, 'a binding backtracking undid') ], JL, Entries),
    flow_dbg_legend_entries(Entries, 140, 30, Max, LPs, LY),
    Y0 is LY + 46,
    length(Xs, NX),
    length(Discs, ND),
    (   ND =:= 0
    ->  Lines = [t(140, Y0, start, 10, sans, normal,
                   [s('no value crossed into a variable the source names in the window', muted)])],
        YEnd0 = Y0
    ;   (   NX > ND
        ->  format(atom(Say), 'the last ~d of the ~d bindings in the window, numbered on the chart; the XML has every one', [ND, NX])
        ;   format(atom(Say), 'the ~d bindings in the window, numbered on the chart', [ND])
        ),
        Y1 is Y0 + 24,
        flow_dbg_disc_lines(Discs, Goals, Y1, DPs, YEnd0),
        Lines = [t(140, Y0, start, 10, sans, normal, [s(Say, muted)])|DPs]
    ),
    flow_dbg_why_block(Facts, YEnd0, WPs, YEnd),
    H is YEnd + 30,
    append([Head, LPs, Lines, WPs], Ps).

%% ---- why it failed (D4) -------------------------------------------------
%%
%% A run that failed has the failures it came from drawn under its
%% bindings: each failed call of the program's own, each clause it tried --
%% its head did not unify, or its body entered and the calls it made --
%% down to the calls that failed with nothing of their own to say why
%% (dbgwhy.pl). The first 60 lines; the XML's <why> has all of it.

flow_dbg_why_block(Facts, Y0, Ps, YEnd) :-
    Facts = dbg(Sum, _, Calls, _, _, _, _, _, _),
    arg(13, Sum, Own),
    (   arg(3, Sum, end(false, _, _))
    ->  flow_dbg_why(Calls, Own, Whys),
        flow_dbg_why_cap(Whys, Ls),
        flow_why_furthest(Whys, Path),
        Y1 is Y0 + 46,
        flow_dbg_furthest_block(Path, Y1, FPs, Y1b),
        Title = t(24, Y1b, start, 10, sans, bold, [s('why it failed', muted)]),
        Y2 is Y1b + 24,
        flow_dbg_why_prims(Ls, Y2, WPs, YEnd),
        append(FPs, [Title|WPs], Ps)
    ;   arg(3, Sum, end(exception(_), _, _))
    ->  flow_dbg_raised(Calls, Own, Raised, Chose, Caught),
        Y1 is Y0 + 46,
        flow_dbg_raise_block(Raised, Chose, Caught, 'where the exception was raised', Y1, Ps, YEnd)
    ;   Ps = [], YEnd = Y0
    ).

%% a raise drawn from Y1: the calls it ended, the branch a choice took and
%% the conditions it ran (1.11.7), the failure it answered, and -- when a
%% catch's recovery raised it -- the exception that catch took, drawn the
%% same way under a title of its own
flow_dbg_raise_block(raised(Chain, Answered), Chose, Caught, Title, Y1, Ps, YEnd) :-
    RTitle = t(24, Y1, start, 10, sans, bold, [s(Title, muted)]),
    Y1a is Y1 + 24,
    (   Chain == []
    ->  CPs = [t(24, Y1a, start, 10, sans, normal, [s('it ended no call the window saw', muted)])],
        Y1c is Y1a + 4
    ;   flow_dbg_chain_lines(Chain, 0, CLs),
        flow_dbg_why_prims(CLs, Y1a, CPs, Y1c)
    ),
    (   Chose = chose(HS, HN/_, HIn, HAt, Branch, Conds)
    ->  Yh is Y1c + 22,
        flow_dbg_args_text(HN, HIn, HT0),
        flow_dbg_branch_words(Branch, BW),
        format(atom(HT), 'the branch it was raised in: ~w, at ~w in ~w (call at ~d)', [BW, HAt, HT0, HS]),
        flow_dbg_why_lines(Conds, 0, HLs, []),
        Yh1 is Yh + 24,
        flow_dbg_why_prims(HLs, Yh1, HPs0, Y1d),
        HPs = [t(24, Yh, start, 10, sans, bold, [s(HT, muted)])|HPs0]
    ;   HPs = [], Y1d = Y1c
    ),
    (   Answered == none
    ->  Y2 is Y1d + 22,
        (   Chose == none -> NT = 'no call failed, having tried a clause, before the raise on its way down'
        ;   NT = 'no condition the choice ran failed having tried a clause'
        ),
        NPs = [t(24, Y2, start, 10, sans, normal, [s(NT, muted)])],
        Y3 is Y2 + 4,
        APs = []
    ;   flow_why_furthest([Answered], Path),
        Y2 is Y1d + 22,
        flow_dbg_furthest_block(Path, Y2, FPs, Y2b),
        ATitle = t(24, Y2b, start, 10, sans, bold, [s('the failure it answered', muted)]),
        flow_dbg_why_cap([Answered], Ls),
        Y2c is Y2b + 24,
        flow_dbg_why_prims(Ls, Y2c, WPs, Y3),
        NPs = [],
        append(FPs, [ATitle|WPs], APs)
    ),
    (   Caught = caught(KS, KN/_, KIn, KAt, R1, KC, KK)
    ->  flow_dbg_args_text(KN, KIn, KT0),
        format(atom(KT), 'raised in the recovery of the catch/3 at ~w in ~w (call at ~d): the exception that catch took',
               [KAt, KT0, KS]),
        Y4 is Y3 + 34,
        flow_dbg_raise_block(R1, KC, KK, KT, Y4, KPs, YEnd)
    ;   KPs = [], YEnd = Y3
    ),
    append([[RTitle|CPs], HPs, NPs, APs, KPs], Ps).

%% the tree's first 60 lines; the XML has all of it
flow_dbg_why_cap(Whys, Ls) :-
    flow_dbg_why_lines(Whys, 0, Ls0, []),
    length(Ls0, NL),
    (   NL > 60
    ->  length(Ls1, 60), append(Ls1, _, Ls0),
        Rest is NL - 60,
        format(atom(More), '⋯  and ~d more lines: the XML''s <why> has every one', [Rest]),
        append(Ls1, [l(0, [s(More, muted)])], Ls)
    ;   Ls = Ls0
    ).

%% where it got furthest, titled, from Y: the next title's Y after it
flow_dbg_furthest_block([], Y, [], Y) :- !.
flow_dbg_furthest_block(Path, Y1, [FTitle|FPs0], Y1b) :-
    FTitle = t(24, Y1, start, 10, sans, bold, [s('where it got furthest', muted)]),
    flow_dbg_furthest_lines(Path, 0, FLs),
    Y1a is Y1 + 24,
    flow_dbg_why_prims(FLs, Y1a, FPs0, Y1c),
    Y1b is Y1c + 22.

%% the calls an exception ended, a level each, down to the deepest
flow_dbg_chain_lines([], _, []).
flow_dbg_chain_lines([E|Es], D, [L|Ls]) :-
    flow_dbg_why_line(E, D, [L], []),
    D1 is D + 1,
    flow_dbg_chain_lines(Es, D1, Ls).

%% the tree as lines: l(Depth, Segments)
flow_dbg_why_lines([], _, L, L).
flow_dbg_why_lines([W|Ws], D, L0, L) :-
    flow_dbg_why_line(W, D, L0, L1),
    flow_dbg_why_lines(Ws, D, L1, L).

flow_dbg_why_line(why(S, N/_, In, Tries), D, [l(D, Segs)|L1], L) :- !,
    flow_dbg_args_text(N, In, CT),
    format(atom(M), '   failed  ·  call at ~d', [S]),
    Segs = [s('✗ ', red), s(CT, ink), s(M, red)],
    D1 is D + 1,
    (   Tries == []
    ->  L1 = [l(D1, [s('no clause tried: none has a head these arguments could unify with', muted)])|L]
    ;   flow_dbg_why_try_lines(Tries, D1, L1, L)
    ).
flow_dbg_why_line(failed(S, N/_, In), D, [l(D, [s('✗ ', red), s(CT, ink), s(M, muted)])|L], L) :- !,
    flow_dbg_args_text(N, In, CT),
    format(atom(M), '   failed, with no clause of the program''s to say why  ·  call at ~d', [S]).
flow_dbg_why_line(exited(S, N/_, In, Out), D, [l(D, Segs)|L], L) :- !,
    flow_dbg_args_text(N, In, CT),
    (   Out \== none, Out \== In
    ->  flow_dbg_args_text(N, Out, OT), OS = [s('  →  ', muted), s(OT, ink)]
    ;   OS = []
    ),
    format(atom(M), '   ·  call at ~d', [S]),
    append([[s('✓ ', green), s(CT, ink)], OS, [s(M, muted)]], Segs).
flow_dbg_why_line(ended(S, N/_, In, Fate), D, [l(D, [s(Gl, GC), s(' ', ink), s(CT, ink), s(M, muted)])|L], L) :-
    flow_dbg_fate_glyph(Fate, Gl, GC),
    flow_dbg_args_text(N, In, CT),
    flow_dbg_fate_word(Fate, FW),
    format(atom(M), '   ~w  ·  call at ~d', [FW, S]).

%% the furthest path (flow_why_furthest/2), a line a step, each a level in
flow_dbg_furthest_lines([], _, []).
flow_dbg_furthest_lines([step(S, N/_, In, K, Done, Tried)|Ps], D, [l(D, Segs)|Ls]) :- !,
    flow_dbg_args_text(N, In, CT),
    (   Done =:= 1 -> DW = 'call' ; DW = 'calls' ),
    format(atom(M), '   clause ~d, the furthest of ~d tried: ~d ~w of its body exited  ·  call at ~d',
           [K, Tried, Done, DW, S]),
    Segs = [s('▸ ', red), s(CT, ink), s(M, muted)],
    D1 is D + 1,
    flow_dbg_furthest_lines(Ps, D1, Ls).
flow_dbg_furthest_lines([E|_], D, [l(D, [s(Gl, GC), s(' ', ink), s(CT, ink), s(M, muted)])]) :-
    flow_dbg_furthest_end(E, N, In, S, Gl, GC, Why),
    flow_dbg_args_text(N, In, CT),
    format(atom(M), '   ~w  ·  call at ~d', [Why, S]).

flow_dbg_furthest_end(failed(S, N/_, In), N, In, S, '✗', red, 'failed there: nothing of the program''s says why').
flow_dbg_furthest_end(nohead(S, N/_, In), N, In, S, '✗', red, 'failed there: no clause''s head unified').
flow_dbg_furthest_end(ended(S, N/_, In, Fate), N, In, S, Gl, GC, FW) :-
    flow_dbg_fate_glyph(Fate, Gl, GC),
    flow_dbg_fate_word(Fate, FW).

flow_dbg_why_try_lines([], _, L, L).
flow_dbg_why_try_lines([nohead(K)|Ts], D, [l(D, [s(T, muted)])|L1], L) :- !,
    format(atom(T), 'clause ~d: its head did not unify', [K]),
    flow_dbg_why_try_lines(Ts, D, L1, L).
flow_dbg_why_try_lines([entered(K, Gs)|Ts], D, [l(D, [s(T, muted)])|L1], L) :-
    (   Gs == [] -> format(atom(T), 'clause ~d: entered, and its body failed before calling anything', [K])
    ;   format(atom(T), 'clause ~d: entered, and called', [K])
    ),
    D1 is D + 1,
    flow_dbg_why_lines(Gs, D1, L1, L2),
    flow_dbg_why_try_lines(Ts, D, L2, L).

flow_dbg_why_prims([], Y, [], Y).
flow_dbg_why_prims([l(D, Segs)|Ls], Y, [t(X, Y, start, 11, mono, normal, Segs)|Ps], YEnd) :-
    X is 140 + 18 * D,
    Y1 is Y + 18,
    flow_dbg_why_prims(Ls, Y1, Ps, YEnd).

%% the entries left to right, a new line where the next would pass Max
flow_dbg_legend_entries([], _, Y, _, [], Y).
flow_dbg_legend_entries([E|Es], X, Y, Max, Ps, YEnd) :-
    flow_dbg_legend_sample(E, 0, 0, _, SW, Caption),
    flow_chars(Caption, CN),
    EW is SW + 8 + (CN * 62 + 9) // 10 + 26,
    (   X + EW > Max, X > 140 -> X1 = 140, Y1 is Y + 32 ; X1 = X, Y1 = Y ),
    flow_dbg_legend_sample(E, X1, Y1, SPs, _, _),
    CX is X1 + SW + 8,
    CY is Y1 + 4,
    X2 is X1 + EW,
    flow_dbg_legend_entries(Es, X2, Y1, Max, Rest, YEnd),
    append(SPs, [t(CX, CY, start, 10, sans, normal, [s(Caption, muted)])|Rest], Ps).

flow_dbg_legend_sample(box(K, C), X, Y, [P], 30, C) :-
    YT is Y - 10,
    (   K == dim -> P = dim(r(X, YT, 30, 20, 5, '#ffffff', '#52606d', 1, none))
    ;   flow_dbg_paint(K, '#ffffff', F, St), P = r(X, YT, 30, 20, 5, F, St, 2.6, none)
    ).
flow_dbg_legend_sample(disc(Port, C), X, Y, [c(CX, Y, 8, F, St, 1.5)], 16, C) :-
    CX is X + 8,
    flow_dbg_disc_paint(Port, F, St, _).
flow_dbg_legend_sample(mark(G, Col, C), X, Y, [t(X, TY, start, 11, sans, bold, [s(G, Col)])], 14, C) :-
    TY is Y + 4.

flow_dbg_disc_lines([], _, Y, [], Y).
flow_dbg_disc_lines([d(K, X)|Ds], Goals, Y, Ps, YEnd) :-
    X = x(I, Port, S, Nm, Val, Box, _),
    number_codes(K, KC),
    atom_codes(KA, KC),
    flow_dbg_disc_paint(Port, F, St, TC),
    TY is Y + 3,
    LY is Y + 4,
    flow_dbg_val_short(Val, 60, VT),
    flow_dbg_port_word(Port, PW),
    (   get_assoc(S, Goals, gi(_, G, Ns, _))
    ->  flow_term_full(G, Ns, 999, GT0), flow_clip(GT0, 50, GT)
    ;   GT = '?'
    ),
    format(atom(Rest), '    ~w of ~w  ·  ~w  ·  inference ~d', [PW, GT, Box, I]),
    Ps = [c(148, Y, 8, F, St, 1.5), t(148, TY, middle, 9, sans, bold, [s(KA, TC)]),
          t(162, LY, start, 11, mono, normal, [s(Nm, ink), s(' = ', muted), s(VT, ink), s(Rest, muted)])|Ps1],
    Y1 is Y + 22,
    flow_dbg_disc_lines(Ds, Goals, Y1, Ps1, YEnd).

%% ======================================================================
%% The tree: the calls themselves
%% ======================================================================

flow_dbg_tree(Facts, CW, CH, Els) :-
    Facts = dbg(_, _, Calls, _, _, _, _, _, _),
    flow_dbg_banner(Facts, BannerPs, BH),
    flow_dbg_tree_rows(Calls, Rows),
    (   Calls == [] -> MinD = 0
    ;   findall(D, member(call(_, _, D, _, _, _, _, _, _, _), Calls), Ds), min_list(Ds, MinD)
    ),
    findall(S-C, ( member(C, Calls), arg(1, C, S) ), SC),
    list_to_assoc(SC, ByS),
    Key = t(24, BH, start, 10, sans, normal,
            [s('✓', green), s(' exited    ', muted), s('✗', red), s(' failed    ', muted),
             s('⚠', purple), s(' raised an exception    ', muted), s('↑', purple), s(' ended by one    ', muted),
             s('↻', amber), s(' being tried again when the window closed    ', muted),
             s('…', muted), s(' still running then    ·    a call made inside another is indented under it', muted)]),
    Y0 is BH + 26,
    flow_dbg_tree_prims(Rows, ByS, MinD, Y0, Ps0, YEnd),
    Ps = [Key|Ps0],
    flow_lines_w(BannerPs, BW),
    flow_lines_w(Ps, PW),
    CW is max(max(BW, PW) + 32, 640),
    CH is YEnd + 40,
    flow_dbg_els(BannerPs, BEs),
    flow_dbg_els(Ps, PEs),
    append(BEs, [element(g, [id=run_tree], PEs)], Els).

%% row(S, Shift): call S drawn Shift levels higher than its depth, for the
%% levels elided above it; elide(S, N, Pred, Shift): N levels of a
%% recursion left out where call S would be; more(N): rows past the cap
flow_dbg_tree_rows(Calls, Rows) :-
    findall(P-S, member(call(S, _, _, P, _, _, _, _, _, _), Calls), PS0),
    keysort(PS0, PS),
    flow_dbg_group(PS, Kids),
    findall(S-Pr, member(call(S, Pr, _, _, _, _, _, _, _, _), Calls), SP),
    list_to_assoc(SP, Preds),
    findall(S-P, member(call(S, _, _, P, _, _, _, _, _, _), Calls), SPa),
    list_to_assoc(SPa, Parents),
    (   get_assoc(0, Kids, Roots) -> true ; Roots = [] ),
    empty_assoc(R0),
    T = t(Kids, Preds, Parents),
    flow_dbg_tree_list(Roots, 0, T, R0, Rows0, []),
    flow_dbg_tree_cap(Rows0, 800, Rows).

%% parent -> its calls, in the order they were made (keysort is stable)
flow_dbg_group(PS, Kids) :-
    empty_assoc(K0),
    reverse(PS, Rev),
    flow_dbg_group_(Rev, K0, Kids).

flow_dbg_group_([], K, K).
flow_dbg_group_([P-S|T], K0, K) :-
    (   get_assoc(P, K0, L) -> true ; L = [] ),
    put_assoc(P, K0, [S|L], K1),
    flow_dbg_group_(T, K1, K).

flow_dbg_tree_list([], _, _, _, R, R).
flow_dbg_tree_list([S|Ss], Shift, T, Repl, R0, R) :-
    (   get_assoc(S, Repl, rep(S2, N, Pr, Shift2))
    ->  R0 = [elide(S, N, Pr, Shift)|R1],
        flow_dbg_tree_node(S2, Shift2, T, Repl, R1, R2)
    ;   flow_dbg_tree_node(S, Shift, T, Repl, R0, R2)
    ),
    flow_dbg_tree_list(Ss, Shift, T, Repl, R2, R).

%% a recursion more than seven deep is drawn by its first three levels and
%% its last three: the chain is each level's first call of the predicate
flow_dbg_tree_node(S, Shift, T, Repl0, [row(S, Shift)|R1], R) :-
    T = t(Kids, Preds, _),
    get_assoc(S, Preds, Pr),
    (   \+ flow_dbg_chain_inner(S, Pr, T),
        flow_dbg_chain(S, Pr, T, Chain),
        length(Chain, L),
        L > 7
    ->  nth1(4, Chain, C4),
        LK is L - 2,
        nth1(LK, Chain, CK),
        NE is L - 6,
        Shift2 is Shift + NE,
        put_assoc(C4, Repl0, rep(CK, NE, Pr, Shift2), Repl)
    ;   Repl = Repl0
    ),
    (   get_assoc(S, Kids, Ks) -> true ; Ks = [] ),
    flow_dbg_tree_list(Ks, Shift, T, Repl, R1, R).

flow_dbg_chain(S, Pr, T, [S|Rest]) :-
    T = t(Kids, Preds, _),
    (   get_assoc(S, Kids, Ks), member(K, Ks), get_assoc(K, Preds, Pr)
    ->  flow_dbg_chain(K, Pr, T, Rest)
    ;   Rest = []
    ).

%% a call that is its parent's first call of the parent's own predicate is
%% a level of a chain whose head has already been measured
flow_dbg_chain_inner(S, Pr, t(Kids, Preds, Parents)) :-
    get_assoc(S, Parents, P),
    P =\= 0,
    get_assoc(P, Preds, Pr),
    get_assoc(P, Kids, Ks),
    member(K, Ks), get_assoc(K, Preds, Pr), !,
    K =:= S.

flow_dbg_tree_cap(Rows, Max, Out) :-
    length(Rows, N),
    (   N > Max
    ->  length(Keep, Max),
        append(Keep, _, Rows),
        More is N - Max,
        append(Keep, [more(More)], Out)
    ;   Out = Rows
    ).

flow_dbg_tree_prims([], _, _, Y, [], Y).
flow_dbg_tree_prims([R|Rs], ByS, MinD, Y, Ps, YEnd) :-
    flow_dbg_tree_row(R, ByS, MinD, Y, P),
    Y1 is Y + 18,
    Ps = [P|Ps1],
    flow_dbg_tree_prims(Rs, ByS, MinD, Y1, Ps1, YEnd).

flow_dbg_tree_row(row(S, Shift), ByS, MinD, Y, t(X, Y, start, 11, mono, normal, Segs)) :-
    get_assoc(S, ByS, call(S, N/_, D, _, Box, Panel, _, In, Out, Fate)),
    V is max(0, D - MinD - Shift),
    X is 24 + 18 * V,
    flow_dbg_fate_glyph(Fate, Gl, GC),
    flow_dbg_args_text(N, In, CT),
    (   Out \== none, Out \== In
    ->  flow_dbg_args_text(N, Out, OT),
        OSegs = [s('  →  ', muted), s(OT, ink)]
    ;   OSegs = []
    ),
    flow_dbg_where(Box, Panel, Wh),
    format(atom(M), '   at ~d~w', [S, Wh]),
    append([[s(Gl, GC), s(' ', ink), s(CT, ink)], OSegs, [s(M, muted)]], Segs).
flow_dbg_tree_row(elide(S, NE, N/A, Shift), ByS, MinD, Y, t(X, Y, start, 11, sans, normal, [s(T, muted)])) :-
    get_assoc(S, ByS, call(S, _, D, _, _, _, _, _, _, _)),
    V is max(0, D - MinD - Shift),
    X is 24 + 18 * V,
    format(atom(T), '⋯  ~d more levels of ~q/~w, and every call they made, left out', [NE, N, A]).
flow_dbg_tree_row(more(N), _, _, Y, t(24, Y, start, 11, sans, normal, [s(T, muted)])) :-
    format(atom(T), '⋯  and ~d more rows: the XML has every call', [N]).

flow_dbg_fate_glyph(exit, '✓', green).
flow_dbg_fate_glyph(fail, '✗', red).
flow_dbg_fate_glyph(redo, '↻', amber).
flow_dbg_fate_glyph(open, '…', muted).
flow_dbg_fate_glyph(raised, '⚠', purple).
flow_dbg_fate_glyph(unwound, '↑', purple).

flow_dbg_args_text(N, [], T) :- !,
    format(atom(T), '~q', [N]).
flow_dbg_args_text(N, As, T) :-
    findall(A, ( member(X, As), flow_dbg_arg_short(X, A) ), Ts),
    atomic_list_concat(Ts, ', ', AT),
    format(atom(N1), '~q', [N]),
    format(atom(T), '~w(~w)', [N1, AT]).

flow_dbg_arg_short(cut(P, _), A) :- !,
    flow_dbg_ung(P, P1),
    atom_concat(P1, '…', A).
flow_dbg_arg_short(X, A) :-
    flow_dbg_ung(X, A).

%% ======================================================================
%% The XML of the run
%% ======================================================================
%%
%% The chart's XML with a <run> after its panels (run version 1):
%%
%%   <run version lane goal ended at answers from to whole diverged calls
%%        [ball] [probe_ended probe_at] [last_fail_call last_fail_at]
%%        [journal portals answered]>
%%     <calls count>   <call n pred depth parent [box] [panel] fate [journal]>
%%                       <clause n at/> <nohead n at/> <thrown box at/>
%%                       <arg i call [call_length] [exit] [exit_length]/>
%%     <events count>  <event at port call depth [box] [clause] [ball]
%%                            [exited]>
%%                       <arg i value [length]/>      (call exit fail redo)
%%     <bindings count discs>
%%                     <binding n [disc] at port call box name value
%%                              [length] [undone]/>
%%     <journal count answered>                       (journal(true))
%%                     <portal at module pred call outcome [value] [ball]
%%                             [message] [length] answered/>
%%     <divergence at> <want .../> <got .../>          (a replay that left it)
%%
%% n of a call is the inference of its Call, and every call= names one;
%% box= is the chart's id; a value cut at text(N) has its whole length. A
%% <thrown> is an exception the call's own body raised by a throw/1, which
%% makes no call: box= the chart's box for it, at= its inference (1.11.7).
%% A redo's exited= is true when its call had exited -- asked for another
%% answer, the one Redo that says a call is nondeterministic -- and false
%% when it had not: its clause failed and it goes on to the next, as SWI
%% prints Redo too (none when the window did not see the call before).
%% A portal's at= is the inference of its call -- the n= of the <call> the
%% window saw there -- its outcome exit (value= the call as it exited),
%% fail, throw (ball=) or error (message=); answered= says whether the
%% replay was answered from it. <want> is the journal's call where the
%% replay left it and <got> the replay's, each at module pred call, or
%% none="true"; ended="diverged" then, and at= the replay's last inference.

flow_dbg_xml(Graph, Fs, Facts, element(flow, As, Cs1)) :-
    flow_xml(Graph, Fs, element(flow, As, Cs)),
    flow_dbg_x_run(Facts, RunE),
    append(Cs, [RunE], Cs1).

flow_dbg_x_run(dbg(Sum, SEs, Calls, _, _, _, Xs, Discs, _), element(run, As, Ks)) :-
    Sum = sum(Goal, Names, end(How, Used, Ats), end(PH, PU, _), F, T, Whole, Div, NC, LF, Th, Jr, Own),
    flow_term_full(Goal, Names, 999, GT),
    flow_dbg_how_word(How, HW),
    atomic_list_concat(Ats, ' ', AtsA),
    (   How = exception(B) -> format(atom(BT), '~q', [B]), BA = [ball=BT] ; BA = [] ),
    (   Div == false -> DA = [diverged=false]
    ;   flow_dbg_how_word(PH, PW), DA = [diverged=true, probe_ended=PW, probe_at=PU]
    ),
    (   LF = from(LI, LS, _, _, _, _) -> LA = [failed_from_call=LS, failed_from_at=LI]
    ;   LF = lf(LI, LS, _, _, _, _) -> LA = [last_fail_call=LS, last_fail_at=LI]
    ;   LA = []
    ),
    (   Th = th(TI, _, _, TR) -> TA0 = [raised_at=TI], ( TR =\= 0 -> TA = [raised_call=TR|TA0] ; TA = TA0 )
    ;   TA = []
    ),
    (   Jr = jr(Es, NA, _, JCalls, TM)
    ->  length(Es, NE), JA = [journal=true, portals=NE, answered=NA]
    ;   JA = [], empty_assoc(JCalls)
    ),
    append([[version=1, lane=l0, goal=GT, ended=HW, at=Used, answers=AtsA, from=F, to=T,
             whole=Whole, calls=NC], BA, DA, LA, TA, JA], As),
    findall(S-Box, member(call(S, _, _, _, Box, _, _, _, _, _), Calls), SB),
    list_to_assoc(SB, BoxOf),
    flow_dbg_x_calls(Calls, JCalls, CE),
    flow_dbg_x_events(SEs, BoxOf, EE),
    flow_dbg_x_bindings(Xs, Discs, BE),
    (   Jr = jr(_, _, _, _, _)
    ->  flow_dbg_x_journal(Es, How, Used, TM, JE),
        (   How = diverged(DAt, W, G)
        ->  flow_dbg_x_side(want, W, WE),
            flow_dbg_x_side(got, G, GE),
            JEs = [JE, element(divergence, [at=DAt], [WE, GE])]
        ;   JEs = [JE]
        )
    ;   JEs = []
    ),
    (   How == false
    ->  flow_dbg_why(Calls, Own, Whys),
        findall(WE1, ( member(W1, Whys), flow_dbg_x_why(W1, WE1) ), WEs),
        flow_why_furthest(Whys, Path),
        flow_dbg_x_furthest_el(Path, FEs),
        YEs = [element(why, [], WEs)|FEs]
    ;   How = exception(_)
    ->  flow_dbg_raised(Calls, Own, Raised, Chose, Caught),
        flow_dbg_x_raised(Raised, Chose, Caught, RE),
        YEs = [RE]
    ;   YEs = []
    ),
    append([[CE, EE, BE], JEs, YEs], Ks).

%% <raised> (1.11.4): an <ended fate> for each call the exception ended,
%% from the top down; <chose> (1.11.7) -- the branch a choice took, at= the
%% construct's box, branch= then, else or branch with n= its arm or branch,
%% call= and pred= the call whose clause chose -- holding a node for each
%% condition it ran; <answered>, the failure it answered and its
%% <furthest>; and <caught> (1.11.7) -- the catch whose recovery raised it,
%% at= its box, call= and pred= the call whose clause holds it -- holding
%% the exception that catch took as a <raised> of its own
flow_dbg_x_raised(raised(Chain, Answered), Chose, Caught, element(raised, [], REs)) :-
    findall(CE1, ( member(C1, Chain), flow_dbg_x_why(C1, CE1) ), CEs),
    (   Chose = chose(HS, HP, _, HAt, Branch, Conds)
    ->  flow_dbg_x_pred(HP, HPA),
        flow_dbg_x_branch(Branch, BAs),
        findall(NE, ( member(N, Conds), flow_dbg_x_why(N, NE) ), NEs),
        append([call=HS, pred=HPA, at=HAt], BAs, HAs),
        HEs = [element(chose, HAs, NEs)]
    ;   HEs = []
    ),
    (   Answered == none -> AEs = []
    ;   flow_dbg_x_why(Answered, AE),
        flow_why_furthest([Answered], APath),
        flow_dbg_x_furthest_el(APath, AFEs),
        AEs = [element(answered, [], [AE|AFEs])]
    ),
    (   Caught = caught(KS, KP, _, KAt, R1, KC, KK)
    ->  flow_dbg_x_pred(KP, KPA),
        flow_dbg_x_raised(R1, KC, KK, R1E),
        KEs = [element(caught, [call=KS, pred=KPA, at=KAt], [R1E])]
    ;   KEs = []
    ),
    append([CEs, HEs, AEs, KEs], REs).

flow_dbg_x_branch(then(J), [branch=then, n=J]).
flow_dbg_x_branch(else, [branch=else]).
flow_dbg_x_branch(branch(J), [branch=branch, n=J]).

flow_dbg_x_furthest_el([], []) :- !.
flow_dbg_x_furthest_el(Path, [element(furthest, [], FEs)]) :-
    findall(FE, ( member(PS, Path), flow_dbg_x_furthest(PS, FE) ), FEs).

%% why it failed, as the tree dbgwhy.pl reads it: <failed call pred> with a
%% <try n unified> for each clause it tried -- none when it tried none, no
%% head being one its arguments could unify with -- and, inside one
%% entered, the calls it made -- <exited>, <failed> (own="false": nothing
%% of the program's to say why) and <ended fate>. A run that raised has
%% <raised> instead (1.11.4): an <ended fate> for each call the exception
%% ended, from the top down; since 1.11.7 a <chose call pred at branch [n]>
%% -- the call whose clause chose the branch the raise is in, the
%% construct's box, then (n= its arm), else or branch (n=) -- holding an
%% element for each condition it ran; <answered> -- the failure the raise
%% answered, as a <failed> and its <furthest> -- when one was found; and,
%% when a catch's recovery raised it, a <caught call pred at> holding the
%% <raised> of the exception the catch took (flow_why_raised/2,3)
flow_dbg_x_why(why(S, P, _, Tries), element(failed, [call=S, pred=PA], TEs)) :- !,
    flow_dbg_x_pred(P, PA),
    findall(TE, ( member(T, Tries), flow_dbg_x_why_try(T, TE) ), TEs).
flow_dbg_x_why(failed(S, P, _), element(failed, [call=S, pred=PA, own=false], [])) :- !,
    flow_dbg_x_pred(P, PA).
flow_dbg_x_why(exited(S, P, _, _), element(exited, [call=S, pred=PA], [])) :- !,
    flow_dbg_x_pred(P, PA).
flow_dbg_x_why(ended(S, P, _, Fate), element(ended, [call=S, pred=PA, fate=Fate], [])) :-
    flow_dbg_x_pred(P, PA).

%% where it got furthest (flow_why_furthest/2): a <step call pred clause done
%% tried> for each failed call on the way, the clause that got furthest
%% and how many of its body's calls exited, then an <end call pred how>
%% -- failed, nohead, or the fate that ended it
flow_dbg_x_furthest(step(S, P, _, K, Done, Tried),
                    element(step, [call=S, pred=PA, clause=K, done=Done, tried=Tried], [])) :- !,
    flow_dbg_x_pred(P, PA).
flow_dbg_x_furthest(failed(S, P, _), element(end, [call=S, pred=PA, how=failed], [])) :- !,
    flow_dbg_x_pred(P, PA).
flow_dbg_x_furthest(nohead(S, P, _), element(end, [call=S, pred=PA, how=nohead], [])) :- !,
    flow_dbg_x_pred(P, PA).
flow_dbg_x_furthest(ended(S, P, _, F), element(end, [call=S, pred=PA, how=F], [])) :-
    flow_dbg_x_pred(P, PA).

flow_dbg_x_why_try(nohead(K), element(try, [n=K, unified=false], [])) :- !.
flow_dbg_x_why_try(entered(K, Gs), element(try, [n=K, unified=true], GEs)) :-
    findall(GE, ( member(G, Gs), flow_dbg_x_why(G, GE) ), GEs).

flow_dbg_x_pred(N/A, PA) :-
    format(atom(PA), '~q/~w', [N, A]).

flow_dbg_x_calls(Calls, JCalls, element(calls, [count=N], Es)) :-
    length(Calls, N),
    findall(E, ( member(C, Calls), flow_dbg_x_call(C, JCalls, E) ), Es).

flow_dbg_x_call(call(S, N/A, D, P, Box, Panel, Cl, In, Out, Fate), JCalls, element(call, As, Ks)) :-
    format(atom(PA), '~q/~w', [N, A]),
    flow_dbg_x_opt(box, Box, BA),
    flow_dbg_x_opt(panel, Panel, PnA),
    (   get_assoc(S, JCalls, _) -> JA = [journal=true] ; JA = [] ),
    append([[n=S, pred=PA, depth=D, parent=P], BA, PnA, [fate=Fate], JA], As),
    findall(E, ( member(X, Cl), flow_dbg_x_clause(X, E) ), CEs),
    flow_dbg_x_args(In, Out, AEs),
    append(CEs, AEs, Ks).

flow_dbg_x_opt(_, none, []) :- !.
flow_dbg_x_opt(K, V, [K=V]).

%% the journal: every entry the probe wrote, and whether the replay was
%% answered from it -- each one before the inference it left the journal
%% at, or up to its last
flow_dbg_x_journal(Es, How, Used, TM, element(journal, [count=N, answered=NA], PEs)) :-
    (   How = diverged(At, _, _) -> Lim is At - 1 ; Lim = Used ),
    length(Es, N),
    findall(PE, ( member(E, Es), flow_dbg_x_portal(E, Lim, TM, PE) ), PEs),
    findall(x, ( member(j(I, _, _, _, _), Es), I =< Lim ), Xs),
    length(Xs, NA).

flow_dbg_x_portal(j(I, M, N/A, C, O), Lim, TM, element(portal, As, [])) :-
    format(atom(PA), '~q/~w', [N, A]),
    flow_dbg_x_outcome(O, TM, OA),
    (   I =< Lim -> AA = [answered=true] ; AA = [answered=false] ),
    append([[at=I, module=M, pred=PA, call=C], OA, AA], As).

flow_dbg_x_outcome(fail, _, [outcome=fail]) :- !.
flow_dbg_x_outcome(exit(G), TM, [outcome=exit|VA]) :- !,
    flow_dbg_x_cut(value, G, TM, VA).
flow_dbg_x_outcome(throw(B), TM, [outcome=throw|VA]) :- !,
    flow_dbg_x_cut(ball, B, TM, VA).
flow_dbg_x_outcome(error(M), _, [outcome=error, message=M]) :- !.
flow_dbg_x_outcome(O, TM, [outcome=other|VA]) :-
    flow_dbg_x_cut(value, O, TM, VA).

%% a term as writeq writes it, cut at TM characters with its whole length
flow_dbg_x_cut(K, T, TM, As) :-
    format(atom(A), '~q', [T]),
    atom_length(A, L),
    (   L > TM
    ->  sub_atom(A, 0, TM, _, P),
        As = [K=P, length=L]
    ;   As = [K=A]
    ).

flow_dbg_x_side(K, none, element(K, [none=true], [])) :- !.
flow_dbg_x_side(K, portal(I, M, N/A, C), element(K, [at=I, module=M, pred=PA, call=C], [])) :-
    format(atom(PA), '~q/~w', [N, A]).

flow_dbg_x_clause(c(K, At), element(clause, [n=K, at=At], [])).
flow_dbg_x_clause(nohead(K, At), element(nohead, [n=K, at=At], [])).
flow_dbg_x_clause(thrown(B, At), element(thrown, [box=B, at=At], [])).

flow_dbg_x_args(In, Out, Es) :-
    flow_dbg_x_args_(In, Out, 1, Es).

flow_dbg_x_args_([], _, _, []).
flow_dbg_x_args_([CI|Cs], Out, I, [element(arg, As, [])|Es]) :-
    flow_dbg_x_val(call, CI, A1),
    (   Out = [OI|Os] -> flow_dbg_x_val(exit, OI, A2) ; Os = none, A2 = [] ),
    append([[i=I], A1, A2], As),
    I1 is I + 1,
    flow_dbg_x_args_(Cs, Os, I1, Es).

flow_dbg_x_val(Key, cut(P, L), [Key=P, KL=L]) :- !,
    atom_concat(Key, '_length', KL).
flow_dbg_x_val(Key, V, [Key=V]).

%% A REDO SAYS WHETHER ITS CALL HAD EXITED (exited=), which the tracer's
%% Redo does not, SWI's neither: a call asked for ANOTHER answer -- its
%% last port an Exit -- is the only Redo that says the call is
%% nondeterministic; one whose clause failed and which goes on to its next
%% clause is a retry within one search, and a predicate of many clauses
%% each guarded by a cut shows many of those. Each call's last port is
%% kept in order; a Redo whose call the window did not see before it has
%% no exited=.
flow_dbg_x_events(SEs, BoxOf, element(events, [count=N], Es)) :-
    length(SEs, N),
    empty_assoc(L0),
    flow_dbg_x_evs(SEs, BoxOf, L0, Es).

flow_dbg_x_evs([], _, _, []).
flow_dbg_x_evs([Ev|Evs], BoxOf, L0, [E|Es]) :-
    Ev = ev(_, Port, S, _, _, _),
    (   Port == redo, get_assoc(S, L0, Last)
    ->  ( Last == exit -> XA = [exited=true] ; XA = [exited=false] )
    ;   XA = []
    ),
    flow_dbg_x_event(Ev, BoxOf, XA, E),
    (   memberchk(Port, [call, exit, fail, redo]) -> put_assoc(S, L0, Port, L1) ; L1 = L0 ),
    flow_dbg_x_evs(Evs, BoxOf, L1, Es).

flow_dbg_x_event(ev(I, Port, S, D, W, As), BoxOf, XA, element(event, Attrs, Ks)) :-
    (   get_assoc(S, BoxOf, Box), Box \== none -> BA = [box=Box] ; BA = [] ),
    flow_dbg_x_what(Port, W, WA),
    append([[at=I, port=Port, call=S, depth=D], BA, WA, XA], Attrs),
    (   memberchk(Port, [call, exit, fail, redo])
    ->  flow_dbg_x_event_args(As, 1, Ks)
    ;   Ks = []
    ).

flow_dbg_x_what(clause, K, [clause=K]) :- !.
flow_dbg_x_what(nohead, K, [clause=K]) :- !.
flow_dbg_x_what(throw, B, As) :- !,
    flow_dbg_x_val(ball, B, As).
flow_dbg_x_what(_, _, []).

flow_dbg_x_event_args([], _, []).
flow_dbg_x_event_args([V|Vs], I, [element(arg, [i=I|VA], [])|Es]) :-
    flow_dbg_x_val(value, V, VA0),
    flow_dbg_x_rename(VA0, VA),
    I1 is I + 1,
    flow_dbg_x_event_args(Vs, I1, Es).

flow_dbg_x_rename([value=V, value_length=L], [value=V, length=L]) :- !.
flow_dbg_x_rename(A, A).

flow_dbg_x_bindings(Xs, Discs, element(bindings, [count=N, discs=ND], Es)) :-
    length(Xs, N),
    length(Discs, ND),
    Skip is N - ND,
    flow_dbg_x_binds(Xs, 1, Skip, Es).

flow_dbg_x_binds([], _, _, []).
flow_dbg_x_binds([x(I, Port, S, Nm, Val, Box, _)|Xs], J, Skip, [element(binding, As, [])|Es]) :-
    (   J > Skip -> K is J - Skip, DA = [disc=K] ; DA = [] ),
    flow_dbg_x_val(value, Val, VA0),
    flow_dbg_x_rename(VA0, VA),
    (   memberchk(Port, [redo, fail]) -> UA = [undone=true] ; UA = [] ),
    append([[n=J], DA, [at=I, port=Port, call=S, box=Box, name=Nm], VA, UA], As),
    J1 is J + 1,
    flow_dbg_x_binds(Xs, J1, Skip, Es).
