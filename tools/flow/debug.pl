%% tools/flow/debug.pl -- what a query did, from the command line: its run
%% drawn over its flowchart, as SVG and XML.
%%
%%     cocolog -s tools/flow/debug.pl -- GOAL FILE BASE [OPTION ...]
%%
%%     GOAL     the query, 'go(30, R)': its variables keep the names it
%%              writes, on the picture and in the XML
%%     FILE     the program
%%     BASE     what to write: BASE.svg for a person, BASE.xml for an agent
%%     OPTION   until=end|answer(K)   where the run stops being explained
%%              window=N              the last N steps up to there (2000)
%%              from=I  to=J          the window by its steps instead
%%              discs=N               bindings numbered on the picture (24)
%%              text=N                a value written whole up to N characters
%%              view=flow|tree        the chart with the run over it, or the calls
%%              depth=N|all           the picture's panels at most N calls deep
%%              only=NAME/ARITY,...   the picture's panels for these predicates alone
%%                                    (both as chart.pl's: the XML has every panel)
%%              timeout=MS            for each run of the program
%%              journal=true|false    the probe journals its portal calls and
%%                                    the replay is answered from them (false)
%%              journal_file=F        and the journal is kept in F
%%              txt=true|false        BASE.txt as well: the run, one line a call
%%                                    (false)
%%              svg=true|false        BASE.svg and BASE.xml (true): false leaves
%%              xml=true|false        one out, and both false leave out the
%%                                    values that crossed, which only they show
%%                                    -- the cheap way to a profile or BASE.txt
%%              profile=VIEWS         BASE.prof as well (false): true is each
%%                                    predicate's calls and the steps spent
%%                                    inside them (flow_profile_text/2); or any
%%                                    of inclusive (that), steps (the window's
%%                                    steps by what took them: each
%%                                    predicate's calls and the control
%%                                    constructs' steps), callers (each
%%                                    predicate's callers and how many calls
%%                                    each made), repeats (the goals asked
%%                                    more than once) and time (each
%%                                    predicate's inclusive and self time,
%%                                    the probe run untraced under a clock
%%                                    read at every step: 1.13.3), a
%%                                    comma between, or all
%%              windows=N             N windows of window=N steps along the
%%              jobs=J                run, over from= to= when given, written as
%%                                    BASE.1.*, BASE.2.*, ... -- each by a
%%                                    process of its own, J at a time (the
%%                                    machine's processors) -- with BASE.prof of
%%                                    them all (flow_debug_windows/4); the chart
%%                                    is built once, into cache=DIR or
%%                                    BASE.charts
%%              cache=DIR             the chart kept in DIR, built once for a
%%                                    goal's call pattern of a file: BASE.xml
%%                                    is then the run alone, naming the
%%                                    chart's XML in DIR
%%              embed=DIR  kb=NAME    the program runs over the store in DIR
%%                                    (as cocolog --embed DIR --kb NAME), the
%%                                    file loaded as -s loads it
%%              own=all|FILE,...      whose failed calls the why explains:
%%                                    all, every predicate with clauses, or
%%                                    those the files hold clauses of too
%%                                    (the chart's panels alone by default)
%%              when=COND             not how the run went but WHEN: the first
%%                                    step at which COND holds -- a goal
%%                                    over GOAL's variables, asked of the run
%%                                    stopped there -- and the window that
%%                                    ends there drawn (flow_when/4, which
%%                                    journals by default); step=N asks every
%%                                    N-th step first
%%              diff=FILE_B           not one run but two: GOAL over FILE and
%%              diff_goal=GOAL_B      over FILE_B, or GOAL_B over FILE (or
%%                                    both), each recorded whole unless a
%%                                    window is given, written as BASE.a.*
%%                                    and BASE.b.*, and BASE.diff: the inputs
%%                                    both called that answered differently,
%%                                    deepest first, and the predicates only
%%                                    one called (flow_diff/3)
%%
%% GOAL IS BEST THE PROGRAM'S ENTRY GOAL. The program runs in a child that
%% starts afresh, so a goal from the middle of a program may fail there for
%% want of what an earlier call set (a global, an asserted fact): debug the
%% goal the program is entered by and pick the part of its run with
%% from=/to=, or with when=COND (library/flow/debug.pl says more).
%%
%% FOR AN AGENT IN ANY LANGUAGE: one command, two files, and an exit status
%% that says what happened -- 0 both written, 1 the program has no such
%% predicate, 2 anything else, with the reason on stderr. Standard output
%% names the files it wrote (the two, or what svg= and xml= leave; BASE.txt
%% as well with txt=true; with cache=DIR the chart's XML that BASE.xml
%% names; BASE.prof with profile=) and then one line about the run:
%%
%%     go(30,R): answer at step 501; recorded 402 to 501; diverged no
%%
%% and with a journal, how many portal calls it held and how many of them
%% answered the replay; a replay that left its journal says where:
%%
%%     grow(F): left its journal at step 7 (stopped at step 9); recorded 1 to 9; diverged yes (the probe: answer at step 9; the replay: diverged at step 9); journal 2 portal calls, 0 answered
%%
%% A replay that diverged says both ends, the probe's -- which the window
%% was taken from -- and the replay's (1.11.4):
%%
%%     go(X): exception at step 181; recorded 4429637 to 4433636; diverged yes (the probe: answer at step 4433636; the replay: exception at step 181)
%%
%% and with when=COND, where it first holds -- or that it does not where the
%% run ends, when nothing is drawn and no file is named:
%%
%%     fill(L): nth1(3,L,X),X==3 first holds at step 10; recorded 1 to 10
%%
%% and with diff=, each run's files, BASE.diff, and how the two compare:
%%
%%     a total([1, 2, 3], T): answer at step 12; b total([1, 2, 3], T): answer at step 18; 3 inputs in both, 3 answered differently, 0 predicates only in a, 1 only in b
%%
%% and with windows=N, each window's files and line, BASE.prof, and the
%% run's line with every window (1.11.10):
%%
%%     go(40, R): answer at step 564; 3 windows: 139 to 188, 327 to 376, 515 to 564
%%
%% (the XML's <run> holds every call, event and binding; library/flow/debug.pl
%% and library/flow/dbgdraw.pl say what each is). A run that failed or threw
%% is no failure of the command: the exit status stays 0.

:- use_module(library(flow/debug)).
:- use_module(library(stream)).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [GoalA, File, Base|OptAs]
    ->  true
    ;   format(user_error, "usage: cocolog -s tools/flow/debug.pl -- GOAL FILE BASE [until=end|answer(K)] [window=N] [from=I] [to=J] [windows=N] [jobs=J] [discs=N] [text=N] [view=flow|tree] [depth=N|all] [only=NAME/ARITY,...] [timeout=MS] [journal=true|false] [journal_file=F] [txt=true|false] [svg=true|false] [xml=true|false] [profile=true|false|all|inclusive,steps,callers,repeats,time] [cache=DIR] [embed=DIR] [kb=NAME] [own=all|FILE,...] [when=COND] [step=N] [diff=FILE] [diff_goal=GOAL]~n", []),
        halt(2)
    ),
    (   exists_file(File)
    ->  true
    ;   format(user_error, "debug: no file ~w~n", [File]),
        halt(2)
    ),
    fd_split('when=', OptAs, CondA, OptAs0),
    fd_split('diff_goal=', OptAs0, GoalBA, OptAs1),
    (   CondA == none
    ->  (   fd_read_goal(GoalA, Goal, Names), callable(Goal)
        ->  true
        ;   format(user_error, "debug: ~w does not read as a goal~n", [GoalA]),
            halt(2)
        )
    ;   atomic_list_concat(['(', GoalA, ') - (', CondA, ')'], GC),
        (   fd_read_goal(GC, Goal-Cond, Names), callable(Goal), callable(Cond)
        ->  true
        ;   format(user_error, "debug: ~w and ~w do not read as a goal and a question~n", [GoalA, CondA]),
            halt(2)
        )
    ),
    fd_options(OptAs1, Opts0),
    (   selectchk(profile(Vs), Opts0, Opts) -> true ; Vs = [], Opts = Opts0 ),
    (   CondA == none
    ->  true
    ;   fd_when(Goal, Cond, Names, File, Base, Opts),
        halt(0)
    ),
    (   GoalBA == none, \+ memberchk(diff(_), Opts)
    ->  true
    ;   fd_diff(Goal, Names, File, GoalBA, Base, Opts),
        halt(0)
    ),
    (   memberchk(windows(_), Opts)
    ->  fd_windows(Goal, Names, File, Base, Opts, Vs),
        halt(0)
    ;   true
    ),
    fd_answers(Vs, Ans),
    append(Ans, Opts, POs),
    catch(flow_debug(Goal, Base, [source(File), names(Names)|POs], Run), E, fd_error(E)),
    fd_files(Goal, File, Base, Opts),
    fd_profile(Vs, Base, Ans),
    flow_term_full(Goal, Names, 999, GT),
    fd_line(GT, Run).

%% the run's line: how it ended and where, the window, whether the replay
%% was the probe's run, and what the journal answered
fd_line(GT, run(How, At, _, window(F, T), _, _, Div, J)) :-
    fd_how(How, At, HT),
    flow_dbg_div_ends(Div, DT),
    (   J = journal(Es)
    ->  length(Es, NE),
        (   How = diverged(DI2, _, _) -> Lim is DI2 - 1 ; Lim = At ),
        findall(x, ( member(j(I, _, _, _, _), Es), I =< Lim ), As), length(As, NA),
        format(atom(JT), '; journal ~d portal calls, ~d answered', [NE, NA])
    ;   JT = ''
    ),
    format("~w: ~w; recorded ~w to ~w; diverged ~w~w~n", [GT, HT, F, T, DT, JT]).

fd_how(How, At, HT) :-
    (   How = exception(B) -> format(atom(HT), 'exception ~q at step ~w', [B, At])
    ;   How = diverged(DI, _, _) -> format(atom(HT), 'left its journal at step ~w (stopped at step ~w)', [DI, At])
    ;   format(atom(HT), '~w at step ~w', [How, At])
    ).

%% PROFILE=: the views BASE.prof holds, in this order, a blank line between
%% -- inclusive (profile=true), steps, callers, repeats and time (all five
%% with profile=all) -- and the answers flow_debug/4 is asked for to write
%% them
fd_answers(Vs, Ans) :-
    findall(A, ( member(V-A, [inclusive-profile(_), steps-profile(_), callers-callers(_),
                              repeats-repeats(_), time-time(_)]),
                 memberchk(V, Vs) ),
            As0),
    fd_one_profile(As0, Ans).

%% profile(P) asked once, for inclusive and steps alike
fd_one_profile(As0, As) :-
    (   select(profile(P), As0, As1), select(profile(P), As1, As2) -> As = [profile(P)|As2]
    ;   As = As0
    ).

fd_profile([], _, _) :- !.
fd_profile(Vs, Base, Ans) :-
    (   memberchk(profile(P), Ans) -> true ; P = none ),
    (   memberchk(callers(C), Ans) -> true ; C = none ),
    (   memberchk(repeats(R), Ans) -> true ; R = none ),
    (   memberchk(time(Ti), Ans) -> true ; Ti = none ),
    fd_profile_write(Vs, Base, P, C, R, Ti).

fd_profile_write(Vs, Base, P, C, R, Ti) :-
    findall(T, ( member(V, Vs), fd_view_text(V, P, C, R, Ti, T) ), Ts),
    atomic_list_concat(Ts, '\n', Text),
    atom_concat(Base, '.prof', PFile),
    open(PFile, write, PS), write(PS, Text), close(PS),
    format("~w~n", [PFile]).

fd_view_text(inclusive, P, _, _, _, T) :- flow_profile_text(P, T).
fd_view_text(steps, P, _, _, _, T) :- flow_steps_text(P, T).
fd_view_text(callers, _, C, _, _, T) :- flow_callers_text(C, T).
fd_view_text(repeats, _, _, R, _, T) :- flow_repeats_text(R, T).
fd_view_text(time, _, _, _, Ti, T) :- flow_time_text(Ti, T).

%% WINDOWS=N: N windows along the run (flow_debug_windows/4), each written
%% as BASE.K.* and its line said, then BASE.prof of them all when profile=
%% asks, and a line for the run. The chart is kept in cache=DIR, or in
%% BASE.charts when none is given, which each window's XML names. The time
%% view's probes run under the clock, each window's (1.13.3)
fd_windows(Goal, Names, File, Base, Opts0, Vs) :-
    (   memberchk(cache(_), Opts0) -> Opts1 = Opts0
    ;   catch(use_module(library(sha)), _, fail)
    ->  atom_concat(Base, '.charts', CD),
        Opts1 = [cache(CD)|Opts0]
    ;   Opts1 = Opts0
    ),
    (   memberchk(time, Vs) -> Opts = [time(_)|Opts1] ; Opts = Opts1 ),
    catch(flow_debug_windows(Goal, Base, [source(File), names(Names)|Opts], windows(End, Ws)), E, fd_error(E)),
    flow_term_full(Goal, Names, 999, GT),
    forall(member(window(_, BK, Run, _), Ws),
           ( fd_files(Goal, File, BK, Opts), fd_line(GT, Run) )),
    (   Vs == [] -> true
    ;   findall(Rows, member(window(_, _, _, Rows), Ws), RLs),
        flow_profile_merge(RLs, P, C, R, Ti),
        fd_profile_write(Vs, Base, P, C, R, Ti)
    ),
    End = end(How, At, _),
    fd_how(How, At, HT),
    length(Ws, NW),
    findall(WT, ( member(window(_, _, run(_, _, _, window(F, T), _, _, _, _), _), Ws),
                  format(atom(WT), '~w to ~w', [F, T]) ),
            WTs),
    atomic_list_concat(WTs, ', ', WA),
    format("~w: ~w; ~d windows: ~w~n", [GT, HT, NW, WA]).

%% when=COND and diff_goal=GOAL, taken out before the others: each is
%% Prolog and may hold an =
fd_split(_, [], none, []).
fd_split(P, [A|As], C, Rest) :-
    (   atom_concat(P, C0, A)
    ->  C = C0, Rest = As
    ;   fd_split(P, As, C, Rest0), Rest = [A|Rest0]
    ).

%% when=COND: where COND first holds, and the window that ends there drawn;
%% a COND that does not hold where the run ends draws nothing
fd_when(Goal, Cond, Names, File, Base, Opts) :-
    catch(flow_when(Goal, Cond, [source(File), names(Names), base(Base)|Opts], When), E, fd_error(E)),
    flow_term_full(Goal, Names, 999, GT),
    flow_term_full(Cond, Names, 999, CT),
    (   When = at(I)
    ->  ( memberchk(window(W), Opts) -> true ; W = 2000 ),
        From is max(1, I - W + 1),
        fd_files(Goal, File, Base, Opts),
        format("~w: ~w first holds at step ~w; recorded ~w to ~w~n", [GT, CT, I, From, I])
    ;   format("~w: ~w does not hold where the run ends~n", [GT, CT])
    ).

%% diff=FILE_B, diff_goal=GOAL_B or both: GOAL over FILE against GOAL_B
%% (GOAL by default) over FILE_B (FILE by default), each run recorded whole
%% unless a window is given -- BASE.a.* and BASE.b.* as each would be
%% written alone, and BASE.diff (flow_diff_text/4)
fd_diff(Goal, Names, File, GoalBA, Base, Opts) :-
    (   memberchk(diff(FileB), Opts) -> true ; FileB = File ),
    (   exists_file(FileB) -> true
    ;   format(user_error, "debug: no file ~w~n", [FileB]),
        halt(2)
    ),
    (   GoalBA == none
    ->  GoalB = Goal, NamesB = Names
    ;   fd_read_goal(GoalBA, GoalB, NamesB), callable(GoalB)
    ->  true
    ;   format(user_error, "debug: ~w does not read as a goal~n", [GoalBA]),
        halt(2)
    ),
    findall(O, ( member(O, Opts), \+ functor(O, diff, 1) ), Os0),
    (   ( memberchk(from(_), Os0) ; memberchk(to(_), Os0) ; memberchk(window(_), Os0) )
    ->  Os = Os0
    ;   Os = [from(1)|Os0]
    ),
    atom_concat(Base, '.a', BaseA),
    atom_concat(Base, '.b', BaseB),
    catch(flow_debug(Goal, BaseA, [source(File), names(Names), places(PA)|Os], RA), E, fd_error(E)),
    catch(flow_debug(GoalB, BaseB, [source(FileB), names(NamesB), places(PB)|Os], RB), E2, fd_error(E2)),
    flow_diff(RA, RB, D),
    flow_diff_text(D, PA, PB, Text),
    atom_concat(Base, '.diff', DF),
    open(DF, write, S), write(S, Text), close(S),
    fd_files(Goal, File, BaseA, Os),
    fd_files(GoalB, FileB, BaseB, Os),
    format("~w~n", [DF]),
    D = diff(Both, Ds, OA, OB),
    length(Ds, ND), length(OA, NA), length(OB, NB),
    fd_ended(RA, HA), fd_ended(RB, HB),
    flow_term_full(Goal, Names, 999, GT),
    flow_term_full(GoalB, NamesB, 999, GTB),
    format("a ~w: ~w; b ~w: ~w; ~d inputs in both, ~d answered differently, ~d predicates only in a, ~d only in b~n",
           [GT, HA, GTB, HB, Both, ND, NA, NB]).

fd_ended(run(How, At, _, _, _, _, _, _), T) :-
    (   How = exception(B) -> format(atom(T), 'exception ~q at step ~w', [B, At])
    ;   How = diverged(DI, _, _) -> format(atom(T), 'left its journal at step ~w', [DI])
    ;   format(atom(T), '~w at step ~w', [How, At])
    ).

%% the files written, a line each: BASE.svg and BASE.xml unless svg=false
%% and xml=false leave them out, BASE.txt with txt=true, and the chart's
%% XML that BASE.xml names, kept in cache=DIR
fd_files(Goal, File, Base, Opts) :-
    (   memberchk(svg(false), Opts) -> true ; format("~w.svg~n", [Base]) ),
    (   memberchk(xml(false), Opts) -> true ; format("~w.xml~n", [Base]) ),
    (   memberchk(txt(true), Opts) -> format("~w.txt~n", [Base]) ; true ),
    (   memberchk(xml(false), Opts) -> true
    ;   flow_dbg_chart_xml(Goal, [source(File)|Opts], CX),
        (   CX == none -> true ; format("~w~n", [CX]) )
    ).

%% the goal with the names it writes: read from a file of its own, which is
%% how read_term/3 gives them
fd_read_goal(A, Goal, Names) :-
    tmp_file(flowgoal, F),
    open(F, write, S),
    format(S, "~w .~n", [A]),
    close(S),
    catch(( open(F, read, R),
            read_term(R, Goal, [variable_names(Names)]),
            close(R) ),
          _, fail),
    catch(delete_file(F), _, true).

fd_options([], []).
fd_options([A|As], [O|Os]) :-
    (   atomic_list_concat([K, V], '=', A), fd_option(K, V, O)
    ->  true
    ;   format(user_error, "debug: an option is until=, window=, from=, to=, windows=, jobs=, discs=, text=, view=, depth=, only=, timeout=, journal=, journal_file=, txt=, svg=, xml=, profile=, cache=, embed=, kb=, own=, when=, step=, diff= or diff_goal=, not ~w~n", [A]),
        halt(2)
    ),
    fd_options(As, Os).

fd_option(until, V, until(U)) :-
    catch(term_to_atom(U, V), _, fail).
fd_option(view, V, view(V)) :-
    memberchk(V, [flow, tree]).
fd_option(journal, V, journal(V)) :-
    memberchk(V, [true, false]).
fd_option(txt, V, txt(V)) :-
    memberchk(V, [true, false]).
fd_option(svg, V, svg(V)) :-
    memberchk(V, [true, false]).
fd_option(xml, V, xml(V)) :-
    memberchk(V, [true, false]).
fd_option(profile, V, profile(Vs)) :-
    fd_views(V, Vs).
%% windows=N and jobs=J, each at least 1
fd_option(K, V, O) :-
    memberchk(K, [windows, jobs]),
    catch(atom_number(V, N), _, fail),
    integer(N), N >= 1,
    O =.. [K, N].
fd_option(journal_file, V, journal_file(V)) :-
    V \== ''.
fd_option(cache, V, cache(V)) :-
    V \== ''.
fd_option(embed, V, embed(V)) :-
    V \== ''.
fd_option(kb, V, kb(V)) :-
    V \== ''.
fd_option(diff, V, diff(V)) :-
    V \== ''.
fd_option(own, V, own(O)) :-
    (   memberchk(V, [all, chart]) -> O = V
    ;   atomic_list_concat(O, ',', V), O \== []
    ).
%% depth= and only=, as chart.pl reads them: they bound the picture, which
%% for a large program is otherwise the 150 panels that fit
fd_option(depth, V, depth(D)) :-
    (   V == all -> D = all
    ;   catch(atom_number(V, D), _, fail), integer(D), D >= 1
    ).
fd_option(only, V, only(Ps)) :-
    atomic_list_concat(As, ',', V),
    fd_preds(As, Ps).
fd_option(K, V, O) :-
    memberchk(K, [window, from, to, discs, text, timeout, step]),
    catch(atom_number(V, N), _, fail),
    integer(N), N >= 0,
    O =.. [K, N].

%% profile=: true (the inclusive view alone, as through 1.11.9), false,
%% all, or views by name, a comma between -- in BASE.prof always in the
%% order inclusive, steps, callers, repeats, time
fd_views(true, [inclusive]) :- !.
fd_views(false, []) :- !.
fd_views(all, [inclusive, steps, callers, repeats, time]) :- !.
fd_views(V, Vs) :-
    atomic_list_concat(Vs0, ',', V),
    Vs0 \== [],
    forall(member(X, Vs0), memberchk(X, [inclusive, steps, callers, repeats, time])),
    findall(X, ( member(X, [inclusive, steps, callers, repeats, time]), memberchk(X, Vs0) ), Vs).

fd_preds([], []).
fd_preds([A|As], [P|Ps]) :-
    catch(term_to_atom(P, A), _, fail),
    flow_pred_spec(P),
    fd_preds(As, Ps).

fd_error(error(existence_error(procedure, PI), _)) :- !,
    format(user_error, "debug: the program has no ~w~n", [PI]),
    halt(1).
fd_error(error(flow_debug_run(File, Exit, Said), _)) :- !,
    format(user_error, "debug: running ~w in a child process ended with status ~w:~n~w~n", [File, Exit, Said]),
    halt(2).
fd_error(E) :-
    format(user_error, "debug: ~q~n", [E]),
    halt(2).
