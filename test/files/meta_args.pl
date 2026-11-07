%  meta_predicate/1's module-sensitive arguments -- 0 to 9, `:', `^' and
%  `//' -- qualified by the module the call is made in unless they are
%  M:X already, as swipl 9.0.4's (cocolog 3.45.0). ma_mod.pl, a module
%  the case's fixture writes, is called from here and calls from there.
:- use_module(ma_mod).
:- use_module(library(aggregate)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(assoc)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(yall)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form
:- use_module(library(lists)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form

out(T) :-
    \+ \+ ( numbervars(T, 0, _), print(T) ), nl.

t(G) :-
    catch(( G -> true ; out(failed) ), E, out(caught(E))).

:- meta_predicate p(0), p2(:), p3(1), s(//), w(?), e(^), h(0), pc(0), tr2(0).
p(G) :- out(p(G)).
p2(G) :- out(p2(G)).
p3(G) :- out(p3(G)).
s(G) :- out(s(G)).
w(G) :- out(w(G)).
e(G) :- out(e(G)).
h(foo) :- writeln(h_bare).
h(user:foo) :- writeln(h_user).
h(lists:foo) :- writeln(h_lists).
pc(G) :- call(G).
tr2(G) :- p(G), p(inner2).
plain(X) :- p(X).
foo :- writeln(foo_ran).

%  called before they are declared: swipl's first call built the code
%  that calls them, which qualifies nothing
pk(G) :- out(pk(G)).
:- pk(called).
:- meta_predicate pk(0).
:- dynamic pd/1.
:- ( pd(x) -> true ; true ).
:- meta_predicate pd(0).
pd(G) :- out(pd(G)).

%  declared again: the declaration as it stands, as swipl's
:- meta_predicate rd(0).
:- meta_predicate rd(?).
rd(G) :- out(rd(G)).
:- meta_predicate re(?).
:- meta_predicate re(0).
re(G) :- out(re(G)).

main :-
    %  the argument kinds, and what is qualified already
    t(p(foo)), t(p(lists:foo)), t(p(1:foo)), t(p(_:foo)), t(p(_)),
    t(p((a, b))), t(p(user:foo)), t(p2(foo)), t(p3(foo)), t(s(digit)),
    t(w(foo)), t(e(X^foo(X))),
    %  a head matches the qualified argument
    t(h(foo)), t(h(lists:foo)), t(h(bar:foo)), t(pc(foo)),
    %  the module the call is made in: a clause's, a module's directive's,
    %  M:G's, a meta-predicate's own clause's, a transparent one's caller's
    t(q(foo)), t(ma_mod:q(foo)), t(q(ma_mod:foo)), t(r(x, foo)),
    t(r(x, Y^foo(Y))), t(lit), t(tr(foo)), t(hq(foo)), t(ma_mod:hq(foo)),
    t(mt(a)), t(tr2(foo)), t(plain(foo)), t(user:p(foo)),
    t(ma_mod:(p(c1), q(c2))),
    %  a predicate called before its declaration qualifies nothing
    t(pk(after)), t(pd(after)),
    %  one declared again
    t(rd(foo)), t(re(foo)),
    %  call/N, and the searches
    t(call(p, bar)), t(call(ma_mod:q, zz)), t(( G1 = p(baz), call(G1) )),
    t(findall(Z, p(Z), _)), t(forall(member(Z1, [z1]), p(Z1))),
    t(aggregate_all(count, p(c), _)), t(ma_mod:aggregate_all(count, p(c), _)),
    t(( with_output_to(string(S), p(w)), out(S) )),
    t(\+ \+ p(n)), t(once(p(o))), t(ignore(p(i))), t(maplist(p, [m1, m2])),
    t(call([A]>>p(A), l1)), t(foreach(member(F, [f1, f2]), p(F))),
    %  an error, and the errors of the libraries' meta-predicates
    t(p(foo, x)), t(aggregate(count, _, _)), t(aggregate(count, _^_, _)),
    t(( aggregate(count, p(a1), C), out(C) )),
    t(max_member(le, _, foo)), t(min_member(le, _, [1|foo])),
    t(map_assoc(integer, foo)), t(call([_, _, _]>>true, 1)).
