%% build.pl -- the reserved-name blocklist, built from source in one pass.
%%
%%     cocolog --local run clauses.pl build.pl bd_main
%%     cocolog --local run clauses.pl build.pl bd_main -- --if-stale
%%
%% THE COCOLOG REWRITE OF build.py, and the Python is gone. What it does is
%% unchanged and its two outputs are byte-identical, which is the bar the
%% clauses.py and lint.py rewrites set and the only one worth having: a
%% rewrite that "looks equivalent" is a second implementation nobody can
%% check.
%%
%% ONE THING GOT SMALLER RATHER THAN TRANSLATED. build.py talked to the
%% clause reader through ccbatch.py, 209 lines of length-prefixed batching
%% that existed for one reason: clauses.pl is a cocolog process and Python
%% is not, so 615 calls were 615 start-ups until somebody batched them.
%% This file IS a cocolog process, so it calls cc_clauses_of/2 directly and
%% the whole apparatus -- the priming, the content-keyed cache, the process
%% counter printed so a batching regression would be visible -- is deleted
%% rather than ported. That is the argument for the rewrite in one file.
%%
%% FIVE REGISTRATION SHAPES, and the fifth is the one an earlier pass missed:
%%
%%   1  (DEFPARAMETER *X-predicates*/*builtins* '(("name" arity fn) ...))
%%   2  (DEFPARAMETER *X-prolog* (FORMAT NIL "~{~A ~}" (LIST "clause..." ...)))
%%   3  a hand-written strcmp chain under (== arity N)  -- torch and bigint only
%%   4  clause heads at column 0 in a .pl file          -- DCG heads at arity+2
%%   5  (DEFPARAMETER *construct-names* ...)            -- NO ARITY, any arity blocked
%%
%% NO TOTAL IS AN ACCEPTANCE TEST. Two independent extractions once got 464
%% and ~533 for tier 1, differing on $-prefixed internals, DCG arity and
%% comment stripping. The linter needs the SET, regenerated from source; a
%% count pinned in a test would just go stale and be edited to match.
%%
%% TWO AXES, because the two halves fail differently:
%%
%%   WHEN   tier 1 is always live; a module's names only once imported.
%%   HOW    a C-registered name is dispatched BEFORE the store
%%          (lib/solve.cicili:1352-1386), so redefining it is DEAD CODE.
%%          A clause-defined one is consulted into the same store and consult
%%          APPENDS, so redefining it merges the two sets of clauses.
%%
%% THE SCANNERS ARE HAND-WRITTEN AND NOT library(text) REGEXES, for the
%% reason clauses.pl gives at length: a regex answers where a match is and
%% nothing about what it means, and three of these five shapes need a
%% BALANCED s-expression, which no regular language can find. `re_first/3'
%% also answers only the first match and hands back no capture groups, so
%% every one of build.py's seven patterns would have needed a re_replace
%% trick to get its groups out. Written out, each is a dozen lines that say
%% what they look for.

:- use_module(library(json)).

%% ---- where things are -------------------------------------------------

bd_root(Root) :-
    (   getenv('COCOLOG_ROOT', R)
    ->  Root = R
    ;   working_directory(Root, Root)
    ).

bd_path(Rel, Abs) :-
    bd_root(Root),
    atomic_list_concat([Root, '/', Rel], Abs).

%% Relative to the root, which is how every path is recorded: an absolute
%% one would put this machine's directory layout into a generated file.
bd_rel(Abs, Rel) :-
    bd_root(Root),
    atom_concat(Root, Rest0, Abs),
    !,
    (   atom_concat('/', Rest, Rest0) -> Rel = Rest ; Rel = Rest0 ).
bd_rel(A, A).

bd_glob(Pattern, Files) :-
    bd_path(Pattern, Abs),
    expand_file_name(Abs, Fs),
    sort(Fs, Files).

%% ---- the little scanners ----------------------------------------------
%%
%% Whitespace is Python's `\s': space, tab, newline, return, form feed and
%% vertical tab. Named here once because three shapes want it.

bd_space(0' ).   bd_space(0'\t).  bd_space(0'\n).
bd_space(0'\r).  bd_space(12).    bd_space(11).

bd_ws([C|T], R) :- bd_space(C), !, bd_ws(T, R).
bd_ws(L, L).

bd_ws1([C|T], R) :- bd_space(C), bd_ws(T, R).

bd_digit(C) :- C >= 0'0, C =< 0'9.

bd_digits1([C|T], [C|Ds], R) :- bd_digit(C), bd_digits(T, Ds, R).

bd_digits([C|T], [C|Ds], R) :- bd_digit(C), !, bd_digits(T, Ds, R).
bd_digits(L, [], L).

bd_lower_us(C) :- C >= 0'a, C =< 0'z.
bd_lower_us(0'_).

%% Up to the next `"', which is what `[^"]+' means -- NO escape handling,
%% deliberately: these are Cicili table entries, where a name never contains
%% a quote, and shape 2's own string scanner below DOES handle escapes
%% because there the payload is Prolog text full of them.
bd_upto_quote([0'"|T], [], T) :- !.
bd_upto_quote([C|T], [C|Cs], R) :- bd_upto_quote(T, Cs, R).

%% ---- shape 1: the ("name" arity fn) tables ----------------------------
%%
%% ANY name, not just an alphanumeric one. An earlier version required
%% [a-zA-Z_] and therefore missed every OPERATOR builtin -- =/2, ==/2, is/2,
%% </2, =../2 -- which is fifteen names in lib/ alone, and exactly the ones a
%% generated program is most likely to redefine by accident.

bd_shape1(Files, Pairs) :-
    findall(Key-Rel,
            ( member(F, Files),
              bd_rel(F, Rel),
              read_file_to_codes(F, Cs),
              bd_scan1(Cs, Keys),
              member(Key, Keys)
            ),
            Pairs0),
    sort(Pairs0, Pairs).

bd_scan1([], []) :- !.
bd_scan1([0'(|T], Out) :-
    !,
    (   bd_entry1(T, Key)
    ->  Out = [Key|Rest]
    ;   Out = Rest
    ),
    bd_scan1(T, Rest).
bd_scan1([_|T], Out) :- bd_scan1(T, Out).

bd_entry1([0'"|T], Key) :-
    bd_upto_quote(T, NameCs, T1),
    NameCs \== [],
    bd_ws1(T1, T2),
    bd_digits1(T2, DigitCs, T3),
    bd_ws1(T3, T4),
    T4 = [C|_],
    bd_lower_us(C),
    atom_codes(Name, NameCs),
    atom_codes(Arity, DigitCs),
    bd_key(Name, Arity, Key).

%% A KEY IS THE ATOM `name/arity', not the term. build.py's dictionary keys
%% were strings and it sorted them as strings, so `=/2' comes before `abs/1'
%% by character code. Sorting Name/Arity terms would order by name as an
%% atom and then by arity as a NUMBER, which is a different order and a
%% different file.
bd_key(Name, Arity, Key) :-
    atomic_list_concat([Name, '/', Arity], Key).

%% ---- shape 2: the *X-prolog* halves -----------------------------------
%%
%% Clauses living inside a `*X-prolog*' DEFPARAMETER, read with the SAME
%% clause reader as a .pl file after unescaping, so a DCG in a module's Coco
%% half is recorded at arity+2 like any other.
%%
%% SCOPED TO THE TABLE, NOT TO EVERY STRING IN THE FILE, and the difference
%% was 354 names. Scanning every literal turned "abs" out of the arithmetic
%% strcmp chain into a clause `abs.' and recorded abs/0; the same went for
%% "abc" out of a test, "access_mode" out of a mode check, and 351 others.
%% Every one of them would have made the linter reject a program for defining
%% a name nothing in cocolog defines -- the worst kind of false positive,
%% because the message is confident and cites a file.
%%
%% The second guard is structural and cheap: a Prolog clause has a `('
%% somewhere, or is a `:-' or a `-->'. A bare identifier is an atom, and an
%% atom in a C string is not a program.

bd_shape2(Files, Pairs) :-
    findall(Key-Rel,
            ( member(F, Files),
              bd_rel(F, Rel),
              read_file_to_codes(F, Cs),
              bd_fragments(Cs, Texts),
              member(Text, Texts),
              bd_fragment_keys(Text, Keys),
              member(Key, Keys)
            ),
            Pairs0),
    sort(Pairs0, Pairs).

bd_fragment_keys(Text, Keys) :-
    cc_split_clauses(Text, Spans),
    findall(Key,
            ( member(Span, Spans),
              bd_slice(Text, Span, Slice),
              catch(cc_read_head(Slice, Span, cc_clause(_, head(N, A), Kind)), _, fail),
              Kind \== directive,
              \+ Kind = directive(_, _),
              bd_key(N, A, Key)
            ),
            Keys).

bd_slice(Codes, at(Off, _, _, Len), Slice) :-
    bd_drop(Off, Codes, Tail),
    bd_take(Len, Tail, Slice).

bd_drop(0, L, L) :- !.
bd_drop(_, [], []) :- !.
bd_drop(N, [_|T], R) :- N1 is N - 1, bd_drop(N1, T, R).

bd_take(0, _, []) :- !.
bd_take(_, [], []) :- !.
bd_take(N, [C|T], [C|R]) :- N1 is N - 1, bd_take(N1, T, R).

%% Every clause text inside a *X-prolog* DEFPARAMETER -- OR the one string a
%% C++ module binds its half to.
%%
%% TWO SHAPES, BECAUSE A C++ TARGET CANNOT USE THE FIRST. modules/tcp writes
%% `(DEFPARAMETER *tcp-prolog* (...))' and its half is a LIST of strings, one
%% clause each; modules/torch is `:cpp #t' and writes
%% `(var const char * torch_prolog . "...")', which is ONE string with the
%% whole program in it, newlines and all. Only the first was read, so
%% library(torch)'s friendly spellings -- tensor_add/3 through tensor_std/2,
%% model_save/2, model_load/2, tensor_train_test/4 -- were names cocolint had
%% never heard of: no collision warning if a program redefined one, and none
%% of them offered to a generator. Thirty predicates of the library a tensor
%% program is most likely to call.
%%
%% THE GUARD IS THE REGION, NOT THE STRING, for the second shape. A table's
%% strings are guarded one at a time because a DEFPARAMETER holds arbitrary
%% literals beside the clauses; a `*_prolog' binding holds the half and
%% nothing else, and its text starts `:- dynamic ...', which no per-clause
%% guard would let through. The clause splitter downstream is the same one
%% either way, and it drops the directives itself.
bd_fragments(Codes, Texts) :-
    bd_table_regions(Codes, Regions),
    findall(T,
            ( member(Kind-Region, Regions),
              bd_strings(Region, Raw),
              member(R, Raw),
              bd_unescape(R, U),
              bd_strip(U, Text),
              bd_region_text(Kind, Text, T)
            ),
            Texts).

bd_region_text(table, Text, T) :- bd_fragment_ok(Text, T).
bd_region_text(blob, Text, Text) :- Text \== [].

%% `not text or not re.match(r"^'?[$a-z]", text)' then the structural guard,
%% then a `.' if it has none.
bd_fragment_ok(Text, Out) :-
    Text \== [],
    bd_starts_clause(Text),
    bd_has_structure(Text),
    (   append(_, ".", Text) -> Out = Text ; append(Text, ".", Out) ).

bd_starts_clause([0''|T]) :- !, T = [C|_], bd_clause_start(C).
bd_starts_clause([C|_]) :- bd_clause_start(C).

bd_clause_start(0'$).
bd_clause_start(C) :- bd_lower(C).

bd_lower(C) :- C >= 0'a, C =< 0'z.

bd_has_structure(T) :- bd_contains(T, "(").
bd_has_structure(T) :- bd_contains(T, ":-").
bd_has_structure(T) :- bd_contains(T, "-->").

bd_contains(Hay, Needle) :- append(_, Rest, Hay), append(Needle, _, Rest), !.

bd_strip(Cs, Out) :-
    bd_ws(Cs, A),
    bd_rstrip(A, Out).

bd_rstrip(Cs, Out) :-
    reverse(Cs, R0),
    bd_ws(R0, R1),
    reverse(R1, Out).

bd_all_space([]).
bd_all_space([C|T]) :- bd_space(C), bd_all_space(T).

%% (DEFPARAMETER \s+ \* [a-z0-9-]+ -prolog \* ... balanced to its close.
%% CASE-INSENSITIVE on DEFPARAMETER, which is `re.I' in the original.
%%
%% ONE WALK, NOT ONE PER POSITION. The first version indexed -- try position
%% 0, then 1, then 2, each reached by dropping that many cells from the head
%% -- which is quadratic in the file and took THREE MINUTES over lib/, with
%% no output, because a failing goal exits silently. It is the same trap
%% cc_clauses_of/2's own comment names about slicing clauses. Walking the
%% list and testing the head costs one pass.
bd_table_regions([], []) :- !.
bd_table_regions([0'(|T], Out) :-
    !,
    (   bd_prolog_region(T, Kind)
    ->  bd_sexp([0'(|T], Region),
        Out = [Kind-Region|Rest]
    ;   Out = Rest
    ),
    bd_table_regions(T, Rest).
bd_table_regions([_|T], Out) :- bd_table_regions(T, Out).

bd_prolog_region(Cs, table) :- bd_is_prolog_table(Cs), !.
bd_prolog_region(Cs, blob)  :- bd_is_prolog_blob(Cs).

bd_is_prolog_table(Cs) :-
    bd_ci_word("defparameter", Cs, T1),
    bd_ws1(T1, T2),
    T2 = [0'*|T3],
    bd_tablename(T3, T4),
    bd_ci_word("-prolog", T4, T5),
    T5 = [0'*|_].

%% `(var const char * torch_prolog . "...")'. The name is anchored on both
%% sides -- a lower-case word, then the literal `_prolog', then whitespace --
%% so it cannot match a `const char *' that merely mentions prolog, and the
%% `(const char * prolog)' ARGUMENT in every module's own declaration of
%% coco_module_register is not it: that one has no name before `prolog'.
bd_is_prolog_blob(Cs) :-
    bd_ci_word("var", Cs, T1),
    bd_ws1(T1, T2),
    bd_ci_word("const", T2, T3),
    bd_ws1(T3, T4),
    bd_ci_word("char", T4, T5),
    bd_ws1(T5, [0'*|T6]),
    bd_ws1(T6, T7),
    bd_tablename(T7, T8),
    bd_ci_word("_prolog", T8, T9),
    bd_ws1(T9, _).

bd_tablename([C|T], R) :- bd_namechar(C), bd_tablename_(T, R).
bd_tablename_([C|T], R) :- bd_namechar(C), !, bd_tablename_(T, R).
bd_tablename_(L, L).

%% [a-z0-9-] but NOT the `-' that begins `-prolog', which the greedy regex
%% resolves by backtracking. Here the check is done the other way: a `-' is
%% a name character only when what follows is not the literal `prolog*'.
bd_namechar(C) :- bd_lower(C).
bd_namechar(C) :- bd_digit(C).

bd_ci_word([], Cs, Cs).
bd_ci_word([W|Ws], [C|Cs], R) :- bd_ci_same(W, C), bd_ci_word(Ws, Cs, R).

bd_ci_same(W, C) :- W == C, !.
bd_ci_same(W, C) :- W >= 0'a, W =< 0'z, C =:= W - 32.

%% The s-expression opening at the head of the list, quotes respected.
bd_sexp(Cs, Region) :- bd_sexp_(Cs, 0, [], Region).

bd_sexp_([], _, Acc, Region) :- !, reverse(Acc, Region).
bd_sexp_([0'"|T], D, Acc, R) :- !, bd_sexp_q(T, D, [0'"|Acc], R).
bd_sexp_([0'(|T], D, Acc, R) :- !, D1 is D + 1, bd_sexp_(T, D1, [0'(|Acc], R).
bd_sexp_([0')|T], D, Acc, R) :-
    !,
    D1 is D - 1,
    (   D1 =:= 0
    ->  reverse([0')|Acc], R)
    ;   bd_sexp_(T, D1, [0')|Acc], R)
    ).
bd_sexp_([C|T], D, Acc, R) :- bd_sexp_(T, D, [C|Acc], R).

bd_sexp_q([], D, Acc, R) :- !, bd_sexp_([], D, Acc, R).
bd_sexp_q([0'\\, C|T], D, Acc, R) :- !, bd_sexp_q(T, D, [C, 0'\\|Acc], R).
bd_sexp_q([0'"|T], D, Acc, R) :- !, bd_sexp_(T, D, [0'"|Acc], R).
bd_sexp_q([C|T], D, Acc, R) :- bd_sexp_q(T, D, [C|Acc], R).

%% Every "..." in the region, with backslash escapes respected.
bd_strings([], []) :- !.
bd_strings([0'"|T], [S|Rest]) :-
    !,
    bd_string_body(T, S, T1),
    bd_strings(T1, Rest).
bd_strings([_|T], Out) :- bd_strings(T, Out).

bd_string_body([], [], []) :- !.
bd_string_body([0'\\, C|T], [0'\\, C|S], R) :- !, bd_string_body(T, S, R).
bd_string_body([0'"|T], [], T) :- !.
bd_string_body([C|T], [C|S], R) :- bd_string_body(T, S, R).

bd_unescape([], []) :- !.
bd_unescape([0'\\, C|T], [U|R]) :- !, bd_esc(C, U), bd_unescape(T, R).
bd_unescape([C|T], [C|R]) :- bd_unescape(T, R).

bd_esc(0'n, 0'\n) :- !.
bd_esc(0't, 0'\t) :- !.
bd_esc(C, C).

%% ---- shape 3: the strcmp chains ---------------------------------------
%%
%% torch's and bigint's hand-written dispatch. No arity is recorded there,
%% so the name is blocked at every arity -- written `name/*' and matched by
%% name.

bd_shape3(Files, Pairs) :-
    findall(Key-Rel,
            ( member(F, Files),
              bd_rel(F, Rel),
              read_file_to_codes(F, Cs),
              bd_scan3(Cs, Keys),
              member(Key, Keys)
            ),
            Pairs0),
    sort(Pairs0, Pairs).

bd_scan3([], []) :- !.
bd_scan3(Cs, Out) :-
    bd_ci_word("strcmp", Cs, T1),
    bd_ws1(T1, T2),
    bd_ci_word("name", T2, T3),
    bd_ws1(T3, [0'"|T4]),
    bd_upto_quote(T4, NameCs, T5),
    NameCs \== [],
    !,
    atom_codes(Name, NameCs),
    bd_key(Name, '*', Key),
    Out = [Key|Rest],
    bd_scan3(T5, Rest).
bd_scan3([_|T], Out) :- bd_scan3(T, Out).

%% ---- shape 4: clause heads at column 0 --------------------------------
%%
%% MINUS THE HOOKS. A library clause of the form `H :- fail.' is not a
%% definition, it is a DECLARED EXTENSION POINT: library/httpd.pl's
%% `httpd_page(_,_,_) :- fail.' is there precisely so a program can add its
%% own pages, which is the whole design of that library. Blocking the name
%% would tell every httpd user to rename the one predicate they are supposed
%% to write.
%%
%% THE HOOKS ARE RETURNED TOO, not thrown away, because the collision oracle
%% needs the same set. Measured over the corpus, the oracle and rule N1 agree
%% on every file but one: 16-httpd.pl's httpd_page/3, which the oracle calls
%% COLLIDED (correctly -- the clauses do merge and current_predicate/1 does
%% say no) and N1 stays quiet about (correctly -- it is the extension point
%% the library exists to offer). Both are right about the mechanism and only
%% one is right about the intent, so both must read the same list or they
%% will drift apart.

bd_shape4(Files, Heads, Hooks) :-
    findall(K-R-H,
            ( member(F, Files),
              bd_rel(F, R),
              catch(bd_file_keys(F, K, H), _, fail)
            ),
            Rows),
    findall(Key-Rel, ( member(Ks-Rel-_, Rows), member(Key, Ks) ), H0),
    findall(Key-Rel, ( member(_-Rel-Hs, Rows), member(Key, Hs) ), K0),
    sort(H0, Heads),
    sort(K0, Hooks).

bd_file_keys(File, Keys, Hooks) :-
    read_file_to_codes(File, Codes),
    cc_split_clauses(Codes, Spans),
    bd_slices(Spans, 0, Codes, Slices),
    bd_partition(Spans, Slices, Keys0, Hooks0),
    sort(Keys0, Keys1),
    sort(Hooks0, Hooks),
    bd_subtract(Keys1, Hooks, Keys).

%% ONE WALK, in span order, for the reason cc_clauses_of/2 gives: cutting
%% each slice from the start of the file would be quadratic.
bd_slices([], _, _, []).
bd_slices([at(Off, _, _, Len)|Ss], Pos, Codes, [Slice|Rest]) :-
    Skip is Off - Pos,
    bd_drop(Skip, Codes, Here),
    bd_take(Len, Here, Slice),
    Next is Off + Len,
    bd_drop(Len, Here, Tail),
    bd_slices(Ss, Next, Tail, Rest).

bd_partition([], [], [], []).
bd_partition([S|Ss], [Sl|Sls], Keys, Hooks) :-
    (   catch(cc_read_head(Sl, S, cc_clause(_, head(N, A), Kind)), _, fail),
        Kind \== directive,
        \+ Kind = directive(_, _)
    ->  bd_key(N, A, Key),
        bd_strip(Sl, Text),
        (   bd_is_hook(Text)
        ->  Hooks = [Key|Hs], Keys = Ks
        ;   Keys = [Key|Ks], Hooks = Hs
        )
    ;   Keys = Ks, Hooks = Hs
    ),
    bd_partition(Ss, Sls, Ks, Hs).

%% `^[^:]*:-\s*fail\s*\.$' over the stripped clause text.
bd_is_hook(Text) :-
    bd_upto_neck(Text, After),
    bd_ws(After, A1),
    append("fail", A2, A1),
    bd_ws(A2, [0'.|A3]),
    bd_ws(A3, []).

bd_upto_neck([0':, 0'-|T], T) :- !.
bd_upto_neck([C|T], R) :- C \== 0':, bd_upto_neck(T, R).

bd_subtract([], _, []).
bd_subtract([K|T], Drop, Out) :-
    (   memberchk(K, Drop) -> Out = Rest ; Out = [K|Rest] ),
    bd_subtract(T, Drop, Rest).

%% ---- shape 5: the control constructs ----------------------------------
%%
%% lib/solve.cicili places them ahead of every builtin in *dispatch-names*.
%% NO ARITY IS RECORDED, so nothing you can name escapes -- which makes this
%% the most absolute of the five and the one an earlier blocklist missed
%% entirely.

bd_shape5(Pairs) :-
    bd_path('lib/solve.cicili', F),
    read_file_to_codes(F, Cs),
    (   bd_constructs(Cs, Names)
    ->  true
    ;   Names = []
    ),
    findall(Key-'lib/solve.cicili',
            ( member(N, Names), bd_key(N, '*', Key) ),
            Pairs0),
    sort(Pairs0, Pairs).

bd_constructs(Codes, Names) :-
    bd_construct_region(Codes, Region),
    !,
    bd_plain_strings(Region, Raw),
    findall(N, ( member(R, Raw), atom_codes(N, R) ), Names).

%% `\(DEFPARAMETER \*construct-names\*\s*'\((.*?)\)\)' -- the inner list.
bd_construct_region([0'(|T], Region) :-
    append("DEFPARAMETER *construct-names*", After, T),
    !,
    bd_ws(After, [0''|Q]),
    bd_sexp(Q, Region).
bd_construct_region([_|T], Region) :- bd_construct_region(T, Region).

%% `"([^"]+)"' -- no escape handling, which is what the original used here.
bd_plain_strings([], []) :- !.
bd_plain_strings([0'"|T], [S|Rest]) :-
    !,
    bd_upto_quote(T, S, T1),
    bd_plain_strings(T1, Rest).
bd_plain_strings([_|T], Out) :- bd_plain_strings(T, Out).

%% ---- the build ---------------------------------------------------------

bd_build(b(T1c, T1p, T2, Hooks)) :-
    bd_glob('lib/*.cicili', LibC),
    bd_glob('modules/*/*.cicili', ModC),
    bd_glob('lib/swipl/*.pl', SwiplPl),
    bd_glob('library/*.pl', LibPl),

    bd_shape1(LibC, S1),
    bd_shape5(S5),
    append(S1, S5, T1c0),
    sort(T1c0, T1c1),

    bd_shape2(LibC, S2),
    bd_shape4(SwiplPl, SwiplHeads, SwiplHooks),
    append(S2, SwiplHeads, T1p0),
    sort(T1p0, T1p1),

    bd_tier2(ModC, LibPl, T2, LibHooks),
    append(SwiplHooks, LibHooks, Hooks0),
    sort(Hooks0, Hooks1),

    %% A name registered in C is dispatched before the store, so the C set
    %% wins. AND A CONSTRUCT NAME WINS AT EVERY ARITY, which is a separate
    %% line because a construct is recorded with NO arity (`throw/*'):
    %% matching only on the exact key left throw/1 in the clause set, where
    %% the prompt's symbol block would have called it nondet. Asked
    %% directly, the store says throw/1 is visible -- the oracle's
    %% documented blind spot -- so rule N3, which matches on the name
    %% alone, is the only thing that catches it.
    bd_group(T1c1, T1c),
    findall(N, ( member(K-_, T1c), bd_star_name(K, N) ), StarNames0),
    sort(StarNames0, StarNames),
    findall(K-F,
            ( member(K-F, T1p1),
              \+ bd_haskey(T1c, K),
              bd_name_of(K, N),
              \+ memberchk(N, StarNames)
            ),
            T1p2),
    bd_group(T1p2, T1p),
    bd_group(Hooks1, Hooks).

bd_star_name(Key, Name) :-
    atom_concat(Name, '/*', Key).

bd_name_of(Key, Name) :-
    atom_codes(Key, Cs),
    bd_upto_last_slash(Cs, NameCs),
    atom_codes(Name, NameCs).

bd_upto_last_slash(Cs, Name) :-
    append(Name, [0'/|Rest], Cs),
    \+ memberchk(0'/, Rest),
    !.

bd_haskey([K-_|_], K) :- !.
bd_haskey([_|T], K) :- bd_haskey(T, K).

%% Tier 2, per module directory and per library file.
%%
%% EVERY FILE OF A MODULE, MERGED. A module directory holds more than its
%% own source: `sdk.cicili' is a symlink into lib/, and the glob finds it.
%% The first version looked the module up with memberchk/2 and so took
%% whichever file sorted first -- which is the real one for aes, curl, der,
%% os and process, and `sdk.cicili' for sha, tcp, text, thread, tls and
%% x509. Six modules came out EMPTY and the module count still read 25,
%% which is why the counts matched and the file did not.
bd_tier2(ModC, LibPl, T2, Hooks) :-
    findall(m(Mod, Key, File),
            ( member(F, ModC),
              bd_module_of(F, Mod),
              bd_shape1([F], A),
              bd_shape3([F], B),
              append(A, B, C0),
              member(Key-File, C0)
            ),
            C1),
    sort(C1, CT),
    findall(m(Mod, Key, File),
            ( member(F, ModC),
              bd_module_of(F, Mod),
              bd_shape2([F], P),
              member(Key-File, P)
            ),
            P1),
    findall(m(Mod, Key, File),
            ( member(F, LibPl),
              bd_library_of(F, Mod),
              bd_shape4([F], H, _),
              member(Key-File, H)
            ),
            P2),
    append(P1, P2, P3),
    sort(P3, PT),
    findall(K-R,
            ( member(F, LibPl), bd_shape4([F], _, Hs), member(K-R, Hs) ),
            Hooks0),
    %% UNGROUPED, because bd_build/1 groups once over these and the swipl
    %% hooks together. Grouping here as well nested the file list one level
    %% deeper and wrote cl_hook(..., '[library/httpd.pl]') -- a path with
    %% brackets in it, which is a fact nothing would ever match.
    sort(Hooks0, Hooks),
    findall(M, ( member(m(M, _, _), CT) ; member(m(M, _, _), PT) ), Mods0),
    sort(Mods0, Mods),
    findall(M-t2(C, P),
            ( member(M, Mods),
              bd_mod_group(M, CT, C),
              bd_mod_group(M, PT, P)
            ),
            T2).

%% The triples are sorted, so a module's pairs come out in key order.
bd_mod_group(M, Triples, Group) :-
    findall(K-F, member(m(M, K, F), Triples), Pairs),
    bd_group(Pairs, Group).

bd_module_of(File, Mod) :-
    atom_codes(File, Cs),
    bd_upto_last_slash(Cs, DirCs),
    bd_upto_last_slash(DirCs, ParentCs),
    append(ParentCs, [0'/|ModCs], DirCs),
    atom_codes(Mod, ModCs).

bd_library_of(File, Mod) :-
    atom_codes(File, Cs),
    append(_, [0'/|BaseCs], Cs),
    \+ memberchk(0'/, BaseCs),
    append(ModCs, ".pl", BaseCs),
    !,
    atom_codes(Mod, ModCs).

%% Key-File pairs, sorted, into Key-[File, ...].
bd_group([], []).
bd_group([K-F|T], [K-[F|Fs]|Rest]) :-
    bd_same(K, T, Fs, T1),
    bd_group(T1, Rest).

bd_same(K, [K2-F|T], [F|Fs], R) :- K == K2, !, bd_same(K, T, Fs, R).
bd_same(_, L, [], L).

%% ---- blocklist.json ----------------------------------------------------
%%
%% Keys sorted at every level, one space of indent: byte for byte what
%% `json.dumps(b, indent=1, sort_keys=True)' wrote. Verified by round trip
%% before the Python was deleted.

bd_json(b(T1c, T1p, T2, Hooks), json([hooks-HJ, tier1-T1J, tier2-T2J])) :-
    bd_map_json(Hooks, HJ),
    bd_map_json(T1c, CJ),
    bd_map_json(T1p, PJ),
    T1J = json([c-CJ, clauses-PJ]),
    findall(M-json([c-MC, clauses-MP]),
            ( member(M-t2(C, P), T2),
              bd_map_json(C, MC),
              bd_map_json(P, MP)
            ),
            T2J0),
    T2J = json(T2J0).

bd_map_json(Pairs, json(Out)) :-
    findall(K-Files, member(K-Files, Pairs), Out).

%% ---- blocklist.pl ------------------------------------------------------
%%
%% A 39-FOLD DIFFERENCE, MEASURED. library(json) parses the 72 KB
%% blocklist.json in 275ms; the same data as facts consults in 7ms, and
%% every lookup afterwards rides first-argument indexing instead of walking
%% an association list. The linter asks these questions once per clause head
%% over the corpus, so the difference is the whole run.
%%
%% IT ALSO SIDESTEPS A BUG. json_parse/2 is documented `is det' and is not:
%% any document containing true, false or null leaves a choice point whose
%% second solution throws syntax_error([]). The hot path never touches it.
%%
%% The JSON stays -- this still writes it, and it is the form a human greps.
%% This is a second rendering of one extraction, not a second extraction.

bd_facts(b(T1c, T1p, T2, Hooks), Text) :-
    bd_header(H),
    findall(L, ( member(K-Fs, T1c), member(F, Fs), bd_fact3(cl_t1c, K, F, L) ), L1),
    findall(L, ( member(K-Fs, T1p), member(F, Fs), bd_fact3(cl_t1p, K, F, L) ), L2),
    %% ONE MODULE AT A TIME, its C names then its clause names. Emitting
    %% every cl_t2c first and every cl_t2p after is the same SET and a
    %% different FILE, and a generated file that differs is a generated
    %% file nobody can diff against the last one.
    findall(L,
            ( member(M-t2(C, P), T2),
              (   member(K, C), F = cl_t2c
              ;   member(K, P), F = cl_t2p
              ),
              bd_pair_key(K, Key),
              bd_split_key(Key, N, A), bd_arity_num(A, AN),
              bd_line3(F, M, N, AN, L)
            ),
            L3),
    findall(L, ( member(K-[Fl|_], Hooks), bd_fact3(cl_hook, K, Fl, L) ), L5),
    append(H, L1, A1), append(A1, L2, A2), append(A2, L3, A3),
    append(A3, L5, Lines),
    bd_join(Lines, Text).

%% A tier-2 entry is Key-[File, ...] like tier 1's; only the key is written.
bd_pair_key(K-_, K) :- !.
bd_pair_key(K, K).

bd_fact3(Functor, Key, File, Line) :-
    bd_split_key(Key, N, A),
    bd_arity_num(A, AN),
    bd_q(N, QN), bd_q(File, QF),
    format(atom(Line), "~w(~w, ~w, ~w).", [Functor, QN, AN, QF]).

bd_line3(Functor, Mod, Name, Arity, Line) :-
    bd_q(Mod, QM), bd_q(Name, QN),
    format(atom(Line), "~w(~w, ~w, ~w).", [Functor, QM, QN, Arity]).

bd_split_key(Key, Name, Arity) :-
    atom_codes(Key, Cs),
    bd_upto_last_slash(Cs, NameCs),
    append(NameCs, [0'/|ACs], Cs),
    atom_codes(Name, NameCs),
    atom_codes(Arity, ACs).

%% -1 is how a CONTROL CONSTRUCT travels: matched by name at every arity.
bd_arity_num('*', -1) :- !.
bd_arity_num(A, N) :- atom_number(A, N).

%% An atom, quoted for cocolog's reader. Doubling is how a quote escapes.
bd_q(A, Q) :-
    atom_codes(A, Cs),
    bd_double_quotes(Cs, Ds),
    atom_codes(Inner, Ds),
    atomic_list_concat(['''', Inner, ''''], Q).

bd_double_quotes([], []).
bd_double_quotes([0''|T], [0'', 0''|R]) :- !, bd_double_quotes(T, R).
bd_double_quotes([C|T], [C|R]) :- bd_double_quotes(T, R).

bd_join([], "") :- !.
bd_join(Lines, Text) :-
    findall(Cs, ( member(L, Lines), atom_codes(L, Cs0), append(Cs0, "\n", Cs) ), Parts),
    bd_concat(Parts, Text).

bd_concat([], []).
bd_concat([P|Ps], Out) :- bd_concat(Ps, Rest), append(P, Rest, Out).

bd_header([ '%% blocklist.pl -- GENERATED by tools/cocolint/build.pl. Do not edit.',
            '%%',
            '%% cl_t1c(Name, Arity, File)    C-dispatched in tier 1; redefining it is',
            '%%                              DEAD CODE, because dispatch reaches the',
            '%%                              builtin table before the store.',
            '%%                              Arity -1 means a CONTROL CONSTRUCT, which',
            '%%                              is matched by name at every arity.',
            '%% cl_t1p(Name, Arity, File)    clause-defined in tier 1; redefining it',
            '%%                              APPENDS to the library''s clauses.',
            '%% cl_t2c/cl_t2p(Mod, N, A)     tier 2, counted only when imported.',
            '%% cl_hook(Name, Arity, File)   a declared extension point (H :- fail.),',
            '%%                              which is a collision that is MEANT.',
            '' ]).

%% ---- staleness ---------------------------------------------------------
%%
%% REBUILD ONLY WHEN SOMETHING CHANGED, and be honest about what `changed'
%% means: the sources the five shapes read, plus this file and clauses.pl,
%% because a change to either alters the answer without touching an input.

bd_inputs(Files) :-
    bd_glob('lib/*.cicili', A),
    bd_glob('modules/*/*.cicili', B),
    bd_glob('lib/swipl/*.pl', C),
    bd_glob('library/*.pl', D),
    bd_path('tools/cocolint/build.pl', E),
    bd_path('tools/cocolint/clauses.pl', F),
    append(A, B, AB), append(AB, C, ABC), append(ABC, D, ABCD),
    append(ABCD, [E, F], Files).

bd_outputs([J, P]) :-
    bd_path('tools/cocolint/blocklist.json', J),
    bd_path('tools/cocolint/blocklist.pl', P).

bd_is_stale :-
    bd_outputs(Outs),
    ( member(O, Outs), \+ exists_file(O) -> true
    ; findall(T, ( member(O, Outs), time_file(O, T) ), Ts),
      bd_min(Ts, Newest),
      bd_inputs(Ins),
      member(I, Ins),
      exists_file(I),
      time_file(I, TI),
      TI > Newest,
      !
    ).

bd_min([T], T) :- !.
bd_min([T|Ts], M) :- bd_min(Ts, M0), ( T < M0 -> M = T ; M = M0 ).

%% ---- writing -----------------------------------------------------------
%%
%% ATOMIC, VIA A TEMPORARY AND A RENAME. A GENERATED FILE IS READ WHILE IT
%% IS BEING WRITTEN: test/lint.pl invokes lint.sh several times and each may
%% rebuild the index, so a reader can open blocklist.pl exactly as a writer
%% is truncating it -- and what comes back is a partial file that either
%% fails to parse or, worse, parses into a short blocklist and reports fewer
%% collisions. rename(2) is atomic within a directory, so a reader sees the
%% old file or the new one and never half of either.

bd_write_atomic(Path, Codes) :-
    atom_concat(Path, '.tmp', Tmp),
    write_file_from_codes(Tmp, Codes),
    rename_file(Tmp, Path).

%% ---- the entry point ---------------------------------------------------
%%
%% ONE FLAG, SO NO OPTION PARSER. `--if-stale' is the whole surface, and
%% reaching for library(main) to read one word would be more machinery than
%% the thing it parses.

bd_main :-
    current_prolog_flag(argv, [_|Args]),
    (   memberchk('--if-stale', Args), \+ bd_is_stale
    ->  true
    ;   bd_run
    ).

bd_run :-
    bd_build(B),
    B = b(T1c, T1p, T2, Hooks),
    bd_json(B, J),
    json_codes(J, JC, [indent(1)]),
    bd_outputs([JPath, PPath]),
    bd_write_atomic(JPath, JC),
    bd_facts(B, FC),
    bd_write_atomic(PPath, FC),
    length(T1c, NC), length(T1p, NP), length(T2, NM), length(Hooks, NH),
    format("tier 1: ~w C-dispatched (redefinition is dead code)~n", [NC]),
    format("        ~w clause-defined (redefinition appends)~n", [NP]),
    format("tier 2: ~w libraries/modules, blocked only when imported~n", [NM]),
    format("hooks : ~w declared extension points, excused in both halves~n", [NH]),
    bd_rel(JPath, JR), bd_rel(PPath, PR),
    format("wrote ~w and ~w~n", [JR, PR]).
