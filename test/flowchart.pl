%% library(flow/chart) -- a predicate drawn from the query to C and back.
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
%%   runtime.pl  what is made or picked as the program runs: dynamic
%%               predicates (one declared by notes.pl, which it loads) and
%%               call/N, with a closure named and with one that is not
%%   faults.pl   one of each finding, and eleven near misses that are not --
%%               three of them false findings the translator once had
%%   gram.pl     grammar rules, drawn as the predicates they are
%%   threads.pl  threads, a pool, an isolated proof, a crew and an httpd
%%               pool; a channel, locks, child processes, writes to the
%%               knowledge base; the three thread findings, a binding a
%%               thread never hands back, and six near misses
%%   crossing.pl what F2 left: a crew handed a list of jobs, a server on
%%               the caller's thread, handles and channels followed through
%%               heads, callers, terms and other channels, and the order a
%%               channel's messages are taken in -- a predicate at a time
%%   gate.pl     cicili-lang's flow gate in small (1.11.4): the false
%%               findings and the requests of its report, with gate_lib.pl
%%               (a file it loads), gate_mod.cicili (its module's source),
%%               gate_half.pl (a library that module loads) and
%%               gate_clash.pl (a helper named as the library's own, given
%%               to the chart and, since 1.11.7, loaded by the program
%%               itself)
%%
%% How the picture LOOKS is not checked here -- that is judged by eye --
%% but that it is an SVG that reads back, and that every goal in the XML
%% has its box in it, is.
%%
%%     cocolog -s test/flowchart.pl      from the checkout root

:- use_module('test/prelude.pl').
:- use_module(library(stream)).
:- use_module(library(flow/chart)).
:- use_module(library(xml)).

main :-
    ( catch(use_module(library(stream)), _, fail) -> true ; skip('(no library/stream.so -- sh modules/stream/build.sh)') ),
    tables,
    modes_and_determinism,
    fixed_point,
    runtime,
    findings,
    grammar,
    positions,
    failure,
    documents,
    drawing_less,
    builtins,
    threads,
    crossing,
    gate,
    command,
    refusals,
    checks_done.

fx(Name, F) :- atomic_list_concat(['test/flowchart/', Name, '.pl'], F).

%% each panel but the query: Name/Arity, its call pattern, its determinism
panels(Spec, Fixture, Ps) :-
    panels(Spec, Fixture, [], Ps).

panels(Spec, Fixture, Opts, Ps) :-
    fx(Fixture, F),
    flow_graph(Spec, graph(_, _, Panels, _, _), [source(F)|Opts]),
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
    check('every C builtin of the engine has a line in the mode table', Missing, []),
    %% the constructs the engine dispatches itself are a table of their own,
    %% so a script that tells a builtin from an unknown name by the tables
    %% does not take call/1 or throw/1 for unknown (cicili-lang's report)
    findall(K5, ( member(K5, [call/1, call/3, throw/1, catch/3, (',')/2, (;)/2, (->)/2,
                              (\+)/1, once/1, ignore/1, not/1, true/0, fail/0, (!)/0]),
                  K5 = N5/A5, \+ flow_t_construct(N5, A5, 'lib/solve.cicili') ), Absent5),
    check('the control constructs are flow_t_construct/3: call/N, throw/1, catch/3 and the rest', Absent5, []).

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
    %% libraries(reach) opens re_lines/3, library(text)'s, to show a library
    %% clause's determinism read the same way
    panels(check('+', '+'), gallery, [libraries(reach)], Ps5),
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
    check('the XML says that goal is never reached, and names no panel for it', R3-C3, false-failed),
    graph(top('+', '-'), fix, GF),
    flow_findings(GF, FFs),
    findall(K-At, member(finding(_, K, _, At, _, _, _, _), FFs), KAs),
    %% spin/1 calls itself with what it was given; size/2 called with
    %% nothing bound calls itself first too, and is a generator, not a loop
    check('fix.pl: spin/1 loops for ever, and size/2 of nothing bound is no finding', KAs,
          [left_recursion-'p6.c1.g1']).

%% ---- what is made or picked as the program runs -------------------------

runtime :-
    section('dynamic predicates and call/N: what is made, or picked, as the program runs'),
    panels(run('+', '-'), runtime, Ps1),
    %% tally/1 starts with one clause and may answer again, or not at all;
    %% apply_to/3's closure may leave a choice; nosuch/1 can only raise
    check('runtime.pl: each panel, its call pattern and how it can end', Ps1,
          [run/2-['+', '-']-nondet,
           visit/1-['+']-nondet,
           apply_to/3-['+', '+', '-']-nondet,
           twice/2-['+', '-']-det,
           try/1-['+']-det,
           broken/1-['+']-semidet,
           tally/1-['-']-nondet,
           double/2-['+', '-']-det]),
    graph(run('+', '-'), runtime, G),
    flow_xml(G, X),
    findall(P-K, ( xml_goal_attrs(X, As), memberchk(kind=K, As),
                   memberchk(K, [dynamic, closure, unknown]), memberchk(pred=P, As) ), PKs),
    check('declared dynamic -- here, with a clause or none, or by a file it loads -- is dynamic; a goal the source does not name is a closure; only what nothing defines is unknown',
          PKs, ['note/1'-dynamic, 'seen/1'-dynamic, 'tally/1'-dynamic,
                'call/3'-closure, 'call/1'-closure, 'nosuch/1'-unknown]),
    attr_of(X, p7, kind, K3), attr_of(X, p7, clauses, C3), attr_of(X, p7, det, D3),
    check('tally/1''s panel holds the clause the file starts it with', K3-C3-D3, dynamic-1-nondet),
    attr_of(X, 'p2.c1.g1.a1.if.g1', calls, C4),
    check('seen/1 has no clause in the file, so no panel to call', C4, failed),
    attr_of(X, 'p4.c1.g1', text, T5), attr_of(X, 'p4.c1.g1', calls, C5),
    attr_of(X, 'p4.c1.g2', text, T6), attr_of(X, 'p4.c1.g2', calls, C6),
    check('call(double, X, Y0) and call(double(Y0), Y) run double/2, one panel for both',
          [T5-C5, T6-C6], ['double(X, Y0)'-p8, 'double(Y0, Y)'-p8]),
    attr_of(X, 'p3.c1.g1', choice, H7),
    check('a closure may leave a choice, so a failure after it goes back into it', H7, true),
    scratch(D),
    atom_concat(D, '/runtime', B),
    fx(runtime, F),
    flow_chart(run('+', '-'), B, [source(F)]),
    svg_doc(B, S),
    svg_title(S, 'p2.c1.g1.a1.if.g1', T8),
    check('the box says what it is', T8,
          'seen(X)  --  dynamic: its clauses are made and unmade as the program runs, nondet'),
    atom_concat(D, '/conj.pl', CF),
    open(CF, write, CS),
    format(CS, "go(X) :- call((a(X), b(X))).~na(1).~nb(1).~n", []),
    close(CS),
    flow_graph(go('?'), G9, [source(CF)]),
    flow_xml(G9, X9),
    findall(P9, ( xml_goal_attrs(X9, A9), memberchk(pred=P9, A9) ), Ps9),
    check('call((a(X), b(X))) is its two goals, not an unknown ,/2', Ps9, ['go/1', 'a/1', 'b/1']).

%% ---- findings ----------------------------------------------------------

findings :-
    section('findings: what is wrong, and where -- one of each, and the near misses that are not'),
    graph(check('+'), faults, G),
    flow_findings(G, Fs),
    findall(N-K-At-In, member(finding(N, K, _, At, In, _, _, _), Fs), Got1),
    %% eleven near misses find nothing: the same goals in the right order, a
    %% variable bound on one path only, recursion on the tail, a test before
    %% the cut, a kept semidet promise, a dynamic call, the translator's
    %% three, a head with one variable in two inputs, and a variable a clause
    %% head binds
    check('faults.pl: every finding, in document order -- and nothing from the near misses', Got1,
          [1-instantiation-'p2.c1.g1'-'total/2',
           2-instantiation-'p5.c1.g1'-'name_size/1',
           3-instantiation-'p6.c1.g1'-'run_it/0',
           4-left_recursion-'p8.c1.g1'-'spin/1',
           5-left_recursion-'p9.c1.g1'-'ping/1',
           6-unreachable_clause-'p11.c2'-'kind/2',
           7-det_promise-p13-'first_pos/2',
           8-det_promise-p14-'pick_one/2',
           9-unknown_procedure-'p16.c1.g1'-'helper/1',
           10-left_recursion-'p23.c1.g1'-'xs/2']),
    panels(check('+'), faults, Ps0),
    findall(K0-CM0-D0, ( member(K0-CM0-D0, Ps0), memberchk(K0, [total/2, percent/1]) ), Ps1),
    %% total/2 always raises; percent/1 handed a free W fails at atom/1
    check('a call that always raises, and a test that never holds of a free variable, end the clause',
          Ps1, [total/2-['+', '-']-failure, percent/1-['-']-failure, percent/1-['?']-semidet]),
    findall(S, member(finding(_, _, S, _, _, _, _, _), Fs), Ss),
    msort(Ss, Ss2),
    check('seven errors and three warnings', Ss2,
          [error, error, error, error, error, error, error, warning, warning, warning]),
    memberchk(finding(1, _, _, _, _, W1, T1, _), Fs),
    check('an instantiation finding names the variable, by its own name, and the place', W1-T1,
          where('test/flowchart/faults.pl', 35, 5)-'S is free on every path to here, and is/2 evaluates it: this call raises an instantiation error'),
    memberchk(finding(2, _, _, _, _, _, T2, _), Fs),
    check('a builtin the engine refuses unbound, from the table checked below', T2,
          'A is free on every path to here, and atom_length/2 will not take it unbound: this call raises an error'),
    memberchk(finding(3, _, _, _, _, _, T3, _), Fs),
    check('a closure with no goal in it', T3,
          'G is free on every path to here, so there is no goal to call: this raises an instantiation error'),
    memberchk(finding(5, _, _, _, _, _, T5, S5), Fs),
    check('left recursion through two predicates names both, and sees the other call', T5-S5,
          'ping/1 reaches itself again first, with the inputs it was given (ping/1 -> pong/1 -> ping/1): once this clause is reached it repeats for ever'-['p24.c1.g1']),
    memberchk(finding(10, _, _, _, _, _, T10, _), Fs),
    check('a grammar rule that calls itself before reading anything is named as the nonterminal', T10,
          'xs//0 calls itself before reading any input: parsing with it loops for ever'),
    memberchk(finding(6, _, _, _, _, _, T6, S6), Fs),
    check('the clause never tried, and the cut that keeps it out', T6-S6,
          'clause 2 of kind/2 is never tried for kind(+, -): clause 1 matches every such call and cuts before anything in it can fail'-['p11.c1.g1']),
    memberchk(finding(7, _, _, _, _, W7, T7, S7), Fs),
    check('a det promise broken by a goal that can fail: the comment''s line, the goal', W7-T7-S7,
          where('test/flowchart/faults.pl', 82, 1)-'first_pos/2 is documented as det (line 82) but can fail: when member(X, L) fails, so does the whole call'-['p13.c1.g1']),
    memberchk(finding(8, _, _, _, _, _, T8, _), Fs),
    check('... and by a goal that can answer again', T8,
          'pick_one/2 is documented as det (line 86) but can leave a choice point: member(X, L) can answer again'),
    memberchk(finding(9, _, _, _, _, _, T9, _), Fs),
    check('an unknown procedure, with the name it was probably meant to be', T9,
          'lenght/2 is defined nowhere: no clause, builtin, module or dynamic declaration answers it, so this call raises existence_error; did you mean length/2?'),
    %% the XML: the findings first, before the panels
    flow_xml(G, X),
    X = element(flow, _, [element(FN, FAs, FEls)|_]),
    findall(V, ( member(A, [count, errors, warnings]), memberchk(A=V, FAs) ), Vs),
    check('the XML opens with them: <findings count errors warnings>', FN-Vs, findings-[10, 7, 3]),
    FEls = [element(finding, F1As, _)|_],
    findall(V, ( member(A, [n, kind, severity, at, in, file, line, col]), memberchk(A=V, F1As) ), V1s),
    check('each one''s number, kind, severity, place and predicate', V1s,
          [1, instantiation, error, 'p2.c1.g1', 'total/2', 'test/flowchart/faults.pl', 35, 5]),
    findall(I, xml_any_id(X, I), XIds), msort(XIds, XSorted), sort(XIds, XSet),
    length(XSorted, NXI), length(XSet, NXS),
    check('every id in the XML names one element: a finding points with at= and ref=', NXI, NXS),
    %% the picture: a numbered disc on the box, and the count by the title
    scratch(D),
    atom_concat(D, '/faults', B),
    fx(faults, FF),
    flow_chart(check('+'), B, [source(FF)]),
    svg_doc(B, Svg),
    yes_no(( svg_element(Svg, p2, P2), svg_element(P2, f1, element(_, _, M1)),
             memberchk(element(title, _, [MT]), M1),
             atom_concat('1  --  error: S is free', _, MT) ), Y11),
    check('finding 1 is a disc in panel 2, its sentence on hover', Y11, yes),
    svg_texts(B, Txs),
    yes_no(memberchk('7 errors, 3 warnings  --  numbered on the chart, listed under it', Txs), Y12),
    check('the title says how many', Y12, yes),
    %% the command an agent runs prints them as a compiler would
    atomic_list_concat(['-s tools/flow/chart.pl -- \'check(+)\' test/flowchart/faults.pl ', D, '/cmdf'], A13),
    cocolog_run(A13, Out13, E13),
    yes_no(sub_atom(Out13, _, _, _, 'test/flowchart/faults.pl:35:5: error: total/2: S is free on every path to here'), Y13),
    check('tools/flow/chart.pl prints each finding as FILE:LINE:COL: error: ..., and exits 0', Y13-E13, yes-0),
    atom_concat(D, '/stop.pl', SP),
    open(SP, write, SS),
    format(SS, "stop :- fail, write(x).~n", []),
    close(SS),
    flow_graph(stop, G14, [source(SP)]),
    flow_xml(G14, X14),
    attr_of(X14, 'p1.c1.g2', reached, R14),
    check('nothing after fail runs', R14, false),
    %% clauses of one predicate not together: one finding, at the first
    %% clause that stands apart; one declared discontiguous has none
    atom_concat(D, '/apart.pl', AP),
    fixture(AP, ['go(X) :- a(X), b(X), c(X).', 'a(1).', 'b(1).', 'a(2).', 'c(1).', 'a(3).',
                 ':- discontiguous(c/1).', 'c(2).']),
    flow_graph(go(-), G15, [source(AP)]),
    flow_findings(G15, Fs15),
    check('a/1 in three places is one finding, at its second clause, after b/1''s -- c/1 is declared',
          Fs15,
          [finding(1, discontiguous, warning, 'p2.c2', 'a/1', where(AP, 4, 1),
                   'the clauses of a/1 are not together: clause 2 (line 4) comes after b/1 at line 3, and its clauses stand in 3 places; cocolog joins them without a word where SWI warns -- move them together, or declare :- discontiguous(a/1)',
                   ['p2.c1'])]),
    findings_twice(D),
    findings_catch(D),
    findings_load(D),
    findings_near(D),
    %% the table of calls the engine refuses unbound: every example raises,
    %% and for its unbound argument -- since 3.0.0 a code list is no text
    %% to string_concat/3, so string_concat(_, "a", _) raised type_error
    findall(Ex-F, ( flow_raises_unbound(_, _, _, Ex0), copy_term(Ex0, Ex),
                    ( catch(( call(Ex), fail ), error(F, _), true) -> true ; F = none ),
                    F \== instantiation_error ), Wrong),
    check('every call the refusal table names raises instantiation_error when made unbound', Wrong, []).

%% a predicate defined twice: a later place repeats a clause of an earlier
%% one, or holds a clause an earlier fact covers -- an error each, and no
%% discontiguous warning beside it (cicili-lang's cpp_thunk_params/4)
findings_twice(D) :-
    atom_concat(D, '/twice.pl', TP),
    fixture(TP, ['go2(L, N) :- len2(L, N), col2(apple, C), write(C).',
                 'len2([], 0).',
                 'len2([_|T], N) :- len2(T, N0), N is N0 + 1.',
                 'mid2(x).',
                 'len2([], 0).',
                 'len2([_|T], N) :- len2(T, M), N is M + 1.',
                 'col2(_, red).',
                 'mid3(y).',
                 'col2(apple, red).']),
    flow_graph(go2('+', '-'), G15b, [source(TP)]),
    flow_findings(G15b, Fs15b),
    findall(K15b-In15b-T15b, member(finding(_, K15b, _, _, In15b, _, T15b, _), Fs15b), KIT15b),
    check('a later place that repeats a clause, and one an earlier fact covers: defined twice, each',
          KIT15b,
          [defined_twice-'len2/2'-'len2/2 is defined twice: clause 3 (line 5) repeats clause 1 (line 2), and its clauses stand in 2 places; cocolog joins the two definitions into one predicate, so the second never answers first and every answer it gives comes again on backtracking -- keep one of them',
           defined_twice-'col2/2'-'col2/2 is defined twice: clause 2 (line 9) is covered by the fact at line 7 (clause 1), and its clauses stand in 2 places; cocolog joins the two definitions into one predicate, so the clause never answers first and every answer it gives the fact gave already -- keep one of them']).

%% a recovery runs with the ball in the catcher: a catcher that is a
%% variable is bound there, and one that is a pattern leaves its
%% variables partly bound -- cicili-lang's report, to the letter
findings_catch(D) :-
    atom_concat(D, '/catchmode.pl', CP),
    fixture(CP, ['go(F) :- catch(work(F), E, report(E)).',
                 'work(F) :- F > 1, throw(error(F, here)).',
                 'report(error(N, _)) :- ( N > 0 -> write(big) ; write(small) ), nl.',
                 'go2(F) :- catch(work(F), error(K, C), why(K, C)).',
                 'why(K, C) :- K > 0, atom_length(C, _).']),
    flow_graph(go('+'), G16, [source(CP)]),
    flow_findings(G16, Fs16),
    G16 = graph(_, _, Ps16, _, _),
    findall(K16-CM16, ( member(panel(I16, K16, _, CM16, _, _, _, _), Ps16), I16 > 0 ), KM16),
    check('the recovery sees the catcher bound: report/1 is called (+), and N > 0 raises nothing',
          Fs16-KM16, []-[go/1-['+'], work/1-['+'], report/1-['+']]),
    flow_graph(go2('+'), G17, [source(CP)]),
    flow_findings(G17, Fs17),
    G17 = graph(_, _, Ps17, _, _),
    findall(K17-CM17, ( member(panel(I17, K17, _, CM17, _, _, _, _), Ps17), I17 > 0 ), KM17),
    check('a catcher''s pattern leaves its variables partly bound: why/2 is called (?, ?)',
          Fs17-KM17, []-[go2/1-['+'], work/1-['+'], why/2-['?', '?']]).

%% a program of several files, charted a file at a time: what the top
%% file loads is defined (cicili-lang's ccl_check.pl took 237 calls into
%% its siblings for unknown). Read alone first -- a load lasts for the
%% process, and after it the sibling is defined whatever is asked
findings_load(D) :-
    atomic_list_concat([D, '/sib18.pl'], SibF18),
    atomic_list_concat([D, '/main18.pl'], MainF18),
    atomic_list_concat([D, '/top18.pl'], TopF18),
    fixture(SibF18, ['sib18_twice(X, Y) :- Y is X * 2.']),
    fixture(MainF18, ['main18_go(X, Y) :- sib18_twice(X, Y).']),
    format(atom(L1_18), ':- use_module(~q).', [MainF18]),
    format(atom(L2_18), ':- use_module(~q).', [SibF18]),
    fixture(TopF18, [L1_18, L2_18]),
    flow_graph(main18_go('+', '-'), G18, [source(MainF18)]),
    flow_findings(G18, Fs18),
    findall(K18-In18, member(finding(_, K18, _, _, In18, _, _, _), Fs18), KI18),
    check('read alone, the call into a sibling it does not load is unknown', KI18,
          [unknown_procedure-'main18_go/2']),
    flow_graph(main18_go('+', '-'), G19, [source(MainF18), load(TopF18)]),
    flow_findings(G19, Fs19),
    flow_xml(G19, X19),
    attr_of(X19, 'p1.c1.g1', kind, Kind19),
    attr_of(X19, 'p1.c1.g1', library, Lib19),
    check('load(Top): the sibling is defined -- a box, kind="library" library="loaded" -- and nothing is unknown',
          Fs19-Kind19-Lib19, []-library-loaded),
    catch(( flow_graph(main18_go('+', '-'), _, [source(MainF18), load('/nonexistent/x18.pl')]), E20 = none ),
          error(E20, _), true),
    check('a load that loads nothing is refused by name', E20, existence_error(flow_load, '/nonexistent/x18.pl')).

%% the near name is kept once a chart, never across two: a name the
%% first program had is no hint in the second
findings_near(D) :-
    atomic_list_concat([D, '/near21.pl'], NF21),
    atomic_list_concat([D, '/near22.pl'], NF22),
    fixture(NF21, ['go21 :- fooo_bar(1).', 'fooo_baz(_).']),
    fixture(NF22, ['go22 :- fooo_bar(1).']),
    flow_graph(go21, G21, [source(NF21)]),
    flow_findings(G21, [finding(_, unknown_procedure, _, _, _, _, T21, _)]),
    flow_graph(go22, G22, [source(NF22)]),
    flow_findings(G22, [finding(_, unknown_procedure, _, _, _, _, T22, _)]),
    yes_no(sub_atom(T21, _, _, _, 'did you mean fooo_baz/1?'), Y21),
    yes_no(sub_atom(T22, _, _, _, 'did you mean'), Y22),
    check('a near name is the chart''s own: fooo_baz/1 for the first program, nothing for the second', Y21-Y22, yes-no).

%% every id attribute of an XML term
xml_any_id(element(_, As, Cs), Id) :-
    (   memberchk(id=Id, As)
    ;   member(C, Cs), C = element(_, _, _), xml_any_id(C, Id)
    ).

%% the attributes of every goal of an XML term, in document order
xml_goal_attrs(element(N, As, Cs), A) :-
    (   N == goal, A = As
    ;   member(C, Cs), C = element(_, _, _), xml_goal_attrs(C, A)
    ).

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
    check('the XML reads back as a flow element, schema version 4', G3, flow-'4'),
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
    %% a root that calls 200 predicates stands at depth one with all of them
    %% its callees, which no depth thins: the stubs are budgeted too -- 150
    %% marked, the 50 calls past them unmarked, and the note says so
    wide_program(D, WF7),
    atom_concat(D, '/wide', B7),
    flow_chart(wide, B7, [source(WF7)]),
    svg_panels(B7, P7),
    findall(I7, member(I7-stub, P7), Stubs7),
    length(Stubs7, NS7),
    svg_note(B7, N7),
    check('a root of 200 callees: 150 stubs marked, and the note says 50 more', NS7-N7,
          150-'1 of 201 panels drawn, to depth 1  ·  150 stubs mark where the other 200 begin (and 50 more calls past the budget, unmarked)  ·  the XML has every one  ·  depth(D) or only([Name/Arity, ...]) draws others'),
    answer(flow_chart(report('+', '+', '+'), B1, [source(F), depth(0)]), yes, G5),
    check('depth(0) is refused by name', G5, error(error(domain_error(flow_depth, 0), flow_chart/3))),
    answer(flow_chart(report('+', '+', '+'), B1, [source(F), only(pick)]), yes, G6),
    check('only/1 wants a list of Name/Arity', G6, error(error(domain_error(flow_only, pick), flow_chart/3))).

%% ---- builtins: drawn by name, never gone inside -------------------------

builtins :-
    section('every builtin drawn by name, and the chart never goes inside one'),
    scratch(D),
    fx(demo, F),
    atom_concat(D, '/demo', B0),
    flow_chart(report('+', '+', '+'), B0, [source(F)]),
    svg_doc(B0, S0),
    %% grep_count/3: codes_lines(Text, Lines), findall(L, (member(L, Lines),
    %% re_match(Pat, L)), Hits), length(Hits, N)
    svg_title(S0, 'p2.c1.g2.g1', T1),
    check('member/2 is a box of its own, with its text', T1, 'member(L, Lines)  --  library(lists), nondet'),
    svg_element(S0, 'p2.c1.g2.g1', element(_, _, C2)),
    yes_no(svg_has_text(C2, '↻'), Y2),
    check('and it says it leaves a choice, which re_match/2''s failure goes back into', Y2, yes),
    svg_title(S0, 'p1.c1.g5', T3),
    check('so is format/2, which can neither fail nor leave a choice', T3,
          'format("~w lines (~w), first big: ~w~n", [N, Class, Big])  --  builtin, C in the engine, det'),
    svg_title(S0, 'p3.c1.g1.a1.if.g1', T4),
    check('and the test in classify/2''s first condition', T4, 'N < 0  --  test, semidet'),
    %% every goal the XML names is a box of its own in the picture, with its
    %% own text: nothing stands for anything else
    xml_file(B0, XC),
    xml_parse(XC, X0),
    findall(Id, xml_ids_of(X0, goal, Id), Ids),
    findall(Id, ( member(Id, Ids), svg_title(S0, Id, none) ), Untitled),
    length(Ids, NIds),
    check('every one of the XML''s goals is a box with its own text', NIds-Untitled, 19-[]),
    %% gallery.pl's lines_or_none/3 calls re_lines/3, library(text)'s, in
    %% Prolog over the C function re_match/2
    panels(check('+', '+'), gallery, [], Ps5),
    check('a library predicate is a box the chart does not go inside: no panel for re_lines/3, nor for the C under it',
          Ps5, [check/2-['+', '+']-semidet,
                sign_word/2-['+', '-']-nondet,
                lines_or_none/3-['+', '+', '-']-det]),
    panels(check('+', '+'), gallery, [libraries(reach)], Ps6),
    findall(K6, member(K6-_-_, Ps6), Keys6),
    check('libraries(reach) opens it, down to the C it reaches', Keys6,
          [check/2, sign_word/2, lines_or_none/3, re_lines/3, re_match/2]),
    %% the fail port: the last clause's lane leaves through the border at its
    %% own height -- one straight line from the last goal it serves
    findall(Dd, ( svg_red_arrow(S0, Dd), atomic_list_concat(Ws, ' ', Dd), append(_, ['L0', _], Ws) ), Ports),
    findall(Dd, ( member(Dd, Ports), \+ ( atomic_list_concat([M, Y, 'L0', Y], ' ', Dd), atom_concat('M', _, M) ) ), Bent),
    length(Ports, NPorts),
    check('each panel''s failure leaves straight through its left border, with no drop before it', NPorts-Bent, 5-[]),
    answer(flow_graph(report('+', '+', '+'), _, [source(F), libraries(maybe)]), yes, G8),
    check('libraries/1 is none, reach or all, by name', G8,
          error(error(domain_error(flow_libraries, maybe), flow_graph/3))).

%% the d of each red line that ends in an arrow
svg_red_arrow(element(N, As, Cs), Dd) :-
    (   N == path, memberchk('marker-end'='url(#a-red)', As), memberchk(d=Dd, As)
    ;   member(C, Cs), C = element(_, _, _), svg_red_arrow(C, Dd)
    ).

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

%% wide/0 calls w1 .. w200, each a fact
wide_program(D, F) :-
    atom_concat(D, '/wide.pl', F),
    numlist(1, 200, Ns),
    findall(G, ( member(N, Ns), format(atom(G), 'w~d', [N]) ), Gs),
    atomic_list_concat(Gs, ', ', Body),
    open(F, write, S),
    format(S, "wide :- ~w.~n", [Body]),
    forall(member(G, Gs), format(S, "~w.~n", [G])),
    close(S).

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

%% ---- threads and processes (F2) ------------------------------------------

threads :-
    section('threads and processes: a lane for each place code runs, a link for what crosses'),
    graph(all, threads, G),
    flow_xml(G, X),
    findall(Id1-K1-R1-S1-Gl1-C1-B1,
            ( xml_el(X, lane, element(_, A1, _)), memberchk(id=Id1, A1), Id1 \== l0,
              memberchk(kind=K1, A1), memberchk(root=R1, A1), memberchk(site=S1, A1),
              memberchk(goal=Gl1, A1), memberchk(copies=C1, A1), memberchk(returns=B1, A1) ),
            Ls1),
    %% what a spawn copies is what is bound where it stands: Ch and X, and
    %% neither the A of double(21, A) nor what httpd hands its page
    check('threads.pl: ten lanes beside the query''s -- the kind, root, site and goal of each, what it copies and what comes back',
          Ls1,
          [l1-thread-p20-'p2.c1.g2'-'worker(Ch)'-'Ch'-nothing,
           l2-pool-p23-'p3.c1.g1'-peek-nothing-nothing,
           l3-thread-p26-'p4.c1.g1'-'report(X)'-'X'-nothing,
           l4-thread-p28-'p5.c1.g1'-'report(d)'-nothing-nothing,
           l5-thread-p30-'p6.c1.g1'-'report(s)'-nothing-nothing,
           l6-thread-p32-'p9.c1.g1'-limit_ok-nothing-nothing,
           l7-isolated-p35-'p10.c1.g1'-peek-nothing-status,
           l8-crew-p38-'p13.c1.g2'-'double(21, A)'-nothing-unified,
           l9-httpd-p40-'p14.c1.g1'-'httpd_page(Path, Request, Reply)'-nothing-nothing,
           l10-thread-p43-'p15.c1.g1'-'double(21, A)'-nothing-nothing]),
    attr_of(X, 'p2.c1.g2', kind, K2), attr_of(X, 'p2.c1.g2', type, T2),
    attr_of(X, 'p2.c1.g2', lane, L2), attr_of(X, 'p2.c1.g2', calls, C2),
    attr_of(X, p20, kind, K2r), attr_of(X, p20, lane, L2r), attr_of(X, 'p20.c0.g1', calls, C2r),
    check('a spawn names its lane and calls the root; the root, a panel of kind lane, calls the predicate''s panel in that lane',
          [K2, T2, L2, C2, K2r, L2r, C2r], [spawn, thread, l1, p20, lane, l1, p21]),
    findall(I3-L3, ( xml_el(X, panel, element(_, A3, _)), memberchk(pred='report/1', A3),
                     memberchk(id=I3, A3), memberchk(lane=L3, A3) ), RL3),
    check('a predicate reached in five places is drawn in each: report/1 in l0, l1, l3, l4 and l5', RL3,
          [p19-l0, p22-l1, p27-l3, p29-l4, p31-l5]),
    findall(Id4-At4-L4-H4-C4, ( xml_el(X, join, element(_, A4, _)), memberchk(id=Id4, A4), memberchk(at=At4, A4),
                                memberchk(lane=L4, A4), memberchk(how=H4, A4), memberchk(carries=C4, A4) ), J4),
    check('each join and detach, the lane it is about, and what it reads back: a status, never a binding', J4,
          [j1-'p2.c1.g5'-l1-join-status, j2-'p3.c1.g2'-l2-join-status, j3-'p5.c1.g2'-l4-detach-nothing,
           j4-'p9.c1.g2'-l6-join-status, j5-'p15.c1.g2'-l10-join-status]),
    %% the send stands in send_all/2, handed the channel as an argument; the
    %% receive in worker/1, in the thread the spawn copied it to
    findall(Id5-M5-Ops5, ( xml_el(X, channel, element(_, A5, C5)), memberchk(id=Id5, A5),
                           ( memberchk(made=M5, A5) -> true ; M5 = none ),
                           findall(Op5-At5, ( member(element(Op5, OA5, _), C5), memberchk(at=At5, OA5) ), Ops5) ),
            Ch5),
    check('one channel, followed from channel_new/1 into an argument and across a spawn', Ch5,
          [ch1-'p2.c1.g1'-[close-'p2.c1.g4', send-'p16.c2.g1', receive-'p21.c1.g1']]),
    attr_of(X, 'p21.c1.g1', kind, K6), attr_of(X, 'p21.c1.g1', role, R6), attr_of(X, 'p21.c1.g1', channel, C6),
    check('the receive in the worker''s lane names the channel the query''s lane made', K6-R6-C6, thread-recv-ch1),
    findall(Id7-At7-Op7-N7, ( xml_el(X, lock, element(_, A7, _)), memberchk(id=Id7, A7), memberchk(at=At7, A7),
                              memberchk(op=Op7, A7), memberchk(name=N7, A7) ), K7),
    check('every lock, taken by hand and by with_mutex/2', K7,
          [k1-'p7.c1.g1'-lock-log, k2-'p7.c1.g3'-unlock-log, k3-'p8.c1.g1'-lock-log,
           k4-'p8.c1.g3'-unlock-log, k5-'p21.c1.g3'-with-log]),
    findall(Id8-As8, ( xml_el(X, process, element(_, A8, _)), memberchk(id=Id8, A8),
                       findall(N8=V8, ( member(N8=V8, A8), memberchk(N8, [at, command, chart]) ), As8) ), P8),
    check('a child process is the end of the chart: its command, and the chart of the file it runs cocolog on', P8,
          [x1-[at='p11.c1.g1', command='ls -l'],
           x2-[at='p12.c1.g1', command='./cocolog -s test/flowchart/demo.pl', chart='test/flowchart/demo.pl']]),
    findall(Id9-At9-Op9-Pr9, ( xml_el(X, write, element(_, A9, _)), memberchk(id=Id9, A9), memberchk(at=At9, A9),
                               memberchk(op=Op9, A9), memberchk(pred=Pr9, A9) ), W9),
    check('the writes to the knowledge base, and of what', W9,
          [w1-'p17.c1.g1'-retract-'tally/1', w2-'p17.c1.g3'-assertz-'tally/1']),
    findall(I10, xml_any_id(X, I10), XIds10), msort(XIds10, XS10), sort(XIds10, XU10),
    length(XS10, NS10), length(XU10, NU10),
    check('every id names one element: lanes, links and panels alike', NS10, NU10),
    threads_handed,
    threads_findings(G),
    threads_picture.

%% a channel handed on twice -- go/0 to feed/1, feed/1 to put/1 -- is still
%% the one channel_new/1 made: each pass of the analysis looks at the
%% panels the passes before handed one. And a clause whose one goal of
%% library(thread) is a with_mutex/2 is a clause a link is about
threads_handed :-
    scratch(D),
    atom_concat(D, '/handed.pl', HF),
    open(HF, write, HS),
    format(HS, "go :- channel_new(Ch), thread_create(eat(Ch), Id), feed(Ch), thread_join(Id, _), note(done), sh(\"ls -a\", _).~nfeed(Ch) :- put(Ch).~nput(Ch) :- channel_send(Ch, x).~neat(Ch) :- channel_recv(Ch, _).~nnote(X) :- with_mutex(log, format(\"~~w~~n\", [X])).~n", []),
    close(HS),
    flow_graph(go, GH, [source(HF)]),
    flow_xml(GH, XH),
    findall(Op23-At23, ( xml_el(XH, channel, element(_, A23, C23)), memberchk(id=ch1, A23),
                         member(element(Op23, OA23, _), C23), memberchk(at=At23, OA23) ), Ops23),
    check('a channel handed on twice, and across a spawn, is followed to each end', Ops23,
          [send-'p4.c1.g1', receive-'p6.c1.g1']),
    findall(At24-Op24, ( xml_el(XH, lock, element(_, A24, _)), memberchk(at=At24, A24), memberchk(op=Op24, A24) ), K24),
    check('a with_mutex/2 alone in its clause is a lock', K24, ['p3.c1.g1'-with]),
    findall(Cmd26, ( xml_el(XH, process, element(_, A26, _)), memberchk(command=Cmd26, A26) ), C26),
    check('a command written in double quotes -- codes, as cocolog reads them -- is still its command', C26, ['ls -a']),
    atom_concat(D, '/nest.pl', NF),
    open(NF, write, NS),
    format(NS, "go :- thread_create(outer, Id), thread_join(Id, _).~nouter :- thread_create(inner, I2), thread_join(I2, _).~ninner :- true.~n", []),
    close(NS),
    flow_graph(go, GN, [source(NF)]),
    flow_xml(GN, XN),
    findall(L25-F25-S25, ( xml_el(XN, lane, element(_, A25, _)), memberchk(id=L25, A25), L25 \== l0,
                           memberchk(from=F25, A25), memberchk(site=S25, A25) ), Ls25),
    check('a spawn inside a lane starts a lane of its own, from that lane', Ls25,
          [l1-l0-'p1.c1.g1', l2-l1-'p3.c1.g1']).

%% three thread findings and a binding a thread never hands back; the
%% detached, the handed-back and the joined threads, the lock round a goal
%% that cannot fail, cowork_ask/2's answer and limit/1, which nobody writes,
%% are no finding
threads_findings(G) :-
    flow_findings(G, Fs),
    findall(N11-K11-At11-In11, member(finding(N11, K11, _, At11, In11, _, _, _), Fs), F11),
    check('threads.pl: six findings, in document order -- and nothing from the near misses', F11,
          [1-thread_unjoined-'p4.c1.g1'-'fire/1',
           2-lock_held-'p7.c1.g1'-'locked/1',
           3-instantiation-'p15.c1.g3'-'lost/1',
           4-thread_visibility-'p24.c1.g1'-'peek/0',
           5-thread_visibility-'p36.c1.g1'-'peek/0',
           6-thread_visibility-'p41.c1.g1'-'httpd_page/3']),
    memberchk(finding(3, _, _, _, _, _, T12, _), Fs),
    check('nothing a thread binds comes back: A is free after thread_join/2, where cowork_ask/2 unifies its answer back', T12,
          'A is free on every path to here, and is/2 evaluates it: this call raises an instantiation error'),
    memberchk(finding(2, _, _, _, _, _, T13, S13), Fs),
    check('a lock with a way out that keeps it, and the goal that is that way', T13-S13,
          'mutex_lock(log) is not released on every way out: when check(J) fails, the clause leaves holding the lock, and the next mutex_lock(log) waits for ever -- with_mutex(log, Goal) releases it on success, on failure and on an exception alike'-['p7.c1.g2']),
    memberchk(finding(4, _, _, _, _, _, T14, S14), Fs),
    check('a pool''s thread never sees what the query''s lane writes, and the write is named', T14-S14,
          'tally/1 is written in lane l0 (retract/1 at p17.c1.g1), and this goal runs in lane l2, each thread of a pool: a thread has no connection to the knowledge base, and its store starts with the clauses of the modules loaded before it and none of what was asserted, so it never sees that write'-['p17.c1.g1']),
    memberchk(finding(5, _, _, _, _, _, T15, _), Fs),
    check('an isolated proof has a connection, and still not the write of a turn still running', T15,
          'tally/1 is written in lane l0 (retract/1 at p17.c1.g1), and this goal runs in lane l7, a fresh machine and store, the caller waiting: its proof has a connection of its own, and its store holds the modules'' clauses and, under --kb or --embed, what was committed when it began -- never a write of a turn still running -- so it does not see that write while the turn that made it runs'),
    %% a program with no thread in it: one lane, nothing crossing
    graph(report('+', '+', '+'), demo, GD),
    flow_xml(GD, XD),
    answer(( xml_el(XD, lanes, element(_, AD16, LD16)), memberchk(count=ND16, AD16),
             xml_el(XD, links, element(_, _, KD16)) ), ND16-LD16-KD16, G16),
    check('demo.pl: the query''s lane alone, and no links', G16,
          1-[element(lane, [id=l0, kind=query, root=query], [])]-[]).

%% the picture: a heavy dashed wire into each root, the answers that come
%% back, the message line, a band for each lane
threads_picture :-
    scratch(D),
    atom_concat(D, '/threads', B17),
    fx(threads, F17),
    flow_chart(all, B17, [source(F17)]),
    svg_doc(B17, S17),
    xml_file(B17, XC17), xml_parse(XC17, X17),
    findall(I17, xml_ids_of(X17, goal, I17), XI17),
    findall(J17, ( member(J17, XI17), svg_title(S17, J17, none) ), U17),
    length(XI17, N17),
    check('every goal of every lane is a box in the picture', N17-U17, 79-[]),
    svg_paths(S17, '#7c3aed', '9 5', N18),
    check('a heavy dashed wire for each of the ten spawns (and the legend''s)', N18, 11),
    svg_paths(S17, '#7c3aed', none, N19),
    check('run_isolated/2''s status and cowork_ask/2''s answer come back on a thin wire', N19, 2),
    svg_paths(S17, '#7c3aed', '2 2', N20),
    check('the status the four joins in a spawn''s own panel read comes back dotted; the detach reads nothing', N20, 4),
    svg_paths(S17, '#2f5bd3', '2 4', N21),
    check('ch1''s send and receive are tied by a dotted message line (and the legend''s)', N21, 2),
    svg_texts(B17, Tx22),
    findall(H22, ( member(H22, Tx22), atom_concat('lane l', _, H22) ), Hs22),
    check('a band for each lane but the query''s, saying what it is', Hs22,
          ['lane l1  ·  thread', 'lane l2  ·  pool', 'lane l3  ·  thread', 'lane l4  ·  thread',
           'lane l5  ·  thread', 'lane l6  ·  thread', 'lane l7  ·  isolated', 'lane l8  ·  crew',
           'lane l9  ·  httpd', 'lane l10  ·  thread']).

%% the failure lanes of a panel that leave through its left border
svg_port_lanes(S, PId, N) :-
    (   svg_element(S, PId, P) -> true ; P = element(g, [], []) ),
    findall(x, ( xml_el(P, path, element(_, As, _)), memberchk('marker-end'='url(#a-red)', As),
                 memberchk(d=D, As), sub_atom(D, _, _, _, ' L0 ') ),
            Xs),
    length(Xs, N).

%% every element of that name, in document order
xml_el(element(N, As, Cs), Name, E) :-
    (   N == Name, E = element(N, As, Cs)
    ;   member(C, Cs), C = element(_, _, _), xml_el(C, Name, E)
    ).

%% how many paths of that stroke and dash (none: not dashed) an SVG draws
svg_paths(S, Stroke, Dash, N) :-
    findall(x, ( xml_el(S, path, element(_, As, _)), memberchk(stroke=Stroke, As),
                 (   Dash == none -> \+ memberchk('stroke-dasharray'=_, As)
                 ;   memberchk('stroke-dasharray'=Dash, As)
                 ) ),
            Xs),
    length(Xs, N).

%% ---- what crosses: the cases F2 left ------------------------------------
%%
%% crossing.pl, a predicate charted at a time: a crew handed jobs, a server
%% on the caller's thread, handles and channels followed through heads,
%% callers, terms and other channels, and the order a channel's messages
%% are taken in

crossing :-
    section('what crosses: jobs, a server here, handles and channels followed, the order of messages'),
    crossing_jobs,
    crossing_here,
    crossing_followed,
    crossing_order,
    crossing_picture.

%% a crew handed a list of jobs: a lane, a row a job, each proved alone
crossing_jobs :-
    graph(jobs('-', '-', '-'), crossing, G1),
    flow_xml(G1, X1),
    findall(L1-R1-S1-Gl1-C1-B1,
            ( xml_el(X1, lane, element(_, A1, _)), memberchk(id=L1, A1), L1 \== l0,
              memberchk(root=R1, A1), memberchk(site=S1, A1), memberchk(goal=Gl1, A1),
              memberchk(copies=C1, A1), memberchk(returns=B1, A1) ),
            Ls1),
    check('cowork_map/3: a lane each, its jobs as the source writes them, what they copy, and a copy back', Ls1,
          [l1-p3-'p1.c1.g3'-'[(half(A, H), H > 1), double(X, A), double(2, B)]'-'X'-copy,
           l2-p6-'p1.c1.g5'-'[double(5, _)|Gs]'-'Gs'-copy,
           l3-p8-'p1.c1.g6'-'Gs'-'Gs'-copy]),
    findall(J2-N2-Rt2, ( xml_el(X1, job, element(_, A2, _)), memberchk(id=J2, A2), memberchk(n=N2, A2),
                         ( memberchk(rest=Rt2, A2) -> true ; Rt2 = no ) ),
            Js2),
    check('a <job> for each, and one more for the rest of a list the source does not write', Js2,
          ['p3.c1'-1-no, 'p3.c2'-2-no, 'p3.c3'-3-no, 'p6.c1'-1-no, 'p6.c2'-2-true, 'p8.c1'-1-true]),
    attr_of(X1, 'p3.c1.g1', line, Ln3), attr_of(X1, 'p3.c1.g1', col, Cl3),
    attr_of(X1, 'p6.c2.g1', text, T3), attr_of(X1, 'p6.c2.g1', kind, K3),
    check('each job stands where the source writes it, and the rest is a goal known only when it runs',
          Ln3-Cl3-T3-K3, 23-21-'call(Gs)'-closure),
    flow_findings(G1, Fs4),
    findall(K4-At4-In4, member(finding(_, K4, _, At4, In4, _, _, _), Fs4), F4),
    check('each job is proved on its own: the A job 1 halves is free there, whatever job 2 binds', F4,
          [instantiation-'p4.c1.g1'-'half/2']).

%% an httpd server with no pool: the page runs here, in the caller's lane
crossing_here :-
    graph(serve, crossing, G5),
    flow_xml(G5, X5),
    attr_of(X5, 'p1.c1.g2', name, N5), attr_of(X5, 'p1.c1.g2', can_fail, CF5),
    attr_of(X5, 'p1.c1.g2.g1', text, T5), attr_of(X5, 'p1.c1.g2.g1', modes, M5),
    attr_of(X5, 'p1.c1.g2.g1', calls, C5), attr_of(X5, 'p1.c1.g2.g1', on_fail, O5),
    attr_of(X5, C5, lane, L5),
    check('httpd_serve/2 with no workers is a construct: the page, called here with its path and request; a failure is a 404',
          [N5, CF5, T5, M5, L5, O5],
          [httpd_serve, false, 'httpd_page(Path, Request, Reply)', '+ + -', l0, 'p1.c1.g2:next']),
    flow_findings(G5, Fs6),
    findall(K6-At6, member(finding(_, K6, _, At6, _, _, _, _), Fs6), F6),
    check('the page here reads what its own lane writes: only the pool''s copy is a finding', F6,
          [thread_visibility-'p6.c1.g1']).

%% a handle and a channel followed: up through a head, down through a
%% call, inside a term, down another channel
crossing_followed :-
    graph(handles, crossing, G7),
    flow_xml(G7, X7),
    findall(At7-L7, ( xml_el(X7, join, element(_, A7, _)), memberchk(at=At7, A7), memberchk(lane=L7, A7) ), J7),
    check('each join reads the lane whose handle it holds: two in one list, a pool''s by member/2, one handed back up and on down',
          J7, ['p1.c1.g4'-l3, 'p1.c1.g4'-l4, 'p1.c1.g6.g2'-l1, 'p3.c1.g1'-l2]),
    graph(terms, crossing, G8),
    flow_xml(G8, X8),
    findall(Op8-At8, ( xml_el(X8, channel, element(_, A8, C8)), memberchk(id=ch1, A8),
                       member(element(Op8, OA8, _), C8), memberchk(at=At8, OA8) ), Ops8),
    check('a channel inside a term is followed out of it by a head, by =/2 and by arg/3', Ops8,
          [send-'p1.c1.g5', close-'p1.c1.g6', receive-'p3.c1.g1', receive-'p6.c1.g2', receive-'p9.c1.g2']),
    graph(reply, crossing, G9),
    flow_xml(G9, X9),
    (   xml_el(X9, channel, element(_, A9, C9)), memberchk(id=ch2, A9) -> true ; A9 = [], C9 = [] ),
    findall(Op9-At9, ( member(element(Op9, OA9, _), C9), memberchk(at=At9, OA9) ), Ops9),
    (   memberchk(via=V9, A9) -> true ; V9 = none ),
    check('a channel sent down another is followed into the thread that takes it, and says which carried it',
          V9-Ops9, ch1-[receive-'p1.c1.g5', send-'p4.c1.g2']).

%% the k-th send is the k-th receive's where one lane sends and one takes,
%% each its messages in an order known; none has a place in a loop, a
%% recursion or a pool
crossing_order :-
    graph(order, crossing, G10),
    flow_xml(G10, X10),
    (   xml_el(X10, channel, element(_, A10, C10)), memberchk(id=ch1, A10) -> true ; A10 = [], C10 = [] ),
    findall(Op10-At10-N10, ( member(element(Op10, OA10, _), C10), memberchk(at=At10, OA10),
                             ( memberchk(n=N10, OA10) -> true ; N10 = none ) ), Ops10),
    (   memberchk(pairs=P10, A10) -> true ; P10 = false ),
    check('three messages in order: each send and receive its place, two of them one helper''s called twice; they pair',
          P10-Ops10,
          true-[send-'p1.c1.g3'-'1', close-'p1.c1.g6'-none, send-'p2.c1.g1'-'2 3',
                receive-'p4.c1.g1'-'1', receive-'p4.c1.g2'-'2', receive-'p5.c1.g1'-'3']),
    findall(Q11-P11, ( member(Q11, [maybe, spin, pooled, choose]),
                       graph(Q11, crossing, G11), flow_xml(G11, X11),
                       xml_el(X11, channel, element(_, A11, _)),
                       ( memberchk(pairs=P11, A11) -> true ; P11 = false ) ),
            Ps11),
    check('a send in one clause of two, in a recursion or after a goal that can be redone, a receive in a pool: no place, no pairs',
          Ps11, [maybe-false, spin-false, pooled-false, choose-false]).

%% what the picture adds: jobs that fail answered `failed', a fine line to
%% each join elsewhere, numbered message lines, and a root with no redo
crossing_picture :-
    scratch(D),
    fx(crossing, F),
    atom_concat(D, '/jobs', B12),
    flow_chart(jobs('-', '-', '-'), B12, [source(F)]),
    svg_texts(B12, Tx12),
    findall(H12, ( member(H12, Tx12), atom_concat('cowork_map/3: ', _, H12) ), Hs12),
    msort(Hs12, Ss12),
    findall(x, member(failed, Tx12), Fd12), length(Fd12, NF12),
    svg_doc(B12, S12),
    svg_port_lanes(S12, p3, NP12),
    check('a jobs root says how many, and each job that can fail -- the first, too -- leaves through the border, failed',
          Ss12-NF12-NP12,
          ['cowork_map/3: 1 job, then each of Gs', 'cowork_map/3: 3 jobs', 'cowork_map/3: each job of Gs']-3-1),
    atom_concat(D, '/handles', B13),
    flow_chart(handles, B13, [source(F)]),
    svg_doc(B13, S13),
    svg_paths(S13, '#7c3aed', '2 3', N13),
    check('a fine dotted line from each lane joined outside its spawn''s panel to its join (and the legend''s)', N13, 4),
    atom_concat(D, '/order', B14),
    flow_chart(order, B14, [source(F)]),
    svg_texts(B14, Tx14),
    findall(T14, ( member(T14, Tx14), atom_concat(ch1, _, T14), T14 \== ch1,
                   \+ atom_concat('send ', _, T14) ), Ls14),
    msort(Ls14, Ss14),
    check('a paired channel ties each send to the receive that takes it alone, numbered', Ss14,
          ['ch1 #1', 'ch1 #2', 'ch1 #3']),
    atom_concat(D, '/serve', B16),
    flow_chart(serve, B16, [source(F)]),
    svg_doc(B16, S16),
    svg_title(S16, 'p1.c1.g2.g1', T16),
    (   sub_atom(T16, 0, 32, _, P16) -> true ; P16 = T16 ),
    check('the page inside the construct names what it is handed, as its lane''s root does', P16,
          'httpd_page(Path, Request, Reply)'),
    atom_concat(D, '/once', B15),
    flow_chart(once_root, B15, [source(F)]),
    svg_texts(B15, Tx15),
    findall(x, member('↶', Tx15), Rd15), length(Rd15, NR15),
    check('a lane''s root is proved once: no redo marks it, where its own clause and work/1''s have one (and the legend)', NR15, 3).

%% ---- cicili-lang's gate ---------------------------------------------------
%%
%% That session charts each file of its library from a root that calls every
%% predicate the file defines, its arguments unknown, and holds the findings
%% to a baseline (1.11.4). Its report named what the chart said wrongly there
%% and what it could not see; gate.pl has each in small. The charts without
%% the options come first: a load, and a module's rows, last for the process.

gate :-
    section('cicili-lang''s gate: sinks, text that binds, a caught absence, run-time declarations, its own modules'),
    fx(gate, F),
    flow_graph(gt_all/2, G0, [source(F)]),
    flow_findings(G0, Fs0),
    findall(In0, member(finding(_, unknown_procedure, error, _, In0, _, _, _), Fs0), Un0),
    check('alone, a table its loaded file declares, its module''s C predicate and its module''s library''s table are unknown',
          Un0, ['gt_bad/2', 'gt_lib/1', 'gt_nobody/1', 'gt_native/2', 'gt_half/2']),
    (   getenv('COCOLOG_LIBRARY', Lib0) -> atomic_list_concat(['test/flowchart:', Lib0], Lib1)
    ;   Lib0 = none, Lib1 = 'test/flowchart'
    ),
    setenv('COCOLOG_LIBRARY', Lib1),
    answer(( flow_graph(gt_all/2, G1, [source(F), load('test/flowchart/gate_lib.pl'),
                                       modules('test/flowchart/gate_mod.cicili')]),
             flow_findings(G1, Fs1) ), G1-Fs1, R1),
    (   Lib0 == none -> unsetenv('COCOLOG_LIBRARY') ; setenv('COCOLOG_LIBRARY', Lib0) ),
    (   R1 = G1-Fs1 -> true
    ;   check('the chart with load(Files) and modules(Files) runs', R1, ran), fail
    ),
    findall(Kd-Sev-In, member(finding(_, Kd, Sev, _, In, _, _, _), Fs1), KSI),
    %% item 3: format(atom(A), ...) and with_output_to(string(S), ...) bind
    %% A and S, so sub_atom/5 and split_string/4 are not refused
    findall(In3, ( member(_-_-In3, KSI), memberchk(In3, ['gt_nan/1', 'gt_wo/2']) ), Sink),
    check('a sink binds its variable: nothing found in gt_nan/1 or gt_wo/2', Sink, []),
    %% item 4: atomic_list_concat([op, W|_], '.', Name) binds W, and each
    %% segment of a list a split by length/2 and append/3 cut; and since
    %% 3.0.0 a text read from a list binds the list's elements
    findall(In4, ( member(_-_-In4, KSI),
                   memberchk(In4, ['gt_fn/2', 'gt_spell/2', 'gt_member/3', 'gt_split/4',
                                   'gt_alen/1', 'gt_slen/1', 'gt_astr/1', 'gt_sspl/1']) ), Text4),
    check('text made from text binds every argument: nothing found in gt_spell/2 and its callers, nor past a text read from a list',
          Text4, []),
    %% item 5: under a catch that takes the existence error, a warning
    findall(Sev5-In5, ( member(unknown_procedure-Sev5-In5, KSI), memberchk(In5, ['gt_big/2', 'gt_bad/2']) ), Caught),
    check('an unknown call under a catch that takes its error is a warning; under one that does not, an error',
          Caught, [warning-'gt_big/2', error-'gt_bad/2']),
    (   member(finding(_, _, _, _, 'gt_big/2', _, T5, _), Fs1),
        sub_atom(T5, _, _, _, 'which the catch/3 around it takes') -> Y5 = yes ; Y5 = no ),
    check('and says the catch takes it', Y5, yes),
    %% item 6: declared as the program runs -- a declarer called with the
    %% name written out, dynamic/1, an assert, and a file it loads
    findall(In6, ( member(unknown_procedure-_-In6, KSI),
                   memberchk(In6, ['gt_look/2', 'gt_was/1', 'gt_count/1', 'gt_lib/1', 'gt_nobody/1']) ), Decl),
    check('a table declared as the program runs is no unknown procedure: only gt_nobody/1''s is', Decl, ['gt_nobody/1']),
    flow_xml(G1, X1),
    findall(T6-K6, ( member(T6, ['gt_cache(K, V)', 'gt_seen(X)', 'gt_hits(N)', 'gl_table(X)']),
                     once(( xml_goal_attrs(X1, As6), memberchk(text=T6, As6) )),
                     memberchk(kind=K6, As6) ), Ks6),
    check('each is a dynamic predicate''s call', Ks6,
          ['gt_cache(K, V)'-dynamic, 'gt_seen(X)'-dynamic, 'gt_hits(N)'-dynamic, 'gl_table(X)'-dynamic]),
    %% item 7: the module's rows, and the table of the library its half loads
    findall(In7, ( member(_-_-In7, KSI), memberchk(In7, ['gt_native/2', 'gt_half/2']) ), Mod7),
    check('modules(Files): its C predicate and its library''s table are known', Mod7, []),
    findall(A7, ( member(A7n, [kind, module, cfun, file, line, modes, head]),
                  xml_pred_attr(X1, 'gm_lex/3', A7n, A7) ), As7),
    check('gm_lex/3 is a portal of gate_mod, its row''s C function and line, the header''s modes and names', As7,
          [c, gate_mod, gm_p_lex, 'test/flowchart/gate_mod.cicili', 12, '+ + -', 'gm_lex(+Text, +Line0, -Tokens)']),
    answer(flow_t_portal(gate_mod, gm_version, 1, CF8, _, _, Ms8, Ns8), CF8-Ms8-Ns8, G8),
    check('a row''s own comment names its modes: gm_version(-V)', G8, gm_p_version-['-']-['V']),
    check('and nothing else is found', KSI,
          [unknown_procedure-warning-'gt_big/2', unknown_procedure-error-'gt_bad/2',
           unknown_procedure-error-'gt_nobody/1']),
    gate_rows,
    gate_clash.

%% the extension point: a file of flow_t_portal/8 rows, given to load(Files),
%% adds a module's C predicates by hand -- and a table's rows are no clash
gate_rows :-
    scratch(D),
    atomic_list_concat([D, '/rows.pl'], RF),
    atomic_list_concat([D, '/use.pl'], UF),
    fixture(RF, ['flow_t_portal(gate_rows, gr_native, 1, gr_p_native, ''gr.cicili'', 3, [''+''], [''X'']).']),
    fixture(UF, ['gr_go(X) :- gr_native(X).']),
    flow_graph(gr_go('+'), G, [source(UF), load(RF)]),
    flow_findings(G, Fs),
    flow_xml(G, X),
    attr_of(X, 'p1.c1.g1', module, M),
    check('flow_t_portal/8 rows loaded with load(Files) make a C predicate, and are no clash', Fs-M, []-gate_rows).

%% a helper named as the library's own: its clause would join the library's,
%% so the chart refuses it by name -- in a process of its own, since the
%% clause, once loaded, stays joined
gate_clash :-
    scratch(D),
    atomic_list_concat([D, '/clash'], B),
    atomic_list_concat(['-s tools/flow/chart.pl -- gt_nan/1 test/flowchart/gate.pl ', B,
                        ' load=test/flowchart/gate_clash.pl 2>&1'], A),
    cocolog_run(A, T, E),
    (   sub_atom(T, _, _, _, 'flow_trim/2 is library(flow/chart)''s own predicate'),
        sub_atom(T, _, _, _, 'gate_clash.pl gives it clauses of its own') -> Y = yes ; Y = no ),
    check('a helper named flow_trim/2 is refused by name: exit 2, the predicate and the file', E-Y, 2-yes),
    %% one the program loaded itself -- the library first, then an
    %% ensure_loaded/1 in its query -- is in none of the chart's files, and
    %% through 1.11.4 joined unseen; and a flow_ predicate the library does
    %% not have is the program's, however many files give it clauses -- the
    %% check of 1.11.4 called flow_mine/1 the library's own (1.11.7)
    atomic_list_concat([D, '/w3.pl'], WF),
    atomic_list_concat([D, '/mine1.pl'], M1),
    atomic_list_concat([D, '/mine2.pl'], M2),
    fixture(M1, ['flow_mine(a).']),
    fixture(M2, ['flow_mine(b).']),
    format(atom(WL1), 'w3 :- ensure_loaded(''test/flowchart/gate_clash.pl''), w3_chart([]).', []),
    format(atom(WL2), 'w4 :- ensure_loaded(''~w''), w3_chart([load(''~w'')]).', [M2, M1]),
    fixture(WF, [ ':- use_module(library(flow/chart)).',
                  WL1, WL2,
                  'w3_chart(Opts) :-',
                  '    catch(( flow_graph(gt_nan/1, _, [source(''test/flowchart/gate.pl'')|Opts]), write(charted), nl ),',
                  '          error(permission_error(modify, flow_procedure, P), context(_, M)),',
                  '          ( write(P), nl, write(M), nl, halt(2) )).' ]),
    atomic_list_concat(['run ', WF, ' w3 2>&1'], A3),
    cocolog_run(A3, T3, E3),
    (   sub_atom(T3, 0, _, _, 'flow_trim/2'),
        sub_atom(T3, _, _, _, 'the program gave it 1 clause of its own from a file it loaded itself') -> Y3 = yes ; Y3 = no ),
    check('flow_trim/2 loaded by the program itself, after the library, is refused too: the predicate, and that no file the chart reads gave it',
          E3-Y3, 2-yes),
    atomic_list_concat(['run ', WF, ' w4 2>&1'], A4),
    cocolog_run(A4, T4, E4),
    check('flow_mine/1, the program''s own in two files, is no clash', E4-T4, 0-charted),
    atomic_list_concat(['-s tools/flow/chart.pl -- gt_native/2 test/flowchart/gate.pl ', B,
                        ' modules=test/flowchart/gate_mod.cicili'], A2),
    cocolog_run(A2, T2, E2),
    yes_no(sub_atom(T2, _, _, _, 'gm_lex/3 is defined nowhere'), Y2),
    check('modules=SRC on the command line', E2-Y2, 0-no).

%% an attribute of the panel of a predicate, in the XML
xml_pred_attr(X, PA, Name, V) :-
    answer(( xml_panel_pred(X, PA, As), memberchk(Name=V0, As) ), V0, V).

xml_panel_pred(element(N, As, Cs), PA, As1) :-
    (   N == panel, memberchk(pred=PA, As) -> As1 = As
    ;   member(C, Cs), C = element(_, _, _), xml_panel_pred(C, PA, As1)
    ), !.

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
    check('an option it does not know is exit 2', E3, 2),
    %% progress on stderr once a chart has run S seconds: a quick chart says
    %% nothing by default, and progress=0.0001 says each part as it starts
    cocolog_out(A1, O4c),
    atom_codes(O4, O4c),
    yes_no(sub_atom(O4, _, _, _, 'chart: '), Y4),
    atomic_list_concat([A1, ' progress=0.0001'], A5),
    cocolog_out(A5, O5c),
    atom_codes(O5, O5c),
    yes_no(( sub_atom(O5, _, _, _, 'chart: the analysis, at '),
             sub_atom(O5, _, _, _, 'chart: the findings, at '),
             sub_atom(O5, _, _, _, 'chart: done, ') ), Y5),
    check('progress: nothing from a quick chart, and each part from progress=S', Y4-Y5, no-yes).

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
