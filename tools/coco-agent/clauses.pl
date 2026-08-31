%% cocolog -- clauses.pl: a clause reader for cocolog source, as a grammar.
%%
%% TIER: none. It is a tool, not a library. Run it:
%%
%%     COCO_CC_FILES=list.txt cocolog --local run tools/coco-agent/clauses.pl cc_dump
%%     cocolog --local run tools/coco-agent/clauses.pl "cc_heads_of('f.pl', Ks), write(Ks), nl"
%%
%% THE PUBLIC SURFACE
%%
%%     cc_split_clauses(+Codes, -Spans)        every clause, as at(Off,Line,Col,Len)
%%     cc_regions(+Codes, -Regions)            reg(Start,End,quote|comment)
%%     cc_in_region(+Regions, +Pos, +Kinds)    semidet
%%     cc_line_col(+Codes, +Offset, -Line, -Col)
%%     cc_read_head(+Codes, +Span, -Clause)    cc_clause(Span, Head, Kind)
%%     cc_clauses_of(+File, -Clauses)
%%     cc_heads_of(+File, -Keys)               the Name/Arity this file DEFINES
%%     cc_dump                                 the TSV the equivalence check reads
%%
%% WHY A GRAMMAR AND NOT A SCANNER. The Python this replaces needed TWO hand-
%% rolled scanners -- one to split clauses, one to find the quote and comment
%% regions -- and its own comment named the hazard: two scanners that disagree
%% about where a string ends is exactly the bug it was written to prevent.
%% Here they are ONE set of non-terminals. cc_quoted//1 and cc_comment//1 both
%% end a clause and ARE the regions, so a disagreement is not a bug to guard
%% against, it is a thing that cannot be written down.
%%
%% WHAT IT REFUSES TO GUESS. It is not a term parser. It splits a file into
%% clauses and reads each one's HEAD, which is all a linter needs, and it is
%% careful about exactly the four things that make that hard: quoted atoms with
%% doubled and backslash escapes, 0'c character literals, comment regions, and
%% nested argument lists. Anything past the head is left as codes.
%%
%% HONEST LIMITS. It reads BYTES, not characters: an offset is a byte offset,
%% because that is the only thing the interpreter ever reports (`syntax error
%% at offset %lu', lib/syntax.cicili:589) and a column that did not match it
%% would be worse than none. A file of UTF-8 above ASCII therefore gets byte
%% columns, which is what cocolog's own error messages give.

%% ======================================================================
%% ---- the grammar: clauses and lexical regions, one walk --------------
%% ======================================================================


%% ---------------------------------------------------------------- the walk

%% cc_scan(+Codes, -Events) -- one pass, both answers.
%%
%% An event is cl(Offset, Len) or reg(Start, End, Kind). They come out
%% interleaved in source order, which is what makes the regions sorted
%% ascending by Start for free.
cc_scan(Codes, Events) :-
    phrase(cc_source(0, 0, none, Events), Codes, []).

%% cc_source(+Pos, +Depth, +Start, -Events)//
%%
%% Pos is the offset of the next code, Depth the bracket nesting, Start the
%% offset the current clause began at or the atom `none'. Events is closed
%% off at the end of input, so the list is built in one downward pass with
%% no reversal.
cc_source(P, _, St, Es) -->
    cc_eos, !,
    { cc_scan_tail(St, P, Es) }.
cc_source(P, D, St, Es) -->
    [C],
    cc_lex(C, P, D, St, Es).

%% A TRAILING FRAGMENT WITH NO FINAL `.' IS STILL A CLAUSE, and it is never
%% blank: Start is only ever set at a non-whitespace code, so clauses.py's
%% `src[start:].strip()' test can only be true when start is set at all.
cc_scan_tail(none, _, []) :- !.
cc_scan_tail(St, P, [cl(St, Len)]) :- Len is P - St.


%% ------------------------------------------------------- one code, decided

%% cc_lex(+Code, +Pos, +Depth, +Start, -Events)//
%%
%% Pos is the offset of Code, which the caller has already consumed. Every
%% clause but the last commits, so a bound Code leaves no choice point; the
%% three guarded ones (48, 47, 46) commit only after their guard, and fall
%% through to the ordinary tail when it fails.

%% 0'c IS A CHARACTER LITERAL AND ITS QUOTE IS NOT A QUOTE. Reading it as
%% one makes the rest of the file a string.
cc_lex(48, P, D, St, Es) --> [39], !, cc_charlit(P, D, St, Es).

%% `%' TO END OF LINE. The newline is left unconsumed: it is what the next
%% step counts, and the region stops before it.
cc_lex(37, P, D, St, Es) -->
    !,
    { P1 is P + 1 },
    cc_comment_line(P1, E),
    { Es = [reg(P, E, comment)|Es1] },
    cc_source(E, D, St, Es1).

%% `/*' TO THE MATCHING `*/', or to the end of input if there is none.
cc_lex(47, P, D, St, Es) -->
    [42], !,
    { P2 is P + 2 },
    cc_comment_block(P2, E),
    { Es = [reg(P, E, comment)|Es1] },
    cc_source(E, D, St, Es1).

%% A QUOTE OPENS A CLAUSE THE WAY ANY OTHER NON-BLANK CODE DOES, which is
%% why the start is taken before the contents are skipped -- a clause that
%% begins with a quoted atom begins at the quote.
cc_lex(39, P, D, St, Es) --> !, cc_quote_at(39, P, D, St, Es).
cc_lex(34, P, D, St, Es) --> !, cc_quote_at(34, P, D, St, Es).
cc_lex(96, P, D, St, Es) --> !, cc_quote_at(96, P, D, St, Es).

%% ( [ { AGAINST ) ] }, all three pairs counted alike, because the depth is
%% only there to tell a `.' inside an argument list from one that ends a
%% clause -- and for that a bracket is a bracket.
cc_lex(40, P, D, St, Es) --> !, cc_deeper(1, 40, P, D, St, Es).
cc_lex(91, P, D, St, Es) --> !, cc_deeper(1, 91, P, D, St, Es).
cc_lex(123, P, D, St, Es) --> !, cc_deeper(1, 123, P, D, St, Es).
cc_lex(41, P, D, St, Es) --> !, cc_deeper(-1, 41, P, D, St, Es).
cc_lex(93, P, D, St, Es) --> !, cc_deeper(-1, 93, P, D, St, Es).
cc_lex(125, P, D, St, Es) --> !, cc_deeper(-1, 125, P, D, St, Es).

%% THE END OF A CLAUSE. End of input counts as the following whitespace,
%% which is what lets a file whose last clause has no newline after it be
%% read at all.
cc_lex(46, P, D, St, Es) -->
    cc_peek(N),
    { D =:= 0, cc_scan_term(N) },
    !,
    { cc_scan_start(St, 46, P, St1),
      P1 is P + 1,
      Len is P1 - St1,
      Es = [cl(St1, Len)|Es1] },
    cc_source(P1, D, none, Es1).

%% Anything else, including a `0' with no quote after it, a `/' that opens
%% no comment and a `.' at depth or mid-number.
cc_lex(C, P, D, St, Es) -->
    { cc_scan_start(St, C, P, St1), P1 is P + 1 },
    cc_source(P1, D, St1, Es).

cc_deeper(Step, C, P, D, St, Es) -->
    { cc_scan_start(St, C, P, St1), D1 is D + Step, P1 is P + 1 },
    cc_source(P1, D1, St1, Es).

cc_quote_at(Q, P, D, St, Es) -->
    { cc_scan_start(St, Q, P, St1), P1 is P + 1 },
    cc_quoted(Q, P1, E),
    { Es = [reg(P, E, quote)|Es1] },
    cc_source(E, D, St1, Es1).

%% A CLAUSE STARTS AT THE FIRST NON-BLANK CODE AFTER THE LAST ONE ENDED,
%% and never moves afterwards. Without the `none' guard a clause would
%% restart at every character in it.
cc_scan_start(none, C, P, St) :-
    !,
    (   cc_scan_space(C)
    ->  St = none
    ;   St = P
    ).
cc_scan_start(St, _, _, St).

cc_scan_space(9).
cc_scan_space(10).
cc_scan_space(11).
cc_scan_space(12).
cc_scan_space(13).
cc_scan_space(28).
cc_scan_space(29).
cc_scan_space(30).
cc_scan_space(31).
cc_scan_space(32).

cc_scan_term(none).
cc_scan_term(9).
cc_scan_term(10).
cc_scan_term(13).
cc_scan_term(32).


%% -------------------------------------------------- the lexical regions

%% cc_quoted(+Quote, +Pos, -End)//
%%
%% From just after the opening quote to just after the closing one. Three
%% things end a quoted atom and only one of them is the quote:
%%
%%   \x  a backslash escapes whatever follows, the quote included
%%   ''  a doubled quote is one quote and NOT an end
%%   '   anything else
%%
%% An unterminated quote runs to the end of input rather than failing --
%% see the header.
cc_quoted(Q, P, E) --> [92, _], !, { P2 is P + 2 }, cc_quoted(Q, P2, E).
cc_quoted(_, P, E) --> [92],    !, { E is P + 1 }.
cc_quoted(Q, P, E) --> [Q, Q],  !, { P2 is P + 2 }, cc_quoted(Q, P2, E).
cc_quoted(Q, P, E) --> [Q],     !, { E is P + 1 }.
cc_quoted(Q, P, E) --> [_],     !, { P1 is P + 1 }, cc_quoted(Q, P1, E).
cc_quoted(_, P, P) --> [].

%% cc_charlit(+Pos, +Depth, +Start, -Events)//
%%
%% Pos is the offset of the `0'; the `0' and its quote are both already
%% consumed, so what is left begins at Pos+2. 0''' and 0'\n are the two
%% that catch people, and the arithmetic is clauses.py:84-93's.
%%
%% A CHARACTER LITERAL DOES NOT START A CLAUSE. clauses.py skips it before
%% it ever reaches the line that sets `start', and so does this -- Start
%% goes through untouched.
cc_charlit(P, D, St, Es) --> [39, 39], !, cc_charlit_end(P, 4, D, St, Es).
cc_charlit(P, D, St, Es) --> [39],     !, cc_charlit_end(P, 3, D, St, Es).
cc_charlit(P, D, St, Es) --> [92, _],  !, cc_charlit_end(P, 4, D, St, Es).
cc_charlit(P, D, St, Es) --> [92],     !, cc_charlit_end(P, 3, D, St, Es).
cc_charlit(P, D, St, Es) --> [_],      !, cc_charlit_end(P, 3, D, St, Es).
cc_charlit(P, D, St, Es) --> [],          cc_charlit_end(P, 2, D, St, Es).

cc_charlit_end(P, K, D, St, Es) -->
    { E is P + K, Es = [reg(P, E, quote)|Es1] },
    cc_source(E, D, St, Es1).

%% cc_comment_line(+Pos, -End)// -- to the newline, which is NOT consumed.
cc_comment_line(P, E) --> cc_peek(10), !, { E = P }.
cc_comment_line(P, E) --> [_], !, { P1 is P + 1 }, cc_comment_line(P1, E).
cc_comment_line(P, P) --> [].

%% cc_comment_block(+Pos, -End)// -- to just after the matching `*/'.
cc_comment_block(P, E) --> [42, 47], !, { E is P + 2 }.
cc_comment_block(P, E) --> [_], !, { P1 is P + 1 }, cc_comment_block(P1, E).
cc_comment_block(P, P) --> [].

%% cc_peek(-Code)// -- the next code without consuming it, or `none' at the
%% end of input. Every lookahead in clauses.py is guarded by `i + 1 < n',
%% and `none' is that guard.
cc_peek(C, S, S) :- cc_scan_head(S, C).

cc_scan_head([], none).
cc_scan_head([C|_], C).

cc_eos([], []).


%% ------------------------------------------------------------- the answers

%% cc_split_clauses(+Codes, -Spans)
%%
%% Every clause in Codes as at(Offset, Line, Col, Len). Line and Col are
%% 1-based and computed in ONE further walk of the file rather than one per
%% clause: the offsets come out ascending, so a single cursor answers them
%% all, and a file of five hundred clauses is not five hundred rescans.
cc_split_clauses(Codes, Spans) :-
    cc_scan(Codes, Events),
    cc_scan_clauses(Events, Cls),
    cc_scan_offsets(Cls, Offs),
    cc_line_walk(Codes, 0, 1, -1, Offs, LCs),
    cc_scan_spans(Cls, LCs, Spans).

%% cc_regions(+Codes, -Regions)
%%
%% The byte ranges that are not plain code, half-open and sorted ascending
%% by Start. THE KIND MATTERS AND THAT IS WHY THEY ARE ONE LIST WITH A TAG
%% RATHER THAN TWO LISTS: a rule that reads a quote as code still must not
%% read a comment as code, and a caller that had to merge two sorted lists
%% to ask "is this position code" would be the second scanner all over
%% again.
cc_regions(Codes, Regions) :-
    cc_scan(Codes, Events),
    cc_scan_regions(Events, Regions).

cc_scan_clauses([], []).
cc_scan_clauses([cl(O, L)|Es], [cl(O, L)|Cs]) :- !, cc_scan_clauses(Es, Cs).
cc_scan_clauses([_|Es], Cs) :- cc_scan_clauses(Es, Cs).

cc_scan_regions([], []).
cc_scan_regions([reg(A, B, K)|Es], [reg(A, B, K)|Rs]) :- !,
    cc_scan_regions(Es, Rs).
cc_scan_regions([_|Es], Rs) :- cc_scan_regions(Es, Rs).

cc_scan_offsets([], []).
cc_scan_offsets([cl(O, _)|Cs], [O|Os]) :- cc_scan_offsets(Cs, Os).

cc_scan_spans([], _, []).
cc_scan_spans([cl(O, L)|Cs], [lc(Line, Col)|LCs], [at(O, Line, Col, L)|Ss]) :-
    cc_scan_spans(Cs, LCs, Ss).

%% cc_line_col(+Codes, +Offset, -Line, -Col)
%%
%% THE INTERPRETER ONLY EVER REPORTS A BYTE OFFSET -- `syntax error at
%% offset %lu' -- and there are no line numbers anywhere in the pipeline.
%% Every finding converts here so a human gets file:line:col.
cc_line_col(Codes, Offset, Line, Col) :-
    cc_line_walk(Codes, 0, 1, -1, [Offset], [lc(Line, Col)]).

%% cc_line_walk(+Codes, +Pos, +Line, +LastNL, +Offsets, -LineCols)
%%
%% Offsets must be ascending; LastNL is the offset of the last newline seen
%% or -1. Col is measured from the newline before, so the code just after
%% one is column 1.
cc_line_walk(_, _, _, _, [], []) :- !.
cc_line_walk(Cs, P, Ln, NL, [O|Os], [lc(Ln, Col)|LCs]) :-
    P =:= O,
    !,
    (   NL >= 0
    ->  Col is O - NL
    ;   Col is O + 1
    ),
    cc_line_walk(Cs, P, Ln, NL, Os, LCs).
cc_line_walk([C|Cs], P, Ln, NL, Os, LCs) :-
    !,
    (   C =:= 10
    ->  Ln1 is Ln + 1, NL1 = P
    ;   Ln1 = Ln, NL1 = NL
    ),
    P1 is P + 1,
    cc_line_walk(Cs, P1, Ln1, NL1, Os, LCs).
%% AN OFFSET PAST THE END OF THE FILE HAS NO LINE, and answering one would
%% be inventing it. The list simply stops, so a caller that asked for more
%% positions than the file has gets fewer answers back and fails to match.
cc_line_walk([], _, _, _, _, []).

%% cc_in_region(+Regions, +Pos, +Kinds) -- semidet.
%%
%% Linear, because a .pl file is small and a bisection here would be the
%% kind of cleverness that hides an off-by-one. The early exit on a region
%% that starts after Pos is what makes it linear in the ANSWER rather than
%% in the file.
cc_in_region([reg(A, B, K)|Rs], Pos, Kinds) :-
    (   Pos >= A, Pos < B
    ->  memberchk(K, Kinds)
    ;   A > Pos
    ->  fail
    ;   cc_in_region(Rs, Pos, Kinds)
    ).

%% ======================================================================
%% ---- the head reader --------------------------------------------------
%% ======================================================================

%% cc-head -- the HEAD READER for clauses.pl: one clause's text in, its
%% head and kind out.
%%
%% `cc_read_head(+Codes, +Span, -cc_clause(Span, Head, Kind))' is the whole
%% surface, with `cc_arity/2' and `cc_balanced/3' exported because the rest
%% of clauses.pl and lint.pl want them by name. It is NOT a term reader: it
%% reads far enough to answer name/arity and stops, which is all a blocklist
%% needs and all that can be done without the interpreter's own reader.
%%
%% WHAT IT REFUSES TO GUESS -- each of these was a wrong answer first:
%%
%%   A DCG HEAD OCCUPIES ARITY+2. `digit(D) --> [D].' is digit/3, because
%%   the translation appends S0 and S (lib/dcg.cicili). Reading it as
%%   digit/1 blocks a name nothing defines and lets the colliding one
%%   through -- under-broad in exactly the arity that collides. The
%%   PUSHBACK head `h, [x] --> ...' is a DCG head too.
%%
%%   A PREFIX OPERATOR TAKES ITS ARGUMENT WITHOUT PARENTHESES. `:- dynamic
%%   seen/1.' is dynamic/1, not dynamic/0. Reading it as 0 made the linter
%%   reject eight files of correct code.
%%
%%   A `Module:Head' CLAUSE IS STORED UNDER HEAD. aggregate.pl writes
%%   `sandbox:safe_meta_predicate(...)' and cocolog -- which has no module
%%   system -- stores safe_meta_predicate/1. Taking the qualifier for the
%%   name is wrong in both directions at once: it blocks `sandbox', which
%%   is free, and misses `safe_meta_predicate', which is taken. Qualifiers
%%   are stripped to a FIXED POINT, so `a:b:c' keeps the innermost head.
%%
%%   A QUOTED HEAD IS A NAME WITH ANYTHING IN IT. `'$cp_member'(X, L)' is
%%   $cp_member/2, and the doubled quote in `'it''s'' is one character, not
%%   the end of the atom.
%%
%% HONEST LIMITS. The name grammar is the Python reader's `_NAME' regex --
%% `\s*(?::-\s*)?('(?:[^']|'')*'|[a-z][a-zA-Z0-9_]*)' -- written out as a
%% DCG, so it accepts exactly what that accepted and no more: an operator
%% head (`X + Y := ...'), a head beginning with a variable, and a head
%% whose functor is written `[]' or `{}' all come back `nohead'. Inside a
%% quoted atom a backslash escape is NOT honoured by the name grammar (the
%% regex's `[^']' matches the backslash and moves on) though it IS honoured
%% by cc_balanced/3 and cc_arity/2, which follow the reader. That
%% asymmetry is the Python's, kept deliberately: two scanners that agree
%% with each other are worth more here than one that is right alone.
%%
%% WHITESPACE HERE IS THE SIX ASCII ONES -- space, tab, newline, return,
%% form feed, vertical tab. Python's `\s' over a decoded str also counts
%% NBSP and friends; nothing in this tree has one outside a comment, and a
%% reader of BYTES that guessed at Unicode classes would be guessing.
%%
%% All three entry points `must_be(list, Codes)' first. Handed a variable,
%% the layout skipper would otherwise GENERATE whitespace lists forever --
%% a hang rather than an error, from a reader whose whole job is to say
%% what is wrong with a file.

% ---- the character classes, once ---------------------------------------
% WRITTEN AS CODES rather than tested with code_type/2: `0'(' and its
% relatives are what the clause text is made of, and a name class that
% asked the C locale would drift from the regex it is reproducing.

cc_ws(32).  % space
cc_ws(9).   % tab
cc_ws(10).  % newline
cc_ws(13).  % carriage return
cc_ws(12).  % form feed
cc_ws(11).  % vertical tab

cc_open(0'().
cc_open(0'[).
cc_open(0'{).

cc_close(0')).
cc_close(0']).
cc_close(0'}).

% THE THREE QUOTES ARE ONE CLASS, as they are in the reader: an atom, a
% code list and a back-quoted list all end at their own opening character.
cc_quote(0'\').
cc_quote(0'").
cc_quote(0'`).

cc_lower(C) :- C >= 0'a, C =< 0'z.

cc_alnum(C) :- C >= 0'a, C =< 0'z.
cc_alnum(C) :- C >= 0'A, C =< 0'Z.
cc_alnum(C) :- C >= 0'0, C =< 0'9.
cc_alnum(0'_).

% ---- layout ------------------------------------------------------------
% MAX MUNCH AND COMMITTED. `\s*' is greedy and nothing that follows it in
% the name grammar is whitespace, so there is never a reason to give a
% character back -- and a choice point per space would leave one per
% character of every file.

cc_lstrip([C|T], R) :- cc_ws(C), !, cc_lstrip(T, R).
cc_lstrip(L, L).

cc_rstrip(L, R) :- reverse(L, RL), cc_lstrip(RL, RS), reverse(RS, R).

cc_strip(L, R) :- cc_lstrip(L, L1), cc_rstrip(L1, R).

cc_blank(L) :- cc_lstrip(L, []).

% ---- the name grammar --------------------------------------------------
% The regex, clause for clause. The optional `:-' is a separate clause
% rather than a disjunction because a backtracking regex tries the longer
% branch FIRST and falls back to the shorter one, which is what ordered
% clauses already do.

cc_name(Name) --> cc_lstrip, ":-", cc_lstrip, cc_name_token(Name).
cc_name(Name) --> cc_lstrip, cc_name_token(Name).

% The group INCLUDES its quotes, because the Python's `.strip("'")' runs
% over the group and stripping the quotes twice is stripping them once.
cc_name_token([0'\'|T]) --> [0'\'], cc_quoted_body(Inner), [0'\'], { append(Inner, [0'\'], T) }.
cc_name_token([C|T])    --> [C], { cc_lower(C) }, cc_name_rest(T).

% `(?:[^']|'')*', greedy: one more repetition is tried before none, and a
% plain character before the doubled quote -- which is the order a
% backtracking regex tries them in, so the FIRST solution here is the one
% the regex reports.
cc_quoted_body([C|T])       --> [C], { C =\= 0'\' }, cc_quoted_body(T).
cc_quoted_body([0'\',0'\'|T]) --> [0'\', 0'\'], cc_quoted_body(T).
cc_quoted_body([])          --> [].

cc_name_rest([C|T]) --> [C], { cc_alnum(C) }, cc_name_rest(T).
cc_name_rest([])    --> [].

%! cc_name_match(+Codes, -NameCodes, -Rest) is semidet.
%
%  ONE ANSWER, LIKE A REGEX MATCH. The grammar above is deliberately
%  backtrackable so that its first solution is the regex's; leaving the
%  choice points alive would let a caller's later failure re-enter the
%  match and read a SHORTER name, which is a bug that would only show up
%  on a quoted atom containing a quote.
cc_name_match(Codes, Name, Rest) :-
    once(cc_name(Name, Codes, Rest)).

% `'$cp_member'' -> `$cp_member'. Every leading and trailing quote goes,
% which is Python's str.strip("'") and not a one-character trim.
cc_unquote(Codes, Atom) :-
    cc_strip_quotes(Codes, C1),
    reverse(C1, R1),
    cc_strip_quotes(R1, R2),
    reverse(R2, C2),
    atom_codes(Atom, C2).

cc_strip_quotes([0'\'|T], R) :- !, cc_strip_quotes(T, R).
cc_strip_quotes(L, L).

% ---- arity -------------------------------------------------------------

%! cc_arity(+ArgCodes, -Arity) is det.
%
%  Top-level commas plus one; a blank argument list is arity 0. Quotes,
%  nesting and the 0'c literal are all counted the way the reader counts
%  them, because a comma inside `f(a, "x,y")' is not an argument boundary.
cc_arity(Codes, Arity) :-
    must_be(list, Codes),
    (   cc_blank(Codes)
    ->  Arity = 0
    ;   cc_commas(Codes, 0, 1, Arity)
    ).

%% cc_charskip(+Codes, -Taken, -Rest) is semidet.
%% CODES starts with a 0'c character literal: TAKEN is its codes and REST what
%% follows.
%%
%% THE LENGTH IS NOT ALWAYS THREE. 0'a and 0'' are three; 0''' (a doubled
%% quote) and 0'\n (a backslash escape) are four. The scanning grammar above
%% knew that -- cc_charlit//4 has all four cases -- and cc_commas/4 and
%% cc_bal/4 each carried their own copy that always took three, so
%%
%%     p([0'\',0'\'|T]) --> q.
%%
%% came out as p/1 PLAIN where the store holds p/3 DCG: the escaped quote
%% opened a quote that swallowed the argument list, cc_bal never found the
%% closing paren, and the --> was never seen. A WRONG ARITY IS THE ONE ERROR
%% THIS READER EXISTS TO PREVENT, because it turns a real collision into a
%% miss. Found by the collision oracle disagreeing with this reader and with
%% clauses.py at once -- the equivalence check between them stayed green the
%% whole time, both being wrong in the same way.
cc_charskip([0'0, 0'', 0'', 0''|T], [0'0, 0'', 0'', 0''], T) :- !.
cc_charskip([0'0, 0'', 0''|T],      [0'0, 0'', 0''],      T) :- !.
cc_charskip([0'0, 0'', 92, X|T],    [0'0, 0'', 92, X],    T) :- !.
cc_charskip([0'0, 0'', 92|T],       [0'0, 0'', 92],       T) :- !.
cc_charskip([0'0, 0'', X|T],        [0'0, 0'', X],        T) :- !.
cc_charskip([0'0, 0''],             [0'0, 0''],           []).

cc_commas([], _, N, N).
cc_commas([C|T], D, N0, N) :-
    (   cc_quote(C)
    ->  cc_commas_q(T, C, D, N0, N)
    ;   C =:= 0'0, T = [0'\'|_], cc_charskip([C|T], _, T3)
    ->  cc_commas(T3, D, N0, N)
    ;   cc_open(C)
    ->  D1 is D + 1, cc_commas(T, D1, N0, N)
    ;   cc_close(C)
    ->  D1 is D - 1, cc_commas(T, D1, N0, N)
    ;   C =:= 0',, D =:= 0
    ->  N1 is N0 + 1, cc_commas(T, D, N1, N)
    ;   cc_commas(T, D, N0, N)
    ).

% A DOUBLED QUOTE IS NOT AN END and a backslash eats what follows it.
% Running off the end inside a quote is not an error here: the scan simply
% stops, the way the reader's index does.
cc_commas_q([], _, _, N, N).
cc_commas_q([C|T], Q, D, N0, N) :-
    (   C =:= 0'\\
    ->  cc_drop(2, [C|T], T2), cc_commas_q(T2, Q, D, N0, N)
    ;   C =:= Q
    ->  (   T = [Q|_]
        ->  cc_drop(2, [C|T], T2), cc_commas_q(T2, Q, D, N0, N)
        ;   cc_commas(T, D, N0, N)
        )
    ;   cc_commas_q(T, Q, D, N0, N)
    ).

cc_drop(0, L, L) :- !.
cc_drop(_, [], []) :- !.
cc_drop(N, [_|T], R) :- N1 is N - 1, cc_drop(N1, T, R).

% ---- the balanced argument list ----------------------------------------

%! cc_balanced(+Codes, -Inside, -After) is det.
%
%  CODES STARTS WITH `('. Inside is what the matching `)' closes over,
%  After what follows it. An unbalanced list answers the tail and nothing
%  after it rather than failing, because a clause the reader will refuse is
%  still a clause the linter must report a line for.
cc_balanced(Codes, Inside, After) :-
    must_be(list, Codes),
    (   cc_bal(Codes, 0, Consumed, After0)
    ->  Consumed = [_|Inside],
        After = After0
    ;   (   Codes = [_|T]
        ->  Inside = T
        ;   Inside = []
        ),
        After = []
    ).

cc_bal([C|T], D, Cs, After) :-
    (   cc_quote(C)
    ->  Cs = [C|Cs1], cc_bal_q(T, C, D, Cs1, After)
    ;   C =:= 0'0, T = [0'\'|_], cc_charskip([C|T], Lit, T3)
    ->  append(Lit, Cs1, Cs), cc_bal(T3, D, Cs1, After)
    ;   cc_open(C)
    ->  D1 is D + 1, Cs = [C|Cs1], cc_bal(T, D1, Cs1, After)
    ;   cc_close(C)
    ->  D1 is D - 1,
        (   D1 =:= 0
        ->  Cs = [], After = T
        ;   Cs = [C|Cs1], cc_bal(T, D1, Cs1, After)
        )
    ;   Cs = [C|Cs1], cc_bal(T, D, Cs1, After)
    ).

cc_bal_q([C|T], Q, D, Cs, After) :-
    (   C =:= 0'\\
    ->  T = [X|T2], Cs = [C,X|Cs1], cc_bal_q(T2, Q, D, Cs1, After)
    ;   C =:= Q
    ->  (   T = [Q|T2]
        ->  Cs = [C,Q|Cs1], cc_bal_q(T2, Q, D, Cs1, After)
        ;   Cs = [C|Cs1], cc_bal(T, D, Cs1, After)
        )
    ;   Cs = [C|Cs1], cc_bal_q(T, Q, D, Cs1, After)
    ).

% ---- the head reader ---------------------------------------------------

%! cc_read_head(+Codes, +Span, -Clause) is det.
%
%  Clause = cc_clause(Span, Head, Kind) with Head one of head(Name, Arity)
%  or nohead, and Kind one of plain, dcg, directive(DName, DArity).
%
%  A DIRECTIVE HAS NO HEAD. `:- dynamic p/1.' defines nothing, so its Head
%  is `nohead' and what it says about `dynamic/1' lives in the Kind -- a
%  directive counted as a definition would blocklist every name any file
%  ever declared.
cc_read_head(Codes, Span, cc_clause(Span, Head, Kind)) :-
    must_be(list, Codes),
    cc_lstrip(Codes, Body),
    (   cc_directive_neck(Body, Inner0)
    ->  Head = nohead,
        cc_lstrip(Inner0, Inner),
        cc_directive_kind(Inner, Kind)
    ;   cc_strip_qualifier(Codes, Text),
        (   cc_name_match(Text, Name0, Rest)
        ->  cc_unquote(Name0, Name),
            (   Rest = [0'(|_]
            ->  cc_balanced(Rest, Args, After),
                cc_arity(Args, Arity0)
            ;   Arity0 = 0,
                After = Rest
            ),
            cc_head_kind(After, Arity0, Arity, Kind),
            Head = head(Name, Arity)
        ;   Head = nohead,
            Kind = plain
        )
    ).

% `:-' and `?-' both. A query in a file is a directive to the consulter.
cc_directive_neck([0':,0'-|T], T).
cc_directive_neck([0'?,0'-|T], T).

% A DIRECTIVE WHOSE ARGUMENT WILL NOT READ IS STILL A DIRECTIVE, and it is
% `directive(none, none)': arity `none' rather than 0, so that a caller can
% tell "no argument I could name" from a real `else/0'.
cc_directive_kind(Inner, directive(Name, Arity)) :-
    cc_name_match(Inner, Name0, Rest),
    !,
    cc_unquote(Name0, Name),
    (   Rest = [0'(|_]
    ->  cc_balanced(Rest, Args, _),
        cc_arity(Args, Arity)
    ;   % A PREFIX OPERATOR TAKES ITS ARGUMENT WITHOUT PARENTHESES, and the
        % clause's own full stop is not that argument.
        cc_strip(Rest, Tail0),
        cc_undot(Tail0, Tail1),
        (   cc_blank(Tail1)
        ->  Arity = 0
        ;   Arity = 1
        )
    ).
cc_directive_kind(_, directive(none, none)).

cc_undot(Codes, Tail) :-
    (   append(Tail0, [0'.], Codes)
    ->  Tail = Tail0
    ;   Tail = Codes
    ).

% A DCG HEAD OCCUPIES ARITY+2 -- the whole reason this file is not a regex.
cc_head_kind(After, Arity0, Arity, Kind) :-
    cc_lstrip(After, Stripped),
    (   cc_starts_with(Stripped, "-->")
    ->  Arity is Arity0 + 2, Kind = dcg
    ;   Stripped = [0',|_],
        cc_take(200, After, Window),
        cc_contains(Window, "-->")
    ->  Arity is Arity0 + 2, Kind = dcg
    ;   Arity = Arity0, Kind = plain
    ).

cc_starts_with(_, []).
cc_starts_with([C|R], [C|T]) :- cc_starts_with(R, T).

cc_contains(L, Sub) :- cc_starts_with(L, Sub), !.
cc_contains([_|T], Sub) :- cc_contains(T, Sub).

% PLAIN LIST UTILITIES, and the only names in this file another piece of
% clauses.pl is likely to want too: keep ONE definition of each when the
% pieces are joined -- consult APPENDS, so a second one is not an error.
cc_take(0, _, []) :- !.
cc_take(_, [], []) :- !.
cc_take(N, [C|T], [C|R]) :- N1 is N - 1, cc_take(N1, T, R).

% `sandbox:safe_meta_predicate(X) :- ...' -> `safe_meta_predicate(X) :- ...'.
% Only when the `:' directly follows a plain name and is not the neck; a
% term like `a:b:c' loses one qualifier per pass, so the loop runs to a
% fixed point and the store's own answer -- the innermost head -- is what
% comes out.
cc_strip_qualifier(Text, Out) :-
    (   cc_name_match(Text, _, Rest),
        Rest = [0':|R1],
        \+ R1 = [0'-|_]
    ->  cc_lstrip(R1, Text1),
        cc_strip_qualifier(Text1, Out)
    ;   Out = Text
    ).
%% ======================================================================
%% ---- the seam: a file in, its clauses out ----------------------------
%% ======================================================================

%% cc_clauses_of(+File, -Clauses) is det.
%% Every clause of FILE as cc_clause(Span, Head, Kind).
%%
%% ONE WALK OF THE CODE LIST, NOT ONE PER CLAUSE. cc_read_head/3 takes the
%% CLAUSE's codes rather than the file's -- pass it the file's and every
%% clause comes back with the first one's head, which is a seam bug worth
%% naming because both halves are individually correct. Cutting each slice
%% with cc_drop/3 from the start would then be quadratic: 95 clauses over
%% 20 KB is a million list steps for nothing. cc_slices/3 walks the list
%% once, in span order, which is the order cc_split_clauses/2 already
%% guarantees.
cc_clauses_of(File, Clauses) :-
    read_file_to_codes(File, Codes),
    cc_split_clauses(Codes, Spans),
    cc_slices(Spans, 0, Codes, Slices),
    cc_heads_from(Spans, Slices, Clauses).

cc_slices([], _, _, []).
cc_slices([at(Off, _, _, Len)|Ss], Pos, Codes, [Slice|Rest]) :-
    Skip is Off - Pos,
    cc_drop(Skip, Codes, Here),
    cc_take(Len, Here, Slice),
    Next is Off + Len,
    cc_drop(Len, Here, Tail),
    cc_slices(Ss, Next, Tail, Rest).

cc_heads_from([], [], []).
cc_heads_from([S|Ss], [Sl|Sls], [C|Cs]) :-
    cc_read_head(Sl, S, C),
    cc_heads_from(Ss, Sls, Cs).

%% cc_heads_of(+File, -Keys) is det.
%% The Name/Arity this file DEFINES -- directives excluded, duplicates gone.
%% This is the blocklist's shape-4 answer and the oracle's DECLARED set, and
%% it is the one place a DCG head's arity+2 has to be right.
cc_heads_of(File, Keys) :-
    cc_clauses_of(File, Clauses),
    findall(N/A,
            ( member(cc_clause(_, head(N, A), Kind), Clauses),
              Kind \== directive,
              \+ Kind = directive(_, _) ),
            Keys0),
    sort(Keys0, Keys).

%% ======================================================================
%% ---- cc_dump: the equivalence gate's input ---------------------------
%% ======================================================================

%% cc_dump is det.
%% One tab-separated row per clause, for tools/coco-agent/equiv.sh to diff
%% against clauses.py over every .pl this repository owns.
%%
%% THE FILE LIST COMES THROUGH THE ENVIRONMENT, not a goal term. cocolog has
%% no argv -- current_prolog_flag/2 answers `executable' and nothing else --
%% so the alternative is a goal the shell has to quote, and a path with a
%% space in it breaks that. getenv/2 is tier 1 and does not care.
cc_dump :-
    getenv('COCO_CC_FILES', ListFile),
    read_file_to_codes(ListFile, Codes),
    cc_lines(Codes, Files),
    forall(member(F, Files), cc_dump_file(F)).

cc_dump_file(F) :-
    atom_codes(FA, F),
    cc_clauses_of(FA, Clauses),
    forall(member(C, Clauses), cc_dump_row(FA, C)).

cc_dump_row(F, cc_clause(at(O, L, Col, Len), Head, Kind)) :-
    cc_dump_head(Head, Name, Arity),
    cc_dump_kind(Kind, KA),
    format("~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w~n", [F, O, L, Col, Len, Name, Arity, KA]).

%% A DIRECTIVE HAS NO HEAD, and clauses.py agrees: read_head returns before
%% it fills name or arity, so both print as absent. The `-' and the -1 are
%% clauses.py's own renderings, matched here so the diff is byte-for-byte.
cc_dump_head(head(N, A), N, A) :- !.
cc_dump_head(nohead, '-', -1).

cc_dump_kind(directive(N, A), K) :- !, format(atom(K), "directive(~w,~w)", [N, A]).
cc_dump_kind(K, K).

%% cc_lines(+Codes, -Lines) is det.
%% Split on newlines, dropping the empty trailing line a text file ends with.
%% Written out rather than taken from library(text)'s codes_lines/2 because
%% this file is TIER-NOTHING: it is a tool, and a tool that needs a tier-2
%% library on the path to read its own argument list is one more thing to
%% get wrong on somebody else's machine.
cc_lines([], []) :- !.
cc_lines(Codes, Lines) :-
    cc_lines_(Codes, [], Lines).

cc_lines_([], Acc, Out) :-
    !,
    ( Acc == [] -> Out = [] ; reverse(Acc, L), Out = [L] ).
cc_lines_([10|T], Acc, [L|Rest]) :-
    !,
    reverse(Acc, L),
    cc_lines_(T, [], Rest).
cc_lines_([C|T], Acc, Out) :-
    cc_lines_(T, [C|Acc], Out).
