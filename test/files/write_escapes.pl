%  write_term/2's last options as swipl 9.0.4's pl-write.c applies them
%  (cocolog 3.55.0): character_escapes(B), character_escapes_unicode(B),
%  quote_non_ascii(B), brace_terms(B), cycles(B) and portrayed(B), which
%  is portray(B) by another name; a cycle's factors named S_1, S_2, ...
%  under numbervars alone; term_to_atom/2's and term_string/2's quoted
%  text as swipl's PL_WRT_QUOTED writes it; and no gap after the text of a
%  portray goal that failed where a goal's text comes next. Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte.
%
%  Through 3.54.0 the six options were checked and read past: a quoted
%  write under character_escapes(false) still wrote `\n' and `\u0001',
%  character_escapes_unicode(false) `\u0001' where swipl writes `\x1\',
%  quote_non_ascii(true) left an atom past U+00FF bare, brace_terms(false)
%  wrote `{a}', cycles(false) wrote a cyclic term in its factors where
%  swipl raises domain_error(cyclic_term, T), and portrayed(true) asked no
%  portray/1. write_term/2 with no numbervars, term_to_atom/2 and
%  term_string/2 named a cycle's factors S_1 where swipl writes the
%  variables they are, and no portray goal was asked of one;
%  term_to_atom/2 wrote a string's quote `\"' where swipl doubles it, and
%  `{}(a,b)' as `'{}'(a,b)'; and a failed goal's text took a gap before a
%  goal's text after it (`pg pg a').
%
%  The file is ASCII, every name past it an escape, and so is every line
%  printed: a write is captured, each code past ASCII or below the space
%  shown as `<hex>', and each variable's name, `_123' in swipl and `_G123'
%  in cocolog, as `_V1', `_V2', ... in the order the text names them.
%  Not held here: NUL, which no atom of cocolog's holds
%  (COMPAT.md); and fullstop(true) or nl(true) beside a write cycles(false)
%  refuses, which swipl 9.0.4 reports as its foreign predicate's uncleared
%  exception and the catch around it does not see (COMPAT.md).

:- set_prolog_flag(double_quotes, string).
:- discontiguous c/2.

%  SWI has write_term/3 built in, cocolog from library(stream)
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

:- op(700, xfx, '\x2248\').
:- op(200, fy, '\xAC\').

main :- forall(member(S, [escapes, unicode, nonascii, braces, cycles, names, text, gaps, portrayed]), run(S)).

run(S) :- write(S), nl, forall(nth1_c(S, N, G), (write(N), write(': '), show(G))).

nth1_c(S, N, G) :- findall(G0, c(S, G0), Gs), nth1(N, Gs, G).

%  the goal's text, or the error it raised
show(G) :-
    catch(( with_output_to(codes(Cs), G) -> vn(Cs, Ds), out(Ds) ; write(failed) ),
          E, report(E)),
    nl.

% cocolint: C2 -- the context printed, of errors both systems name alike (system:write_term/2, system:format/2)
report(error(F, context(P, _))) :- !, write('error '), print(F), write(' in '), writeq(P).
report(E) :- write('caught '), print(E).

%  the text with each variable's name `_V1', `_V2', ...
vn(Cs, Ds) :- vn(Cs, 32, [], Ds).
vn([], _, _, []).
vn([0'_|Cs], P, M0, Ds) :-
    \+ word(P), vname(Cs, Ns, Rest), !,
    ( memberchk(Ns-K, M0) -> M = M0 ; length(M0, L), K is L + 1, M = [Ns-K|M0] ),
    format(codes(Ks), "_V~d", [K]), append(Ks, Ds1, Ds), vn(Rest, 0'0, M, Ds1).
vn([C|Cs], _, M, [C|Ds]) :- vn(Cs, C, M, Ds).

vname([0'G|Cs], [0'G|Ns], Rest) :- vdigits(Cs, Ns, Rest), Ns \== [], !.
vname(Cs, Ns, Rest) :- vdigits(Cs, Ns, Rest), Ns \== [].

vdigits([C|Cs], [C|Ns], Rest) :- digit(C), !, vdigits(Cs, Ns, Rest).
vdigits(Cs, [], Cs).

%  ASCII's classes, which no locale moves
digit(C) :- C >= 0'0, C =< 0'9.
word(C) :- ( digit(C) -> true ; C >= 0'a, C =< 0'z -> true ; C >= 0'A, C =< 0'Z -> true ; C =:= 0'_ ).

out([]).
out([C|Cs]) :- ( C >= 32, C < 127 -> put_char_code(C) ; format("<~16r>", [C]) ), out(Cs).

put_char_code(C) :- char_code(Ch, C), put_char(Ch).

w(T, Os) :- write_term(T, Os), write('|').

%  a portray goal that writes and declines
pg(_, _) :- write(pg), fail.

%  ---- character_escapes(false): the text as it is, the quote doubled and
%  the backslash `\\' (swipl's putQuoted() without PL_WRT_CHARESCAPES)
ce(T) :- w(T, [quoted(true), character_escapes(false)]).
c(escapes, ce('a\nb')).
c(escapes, ce('a\tb')).
c(escapes, ce('a\x1\b')).
c(escapes, ce('a\x7f\b')).
c(escapes, ce('it''s')).
c(escapes, ce('a\\b')).
c(escapes, ce('a b')).
c(escapes, ce('\x80\')).
c(escapes, ce('\xA0\')).
c(escapes, ce('a \xE9\')).
c(escapes, ce('\x2028\')).
c(escapes, ce('\x200B\')).
c(escapes, ce('a\x2200\b')).
c(escapes, ce('\x7\')).
c(escapes, ce('\b')).
c(escapes, ce('\v')).
c(escapes, ce('\f')).
c(escapes, ce('\r')).
c(escapes, ce('\e')).
c(escapes, ce('\x1F\')).
c(escapes, ce('a\x85\b')).
c(escapes, ce('\xFEFF\')).
c(escapes, ce('\x10FFFF\')).
c(escapes, ce('\x3000\')).
c(escapes, ce('')).
c(escapes, ce('[]')).
c(escapes, ce('{}')).
c(escapes, ce('hello world')).
c(escapes, ce("a\nb")).
c(escapes, ce("it's")).
c(escapes, ce("say \"hi\"")).
c(escapes, ce("a\\b")).
c(escapes, ce("a\x1\b")).
c(escapes, ce('a\x1\b'(x))).
c(escapes, ce('a b'(x))).
c(escapes, ce(f('a''b', "c\"d"))).
c(escapes, ce(['a\nb', "x\"y"])).
c(escapes, w('a\nb'+'c', [quoted(true), character_escapes(false), ignore_ops(true)])).
c(escapes, ce(- 'a\nb')).
c(escapes, ce(hello(world))).
c(escapes, w('a\x2028\b', [quoted(true), character_escapes(false), character_escapes_unicode(false)])).
c(escapes, w('a\x1\b', [character_escapes(true)])).
c(escapes, w('a\nb', [character_escapes(false)])).
c(escapes, w('a\x1\b', [quoted(true), character_escapes(false), character_escapes(true)])).
c(escapes, w('it''s', [quoted(true), character_escapes(true), character_escapes(false)])).
c(escapes, w({a}, [brace_terms(false), quoted(true), character_escapes(false)])).
c(escapes, w({}(a,b), [quoted(true), character_escapes(false)])).

%  ---- character_escapes_unicode(false): a character escaped by its code
%  `\x1\', where write_term/2's default form is `\u0001'
cu(T) :- w(T, [quoted(true), character_escapes_unicode(false)]).
cq(T) :- w(T, [quoted(true)]).
c(unicode, cu('a\x1\b')).
c(unicode, cq('a\x1\b')).
c(unicode, cu('a\x7f\b')).
c(unicode, cu('\x80\')).
c(unicode, cu('\x9f\')).
c(unicode, cu('\xA0\')).
c(unicode, cu('\x2028\')).
c(unicode, cu('\x200B\')).
c(unicode, cu('\e')).
c(unicode, cq('\e')).
c(unicode, cu('\x1F\')).
c(unicode, cu('a\x85\b')).
c(unicode, cu('\xFEFF\')).
c(unicode, cu('\xE000\')).
c(unicode, cu('\x378\')).
c(unicode, cu('\x10FFFF\')).
c(unicode, cq('\x10FFFF\')).
c(unicode, cu('\xFFFE\')).
c(unicode, cu('\xD7FF\')).
c(unicode, cu('\x3000\')).
c(unicode, cu('\x2029\')).
c(unicode, cu('\x061C\')).
c(unicode, cu("a\x1\b")).
c(unicode, cu('it''s')).
c(unicode, cu('\x7\')).
c(unicode, cu('a\nb')).
c(unicode, cu('a\x2200\b')).
c(unicode, w('a\x1\b', [quoted(true), character_escapes_unicode(false), character_escapes_unicode(true)])).
c(unicode, w('a\x1\b', [character_escapes_unicode(false)])).

%  ---- quote_non_ascii(true): a name past U+00FF quoted (unquoted_atomW()),
%  never one of Latin-1 (atomType())
qn(T) :- w(T, [quoted(true), quote_non_ascii(true)]).
qn0(T) :- w(T, [quote_non_ascii(true)]).
c(nonascii, qn('\xE9\')).
c(nonascii, qn('a\xE9\')).
c(nonascii, qn('\x3B1\\x3B2\')).
c(nonascii, qn0('\x3B1\\x3B2\')).
c(nonascii, qn('\x2200\')).
c(nonascii, qn('+\x2200\')).
c(nonascii, qn('\xC9\t\xE9\')).
c(nonascii, qn('\xE9\'(x))).
c(nonascii, qn('\x2200\'(x))).
c(nonascii, qn('\x2248\'(a, b))).
c(nonascii, qn0('\x2248\'(a, b))).
c(nonascii, qn('\xAC\'(a))).
c(nonascii, qn(f('\xAC\'))).
c(nonascii, qn(['\xE9\'])).
c(nonascii, qn('a b \xE9\')).
c(nonascii, qn('\xB2\')).
c(nonascii, qn('\x1F600\')).
c(nonascii, qn('\xE9\'-'\xE9\')).
c(nonascii, qn(- '\xE9\')).
c(nonascii, qn(f('\xE9\', '\xFF\', '\x100\'))).
c(nonascii, qn([a|'\x2200\'])).
c(nonascii, qn(f('\x3B1\\x3B2\', g('\x3B3\')))).
c(nonascii, w('\x2200\'-'\x2200\', [quoted(true), quote_non_ascii(true), ignore_ops(true)])).
c(nonascii, w('$VAR'('\xC9\t\xE9\'), [quoted(true), numbervars(true), quote_non_ascii(true)])).
c(nonascii, w('$VAR'('\x100\'), [quoted(true), numbervars(true), quote_non_ascii(true)])).
c(nonascii, w('\x3B1\\x3B2\', [quoted(true), quote_non_ascii(true), quote_non_ascii(false)])).
c(nonascii, w("\x3B1\\x3B2\", [quoted(true), quote_non_ascii(true)])).
c(nonascii, w('\x3B1\\x3B2\', [quoted(true), quote_non_ascii(true), character_escapes(false)])).

%  ---- brace_terms(false): a curly term `{}(T)', swipl's PL_WRT_BRACETERMS
bt(T) :- w(T, [brace_terms(false)]).
btq(T) :- w(T, [brace_terms(false), quoted(true)]).
bti(T) :- w(T, [brace_terms(false), ignore_ops(true)]).
c(braces, bt({a})).
c(braces, btq({a})).
c(braces, bti({a})).
c(braces, bt({a,b})).
c(braces, btq({a,b})).
c(braces, bti({a,b})).
c(braces, bt({})).
c(braces, bt('{}'(a,b))).
c(braces, bt({a}+{b})).
c(braces, bti({a}+{b})).
c(braces, bt(f({a}))).
c(braces, bt([{a}])).
c(braces, bt({{a}})).
c(braces, bt(-({a}))).
c(braces, bti(-({a}))).
c(braces, bt({a}-1)).
c(braces, bt('{}'(_))).
c(braces, bt({(:-a)})).
c(braces, bti({(:-a)})).
c(braces, bt(({a}:-b))).
c(braces, bt(f({}))).
c(braces, bt('{}'(1))).
c(braces, bt({[]})).
c(braces, btq({'[]'})).
c(braces, w({a}, [brace_terms(true)])).
c(braces, w({a}, [brace_terms(false), brace_terms(true)])).
c(braces, w({a}, [brace_terms(false), portray(true)])).
c(braces, w({a}, [brace_terms(false), dotlists(true)])).
c(braces, w('{}'([a]), [brace_terms(false), no_lists(true)])).
c(braces, w(f({a}), [brace_terms(false), max_depth(2)])).
c(braces, format("~W", [{a,b}, [brace_terms(false)]])).

%  ---- cycles(false): domain_error(cyclic_term, T) before a character is
%  written, whatever the depth limit, in the context of the predicate
%  called
c(cycles, (X = f(X), w(X, [cycles(false)]))).
c(cycles, (X = f(X), w(X, [cycles(false), max_depth(5)]))).
c(cycles, (X = f(X), w(X, [cycles(false), max_depth(0)]))).
c(cycles, (X = f(X), w(h(X), [cycles(false), max_depth(3)]))).
c(cycles, (X = f(X), w(X, [cycles(true)]))).
c(cycles, (X = f(X), w(X, [cycles(false), cycles(true)]))).
c(cycles, (X = f(X), w(X, [cycles(true), cycles(false)]))).
c(cycles, w(f(a), [cycles(false)])).
c(cycles, (Y = [a|Y], w(Y, [cycles(false)]))).
c(cycles, (Y = [a|Y], w(g(Y), [cycles(false), max_depth(4)]))).
c(cycles, (Z = {Z}, w(Z, [cycles(false), brace_terms(false), max_depth(3)]))).
c(cycles, (X = f(X), w(X, [cycles(false), portray(true)]))).
c(cycles, (X = f(X), w(X, [cycles(false), quoted(true)]))).
c(cycles, (X = f(X), w(X, [cycles(maybe)]))).
c(cycles, (X = f(X), w(X, [cycles(false), quoted(maybe)]))).
c(cycles, (X = f(X), format("~W", [X, [cycles(false)]]))).
c(cycles, (X = f(X), format(atom(_), "~W", [X, [cycles(false)]]))).
c(cycles, (X = f(X), write_term(nosuch, X, [cycles(false)]))).
c(cycles, (X = f(X), write_term(user_input, X, [cycles(false)]))).
c(cycles, (X = f(X), write_term(user_output, X, [cycles(false)]))).
c(cycles, write_term(user_output, f(a), [cycles(false), quoted(maybe)])).

%  ---- a cycle's factors: S_1, S_2, ... under numbervars alone, as swipl
%  binds them to '$VAR'('S_1') only then -- and asks a portray goal of
%  that term; with none, the variables they are
c(names, (X = f(X), write(X))).
c(names, (X = f(X), print(X))).
c(names, (X = f(X), writeq(X))).
c(names, (X = f(X), write_canonical(X))).
c(names, (X = f(X), write_term(X, []))).
c(names, (X = f(X), write_term(X, [quoted(true)]))).
c(names, (X = f(X), write_term(X, [numbervars(true)]))).
c(names, (X = f(X), write_term(X, [numbervars(false)]))).
c(names, (X = f(X), write_term(X, [portray(true)]))).
c(names, (X = f(X), write_term(X, [portray(true), numbervars(false)]))).
c(names, (X = f(X), format("~w ~q ~p ~k", [X, X, X, X]))).
c(names, (X = f(X), format("~W", [X, []]))).
c(names, (X = f(X), format("~W", [X, [numbervars(true)]]))).
c(names, (X = f(X), write_term(X, [variable_names(['Q'=X])]))).
c(names, (X = f(X), write_term(g(X, V), [variable_names(['V'=V])]))).
c(names, (X = f(X), write_term(g(X, V), [variable_names(['V'=V]), numbervars(true)]))).
c(names, (X = f(X), write_term(g(X, V, W), [variable_names(['S_1'=V, 'W'=W]), numbervars(true)]))).
c(names, (X = f(X), write_term(g(X, '$VAR'('S_1')), [numbervars(true)]))).
c(names, (X = f(X), write_term(g(X, _), [numbervars(true)]))).
c(names, (Z = f(Z, Q), write_term(Z, [numbervars(true), variable_names(['Q'=Q])]))).
c(names, (Z = f(Z, Q), write_term(Z, [variable_names(['Q'=Q])]))).
c(names, (X = f(X), write_term(X, [quoted(true), ignore_ops(true)]))).
c(names, (X = f(X), write_term(X, [quoted(true), ignore_ops(true), numbervars(true)]))).
c(names, (X = f(X), write_canonical(g(X, '$VAR'(1))))).
c(names, (X = f(X), print([X, _]))).
c(names, (X = f(X), write_term(g(X, '$VAR'(1)), []))).
c(names, (X = f(X), write_term(g(X, '$VAR'(1)), [numbervars(true)]))).
c(names, (A = [a|A], write_term(g(A, A), []))).
c(names, (A = [a|A], write_term(g(A, A), [numbervars(true)]))).
c(names, (X = f(X), Y = g(Y), write_term(t(X, Y), []))).
c(names, (X = f(X), Y = g(Y), write_term(t(X, Y), [numbervars(true)]))).
c(names, (X = f(X), write_term(X, [portray_goal(pg)]))).
c(names, (X = f(X), write_term(X, [portray_goal(pg), numbervars(false)]))).
c(names, (X = f(X), write_term(X, [max_depth(3)]))).

%  ---- term_to_atom/2 and term_string/2: swipl's PL_WRT_QUOTED alone
tt(T) :- term_to_atom(T, A), atom_codes(A, Cs), atom_codes(Q, Cs), write(Q).
ts(T) :- term_string(T, S), write(S).
c(text, tt("a\"b")).
c(text, ts("a\"b")).
c(text, tt('a''b')).
c(text, tt("a\\b")).
c(text, tt("a\nb\x1\c")).
c(text, tt(f("x\"y", 'q''r'))).
c(text, tt({}(a,b))).
c(text, tt({a})).
c(text, ts({}(a,b))).
c(text, (X = f(X), tt(X))).
c(text, (X = f(X), ts(X))).
c(text, (X = f(X), tt(g(X, '$VAR'(1))))).

%  ---- no gap goes before a portray goal's text, even right after the
%  text of one that failed (3.55.0; 3.54.0 wrote `pg pg a+pg b')
pz(T, _) :- T == z, write(zz).
pz(_, _) :- write(q), fail.
c(gaps, write_term(a+b, [portray_goal(pg)])).
c(gaps, write_term(f(a+b, [c|d]), [portray_goal(pg)])).
c(gaps, write_term(- (1), [portray_goal(pg)])).
c(gaps, write_term(1 - -1, [portray_goal(pg)])).
c(gaps, write_term(f(z)+z, [portray_goal(pz)])).
c(gaps, write_term((a:-b,c), [portray_goal(pg)])).
c(gaps, write_term([a+b], [portray_goal(pg)])).
c(gaps, write_term(f(- a), [portray_goal(pg)])).
%  a goal that failed inside the term another failed goal is writing: the
%  outer goal's place comes back after the inner one's, so its gap is
%  decided by the term's own first text (`pg g(pgzz+y)')
pn(g(_), _) :- write(pg), fail.
pn(x+y, _) :- write(pg), fail.
pn(x, _) :- write(zz).
pn(h(_, _), _) :- write(ph), fail.
pn(k, _) :- write(kk).
pn(m(_), _) :- write(pm), fail.
pn([_|_], _) :- write(pl), fail.
pn(- _, _) :- write(pp), fail.
c(gaps, write_term(g(x+y), [portray_goal(pn)])).
c(gaps, write_term(g(x), [portray_goal(pn)])).
c(gaps, write_term(h(x+y, k), [portray_goal(pn)])).
c(gaps, write_term(m(g(x+y)), [portray_goal(pn)])).
c(gaps, write_term(g(m(x+y)), [portray_goal(pn)])).
c(gaps, write_term(g(x+y)+g(k), [portray_goal(pn)])).
c(gaps, write_term([x+y, g(x+y)], [portray_goal(pn)])).
c(gaps, write_term(- (x+y), [portray_goal(pn)])).
c(gaps, write_term(g(- (x+y)), [portray_goal(pn)])).
c(gaps, write_term(m([x+y]), [portray_goal(pn)])).

%  ---- portrayed(B): portray(B) by another name, the last of the two said
%  standing, numbervars(true) implied as by portray(true) (3.55.0; through
%  3.54.0 checked and read past). portray/1 has its clause only around
%  these writes: the sections before write where it has none.
pt(T, Os) :-
    setup_call_cleanup(assertz((portray(pv(_)) :- write(pp))), w(T, Os),
                       retractall(portray(_))).
c(portrayed, pt(f(pv(1)), [portrayed(true)])).
c(portrayed, pt(f(pv(1)), [portrayed(false)])).
c(portrayed, pt(f(pv(1)), [portrayed(true), portray(false)])).
c(portrayed, pt(f(pv(1)), [portray(true), portrayed(false)])).
c(portrayed, pt(f(pv(1)), [portray(false), portrayed(true)])).
c(portrayed, pt('$VAR'(1), [portrayed(true)])).
c(portrayed, pt('$VAR'(1), [portrayed(true), numbervars(false)])).
c(portrayed, pt(f(pv(1)), [portrayed])).
c(portrayed, pt(f(pv(1)), [portrayed(maybe)])).
c(portrayed, pt(f(pv(1)), [portrayed = true])).
c(portrayed, pt(f(pv(1)), [])).
