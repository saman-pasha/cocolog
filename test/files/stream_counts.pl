%  library(stream)'s counters and encodings, as swipl's.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  Through 3.18.0 open/4 applied iso_latin_1, octet and ascii (3.17.0,
%  with character_count/2, line_count/2, line_position/2, is_stream/1 and
%  stream_position_data/3) and wrote UTF-8 for UTF-16, UTF-32 and wchar_t,
%  no stream's encoding or BOM was a property, and byte_count/2 and
%  set_stream/2 were none (through 3.16.0 every encoding was UTF-8). swipl
%  counts what a stream read or wrote (characters, lines, the column,
%  bytes), writes and reads each character in the stream's encoding --
%  one byte in iso_latin_1 and octet, refused past 127 in ascii, two or
%  four in UTF-16, four in wchar_t, the BOM where bom(true) asks and
%  looked for by a read -- and tells a stream from a term that names none.
%  Every file is opened and read afresh, and a stream in an answer is
%  written by the name it was opened as: swipl writes <stream>(0x...).
%  Not compared: `text', the locale's encoding to swipl and UTF-8 to
%  cocolog; and a character past ASCII written to the console, which
%  swipl writes in the locale's encoding too. The file's own are escapes.

:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

main :-
    counts,
    encodings,
    streams,
    positions,
    bytes,
    setting,
    puts,
    malformed,
    console.

show(Label, Value) :- format("~w: ~q~n", [Label, Value]).

where(S, Label) :-
    character_count(S, C), line_count(S, L), line_position(S, P), byte_count(S, B),
    format("~w: chars ~w, line ~w, column ~w, bytes ~w~n", [Label, C, L, P, B]).

%% what a write and a read count, a character of two bytes among them
counts :-
    open('c.txt', write, W, [encoding(utf8)]),
    where(W, opened),
    write(W, 'h\u00e9llo'), where(W, 'after a word with a character of two bytes'),
    nl(W), where(W, 'after nl'),
    write(W, 'w\u00f6rld'), nl(W), write(W, tab), put_char(W, '\t'), where(W, 'after a tab'),
    close(W),
    open('c.txt', read, R, [encoding(utf8)]),
    get_char(R, C1), get_char(R, C2), char_code(C1, K1), char_code(C2, K2), show(read, [K1, K2]),
    where(R, 'after two'),
    read_line_to_codes(R, _), where(R, 'after the line'),
    get_char(R, C3), show(next, C3), where(R, 'after one more'),
    close(R).

%% each character as the encoding writes it, and read back
encodings :-
    forall(member(E, [utf8, iso_latin_1, octet, unicode_be, unicode_le, utf16be, utf16le, wchar_t]),
           ( open('e.txt', write, W, [encoding(E)]), write(W, 'a\u00e9'), close(W),
             size_file('e.txt', N), show(E-bytes, N),
             open('e.txt', read, R, [encoding(E)]), read_line_to_codes(R, Cs), close(R),
             show(E-codes, Cs),
             open('e.txt', read, B, [type(binary)]), read_stream_to_codes(B, Bs), close(B),
             show(E-raw, Bs) )),
    %% ascii takes what is ascii and refuses the rest
    open('a.txt', write, A, [encoding(ascii)]), write(A, abc),
    catch(( put_char(A, '\u00e9'), Outcome = wrote ),
          error(io_error(Op, _), context(_, Msg)), Outcome = io_error(Op, Msg)),
    show(ascii, Outcome),
    catch(close(A), _, true),
    %% the property says the encoding, and set_stream/2 changes it
    open('p.txt', write, P, [encoding(iso_latin_1)]),
    stream_property(P, encoding(PE)), show(property, PE),
    set_stream(P, encoding(utf8)), stream_property(P, encoding(PE2)), show(set, PE2),
    write(P, '\u00e9'), close(P), size_file('p.txt', PN), show(after_set, PN),
    open('b.bin', write, BS, [type(binary)]), stream_property(BS, encoding(BE)), show(binary, BE),
    close(BS),
    %% a BOM where it is asked for
    open('m.txt', write, M, [encoding(utf8), bom(true)]), write(M, x), close(M),
    size_file('m.txt', MN), show(bom_bytes, MN),
    open('m.txt', read, MR, [type(binary)]), read_stream_to_codes(MR, MB), close(MR),
    show(bom_raw, MB),
    open('m.txt', read, MT), read_stream_to_codes(MT, MC), close(MT),
    show(bom_read, MC),
    %% a UTF-16 BOM sets the encoding of a read that looks for one, and a
    %% character past U+FFFF is two units, counted as one character
    open('u.txt', write, U, [encoding(utf16le), bom(true)]), write(U, 'a\U0001F600b'),
    where(U, utf16_write), close(U),
    size_file('u.txt', UN), show(utf16_bytes, UN),
    open('u.txt', read, UR), stream_property(UR, encoding(UE)), show(utf16_found, UE),
    read_stream_to_codes(UR, UC), show(utf16_read, UC), where(UR, utf16_read), close(UR),
    open('u.txt', read, UB, [encoding(utf16le), bom(false)]), get_code(UB, UB1), show(no_bom_look, UB1),
    close(UB),
    %% and the options open/4 refuses
    catch(open('x.txt', write, _, [encoding(klingon)]), error(EK, _), true), show(klingon, EK),
    catch(open('x.txt', write, _, [type(binary), encoding(utf8)]), error(EB, _), true),
    show(binary_utf8, EB).

%% is_stream/1 and an alias set_stream/2 gives
streams :-
    ( is_stream(user_input) -> show(user_input, yes) ; show(user_input, no) ),
    ( is_stream(nothing) -> show(nothing, yes) ; show(nothing, no) ),
    ( is_stream(f(x)) -> show(compound, yes) ; show(compound, no) ),
    ( is_stream(_) -> show(unbound, yes) ; show(unbound, no) ),
    open('s.txt', write, S),
    ( is_stream(S) -> show(open, yes) ; show(open, no) ),
    set_stream(S, alias(mine)),
    ( is_stream(mine) -> show(alias, yes) ; show(alias, no) ),
    write(mine, hello), nl(mine),
    close(S),
    ( is_stream(S) -> show(closed, yes) ; show(closed, no) ),
    open('s.txt', read, SR), read_stream_to_codes(SR, Cs), close(SR), atom_codes(A, Cs),
    show(written, A),
    catch(set_stream(user_output, nonsense(1)), error(E, _), true), show(attribute, E),
    catch(set_stream(user_output, encoding(klingon)), error(E2, _), true), show(set_encoding, E2).

%% a position's fields
positions :-
    open('q.txt', write, W), write(W, 'ab'), nl(W), write(W, 'cde'),
    stream_property(W, position(P)),
    forall(member(F, [char_count, line_count, line_position, byte_count]),
           ( stream_position_data(F, P, V), show(F, V) )),
    close(W),
    findall(F2, stream_position_data(F2, P, _), Fs), show(fields, Fs),
    %% (swipl's ball is error/1 here, with no context)
    catch(stream_position_data(nonsense, P, _), Ball, true), show(nonsense, Ball).

%% the console's counts: user_output and user_error share one, as swipl's
%% standard streams do, its lines counted from 0, a tab to the next stop of
%% eight, and what a capture takes no part of them
console :-
    format("abc~n"),
    character_count(user_output, C0), line_count(user_output, L0), line_position(user_output, P0),
    format("xy\tz"), line_position(user_output, P1), nl,
    character_count(user_error, CE), show(console, [C0, L0, P0, P1, CE]),
    line_count(user_error, LE), byte_count(user_output, B), show(console_lines, LE-B),
    character_count(user_output, C1),
    with_output_to(string(_), write(captured)),
    character_count(user_output, C2), D is C2 - C1, show(console_capture, D),
    %% set_stream/2 sets the column the three standard streams share
    write(abc), set_stream(user_output, line_position(5)),
    line_position(user_output, P5), line_position(user_error, PE5), nl, show(console_set, P5-PE5),
    set_stream(user_input, line_position(3)), line_position(user_output, PO3), nl,
    show(console_input, PO3).


%% a byte from a text stream in octet and iso_latin_1, refused in utf8 and
%% ascii; characters, codes, a line and a term in iso_latin_1; terms and
%% their positions in UTF-16; a BOM only where the encoding has one
bytes :-
    open('l.txt', write, W, [encoding(iso_latin_1)]), write(W, 'a\u00bdb'), where(W, latin_write), close(W),
    forall(member(E, [octet, iso_latin_1, utf8, ascii]),
           ( open('l.txt', read, R, [encoding(E)]), try(E-get_byte, (get_byte(R, B), show(E-byte, B))), close(R) )),
    open('l.txt', read, R1, [encoding(iso_latin_1)]), get_char(R1, C1), get_char(R1, C2), char_code(C2, K2),
    show(latin_chars, [C1, K2]), get_code(R1, K3), show(latin_code, K3), where(R1, latin_read), close(R1),
    open('l.txt', read, R2, [encoding(iso_latin_1)]), read_line_to_codes(R2, L2), show(latin_line, L2), close(R2),
    open('t1.txt', write, W1, [encoding(iso_latin_1)]), format(W1, "p('~a').~n", ['\u00bd']), close(W1),
    size_file('t1.txt', N1), show(latin_term_bytes, N1),
    open('t1.txt', read, R3, [encoding(iso_latin_1)]), read(R3, T3), T3 = p(A3), atom_codes(A3, AC3),
    show(latin_term, AC3), close(R3),
    open('t2.txt', write, W2, [encoding(utf16le), bom(true)]), write(W2, 'f(x). g(y).'), nl(W2), put_char(W2, z),
    where(W2, utf16_written), close(W2),
    open('t2.txt', read, R4), read_term(R4, T4, [term_position(_)]), read_term(R4, T5, [term_position(P5)]),
    stream_position_data(char_count, P5, PC5), stream_position_data(byte_count, P5, PB5),
    show(utf16_terms, [T4, T5, PC5, PB5]), where(R4, utf16_terms), close(R4),
    open('t2.txt', read, B2, [type(binary)]), read_stream_to_codes(B2, BC2), close(B2), show(utf16_raw, BC2),
    open('o.txt', write, O, [encoding(iso_latin_1), bom(true)]), write(O, x), close(O),
    size_file('o.txt', ON), show(latin_bom, ON).

%% set_stream/2: the type and the encoding it implies, the column, an alias
%% moved from one stream to another, and what each attribute takes
setting :-
    open('s1.txt', write, S1), set_stream(S1, type(binary)),
    stream_property(S1, type(ST)), stream_property(S1, encoding(SE)), show(set_type, ST-SE),
    %% back to text, the stream takes the default encoding: `text' to swipl
    %% under the POSIX locale, UTF-8 to cocolog (not compared, above)
    set_stream(S1, type(text)), stream_property(S1, encoding(SE2)),
    ( memberchk(SE2, [text, utf8]) -> show(set_type_back, default) ; show(set_type_back, SE2) ),
    set_stream(S1, line_position(5)), line_position(S1, LP), show(set_column, LP),
    open('s2.txt', write, S2), set_stream(S1, alias(al)), set_stream(S2, alias(al)),
    ( stream_property(S1, alias(al)) -> show(alias_kept, yes) ; show(alias_kept, no) ),
    ( stream_property(S2, alias(al)) -> show(alias_moved, yes) ; show(alias_moved, no) ),
    forall(member(A, [buffer(full), buffer(wrong), buffer_size(10), buffer_size(x), close_on_abort(true),
                      close_on_abort(x), close_on_exec(false), record_position(true), tty(maybe),
                      eof_action(reset), newline(dos), newline(mac), newline(1), newline(_),
                      representation_errors(xml), representation_errors(x), write_errors(ignore),
                      write_errors(x), timeout(1.5), timeout(infinite), timeout(x), file_name(foo),
                      file_name(1), locale(default), locale(foo), type(foo), encoding(1),
                      line_position(x), alias(1), _, 7, eof_action(foo), eof_action(_),
                      buffer_size(-1), buffer_size(0), close_on_exec(x), record_position(x),
                      tty(true), line_position(-3), timeout(-1), file_name(_), encoding(_),
                      alias(_), line_position(_), buffer(_), timeout(_)]),
           ( ( ground(A) -> L = A ; compound(A) -> functor(A, F, _), L = unbound(F) ; L = unbound ),
             try(set(L), set_stream(S1, A)) )),
    open('b.bin', write, BB, [type(binary)]), try(binary_enc, set_stream(BB, encoding(utf8))),
    stream_property(BB, type(BT)), show(binary_after, BT), close(BB),
    close(S1), close(S2).

%% what a put writes in iso_latin_1 and ascii, a peek's counts, the bom
%% property, a term's position after one with a character of one byte,
%% and the streams get_byte/2 refuses
puts :-
    open('l2.txt', write, L, [encoding(iso_latin_1)]), put_char(L, '\u00e9'), put_char(L, x),
    try(latin_put_big, put_char(L, '\u0100')), close(L), size_file('l2.txt', LN), show(latin_put_size, LN),
    open('l2.txt', read, LR, [encoding(iso_latin_1)]), peek_char(LR, P1), char_code(P1, PK1), where(LR, latin_peek),
    get_char(LR, _), peek_code(LR, PK2), show(latin_peeks, [PK1, PK2]), where(LR, latin_peek2), close(LR),
    open('a2.txt', write, A, [encoding(ascii)]), try(ascii_put, put_char(A, '\u00e9')), close(A),
    size_file('a2.txt', AN), show(ascii_size, AN),
    open('s16.txt', write, S, [encoding(utf16le)]), put_char(S, a), try(lone_put, put_code(S, 0xD800)),
    put_char(S, b), close(S), size_file('s16.txt', SN), show(lone_put_size, SN),
    open('u2.txt', write, U, [encoding(utf16le)]), write(U, 'ab\u00e9c'), close(U),
    open('u2.txt', read, UR, [encoding(utf16le)]), get_char(UR, _), peek_char(UR, _), where(UR, utf16_peek),
    get_char(UR, _), get_char(UR, _), where(UR, utf16_two), try(utf16_byte, get_byte(UR, _)), close(UR),
    open('e2.txt', write, E8, [encoding(utf8)]), write(E8, '\u00e9'), close(E8),
    open('e2.txt', read, E8R, [encoding(utf8)]), try(utf8_byte, get_byte(E8R, _)), close(E8R),
    open('m2.txt', write, M, [encoding(utf8), bom(true)]), write(M, x),
    findall(B, stream_property(M, bom(B)), MB), show(bom_prop_write, MB), close(M),
    open('m2.txt', read, MR), findall(B, stream_property(MR, bom(B)), MB2), show(bom_prop_read, MB2), close(MR),
    open('n2.txt', write, NW), findall(B, stream_property(NW, bom(B)), MB3), show(bom_prop_none, MB3), close(NW),
    open('t3.txt', write, T3, [encoding(iso_latin_1)]), format(T3, "p('~a'). q(x).~n", ['\u00bd']), close(T3),
    open('t3.txt', read, TR, [encoding(iso_latin_1)]), read_term(TR, _, []), read_term(TR, Q, [term_position(QP)]),
    stream_position_data(char_count, QP, QC), stream_position_data(byte_count, QP, QB),
    show(latin_term_pos, [Q, QC, QB]), close(TR),
    catch(stream_position_data(char_count, _, _), error(EP1, _), true), show(position_unbound, EP1),
    catch(stream_position_data(char_count, foo, _), error(EP2, _), true), show(position_atom, EP2),
    catch(stream_position_data(1, '$stream_position'(1, 2, 3, 4), _), EP3, true), show(position_field, EP3).

%% malformed UTF-16 and UCS-4, as swipl reads it: a lead surrogate before
%% a unit that is no trail one is U+FFFD and takes both, and so is what
%% the end cuts short; a trail surrogate alone is itself. (swipl's warnings
%% are taken by message_hook/3 below; cocolog says none.)
malformed :-
    raw('h.txt', [0x3D, 0xD8, 0x61, 0x00, 0x62, 0x00]), codes('h.txt', utf16le, C1), show(lone_high, C1),
    open('h.txt', read, H, [encoding(utf16le)]), get_code(H, H1), where(H, lone), get_code(H, H2),
    show(lone_codes, [H1, H2]), close(H),
    raw('hb.txt', [0xD8, 0x3D, 0x00, 0x61]), codes('hb.txt', utf16be, C2), show(lone_high_be, C2),
    raw('o.txt', [0x61, 0x00, 0x62]), codes('o.txt', utf16le, C3), show(odd_tail, C3),
    raw('d.txt', [0x3D, 0xD8]), codes('d.txt', utf16le, C4), show(lone_high_end, C4),
    raw('hh.txt', [0x3D, 0xD8, 0x3D, 0xD8, 0x00, 0xDE]), codes('hh.txt', utf16le, C5), show(high_high, C5),
    raw('lo.txt', [0x00, 0xDC, 0x61, 0x00]), codes('lo.txt', utf16le, C6), show(lone_low, C6),
    raw('w2.txt', [0x41, 0, 0, 0, 0x42]), codes('w2.txt', wchar_t, C7), show(ucs_cut, C7),
    open('w2.txt', read, W, [encoding(wchar_t)]), get_code(W, _), get_code(W, _), where(W, ucs_cut), close(W).

raw(F, Bytes) :-
    open(F, write, W, [type(binary)]), forall(member(B, Bytes), put_byte(W, B)), close(W).

codes(F, E, Cs) :-
    open(F, read, R, [encoding(E)]), read_stream_to_codes(R, Cs), close(R).

%% a goal's answer, its error with the stream it names left out
try(L, G) :-
    catch(( G -> R = yes ; R = no ), error(E, _), shown_error(E, R)),
    show(L, R).

shown_error(permission_error(A, T, _), permission_error(A, T, stream)) :- !.
shown_error(io_error(A, _), io_error(A, stream)) :- !.
shown_error(E, E).

:- multifile message_hook/3.
message_hook(io_warning(_, _), warning, _).
