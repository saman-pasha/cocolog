%  Definite clause grammars: the translation itself.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  `double_quotes' is set because SWI's default is `string' and cocolog's
%  reader has only one behaviour -- a double-quoted literal is a list of codes.
%  Saying so makes the two agree on what `"abc"' means; cocolog accepts the
%  directive only for the value it actually honours.
:- set_prolog_flag(double_quotes, codes).

%  ---- the shapes a body can take ----------------------------------------
greeting --> [hello], name.
name     --> [world].
name     --> [prolog].

empty    --> [].
lit      --> "abc".
curly(X) --> [X], { X > 2 }.
cut_one  --> [a], !, [b].
disj     --> [a] ; [b].
ifte(T)  --> ( [a] -> { T = saw_a } ; [b], { T = saw_b } ).
neg      --> \+ [a], [_].
seq([])     --> [].
seq([H|T])  --> [H], seq(T).
callit(G)   --> call(G).
one         --> [x].
two(V)      --> [V].

%  a body that is a variable, resolved when the rule runs
via(B) --> B.

%  pushback: match a, leave b behind in front of the rest
pb, [b] --> [a].

%  ---- what the translation leaves behind ---------------------------------
%  A grammar rule becomes an ORDINARY CLAUSE with two more arguments, and that
%  is observable: the non-terminal can be called directly, without phrase/2.
%
%  THE CLAUSE'S EXACT BODY IS NOT COMPARED HERE, on purpose. SWI's compiler
%  lifts a leading unification into the head, so `clause/2' there shows
%  `greeting([hello|S1], S) :- name(S1, S)' where cocolog shows the unification
%  still in the body. Both prove the same things in the same order; which one
%  `clause/2' hands back is each system's own business, and a test that pinned
%  it would be testing SWI's clause compiler rather than this translation.
%  cocolog's own form is checked in test/solve.cicili instead.
direct(G) :- ( call(G) -> write(y) ; write(n) ), nl.

main :-
    ( phrase(greeting, [hello,world]) -> write(y) ; write(n) ), nl,
    ( phrase(greeting, [hello,nope])  -> write(y) ; write(n) ), nl,
    findall(X, phrase(name, [X]), L1), write(L1), nl,
    ( phrase(empty, []) -> write(y) ; write(n) ), nl,
    ( phrase(lit, "abc") -> write(y) ; write(n) ), nl,
    ( phrase(curly(5), [5]) -> write(y) ; write(n) ), nl,
    ( phrase(curly(1), [1]) -> write(y) ; write(n) ), nl,
    ( phrase(cut_one, [a,b]) -> write(y) ; write(n) ), nl,
    findall(R, phrase(disj, R, []), L2), write(L2), nl,
    ( phrase(ifte(T1), [a]) -> write(T1) ; write(n) ), nl,
    ( phrase(ifte(T2), [b]) -> write(T2) ; write(n) ), nl,
    ( phrase(neg, [b]) -> write(y) ; write(n) ), nl,
    ( phrase(neg, [a]) -> write(y) ; write(n) ), nl,
    ( phrase(seq(S), [1,2,3]) -> write(S) ; write(n) ), nl,
    ( phrase(callit(one), [x]) -> write(y) ; write(n) ), nl,
    %  call//N passes its extra arguments through before the two the DCG adds
    ( phrase(call(two, V2), [7]) -> write(V2) ; write(n) ), nl,
    ( phrase(via([q]), [q]) -> write(y) ; write(n) ), nl,
    ( phrase(via(name), [world]) -> write(y) ; write(n) ), nl,

    %  pushback: `pb' eats a and puts b back, so the rest starts with b
    ( phrase(pb, [a|Rest0], Rest0) -> write(pb_no) ; write(pb_ok) ), nl,
    ( phrase((pb, [b]), [a]) -> write(y) ; write(n) ), nl,

    %  a partial list of terminals, whose tail is only known at run time
    T3 = [1|_], ( phrase(seq([1,2]), [1,2]) -> write(y) ; write(n) ), nl, T3 = [1|_],

    %  ---- the translated clause's shape ----
    direct(greeting([hello,world], [])),
    direct(greeting([hello,nope], [])),
    direct(empty([], [])),
    direct(cut_one([a,b], [])),
    direct(seq([1,2], [1,2], [])),
    %  and the two extra arguments are a difference list, not a whole one
    direct(greeting([hello,world,extra], [extra])),

    %  ---- the errors ----
    ( catch(phrase(_, [a]), error(E1,_), true) -> write(E1) ; write(no) ), nl,
    ( catch(phrase(1, [a]), error(E2,_), true) -> write(E2) ; write(no) ), nl,
    %  phrase/3 checks its lists, and does it BEFORE looking at the body --
    %  `phrase(1, foo)' complains about `foo'. call_dcg/3 is the same thing
    %  without the check, which is the only difference between them.
    ( catch(phrase(x, foo), error(E3,_), true) -> write(E3) ; write(no) ), nl,
    ( catch(phrase(1, foo), error(E4,_), true) -> write(E4) ; write(no) ), nl,
    ( catch(phrase(greeting, [hello,world], bad), error(E5,_), true) -> write(E5) ; write(no) ), nl,
    ( catch(call_dcg(greeting, foo, _), error(E6,_), true) -> write(E6) ; write(failed_not_raised) ), nl,
    ( phrase(greeting, [hello,world|T7], T7) -> write(partial_ok) ; write(partial_no) ), nl,
    true.

x --> [a].
