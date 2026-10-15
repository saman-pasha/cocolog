%% tools/flow/chart.pl -- a flowchart from the command line, as SVG and XML.
%%
%%     cocolog -s tools/flow/chart.pl -- SPEC FILE BASE [OPTION ...]
%%
%%     SPEC     a call pattern, 'report(+,+,+)'; name/arity, every argument ?;
%%              or name//arity, a nonterminal called to parse
%%     FILE     the program
%%     BASE     what to write: BASE.svg for a person, BASE.xml for an agent
%%     OPTION   libraries=none|reach|all    none (the default): a library
%%                                          predicate is a box, never opened;
%%                                          reach: opened on a path to C;
%%                                          all: every one opened
%%              title=TEXT
%%              depth=N|all                 draw panels at most N calls deep
%%              only=NAME/ARITY,NAME//ARITY draw these predicates' panels
%%              load=FILE,library(NAME),... the program's other files, or
%%                                          its top file: loaded first, so a
%%                                          call into one is no unknown
%%                                          procedure; only FILE is drawn
%%              modules=SRC.cicili,...      the program's own modules, by
%%                                          their Cicili sources: each row
%%                                          of their tables a C predicate
%%              progress=S                  a line on stderr every S seconds
%%                                          once the chart has run S seconds
%%                                          (10; 0 for none)
%%
%% depth and only change the picture alone: the XML always has everything.
%% A chart of more than 150 panels is drawn to the depth that fits unless
%% depth or only says otherwise.
%%
%% FOR AN AGENT IN ANY LANGUAGE: one command, two files, and an exit status
%% that says what happened -- 0 both written, 1 the program has no such
%% predicate, 2 anything else, with the reason on stderr. Standard output
%% names the two files and then the FINDINGS, one a line, as a compiler
%% writes them:
%%
%%     test/flowchart/faults.pl:29:5: error: total/2: S is free on every path
%%     to here, and is/2 evaluates it: this call raises an instantiation error
%%     [instantiation p2.c1.g1]
%%
%% (one line each; the id is the box in the SVG and the element in the XML).
%% A finding is no failure of the command: the exit status stays 0. The
%% XML's shape is in library/flow/xml.pl's header, and DESIGN-flow.md says
%% what it is for.

:- use_module(library(flow/chart)).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [SpecA, File, Base|OptAs]
    ->  true
    ;   format(user_error, "usage: cocolog -s tools/flow/chart.pl -- SPEC FILE BASE [libraries=none|reach|all] [title=TEXT] [depth=N|all] [only=NAME/ARITY,...] [load=FILE,...] [modules=SRC,...] [progress=S]~n", []),
        halt(2)
    ),
    (   catch(term_to_atom(Spec, SpecA), _, fail)
    ->  true
    ;   format(user_error, "chart: ~w does not read as a call pattern~n", [SpecA]),
        halt(2)
    ),
    (   exists_file(File)
    ->  true
    ;   format(user_error, "chart: no file ~w~n", [File]),
        halt(2)
    ),
    fc_options(OptAs, Opts0),
    (   memberchk(progress(_), Opts0) -> Opts = Opts0 ; Opts = [progress(10)|Opts0] ),
    catch(flow_chart(Spec, Base, [source(File)|Opts], Fs), E, fc_error(E)),
    format("~w.svg~n~w.xml~n", [Base, Base]),
    forall(member(F, Fs), fc_finding(F)).

%% a finding as a compiler says one: FILE:LINE:COL: error: IN: TEXT [KIND ID]
fc_finding(finding(_, Kind, Sev, At, In, Where, Text, _)) :-
    (   Where = where(F, L, C) -> format("~w:~w:~w: ", [F, L, C]) ; true ),
    format("~w: ~w: ~w [~w ~w]~n", [Sev, In, Text, Kind, At]).

fc_options([], []).
fc_options([A|As], [O|Os]) :-
    (   atomic_list_concat([K, V], '=', A), fc_option(K, V, O)
    ->  true
    ;   format(user_error, "chart: an option is libraries=..., title=..., depth=..., only=..., load=... or progress=..., not ~w~n", [A]),
        halt(2)
    ),
    fc_options(As, Os).

fc_option(libraries, V, libraries(V)) :- memberchk(V, [none, reach, all]).
fc_option(title, V, title(V)).
fc_option(depth, V, depth(D)) :-
    (   V == all -> D = all
    ;   catch(atom_number(V, D), _, fail), integer(D), D >= 1
    ).
fc_option(only, V, only(Ps)) :-
    atomic_list_concat(As, ',', V),
    fc_preds(As, Ps).
fc_option(load, V, load(Fs)) :-
    atomic_list_concat(As, ',', V),
    fc_files(As, Fs).
fc_option(modules, V, modules(Fs)) :-
    atomic_list_concat(Fs, ',', V).
fc_option(progress, V, progress(S)) :-
    catch(atom_number(V, S), _, fail), number(S), S >= 0.

%% a file by its path, or library(Name) as a term
fc_files([], []).
fc_files([A|As], [F|Fs]) :-
    (   atom_concat('library(', _, A) -> catch(term_to_atom(F, A), _, fail) ; F = A ),
    fc_files(As, Fs).

fc_preds([], []).
fc_preds([A|As], [P|Ps]) :-
    catch(term_to_atom(P, A), _, fail),
    flow_pred_spec(P),
    fc_preds(As, Ps).

fc_error(error(existence_error(procedure, PI), _)) :- !,
    format(user_error, "chart: the program has no ~w~n", [PI]),
    halt(1).
fc_error(error(existence_error(flow_load, F), _)) :- !,
    format(user_error, "chart: load=~w would not load: no such file or library~n", [F]),
    halt(2).
fc_error(error(existence_error(flow_module, F), _)) :- !,
    format(user_error, "chart: modules=~w: no such file~n", [F]),
    halt(2).
fc_error(error(permission_error(modify, flow_procedure, _), context(_, Msg))) :- !,
    format(user_error, "chart: ~w~n", [Msg]),
    halt(2).
fc_error(E) :-
    format(user_error, "chart: ~w~n", [E]),
    halt(2).
