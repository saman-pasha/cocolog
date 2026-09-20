%% library(reasoning/translate) -- a language lesson as a knowledge base, and
%% a translation as a proof over it. TWENTY LINES OF SPANISH, read by
%% reason_learn/1 into facts and rules -- no lexicon, no corpus, no model,
%% nothing in the library that knows a word of Spanish -- and then simple
%% sentences translated both ways, the lesson questioned, and what it
%% refuses.
%%
%%     cocolog -s test/translate.pl        from the checkout root
%%
%% One process for the lot, and nothing here needs a server or a build flag:
%% both libraries are clauses over a DCG, so this case runs everywhere.

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/translate)).

main :-
    lesson, into_spanish, into_english, questions, rules, refusals, outline,
    checks_done.

%% the twenty lines, one sentence each: the language, six nouns, three
%% adjectives, four verbs, four articles, two rules of gender and one of order
lesson_text('Spanish is a language.
The noun "casa" means "house".
The noun "perro" means "dog".
The noun "gato" means "cat".
The noun "mesa" means "table".
The noun "libro" means "book".
The noun "pan" means "bread".
The adjective "grande" means "big".
The masculine adjective "rojo" means "red".
The feminine adjective "roja" means "red".
The verb "es" means "is".
The verb "come" means "eats".
The verb "lee" means "reads".
The verb "tiene" means "has".
The masculine article "el" means "the".
The feminine article "la" means "the".
The masculine article "un" means "a".
The feminine article "una" means "a".
Every noun that ends in "a" is feminine.
Every noun that does not end in "a" is masculine.
Every adjective follows the noun.').

%% ---- the lesson, learned ------------------------------------------------------

lesson :-
    section('the lesson: twenty lines, forty-four terms'),
    lesson_text(Text),
    reason_tokens(Text, Tokens),
    findall(S, member('.', Tokens), Stops), length(Stops, NS),
    check('twenty-one sentences: the language and twenty lines', NS, 21),
    reason_learn(Text, Terms),
    length(Terms, NT),
    check('forty-four terms out of them', NT, 44),
    yes_no(memberchk(mean(casa, house), Terms), L1),
    check('a mentioned word means a mentioned word', L1, yes),
    yes_no(memberchk(noun(casa), Terms), L2),
    check('`the noun "casa"'': the class is a fact about the word', L2, yes),
    yes_no(( memberchk(article(la), Terms), memberchk(feminine(la), Terms) ), L3),
    check('`the feminine article "la"'': the adjective too', L3, yes),
    yes_no(memberchk(language(spanish), Terms), L4),
    check('the language is a fact', L4, yes),
    member((feminine(X5) :- B5), Terms), B5 = (noun(Y5), end_in(Z5, a)),
    yes_no((X5 == Y5, Y5 == Z5), S5),
    check('`every noun that ends in "a" is feminine'' is a rule over end_in/2', S5, yes),
    member((masculine(X6) :- B6), Terms), B6 = (noun(Y6), \+ end_in(Z6, a)),
    yes_no((X6 == Y6, Y6 == Z6), S6),
    check('`that does not end in "a"'' is \\+ end_in/2', S6, yes),
    member((follow(X7, noun) :- adjective(Y7)), Terms),
    yes_no(X7 == Y7, S7),
    check('`every adjective follows the noun'' is a rule too', S7, yes),
    truth(feminine(mesa), T8),   check('and the rules RUN: mesa ends in a', T8, true),
    truth(masculine(perro), T9), check('perro does not', T9, true),
    truth(feminine(perro), T10), check('so it is not feminine: unknown, the text never said', T10, unknown),
    truth(feminine(grande), T11), check('an adjective the lesson gave no gender: unknown', T11, unknown),
    truth(follow(roja, noun), T12), check('roja follows its noun', T12, true).

%% ---- into Spanish ------------------------------------------------------------------

into_spanish :-
    section('into Spanish: article and adjective agree, the adjective follows'),
    reason_translate('The house is big.', S1),
    check('a feminine noun by the rule takes la; grande has no gender and fits', S1, 'La casa es grande.'),
    reason_translate('The dog eats the bread.', S2),
    check('masculine by the rule, twice', S2, 'El perro come el pan.'),
    reason_translate('Maria has a red table.', S3),
    check('a name passes through; una and roja agree with mesa; roja after it', S3, 'Maria tiene una mesa roja.'),
    reason_translate('The cat reads a big book.', S4),
    check('un with libro; grande after it', S4, 'El gato lee un libro grande.'),
    reason_translate('The table is red.', S5),
    check('a bare adjective agrees with the subject', S5, 'La mesa es roja.'),
    reason_translate('The dog is red.', S6),
    check('and rojo with perro', S6, 'El perro es rojo.'),
    reason_translate('The house is big. The dog eats the bread!', S7),
    check('two sentences, each ending as it ended', S7, 'La casa es grande. El perro come el pan!'),
    reason_translate('The house is big.', spanish, S8),
    check('reason_translate/3 by the name the lesson gave', S8, 'La casa es grande.').

%% ---- into English ------------------------------------------------------------------

into_english :-
    section('into English: which way, the words say'),
    reason_translate('La casa es grande.', E1),
    check('the same sentence back', E1, 'The house is big.'),
    reason_translate('El perro come el pan.', E2),
    check('el and la are both the', E2, 'The dog eats the bread.'),
    reason_translate('Maria tiene una mesa roja.', E3),
    check('the adjective goes before the noun again', E3, 'Maria has a red table.'),
    reason_translate('El gato lee un libro grande.', E4),
    check('un is a', E4, 'The cat reads a big book.'),
    reason_translate('La mesa es roja.', E5),
    check('roja is red', E5, 'The table is red.'),
    reason_translate('La casa es grande.', english, E6),
    check('reason_translate/3 into english', E6, 'The house is big.'),
    reason_translate('The house is big.', S7), reason_translate(S7, E7),
    check('the round trip', E7, 'The house is big.').

%% ---- the lesson questioned ---------------------------------------------------------

questions :-
    section('the lesson questioned: a quoted word in a question'),
    reason_ask('Is "mesa" feminine? Is "perro" masculine? Is "perro" feminine? What does "perro" mean? Why is "mesa" feminine? Why is "perro" masculine?', As),
    As = [A1, A2, A3, A4, A5, A6],
    check('yes, by the rule, with the body as it proved', A1, yes(rule((feminine(mesa) :- noun(mesa), end_in(mesa, a))))),
    check('yes, by the other rule', A2, yes(rule((masculine(perro) :- noun(perro), \+ end_in(perro, a))))),
    check('unknown: the lesson never said', A3, unknown),
    check('what does "perro" mean: the fact', A4, [dog-fact]),
    check('why: the proof in sentences, the word in its quotation marks', A5,
          because('"mesa" is feminine because "mesa" is a noun and "mesa" ends in "a".')),
    check('a helper that fails is said as it is, not as `nothing shows''', A6,
          because('"perro" is masculine because "perro" is a noun and "perro" does not end in "a".')).

%% ---- the rules are what the translator asks ---------------------------------------------

rules :-
    section('the order is the rule, not the code'),
    retract((follow(X, noun) :- adjective(X))),
    reason_translate('Maria has a red table.', S1),
    check('without `every adjective follows the noun'', English''s order', S1, 'Maria tiene una roja mesa.'),
    reason_translate('Maria tiene una roja mesa.', E1),
    check('and read back that way: the noun is the last word again', E1, 'Maria has a red table.'),
    assertz((follow(Y, noun) :- adjective(Y))),
    reason_translate('Maria has a red table.', S2),
    check('the rule back, the order back', S2, 'Maria tiene una mesa roja.'),
    assertz(feminine(pan)),
    reason_translate('The bread is red.', S3),
    check('a gender said of a word wins over the rule: feminine is asked first', S3, 'La pan es roja.'),
    retract(feminine(pan)).

%% ---- what it refuses, whole ----------------------------------------------------------

refusals :-
    section('refused whole, and reason_untranslated/2 says which word'),
    yes_no(reason_translate('The house is small.', _), R1),
    check('a word the lesson has no meaning for', R1, no),
    reason_untranslated('The house is small.', U1),
    check('named', U1, [small]),
    yes_no(reason_translate('Maria sleeps.', _), R2),
    check('no known word at all: which way is not even settled', R2, no),
    reason_untranslated('Maria sleeps.', U2),
    check('the name is not reported, the verb is', U2, [sleeps]),
    yes_no(reason_translate('The house.', _), R3),
    check('no verb', R3, no),
    reason_untranslated('The house.', U3),
    check('and nothing untranslated: the words are known, the shape is not', U3, []),
    yes_no(reason_translate('Maria has 3 dogs.', _), R4),
    check('a number is not a sentence this translates', R4, no),
    yes_no(reason_translate('The house is big. The house is small.', _), R5),
    check('two sentences, one refused: both refused', R5, no),
    catch(( reason_translate('La casa es grande.', french, _), E6 = none ), error(E6, _), true),
    check('a language the lesson did not name', E6, domain_error(language, french)),
    catch(( reason_translate(42, _), E7 = none ), error(E7, _), true),
    check('not text', E7, type_error(text, 42)).

%% ---- the lesson outlined -------------------------------------------------------------

outline :-
    section('the lesson as an outline'),
    lesson_text(Text),
    reason_outline(Text, Lines),
    Lines = [L1, L2|_],
    check('the class with the most said about it first: its members and its rules', L1,
          'Noun ("casa", "perro", "gato", "mesa", "libro" and "pan"): every noun that ends in "a" is feminine; every noun that does not end in "a" is masculine.'),
    check('then the adjectives', L2, 'Adjective ("grande", "rojo" and "roja"): every adjective follows the noun.'),
    yes_no(memberchk('"casa", a noun: means "house".', Lines), O3),
    check('a word with its class and its meaning', O3, yes),
    yes_no(memberchk('"la", an article: feminine; means "the".', Lines), O4),
    check('an article with its gender', O4, yes),
    yes_no(memberchk('Feminine: a noun that ends in "a".', Lines), O5),
    check('a definition: the condition with its object', O5, yes),
    yes_no(memberchk('Masculine: a noun that does not end in "a".', Lines), O6),
    check('and negated', O6, yes).
