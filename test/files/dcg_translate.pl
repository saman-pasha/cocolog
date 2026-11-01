%  The grammar translation as swipl's boot/dcg.pl makes it: what
%  dcg_translate_rule/2 answers, what phrase/2,3 does with a body it is
%  handed, what a file's rule is stored as, and what a rule that will not
%  translate says when it is read. Run by BOTH SWI-Prolog and cocolog,
%  output compared byte for byte.
%
%  Through 3.12.0 cocolog's translation was its own where these differ:
%  `{}' was `S = S0' where swipl unifies the two lists when it translates
%  (`a --> {}' is `a(A, A) :- true'), a disjunction's branch got the
%  rule's output where swipl binds a branch's own after it, `m:b' in a
%  body was the non-terminal `:'/4, a string was no terminal, a partial
%  list was walked by append/3 where swipl's is '$append'/3, a list that
%  is neither proper nor partial was walked too where swipl raises, and a
%  rule that would not translate was `not a clause'; assertz/1 translated
%  a rule (swipl's asserts the `-->'/2 clause it is given); phrase/3
%  translated every body (swipl's calls a non-terminal, `{}' and `*->'
%  among them, as call/3 does); and dcg_translate_rule/2 did not exist.
%
%  NOT HELD HERE: a stored body's conjunctions as swipl's compiler flattens
%  them, and its head unifications moved; a rule in a module file.
:- set_prolog_flag(double_quotes, codes).

%  ---- a file's rules, read back with clause/2 --------------------------
s1 --> [].
s2 --> {}.
s3 --> [x], b.
s4 --> ([x] ; {}).
s5 --> ({} ; [x]).
s6 --> (b ; ({}, {})).
s7, [p] --> b.
s8, {g} --> b.
s9, ! --> b.
s10 --> m:b.
s11 --> user:b.
s12 --> m:{g}.
s13 --> m:[x].
s14 --> [x|_].
s15 --> b, {}, c.
s16(X) --> [X], {X > 1}.
s17 --> call(f, x).
s18 --> m:(b ; [x]).
b --> [].
c --> [].
g.

%  ---- rules that will not translate: reported, and the load goes on ----
[a] --> b.
(a ; b) --> c.
x1 --> 1.
x2 --> (b --> c).
x3 --> [x|foo].
{} --> b.
(\+ a) --> b.
x4, [p|q] --> b.
x5 --> b, 2.
x6 --> m:3.
_ --> b.
%  after them all, the file's last rule is read as ever
z --> [z].

%  ---- helpers -----------------------------------------------------------
%  a term's variables named A, B, ... in the order they stand in it
nv(T) :- term_variables(T, Vs), nv(Vs, 0).
nv([], _).
nv(['$VAR'(N)|T], N) :- M is N + 1, nv(T, M).

%  an error's formal and its context's predicate, `_' for none: no
%  system names a variable as another does
ball(error(F, C), F-W) :- !, ( var(C) -> W = '_' ; C = context(W, _) -> true ; W = C ).
ball(B, B).

%  dcg_translate_rule/2 of RULE, its clause or its ball, each in a world
%  of its own so no rule's variables are another's
r(Rule) :-
    \+ \+ ( catch(( dcg_translate_rule(Rule, C) -> nv(C), print(C) ; write(no) ),
                  E, ( ball(E, B), print(caught(B)) )),
            nl ).

%  the stored clause of HEAD
s(H) :-
    \+ \+ ( ( clause(H, B) -> nv(H-B), print((H :- B)) ; write(none) ), nl ).

%  a goal's answer, yes, no or its ball
t(G) :-
    \+ \+ ( catch(( G -> write(yes) ; write(no) ), E, ( ball(E, B), print(caught(B)) )),
            nl ).

translations :-
    r(foo), r(_), r((_ --> b)), r((1 --> b)), r(([a] --> b)), r((a --> 1)),
    r(({} --> b)), r((! --> b)), r(((a, b) --> c)), r(((a ; b) --> c)), r((\+ a --> c)),
    r(((a --> b) --> c)), r((a --> (b --> c))), r((a --> [x|foo])), r((a --> [x|_])),
    r((a, [p] --> b)), r((a, x --> b)), r((a, _ --> b)), r(((_, [p]) --> b)),
    r(((a, [p]) --> [q])), r((m:a --> b)), r((m:[a] --> b)), r((a --> m:(b, c))),
    r((a --> m:(b ; [x]))), r((a --> m:(n:b))), r((a --> m:_)), r((a --> m:{_})), r((a --> m:!)),
    r((a --> m:[x])), r((a --> m:{})), r((a --> m:(\+ b))), r((a --> user:(b, c))),
    r((a --> ({} ; b))), r((a --> (b ; {}))), r((a --> ({} | {}))), r((a --> ({}, {}))),
    r((a --> (b ; ({}, {})))), r((a --> ((b ; {}), c))), r((a --> (\+ {}))),
    r((a --> ({} -> b ; c))), r((a --> call(f))), r((a --> [])), r((a(X) --> {X = 1})),
    r((a --> _, [y])), r((a --> (b, ! ; c))), r((a --> [a, b, c], d)), r((a --> b:c:d)),
    r((a --> f(Y), {Y})), r((a --> 'x y')), r((a --> [x] ; [y])), r((_ --> b)),
    r((a --> (b *-> {} ; c))), r((a(1, 2) --> b(3))), r((a --> m:(n:[x]))), r((a --> (m:b, c))),
    r((a --> {a}, {b})), r((a --> \+ \+ b)), r((a --> call(_, _))), r((a --> foo:call(f))),
    r((a, [b|_] --> c)), r((a, [b|c] --> d)), r((a, {x} --> b)), r((a, ! --> b)),
    r((a, [] --> b)), r((a, m:[p] --> b)), r((a --> [x], b)), r((a --> b, !, c)),
    r((a --> \+ [x], b)), r((a --> b, [x])), r((a --> 2.5)), r((f() --> b)), r((a --> f())),
    r((a --> "")), r((a --> "ab", b)), r((a --> !())), r((a --> {}())),
    string_codes(S, "ab"), r((a --> S)), r((a --> b, S)), string_codes(E, ""), r((a --> E)).

stored :-
    s(s1(_, _)), s(s2(_, _)), s(s3(_, _)), s(s4(_, _)), s(s5(_, _)),
    s(s7(_, _)), s(s8(_, _)), s(s9(_, _)), s(s10(_, _)), s(s11(_, _)), s(s12(_, _)),
    s(s13(_, _)), s(s14(_, _)), s(s15(_, _)), s(s16(_, _, _)), s(s17(_, _)), s(s18(_, _)),
    s(z(_, _)),
    %  a rule asserted is the clause of `-->'/2 it is
    t(assertz((y1 --> [y]))), t((clause((y1 --> B1), true), B1 == [y])),
    t(phrase(y1, [y])), t(retract((y1 --> _))).

phrases :-
    t(phrase(nope, [a])), t(phrase(1, [a])), t(phrase(_, [a])), t(phrase({}, [a])),
    t(phrase({}, [])), t(phrase((b *-> []), [])), t(phrase(m:[b], [b])),
    t(phrase(m:nope, [b])), t(phrase((x --> y), [])), t(phrase(call(b), [])),
    t(phrase([b|_], [b])), t(phrase([b|c], [b])), t(phrase((b, nope), [])),
    t(phrase((b, 1), [])), t(phrase(\+ nope, [])), t(phrase({nope}, [])),
    t(phrase(m:{true}, [])), t(phrase(m:(b, []), [])), t(phrase(user:b, [])),
    t(phrase(foo:b, [])), t(call_dcg({}, [], _)), t(call_dcg(b, [], _)),
    t(phrase(b, foo)), t(phrase((b, {}), [])), t(phrase(!, [])), t(phrase((b, !), [])),
    t(phrase((b | []), [])), t(phrase((b -> []), [])), t(phrase([], [])),
    t(phrase((b, _), [])), t(phrase((b, (x --> y)), [])), t(phrase(([] ; {}), [])),
    t(phrase([x|foo], _)), t(phrase((a --> b), _)), t(phrase(m:[x], [x])),
    t((phrase({}, L, R), L == R)), t(phrase("ab", "ab")),
    t((string_codes(S, "ab"), phrase(S, "ab"))), t((string_codes(S2, "ab"), phrase(S2, "abc", "c"))),
    t((phrase(([a] ; {}), L2, R2), L2 == R2)), t((phrase(s14, [x, y, z], R3), R3 == [y, z])),
    t(phrase(s16(2), [2])), t(phrase(s16(1), [1])),
    t(phrase(user:nope, [])), t(phrase(m:n:nope, [])), t(phrase(m:n:b, [])),
    t(( phrase((b, {}), [x], R4), fail ; var(R4) )),
    %  the lists a translation binds are its own: the caller's are unified after
    t(( findall(R9, ( member(A9, [[1], [2, 3], [4, 5, 6]]), phrase((b, {}), A9, R9) ), L9),
        L9 == [[1], [2, 3], [4, 5, 6]] )).

main :- translations, stored, phrases.
