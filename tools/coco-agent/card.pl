%% card.pl -- the dialect card, as data, with every citation checked.
%%
%%     cocolog --local run card.pl cd_main -- --check       every anchor is there
%%     ...                                     --check --fix   drift renumbered
%%     ...                                     --card        the card, regenerated
%%     ...                                     --patterns    the S1 terms
%%     ...                                     --facts       write traps.pl
%%
%% THE COCOLOG REWRITE OF traps.py, and the Python is gone. Same checks, same
%% outputs: traps.pl comes out byte-identical but for the header line naming
%% its generator.
%%
%% The card in library/llm/DESIGN.md section 4 is thirty-six rows of "SWI
%% writes X, cocolog needs Y, because <source citation>". A citation nobody
%% checks is a citation that rots: a line number moves and the row goes on
%% asserting a fact about code that is no longer there. So each row carries,
%% beside its cite, an ANCHOR -- a literal substring that must appear inside
%% the cited line range -- and this file checks every one.
%%
%% THE ANCHOR IS CODE, NEVER PROSE NEAR IT. Comments are the part of a file
%% that gets rewritten without the behaviour changing, so anchoring on one
%% gives a check that passes while the claim quietly stops being true. Row F1
%% anchors on `(== d 116)' and not on the word "column"; row I1 on
%% `coco_arg_key' and not on the declaration's shouted comment above it. P1
%% anchored on a comment for a while and the rule caught it the hard way: a
%% rewrite of that comment deleted the anchor, and the check said GONE.
%%
%% Two rows anchor on a comment anyway and say so rather than pretending:
%% Z1's page-size limit lives in parsi/01-schema.parsi as a paragraph of
%% measured numbers with no code beside it, and R2's evidence IS the Prolog
%% text of the clauses in a *X-prolog* string table. Both are quoted exactly.
%%
%% A MOVED ANCHOR IS NOT A BROKEN CITATION when the anchor is unique in its
%% file. The range is a finding aid there and nothing else -- if the text
%% appears exactly once, no range was ever distinguishing it from anything --
%% so the code moving is a fact about the code, not a defect in the card, and
%% --check accepts it, reports it, and --fix renumbers it.
%%
%% The range earns its keep when the anchor is NOT unique, and then it is the
%% whole answer: `coco_arg_key', `coco_new_int' and `coco_num_value' each
%% appear in lib/ as a declaration, a definition and a use or two, and a range
%% that has drifted off the definition is now sitting on the declaration
%% saying something subtly different. Nothing here can know which was meant,
%% so that stays a complaint for a human.
%%
%% An anchor that appears NOWHERE is the failure this file exists to catch.
%% The evidence for the claim has been deleted or rewritten, and the row needs
%% rereading rather than renumbering; the message says so in those words,
%% because the reflex on a red citation check is to reach for the line number.
%%
%% ONE CHECK GOT STRUCTURALLY SIMPLER RATHER THAN TRANSLATED. traps.py
%% validated a pattern by counting braces through the TEXT of the term,
%% tracking quotes and a functor stack by hand, because Python has no reader
%% for cocolog terms. Here the pattern IS a term: term_to_atom/2 reads it and
%% cd_bad_term/2 walks it. Unbalanced parentheses cannot even be represented,
%% so that half of the check disappears and what is left -- a functor no
%% clause of cl_at/4 implements -- is a walk over the arguments.

:- use_module(library(json)).

%% ---- where things are -------------------------------------------------

cd_root(Root) :-
    (   getenv('COCOLOG_ROOT', R)
    ->  Root = R
    ;   working_directory(Root, Root)
    ).

cd_path(Rel, Abs) :-
    cd_root(Root),
    atomic_list_concat([Root, '/', Rel], Abs).

%% Overridable so the suite can point the checker at a COPY with one cite
%% broken on purpose, and the real card is never written to by a test.
cd_traps(Path) :-
    (   getenv('COCOLOG_TRAPS', P)
    ->  Path = P
    ;   cd_path('tools/coco-agent/traps.jsonl', Path)
    ).

%% ---- the rows ----------------------------------------------------------
%%
%% RAW LINES ARE KEPT BESIDE THE PARSED ROWS, because --fix rewrites the file
%% surgically. Re-serialising every row would reformat all thirty-six and
%% bury a two-line change in a seventy-two-line diff.

cd_rows(Rows) :-
    cd_traps(Path),
    read_file_to_codes(Path, Codes),
    cd_lines(Codes, Lines),
    findall(row(N, Term, Line),
            ( nth0(N, Lines, Line),
              cd_content(Line),
              once(json_parse(Line, Term))
            ),
            Rows).

cd_content(Line) :-
    cd_lstrip(Line, S),
    S \== [],
    S \= [0'#|_].

cd_lines([], []) :- !.
cd_lines(Codes, [L|Ls]) :-
    (   append(L, [0'\n|Rest], Codes)
    ->  true
    ;   L = Codes, Rest = []
    ),
    !,
    (   Rest == [], L == []
    ->  Ls = []
    ;   cd_lines(Rest, Ls)
    ).

cd_lstrip([C|T], R) :- cd_space(C), !, cd_lstrip(T, R).
cd_lstrip(L, L).

cd_space(0' ).  cd_space(0'\t).  cd_space(0'\n).
cd_space(0'\r). cd_space(12).    cd_space(11).

%% A field of a row, as an atom. json_parse/2 gives strings as atoms.
cd_get(json(Ps), Key, Value) :- memberchk(Key-Value, Ps).

cd_get_or(Term, Key, _, V) :- cd_get(Term, Key, V), !.
cd_get_or(_, _, D, D).

%% ---- what a row must have ---------------------------------------------

cd_required(id).        cd_required(severity).  cd_required(rule).
cd_required(swi).       cd_required(cocolog).   cd_required(why).
cd_required(cite).

cd_severity('HARD').  cd_severity('WARN').  cd_severity('PROMPT').

%% The vocabulary lint.pl's cl_at/4 implements, split by what its arguments
%% are. Inside the DATA ones the argument is literal text or a character set
%% -- `lit(format)' names the word format, it does not call a constructor --
%% so the walk stops there rather than reporting every literal in the table
%% as an unknown functor.
cd_ctor_pattern(seq).   cd_ctor_pattern(alt).
cd_ctor_data(lit).      cd_ctor_data(notword).  cd_ctor_data(oneof).
cd_ctor_data(noneof).   cd_ctor_data(someof).   cd_ctor_data(exactly).
cd_ctor_nullary(ws).    cd_ctor_nullary(bstart).
cd_ctor_nullary(bend).  cd_ctor_nullary(bol).

cd_ctor(C) :- cd_ctor_pattern(C).
cd_ctor(C) :- cd_ctor_data(C).
cd_ctor(C) :- cd_ctor_nullary(C).

%% cd_bad_term(+PatternAtom, -Complaints) is det.
%%
%% NOT A PARSER, and it does not need to be -- cocolog reads the term for
%% real when it consults traps.pl, and a malformed one fails loudly there.
%% What this catches is the case that does NOT fail loudly: a well-formed
%% term whose functor no clause of cl_at/4 matches, which loads fine and
%% quietly never fires. A bare `bstrt' where `bstart' was meant is caught.
cd_bad_term(Atom, Complaints) :-
    (   catch(term_to_atom(Term, Atom), _, fail)
    ->  findall(C, cd_walk(Term, C), Complaints)
    ;   Complaints = ['pattern is not a readable term']
    ).

cd_walk(Term, Complaint) :-
    var(Term),
    !,
    Complaint = 'pattern has an unbound variable in it'.
cd_walk(Term, Complaint) :-
    atom(Term),
    !,
    \+ cd_ctor(Term),
    format(atom(Complaint),
           "unknown constructor ~q -- lint.pl's cl_at/4 has no clause for it, so the rule would never fire",
           [Term]).
cd_walk(Term, _) :- \+ compound(Term), !, fail.
cd_walk(Term, Complaint) :-
    functor(Term, F, _),
    (   \+ cd_ctor(F),
        format(atom(Complaint),
               "unknown constructor ~q -- lint.pl's cl_at/4 has no clause for it, so the rule would never fire",
               [F])
    ;   %% A DATA constructor's arguments are literal text, not more
        %% pattern, so the walk stops. That distinction is the whole reason
        %% the Python version reported every literal in the table as an
        %% unknown functor until it was split this way.
        %%
        %% `=..' AND NOT arg/3: arg(N, T, A) with N unbound enumerates in
        %% SWI and raises instantiation_error here, from inside a findall,
        %% where C1 says an outer catch will never see it. The symptom was
        %% an uncaught error with no indication of which row produced it.
        \+ cd_ctor_data(F),
        Term =.. [_|Args],
        member(A, Args),
        cd_walk_arg(A, Complaint)
    ).

cd_walk_arg(A, C) :- is_list(A), !, member(E, A), cd_walk(E, C).
cd_walk_arg(A, C) :- cd_walk(A, C).

%% ---- the cites ---------------------------------------------------------

%% cd_parse_cite(+At, -Rel, -First, -Last) is semidet.
%% `path:LINE' or `path:A-B', both 1-based inclusive.
cd_parse_cite(At, Rel, First, Last) :-
    atom_codes(At, Cs),
    cd_last_colon(Cs, PathCs, SpanCs),
    PathCs \== [],
    (   append(ACs, [0'-|BCs], SpanCs)
    ->  true
    ;   ACs = SpanCs, BCs = SpanCs
    ),
    catch(( number_codes(First, ACs), number_codes(Last, BCs) ), _, fail),
    atom_codes(Rel, PathCs).

cd_last_colon(Cs, Path, Span) :-
    append(Path, [0':|Span], Cs),
    \+ memberchk(0':, Span),
    !.

%% cd_cite_status(+Anchor, +First, +Last, +Lines, -Verdict, -Line, -Count)
%%
%% ok | drift | ambiguous | gone. See the header for the argument.
cd_cite_status(Anchor, First, Last, Lines, Verdict, Line, N) :-
    atom_codes(Anchor, ACs),
    cd_region(Lines, First, Last, Region),
    (   cd_contains(Region, ACs)
    ->  Verdict = ok, Line = none, N = 1
    ;   cd_whole(Lines, Whole),
        cd_occurrences(Whole, ACs, Positions),
        length(Positions, N),
        (   N =:= 0
        ->  Verdict = gone, Line = none
        ;   Positions = [P|_],
            cd_line_of(Whole, P, Line),
            ( N =:= 1 -> Verdict = drift ; Verdict = ambiguous )
        )
    ).

cd_region(Lines, First, Last, Region) :-
    Skip is First - 1,
    Take is Last - First + 1,
    cd_drop(Skip, Lines, Tail),
    cd_take(Take, Tail, Sel),
    cd_unlines(Sel, Region).

cd_whole(Lines, Whole) :- cd_unlines(Lines, Whole).

cd_unlines([], []) :- !.
cd_unlines([L|Ls], Out) :-
    cd_unlines(Ls, Rest),
    append(L, [0'\n|Rest], Out).

cd_drop(0, L, L) :- !.
cd_drop(_, [], []) :- !.
cd_drop(N, [_|T], R) :- N1 is N - 1, cd_drop(N1, T, R).

cd_take(N, _, []) :- N =< 0, !.
cd_take(_, [], []) :- !.
cd_take(N, [C|T], [C|R]) :- N1 is N - 1, cd_take(N1, T, R).

cd_contains(Hay, Needle) :- append(_, Rest, Hay), append(Needle, _, Rest), !.

%% Every offset the anchor starts at. NON-OVERLAPPING, like str.count.
cd_occurrences(Hay, Needle, Positions) :- cd_occ(Hay, Needle, 0, Positions).

cd_occ(Hay, Needle, Pos, Out) :-
    (   append(Needle, Rest, Hay)
    ->  length(Needle, L),
        Next is Pos + L,
        Out = [Pos|More],
        cd_occ(Rest, Needle, Next, More)
    ;   Hay = [_|T]
    ->  P1 is Pos + 1,
        cd_occ(T, Needle, P1, Out)
    ;   Out = []
    ).

cd_line_of(Whole, Pos, Line) :-
    cd_take(Pos, Whole, Before),
    cd_count_nl(Before, 0, N),
    Line is N + 1.

cd_count_nl([], A, A).
cd_count_nl([0'\n|T], A, N) :- !, A1 is A + 1, cd_count_nl(T, A1, N).
cd_count_nl([_|T], A, N) :- cd_count_nl(T, A, N).

%% ---- the check ----------------------------------------------------------

%% cd_check(-Complaints, -Drifts) is det.
%% A drift is d(Id, Anchor, OldAt, NewAt) and is NOT a complaint.
cd_check(Complaints, Drifts) :-
    cd_rows(Rows),
    findall(C, cd_row_complaint(Rows, C), C0),
    findall(D, cd_row_drift(Rows, D), Drifts),
    cd_dup_ids(Rows, Dups),
    append(C0, Dups, Complaints).

cd_row_complaint(Rows, Out) :-
    member(row(_, T, _), Rows),
    cd_get_or(T, id, '<no id>', Id),
    (   cd_required(K), \+ cd_get(T, K, _),
        format(atom(Out), "~w: missing field ~w", [Id, K])
    ;   cd_get_or(T, scan, code, Scan),
        \+ memberchk(Scan, [code, text]),
        format(atom(Out), "~w: scan ~q is not code or text", [Id, Scan])
    ;   cd_get_or(T, severity, none, Sev),
        \+ cd_severity(Sev),
        format(atom(Out), "~w: severity ~q is not one of HARD/WARN/PROMPT", [Id, Sev])
    ;   cd_get(T, pattern, P), P \== '',
        cd_bad_term(P, Cs), member(C, Cs),
        format(atom(Out), "~w: ~w", [Id, C])
    ;   cd_get(T, cite, Cites),
        member(Cite, Cites),
        cd_cite_complaint(Id, Cite, Out)
    ).

cd_cite_complaint(Id, Cite, Out) :-
    (   \+ ( cd_get(Cite, at, _), cd_get(Cite, anchor, _) )
    ->  format(atom(Out), "~w: a cite needs both `at' and `anchor'", [Id])
    ;   cd_get(Cite, at, At),
        cd_get(Cite, anchor, Anchor),
        (   \+ cd_parse_cite(At, _, _, _)
        ->  format(atom(Out), "~w: cite ~q is not path:LINE or path:A-B", [Id, At])
        ;   cd_parse_cite(At, Rel, First, Last),
            cd_path(Rel, Abs),
            (   \+ exists_file(Abs)
            ->  format(atom(Out), "~w: ~w does not exist", [Id, Rel])
            ;   read_file_to_codes(Abs, Codes),
                cd_lines(Codes, Lines),
                cd_cite_status(Anchor, First, Last, Lines, V, _, N),
                cd_verdict_complaint(V, Id, Rel, First, Last, Anchor, N, Lines, Out)
            )
        )
    ).

cd_verdict_complaint(gone, Id, Rel, _, _, Anchor, _, _, Out) :-
    cd_repr(Anchor, QA),
    format(atom(Out),
           "~w: anchor is GONE from ~w -- the claim's evidence was deleted or rewritten, so the row needs rereading, not renumbering\n      ~w",
           [Id, Rel, QA]).
cd_verdict_complaint(ambiguous, Id, Rel, First, Last, Anchor, N, Lines, Out) :-
    cd_whole(Lines, Whole),
    atom_codes(Anchor, ACs),
    cd_occurrences(Whole, ACs, Ps),
    findall(L, ( member(P, Ps), cd_line_of(Whole, P, L) ), Ls),
    cd_commas(Ls, Where),
    cd_repr(Anchor, QA),
    format(atom(Out),
           "~w: anchor is not in ~w:~w-~w and appears ~w times (lines ~w) -- the range is what picks the site, so which one this row means is yours to say\n      ~w",
           [Id, Rel, First, Last, N, Where, QA]).

cd_commas([], '') :- !.
cd_commas([X], A) :- !, atom_number(A, X).
cd_commas([X|Xs], A) :-
    cd_commas(Xs, R),
    atom_number(XA, X),
    atomic_list_concat([XA, ', ', R], A).

cd_row_drift(Rows, d(Id, Anchor, At, NewAt)) :-
    member(row(_, T, _), Rows),
    cd_get(T, id, Id),
    cd_get(T, cite, Cites),
    member(Cite, Cites),
    cd_get(Cite, at, At),
    cd_get(Cite, anchor, Anchor),
    cd_parse_cite(At, Rel, First, Last),
    cd_path(Rel, Abs),
    exists_file(Abs),
    read_file_to_codes(Abs, Codes),
    cd_lines(Codes, Lines),
    cd_cite_status(Anchor, First, Last, Lines, drift, Line, _),
    atom_number(LA, Line),
    atomic_list_concat([Rel, ':', LA], NewAt).

cd_dup_ids(Rows, Dups) :-
    findall(Id, ( member(row(_, T, _), Rows), cd_get(T, id, Id) ), Ids),
    findall(C,
            ( member(Id, Ids),
              cd_count(Id, Ids, N), N > 1,
              format(atom(C), "~w: duplicate id", [Id])
            ),
            Dups0),
    sort(Dups0, Dups).

cd_count(_, [], 0).
cd_count(X, [Y|T], N) :- cd_count(X, T, N0), ( X == Y -> N is N0 + 1 ; N = N0 ).

%% ---- --fix --------------------------------------------------------------
%%
%% IT WRITES `path:LINE' AND NOT A WINDOW, because one line is all it knows.
%% A range in the card is editorial -- somebody chose 782-808 to bracket a
%% whole set_prolog_flag block -- and nothing here can reconstruct which of
%% the moved block's lines they meant to include. Widening it back by hand
%% keeps working: a wider range still contains the anchor, so it stays `ok'.

cd_fix(Drifts, Written) :-
    cd_traps(Path),
    read_file_to_codes(Path, Codes),
    cd_lines(Codes, Lines),
    cd_fix_lines(Lines, Drifts, Out, 0, Written),
    cd_unlines(Out, NewCodes),
    atom_concat(Path, '.tmp', Tmp),
    write_file_from_codes(Tmp, NewCodes),
    rename_file(Tmp, Path).

cd_fix_lines([], _, [], N, N).
cd_fix_lines([L|Ls], Drifts, [L2|Out], N0, N) :-
    cd_fix_line(L, Drifts, L2, N0, N1),
    cd_fix_lines(Ls, Drifts, Out, N1, N).

cd_fix_line(Line, Drifts, Out, N0, N) :-
    (   cd_content(Line),
        once(json_parse(Line, T)),
        cd_get(T, id, Id),
        member(d(Id, Anchor, Old, New), Drifts),
        cd_replace_in_cite(Line, Anchor, Old, New, L2),
        %% AND IT MUST HAVE CHANGED SOMETHING. cd_replace_in_cite/5 walks
        %% the line and hands back what it found; when no cite object holds
        %% both the anchor and the old range that is the line unaltered, and
        %% recursing on it is an infinite loop. It was: the process was
        %% killed by the OOM killer rather than failing, which is the least
        %% informative way a Prolog bug can present itself.
        L2 \== Line
    ->  N1 is N0 + 1,
        cd_fix_line(L2, Drifts, Out, N1, N)
    ;   Out = Line, N = N0
    ).

%% The raw line with `at' changed inside the cite object holding ANCHOR.
%% Scoped, because a row may cite two ranges and one of them may be another
%% row's. Brace counting rather than a pattern, because an anchor may
%% legitimately contain a brace.
cd_replace_in_cite(Line, Anchor, Old, New, Out) :-
    cd_json_atom(Anchor, AJ),
    cd_json_atom(Old, OJ),
    cd_json_atom(New, NJ),
    cd_scan_objects(Line, 0, [], AJ, OJ, NJ, Out).

%% Depth 2 is a cite object inside the row object.
cd_scan_objects(Cs, Depth, Acc, AJ, OJ, NJ, Out) :-
    cd_obj(Cs, Depth, Acc, AJ, OJ, NJ, Out).

cd_obj([], _, Acc, _, _, _, Out) :- !, reverse(Acc, Out).
cd_obj([0'"|T], D, Acc, A, O, N, Out) :-
    !,
    cd_obj_str(T, D, [0'"|Acc], A, O, N, Out).
cd_obj([0'{|T], D, Acc, A, O, N, Out) :-
    !,
    D1 is D + 1,
    (   D1 =:= 2,
        cd_object_span(T, Body, Rest),
        cd_contains(Body, A),
        cd_contains(Body, O)
    ->  cd_replace_once(Body, O, N, Body2),
        reverse([0'{|Acc], Head),
        append(Head, Body2, H2),
        append(H2, Rest, Out)
    ;   cd_obj(T, D1, [0'{|Acc], A, O, N, Out)
    ).
cd_obj([0'}|T], D, Acc, A, O, N, Out) :-
    !,
    D1 is D - 1,
    cd_obj(T, D1, [0'}|Acc], A, O, N, Out).
cd_obj([C|T], D, Acc, A, O, N, Out) :- cd_obj(T, D, [C|Acc], A, O, N, Out).

cd_obj_str([], D, Acc, A, O, N, Out) :- !, cd_obj([], D, Acc, A, O, N, Out).
cd_obj_str([0'\\, C|T], D, Acc, A, O, N, Out) :-
    !,
    cd_obj_str(T, D, [C, 0'\\|Acc], A, O, N, Out).
cd_obj_str([0'"|T], D, Acc, A, O, N, Out) :-
    !,
    cd_obj(T, D, [0'"|Acc], A, O, N, Out).
cd_obj_str([C|T], D, Acc, A, O, N, Out) :- cd_obj_str(T, D, [C|Acc], A, O, N, Out).

%% The body of the object whose `{' has just been consumed, up to its `}',
%% with the remainder after it. Quotes respected.
cd_object_span(Cs, Body, Rest) :- cd_span(Cs, 0, [], Body, Rest).

cd_span([0'}|T], 0, Acc, Body, Rest) :- !, reverse([0'}|Acc], Body), Rest = T.
cd_span([0'{|T], D, Acc, B, R) :- !, D1 is D + 1, cd_span(T, D1, [0'{|Acc], B, R).
cd_span([0'}|T], D, Acc, B, R) :- !, D1 is D - 1, cd_span(T, D1, [0'}|Acc], B, R).
cd_span([0'"|T], D, Acc, B, R) :- !, cd_span_q(T, D, [0'"|Acc], B, R).
cd_span([C|T], D, Acc, B, R) :- cd_span(T, D, [C|Acc], B, R).

cd_span_q([0'\\, C|T], D, Acc, B, R) :- !, cd_span_q(T, D, [C, 0'\\|Acc], B, R).
cd_span_q([0'"|T], D, Acc, B, R) :- !, cd_span(T, D, [0'"|Acc], B, R).
cd_span_q([C|T], D, Acc, B, R) :- cd_span_q(T, D, [C|Acc], B, R).

cd_replace_once(Cs, Old, New, Out) :-
    append(Pre, Rest, Cs),
    append(Old, Post, Rest),
    !,
    append(New, Post, Tail),
    append(Pre, Tail, Out).

%% An atom as it appears inside JSON, quotes included, so a substring test
%% cannot match half of a longer value.
cd_json_atom(A, Cs) :-
    atom_codes(A, A0),
    cd_json_escape(A0, E),
    append([0'"|E], [0'"], Cs).

cd_json_escape([], []).
cd_json_escape([0'"|T], [0'\\, 0'"|R]) :- !, cd_json_escape(T, R).
cd_json_escape([0'\\|T], [0'\\, 0'\\|R]) :- !, cd_json_escape(T, R).
cd_json_escape([C|T], [C|R]) :- cd_json_escape(T, R).

%% ---- --patterns and --facts ---------------------------------------------

cd_patterns(Ps) :-
    cd_rows(Rows),
    findall(p(Id, Pat, Why, Cite, Fix, Scan),
            ( member(row(_, T, _), Rows),
              cd_get(T, pattern, Pat), Pat \== '',
              cd_get(T, id, Id),
              cd_get_or(T, why, '', Why),
              cd_get_or(T, fix, '-', Fix),
              cd_get_or(T, scan, code, Scan),
              (   cd_get(T, cite, [C1|_]), cd_get(C1, at, Cite) -> true ; Cite = '-' )
            ),
            Ps).

%% traps.jsonl as CLAUSES, which is what lint.pl consults.
%%
%% PATTERN IS EMITTED AS A TERM, not as an atom: it is cocolog source.
%% Everything else is an atom, quoted by doubling.
%%
%% THE MESSAGES ARE NOT COPIED INTO lint.pl. A rule and the evidence for it
%% drifting apart is the failure this whole file was built to prevent, so
%% there is one source -- traps.jsonl -- and two renderings of it, and
%% test/lint.sh proves the renderings agree.
cd_facts(Text) :-
    cd_patterns(Ps),
    cd_facts_header(H),
    findall(L, ( member(P, Ps), cd_fact_line(P, L) ), Ls),
    append(H, Ls, Lines),
    cd_join(Lines, Text).

cd_fact_line(p(Id, Pat, Why, Cite, Fix, Scan), Line) :-
    cd_q(Id, QI),
    downcase_atom(Scan, LScan),
    cd_q(LScan, QS0),
    cd_severity_of(Id, Sev),
    cd_q(Sev, QSev),
    cd_squash(Why, W), cd_q(W, QW),
    cd_squash(Fix, F), cd_q(F, QF),
    cd_q(Cite, QC),
    format(atom(Line), "cl_trap(~w, ~w, ~w, ~w, ~w, ~w, ~w).",
           [QI, QSev, QS0, Pat, QW, QF, QC]).

cd_severity_of(Id, Sev) :-
    cd_rows(Rows),
    member(row(_, T, _), Rows),
    cd_get(T, id, Id),
    !,
    cd_get(T, severity, S),
    downcase_atom(S, Sev).

%% `" ".join(s.split())' -- every run of whitespace becomes one space, and
%% the ends are trimmed.
cd_squash(A, Out) :-
    atom_codes(A, Cs),
    cd_words(Cs, Ws),
    cd_join_words(Ws, OutCs),
    atom_codes(Out, OutCs).

cd_words([], []) :- !.
cd_words(Cs, Ws) :-
    cd_lstrip(Cs, C1),
    (   C1 == []
    ->  Ws = []
    ;   cd_word(C1, W, Rest),
        Ws = [W|More],
        cd_words(Rest, More)
    ).

cd_word([C|T], [C|W], R) :- \+ cd_space(C), !, cd_word(T, W, R).
cd_word(L, [], L).

cd_join_words([], []) :- !.
cd_join_words([W], W) :- !.
cd_join_words([W|Ws], Out) :-
    cd_join_words(Ws, Rest),
    append(W, [0' |Rest], Out).

cd_facts_header(
  [ '%% traps.pl -- GENERATED by tools/coco-agent/card.pl. Do not edit.',
    '%%',
    '%% cl_trap(Id, Severity, Scan, Pattern, Why, Fix, Cite)',
    '%%',
    '%%   Scan is `code'' (a match inside a quote or a comment is not a',
    '%%   finding) or `text'' (a quote counts as code; a comment still',
    '%%   does not). Only F1, L1 and E1 are `text'', all three because the',
    '%%   form they look for lives INSIDE a quote by construction -- a',
    '%%   format directive, a list-cell atom, a character escape.',
    '%%',
    '%%   Pattern is a TERM, matched by cl_match/4. See lint.pl for the',
    '%%   vocabulary and for why it is not a regex.',
    '' ]).

%% Python's `%r' on a string ALWAYS quotes; `~q' quotes only when the atom
%% would not read back without it. These messages are compared against the
%% Python ones, so the always-quoting form is the one to match.
cd_repr(A, Q) :-
    atom_codes(A, Cs),
    cd_repr_esc(Cs, Ds),
    atom_codes(Inner, Ds),
    atomic_list_concat(['''', Inner, ''''], Q).

cd_repr_esc([], []).
cd_repr_esc([0''|T], [0'\\, 0''|R]) :- !, cd_repr_esc(T, R).
cd_repr_esc([C|T], [C|R]) :- cd_repr_esc(T, R).

cd_q(A, Q) :-
    atom_codes(A, Cs),
    cd_double(Cs, Ds),
    atom_codes(Inner, Ds),
    atomic_list_concat(['''', Inner, ''''], Q).

cd_double([], []).
cd_double([0''|T], [0'', 0''|R]) :- !, cd_double(T, R).
cd_double([C|T], [C|R]) :- cd_double(T, R).

cd_join([], "") :- !.
cd_join(Lines, Text) :-
    findall(Cs, ( member(L, Lines), atom_codes(L, C0), append(C0, "\n", Cs) ), Parts),
    cd_concat(Parts, Text).

cd_concat([], []).
cd_concat([P|Ps], Out) :- cd_concat(Ps, R), append(P, R, Out).

%% ---- --card --------------------------------------------------------------
%%
%% Silent rows first, because a loud failure is repaired by a gate for free
%% and needs no card row.

cd_card :-
    cd_rows(Rows),
    findall(K-T,
            ( member(row(_, T, _), Rows),
              cd_get(T, id, Id),
              cd_get_or(T, severity, none, Sev),
              cd_sev_order(Sev, O),
              K = k(O, Id)
            ),
            Keyed0),
    msort(Keyed0, Keyed),
    format("| id | SWI writes | cocolog needs | because |~n|---|---|---|---|~n"),
    forall(member(_-T, Keyed), cd_card_row(T)).

cd_sev_order('HARD', 0) :- !.
cd_sev_order('WARN', 1) :- !.
cd_sev_order('PROMPT', 2) :- !.
cd_sev_order(_, 9).

cd_card_row(T) :-
    cd_get(T, id, Id),
    cd_get_or(T, swi, '', Swi),
    cd_get_or(T, cocolog, '', Coco),
    cd_get_or(T, why, '', Why),
    (   cd_get(T, cite, Cs)
    ->  findall(A, ( member(C, Cs), cd_get(C, at, A) ), As)
    ;   As = []
    ),
    cd_semis(As, Cite),
    cd_one_line(Swi, S1), cd_one_line(Coco, C1), cd_one_line(Why, W1),
    format("| **~w** | `~w` | ~w | ~w (`~w`) |~n", [Id, S1, C1, W1, Cite]).

cd_semis([], '') :- !.
cd_semis([X], X) :- !.
cd_semis([X|Xs], A) :- cd_semis(Xs, R), atomic_list_concat([X, '; ', R], A).

%% A newline becomes a space and a bar is escaped: a markdown table row is
%% one line and an unescaped `|' would end the cell.
cd_one_line(A, Out) :-
    atom_codes(A, Cs),
    cd_flatten(Cs, Ds),
    atom_codes(Out, Ds).

cd_flatten([], []).
cd_flatten([0'\n|T], [0' |R]) :- !, cd_flatten(T, R).
cd_flatten([0'||T], [0'\\, 0'||R]) :- !, cd_flatten(T, R).
cd_flatten([C|T], [C|R]) :- cd_flatten(T, R).

%% ---- staleness and writing ----------------------------------------------

cd_facts_path(P) :- cd_path('tools/coco-agent/traps.pl', P).

cd_facts_stale :-
    cd_facts_path(F),
    (   \+ exists_file(F)
    ->  true
    ;   cd_traps(T),
        cd_path('tools/coco-agent/card.pl', Self),
        time_file(F, TF),
        member(In, [T, Self]),
        exists_file(In),
        time_file(In, TI),
        TI > TF,
        !
    ).

cd_write_atomic(Path, Codes) :-
    atom_concat(Path, '.tmp', Tmp),
    write_file_from_codes(Tmp, Codes),
    rename_file(Tmp, Path).

%% ---- the entry point ------------------------------------------------------

cd_main :-
    current_prolog_flag(argv, [_|Args]),
    (   memberchk('--patterns', Args) -> cd_do_patterns
    ;   memberchk('--facts', Args)    -> cd_do_facts(Args)
    ;   memberchk('--card', Args)     -> cd_card
    ;   cd_do_check(Args)
    ).

%% `%-4s %s' -- the id left-aligned in four columns. NO ~t OR ~|: cocolog
%% refuses the column directives by name (F1 in this very card), so the
%% padding is computed, which is the documented fix for the trap.
cd_do_patterns :-
    cd_patterns(Ps),
    forall(member(p(Id, Pat, _, _, _, _), Ps),
           ( cd_pad(Id, 4, P), format("~w ~w~n", [P, Pat]) )).

cd_pad(A, W, Out) :-
    atom_length(A, N),
    Need is W - N,
    (   Need =< 0
    ->  Out = A
    ;   cd_spaces(Need, S),
        atom_concat(A, S, Out)
    ).

cd_spaces(0, '') :- !.
cd_spaces(N, S) :- N1 is N - 1, cd_spaces(N1, S0), atom_concat(' ', S0, S).

cd_do_facts(Args) :-
    (   memberchk('--if-stale', Args), \+ cd_facts_stale
    ->  true
    ;   cd_facts(Text),
        cd_facts_path(F),
        cd_write_atomic(F, Text),
        cd_patterns(Ps), length(Ps, N),
        cd_rel(F, R),
        format("traps: wrote ~w (~w patterns)~n", [R, N])
    ).

cd_rel(Abs, Rel) :-
    cd_root(Root),
    atom_concat(Root, Rest0, Abs),
    !,
    ( atom_concat('/', Rest, Rest0) -> Rel = Rest ; Rel = Rest0 ).
cd_rel(A, A).

cd_do_check(Args) :-
    cd_check(Complaints, Drifts),
    forall(member(C, Complaints), format("traps: ~w~n", [C])),
    %% DRIFT IS NOT A COMPLAINT, and printing it under the same prefix would
    %% make it read as one. It is reported because a range nobody refreshes
    %% rots until the day its anchor stops being unique -- and that day the
    %% message is `ambiguous', which costs a human a read of the code.
    forall(member(d(Id, Anchor, Old, New), Drifts),
           ( cd_repr(Anchor, QA),
             format("traps: ~w: ~w moved to ~w (unique anchor, accepted)~n      ~w~n",
                    [Id, Old, New, QA]) )),
    cd_rows(Rows),
    length(Rows, NR),
    (   Complaints == []
    ->  cd_check_ok(Args, Rows, NR, Drifts)
    ;   length(Complaints, NC),
        format("traps: ~w rows, ~w complaints~n", [NR, NC]),
        fail
    ).

cd_check_ok(Args, Rows, NR, Drifts) :-
    (   memberchk('--fix', Args)
    ->  cd_fix(Drifts, W),
        cd_traps(TP), cd_rel(TP, TR),
        format("traps: ~w cite(s) renumbered in ~w~n", [W, TR]),
        Fixed = yes
    ;   Fixed = no
    ),
    cd_cite_count(Rows, NCites),
    cd_patterns(Ps),
    length(Ps, NP),
    (   ( Drifts == [] ; Fixed == yes )
    ->  format("traps: ~w rows, ~w cites all anchored, ~w S1 pattern terms~n",
               [NR, NCites, NP])
    ;   length(Drifts, ND),
        format("traps: ~w rows, ~w cites all anchored (~w by a moved anchor), ~w S1 pattern terms~n",
               [NR, NCites, ND, NP])
    ).

cd_cite_count(Rows, N) :-
    findall(1, ( member(row(_, T, _), Rows), cd_get(T, cite, Cs), member(_, Cs) ), L),
    length(L, N).
