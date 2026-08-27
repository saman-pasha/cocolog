%% library(json) -- a Prolog term as JSON text.
%%
%% EVERY PREDICATE IS `json_'-PREFIXED, helpers and nonterminals included,
%% for the reason library(http) spells out at length: cocolog has ONE
%% namespace, a library's private names are everybody's, and the first
%% clash is silent. There is no `escape//1' in here and there never will
%% be; there is `json_escape//1'.
%%
%% IT IS ALL CLAUSES, and a DCG at that. Serialising is the mirror of
%% parsing and it is what Prolog is for -- a grammar that emits is the
%% format written down, readable a clause at a time. There is no C in this
%% file and there should never be any.
%%
%% IT ANSWERS CODES, NOT AN ATOM. An atom in cocolog is a C string and
%% stops at the first NUL, and while well-formed JSON never contains one
%% (a NUL byte in a string is escaped `\u0000' below), the codes are the
%% honest unit: they are what `tcp_write/2' wants, what library(http)
%% hands around, and what concatenates without a round trip. `json_atom/2'
%% is there for when an atom is genuinely what you have to produce.
%%
%% ---- WHAT MAPS TO WHAT ------------------------------------------------
%%
%%     json([Key-Value, ...])      an object. `Key=Value' and `Key:Value'
%%                                 are accepted too, because all three are
%%                                 idiomatic and the pair's own functor
%%                                 says which one you wrote. Key order is
%%                                 PRESERVED: JSON objects are unordered
%%                                 by the spec and diffs are not.
%%     [E1, E2, ...]               an array
%%     @(true) @(false) @(null)    the three literals, SWI's spelling
%%     a number                    a number
%%     an atom                     a string
%%     str(X)                      a string, from an atom, a number or a
%%                                 CODE LIST -- see the next paragraph
%%
%% `str/1' EXISTS BECAUSE A CODE LIST IS A LIST. cocolog has no string
%% type: `double_quotes' is `codes', so `"hi"' IS `[104,105]' and there is
%% nothing in the term to tell a serialiser which you meant. Guessing --
%% "a list of small integers is probably text" -- is how a JSON array of
%% byte values silently becomes a word. So a bare list is ALWAYS an array,
%% and `str("hi")' is how you say you meant the other thing. The
%% alternative, `atom_codes(A, "hi")' first, works just as well and needs
%% no vocabulary; `str/1' is the shorthand, not a second mechanism.
%%
%% ---- WHERE IT IS STRICT, each a decision rather than an omission ------
%%
%%   AN UNBOUND VARIABLE IS AN ERROR, not `null'. A term with a hole in it
%%   is a term you have not finished building, and answering `null' for it
%%   turns a bug into a document.
%%
%%   A TERM IT CANNOT WRITE IS AN ERROR, not a best effort. `foo(1)' has no
%%   JSON meaning; `type_error(json_term, foo(1))' says so at the call site
%%   rather than emitting `"foo(1)"' and letting the far end discover it.
%%
%%   `@(foo)' IS AN ERROR. The three literals are the three literals. A
%%   fourth would be a bare word in the output and no JSON parser accepts
%%   one.
%%
%%   AN INFINITE OR NOT-A-NUMBER FLOAT IS AN ERROR. JSON has no spelling
%%   for either -- `Infinity' is not in the grammar -- so the check is that
%%   every code of the written number is one of `0-9 - + . e E'. Anything
%%   with a letter in it (`inf', `nan', `1.0Inf') fails that and throws,
%%   which is better than emitting a token that parses nowhere.
%%
%%   BYTES ABOVE 0x7F PASS THROUGH UNTOUCHED. cocolog is byte-oriented:
%%   codes are bytes and there is no decoder in this file. So UTF-8 in is
%%   UTF-8 out, which is what JSON wants -- RFC 8259 says the default
%%   encoding is UTF-8 -- and the `\uXXXX' escapes are used only where the
%%   spec REQUIRES them, on the C0 controls. A serialiser that escaped
%%   non-ASCII would have to decode UTF-8 to do it, and would corrupt
%%   anything that was not UTF-8 in the first place.
%%
%%   THE SOLIDUS IS NOT ESCAPED. `\/' is legal and pointless; `</script>'
%%   inside a JSON string embedded in HTML is a problem for whoever does
%%   that embedding, and library(html) refuses it there, where it is
%%   actually a hazard.
%%
%% ---- OPTIONS ---------------------------------------------------------
%%
%%     indent(N)   N spaces per level, newline between members. Absent or
%%                 0 means COMPACT -- no space anywhere -- which is the
%%                 default because the common caller is a wire.

:- use_module(library(lists)).

%% ---- the entry points ------------------------------------------------

%% json_codes(+Term, -Codes) is det.
json_codes(Term, Codes) :- json_codes(Term, Codes, []).

%% json_codes(+Term, -Codes, +Options) is det.
json_codes(Term, Codes, Options) :-
    json_step(Options, Step),
    phrase(json_emit(Term, Step, 0), Codes).

%% json_atom(+Term, -Atom) is det.
json_atom(Term, Atom) :- json_atom(Term, Atom, []).

json_atom(Term, Atom, Options) :-
    json_codes(Term, Codes, Options),
    atom_codes(Atom, Codes).

%% json_write(+Term) is det.
%% Straight to the current output, and through `~s' rather than an atom:
%% no round trip, and nothing to truncate on a byte an atom could not hold.
json_write(Term) :- json_write(Term, []).

json_write(Term, Options) :-
    json_codes(Term, Codes, Options),
    format("~s", [Codes]).

%% json_value(+Term)// is det.
%% The nonterminal, for a caller already building codes with a grammar of
%% its own. Compact: a document being assembled has no level to indent to.
json_value(Term) --> json_emit(Term, 0, 0).

json_step(Options, Step) :-
    (   memberchk(indent(N), Options),
        integer(N),
        N > 0
    ->  Step = N
    ;   Step = 0
    ).

%% ---- one value -------------------------------------------------------
%%
%% ORDER IS THE DISPATCH and the cuts make it one. `json(...)' is checked
%% before `compound', `[]' before `[H|T]', and the atom clause last of the
%% ones that can succeed -- so `[]' is the empty ARRAY and never the atom
%% `[]', which is what every other Prolog JSON library also decides and
%% none of them writes down.

json_emit(V, _, _) --> { var(V) }, !,
    { throw(error(instantiation_error, json_codes/2)) }.
json_emit(@(X), _, _) --> { json_literal(X) }, !, { atom_codes(X, Cs) }, json_raw(Cs).
json_emit(str(X), _, _) --> !, json_string(X).
json_emit(json(Pairs), Step, Depth) --> !, json_object(Pairs, Step, Depth).
json_emit(N, _, _) --> { number(N) }, !, json_number(N).
json_emit([], _, _) --> !, "[]".
json_emit([H|T], Step, Depth) --> !, json_array([H|T], Step, Depth).
json_emit(A, _, _) --> { atom(A) }, !, json_string(A).
json_emit(T, _, _) --> { throw(error(type_error(json_term, T), json_codes/2)) }.

json_literal(true).
json_literal(false).
json_literal(null).

%% ---- objects and arrays ----------------------------------------------
%%
%% AN EMPTY OBJECT AND AN EMPTY ARRAY ARE WRITTEN FLAT, `{}' and `[]',
%% whatever the indent. There is nothing to put on a line of its own, and
%% an indenter that opens a brace and closes it two lines later over
%% nothing is one nobody reads twice.

json_object([], _, _) --> !, "{}".
json_object(Pairs, Step, Depth) -->
    "{", { Deeper is Depth + 1 },
    json_members(Pairs, Step, Deeper),
    json_break(Step, Depth), "}".

json_members([], _, _) --> [].
json_members([P|Ps], Step, Depth) -->
    json_break(Step, Depth),
    json_member(P, Step, Depth),
    json_more_members(Ps, Step, Depth).

json_more_members([], _, _) --> [].
json_more_members([P|Ps], Step, Depth) -->
    ",", json_break(Step, Depth),
    json_member(P, Step, Depth),
    json_more_members(Ps, Step, Depth).

%% THE THREE PAIR SPELLINGS, and no fourth. A member that is none of them
%% is an error naming the member, because the usual cause is a list that
%% was meant to be an array handed to `json/1' by mistake, and `the second
%% element of your object is not a pair' is the sentence that finds it.
json_member(Key-Value, Step, Depth) --> !, json_pair(Key, Value, Step, Depth).
json_member(Key=Value, Step, Depth) --> !, json_pair(Key, Value, Step, Depth).
json_member(Key:Value, Step, Depth) --> !, json_pair(Key, Value, Step, Depth).
json_member(P, _, _) --> { throw(error(type_error(json_pair, P), json_codes/2)) }.

json_pair(Key, Value, Step, Depth) -->
    json_string(Key), ":", json_space(Step),
    json_emit(Value, Step, Depth).

json_array([], _, _) --> !, "[]".
json_array(Items, Step, Depth) -->
    "[", { Deeper is Depth + 1 },
    json_items(Items, Step, Deeper),
    json_break(Step, Depth), "]".

json_items([], _, _) --> [].
json_items([I|Is], Step, Depth) -->
    json_break(Step, Depth),
    json_emit(I, Step, Depth),
    json_more_items(Is, Step, Depth).

json_more_items([], _, _) --> [].
json_more_items([I|Is], Step, Depth) -->
    ",", json_break(Step, Depth),
    json_emit(I, Step, Depth),
    json_more_items(Is, Step, Depth).

%% ---- what indenting is -----------------------------------------------
%%
%% TWO NONTERMINALS AND THE COMPACT CASE IS `[]'. A step of 0 emits
%% nothing at all from either, so the compact path costs one integer
%% comparison per token and no special-casing anywhere above.

json_break(0, _) --> !, [].
json_break(Step, Depth) --> "\n", { Wide is Step * Depth }, json_spaces(Wide).

json_space(0) --> !, [].
json_space(_) --> " ".

json_spaces(N) --> { N =< 0 }, !, [].
json_spaces(N) --> " ", { M is N - 1 }, json_spaces(M).

%% ---- numbers ---------------------------------------------------------

json_number(N) -->
    { number_codes(N, Cs), json_finite(Cs, N) },
    json_raw(Cs).

json_finite([], _).
json_finite([C|Cs], N) :-
    (   json_number_code(C)
    ->  json_finite(Cs, N)
    ;   throw(error(type_error(json_number, N), json_codes/2))
    ).

json_number_code(C) :- code_type(C, digit), !.
json_number_code(0'-).
json_number_code(0'+).
json_number_code(0'.).
json_number_code(0'e).
json_number_code(0'E).

%% ---- strings ---------------------------------------------------------

json_string(X) -->
    { json_text_codes(X, Cs) },
    [0'"], json_escaped(Cs), [0'"].

json_text_codes(A, Cs) :- atom(A), !, atom_codes(A, Cs).
json_text_codes(N, Cs) :- number(N), !, number_codes(N, Cs).
json_text_codes(str(X), Cs) :- !, json_text_codes(X, Cs).
json_text_codes(Cs, Cs) :- is_list(Cs), !.
json_text_codes(X, _) :- throw(error(type_error(json_text, X), json_codes/2)).

json_escaped([]) --> [].
json_escaped([C|Cs]) --> json_escape(C), json_escaped(Cs).

%% THE SIX NAMED ESCAPES, then the C0 controls as `\u00XX', then the byte
%% itself. RFC 8259 requires escaping exactly `"', `\' and U+0000-U+001F;
%% everything else here is either the shorter spelling of one of those or
%% left alone on purpose.
json_escape(0'") --> !, [0'\\, 0'"].
json_escape(0'\\) --> !, [0'\\, 0'\\].
json_escape(0'\b) --> !, [0'\\, 0'b].
json_escape(0'\f) --> !, [0'\\, 0'f].
json_escape(0'\n) --> !, [0'\\, 0'n].
json_escape(0'\r) --> !, [0'\\, 0'r].
json_escape(0'\t) --> !, [0'\\, 0't].
json_escape(C) --> { C < 0x20 }, !, json_u_escape(C).
json_escape(C) --> [C].

json_u_escape(C) -->
    { High is (C >> 4) /\ 0xF, Low is C /\ 0xF,
      json_hex_digit(High, H), json_hex_digit(Low, L) },
    [0'\\, 0'u, 0'0, 0'0, H, L].

json_hex_digit(N, C) :- N < 10, !, C is 0'0 + N.
json_hex_digit(N, C) :- C is 0'a + N - 10.

%% ---- a code list, verbatim -------------------------------------------
%%
%% A BODY ITEM THAT IS A VARIABLE IS A CALL, not a literal. `--> Cs' with
%% Cs bound to a list translates to `phrase(Cs, S0, S)', which is a call to
%% a predicate named after the first element and not the emission anybody
%% meant. This walks it instead, which is the only correct way to put a
%% computed list into a DCG body.
json_raw([]) --> [].
json_raw([C|Cs]) --> [C], json_raw(Cs).

%% ======================================================================
%% ---- READING: JSON text as a Prolog term -----------------------------
%% ======================================================================
%%
%% THE INVERSE OF EVERYTHING ABOVE, and deliberately the same term. What
%% `json_codes/2' writes, `json_parse/2' reads back; what `json_parse/2'
%% answers, `json_codes/2' writes out again. `test/serialize.sh' checks
%% that in both directions, because a pair of these that disagree is worse
%% than either one alone.
%%
%%     json_parse(+Text, -Term)          Text is codes OR an atom
%%     json_parse(+Codes, -Term, -Rest)  Rest is what was not this value
%%     json_input(-Term)//               the nonterminal, for a grammar
%%                                       that has JSON inside it
%%
%% `json_parse/3' IS THE STREAMING ONE, and the reason is library(http)'s:
%% a socket hands you what arrived, which may be one value and the start of
%% the next. `json_parse/2' requires the whole input to be one value and
%% says so if it is not.
%%
%% ---- IT IS RFC 8259, INCLUDING THE PARTS PEOPLE LEAVE OUT -------------
%%
%%   A LEADING ZERO IS NOT A NUMBER. `01' is two tokens to this grammar,
%%   and the parser says so rather than answering 1. Same for `+1', `.5'
%%   and `5.' -- none of them is in the grammar, all of them are accepted
%%   by parsers written from memory, and every one of them is a place
%%   where two implementations disagree about the same bytes.
%%
%%   AN INTEGER TOO BIG FOR THE MACHINE IS AN ERROR. cocolog's integers
%%   are 64-bit and `number_codes/2' answers -1 for a twenty-digit
%%   literal without complaining, so the digits are written back and
%%   compared. A silently wrong balance is the worst thing a JSON parser
%%   can do.
%%
%%   `\uXXXX' IS DECODED TO UTF-8, surrogate pairs included, because this
%%   library is byte-oriented everywhere else: the serialiser passes UTF-8
%%   through untouched, so the parser has to produce it. A LONE surrogate
%%   is an error -- there is no byte sequence that means half a character.
%%
%%   A NUL IS AN ERROR, whether it arrives as an escape or a raw byte, and
%%   it is the one place the round trip is not total. An atom in cocolog is
%%   a C string, so a NUL truncates it: the parser would answer a shorter
%%   atom than the document contained and nothing would say so. Refusing is
%%   the only honest option, and the serialiser can still WRITE a NUL that
%%   arrived some other way.
%%
%%   DUPLICATE KEYS ARE ALL KEPT, in the order they appeared. RFC 8259
%%   says the behaviour is undefined; a list of pairs is what this library
%%   already uses, and it is the only answer that loses nothing.
%%
%% ---- WHAT COMES BACK -------------------------------------------------
%%
%%     an object    json([Key-Value, ...])   keys are atoms, `-' pairs
%%     an array     a list
%%     a string     an ATOM -- which is the inverse of the writer's rule
%%     a number     an integer or a float
%%     the literals @(true), @(false), @(null)
%%
%% A STRING COMES BACK AS AN ATOM AND NOT AS CODES, so `json_parse' then
%% `json_codes' is the document again. It also means an empty string is
%% the atom `'' ' and not `[]', which is exactly the distinction the
%% writer needs in order to tell a string from an array.
%%
%% ---- WHEN IT WILL NOT PARSE ------------------------------------------
%%
%% It THROWS, and the ball carries where:
%%
%%     error(syntax_error(What), json_at(Snippet))
%%
%% `What' is what was expected and `Snippet' is the first forty bytes that
%% were there instead, as an atom. A parser that only fails tells you a
%% document is bad; this tells you where, which is the difference between
%% a minute and an afternoon on a document nobody wrote by hand.

%% ---- the entry points ------------------------------------------------

%% json_parse(+Text, -Term) is det.
json_parse(Text, Term) :-
    json_in_codes(Text, Cs),
    phrase(json_only(Term), Cs).

%% json_parse(+Codes, -Term, -Rest) is det.
json_parse(Text, Term, Rest) :-
    json_in_codes(Text, Cs),
    phrase(json_ws, Cs, Cs1),
    phrase(json_input(Term), Cs1, Rest).

json_in_codes(Text, Cs) :- is_list(Text), !, Cs = Text.
json_in_codes(Text, Cs) :- atom(Text), !, atom_codes(Text, Cs).
json_in_codes(Text, _) :- throw(error(type_error(json_text, Text), json_parse/2)).

json_only(T) --> json_ws, json_input(T), json_ws, json_eos.

json_eos([], []) :- !.
json_eos(Rest, _) :- json_oops('one value and then the end of the input', Rest).

%% THE ERROR CARRIES A SNIPPET, not an offset. An offset is only useful
%% with the document beside it; forty bytes of what was actually there is
%% readable on its own, in a log, by somebody who does not have the file.
json_oops(What, Rest) :-
    json_snippet(Rest, 40, Cs),
    atom_codes(Where, Cs),
    throw(error(syntax_error(What), json_at(Where))).

json_snippet(_, 0, []) :- !.
json_snippet([], _, []) :- !.
json_snippet([C|Cs], N, Out) :-
    (   C =:= 0
    ->  Out = []                  % an atom would stop here anyway
    ;   Out = [C|Rest], M is N - 1, json_snippet(Cs, M, Rest)
    ).

%% ---- whitespace ------------------------------------------------------
%%
%% FOUR BYTES AND NO MORE. RFC 8259 names space, tab, LF and CR; a form
%% feed is not whitespace in JSON however much it looks like it, and a
%% parser that skipped it would accept documents another one rejects.
json_ws --> [C], { json_ws_code(C) }, !, json_ws.
json_ws --> [].

json_ws_code(0' ).
json_ws_code(0'\t).
json_ws_code(0'\n).
json_ws_code(0'\r).

%% ---- one value -------------------------------------------------------
%%
%% JSON IS LL(1): the first byte of a value says which value it is, so
%% this dispatches on a PEEK and never backtracks. That is also what makes
%% the errors precise -- once the byte says `{', anything that follows is
%% a broken object rather than a value that might still be something else.

json_input(T) --> json_peek(C), !, json_by(C, T).
json_input(_, Rest, _) :- json_oops('a value, and the input ended', Rest).

json_peek(C, [C|Cs], [C|Cs]).

json_by(0'{, json(Pairs)) --> !, [_], json_ws, json_members_in(Pairs).
json_by(0'[, Items) --> !, [_], json_ws, json_items_in(Items).
json_by(0'", Atom) --> !, [_], json_string_in(Cs), { json_atom_of(Cs, Atom) }.
json_by(0't, @(true)) --> !, json_word("true").
json_by(0'f, @(false)) --> !, json_word("false").
json_by(0'n, @(null)) --> !, json_word("null").
json_by(C, N) --> { json_number_start(C) }, !, json_number_in(N).
json_by(_, _, Rest, _) :- json_oops('a value', Rest).

json_number_start(0'-) :- !.
json_number_start(C) :- code_type(C, digit).

json_word([]) --> [].
json_word([C|Cs]) --> [C], !, json_word(Cs).
json_word(Cs, Rest, _) :- json_oops(Cs, Rest).

%% ---- objects and arrays ----------------------------------------------
%%
%% NO TRAILING COMMA, and that is the grammar rather than a strictness
%% setting: after a comma RFC 8259 requires another member, so `[1,]' is
%% not a one-element array with a typo in it -- it is two different
%% documents depending on who reads it.

json_members_in([]) --> [0'}], !.
json_members_in([P|Ps]) --> json_member_in(P), json_ws, json_members_more(Ps).

json_members_more([]) --> [0'}], !.
json_members_more([P|Ps]) --> [0',], !, json_ws, json_member_in(P), json_ws,
    json_members_more(Ps).
json_members_more(_, Rest, _) :- json_oops('a comma or a closing brace', Rest).

json_member_in(Key-Value) -->
    json_key_in(Key), json_ws, json_colon, json_ws, json_input(Value).

json_key_in(Key) --> [0'"], !, json_string_in(Cs), { json_atom_of(Cs, Key) }.
json_key_in(_, Rest, _) :- json_oops('a quoted key', Rest).

json_colon --> [0':], !.
json_colon(Rest, _) :- json_oops('a colon after the key', Rest).

json_items_in([]) --> [0']], !.
json_items_in([I|Is]) --> json_input(I), json_ws, json_items_more(Is).

json_items_more([]) --> [0']], !.
json_items_more([I|Is]) --> [0',], !, json_ws, json_input(I), json_ws,
    json_items_more(Is).
json_items_more(_, Rest, _) :- json_oops('a comma or a closing bracket', Rest).

%% ---- strings ---------------------------------------------------------
%%
%% THE OPENING QUOTE IS ALREADY EATEN when this starts, which is why it is
%% `_in' and not a whole-string nonterminal: the dispatch above had to
%% look at that byte to know it was a string at all.

json_string_in([]) --> [0'"], !.
json_string_in(Out) --> [0'\\], !, json_escape_in(Cs), json_string_in(Rest),
    { append(Cs, Rest, Out) }.
%% AN UNESCAPED CONTROL BYTE IS NOT LEGAL IN A STRING. RFC 8259 says a
%% string may hold any code point except the quote, the backslash and
%% U+0000-U+001F -- so a raw newline inside one is a document somebody
%% built by pasting, and saying so beats accepting it silently.
json_string_in(_, Rest, _) :- Rest = [C|_], C < 0x20, !,
    json_oops('an escape -- a raw control byte is not legal in a string', Rest).
json_string_in([C|Cs]) --> [C], !, json_string_in(Cs).
json_string_in(_, Rest, _) :- json_oops('a closing quote', Rest).

json_escape_in([0'"]) --> [0'"], !.
json_escape_in([0'\\]) --> [0'\\], !.
json_escape_in([0'/]) --> [0'/], !.
json_escape_in([0'\b]) --> [0'b], !.
json_escape_in([0'\f]) --> [0'f], !.
json_escape_in([0'\n]) --> [0'n], !.
json_escape_in([0'\r]) --> [0'r], !.
json_escape_in([0'\t]) --> [0't], !.
json_escape_in(Cs) --> [0'u], !, json_u_in(Cs).
json_escape_in(_, Rest, _) :- json_oops('a legal escape after the backslash', Rest).

%% ---- the u escape, and the surrogate pair ----------------------------
%%
%% A `\u' ESCAPE NAMES A UTF-16 CODE UNIT, not a character, and that is
%% the whole reason this is four clauses instead of one. A character above
%% U+FFFF is written as a PAIR -- a high unit D800-DBFF then a low one
%% DC00-DFFF -- so the high half must go and look for its partner before
%% it can know what character it was half of.
%%
%% A LONE SURROGATE IS AN ERROR because there is no UTF-8 for one: the
%% encoding has no byte sequence that means half a character, and a parser
%% that emitted a raw D800 as three bytes would produce text that is not
%% UTF-8 at all.
json_u_in(Cs) -->
    json_hex4(U),
    (   { U >= 0xD800, U =< 0xDBFF }
    ->  json_low_surrogate(Low),
        { Code is 0x10000 + ((U - 0xD800) << 10) + (Low - 0xDC00),
          json_utf8(Code, Cs) }
    ;   { U >= 0xDC00, U =< 0xDFFF }
    ->  { throw(error(syntax_error('a high surrogate before this low one'),
                      json_at(U))) }
    ;   { json_utf8(U, Cs) }
    ).

json_low_surrogate(Low) --> [0'\\, 0'u], !, json_hex4(Low),
    { (   Low >= 0xDC00, Low =< 0xDFFF
      ->  true
      ;   throw(error(syntax_error('a low surrogate after the high one'),
                      json_at(Low)))
      ) }.
json_low_surrogate(_, Rest, _) :-
    json_oops('a low surrogate escape after the high one', Rest).

json_hex4(N) --> [A, B, C, D], !,
    { json_hex(A, HA), json_hex(B, HB), json_hex(C, HC), json_hex(D, HD),
      N is (((HA * 16 + HB) * 16 + HC) * 16 + HD) }.
json_hex4(_, Rest, _) :- json_oops('four hex digits after the u', Rest).

json_hex(C, N) :- C >= 0'0, C =< 0'9, !, N is C - 0'0.
json_hex(C, N) :- C >= 0'a, C =< 0'f, !, N is C - 0'a + 10.
json_hex(C, N) :- C >= 0'A, C =< 0'F, !, N is C - 0'A + 10.
json_hex(C, _) :- throw(error(syntax_error('a hex digit'), json_at(C))).

%% UTF-8, WRITTEN OUT RATHER THAN CALLED, because there is no encoder in
%% this interpreter and this is the only place that needs one. Four
%% ranges, and code point zero refused for the reason at the top of this
%% section.
json_utf8(0, _) :-
    throw(error(syntax_error('any character but a NUL -- an atom stops there'),
                json_at('u0000'))).
json_utf8(C, [C]) :- C < 0x80, !.
json_utf8(C, [A, B]) :- C < 0x800, !,
    A is 0xC0 \/ (C >> 6), B is 0x80 \/ (C /\ 0x3F).
json_utf8(C, [A, B, D]) :- C < 0x10000, !,
    A is 0xE0 \/ (C >> 12), B is 0x80 \/ ((C >> 6) /\ 0x3F), D is 0x80 \/ (C /\ 0x3F).
json_utf8(C, [A, B, D, E]) :-
    A is 0xF0 \/ (C >> 18), B is 0x80 \/ ((C >> 12) /\ 0x3F),
    D is 0x80 \/ ((C >> 6) /\ 0x3F), E is 0x80 \/ (C /\ 0x3F).

json_atom_of(Cs, Atom) :- json_no_nul(Cs, Cs), atom_codes(Atom, Cs).

json_no_nul([], _).
json_no_nul([C|Cs], Whole) :-
    (   C =:= 0
    ->  json_oops('a string with no NUL in it -- an atom stops there', Whole)
    ;   json_no_nul(Cs, Whole)
    ).

%% ---- numbers ---------------------------------------------------------
%%
%% THE GRAMMAR IS COLLECTED AND THEN READ, rather than computed digit by
%% digit, because `number_codes/2' already knows how to turn a numeral
%% into a number and doing it again by hand is how a float ends up one
%% unit in the last place away from every other parser's answer.

json_number_in(N) -->
    json_minus_in(A), json_int_in(B), json_frac_in(C), json_exp_in(D),
    { append(A, B, AB), append(C, D, CD), append(AB, CD, Cs),
      number_codes(N, Cs),
      json_number_fits(Cs, C, D, N) }.

json_minus_in([0'-]) --> [0'-], !.
json_minus_in([]) --> [].

%% RFC 8259: int = zero / ( digit1-9 *DIGIT ). `01' IS NOT A NUMBER.
json_int_in([0'0]) --> [0'0], !.
json_int_in([D|Ds]) --> [D], { D >= 0'1, D =< 0'9 }, !, json_digits_in(Ds).
json_int_in(_, Rest, _) :- json_oops('a digit, and no leading zero', Rest).

json_digits_in([D|Ds]) --> [D], { code_type(D, digit) }, !, json_digits_in(Ds).
json_digits_in([]) --> [].

%% A DOT WITH NO DIGIT AFTER IT is not consumed here: the clause fails,
%% the empty one takes over, and the dot is left for whoever reads next --
%% who reports it as text where a comma or a brace was wanted. That is a
%% better message than "bad number" and it costs nothing.
json_frac_in([0'., D|Ds]) --> [0'., D], { code_type(D, digit) }, !, json_digits_in(Ds).
json_frac_in([]) --> [].

json_exp_in([E|Rest]) --> [E], { E == 0'e ; E == 0'E }, !,
    json_exp_sign(S), json_exp_digits(Ds), { append(S, Ds, Rest) }.
json_exp_in([]) --> [].

json_exp_sign([C]) --> [C], { C == 0'+ ; C == 0'- }, !.
json_exp_sign([]) --> [].

json_exp_digits([D|Ds]) --> [D], { code_type(D, digit) }, !, json_digits_in(Ds).
json_exp_digits(_, Rest, _) :- json_oops('a digit after the exponent', Rest).

%% THE OVERFLOW CHECK, and it is only meaningful for an integer. cocolog's
%% integers are 64-bit and `number_codes/2' answers -1 for a twenty-digit
%% literal with no complaint at all, so the digits are written back and
%% compared. `-0' is the one numeral that legitimately differs from its own
%% round trip, and it is the only exception.
json_number_fits(_, [_|_], _, _) :- !.       % has a fraction: a float
json_number_fits(_, _, [_|_], _) :- !.       % has an exponent: a float
json_number_fits(Cs, _, _, N) :-
    number_codes(N, Back),
    (   Back == Cs
    ->  true
    ;   Cs == [0'-, 0'0]
    ->  true
    ;   json_oops('an integer this machine can hold -- 64 bits', Cs)
    ).
