%% library(flowchart) -- a predicate drawn from the query to C and back.
%%
%% WHAT IS WORTH CHECKING is what a reader would act on and could not see
%% for themselves: the MODE drawn on an argument, the DETERMINISM written on
%% a panel, WHERE a failure goes, WHERE in the file a goal stands, and that
%% the SVG and the XML name the same things. A chart that is wrong there is
%% worse than none -- it sends a person, or an agent, to the wrong line --
%% so those are the checks, each against a value worked out by hand from
%% the fixtures in test/flowchart/:
%%
%%   demo.pl     user code, a library predicate, a C function, a cut, an
%%               if-then-else, \+, findall/3, a recursive nondeterministic
%%               predicate
%%   gallery.pl  every construct: forall, once, ignore, aggregate_all, ;,
%%               catch with a recovery that fails, a cut that commits
%%   fix.pl      the fixed point: one predicate met in three call patterns,
%%               an accumulator, two predicates through each other, one
%%               that never succeeds
%%   gram.pl     grammar rules, drawn as the predicates they are
%%
%% How the picture LOOKS is not checked here -- that is judged by eye --
%% but that it is an SVG that reads back, and that every goal in the XML
%% has its box in it, is.
%%
%%     cocolog -s test/flowchart.pl      from the checkout root

:- use_module('test/prelude.pl').
:- use_module(library(stream)).
:- use_module(library(flowchart)).
:- use_module(library(xml)).

main :-
    ( catch(use_module(library(stream)), _, fail) -> true ; skip('(no library/stream.so -- sh modules/stream/build.sh)') ),
    tables,
    modes_and_determinism,
    fixed_point,
    grammar,
    positions,
    failure,
    documents,
    drawing_less,
    folding,
    command,
    refusals,
    checks_done.

fx(Name, F) :- atomic_list_concat(['test/flowchart/', Name, '.pl'], F).

%% each panel but the query: Name/Arity, its call pattern, its determinism
panels(Spec, Fixture, Ps) :-
    fx(Fixture, F),
    flow_graph(Spec, graph(_, _, Panels, _, _), [source(F)]),
    findall(K-CM-Det, ( member(panel(I, K, _, CM, _, _, Det, _), Panels), I > 0 ), Ps).

graph(Spec, Fixture, G) :-
    fx(Fixture, F),
    flow_graph(Spec, G, [source(F)]).

%% ---- the tables ----------------------------------------------------------

tables :-
    section('the tables: what answers in C, generated at build time'),
    %% they are build output, made from the sources alone, so a case that
    %% finds them missing makes them -- and loads them, which the library's
    %% own load could not do while they were not there
    (   catch(flow_t_c(_, _, _), _, fail)
    ->  true
    ;   format("     (library/flow/tables.pl missing: sh tools/flow/build.sh)~n", []),
        shell('sh tools/flow/build.sh', _, _),
        use_module(library(flow/tables))
    ),
    yes_no(flow_t_c(atom_length, 2, _), Y1),
    check('atom_length/2 is a C builtin of the engine', Y1, yes),
    answer(flow_t_portal(text, re_match, 2, CF2, F2, _, Ms2, Ns2), CF2-F2-Ms2-Ns2, G2),
    check('re_match/2 is library(text)''s C function, with its row''s modes and names', G2,
          coco_x_match-'modules/text/text.cicili'-['+', '+']-['Pat', 'Text']),
    answer(flow_t_sig(re_lines, 3, Ms3, Ns3), Ms3-Ns3, G3),
    check('a module''s Prolog half is named from its header', G3, ['+', '+', '-']-['Pat', 'Codes', 'Lines']),
    findall(N/A, ( flow_t_c(N, A, _), \+ atom_concat('$', _, N),
                   \+ flow_mode(N, A, _, _), \+ flow_test(N, A) ), Missing),
    check('every C builtin of the engine has a line in the mode table', Missing, []).

%% ---- modes and determinism ----------------------------------------------

modes_and_determinism :-
    section('modes and determinism, read off the analysed goals'),
    panels(report('+', '+', '+'), demo, Ps1),
    check('demo.pl: each panel, its call pattern and its determinism', Ps1,
          [report/3-['+', '+', '+']-semidet,
           grep_count/3-['+', '+', '-']-det,
           classify/2-['+', '-']-det,
           first_big/2-['+', '-']-semidet,
           re_match/2-['+', '+']-semidet,
           pick/2-['-', '+']-nondet]),
    %% length/2 is det for (+, -) and nondet for (-, -): a line per mode
    answer(flow_mode_for(length, 2, ['+', '-'], _, D2), D2, G2),
    check('length(+L, -N) is det', G2, det),
    answer(flow_mode_for(length, 2, ['-', '-'], _, D3), D3, G3),
    check('length(-L, -N) is nondet', G3, nondet),
    answer(flow_mode_for(atom_length, 2, ['+', '+'], _, D4), D4, G4),
    check('a det builtin handed its output bound only compares: semidet', G4, semidet),
    panels(check('+', '+'), gallery, Ps5),
    check('gallery.pl: committed clauses whose last cannot fail are det', Ps5,
          [check/2-['+', '+']-semidet,
           sign_word/2-['+', '-']-nondet,
           lines_or_none/3-['+', '+', '-']-det,
           re_lines/3-['+', '+', '-']-det,
           re_match/2-['+', '+']-semidet]).

%% ---- the fixed point ----------------------------------------------------

fixed_point :-
    section('the fixed point, and a panel per call pattern'),
    panels(top('+', '-'), fix, Ps),
    check('fix.pl: every pattern the query reaches, and how each can end', Ps,
          [top/2-['+', '-']-nondet,
           rev/2-['+', '-']-semidet,
           size/2-['+', '-']-semidet,
           size/2-['-', '+']-nondet,
           evenp/1-['+']-nondet,
           spin/1-['?']-failure,
           rev/3-['+', '+', '-']-semidet,
           size/2-['-', '-']-nondet,
           oddp/1-['+']-nondet]),
    %% past a call that never succeeds nothing runs: the goal is drawn,
    %% unreached, and what it would call gets no panel
    scratch(D),
    atom_concat(D, '/stuck.pl', SF),
    open(SF, write, S),
    format(S, "go(X) :- stuck(X), after(X).~nstuck(X) :- stuck(X).~nafter(_).~n", []),
    close(S),
    flow_graph(go('?'), G2, [source(SF)]),
    G2 = graph(_, _, Panels2, _, _),
    findall(K-CM-Det, ( member(panel(I, K, _, CM, _, _, Det, _), Panels2), I > 0 ), Ps2),
    check('a call past one that never succeeds makes no panel', Ps2,
          [go/1-['?']-failure, stuck/1-['?']-failure]),
    flow_xml(G2, X2),
    attr_of(X2, 'p1.c1.g2', reached, R3),
    attr_of(X2, 'p1.c1.g2', calls, C3),
    check('the XML says that goal is never reached, and names no panel for it', R3-C3, false-failed).

%% ---- grammar rules ------------------------------------------------------

grammar :-
    section('grammar rules are the predicates they stand for'),
    panels(sum('+', '-'), gram, Ps1),
    check('gram.pl: phrase/2 calls expr//1 with its list in and [] out', Ps1,
          [sum/2-['+', '-']-semidet,
           expr/3-['-', '+', '+']-semidet,
           term/3-['-', '+', '-']-semidet,
           rest/4-['+', '-', '+', '+']-semidet,
           figure/3-['-', '+', '-']-semidet,
           figures/3-['-', '+', '-']-semidet]),
    graph(sum('+', '-'), gram, G),
    G = graph(_, _, Panels, _, _),
    memberchk(panel(_, rest/4, _, _, _, rows([row(_, H, Names, _, Nodes, CI)|_]), _, _), Panels),
    flow_term_full(H, Names, 1200, HT),
    check('the leading terminal is lifted into the head, as the store does it', HT,
          'rest(A, V, [0\'+|S0], S4)'),
    yes_no(memberchk(dcg, CI), Y3),
    check('the clause says it was a grammar rule', Y3, yes),
    findall(F, ( member(g(_, _, _, _, _, I), Nodes), memberchk(dcg(F), I) ), Forms),
    check('each goal keeps what it was in the grammar', Forms,
          [pass, nonterminal(term//1), goal, pass, nonterminal(rest//2)]),
    panels(expr//1, gram, [P4|_]),
    check('a Name//Arity spec parses: its list in, the rest out', P4, expr/3-['?', '+', '-']-semidet).

%% ---- positions ----------------------------------------------------------

positions :-
    section('where each goal stands: line and column, counted by hand'),
    graph(report('+', '+', '+'), demo, G),
    G = graph(_, _, Panels, _, _),
    memberchk(panel(1, _, _, _, _, rows([row(_, _, _, _, Ns1, CI1)]), _, _), Panels),
    answer(memberchk(at(L1, C1), CI1), L1:C1, G1),
    check('report/3''s clause starts at 12:1', G1, 12:1),
    flow_goal_places(Ns1, Places),
    check('its goals, the one inside \\+ and the two inside the if-then-else included',
          Places,
          [grep_count/3-(13:5), classify/2-(14:5), (==)/2-(15:8),
           first_big/2-(16:9), (=)/2-(16:40), format/2-(17:5)]),
    memberchk(panel(2, _, _, _, _, rows([row(_, _, _, _, Ns2, _)]), _, _), Panels),
    flow_goal_places(Ns2, P2),
    check('inside findall/3 too', P2,
          [codes_lines/2-(21:5), member/2-(22:18), re_match/2-(22:36), length/2-(23:5)]).

flow_goal_places(Nodes, Places) :-
    findall(N/A-(L:C), ( flow_some_goal(Nodes, g(Gl, _, _, _, _, I)),
                         memberchk(at(L, C), I), functor(Gl, N, A) ), Places).

flow_some_goal(Nodes, G) :- member(N, Nodes), flow_inner_goal(N, G).
flow_inner_goal(g(A, B, C, D, E, F), g(A, B, C, D, E, F)).
flow_inner_goal(not(Ns), G) :- flow_some_goal(Ns, G).
flow_inner_goal(ite(_, Arms, Else), G) :-
    (   member(arm(C, T), Arms), ( flow_some_goal(C, G) ; flow_some_goal(T, G) )
    ;   Else \== none, flow_some_goal(Else, G)
    ).
flow_inner_goal(meta(_, _, _, [Ns], _), G) :- flow_some_goal(Ns, G).

%% ---- where a failure goes -----------------------------------------------

failure :-
    section('where each failure goes, as the XML says it'),
    graph(report('+', '+', '+'), demo, G),
    flow_xml(G, X),
    attr_of(X, 'p4.c1.g2', on_fail, F1),
    check('X > 2 fails: pick/2 is tried again', F1, 'p4.c1.g1'),
    attr_of(X, 'p4.c1', redo, F2),
    attr_of(X, 'p4.c1', past_cut, F3),
    check('backtracking into first_big/2 past its cut: the call fails', F2-F3, fail-'p4.c1.g3'),
    attr_of(X, 'p1.c1.g4.a1.if.g1', on_fail, F4),
    check('a condition that fails goes to the else', F4, 'p1.c1.g4.else'),
    attr_of(X, 'p1.c1.g3.g1', on_fail, F5),
    check('the goal inside \\+ failing makes the \\+ done (it succeeds)', F5, 'p1.c1.g3:done'),
    attr_of(X, 'p6.c2', redo, F6),
    check('backtracking into pick/2''s second clause redoes its recursion', F6, 'p6.c2.g1'),
    attr_of(X, 'p6.c1', redo, F7),
    check('...and into its first, the next clause', F7, next_clause),
    attr_of(X, 'p6.c2.g1', calls, F8),
    check('a call to itself says so', F8, self).

%% the attribute of the element with that id
attr_of(X, Id, Name, V) :-
    answer(( xml_element_id(X, Id, element(_, As, _)), memberchk(Name=V0, As) ), V0, V).

xml_element_id(element(N, As, Cs), Id, E) :-
    (   memberchk(id=Id, As) -> E = element(N, As, Cs)
    ;   member(C, Cs), C = element(_, _, _), xml_element_id(C, Id, E)
    ), !.

%% ---- the two documents --------------------------------------------------

documents :-
    section('the SVG and the XML: written, read back, naming the same things'),
    scratch(D),
    atom_concat(D, '/demo', Base),
    fx(demo, F),
    answer(flow_chart(report('+', '+', '+'), Base, [source(F)]), yes, G1),
    check('flow_chart/3 writes both', G1, yes),
    atom_concat(Base, '.svg', SF),
    atom_concat(Base, '.xml', XF),
    read_file_to_codes(SF, SC),
    read_file_to_codes(XF, XC),
    answer(xml_parse(SC, element(R2, _, _)), R2, G2),
    check('the SVG reads back as an svg element', G2, svg),
    answer(( xml_parse(XC, element(R3, A3, _)), memberchk(version=V3, A3) ), R3-V3, G3),
    check('the XML reads back as a flow element, schema version 1', G3, flow-'1'),
    xml_parse(SC, S),
    xml_parse(XC, X),
    findall(I, xml_ids_of(X, goal, I), XIds),
    findall(I, xml_ids_of(S, g, I), SIds),
    findall(I, ( member(I, XIds), \+ memberchk(I, SIds) ), Unboxed),
    length(XIds, NX),
    %% query 1, report/3 6, grep_count/3 4, classify/2 5, first_big/2 2, pick/2 1
    check('the XML has a goal for every one of the chart''s 19', NX, 19),
    check('and every goal in the XML has its box, by id, in the SVG', Unboxed, []),
    %% the files are written a piece at a time, not through library(xml)'s
    %% one code list; they must be the bytes it would have written
    graph(report('+', '+', '+'), demo, Gr),
    flow_svg(Gr, SvgT), flow_xml(Gr, XmlT),
    xml_codes(SvgT, SWant, [header(true)]),
    xml_codes(XmlT, XWant, [header(true), indent(2)]),
    yes_no(SC == SWant, Y4),
    yes_no(XC == XWant, Y5),
    check('both files are the bytes library(xml) writes for the same terms', Y4-Y5, yes-yes).

%% ---- drawing less -------------------------------------------------------

drawing_less :-
    section('drawing less: depth(D), only(Preds), the budget -- and the XML never pruned'),
    scratch(D),
    fx(demo, F),
    atom_concat(D, '/all', B0), atom_concat(D, '/d1', B1), atom_concat(D, '/only', B2),
    flow_chart(report('+', '+', '+'), B0, [source(F)]),
    flow_chart(report('+', '+', '+'), B1, [source(F), depth(1)]),
    flow_chart(report('+', '+', '+'), B2, [source(F), only([pick/2, classify/2])]),
    svg_panels(B0, P0),
    check('with no option, every panel of demo.pl is drawn in full', P0,
          [p1-full, p2-full, p3-full, p4-full, p5-full, p6-full, query-full]),
    svg_panels(B1, P1),
    %% report/3 is depth 1; grep_count/3, classify/2 and first_big/2 depth 2
    check('depth(1): report/3 in full, what it calls as stubs, nothing deeper', P1,
          [p1-full, p2-stub, p3-stub, p4-stub, query-full]),
    svg_note(B1, N1),
    check('and the chart says what it left out', N1,
          '1 of 6 panels drawn, to depth 1  ·  3 stubs mark where the other 5 begin  ·  the XML has every one  ·  depth(D) or only([Name/Arity, ...]) draws others'),
    svg_panels(B2, P2),
    check('only([pick/2, classify/2]): those two in full, report/3 a stub under the query', P2,
          [p1-stub, p3-full, p6-full, query-full]),
    xml_file(B0, X0), xml_file(B1, X1), xml_file(B2, X2),
    yes_no(( X0 == X1, X0 == X2 ), Y4),
    check('the XML is the same whatever the picture draws', Y4, yes),
    %% 1 + 10 + 200 panels: depth 2 and its 200 stubs do not fit in 150
    fan_program(D, FF),
    atom_concat(D, '/fan', B3),
    flow_chart(top, B3, [source(FF)]),
    svg_panels(B3, P3),
    findall(I, member(I-stub, P3), Stubs3),
    length(Stubs3, NS3),
    check('211 panels are over the budget: top/0 in full and its ten callees as stubs', NS3-P3,
          10-[p1-full, p10-stub, p11-stub, p2-stub, p3-stub, p4-stub, p5-stub, p6-stub, p7-stub, p8-stub, p9-stub, query-full]),
    svg_texts(B3, Texts3),
    findall(T, ( member(T, Texts3), T == '20 more panels hang from it  ·  the XML has them all' ), Hang3),
    length(Hang3, NH3),
    check('each stub says 20 panels hang from it', NH3, 10),
    answer(flow_chart(report('+', '+', '+'), B1, [source(F), depth(0)]), yes, G5),
    check('depth(0) is refused by name', G5, error(error(domain_error(flow_depth, 0), flow_chart/3))),
    answer(flow_chart(report('+', '+', '+'), B1, [source(F), only(pick)]), yes, G6),
    check('only/1 wants a list of Name/Arity', G6, error(error(domain_error(flow_only, pick), flow_chart/3))).

%% ---- builtin work, folded ----------------------------------------------

folding :-
    section('builtin work folded by default, every goal with builtins(show)'),
    scratch(D),
    fx(demo, F),
    atom_concat(D, '/fold', B0), atom_concat(D, '/show', B1),
    flow_chart(report('+', '+', '+'), B0, [source(F)]),
    flow_chart(report('+', '+', '+'), B1, [source(F), builtins(show)]),
    svg_doc(B0, S0), svg_doc(B1, S1),
    %% grep_count/3: codes_lines(Text, Lines), findall(L, (member(L, Lines),
    %% re_match(Pat, L)), Hits), length(Hits, N)
    svg_title(S1, 'p2.c1.g2.g1', T1),
    check('builtins(show): member/2 has a box of its own', T1, 'member(L, Lines)  --  library(lists), nondet'),
    svg_title(S0, 'p2.c1.g2.g1', T2),
    check('by default it is folded, and its box says what it holds', T2,
          '1 builtin goal, folded  --  builtins(show) draws it:\nmember(L, Lines)'),
    svg_element(S0, 'p2.c1.g2.g1', element(_, _, C3)),
    yes_no(svg_has_text(C3, '↻'), Y3),
    check('the fold leaves the choice member/2 leaves, so re_match/2''s failure still goes back into it', Y3, yes),
    svg_element(S0, 'p1.c1.g5', element(_, _, C4)),
    yes_no(( memberchk(element(circle, _, _), C4), \+ memberchk(element(text, _, _), C4) ), Y4),
    check('format/2, which can neither fail nor leave a choice, is a dot on the line', Y4, yes),
    svg_element(S0, p3, element(_, _, C5)),
    yes_no(svg_has_text(C5, 'if  ->  then  ;  else'), Y5),
    check('classify/2''s if-then-else is drawn though it holds only builtins: conditions are the flow', Y5, yes),
    svg_element(S0, 'p3.c1.g1.a1.if.g1', element(_, _, C6)),
    yes_no(svg_has_text(C6, '⋯ 1'), Y6),
    check('and the test in its condition is folded inside it', Y6, yes),
    xml_file(B0, X0), xml_file(B1, X1),
    yes_no(X0 == X1, Y7),
    check('the XML is the same folded or not', Y7, yes),
    answer(flow_chart(report('+', '+', '+'), B0, [source(F), builtins(maybe)]), yes, G8),
    check('builtins/1 is fold or show, by name', G8, error(error(domain_error(flow_builtins, maybe), flow_chart/3))).

svg_doc(Base, S) :-
    atom_concat(Base, '.svg', SF),
    read_file_to_codes(SF, C),
    xml_parse(C, S).

svg_element(S, Id, E) :-
    xml_element_id(S, Id, E).

svg_title(S, Id, T) :-
    (   svg_element(S, Id, element(_, _, Cs)), memberchk(element(title, _, [T0]), Cs)
    ->  T = T0
    ;   T = none
    ).

%% the panels of an SVG, each drawn in full or as a stub, sorted
svg_panels(Base, Ps) :-
    atom_concat(Base, '.svg', S),
    read_file_to_codes(S, C),
    xml_parse(C, element(svg, _, Kids)),
    findall(I-How, ( member(element(g, As, Cs), Kids), memberchk(id=I, As), memberchk(transform=_, As),
                     ( svg_has_text(Cs, 'not drawn') -> How = stub ; How = full ) ),
            Ps0),
    msort(Ps0, Ps).

svg_has_text(Cs, Prefix) :-
    member(C, Cs),
    (   atom(C), atom_concat(Prefix, _, C) -> true
    ;   C = element(_, _, Cs1), svg_has_text(Cs1, Prefix)
    ), !.

%% every text in an SVG, in order
svg_texts(Base, Ts) :-
    atom_concat(Base, '.svg', S),
    read_file_to_codes(S, C),
    xml_parse(C, E),
    findall(T, svg_text(E, T), Ts).

svg_text(element(_, _, Cs), T) :-
    member(C, Cs),
    (   atom(C), T = C
    ;   C = element(_, _, _), svg_text(C, T)
    ).

%% the line under the title that says what was left out
svg_note(Base, N) :-
    svg_texts(Base, Ts),
    member(N, Ts),
    sub_atom(N, _, _, _, ' panels drawn, '), !.

xml_file(Base, Cs) :-
    atom_concat(Base, '.xml', X),
    read_file_to_codes(X, Cs).

%% top/0 calls m1 .. m10, and each mI twenty facts
fan_program(D, F) :-
    atom_concat(D, '/fan.pl', F),
    open(F, write, S),
    numlist(1, 10, Ms),
    numlist(1, 20, Ls),
    findall(G, ( member(M, Ms), format(atom(G), 'm~d', [M]) ), Gs),
    atomic_list_concat(Gs, ', ', Body),
    format(S, "top :- ~w.~n", [Body]),
    forall(member(M, Ms),
           ( findall(L, ( member(J, Ls), format(atom(L), 'l~d_~d', [M, J]) ), LGs),
             atomic_list_concat(LGs, ', ', LB),
             format(S, "m~d :- ~w.~n", [M, LB]),
             forall(member(L, LGs), format(S, "~w.~n", [L])) )),
    close(S).

xml_ids_of(element(N, As, Cs), Name, Id) :-
    (   N == Name, memberchk(id=Id, As)
    ;   member(C, Cs), C = element(_, _, _), xml_ids_of(C, Name, Id)
    ).

%% ---- the command an agent runs -------------------------------------------

command :-
    section('tools/flow/chart.pl: one command, two files, an exit status'),
    scratch(D),
    atomic_list_concat([D, '/cmd'], B),
    atomic_list_concat(['-s tools/flow/chart.pl -- \'report(+,+,+)\' test/flowchart/demo.pl ', B], A1),
    cocolog_run(A1, _, E1),
    atom_concat(B, '.xml', XF),
    yes_no(exists_file(XF), Y1),
    check('it writes BASE.xml and exits 0', E1-Y1, 0-yes),
    atomic_list_concat(['-s tools/flow/chart.pl -- \'nosuch(+)\' test/flowchart/demo.pl ', B], A2),
    cocolog_run(A2, _, E2),
    check('a predicate the program does not have is exit 1', E2, 1),
    atomic_list_concat(['-s tools/flow/chart.pl -- \'report(+,+,+)\' test/flowchart/demo.pl ', B, ' colour=red'], A3),
    cocolog_run(A3, _, E3),
    check('an option it does not know is exit 2', E3, 2).

%% ---- refusals -----------------------------------------------------------

refusals :-
    section('refusals, by name'),
    answer(flow_graph(report('+', '+', '+'), _, []), x, G1),
    check('no source is an existence error naming the option', G1,
          error(error(existence_error(flow_option, source), flow_graph/3))),
    fx(demo, F),
    answer(flow_graph(nosuch('+'), _, [source(F)]), x, G2),
    check('a predicate the program does not have is named', G2,
          error(error(existence_error(procedure, nosuch/1), flow_graph/3))).
