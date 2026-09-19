%% library(reason) -- a paragraph in, predicates out: every sentence shape
%% the header promises, pinned; the four decisions, pinned; and the one
%% claim that matters, that what comes out ASSERTS and then PROVES.
%%
%%     cocolog -s test/reason.pl        from the checkout root
%%
%% One process for the lot. Nothing here needs a server or a build flag:
%% the library is clauses over a DCG, so this case runs everywhere.

:- use_module('test/prelude.pl').
:- use_module(library(reason)).

main :-
    tokens, facts, copula, negation, rules, relative, lexicon, naming,
    round_trip, refusals, declares, refused, truth, errors,
    checks_done.

%% ---- the tokeniser -----------------------------------------------------

tokens :-
    section('tokens'),
    reason_tokens('Hello, World. Alice_1 x9!', T1),
    check('word(Lower, Case), comma, stop; digits and _ stay in a word', T1,
          [word(hello, upper), ',', word(world, upper), '.', word(alice_1, upper), word(x9, lower), '.']),
    reason_tokens('a? b! c.', T2),
    check('? and ! are stops too', T2, [word(a, lower), '.', word(b, lower), '.', word(c, lower), '.']),
    reason_tokens("codes work", T3),
    check('a code list is text', T3, [word(codes, lower), word(work, lower)]),
    reason_tokens('(semi;colons) -- dashes', T4),
    check('other punctuation is dropped', T4, [word(semi, lower), word(colons, lower), word(dashes, lower)]),
    reason_tokens('', T5),
    check('empty text, no tokens', T5, []).

%% ---- a proper subject and a verb ----------------------------------------

facts :-
    section('facts'),
    reason_sentence('Alice owns a red car.', F1),
    check('indefinite object: an individual, its noun, its adjective', F1,
          [car(car_1), red(car_1), own(alice, car_1)]),
    reason_sentence('Alice owns a big red car.', F2),
    check('every word before the noun is an adjective', F2,
          [car(car_1), big(car_1), red(car_1), own(alice, car_1)]),
    reason_sentence('Alice likes Bob.', F3),
    check('a proper object is its constant', F3, [like(alice, bob)]),
    reason_sentence('Alice sleeps.', F4),
    check('no object: a unary claim', F4, [sleep(alice)]),
    reason_sentence('Alice may access the server.', F5),
    check('a modal joins its verb; `the N'' is the class atom', F5, [may_access(alice, server)]),
    reason_sentence('Alice has a badge.', F6),
    check('`has'' is have, irregular', F6, [badge(badge_1), have(alice, badge_1)]),
    reason_sentence('Alice watches Bob.', F7),
    check('-es comes off after ch', F7, [watch(alice, bob)]),
    reason_sentence('Alice passes Bob.', F8),
    check('-es comes off after ss', F8, [pass(alice, bob)]),
    findall(T, reason_sentence('Alice owns a red car.', T), Rs),
    length(Rs, NR),
    check('the grammar is deterministic: one reading', NR, 1).

%% ---- the copula ---------------------------------------------------------

copula :-
    section('copula'),
    reason_sentence('Alice is happy.', C1),        check('is ADJ',        C1, [happy(alice)]),
    reason_sentence('Alice is a person.', C2),     check('is a NOUN',     C2, [person(alice)]),
    reason_sentence('Alice is an employee.', C3),  check('is an NOUN',    C3, [employee(alice)]),
    reason_sentence('Alice is not happy.', C4),    check('is not ADJ',    C4, [neg(happy(alice))]),
    reason_sentence('Alice is not a robot.', C5),  check('is not a NOUN', C5, [neg(robot(alice))]).

%% ---- negation: neg/1, and the class atom ----------------------------------

negation :-
    section('negation'),
    reason_sentence('Bob does not own a car.', N1),
    check('does not V a N: neg/1 over the CLASS, no car_1', N1, [neg(own(bob, car))]),
    reason_sentence('Bob does not sleep.', N2),
    check('does not V: unary', N2, [neg(sleep(bob))]),
    reason_sentence('Bob does not like Alice.', N3),
    check('does not V Proper', N3, [neg(like(bob, alice))]),
    reason_sentence('Bob does not have a badge.', N4),
    check('the negative names the SAME predicate as the positive', N4, [neg(have(bob, badge))]).

%% ---- every: a rule --------------------------------------------------------

rules :-
    section('rules'),
    reason_sentence('Every employee is a person.', [R1]),
    R1 = (H1 :- B1), H1 = person(X1), B1 = employee(Y1),
    yes_no(X1 == Y1, Same1),
    check('one variable through head and body', Same1, yes),
    yes_no(var(X1), Var1),
    check('and it is a VARIABLE, not employee_1', Var1, yes),
    reason_sentence('Every employee has a badge.', [R2]),
    R2 = (have(X2, O2) :- employee(Y2)),
    yes_no(X2 == Y2, Same2), check('rule over a verb', Same2, yes),
    check('an indefinite object in a rule is the class atom', O2, badge),
    reason_sentence('Every employee may access the server.', [R3]),
    R3 = (may_access(X3, O3) :- employee(Y3)),
    yes_no(X3 == Y3, Same3), check('modal in a rule', Same3, yes),
    check('the server', O3, server),
    reason_sentence('All employees are people.', [R4]),
    R4 = (H4 :- B4), functor(H4, HN4, 1), functor(B4, BN4, 1),
    check('`all'' and `are''; nouns are taken as written, plural included', HN4-BN4, people-employees),
    reason_sentence('Every employee is happy.', [R5]),
    R5 = (happy(X5) :- employee(Y5)),
    yes_no(X5 == Y5, Same5), check('rule over an adjective', Same5, yes).

%% ---- that is [not] ADJ: a condition ----------------------------------------

relative :-
    section('relative clause'),
    reason_sentence('Every employee that is authorized may access the server.', [L1]),
    L1 = (may_access(X1, server) :- employee(Y1), authorized(Z1)),
    yes_no((X1 == Y1, Y1 == Z1), S1),
    check('`that is ADJ'' is a second body goal on the same variable', S1, yes),
    reason_sentence('Every employee that is not suspended may access the server.', [L2]),
    L2 = (may_access(X2, server) :- employee(Y2), \+ suspended(Z2)),
    yes_no((X2 == Y2, Y2 == Z2), S2),
    check('`that is not ADJ'' is \\+ in the body, same variable', S2, yes),
    reason_sentence('Every person that is happy sleeps.', [L3]),
    L3 = (sleep(X3) :- person(Y3), happy(Z3)),
    yes_no((X3 == Y3, Y3 == Z3), S3),
    check('a relative clause before an intransitive verb', S3, yes).

%% ---- the lexicon overrides position ------------------------------------------

lexicon :-
    section('lexicon'),
    assertz(reason_verb(owns, owns)),
    reason_sentence('Carol owns a car.', X1),
    check('reason_verb/2 keeps a surface form', X1, [car(car_1), owns(carol, car_1)]),
    retract(reason_verb(owns, owns)),
    reason_sentence('Carol owns a car.', X2),
    check('and retracting it restores the base form', X2, [car(car_1), own(carol, car_1)]),
    assertz(reason_proper(acme, acme_corp)),
    reason_sentence('Acme employs Dave.', X3),
    check('reason_proper/2 names the constant', X3, [employ(acme_corp, dave)]),
    reason_sentence('Dave joins acme.', X4),
    check('and a lexicon proper noun needs no capital', X4, [join(dave, acme_corp)]),
    retract(reason_proper(acme, acme_corp)),
    yes_no(reason_sentence('Dave joins acme.', _), X5),
    check('without it a lowercase word is no object', X5, no).

%% ---- naming the individuals ----------------------------------------------------

naming :-
    section('naming'),
    reason_text('Alice owns a red car. Bob owns a car. Carol owns a dog.', M1),
    check('numbered per noun, in order, across the paragraph', M1,
          [car(car_1), red(car_1), own(alice, car_1),
           car(car_2), own(bob, car_2),
           dog(dog_1), own(carol, dog_1)]),
    reason_text('Alice owns a car.', [variables(true)], M2),
    M2 = [car(V2), own(alice, W2)],
    yes_no((var(V2), V2 == W2), K2),
    check('variables(true) keeps the individual a shared variable', K2, yes),
    reason_name([car(V3), own(a, V3), (p(Q3) :- q(Q3))], M3),
    M3 = [car(N3), own(a, N3b), (p(Q3b) :- q(Q3c))],
    check('reason_name/2 names a fact''s variable', N3-N3b, car_1-car_1),
    yes_no((var(Q3b), Q3b == Q3c), K3),
    check('and leaves a rule''s alone', K3, yes),
    reason_name([g(V4, a)], M4),
    check('a variable no unary term introduces is a thing', M4, [g(thing_1, a)]),
    reason_text('', M5),
    check('empty text, no terms', M5, []).

%% ---- the claim: what comes out asserts, and then proves --------------------------

round_trip :-
    section('round trip'),
    reason_text('Alice is an employee. Alice is authorized. Bob is an employee. Bob is suspended. Every employee that is authorized may access the server. Every employee that is not suspended may access the server. Bob does not own a car.', Ts),
    length(Ts, N), check('seven sentences, seven terms', N, 7),
    forall(member(T, Ts), assertz(T)),
    findall(W, may_access(W, server), Ws), sort(Ws, Who),
    check('the rules the text wrote prove Alice and not Bob', Who, [alice]),
    yes_no(may_access(bob, server), Bob),
    check('Bob: not authorized, and suspended', Bob, no),
    yes_no(neg(own(bob, car)), Neg),
    check('and the negative sentence is a fact to query', Neg, yes).

%% ---- what it refuses, by failing -----------------------------------------------------

refusals :-
    section('refusals'),
    yes_no(reason_sentence('She uses it.', _), F1),
    check('a pronoun object', F1, no),
    yes_no(reason_text('Alice owns a car. She uses it.', _), F2),
    check('a paragraph half understood is refused whole', F2, no),
    yes_no(reason_sentence('If an employee is authorized then it may access the server.', _), F3),
    check('if-then', F3, no),
    yes_no(reason_sentence('owns a car.', _), F4),
    check('no subject', F4, no),
    yes_no(reason_sentence('Alice owns.', _), F5),
    check('a transitive frame with nothing after the verb is... a unary claim: own(alice)', F5, yes),
    yes_no(reason_sentence('Alice a car.', _), F6),
    check('no verb', F6, no),
    yes_no(reason_sentence('Alice owns a house in Rome.', _), F7),
    check('a prepositional phrase: REFUSED, where it once parsed as rome(rome_1)', F7, no),
    reason_refused('Alice owns a house in Rome.', F7r),
    check('  -- and reason_refused/2 names it', F7r, 'alice owns a house in rome'),
    yes_no(reason_sentence('Alice sleeps at the house.', _), F8),
    check('a preposition after an intransitive verb', F8, no),
    yes_no(reason_sentence('Alice is in.', _), F9),
    check('a preposition is not an adjective', F9, no),
    yes_no(reason_sentence('Every tenant that is not exempt must pay the rent to Alice.', _), F10),
    check('a preposition after a rule''s object', F10, no).

%% ---- a rule declares what its body names ------------------------------------------------

declares :-
    section('declares'),
    reason_text('Every member that is not banned may post the message. Zed is a member.', D1),
    forall(member(T, D1), assertz(T)),
    catch(( may_post(zed, message) -> R1 = proves ; R1 = fails ), E1, R1 = threw(E1)),
    check('`that is not banned'' with nobody banned: the rule PROVES, no existence_error', R1, proves),
    reason_text('Every widget that is blue is nice.', D2),
    forall(member(T, D2), assertz(T)),
    catch(( nice(w9) -> R2 = proves ; R2 = fails ), E2, R2 = threw(E2)),
    check('a body predicate nothing asserted: the rule FAILS, no existence_error', R2, fails),
    yes_no(reason_refused('Every gadget that is not broken works. She fixes it.', _), R3),
    check('reason_refused/2 declares nothing (still a pure check)', R3, yes),
    catch(( broken(g1) -> R4 = proves ; R4 = fails ), E4, R4 = threw(E4)),
    R4 = threw(error(existence_error(procedure, PI4), _)),
    check('  -- so broken/1 is still absent afterwards', PI4, broken/1).

%% ---- reason_refused/2 names the sentence ----------------------------------------------

refused :-
    section('refused'),
    reason_refused('Alice owns a car. Every tenant must_pay rent. Bob is a tenant.', R1),
    check('the first refused sentence, as its words', R1, 'every tenant must_pay rent'),
    findall(R, reason_refused('Alice owns a car. She uses it. Bob sleeps. It rains.', R), Rs2),
    check('every refused sentence on backtracking, in order', Rs2, ['she uses it', 'it rains']),
    yes_no(reason_refused('Alice owns a car. Bob sleeps.', _), R3),
    check('fails when the whole text parses', R3, no),
    yes_no(reason_refused('', _), R4),
    check('and on empty text', R4, no),
    reason_refused('Hello, World, again!', R5),
    check('punctuation is not in the words', R5, 'hello world again').

%% ---- truth/2: four answers ---------------------------------------------------------------

truth :-
    section('truth'),
    reason_text('Alice is happy. Bob is not happy. Carol is a tenant. Every tenant that is not exempt must pay the rent. Dave is a tenant. Dave is exempt.', Ts),
    forall(member(T, Ts), assertz(T)),
    truth(happy(alice), T1),          check('said: true', T1, true),
    truth(happy(bob), T2),            check('denied: false', T2, false),
    truth(happy(carol), T3),          check('never mentioned: unknown', T3, unknown),
    truth(sad(alice), T4),            check('a predicate that does not exist: unknown, not an error', T4, unknown),
    truth(must_pay(carol, rent), T5), check('proved through a rule: true', T5, true),
    truth(must_pay(dave, rent), T6),  check('the rule does not fire and nothing denies it: unknown', T6, unknown),
    assertz(reason_closed(must_pay/2)),
    truth(must_pay(dave, rent), T7),  check('the same goal once the predicate is closed: false', T7, false),
    truth(must_pay(carol, rent), T7b), check('closing changes nothing that proves', T7b, true),
    retract(reason_closed(must_pay/2)),
    assertz(neg(happy(alice))),
    truth(happy(alice), T8),          check('said AND denied: conflict', T8, conflict),
    retract(neg(happy(alice))),
    truth(neg(happy(bob)), T9),       check('a neg/1 goal is a goal like any other', T9, true),
    catch(( truth(happy(_), _), E10 = none ), error(E10, _), true),
    check('a variable is not a question with a truth value', E10, instantiation_error),
    catch(( truth(f(a), _), E11 = none ), error(E11, _), true),
    check('an absent predicate does not throw', E11, none).

%% ---- errors --------------------------------------------------------------------------

errors :-
    section('errors'),
    catch(( reason_tokens(42, _), E1 = none ), error(E1, _), true),
    check('not text: type_error', E1, type_error(text, 42)),
    catch(( reason_text(f(x), _), E2 = none ), error(E2, _), true),
    check('a compound is not text either', E2, type_error(text, f(x))).
