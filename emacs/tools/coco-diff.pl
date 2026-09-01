%% coco-diff.pl -- ask the mode's engine and cocolog the same questions.
%%
%%     cocolog -s emacs/tools/coco-diff.pl -- ANSWERS.tsv
%%
%% THE COCOLOG REWRITE OF the python3 block in coco-diff.sh. The shell still
%% runs emacs and collects its answers; this reads them and asks cocolog the
%% same questions. ANSWERS.tsv is four tab-separated columns per line --
%% path, query, the engine's answer, and an inline program when the question
%% carries one.
%%
%% Exits 1 if anything differs, which is what `make coco' reads.
%%
%% FAITHFUL, NOT IMPROVED, and that is a decision worth stating. blocks_of
%% below splits a file on lines that OPEN AT COLUMN ONE with a lower-case
%% name, which is cruder than clauses.pl's real reader and is kept anyway:
%% the split decides which library clauses get shadowed out, so a better
%% splitter would change which program each query is asked against, and the
%% answers with it. Changing the reader and the comparison in one move would
%% leave nothing to blame when a row disagreed.

:- use_module(library(main)).
:- use_module(library(process)).

%% The library cocolog is given with every question: SWI's dcg/basics and
%% yall as cocolog vendors them, then the few rules the engine's library has
%% that the vendored files do not.
cd_library_rel('lib/swipl/dcg_basics.pl').
cd_library_rel('lib/swipl/yall.pl').
cd_library_rel('tools/coco-prelude.pl').

main([TSV|_]) :-
    cd_binary(Bin),
    read_file_to_codes(TSV, Cs),
    cd_lines(Cs, Lines),
    cd_rows(Lines, Bin, 0, A, 0, D),
    N is A + D,
    format("~n~w queries, ~w agree, ~w differ~n", [N, A, D]),
    D =:= 0.

cd_binary(Bin) :-
    ( getenv('COCOLOG', B) -> Bin = B ; current_prolog_flag(executable, Bin) ).

cd_root(Root) :-
    cd_binary(Bin),
    atom_codes(Bin, Cs),
    ( append(R, [0'/|Base], Cs), \+ memberchk(0'/, Base) -> atom_codes(Root, R)
    ; Root = '.' ).

cd_rows([], _, A, A, D, D).
cd_rows([L|Ls], Bin, A0, A, D0, D) :-
    cd_fields(L, [Path, Query, Ours, Inline]),
    (   Query == ''
    ->  cd_rows(Ls, Bin, A0, A, D0, D)
    ;   cd_program(Path, Inline, Prog),
        cd_ask(Bin, Prog, Query, Coco),
        cd_norm(Ours, NO),
        cd_norm(Coco, NC),
        (   NO == NC
        ->  A1 is A0 + 1, cd_rows(Ls, Bin, A1, A, D0, D)
        ;   D1 is D0 + 1,
            cd_trim_dot(Query, Q),
            format("DIFFERS  ~w~n  ?- ~w.~n    engine : ~w~n    cocolog: ~w~n",
                   [Path, Q, Ours, Coco]),
            cd_rows(Ls, Bin, A0, A, D1, D)
        )
    ).

%% Four columns, padded, exactly as (line.split('\t') + ['','',''])[:4].
cd_fields(L, [A, B, C, D]) :-
    cd_split_tabs(L, Parts0),
    append(Parts0, ['', '', ''], Padded),
    Padded = [A, B, C, D|_].

cd_split_tabs(Cs, [A|Rest]) :-
    (   append(Head, [0'\t|Tail], Cs)
    ->  atom_codes(A, Head), cd_split_tabs(Tail, Rest)
    ;   atom_codes(A, Cs), Rest = []
    ).

%% ---- the program a question is asked against ----------------------------
%%
%% The fourth column when the line carries one -- a snippet brings its rule
%% along -- and the file named by the first column otherwise.

cd_program(_, Inline, Text) :-
    Inline \== '',
    !,
    atom_codes(Inline, Cs),
    cd_unescape(Cs, Text).
cd_program(Path, _, Text) :-
    (   Path \== '', exists_file(Path)
    ->  read_file_to_codes(Path, Text)
    ;   Text = []
    ).

cd_unescape([], []) :- !.
cd_unescape([0'\\, C|T], [U|R]) :- !, cd_esc(C, U), cd_unescape(T, R).
cd_unescape([C|T], [C|R]) :- cd_unescape(T, R).

cd_esc(0'n, 0'\n) :- !.
cd_esc(0't, 0'\t) :- !.
cd_esc(C, C).

%% ---- the blocks ----------------------------------------------------------
%%
%% A block starts at a line whose FIRST COLUMN opens a head -- a lower-case
%% name -- and runs to the next such line. Directives, comments and
%% operator-headed clauses keep no name and are never dropped.

cd_blocks(Text, Blocks) :-
    cd_lines_keep(Text, Lines),
    cd_blocks_(Lines, none, [], Blocks).

cd_blocks_([], Name, Acc, Out) :-
    !,
    ( Acc == [] -> Out = [] ; reverse(Acc, Ls), Out = [b(Name, Ls)] ).
cd_blocks_([L|Ls], Name, Acc, Out) :-
    (   cd_head_name(L, N)
    ->  (   Acc == []
        ->  Out = Rest
        ;   reverse(Acc, Prev), Out = [b(Name, Prev)|Rest]
        ),
        cd_blocks_(Ls, N, [L], Rest)
    ;   cd_blocks_(Ls, Name, [L|Acc], Out)
    ).

%% `^([a-z][A-Za-z0-9_]*)' -- re.match, so anchored at the line's start.
cd_head_name([C|T], Name) :-
    C >= 0'a, C =< 0'z,
    cd_name_rest(T, Ns),
    atom_codes(Name, [C|Ns]).

cd_name_rest([C|T], [C|Ns]) :- cd_word(C), !, cd_name_rest(T, Ns).
cd_name_rest(_, []).

cd_word(C) :- C >= 0'a, C =< 0'z.
cd_word(C) :- C >= 0'A, C =< 0'Z.
cd_word(C) :- C >= 0'0, C =< 0'9.
cd_word(0'_).

cd_defined_names(Text, Names) :-
    cd_blocks(Text, Bs),
    findall(N, ( member(b(N, _), Bs), N \== none ), Ns),
    sort(Ns, Names).

%% ---- the shadow-filtered library -----------------------------------------
%%
%% The engine resolves a program's own rules before its library's, the way a
%% module's definition shadows an import. cocolog consults into one
%% namespace, so the same reading is made by leaving out every library clause
%% for a predicate the program defines -- and, so no half-library rule is
%% left calling across the seam, every library clause that reaches one of
%% those, to a fixpoint.

cd_filtered_library(Prog, Out) :-
    cd_library_text(Lib0),
    cd_strip_block_comments(Lib0, Lib),
    cd_defined_names(Prog, Shadowed),
    cd_blocks(Lib, Blocks),
    findall(N, ( member(b(N, _), Blocks), N \== none, memberchk(N, Shadowed) ), D0),
    sort(D0, Dropped0),
    cd_fixpoint(Blocks, Dropped0, Dropped),
    findall(Ls,
            ( member(b(N, Ls), Blocks), ( N == none ; \+ memberchk(N, Dropped) ) ),
            Kept),
    cd_join_blocks(Kept, Out).

cd_fixpoint(Blocks, In, Out) :-
    findall(N,
            ( member(b(N, Ls), Blocks), N \== none, \+ memberchk(N, In),
              cd_join_nl(Ls, T), cd_calls(T, In) ),
            More0),
    sort(More0, More),
    (   More == []
    ->  Out = In
    ;   append(In, More, U0), sort(U0, U),
        cd_fixpoint(Blocks, U, Out)
    ).

%% Non-nil when the block mentions one of NAMES outside remarks.
cd_calls(Text, Names) :-
    cd_strip_line_comments(Text, Bare),
    member(N, Names),
    atom_codes(N, NCs),
    cd_word_occurs(Bare, NCs),
    !.

cd_word_occurs(Hay, Needle) :-
    cd_word_occ(Hay, Needle, none).

cd_word_occ(Hay, Needle, Prev) :-
    (   append(Needle, After, Hay),
        cd_boundary(Prev),
        ( After = [C|_] -> \+ cd_word(C) ; true )
    ->  true
    ;   Hay = [C|T],
        cd_word_occ(T, Needle, C)
    ).

cd_boundary(none) :- !.
cd_boundary(C) :- \+ cd_word(C).

cd_strip_line_comments(Text, Out) :-
    cd_lines_keep(Text, Ls),
    findall(B, ( member(L, Ls), cd_before_pct(L, B) ), Bs),
    cd_join_nl(Bs, Out).

cd_before_pct([], []) :- !.
cd_before_pct([0'%|_], []) :- !.
cd_before_pct([C|T], [C|R]) :- cd_before_pct(T, R).

%% `/*...*/' non-greedy, DOTALL -- a remark reads like clauses to the line
%% splitter above.
cd_strip_block_comments([], []) :- !.
cd_strip_block_comments([0'/, 0'*|T], Out) :-
    !,
    cd_to_close(T, Rest),
    cd_strip_block_comments(Rest, Out).
cd_strip_block_comments([C|T], [C|R]) :- cd_strip_block_comments(T, R).

cd_to_close([], []) :- !.
cd_to_close([0'*, 0'/|T], T) :- !.
cd_to_close([_|T], R) :- cd_to_close(T, R).

cd_library_text(Text) :-
    cd_root(Root),
    findall(Cs,
            ( cd_library_rel(Rel),
              cd_lib_path(Root, Rel, P),
              exists_file(P),
              read_file_to_codes(P, Cs)
            ),
            Parts),
    cd_join_nl(Parts, Text).

%% `tools/coco-prelude.pl' is relative to the mode's directory, the other two
%% to the repository root beside the binary.
cd_lib_path(_, 'tools/coco-prelude.pl', 'tools/coco-prelude.pl') :- !.
cd_lib_path(Root, Rel, P) :- atomic_list_concat([Root, '/', Rel], P).

cd_join_blocks([], []) :- !.
cd_join_blocks(Blocks, Out) :-
    findall(T, ( member(Ls, Blocks), cd_join_nl(Ls, T) ), Texts),
    cd_join_nl(Texts, Out).

%% ---- the query's variables ------------------------------------------------
%%
%% The engine names a solution by the variables written in the query, so
%% cocolog is asked to print those same names. A name inside a quoted atom or
%% a string is text, not a variable, and a name that starts with an
%% underscore says nothing worth comparing.

cd_variables(Query, Names) :-
    atom_codes(Query, Cs),
    cd_blank_quoted(Cs, Bare),
    cd_var_scan(Bare, none, [], Names).

cd_blank_quoted([], []) :- !.
cd_blank_quoted([0''|T], [0'', 0''|R]) :- !, cd_skip_quoted(T, 0'', Rest), cd_blank_quoted(Rest, R).
cd_blank_quoted([0'"|T], [0'", 0'"|R]) :- !, cd_skip_quoted(T, 0'", Rest), cd_blank_quoted(Rest, R).
cd_blank_quoted([C|T], [C|R]) :- cd_blank_quoted(T, R).

cd_skip_quoted([], _, []) :- !.
cd_skip_quoted([0'\\, _|T], Q, R) :- !, cd_skip_quoted(T, Q, R).
cd_skip_quoted([Q|T], Q, T) :- !.
cd_skip_quoted([_|T], Q, R) :- cd_skip_quoted(T, Q, R).

cd_var_scan([], _, Acc, Names) :- !, reverse(Acc, Names).
cd_var_scan(Cs, Prev, Acc, Names) :-
    Cs = [C|T],
    (   cd_var_start(C), cd_boundary(Prev)
    ->  cd_name_rest(T, Ns),
        atom_codes(Name, [C|Ns]),
        length(Ns, L), Skip is L,
        cd_drop(Skip, T, Rest),
        cd_last_of([C|Ns], Last),
        (   ( C == 0'_ ; memberchk(Name, Acc) )
        ->  Acc1 = Acc
        ;   Acc1 = [Name|Acc]
        ),
        cd_var_scan(Rest, Last, Acc1, Names)
    ;   cd_var_scan(T, C, Acc, Names)
    ).

cd_var_start(C) :- C >= 0'A, C =< 0'Z.
cd_var_start(0'_).

cd_last_of(L, C) :- reverse(L, [C|_]).

cd_drop(0, L, L) :- !.
cd_drop(_, [], []) :- !.
cd_drop(N, [_|T], R) :- N1 is N - 1, cd_drop(N1, T, R).

%% ---- asking cocolog --------------------------------------------------------
%%
%% One --local run per query: consult the shadow-filtered library and the
%% program, prove a goal that prints each solution as NAME=VALUE bindings on
%% a line of its own, then join the first ten the way the engine joins its
%% own. Every printed line opens on a fresh one, so a query that writes
%% cannot run its text into an answer.

cd_ask(Bin, Prog, Query, Answer) :-
    cd_trim_dot(Query, Q),
    cd_variables(Q, Names),
    cd_goal(Q, Names, Goal),
    tmp_file(cdlib, LibF0), atom_concat(LibF0, '.pl', LibF),
    tmp_file(cdprog, ProgF0), atom_concat(ProgF0, '.pl', ProgF),
    tmp_file(cderr, ErrF),
    cd_filtered_library(Prog, Lib),
    write_file_from_codes(LibF, Lib),
    write_file_from_codes(ProgF, Prog),
    cd_command(Bin, LibF, ProgF, Goal, ErrF, Cmd),
    (   catch(proc_run(Cmd, 60000, Out, Exit), _, fail)
    ->  ( Exit =:= 124 -> Answer = '<timeout>' ; cd_answer(ErrF, Out, Names, Answer) )
    ;   Answer = '<timeout>'
    ),
    cd_rm(LibF), cd_rm(ProgF), cd_rm(ErrF).

cd_rm(F) :- ( exists_file(F) -> catch(delete_file(F), _, true) ; true ).

cd_goal(Q, [], Goal) :-
    !,
    atomic_list_concat(['( (', Q, ') -> format("~ncoco_true~n", []) ; true )'], Goal).
cd_goal(Q, Names, Goal) :-
    cd_fmt(Names, Fmt),
    cd_join_commas(Names, Args),
    atomic_list_concat(['forall((', Q, '), format("~n', Fmt, '~n", [', Args, ']))'], Goal).

cd_fmt([], '') :- !.
cd_fmt([N], A) :- !, atomic_list_concat([N, '=~q'], A).
cd_fmt([N|Ns], A) :-
    cd_fmt(Ns, R), atomic_list_concat([N, '=~q,', R], A).

cd_join_commas([], '') :- !.
cd_join_commas([X], X) :- !.
cd_join_commas([X|Xs], A) :- cd_join_commas(Xs, R), atomic_list_concat([X, ', ', R], A).

%% STDERR TO A FILE, because error_text reads it and proc_run/4 answers only
%% what came back on stdout.
cd_command(Bin, LibF, ProgF, Goal, ErrF, Cmd) :-
    cd_shellq(Goal, QG),
    atomic_list_concat([Bin, ' --local run ', LibF, ' ', ProgF, ' ', QG,
                        ' 2>', ErrF], Cmd).

cd_shellq(A, Q) :-
    atom_codes(A, Cs),
    cd_sq(Cs, Ds),
    atom_codes(Inner, Ds),
    atomic_list_concat(['''', Inner, ''''], Q).

%% A single quote inside single quotes closes, escapes and reopens.
cd_sq([], []).
cd_sq([0''|T], Out) :- !, cd_sq(T, R), append("'\\''", R, Out).
cd_sq([C|T], [C|R]) :- cd_sq(T, R).

cd_answer(ErrF, Out, Names, Answer) :-
    (   cd_error_text(ErrF, E)
    ->  Answer = E
    ;   cd_keep(Out, Names, Lines),
        (   Lines == []
        ->  Answer = 'no solutions'
        ;   Names == []
        ->  Answer = true
        ;   cd_take(10, Lines, First),
            cd_join_semi(First, Answer)
        )
    ).

cd_keep(Out, Names, Kept) :-
    cd_lines_keep(Out, Ls),
    (   Names = [N|_]
    ->  atom_codes(N, NCs), append(NCs, "=", Pfx)
    ;   Pfx = "coco_true"
    ),
    findall(A,
            ( member(L, Ls),
              ( Names == [] -> L == Pfx ; append(Pfx, _, L) ),
              atom_codes(A, L)
            ),
            Kept).

cd_join_semi([X], X) :- !.
cd_join_semi([X|Xs], A) :- cd_join_semi(Xs, R), atomic_list_concat([X, ' ; ', R], A).

%% cocolog's uncaught exception, said the way the engine says it.
cd_error_text(ErrF, Text) :-
    exists_file(ErrF),
    read_file_to_codes(ErrF, Cs),
    cd_lines_keep(Cs, Ls),
    member(L, Ls),
    append(_, R0, L),
    append("uncaught exception:", R1, R0),
    !,
    cd_strip(R1, Term),
    (   cd_existence(Term, PI)
    ->  atom_codes(PIA, PI),
        atomic_list_concat(['ERROR: unknown procedure ', PIA], Text)
    ;   atom_codes(TA, Term),
        atomic_list_concat(['ERROR: uncaught exception: ', TA], Text)
    ).

cd_existence(Term, PI) :-
    append(_, R0, Term),
    append("existence_error(procedure,", R1, R0),
    !,
    cd_upto_paren(R1, Inner),
    cd_strip(Inner, PI).

cd_upto_paren([0')|_], []) :- !.
cd_upto_paren([C|T], [C|R]) :- cd_upto_paren(T, R).

%% ---- normalising an answer -------------------------------------------------
%%
%% Reduce an answer to what it says, not how it was written. The two writers
%% differ in three harmless ways: an unbound variable is printed by its name
%% here and as _123 there, they space terms differently, and one
%% parenthesises a lone operator atom.

cd_norm(A, Out) :-
    atom_codes(A, Cs0),
    cd_strip(Cs0, Cs1),
    cd_despace(Cs1, Cs),
    cd_split_bindings(Cs, Parts),
    findall(P, ( member(B, Parts), cd_norm_binding(B, P) ), Ps),
    cd_join_comma_codes(Ps, OutCs),
    atom_codes(Out, OutCs).

cd_norm_binding(B, Out) :-
    (   append(Name, [0'=|Value], B)
    ->  cd_num_to_us(Value, V1),
        cd_upper_to_us(V1, V2),
        cd_unparen_op(V2, V3),
        append(Name, [0'=|V3], Out)
    ;   Out = B
    ).

%% `_G?\d+' -> `_'
cd_num_to_us([], []) :- !.
cd_num_to_us([0'_|T], [0'_|R]) :-
    cd_us_tail(T, T1),
    !,
    cd_num_to_us(T1, R).
cd_num_to_us([C|T], [C|R]) :- cd_num_to_us(T, R).

cd_us_tail([0'G|T], R) :- !, cd_digits1(T, _, R).
cd_us_tail(T, R) :- cd_digits1(T, _, R).

cd_digits1([C|T], [C|Ds], R) :- cd_digit(C), cd_digits(T, Ds, R).
cd_digits([C|T], [C|Ds], R) :- cd_digit(C), !, cd_digits(T, Ds, R).
cd_digits(L, [], L).
cd_digit(C) :- C >= 0'0, C =< 0'9.

%% `\b[A-Z][A-Za-z0-9_]*\b' -> `_' : a name still unbound
cd_upper_to_us(Cs, Out) :- cd_u2u(Cs, none, Out).

cd_u2u([], _, []) :- !.
cd_u2u([C|T], Prev, Out) :-
    (   C >= 0'A, C =< 0'Z, cd_boundary(Prev)
    ->  cd_name_rest(T, Ns),
        length(Ns, L),
        cd_drop(L, T, Rest),
        cd_last_of([C|Ns], Last),
        Out = [0'_|R],
        cd_u2u(Rest, Last, R)
    ;   Out = [C|R],
        cd_u2u(T, C, R)
    ).

%% `\((<|>|=)\)' -> the operator alone
cd_unparen_op([], []) :- !.
cd_unparen_op([0'(, C, 0')|T], [C|R]) :-
    memberchk(C, [0'<, 0'>, 0'=]),
    !,
    cd_unparen_op(T, R).
cd_unparen_op([C|T], [C|R]) :- cd_unparen_op(T, R).

%% Split "A=1,B=f(x,y)" into its bindings, not into its commas.
cd_split_bindings(Cs, Parts) :- cd_sb(Cs, 0, [], Parts).

cd_sb([], _, Cur, Out) :- !, ( Cur == [] -> Out = [] ; reverse(Cur, P), Out = [P] ).
cd_sb([C|T], D, Cur, Out) :-
    (   memberchk(C, [0'(, 0'[]) -> D1 is D + 1 ; memberchk(C, [0'), 0']]) -> D1 is D - 1 ; D1 = D ),
    (   C =:= 0',, D1 =:= 0
    ->  reverse(Cur, P), Out = [P|R], cd_sb(T, D1, [], R)
    ;   cd_sb(T, D1, [C|Cur], Out)
    ).

cd_join_comma_codes([], []) :- !.
cd_join_comma_codes([P], P) :- !.
cd_join_comma_codes([P|Ps], Out) :-
    cd_join_comma_codes(Ps, R), append(P, [0',|R], Out).

%% ---- text ------------------------------------------------------------------

cd_lines([], []) :- !.
cd_lines(Cs, [L|Ls]) :-
    ( append(L, [0'\n|R], Cs) -> true ; L = Cs, R = [] ),
    !,
    ( R == [], L == [] -> Ls = [] ; cd_lines(R, Ls) ).

%% splitlines(), which keeps interior blanks and drops nothing else.
cd_lines_keep([], []) :- !.
cd_lines_keep(Cs, Out) :-
    ( append(L, [0'\n|R], Cs) -> Out = [L|Rest], cd_lines_keep(R, Rest)
    ; Out = [Cs] ).

cd_join_nl([], []) :- !.
cd_join_nl([X], X) :- !.
cd_join_nl([X|Xs], Out) :- cd_join_nl(Xs, R), append(X, [0'\n|R], Out).

cd_space(0' ). cd_space(0'\t). cd_space(0'\r). cd_space(0'\n).

cd_strip(Cs, Out) :-
    cd_ws(Cs, A), reverse(A, R0), cd_ws(R0, R1), reverse(R1, Out).

cd_ws([C|T], R) :- cd_space(C), !, cd_ws(T, R).
cd_ws(L, L).

cd_despace([], []) :- !.
cd_despace([C|T], R) :- cd_space(C), !, cd_despace(T, R).
cd_despace([C|T], [C|R]) :- cd_despace(T, R).

cd_trim_dot(A, Out) :-
    atom_codes(A, Cs), cd_strip(Cs, S),
    ( append(P, ".", S) -> atom_codes(Out, P) ; atom_codes(Out, S) ).

cd_take(N, _, []) :- N =< 0, !.
cd_take(_, [], []) :- !.
cd_take(N, [X|T], [X|R]) :- N1 is N - 1, cd_take(N1, T, R).
