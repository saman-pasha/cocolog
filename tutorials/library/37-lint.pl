%% cocolog tutorial 37 -- cocolint: the dialect linter, and why it is clauses.
%%
%% TIER: none. cocolint is a TOOL, not a library, so there is no
%% `use_module(library(lint))'. It lives in tools/coco-agent and you run it:
%%
%%     sh tools/coco-agent/lint.sh myprogram.pl
%%
%% This lesson loads its two halves directly, which is what `use_module' on a
%% plain path is for:
%%
%%     :- use_module('tools/coco-agent/clauses.pl').   the clause reader
%%     :- use_module('tools/coco-agent/lint.pl').      the rules
%%
%% WHAT IT IS FOR. cocolog is close enough to SWI that your instincts will
%% compile, and far enough that they will be wrong. Every rule cocolint has
%% exists because the failure it catches is SILENT or nearly so -- a loud
%% failure needs no linter, because the interpreter already names it. A
%% program that calls `halt' at the end of main exits 1 with nothing on
%% stderr; one that defines `step/4' merges its clauses into a library's; one
%% that writes `format(string(S), ...)' has asked for a type that does not
%% exist. None of the three says so.
%%
%% WHAT THIS LESSON CLAIMS. Nine sections, every claim a must/3:
%%
%%     1  a clause reader is a GRAMMAR, and why a regex will not do
%%     2  the four things that make reading a head hard
%%     3  regions: what is code and what is not
%%     4  the rules are CLAUSES you can query
%%     5  S1's patterns are TERMS, not regexes
%%     6  a term answers WHERE, which is the whole of a finding
%%     7  the negative lookahead POSIX has no form for
%%     8  the dialect card is DATA, with its citations checked
%%     9  running it for real
%%
%% IT NEEDS NO GENERATED FILE. clauses.pl, lint.pl and traps.jsonl are all
%% committed; the blocklist the collision rules consult is not, and section 9
%% says how to make one rather than pretending it is there.

:- use_module('tools/coco-agent/clauses.pl').
:- use_module('tools/coco-agent/lint.pl').
:- use_module(library(json)).

%% ---- a small helper, so each claim reads as one line ------------------
%% The reader answers a SPAN and the head reader wants the clause's own
%% codes, so this cuts one out. cc_read_head/3 takes the CLAUSE's codes and
%% not the file's -- hand it the file's and every clause comes back with the
%% first one's head, which is a seam worth knowing about.
t37_read(Codes, Clause) :-
    cc_split_clauses(Codes, [Span]),
    Span = at(_, _, _, Len),
    cc_take(Len, Codes, Slice),
    cc_read_head(Slice, Span, Clause).

main :-
    t37_reader,
    t37_head,
    t37_regions,
    t37_rules,
    t37_patterns,
    t37_where,
    t37_lookahead,
    t37_card,
    t37_running,
    format("~ndone~n").

t37_reader :-
    format("~n-- 1. a clause reader is a GRAMMAR~n"),
    format("   clauses.py needed two hand-rolled scanners for this: one to~n"),
    format("   split clauses, one to find the quote and comment regions. Its~n"),
    format("   own comment named the hazard -- two scanners that disagree~n"),
    format("   about where a string ends. Here they are the same~n"),
    format("   non-terminals, so the disagreement cannot be written down.~n"),
    cc_split_clauses("foo(a).\nbar :- baz.\n", Spans),
    must('two clauses, with their offsets', Spans,
         [at(0, 1, 1, 7), at(8, 2, 1, 11)]),

    true.

t37_head :-
    format("~n-- 2. A DCG HEAD OCCUPIES ARITY+2~n"),
    format("   This is the whole reason a regex over heads will not do. A~n"),
    format("   regex answers digit/1; what the store holds is digit/3,~n"),
    format("   because lib/dcg.cicili appends S0 and S. A blocklist built~n"),
    format("   from the regex is under-broad IN EXACTLY THE ARITY THAT~n"),
    format("   COLLIDES: it blocks a name nothing defines and lets the real~n"),
    format("   one through.~n"),
    t37_read("digit(D) --> [D].", Dcg),
    must('digit//1 is digit/3', Dcg,
         cc_clause(at(0, 1, 1, 17), head(digit, 3), dcg)),

    format("~n   A PREFIX OPERATOR TAKES ITS ARGUMENT WITHOUT PARENTHESES.~n"),
    format("   `:- dynamic seen/1.' is dynamic/1, not dynamic/0. Reading it~n"),
    format("   as arity 0 once made the linter reject eight files of~n"),
    format("   perfectly correct code.~n"),
    t37_read(":- dynamic seen/1.", Dir),
    must('the directive is dynamic/1', Dir,
         cc_clause(at(0, 1, 1, 18), nohead, directive(dynamic, 1))),

    format("~n   A Module:Head CLAUSE IS STORED UNDER HEAD. cocolog has no~n"),
    format("   module system, so the qualifier is dropped rather than~n"),
    format("   meaning anything -- verified against the binary, not read off~n"),
    format("   the source. Reading the qualifier as the name was wrong in~n"),
    format("   BOTH directions: it blocked `sandbox', which is free, and~n"),
    format("   missed `safe_meta_predicate', which is taken.~n"),
    t37_read("mod:head(X) :- q(X).", Qual),
    must('the qualifier is stripped', Qual,
         cc_clause(at(0, 1, 1, 20), head(head, 1), plain)),

    format("~n   A 0'c LITERAL IS NOT ALWAYS THREE CHARACTERS. 0'a and 0''~n"),
    format("   are three; 0''' and 0'\\n are four. Assuming three made the~n"),
    format("   escaped quote below open a quote that swallowed the argument~n"),
    format("   list, so this clause read as p/1 PLAIN where the store holds~n"),
    format("   p/3 DCG -- and a WRONG ARITY is the one error a clause reader~n"),
    format("   exists to prevent, because it turns a real collision into a~n"),
    format("   miss.~n"),
    t37_read("p([0'\\',0'\\'|T]) --> [].", Esc),
    must('the escaped quote does not eat the head', Esc,
         cc_clause(at(0, 1, 1, 24), head(p, 3), dcg)),

    true.

t37_regions :-
    format("~n-- 3. REGIONS: what is code and what is not~n"),
    format("   A `.' inside a quoted atom does not end a clause, and a name~n"),
    format("   inside a comment is not a definition. Without the second,~n"),
    format("   yall.pl's /** <module> */ header contributes a bogus~n"),
    format("   call/1..4 to the blocklist.~n"),
    t37_read("q('a. b', 2).", Dotted),
    must('a `.` inside a quote is not the end', Dotted,
         cc_clause(at(0, 1, 1, 13), head(q, 2), plain)),
    cc_regions("p('x'). % hi", Regions),
    must('the quote and the comment, as byte ranges', Regions,
         [reg(2, 5, quote), reg(8, 12, comment)]),
    ( cc_in_region(Regions, 3, [quote]) -> InQ = yes ; InQ = no ),
    must('offset 3 is inside the quoted atom', InQ, yes),
    ( cc_in_region(Regions, 1, [quote, comment]) -> InC = yes ; InC = no ),
    must('offset 1 is code', InC, no),

    true.

t37_rules :-
    format("~n-- 4. THE RULES ARE CLAUSES YOU CAN QUERY~n"),
    format("   That is the argument for writing a linter in this language at~n"),
    format("   all: a rule IS a clause -- a head that names it and a body~n"),
    format("   that says when it fires -- and the tables it reads are facts~n"),
    format("   somebody can list and argue with.~n"),
    findall(D, cl_directive(D, _), Ds0),
    sort(Ds0, Ds),
    length(Ds, NDirectives),
    must('the accepted directive names', NDirectives, 14),
    ( cl_directive(dynamic, 1) -> Dyn = accepted ; Dyn = refused ),
    must('dynamic/1 is a directive', Dyn, accepted),
    ( cl_directive(initialization, 1) -> Init = accepted ; Init = refused ),
    must('initialization/1 is not', Init, refused),
    format("   ...and THAT is rule D1, which is HARD because an unsupported~n"),
    format("   directive does not get ignored: it ABORTS THE WHOLE CONSULT.~n"),
    format("   The file loads nothing and cocolog exits 1.~n"),
    cl_severity(d1, SevD1),
    must('D1 is hard', SevD1, hard),

    true.

t37_patterns :-
    format("~n-- 5. S1's PATTERNS ARE TERMS, NOT REGEXES~n"),
    format("   library(text) does bind a POSIX engine, and porting the~n"),
    format("   seventeen banned forms to it loses six things, THREE OF THEM~n"),
    format("   SILENTLY: \\d becomes a literal `d'; a lazy .*? compiles and~n"),
    format("   is greedy; lookaround fails with no error; [^\\n] reads as~n"),
    format("   \"not backslash, not n\"; a pattern regcomp REJECTS looks~n"),
    format("   exactly like one that missed; and there are no flags.~n"),
    ( cl_match(seq([lit(format), ws, lit('('), ws, lit(string)]),
               "x :- format(string(S), a, b).", OffS, _)
    -> true ; OffS = none ),
    must('format(string(S)) found, at its offset', OffS, 5),

    true.

t37_where :-
    format("~n-- 6. A TERM ANSWERS *WHERE*, which a regex binding here~n"),
    format("   cannot: re_match/2 says yes or no and re_first/3 says WHAT~n"),
    format("   matched, and nothing says where. Every cocolint finding is a~n"),
    format("   file:line:col, so that is not a detail.~n"),
    findall(O, cl_match(lit(ab), "ab_ab_ab", O, _), Offsets),
    must('every match, in order', Offsets, [0, 3, 6]),

    format("~n   A WORD BOUNDARY IS A CHANGE, not a character. `halt' fires;~n"),
    format("   `ahalt' and `halted' do not, which is exactly what rule H1~n"),
    format("   needs -- halt/0 makes a proof report NO SOLUTION and the~n"),
    format("   process exit 1 with nothing on stderr.~n"),
    ( cl_match(seq([bstart, lit(halt), bend]), "x halt y", OffH, _)
    -> true ; OffH = none ),
    must('halt, at a boundary', OffH, 2),
    ( cl_match(seq([bstart, lit(halt), bend]), "ahalt halted", _, _)
    -> Bounded = fired ; Bounded = quiet ),
    must('neither ahalt nor halted', Bounded, quiet),

    true.

t37_lookahead :-
    format("~n-- 7. THE NEGATIVE LOOKAHEAD POSIX HAS NO FORM FOR~n"),
    format("   Rule P1: exactly one prolog flag answers here, and it is~n"),
    format("   `executable'. Every portability shim written against~n"),
    format("   current_prolog_flag/2 therefore takes the wrong branch,~n"),
    format("   silently. The rule has to fire on every flag BUT that one.~n"),
    format("   In a DCG the lookahead is \\+, one word; in POSIX it does not~n"),
    format("   exist and a port of it fails without saying so.~n"),
    ( cl_match(seq([lit(current_prolog_flag), ws, lit('('), ws,
                    notword(executable), oneof(abcdefghijklmnopqrstuvwxyz_)]),
               "p :- current_prolog_flag(bounded, B).", OffP, _)
    -> true ; OffP = none ),
    must('bounded is flagged', OffP, 5),
    ( cl_match(seq([lit(current_prolog_flag), ws, lit('('), ws,
                    notword(executable), oneof(abcdefghijklmnopqrstuvwxyz_)]),
               "p :- current_prolog_flag(executable, P).", _, _)
    -> Exec = flagged ; Exec = quiet ),
    must('executable is not', Exec, quiet),

    true.

t37_card :-
    format("~n-- 8. THE DIALECT CARD IS DATA, and its citations are CHECKED~n"),
    format("   tools/coco-agent/traps.jsonl is the card as rows. Each one~n"),
    format("   carries the source it is claiming something about, and an~n"),
    format("   ANCHOR -- a literal substring that must appear in the cited~n"),
    format("   lines. A citation nobody checks is a citation that rots: a~n"),
    format("   line number moves and the row goes on asserting a fact about~n"),
    format("   code that is no longer there.~n"),
    read_file_to_codes('tools/coco-agent/traps.jsonl', TrapCodes),
    t37_rows(TrapCodes, Rows),
    length(Rows, NRows),
    must('rows in the card', NRows, 36),
    findall(Id, ( member(R, Rows), t37_field(R, id, Id) ), Ids),
    sort(Ids, SortedIds),
    length(SortedIds, NIds),
    must('every id distinct', NIds, 36),
    findall(P, ( member(R, Rows), t37_field(R, pattern, P) ), Pats),
    length(Pats, NPats),
    must('rows carrying an S1 pattern term', NPats, 17),
    findall(x, ( member(R, Rows), t37_field(R, cite, Cites), Cites == [] ), NoCite),
    must('rows with no citation at all', NoCite, []),

    true.

t37_running :-
    format("~n-- 9. RUNNING IT FOR REAL~n"),
    format("   This lesson loaded the reader and the rules and called them~n"),
    format("   directly, which needs nothing generated. The COLLISION rules~n"),
    format("   -- N1, N2, N3 -- need a blocklist extracted from this~n"),
    format("   checkout, and lint.sh makes one for you:~n"),
    format("~n       sh tools/coco-agent/lint.sh myprogram.pl~n~n"),
    format("   It exits 1 if there is a HARD finding, which is how a cocolog~n"),
    format("   program sets an exit code at all: `cocolog run FILE GOAL'~n"),
    format("   exits 1 when the goal FAILS, so cl_lint/1 simply fails. No~n"),
    format("   halt is involved, and could not be -- see section 6.~n"),
    ( exists_file('tools/coco-agent/blocklist.pl') -> Index = built ; Index = absent ),
    show('the generated blocklist is', Index),
    (   Index == built
    ->  format("   It is here, so the collision rules would run.~n")
    ;   format("   It is not here. That is not a failure: it is generated,~n"),
        format("   it is gitignored, and lint.sh builds it on first use.~n")
    ),

    format("~n-- what this lesson did NOT do~n"),
    format("   It never ran your program. cocolint reads source and a~n"),
    format("   blocklist; it does not prove a goal, and it says nothing~n"),
    format("   about a name it has no evidence for. The other half is the~n"),
    format("   collision ORACLE in oracle.pl, which asks the running store~n"),
    format("   instead -- and catches what a blocklist cannot. Neither~n"),
    format("   mechanism is sound alone: measured, the oracle misses 110 of~n"),
    format("   112 C-dispatched names, because redefining one is dead code~n"),
    format("   the store still calls yours.~n").

%% ---- reading the card ------------------------------------------------
%%
%% JSON LINES: one document per line, so the file is split first and each
%% line parsed on its own. ONCE/1 IS NOT OPTIONAL AROUND json_parse/2: it is
%% documented `is det' and is not -- any document containing true, false or
%% null leaves a choice point whose second solution THROWS -- so a findall
%% over it without once/1 throws rather than answering.
t37_rows([], []) :- !.
t37_rows(Codes, Rows) :-
    t37_lines(Codes, Lines),
    findall(T, ( member(L, Lines), L \== [], once(json_parse(L, T)) ), Rows).

t37_lines([], []) :- !.
t37_lines(Codes, Lines) :- t37_lines_(Codes, [], Lines).
t37_lines_([], Acc, Out) :-
    !, ( Acc == [] -> Out = [] ; reverse(Acc, L), Out = [L] ).
t37_lines_([10|T], Acc, [L|Rest]) :-
    !, reverse(Acc, L), t37_lines_(T, [], Rest).
t37_lines_([C|T], Acc, Out) :- t37_lines_(T, [C|Acc], Out).

%% library(json) answers an object as json(Pairs), and a pair as Key-Value.
t37_field(json(Pairs), Key, Value) :- memberchk(Key-Value, Pairs).

%% ---- the two helpers every lesson repeats ----------------------------
%% Duplicated at the foot of every tutorial on purpose: one you can copy
%% anywhere and run is worth six repeated lines, and one that needs a support
%% file beside it stops working the moment it moves.

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
