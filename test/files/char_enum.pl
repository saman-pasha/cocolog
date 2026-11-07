%  char_type/2 and code_type/2 as swipl 9.0.4's do_char_type() answers them,
%  the character or the type unbound included. Run by BOTH SWI-Prolog and
%  cocolog, output compared byte for byte.
%
%  Each goal's every answer, with whether it left a choice point (det or
%  nondet, by setup_call_cleanup/3's own report), or the ball it raised. An
%  unbound character is walked from -1 to U+10FFFF and an unbound type over
%  swipl's table in its order; an answer short of the last code or class
%  leaves a choice point whatever comes after it. Through 3.29.0 cocolog
%  raised instantiation_error for every walk, and knew no decimal, no
%  end_of_file and no paren(C). The digests at the end hold every class over
%  every code point: the tables lib/swipl-ctype.cicili makes.
%
%  NOT HELD HERE, AS cocolog DIFFERS ON PURPOSE (COMPAT.md): period and
%  quote past ASCII -- swipl's strchr() over a truncated code also calls
%  U+0100 and 17 403 more so -- so no code past 127 whose low byte is 0,
%  `!', `.', `?', a quote or a backquote is walked for its types; a
%  character of a surrogate, which char_type/2's walk passes by; the NUL as
%  a character, '' here; and an atom past ASCII written, which cocolog
%  quotes where swipl does not.

:- set_prolog_flag(double_quotes, codes).
:- use_module(library(dcg/basics)).

%  swipl asks glibc for most classes, and glibc's C locale -- LANG unset --
%  has no letter past ASCII. cocolog's classes are written out, its own
%  whatever the locale, and it has no setlocale/3: the goal raises there and
%  is passed by.
:- G = setlocale(ctype, _, 'C.UTF-8'), catch(G, _, true).

pv(T) :- \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

t(G) :-
    catch(( findall(G-D, ( setup_call_cleanup(true, G, D0 = det),
                           ( D0 == det -> D = det ; D = nondet ) ), L),
            pv(G), write(' => '), pv(L), nl ),
          E, ( pv(G), write(' raised '), pv(E), nl )).

main :- bound, reverse, walk_codes, walk_types, nested, library, digests.

%  both arguments bound, and what a character or a type is
bound :-
    t(code_type(0x110000, alpha)), t(code_type(0x110000, _)), t(code_type(-2, alpha)),
    t(code_type(2147483647, alpha)), t(code_type(2147483648, alpha)),
    t(code_type(-2147483649, alpha)), t(code_type(9999999999999, alpha)),
    t(char_type(ab, alpha)), t(char_type([], alpha)), t(code_type(1.5, alpha)),
    t(code_type("ab", alpha)), t(char_type("a", alpha)), t(char_type([a], alpha)),
    t(char_type(f(x), alpha)), t(char_type([a|_], alpha)), t(code_type(foo, alpha)),
    t(code_type(foo, _)),
    %  the end of the input: end_of_file, before any type is asked
    t(code_type(-1, foo)), t(code_type(-1, _)), t(char_type(end_of_file, _)),
    t(code_type(-1, end_of_file)), t(code_type(-1, upper(_))), t(code_type(-1, 3)),
    t(code_type(0'a, end_of_file)),
    %  a type that is none, named char_type/2 for code_type/2 as well
    t(code_type(_, _)), t(char_type(_, _)), t(code_type(_, foo)), t(code_type(_, paren)),
    t(code_type(_, upper(_, _))), t(code_type(_, 3)), t(code_type(_, "alpha")),
    t(code_type(0'a, foo)), t(code_type(0'a, paren)), t(code_type(0'a, 3)),
    t(code_type(0'a, f())), t(code_type(0'a, [])), t(code_type(0'a, decimal(1, 2))),
    %  a class and its argument
    t(code_type(0'a, alpha)), t(code_type(0'a, upper(_))), t(code_type(0'a, lower(_))),
    t(char_type(a, lower(_))), t(char_type(a, to_lower(_))), t(char_type(a, to_upper(_))),
    t(code_type(0'A, upper(_))), t(char_type('A', upper(_))), t(code_type(0'5, digit(_))),
    t(code_type(0'5, decimal(_))), t(code_type(0'f, xdigit(_))), t(code_type(0'F, xdigit(_))),
    t(code_type(0'(, paren(_))), t(char_type('[', paren(_))), t(code_type(0'), paren(_))),
    t(code_type(0x661, decimal(_))), t(code_type(0x1D7CF, decimal(_))),
    t(code_type(0xE9, upper(_))), t(code_type(0xC9, upper(_))), t(code_type(0xFF, lower(_))),
    t(code_type(0xDF, to_lower(_))), t(code_type(0x1E9E, to_upper(_))),
    t(code_type(0x10A0, to_upper(_))), t(code_type(0x13A0, to_upper(_))),
    t(code_type(0x2C00, to_upper(_))), t(code_type(0x10400, to_upper(_))),
    t(code_type(0x1E922, to_lower(_))).

%  "the other way around": a value that does not unify is tried as the
%  argument's reverse; a character unbound and the argument bound, the
%  reverse alone
reverse :-
    t(code_type(0'a, to_lower(0'a))), t(code_type(0'A, to_lower(0'a))),
    t(code_type(0'a, upper(0'a))), t(code_type(0'A, upper(0'a))),
    t(char_type('A', upper(a))), t(char_type('A', upper(97))), t(code_type(0'A, upper(a))),
    t(code_type(0'A, upper([0'a]))), t(char_type('A', upper("a"))),
    t(code_type(0'a, to_upper(0'a))), t(code_type(0'A, to_upper(0'a))),
    t(code_type(0'a, to_upper(0'A))), t(code_type(0'a, lower(0'A))),
    t(code_type(0'A, lower(0'A))), t(code_type(0'a, lower(0'a))),
    t(code_type(0'5, digit(7))), t(code_type(0'5, digit(5))), t(code_type(0'5, decimal(7))),
    t(code_type(0'5, decimal(5))), t(code_type(0'a, xdigit(10))), t(code_type(0'A, xdigit(10))),
    t(code_type(0'0, decimal(0))), t(code_type(0'(, paren(0')))), t(code_type(0'), paren(0'())),
    t(code_type(0'(, paren(0'())),
    %  an argument that is no character raises, read as the reverse reads it
    t(code_type(0'A, upper(foo))), t(code_type(0'a, to_lower(f(_)))),
    t(code_type(0'5, digit(foo))), t(code_type(0'a, digit(foo))), t(code_type(0'A, to_lower(foo))),
    t(code_type(0'a, upper(end_of_file))), t(code_type(0'A, upper(end_of_file))),
    t(code_type(0'A, upper(-1))), t(code_type(0'A, upper(2147483648))),
    t(code_type(0'A, upper(1114112))), t(code_type(0'A, upper(-2))), t(code_type(0'A, upper(ab))),
    t(code_type(0'A, upper(97.0))), t(code_type(0'5, digit(5.0))), t(code_type(0'5, digit(-1))),
    %  the character unbound, the argument bound
    t(code_type(_, upper(0'a))), t(char_type(_, upper(a))), t(code_type(_, lower(0'A))),
    t(char_type(_, to_lower(a))), t(code_type(_, to_upper(0'a))), t(code_type(_, upper(0'A))),
    t(code_type(_, digit(5))), t(char_type(_, digit(5))), t(code_type(_, digit(10))),
    t(code_type(_, digit('5'))), t(code_type(_, digit(53))), t(code_type(_, xdigit(15))),
    t(char_type(_, xdigit(10))), t(code_type(_, xdigit(16))), t(code_type(_, paren(0')))),
    t(char_type(_, paren(']'))), t(code_type(_, paren(0'())), t(code_type(_, upper(foo))),
    t(code_type(_, upper(-1))), t(code_type(_, upper(1114112))), t(code_type(_, upper(2147483648))),
    t(code_type(_, upper(f(x)))), t(code_type(_, digit(-1))), t(code_type(_, digit(foo))),
    t(code_type(_, xdigit(f(x)))), t(code_type(_, paren(foo))), t(char_type(_, to_lower(end_of_file))),
    t(code_type(_, decimal(foo))), t(code_type(_, lower(f(_)))), t(code_type(_, decimal(7))).

%  an unbound character: walked from -1 to U+10FFFF
walk_codes :-
    t(code_type(_, digit)), t(char_type(_, digit)), t(char_type(_, digit(_))),
    t(code_type(_, xdigit(_))), t(code_type(_, paren(_))), t(char_type(_, paren(_))),
    t(code_type(_, end_of_line)), t(code_type(_, newline)), t(code_type(_, white)),
    t(code_type(_, end_of_file)), t(char_type(_, end_of_file)),
    t((code_type(C1, digit), C1 > 0'7)), t((code_type(_, digit), !)), t(once(code_type(_, alpha))),
    t((code_type(C2, upper), C2 > 0x10400, C2 < 0x10410)),
    t(cs(_)),
    t((code_type(C4, lower(U4)), C4 >= 0x10428, U4 < 0x10404)),
    t((code_type(C5, to_upper(L5)), C5 >= 0x1E900, L5 > C5, C5 < 0x1E905)),
    t((code_type(C6, prolog_symbol), C6 > 0x2200, C6 < 0x2206)),
    t((code_type(C7, decimal(W7)), C7 > 0x1D7F0, W7 > 6)),
    t((code_type(C8, space), C8 > 127)), t((code_type(C9, cntrl), C9 > 127, C9 < 140)),
    t((code_type(C10, to_lower(_)), C10 > 0x10FFFC)).

%  an unbound type: walked over swipl's table, in its order
walk_types :-
    t(code_type(0'a, _)), t(char_type(a, _)), t(code_type(0'g, _)), t(code_type(0'0, _)),
    t(code_type(0'5, _)), t(code_type(0'_, _)), t(code_type(0' , _)), t(code_type(10, _)),
    t(code_type(0, _)), t(code_type(127, _)), t(code_type(0'(, _)), t(char_type(')', _)),
    t(code_type(0'., _)), t(code_type(0'", _)), t(code_type(0'Z, _)), t(code_type(0xE9, _)),
    t(code_type(0xDF, _)), t(code_type(0xFF, _)), t(code_type(0xA0, _)), t(code_type(0x661, _)),
    t(code_type(0x1D7CE, _)), t(code_type(0x2028, _)), t(code_type(0x1680, _)),
    t(code_type(0x2003, _)), t(code_type(0x10FFFF, _)), t(code_type(0xD801, _)),
    t(code_type(0x1E9E, _)), t(code_type(0x1C5, _)), t(code_type(0x2161, _)),
    t((code_type(0'a, T1), T1 = csymf)), t((code_type(0'a, T2), !, T2 \== alnum)).

%  inside a clause's body, a disjunction, a negation, findall/3, call/N
%  and a module's qualifier
nested :-
    t(ab(_, _)), t(ac(_)), t(ad), t(ae(_)), t(af(_)),
    t(system:code_type(_, digit)), t(user:char_type(_, paren(_))), t(lists:code_type(0'a, upper(_))),
    t(call(code_type, _, white)), t(call(char_type(_), end_of_line)), t(qa(_)).

ab(C, T) :- ( code_type(C, paren(T)) ; C = none, T = none ).
ac(L) :- findall(C, code_type(C, xdigit(_)), L).
ad :- \+ code_type(_, upper(0'1)).
ae(T) :- code_type(0'A, T), T = upper(_).
af(K-T) :- ( K = 0'x ; K = 0'9 ), code_type(K, T), T = xdigit(_).
qa(C) :- system:char_type(C, newline).

%  a character past ASCII, by its code: cocolog writes the atom quoted
cs(K) :- char_type(C, csymf), char_code(C, K), K > 0x2C2C, K < 0x2C34.

%  library(dcg/basics) generating, its grammar's code_type/2 walked
library :-
    t(phrase(digit(_), _)), t(phrase(xdigit(_), _)),
    t((phrase(nonblank(C1), _), C1 > 0x1F600, C1 < 0x1F603)),
    t(phrase(xdigits(_), [0'f, _])).

%  EVERY CLASS OVER EVERY CODE POINT: the answers' count, their sum and a
%  sum of each answer weighted by its place, where a code in or out of a
%  class, a value and an order all tell
digests :-
    forall(member(T, [alnum, alpha, csym, csymf, prolog_var_start, prolog_atom_start,
                      prolog_identifier_continue, decimal, prolog_symbol, ascii, white,
                      cntrl, digit, print, graph, lower, upper, punct, space, end_of_file,
                      end_of_line, newline]),
           digest(T)),
    forall(member(T, [decimal(_), lower(_), upper(_), to_lower(_), to_upper(_), paren(_),
                      digit(_), xdigit(_)]),
           digest(T)),
    forall(member(T, [period, quote]),
           ( findall(C, ( code_type(C, T), C < 128 ), L), pv(T-L), nl )),
    chars(alpha), chars(upper(_)), chars(prolog_symbol),
    last_det(code_type(_, to_lower(_))), last_det(code_type(_, print)),
    last_det(code_type(0'a, _)),
    cases(upcase_atom), cases(downcase_atom).

%  upcase_atom/2 and downcase_atom/2 of every character but the NUL and
%  the surrogates, towupper() and towlower() of each as code_type/2's
%  to_lower(U) and to_upper(L) give them -- the same tables since 3.30.0.
%  Nor 181 and 255: swipl 9.0.4 aborts on upcase_atom of either (an
%  assertion in pl-ctype.c's modify_case_atom, c <= 0xff: a Latin-1 atom
%  whose capital is past Latin-1); cocolog's are 924 and 376.
cases(P) :-
    findall(K-W, ( between(1, 0x10FFFF, K), \+ between(0xD800, 0xDFFF, K),
                   K =\= 181, K =\= 255,
                   char_code(C, K), call(P, C, A), atom_codes(A, [W]) ), L),
    length(L, N),
    foldl(weigh, L, 0-0-1, S-H-_),
    format("~w ~d ~d ~d~n", [P, N, S, H]).

digest(T) :-
    findall(C-W, ( code_type(C, T), value(T, W) ), L),
    length(L, N),
    foldl(weigh, L, 0-0-1, S-H-_),
    pv(T), format(" ~d ~d ~d~n", [N, S, H]).

value(T, W) :- ( compound(T) -> arg(1, T, W) ; W = 0 ).

weigh(C-W, S0-H0-I, S-H-I1) :-
    S is S0 + C + W,
    H is (H0 + I * (C * 7 + W)) mod 1000000007,
    I1 is I + 1.

%  char_type/2's walk, its characters' codes
chars(T) :-
    findall(K-W, ( char_type(X, T), char_code(X, K), value(T, V), cv(V, W) ), L),
    length(L, N),
    foldl(weigh, L, 0-0-1, S-H-_),
    write(char), write(' '), pv(T), format(" ~d ~d ~d~n", [N, S, H]).

cv(V, W) :- ( atom(V) -> char_code(V, W) ; W = V ).

%  the last answer of a walk, and whether it left a choice point
last_det(G) :-
    findall(G-D, ( setup_call_cleanup(true, G, D0 = det),
                   ( D0 == det -> D = det ; D = nondet ) ), L),
    length(L, N), last(L, Last),
    pv(G), write(' '), write(N), write(' last '), pv(Last), nl.
