%% cocolog -- lint.pl: cocolint, the dialect linter, as clauses.
%%
%% TIER: none. It is a tool. Run it through its wrapper:
%%
%%     sh tools/cocolint/lint.sh myprogram.pl
%%
%% or by hand, which is the same thing without the file-list plumbing:
%%
%%     cocolog --local run tools/cocolint/blocklist.pl \
%%         tools/cocolint/traps.pl tools/cocolint/clauses.pl \
%%         tools/cocolint/lint.pl "cl_lint(['myprogram.pl'])"
%%
%% WHAT IT IS FOR. cocolog is close enough to SWI that your instincts will
%% compile and far enough that they will be wrong. Every rule below exists
%% because the failure it catches is SILENT or nearly so; a loud failure needs
%% no linter, because the interpreter already names it.
%%
%%     P1  the file does not read at all
%%     N1  a head that collides with a clause-defined tier-1 name: the two sets
%%         of clauses MERGE, and which is tried first depends on how the file
%%         is run
%%     N2  a head that collides with a C-registered name: dispatched before the
%%         store, so the clauses are DEAD CODE
%%     N3  a head whose NAME is a control construct: no arity escapes it
%%     S1  a form this dialect refuses or silently reads differently
%%     T1  a use_module for a tier-1 library, which is a no-op
%%     A1  an integer literal above the cell's silent-wrap point
%%     Z1  a clause too big for a database page, or a term too big for the wire
%%     C2  one name defined in two files of one run
%%
%% WHY THIS IS CLAUSES AND NOT PYTHON. A lint rule IS a clause -- a head that
%% names the rule and a body that says when it fires -- and writing them in a
%% language where a rule is a compiled regex object was the tool disagreeing
%% with the repository it lints. The rewrite also removed a whole class of
%% error: S1's patterns are TERMS now, matched by a grammar, so the six silent
%% divergences a POSIX port suffers (see cl_match below) cannot arise.
%%
%% WHAT IT REFUSES TO GUESS. It reports what it can prove from the source and
%% a blocklist extracted from this checkout. It does not run the program, does
%% not resolve a goal, and says nothing about a name it has no evidence for.
%% The collision ORACLE is the other half and lives in oracle.pl: it asks the
%% running store instead, and it catches what a blocklist cannot -- see the
%% note on N2's blind spot below.
%%
%% HONEST LIMITS. S1 is textual with comment and quote regions masked, so
%% `retract(X), fail' inside a format string is not a finding and the same
%% form spread across two lines by an unusual layout may be missed. C2 needs a
%% manifest. Nothing here type-checks, and no rule proves a program correct.

%% ---- what it depends on ----------------------------------------------
%%
%% Four files, consulted alongside this one by lint.sh, and NOT use_module'd:
%% they are generated data and a sibling tool, not libraries on the path.
%%
%%     blocklist.pl   cl_t1c/3 cl_t1p/3 cl_t2c/3 cl_t2p/3 cl_hook/3
%%     traps.pl       cl_trap/7
%%     clauses.pl     cc_clauses_of/2 cc_regions/2 cc_in_region/3 cc_line_walk/6
%%
%% ======================================================================
%% ---- what used to be here: the accepted directives -------------------
%% ======================================================================

%% THE FOURTEEN ARE GONE, and so is rule D1 with them. A directive is a
%% GOAL now (lib/kb.cicili: coco_directive falls through to the seam
%% coco_goal_install fills in), run in file order, and one that fails or
%% throws is reported and the load CARRIES ON. There is nothing silent left
%% for a rule to catch: an unknown directive says so on stderr at load time,
%% which is exactly the loud failure this linter exists not to duplicate.
%%
%% WHAT SURVIVED IS D2, and it survived because it is not about directives
%% at all: `:- table p/1.' and `:- thread_local p/1.' name predicates that
%% are not prefix OPERATORS, so the file does not parse -- and a syntax
%% error is now the one thing that still ends a consult. It is an S1
%% pattern row in traps.jsonl and needs no code here.

%% TIER 1 IS ALWAYS PRESENT. The first row is compiled in, the second is read
%% from lib/swipl at start-up. A use_module for any of them is a directive
%% that does nothing, and none is written anywhere in this repository.
cl_tier1(apply).      cl_tier1(builtins).  cl_tier1(dcg).
cl_tier1(files).      cl_tier1(library).   cl_tier1(lists).
cl_tier1(zigurat).
cl_tier1(assoc).      cl_tier1(pairs).     cl_tier1(ordsets).
cl_tier1(yall).       cl_tier1(aggregate). cl_tier1(ugraphs).
cl_tier1(dcg_basics). cl_tier1(dcg_high_order).

%% ---- severity --------------------------------------------------------
%%
%% HARD MEANS IT FAILS SILENTLY, which is the only test applied. A finding
%% that the interpreter would itself have shouted about does not need to stop
%% a build.
cl_severity(p1, hard).  cl_severity(n1, hard).
cl_severity(n2, hard).  cl_severity(n3, hard).  cl_severity(s1, hard).
cl_severity(c2, hard).
cl_severity(t1, warn).  cl_severity(a1, warn).  cl_severity(z1, warn).

%% A cell is a u64 with 3 tag bits and an INT is v<<3|2 with NO range check,
%% so 2^60 is where a positive integer starts wrapping SILENTLY. The warning
%% is at 2^59 rather than at the cliff: a program near the edge is one
%% multiplication from being over it, and the wrap prints a plausible number.
cl_wrap_digits(18).
cl_wrap_at('576460752303423488').

%% A row must fit inside a database page. 8000 stores and 8192 comes back
%% `allocation overflow'. 7900 leaves room for the rest of the row.
cl_page_bytes(7900).
%% The client refuses earlier and differently: a Text is a 16-bit length.
cl_wire_bytes(65535).

%% ======================================================================
%% ---- the rules --------------------------------------------------------
%% ======================================================================

%% cl_file(+File, +Imports, -Findings) is det.
%% Every finding in one file, sorted by line then column.
%%
%% ONE READ AND ONE SCAN, then every rule over the result. Reading the file
%% per rule would be nine walks of it, and cc_regions/2 alone is the expensive
%% one.
cl_file(File, Imports0, Findings) :-
    read_file_to_codes(File, Codes),
    cc_clauses_of(File, Clauses),
    cc_regions(Codes, Regions),
    cl_texts(Clauses, Codes, Texts),
    cl_zip(Clauses, Texts, Pairs),
    cl_imports(Pairs, Imports1),
    append(Imports0, Imports1, Imports),
    cl_rule_t1(File, Pairs, F2),
    cl_rule_n(File, Clauses, Imports, F3),
    cl_rule_s1(File, Codes, Regions, F4),
    cl_rule_a1(File, Codes, Regions, F5),
    cl_rule_z1(File, Regions, Pairs, F6),
    append([F2, F3, F4, F5, F6], All),
    cl_sort_findings(All, Findings).

%% ---- T1: a use_module for a tier-1 library ---------------------------

cl_rule_t1(File, Pairs, Findings) :-
    findall(F,
            ( member(cc_clause(Span, _, directive(use_module, _))-Text, Pairs),
              cl_library_arg(Text, Lib),
              cl_tier1(Lib),
              format(atom(Msg),
                     "`library(~w)' is TIER 1 -- compiled in or preloaded. This directive succeeds and does nothing.", [Lib]),
              cl_finding(File, Span, t1, none, Msg,
                         'delete it', 'CLAUDE.md, the two tier-1 rows', F) ),
            Findings).

%% ---- N1, N2, N3: the collisions --------------------------------------
%%
%% ORDER IS THE RULE. N3 before N2 before N1, and a head is reported ONCE,
%% because they are three different fates and the earliest one wins: a control
%% construct is matched before the builtin table, which is reached before the
%% store. A head reported twice would be a linter that had not understood the
%% dispatch it is warning about.
cl_rule_n(File, Clauses, Imports, Findings) :-
    findall(N/A-Span,
            ( member(cc_clause(Span, head(N, A), Kind), Clauses),
              Kind \= directive(_, _) ),
            Pairs0),
    cl_first_each(Pairs0, Pairs),
    findall(F,
            ( member(N/A-Span, Pairs),
              cl_dcg_note(Clauses, N, A, Note),
              cl_collision(N, A, Imports, Note, Rule, Msg, Fix, Cite),
              cl_finding(File, Span, Rule, none, Msg, Fix, Cite, F) ),
            Findings).

%% A DECLARED EXTENSION POINT IS A COLLISION THAT IS MEANT. library/httpd.pl's
%% `httpd_page(_,_,_) :- fail.' exists so a program can add its own pages;
%% blocking it would tell every httpd user to rename the one predicate they
%% are supposed to write. The list comes from blocklist.pl, so the linter and
%% the oracle excuse exactly the same names.
cl_collision(N, A, _, _, _, _, _, _) :- cl_hook(N, A, _), !, fail.

%% N3 -- a control construct, AT ANY ARITY. Matched by interned id before the
%% builtin table and before the store, so the clauses are unreachable and NO
%% RUNTIME CHECK CAN SEE THEM. In blocklist.pl a construct is arity -1.
cl_collision(N, _, _, _, n3, Msg, 'rename it',
             'lib/solve.cicili:151-154, dispatched :1149-1351') :-
    cl_t1c(N, -1, _),
    !,
    format(atom(Msg),
           "`~w' is a CONTROL CONSTRUCT, matched by interned id before the builtin table and before the store. No arity escapes it: your clauses are unreachable and no runtime check can see them.", [N]).

%% N2 -- C-dispatched, in tier 1 or in an imported module. Dispatch reaches
%% the builtin table before the knowledge base, so the clauses load, listing/1
%% shows them, and nothing calls them.
%%
%% THE ORACLE CANNOT SEE THIS ONE. A C name's record has library = 0, so
%% current_predicate/1 reports it as the program's own while the clauses are
%% dead -- measured: 110 of 112 probeable C names come back visible. N2 is the
%% only cover, which is why it stays even when the oracle is available.
cl_collision(N, A, Imports, _, n2, Msg, 'rename it', Cite) :-
    cl_c_dispatched(N, A, Imports, Where),
    !,
    format(atom(Msg),
           "`~w/~w' is dispatched BEFORE the knowledge base. Your clauses are dead code -- they load, listing/1 shows them, and nothing calls them.", [N, A]),
    format(atom(Cite), "lib/solve.cicili:1352-1386; defined in ~w", [Where]).

%% N1 -- clause-defined in a library. Consult APPENDS, so the two sets merge.
cl_collision(N, A, Imports, Note, n1, Msg, Fix, Cite) :-
    cl_clause_defined(N, A, Imports, Where),
    format(atom(Msg),
           "`~w/~w' is already defined by ~w~w. Consult APPENDS, so the two sets of clauses merge and which is tried first depends on how the file is run (measured: `run' puts yours first, `-s' puts the library's).", [N, A, Where, Note]),
    format(atom(Fix),
           "prefix it -- and `listing(~w/~w)' shows both sets of clauses in the order they will be tried, which is the one in-language diagnostic for this (listing/0 hides the predicate entirely)",
           [N, A]),
    Cite = 'library/llm/DESIGN.md sections 6.3 and 16.1'.

cl_c_dispatched(N, A, _, Where) :-
    findall(F, cl_t1c(N, A, F), Fs), Fs = [_|_], !,
    cl_join(Fs, ', ', Where).
cl_c_dispatched(N, A, Imports, Where) :-
    member(M, Imports), cl_t2c(M, N, A), !,
    format(atom(Where), "library(~w)", [M]).

cl_clause_defined(N, A, _, Where) :-
    findall(F, cl_t1p(N, A, F), Fs), Fs = [_|_], !,
    cl_join(Fs, ', ', Where).
cl_clause_defined(N, A, Imports, Where) :-
    member(M, Imports), cl_t2p(M, N, A), !,
    format(atom(Where), "library(~w)", [M]).

%% A DCG HEAD OCCUPIES ARITY+2, and the message has to say so or the reader
%% goes looking for a `digits/3' they never wrote.
cl_dcg_note(Clauses, N, A, ' (a DCG head occupies arity+2)') :-
    member(cc_clause(_, head(N, A), dcg), Clauses),
    !.
cl_dcg_note(_, _, _, '').

%% ---- S1: the banned forms --------------------------------------------
%%
%% THE PATTERNS ARE TERMS, MATCHED BY A GRAMMAR. library(text) binds glibc's
%% regcomp(REG_EXTENDED), and porting the seventeen to it loses six things,
%% three of them SILENTLY: \d becomes a literal `d'; lazy .*? compiles and is
%% greedy; lookaround and (?:...) fail with no error; [^\n] reads as "not
%% backslash, not n"; a rejected pattern is indistinguishable from a miss;
%% and there are no flags. Worst for this job: nothing in that binding answers
%% WHERE a match was, and every finding here is a file:line:col.
%%
%% MASKED BY REGION, and the mask is per trap. `code' means a match inside a
%% quote or a comment is not a finding -- without it a tutorial explaining
%% `retract(X), fail' is reported as committing it. `text' means a quote
%% counts as code, which F1, L1 and E1 need because the form they look for
%% lives inside a quote by construction. NOTHING scans comments: a comment
%% naming ~t documents the rule rather than breaking it.
cl_rule_s1(File, Codes, Regions, Findings) :-
    findall(tr(Id, Scan, P, Set, Pre, Why, Fix, Cite),
            ( cl_trap(Id, _, Scan, P, Why, Fix, Cite),
              cl_first(P, Set), cl_prefix(P, Pre) ),
            Traps),
    findall(S, member(tr(_, _, _, S, _, _, _, _), Traps), Sets),
    cl_union(Sets, Union),
    cl_s1_index(Union, Traps, Index),
    cl_s1_hits(Codes, -1, 0, Index, Union, Raw),
    cl_s1_nonoverlap(Raw, Kept),
    findall(F,
            ( member(hit(Id, Off, _), Kept),
              member(tr(Id, Scan, _, _, _, Why, Fix, Cite), Traps),
              cl_skip_kinds(Scan, Kinds),
              \+ cc_in_region(Regions, Off, Kinds),
              format(atom(Msg), "[~w] ~w", [Id, Why]),
              cl_finding_off(File, Codes, Off, s1, Id, Msg, Fix, Cite, F) ),
            Findings).

%% ONE WALK FOR ALL SEVENTEEN, GATED TWICE. Seventeen separate searches each
%% walked the whole file -- measured four seconds on a 26 KB file, the linter's
%% dominant cost. Here the file is walked once, and at each position the union
%% of every pattern's first-code set decides in ONE memberchk whether any
%% pattern could start there at all. Only then are the individual patterns
%% tried, and only those whose own set admits the code.
%%
%% The union is not tiny -- H1 can start at a space and E1 at a digit -- but it
%% excludes most letters, which is most of a source file.
%% INDEXED BY FIRST CODE. Trying all seventeen at every position the union
%% admits was three seconds on library/html.pl; a code that only one pattern
%% can start with should try one pattern. The index is a sorted list of
%% Code-Traps built once per run.
cl_s1_index(any, Traps, any(Traps)) :- !.
cl_s1_index(Union, Traps, Index) :-
    findall(C-Mine,
            ( member(C, Union),
              findall(T, ( member(T, Traps),
                           T = tr(_, _, _, Set, _, _, _, _),
                           cl_first_ok(Set, C) ), Mine) ),
            Index).

cl_s1_at_code(any(Ts), _, Ts) :- !.
cl_s1_at_code(Index, C, Ts) :- memberchk(C-Ts, Index).

cl_s1_hits([], _, _, _, _, []).
cl_s1_hits([C|T], Prev, Pos, Index, Union, Hits) :-
    Pos1 is Pos + 1,
    (   cl_first_ok(Union, C),
        cl_s1_at_code(Index, C, Mine)
    ->  cl_s1_try(Mine, C, Prev, [C|T], Pos, Here),
        append(Here, More, Hits),
        cl_s1_hits(T, C, Pos1, Index, Union, More)
    ;   cl_s1_hits(T, C, Pos1, Index, Union, Hits)
    ).

cl_s1_try([], _, _, _, _, []).
cl_s1_try([tr(Id, _, P, Set, Pre, _, _, _)|Ts], C, Prev, Codes, Pos, Hits) :-
    (   cl_first_ok(Set, C),
        cl_prefix_ok(Pre, Codes),
        cl_at(P, Prev, Codes, Rest)
    ->  cl_len(Codes, Rest, Len),
        Hits = [hit(Id, Pos, Len)|More]
    ;   Hits = More
    ),
    cl_s1_try(Ts, C, Prev, Codes, Pos, More).

%% NON-OVERLAPPING PER PATTERN, which is what Python's finditer does and
%% therefore what the golden output was produced with: after a match the next
%% search for THAT pattern resumes at its end. A zero-length match advances by
%% one, or the filter would keep every position.
cl_s1_nonoverlap(Raw, Kept) :-
    findall(Id, member(hit(Id, _, _), Raw), Ids0),
    sort(Ids0, Ids),
    findall(H,
            ( member(Id, Ids),
              findall(hit(Id, O, L), member(hit(Id, O, L), Raw), Mine),
              cl_nonoverlap_run(Mine, -1, Run),
              member(H, Run) ),
            Kept).

cl_nonoverlap_run([], _, []).
cl_nonoverlap_run([hit(Id, O, L)|T], End, Out) :-
    (   O >= End
    ->  Next is O + max(L, 1),
        Out = [hit(Id, O, L)|Rest],
        cl_nonoverlap_run(T, Next, Rest)
    ;   cl_nonoverlap_run(T, End, Out)
    ).

cl_skip_kinds(code, [quote, comment]).
cl_skip_kinds(text, [comment]).

%% ---- A1: an integer at or above the wrap point -----------------------
%%
%% COMPARED BY LENGTH AND THEN BY TEXT, never by evaluating the literal: a
%% cocolog integer wraps at 2^60, so number_codes/2 on a 25-digit literal
%% answers a number smaller than the threshold and the rule would go quiet on
%% exactly the values it exists to catch.
cl_rule_a1(File, Codes, Regions, Findings) :-
    cl_digit_runs(Codes, 0, -1, Runs),
    findall(F,
            ( member(run(Off, Digits), Runs),
              cl_over_wrap(Digits),
              \+ cc_in_region(Regions, Off, [quote, comment]),
              atom_codes(Lit, Digits),
              format(atom(Msg),
                     "[A2] ~w is at or above 2^59. A cell is a u64 with 3 tag bits and an INT is v<<3|2 with NO range check, so arithmetic here wraps SILENTLY at 2^60.", [Lit]),
              cl_finding_off(File, Codes, Off, a1, 'A2', Msg,
                             'keep integers under 2^59, or use library(bigint)',
                             'lib/term.cicili:105-113', F) ),
            Findings).

cl_over_wrap(Digits) :-
    length(Digits, N),
    cl_wrap_digits(Min),
    N >= Min,
    (   N > Min
    ->  true
    ;   cl_wrap_at(W), atom_codes(W, WC), cl_ge_codes(Digits, WC)
    ).

cl_ge_codes([], []).
cl_ge_codes([A|As], [B|Bs]) :- ( A > B -> true ; A =:= B, cl_ge_codes(As, Bs) ).

%% A run of digits with no word character or `.' on either side -- Python's
%% (?<![\w.'"])(\d{18,})(?![\w.]), which POSIX has neither half of.
cl_digit_runs([], _, _, []).
cl_digit_runs([C|T], Pos, Prev, Runs) :-
    (   cl_digit(C), \+ cl_a1_bound(Prev)
    ->  cl_digit_run([C|T], Pos, Digits, Rest, Pos1, Prev1),
        (   cl_a1_after(Rest)
        ->  Runs = [run(Pos, Digits)|More]
        ;   Runs = More
        ),
        cl_digit_runs(Rest, Pos1, Prev1, More)
    ;   Pos1 is Pos + 1,
        cl_digit_runs(T, Pos1, C, Runs)
    ).

cl_digit_run([C|T], Pos, [C|Ds], Rest, End, Prev) :-
    cl_digit(C), !,
    Pos1 is Pos + 1,
    cl_digit_run(T, Pos1, Ds, Rest, End, Prev0),
    ( Prev0 == none -> Prev = C ; Prev = Prev0 ).
cl_digit_run(Rest, Pos, [], Rest, Pos, none).

cl_digit(C) :- C >= 0'0, C =< 0'9.

cl_a1_bound(P) :- P =:= 0'. .
cl_a1_bound(P) :- P =:= 0'_.
cl_a1_bound(P) :- P =:= 0'\'.
cl_a1_bound(P) :- P =:= 0'".
cl_a1_bound(P) :- P >= 0'a, P =< 0'z.
cl_a1_bound(P) :- P >= 0'A, P =< 0'Z.
cl_a1_bound(P) :- P >= 0'0, P =< 0'9.

cl_a1_after([]).
cl_a1_after([C|_]) :- \+ cl_a1_bound(C).

%% ---- Z1: a clause too big for a page ---------------------------------
%%
%% MEASURED WITH THE COMMENTS TAKEN OUT, because raw source is not the proxy
%% it looks like: a clause is stored as canonical TEXT and a comment is not
%% part of the term at all. Runs of whitespace outside quotes collapse for the
%% same reason. What is left is not the canonical form -- quoting can lengthen
%% an atom, operators are rewritten -- but it is within a few per cent, which
%% is what a budget check needs.
cl_rule_z1(File, Regions, Pairs, Findings) :-
    findall(F,
            ( member(cc_clause(Span, _, _)-Text, Pairs),
              cl_stored_size(Text, Span, Regions, N),
              cl_z1_message(N, Msg, Fix, Cite),
              cl_finding(File, Span, z1, 'Z1', Msg, Fix, Cite, F) ),
            Findings).

cl_z1_message(N, Msg, 'split it', 'client/zigurat.c:905-915') :-
    cl_wire_bytes(W), N > W, !,
    format(atom(Msg),
           "[Z1] this clause is ~~~w bytes stored. A Text is limited to 65535 bytes on the wire and the CLIENT refuses it -- earlier and differently from the page limit. (Only under --kb or --embed; a --local run stores nothing.)", [N]).
cl_z1_message(N, Msg,
              'chunk it, and assert the completion mark in the same turn',
              'parsi/01-schema.parsi:20-35') :-
    cl_page_bytes(P), N > P,
    format(atom(Msg),
           "[Z1] this clause is ~~~w bytes stored, over the ~w-byte page budget. A row must fit in a page and the refusal arrives at the TURN'S FLUSH -- and under --embed not even then: measured, the writing process exits 0 with empty stderr and the clause is simply absent for the next reader. (Only under --kb or --embed; a --local run stores nothing.)", [N, P]).

%% ONE LOCKSTEP PASS, because the characters are visited in ascending order
%% and so are the regions. The first version asked cc_in_region/3 per byte,
%% which scans the region list from the front every time: 32 KB against 500
%% regions is sixteen million comparisons, and it measured FORTY-THREE SECONDS
%% on tutorials/library/36-llm.pl -- ninety per cent of the whole linter. Here
%% the region list is consumed as the walk advances and never re-examined.
cl_stored_size(Text, at(Off, _, _, _), Regions, N) :-
    cl_shift_regions(Regions, Off, Local),
    cl_size_walk(Text, 0, Local, no, Out),
    cl_trim(Out, Trimmed),
    length(Trimmed, N).

cl_shift_regions([], _, []).
cl_shift_regions([reg(A, B, K)|Rs], Off, Out) :-
    B1 is B - Off,
    (   B1 =< 0
    ->  cl_shift_regions(Rs, Off, Out)
    ;   A1 is A - Off,
        Out = [reg(A1, B1, K)|Rest],
        cl_shift_regions(Rs, Off, Rest)
    ).

%% A COMMENT IS NOT PART OF THE TERM AT ALL, so it goes; whitespace outside a
%% quote collapses to one space; everything else is kept as it stands. What is
%% left is not the canonical form -- quoting can lengthen an atom, operators
%% are rewritten -- but it is within a few per cent, which is what a budget
%% check needs.
cl_size_walk([], _, _, _, []).
cl_size_walk([C|T], Pos, Regions0, Run, Out) :-
    cl_drop_past(Regions0, Pos, Regions),
    Pos1 is Pos + 1,
    (   Regions = [reg(A, _, comment)|_], A =< Pos
    ->  cl_size_walk(T, Pos1, Regions, Run, Out)
    ;   Regions = [reg(A, _, quote)|_], A =< Pos
    ->  Out = [C|Out1], cl_size_walk(T, Pos1, Regions, no, Out1)
    ;   cl_layout(C)
    ->  (   Run == yes
        ->  cl_size_walk(T, Pos1, Regions, yes, Out)
        ;   Out = [32|Out1], cl_size_walk(T, Pos1, Regions, yes, Out1)
        )
    ;   Out = [C|Out1], cl_size_walk(T, Pos1, Regions, no, Out1)
    ).

%% Regions that end at or before POS can never match again -- the walk only
%% goes forward -- so drop them once rather than skipping them every byte.
cl_drop_past([reg(_, B, _)|Rs], Pos, Out) :- B =< Pos, !, cl_drop_past(Rs, Pos, Out).
cl_drop_past(Rs, _, Rs).

cl_trim(Cs, Out) :-
    cl_ws_run(Cs, C1),
    reverse(C1, R1),
    cl_ws_run(R1, R2),
    reverse(R2, Out).

%% ---- C2: one name, two files -----------------------------------------
%%
%% ONLY UNDER A MANIFEST. C2 asks whether two files of ONE PROGRAM define the
%% same name, and a bag of unrelated files is not a program: run over all 47
%% tutorials it reports main/0 forty-five times, which is true and useless.
cl_rule_c2(Files, Findings) :-
    findall(K-File,
            ( member(File, Files), cc_heads_of(File, Ks), member(K, Ks) ),
            Pairs),
    keysort(Pairs, Sorted),
    findall(F,
            ( cl_grouped(Sorted, K, Wheres),
              Wheres = [_, _|_],
              cl_join(Wheres, ' and ', Joined),
              format(atom(Msg),
                     "`~w' is defined in ~w. One run consults them all into one store and consult appends.", [K, Joined]),
              Files = [First|_],
              F = cl_finding(First, 1, 1, c2, hard, none, Msg,
                             'keep it in one file', none) ),
            Findings).

cl_grouped(Pairs, K, Wheres) :-
    findall(K0, member(K0-_, Pairs), Ks0),
    sort(Ks0, Ks),
    member(K, Ks),
    findall(W, member(K-W, Pairs), Wheres0),
    sort(Wheres0, Wheres).

%% ======================================================================
%% ---- findings ---------------------------------------------------------
%% ======================================================================

%% cl_finding(File, Line, Col, Rule, Severity, TrapId, Msg, Fix, Cite)

cl_finding(File, at(_, Line, Col, _), Rule, Id, Msg, Fix, Cite,
           cl_finding(File, Line, Col, Rule, Sev, Id, Msg, Fix, Cite)) :-
    cl_severity(Rule, Sev).

cl_finding_at(File, _, Span, Rule, Id, Msg, Fix, Cite, F) :-
    cl_finding(File, Span, Rule, Id, Msg, Fix, Cite, F).

%% An offset rather than a span: S1 and A1 point INTO a clause, not at it.
cl_finding_off(File, Codes, Off, Rule, Id, Msg, Fix, Cite,
               cl_finding(File, Line, Col, Rule, Sev, Id, Msg, Fix, Cite)) :-
    cl_severity(Rule, Sev),
    cc_line_col(Codes, Off, Line, Col).

cl_sort_findings(Fs, Sorted) :-
    findall(L-C-F,
            ( member(F, Fs), F = cl_finding(_, L, C, _, _, _, _, _, _) ),
            Keyed),
    keysort(Keyed, KS),
    findall(F, member(_-_-F, KS), Sorted).

%% ---- rendering --------------------------------------------------------
%%
%% BYTE-IDENTICAL TO THE PYTHON IT REPLACES, because the suite pins the output
%% and a cosmetic difference would read as a behavioural one.
%%
%%     path:LINE:COL SEVERITY RULE message
%%         fix: ...
%%         see: ...
cl_render(cl_finding(File, Line, Col, Rule, Sev, _, Msg, Fix, Cite)) :-
    cl_relative(File, Rel),
    upcase_atom(Sev, SevU),
    upcase_atom(Rule, RuleU),
    format("~w:~w:~w ~w ~w ~w~n", [Rel, Line, Col, SevU, RuleU, Msg]),
    ( Fix == none -> true ; format("    fix: ~w~n", [Fix]) ),
    ( Cite == none -> true ; format("    see: ~w~n", [Cite]) ).

%% THE PATH IS PRINTED RELATIVE TO THE REPOSITORY ROOT, and cocolog has
%% neither relative_file_name/3 nor directory_file_path/3 -- both confirmed
%% absent from tier-1 library(files) -- so it is a prefix strip. $COCOLOG_ROOT
%% names the root when the caller knows it; otherwise the path is printed as
%% given, which is what a human running the tool by hand typed anyway.
cl_relative(File, Rel) :-
    (   getenv('COCOLOG_ROOT', Root),
        atom_concat(Root, '/', Prefix),
        atom_concat(Prefix, Rel0, File)
    ->  Rel = Rel0
    ;   Rel = File
    ).

%% ======================================================================
%% ---- the entry points -------------------------------------------------
%% ======================================================================

%% cl_main is semidet.
%% Reads $COCO_LINT_FILES, one path per line. THE ENVIRONMENT RATHER THAN A
%% GOAL TERM: cocolog has no argv -- current_prolog_flag/2 answers `executable'
%% and nothing else -- so the alternative is a goal the shell has to quote,
%% and a path with a space in it breaks that.
cl_main :-
    getenv('COCO_LINT_FILES', ListFile),
    read_file_to_codes(ListFile, Codes),
    cl_lines(Codes, Lines),
    findall(F, ( member(L, Lines), atom_codes(F, L) ), Files),
    cl_lint(Files).

%% cl_lint(+Files) is semidet.
%% FAILS when there is a HARD finding, and that is the exit code. `cocolog
%% --local run FILE GOAL' exits 1 with empty stderr when the goal fails --
%% verified -- so no halt is needed, which matters because halt/0 would make
%% the goal report no solution and is the trap card row H1 names.
cl_lint(Files) :-
    cl_manifest(Files, Manifest),
    findall(Fs, ( member(File, Files), cl_file(File, [], Fs) ), PerFile),
    append(PerFile, Findings0),
    (   Manifest == yes
    ->  cl_rule_c2(Files, C2), append(Findings0, C2, Findings)
    ;   Findings = Findings0
    ),
    forall(member(F, Findings), cl_render(F)),
    ( Findings == [] -> true ; nl ),
    cl_count(Findings, hard, Hard),
    cl_count(Findings, warn, Warn),
    length(Files, NF),
    format("cocolint: ~w HARD, ~w WARN over ~w file(s)~n", [Hard, Warn, NF]),
    Hard =:= 0.

cl_manifest(_, Manifest) :-
    ( getenv('COCO_LINT_MANIFEST', _) -> Manifest = yes ; Manifest = no ).

cl_count(Fs, Sev, N) :-
    findall(x, ( member(cl_finding(_, _, _, _, Sev, _, _, _, _), Fs) ), Xs),
    length(Xs, N).

%% ======================================================================
%% ---- small helpers ----------------------------------------------------
%% ======================================================================

%% EVERY CLAUSE'S TEXT IN ONE WALK. Cutting each one with cc_drop/3 from the
%% start of the file is O(offset) per clause and therefore quadratic over the
%% file: library/html.pl's 396 clauses at an average offset of 24 KB is nine
%% and a half million list steps, and it measured as fourteen seconds on that
%% one file. The spans arrive in source order, so one walk serves them all --
%% the same fix cc_clauses_of/2 already makes for the head reader, missed here
%% because the three rules that wanted a clause's text each asked separately.
cl_zip([], [], []).
cl_zip([A|As], [B|Bs], [A-B|Cs]) :- cl_zip(As, Bs, Cs).

cl_texts([], _, []).
cl_texts(Clauses, Codes, Texts) :- cl_texts_(Clauses, 0, Codes, Texts).

cl_texts_([], _, _, []).
cl_texts_([cc_clause(at(Off, _, _, Len), _, _)|Cs], Pos, Codes, [T|Ts]) :-
    Skip is Off - Pos,
    cc_drop(Skip, Codes, Here),
    cc_take(Len, Here, T),
    cc_drop(Len, Here, Tail),
    Next is Off + Len,
    cl_texts_(Cs, Next, Tail, Ts).

%% library(NAME) inside a directive's text.
cl_library_arg(Text, Lib) :-
    append(_, Rest, Text),
    append("library(", After, Rest),
    !,
    cl_upto(After, 0'), Name),
    atom_codes(Lib, Name).

cl_upto([C|_], C, []) :- !.
cl_upto([C|T], Stop, [C|R]) :- cl_upto(T, Stop, R).

%% The FIRST span for each key, in source order: a predicate with six clauses
%% is one collision, reported where it starts.
cl_first_each(Pairs, First) :-
    findall(K, member(K-_, Pairs), Ks0),
    cl_dedup(Ks0, Ks),
    findall(K-S, ( member(K, Ks), once(member(K-S, Pairs)) ), First).

cl_dedup([], []).
cl_dedup([X|T], [X|R]) :- cl_del(T, X, T1), cl_dedup(T1, R).
cl_del([], _, []).
cl_del([X|T], X, R) :- !, cl_del(T, X, R).
cl_del([Y|T], X, [Y|R]) :- cl_del(T, X, R).

%% Which tier-2 libraries a file imports.
cl_imports(Pairs, Imports) :-
    findall(Lib,
            ( member(cc_clause(_, _, directive(D, _))-Text, Pairs),
              ( D == use_module ; D == ensure_loaded ),
              cl_library_arg(Text, Lib0),
              cl_last_segment(Lib0, Lib) ),
            Imports0),
    sort(Imports0, Imports).

%% library(dcg/basics) is the path "dcg/basics" and the module is dcg_basics;
%% what a blocklist entry is keyed on is the last segment.
cl_last_segment(A, Last) :-
    atom_codes(A, Cs),
    (   append(_, [0'/|Tail], Cs)
    ->  atom_codes(Last, Tail)
    ;   Last = A
    ).

cl_join([], _, '').
cl_join([X], _, A) :- !, ( atom(X) -> A = X ; term_to_atom(X, A) ).
cl_join([X|T], Sep, Out) :-
    cl_join(T, Sep, Rest),
    ( atom(X) -> XA = X ; term_to_atom(X, XA) ),
    atom_concat(XA, Sep, A1),
    atom_concat(A1, Rest, Out).

cl_lines([], []) :- !.
cl_lines(Codes, Lines) :- cl_lines_(Codes, [], Lines).
cl_lines_([], Acc, Out) :-
    !, ( Acc == [] -> Out = [] ; reverse(Acc, L), Out = [L] ).
cl_lines_([10|T], Acc, [L|Rest]) :-
    !, reverse(Acc, L), cl_lines_(T, [], Rest).
cl_lines_([C|T], Acc, Out) :- cl_lines_(T, [C|Acc], Out).
%% cl_match -- S1's patterns as TERMS, matched by a grammar.
%%
%% WHY NOT A REGEX. library(text) binds glibc's regcomp(REG_EXTENDED), and an
%% audit of what happens if the 17 S1 patterns are ported to it found six gaps,
%% three of them SILENT: \d becomes a literal `d'; lazy .*? compiles and is
%% greedy; lookaround and (?:...) fail with no error; [^\n] is read as "not
%% backslash, not n"; a pattern regcomp REJECTS is indistinguishable from one
%% that merely missed; and there are no flags at all. Worst of the lot for this
%% job: re_match/2 answers yes or no and re_first/3 answers WHAT matched, and
%% NOTHING answers WHERE -- while every finding this linter emits is a
%% file:line:col.
%%
%% A grammar has the offset for free, real alternation, real negation, and a
%% shortest-match quantifier. And a pattern becomes a TERM somebody can read
%% and argue with, which is the whole reason this repository exists.
%%
%%     cl_match(+Pattern, +Codes, -Offset, -Len)   nondet, leftmost first,
%%                                                 non-overlapping
%%
%% THE VOCABULARY, and it is deliberately small -- nine constructors covering
%% all seventeen patterns. A tenth would be a sign that a rule wants a real
%% parser and should be a rule of its own instead.
%%
%%     seq([P|Ps])       in order
%%     alt([P|Ps])       any, tried left to right
%%     lit(Atom)         literal text
%%     ws                zero or more layout            (\s*)
%%     oneof(Atom)       exactly one code from the set  ([abc])
%%     noneof(Atom, N)   N or more codes NOT in the set ([^abc]+), greedy
%%     someof(Atom, N)   N or more codes from the set   ([abc]+)
%%     exactly(N, Atom)  exactly N codes from the set   ([abc]{4})
%%     bstart            a word boundary before what follows   (\b)
%%     bend              a word boundary after what precedes   (\b)
%%     notword(Atom)     Atom does NOT start here, as a word   ((?!atom\b))
%%     bol               the start of the input                (^)
%%
%% WORD BOUNDARIES NEED THE PREVIOUS CODE, which a DCG does not have -- so the
%% matcher threads it. cl_at/4's first argument is the code before the current
%% position, or -1 at the start of input. That is the whole reason this is not
%% a plain phrase/3.

%% ---- the search ------------------------------------------------------

%% cl_match(+Pattern, +Codes, -Offset, -Len) is nondet.
%% Every match, leftmost first and NON-OVERLAPPING -- the next search resumes
%% at the end of the last match, which is what Python's finditer does and
%% therefore what the golden output was produced with. A zero-length match
%% advances by one, or the search would not terminate.
cl_match(P, Codes, Off, Len) :-
    cl_first(P, Set),
    cl_search(P, Set, Codes, -1, 0, Off, Len).

cl_search(P, Set, Codes, Prev, Pos, Off, Len) :-
    Codes = [C|T],
    (   cl_first_ok(Set, C),
        cl_at(P, Prev, Codes, Rest)
    ->  cl_len(Codes, Rest, L0),
        (   Off = Pos, Len = L0
        ;   Skip is max(L0, 1),
            cl_advance(Skip, Codes, Prev, Rest1, Prev1),
            Pos1 is Pos + Skip,
            cl_search(P, Set, Rest1, Prev1, Pos1, Off, Len)
        )
    ;   Pos1 is Pos + 1,
        cl_search(P, Set, T, C, Pos1, Off, Len)
    ).

%% How many codes the match consumed: the difference between two suffixes of
%% one list. Walking to the shorter one is O(match length), not O(file).
cl_len(Codes, Rest, N) :- cl_len_(Codes, Rest, 0, N).
cl_len_(L, R, N, N) :- L == R, !.
cl_len_([], _, N, N) :- !.
cl_len_([_|T], R, N0, N) :- N1 is N0 + 1, cl_len_(T, R, N1, N).

cl_advance(0, L, P, L, P) :- !.
cl_advance(_, [], P, [], P) :- !.
cl_advance(N, [C|T], _, R, P) :- N1 is N - 1, cl_advance(N1, T, C, R, P).

%% ---- the first-code set, which is what makes the search affordable ----
%%
%% NAIVELY THE SEARCH IS SEVENTEEN FULL ATTEMPTS PER BYTE, and measured that
%% was four seconds on a 26 KB file -- the dominant cost of the whole linter.
%% Every pattern here begins with something that fixes its first code (a
%% literal, a character set, or an alternation of those), so the search can
%% skip any offset whose code no such pattern could start at. cl_first/2
%% computes that set once per pattern; `any' means it could not be determined
%% and the search falls back to trying at every position, which is correct but
%% slow -- so a pattern that answers `any' is a pattern worth rewriting.
%%
%% ZERO-WIDTH ITEMS ARE TRANSPARENT: bstart, bend, bol and notword consume
%% nothing, so the first code is whatever follows them. `ws' and a noneof with
%% a minimum of zero can match empty, so they are transparent too -- but their
%% own set has to be unioned in, because they can also match one code.

cl_first(lit(A), Set) :- !, atom_codes(A, [C|_]), Set = [C].
cl_first(oneof(A), Set) :- !, atom_codes(A, Set).
cl_first(someof(A, N), Set) :- N > 0, !, atom_codes(A, Set).
cl_first(exactly(N, A), Set) :- N > 0, !, atom_codes(A, Set).
%% A ZERO-WIDTH ALTERNATIVE CONTRIBUTES NO CODE OF ITS OWN. H1 begins
%% alt([bol, oneof(...)]) -- `at the start of input, or after one of these' --
%% and reading bol as an unknown made the whole alternation `any', which made
%% the UNION `any', which turned the gate off entirely and cost more than it
%% saved. bol contributes nothing; what follows the alternation does.
cl_first(alt(Ps), Set) :- !,
    findall(P, ( member(P, Ps), \+ cl_zero_width(P) ), Real),
    cl_first_alt(Real, Sets),
    cl_union(Sets, Set).
cl_first(seq(Ps), Set) :- !, cl_first_seq(Ps, Set).
cl_first(_, any).

cl_first_alt([], []).
cl_first_alt([P|Ps], [S|Ss]) :- cl_first(P, S), cl_first_alt(Ps, Ss).

%% A leading zero-width or possibly-empty item does not fix the first code,
%% so keep looking -- and for a possibly-empty one, union what it could match.
cl_first_seq([], any).
cl_first_seq([P|Ps], Set) :-
    (   cl_zero_width(P)
    ->  cl_first_seq(Ps, Set)
    ;   cl_maybe_empty(P)
    ->  cl_first(P, S1), cl_first_seq(Ps, S2), cl_union([S1, S2], Set)
    ;   cl_first(P, Set)
    ).

cl_zero_width(bstart).
cl_zero_width(bend).
cl_zero_width(bol).
cl_zero_width(notword(_)).

cl_maybe_empty(ws).
cl_maybe_empty(noneof(_, 0)).
cl_maybe_empty(someof(_, 0)).
cl_maybe_empty(exactly(0, _)).
%% An alternation with a zero-width branch can match nothing, so the codes
%% after it are also possible first codes.
cl_maybe_empty(alt(Ps)) :- member(P, Ps), ( cl_zero_width(P) ; cl_maybe_empty(P) ), !.

cl_union(Sets, any) :- member(any, Sets), !.
cl_union(Sets, Set) :- append(Sets, All), sort(All, Set).

cl_first_ok(any, _) :- !.
cl_first_ok(Set, C) :- memberchk(C, Set).

%% ---- the literal prefix, which is the rest of the saving ---------------
%%
%% NINE OF THE SEVENTEEN BEGIN WITH A LITERAL WORD, and one of them is
%% `current_prolog_flag' -- nineteen characters that the matcher was walking
%% into at every letter in the file before failing. cl_prefix/2 pulls that
%% literal out so the search can reject a position with one unification
%% against the code list instead of an attempt at the whole pattern.
%%
%% The eight that begin with an alternation get no prefix and are tried in
%% full -- but they fail on their second item, so they were never the cost.
cl_prefix(P, Pre) :- cl_prefix_(P, Pre), !.
cl_prefix(_, []).

cl_prefix_(lit(A), Cs) :- atom_codes(A, Cs).
cl_prefix_(seq([P|Ps]), Cs) :-
    (   cl_zero_width(P)
    ->  cl_prefix_(seq(Ps), Cs)
    ;   cl_prefix_(P, Cs)
    ).

cl_prefix_ok([], _) :- !.
cl_prefix_ok(Pre, Codes) :- append(Pre, _, Codes).

%% ---- the matcher -----------------------------------------------------
%%
%% cl_at(+Pattern, +Prev, +Codes, -Rest) is nondet.
%% PREV is the code before CODES, or -1 at the start of input. FIRST-ARGUMENT
%% INDEXING carries the dispatch: every constructor is a distinct functor, so
%% no cut is needed to choose between them and none is written.

cl_at(seq([]), _, Cs, Cs).
cl_at(seq([P|Ps]), Prev, Cs, Rest) :-
    cl_at(P, Prev, Cs, Mid),
    cl_len(Cs, Mid, N),
    (   N =:= 0
    ->  Prev1 = Prev
    ;   cl_last_consumed(Cs, N, Prev1)
    ),
    cl_at(seq(Ps), Prev1, Mid, Rest).

cl_at(alt([P|_]), Prev, Cs, Rest) :- cl_at(P, Prev, Cs, Rest).
cl_at(alt([_|Ps]), Prev, Cs, Rest) :- cl_at(alt(Ps), Prev, Cs, Rest).

cl_at(lit(A), _, Cs, Rest) :-
    atom_codes(A, Lit),
    append(Lit, Rest, Cs).

cl_at(ws, _, Cs, Rest) :- cl_ws_run(Cs, Rest).

cl_at(oneof(A), _, [C|Rest], Rest) :-
    atom_codes(A, Set),
    memberchk(C, Set).

cl_at(noneof(A, N), _, Cs, Rest) :-
    atom_codes(A, Set),
    cl_run_not(Cs, Set, 0, Got, Rest),
    Got >= N.

cl_at(someof(A, N), _, Cs, Rest) :-
    atom_codes(A, Set),
    cl_run_in(Cs, Set, 0, Got, Rest),
    Got >= N.

cl_at(exactly(N, A), _, Cs, Rest) :-
    atom_codes(A, Set),
    cl_take_in(N, Cs, Set, Rest).

%% A WORD BOUNDARY IS A CHANGE, not a character. bstart looks BACK at the code
%% before the position; bend looks FORWARD at the one after, without consuming
%% it. -1 stands for the edge of the input, which counts as a non-word code --
%% so `\bfoo' matches at offset 0 and `foo\b' matches at end of file.
cl_at(bstart, Prev, Cs, Cs) :-
    \+ cl_word_code(Prev),
    Cs = [C|_],
    cl_word_code(C).

cl_at(bend, Prev, Cs, Cs) :-
    cl_word_code(Prev),
    (   Cs = [C|_]
    ->  \+ cl_word_code(C)
    ;   true
    ).

cl_at(bol, Prev, Cs, Cs) :- Prev =:= -1.

%% notword(A): A does not start here AS A WORD. `(?!executable\b)' must not
%% fire on `executables', which is why the boundary is part of the test and not
%% just the literal.
cl_at(notword(A), _, Cs, Cs) :-
    \+ ( atom_codes(A, Lit),
         append(Lit, After, Cs),
         (   After = [C|_]
         ->  \+ cl_word_code(C)
         ;   true
         ) ).

%% The code the pattern last consumed, for the next item's boundary test.
cl_last_consumed(Cs, N, C) :- N1 is N - 1, cl_nth_code(N1, Cs, C).
cl_nth_code(0, [C|_], C) :- !.
cl_nth_code(N, [_|T], C) :- N1 is N - 1, cl_nth_code(N1, T, C).

cl_word_code(C) :- integer(C), C >= 0'a, C =< 0'z.
cl_word_code(C) :- integer(C), C >= 0'A, C =< 0'Z.
cl_word_code(C) :- integer(C), C >= 0'0, C =< 0'9.
cl_word_code(0'_).

%% GREEDY WITH BACKTRACKING, which is what a regex quantifier is and what
%% [^\n]* in R1 needs: it must give ground so the `)' after it can match.
cl_run_not(Cs, Set, N0, N, Rest) :-
    Cs = [C|T],
    \+ memberchk(C, Set),
    N1 is N0 + 1,
    cl_run_not(T, Set, N1, N, Rest).
cl_run_not(Cs, _, N, N, Cs).

cl_run_in(Cs, Set, N0, N, Rest) :-
    Cs = [C|T],
    memberchk(C, Set),
    N1 is N0 + 1,
    cl_run_in(T, Set, N1, N, Rest).
cl_run_in(Cs, _, N, N, Cs).

cl_take_in(0, Cs, _, Cs) :- !.
cl_take_in(N, [C|T], Set, Rest) :-
    memberchk(C, Set),
    N1 is N - 1,
    cl_take_in(N1, T, Set, Rest).

%% Layout is the six ASCII codes cocolog's own reader treats as layout.
cl_ws_run([C|T], Rest) :- cl_layout(C), !, cl_ws_run(T, Rest).
cl_ws_run(Cs, Cs).

cl_layout(32). cl_layout(9). cl_layout(10). cl_layout(13). cl_layout(12).
cl_layout(11).
