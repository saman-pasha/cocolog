%% colab-check.pl -- the notebook checks test/colab.pl used to ask Python.
%%
%%     cocolog --local run test/colab-check.pl cb_main -- VERB NOTEBOOK [ARG]
%%
%%     version NB VERSIONFILE   the two declarations agree
%%     first   NB               the version prints before anything installs
%%     named   NB               a stale notebook is named, not guessed at
%%     shape   NB               valid JSON, nbformat 4, cells well-formed
%%     relpath NB               no cell runs cocolog by a relative path
%%
%% THE COCOLOG REWRITE OF colab.sh's five python3 blocks. Each printed one
%% word and the shell compared it; that contract is unchanged, so the checks
%% read the same and only the reader moved.
%%
%% ONE CHECK DID NOT SURVIVE AND IS NOT PRETENDED AWAY. The old `shape' block
%% ended with `ast.parse(s)' on every code cell -- valid JSON, nbformat 4,
%% well-formed cells, AND every Python cell parses as Python. cocolog has no
%% Python parser and will not grow one to check a notebook, so that last
%% clause is gone. What is left still catches a truncated notebook, a cell
%% with a missing field, a non-list source and a code cell without outputs,
%% which is what a bad merge or a hand edit actually produces; a cell whose
%% Python is malformed now fails on the VM instead of here. That is a real
%% reduction in cover and it is written down rather than absorbed.
%%
%% THE NOTEBOOK ITSELF STAYS PYTHON, and that is not a contradiction: it is a
%% Colab artefact, and Colab runs Python. What left this repository is the
%% Python that TOOLS it.

:- use_module(library(json)).

cb_main :-
    current_prolog_flag(argv, [_, Verb|Rest]),
    cb_do(Verb, Rest).

%% ---- the notebook, as a term --------------------------------------------

cb_load(Path, NB) :-
    read_file_to_codes(Path, Cs),
    once(json_parse(Cs, NB)).

cb_get(json(Ps), K, V) :- memberchk(K-V, Ps).

%% Every code cell's source, joined the way ''.join(c['source']) and then
%% '\n'.join(...) joined it: each cell's lines run together, cells separated
%% by a newline.
cb_code_source(NB, Codes) :-
    cb_get(NB, cells, Cells),
    findall(S,
            ( member(C, Cells),
              cb_get(C, cell_type, code),
              cb_get(C, source, Lines),
              cb_join_atoms(Lines, S)
            ),
            Srcs),
    cb_join_nl(Srcs, Codes).

cb_join_atoms([], []) :- !.
cb_join_atoms([A|As], Out) :-
    atom_codes(A, Cs),
    cb_join_atoms(As, R),
    append(Cs, R, Out).

cb_join_nl([], []) :- !.
cb_join_nl([X], X) :- !.
cb_join_nl([X|Xs], Out) :- cb_join_nl(Xs, R), append(X, [0'\n|R], Out).

%% ---- version ------------------------------------------------------------
%%
%% `^NOTEBOOK_VERSION\s*=\s*(\d+)\s*$' over the code cells, against the first
%% line of colab/VERSION.

cb_do(version, [NBP, VerP]) :-
    !,
    cb_load(NBP, NB),
    cb_code_source(NB, Src),
    read_file_to_codes(VerP, VC),
    cb_first_line(VC, WantCs),
    cb_strip(WantCs, Want),
    (   cb_declared_version(Src, Got)
    ->  (   Got == Want
        ->  write(agree)
        ;   atom_codes(GA, Got), atom_codes(WA, Want),
            format("notebook ~w, VERSION ~w", [GA, WA])
        )
    ;   atom_codes(WA, Want),
        format("notebook undeclared, VERSION ~w", [WA])
    ),
    nl.

cb_declared_version(Src, Digits) :-
    cb_lines(Src, Lines),
    member(L, Lines),
    append("NOTEBOOK_VERSION", R0, L),
    cb_ws(R0, [0'=|R1]),
    cb_ws(R1, R2),
    cb_digits1(R2, Digits, R3),
    cb_ws(R3, []),
    !.

%% ---- first --------------------------------------------------------------
%%
%% The banner must be printed before prereqs.sh is invoked, so a stale
%% notebook says so before it spends four minutes building the wrong thing.

cb_do(first, [NBP]) :-
    !,
    cb_load(NBP, NB),
    cb_code_source(NB, Src),
    (   cb_contains(Src, "notebook v{NOTEBOOK_VERSION}"),
        cb_index(Src, "NOTEBOOK_VERSION", I),
        cb_index(Src, "prereqs.sh", J),
        I < J
    ->  write(first)
    ;   write(buried)
    ),
    nl.

%% ---- named --------------------------------------------------------------

cb_do(named, [NBP]) :-
    !,
    cb_load(NBP, NB),
    cb_code_source(NB, Src),
    (   cb_contains(Src, "colab/VERSION"),
        cb_contains(Src, "Revert to saved")
    ->  write(named)
    ;   write(silent)
    ),
    nl.

%% ---- shape --------------------------------------------------------------
%%
%% Valid JSON is proved by getting this far -- json_parse/2 threw or failed
%% otherwise -- so what is left is nbformat 4 and the cells.

cb_do(shape, [NBP]) :-
    !,
    (   catch(cb_load(NBP, NB), E, ( cb_unreadable(E), fail ))
    ->  cb_shape(NB)
    ;   true
    ).

cb_unreadable(E) :- format("unreadable: ~w~n", [E]).

cb_shape(NB) :-
    (   \+ cb_get(NB, nbformat, 4)
    ->  ( cb_get(NB, nbformat, F) -> true ; F = absent ),
        format("nbformat ~w~n", [F])
    ;   cb_get(NB, cells, Cells),
        (   cb_bad_cell(Cells, 0, Why)
        ->  format("~w~n", [Why])
        ;   write(ok), nl
        )
    ).

cb_bad_cell([C|_], I, Why) :-
    \+ cb_cell_ok(C),
    !,
    format(atom(Why), "cell ~w malformed", [I]).
cb_bad_cell([C|_], I, Why) :-
    cb_get(C, cell_type, code),
    \+ ( cb_get(C, outputs, _), cb_get(C, execution_count, _) ),
    !,
    format(atom(Why), "cell ~w is code without outputs", [I]).
cb_bad_cell([_|T], I, Why) :- I1 is I + 1, cb_bad_cell(T, I1, Why).

cb_cell_ok(C) :-
    cb_get(C, cell_type, T),
    memberchk(T, [code, markdown]),
    cb_get(C, source, Src),
    is_list(Src),
    \+ ( member(L, Src), \+ atom(L) ).

%% ---- relpath ------------------------------------------------------------
%%
%% NO CELL MAY DEPEND ON WHERE A PREVIOUS CELL LEFT THE PROCESS. A notebook
%% cell inherits the last cell's working directory, so `./cocolog' is a bet
%% on execution order -- and section 2 lost it the first time anyone ran the
%% notebook without running section 4 first. A comment may DISCUSS it, so
%% each line is cut at its first `#' before the test.

cb_do(relpath, [NBP]) :-
    !,
    cb_load(NBP, NB),
    cb_get(NB, cells, Cells),
    findall(B, cb_relpath_bad(Cells, 0, B), Bad),
    (   Bad == []
    ->  write(none)
    ;   cb_join_semi(Bad, A), write(A)
    ),
    nl.

cb_relpath_bad([C|_], I, Why) :-
    cb_get(C, cell_type, code),
    cb_get(C, source, Lines),
    cb_join_atoms(Lines, Src),
    cb_lines(Src, Ls),
    member(L, Ls),
    cb_before_hash(L, Code),
    (   cb_contains(Code, "./cocolog")
    ;   cb_strip(Code, S), append("%cd ", _, S)
    ),
    cb_strip(L, Trim),
    cb_take(40, Trim, Head),
    atom_codes(HA, Head),
    format(atom(Why), "cell ~w: ~w", [I, HA]).
cb_relpath_bad([_|T], I, Why) :- I1 is I + 1, cb_relpath_bad(T, I1, Why).

cb_before_hash([], []) :- !.
cb_before_hash([0'#|_], []) :- !.
cb_before_hash([C|T], [C|R]) :- cb_before_hash(T, R).

%% The complaints are already atoms, from format(atom(Why), ...).
cb_join_semi([X], X) :- !.
cb_join_semi([X|Xs], A) :-
    cb_join_semi(Xs, R),
    atomic_list_concat([X, '; ', R], A).

%% ---- text ----------------------------------------------------------------

cb_lines([], []) :- !.
cb_lines(Cs, [L|Ls]) :-
    ( append(L, [0'\n|R], Cs) -> true ; L = Cs, R = [] ),
    !,
    ( R == [], L == [] -> Ls = [] ; cb_lines(R, Ls) ).

cb_first_line(Cs, L) :- ( append(L, [0'\n|_], Cs) -> true ; L = Cs ), !.

cb_space(0' ).  cb_space(0'\t). cb_space(0'\r).
cb_space(0'\n). cb_space(11).   cb_space(12).

cb_ws([C|T], R) :- cb_space(C), !, cb_ws(T, R).
cb_ws(L, L).

cb_strip(Cs, Out) :-
    cb_ws(Cs, A), reverse(A, R0), cb_ws(R0, R1), reverse(R1, Out).

cb_digits1([C|T], [C|Ds], R) :- cb_digit(C), cb_digits(T, Ds, R).
cb_digits([C|T], [C|Ds], R) :- cb_digit(C), !, cb_digits(T, Ds, R).
cb_digits(L, [], L).
cb_digit(C) :- C >= 0'0, C =< 0'9.

cb_contains(Hay, Needle) :- append(_, R, Hay), append(Needle, _, R), !.

cb_index(Hay, Needle, I) :- cb_index_(Hay, Needle, 0, I).
cb_index_(Hay, Needle, A, I) :-
    (   append(Needle, _, Hay) -> I = A
    ;   Hay = [_|T] -> A1 is A + 1, cb_index_(T, Needle, A1, I)
    ).

cb_take(N, _, []) :- N =< 0, !.
cb_take(_, [], []) :- !.
cb_take(N, [C|T], [C|R]) :- N1 is N - 1, cb_take(N1, T, R).
