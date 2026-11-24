%% retractall/1 of single-sided rules as swipl 9.0.4's (cocolog 3.78.12).
%% Run by test/files.pl beside swipl, the two outputs compared byte for
%% byte.
%%
%% retractall(H) takes every rule whose head unifies with H, as it takes
%% any clause, and leaves the predicate a set of rules: a call no rule
%% matches raises existence_error(matching_rule, Goal) after it, as before,
%% and predicate_property/2 says `ssu'. swipl keeps a flag on the predicate
%% (P_SSU_DET, pl-proc.c's add_ssu_clause()), which a plain clause clears
%% where the predicate has no clauses, and cocolog the last clause its rules
%% end on: through 3.78.11 retractall/1 took that clause too, whose head
%% unifies with any call, and a call no rule matched failed. So a rule
%% asserted into rules emptied is a rule, and a plain clause makes the
%% predicate a plain one, its last clause gone.
%%
%% EACH SHAPE HAS A PREDICATE OF ITS OWN, rules read from this file and
%% never called before the shape runs. swipl decides a call's kind by the
%% code it built at the predicate's first call (the supervisor S_SSU_DET),
%% which a plain clause asserted after does not rebuild: a predicate called
%% as rules, emptied and given a plain clause raises
%% existence_error(matching_rule, G) there though predicate_property/2 no
%% longer says `ssu', where cocolog's call fails. Not copied (COMPAT.md).

:- dynamic s1/1, s2/1, s3/1, s4/1, s5/1, s6/1, s7/1, s8/1, s9/1, s10/1,
           s11/1, s12/1, s13/1, s14/1, s15/2, s16/1, s17/1.

s1(1) => true.
s1(2) => true.
s1(X), X > 5 => true.
s2(1) => true.
s2(2) => true.
s3(1) => true.
s3(2) => true.
s4(1) => true.
s5(1) => true.
s5(2) => true.
s6(1) => true.
s7(1) => true.
s8(1) => true.
s9(a) => true.
s9(b) => true.
s10(1) => true.
s11(1) => true.
s11(2) => true.
s12(1) => true.
s13(1) => true.
s14(X), X > 2 => true.
s14(_) => fail.
s15(K, V), atom(K) => V = atom.
s15(_, V) => V = other.
s16(1) => true.
s16(2) => true.
s17(1) => true.

%% a call's answer, an error its formal alone
r(G) :- catch(( G -> R = yes ; R = no ), E, ( E = error(F, _) -> R = F ; R = E )),
       \+ \+ ( numbervars(G-R, 0, _), print(G-R) ), nl.
%% the clauses as clause/2 sees them
cl(H) :- findall(H-B, clause(H, B), L), writeq(L), nl.
%% the properties that tell the kind, in swipl's order
pp(H) :- findall(P, ( predicate_property(H, P),
                      memberchk(P, [dynamic, number_of_clauses(_), number_of_rules(_), ssu]) ), Ps),
         writeq(Ps), nl.
%% an assert that may be refused, the formal alone
as(C) :- catch(assertz(C), error(F, _), ( writeq(refused(F)), nl )).

%% ---- the rules a retractall/1 takes ----
%% the head s1(X) of the guard's rule unifies with s1(1) too
ss01 :- retractall(s1(1)), r(s1(1)), r(s1(2)), r(s1(3)), r(s1(7)), cl(s1(_)), pp(s1(_)).
ss02 :- retractall(s2(_)), r(s2(1)), r(s2(3)), cl(s2(_)), pp(s2(_)).
%% one rule taken, the others standing
ss09 :- retractall(s9(a)), r(s9(a)), r(s9(b)), r(s9(c)), cl(s9(_)), pp(s9(_)).
%% a rule with a guard that fails and a catch-all
ss14 :- retractall(s14(3)), r(s14(3)), r(s14(1)), cl(s14(_)), pp(s14(_)).
%% the second argument decides nothing: every rule's head unifies
ss15 :- retractall(s15(_, other)), r(s15(a, _)), cl(s15(_, _)), pp(s15(_, _)).
%% nothing matches: the rules stand, the call that matches none raises
ss12 :- retractall(s12(9)), r(s12(1)), r(s12(9)), cl(s12(_)), pp(s12(_)).

%% ---- what comes to rules emptied ----
%% a plain clause: a plain predicate from then on
ss03 :- retractall(s3(_)), assertz(s3(5)), r(s3(5)), r(s3(1)), cl(s3(_)), pp(s3(_)).
%% asserta, twice
ss04 :- retractall(s4(_)), asserta(s4(5)), asserta(s4(6)), r(s4(6)), r(s4(1)), cl(s4(_)), pp(s4(_)).
%% a rule: still rules
ss05 :- retractall(s5(_)), assertz((s5(5) => true)), r(s5(5)), r(s5(1)), cl(s5(_)), pp(s5(_)).
%% a rule by asserta
ss06 :- retractall(s6(_)), asserta((s6(5) => true)), r(s6(5)), r(s6(1)), cl(s6(_)), pp(s6(_)).
%% a plain clause and then a rule: the rule is refused
ss07 :- retractall(s7(_)), assertz(s7(5)), as((s7(6) => true)), r(s7(5)), r(s7(6)), cl(s7(_)), pp(s7(_)).
%% a rule and then a plain clause: the clause is refused
ss08 :- retractall(s8(_)), assertz((s8(5) => true)), as(s8(6)), r(s8(5)), r(s8(6)), cl(s8(_)), pp(s8(_)).
%% the rules a walk saw die, their dead waiting when the plain clause comes
ss16 :- findall(B, ( clause(s16(_), B), retractall(s16(_)) ), L), writeq(L), nl,
        assertz(s16(5)), r(s16(5)), r(s16(1)), cl(s16(_)), pp(s16(_)).
%% a plain clause refused, a cycle, and then one that goes in
ss17 :- retractall(s17(_)), X = f(X), as(s17(X)), assertz(s17(5)), r(s17(5)), r(s17(1)),
        cl(s17(_)), pp(s17(_)).

%% ---- the rest of the database ----
%% retract/1 takes no rule, and none is left
ss10 :- retractall(s10(_)), ( retract(s10(_)) -> R = took ; R = none ), writeq(R), nl,
        r(s10(1)), pp(s10(_)).
%% a second retractall/1 over the emptied rules, and one over a rule added
ss11 :- retractall(s11(_)), retractall(s11(_)), r(s11(1)), assertz((s11(7) => true)),
        retractall(s11(7)), r(s11(7)), cl(s11(_)), pp(s11(_)).
%% listing/1 writes the declaration alone
ss13 :- retractall(s13(_)), listing(s13/1).

main :-
    forall(member(G, [ss01, ss02, ss09, ss14, ss15, ss12, ss03, ss04, ss05, ss06, ss07, ss08,
                      ss16, ss17, ss10, ss11, ss13]),
           ( write(G), write(':'), nl, ( catch(G, E, ( print_message(error, E), fail )) -> true
                                       ; write(failed), nl ) )).

