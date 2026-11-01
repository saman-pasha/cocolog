%  A file's line is its own (cocolog 2.16.0), held to swipl 9.0.4. Run by
%  BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  format/3's `~N' on a file opened with open/3 begins a line only where
%  the file's own last character was no newline -- whatever the console's
%  column -- and print_message_lines/3 writes to the file with the prefix
%  it is given, or a kind's, each beginning a fresh line there. Apart from
%  test/files/print_message.pl because SWI has open/4 built in and cocolog
%  from library(stream), whose loading also takes the console's writes:
%  that case keeps the engine's own.

:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

main :-
    File = 'fresh_line_out.txt',
    open(File, write, S),
    format(user_error, 'console half', []),
    format(S, '~Nfirst', []),
    format(S, '~Nx~N', []),
    format(S, '~Ny~n', []),
    format(S, '~Nz~n', []),
    print_message_lines(S, 'P ', ['one', nl, 'two']),
    write(S, half),
    print_message_lines(S, kind(warning), ['w ~w'-[1]]),
    write(S, half),
    print_message_lines(S, kind(informational), ['i']),
    print_message_lines(S, kind(help), ['h', nl, 'h2']),
    format(S, 'end', []),
    format(S, '~N', []),
    close(S),
    format(user_error, '~N[the file]~n', []),
    open(File, read, R),
    fl_chars(R, Cs),
    close(R),
    atom_chars(A, Cs),
    format(user_error, '~q~n', [A]),
    delete_file(File).

fl_chars(R, Cs) :-
    get_char(R, C),
    (   C == end_of_file
    ->  Cs = []
    ;   Cs = [C|Cs1],
        fl_chars(R, Cs1)
    ).
