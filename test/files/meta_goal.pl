%  meta_predicate/1 as a goal, as swipl 9.0.4's (cocolog 3.46.0): a
%  conjunction declared left to right, each head's module qualifiers taken
%  off, an ISO predicate refused, each specifier checked in order; what a
%  declaration made so qualifies; and the qualification a predicate's calls
%  get as its declaration stood at its first call, kept till abolish/1.
:- set_prolog_flag(double_quotes, codes).
:- dynamic dd/1, d1/1, d2/1, d3/1.

out(T) :-
    \+ \+ ( numbervars(T, 0, _), print(T) ), nl.

t(G) :-
    catch(( G -> out(yes) ; out(no) ), E, out(caught(E))).

%% the same, saying nothing of a goal that succeeds
q(G) :-
    catch(( G -> true ; out(no) ), E, out(caught(E))).

spec(H) :-
    ( predicate_property(H, meta_predicate(S)) -> out(S) ; out(none) ).

w1(G) :- out(w1(G)).
w2(G, X) :- out(w2(G, X)).
w4(G) :- out(w4(G)).
q1(G) :- out(q1(G)).
q2(G) :- out(q2(G)).
zero :- out(zero).
late(G) :- out(late(G)).
late2(G) :- out(late2(G)).
s1(G) :- out(s1(G)).

main :-
    declared, conjunctions, wholes, specifiers, system, first_call, kept.

%% declared, and the declaration standing as made again
declared :-
    t(meta_predicate(w1(0))), spec(w1(_)), t(w1(foo)),
    t(meta_predicate(w2(0, ?))), spec(w2(_, _)),
    t(meta_predicate(w2(?, ?))), spec(w2(_, _)),
    t(meta_predicate(zero)), spec(zero),
    t(meta_predicate(dd(0))), spec(dd(_)).

%% a conjunction, left to right: what stood before the error stays
conjunctions :-
    t(meta_predicate((q1(0), q2(x)))), spec(q1(_)), spec(q2(_)),
    t(meta_predicate(w4(x))), spec(w4(_)).

%% the qualifiers taken off, and the whole and its parts
wholes :-
    t(meta_predicate(m:w5(:))),
    t(meta_predicate(_:w1(0))), t(meta_predicate(m:_)),
    t(meta_predicate(_)), t(meta_predicate((w1(0), _))),
    t(meta_predicate((w1(0), 1))), t(meta_predicate(1)),
    t(meta_predicate("g(0)")), t(meta_predicate([c(0), d(0)])),
    t(meta_predicate(x(0)/1)), t(meta_predicate(x/1)),
    t(meta_predicate(x(0) : y)).

%% each specifier in order
specifiers :-
    t(meta_predicate(x(_))), t(meta_predicate(x(0, _))), t(meta_predicate(x(_, 0))),
    t(meta_predicate(x(y, _))), t(meta_predicate(x(_, y))),
    t(meta_predicate(x(10))), t(meta_predicate(x(-1))),
    t(meta_predicate(x(2147483647))), t(meta_predicate(x(2147483648))),
    t(meta_predicate(x(-2147483648))), t(meta_predicate(x(-2147483649))),
    t(meta_predicate(x(0.5))), t(meta_predicate(x(""))),
    t(meta_predicate(x(f(x)))), t(meta_predicate(x('0'))), t(meta_predicate(x([]))),
    t(meta_predicate(x(@))), t(meta_predicate(x(!))),
    t(meta_predicate(x(?, +, -, *, :, ^, //, 0, 9))).

%% an ISO predicate, asked before the specifiers
system :-
    t(meta_predicate(atom_length(0, ?))), t(meta_predicate(atom_length(x, ?))),
    t(meta_predicate(call(0))), t(meta_predicate(true)).

%% THE DECLARATION AS IT STOOD AT THE FIRST CALL: called before it is
%% declared, nothing qualifies; declared and called, it goes on qualifying
%% whatever is declared after, which predicate_property/2 tells
first_call :-
    t(late(a)), t(meta_predicate(late(0))), t(late(b)), t(call(late, c)),
    t(meta_predicate(late2(0))), t(late2(a)), t(meta_predicate(late2(?))), t(late2(b)),
    spec(late2(_)), t(meta_predicate(late2(0))), t(late2(c)),
    t(meta_predicate(s1(0))), q(s1(a)), t(meta_predicate(s1(?))), q(s1(b)), spec(s1(_)),
    ( predicate_property(s1(_), transparent) -> out(transparent) ; out(not_transparent) ).

%% kept through the clauses a dynamic predicate is given and loses, and
%% dropped by abolish/1
kept :-
    q(meta_predicate(d1(0))), assertz((d1(G) :- out(d1a(G)))), q(d1(a)),
    q(meta_predicate(d1(?))), q(d1(b)),
    assertz((d1(G2) :- out(d1b(G2)))), q(d1(c)),
    q(retract((d1(_) :- out(d1a(_))))), q(d1(d)),
    assertz((d2(G3) :- out(d2a(G3)))), q(d2(a)), q(meta_predicate(d2(0))), q(d2(b)),
    assertz((d2(G4) :- out(d2b(G4)))), q(d2(c)),
    q(retractall(d2(_))), assertz((d2(G5) :- out(d2c(G5)))), q(d2(d)),
    q(meta_predicate(d3(0))), assertz((d3(G6) :- out(d3a(G6)))), q(d3(a)),
    q(abolish(d3/1)), q(meta_predicate(d3(?))), assertz((d3(G7) :- out(d3b(G7)))), q(d3(b)),
    q(abolish(d3/1)), q(meta_predicate(d3(0))), assertz((d3(G8) :- out(d3c(G8)))), q(d3(c)).
