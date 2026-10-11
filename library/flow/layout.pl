%% library(flowchart), part: the layout -- items, rows, lanes, panels,
%% the chart and its legend, as layered primitives.

%% ======================================================================
%% Measuring: every item knows its width and how far it reaches above
%% and below the main line it sits on
%% ======================================================================
%%
%%   mg(Kind, Segs, Badge, ND, CF, W, Tip)   a goal
%%   mhead(Segs, HF, W, Tip)                  a clause head
%%   mcut | mfail(W) | mthrow(Segs, W)
%%   mframe(Items, W, A, D)                   an if-then-else's condition
%%   mcon(Type, Label, Tracks, W, A, D, CF, ND)   a construct of tracks
%%
%% CF: the item can fail. ND: it can leave a choice point to come back to.

%% ITS NAME. Every item measured here carries the id the XML gives the same
%% thing -- p3.c2.g4 is panel 3, clause 2, goal 4; inside a construct the
%% list it stands in comes next: X.a1.if and X.a1 for an if-then-else's
%% first condition and its then, X.else, X.b2 for a disjunction's second
%% branch, X.try and X.recover for catch/3, X itself for the one list of
%% \+ and of a meta-call -- so a finding in the XML points at a box here.
%% The context is lc(Names, Ids, Self, Base): Base names the list.
%%
%% EVERY GOAL IS A BOX WITH ITS OWN TEXT: a builtin, a test, a unification
%% and a library predicate stand on their clause's line as any call does,
%% and the chart never goes inside one -- a builtin is C in the engine, and
%% a library predicate is opened into a panel only when libraries(reach)
%% or libraries(all) asks (analyse.pl, "The panels"). A construct shows
%% the goals it was handed, which are the program's own.

flow_m_list(Ns, LC, Is) :-
    flow_m_list_(Ns, LC, 1, Is).

flow_m_list_([], _, _, []).
flow_m_list_([N|Ns], LC, K, [I|Is]) :-
    LC = lc(Names, Ids, Self, Base),
    atomic_list_concat([Base, '.g', K], Id),
    flow_m(N, lc(Names, Ids, Self, Id), I),
    K1 is K + 1,
    flow_m_list_(Ns, LC, K1, Is).

%% a construct's lists, each under its own name: X.b1, X.b2, ...
flow_m_lists(Ls, LC, Tag, Is) :-
    flow_m_lists_(Ls, LC, Tag, 1, Is).

flow_m_lists_([], _, _, _, []).
flow_m_lists_([L|Ls], LC, Tag, K, [I|Is]) :-
    flow_lc_sub(LC, [Tag, K], LC1),
    flow_m_list(L, LC1, I),
    K1 is K + 1,
    flow_m_lists_(Ls, LC, Tag, K1, Is).

flow_lc_sub(lc(N, I, S, X), Parts, lc(N, I, S, B)) :-
    atomic_list_concat([X, '.'|Parts], B).

flow_m(g(G, Kind, Ms, Det, Key, Info), LC, mg(Kind, Segs, Badge, ND, CF, W, tip(Tip, Id))) :- !,
    LC = lc(Names, Ids, Self, Id),
    flow_goal_segs(G, Ms, Names, Segs),
    flow_badge(Kind, Key, Ms, Ids, Self, Badge),
    flow_det_flags(Det, CF, ND),
    flow_segs_w(Segs, TW),
    flow_badge_w(Badge, BW),
    (   ND == true -> NW = 13 ; NW = 0 ),
    (   Kind == test -> HW = 12 ; HW = 0 ),
    (   Kind = portal(_) -> PW = 17 ; PW = 0 ),
    W is 18 + TW + NW + BW + HW + PW,
    flow_tip(G, Kind, Det, Names, Tip0),
    (   memberchk(unreached, Info)
    ->  atom_concat(Tip0, '  --  never reached: past a call that never succeeds', Tip)
    ;   Tip = Tip0
    ).
flow_m(cut, _, mcut) :- !.
flow_m(failn, _, mfail(W)) :- !,
    flow_text_w(4, TW),
    W is TW + 18.
flow_m(thrown(E), lc(Names, _, _, _), mthrow(Segs, W)) :- !,
    flow_term_text(E, Names, 999, T),
    Segs = [s('throw(', ink), s(T, m('+')), s(')', ink)],
    flow_segs_w(Segs, TW),
    W is TW + 18.
flow_m(ite(Soft, Arms, Else), LC, mcon(ite, Label, Tracks, W, A, D, CF, ND)) :- !,
    (   Soft == soft -> Label = lbl('if  *->  then  ;  else') ; Label = lbl('if  ->  then  ;  else') ),
    flow_m_arms(Arms, LC, 1, ArmTracks),
    (   Else == none -> Rest = []
    ;   flow_lc_sub(LC, [else], LCE), flow_m_list(Else, LCE, EIs), Rest = [EIs]
    ),
    append(ArmTracks, Rest, TrackItems),
    flow_tracks(TrackItems, 0, 26, Tracks),
    flow_con_size(Tracks, Label, W, A, D),
    flow_tracks_flags(Tracks, CF0, ND),
    (   Else == none -> CF = true ; CF = CF0 ).
flow_m(or(Bs), LC, mcon(or, Label, Tracks, W, A, D, true, true)) :- !,
    Label = lbl('or  ;   each branch in turn'),
    flow_m_lists(Bs, LC, b, TIs),
    flow_tracks(TIs, 14, 0, Tracks),
    flow_con_size(Tracks, Label, W, A, D).
flow_m(not(Ns), LC, mcon(not, Label, Tracks, W, A, D, true, false)) :- !,
    Label = lbl('\\+   succeeds when this fails'),
    flow_m_list(Ns, LC, Is),
    flow_tracks([Is], 0, 0, Tracks),
    flow_con_size(Tracks, Label, W, A, D).
flow_m(meta(Name, Head, Ms, Ts, _), LC, mcon(meta, segs(Segs), Tracks, W, A, D, CF, ND)) :- !,
    LC = lc(Names, _, _, _),
    flow_goal_segs(Head, Ms, Names, Segs0),
    flow_meta_note(Name, Note),
    append(Segs0, [s(Note, muted)], Segs),
    findall(TI, ( member(T, Ts), flow_m_list(T, LC, TI) ), TIs),
    flow_tracks(TIs, 0, 0, Tracks),
    flow_con_size(Tracks, segs(Segs), W, A, D),
    flow_meta_can_fail(Name, Head, Ms, Ts, CF),
    (   Name == phrase -> flow_tracks_flags(Tracks, _, ND) ; ND = false ).   % phrase is transparent to choice
flow_m(catchc(G, Ball, R), LC, mcon(catch, segs(Segs), Tracks, W, A, D, CF, ND)) :- !,
    LC = lc(Names, _, _, _),
    flow_term_text(Ball, Names, 999, BT),
    Segs = [s('catch(…, ', ink), s(BT, m('?')), s(', …)', ink)],
    flow_lc_sub(LC, [try], LCT),
    flow_lc_sub(LC, [recover], LCR),
    flow_m_list(G, LCT, GIs),
    flow_m_list(R, LCR, RIs),
    flow_tracks([GIs, RIs], 0, 26, Tracks),
    flow_con_size(Tracks, segs(Segs), W, A, D),
    flow_tracks_flags(Tracks, CF, ND).

flow_meta_note(findall, '    every solution').
flow_meta_note(aggregate_all, '    every solution').
flow_meta_note(forall, '    for every one').
flow_meta_note(once, '    the first solution').
flow_meta_note(ignore, '    never fails').
flow_meta_note(phrase, '    the grammar over a list').

flow_m_arms([], _, _, []).
flow_m_arms([arm(C, T)|As], LC, K, [[F|TIs]|Ts]) :-
    flow_lc_sub(LC, [a, K, '.if'], LCC),
    flow_lc_sub(LC, [a, K], LCT),
    flow_m_list(C, LCC, CIs),
    flow_track_size(CIs, CW, CA, CD),
    FW is CW + 16, FA is CA + 13, FD is CD + 6,
    F = mframe(CIs, FW, FA, FD),
    flow_m_list(T, LCT, TIs),
    K1 is K + 1,
    flow_m_arms(As, LC, K1, Ts).

%% a track: t(Offset, Items, Width, Ascent, Descent)
flow_tracks([], _, _, []).
flow_tracks([Is|Iss], Off, Step, [t(Off, Is, TW, TA, TD)|Ts]) :-
    flow_track_size(Is, TW, TA, TD),
    Off1 is Off + Step,
    flow_tracks(Iss, Off1, Step, Ts).

flow_track_size([], 24, 13, 13) :- !.
flow_track_size(Is, TW, TA, TD) :-
    flow_items_size(Is, 0, W0, 13, TA, 13, TD),
    length(Is, N),
    TW is W0 + 22 * (N - 1).

flow_items_size([], W, W, A, A, D, D).
flow_items_size([I|Is], W0, W, A0, A, D0, D) :-
    flow_size(I, IW, IA, ID),
    W1 is W0 + IW,
    A1 is max(A0, IA),
    D1 is max(D0, ID),
    flow_items_size(Is, W1, W, A1, A, D1, D).

flow_con_size(Tracks, Label, W, A, D) :-
    Tracks = [t(_, _, _, A1, D1)|Rest],
    flow_tracks_maxw(Tracks, 0, MW),
    flow_label_w(Label, LW),
    W is max(12 + MW + 24, LW + 20),
    A is 19 + A1,
    flow_rest_h(Rest, 0, RH),
    D is D1 + RH + 9.

flow_tracks_maxw([], M, M).
flow_tracks_maxw([t(Off, _, TW, _, _)|Ts], M0, M) :-
    M1 is max(M0, Off + TW),
    flow_tracks_maxw(Ts, M1, M).

flow_rest_h([], H, H).
flow_rest_h([t(_, _, _, A, D)|Ts], H0, H) :-
    H1 is H0 + 16 + A + D,
    flow_rest_h(Ts, H1, H).

flow_label_w(lbl(A), W) :- flow_chars(A, N), W is (N * 62 + 9) // 10.
flow_label_w(segs(Ss), W) :- flow_segs_chars(Ss, N), W is (N * 66 + 9) // 10.

flow_tracks_flags(Tracks, CF, ND) :-
    (   member(t(_, Is, _, _, _), Tracks), member(I, Is), flow_flags(I, true, _) -> CF = true ; CF = false ),
    (   member(t(_, Is2, _, _, _), Tracks), member(I2, Is2), flow_flags(I2, _, true) -> ND = true ; ND = false ).

flow_flags(mg(_, _, _, ND, CF, _, _), CF, ND).
flow_flags(mhead(_, HF, _, _), HF, false).
flow_flags(mcut, false, false).
flow_flags(mfail(_), true, false).
flow_flags(mthrow(_, _), false, false).
flow_flags(mframe(_, _, _, _), false, false).
flow_flags(mcon(_, _, _, _, _, _, CF, ND), CF, ND).

flow_size(mg(_, _, _, _, _, W, _), W, 13, 13).
flow_size(mhead(_, _, W, _), W, 13, 13).
flow_size(mcut, 14, 13, 13).
flow_size(mfail(W), W, 13, 13).
flow_size(mthrow(_, W), W, 13, 13).
flow_size(mframe(_, W, A, D), W, A, D).
flow_size(mcon(_, _, _, W, A, D, _, _), W, A, D).

flow_det_flags(det, false, false).
flow_det_flags(semidet, true, false).
flow_det_flags(nondet, true, true).
flow_det_flags(failure, true, false).

%% the word a panel or a tooltip says
flow_det_text(failure, 'never succeeds') :- !.
flow_det_text(D, D).

%% a call carries the number of the panel for its own call pattern; a call
%% to the very panel it stands in is a recursion
flow_badge(Kind, Key, Ms, Ids, Self, B) :-
    (   flow_callable_kind(Kind), flow_panel_key(Kind, Key, Ms, PK)
    ->  (   PK == Self -> B = self
        ;   get_assoc(PK, Ids, Id) -> B = ref(Id)
        ;   B = none
        )
    ;   B = none
    ).

flow_badge_w(none, 0).
flow_badge_w(ref(_), 21).
flow_badge_w(self, 17).

flow_tip(G, Kind, Det, Names, Tip) :-
    flow_term_full(G, Names, 1200, T),
    flow_kind_word(Kind, KW),
    flow_det_text(Det, DT),
    format(atom(Tip), '~w  --  ~w, ~w', [T, KW, DT]).

flow_kind_word(user, 'your predicate') :- !.
flow_kind_word(dynamic, 'dynamic: its clauses are made and unmade as the program runs') :- !.
flow_kind_word(library(L), W) :- !, flow_lib_name(L, N), format(atom(W), 'library(~w)', [N]).
flow_kind_word(builtin, 'builtin, C in the engine') :- !.
flow_kind_word(test, test) :- !.
flow_kind_word(unify, unification) :- !.
flow_kind_word(portal(M), W) :- !, format(atom(W), 'C function of library(~w), not traced', [M]).
flow_kind_word(unknown, 'defined nowhere the chart can see: calling it is an existence error') :- !.
flow_kind_word(closure, 'a goal known only when it runs') :- !.
flow_kind_word(_, 'a goal known only when it runs').

flow_m_head(H, CM, Names, HF, Id, mhead(Segs, HF, W, tip(Tip, Id))) :-
    flow_goal_segs(H, CM, Names, Segs),
    flow_segs_w(Segs, TW),
    W is TW + 22,
    flow_segs_atom(Segs, T),
    (   HF == true
    ->  atom_concat(T, '  --  the clause head: unifying it can fail', Tip)
    ;   atom_concat(T, '  --  the clause head: unifying it cannot fail', Tip)
    ).

%% ======================================================================
%% Placing: items on a main line, emitting layered primitives
%% ======================================================================
%%
%% A primitive is drawn in a LAYER -- 0 backgrounds, 1 lines, 2 boxes,
%% 3 text and marks -- so lines pass under boxes whatever order they are
%% made in; site(Id, Y) is no drawing, it tells the panel where a call to
%% panel Id stands, for its wire.

flow_p(mg(Kind, Segs, Badge, ND, CF, W, Tip), X, Y, Prims, it(X, W, B, CF, ND, false)) :- !,
    T is Y - 13,
    B is Y + 13,
    flow_box_style(Kind, Fill, Stroke, Dash),
    (   Kind == test
    ->  X1 is X + 7, X2 is X + W - 7, XR is X + W,
        Shape = pg([X-Y, X1-T, X2-T, XR-Y, X2-B, X1-B], Fill, Stroke, 1)
    ;   Shape = r(X, T, W, 26, 5, Fill, Stroke, 1, Dash)
    ),
    (   ND == true -> NW = 13 ; NW = 0 ),
    (   Kind == test -> HX = 6 ; HX = 0 ),
    TX is X + 9 + NW + HX,
    TY is Y + 4,
    (   ND == true
    ->  GX is X + 8,
        Glyph = [t(GX, TY, start, 11, sans, normal, [s('↻', muted)])]
    ;   Glyph = []
    ),
    flow_portal_plaque(Kind, X, W, Badge, Y, Plaque),
    flow_badge_prims(Badge, Kind, X, W, Y, BadgePs),
    append([[Shape, t(TX, TY, start, 12, mono, normal, Segs)], Glyph, Plaque, BadgePs], Inner),
    (   Badge = ref(Id) -> Site = [9-site(Id, Y)] ; Site = [] ),
    Prims = [2-grp(Tip, Inner)|Site].
flow_p(mhead(Segs, HF, W, Tip), X, Y,
       [2-grp(Tip, [r(X, T, W, 26, 13, '#eef0ff', '#5a5fcf', 1, none),
                    t(TX, TY, start, 12, mono, normal, Segs)])],
       it(X, W, B, HF, false, false)) :- !,
    T is Y - 13, B is Y + 13, TX is X + 11, TY is Y + 4.
flow_p(mcut, X, Y,
       [2-grp('!  --  the cut: it commits to this clause, and nothing to its left is tried again',
              [r(RX, T, 8, 24, 2, '#d97706', none, 0, none),
               t(CX, TY, middle, 11, sans, bold, [s('!', white)])])],
       it(X, 14, B, false, false, true)) :- !,
    RX is X + 3, T is Y - 12, B is Y + 13, CX is X + 7, TY is Y + 4.
flow_p(mfail(W), X, Y,
       [2-grp('fail  --  always fails',
              [r(X, T, W, 26, 5, '#fff1f1', '#d62828', 1, none),
               t(TX, TY, start, 12, mono, normal, [s(fail, red)])])],
       it(X, W, B, true, false, false)) :- !,
    T is Y - 13, B is Y + 13, TX is X + 9, TY is Y + 4.
flow_p(mthrow(Segs, W), X, Y,
       [2-grp('throw  --  leaves through the nearest catch/3',
              [r(X, T, W, 26, 5, '#f7f0ff', '#7e22ce', 1, none),
               t(TX, TY, start, 12, mono, normal, Segs)])],
       it(X, W, B, false, false, false)) :- !,
    T is Y - 13, B is Y + 13, TX is X + 9, TY is Y + 4.
flow_p(mframe(Is, W, A, D), X, Y, Prims, it(X, W, B, false, false, false)) :- !,
    T is Y - A,
    B is Y + D,
    H is A + D,
    LX is X + 6,
    LY is T + 10,
    IX is X + 8,
    flow_p_items(Is, IX, Y, IPs, _, _),
    Prims = [1-r(X, T, W, H, 5, none, '#c08a00', 1, '3 2'),
             3-t(LX, LY, start, 9, sans, bold, [s('if', amber)])|IPs].
flow_p(mcon(Type, Label, Tracks, W, A, D, CF, ND), X, Y, Prims, it(X, W, B, CF, ND, false)) :-
    T is Y - A,
    B is Y + D,
    H is A + D,
    XR is X + W - 11,
    LX is X + 8,
    LY is T + 13,
    flow_label_prims(Label, LX, LY, LPs),
    flow_p_tracks(Tracks, X, Y, TPs, TInfo),
    flow_con_wires(Type, X, Y, XR, W, TInfo, WPs),
    append([[0-r(X, T, W, H, 7, '#f5f7fa', '#b8c4d0', 1, none)], LPs, WPs, TPs], Prims).

flow_label_prims(lbl(A), X, Y, [3-t(X, Y, start, 10, sans, normal, [s(A, muted)])]).
flow_label_prims(segs(Ss), X, Y, [3-t(X, Y, start, 11, mono, normal, Ss)]).

flow_p_items([], X, _, [], X, []).
flow_p_items([I|Is], X, Y, Prims, XE, [Info|Infos]) :-
    flow_p(I, X, Y, P1, Info),
    flow_size(I, W, _, _),
    (   Is == []
    ->  XE is X + W, P2 = [], Infos = []
    ;   X1 is X + W + 22,
        flow_p_items(Is, X1, Y, P2, XE, Infos)
    ),
    append(P1, P2, Prims).

%% the tracks of a construct, top to bottom; tk(XStart, Y, XEnd, Descent, Infos)
flow_p_tracks([], _, _, [], []).
flow_p_tracks([t(Off, Is, _, _, TD)|Ts], X, Y, Prims, [tk(XS, Y, XE, TD, Infos)|TIs]) :-
    XS is X + 12 + Off,
    flow_p_items(Is, XS, Y, P1, XE0, Infos),
    (   Is == [] -> XE is XS + 24 ; XE = XE0 ),
    (   Ts = [t(_, _, _, TA2, _)|_] -> Y2 is Y + TD + 16 + TA2 ; Y2 = Y ),
    flow_p_tracks(Ts, X, Y2, P2, TIs),
    append(P1, P2, Prims).

flow_con_wires(Type, X, Y, XR, W, TInfo, Prims) :-
    TInfo = [tk(XS1, _, _, _, _)|_],
    XW is X + W,
    flow_track_lines(TInfo, XR, Lines),
    last(TInfo, tk(_, YL, _, _, _)),
    (   YL =\= Y -> Rail = [1-l([XR-YL, XR-Y], ink, 1.4, none, none)] ; Rail = [] ),
    Entry = [1-l([X-Y, XS1-Y], ink, 1.4, none, none), 1-l([XR-Y, XW-Y], ink, 1.4, none, none)],
    flow_con_extra(Type, TInfo, Extra),
    append([Entry, Lines, Rail, Extra], Prims).

flow_track_lines([], _, []).
flow_track_lines([tk(XS, YK, _, _, _)|Ts], XR, [1-l([XS-YK, XR-YK], ink, 1.4, none, none)|Ls]) :-
    flow_track_lines(Ts, XR, Ls).

flow_con_extra(ite, TInfo, Ps) :- !, flow_else_drops(TInfo, Ps).
flow_con_extra(or, TInfo, Ps) :- !, flow_or_retries(TInfo, Ps).
flow_con_extra(catch, [tk(XS1, Y1, _, TD1, _), tk(XS2, Y2, _, _, _)],
               [1-l([DX-DY, DX-Y2, XS2-Y2], purple, 1.2, '4 3', purple),
                3-t(LX, LY, start, 9, sans, bold, [s(throw, purple)])]) :- !,
    DX is XS1 + 10, DY is Y1 + TD1, LX is DX + 5, LY is DY + 11.
flow_con_extra(_, _, []).

%% the condition fails: down, and into the next arm
flow_else_drops([T1, T2|Ts], Ps) :-
    T1 = tk(_, _, _, _, [it(FX, _, FB, _, _, _)|_]), !,
    T2 = tk(XS2, Y2, _, _, _),
    DX is FX + 10, LX is DX + 5, LY is FB + 11,
    Ps = [1-l([DX-FB, DX-Y2, XS2-Y2], amber, 1.2, '4 3', amber),
          3-t(LX, LY, start, 9, sans, bold, [s(else, amber)])|Rest],
    flow_else_drops([T2|Ts], Rest).
flow_else_drops(_, []).

%% a branch fails: down the inner rail, into the next branch
flow_or_retries([T1, T2|Ts], [1-l([XL-Y0, XL-Y2, XS2-Y2], red, 1.2, '4 3', red)|Rest]) :- !,
    T1 = tk(XS1, Y1, _, TD1, _),
    T2 = tk(XS2, Y2, _, _, _),
    XL is XS1 - 9,
    Y0 is Y1 + TD1 + 3,
    flow_or_retries([T2|Ts], Rest).
flow_or_retries(_, []).

flow_box_style(user, '#ffffff', '#52606d', none) :- !.
flow_box_style(dynamic, '#f3f7fd', '#33507a', '6 2') :- !.
flow_box_style(library(_), '#ffffff', '#8a97a5', '4 3') :- !.
flow_box_style(builtin, '#eef1f4', '#a3aeb9', none) :- !.
flow_box_style(test, '#fff7df', '#c08a00', none) :- !.
flow_box_style(unify, '#eef1f4', '#a3aeb9', none) :- !.
flow_box_style(portal(_), '#e3f4f1', '#0f766e', none) :- !.
flow_box_style(unknown, '#fff5f5', '#d62828', '3 3') :- !.
flow_box_style(_, '#ffffff', '#7e22ce', '3 3').

flow_portal_plaque(portal(_), X, W, Badge, Y,
                   [r(PX, PY, 13, 16, 3, '#0f766e', none, 0, none),
                    t(TX, TY, middle, 10, sans, bold, [s('C', white)])]) :- !,
    flow_badge_w(Badge, BW),
    PX is X + W - BW - 17,
    PY is Y - 8,
    TX is PX + 7,
    TY is Y + 4.
flow_portal_plaque(_, _, _, _, _, []).

flow_badge_prims(none, _, _, _, _, []).
flow_badge_prims(self, _, X, W, Y, [t(CX, TY, middle, 14, sans, normal, [s('↺', ink)])]) :-
    CX is X + W - 10,
    TY is Y + 5.
flow_badge_prims(ref(Id), Kind, X, W, Y,
                 [c(CX, Y, 8, Col, none, 0), t(CX, TY, middle, 9, sans, bold, [s(IdA, white)])]) :-
    CX is X + W - 12,
    TY is Y + 3,
    flow_badge_col(Kind, Col),
    number_codes(Id, Cs),
    atom_codes(IdA, Cs).

flow_badge_col(user, '#33507a') :- !.
flow_badge_col(dynamic, '#33507a') :- !.
flow_badge_col(library(_), '#6b7785') :- !.
flow_badge_col(portal(_), '#0f766e') :- !.
flow_badge_col(query, '#3d3d6b') :- !.
flow_badge_col(_, '#6b7785').

%% ======================================================================
%% A clause row, and the lane under it that says where failure goes
%% ======================================================================
%%
%% Item k can fail. Its failure goes to the nearest item j < k that can
%% redo -- unless a cut stands between them, which removed that choice and
%% every clause below: then the whole call fails ("fail !"). With nothing
%% left of k to redo, it goes down the rail to the next clause. Backtracking
%% INTO the clause after it exited arrives at the row's end (the redo mark)
%% and goes the same way. Because the target is always the NEAREST, two
%% failures whose spans overlap share their target, and each target's
%% lane is one line: the lanes never cross.

flow_m_row(row(I, H, Names, HF, Nodes, _), CM, Ids, Self, PId, mrow(I, Items, A, D, W)) :-
    atomic_list_concat([PId, '.c', I], Base),
    LC = lc(Names, Ids, Self, Base),
    flow_m_list(Nodes, LC, BIs),
    (   H == none -> Items = BIs
    ;   atom_concat(Base, '.h', HId),
        flow_m_head(H, CM, Names, HF, HId, MH), Items = [MH|BIs]
    ),
    flow_track_size(Items, W0, A, D),
    flow_row_tail(Items, Tail),
    W is W0 + Tail.

%% a row that ends in a cut keeps room after it: its redo runs back to the
%% cut's tag, and the tag is centred under the cut
flow_row_tail(Items, Tail) :-
    (   append(_, [mcut], Items) -> Tail = 16 ; Tail = 0 ).

flow_m_rows([], _, _, _, _, []).
flow_m_rows([R|Rs], CM, Ids, Self, PId, [M|Ms]) :-
    flow_m_row(R, CM, Ids, Self, PId, M),
    flow_m_rows(Rs, CM, Ids, Self, PId, Ms).

flow_rows_maxw([], M, M).
flow_rows_maxw([mrow(_, _, _, _, W)|Rs], M0, M) :-
    M1 is max(M0, W),
    flow_rows_maxw(Rs, M1, M).

%% A failure with nothing left to redo in its clause goes left along its
%% lane to the rail, and down the rail into the next clause; from the LAST
%% clause the lane runs on through the panel's left border at its own
%% height -- that is the fail port -- so it reaches the border straight.
flow_p_rows([], _, Top, _, _, [], [], Top).
flow_p_rows([MR|MRs], X0, Top, RailX, ExitX, Prims, [G|Gs], Bottom) :-
    (   MRs == [] -> LaneEnd = port ; LaneEnd = rail(RailX) ),
    flow_p_row(MR, X0, Top, LaneEnd, ExitX, P1, G),
    G = row_geo(_, _, _, RB, _),
    Top2 is RB + 4,
    flow_p_rows(MRs, X0, Top2, RailX, ExitX, P2, Gs, Bottom),
    append(P1, P2, Prims).

flow_p_row(mrow(I, Items, A, D, _), X0, Top, LaneEnd, ExitX, Prims, row_geo(I, Y, YF, Bottom, RailHit)) :-
    Y is Top + A,
    flow_p_items(Items, X0, Y, IPs, XE, Infos),
    YF is Y + D + 12,
    flow_row_tail(Items, Tail),
    RowEnd is XE + 12 + Tail,
    flow_lanes(Infos, RowEnd, LaneEnd, YF, LPs, RailHit, Tags),
    (   Tags == true -> Extra = 6 ; Extra = 0 ),
    Bottom is YF + 12 + Extra,
    append([[1-l([X0-Y, ExitX-Y], ink, 1.4, none, none)], IPs, LPs], Prims).

flow_lanes(Infos, RowEnd, LaneEnd, YF, Prims, RailHit, Tags) :-
    flow_index(Infos, 1, Indexed),
    flow_fail_sources(Indexed, [], Srcs0),
    reverse(Indexed, RevAll),
    flow_fail_target(RevAll, EndT),
    Srcs = [src(EndT, RowEnd, end)|Srcs0],
    findall(T, member(src(T, _, _), Srcs), Ts0),
    sort(Ts0, Ts),
    flow_lane_groups(Ts, Srcs, Indexed, LaneEnd, YF, GPs),
    flow_stubs(Srcs, YF, SPs),
    (   memberchk(rail, Ts) -> RailHit = true ; RailHit = false ),
    (   memberchk(cutfail(_), Ts) -> Tags = true ; Tags = false ),
    append(GPs, SPs, Prims).

flow_index([], _, []).
flow_index([X|Xs], I, [I-X|R]) :- I1 is I + 1, flow_index(Xs, I1, R).

flow_fail_sources([], _, []).
flow_fail_sources([K-Info|Rest], RevPrefix, Srcs) :-
    Info = it(X, W, B, CF, _, _),
    (   CF == true
    ->  flow_fail_target(RevPrefix, T),
        SX is X + min(14, W // 3),
        Srcs = [src(T, SX, B)|Srcs1]
    ;   Srcs = Srcs1
    ),
    flow_fail_sources(Rest, [K-Info|RevPrefix], Srcs1).

flow_fail_target([], rail).
flow_fail_target([K-it(_, _, _, _, ND, Cut)|Rest], T) :-
    (   Cut == true -> T = cutfail(K)
    ;   ND == true -> T = item(K)
    ;   flow_fail_target(Rest, T)
    ).

flow_lane_groups([], _, _, _, _, []).
flow_lane_groups([T|Ts], Srcs, Indexed, LaneEnd, YF, Prims) :-
    findall(SX, member(src(T, SX, _), Srcs), SXs),
    max_list(SXs, MaxX),
    flow_lane_group(T, MaxX, Indexed, LaneEnd, YF, P1),
    flow_lane_groups(Ts, Srcs, Indexed, LaneEnd, YF, P2),
    append(P1, P2, Prims).

%% to the rail, which takes it down into the next clause; from the last
%% clause, through the border: out of the panel, as its fail port
flow_lane_group(rail, MaxX, _, rail(RailX), YF, [1-l([MaxX-YF, RailX-YF], red, 1.2, '4 3', none)]).
flow_lane_group(rail, MaxX, _, port, YF, [1-l([MaxX-YF, 0-YF], red, 1.2, '4 3', red)]).
flow_lane_group(item(K), MaxX, Indexed, _, YF, [1-l([MaxX-YF, NX-YF, NX-BK], red, 1.2, '4 3', red)]) :-
    memberchk(K-it(XK, WK, BK, _, _, _), Indexed),
    NX is XK + WK - min(14, WK // 3).
%% past a cut: the lane runs back to the cut and stops at its tag
flow_lane_group(cutfail(K), MaxX, Indexed, _, YF, [1-l([MaxX-YF, TR-YF], red, 1.2, '4 3', none)|Tag]) :-
    memberchk(K-it(XK, WK, _, _, _, _), Indexed),
    CX is XK + WK // 2,
    TR is CX + 17,
    flow_cut_tag(CX, YF, Tag).

flow_cut_tag(CX, Y, [3-grp('fail !  --  the cut removed every alternative: the whole call fails',
                           [r(TX, TY, 34, 14, 3, '#d62828', none, 0, none),
                            t(CX, LY, middle, 8, sans, bold, [s('fail !', white)])])]) :-
    TX is CX - 17,
    TY is Y - 7,
    LY is Y + 3.

flow_stubs([], _, []).
flow_stubs([src(_, SX, B)|Ss], YF, Prims) :-
    flow_stub(SX, B, YF, P1),
    flow_stubs(Ss, YF, P2),
    append(P1, P2, Prims).

flow_stub(SX, end, YF, [3-grp('redo  --  backtracking into this clause after it exited starts here',
                              [t(SX, GY, middle, 13, sans, bold, [s('↶', red)])])]) :- !,
    GY is YF + 5.
flow_stub(SX, B, YF, [1-l([SX-B, SX-YF], red, 1.2, '4 3', none)]).

%% ======================================================================
%% Panels, drawn at their own origin
%% ======================================================================
%%
%% pd(Id, Depth, Width, Height, CallY, Jacks, Prims): CallY is where the
%% call port is, Jacks where its own calls leave for the panels they call.

flow_draw(P, Ids, DMap, KMap, Docs, PD) :-
    P = panel(_, _, Kind, _, _, Body, _, _),
    (   Body = stub(_, _, _) -> flow_draw_stub(P, Docs, PD)
    ;   Kind == query -> flow_draw_query(P, Ids, DMap, KMap, Docs, PD)
    ;   Kind = portal(_) -> flow_draw_portal(P, PD)
    ;   flow_draw_rows(P, Ids, DMap, KMap, Docs, PD)
    ).

%% a panel not drawn: its head, why, and how much hangs from it
flow_draw_stub(panel(Id, Key, Kind, CM, D, stub(N, Rule, Body), Det, _), Docs,
               pd(Id, D, W, H, 48, [], Prims)) :-
    (   Body = rows(Rows) -> true ; Rows = [] ),
    flow_panel_head(Key, CM, Rows, Docs, HeadSegs),
    flow_det_text(Det, DT),
    (   Rule = rule(Depth, Ps), Depth \== all, D > Depth
    ->  format(atom(L2), 'not drawn: deeper than depth(~w)', [Depth])
    ;   Rule = rule(_, Ps), Ps \== all
    ->  L2 = 'not drawn: not one of only(...)'
    ;   L2 = 'not drawn'
    ),
    (   N =:= 0 -> L3 = 'the XML has it in full'
    ;   N =:= 1 -> L3 = '1 more panel hangs from it  ·  the XML has them all'
    ;   format(atom(L3), '~d more panels hang from it  ·  the XML has them all', [N])
    ),
    flow_segs_w(HeadSegs, HW),
    flow_chars(L2, N2), flow_chars(L3, N3),
    W2 is (N2 * 62 + 9) // 10, W3 is (N3 * 62 + 9) // 10,
    W is max(34 + HW + 120, max(W2, W3) + 32),
    H = 84,
    flow_panel_frame(Id, Kind, W, H, HeadSegs, DT, FramePs),
    Body1 = [1-l([0-48, 12-48], ink, 1.4, none, ink),
             3-t(16, 52, start, 10, sans, normal, [s(L2, muted)]),
             3-t(16, 70, start, 10, sans, normal, [s(L3, muted)])],
    append(FramePs, Body1, Prims).

flow_draw_rows(panel(Id, Key, Kind, CM, D, rows(Rows), Det, _), Ids, DMap, KMap, Docs,
               pd(Id, D, W, H, CallY, Jacks, Prims)) :-
    flow_panel_head(Key, CM, Rows, Docs, HeadSegs),
    flow_doc_rows(Key, Kind, Docs, Rows, DRows),
    flow_panel_key(Kind, Key, CM, Self),
    flow_panel_id(Id, PId),
    flow_m_rows(DRows, CM, Ids, Self, PId, MRows),
    flow_rows_maxw(MRows, 0, MW),
    flow_segs_w(HeadSegs, HW),
    length(Rows, NC),
    flow_panel_tag(Kind, Det, NC, Tag),
    flow_chars(Tag, TN),
    TagW is (TN * 62 + 9) // 10,
    W is max(34 + MW + 26 + 16, 34 + HW + max(140, TagW + 30)),
    ExitX is W - 14,
    flow_p_rows(MRows, 34, 44, 16, ExitX, RowPs, Geos, Bottom),
    Geos = [row_geo(_, CallY, _, _, _)|_],
    MinY is CallY + 18,
    flow_jacks(RowPs, D, DMap, KMap, W, MinY, Jacks, JackPs),
    %% room under the last lane for the fail port's word, and for every jack
    findall(JY, member(jk(_, JY), Jacks), JYs),
    max_list([0|JYs], MaxJY),
    H is max(Bottom + 8, MaxJY + 12),
    flow_panel_frame(Id, Kind, W, H, HeadSegs, Tag, FramePs),
    flow_panel_ports(Geos, W, ExitX, PortPs),
    exclude(flow_is_site, RowPs, RowPs1),
    append([FramePs, PortPs, RowPs1, JackPs], Prims).

flow_is_site(9-site(_, _)).

%% a library clause read back with clause/2 has letters for names; its
%% head's variables take the names its library's header documents
flow_doc_rows(Key, library(_), Docs, Rows0, Rows) :-
    get_assoc(Key, Docs, sig(_, DNs, _)), !,
    findall(R, ( member(R0, Rows0), flow_doc_row(R0, DNs, R) ), Rows).
flow_doc_rows(_, _, _, Rows, Rows).

flow_doc_row(row(I, H, Names, HF, Nodes, CI), DNs, row(I, H, Names1, HF, Nodes, CI)) :-
    H =.. [_|Args],
    flow_rename_args(Args, DNs, Names, Names1).

flow_rename_args([], _, Ns, Ns).
flow_rename_args([A|As], [D|Ds], Ns0, Ns) :-
    (   var(A) -> flow_rename_var(Ns0, A, D, Ns1) ; Ns1 = Ns0 ),
    flow_rename_args(As, Ds, Ns1, Ns).

flow_rename_var([], _, _, []).
flow_rename_var([N=V|T], A, D, [N1=V|T1]) :-
    (   V == A -> N1 = D ; N1 = N ),
    flow_rename_var(T, A, D, T1).

flow_panel_tag(user, Det0, NC, Tag) :- !,
    flow_det_text(Det0, Det),
    flow_plural(NC, clause, Cl),
    format(atom(Tag), '~w  ·  ~d ~w', [Det, NC, Cl]).
flow_panel_tag(library(L), Det0, NC, Tag) :- !,
    flow_det_text(Det0, Det),
    flow_lib_name(L, LN),
    flow_plural(NC, clause, Cl),
    format(atom(Tag), 'library(~w)  ·  ~w  ·  ~d ~w', [LN, Det, NC, Cl]).
flow_panel_tag(dynamic, Det0, NC, Tag) :- !,
    flow_det_text(Det0, Det),
    flow_plural(NC, clause, Cl),
    format(atom(Tag), 'dynamic  ·  ~w  ·  starts with ~d ~w', [Det, NC, Cl]).
flow_panel_tag(_, Det0, _, Det) :- flow_det_text(Det0, Det).

flow_plural(1, W, W) :- !.
flow_plural(_, W, P) :- atom_concat(W, s, P).

flow_panel_frame(Id, Kind, W, H, HeadSegs, Tag, Prims) :-
    flow_panel_fill(Kind, HFill),
    flow_badge_col(Kind, BCol),
    flow_id_atom(Id, IdA),
    W2 is W - 2,
    W1 is W - 1,
    TX is W - 10,
    Prims = [0-r(0, 0, W, H, 8, '#fbfcfd', '#c3ccd6', 1, none),
             0-r(1, 1, W2, 29, 7, HFill, none, 0, none),
             0-r(1, 20, W2, 10, 0, HFill, none, 0, none),
             0-l([1-30, W1-30], '#d5dce4', 1, none, none),
             3-c(17, 15, 10, BCol, none, 0),
             3-t(17, 19, middle, 11, sans, bold, [s(IdA, white)]),
             3-t(34, 20, start, 12, mono, bold, HeadSegs),
             3-t(TX, 19, end, 10, sans, normal, [s(Tag, muted)])].

flow_id_atom(query, '?-') :- !.
flow_id_atom(Id, A) :- number_codes(Id, Cs), atom_codes(A, Cs).

flow_panel_fill(user, '#e8eef6') :- !.
flow_panel_fill(dynamic, '#e3ebf8') :- !.
flow_panel_fill(library(_), '#eef0f2') :- !.
flow_panel_fill(portal(_), '#dcf1ed') :- !.
flow_panel_fill(_, '#e9e9f3').

%% Byrd's ports: call at the top left, exit at the top right, fail at the
%% bottom left -- where the last clause's lane leaves through the border;
%% the left rail carries each other clause's failure to the next
flow_panel_ports(Geos, W, ExitX, Prims) :-
    Geos = [row_geo(_, Y1, _, _, _)|_],
    last(Geos, row_geo(_, YL, _, _, _)),
    LY is Y1 - 8,
    EX is W - 3,
    Ports = [1-l([0-Y1, 9-Y1], ink, 1.4, none, ink),
             3-t(2, LY, start, 8, sans, normal, [s(call, muted)]),
             1-l([ExitX-Y1, W-Y1], ink, 1.4, none, ink),
             3-t(EX, LY, end, 8, sans, normal, [s(exit, muted)])],
    (   YL =\= Y1 -> Rail = [1-l([ExitX-YL, ExitX-Y1], ink, 1.4, none, none)] ; Rail = [] ),
    flow_markers(Geos, Marks),
    flow_retries(Geos, Retries),
    append([Ports, Rail, Marks, Retries], Prims).

flow_markers([], []).
flow_markers([row_geo(I, Y, _, _, _)|Gs], [1-l([23-Y, 34-Y], ink, 1.4, none, none),
                                           3-c(16, Y, 7, '#ffffff', '#1f2933', 1.2),
                                           3-t(16, TY, middle, 8, sans, bold, [s(IA, ink)])|Ms]) :-
    TY is Y + 3,
    number_codes(I, Cs),
    atom_codes(IA, Cs),
    flow_markers(Gs, Ms).

%% the last clause's lane is its own way out (flow_lane_group/6): here it
%% only gets its word, under the arrow
flow_retries([], []).
flow_retries([row_geo(_, _, YF, _, Hit)|Gs], Prims) :-
    (   Hit == true
    ->  (   Gs = [row_geo(_, YN, _, _, _)|_]
        ->  YT is YN - 8,
            P1 = [1-l([16-YF, 16-YT], red, 1.2, '4 3', red)]
        ;   LY is YF + 11,
            P1 = [3-t(3, LY, start, 8, sans, normal, [s(fail, red)])]
        )
    ;   P1 = []
    ),
    flow_retries(Gs, P2),
    append(P1, P2, Prims).

%% where this panel's calls leave it: one jack per panel called in the
%% next column, level with the first call to it, spaced to stay apart
flow_jacks(Prims, D, DMap, KMap, W, MinY, Jacks, JackPs) :-
    findall(C-Y, member(9-site(C, Y), Prims), Sites),
    flow_first_per_key(Sites, [], Firsts),
    D1 is D + 1,
    include(flow_wired(DMap, D1), Firsts, Wired),
    findall(Y-C, member(C-Y, Wired), YC),
    keysort(YC, Sorted),
    flow_space(Sorted, MinY, Spaced),
    flow_jack_prims(Spaced, KMap, W, JackPs),
    findall(jk(C, JY), member(C-JY, Spaced), Jacks).


flow_wired(DMap, D1, C-_) :-
    get_assoc(C, DMap, DC),
    DC =:= D1.

flow_space([], _, []).
flow_space([Y-C|T], Min, [C-JY|R]) :-
    JY is max(Y, Min),
    Min2 is JY + 16,
    flow_space(T, Min2, R).

flow_jack_prims([], _, _, []).
flow_jack_prims([C-JY|T], KMap, W, [3-c(W, JY, 4, Col, none, 0),
                                    3-t(LX, LY, end, 8, sans, bold, [s(CA, Col)])|R]) :-
    get_assoc(C, KMap, K),
    flow_badge_col(K, Col),
    LX is W - 7,
    LY is JY + 3,
    flow_id_atom(C, CA),
    flow_jack_prims(T, KMap, W, R).

flow_draw_query(panel(_, _, _, _, D, rows([row(_, _, Names0, _, [GNode], _)]), _, _), Ids, DMap, KMap, Docs,
                pd(0, D, W, H, 56, Jacks, Prims)) :-
    GNode = g(G, _, _, _, Key, _),
    (   get_assoc(Key, Docs, sig(_, DNs, _)), G =.. [_|Vs], flow_pair_names(DNs, Vs, Names1)
    ->  Names = Names1
    ;   Names = Names0
    ),
    flow_m(GNode, lc(Names, Ids, none, 'query.g1'), MG),
    flow_size(MG, GW, _, _),
    W is max(16 + GW + 24, 184),          % room for its title and its tag
    H = 84,
    flow_p(MG, 16, 56, GPs, _),
    flow_panel_frame(query, query, W, H, [s(query, ink)], 'what was asked', FramePs),
    flow_jacks(GPs, D, DMap, KMap, W, 56, Jacks, JackPs),
    exclude(flow_is_site, GPs, GPs1),
    append([FramePs, GPs1, JackPs], Prims).

flow_draw_portal(panel(Id, N/A, portal(Mod), _, D, portal(info(CFun, File, Line, Modes, Names)), _, _),
                 pd(Id, D, W, H, 48, [], Prims)) :-
    functor(G, N, A),
    G =.. [_|Vs],
    (   flow_pair_names(Names, Vs, NVs0) -> NVs = NVs0 ; flow_gen_names(G, NVs) ),
    flow_moded_head(G, Modes, NVs, SigSegs),
    format(atom(Title), '~w/~w', [N, A]),
    format(atom(L2), 'library(~w)  ·  ~w()', [Mod, CFun]),
    format(atom(L3), '~w:~w', [File, Line]),
    flow_segs_w(SigSegs, SW),
    flow_chars(L2, N2), flow_chars(L3, N3),
    W2 is (N2 * 62 + 9) // 10, W3 is (N3 * 60 + 9) // 10,
    flow_chars(Title, NT), flow_text_w(NT, TW),
    W is max(max(SW, TW + 90), max(W2, W3)) + 40,
    H = 104,
    flow_panel_frame(Id, portal(Mod), W, H, [s(Title, ink)], 'C portal', FramePs),
    Body = [1-l([0-48, 12-48], ink, 1.4, none, ink),
            3-t(16, 52, start, 12, mono, normal, SigSegs),
            3-t(16, 70, start, 10, sans, normal, [s(L2, muted)]),
            3-t(16, 85, start, 10, mono, normal, [s(L3, muted)]),
            3-t(16, 98, start, 9, sans, normal, [s('C: the flow libraries do not look inside', muted)])],
    append(FramePs, Body, Prims).

flow_pair_names([], [], []).
flow_pair_names([N|Ns], [V|Vs], [N=V|R]) :- flow_pair_names(Ns, Vs, R).

%% ======================================================================
%% How much is drawn
%% ======================================================================
%%
%% THE XML IS NEVER PRUNED; THE PICTURE MAY BE. depth(D) draws the panels
%% at most D calls from the query, only(Preds) the panels of those
%% predicates (Name/Arity, or Name//Arity for a nonterminal), and a panel
%% that a drawn one calls but that is not drawn itself is a STUB: its head,
%% why it is not drawn, and how many panels hang from it. A C function is
%% always drawn when its caller is: it is where the chart ends. With
%% neither option, a chart of more than flow_panel_budget/1 panels is drawn
%% to the deepest level that fits with its stubs, and says so under its
%% title: the translator's is 2898 panels, a 148 MB SVG nobody can read.

flow_panel_budget(150).

flow_prune(graph(T, S, Panels, Ids, Docs), Opts, graph(T, S, Kept, Ids, Docs), Note) :-
    flow_draw_rule(Panels, Opts, Rule),
    (   Rule == all
    ->  Kept = Panels, Note = none
    ;   flow_drawn(Panels, Rule, Drawn),
        flow_frontier(Panels, Ids, Drawn, Stubs0),
        findall(I, ( member(I, Stubs0), memberchk(panel(I, _, portal(_), _, _, _, _, _), Panels) ), Ports),
        subtract(Stubs0, Ports, Stubs),
        append(Drawn, Ports, Drawn1),
        flow_hidden_counts(Panels, Ids, Drawn1, Stubs, Counts),
        findall(P, ( member(P0, Panels), flow_keep(P0, Drawn1, Stubs, Counts, Rule, P) ), Kept),
        length(Panels, NP0), NP is NP0 - 1,
        length(Drawn1, ND0), ND is ND0 - 1,
        length(Stubs, NS),
        flow_prune_note(Rule, ND, NS, NP, Note)
    ).

%% all, or rule(Depth, Preds): Depth an integer or all, Preds a list or all
flow_draw_rule(Panels, Opts, Rule) :-
    (   memberchk(depth(D0), Opts) -> true ; D0 = auto ),
    (   memberchk(only(Ps), Opts) -> true ; Ps = all ),
    (   D0 == auto
    ->  length(Panels, NP0), NP is NP0 - 1,
        flow_panel_budget(B),
        (   Ps == all, NP > B -> flow_auto_depth(Panels, B, D) ; D = all )
    ;   D = D0
    ),
    (   D == all, Ps == all -> Rule = all ; Rule = rule(D, Ps) ).

%% the deepest level whose panels, and the stubs one level further, fit
flow_auto_depth(Panels, B, D) :-
    findall(PD, ( member(panel(I, _, _, _, PD, _, _, _), Panels), I > 0 ), Ds),
    max_list(Ds, Max),
    flow_auto_depth_(1, Max, Ds, B, 1, D).

flow_auto_depth_(E, Max, Ds, B, D0, D) :-
    (   E >= Max -> D = D0
    ;   E1 is E + 1,
        include(>=(E1), Ds, Upto),
        length(Upto, N),
        (   N =< B -> flow_auto_depth_(E1, Max, Ds, B, E, D) ; D = D0 )
    ).

flow_drawn(Panels, rule(D, Ps), Drawn) :-
    findall(I, ( member(panel(I, Key, _, _, PD, _, _, _), Panels),
                 (   I =:= 0 -> true
                 ;   ( D == all -> true ; PD =< D ),
                     ( Ps == all -> true ; flow_only_has(Ps, Key) )
                 ) ),
            Drawn).

flow_only_has(Ps, N/A) :-
    (   memberchk(N/A, Ps) -> true
    ;   A2 is A - 2, A2 >= 0, memberchk(N//A2, Ps)
    ).

%% the panels a drawn panel calls that are not drawn themselves
flow_frontier(Panels, Ids, Drawn, Stubs) :-
    findall(C, ( member(panel(I, _, _, _, _, _, _, Calls), Panels), memberchk(I, Drawn),
                 member(c(Key, Kind, Ms), Calls),
                 flow_panel_key(Kind, Key, Ms, PK), get_assoc(PK, Ids, C),
                 \+ memberchk(C, Drawn) ),
            Cs),
    sort(Cs, Stubs).

%% how many panels hang from each stub: those whose first callers, followed
%% back, reach it before anything drawn
flow_hidden_counts(Panels, Ids, Drawn, Stubs, Counts) :-
    findall(I-D, member(panel(I, _, _, _, D, _, _, _), Panels), DPairs),
    list_to_assoc(DPairs, DMap),
    flow_parents(Panels, DMap, Ids, Parents),
    findall(S, ( member(panel(I, _, _, _, _, _, _, _), Panels),
                 \+ memberchk(I, Drawn), \+ memberchk(I, Stubs),
                 flow_hangs_from(I, Parents, Stubs, S) ),
            Ss),
    msort(Ss, Sorted),
    flow_count_runs(Sorted, Counts).

flow_hangs_from(I, Parents, Stubs, S) :-
    get_assoc(I, Parents, P),
    (   memberchk(P, Stubs) -> S = P ; flow_hangs_from(P, Parents, Stubs, S) ).

flow_count_runs([], []).
flow_count_runs([S|Ss], [S-N|Cs]) :-
    flow_count_same(Ss, S, 1, N, Rest),
    flow_count_runs(Rest, Cs).

flow_count_same([S|Ss], S, N0, N, Rest) :- !,
    N1 is N0 + 1,
    flow_count_same(Ss, S, N1, N, Rest).
flow_count_same(Rest, _, N, N, Rest).

%% a drawn panel as it is, a stub with nothing hanging from it in the
%% picture, and anything else not at all
flow_keep(P, Drawn, _, _, _, P) :-
    P = panel(I, _, _, _, _, _, _, _),
    memberchk(I, Drawn), !.
flow_keep(panel(I, Key, Kind, CM, D, Body, Det, _), _, Stubs, Counts, Rule,
          panel(I, Key, Kind, CM, D, stub(N, Rule, Body), Det, [])) :-
    memberchk(I, Stubs),
    (   memberchk(I-N, Counts) -> true ; N = 0 ).

flow_prune_note(rule(D, Ps), ND, NS, NP, Note) :-
    NH is NP - ND,
    (   Ps == all
    ->  format(atom(Why), 'to depth ~w', [D])
    ;   D == all
    ->  format(atom(Why), 'only ~w', [Ps])
    ;   format(atom(Why), 'to depth ~w, only ~w', [D, Ps])
    ),
    (   NS =:= 1 -> SW = 'stub marks' ; SW = 'stubs mark' ),
    format(atom(Note), '~d of ~d panels drawn, ~w  ·  ~d ~w where the other ~d begin  ·  the XML has every one  ·  depth(D) or only([Name/Arity, ...]) draws others',
           [ND, NP, Why, NS, SW, NH]).

%% ======================================================================
%% The chart: panels in columns by call depth, wires through gutters
%% ======================================================================

flow_layout(Graph, Canvas) :-
    flow_findings(Graph, Fs),
    flow_layout(Graph, none, Fs, Canvas).

%% Note: what pruning left out, or none; Fs: the findings, marked on the
%% boxes they are about and listed under the chart
flow_layout(graph(Title, Src, Panels, Ids, Docs), Note, Fs, canvas(CW, CH, Items)) :-
    findall(I-D, member(panel(I, _, _, _, D, _, _, _), Panels), DPairs),
    list_to_assoc(DPairs, DMap),
    findall(I-K, member(panel(I, _, K, _, _, _, _, _), Panels), KPairs),
    list_to_assoc(KPairs, KMap),
    flow_draw_all(Panels, Ids, DMap, KMap, Docs, PDs),
    flow_parents(Panels, DMap, Ids, Parents),
    flow_place_tree(PDs, Parents, [], Placed),
    flow_tree_wires(Placed, Wires),
    findall(R, ( member(pp(_, _, X, _, W, _, _, _, _, _), Placed), R is X + W ), Rs),
    max_list(Rs, MaxR),
    findall(B, ( member(pp(_, _, _, Y, _, H, _, _, _, _), Placed), B is Y + H ), Bs),
    max_list(Bs, MaxB),
    flow_title_prims(Title, Src, Note, TitlePs0),
    flow_findings_summary(Fs, TitlePs0, TitlePs),
    flow_lines_w(TitlePs, TitleW),
    ListY is MaxB + 44,
    flow_findings_list(Fs, ListY, ListPs, ListH),
    flow_lines_w(ListPs, ListW),
    CW0 is max(max(MaxR + 32, 980), max(TitleW, ListW) + 32),
    LegendY is ListY + ListH,
    flow_legend(LegendY, CW0, LegendPs, LegendH),
    CW = CW0,
    CH is LegendY + LegendH + 20,
    findall(tr(X, Y, Ps, PId), ( member(pp(Id, _, X, Y, _, _, _, _, Ps0, _), Placed), flow_panel_id(Id, PId),
                                 flow_layered(Ps0, Ps1), flow_mark_findings(Ps1, PId, Fs, Ps) ), Groups),
    append([TitlePs, Groups, Wires, ListPs, LegendPs], Items).

flow_draw_all([], _, _, _, _, []).
flow_draw_all([P|Ps], Ids, DMap, KMap, Docs, [D|Ds]) :-
    flow_draw(P, Ids, DMap, KMap, Docs, D),
    flow_draw_all(Ps, Ids, DMap, KMap, Docs, Ds).

%% EACH PANEL STANDS JUST RIGHT OF THE PANEL THAT FIRST CALLS IT, level
%% with the jack its call leaves from, and moves down only as far as it
%% must to clear a panel already placed. A column shared by every panel at
%% one depth would put a callee as far right as the WIDEST panel of its
%% caller's depth, and its wire across the empty space that leaves.
flow_parents(Panels, DMap, Ids, Parents) :-
    empty_assoc(P0),
    flow_parents_(Panels, DMap, Ids, P0, Parents).

flow_parents_([], _, _, P, P).
flow_parents_([panel(Id, _, _, _, D, _, _, Calls)|Ps], DMap, Ids, P0, P) :-
    D1 is D + 1,
    flow_parent_calls(Calls, Id, D1, DMap, Ids, P0, P1),
    flow_parents_(Ps, DMap, Ids, P1, P).

flow_parent_calls([], _, _, _, _, P, P).
flow_parent_calls([c(Key, Kind, Ms)|Cs], Id, D1, DMap, Ids, P0, P) :-
    (   flow_panel_key(Kind, Key, Ms, PK), get_assoc(PK, Ids, C), \+ get_assoc(C, P0, _),
        get_assoc(C, DMap, DC), DC =:= D1
    ->  put_assoc(C, P0, Id, P1)
    ;   P1 = P0
    ),
    flow_parent_calls(Cs, Id, D1, DMap, Ids, P1, P).

%% pp(Id, Depth, X, Y, W, H, CallY, Jacks, Prims, Lo): Lo is where the
%% corridor of the wire that comes into the panel begins (below)
flow_place_tree([], _, Placed, Placed).
flow_place_tree([PD|PDs], Parents, Acc, Placed) :-
    PD = pd(Id, D, W, H, CY, J, Ps),
    (   get_assoc(Id, Parents, Par),
        memberchk(pp(Par, _, PX, PY, PW, _, _, PJ, _, _), Acc),
        memberchk(jk(Id, JY), PJ)
    ->  length(PJ, NT),
        flow_gutter_w(NT, GW),
        GL is PX + PW,
        SY is PY + JY,
        Want is max(SY - CY, 84),
        flow_place_clear(GL, GW, SY, Want, W, H, CY, Par, Acc, X, Y, Lo)
    ;   X = 24, Lo = 24,
        flow_free_y(X, 84, W, H, Acc, Y)
    ),
    flow_place_tree(PDs, Parents, [pp(Id, D, X, Y, W, H, CY, J, Ps, Lo)|Acc], Placed).

flow_gutter_w(NT, W) :- W is 34 + NT * 18 + 26.

%% THE CORRIDOR. A call's wire runs right from its jack, along a track
%% down (or up) the gutter, and right again into the panel it calls, and a
%% wire never crosses a panel. A panel of the caller's column that is wider
%% than the caller can lie across the way down; then the callee moves right
%% of it, and the wire's track with it (Lo, the corridor's left edge), and
%% again for whatever stands there, until the corridor is clear.
flow_place_clear(Lo, GW, SY, Want, W, H, CY, Par, Acc, X, Y, LoOut) :-
    X0 is Lo + GW,
    flow_free_y(X0, Want, W, H, Acc, Y0),
    TY is Y0 + CY,
    YLo is min(SY, TY) - 8,
    YHi is max(SY, TY) + 8,
    findall(R, ( member(pp(Q, _, QX, QY, QW, QH, _, _, _, _), Acc), Q \== Par,
                 QX < X0, QX + QW > Lo, QY < YHi, QY + QH > YLo,
                 R is QX + QW ),
            Rs),
    (   Rs == []
    ->  X = X0, Y = Y0, LoOut = Lo
    ;   max_list(Rs, R),
        flow_place_clear(R, GW, SY, Want, W, H, CY, Par, Acc, X, Y, LoOut)
    ).

%% the first Y at or below Y0 where the panel overlaps nothing placed
flow_free_y(X, Y0, W, H, Placed, Y) :-
    (   member(pp(_, _, PX, PY, PW, PH, _, _, _, _), Placed),
        X < PX + PW + 24, PX < X + W + 24,
        Y0 < PY + PH + 28, PY < Y0 + H + 28
    ->  Y1 is PY + PH + 28,
        flow_free_y(X, Y1, W, H, Placed, Y)
    ;   Y = Y0
    ).

%% every jack's wire, through its own panel's gutter
flow_tree_wires(Placed, Wires) :-
    findall(Ws,
            ( member(pp(_, _, X, Y, W, _, _, Jacks, _, _), Placed),
              Jacks \== [],
              GL is X + W,
              findall(n(C, TY, [SY]),
                      ( member(jk(C, JY), Jacks),
                        memberchk(pp(C, _, _, CYp, _, _, CCY, _, _, _), Placed),
                        TY is CYp + CCY,
                        SY is Y + JY ),
                      Nets0),
              flow_order_nets(Nets0, Nets1),
              flow_moved_last(Nets1, GL, Placed, Nets),
              XT0 is GL + 16,
              flow_tree_route(Nets, XT0, GL, Placed, Ws) ),
            Wss),
    append(Wss, Wires).

%% a wire whose corridor moved right takes the last tracks: they are the
%% ones right of whatever stood in its way
flow_moved_last(Nets, GL, Placed, Out) :-
    findall(N, ( member(N, Nets), N = n(C, _, _),
                 memberchk(pp(C, _, _, _, _, _, _, _, _, Lo), Placed), Lo =< GL ), Clear),
    findall(Lo-N, ( member(N, Nets), N = n(C, _, _),
                    memberchk(pp(C, _, _, _, _, _, _, _, _, Lo), Placed), Lo > GL ), Moved0),
    keysort(Moved0, Moved1),
    findall(N, member(_-N, Moved1), Moved),
    append(Clear, Moved, Out).

flow_tree_route([], _, _, _, []).
flow_tree_route([n(C, TY, [SY])|Ns], Prev, GL, Placed, Wires) :-
    memberchk(pp(C, _, TX, _, _, _, _, _, _, Lo), Placed),
    XT is max(Prev + 18, Lo + 34),
    flow_wire(GL, SY, XT, TX, TY, W1),
    flow_tree_route(Ns, XT, GL, Placed, W2),
    append(W1, W2, Wires).

%% layers, in order, keeping the order things were made in within one
flow_layered(Ps0, Ps) :-
    keysort(Ps0, Sorted),
    findall(P, member(_-P, Sorted), Ps).

%% THE GUTTER. Each callee's wires share one vertical track; the tracks are
%% ordered so that as few horizontals as possible cross another's vertical.
%% A placed left of B costs one crossing for each of B's sources strictly
%% inside A's span, and one if A's target is strictly inside B's span.
flow_order_nets(Nets, Ordered) :-
    flow_insert_all(Nets, [], Ordered).

flow_insert_all([], O, O).
flow_insert_all([N|Ns], O0, O) :-
    flow_best_insert(N, O0, O1),
    flow_insert_all(Ns, O1, O).

flow_best_insert(N, O0, O) :-
    length(O0, Len),
    findall(Cost-Pos, ( between(0, Len, Pos), flow_insert_cost(N, O0, Pos, Cost) ), CPs),
    keysort(CPs, [_-Best|_]),
    flow_insert_at(O0, Best, N, O).

flow_insert_cost(N, O, Pos, Cost) :-
    length(Left, Pos),
    append(Left, Right, O),
    flow_cost_left(Left, N, C1),
    flow_cost_right(Right, N, C2),
    Cost is C1 + C2.

flow_cost_left([], _, 0).
flow_cost_left([M|Ms], N, C) :-
    flow_cross(M, N, C1),
    flow_cost_left(Ms, N, C2),
    C is C1 + C2.

flow_cost_right([], _, 0).
flow_cost_right([M|Ms], N, C) :-
    flow_cross(N, M, C1),
    flow_cost_right(Ms, N, C2),
    C is C1 + C2.

flow_cross(n(_, TA, SA), n(_, TB, SB), C) :-
    flow_span(TA, SA, LoA, HiA),
    flow_span(TB, SB, LoB, HiB),
    flow_inside(SB, LoA, HiA, K1),
    (   TA > LoB, TA < HiB -> K2 = 1 ; K2 = 0 ),
    C is K1 + K2.

flow_span(T, Ss, Lo, Hi) :-
    min_list([T|Ss], Lo),
    max_list([T|Ss], Hi).

flow_inside([], _, _, 0).
flow_inside([S|Ss], Lo, Hi, K) :-
    flow_inside(Ss, Lo, Hi, K0),
    (   S > Lo, S < Hi -> K is K0 + 1 ; K = K0 ).

flow_insert_at(O, 0, N, [N|O]) :- !.
flow_insert_at([M|Ms], P, N, [M|R]) :-
    P1 is P - 1,
    flow_insert_at(Ms, P1, N, R).

%% a call goes out on the dark lane and its answer comes back on the green
%% one, six pixels below, on the side that keeps the two from crossing
flow_wire(SX, SY, XT, TX, TY, [l(CallPts, ink, 1.5, none, ink), l(ExitPts, green, 1.3, none, green)]) :-
    TY6 is TY + 6,
    SY6 is SY + 6,
    (   SY =:= TY
    ->  CallPts = [SX-SY, TX-TY],
        ExitPts = [TX-TY6, SX-SY6]
    ;   CallPts = [SX-SY, XT-SY, XT-TY, TX-TY],
        (   TY > SY -> XE is XT - 6 ; XE is XT + 6 ),
        ExitPts = [TX-TY6, XE-TY6, XE-SY6, SX-SY6]
    ).

%% how far right the title's lines reach, at about 0.62 em a character
flow_lines_w(Ps, W) :-
    findall(R, ( member(t(X, _, start, Size, _, _, Segs), Ps),
                 findall(N, ( member(s(T, _), Segs), flow_chars(T, N) ), Ns),
                 sum_list(Ns, NC),
                 R is X + (NC * Size * 62 + 99) // 100 ),
            Rs),
    max_list([0|Rs], W).

flow_title_prims(Title, Src, Note, [t(24, 36, start, 18, sans, bold, [s(Title, ink)]),
                                    t(24, 58, start, 11, sans, normal, [s(Sub, muted)])|NPs]) :-
    flow_lib_name(Src, Base),
    format(atom(Sub), 'flowchart of ~w.pl  ·  library(flowchart)  ·  modes are inferred from the call pattern  ·  hover a box for its full text  ·  the XML beside this file says the same, for a program to read', [Base]),
    (   Note == none -> NPs = []
    ;   NPs = [t(24, 74, start, 11, sans, bold, [s(Note, amber)])]
    ).

%% ======================================================================
%% The findings, on the chart
%% ======================================================================
%%
%% Each finding (findings.pl) is a numbered disc on the box it is about --
%% red for an error, amber for a warning; a clause's on its head, a
%% predicate's on its panel's top right corner -- with its sentence on
%% hover, listed under the chart with its place, and counted beside the
%% title. A finding in a panel the picture leaves out is listed all the
%% same, and the XML has every one.

flow_finding_col(error, red).
flow_finding_col(warning, amber).

flow_findings_counts(Fs, NE, NW) :-
    findall(x, member(finding(_, _, error, _, _, _, _, _), Fs), Es),
    length(Es, NE),
    length(Fs, N),
    NW is N - NE.

%% `2 errors, 1 warning'
flow_count_words(NE, NW, W) :-
    flow_count_word(NE, error, A),
    flow_count_word(NW, warning, B),
    (   NE =:= 0 -> W = B
    ;   NW =:= 0 -> W = A
    ;   format(atom(W), '~w, ~w', [A, B])
    ).

flow_count_word(N, Word, A) :-
    flow_plural(N, Word, P),
    format(atom(A), '~d ~w', [N, P]).

%% beside the title, on its line
flow_findings_summary([], Ps, Ps) :- !.
flow_findings_summary(Fs, [T|Ps], [T, S|Ps]) :-
    T = t(_, _, _, _, _, _, [s(Title, _)]),
    flow_chars(Title, NT),
    X is 24 + (NT * 18 * 62 + 99) // 100 + 28,
    flow_findings_counts(Fs, NE, NW),
    flow_count_words(NE, NW, Words),
    format(atom(A), '~w  --  numbered on the chart, listed under it', [Words]),
    (   NE > 0 -> Col = red ; Col = amber ),
    S = t(X, 35, start, 12, sans, bold, [s(A, Col)]).

flow_findings_shown(40).

%% under the chart: a line each, the first forty
flow_findings_list([], _, [], 0) :- !.
flow_findings_list(Fs, Y0, [t(24, LY, start, 10, sans, bold, [s(findings, muted)])|Ps], H) :-
    LY is Y0 + 4,
    flow_findings_shown(Max),
    length(Fs, N),
    (   N > Max -> length(Shown, Max), append(Shown, _, Fs) ; Shown = Fs ),
    flow_finding_lines(Shown, Y0, Ps0, YEnd),
    (   N > Max
    ->  More is N - Max,
        MY is YEnd + 4,
        format(atom(MA), '... and ~d more: the XML lists every one', [More]),
        append(Ps0, [t(140, MY, start, 10, sans, normal, [s(MA, muted)])], Ps),
        H is YEnd - Y0 + 22 + 34
    ;   Ps = Ps0,
        H is YEnd - Y0 + 34
    ).

flow_finding_lines([], Y, [], Y).
flow_finding_lines([finding(N, _, Sev, At, In, Where, Text, _)|Fs], Y,
                   [c(148, Y, 8, Col, white, 1.5), t(148, NY, middle, 9, sans, bold, [s(NA, white)]),
                    t(162, TY, start, 10, sans, bold, [s(Sev, Col)]),
                    t(214, TY, start, 10, sans, normal, [s(In, ink), s(':  ', ink), s(Short, ink), s(Place, muted)])|Ps], YEnd) :-
    flow_finding_col(Sev, Col),
    number_codes(N, NCs), atom_codes(NA, NCs),
    NY is Y + 3, TY is Y + 4,
    flow_short(Text, 180, Short),
    (   Where = where(F, L, K) -> format(atom(Place), '  --  ~w:~w:~w  ~w', [F, L, K, At])
    ;   format(atom(Place), '  --  ~w', [At])
    ),
    Y1 is Y + 22,
    flow_finding_lines(Fs, Y1, Ps, YEnd).

flow_short(T, Max, S) :-
    flow_chars(T, N),
    (   N =< Max -> S = T
    ;   Keep is Max - 3,
        atom_codes(T, Cs),
        length(Ks, Keep),
        append(Ks, _, Cs),
        atom_codes(K, Ks),
        atom_concat(K, '...', S)
    ).

%% the discs on a panel's boxes, drawn last, so on top
flow_mark_findings(Ps0, PId, Fs, Ps) :-
    findall(F, ( member(F, Fs), F = finding(_, _, _, At, _, _, _, _), flow_in_panel(At, PId) ), Mine),
    (   Mine == [] -> Ps = Ps0
    ;   flow_finding_marks(Mine, Ps0, [], Marks),
        append(Ps0, Marks, Ps)
    ).

flow_in_panel(At, PId) :-
    (   At == PId -> true
    ;   atom_concat(PId, Rest, At), sub_atom(Rest, 0, 1, _, '.')
    ).

flow_finding_marks([], _, _, []).
flow_finding_marks([finding(N, _, Sev, At, _, _, Text, _)|Fs], Ps0, Used, Marks) :-
    (   flow_mark_point(Ps0, At, X0, Y)
    ->  findall(x, member(X0-Y, Used), Us),
        length(Us, K),
        X is X0 + 17 * K,
        flow_finding_col(Sev, Col),
        number_codes(N, NCs), atom_codes(NA, NCs),
        atom_concat(f, NA, FId),
        format(atom(Tip), '~w  --  ~w: ~w', [NA, Sev, Text]),
        TY is Y + 3,
        Marks = [grp(tip(Tip, FId), [c(X, Y, 8, Col, white, 1.5),
                                     t(X, TY, middle, 9, sans, bold, [s(NA, white)])])|Marks1],
        Used1 = [X0-Y|Used]
    ;   Marks = Marks1, Used1 = Used
    ),
    flow_finding_marks(Fs, Ps0, Used1, Marks1).

%% where the disc goes: a panel's top right corner, a clause's head box,
%% a goal's box
flow_mark_point(Ps0, At, X, Y) :-
    (   \+ sub_atom(At, _, _, _, '.')
    ->  memberchk(r(0, 0, W, _, 8, _, _, _, _), Ps0),
        X is W - 6, Y = 6
    ;   (   sub_atom(At, _, _, _, '.g') -> Box = At ; atom_concat(At, '.h', Box) ),
        memberchk(grp(tip(_, Box), Inner), Ps0),
        Inner = [S|_],
        flow_corner(S, X, Y)
    ).

flow_corner(r(X, Y, _, _, _, _, _, _, _), X, Y) :- !.
flow_corner(pg([_, X-Y|_], _, _, _), X, Y) :- !.
flow_corner(c(CX, CY, _, _, _, _), X, Y) :- X is CX + 4, Y is CY - 10.

%% ======================================================================
%% The legend: what each mark means, drawn with the marks themselves
%% ======================================================================

flow_legend(Y0, CW, Prims, H) :-
    Max is CW - 24,
    RuleY is Y0 - 18,
    RX is CW - 24,
    Rule = [l([24-RuleY, RX-RuleY], '#e3e8ee', 1, none, none)],
    Boxes = [head, user, library, builtin, test, portal, cut],
    flow_legend_row('boxes', Boxes, Y0, Max, P1, Y1),
    flow_legend_row('flow', [success, failure, cutfail, choice, recursion, redo], Y1, Max, P2, Y2),
    flow_legend_row('wires and modes', [wire, mode('+'), mode('-'), mode('?'), mode(':')], Y2, Max, P3, Y3),
    H is Y3 - Y0 + 4,
    append([Rule, P1, P2, P3], Prims).

flow_legend_row(Label, Entries, Y, Max, [t(24, LY, start, 10, sans, bold, [s(Label, muted)])|Ps], YNext) :-
    LY is Y + 4,
    flow_legend_entries(Entries, 140, Y, Max, Ps, YEnd),
    YNext is YEnd + 34.

flow_legend_entries([], _, Y, _, [], Y).
flow_legend_entries([E|Es], X, Y, Max, Ps, YEnd) :-
    flow_legend_entry(E, SW, Caption),
    flow_chars(Caption, CN),
    EW is SW + 8 + (CN * 62 + 9) // 10 + 26,
    (   X + EW > Max, X > 140 -> X1 = 140, Y1 is Y + 32 ; X1 = X, Y1 = Y ),
    flow_legend_sample(E, X1, Y1, SPs),
    CX is X1 + SW + 8,
    CY is Y1 + 4,
    X2 is X1 + EW,
    flow_legend_entries(Es, X2, Y1, Max, Rest, YEnd),
    append(SPs, [t(CX, CY, start, 10, sans, normal, [s(Caption, muted)])|Rest], Ps).

flow_legend_entry(head, W, 'clause head') :- flow_text_w(12, TW), W is TW + 22.
flow_legend_entry(user, W, 'your predicate, drawn in panel 3') :- flow_text_w(4, TW), W is TW + 18 + 21.
flow_legend_entry(library, W, 'library') :- flow_text_w(12, TW), W is TW + 18.
flow_legend_entry(builtin, W, 'builtin') :- flow_text_w(8, TW), W is TW + 18.
flow_legend_entry(test, W, 'test') :- flow_text_w(5, TW), W is TW + 30.
flow_legend_entry(portal, W, 'C function: a portal, not traced') :- flow_text_w(14, TW), W is TW + 18 + 17 + 21.
flow_legend_entry(cut, 14, 'cut').
flow_legend_entry(success, 40, 'success: left to right').
flow_legend_entry(failure, 40, 'failure: redo the nearest goal that can, else the next clause').
flow_legend_entry(cutfail, 34, 'past a cut: the whole call fails').
flow_legend_entry(choice, 14, 'can leave a choice point').
flow_legend_entry(recursion, 14, 'calls itself').
flow_legend_entry(redo, 14, 'redo enters here').
flow_legend_entry(wire, 48, 'the call goes out; its answer comes back').
flow_legend_entry(mode('+'), W, 'input') :- flow_text_w(3, W).
flow_legend_entry(mode('-'), W, 'output') :- flow_text_w(4, W).
flow_legend_entry(mode('?'), W, 'either') :- flow_text_w(4, W).
flow_legend_entry(mode(':'), W, 'a goal') :- flow_text_w(5, W).

flow_legend_sample(head, X, Y, Ps) :-
    flow_p(mhead([s('p(', ink), s('+In', m('+')), s(', ', ink), s('-Out', m('-')), s(')', ink)], false, W, 'a clause head'), X, Y, Ps0, _),
    flow_legend_entry(head, W, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(user, X, Y, Ps) :-
    flow_legend_entry(user, W, _),
    flow_p(mg(user, [s('q(', ink), s('X', m('?')), s(')', ink)], ref(3), false, true, W, 'a call to your predicate'), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(library, X, Y, Ps) :-
    flow_legend_entry(library, W, _),
    flow_p(mg(library(lists), [s('member(X, L)', ink)], none, false, true, W, library), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(builtin, X, Y, Ps) :-
    flow_legend_entry(builtin, W, _),
    flow_p(mg(builtin, [s('write(X)', ink)], none, false, false, W, builtin), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(test, X, Y, Ps) :-
    flow_legend_entry(test, W, _),
    flow_p(mg(test, [s('X > 2', ink)], none, false, true, W, test), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(portal, X, Y, Ps) :-
    flow_legend_entry(portal, W, _),
    flow_p(mg(portal(text), [s('re_match(P, L)', ink)], ref(4), false, true, W, portal), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(cut, X, Y, Ps) :-
    flow_p(mcut, X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(success, X, Y, [l([X-Y, X2-Y], ink, 1.4, none, ink)]) :- X2 is X + 38.
flow_legend_sample(failure, X, Y, [l([X2-Y, X-Y], red, 1.2, '4 3', red)]) :- X2 is X + 38.
flow_legend_sample(cutfail, X, Y, Ps) :-
    CX is X + 17,
    flow_cut_tag(CX, Y, Ps0),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(choice, X, Y, [t(X1, TY, start, 11, sans, normal, [s('↻', muted)])]) :- X1 is X + 2, TY is Y + 4.
flow_legend_sample(recursion, X, Y, [t(X1, TY, start, 14, sans, normal, [s('↺', ink)])]) :- X1 is X + 1, TY is Y + 5.
flow_legend_sample(redo, X, Y, [t(X1, TY, start, 13, sans, bold, [s('↶', red)])]) :- X1 is X + 1, TY is Y + 5.
flow_legend_sample(wire, X, Y, [l([X-Y1, X2-Y1], ink, 1.5, none, ink), l([X2-Y2, X-Y2], green, 1.3, none, green)]) :-
    X2 is X + 46, Y1 is Y - 3, Y2 is Y + 3.
flow_legend_sample(mode(M), X, Y, [t(X, TY, start, 12, mono, bold, [s(T, m(M))])]) :-
    TY is Y + 4,
    flow_mode_sample(M, T).

flow_mode_sample('+', '+In').
flow_mode_sample('-', '-Out').
flow_mode_sample('?', '?Any').
flow_mode_sample(':', ':Goal').

flow_unlayer([], []).
flow_unlayer([_-P|T], R) :- !, ( P = site(_, _) -> R = R1 ; R = [P|R1] ), flow_unlayer(T, R1).
flow_unlayer([P|T], [P|R]) :- flow_unlayer(T, R).

