%  read_term/3's subterm_positions and term_position.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  Through 1.10.6 cocolog accepted both options and bound nothing. Every
%  shape SWI answers is here -- From-To, string_position,
%  term_position (functional notation, prefix and infix operators),
%  list_position with a tail and without, brace_term_position,
%  parentheses_term_position -- with comments, a tab (to the next eighth
%  column), a CR (back to column 0), a two-byte character (a position
%  counts characters, the fourth field of '$stream_position' bytes), and
%  reads of other kinds between two read_terms, which the count must
%  follow. Only positions are written: a term with variables is written
%  differently by every Prolog. At the end of the file SWI puts
%  end_of_file one character before the end, with a column of -1 when the
%  file ends in a newline; cocolog puts it at the end. So only the length
%  of its span, the eleven characters of its name in both, is written
%  there.
%
%  The input is written as bytes, the same in both systems; an @ in a line
%  below is the two bytes of an e acute.

%  SWI has open/4 built in, cocolog from library(stream); a condition
%  cocolog decides while reading is one about the store
:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

line("% a comment with an e acute: @").
line("foo(X, bar) :- X = [1, 2|T], T = \"ab\", {a, b}, - 1, -1, (a ; b), 'q a'(x).").
line("  hello.").
line("p(\"@\") :- f(x), ( a ).").
line("q :- [a, b], [], {}, a- (-), - (1), f(- 1), \"\", 0'c, 1.5e3, X = f(Y), Y.").
line("\tb.").
line("/* ab\r*/\tc.").
line("  /* c */ d(/* x */ e) .").
line("f([ ], { }, -(1), - 1.5, -1.5, (-), [a|[]], f((a,b))).").
line("g :- \\+ a, x = - , y = (a:-b), - - a, a=..b, [x|Y], \"x y\".").
line("h(A) --> [a], {A = 1}, !.").
line("k :- a -> b ; c.   m. n.").
line("r(X) :-").
line("    s(X),").
line("\tt(X).").
line("'@'(1).  last.").
line("% a trailing comment").

write_input(F) :-
    findall(L, line(L), Ls),
    open(F, write, S, [type(binary)]),
    forall(member(L, Ls), ( forall(member(B, L), wb(S, B)), put_byte(S, 10) )),
    close(S).

wb(S, 0'@) :- !, put_byte(S, 195), put_byte(S, 169).
wb(S, B) :- put_byte(S, B).

show(S) :-
    read_term(S, T, [subterm_positions(SP), term_position(P), variable_names(Vs)]),
    (   T == end_of_file
    ->  SP = F-E, P = '$stream_position'(C, _, _, _), D is E - F, Same is C - F,
        writeq(end_of_file(D, Same)), nl
    ;   findall(N, member(N=_, Vs), Ns),
        writeq(P), nl, writeq(SP), nl, writeq(Ns), nl
    ).

main :-
    write_input('in.pl'),
    open('in.pl', read, S, [encoding(utf8)]),
    show(S), show(S), show(S), show(S), show(S),
    %  one option alone, then neither, then a character and a code taken
    %  by hand: the count follows every read
    read_term(S, _, [term_position(P1)]), writeq(P1), nl,
    read_term(S, _, [subterm_positions(SP2)]), writeq(SP2), nl,
    read(S, _),
    peek_char(S, C1), get_char(S, C2), peek_code(S, C3), get_code(S, C4),
    writeq([C1, C2, C3, C4]), nl,
    show(S), show(S), show(S), show(S), show(S), show(S), show(S), show(S),
    show(S), show(S),
    close(S).
