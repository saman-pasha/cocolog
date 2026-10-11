%% tools/flow/chart.pl -- a flowchart from the command line, as SVG and XML.
%%
%%     cocolog -s tools/flow/chart.pl -- SPEC FILE BASE [OPTION ...]
%%
%%     SPEC     a call pattern, 'report(+,+,+)'; name/arity, every argument ?;
%%              or name//arity, a nonterminal called to parse
%%     FILE     the program
%%     BASE     what to write: BASE.svg for a person, BASE.xml for an agent
%%     OPTION   libraries=reach|all|none    title=TEXT
%%              depth=N|all                 draw panels at most N calls deep
%%              only=NAME/ARITY,NAME//ARITY draw these predicates' panels
%%
%% depth and only change the picture alone: the XML always has everything.
%% A chart of more than 150 panels is drawn to the depth that fits unless
%% one of them says otherwise.
%%
%% FOR AN AGENT IN ANY LANGUAGE: one command, two files, and an exit status
%% that says what happened -- 0 both written, 1 the program has no such
%% predicate, 2 anything else, with the reason on stderr. The XML's shape is
%% in library/flow/xml.pl's header, and DESIGN-flow.md says what it is for.

:- use_module(library(flowchart)).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [SpecA, File, Base|OptAs]
    ->  true
    ;   format(user_error, "usage: cocolog -s tools/flow/chart.pl -- SPEC FILE BASE [libraries=reach|all|none] [title=TEXT] [depth=N|all] [only=NAME/ARITY,...]~n", []),
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
    fc_options(OptAs, Opts),
    catch(flow_chart(Spec, Base, [source(File)|Opts]), E, fc_error(E)),
    format("~w.svg~n~w.xml~n", [Base, Base]).

fc_options([], []).
fc_options([A|As], [O|Os]) :-
    (   atomic_list_concat([K, V], '=', A), fc_option(K, V, O)
    ->  true
    ;   format(user_error, "chart: an option is libraries=..., title=..., depth=... or only=..., not ~w~n", [A]),
        halt(2)
    ),
    fc_options(As, Os).

fc_option(libraries, V, libraries(V)) :- memberchk(V, [reach, all, none]).
fc_option(title, V, title(V)).
fc_option(depth, V, depth(D)) :-
    (   V == all -> D = all
    ;   catch(atom_number(V, D), _, fail), integer(D), D >= 1
    ).
fc_option(only, V, only(Ps)) :-
    atomic_list_concat(As, ',', V),
    fc_preds(As, Ps).

fc_preds([], []).
fc_preds([A|As], [P|Ps]) :-
    catch(term_to_atom(P, A), _, fail),
    flow_pred_spec(P),
    fc_preds(As, Ps).

fc_error(error(existence_error(procedure, PI), _)) :- !,
    format(user_error, "chart: the program has no ~w~n", [PI]),
    halt(1).
fc_error(E) :-
    format(user_error, "chart: ~w~n", [E]),
    halt(2).
