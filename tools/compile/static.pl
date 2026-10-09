%% static.pl -- how much of cocolog's own Prolog has code that is fixed
%% before it runs: the count DESIGN-compiling.md §7 asked for, and which
%% its §8 puts before any code generator.
%%
%%     cocolog --local run tools/cocolint/blocklist.pl tools/compile/static.pl sf_main
%%     ...                                                     -- DIR-OR-FILE...
%%
%% With nothing after `--' it reads what §7 named -- library/, tutorials/
%% and coworker/, every .pl under each -- and prints a block for each and
%% one for all of them. blocklist.pl is cocolint's, generated from the
%% engine's own tables: which names are builtins, and which are which
%% library's.
%%
%% WHAT A COMPILER NEEDS TO KNOW OF A PREDICATE is whether its clauses can
%% change once the program runs. They can when the file declares it
%% `dynamic', or a clause of the file asserts into it, retracts from it or
%% abolishes it, naming its head; and all of a file's predicates can when
%% the file changes something it does not name (`assertz(C)' with C made
%% at run time) or consults a file while it runs. Everything else is
%% FIXED: a compiler may take it.
%%
%% AND WHAT ITS CALLS ARE. A goal in a body is a LOCAL call (the file
%% defines it), a BUILTIN, a LIBRARY predicate (tier 1's clauses, tier 2's
%% modules, a file of library/), an ASSERTED one (the file changes it by
%% name and defines no clause of it: data it makes as it runs), a CLOSURE
%% -- an argument of the clause's own head, called: the caller knows it and
%% the clause does not -- or COMPUTED, a goal made at run time that only
%% the running program can name. UNRESOLVED is a name nothing above
%% defines. `true', a fact's body, and the cut are no calls.
%%
%% A META-PREDICATE'S GOALS ARE CALLS. `findall(X, p(X), L)' calls p/1 and
%% `maplist(q, Xs)' calls q/1, as well as findall/3 and maplist/2. The
%% builtins' goal positions are a table (sf_meta/3); a predicate of the
%% corpus that calls an argument of its own head becomes one too, found
%% to a fixpoint (sf_infer/0) -- so `astar(S, G, next, h, P, C)' calls
%% next/4 and h/2, because library(astar) calls those arguments so.
%%
%% REACHED is what the file's roots reach through literal calls: its
%% directives, `main/0' and a module's exports, or every predicate of a
%% file that has none of those. What is not reached is called only through
%% a closure or a computed goal, or not at all.
%%
%% HONEST LIMITS. Each file is its own program: a predicate is changed
%% only by its own file (the heads a file changes and does not define are
%% counted, so the limit shows). A goal bound to a variable in the body
%% and then called -- `G = p(X), call(G)' -- is counted COMPUTED, as is a
%% closure a meta-predicate passes on through a variable the analysis does
%% not follow. A computed change or a run-time consult marks the whole
%% file. Each of these errs towards less being fixed.

:- use_module(library(stream)).

:- dynamic sf_file/2.
:- dynamic sf_unread/2.
:- dynamic sf_cl/4.
:- dynamic sf_declared/2.
:- dynamic sf_export/2.
:- dynamic sf_meta_inf/4.
:- dynamic sf_ev/3.
:- dynamic sf_unknown/1.
:- dynamic sf_mod/2.
:- dynamic sf_libdef/2.
:- dynamic sf_def/3.
:- dynamic sf_ncl/4.
:- dynamic sf_out/4.

sf_main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args == [] -> Roots = [library, tutorials, coworker] ; Roots = Args ),
    forall(member(R, Roots), sf_load_root(R)),
    sf_reread,
    sf_index,
    sf_library_index,
    sf_infer,
    sf_events,
    sf_edges,
    sf_changes,
    format("static.pl -- clauses a compiler could take, and what calls them~n"),
    forall(member(R, Roots), sf_report([R])),
    (   Roots = [_, _|_] -> sf_report(Roots) ; true ),
    sf_report_files(Roots),
    sf_report_unresolved(Roots).

%% ---- reading ------------------------------------------------------------

%% every .pl under a directory, in name order, or the one file named
sf_pl_files(P, Fs) :-
    exists_directory(P), !,
    directory_files(P, Es0),
    msort(Es0, Es),
    findall(F, ( member(E, Es), E \== '.', E \== '..',
                 atomic_list_concat([P, '/', E], Q),
                 sf_pl_files(Q, Fs0), member(F, Fs0) ),
            Fs).
sf_pl_files(P, [P]) :- file_name_extension(_, pl, P), !.
sf_pl_files(_, []).

sf_load_root(R) :-
    sf_pl_files(R, Fs),
    forall(member(F, Fs), sf_read_file(R, F)).

%% A FILE THAT WILL NOT READ IS COUNTED AS SUCH, with the clauses read
%% before the error kept. Its operators are its own: an `op/3' directive
%% is obeyed as it is met, so a later clause of the file -- or of a file
%% that uses its library -- reads as cocolog would read it.
sf_read_file(Seg, F) :-
    assertz(sf_file(F, Seg)),
    catch(open(F, read, S), E, ( assertz(sf_unread(F, E)), fail )), !,
    sf_read_terms(S, F),
    close(S).
sf_read_file(_, _).

sf_read_terms(S, F) :-
    catch(read_term(S, T, []), E, ( assertz(sf_unread(F, E)), T = end_of_file )),
    (   T == end_of_file -> true
    ;   sf_term(F, T), sf_read_terms(S, F)
    ).

%% A FILE READ BEFORE THE LIBRARY THAT DEFINES ITS OPERATORS -- name order
%% puts library/reasoning/ before library/tensor_expr.pl -- is read again
%% once every file has been, from the start, what it gave the first time
%% forgotten
sf_reread :-
    findall(F, sf_unread(F, _), Fs0),
    sort(Fs0, Fs),
    forall(member(F, Fs),
           ( retractall(sf_unread(F, _)), retractall(sf_cl(F, _, _, _)),
             retractall(sf_declared(F, _)), retractall(sf_export(F, _)),
             (   catch(open(F, read, S), E, ( assertz(sf_unread(F, E)), fail ))
             ->  sf_read_terms(S, F), close(S)
             ;   true
             ) )).

sf_term(F, T) :- var(T), !, assertz(sf_unread(F, variable_clause)).
sf_term(F, (:- D)) :- !, sf_directive(F, D).
sf_term(F, (H --> B)) :- !, sf_dcg(F, H, B).
sf_term(F, (H :- B)) :- !, sf_clause(F, H, B).
sf_term(F, H) :- sf_clause(F, H, true).

sf_clause(F, H0, B) :-
    (   nonvar(H0), H0 = _:H1 -> true ; H1 = H0 ),
    (   callable(H1) -> functor(H1, N, A), assertz(sf_cl(F, N/A, H1, B)) ; true ).

%% A GRAMMAR RULE is counted as the clause it becomes: its head with the
%% two list arguments, its body through the engine's own translator (the
%% one phrase/3 uses). A pushback list is terminals and calls nothing.
sf_dcg(F, H0, B) :-
    (   nonvar(H0), H0 = (H1, _) -> true ; H1 = H0 ),
    (   callable(H1), catch('$dcg_goal'(B, S0, S, G), _, fail)
    ->  H1 =.. L, append(L, [S0, S], L2), H =.. L2,
        functor(H, N, A), assertz(sf_cl(F, N/A, H, G))
    ;   true
    ).

%% A DIRECTIVE that runs a goal is a root's body: the file's pseudo
%% predicate '$load'/0 holds every one, `initialization/1,2' included.
sf_directive(F, D) :- var(D), !, assertz(sf_cl(F, '$load'/0, '$load', D)).
sf_directive(_, op(P, T, N)) :- !, catch(op(P, T, N), _, true).
sf_directive(F, module(_, Es)) :- !, sf_exports(F, Es).
sf_directive(F, dynamic(Ss)) :- !,
    sf_specs(Ss, Ks),
    forall(member(K, Ks), assertz(sf_declared(F, K))).
sf_directive(F, initialization(G)) :- !, assertz(sf_cl(F, '$load'/0, '$load', G)).
sf_directive(F, initialization(G, _)) :- !, assertz(sf_cl(F, '$load'/0, '$load', G)).
sf_directive(_, D) :- sf_declaration(D), !.
sf_directive(F, G) :- assertz(sf_cl(F, '$load'/0, '$load', G)).

%% what a directive says about the program rather than runs in it
sf_declaration(use_module(_)).
sf_declaration(use_module(_, _)).
sf_declaration(ensure_loaded(_)).
sf_declaration(discontiguous(_)).
sf_declaration(multifile(_)).
sf_declaration(meta_predicate(_)).
sf_declaration(set_prolog_flag(_, _)).
sf_declaration(autoload(_)).
sf_declaration(autoload(_, _)).

sf_exports(_, Es) :- var(Es), !.
sf_exports(_, []) :- !.
sf_exports(F, [E|Es]) :- !, sf_export1(F, E), sf_exports(F, Es).
sf_exports(_, _).

sf_export1(_, E) :- var(E), !.
sf_export1(_, op(P, T, N)) :- !, catch(op(P, T, N), _, true).
sf_export1(F, E) :- sf_specs(E, Ks), forall(member(K, Ks), assertz(sf_export(F, K))).

%% `p/1', `p//2', and a conjunction or list of them
sf_specs(S, []) :- var(S), !.
sf_specs((A, B), Ks) :- !, sf_specs(A, K1), sf_specs(B, K2), append(K1, K2, Ks).
sf_specs([], []) :- !.
sf_specs([S|Ss], Ks) :- !, sf_specs(S, K1), sf_specs(Ss, K2), append(K1, K2, Ks).
sf_specs(_:S, Ks) :- !, sf_specs(S, Ks).
sf_specs(N/A, [N/A]) :- atom(N), integer(A), !.
sf_specs(N//A, [N/A2]) :- atom(N), integer(A), !, A2 is A + 2.
sf_specs(_, []).

%% ---- a body, goal by goal --------------------------------------------------

%% sf_event(+File, +Head, +Goal, -Event) enumerates what a goal does:
%%   call(N/A)          a call of a named predicate
%%   closure            a call of an argument of the head
%%   computed           a call of a goal made at run time
%%   modify(N/A)        a change to the clauses of a named predicate
%%   modify(computed)   a change to clauses it cannot name
%%   load               a consult at run time
sf_event(_, H, G, E) :- var(G), !, sf_var(G, H, E).
sf_event(F, H, _:G, E) :- !, sf_event(F, H, G, E).
sf_event(F, H, G, E) :- sf_control(G, Gs), !, member(G1, Gs), sf_event(F, H, G1, E).
sf_event(_, _, G, E) :- sf_modifier_goal(G), !, sf_modifies(G, E).
sf_event(_, _, G, E) :- sf_loads(G), !, E = load.
sf_event(F, H, G, E) :-
    callable(G), !,
    functor(G, N, A),
    (   E = call(N/A)
    ;   sf_meta_spec(F, N, A, Specs), member(I-K, Specs),
        arg(I, G, X), sf_closure(F, H, X, K, E)
    ).

%% a construct is no call; `true', a fact's body, and the cut call nothing
sf_control(true, []).
sf_control(!, []).
sf_control((A, B), [A, B]).
sf_control((A ; B), [A, B]).
sf_control((A -> B), [A, B]).
sf_control((A *-> B), [A, B]).
sf_control(\+ A, [A]).
sf_control(_ ^ A, [A]).

sf_var(V, H, E) :-
    term_variables(H, Vs),
    (   sf_memq(V, Vs) -> E = closure ; E = computed ).

sf_memq(X, [Y|Ys]) :- ( X == Y -> true ; sf_memq(X, Ys) ).

%% a goal position holding X, called with K more arguments
sf_closure(_, H, X, _, E) :- var(X), !, sf_var(X, H, E).
sf_closure(F, H, _:X, K, E) :- !, sf_closure(F, H, X, K, E).
sf_closure(F, H, X, dcg, E) :- !,
    catch('$dcg_goal'(X, _, _, G), _, fail),
    sf_event(F, H, G, E).
sf_closure(F, H, _>>B, _, E) :- !, sf_event(F, H, B, E).
sf_closure(F, H, X, 0, E) :- !, sf_event(F, H, X, E).
sf_closure(_, _, X, K, call(N/A)) :-
    callable(X), functor(X, N, A0), A is A0 + K.

%% a goal that changes clauses, by its name; what it changes, one by one
sf_modifier_goal(G) :- functor(G, N, A), sf_modifier(N, A).

sf_modifier(assert, 1).
sf_modifier(asserta, 1).
sf_modifier(assertz, 1).
sf_modifier(retract, 1).
sf_modifier(retractall, 1).
sf_modifier(abolish, 1).
sf_modifier(abolish, 2).
sf_modifier(dynamic, 1).

sf_modifies(abolish(S), E) :- !,
    (   nonvar(S), S = N/A, atom(N), integer(A) -> E = modify(N/A) ; E = modify(computed) ).
sf_modifies(abolish(N, A), E) :- !,
    (   atom(N), integer(A) -> E = modify(N/A) ; E = modify(computed) ).
sf_modifies(dynamic(S), E) :- !,
    sf_specs(S, Ks),
    (   Ks == [] -> E = modify(computed) ; member(K, Ks), E = modify(K) ).
sf_modifies(G, E) :- arg(1, G, C), sf_target(C, E).

sf_target(C, modify(computed)) :- var(C), !.
sf_target((H :- _), E) :- !, sf_target(H, E).
sf_target(_:C, E) :- !, sf_target(C, E).
sf_target(C, modify(N/A)) :- callable(C), !, functor(C, N, A).
sf_target(_, modify(computed)).

sf_loads(consult(_)).
sf_loads(load_files(_)).
sf_loads(load_files(_, _)).
sf_loads([_|_]).

%% ---- meta-predicates -------------------------------------------------------

%% THE BUILTINS THAT CALL A GOAL, each argument that is one as I-K: the
%% I-th argument is called with K more arguments, or translated as a
%% grammar body (dcg).
sf_meta(call, A, [1-K]) :- A >= 1, K is A - 1.
sf_meta(findall, 3, [2-0]).
sf_meta(findall, 4, [2-0]).
sf_meta(bagof, 3, [2-0]).
sf_meta(setof, 3, [2-0]).
sf_meta(aggregate_all, 3, [2-0]).
sf_meta(aggregate_all, 4, [3-0]).
sf_meta(aggregate, 3, [2-0]).
sf_meta(aggregate, 4, [3-0]).
sf_meta(forall, 2, [1-0, 2-0]).
sf_meta(foreach, 2, [1-0, 2-0]).
sf_meta(once, 1, [1-0]).
sf_meta(ignore, 1, [1-0]).
sf_meta(not, 1, [1-0]).
sf_meta(catch, 3, [1-0, 3-0]).
sf_meta(call_cleanup, 2, [1-0, 2-0]).
sf_meta(setup_call_cleanup, 3, [1-0, 2-0, 3-0]).
sf_meta(call_metered, 4, [1-0]).
sf_meta(call_limited, 3, [1-0]).
sf_meta(with_output_to, 2, [2-0]).
sf_meta(with_mutex, 2, [2-0]).
sf_meta(zigurat_call, 2, [2-0]).
sf_meta(zigurat_call, 3, [2-0]).
sf_meta(apply, 2, [1-0]).
sf_meta(maplist, A, [1-K]) :- A >= 2, A =< 7, K is A - 1.
sf_meta(foldl, A, [1-K]) :- A >= 4, A =< 7, K is A - 1.
sf_meta(scanl, A, [1-K]) :- A >= 4, A =< 7, K is A - 1.
sf_meta(include, 3, [1-1]).
sf_meta(exclude, 3, [1-1]).
sf_meta(partition, 4, [1-1]).
sf_meta(partition, 5, [1-2]).
sf_meta(convlist, 3, [1-2]).
sf_meta(max_member, 3, [1-2]).
sf_meta(min_member, 3, [1-2]).
sf_meta(predsort, 3, [1-3]).
sf_meta(phrase, 2, [1-dcg]).
sf_meta(phrase, 3, [1-dcg]).
sf_meta(call_dcg, 3, [1-dcg]).

%% the specs for a call of N/A in file F: the builtin's, else what the
%% fixpoint found for the file's own predicate, else for a library's
sf_meta_spec(_, N, A, Specs) :- sf_meta(N, A, Specs), !.
sf_meta_spec(F, N, A, Specs) :-
    sf_defined(F, N/A), !,
    findall(I-K, sf_meta_inf(F, N/A, I, K), Specs), Specs \== [].
sf_meta_spec(_, N, A, Specs) :-
    sf_library_file(N/A, LF), !,
    findall(I-K, sf_meta_inf(LF, N/A, I, K), Specs), Specs \== [].

%% THE FIXPOINT: a clause that hands an argument of its own head to a goal
%% position makes that argument one, with the same number of arguments
%% added; repeat until a pass finds nothing new.
sf_infer :-
    findall(m(F, Key, J, K), sf_new_meta(F, Key, J, K), New0),
    sort(New0, New),
    (   New == [] -> true
    ;   forall(member(m(F, Key, J, K), New), assertz(sf_meta_inf(F, Key, J, K))),
        sf_infer
    ).

sf_new_meta(F, Key, J, K) :-
    sf_cl(F, Key, H, B),
    Key \== '$load'/0,
    sf_goal_position(F, B, X, K),
    var(X),
    sf_head_arg(H, X, J),
    \+ sf_meta_inf(F, Key, J, K).

%% every goal position of a body, as the term in it and the arguments it
%% is called with: the body's own goals with 0, and each meta argument
sf_goal_position(_, G, G, 0) :- var(G), !.
sf_goal_position(F, _:G, X, K) :- !, sf_goal_position(F, G, X, K).
sf_goal_position(F, G, X, K) :- sf_control(G, Gs), !, member(G1, Gs), sf_goal_position(F, G1, X, K).
sf_goal_position(F, G, X, K) :-
    callable(G),
    functor(G, N, A),
    sf_meta_spec(F, N, A, Specs),
    member(I-K0, Specs), integer(K0),
    arg(I, G, Y),
    (   var(Y) -> X = Y, K = K0
    ;   K0 =:= 0, sf_goal_position(F, Y, X, K)
    ).

sf_head_arg(H, X, J) :-
    functor(H, _, A),
    between(1, A, J),
    arg(J, H, Y), Y == X, !.

%% ---- the events, once ------------------------------------------------------

sf_events :-
    forall(sf_cl(F, Key, H, B),
           forall(sf_event(F, H, B, E), assertz(sf_ev(F, Key, E)))).

%% TABLES KEYED ON THE NAME. sf_cl/4 and sf_ev/3 hold a predicate as N/A,
%% and every such key has the one functor `/', which no argument index
%% can split: a lookup by file and key walked the file's every clause, and
%% that was most of the run. These put the name first.
sf_index :-
    findall(F-N-A, sf_cl(F, N/A, _, _), L0),
    msort(L0, L),
    sf_count_runs(L, C),
    forall(member((F-N-A)-Cn, C), ( assertz(sf_def(N, A, F)), assertz(sf_ncl(N, A, F, Cn)) )).

sf_edges :-
    findall(e(N, A, F, K2), sf_ev(F, N/A, call(K2)), Es0),
    sort(Es0, Es),
    forall(member(e(N, A, F, K2), Es), assertz(sf_out(N, A, F, K2))).

sf_defined(F, N/A) :- sf_def(N, A, F), !.

%% a file of library/ that defines it, from a table made once
%% (sf_library_index/0): asked for every call, a walk over the files
%% was most of the run
sf_library_file(Key, LF) :- sf_libdef(Key, LF), !.

sf_library_index :-
    findall(K-LF, ( sf_file(LF, library), sf_cl(LF, K, _, _) ), Ps0),
    sort(Ps0, Ps),
    forall(member(K-LF, Ps), ( sf_libdef(K, _) -> true ; assertz(sf_libdef(K, LF)) )).

%% what a call of N/A from file F reaches
sf_kind(F, N/A, local) :- sf_defined(F, N/A), !.
sf_kind(_, N/A, builtin) :- ( cl_t1c(N, A, _) ; cl_t1c(N, -1, _) ), !.
sf_kind(_, N/A, library) :- cl_t1p(N, A, _), !.
sf_kind(_, N/A, library) :- ( cl_t2c(_, N, A) ; cl_t2c(_, N, -1) ; cl_t2p(_, N, A) ), !.
sf_kind(_, Key, library) :- sf_library_file(Key, _), !.
sf_kind(F, Key, asserted) :- ( sf_mod(F, Key) ; sf_declared(F, Key) ), !.
sf_kind(_, _, unresolved).

%% ---- what is fixed ----------------------------------------------------------

%% WHAT EACH FILE CHANGES, read off its events once: the heads it names,
%% and whether it changes something it cannot name or consults
sf_changes :-
    findall(F-K, ( sf_ev(F, _, modify(K)), K \== computed ), M0),
    sort(M0, M),
    forall(member(F-K, M), assertz(sf_mod(F, K))),
    findall(F, ( sf_ev(F, _, E), ( E == modify(computed) ; E == load ) ), U0),
    sort(U0, U),
    forall(member(F, U), assertz(sf_unknown(F))).

%% the file changes what it cannot name, or consults while it runs
sf_unknown_change(F) :- sf_unknown(F).

%% a predicate whose clauses the file can change by name
sf_changed(F, Key) :- sf_declared(F, Key), !.
sf_changed(F, Key) :- sf_mod(F, Key), !.

%% FIXED, read two ways: a change the file cannot name may reach any of
%% its predicates (sf_fixed/2, the count a compiler could rely on), or
%% only the ones it does not define -- the data it builds and asserts,
%% which is what the translator's turn out to be (sf_fixed_named/2)
sf_fixed(F, Key) :- \+ sf_unknown_change(F), \+ sf_changed(F, Key).

sf_fixed_named(F, Key) :- \+ sf_changed(F, Key).

%% the predicates of a set of segments, as F-Key, the pseudo '$load'/0 not
%% among them
sf_preds(Segs, Ps) :-
    findall(F-Key, ( member(S, Segs), sf_file(F, S), sf_cl(F, Key, _, _), Key \== '$load'/0 ), Ps0),
    sort(Ps0, Ps).

sf_roots(F, Roots) :-
    findall(K, ( K = '$load'/0, sf_defined(F, K)
               ; K = main/0, sf_defined(F, K)
               ; sf_export(F, K), sf_defined(F, K) ), R0),
    sort(R0, R1),
    (   R1 == []
    ->  findall(K, sf_cl(F, K, _, _), R2), sort(R2, Roots)
    ;   Roots = R1
    ).

sf_reach(F, Reached) :-
    sf_roots(F, Roots),
    sf_reach_(F, Roots, [], Reached).

sf_reach_(_, [], Seen, Seen).
sf_reach_(F, [K|Ks], Seen, R) :-
    (   ord_memberchk(K, Seen) -> sf_reach_(F, Ks, Seen, R)
    ;   ord_add_element(Seen, K, Seen1),
        K = N/A,
        findall(K2, ( sf_out(N, A, F, K2), sf_defined(F, K2) ), Next),
        append(Next, Ks, Ks1),
        sf_reach_(F, Ks1, Seen1, R)
    ).

%% ---- the report --------------------------------------------------------------

sf_report(Segs) :-
    atomic_list_concat(Segs, ' + ', Name),
    findall(F, ( member(S, Segs), sf_file(F, S) ), Fs),
    length(Fs, NF),
    findall(F, ( member(F, Fs), sf_unread(F, _) ), U0), sort(U0, U), length(U, NU),
    sf_preds(Segs, Ps), length(Ps, NP),
    sf_nclauses(Ps, NC),
    findall(F-K, ( member(F-K, Ps), sf_fixed(F, K) ), Fx), length(Fx, NFx),
    sf_nclauses(Fx, NFxC),
    findall(F-K, ( member(F-K, Ps), sf_fixed_named(F, K) ), FxN), length(FxN, NFxN),
    findall(F-K, ( member(F-K, Ps), \+ sf_unknown_change(F), sf_changed(F, K) ), Ch), length(Ch, NCh),
    findall(F-K, ( member(F-K, Ch), sf_declared(F, K) ), ChD), length(ChD, NChD),
    findall(F-K, ( member(F-K, Ps), sf_unknown_change(F) ), Un), length(Un, NUn),
    findall(F, ( member(F, Fs), sf_unknown_change(F) ), UF0), sort(UF0, UF), length(UF, NUF),
    findall(F-K, ( member(F, Fs), sf_reach(F, R), member(K, R), K \== '$load'/0 ), Re), length(Re, NRe),
    findall(x, ( member(F-K, Re), sf_fixed(F, K) ), ReF), length(ReF, NReF),
    findall(F, ( member(F, Fs), \+ sf_defined(F, '$load'/0), \+ sf_defined(F, main/0),
                 \+ ( sf_export(F, K), sf_defined(F, K) ) ), NoR), length(NoR, NNoR),
    sf_calls(Fs, Calls),
    format("~n== ~w: ~w files (~w that will not read to the end), ~w predicates, ~w clauses~n",
           [Name, NF, NU, NP, NC]),
    sf_pct(NFx, NP, P1), sf_pct(NFxC, NC, P2),
    format("   fixed while it runs: ~w predicates (~w %), ~w clauses (~w %)~n", [NFx, P1, NFxC, P2]),
    sf_pct(NFxN, NP, P0),
    format("   fixed if an unnamed change reaches only data: ~w predicates (~w %)~n", [NFxN, P0]),
    format("   changed by name: ~w predicates (~w declared dynamic)~n", [NCh, NChD]),
    format("   in a file that changes what it cannot name, or consults: ~w predicates in ~w files~n",
           [NUn, NUF]),
    sf_pct(NRe, NP, P3), sf_pct(NReF, NRe, P4),
    format("   reached from the roots by literal calls: ~w (~w %), fixed ~w (~w %)~n", [NRe, P3, NReF, P4]),
    format("   files with no root (every predicate one): ~w~n", [NNoR]),
    sf_calls_line(Calls).

sf_nclauses(Ps, N) :-
    findall(C, ( member(F-(Nm/A), Ps), sf_ncl(Nm, A, F, C) ), Cs),
    sum_list(Cs, N).

sf_calls(Fs, Counts) :-
    findall(Kind, ( member(F, Fs), sf_ev(F, _, E), sf_event_kind(F, E, Kind) ), Ks0),
    msort(Ks0, Ks),
    sf_count_runs(Ks, Counts).

sf_event_kind(F, call(Key), Kind) :- !, sf_kind(F, Key, Kind).
sf_event_kind(_, closure, closure) :- !.
sf_event_kind(_, computed, computed) :- !.
sf_event_kind(_, modify(computed), modify_unnamed) :- !.
sf_event_kind(_, modify(_), modify_named) :- !.
sf_event_kind(_, load, load).

sf_count_runs([], []).
sf_count_runs([K|Ks], [K-N|Rest]) :-
    sf_take_same(K, Ks, 1, N, Ks1),
    sf_count_runs(Ks1, Rest).

sf_take_same(K, [K1|Ks], N0, N, Rest) :- K1 == K, !, N1 is N0 + 1, sf_take_same(K, Ks, N1, N, Rest).
sf_take_same(_, Ks, N, N, Ks).

sf_calls_line(Counts) :-
    sf_call_kinds(Kinds),
    findall(N, ( member(K-N, Counts), memberchk(K, Kinds) ), Ns),
    sum_list(Ns, Total),
    format("   calls: ~w --", [Total]),
    forall(member(K, Kinds),
           ( ( memberchk(K-N, Counts) -> true ; N = 0 ),
             sf_pct(N, Total, P),
             format(" ~w ~w (~w %)", [K, N, P]) )),
    nl,
    forall(member(K, [modify_named, modify_unnamed, load]),
           ( ( memberchk(K-N, Counts) -> true ; N = 0 ), format("   ~w: ~w~n", [K, N]) )).

%% what a call can reach, in the order the report gives them: ASSERTED is
%% a predicate its file changes by name and defines no clause of
sf_call_kinds([local, builtin, library, asserted, closure, computed, unresolved]).

sf_pct(_, 0, '-') :- !.
sf_pct(N, D, P) :- X is 100 * N / D, format(atom(P), "~1f", [X]).

%% the files that change what they cannot name, or consult, by segment
sf_report_files(Segs) :-
    format("~nfiles that change clauses they cannot name, or consult while they run:~n"),
    forall(( member(S, Segs), sf_file(F, S), sf_unknown_change(F) ),
           ( findall(E, ( sf_ev(F, _, E), ( E == modify(computed) ; E == load ) ), Es0),
             msort(Es0, Es), sf_count_runs(Es, C),
             format("   ~w ~w~n", [F, C]) )),
    format("heads changed by a file that does not define them:~n"),
    forall(( member(S, Segs), sf_file(F, S),
             findall(K, ( sf_ev(F, _, modify(K)), K \== computed, \+ sf_defined(F, K) ), K0),
             K0 \== [], sort(K0, Ks) ),
           format("   ~w ~w~n", [F, Ks])),
    format("files that would not read to the end:~n"),
    forall(( member(S, Segs), sf_file(F, S), sf_unread(F, E) ), format("   ~w ~q~n", [F, E])).

sf_report_unresolved(Segs) :-
    findall(Key, ( member(S, Segs), sf_file(F, S), sf_ev(F, _, call(Key)),
                   sf_kind(F, Key, Kind), Kind == unresolved ), U0),
    msort(U0, U), sf_count_runs(U, C),
    findall(N-K, member(K-N, C), NK0), msort(NK0, NK1), reverse(NK1, NK),
    length(NK, NN),
    format("unresolved names: ~w, the most called:~n", [NN]),
    forall(( nth1(I, NK, N-K), I =< 25 ), format("   ~w ~w~n", [K, N])).
