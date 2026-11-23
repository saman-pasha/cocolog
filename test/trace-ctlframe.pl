%% once/1, ignore/1, not/1 and catch/3 under trace (3.78.7), for
%% test/trace.pl: in swipl each is a transparent predicate of its system, a
%% port of its own whose body meta-calls the goal -- a goal a level below
%% it, a control structure in a `'<meta-call>'/1' frame there and its parts
%% a level below that -- and which hides what it calls but a program's
%% predicate. Its Call shows the goal as the caller gave it, its Exit, Fail
%% and Redo said of user. catch/3's recovery runs a level below it, a
%% structure in a meta-call frame; and a catch/3 that took a ball says no
%% Fail after (swipl's B_THROW discards its debug choice point), its Exit
%% and a Redo in its recovery printed still. Through 3.78.6 the four ran in
%% place, no port and no level: their goals stood at the caller's.

cf_a.
cf_b.
cf_m(1).
cf_m(2).
cf_n(X) :- cf_m(X).

%% once/1
cf1 :- once(cf_a).
cf2 :- once((cf_a, cf_b)).
cf3 :- once(cf_m(X)), X > 0.
cf4 :- once(member(X, [1, 2])), X > 0.
cf5 :- once(fail) ; true.
cf6 :- once((cf_m(X), X > 1)).
cf7 :- once(cf_m(_)), fail.
cf8 :- once(!).
cf9 :- once(user:cf_a).
cf10 :- once(\+ fail).
cf11 :- once(\+ cf_a) ; true.
cf12 :- once((cf_m(X), !)), X > 0.
cf13 :- once((cf_m(X), X > 1, !)).
cf14 :- G = (cf_a, cf_b), once(G).
cf15 :- once(cf_n(X)), X > 0.
cf16 :- once(user:(cf_a, cf_b)).
cf17 :- G = once(cf_a), call(G).
cf18 :- call(once, cf_a).
cf19 :- once(catch(once(cf_a), _, true)).
cf20 :- \+ once(fail).
cf21 :- once(ignore(fail)).

%% ignore/1
cf22 :- ignore(cf_a).
cf23 :- ignore(fail).
cf24 :- ignore((cf_m(X), X > 5)).
cf25 :- ignore(cf_m(X)), X > 1.
cf26 :- ignore(once(cf_a)).
cf27 :- ignore(fail), cf_a.
cf28 :- ignore(cf_n(X)), X > 1.
cf29 :- ignore(user:fail).
cf30 :- G = ignore(cf_a), G.
cf31 :- ignore(catch(fail, _, true)).

%% not/1
cf32 :- not(cf_a) ; true.
cf33 :- not(fail).
cf34 :- not(cf_m(_)) ; true.
cf35 :- not(not(cf_a)).
cf36 :- not(not(cf_n(_))).
cf37 :- not(member(9, [1, 2])).

%% catch/3
cf38 :- catch(cf_a, _, true).
cf39 :- catch((cf_a, cf_b), _, true).
cf40 :- catch(cf_m(X), _, true), X > 1.
cf41 :- catch(throw(x), x, cf_a).
cf42 :- catch(fail, _, true) ; true.
cf43 :- catch(cf_m(X), _, true), X > 5.
cf44 :- catch((cf_m(X), X > 1), _, true).
cf45 :- catch(catch(throw(x), y, true), x, cf_a).
cf46 :- catch(once(cf_a), _, true).
cf47 :- catch(!, _, true).
cf48 :- catch(member(X, [1, 2]), _, true), X > 1.
cf49 :- catch(throw(x), x, cf_m(X)), X > 1.
cf50 :- catch(once(throw(x)), x, true).
cf51 :- catch(once(1), _, true).
cf52 :- catch(ignore(1), _, true).
cf53 :- catch(not(1), _, true).
cf54 :- catch(catch(1, _, true), _, true).
cf55 :- catch((cf_m(X), !), _, true), X > 0.
cf56 :- catch(cf_n(X), _, true), X > 1.
cf57 :- catch(cf_m(X), _, true), X > 3.
cf58 :- catch((cf_a ; cf_b), _, true), fail.
cf59 :- catch(member(X, [1, 2, 3]), _, true), X > 2.
cf60 :- catch(user:cf_m(X), _, true), X > 1.
cf61 :- once(catch((cf_m(X), X > 1), _, true)).
cf62 :- catch(cf_m(X), _, true), cf_m(Y), X > Y.
cf63 :- forall(cf_m(X), once(cf_m(X))).
cf64 :- catch(atom_length(_, _), _, true).
cf65 :- catch(throw(x), _, true).

%% a catch/3 that took a ball: no Fail after, its recovery a level below
%% it, a structure in a meta-call frame
cf66 :- catch(throw(x), x, fail) ; true.
cf67 :- catch(throw(x), x, cf_m(X)), X > 5.
cf68 :- catch(throw(x), x, (cf_m(X), X > 5)).
cf69 :- catch(throw(x), x, nth0(_, [a, b], b)), fail.
cf70 :- catch(throw(x), x, once(fail)).
cf71 :- catch(throw(x), x, \+ cf_a).
cf72 :- catch(throw(x), E, (E == x, cf_a)).
cf73 :- catch(throw(x), x, (cf_m(X), !)), X > 0.

%% a shallow backtrack by once/1, not/1, ignore/1 and catch/3 (3.78.5's
%% rules, the four frames now): once/1's else no choice point of swipl's,
%% not/1's own fail deep, a `\+' in the goal fails back into its `;'
cf74 :- once(fail).
cf75 :- ( not(atom(a)) ; true ).
cf76 :- ( not(( \+ atom(a) ; true )) ; true ).
cf77 :- catch(( \+ atom(a) ; true ), _, true).
cf78 :- once(( \+ atom(a) ; true )).
cf79 :- ignore(( \+ atom(a) ; true )).
cf80 :- not(atom(a)).
cf80.

%% in a clause that hides its children (generate_debug_info false): the
%% catch/3 hidden and a level, and a goal nothing defines a port
:- set_prolog_flag(generate_debug_info, false).
cf81 :- catch(lists:cf_nosuch, _, true).
:- set_prolog_flag(generate_debug_info, true).

%% a retry in a hidden call of a catch/3's recovery is the catch's Redo,
%% once it has exited: the frame hides its children after its catch too
cf82 :- catch(throw(x), x, member(X, [1, 2, 3])), X > 2.
