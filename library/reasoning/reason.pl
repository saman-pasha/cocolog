%% cocolog -- library(reasoning/reason): a paragraph in, predicates out.
%%
%%     :- use_module(library(reasoning/reason)).
%%
%%     ?- reason_text("Alice owns a red car. Every employee that is
%%                     authorized may access the server.", Terms).
%%     Terms = [ car(car_1), red(car_1), own(alice, car_1),
%%               (may_access(X, server) :- employee(X), authorized(X)) ].
%%
%% TIER 2, and clauses only. Its grammar is a DCG over tokens, the way
%% library(http) reads HTTP/1.1 and library(xml) reads a document: the
%% semantic argument of each nonterminal is the TERM the phrase stands for,
%% so parsing and interpretation are one walk. Nothing is called out to.
%%
%% THE LEXICON IS DATA. Four dynamic predicates say what a word is --
%% reason_noun/1, reason_adj/1, reason_verb/2, reason_proper/2 -- and a
%% program extends them with assertz/1 like any other fact. They are
%% consulted FIRST; when they are silent, POSITION decides: the last word of
%% a noun phrase is its noun, every word between the determiner and that
%% noun is an adjective, and the word after the subject is the verb. So the
%% examples above parse with an empty lexicon, and a lexicon entry is how a
%% program says a word is not what its position suggests. The closed
%% classes -- determiners, quantifiers, modals, the copula, `does', `not',
%% `that' -- are fixed, because those are the words the grammar is made of.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     reason_text(+Text, -Terms)
%%     reason_text(+Text, +Options, -Terms)
%%         Text is an atom, a string or a code list; sentences end at `.',
%%         `!' or `?'. Terms is a list: facts, neg/1 facts, and rules
%%         written (Head :- Body), each one a term assertz/1 will take.
%%         Indefinite individuals are NAMED, car_1 then car_2 across the
%%         whole text, unless Options carries variables(true).
%%
%%     reason_sentence(+Text, -Terms)
%%     reason_sentence(+Text, +Options, -Terms)
%%         One sentence, with no state: a subject pronoun in it is refused.
%%         The grammar is DETERMINISTIC by construction --
%%         the noun is the last word of its phrase and the closed classes
%%         are fixed -- so there is one reading or none; a program that
%%         adds grammar clauses of its own gets its readings on
%%         backtracking, which is the engine's search and needs nothing
%%         from here.
%%
%%     reason_tokens(+Text, -Tokens)
%%         The tokeniser, exposed. A token is word(Lower, upper|lower),
%%         num(N) for digits (500, 5.5, 1,000; `5%' is 5 and the word
%%         percent), `.' or `,'.
%%
%%     reason_refused(+Text, -Sentence)
%%         The first sentence reason_text/2 would refuse, as its words
%%         joined by spaces -- and every later one on backtracking. FAILS
%%         when the whole text parses. reason_text/2 refuses a paragraph
%%         whole and says nothing; this is how a caller finds out which
%%         sentence to rewrite.
%%
%%     reason_question(+Text, -Question)
%%         One sentence read as a question: question(Goal) for yes or no,
%%         question(X, Goal) with X for what `who', `what' or `where' asks.
%%         The forms are under THE QUESTIONS IT READS, below.
%%
%%     reason_ask(+Text, -Answers)
%%         Every question in Text answered against the knowledge base as it
%%         stands, one answer each in order; the statements in Text are
%%         read for their state and asserted by nobody. A yes-or-no
%%         question answers yes(Why), no(Why), unknown or conflict --
%%         truth/2's verdict, with the fact or the rule it rests on -- and a
%%         who, what or where question a list of Value-Why, empty when
%%         nobody. Neither this nor reason_question/2 resets the state, so
%%         `Is she licensed?' may follow the paragraph that introduced her.
%%
%%     reason_prose(+Text, -Terms)
%%     reason_ask_prose(+Text, -Answers)
%%         TYPED prose, not the controlled English: the shipped tagger
%%         normalises it first, then reason_text/2 or reason_ask/2 reads
%%         what came out. OPTIONAL, and loaded on first use --
%%         library(reasoning/tagger) and the model beside the library
%%         (tagger_pretrained/1 there), which need library(torch) and the
%%         embedded engine. Without them the call raises
%%         existence_error(tagger, pretrained), and nothing else here
%%         changes.
%%
%%     reason_why(+Goal, -Why)
%%         The REASON a ground goal holds: fact when it was said,
%%         rule(Head :- Body) with the body as it proved when a rule gave
%%         it (one level), denied when its negation was said; fails when
%%         nothing holds it up.
%%
%%     reason_amount(+Object, -Quantity)
%%         What `how much' asks for: the quantity the object IS -- a
%%         quantity/2,3 term or a bare number -- or, for a class atom, the
%%         amount the text gave it: after `Nadia pays the rent. The rent is
%%         500 euros.' the object `rent' answers quantity(500, euros). The
%%         goal a how-much question reads to calls it last.
%%
%%     reason_count(+Object, +Noun, -N)
%%         What `how many NOUN' asks for: N when the object is
%%         quantity(N, Noun) or quantity(N, Noun, Of). The goal a how-many
%%         question reads to calls it last.
%%
%%     truth(+Goal, -Truth)
%%         true, false, unknown or conflict, for a GROUND goal against the
%%         knowledge base as it stands: what a text said, what it denied,
%%         what it never mentioned, and what it contradicted. The whole
%%         argument is below, under FIVE DECISIONS.
%%
%%     reason_closed(?Name/Arity)          dynamic; see truth/2
%%
%%     reason_name(+Terms, -Named)
%%         What reason_text/2 does last: every variable is named after the
%%         noun that introduced it, numbered from 1 in order of appearance.
%%
%%     reason_noun(?Word)                  dynamic, the lexicon
%%     reason_adj(?Word)
%%     reason_verb(?Word, ?Base)
%%     reason_proper(?Word, ?Constant)
%%
%% ---- THE SENTENCES IT READS -------------------------------------------
%%
%%   Alice owns a red car.               car(V), red(V), own(alice, V)
%%   Alice is happy.                     happy(alice)
%%   Alice is a person.                  person(alice)
%%   Alice is not happy.                 neg(happy(alice))
%%   Bob does not own a car.             neg(own(bob, car))
%%   Alice sleeps.                       sleep(alice)
%%   Alice may access the server.        may_access(alice, server)
%%   Alice lives_in Rome.                live_in(alice, rome)
%%   Alice rents a flat in Rome.         flat(V), rent_in(alice, V, rome)
%%   Alice is a baker. She is licensed.  baker(alice), licensed(alice)
%%   Alice pays 500 euros.               pay(alice, quantity(500, euros))
%%   Alice owns three vineyards.         own(alice, quantity(3, vineyards))
%%   Alice buys two litres of milk.      buy(alice, quantity(2, litres, milk))
%%   The rent is 500 euros.              amount(rent, quantity(500, euros))
%%   Does Alice own a car?               question((car(V), own(alice, V)))
%%   Who is licensed?                    question(X, licensed(X))
%%   How much does Alice pay?            question(Q, (pay(alice, O), reason_amount(O, Q)))
%%   How many vineyards does Alice own?  question(N, (own(alice, O), reason_count(O, vineyards, N)))
%%   Every employee is a person.         person(X) :- employee(X)
%%   Every employee has a badge.         have(X, badge) :- employee(X)
%%   Every employee that is authorized   may_access(X, server) :-
%%       may access the server.              employee(X), authorized(X)
%%   Every employee that is not          may_access(X, server) :-
%%       suspended may access the server.    employee(X), \+ suspended(X)
%%
%% A subject is a proper noun or a quantified class; an object is a proper
%% noun or a determined noun phrase. A place after an object joins the
%% relation -- `rents a flat in Rome' is rent_in/3, the place its last
%% argument -- exactly as a preposition written joined to a bare verb does
%% (`lives_in Rome' is live_in/2, the verb inside it stemmed): after a bare
%% verb the two words are ONE relation and are written as one, so `sleeps
%% in Rome' is refused where `sleeps_in Rome' is read, and it is
%% library(reasoning/normalise)'s assembler that joins them. Which is also
%% why `Alice owns a house in Rome' is a fact about a house in Rome and
%% `Alice sleeps in Rome' is not a fact at all: only after an object can the
%% preposition belong to nothing else. A paragraph carries ONE piece of
%% state from sentence to sentence, the subject of the last fact, and
%% `she', `he' or `they' as a subject stands for it -- so `Alice is a
%% baker. She is licensed.' is two facts about Alice, and `She is licensed'
%% with no fact before it is refused. That is the one coreference this
%% reader does: `it' is left alone (`It rains' is not about anybody), and
%% a pronoun as an object is refused. A QUESTION IS A GOAL, the term the
%% statement would have asserted with a variable where the question word
%% stood, and reason_ask/2 answers it against the knowledge base with the
%% REASON beside the answer: the fact that was said, the rule and the
%% body that proved it, or the denial. A QUANTITY IS A VALUE, NOT AN
%% INDIVIDUAL: a number and the noun it counts -- `500 euros', `three
%% vineyards', `5.5 percent', `two litres of milk' -- reads as
%% quantity(N, Noun) or quantity(N, Unit, Noun), the noun AS WRITTEN
%% (euros, not euro, by the rule below), the number as digits or as the
%% number words (`twenty five', `two hundred', `a hundred'), and a bare
%% number as the number. No car_1 is introduced for `three cars', because
%% three of them is not one, so the object of the claim is the quantity
%% term itself, in a fact, a rule and a denial alike -- must_pay(X,
%% quantity(500, euros)) :- tenant(X); neg(pay(bob, quantity(500,
%% euros))). `The rent is 500 euros' is the one sentence with a definite
%% SUBJECT, and it is amount(rent, quantity(500, euros)): what a definite
%% object costs, said once and asked for by `how much'. A quantity
%% carries no adjective (`three red cars' is refused, not read with `red'
%% dropped) and no comparison (`more than 500 euros' is refused). The
%% relative clause `that is [not]
%% ADJ' is how a condition is written, and it is deliberately the ONLY
%% way: `if ... then ...' with a pronoun would need the pronoun bound
%% inside a rule, and a rule with two conditions is two sentences or one
%% relative clause per condition. What it does not read it REFUSES, by
%% failing -- reason_text/2 fails on the first sentence that does not
%% parse rather than skipping it, because a paragraph half understood is
%% worse than one refused; reason_refused/2 then names the sentence.
%%
%% ---- FIVE DECISIONS, EACH WITH ITS REASON -----------------------------
%%
%% A NOUN IS TAKEN AS WRITTEN. `All employees are people' gives
%% people(X) :- employees(X): no plural comes off, because a rule that
%% strips an `s' from a noun turns `bus' into `bu' and `glass' into
%% `glas', and a program that wants the singular writes it.
%%
%% A VERB IS REPORTED IN ITS BASE FORM. `Alice owns a car' and `Bob does
%% not own a car' must name ONE predicate or no rule can mention both, and
%% the surface forms differ (`owns', `own'). So a third-person `-s' comes
%% off, `has' becomes `have', and reason_verb/2 overrides: assertz(
%% reason_verb(owns, owns)) keeps the surface form if a program wants it.
%%
%% AN INDEFINITE OBJECT IS AN INDIVIDUAL IN A FACT AND A CLASS EVERYWHERE
%% ELSE. `Alice owns a car' asserts that some car exists -- so a fresh
%% individual, car_1, and the fact car(car_1) beside own(alice, car_1).
%% `Bob does not own a car' asserts that NO such car exists, and a fresh
%% car_2 would assert one; `Every employee has a badge' has no single
%% badge for the head of a rule to name. Both report the object by its
%% class atom: neg(own(bob, car)), have(X, badge) :- employee(X). Prolog
%% has no existential in a head and no negative fact, and this is the
%% honest projection onto what it has, written where a reader will see
%% it rather than left to be discovered.
%%
%% A DEFINITE OBJECT IS THE CLASS ATOM. `the server' names THE server, the
%% one this program is about, so it is the constant `server' -- which is
%% what a rule wants: may_access(X, server). A program with several
%% servers writes their names.
%%
%% NEGATION IS neg/1, NOT \+/1. A negative SENTENCE is knowledge -- `Bob
%% does not own a car' is something the text said -- and \+ is a question
%% about provability, which is not the same claim. neg/1 is a term a
%% program can assertz, query and reason over as it likes; the one place
%% \+ appears is the BODY of a rule from `that is not', where "not
%% provable" is exactly what a rule condition means.
%%
%% A RULE DECLARES WHAT ITS BODY NAMES, because otherwise it throws.
%% `\+ exempt(X)' over a knowledge base with no exempt/1 in it is an
%% existence_error, not a failure -- SWI's rule too -- so `every tenant that
%% is not exempt must pay the rent' would throw at the first tenant unless
%% somebody had also been declared exempt. reason_text/2 therefore calls
%% dynamic/1 for every predicate a rule's body mentions, at the moment it
%% hands the rule back: the promise that every term is one assertz/1 takes
%% is only worth keeping if the rule then RUNS. Found by the lesson, whose
%% twelfth section named nobody exempt.
%%
%% A MODAL JOINS ITS VERB. `may access' is may_access/2 and `must submit'
%% is must_submit/2, because a modality is part of what is claimed and a
%% predicate name is where a claim's shape lives. `may' and `must' as
%% separate wrapper terms would be a deontic logic, which this is not.
%%
%% truth/2 IS FOUR-VALUED, AND THAT IS ONE MORE THAN WAS ASKED FOR. Prolog
%% answers yes or no, and no means "not provable", which is not "false":
%% a knowledge base that never mentioned cats cannot deny that Tom is one.
%% So truth(G, T) asks two questions -- does G prove, does neg(G) prove --
%% and reads the pair:
%%
%%     G proves, neg(G) does not      true      the text said it
%%     neg(G) proves, G does not      false     the text denied it
%%     neither proves                 unknown   the text never said
%%     BOTH prove                     conflict  the text contradicted itself
%%
%% The fourth is the one a three-valued answer would hide: a paragraph that
%% says `Alice is happy' and `Alice is not happy' has told you something,
%% and answering `true' about it because the positive fact was found first
%% is not reading the text, it is reading the clause order. A predicate that
%% does not exist proves nothing and is `unknown', not an error: the whole
%% point of the value is that silence is an answer.
%%
%% AND A PROGRAM MAY CLOSE A PREDICATE. Sometimes the text IS the whole
%% truth -- a roster, a list of who is exempt -- and then not-provable
%% really is false. assertz(reason_closed(exempt/1)) says so, and truth/2
%% answers `false' for exempt(X) it cannot prove. It is opt-in, per
%% predicate, and the default is open, because the text that gives you
%% every fact about a predicate is rarer than the one that gives you some.
%%
%% THE GOAL MUST BE GROUND. truth(own(bob, X), T) is not a question with a
%% truth value, it is a search -- and `true' for "some X proves" beside
%% `false' for "some other X is denied" would be two quantifiers wearing
%% one word. A variable raises instantiation_error; findall/3 is the tool
%% for the question that was meant. And the class-atom decision above
%% reaches here: neg(own(bob, car)) makes truth(own(bob, car), T) false and
%% leaves truth(own(bob, car_1), T) unknown, because the projection kept
%% the class and lost the individual. That is the cost, stated.
%%
%% ---- WHAT IT IS NOT ---------------------------------------------------
%%
%% It is not a parser of English. It reads a controlled subset -- the
%% shapes above and nothing else -- and a program that wants more writes
%% grammar clauses of its own beside these, the way a library(httpd) page
%% is written beside the server. It does not resolve pronouns, so `Alice
%% bought a car. She uses it.' is two sentences of which the second fails.
%% It does not read a prepositional phrase, and it REFUSES one rather than
%% misreading it: `Alice owns a house in Rome' once came back as
%% rome(rome_1), house(rome_1), in(rome_1), own(alice, rome_1) -- the
%% position rule taking the last word for the noun -- and that is worse
%% than a refusal. Prepositions are closed now, so `in Rome' is left over
%% and the sentence fails, and reason_refused/2 names it.
%% It does not read a conjunction, and refuses one BY RULE: `Alice and
%% Bob' parsed as and(alice, bob) while `and' was an open word, and a
%% sentence refused only because its tail did not fit is one misreading
%% away from being accepted. `and', `or' and `but' are closed.
%% It does not read compound nouns: `an identification number' is a
%% `number' that is `identification', by the position rule, and a program
%% that means one word writes identification_number. And it decides nothing
%% about truth: what comes out is what the text SAID, shaped for a
%% knowledge base, and whether it is so is the rest of the program's job.

:- dynamic reason_noun/1.
:- dynamic reason_adj/1.
:- dynamic reason_verb/2.
:- dynamic reason_proper/2.
:- dynamic reason_closed/1.

%% ---- text ------------------------------------------------------------

reason_text(Text, Terms) :- reason_text(Text, [], Terms).

reason_text(Text, Options, Terms) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, Sentences),
    nb_setval('$rs_subject', none),
    rs_read(Sentences, Options, Terms).

rs_read(Sentences, Options, Terms) :-
    rs_each(Sentences, Raw),
    rs_declare(Raw),
    (   memberchk(variables(true), Options)
    ->  Terms = Raw
    ;   reason_name(Raw, Terms)
    ).

%% ---- questions: a goal, and the reason with the answer ----------------
%% The state is NOT reset here: a question may follow the paragraph the
%% last reason_text/2 read, and `Is she licensed?' asks about its subject.

reason_question(Text, Question) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, [S|_]),
    phrase(rs_question(Question), S).

reason_ask(Text, Answers) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, Sentences),
    rs_read(Sentences, [variables(true)], Terms),
    findall(A, ( member(Q, Terms), rq_answer(Q, A) ), Answers).

%% ---- prose, through the shipped tagger: optional ----------------------

reason_prose(Text, Terms) :- rp_model(M), tagger_normalise(M, Text, _, Terms).
reason_ask_prose(Text, Answers) :- rp_model(M), tagger_ask(M, Text, Answers).

rp_model(M) :-
    (   catch(nb_getval('$rp_model', Cached), _, Cached = none), Cached \== none
    ->  M = Cached
    ;   catch(use_module(library(reasoning/tagger)), _,
              throw(error(existence_error(tagger, pretrained),
                          context(reason_prose/2, 'library(reasoning/tagger) would not load: is library(torch) built?')))),
        tagger_pretrained(M0),
        nb_setval('$rp_model', M0),
        M = M0
    ).

rq_answer(question(Goal), A) :- !, rq_yes_no(Goal, A).
rq_answer(question(X, Goal), As) :- !,
    findall(X-Why, ( rq_solve(Goal), rq_why(Goal, Why) ), As0),
    list_to_set(As0, As).

%% yes or no: truth/2's verdict over a goal that may carry an existential
%% (`a flat' is some flat), with the denial in the class form a negative
%% sentence gives -- neg(rent_in(priya, flat, bristol)) -- and the reason
rq_yes_no(Goal, A) :-
    rq_denial(Goal, Denial),
    ( rq_solve(Goal) -> Pos = yes ; Pos = no ),
    ( rq_solve(Denial) -> Neg = yes ; Neg = no ),
    (   Pos == yes, Neg == yes -> A = conflict
    ;   Pos == yes -> rq_why(Goal, Why), A = yes(Why)
    ;   Neg == yes -> A = no(denied(Denial))
    ;   rq_split(Goal, _, P), functor(P, F, Ar), reason_closed(F/Ar) -> A = no(closed)
    ;   A = unknown
    ).

rq_solve(Goal) :- catch(Goal, error(existence_error(procedure, _), _), fail).

rq_split((A, B), [A|As], P) :- !, rq_split(B, As, P).
rq_split(P, [], P).

rq_denial(Goal, neg(ClassP)) :-
    rq_split(Goal, [First|_], P), First =.. [N, V], var(V), !,
    copy_term(V-P, N-ClassP).
rq_denial(Goal, neg(Goal)).

rq_why(Goal, Why) :- rq_claim(Goal, P), ( reason_why(P, Why0) -> Why = Why0 ; Why = proved ).

%% the claim a goal makes: its last conjunct, or the one before a trailing
%% reason_amount/2 or reason_count/3, which a how-much or how-many
%% question puts after the claim
rq_claim(Goal, P) :-
    rq_split(Goal, Pre, Last),
    (   ( Last = reason_amount(_, _) ; Last = reason_count(_, _, _) ), append(_, [P0], Pre)
    ->  P = P0
    ;   P = Last
    ).

%% reason_why(+Goal, -Why): fact when the goal was said; rule(Head :- Body)
%% with the body as it proved when a rule gave it, one level; denied when
%% its negation was said. Fails when nothing holds it up.
reason_why(P, fact) :- catch(clause(P, true), _, fail), !.
reason_why(P, rule((P :- Body))) :-
    catch(clause(P, Body), _, fail), Body \== true, rq_solve(Body), !.
reason_why(P, denied) :- catch(clause(neg(P), true), _, fail), !.

%% reason_amount(+Object, -Quantity): what `how much' asks for. The object
%% IS a quantity -- quantity/2, quantity/3 or a bare number -- or it is a
%% class atom the text gave an amount: `Nadia pays the rent. The rent is
%% 500 euros.' answers quantity(500, euros) for the object `rent'. A
%% knowledge base with no amount/2 in it answers nothing, not an error.
reason_amount(Q, Q) :- nonvar(Q), ( number(Q) ; Q = quantity(_, _) ; Q = quantity(_, _, _) ), !.
reason_amount(O, Q) :- atom(O), catch(amount(O, Q), error(existence_error(procedure, _), _), fail).

%% reason_count(+Object, +Noun, -N): what `how many NOUN' asks for -- the
%% number in a quantity of that noun, with or without an `of' part
reason_count(quantity(N, U), U, N).
reason_count(quantity(N, U, _), U, N).

%% the sentences in order, and the STATE between them: the subject of the
%% last fact, which a subject pronoun in the next sentence stands for
rs_each([], []).
rs_each([S|Ss], Terms) :-
    once(phrase(rs_sentence(T, State), S)),
    rs_remember(State),
    append(T, Rest, Terms),
    rs_each(Ss, Rest).

rs_remember(subject(S)) :- !, nb_setval('$rs_subject', S).
rs_remember(_).

reason_sentence(Text, Terms) :- reason_sentence(Text, [], Terms).

reason_sentence(Text, Options, Terms) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, [S|_]),
    nb_setval('$rs_subject', none),
    phrase(rs_sentence(Raw, _), S),
    rs_declare(Raw),
    (   memberchk(variables(true), Options)
    ->  Terms = Raw
    ;   reason_name(Raw, Terms)
    ).

%% A RULE DECLARES WHAT ITS BODY NAMES. `\+ exempt(X)' THROWS an
%% existence_error when no exempt/1 was ever asserted -- and so does a
%% plain tenant(X) -- so a rule handed back from `every tenant that is not
%% exempt ...' would throw for every caller in a knowledge base that
%% mentions no exemption, which is the ordinary case. dynamic/1 as a goal
%% is the cure (measured: after it, \+ over the empty predicate fails, as
%% it should), and it is done HERE, at the boundary, once per call, over
%% the finished terms -- never inside the grammar, so reason_refused/2's
%% checks declare nothing. A predicate that already exists is unchanged;
%% one that cannot be declared (a builtin's name) is left as it was.
rs_declare([]).
rs_declare([T|Ts]) :-
    ( nonvar(T), T = (_ :- Body) -> rs_declare_body(Body) ; true ),
    rs_declare(Ts).

rs_declare_body((A, B)) :- !, rs_declare_body(A), rs_declare_body(B).
rs_declare_body(\+ G)   :- !, rs_declare_body(G).
rs_declare_body(G) :-
    callable(G), functor(G, N, A),
    catch(dynamic(N/A), _, true).

%% Split the token stream at `.', dropping empty sentences. THE CUT IS
%% LOAD-BEARING: without it rs_sentences([], _) has two applicable clauses
%% and the second recurses on [] again, so anything that backtracks into
%% this -- a findall over reason_sentence/2, or every refused sentence --
%% never returns. Found by the suite case hanging at its first refusal.
rs_sentences([], []) :- !.
rs_sentences(Tokens, Sentences) :-
    rs_upto(Tokens, S, Rest),
    (   S == [] -> Sentences = More ; Sentences = [S|More] ),
    rs_sentences(Rest, More).

rs_upto([], [], []).
rs_upto(['.'|Rest], [], Rest) :- !.
rs_upto([T|Ts], [T|S], Rest) :- rs_upto(Ts, S, Rest).

%% ---- what was refused -------------------------------------------------

reason_refused(Text, Sentence) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, Sentences),
    nb_setval('$rs_subject', none),
    rr_refused(Sentences, S),
    rs_words(S, Sentence).

%% the sentences in order with the state carried exactly as reason_text/2
%% carries it, so a pronoun after its antecedent is not reported refused;
%% each refused sentence in turn on backtracking
rr_refused([S|Ss], R) :-
    (   phrase(rs_sentence(_, State), S)
    ->  rs_remember(State), rr_refused(Ss, R)
    ;   ( R = S ; rr_refused(Ss, R) )
    ).

rs_words(Tokens, Atom) :-
    findall(W, ( member(T, Tokens), rs_token_text(T, W) ), Ws),
    atomic_list_concat(Ws, ' ', Atom).

rs_token_text(word(W, _), W).
rs_token_text(num(N), A) :- format(atom(A), "~w", [N]).

%% ---- truth -------------------------------------------------------------
%%
%% Two questions, and the pair read as one of four answers. A predicate
%% that does not exist is caught here and counts as not proving: silence
%% is `unknown', never an error. Any other ball is the program's and
%% travels.

truth(Goal, Truth) :-
    (   ground(Goal) -> true
    ;   throw(error(instantiation_error, truth/2))
    ),
    ( rt_proves(Goal)      -> Pos = yes ; Pos = no ),
    ( rt_proves(neg(Goal)) -> Neg = yes ; Neg = no ),
    rt_verdict(Pos, Neg, Goal, Truth).

rt_verdict(yes, yes, _, conflict) :- !.
rt_verdict(yes, no,  _, true)     :- !.
rt_verdict(no,  yes, _, false)    :- !.
rt_verdict(no,  no,  Goal, Truth) :-
    functor(Goal, N, A),
    ( reason_closed(N/A) -> Truth = false ; Truth = unknown ).

rt_proves(Goal) :-
    catch(Goal, error(existence_error(procedure, _), _), fail), !.

%% ---- tokens ----------------------------------------------------------

reason_tokens(Text, Tokens) :-
    rt_codes(Text, Codes),
    rt_tokens(Codes, Tokens).

rt_codes(T, Cs) :- is_list(T), !, Cs = T.
rt_codes(T, Cs) :- atom(T), !, atom_codes(T, Cs).
rt_codes(T, Cs) :- string(T), !, string_codes(T, Cs).
rt_codes(T, _)  :- throw(error(type_error(text, T), reason_tokens/2)).

rt_tokens([], []).
rt_tokens([C|Cs], ['.'|Ts]) :- rt_stop(C), !, rt_tokens(Cs, Ts).
rt_tokens([44|Cs], [','|Ts]) :- !, rt_tokens(Cs, Ts).          % 44 is `,'
%% a number: digits, a comma between digits passed over (1,000), a point
%% between digits kept (5.5), and `%' right after it the word `percent'
rt_tokens([C|Cs], [num(N)|Ts]) :-
    rt_digit(C), !,
    rt_digits(Cs, More, Rest0),
    (   Rest0 = [46, D|Rest1], rt_digit(D)                      % 46 is `.'
    ->  rt_digits([D|Rest1], Frac, Rest2), append([C|More], [46|Frac], NCs)
    ;   NCs = [C|More], Rest2 = Rest0
    ),
    atom_codes(NA, NCs), atom_number(NA, N),
    (   Rest2 = [37|Rest] -> Ts = [word(percent, lower)|Ts1]    % 37 is `%'
    ;   Rest = Rest2, Ts = Ts1
    ),
    rt_tokens(Rest, Ts1).
rt_tokens([C|Cs], [word(W, Case)|Ts]) :-
    rt_alpha(C), !,
    rt_run(Cs, More, Rest),
    ( rt_upper(C) -> Case = upper ; Case = lower ),
    rt_lower(C, L), rt_lowers(More, Ls),
    atom_codes(W, [L|Ls]),
    rt_tokens(Rest, Ts).
rt_tokens([_|Cs], Ts) :- rt_tokens(Cs, Ts).

rt_stop(46). rt_stop(33). rt_stop(63).                          % . ! ?

rt_run([C|Cs], [C|More], Rest) :- ( rt_alpha(C) ; rt_digit(C) ; C == 95 ), !, rt_run(Cs, More, Rest).
rt_run(Cs, [], Cs).

rt_digits([C|Cs], [C|More], Rest) :- rt_digit(C), !, rt_digits(Cs, More, Rest).
rt_digits([44, C|Cs], More, Rest) :- rt_digit(C), !, rt_digits([C|Cs], More, Rest).   % 1,000: the comma is a separator
rt_digits(Cs, [], Cs).

rt_alpha(C) :- C >= 97, C =< 122, !.
rt_alpha(C) :- C >= 65, C =< 90.
rt_upper(C) :- C >= 65, C =< 90.
rt_digit(C) :- C >= 48, C =< 57.
rt_lower(C, L) :- ( rt_upper(C) -> L is C + 32 ; L = C ).
rt_lowers([], []).
rt_lowers([C|Cs], [L|Ls]) :- rt_lower(C, L), rt_lowers(Cs, Ls).

%% ---- the grammar -----------------------------------------------------
%%
%% Every nonterminal carries the TERMS its phrase contributes. A subject
%% is either a constant (a proper noun) or a variable with a guard -- the
%% class goals a rule's body will need -- and `Ctx' says which: `fact'
%% for a proper subject, `rule' under a quantifier. An object read under
%% `rule' or under negation is a class atom; under `fact' an indefinite
%% object is a fresh variable with its noun and adjectives as terms.

rs_sentence(Terms) --> rs_sentence(Terms, _).
rs_sentence([Q], none) --> rs_question(Q), !.
rs_sentence([Claim], none) --> rs_amount(Claim), !.
rs_sentence(Terms, State) -->
    rs_subject(S, Guard, Ctx),
    rs_predication(S, Ctx, Claim, Extra),
    { rs_assemble(Ctx, Guard, Claim, Extra, Terms),
      ( Ctx == fact -> State = subject(S) ; State = none ) }.

%% ---- questions ---------------------------------------------------------
%% `?' is a stop like `.', so a question is known by its first word. It
%% reads to the GOAL the statement would have asserted, with a variable
%% where `who', `what' or `where' stood:
%%
%%   Does Priya sell the bread?        question(sell(priya, bread))
%%   Does Priya rent a flat in Rome?   question((flat(V), rent_in(priya, V, rome)))
%%   Is Priya licensed?  Is Priya a baker?   question(licensed(priya)), question(baker(priya))
%%   May Priya sell the bread?         question(may_sell(priya, bread))
%%   Who rents a flat in Rome?         question(X, (flat(V), rent_in(X, V, rome)))
%%   Who is licensed?  Who is a baker?  question(X, licensed(X)), question(X, baker(X))
%%   What does Priya sell?             question(X, sell(priya, X))
%%   What does Priya keep in Leeds?    question(X, keep_in(priya, X, leeds))   -- or `keep_in Leeds', joined
%%   Where does Priya sleep?           question(X, sleep_in(priya, X))     -- `in' assumed
%%   Does Priya pay 500 euros?         question(pay(priya, quantity(500, euros)))
%%   Is the rent 500 euros?            question(amount(rent, quantity(500, euros)))
%%   How much does Priya pay?          question(Q, (pay(priya, O), reason_amount(O, Q)))
%%   How much must Priya pay?          question(Q, (must_pay(priya, O), reason_amount(O, Q)))
%%   How much does Priya pay to Omar?  question(Q, (pay_to(priya, O, omar), reason_amount(O, Q)))   -- or `pay_to Omar'
%%   How many vineyards does Priya own?  question(N, (own(priya, O), reason_count(O, vineyards, N)))
%%   How much is the rent?             question(Q, amount(rent, Q))
%%
%% The subject may be a pronoun, resolved as a statement's is. `How much'
%% asks for the object THROUGH reason_amount/2, so that `Priya pays the
%% rent' beside `The rent is 500 euros' answers the 500 euros and not the
%% word `rent'; `how many' asks, through reason_count/3, for the number
%% in a quantity of the noun it names -- quantity(2, litres) and
%% quantity(2, litres, milk) both answer 2 litres.

rs_question(question(Goal)) -->
    rs_aux, rs_qsubject(S), rs_verb(V), rs_object_opt(fact, O, Extra), rs_place_opt(O, Pl),
    { rs_claim(V, S, O, Pl, P), rs_goal(Extra, P, Goal) }.
rs_question(question(Goal)) -->
    rs_copula, rs_qsubject(S), rs_property(S, Goal).
rs_question(question(Goal)) -->
    [word(M, _)], { rl_modal(M) }, rs_qsubject(S), rs_verb_word(W), { atomic_list_concat([M, '_', W], V) },
    rs_object_opt(fact, O, Extra), rs_place_opt(O, Pl),
    { rs_claim(V, S, O, Pl, P), rs_goal(Extra, P, Goal) }.
rs_question(question(X, Goal)) -->
    [word(who, _)], rs_copula, !, rs_property(X, Goal).
rs_question(question(X, Goal)) -->
    [word(who, _)], rs_modal_verb(V), rs_object_opt(fact, O, Extra), rs_place_opt(O, Pl),
    { rs_claim(V, X, O, Pl, P), rs_goal(Extra, P, Goal) }.
rs_question(question(X, Goal)) -->
    [word(Wh, _)], { Wh == what ; Wh == whom }, rs_aux, rs_qsubject(S), rs_verb_place(V, X, Pl),
    { rs_claim(V, S, X, Pl, Goal) }.

%% the verb and a place after it: `keep in Leeds' as it is written, or
%% `keep_in Leeds' as the assembler writes it, taken apart again
rs_verb_place(V, O, Pl) --> rs_verb_word_place(W, O, Pl), { rs_base(W, V) }.
rs_verb_word_place(W, O, Pl) -->
    rs_verb_word(W0),
    (   rs_proper(Place), { rs_unjoin(W0, W, Prep) } -> { Pl = Prep-Place }
    ;   { W = W0 }, rs_place_opt(O, Pl)
    ).

%% keep_in -> keep, in: a relation the assembler joined, taken apart when
%% the object it asks for stood in front
rs_unjoin(V0, V, Prep) :-
    atomic_list_concat(Parts, '_', V0), append(Front, [Prep], Parts), Front \== [], rl_preposition(Prep), !,
    atomic_list_concat(Front, '_', V).
rs_question(question(X, Goal)) -->
    [word(where, _)], rs_aux, rs_qsubject(S), rs_verb(V), rs_object_opt(fact, O, Extra),
    { rs_claim(V, S, O, in-X, P), rs_goal(Extra, P, Goal) }.
rs_question(question(Q, (P, reason_amount(O, Q)))) -->
    [word(how, _)], [word(much, _)], rs_aux, rs_qsubject(S), rs_verb_place(V, O, Pl),
    { rs_claim(V, S, O, Pl, P) }.
rs_question(question(Q, (P, reason_amount(O, Q)))) -->
    [word(how, _)], [word(much, _)], [word(M, _)], { rl_modal(M) }, rs_qsubject(S), rs_verb_word_place(W, O, Pl),
    { atomic_list_concat([M, '_', W], V), rs_claim(V, S, O, Pl, P) }.
rs_question(question(Q, amount(N, Q))) -->
    [word(how, _)], [word(much, _)], rs_copula, rs_det(def), rs_noun(N).
rs_question(question(N, (P, reason_count(O, U, N)))) -->
    [word(how, _)], [word(many, _)], rs_noun(U), rs_aux, rs_qsubject(S), rs_verb_place(V, O, Pl),
    { rs_claim(V, S, O, Pl, P) }.
rs_question(question(amount(N, Q))) -->
    rs_copula, rs_det(def), rs_noun(N), rs_quantity(Q).

%% `The rent is [not] 500 euros': the one sentence with a definite subject,
%% and the amount a definite object has -- what `how much' reads back
rs_amount(Claim) -->
    rs_det(def), rs_noun(N), rs_copula,
    (   [word(not, _)] -> { Claim = neg(amount(N, Q)) } ; { Claim = amount(N, Q) } ),
    rs_quantity(Q).

rs_qsubject(S) --> rs_subject(S, _, fact).

rs_goal([], P, P).
rs_goal([E|Es], P, (E, G)) :- rs_goal(Es, P, G).

%% a proper noun, `every NOUN [that is [not] ADJ]', or a subject pronoun
rs_subject(S, [], fact) --> rs_proper(S).
rs_subject(X, Guard, rule) -->
    [word(Q, _)], { rl_quant(Q) },
    rs_noun(N), { G1 =.. [N, X] },
    rs_relative(X, Rel),
    { Guard = [G1|Rel] }.
%% `she', `he' or `they': the subject of the last FACT read, carried from
%% sentence to sentence by reason_text/2 and reason_refused/2 -- the one
%% coreference this reader does. With no fact before it the sentence is
%% refused, and reason_sentence/2 reads one sentence with no state at all.
rs_subject(S, [], fact) -->
    [word(P, _)], { rl_subject_pronoun(P), catch(nb_getval('$rs_subject', S0), _, S0 = none), S0 \== none, S = S0 }.

rs_relative(X, Rel) -->
    [word(that, _)], rs_copula,
    (   [word(not, _)] -> { Neg = yes } ; { Neg = no } ),
    rs_adj(A), { G =.. [A, X], ( Neg == yes -> Rel = [\+ G] ; Rel = [G] ) }.
rs_relative(_, []) --> [].

%% what is said of the subject: Claim is the head term, Extra the object's
%% existence terms (only ever non-empty for an indefinite object in a fact)
rs_predication(S, _, Claim, []) -->
    rs_copula, [word(not, _)], !, rs_property(S, P), { Claim = neg(P) }.
rs_predication(S, _, Claim, []) -->
    rs_copula, rs_property(S, Claim).
rs_predication(S, _, Claim, []) -->
    rs_aux, [word(not, _)], rs_verb(V),
    rs_object_opt(class, O),
    rs_place_opt(O, Pl),
    { rs_claim(V, S, O, Pl, P), Claim = neg(P) }.
rs_predication(S, Ctx, Claim, Extra) -->
    rs_modal_verb(V),
    rs_object_opt(Ctx, O, Extra),
    rs_place_opt(O, Pl),
    { rs_claim(V, S, O, Pl, Claim) }.

%% `is ADJ' or `is a NOUN' -- both a unary property of the subject
rs_property(S, P) --> rs_det(_), !, rs_noun(N), { P =.. [N, S] }.
rs_property(S, P) --> rs_adj(A), { P =.. [A, S] }.

%% a modal in front of the verb joins it: may_access
rs_modal_verb(V) --> [word(M, _)], { rl_modal(M) }, !, rs_verb_word(W), { atomic_list_concat([M, '_', W], V) }.
rs_modal_verb(V) --> rs_verb(V).

%% an object, or none for an intransitive verb
rs_object_opt(Ctx, O, Extra) --> rs_object(Ctx, O, Extra).
rs_object_opt(_, none, []) --> [].
rs_object_opt(Ctx, O) --> rs_object_opt(Ctx, O, _).

%% `in Rome' AFTER AN OBJECT: the preposition joins the relation, as it does
%% when it is written joined to a bare verb (`lives_in Rome'), and the place
%% is a third argument -- rent_in(alice, V, rome). Only after an object:
%% after a bare verb the two words are ONE relation and are written as one,
%% so `Alice sleeps in Rome' is still refused where `Alice sleeps_in Rome'
%% is read, and library(reasoning/normalise)'s assembler is what joins them.
rs_place_opt(O, Prep-Place) --> { O \== none }, [word(Prep, _)], { rl_preposition(Prep) }, rs_proper(Place), !.
rs_place_opt(_, none) --> [].

%% a quantity, a proper noun; `the N' as the class atom; `a N' as an
%% individual in a fact and the class atom otherwise
rs_object(_, Q, []) --> rs_quantity(Q).
rs_object(_, O, []) --> rs_proper(O).
rs_object(_, N, []) --> rs_det(def), rs_adjs(_), rs_noun(N).
rs_object(fact, V, [Noun|Adjs]) -->
    rs_det(indef), rs_adjs(As), rs_noun(N),
    { Noun =.. [N, V], rs_adj_terms(As, V, Adjs) }.
rs_object(Ctx, N, []) --> { Ctx \== fact }, rs_det(indef), rs_adjs(_), rs_noun(N).

%% a quantity: a number and the noun it counts, as written -- `500 euros'
%% quantity(500, euros), `three vineyards' quantity(3, vineyards), `5.5
%% percent' quantity(5.5, percent); `two litres of milk' quantity(2,
%% litres, milk), and `a litre of milk' the same with 1; a bare number the
%% number itself. A VALUE, never an individual: nothing is introduced, and
%% no adjective is read inside one (`three red cars' is refused).
rs_quantity(quantity(N, U, Of)) --> rs_number_or_one(N), rs_noun(U), [word(of, _)], !, rs_noun(Of).
rs_quantity(quantity(N, U)) --> rs_number(N), rs_noun(U), !.
rs_quantity(N) --> rs_number(N).

rs_number_or_one(N) --> rs_number(N).
rs_number_or_one(1) --> rs_det(indef).

%% digits as the tokeniser read them, or the number words: `five', `twenty
%% five', `two hundred', `two hundred fifty', `a hundred', `three thousand'
rs_number(N) --> [num(N)].
rs_number(N) --> [word(a, _)], [word(S, _)], { rl_scale(S, N) }.
rs_number(N) --> [word(W, _)], { rl_number(W, N0) }, rs_number_rest(N0, N).

rs_number_rest(N0, N) --> [word(S, _)], { rl_scale(S, M) }, !, { N1 is N0 * M }, rs_number_rest(N1, N).
rs_number_rest(N0, N) --> { N0 >= 20, N0 mod 10 =:= 0 }, [word(U, _)], { rl_number(U, D), D > 0, D < 10 }, !, { N is N0 + D }.
rs_number_rest(N0, N) --> { N0 >= 100 }, [word(W, _)], { rl_number(W, D0), D0 < 100 }, rs_number_rest(D0, D), { D < 100 }, !, { N is N0 + D }.
rs_number_rest(N, N) --> [].

%% O == none, never a unification: an indefinite object is still a fresh
%% VARIABLE here, and a variable unifies with `none' happily
rs_claim(V, S, O, P) :- O == none, !, P =.. [V, S].
rs_claim(V, S, O, P) :- P =.. [V, S, O].

rs_claim(V, S, O, none, P) :- !, rs_claim(V, S, O, P).
rs_claim(V, S, O, Prep-Place, P) :- O == none, !, atomic_list_concat([V, '_', Prep], VP), P =.. [VP, S, Place].
rs_claim(V, S, O, Prep-Place, P) :- atomic_list_concat([V, '_', Prep], VP), P =.. [VP, S, O, Place].

rs_adj_terms([], _, []).
rs_adj_terms([A|As], V, [T|Ts]) :- T =.. [A, V], rs_adj_terms(As, V, Ts).

rs_assemble(fact, _, Claim, Extra, Terms) :- append(Extra, [Claim], Terms).
rs_assemble(rule, Guard, Claim, _, [(Claim :- Body)]) :- rs_conj(Guard, Body).

rs_conj([G], G) :- !.
rs_conj([G|Gs], (G, B)) :- rs_conj(Gs, B).

%% ---- words -----------------------------------------------------------

%% a capitalised word that is not one of the grammar's own, or a lexicon
%% entry whatever its case
rs_proper(C) --> [word(W, _)], { reason_proper(W, C) }, !.
rs_proper(W) --> [word(W, upper)], { \+ rl_closed(W) }.

rs_det(Kind) --> [word(D, _)], { rl_det(D, Kind) }.
rs_copula   --> [word(C, _)], { rl_copula(C) }.
rs_aux      --> [word(A, _)], { rl_aux(A) }.

%% the lexicon first, position second
rs_noun(N) --> [word(W, _)], { reason_noun(W) }, !, { N = W }.
rs_noun(N) --> [word(W, _)], { \+ rl_closed(W), N = W }.

rs_adj(A)  --> [word(W, _)], { reason_adj(W) }, !, { A = W }.
rs_adj(A)  --> [word(W, _)], { \+ rl_closed(W), A = W }.

%% zero or more adjectives before a noun -- the noun is the LAST word, so
%% this takes what precedes it
rs_adjs([A|As]) --> rs_adj(A), rs_adjs(As).
rs_adjs([]) --> [].

rs_verb(V) --> rs_verb_word(W), { rs_base(W, V) }.
rs_verb_word(W) --> [word(W, _)], { \+ rl_closed(W) }.

rs_base(W, B) :- reason_verb(W, B), !.
rs_base(W, B) :-                                   % a joined relation, lives_in: the verb stems, the rest stays
    atomic_list_concat([Head|Tails], '_', W), Tails \== [], !,
    (   rl_modal(Head) -> B = W                    % may_use: a modal and a base form, as written
    ;   rs_base(Head, HB), atomic_list_concat([HB|Tails], '_', B)
    ).
rs_base(W, B) :- rl_irregular(W, B), !.
rs_base(W, B) :-                                   % carries, tries -- but dies, lies: die, lie
    atom_codes(W, Cs), append(Pre, [0'i, 0'e, 0's], Cs),
    length(Pre, N), N >= 2, !,
    append(Pre, [0'y], BCs), atom_codes(B, BCs).
rs_base(W, B) :-                                   % watches, passes, fixes, goes
    atom_codes(W, Cs), append(Pre, [0'e, 0's], Cs),
    rl_es_stem(Pre), !,
    atom_codes(B, Pre).
rs_base(W, B) :-                                   % owns, likes, uses
    atom_codes(W, Cs), append(Pre, [0's], Cs),
    length(Pre, N), N >= 3, \+ append(_, [0's], Pre), !,
    atom_codes(B, Pre).
rs_base(W, W).

%% a stem that takes -es rather than -s: it ends in ss, sh, ch, x, z or o.
%% A SINGLE s OR h IS NOT ENOUGH: `uses' is use+s, not us+es, and the first
%% draft answered `us' -- and `clos', `rais', `bath'. Found by writing
%% library(reasoning/normalise)'s inflector, which this must invert exactly:
%% normalise_third/2 there and the four rules above are one pair, changed
%% together. The -ies rule wants two letters before it, so `dies' and `lies'
%% are die+s and lie+s rather than dy and ly, and `carries' is carry. What
%% no rule can settle -- `buses' from bus, `belies' from belie, `aches' from
%% ache -- reason_verb/2 is there for, and library(reasoning/normalise)
%% DROPS from its lexicon as it loads: a verb whose third person does not
%% come back to it here is never generated, so the round trip holds by
%% construction.
rl_es_stem(Pre) :- append(_, [0's, 0's], Pre), !.
rl_es_stem(Pre) :- append(_, [0's, 0'h], Pre), !.
rl_es_stem(Pre) :- append(_, [0'c, 0'h], Pre), !.
rl_es_stem(Pre) :- append(_, [0'x], Pre), !.
rl_es_stem(Pre) :- append(_, [0'z], Pre), !.
rl_es_stem(Pre) :- append(_, [0'o], Pre).

%% ---- the closed classes ----------------------------------------------

rl_det(a, indef).   rl_det(an, indef).   rl_det(the, def).
rl_quant(every).    rl_quant(all).       rl_quant(each).
rl_copula(is).      rl_copula(are).      rl_copula(was).     rl_copula(were).
rl_aux(does).       rl_aux(do).          rl_aux(did).
rl_modal(may).      rl_modal(must).      rl_modal(can).
rl_modal(should).   rl_modal(shall).     rl_modal(will).
rl_irregular(has, have). rl_irregular(is, be). rl_irregular(does, do).
rl_irregular(was, be).   rl_irregular(were, be). rl_irregular(goes, go).

rl_closed(W) :- rl_det(W, _), !.
rl_closed(W) :- rl_quant(W), !.
rl_closed(W) :- rl_copula(W), !.
rl_closed(W) :- rl_aux(W), !.
rl_closed(W) :- rl_modal(W), !.
rl_closed(not).
rl_closed(that).
rl_closed(if).
rl_closed(then).
%% number words and scales: closed, so `five' is never an adjective and
%% `Six' never a name; `much' and `many' with them, the words of a how-much
%% question
rl_closed(W) :- rl_number(W, _), !.
rl_closed(W) :- rl_scale(W, _), !.
rl_closed(much).
rl_closed(many).
%% pronouns: closed, so a capitalised `It' at the head of a sentence is
%% not a proper noun named `it' -- `It rains' answered rain(it) until the
%% suite asked for it to be refused. Nothing here resolves one; a sentence
%% built on one is refused whole, as the header says.
rl_closed(W) :- rl_pronoun(W).
rl_closed(W) :- rl_question(W).
rl_closed(W) :- rl_preposition(W).
rl_closed(W) :- rl_conjunction(W).
rl_pronoun(it).   rl_pronoun(he).   rl_pronoun(she).  rl_pronoun(they).
rl_subject_pronoun(she). rl_subject_pronoun(he). rl_subject_pronoun(they).   % the ones that stand for a subject; not `it'
%% question words: closed, so that `Who' at the head of a sentence is never
%% read as somebody's name
rl_question(who).   rl_question(whom).  rl_question(what).  rl_question(which).
rl_question(where). rl_question(when).  rl_question(why).   rl_question(how).
rl_pronoun(we).   rl_pronoun(i).    rl_pronoun(you).  rl_pronoun(him).
rl_pronoun(her).  rl_pronoun(them). rl_pronoun(us).   rl_pronoun(me).
rl_pronoun(his).  rl_pronoun(its).  rl_pronoun(their). rl_pronoun(our).
%% prepositions: closed, so a phrase after the object is LEFT OVER and the
%% sentence fails. Without this the position rule -- the noun is the last
%% word -- read `Alice owns a house in Rome' as a `rome' that is `house'
%% and `in', and accepted it. A wrong reading accepted is worse than a
%% refusal, and this library refuses.
rl_preposition(in).      rl_preposition(on).      rl_preposition(at).
rl_preposition(to).      rl_preposition(from).    rl_preposition(with).
rl_preposition(by).      rl_preposition(for).     rl_preposition(of).
rl_preposition(after).   rl_preposition(before).  rl_preposition(under).
rl_preposition(over).    rl_preposition(into).    rl_preposition(onto).
rl_preposition(about).   rl_preposition(between). rl_preposition(through).
rl_preposition(during).  rl_preposition(without). rl_preposition(within).
rl_preposition(across).  rl_preposition(against). rl_preposition(among).
rl_preposition(around).  rl_preposition(behind).  rl_preposition(below).
rl_preposition(beneath). rl_preposition(beside).  rl_preposition(beyond).
rl_preposition(near).    rl_preposition(off).     rl_preposition(out).
rl_preposition(since).   rl_preposition(until).   rl_preposition(upon).
rl_preposition(toward).  rl_preposition(towards). rl_preposition(via).
rl_preposition(as).      rl_preposition(than).
%% conjunctions: closed, because `Alice and Bob' PARSED as and(alice, bob)
%% -- the conjunction fell through as the verb -- and `Alice and Bob signed
%% the contract' was refused only because what followed did not fit. A
%% refusal by luck is a misreading waiting for the sentence that fits.
rl_conjunction(and). rl_conjunction(or). rl_conjunction(but).
%% the number words, and the scales a number word multiplies by
rl_number(zero, 0).      rl_number(one, 1).       rl_number(two, 2).       rl_number(three, 3).
rl_number(four, 4).      rl_number(five, 5).      rl_number(six, 6).       rl_number(seven, 7).
rl_number(eight, 8).     rl_number(nine, 9).      rl_number(ten, 10).      rl_number(eleven, 11).
rl_number(twelve, 12).   rl_number(thirteen, 13). rl_number(fourteen, 14). rl_number(fifteen, 15).
rl_number(sixteen, 16).  rl_number(seventeen, 17). rl_number(eighteen, 18). rl_number(nineteen, 19).
rl_number(twenty, 20).   rl_number(thirty, 30).   rl_number(forty, 40).    rl_number(fifty, 50).
rl_number(sixty, 60).    rl_number(seventy, 70).  rl_number(eighty, 80).   rl_number(ninety, 90).
rl_scale(hundred, 100).  rl_scale(thousand, 1000). rl_scale(million, 1000000). rl_scale(billion, 1000000000).

%% ---- naming the individuals ------------------------------------------
%%
%% A fresh individual is a variable while the grammar runs, so a sentence
%% with several stays one term with shared variables. Naming is a pass
%% over the finished list: each variable takes the noun of the first
%% unary term that mentions it -- the grammar always emits the noun term
%% first -- and a counter per noun, so two cars are car_1 and car_2.

%% ONLY THE FACTS. A variable in a rule is universal -- the X of `every
%% employee' -- and must stay one; a variable in a fact is an individual
%% the text introduced and gets its name. The grammar never shares a
%% variable between the two.
reason_name(Terms, Terms) :-
    rn_facts(Terms, Facts),
    term_variables(Facts, Vs),
    rn_each(Vs, Facts, []).

%% rules and questions keep their variables: a question's variable is
%% what it asks
rn_facts([], []).
rn_facts([T|Ts], Fs) :-
    ( nonvar(T), ( T = (_ :- _) ; T = question(_) ; T = question(_, _) ) -> Fs = Fs1 ; Fs = [T|Fs1] ),
    rn_facts(Ts, Fs1).

rn_each([], _, _).
rn_each([V|Vs], Terms, Counts0) :-
    ( rn_noun_of(V, Terms, N) -> true ; N = thing ),
    ( memberchk(N-C0, Counts0) -> C is C0 + 1, rn_bump(Counts0, N, C, Counts)
    ; C = 1, Counts = [N-1|Counts0] ),
    atomic_list_concat([N, '_', C], Name),
    V = Name,
    rn_each(Vs, Terms, Counts).

rn_bump([], _, _, []).
rn_bump([N-_|Cs], N, C, [N-C|Cs]) :- !.
rn_bump([X|Cs], N, C, [X|Ds]) :- rn_bump(Cs, N, C, Ds).

rn_noun_of(V, [T|Ts], N) :-
    (   compound(T), \+ T = (_ :- _), \+ T = neg(_),
        functor(T, N, 1), arg(1, T, A), A == V
    ->  true
    ;   rn_noun_of(V, Ts, N)
    ).
