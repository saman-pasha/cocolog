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
%%              window=N              the last N inferences up to there (2000)
%%              from=I  to=J          the window by its inferences instead
%%              discs=N               bindings numbered on the picture (24)
%%              text=N                a value written whole up to N characters
%%              view=flow|tree        the chart with the run over it, or the calls
%%              timeout=MS            for each run of the program
%%
%% FOR AN AGENT IN ANY LANGUAGE: one command, two files, and an exit status
%% that says what happened -- 0 both written, 1 the program has no such
%% predicate, 2 anything else, with the reason on stderr. Standard output
%% names the two files and then one line about the run:
%%
%%     go(30,R): answer at inference 501; recorded 402 to 501; diverged no
%%
%% (the XML's <run> holds every call, event and binding; library/flowdebug.pl
%% and library/flow/dbgdraw.pl say what each is). A run that failed or threw
%% is no failure of the command: the exit status stays 0.

:- use_module(library(flowdebug)).
:- use_module(library(stream)).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [GoalA, File, Base|OptAs]
    ->  true
    ;   format(user_error, "usage: cocolog -s tools/flow/debug.pl -- GOAL FILE BASE [until=end|answer(K)] [window=N] [from=I] [to=J] [discs=N] [text=N] [view=flow|tree] [timeout=MS]~n", []),
        halt(2)
    ),
    (   exists_file(File)
    ->  true
    ;   format(user_error, "debug: no file ~w~n", [File]),
        halt(2)
    ),
    (   fd_read_goal(GoalA, Goal, Names), callable(Goal)
    ->  true
    ;   format(user_error, "debug: ~w does not read as a goal~n", [GoalA]),
        halt(2)
    ),
    fd_options(OptAs, Opts),
    catch(flow_debug(Goal, Base, [source(File), names(Names)|Opts], Run), E, fd_error(E)),
    format("~w.svg~n~w.xml~n", [Base, Base]),
    Run = run(How, At, _, window(F, T), _, _, Div),
    (   How = exception(B) -> format(atom(HT), 'exception ~q', [B]) ; HT = How ),
    (   Div == false -> DT = no ; DT = yes ),
    flow_term_full(Goal, Names, 999, GT),
    format("~w: ~w at inference ~w; recorded ~w to ~w; diverged ~w~n", [GT, HT, At, F, T, DT]).

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
    ;   format(user_error, "debug: an option is until=, window=, from=, to=, discs=, text=, view= or timeout=, not ~w~n", [A]),
        halt(2)
    ),
    fd_options(As, Os).

fd_option(until, V, until(U)) :-
    catch(term_to_atom(U, V), _, fail).
fd_option(view, V, view(V)) :-
    memberchk(V, [flow, tree]).
fd_option(K, V, O) :-
    memberchk(K, [window, from, to, discs, text, timeout]),
    catch(atom_number(V, N), _, fail),
    integer(N), N >= 0,
    O =.. [K, N].

fd_error(error(existence_error(procedure, PI), _)) :- !,
    format(user_error, "debug: the program has no ~w~n", [PI]),
    halt(1).
fd_error(error(flow_debug_run(File, Exit, Said), _)) :- !,
    format(user_error, "debug: running ~w in a child process ended with status ~w:~n~w~n", [File, Exit, Said]),
    halt(2).
fd_error(E) :-
    format(user_error, "debug: ~q~n", [E]),
    halt(2).
