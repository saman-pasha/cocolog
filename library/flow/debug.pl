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
%% Exit, and every <event> in order. So an agent can ask which goal failed
%% last, and with what.
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

flow_debug(Goal, Base) :-
    flow_debug(Goal, Base, []).

flow_debug(Goal, Base, Opts) :-
    flow_debug(Goal, Base, Opts, _).

flow_debug(Goal, Base0, Opts, Out) :-
    flow_base(Base0, Base),
    flow_dbg_check(Goal, Opts, File),
    flow_dbg_spec(Goal, Spec),
    flow_graph(Spec, Graph, [source(File)]),
    flow_findings(Graph, Fs),
    flow_dbg_run(Goal, File, Opts, Run),
    Run = run(_, _, _, _, Events, _),
    flow_dbg_match(Graph, Events, Calls),
    flow_dbg_names(Goal, Opts, Names),
    flow_dbg_facts(Graph, Run, Calls, Names, Opts, Facts),
    flow_dbg_svg(Graph, Fs, Facts, Opts, Svg),
    flow_dbg_xml(Graph, Fs, Facts, Xml),
    atom_concat(Base, '.svg', SvgFile),
    atom_concat(Base, '.xml', XmlFile),
    flow_write_doc(SvgFile, Svg, []),
    flow_write_doc(XmlFile, Xml, [indent(2)]),
    flow_dbg_out(Facts, Out).

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

flow_dbg_run(Goal, File, Opts, run(Goal, Probe, Replay, window(From, To), Events, Journal)) :-
    (   memberchk(until(answer(K)), Opts) -> true ; K = 1 ),
    flow_option(timeout(Ms), Opts, 600000),
    flow_option(text(TM), Opts, 60),
    flow_dbg_journal_file(Opts, JFile, Keep),
    (   JFile == none -> JR = [], JP = []
    ;   JR = [journal(record(JFile))], JP = [journal(replay(JFile))]
    ),
    (   memberchk(to(Cap), Opts) -> POpts0 = [answers(K), to(Cap)] ; POpts0 = [answers(K)] ),
    append(POpts0, JR, POpts),
    (   catch(flow_dbg_runs(File, Goal, POpts, JP, K, TM, Ms, Opts, Probe, Replay, From, To, Events),
              E, ( flow_dbg_journal_drop(JFile, Keep), throw(E) ))
    ->  true
    ;   flow_dbg_journal_drop(JFile, Keep), fail
    ),
    flow_dbg_journal_read(JFile, Keep, Journal).

%% the probe, and the replay of the window it decides
flow_dbg_runs(File, Goal, POpts, JP, K, TM, Ms, Opts, Probe, Replay, From, To, Events) :-
    flow_dbg_child(File, Goal, POpts, Ms, Probe0, _),
    flow_dbg_norm_end(Probe0, Probe),
    Probe = end(_, Used, _),
    flow_dbg_window(Opts, Used, From, To),
    (   From =< To, Used >= 1
    ->  append([from(From), to(To), answers(K), text(TM)], JP, ROpts),
        flow_dbg_child(File, Goal, ROpts, Ms, Replay0, Events),
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
%% of its own, which is what makes a replay the run the probe was.
flow_dbg_child(File, Goal, WOpts, Ms, End, Events) :-
    tmp_file(flowdebug, Out),
    Driver = ( use_module(library(stream)),
               '$trace_window'(Goal, WOpts, Es, E),
               open(Out, write, S),
               format(S, '~q.~n', [E]),
               forall(member(X, Es), format(S, '~q.~n', [X])),
               close(S) ),
    format(atom(GoalText), '~q', [Driver]),
    current_prolog_flag(executable, Exe),
    flow_dbg_shq(Exe, QExe), flow_dbg_shq(File, QFile), flow_dbg_shq(GoalText, QGoal),
    atomic_list_concat([QExe, ' run ', QFile, ' ', QGoal, ' 2>&1'], Cmd),
    proc_run(Cmd, Ms, OutCodes, Exit),
    (   Exit =:= 0, exists_file(Out)
    ->  flow_dbg_read_terms(Out, [End|Events]),
        catch(delete_file(Out), _, true)
    ;   catch(delete_file(Out), _, true),
        atom_codes(Said, OutCodes),
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
