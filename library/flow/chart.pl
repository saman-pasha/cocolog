%% library(flow/chart) -- a predicate drawn as a flowchart: from the query
%% down to the C it reaches, and back -- as an SVG for a person and an XML
%% for a program.
%%
%%     :- use_module(library(flow/chart)).
%%
%%     flow_chart(+Spec, +Base)               Base.svg and Base.xml
%%     flow_chart(+Spec, +Base, +Options)
%%     flow_chart(+Spec, +Base, +Options, -Findings)
%%     flow_graph(+Spec, -Graph, +Options)    the analysis, as a term
%%     flow_findings(+Graph, -Findings)       what is wrong, and where
%%     flow_svg(+Graph, -Svg)                 the documents, as library(xml)
%%     flow_svg(+Graph, -Svg, +Options)       terms
%%     flow_xml(+Graph, -Xml)
%%
%%     cocolog -s tools/flow/chart.pl -- SPEC FILE BASE [OPTION ...]
%%
%% Spec is a call pattern -- report(+, +, +) -- or Name/Arity, which reads
%% every argument as `?', or Name//Arity, a nonterminal called to parse:
%% its list `+', what is left `-'. NOTHING IS RUN: the program is read and
%% analysed. Options:
%%
%%     source(File)     the program (required), read with its own variable
%%                      names and where each goal stands
%%     title(Atom)      the chart's title (default: the moded head)
%%     libraries(How)   none (default): a library predicate is a box, and the
%%                      chart never goes inside it; reach: one is opened
%%                      into a panel of its clauses on a path that reaches
%%                      C; all: every one the program reaches is opened
%%     depth(D)         the PICTURE draws panels at most D calls deep
%%     only(Preds)      the PICTURE draws these predicates' panels, a list of
%%                      Name/Arity and Name//Arity
%%     load(Files)      the program's other files, or its top file, a file
%%                      or a list (library(Name) too): loaded first, so a
%%                      call into one is a box the chart knows is defined --
%%                      for a program of several files, drawn a file at a
%%                      time (1.10.28). Like the source, each is LOADED, as
%%                      use_module/1 loads it: its directives run
%%     modules(Files)   the Cicili sources of the program's own modules,
%%                      a file or a list (1.11.4): each ("name" Arity
%%                      c_function) row of their tables is a C predicate,
%%                      a portal, with the modes its comment or the
%%                      header's signature list gives (read.pl). The rows
%%                      are flow_t_portal/8's -- the extension point: a
%%                      file of such rows given to load(Files) does the same
%%                      by hand
%%     progress(S)      a line on stderr every S seconds, once the chart
%%                      has run S seconds (0, the default: none)
%%
%% WHAT THE PROGRAM DECLARES AS IT RUNS counts as declared (1.11.4):
%% dynamic/1 with its spec written out, an assert of a clause whose head
%% is, and a call of a declarer of the program's own -- `reset(F/A) :-
%% abolish(F/A), dynamic(F/A)' called as `reset(t/2)' -- anywhere in the
%% source, the files load(Files) names and the files they load: a call of
%% such a table is a dynamic predicate's, not an unknown procedure. A file
%% read here that defines a predicate of this library's own -- a helper
%% named flow_trim/2 -- is refused by name before anything is analysed:
%% its clauses would join the library's (read.pl).
%%
%% EVERY GOAL IS DRAWN, by name, builtins and library calls too: each is a
%% box on its clause's line, which the chart does not go inside -- a
%% builtin is C in the engine, and a library predicate is the library's
%% own business unless libraries(reach|all) asks for its clauses. A panel
%% that a drawn one calls but that is not drawn itself is a STUB -- its
%% head, why, and how many panels hang from it. With neither depth nor
%% only, a chart of more than 150 panels is drawn to the depth that fits
%% and says so. THE XML IS NEVER PRUNED.
%%
%% THE TWO FILES COME FROM ONE GRAPH, so they cannot disagree, and they
%% share their ids: panel p3, its clause p3.c2, that clause's goal p3.c2.g4
%% (library/flow/xml.pl's header has the rest). In the XML every goal has
%% its file, line and column, its modes, can_fail and choice, the panel it
%% calls, and on_fail: the goal tried again, next_clause, or fail -- the
%% questions an agent asks of a program that does not do what it should.
%% Both are written a piece at a time (library/flow/write.pl), the bytes
%% library(xml) would write.
%%
%% THE ANALYSIS. A pair is a predicate and a call pattern; each pair the
%% query reaches is analysed against what its callees are known to do,
%% again whenever one of those answers changes, until none does -- a
%% worklist (library/flow/analyse.pl). A predicate met with two call
%% patterns has a panel for each. A grammar rule is the predicate it stands
%% for, translated by the engine's own translator, its leading terminal in
%% the head as the store keeps it. A goal past a call that never succeeds
%% is drawn and marked unreached. The translator, 1066 predicates and 3255
%% clauses, charts in about 50 s.
%%
%% THE PARTS, each a file under library/flow/: read (the program, its
%% positions, its comments' signatures, the generated tables), modes (the
%% hand-kept table, a line per way of calling a builtin), analyse, findings,
%% lanes (where the code runs), text (terms written with their names),
%% layout, svg, xml, write. The tables
%% (library/flow/tables.pl) are written by `make modules'
%% (tools/flow/build.sh) and git ignores them.
%%
%% WHAT IS DRAWN. Each predicate the query reaches is a PANEL in Byrd's box
%% model: the call enters at the top left, the exit leaves at the top right,
%% a failure leaves at the bottom left. Inside, each clause is a ROW: its
%% head unifies, then its goals run left to right on one main line. Under
%% each row a red dashed LANE says where every failure goes -- back up into
%% the latest goal that can still redo, else down the left rail to the next
%% clause, else, past a cut, out of the whole call. A call carries the
%% number of the panel it calls; between panels a dark wire takes the call
%% there and a green one brings the answer back. A C function is a PORTAL:
%% the end of the chart, never looked inside. A DYNAMIC predicate -- one
%% declared dynamic -- is drawn with the clauses the file starts it with,
%% and may fail or answer again whatever they say. call(double, X, Y) is
%% double(X, Y); a goal known only when it runs is a CLOSURE, which may
%% fail and leave a choice; a call nothing defines is UNKNOWN, an
%% existence error when it runs.
%%
%% MODES are shown the Prolog way, on every argument: + input, - output,
%% ? either, : a goal. A builtin's come from the hand-kept table
%% (library/flow/modes.pl), a C function's from its module's table row, and
%% user code's are INFERRED from the call pattern: which variables are
%% bound when each goal runs.
%%
%% THE LAYOUT IS THE STRUCTURE. Prolog's control is sequence and choice,
%% nested, so each panel is laid out from its clauses directly -- one main
%% line per clause, choice as rows, failure as lanes -- and no general graph
%% layout is ever asked to guess. Failure lanes cannot cross: a failure goes
%% to the NEAREST goal to its left that can redo, so two failures whose
%% spans overlap go to the same place and share one line. Between panels
%% every wire runs left to right through a gutter whose tracks are ordered
%% to cross as little as the wires allow, and a panel is placed level with
%% the call that first reaches it, so most wires are straight.
%%
%% FINDINGS: what is wrong, and where (library/flow/findings.pl) -- a call
%% nothing answers, with the name it was probably meant to be; a call the
%% engine refuses with an argument free on every path to it; a predicate
%% whose first call reaches itself again with the inputs it was given, for
%% a grammar before reading anything; a clause never tried; a `%! p(...)
%% is det' the code does not keep; a predicate whose clauses are not
%% together in the file (1.10.27). Each is about one id, a red disc on its
%% box in the picture, an element at the head of the XML, a line from
%% tools/flow/chart.pl as a compiler writes one:
%%
%%     finding(N, Kind, Severity, At, In, where(File, Line, Col), Text, See)
%%
%% WHERE THE CODE RUNS (library/flow/lanes.pl). A spawn -- thread_create/2,
%% thread_pool/3, run_isolated/2, a cowork job or cowork_map/3's list of
%% them (a row each), an httpd pool of workers -- sends its goal, a copy, to
%% a LANE of its own: a band of the picture with its own panels, a <lane>
%% of the XML. An httpd server with no pool serves on the caller's thread:
%% a construct whose page is called here. The copy is analysed as one: what
%% is bound where the spawn stands goes, and nothing the lane binds comes
%% back but what the spawn hands back (a status, cowork_ask/2's answer).
%% What crosses between lanes is a LINK: a spawn and its join, a channel
%% from channel_new/1 to each send and receive (a dotted line across the
%% lanes), a lock, a child process -- a portal like C, its command written
%% on it -- and a write to the knowledge base. A channel and a thread's
%% handle are FOLLOWED wherever the program takes them: into a call, back
%% out of one, inside a term, down another channel. Where one lane sends on
%% a channel and one receives, each in an order the chart can read, the
%% k-th send is tied to the k-th receive alone. A thread never joined, a
%% lock with a way out that keeps it, and a lane reading what only another
%% lane writes are findings.
%%
%% WHAT A RUN DID is library(flow/debug)'s: a query run, recorded and drawn
%% over this chart, the same ids in its XML (lesson 51, DESIGN-flow.md 9).

:- use_module(library(xml)).
:- use_module(library(stream)).
:- use_module(library(flow/read)).
:- use_module(library(flow/modes)).
:- use_module(library(flow/analyse)).
:- use_module(library(flow/findings)).
:- use_module(library(flow/lanes)).
:- use_module(library(flow/text)).
:- use_module(library(flow/layout)).
:- use_module(library(flow/svg)).
:- use_module(library(flow/xml)).
:- use_module(library(flow/write)).

%% ======================================================================
%% Entry
%% ======================================================================

flow_chart(Spec, Base) :-
    flow_chart(Spec, Base, []).

%% Base.svg for a person and Base.xml for an agent, from one graph, so the
%% two cannot disagree. A Base given as x.svg or x.xml means x.
flow_chart(Spec, Base, Opts) :-
    flow_chart(Spec, Base, Opts, _).

%% and the findings, found once for both files
flow_chart(Spec, Base0, Opts, Fs) :-
    flow_base(Base0, Base),
    flow_check_draw_opts(Opts),
    flow_graph(Spec, Graph, Opts),
    flow_progress_phase('the findings'),
    flow_findings(Graph, Fs),
    flow_progress_phase('the picture'),
    flow_svg(Graph, Fs, Svg, Opts),
    flow_progress_phase('the XML'),
    flow_xml(Graph, Fs, Xml),
    atom_concat(Base, '.svg', SvgFile),
    atom_concat(Base, '.xml', XmlFile),
    flow_progress_phase('writing the files'),
    flow_write_doc(SvgFile, Svg, []),
    flow_write_doc(XmlFile, Xml, [indent(2)]),
    flow_progress_phase(done).

%% PROGRESS ON STDERR, for a chart that takes a while: progress(Seconds)
%% says how often (0, the default, says nothing). Nothing is written until
%% the chart has run that long, so a quick one stays quiet; then a line
%% each Seconds while the analysis runs -- the pairs met, the analyses
%% made, the queue -- and one as each later part starts. A chart that ran
%% longer than a time cap could not say whether it was getting anywhere
%% (cicili-lang's ccl_cpp.pl, killed at 30 minutes).
flow_progress_start(Opts) :-
    flow_option(progress(Int), Opts, 0),
    (   number(Int), Int > 0
    ->  get_time(T0),
        Next is T0 + Int,
        nb_setval('$flow_progress', p(Int, T0, Next, 0, quiet))
    ;   nb_setval('$flow_progress', off)
    ).

%% at each pair analysed: T the pairs met, Q the queue
flow_progress_tick(T, Q) :-
    catch(nb_getval('$flow_progress', p(Int, T0, Next, N0, Said)), _, fail), !,
    N is N0 + 1,
    get_time(Now),
    (   Now >= Next
    ->  assoc_to_keys(T, Ks), length(Ks, NP),
        Q = q(F, B), length(F, NF), length(B, NB), NQ is NF + NB,
        E is Now - T0,
        format(user_error, "chart: analysing -- ~d pairs met, ~d analyses made, ~d queued, ~0f s~n",
               [NP, N, NQ, E]),
        Next1 is Now + Int,
        nb_setval('$flow_progress', p(Int, T0, Next1, N, said))
    ;   nb_setval('$flow_progress', p(Int, T0, Next, N, Said))
    ).
flow_progress_tick(_, _).

%% a part begins: said once the chart has run Int seconds, and the next
%% line of the analysis is Int seconds after it
flow_progress_phase(What) :-
    catch(nb_getval('$flow_progress', p(Int, T0, _, N, Said)), _, fail), !,
    get_time(Now),
    E is Now - T0,
    Next is Now + Int,
    (   ( Said == said ; E >= Int )
    ->  (   What == done
        ->  format(user_error, "chart: done, ~0f s~n", [E])
        ;   format(user_error, "chart: ~w, at ~0f s~n", [What, E])
        ),
        nb_setval('$flow_progress', p(Int, T0, Next, N, said))
    ;   nb_setval('$flow_progress', p(Int, T0, Next, N, Said))
    ).
flow_progress_phase(_).

flow_base(B0, B) :-
    (   atom_concat(B1, '.svg', B0) -> B = B1
    ;   atom_concat(B1, '.xml', B0) -> B = B1
    ;   B = B0
    ).


flow_graph(Spec, graph(Title, Src, Panels, Ids, Docs), Opts) :-
    flow_spec(Spec, Name, Arity, CM),
    flow_option(source(Src), Opts, none),
    (   Src == none
    ->  throw(error(existence_error(flow_option, source), flow_graph/3))
    ;   true
    ),
    flow_option(libraries(How), Opts, none),
    (   memberchk(How, [none, reach, all]) -> true
    ;   throw(error(domain_error(flow_libraries, How), flow_graph/3))
    ),
    flow_tables,
    flow_progress_start(Opts),
    flow_option(load(Load0), Opts, []),
    (   is_list(Load0) -> Loads = Load0 ; Loads = [Load0] ),
    flow_option(modules(Mod0), Opts, []),
    (   is_list(Mod0) -> Mods = Mod0 ; Mods = [Mod0] ),
    findall(Sp, ( member(MF, Mods), flow_module_portals(MF, Sps), member(Sp, Sps) ), ModLoads),
    forall(member(LF, Loads), flow_load(LF)),
    use_module(Src),
    flow_scan(Src, Loads, ModLoads, Scan),
    flow_clash_check(Scan),
    flow_near_gen,
    flow_read_source(Src, Prog0),
    Scan = scan(Declared, _),
    flow_mark_declared(Declared, How, Prog0, Prog),
    functor(Root, Name, Arity),
    (   get_assoc(Name/Arity, Prog, _) -> true
    ;   flow_kind(Root, ctx(Prog, none, How), RK), RK \== unknown -> true
    ;   throw(error(existence_error(procedure, Name/Arity), flow_graph/3))
    ),
    flow_doc_sigs(Src, Docs0),
    empty_assoc(Memo0),
    Ctx = ctx(Prog, Memo0, How),
    flow_progress_phase('the analysis'),
    flow_build(Ctx, Name/Arity, CM, Panels, Ids),
    flow_library_docs(Panels, Docs0, Docs),
    flow_option(title(Title0), Opts, none),
    (   Title0 == none -> flow_default_title(Panels, Docs, Title) ; Title = Title0 ).

flow_option(Opt, Opts, Default) :-
    (   memberchk(Opt, Opts) -> true ; arg(1, Opt, Default) ).

%% load(Files): the program's other files -- or its top file, which loads
%% them -- loaded before the source, so that what they define is defined
%% here too: a call into one is a box, library(loaded), and never an
%% unknown procedure. Only the source is drawn. Through 1.10.27 a file
%% read alone took every call into a sibling it does not load itself for
%% unknown (cicili-lang's ccl_check.pl: 237 such findings, none real).
flow_load(F) :-
    (   catch(use_module(F), _, fail)
    ->  true
    ;   throw(error(existence_error(flow_load, F), flow_graph/3))
    ).

%% depth(D): D calls deep at most, D a positive integer or `all';
%% only(Preds): a list of Name/Arity and Name//Arity
flow_check_draw_opts(Opts) :-
    (   memberchk(depth(D), Opts),
        \+ ( D == all ; integer(D), D >= 1 )
    ->  throw(error(domain_error(flow_depth, D), flow_chart/3))
    ;   true
    ),
    (   memberchk(only(Ps), Opts),
        \+ ( is_list(Ps), forall(member(P, Ps), flow_pred_spec(P)) )
    ->  throw(error(domain_error(flow_only, Ps), flow_chart/3))
    ;   true
    ).

flow_pred_spec(N/A) :- atom(N), integer(A), A >= 0.
flow_pred_spec(N//A) :- atom(N), integer(A), A >= 0.

%% a nonterminal is called to parse: its list in, what is left out
flow_spec(Name//Arity, Name, A2, CM) :- !,
    A2 is Arity + 2,
    length(CM0, Arity),
    flow_fill(CM0, '?'),
    append(CM0, ['+', '-'], CM).
flow_spec(Name/Arity, Name, Arity, CM) :- !,
    length(CM, Arity),
    flow_fill(CM, '?').
flow_spec(Spec, Name, Arity, CM) :-
    compound(Spec), !,
    Spec =.. [Name|CM],
    length(CM, Arity),
    forall(member(M, CM), memberchk(M, ['+', '-', '?'])).
flow_spec(Name, Name, 0, []) :-
    atom(Name).


