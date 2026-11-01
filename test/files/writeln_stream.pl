%  writeln/2, run by BOTH SWI-Prolog and cocolog and the output compared
%  byte for byte: write/2 and then a newline, to a stream or an alias --
%  numbervars as write/1 has them, operators, a string, a float, a file
%  read back by lines -- and the stream refused as write/2 refuses it. SWI
%  has it built in; cocolog from library(stream) (3.9.0). The refusals are
%  compared by their formal term alone: the context library(stream) gives
%  is its own (STATUS.md, `library(stream)'s errors').

:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

refused(Label, Goal) :-
    catch(( Goal, R = yes ), error(F, _), R = ex(F)),
    print(Label-R), nl.

main :-
    writeln(user_output, hello),
    writeln(user_output, 'a b'),
    atom_string(str, S), writeln(user_output, S),
    writeln(user_output, '$VAR'(1)),
    writeln(user_output, [1, 2]),
    writeln(user_output, - 1),
    writeln(user_output, 1 + 2 * 3),
    writeln(user_output, 1.0Inf),
    writeln(user_output, 0.1),
    File = 'writeln_out.txt',
    open(File, write, Out),
    writeln(Out, first),
    writeln(Out, g('Q', S)),
    close(Out),
    open(File, read, In),
    read_line_to_codes(In, L1), read_line_to_codes(In, L2), read_line_to_codes(In, L3),
    close(In),
    atom_codes(A1, L1), atom_codes(A2, L2), print(file(A1, A2, L3)), nl,
    refused(unbound, writeln(_, x)),
    refused(unknown, writeln(no_such_stream, x)),
    refused(number, writeln(1, x)),
    writeln(done).
