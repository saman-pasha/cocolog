%% library(flow/debug), part: a run as text, one line a call -- the
%% cheapest view of a run for an agent, written beside the picture and the
%% XML as BASE.txt when flow_debug/4 is given txt(true).
%%
%%     flow_dbg_text(+Places, +Facts, -Text)
%%     flow_dbg_text_places_of(+Xml, -Places)
%%
%% Places is where each box of the chart is written, read from the chart's
%% XML (flow_dbg_text_places_of/2) -- or from a cached chart, which keeps
%% them.
%%
%% The first line says how the run ended, as tools/flow/debug.pl's summary
%% does. Then each call the window saw, in the order it was made:
%%
%%     S INDENT GOAL FATE [CLAUSES] BOX WHERE
%%
%%     S        the inference of its Call: the n= of its <call> in the
%%              XML, by which every other element of the run names it
%%     INDENT   two spaces a level below the shallowest call of the window
%%     GOAL     the predicate over its arguments as they stood at its Call
%%     FATE     exit -- then the goal as it last exited -- fail, open (still
%%              running when the window closed), redo (tried again and not
%%              done when it closed), raised or unwound
%%     CLAUSES  the clauses it entered, c1 c3, and the heads that did not
%%              unify, h2
%%     BOX      the chart's id for the goal it is -- query.g1, p3.c2.g4 --
%%              or - for a call made in a clause the window did not see
%%              entered
%%     WHERE    that goal's FILE:LINE:COL, the place it is written
%%
%% A value cut at text(N) ends in `...' and its whole length in brackets.
%%
%%     7   member(z-_8,[a-1,b-2,c-3]) fail [c1 c2] p2.c1.g2 run.pl:37:28

%% the text of a run
flow_dbg_text(Places, Facts, Text) :-
    Facts = dbg(Sum, _, Calls, _, _, _, _, _, _),
    flow_dbg_text_head(Sum, Head),
    findall(D, member(call(_, _, D, _, _, _, _, _, _, _), Calls), Ds),
    ( Ds == [] -> D0 = 0 ; min_list(Ds, D0) ),
    findall(L, ( member(C, Calls), flow_dbg_text_call(C, D0, Places, L) ), Ls),
    atomic_list_concat([Head|Ls], '\n', T0),
    atom_concat(T0, '\n', Text).

%% the head line: the goal, how it ended and where, the window
flow_dbg_text_head(Sum, Head) :-
    Sum = sum(Goal, Names, end(How, Used, _), _, F, T, _, Div, NC, _, _, _),
    flow_term_full(Goal, Names, 999, GT),
    flow_dbg_how_word(How, HW),
    (   Div == false -> DT = no ; DT = yes ),
    format(atom(Head), '% ~w: ~w at inference ~w; recorded ~w to ~w; diverged ~w; ~w calls',
           [GT, HW, Used, F, T, DT, NC]).

%% one call's line
flow_dbg_text_call(call(S, N/_, D, _, Box, _, Cl, In, Out, Fate), D0, Places, Line) :-
    I is 2 * max(0, D - D0),
    flow_dbg_text_spaces(I, Indent),
    flow_dbg_text_goal(N, In, GT),
    (   Fate == exit, Out \== none
    ->  flow_dbg_text_goal(N, Out, OT),
        atom_concat('exit ', OT, FT)
    ;   FT = Fate
    ),
    findall(CT, ( member(X, Cl), flow_dbg_text_clause(X, CT) ), CTs),
    atomic_list_concat(CTs, ' ', ClT),
    (   Box == none -> BT = '-' ; BT = Box ),
    (   Box \== none, get_assoc(Box, Places, Where) -> true ; Where = '' ),
    format(atom(Line0), '~w ~w~w ~w [~w] ~w ~w', [S, Indent, GT, FT, ClT, BT, Where]),
    flow_dbg_text_trim(Line0, Line).

flow_dbg_text_clause(c(K, _), CT) :- !, atom_concat(c, K, CT).
flow_dbg_text_clause(nohead(K, _), CT) :- atom_concat(h, K, CT).

%% Name(Arg, ...), each argument as the window wrote it
flow_dbg_text_goal(N, As, T) :-
    format(atom(NT), '~q', [N]),
    (   As == []
    ->  T = NT
    ;   findall(AT, ( member(A, As), flow_dbg_text_value(A, AT) ), ATs),
        atomic_list_concat(ATs, ',', AA),
        atomic_list_concat([NT, '(', AA, ')'], T)
    ).

flow_dbg_text_value(cut(P, L), T) :- !,
    format(atom(T), '~w...[~w]', [P, L]).
flow_dbg_text_value(V, V).

flow_dbg_text_spaces(0, '') :- !.
flow_dbg_text_spaces(N, S) :-
    N1 is N - 1,
    flow_dbg_text_spaces(N1, S1),
    atom_concat(' ', S1, S).

%% a line ends where its last field does
flow_dbg_text_trim(L0, L) :-
    (   atom_concat(L1, ' ', L0) -> flow_dbg_text_trim(L1, L) ; L = L0 ).

%% where each goal of the chart is written: box id -> FILE:LINE:COL, from
%% the chart's XML -- a <goal> has its line and column, the <clause> it is
%% in its file
flow_dbg_text_places_of(element(flow, _, Ks), Places) :-
    flow_dbg_text_places(Ks, Places).

flow_dbg_text_places(Ks, Places) :-
    findall(Id-W, flow_dbg_text_place(Ks, none, Id, W), Ps),
    empty_assoc(P0),
    flow_dbg_text_put(Ps, P0, Places).

flow_dbg_text_put([], P, P).
flow_dbg_text_put([K-V|KVs], P0, P) :-
    put_assoc(K, P0, V, P1),
    flow_dbg_text_put(KVs, P1, P).

flow_dbg_text_place(Ks, File, Id, W) :-
    member(K, Ks), nonvar(K), K = element(N, As, Cs),
    (   N == clause, memberchk(file=F, As) -> File1 = F ; File1 = File ),
    (   N == goal, File1 \== none,
        memberchk(id=Id, As), memberchk(line=L, As), memberchk(col=C, As),
        atomic_list_concat([File1, ':', L, ':', C], W)
    ;   flow_dbg_text_place(Cs, File1, Id, W)
    ).
