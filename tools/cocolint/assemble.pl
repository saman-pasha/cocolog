%% assemble.pl -- the prompt, built from the index and nothing else.
%%
%%     cocolog --local run card.pl assemble.pl as_main -- "read a JSON file"
%%     ...                                     -- --show system "..."
%%     ...                                     -- --sizes "..."
%%
%% THE COCOLOG REWRITE OF assemble.py, the last of the four, and with it the
%% Python is gone from this repository.
%%
%% Increment 9's deterministic half: everything up to the model call. It reads
%% traps.jsonl, blocklist.json and the three index files and prints exactly
%% what would be sent, so the budget ladder can be checked without spending a
%% token.
%%
%% THE ROUTER HERE IS A STUB, and says so. DESIGN.md section 10 makes routing
%% a model call; what this does is keyword-match capabilities.json, which is
%% the exact-match half that file exists for (section 9.2: "not a similarity
%% problem"). Its verdict is a starting point a model replaces, not a
%% decision.
%%
%% ORDER IS THE ARGUMENT, and it is stated as a hypothesis rather than a
%% finding (DESIGN.md section 9 says so, and schedules an ablation): framing
%% first because it reframes everything after it; the tier inventory early
%% because it is reference consulted while planning; exemplars in the middle,
%% the largest block and the one whose position matters least; the divergence
%% table LATE, nearest the generation, because those are the reflexes being
%% overridden and recency is the cheapest lever there is; the naming law last,
%% for the same reason.
%%
%% THE FOUR FIXED CARDS ARE LINE LISTS, not one atom with escapes in it. A
%% cocolog atom can carry a newline as `\n', but a forty-line prompt written
%% that way is unreadable and undiffable, and these are the part of the
%% prompt a human edits most.
%%
%% EVERY COLUMN IS COMPUTED. Python had %-4s, %-28s, %-6s, %-40s and %5d;
%% cocolog refuses ~t, ~| and ~+ by name -- F1 in the very card this file
%% assembles -- so as_pad/3 and as_lpad/3 do the work. That is the documented
%% fix for the trap, applied in the tool that ships the trap.

:- use_module(library(json)).

%% ---- where things are --------------------------------------------------

as_root(Root) :-
    ( getenv('COCOLOG_ROOT', R) -> Root = R ; working_directory(Root, Root) ).

as_path(Rel, Abs) :- as_root(Root), atomic_list_concat([Root, '/', Rel], Abs).

as_here(Rel, Abs) :- as_path('tools/cocolint/', D), atom_concat(D, Rel, Abs).

%% Hard cap on the user turn, DESIGN.md section 9. `--cap' is for exercising
%% the ladder; nothing on a real request should change it.
as_default_cap(24000).

%% Chars per token, the usual rough rule; stated, not measured.
as_est(Codes, N) :- length(Codes, L), N is (L + 3) // 4.

as_est_atom(A, N) :- as_text(A, Cs), as_est(Cs, N).

%% ---- the four fixed cards ----------------------------------------------

as_card(a, [
    'You are writing cocolog, not SWI-Prolog. cocolog is a Prolog whose clauses are',
    'rows in a database. It is close enough to SWI that your instincts will compile, and far',
    'enough that they will be wrong. Where this card and your priors differ, this card wins.',
    'Every row below exists because someone lost a day to it. Three of them fail SILENTLY.'
  ]).

as_card(c, [
    'HOUSE STYLE.',
    '',
    'File shape. A %% header block first: (1) one line naming the thing, (2) tier and how to',
    'import it, (3) the public surface as an indented signature list, (4) what it refuses to',
    'guess, (5) honest limits. Then directives. Then code in %% ---- section ---- bands.',
    '',
    'Comment voice. A capitalised decision clause, then the failure it prevents. Never restate',
    'the code.',
    '',
    'Throw rather than guess. Every writer ends with a catch-all clause that throws naming the',
    'term. The second argument of error/2 names the PUBLIC entry point.',
    '',
    'Codes out, codes-or-atom in. Writers answer codes (*_codes/2,3) with *_atom/2,3 as a',
    'convenience; readers take either through a three-clause normaliser whose last clause throws.',
    '',
    'Options are a list of one-argument terms, every one with a default, all defaults in one',
    'place, none required.',
    '',
    'Determinism is stated. A clause meant to be deterministic carries a cut and a comment',
    'saying why -- but see row I1: do not add one the engine already gives you.'
  ]).

as_card(d, [
    'THE ENTRY-POINT CONTRACT.',
    '',
    'No entry directive exists. The CLI names the goal:',
    '',
    '    cocolog --local run FILE... main',
    '',
    'exit 0 if and only if main proved. Do not call halt. End main with format("done~n"); the',
    'harness requires that as the last line of stdout, because exit 0 alone is satisfied by',
    '`main :- true.''',
    '',
    'Every claim your program makes about itself is a must/3, and this block is repeated',
    'VERBATIM at the foot of every file -- deliberately duplicated, so a program you copy',
    'anywhere still runs:',
    '',
    '    show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).',
    '',
    '    must(Label, Got, Want) :-',
    '        (   Got == Want',
    '        ->  format("   ~w = ~q~n", [Label, Got])',
    '        ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),',
    '            fail',
    '        ).',
    '',
    'Call flush_output after any progress marker a long run prints: stdout is block-buffered',
    'into a pipe and a killed run loses what it has not flushed.'
  ]).

as_card(e, [
    'THE NAMING LAW.',
    '',
    'Every predicate you define is prefixed with the program''s own name -- helpers, DCG',
    'non-terminals, and main''s callees included. You may CALL only: a name in the SYMBOLS block',
    'of this request, a name you define in this file, or one of the 22 control constructs. A',
    'gate checks this against the running binary and rejects collisions by name.'
  ]).

as_card_text(Key, Codes) :-
    as_card(Key, Lines),
    as_join_nl(Lines, Codes).

%% EVERYTHING BIG IS A CODE LIST, AND THAT IS NOT A STYLE CHOICE.
%% `atomic_list_concat/2' is `$atom_join'/3 in lib/builtins.cicili, and that
%% C function has `char one[4096]' for each element and `char out[8192]' for
%% the result. An element over 4096 bytes raises type_error(atomic, X) --
%% naming a term that is plainly atomic, which is a confusing way to say "too
%% long" -- and a result over 8192 bytes simply FAILS. This prompt is 40 KB.
%%
%% So the whole assembly is codes: joined with append/3, measured with
%% length/2, printed with ~s. Atoms are used only for the short pieces that
%% cannot approach either limit. This is the repository's own "codes out,
%% codes-or-atom in" rule arrived at from the other direction -- by hitting
%% the wall the rule exists to keep you away from.
as_join_nl([], []) :- !.
as_join_nl([L], Cs) :- !, as_text(L, Cs).
as_join_nl([L|Ls], Out) :-
    as_text(L, Cs),
    as_join_nl(Ls, R),
    append(Cs, [0'\n|R], Out).

%% An atom or a code list, as codes.
as_text(X, Cs) :- is_list(X), !, Cs = X.
as_text(X, Cs) :- atom_codes(X, Cs).

%% ---- the inputs ----------------------------------------------------------

as_load_json(Name, Term) :-
    as_here(Name, P),
    (   exists_file(P)
    ->  read_file_to_codes(P, Cs), once(json_parse(Cs, Term))
    ;   format("assemble: no ~w -- run index.pl and build.pl first~n", [Name]),
        fail
    ).

as_load_jsonl(Name, Rows) :-
    as_here(Name, P),
    (   exists_file(P)
    ->  read_file_to_codes(P, Cs),
        as_lines(Cs, Ls),
        findall(T, ( member(L, Ls), L \== [], once(json_parse(L, T)) ), Rows)
    ;   format("assemble: no ~w -- run index.pl and build.pl first~n", [Name]),
        fail
    ).

as_get(json(Ps), K, V) :- memberchk(K-V, Ps).
as_get_or(T, K, _, V) :- as_get(T, K, V), !.
as_get_or(_, _, D, D).

%% ---- Card B: the divergence table ---------------------------------------
%%
%% Silent failures first: a loud failure is repaired by a gate for free and
%% does not need to be in the prompt at all.

as_card_b(Text) :-
    cd_rows(Rows),
    findall(k(O, Id)-T,
            ( member(row(_, T, _), Rows),
              as_get(T, id, Id),
              as_get_or(T, severity, none, S),
              as_sev(S, O)
            ),
            Keyed0),
    msort(Keyed0, Keyed),
    findall(L, ( member(_-T, Keyed), as_trap_lines(T, L) ), Lss),
    as_flatten(Lss, Lines0),
    append(['THE DIVERGENCE TABLE. SWI writes | cocolog needs | because.', ''],
           Lines0, Lines),
    as_join_nl(Lines, Text).

as_sev('HARD', 0) :- !.
as_sev('WARN', 1) :- !.
as_sev('PROMPT', 2) :- !.
as_sev(_, 9).

as_trap_lines(T, Lines) :-
    as_get(T, id, Id),
    as_get_or(T, swi, '', Swi),
    as_get_or(T, cocolog, '', Coco),
    as_get_or(T, why, '', Why),
    as_pad(Id, 4, PI),
    as_squash(Swi, S1), as_squash(Coco, C1), as_squash(Why, W1),
    atomic_list_concat([PI, ' ', S1], L1),
    atomic_list_concat(['     -> ', C1], L2),
    atomic_list_concat(['        ', W1], L3),
    (   as_get(T, empirical, E), E \== ''
    ->  as_squash(E, E1),
        atomic_list_concat(['        MEASURED: ', E1], L4),
        Lines = [L1, L2, L3, L4, '']
    ;   Lines = [L1, L2, L3, '']
    ).

%% ---- Block E: the reserved short names -----------------------------------
%%
%% CHEAP, AND THE ONE PLACE A BLOCKLIST BEATS A VOCABULARY. Everything else in
%% the prompt tells the model what it MAY call; this tells it what it may not
%% NAME, because the temptation these names meet is to invent a helper called
%% `step' or `insert', not to call one.

as_short_names(BL, Short) :-
    as_get(BL, tier1, T1),
    as_get(T1, c, json(Cs)),
    as_get(T1, clauses, json(Ps)),
    findall(K, ( member(K-_, Cs) ; member(K-_, Ps) ), Ks0),
    sort(Ks0, Ks),
    findall(K,
            ( member(K, Ks),
              as_key_name(K, N),
              atom_codes(N, NCs),
              \+ memberchk(0'_, NCs),
              as_all_alpha(NCs),
              length(NCs, L), L > 2
            ),
            Short0),
    sort(Short0, Short).

as_key_name(K, N) :-
    atom_codes(K, Cs),
    append(NCs, [0'/|R], Cs),
    \+ memberchk(0'/, R),
    !,
    atom_codes(N, NCs).

as_all_alpha([]) :- fail.
as_all_alpha(Cs) :- \+ ( member(C, Cs), \+ as_alpha(C) ).

as_alpha(C) :- C >= 0'a, C =< 0'z.
as_alpha(C) :- C >= 0'A, C =< 0'Z.

%% ---- the system prompt -----------------------------------------------------

as_system(BL, Surf, Text) :-
    as_get(BL, tier1, T1),
    as_get(T1, c, json(Cs)), length(Cs, T1C),
    as_get(T1, clauses, json(Ps)), length(Ps, T1P),
    findall(L, as_inventory_line(Surf, T1C, T1P, L), Inv),
    as_join_nl(Inv, InvText),
    as_card_text(a, A), as_card_text(c, C), as_card_text(d, D), as_card_text(e, E),
    as_card_b(B),
    as_join_blank([A, InvText, '[EXEMPLARS -- inserted per request]', C, B, D, E], Text).

as_inventory_line(_, T1C, T1P, L) :-
    member(N,
      [ 'TIER 1 -- always present, no use_module needed, none of it optional:',
        '    apply builtins dcg files library lists zigurat',
        '    assoc pairs ordsets yall aggregate ugraphs dcg_basics dcg_high_order' ]),
    L = N,
    T1C = T1C, T1P = T1P.
as_inventory_line(_, T1C, _, L) :-
    format(atom(L),
      "  ~w names are dispatched in C BEFORE the knowledge base (redefining one is",
      [T1C]).
as_inventory_line(_, _, T1P, L) :-
    format(atom(L),
      "  dead code); ~w are clauses consulted into the same store (redefining one",
      [T1P]).
as_inventory_line(_, _, _, '  APPENDS to them). A use_module for any of these is a directive that does').
as_inventory_line(_, _, _, '  nothing -- none is written anywhere in this repository.').
as_inventory_line(_, _, _, '').
as_inventory_line(_, _, _, 'TIER 2 -- on the library path, loaded when asked:').
as_inventory_line(Surf, _, _, L) :-
    findall(M-R, ( member(R, Surf), as_get(R, tier, 2), as_get(R, module, M) ), Rows0),
    msort(Rows0, Rows),
    member(M-R, Rows),
    as_get_or(R, documented, [], Doc),
    ( Doc = [D0|_] -> D = D0 ; D = '(header has no signature list)' ),
    as_pad(M, 6, PM),
    atomic_list_concat(['    library(', PM, ')  ', D], L).

as_join_blank([], []) :- !.
as_join_blank([X], Cs) :- !, as_text(X, Cs).
as_join_blank([X|Xs], Out) :-
    as_text(X, Cs),
    as_join_blank(Xs, R),
    append(Cs, [0'\n, 0'\n|R], Out).

%% ---- the stub router --------------------------------------------------------
%%
%% Keyword match, longest phrase first so `http request' beats `request'. A
%% model replaces this; capabilities.json is the table either way.

as_route(Request, Caps, verdict(Topics, Matched, Arr, Libs, Tags)) :-
    downcase_atom(Request, Low),
    findall(Topic-Word,
            ( member(C, Caps),
              as_get(C, topic, Topic),
              as_get(C, words, Ws),
              as_longest_hit(Ws, Low, Word)
            ),
            Hits),
    findall(T, member(T-_, Hits), Topics),
    findall(W, member(_-W, Hits), Matched),
    findall(A,
            ( member(C, Caps), as_get(C, topic, T2), memberchk(T2-_, Hits),
              as_get(C, arrangement, A), A \== local ),
            Arrs),
    ( Arrs = [A1|_] -> Arr = A1 ; Arr = local ),
    findall(M,
            ( member(C, Caps), as_get(C, topic, T3), memberchk(T3-_, Hits),
              as_get(C, libraries, Ls), member(M, Ls) ),
            Libs0),
    as_dedup(Libs0, Libs),
    findall(G,
            ( member(C, Caps), as_get(C, topic, T4), memberchk(T4-_, Hits),
              as_get(C, exemplars, Es), member(G, Es) ),
            Tags0),
    as_dedup(Tags0, Tags1),
    ( Tags1 == [] -> Tags = ['self-checking program'] ; Tags = Tags1 ).

as_longest_hit(Words, Low, Word) :-
    findall(L-W, ( member(W, Words), atom_length(W, L) ), Pairs0),
    msort(Pairs0, Pairs1),
    reverse(Pairs1, Pairs),
    member(_-Word, Pairs),
    as_sub(Low, Word),
    !.

as_sub(Hay, Needle) :-
    atom_codes(Hay, H), atom_codes(Needle, N),
    append(_, R, H), append(N, _, R), !.

%% FIRST OCCURRENCE WINS, which is what `if m not in libs: libs.append(m)'
%% does. Written the other way round -- drop X when it recurs later -- it
%% keeps the LAST, and the import list came out as json, xml, httpd, html
%% where Python had json, xml, html, httpd: the same set in a different
%% order, which is exactly the kind of difference a set comparison would
%% have missed and a byte comparison caught.
as_dedup([], []).
as_dedup([X|T], [X|R]) :- as_delete(X, T, T1), as_dedup(T1, R).

as_delete(_, [], []).
as_delete(X, [Y|T], R) :-
    (   X == Y
    ->  as_delete(X, T, R)
    ;   R = [Y|R1], as_delete(X, T, R1)
    ).

as_verdict_json(verdict(Topics, Matched, Arr, Libs, Tags), J) :-
    J = json([topics-Topics, matched-Matched, arrangement-Arr,
              tier2_imports-Libs, exemplar_tags-Tags,
              router-'STUB -- keyword match over capabilities.json, not a model verdict']).

%% ---- padding, because there are no column directives ---------------------

as_pad(A, W, Out) :-
    atom_length(A, N), Need is W - N,
    ( Need =< 0 -> Out = A ; as_spaces(Need, S), atom_concat(A, S, Out) ).

as_lpad(A, W, Out) :-
    atom_length(A, N), Need is W - N,
    ( Need =< 0 -> Out = A ; as_spaces(Need, S), atom_concat(S, A, Out) ).

as_spaces(0, '') :- !.
as_spaces(N, S) :- N1 is N - 1, as_spaces(N1, S0), atom_concat(' ', S0, S).

%% ---- text helpers ---------------------------------------------------------

as_lines([], []) :- !.
as_lines(Cs, [L|Ls]) :-
    ( append(L, [0'\n|R], Cs) -> true ; L = Cs, R = [] ),
    !,
    ( R == [], L == [] -> Ls = [] ; as_lines(R, Ls) ).

as_space(0' ).  as_space(0'\t). as_space(0'\n).
as_space(0'\r). as_space(11).   as_space(12).

as_squash(A, Out) :-
    atom_codes(A, Cs), as_words(Cs, Ws), as_join_words(Ws, O), atom_codes(Out, O).

as_words([], []) :- !.
as_words(Cs, Ws) :-
    as_lstrip(Cs, C1),
    ( C1 == [] -> Ws = [] ; as_word(C1, W, R), Ws = [W|M], as_words(R, M) ).

as_lstrip([C|T], R) :- as_space(C), !, as_lstrip(T, R).
as_lstrip(L, L).

as_word([C|T], [C|W], R) :- \+ as_space(C), !, as_word(T, W, R).
as_word(L, [], L).

as_join_words([], []) :- !.
as_join_words([W], W) :- !.
as_join_words([W|Ws], Out) :- as_join_words(Ws, R), append(W, [0' |R], Out).

as_flatten([], []).
as_flatten([L|Ls], Out) :- as_flatten(Ls, R), append(L, R, Out).

%% ---- the user turn: blocks A-F ------------------------------------------
%%
%% A block is b(Name, Body, Keep). The ladder marks one `no' rather than
%% removing it, so --sizes can show what was dropped and why.

as_user(Request, V, Surf, Exs, BL, Cap, Text, Parts) :-
    as_blocks(Request, V, Surf, Exs, BL, Blocks0),
    as_ladder(Blocks0, Cap, Blocks),
    findall(B, member(b(_, B, yes), Blocks), Kept),
    as_join_rule(Kept, Body),
    append("\n\n", Body, Text),
    findall(p(N, E, K),
            ( member(b(N, B, K), Blocks), as_est_atom(B, E) ),
            Parts).

as_join_rule([], []) :- !.
as_join_rule([X], Cs) :- !, as_text(X, Cs).
as_join_rule([X|Xs], Out) :-
    as_text(X, Cs),
    as_join_rule(Xs, R),
    append("\n\n----------------------------------------------------------------------\n\n", R, Sep),
    append(Cs, Sep, Out).

as_blocks(Request, V, Surf, Exs, BL, Blocks) :-
    V = verdict(_, _, _, Libs, Tags),
    as_squash_ends(Request, Req),
    atom_codes(Req, ReqCs),
    append("THE REQUEST, VERBATIM:\n\n", ReqCs, BA),
    as_verdict_json(V, VJ),
    json_codes(VJ, VC, [indent(1)]),
    append("ROUTER VERDICT:\n\n", VC, BB),
    findall(b(N, B, yes), as_surface_block(Libs, Surf, N, B), CBlocks),
    as_symbols(BL, Libs, SymA),
    as_everyday(BL, EvA),
    as_short_names(BL, Short),
    as_join_words_atoms(Short, ShortA),
    atom_codes(ShortA, ShortCs),
    append("RESERVED SHORT NAMES -- do not define any of these, at any arity:\n\n  ",
           ShortCs, BE),
    as_take(3, Tags, Tags3),
    findall(b(N, B, yes), as_exemplar_block(Tags3, Exs, N, B), FBlocks),
    append([ b('A. the request', BA, yes),
             b('B. router verdict', BB, yes) ], CBlocks, P1),
    append(P1, [ b('D. symbols: C table and imports', SymA, yes),
                 b('D2. symbols: tier-1 library predicates', EvA, yes),
                 b('E. reserved short names', BE, yes) ], P2),
    append(P2, FBlocks, Blocks).

as_squash_ends(A, Out) :-
    atom_codes(A, Cs), as_lstrip(Cs, C1),
    reverse(C1, R0), as_lstrip(R0, R1), reverse(R1, C2),
    atom_codes(Out, C2).

as_surface_block(Libs, Surf, Name, Body) :-
    member(M, Libs),
    member(R, Surf),
    as_get(R, module, M),
    as_get(R, header, H),
    as_get(R, import, I),
    format(atom(Name), "C. surface library(~w)", [M]),
    atom_codes(H, HCs), atom_codes(I, ICs), atom_codes(M, MCs),
    append("LIBRARY(", MCs, X1),
    append(X1, ") -- its own header, verbatim:\n\n", X2),
    append(X2, HCs, X3),
    append(X3, "\n\nIMPORT: ", X4),
    append(X4, ICs, Body).

%% THE FULL RESERVED TABLE IS DELIBERATELY NOT HERE. DESIGN.md section 9 says
%% so outright: it is ~2k tokens the model cannot reliably apply while
%% generating, and which the gate checks perfectly. What a generator needs is
%% a VOCABULARY -- the names it may call -- and the blocklist half of the job
%% belongs to block E and to G1.
as_symbols(BL, Libs, Text) :-
    as_get(BL, tier1, T1),
    as_get(T1, c, json(Cs)),
    findall(L,
            ( member(K-_, Cs), \+ as_dollar(K),
              as_pad(K, 28, P), atomic_list_concat(['  ', P, ' det'], L) ),
            CLines),
    findall(L, as_tier2_symbol(BL, Libs, L), T2Lines),
    append([ 'THE NAMES THAT EXIST. Anything else raises existence_error at run time.',
             '`det'' means a C table entry: it answers ONCE and leaves no choice point,',
             'so a failure-driven loop over one runs the body exactly once.',
             '`nondet'' means Prolog clauses: it backtracks.',
             '',
             'Also present and not listed: assoc pairs ordsets yall aggregate ugraphs',
             'dcg_basics dcg_high_order -- SWI''s own files, vendored unmodified, and',
             'SWI''s documentation of them applies. They need no use_module.',
             '' ], CLines, H1),
    append(H1, T2Lines, Lines),
    as_join_nl(Lines, Text).

as_tier2_symbol(BL, Libs, L) :-
    member(M, Libs),
    as_get(BL, tier2, T2),
    as_get(T2, M, E),
    (   as_get(E, c, json(Cs)), member(K-_, Cs),
        as_pad(K, 28, P),
        format(atom(L), "  ~w det     library(~w)", [P, M])
    ;   as_get(E, clauses, json(Ps)), member(K-_, Ps),
        as_pad(K, 28, P),
        format(atom(L), "  ~w nondet  library(~w)", [P, M])
    ).

as_dollar(K) :- atom_codes(K, [0'$|_]).

%% The everyday clause-defined names: the tier-1 modules written in this
%% repository, not the eight vendored SWI files -- those are NAMED in the
%% block above rather than listed, because 260 rows of assoc and ugraphs
%% internals would cost a fifth of the turn to say what one sentence says.
as_everyday(BL, Text) :-
    as_get(BL, tier1, T1),
    as_get(T1, clauses, json(Ps)),
    findall(L,
            ( member(K-Files, Ps), \+ as_dollar(K),
              member(F, Files), as_everyday_file(F),
              atomic_list_concat(['  ', K], L) ),
            Ls0),
    as_dedup(Ls0, Ls),
    append([ 'THE TIER-1 LIBRARY PREDICATES. All nondet -- they are clauses, so they',
             'backtrack, which is what makes a failure-driven loop work over one and',
             'not over a C builtin.', '' ], Ls, Lines),
    as_join_nl(Lines, Text).

as_everyday_file('lib/builtins.cicili').
as_everyday_file('lib/lists.cicili').
as_everyday_file('lib/apply.cicili').
as_everyday_file('lib/dcg.cicili').
as_everyday_file('lib/files.cicili').

as_exemplar_block(Tags, Exs, Name, Body) :-
    member(Tag, Tags),
    member(R, Exs),
    as_get(R, tag, Tag),
    as_get(R, path, Rel),
    as_get(R, why, Why),
    as_path(Rel, Abs),
    read_file_to_codes(Abs, Src0),
    (   as_get(R, start_anchor, A), as_get(R, end_anchor, E)
    ->  atom_codes(A, ACs), atom_codes(E, ECs),
        ix_index(Src0, ACs, I), ix_index(Src0, ECs, J0),
        length(ECs, EL), J is J0 + EL, Len is J - I,
        as_slice(Src0, I, Len, Src)
    ;   Src = Src0
    ),
    atom_codes(SrcA, Src),
    format(atom(Name), "F. exemplar ~w", [Tag]),
    format(atom(Head), "EXEMPLAR (~w) -- ~w\n~w\n\n", [Tag, Rel, Why]),
    atom_codes(Head, HeadCs),
    append(HeadCs, Src, B0),
    (   as_get(R, recorded_stdout, Out), Out \== @(null)
    ->  atom_codes(Out, OutCs),
        append("\n\nAND THIS IS WHAT IT ACTUALLY PRINTS:\n\n", OutCs, Tail),
        append(B0, Tail, Body)
    ;   Body = B0
    ),
    SrcA = SrcA.

as_slice(Cs, Off, Len, Out) :- as_drop(Off, Cs, T), as_take_c(Len, T, Out).

as_drop(0, L, L) :- !.
as_drop(_, [], []) :- !.
as_drop(N, [_|T], R) :- N1 is N - 1, as_drop(N1, T, R).

as_take_c(N, _, []) :- N =< 0, !.
as_take_c(_, [], []) :- !.
as_take_c(N, [C|T], [C|R]) :- N1 is N - 1, as_take_c(N1, T, R).

as_take(0, _, []) :- !.
as_take(_, [], []) :- !.
as_take(N, [X|T], [X|R]) :- N1 is N - 1, as_take(N1, T, R).

as_join_words_atoms([], '') :- !.
as_join_words_atoms([W], W) :- !.
as_join_words_atoms([W|Ws], Out) :-
    as_join_words_atoms(Ws, R), atomic_list_concat([W, ' ', R], Out).

%% ---- the ladder ------------------------------------------------------------
%%
%% THE DESIGN'S DROP ORDER IS CORRECTED HERE, and the correction is measured.
%% It read: third exemplar, second exemplar, largest header, then the symbol
%% scope. That was written expecting block D at 0.8-2k tokens; counted, the C
%% table plus the everyday tier-1 predicates is 4.7k, and on a request
%% importing eleven libraries the whole symbol block reaches 13k. Following
%% the stated order there leaves the model ONE exemplar and a 13k name dump --
%% the wrong half kept, because the exemplars are the only grounding signal in
%% the turn and the symbol list is what the gates check perfectly. So D2, the
%% tier-1 library predicates, goes FIRST.
%%
%% Never dropped, in any order: block E and the router verdict.

as_ladder(Blocks, Cap, Out) :-
    as_total(Blocks, T),
    (   T =< Cap
    ->  Out = Blocks
    ;   as_drop_one(Blocks, Next)
    ->  as_ladder(Next, Cap, Out)
    ;   Out = Blocks
    ).

as_total(Blocks, T) :-
    findall(E, ( member(b(_, B, yes), Blocks), as_est_atom(B, E) ), Es),
    as_sum(Es, 0, T).

as_sum([], A, A).
as_sum([E|Es], A, T) :- A1 is A + E, as_sum(Es, A1, T).

as_drop_one(Blocks, Out) :-
    as_drop_named(Blocks, 'D2.',
        'the gates check names perfectly; an exemplar cannot be replaced', Out),
    !.
as_drop_one(Blocks, Out) :-
    as_kept_exemplars(Blocks, Ex),
    length(Ex, N), N > 1,
    last(Ex, LastName),
    as_drop_exact(Blocks, LastName, 'over budget', Out),
    !.
as_drop_one(Blocks, Out) :-
    findall(E-N,
            ( member(b(N, B, yes), Blocks), as_prefix('C. surface', N),
              as_est_atom(B, E) ),
            Ps),
    Ps \== [],
    msort(Ps, Sorted), reverse(Sorted, [_-Biggest|_]),
    as_drop_exact(Blocks, Biggest, 'largest header, over budget', Out).

as_kept_exemplars(Blocks, Names) :-
    findall(N, ( member(b(N, _, yes), Blocks), as_prefix('F. exemplar', N) ), Names).

as_drop_named([b(N, B, yes)|T], Prefix, Why, [b(N2, B, no)|T]) :-
    as_prefix(Prefix, N),
    !,
    format(atom(N2), "~w  [DROPPED: ~w]", [N, Why]).
as_drop_named([X|T], P, W, [X|R]) :- as_drop_named(T, P, W, R).

as_drop_exact([b(N, B, yes)|T], N, Why, [b(N2, B, no)|T]) :-
    !,
    format(atom(N2), "~w  [DROPPED: ~w]", [N, Why]).
as_drop_exact([X|T], N, W, [X|R]) :- as_drop_exact(T, N, W, R).

as_prefix(P, Name) :-
    atom_codes(P, PC), atom_codes(Name, NC), append(PC, _, NC).

%% HOW FAR OVER, once every rung is spent. NOT SILENT: a request that imports
%% eleven libraries cannot be made to fit by dropping anything the ladder is
%% allowed to drop -- the tier-2 symbol rows dominate and dropping those while
%% keeping the imports would hand the model a library it may use and no names
%% for it. The honest answer is to say so and let the caller narrow the
%% request.
as_over_cap(Text, Cap, Over) :-
    as_est_atom(Text, N),
    ( N > Cap -> Over is N - Cap ; Over = 0 ).

%% ---- the entry point --------------------------------------------------------

as_main :-
    current_prolog_flag(argv, [_|Args]),
    as_opt_value('--show', Args, Show),
    as_opt_value('--cap', Args, CapA),
    ( CapA == none -> as_default_cap(Cap) ; atom_number(CapA, Cap) ),
    ( memberchk('--sizes', Args) -> Sizes = yes ; Sizes = no ),
    as_request(Args, Req),
    (   Req == ''
    ->  format("usage: assemble.pl [--show system|user] [--sizes] \"REQUEST\"~n"),
        fail
    ;   as_load_json('blocklist.json', BL),
        as_load_jsonl('surface.jsonl', Surf),
        as_load_jsonl('exemplars.jsonl', Exs),
        as_load_json('capabilities.json', Caps),
        as_route(Req, Caps, V),
        as_system(BL, Surf, Sys),
        as_user(Req, V, Surf, Exs, BL, Cap, Usr, Parts),
        as_output(Show, Sizes, Req, V, Sys, Usr, Parts, Cap)
    ).

%% `--show X' and `--cap N': the value is the argument after the flag.
as_opt_value(Flag, Args, V) :-
    (   append(_, [Flag, V0|_], Args) -> V = V0 ; V = none ).

%% Everything that is not a flag and not a flag's value.
as_request(Args, Req) :-
    as_flag_values(Args, Skip),
    findall(A,
            ( nth0(I, Args, A),
              \+ as_prefix('-', A),
              \+ memberchk(I, Skip)
            ),
            Words),
    as_join_words_atoms(Words, Req).

as_flag_values(Args, Skip) :-
    findall(J,
            ( nth0(I, Args, F), memberchk(F, ['--show', '--cap']), J is I + 1 ),
            Skip).

as_output(system, _, _, _, Sys, _, _, _) :- !, as_write_codes(Sys), nl.
as_output(user, _, _, _, _, Usr, _, _) :- !, as_write_codes(Usr), nl.

%% ~s IS CAPPED AT 8192 BYTES TOO, and past it format/2 says "~s wants text"
%% -- which reads as a type error about the argument rather than a size limit
%% on the buffer. lib/builtins.cicili's format has `char buf[8192]' for ~a and
%% ~s alike, the same shape as $atom_join's. The system prompt is 14 KB and
%% the user turn 30 KB, so both go out in chunks under the cap.
%%
%% That is the SECOND 8192-byte wall this file met. Both are real limits of
%% the interpreter rather than of this tool, both are reported as something
%% other than "too long", and both are recorded here because the next person
%% to assemble a large document in cocolog will meet them in this order.
as_write_codes([]) :- !.
as_write_codes(Cs) :-
    as_take_c(4000, Cs, Chunk),
    as_drop(4000, Cs, Rest),
    format("~s", [Chunk]),
    as_write_codes(Rest).
as_output(_, Sizes, Req, V, Sys, Usr, Parts, Cap) :-
    V = verdict(Topics, _, Arr, Libs, Tags),
    ( Libs == [] -> LibsA = none ; as_repr_list(Libs, LibsA) ),
    as_repr_list(Tags, TagsA),
    format("request : ~w~n", [Req]),
    format("router  : STUB | ~w | imports ~w | exemplars ~w~n", [Arr, LibsA, TagsA]),
    ( Topics == [] -> TopA = none ; as_join_commas(Topics, TopA) ),
    format("          topics matched: ~w~n", [TopA]),
    nl,
    as_est_atom(Sys, SN),
    format("system  : ~~~w tokens~n", [SN]),
    (   Sizes == yes
    ->  forall(member(p(N, E, K), Parts),
               ( as_pad(N, 40, PN), atom_number(EA, E), as_lpad(EA, 5, PE),
                 ( K == yes -> Tail = '' ; Tail = '(dropped)' ),
                 format("  ~w ~~~w ~w~n", [PN, PE, Tail]) ))
    ;   true
    ),
    as_est_atom(Usr, UN),
    format("user    : ~~~w tokens of a ~w cap~n", [UN, Cap]),
    as_over_cap(Usr, Cap, Over),
    (   Over > 0
    ->  format("          OVER CAP by ~~~w tokens with every rung spent. The tier-2~n", [Over]),
        format("          symbol rows dominate; narrow the request or split it.~n")
    ;   true
    ),
    Total is SN + UN,
    format("total   : ~~~w tokens per request~n", [Total]).

%% Python's repr of a list of strings: ['a', 'b']. Matched because these two
%% lines are compared against the Python's output character for character.
as_repr_list(Xs, Out) :-
    findall(Q, ( member(X, Xs), as_quote(X, Q) ), Qs),
    as_join_commas_sp(Qs, Inner),
    atomic_list_concat(['[', Inner, ']'], Out).

as_quote(X, Q) :- atomic_list_concat(['''', X, ''''], Q).

as_join_commas_sp([], '') :- !.
as_join_commas_sp([X], X) :- !.
as_join_commas_sp([X|Xs], A) :-
    as_join_commas_sp(Xs, R), atomic_list_concat([X, ', ', R], A).

as_join_commas([], '') :- !.
as_join_commas([X], X) :- !.
as_join_commas([X|Xs], A) :- as_join_commas(Xs, R), atomic_list_concat([X, ', ', R], A).
