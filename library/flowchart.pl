%% library(flowchart) -- a predicate drawn as a flowchart: from the query
%% down to the C it reaches, and back.
%%
%%     :- use_module(library(flowchart)).
%%
%%     flow_chart(+Spec, +SvgFile)
%%     flow_chart(+Spec, +SvgFile, +Options)
%%     flow_graph(+Spec, -Graph, +Options)
%%
%% PROTOTYPE (F0). It is here to settle the LOOK before the rest is built;
%% what it does not do yet is listed at the end of this header.
%%
%% Spec is a call pattern -- report(+, +, +) -- or Name/Arity, which reads
%% every argument as `?'. Options:
%%
%%     source(File)     the program, read with its own variable names
%%     title(Atom)      the chart's title (default: the moded head)
%%     libraries(How)   reach (default): a library predicate becomes a panel
%%                      only on a path that reaches C; all; none
%%     data(Dir)        a cocolog checkout, '.' by default (see NOT YET)
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
%% the end of the chart, never looked inside.
%%
%% MODES are shown the Prolog way, on every argument: + input, - output,
%% ? either, : a goal. A builtin's come from the hand-kept table below, a C
%% function's from its module's table, and user code's are INFERRED from
%% the call pattern: which variables are bound when each goal runs.
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
%% NOT YET (F1): grammar rules are not drawn; a predicate called with two
%% call patterns is drawn for its first; the tables that classify a goal
%% come from a checkout (tools/cocolint/blocklist.pl and modules/*/*.cicili)
%% instead of shipping with the library.

:- use_module(library(xml)).
:- use_module(library(stream)).

%% ======================================================================
%% Entry
%% ======================================================================

flow_chart(Spec, File) :-
    flow_chart(Spec, File, []).

flow_chart(Spec, File, Opts) :-
    flow_graph(Spec, Graph, Opts),
    flow_svg(Graph, Svg),
    xml_codes(Svg, Codes, [header(true)]),
    open(File, write, S),
    flow_write_codes(S, Codes),
    close(S).

%% in pieces: format/2's ~s refuses a list of some tens of thousands of
%% codes ("~s wants text"), and a chart is easily that
flow_write_codes(S, Cs) :-
    (   Cs == [] -> true
    ;   flow_split_at(Cs, 4096, Chunk, Rest),
        format(S, "~s", [Chunk]),
        flow_write_codes(S, Rest)
    ).

flow_split_at(Cs, 0, [], Cs) :- !.
flow_split_at([], _, [], []) :- !.
flow_split_at([C|Cs], N, [C|H], T) :-
    N1 is N - 1,
    flow_split_at(Cs, N1, H, T).

flow_graph(Spec, graph(Title, Src, Panels, Ids, Docs), Opts) :-
    flow_spec(Spec, Name, Arity, CM),
    flow_option(source(Src), Opts, none),
    (   Src == none
    ->  throw(error(existence_error(flow_option, source), flow_graph/3))
    ;   true
    ),
    flow_option(data(Dir), Opts, '.'),
    flow_option(libraries(How), Opts, reach),
    flow_data_load(Dir),
    use_module(Src),
    flow_read_source(Src, Prog),
    flow_doc_sigs(Src, Docs0),
    Ctx = ctx(Prog, Dir, How),
    flow_build(Ctx, Name/Arity, CM, Panels, Ids),
    flow_library_docs(Panels, Dir, Docs0, Docs),
    flow_option(title(Title0), Opts, none),
    (   Title0 == none -> flow_default_title(Panels, Docs, Title) ; Title = Title0 ).

flow_option(Opt, Opts, Default) :-
    (   memberchk(Opt, Opts) -> true ; arg(1, Opt, Default) ).

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

flow_fill([], _).
flow_fill([X|Xs], X) :- flow_fill(Xs, X).

%% ======================================================================
%% What the prototype classifies with: cocolint's generated tables
%% ======================================================================

flow_data_load(Dir) :-
    atomic_list_concat([Dir, '/tools/cocolint/blocklist.pl'], F),
    (   exists_file(F) -> use_module(F) ; true ).

flow_bl(G) :- catch(G, _, fail).

%% ======================================================================
%% The program, read with its variable names
%% ======================================================================

flow_read_source(File, Prog) :-
    open(File, read, S),
    flow_read_terms(S, Pairs),
    close(S),
    keysort(Pairs, Sorted),
    flow_group(Sorted, Grouped),
    list_to_assoc(Grouped, Prog).

flow_read_terms(S, Pairs) :-
    read_term(S, T, [variable_names(Vs)]),
    (   T == end_of_file -> Pairs = []
    ;   flow_source_clause(T, Vs, Pair) -> Pairs = [Pair|Rest], flow_read_terms(S, Rest)
    ;   flow_read_terms(S, Pairs)
    ).

flow_source_clause(T, _, _) :- var(T), !, fail.
flow_source_clause((:- _), _, _) :- !, fail.
flow_source_clause((_ --> _), _, _) :- !, fail.
flow_source_clause((H :- B), Vs, N/A-cl(H, B, Vs)) :- !,
    callable(H), functor(H, N, A).
flow_source_clause(H, Vs, N/A-cl(H, true, Vs)) :-
    callable(H), functor(H, N, A).

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
flow_doc_sigs(File, Docs) :-
    catch(read_file_to_codes(File, Cs), _, Cs = []),
    flow_lines(Cs, 1, Lines),
    findall(N/A-sig(Ms, Ns), ( member(_-L, Lines), flow_doc_line(L, N, A, Ms, Ns) ), Pairs),
    flow_first_per_key(Pairs, [], Firsts),
    list_to_assoc(Firsts, Docs).

%% a comment line at column 0: `%' in Prolog, `;;' in a module's Cicili
%% (one `;' could open a line of code)
flow_doc_line(L, N, A, Ms, Ns) :-
    (   L = [37|R0] -> true ; L = [59, 59|R0] ),
    flow_drop_pct(R0, R1),
    flow_skip_sp(R1, R2),
    flow_name_codes(R2, NCs, R3),
    R3 = [40|_],
    atom_codes(N, NCs),
    atom_codes(SigA, R2),
    flow_sig_parse(SigA, Ms, Ns),
    Ns = [_|_],
    flow_all_named(Ns),
    length(Ms, A).

flow_drop_pct([C|Cs], R) :- ( C =:= 37 ; C =:= 33 ; C =:= 59 ), !, flow_drop_pct(Cs, R).
flow_drop_pct(R, R).

%% A library predicate drawn as a panel is named from its library's own
%% header, which lists its surface the same way: `;;;   re_lines(+Pat,
%% +Codes, -Lines)' in a module, `%%   astar(+Start, ...)' in a .pl.
flow_library_docs(Panels, Dir, Docs0, Docs) :-
    findall(Key-L, member(panel(_, Key, library(L), _, _, _, _, _), Panels), KLs),
    flow_library_docs_(KLs, Dir, Docs0, Docs).

flow_library_docs_([], _, Docs, Docs).
flow_library_docs_([Key-L|KLs], Dir, Docs0, Docs) :-
    (   \+ get_assoc(Key, Docs0, _),
        flow_library_file(L, Dir, File),
        flow_doc_sigs(File, LDocs),
        get_assoc(Key, LDocs, Sig)
    ->  put_assoc(Key, Docs0, Sig, Docs1)
    ;   Docs1 = Docs0
    ),
    flow_library_docs_(KLs, Dir, Docs1, Docs).

flow_library_file(L, Dir, File) :-
    (   flow_module_file(Dir, L, _, File) -> true
    ;   atomic_list_concat([Dir, '/', L], File), exists_file(File) -> true
    ;   atomic_list_concat([Dir, '/library/', L, '.pl'], File), exists_file(File)
    ).

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
    (   get_assoc(N/A, Docs, sig(_, DNs)), length(DNs, A)
    ->  G =.. [_|Vs], flow_pair_names(DNs, Vs, Names)
    ;   Rows = [row(_, H, Vs, _, _)|_], H \== none
    ->  flow_arg_names(H, Vs, G, 1, A, Names)
    ;   flow_gen_names(G, Names)
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
%% What a goal is
%% ======================================================================
%%
%% Dispatch is construct, C builtin, module, store -- so is this, in that
%% order: a name the engine answers in C is a builtin whatever a file
%% defines under it.

flow_kind(G, Ctx, Kind) :-
    functor(G, N, A),
    Ctx = ctx(Prog, _, _),
    (   flow_test(N, A)                 -> Kind = test
    ;   N == (=), A =:= 2               -> Kind = unify
    ;   flow_bl(cl_t1c(N, A, _))        -> Kind = builtin
    ;   flow_bl(cl_t2c(Mod, N, A))      -> Kind = portal(Mod)
    ;   get_assoc(N/A, Prog, _)         -> Kind = user
    ;   flow_bl(cl_t1p(N, A, F))        -> Kind = library(F)
    ;   flow_bl(cl_t2p(M, N, A))        -> Kind = library(M)
    ;   flow_has_clauses(N, A)          -> Kind = library(loaded)
    ;   Kind = unknown
    ).

flow_has_clauses(N, A) :-
    functor(H, N, A),
    catch(clause(H, _), _, fail), !.

flow_callable_kind(user).
flow_callable_kind(library(_)).
flow_callable_kind(portal(_)).

flow_test('<', 2).
flow_test('>', 2).
flow_test('=<', 2).
flow_test('>=', 2).
flow_test('=:=', 2).
flow_test('=\\=', 2).
flow_test('==', 2).
flow_test('\\==', 2).
flow_test('@<', 2).
flow_test('@>', 2).
flow_test('@=<', 2).
flow_test('@>=', 2).
flow_test('\\=', 2).
flow_test(var, 1).
flow_test(nonvar, 1).
flow_test(atom, 1).
flow_test(number, 1).
flow_test(integer, 1).
flow_test(float, 1).
flow_test(atomic, 1).
flow_test(compound, 1).
flow_test(callable, 1).
flow_test(is_list, 1).
flow_test(ground, 1).
flow_test(string, 1).

%% THE HAND-KEPT TABLE: a builtin's or a library predicate's argument modes
%% and determinism, a line per way of calling it, as SWI's manual lists
%% them. det never fails; semidet may fail and leaves no choice; nondet may
%% leave one. A call takes the first line its modes meet (flow_mode_for/5)
%% and else the first line, CHECKING what that line would produce: a det
%% builtin handed its output already bound only compares, and can fail. F1
%% makes the table complete against the engine's own builtin table; the
%% prototype carries what charts usually meet.
flow_mode(is, 2, ['-', '+'], det).
flow_mode(succ, 2, ['?', '?'], semidet).
flow_mode(plus, 3, ['?', '?', '?'], semidet).
flow_mode(functor, 3, ['+', '-', '-'], det).
flow_mode(functor, 3, ['-', '+', '+'], det).
flow_mode(arg, 3, ['+', '+', '?'], semidet).
flow_mode('=..', 2, ['+', '-'], det).
flow_mode('=..', 2, ['-', '+'], det).
flow_mode(copy_term, 2, ['+', '-'], det).
flow_mode(term_variables, 2, ['+', '-'], det).
flow_mode(atom_codes, 2, ['+', '-'], det).
flow_mode(atom_codes, 2, ['-', '+'], det).
flow_mode(atom_chars, 2, ['+', '-'], det).
flow_mode(atom_chars, 2, ['-', '+'], det).
flow_mode(char_code, 2, ['+', '-'], det).
flow_mode(char_code, 2, ['-', '+'], det).
flow_mode(atom_length, 2, ['+', '-'], det).
flow_mode(atom_number, 2, ['+', '-'], semidet).
flow_mode(atom_number, 2, ['-', '+'], det).
flow_mode(number_codes, 2, ['+', '-'], det).
flow_mode(number_codes, 2, ['-', '+'], det).
flow_mode(atom_concat, 3, ['+', '+', '-'], det).
flow_mode(atom_concat, 3, ['?', '?', '?'], semidet).
flow_mode(sub_atom, 5, ['+', '?', '?', '?', '?'], nondet).
flow_mode(atomic_list_concat, 2, ['+', '-'], det).
flow_mode(atomic_list_concat, 3, ['+', '+', '-'], det).
flow_mode(atomic_list_concat, 3, ['-', '+', '+'], det).
flow_mode(upcase_atom, 2, ['+', '-'], det).
flow_mode(term_to_atom, 2, ['+', '-'], det).
flow_mode(term_to_atom, 2, ['-', '+'], det).
flow_mode(format, 1, ['+'], det).
flow_mode(format, 2, ['+', '+'], det).
flow_mode(format, 3, ['+', '+', '+'], det).
flow_mode(write, 1, ['+'], det).
flow_mode(print, 1, ['+'], det).
flow_mode(writeln, 1, ['+'], det).
flow_mode(write_canonical, 1, ['+'], det).
flow_mode(nl, 0, [], det).
flow_mode(tab, 1, ['+'], det).
flow_mode(read_term, 3, ['+', '-', '+'], det).
flow_mode(read, 1, ['-'], det).
flow_mode(assertz, 1, ['+'], det).
flow_mode(asserta, 1, ['+'], det).
flow_mode(assert, 1, ['+'], det).
flow_mode(retract, 1, ['?'], semidet).
flow_mode(retractall, 1, ['?'], det).
flow_mode(nb_setval, 2, ['+', '+'], det).
flow_mode(nb_getval, 2, ['+', '-'], det).
flow_mode(b_setval, 2, ['+', '+'], det).
flow_mode(b_getval, 2, ['+', '-'], det).
flow_mode(length, 2, ['+', '-'], det).
flow_mode(length, 2, ['-', '+'], det).
flow_mode(length, 2, ['+', '+'], semidet).
flow_mode(length, 2, ['?', '?'], nondet).
flow_mode(between, 3, ['+', '+', '?'], nondet).
flow_mode(msort, 2, ['+', '-'], det).
flow_mode(sort, 2, ['+', '-'], det).
flow_mode(sort, 4, ['+', '+', '+', '-'], det).
flow_mode(keysort, 2, ['+', '-'], det).
flow_mode(member, 2, ['?', '+'], nondet).
flow_mode(memberchk, 2, ['?', '+'], semidet).
flow_mode(append, 3, ['?', '?', '?'], nondet).
flow_mode(append, 2, ['+', '-'], det).
flow_mode(reverse, 2, ['+', '-'], det).
flow_mode(nth0, 3, ['?', '+', '?'], nondet).
flow_mode(nth1, 3, ['?', '+', '?'], nondet).
flow_mode(last, 2, ['+', '-'], semidet).
flow_mode(sum_list, 2, ['+', '-'], det).
flow_mode(max_list, 2, ['+', '-'], semidet).
flow_mode(min_list, 2, ['+', '-'], semidet).
flow_mode(numlist, 3, ['+', '+', '-'], det).
flow_mode(list_to_set, 2, ['+', '-'], det).
flow_mode(delete, 3, ['+', '+', '-'], det).
flow_mode(subtract, 3, ['+', '+', '-'], det).
flow_mode(select, 3, ['?', '?', '?'], nondet).
flow_mode(exclude, 3, [':', '+', '-'], det).
flow_mode(include, 3, [':', '+', '-'], det).
flow_mode(maplist, 2, [':', '?'], semidet).
flow_mode(maplist, 3, [':', '?', '?'], semidet).
flow_mode(maplist, 4, [':', '?', '?', '?'], semidet).
flow_mode(foldl, 4, [':', '+', '+', '-'], semidet).
flow_mode(flatten, 2, ['+', '-'], det).
flow_mode(halt, 0, [], det).
flow_mode(halt, 1, ['+'], det).
flow_mode(get_time, 1, ['-'], det).
flow_mode(statistics, 2, ['+', '-'], det).
flow_mode(garbage_collect, 0, [], det).
flow_mode(list_to_assoc, 2, ['+', '-'], det).
flow_mode(put_assoc, 4, ['+', '+', '+', '-'], det).
flow_mode(get_assoc, 3, ['+', '+', '?'], semidet).
flow_mode(pairs_keys_values, 3, ['+', '-', '-'], det).
flow_mode(pairs_keys_values, 3, ['-', '+', '+'], det).
flow_mode(read_file_to_codes, 2, ['+', '-'], det).
flow_mode(open, 3, ['+', '+', '-'], det).
flow_mode(open, 4, ['+', '+', '-', '+'], det).
flow_mode(close, 1, ['+'], det).
flow_mode(codes_lines, 2, ['+', '-'], det).
flow_mode(codes_lines, 2, ['-', '+'], det).

%% the line a call takes: the first whose modes it meets (a bound argument
%% meets + or ?, a free one - or ?), else the first line, which then only
%% checks where it would have produced -- det becomes semidet
flow_mode_for(N, A, Ms, DMs, Det) :-
    (   flow_mode(N, A, DMs, Det), flow_modes_meet(Ms, DMs) -> true
    ;   flow_mode(N, A, DMs, Det0), !,
        (   Det0 == det -> Det = semidet ; Det = Det0 )
    ).

flow_modes_meet([], []).
flow_modes_meet([M|Ms], [D|Ds]) :-
    flow_mode_meets(M, D), !,
    flow_modes_meet(Ms, Ds).

flow_mode_meets(_, '?').
flow_mode_meets(_, ':').
flow_mode_meets('+', '+').
flow_mode_meets('-', '-').

%% ======================================================================
%% A C function, from its module's table
%% ======================================================================
%%
%% Each module dispatches through rows like
%%     ("re_first"   3 coco_x_first)     ; re_first(+Pat, +Text, -MatchCodes)
%% so the row says which C function answers the name and arity, and its
%% comment says the modes.

flow_portal(Mod, N, A, Dir, info(CFun, Rel, Line, Modes, Names)) :-
    flow_module_file(Dir, Mod, Rel, File),
    catch(read_file_to_codes(File, Cs), _, fail),
    flow_lines(Cs, 1, Lines),
    flow_find_row(Lines, N, A, CFun, Line, Sig), !,
    (   Sig == none
    ->  length(Modes, A), flow_fill(Modes, '?'), flow_gen_arg_names(A, Names)
    ;   flow_sig_parse(Sig, Modes, Names)
    ).

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

flow_find_row([I-L|Ls], N, A, CFun, Line, Sig) :-
    (   flow_table_row(L, N, A, CFun, Sig) -> Line = I
    ;   flow_find_row(Ls, N, A, CFun, Line, Sig)
    ).

%% ("NAME"  ARITY  cfun)  ; signature        -- 40 ( 34 " 59 ;
flow_table_row(L, N, A, CFun, Sig) :-
    atom_codes(N, NCs),
    append(NCs, [34], NQ),
    append(_, [40, 34|R0], L),
    append(NQ, R1, R0), !,
    flow_skip_sp(R1, R2),
    flow_digits(R2, DCs, R3),
    DCs \== [],
    number_codes(A0, DCs),
    A0 =:= A,
    flow_skip_sp(R3, R4),
    flow_sym(R4, FCs, R5),
    FCs \== [],
    atom_codes(CFun, FCs),
    (   append(_, [59|R6], R5) -> flow_trim(R6, SCs), atom_codes(Sig, SCs)
    ;   Sig = none
    ).

flow_skip_sp([C|Cs], R) :- ( C =:= 32 ; C =:= 9 ), !, flow_skip_sp(Cs, R).
flow_skip_sp(R, R).

flow_digits([C|Cs], [C|Ds], R) :- C >= 48, C =< 57, !, flow_digits(Cs, Ds, R).
flow_digits(R, [], R).

flow_sym([C|Cs], [C|Ds], R) :- C =\= 41, C =\= 32, C =\= 9, !, flow_sym(Cs, Ds, R).
flow_sym(R, [], R).

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

%% ======================================================================
%% Building the graph: one panel per predicate, breadth first
%% ======================================================================

flow_build(Ctx, Key, CM, [Q|Panels], Ids) :-
    empty_assoc(I0),
    Key = N/A,
    functor(G, N, A),
    flow_kind(G, Ctx, Kind),
    put_assoc(Key, I0, 1, I1),
    empty_assoc(M0),
    flow_bfs([todo(1, Key, Kind, CM, 1)], Ctx, I1, 2, M0, Panels, Ids),
    flow_query_panel(Key, Kind, CM, Ctx, Panels, Q).

flow_bfs([], _, Ids, _, _, [], Ids).
flow_bfs([todo(Id, Key, Kind, CM, D)|Q], Ctx, I0, Next0, M0, [P|Ps], Ids) :-
    flow_make_panel(Id, Key, Kind, CM, D, Ctx, M0, M1, P),
    P = panel(_, _, _, _, _, _, _, Calls),
    flow_enqueue(Calls, D, Ctx, I0, I1, Next0, Next1, New),
    append(Q, New, Q1),
    flow_bfs(Q1, Ctx, I1, Next1, M1, Ps, Ids).

flow_enqueue([], _, _, I, I, N, N, []).
flow_enqueue([c(Key, Kind, CMs)|Cs], D, Ctx, I0, I, N0, N, New) :-
    (   get_assoc(Key, I0, _)
    ->  I1 = I0, N1 = N0, New = New1
    ;   flow_panel_worthy(Key, Kind, Ctx)
    ->  put_assoc(Key, I0, N0, I1),
        N1 is N0 + 1,
        D1 is D + 1,
        New = [todo(N0, Key, Kind, CMs, D1)|New1]
    ;   I1 = I0, N1 = N0, New = New1
    ),
    flow_enqueue(Cs, D, Ctx, I1, I, N1, N, New1).

flow_panel_worthy(_, user, _) :- !.
flow_panel_worthy(_, portal(_), _) :- !.
flow_panel_worthy(Key, library(_), ctx(_, _, How)) :-
    (   How == all -> true
    ;   How == reach -> flow_reaches_c(Key, [], 0)
    ;   fail
    ).

%% A library predicate earns a panel by standing between the query and C.
flow_reaches_c(N/A, Seen, D) :-
    D < 6,
    functor(H, N, A),
    findall(B, catch(clause(H, B), _, fail), Bodies),
    flow_bodies_goals(Bodies, Goals),
    D1 is D + 1,
    member(G, Goals),
    callable(G),
    functor(G, GN, GA),
    (   flow_bl(cl_t2c(_, GN, GA)) -> true
    ;   \+ memberchk(GN/GA, Seen),
        (   flow_bl(cl_t1p(GN, GA, _)) ; flow_bl(cl_t2p(_, GN, GA)) ),
        flow_reaches_c(GN/GA, [N/A|Seen], D1)
    ), !.

flow_bodies_goals([], []).
flow_bodies_goals([B|Bs], Gs) :-
    flow_goals_in(B, G1),
    flow_bodies_goals(Bs, G2),
    append(G1, G2, Gs).

flow_goals_in(V, []) :- var(V), !.
flow_goals_in((A, B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in((A ; B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in((A -> B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in((A *-> B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in(\+ A, Gs) :- !, flow_goals_in(A, Gs).
flow_goals_in(findall(_, G, _), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(findall(_, G, _, _), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(forall(A, B), Gs) :- !, flow_goals_in2(A, B, Gs).
flow_goals_in(aggregate_all(_, G, _), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(once(G), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(ignore(G), Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(catch(G, _, R), Gs) :- !, flow_goals_in2(G, R, Gs).
flow_goals_in(_:G, Gs) :- !, flow_goals_in(G, Gs).
flow_goals_in(G, [G]).

flow_goals_in2(A, B, Gs) :-
    flow_goals_in(A, Ga),
    flow_goals_in(B, Gb),
    append(Ga, Gb, Gs).

flow_make_panel(Id, Key, portal(Mod), CM, D, ctx(_, Dir, _), M, M,
                panel(Id, Key, portal(Mod), CM, D, portal(Info), semidet, [])) :- !,
    Key = N/A,
    (   flow_portal(Mod, N, A, Dir, Info) -> true
    ;   length(Ms, A), flow_fill(Ms, '?'), flow_gen_arg_names(A, Ns),
        Info = info(unknown, unknown, 0, Ms, Ns)
    ).
flow_make_panel(Id, Key, Kind, CM, D, Ctx, M0, M,
                panel(Id, Key, Kind, CM, D, rows(Rows), Det, Calls)) :-
    flow_clauses(Key, Kind, Ctx, Cls),
    flow_rows(Cls, 1, CM, Ctx, M0, M, Rows),
    flow_rows_nodes(Rows, NLs),
    flow_pred_det(Cls, NLs, CM, Det),
    flow_rows_calls(Rows, Calls).

flow_rows_nodes([], []).
flow_rows_nodes([row(_, _, _, _, Ns)|Rs], [Ns|NLs]) :- flow_rows_nodes(Rs, NLs).

flow_clauses(Key, user, ctx(Prog, _, _), Cls) :- !,
    get_assoc(Key, Prog, Cls).
flow_clauses(N/A, _, _, Cls) :-
    functor(H, N, A),
    findall(cl(H, B, Vs), ( catch(clause(H, B), _, fail), flow_gen_names(H-B, Vs) ), Cls).

flow_rows([], _, _, _, M, M, []).
flow_rows([cl(H, B, Vs)|Cs], I, CM, Ctx, M0, M, [row(I, H, Vs, HF, Nodes)|Rs]) :-
    flow_head_state(H, CM, St0),
    flow_head_can_fail(H, CM, HF),
    flow_an_seq(B, St0, _, Ctx, M0, M1, Nodes),
    I1 is I + 1,
    flow_rows(Cs, I1, CM, Ctx, M1, M, Rs).

%% the calls a panel makes, first occurrence of each, in reading order
flow_rows_calls(Rows, Calls) :-
    flow_rows_calls_(Rows, [], Rev),
    reverse(Rev, Calls).

flow_rows_calls_([], Acc, Acc).
flow_rows_calls_([row(_, _, _, _, Ns)|Rs], Acc0, Acc) :-
    flow_nodes_calls(Ns, Acc0, Acc1),
    flow_rows_calls_(Rs, Acc1, Acc).

flow_nodes_calls([], Acc, Acc).
flow_nodes_calls([N|Ns], Acc0, Acc) :-
    flow_node_calls(N, Acc0, Acc1),
    flow_nodes_calls(Ns, Acc1, Acc).

flow_node_calls(g(_, Kind, Ms, _, Key), Acc0, Acc) :- !,
    (   flow_callable_kind(Kind), \+ memberchk(c(Key, _, _), Acc0)
    ->  Acc = [c(Key, Kind, Ms)|Acc0]
    ;   Acc = Acc0
    ).
flow_node_calls(ite(_, Arms, Else), Acc0, Acc) :- !,
    flow_arms_calls(Arms, Acc0, Acc1),
    (   Else == none -> Acc = Acc1 ; flow_nodes_calls(Else, Acc1, Acc) ).
flow_node_calls(or(Bs), Acc0, Acc) :- !, flow_lists_calls(Bs, Acc0, Acc).
flow_node_calls(not(Ns), Acc0, Acc) :- !, flow_nodes_calls(Ns, Acc0, Acc).
flow_node_calls(meta(_, _, _, Ts), Acc0, Acc) :- !, flow_lists_calls(Ts, Acc0, Acc).
flow_node_calls(catchc(G, _, R), Acc0, Acc) :- !, flow_lists_calls([G, R], Acc0, Acc).
flow_node_calls(_, Acc, Acc).

flow_arms_calls([], Acc, Acc).
flow_arms_calls([arm(C, T)|As], Acc0, Acc) :-
    flow_nodes_calls(C, Acc0, A1),
    flow_nodes_calls(T, A1, A2),
    flow_arms_calls(As, A2, Acc).

flow_lists_calls([], Acc, Acc).
flow_lists_calls([L|Ls], Acc0, Acc) :-
    flow_nodes_calls(L, Acc0, A1),
    flow_lists_calls(Ls, A1, Acc).

%% the query, drawn as a panel of its own: ?- report(+Pat, +Text, +Nums).
flow_query_panel(Key, Kind, CM, ctx(Prog, _, _), Panels,
                 panel(0, query, query, CM, 0,
                       rows([row(0, none, Names, false, [g(Goal, Kind, CM, Det, Key)])]),
                       Det, [c(Key, Kind, CM)])) :-
    Key = N/A,
    functor(Goal, N, A),
    (   get_assoc(Key, Prog, [cl(H, _, Vs)|_])
    ->  flow_arg_names(H, Vs, Goal, 1, A, Names)
    ;   flow_gen_names(Goal, Names)
    ),
    (   memberchk(panel(1, _, _, _, _, _, Det0, _), Panels) -> Det = Det0 ; Det = semidet ).

flow_default_title(Panels, Docs, Title) :-
    memberchk(panel(0, _, _, CM, _, rows([row(_, _, _, _, [g(_, _, _, _, Key)])]), _, _), Panels),
    memberchk(panel(1, _, _, _, _, Body, _, _), Panels),
    (   Body = rows(Rows) -> true ; Rows = [] ),
    flow_names_for(Key, Docs, Rows, G, Names),
    flow_moded_head(G, CM, Names, Segs),
    flow_segs_atom(Segs, Title).

flow_segs_atom(Segs, A) :-
    findall(T, member(s(T, _), Segs), Ts),
    atomic_list_concat(Ts, A).

%% ======================================================================
%% Modes: which variables are bound when each goal runs
%% ======================================================================
%%
%% A variable is f (free), p (partly bound) or b (bound). A head enters
%% with its + arguments bound; each goal then binds what its modes say it
%% binds -- a builtin's from the table, a C function's from its row, a
%% user predicate's from analysing ITS clauses for this call pattern, once,
%% remembered. A recursive call meets its own analysis in progress and is
%% taken to bind its outputs, which is what a terminating recursion does.

flow_st_get(St, V, S) :-
    (   flow_st_find(St, V, S0) -> S = S0 ; S = f ).

flow_st_find([V0-S0|R], V, S) :-
    (   V0 == V -> S = S0 ; flow_st_find(R, V, S) ).

flow_st_del([], _, []).
flow_st_del([V0-S0|R], V, Out) :-
    (   V0 == V -> Out = R ; Out = [V0-S0|Out1], flow_st_del(R, V, Out1) ).

flow_raise_list([], _, St, St).
flow_raise_list([V|Vs], S, St0, St) :-
    flow_st_get(St0, V, Old),
    flow_max_state(Old, S, New),
    (   New == Old -> St1 = St0 ; flow_st_del(St0, V, St2), St1 = [V-New|St2] ),
    flow_raise_list(Vs, S, St1, St).

flow_raise_term(T, S, St0, St) :-
    term_variables(T, Vs),
    flow_raise_list(Vs, S, St0, St).

flow_max_state(A, B, M) :-
    flow_rank(A, RA),
    flow_rank(B, RB),
    (   RA >= RB -> M = A ; M = B ).

flow_rank(f, 0).
flow_rank(p, 1).
flow_rank(b, 2).

flow_all_state([], _, _).
flow_all_state([V|Vs], St, S) :-
    flow_st_get(St, V, S0),
    S0 == S,
    flow_all_state(Vs, St, S).

flow_any_not_free([V|Vs], St) :-
    (   flow_st_get(St, V, S), S \== f -> true ; flow_any_not_free(Vs, St) ).

flow_arg_modes([], _, []).
flow_arg_modes([A|As], St, [M|Ms]) :-
    flow_arg_mode(A, St, M),
    flow_arg_modes(As, St, Ms).

flow_arg_mode(A, St, M) :-
    term_variables(A, Vs),
    (   Vs == [] -> M = '+'
    ;   flow_all_state(Vs, St, b) -> M = '+'
    ;   var(A), flow_st_get(St, A, f) -> M = '-'
    ;   M = '?'
    ).

flow_head_state(H, CM, St) :-
    H =.. [_|Args],
    flow_head_pass(Args, CM, '+', b, [], St1),
    flow_head_pass(Args, CM, ':', b, St1, St2),
    flow_head_pass(Args, CM, '?', p, St2, St).

flow_head_pass([], _, _, _, St, St).
flow_head_pass([A|As], [M|Ms], Which, S, St0, St) :-
    (   M == Which -> flow_raise_term(A, S, St0, St1) ; St1 = St0 ),
    flow_head_pass(As, Ms, Which, S, St1, St).

%% a head can fail to unify when an input position holds a pattern
flow_head_can_fail(H, CM, HF) :-
    H =.. [_|Args],
    (   flow_pattern_input(Args, CM) -> HF = true ; HF = false ).

flow_pattern_input([A|As], [M|Ms]) :-
    (   M \== '-', nonvar(A) -> true ; flow_pattern_input(As, Ms) ).

flow_join(S1, S2, S) :-
    flow_keys(S1, K1),
    flow_keys(S2, K2),
    flow_union_vars(K1, K2, Ks),
    flow_join_vars(Ks, S1, S2, S).

flow_keys([], []).
flow_keys([V-_|T], [V|Vs]) :- flow_keys(T, Vs).

flow_union_vars(A, [], A).
flow_union_vars(A, [V|Vs], U) :-
    (   flow_var_in(V, A) -> flow_union_vars(A, Vs, U) ; flow_union_vars([V|A], Vs, U) ).

flow_var_in(V, [W|Ws]) :-
    (   V == W -> true ; flow_var_in(V, Ws) ).

flow_join_vars([], _, _, []).
flow_join_vars([V|Vs], S1, S2, [V-S|R]) :-
    flow_st_get(S1, V, A),
    flow_st_get(S2, V, B),
    (   A == B -> S = A ; S = p ),
    flow_join_vars(Vs, S1, S2, R).

flow_join_all([], St, St).
flow_join_all([S|Ss], _, St) :- flow_join_all_(Ss, S, St).

flow_join_all_([], St, St).
flow_join_all_([S|Ss], Acc, St) :- flow_join(Acc, S, Acc1), flow_join_all_(Ss, Acc1, St).

%% ---- the body, goal by goal ------------------------------------------

flow_an_seq(B, St0, St, Ctx, M0, M, Nodes) :-
    flow_conj(B, Goals),
    flow_an_goals(Goals, St0, St, Ctx, M0, M, Nodes).

flow_conj(V, [V]) :- var(V), !.
flow_conj((A, B), Gs) :- !,
    flow_conj(A, Ga),
    flow_conj(B, Gb),
    append(Ga, Gb, Gs).
flow_conj(true, []) :- !.
flow_conj(G, [G]).

flow_an_goals([], St, St, _, M, M, []).
flow_an_goals([G|Gs], St0, St, Ctx, M0, M, Nodes) :-
    flow_an_item(G, St0, St1, Ctx, M0, M1, Ns),
    flow_an_goals(Gs, St1, St, Ctx, M1, M, Rest),
    append(Ns, Rest, Nodes).

flow_an_item(V, St, St, _, M, M, [g(call(V), closure, ['?'], semidet, none)]) :- var(V), !.
flow_an_item(_:G, St0, St, Ctx, M0, M, Ns) :- !,
    flow_an_item(G, St0, St, Ctx, M0, M, Ns).
flow_an_item(!, St, St, _, M, M, [cut]) :- !.
flow_an_item(fail, St, St, _, M, M, [failn]) :- !.
flow_an_item(false, St, St, _, M, M, [failn]) :- !.
flow_an_item(throw(E), St, St, _, M, M, [thrown(E)]) :- !.
flow_an_item((C -> T ; E), St0, St, Ctx, M0, M, [ite(hard, Arms, Else)]) :- !,
    flow_an_ite((C -> T ; E), St0, St, Ctx, M0, M, Arms, Else).
flow_an_item((C *-> T ; E), St0, St, Ctx, M0, M, [ite(soft, [arm(Cn, Tn)], En)]) :- !,
    flow_an_seq(C, St0, St1, Ctx, M0, M1, Cn),
    flow_an_seq(T, St1, StT, Ctx, M1, M2, Tn),
    flow_an_seq(E, St0, StE, Ctx, M2, M, En),
    flow_join(StT, StE, St).
flow_an_item((A ; B), St0, St, Ctx, M0, M, [or(Branches)]) :- !,
    flow_disj((A ; B), Ds),
    flow_an_branches(Ds, St0, Sts, Ctx, M0, M, Branches),
    flow_join_all(Sts, St0, St).
flow_an_item((C -> T), St0, St, Ctx, M0, M, [ite(hard, [arm(Cn, Tn)], none)]) :- !,
    flow_an_seq(C, St0, St1, Ctx, M0, M1, Cn),
    flow_an_seq(T, St1, St, Ctx, M1, M, Tn).
flow_an_item(\+ G, St, St, Ctx, M0, M, [not(Ns)]) :- !,
    flow_an_seq(G, St, _, Ctx, M0, M, Ns).
flow_an_item(not(G), St, St, Ctx, M0, M, [not(Ns)]) :- !,
    flow_an_seq(G, St, _, Ctx, M0, M, Ns).
flow_an_item(findall(T, G, L), St0, St, Ctx, M0, M, [meta(findall, findall(T, '…', L), [MT, ':', ML], [Ns])]) :- !,
    flow_an_seq(G, St0, _, Ctx, M0, M, Ns),
    flow_arg_mode(T, St0, MT0), flow_meta_template(MT0, MT),
    flow_arg_mode(L, St0, ML),
    flow_raise_term(L, b, St0, St).
flow_an_item(findall(T, G, L, R), St0, St, Ctx, M0, M, [meta(findall, findall(T, '…', L, R), [MT, ':', ML, MR], [Ns])]) :- !,
    flow_an_seq(G, St0, _, Ctx, M0, M, Ns),
    flow_arg_mode(T, St0, MT0), flow_meta_template(MT0, MT),
    flow_arg_mode(L, St0, ML),
    flow_arg_mode(R, St0, MR),
    flow_raise_term(L, p, St0, St).
flow_an_item(aggregate_all(Spec, G, R), St0, St, Ctx, M0, M, [meta(aggregate_all, aggregate_all(Spec, '…', R), ['?', ':', MR], [Ns])]) :- !,
    flow_an_seq(G, St0, _, Ctx, M0, M, Ns),
    flow_arg_mode(R, St0, MR),
    flow_raise_term(R, b, St0, St).
flow_an_item(forall(C, A), St, St, Ctx, M0, M, [meta(forall, forall('…', '…'), [':', ':'], [Ns])]) :- !,
    flow_an_seq((C, A), St, _, Ctx, M0, M, Ns).
flow_an_item(once(G), St0, St, Ctx, M0, M, [meta(once, once('…'), [':'], [Ns])]) :- !,
    flow_an_seq(G, St0, St, Ctx, M0, M, Ns).
flow_an_item(ignore(G), St0, St, Ctx, M0, M, [meta(ignore, ignore('…'), [':'], [Ns])]) :- !,
    flow_an_seq(G, St0, St1, Ctx, M0, M, Ns),
    flow_join(St0, St1, St).
flow_an_item(catch(G, Ball, R), St0, St, Ctx, M0, M, [catchc(Gn, Ball, Rn)]) :- !,
    flow_an_seq(G, St0, St1, Ctx, M0, M1, Gn),
    flow_an_seq(R, St0, St2, Ctx, M1, M, Rn),
    flow_join(St1, St2, St).
flow_an_item(call(G), St0, St, Ctx, M0, M, Ns) :- nonvar(G), !,
    flow_an_item(G, St0, St, Ctx, M0, M, Ns).
flow_an_item(G, St0, St, Ctx, M0, M, [g(G, Kind, Ms, Det, N/A)]) :-
    flow_kind(G, Ctx, Kind),
    functor(G, N, A),
    G =.. [_|Args],
    flow_arg_modes(Args, St0, Ms),
    flow_effect(Kind, N/A, Args, Ms, St0, St, Ctx, M0, M, Det).

flow_meta_template('+', '+') :- !.
flow_meta_template(_, '?').

flow_an_ite((C -> T ; E), St0, St, Ctx, M0, M, [arm(Cn, Tn)|Arms], Else) :-
    flow_an_seq(C, St0, St1, Ctx, M0, M1, Cn),
    flow_an_seq(T, St1, StT, Ctx, M1, M2, Tn),
    (   nonvar(E), E = (C2 -> T2 ; E2)
    ->  flow_an_ite((C2 -> T2 ; E2), St0, StE, Ctx, M2, M, Arms, Else)
    ;   Arms = [],
        flow_an_seq(E, St0, StE, Ctx, M2, M, Else)
    ),
    flow_join(StT, StE, St).

flow_disj(V, [V]) :- var(V), !.
flow_disj((A ; B), Ds) :-
    \+ ( nonvar(A), A = (_ -> _) ),
    \+ ( nonvar(A), A = (_ *-> _) ), !,
    flow_disj(A, Da),
    flow_disj(B, Db),
    append(Da, Db, Ds).
flow_disj(G, [G]).

flow_an_branches([], _, [], _, M, M, []).
flow_an_branches([D|Ds], St0, [S|Ss], Ctx, M0, M, [Ns|Nss]) :-
    flow_an_seq(D, St0, S, Ctx, M0, M1, Ns),
    flow_an_branches(Ds, St0, Ss, Ctx, M1, M, Nss).

%% what a goal binds, and how it can end
flow_effect(test, _, _, _, St, St, _, M, M, semidet) :- !.
flow_effect(unify, _, [X, Y], _, St0, St, _, M, M, Det) :- !,
    (   flow_fresh_side(X, Y, St0) -> Det = det ; Det = semidet ),
    flow_unify_effect(X, Y, St0, St).
flow_effect(portal(Mod), N/A, Args, _, St0, St, ctx(_, Dir, _), M, M, semidet) :- !,
    (   flow_portal(Mod, N, A, Dir, info(_, _, _, DMs, _)) -> true
    ;   length(DMs, A), flow_fill(DMs, '?')
    ),
    flow_apply_modes(Args, DMs, St0, St).
flow_effect(user, Key, Args, Ms, St0, St, Ctx, M0, M, Det) :- !,
    flow_success(Key, user, Ms, Ctx, M0, M, SP, Det),
    flow_apply_sp(Args, SP, St0, St).
flow_effect(_, N/A, Args, Ms, St0, St, _, M, M, Det) :-
    flow_mode_for(N, A, Ms, DMs, Det), !,
    flow_apply_modes(Args, DMs, St0, St).
flow_effect(library(L), Key, Args, Ms, St0, St, Ctx, M0, M, Det) :- !,
    flow_success(Key, library(L), Ms, Ctx, M0, M, SP, Det),
    flow_apply_sp(Args, SP, St0, St).
flow_effect(_, _, Args, _, St0, St, _, M, M, semidet) :-
    flow_raise_args(Args, p, St0, St).

%% X = Y cannot fail when one side is a variable nothing has touched yet
flow_fresh_side(X, Y, St) :-
    (   var(X), flow_st_get(St, X, f), \+ flow_occurs(X, Y) -> true
    ;   var(Y), flow_st_get(St, Y, f), \+ flow_occurs(Y, X)
    ).

flow_occurs(V, T) :-
    term_variables(T, Vs),
    flow_var_in(V, Vs).

flow_unify_effect(X, Y, St0, St) :-
    term_variables(X, VX),
    term_variables(Y, VY),
    (   flow_all_state(VY, St0, b) -> flow_raise_list(VX, b, St0, St)
    ;   flow_all_state(VX, St0, b) -> flow_raise_list(VY, b, St0, St)
    ;   append(VX, VY, V), flow_raise_list(V, p, St0, St)
    ).

flow_apply_modes([], _, St, St).
flow_apply_modes([A|As], [M|Ms], St0, St) :-
    (   ( M == '-' ; M == '?' ) -> flow_raise_term(A, b, St0, St1) ; St1 = St0 ),
    flow_apply_modes(As, Ms, St1, St).

flow_apply_sp([], _, St, St).
flow_apply_sp([A|As], [S|Ss], St0, St) :-
    (   S == f -> St1 = St0 ; flow_raise_term(A, S, St0, St1) ),
    flow_apply_sp(As, Ss, St1, St).

flow_raise_args([], _, St, St).
flow_raise_args([A|As], S, St0, St) :-
    flow_raise_term(A, S, St0, St1),
    flow_raise_args(As, S, St1, St).

%% a predicate's success pattern for one call pattern, remembered
flow_success(Key, Kind, CM, Ctx, M0, M, SP, Det) :-
    MK = Key-CM,
    (   get_assoc(MK, M0, V)
    ->  M = M0,
        (   V = done(SP, Det) -> true
        ;   length(CM, Ar), length(SP, Ar), flow_fill(SP, b), Det = semidet
        )
    ;   put_assoc(MK, M0, busy, M1),
        flow_clauses(Key, Kind, Ctx, Cls),
        flow_success_cls(Cls, CM, Ctx, M1, M2, SPs, NLs),
        length(CM, Ar),
        flow_combine_sps(SPs, Ar, SP),
        flow_pred_det(Cls, NLs, CM, Det),
        put_assoc(MK, M2, done(SP, Det), M)
    ).

flow_success_cls([], _, _, M, M, [], []).
flow_success_cls([cl(H, B, _)|Cs], CM, Ctx, M0, M, SPs, [Nodes|NLs]) :-
    flow_head_state(H, CM, St0),
    flow_an_seq(B, St0, St, Ctx, M0, M1, Nodes),
    (   memberchk(failn, Nodes) -> SPs = SPs1
    ;   flow_clause_sp(H, St, SP), SPs = [SP|SPs1]
    ),
    flow_success_cls(Cs, CM, Ctx, M1, M, SPs1, NLs).

flow_combine_sps([], Ar, SP) :- length(SP, Ar), flow_fill(SP, f).
flow_combine_sps([S|Ss], _, SP) :- flow_meet_all(Ss, S, SP).

flow_meet_all([], S, S).
flow_meet_all([S|Ss], Acc, SP) :- flow_meet(S, Acc, Acc1), flow_meet_all(Ss, Acc1, SP).

flow_meet([], [], []).
flow_meet([A|As], [B|Bs], [C|Cs]) :-
    (   A == B -> C = A ; C = p ),
    flow_meet(As, Bs, Cs).

flow_clause_sp(H, St, SP) :-
    H =.. [_|Args],
    flow_args_final(Args, St, SP).

flow_args_final([], _, []).
flow_args_final([A|As], St, [S|Ss]) :-
    term_variables(A, Vs),
    flow_vars_final(Vs, St, S),
    flow_args_final(As, St, Ss).

flow_vars_final([], _, b) :- !.
flow_vars_final(Vs, St, S) :-
    (   flow_all_state(Vs, St, b) -> S = b
    ;   flow_any_not_free(Vs, St) -> S = p
    ;   S = f
    ).

%% ---- determinism: does a call leave a choice point? -------------------

%% Read off the clauses' analysed goals (NLs, a node list per clause): a
%% choice left after a clause's last cut makes it nondet, and it is det
%% when no clause that can be reached can fail.
flow_pred_det([], _, _, semidet) :- !.
flow_pred_det(Cls, NLs, CM, Det) :-
    (   flow_alternatives(Cls, CM) -> Det = nondet
    ;   flow_late_choice(NLs) -> Det = nondet
    ;   flow_pred_total(Cls, NLs, CM) -> Det = det
    ;   Det = semidet
    ).

%% one clause that cannot fail; or clauses committed by their cuts, each
%% unable to fail once past its cut, and a last that cannot fail at all
flow_pred_total(Cls, NLs, CM) :-
    append(Init, [cl(H, _, _)], Cls),
    append(InitNs, [LastNs], NLs),
    flow_head_can_fail(H, CM, false),
    flow_nodes_total(LastNs),
    (   Init == [] -> true ; flow_committed(Cls) ),
    forall(member(Ns, InitNs), ( flow_after_cut(Ns, After), flow_nodes_total(After) )).

flow_late_choice(NLs) :-
    member(Ns, NLs),
    flow_after_cut(Ns, After),
    member(N, After),
    flow_node_nondet(N), !.

flow_after_cut(Ns, After) :-
    (   append(_, [cut|R], Ns), \+ memberchk(cut, R) -> After = R ; After = Ns ).

flow_nodes_total(Ns) :-
    forall(member(N, Ns), flow_node_total(N)).

%% a goal that cannot fail the first time it runs -- the drawing's CF false
flow_node_total(g(_, _, _, det, _)) :- !.
flow_node_total(cut) :- !.
flow_node_total(thrown(_)) :- !.
flow_node_total(meta(Name, Head, Ms, Ts)) :- !,
    flow_meta_can_fail(Name, Head, Ms, Ts, false).
flow_node_total(ite(_, Arms, Else)) :- !,
    Else \== none,
    flow_nodes_total(Else),
    forall(member(arm(_, T), Arms), flow_nodes_total(T)).
flow_node_total(or(Bs)) :- !,
    member(B, Bs), flow_nodes_total(B), !.
flow_node_total(catchc(G, _, R)) :-
    flow_nodes_total(G),
    flow_nodes_total(R).

flow_nodes_nondet(Ns) :-
    member(N, Ns), flow_node_nondet(N), !.

%% a goal that can leave a choice point behind
flow_node_nondet(g(_, _, _, nondet, _)) :- !.
flow_node_nondet(or(_)) :- !.
flow_node_nondet(ite(soft, [arm(C, _)], _)) :- flow_nodes_nondet(C), !.
flow_node_nondet(ite(_, Arms, Else)) :- !,
    (   member(arm(_, T), Arms), flow_nodes_nondet(T) -> true
    ;   Else \== none, flow_nodes_nondet(Else)
    ).
flow_node_nondet(catchc(G, _, R)) :-
    (   flow_nodes_nondet(G) -> true ; flow_nodes_nondet(R) ).

%% findall/3,4 fails only on a list it is handed; aggregate_all/3 on a
%% result it is handed, or for max or min of nothing; forall/2 on a
%% counter-example; ignore/1 never; once/1 as its goal does
flow_meta_can_fail(findall, _, Ms, _, CF) :- !,
    (   Ms = [_, _, '-'|_] -> CF = false ; CF = true ).
flow_meta_can_fail(aggregate_all, aggregate_all(Spec, _, _), [_, _, MR], _, CF) :- !,
    (   MR == '-', nonvar(Spec), \+ flow_agg_partial(Spec) -> CF = false ; CF = true ).
flow_meta_can_fail(forall, _, _, _, true) :- !.
flow_meta_can_fail(ignore, _, _, _, false) :- !.
flow_meta_can_fail(_, _, _, [Ns], CF) :-
    (   flow_nodes_total(Ns) -> CF = false ; CF = true ).

flow_agg_partial(max(_)).
flow_agg_partial(min(_)).
flow_agg_partial(max(_, _)).
flow_agg_partial(min(_, _)).

flow_alternatives(Cls, CM) :-
    Cls = [_, _|_],
    \+ flow_indexed(Cls, CM),
    \+ flow_committed(Cls).

%% every clause but the last cuts: once one passes its cut, none is left
flow_committed(Cls) :-
    append(Init, [_], Cls),
    Init \== [],
    forall(member(cl(_, B, _), Init), flow_has_cut(B)).

flow_has_cut(B) :-
    flow_conj(B, Gs),
    memberchk(!, Gs).

%% a bound argument whose patterns all differ picks at most one clause
flow_indexed(Cls, CM) :-
    nth1(I, CM, '+'),
    flow_arg_keys(Cls, I, Keys),
    length(Keys, N),
    sort(Keys, Set),
    length(Set, N), !.

flow_arg_keys([], _, []).
flow_arg_keys([cl(H, _, _)|Cs], I, [K|Ks]) :-
    arg(I, H, A),
    nonvar(A),
    flow_key(A, K),
    flow_arg_keys(Cs, I, Ks).

flow_key(A, K) :-
    (   compound(A) -> functor(A, N, Ar), K = N/Ar ; K = A ).


%% ======================================================================
%% Text: terms written with their own variable names
%% ======================================================================
%%
%% write_term/2's variable_names is not honoured by cocolog, and the chart
%% needs each argument on its own anyway, to colour it by its mode -- so
%% the terms are written here, by a grammar over the term.

flow_term_text(T, Names, Prec, A) :-
    flow_term_full(T, Names, Prec, A0),
    flow_clip(A0, 26, A).

flow_term_full(T, Names, Prec, A) :-
    phrase(flow_t(T, Names, Prec), Cs),
    atom_codes(A, Cs).

flow_t(V, Names, _) --> { var(V) }, !, flow_tv(V, Names).
flow_t(N, _, _) --> { number(N) }, !, { number_codes(N, Cs) }, flow_codes(Cs).
flow_t('…', _, _) --> !, { atom_codes('…', Cs) }, flow_codes(Cs).
flow_t(A, _, _) --> { atom(A) }, !, flow_ta(A).
flow_t(T, _, _) --> { flow_is_text(T) }, !, "\"", flow_codes(T), "\"".
flow_t([H|T], Names, _) --> !, "[", flow_t(H, Names, 999), flow_tl(T, Names), "]".
flow_t({X}, Names, _) --> !, "{", flow_t(X, Names, 1200), "}".
flow_t(T, Names, P) --> { T =.. [F, L, R], flow_infix(F, OP, LP, RP) }, !,
    flow_open(OP, P),
    flow_t(L, Names, LP),
    { flow_infix_text(F, OT), atom_codes(OT, OCs) },
    flow_codes(OCs),
    flow_t(R, Names, RP),
    flow_close(OP, P).
flow_t(T, Names, P) --> { T =.. [F, X], flow_prefix(F, OP, XP) }, !,
    flow_open(OP, P),
    flow_ta(F),
    flow_prefix_gap(F),
    flow_t(X, Names, XP),
    flow_close(OP, P).
flow_t(T, Names, _) --> { T =.. [F|Args] }, flow_ta(F), "(", flow_targs(Args, Names), ")".

flow_tl(T, _) --> { T == [] }, !, [].
flow_tl(T, Names) --> { var(T) }, !, "|", flow_tv(T, Names).
flow_tl([H|T], Names) --> !, ", ", flow_t(H, Names, 999), flow_tl(T, Names).
flow_tl(T, Names) --> "|", flow_t(T, Names, 999).

flow_targs([A], Names) --> !, flow_t(A, Names, 999).
flow_targs([A|As], Names) --> flow_t(A, Names, 999), ", ", flow_targs(As, Names).

flow_open(OP, P) --> { OP > P }, !, "(".
flow_open(_, _) --> [].

flow_close(OP, P) --> { OP > P }, !, ")".
flow_close(_, _) --> [].

flow_tv(V, Names) --> { flow_var_name(V, Names, N), atom_codes(N, Cs) }, !, flow_codes(Cs).
flow_tv(_, _) --> "_".

flow_ta(A) --> { format(atom(Q), '~q', [A]), atom_codes(Q, Cs) }, flow_codes(Cs).

flow_codes([]) --> [].
flow_codes([C|Cs]) --> [C], flow_codes(Cs).

flow_prefix_gap(F) --> { atom_codes(F, [C|_]), C >= 0'a, C =< 0'z }, !, " ".
flow_prefix_gap('\\+') --> !, " ".
flow_prefix_gap(_) --> [].

flow_is_text(T) :-
    is_list(T),
    T = [_|_],
    flow_printable(T).

flow_printable([]).
flow_printable([C|Cs]) :-
    integer(C), C >= 32, C =< 126, C =\= 34, C =\= 92,
    flow_printable(Cs).

flow_op(':-', xfx, 1200).
flow_op('-->', xfx, 1200).
flow_op(';', xfy, 1100).
flow_op('|', xfy, 1100).
flow_op('->', xfy, 1050).
flow_op('*->', xfy, 1050).
flow_op(',', xfy, 1000).
flow_op('=', xfx, 700).
flow_op('\\=', xfx, 700).
flow_op('==', xfx, 700).
flow_op('\\==', xfx, 700).
flow_op('@<', xfx, 700).
flow_op('@>', xfx, 700).
flow_op('@=<', xfx, 700).
flow_op('@>=', xfx, 700).
flow_op('=..', xfx, 700).
flow_op(is, xfx, 700).
flow_op('=:=', xfx, 700).
flow_op('=\\=', xfx, 700).
flow_op('<', xfx, 700).
flow_op('>', xfx, 700).
flow_op('=<', xfx, 700).
flow_op('>=', xfx, 700).
flow_op('+', yfx, 500).
flow_op('-', yfx, 500).
flow_op('/\\', yfx, 500).
flow_op('\\/', yfx, 500).
flow_op(xor, yfx, 500).
flow_op('*', yfx, 400).
flow_op('/', yfx, 400).
flow_op('//', yfx, 400).
flow_op(mod, yfx, 400).
flow_op(rem, yfx, 400).
flow_op(div, yfx, 400).
flow_op('<<', yfx, 400).
flow_op('>>', yfx, 400).
flow_op('**', xfx, 200).
flow_op('^', xfy, 200).
flow_op(':', xfy, 200).

flow_infix(F, P, LP, RP) :-
    flow_op(F, Type, P),
    flow_op_sides(Type, P, LP, RP).

flow_op_sides(xfx, P, L, R) :- L is P - 1, R is P - 1.
flow_op_sides(xfy, P, L, P) :- L is P - 1.
flow_op_sides(yfx, P, P, R) :- R is P - 1.

flow_infix_text(',', ', ') :- !.
flow_infix_text(':', ':') :- !.
flow_infix_text(F, T) :- atomic_list_concat([' ', F, ' '], T).

flow_prefix('\\+', 900, 900).
flow_prefix('-', 200, 200).
flow_prefix('\\', 200, 200).

%% ---- widths -----------------------------------------------------------
%%
%% Code is drawn in a monospace font at 12px, 7.2px a character, so a
%% width is a count. atom_codes/2 answers UTF-8 BYTES, so a character is
%% every byte that is not a continuation byte.

flow_chars(A, N) :-
    atom_codes(A, Cs),
    flow_count_chars(Cs, 0, N).

flow_count_chars([], N, N).
flow_count_chars([C|Cs], N0, N) :-
    (   C >= 128, C < 192 -> N1 = N0 ; N1 is N0 + 1 ),
    flow_count_chars(Cs, N1, N).

flow_text_w(Chars, W) :- W is (Chars * 72 + 9) // 10.

flow_segs_chars([], 0).
flow_segs_chars([s(T, _)|Ss], N) :-
    flow_chars(T, N1),
    flow_segs_chars(Ss, N2),
    N is N1 + N2.

flow_segs_w(Ss, W) :-
    flow_segs_chars(Ss, N),
    flow_text_w(N, W).

flow_clip(A, Max, C) :-
    flow_chars(A, N),
    (   N =< Max -> C = A
    ;   atom_codes(A, Cs),
        K is Max - 1,
        flow_take_chars(Cs, K, T),
        atom_codes(T0, T),
        atom_concat(T0, '…', C)
    ).

flow_take_chars([], _, []).
flow_take_chars([C|Cs], K, Out) :-
    (   C >= 128, C < 192 -> Out = [C|R], flow_take_chars(Cs, K, R)
    ;   K =:= 0 -> Out = []
    ;   K1 is K - 1, Out = [C|R], flow_take_chars(Cs, K1, R)
    ).

%% a goal as coloured segments: each argument in the colour of its mode
flow_goal_segs(G, Ms, Names, Segs) :-
    G =.. [F|Args],
    (   Args = [L, R], flow_infix(F, P, LP, RP), P >= 700, Ms = [ML, MR]
    ->  flow_term_text(L, Names, LP, LT),
        flow_term_text(R, Names, RP, RT),
        flow_infix_text(F, OT),
        Segs = [s(LT, m(ML)), s(OT, ink), s(RT, m(MR))]
    ;   format(atom(FA), '~q', [F]),
        (   Args == [] -> Segs = [s(FA, ink)]
        ;   flow_args_segs(Args, Ms, Names, ASegs),
            append([s(FA, ink), s('(', ink)|ASegs], [s(')', ink)], Segs)
        )
    ).

flow_args_segs([A], [M], Names, [s(T, m(M))]) :- !,
    flow_term_text(A, Names, 999, T).
flow_args_segs([A|As], [M|Ms], Names, [s(T, m(M)), s(', ', ink)|R]) :-
    flow_term_text(A, Names, 999, T),
    flow_args_segs(As, Ms, Names, R).

%% a predicate as called: report(+Pat, +Text, +Nums)
flow_moded_head(G, CM, Names, Segs) :-
    G =.. [F|Args],
    format(atom(FA), '~q', [F]),
    (   Args == [] -> Segs = [s(FA, ink)]
    ;   flow_moded_args(Args, CM, Names, ASegs),
        append([s(FA, ink), s('(', ink)|ASegs], [s(')', ink)], Segs)
    ).

flow_moded_args([A], [M], Names, [s(T, m(M))]) :- !,
    flow_moded_arg(A, M, Names, T).
flow_moded_args([A|As], [M|Ms], Names, [s(T, m(M)), s(', ', ink)|R]) :-
    flow_moded_arg(A, M, Names, T),
    flow_moded_args(As, Ms, Names, R).

flow_moded_arg(A, M, Names, T) :-
    (   var(A), flow_var_name(A, Names, N) -> atom_concat(M, N, T)
    ;   flow_term_text(A, Names, 999, T0), atom_concat(M, T0, T)
    ).

flow_panel_head(Key, CM, Rows, Docs, Segs) :-
    flow_names_for(Key, Docs, Rows, G, Names),
    flow_moded_head(G, CM, Names, Segs).

flow_lib_name(F, N) :-
    atom_codes(F, Cs),
    (   append(_, [47|R], Cs), \+ memberchk(47, R) -> true ; R = Cs ),
    (   append(B, [46|_], R) -> true ; B = R ),
    atom_codes(N, B).

%% ======================================================================
%% Measuring: every item knows its width and how far it reaches above
%% and below the main line it sits on
%% ======================================================================
%%
%%   mg(Kind, Segs, Badge, ND, CF, W, Tip)   a goal
%%   mhead(Segs, HF, W, Tip)                  a clause head
%%   mcut | mfail(W) | mthrow(Segs, W)
%%   mframe(Items, W, A, D)                   an if-then-else's condition
%%   mcon(Type, Label, Tracks, W, A, D, CF, ND)   a construct of tracks
%%
%% CF: the item can fail. ND: it can leave a choice point to come back to.

flow_m_list([], _, []).
flow_m_list([N|Ns], LC, [I|Is]) :-
    flow_m(N, LC, I),
    flow_m_list(Ns, LC, Is).

flow_m_lists([], _, []).
flow_m_lists([L|Ls], LC, [I|Is]) :-
    flow_m_list(L, LC, I),
    flow_m_lists(Ls, LC, Is).

flow_m(g(G, Kind, Ms, Det, Key), LC, mg(Kind, Segs, Badge, ND, CF, W, Tip)) :- !,
    LC = lc(Names, Ids, Self),
    flow_goal_segs(G, Ms, Names, Segs),
    flow_badge(Kind, Key, Ids, Self, Badge),
    flow_det_flags(Det, CF, ND),
    flow_segs_w(Segs, TW),
    flow_badge_w(Badge, BW),
    (   ND == true -> NW = 13 ; NW = 0 ),
    (   Kind == test -> HW = 12 ; HW = 0 ),
    (   Kind = portal(_) -> PW = 17 ; PW = 0 ),
    W is 18 + TW + NW + BW + HW + PW,
    flow_tip(G, Kind, Det, Names, Tip).
flow_m(cut, _, mcut) :- !.
flow_m(failn, _, mfail(W)) :- !,
    flow_text_w(4, TW),
    W is TW + 18.
flow_m(thrown(E), lc(Names, _, _), mthrow(Segs, W)) :- !,
    flow_term_text(E, Names, 999, T),
    Segs = [s('throw(', ink), s(T, m('+')), s(')', ink)],
    flow_segs_w(Segs, TW),
    W is TW + 18.
flow_m(ite(Soft, Arms, Else), LC, mcon(ite, Label, Tracks, W, A, D, CF, ND)) :- !,
    (   Soft == soft -> Label = lbl('if  *->  then  ;  else') ; Label = lbl('if  ->  then  ;  else') ),
    flow_m_arms(Arms, LC, ArmTracks),
    (   Else == none -> Rest = [] ; flow_m_list(Else, LC, EIs), Rest = [EIs] ),
    append(ArmTracks, Rest, TrackItems),
    flow_tracks(TrackItems, 0, 26, Tracks),
    flow_con_size(Tracks, Label, W, A, D),
    flow_tracks_flags(Tracks, CF0, ND),
    (   Else == none -> CF = true ; CF = CF0 ).
flow_m(or(Bs), LC, mcon(or, Label, Tracks, W, A, D, true, true)) :- !,
    Label = lbl('or  ;   each branch in turn'),
    flow_m_lists(Bs, LC, TIs),
    flow_tracks(TIs, 14, 0, Tracks),
    flow_con_size(Tracks, Label, W, A, D).
flow_m(not(Ns), LC, mcon(not, Label, Tracks, W, A, D, true, false)) :- !,
    Label = lbl('\\+   succeeds when this fails'),
    flow_m_list(Ns, LC, Is),
    flow_tracks([Is], 0, 0, Tracks),
    flow_con_size(Tracks, Label, W, A, D).
flow_m(meta(Name, Head, Ms, Ts), LC, mcon(meta, segs(Segs), Tracks, W, A, D, CF, ND)) :- !,
    LC = lc(Names, _, _),
    flow_goal_segs(Head, Ms, Names, Segs0),
    flow_meta_note(Name, Note),
    append(Segs0, [s(Note, muted)], Segs),
    flow_m_lists(Ts, LC, TIs),
    flow_tracks(TIs, 0, 0, Tracks),
    flow_con_size(Tracks, segs(Segs), W, A, D),
    flow_meta_can_fail(Name, Head, Ms, Ts, CF),
    ND = false.
flow_m(catchc(G, Ball, R), LC, mcon(catch, segs(Segs), Tracks, W, A, D, CF, ND)) :- !,
    LC = lc(Names, _, _),
    flow_term_text(Ball, Names, 999, BT),
    Segs = [s('catch(…, ', ink), s(BT, m('?')), s(', …)', ink)],
    flow_m_list(G, LC, GIs),
    flow_m_list(R, LC, RIs),
    flow_tracks([GIs, RIs], 0, 26, Tracks),
    flow_con_size(Tracks, segs(Segs), W, A, D),
    flow_tracks_flags(Tracks, CF, ND).

flow_meta_note(findall, '    every solution').
flow_meta_note(aggregate_all, '    every solution').
flow_meta_note(forall, '    for every one').
flow_meta_note(once, '    the first solution').
flow_meta_note(ignore, '    never fails').

flow_m_arms([], _, []).
flow_m_arms([arm(C, T)|As], LC, [[F|TIs]|Ts]) :-
    flow_m_list(C, LC, CIs),
    flow_track_size(CIs, CW, CA, CD),
    FW is CW + 16, FA is CA + 13, FD is CD + 6,
    F = mframe(CIs, FW, FA, FD),
    flow_m_list(T, LC, TIs),
    flow_m_arms(As, LC, Ts).

%% a track: t(Offset, Items, Width, Ascent, Descent)
flow_tracks([], _, _, []).
flow_tracks([Is|Iss], Off, Step, [t(Off, Is, TW, TA, TD)|Ts]) :-
    flow_track_size(Is, TW, TA, TD),
    Off1 is Off + Step,
    flow_tracks(Iss, Off1, Step, Ts).

flow_track_size([], 24, 13, 13) :- !.
flow_track_size(Is, TW, TA, TD) :-
    flow_items_size(Is, 0, W0, 13, TA, 13, TD),
    length(Is, N),
    TW is W0 + 22 * (N - 1).

flow_items_size([], W, W, A, A, D, D).
flow_items_size([I|Is], W0, W, A0, A, D0, D) :-
    flow_size(I, IW, IA, ID),
    W1 is W0 + IW,
    A1 is max(A0, IA),
    D1 is max(D0, ID),
    flow_items_size(Is, W1, W, A1, A, D1, D).

flow_con_size(Tracks, Label, W, A, D) :-
    Tracks = [t(_, _, _, A1, D1)|Rest],
    flow_tracks_maxw(Tracks, 0, MW),
    flow_label_w(Label, LW),
    W is max(12 + MW + 24, LW + 20),
    A is 19 + A1,
    flow_rest_h(Rest, 0, RH),
    D is D1 + RH + 9.

flow_tracks_maxw([], M, M).
flow_tracks_maxw([t(Off, _, TW, _, _)|Ts], M0, M) :-
    M1 is max(M0, Off + TW),
    flow_tracks_maxw(Ts, M1, M).

flow_rest_h([], H, H).
flow_rest_h([t(_, _, _, A, D)|Ts], H0, H) :-
    H1 is H0 + 16 + A + D,
    flow_rest_h(Ts, H1, H).

flow_label_w(lbl(A), W) :- flow_chars(A, N), W is (N * 62 + 9) // 10.
flow_label_w(segs(Ss), W) :- flow_segs_chars(Ss, N), W is (N * 66 + 9) // 10.

flow_tracks_flags(Tracks, CF, ND) :-
    (   member(t(_, Is, _, _, _), Tracks), member(I, Is), flow_flags(I, true, _) -> CF = true ; CF = false ),
    (   member(t(_, Is2, _, _, _), Tracks), member(I2, Is2), flow_flags(I2, _, true) -> ND = true ; ND = false ).

flow_flags(mg(_, _, _, ND, CF, _, _), CF, ND).
flow_flags(mhead(_, HF, _, _), HF, false).
flow_flags(mcut, false, false).
flow_flags(mfail(_), true, false).
flow_flags(mthrow(_, _), false, false).
flow_flags(mframe(_, _, _, _), false, false).
flow_flags(mcon(_, _, _, _, _, _, CF, ND), CF, ND).

flow_size(mg(_, _, _, _, _, W, _), W, 13, 13).
flow_size(mhead(_, _, W, _), W, 13, 13).
flow_size(mcut, 14, 13, 13).
flow_size(mfail(W), W, 13, 13).
flow_size(mthrow(_, W), W, 13, 13).
flow_size(mframe(_, W, A, D), W, A, D).
flow_size(mcon(_, _, _, W, A, D, _, _), W, A, D).

flow_det_flags(det, false, false).
flow_det_flags(semidet, true, false).
flow_det_flags(nondet, true, true).

flow_badge(Kind, Key, Ids, Self, B) :-
    (   flow_callable_kind(Kind), Key == Self -> B = self
    ;   flow_callable_kind(Kind), get_assoc(Key, Ids, Id) -> B = ref(Id)
    ;   B = none
    ).

flow_badge_w(none, 0).
flow_badge_w(ref(_), 21).
flow_badge_w(self, 17).

flow_tip(G, Kind, Det, Names, Tip) :-
    flow_term_full(G, Names, 1200, T),
    flow_kind_word(Kind, KW),
    format(atom(Tip), '~w  --  ~w, ~w', [T, KW, Det]).

flow_kind_word(user, 'your predicate') :- !.
flow_kind_word(library(L), W) :- !, flow_lib_name(L, N), format(atom(W), 'library(~w)', [N]).
flow_kind_word(builtin, 'builtin, C in the engine') :- !.
flow_kind_word(test, test) :- !.
flow_kind_word(unify, unification) :- !.
flow_kind_word(portal(M), W) :- !, format(atom(W), 'C function of library(~w), not traced', [M]).
flow_kind_word(unknown, 'defined nowhere the chart can see') :- !.
flow_kind_word(_, 'a goal known only when it runs').

flow_m_head(H, CM, Names, HF, mhead(Segs, HF, W, Tip)) :-
    flow_goal_segs(H, CM, Names, Segs),
    flow_segs_w(Segs, TW),
    W is TW + 22,
    flow_segs_atom(Segs, T),
    (   HF == true
    ->  atom_concat(T, '  --  the clause head: unifying it can fail', Tip)
    ;   atom_concat(T, '  --  the clause head: unifying it cannot fail', Tip)
    ).

%% ======================================================================
%% Placing: items on a main line, emitting layered primitives
%% ======================================================================
%%
%% A primitive is drawn in a LAYER -- 0 backgrounds, 1 lines, 2 boxes,
%% 3 text and marks -- so lines pass under boxes whatever order they are
%% made in; site(Id, Y) is no drawing, it tells the panel where a call to
%% panel Id stands, for its wire.

flow_p(mg(Kind, Segs, Badge, ND, CF, W, Tip), X, Y, Prims, it(X, W, B, CF, ND, false)) :- !,
    T is Y - 13,
    B is Y + 13,
    flow_box_style(Kind, Fill, Stroke, Dash),
    (   Kind == test
    ->  X1 is X + 7, X2 is X + W - 7, XR is X + W,
        Shape = pg([X-Y, X1-T, X2-T, XR-Y, X2-B, X1-B], Fill, Stroke, 1)
    ;   Shape = r(X, T, W, 26, 5, Fill, Stroke, 1, Dash)
    ),
    (   ND == true -> NW = 13 ; NW = 0 ),
    (   Kind == test -> HX = 6 ; HX = 0 ),
    TX is X + 9 + NW + HX,
    TY is Y + 4,
    (   ND == true
    ->  GX is X + 8,
        Glyph = [t(GX, TY, start, 11, sans, normal, [s('↻', muted)])]
    ;   Glyph = []
    ),
    flow_portal_plaque(Kind, X, W, Badge, Y, Plaque),
    flow_badge_prims(Badge, Kind, X, W, Y, BadgePs),
    append([[Shape, t(TX, TY, start, 12, mono, normal, Segs)], Glyph, Plaque, BadgePs], Inner),
    (   Badge = ref(Id) -> Site = [9-site(Id, Y)] ; Site = [] ),
    Prims = [2-grp(Tip, Inner)|Site].
flow_p(mhead(Segs, HF, W, Tip), X, Y,
       [2-grp(Tip, [r(X, T, W, 26, 13, '#eef0ff', '#5a5fcf', 1, none),
                    t(TX, TY, start, 12, mono, normal, Segs)])],
       it(X, W, B, HF, false, false)) :- !,
    T is Y - 13, B is Y + 13, TX is X + 11, TY is Y + 4.
flow_p(mcut, X, Y,
       [2-grp('!  --  the cut: it commits to this clause, and nothing to its left is tried again',
              [r(RX, T, 8, 24, 2, '#d97706', none, 0, none),
               t(CX, TY, middle, 11, sans, bold, [s('!', white)])])],
       it(X, 14, B, false, false, true)) :- !,
    RX is X + 3, T is Y - 12, B is Y + 13, CX is X + 7, TY is Y + 4.
flow_p(mfail(W), X, Y,
       [2-grp('fail  --  always fails',
              [r(X, T, W, 26, 5, '#fff1f1', '#d62828', 1, none),
               t(TX, TY, start, 12, mono, normal, [s(fail, red)])])],
       it(X, W, B, true, false, false)) :- !,
    T is Y - 13, B is Y + 13, TX is X + 9, TY is Y + 4.
flow_p(mthrow(Segs, W), X, Y,
       [2-grp('throw  --  leaves through the nearest catch/3',
              [r(X, T, W, 26, 5, '#f7f0ff', '#7e22ce', 1, none),
               t(TX, TY, start, 12, mono, normal, Segs)])],
       it(X, W, B, false, false, false)) :- !,
    T is Y - 13, B is Y + 13, TX is X + 9, TY is Y + 4.
flow_p(mframe(Is, W, A, D), X, Y, Prims, it(X, W, B, false, false, false)) :- !,
    T is Y - A,
    B is Y + D,
    H is A + D,
    LX is X + 6,
    LY is T + 10,
    IX is X + 8,
    flow_p_items(Is, IX, Y, IPs, _, _),
    Prims = [1-r(X, T, W, H, 5, none, '#c08a00', 1, '3 2'),
             3-t(LX, LY, start, 9, sans, bold, [s('if', amber)])|IPs].
flow_p(mcon(Type, Label, Tracks, W, A, D, CF, ND), X, Y, Prims, it(X, W, B, CF, ND, false)) :-
    T is Y - A,
    B is Y + D,
    H is A + D,
    XR is X + W - 11,
    LX is X + 8,
    LY is T + 13,
    flow_label_prims(Label, LX, LY, LPs),
    flow_p_tracks(Tracks, X, Y, TPs, TInfo),
    flow_con_wires(Type, X, Y, XR, W, TInfo, WPs),
    append([[0-r(X, T, W, H, 7, '#f5f7fa', '#b8c4d0', 1, none)], LPs, WPs, TPs], Prims).

flow_label_prims(lbl(A), X, Y, [3-t(X, Y, start, 10, sans, normal, [s(A, muted)])]).
flow_label_prims(segs(Ss), X, Y, [3-t(X, Y, start, 11, mono, normal, Ss)]).

flow_p_items([], X, _, [], X, []).
flow_p_items([I|Is], X, Y, Prims, XE, [Info|Infos]) :-
    flow_p(I, X, Y, P1, Info),
    flow_size(I, W, _, _),
    (   Is == []
    ->  XE is X + W, P2 = [], Infos = []
    ;   X1 is X + W + 22,
        flow_p_items(Is, X1, Y, P2, XE, Infos)
    ),
    append(P1, P2, Prims).

%% the tracks of a construct, top to bottom; tk(XStart, Y, XEnd, Descent, Infos)
flow_p_tracks([], _, _, [], []).
flow_p_tracks([t(Off, Is, _, _, TD)|Ts], X, Y, Prims, [tk(XS, Y, XE, TD, Infos)|TIs]) :-
    XS is X + 12 + Off,
    flow_p_items(Is, XS, Y, P1, XE0, Infos),
    (   Is == [] -> XE is XS + 24 ; XE = XE0 ),
    (   Ts = [t(_, _, _, TA2, _)|_] -> Y2 is Y + TD + 16 + TA2 ; Y2 = Y ),
    flow_p_tracks(Ts, X, Y2, P2, TIs),
    append(P1, P2, Prims).

flow_con_wires(Type, X, Y, XR, W, TInfo, Prims) :-
    TInfo = [tk(XS1, _, _, _, _)|_],
    XW is X + W,
    flow_track_lines(TInfo, XR, Lines),
    last(TInfo, tk(_, YL, _, _, _)),
    (   YL =\= Y -> Rail = [1-l([XR-YL, XR-Y], ink, 1.4, none, none)] ; Rail = [] ),
    Entry = [1-l([X-Y, XS1-Y], ink, 1.4, none, none), 1-l([XR-Y, XW-Y], ink, 1.4, none, none)],
    flow_con_extra(Type, TInfo, Extra),
    append([Entry, Lines, Rail, Extra], Prims).

flow_track_lines([], _, []).
flow_track_lines([tk(XS, YK, _, _, _)|Ts], XR, [1-l([XS-YK, XR-YK], ink, 1.4, none, none)|Ls]) :-
    flow_track_lines(Ts, XR, Ls).

flow_con_extra(ite, TInfo, Ps) :- !, flow_else_drops(TInfo, Ps).
flow_con_extra(or, TInfo, Ps) :- !, flow_or_retries(TInfo, Ps).
flow_con_extra(catch, [tk(XS1, Y1, _, TD1, _), tk(XS2, Y2, _, _, _)],
               [1-l([DX-DY, DX-Y2, XS2-Y2], purple, 1.2, '4 3', purple),
                3-t(LX, LY, start, 9, sans, bold, [s(throw, purple)])]) :- !,
    DX is XS1 + 10, DY is Y1 + TD1, LX is DX + 5, LY is DY + 11.
flow_con_extra(_, _, []).

%% the condition fails: down, and into the next arm
flow_else_drops([T1, T2|Ts], Ps) :-
    T1 = tk(_, _, _, _, [it(FX, _, FB, _, _, _)|_]), !,
    T2 = tk(XS2, Y2, _, _, _),
    DX is FX + 10, LX is DX + 5, LY is FB + 11,
    Ps = [1-l([DX-FB, DX-Y2, XS2-Y2], amber, 1.2, '4 3', amber),
          3-t(LX, LY, start, 9, sans, bold, [s(else, amber)])|Rest],
    flow_else_drops([T2|Ts], Rest).
flow_else_drops(_, []).

%% a branch fails: down the inner rail, into the next branch
flow_or_retries([T1, T2|Ts], [1-l([XL-Y0, XL-Y2, XS2-Y2], red, 1.2, '4 3', red)|Rest]) :- !,
    T1 = tk(XS1, Y1, _, TD1, _),
    T2 = tk(XS2, Y2, _, _, _),
    XL is XS1 - 9,
    Y0 is Y1 + TD1 + 3,
    flow_or_retries([T2|Ts], Rest).
flow_or_retries(_, []).

flow_box_style(user, '#ffffff', '#52606d', none) :- !.
flow_box_style(library(_), '#ffffff', '#8a97a5', '4 3') :- !.
flow_box_style(builtin, '#eef1f4', '#a3aeb9', none) :- !.
flow_box_style(test, '#fff7df', '#c08a00', none) :- !.
flow_box_style(unify, '#eef1f4', '#a3aeb9', none) :- !.
flow_box_style(portal(_), '#e3f4f1', '#0f766e', none) :- !.
flow_box_style(unknown, '#fff5f5', '#d62828', '3 3') :- !.
flow_box_style(_, '#ffffff', '#7e22ce', '3 3').

flow_portal_plaque(portal(_), X, W, Badge, Y,
                   [r(PX, PY, 13, 16, 3, '#0f766e', none, 0, none),
                    t(TX, TY, middle, 10, sans, bold, [s('C', white)])]) :- !,
    flow_badge_w(Badge, BW),
    PX is X + W - BW - 17,
    PY is Y - 8,
    TX is PX + 7,
    TY is Y + 4.
flow_portal_plaque(_, _, _, _, _, []).

flow_badge_prims(none, _, _, _, _, []).
flow_badge_prims(self, _, X, W, Y, [t(CX, TY, middle, 14, sans, normal, [s('↺', ink)])]) :-
    CX is X + W - 10,
    TY is Y + 5.
flow_badge_prims(ref(Id), Kind, X, W, Y,
                 [c(CX, Y, 8, Col, none, 0), t(CX, TY, middle, 9, sans, bold, [s(IdA, white)])]) :-
    CX is X + W - 12,
    TY is Y + 3,
    flow_badge_col(Kind, Col),
    number_codes(Id, Cs),
    atom_codes(IdA, Cs).

flow_badge_col(user, '#33507a') :- !.
flow_badge_col(library(_), '#6b7785') :- !.
flow_badge_col(portal(_), '#0f766e') :- !.
flow_badge_col(query, '#3d3d6b') :- !.
flow_badge_col(_, '#6b7785').

%% ======================================================================
%% A clause row, and the lane under it that says where failure goes
%% ======================================================================
%%
%% Item k can fail. Its failure goes to the nearest item j < k that can
%% redo -- unless a cut stands between them, which removed that choice and
%% every clause below: then the whole call fails ("fail !"). With nothing
%% left of k to redo, it goes down the rail to the next clause. Backtracking
%% INTO the clause after it exited arrives at the row's end (the redo mark)
%% and goes the same way. Because the target is always the NEAREST, two
%% failures whose spans overlap share their target, and each target's
%% lane is one line: the lanes never cross.

flow_m_row(row(I, H, Names, HF, Nodes), CM, Ids, Self, mrow(I, Items, A, D, W)) :-
    LC = lc(Names, Ids, Self),
    flow_m_list(Nodes, LC, BIs),
    (   H == none -> Items = BIs
    ;   flow_m_head(H, CM, Names, HF, MH), Items = [MH|BIs]
    ),
    flow_track_size(Items, W0, A, D),
    flow_row_tail(Items, Tail),
    W is W0 + Tail.

%% a row that ends in a cut keeps room after it: its redo runs back to the
%% cut's tag, and the tag is centred under the cut
flow_row_tail(Items, Tail) :-
    (   append(_, [mcut], Items) -> Tail = 16 ; Tail = 0 ).

flow_m_rows([], _, _, _, []).
flow_m_rows([R|Rs], CM, Ids, Self, [M|Ms]) :-
    flow_m_row(R, CM, Ids, Self, M),
    flow_m_rows(Rs, CM, Ids, Self, Ms).

flow_rows_maxw([], M, M).
flow_rows_maxw([mrow(_, _, _, _, W)|Rs], M0, M) :-
    M1 is max(M0, W),
    flow_rows_maxw(Rs, M1, M).

flow_p_rows([], _, Top, _, _, [], [], Top).
flow_p_rows([MR|MRs], X0, Top, RailX, ExitX, Prims, [G|Gs], Bottom) :-
    flow_p_row(MR, X0, Top, RailX, ExitX, P1, G),
    G = row_geo(_, _, _, RB, _),
    Top2 is RB + 4,
    flow_p_rows(MRs, X0, Top2, RailX, ExitX, P2, Gs, Bottom),
    append(P1, P2, Prims).

flow_p_row(mrow(I, Items, A, D, _), X0, Top, RailX, ExitX, Prims, row_geo(I, Y, YF, Bottom, RailHit)) :-
    Y is Top + A,
    flow_p_items(Items, X0, Y, IPs, XE, Infos),
    YF is Y + D + 12,
    flow_row_tail(Items, Tail),
    RowEnd is XE + 12 + Tail,
    flow_lanes(Infos, RowEnd, RailX, YF, LPs, RailHit, Tags),
    (   Tags == true -> Extra = 6 ; Extra = 0 ),
    Bottom is YF + 12 + Extra,
    append([[1-l([X0-Y, ExitX-Y], ink, 1.4, none, none)], IPs, LPs], Prims).

flow_lanes(Infos, RowEnd, RailX, YF, Prims, RailHit, Tags) :-
    flow_index(Infos, 1, Indexed),
    flow_fail_sources(Indexed, [], Srcs0),
    reverse(Indexed, RevAll),
    flow_fail_target(RevAll, EndT),
    Srcs = [src(EndT, RowEnd, end)|Srcs0],
    findall(T, member(src(T, _, _), Srcs), Ts0),
    sort(Ts0, Ts),
    flow_lane_groups(Ts, Srcs, Indexed, RailX, YF, GPs),
    flow_stubs(Srcs, YF, SPs),
    (   memberchk(rail, Ts) -> RailHit = true ; RailHit = false ),
    (   memberchk(cutfail(_), Ts) -> Tags = true ; Tags = false ),
    append(GPs, SPs, Prims).

flow_index([], _, []).
flow_index([X|Xs], I, [I-X|R]) :- I1 is I + 1, flow_index(Xs, I1, R).

flow_fail_sources([], _, []).
flow_fail_sources([K-Info|Rest], RevPrefix, Srcs) :-
    Info = it(X, W, B, CF, _, _),
    (   CF == true
    ->  flow_fail_target(RevPrefix, T),
        SX is X + min(14, W // 3),
        Srcs = [src(T, SX, B)|Srcs1]
    ;   Srcs = Srcs1
    ),
    flow_fail_sources(Rest, [K-Info|RevPrefix], Srcs1).

flow_fail_target([], rail).
flow_fail_target([K-it(_, _, _, _, ND, Cut)|Rest], T) :-
    (   Cut == true -> T = cutfail(K)
    ;   ND == true -> T = item(K)
    ;   flow_fail_target(Rest, T)
    ).

flow_lane_groups([], _, _, _, _, []).
flow_lane_groups([T|Ts], Srcs, Indexed, RailX, YF, Prims) :-
    findall(SX, member(src(T, SX, _), Srcs), SXs),
    max_list(SXs, MaxX),
    flow_lane_group(T, MaxX, Indexed, RailX, YF, P1),
    flow_lane_groups(Ts, Srcs, Indexed, RailX, YF, P2),
    append(P1, P2, Prims).

flow_lane_group(rail, MaxX, _, RailX, YF, [1-l([MaxX-YF, RailX-YF], red, 1.2, '4 3', none)]).
flow_lane_group(item(K), MaxX, Indexed, _, YF, [1-l([MaxX-YF, NX-YF, NX-BK], red, 1.2, '4 3', red)]) :-
    memberchk(K-it(XK, WK, BK, _, _, _), Indexed),
    NX is XK + WK - min(14, WK // 3).
%% past a cut: the lane runs back to the cut and stops at its tag
flow_lane_group(cutfail(K), MaxX, Indexed, _, YF, [1-l([MaxX-YF, TR-YF], red, 1.2, '4 3', none)|Tag]) :-
    memberchk(K-it(XK, WK, _, _, _, _), Indexed),
    CX is XK + WK // 2,
    TR is CX + 17,
    flow_cut_tag(CX, YF, Tag).

flow_cut_tag(CX, Y, [3-grp('fail !  --  the cut removed every alternative: the whole call fails',
                           [r(TX, TY, 34, 14, 3, '#d62828', none, 0, none),
                            t(CX, LY, middle, 8, sans, bold, [s('fail !', white)])])]) :-
    TX is CX - 17,
    TY is Y - 7,
    LY is Y + 3.

flow_stubs([], _, []).
flow_stubs([src(_, SX, B)|Ss], YF, Prims) :-
    flow_stub(SX, B, YF, P1),
    flow_stubs(Ss, YF, P2),
    append(P1, P2, Prims).

flow_stub(SX, end, YF, [3-grp('redo  --  backtracking into this clause after it exited starts here',
                              [t(SX, GY, middle, 13, sans, bold, [s('↶', red)])])]) :- !,
    GY is YF + 5.
flow_stub(SX, B, YF, [1-l([SX-B, SX-YF], red, 1.2, '4 3', none)]).

%% ======================================================================
%% Panels, drawn at their own origin
%% ======================================================================
%%
%% pd(Id, Depth, Width, Height, CallY, Jacks, Prims): CallY is where the
%% call port is, Jacks where its own calls leave for the panels they call.

flow_draw(P, Ids, DMap, KMap, Docs, PD) :-
    P = panel(_, _, Kind, _, _, _, _, _),
    (   Kind == query -> flow_draw_query(P, Ids, DMap, KMap, Docs, PD)
    ;   Kind = portal(_) -> flow_draw_portal(P, PD)
    ;   flow_draw_rows(P, Ids, DMap, KMap, Docs, PD)
    ).

flow_draw_rows(panel(Id, Key, Kind, CM, D, rows(Rows), Det, _), Ids, DMap, KMap, Docs,
               pd(Id, D, W, H, CallY, Jacks, Prims)) :-
    flow_panel_head(Key, CM, Rows, Docs, HeadSegs),
    flow_doc_rows(Key, Kind, Docs, Rows, DRows),
    flow_m_rows(DRows, CM, Ids, Key, MRows),
    flow_rows_maxw(MRows, 0, MW),
    flow_segs_w(HeadSegs, HW),
    W is max(34 + MW + 26 + 16, 34 + HW + 140),
    ExitX is W - 14,
    flow_p_rows(MRows, 34, 44, 16, ExitX, RowPs, Geos, Bottom),
    H is Bottom + 22,
    Geos = [row_geo(_, CallY, _, _, _)|_],
    length(Rows, NC),
    flow_panel_tag(Kind, Det, NC, Tag),
    flow_panel_frame(Id, Kind, W, H, HeadSegs, Tag, FramePs),
    flow_panel_ports(Geos, W, H, ExitX, PortPs),
    MinY is CallY + 18,
    flow_jacks(RowPs, D, DMap, KMap, W, MinY, Jacks, JackPs),
    exclude(flow_is_site, RowPs, RowPs1),
    append([FramePs, PortPs, RowPs1, JackPs], Prims).

flow_is_site(9-site(_, _)).

%% a library clause read back with clause/2 has letters for names; its
%% head's variables take the names its library's header documents
flow_doc_rows(Key, library(_), Docs, Rows0, Rows) :-
    get_assoc(Key, Docs, sig(_, DNs)), !,
    findall(R, ( member(R0, Rows0), flow_doc_row(R0, DNs, R) ), Rows).
flow_doc_rows(_, _, _, Rows, Rows).

flow_doc_row(row(I, H, Names, HF, Nodes), DNs, row(I, H, Names1, HF, Nodes)) :-
    H =.. [_|Args],
    flow_rename_args(Args, DNs, Names, Names1).

flow_rename_args([], _, Ns, Ns).
flow_rename_args([A|As], [D|Ds], Ns0, Ns) :-
    (   var(A) -> flow_rename_var(Ns0, A, D, Ns1) ; Ns1 = Ns0 ),
    flow_rename_args(As, Ds, Ns1, Ns).

flow_rename_var([], _, _, []).
flow_rename_var([N=V|T], A, D, [N1=V|T1]) :-
    (   V == A -> N1 = D ; N1 = N ),
    flow_rename_var(T, A, D, T1).

flow_panel_tag(user, Det, NC, Tag) :- !,
    flow_plural(NC, clause, Cl),
    format(atom(Tag), '~w  ·  ~d ~w', [Det, NC, Cl]).
flow_panel_tag(library(L), Det, NC, Tag) :- !,
    flow_lib_name(L, LN),
    flow_plural(NC, clause, Cl),
    format(atom(Tag), 'library(~w)  ·  ~w  ·  ~d ~w', [LN, Det, NC, Cl]).
flow_panel_tag(_, Det, _, Det).

flow_plural(1, W, W) :- !.
flow_plural(_, W, P) :- atom_concat(W, s, P).

flow_panel_frame(Id, Kind, W, H, HeadSegs, Tag, Prims) :-
    flow_panel_fill(Kind, HFill),
    flow_badge_col(Kind, BCol),
    flow_id_atom(Id, IdA),
    W2 is W - 2,
    W1 is W - 1,
    TX is W - 10,
    Prims = [0-r(0, 0, W, H, 8, '#fbfcfd', '#c3ccd6', 1, none),
             0-r(1, 1, W2, 29, 7, HFill, none, 0, none),
             0-r(1, 20, W2, 10, 0, HFill, none, 0, none),
             0-l([1-30, W1-30], '#d5dce4', 1, none, none),
             3-c(17, 15, 10, BCol, none, 0),
             3-t(17, 19, middle, 11, sans, bold, [s(IdA, white)]),
             3-t(34, 20, start, 12, mono, bold, HeadSegs),
             3-t(TX, 19, end, 10, sans, normal, [s(Tag, muted)])].

flow_id_atom(query, '?-') :- !.
flow_id_atom(Id, A) :- number_codes(Id, Cs), atom_codes(A, Cs).

flow_panel_fill(user, '#e8eef6') :- !.
flow_panel_fill(library(_), '#eef0f2') :- !.
flow_panel_fill(portal(_), '#dcf1ed') :- !.
flow_panel_fill(_, '#e9e9f3').

%% Byrd's ports: call at the top left, exit at the top right, fail at the
%% bottom left; the left rail carries each clause's failure to the next
flow_panel_ports(Geos, W, H, ExitX, Prims) :-
    Geos = [row_geo(_, Y1, _, _, _)|_],
    last(Geos, row_geo(_, YL, _, _, _)),
    LY is Y1 - 8,
    EX is W - 3,
    Ports = [1-l([0-Y1, 9-Y1], ink, 1.4, none, ink),
             3-t(2, LY, start, 8, sans, normal, [s(call, muted)]),
             1-l([ExitX-Y1, W-Y1], ink, 1.4, none, ink),
             3-t(EX, LY, end, 8, sans, normal, [s(exit, muted)])],
    (   YL =\= Y1 -> Rail = [1-l([ExitX-YL, ExitX-Y1], ink, 1.4, none, none)] ; Rail = [] ),
    flow_markers(Geos, Marks),
    YB is H - 12,
    flow_retries(Geos, YB, Retries),
    append([Ports, Rail, Marks, Retries], Prims).

flow_markers([], []).
flow_markers([row_geo(I, Y, _, _, _)|Gs], [1-l([23-Y, 34-Y], ink, 1.4, none, none),
                                           3-c(16, Y, 7, '#ffffff', '#1f2933', 1.2),
                                           3-t(16, TY, middle, 8, sans, bold, [s(IA, ink)])|Ms]) :-
    TY is Y + 3,
    number_codes(I, Cs),
    atom_codes(IA, Cs),
    flow_markers(Gs, Ms).

flow_retries([], _, []).
flow_retries([row_geo(_, _, YF, _, Hit)|Gs], YB, Prims) :-
    (   Hit == true
    ->  (   Gs = [row_geo(_, YN, _, _, _)|_]
        ->  YT is YN - 8,
            P1 = [1-l([16-YF, 16-YT], red, 1.2, '4 3', red)]
        ;   LY is YB + 10,
            P1 = [1-l([16-YF, 16-YB, 0-YB], red, 1.2, '4 3', red),
                  3-t(3, LY, start, 8, sans, normal, [s(fail, red)])]
        )
    ;   P1 = []
    ),
    flow_retries(Gs, YB, P2),
    append(P1, P2, Prims).

%% where this panel's calls leave it: one jack per panel called in the
%% next column, level with the first call to it, spaced to stay apart
flow_jacks(Prims, D, DMap, KMap, W, MinY, Jacks, JackPs) :-
    findall(C-Y, member(9-site(C, Y), Prims), Sites),
    flow_first_per_key(Sites, [], Firsts),
    D1 is D + 1,
    include(flow_wired(DMap, D1), Firsts, Wired),
    findall(Y-C, member(C-Y, Wired), YC),
    keysort(YC, Sorted),
    flow_space(Sorted, MinY, Spaced),
    flow_jack_prims(Spaced, KMap, W, JackPs),
    findall(jk(C, JY), member(C-JY, Spaced), Jacks).

flow_first_per_key([], _, []).
flow_first_per_key([C-Y|T], Seen, Out) :-
    (   memberchk(C, Seen) -> Out = Out1 ; Out = [C-Y|Out1] ),
    flow_first_per_key(T, [C|Seen], Out1).

flow_wired(DMap, D1, C-_) :-
    get_assoc(C, DMap, DC),
    DC =:= D1.

flow_space([], _, []).
flow_space([Y-C|T], Min, [C-JY|R]) :-
    JY is max(Y, Min),
    Min2 is JY + 16,
    flow_space(T, Min2, R).

flow_jack_prims([], _, _, []).
flow_jack_prims([C-JY|T], KMap, W, [3-c(W, JY, 4, Col, none, 0),
                                    3-t(LX, LY, end, 8, sans, bold, [s(CA, Col)])|R]) :-
    get_assoc(C, KMap, K),
    flow_badge_col(K, Col),
    LX is W - 7,
    LY is JY + 3,
    flow_id_atom(C, CA),
    flow_jack_prims(T, KMap, W, R).

flow_draw_query(panel(_, _, _, _, D, rows([row(_, _, Names0, _, [GNode])]), _, _), Ids, DMap, KMap, Docs,
                pd(0, D, W, H, 56, Jacks, Prims)) :-
    GNode = g(G, _, _, _, Key),
    (   get_assoc(Key, Docs, sig(_, DNs)), G =.. [_|Vs], flow_pair_names(DNs, Vs, Names1)
    ->  Names = Names1
    ;   Names = Names0
    ),
    flow_m(GNode, lc(Names, Ids, none), MG),
    flow_size(MG, GW, _, _),
    W is 16 + GW + 24,
    H = 84,
    flow_p(MG, 16, 56, GPs, _),
    flow_panel_frame(query, query, W, H, [s(query, ink)], 'what was asked', FramePs),
    flow_jacks(GPs, D, DMap, KMap, W, 56, Jacks, JackPs),
    exclude(flow_is_site, GPs, GPs1),
    append([FramePs, GPs1, JackPs], Prims).

flow_draw_portal(panel(Id, N/A, portal(Mod), _, D, portal(info(CFun, File, Line, Modes, Names)), _, _),
                 pd(Id, D, W, H, 48, [], Prims)) :-
    functor(G, N, A),
    G =.. [_|Vs],
    (   flow_pair_names(Names, Vs, NVs0) -> NVs = NVs0 ; flow_gen_names(G, NVs) ),
    flow_moded_head(G, Modes, NVs, SigSegs),
    format(atom(Title), '~w/~w', [N, A]),
    format(atom(L2), 'library(~w)  ·  ~w()', [Mod, CFun]),
    format(atom(L3), '~w:~w', [File, Line]),
    flow_segs_w(SigSegs, SW),
    flow_chars(L2, N2), flow_chars(L3, N3),
    W2 is (N2 * 62 + 9) // 10, W3 is (N3 * 60 + 9) // 10,
    flow_chars(Title, NT), flow_text_w(NT, TW),
    W is max(max(SW, TW + 90), max(W2, W3)) + 40,
    H = 104,
    flow_panel_frame(Id, portal(Mod), W, H, [s(Title, ink)], 'C portal', FramePs),
    Body = [1-l([0-48, 12-48], ink, 1.4, none, ink),
            3-t(16, 52, start, 12, mono, normal, SigSegs),
            3-t(16, 70, start, 10, sans, normal, [s(L2, muted)]),
            3-t(16, 85, start, 10, mono, normal, [s(L3, muted)]),
            3-t(16, 98, start, 9, sans, normal, [s('C: the flow libraries do not look inside', muted)])],
    append(FramePs, Body, Prims).

flow_pair_names([], [], []).
flow_pair_names([N|Ns], [V|Vs], [N=V|R]) :- flow_pair_names(Ns, Vs, R).

%% ======================================================================
%% The chart: panels in columns by call depth, wires through gutters
%% ======================================================================

flow_layout(graph(Title, Src, Panels, Ids, Docs), canvas(CW, CH, Items)) :-
    findall(I-D, member(panel(I, _, _, _, D, _, _, _), Panels), DPairs),
    list_to_assoc(DPairs, DMap),
    findall(I-K, member(panel(I, _, K, _, _, _, _, _), Panels), KPairs),
    list_to_assoc(KPairs, KMap),
    flow_draw_all(Panels, Ids, DMap, KMap, Docs, PDs),
    flow_parents(Panels, DMap, Ids, Parents),
    flow_place_tree(PDs, Parents, [], Placed),
    flow_tree_wires(Placed, Wires),
    findall(R, ( member(pp(_, _, X, _, W, _, _, _, _), Placed), R is X + W ), Rs),
    max_list(Rs, MaxR),
    findall(B, ( member(pp(_, _, _, Y, _, H, _, _, _), Placed), B is Y + H ), Bs),
    max_list(Bs, MaxB),
    CW0 is max(MaxR + 32, 980),
    LegendY is MaxB + 44,
    flow_legend(LegendY, CW0, LegendPs, LegendH),
    CW = CW0,
    CH is LegendY + LegendH + 20,
    flow_title_prims(Title, Src, TitlePs),
    findall(tr(X, Y, Ps), ( member(pp(_, _, X, Y, _, _, _, _, Ps0), Placed), flow_layered(Ps0, Ps) ), Groups),
    append([TitlePs, Groups, Wires, LegendPs], Items).

flow_draw_all([], _, _, _, _, []).
flow_draw_all([P|Ps], Ids, DMap, KMap, Docs, [D|Ds]) :-
    flow_draw(P, Ids, DMap, KMap, Docs, D),
    flow_draw_all(Ps, Ids, DMap, KMap, Docs, Ds).

%% EACH PANEL STANDS JUST RIGHT OF THE PANEL THAT FIRST CALLS IT, level
%% with the jack its call leaves from, and moves down only as far as it
%% must to clear a panel already placed. A column shared by every panel at
%% one depth would put a callee as far right as the WIDEST panel of its
%% caller's depth, and its wire across the empty space that leaves.
flow_parents(Panels, DMap, Ids, Parents) :-
    empty_assoc(P0),
    flow_parents_(Panels, DMap, Ids, P0, Parents).

flow_parents_([], _, _, P, P).
flow_parents_([panel(Id, _, _, _, D, _, _, Calls)|Ps], DMap, Ids, P0, P) :-
    D1 is D + 1,
    flow_parent_calls(Calls, Id, D1, DMap, Ids, P0, P1),
    flow_parents_(Ps, DMap, Ids, P1, P).

flow_parent_calls([], _, _, _, _, P, P).
flow_parent_calls([c(Key, _, _)|Cs], Id, D1, DMap, Ids, P0, P) :-
    (   get_assoc(Key, Ids, C), \+ get_assoc(C, P0, _),
        get_assoc(C, DMap, DC), DC =:= D1
    ->  put_assoc(C, P0, Id, P1)
    ;   P1 = P0
    ),
    flow_parent_calls(Cs, Id, D1, DMap, Ids, P1, P).

flow_place_tree([], _, Placed, Placed).
flow_place_tree([PD|PDs], Parents, Acc, Placed) :-
    PD = pd(Id, D, W, H, CY, J, Ps),
    (   get_assoc(Id, Parents, Par),
        memberchk(pp(Par, _, PX, PY, PW, _, _, PJ, _), Acc),
        memberchk(jk(Id, JY), PJ)
    ->  length(PJ, NT),
        flow_gutter_w(NT, GW),
        X is PX + PW + GW,
        Want is PY + JY - CY
    ;   X = 24, Want = 84
    ),
    Y0 is max(Want, 84),
    flow_free_y(X, Y0, W, H, Acc, Y),
    flow_place_tree(PDs, Parents, [pp(Id, D, X, Y, W, H, CY, J, Ps)|Acc], Placed).

flow_gutter_w(NT, W) :- W is 34 + NT * 18 + 26.

%% the first Y at or below Y0 where the panel overlaps nothing placed
flow_free_y(X, Y0, W, H, Placed, Y) :-
    (   member(pp(_, _, PX, PY, PW, PH, _, _, _), Placed),
        X < PX + PW + 24, PX < X + W + 24,
        Y0 < PY + PH + 28, PY < Y0 + H + 28
    ->  Y1 is PY + PH + 28,
        flow_free_y(X, Y1, W, H, Placed, Y)
    ;   Y = Y0
    ).

%% every jack's wire, through its own panel's gutter
flow_tree_wires(Placed, Wires) :-
    findall(Ws,
            ( member(pp(_, _, X, Y, W, _, _, Jacks, _), Placed),
              Jacks \== [],
              GL is X + W,
              findall(n(C, TY, [SY]),
                      ( member(jk(C, JY), Jacks),
                        memberchk(pp(C, _, _, CYp, _, _, CCY, _, _), Placed),
                        TY is CYp + CCY,
                        SY is Y + JY ),
                      Nets0),
              flow_order_nets(Nets0, Nets),
              flow_tree_route(Nets, 0, GL, Placed, Ws) ),
            Wss),
    append(Wss, Wires).

flow_tree_route([], _, _, _, []).
flow_tree_route([n(C, TY, [SY])|Ns], T, GL, Placed, Wires) :-
    XT is GL + 34 + T * 18,
    memberchk(pp(C, _, TX, _, _, _, _, _, _), Placed),
    flow_wire(GL, SY, XT, TX, TY, W1),
    T1 is T + 1,
    flow_tree_route(Ns, T1, GL, Placed, W2),
    append(W1, W2, Wires).

%% layers, in order, keeping the order things were made in within one
flow_layered(Ps0, Ps) :-
    keysort(Ps0, Sorted),
    findall(P, member(_-P, Sorted), Ps).

%% THE GUTTER. Each callee's wires share one vertical track; the tracks are
%% ordered so that as few horizontals as possible cross another's vertical.
%% A placed left of B costs one crossing for each of B's sources strictly
%% inside A's span, and one if A's target is strictly inside B's span.
flow_order_nets(Nets, Ordered) :-
    flow_insert_all(Nets, [], Ordered).

flow_insert_all([], O, O).
flow_insert_all([N|Ns], O0, O) :-
    flow_best_insert(N, O0, O1),
    flow_insert_all(Ns, O1, O).

flow_best_insert(N, O0, O) :-
    length(O0, Len),
    findall(Cost-Pos, ( between(0, Len, Pos), flow_insert_cost(N, O0, Pos, Cost) ), CPs),
    keysort(CPs, [_-Best|_]),
    flow_insert_at(O0, Best, N, O).

flow_insert_cost(N, O, Pos, Cost) :-
    length(Left, Pos),
    append(Left, Right, O),
    flow_cost_left(Left, N, C1),
    flow_cost_right(Right, N, C2),
    Cost is C1 + C2.

flow_cost_left([], _, 0).
flow_cost_left([M|Ms], N, C) :-
    flow_cross(M, N, C1),
    flow_cost_left(Ms, N, C2),
    C is C1 + C2.

flow_cost_right([], _, 0).
flow_cost_right([M|Ms], N, C) :-
    flow_cross(N, M, C1),
    flow_cost_right(Ms, N, C2),
    C is C1 + C2.

flow_cross(n(_, TA, SA), n(_, TB, SB), C) :-
    flow_span(TA, SA, LoA, HiA),
    flow_span(TB, SB, LoB, HiB),
    flow_inside(SB, LoA, HiA, K1),
    (   TA > LoB, TA < HiB -> K2 = 1 ; K2 = 0 ),
    C is K1 + K2.

flow_span(T, Ss, Lo, Hi) :-
    min_list([T|Ss], Lo),
    max_list([T|Ss], Hi).

flow_inside([], _, _, 0).
flow_inside([S|Ss], Lo, Hi, K) :-
    flow_inside(Ss, Lo, Hi, K0),
    (   S > Lo, S < Hi -> K is K0 + 1 ; K = K0 ).

flow_insert_at(O, 0, N, [N|O]) :- !.
flow_insert_at([M|Ms], P, N, [M|R]) :-
    P1 is P - 1,
    flow_insert_at(Ms, P1, N, R).

%% a call goes out on the dark lane and its answer comes back on the green
%% one, six pixels below, on the side that keeps the two from crossing
flow_wire(SX, SY, XT, TX, TY, [l(CallPts, ink, 1.5, none, ink), l(ExitPts, green, 1.3, none, green)]) :-
    TY6 is TY + 6,
    SY6 is SY + 6,
    (   SY =:= TY
    ->  CallPts = [SX-SY, TX-TY],
        ExitPts = [TX-TY6, SX-SY6]
    ;   CallPts = [SX-SY, XT-SY, XT-TY, TX-TY],
        (   TY > SY -> XE is XT - 6 ; XE is XT + 6 ),
        ExitPts = [TX-TY6, XE-TY6, XE-SY6, SX-SY6]
    ).

flow_title_prims(Title, Src, [t(24, 36, start, 18, sans, bold, [s(Title, ink)]),
                              t(24, 58, start, 11, sans, normal, [s(Sub, muted)])]) :-
    flow_lib_name(Src, Base),
    format(atom(Sub), 'flowchart of ~w.pl  ·  library(flowchart), prototype F0  ·  modes are inferred from the call pattern; hover a box for its full text', [Base]).

%% ======================================================================
%% The legend: what each mark means, drawn with the marks themselves
%% ======================================================================

flow_legend(Y0, CW, Prims, H) :-
    Max is CW - 24,
    RuleY is Y0 - 18,
    RX is CW - 24,
    Rule = [l([24-RuleY, RX-RuleY], '#e3e8ee', 1, none, none)],
    flow_legend_row('boxes', [head, user, library, builtin, test, portal, cut], Y0, Max, P1, Y1),
    flow_legend_row('flow', [success, failure, cutfail, choice, recursion, redo], Y1, Max, P2, Y2),
    flow_legend_row('wires and modes', [wire, mode('+'), mode('-'), mode('?'), mode(':')], Y2, Max, P3, Y3),
    H is Y3 - Y0 + 4,
    append([Rule, P1, P2, P3], Prims).

flow_legend_row(Label, Entries, Y, Max, [t(24, LY, start, 10, sans, bold, [s(Label, muted)])|Ps], YNext) :-
    LY is Y + 4,
    flow_legend_entries(Entries, 140, Y, Max, Ps, YEnd),
    YNext is YEnd + 34.

flow_legend_entries([], _, Y, _, [], Y).
flow_legend_entries([E|Es], X, Y, Max, Ps, YEnd) :-
    flow_legend_entry(E, SW, Caption),
    flow_chars(Caption, CN),
    EW is SW + 8 + (CN * 62 + 9) // 10 + 26,
    (   X + EW > Max, X > 140 -> X1 = 140, Y1 is Y + 32 ; X1 = X, Y1 = Y ),
    flow_legend_sample(E, X1, Y1, SPs),
    CX is X1 + SW + 8,
    CY is Y1 + 4,
    X2 is X1 + EW,
    flow_legend_entries(Es, X2, Y1, Max, Rest, YEnd),
    append(SPs, [t(CX, CY, start, 10, sans, normal, [s(Caption, muted)])|Rest], Ps).

flow_legend_entry(head, W, 'clause head') :- flow_text_w(12, TW), W is TW + 22.
flow_legend_entry(user, W, 'your predicate, drawn in panel 3') :- flow_text_w(4, TW), W is TW + 18 + 21.
flow_legend_entry(library, W, 'library') :- flow_text_w(12, TW), W is TW + 18.
flow_legend_entry(builtin, W, 'builtin') :- flow_text_w(8, TW), W is TW + 18.
flow_legend_entry(test, W, 'test') :- flow_text_w(5, TW), W is TW + 30.
flow_legend_entry(portal, W, 'C function: a portal, not traced') :- flow_text_w(14, TW), W is TW + 18 + 17 + 21.
flow_legend_entry(cut, 14, 'cut').
flow_legend_entry(success, 40, 'success: left to right').
flow_legend_entry(failure, 40, 'failure: redo the nearest goal that can, else the next clause').
flow_legend_entry(cutfail, 34, 'past a cut: the whole call fails').
flow_legend_entry(choice, 14, 'can leave a choice point').
flow_legend_entry(recursion, 14, 'calls itself').
flow_legend_entry(redo, 14, 'redo enters here').
flow_legend_entry(wire, 48, 'the call goes out; its answer comes back').
flow_legend_entry(mode('+'), W, 'input') :- flow_text_w(3, W).
flow_legend_entry(mode('-'), W, 'output') :- flow_text_w(4, W).
flow_legend_entry(mode('?'), W, 'either') :- flow_text_w(4, W).
flow_legend_entry(mode(':'), W, 'a goal') :- flow_text_w(5, W).

flow_legend_sample(head, X, Y, Ps) :-
    flow_p(mhead([s('p(', ink), s('+In', m('+')), s(', ', ink), s('-Out', m('-')), s(')', ink)], false, W, 'a clause head'), X, Y, Ps0, _),
    flow_legend_entry(head, W, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(user, X, Y, Ps) :-
    flow_legend_entry(user, W, _),
    flow_p(mg(user, [s('q(', ink), s('X', m('?')), s(')', ink)], ref(3), false, true, W, 'a call to your predicate'), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(library, X, Y, Ps) :-
    flow_legend_entry(library, W, _),
    flow_p(mg(library(lists), [s('member(X, L)', ink)], none, false, true, W, library), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(builtin, X, Y, Ps) :-
    flow_legend_entry(builtin, W, _),
    flow_p(mg(builtin, [s('write(X)', ink)], none, false, false, W, builtin), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(test, X, Y, Ps) :-
    flow_legend_entry(test, W, _),
    flow_p(mg(test, [s('X > 2', ink)], none, false, true, W, test), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(portal, X, Y, Ps) :-
    flow_legend_entry(portal, W, _),
    flow_p(mg(portal(text), [s('re_match(P, L)', ink)], ref(4), false, true, W, portal), X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(cut, X, Y, Ps) :-
    flow_p(mcut, X, Y, Ps0, _),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(success, X, Y, [l([X-Y, X2-Y], ink, 1.4, none, ink)]) :- X2 is X + 38.
flow_legend_sample(failure, X, Y, [l([X2-Y, X-Y], red, 1.2, '4 3', red)]) :- X2 is X + 38.
flow_legend_sample(cutfail, X, Y, Ps) :-
    CX is X + 17,
    flow_cut_tag(CX, Y, Ps0),
    flow_unlayer(Ps0, Ps).
flow_legend_sample(choice, X, Y, [t(X1, TY, start, 11, sans, normal, [s('↻', muted)])]) :- X1 is X + 2, TY is Y + 4.
flow_legend_sample(recursion, X, Y, [t(X1, TY, start, 14, sans, normal, [s('↺', ink)])]) :- X1 is X + 1, TY is Y + 5.
flow_legend_sample(redo, X, Y, [t(X1, TY, start, 13, sans, bold, [s('↶', red)])]) :- X1 is X + 1, TY is Y + 5.
flow_legend_sample(wire, X, Y, [l([X-Y1, X2-Y1], ink, 1.5, none, ink), l([X2-Y2, X-Y2], green, 1.3, none, green)]) :-
    X2 is X + 46, Y1 is Y - 3, Y2 is Y + 3.
flow_legend_sample(mode(M), X, Y, [t(X, TY, start, 12, mono, bold, [s(T, m(M))])]) :-
    TY is Y + 4,
    flow_mode_sample(M, T).

flow_mode_sample('+', '+In').
flow_mode_sample('-', '-Out').
flow_mode_sample('?', '?Any').
flow_mode_sample(':', ':Goal').

flow_unlayer([], []).
flow_unlayer([_-P|T], R) :- !, ( P = site(_, _) -> R = R1 ; R = [P|R1] ), flow_unlayer(T, R1).
flow_unlayer([P|T], [P|R]) :- flow_unlayer(T, R).

%% ======================================================================
%% SVG
%% ======================================================================
%%
%% Self-contained: presentation attributes, no stylesheet and no script,
%% so the file looks the same in a browser, an editor or a viewer.

flow_svg(Graph, Svg) :-
    flow_layout(Graph, canvas(CW, CH, Items)),
    flow_els(Items, Els),
    flow_defs(Defs),
    format(atom(VB), '0 0 ~w ~w', [CW, CH]),
    flow_font(sans, Sans),
    Svg = element(svg, [xmlns='http://www.w3.org/2000/svg', width=CW, height=CH, viewBox=VB,
                        'font-family'=Sans],
                  [Defs, element(rect, [x=0, y=0, width=CW, height=CH, fill='#ffffff'], [])|Els]).

flow_defs(element(defs, [], Ms)) :-
    findall(element(marker, [id=Id, viewBox='0 0 10 10', refX=9, refY=5,
                             markerWidth=8, markerHeight=8, orient=auto,
                             markerUnits=userSpaceOnUse],
                    [element(path, [d='M0,0 L10,5 L0,10 z', fill=C], [])]),
            ( flow_marker(K, C), atom_concat('a-', K, Id) ),
            Ms).

flow_marker(ink, '#1f2933').
flow_marker(red, '#d62828').
flow_marker(green, '#15803d').
flow_marker(amber, '#b7791f').
flow_marker(purple, '#7e22ce').

flow_els([], []).
flow_els([P|Ps], Els) :-
    (   flow_el(P, E) -> Els = [E|Es] ; Els = Es ),
    flow_els(Ps, Es).

flow_el(_-P, E) :- !, flow_el(P, E).
flow_el(site(_, _), _) :- !, fail.
flow_el(r(X, Y, W, H, Rx, Fill, Stroke, SW, Dash), element(rect, As, [])) :- !,
    flow_paint(Fill, F),
    flow_stroke(Stroke, SW, Dash, SAs),
    As = [x=X, y=Y, width=W, height=H, rx=Rx, fill=F|SAs].
flow_el(l(Pts, Col, SW, Dash, Mk), element(path, As, [])) :- !,
    flow_dedup(Pts, P1),
    flow_path_d(P1, D),
    flow_paint(Col, C),
    flow_dash(Dash, DAs),
    flow_marker_attr(Mk, MAs),
    append([[d=D, fill=none, stroke=C, 'stroke-width'=SW, 'stroke-linejoin'=round], DAs, MAs], As).
flow_el(t(X, Y, Anchor, Size, Font, Weight, Segs), element(text, As, Spans)) :- !,
    flow_font(Font, F),
    As0 = [x=X, y=Y, 'font-size'=Size, 'font-family'=F, 'xml:space'=preserve],
    (   Anchor == start -> As1 = As0 ; append(As0, ['text-anchor'=Anchor], As1) ),
    (   Weight == normal -> As = As1 ; append(As1, ['font-weight'=Weight], As) ),
    flow_spans(Segs, Spans).
flow_el(c(X, Y, R, Fill, Stroke, SW), element(circle, [cx=X, cy=Y, r=R, fill=F|SAs], [])) :- !,
    flow_paint(Fill, F),
    flow_stroke(Stroke, SW, none, SAs).
flow_el(pg(Pts, Fill, Stroke, SW), element(polygon, [points=PA, fill=F|SAs], [])) :- !,
    findall(A, ( member(X-Y, Pts), format(atom(A), '~w,~w', [X, Y]) ), As),
    atomic_list_concat(As, ' ', PA),
    flow_paint(Fill, F),
    flow_stroke(Stroke, SW, none, SAs).
flow_el(grp(Tip, Ps), element(g, [], [element(title, [], [Tip])|Es])) :- !,
    flow_els(Ps, Es).
flow_el(tr(X, Y, Ps), element(g, [transform=T], Es)) :-
    format(atom(T), 'translate(~w,~w)', [X, Y]),
    flow_els(Ps, Es).

flow_spans([], []).
flow_spans([s(T, C)|Ss], [element(tspan, [fill=F], [T])|Es]) :-
    flow_paint(C, F),
    flow_spans(Ss, Es).

flow_stroke(none, _, _, [stroke=none]) :- !.
flow_stroke(C, SW, Dash, [stroke=P, 'stroke-width'=SW|DAs]) :-
    flow_paint(C, P),
    flow_dash(Dash, DAs).

flow_dash(none, []) :- !.
flow_dash(D, ['stroke-dasharray'=D]).

flow_marker_attr(none, []) :- !.
flow_marker_attr(K, ['marker-end'=U]) :- format(atom(U), 'url(#a-~w)', [K]).

flow_paint(none, none) :- !.
flow_paint(C, C) :- atom(C), atom_codes(C, [35|_]), !.
flow_paint(ink, '#1f2933') :- !.
flow_paint(muted, '#5f6b7a') :- !.
flow_paint(white, '#ffffff') :- !.
flow_paint(red, '#d62828') :- !.
flow_paint(green, '#15803d') :- !.
flow_paint(amber, '#a86a00') :- !.
flow_paint(purple, '#7e22ce') :- !.
flow_paint(teal, '#0f766e') :- !.
flow_paint(m('+'), '#1d4ed8') :- !.
flow_paint(m('-'), '#c2410c') :- !.
flow_paint(m('?'), '#7e22ce') :- !.
flow_paint(m(':'), '#047857') :- !.
flow_paint(_, '#1f2933').

flow_font(mono, 'ui-monospace, SFMono-Regular, Menlo, Consolas, DejaVu Sans Mono, monospace').
flow_font(sans, 'system-ui, -apple-system, Segoe UI, Helvetica, Arial, DejaVu Sans, sans-serif').

flow_dedup([], []).
flow_dedup([P], [P]) :- !.
flow_dedup([P, Q|R], Out) :-
    (   P == Q -> flow_dedup([Q|R], Out) ; Out = [P|Out1], flow_dedup([Q|R], Out1) ).

%% an orthogonal polyline with its corners rounded
flow_path_d([X0-Y0|Rest], D) :-
    format(atom(M), 'M~w ~w', [X0, Y0]),
    flow_path_rest(X0-Y0, Rest, Parts),
    atomic_list_concat([M|Parts], ' ', D).

flow_path_rest(_, [], []).
flow_path_rest(_, [X-Y], [L]) :- !,
    format(atom(L), 'L~w ~w', [X, Y]).
flow_path_rest(PX-PY, [X-Y, NX-NY|Rest], [L, Q|Parts]) :-
    DX1 is sign(X - PX), DY1 is sign(Y - PY),
    DX2 is sign(NX - X), DY2 is sign(NY - Y),
    Len1 is abs(X - PX) + abs(Y - PY),
    Len2 is abs(NX - X) + abs(NY - Y),
    R is min(6, min(Len1 // 2, Len2 // 2)),
    AX is X - DX1 * R, AY is Y - DY1 * R,
    BX is X + DX2 * R, BY is Y + DY2 * R,
    format(atom(L), 'L~w ~w', [AX, AY]),
    format(atom(Q), 'Q~w ~w ~w ~w', [X, Y, BX, BY]),
    flow_path_rest(BX-BY, [NX-NY|Rest], Parts).
