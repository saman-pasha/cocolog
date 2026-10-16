%% library(flow/chart), part: reading a program -- its clauses with their
%% variable names, and the names its comments and headers give.

:- use_module(library(stream)).

%% ======================================================================
%% The tables: what the engine and the modules answer in C
%% ======================================================================
%%
%% library/flow/tables.pl is GENERATED, by tools/flow/tables.pl at build
%% time (`make modules', or sh tools/flow/build.sh), and git ignores it:
%%
%%     flow_t_c(Name, Arity, File)           a C builtin of the engine
%%     flow_t_lib(Name, Arity, Lib, File)    a predicate a library's clauses define
%%     flow_t_portal(Module, Name, Arity, CFunction, File, Line, Modes, Names)
%%                                           a module's C function, and its row

:- catch(use_module(library(flow/tables)), _, true).

flow_tables :-
    catch(flow_t_c(_, _, _), error(existence_error(_, _), _), fail), !.
flow_tables :-
    throw(error(existence_error(flow_tables, 'library/flow/tables.pl'),
                context(flow_graph/3, 'not built: make modules writes it (sh tools/flow/build.sh)'))).

%% ======================================================================
%% The program, read with its variable names and where each thing stands
%% ======================================================================
%%
%% Each clause's text is cut out of the file by stream_position/2 -- the
%% positions after two reads are contiguous, so a clause's text runs from
%% where the last one ended, its comments included -- and its goals are
%% found in that text in reading order, which is the order the analysis
%% visits them in, by a small tokenizer that steps over quoted atoms,
%% strings, comments and 0'c. Each goal found is wrapped '$at'(Goal, Info)
%% for the analysis to carry into its node. A goal the scan cannot place is
%% left as it is: a position is help, never a reason to refuse a program.
%% The scan was written when read_term/3 ignored term_position and
%% subterm_positions; it answers both since 1.10.7, and moving the scan
%% onto them is a change to the chart, not made yet.
%%
%% A clause is cl(Head, Body, Names, Info), Info holding file(F), at(Line,
%% Col) and text(Codes), and `dcg' for a grammar rule.
%%
%% Prog maps each Name/Arity to its clauses -- or to dyn(Clauses) when the
%% file declares it dynamic, whether or not it holds a clause of it: what a
%% dynamic predicate answers is made as the program runs. One lookup says
%% both, and it is the one every goal of the program's own costs anyway.

flow_read_source(File, Prog) :-
    read_file_to_codes(File, Codes),
    open(File, read, S),
    flow_read_terms(S, File, Codes, 0, 1, 1, Pairs, Dyn0),
    close(S),
    keysort(Pairs, Sorted),
    flow_group(Sorted, Grouped),
    list_to_assoc(Grouped, Prog0),
    sort(Dyn0, Dyn),
    flow_mark_dynamic(Dyn, Prog0, Prog).

flow_mark_dynamic([], Prog, Prog).
flow_mark_dynamic([K|Ks], Prog0, Prog) :-
    (   get_assoc(K, Prog0, Cls) -> true ; Cls = [] ),
    put_assoc(K, Prog0, dyn(Cls), Prog1),
    flow_mark_dynamic(Ks, Prog1, Prog).

%% Rest is the file from byte Off on, which is line L, column K
flow_read_terms(S, File, Rest, Off, L, K, Pairs, Dyn) :-
    read_term(S, T, [variable_names(Vs)]),
    stream_position(S, Off1),
    N is Off1 - Off,
    flow_split_at(Rest, N, Text0, Rest1),
    flow_advance(Text0, L, K, L1, K1),
    (   T == end_of_file
    ->  Pairs = [], Dyn = []
    ;   flow_skip_layout(Text0, L, K, Text, LS, KS),
        (   catch(flow_source_clause(T, Vs, File, Text, LS, KS, Pair), _, fail)
        ->  Pairs = [Pair|Pairs1]
        ;   Pairs = Pairs1
        ),
        (   nonvar(T), T = (:- D), nonvar(D), D = dynamic(Spec)
        ->  flow_dynamic_keys(Spec, Ks), append(Ks, Dyn1, Dyn)
        ;   Dyn = Dyn1
        ),
        flow_read_terms(S, File, Rest1, Off1, L1, K1, Pairs1, Dyn1)
    ).

%% dynamic p/1, (p/1, q/2), [p/1, q/2], m:p/1 -- `:- dynamic p/1, q/2.'
%% reads as dynamic((p/1, q/2))
flow_dynamic_keys(V, []) :- var(V), !.
flow_dynamic_keys((A, B), Ks) :- !,
    flow_dynamic_keys(A, Ka),
    flow_dynamic_keys(B, Kb),
    append(Ka, Kb, Ks).
flow_dynamic_keys([], []) :- !.
flow_dynamic_keys([S|Ss], Ks) :- !,
    flow_dynamic_keys(S, K1),
    flow_dynamic_keys(Ss, K2),
    append(K1, K2, Ks).
flow_dynamic_keys(_:S, Ks) :- !,
    flow_dynamic_keys(S, Ks).
flow_dynamic_keys(N/A, [N/A]) :- atom(N), integer(A), !.
flow_dynamic_keys(_, []).

%% ======================================================================
%% What the program declares as it runs, and the files the chart reads
%% ======================================================================
%%
%% A TABLE MAY BE DECLARED WHERE A CLAUSE RUNS rather than by a directive
%% (1.11.4, from cicili-lang's report): `dynamic(t/2)' in a body,
%% `assertz(t(K, V))', or a declarer of the program's own --
%% `reset(F/A) :- abolish(F/A), dynamic(F/A)' -- called with the name
%% written out, `reset(t/2)'. Each such goal declares what it names in the
%% files the chart reads: the source, the files load(Files) names, the
%% Prolog libraries the Prolog halves of modules(Files) load, and the files
%% the directives of each of those load in turn (use_module/1,2 and
%% ensure_loaded/1, found on the library path as the engine finds them;
%% cocolog's own libraries are not the program's, and a compiled module has
%% no clauses to read). A call the chart would otherwise take for unknown is
%% then a dynamic predicate's, which fails while nothing is asserted, as if
%% a directive had declared it (flow_mark_declared/4). One level of declarer
%% is followed: a clause whose dynamic/1, or whose assert of a variable,
%% takes its argument from the head declares what each call of it names.
%% 1221 of the 1291 findings of cicili-lang's ccl_cpp.pl were calls of
%% tables declared that way.
%%
%% flow_scan(+Src, +Loads, +ModLoads, -Scan): Scan is scan(Keys, Defs),
%% the keys declared, sorted, and Name/Arity-Files-Count for each
%% flow_-named predicate the files give clauses of, which
%% flow_clash_check/1 holds to the store.

flow_scan(Src, Loads, ModLoads, scan(Keys, Defs)) :-
    absolute_file_name(Src, SrcA),
    findall(P, ( member(F, Loads), flow_spec_file(F, P, _) ), LPs),
    findall(P, ( member(F, ModLoads), flow_spec_file(F, P, own) ), MPs),
    append([[SrcA], LPs, MPs], Roots),
    flow_scan_files(Roots, [], Cls),
    findall(K, ( member(c(_, _, _, B), Cls), flow_body_goal(B, G), flow_goal_declares(G, Ks),
                 member(K, Ks) ), K1),
    findall(d(K, H, Sp), ( member(c(K, _, H, B), Cls), H \== none,
                           flow_body_goal(B, G), flow_goal_declarer(G, H, Sp) ), Decls),
    (   Decls == [] -> K2 = []
    ;   findall(K, ( member(c(_, _, _, B), Cls), flow_body_goal(B, G), callable(G),
                     functor(G, N, A), memberchk(d(N/A, _, _), Decls),
                     member(d(N/A, H0, Sp0), Decls),
                     copy_term(G, G1), copy_term(H0-Sp0, G1-Sp1),
                     flow_spec_keys(Sp1, Ks), member(K, Ks) ), K2)
    ),
    append(K1, K2, Keys0),
    sort(Keys0, Keys),
    findall(K-P, ( member(c(K, P, _, _), Cls), K = N/_, atom_concat(flow_, _, N) ), KPs0),
    msort(KPs0, KPs),
    flow_group(KPs, Grouped),
    findall(K-Fs-C, ( member(K-Ps, Grouped), length(Ps, C), sort(Ps, Fs) ), Defs).

%% each file once, and the files its directives load after it
flow_scan_files([], _, []).
flow_scan_files([P|Ps], Seen, Cls) :-
    (   memberchk(P, Seen)
    ->  flow_scan_files(Ps, Seen, Cls)
    ;   flow_scan_file(P, Cls0, Specs),
        findall(Q, ( member(S, Specs), flow_spec_file(S, Q, own) ), Qs),
        append(Ps, Qs, Ps1),
        append(Cls0, Cls1, Cls),
        flow_scan_files(Ps1, [P|Seen], Cls1)
    ).

%% a file's clauses, c(Key, File, Head, Body), and what its directives load;
%% a term the reader refuses ends the file there, as it ends a consult
flow_scan_file(P, Cls, Specs) :-
    catch(open(P, read, S), _, fail), !,
    flow_scan_terms(S, P, Cls, Specs),
    close(S).
flow_scan_file(_, [], []).

flow_scan_terms(S, P, Cls, Specs) :-
    catch(read_term(S, T, []), _, T = end_of_file),
    (   T == end_of_file
    ->  Cls = [], Specs = []
    ;   nonvar(T), T = (:- D)
    ->  Cls = Cls1,
        (   nonvar(D), flow_load_specs(D, Ss) -> append(Ss, Specs1, Specs) ; Specs = Specs1 ),
        flow_scan_terms(S, P, Cls1, Specs1)
    ;   flow_scan_clause(T, P, C)
    ->  Cls = [C|Cls1],
        flow_scan_terms(S, P, Cls1, Specs)
    ;   flow_scan_terms(S, P, Cls, Specs)
    ).

flow_load_specs(use_module(X), Ss) :- flow_spec_list(X, Ss).
flow_load_specs(use_module(X, _), Ss) :- flow_spec_list(X, Ss).
flow_load_specs(ensure_loaded(X), Ss) :- flow_spec_list(X, Ss).

flow_spec_list(X, []) :- var(X), !.
flow_spec_list(Xs, Xs) :- is_list(Xs), !.
flow_spec_list(X, [X]).

%% a grammar rule's goals are its {}/1 parts; its head is not looked at
flow_scan_clause(T, P, c(K, P, H, B)) :-
    flow_clause_key(T, K),
    (   T = (_ --> B0) -> H = none, B = '$flow_dcg'(B0)
    ;   T = (H :- B) -> true
    ;   H = T, B = true
    ).

%% WHERE THE ENGINE FINDS A FILE use_module/1 names (lb_find in
%% lib/library.cicili): library(Name) on $COCOLOG_LIBRARY, then ./library,
%% then beside the binary (library/, lib/swipl/), then ./lib/swipl -- in
%% each a compiled module (.so) before a .pl, and a .so has no clauses to
%% read; a path as written, then with .pl. Whose is shipped for a file of
%% cocolog's own libraries, own for any other.
flow_spec_file(library(L), Path, Whose) :- !,
    flow_lib_spec_name(L, Name),
    flow_lib_dirs(Dirs),
    member(d(Dir, Exts), Dirs),
    member(Ext, Exts),
    atomic_list_concat([Dir, '/', Name, Ext], P),
    exists_file(P), !,
    Ext == '.pl',
    absolute_file_name(P, Path),
    flow_whose(Path, Whose).
flow_spec_file(F, Path, Whose) :-
    atom(F),
    (   exists_file(F) -> P = F
    ;   atom_concat(F, '.pl', P), exists_file(P)
    ),
    \+ atom_concat(_, '.so', P),
    absolute_file_name(P, Path),
    flow_whose(Path, Whose).

flow_lib_spec_name(L, L) :- atom(L), !.
flow_lib_spec_name(D/N, Name) :-
    flow_lib_spec_name(D, DN), atom(N),
    atomic_list_concat([DN, '/', N], Name).

flow_lib_dirs(Dirs) :-
    (   getenv('COCOLOG_LIBRARY', Env), Env \== ''
    ->  atomic_list_concat(Es, ':', Env),
        findall(d(E, ['.so', '.pl']), ( member(E, Es), E \== '' ), D1)
    ;   D1 = []
    ),
    (   flow_exedir(X)
    ->  atomic_list_concat([X, '/library'], XL),
        atomic_list_concat([X, '/lib/swipl'], XS),
        D3 = [d(XL, ['.so', '.pl']), d(XS, ['.pl'])]
    ;   D3 = []
    ),
    append([D1, [d(library, ['.so', '.pl'])], D3, [d('lib/swipl', ['.pl'])]], Dirs).

flow_exedir(X) :-
    current_prolog_flag(executable, E),
    absolute_file_name(E, EA),
    file_directory_name(EA, X).

flow_whose(Path, Whose) :-
    (   flow_exedir(X),
        (   atomic_list_concat([X, '/library/'], Pre)
        ;   atomic_list_concat([X, '/lib/swipl/'], Pre)
        ),
        atom_concat(Pre, _, Path)
    ->  Whose = shipped
    ;   Whose = own
    ).

%% EACH GOAL A BODY CALLS, through the control constructs and the
%% meta-calls whose goal it writes
flow_body_goal(B, _) :- var(B), !, fail.
flow_body_goal('$flow_dcg'(B), G) :- !, flow_dcg_goal(B, G).
flow_body_goal((A, B), G) :- !, ( flow_body_goal(A, G) ; flow_body_goal(B, G) ).
flow_body_goal((A ; B), G) :- !, ( flow_body_goal(A, G) ; flow_body_goal(B, G) ).
flow_body_goal((A -> B), G) :- !, ( flow_body_goal(A, G) ; flow_body_goal(B, G) ).
flow_body_goal((A *-> B), G) :- !, ( flow_body_goal(A, G) ; flow_body_goal(B, G) ).
flow_body_goal(\+ A, G) :- !, flow_body_goal(A, G).
flow_body_goal(_:A, G) :- !, flow_body_goal(A, G).
flow_body_goal(B, G) :-
    (   G = B
    ;   flow_meta_arg(B, A), flow_body_goal(A, G)
    ).

flow_meta_arg(call(A), A).
flow_meta_arg(once(A), A).
flow_meta_arg(ignore(A), A).
flow_meta_arg(not(A), A).
flow_meta_arg(forall(A, _), A).
flow_meta_arg(forall(_, A), A).
flow_meta_arg(findall(_, A, _), A).
flow_meta_arg(findall(_, A, _, _), A).
flow_meta_arg(aggregate_all(_, A, _), A).
flow_meta_arg(catch(A, _, _), A).
flow_meta_arg(catch(_, _, A), A).
flow_meta_arg(with_output_to(_, A), A).
flow_meta_arg(with_mutex(_, A), A).
flow_meta_arg(setof(_, A, _), A).
flow_meta_arg(bagof(_, A, _), A).
flow_meta_arg(_^A, A).

flow_dcg_goal(B, _) :- var(B), !, fail.
flow_dcg_goal((A, B), G) :- !, ( flow_dcg_goal(A, G) ; flow_dcg_goal(B, G) ).
flow_dcg_goal((A ; B), G) :- !, ( flow_dcg_goal(A, G) ; flow_dcg_goal(B, G) ).
flow_dcg_goal((A -> B), G) :- !, ( flow_dcg_goal(A, G) ; flow_dcg_goal(B, G) ).
flow_dcg_goal(\+ A, G) :- !, flow_dcg_goal(A, G).
flow_dcg_goal({A}, G) :- flow_body_goal(A, G).

%% what a goal declares with its argument written out: dynamic/1's spec,
%% the head of an assert's clause
flow_goal_declares(dynamic(S), Ks) :- !,
    flow_dynamic_keys(S, Ks), Ks \== [].
flow_goal_declares(G, [K]) :-
    flow_assert_arg(G, C), nonvar(C),
    flow_asserted_key(C, K).

flow_assert_arg(assert(C), C).
flow_assert_arg(asserta(C), C).
flow_assert_arg(assertz(C), C).

flow_asserted_key(_:C, K) :- !, nonvar(C), flow_asserted_key(C, K).
flow_asserted_key((H :- _), K) :- !, nonvar(H), flow_asserted_key(H, K).
flow_asserted_key(H, N/A) :- callable(H), functor(H, N, A).

%% a goal of a clause that declares what the clause's head is given:
%% dynamic/1 of a spec, or an assert of a clause, not written out but
%% sharing a variable with the head
flow_goal_declarer(G, H, Sp) :-
    (   G = dynamic(S), flow_dynamic_keys(S, []), Sp = dyn(S)
    ;   flow_assert_arg(G, C), ( var(C) ; C = (V :- _), var(V) ), Sp = asr(C)
    ),
    term_variables(Sp, SVs),
    term_variables(H, HVs),
    member(V1, SVs), flow_var_in(V1, HVs), !.

flow_spec_keys(dyn(S), Ks) :- flow_dynamic_keys(S, Ks).
flow_spec_keys(asr(C), [K]) :- nonvar(C), flow_asserted_key(C, K).

%% each key declared as the program runs that the chart would otherwise
%% take for unknown: a dynamic predicate with no clauses of the file's
flow_mark_declared([], _, Prog, Prog).
flow_mark_declared([N/A|Ks], How, Prog0, Prog) :-
    functor(G, N, A),
    (   \+ get_assoc(N/A, Prog0, _),
        flow_kind(G, ctx(Prog0, none, How), unknown)
    ->  put_assoc(N/A, Prog0, dyn([]), Prog1)
    ;   Prog1 = Prog0
    ),
    flow_mark_declared(Ks, How, Prog1, Prog).

%% A CLAUSE OF THE CHART'S OWN, from the program (1.11.4, from
%% cicili-lang's report): a file of the program's that defines a predicate
%% this library defines too -- a helper named flow_trim/2 -- joins the
%% library's clauses, and the chart fails far from the cause (a type error
%% from atom_codes/2 in the signature reader). It is refused, by name,
%% before anything is analysed. Through 1.11.4 the store was held to the
%% chart's own files, and a file the program loaded itself -- by an
%% ensure_loaded/1 in the query, before the chart was asked for -- joined
%% unseen (1.11.7, from cicili-lang's report). Now the store is held to the
%% library: each part of it (a file beside chart.pl on the library path)
%% is read once, for how many clauses it gives each of its flow_
%% predicates, and a part the store holds at least that many of each is
%% loaded; a predicate of a loaded part with more clauses in the store than
%% its file gives it is refused -- naming the chart's files that give it
%% clauses, or saying the program loaded them itself. A flow_ predicate of
%% the program's that the library does not have is the program's to name.
%% The tables the chart reads are open to a program -- flow_t_portal/8 rows
%% for a module of its own (modules(Files) writes them), flow_mode/4 lines
%% for a builtin -- and their rows are not refused.
flow_clash_check(scan(_, Defs)) :-
    flow_own_counts(Parts),
    (   member(part(Lib, KLs), Parts),
        flow_part_loaded(KLs),
        member(N/A-L, KLs),
        flow_store_count(N/A, T),
        T > L
    ->  (   memberchk(N/A-[F|_]-_, Defs)
        ->  format(atom(Msg), '~q/~w is library(~w)''s own predicate, and ~w gives it clauses of its own, which join the library''s: the chart would fail far from here -- name the program''s another way',
                   [N, A, Lib, F])
        ;   X is T - L,
            ( X =:= 1 -> Cl = clause ; Cl = clauses ),
            format(atom(Msg), '~q/~w is library(~w)''s own predicate, and the program gave it ~d ~w of its own from a file it loaded itself -- none the chart reads -- which join the library''s: the chart would fail far from here -- name the program''s another way',
                   [N, A, Lib, X, Cl])
        ),
        throw(error(permission_error(modify, flow_procedure, N/A), context(flow_graph/3, Msg)))
    ;   true
    ).

flow_open_table(N, _) :- atom_concat(flow_t_, _, N), !.
flow_open_table(flow_mode, 4).
flow_open_table(flow_raises_unbound, 4).

%% the clauses the store holds of a predicate: 0 for one it does not have
flow_store_count(N/A, T) :-
    functor(H, N, A),
    (   catch(predicate_property(H, number_of_clauses(T0)), _, fail) -> T = T0 ; T = 0 ).

flow_part_loaded(KLs) :-
    forall(member(K-L, KLs), ( flow_store_count(K, T), T >= L )).

%% each part of the library -- each file in the directory chart.pl is
%% found in -- with the clauses its file gives each of its flow_ predicates
%% (part(Lib, [Name/Arity-Count, ...]), Lib flow/chart or flow/debug), read
%% once a process: twenty files, 0.04 s
flow_own_counts(Parts) :-
    catch(nb_getval('$flow_own_counts', Parts), _, fail), !.
flow_own_counts(Parts) :-
    (   flow_spec_file(library(flow/chart), CP, _)
    ->  file_directory_name(CP, Dir),
        atom_concat(Dir, '/*.pl', Pat),
        expand_file_name(Pat, Fs)
    ;   Fs = []
    ),
    findall(part(Lib, KLs),
            ( member(F, Fs),
              flow_scan_file(F, Cls, _),
              findall(K-x, ( member(c(K, _, _, _), Cls), K = N/A, atom_concat(flow_, _, N),
                             \+ flow_open_table(N, A) ), KXs0),
              KXs0 \== [],
              msort(KXs0, KXs),
              flow_group(KXs, Grouped),
              findall(K-L, ( member(K-Xs, Grouped), length(Xs, L) ), KLs),
              file_base_name(F, B),
              (   ( atom_concat(dbg, _, B) ; B == 'debug.pl' ) -> Lib = flow/debug ; Lib = flow/chart )
            ),
            Parts),
    nb_setval('$flow_own_counts', Parts).

%% MODULES OUT OF THE TREE (1.11.4, from cicili-lang's report):
%% modules(Files) names a module's Cicili source, read as
%% tools/flow/tables.pl reads the tree's own -- each ("name" Arity c_fun)
%% row of its tables a C predicate, a portal, its modes from the row's
%% comment, else from the header's signature list (`;;;;   name(+A, -B)'),
%% else `?'; a name its hand-written dispatcher compares
%% (`(strcmp name "x")') one at each arity the header documents, or at any.
%% The rows are flow_t_portal/8's, written to a file and loaded beside the
%% generated ones for the rest of the process, as load(Files) is; a file of
%% such rows given to load(Files) does the same by hand. Mod is the file's
%% name less `.cicili' (and a leading `coco-'), and Specs the libraries its
%% Prolog half loads, read for their declarations.
flow_module_portals(File, Specs) :-
    (   exists_file(File) -> true
    ;   throw(error(existence_error(flow_module, File), flow_graph/3))
    ),
    flow_module_rows(File, Mod, Rows, Specs),
    (   Rows == [] -> true
    ;   catch(flow_t_portal(Mod, _, _, _, File, _, _, _), _, fail) -> true
    ;   tmp_file(flow_portals, T0),
        atom_concat(T0, '.pl', T),
        open(T, write, S),
        forall(member(R, Rows), format(S, "~q.~n", [R])),
        close(S),
        use_module(T),
        catch(delete_file(T), _, true)
    ).

flow_module_rows(File, Mod, Rows, Specs) :-
    read_file_to_codes(File, Cs),
    flow_lines(Cs, 1, Lines),
    flow_doc_sigs(File, Docs),
    file_base_name(File, Base),
    file_name_extension(Mod0, _, Base),
    (   atom_concat('coco-', Mod, Mod0) -> true ; Mod = Mod0 ),
    findall(N/A-r(CFun, Line, Sig), ( member(Line-L, Lines), flow_dispatch_row(L, N, A, CFun, Sig) ), Rs0),
    flow_first_per_key(Rs0, [], Rs),
    findall(flow_t_portal(Mod, N, A, CFun, File, Line, Ms, Ns),
            ( member(N/A-r(CFun, Line, Sig), Rs), flow_row_modes(Sig, N, A, Docs, Ms, Ns) ), P1),
    findall(N, ( member(_-L, Lines), flow_strcmp_name(L, N), \+ memberchk(N/_-_, Rs) ), HNs0),
    sort(HNs0, HNs),
    assoc_to_list(Docs, DL),
    findall(R, ( member(N, HNs), flow_hand_row(N, Mod, File, DL, R) ), P2),
    append(P1, P2, Rows),
    findall(Sp, flow_half_loads(Cs, Sp), Specs).

%% ("NAME"  ARITY  c_function)  ; signature -- cocolint's first shape: any
%% name, an arity, then a C name
flow_dispatch_row(L, N, A, CFun, Sig) :-
    append(_, [40, 34|R0], L),
    flow_until(R0, 34, NCs, R1),
    NCs \== [], \+ memberchk(10, NCs),
    flow_skip_sp(R1, R2),
    flow_digit_run(R2, DCs, R3),
    DCs \== [],
    flow_skip_sp(R3, [C|R4]),
    ( C >= 0'a, C =< 0'z ; C =:= 0'_ ), !,
    flow_c_name([C|R4], FCs, R5),
    atom_codes(N, NCs),
    number_codes(A, DCs),
    atom_codes(CFun, FCs),
    (   append(_, [59|R6], R5) -> flow_drop_pct(R6, R7), flow_trim(R7, SCs), atom_codes(Sig, SCs)
    ;   Sig = none
    ).

flow_digit_run([C|Cs], [C|Ds], R) :- C >= 0'0, C =< 0'9, !, flow_digit_run(Cs, Ds, R).
flow_digit_run(R, [], R).

flow_c_name([C|Cs], [C|Ds], R) :- C =\= 41, C =\= 32, C =\= 9, !, flow_c_name(Cs, Ds, R).
flow_c_name(R, [], R).

flow_row_modes(Sig, N, A, Docs, Ms, Ns) :-
    (   Sig \== none, flow_sig_parse(Sig, Ms0, Ns0), length(Ms0, A)
    ->  Ms = Ms0, Ns = Ns0
    ;   get_assoc(N/A, Docs, sig(Ms1, Ns1, _)), length(Ms1, A)
    ->  Ms = Ms1, Ns = Ns1
    ;   length(Ms, A), flow_fill(Ms, '?'), flow_gen_arg_names(A, Ns)
    ).

%% (strcmp name "x") -- cocolint's third shape, a hand-written dispatcher
flow_strcmp_name(L, N) :-
    atom_codes(strcmp, K),
    append(_, R0, L), append(K, R1, R0),
    flow_skip_sp(R1, R2),
    append([0'n, 0'a, 0'm, 0'e], R3, R2),
    flow_skip_sp(R3, [34|R4]),
    flow_until(R4, 34, NCs, _),
    NCs \== [],
    atom_codes(N, NCs).

flow_hand_row(N, Mod, File, DL, R) :-
    findall(flow_t_portal(Mod, N, K, unknown, File, 0, Ms, Ns), member(N/K-sig(Ms, Ns, _), DL), Rs),
    (   Rs == [] -> R = flow_t_portal(Mod, N, -1, unknown, File, 0, [], [])
    ;   member(R, Rs)
    ).

%% use_module(library(X)) and ensure_loaded(library(X)) written in the
%% module's Prolog half, which is text inside its source
flow_half_loads(Cs, library(Spec)) :-
    (   atom_codes('use_module(library(', K) ; atom_codes('ensure_loaded(library(', K) ),
    append(_, R0, Cs), append(K, R1, R0),
    flow_until(R1, 41, NCs, _),
    NCs \== [],
    atom_codes(NA, NCs),
    atomic_list_concat(Parts, '/', NA),
    flow_slash_term(Parts, Spec).

flow_slash_term([P], P) :- !.
flow_slash_term(Ps, D/L) :-
    append(Init, [L], Ps),
    flow_slash_term(Init, D).

flow_source_clause(T, _, _, _, _, _, _) :- var(T), !, fail.
flow_source_clause((:- _), _, _, _, _, _, _) :- !, fail.
flow_source_clause((H0 --> B0), Vs, File, Text, L, K, N/A-cl(H, B, Names, Info)) :- !,
    flow_dcg_rule(H0, B0, Vs, Text, L, K, H, B, Names),
    callable(H), functor(H, N, A),
    flow_clause_info(File, Text, L, K, [dcg], Info).
flow_source_clause((H :- B0), Vs, File, Text, L, K, N/A-cl(H, B, Vs, Info)) :- !,
    callable(H), functor(H, N, A),
    (   flow_tokens(Text, L, K, Toks),
        flow_after(Toks, ':-', BToks),
        flow_ann_body(B0, BToks, _, B1)
    ->  B = B1
    ;   B = B0
    ),
    flow_clause_info(File, Text, L, K, [], Info).
flow_source_clause(H, Vs, File, Text, L, K, N/A-cl(H, true, Vs, Info)) :-
    callable(H), functor(H, N, A),
    flow_clause_info(File, Text, L, K, [], Info).

flow_clause_info(File, Text, L, K, Extra, [file(File), at(L, K), text(T)|Extra]) :-
    flow_clause_end(Text, T).

%% the clause's text up to and including its full stop
flow_clause_end(Text, T) :-
    flow_tokens(Text, 1, 1, Toks),
    (   member(t(end, _, EL, EK), Toks)
    ->  flow_take_to(Text, 1, 1, EL, EK, T)
    ;   T = Text
    ).

flow_take_to([], _, _, _, _, []).
flow_take_to([C|Cs], L, K, EL, EK, Out) :-
    (   L =:= EL, K =:= EK
    ->  Out = [C]
    ;   Out = [C|R],
        flow_advance([C], L, K, L1, K1),
        flow_take_to(Cs, L1, K1, EL, EK, R)
    ).

flow_split_at(Cs, 0, [], Cs) :- !.
flow_split_at([], _, [], []) :- !.
flow_split_at([C|Cs], N, [C|H], T) :-
    N1 is N - 1,
    flow_split_at(Cs, N1, H, T).

%% the line and column after Codes: a column counts characters, so under
%% `text_units = bytes', where the codes are UTF-8 bytes, a continuation
%% byte (128..191) moves nothing; in characters, the default since 2.0.0,
%% every code is a character
flow_advance([], L, K, L, K).
flow_advance([C|Cs], L, K, L1, K1) :-
    (   C =:= 10 -> L2 is L + 1, K2 = 1
    ;   C >= 128, C < 192, current_prolog_flag(text_units, bytes) -> L2 = L, K2 = K
    ;   L2 = L, K2 is K + 1
    ),
    flow_advance(Cs, L2, K2, L1, K1).

%% past white space and comments, to where a clause begins
flow_skip_layout(Cs0, L0, K0, Cs, L, K) :-
    (   Cs0 = [C|Cs1], ( C =:= 32 ; C =:= 9 ; C =:= 13 ; C =:= 10 )
    ->  flow_advance([C], L0, K0, L1, K1),
        flow_skip_layout(Cs1, L1, K1, Cs, L, K)
    ;   Cs0 = [37|_]
    ->  flow_until_nl(Cs0, Skip, Cs1),
        flow_advance(Skip, L0, K0, L1, K1),
        flow_skip_layout(Cs1, L1, K1, Cs, L, K)
    ;   Cs0 = [47, 42|_]
    ->  flow_block_comment(Cs0, Skip, Cs1),
        flow_advance(Skip, L0, K0, L1, K1),
        flow_skip_layout(Cs1, L1, K1, Cs, L, K)
    ;   Cs = Cs0, L = L0, K = K0
    ).

flow_until_nl([], [], []).
flow_until_nl([C|Cs], Skip, Rest) :-
    (   C =:= 10 -> Skip = [], Rest = [C|Cs]
    ;   Skip = [C|S1], flow_until_nl(Cs, S1, Rest)
    ).

%% /* ... */, from the opening /*
flow_block_comment([47, 42|Cs], [47, 42|Skip], Rest) :-
    flow_block_end(Cs, Skip, Rest).

flow_block_end([], [], []).
flow_block_end([42, 47|Cs], [42, 47], Cs) :- !.
flow_block_end([C|Cs], [C|S], Rest) :- flow_block_end(Cs, S, Rest).

%% ======================================================================
%% Tokens: enough of Prolog's to find a goal in its clause
%% ======================================================================
%%
%% t(Kind, Text, Line, Col): name, var, num, str, qatom, bq, sym (a run of
%% symbol characters), punct ( ) [ ] { } , |, solo ! ;, and end (the full
%% stop). Text is an atom for name, qatom (unquoted), sym, punct and solo.

flow_tokens([], _, _, []).
flow_tokens([C|Cs], L, K, Ts) :-
    (   ( C =:= 32 ; C =:= 9 ; C =:= 13 )
    ->  K1 is K + 1, flow_tokens(Cs, L, K1, Ts)
    ;   C =:= 10
    ->  L1 is L + 1, flow_tokens(Cs, L1, 1, Ts)
    ;   C =:= 37
    ->  flow_until_nl([C|Cs], Skip, R), flow_advance(Skip, L, K, L1, K1), flow_tokens(R, L1, K1, Ts)
    ;   C =:= 47, Cs = [42|_]
    ->  flow_block_comment([C|Cs], Skip, R), flow_advance(Skip, L, K, L1, K1), flow_tokens(R, L1, K1, Ts)
    ;   flow_token([C|Cs], T, Used, R)
    ->  T = t(Kd, Tx), Ts = [t(Kd, Tx, L, K)|Ts1],
        flow_advance(Used, L, K, L1, K1),
        flow_tokens(R, L1, K1, Ts1)
    ;   flow_advance([C], L, K, L1, K1), flow_tokens(Cs, L1, K1, Ts)
    ).

%% one token from the front of the codes: t(Kind, Text), the codes it used
flow_token([C|Cs], t(name, A), [C|Ns], R) :-
    C >= 0'a, C =< 0'z, !,
    flow_alnum(Cs, Ns, R), atom_codes(A, [C|Ns]).
flow_token([C|Cs], t(var, A), [C|Ns], R) :-
    ( C >= 0'A, C =< 0'Z ; C =:= 0'_ ), !,
    flow_alnum(Cs, Ns, R), atom_codes(A, [C|Ns]).
flow_token([0'0, 0''|Cs], t(num, A), [0'0, 0''|Us], R) :- !,
    flow_char_code(Cs, Us, R), atom_codes(A, [0'0, 0''|Us]).
flow_token([C|Cs], t(num, A), [C|Ds], R) :-
    C >= 0'0, C =< 0'9, !,
    flow_number_rest(Cs, Ds, R), atom_codes(A, [C|Ds]).
flow_token([0''|Cs], t(qatom, A), [0''|Us], R) :- !,
    flow_quoted(Cs, 0'', Body, Us, R), atom_codes(A, Body).
flow_token([0'"|Cs], t(str, A), [0'"|Us], R) :- !,
    flow_quoted(Cs, 0'", Body, Us, R), atom_codes(A, Body).
flow_token([0'`|Cs], t(bq, A), [0'`|Us], R) :- !,
    flow_quoted(Cs, 0'`, Body, Us, R), atom_codes(A, Body).
flow_token([C|Cs], t(punct, A), [C], Cs) :-
    memberchk(C, [0'(, 0'), 0'[, 0'], 0'{, 0'}, 0',, 0'|]), !,
    atom_codes(A, [C]).
flow_token([C|Cs], t(solo, A), [C], Cs) :-
    ( C =:= 0'! ; C =:= 0'; ), !,
    atom_codes(A, [C]).
flow_token([0'.|Cs], t(end, '.'), [0'.], Cs) :-
    ( Cs == [] ; Cs = [D|_], ( D =< 32 ; D =:= 37 ) ), !.
flow_token([C|Cs], t(sym, A), [C|Ss], R) :-
    flow_symch(C), !,
    flow_syms(Cs, Ss, R), atom_codes(A, [C|Ss]).

flow_alnum([C|Cs], [C|Ns], R) :-
    ( C >= 0'a, C =< 0'z ; C >= 0'A, C =< 0'Z ; C >= 0'0, C =< 0'9 ; C =:= 0'_ ), !,
    flow_alnum(Cs, Ns, R).
flow_alnum(R, [], R).

flow_symch(C) :- memberchk(C, [0'#, 0'$, 0'&, 0'*, 0'+, 0'-, 0'., 0'/, 0':, 0'<, 0'=, 0'>, 0'?, 0'@, 0'^, 0'~, 0'\\]).

flow_syms([C|Cs], [C|Ss], R) :- flow_symch(C), !, flow_syms(Cs, Ss, R).
flow_syms(R, [], R).

%% 0'c, 0''' (a quote), 0'\n
flow_char_code([0'\\, C|Cs], [0'\\, C], Cs) :- !.
flow_char_code([0'', 0''|Cs], [0'', 0''], Cs) :- !.
flow_char_code([C|Cs], [C], Cs).

flow_number_rest([C|Cs], [C|Ds], R) :-
    ( C >= 0'0, C =< 0'9 ; C =:= 0'_ ; C >= 0'a, C =< 0'f ; C >= 0'A, C =< 0'F ; C =:= 0'x ; C =:= 0'o ; C =:= 0'b ), !,
    flow_number_rest(Cs, Ds, R).
flow_number_rest([0'., D|Cs], [0'., D|Ds], R) :-
    D >= 0'0, D =< 0'9, !,
    flow_number_rest(Cs, Ds, R).
flow_number_rest(R, [], R).

%% the body of a quoted item and every code it used, the closing quote
%% included; a doubled quote and a backslash escape stay inside
flow_quoted([], _, [], [], []).
flow_quoted([C|Cs], Q, Body, [C|Us], R) :-
    (   C =:= Q, Cs = [Q|Cs1]
    ->  Body = [Q|B1], Us = [Q|U1], flow_quoted(Cs1, Q, B1, U1, R)
    ;   C =:= Q
    ->  Body = [], Us = [], R = Cs
    ;   C =:= 0'\\, Cs = [E|Cs1]
    ->  Body = [C, E|B1], Us = [E|U1], flow_quoted(Cs1, Q, B1, U1, R)
    ;   Body = [C|B1], flow_quoted(Cs, Q, B1, Us, R)
    ).

%% the tokens after the first depth-0 Op (:- or -->)
flow_after(Toks, Op, After) :-
    flow_after_(Toks, 0, Op, After).

flow_after_([t(Kd, Tx, _, _)|Ts], D, Op, After) :-
    (   D =:= 0, Kd == sym, Tx == Op -> After = Ts
    ;   flow_depth(Kd, Tx, D, D1), flow_after_(Ts, D1, Op, After)
    ).

flow_depth(punct, Tx, D, D1) :- memberchk(Tx, ['(', '[', '{']), !, D1 is D + 1.
flow_depth(punct, Tx, D, D1) :- memberchk(Tx, [')', ']', '}']), !, D1 is D - 1.
flow_depth(_, _, D, D).

%% ======================================================================
%% Each goal of a body, found in its clause's tokens
%% ======================================================================
%%
%% The walk follows the analysis: a control construct's parts in order, the
%% goals a meta-call runs, and leaves. A leaf starts at the first token that
%% is not a control token ( ( ) , ; | -> *-> \+ ) and runs to the next
%% depth-0 one; that first token is its place.

flow_ann_body(B, T0, T, '$at'(B, [at(L, K)])) :-
    var(B), !,
    flow_leaf_start(T0, t(_, _, L, K), T1),
    flow_skip_goal(T1, T).
flow_ann_body((A, B), T0, T, (AA, AB)) :- !,
    flow_ann_body(A, T0, T1, AA),
    flow_ann_body(B, T1, T, AB).
flow_ann_body((A ; B), T0, T, (AA ; AB)) :- !,
    flow_ann_body(A, T0, T1, AA),
    flow_ann_body(B, T1, T, AB).
flow_ann_body((A -> B), T0, T, (AA -> AB)) :- !,
    flow_ann_body(A, T0, T1, AA),
    flow_ann_body(B, T1, T, AB).
flow_ann_body((A *-> B), T0, T, (AA *-> AB)) :- !,
    flow_ann_body(A, T0, T1, AA),
    flow_ann_body(B, T1, T, AB).
flow_ann_body(\+ A, T0, T, \+ AA) :- !,
    flow_ann_body(A, T0, T, AA).
flow_ann_body(!, T0, T, !) :- !,
    flow_leaf_start(T0, t(solo, '!', _, _), [_|T]).
flow_ann_body(true, T0, T, true) :- !,
    flow_leaf_start(T0, t(name, true, _, _), [_|T]).
flow_ann_body(G, T0, T, '$at'(GA, [at(L, K)])) :-
    flow_meta_args(G, Kinds), !,
    flow_leaf_start(T0, t(Kd, Tx, L, K), T1),
    functor(G, Name, _),
    ( Kd == name ; Kd == qatom ), Tx == Name,
    T1 = [_, t(punct, '(', _, _)|T2],
    G =.. [Name|Args],
    flow_ann_args(Args, Kinds, T2, T3, AArgs),
    T3 = [t(punct, ')', _, _)|T],
    GA =.. [Name|AArgs].
flow_ann_body(G, T0, T, '$at'(G, [at(L, K)])) :-
    flow_leaf_start(T0, t(_, _, L, K), T1),
    flow_skip_goal(T1, T).

%% the arguments of a meta-call: g, a goal the analysis walks; l, a list of
%% them, each one placed as the source writes it; t, a term
flow_meta_args(findall(_, _, _), [t, g, t]).
flow_meta_args(findall(_, _, _, _), [t, g, t, t]).
flow_meta_args(aggregate_all(_, _, _), [t, g, t]).
flow_meta_args(forall(_, _), [g, g]).
flow_meta_args(once(_), [g]).
flow_meta_args(ignore(_), [g]).
flow_meta_args(not(_), [g]).
flow_meta_args(call(G), [g]) :- nonvar(G).
flow_meta_args(catch(_, _, _), [g, t, g]).
%% the goals a thread, a crew or a lock is handed (lanes.pl)
flow_meta_args(thread_create(_, _), [g, t]).
flow_meta_args(thread_pool(_, _, _), [t, g, t]).
flow_meta_args(run_isolated(_, _), [g, t]).
flow_meta_args(cowork_ask(_, _), [t, g]).
flow_meta_args(cowork_ask(_, _, _), [t, g, t]).
flow_meta_args(cowork_post(_, _), [t, g]).
flow_meta_args(cowork_map(_, _, _), [t, l, t]).
flow_meta_args(with_mutex(_, _), [t, g]).
flow_meta_args(cond_wait_until(_, _, _), [t, t, g]).

flow_ann_args([], [], T, T, []).
flow_ann_args([A|As], [Kd|Ks], T0, T, [AA|AAs]) :-
    (   Kd == g
    ->  flow_ann_body(A, T0, T1, AA),
        flow_balance(T0, T1, D),
        flow_close_n(D, T1, T2)
    ;   Kd == l, flow_ann_list(A, T0, T2L, AAL)
    ->  AA = AAL, T2 = T2L
    ;   AA = A,
        flow_skip_term(T0, T2)
    ),
    (   As == [] -> T3 = T2 ; T2 = [t(punct, ',', _, _)|T3] ),
    flow_ann_args(As, Ks, T3, T, AAs).

%% a list of goals written as one, [G1, G2 | Rest]: each element placed, a
%% tail a term; anything else is a term, and is not placed
flow_ann_list(L, [t(punct, '[', _, _)|T0], T, AL) :-
    nonvar(L), L = [_|_],
    flow_ann_elems(L, T0, T, AL).

flow_ann_elems([E|Es], T0, T, [AE|AEs]) :-
    flow_ann_body(E, T0, T1, AE),
    flow_balance(T0, T1, D),
    flow_close_n(D, T1, T2),
    (   T2 = [t(punct, ',', _, _)|T3], nonvar(Es), Es = [_|_]
    ->  flow_ann_elems(Es, T3, T, AEs)
    ;   T2 = [t(punct, '|', _, _)|T3]
    ->  AEs = Es,
        flow_skip_term(T3, T4),
        T4 = [t(punct, ']', _, _)|T]
    ;   Es == [], T2 = [t(punct, ']', _, _)|T]
    ->  AEs = []
    ).

%% past the control tokens, to the token a leaf starts with
flow_leaf_start([Tk|Ts], First, Rest) :-
    (   flow_control(Tk) -> flow_leaf_start(Ts, First, Rest)
    ;   First = Tk, Rest = [Tk|Ts]
    ).

flow_control(t(punct, Tx, _, _)) :- memberchk(Tx, ['(', ')', ',', '|']).
flow_control(t(solo, ';', _, _)).
flow_control(t(sym, Tx, _, _)) :- memberchk(Tx, ['->', '*->', '\\+']).

%% a goal runs to the next depth-0 , ; | -> *-> or a bracket that closes
flow_skip_goal(T0, T) :- flow_skip(T0, 0, goal, T).

%% a term argument runs to the next depth-0 , or a bracket that closes
flow_skip_term(T0, T) :- flow_skip(T0, 0, term, T).

flow_skip([], _, _, []).
flow_skip([Tk|Ts], D, How, T) :-
    Tk = t(Kd, Tx, _, _),
    (   D =:= 0, flow_stops(How, Kd, Tx) -> T = [Tk|Ts]
    ;   flow_depth(Kd, Tx, D, D1), flow_skip(Ts, D1, How, T)
    ).

flow_stops(_, end, _).
flow_stops(_, punct, Tx) :- memberchk(Tx, [',', ')', ']', '}']).
flow_stops(goal, punct, '|').
flow_stops(goal, solo, ';').
flow_stops(goal, sym, Tx) :- memberchk(Tx, ['->', '*->']).

%% how many brackets the tokens from T0 to T opened and did not close
flow_balance(T0, T, D) :-
    length(T0, N0),
    length(T, N),
    K is N0 - N,
    flow_count_open(T0, K, 0, D).

flow_count_open(_, 0, D, D) :- !.
flow_count_open([t(Kd, Tx, _, _)|Ts], K, D0, D) :-
    flow_depth(Kd, Tx, D0, D1),
    K1 is K - 1,
    flow_count_open(Ts, K1, D1, D).

flow_close_n(D, T, T) :- D =< 0, !.
flow_close_n(D, [t(punct, ')', _, _)|T0], T) :-
    D1 is D - 1,
    flow_close_n(D1, T0, T).

%% ======================================================================
%% A grammar rule is the predicate it stands for
%% ======================================================================
%%
%% `greeting --> [hello], name.' is translated by the engine's own
%% translator, '$dcg_goal'/4 (lib/dcg.cicili, what phrase/3 runs), so the
%% chart is of the clause that runs; its leading terminal is lifted into the
%% head as the store does it (coco_dcg_leading): the rule is drawn as
%% `greeting([hello|S1], S) :- name(S1, S)', whose head can fail when the
%% input is bound. The two hidden list arguments are named S0, S1, ... in
%% reading order -- another letter when the rule already uses S names -- so
%% the thread of the input reads off the chart. Each goal of the body keeps
%% what it was in the grammar: dcg(terminal), dcg(nonterminal(N//A)),
%% dcg(pass) for the `S = S0' a {}, ! or \+ leaves behind, dcg(call),
%% dcg(phrase) for a variable body, dcg(pushback).

flow_dcg_rule(H0, B0, Vs, Text, L, K, H, B, Names) :-
    flow_tokens(Text, L, K, Toks),
    flow_after(Toks, '-->', BToks),
    (   nonvar(H0), H0 = (NT, PB)
    ->  flow_dcg_head(NT, S0, S, H),
        '$dcg_goal'(B0, S0, S1, TB0),
        '$dcg_goal'(PB, S, S1, TB1),
        (   flow_dcg_ann(B0, TB0, BToks, _, AB0) -> true ; AB0 = TB0 ),
        (   flow_skip_term(Toks, [t(punct, ',', _, _)|PT]),
            flow_leaf_start(PT, t(_, _, PL, PK), _)
        ->  AB1 = '$at'(TB1, [at(PL, PK), dcg(pushback)])
        ;   AB1 = '$at'(TB1, [dcg(pushback)])
        ),
        B = (AB0, AB1)
    ;   flow_dcg_head(H0, S0, S, H),
        '$dcg_goal'(B0, S0, S, TB),
        (   flow_dcg_ann(B0, TB, BToks, _, AB) -> true ; AB = TB ),
        flow_dcg_lift(AB, S0, B)
    ),
    flow_dcg_names(H, B, S, Vs, Names).

flow_dcg_head(NT, S0, S, H) :-
    callable(NT),
    NT =.. [F|As],
    append(As, [S0, S], As1),
    H =.. [F|As1].

%% the first goal `S0 = T', T bound, goes into the head -- and only the
%% first: a terminal after a ! or a {} is not lifted over it
flow_dcg_lift(B0, S0, B) :-
    (   nonvar(B0), B0 = (First, Rest) -> true ; First = B0, Rest = true ),
    (   flow_unwrap(First, G), nonvar(G), G = (X = T), X == S0, nonvar(T)
    ->  S0 = T, B = Rest
    ;   B = B0
    ).

flow_unwrap(G0, G) :- ( nonvar(G0), G0 = '$at'(G1, _) -> G = G1 ; G = G0 ).

%% the grammar body and its translation, walked together
flow_dcg_ann(GB, TB, T0, T, '$at'(TB, [at(L, K), dcg(phrase)])) :-
    var(GB), !,
    flow_leaf_start(T0, t(_, _, L, K), T1),
    flow_skip_goal(T1, T).
flow_dcg_ann((X, Y), (TX, TY), T0, T, (AX, AY)) :- !,
    flow_dcg_ann(X, TX, T0, T1, AX),
    flow_dcg_ann(Y, TY, T1, T, AY).
flow_dcg_ann((X ; Y), (TX ; TY), T0, T, (AX ; AY)) :- !,
    flow_dcg_ann(X, TX, T0, T1, AX),
    flow_dcg_ann(Y, TY, T1, T, AY).
flow_dcg_ann((X | Y), (TX ; TY), T0, T, (AX ; AY)) :- !,
    flow_dcg_ann(X, TX, T0, T1, AX),
    flow_dcg_ann(Y, TY, T1, T, AY).
flow_dcg_ann((X -> Y), (TX -> TY), T0, T, (AX -> AY)) :- !,
    flow_dcg_ann(X, TX, T0, T1, AX),
    flow_dcg_ann(Y, TY, T1, T, AY).
flow_dcg_ann((X *-> Y), (TX *-> TY), T0, T, (AX *-> AY)) :- !,
    flow_dcg_ann(X, TX, T0, T1, AX),
    flow_dcg_ann(Y, TY, T1, T, AY).
flow_dcg_ann(\+ X, (\+ TX, P), T0, T, (\+ AX, '$at'(P, [dcg(pass)]))) :- !,
    flow_dcg_ann(X, TX, T0, T, AX).
flow_dcg_ann('{}'(G), (TG, P), T0, T, (AG, '$at'(P, [dcg(pass)]))) :- !,
    flow_leaf_start(T0, t(punct, '{', _, _), [_|T1]),
    flow_ann_body(TG, T1, T2, AG0),
    flow_mark_goals(AG0, AG),
    flow_balance(T1, T2, D),
    flow_close_n(D, T2, T3),
    T3 = [t(punct, '}', _, _)|T],
    G == TG.
flow_dcg_ann(!, (!, P), T0, T, (!, '$at'(P, [dcg(pass)]))) :- !,
    flow_leaf_start(T0, t(solo, '!', _, _), [_|T]).
flow_dcg_ann(GB, TB, T0, T, '$at'(TB, [at(L, K), dcg(Form)])) :-
    flow_leaf_start(T0, t(_, _, L, K), T1),
    flow_skip_goal(T1, T),
    flow_dcg_form(GB, Form).

flow_dcg_form(GB, terminal) :- ( GB == [] ; GB = [_|_] ), !.
flow_dcg_form(GB, call) :- functor(GB, call, _), !.
flow_dcg_form(GB, nonterminal(N//A)) :- functor(GB, N, A).

%% a {} block's goals are goals: dcg(goal)
flow_mark_goals(V, V) :- var(V), !.
flow_mark_goals('$at'(G, I), '$at'(G, [dcg(goal)|I])) :- !.
flow_mark_goals((A, B), (MA, MB)) :- !, flow_mark_goals(A, MA), flow_mark_goals(B, MB).
flow_mark_goals((A ; B), (MA ; MB)) :- !, flow_mark_goals(A, MA), flow_mark_goals(B, MB).
flow_mark_goals((A -> B), (MA -> MB)) :- !, flow_mark_goals(A, MA), flow_mark_goals(B, MB).
flow_mark_goals(G, G).

%% the hidden lists named in reading order: the head's input first, then
%% the body's, the head's output last
flow_dcg_names(H, B, Out, Vs, Names) :-
    functor(H, _, A),
    A1 is A - 1,
    arg(A1, H, In),
    term_variables(In, VIn),
    term_variables(B, VB),
    append(VIn, VB, V0),
    flow_hidden(V0, Out, Vs, [], Hidden0),
    (   var(Out), \+ flow_named(Out, Vs) -> append(Hidden0, [Out], Hidden) ; Hidden = Hidden0 ),
    flow_dcg_prefix(Vs, P),
    flow_number_vars(Hidden, P, 0, HNames),
    append(Vs, HNames, Names).

flow_hidden([], _, _, Acc, Hidden) :- reverse(Acc, Hidden).
flow_hidden([V|Vs], Out, Named, Acc, Hidden) :-
    (   ( V == Out ; flow_named(V, Named) ; flow_var_in(V, Acc) )
    ->  flow_hidden(Vs, Out, Named, Acc, Hidden)
    ;   flow_hidden(Vs, Out, Named, [V|Acc], Hidden)
    ).

flow_named(V, [_=V0|Ns]) :- ( V == V0 -> true ; flow_named(V, Ns) ).

flow_dcg_prefix(Vs, P) :-
    member(P, ['S', 'L', 'T', 'Z', 'Q', 'W']),
    \+ ( member(N=_, Vs), flow_prefix_name(P, N) ), !.
flow_dcg_prefix(_, 'S_').

flow_prefix_name(P, N) :-
    atom_concat(P, Rest, N),
    atom_codes(Rest, Cs),
    forall(member(C, Cs), ( C >= 0'0, C =< 0'9 )).

flow_number_vars([], _, _, []).
flow_number_vars([V|Vs], P, I, [N=V|Ns]) :-
    number_codes(I, Cs),
    atom_codes(IA, Cs),
    atom_concat(P, IA, N),
    I1 is I + 1,
    flow_number_vars(Vs, P, I1, Ns).

flow_group([], []).
flow_group([K-C|T], [K-[C|Cs]|G]) :-
    flow_take(T, K, Cs, Rest),
    flow_group(Rest, G).

flow_take([K1-C|T], K, [C|Cs], Rest) :- K1 == K, !, flow_take(T, K, Cs, Rest).
flow_take(Rest, _, [], Rest).

%% THE NAMES A PROGRAMMER GAVE: a comment line `%% pick(-X, +List)' or
%% `%! pick(-X, +List)' names the arguments a predicate is drawn with. The
%% modes drawn are still the ones INFERRED for the call -- a comment is a
%% claim, the analysis is what the code does -- the names are the author's.
%% sig(Modes, Names, Promise): Promise is promise(Det, Line) when the
%% comment says how the predicate ends -- `%! count(+Text, -N) is det.' --
%% and none when it does not. A promise is the author's claim, which is
%% what makes it worth checking (findings.pl).
flow_doc_sigs(File, Docs) :-
    catch(read_file_to_codes(File, Cs), _, Cs = []),
    flow_lines(Cs, 1, Lines),
    findall(N/A-sig(Ms, Ns, P), ( member(LN-L, Lines), flow_doc_line(L, N, A, Ms, Ns, Rest),
                                  flow_doc_promise(Rest, LN, P) ), Pairs),
    flow_first_per_key(Pairs, [], Firsts),
    list_to_assoc(Firsts, Docs).

%% a comment line at column 0: `%' in Prolog, `;;' in a module's Cicili
%% (one `;' could open a line of code); Rest is what follows the signature
flow_doc_line(L, N, A, Ms, Ns, Rest) :-
    (   L = [37|R0] -> true ; L = [59, 59|R0] ),
    flow_drop_pct(R0, R1),
    flow_skip_sp(R1, R2),
    flow_name_codes(R2, NCs, R3),
    atom_codes(N, NCs),
    (   R3 = [47, 47|Rest]
    ->  Ms = ['?', '?'], Ns = ['S0', 'S'], A = 2          % name//: a nonterminal
    ;   R3 = [40|_],
        atom_codes(SigA, R2),
        flow_sig_parse(SigA, Ms0, Ns0),
        Ns0 = [_|_],
        flow_all_named(Ns0),
        flow_after_close(R3, After),
        (   After = [47, 47|Rest]                          % name(+A, -B)//
        ->  append(Ms0, ['?', '?'], Ms), append(Ns0, ['S0', 'S'], Ns)
        ;   Ms = Ms0, Ns = Ns0, Rest = After
        ),
        length(Ms, A)
    ).

%% ` is det', ` is semidet', ... right after the signature, as PlDoc
%% writes it
flow_doc_promise(Rest, LN, P) :-
    flow_skip_sp(Rest, R1),
    (   R1 = [0'i, 0's, C|R2], ( C =:= 32 ; C =:= 9 ),
        flow_skip_sp(R2, R3),
        flow_name_codes(R3, WCs, _),
        atom_codes(W, WCs),
        memberchk(W, [det, semidet, nondet, multi, failure])
    ->  P = promise(W, LN)
    ;   P = none
    ).

%% what follows the parenthesis that closes the one in front
flow_after_close([40|Cs], After) :-
    flow_after_close_(Cs, 1, After).

flow_after_close_([C|Cs], D, After) :-
    (   C =:= 41, D =:= 1 -> After = Cs
    ;   C =:= 40 -> D1 is D + 1, flow_after_close_(Cs, D1, After)
    ;   C =:= 41 -> D1 is D - 1, flow_after_close_(Cs, D1, After)
    ;   flow_after_close_(Cs, D, After)
    ).

flow_drop_pct([C|Cs], R) :- ( C =:= 37 ; C =:= 33 ; C =:= 59 ), !, flow_drop_pct(Cs, R).
flow_drop_pct(R, R).

%% A library predicate drawn as a panel is named from its library's own
%% header, which lists its surface the same way -- `;;;   re_lines(+Pat,
%% +Codes, -Lines)' in a module, `%%   astar(+Start, ...)' in a .pl -- and
%% which the tables carry (flow_t_sig/4), so no source is read to draw it.
flow_library_docs(Panels, Docs0, Docs) :-
    findall(Key, member(panel(_, Key, library(_), _, _, _, _, _), Panels), Keys),
    flow_library_docs_(Keys, Docs0, Docs).

flow_library_docs_([], Docs, Docs).
flow_library_docs_([N/A|Keys], Docs0, Docs) :-
    (   \+ get_assoc(N/A, Docs0, _),
        flow_t_sig(N, A, Ms, Ns)
    ->  put_assoc(N/A, Docs0, sig(Ms, Ns, none), Docs1)
    ;   Docs1 = Docs0
    ),
    flow_library_docs_(Keys, Docs1, Docs).

flow_name_codes([C|Cs], [C|Ns], R) :- C >= 0'a, C =< 0'z, !, flow_name_rest(Cs, Ns, R).

flow_name_rest([C|Cs], [C|Ns], R) :-
    (   C >= 0'a, C =< 0'z ; C >= 0'A, C =< 0'Z ; C >= 0'0, C =< 0'9 ; C =:= 0'_ ), !,
    flow_name_rest(Cs, Ns, R).
flow_name_rest(R, [], R).

flow_all_named([]).
flow_all_named([N|Ns]) :-
    atom_codes(N, [C|_]),
    (   C >= 0'A, C =< 0'Z ; C =:= 0'_ ), !,
    flow_all_named(Ns).

%% a predicate's argument names: the author's from a comment, else the
%% first clause head's variables, else letters
flow_names_for(N/A, Docs, Rows, G, Names) :-
    functor(G, N, A),
    (   get_assoc(N/A, Docs, sig(_, DNs, _)), length(DNs, A)
    ->  G =.. [_|Vs], flow_pair_names(DNs, Vs, Names)
    ;   Rows = [row(_, H, Vs, _, _, CI)|_], H \== none
    ->  flow_arg_names(H, Vs, G, 1, A, Names0),
        (   memberchk(dcg, CI) -> flow_dcg_pair(Names0, Names) ; Names = Names0 )
    ;   flow_gen_names(G, Names)
    ).

%% a grammar rule's two hidden arguments are named as a grammar is read --
%% the list in, S0, and what is left of it, S -- unless a visible argument
%% already has one of those names
flow_dcg_pair(Names0, Names) :-
    (   append(Front, [_=V0, _=V], Names0),
        \+ memberchk('S0'=_, Front),
        \+ memberchk('S'=_, Front)
    ->  append(Front, ['S0'=V0, 'S'=V], Names)
    ;   Names = Names0
    ).

%% A clause read back with clause/2 has no names; it is given A, B, C ...
flow_gen_names(T, Names) :-
    term_variables(T, Vs),
    flow_name_vars(Vs, 0, Names).

flow_name_vars([], _, []).
flow_name_vars([V|Vs], I, [N=V|Ns]) :-
    flow_letter_name(I, N),
    I1 is I + 1,
    flow_name_vars(Vs, I1, Ns).

flow_letter_name(I, N) :-
    C is 0'A + I mod 26,
    K is I // 26,
    (   K =:= 0 -> atom_codes(N, [C])
    ;   number_codes(K, Ks), atom_codes(N, [C|Ks])
    ).

flow_var_name(V, [N=V0|Ns], Nm) :-
    (   V0 == V -> Nm = N ; flow_var_name(V, Ns, Nm) ).

%% the names of a head's arguments, for drawing the predicate as called:
%% a variable keeps its name, anything else is named by its position
flow_arg_names(_, _, _, I, A, []) :- I > A, !.
flow_arg_names(H, Vs, G, I, A, [Nm=V|Ns]) :-
    arg(I, G, V),
    arg(I, H, HA),
    (   var(HA), flow_var_name(HA, Vs, Nm0) -> Nm = Nm0
    ;   I0 is I - 1, flow_letter_name(I0, Nm)
    ),
    I1 is I + 1,
    flow_arg_names(H, Vs, G, I1, A, Ns).


%% ======================================================================
%% Text, a line at a time, and signatures like re_first(+Pat, +Text, -M)
%% ======================================================================

flow_module_file(Dir, Mod, Rel, File) :-
    (   atomic_list_concat(['modules/', Mod, '/', Mod, '.cicili'], Rel)
    ;   atomic_list_concat(['modules/', Mod, '/coco-', Mod, '.cicili'], Rel)
    ),
    atomic_list_concat([Dir, '/', Rel], File),
    exists_file(File).

flow_lines(Cs, I, Lines) :-
    (   Cs == [] -> Lines = []
    ;   flow_until(Cs, 10, L, Rest),
        Lines = [I-L|Ls],
        I1 is I + 1,
        flow_lines(Rest, I1, Ls)
    ).

flow_until([], _, [], []).
flow_until([C|Cs], Stop, Before, After) :-
    (   C =:= Stop -> Before = [], After = Cs
    ;   Before = [C|B], flow_until(Cs, Stop, B, After)
    ).


flow_skip_sp([C|Cs], R) :- ( C =:= 32 ; C =:= 9 ), !, flow_skip_sp(Cs, R).
flow_skip_sp(R, R).

flow_trim(Cs, T) :-
    flow_skip_sp(Cs, C1),
    reverse(C1, R1),
    flow_skip_sp(R1, R2),
    reverse(R2, T).

%% re_first(+Pat, +Text, -MatchCodes) -> modes and names
flow_sig_parse(Sig, Modes, Names) :-
    atom_codes(Sig, Cs),
    append(_, [40|R], Cs), !,
    flow_sig_args(R, 0, [], Args),
    flow_sig_modes(Args, Modes, Names).

flow_sig_args([], _, Cur, [Arg]) :- reverse(Cur, Arg).
flow_sig_args([C|Cs], D, Cur, Args) :-
    (   C =:= 41, D =:= 0 -> reverse(Cur, A), Args = [A]
    ;   C =:= 44, D =:= 0 -> reverse(Cur, A), Args = [A|As], flow_sig_args(Cs, D, [], As)
    ;   ( C =:= 40 ; C =:= 91 ) -> D1 is D + 1, flow_sig_args(Cs, D1, [C|Cur], Args)
    ;   ( C =:= 41 ; C =:= 93 ) -> D1 is D - 1, flow_sig_args(Cs, D1, [C|Cur], Args)
    ;   flow_sig_args(Cs, D, [C|Cur], Args)
    ).

flow_sig_modes([], [], []).
flow_sig_modes([A|As], [M|Ms], [N|Ns]) :-
    flow_trim(A, T),
    (   T = [C|Rest], memberchk(C, [43, 45, 63, 58, 64])
    ->  (   C =:= 64 -> M = '+' ; atom_codes(M, [C]) ),
        atom_codes(N, Rest)
    ;   M = '?', atom_codes(N, T)
    ),
    flow_sig_modes(As, Ms, Ns).

flow_gen_arg_names(A, Names) :-
    A1 is A - 1,
    findall(N, ( between(0, A1, I), flow_letter_name(I, N) ), Names).

%% ---- small things every part uses --------------------------------------

flow_fill([], _).
flow_fill([X|Xs], X) :- flow_fill(Xs, X).

%% the first pair of each key, in order
flow_first_per_key([], _, []).
flow_first_per_key([C-Y|T], Seen, Out) :-
    (   memberchk(C, Seen) -> Out = Out1 ; Out = [C-Y|Out1] ),
    flow_first_per_key(T, [C|Seen], Out1).
