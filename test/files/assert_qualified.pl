%% Clauses a program asserts under module qualifiers, as swipl 9.0.4 files
%% them (cocolog 3.64.8). Run by test/files.pl beside swipl, the two
%% outputs compared byte for byte.
%%
%% cocolog has one namespace, so a qualifier on a clause -- on the whole of
%% it, on its head, or both, nested or not -- names the predicate its head
%% names. The qualifiers here are `user', where swipl's modules and
%% cocolog's namespace file the clause alike. The assert makes that
%% predicate dynamic, as any assert does. Through 3.64.7 the store took one
%% qualifier off the clause and the head's only where the clause had none:
%% `user:user:w(1)' and `user:(user:y(1) :- true)' were clauses of (:)/2,
%% `user:(z(a) => true)' a fact of (=>)/2, never a rule; and the assert
%% marked (:)/2 dynamic for every qualified clause, so none of these
%% predicates was. Through 3.73.0 retractall/1 read a qualified head as
%% written, a head of (:)/2, and took nothing (raising for a module that
%% is no atom, where swipl's takes nothing), and clause/2 of a hook's
%% head asked message/3, which holds none of the hook's clauses.
%%
%% A file's clauses are filed the same way, and there the innermost module
%% is the one a hook's head is asked of: a clause `prolog:(message(...) :-
%% B)' is the message hook (through 3.64.7, message/3's), where a grammar
%% rule under a qualifier is translated by neither system. The messages
%% are printed first, so that stderr and stdout never interleave.

:- multifile prolog:message//1.
prolog:(message(qa_one) --> ['qualified rule']).
prolog:(message(qa_two, ['qualified clause'|T], T) :- true).

said(G) :- catch((G -> R = yes ; R = no), error(E, _), R = E), writeln(R).

main :-
    print_message(error, qa_one), print_message(error, qa_two),
    % a fact, a clause, nested qualifiers, the head's, and both
    assertz(user:u(1)), said(predicate_property(u(_), dynamic)),
    asserta(user:(v(1) :- true)), said(predicate_property(v(_), dynamic)),
    assertz(user:user:w(1)), said(predicate_property(w(_), dynamic)), said(w(1)),
    assertz((user:x(1) :- true)), said(predicate_property(x(_), dynamic)), said(x(1)),
    assertz((user:user:x2(1) :- true)), said(predicate_property(x2(_), dynamic)), said(x2(1)),
    assertz(user:(user:y(1) :- true)), said(predicate_property(y(_), dynamic)), said(y(1)),
    % a single-sided rule under a qualifier is a rule: a goal no rule
    % matches raises
    assertz(user:(z(a) => true)), said(predicate_property(z(_), dynamic)), said(z(a)), said(z(b)),
    assertz((user:q(a) => true)), said(predicate_property(q(_), dynamic)), said(q(a)), said(q(b)),
    assertz(user:(user:r(a) => true)), said(r(a)), said(r(b)),
    % the clauses as clause/2 shows them, through a qualifier too
    findall(H-B, clause(y(H), B), L1), writeln(L1),
    findall(H-B, clause(user:z(H), B), L2), writeln(L2),
    % a retract through a qualifier takes the clause
    said(retract(user:u(1))), said(u(_)),
    % so does retractall/1, its qualifiers off as swipl's PL_strip_module()
    % takes them: an atom's, every one, the innermost the module named; a
    % module that is no atom ends the strip, and the head left is no
    % clause's, so nothing is taken and nothing declared
    assertz(ra(1)), assertz(ra(2)), assertz(ra(3)), assertz(ra(4)),
    said(retractall(user:ra(1))), findall(X1, ra(X1), La), writeln(La),
    said(retractall(user:user:ra(2))), findall(X2, ra(X2), Lb), writeln(Lb),
    said(retractall(prolog:user:ra(3))), findall(X3, ra(X3), Lc), writeln(Lc),
    said(retractall(_:ra(4))), said(retractall([]:ra(4))), said(retractall(f(x):ra(4))),
    said(retractall(user:(_:ra(4)))), findall(X4, ra(X4), Ld), writeln(Ld),
    said(retractall(user:_)), said(retractall(user:3)),
    C5 = user:C5, catch(retractall(C5), error(type_error(T5, _), _), true), writeln(T5),
    % a rule is no head of retractall/1's: nothing is taken
    said(retractall(user:(ra(4) :- true))), findall(X6, ra(X6), Le), writeln(Le),
    % a predicate with no clauses is declared dynamic: the head's own
    said(retractall(user:rn(_))), said(predicate_property(rn(_), dynamic)),
    said(retractall(_:rm(_))), said(predicate_property(rm(_), dynamic)),
    % clause/2 of a hook's head asks the hook, as the load filed it
    said(clause(prolog:message(qa_two, ['qualified clause'|T7], T7), true)),
    % listing/1 writes the declaration every one of them has
    listing(v/1), listing(w/1), listing(x/1), listing(y/1), listing(z/1), listing(q/1),
    writeln(done).
