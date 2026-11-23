%  print_message/2's two hooks named where a program names them (cocolog
%  3.78.1), held to swipl 9.0.4. Run by BOTH SWI-Prolog and cocolog, output
%  compared byte for byte.
%
%  prolog:message//1 and prolog:error_message//1 are swipl's system's
%  multifile hooks. A declaration of one declares the hook, not user's
%  message/3 or error_message/3, as a goal and as a directive, under any
%  qualifiers; predicate_property/2, current_predicate/1 and a call of
%  prolog:message(...) ask the hook, as an assert and clause/2 reach it.
%  swipl's own clauses of prolog:message//1 are counted by no check here:
%  the error hook's count is asked, which swipl gives none of its own, and
%  whether this file is among the message hook's source files, the first
%  of which are swipl's own files.

:- multifile prolog:message//1.
:- discontiguous prolog:message//1.
prolog:message(mh_hello(X)) --> [ 'hello ~w'-[X] ].
:- dynamic prolog:error_message//1.
prolog:message(mh_two) --> [ two ].

w(T) :- \+ \+ ( numbervars(T, 0, _), print(T) ), nl.
t(G) :- ( catch(G, E, ( w(caught(E)), fail )) -> w(yes(G)) ; w(no(G)) ).
props(H) :-
    findall(P, ( predicate_property(H, P),
                 memberchk(P, [dynamic, multifile, defined, discontiguous, static, visible]) ), Ps),
    msort(Ps, S),
    w(H-S).
count(H) :- ( predicate_property(H, number_of_clauses(N)) -> w(count(N)) ; w(count(none)) ).
%% whether this file is among Head's source files, its path not printed
mine(H) :- source_file(main, Me), findall(F, source_file(H, F), Fs), memberchk(Me, Fs).

main :-
    declared,
    current,
    called,
    counted,
    goals,
    sourced.

%% the declarations declared the hooks and nothing of user's
declared :-
    props(prolog:message(_, _, _)),
    props(prolog:error_message(_, _, _)),
    props(user:prolog:message(_, _, _)),
    props(user:message(_, _, _)),
    props(message(_, _, _)),
    props(user:error_message(_, _, _)),
    t(( predicate_property(prolog:message(_, _, _), implementation_module(M1)), M1 == prolog )),
    t(( predicate_property(prolog:error_message(_, _, _), implementation_module(M2)), M2 == prolog )).

%% current_predicate/1 of a hook, its arity 3 where none is given
current :-
    t(current_predicate(prolog:message/3)),
    t(current_predicate(prolog:error_message/3)),
    t(current_predicate(user:prolog:message/3)),
    t(current_predicate(prolog:message/2)),
    t(( current_predicate(prolog:message/A1), A1 == 3 )),
    t(current_predicate(user:message/3)),
    t(current_predicate(message/3)),
    t(current_predicate(error_message/3)).

%% a call runs the program's rules, through phrase/2 and as a goal; a term
%% no rule matches fails, and user's error_message/3 is no predicate
called :-
    t(( phrase(prolog:message(mh_hello(1)), L1), w(L1) )),
    t(( prolog:message(mh_two, L2, []), w(L2) )),
    t(( user:prolog:message(mh_two, L3, []), w(L3) )),
    t(prolog:message(mh_none, _, [])),
    t(prolog:error_message(mh_none, _, [])),
    t(error_message(mh_none, _, [])).

%% the dynamic hook: what an assert and a retract change is counted
counted :-
    count(prolog:error_message(_, _, _)),
    t(assertz(prolog:error_message(mh_err, L1, L1))),
    count(prolog:error_message(_, _, _)),
    t(( phrase(prolog:error_message(mh_err), L2), w(L2) )),
    t(retract(prolog:error_message(mh_err, _, _))),
    count(prolog:error_message(_, _, _)).

%% the declarations as goals
goals :-
    t(dynamic(user:prolog:error_message/3)),
    t(multifile(prolog:message//1)),
    t(discontiguous(prolog:[message//1])),
    props(prolog:message(_, _, _)),
    props(user:message(_, _, _)),
    props(user:error_message(_, _, _)).

%% the hooks are swipl's system's: a file's clause of one names the file
%% among its files, under any qualifiers, and a declaration of one
%% registers nothing with the file -- the error hook has no file, and the
%% file's lists name the message hook alone, under prolog
sourced :-
    t(mine(prolog:message(_, _, _))),
    t(mine(user:prolog:message(_, _, _))),
    t(source_file(prolog:error_message(_, _, _), _)),
    t(source_file(user:prolog:error_message(_, _, _), _)),
    source_file(main, Me),
    findall(P1, source_file(prolog:P1, Me), L1), w(prolog-L1),
    findall(P2, source_file(P2, Me), L2), w(user-L2).
