%  write_term/2,3's partial(true) as swipl 9.0.4's pl-write.c begins a
%  write (cocolog 3.56.0): after the last character written where the
%  write goes, its first token taking a space where the two would read as
%  one, as swipl's PutOpenToken() asks the stream's lastc, which
%  partial(false) sets to none. Where the write goes: the console's
%  user_output or user_error, each its own last character; a capture
%  (with_output_to/2, format/3 into a term), from none at its start and
%  its own while it runs, the console's or the outer capture's again after
%  it; a file of library(stream), in any encoding; and format's own text
%  before `~W', or none after a fill point, where swipl's text is a
%  sub-format's. A string's unquoted text clears the gap a failed portray
%  goal's text leaves, as swipl's PutString makes no token check. Run by
%  BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  Through 3.55.0 partial(B) was checked and read past: every write began
%  at no character, so `a' and then partial(true)'s `b' wrote `ab' where
%  swipl writes `a b'; and a string's text after a failed goal's took a
%  space before it (`pg s', swipl's `pgs').
%
%  The file is ASCII, every name past it an escape, and so is every line
%  printed: what a capture or a file holds is shown as its codes, each past
%  ASCII or below the space as `<hex>'. Not held here: a write to
%  user_output by name inside with_output_to/2's goal, which cocolog
%  captures with the current output where swipl's goes to the console
%  (COMPAT.md); and a variable's name, `_123' in swipl and `_G123' in
%  cocolog.

:- set_prolog_flag(double_quotes, string).
:- discontiguous c/2.

%  SWI has write_term/3 built in, cocolog from library(stream)
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

main :- forall(member(S, [console, stderr, capture, files, format, gaps]), run(S)).

run(S) :- write(S), nl, forall(nth1_c(S, N, G), (write(N), write(': '), case(S, G))).

nth1_c(S, N, G) :- findall(G0, c(S, G0), Gs), nth1(N, Gs, G).

%  the console's cases write where they stand, after `N: '; the rest are
%  shown as what they captured or read back
case(console, G) :- !, catch(( G -> true ; write(failed) ), E, report(E)), write('|'), nl.
case(stderr, G) :- !, flush_output, catch(( G -> true ; write(failed) ), E, report(E)),
    format(user_error, "|~n", []), write('|'), nl.
case(_, G) :- show(G).

%  the goal's text, or the error it raised
show(G) :-
    catch(( with_output_to(codes(Cs), G) -> out(Cs) ; write(failed) ), E, report(E)),
    nl.

% cocolint: C2 -- the context printed, of errors both systems name alike
report(error(F, context(P, _))) :- !, write('error '), print(F), write(' in '), writeq(P).
report(E) :- write('caught '), print(E).

out([]).
out([C|Cs]) :- ( C >= 32, C < 127 -> put_char_code(C) ; format("<~16r>", [C]) ), out(Cs).

put_char_code(C) :- char_code(Ch, C), put_char(Ch).

p(T) :- write_term(T, [partial(true)]).
pq(T) :- write_term(T, [partial(true), quoted(true)]).

%  a portray goal that writes and declines
pg(_, _) :- write(pg), fail.

%  a file's bytes, written by G of the stream opened with Os
file(Os, G) :-
    tmp_file(wp, F),
    open(F, write, S, Os), call(G, S), close(S),
    open(F, read, In, [type(binary)]), get_byte(In, B0), bytes(B0, In, Bs), close(In),
    delete_file(F), out(Bs).

bytes(-1, _, []) :- !.
bytes(B, In, [B|Bs]) :- get_byte(In, B1), bytes(B1, In, Bs).

%  ---- the console: the write begins after user_output's last character
c(console, (write(a), p(b))).
c(console, (write(a), nl, p(b))).
c(console, (write('a '), p(b))).
c(console, p(b)).
c(console, (write(+), p(-))).
c(console, (write(+), p(1))).
c(console, (write(-), p(- 1))).
c(console, (write(-), p(-(a)))).
c(console, (write(1), p(a))).
c(console, (write(1), p(2))).
c(console, (write(1), p(-2))).
c(console, (write(a), p(-(1)))).
c(console, (write(a), p(- a))).
c(console, (write(a), p('A'))).
c(console, (write(a), p('_x'))).
c(console, (write(a), p([]))).
c(console, (write(a), p('[]'))).
c(console, (write(a), p({x}))).
c(console, (write(a), p(f(x)))).
c(console, (write(a), p(1.5))).
c(console, (write(a), p(a:b))).
c(console, (write(a), p((:- a)))).
c(console, (write(0), p(a))).
c(console, (write(','), p(a))).
c(console, (write('|'), p('|'))).
c(console, (write(a), write_term((a,b), [partial(true), priority(999)]))).
c(console, (write('('), write_term((a,b), [partial(true), priority(999)]))).
c(console, (write(' '), write_term((a,b), [partial(true), priority(999)]))).
c(console, (write(a), pq('b c'))).
c(console, (write(''''), pq(''''))).
c(console, (write('"'), atom_string(s, S), pq(S))).
c(console, (write(0), pq('''a'''))).
c(console, (write(a), atom_string(s, S), p(S))).
c(console, (write(a), write_term(f(x), [partial(true), fullstop(true)]))).
c(console, (write(a), write_term(f(x), [partial(true), portray(true)]))).
c(console, (write(a), write_term(f(x), [partial(true), max_depth(1)]))).
c(console, (write(a), write_term([a], [partial(true), max_depth(1)]))).
c(console, (write(a), write_term('$VAR'(1), [partial(true), numbervars(true)]))).
c(console, (write(a), p(1r3))).
c(console, (write(1), p(1r3))).
%  partial(false), the last said standing, and the writers with no partial
c(console, (write(a), write_term(b, [partial(false)]))).
c(console, (write(a), write_term(b, [partial(true), partial(false)]))).
c(console, (write(a), write_term(b, [partial(false), partial(true)]))).
c(console, (write(a), write_term(b, [partial]))).
c(console, (write(a), print(b))).
c(console, (write(a), writeq(b))).
c(console, (write(a), write_canonical(b))).
c(console, (write(a), format("~w", [b]))).
%  the console's last character, kept across a capture and set by
%  write_term/3 of user_output, the current output and a format to it
c(console, (write(a), with_output_to(string(_), write(x)), p(b))).
c(console, (write('('), with_output_to(string(_), write(x)), p(b))).
c(console, (write(a), write_term(user_output, b, [partial(true)]))).
c(console, (write(user_output, a), write_term(user_output, b, [partial(true)]))).
c(console, (current_output(S), write(S, a), write_term(S, b, [partial(true)]))).
c(console, (write(a), format("~W", [b, [partial(true)]]))).
c(console, (write(a), format(user_output, "~W", [b, [partial(true)]]))).
c(console, (write(a), format("x~W", [b, [partial(true)]]))).
c(console, (write(a), format(atom(A), "~W", [b, [partial(true)]]), write(A))).

%  ---- user_error: its own last character, user_output's beside it
c(stderr, (format(user_error, "a", []), write_term(user_error, b, [partial(true)]))).
c(stderr, (format(user_error, "a", []), format(user_error, "~W", [b, [partial(true)]]))).
c(stderr, (format(user_error, "(", []), write_term(user_error, b, [partial(true)]))).
c(stderr, (format(user_error, "a", []), p(b))).
c(stderr, (write(a), flush_output, format(user_error, "(", []), p(b))).
c(stderr, (write('('), flush_output, format(user_error, "a", []), write_term(user_error, b, [partial(true)]))).

%  ---- a capture: from none at its start, its own while it runs, and the
%  outer one's again after an inner one
c(capture, p(b)).
c(capture, (write(a), p(b))).
c(capture, (write('\xE9\'), p(b))).
c(capture, (write('\x2200\'), p(+))).
c(capture, (write(a), p('\x3B1\'))).
c(capture, (write('\x3B1\'), p(b))).
c(capture, (write('\x3B1\'), p(+))).
c(capture, (write(+), p('\x2200\'))).
c(capture, (write('\xE9\'), pq('b c'))).
c(capture, (with_output_to(string(_), write(x)), with_output_to(string(S), p(b)), write(S))).
c(capture, (write(a), with_output_to(string(S), p(b)), write(S))).
c(capture, (write(a), with_output_to(string(_), write('(')), p(b))).
c(capture, (write('('), with_output_to(string(S), (write(a), with_output_to(string(T), (write(x), p(y))), write(T), p(b))), write(S))).
c(capture, (write(a), format(atom(A), "~W", [b, [partial(true)]]), write(A))).
c(capture, (format(atom(A), "~a~W", [x, b, [partial(true)]]), write(A))).
c(capture, (format(codes(Cs), "~W", [b, [partial(true)]]), atom_codes(A, Cs), write(A))).
c(capture, (format(string(S), "~a~W", ['\xE9\', b, [partial(true)]]), write(S))).
c(capture, (write(a), format("~@~W", [write(x), b, [partial(true)]]))).
c(capture, (write(a), format("~W~W", [b, [partial(true)], c, [partial(true)]]))).

%  ---- a file: its own last character, in its encoding
c(files, file([], [S]>>(write(S, a), write_term(S, b, [partial(true)])))).
c(files, file([], [S]>>write_term(S, b, [partial(true)]))).
c(files, file([], [S]>>(write(S, a), nl(S), write_term(S, b, [partial(true)])))).
c(files, file([], [S]>>(put_char(S, a), write_term(S, b, [partial(true)])))).
c(files, file([], [S]>>(put_char(S, +), write_term(S, -, [partial(true)])))).
c(files, file([], [S]>>(put_code(S, 0'a), write_term(S, b, [partial(true)])))).
c(files, file([], [S]>>(format(S, "~w", [a]), write_term(S, b, [partial(true)])))).
c(files, file([], [S]>>(write(S, a), format(S, "~W", [b, [partial(true)]])))).
c(files, file([], [S]>>(print(S, a), write_term(S, b, [partial(true)])))).
c(files, file([], [S]>>(writeq(S, 'a b'), write_term(S, c, [partial(true)])))).
c(files, file([], [S]>>(write(S, a), tab(S, 0), write_term(S, b, [partial(true)])))).
c(files, file([], [S]>>(write(S, a), write_term(S, b, [partial(true)]), write_term(S, c, [partial(true)])))).
c(files, file([], [S]>>(write(S, a), write_term(S, b, [partial(false)])))).
c(files, file([encoding(utf8)], [S]>>(write(S, '\xE9\'), write_term(S, b, [partial(true)])))).
c(files, file([encoding(utf8)], [S]>>(write(S, '\x2200\'), write_term(S, +, [partial(true)])))).
c(files, file([alias(wpa)], [_]>>(write(wpa, a), write_term(wpa, b, [partial(true)])))).
c(files, file([encoding(iso_latin_1)], [S]>>(write(S, '\xE9\'), write_term(S, b, [partial(true)])))).
c(files, file([encoding(iso_latin_1)], [S]>>(write(S, a), write_term(S, b, [partial(true)])))).
c(files, file([encoding(utf16be)], [S]>>(write(S, a), write_term(S, b, [partial(true)])))).
c(files, file([encoding(utf16le)], [S]>>(write(S, '\x3B1\'), write_term(S, b, [partial(true)])))).
c(files, file([encoding(utf16be)], [S]>>(write(S, '('), write_term(S, b, [partial(true)])))).
c(files, file([type(binary)], [S]>>(put_byte(S, 97), write_term(S, b, [partial(true)])))).
%  a stream opened where another was closed begins at none
c(files, (file([], [S]>>write(S, a)), file([], [S2]>>write_term(S2, b, [partial(true)])))).

%  ---- format's text: `~W' begins after the text before it, or after
%  none past a fill point, until the column stop puts it out
c(format, format("x~t~W~2|", [b, [partial(true)]])).
c(format, (write(a), format("~t~W~1|", [b, [partial(true)]]))).
c(format, format("~tx~W~2|", [b, [partial(true)]])).
c(format, format("y~tx~W~2|", [b, [partial(true)]])).
c(format, format("a~t~5|~W", [b, [partial(true)]])).
c(format, format("a~5|~W", [b, [partial(true)]])).
c(format, format("a~t~W~t~5|", [b, [partial(true)]])).
c(format, format("a~t~a~W~t~5|", [x, b, [partial(true)]])).
c(format, format("~a~t~W~2+", [x, b, [partial(true)]])).
c(format, format("a~2|~W", [b, [partial(true)]])).
c(format, format("a~1|~W", [b, [partial(true)]])).
c(format, format("~t~w~W~3|", [a, b, [partial(true)]])).
c(format, format("~w~W~3|", [a, b, [partial(true)]])).
c(format, format("~w~W~3+", [a, b, [partial(true)]])).
c(format, format("~t~w~3|~w~W", [a, x, b, [partial(true)]])).
c(format, format("~w~t~3|~W", [a, b, [partial(true)]])).
c(format, format("~w~W~t~5|", [a, b, [partial(true)]])).
c(format, format("~w~t~W", [a, b, [partial(true)]])).
c(format, format("~w~t~w~W", [a, x, b, [partial(true)]])).
c(format, format("a~t~@~W~5|", [write(x), b, [partial(true)]])).
c(format, format("~d~W", [1, 2, [partial(true)]])).
c(format, format("~w~W", [-, - 1, [partial(true)]])).
c(format, format("~c~W", [0'a, b, [partial(true)]])).

%  ---- a failed portray goal's gap, which a goal's text and a string's
%  clear: `pgs', where a quoted string and an atom take one
c(gaps, (atom_string(s, S), write_term(S, [portray_goal(pg)]))).
c(gaps, (atom_string(s, S), write_term(f(S), [portray_goal(pg)]))).
c(gaps, (atom_string(s, S), write_term(S+1, [portray_goal(pg)]))).
c(gaps, (atom_string(s, S), write_term([S], [portray_goal(pg)]))).
c(gaps, (atom_string(s, S), write_term(-S, [portray_goal(pg)]))).
c(gaps, (atom_string('(s', S), write_term(S, [portray_goal(pg)]))).
c(gaps, (atom_string(s, S), write_term(S, [portray_goal(pg), quoted(true)]))).
c(gaps, write_term(s, [portray_goal(pg)])).
c(gaps, (write(a), atom_string(s, S), write_term(S, [portray_goal(pg), partial(true)]))).
c(gaps, (write(a), write_term(s, [portray_goal(pg), partial(true)]))).
