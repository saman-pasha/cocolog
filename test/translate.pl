%% library(reasoning/translate) -- a language lesson as a knowledge base, and
%% a translation as a proof over it. THIRTY-TWO LINES OF SPANISH, read by
%% reason_learn/1 into facts and rules -- no lexicon, no corpus, no model,
%% nothing in the library that knows a word of Spanish -- and then simple
%% sentences translated both ways, singular and plural, denied and not; the
%% lesson questioned; and what it refuses.
%%
%%     cocolog -s test/translate.pl        from the checkout root
%%
%% One process for the lot, and nothing here needs a server or a build flag:
%% both libraries are clauses over a DCG, so this case runs everywhere.

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/translate)).

main :-
    lesson, into_spanish, into_english, plurals, negation, questions, rules, refusals, outline,
    checks_done.

%% the lesson, one sentence a line: the language, six nouns, three
%% adjectives, four verbs, four articles, two rules of gender and one of
%% order; then the plural -- four ending rules, three stated plurals -- the
%% word for `not', where it stands, and one more noun
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
Every adjective follows the noun.
Every noun that ends in a vowel takes "s" in the plural.
Every noun that ends in a consonant takes "es" in the plural.
Every adjective that ends in a vowel takes "s" in the plural.
Every article that ends in a vowel takes "s" in the plural.
"los" is the plural of "el".
"unos" is the plural of "un".
Every verb that ends in "e" takes "n" in the plural.
"son" is the plural of "es".
The word "no" means "not".
The word "no" precedes the verb.
The noun "huevo" means "egg".').

%% ---- the lesson, learned ------------------------------------------------------

lesson :-
    section('the lesson: thirty-two lines, fifty-eight terms'),
    lesson_text(Text),
    reason_tokens(Text, Tokens),
    findall(S, member('.', Tokens), Stops), length(Stops, NS),
    check('thirty-two sentences', NS, 32),
    reason_learn(Text, Terms),
    length(Terms, NT),
    check('fifty-eight terms out of them', NT, 58),
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
    member((take_in(X8, es, plural) :- B8), Terms), B8 = (noun(Y8), end_in(Z8, consonant)),
    yes_no((X8 == Y8, Y8 == Z8), S8),
    check('`takes "es" in the plural'' is take_in/3 over a letter class', S8, yes),
    yes_no(( memberchk(plural_of(los, el), Terms), memberchk(plural_of(son, es), Terms) ), L9),
    check('`"los" is the plural of "el"'' is plural_of/2', L9, yes),
    yes_no(( memberchk(mean(no, not), Terms), memberchk(precede(no, verb), Terms) ), L10),
    check('the word for not, and where it stands', L10, yes),
    truth(feminine(mesa), T11),   check('and the rules RUN: mesa ends in a', T11, true),
    truth(masculine(perro), T12), check('perro does not', T12, true),
    truth(feminine(perro), T13), check('so it is not feminine: unknown, the text never said', T13, unknown),
    truth(feminine(grande), T14), check('an adjective the lesson gave no gender: unknown', T14, unknown),
    truth(follow(roja, noun), T15), check('roja follows its noun', T15, true),
    truth(take_in(casa, s, plural), T16), check('casa takes s: it ends in a vowel', T16, true),
    truth(take_in(pan, es, plural), T17), check('pan takes es: a consonant', T17, true),
    truth(take_in(pan, s, plural), T18), check('and not s', T18, unknown).

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

%% ---- the plural ------------------------------------------------------------------------

plurals :-
    section('the plural: the lesson''s endings and stated plurals, the number the noun''s'),
    reason_translate('The houses are big.', P1),
    check('las, casas, son, grandes: an article, a noun and an adjective by the rules, the verb stated', P1, 'Las casas son grandes.'),
    reason_translate('The dogs eat the bread.', P2),
    check('los stated; comen by the verb rule; the object keeps its own number', P2, 'Los perros comen el pan.'),
    reason_translate('Maria has red tables.', P3),
    check('no article, and the adjective agrees in gender and number', P3, 'Maria tiene mesas rojas.'),
    reason_translate('The cats read the books.', P4),
    check('both phrases plural', P4, 'Los gatos leen los libros.'),
    reason_translate('The eggs are red.', P5),
    check('a bare adjective in the subject''s number', P5, 'Los huevos son rojos.'),
    reason_translate('Maria has an egg.', P6),
    check('an is a', P6, 'Maria tiene un huevo.'),
    reason_translate('Las casas son grandes.', E1),
    check('back: are, and a plural noun by -s', E1, 'The houses are big.'),
    reason_translate('Los perros comen el pan.', E2),
    check('a base form in the plural', E2, 'The dogs eat the bread.'),
    reason_translate('Maria tiene mesas rojas.', E3),
    check('adjectives do not inflect in English', E3, 'Maria has red tables.'),
    reason_translate('Los gatos leen los libros.', E4),
    check('the is the either way', E4, 'The cats read the books.'),
    reason_translate('Maria tiene unos libros.', E5),
    check('unos is the plural of un, and English has no plural a', E5, 'Maria has books.'),
    reason_translate('Maria tiene un huevo.', E6),
    check('an before a vowel', E6, 'Maria has an egg.'),
    reason_translate('The houses are big.', S7), reason_translate(S7, E7),
    check('the round trip', E7, 'The houses are big.').

%% ---- negation ----------------------------------------------------------------------------

negation :-
    section('negation: the lesson''s word for not, and English''s does not, do not, is not'),
    reason_translate('The dog does not eat the bread.', N1),
    check('does not eat: no before the verb', N1, 'El perro no come el pan.'),
    reason_translate('The house is not big.', N2),
    check('is not: the same word, the same place', N2, 'La casa no es grande.'),
    reason_translate('The dogs do not eat the bread.', N3),
    check('do not, plural', N3, 'Los perros no comen el pan.'),
    reason_translate('Maria does not have a red table.', N4),
    check('does not have', N4, 'Maria no tiene una mesa roja.'),
    reason_translate('The houses are not big.', N5),
    check('are not', N5, 'Las casas no son grandes.'),
    reason_translate('El perro no come el pan.', E1),
    check('back: does not, and the base form', E1, 'The dog does not eat the bread.'),
    reason_translate('La casa no es grande.', E2),
    check('is not', E2, 'The house is not big.'),
    reason_translate('Los perros no comen el pan.', E3),
    check('do not', E3, 'The dogs do not eat the bread.'),
    reason_translate('Maria no tiene una mesa roja.', E4),
    check('does not have', E4, 'Maria does not have a red table.'),
    reason_translate('Las casas no son grandes.', E5),
    check('are not', E5, 'The houses are not big.'),
    reason_translate('The dogs are not red houses.', N6),
    check('a plural denied predicate phrase', N6, 'Los perros no son casas rojas.').

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
          because('"perro" is masculine because "perro" is a noun and "perro" does not end in "a".')),
    reason_ask('Is "los" the plural of "el"? What is the plural of "el"? Does "casa" take "s" in the plural? Why does "pan" take "es" in the plural? Why is "los" the plural of "el"? What does "no" mean?', Bs),
    Bs = [B1, B2, B3, B4, B5, B6],
    check('a stated plural: yes, as said', B1, yes(fact)),
    check('what is the plural of: the relation the noun names', B2, [los-fact]),
    check('a ruled plural: yes, by the rule', B3, yes(rule((take_in(casa, s, plural) :- noun(casa), end_in(casa, vowel))))),
    check('why: a letter class said with its article', B4,
          because('"pan" takes "es" in the plural because "pan" is a noun and "pan" ends in a consonant.')),
    check('why a stated plural: as said, with the noun', B5, because('"los" is the plural of "el", as said.')),
    check('the word for not', B6, [not-fact]).

%% ---- the rules are what the translator asks ---------------------------------------------

rules :-
    section('the order, the plural and the denial are the rules, not the code'),
    retract((follow(X, noun) :- adjective(X))),
    reason_translate('Maria has a red table.', S1),
    check('without `every adjective follows the noun'', English''s order', S1, 'Maria tiene una roja mesa.'),
    reason_translate('Maria tiene una roja mesa.', E1),
    check('and read back that way: the classes say which is the noun', E1, 'Maria has a red table.'),
    assertz((follow(Y, noun) :- adjective(Y))),
    reason_translate('Maria has a red table.', S2),
    check('the rule back, the order back', S2, 'Maria tiene una mesa roja.'),
    assertz(feminine(pan)),
    reason_translate('The bread is red.', S3),
    check('a gender said of a word wins over the rule: feminine is asked first', S3, 'La pan es roja.'),
    retract(feminine(pan)),
    retract((take_in(V, n, plural) :- verb(V), end_in(V, e))),
    yes_no(reason_translate('The dogs eat the bread.', _), R4),
    check('without the verb rule a plural verb cannot be made: refused whole', R4, no),
    assertz((take_in(V2, n, plural) :- verb(V2), end_in(V2, e))),
    retract(mean(no, not)),
    yes_no(reason_translate('The dog does not eat the bread.', _), R5),
    check('without a word for not a denial cannot be said: refused', R5, no),
    reason_untranslated('The dog does not eat the bread.', U5),
    check('and English''s not, does and do are not reported: they are the translator''s own', U5, []),
    assertz(mean(no, not)),
    assertz((follow(N6, verb) :- mean(N6, not))),
    reason_translate('The dog does not eat the bread.', S6),
    check('a lesson whose denial follows the verb', S6, 'El perro come no el pan.'),
    reason_translate('El perro come no el pan.', E6),
    check('and read from there', E6, 'The dog does not eat the bread.'),
    retract((follow(_, verb) :- mean(_, not))).

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
    yes_no(reason_translate('Maria does not sleep.', _), R6),
    check('a denied verb the lesson does not know', R6, no),
    reason_untranslated('Maria does not sleep.', U6),
    check('reported as its base form, the word as typed', U6, [sleep]),
    catch(( reason_translate('La casa es grande.', french, _), E7 = none ), error(E7, _), true),
    check('a language the lesson did not name', E7, domain_error(language, french)),
    catch(( reason_translate(42, _), E8 = none ), error(E8, _), true),
    check('not text', E8, type_error(text, 42)).

%% ---- the lesson outlined -------------------------------------------------------------

outline :-
    section('the lesson as an outline'),
    lesson_text(Text),
    reason_outline(Text, Lines),
    Lines = [L1|_],
    check('the class with the most said about it first: its members and its four rules', L1,
          'Noun ("casa", "perro", "gato", "mesa", "libro", "pan" and "huevo"): every noun that ends in "a" is feminine; every noun that does not end in "a" is masculine; every noun that ends in a vowel takes "s" in the plural; every noun that ends in a consonant takes "es" in the plural.'),
    yes_no(memberchk('Adjective ("grande", "rojo" and "roja"): every adjective follows the noun; every adjective that ends in a vowel takes "s" in the plural.', Lines), O2),
    check('the adjectives, with both their rules', O2, yes),
    yes_no(memberchk('"casa", a noun: means "house".', Lines), O3),
    check('a word with its class and its meaning', O3, yes),
    yes_no(memberchk('"el", an article: masculine; means "the"; "los" is the plural of it.', Lines), O4),
    check('an article with its gender and its stated plural', O4, yes),
    yes_no(memberchk('"son": is the plural of "es".', Lines), O5),
    check('a stated plural from the other side', O5, yes),
    yes_no(memberchk('Feminine: a noun that ends in "a".', Lines), O6),
    check('a definition: the condition with its object', O6, yes),
    yes_no(memberchk('Masculine: a noun that does not end in "a".', Lines), O7),
    check('and negated', O7, yes).
