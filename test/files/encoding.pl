%  A load's source encodings, as swipl 9.0.4 has them (cocolog 3.58.0).
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  `:- encoding(E)' reads the rest of its file in E, from the byte after
%  its full stop: swipl's names, its MIME ones among them, `bom' changing
%  nothing there, and a name that is none ending the load with
%  set_stream/2's error. A BOM at a file's start names its encoding and is
%  taken off. load_files/2's encoding(E) reads the file in E whatever its
%  BOM said -- `bom' its BOM's or nothing, `default' nothing -- checked
%  once the file is found and is to be read. An included file is read in
%  the encoding the file that includes it is in there. library(stream)
%  takes the MIME names and answers swipl's own for a stream's encoding.
%  Through 3.57.0 the directive was an unknown procedure, reported, and
%  every file was read as UTF-8, a BOM's bytes in its first clause.
%
%  The case writes the files it loads into the working directory (the
%  sandbox), byte by byte. Every one that holds a byte past ASCII says its
%  encoding -- a directive, a BOM, a load's option -- as swipl's default is
%  the locale's and cocolog's UTF-8, and what is printed is codes. Not
%  compared: a byte that is no UTF-8 (swipl reads U+FFFD and says `Illegal
%  UTF-8 continuation', cocolog reads U+DC00 plus the byte), ascii's
%  `non-ASCII character' warning, and `text' past ASCII.

:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

:- dynamic p/1, q/1, r/1.

%  F's bytes: each element a code list (ASCII text), a byte, or
%  u16le(Text), u16be(Text) and u32le(Text), the text's characters in that
%  encoding
bytes(F, Parts) :-
    open(F, write, S, [type(binary)]),
    forall(member(P, Parts), part(S, P)),
    close(S).

part(S, B) :- integer(B), !, put_byte(S, B).
part(S, u16le(T)) :- !, forall(( member(C, T), unit(C, W) ), ( L is W /\ 255, H is W >> 8, put_byte(S, L), put_byte(S, H) )).
part(S, u16be(T)) :- !, forall(( member(C, T), unit(C, W) ), ( L is W /\ 255, H is W >> 8, put_byte(S, H), put_byte(S, L) )).
part(S, u32le(T)) :- !, forall(member(C, T), ( B0 is C /\ 255, B1 is (C >> 8) /\ 255, B2 is (C >> 16) /\ 255,
                                              B3 is C >> 24, put_byte(S, B0), put_byte(S, B1),
                                              put_byte(S, B2), put_byte(S, B3) )).
part(S, T) :- forall(member(C, T), put_byte(S, C)).

%  C's UTF-16 units, a character past U+FFFF its two surrogates
unit(C, C) :- C =< 0xFFFF, !.
unit(C, W) :- V is C - 0x10000, ( W is 0xD800 + (V >> 10) ; W is 0xDC00 + (V /\ 0x3FF) ).

%  what P, Q and R hold, as codes
show :-
    forall(member(N, [p, q, r]),
           ( G =.. [N, X], findall(Cs, ( catch(G, _, fail), text_codes(X, Cs) ), L),
             ( L == [] -> true ; format("  ~w ~w~n", [N, L]) ) )).

text_codes(X, Cs) :- atom(X), !, atom_codes(X, Cs).
text_codes(X, Cs) :- string(X), !, string_codes(X, Cs).
text_codes(X, X).

clear :- retractall(p(_)), retractall(q(_)), retractall(r(_)).

%  one load, its ball printed, and what it read
load(Label, Goal) :-
    clear,
    format("== ~w~n", [Label]),
    flush_output,
    (   catch(Goal, E, (print_message(error, E), writeln(caught)))
    ->  true
    ;   writeln(failed)
    ),
    flush_output,
    show.

main :-
    files,
    directives,
    switches,
    boms,
    options,
    includes,
    modules,
    nuls,
    streams.

%  ---- the directive's names ----------------------------------------------

files :-
    bytes('utf8.pl', [":- encoding(utf8).\np(", 0xC3, 0xA9, "t", 0xC3, 0xA9, ").\n"]),
    bytes('latin1.pl', [":- encoding(iso_latin_1).\np(", 0xE9, "t", 0xE9, ").\n"]),
    bytes('mime8.pl', [":- encoding('UTF-8').\np(", 0xC3, 0xA9, ").\n"]),
    bytes('mime1.pl', [":- encoding('ISO-8859-1').\np(", 0xE9, ").\n"]),
    bytes('octet.pl', [":- encoding(octet).\np(", 0xE9, "t).\n"]),
    bytes('ascii.pl', [":- encoding(ascii).\np(abc).\n"]),
    bytes('text.pl', [":- encoding(text).\np(abc).\n"]),
    bytes('u16le.pl', [":- encoding(utf16le).", u16le("\np(\xE9\).\nq(\x10348\).\n")]),
    bytes('uni_le.pl', [":- encoding(unicode_le).", u16le("\np(\xE9\).\n")]),
    bytes('mime16le.pl', [":- encoding('UTF-16LE').", u16le("\np(\xE9\).\n")]),
    %% a big-endian unit's first byte after the full stop is a NUL, which
    %% is no layout to end the directive (swipl's, and so here): so the
    %% name ends the file
    bytes('u16be.pl', ["p(a).\n:- encoding(utf16be)."]),
    bytes('uni_be.pl', ["p(a).\n:- encoding(unicode_be)."]),
    bytes('mime16be.pl', ["p(a).\n:- encoding('UTF-16BE')."]),
    bytes('wchar.pl', [":- encoding(wchar_t).", u32le("\np(\xE9\).\nq(\x10348\).\n")]),
    bytes('octet_bad.pl', [":- encoding(octet).\np(", 0xC3, 0xA9, ").\nq(a).\n"]),
    bytes('bad_name.pl', ["p(0).\n:- encoding(foo).\np(a).\n"]),
    bytes('bad_case.pl', ["p(0).\n:- encoding('Utf-8').\np(a).\n"]),
    bytes('bad_var.pl', ["p(0).\n:- encoding(E).\np(a).\n"]),
    bytes('bad_int.pl', ["p(0).\n:- encoding(1).\np(a).\n"]),
    bytes('bad_comp.pl', ["p(0).\n:- encoding(utf8(x)).\np(a).\n"]),
    bytes('bad_nil.pl', ["p(0).\n:- encoding([]).\np(a).\n"]),
    bytes('skipped.pl', [":- if(fail).\n:- encoding(foo).\n:- endif.\n:- encoding(iso_latin_1).\np(", 0xE9, ").\n"]),
    bytes('bom_mid.pl', [":- encoding(iso_latin_1).\n:- encoding(bom).\np(", 0xE9, ").\n"]).

directives :-
    forall(member(F, [utf8, latin1, mime8, mime1, octet, ascii, text, u16le, u16be, uni_le, uni_be,
                      mime16le, mime16be, wchar, octet_bad, bad_name, bad_case, bad_var, bad_int,
                      bad_comp, bad_nil, skipped, bom_mid]),
           load(F, consult(F))).

%  ---- switches in one file -------------------------------------------------

%  latin-1, then UTF-8, then octet; then UTF-16 and back to latin-1 -- a
%  full stop is one where what follows it is layout or a comment in the
%  encoding it stands in, and the switch is from the byte after it, so the
%  UTF-16 `%' that follows is a `%' and a NUL to latin-1, the NUL in the
%  comment; and one whose UTF-16 full stop has no layout after it, which
%  ends no clause
switches :-
    bytes('back.pl', [":- encoding(iso_latin_1).\np(", 0xE9, ").\n:- encoding(utf8).\nq(", 0xC3, 0xA9, ").\n",
                      ":- encoding(octet).\nr(a", 0xE9, ").\n"]),
    bytes('round.pl', [":- encoding(utf16le).", u16le("\np(\xE9\).\n:- encoding(iso_latin_1).%"), "\nq(", 0xE9, ").\n"]),
    bytes('nolayout.pl', [":- encoding(utf16le).", u16le("\np(a).\n:- encoding(utf8)."), "q(b).\n"]),
    forall(member(F, [back, round, nolayout]), load(F, consult(F))).

%  ---- a BOM ------------------------------------------------------------------

boms :-
    bytes('bom8.pl', [0xEF, 0xBB, 0xBF, "p(", 0xC3, 0xA9, ").\n"]),
    bytes('bom16le.pl', [0xFF, 0xFE, u16le("p(\xE9\).\nq(\x10348\).\n")]),
    bytes('bom16be.pl', [0xFE, 0xFF, u16be("p(\xE9\).\n")]),
    %% a BOM, then a directive that reads the rest otherwise
    bytes('bom_then.pl', [0xEF, 0xBB, 0xBF, ":- encoding(iso_latin_1).\np(", 0xE9, ").\n"]),
    %% a BOM's bytes after the start are no BOM
    bytes('bom_late.pl', [":- encoding(iso_latin_1).\n", 0xEF, 0xBB, 0xBF, "p(a).\nq(b).\n"]),
    forall(member(F, [bom8, bom16le, bom16be, bom_then, bom_late]), load(F, consult(F))).

%  ---- load_files/2's encoding(E) --------------------------------------------

%  (not_loaded reads a file no load read before: swipl takes a file a
%  second refused load named for one that is no source file, and reads it
%  again)
options :-
    bytes('plain1.pl', ["p(", 0xE9, ").\n"]),
    bytes('plain2.pl', ["p(", 0xE9, ").\n"]),
    bytes('plain_ascii.pl', ["p(abc).\n"]),
    forall(member(L-G,
                  [ latin1 - load_files(plain1, [encoding(iso_latin_1)]),
                    mime1 - load_files(plain1, [encoding('ISO-8859-1')]),
                    octet - load_files(plain1, [encoding(octet)]),
                    bom_over - load_files(bom8, [encoding(iso_latin_1)]),
                    bom16_utf16 - load_files(bom16le, [encoding(utf16le)]),
                    bom_option - load_files(bom8, [encoding(bom)]),
                    bom16_option - load_files(bom16le, [encoding(bom)]),
                    no_bom_option - load_files(plain_ascii, [encoding(bom)]),
                    default_option - load_files(plain_ascii, [encoding(default)]),
                    directive_over - load_files(utf8, [encoding(iso_latin_1)]),
                    first_wins - load_files(plain1, [encoding(iso_latin_1), encoding(foo)]),
                    first_bad - load_files(plain1, [encoding(foo), encoding(iso_latin_1)]),
                    unbound - load_files(plain1, [encoding(_)]),
                    integer - load_files(plain1, [encoding(1)]),
                    nil - load_files(plain1, [encoding([])]),
                    missing_first - load_files(nonesuch, [encoding(foo)]),
                    not_loaded - load_files(plain2, [if(not_loaded), encoding(iso_latin_1)]) ]),
           load(L, G)),
    %% a file loaded already, under if(not_loaded), is not read: its
    %% option is not checked
    clear,
    load_files(plain_ascii, []),
    load(loaded_already, load_files(plain_ascii, [if(not_loaded), encoding(foo)])).

%  ---- an include --------------------------------------------------------------

%  read in the encoding the including file is in at the include, its BOM
%  taken off, its own directive its own
includes :-
    bytes('inc_l1.pl', ["q(", 0xE9, ").\n"]),
    bytes('inc_bom8.pl', [0xEF, 0xBB, 0xBF, "q(", 0xC3, 0xA9, ").\n"]),
    bytes('inc_sw.pl', [":- encoding(utf8).\nq(", 0xC3, 0xA9, ").\n"]),
    bytes('im_l1.pl', [":- encoding(iso_latin_1).\n:- include(inc_l1).\np(", 0xE9, ").\n"]),
    bytes('im_bom.pl', [":- encoding(iso_latin_1).\n:- include(inc_bom8).\np(", 0xE9, ").\n"]),
    bytes('im_bom_u8.pl', [":- encoding(utf8).\n:- include(inc_bom8).\np(", 0xC3, 0xA9, ").\n"]),
    bytes('im_sw.pl', [":- encoding(iso_latin_1).\n:- include(inc_sw).\np(", 0xE9, ").\n"]),
    forall(member(F, [im_l1, im_bom, im_bom_u8, im_sw]), load(F, consult(F))).

%  ---- a module's file ---------------------------------------------------------

%  read in the encoding its BOM or its load named, so a directive that names
%  it again changes nothing
modules :-
    bytes('mod16.pl', [0xFF, 0xFE, u16le(":- module(mod16, [m16/1]).\n:- encoding(utf16le).\nm16('\xE9\').\n")]),
    bytes('modl1.pl', [":- module(modl1, [ml1/1]).\n:- encoding(iso_latin_1).\nml1('", 0xE9, "').\n"]),
    load(mod16, ( use_module(mod16), m16(A), atom_codes(A, C), format("  m16 ~w~n", [C]) )),
    load(modl1, ( load_files(modl1, [if(not_loaded), encoding(iso_latin_1)]), ml1(B), atom_codes(B, D),
                  format("  ml1 ~w~n", [D]) )).

%  ---- a NUL byte -------------------------------------------------------------

%  no end of the text (through 3.57.0 the file ended at it, unsaid): outside
%  quotes a character no token takes, reported where it stands, and the load
%  goes on; inside a code list, a string or after 0' the code 0, and in a
%  comment nothing. An atom is left out: cocolog's ends at the NUL
%  (COMPAT.md)
nuls :-
    bytes('nul1.pl', ["p(a).\nq(b", 0, "c).\nr(d).\n"]),
    bytes('nul2.pl', ["p(a).\n", 0, "\nr(d).\n"]),
    bytes('nul3.pl', [":- set_prolog_flag(double_quotes, codes).\nq(\"a", 0, "b\").\nr(0'", 0, ").\n"]),
    bytes('nul4.pl', [":- set_prolog_flag(double_quotes, string).\nq(\"a", 0, "b\").\nr(`c", 0, "d`).\n"]),
    bytes('nul5.pl', ["p(a). % x", 0, "y\n/* ", 0, " */ r(b).\nq(c).\n"]),
    %% and one column, where an error after it is placed
    bytes('nul6.pl', ["p(\"a", 0, "b\" c).\nq(1).\n"]),
    %% and an included file's is read so too
    bytes('inc_nul.pl', ["q(\"a", 0, "b\").\n"]),
    bytes('nul7.pl', [":- set_prolog_flag(double_quotes, codes).\n:- include(inc_nul).\np(a).\n"]),
    forall(member(F, [nul1, nul2, nul3, nul4, nul5, nul6, nul7]), load(F, consult(F))).

%  ---- library(stream) -------------------------------------------------------

%  the names a stream is opened in, and the name stream_property/2 answers
streams :-
    writeln('== streams'),
    bytes('s.txt', ["abc\n"]),
    forall(member(E, [utf8, 'UTF-8', iso_latin_1, 'ISO-8859-1', octet, ascii, text,
                      unicode_be, unicode_le, utf16be, utf16le, 'UTF-16BE', 'UTF-16LE', wchar_t]),
           ( open('s.txt', read, S, [encoding(E)]),
             stream_property(S, encoding(P)),
             set_stream(S, encoding(E)),
             stream_property(S, encoding(P2)),
             close(S),
             format("  ~q ~q ~q~n", [E, P, P2]) )),
    forall(member(E, ['utf-8', 'UTF8', bom, latin1]),
           ( catch(( open('s.txt', read, S, [encoding(E)]), close(S), writeln(opened) ),
                   error(Err, _), ( print(Err), nl )) )),
    open('s.txt', read, S2, []),
    forall(member(E, ['utf-8', 'UTF-32', foo]),
           catch(set_stream(S2, encoding(E)), error(Err2, _), ( print(Err2), nl ))),
    close(S2).
