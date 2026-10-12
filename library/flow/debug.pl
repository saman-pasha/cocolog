%% library(flow/debug) -- what a query DID, drawn over the flowchart of what
%% it can do: the path it took, where it failed, the values that crossed
%% -- as an SVG for a person and an XML for an agent.
%%
%%     :- use_module(library(flow/debug)).
%%
%%     flow_debug(+Goal, +Base, +Options)          Base.svg and Base.xml
%%     flow_debug(+Goal, +Base, +Options, -Run)    and the run as a term
%%     flow_why(+Run, -Whys)                       why it failed (dbgwhy.pl)
%%     flow_when(+Goal, +Cond, +Options, -When)    the first inference at
%%                                                 which Cond holds (dbgwhen.pl)
%%
%% The run flow_debug/4 hands back:
%%
%%     run(How, At, Answers, window(From, To), Calls, Bindings, Diverged, Journal)
%%
%% How the run ended -- answer, false, limit, exception(Ball), halt(Code),
%% error(Message), or diverged(I, Want, Got) where a replay left its
%% journal -- at inference At, Answers the inference of each answer; Calls
%% a call(S, Name/Arity, Depth, Parent, Box, Panel, Clauses, In, Out, Fate)
%% for each call the window saw (library/flow/dbgmatch.pl); Bindings an
%% x(I, Port, S, Name, Value, Box) for each value that crossed into a
%% variable the source names (library/flow/dbgdraw.pl); Diverged false, or
%% diverged(ProbeEnd, ReplayEnd); Journal none, or journal(Entries), each
%% entry j(I, Module, Name/Arity, CallText, Outcome) as the probe wrote it.
%%
%%     cocolog -s tools/flow/debug.pl -- GOAL FILE BASE [OPTION ...]
%%
%% Goal is a call of a predicate the program defines; its arguments, bound
%% or not, are its call pattern, and the chart is library(flow/chart)'s for
%% that pattern. Options:
%%
%%     source(File)     the program (required)
%%     until(Where)     end (default): the run's first answer, its failure or
%%                      its exception; answer(K): its K-th answer
%%     window(N)        the inferences recorded, up to where the run stops
%%                      being explained (2000); a run that short is
%%                      recorded whole
%%     from(I), to(J)   the window by its inferences instead
%%     discs(N)         how many crossings are numbered on the picture (24),
%%                      the last before the window closes
%%     text(N)          a value is written whole up to N characters (60)
%%     view(View)       flow (default): the chart, the run drawn over it;
%%                      tree: the calls themselves, a row each
%%     names(Names)     ['X'=X, ...]: the goal's variables by name
%%     timeout(Ms)      for each run of the program (600000)
%%     journal(Bool)    false (default), or true: the probe journals every
%%                      portal call it makes and the replay is answered
%%                      from the journal (below)
%%     journal_file(F)  the journal kept in F (and journal(true)); without
%%                      it the journal is a temporary file, deleted after
%%     txt(Bool)        false (default), or true: Base.txt as well, the run
%%                      one line a call -- its inference, the goal at its
%%                      Call, how it ended, the clauses it entered, its box
%%                      and where that box is written (dbgtext.pl): the
%%                      cheapest view of a run for an agent
%%     cache(Dir)       the chart kept in Dir and built once for a call
%%                      pattern of a file: Base.xml is then the <run> alone,
%%                      naming the chart's XML (below; needs library(sha))
%%     embed(Dir)       the program runs over the store in Dir, as
%%                      `cocolog --embed Dir' runs it; kb(Name) the
%%                      knowledge base of it (below)
%%
%% NOTHING HERE SLOWS THE RUN IT EXPLAINS (DESIGN-flow.md 9). The program
%% runs twice, each time in a child process of its own that reads it
%% afresh -- so what the first run asserted, or set as a global, cannot
%% change the second: a PROBE, untraced at full speed, learns how the run
%% ends and at which inference; a REPLAY goes untraced at full speed to
%% the window's first inference and records from there ('$trace_window'/4,
%% the engine's). The clock is the untraced run's in both, so the replay
%% must end where the probe did. One that does not is DIVERGED -- a
%% program that reads the time, a file or the knowledge base under --kb
%% can -- and is drawn all the same, a true recording of a run of the
%% program, under a red line that says both ends.
%%
%% DEBUG THE GOAL THE PROGRAM IS ENTERED BY, and narrow the window. Each
%% child starts afresh: it reads the program and calls Goal, and nothing ran
%% before it -- no earlier call set the globals, asserted the facts or
%% opened the streams a goal from the middle of a program may stand on. So
%% such a goal can fail in the child where it succeeds in the program: the
%% translator's tr_write_ir(english, IR, 46, Out) alone fails at inference
%% 330, the language it writes having been set by the reading that comes
%% first in any real run. Give the entry goal (reason_translate/4 there),
%% and choose the part of its run to record with from(I) and to(J) -- the
%% inferences are the untraced run's, the same in every run -- or let
%% flow_when/4 find the inference at which something first holds.
%%
%% THE JOURNAL (journal(true), DESIGN-flow.md 9.2) takes what the program
%% reads out of that: the probe writes an entry for each PORTAL call it
%% makes -- the clock, the environment, a file, a stream, a process, a
%% thread, the knowledge base under --kb: a call of a module that reaches
%% the world -- with the inference it was made at, its text and how it
%% went; the replay answers each from its entry and runs none of them, so
%% a file is not appended to twice, a thread not started again, and the
%% clock reads what it read. A replay that reaches a portal call at
%% another inference, or another call where the journal holds one, or
%% that passes one by, stops there: How is diverged(I, Want, Got), the
%% journal's call (Want) and the replay's (Got) each portal(I, Module,
%% Name/Arity, CallText) or none. The boxes whose calls the journal
%% answered carry a mark, and the XML lists every entry.
%%
%% WHAT IS DRAWN. The chart (library(flow/chart)), with every box the run
%% reached drawn heavy, every one whose last call failed red, one that
%% raised an exception purple, and the boxes and panels it never reached
%% faded; a head that did not match is red too.
%% Numbered discs mark where a value crossed -- an argument a call was
%% given, a binding its exit made, a binding backtracking undid (hollow) --
%% and a legend under the chart lists each: the variable by its source
%% name, the value, the port, the clause and the inference. view(tree)
%% draws the calls instead, a row each, deeper calls indented, a
%% recursion's middle elided.
%%
%% THE XML is the chart's, the same ids, and a <run> after its panels:
%% how the run ended and where, the window, a <call> for each call with the
%% box it is and the panel it entered, its arguments at its Call and at its
%% Exit, and every <event> in order -- a redo saying whether its call had
%% exited (exited="true": asked for another answer, the one Redo that
%% makes a call nondeterministic) or had not (a failed clause's retry,
%% which SWI's tracer prints as Redo too). So an agent can ask which goal
%% failed last, and with what.
%%
%% THE CHART, KEPT (cache(Dir)). Building the chart of a large program is
%% most of a run's cost -- the translator's, 52 of a run's 57 seconds --
%% and the chart is most of the XML (26 MB of it). With cache(Dir) it is
%% built once for a call pattern of a file and kept in Dir as KEY.chart
%% (the graph) and KEY.xml (its XML), and a run that reads them takes 4.6
%% seconds. KEY is the sha256 of the pattern, the file's name and `cocolog
%% --version' (a new cocolog draws its own; library(flow/chart) edited
%% without a new version is not seen -- empty Dir). KEY.chart names each
%% file the chart holds a clause of with its sha256, and a file that
%% changed builds it again. Base.xml is then the run alone -- <flow
%% chart="Dir/KEY.xml" ...> with the chart's attributes, and the <run>
%% -- and its ids are the ones KEY.xml has.
%%
%% OVER A STORE (embed(Dir), kb(Name)). Without them each child runs `cocolog
%% run File Goal': the file consulted into a knowledge base of the child's
%% own. With them it runs `cocolog --embed Dir [--kb Name] query', loading
%% the file as -s does (use_module: its clauses never written through) and
%% calling the goal over what the store holds. What the run WRITES is
%% written: the probe's writes are in the store when the replay runs, and
%% stay -- debug a program that writes against a copy of its store.
%%
%% QUESTIONS OVER THE CLOCK (D4). A run that failed has WHY drawn under its
%% bindings and in the XML's <why>: each failed call of the program's own,
%% each clause it tried -- its head did not unify, or its body entered and
%% the calls it made -- down to the calls that failed with nothing of the
%% program's to say why; flow_why/2 hands the same tree back as a term.
%% flow_when/4 answers WHEN: the first inference at which a question holds,
%% asked of runs stopped part way -- a handful of them, each at full speed
%% and each a replay of the probe's journal (dbgwhen.pl says how, and what
%% "first" can mean for a question backtracking undoes).
%%
%% A WINDOW SEES THE CALLS MADE IN IT: one that began before the window
%% opened is placed in a panel of its predicate, not in its caller's
%% clause, and has no box.

:- use_module(library(process)).
:- use_module(library(stream)).
:- use_module(library(flow/chart)).
:- use_module(library(flow/dbgmatch)).
:- use_module(library(flow/dbgdraw)).
:- use_module(library(flow/dbgwhen)).
:- use_module(library(flow/dbgwhy)).
:- use_module(library(flow/dbgtext)).

flow_debug(Goal, Base) :-
    flow_debug(Goal, Base, []).

flow_debug(Goal, Base, Opts) :-
    flow_debug(Goal, Base, Opts, _).

flow_debug(Goal, Base0, Opts, Out) :-
    flow_base(Base0, Base),
    flow_dbg_check(Goal, Opts, File),
    flow_dbg_spec(Goal, Spec),
    flow_dbg_chart(Spec, File, Opts, Graph, Fs, Chart),
    flow_dbg_src(File, Opts, Src),
    flow_dbg_run(Goal, Src, Opts, Run),
    Run = run(_, _, _, _, Events, _),
    flow_dbg_match(Graph, Events, Calls),
    flow_dbg_names(Goal, Opts, Names),
    flow_dbg_facts(Graph, Run, Calls, Names, Opts, Facts),
    flow_dbg_svg(Graph, Fs, Facts, Opts, Svg),
    (   Chart = cached(CXF, CAs, Places)
    ->  flow_dbg_x_run(Facts, RunE),
        Xml = element(flow, [chart=CXF|CAs], [RunE])
    ;   flow_dbg_xml(Graph, Fs, Facts, Xml),
        Places = none
    ),
    atom_concat(Base, '.svg', SvgFile),
    atom_concat(Base, '.xml', XmlFile),
    flow_write_doc(SvgFile, Svg, []),
    flow_write_doc(XmlFile, Xml, [indent(2)]),
    (   memberchk(txt(true), Opts)
    ->  (   Places == none -> flow_dbg_text_places_of(Xml, Places1) ; Places1 = Places ),
        flow_dbg_text(Places1, Facts, Text),
        atom_concat(Base, '.txt', TxtFile),
        open(TxtFile, write, TS),
        write(TS, Text),
        close(TS)
    ;   true
    ),
    flow_dbg_out(Facts, Out).

%% ======================================================================
%% The chart, built or kept
%% ======================================================================
%%
%% WITHOUT cache(Dir) the chart is built for every run, and written into
%% the run's XML; WITH it, it is kept (the header says how). KEY.chart is
%% the graph ONE TERM A PART -- a panel, an id, a finding, where a box is
%% written: the translator's whole graph as one term took longer to read
%% than to build, which the reader's cost per term (superlinear in its
%% size) makes so.
flow_dbg_chart(Spec, File, Opts, Graph, Fs, Chart) :-
    (   memberchk(cache(Dir), Opts)
    ->  flow_dbg_cache(Dir, Spec, File, Graph, Fs, Chart)
    ;   flow_graph(Spec, Graph, [source(File)]),
        flow_findings(Graph, Fs),
        Chart = none
    ).

flow_dbg_cache(Dir, Spec, File, Graph, Fs, cached(XF, As, Places)) :-
    flow_dbg_cache_paths(Dir, Spec, File, CF, XF),
    (   exists_file(CF), exists_file(XF),
        catch(flow_dbg_cache_read(CF, Spec, Graph, Fs, As, Places), _, fail)
    ->  true
    ;   sha_file(sha256, File, H0),
        flow_graph(Spec, Graph, [source(File)]),
        flow_findings(Graph, Fs),
        flow_xml(Graph, Fs, CX),
        CX = element(flow, As, _),
        flow_dbg_cache_tmp(Dir, XT),
        flow_write_doc(XT, CX, [indent(2)]),
        rename_file(XT, XF),
        flow_dbg_text_places_of(CX, Places),
        flow_dbg_cache_files(CX, FHs),
        %% a file changed while it was charted is not kept: the chart may
        %% be of either text, and the hash is of the new one
        (   memberchk(File-H1, FHs), H1 \== H0
        ->  true
        ;   flow_dbg_cache_tmp(Dir, CT),
            flow_dbg_cache_write(CT, Spec, FHs, Graph, Fs, As, Places),
            rename_file(CT, CF)
        )
    ).

%% EACH FILE IS WRITTEN BESIDE ITS NAME AND RENAMED IN, so a reader -- a
%% run beside this one -- sees all of it or none; KEY.chart ends with the
%% count of each part, so one cut short where a term ends is no entry
flow_dbg_cache_tmp(Dir, Tmp) :-
    tmp_file(flowcache, T0),
    file_base_name(T0, B),
    atomic_list_concat([Dir, '/', B, '.part'], Tmp).

%% KEY.chart and KEY.xml in Dir for a call pattern of a file, drawn by
%% this cocolog: `cocolog --version' is in the key, and a version is a
%% change to the binary or a library (CLAUDE.md), so a chart drawn by
%% another cocolog's library(flow/chart) is never read
flow_dbg_cache_paths(Dir, Spec, File, CF, XF) :-
    flow_dbg_sha_loaded,
    current_prolog_flag(executable, Exe),
    flow_dbg_shq(Exe, QExe),
    atom_concat(QExe, ' --version', VCmd),
    proc_run(VCmd, 60000, VCodes, _),
    atom_codes(Ver, VCodes),
    format(atom(KT), 'flow chart cache 1|~w|~q|~w', [Ver, Spec, File]),
    sha_hash(sha256, KT, Key),
    atomic_list_concat([Dir, '/', Key, '.chart'], CF),
    atomic_list_concat([Dir, '/', Key, '.xml'], XF).

%% the chart's XML a cached run names, for Goal and the options it was
%% given: none without cache(Dir)
flow_dbg_chart_xml(Goal, Opts, XF) :-
    (   memberchk(cache(Dir), Opts), memberchk(source(File), Opts)
    ->  flow_dbg_spec(Goal, Spec),
        flow_dbg_cache_paths(Dir, Spec, File, _, XF)
    ;   XF = none
    ).

%% library(sha), loaded when a cache is asked for: a cocolog built without
%% ZiguratIP has none, and refuses cache(Dir) by name
flow_dbg_sha_loaded :-
    (   catch(use_module(library(sha)), _, fail) -> true
    ;   throw(error(existence_error(library, sha), flow_debug/3))
    ).

%% every file the chart holds a clause of, with its sha256
flow_dbg_cache_files(CX, FHs) :-
    findall(F, flow_dbg_x_file(CX, F), Fs0),
    sort(Fs0, Fs),
    findall(F-H, ( member(F, Fs), sha_file(sha256, F, H) ), FHs).

flow_dbg_x_file(element(N, As, Cs), F) :-
    (   N == clause, memberchk(file=F, As)
    ;   member(C, Cs), nonvar(C), C = element(_, _, _), flow_dbg_x_file(C, F)
    ).

flow_dbg_cache_write(CF, Spec, FHs, graph(T, S, Ps, IdsA, DocsA), Fs, As, Places) :-
    assoc_to_list(IdsA, Ids),
    assoc_to_list(DocsA, Docs),
    assoc_to_list(Places, Ws),
    open(CF, write, O),
    flow_dbg_cache_put(O, flow_chart_cache(1, Spec, FHs)),
    flow_dbg_cache_put(O, h(T, S, As)),
    forall(member(P, Ps), flow_dbg_cache_put(O, p(P))),
    forall(member(I, Ids), flow_dbg_cache_put(O, i(I))),
    forall(member(D, Docs), flow_dbg_cache_put(O, d(D))),
    forall(member(F, Fs), flow_dbg_cache_put(O, f(F))),
    forall(member(W, Ws), flow_dbg_cache_put(O, w(W))),
    maplist(length, [Ps, Ids, Docs, Fs, Ws], Ns),
    flow_dbg_cache_put(O, n(Ns)),
    close(O).

%% writeq/2: quoted, so each term reads back as itself, its variables
%% shared as they were (`_G' names); with its operators, so a clause's text
%% stays a list and not a '.'/2 nest a thousand deep
flow_dbg_cache_put(O, T) :-
    writeq(O, T),
    write(O, '.\n').

%% an entry, when it is this call pattern's and its files are as they were
flow_dbg_cache_read(CF, Spec, graph(T, S, Ps, IdsA, DocsA), Fs, As, Places) :-
    flow_dbg_read_terms(CF, [flow_chart_cache(1, Spec0, FHs), h(T, S, As)|Ts]),
    format(atom(A0), '~q', [Spec0]), format(atom(A1), '~q', [Spec]), A0 == A1,
    forall(member(F-H, FHs), ( exists_file(F), sha_file(sha256, F, H1), H1 == H )),
    findall(P, member(p(P), Ts), Ps),
    findall(I, member(i(I), Ts), Ids), list_to_assoc(Ids, IdsA),
    findall(D, member(d(D), Ts), Docs), list_to_assoc(Docs, DocsA),
    findall(F, member(f(F), Ts), Fs),
    findall(W, member(w(W), Ts), Ws), list_to_assoc(Ws, Places),
    last(Ts, n(Ns)),
    maplist(length, [Ps, Ids, Docs, Fs, Ws], Ns).

%% ======================================================================
%% Where the program runs
%% ======================================================================
%%
%% Its file, and the store it opens: embed(Dir), and kb(Name) of it, as the
%% program would be run (`cocolog --embed Dir --kb Name ...'). The child
%% then LOADS the file as -s does -- use_module, its clauses muted and never
%% written through -- where `run' would consult them into the store. What
%% the run itself writes to the store is written: the probe's writes are
%% there for the replay, which then leaves the probe's run (diverged), and
%% they stay. Debug a run that writes against a copy of its store.
flow_dbg_src(File, Opts, Src) :-
    (   memberchk(embed(Dir), Opts)
    ->  ( memberchk(kb(K), Opts) -> true ; K = none ),
        Src = embedded(File, Dir, K)
    ;   Src = File
    ).

flow_dbg_src_file(embedded(File, _, _), File) :- !.
flow_dbg_src_file(File, File).

%% the child's command line, for GoalText, the driver
flow_dbg_cmd(Src, GoalText, Cmd) :-
    current_prolog_flag(executable, Exe),
    flow_dbg_shq(Exe, QExe),
    (   Src = embedded(File, Dir, K)
    ->  format(atom(Load), 'use_module(~q), ', [File]),
        atom_concat(Load, GoalText, G2),
        flow_dbg_shq(G2, QG), flow_dbg_shq(Dir, QD),
        (   K == none -> KA = ''
        ;   flow_dbg_shq(K, QK), atom_concat(' --kb ', QK, KA)
        ),
        atomic_list_concat([QExe, ' --embed ', QD, KA, ' query ', QG, ' 2>&1'], Cmd)
    ;   flow_dbg_shq(Src, QFile), flow_dbg_shq(GoalText, QGoal),
        atomic_list_concat([QExe, ' run ', QFile, ' ', QGoal, ' 2>&1'], Cmd)
    ).

flow_dbg_check(Goal, Opts, File) :-
    (   var(Goal) -> throw(error(instantiation_error, flow_debug/3)) ; true ),
    (   callable(Goal) -> true ; throw(error(type_error(callable, Goal), flow_debug/3)) ),
    (   memberchk(source(File), Opts) -> true
    ;   throw(error(existence_error(flow_option, source), flow_debug/3))
    ),
    (   memberchk(until(U), Opts), \+ ( U == end ; U = answer(K), integer(K), K >= 1 )
    ->  throw(error(domain_error(flow_until, U), flow_debug/3))
    ;   true
    ),
    forall(( member(O, Opts), memberchk(O, [window(_), discs(_), text(_), from(_), to(_), timeout(_)]) ),
           ( arg(1, O, V), integer(V), V >= 0 -> true
           ; throw(error(domain_error(flow_debug_option, O), flow_debug/3)) )),
    (   memberchk(view(V), Opts), \+ memberchk(V, [flow, tree])
    ->  throw(error(domain_error(flow_view, V), flow_debug/3))
    ;   true
    ),
    (   memberchk(journal(J), Opts), \+ memberchk(J, [true, false])
    ->  throw(error(domain_error(flow_debug_option, journal(J)), flow_debug/3))
    ;   true
    ),
    (   memberchk(journal_file(JF), Opts), \+ atom(JF)
    ->  throw(error(domain_error(flow_debug_option, journal_file(JF)), flow_debug/3))
    ;   true
    ),
    (   memberchk(txt(X), Opts), \+ memberchk(X, [true, false])
    ->  throw(error(domain_error(flow_debug_option, txt(X)), flow_debug/3))
    ;   true
    ),
    flow_dbg_check_where(Opts, flow_debug/3).

%% embed(Dir) a store that is there, kb(Name) a name of one in it (with
%% embed(Dir)), cache(Dir) a directory -- made when it is not there
flow_dbg_check_where(Opts, Who) :-
    (   Who == flow_when/4 -> Dom = flow_when_option ; Dom = flow_debug_option ),
    (   memberchk(embed(D), Opts), \+ ( atom(D), exists_directory(D) )
    ->  throw(error(existence_error(directory, D), Who))
    ;   true
    ),
    (   memberchk(kb(K), Opts)
    ->  (   atom(K) -> true ; throw(error(domain_error(Dom, kb(K)), Who)) ),
        (   memberchk(embed(_), Opts) -> true
        ;   throw(error(existence_error(flow_option, embed), Who))
        )
    ;   true
    ),
    (   memberchk(cache(C), Opts)
    ->  (   atom(C) -> true ; throw(error(domain_error(Dom, cache(C)), Who)) ),
        (   exists_directory(C) -> true
        ;   catch(make_directory(C), _, fail) -> true
        ;   throw(error(existence_error(directory, C), Who))
        )
    ;   true
    ).

%% the call pattern a goal is: an argument bound is +, unbound -, and one
%% partly bound ?
flow_dbg_spec(Goal, Spec) :-
    Goal =.. [N|As],
    findall(M, ( member(A, As), ( var(A) -> M = '-' ; ground(A) -> M = '+' ; M = '?' ) ), Ms),
    Spec =.. [N|Ms].

%% the goal's variables by name: given, or none
flow_dbg_names(_, Opts, Names) :-
    (   memberchk(names(Names), Opts) -> true ; Names = [] ).

%% ======================================================================
%% The two runs
%% ======================================================================
%%
%% run(Goal, Probe, Replay, window(From, To), Events, Journal): Probe and
%% Replay are '$trace_window'/4's end(How, Used, Answers) for each run;
%% Journal none, or journal(Entries) when the probe journalled (and the
%% replay was answered from it).

flow_dbg_run(Goal, Src, Opts, run(Goal, Probe, Replay, window(From, To), Events, Journal)) :-
    (   memberchk(until(answer(K)), Opts) -> true ; K = 1 ),
    flow_option(timeout(Ms), Opts, 600000),
    flow_option(text(TM), Opts, 60),
    flow_dbg_journal_file(Opts, JFile, Keep),
    (   JFile == none -> JR = [], JP = []
    ;   JR = [journal(record(JFile))], JP = [journal(replay(JFile))]
    ),
    (   memberchk(to(Cap), Opts) -> POpts0 = [answers(K), to(Cap)] ; POpts0 = [answers(K)] ),
    append(POpts0, JR, POpts),
    (   catch(flow_dbg_runs(Src, Goal, POpts, JP, K, TM, Ms, Opts, Probe, Replay, From, To, Events),
              E, ( flow_dbg_journal_drop(JFile, Keep), throw(E) ))
    ->  true
    ;   flow_dbg_journal_drop(JFile, Keep), fail
    ),
    flow_dbg_journal_read(JFile, Keep, Journal).

%% the probe, and the replay of the window it decides
flow_dbg_runs(Src, Goal, POpts, JP, K, TM, Ms, Opts, Probe, Replay, From, To, Events) :-
    flow_dbg_child(Src, Goal, POpts, Ms, Probe0, _),
    flow_dbg_norm_end(Probe0, Probe),
    Probe = end(_, Used, _),
    flow_dbg_window(Opts, Used, From, To),
    (   From =< To, Used >= 1
    ->  append([from(From), to(To), answers(K), text(TM)], JP, ROpts),
        flow_dbg_child(Src, Goal, ROpts, Ms, Replay0, Events),
        flow_dbg_norm_end(Replay0, Replay)
    ;   Replay = Probe, Events = []
    ).

%% a divergence's CallTexts as atoms: the child writes them as strings,
%% and they are read back here as codes
flow_dbg_norm_end(end(diverged(At, W, G), U, A), end(diverged(At, W1, G1), U, A)) :- !,
    flow_dbg_norm_side(W, W1),
    flow_dbg_norm_side(G, G1).
flow_dbg_norm_end(E, E).

flow_dbg_norm_side(portal(I, M, P, C), portal(I, M, P, CA)) :- !,
    flow_dbg_text_atom(C, CA).
flow_dbg_norm_side(S, S).

%% where the journal goes: journal_file(F), kept; journal(true), a
%% temporary file, deleted once read; or none
flow_dbg_journal_file(Opts, F, true) :-
    memberchk(journal_file(F), Opts), !.
flow_dbg_journal_file(Opts, F, false) :-
    memberchk(journal(true), Opts), !,
    tmp_file(flowjournal, F).
flow_dbg_journal_file(_, none, false).

%% the entries the probe wrote, each CallText an atom, and a temporary
%% journal deleted
flow_dbg_journal_read(none, _, none) :- !.
flow_dbg_journal_read(F, Keep, journal(Es)) :-
    (   exists_file(F)
    ->  flow_dbg_read_terms(F, Es0),
        findall(j(I, M, P, CA, O), ( member(j(I, M, P, C, O), Es0), flow_dbg_text_atom(C, CA) ), Es)
    ;   Es = []
    ),
    flow_dbg_journal_drop(F, Keep).

flow_dbg_journal_drop(none, _) :- !.
flow_dbg_journal_drop(_, true) :- !.
flow_dbg_journal_drop(F, false) :-
    catch(delete_file(F), _, true).

flow_dbg_text_atom(C, A) :-
    (   atom(C) -> A = C
    ;   string(C) -> atom_string(A, C)
    ;   atom_codes(A, C)
    ).

%% the window: from(I) and to(J) as given, else the last window(N)
%% inferences up to where the run stopped
flow_dbg_window(Opts, Used, From, To) :-
    flow_option(window(W), Opts, 2000),
    (   memberchk(to(J), Opts) -> To is min(J, Used) ; To = Used ),
    (   memberchk(from(I), Opts) -> From is max(1, I)
    ;   From is max(1, To - W + 1)
    ).

%% THE PROGRAM RUN IN A CHILD: `cocolog run File Goal', where the goal is
%% the window and the writing of what it found, a term a line, into a file
%% this process reads back. `run' consults the file into a knowledge base
%% of its own, which is what makes a replay the run the probe was -- or,
%% over a store (embed(Dir)), `cocolog --embed Dir query' of the file
%% loaded and the goal (flow_dbg_cmd/3).
flow_dbg_child(Src, Goal, WOpts, Ms, End, Events) :-
    tmp_file(flowdebug, Out),
    Driver = ( use_module(library(stream)),
               '$trace_window'(Goal, WOpts, Es, E),
               open(Out, write, S),
               format(S, '~q.~n', [E]),
               forall(member(X, Es), format(S, '~q.~n', [X])),
               close(S) ),
    format(atom(GoalText), '~q', [Driver]),
    flow_dbg_cmd(Src, GoalText, Cmd),
    proc_run(Cmd, Ms, OutCodes, Exit),
    (   Exit =:= 0, exists_file(Out)
    ->  flow_dbg_read_terms(Out, [End|Events]),
        catch(delete_file(Out), _, true)
    ;   catch(delete_file(Out), _, true),
        atom_codes(Said, OutCodes),
        flow_dbg_src_file(Src, File),
        throw(error(flow_debug_run(File, Exit, Said), flow_debug/3))
    ).

flow_dbg_read_terms(File, Ts) :-
    open(File, read, S),
    read_term(S, T, []),
    flow_dbg_read_rest(T, S, Ts),
    close(S).

flow_dbg_read_rest(end_of_file, _, []) :- !.
flow_dbg_read_rest(T, S, [T|Ts]) :-
    read_term(S, T1, []),
    flow_dbg_read_rest(T1, S, Ts).

%% an argument for /bin/sh, in single quotes, each quote in it '\''
flow_dbg_shq(A, Q) :-
    atomic_list_concat(Parts, '''', A),
    atomic_list_concat(Parts, '''\\''''', Inner),
    atomic_list_concat(['''', Inner, ''''], Q).
