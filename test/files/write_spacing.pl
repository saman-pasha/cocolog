%  The spaces a write puts between its tokens, as swipl 9.0.4's pl-write.c
%  puts them (cocolog 3.64.2): one stream keeps the last code written
%  (lastc) for the whole write, and a token takes a space before it where
%  the two would read as one (needSpace()), an infix operator that took
%  one taking one after it too (TRUE_WITH_SPACE). So an operand that
%  writes nothing -- the atom '' and the string "" unquoted -- leaves its
%  operator to ask the code before it, `x= * 1'; a write's start asks none,
%  whatever its buffer held before (format's text before `~w', `a=*1'),
%  where partial(true) goes on from it, `a= * 1'; an operator of a code
%  past U+00FF takes no space after it, as swipl writes such an atom with
%  writeUCSAtom(), which answers no TRUE_WITH_SPACE (`-1 '<2264>'0'); and
%  an unquoted string's text and the `(' of a compound whose name writes
%  nothing ask no token break, as swipl puts both with Putc() (`p qit's',
%  `p q(a)'). write_canonical/1 and `~k' quote an atom past U+00FF
%  (PL_WRT_QUOTE_NON_ASCII). Run by BOTH SWI-Prolog and cocolog, output
%  compared byte for byte.
%
%  Through 3.64.1 each operand's buffer was all the writer asked: `x= *1',
%  `a= * 1' after format's `a=', `-1 '<2264>' 0', `p q it's', `p q (a)', and
%  write_canonical/1 wrote `<3bb>(x)' bare.
%
%  The file is ASCII, every name past it made of its codes, and so is every
%  line printed: a write is shown as the codes it wrote, each past ASCII or
%  below the space as `<hex>'. NOT HELD HERE: the atom '.', an operator of
%  swipl's (100 yfx, its dicts' functional notation) that cocolog has not
%  got, which swipl's writer brackets as an operand, `- ('.')', and
%  cocolog's leaves bare (COMPAT.md); and a variable's name, `_123' in
%  swipl and `_G123' in cocolog.

:- set_prolog_flag(double_quotes, codes).

%  SWI has write_term/3 built in, cocolog from library(stream)
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

%  the names past ASCII, by their codes
nm(le, [8804]).                 % a symbol past U+00FF
nm(ll, [955, 955]).             % two letters past U+00FF
nm(lam, [955]).
nm(all, [8704]).
nm(ab, [945, 946]).
nm(xle, [120, 32, 8804]).       % quoted, a space and a symbol past U+00FF
nm(e, [233]).                   % a letter of Latin-1
nm(ee, [233, 233]).
nm(not, [172]).                 % a symbol of Latin-1

n(K, A) :- nm(K, Cs), atom_codes(A, Cs).

:- n(le, A), op(700, xfx, A).
:- n(ll, A), op(700, xfx, A).
:- n(xle, A), op(700, xfx, A).
:- n(ee, A), op(700, xfx, A).
:- n(not, A), op(700, xfx, A).
:- n(lam, A), op(200, fy, A).
:- op(700, xfx, 'x y').
:- op(700, xfx, 'x\'y').
:- op(700, xfx, xx).
:- op(200, fy, 'p q').
:- op(200, fy, pq).

%  a term of the operator K's name over L and R, or over A alone
o(K, L, R, T) :- n(K, Op), T =.. [Op, L, R].
o(K, A, T) :- n(K, Op), T =.. [Op, A].

%  a string of codes Cs
s(Cs, S) :- atom_codes(A, Cs), atom_string(A, S).

main :- forall(member(S, [empty, start, wide, raw, canonical, kept]), run(S)).

run(S) :- write(S), nl, forall(nth1_c(S, N, G), (write(N), write(': '), show(G))).

nth1_c(S, N, G) :- findall(G0, c(S, G0), Gs), nth1(N, Gs, G).

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

wq(T) :- write_term(T, [quoted(true), quote_non_ascii(true)]).

%  a portray goal whose writes start afresh inside a partial(true) write
pgf(_, _) :- format("=~w", [''*1]).

%  a portray goal that writes elsewhere: the write it portrays t in goes on
%  from where it stood
pgs(t, _) :- with_output_to(string(_), write(t)).

%  ---- an operand that wrote nothing: its operator asks the code before it
c(empty, write(x = ''*1)).
c(empty, write(x = ''*a)).
c(empty, write(x @=< ''*(b+c))).
c(empty, write(x+''-1)).
c(empty, write(x = (''*1)*2)).
c(empty, write(x = ''*(-1))).
c(empty, write((x :- ''*1))).
c(empty, write(\+ ''*1)).
c(empty, write(- (''^1))).
c(empty, (s("", S), write(x = S*1))).
c(empty, (s("", S), write(x = S+S))).
c(empty, write(x = ''*'')).
c(empty, write('@@' = ''*1)).
c(empty, write((x , ''*1))).
c(empty, write((x ; ''*1))).
c(empty, write(x is ''*1)).
c(empty, write(x mod (''*1))).
c(empty, write(x^(''*1))).
c(empty, write(f(''*1))).
c(empty, write([''*1])).
c(empty, write({''*1})).
c(empty, write(''*1)).
c(empty, writeq(x = ''*1)).
c(empty, print(x = ''*1)).
c(empty, write_term(x = ''*1, [spacing(next_argument)])).
c(empty, (o(e, x, ''*1, T), write(T))).
%  ---- a write's start asks no code before it; partial(true) goes on
c(start, format("a=~w|", [''*1])).
c(start, format("a=~w|", [- a])).
c(start, format("a=~w|", [- (-a)])).
c(start, format("a=~p|", [- a])).
c(start, format("a=~q|", [''*1])).
c(start, format("~w~w|", [=, ''*1])).
c(start, format("a=~W|", [''*1, []])).
c(start, format("a=~W|", [''*1, [partial(true)]])).
c(start, format("a=~W|", [- a, [partial(true)]])).
c(start, (write(=), write(''*1))).
c(start, (write(=), write_term(''*1, [partial(true)]))).
c(start, (write(=), write_term(- a, [partial(true)]))).
c(start, (write(a), write_term(- a, [partial(true)]))).
c(start, (write(=), write(- a))).
c(start, (write(a), write_term(t, [partial(true), portray_goal(pgf)]))).
c(start, (write(=), write_term(t, [partial(true), portray_goal(pgf)]))).
c(start, (write(a), write_term(f(t), [partial(true), portray_goal(pgf)]))).
c(start, format("abcd=~w|", [x = a*1])).
c(start, format("abcd=~w|", [-(a*1)])).
c(start, write_term(x = t*1, [portray_goal(pgs)])).
c(start, write_term(x = - t*1, [portray_goal(pgs)])).
%  ---- an operator past U+00FF takes no space after the one before it
c(wide, (o(le, '@@', b, T), write(T))).
c(wide, (o(le, '@@', 1, T), write(T))).
c(wide, (o(le, -1, 0, T), wq(T))).
c(wide, (o(le, -1, 0, T), writeq(T))).
c(wide, (o(le, 1, 2, T), wq(T))).
c(wide, (o(ll, a, -1, T), write(T))).
c(wide, (o(ll, a, b, T), write(T))).
c(wide, (o(xle, 1, 2, T), writeq(T))).
c(wide, (o(xle, 'A', b, T), writeq(T))).
c(wide, (o(ee, a, -1, T), write(T))).
c(wide, (o(not, '@@', b, T), write(T))).
c(wide, (o(le, '@@', b, T), o(le, T, -1, U), write(U))).
c(wide, (o(lam, a, T), o(le, T, -1, U), wq(U))).
%  ---- an unquoted string and the `(' of a nameless compound ask no break
c(raw, (s("\\\\", S), write(+S))).
c(raw, (s("it's", S), write('p q'(S)))).
c(raw, (s("1", S), write(- S))).
c(raw, (s("-1", S), write(1 - S))).
c(raw, (s("x y", S), write(+(rdiv, S)))).
c(raw, (s("1", S), write(zz(+, S)))).
c(raw, (s("a", S), write(xx(S, b)))).
c(raw, (s("(a)", S), write(- S))).
c(raw, (s("{a}", S), write(pq(S)))).
c(raw, (s("a", S), write(table(S / x)))).
c(raw, (s("a", S), writeq('p q'(S)))).
c(raw, (s("1", S), print(- S))).
c(raw, write('p q'(''(a)))).
c(raw, write(-(''(a)))).
c(raw, write(x = ''(a))).
c(raw, write(pq(''(a, b)))).
c(raw, writeq('p q'(''(a)))).
c(raw, writeq(-(''(a)))).
c(raw, write('p q'(''(- a)))).
c(raw, write(- (''(\+ a)))).
%  ---- write_canonical/1 and ~k quote an atom past U+00FF
c(canonical, (n(lam, A), write_canonical(f(A)))).
c(canonical, (n(e, A), write_canonical(f(A)))).
c(canonical, (n(ab, A), n(all, B), write_canonical([A, B]))).
c(canonical, (n(ee, A), write_canonical(A))).
c(canonical, (n(not, A), write_canonical(A))).
c(canonical, (n(all, A), T =.. [A, x], write_canonical(T))).
c(canonical, (n(lam, A), format("~k", [A]))).
c(canonical, (n(lam, A), writeq(A))).
%  ---- what the writer already wrote as swipl's
c(kept, writeq('x\'y'(1, 2))).
c(kept, writeq('x y'(1, 2))).
c(kept, writeq('x y'(a, 2))).
c(kept, writeq('x y'('A', 'B'))).
c(kept, writeq(a- -1)).
c(kept, writeq(- 1)).
c(kept, writeq(-(-(1)))).
c(kept, writeq(- (1+2))).
c(kept, writeq('@@' = b)).
c(kept, writeq(- a = b)).
c(kept, writeq(1 rdiv -1)).
c(kept, writeq(pq (a, b))).
c(kept, writeq(\+ {a})).
c(kept, write("ab" = x)).
c(kept, (s("ab", S), write(S = x))).
