%% A load past syntax errors, held to swipl 9.0.4 (cocolog 3.10.0). The
%% files are test/files.pl's fixtures(syntax_load, _).
%%
%% Each error is reported on one line, FILE:LINE:COL and swipl's sentence
%% for its id (messages.pl's syntax_error//1: `Operator expected',
%% `Unbalanced operator', `Unexpected end of clause', `Illegal start of
%% term'), and the load goes on past the clause. The place is where swipl
%% puts it: it walks the clause's raw text from one column past its first
%% character for one character less than the error's place, so an error on
%% the clause's first line is at the token's column and one on a later line
%% a column short of it (`s1g(x\n  y).' is at 7:1); what the raw read
%% refuses -- a quoted item or a block comment open at the end of the file,
%% a full stop alone -- is at the clause's first column plus one, a clause
%% with no full stop before the end is end_of_file at its last character,
%% and a block comment that opens before anything is read is at 0:1.
%% Through 3.9.0 the words were cocolog's (`expected a term') and every
%% place was the token's own.
%%
%% Each file is consulted and the clauses either side of its errors are
%% asked for.

loads(F, Goals) :-
    catch(consult(F), E, ( print(raised(E)), nl )),
    flush_output,
    findall(G, ( member(G, Goals), catch(G, _, fail) ), L),
    print(F-L), nl, flush_output.

main :-
    loads('s1.pl', [s1a(_), s1r(_), s1zz(_)]),
    loads('s2.pl', [s2a(_)]),
    loads('s3.pl', [s3a(_)]),
    loads('s4.pl', [s4c(_)]),
    loads('s5.pl', [s5a(_)]),
    loads('s6.pl', [s6a(_)]),
    loads('s7.pl', [s7a(_)]),
    loads('s8.pl', [s8a(_)]),
    loads('s9.pl', [s9a(_)]),
    loads('s10.pl', [s10a(_)]),
    loads('s11.pl', [s11a(_)]),
    loads('s12.pl', [s12a(_)]),
    loads('s13.pl', [s13a(_)]),
    loads('s14.pl', [s14a(_)]).
