%  read_term/3 from a stream: what a clause that will not read raises.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  Through 3.10.1 cocolog raised error(syntax_error(Message), read_term/3)
%  with a sentence of its own, and its scanner put the end of a clause
%  elsewhere than swipl's raw read after an octal or hex escape's closing
%  backslash ('\x41\''), a radix's quote (16'ff) and 0'''. swipl's term is
%  error(syntax_error(Id), file(File, Line, LinePos, CharNo)) for a stream
%  of a file -- the place a load gives the error, and CharNo the characters
%  before it -- and stream(S, 0, 1, 0) for a block comment open before
%  anything. After the error the stream stands after the clause's full
%  stop, or at its end, and the next read goes on from there. Each file is
%  read to its end: every term, every error and the character the stream
%  reads next, and print_message/2's words for the first error of each.
%
%  The input is written as bytes, the same in both systems; an @ in a line
%  below is the two bytes of an e acute.

%  SWI has open/4 built in, cocolog from library(stream); a condition
%  cocolog decides while reading is one about the store
:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

%  a parse error on a clause's first line, on a later line of it, in a
%  clause that begins part way along a line, and after an e acute on the
%  error's line and on an earlier one
input('t1.pl', [ "foo(a b).", "bar.", "  baz(1,", "   2 3).", "q(x :- .", "ok.",
                 "m(1,", "  2 x).", "a. b c.", "e('@') x.", "f('@',", " '@@' y).", "end." ]).
%  what the raw read refuses at the end: a quoted item open, a block
%  comment open (inside a clause, and before anything), no full stop, a
%  full stop alone
input('t2.pl', [ "p(1).", "\"abc" ]).
input('t3.pl', [ "p(1).", "f(/* a" ]).
input('t4.pl', [ "p(1).", "/* abc" ]).
input('t5.pl', [ "p(1).", "  .", "q." ]).
input('t6.pl', [ "p(1).", "foo(" ]).
%  where a clause ends: after an escape's closing backslash (and a quote
%  after that one, which doubles the next), a radix's quote, 0''', a full
%  stop inside a quoted atom and a comment, a full stop before a comment,
%  and two clauses on a line
input('t7.pl', [ "a('\\x41\\').", "o('\\x41\\'').","b(16'ff). c(0''').", "d('x. y'). % e. f", "g.% h", "i.",
                 "'.", "j(k). l(m).", "n." ]).
%  the reasons a load gives, read from a stream
input('t8.pl', [ "s1d(f(,)).", "s1e([1,2).", "s1f :- .", "s1j([a|b|c]).", "s1k(- - -).",
                 "s1l :- :- m.", "s1n(\"abc\\q\").", "s1p({a).", "s1q(a)).", "  )foo.",
                 "/* c1 */ s1s(2) c.", "s1t(2,", " /* x", " y */ 3 4).", "s1u(a :- b :- c).",
                 "s1v(a = = b).", "s1w('\\x').", "s1y(1.0e400).", "s1z(1.0NaN).", "s1zz(2)." ]).
%  a 0' at the end, and a radix's quote at the end
input('t9.pl', [ "p(1).", "  x :- 0'" ]).
input('t10.pl', [ "p(1).", "  x :- 16'" ]).

%  and the end of the file cutting a clause short where no newline ends it:
%  a whole term, a comment, a quoted atom, a code
raw('t11.pl', "p.\nc(3)").
raw('t12.pl', "x % c").
raw('t13.pl', "p.\n'a'").
raw('t14.pl', "q :- 0'a").

write_input(F, Ls) :-
    open(F, write, S, [type(binary)]),
    forall(member(L, Ls), ( forall(member(B, L), wb(S, B)), put_byte(S, 10) )),
    close(S).

wb(S, 0'@) :- !, put_byte(S, 195), put_byte(S, 169).
wb(S, B) :- put_byte(S, B).

%  where the stream stands: the character it reads next
at(S, next(C)) :- peek_char(S, C).

%  the stream of a stream(S, ...) context is said as `same' when it is the
%  one read, as every Prolog names a stream its own way
said(S, error(E, stream(S1, L, LP, C)), error(E, stream(Same, L, LP, C))) :- !,
    ( S1 == S -> Same = same ; Same = other(S1) ).
said(_, E, E).

read_all(S, Said0) :-
    catch(read_term(S, T, []), E, true),
    at(S, At),
    (   nonvar(E)
    ->  said(S, E, Said), writeq(Said-At), nl,
        ( Said0 == no -> print_message(error, E) ; true ),
        read_all(S, yes)
    ;   T == end_of_file
    ->  writeq(eof-At), nl
    ;   writeq(T-At), nl,
        read_all(S, Said0)
    ).

write_raw(F, Cs) :-
    open(F, write, S, [type(binary)]),
    forall(member(B, Cs), wb(S, B)),
    close(S).

read_file(F) :-
    writeq(file(F)), nl,
    open(F, read, S, [encoding(utf8)]),
    read_all(S, no),
    close(S).

main :-
    forall(input(F, Ls), ( write_input(F, Ls), read_file(F) )),
    forall(raw(F, Cs), ( write_raw(F, Cs), read_file(F) )).
