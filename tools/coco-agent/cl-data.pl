%% cl-data -- cocolint's two data files, read in cocolog.
%%
%% lint.py opens blocklist.json (~72 KB, ~1300 predicate indicators) and
%% traps.jsonl (36 rows, one JSON document per line) before it looks at a
%% single source file. This is the same load and the same counts. It
%% decides nothing: it answers "is this name already taken, and by what"
%% and "what are the thirty-six traps", and the rules that ask are
%% somebody else's clauses.
%%
%% ---- WHAT IT REFUSES TO GUESS -----------------------------------------
%%
%%   A KEY THAT IS NOT `name/arity' THROWS, naming the key. Skipping it
%%   would leave the blocklist one entry short and the linter one
%%   collision short, and nothing anywhere would say so.
%%
%%   A MISSING TOP-LEVEL MEMBER THROWS, naming the member. A blocklist
%%   with no `tier2' is a build.py that changed shape, not an empty set
%%   of modules.
%%
%%   A SEVERITY OUTSIDE HARD/WARN/PROMPT THROWS, naming the row -- the
%%   same three traps.py checks -- rather than defaulting to the mild one.
%%
%%   A QUERY WITH AN UNBOUND NAME THROWS rather than failing. `get_assoc/3'
%%   on a variable key walks the tree and answers no, and "no" here reads
%%   exactly like "that name is free", which is the one wrong answer this
%%   file could give.
%%
%%   NO BLOCKLIST FILE ANYWHERE THROWS, naming every directory tried. A
%%   linter that silently found no blocklist reports no collisions and
%%   exits 0, which is worse than not running.
%%
%% ---- THE FOUR QUESTIONS, AND WHICH PREDICATE IS WHICH ------------------
%%
%%   is Name/Arity C-dispatched in tier 1?          cl_bl_t1_c/4
%%   is it clause-defined in tier 1, and by which
%%   files?                                         cl_bl_t1_clauses/4
%%   is Name a control construct (ANY arity)?       cl_bl_construct/2
%%   is Name/Arity a declared hook?                 cl_bl_hook/4
%%
%%   and tier 2, which counts only when the file being linted imports the
%%   module:                                        cl_bl_t2_c/5
%%                                                  cl_bl_t2_clauses/5
%%   with cl_bl_c/5 and cl_bl_clauses/5 doing lint.py's `active_c' and
%%   `active_p' -- tier 1 first, then the imports in the order given.
%%
%% THE BUCKETS ARE DISJOINT, checked over the file rather than assumed:
%% no key of the 1297 appears in two of tier1.c, tier1.clauses, hooks or
%% any tier-2 module. So "which bucket wins a merge" is a question this
%% does not have to answer, and cl_bl_c/5 is honestly semidet.
%%
%% ---- THE SHAPE, and why it is a term rather than asserted facts -------
%%
%%     cl_bl(T1C, T1P, Ctl, Hooks, T2C, T2P, Mods)
%%
%%     T1C    assoc  Name/Arity          -> [File, ...]   tier1.c, all 163
%%     T1P    assoc  Name/Arity          -> [File, ...]   tier1.clauses, 400
%%     Ctl    assoc  Name                -> [File, ...]   the 22 `/*' rows
%%     Hooks  assoc  Name/Arity          -> [File, ...]   1
%%     T2C    assoc  t2(Mod,Name,Arity)  -> [File, ...]   163
%%     T2P    assoc  t2(Mod,Name,Arity)  -> [File, ...]   570
%%     Mods   the 24 module names, in file order
%%
%% A `/*' row keeps its place in T1C with the ATOM `*' as its arity, so
%% `cl_bl_t1_c(BL, call, 2, F)' correctly misses: no integer arity is a
%% construct's arity, and Ctl is the index that answers by name alone.
%%
%% MEASURED, on this box, ten runs each, whole process (`--local run'):
%%
%%     start-up + use_module(library(json))            6 ms
%%     + read_file_to_codes of the 72 KB                9 ms
%%     + json_parse of it                             247 ms
%%     + the whole index above                        311 ms
%%     + traps.jsonl on top of that                   375 ms
%%
%% So THE LOAD IS THE JSON PARSE -- 238 ms of 369, at ~3.3 us a byte --
%% and the index over 1297 entries is 64 ms of it. Asserting the same
%% entries as facts instead measured within noise of `list_to_assoc' to
%% BUILD (292 ms against 302 ms for tier 1) and much cheaper to READ:
%% 10 000 lookups cost ~80 ms through `get_assoc/3' (~8 us each) and
%% nothing measurable through first-argument indexing. It is a term
%% anyway, for two reasons that outrank 8 us: a linter run under `--kb'
%% or `--embed' would WRITE 1297 asserted facts into the knowledge base
%% it was invited to inspect, and a second `cl_blocklist/1' in one
%% process would append a second copy of all of them. At the scale the
%% linter works at -- a few hundred lookups a file -- the difference is
%% about 2 ms.
%%
%% ---- THE LIMITS, stated -----------------------------------------------
%%
%% Eight of the thirty-six rows write `"rule": null' and three write
%% `"fix": null'. Both reach a caller as the atom `none', which is what
%% python's truth tests already make of them and what cl_finding/9 spells
%% an absent fix.
%%
%% `swi', `cocolog' and `empirical' are read past and NOT carried: the
%% linter uses none of the three, and regenerating the dialect card is
%% traps.py --card's job. Move the card here and the term grows three
%% arguments.
%%
%% Nothing here checks a citation. traps.py --check opens every cited
%% file and looks for the anchor; that is a different tool with a
%% different exit code, and this one only has to hand over the rows.

:- use_module(library(json)).


%% ---- where the files are ----------------------------------------------

%% cl_data_dirs(-Dirs) is det.
%% WHERE lint.py HAS `__file__' THIS HAS TO SEARCH. cocolog answers
%% `current_prolog_flag(executable, P)' and no other flag -- there is no
%% argv and no path to the running program's source -- so the candidates
%% are an explicit override, the repository root, the binary's own
%% directory, and the working directory, in that order.
cl_data_dirs(Dirs) :-
    findall(D, cl_data_dir(D), Dirs).

cl_data_dir(D) :-
    getenv('COCO_AGENT_DIR', D).
cl_data_dir(D) :-
    getenv('COCOLOG_ROOT', R),
    atom_concat(R, '/tools/coco-agent', D).
cl_data_dir(D) :-
    current_prolog_flag(executable, X),
    file_directory_name(X, R),
    atom_concat(R, '/tools/coco-agent', D).
cl_data_dir('tools/coco-agent').

%% cl_data_file(+Base, -Path) is det.
cl_data_file(Base, Path) :-
    cl_data_dirs(Dirs),
    (   member(D, Dirs),
        atomic_list_concat([D, '/', Base], P),
        exists_file(P)
    ->  Path = P
    ;   throw(error(existence_error(source_sink, Base), cl_data_dirs(Dirs)))
    ).


%% ---- reading a JSON object --------------------------------------------

%% cl_j_get(+Object, +Key, -Value) is det.
%% A MISSING MEMBER IS A THROW, not a failure, because every member this
%% file asks for is one build.py always writes: its absence is a shape
%% change, and a shape change that fails quietly becomes an empty index.
cl_j_get(json(Pairs), Key, Value) :-
    !,
    (   memberchk(Key-V, Pairs)
    ->  Value = V
    ;   throw(error(existence_error(json_key, Key), cl_j_get/3))
    ).
cl_j_get(Term, Key, _) :-
    throw(error(type_error(json_object, Term), cl_j_get(Key))).

%% cl_j_obj(+Object, +Key, -Pairs) is det.
cl_j_obj(Object, Key, Pairs) :-
    cl_j_get(Object, Key, Value),
    (   Value = json(P)
    ->  Pairs = P
    ;   throw(error(type_error(json_object, Value), cl_j_obj(Key)))
    ).

%% cl_j_opt(+Pairs, +Key, +Default, -Value) is det.
%% cl_j_or(+Value, +Default, -Value) is det.
%%
%% ABSENT, JSON null AND THE EMPTY STRING ARE ONE THING. Eight rows of
%% traps.jsonl write `"rule": null' and three write `"fix": null', and
%% python tests those fields for TRUTH -- `if self.fix:',
%% `r.get("fix") or ""' -- so a null and a missing key are already the
%% same field there. Carrying `@(null)' through instead would put a
%% compound where every caller expects an atom, and `format/2' would
%% print it as the word `@(null)' in a finding.
cl_j_opt(Pairs, Key, Default, Value) :-
    (   memberchk(Key-V, Pairs)
    ->  cl_j_or(V, Default, Value)
    ;   Value = Default
    ).

cl_j_or(V, Default, Value) :-
    (   cl_j_absent(V)
    ->  Value = Default
    ;   Value = V
    ).

cl_j_absent(@(null)).
cl_j_absent('').

%% cl_read_file(+Path, -Codes) is det.
%% `read_file_to_codes/2' FAILS on a file that is not there -- no
%% exception, no message. A loader built straight on it fails silently
%% too, and a caller that wrote `( cl_blocklist(BL) -> ... ; ... )' would
%% report a clean file over a mistyped path. So the read is the one place
%% that turns a missing file into a throw naming it.
cl_read_file(Path, Codes) :-
    (   read_file_to_codes(Path, Cs)
    ->  Codes = Cs
    ;   throw(error(existence_error(source_sink, Path), cl_read_file/2))
    ).

%% cl_j_file(+Path, -Term) is det.
%% `once/1' IS NOT DECORATION. json_parse/2 is documented det and is not:
%% any document containing true, false or null leaves a choice point whose
%% second solution throws syntax_error([]), and a caller that backtracks
%% into it -- findall does -- gets that throw instead of an answer.
cl_j_file(Path, Term) :-
    cl_read_file(Path, Codes),
    once(json_parse(Codes, Term)).


%% ---- the blocklist ----------------------------------------------------

%% cl_blocklist(-BL) is det.
cl_blocklist(BL) :-
    cl_data_file('blocklist.json', Path),
    cl_blocklist(Path, BL).

%% cl_blocklist(+Path, -BL) is det.
cl_blocklist(Path, cl_bl(T1C, T1P, Ctl, Hooks, T2C, T2P, Mods)) :-
    cl_j_file(Path, J),
    cl_j_obj(J, tier1, Tier1Pairs),
    cl_j_get(json(Tier1Pairs), c, json(CRaw)),
    cl_j_get(json(Tier1Pairs), clauses, json(PRaw)),
    cl_j_obj(J, hooks, HRaw),
    cl_j_obj(J, tier2, T2Raw),
    cl_bl_pairs(CRaw, CPairs),
    cl_bl_pairs(PRaw, PPairs),
    cl_bl_pairs(HRaw, HPairs),
    cl_bl_stars(CPairs, CtlPairs),
    cl_bl_t2_pairs(T2Raw, T2CPairs, T2PPairs),
    cl_bl_mods(T2Raw, Mods),
    list_to_assoc(CPairs, T1C),
    list_to_assoc(PPairs, T1P),
    list_to_assoc(CtlPairs, Ctl),
    list_to_assoc(HPairs, Hooks),
    list_to_assoc(T2CPairs, T2C),
    list_to_assoc(T2PPairs, T2P).

%% cl_bl_pairs(+KeyPairs, -IndicatorPairs) is det.
cl_bl_pairs([], []).
cl_bl_pairs([Key-Files|T], [PI-Files|T2]) :-
    cl_bl_pi(Key, PI),
    cl_bl_pairs(T, T2).

%% cl_bl_pi(+Key, -Name/Arity) is det.
%% SPLIT ON THE LAST SLASH. `//2' is the division operator at arity two
%% and there are eight of those keys in tier1.clauses; splitting on the
%% first slash would name that predicate `' and lose every one of them.
cl_bl_pi(Key, PI) :-
    (   cl_bl_split(Key, PI0)
    ->  PI = PI0
    ;   throw(error(domain_error(predicate_indicator, Key), cl_blocklist/2))
    ).

cl_bl_split(Key, Name/Arity) :-
    atomic_list_concat(Parts, '/', Key),
    reverse(Parts, [Token|RevName]),
    RevName = [_|_],
    reverse(RevName, NameParts),
    atomic_list_concat(NameParts, '/', Name),
    cl_bl_arity(Token, Arity).

%% `*' IS AN ARITY HERE, and the one that is not a number: build.py writes
%% `call/*' for a control construct because no arity escapes one.
cl_bl_arity('*', '*') :- !.
cl_bl_arity(Token, Arity) :-
    atom_number(Token, Arity),
    integer(Arity),
    Arity >= 0.

%% cl_bl_stars(+IndicatorPairs, -NamePairs) is det.
%% The by-name index, built from the `/*' rows of tier1.c and from nothing
%% else -- a construct is a construct because the engine interns its id,
%% which is a property of the name alone.
cl_bl_stars([], []).
cl_bl_stars([Name/Arity-Files|T], Out) :-
    (   Arity == '*'
    ->  Out = [Name-Files|Out1]
    ;   Out = Out1
    ),
    cl_bl_stars(T, Out1).

%% cl_bl_t2_pairs(+ModulePairs, -CPairs, -PPairs) is det.
%% ONE ASSOC EACH, keyed t2(Mod,Name,Arity), rather than an assoc of
%% assocs: a lookup is one descent instead of two, and the caller never
%% holds a module's set on its own -- it asks about a name it has.
cl_bl_t2_pairs([], [], []).
cl_bl_t2_pairs([Mod-Entry|T], CPairs, PPairs) :-
    cl_j_obj(Entry, c, CRaw),
    cl_j_obj(Entry, clauses, PRaw),
    cl_bl_pairs(CRaw, C1),
    cl_bl_pairs(PRaw, P1),
    cl_bl_tag(Mod, C1, C2),
    cl_bl_tag(Mod, P1, P2),
    cl_bl_t2_pairs(T, C3, P3),
    append(C2, C3, CPairs),
    append(P2, P3, PPairs).

cl_bl_tag(_, [], []).
cl_bl_tag(Mod, [Name/Arity-Files|T], [t2(Mod, Name, Arity)-Files|T2]) :-
    cl_bl_tag(Mod, T, T2).

cl_bl_mods([], []).
cl_bl_mods([Mod-_|T], [Mod|T2]) :-
    cl_bl_mods(T, T2).


%% ---- asking the blocklist ---------------------------------------------

%% cl_bl_t1_c(+BL, +Name, +Arity, -Files) is semidet.
%% Q1: is Name/Arity C-dispatched in tier 1? Then clauses for it are DEAD
%% CODE -- dispatch reaches the builtin table before the store.
cl_bl_t1_c(cl_bl(T1C, _, _, _, _, _, _), Name, Arity, Files) :-
    cl_bl_key(Name, Arity, Key),
    get_assoc(Key, T1C, Files).

%% cl_bl_t1_clauses(+BL, +Name, +Arity, -Files) is semidet.
%% Q2: is it clause-defined in tier 1, and by which files? Then consult
%% APPENDS and the two sets of clauses merge.
cl_bl_t1_clauses(cl_bl(_, T1P, _, _, _, _, _), Name, Arity, Files) :-
    cl_bl_key(Name, Arity, Key),
    get_assoc(Key, T1P, Files).

%% cl_bl_construct(+BL, +Name) is semidet.
%% Q3: is Name a control construct? NO ARITY ESCAPES ONE, which is why
%% this takes a name and not an indicator.
cl_bl_construct(cl_bl(_, _, Ctl, _, _, _, _), Name) :-
    must_be(atom, Name),
    get_assoc(Name, Ctl, _).

%% cl_bl_hook(+BL, +Name, +Arity, -Files) is semidet.
%% Q4: is Name/Arity a declared hook -- an `H :- fail.' extension point?
%% That is a collision that is MEANT, and the caller reports it as one.
cl_bl_hook(cl_bl(_, _, _, Hooks, _, _, _), Name, Arity, Files) :-
    cl_bl_key(Name, Arity, Key),
    get_assoc(Key, Hooks, Files).

%% cl_bl_t2_c(+BL, +Mod, +Name, +Arity, -Files) is semidet.
cl_bl_t2_c(cl_bl(_, _, _, _, T2C, _, _), Mod, Name, Arity, Files) :-
    must_be(atom, Mod),
    cl_bl_key(Name, Arity, _),
    get_assoc(t2(Mod, Name, Arity), T2C, Files).

%% cl_bl_t2_clauses(+BL, +Mod, +Name, +Arity, -Files) is semidet.
cl_bl_t2_clauses(cl_bl(_, _, _, _, _, T2P, _), Mod, Name, Arity, Files) :-
    must_be(atom, Mod),
    cl_bl_key(Name, Arity, _),
    get_assoc(t2(Mod, Name, Arity), T2P, Files).

%% cl_bl_modules(+BL, -Mods) is det.
%% The twenty-four tier-2 modules the blocklist knows. An import of
%% anything else is not an error here -- lint.py ignores it too -- but a
%% caller that wants to say so needs the list.
cl_bl_modules(cl_bl(_, _, _, _, _, _, Mods), Mods).

%% cl_bl_c(+BL, +Imports, +Name, +Arity, -Files) is semidet.
%% lint.py's `active_c': tier 1 plus every imported tier-2 module.
cl_bl_c(BL, Imports, Name, Arity, Files) :-
    (   cl_bl_t1_c(BL, Name, Arity, F)
    ->  Files = F
    ;   once(( member(Mod, Imports),
               cl_bl_t2_c(BL, Mod, Name, Arity, Files) ))
    ).

%% cl_bl_clauses(+BL, +Imports, +Name, +Arity, -Files) is semidet.
%% lint.py's `active_p'.
cl_bl_clauses(BL, Imports, Name, Arity, Files) :-
    (   cl_bl_t1_clauses(BL, Name, Arity, F)
    ->  Files = F
    ;   once(( member(Mod, Imports),
               cl_bl_t2_clauses(BL, Mod, Name, Arity, Files) ))
    ).

%% cl_bl_key(+Name, +Arity, -Key) is det.
%% AN UNBOUND NAME THROWS. `get_assoc/3' compares a variable key against
%% the tree and answers no, and no here means "that name is free" -- the
%% single wrong answer a blocklist can give.
cl_bl_key(Name, Arity, Name/Arity) :-
    must_be(atom, Name),
    must_be(integer, Arity).

%% cl_bl_counts(+BL, -Counts) is det.
%% counts(T1C, T1Clauses, Constructs, Hooks, T2C, T2Clauses, Modules) --
%% for holding this loader to the numbers python reads out of the same
%% file. Not a hot path: it walks all six trees.
cl_bl_counts(cl_bl(T1C, T1P, Ctl, Hooks, T2C, T2P, Mods),
             counts(N1, N2, N3, N4, N5, N6, N7)) :-
    cl_bl_size(T1C, N1),
    cl_bl_size(T1P, N2),
    cl_bl_size(Ctl, N3),
    cl_bl_size(Hooks, N4),
    cl_bl_size(T2C, N5),
    cl_bl_size(T2P, N6),
    length(Mods, N7).

cl_bl_size(Assoc, N) :-
    assoc_to_keys(Assoc, Keys),
    length(Keys, N).


%% ---- traps.jsonl ------------------------------------------------------

%% cl_traps(-Traps) is det.
cl_traps(Traps) :-
    cl_data_file('traps.jsonl', Path),
    cl_traps(Path, Traps).

%% cl_traps(+Path, -Traps) is det.
%% JSON LINES IS NOT JSON: the file is one document per line and parsing
%% the whole of it as one value is a syntax error at the second `{'. So
%% the split comes first, and each line is its own `json_parse/2'.
cl_traps(Path, Traps) :-
    cl_read_file(Path, Codes),
    cl_lines(Codes, Lines),
    cl_trap_rows(Lines, Traps).

%% cl_lines(+Codes, -Lines) is det.
%% Split on 10 (newline). A trailing newline leaves a final empty line,
%% which the row loader skips like any other blank.
cl_lines(Codes, Lines) :-
    cl_lines_(Codes, [], [], Lines).

cl_lines_([], Acc, Done, Lines) :-
    reverse(Acc, Line),
    reverse([Line|Done], Lines).
cl_lines_([10|T], Acc, Done, Lines) :-
    !,
    reverse(Acc, Line),
    cl_lines_(T, [], [Line|Done], Lines).
cl_lines_([C|T], Acc, Done, Lines) :-
    cl_lines_(T, [C|Acc], Done, Lines).

%% cl_trap_rows(+Lines, -Traps) is det.
cl_trap_rows([], []).
cl_trap_rows([Line|Ls], Out) :-
    cl_strip(Line, S),
    (   cl_trap_skip(S)
    ->  Out = Out1
    ;   once(json_parse(S, J)),
        cl_trap_row(J, Row),
        Out = [Row|Out1]
    ),
    cl_trap_rows(Ls, Out1).

%% A BLANK LINE AND A `#' LINE ARE SKIPPED, which is traps.py's rule and
%% not a courtesy: JSON has no comment syntax, so a card row taken
%% temporarily out of service is commented out, and a loader that choked
%% on one would make the card uneditable.
cl_trap_skip([]).
cl_trap_skip([0'#|_]).

%% cl_strip(+Codes, -Stripped) is det.
%% Leading and trailing whitespace off, python's str.strip() as the rows
%% are read there. Space, tab, newline, return, form feed, vertical tab.
cl_strip(Codes, Stripped) :-
    cl_strip_left(Codes, A),
    reverse(A, B),
    cl_strip_left(B, C),
    reverse(C, Stripped).

cl_strip_left([], []).
cl_strip_left([C|T], Out) :-
    (   cl_space(C)
    ->  cl_strip_left(T, Out)
    ;   Out = [C|T]
    ).

cl_space(32).
cl_space(9).
cl_space(10).
cl_space(13).
cl_space(12).
cl_space(11).

%% cl_trap_row(+Json, -Trap) is det.
%%
%%     cl_trap(Id, Rule, Severity, Why, Fix, Pattern, Scan, Cites)
%%
%%     Id        the row's own name -- `N1', `F1', `Z1'
%%     Rule      the linter rule it belongs to, an atom
%%     Severity  hard | warn | prompt, DOWNCASED from the file's
%%               HARD/WARN/PROMPT so that one vocabulary reaches
%%               cl_finding/9 and nothing has to translate at the seam
%%     Why       the prose the finding quotes
%%     Fix       an atom, or `none'
%%     Pattern   the S1 regex VERBATIM, or `none' -- 17 rows have one
%%     Scan      code | text. `code' means a match inside a quote or a
%%               comment is not a finding; `text' means a quote counts,
%%               which is the only way a rule about `~t' or `\xHH\' can
%%               see its own subject. Nothing scans comments.
%%     Cites     [cite(At, Anchor), ...], At being `path:LINE' or
%%               `path:A-B'
cl_trap_row(json(Ps), cl_trap(Id, Rule, Sev, Why, Fix, Pattern, Scan, Cites)) :-
    !,
    cl_j_get(json(Ps), id, Id),
    cl_j_get(json(Ps), rule, RuleRaw),
    cl_j_or(RuleRaw, none, Rule),
    cl_j_get(json(Ps), severity, SevRaw),
    cl_trap_sev(SevRaw, Id, Sev),
    cl_j_get(json(Ps), why, Why),
    cl_j_opt(Ps, fix, none, Fix),
    cl_j_opt(Ps, pattern, none, Pattern),
    cl_j_opt(Ps, scan, code, ScanRaw),
    cl_trap_scan(ScanRaw, Id, Scan),
    cl_j_opt(Ps, cite, [], CiteRaw),
    cl_trap_cites(CiteRaw, Id, Cites).
cl_trap_row(T, _) :-
    throw(error(type_error(json_object, T), cl_traps/2)).

cl_trap_sev('HARD', _, hard) :- !.
cl_trap_sev('WARN', _, warn) :- !.
cl_trap_sev('PROMPT', _, prompt) :- !.
cl_trap_sev(S, Id, _) :-
    throw(error(domain_error(trap_severity, S), cl_trap(Id))).

cl_trap_scan(code, _, code) :- !.
cl_trap_scan(text, _, text) :- !.
cl_trap_scan(S, Id, _) :-
    throw(error(domain_error(trap_scan, S), cl_trap(Id))).

%% A CITE NEEDS BOTH `at' AND `anchor', which is traps.py --check's first
%% complaint about a row: an anchor is what stops a line number rotting
%% into a citation for code that has moved, and a cite with no anchor is
%% the rot it was meant to catch.
cl_trap_cites([], _, []).
cl_trap_cites([json(P)|T], Id, [cite(At, Anchor)|T2]) :-
    !,
    (   memberchk(at-At, P),
        memberchk(anchor-Anchor, P)
    ->  true
    ;   throw(error(domain_error(trap_cite, json(P)), cl_trap(Id)))
    ),
    cl_trap_cites(T, Id, T2).
cl_trap_cites([C|_], Id, _) :-
    throw(error(type_error(json_object, C), cl_trap(Id))).

%% cl_trap_patterns(+Traps, -Patterns) is det.
%%
%%     pat(Id, Pattern, Why, Cite, Fix, Scan)
%%
%% traps.patterns()'s six-tuple, in its order, so the S1 rule
%% destructures it exactly as lint.py does. `Cite' is the FIRST cite's
%% `at' -- one line of `see:' under a finding -- and `none' where the row
%% carries no cite at all.
cl_trap_patterns([], []).
cl_trap_patterns([cl_trap(Id, _, _, Why, Fix, Pattern, Scan, Cites)|T], Out) :-
    (   Pattern == none
    ->  Out = Out1
    ;   cl_trap_cite1(Cites, At),
        Out = [pat(Id, Pattern, Why, At, Fix, Scan)|Out1]
    ),
    cl_trap_patterns(T, Out1).

cl_trap_cite1([], none).
cl_trap_cite1([cite(At, _)|_], At).
