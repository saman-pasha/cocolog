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
