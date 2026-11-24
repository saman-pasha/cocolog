%% test/files/ssu_read.pl: a call made while a file is read reaches the
%% rules read so far and raises for none, as swipl 9.0.4's (3.78.13)
:- discontiguous p/1.
:- dynamic d/1.
:- multifile r/1.

t(G) :- catch(( G -> R = yes ; R = no ), E, ( E = error(F, _) -> R = F ; R = E )), writeq(G-R), nl.

p(1) => true.
p(X), X > 5 => true.
:- t(p(1)), t(p(2)), t(p(7)).
%% a rule read right before an initialization(G, now), no other goal between
s(1) => true.
:- initialization((t(s(2)), t(p(3))), now).
:- initialization(t(p(4))).
q(a) => true.
:- t(q(b)), t(p(2)).
p(9) => true.
:- t(p(9)), t(p(10)), t(q(a)).
%% a nested read's goal calls this file's rules
:- consult(nest).
%% a rule a directive asserts goes before the last clause
d(1) => true.
:- assertz((d(2) => true)), t(d(2)), t(d(3)).
d(4) => true.
:- t(d(4)), t(d(5)).
:- assertz((w(1) => true)), t(w(1)), t(w(2)).
%% a module the read's directive loads asserts a rule for a predicate the
%% read gives rules, and calls one -- a read of its own, cocolog's muted
%% one, whose goals settle nothing of this file's: the directive settles
%% the rules read so far before the load, so the module's call no rule
%% matches raises, its rule goes after the read's first, the read's next
%% after it, and a call no rule matches raises here too. Before the hook
%% below, whose call settles the rules read before each term
:- dynamic ip/1.
ip(1) => true.
:- use_module(inner).
ip(2) => true.
:- t(ip(1)), t(ip(2)), t(ip(5)), t(ip(3)).
%% a file an ensure_loaded/1 directive loads calls the rules read so far
:- dynamic eq/1.
eq(1) => true.
:- ensure_loaded(plainq).
eq(2) => true.
:- t(eq(1)), t(eq(2)), t(eq(3)).
%% a term_expansion/2 hook calls the rules read before it
cls(1) => true.
term_expansion(mk(X), made(X, R)) :- catch(( cls(X) -> R = yes ; R = no ), error(E, _), R = E).
mk(1).
mk(2).
r(1) => true.

%% a rule asserted after the read goes before the one last clause it left
main :- t(p(1)), t(p(2)), t(p(9)), t(q(b)), t(d(4)), t(d(5)), t(w(2)),
        assertz((d(6) => true)), t(d(6)), t(d(7)),
        forall(made(X, R), ( writeq(made(X, R)), nl )),
        consult(mfb), t(r(1)), t(r(2)), t(r(3)).
