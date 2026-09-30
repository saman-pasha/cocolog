%% LIBRARY 48 -- library(stream): files as streams -- bytes, characters, lines,
%% terms and formatted text
%%
%%     ./cocolog run tutorials/library/48-stream.pl main
%%
%% TIER 2: `use_module(library(stream))', a `.so' from `modules/stream'. It
%% needs nothing but a C compiler: `sh modules/stream/build.sh'.
%%
%% BEFORE THIS, A PROGRAM'S ONLY WAY INTO A FILE WAS `read_file_to_codes/2'
%% and its only way out was the shell. A stream is a HANDLE -- '$stream'(N),
%% a slot in the module's table, the shape a socket has in library(tcp) --
%% opened on a path in one of four modes and one of two KINDS:
%%
%%     stream_open(+Path, +Mode, -S)            read | write | append | update; text
%%     stream_open(+Path, +Mode, +Opts, -S)     type(text) or type(binary)
%%     stream_close(+S)   stream_flush(+S)   stream_eof(+S)
%%     stream_position(+S, -Bytes)   stream_seek(+S, +Bytes)   stream_seek(+S, +Off, bof|current|eof)
%%     stream_size(+S, -Bytes)   stream_property(?S, ?P)
%%     stream_input(-S)  stream_output(-S)  stream_error(-S)      stdin, stdout, stderr
%%
%% and the predicates come in three kinds, as ISO sorts them:
%%
%%     BINARY     stream_get_byte/2  stream_peek_byte/2  stream_put_byte/2
%%                stream_read_bytes/3  stream_write_bytes/2
%%     TEXT       stream_get_char/2  stream_peek_char/2  stream_put_char/2
%%                stream_read_line/2  stream_read_lines/2  stream_write_text/2  stream_nl/1
%%     FORMATTED  stream_format/3  stream_write/2  stream_writeq/2  stream_print/2
%%                stream_write_canonical/2  stream_write_term/3  stream_with_output/2
%%                stream_read_term/2  stream_read_terms/2
%%     EITHER     stream_read_all/2
%%
%% A byte from a text stream, or a character from a binary one, is a
%% permission_error rather than a quiet read of the wrong thing -- which
%% is what the kind is FOR. A character is a UTF-8 character, however
%% many bytes it takes; a line and a whole file come back as CODES, the
%% shape every text predicate in this family takes. FORMATTED output is
%% the engine's own `format/2', `write/1', `writeq/1' and `print/1'
%% spelled into the file, so a file and the terminal never disagree;
%% formatted INPUT is the engine's own reader over one clause at a time,
%% operators and all, so a file this reads is a file cocolog would consult.
%%
%% THIS FILE WRITES TO /tmp AND READS ITSELF BACK, which is the whole
%% argument: nothing below is claimed that the file on disk does not show.

:- use_module(library(stream)).

main :-
    Dir = '/tmp/cocolog-stream-lesson',
    ( exists_directory(Dir) -> true ; make_directory(Dir) ),
    atom_concat(Dir, '/notes.txt', Notes),
    atom_concat(Dir, '/data.bin', Data),
    atom_concat(Dir, '/facts.pl', Facts),

    format("~n-- text: lines out, and lines back in~n"),
    stream_open(Notes, write, W),
    stream_write_text(W, 'first line'), stream_nl(W),
    stream_write_text(W, "second, as codes"), stream_nl(W),
    stream_close(W),
    stream_open(Notes, read, R),
    stream_read_line(R, L1), atom_codes(A1, L1),
    must('the first line, its newline off', A1, 'first line'),
    stream_read_line(R, L2), atom_codes(A2, L2),
    must('the second', A2, 'second, as codes'),
    stream_read_line(R, L3),
    must('and end_of_file after the last', L3, end_of_file),
    stream_close(R),
    stream_open(Notes, append, Ap), stream_write_text(Ap, 'third, appended'), stream_nl(Ap), stream_close(Ap),
    stream_open(Notes, read, R2), stream_read_lines(R2, Lines), stream_close(R2),
    length(Lines, NLines),
    must('append adds a line, and read_lines reads them all', NLines, 3),

    format("~n-- characters, which are UTF-8~n"),
    stream_open(Notes, write, W2), stream_put_char(W2, 'é'), stream_put_char(W2, x), stream_close(W2),
    stream_open(Notes, read, R3),
    stream_get_char(R3, C1), stream_peek_char(R3, C2), stream_get_char(R3, C3), stream_get_char(R3, C4),
    stream_close(R3),
    must('get_char reads a whole character, peek_char leaves it', [C1, C2, C3, C4], ['é', x, x, end_of_file]),
    stream_size_of(Notes, Sz),
    must('two characters, three bytes on disk', Sz, 3),

    format("~n-- binary: bytes, positions, a seek~n"),
    stream_open(Data, write, [type(binary)], B),
    numlist(0, 9, Ns), stream_write_bytes(B, Ns), stream_put_byte(B, 255),
    stream_close(B),
    stream_open(Data, read, [type(binary)], RB),
    stream_get_byte(RB, B0), stream_read_bytes(RB, 3, B123), stream_position(RB, Pos),
    stream_seek(RB, -1, eof), stream_get_byte(RB, Last), stream_get_byte(RB, Past),
    stream_size(RB, Size), stream_close(RB),
    must('get_byte, read_bytes, and where that leaves the position', B0-B123-Pos, 0-[1,2,3]-4),
    must('seek from the end, the last byte, then -1', Last-Past, 255-(-1)),
    must('the size is the file''s', Size, 11),
    stream_open(Data, update, [type(binary)], U),
    stream_seek(U, 5), stream_put_byte(U, 99), stream_close(U),
    stream_open(Data, read, [type(binary)], RB2), stream_read_all(RB2, All), stream_close(RB2),
    must('update writes into the middle of a file', All, [0,1,2,3,4,99,6,7,8,9,255]),
    stream_open(Data, read, [type(binary)], RB3),
    catch(stream_read_line(RB3, _), error(E1, _), true),
    stream_close(RB3),
    must('a line from a binary stream is refused by name', E1, permission_error(input, binary_stream, RB3)),

    format("~n-- formatted: the engine's own spelling, into the file~n"),
    stream_open(Notes, write, W3),
    stream_format(W3, "~w owes ~a ~d euros~n", ['Omar', 'Priya', 40]),
    stream_writeq(W3, 'a quoted atom'), stream_nl(W3),
    stream_write_canonical(W3, point(1, 2) + 3), stream_nl(W3),
    stream_with_output(W3, ( write(anything), write(' a goal prints'), nl )),
    stream_close(W3),
    read_file_to_codes(Notes, Cs), atom_codes(Text, Cs),
    must('format, writeq, write_canonical and a captured goal', Text,
         'Omar owes Priya 40 euros\n\'a quoted atom\'\npoint(1,2)+3\nanything a goal prints\n'),

    format("~n-- terms: a clause at a time, the reader consult uses~n"),
    stream_open(Facts, write, W4),
    stream_format(W4, "% facts a program wrote~n", []),
    forall(member(P, [alice-42, bob-7]), ( P = N-Age, stream_writeq(W4, person(N, Age)), stream_write_text(W4, '.'), stream_nl(W4) )),
    stream_write_text(W4, "adult(X) :- person(X, A), A >= 18.  /* a rule, with a . in a comment */\n"),
    stream_close(W4),
    stream_open(Facts, read, R4),
    stream_read_term(R4, T1), stream_read_term(R4, T2), stream_read_term(R4, T3), stream_read_term(R4, T4),
    stream_close(R4),
    must('two facts', [T1, T2], [person(alice, 42), person(bob, 7)]),
    ( T3 = (adult(V) :- (person(V, VA), VA >= 18)) -> Rule = read ; Rule = T3 ),
    must('a rule with operators, read as consult would read it', Rule, read),
    must('and end_of_file after the comment', T4, end_of_file),
    stream_open(Facts, read, R5), stream_read_terms(R5, Ts), stream_close(R5),
    length(Ts, NTs),
    must('read_terms reads them all', NTs, 3),

    format("~n-- the standard streams are streams too~n"),
    stream_output(Out),
    stream_format(Out, "     this line went through stream_format(user_output, ...)~n", []),
    stream_property(Out, alias(Alias)),
    must('stdout is slot 1, alias user_output', Out-Alias, '$stream'(1)-user_output),
    catch(stream_close(user_output), error(E2, _), true),
    must('and is never closed', E2, permission_error(close, stream, user_output)),

    format("~n-- what goes wrong is an error that names the thing~n"),
    catch(stream_open('/no/such/file', read, _), error(E3, _), true),
    must('no such file', E3, existence_error(source_sink, '/no/such/file')),
    stream_open(Notes, read, R6), stream_close(R6),
    catch(stream_read_line(R6, _), error(E4, _), true),
    must('a closed stream', E4, existence_error(stream, R6)),
    catch(stream_get_byte(not_a_stream, _), error(E5, _), true),
    must('a term that is no stream', E5, domain_error(stream, not_a_stream)),

    format("~ndone~n").

stream_size_of(Path, Size) :- stream_open(Path, read, S), stream_size(S, Size), stream_close(S).

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~q~n", [What, Got])
    ;   format("     ~w = ~q  BUT THIS LESSON SAYS ~q~n", [What, Got, Want]),
        fail
    ).
