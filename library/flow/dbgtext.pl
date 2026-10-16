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
%% does; the second, `% file: FILE', names the file every place below is in,
%% when they are all in one (1.11.0: through 1.10.28 each line carried it,
%% and on the translator its path was 93 of a line's 213 bytes -- reported
%% from the reasoning session). Then each call the window saw, in the order
%% it was made:
%%
%%     S INDENT GOAL FATE [CLAUSES] BOX WHERE
%%
%%     S        the step of its Call: the n= of its <call> in the
%%              XML, by which every other element of the run names it
%%     INDENT   two spaces a level below the shallowest call of the window
%%     GOAL     the predicate over its arguments as they stood at its Call
%%     FATE     exit -- then the goal as it last exited -- fail, open (still
%%              running when the window closed), redo (tried again and not
%%              done when it closed), raised or unwound
%%     CLAUSES  the clauses it entered, c1 c3, and the heads it tried that
%%              did not unify, h2 -- [] when it tried none, no head being
%%              one its arguments could unify with -- and threw:BOX where
%%              its own body raised an exception, a throw/1 at BOX (1.11.7)
%%     BOX      the chart's id for the goal it is -- query.g1, p3.c2.g4 --
%%              or - for a call made in a clause the window did not see
%%              entered; in a clause the chart does not draw, a call an
%%              exception ended made its calls at the places the clause
%%              read from the file gives them, cpp_refuse/2#c1.g2
%%              (1.11.7, dbgmatch.pl), with no WHERE
%%     WHERE    that goal's :LINE:COL in the file the second line names, the
%%              place it is written -- or its whole FILE:LINE:COL when the
%%              window's places are in more than one file
%%
%% A value cut at text(N) ends in `...' and its whole length in brackets.
%%
%%     % file: run.pl
%%     7   member(z-_8,[a-1,b-2,c-3]) fail [c1 c2] p2.c1.g2 :37:28

%% the text of a run
flow_dbg_text(Places, Facts, Text) :-
    Facts = dbg(Sum, _, Calls, _, _, _, _, _, _),
    flow_dbg_text_head(Sum, Head),
    findall(D, member(call(_, _, D, _, _, _, _, _, _, _), Calls), Ds),
    ( Ds == [] -> D0 = 0 ; min_list(Ds, D0) ),
    flow_dbg_text_file(Calls, Places, File),
    findall(L, ( member(C, Calls), flow_dbg_text_call(C, D0, Places, File, L) ), Ls0),
    flow_dbg_text_furthest(Sum, Calls, FLs),
    append(Ls0, FLs, Ls),
    (   File == none -> Heads = [Head]
    ;   format(atom(FH), '% file: ~w', [File]), Heads = [Head, FH]
    ),
    append(Heads, Ls, All),
    atomic_list_concat(All, '\n', T0),
    atom_concat(T0, '\n', Text).

%% the one file every place of the window's calls is in, or none: none
%% has a place, or they are in several
flow_dbg_text_file(Calls, Places, File) :-
    findall(F, ( member(call(_, _, _, _, Box, _, _, _, _, _), Calls), Box \== none,
                 get_assoc(Box, Places, W), flow_dbg_text_split(W, F, _) ),
            Fs0),
    sort(Fs0, Fs),
    ( Fs = [File] -> true ; File = none ).

%% FILE:LINE:COL as FILE and :LINE:COL -- split at its last two colons, so a
%% colon in the file's own name stays in it
flow_dbg_text_split(W, File, LC) :-
    atomic_list_concat(Parts, ':', W),
    append(FParts, [L, C], Parts), FParts \== [], !,
    atomic_list_concat(FParts, ':', File),
    atomic_list_concat(['', L, C], ':', LC).

%% the head line: the goal, how it ended and where, the window
flow_dbg_text_head(Sum, Head) :-
    Sum = sum(Goal, Names, end(How, Used, _), _, F, T, _, Div, NC, _, _, _, _),
    flow_term_full(Goal, Names, 999, GT),
    flow_dbg_how_word(How, HW),
    flow_dbg_div_ends(Div, DT),
    format(atom(Head), '% ~w: ~w at step ~w; recorded ~w to ~w; diverged ~w; ~w calls',
           [GT, HW, Used, F, T, DT, NC]).

%% `no', or `yes' and both ends: the window is the probe's, and a replay
%% that ended elsewhere is no window of it (1.11.4, from cicili-lang's
%% report: a cache on disk the probe wrote sent the replay a shorter way)
flow_dbg_div_ends(false, no) :- !.
flow_dbg_div_ends(diverged(end(PH, PU, _), end(RH, RU, _)), T) :-
    flow_dbg_how_word(PH, PW),
    flow_dbg_how_word(RH, RW),
    format(atom(T), 'yes (the probe: ~w at step ~w; the replay: ~w at step ~w)', [PW, PU, RW, RU]).

%% one call's line, its place :LINE:COL in File, or whole when File is none
flow_dbg_text_call(call(S, N/_, D, _, Box, _, Cl, In, Out, Fate), D0, Places, File, Line) :-
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
    (   Box \== none, get_assoc(Box, Places, W)
    ->  (   File \== none, flow_dbg_text_split(W, File, LC) -> Where = LC ; Where = W )
    ;   Where = ''
    ),
    format(atom(Line0), '~w ~w~w ~w [~w] ~w ~w', [S, Indent, GT, FT, ClT, BT, Where]),
    flow_dbg_text_trim(Line0, Line).

flow_dbg_text_clause(c(K, _), CT) :- !, atom_concat(c, K, CT).
flow_dbg_text_clause(nohead(K, _), CT) :- !, atom_concat(h, K, CT).
flow_dbg_text_clause(thrown(B, _), CT) :- atom_concat('threw:', B, CT).

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

%% N spaces, made at once (1.11.10): through 1.11.9 a space at a time, an
%% atom_concat/3 a level, which is quadratic in the depth -- and a window
%% far along a recursion that does not return (a loop of last calls) is
%% hundreds of levels deep: BASE.txt of a 20 000-step window took
%% 10.4 s, of 100 000 minutes (the reasoning session's point 8)
flow_dbg_text_spaces(N, S) :-
    format(atom(S), '~*c', [N, 0' ]).

%% a line ends where its last field does
flow_dbg_text_trim(L0, L) :-
    (   atom_concat(L1, ' ', L0) -> flow_dbg_text_trim(L1, L) ; L = L0 ).

%% where each goal and each clause of the chart is written: its id (a box,
%% p2.c1.g2, or a clause, p2.c1) -> FILE:LINE:COL, from the chart's XML --
%% a <goal> has its line and column, the <clause> it is in its file and its
%% own
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
    (   memberchk(N, [goal, clause]), File1 \== none,
        memberchk(id=Id, As), memberchk(line=L, As), memberchk(col=C, As),
        atomic_list_concat([File1, ':', L, ':', C], W)
    ;   flow_dbg_text_place(Cs, File1, Id, W)
    ).

%% a failed run ends with where it got furthest (flow_why_furthest/2): a
%% line a failed call on the way, the clause that got furthest and how many
%% of its body's calls exited, and how the last failed. A run that raised
%% ends with the calls the exception ended, from the top down, and where the
%% failure it answered got furthest (flow_why_raised/2, 1.11.4); since
%% 1.11.7 between them the branch a choice took and the conditions it ran,
%% and after them, when a catch's recovery raised it, the exception the
%% catch took, told the same way and indented under its own line
flow_dbg_text_furthest(Sum, Calls, Ls) :-
    arg(13, Sum, Own),
    (   arg(3, Sum, end(false, _, _))
    ->  flow_dbg_why(Calls, Own, Whys),
        flow_why_furthest(Whys, Path),
        (   Path == [] -> Ls = []
        ;   flow_dbg_text_path(Path, 1, Ls0),
            Ls = ['% where it got furthest:'|Ls0]
        )
    ;   arg(3, Sum, end(exception(_), _, _))
    ->  flow_dbg_raised(Calls, Own, Raised, Chose, Caught),
        flow_dbg_text_raise(Raised, Chose, Caught, 0, Ls)
    ;   Ls = []
    ).

%% a raise, its headings indented D levels
flow_dbg_text_raise(raised(Chain, Answered), Chose, Caught, D, Ls) :-
    I is 2 * D,
    flow_dbg_text_spaces(I, Ind),
    D1 is D + 1,
    (   Chain == []
    ->  format(atom(H1), '% ~wwhere the exception was raised: it ended no call the window saw', [Ind]),
        CLs = []
    ;   format(atom(H1), '% ~wwhere the exception was raised:', [Ind]),
        flow_dbg_text_chain(Chain, D1, CLs)
    ),
    flow_dbg_text_chose(Chose, Ind, D1, HLs),
    (   Answered == none
    ->  (   Chose == none
        ->  format(atom(A1), '% ~wthe failure it answered: none -- no call failed, having tried a clause, before the raise on its way down', [Ind])
        ;   format(atom(A1), '% ~wthe failure it answered: none -- no condition the choice ran failed having tried a clause', [Ind])
        ),
        ALs = [A1]
    ;   flow_why_furthest([Answered], Path),
        flow_dbg_text_path(Path, D1, PLs),
        format(atom(A1), '% ~wthe failure it answered, where it got furthest:', [Ind]),
        ALs = [A1|PLs]
    ),
    (   Caught = caught(KS, KN/_, KIn, KAt, R1, C1, K1)
    ->  flow_dbg_text_goal(KN, KIn, KG),
        format(atom(K0), '% ~wit was raised in the recovery of the catch/3 at ~w in ~w (call ~w); the exception that catch took:',
               [Ind, KAt, KG, KS]),
        flow_dbg_text_raise(R1, C1, K1, D1, KLs1),
        KLs = [K0|KLs1]
    ;   KLs = []
    ),
    append([[H1|CLs], HLs, ALs, KLs], Ls).

%% the branch a choice took, and its conditions a line each
flow_dbg_text_chose(none, _, _, []) :- !.
flow_dbg_text_chose(chose(S, N/_, In, At, Branch, Conds), Ind, D1, [H|CLs]) :-
    flow_dbg_text_goal(N, In, GT),
    flow_dbg_branch_words(Branch, BW),
    format(atom(H), '% ~wthe branch it was raised in: ~w, at ~w in ~w (call ~w); the conditions it ran:',
           [Ind, BW, At, GT, S]),
    I is 2 * D1,
    flow_dbg_text_spaces(I, CInd),
    findall(L, ( member(C, Conds), flow_dbg_text_cond(C, CInd, L) ), CLs).

flow_dbg_text_cond(Node, CInd, L) :-
    arg(1, Node, S), arg(2, Node, N/_), arg(3, Node, In),
    flow_dbg_text_goal(N, In, GT),
    flow_dbg_cond_word(Node, W),
    format(atom(L), '%~w~w: ~w (call ~w)', [CInd, GT, W, S]).

%% how a branch was chosen, and how a condition ended, in words
flow_dbg_branch_words(then(J), W) :- !,
    format(atom(W), 'the then of arm ~w (its condition held)', [J]).
flow_dbg_branch_words(else, 'the else (every condition failed)') :- !.
flow_dbg_branch_words(branch(J), W) :-
    format(atom(W), 'branch ~w (the branches before it failed)', [J]).

flow_dbg_cond_word(exited(_, _, _, _), exited) :- !.
flow_dbg_cond_word(why(_, _, _, []), 'failed, no clause''s head unified') :- !.
flow_dbg_cond_word(why(_, _, _, _), 'failed in its clauses') :- !.
flow_dbg_cond_word(failed(_, _, _), 'failed, nothing of the program''s to say why') :- !.
flow_dbg_cond_word(ended(_, _, _, F), W) :-
    format(atom(W), '~w, and a catch took the exception', [F]).

flow_dbg_text_chain([], _, []).
flow_dbg_text_chain([ended(S, N/_, In, F)|Es], D, [L|Ls]) :-
    I is 2 * D,
    flow_dbg_text_spaces(I, Indent),
    flow_dbg_text_goal(N, In, GT),
    format(atom(L), '%~w~w: ~w (call ~w)', [Indent, GT, F, S]),
    D1 is D + 1,
    flow_dbg_text_chain(Es, D1, Ls).

flow_dbg_text_path([], _, []).
flow_dbg_text_path([step(S, N/_, In, K, Done, Tried)|Ps], D, [L|Ls]) :- !,
    I is 2 * D,
    flow_dbg_text_spaces(I, Indent),
    flow_dbg_text_goal(N, In, GT),
    format(atom(L), '%~w~w: clause ~d, the furthest of ~d tried: ~d of its calls exited (call ~w)',
           [Indent, GT, K, Tried, Done, S]),
    D1 is D + 1,
    flow_dbg_text_path(Ps, D1, Ls).
flow_dbg_text_path([E|_], D, [L]) :-
    I is 2 * D,
    flow_dbg_text_spaces(I, Indent),
    flow_dbg_text_end(E, S, N, In, How),
    flow_dbg_text_goal(N, In, GT),
    format(atom(L), '%~w~w: ~w (call ~w)', [Indent, GT, How, S]).

flow_dbg_text_end(failed(S, N/_, In), S, N, In, 'failed, nothing of the program''s to say why').
flow_dbg_text_end(nohead(S, N/_, In), S, N, In, 'failed, no clause''s head unified').
flow_dbg_text_end(ended(S, N/_, In, F), S, N, In, F).
