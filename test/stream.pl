%% library(stream) -- files as streams: bytes, characters, lines, terms and
%% formatted text, under names of its own and under ISO's, held to what came
%% back.
%%
%% EVERY CHECK WRITES A FILE AND READS IT BACK, in this process, through
%% the module: what `stream_format' put down is what `stream_read_line'
%% picks up, byte for byte, and `read_file_to_codes/2' -- the one file
%% reader the interpreter had before this -- is the second witness where
%% one is wanted. A CLAUSE HAS ONE SCOPE: every check's variables carry
%% its number.
%%
%%     cocolog -s test/stream.pl        from the checkout root
%%
%% SKIPs without library/stream.so -- sh modules/stream/build.sh, which
%% needs nothing but a C compiler.

:- use_module('test/prelude.pl').

main :-
    ( exists_file('library/stream.so') -> true ; skip('(no library/stream.so -- sh modules/stream/build.sh)') ),
    ( catch(use_module(library(stream)), _, fail) -> true ; skip('(library(stream) will not load)') ),
    scratch(D),
    text_out_and_in(D),
    characters(D),
    binary(D),
    positions(D),
    formatted(D),
    terms(D),
    the_standard_three,
    properties(D),
    what_goes_wrong(D),
    iso_names(D),
    aliases(D),
    current_io(D),
    read_options(D),
    codes(D),
    sinks,
    shl(['rm -rf ', D]),
    checks_done.

%% the shape of a ball with its context taken off: check/3 compares with ==
ball(error(error(E, _)), E) :- !.
ball(error(E, _), E) :- !.
ball(error(E), E) :- !.
ball(X, X).

path(D, Name, Path) :- atomic_list_concat([D, '/', Name], Path).

%% ---- text: lines out, lines in ---------------------------------------------

text_out_and_in(D) :-
    section('text: lines out, lines in'),
    path(D, 't.txt', T),
    answer(( stream_open(T, write, S1), stream_write_text(S1, hello), stream_nl(S1),
             stream_write_text(S1, "two words"), stream_nl(S1), stream_write_text(S1, 'no newline at the end'),
             stream_close(S1), read_file_to_codes(T, C1), atom_codes(A1, C1) ), A1, G1),
    check('stream_write_text and stream_nl write what they were given', G1, 'hello\ntwo words\nno newline at the end'),
    answer(( stream_open(T, read, S2), stream_read_line(S2, L2a), stream_read_line(S2, L2b), stream_read_line(S2, L2c),
             stream_read_line(S2, L2d), stream_close(S2),
             atom_codes(A2a, L2a), atom_codes(A2b, L2b), atom_codes(A2c, L2c) ), A2a-A2b-A2c-L2d, G2),
    check('stream_read_line: the newline off, the last line without one still a line, then end_of_file', G2,
          hello-'two words'-'no newline at the end'-end_of_file),
    answer(( stream_open(T, read, S3), stream_read_lines(S3, Ls3), stream_close(S3), length(Ls3, N3) ), N3, G3),
    check('stream_read_lines reads the rest', G3, 3),
    answer(( stream_open(T, append, S4), stream_write_text(S4, "\r\nfourth\r\n"), stream_close(S4),
             stream_open(T, read, S4b), stream_read_lines(S4b, Ls4), stream_close(S4b), last(Ls4, L4), atom_codes(A4, L4) ), A4, G4),
    check('append adds to the end, and a CR before the newline comes off', G4, fourth),
    answer(( stream_open(T, write, S5), stream_close(S5), stream_open(T, read, S5b),
             ( stream_eof(S5b) -> E5 = eof ; E5 = more ), stream_read_all(S5b, All5), stream_close(S5b) ), E5-All5, G5),
    check('write truncates, and an empty file is at its end at once', G5, eof-[]).

%% ---- characters, which are UTF-8 -------------------------------------------

characters(D) :-
    section('characters: one UTF-8 character at a time'),
    path(D, 'c.txt', C),
    answer(( stream_open(C, write, S1), stream_put_char(S1, a), stream_put_char(S1, 'é'), stream_put_char(S1, '€'),
             stream_put_char(S1, '\n'), stream_close(S1), read_file_to_codes(C, Cs1), length(Cs1, N1) ), N1, G1),
    check('put_char writes a character''s bytes: 1 + 2 + 3 + 1', G1, 7),
    answer(( stream_open(C, read, S2), stream_get_char(S2, C2a), stream_get_char(S2, C2b), stream_get_char(S2, C2c),
             stream_get_char(S2, C2d), stream_get_char(S2, C2e), stream_close(S2) ), [C2a, C2b, C2c, C2d, C2e], G2),
    check('get_char answers each character whole, then end_of_file', G2, [a, 'é', '€', '\n', end_of_file]),
    answer(( stream_open(C, read, S3), stream_get_char(S3, _), stream_peek_char(S3, P3), stream_position(S3, Pos3a),
             stream_get_char(S3, C3), stream_position(S3, Pos3b), stream_close(S3) ), P3-Pos3a-C3-Pos3b, G3),
    check('peek_char leaves the character and the position where they were', G3, 'é'-1-'é'-3),
    answer(( stream_open(C, read, S4), stream_peek_char(S4, _), stream_read_line(S4, L4), stream_close(S4), atom_codes(A4, L4) ), A4, G4),
    check('a line read after a peek starts with the peeked character', G4, 'aé€'),
    answer(( stream_open(C, read, S5), stream_get_char(S5, _), stream_seek(S5, 0), stream_get_char(S5, C5), stream_close(S5) ), C5, G5),
    check('seek(0) starts again', G5, a).

%% ---- bytes ---------------------------------------------------------------

binary(D) :-
    section('binary: bytes, and only bytes'),
    path(D, 'b.bin', B),
    answer(( stream_open(B, write, [type(binary)], S1), stream_write_bytes(S1, [0, 1, 2, 255, 10, 13]), stream_put_byte(S1, 7),
             stream_close(S1), read_file_to_codes(B, Cs1) ), Cs1, G1),
    check('write_bytes and put_byte: every value 0..255, a NUL included', G1, [0, 1, 2, 255, 10, 13, 7]),
    answer(( stream_open(B, read, [type(binary)], S2), stream_get_byte(S2, B2a), stream_peek_byte(S2, B2b), stream_get_byte(S2, B2c),
             stream_read_bytes(S2, 3, Bs2), stream_read_bytes(S2, 10, Bs2b), stream_get_byte(S2, B2e), stream_close(S2) ),
           B2a-B2b-B2c-Bs2-Bs2b-B2e, G2),
    check('get, peek, read N (short at the end), and -1 past it', G2, 0-1-1-[2, 255, 10]-[13, 7]-(-1)),
    answer(( stream_open(B, read, [type(binary)], S3), stream_size(S3, Sz3), stream_read_all(S3, All3), length(All3, N3), stream_close(S3) ), Sz3-N3, G3),
    check('size is the file''s, and read_all reads it whole', G3, 7-7),
    answer(( stream_open(B, update, [type(binary)], S4), stream_seek(S4, 1), stream_put_byte(S4, 99), stream_flush(S4),
             stream_seek(S4, 0), stream_read_bytes(S4, 7, Bs4), stream_close(S4) ), Bs4, G4),
    check('update writes into the file where it is and reads it back', G4, [0, 99, 2, 255, 10, 13, 7]),
    answer(( stream_open(B, read, [type(binary)], S5), stream_get_byte(S5, _), stream_read_bytes(S5, 100, Bs5), stream_close(S5), length(Bs5, N5) ), N5, G5),
    check('read_bytes past the end answers what there was', G5, 6).

%% ---- positions --------------------------------------------------------------

positions(D) :-
    section('positions: tell, seek, size'),
    path(D, 'p.bin', P),
    answer(( stream_open(P, write, [type(binary)], S1), numlist(0, 99, Ns1), stream_write_bytes(S1, Ns1), stream_close(S1),
             stream_open(P, read, [type(binary)], S2), stream_position(S2, P0),
             stream_seek(S2, 50), stream_get_byte(S2, B50), stream_position(S2, P51),
             stream_seek(S2, -3, eof), stream_get_byte(S2, B97),
             stream_seek(S2, -10, current), stream_get_byte(S2, B88),
             stream_seek(S2, 0, eof), ( stream_eof(S2) -> E = eof ; E = more ), stream_size(S2, Sz), stream_close(S2) ),
           P0-B50-P51-B97-B88-E-Sz, G1),
    check('seek from the start, the end and here; eof at the end; size 100', G1, 0-50-51-97-88-eof-100),
    answer(( stream_open(P, read, [type(binary)], S3), stream_peek_byte(S3, _), stream_position(S3, Pos3),
             stream_seek(S3, 2, current), stream_get_byte(S3, B3), stream_close(S3) ), Pos3-B3, G3),
    check('a peeked byte is not counted, and a relative seek starts before it', G3, 0-2).

%% ---- formatted output ------------------------------------------------------

formatted(D) :-
    section('formatted: the engine''s formatter into the file'),
    path(D, 'f.txt', F),
    answer(( stream_open(F, write, S1), stream_format(S1, "~w ~q ~a ~d~n", [f('X', "ab"), 'A b', bar, 42]),
             stream_write(S1, 'A b'), stream_nl(S1), stream_writeq(S1, 'A b'), stream_nl(S1),
             stream_print(S1, [1, 2]), stream_nl(S1), stream_write_canonical(S1, 'A' + b), stream_nl(S1),
             stream_write_term(S1, f('X'), [quoted(true)]), stream_nl(S1), stream_close(S1),
             read_file_to_codes(F, C1), atom_codes(A1, C1) ), A1, G1),
    check('format, write, writeq, print, write_canonical and write_term, each as on the terminal', G1,
          'f(X,[97,98]) \'A b\' bar 42\nA b\n\'A b\'\n[1,2]\n\'A\'+b\nf(\'X\')\n'),
    answer(( stream_open(F, write, S2), stream_with_output(S2, ( write(captured), nl, format("~a~n", [and_formatted]) )),
             stream_close(S2), read_file_to_codes(F, C2), atom_codes(A2, C2) ), A2, G2),
    check('stream_with_output sends what a goal prints to the file', G2, 'captured\nand_formatted\n'),
    answer(( stream_open(F, write, S3), stream_format(S3, "~w~n", [first]), stream_flush(S3),
             read_file_to_codes(F, C3), atom_codes(A3, C3), stream_close(S3) ), A3, G3),
    check('stream_flush makes what was written visible to another reader', G3, 'first\n').

%% ---- terms ----------------------------------------------------------------

terms(D) :-
    section('terms: a clause at a time, the engine''s own reader'),
    path(D, 'c.pl', C),
    answer(( stream_open(C, write, S1),
             stream_write_text(S1, "% a comment\nfoo(X, Y) :- X is Y + 1, Y = 'a.b'. /* block . comment */\nbar(\"str.ing\", 0'., [1,2|T]).\nbaz :- X =.. [f, 1].\n\n% trailing comment\n"),
             stream_close(S1),
             stream_open(C, read, S2), stream_read_term(S2, T1), stream_read_term(S2, T2), stream_read_term(S2, T3),
             stream_read_term(S2, T4), stream_close(S2),
             ( T1 = (foo(X1, Y1) :- (X1 is Y1 + 1, Y1 = 'a.b')) -> V1a = clause ; V1a = T1 ),
             ( T2 = bar(Str, 46, [1, 2|_]), atom_codes('str.ing', Str) -> V1b = fact ; V1b = T2 ),
             ( T3 = (baz :- _ =.. [f, 1]) -> V1c = univ ; V1c = T3 ) ), V1a-V1b-V1c-T4, G1),
    check('operators, a quoted dot, a string with a dot, 0''., a comment with a dot, and end_of_file after the last', G1,
          clause-fact-univ-end_of_file),
    answer(( stream_open(C, read, S3), stream_read_terms(S3, Ts3), stream_close(S3), length(Ts3, N3) ), N3, G3),
    check('read_terms reads them all', G3, 3),
    answer(( stream_open(C, append, S4), stream_write_text(S4, "oops(.\n"), stream_close(S4),
             stream_open(C, read, S5), stream_read_terms(S5, _) ), ok, G5), ball(G5, B5),
    ( B5 = syntax_error(Why5), atom(Why5) -> V5 = syntax_error ; V5 = B5 ),
    check('a clause that will not read is syntax_error(Message), ISO''s shape, not a term', V5, syntax_error),
    answer(( stream_open(C, write, S6), stream_write_text(S6, "unfinished(1, 2"), stream_close(S6),
             stream_open(C, read, S7), stream_read_term(S7, _) ), ok, G7), ball(G7, B7),
    ( B7 = syntax_error(Why7), sub_atom(Why7, _, _, _, 'end of file') -> V7 = cut_short ; V7 = B7 ),
    check('and a clause the end of the file cut short says so', V7, cut_short),
    answer(( stream_open(C, write, S8), stream_write_text(S8, "  % only a comment\n/* and another */\n"), stream_close(S8),
             stream_open(C, read, S9), stream_read_term(S9, T9), stream_close(S9) ), T9, G9),
    check('a file of comments is end_of_file', G9, end_of_file).

%% ---- the standard three --------------------------------------------------

the_standard_three :-
    section('the standard streams'),
    answer(( stream_input(I), stream_output(O), stream_error(E) ), I-O-E, G1),
    check('stream_input, stream_output and stream_error name slots 0, 1 and 2', G1, '$stream'(0)-'$stream'(1)-'$stream'(2)),
    cocolog(C),
    sh_join(['printf ''one\\ntwo\\n'' | ', C, ' query "use_module(library(stream)), stream_read_line(user_input, L), atom_codes(A, L), stream_read_lines(user_input, Ls), length(Ls, N), write(answer(A-N)), nl" 2>/dev/null'], Cmd2),
    proc_run(Cmd2, 60000, Out2, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out2, A2) -> sub_atom(A2, 7, _, 1, G2) ; G2 = '' ),
    check('user_input reads a child''s stdin, a line and then the rest', G2, 'one-1'),
    sh_join([C, ' query "use_module(library(stream)), stream_format(user_error, \\"answer(~w)~n\\", [stderr])" 2>&1 >/dev/null'], Cmd3),
    proc_run(Cmd3, 60000, Out3, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out3, A3) -> sub_atom(A3, 7, _, 1, G3) ; G3 = '' ),
    check('user_error writes to a child''s stderr', G3, stderr).

%% ---- properties -----------------------------------------------------------

properties(D) :-
    section('stream_property'),
    path(D, 'q.txt', Q),
    answer(( stream_open(Q, write, [type(binary)], S1), findall(P, stream_property(S1, P), Ps1), stream_close(S1) ), Ps1, G1),
    check('ISO''s properties: file_name, mode, type, direction, position, eof_action, reposition', G1,
          [file_name(Q), mode(write), type(binary), output, position(0), eof_action(eof_code), reposition(true)]),
    answer(( stream_open(Q, update, S2), findall(P, stream_property(S2, P), Ps2), stream_close(S2) ), Ps2, G2),
    check('update is input and output both, and an input stream says whether it is at its end', G2,
          [file_name(Q), mode(update), type(text), input, output, position(0), end_of_stream(at), eof_action(eof_code), reposition(true)]),
    answer(( findall(A, stream_property(_, alias(A)), As) ), As, G3),
    check('the standard three carry their aliases', G3, [user_input, user_output, user_error]),
    answer(( stream_open(Q, read, S4), stream_close(S4), findall(S, stream_property(S, file_name(Q)), Ss4) ), Ss4, G4),
    check('a closed stream is gone from the table', G4, []).

%% ---- what goes wrong ------------------------------------------------------

what_goes_wrong(D) :-
    section('what goes wrong'),
    path(D, 'w.txt', W),
    answer(stream_open('/nonexistent/dir/x', read, _), ok, G1), ball(G1, B1),
    check('no such file is existence_error(source_sink, Path)', B1, existence_error(source_sink, '/nonexistent/dir/x')),
    path(D, 'readonly.txt', RO), shl(['touch ', RO, ' && chmod 444 ', RO]),
    answer(stream_open(RO, write, _), ok, G2), ball(G2, B2),
    check('a file that may not be written is a permission_error naming it', B2, permission_error(open, source_sink, RO)),
    answer(stream_open(W, sideways, _), ok, G3), ball(G3, B3),
    check('a mode nobody defined is a domain error', B3, domain_error(io_mode, sideways)),
    answer(( stream_open(W, write, S4), stream_close(S4), stream_write_text(S4, x) ), ok, G4), ball(G4, B4),
    ( B4 = existence_error(stream, '$stream'(_)) -> V4 = shape ; V4 = B4 ),
    check('a closed stream is an existence_error naming the handle', V4, shape),
    answer(stream_read_line(foo, _), ok, G5), ball(G5, B5),
    check('an atom that names no stream is existence_error(stream, A), ISO''s shape for an alias', B5, existence_error(stream, foo)),
    answer(stream_read_line(f(x), _), ok, G5b), ball(G5b, B5b),
    check('and a term that could be neither is domain_error(stream_or_alias, T)', B5b, domain_error(stream_or_alias, f(x))),
    answer(( stream_close(user_output), close(user_error), write(user_output, '') ), ok, G6),
    check('closing a standard stream does nothing, which is ISO''s rule', G6, ok),
    answer(( stream_open(W, write, S7), stream_close(S7), stream_open(W, read, S7b), catch(stream_get_byte(S7b, _), E7, true), stream_close(S7b) ), E7, G7),
    ( G7 = error(permission_error(input, text_stream, '$stream'(_)), _) -> V7 = shape ; V7 = G7 ),
    check('a byte from a text stream is permission_error(input, text_stream, S), S the handle', V7, shape),
    answer(( stream_open(W, read, [type(binary)], S8), catch(stream_read_line(S8, _), E8, true), stream_close(S8) ), E8, G8),
    ( G8 = error(permission_error(input, binary_stream, '$stream'(_)), _) -> V8 = shape ; V8 = G8 ),
    check('and a line from a binary one is permission_error(input, binary_stream, S)', V8, shape),
    answer(( stream_open(W, read, S9), catch(stream_write_text(S9, x), E9, true), stream_close(S9) ), E9, G9),
    ( G9 = error(permission_error(output, stream, '$stream'(_)), _) -> V9 = shape ; V9 = G9 ),
    check('writing to a stream opened for reading', V9, shape),
    answer(( stream_open(W, write, [type(binary)], S10), catch(stream_put_byte(S10, 256), E10, true), stream_close(S10) ), E10, G10),
    ( G10 = error(type_error(byte, 256), _) -> V10 = shape ; V10 = G10 ),
    check('a byte past 255 is a type error', V10, shape),
    answer(( stream_open(W, write, S11), catch(stream_put_char(S11, ab), E11, true), stream_close(S11) ), E11, G11),
    ( G11 = error(type_error(character, ab), _) -> V11 = shape ; V11 = G11 ),
    check('and two characters are no character', V11, shape).

%% ---- ISO's names --------------------------------------------------------

iso_names(D) :-
    section('ISO''s names over the same table'),
    path(D, 'iso.txt', F),
    answer(( open(F, write, S1), write(S1, f('A b', "x")), nl(S1), writeq(S1, 'A b'), nl(S1),
             print(S1, [1, 2]), nl(S1), write_canonical(S1, 'A' + b), nl(S1),
             write_term(S1, g('Y'), [quoted(true)]), nl(S1), format(S1, "~a=~d~n", [n, 42]),
             tab(S1, 2), put_char(S1, x), nl(S1), close(S1),
             read_file_to_codes(F, C1), atom_codes(A1, C1) ), A1, G1),
    check('write/2, writeq/2, print/2, write_canonical/2, write_term/3, nl/1, tab/2, put_char/2, and format/3 into a stream', G1,
          'f(A b,[120])\n\'A b\'\n[1,2]\n\'A\'+b\ng(\'Y\')\nn=42\n  x\n'),
    answer(( open(F, write, S2), with_output_to(S2, ( write(captured), nl )), close(S2),
             read_file_to_codes(F, C2), atom_codes(A2, C2) ), A2, G2),
    check('with_output_to/2 takes a stream as its sink', G2, 'captured\n'),
    answer(( open(F, read, S3), get_char(S3, C3a), peek_char(S3, C3b), get_char(S3, C3c), close(S3) ), C3a-C3b-C3c, G3),
    check('get_char/2 and peek_char/2', G3, c-a-a),
    answer(( open(F, read, S4), read_line_to_codes(S4, L4), read_line_to_string(S4, E4), close(S4), atom_codes(A4, L4) ), A4-E4, G4),
    check('read_line_to_codes/2 and read_line_to_string/2, end_of_file after the last', G4, captured-end_of_file),
    answer(( open(F, read, S5), read_stream_to_codes(S5, C5), ( at_end_of_stream(S5) -> E5 = at ; E5 = not ), close(S5) ), C5-E5, G5),
    check('read_stream_to_codes/2 reads the rest, and at_end_of_stream/1 follows', G5, "captured\n"-at),
    answer(( path(D, 'iso.bin', FB), open(FB, write, S6, [type(binary)]), put_byte(S6, 7), put_byte(S6, 200), close(S6),
             open(FB, read, S7, [type(binary)]), get_byte(S7, B7a), peek_byte(S7, B7b), get_byte(S7, B7c), get_byte(S7, B7d), close(S7) ),
           B7a-B7b-B7c-B7d, G7),
    check('put_byte/2, get_byte/2, peek_byte/2, and -1 past the end', G7, 7-200-200-(-1)),
    answer(( open(F, read, S8), set_stream_position(S8, 3), get_char(S8, C8), close(S8) ), C8, G8),
    check('set_stream_position/2 takes the byte offset stream_position/2 answers', G8, t),
    answer(open(F, read, notvar), ok, G9), ball(G9, B9),
    check('open/3 with its stream bound is uninstantiation_error, as ISO''s corrigendum says', B9, uninstantiation_error(notvar)),
    answer(( open(F, read, S10), catch(write(S10, x), E10, true), close(S10) ), E10, G10),
    ( G10 = error(permission_error(output, stream, '$stream'(_)), _) -> V10 = shape ; V10 = G10 ),
    check('write/2 to an input stream is permission_error(output, stream, S)', V10, shape),
    answer(( open(F, write, S11), close(S11), catch(format(S11, "x", []), E11, true) ), E11, G11),
    ( G11 = error(existence_error(stream, '$stream'(_)), _) -> V11 = shape ; V11 = G11 ),
    check('format/3 into a closed stream is existence_error(stream, S)', V11, shape),
    answer(( path(D, 'iso2.bin', FB2), open(FB2, write, S12, [type(binary)]), catch(format(S12, "x", []), E12, true), close(S12) ), E12, G12),
    ( G12 = error(permission_error(output, binary_stream, '$stream'(_)), _) -> V12 = shape ; V12 = G12 ),
    check('and into a binary one is permission_error(output, binary_stream, S)', V12, shape).

%% ---- aliases ----------------------------------------------------------

aliases(D) :-
    section('aliases: open/4''s alias(A), and the atom as the stream'),
    path(D, 'alias.txt', F),
    answer(( open(F, write, _, [alias(log)]), format(log, "one~n", []), write(log, two), nl(log),
             with_output_to(log, write(three)), close(log),
             read_file_to_codes(F, C1), atom_codes(A1, C1) ), A1, G1),
    check('format/3, write/2, nl/1 and with_output_to/2 all take the alias', G1, 'one\ntwo\nthree'),
    answer(( open(F, read, S2, [alias(src)]), stream_property(S2, alias(A2)), read_line_to_codes(src, L2), close(src), atom_codes(T2, L2) ), A2-T2, G2),
    check('stream_property/2 answers the alias, and reading by it reads the stream', G2, src-one),
    answer(format(log, "x", []), ok, G3), ball(G3, B3),
    check('a closed stream''s alias is gone: format/3 raises domain_error(output_sink, A) as for any atom', B3, domain_error(output_sink, log)),
    answer(( open(F, read, _, [alias(twice)]), catch(open(F, read, _, [alias(twice)]), E4, true), close(twice) ), E4, G4), ball(G4, B4),
    check('an alias in use is permission_error(open, source_sink, alias(A))', B4, permission_error(open, source_sink, alias(twice))),
    answer(open(F, read, _, [alias(user_output)]), ok, G5), ball(G5, B5),
    check('and so is a standard one', B5, permission_error(open, source_sink, alias(user_output))).

%% ---- the current input and output -------------------------------------

current_io(D) :-
    section('the current input and output'),
    path(D, 'cur.txt', F), path(D, 'cur.pl', P),
    answer(( current_input(I), current_output(O) ), I-O, G1),
    check('the standard ones at the start', G1, '$stream'(0)-'$stream'(1)),
    answer(( open(F, write, S2), set_output(S2), write(through_write1), nl, format("and format/2 ~w~n", [too]),
             put_char(S2, '!'), nl, current_output(O2), set_output(user_output), close(S2),
             read_file_to_codes(F, C2), atom_codes(A2, C2), ( O2 == S2 -> Cur2 = current ; Cur2 = O2 ) ), A2-Cur2, G2),
    check('set_output/1 sends the engine''s own write/1, nl/0 and format/2 to the file, in order with the stream''s', G2,
          'through_write1\nand format/2 too\n!\n'-current),
    answer(( open(F, write, S3), set_output(S3), write(x), close(S3), current_output(O3),
             read_file_to_codes(F, C3), atom_codes(A3, C3) ), A3-O3, G3),
    check('closing the current output makes user_output current again', G3, x-'$stream'(1)),
    answer(( open(P, write, S4), write(S4, 'first(1).'), nl(S4), write(S4, 'second(2).'), nl(S4), close(S4),
             open(P, read, S5), set_input(S5), read(T5a), read_term(T5b, []), read(T5c), set_input(user_input), close(S5) ), T5a-T5b-T5c, G4),
    check('set_input/1, then read/1 and read_term/2 read the current input', G4, first(1)-second(2)-end_of_file),
    answer(( open(F, write, S6, [type(binary)]), catch(set_output(S6), E6, true), close(S6) ), E6, G6),
    ( G6 = error(permission_error(output, binary_stream, '$stream'(_)), _) -> V6 = shape ; V6 = G6 ),
    check('set_output/1 to a binary stream is refused, since the engine writes text', V6, shape),
    cocolog(C),
    sh_join([C, ' query "use_module(library(stream)), open(''', F, ''', write, S), set_output(S), format(user_output, \\"answer(terminal)~n\\", []), write(in_file), set_output(user_output), close(S)" 2>/dev/null'], Cmd7),
    proc_run(Cmd7, 60000, Out7, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out7, A7) -> sub_atom(A7, 7, _, 1, G7a) ; G7a = '' ),
    read_file_to_codes(F, C7), atom_codes(F7, C7),
    check('user_output named explicitly still reaches the terminal while a file is the current output', G7a-F7, terminal-in_file).

%% ---- read_term/3's options -----------------------------------------------

read_options(D) :-
    section('read_term/3: variable_names, singletons, variables, and a syntax error'),
    path(D, 'opts.pl', P),
    answer(( open(P, write, S0), write(S0, 'p(X, Y, _Z, X) :- q(Y, W).'), nl(S0), write(S0, 'broken( .'), nl(S0), close(S0),
             open(P, read, S1), read_term(S1, T1, [variable_names(Ns), singletons(Ss), variables(Vs)]),
             catch(read(S1, _), E1, true), close(S1),
             Ns = [X1 = VX, Y1 = VY, Z1 = _, W1 = VW], length(Vs, NV), Ss = [SN = SV],
             ( T1 = (p(VX, VY, _, VX) :- q(VY, VW)) -> Shape = same ; Shape = T1 ),
             ( SV == VW -> SVar = w ; SVar = SV ),
             ( E1 = error(syntax_error(M1), _), atom(M1) -> Err = syntax_error ; Err = E1 ) ),
           X1-Y1-Z1-W1-NV-SN-SVar-Shape-Err, G1),
    check('names in the order they appear, _Z among them; W the one singleton; four variables; then a syntax error in ISO''s shape', G1,
          'X'-'Y'-'_Z'-'W'-4-'W'-w-same-syntax_error).

%% ---- codes, which are bytes ----------------------------------------------

codes(D) :-
    section('codes, as cocolog counts them: bytes'),
    path(D, 'codes.txt', F),
    answer(( open(F, write, S1), put_code(S1, 97), put_code(S1, 8364), put_code(S1, 233), close(S1),
             read_file_to_codes(F, C1) ), C1, G1),
    check('put_code/2: a byte below 256, the UTF-8 of a code point above', G1, [97, 226, 130, 172, 233]),
    answer(( open(F, read, S2), get_code(S2, K2a), peek_code(S2, K2b), get_code(S2, K2c), close(S2) ), K2a-K2b-K2c, G2),
    check('get_code/2 and peek_code/2 read one byte, as atom_codes/2 counts', G2, 97-226-226),
    answer(( open(F, write, S3), catch(put_code(S3, -1), E3, true), close(S3) ), E3, G3), ball(G3, B3),
    check('a negative code is representation_error(character_code)', B3, representation_error(character_code)).

%% ---- the sink: what the engine does with no module, and cell 0 -------------

sinks :-
    section('format/3''s sink without the module, and the cell-zero sentinel'),
    cocolog(C),
    %% A QUERY'S FIRST TERM IS HEAP CELL 0, and format/2's "plain stdout" was
    %% cell index 0 until 1.8.34: this atom took that path and printed.
    sh_join([C, ' query "catch(format(nosuch_sink, x, []), error(E, _), true), write(answer(E)), nl" 2>/dev/null'], Cmd1),
    proc_run(Cmd1, 60000, Out1, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out1, A1) -> sub_atom(A1, 7, _, 1, G1) ; G1 = '' ),
    check('an unknown atom sink raises even as a query''s first term', G1, 'domain_error(output_sink,nosuch_sink)'),
    sh_join([C, ' query "format(''~w~n'', [plain]), format(atom(A), ''~w'', [a]), write(answer(A)), nl" 2>/dev/null'], Cmd2),
    proc_run(Cmd2, 60000, Out2, _),
    ( re_first_atom('plain', Out2, _), re_first_atom('answer\\([^\n]*\\)', Out2, A2) -> sub_atom(A2, 7, _, 1, G2) ; G2 = Out2 ),
    check('format/2 still prints, and atom(A) still captures, with no module loaded', G2, a).
