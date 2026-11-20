%% Single-sided rules a program asserts, as swipl 9.0.4's (cocolog 3.64.7).
%% Run by test/files.pl beside swipl, the two outputs compared byte for
%% byte.
%%
%% A goal no rule of a predicate matches raises
%% existence_error(matching_rule, G), and an assert keeps it so: an assertz
%% goes before the clause that raises (cocolog's `'$ssu_none'' last
%% clause), a predicate's first rule is given one, by assertz or asserta,
%% and an asserta goes first. Under the logical update view a call or a
%% clause/2 walk open on the predicate sees none of the rules asserted after
%% it began -- not even when it has the last clause still to try, where the
%% rule is put after the last one and the last one moved after it
%% (`coco_ssu_add''s shape 2). Through 3.64.6 an assertz added the rule
%% and retracted the last clause and asserted another, three writes a
%% knowledge base could refuse apart (test/store-lock.pl's `rr_retract'),
%% and the asserted rule's predicate was dynamic only by that retract.

:- dynamic r/1, w/1, u/1, v/1, f/1.

r(X), X > 100 => writeln(big).
r(_), (assertz((r(_) => writeln(new_rule))), fail) => writeln(never).
r(X), X < 0 => writeln(negative).

w(1) => true.
w(2) => true.

f(1) => writeln(f1).

said(G) :- catch((G -> R = yes ; R = no), error(E, _), R = E), writeln(R).

main :-
    % a call open on r/1 has the last clause to try: the rule its guard
    % asserts is not its to see, and its goal matches none
    said(r(5)),
    % a new call sees the rule the last one asserted
    said(r(5)),
    % a clause/2 walk open on w/1: an assertz is not its to see
    findall(H, (clause(w(H), _), (H == 1 -> assertz((w(3) => true)) ; true)), L1),
    writeln(L1),
    findall(H, clause(w(H), _), L2), writeln(L2),
    said(w(3)), said(w(4)),
    % no rules yet: the first assertz, and then a goal no rule matches
    assertz((u(1) => true)),
    said(u(1)), said(u(2)),
    assertz((u(2) => true)), said(u(2)), said(u(3)),
    % no rules yet: the first asserta
    asserta((v(1) => true)),
    said(v(1)), said(v(2)),
    asserta((v(2) => true)), said(v(2)), said(v(3)),
    findall(H, clause(v(H), _), L3), writeln(L3),
    % a file's rules, then an assertz and an asserta
    assertz((f(2) => writeln(f2))), asserta((f(0) => writeln(f0))),
    said(f(0)), said(f(1)), said(f(2)), said(f(3)),
    findall(H, clause(f(H), _), L4), writeln(L4),
    % a retract of a rule is no retract (swipl 9.0.4), the predicate as it was
    said(retract((f(1) :- _))),
    findall(H, clause(f(H), _), L5), writeln(L5),
    % one asserted rule makes its predicate dynamic, as an asserted clause
    % does, and listing/1 says so (through 3.64.6 only a second rule's
    % assert did, by the retract of the last clause it made)
    assertz((d1(1) => true)),
    said(predicate_property(d1(_), dynamic)),
    listing(d1/1).
