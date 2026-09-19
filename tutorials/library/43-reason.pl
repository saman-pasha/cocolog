%% cocolog tutorial 43 -- library(reason): a paragraph in, predicates out.
%%
%% TIER 2: `use_module(library(reason))', from library/reason.pl. Clauses only.
%%
%%     cocolog -s tutorials/library/43-reason.pl
%%
%% A KNOWLEDGE BASE IS ROWS, AND THIS IS HOW A PARAGRAPH BECOMES SOME. The
%% library reads a controlled English -- a proper noun or `every NOUN' as
%% subject, a verb or the copula, an object with `a', `an' or `the' -- and
%% hands back a list of terms: facts, neg/1 facts, and rules written
%% (Head :- Body). Every one of them is a term assertz/1 takes, and section
%% 6 below does exactly that and then PROVES through the rules the text
%% wrote. Nothing is called out to: the grammar is a DCG whose semantic
%% argument is the term, the way library(http) reads a request.
%%
%% THE LEXICON IS DATA AND POSITION IS THE DEFAULT. Nothing here declares
%% that `car' is a noun or `owns' a verb -- the last word of a noun phrase
%% is its noun, what precedes it is adjectives, the word after the subject
%% is the verb. reason_noun/1, reason_adj/1, reason_verb/2 and
%% reason_proper/2 are consulted first, and section 7 shows one saying a
%% word is not what its position suggests.
%%
%% FOUR DECISIONS YOU WILL MEET, each argued in library/reason.pl's header:
%% a verb comes back in its BASE form (`owns' -> own), so a positive and a
%% negative sentence name one predicate; an indefinite object is an
%% INDIVIDUAL in a fact (car_1, with car(car_1) beside it) and a CLASS atom
%% under negation or in a rule, because Prolog has no negative fact and no
%% existential in a head; `the server' is the constant `server'; and a
%% negative sentence is neg/1, a term you can store and query, never \+,
%% which is a question about provability and not a claim the text made.

:- use_module(library(reason)).

main :-
    format("~n1. One sentence, one fact -- and the individual it introduces~n", []),
    reason_sentence('Alice owns a red car.', T1),
    must('Alice owns a red car', T1, [car(car_1), red(car_1), own(alice, car_1)]),
    reason_sentence('Alice likes Bob.', T1b),
    must('Alice likes Bob', T1b, [like(alice, bob)]),
    reason_sentence('Alice sleeps.', T1c),
    must('an intransitive verb', T1c, [sleep(alice)]),

    format("~n2. The copula: a property, a class, and their negations~n", []),
    reason_sentence('Alice is happy.', T2a),      must('is ADJ',      T2a, [happy(alice)]),
    reason_sentence('Alice is a person.', T2b),   must('is a NOUN',   T2b, [person(alice)]),
    reason_sentence('Alice is not happy.', T2c),  must('is not ADJ',  T2c, [neg(happy(alice))]),
    reason_sentence('Alice is not a robot.', T2d), must('is not a NOUN', T2d, [neg(robot(alice))]),

    format("~n3. A negative sentence with an indefinite object names the CLASS~n", []),
    reason_sentence('Bob does not own a car.', T3),
    must('does not own a car', T3, [neg(own(bob, car))]),
    show('   -- and not car(car_1): the sentence says no such car exists', ''),

    format("~n4. `every': a rule, and its variable stays a variable~n", []),
    reason_sentence('Every employee is a person.', [R4]),
    R4 = (H4 :- B4), H4 = person(X4), B4 = employee(Y4),
    ( X4 == Y4 -> Shared4 = yes ; Shared4 = no ),
    must('one variable through head and body', Shared4, yes),
    ( var(X4) -> Var4 = yes ; Var4 = no ),
    must('and it is still a variable, not employee_1', Var4, yes),
    reason_sentence('Every employee has a badge.', [R4b]),
    R4b = (have(_, Obj4b) :- employee(_)),
    must('an indefinite object in a rule is the class atom', Obj4b, badge),

    format("~n5. `that is [not] ADJ': a condition, and \\+ in the body~n", []),
    reason_sentence('Every employee that is authorized may access the server.', [R5a]),
    R5a = (may_access(X5a, server) :- employee(Y5a), authorized(Z5a)),
    ( X5a == Y5a, Y5a == Z5a -> S5a = yes ; S5a = no ),
    must('may access -> may_access/2, over one variable', S5a, yes),
    reason_sentence('Every employee that is not suspended may access the server.', [R5b]),
    R5b = (may_access(X5b, server) :- employee(Y5b), \+ suspended(Z5b)),
    ( X5b == Y5b, Y5b == Z5b -> S5b = yes ; S5b = no ),
    must('`that is not'' is \\+ in the body, over one variable', S5b, yes),

    format("~n6. The terms are what assertz/1 takes -- and then the rules RUN~n", []),
    reason_text('Alice is an employee. Alice is authorized. Bob is an employee. Bob is suspended. Every employee that is authorized may access the server. Every employee that is not suspended may access the server.', T6),
    length(T6, N6), must('six sentences, six terms', N6, 6),
    forall(member(T, T6), assertz(T)),
    findall(W, may_access(W, server), Ws6), sort(Ws6, Who6),
    must('who may access the server', Who6, [alice]),
    ( may_access(bob, server) -> Bob6 = yes ; Bob6 = no ),
    must('Bob is suspended and not authorized', Bob6, no),

    format("~n7. The lexicon overrides position~n", []),
    reason_sentence('Carol owns a car.', T7a),
    must('by default the verb is normalised', T7a, [car(car_1), own(carol, car_1)]),
    assertz(reason_verb(owns, owns)),
    reason_sentence('Carol owns a car.', T7b),
    must('reason_verb/2 keeps the surface form', T7b, [car(car_1), owns(carol, car_1)]),
    retract(reason_verb(owns, owns)),
    assertz(reason_proper(acme, acme_corp)),
    reason_sentence('Acme employs Dave.', T7c),
    must('reason_proper/2 names the constant', T7c, [employ(acme_corp, dave)]),
    retract(reason_proper(acme, acme_corp)),

    format("~n8. Across a paragraph the individuals are numbered in order~n", []),
    reason_text('Alice owns a red car. Bob owns a car. Carol owns a dog.', T8),
    must('car_1, car_2, dog_1', T8,
         [car(car_1), red(car_1), own(alice, car_1),
          car(car_2), own(bob, car_2),
          dog(dog_1), own(carol, dog_1)]),
    reason_text('Alice owns a car.', [variables(true)], T8v),
    T8v = [car(V8), own(alice, W8)],
    ( var(V8), V8 == W8 -> Kept8 = yes ; Kept8 = no ),
    must('variables(true) keeps the individual a variable', Kept8, yes),

    format("~n9. What it refuses, and how: by failing~n", []),
    ( reason_sentence('She uses it.', _) -> P9a = parsed ; P9a = refused ),
    must('a pronoun object', P9a, refused),
    ( reason_text('Alice owns a car. She uses it.', _) -> P9b = parsed ; P9b = refused ),
    must('a paragraph half understood is refused whole', P9b, refused),
    ( reason_sentence('If an employee is authorized then it may access the server.', _)
    -> P9c = parsed ; P9c = refused ),
    must('if-then with a pronoun (write `that is'' instead)', P9c, refused),
    ( reason_sentence('Alice owns a house in Rome.', _) -> P9d = parsed ; P9d = refused ),
    must('a prepositional phrase -- refused, never misread as rome(rome_1)', P9d, refused),

    format("~n10. The tokens, for a grammar of your own~n", []),
    reason_tokens('Hello, World. Alice_1!', Tk),
    must('word(Lower, Case), comma, stop', Tk,
         [word(hello, upper), ',', word(world, upper), '.', word(alice_1, upper), '.']),

    format("~n11. Which sentence was refused: reason_refused/2~n", []),
    ( reason_text('Alice owns a car. Every tenant must_pay rent.', _) -> W11 = parsed ; W11 = refused ),
    must('a bare noun object is not a shape it reads, so the text is refused', W11, refused),
    reason_refused('Alice owns a car. Every tenant must_pay rent.', R11),
    must('and this names the sentence to rewrite', R11, 'every tenant must_pay rent'),
    reason_text('Alice owns a car. Every tenant must pay the rent.', T11),
    length(T11, N11), must('written as `the rent'' it parses', N11, 3),

    format("~n12. truth/2: said, denied, never mentioned, contradicted~n", []),
    reason_text('Eve is a tenant. Eve is not exempt. Every tenant that is not exempt must pay the rent.', T12),
    forall(member(X12, T12), assertz(X12)),
    truth(must_pay(eve, rent), V12a),  must('proved through the rule', V12a, true),
    truth(exempt(eve), V12b),          must('the text denied it', V12b, false),
    truth(landlord(eve), V12c),        must('the text never said', V12c, unknown),
    truth(may_access(eve, server), V12d), must('nor did anything: no rule fires', V12d, unknown),
    assertz(reason_closed(may_access/2)),
    truth(may_access(eve, server), V12e), must('closed, the same silence is false', V12e, false),
    retract(reason_closed(may_access/2)),
    assertz(neg(tenant(eve))),
    truth(tenant(eve), V12f),          must('said and denied both: conflict', V12f, conflict),
    retract(neg(tenant(eve))),

    format("~nDone.~n", []).

%% Duplicated at the foot of every tutorial on purpose: one you can copy
%% anywhere and run is worth six repeated lines, and one that needs a support
%% file beside it stops working the moment it moves.

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
