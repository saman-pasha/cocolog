%% library(flowchart), part: the primitives written as SVG.

:- use_module(library(xml)).

%% ======================================================================
%% SVG
%% ======================================================================
%%
%% Self-contained: presentation attributes, no stylesheet and no script,
%% so the file looks the same in a browser, an editor or a viewer.

flow_svg(Graph, Svg) :-
    flow_svg(Graph, Svg, []).

%% depth(D) and only(Preds) choose what is drawn (layout.pl, "How much is
%% drawn"); the XML is never pruned
flow_svg(Graph, Svg, Opts) :-
    flow_findings(Graph, Fs),
    flow_svg(Graph, Fs, Svg, Opts).

%% the findings already found (flow_chart/4 finds them once for both files)
flow_svg(Graph, Fs, Svg, Opts) :-
    flow_prune(Graph, Opts, Graph1, Note),
    flow_layout(Graph1, Note, Fs, canvas(CW, CH, Items)),
    flow_els(Items, Els),
    flow_defs(Defs),
    format(atom(VB), '0 0 ~w ~w', [CW, CH]),
    flow_font(sans, Sans),
    Svg = element(svg, [xmlns='http://www.w3.org/2000/svg', width=CW, height=CH, viewBox=VB,
                        'font-family'=Sans],
                  [Defs, element(rect, [x=0, y=0, width=CW, height=CH, fill='#ffffff'], [])|Els]).

flow_defs(element(defs, [], Ms)) :-
    findall(element(marker, [id=Id, viewBox='0 0 10 10', refX=9, refY=5,
                             markerWidth=8, markerHeight=8, orient=auto,
                             markerUnits=userSpaceOnUse],
                    [element(path, [d='M0,0 L10,5 L0,10 z', fill=C], [])]),
            ( flow_marker(K, C), atom_concat('a-', K, Id) ),
            Ms).

flow_marker(ink, '#1f2933').
flow_marker(red, '#d62828').
flow_marker(green, '#15803d').
flow_marker(amber, '#b7791f').
flow_marker(purple, '#7e22ce').
flow_marker(violet, '#7c3aed').
flow_marker(blue, '#2f5bd3').

flow_els([], []).
flow_els([P|Ps], Els) :-
    (   flow_el(P, E) -> Els = [E|Es] ; Els = Es ),
    flow_els(Ps, Es).

flow_el(_-P, E) :- !, flow_el(P, E).
flow_el(site(_, _), _) :- !, fail.
flow_el(r(X, Y, W, H, Rx, Fill, Stroke, SW, Dash), element(rect, As, [])) :- !,
    flow_paint(Fill, F),
    flow_stroke(Stroke, SW, Dash, SAs),
    As = [x=X, y=Y, width=W, height=H, rx=Rx, fill=F|SAs].
flow_el(l(Pts, Col, SW, Dash, Mk), element(path, As, [])) :- !,
    flow_dedup(Pts, P1),
    flow_path_d(P1, D),
    flow_paint(Col, C),
    flow_dash(Dash, DAs),
    flow_marker_attr(Mk, MAs),
    append([[d=D, fill=none, stroke=C, 'stroke-width'=SW, 'stroke-linejoin'=round], DAs, MAs], As).
flow_el(t(X, Y, Anchor, Size, Font, Weight, Segs), element(text, As, Spans)) :- !,
    flow_font(Font, F),
    As0 = [x=X, y=Y, 'font-size'=Size, 'font-family'=F, 'xml:space'=preserve],
    (   Anchor == start -> As1 = As0 ; append(As0, ['text-anchor'=Anchor], As1) ),
    (   Weight == normal -> As = As1 ; append(As1, ['font-weight'=Weight], As) ),
    flow_spans(Segs, Spans).
flow_el(c(X, Y, R, Fill, Stroke, SW), element(circle, [cx=X, cy=Y, r=R, fill=F|SAs], [])) :- !,
    flow_paint(Fill, F),
    flow_stroke(Stroke, SW, none, SAs).
flow_el(pg(Pts, Fill, Stroke, SW), element(polygon, [points=PA, fill=F|SAs], [])) :- !,
    findall(A, ( member(X-Y, Pts), format(atom(A), '~w,~w', [X, Y]) ), As),
    atomic_list_concat(As, ' ', PA),
    flow_paint(Fill, F),
    flow_stroke(Stroke, SW, none, SAs).
flow_el(grp(tip(Tip, Id), Ps), element(g, [id=Id], [element(title, [], [Tip])|Es])) :- !,
    flow_els(Ps, Es).
flow_el(grp(Tip, Ps), element(g, [], [element(title, [], [Tip])|Es])) :- !,
    flow_els(Ps, Es).
flow_el(tr(X, Y, Ps, Id), element(g, [id=Id, transform=T], Es)) :-
    format(atom(T), 'translate(~w,~w)', [X, Y]),
    flow_els(Ps, Es).

%% `[]' is one atom with the empty list here, and library(xml) would read
%% it as no children at all: it goes as str/1, the library's way to say text
flow_spans([], []).
flow_spans([s(T, C)|Ss], [element(tspan, [fill=F], [N])|Es]) :-
    flow_paint(C, F),
    (   T == [] -> N = str("[]") ; N = T ),
    flow_spans(Ss, Es).

flow_stroke(none, _, _, [stroke=none]) :- !.
flow_stroke(C, SW, Dash, [stroke=P, 'stroke-width'=SW|DAs]) :-
    flow_paint(C, P),
    flow_dash(Dash, DAs).

flow_dash(none, []) :- !.
flow_dash(D, ['stroke-dasharray'=D]).

flow_marker_attr(none, []) :- !.
flow_marker_attr(K, ['marker-end'=U]) :- format(atom(U), 'url(#a-~w)', [K]).

flow_paint(none, none) :- !.
flow_paint(C, C) :- atom(C), atom_codes(C, [35|_]), !.
flow_paint(ink, '#1f2933') :- !.
flow_paint(muted, '#5f6b7a') :- !.
flow_paint(white, '#ffffff') :- !.
flow_paint(red, '#d62828') :- !.
flow_paint(green, '#15803d') :- !.
flow_paint(amber, '#a86a00') :- !.
flow_paint(purple, '#7e22ce') :- !.
flow_paint(teal, '#0f766e') :- !.
flow_paint(violet, '#7c3aed') :- !.
flow_paint(blue, '#2f5bd3') :- !.
flow_paint(m('+'), '#1d4ed8') :- !.
flow_paint(m('-'), '#c2410c') :- !.
flow_paint(m('?'), '#7e22ce') :- !.
flow_paint(m(':'), '#047857') :- !.
flow_paint(_, '#1f2933').

flow_font(mono, 'ui-monospace, SFMono-Regular, Menlo, Consolas, DejaVu Sans Mono, monospace').
flow_font(sans, 'system-ui, -apple-system, Segoe UI, Helvetica, Arial, DejaVu Sans, sans-serif').

flow_dedup([], []).
flow_dedup([P], [P]) :- !.
flow_dedup([P, Q|R], Out) :-
    (   P == Q -> flow_dedup([Q|R], Out) ; Out = [P|Out1], flow_dedup([Q|R], Out1) ).

%% an orthogonal polyline with its corners rounded
flow_path_d([X0-Y0|Rest], D) :-
    format(atom(M), 'M~w ~w', [X0, Y0]),
    flow_path_rest(X0-Y0, Rest, Parts),
    atomic_list_concat([M|Parts], ' ', D).

flow_path_rest(_, [], []).
flow_path_rest(_, [X-Y], [L]) :- !,
    format(atom(L), 'L~w ~w', [X, Y]).
flow_path_rest(PX-PY, [X-Y, NX-NY|Rest], [L, Q|Parts]) :-
    DX1 is sign(X - PX), DY1 is sign(Y - PY),
    DX2 is sign(NX - X), DY2 is sign(NY - Y),
    Len1 is abs(X - PX) + abs(Y - PY),
    Len2 is abs(NX - X) + abs(NY - Y),
    R is min(6, min(Len1 // 2, Len2 // 2)),
    AX is X - DX1 * R, AY is Y - DY1 * R,
    BX is X + DX2 * R, BY is Y + DY2 * R,
    format(atom(L), 'L~w ~w', [AX, AY]),
    format(atom(Q), 'Q~w ~w ~w ~w', [X, Y, BX, BY]),
    flow_path_rest(BX-BY, [NX-NY|Rest], Parts).
