%% library(reasoning/translate) -- a language lesson as a knowledge base, and
%% a translation as a proof over it. ONE HUNDRED AND EIGHTY-THREE LINES OF
%% SPANISH, read by reason_learn/1 into facts and rules -- no lexicon, no
%% corpus, no model, nothing in the library that knows a word of Spanish --
%% and then simple sentences translated both ways: singular and plural,
%% denied and not, in every person, present, past, future and perfect,
%% with a pronoun, a possessive, a number, a prepositional phrase, an
%% adverb or two subjects joined, a person as the object with the word
%% the lesson puts before one, statements and questions (yes or no, what,
%% who, whom, where, when, which); a second lesson learned under its own
%% name beside it; the lesson questioned; and what it refuses.
%%
%%     cocolog -s test/translate.pl        from the checkout root
%%
%% One process for the lot, and nothing here needs a server or a build flag:
%% both libraries are clauses over a DCG, so this case runs everywhere.

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/translate)).
:- use_module(library(reasoning/normalise)).     % normalise_corpus_dir/1, for the vocabulary files

main :-
    lesson, into_spanish, into_english, plurals, negation, asks, past,
    persons, future, perfect, phrases, wh, languages, ir, elision, clauses, passive, reflexive, reduced, purpose,
    complement, superlative, inversion, headline, subordinate, names, imperatives,
    adjuncts, newspaper_es, newspaper_it, newspaper_fiat, newspaper_valencia, newspaper_bio, newspaper_football,
    newspaper_monreale, newspaper_record, newspaper_islands, newspaper_opera, newspaper_ferlaino,
    newspaper_georgia, newspaper_wapo, newspaper_clinton, newspaper_letter, newspaper_solana,
    newspaper_pacifist, newspaper_mobile, newspaper_bastille, newspaper_basque, newspaper_giglio,
    newspaper_england, newspaper_bovalino, newspaper_puigbo, newspaper_salvini, newspaper_radio,
    newspaper_fregene, newspaper_lotr, newspaper_ciampi, newspaper_omnium, newspaper_astro, newspaper_senegal,
    newspaper_eco, newspaper_arzalluz, newspaper_cecchi,
    questions, rules, refusals, outline, vocabulary, shapes, build,
    checks_done.

%% the lesson, one sentence a line, in three parts because a clause over a
%% page (8 KB) cannot be stored: the language, the nouns, adjectives, verbs
%% and articles, the rules of gender and order; the plural -- ending rules
%% and stated plurals -- the word for `not' and where it stands, the
%% question words and the mark a question begins with; the past of each
%% verb in both numbers and the English pasts the -ed rule cannot make;
%% the future, by a rule and stated; the auxiliary and the participles;
%% the first and second persons; the pronouns, possessives, prepositions,
%% the word before a person and two contractions, adverbs, numbers and
%% the conjunction
lesson_text(Text) :- lesson_part(1, A), lesson_part(2, B), lesson_part(3, C), atomic_list_concat([A, ' ', B, ' ', C], Text).

lesson_part(1, 'Spanish is a language.
The noun "casa" means "house".
The noun "perro" means "dog".
The noun "gato" means "cat".
The noun "mesa" means "table".
The noun "libro" means "book".
The noun "pan" means "bread".
The noun "huevo" means "egg".
The noun "leche" means "milk".
"leche" is feminine.
The noun "ciudad" means "city".
"ciudad" is feminine.
The noun "amigo" means "friend".
The noun "amiga" means "friend".
The adjective "grande" means "big".
The masculine adjective "rojo" means "red".
The feminine adjective "roja" means "red".
The masculine adjective "pequeño" means "small".
The feminine adjective "pequeña" means "small".
The verb "es" means "is".
The verb "come" means "eats".
The verb "lee" means "reads".
The verb "tiene" means "has".
The verb "vive" means "lives".
The verb "ve" means "sees".
The verb "da" means "gives".
The verb "canta" means "sings".
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
Every possessive that ends in a vowel takes "s" in the plural.
"los" is the plural of "el".
"unos" is the plural of "un".
Every verb that ends in "e" takes "n" in the plural.
"son" is the plural of "es".
"viven" is the plural of "vive".
"ven" is the plural of "ve".
"dan" is the plural of "da".
"cantan" is the plural of "canta".
The word "no" means "not".
The word "no" precedes the verb.
The word "qué" means "what".
The word "qué" means "which".
The word "quién" means "who".
The word "dónde" means "where".
The word "cuándo" means "when".
The mark "¿" begins the question.
"comió" is the past of "come".
"comieron" is the past of "comen".').
lesson_part(2, '"leyó" is the past of "lee".
"leyeron" is the past of "leen".
"tenía" is the past of "tiene".
"tenían" is the past of "tienen".
"era" is the past of "es".
"eran" is the past of "son".
"vivió" is the past of "vive".
"vivieron" is the past of "viven".
"vio" is the past of "ve".
"vieron" is the past of "ven".
"dio" is the past of "da".
"dieron" is the past of "dan".
"cantó" is the past of "canta".
"cantaron" is the past of "cantan".
"ate" is the past of "eats".
"read" is the past of "reads".
"saw" is the past of "sees".
"gave" is the past of "gives".
"sang" is the past of "sings".
Every verb that ends in "e" takes "rá" in the future.
Every verb that ends in "a" takes "rá" in the future.
"será" is the future of "es".
"tendrá" is the future of "tiene".
"vivirá" is the future of "vive".
"comerán" is the plural of "comerá".
"leerán" is the plural of "leerá".
"serán" is the plural of "será".
"tendrán" is the plural of "tendrá".
"vivirán" is the plural of "vivirá".
"verán" is the plural of "verá".
"darán" is the plural of "dará".
"cantarán" is the plural of "cantará".
The auxiliary "ha" means "has".
"han" is the plural of "ha".
"he" is the first person of "ha".
"has" is the second person of "ha".
"hemos" is the first person of "han".
"había" is the past of "ha".
"habían" is the past of "han".
The auxiliary "está" means "is".
"están" is the plural of "está".
"estoy" is the first person of "está".
"estás" is the second person of "está".
"estamos" is the first person of "están".
"estaba" is the past of "está".
"estaban" is the past of "están".
"comido" is the participle of "come".
"leído" is the participle of "lee".
"tenido" is the participle of "tiene".
"sido" is the participle of "es".
"vivido" is the participle of "vive".
"visto" is the participle of "ve".
"dado" is the participle of "da".
"cantado" is the participle of "canta".
"eaten" is the participle of "eats".
"seen" is the participle of "sees".
"given" is the participle of "gives".
"sung" is the participle of "sings".
"como" is the first person of "come".
"comes" is the second person of "come".
"comemos" is the first person of "comen".
"soy" is the first person of "es".
"eres" is the second person of "es".
"somos" is the first person of "son".').
lesson_part(3, '"tengo" is the first person of "tiene".
"tienes" is the second person of "tiene".
"tenemos" is the first person of "tienen".
"vivo" is the first person of "vive".
"vives" is the second person of "vive".
"vivimos" is the first person of "viven".
"veo" is the first person of "ve".
"ves" is the second person of "ve".
"vemos" is the first person of "ven".
"leo" is the first person of "lee".
"canto" is the first person of "canta".
"doy" is the first person of "da".
"comí" is the first person of "comió".
"comiste" is the second person of "comió".
"comimos" is the first person of "comieron".
"comeré" is the first person of "comerá".
"comerás" is the second person of "comerá".
"comeremos" is the first person of "comerán".
"fui" is the first person of "era".
"fuimos" is the first person of "eran".
"seré" is the first person of "será".
The pronoun "yo" means "I".
The pronoun "tú" means "you".
The pronoun "él" means "he".
The pronoun "ella" means "she".
The pronoun "nosotros" means "we".
The pronoun "ellos" means "they".
The pronoun "me" means "me".
The pronoun "te" means "you".
The pronoun "lo" means "him".
The pronoun "la" means "her".
The pronoun "lo" means "it".
The pronoun "nos" means "us".
The pronoun "los" means "them".
The pronoun "le" means "him".
The pronoun "él" means "him".
The pronoun "ella" means "her".
The pronoun "nosotros" means "us".
The pronoun "ellos" means "them".
Every pronoun precedes the verb.
The pronoun "él" does not precede the verb.
The possessive "mi" means "my".
The possessive "tu" means "your".
The possessive "su" means "his".
The possessive "su" means "her".
The masculine possessive "nuestro" means "our".
The feminine possessive "nuestra" means "our".
The preposition "en" means "in".
The preposition "con" means "with".
The preposition "a" means "to".
The preposition "de" means "of".
The word "a" precedes the person.
"amigo" is a person.
"amiga" is a person.
"al" is the contraction of "a el".
"del" is the contraction of "de el".
The adverb "rápidamente" means "quickly".
The adverb "bien" means "well".
The adverb "hoy" means "today".
The adverb "siempre" means "always".
The preposition "para" means "for".
The noun "sábado" means "saturday".
"sábado" is a time.
The pronoun "todo" means "everything".
The pronoun "todo" does not precede the verb.
The number "dos" means "two".
The number "tres" means "three".
The conjunction "y" means "and".').

%% ---- the lesson, learned ------------------------------------------------------

lesson :-
    section('the lesson: one hundred and eighty-nine lines, three hundred and eleven terms'),
    lesson_text(Text),
    reason_tokens(Text, Tokens),
    findall(S, member('.', Tokens), Stops), length(Stops, NS),
    check('one hundred and eighty-nine sentences', NS, 189),
    reason_learn(Text, Terms),
    length(Terms, NT),
    check('three hundred and eleven terms out of them', NT, 311),
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
    yes_no(( memberchk(mean('qué', what), Terms), memberchk(mean('quién', who), Terms), memberchk(mean('dónde', where), Terms), memberchk(mean('cuándo', when), Terms), memberchk(mean('qué', which), Terms) ), L10q),
    check('the question words are vocabulary, and one word may mean two', L10q, yes),
    yes_no(( memberchk(mark('¿'), Terms), memberchk(begin('¿', question), Terms) ), L10m),
    check('`the mark "¿" begins the question'': the class atom, and not the reader''s question/1', L10m, yes),
    yes_no(( memberchk(past_of('comió', come), Terms), memberchk(past_of(comieron, comen), Terms), memberchk(past_of(ate, eats), Terms) ), L10p),
    check('a past is stated of a form, singular or plural, on either side', L10p, yes),
    yes_no(( memberchk(future_of('será', es), Terms), member((take_in(F10, 'rá', future) :- verb(G10), end_in(H10, e)), Terms), F10 == G10, G10 == H10 ), L10f),
    check('a future stated, and a future by a rule', L10f, yes),
    yes_no(( memberchk(auxiliary(ha), Terms), memberchk(mean(ha, has), Terms), memberchk(participle_of(comido, come), Terms), memberchk(participle_of(eaten, eats), Terms) ), L10h),
    check('the auxiliary, and a participle on either side', L10h, yes),
    yes_no(( memberchk(person_of(como, come), Terms), memberchk(first(como), Terms), memberchk(second(comes), Terms) ), L10n),
    check('`"como" is the first person of "come"'': person_of/2 and the adjective as a fact', L10n, yes),
    yes_no(( memberchk(pronoun(yo), Terms), memberchk(mean(yo, i), Terms), memberchk(mean(lo, him), Terms), memberchk(mean(lo, it), Terms), memberchk(possessive(mi), Terms), memberchk(preposition(en), Terms), memberchk(adverb(hoy), Terms), memberchk(number(dos), Terms), memberchk(conjunction(y), Terms) ), L10w),
    check('pronouns, possessives, prepositions, adverbs, numbers and the conjunction are classes too', L10w, yes),
    yes_no(memberchk(neg(precede('él', verb)), Terms), L10d),
    check('`the pronoun "él" does not precede the verb'' is a denial', L10d, yes),
    yes_no(( memberchk(precede(a, person), Terms), memberchk(person(amigo), Terms), memberchk(contraction_of(al, 'a el'), Terms) ), L10a),
    check('the word before a person, a person, and a contraction with its two words', L10a, yes),
    truth(feminine(mesa), T11),   check('and the rules RUN: mesa ends in a', T11, true),
    truth(masculine(perro), T12), check('perro does not', T12, true),
    truth(feminine(perro), T13), check('so it is not feminine: unknown, the text never said', T13, unknown),
    truth(feminine(grande), T14), check('an adjective the lesson gave no gender: unknown', T14, unknown),
    truth(follow(roja, noun), T15), check('roja follows its noun', T15, true),
    truth(take_in(casa, s, plural), T16), check('casa takes s: it ends in a vowel', T16, true),
    truth(take_in(pan, es, plural), T17), check('pan takes es: a consonant', T17, true),
    truth(take_in(pan, s, plural), T18), check('and not s', T18, unknown),
    truth(take_in(come, 'rá', future), T19), check('come takes rá in the future: it ends in e', T19, true),
    truth(feminine(leche), T20), check('a gender the lesson states of a word that breaks its rule', T20, true).

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
    check('the is the either way, and los before a noun is the article, not them', E4, 'The cats read the books.'),
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

%% ---- questions translated -------------------------------------------------------------

asks :-
    section('questions: yes or no, what for the object, who for the subject'),
    reason_translate('Is the house big?', Q1),
    check('the copula fronted in English; the statement''s order and the lesson''s mark in Spanish', Q1, '¿La casa es grande?'),
    reason_translate('Does the dog eat the bread?', Q2),
    check('does, and the base form', Q2, '¿El perro come el pan?'),
    reason_translate('Do the dogs eat the bread?', Q3),
    check('do, plural', Q3, '¿Los perros comen el pan?'),
    reason_translate('Is the house not big?', Q4),
    check('denied', Q4, '¿La casa no es grande?'),
    reason_translate('What does the dog eat?', Q5),
    check('what: the object asked, and the verb before the subject', Q5, '¿Qué come el perro?'),
    reason_translate('Who eats the bread?', Q6),
    check('who: the subject asked', Q6, '¿Quién come el pan?'),
    reason_translate('Who is big?', Q7),
    check('who, with the copula', Q7, '¿Quién es grande?'),
    reason_translate('Who does not eat the bread?', Q8),
    check('who, denied', Q8, '¿Quién no come el pan?'),
    reason_translate('Is the big house red?', Q9),
    check('the subject phrase ends at its noun', Q9, '¿La casa grande es roja?'),
    reason_translate('What is the house?', Q10),
    check('what, with the copula', Q10, '¿Qué es la casa?'),
    reason_translate('¿La casa es grande?', E1),
    check('back: the copula fronted', E1, 'Is the house big?'),
    reason_translate('¿Es grande la casa?', E2),
    check('the verb first and the adjective before the subject: read as well', E2, 'Is the house big?'),
    reason_translate('¿Come el perro el pan?', E3),
    check('the verb first, then the subject up to the next article', E3, 'Does the dog eat the bread?'),
    reason_translate('¿El perro no come el pan?', E4),
    check('denied: not after the subject', E4, 'Does the dog not eat the bread?'),
    reason_translate('¿Qué come el perro?', E5),
    check('what does', E5, 'What does the dog eat?'),
    reason_translate('¿Quién come el pan?', E6),
    check('who eats', E6, 'Who eats the bread?'),
    reason_translate('¿Quién es grande?', E7),
    check('who is', E7, 'Who is big?'),
    reason_translate('¿Los perros comen el pan?', E8),
    check('do the dogs', E8, 'Do the dogs eat the bread?'),
    reason_translate('¿Come Maria el pan?', E9),
    check('a name after the verb', E9, 'Does Maria eat the bread?'),
    reason_translate('The house is big. Is the house big?', M1),
    check('a statement and a question, each its own', M1, 'La casa es grande. ¿La casa es grande?'),
    reason_translate('What does the dog eat?', S2), reason_translate(S2, E10),
    check('the round trip', E10, 'What does the dog eat?'),
    retract(begin('¿', question)),
    reason_translate('Is the house big?', Q12),
    check('without the mark the lesson gave, none', Q12, 'La casa es grande?'),
    assertz(begin('¿', question)),
    retract(mean('qué', what)),
    yes_no(reason_translate('What does the dog eat?', _), R13),
    check('a question word the lesson did not give: refused, never passed through as a name', R13, no),
    reason_untranslated('What does the dog eat?', U13),
    check('and reported', U13, [what]),
    assertz(mean('qué', what)).

%% ---- the past ---------------------------------------------------------------------------

past :-
    section('the past: a form the lesson stated or ruled; English''s own -ed, was, were, had, did'),
    reason_translate('The dog ate the bread.', P1),
    check('a past the lesson stated, of the singular form', P1, 'El perro comió el pan.'),
    reason_translate('The dogs ate the bread.', P2),
    check('and of the plural form: `"comieron" is the past of "comen"''', P2, 'Los perros comieron el pan.'),
    reason_translate('The house was big.', P3),
    check('was: the past of the copula', P3, 'La casa era grande.'),
    reason_translate('The houses were big.', P4),
    check('were', P4, 'Las casas eran grandes.'),
    reason_translate('Maria had a red table.', P5),
    check('had', P5, 'Maria tenía una mesa roja.'),
    reason_translate('The dog did not eat the bread.', P6),
    check('did not: the past, which the base form after it cannot say', P6, 'El perro no comió el pan.'),
    reason_translate('The house was not big.', P7),
    check('was not', P7, 'La casa no era grande.'),
    reason_translate('Did the dog eat the bread?', P8),
    check('did fronted', P8, '¿El perro comió el pan?'),
    reason_translate('Was the house big?', P9),
    check('was fronted', P9, '¿La casa era grande?'),
    reason_translate('What did the dog eat?', P10),
    check('what did', P10, '¿Qué comió el perro?'),
    reason_translate('Who ate the bread?', P11),
    check('who ate', P11, '¿Quién comió el pan?'),
    reason_translate('Who did not eat the bread?', P12),
    check('who did not', P12, '¿Quién no comió el pan?'),
    reason_translate('El perro comió el pan.', E1),
    check('back: a past the lesson stated for English, `"ate" is the past of "eats"''', E1, 'The dog ate the bread.'),
    reason_translate('Los perros comieron el pan.', E2),
    check('a plural past, its form read through the plural rule', E2, 'The dogs ate the bread.'),
    reason_translate('La casa era grande.', E3),
    check('was', E3, 'The house was big.'),
    reason_translate('Las casas eran grandes.', E4),
    check('were', E4, 'The houses were big.'),
    reason_translate('Maria tenía una mesa roja.', E5),
    check('had', E5, 'Maria had a red table.'),
    reason_translate('El perro no comió el pan.', E6),
    check('did not, with the base', E6, 'The dog did not eat the bread.'),
    reason_translate('Los gatos leyeron los libros.', E7),
    check('a past that spells like the base: `"read" is the past of "reads"''', E7, 'The cats read the books.'),
    reason_translate('¿Comió el perro el pan?', E8),
    check('did the dog', E8, 'Did the dog eat the bread?'),
    reason_translate('¿Era grande la casa?', E9),
    check('was the house', E9, 'Was the house big?'),
    reason_translate('¿Qué comió el perro?', E10),
    check('what did', E10, 'What did the dog eat?'),
    reason_translate('¿Quién comió el pan?', E11),
    check('who ate', E11, 'Who ate the bread?'),
    reason_translate('The cats read the books.', E12),
    check('and `read'' typed spells the present too, and the present wins', E12, 'Los gatos leen los libros.'),
    reason_translate('The dog ate the bread.', S13), reason_translate(S13, E13),
    check('the round trip', E13, 'The dog ate the bread.').

%% ---- persons and pronouns ------------------------------------------------------------

persons :-
    section('persons and pronouns: the lesson''s first and second persons, its pronouns, a subject the verb says'),
    reason_translate('I eat the bread.', P1),
    check('I: yo, and the first person the lesson stated', P1, 'Yo como el pan.'),
    reason_translate('You are big.', P2),
    check('you: tú, and eres', P2, 'Tú eres grande.'),
    reason_translate('We are big.', P3),
    check('we: nosotros, and somos, the first person of the plural form', P3, 'Nosotros somos grandes.'),
    reason_translate('They eat the bread.', P4),
    check('they: ellos, and the plural', P4, 'Ellos comen el pan.'),
    reason_translate('I ate the bread.', P5),
    check('the first person of a past form', P5, 'Yo comí el pan.'),
    reason_translate('I was big.', P6),
    check('the first person of the copula''s past', P6, 'Yo fui grande.'),
    reason_translate('You see me.', P7),
    check('the second person of the verb, and me before it: every pronoun precedes the verb', P7, 'Tú me ves.'),
    reason_translate('She sees him.', P8),
    check('him is lo, before the verb', P8, 'Ella lo ve.'),
    reason_translate('He does not see her.', P9),
    check('él with its capital, no, la, ve', P9, 'Él no la ve.'),
    reason_translate('We see them.', P10),
    check('los before the verb, and the first person of the plural', P10, 'Nosotros los vemos.'),
    reason_translate('Maria eats it.', P11),
    check('it as an object is lo', P11, 'Maria lo come.'),
    reason_translate('It is big.', P12),
    check('it as a subject: no word of the lesson may be one, and the verb says who', P12, 'Es grande.'),
    reason_translate('Maria eats with him.', P13),
    check('after a preposition, the pronoun that does not precede the verb: `the pronoun "él" does not precede the verb''', P13, 'Maria come con él.'),
    reason_translate('Maria will eat the bread with us.', P14),
    check('and one that serves as a subject too', P14, 'Maria comerá el pan con nosotros.'),
    reason_translate('My house is big.', P15),
    check('a possessive, agreeing', P15, 'Mi casa es grande.'),
    reason_translate('Our houses are big.', P16),
    check('nuestras: feminine and plural', P16, 'Nuestras casas son grandes.'),
    reason_translate('Her dogs see her.', P17),
    check('her before a noun is the possessive, her after the verb the pronoun', P17, 'Sus perros la ven.'),
    reason_translate('Como el pan.', E1),
    check('back: no subject, and como says I', E1, 'I eat the bread.'),
    reason_translate('Comemos el pan.', E2),
    check('comemos says we', E2, 'We eat the bread.'),
    reason_translate('Comen el pan.', E3),
    check('comen says they', E3, 'They eat the bread.'),
    yes_no(reason_translate('Come el pan.', _), E4),
    check('come says he, she or it: refused, never guessed', E4, no),
    reason_translate('Yo como el pan.', E5),
    check('with the pronoun', E5, 'I eat the bread.'),
    reason_translate('Ella lo ve.', E6),
    check('lo before the verb is the object: him, after it', E6, 'She sees him.'),
    reason_translate('Él no la ve.', E7),
    check('a capital É is a capital', E7, 'He does not see her.'),
    reason_translate('Te veo.', E8),
    check('te could be you the subject; veo says I, so it is the object', E8, 'I see you.'),
    reason_translate('Nos ven.', E9),
    check('nos is never a subject', E9, 'They see us.'),
    reason_translate('La ven.', E10),
    check('la alone is the pronoun, not the article', E10, 'They see her.'),
    reason_translate('Ellos la ven.', E11),
    check('they, and her: the longest subject that is one', E11, 'They see her.'),
    reason_translate('Tú lo ves.', E12),
    check('you, and him', E12, 'You see him.'),
    reason_translate('Sus perros la ven.', E13),
    check('su is his: the first meaning; la after the noun is the object', E13, 'His dogs see her.'),
    reason_translate('Maria come con él.', E14),
    check('with him', E14, 'Maria eats with him.'),
    reason_translate('Maria comerá el pan con nosotros.', E15),
    check('with us: the object form of a pronoun that means we', E15, 'Maria will eat the bread with us.'),
    reason_translate('Fui grande.', E16),
    check('fui says I, in the past', E16, 'I was big.'),
    reason_translate('Nuestras casas son grandes.', E17),
    check('our', E17, 'Our houses are big.'),
    reason_translate('Do you eat the bread?', Q1),
    check('a question to you', Q1, '¿Tú comes el pan?'),
    reason_translate('¿Comes el pan?', Q2),
    check('the verb first, and nothing after it agrees with comes: you', Q2, 'Do you eat the bread?'),
    reason_translate('¿Ella come el pan?', Q3),
    check('a subject pronoun before the verb is the subject, in the statement''s order', Q3, 'Does she eat the bread?'),
    reason_translate('¿Come ella el pan?', Q4),
    check('or after the verb', Q4, 'Does she eat the bread?'),
    reason_translate('What do you eat?', Q5),
    check('what, to you', Q5, '¿Qué comes tú?'),
    reason_translate('¿Qué comes?', Q6),
    check('and with no pronoun at all', Q6, 'What do you eat?'),
    reason_translate('Where did she live?', Q7),
    check('where, to her', Q7, '¿Dónde vivió ella?'),
    reason_translate('She sees him.', S18), reason_translate(S18, E18),
    check('the round trip', E18, 'She sees him.'),
    reason_translate('Maria sees Omar.', A1),
    check('a name as the object: the word the lesson puts before a person', A1, 'Maria ve a Omar.'),
    reason_translate('Maria sees her friend.', A2),
    check('a phrase whose noun the lesson calls a person', A2, 'Maria ve a su amigo.'),
    reason_translate('Maria sees the dog.', A3),
    check('and not before a dog', A3, 'Maria ve el perro.'),
    reason_translate('Maria sees Omar and Pablo.', A4),
    check('two persons joined, one word', A4, 'Maria ve a Omar y Pablo.'),
    reason_translate('Maria sees him.', A5),
    check('a pronoun before the verb takes none', A5, 'Maria lo ve.'),
    reason_translate('Maria does not see Omar.', A6),
    check('denied', A6, 'Maria no ve a Omar.'),
    reason_translate('Maria has seen Omar.', A7),
    check('in the perfect', A7, 'Maria ha visto a Omar.'),
    reason_translate('Maria sees the friend.', A8),
    check('a contraction the lesson states: a el is al', A8, 'Maria ve al amigo.'),
    reason_translate('The dogs of the friend eat.', A9),
    check('de el is del', A9, 'Los perros del amigo comen.'),
    reason_translate('Maria gives the book to Omar.', A10),
    check('after an object the word is the preposition it is', A10, 'Maria da el libro a Omar.'),
    reason_translate('Maria ve a Omar.', B1),
    check('back: the word with a person after it and no object before it is the object', B1, 'Maria sees Omar.'),
    reason_translate('Maria ve a su amiga.', B2),
    check('a person noun', B2, 'Maria sees his friend.'),
    reason_translate('Maria ve el perro.', B3),
    check('no word before a dog', B3, 'Maria sees the dog.'),
    reason_translate('Maria ve a Omar y Pablo.', B4),
    check('two joined', B4, 'Maria sees Omar and Pablo.'),
    reason_translate('Maria ha visto a Omar.', B5),
    check('in the perfect: the participle is a word of the lesson''s, and ha is the lesson''s whatever the inflector makes of it', B5, 'Maria has seen Omar.'),
    reason_translate('Maria ve al amigo.', B6),
    check('al is read as a el', B6, 'Maria sees the friend.'),
    reason_translate('Los perros del amigo comen.', B7),
    check('del is de el', B7, 'The dogs of the friend eat.'),
    reason_translate('Maria da el libro a Omar.', B8),
    check('after an object: to Omar', B8, 'Maria gives the book to Omar.'),
    reason_translate('Maria ve a Omar hoy.', B9),
    check('the object, then an adverb', B9, 'Maria sees Omar today.'),
    reason_translate('Maria sees Omar.', S19), reason_translate(S19, E19),
    check('the round trip', E19, 'Maria sees Omar.').

%% ---- the future ------------------------------------------------------------------------

future :-
    section('the future: by the lesson''s ending rule, or stated; English''s will'),
    reason_translate('The dog will eat the bread.', F1),
    check('comerá by the rule: come ends in e and takes rá', F1, 'El perro comerá el pan.'),
    reason_translate('The dogs will not eat the bread.', F2),
    check('the plural of the future, stated, and denied', F2, 'Los perros no comerán el pan.'),
    reason_translate('The house will be big.', F3),
    check('will be: será, stated', F3, 'La casa será grande.'),
    reason_translate('The house will not be big.', F4),
    check('will not be', F4, 'La casa no será grande.'),
    reason_translate('I will eat the bread.', F5),
    check('the first person of the future form', F5, 'Yo comeré el pan.'),
    reason_translate('You will eat the bread.', F6),
    check('the second', F6, 'Tú comerás el pan.'),
    reason_translate('We will not eat.', F7),
    check('the first person of the plural future, denied', F7, 'Nosotros no comeremos.'),
    reason_translate('Will the dog eat the bread?', F8),
    check('will fronted', F8, '¿El perro comerá el pan?'),
    reason_translate('Will the house be big?', F9),
    check('will the house be', F9, '¿La casa será grande?'),
    reason_translate('What will the dog eat?', F10),
    check('what will', F10, '¿Qué comerá el perro?'),
    reason_translate('Who will eat the bread?', F11),
    check('who will', F11, '¿Quién comerá el pan?'),
    reason_translate('When will Maria eat?', F12),
    check('when will', F12, '¿Cuándo comerá Maria?'),
    reason_translate('El perro comerá el pan.', E1),
    check('back: a form the rule makes, read through the rule', E1, 'The dog will eat the bread.'),
    reason_translate('Los perros no comerán el pan.', E2),
    check('will not', E2, 'The dogs will not eat the bread.'),
    reason_translate('La casa será grande.', E3),
    check('will be', E3, 'The house will be big.'),
    reason_translate('Comeré el pan.', E4),
    check('comeré says I, in the future', E4, 'I will eat the bread.'),
    reason_translate('No comeremos.', E5),
    check('we will not', E5, 'We will not eat.'),
    reason_translate('¿Qué comerá el perro?', E6),
    check('what will', E6, 'What will the dog eat?'),
    reason_translate('¿Quién comerá el pan?', E7),
    check('who will', E7, 'Who will eat the bread?'),
    reason_translate('¿Cuándo comerá Maria?', E8),
    check('when will', E8, 'When will Maria eat?'),
    reason_translate('The house will be big.', S9), reason_translate(S9, E9),
    check('the round trip', E9, 'The house will be big.').

%% ---- the perfect --------------------------------------------------------------------------

perfect :-
    section('the perfect: the auxiliary the lesson names, in the subject''s person, and the participle'),
    reason_translate('The dog has eaten the bread.', H1),
    check('has eaten: ha, and the participle stated', H1, 'El perro ha comido el pan.'),
    reason_translate('The dogs have not eaten the bread.', H2),
    check('have not: the plural of the auxiliary', H2, 'Los perros no han comido el pan.'),
    reason_translate('I have eaten the bread.', H3),
    check('I have: the first person of the auxiliary', H3, 'Yo he comido el pan.'),
    reason_translate('We have eaten.', H4),
    check('we have', H4, 'Nosotros hemos comido.'),
    reason_translate('The dog had eaten the bread.', H5),
    check('had: the past of the auxiliary', H5, 'El perro había comido el pan.'),
    reason_translate('The house has not been big.', H6),
    check('has been: the participle of the copula', H6, 'La casa no ha sido grande.'),
    reason_translate('Has the dog eaten the bread?', H7),
    check('has fronted', H7, '¿El perro ha comido el pan?'),
    reason_translate('Has the house been big?', H8),
    check('has the house been', H8, '¿La casa ha sido grande?'),
    reason_translate('What has the dog eaten?', H9),
    check('what has', H9, '¿Qué ha comido el perro?'),
    reason_translate('Who has eaten the bread?', H10),
    check('who has', H10, '¿Quién ha comido el pan?'),
    reason_translate('Maria has eaten two eggs today.', H11),
    check('with a number and an adverb', H11, 'Maria ha comido dos huevos hoy.'),
    reason_translate('El perro ha comido el pan.', E1),
    check('back: has eaten, the participle stated for English', E1, 'The dog has eaten the bread.'),
    reason_translate('Los perros no han comido el pan.', E2),
    check('have not eaten', E2, 'The dogs have not eaten the bread.'),
    reason_translate('Yo he comido el pan.', E3),
    check('I have eaten', E3, 'I have eaten the bread.'),
    reason_translate('Hemos comido.', E4),
    check('hemos says we', E4, 'We have eaten.'),
    reason_translate('El perro había comido el pan.', E5),
    check('had eaten', E5, 'The dog had eaten the bread.'),
    reason_translate('Los perros no habían comido.', E6),
    check('had not eaten', E6, 'The dogs had not eaten.'),
    reason_translate('¿Ha comido el perro el pan?', E7),
    check('the auxiliary first, the subject after the participle', E7, 'Has the dog eaten the bread?'),
    reason_translate('¿Has comido el pan?', E8),
    check('has is the second person of ha: you', E8, 'Have you eaten the bread?'),
    reason_translate('¿Qué ha comido el perro?', E9),
    check('what has', E9, 'What has the dog eaten?'),
    reason_translate('¿Quién ha comido el pan?', E10),
    check('who has', E10, 'Who has eaten the bread?'),
    reason_translate('Maria has eaten two eggs today.', S11), reason_translate(S11, E11),
    check('the round trip', E11, 'Maria has eaten two eggs today.').

%% ---- phrases: prepositions, adverbs, numbers, two joined ----------------------------------

phrases :-
    section('prepositional phrases, adverbs, numbers, adjectives and two phrases joined'),
    reason_translate('Maria lives in Madrid.', R1),
    check('a preposition and a name', R1, 'Maria vive en Madrid.'),
    reason_translate('Maria gives the book to Omar.', R2),
    check('an object and then a phrase', R2, 'Maria da el libro a Omar.'),
    reason_translate('Maria eats the bread with Omar in the house.', R3),
    check('two phrases, in order', R3, 'Maria come el pan con Omar en la casa.'),
    reason_translate('Maria lives in a big city.', R4),
    check('a phrase with an article and an adjective, agreeing: ciudad is feminine, stated', R4, 'Maria vive en una ciudad grande.'),
    reason_translate('Maria eats the bread quickly.', R5),
    check('an adverb, last', R5, 'Maria come el pan rápidamente.'),
    reason_translate('Maria sings well.', R6),
    check('an adverb alone', R6, 'Maria canta bien.'),
    reason_translate('Maria has three dogs.', R7),
    check('a number, and the noun in the plural', R7, 'Maria tiene tres perros.'),
    reason_translate('The two dogs eat.', R8),
    check('an article and a number', R8, 'Los dos perros comen.'),
    reason_translate('Maria and Omar eat the bread.', R9),
    check('two subjects joined: plural', R9, 'Maria y Omar comen el pan.'),
    reason_translate('Maria eats the bread and the egg.', R10),
    check('two objects joined', R10, 'Maria come el pan y el huevo.'),
    reason_translate('Maria eats the bread and the milk.', R11),
    check('leche is feminine as stated, whatever the rule says', R11, 'Maria come el pan y la leche.'),
    reason_translate('The house is big and red.', R12),
    check('two adjectives joined, agreeing', R12, 'La casa es grande y roja.'),
    reason_translate('The red dog and the big cat eat.', R13),
    check('two phrases with adjectives, each after its noun', R13, 'El perro rojo y el gato grande comen.'),
    reason_translate('The big red house is small.', R14),
    check('two adjectives on one noun, both after it', R14, 'La casa grande roja es pequeña.'),
    reason_translate('The dogs of Maria eat.', R15),
    check('a phrase inside the subject', R15, 'Los perros de Maria comen.'),
    reason_translate('Maria eats bread.', R16),
    check('no article either side', R16, 'Maria come pan.'),
    reason_translate('They are our friends.', R17),
    check('a plural possessive, agreeing', R17, 'Ellos son nuestros amigos.'),
    reason_translate('Maria vive en Madrid.', E1),
    check('back: in Madrid', E1, 'Maria lives in Madrid.'),
    reason_translate('Maria da el libro a Omar.', E2),
    check('to Omar', E2, 'Maria gives the book to Omar.'),
    reason_translate('Maria come el pan con Omar en la casa.', E3),
    check('two phrases; la before casa is the article, not her', E3, 'Maria eats the bread with Omar in the house.'),
    reason_translate('Maria vive en la ciudad.', E4),
    check('in the city', E4, 'Maria lives in the city.'),
    reason_translate('Maria come el pan rápidamente.', E5),
    check('quickly', E5, 'Maria eats the bread quickly.'),
    reason_translate('Maria come el pan hoy.', E6),
    check('today', E6, 'Maria eats the bread today.'),
    reason_translate('Maria tiene tres perros.', E7),
    check('three dogs', E7, 'Maria has three dogs.'),
    reason_translate('Los dos perros comen.', E8),
    check('the two dogs', E8, 'The two dogs eat.'),
    reason_translate('Maria y Omar comen el pan.', E9),
    check('and', E9, 'Maria and Omar eat the bread.'),
    reason_translate('Maria come pan y huevos.', E10),
    check('two bare objects', E10, 'Maria eats bread and eggs.'),
    reason_translate('El perro rojo y el gato grande comen.', E11),
    check('each adjective back before its noun', E11, 'The red dog and the big cat eat.'),
    reason_translate('La casa grande roja es pequeña.', E12),
    check('two adjectives, in order', E12, 'The big red house is small.'),
    reason_translate('Los perros de Maria comen.', E13),
    check('of Maria', E13, 'The dogs of Maria eat.'),
    reason_translate('Maria le da el libro.', E14),
    check('a pronoun before the verb, then the object: him, then the book', E14, 'Maria gives him the book.'),
    reason_translate('Ellos son nuestros amigos.', E15),
    check('our friends', E15, 'They are our friends.'),
    reason_translate('Maria eats the bread with Omar in the house.', S16), reason_translate(S16, E16),
    check('the round trip', E16, 'Maria eats the bread with Omar in the house.').

%% ---- where, when, which ----------------------------------------------------------------

wh :-
    section('where, when and which: the lesson''s words for them'),
    reason_translate('Where does Maria live?', W1),
    check('where: dónde, the verb, the subject', W1, '¿Dónde vive Maria?'),
    reason_translate('When does Maria eat?', W2),
    check('when: cuándo', W2, '¿Cuándo come Maria?'),
    reason_translate('Where has Maria lived?', W3),
    check('where has', W3, '¿Dónde ha vivido Maria?'),
    reason_translate('Which dog eats the bread?', W4),
    check('which with its noun, asking for the subject', W4, '¿Qué perro come el pan?'),
    reason_translate('Which houses are big?', W5),
    check('the subject, plural', W5, '¿Qué casas son grandes?'),
    reason_translate('Which dog will eat the bread?', W6),
    check('the subject, with will', W6, '¿Qué perro comerá el pan?'),
    reason_translate('Which book does Maria read?', W7),
    check('which asking for the object: does, and the subject after it', W7, '¿Qué libro lee Maria?'),
    reason_translate('Which dog did Maria see?', W8),
    check('the object, in the past', W8, '¿Qué perro vio Maria?'),
    reason_translate('Does Maria live in Madrid?', W9),
    check('yes or no, with a phrase', W9, '¿Maria vive en Madrid?'),
    reason_translate('¿Dónde vive Maria?', E1),
    check('back: where does', E1, 'Where does Maria live?'),
    reason_translate('¿Cuándo come Maria?', E2),
    check('when does', E2, 'When does Maria eat?'),
    reason_translate('¿Dónde ha vivido Maria?', E3),
    check('where has', E3, 'Where has Maria lived?'),
    reason_translate('¿Qué perro come el pan?', E4),
    check('qué with a noun is which; the verb follows: the subject', E4, 'Which dog eats the bread?'),
    reason_translate('¿Qué perros comen el pan?', E5),
    check('which dogs', E5, 'Which dogs eat the bread?'),
    reason_translate('¿Qué libro lee Maria?', E6),
    check('a name alone after the verb: the object was asked', E6, 'Which book does Maria read?'),
    reason_translate('¿Qué perro vio Maria?', E7),
    check('which did', E7, 'Which dog did Maria see?'),
    reason_translate('¿Vive Maria en Madrid?', E8),
    check('the verb first, the name, the phrase', E8, 'Does Maria live in Madrid?'),
    reason_translate('Whom does Maria see?', W10),
    check('whom is who asked for as the object, and a person: the word before it', W10, '¿A quién ve Maria?'),
    reason_translate('Who sees Maria?', W11),
    check('who asks for the subject, and Maria is the object', W11, '¿Quién ve a Maria?'),
    reason_translate('Which friend does Maria see?', W12),
    check('which, with a person noun, asked for as the object', W12, '¿A qué amigo ve Maria?'),
    reason_translate('Whom has Maria seen?', W13),
    check('whom has', W13, '¿A quién ha visto Maria?'),
    reason_translate('¿A quién ve Maria?', E9),
    check('back: the word, then the question word: whom', E9, 'Whom does Maria see?'),
    reason_translate('¿Quién ve a Maria?', E10w),
    check('the question word alone: who', E10w, 'Who sees Maria?'),
    reason_translate('¿A qué amigo ve Maria?', E11),
    check('which friend', E11, 'Which friend does Maria see?'),
    reason_translate('¿A quién ha visto Maria?', E12),
    check('whom has', E12, 'Whom has Maria seen?'),
    reason_untranslated('Whom does Maria see?', U9),
    check('whom needs no word of the lesson''s: nothing is untranslated', U9, []),
    reason_translate('Which book does Maria read?', S10), reason_translate(S10, E10),
    check('the round trip', E10, 'Which book does Maria read?').

%% ---- a second lesson, under its own name ---------------------------------------------------

languages :-
    section('two lessons: one learned under a name shares nothing with the plain one, and the words say which'),
    reason_learn('Italian is a language. The noun "casa" means "house". The noun "cane" means "dog". The noun "pane" means "bread". The adjective "grande" means "big". The verb "è" means "is". The verb "mangia" means "eats". The feminine article "la" means "the". The masculine article "il" means "the". Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine. Every adjective follows the noun. "case" is the plural of "casa". "grandi" is the plural of "grande". "sono" is the plural of "è". "le" is the plural of "la". The word "non" means "not". The word "cosa" means "what".', italian, Ts),
    length(Ts, N1),
    check('eighteen lines, thirty terms', N1, 30),
    yes_no(reason_lesson(italian, mean(casa, house)), L2),
    check('held under the language: reason_lesson/2 answers for it', L2, yes),
    yes_no(reason_lesson(spanish, mean(casa, house)), L2b),
    check('and the plain lesson is not a named one', L2b, no),
    truth(plural_of(case, casa), T3),
    check('and not as a plain fact: the plain lesson knows no Italian', T3, unknown),
    reason_translate('La casa è grande.', E4),
    check('è is Italian''s alone: from Italian', E4, 'The house is big.'),
    reason_translate('Il cane mangia il pane.', E5),
    check('il, cane, mangia, pane', E5, 'The dog eats the bread.'),
    reason_translate('Le case non sono grandi.', E6),
    check('the Italian plurals, stated, and non', E6, 'The houses are not big.'),
    reason_translate('Cosa mangia il cane?', E7),
    check('a question in Italian', E7, 'What does the dog eat?'),
    reason_translate('El perro come el pan.', E8),
    check('and Spanish is still Spanish', E8, 'The dog eats the bread.'),
    yes_no(reason_translate('The house is big.', _), R9),
    check('English into which? both lessons fit equally: refused', R9, no),
    reason_untranslated('The house is big.', U9),
    check('and no word is untranslated', U9, []),
    reason_translate('The house is big.', italian, I10),
    check('reason_translate/3 names Italian', I10, 'La casa è grande.'),
    reason_translate('The house is big.', spanish, S10),
    check('or Spanish', S10, 'La casa es grande.'),
    reason_translate('The houses are big.', italian, I11),
    check('casa has a stated plural in one lesson and a ruled one in the other', I11, 'Le case sono grandi.'),
    reason_translate('The houses are big.', spanish, S11),
    check('the same word, the other lesson', S11, 'Las casas son grandes.'),
    reason_translate('The dog eats the bread.', italian, I12),
    check('il cane mangia il pane', I12, 'Il cane mangia il pane.'),
    reason_translate('The dog eats the bread and the milk.', S12),
    check('milk is Spanish''s alone: the words decide', S12, 'El perro come el pan y la leche.'),
    reason_unlearn(italian),
    yes_no(reason_lesson(italian, mean(casa, house)), L13a),
    check('reason_unlearn/1 takes the whole lesson out', L13a, no),
    reason_translate('The house is big.', S13),
    check('the Italian lesson forgotten: Spanish again', S13, 'La casa es grande.').

%% ---- the intermediate representation ---------------------------------------------------
%%
%% The Italian lesson again, beside the Spanish one this file opened
%% with: two languages in one process, each learned under its own name
%% (Spanish names itself, `Spanish is a language'). So Italian and
%% Spanish translate BETWEEN THEMSELVES here, through the IR, with no
%% English sentence written and none read -- which is the claim the IR
%% exists to make. The words are the ones both hand lessons happen to
%% give: casa, cane/perro, pane/pan, grande, è/es, mangia/come, the
%% articles, non/no and cosa/qué.

ir :-
    section('the IR: every language into it and out of it, and no pair with a path of its own'),
    reason_learn('Italian is a language. The noun "casa" means "house". The noun "cane" means "dog". The noun "pane" means "bread". The adjective "grande" means "big". The verb "è" means "is". The verb "mangia" means "eats". The feminine article "la" means "the". The masculine article "il" means "the". Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine. Every adjective follows the noun. "case" is the plural of "casa". "grandi" is the plural of "grande". "sono" is the plural of "è". "le" is the plural of "la". The word "non" means "not". The word "cosa" means "what".', italian, _),

    reason_languages(L1),
    check('english, the pivot, and each lesson: the plain one names itself', L1, [english, none, italian]),

    reason_ir('Il cane non mangia il pane.', italian, IR2),
    check('a sentence into the IR: the reader''s own shape, with English words in it', IR2,
          [ir(s(none,
                np(det(article, the, w(the, lower)), none, [], w(dog, lower), singular),
                g(eats, present, simple, yes),
                [obj(np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular))]),
             46)]),

    reason_ir('Il cane non mangia il pane.', italian, IR3),
    findall(O3, ( member(N3, [italian, english, spanish]), reason_ir_text(IR3, N3, O3) ), Os3),
    check('ONE IR, written into all three', Os3,
          ['Il cane non mangia il pane.', 'The dog does not eat the bread.', 'El perro no come el pan.']),

    reason_translate('Il cane mangia il pane.', italian, spanish, S4),
    check('Italian into Spanish', S4, 'El perro come el pan.'),
    reason_translate('La casa è grande.', italian, spanish, S5),
    check('the copula, and the gender rule of the other lesson', S5, 'La casa es grande.'),
    reason_translate('Le case non sono grandi.', italian, spanish, S6),
    check('a stated plural one side, a ruled one the other', S6, 'Las casas no son grandes.'),
    reason_translate('Cosa mangia il cane?', italian, spanish, S7),
    check('a question, with the mark the other lesson begins one with', S7, '¿Qué come el perro?'),

    reason_translate('El perro come el pan.', spanish, italian, I8),
    check('and the other way, which is the same two halves', I8, 'Il cane mangia il pane.'),
    reason_translate('Las casas no son grandes.', spanish, italian, I9),
    check('the plurals back', I9, 'Le case non sono grandi.'),
    reason_translate('¿Qué come el perro?', spanish, italian, I10),
    check('the question back, and Italian begins one with nothing', I10, 'Cosa mangia il cane?'),

    reason_translate('The dog eats the bread.', english, italian, I11),
    check('english is a language like any other into the IR', I11, 'Il cane mangia il pane.'),
    reason_translate('Il cane mangia il pane.', italian, english, E12),
    check('and out of it', E12, 'The dog eats the bread.'),
    reason_translate('The dog eats the bread.', english, english, E13),
    check('english to english: the IR is already English, so this is a round trip', E13, 'The dog eats the bread.'),

    reason_translate_page('Il cane mangia il pane. Il cane mangia la xyzzy.', italian, spanish, P14),
    check('a page between two languages: one refused names its word', P14,
          ['Il cane mangia il pane.'-'El perro come el pan.',
           'Il cane mangia la xyzzy.'-refused([xyzzy])]),

    yes_no(reason_translate('Il cane mangia il pane.', italian, klingon, _), R15),
    check('a language no lesson teaches is a domain_error, not a failure', R15,
          error(error(domain_error(language, klingon), reason_translate/3))),

    reason_ir('Il cane mangia il pane. Le case sono grandi.', italian, IR16),
    length(IR16, N16),
    check('a text is read once, sentence by sentence', N16, 2),
    reason_ir_text(IR16, spanish, S16),
    check('and written as many times as there are languages', S16, 'El perro come el pan. Las casas son grandes.'),

    reason_unlearn(italian).

%% ---- the elision and the impersonal ------------------------------------------------
%% Both are lesson shapes that were already there: `"l'" is the elision of
%% "lo"' is `is the NOUN of X' and `The impersonal pronoun "si" means "one"'
%% is the apposition. What had to move was the TOKENISER, which cut
%% `l'amico' at the apostrophe and left an `l' no lesson could give a
%% meaning, and the subject reader, which refused a third person singular
%% with nobody in front of it -- rightly, until the impersonal word IS the
%% something that says who.

elision :-
    section('the elision and the impersonal pronoun: an apostrophe is part of the word before it'),
    reason_learn('Italian is a language. The noun "amico" means "friend". The noun "cane" means "dog". The verb "è" means "is". The adjective "grande" means "big". Every adjective follows the noun. The noun "pane" means "bread". The verb "mangia" means "eats". The feminine article "la" means "the". The masculine article "il" means "the". The masculine article "lo" means "the". Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine. The word "non" means "not". The word "non" precedes the verb. The preposition "di" means "of". "del" is the contraction of "di il". "l''" is the elision of "il". "l''" is the elision of "lo". "l''" is the elision of "la". "dell''" is the elision of "del". The impersonal pronoun "si" means "one".', italian, _),

    reason_tokens('l''incolumita del presidente.', T1),
    check('the apostrophe ENDS the word and stays with it: two words, not `l'' and a noun', T1,
          [word('l''', lower), word(incolumita, lower), word(del, lower), word(presidente, lower), '.']),

    reason_tokens('a b’c', T2),
    check('the typographic apostrophe is written as the plain one, so a lesson spells the form once', T2,
          [word(a, lower), word('b''', lower), word(c, lower)]),

    reason_tokens('un po'' di pane', T3),
    check('and an apostrophe with no letter after it is punctuation as before', T3,
          [word(un, lower), word(po, lower), word(di, lower), word(pane, lower)]),

    reason_translate('L''amico mangia il pane.', italian, english, S4),
    check('an elided article READS as what it elides', S4, 'The friend eats the bread.'),

    reason_translate('The friend eats the bread.', english, italian, S5),
    check('and is WRITTEN before a vowel, joined to the word after it', S5, 'L''amico mangia il pane.'),

    reason_translate('The dog eats the bread.', english, italian, S6),
    check('a consonant still takes the plain form', S6, 'Il cane mangia il pane.'),

    reason_translate('Il pane dell''amico è grande.', italian, english, S7),
    check('an elided CONTRACTION is un-elided and then read as its two words', S7,
          'The bread of the friend is big.'),

    reason_translate('Si mangia il pane.', italian, english, S8),
    check('the impersonal pronoun is a subject naming nobody: English says `one''', S8,
          'One eats the bread.'),

    reason_translate('One eats the bread.', english, italian, S9),
    check('and English''s `one'' comes back as the lesson''s own word', S9, 'Si mangia il pane.'),

    reason_translate('Non si mangia il pane.', italian, english, S10),
    check('denied, and the verb stays third person singular', S10, 'One does not eat the bread.'),

    reason_ir('Si mangia il pane.', italian, IR11),
    check('what the IR carries is the subject `impersonal'', not a word of any language', IR11,
          [ir(s(none, impersonal, g(eats, present, simple, no),
                [obj(np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular))]),
              46)]),

    yes_no(reason_translate('Mangia il pane.', italian, english, _), R12),
    check('a third person singular with NOBODY in front of it is still refused: it could be anybody', R12, no),

    reason_unlearn(italian).

%% ---- several clauses in one sentence ------------------------------------------------
%% The comma was DROPPED in tr_words/2 before anything could see it, and
%% tr_split/2 divides a text on `.', `!' and `?' alone -- so one piece was
%% one clause by construction, and half the newspaper sample could not begin
%% to parse. The whole piece is still tried as one statement first, so every
%% sentence that read before reads by the same clauses.

clauses :-
    section('several clauses in one sentence: a comma or a connecting word divides them'),
    reason_learn('Italian is a language. The noun "cane" means "dog". The noun "gatto" means "cat". The noun "pane" means "bread". The verb "vede" means "sees". The verb "mangia" means "eats". The masculine article "il" means "the". Every noun that does not end in "a" is masculine. The conjunction "e" means "and". The word "non" means "not". The word "non" precedes the verb. "mangiano" is the plural of "mangia". "vedono" is the plural of "vede".', italian, _),

    reason_translate('Il cane vede il gatto e il cane mangia il pane.', italian, english, C1),
    check('two clauses joined by a connecting word, into English', C1,
          'The dog sees the cat and the dog eats the bread.'),

    reason_translate('Il cane vede il gatto e il cane mangia il pane.', italian, spanish, C2),
    check('and into a third language, with no English written', C2,
          'El perro ve el gato y el perro come el pan.'),

    reason_translate('The dog sees the cat and the dog eats the bread.', english, italian, C3),
    check('and back, which is the same two halves the other way', C3,
          'Il cane vede il gatto e il cane mangia il pane.'),

    reason_translate('Il cane mangia il pane, il gatto mangia il pane.', italian, english, C4),
    check('a bare COMMA divides two clauses, and is written with no space before it', C4,
          'The dog eats the bread, the cat eats the bread.'),

    reason_ir('Il cane vede il gatto e il cane mangia il pane.', italian, C5),
    check('what the IR carries is join(Connector, S1, S2), the connector an ENGLISH word', C5,
          [ir(join(w(and, lower),
                   s(none, np(det(article, the, w(the, lower)), none, [], w(dog, lower), singular),
                     g(sees, present, simple, no),
                     [obj(np(det(article, the, w(the, lower)), none, [], w(cat, lower), singular))]),
                   s(none, np(det(article, the, w(the, lower)), none, [], w(dog, lower), singular),
                     g(eats, present, simple, no),
                     [obj(np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular))])),
              46)]),

    reason_translate('Il cane non mangia il pane e il gatto mangia il pane.', italian, english, C6),
    check('each clause carries its own denial', C6,
          'The dog does not eat the bread and the cat eats the bread.'),

    reason_translate('Il cane e il gatto mangiano il pane.', italian, english, C7),
    check('A CONJUNCTION INSIDE A SUBJECT IS NOT A DIVISION: neither side is a clause', C7,
          'The dog and the cat eat the bread.'),

    reason_unlearn(italian).

%% ---- the passive ---------------------------------------------------------------------
%% The copula and a participle. WHAT TELLS A PASSIVE FROM A PERFECT IS THE
%% LESSON: Italian builds the perfect of some verbs with the copula too (`e
%% riuscito' is `has succeeded'), and nothing a lesson says tells which verbs
%% those are -- so the perfect reading fires only for a word the lesson calls
%% an AUXILIARY, and the copula falls through to the passive.

passive :-
    section('the passive: the copula and a participle, and the participle agrees'),
    reason_learn('Italian is a language.
The noun "casa" means "house". The noun "pane" means "bread". The noun "soldati" means "soldiers".
The masculine article "il" means "the". The feminine article "la" means "the". The masculine article "i" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "è" means "is". "sono" is the plural of "è".
"stato" is the participle of "è". "stata" is the participle of "è". "stata" is feminine.
The verb "getta" means "throws". "gettato" is the participle of "getta". "gettata" is the participle of "getta". "gettata" is feminine.
The verb "considera" means "considers". "considerato" is the participle of "considera". "considerata" is the participle of "considera". "considerata" is feminine.
The preposition "da" means "by". The preposition "in" means "in".
The word "non" means "not". The word "non" precedes the verb.', italian, _),
    reason_learn('Spanish is a language.
The noun "casa" means "house". The feminine article "la" means "the". "las" is the plural of "la".
"casas" is the plural of "casa".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "es" means "is". "son" is the plural of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha".
"ha" is the auxiliary of "es".
"sido" is the participle of "es".
The verb "arroja" means "throws".
"arrojado" is the participle of "arroja". "arrojada" is the participle of "arroja". "arrojada" is feminine.
"arrojadas" is the participle of "arroja". "arrojadas" is feminine. "arrojadas" is the plural of "arrojada".', spanish, _),

    reason_translate('La casa è considerata.', italian, english, V1),
    check('the copula and a participle is a passive', V1, 'The house is considered.'),

    reason_translate('The house is considered.', english, italian, V2),
    check('and back, THE PARTICIPLE AGREEING with a feminine subject', V2, 'La casa è considerata.'),

    reason_translate('Il pane è considerato.', italian, english, V3),
    check('a masculine subject takes the other form, which is what the four participle rows are for', V3,
          'The bread is considered.'),

    reason_translate('La casa è stata gettata.', italian, english, V4),
    check('the PERFECT passive: the copula, its own participle, and the verb''s', V4,
          'The house has been throwed.'),

    reason_translate('Il pane è considerato da i soldati.', italian, english, V5),
    check('THE AGENT IS NOT AN ADJUNCT: it travels as by/1 and writes with the target''s word for `by''', V5,
          'The bread is considered by the soldiers.'),

    reason_translate('La casa non è considerata.', italian, english, V6),
    check('denied', V6, 'The house is not considered.'),

    reason_ir('La casa è stata gettata.', italian, V7),
    check('what the IR carries is the ASPECT, passive_perfect, and no word of any language', V7,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(house, lower), singular),
                g(throws, present, passive_perfect, no), []), 46)]),

    %% WHICH WORD CARRIES THE TENSE IN A PASSIVE PERFECT IS THE LESSON'S.
    %% Italian builds the copula's perfect with the copula and Spanish with
    %% the auxiliary, so the Spanish lesson says `"ha" is the auxiliary of
    %% "es"' and the Italian one says nothing, the copula being the default.
    %% Before 1.6.8 both sides took the copula: Spanish WROTE `es sido
    %% evacuada' and REFUSED `ha sido evacuada', which is the worse half.
    reason_translate('La casa è stata gettata.', italian, spanish, V8),
    check('the Spanish passive perfect is the AUXILIARY, never the copula', V8,
          'La casa ha sido arrojada.'),

    reason_translate('La casa ha sido arrojada.', spanish, italian, V9),
    check('and it reads back, where a perfect reading would leave the participle over', V9,
          'La casa è stata gettata.'),

    reason_translate('Las casas han sido arrojadas.', spanish, english, V10),
    check('the plural, the auxiliary agreeing and the participle after it not', V10,
          'The houses have been throwed.'),

    reason_translate('Las casas han sido arrojadas.', spanish, spanish, V11),
    check('and back as itself', V11, 'Las casas han sido arrojadas.'),

    reason_translate('La casa è stata gettata.', italian, italian, V12),
    check('ITALIAN IS UNTOUCHED: no lesson line, so the copula carries it', V12,
          'La casa è stata gettata.'),

    reason_unlearn(italian), reason_unlearn(spanish).

%% ---- the reflexive -------------------------------------------------------------------
%% A REFLEXIVE PRONOUN BELONGS TO THE VERB, so the IR wraps the lexeme --
%% g(reflexive(L), T, A, Neg) -- and a language with a reflexive pronoun
%% writes it back where English, which has none there, drops it.
%%
%% THE COST IS A TRUE REFLEXIVE: `si lava' is `washes himself' and comes out
%% `washes'. Italian spells a lexical reflexive and a true one the same way
%% and nothing in a lesson tells them apart; the lexical one is what
%% newspaper prose is made of, so that is the reading taken.

reflexive :-
    section('the reflexive: it belongs to the verb, and `si'' is the impersonal word too'),
    reason_learn('Italian is a language.
The noun "casa" means "house". The masculine article "il" means "the". The feminine article "la" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "è" means "is". "stata" is the participle of "è". "stata" is feminine.
The verb "adegua" means "adapts". "adeguato" is the participle of "adegua". "adeguata" is the participle of "adegua". "adeguata" is feminine.
The reflexive pronoun "si" means "itself".
The impersonal pronoun "si" means "one".
The word "non" means "not". The word "non" precedes the verb.
Every pronoun precedes the verb.', italian, _),

    reason_translate('La casa si adegua.', italian, english, X1),
    check('the reflexive comes off the clitics and English drops it', X1, 'The house adapts.'),

    reason_translate('La casa non si adegua.', italian, english, X2),
    check('denied', X2, 'The house does not adapt.'),

    reason_translate('La casa si è adeguata.', italian, english, X3),
    check('and with the copula and a participle after it', X3, 'The house is adapted.'),

    reason_translate('Si adegua.', italian, english, X4),
    check('THE SAME WORD, the IMPERSONAL reading: nothing before the verb but itself', X4,
          'One adapts.'),

    reason_ir('La casa si adegua.', italian, X5),
    check('what the IR carries is the LEXEME wrapped, not a pronoun among the complements', X5,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(house, lower), singular),
                g(reflexive(adapts), present, simple, no), []), 46)]),

    reason_ir('Si adegua.', italian, X6),
    check('where the impersonal is a SUBJECT and the verb is bare', X6,
          [ir(s(none, impersonal, g(adapts, present, simple, no), []), 46)]),

    reason_translate('La casa si adegua.', italian, italian, X7),
    check('and the pronoun is written back into a language that has one', X7, 'La casa si adegua.'),

    reason_unlearn(italian).

%% ---- the reduced relative -------------------------------------------------------------
%% `il coprifuoco imposto dai soldati' is the curfew THAT WAS imposed by the
%% soldiers: a passive relative clause with the copula and the pronoun left
%% out. Both the lesson's languages and English put it after the noun, which
%% is why ONE shape -- rel(NP, Lexeme, Comps) -- writes into all three.

reduced :-
    section('the reduced relative: a participle after the noun, and its agent'),
    reason_learn('Italian is a language.
The noun "casa" means "house". The noun "pane" means "bread". The noun "soldato" means "soldier". "soldati" is the plural of "soldato".
The masculine article "il" means "the". The feminine article "la" means "the". The masculine article "i" means "the". "i" is the plural of "il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "impone" means "imposes".
"imposto" is the participle of "impone". "imposta" is the participle of "impone". "imposta" is feminine.
The verb "domina" means "dominates".
The adjective "grande" means "big".
The preposition "da" means "by".
Every adjective follows the noun.', italian, _),

    %% (English puts a bare participle BEFORE its noun since 1.8.2; this
    %% pinned `The house imposed dominates.', and both are read)
    reason_translate('La casa imposta domina.', italian, english, D1),
    check('a participle after the noun is a reduced relative, before the noun in English', D1, 'The imposed house dominates.'),

    reason_translate('The imposed house dominates.', english, italian, D1b),
    check('and English reads it there', D1b, 'La casa imposta domina.'),

    reason_translate('The house imposed dominates.', english, italian, D2),
    check('and back, THE PARTICIPLE AGREEING with its own noun', D2, 'La casa imposta domina.'),

    reason_translate('Il pane imposto domina.', italian, english, D3),
    check('a masculine noun takes the other form', D3, 'The imposed bread dominates.'),

    reason_translate('La casa imposta da i soldati domina.', italian, english, D4),
    check('with its AGENT, which stays inside the phrase rather than hanging on the sentence''s verb', D4,
          'The house imposed by the soldiers dominates.'),

    reason_translate('The house imposed by the soldiers dominates.', english, italian, D5),
    check('and back whole', D5, 'La casa imposta da i soldati domina.'),

    reason_translate('La casa grande domina.', italian, english, D6),
    check('a plain phrase with an adjective is untouched', D6, 'The big house dominates.'),

    reason_ir('La casa imposta da i soldati domina.', italian, D7),
    check('what the IR carries is rel(Phrase, Lexeme, Comps), the lexeme ENGLISH and the form not in it', D7,
          [ir(s(none,
                rel(np(det(article, the, w(the, lower)), none, [], w(house, lower), singular),
                    imposes,
                    [by(np(det(article, the, w(the, lower)), none, [], w(soldier, lower), plural))]),
                g(dominates, present, simple, no), []), 46)]),

    reason_unlearn(italian).

%% ---- the purpose clause ---------------------------------------------------------------
%% `per definire' is `to define', `para definir'. The lesson names the word
%% -- `The word "per" begins the purpose.' -- which is the shape `The mark
%% "¿" begins the question' already uses, so no grammar moved for it.
%%
%% ENGLISH LOSES THE DISTINCTION AND THAT IS ENGLISH'S DOING: `wants to eat'
%% and `came to eat' are the same three words. So English writes a purpose
%% exactly as it writes a plain infinitive, and Italian into English and back
%% loses the mark where Italian into Spanish keeps it.

purpose :-
    section('the purpose clause: an infinitive with a word in front of it'),
    reason_learn('Italian is a language.
The noun "casa" means "house". The masculine article "il" means "the". The feminine article "la" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "arriva" means "arrives". The verb "mangia" means "eats". The verb "vuole" means "wants".
"mangiare" is the infinitive of "mangia".
The word "per" begins the purpose. The preposition "per" means "for".', italian, _),
    reason_learn('Spanish is a language.
The noun "casa" means "house". The masculine article "el" means "the". The feminine article "la" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "llega" means "arrives". The verb "come" means "eats".
"comer" is the infinitive of "come".
The word "para" begins the purpose.', spanish, _),

    reason_translate('La casa arriva per mangiare.', italian, english, U1),
    check('a purpose into English, which spells it as any infinitive', U1, 'The house arrives to eat.'),

    reason_translate('La casa arriva per mangiare.', italian, spanish, U2),
    check('and into a language that MARKS it, with its own word written back', U2,
          'La casa llega para comer.'),

    reason_translate('La casa vuole mangiare.', italian, english, U3),
    check('a plain infinitive is still a plain infinitive', U3, 'The house wants to eat.'),

    reason_ir('La casa arriva per mangiare.', italian, U4),
    check('the IR tells them apart: purpose/1', U4,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(house, lower), singular),
                g(arrives, present, simple, no), [purpose(eats)]), 46)]),

    reason_ir('La casa vuole mangiare.', italian, U5),
    check('where a complement infinitive is inf/1', U5,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(house, lower), singular),
                g(wants, present, simple, no), [inf(eats)]), 46)]),

    reason_unlearn(italian), reason_unlearn(spanish).

%% ---- the object complement ---------------------------------------------------------
%% `definire illegale la decisione' is what the verb predicates OF its
%% object, and the two sides put it in opposite places: the lesson's
%% language before the object, English after it. It travels as
%% oc(Object, Adjectives) and the adjectives agree with the OBJECT.
%%
%% WHAT TELLS IT FROM AN ORDINARY OBJECT IS NOT THE SAME THING EITHER SIDE.
%% In English it is the position, because an attributive adjective goes
%% before its noun. In the lesson's language an adjective before its noun is
%% ordinary (`buono pane'), so the tell is the DETERMINER after the
%% adjectives.

complement :-
    section('the object complement: what the verb predicates of its object'),
    reason_learn('Italian is a language.
The noun "casa" means "house". The noun "pane" means "bread".
The masculine article "il" means "the". The feminine article "la" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The masculine adjective "rosso" means "red". The feminine adjective "rossa" means "red".
The adjective "illegale" means "illegal". The adjective "buono" means "good". The adjective "grande" means "big".
The verb "definisce" means "defines". The verb "mangia" means "eats". The verb "è" means "is".
"definire" is the infinitive of "definisce". The word "per" begins the purpose. The preposition "per" means "for".
The conjunction "e" means "and".
Every adjective follows the noun.', italian, _),
    reason_learn('Spanish is a language.
The noun "casa" means "house". The noun "pan" means "bread".
The masculine article "el" means "the". The feminine article "la" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The masculine adjective "rojo" means "red". The feminine adjective "roja" means "red".
The adjective "ilegal" means "illegal". The adjective "bueno" means "good". The adjective "grande" means "big".
The verb "define" means "defines". The verb "come" means "eats". The verb "es" means "is".
"definir" is the infinitive of "define". The word "para" begins the purpose. The preposition "para" means "for".
The conjunction "y" means "and".
Every adjective follows the noun.', spanish, _),

    reason_translate('Il pane definisce rossa la casa.', italian, english, C1),
    check('the complement goes AFTER the object in English', C1, 'The bread defines the house red.'),

    reason_translate('Il pane definisce rossa la casa.', italian, spanish, C2),
    check('and before it in a language that puts it there', C2, 'El pan define roja la casa.'),

    reason_translate('The bread defines the house red.', english, italian, C3),
    check('and English read back the other way', C3, 'Il pane definisce rossa la casa.'),

    reason_translate('La casa definisce rosso il pane.', italian, spanish, C3b),
    check('the mirror: ROJO with a feminine subject, because it agrees with the OBJECT', C3b,
          'La casa define rojo el pan.'),

    reason_ir('Il pane definisce rossa la casa.', italian, C4),
    check('the IR is oc(Object, Adjectives), the object a phrase of its own', C4,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular),
                g(defines, present, simple, no),
                [oc(np(det(article, the, w(the, lower)), none, [], w(house, lower), singular),
                    [w(red, lower)])]), 46)]),

    reason_translate('Il pane mangia buono pane.', italian, english, C5),
    check('an adjective before a BARE noun is the phrase''s own, not a complement', C5,
          'The bread eats good bread.'),

    %% pre/1 since the Spanish article: the adjective stands BEFORE a noun
    %% where the lesson's rule puts it after, and a writer into a language
    %% with the same rule keeps it there (`una paradossale educazione')
    reason_ir('Il pane mangia buono pane.', italian, C6),
    check('and the IR says so: obj/1 with the adjective inside the phrase, marked as placed before its noun', C6,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular),
                g(eats, present, simple, no),
                [obj(np(none, none, [pre(w(good, lower))], w(bread, lower), singular))]), 46)]),

    reason_ir('La casa è rossa.', italian, C7),
    check('a copula''s own predicate is adj/1 still: the object must be an object', C7,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(house, lower), singular),
                g(is, present, simple, no), [adj([w(red, lower)])]), 46)]),

    reason_translate('La casa mangia il pane rosso.', italian, spanish, C8),
    check('an adjective after its noun inside the phrase is untouched', C8, 'La casa come el pan rojo.'),

    reason_translate('La casa definisce "illegale" il pane.', italian, spanish, C9),
    check('a quoted adjective, as the sample writes it: the marks travel with the word', C9,
          'La casa define "ilegal" el pan.'),

    reason_translate('Il pane definisce rossa e grande la casa.', italian, english, C10),
    check('two adjectives joined, both agreeing with the object', C10,
          'The bread defines the house red and big.'),

    reason_translate('Il pane definisce rossa e grande la casa.', italian, spanish, C11),
    check('and into Spanish with its own word for and', C11, 'El pan define roja y grande la casa.'),

    reason_translate('La casa mangia il pane per definire rossa la casa.', italian, english, C12),
    check('THE SAMPLE''S OWN SHAPE: an object already read, and the purpose infinitive with a complement of its own',
          C12, 'The house eats the bread to define the house red.'),

    reason_translate('La casa mangia il pane per definire rossa la casa.', italian, spanish, C13),
    check('and into Spanish, where the complement stays before its object', C13,
          'La casa come el pan para definir roja la casa.'),

    reason_unlearn(italian), reason_unlearn(spanish).

%% ---- the superlative ---------------------------------------------------------------
%% `il paese più ricco' is the richest country and `un paese più ricco' a
%% richer one: the lesson's language spells the two degrees with ONE word,
%% which it names (`The word "più" begins the comparative.'), and what
%% tells them apart is the ARTICLE. English marks the degree on the
%% adjective, so the IR carries deg(Degree, Word) and the degree is what
%% English needs; the foreign writer spells both the same.

superlative :-
    section('the superlative: one word in the lesson''s language, an ending in English'),
    reason_learn('Italian is a language.
The noun "paese" means "country". The noun "mondo" means "world". The noun "generale" means "general".
"paesi" is the plural of "paese".
The masculine article "il" means "the". The feminine article "la" means "the". The masculine article "un" means "a".
"i" is the plural of "il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The masculine adjective "ricco" means "rich". "ricchi" is the plural of "ricco".
The adjective "felice" means "happy".
The masculine adjective "costoso" means "expensive".
The verb "domina" means "dominates". The verb "definisce" means "defines". The verb "è" means "is".
"dominano" is the plural of "domina".
The preposition "di" means "of". "del" is the contraction of "di il". "dei" is the contraction of "di i".
The word "più" begins the comparative. The adverb "più" means "more".
The pronoun "uno" means "one".
Every adjective follows the noun.', italian, _),
    reason_learn('Spanish is a language.
The noun "pais" means "country". The noun "mundo" means "world". The noun "general" means "general".
"paises" is the plural of "pais".
The masculine article "el" means "the". The feminine article "la" means "the". The masculine article "un" means "a".
"los" is the plural of "el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The masculine adjective "rico" means "rich". "ricos" is the plural of "rico".
The adjective "feliz" means "happy".
The masculine adjective "costoso" means "expensive".
The verb "domina" means "dominates". The verb "define" means "defines". The verb "es" means "is".
"dominan" is the plural of "domina".
The preposition "de" means "of". "del" is the contraction of "de el".
The word "más" begins the comparative. The adverb "más" means "more".
The pronoun "uno" means "one".
Every adjective follows the noun.', spanish, _),

    reason_translate('Il paese più ricco domina.', italian, english, G1),
    check('the definite article makes it the SUPERLATIVE, and English spells it', G1,
          'The richest country dominates.'),

    reason_translate('Il paese più ricco domina.', italian, spanish, G2),
    check('and a language that marks it with a word writes its own', G2, 'El pais más rico domina.'),

    reason_translate('Un paese più ricco domina.', italian, english, G3),
    check('the INDEFINITE article makes the same word a comparative', G3, 'A richer country dominates.'),

    reason_ir('Il paese più ricco domina.', italian, G4),
    check('the IR carries deg(Degree, Word) among the adjectives', G4,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [deg(superlative, w(rich, lower))],
                         w(country, lower), singular),
                g(dominates, present, simple, no), []), 46)]),

    reason_translate('Il paese è più ricco.', italian, english, G5),
    check('a bare predicate has no article, so it is the comparative', G5, 'The country is richer.'),

    reason_ir('Il paese è più ricco.', italian, G6),
    check('and the IR says so', G6,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(country, lower), singular),
                g(is, present, simple, no), [adj([deg(comparative, w(rich, lower))])]), 46)]),

    reason_translate('The richest country dominates.', english, italian, G7),
    check('English read back the other way: the ending becomes the word', G7,
          'Il paese più ricco domina.'),

    reason_translate('A more rich country dominates.', english, english, G8),
    check('`more rich'' is READ and written as `richer'': both forms in, one out', G8,
          'A richer country dominates.'),

    reason_translate('Il paese più costoso domina.', italian, english, G9),
    check('a word English gives no ending to takes `most''', G9,
          'The most expensive country dominates.'),

    reason_translate('Il paese è più felice.', italian, english, G10),
    check('and a two-syllable word ending in `y'' takes the ending', G10, 'The country is happier.'),

    reason_translate('Il paese ricco domina.', italian, english, G11),
    check('an adjective with no degree word is untouched', G11, 'The rich country dominates.'),

    reason_translate('I paesi più ricchi dominano.', italian, english, G12),
    check('the plural, where the adjective agrees and the degree does not', G12,
          'The richest countries dominate.'),

    reason_translate('Il generale definisce uno dei paesi più ricchi del mondo.', italian, english, G13),
    check('THE SAMPLE''S OWN PHRASE: one of the richest countries of the world', G13,
          'The general defines one of the richest countries of the world.'),

    reason_translate('Il generale definisce uno dei paesi più ricchi del mondo.', italian, spanish, G14),
    check('and into Spanish, where the partitive is the same shape', G14,
          'El general define uno de los paises más ricos del mundo.'),

    reason_unlearn(italian), reason_unlearn(spanish).

% ---- inversion ----------------------------------------------------------------------
% `Qui dominava il generale' is the general dominating, with the subject
% AFTER the verb, and what says so is the adjunct fronted before it. A
% fronted adjunct makes inversion possible and never certain -- `Ieri
% mangiava il pane' is pro-drop with an object -- so the lesson says which
% verbs take no object: `"domina" is intransitive.'

inversion :-
    section('inversion: a fronted adjunct puts the subject after the verb'),
    reason_learn('Italian is a language.
The noun "paese" means "country". The noun "generale" means "general". The noun "pane" means "bread". The noun "casa" means "house".
The masculine article "il" means "the". The feminine article "la" means "the".
"le" is the plural of "la". "case" is the plural of "casa".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "domina" means "dominates". The verb "mangia" means "eats". The verb "è" means "is".
"dominava" is the past of "domina". "mangiava" is the past of "mangia".
"sono" is the plural of "è".
"domina" is intransitive.
The adverb "qui" means "here". The adverb "ieri" means "yesterday".
The preposition "in" means "in".
Every adjective follows the noun.', italian, _),
    reason_learn('Spanish is a language.
The noun "pais" means "country". The noun "general" means "general". The noun "pan" means "bread". The noun "casa" means "house".
The masculine article "el" means "the". The feminine article "la" means "the".
"las" is the plural of "la". "casas" is the plural of "casa".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "domina" means "dominates". The verb "come" means "eats". The verb "es" means "is".
"dominaba" is the past of "domina". "comia" is the past of "come".
"son" is the plural of "es".
"domina" is intransitive.
The adverb "aqui" means "here". The adverb "ayer" means "yesterday".
The preposition "en" means "in".
Every adjective follows the noun.', spanish, _),

    %% 1.8.10: an ADVERB alone in front is written back in front, where the
    %% subject stays after the verb -- these four pinned the statement's
    %% order, `The general dominated here', `Il generale dominava qui', until
    %% the Bosnian letter's `Forse è venuto il momento di porsi ...' needed
    %% the reader that keeps the subject in its place; a PHRASE in front is
    %% still read into the statement's order (below)
    reason_translate('Qui dominava il generale.', italian, english, V1),
    check('the adverb is fronted and the subject follows the verb', V1,
          'Here the general dominated.'),

    reason_translate('Qui dominava il generale.', italian, spanish, V2),
    check('and into Spanish', V2, 'Aqui dominaba el general.'),

    reason_ir('Qui dominava il generale.', italian, V3),
    check('the IR keeps the adverb in front and the subject''s place after the verb', V3,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(general, lower), singular),
                g(dominates, past, simple, no), [frn(adv(w(here, lower))), subj_here]), 46)]),

    reason_translate('Qui dominava il generale.', italian, italian, V4),
    check('AN ADVERB IN FRONT IS WRITTEN BACK THERE: the source''s own order', V4,
          'Qui dominava il generale.'),

    %% 1.8.0: an intransitive verb takes no object, so the phrase after it is
    %% its subject with nothing fronted too -- `le gusta el buen fútbol' --
    %% and its place is kept; this pinned an object of an intransitive verb
    reason_ir('Dominava il generale.', italian, V5),
    check('AN INTRANSITIVE VERB TAKES NO OBJECT: nothing fronted, and the phrase after it is still its subject', V5,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(general, lower), singular),
                g(dominates, past, simple, no), [subj_here]), 46)]),

    reason_ir('Ieri mangiava il pane.', italian, V6),
    check('and a verb no lesson calls intransitive keeps the phrase after it as its object', V6,
          [ir(s(none, null(third, singular), g(eats, past, simple, no),
                [obj(np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular)),
                 adv(w(yesterday, lower))]), 46)]),

    reason_translate('In la casa dominava il generale.', italian, english, V7),
    check('a prepositional phrase fronts it too', V7, 'The general dominated in the house.'),

    reason_translate('Il generale dominava.', italian, english, V8),
    check('a subject before the verb is untouched', V8, 'The general dominated.'),

    reason_unlearn(italian), reason_unlearn(spanish).

% ---- the headline participle --------------------------------------------------------
% `Evacuata la Tate Gallery.' is `La Tate Gallery e stata evacuata' with
% the copula dropped, so it reads as the PASSIVE it is and the IR carries
% an ordinary statement. There is no fragment in the grammar and this
% shape needed none.

headline :-
    section('the headline participle: the copula dropped, and it is not a fragment'),
    reason_learn('Italian is a language.
The noun "casa" means "house".
The feminine article "la" means "the". "le" is the plural of "la". "case" is the plural of "casa".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "evacua" means "evacuates". The verb "è" means "is". "sono" is the plural of "è".
"evacuato" is the participle of "evacua". "evacuata" is the participle of "evacua". "evacuata" is feminine.
"evacuate" is the participle of "evacua". "evacuate" is feminine. "evacuati" is the participle of "evacua".
"evacuate" is the plural of "evacuata". "evacuati" is the plural of "evacuato".
"stato" is the participle of "è". "stata" is the participle of "è". "stata" is feminine.
"state" is the participle of "è". "state" is feminine. "stati" is the participle of "è".
"state" is the plural of "stata". "stati" is the plural of "stato".
Every adjective follows the noun.', italian, _),

    reason_translate('Evacuata la casa.', italian, english, H1),
    check('a participle at the head is a passive whose copula the headline dropped', H1,
          'The house has been evacuated.'),

    reason_translate('Evacuata la casa.', italian, italian, H2),
    check('THE COPULA IS WRITTEN BACK: a headline read is a sentence written', H2,
          'La casa è stata evacuata.'),

    reason_ir('Evacuata la casa.', italian, H3),
    check('the IR is the passive perfect, with no shape of its own', H3,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(house, lower), singular),
                g(evacuates, present, passive_perfect, no), []), 46)]),

    reason_ir('La casa è stata evacuata.', italian, H4),
    check('and the full sentence reads to exactly that IR', H4, H3),

    reason_translate('Evacuate le case.', italian, english, H5),
    check('the plural, where the participle agrees and the number is read off it', H5,
          'The houses have been evacuated.'),

    reason_translate('Evacuate le case.', italian, italian, H6),
    check('and back, both participles agreeing', H6, 'Le case sono state evacuate.'),

    reason_unlearn(italian).

% ---- the gerund clause and the `that' complement ------------------------------------
% `..., escludendo che il generale dominasse' is a clause with a verb, no
% subject and no auxiliary, hung off the one before it by the join of
% 1.6.1, with a `that' clause of its own as its complement. The
% subjunctive is read as the tense it stands for and written back as the
% indicative, because English marks none there.

subordinate :-
    section('the gerund clause, the `that'' complement and the subjunctive'),
    reason_learn('Italian is a language.
The noun "paese" means "country". The noun "generale" means "general". The noun "casa" means "house".
The masculine article "il" means "the". The feminine article "la" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "domina" means "dominates". The verb "definisce" means "defines". The verb "esclude" means "excludes".
"dominava" is the past of "domina".
"escludendo" is the gerund of "esclude".
"dominasse" is the past subjunctive of "domina".
The conjunction "che" means "that".
Every adjective follows the noun.', italian, _),
    reason_learn('Spanish is a language.
The noun "pais" means "country". The noun "general" means "general". The noun "casa" means "house".
The masculine article "el" means "the". The feminine article "la" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "domina" means "dominates". The verb "define" means "defines". The verb "excluye" means "excludes".
"dominaba" is the past of "domina".
"excluyendo" is the gerund of "excluye".
The conjunction "que" means "that".
Every adjective follows the noun.', spanish, _),

    reason_translate('Escludendo che il generale domina.', italian, english, B1),
    check('a gerund heads a clause of its own, with a `that'' clause in it', B1,
          'Excluding that the general dominates.'),

    reason_translate('Escludendo che il generale domina.', italian, spanish, B2),
    check('and into Spanish, both words the lesson''s own', B2,
          'Excluyendo que el general domina.'),

    reason_ir('Escludendo che il generale domina.', italian, B3),
    check('the IR: the aspect is gerund, the subject is none, the clause is that/1', B3,
          [ir(s(none, none, g(excludes, present, gerund, no),
                [that(s(none, np(det(article, the, w(the, lower)), none, [], w(general, lower), singular),
                        g(dominates, present, simple, no), []))]), 46)]),

    reason_translate('Il generale definisce la casa, escludendo che il paese domina.', italian, english, B4),
    check('THE SAMPLE''S OWN SHAPE: a comma join, a gerund clause and a `that'' clause', B4,
          'The general defines the house, excluding that the country dominates.'),

    reason_translate('Escludendo che il generale dominasse.', italian, english, B5),
    check('a subjunctive is read as the tense it stands for', B5,
          'Excluding that the general dominated.'),

    reason_translate('Escludendo che il generale dominasse.', italian, italian, B6),
    check('and written back as the INDICATIVE, which is the cost', B6,
          'Escludendo che il generale dominava.'),

    reason_translate('Excluding that the general dominates.', english, italian, B7),
    check('English reads a gerund clause back the other way', B7,
          'Escludendo che il generale domina.'),

    reason_unlearn(italian), reason_unlearn(spanish).

% ---- an article before a name -------------------------------------------------------
% `Evacuata la Tate Gallery.' refused with every word known, and it was not
% the headline: `Evacuata la casa.' reads. `tr_np/3' took a BARE capitalised
% word no lesson knows as a name and a determiner in front of it sent the
% phrase reader looking for a noun it does not have. It is an ordinary phrase
% now with `named(Gender, Words)' where the noun goes, and the gender is the
% source article's, because a name has none of its own.

names :-
    section('an article before a name, and the gender the article lends it'),
    reason_learn('Italian is a language.
The noun "casa" means "house".
The feminine article "la" means "the". The masculine article "il" means "the".
"le" is the plural of "la". "i" is the plural of "il". "case" is the plural of "casa".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "evacua" means "evacuates". The verb "è" means "is". "sono" is the plural of "è".
The verb "domina" means "dominates". "domina" is intransitive. "dominano" is the plural of "domina".
"evacuata" is the participle of "evacua". "evacuata" is feminine.
"evacuato" is the participle of "evacua".
"evacuate" is the participle of "evacua". "evacuate" is feminine. "evacuate" is the plural of "evacuata".
"stata" is the participle of "è". "stata" is feminine. "stato" is the participle of "è".
"state" is the participle of "è". "state" is feminine. "state" is the plural of "stata".
Every adjective follows the noun.', italian, _),
    reason_learn('Spanish is a language.
The noun "casa" means "house".
The feminine article "la" means "the". The masculine article "el" means "the".
"las" is the plural of "la". "casas" is the plural of "casa".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "evacua" means "evacuates". The verb "es" means "is".
The verb "domina" means "dominates". "domina" is intransitive.
The auxiliary "ha" means "has". "ha" is the auxiliary of "es".
"sido" is the participle of "es".
"evacuada" is the participle of "evacua". "evacuada" is feminine.
"evacuado" is the participle of "evacua".
Every adjective follows the noun.', spanish, _),

    reason_translate('La Gallery domina.', italian, english, N1),
    check('an article and a name the lesson cannot know is a phrase', N1,
          'The Gallery dominates.'),

    reason_translate('Evacuata la Tate Gallery.', italian, english, N2),
    check('THE SAMPLE''S SHORTEST SENTENCE, which refused with every word known', N2,
          'The Tate Gallery has been evacuated.'),

    reason_translate('Evacuata la Tate Gallery.', italian, spanish, N3),
    check('and into Spanish, the name crossing as itself', N3,
          'La Tate Gallery ha sido evacuada.'),

    reason_ir('Evacuata la Tate Gallery.', italian, N4),
    check('the IR: an ordinary phrase, the name where the noun goes, the gender the article gave', N4,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [],
                         named(feminine, [w(tate, upper), w(gallery, upper)]), singular),
                g(evacuates, present, passive_perfect, no), []), 46)]),

    reason_translate('Il Tate domina.', italian, italian, N5),
    check('a masculine article keeps its own', N5, 'Il Tate domina.'),

    reason_translate('Le Gallery dominano.', italian, english, N6),
    check('the article says the NUMBER too, which a name cannot', N6,
          'The Gallery dominate.'),

    %% Read on the ENGLISH side there is no gender to read, so the IR carries
    %% `none' and the article the lesson's order chooses supplies one -- which
    %% everything after it must then agree with, or the sentence disagrees with
    %% itself (measured: `La Tate Gallery e stato evacuato').
    reason_translate('The Tate Gallery has been evacuated.', english, italian, N7),
    check('ENGLISH GIVES NO GENDER, so the written article lends one and the participles follow', N7,
          'La Tate Gallery è stata evacuata.'),

    reason_ir('The Tate Gallery dominates.', english, N8),
    check('and the IR says so: none, where Italian said feminine', N8,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [],
                         named(none, [w(tate, upper), w(gallery, upper)]), singular),
                g(dominates, present, simple, no), []), 46)]),

    %% ENGLISH'S PASSIVE PERFECT WAS REFUSED BY ITS OWN READER since 1.6.2 --
    %% `been' is the participle of `is', so the two-word perfect matched first
    %% and left the verb over. The writer produced exactly these words, so a
    %% passive perfect could not round-trip through English at all.
    reason_translate('The house has been evacuated.', english, italian, N9),
    check('ENGLISH READS ITS OWN PASSIVE PERFECT now', N9, 'La casa è stata evacuata.'),

    reason_translate('The house had been evacuated.', english, english, N10),
    check('and in the past, round-tripping through English alone', N10,
          'The house had been evacuated.'),

    reason_translate('Maria domina.', italian, english, N11),
    check('a BARE name is untouched: one word, and no article to lend it anything', N11,
          'Maria dominates.'),

    reason_unlearn(italian), reason_unlearn(spanish).

% ---- the imperative ------------------------------------------------------------------
% An imperative has no subject and names one anyway -- the person spoken to --
% so the aspect carries it and the subject is `none'. It is tried LAST, so a
% bare third person that was refused before is what changes and nothing else;
% and only a form the lesson CALLS an imperative reads as one, which is what
% keeps `Comia el pan.' refused where `Come el pan.' is read.
%
% THE NEGATIVE IMPERATIVE IS A DIFFERENT FORM IN EVERY LANGUAGE THAT HAS ONE
% -- Spanish takes the second-person subjunctive and Italian the infinitive --
% and the translator knows neither: it asks the lesson for `the negative
% imperative' and writes back whatever the lesson called one.

imperatives :-
    section('the imperative, and the negative one the lesson names'),
    reason_learn('Spanish is a language.
The noun "pan" means "bread". The noun "casa" means "house".
The masculine article "el" means "the". The feminine article "la" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "come" means "eats". The verb "es" means "is".
"comia" is the past of "come".
"come" is the imperative of "come". "comas" is the negative imperative of "come".
The pronoun "lo" means "it". Every pronoun precedes the verb.
The word "no" means "not".', spanish, _),
    reason_learn('Italian is a language.
The noun "pane" means "bread". The noun "casa" means "house".
The masculine article "il" means "the". The feminine article "la" means "the".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "mangia" means "eats". The verb "è" means "is".
"mangiava" is the past of "mangia".
"mangia" is the imperative of "mangia". "mangiare" is the negative imperative of "mangia".
The pronoun "lo" means "it". Every pronoun precedes the verb.
The word "non" means "not".', italian, _),

    reason_translate('Come el pan.', spanish, english, I1),
    check('a form the lesson calls an imperative, with no subject', I1, 'Eat the bread.'),

    reason_translate('Eat the bread.', english, spanish, I2),
    check('and back: English''s imperative is the BASE form', I2, 'Come el pan.'),

    reason_translate('Come el pan.', spanish, italian, I3),
    check('Spanish into Italian, with no English written', I3, 'Mangia il pane.'),

    reason_ir('Come el pan.', spanish, I4),
    check('the IR: the aspect carries it and the subject is none', I4,
          [ir(s(none, none, g(eats, present, imperative, no),
                [obj(np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular))]), 46)]),

    %% THE FINDING: the two languages build the denial on different forms,
    %% and the translator knows neither of them.
    reason_translate('No comas el pan.', spanish, italian, I5),
    check('the NEGATIVE: Spanish''s subjunctive in, Italian''s infinitive out', I5,
          'Non mangiare il pane.'),

    reason_translate('Non mangiare il pane.', italian, spanish, I6),
    check('and the other way round', I6, 'No comas el pan.'),

    reason_translate('Do not eat the bread.', english, spanish, I7),
    check('English denies with `do not'', never `does not'': an imperative has no person', I7,
          'No comas el pan.'),

    reason_translate('No comas el pan.', spanish, english, I8),
    check('and back', I8, 'Do not eat the bread.'),

    reason_translate('No lo comas.', spanish, english, I9),
    check('a clitic before the verb belongs to the imperative like any other', I9,
          'Do not eat it.'),

    reason_translate('Come.', spanish, english, I10),
    check('an imperative with nothing after it', I10, 'Eat.'),

    reason_ir('Comia el pan.', spanish, I11),
    check('A FORM NO LESSON CALLS AN IMPERATIVE IS NO IMPERATIVE: a subject nobody named, and simple', I11,
          [ir(s(none, null(third, singular), g(eats, past, simple, no),
                [obj(np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular))]), 46)]),

    reason_translate('La casa come el pan.', spanish, english, I12),
    check('and a sentence WITH a subject is untouched: the imperative is tried last', I12,
          'The house eats the bread.'),

    yes_no(reason_ir('Mangiare il pane.', italian, _), I13),
    check('the infinitive alone is no imperative: the lesson calls that form the NEGATIVE one', I13, no),

    %% THE COST THAT STOOD HERE UNTIL 1.8.14: Spanish ATTACHES the pronoun to
    %% an affirmative imperative and accents the stem (`Cómelo.', `Dame
    %% eso.'), and such a sentence was refused. The Bastille letter's
    %% `correggetemi' made it read: the joined pronoun is the clitic it is,
    %% and written back joined. The accent where the stress moves is still
    %% no rule a lesson states, so it comes out without one.
    nf_tr('Comelo.', spanish, english, I14),
    check('AN ATTACHED CLITIC READS SINCE 1.8.14, where this pinned the refusal: the pronoun joined to a command is its object', I14, 'Eat it.'),

    reason_unlearn(italian), reason_unlearn(spanish).

%% ---- what stands beside the sentence ------------------------------------------------
%%
%% Newspaper prose puts an adverb inside the verb group, a connector at the
%% head and an adjunct before the subject, and none of the three was read
%% before 1.6.14. Every one of them is tried only after the plain reading
%% failed, so nothing above this line changed.

adjuncts :-
    section('adjuncts: an adverb inside the group, a connector at the head, a phrase before the subject'),
    reason_translate('El perro ha siempre comido el pan.', A1),
    check('an adverb INSIDE the verb group, which no reader was looking for', A1, 'The dog has eaten the bread always.'),
    reason_translate('Siempre el perro come el pan.', A2),
    check('and one at the head, before the subject -- and the fronting is not written back, which is 1.6.8''s rule', A2, 'The dog eats the bread always.'),
    reason_translate('Y el perro come el pan.', A3),
    check('a connector at the head, with no left clause in the sentence at all', A3, 'And the dog eats the bread.'),
    reason_translate('En la casa el perro come el pan.', A4),
    check('a fronted adjunct before the subject', A4, 'The dog eats the bread in the house.'),
    reason_translate('Sábado el perro come el pan.', A5),
    check('a bare time phrase, which the lesson says is one', A5, 'The dog eats the bread saturday.'),
    reason_translate('El perro come el pan para siempre.', A6),
    check('a preposition whose object is an adverb', A6, 'The dog eats the bread for always.'),
    reason_translate('El todo es grande.', A7),
    check('a determiner and a pronoun: the pronoun is the head', A7, 'The everything is big.'),
    %% and the refusals that stay
    yes_no(reason_translate('Come el pan rápidamente y.', _), A8),
    check('a connector with nothing after it is still refused', A8, no).

% ---- a Spanish article into Italian ----------------------------------------------------
%%
%% A real Spanish newspaper article -- El Periódico, 2 February 1999, the
%% AnCora document CESS-CAST-P-19990202-16, eleven sentences -- translated
%% into Italian needed what the Italian sample did not: a relative clause
%% with its own pronoun, a list with commas in it, a word of several words,
%% a gerund and `al' with an infinitive for how and when a thing was done,
%% a phrase whose noun was left out, what has no verb, and the forms
%% Italian chooses by the word after them. Each shape here is one of the
%% article's, on two small lessons of its own.

newspaper_es :-
    section('a Spanish article into Italian: relatives, lists, ellipsis, what has no verb, and the forms Italian chooses'),
    newspaper_es_learn,
    newspaper_es_checks.
newspaper_es_learn :-
    newspaper_es_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_es_lesson(italian, IT), reason_learn(IT, italian, _).
%% one fact a lesson: both in one clause ran over the page a stored clause
%% must fit in, which cocolint flags
newspaper_es_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread".
"panes" is the plural of "pan". The noun "caldo" means "broth". The noun "sopa" means "soup".
The noun "chico" means "boy". "chico" is a person.
The noun "grupo" means "group". "grupo" is a person.
The noun "padre" means "father". "padre" is a person.
The noun "ministro" means "minister". "ministro" is a person.
The noun "escándalo" means "scandal".
The noun "institución" means "institution". "institución" is feminine. "institución" is a person.
The noun "familia" means "family".
The noun "ciudad" means "city". "ciudad" is feminine. "ciudades" is the plural of "ciudad".
The masculine noun "lavado de cerebro" means "brainwashing". "lavados de cerebro" is the plural of "lavado de cerebro".
The preposition "junto a" means "along with".
The modal "tiene que" means "must".
The adjective "grande" means "big". "grandes" is the plural of "grande".
The adjective "débil" means "weak". "débiles" is the plural of "débil".
The masculine adjective "pacífico" means "peaceful". The feminine adjective "pacífica" means "peaceful".
The masculine adjective "sacrosanto" means "sacrosanct". The feminine adjective "sacrosanta" means "sacrosanct".
The noun "culpable" means "culprit". The adjective "culpable" means "guilty". "culpables" is the plural of "culpable".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
"comiendo" is the gerund of "come". "comido" is the participle of "come". "comía" is the past of "come".
The verb "es" means "is". "son" is the plural of "es".
The verb "llama" means "calls". "llamará" is the future of "llama".
The verb "pertenece" means "belongs". "pertenece" is the imperative of "pertenece".
The verb "acusa" means "accuses". "acusar" is the infinitive of "acusa". "acusando" is the gerund of "acusa".
The verb "provoca" means "causes". "provocado" is the participle of "provoca".
The verb "equivoca" means "errs". "equivocado" is the participle of "equivoca". "equivoca" is reflexive.
The verb "golpea" means "hits".
The auxiliary "ha" means "has".
The verb "hay" means "there is".
"sido" is the participle of "es". "ha" is the auxiliary of "es".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The adverb "después" means "afterwards". The adverb "tan" means "so". The adverb "todavía" means "still".
The word "cómo" means "how".
The conjunction "y" means "and". The conjunction "o" means "or". The conjunction "que" means "that".
"que" is a relative.
The masculine pronoun "ese" means "that". "esos" is the plural of "ese". The pronoun "ese" does not precede the verb.
The pronoun "les" means "them". Every pronoun precedes the verb.
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".
The possessive "su" means "his". "sus" is the plural of "su".
The word "a" precedes the person.
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in".
The word "al" begins the moment. The word "más" begins the comparative. The adverb "más" means "more". The word "el" replaces the noun.
The mark "¿" begins the question.
The word "no" means "not". The word "no" precedes the verb.').
newspaper_es_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The masculine article "uno" means "a". The feminine article "una" means "a".
"l''" is the elision of "lo". "l''" is the elision of "la". "un''" is the elision of "una".
The article "lo" comes before a vowel. The article "lo" comes before "sc". The article "uno" comes before "sc".
"del" is the contraction of "di il". "dello" is the contraction of "di lo". "della" is the contraction of "di la".
"dei" is the contraction of "di i". "degli" is the contraction of "di gli". "delle" is the contraction of "di le".
"dell''" is the elision of "dello". "dell''" is the elision of "della". "al" is the contraction of "a il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane".
The noun "brodo" means "broth". The noun "minestra" means "soup".
The noun "ragazzo" means "boy". "ragazzi" is the plural of "ragazzo".
The noun "gruppo" means "group". The noun "padre" means "father". "padri" is the plural of "padre".
The noun "ministro" means "minister".
The noun "scandalo" means "scandal". "scandali" is the plural of "scandalo".
The noun "istituzione" means "institution". "istituzione" is feminine.
The noun "famiglia" means "family".
The noun "città" means "city". "città" is feminine. "città" is the plural of "città".
The masculine noun "lavaggio del cervello" means "brainwashing". "lavaggi del cervello" is the plural of "lavaggio del cervello".
The preposition "insieme a" means "along with".
The modal "deve" means "must".
The adjective "grande" means "big". "grandi" is the plural of "grande".
The adjective "debole" means "weak".
The masculine adjective "pacifico" means "peaceful". The feminine adjective "pacifica" means "peaceful".
The masculine adjective "sacrosanto" means "sacrosanct". The feminine adjective "sacrosanta" means "sacrosanct".
The adjective "colpevole" means "guilty". "colpevoli" is the plural of "colpevole".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangiando" is the gerund of "mangia". "mangiato" is the participle of "mangia".
The verb "è" means "is". "sono" is the plural of "è".
The verb "chiama" means "calls". "chiamerà" is the future of "chiama".
The verb "appartiene" means "belongs". "appartieni" is the imperative of "appartiene".
The verb "accusa" means "accuses". "accusando" is the gerund of "accusa".
The verb "causa" means "causes". "causato" is the participle of "causa".
The verb "sbaglia" means "errs". "sbagliato" is the participle of "sbaglia".
The verb "colpisce" means "hits".
The auxiliary "ha" means "has". "è" is the auxiliary of the reflexive.
The verb "c''è" means "there is". "ci sono" is the plural of "c''è".
"stato" is the participle of "è".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The adverb "dopo" means "afterwards". The adverb "così" means "so". The adverb "ancora" means "still".
The word "come" means "how".
The conjunction "e" means "and". The conjunction "o" means "or". The conjunction "che" means "that".
"che" is a relative. "cui" is a relative. The word "cui" follows the preposition.
The masculine pronoun "quello" means "that". "quelli" is the plural of "quello". The pronoun "quello" does not precede the verb.
The pronoun "li" means "them". Every pronoun precedes the verb.
The impersonal pronoun "si" means "one". The reflexive pronoun "si" means "itself". The word "si" follows the pronoun.
The possessive "suo" means "his". "suoi" is the plural of "suo". The article "il" takes the possessive.
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in".
The word "più" begins the comparative. The adverb "più" means "more".
The word "non" means "not". The word "non" precedes the verb.').
newspaper_es_checks :-

    %% a relative clause with its own pronoun: for the object, the subject,
    %% and the object of a preposition, where the clause's own subject is the
    %% one nobody named and its verb could be an imperative, and is not one
    answer(reason_translate('El perro come el caldo que el chico come.', spanish, italian, ON1), ON1, N1),
    check('a relative clause for the object', N1, 'Il cane mangia il brodo che il ragazzo mangia.'),
    answer(reason_translate('El perro come el pan de esos, que son culpables.', spanish, italian, ON2), ON2, N2),
    check('for the subject, on a pronoun, with its comma, the verb in the pronoun''s number, and guilty for the ADJECTIVE', N2,
          'Il cane mangia il pane di quelli, che sono colpevoli.'),
    answer(reason_translate('Es el grupo al que pertenece.', spanish, italian, ON3), ON3, N3),
    check('for a preposition''s object: al que is a cui, and pertenece is no imperative there', N3,
          'È il gruppo a cui appartiene.'),
    answer(reason_ir('Es el grupo al que pertenece.', spanish, IIR3), IIR3, IR3),
    check('the IR: rc(Phrase, pp(Preposition), Clause), the subjects nobody named', IR3,
          [ir(s(none, null(third, singular), g(is, present, simple, no),
                [obj(rc(np(det(article, the, w(the, lower)), none, [], w(group, lower), singular), pp(w(to, lower)),
                        s(none, null(third, singular), g(belongs, present, simple, no), [])))]), 46)]),
    yes_no(reason_translate('Es el grupo al que pertenece.', spanish, english, _), N4),
    check('and English refuses a third person nobody named: he, she and it are three claims', N4, no),

    %% the conjunction kept, a list's comma, a word of several words
    answer(reason_translate('El perro come el pan o el caldo.', spanish, italian, ON5), ON5, N5),
    check('or stays or', N5, 'Il cane mangia il pane o il brodo.'),
    answer(reason_translate('El perro come pan, caldo y sopa.', spanish, italian, ON6), ON6, N6),
    check('a comma inside a list is the list''s, and comes back', N6, 'Il cane mangia pane, brodo e minestra.'),
    answer(reason_translate('El chico come el pan junto a una sopa.', spanish, italian, ON7), ON7, N7),
    check('a preposition of two words is one word', N7, 'Il ragazzo mangia il pane insieme a una minestra.'),
    answer(reason_translate('El perro tiene que comer el pan.', spanish, italian, ON8), ON8, N8),
    check('and a modal of two words', N8, 'Il cane deve mangiare il pane.'),
    answer(reason_translate('Hay lavados de cerebro.', spanish, italian, ON9), ON9, N9),
    check('and a noun of three, whose plural there is agrees with', N9, 'Ci sono lavaggi del cervello.'),

    %% how a thing was done, and the moment of it
    answer(reason_translate('El ministro golpea el pan comiendo la sopa.', spanish, italian, ON10), ON10, N10),
    check('a gerund after the complements', N10, 'Il ministro colpisce il pane mangiando la minestra.'),
    answer(reason_translate('El ministro ha provocado el escándalo al acusar a la institución.', spanish, italian, ON11), ON11, N11),
    check('al and an infinitive, written as the gerund; lo before sc; the elided la', N11,
          'Il ministro ha causato lo scandalo accusando l''istituzione.'),

    %% a phrase whose noun was left out
    answer(reason_translate('El ministro golpea a un grupo y el más débil.', spanish, italian, ON12), ON12, N12),
    check('the article and a superlative, the noun left out', N12, 'Il ministro colpisce un gruppo e il più debole.'),
    answer(reason_translate('El perro come el pan de los gatos y el de los chicos.', spanish, italian, ON13), ON13, N13),
    %% the ellipsis joins INSIDE the `de' phrase -- the IR hangs `el de los
    %% chicos' on the cats, where it belongs beside the bread -- and every
    %% language writes the same words either way, which is 1.6.6's PP finding
    check('the article and a de phrase: Spanish''s article, Italian''s pronoun', N13,
          'Il cane mangia il pane dei gatti e quello dei ragazzi.'),

    %% what has no verb: an exclamation, and a clause that leaves out the verb before it
    answer(reason_translate('¡El pan del perro!', spanish, italian, ON14), ON14, N14),
    check('an exclamation with no verb', N14, 'Il pane del cane!'),
    answer(reason_translate('El pan del perro.', spanish, italian, ON15), ON15, N15),
    check('A HEADING OF A PHRASE WITH ITS DE PHRASE READS NOW -- `El voto de los descontentos.'' in the Georgia report -- where this pinned the refusal before 1.8.7', N15, 'Il pane del cane.'),
    yes_no(reason_translate('Pan del perro.', spanish, italian, _), N15b),
    check('and a statement with no verb and no article is still refused', N15b, no),
    answer(reason_translate('El perro come el pan; el gato, la sopa.', spanish, italian, ON16), ON16, N16),
    check('a semicolon, and after it a clause that leaves the verb out', N16, 'Il cane mangia il pane; il gatto, la minestra.'),

    %% an apposition, an intensifier, a question in quotation marks, a front
    answer(reason_translate('El ministro, Jean-Pierre Chevènement, come el pan.', spanish, italian, ON17), ON17, N17),
    check('a name between commas after a phrase, a hyphen and all', N17, 'Il ministro, Jean-Pierre Chevènement, mangia il pane.'),
    answer(reason_translate('El chico come en una familia tan pacífica.', spanish, italian, ON18), ON18, N18),
    check('an adverb before an adjective inside a phrase', N18, 'Il ragazzo mangia in una famiglia così pacifica.'),
    answer(reason_translate('"¿Cómo come el perro?".', spanish, italian, ON19), ON19, N19),
    check('how, in a question in quotation marks', N19, '"Come mangia il cane?".'),
    answer(reason_translate('Después, el perro come el pan.', spanish, italian, ON20), ON20, N20),
    check('a front set off by a comma is written in front', N20, 'Dopo, il cane mangia il pane.'),
    answer(reason_translate('Después el perro come el pan.', spanish, italian, ON21), ON21, N21),
    check('and one with no comma after the verb, as 1.6.8 writes it', N21, 'Il cane mangia il pane dopo.'),

    %% the forms Italian chooses
    answer(reason_translate('Los escándalos son grandes.', spanish, italian, ON22), ON22, N22),
    check('gli, the plural of the lo the next word chose', N22, 'Gli scandali sono grandi.'),
    answer(reason_translate('El perro come el pan de sus padres.', spanish, italian, ON23), ON23, N23),
    check('the article a possessive takes, and its contraction', N23, 'Il cane mangia il pane dei suoi padri.'),
    answer(reason_translate('El ministro se ha equivocado.', spanish, italian, ON24), ON24, N24),
    check('the perfect of a reflexive, with the auxiliary the lesson names', N24, 'Il ministro si è sbagliato.'),
    answer(reason_translate('Se ha equivocado.', spanish, italian, ON25), ON25, N25),
    check('and se before a verb the lesson calls reflexive is its own, never the impersonal subject', N25, 'Si è sbagliato.'),
    answer(reason_translate('Se les llamará chicos.', spanish, italian, ON26), ON26, N26),
    check('the impersonal si after the clitics', N26, 'Li si chiamerà ragazzi.'),
    answer(reason_translate('La sacrosanta institución es grande.', spanish, italian, ON27), ON27, N27),
    check('an adjective the source set before its noun stays there', N27, 'La sacrosanta istituzione è grande.'),
    answer(reason_translate('La institución sacrosanta es grande.', spanish, italian, ON28), ON28, N28),
    check('and one after it stays after it', N28, 'L''istituzione sacrosanta è grande.'),
    answer(reason_translate('Las ciudades son grandes.', spanish, italian, ON29), ON29, N29),
    check('a noun whose plural is itself', N29, 'Le città sono grandi.'),

    %% and the other way, Italian into Spanish: four readings the twelve
    %% Italian sentences lost on the vocabulary store while this section was
    %% green, pinned here so a small lesson sees them
    answer(reason_translate('Il cane mangia il pane dei suoi padri.', italian, spanish, ON30), ON30, N30),
    check('a possessive after an article is the phrase''s determiner, so Spanish writes no article before it', N30,
          'El perro come el pan de sus padres.'),
    answer(reason_translate('Uno dei cani mangia.', italian, spanish, ON31), ON31, N31),
    check('an article the lesson says stands alone as a pronoun heads its own phrase: no noun left out', N31,
          'Uno de los perros come.'),
    answer(reason_translate('Il pane è stato ancora mangiato.', italian, spanish, ON32), ON32, N32),
    check('an adverb inside a passive perfect, never the passive of the copula''s participle', N32,
          'El pan ha sido comido todavía.'),
    answer(reason_translate('In famiglia si mangia il pane, accusando il ministro.', italian, spanish, ON33), ON33, N33),
    check('a front with no comma goes before the comma that a gerund stands after', N33,
          'Se come el pan en familia, acusando al ministro.'),

    reason_unlearn(italian), reason_unlearn(spanish).

% ---- an Italian article into Spanish ----------------------------------------------------
%%
%% A second real Italian article -- Monte Livata, the Italian UD ISDT
%% document test-232..260, twenty-nine sentences of a rescue story told in
%% quotations -- translated into Spanish needed what neither sample before
%% it did: the copula of a STATE, a count with an adverb before it and a
%% noun left out after it, `of which' with no verb, `all' before a phrase,
%% a DATIVE pronoun, the `to' before an infinitive, a front that asks where,
%% a sentence of thanks with no verb, and an elided article after a
%% contraction. Each shape here is one of the article's, on two small
%% lessons of its own.

newspaper_it :-
    section('an Italian article into Spanish: a state, counts, of which, all, datives, to, where, thanks'),
    newspaper_it_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_it_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_it_checks,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_it_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "noche" means "night". "noche" is feminine.
The noun "unidad" means "unit". "unidad" is feminine. "unidades" is the plural of "unidad".
The masculine adjective "canino" means "canine". The feminine adjective "canina" means "canine".
The masculine adjective "cansado" means "tired". The feminine adjective "cansada" means "tired".
The masculine determiner "otro" means "other". The feminine determiner "otra" means "other".
The masculine pronoun "todo" means "all". The feminine pronoun "toda" means "all".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
The verb "duerme" means "sleeps". The verb "va" means "goes".
The verb "da" means "gives". "dado" is the participle of "da".
The verb "es" means "is". "son" is the plural of "es". "somos" is the first person of "son".
The auxiliary "está" means "is". "están" is the plural of "está". "estamos" is the first person of "están".
The auxiliary "está" marks the state. The verb "está" means "stays".
The auxiliary "ha" means "has". "han" is the plural of "ha". "hemos" is the first person of "han".
The pronoun "lo" means "him". The dative pronoun "le" means "him". Every pronoun precedes the verb.
"que" is a relative. The conjunction "que" means "that".
The preposition "a" means "to". The preposition "de" means "of". The preposition "desde" means "from".
The preposition "con" means "with". The preposition "en" means "in".
The preposition "junto a" means "along with". The preposition "gracias a" means "thanks to".
The adverb "más de" means "more than". The number "tres" means "three".
The conjunction "y" means "and". The conjunction "donde" means "where". The word "dónde" means "where".
The noun "sábado" means "saturday". "sábado" is a time.
"ha" is the auxiliary of "es". "sido" is the participle of "es".
The verb "verifica" means "verifies". "verificado" is the participle of "verifica".
"verificados" is the participle of "verifica". "verificados" is the plural of "verificado".
The adverb "todavía" means "still".
The masculine adjective "voluntario" means "voluntary". "voluntarios" is the plural of "voluntario".
The masculine noun "voluntario" means "volunteer".
The word "no" means "not".').
%% one lesson a clause: both in one ran over the page a stored clause must fit in
newspaper_it_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"l''" is the elision of "lo". "l''" is the elision of "la".
"al" is the contraction of "a il". "alla" is the contraction of "a la". "ai" is the contraction of "a i".
"all''" is the elision of "alla". "dalla" is the contraction of "da la". "dall''" is the elision of "dalla".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat".
The noun "pane" means "bread". "pani" is the plural of "pane".
The noun "notte" means "night". "notte" is feminine.
The noun "unità" means "unit". "unità" is feminine. "unità" is the plural of "unità".
The masculine adjective "cinofilo" means "canine". The feminine adjective "cinofila" means "canine".
"cinofile" is the plural of "cinofila".
The masculine adjective "stanco" means "tired". "stanchi" is the plural of "stanco".
The masculine adjective "altro" means "other". The feminine adjective "altra" means "other".
The masculine pronoun "tutto" means "all". The feminine pronoun "tutta" means "all".
The pronoun "tutta" does not precede the verb.
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". The verb "va" means "goes".
The verb "dà" means "gives". "dato" is the participle of "dà".
The verb "è" means "is". "sono" is the plural of "è". "siamo" is the first person of "sono".
The auxiliary "sta" means "is". "stanno" is the plural of "sta". "stiamo" is the first person of "stanno".
The verb "sta" means "stays".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "abbiamo" is the first person of "hanno".
The dative pronoun "gli" means "him". Every pronoun precedes the verb.
"che" is a relative. "cui" is a relative. The word "cui" follows the preposition.
The preposition "a" means "to". The preposition "di" means "of". The preposition "da" means "from".
The preposition "con" means "with". The preposition "in" means "in".
The preposition "insieme a" means "along with". The preposition "grazie a" means "thanks to".
The adverb "oltre" means "more than". The number "tre" means "three".
The conjunction "e" means "and". The word "dove" means "where".
The noun "sabato" means "saturday". "sabato" is a time.
"sono" is the first person of "è". "stato" is the participle of "è".
"stati" is the participle of "è". "stati" is the plural of "stato".
The verb "accerta" means "verifies". "accertato" is the participle of "accerta".
"accertati" is the participle of "accerta". "accertati" is the plural of "accertato".
The adverb "ancora" means "still".
The masculine adjective "volontario" means "voluntary". "volontari" is the plural of "volontario".
The masculine noun "volontario" means "volunteer".
The word "non" means "not".').

newspaper_it_checks :-
    %% THE COPULA OF A STATE: the auxiliary that means `is', with no gerund
    %% after it, is the state's, and the IR keeps it apart as state(is).
    %% Spanish writes the word its lesson says marks the state; Italian,
    %% whose lesson says nothing of the kind, writes its plain copula.
    reason_ir('Stiamo stanchi.', italian, L1),
    check('stare with no gerund is the copula of a state, state(is)', L1,
          [ir(s(none, null(first, plural), g(state(is), present, simple, no), [adj([w(tired, lower)])]), 46)]),
    reason_translate('Stiamo stanchi.', italian, spanish, L2),
    check('Spanish writes estar, which its lesson says marks the state', L2, 'Estamos cansados.'),
    reason_translate('Stiamo stanchi.', italian, english, L3),
    check('English has one word for both', L3, 'We are tired.'),
    reason_translate('Estamos cansados.', spanish, italian, L4),
    check('and Italian, whose lesson says nothing of a state, the plain copula', L4, 'Siamo stanchi.'),
    %% counts and what stands for the counted
    reason_translate('Il cane mangia oltre 50 pani.', italian, spanish, L5),
    check('an adverb before a number is the count''s: more than, and a preposition too', L5, 'El perro come más de 50 panes.'),
    reason_translate('Il cane mangia 37 pani, di cui tre.', italian, spanish, L6),
    check('OF WHICH with no verb: the relative after its preposition, agreeing with the object before it', L6,
          'El perro come 37 panes, de los que tres.'),
    reason_translate('Il cane mangia con unità cinofile.', italian, spanish, L7),
    check('a noun that is its own plural takes the number of the adjective that has only one', L7,
          'El perro come con unidades caninas.'),
    reason_translate('Il cane dorme tutta la notte.', italian, spanish, L8),
    check('ALL before a determiner is the phrase''s own, agreeing with its noun', L8, 'El perro duerme toda la noche.'),
    %% a dative, the `to' before an infinitive, a front that asks where
    reason_translate('Gli abbiamo dato il pane.', italian, spanish, L9),
    check('a DATIVE pronoun stays one: le, never lo', L9, 'Le hemos dado el pan.'),
    reason_translate('Il cane va a mangiare il pane.', italian, spanish, L10),
    check('the to before an infinitive is kept, and written as the lesson''s own', L10, 'El perro va a comer el pan.'),
    reason_translate('Il cane dorme e da dove il gatto mangia il pane.', italian, spanish, L11),
    check('a front that asks where is written in front, with no comma', L11, 'El perro duerme y desde donde el gato come el pan.'),
    %% thanks with no verb, a word of several words that contracts, an
    %% elided article after a contraction
    reason_translate('Grazie ai cani!', italian, spanish, L12),
    check('thanks: a sentence with no verb', L12, 'Gracias a los perros!'),
    reason_translate('Il cane mangia insieme al gatto.', italian, spanish, L13),
    check('a word of several words contracts by its last word: junto al', L13, 'El perro come junto al gato.'),
    reason_translate('Il cane va dall''altra.', italian, spanish, L14),
    check('an elided article after a contraction stays elided, and the adjective says the gender', L14,
          'El perro va desde la otra.'),
    %% two regressions the control sentences found, each pinned where it bit:
    %% the coordinator INSIDE a subject opens no clause, so the denial after
    %% it is still the sentence's; and a time at the head keeps no capital,
    %% so the name after it is the subject and not a name apposed to the day
    reason_translate('Il cane e il gatto non mangiano il pane.', italian, spanish, L15),
    check('a coordinator inside the subject opens no clause: the denial is the verb''s', L15,
          'El perro y el gato no comen el pan.'),
    reason_translate('Il cane e il gatto non mangiano il pane.', italian, english, L16),
    check('and English denies the same verb', L16, 'The dog and the cat do not eat the bread.'),
    reason_ir('Sabato Maria mangia il pane.', italian, L17),
    check('a TIME at the head keeps no capital: Maria is the subject, not a name apposed to the day', L17,
          [ir(s(none, name(maria), g(eats, present, simple, no),
                [obj(np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular)),
                 at_time(np(none, none, [], w(saturday, lower), singular))]), 46)]),
    %% and an adverb inside the passive perfect leaves the participle to
    %% choose the copula's number: `sono' is I am before it is they are
    reason_translate('Non sono stati ancora accertati.', italian, spanish, L18),
    check('the participle chooses the copula''s number with an adverb inside: they, not I', L18,
          'No han sido verificados todavía.'),
    %% and a word standing alone where no verb was read is a thing named: the
    %% volunteers thanked, not something voluntary
    reason_translate('Grazie ai cani, volontari!', italian, spanish, L19),
    check('a noun and adjective alone in a clause with no verb is the noun', L19,
          'Gracias a los perros, voluntarios!').

% ---- an Italian business article into Spanish --------------------------------------------
%%
%% A third real Italian article -- the Fiat-Chrysler agreement with Veba of
%% January 2014, the Italian UD ISDT document test-261..281, twenty sentences
%% of figures, dates and quotations -- needed what the two before it did not:
%% a percentage as one word with its sign, a quotation inside a sentence read
%% as the words it holds, a date, a heading that ends in its colon, a sentence
%% that is one phrase with its relative clause, a list that is the subject,
%% reporting clauses between two dashes, between two commas and after a
%% quotation that closes inside its sentence, `di' and `nel' before an
%% infinitive, a participle that keeps its own gender, and Spanish's apocope.
%% Each shape is pinned on two small lessons of their own, and of the first
%% thirty checks every one but the two marked as guards fails on the
%% translator before them. The last four pin what the controls found against
%% the first cut of this, and each fails with its own rule put back as that
%% cut wrote it; the first three pass on the translator before this too,
%% which is what they are -- behaviour the first cut broke.

newspaper_fiat :-
    section('an Italian business article into Spanish: percentages, dates, headings, quotations inside a sentence, reporting clauses between dashes and commas'),
    newspaper_fiat_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_fiat_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_fiat_checks,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_fiat_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "casa" means "house". The noun "luz" means "light". "luz" is feminine.
The noun "premio" means "prize". The noun "leche" means "milk". "leche" is feminine.
The noun "secretario" means "secretary". The noun "amiga" means "friend".
The noun "satisfacción" means "satisfaction". "satisfacción" is feminine.
The masculine adjective "primero" means "first". The feminine adjective "primera" means "first".
The adjective "grande" means "big". The adjective "restante" means "remaining".
"primer" is the apocope of "primero". "gran" is the apocope of "grande".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
"comido" is the participle of "come". "comidos" is the participle of "come". "comidos" is the plural of "comido".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "dice" means "says". The verb "permite" means "allows". The verb "ama" means "loves". The verb "da" means "gives".
"dormir" is the infinitive of "duerme". The conjunction "desde que" means "ever since".
The verb "vende" means "sells". "vendido" is the participle of "vende".
"vendida" is the participle of "vende". "vendida" is feminine.
The verb "es" means "is". "son" is the plural of "es".
The verb "hay" means "there is". "hay" is the plural of "hay".
The pronoun "nos" means "us". Every pronoun precedes the verb.
"que" is a relative. The conjunction "que" means "that".
The preposition "a" means "to". The preposition "de" means "of". The preposition "desde" means "from".
The preposition "en" means "in". The preposition "por" means "by".
The preposition "antes de" means "before". The preposition "a la luz de" means "in the light of".
The preposition "como" means "as". The conjunction "y" means "and".
The adverb "ahora" means "now".
The noun "enero" means "january". "enero" is a month. The word "de" joins the date.
The word "a" precedes the person.
The word "no" means "not".
The adverb "más" means "more". The preposition "más" means "plus". The adverb "despacio" means "slowly".
The word "más" begins the comparative. The verb "acaba" means "finishes".
The noun "hora" means "hour".').
newspaper_fiat_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a il". "alla" is the contraction of "a la". "del" is the contraction of "di il".
"della" is the contraction of "di la". "dal" is the contraction of "da il". "dalla" is the contraction of "da la".
"nel" is the contraction of "in il". "nella" is the contraction of "in la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat".
The noun "pane" means "bread". "pani" is the plural of "pane".
The noun "casa" means "house". The noun "luce" means "light". "luce" is feminine.
The noun "premio" means "prize". The noun "latte" means "milk".
The noun "segretario" means "secretary". The noun "amica" means "friend".
The noun "soddisfazione" means "satisfaction". "soddisfazione" is feminine.
The masculine adjective "primo" means "first". The feminine adjective "prima" means "first".
The adjective "grande" means "big". The adjective "restante" means "remaining".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangiato" is the participle of "mangia". "mangiati" is the participle of "mangia". "mangiati" is the plural of "mangiato".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "dice" means "says". The verb "permette" means "allows". The verb "ama" means "loves". The verb "dà" means "gives".
"dormire" is the infinitive of "dorme". The conjunction "sin da quando" means "ever since".
The verb "vende" means "sells". "venduto" is the participle of "vende".
"venduta" is the participle of "vende". "venduta" is feminine.
The verb "è" means "is". "sono" is the plural of "è".
The verb "c''è" means "there is". "ci sono" is the plural of "c''è".
The pronoun "ci" means "us". Every pronoun precedes the verb.
"che" is a relative. The conjunction "che" means "that".
The preposition "a" means "to". The preposition "di" means "of". The preposition "da" means "from".
The preposition "da" means "by". The preposition "in" means "in".
The preposition "entro" means "before". The preposition "alla luce di" means "in the light of".
The word "come" means "how". The preposition "come" means "as". The conjunction "e" means "and".
The noun "ora" means "hour". "ora" is a time. The adverb "ora" means "now".
The noun "gennaio" means "january". "gennaio" is a month.
The word "non" means "not". The adverb "non" means "not".
The word "di" begins the infinitive.
"ore" is the plural of "ora". "prime" is the plural of "prima". "dalle" is the contraction of "da le".').

%% a refusal is a value the check names, not the end of the section
nf_tr(S, From, To, T) :- ( reason_translate(S, From, To, T0) -> T = T0 ; T = refused ).

newspaper_fiat_checks :-
    %% the tokeniser: a percentage is one word with its sign, and a quotation
    %% inside a sentence is read as words, its commas among them
    nf_tr('Il cane mangia il 41,46% del pane.', italian, spanish, F1),
    check('a percentage keeps its sign: one word, a number and a noun', F1, 'El perro come el 41,46% del pan.'),
    nf_tr('Il cane mangia il 100% del pane.', italian, spanish, F2),
    check('... and a bare one is no word `percent'' a lesson must give', F2, 'El perro come el 100% del pan.'),
    nf_tr('Il cane mangia il restante 41,46% del pane.', italian, spanish, F3),
    check('an adjective before a percentage describes it', F3, 'El perro come el restante 41,46% del pan.'),
    nf_tr('Il cane mangia “il pane, il latte e il premio”.', italian, spanish, F4),
    check('a quotation inside a sentence is its words, the comma among them', F4, 'El perro come "el pan, la leche y el premio".'),
    %% a phrase with its preposition before the object: a name ends a phrase
    nf_tr('Il cane mangia da Maria il pane.', italian, spanish, F5),
    check('a name is a phrase''s noun: the article after it starts the object', F5, 'El perro come desde Maria el pan.'),
    nf_tr('Il cane dà a Maria 3 pani.', italian, spanish, F6),
    check('... and so does a number after it', F6, 'El perro da a Maria 3 panes.'),
    %% a date
    nf_tr('Il cane mangia entro il 20 gennaio 2014.', italian, spanish, F7),
    check('a date: the day, the month and the year, joined by the word the lesson names', F7,
          'El perro come antes del 20 de enero de 2014.'),
    nf_tr('Il cane mangia entro il 20 gennaio 2014.', italian, english, F8),
    check('... and English puts the month first', F8, 'The dog eats before January 20, 2014.'),
    nf_tr('El perro come antes del 20 de enero de 2014.', spanish, italian, F9),
    check('... and read back, the join words come off', F9, 'Il cane mangia entro il 20 gennaio 2014.'),
    %% a word of several words whose last word came contracted
    nf_tr('Il cane dorme alla luce della casa.', italian, english, F10),
    check('a preposition of several words before a contracted article', F10, 'The dog sleeps in the light of the house.'),
    %% `come' as a preposition crosses as one
    nf_tr('Il cane mangia il pane come premio.', italian, spanish, F11),
    check('a preposition crosses by the meaning the lesson gave it as one', F11, 'El perro come el pan como premio.'),
    %% reporting clauses: between dashes inside, between commas, after a
    %% quotation that closes inside the piece, with a name after the phrase
    nf_tr('Il cane – dice Maria – mangia il pane.', italian, spanish, F12),
    check('a reporting clause between two dashes inside the sentence goes after it', F12,
          'El perro come el pan – dice Maria –.'),
    nf_tr('Alla luce della casa, dice Maria, il cane dorme.', italian, spanish, F13),
    check('... and one between two commas, the front kept in front', F13,
          'A la luz de la casa, el perro duerme, dice Maria.'),
    nf_tr('Il cane mangia “il pane” dice Maria.', italian, spanish, F14),
    check('a quotation that closes inside its sentence, and the clause that reports it', F14,
          'El perro come "el pan" dice Maria.'),
    nf_tr('“Il cane dorme” dice il segretario Mario Rossi.', italian, spanish, F15),
    check('a name after the speaker''s phrase is the speaker''s', F15, '“El perro duerme” dice el secretario Mario Rossi.'),
    nf_tr('Il cane dorme – dice Maria, amica del cane –.', italian, spanish, F16),
    check('a phrase after the speaker''s comma is its apposition, no object', F16,
          'El perro duerme – dice Maria, amiga del perro –.'),
    %% a heading that ends in a colon, a sentence that is one phrase
    nf_tr('Soddisfazione dalla Maria:', italian, spanish, F17),
    check('a heading: no verb, and its colon takes no full stop', F17, 'Satisfacción desde la Maria:'),
    nf_tr('Una casa che il cane ama.', italian, spanish, F18),
    check('a sentence that is one phrase with its relative clause', F18, 'Una casa que el perro ama.'),
    %% the subject a list, commas and all
    nf_tr('Il cane, il gatto e il segretario dormono.', italian, spanish, F19),
    check('a list at the head is the subject, whatever follows it', F19, 'El perro, el gato y el secretario duermen.'),
    %% `di' and an infinitive, and `nel' and one
    nf_tr('Il cane ci permette di mangiare il pane.', italian, spanish, F20),
    check('of and an infinitive after the verb is the infinitive', F20, 'El perro nos permite comer el pan.'),
    nf_tr('Il cane mangia nel dormire.', italian, spanish, F21),
    check('a preposition, an article and an infinitive', F21, 'El perro come en dormir.'),
    %% the agent and what follows it; a participle keeps its own gender
    nf_tr('Il cane mangia i pani mangiati dal gatto nel 2014.', italian, spanish, F22),
    check('the agent of a reduced relative, and the adjuncts after it', F22,
          'El perro come los panes comidos por el gato en el 2014.'),
    nf_tr('Il cane vende la casa del 41,5% venduta.', italian, spanish, F23),
    check('a participle that does not agree with the noun before it keeps its gender', F23,
          'El perro vende la casa del 41,5% vendida.'),
    %% Spanish's apocope, stated in the lesson -- and the feminine, which
    %% states none, is a GUARD: it passes on the translator before this too
    nf_tr('Il primo cane dorme nella grande casa.', italian, spanish, F24),
    check('an adjective before a singular noun takes its apocope', F24, 'El primer perro duerme en la gran casa.'),
    nf_tr('La prima casa dorme.', italian, spanish, F25),
    check('... only the form the lesson states one for', F25, 'La primera casa duerme.'),
    %% there are -- a guard as well: the plural is the lesson's line, `"hay"
    %% is the plural of "hay"', and no code moved for it -- and now
    nf_tr('Ci sono cani.', italian, spanish, F26),
    check('there are: `hay'' in both numbers, as the lesson states', F26, 'Hay perros.'),
    nf_tr('Ora il cane dorme.', italian, spanish, F27),
    check('a lone word that is an adverb too is the adverb, and crosses as one', F27, 'El perro duerme ahora.'),
    %% the word for `not' is the verb's, never the end of a front
    nf_tr('Alla luce della casa, non dorme.', italian, spanish, F28),
    check('a front never ends in the verb''s denial', F28, 'A la luz de la casa, no duerme.'),
    %% a closing mark at the head of a sentence, and `ever since'
    nf_tr('” Il cane dorme.', italian, spanish, F29),
    check('a closing mark at a sentence''s head goes back in front', F29, '”El perro duerme.'),
    nf_tr('Il cane dorme sin da quando il gatto mangia.', italian, spanish, F30),
    check('a connecting word of several words divides two clauses', F30, 'El perro duerme desde que el gato come.'),
    %% three the controls found, each a rule above read too widely: a word
    %% whose dictionary gave another class first crosses by that order, not
    %% by its preposition link -- `más despacio' is more slowly, never plus
    nf_tr('El perro come más despacio.', spanish, english, F31),
    check('a preposition link is taken only over a first meaning with no class', F31, 'The dog eats more slowly.'),
    %% `de' before an infinitive straight after the verb is the verb's only
    %% where the lesson says the word begins one: Italian's `di' does and
    %% Spanish's `de' does not, and `acaba de comer' is has just eaten
    nf_tr('El perro acaba de comer el pan.', spanish, english, F32),
    check('... and `de'' and an infinitive after a verb are refused where no word begins one', F32, refused),
    %% a reporting clause's speaker after the verb opens on a determiner or
    %% is a name: a bare noun there is the verb's object
    nf_tr('Il cane mangia il pane, ama casa, il gatto dorme.', italian, spanish, F33),
    check('a bare noun after the verb between two commas is its object, and no speaker', F33,
          'El perro come el pan, ama casa, el gato duerme.'),
    %% and an adverb has no plural: `ore' is the hours, never the plural of
    %% the adverb `ora'
    nf_tr('Il cane dorme dalle prime ore.', italian, spanish, F34),
    check('a plural is never an adverb, a preposition or a conjunction', F34,
          'El perro duerme desde las primeras horas.').

% ---- a Spanish article into Italian ------------------------------------------------------
%%
%% A real Spanish article into Italian for the first time the other way from
%% the three before it -- El Periódico of 2 February 2001 on the exhibition
%% of old violins in Valencia, AnCora's CESS-CAST-P-20010202-169, sixteen
%% sentences -- and what it needed is what a report on a show says: a
%% quotation over two sentences in the plain mark a keyboard has, a verb
%% whose sense turns on whether it has an object, a name after `llamado', a
%% year aside, the state copula with a participle, a noun's own clause after
%% `de que', a list of subjects with a relative clause on the last, a number
%% after the noun that is its label, and a partitive's head agreeing with
%% the phrase it is taken from. Each shape is pinned on two small lessons of
%% their own, and every check but the two marked as guards fails on the
%% translator before this.

newspaper_valencia :-
    section('a Spanish article into Italian: plain quotation marks, a verb''s sense by its object, a name after a participle, a noun''s own clause'),
    newspaper_valencia_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_valencia_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_valencia_checks,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_valencia_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "violín" means "violin". "violines" is the plural of "violín".
The noun "constructor" means "builder". "constructores" is the plural of "constructor".
The noun "experto" means "expert". The noun "pan" means "bread".
The noun "diferencia" means "difference". The noun "familia" means "family".
The noun "colección" means "collection". "colección" is feminine.
The noun "máquina" means "machine". The noun "prueba" means "proof".
The noun "día" means "day". "día" is not feminine. "día" is a time.
The noun "vía" means "way". The preposition "vía" means "via".
The adjective "capaz" means "able". The adjective "próximo" means "next". The adjective "ex" means "former".
The adjective "bueno" means "good". The adjective "mejor" means "good". "mejor" is the comparative of "bueno".
The adverb "más" means "more". The word "más" begins the comparative.
The intransitive verb "destaca" means "stands out". The verb "destaca" means "highlights".
"destacó" is the past of "destaca".
The intransitive verb "pasa" means "happens". The verb "pasa" means "passes".
The verb "come" means "eats". "comen" is the plural of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "duerma" is the subjunctive of "duerme".
The verb "dice" means "says".
The verb "llama" means "calls". "llamado" is the participle of "llama".
The verb "considera" means "considers". "considerado" is the participle of "considera".
The verb "expone" means "exposes". "exponen" is the plural of "expone".
The verb "mejora" means "improves". "mejorado" is the participle of "mejora".
The verb "va" means "goes". "van" is the plural of "va".
The verb "es" means "is". "son" is the plural of "es". "sido" is the participle of "es".
"eres" is the second person of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha". "ha" is the auxiliary of "es".
The auxiliary "está" means "is". "están" is the plural of "está".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The feminine pronoun "alguna" means "some". "algunas" is the plural of "alguna".
The pronoun "alguna" does not precede the verb.
The reflexive pronoun "se" means "itself". The pronoun "la" means "her". The pronoun "lo" means "him".
Every pronoun precedes the verb. "que" is a relative. The conjunction "que" means "that". The word "de" begins the clause.
The conjunction "sin que" means "without".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in".
The preposition "como" means "as". The conjunction "y" means "and".
The word "no" means "not".').
newspaper_valencia_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a". The masculine article "uno" means "a".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i".
"delle" is the contraction of "di le". "nella" is the contraction of "in la". "nel" is the contraction of "in il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The article "il" takes the year.
The noun "violino" means "violin". "violini" is the plural of "violino".
The noun "costruttore" means "builder". "costruttori" is the plural of "costruttore".
The noun "esperto" means "expert". The noun "pane" means "bread".
The noun "differenza" means "difference". "differenze" is the plural of "differenza".
The noun "famiglia" means "family". The noun "collezione" means "collection". "collezione" is feminine.
The noun "macchina" means "machine". The noun "prova" means "proof".
The noun "giorno" means "day". "giorno" is a time. The noun "via" means "way".
The adjective "capace" means "able". The adjective "prossimo" means "next". The adjective "ex" means "former".
The adjective "buono" means "good". The adjective "migliore" means "good". "migliore" is the comparative of "buono".
The adverb "più" means "more". The word "più" begins the comparative.
The intransitive verb "spicca" means "stands out". The verb "evidenzia" means "highlights".
"evidenziò" is the past of "evidenzia".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "dice" means "says".
The verb "chiama" means "calls". "chiamato" is the participle of "chiama".
The verb "considera" means "considers". "considerato" is the participle of "considera".
The verb "espone" means "exposes". "espongono" is the plural of "espone".
The verb "migliora" means "improves". "migliorato" is the participle of "migliora".
The verb "è" means "is". "sono" is the plural of "è". "sei" is the second person of "è".
"stato" is the participle of "è". "stata" is the participle of "è". "stata" is feminine.
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "è" is the auxiliary of "è".
The impersonal pronoun "si" means "one".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The masculine pronoun "alcuno" means "some". "alcuni" is the plural of "alcuno".
The feminine determiner "alcuna" means "some". The feminine pronoun "alcuna" means "some".
"alcune" is the plural of "alcuna".
The pronoun "alcuno" does not precede the verb. The pronoun "alcuna" does not precede the verb.
The reflexive pronoun "si" means "itself". Every pronoun precedes the verb.
"che" is a relative. The conjunction "che" means "that".
The conjunction "senza che" means "without".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in".
The preposition "come" means "as". The conjunction "e" means "and".
The word "non" means "not".').

newspaper_valencia_checks :-
    %% the plain quotation mark: where it stands says which it is
    nf_tr('"El constructor come el pan.', spanish, italian, V1),
    check('a plain mark that no mark closes goes in front of its sentence', V1, '"Il costruttore mangia il pane.'),
    nf_tr('El constructor come el pan ", dice la familia.', spanish, italian, V2),
    check('... and one that closes nothing divides the quotation from its reporting clause, its comma kept', V2,
          'Il costruttore mangia il pane", dice la famiglia.'),
    %% `sin que' is a conjunction, never a relative after a preposition
    nf_tr('El constructor come el pan sin que la familia duerma.', spanish, italian, V3),
    check('a connecting word of two words: without a clause', V3,
          'Il costruttore mangia il pane senza che la famiglia dorme.'),
    %% a verb's sense by whether its clause has an object
    nf_tr('En la colección, destaca un violín.', spanish, italian, V4),
    check('with no object the verb takes its intransitive meaning, and the phrase after it is its subject', V4,
          'Nella collezione, un violino spicca.'),
    %% (a GUARD: the translator before this took the same meaning, because
    %% the intransitive one is not shaped like a third person)
    nf_tr('El constructor destaca las diferencias.', spanish, italian, V5),
    check('... and with one the first meaning that is not it', V5, 'Il costruttore evidenzia le differenze.'),
    nf_tr('En la colección, destaca un violín.', spanish, english, V6),
    check('... which English says as the lesson gave it', V6, 'In the collection, a violin stands out.'),
    %% the adjective is its sentence's: a second meaning in the same lesson is
    %% not intransitive because the first was, or `happens' took the object
    nf_tr('El constructor pasa el pan.', spanish, english, V24),
    check('... and only the meaning its own sentence calls intransitive is', V24, 'The builder passes the bread.'),
    %% a partitive's head agrees with the noun it is taken from
    nf_tr('El constructor destacó algunas de las diferencias.', spanish, italian, V7),
    check('a partitive: the head agrees with the noun of its phrase', V7, 'Il costruttore evidenziò alcune delle differenze.'),
    nf_tr('Uno de los violines duerme.', spanish, italian, V8),
    check('... and `uno'' is the pronoun, never the impersonal `si''', V8, 'Uno dei violini dorme.'),
    %% a noun that is a preposition too, after its article
    nf_tr('El constructor duerme en la vía.', spanish, italian, V9),
    check('a noun that is a preposition too does not end the phrase after its article', V9,
          'Il costruttore dorme nella via.'),
    %% a name after `llamado', whole, spelled as the source spelled it
    nf_tr('Un violín llamado Ex VieuxTemps duerme.', spanish, italian, V10),
    check('a name after a participle is its object, a word the lesson knows among its words', V10,
          'Un violino chiamato Ex VieuxTemps dorme.'),
    %% a year after a comma is the thing's, and Italian gives it the article
    nf_tr('Un violín, de 1736, duerme.', spanish, italian, V11),
    check('a year between a comma and a comma stands aside, and takes the article the lesson names', V11,
          'Un violino, del 1736, dorme.'),
    nf_tr('Un violino del 1736 dorme.', italian, spanish, V12),
    check('... and read back the article comes off', V12, 'Un violín de 1736 duerme.'),
    %% the state copula with a participle is a passive, not a perfect
    nf_tr('El constructor está considerado.', spanish, italian, V13),
    check('the copula of a state and a participle is a passive', V13, 'Il costruttore è considerato.'),
    %% an article before a capitalised run whose last word no lesson knows
    nf_tr('El constructor es el Van Gogh de la familia.', spanish, italian, V14),
    check('a capitalised run after an article is a name though the lesson knows a word of it', V14,
          'Il costruttore è il Van Gogh della famiglia.'),
    %% the copula's own perfect is built with the copula in Italian -- a
    %% guard as well: it is the lesson's line, `"è" is the auxiliary of
    %% "è".', and no code moved for it
    nf_tr('La máquina ha sido capaz.', spanish, italian, V15),
    check('the copula''s perfect is built as its passive perfect is', V15, 'La macchina è stata capace.'),
    %% a relative clause with its reflexive, inside a subject -- and an
    %% auxiliary is no phrase's noun, so `han mejorado' after the clause is
    %% the sentence's own verb (the text alone could not tell: read with
    %% `han' for a noun the words came out the same)
    nf_tr('Los violines que se exponen duermen.', spanish, italian, V16),
    check('a reflexive inside a subject''s relative clause is the clause''s', V16,
          'I violini che si espongono dormono.'),
    ( reason_ir('Los violines que se exponen han mejorado.', spanish, [ir(s(_, _, g(L17, _, A17, _), _), _)]) -> V17 = L17-A17 ; V17 = none ),
    check('... and the auxiliary after it is the sentence''s perfect, never a noun', V17, improves-perfect),
    %% ... and an OBJECT pronoun there is the clause's too, where it refused
    %% the subject -- so long as the clause opens no further clause, which
    %% is what kept Livata's twenty-seven words from being a subject
    nf_tr('Los constructores que lo exponen duermen.', spanish, english, V25),
    check('an object pronoun inside a subject''s relative clause is the clause''s too', V25,
          'The builders that expose him sleep.'),
    %% a noun's own clause, and the clause after the comma is the next one
    nf_tr('Como prueba de que los violines duermen, los constructores comen el pan.', spanish, italian, V18),
    check('a noun''s own clause after `de que'', ending at the comma', V18,
          'Come prova che i violini dormono, i costruttori mangiano il pane.'),
    %% a number after a noun is its label, and a time phrase after a comma
    nf_tr('Los constructores comen el pan, el próximo día 14.', spanish, italian, V19),
    check('a number after its noun is the noun''s label, and the phrase a time', V19,
          'I costruttori mangiano il pane, il prossimo giorno 14.'),
    %% a comparative that is a word of its own, read and written as one: the
    %% dictionary gives `mejor' and `migliore' only as `good'
    nf_tr('El mejor de los constructores come el pan.', spanish, italian, V20),
    check('a comparative that is a word of its own, with the article the superlative', V20,
          'Il migliore dei costruttori mangia il pane.'),
    nf_tr('El mejor de los constructores come el pan.', spanish, english, V21),
    check('... which English writes with its own ending', V21, 'The best of the builders eats the bread.'),
    nf_tr('La máquina es la mejor.', spanish, italian, V22),
    check('... and after an article that is a pronoun too, the article''s and no pronoun', V22,
          'La macchina è la migliore.'),
    nf_tr('Eres la más capaz.', spanish, italian, V23),
    check('... as it is before `más'' and an adjective', V23, 'Sei la più capace.').

% ---- the lesson questioned ---------------------------------------------------------

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
    check('the word for not', B6, [not-fact]),
    reason_ask('What is the first person of "come"? Is "comes" the second person of "come"? What is the past of "come"?', Cs),
    Cs = [C1, C2, C3],
    check('the first person of: the relation, and the adjective as a condition', C1, [como-fact]),
    check('is the second person of: yes', C2, yes(fact)),
    check('the past of', C3, ['comió'-fact]).

newspaper_bio :-
    section('an Italian report into Spanish: a dateline, a relative after a comma, a headline colon, the passive of venire and andare'),
    newspaper_bio_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_bio_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_bio_checks,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_bio_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "comité" means "committee". The noun "estado" means "state". The noun "derecho" means "right".
The noun "terapia" means "therapy". The noun "cura" means "cure". The noun "forma" means "form".
The noun "eutanasia" means "euthanasia". The noun "capítulo" means "chapter".
The noun "experimentación" means "experimentation". "experimentación" is feminine.
The noun "familia" means "family". The noun "paciente" means "patient". The noun "asentimiento" means "assent".
The noun "tiempo" means "time". The noun "modo" means "way".
The adjective "ético" means "ethical". The determiner "cada" means "each".
The verb "resume" means "summarises". The verb "protege" means "protects".
The verb "favorece" means "favours". "favorecer" is the infinitive of "favorece".
The verb "excluye" means "excludes". "excluido" is the participle of "excluye". "excluida" is the participle of "excluye".
"excluida" is feminine.
The verb "activa" means "activates". "activado" is the participle of "activa". "activada" is the participle of "activa".
"activadas" is the participle of "activa". "activados" is the participle of "activa".
"activada" is feminine. "activadas" is feminine. "activadas" is the plural of "activada". "activados" is the plural of "activado".
The verb "duerme" means "sleeps". The verb "lleva" means "brings". The verb "tiene" means "has".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es". "sido" is the participle of "es".
The auxiliary "ha" means "has". "ha" is the auxiliary of "es".
The modal "tiene que" means "must". "tienen que" is the plural of "tiene que".
The verb "hay" means "there is".
The conjunction "y" means "and". The conjunction "si" means "if". The conjunction "porque" means "because".
The conjunction "de modo que" means "so that".
The adverb "ni siquiera" means "not even". The adverb "no" means "no".
"que" is a relative. The conjunction "que" means "that".
The preposition "a" means "to". The preposition "de" means "of". The preposition "con" means "with".
The word "no" means "not".').
newspaper_bio_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a". The masculine article "lo" means "the".
"l''" is the elision of "il". "l''" is the elision of "la". "all''" is the elision of "alla".
"alla" is the contraction of "a la". "al" is the contraction of "a il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "comitato" means "committee". The noun "stato" means "state". The noun "diritto" means "right".
The noun "terapia" means "therapy". The noun "cura" means "cure". The noun "forma" means "form".
The noun "eutanasia" means "euthanasia". The noun "capitolo" means "chapter".
The noun "sperimentazione" means "experimentation". "sperimentazione" is feminine.
The noun "famiglia" means "family". The noun "malato" means "patient". The noun "assenso" means "assent".
The noun "tempo" means "time". "tempi" is the plural of "tempo". The noun "modo" means "way". "modi" is the plural of "modo".
The adjective "etico" means "ethical". The determiner "ogni" means "each".
The verb "riassume" means "summarises". The verb "protegge" means "protects".
The verb "favorisce" means "favours". "favorire" is the infinitive of "favorisce".
The verb "esclude" means "excludes". "esclusa" is the participle of "esclude". "esclusa" is feminine.
The verb "attiva" means "activates". "attivata" is the participle of "attiva". "attivata" is feminine.
"attivate" is the participle of "attiva". "attivate" is feminine. "attivate" is the plural of "attivata".
The verb "dorme" means "sleeps". The verb "porta" means "brings". The verb "ha" means "has".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è".
The verb "viene" means "comes". The verb "viene" marks the passive.
The verb "va" means "goes". "vanno" is the plural of "va". The verb "va" marks the duty.
The modal "deve" means "must". The verb "deve" means "owes".
The verb "vi è" means "there is". "vi sia" is the subjunctive of "vi è".
The conjunction "e" means "and". The conjunction "se" means "if". The conjunction "perché" means "because".
The conjunction "in modo che" means "so that".
The adverb "neanche" means "not even". The adverb "no" means "no".
"che" is a relative. The conjunction "che" means "that".
The preposition "a" means "to". The preposition "di" means "of". The preposition "con" means "with".
The word "non" means "not".').

newspaper_bio_checks :-
    %% a dateline: the place a report was filed from and a dash, then the
    %% sentence, which read as a reporting clause had a lone name for a clause
    nf_tr('Roma - lo stato ha il diritto di favorire la famiglia.', italian, spanish, B1),
    check('a dateline: a place and a dash before the sentence, written back where it stood', B1,
          'Roma – el estado tiene el derecho de favorecer la familia.'),
    %% a relative clause after a comma is the phrase's, never a `that' clause
    %% (a GUARD in Spanish: read as the verb's `that' clause with nobody for
    %% its subject, the words came out the same; English and the IR did not)
    nf_tr('Un capitolo riassume la sperimentazione, che protegge la famiglia.', italian, spanish, B2),
    check('a relative clause after a comma says more of the phrase before it', B2,
          'Un capítulo resume la experimentación, que protege la familia.'),
    nf_tr('Un capitolo riassume la sperimentazione, che protegge la famiglia.', italian, english, B3),
    check('... and English says it with `which''', B3, 'A chapter summarises the experimentation, which protects the family.'),
    ( reason_ir('Un capitolo riassume la sperimentazione, che protegge la famiglia.', italian, [ir(s(_, _, _, [obj(nrc(_, R4, _))]), _)]) -> B4 = R4 ; B4 = none ),
    check('... the relative word the clause''s subject', B4, subject),
    %% a headline colon: neither side has a verb
    nf_tr('Il comitato: no all''eutanasia.', italian, spanish, B5),
    check('a headline colon: who speaks, and what they say, and no verb on either side', B5,
          'El comité: no a la eutanasia.'),
    %% the passive of `venire', and its subject after it
    nf_tr('Viene esclusa ogni forma di eutanasia.', italian, spanish, B6),
    check('the verb the lesson says marks the passive builds one, its subject after it', B6,
          'Es excluida cada forma de eutanasia.'),
    nf_tr('Viene esclusa ogni forma di eutanasia.', italian, english, B7),
    check('... which English writes first', B7, 'Each form of euthanasia is excluded.'),
    %% the passive of `andare' is what must be done
    nf_tr('La terapia va attivata.', italian, spanish, B8),
    check('the verb the lesson says marks the duty: must be, and the participle', B8, 'La terapia tiene que ser activada.'),
    nf_tr('Vanno attivate la terapia e la cura.', italian, spanish, B9),
    check('... its subject after it, two feminine phrases agreeing as feminine', B9,
          'Tienen que ser activadas la terapia y la cura.'),
    nf_tr('Vanno attivate la terapia e la cura.', italian, english, B10),
    check('... and English''s `must be''', B10, 'The therapy and the cure must be activated.'),
    %% a verb the lesson also calls a modal is the modal before an infinitive
    nf_tr('La terapia deve essere attivata.', italian, english, B11),
    check('a verb that is a modal too is the modal before an infinitive', B11, 'The therapy must be activated.'),
    %% two feminine phrases joined agree as feminine
    nf_tr('La terapia e la cura sono attivate.', italian, spanish, B12),
    check('two feminine subjects joined: the participle feminine', B12, 'La terapia y la cura son activadas.'),
    %% `neanche se vi sia': not even, if, there is
    nf_tr('La forma viene esclusa, neanche se vi sia l''assenso.', italian, spanish, B13),
    check('`if'' joins two clauses, and `vi sia'' is there is', B13,
          'La forma es excluida, ni siquiera si hay el asentimiento.'),
    %% a comma before a subordinating word is the source's
    nf_tr('Il malato dorme, perché la terapia protegge il malato.', italian, spanish, B14),
    check('a comma before a subordinating word is written back', B14,
          'El paciente duerme, porque la terapia protege el paciente.'),
    nf_tr('La terapia va attivata, in modo che il malato dorme.', italian, spanish, B15),
    check('... and a connecting word of three words, so that', B15,
          'La terapia tiene que ser activada, de modo que el paciente duerme.'),
    %% a noun in the other number begins the next phrase
    nf_tr('Il comitato porta al comitato etico tempi e modi.', italian, spanish, B16),
    check('a noun in the other number after a phrase with its noun begins the next phrase', B16,
          'El comité lleva al comité ético tiempos y modos.'),
    %% two the controls found: a front goes before the phrase that carries a
    %% relative clause after a comma, or it reads as the clause's own
    nf_tr('Con la terapia il comitato protegge la famiglia, che dorme.', italian, spanish, B17),
    check('a front goes before the phrase a relative clause after a comma is on', B17,
          'El comité protege con la terapia la familia, que duerme.'),
    %% ... and a clause after a subordinating word is no question of its own
    nf_tr('¿Y si el paciente duerme?', spanish, english, B18),
    check('a clause after `if'' keeps the statement''s order in a question', B18, 'And if the patient sleeps?').

%% ---- a Spanish football report into Italian -----------------------------------------
%%
%% El Periódico, 3 January 2001 -- the AnCora document CESS-CAST-P-20010103-120,
%% twenty sentences of Barça before a cup tie at Ceuta -- into Italian needed
%% what the four articles before it did not: a list that is the subject of a
%% clause after a comma, a comma that parts two names, a subordinate clause
%% at the head with an insertion after its word, more than an adjective, a
%% comparison with a phrase, a denial before its verb kept there, `ni ... ni',
%% the impersonal modal, a verb's own preposition before its infinitive, and a
%% determiner and a pronoun chosen in the lesson's order. Every check but the
%% last three fails on the 1.7.2 translator; the last three pass on it and
%% fail on 1.8.0's, which is what the controls found 1.8.0 had broken
%% (1.8.1).

newspaper_football :-
    section('a Spanish football report into Italian: lists, names a comma parts, more than, ni ... ni, hay que'),
    newspaper_football_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_football_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_football_checks,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_football_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a". "unos" is the plural of "un".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread".
"panes" is the plural of "pan".
The noun "casa" means "house". The noun "equipo" means "team". The noun "fútbol" means "football".
The noun "entrenador" means "coach". "entrenador" is a person.
The noun "decisión" means "decision". "decisión" is feminine. "decisiones" is the plural of "decisión".
The noun "elección" means "choice". "elección" is feminine.
The noun "ronda" means "round". The noun "plan" means "plan". "planes" is the plural of "plan".
The adjective "bueno" means "good". "buen" is the apocope of "bueno".
The adjective "grande" means "big". The adjective "cuestionable" means "questionable".
The adjective "idéntico" means "identical".
The adjective "anterior" means "previous". The adjective "anterior" means "anterior".
The adjective "primero" means "first". "primeros" is the plural of "primero".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
"comido" is the participle of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormido" is the participle of "duerme".
"duermo" is the first person of "duerme". "duerme" is intransitive. "como" is the first person of "come".
The number "dos" means "two". The reflexive pronoun "se" means "itself".
The verb "confía" means "trusts". "confía" takes "en" before the infinitive.
The intransitive verb "gusta" means "pleases". The verb "gusta" means "likes".
The transitive verb "conoce" means "knows". "conozco" is the first person of "conoce".
The verb "resulta" means "results".
The verb "tiene" means "has". "tienen" is the plural of "tiene".
The verb "queda" means "stays". "queda" is reflexive. "quedado" is the participle of "queda".
The verb "optará" means "will opt". The verb "parece" means "seems".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es". "sido" is the participle of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha". "he" is the first person of "ha".
The impersonal modal "hay que" means "must".
The verb "dice" means "says". "dijo" is the past of "dice". "dicho" is the participle of "dice".
The preposition "más" means "plus". The pronoun "los" means "them".
The pronoun "le" means "him". The dative pronoun "le" means "him".
The pronoun "todos" means "everyone". The pronoun "todos" does not precede the verb.
The pronoun "esto" means "this". The pronoun "esto" does not precede the verb.
The masculine demonstrative "este" means "this". The pronoun "este" means "this". The pronoun "este" does not precede the verb.
Every pronoun precedes the verb.
The determiner "cualquiera" means "any". "cualquier" is the apocope of "cualquiera".
The conjunction "y" means "and". The conjunction "ni" means "neither". The conjunction "ni" means "nor".
The conjunction "al margen de que" means "apart from the fact that".
The conjunction "con lo que" means "so".
"que" is a relative. The conjunction "que" means "that". The conjunction "que" means "than".
The word "más" begins the comparative. The adverb "más" means "more". The verb "hay" means "there is".
The word "el" replaces the noun.
The adverb "tampoco" means "neither". The adverb "curiosamente" means "curiously". The adverb "probable" means "probable".
The adjective "probable" means "probable".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in".
The preposition "con" means "with". The preposition "por" means "by". The preposition "por" means "for". The preposition "salvo" means "except".
The noun "jugador" means "player". "jugador" is a person. "jugadores" is the plural of "jugador".
The verb "reclama" means "demands". "reclamado" is the participle of "reclama".
The verb "da" means "gives". "dado" is the participle of "da". The dative pronoun "les" means "them".
The noun "afán" means "eagerness". "afán" is masculine.
The preposition "como" means "like". The word "como" means "as".
The word "a" precedes the person.
The word "no" means "not".').
newspaper_football_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a". "dei" is the plural of "un".
"l''" is the elision of "il". "l''" is the elision of "la".
"al" is the contraction of "a il". "del" is the contraction of "di il". "nel" is the contraction of "in il".
"della" is the contraction of "di la". "grandi" is the plural of "grande".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". The noun "casa" means "house". The noun "squadra" means "team".
The noun "calcio" means "football".
The noun "allenatore" means "coach". "allenatore" is a person.
The noun "decisione" means "decision". "decisione" is feminine.
The noun "scelta" means "choice". The noun "turno" means "round". The noun "piano" means "plan". "piani" is the plural of "piano".
The adjective "buono" means "good". "buon" is the apocope of "buono".
The adjective "grande" means "big". The adjective "discutibile" means "questionable".
The adjective "identico" means "identical". "identici" is the plural of "identico".
The adjective "precedente" means "previous". The adjective "anteriore" means "anterior".
The adjective "primo" means "first". "primi" is the plural of "primo".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangiato" is the participle of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormito" is the participle of "dorme".
"dorme" is intransitive. The number "due" means "two". The reflexive pronoun "si" means "itself".
The verb "confida" means "trusts". "confida" takes "di" before the infinitive.
The intransitive verb "piace" means "pleases".
The verb "sa" means "knows". The transitive verb "conosce" means "knows". "conosco" is the first person of "conosce".
The verb "risulta" means "results".
The verb "ha" means "has". "hanno" is the plural of "ha".
The verb "rimane" means "stays". "rimane" is not reflexive. "rimasto" is the participle of "rimane".
"è" is the auxiliary of "rimane".
The verb "opterà" means "will opt". The verb "sembra" means "seems".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è". "stato" is the participle of "è".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "ho" is the first person of "ha".
The impersonal modal "bisogna" means "must".
The verb "dice" means "says". "disse" is the past of "dice". "detto" is the participle of "dice".
The word "di" begins the infinitive.
The dative pronoun "gli" means "him".
The pronoun "tutti" means "everyone". The pronoun "tutti" does not precede the verb.
The pronoun "questo" means "this". The pronoun "questo" does not precede the verb.
The masculine demonstrative "questo" means "this".
The pronoun "codesto" means "this". The pronoun "codesto" does not precede the verb.
Every pronoun precedes the verb.
The determiner "qualsiasi" means "any". The masculine determiner "molto" means "any".
The conjunction "e" means "and". The conjunction "né" means "neither". The conjunction "né" means "nor".
The conjunction "a parte il fatto che" means "apart from the fact that".
The conjunction "per cui" means "so".
"che" is a relative. The conjunction "che" means "that". The conjunction "che" means "than".
The word "di" means "than".
The word "più" begins the comparative. The adverb "più" means "more".
The masculine pronoun "quello" means "that". "quelli" is the plural of "quello".
The adverb "neanche" means "neither". The adverb "curiosamente" means "curiously". The adjective "probabile" means "probable".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in".
The preposition "con" means "with". The preposition "da" means "by". The preposition "per" means "for". The preposition "eccetto" means "except".
The noun "giocatore" means "player". "giocatore" is a person. "giocatori" is the plural of "giocatore".
The verb "reclama" means "demands". "reclamato" is the participle of "reclama".
The verb "dà" means "gives". "dato" is the participle of "dà". The dative pronoun "gli" means "them".
The noun "smania" means "eagerness".
"ai" is the contraction of "a i". "dell''" is the elision of "del".
The preposition "come" means "like". The word "come" means "as".
The word "non" means "not".').

newspaper_football_checks :-
    %% more than an adjective: the comparative word, the lesson's `than' and
    %% an adjective with no phrase after it (a GUARD into Italian: read as a
    %% phrase whose noun was `que', the words came out the same; English and
    %% the IR did not)
    nf_tr('La elección resulta más que cuestionable.', spanish, italian, G1),
    check('more than an adjective: the lesson''s comparative word and its conjunction for than', G1,
          'La scelta risulta più che discutibile.'),
    nf_tr('La elección resulta más que cuestionable.', spanish, english, G2),
    check('... and English''s more than', G2, 'The choice results more than questionable.'),
    %% a comparison with a phrase: Italian's `di' before a phrase, `che' before an adjective
    nf_tr('El gato es más grande que el perro.', spanish, italian, G3),
    check('a comparison with a phrase: the lesson''s word for than that is no conjunction', G3,
          'Il gatto è più grande del cane.'),
    nf_tr('El gato tiene idénticos planes que el perro.', spanish, italian, G4),
    check('... and one after a word meaning identical', G4, 'Il gatto ha identici piani del cane.'),
    ( reason_ir('El gato tiene idénticos planes que el perro.', spanish, [ir(s(_, _, _, Cs5), _)]), memberchk(cmp(K5, _), Cs5) -> G5 = K5 ; G5 = none ),
    check('... which the IR carries as an equal comparison', G5, equal),
    %% a subordinate clause at the head, and an insertion after its word
    nf_tr('Al margen de que, como todos, han comido pan, el perro duerme.', spanish, italian, G6),
    check('a comma after a connecting word at the head opens an insertion, which is its clause''s', G6,
          'A parte il fatto che, come tutti, hanno mangiato pane, il cane dorme.'),
    %% two names after a comma are the subject of a clause of their own
    nf_tr('Han comido pan, Rivaldo y Overmars no duermen.', spanish, italian, G7),
    check('two names and a verb after a comma are a clause, never the end of a list', G7,
          'Hanno mangiato pane, Rivaldo e Overmars non dormono.'),
    nf_tr('Salvo la decisión de Rivaldo y Overmars, Serra Ferrer come pan y ha dormido.', spanish, italian, G8),
    check('a comma between two names parts them, and a front ends there', G8,
          'Eccetto la decisione di Rivaldo e Overmars, Serra Ferrer mangia pane e ha dormito.'),
    %% an English meaning in -us is no third person
    nf_tr('El perro come la ronda anterior.', spanish, italian, G9),
    check('previous is no verb''s third person in an adjective''s place', G9, 'Il cane mangia il turno precedente.'),
    %% the lesson's order among the words that agree
    nf_tr('Esto es grande.', spanish, italian, G10),
    check('a pronoun whose first sentence was a pronoun''s comes first', G10, 'Questo è grande.'),
    nf_tr('El perro come cualquier pan.', spanish, italian, G11),
    check('a determiner of no gender in the lesson''s order before a masculine one', G11, 'Il cane mangia qualsiasi pane.'),
    %% a verb's own preposition before its infinitive
    nf_tr('El perro confía en comer pan.', spanish, italian, G12),
    check('the preposition the lesson says a verb takes before its infinitive', G12, 'Il cane confida di mangiare pane.'),
    %% the intransitive verb whose subject stands after it, and an apocope
    nf_tr('Le gusta el buen fútbol.', spanish, italian, G13),
    check('gustar: a dative before the verb, the subject after it, and buen the apocope of bueno', G13,
          'Gli piace il buon calcio.'),
    nf_tr('Le gusta el buen fútbol.', spanish, english, G13b),
    check('... and the verb''s intransitive sense, the pronoun before it being no object', G13b,
          'The good football pleases him.'),
    %% the impersonal modal, in a quotation that closes at a comma
    nf_tr('"Hay que comer pan", dijo.', spanish, italian, G14),
    check('the impersonal modal, and a quotation that opens the sentence and closes at a comma', G14,
          '"Bisogna mangiare pane", disse.'),
    %% a verb's sense with a phrase for its object
    nf_tr('Conozco al entrenador.', spanish, italian, G15),
    check('the transitive sense the lesson gives: knows a person', G15, 'Conosco l''allenatore.'),
    %% ni ... ni, before the verb and after it
    nf_tr('Ni el perro ni el gato duermen.', spanish, italian, G16),
    check('a list that begins with its own connector: neither ... nor', G16, 'Né il cane né il gatto dormono.'),
    nf_tr('No duermen ni el perro ni el gato.', spanish, italian, G17),
    check('... and after an intransitive verb, which denies it', G17, 'Non dormono né il cane né il gatto.'),
    %% a denying adverb before its verb stays there
    nf_tr('El perro tampoco duerme.', spanish, italian, G18),
    check('a denying adverb before its verb is written in front', G18, 'Neanche il cane dorme.'),
    %% a clause in parentheses
    nf_tr('El perro duerme (el gato come pan).', spanish, italian, G19),
    check('a clause in parentheses is an aside of its own', G19, 'Il cane dorme (il gatto mangia pane).'),
    %% a denial after a relative clause that has had its verb is the sentence's
    nf_tr('Los perros que comen pan no duermen.', spanish, italian, G20),
    check('a denial after a relative clause that has its verb denies the sentence''s', G20,
          'I cani che mangiano pane non dormono.'),
    %% a count with its noun left out
    nf_tr('Los dos primeros duermen.', spanish, italian, G21),
    check('a count and an adjective with the noun left out', G21, 'I due primi dormono.'),
    %% a verb the lesson says is not reflexive writes no `si'
    nf_tr('El perro se ha quedado en casa.', spanish, italian, G22),
    check('a reflexive verb whose meaning is not reflexive in Italian, with its own auxiliary', G22,
          'Il cane è rimasto in casa.'),
    %% a comment between commas
    nf_tr('El perro optará, como parece probable, por comer pan.', spanish, italian, G23),
    check('a comment between two commas is written after the sentence', G23,
          'Il cane opterà per mangiare pane, come sembra probabile.'),
    %% `el que': the article with its noun left out and a relative clause
    nf_tr('El gato come un pan como el que come el perro.', spanish, italian, G24),
    check('an article and a relative clause with the noun left out: Italian''s pronoun for that', G24,
          'Il gatto mangia un pane come quello che mangia il cane.'),
    %% a person marked as the object before a second object is the indirect one
    nf_tr('El entrenador ha reclamado a los jugadores la decisión.', spanish, italian, G25),
    check('the word before a person, and a second object after it: to the players', G25,
          'L''allenatore ha reclamato ai giocatori la decisione.'),
    %% a preposition crosses by the first meaning that is not the agent's
    nf_tr('El perro duerme por decisión del entrenador.', spanish, italian, G26),
    check('por with no passive is for, never the agent''s by', G26, 'Il cane dorme per decisione dell''allenatore.'),
    %% an infinitive with its object inside the subject
    nf_tr('El afán por comer pan es grande.', spanish, italian, G27),
    check('a subject carries an infinitive and its object', G27, 'La smania per mangiare pane è grande.'),
    %% three the controls found in 1.8.0 (1.8.1): Italian's `di' is `than'
    %% only where Spanish's comparisons are written, never where it is read
    nf_tr('Il cane mangia il pane del gatto.', italian, spanish, G28),
    check('an Italian `di'' after a noun is `of'', never a comparison', G28, 'El perro come el pan del gato.'),
    %% ... a superlative is not split at `más', the preposition `plus' too
    nf_tr('Los más grandes perros de la casa duermen.', spanish, italian, G29),
    check('an article alone is no phrase before a preposition in a subject', G29,
          'I cani più grandi della casa dormono.'),
    %% ... and the verb's own `di' before an infinitive is the verb's
    nf_tr('Il cane ha detto al gatto di mangiare il pane.', italian, spanish, G30),
    check('a word the lesson says begins the infinitive is not the phrase''s before it', G30,
          'El perro ha dicho al gato comer el pan.').

%% ---- an Italian report into Spanish: a court, a title and a cleft (1.8.2) ----------------

%% the Monreale article, Italian UD VIT-9465..9470: a headline's command, a
%% place before a comma, a title before a name, a subject after its modal
%% and its adjuncts, a cleft, an absolute superlative, the conditional
%% perfect and an aside between the subject and its verb. Every check but
%% the four marked GUARD fails on the 1.8.1 translator.
newspaper_monreale :-
    section('an Italian report into Spanish: a command, a title, a subject after its verb, a cleft'),
    newspaper_monreale_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_monreale_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_monreale_checks,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_monreale_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
"l''" is the elision of "il". "l''" is the elision of "la".
"al" is the contraction of "a il". "del" is the contraction of "di il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat".
The noun "pane" means "bread". "pani" is the plural of "pane".
The noun "vescovo" means "bishop". "vescovo" is a person.
The noun "procura" means "prosecution".
The noun "monsignore" means "monsignor". "monsignor" is the apocope of "monsignore". "monsignore" is a title.
The adjective "pesante" means "heavy". "pesanti" is the plural of "pesante".
"pesantissimo" is the superlative of "pesante". "pesantissimi" is the superlative of "pesanti".
The adverb "molto" means "very".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangiato" is the participle of "mangia".
"mangiata" is the participle of "mangia". "mangiata" is feminine.
"mangiate" is the participle of "mangia". "mangiate" is feminine. "mangiate" is the plural of "mangiata".
"mangia" is the imperative of "mangia". "mangiare" is the negative imperative of "mangia".
"mangiate" is the imperative of "mangiano".
"mangiati" is the participle of "mangia". "mangiati" is the plural of "mangiato".
The verb "gioca" means "plays". "giocano" is the plural of "gioca".
The verb "ordina" means "orders". "ordinato" is the participle of "ordina".
"ordinati" is the participle of "ordina". "ordinati" is the plural of "ordinato".
The verb "vuole" means "wants". "vogliono" is the plural of "vuole".
The verb "chiede" means "asks". "chiedere" is the infinitive of "chiede".
The intransitive verb "finisce" means "ends up". "finire" is the infinitive of "finisce".
The modal "deve" means "must".
The verb "gonfia" means "inflates". "gonfiato" is the participle of "gonfia".
The verb "è" means "is". "sono" is the plural of "è". "stato" is the participle of "è". "sarà" is the future of "è".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "avrebbe" is the conditional of "ha".
The pronoun "lo" means "it". Every pronoun precedes the verb.
"che" is a relative. The conjunction "che" means "that". The conjunction "e" means "and".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in".
The preposition "secondo" means "according to".
"ate" is the past of "eats". "eaten" is the participle of "eats".
The adverb "in tribunale" means "in court".
The word "a" begins the cleft.
The word "non" means "not".').
newspaper_monreale_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "obispo" means "bishop". "obispo" is a person.
The noun "fiscalía" means "prosecution".
The noun "monseñor" means "monsignor". "monseñor" is a title.
The adjective "pesado" means "heavy". "pesados" is the plural of "pesado".
The adverb "muy" means "very".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
"comido" is the participle of "come".
"come" is the imperative of "come". "comas" is the negative imperative of "come".
"comed" is the imperative of "comen". "comáis" is the negative imperative of "comen".
"comidos" is the participle of "come". "comidos" is the plural of "comido".
The verb "juega" means "plays". "juegan" is the plural of "juega".
The verb "ordena" means "orders". "ordenado" is the participle of "ordena".
"ordenados" is the participle of "ordena". "ordenados" is the plural of "ordenado".
The adjective "ordenado" means "orderly".
The adjective "contento" means "happy". The adjective "gracioso" means "funny".
"graciosísimo" is the superlative of "gracioso".
The verb "quiere" means "wants". "quieren" is the plural of "quiere".
The verb "pide" means "asks".
The intransitive verb "acaba" means "ends up". "acabar" is the infinitive of "acaba".
The modal "debe" means "must".
The verb "hincha" means "inflates". "hinchado" is the participle of "hincha".
The verb "es" means "is". "son" is the plural of "es". "sido" is the participle of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha". "habría" is the conditional of "ha".
"ha" is the auxiliary of "es".
The auxiliary "está" means "is". "estate" is the imperative of "está".
The pronoun "lo" means "it". Every pronoun precedes the verb.
"que" is a relative. The conjunction "que" means "that". The conjunction "y" means "and".
"ate" is the past of "eats". "eaten" is the participle of "eats".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in".
The preposition "según" means "according to".
The adverb "ante los tribunales" means "in court".
The word "a" precedes the person.
The word "no" means "not".').

newspaper_monreale_checks :-
    %% a place before a comma at the head is a topic, not an object: no word
    %% before a person in front of it
    nf_tr('Monreale, i cani vogliono il pane.', italian, spanish, M1),
    check('a place before a comma at the head is written as it is, never as an object', M1,
          'Monreale, los perros quieren el pan.'),
    %% the plural imperative, stated of the plural form
    nf_tr('"Mangiate il pane".', italian, spanish, M2),
    check('the plural imperative, where a plural participle agreed with a singular phrase', M2, '"Comed el pan".'),
    nf_tr('Comed el pan.', spanish, italian, M3),
    check('... and back', M3, 'Mangiate il pane.'),
    nf_tr('Non mangiate il pane.', italian, spanish, M4),
    check('Italian denies the plural with the plural itself; Spanish with its own form', M4, 'No comáis el pan.'),
    nf_tr('"Mangiate il pane".', italian, english, M5),
    check('... and English has one imperative for both', M5, '"Eat the bread".'),
    %% a GUARD: the singular headline participle still reads
    nf_tr('Mangiato il pane.', italian, spanish, M6),
    check('a GUARD: a participle that agrees with the phrase after it is still a headline', M6,
          'El pan ha sido comido.'),
    %% the subject after an intransitive verb, its adjuncts before it
    nf_tr('Finisce in tribunale il vescovo.', italian, spanish, M7),
    check('an intransitive verb''s adjuncts, then its subject', M7, 'Acaba ante los tribunales el obispo.'),
    nf_tr('Deve finire in tribunale il vescovo.', italian, spanish, M8),
    check('... after a modal whose infinitive is intransitive', M8, 'Debe acabar ante los tribunales el obispo.'),
    nf_tr('Deve finire in tribunale il vescovo.', italian, english, M9),
    check('... the subject first in English, and a verb of two words inflects its first', M9,
          'The bishop must end up in court.'),
    %% a title before a name, apposed to the subject with its `di' phrase
    nf_tr('Deve finire in tribunale il vescovo di Monreale monsignor Salvatore Cassisa.', italian, spanish, M10),
    check('a title before a name, apposed to the subject and its of phrase', M10,
          'Debe acabar ante los tribunales el obispo de Monreale monseñor Salvatore Cassisa.'),
    nf_tr('Deve finire in tribunale il vescovo di Monreale monsignor Salvatore Cassisa.', italian, english, M11),
    check('... and English capitalises the title', M11,
          'The bishop of Monreale Monsignor Salvatore Cassisa must end up in court.'),
    nf_tr('Monseñor Cassisa come el pan.', spanish, italian, M12),
    check('... and Italian writes the title''s short form the lesson states', M12, 'Monsignor Cassisa mangia il pane.'),
    %% the cleft
    nf_tr('A mangiarlo è il cane.', italian, spanish, M13),
    check('a cleft: what is done, the copula, who does it', M13, 'Lo come el perro.'),
    nf_tr('A chiederlo è la procura che vuole il pane, il gatto e il cane.', italian, spanish, M14),
    check('... with a relative clause whose list keeps its commas', M14,
          'Lo pide la fiscalía que quiere el pan, el gato y el perro.'),
    nf_tr('A mangiarlo è il cane.', italian, english, M14b),
    check('... and English puts the subject first', M14b, 'The dog eats it.'),
    %% the absolute superlative
    nf_tr('Il cane mangia i pani pesantissimi.', italian, spanish, M15),
    check('an absolute superlative is the word for very and the plain form', M15, 'El perro come los panes muy pesados.'),
    nf_tr('Il cane mangia i pani pesantissimi.', italian, english, M16),
    check('... in English too', M16, 'The dog eats the very heavy breads.'),
    %% the conditional perfect
    %% (a GUARD: 1.8.1 writes it too once the lesson states `habría'; the
    %% vocabulary did not, and the fix is lines of corpus/extra/spanish.txt)
    nf_tr('Il cane avrebbe mangiato il pane.', italian, spanish, M17),
    check('a GUARD: the conditional perfect, the auxiliary''s conditional', M17, 'El perro habría comido el pan.'),
    nf_tr('Il cane avrebbe mangiato il pane.', italian, english, M18),
    check('... and English''s would have', M18, 'The dog would have eaten the bread.'),
    nf_tr('Il pane sarà mangiato.', italian, english, M18b),
    check('... and its passive in the future, will be', M18b, 'The bread will be eaten.'),
    %% an aside between the subject and its verb
    nf_tr('Il cane, secondo il gatto, ha mangiato il pane.', italian, spanish, M19),
    check('an aside between the subject and its verb keeps its commas there', M19,
          'El perro, según el gato, ha comido el pan.'),
    nf_tr('Il cane, secondo il gatto, ha mangiato il pane.', italian, english, M19b),
    check('... in English too', M19b, 'The dog, according to the cat, has eaten the bread.'),
    %% a bare participle after its noun goes before it in English
    nf_tr('Il cane mangia il pane gonfiato.', italian, english, M20),
    check('a bare participle after its noun is written before it in English', M20, 'The dog eats the inflated bread.'),
    %% three the controls found: an intensifier before a predicate adjective,
    %% English's imperative of the copula, and (a GUARD: this version's first
    %% cut refused it) a joined subject after a plural headline participle
    nf_tr('El pan es muy gracioso.', spanish, english, M21),
    check('an adverb before a predicate adjective is the adjective''s', M21, 'The bread is very funny.'),
    nf_tr('El pan es graciosísimo.', spanish, english, M22),
    check('... and so is the superlative, which reads as it', M22, 'The bread is very funny.'),
    nf_tr('Estate contento.', spanish, english, M23),
    check('English''s imperative of the copula is be', M23, 'Be happy.'),
    nf_tr('Mangiati pane e cani.', italian, spanish, M24),
    check('a GUARD: two nouns joined are two phrases, and plural, after a plural participle', M24,
          'Pan y perros han sido comidos.'),
    %% (a GUARD too: this version's second cut read the participle as the
    %% intensified adjective `orderly', which Italian has no word for)
    nf_tr('Juegan muy ordenados.', spanish, italian, M25),
    check('a GUARD: a participle after an adverb is still predicated of the subject', M25,
          'Giocano molto ordinati.').

%% ---- a Spanish report on the record market, into Italian ----------------------------------

newspaper_record :-
    section('a Spanish report into Italian: figures, a heading in capitals, a passive made with se'),
    newspaper_record_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_record_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_record_checks,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_record_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". "unos" is the plural of "un".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every number is masculine.
The noun "perro" means "dog". "perro" is a person. The noun "gato" means "cat".
The noun "pan" means "bread". "panes" is the plural of "pan". The noun "queso" means "cheese".
The noun "casete" means "cassette". The noun "año" means "year".
The noun "venta" means "sale". The noun "bienio" means "biennium".
The noun "empresa" means "company".
The noun "empleado" means "employee". "empleado" is a person.
The adjective "compacto" means "compact". The adjective "grande" means "big".
The number "dos" means "two".
The adverb "unos" means "about". The adverb "a corto-medio plazo" means "in the short to medium term".
The adverb "en cambio" means "instead".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
"comiendo" is the gerund of "come". "comieron" is the past of "comen".
The verb "compacta" means "compacts". "compacto" is the first person of "compacta".
The verb "emplea" means "employs". "empleado" is the participle of "emplea".
"empleados" is the participle of "emplea". "empleados" is the plural of "empleado".
The verb "sitúa" means "situates". "situar" is the infinitive of "sitúa".
The verb "vende" means "sells". "venden" is the plural of "vende".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "continúa" means "continues". "continúa" takes the gerund.
The intransitive verb "destaca" means "stands out".
The verb "es" means "is". "son" is the plural of "es".
The reflexive pronoun "se" means "itself".
"que" is a relative. The conjunction "que" means "that". The conjunction "y" means "and".
The conjunction "aunque" means "although".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in".
The preposition "contra" means "against". The preposition "durante" means "during".
The preposition "hasta" means "until".
The preposition "por" means "by". The preposition "por" means "for".
"sold" is the participle of "sells". "ate" is the past of "eats".
The word "no" means "not".').
newspaper_record_lesson(italian, 'Italian is a language.
The feminine article "la" means "the". The masculine article "il" means "the". The masculine article "lo" means "the".
"le" is the plural of "la". "i" is the plural of "il". "gli" is the plural of "lo".
The article "lo" comes before a vowel. The article "il" takes the year.
The masculine article "un" means "a". "dei" is the plural of "un".
"al" is the contraction of "a il". "del" is the contraction of "di il". "nel" is the contraction of "in il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every number is masculine.
The noun "cane" means "dog". "cani" is the plural of "cane". "cane" is a person.
The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane". The noun "formaggio" means "cheese".
The noun "cassetta" means "cassette". The noun "anno" means "year". "anni" is the plural of "anno".
The noun "vendita" means "sale". The noun "biennio" means "biennium".
The noun "impresa" means "company".
The noun "impiegato" means "employee". "impiegati" is the plural of "impiegato".
The adjective "compatto" means "compact". The adjective "grande" means "big".
The number "due" means "two".
The adverb "circa" means "about". The adverb "a breve-medio termine" means "in the short to medium term".
The adverb "invece" means "instead".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangiando" is the gerund of "mangia". "mangiarono" is the past of "mangiano".
The verb "situa" means "situates". "situare" is the infinitive of "situa".
The verb "vende" means "sells". "vendono" is the plural of "vende".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "continua" means "continues". "continua" takes "a" before the infinitive.
The intransitive verb "spicca" means "stands out".
The verb "è" means "is". "sono" is the plural of "è".
The reflexive pronoun "si" means "itself".
"che" is a relative. The conjunction "che" means "that". The conjunction "e" means "and".
The conjunction "nonostante" means "although".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in".
The preposition "contro" means "against". The preposition "durante" means "during".
The preposition "fino a" means "until".
The preposition "da" means "by". The preposition "per" means "for".
"sold" is the participle of "sells". "ate" is the past of "eats".
The word "non" means "not".').

newspaper_record_checks :-
    %% a heading in capitals: lowered, and read with no verb first
    nf_tr('COMPACTO CONTRA CASETE.', spanish, italian, R1),
    check('a heading in capitals is read as its words, with no verb before any', R1, 'Compatto contro cassetta.'),
    nf_tr('COMPACTO CONTRA CASETE.', spanish, english, R1b),
    check('... in English too, where it had been `I compact Against Casete''', R1b, 'Compact against cassette.'),
    %% an acronym among small letters keeps its capitals
    nf_tr('El perro de DBK come el pan.', spanish, italian, R2),
    check('an acronym is a name spelled as the text spelled it', R2, 'Il cane di DBK mangia il pane.'),
    %% a number is masculine by the lesson's rule
    nf_tr('El perro come el 4% del pan en el 2001.', spanish, italian, R3),
    check('a number used as a noun is masculine by the lesson''s rule, where the first article was written', R3,
          'Il cane mangia il 4% del pane nel 2001.'),
    %% the article is chosen by the word written after it, the count too
    nf_tr('Los perros comen el pan durante los dos años.', spanish, italian, R4),
    check('the article is chosen by the word after it, which is the count', R4,
          'I cani mangiano il pane durante i due anni.'),
    %% an infinitive with the reflexive joined to it, after a preposition
    nf_tr('El perro come el pan hasta situarse en el 4%.', spanish, italian, R5),
    check('a preposition and an infinitive with its reflexive, never the impersonal pronoun', R5,
          'Il cane mangia il pane fino a situarsi nel 4%.'),
    %% a bare noun after `por' is no agent, and a count before a noun is its count
    nf_tr('Los perros comen el pan de 22 empleados por empresa.', spanish, italian, R6),
    check('a count before a noun is the count, and a bare noun after `por'' is nobody''s agent', R6,
          'I cani mangiano il pane di 22 impiegati per impresa.'),
    %% a gerund straight after a verb that takes a word before an infinitive
    nf_tr('El perro continúa comiendo el pan.', spanish, italian, R7),
    check('a verb''s own gerund is the infinitive its word takes in the other language', R7,
          'Il cane continua a mangiare il pane.'),
    nf_tr('Il cane continua a mangiare il pane.', italian, spanish, R7b),
    check('... and back, where the lesson says the verb takes the gerund', R7b, 'El perro continúa comiendo el pan.'),
    %% an inverted subject carries a relative clause after a comma
    nf_tr('Destaca el perro, que come el pan.', spanish, english, R8),
    check('an inverted subject carries its relative clause after a comma, and English closes it with one', R8,
          'The dog, who eats the bread, stands out.'),
    nf_tr('Destaca el perro, que come el pan.', spanish, italian, R8b),
    check('a GUARD: ... and the lesson''s language keeps the order', R8b, 'Spicca il cane, che mangia il pane.'),
    %% a relative clause with an adjunct before its verb
    nf_tr('El perro ve los gatos, que en 1999 comieron el pan.', spanish, english, R9),
    check('a relative clause with an adjunct before its verb', R9, 'The dog sees the cats, which ate the bread in 1999.'),
    %% one subject, with a bare noun joined inside its last phrase
    nf_tr('Aunque la venta de pan y queso es grande, el perro duerme.', spanish, italian, R10),
    check('a bare noun after a coordinator is inside the phrase, and divides no clause', R10,
          'Nonostante la vendita di pane e formaggio è grande, il cane dorme.'),
    %% a hyphenated word of the lesson, and a range of numbers
    nf_tr('El perro come el pan a corto-medio plazo.', spanish, italian, R11),
    check('a word the lesson spells with a hyphen is found by the words the tokeniser reads', R11,
          'Il cane mangia il pane a breve-medio termine.'),
    nf_tr('El perro come el pan durante el bienio 2000-2001.', spanish, italian, R12),
    check('a range of numbers is one word', R12, 'Il cane mangia il pane durante il biennio 2000-2001.'),
    %% a number ends its phrase before a determiner
    nf_tr('Los perros comen en 1999 el pan.', spanish, italian, R13),
    check('a number ends its phrase before a determiner', R13, 'I cani mangiano nel 1999 il pane.'),
    %% the article before a number that the lesson calls an adverb too
    nf_tr('Los perros comen unos 980 panes.', spanish, italian, R14),
    check('a GUARD: an article the lesson calls an adverb, before a number, is the count''s adverb', R14,
          'I cani mangiano circa 980 pani.'),
    nf_tr('Los perros comen unos 980 panes.', spanish, english, R14b),
    check('... and stays with its count in English', R14b, 'The dogs eat about 980 breads.'),
    %% (this version's first cut read the article as the adverb everywhere:
    %% `employ about industrious' for `emplean unos trabajadores')
    nf_tr('Los perros comen unos panes.', spanish, italian, R14c),
    check('... and before a noun it is the article it is', R14c, 'I cani mangiano dei pani.'),
    %% the commas the source set
    nf_tr('En cambio, el perro come el pan, comiendo el queso.', spanish, italian, R15),
    check('a comma after a front''s own comma is kept', R15, 'Invece, il cane mangia il pane, mangiando il formaggio.'),
    nf_tr('El perro no come, y el gato duerme.', spanish, italian, R16),
    check('a comma before a coordinator is kept', R16, 'Il cane non mangia, e il gatto dorme.'),
    %% the reflexive's passive
    nf_tr('Se venden los panes.', spanish, english, R17),
    check('se and a plural verb: the phrase after it is its subject, and English writes the passive', R17,
          'The breads are sold.'),
    nf_tr('Se venden los panes.', spanish, italian, R17b),
    check('a GUARD: ... and Italian its si and the verb, in the source''s order', R17b, 'Si vendono i pani.'),
    nf_tr('Se venden los panes de los perros, que comen el pan.', spanish, english, R17c),
    check('... and an aside on the last phrase of that subject closes with its comma in English', R17c,
          'The breads of the dogs, who eat the bread, are sold.'),
    %% a GUARD: with a singular verb the word is still the impersonal one
    nf_tr('Se vende el pan.', spanish, italian, R18),
    check('a GUARD: with a singular verb se is still the impersonal word', R18, 'Si vende il pane.').

%% ---- an Italian report on traffic banned from the islands, into Spanish ------------------

newspaper_islands :-
    section('an Italian report into Spanish: a list of islands, a clause between dashes, a participle after a comma, a range of days'),
    newspaper_islands_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_islands_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_islands_checks,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_islands_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"l''" is the elision of "lo". "l''" is the elision of "la".
"al" is the contraction of "a il". "dal" is the contraction of "da il". "del" is the contraction of "di il".
"nella" is the contraction of "in la". "dei" is the contraction of "di i".
"della" is the contraction of "di la". "dell''" is the elision of "della".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every number is masculine.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "topo" means "mouse". "topi" is the plural of "topo".
The noun "pane" means "bread". The noun "casa" means "house". "case" is the plural of "casa".
The noun "isola" means "island". "isole" is the plural of "isola".
The noun "giglio" means "lily". The noun "traffico" means "traffic". The noun "giorno" means "day".
The noun "ambiente" means "environment". The noun "responsabile" means "manager".
The masculine noun "lavoro pubblico" means "public work". "lavori pubblici" is the plural of "lavoro pubblico".
The noun "luglio" means "july". "luglio" is a month. The noun "agosto" means "august". "agosto" is a month.
The adjective "grande" means "big". "grandi" is the plural of "grande".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dorme" is intransitive.
The intransitive verb "firma" means "signs".
The verb "isola" means "isolates".
The verb "chiama" means "calls". "chiamano" is the plural of "chiama".
The verb "vieta" means "forbids". "vietato" is the participle of "vieta".
"vietata" is the participle of "vieta". "vietata" is feminine.
"vietati" is the participle of "vieta". "vietati" is the plural of "vietato".
"vietate" is the participle of "vieta". "vietate" is the plural of "vietata". "vietate" is feminine.
The verb "è" means "is". "sono" is the plural of "è". "è" is the auxiliary of "è".
The reflexive pronoun "si" means "itself".
The masculine pronoun "quello" means "that". "quelli" is the plural of "quello". The pronoun "quello" does not precede the verb.
"che" is a relative. The conjunction "che" means "that". The conjunction "e" means "and".
The conjunction "se" means "if". The word "dove" means "where".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in".
The preposition "da" means "from". The preposition "da" means "by". The preposition "per" means "for".
The preposition "così come" means "just like".
The adverb "più" means "more". The word "più" begins the comparative.
The adverb "sempre" means "always". The adverb "quantomeno" means "at least". The adverb "soltanto" means "only".
The word "non" means "not".').
newspaper_islands_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every number is masculine.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "ratón" means "mouse". "ratones" is the plural of "ratón".
The noun "pan" means "bread". The noun "casa" means "house". The noun "isla" means "island".
The noun "lirio" means "lily". The noun "tráfico" means "traffic". The noun "día" means "day". "día" is not feminine.
The noun "entorno" means "environment". The noun "director" means "manager". "directores" is the plural of "director".
The feminine noun "obra pública" means "public work". "obras públicas" is the plural of "obra pública".
The noun "julio" means "july". "julio" is a month. The noun "agosto" means "august". "agosto" is a month.
The word "de" joins the date.
The adjective "grande" means "big". "grandes" is the plural of "grande".
The verb "come" means "eats". "comen" is the plural of "come".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "firma" means "signs".
The verb "aísla" means "isolates".
The verb "llama" means "calls". "llaman" is the plural of "llama".
The verb "prohíbe" means "forbids". "prohibido" is the participle of "prohíbe".
"prohibida" is the participle of "prohíbe". "prohibida" is feminine.
"prohibidos" is the participle of "prohíbe". "prohibidos" is the plural of "prohibido".
"prohibidas" is the participle of "prohíbe". "prohibidas" is the plural of "prohibida". "prohibidas" is feminine.
The verb "es" means "is". "son" is the plural of "es". "ha" is the auxiliary of "es".
The reflexive pronoun "se" means "itself".
The masculine pronoun "aquél" means "that". "aquéllos" is the plural of "aquél". The pronoun "aquél" does not precede the verb.
"que" is a relative. The conjunction "que" means "that". The conjunction "y" means "and".
The conjunction "si" means "if". The conjunction "donde" means "where". The word "dónde" means "where".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in".
The preposition "desde" means "from". The preposition "por" means "by". The preposition "para" means "for".
The preposition "así como" means "just like".
The adverb "más" means "more". The word "más" begins the comparative.
The adverb "siempre" means "always". The adverb "al menos" means "at least". The adverb "sólo" means "only".
The word "no" means "not".').

newspaper_islands_checks :-
    %% a list of names, one of which the lesson knows as a noun
    nf_tr('I cani si chiamano Giglio, Eolie, Ustica e Ponza.', italian, spanish, I1),
    check('a name the lesson knows as a noun, in a list of names, is no noun with a name apposed to it', I1,
          'Los perros se llaman Giglio, Eolie, Ustica y Ponza.'),
    %% `se non ... quantomeno ...'
    nf_tr('I cani sono vietati se non per sempre quantomeno per un giorno.', italian, spanish, I2),
    check('if not for ever, at least for a day: the connector and the denied adjunct after it', I2,
          'Los perros son prohibidos si no para siempre al menos para un día.'),
    reason_ir('I cani sono vietati se non per sempre quantomeno per un giorno.', italian, [ir(s(_, _, _, I2c), _)]),
    ( I2c = [I2a, I2b|_] -> true ; I2a = none, I2b = none ),
    check('... and in the IR the connector is no phrase''s noun, and the denial is the adjunct''s', I2a-I2b,
          cnj(w(if, lower))-neg(pp(w(for, lower), adv(w(always, lower))))),
    %% a sentence that is one phrase and the clause `dove' opens
    nf_tr('Grandi case dove i cani sono vietati.', italian, spanish, I3),
    check('a sentence that is a phrase and a clause opened by where', I3, 'Grandes casas donde los perros son prohibidos.'),
    nf_tr('Grandi case dove i cani, i gatti e i topi sono vietati.', italian, spanish, I4),
    check('... and a list at the head of that clause is its subject, commas and all', I4,
          'Grandes casas donde los perros, los gatos y los ratones son prohibidos.'),
    %% adjectives between the article and a name
    nf_tr('Il cane vede le grandi Eolie.', italian, spanish, I5),
    check('an adjective between the article and a name', I5, 'El perro ve las grandes Eolie.'),
    nf_tr('Il cane vede le più grandi Eolie.', italian, spanish, I5b),
    check('... and a superlative there, agreeing with the gender the article lends the name', I5b,
          'El perro ve las Eolie más grandes.'),
    %% a range of days is nobody's agent
    nf_tr('Il pane è vietato dal 24 luglio al 25 agosto.', italian, spanish, I6),
    check('a range of days after a passive is when, and not who: `por el 24 de julio'' before', I6,
          'El pan es prohibido desde el 24 de julio al 25 de agosto.'),
    nf_tr('Il cane vede la casa vietata dal 4 al 24 agosto.', italian, spanish, I7),
    check('... and after a participle standing after its noun', I7,
          'El perro ve la casa prohibida desde el 4 al 24 de agosto.'),
    nf_tr('Il cane vede l''isola di Ustica "vietata" dal 4 al 24 agosto.', italian, spanish, I8),
    check('a participle after a name agrees with its own gender, and keeps its quotation marks', I8,
          'El perro ve la isla de Ustica "prohibida" desde el 4 al 24 de agosto.'),
    %% a participle after a comma is the phrase's aside
    nf_tr('Il cane vede le Eolie, vietate al traffico, e l''isola di Ustica.', italian, spanish, I9),
    check('a participle after a comma is the phrase''s, and the phrase after the next comma is joined to it', I9,
          'El perro ve las Eolie, prohibidas al tráfico, y la isla de Ustica.'),
    %% a clause between two dashes
    nf_tr('La casa - dove i cani sono vietati - è grande.', italian, spanish, I10),
    check('a clause between two dashes that opens on where is the phrase''s', I10,
          'La casa – donde los perros son prohibidos – es grande.'),
    %% a connector at the head keeps the sentence's commas
    nf_tr('E il cane vede le Eolie, vietate al traffico, e l''isola di Ustica.', italian, spanish, I11),
    check('a connector at the head is read before any division, with the commas after it', I11,
          'Y el perro ve las Eolie, prohibidas al tráfico, y la isla de Ustica.'),
    %% an intransitive verb, its adjuncts, and a subject with its relative clause after them
    %% (1.8.31: `soltanto' before the subject is the subject's, advp/2 -- only
    %% THOSE eat the bread -- where it was the clause's adverb and English
    %% wrote it last, `... sleep in the house only.'; the Spanish is the same)
    nf_tr('Dormono nella casa soltanto quelli che mangiano il pane.', italian, english, I12),
    check('an intransitive verb''s subject after its adjuncts carries its relative clause', I12,
          'Only those that eat the bread sleep in the house.'),
    %% two `di' phrases joined in a subject after its verb
    nf_tr('Firma il responsabile dell''ambiente e dei lavori pubblici, Paolo Baratta, e i cani dormono.', italian, english, I13),
    check('a subject after its verb takes two of-phrases joined, and the name after them', I13,
          'The manager of the environment and of the public works, Paolo Baratta, signs and the dogs sleep.'),
    nf_tr('Firma il responsabile dell''ambiente e dei lavori pubblici, Paolo Baratta, e i cani dormono.', italian, spanish, I13b),
    check('... and Spanish keeps it in the source''s order', I13b,
          'Firma el director del entorno y de las obras públicas, Paolo Baratta, y los perros duermen.').

newspaper_opera :-
    section('a Spanish opera review into Italian: a clause between dashes, what stands beside a phrase, a name after its verb'),
    newspaper_opera_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_opera_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_opera_checks,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_opera_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "casa" means "house". The noun "luna" means "moon". The noun "escena" means "scene".
The noun "versión" means "version". "versión" is feminine.
The noun "éxito" means "success". The noun "sentido" means "sense". The noun "término" means "term".
The noun "retrato" means "portrait". The noun "ironía" means "irony". The noun "ópera" means "opera".
The noun "noche" means "night". "noche" is feminine.
The noun "aficionado" means "fan". "aficionado" is a person.
The noun "descripción" means "description". "descripción" is feminine.
The noun "dirección" means "direction". "dirección" is feminine.
The noun "lord" means "lord". "lord" is a person.
The adjective "grande" means "big". "grandes" is the plural of "grande".
The masculine adjective "discreto" means "discreet".
The masculine adjective "estilizado" means "stylized". The feminine adjective "estilizada" means "stylized".
The masculine adjective "conservador" means "conservative". The feminine adjective "conservadora" means "conservative".
The masculine adjective "frío" means "cold". The masculine adjective "expresivo" means "expressive".
The masculine adjective "preciso" means "precise".
The adjective "bueno" means "good". The adjective "mejor" means "good". "mejores" is the plural of "mejor".
"mejor" is the comparative of "bueno". "buenos" is the plural of "bueno". "mejores" is the comparative of "buenos".
The masculine determiner "poco" means "little". "pocos" is the plural of "poco".
The masculine determiner "otro" means "another". "otros" is the plural of "otro".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The possessive "su" means "his". "sus" is the plural of "su".
The verb "come" means "eats". "comen" is the plural of "come". "come" is the imperative of "come".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "es" means "is". "son" is the plural of "es". "fue" is the past of "es".
The verb "va" means "goes". "fue" is the past of "va".
The verb "canta" means "sings". "cantó" is the past of "canta".
The verb "tiene" means "has". "tuvo" is the past of "tiene".
The verb "ofrece" means "offers". "ofreció" is the past of "ofrece".
The verb "empieza" means "begins". "empezó" is the past of "empieza".
The verb "permite" means "allows". "permite" is the imperative of "permite".
The verb "pide" means "asks". "pedir" is the infinitive of "pide".
The verb "entona" means "intones". "entonando" is the gerund of "entona".
The verb "espera" means "waits". "esperado" is the participle of "espera".
"esperada" is the participle of "espera". "esperada" is feminine.
The verb "interpreta" means "interprets". "interpretado" is the participle of "interpreta".
The verb "recuerda" means "remembers". "recordar" is the infinitive of "recuerda".
The verb "para" means "stops".
The verb "cuenta" means "counts". "cuenta" is the imperative of "cuenta".
The verb "cose" means "sews". "cosías" is the second person of "cose".
The verb "dice" means "says". "dijo" is the past of "dice".
The reflexive pronoun "se" means "itself". Every pronoun precedes the verb.
The dative pronoun "les" means "them".
The pronoun "lo" means "him".
"que" is a relative. The conjunction "que" means "that".
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "pese a que" means "although".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in".
The preposition "con" means "with". The preposition "por" means "by". The preposition "para" means "for".
The word "para" begins the purpose.
The preposition "bajo" means "under". The preposition "sin" means "without".
The adverb "muy" means "very". The adverb "más" means "more". The word "más" begins the comparative.
The adverb "además" means "besides". The adverb "al fin y al cabo" means "after all".
The demonstrative "esta" means "this".
The word "a" precedes the person.').
newspaper_opera_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the". The masculine article "lo" means "the".
"i" is the plural of "il". "le" is the plural of "la". "gli" is the plural of "lo".
The masculine article "un" means "a". The feminine article "una" means "a".
"l''" is the elision of "lo". "l''" is the elision of "la". "un''" is the elision of "una".
"del" is the contraction of "di il". "della" is the contraction of "di la". "delle" is the contraction of "di le".
"dagli" is the contraction of "da gli". "degli" is the contraction of "di gli". "nella" is the contraction of "in la". "nel" is the contraction of "in il".
The article "lo" comes before a vowel. The article "il" takes the possessive.
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "cane" means "dog". The noun "gatto" means "cat". The noun "pane" means "bread". "pani" is the plural of "pane".
The noun "casa" means "house". The noun "luna" means "moon". The noun "scena" means "scene".
The noun "versione" means "version". "versione" is feminine.
The noun "successo" means "success". The noun "senso" means "sense". The noun "termine" means "term".
The noun "ritratto" means "portrait". The noun "ironia" means "irony". The noun "opera" means "opera".
The noun "notte" means "night". "notte" is feminine. "notti" is the plural of "notte".
The noun "appassionato" means "fan". "appassionati" is the plural of "appassionato".
The noun "descrizione" means "description". "descrizione" is feminine.
The noun "direzione" means "direction". "direzione" is feminine.
The noun "lord" means "lord".
The adjective "grande" means "big". "grandi" is the plural of "grande".
The masculine adjective "discreto" means "discreet".
The masculine adjective "stilizzato" means "stylized". The feminine adjective "stilizzata" means "stylized".
The masculine adjective "conservatore" means "conservative". The feminine adjective "conservatrice" means "conservative".
The masculine adjective "freddo" means "cold". The masculine adjective "espressivo" means "expressive".
The masculine adjective "preciso" means "precise".
The adjective "buono" means "good". The adjective "migliore" means "good". "migliori" is the plural of "migliore".
"migliore" is the comparative of "buono". "buoni" is the plural of "buono". "migliori" is the comparative of "buoni".
The masculine determiner "poco" means "little". "pochi" is the plural of "poco".
The masculine determiner "altro" means "another". "altri" is the plural of "altro".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The masculine possessive "suo" means "his". The feminine possessive "sua" means "his".
"suoi" is the plural of "suo". "sue" is the plural of "sua".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "è" means "is". "sono" is the plural of "è". "fu" is the past of "è".
The verb "va" means "goes". "andò" is the past of "va".
The verb "canta" means "sings". "cantò" is the past of "canta".
The verb "ha" means "has". "ebbe" is the past of "ha".
The verb "offre" means "offers". "offrì" is the past of "offre".
The verb "comincia" means "begins". "cominciò" is the past of "comincia".
The verb "permette" means "allows".
The verb "chiede" means "asks". "chiedere" is the infinitive of "chiede".
The verb "intona" means "intones". "intonando" is the gerund of "intona".
The verb "attende" means "waits". "atteso" is the participle of "attende".
"attesa" is the participle of "attende". "attesa" is feminine.
The verb "interpreta" means "interprets". "interpretato" is the participle of "interpreta".
The verb "ricorda" means "remembers". "ricordare" is the infinitive of "ricorda".
The verb "conta" means "counts". "conta" is the imperative of "conta".
The verb "dice" means "says". "disse" is the past of "dice".
The reflexive pronoun "si" means "itself". Every pronoun precedes the verb.
The dative pronoun "gli" means "them".
The pronoun "lo" means "him".
"che" is a relative. The conjunction "che" means "that".
The conjunction "e" means "and". The conjunction "ma" means "but". The conjunction "nonostante" means "although".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in".
The preposition "con" means "with". The preposition "da" means "by". The preposition "per" means "for".
The word "per" begins the purpose.
The preposition "sotto" means "under". The preposition "senza" means "without".
The adverb "molto" means "very". The adverb "più" means "more". The word "più" begins the comparative.
The adverb "inoltre" means "besides". The adverb "dopotutto" means "after all".
The demonstrative "questa" means "this".').

newspaper_opera_checks :-
    %% the tokeniser: AnCora spells an em dash as two hyphens, and a whole
    %% clause between two dashes is an aside of the phrase before them
    nf_tr('La luna - - el perro es grande - - es grande.', spanish, italian, O1),
    check('two hyphens are one dash, and a clause between two dashes stands where it stood', O1,
          'La luna – il cane è grande – è grande.'),
    %% a purpose standing alone
    nf_tr('Para recordar.', spanish, italian, O2),
    check('the purpose word and an infinitive are no verb: `para'' is no `parar'' there', O2, 'Per ricordare.'),
    %% a word of five words, an adjective list that ends on its coordinator,
    %% and an adjective phrase between two commas after its noun
    nf_tr('El perro ve el éxito, discreto pero al fin y al cabo éxito, de la casa.', spanish, italian, O3),
    check('a word of five words, and an aside of the noun before it, `but'' no adjective in it', O3,
          'Il cane vede il successo, discreto ma dopotutto successo, della casa.'),
    nf_tr('El perro es una versión estilizada, conservadora en el mejor sentido del término, y come el pan.', spanish, italian, O4),
    check('the aside agrees with its own noun; `el mejor sentido'' is a sense; after `y'' and a statement no command', O4,
          'Il cane è una versione stilizzata, conservatrice nel senso migliore del termine, e mangia il pane.'),
    nf_tr('Lo come y permite el pan.', spanish, italian, O5),
    check('a clause joined to a statement by `y'' is no command, though `permite'' is spelled like one', O5,
          'Lo mangia e permette il pane.'),
    %% an infinitive after a preposition keeps its pronoun
    nf_tr('El perro canta sin pedirles pan.', spanish, italian, O6),
    check('a pronoun joined to an infinitive after a preposition is the infinitive''s, a dative as the dative', O6,
          'Il cane canta senza chiedergli pane.'),
    %% the most awaited one
    nf_tr('El perro ve una escena de la casa, la más esperada por los aficionados.', spanish, italian, O7),
    check('an article, `más'' and a participle with its agent: the noun left out, the degree on the participle', O7,
          'Il cane vede una scena della casa, la più attesa dagli appassionati.'),
    nf_tr('En esta versión, además, cuenta con una June Anderson que canta una escena, la más esperada por los aficionados.', spanish, italian, O8),
    check('... and `cuenta'' is no reporting verb with `Anderson'' cut out of `una June Anderson'' for its speaker', O8,
          'In questa versione, inoltre, conta con una June Anderson che canta una scena, la più attesa dagli appassionati.'),
    %% a bare phrase at the head that says what the subject is
    nf_tr('Retrato preciso de la casa, Anderson canta.', spanish, italian, O9),
    check('a phrase with no determiner, before a comma and a named subject, stays in front with its comma', O9,
          'Ritratto preciso della casa, Anderson canta.'),
    %% one of, and a possessive's superlative
    nf_tr('Anderson ofreció una de sus mejores noches.', spanish, italian, O10),
    check('the indefinite article with its noun left out is `one of''', O10,
          'Anderson offrì una delle sue notti migliori.'),
    nf_tr('Anderson ofreció una de sus mejores noches.', spanish, english, O11),
    check('... `one of'' in English, and a possessive makes a superlative', O11, 'Anderson offered one of his best nights.'),
    nf_tr('Anderson ofreció sus mejores noches.', spanish, english, O12),
    check('... his best nights, never his better ones', O12, 'Anderson offered his best nights.'),
    %% names
    nf_tr('La ópera de Donizetti Lucia di Lammermoor es grande.', spanish, italian, O13),
    check('a small word between two names is the name''s: `di'' is no Spanish preposition', O13,
          'L''opera di Donizetti Lucia di Lammermoor è grande.'),
    nf_tr('Bajo la dirección de Bertrand de Billy, el perro come.', spanish, italian, O14),
    check('... nor is `de'' there, between two names', O14, 'Sotto la direzione di Bertrand de Billy, il cane mangia.'),
    nf_tr('El perro tuvo en Josep Bros, Edgardo, otro éxito.', spanish, italian, O15),
    check('a guard: a name between commas after a name is its apposition', O15,
          'Il cane ebbe in Josep Bros, Edgardo, altro successo.'),
    nf_tr('En la descripción de lord Arturo Bucklaw, interpretado por Carlos Cosías, Vick se permite una ironía.', spanish, italian, O16),
    check('a title and a name, a participle between commas after it, and a name a verb''s form is part of', O16,
          'Nella descrizione di lord Arturo Bucklaw, interpretato da Carlos Cosías, Vick si permette un''ironia.'),
    nf_tr('Se permite Vick una ironía.', spanish, italian, O17),
    check('a bare name after the verb is its subject where a person object takes `a'', and it stays there', O17,
          'Si permette Vick un''ironia.'),
    nf_tr('Se permite Vick una ironía.', spanish, english, O18),
    check('... and `se'' is his reflexive', O18, 'Vick allows an irony.'),
    %% a gerund with its reflexive, after `ir'
    nf_tr('Bros fue entonándose.', spanish, italian, O19),
    check('`fue'' before a gerund is `ir'', and the gerund carries its reflexive', O19, 'Bros andò intonandosi.'),
    nf_tr('Pese a que empezó frío, poco expresivo, Bros fue entonándose.', spanish, italian, O20),
    check('a clause after its connector keeps its commas, and a subject does not run across one into a name', O20,
          'Nonostante cominciò freddo, poco espressivo, Bros andò intonandosi.'),
    %% a quantity with an adverb
    nf_tr('El perro come muy pocos panes.', spanish, english, O21),
    check('`pocos'' is `few'', the plural of `little'', and the adverb before it is its own', O21,
          'The dog eats very few breads.'),
    %% two regressions the controls found in the first draft of these shapes
    nf_tr('Su perro, Josep Bros, de la casa, come el pan.', spanish, italian, O22),
    check('an insertion the apposition before it opens keeps its closing comma', O22,
          'Il suo cane, Josep Bros, della casa, mangia il pane.'),
    nf_tr('Su perro, Josep Bros, de la casa, come el pan.', spanish, english, O23),
    check('... in English too', O23, 'His dog, Josep Bros, of the house, eats the bread.'),
    nf_tr('Dijo Josep Bros, uno de los aficionados.', spanish, italian, O24),
    check('a name after its verb, with a phrase apposed to it, stays after the verb', O24,
          'Disse Josep Bros, uno degli appassionati.').

%% ---- an Italian interview on Maradona, into Spanish ---------------------------------------

newspaper_ferlaino :-
    section('an Italian interview into Spanish: a time clause standing alone, a heading of one phrase, a clause with no speaker between dashes, an infinitive for a subject'),
    newspaper_ferlaino_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_ferlaino_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_ferlaino_checks,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_ferlaino_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"l''" is the elision of "lo". "l''" is the elision of "la".
"al" is the contraction of "a il". "del" is the contraction of "di il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every number is masculine.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". The noun "casa" means "house".
The noun "giorno" means "day". "giorno" is a time. The noun "futuro" means "future".
The noun "calcio" means "football". The verb "calcia" means "kicks". "calcio" is the first person of "calcia".
The noun "amico" means "friend". "amici" is the plural of "amico".
The noun "persona" means "person". "persone" is the plural of "persona".
The noun "presidente" means "president". The noun "monte" means "mount".
The feminine demonstrative "quella" means "that". "quelle" is the plural of "quella". The feminine pronoun "quella" means "that". The pronoun "quella" does not precede the verb.
The noun "condizione" means "condition". "condizioni" is the plural of "condizione". The verb "condiziona" means "conditions". "condizioni" is the second person of "condiziona". "condizioni" is the subjunctive of "condiziona". "condizionino" is the plural of "condizioni".
The verb "pensa" means "thinks". The adverb "già" means "already".
The noun "anno" means "year". "anni" is the plural of "anno". The adjective "grande" means "big". "grandi" is the plural of "grande".
The word "cosa" means "what". The feminine noun "cosa" means "thing".
The number "due" means "two".
The adjective "difficile" means "difficult".
The feminine adjective "prima" means "first". The adverb "prima" means "before".
The masculine adjective "pellegrino" means "wandering". "pellegrini" is the plural of "pellegrino".
The masculine noun "pellegrino" means "pilgrim".
The masculine adjective "diverso" means "diverse". "diversi" is the plural of "diverso".
The feminine adjective "diversa" means "diverse". "diverse" is the plural of "diversa".
The masculine determiner "diverso" means "several". "diversi" is the plural of "diverso".
The feminine determiner "diversa" means "several". "diverse" is the plural of "diversa".
The masculine determiner "altro" means "another". "altri" is the plural of "altro".
The masculine pronoun "altro" means "others". "altri" is the plural of "altro". The pronoun "altro" does not precede the verb.
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiò" is the past of "mangia". "mangiato" is the participle of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormiva" is the past of "dorme". "dorme" is intransitive.
The verb "vede" means "sees". The verb "dice" means "says". "disse" is the past of "dice". "said" is the past of "says".
The verb "continua" means "continues".
The verb "parla" means "speaks". "parlare" is the infinitive of "parla".
The verb "riconosce" means "recognizes". "riconoscere" is the infinitive of "riconosce".
The intransitive verb "serve" means "is needed". "servono" is the plural of "serve".
The intransitive verb "arriva" means "arrives". The intransitive verb "va via" means "exits".
The verb "è" means "is". "sono" is the plural of "è". "era" is the past of "è". "erano" is the plural of "era".
The auxiliary "ha" means "has". "hanno" is the plural of "ha".
The pronoun "lo" means "him". Every pronoun precedes the verb. The impersonal pronoun "si" means "one".
"che" is a relative. The conjunction "che" means "that". The conjunction "e" means "and".
The conjunction "cioè" means "that is". The word "quando" means "when".
The conjunction "se" means "if". The preposition "a" means "to". The preposition "di" means "of". The preposition "con" means "with". The preposition "come" means "as". The preposition "in" means "in".
The adjective "in grado" means "able".
The adverb "poi" means "then". The adverb "oggi" means "today".
The word "non" means "not". The word "non" precedes the verb.').
newspaper_ferlaino_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every number is masculine.
The noun "perro" means "dog". The noun "gato" means "cat".
The noun "pan" means "bread". The noun "casa" means "house".
The noun "día" means "day". "día" is not feminine. "día" is a time. The noun "futuro" means "future".
The noun "fútbol" means "football".
The noun "amigo" means "friend". "amigo" is a person. The word "a" precedes the person.
The noun "persona" means "person". The noun "presidente" means "president". The noun "monte" means "mount".
The feminine demonstrative "esa" means "that". "esas" is the plural of "esa".
The noun "condición" means "condition". "condiciones" is the plural of "condición". "condición" is feminine.
The verb "piensa" means "thinks". The adverb "ya" means "already".
The noun "año" means "year". The adjective "grande" means "big". "grandes" is the plural of "grande".
The word "qué" means "what". The feminine noun "cosa" means "thing".
The number "dos" means "two".
The adjective "difícil" means "difficult". "difíciles" is the plural of "difícil".
The adverb "antes" means "before".
The masculine adjective "peregrino" means "wandering". "peregrinos" is the plural of "peregrino".
The masculine noun "peregrino" means "pilgrim".
The masculine adjective "diverso" means "diverse". "diversos" is the plural of "diverso".
The feminine adjective "diversa" means "diverse". "diversas" is the plural of "diversa".
The masculine determiner "otro" means "another". "otros" is the plural of "otro".
The masculine pronoun "otro" means "others". "otros" is the plural of "otro". The pronoun "otro" does not precede the verb.
The verb "come" means "eats". "comen" is the plural of "come". "comió" is the past of "come". "comido" is the participle of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormía" is the past of "duerme".
The verb "ve" means "sees". The verb "dice" means "says". "dijo" is the past of "dice".
The verb "continúa" means "continues".
The verb "habla" means "speaks". "hablar" is the infinitive of "habla".
The verb "reconoce" means "recognizes". "reconocer" is the infinitive of "reconoce".
The intransitive verb "hace falta" means "is needed". "hacen falta" is the plural of "hace falta".
The verb "llega" means "arrives". The verb "sale" means "exits".
The verb "es" means "is". "son" is the plural of "es". "era" is the past of "es". "eran" is the plural of "era".
The auxiliary "ha" means "has". "han" is the plural of "ha".
The pronoun "lo" means "him". Every pronoun precedes the verb. The impersonal pronoun "se" means "one".
"que" is a relative. The conjunction "que" means "that". The conjunction "y" means "and".
The word "cuándo" means "when". The conjunction "es decir" means "that is". The conjunction "cuando" means "when".
The conjunction "si" means "if". The preposition "a" means "to". The preposition "de" means "of". The preposition "con" means "with". The preposition "como" means "as". The preposition "en" means "in".
The adjective "capaz" means "able".
The adverb "entonces" means "then". The adverb "hoy" means "today".
The word "no" means "not". The word "no" precedes the verb.').

newspaper_ferlaino_checks :-
    %% a pronoun that stands alone ends a subject phrase: `altri' is a
    %% determiner, an object pronoun and `others' at once
    nf_tr('Gli altri dormono.', italian, spanish, M1),
    check('a pronoun that stands alone may end a subject phrase, where only a clitic may not', M1, 'Los otros duermen.'),
    %% `that is' and a time clause after a colon
    nf_tr('Il cane mangia il pane: cioè quando gli altri dormono.', italian, spanish, M2),
    check('a colon, `that is'' and a time clause standing alone', M2, 'El perro come el pan: es decir cuando los otros duermen.'),
    ( reason_ir('Il cane mangia il pane: cioè quando gli altri dormono.', italian, [ir(join(colon, _, M3r), _)]) -> true ; M3r = refused ),
    ( M3r = join(M3c, none, gap([], [rwh(M3q, _)])) -> M3 = M3c-M3q ; M3 = M3r ),
    check('... and in the IR `that is'' is the connector, never a phrase''s noun, and the clause is the relative when', M3,
          w('that is', lower)-when),
    %% `when' after the verb's object is the time, not a question
    nf_tr('L''ha mangiato quando il gatto dormiva.', italian, spanish, M4),
    check('a question word after the verb''s object pronoun opens no question: `cuando'', where it was `cuándo''', M4,
          'Lo ha comido cuando el gato dormía.'),
    nf_tr('Il cane vede quando il gatto dorme.', italian, spanish, M5),
    check('a GUARD: straight after the verb it is still the question the verb takes', M5, 'El perro ve cuándo el gato duerme.'),
    %% a section's name before the dash
    nf_tr('Calcio - il cane mangia il pane.', italian, spanish, M6),
    check('a noun before a dash at the head is a dateline, where it was `calcio'', I kick', M6, 'Fútbol – el perro come el pan.'),
    %% the day before
    nf_tr('Il giorno prima mangiò il pane.', italian, spanish, M7),
    check('an adverb that is an adjective in the other gender too, after the noun, is the adverb; and a time is no subject of a verb with an object', M7,
          'Comió el pan el día antes.'),
    nf_tr('Il giorno mangiò il pane.', italian, spanish, M8),
    check('... the second alone: the day did not eat the bread', M8, 'Comió el pan el día.'),
    %% an infinitive for a subject
    nf_tr('Parlare con il cane è difficile.', italian, spanish, M9),
    check('an infinitive and its complements are a subject', M9, 'Hablar con el perro es difícil.'),
    nf_tr('Parlare con il cane è difficile.', italian, english, M10),
    check('... in English too, with its `to''', M10, 'To speak with the dog is difficult.'),
    %% a reporting clause with no speaker
    nf_tr('Il cane - continua - mangia il pane.', italian, spanish, M11),
    check('a verb alone between two dashes reports the sentence, and nobody is named', M11, 'El perro come el pan – continúa –.'),
    %% a heading of one phrase, and three points
    nf_tr('Il futuro.', italian, spanish, M12),
    check('an article and its noun alone are a heading', M12, 'El futuro.'),
    nf_tr('Il cane riconosce gli amici ...', italian, spanish, M13),
    check('three points are one stop, and they are written back', M13, 'El perro reconoce a los amigos...'),
    %% the word before a person, after an infinitive after the copula
    nf_tr('Il cane non era in grado di riconoscere gli amici.', italian, spanish, M14),
    check('what follows an infinitive is its own: a person there takes `a'', whatever verb the clause has', M14,
          'El perro no era capaz de reconocer a los amigos.'),
    %% a verb of several words that opens on the copula
    nf_tr('Servono due cani.', italian, english, M15),
    check('English inflects `is needed'' as the copula: `are needed'', where it was `be needed''', M15, 'Two dogs are needed.'),
    %% a score
    nf_tr('Il cane ha mangiato lo 0/2.', italian, spanish, M16),
    check('a number with a slash in it is one word', M16, 'El perro ha comido el 0/2.'),
    %% a comment before a colon stays before it
    nf_tr('Il cane, come si dice, mangia il pane: il gatto dorme.', italian, spanish, M17),
    check('a comment between commas is its own clause''s, and a colon after it divides first', M17,
          'El perro come el pan, como se dice: el gato duerme.'),
    %% an adverb before a clause the verb takes
    %% (MOVED in 1.8.25: this pinned `Poi il cane disse che ...', and `poi' is
    %% `then', an adverb that joins its sentence to the one before -- which
    %% stays in front now, where the source put it, `Entonces el perro dijo
    %% que ...'. The pin's point, that a lifted adverb is the main clause's
    %% and never the `that' clause's, is kept with an adverb that joins
    %% nothing, and the connecting one is pinned beside it)
    nf_tr('Oggi il cane disse che il gatto dorme.', italian, spanish, M18),
    check('a lifted adverb goes before a `that'' clause, where it read as the clause''s', M18, 'El perro dijo hoy que el gato duerme.'),
    nf_tr('Oggi il cane disse che il gatto dorme.', italian, english, M19),
    check('... and English writes it there too', M19, 'The dog said today that the cat sleeps.'),
    nf_tr('Poi il cane disse che il gatto dorme.', italian, spanish, M18b),
    check('... and a connecting adverb at the head stays in front, where the source put it', M18b, 'Entonces el perro dijo que el gato duerme.'),
    nf_tr('Poi il cane disse che il gatto dorme.', italian, english, M19b),
    check('... in English too', M19b, 'Then the dog said that the cat sleeps.'),
    %% a question word in a noun's place
    nf_tr('La cosa è difficile.', italian, english, M20),
    check('a word that is a question word and a noun is the noun in a noun''s place', M20, 'The thing is difficult.'),
    %% a determiner that is an adjective too
    nf_tr('Il cane parla con due persone diverse.', italian, spanish, M21),
    check('a determiner that is an adjective too, with nothing after it to head, is the adjective and agrees', M21,
          'El perro habla con dos personas diversas.'),
    %% a quotation that closes on a name
    nf_tr('"Il cane vede Roma".', italian, spanish, M22),
    check('a closing mark on the last word goes on the sentence, and the name keeps its capital', M22, '"El perro ve a Roma".'),
    %% names
    nf_tr('Il cane vede il presidente Mario Rossi.', italian, spanish, M23),
    check('a run of capitalised words at the end of a phrase is a name apposed to its noun', M23, 'El perro ve el presidente Mario Rossi.'),
    nf_tr('Dorme Pellegrini.', italian, spanish, M24),
    check('a capitalised word inside a sentence is no predicate adjective', M24, 'Duerme Pellegrini.'),
    nf_tr('Se a Roma va via Pellegrini, arriva Mario.', italian, spanish, M25),
    check('... and a name after a fronted place and its verb is the subject, in the singular', M25,
          'Si Pellegrini sale a Roma, llega Mario.'),
    %% three regressions the controls found in the first draft of these shapes
    nf_tr('Il cane vede il Monte Livata.', italian, spanish, M26),
    check('a GUARD: a run of capitalised words after an article alone is the phrase''s head, never a name apposed to no noun', M26,
          'El perro ve el Monte Livata.'),
    nf_tr('Due cani di 4 e 5 anni, in quelle condizioni: sono grandi.', italian, spanish, M27),
    check('a GUARD: a pronoun that stands alone ends a subject only after a determiner -- after `in'' it is the phrase''s, and `condizioni'' no verb', M27,
          'Dos perros de 4 y 5 años, en esas condiciones: son grandes.'),
    nf_tr('Il cane pensa che il gatto già dorme.', italian, spanish, M28),
    check('a GUARD: an adverb lifted from inside a `che'' clause stays the clause''s', M28,
          'El perro piensa que el gato duerme ya.').

%% ---- a Spanish report on an election into Italian (1.8.7) --------------------------------

newspaper_georgia :-
    section('a Spanish report on an election into Italian: one person named by two nouns, a comma before the coordinator, a heading with its de phrase, a share of a plural, a quotation that opens on the verb'),
    newspaper_georgia_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_georgia_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_georgia_checks,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_georgia_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
The article "lo" comes before a vowel.
"l''" is the elision of "lo". "l''" is the elision of "la". "d''" is the elision of "di".
"al" is the contraction of "a il". "del" is the contraction of "di il". "dei" is the contraction of "di i". "della" is the contraction of "di la". "nella" is the contraction of "in la". "nel" is the contraction of "in il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every number is masculine.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". The noun "minestra" means "soup". The noun "latte" means "milk". The noun "uovo" means "egg".
The noun "casa" means "house". The noun "voto" means "vote". The feminine noun "notizia" means "news".
The noun "presidente" means "president". The noun "ministro" means "minister".
The masculine noun "affari esteri" means "foreign affairs".
The adjective "ex" means "ex". The adjective "bianco" means "white". The adjective "capace" means "able".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiò" is the past of "mangia". "mangiare" is the infinitive of "mangia". "mangiando" is the gerund of "mangia".
The verb "beve" means "drinks". "bevono" is the plural of "beve". "bere" is the infinitive of "beve". "bevendo" is the gerund of "beve".
The verb "vota" means "votes". "votano" is the plural of "vota". "votò" is the past of "vota". "votarono" is the plural of "votò".
The verb "vuole" means "wants". The verb "continua" means "continues". "continuare" is the infinitive of "continua". "continua" takes "a" before the infinitive.
The verb "tenta" means "tries". "tentare" is the infinitive of "tenta". "tenta" takes "di" before the infinitive.
The verb "dice" means "says". The verb "vede" means "sees".
The verb "è" means "is". "sono" is the plural of "è".
"che" is a relative. The conjunction "che" means "that". The conjunction "e" means "and".
The preposition "a" means "to". The preposition "di" means "of". The preposition "con" means "with". The preposition "in" means "in".
The adverb "oltre" means "more than". The number "due" means "two".
The word "non" means "not". The word "non" precedes the verb.').
newspaper_georgia_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every number is masculine.
The noun "perro" means "dog". The noun "gato" means "cat".
The noun "pan" means "bread". The noun "sopa" means "soup". The noun "leche" means "milk". "leche" is feminine. The noun "huevo" means "egg".
The noun "casa" means "house". The noun "voto" means "vote". The feminine noun "noticia" means "news". The word "de" begins the clause.
The noun "presidente" means "president". "presidente" is a person. The noun "ministro" means "minister". "ministro" is a person.
The masculine noun "asuntos exteriores" means "foreign affairs".
The adjective "ex" means "ex". The adjective "blanco" means "white". The adjective "capaz" means "able".
The verb "come" means "eats". "comen" is the plural of "come". "comió" is the past of "come". "comer" is the infinitive of "come". "comiendo" is the gerund of "come".
The verb "bebe" means "drinks". "beben" is the plural of "bebe". "beber" is the infinitive of "bebe". "bebiendo" is the gerund of "bebe".
The verb "vota" means "votes". "votan" is the plural of "vota". "votó" is the past of "vota". "votaron" is the plural of "votó".
The verb "quiere" means "wants". The verb "continúa" means "continues". "continuar" is the infinitive of "continúa".
The verb "intenta" means "tries". "intentar" is the infinitive of "intenta".
The verb "dice" means "says". The verb "ve" means "sees".
The verb "es" means "is". "son" is the plural of "es".
"que" is a relative. The conjunction "que" means "that". The conjunction "y" means "and". The conjunction "e" means "and".
The word "a" precedes the person.
The preposition "a" means "to". The preposition "de" means "of". The preposition "con" means "with". The preposition "en" means "in".
The adverb "más de" means "more than". The number "dos" means "two".
The word "no" means "not". The word "no" precedes the verb.').

newspaper_georgia_checks :-
    %% two nouns under one article, and a verb that says one
    nf_tr('El presidente y ex ministro votó.', spanish, italian, G1),
    check('two nouns under one article with a singular verb are one person, where the Italian verb came out plural', G1,
          'Il presidente e ex ministro votò.'),
    %% a name apposed to an article and a name
    nf_tr('El ministro de la URSS, Eduard Shevardnadze, votó.', spanish, italian, G2),
    check('a name between commas after an article and a name, which refused the sentence', G2,
          'Il ministro della URSS, Eduard Shevardnadze, votò.'),
    nf_tr('El presidente de Adjaria votó.', spanish, italian, G3),
    check('a name keeps its capital after an elision, where it came out `d''adjaria''', G3, 'Il presidente d''Adjaria votò.'),
    %% a comma before the coordinator closes what the comma before it opened
    nf_tr('El perro come el pan, el huevo del gato, y la sopa.', spanish, italian, G4),
    check('a comma, a coordinator and a phrase join the objects before it, both commas kept', G4,
          'Il cane mangia il pane, l''uovo del gatto, e la minestra.'),
    %% an infinitive joined to another is the same verb's
    nf_tr('El perro quiere continuar con el pan y comer la sopa.', spanish, italian, G5),
    check('an infinitive joined to another takes the word its verb takes, where it took the first infinitive''s, `e a mangiare''', G5,
          'Il cane vuole continuare con il pane e mangiare la minestra.'),
    %% a heading with its de phrase
    nf_tr('El voto del perro.', spanish, italian, G6),
    check('a heading of a phrase with its `de'' phrase, `El voto de los descontentos.''', G6, 'Il voto del cane.'),
    nf_tr('Voto del perro.', spanish, italian, G7),
    check('a GUARD: a phrase with no article names nothing in particular and is still refused', G7, refused),
    %% a share of a plural
    nf_tr('Un 60% de los perros comen el pan.', spanish, italian, G8),
    check('a percentage and a plural `de'' phrase take a plural verb, which refused the sentence', G8,
          'Un 60% dei cani mangia il pane.'),
    %% an adverb before a count is the count's
    nf_tr('En la casa, más de dos perros comen el pan.', spanish, italian, G9),
    check('a front does not end on an adverb before a count, where it came out `oltre, due cani''', G9,
          'Nella casa, oltre due cani mangiano il pane.'),
    %% a quotation that opens on the verb
    nf_tr('El perro dice que el gato "come el pan".', spanish, italian, G10),
    check('a quotation that opens on the verb keeps its opening mark, where Italian closed one it never opened', G10,
          'Il cane dice che il gatto "mangia il pane".'),
    nf_tr('El perro come "el pan blanco".', spanish, english, G11),
    check('a quotation mark on a phrase stays at its edge when English moves the adjective', G11,
          'The dog eats "the white bread".'),
    %% a relative clause with a front set off by a comma
    nf_tr('El perro come con los gatos, que en la casa, no comen el pan.', spanish, italian, G12),
    check('a relative clause with a front and a comma before its verb, the front kept in front', G12,
          'Il cane mangia con i gatti, che nella casa, non mangiano il pane.'),
    %% English leaves out a subject the clause before named
    nf_tr('El perro come el pan e intenta comer la sopa.', spanish, english, G13),
    check('English leaves out the subject of a clause joined to one that named it, which refused the sentence', G13,
          'The dog eats the bread and tries to eat the soup.'),
    %% after the copula, what follows a preposition and its infinitive is the infinitive's
    nf_tr('El perro es capaz de comer el pan y beber la leche.', spanish, english, G14),
    check('an infinitive joined to one under a preposition is under it too, where English wrote `and to drink''', G14,
          'The dog is able of eating the bread and of drinking the milk.'),
    nf_tr('El perro es capaz de comer el pan y beber la leche.', spanish, italian, G15),
    check('... and Italian repeats the preposition', G15, 'Il cane è capace di mangiare il pane e di bere il latte.'),
    nf_tr('El perro es capaz de comer el pan bebiendo la leche.', spanish, italian, G16),
    check('a gerund after an infinitive after the copula is the infinitive''s, which refused the sentence', G16,
          'Il cane è capace di mangiare il pane bevendo il latte.'),
    %% a word of several words the lesson states is no name
    nf_tr('El ministro de Asuntos Exteriores come.', spanish, italian, G17),
    check('a capitalised word of several words the lesson states is the lesson''s word, never a name', G17,
          'Il ministro d''Affari esteri mangia.'),
    nf_tr('El perro come el pan que el gato ve.', spanish, italian, G18),
    check('a GUARD: a relative clause whose own subject stands before its verb still has the relative for its object', G18,
          'Il cane mangia il pane che il gatto vede.'),
    %% a clause with its own subject and object after a noun and `che'
    nf_tr('Il cane vede la notizia che il gatto mangia il pane.', italian, spanish, G19),
    check('a clause with its own subject and object after a noun and `che'' is the noun''s own clause, which the rule for the relative''s object refused -- Spanish writes `de que''', G19,
          'El perro ve la noticia de que el gato come el pan.').

%% ---- an Italian extract from the Washington Post into Spanish (1.8.8) ---------------

newspaper_wapo :-
    section('an Italian extract from the Washington Post into Spanish: of which with no verb, the one led by, a name among the adjectives, a line that is a name, a bracket at the head'),
    newspaper_wapo_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_wapo_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_wapo_checks,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_wapo_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
The article "lo" comes before a vowel.
"l''" is the elision of "lo". "l''" is the elision of "la".
"al" is the contraction of "a il". "del" is the contraction of "di il". "dei" is the contraction of "di i". "della" is the contraction of "di la". "delle" is the contraction of "di le". "dal" is the contraction of "da il". "dalla" is the contraction of "da la". "nel" is the contraction of "in il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every number is masculine.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". The noun "minestra" means "soup". The noun "casa" means "house". "case" is the plural of "casa".
The noun "governo" means "government". "governi" is the plural of "governo". The noun "giornale" means "newspaper". The noun "magnate" means "tycoon".
The noun "lista" means "list".
The masculine noun "pil" means "GDP". "pil" is the plural of "pil". "pil" is an acronym.
The feminine noun "serie" means "series". "serie" is the plural of "serie".
"italia" is feminine.
The adjective "successivo" means "successive". The adjective "televisivo" means "television". The adjective "attuale" means "current".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "guida" means "drives". "guidato" is the participle of "guida". "guidata" is the participle of "guida". "guidata" is feminine.
The verb "fissa" means "fixes". "fissato" is the participle of "fissa". "fissata" is the participle of "fissa". "fissata" is feminine. "fissate" is the plural of "fissata". "fissati" is the plural of "fissato".
The verb "esce" means "exits". "uscito" is the participle of "esce".
The verb "è" means "is". "sono" is the plural of "è". "è" is the auxiliary of "esce".
The verb "domina" means "dominates". "dominata" is the participle of "domina". "dominata" is feminine. "domina" is intransitive.
"che" is a relative. The conjunction "che" means "that". "cui" is a relative. The word "cui" follows the preposition.
The conjunction "e" means "and". The conjunction "se" means "if".
The conjunction "nonostante" means "although". The preposition "nonostante" means "despite".
The word "quello" replaces the noun. The pronoun "quello" means "that".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The pronoun "niente" means "nothing". The pronoun "niente" does not precede the verb.
The masculine pronoun "tutto" means "all". The feminine pronoun "tutta" means "all". The pronoun "tutto" does not precede the verb. The pronoun "tutta" does not precede the verb.
The adverb "solo" means "only". The number "quattro" means "four".
The masculine determiner "nessuno" means "no". "nessun" is the apocope of "nessuno".
The masculine determiner "altro" means "another". The masculine adjective "altro" means "other". The masculine pronoun "altro" means "others". The pronoun "altro" does not precede the verb.
The preposition "a" means "to". The preposition "di" means "of". The preposition "da" means "by". The preposition "da" means "from". The preposition "in" means "in". The preposition "per" means "for".').
newspaper_wapo_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every number is masculine.
The word "el" replaces the noun.
The noun "perro" means "dog". The noun "gato" means "cat".
The noun "pan" means "bread". The noun "sopa" means "soup". The noun "casa" means "house".
The noun "gobierno" means "government". The noun "diario" means "newspaper". The noun "magnate" means "tycoon".
The noun "lista" means "list".
The masculine noun "pib" means "GDP". "pib" is the plural of "pib". "pib" is an acronym.
The feminine noun "serie" means "series". "serie" is the plural of "serie".
The adjective "sucesivo" means "successive". The adjective "televisivo" means "television". The adjective "actual" means "current".
The verb "come" means "eats". "comen" is the plural of "come".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "conduce" means "drives". "conducido" is the participle of "conduce". "conducida" is the participle of "conduce". "conducida" is feminine.
The verb "fija" means "fixes". "fijado" is the participle of "fija". "fijada" is the participle of "fija". "fijada" is feminine. "fijadas" is the plural of "fijada". "fijados" is the plural of "fijado".
The verb "sale" means "exits". "salido" is the participle of "sale".
The verb "domina" means "dominates". "dominada" is the participle of "domina". "dominada" is feminine. "domina" is intransitive.
"que" is a relative. The conjunction "que" means "that". The conjunction "y" means "and". The conjunction "si" means "if".
The conjunction "aunque" means "although". The preposition "a pesar de" means "despite".
The pronoun "eso" means "that". The pronoun "eso" does not precede the verb.
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The pronoun "nada" means "nothing". The pronoun "nada" does not precede the verb.
The masculine pronoun "todo" means "all". The feminine pronoun "toda" means "all". The pronoun "todo" does not precede the verb. The pronoun "toda" does not precede the verb.
The adverb "sólo" means "only". The number "cuatro" means "four".
The masculine determiner "ningún" means "no". The masculine determiner "ninguno" means "no".
The masculine determiner "otro" means "another". The masculine adjective "otro" means "other". The masculine pronoun "otro" means "others". The pronoun "otro" does not precede the verb.
The preposition "a" means "to". The preposition "de" means "of". The preposition "por" means "for". The preposition "por" means "by". The preposition "desde" means "from". The preposition "en" means "in".
The word "a" precedes the person.').

newspaper_wapo_checks :-
    %% of which, with no verb and no comma before it
    nf_tr('Il cane vede quattro gatti di cui uno.', italian, spanish, W1),
    check('a preposition and the relative after one open a part with no verb, which was read as a relative clause and refused the sentence', W1,
          'El perro ve cuatro gatos de los que uno.'),
    nf_tr('Il cane vede quattro gatti di cui solo uno.', italian, spanish, W2),
    check('... and an adverb before its phrase is the phrase''s, in front of it in every language', W2,
          'El perro ve cuatro gatos de los que sólo uno.'),
    %% a verb that takes no object has no agent
    nf_tr('Il cane vede quattro gatti, di cui uno uscito dalla casa.', italian, spanish, W3),
    check('`da'' after the participle of a verb whose perfect takes the copula is `from'', where it was the agent, `salido por''', W3,
          'El perro ve cuatro gatos, de los que uno salido desde la casa.'),
    nf_tr('El perro ve la casa dominada por el gato.', spanish, italian, W3b),
    check('a GUARD: a verb that MAY take no object still has a passive, and its agent -- the first cut asked `intransitive'' and wrote `dominata per''', W3b,
          'Il cane vede la casa dominata dal gatto.'),
    %% the one led by
    nf_tr('Il cane vede quello guidato dal gatto.', italian, spanish, W4),
    check('a word that replaces the noun before a participle is the one it led, where it was the pronoun `that'', `eso conducido desde''', W4,
          'El perro ve el conducido por el gato.'),
    nf_tr('Il cane, quello guidato dal gatto, mangia il pane.', italian, spanish, W5),
    check('... and between two commas after a noun it is that noun said again, its commas kept', W5,
          'El perro, el conducido por el gato, come el pan.'),
    nf_tr('Il cane vede quattro gatti di cui solo uno, quello fissato dal cane, uscito dalla casa ...', italian, spanish, W6),
    check('the article''s third sentence in small: of which only one, the one fixed by, gone out from -- which was refused', W6,
          'El perro ve cuatro gatos de los que sólo uno, el fijado por el perro, salido desde la casa...'),
    nf_tr('Il cane vede quattro gatti di cui solo uno, quello fissato dal cane, uscito dalla casa ...', italian, english, W7),
    check('... and in English, the one fixed by', W7,
          'The dog sees four cats of which only one, the one fixed by the dog, exited from the house...'),
    %% a name among the adjectives
    nf_tr('Il governo Dini successivo mangia il pane.', italian, spanish, W8),
    check('adjectives may follow a name apposed to a noun, and the name keeps its place among them, which refused the sentence', W8,
          'El gobierno Dini sucesivo come el pan.'),
    nf_tr('Il cane vede il gatto guidato dal governo Dini successivo.', italian, spanish, W9),
    check('... so the phrase does not end at the name, and the agent is the whole phrase, where it came out `conducido desde''', W9,
          'El perro ve el gato conducido por el gobierno Dini sucesivo.'),
    nf_tr('Il governo guidato dal magnate televisivo Silvio Berlusconi mangia il pane.', italian, spanish, W10),
    check('a GUARD: a name after an adjective stays after it, the order the source had', W10,
          'El gobierno conducido por el magnate televisivo Silvio Berlusconi come el pan.'),
    %% an elided article before a name, and the name's gender
    nf_tr('L''Italia attuale vede il cane.', italian, spanish, W11),
    check('an elided article says no gender and the lesson says the name''s, with an adjective after the name, which refused the sentence', W11,
          'La Italia actual ve el perro.'),
    %% a word that replaces the noun before `di'
    nf_tr('Il governo vede quello di Berlusconi.', italian, spanish, W12),
    check('`quello di'' is the one of, written with the article that replaces the noun, where it was `eso de''', W12,
          'El gobierno ve al de Berlusconi.'),
    %% a pronoun that is an adjective too
    nf_tr('Nessun altro cane mangia il pane.', italian, spanish, W13),
    check('a pronoun the lesson calls an adjective too is one before a noun, which refused the phrase', W13,
          'Ningún otro perro come el pan.'),
    %% the participle's own number
    nf_tr('Il cane vede la lista delle case fissata dal gatto.', italian, spanish, W14),
    check('a participle agrees with a noun further back in number as in gender, where it agreed with the houses, `fijado''', W14,
          'El perro ve la lista de las casas fijada por el gato.'),
    %% a series of a plural
    nf_tr('Una serie di cani mangiano il pane.', italian, spanish, W15),
    check('a series of a plural takes a plural verb, as a majority does, which refused the sentence', W15,
          'Una serie de perros come el pan.'),
    nf_tr('Tutta una serie di cani mangiano il pane.', italian, spanish, W16),
    check('... and `all'' before its determiner is the phrase''s own, where the pronoun refused the subject', W16,
          'Toda una serie de perros come el pan.'),
    %% a bracket, and an ellipsis after it
    nf_tr('I cani (i gatti, le case) mangiano il pane ...', italian, spanish, W17),
    check('a bracket keeps its marks in a sentence that ends in an ellipsis, which refused the sentence', W17,
          'Los perros (los gatos, las casas) comen el pan...'),
    nf_tr('(dal giornale) il cane mangia il pane.', italian, spanish, W18),
    check('a bracket at the head of a sentence stands aside from it, which refused the sentence', W18,
          '(desde el diario) el perro come el pan.'),
    %% an answer with its condition
    nf_tr('Niente, se il cane mangia il pane.', italian, spanish, W19),
    check('a pronoun that stands alone and the condition after its comma, which refused the sentence', W19,
          'Nada, si el perro come el pan.'),
    nf_tr('Niente, se il cane mangia il pane.', italian, english, W20),
    check('... and in English', W20, 'Nothing, if the dog eats the bread.'),
    %% names
    nf_tr('The Washington Post.', italian, spanish, W21),
    check('a line of names alone is the name, which refused the sentence', W21, 'The Washington Post.'),
    nf_tr('Il cane vede il "Washington Post".', italian, spanish, W22),
    check('a name of several words in quotation marks is one name, marks kept, which refused the sentence', W22,
          'El perro ve el "Washington Post".'),
    %% the acronym, and the preposition that is a conjunction too
    nf_tr('Il cane mangia il pil.', italian, spanish, W23),
    check('an acronym is written in capitals, where it came out `pib''', W23, 'El perro come el PIB.'),
    nf_tr('Il cane mangia il pane nonostante la minestra.', italian, spanish, W24),
    check('a preposition crosses by its meaning as one when its first is a conjunction''s, where it came out `aunque la sopa''', W24,
          'El perro come el pan a pesar de la sopa.'),
    nf_tr('Il cane mangia il pane nonostante il gatto mangia la minestra.', italian, spanish, W25),
    check('a GUARD: before a clause it is still the conjunction', W25,
          'El perro come el pan aunque el gato come la sopa.'),
    %% a piece with no subject agrees with nothing before it
    nf_tr('La casa vede il cane. (dal giornale) guidato pane del gatto.', italian, spanish, W26),
    check('a participle with no subject is masculine, where it agreed with the subject of the sentence before, `conducida''', W26,
          'La casa ve el perro. (desde el diario) conducido pan del gato.').

%% ---- the Clinton inquiry (AnCora CESS-CAST-P-19981202-34), into Italian -------------------

newspaper_clinton :-
    section('a Spanish report on the Clinton inquiry into Italian: al and an infinitive in front, according to and who said so, a gerund with its pronoun, what it does is'),
    newspaper_clinton_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_clinton_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_clinton_checks,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_clinton_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "el" replaces the noun. The word "lo" replaces the noun.
The word "al" begins the moment. The word "para" begins the purpose. The word "no" means "not".
The noun "perro" means "dog". The noun "gato" means "cat".
The noun "pan" means "bread". The noun "sopa" means "soup". The noun "casa" means "house".
The noun "ministra" means "minister". The noun "mayoría" means "majority". "mayoría" is a person.
The noun "insistencia" means "insistence". The noun "fuente" means "source".
The feminine noun "sesión" means "session". "sesiones" is the plural of "sesión".
The noun "reno" means "reindeer". The noun "justicia" means "justice".
The adjective "grande" means "big". The adjective "aceptable" means "acceptable".
The adverb "a puerta cerrada" means "behind closed doors". The adverb "muy" means "very".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
The verb "aprieta" means "tightens". "apretado" is the participle of "aprieta".
The verb "permite" means "allows". "permite" takes "a" before the person.
The verb "duerme" means "sleeps". "dormir" is the infinitive of "duerme".
The verb "ve" means "sees". "visto" is the participle of "ve".
The verb "busca" means "searches". "buscar" is the infinitive of "busca".
The verb "acusa" means "accuses". "acusó" is the past of "acusa".
The verb "escribe" means "writes". "escribió" is the past of "escribe". "escribe" takes "a" before the person.
The verb "pide" means "asks". "pidiendo" is the gerund of "pide".
The verb "abre" means "opens". "abrir" is the infinitive of "abre".
The verb "dice" means "says". The verb "hace" means "does".
The verb "añade" means "adds". "añaden" is the plural of "añade". "añadieron" is the past of "añaden".
The verb "centra" means "centres". "centrado" is the participle of "centra". "centrada" is the participle of "centra". "centrada" is feminine. "centradas" is the participle of "centra". "centradas" is feminine. "centradas" is the plural of "centrada". "centrados" is the participle of "centra". "centrados" is the plural of "centrado".
The verb "es" means "is". "son" is the plural of "es". "siendo" is the gerund of "es".
The auxiliary "está" means "is".
"que" is a relative. The conjunction "que" means "that".
The pronoun "lo" means "him". The pronoun "le" means "him". The dative pronoun "le" means "him".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "por" means "by". The preposition "según" means "according to". The preposition "para" means "for".
The word "a" precedes the person.
"wrote" is the past of "writes". "seen" is the participle of "sees".').
newspaper_clinton_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The article "lo" comes before a vowel.
"l''" is the elision of "lo". "l''" is the elision of "la".
"al" is the contraction of "a il". "alla" is the contraction of "a la". "del" is the contraction of "di il". "nel" is the contraction of "in il". "nella" is the contraction of "in la". "dal" is the contraction of "da il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "quello" replaces the noun. The pronoun "quello" means "that". The pronoun "quello" does not precede the verb.
The word "per" begins the purpose. The preposition "per" means "for". The word "non" means "not".
The noun "cane" means "dog". The noun "gatto" means "cat".
The noun "pane" means "bread". The noun "minestra" means "soup". The noun "casa" means "house".
The noun "ministro" means "minister". The noun "maggioranza" means "majority". The noun "insistenza" means "insistence".
The noun "fonte" means "source". "fonti" is the plural of "fonte". "fonte" is feminine.
The feminine noun "sessione" means "session". "sessioni" is the plural of "sessione".
The adjective "grande" means "big". The adjective "accettabile" means "acceptable".
The adverb "a porte chiuse" means "behind closed doors". The adverb "molto" means "very".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
The verb "stringe" means "tightens". "stretto" is the participle of "stringe".
The verb "permette" means "allows".
The verb "dorme" means "sleeps". "dormire" is the infinitive of "dorme".
The verb "vede" means "sees". "visto" is the participle of "vede".
The verb "cerca" means "searches". "cercare" is the infinitive of "cerca". "cerca" takes "di" before the infinitive.
The verb "accusa" means "accuses". "accusò" is the past of "accusa".
The verb "scrive" means "writes". "scrisse" is the past of "scrive".
The verb "chiede" means "asks". "chiedendo" is the gerund of "chiede".
The verb "apre" means "opens". "aprendo" is the gerund of "apre".
The verb "dice" means "says". The verb "fa" means "does".
The verb "aggiunge" means "adds". "aggiungono" is the plural of "aggiunge". "aggiunsero" is the past of "aggiungono".
The verb "centra" means "centres". "centrato" is the participle of "centra". "centrata" is the participle of "centra". "centrata" is feminine. "centrate" is the participle of "centra". "centrate" is feminine. "centrate" is the plural of "centrata". "centrati" is the participle of "centra". "centrati" is the plural of "centrato".
The verb "è" means "is". "sono" is the plural of "è". "essendo" is the gerund of "è".
The auxiliary "sta" means "is".
The verb "viene" means "comes". "vengono" is the plural of "viene". The verb "viene" marks the passive.
"che" is a relative. The conjunction "che" means "that".
The dative pronoun "gli" means "him".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "da" means "by". The preposition "come" means "as".').

newspaper_clinton_checks :-
    %% the word before a person, and the object after it the infinitive's
    nf_tr('La casa acusó a la mayoría de buscar el pan.', spanish, italian, C1),
    check('an object after an infinitive is the infinitive''s, and made the person the verb''s indirect object, `alla maggioranza''', C1,
          'La casa accusò la maggioranza di cercare il pane.'),
    nf_tr('El perro escribió a Maria.', spanish, italian, C2),
    check('a verb the lesson says takes `a'' before the person writes TO them, where it was `scrisse Maria''', C2,
          'Il cane scrisse a Maria.'),
    %% a gerund with its own pronoun
    nf_tr('El perro escribió a Maria, pidiéndole el pan.', spanish, italian, C3),
    check('a pronoun joined to a gerund is its object and is joined back, where it headed a phrase', C3,
          'Il cane scrisse a Maria, chiedendogli il pane.'),
    nf_tr('El perro escribió a Maria, pidiéndole el pan.', spanish, english, C4),
    check('... and in English it follows the gerund', C4, 'The dog wrote to Maria, asking him the bread.'),
    %% `al'' and an infinitive in front, to its comma
    nf_tr('Al abrir la casa, el perro come el pan.', spanish, italian, C5),
    check('`al'' and an infinitive stand in front and end at their comma, which refused the sentence', C5,
          'Aprendo la casa, il cane mangia il pane.'),
    nf_tr('Al abrir la casa, el perro come el pan.', spanish, english, C6),
    check('... and in English', C6, 'On opening the house, the dog eats the bread.'),
    %% a quotation that opens on an infinitive subject
    nf_tr('El perro dice que "comer pan no es aceptable".', spanish, italian, C7),
    check('an infinitive that opens a quotation keeps its mark, which was lost', C7,
          'Il cane dice che "mangiare pane non è accettabile".'),
    %% the progressive of a passive
    nf_tr('El perro está siendo visto.', spanish, italian, C8),
    check('the progressive of a passive is the verb the lesson says marks the passive, where it was `sta essendo visto''', C8,
          'Il cane viene visto.'),
    nf_tr('El perro está siendo visto.', spanish, english, C9),
    check('... and English writes the copula''s progressive, `is being'', which it refused', C9, 'The dog is being seen.'),
    %% according to, and who said so
    nf_tr('El perro come el pan, según añadieron las fuentes.', spanish, italian, C10),
    check('`según'' and a clause with its speaker after its verb report the rest, where the sources were an object', C10,
          'Il cane mangia il pane, come aggiunsero le fonti.'),
    nf_tr('El perro come el pan, según añadieron las fuentes.', spanish, english, C11),
    check('... and in English', C11, 'The dog eats the bread, as the sources added.'),
    %% a name apposed between commas whose second word the lesson knows
    nf_tr('La ministra, Janet Reno, come el pan.', spanish, italian, C12),
    check('a name opens on a word no lesson knows and runs on through capitals, where `reno'' ended it and the commas were lost', C12,
          'Il ministro, Janet Reno, mangia il pane.'),
    nf_tr('La ministra de Justicia, Janet Reno, come el pan.', spanish, italian, C13),
    check('... and after `de'' and a capitalised word the lesson knows, which refused the sentence', C13,
          'Il ministro di Justicia, Janet Reno, mangia il pane.'),
    %% what it does
    nf_tr('Lo que hace es comer el pan.', spanish, italian, C14),
    check('`lo que'' is the word that replaces a noun and a relative clause, where it was `him that'', and as a subject it is written', C14,
          'Quello che fa è mangiare il pane.'),
    nf_tr('La insistencia lo que hace es comer el pan.', spanish, italian, C15),
    check('a phrase in front of it with no comma is what it is about, which refused the sentence', C15,
          'L''insistenza quello che fa è mangiare il pane.'),
    nf_tr('El perro dice que la insistencia lo que hace es comer el pan.', spanish, italian, C16),
    check('... and after `que'' too', C16, 'Il cane dice che l''insistenza quello che fa è mangiare il pane.'),
    %% a subject with a purpose in it
    nf_tr('La insistencia en buscar el pan para comer la sopa es grande.', spanish, italian, C17),
    check('a purpose and its object stay inside a subject, which refused the sentence', C17,
          'L''insistenza in cercare il pane per mangiare la minestra è grande.'),
    %% an adverb between a noun and its participle
    nf_tr('El perro come el pan en sesiones a puerta cerrada centradas en la casa.', spanish, italian, C18),
    check('an adverb between a noun and its participle is the participle''s and stands before it, where the participle agreed with the subject, `centrato''', C18,
          'Il cane mangia il pane in sessioni a porte chiuse centrate nella casa.'),
    %% GUARD: the controls found it -- an intensifier before a participle is
    %% the participle's too, and the first cut wrote it after, `stretto molto'
    nf_tr('El perro come el pan muy apretado.', spanish, italian, C19),
    check('an intensifier before a participle stays before it', C19,
          'Il cane mangia il pane molto stretto.'),
    %% the person a verb gives something to, before an infinitive with no object
    nf_tr('El perro permite a Maria dormir.', spanish, italian, C20),
    check('a verb the lesson says takes `a'' before the person gives TO them before an infinitive too, where it was `permette Maria''', C20,
          'Il cane permette a Maria dormire.').

newspaper_letter :-
    section('an Italian letter into Spanish: adjectives before a name and before a subject, two clauses of che, an object in front, the subject after its verb, a signature'),
    newspaper_letter_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_letter_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_letter_checks,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_letter_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The article "lo" comes before a vowel.
"l''" is the elision of "lo". "l''" is the elision of "la".
"al" is the contraction of "a il". "alla" is the contraction of "a la". "del" is the contraction of "di il". "della" is the contraction of "di la". "nel" is the contraction of "in il". "nella" is the contraction of "in la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not". The word "di" begins the infinitive.
The masculine demonstrative "quello" means "that". "quelli" is the plural of "quello". "quel" is the apocope of "quello". "quei" is the plural of "quel".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane". The noun "casa" means "house". The noun "momento" means "moment".
The noun "domanda" means "question". The noun "via" means "way". The adverb "via" means "away".
The adjective "grande" means "big". "grandi" is the plural of "grande".
The masculine adjective "rosso" means "red". "rossi" is the plural of "rosso". The feminine adjective "rossa" means "red". "rosse" is the plural of "rossa".
The adjective "nuovo" means "new". "nuovi" is the plural of "nuovo".
The adjective "piccolo" means "small". "piccoli" is the plural of "piccolo". The adjective "vecchio" means "old". "vecchi" is the plural of "vecchio". The noun "vecchio" means "old man".
The masculine adjective "stanco" means "tired". The feminine adjective "stanca" means "tired".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "dice" means "says". The verb "segue" means "follows".
The verb "decide" means "decides". "decidere" is the infinitive of "decide". "decide" takes the question.
The verb "rende" means "renders". "rendere" is the infinitive of "rende". The verb "rende conto" means "realizes". "rendere conto" is the infinitive of "rende conto".
The verb "ha" means "has". "hanno" is the plural of "ha". "ho" is the first person of "ha".
"ce" is the particle of "ha".
The verb "è" means "is". "sono" is the plural of "è". "sono" is the first person of "è". "essere" is the infinitive of "è".
The intransitive verb "viene" means "comes". "venuto" is the participle of "viene". "è" is the auxiliary of "viene". "come" is the participle of "comes".
The auxiliary "sta" means "is". "stare" is the infinitive of "sta".
The verb "guarda" means "watches". "guardare" is the infinitive of "guarda".
The verb "pone" means "puts". "porre" is the infinitive of "pone".
The verb "cerca" means "searches". "cercare" is the infinitive of "cerca". "cerca" takes "di" before the infinitive.
"che" is a relative. The conjunction "che" means "that". The word "che" means "what".
The word "che cosa" means "what". The word "chi" means "who".
The conjunction "e" means "and". The conjunction "ma" means "but".
The conjunction "se" means "if". The conjunction "mentre" means "while".
The pronoun "sé" means "itself". The pronoun "sé" does not precede the verb.
The pronoun "lo" means "him". The pronoun "la" means "her". The reflexive pronoun "si" means "itself".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "con" means "with". The preposition "come" means "like". The preposition "senza" means "without". The preposition "per" means "for". The preposition "davanti a" means "in front of".
The adverb "solo" means "only". The adverb "forse" means "perhaps".
The noun "minestra" means "soup".
The verb "cucina" means "cooks". "cucinato" is the participle of "cucina". "cucinata" is the participle of "cucina". "cucinata" is feminine.
The conjunction "purché" means "provided that". The conjunction "per cui" means "so".
The modal "deve" means "must".
The adverb "meno" means "less". The conjunction "che" means "than".
The pronoun "loro" means "them". The pronoun "loro" does not precede the verb.
The dative pronoun "gli" means "them". The dative pronoun "loro" means "them".
The verb "chiede" means "asks". "chiedere" is the infinitive of "chiede".').
newspaper_letter_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural. Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not".
The masculine demonstrative "ese" means "that". "esos" is the plural of "ese". The feminine demonstrative "esa" means "that". "esas" is the plural of "esa".
The noun "perro" means "dog". The noun "gato" means "cat".
The noun "pan" means "bread". "panes" is the plural of "pan". The noun "casa" means "house". The noun "momento" means "moment".
The noun "pregunta" means "question". The noun "camino" means "way".
The adjective "grande" means "big". "grandes" is the plural of "grande".
The masculine adjective "rojo" means "red". The feminine adjective "roja" means "red".
The adjective "nuevo" means "new". The adjective "viejo" means "old". The noun "viejo" means "old man". The adjective "pequeño" means "small".
The masculine adjective "cansado" means "tired". The feminine adjective "cansada" means "tired".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "dice" means "says". The verb "sigue" means "follows".
The verb "decide" means "decides". "decidir" is the infinitive of "decide". "decide" takes the question.
The verb "da" means "gives". "dar" is the infinitive of "da". The verb "da cuenta" means "realizes". "dar cuenta" is the infinitive of "da cuenta". "da cuenta" takes "de" before the clause.
The verb "tiene" means "has". "tienen" is the plural of "tiene". "tengo" is the first person of "tiene".
The verb "es" means "is". "son" is the plural of "es". "soy" is the first person of "es". "ser" is the infinitive of "es".
The intransitive verb "viene" means "comes". "venido" is the participle of "viene".
The verb "ha" means "has". The auxiliary "ha" means "has". "han" is the plural of "ha".
The auxiliary "está" means "is". "estar" is the infinitive of "está". The auxiliary "está" marks the state.
The verb "mira" means "watches". "mirar" is the infinitive of "mira".
The verb "pone" means "puts". "poner" is the infinitive of "pone".
The verb "busca" means "searches". "buscar" is the infinitive of "busca".
"que" is a relative. The conjunction "que" means "that". The word "qué" means "what". The word "qué" means "which". The word "quién" means "who".
The conjunction "y" means "and". The conjunction "pero" means "but".
The conjunction "si" means "if". The conjunction "mientras" means "while".
The pronoun "sí" means "itself". The pronoun "sí" does not precede the verb.
The pronoun "lo" means "him". The pronoun "la" means "her". The reflexive pronoun "se" means "itself".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with". The preposition "como" means "like". The preposition "sin" means "without". The preposition "para" means "for". The preposition "delante de" means "in front of".
The adverb "sólo" means "only". The adverb "quizás" means "perhaps".
The mark "¿" begins the question.
The noun "sopa" means "soup".
The verb "cocina" means "cooks". "cocinado" is the participle of "cocina". "cocinada" is the participle of "cocina". "cocinada" is feminine.
The conjunction "siempre que" means "provided that". The conjunction "por lo que" means "so".
The modal "debe" means "must".
The adverb "menos" means "less". The conjunction "que" means "than".
The dative pronoun "les" means "them".
The verb "pide" means "asks". "pedir" is the infinitive of "pide".
"debe" is the imperative of "debe".').

newspaper_letter_checks :- newspaper_letter_checks_1, newspaper_letter_checks_2.
newspaper_letter_checks_1 :-
    %% a list of adjectives before a name, each set off by a comma
    nf_tr('Il cane mangia il pane con i nuovi, piccoli, Hitler.', italian, spanish, L1),
    check('adjectives between commas before a name are one phrase, where the first comma was an aside and the second a list: refused', L1,
          'El perro come el pan con los nuevos, pequeños, Hitler.'),
    nf_tr('Il cane mangia il pane con i nuovi, piccoli, Hitler.', italian, english, L2),
    check('... and in English', L2,
          'The dog eats the bread with the new, small, Hitler.'),
    %% adjectives in front, before their comma
    nf_tr('Grande e rosso, il cane mangia il pane.', italian, spanish, L3),
    check('adjectives at the head before a comma are said of the subject and stand in front, which refused the sentence', L3,
          'Grande y rojo, el perro come el pan.'),
    nf_tr('Grande e rosso, il cane mangia il pane.', italian, english, L4),
    check('... and in English', L4,
          'Big and red, the dog eats the bread.'),
    nf_tr('Stanca e rossa, la casa dorme.', italian, spanish, L5),
    check('... and they agree with the subject''s noun, which a first cut wrote masculine', L5,
          'Cansada y roja, la casa duerme.'),
    %% two clauses of `che' joined
    nf_tr('Il cane dice che la casa è grande e che il gatto mangia il pane.', italian, spanish, L6),
    check('two `che'' clauses joined by `e'' are both the verb''s, which refused the sentence', L6,
          'El perro dice que la casa es grande y que el gato come el pan.'),
    %% an idiom of two words, and the preposition its clause takes
    nf_tr('Il cane si rende conto che la casa è grande.', italian, spanish, L7),
    check('`"da cuenta" takes "de" before the clause.'': Spanish writes it, where it was `se da cuenta que''', L7,
          'El perro se da cuenta de que la casa es grande.'),
    nf_tr('El perro se da cuenta de que la casa es grande.', spanish, italian, L8),
    check('... and reads it, which refused the sentence', L8,
          'Il cane si rende conto che la casa è grande.'),
    nf_tr('Il cane mangia il pane senza rendersi conto che la casa è grande.', italian, spanish, L9),
    check('the pronoun joined to the first word of a verb of two words is cut off and the words are joined, which refused the sentence', L9,
          'El perro come el pan sin darse cuenta de que la casa es grande.'),
    nf_tr('Il cane mangia il pane senza rendersi conto che la casa è grande.', italian, english, L10),
    check('... and in English', L10,
          'The dog eats the bread without realizing that the house is big.'),
    %% a clause of `che' with an insertion before its subject
    nf_tr('Il cane dice che, come il gatto, la casa è grande.', italian, spanish, L11),
    check('an insertion between `che'' and its subject keeps its place and its commas, where it went last', L11,
          'El perro dice que, como el gato, la casa es grande.'),
    %% a question with no question word and commas in it
    nf_tr('Il cane, come il gatto, mangia il pane?', italian, spanish, L12),
    check('a question with commas is read with them, where they were lost', L12,
          '¿El perro, como el gato, come el pan?'),
    nf_tr('Grande e rosso, il cane mangia il pane?', italian, spanish, L13),
    check('... and adjectives in front of it', L13,
          '¿Grande y rojo, el perro come el pan?'),
    %% the object in front and taken up by a pronoun, and `ce'
    nf_tr('Il cane il pane non ce l''ha.', italian, spanish, L14),
    check('an object in front taken up by a clitic is the object, and `"ce" is the particle of "ha".'', which refused the sentence', L14,
          'El perro no tiene el pan.'),
    nf_tr('Il cane il pane non ce l''ha.', italian, english, L15),
    check('... and in English', L15,
          'The dog does not have the bread.'),
    %% a second clause whose verb is a first person and a third plural alike
    nf_tr('I cani mangiano il pane e sono grandi.', italian, spanish, L16),
    check('`sono'' after `e'' is the subject before it, where it was `soy'', I', L16,
          'Los perros comen el pan y son grandes.'),
    nf_tr('I cani mangiano il pane e sono grandi.', italian, english, L17),
    check('... and in English', L17,
          'The dogs eat the bread and are big.'),
    %% a verb that takes a question
    nf_tr('Il cane decide se il gatto mangia il pane.', italian, english, L18),
    check('`"decide" takes the question.'' makes `se'' after it whether, where it was if', L18,
          'The dog decides whether the cat eats the bread.'),
    %% a noun with its own infinitive, the subject after an intransitive verb
    nf_tr('È venuto il momento di mangiare il pane.', italian, spanish, L19),
    check('a subject after its verb keeps the infinitive its noun takes, where `de'' was lost', L19,
          'Ha venido el momento de comer el pan.'),
    nf_tr('Forse è venuto il momento di mangiare il pane.', italian, spanish, L20),
    check('... with an adverb in front, which stays there, where the moment came to eat', L20,
          'Quizás ha venido el momento de comer el pan.'),
    nf_tr('Forse è venuto il momento di porsi la domanda, e decidere se il gatto mangia il pane.', italian, spanish, L21),
    check('... and the subject ends at the comma, which refused the sentence', L21,
          'Quizás ha venido el momento de ponerse la pregunta, y decidir si el gato come el pan.'),
    %% the infinitive of the copula of a state
    nf_tr('Il cane cerca di stare nella casa.', italian, spanish, L22),
    check('`stare'' is the infinitive of the state, `estar'', where it was `ser''', L22,
          'El perro busca estar en la casa.'),
    %% a verb in -rre with its pronoun joined
    nf_tr('Il cane cerca di porsi la domanda.', italian, spanish, L23),
    check('`porsi'' is `porre'' and `si'', which refused the sentence', L23,
          'El perro busca ponerse la pregunta.'),
    %% a signature and the next letter's title
    nf_tr('Maria Bianchi Roma - Milano P pane "rosso".', italian, spanish, L24),
    check('names, a dash, names and a noun with a word in quotation marks are written as they stood, which refused the line', L24,
          'Maria Bianchi Roma – Milano P pan "rojo".'),
    %% a heading of one word
    nf_tr('Cani.', italian, spanish, L35),
    check('a bare noun of one word names the section it opens, which refused the line', L35,
          'Perros.'),
    %% the apocope before a plural noun
    nf_tr('Quei cani mangiano il pane.', italian, spanish, L25),
    check('`"quei" is the plural of "quel".'', and `quel'' the apocope of `quello'', which refused the sentence', L25,
          'Esos perros comen el pan.'),
    %% a reflexive after a preposition
    nf_tr('Il cane ha davanti a sé il pane.', italian, spanish, L26),
    check('`sé'' after a preposition is an object pronoun, which refused the sentence', L26,
          'El perro tiene delante de sí el pan.'),
    %% a question word inside a phrase
    nf_tr('In che casa dorme il cane?', italian, spanish, L27),
    check('`in che casa'' asks which house, where it was `¿Casa duerme el perro en qué?''', L27,
          '¿En qué casa duerme el perro?'),
    nf_tr('Che cosa è venuto?', italian, english, L28),
    check('`che cosa'' is what, the subject of an intransitive verb, which refused the sentence', L28,
          'What has come?'),
    %% a question after a colon
    nf_tr('Il cane dice: che cosa mangia il gatto?', italian, spanish, L29),
    check('a question after a colon is written as one, which refused the sentence', L29,
          'El perro dice: ¿qué come el gato?'),
    %% two adjectives joined before a noun, the first a noun too
    nf_tr('Il cane guarda i vecchi e rossi gatti.', italian, english, L30),
    check('two adjectives joined before one noun are one phrase, where the old ones were a second thing', L30,
          'The dog watches the old and red cats.'),
    %% a noun after its article that is an adverb too
    nf_tr('Il cane segue solo la via della casa.', italian, spanish, L31),
    check('`la via'' is the way, where `via'' was away and `la'' her', L31,
          'El perro sigue sólo el camino de la casa.'),
    nf_tr('Il cane segue solo la via della casa.', italian, english, L32),
    check('... and in English', L32,
          'The dog follows the way of the house only.'),
    %% a question in parentheses, and two phrases
    nf_tr('Il cane dorme (ma chi dorme)?', italian, spanish, L33),
    check('a clause in parentheses that is a question is one, which refused the sentence', L33,
          '¿El perro duerme (pero quién duerme)?'),
    nf_tr('Il cane mangia il pane della casa (ma la casa di chi e per chi)?', italian, spanish, L34),
    check('... and two phrases joined, which refused the sentence', L34,
          '¿El perro come el pan de la casa (pero la casa de quién y para quién)?').

%% (in two clauses, because one holding every check ran over the page a
%% stored clause must fit in, which cocolint flags)
newspaper_letter_checks_2 :-
    %% a clause of `mentre' joined inside the clause of `che' it belongs to
    reason_ir('Il cane dice che il gatto guarda mentre la casa dorme e il pane è grande.', italian, IR36),
    yes_no(IR36 = [ir(s(_, _, g(says, _, _, _), [that(join(w(while, _), _, join(w(and, _), _, _)))]), _)], C36),
    check('a division inside a nested clause stays inside it, where the sentence was divided at `mentre'' and the dog said less', C36, yes),
    %% GUARDS the controls wrote, each on the first cut of this version
    %% a participle standing alone in a clause with no verb
    nf_tr('Il cane mangia la minestra, purché cucinata con il pane, e con la casa.', italian, spanish, L37),
    check('a GUARD: a participle in a clause with no verb agrees with the form the source gave it, where the first cut wrote `cocinado''', L37,
          'El perro come la sopa, siempre que cocinada con el pan, y con la casa.'),
    %% a quotation that closes before a connector
    nf_tr('El perro dice que "el pan es grande y debe comer la sopa", por lo que la casa duerme.', spanish, italian, L38),
    check('a GUARD: a nested clause is not divided after its closing mark, where the first cut took `por lo que'' into the quotation and refused', L38,
          'Il cane dice che "il pane è grande e deve mangiare la minestra", per cui la casa dorme.'),
    nf_tr('El perro dice que el gato come el pan, pero la casa duerme.', spanish, italian, L42),
    check('a GUARD: ... nor where the sentence has a comma, which a nested clause is read without -- the first cut took `pero'' into the `que'' clause and lost the comma', L42,
          'Il cane dice che il gatto mangia il pane, ma la casa dorme.'),
    %% a comparison whose second term has a preposition
    nf_tr('El perro come menos que en la casa.', spanish, italian, L39),
    check('a GUARD: `que'' and a preposition after `menos'' are a comparison, where the first cut refused -- `que'' is no noun', L39,
          'Il cane mangia meno che nella casa.'),
    nf_tr('El perro come menos que en la casa.', spanish, english, L40),
    check('... and English writes the adverb before `than'', where it went last', L40,
          'The dog eats less than in the house.'),
    %% a dative that stands after the verb is read, and the clitic written
    nf_tr('El perro come sin pedirles el pan.', spanish, italian, L41),
    check('the dative written is one that stands before the verb, where `loro'' was joined to the infinitive', L41,
          'Il cane mangia senza chiedergli il pane.').

newspaper_solana :-
    section('a Spanish report into Italian: a name in quotation marks, an aside after a name, a reporting clause at the end, a title before a name, an adjective in the lesson''s order'),
    newspaper_solana_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_solana_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_solana_checks,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_solana_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural. Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "casa" means "house". The noun "sopa" means "soup". The noun "puerta" means "door".
The noun "ministro" means "minister". "ministro" is a person. The noun "amigo" means "friend". "amigo" is a person.
The noun "señor" means "gentleman". "señor" is a person.
The noun "jueves" means "thursday". "jueves" is a time.
The adjective "grande" means "big". "grandes" is the plural of "grande".
The masculine adjective "rojo" means "red". The feminine adjective "roja" means "red".
The adjective "común" means "common".
The verb "come" means "eats". "comen" is the plural of "come". "come" is the imperative of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "ve" means "sees". The verb "dice" means "says". The verb "abre" means "opens".
The verb "conoce" means "knows". "conocido" is the participle of "conoce".
The verb "es" means "is". "son" is the plural of "es".
"que" is a relative. The conjunction "que" means "that".
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "si" means "if".
The conjunction "ni" means "neither". The conjunction "ni" means "nor".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with". The preposition "como" means "as".
The adjective "actual" means "current". "actuales" is the plural of "actual".
The auxiliary "ha" means "has". "han" is the plural of "ha". The verb "ha" means "has".
"sido" is the participle of "es".
"visto" is the participle of "ve". "vista" is the participle of "ve". "vista" is feminine.
"vistos" is the participle of "ve". "vistas" is the participle of "ve". "vistas" is feminine.
"vistos" is the plural of "visto". "vistas" is the plural of "vista".
The preposition "por" means "by".
The preposition "tras" means "after". The adverb "después" means "after".
The reflexive pronoun "se" means "itself".').
newspaper_solana_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The article "lo" comes before a vowel.
"l''" is the elision of "lo". "l''" is the elision of "la".
"al" is the contraction of "a il". "dal" is the contraction of "da il". "del" is the contraction of "di il". "della" is the contraction of "di la". "nel" is the contraction of "in il". "nella" is the contraction of "in la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". The noun "casa" means "house". The noun "minestra" means "soup". The noun "porta" means "door".
The noun "ministro" means "minister". The noun "amico" means "friend".
The noun "signore" means "gentleman". "signor" is the apocope of "signore".
The noun "giovedì" means "thursday". "giovedì" is a time.
The adjective "grande" means "big". "grandi" is the plural of "grande".
The masculine adjective "rosso" means "red". The feminine adjective "rossa" means "red".
The adjective "comune" means "common". The feminine noun "corrente" means "current". The adjective "corrente" means "common".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "vede" means "sees". The verb "dice" means "says". The verb "apre" means "opens".
The verb "conosce" means "knows". "conosciuto" is the participle of "conosce".
The verb "è" means "is". "sono" is the plural of "è".
"che" is a relative. The conjunction "che" means "that".
The conjunction "e" means "and". The conjunction "ma" means "but". The conjunction "se" means "if".
The adverb "neanche" means "neither". The conjunction "né" means "neither". The conjunction "né" means "nor".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "con" means "with". The preposition "come" means "as".
The adjective "attuale" means "current". "attuali" is the plural of "attuale".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". The verb "ha" means "has".
"stato" is the participle of "è". "stata" is the participle of "è". "stata" is feminine. "è" is the auxiliary of "è".
"visto" is the participle of "vede". "vista" is the participle of "vede". "vista" is feminine.
"visti" is the participle of "vede". "viste" is the participle of "vede". "viste" is feminine.
"visti" is the plural of "visto". "viste" is the plural of "vista".
"porte" is the plural of "porta". "quale" is a relative.
The preposition "da" means "by".
The preposition "dopo" means "after". The adverb "dopo" means "after".
The reflexive pronoun "si" means "itself".').

newspaper_solana_checks :- newspaper_solana_checks_1, newspaper_solana_checks_2.
newspaper_solana_checks_1 :-
    %% a name at the head of a quotation
    nf_tr('El perro dice que "María come el pan".', spanish, italian, L1),
    check('a name at the head of a quotation keeps its capital and the mark before it, which refused the sentence', L1,
          'Il cane dice che "María mangia il pane".'),
    nf_tr('El perro dice que "María come el pan" y que "el gato duerme".', spanish, italian, L2),
    check('... and two quoted clauses of `que'' joined, the second closing on its verb', L2,
          'Il cane dice che "María mangia il pane" e che "il gatto dorme".'),
    %% a phrase between commas after a name
    nf_tr('El perro ve a Juan Pérez, amigo del gato, en la casa.', spanish, italian, L3),
    check('a phrase between commas after a name is the name''s aside, where the name was read after `to'' and the phrase as a second object', L3,
          'Il cane vede Juan Pérez, amico del gatto, nella casa.'),
    nf_tr('La casa de Juan, amigo del gato, ha sido vista por el perro.', spanish, italian, L4),
    check('... and after a name in the subject, where the phrase was a clause of its own and the participle agreed with nobody', L4,
          'La casa di Juan, amico del gatto, è stata vista dal cane.'),
    %% a participle and its phrases between commas
    nf_tr('El perro, conocido en la casa como Rex, come el pan.', spanish, italian, L5),
    check('a participle with its own phrases between commas after the subject is an aside and keeps its commas, where they were lost', L5,
          'Il cane, conosciuto nella casa come Rex, mangia il pane.'),
    %% a quotation that closes on its verb
    nf_tr('El perro dice que "el gato duerme" en la casa.', spanish, italian, L6),
    check('a quotation that closes on its verb closes there, where the closing mark was lost', L6,
          'Il cane dice che "il gatto dorme" nella casa.'),
    %% a day the source capitalises
    nf_tr('El perro come el pan el Jueves.', spanish, italian, L7),
    check('a day the source capitalises is written as a day, where Italian wrote `Giovedì''', L7,
          'Il cane mangia il pane il giovedì.'),
    %% a heading of a noun and a name
    nf_tr('Pan de María.', spanish, italian, L8),
    check('a bare noun of a name is a heading, which refused the line', L8,
          'Pane di María.'),
    nf_tr('Pan del perro.', spanish, italian, L9),
    check('a GUARD: ... and a bare noun of a phrase stays refused, as since 1.8.7', L9, refused),
    %% a name that goes on through a noun
    nf_tr('El perro ve a Juan Casa.', spanish, italian, L10),
    check('a name that opens on a word no lesson knows goes on through a capitalised noun the lesson knows, which refused the sentence', L10,
          'Il cane vede Juan Casa.').

%% (in two clauses, because one holding every check ran over the page a
%% stored clause must fit in)
newspaper_solana_checks_2 :-
    %% one word in capitals between brackets
    nf_tr('El perro come el pan de la casa (UE).', spanish, italian, L11),
    check('one word in capitals between brackets is an acronym, where it came out `Ue''', L11,
          'Il cane mangia il pane della casa (UE).'),
    %% a capitalised adjective standing alone
    nf_tr('El perro duerme en Roja.', spanish, italian, L12),
    check('a capitalised adjective standing alone after a preposition is a name, as a noun is since 1.7.0, where it was `in Rosso''', L12,
          'Il cane dorme in Roja.'),
    %% a reporting clause at the end, after a plain comma
    nf_tr('El perro come el pan, dice el ministro de la casa, Abel Matutes.', spanish, italian, L13),
    check('a clause at the end whose subject is a person reports the rest, and a name after the last comma is apposed, where the name went to the first clause', L13,
          'Il cane mangia il pane, dice il ministro della casa, Abel Matutes.'),
    nf_tr('El perro come el pan, dice el ministro.', spanish, english, L14),
    check('... and in English, where the minister was the object of nobody and English refused', L14,
          'The dog eats the bread, the minister says.'),
    reason_ir('El perro come el pan, abre la puerta.', spanish, IR15),
    yes_no(IR15 = [ir(join(comma, _, s(none, null(third, singular), g(opens, _, _, _), [obj(np(_, _, _, w(door, _), _))])), _)], C15),
    check('a GUARD: ... and a clause whose phrase after the verb is no person keeps its object, as since 1.6.15', C15, yes),
    %% an adjective in the lesson's order
    nf_tr('El perro come la sopa común.', spanish, italian, L16),
    check('an adjective is taken in the lesson''s order, where `corrente'', a feminine NOUN, came before the genderless `comune''', L16,
          'Il cane mangia la minestra comune.'),
    %% a title before a name, with its article
    nf_tr('El perro ve al señor Pérez.', spanish, italian, L17),
    check('a noun with a name after it takes the short form the lesson states, where it was `il signore Pérez''', L17,
          'Il cane vede il signor Pérez.'),
    %% `ni' between two adjectives
    nf_tr('La casa no es grande ni roja.', spanish, italian, L18),
    check('`ni'' between two adjectives crosses as nor, where it crossed as neither and Italian wrote the adverb `neanche''', L18,
          'La casa non è grande né rossa.'),
    %% no command after `si'
    nf_tr('El perro duerme si come el pan.', spanish, italian, L19),
    check('after `si'' the verb is no command, which refused the sentence -- `come'' is its own imperative', L19,
          'Il cane dorme se mangia il pane.'),
    %% GUARDS the controls wrote, each on a first cut of this version
    reason_ir('Juan, Pedro, Casa, María y Ana en la casa.', spanish, IR20),
    %% (ONE list of five names since 1.8.12, where the first comma was the
    %% gap's and the list began at Pedro -- a comma after a name is the list's
    %% when names go on to a coordinator)
    yes_no(IR20 = [ir(gap([], [obj(co(w(',', lcomma), name(juan), co(w(',', lcomma), name(pedro), co(w(',', lcomma), name(casa), _))))|_]), _)], C20),
    check('a GUARD: a capitalised noun between commas in a list of names is the next name, where the first cut took `, Casa,'' for what Pedro is and broke the list', C20, yes),
    nf_tr('Juan, Pedro, Casa, María y Ana duermen.', spanish, italian, L21),
    check('a GUARD: ... and a comma before it parts it from the name before, where a name that goes on through a noun ran over the commas into `Pedro Casa María''', L21,
          'Juan, Pedro, Casa, María e Ana dormono.'),
    nf_tr('Il cane mangia il pane, si dice dopo María.', italian, spanish, L22),
    check('a GUARD: a clause at the end whose name follows a preposition reports nothing, where the first cut had María say it -- `se dice después María''', L22,
          'El perro come el pan, se dice tras María.'),
    %% what the data column found: a line of this version's lesson made
    %% Fiat's `sono previste' a passive, and after `nel quale' its subject
    %% was an object -- the participle agreed with nobody
    nf_tr('Il cane vede la casa nella quale sono viste le porte del gatto.', italian, spanish, L23),
    check('a relative word that a preposition governs opens a whole statement, and a passive''s subject after it is its subject there too, where the doors were an object and the participle agreed with nobody -- `son vistos las puertas''', L23,
          'El perro ve la casa en la que son vistas las puertas del gato.').

%% ---- the pacifist letter, Italian into Spanish (1.8.12) ----------------------------------

%% the Italian UD VIT letter VIT-9775..9780: a list of names, a name with
%% its relative clause, a heart that tightens, the writer's own comment
%% between two commas, an exclamation and a signature with its province
newspaper_pacifist :-
    section('an Italian letter into Spanish: a list of names, a name with its relative clause, a reflexive verb with its subject after it, the writer''s comment, an exclamation, a signature'),
    newspaper_pacifist_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_pacifist_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_pacifist_checks_1, newspaper_pacifist_checks_2,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_pacifist_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
"l''" is the elision of "lo". "l''" is the elision of "la".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dell''" is the elision of "della". "dell''" is the elision of "dello". "dello" is the contraction of "di lo".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The noun "cane" means "dog". The noun "gatto" means "cat". The noun "topo" means "mouse". The noun "coniglio" means "rabbit".
The noun "pane" means "bread". The noun "vino" means "wine". The noun "casa" means "house".
The noun "cuore" means "heart". The noun "libro" means "book". The noun "amico" means "friend".
The noun "tristezza" means "sadness". The noun "dio" means "god". The noun "marina" means "navy".
The feminine noun "bastiglia" means "bastille". The masculine noun "termidoro" means "thermidor".
The adjective "grande" means "big".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "vede" means "sees". The verb "parla" means "speaks". The verb "dice" means "says".
The verb "legge" means "reads". "leggendo" is the gerund of "legge".
The verb "sottolinea" means "underlines". "sottolineo" is the first person of "sottolinea".
The verb "osa" means "dares". "osato" is the participle of "osa".
The verb "stringe" means "tightens". "stretto" is the participle of "stringe". "stringe" is reflexive.
The verb "è" means "is". "sono" is the plural of "è".
"che" is a relative. The conjunction "che" means "that". The word "che" means "what".
The conjunction "e" means "and".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "con" means "with".
The auxiliary "ha" means "has". "è" is the auxiliary of the reflexive.
The pronoun "mi" means "me". The possessive "mio" means "my".
The adverb "ieri" means "yesterday". The adverb "proprio" means "precisely".
The reflexive pronoun "si" means "itself".').
newspaper_pacifist_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
"del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "ratón" means "mouse". The noun "conejo" means "rabbit".
The noun "pan" means "bread". The noun "vino" means "wine". The noun "casa" means "house".
The noun "corazón" means "heart". The noun "libro" means "book". The noun "amigo" means "friend". "amigo" is a person.
The noun "tristeza" means "sadness". The noun "dios" means "god". The noun "armada" means "navy".
The feminine noun "bastilla" means "bastille". The masculine noun "termidor" means "thermidor".
The adjective "grande" means "big".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "ve" means "sees". The verb "habla" means "speaks". The verb "dice" means "says".
The verb "lee" means "reads". "leyendo" is the gerund of "lee".
The verb "subraya" means "underlines". "subrayo" is the first person of "subraya".
The verb "osa" means "dares". "osado" is the participle of "osa".
The verb "aprieta" means "tightens". "apretado" is the participle of "aprieta".
The verb "es" means "is". "son" is the plural of "es".
"que" is a relative. The conjunction "que" means "that". The word "qué" means "what".
The conjunction "y" means "and".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with".
The auxiliary "ha" means "has".
The pronoun "me" means "me". The possessive "mi" means "my".
The adverb "ayer" means "yesterday". The adverb "precisamente" means "precisely".
The reflexive pronoun "se" means "itself".
The mark "¡" begins the exclamation.').

newspaper_pacifist_checks_1 :-
    %% a list of names
    nf_tr('Il cane vede Maria, Carla e Luisa.', italian, spanish, L1),
    check('a list of names is one object, where the first was an object of its own and the word before a person stood twice -- `ve a Maria, a Carla y Luisa''', L1,
          'El perro ve a Maria, Carla y Luisa.'),
    nf_tr('Il cane parla con Maria, Carla, Luisa e Ana.', italian, spanish, L2),
    check('... and after a preposition, where the three after the first comma were objects of `parla'' -- `con Maria, a Carla, a Luisa y Ana''', L2,
          'El perro habla con Maria, Carla, Luisa y Ana.'),
    reason_ir('Il cane, il gatto, il topo e il coniglio mangiano il pane.', italian, IR3),
    yes_no(IR3 = [ir(s(none, co(w(',', lcomma), _, co(w(',', lcomma), _, co(w(and, _), _, _))), _, _), _)], C3),
    check('four phrases with commas between them are ONE subject, where the first two were a verbless piece and the mouse and the rabbit ate the bread', C3, yes),
    %% a name with its relative clause
    nf_tr('Maria che dorme mangia il pane.', italian, spanish, L4),
    check('a name with its relative clause is a subject, which refused the sentence', L4,
          'Maria que duerme come el pan.'),
    %% an adverb after a front's comma, before the subject
    nf_tr('Il cane dice che, ieri, proprio il gatto dorme.', italian, spanish, L5),
    check('an adverb after a front''s comma and before the subject stays there, where `ieri, proprio'' was one front and the writer put a comma after it', L5,
          'El perro dice que, ayer, precisamente el gato duerme.'),
    nf_tr('Proprio la casa è grande.', italian, spanish, L6),
    check('a GUARD: ... and one at the head of a whole piece keeps 1.6.8''s rule and goes after the verb', L6,
          'La casa es grande precisamente.'),
    %% a reflexive verb with a dative before it
    reason_ir('Mi si è stretto il cuore.', italian, IR7),
    yes_no(IR7 = [ir(s(none, np(_, _, _, w(heart, _), _), g(reflexive(tightens), present, perfect, no), [opron(_), subj_here]), _)], C7),
    check('a verb the lesson calls reflexive, with its pronoun before it, has its subject after it: my heart tightened, where somebody nobody named tightened it', C7, yes),
    reason_ir('Mi si è stretto il cuore leggendo il libro.', italian, IR8),
    yes_no(IR8 = [ir(s(none, np(_, _, _, w(heart, _), _), _, [opron(_), subj_here, ger(_, _)]), _)], C8),
    check('... and a gerund ends the phrase before it, where `il cuore leggendo'' was no phrase and the heart the object again', C8, yes),
    nf_tr('Mi si è stretto il cuore leggendo il libro.', italian, spanish, L9),
    check('a GUARD: ... which Spanish writes as it did, with the heart its subject after the verb', L9,
          'Se me ha apretado el corazón leyendo el libro.').

newspaper_pacifist_checks_2 :-
    %% the writer's comment between two commas
    nf_tr('Il cane ha osato, sottolineo "osato", mangiare il pane.', italian, spanish, L10),
    check('the writer''s own comment between two commas stands where it stood, with the marks on its word, where it divided the sentence and `dire'' was what I stress', L10,
          'El perro ha osado, subrayo "osado", comer el pan.'),
    nf_tr('Il cane ha osato, sottolineo "osato", mangiare il pane.', italian, english, L11),
    check('... and English', L11,
          'The dog has dared, I underline "dared", to eat the bread.'),
    reason_ir('Il cane dorme, sottolineo il libro del gatto, e il gatto dorme.', italian, IR17),
    format(atom(A17), '~q', [IR17]),
    yes_no(( IR17 = [_], \+ sub_atom(A17, _, _, _, 'comment(') ), C17),
    check('a GUARD: ... and only a short one: a first person clause of more than three words is the sentence''s own, which the first cut took for a comment and refused the Bosnian letter''s third sentence', C17, yes),
    %% an exclamation
    nf_tr('Mio dio, che tristezza!', italian, spanish, L12),
    check('an exclamation''s `what'' and its phrase, and the mark Spanish opens it with, which refused the line', L12,
          '¡Mi dios, qué tristeza!'),
    %% a signature with its province
    nf_tr('Maria Rossi Roma (RM) Bastiglia e termidoro.', italian, spanish, L13),
    check('a signature whose town ends on its province in brackets, and the next letter''s title, which refused the line', L13,
          'Maria Rossi Roma (RM) Bastilla y termidor.'),
    nf_tr('Pane e vino.', italian, spanish, L14),
    check('a GUARD: ... and bare nouns joined, standing alone, stay refused', L14, refused),
    %% an elided contraction before a quotation mark
    nf_tr('Il cane legge il libro dell''"amico".', italian, spanish, L15),
    check('an elided contraction before a quotation mark keeps its apostrophe, which refused the sentence for `dell''', L15,
          'El perro lee el libro del "amigo".'),
    %% a name with a particle in capitals
    nf_tr('Il cane legge il libro di Marina Ripa Di Meana.', italian, spanish, L16),
    check('a name with a particle in capitals is one name after a preposition, though its first word is a noun of the lesson''s', L16,
          'El perro lee el libro de Marina Ripa Di Meana.').

newspaper_mobile :-
    section('a Spanish column into Italian: the word for more before a participle, an aside with it, what a copula has last is its subject, a relative clause that ends before another, a clause of the verb''s after a phrase, a participle said of the object'),
    newspaper_mobile_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_mobile_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_mobile_checks_1, newspaper_mobile_checks_2, newspaper_mobile_checks_3,
    reason_unlearn(spanish), reason_unlearn(italian).

newspaper_mobile_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The word "el" replaces the noun. The word "lo" replaces the noun.
The word "más" begins the comparative. The adverb "más" means "more". The preposition "más" means "plus".
The noun "perro" means "dog". The noun "gato" means "cat". The noun "hombre" means "man". "hombre" is a person.
The noun "pan" means "bread". The noun "alegría" means "joy". The noun "precio" means "price".
The noun "libertad" means "freedom". "libertad" is feminine. The noun "invento" means "invention".
The noun "teléfono" means "telephone". The noun "sorpresa" means "surprise". The noun "caso" means "case".
The noun "país" means "country". "países" is the plural of "país".
The masculine noun "punto de vista" means "point of view". "puntos de vista" is the plural of "punto de vista".
The adjective "grande" means "big". "grandes" is the plural of "grande".
The masculine adjective "alto" means "tall". The feminine adjective "alta" means "tall".
The masculine adjective "vacío" means "empty". The feminine adjective "vacía" means "empty".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "ve" means "sees".
The verb "busca" means "seeks". "buscado" is the participle of "busca".
The verb "limita" means "limits". "limitado" is the participle of "limita". "limitada" is the participle of "limita". "limitada" is feminine.
The verb "contiene" means "contains". "contenido" is the participle of "contiene". "contenida" is the participle of "contiene". "contenida" is feminine.
The verb "moderniza" means "modernises". "modernizado" is the participle of "moderniza". "modernizados" is the participle of "moderniza". "modernizados" is the plural of "modernizado".
The verb "hace" means "makes". "hacen" is the plural of "hace".
The verb "desea" means "wishes". "deseado" is the participle of "desea". "deseados" is the participle of "desea". "deseados" is the plural of "deseado".
The verb "ofrece" means "offers". "ofrecen" is the plural of "ofrece".
The verb "descubre" means "discovers". "descubren" is the plural of "descubre".
The verb "casa" means "marries". "case" is the subjunctive of "casa". "casen" is the plural of "case".
The verb "es" means "is". "son" is the plural of "es". "era" is the past of "es". The noun "era" means "age".
The intransitive verb "pasa" means "happens". "pase" is the subjunctive of "pasa". "coma" is the subjunctive of "come".
The pronoun "algo" means "something". The adjective "difícil" means "difficult".
The word "cuando" means "when". The conjunction "a medida que" means "as".
"estaba" is the past of "está".
The auxiliary "está" means "is". The auxiliary "está" marks the state. The verb "está" means "stays".
The modal "debe" means "must". "debería" is the conditional of "debe".
"que" is a relative. The conjunction "que" means "that". The word "que" means "than".
The conjunction "y" means "and".
The preposition "a" means "to". The preposition "de" means "of". The preposition "con" means "with".
The preposition "desde" means "from".
The pronoun "lo" means "it". The pronoun "los" means "them". The pronoun "ella" means "she". The pronoun "alguien" means "somebody".').
newspaper_mobile_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
The article "lo" comes before a vowel.
"l''" is the elision of "lo". "l''" is the elision of "la". "un''" is the elision of "una".
"del" is the contraction of "di il". "dai" is the contraction of "da i".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The word "quello" replaces the noun. The pronoun "quello" means "that". The pronoun "quello" does not precede the verb.
The word "più" begins the comparative. The adverb "più" means "more".
The noun "cane" means "dog". The noun "gatto" means "cat". The noun "uomo" means "man".
The noun "pane" means "bread". The noun "allegria" means "joy". The noun "prezzo" means "price".
The noun "libertà" means "freedom". "libertà" is feminine. The noun "invenzione" means "invention". "invenzione" is feminine. "invenzioni" is the plural of "invenzione".
The noun "telefono" means "telephone". The noun "sorpresa" means "surprise". The noun "caso" means "case".
The noun "paese" means "country". "paesi" is the plural of "paese".
The masculine noun "punto di vista" means "point of view". "punti di vista" is the plural of "punto di vista". "punto di vista" is not feminine.
The adjective "grande" means "big". "grandi" is the plural of "grande".
The masculine adjective "alto" means "tall". The feminine adjective "alta" means "tall".
The feminine adjective "vuota" means "empty". The masculine adjective "vuoto" means "empty".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "vede" means "sees".
The verb "cerca" means "seeks". "cercato" is the participle of "cerca".
The verb "limita" means "limits". "limitato" is the participle of "limita". "limitata" is the participle of "limita". "limitata" is feminine.
The verb "contiene" means "contains". "contenuto" is the participle of "contiene". "contenuta" is the participle of "contiene". "contenuta" is feminine.
The verb "modernizza" means "modernises". "modernizzato" is the participle of "modernizza". "modernizzati" is the participle of "modernizza". "modernizzati" is the plural of "modernizzato".
The verb "fa" means "makes". "fanno" is the plural of "fa".
The verb "desidera" means "wishes". "desiderato" is the participle of "desidera". "desiderati" is the participle of "desidera". "desiderati" is the plural of "desiderato".
The verb "offre" means "offers". "offrono" is the plural of "offre".
The verb "scopre" means "discovers". "scoprono" is the plural of "scopre".
The verb "è" means "is". "sono" is the plural of "è". "era" is the past of "è".
The intransitive verb "succede" means "happens".
The pronoun "qualcosa" means "something". The adjective "difficile" means "difficult".
The word "quando" means "when". The conjunction "man mano che" means "as".
"che" is a relative. The conjunction "che" means "that".
The conjunction "e" means "and".
The preposition "a" means "to". The preposition "di" means "of". The preposition "con" means "with".
The preposition "da" means "from".
The pronoun "lo" means "it". The pronoun "li" means "them". The pronoun "lei" means "she". The pronoun "qualcuno" means "somebody".').

newspaper_mobile_checks_1 :-
    %% the word for `more' between a noun and its participle
    nf_tr('El perro come con una alegría más contenida.', spanish, italian, M1),
    check('the word for more between a noun and its participle is the participle''s degree, and it agrees with the noun, where it was said of the subject -- `più contenuto''', M1,
          'Il cane mangia con un''allegria più contenuta.'),
    nf_tr('El perro come con una alegría más contenida.', spanish, english, M2),
    check('... and English puts it before the noun with its degree', M2,
          'The dog eats with a more contained joy.'),
    nf_tr('El hombre más buscado duerme.', spanish, italian, M3),
    check('a GUARD: ... a superlative after the definite article, which the phrase''s own degree read before', M3,
          'L''uomo più cercato dorme.'),
    %% a participle with its degree after a comma
    nf_tr('El perro come con una alegría más limitada, más contenida.', spanish, italian, M4),
    check('a participle with its degree after a comma is the same noun''s, where it was the subject''s', M4,
          'Il cane mangia con un''allegria più limitata, più contenuta.'),
    nf_tr('Los países, más modernizados, duermen.', spanish, italian, M5),
    check('... and between two commas after a subject it stays there, a comparative, where the commas went and it was the superlative', M5,
          'I paesi, più modernizzati, dormono.'),
    nf_tr('Los países, más modernizados desde los puntos de vista, duermen.', spanish, italian, M5b),
    check('... with its adjuncts, where the commas went', M5b,
          'I paesi, più modernizzati dai punti di vista, dormono.'),
    %% what a copula with nobody before it has last is its subject
    nf_tr('Es el precio lo que los hace deseados.', spanish, italian, M6),
    check('what a copula with nobody named has last is its subject, a phrase whose noun a relative clause stands for: the order kept, and the participle the object''s', M6,
          'È il prezzo quello che li fa desiderati.'),
    nf_tr('Es el precio lo que los hace deseados.', spanish, english, M7),
    check('... and English puts the subject first, which refused the sentence', M7,
          'The one that makes them wished is the price.'),
    nf_tr('El precio los hace deseados.', spanish, italian, M8),
    check('a participle after an object pronoun is said of the object, where it agreed with the subject', M8,
          'Il prezzo li fa desiderati.').

newspaper_mobile_checks_3 :-
    %% a time clause whose main clause follows with no comma
    nf_tr('Cuando el perro come descubren el pan.', spanish, italian, M20),
    check('a time clause at the head ends where its main clause''s verb begins, with no comma between, which refused the sentence', M20,
          'Quando il cane mangia scoprono il pane.'),
    %% a copula after a comma that is a noun as well
    nf_tr('El teléfono estaba vacío, era grande.', spanish, italian, M21),
    check('a form of the copula after a comma that is also a noun opens a clause of its own, where it was an age', M21,
          'Il telefono era vuoto, era grande.'),
    %% as
    nf_tr('A medida que el perro come, el gato duerme.', spanish, italian, M22),
    check('`as'' joins two clauses, which refused the sentence', M22,
          'Man mano che il cane mangia, il gatto dorme.'),
    %% an adjective and the clause said of it
    ( reason_ir('Es difícil que el perro coma.', spanish, IR23) -> true ; IR23 = none ),
    yes_no(IR23 = [ir(s(_, _, _, [adj([w(difficult, _)]), that(s(_, _, g(eats, _, _, _), _))]), _)], C23),
    check('an adjective and the clause said of it, where the adjective was read as a noun and the clause as its relative clause', C23, yes),
    nf_tr('Es difícil que el perro coma.', spanish, italian, M23),
    check('a GUARD: ... and Italian writes the same words from either reading, which is why only the IR shows it', M23,
          'È difficile che il cane mangia.'),
    nf_tr('Es más difícil que pase algo.', spanish, italian, M24),
    check('... and a subjunctive after the word for than opens that clause, where the comparison took it for a noun', M24,
          'È più difficile che succede qualcosa.').

newspaper_mobile_checks_2 :-
    %% a relative clause that ends before a second one
    %% (the clause is the object's since 1.8.15: `la libertad' is singular and
    %% `ofrecen' plural, so the freedom is what the inventions offer, their
    %% subject after the verb -- where this pinned the inventions as the
    %% object of a freedom that offered them)
    ( reason_ir('Es la libertad que ofrecen los inventos lo que los hace deseados.', spanish, IR9) -> true ; IR9 = none ),
    yes_no(IR9 = [ir(s(_, ell(_, _, _, rel(_, _)), _, [obj(rc(_, object, s(_, np(_, _, _, w(invention, _), plural), _, [subj_here]))), subj_here]), _)], C9),
    check('a relative clause ends where a phrase whose noun a relative clause stands for begins, and that phrase is the copula''s subject, where the clause had it for a second object', C9, yes),
    nf_tr('Es la libertad que ofrecen los inventos lo que los hace deseados.', spanish, italian, M9),
    check('... written in the order it stood', M9,
          'È la libertà che offrono le invenzioni quello che li fa desiderati.'),
    %% a clause of the verb's after a phrase
    ( reason_ir('Descubren con sorpresa que el teléfono está vacío.', spanish, IR10) -> true ; IR10 = none ),
    yes_no(IR10 = [ir(s(_, _, g(discovers, _, _, _), [pp(_, _), that(_)]), _)], C10),
    check('a clause of the verb''s after a phrase is the verb''s, where it was the surprise''s relative clause -- a copula with its adjective has no gap for `que'' to fill', C10, yes),
    ( reason_ir('El perro ve el pan que el gato come.', spanish, IR11) -> true ; IR11 = none ),
    yes_no(IR11 = [ir(s(_, _, _, [obj(rc(_, object, _))]), _)], C11),
    check('a GUARD: a relative clause whose verb has a gap stays one', C11, yes),
    %% a subject with no noun
    nf_tr('Ella es alta.', spanish, italian, M12),
    check('a predicate adjective agrees with a pronoun subject''s gender, where it came out `alto''', M12, 'Lei è alta.'),
    nf_tr('El teléfono está vacío, está vacío.', spanish, italian, M13),
    check('... and with the masculine where nobody is named, where the lesson''s first word was taken and it came out `vuota''', M13,
          'Il telefono è vuoto, è vuoto.'),
    %% English
    nf_tr('Alguien debería comer el pan.', spanish, english, M14),
    check('English''s conditional of must is should, which refused the sentence', M14, 'Somebody should eat the bread.'),
    nf_tr('Los puntos de vista son grandes.', spanish, english, M15),
    check('English''s plural of a noun with of in it is on the word before of, where it was `point of views''', M15,
          'The points of view are big.'),
    nf_tr('El gato come más que el perro.', spanish, english, M16),
    check('English writes more before than, where it went last', M16, 'The cat eats more than the dog.'),
    nf_tr('Los casos son grandes.', spanish, english, M17),
    check('English''s plural of a word that is a FORM of the lesson''s is English''s own, where `"casen" is the plural of "case"'' made it `casen''', M17,
          'The cases are big.').

%% ---- the Bastille letter, Italian into Spanish (1.8.14) ----------------------------------

%% the Italian UD VIT letter VIT-9781..9791: `Bastiglia e termidoro' -- a
%% clause of `che' in front, a copula with its subject after what it says, a
%% comment that ends a clause, a connector that means `so that' before a
%% subjunctive, nothing to object, a bracket inside a phrase, a word that
%% begins a relative, a command with its pronoun joined and a signature
newspaper_bastille :-
    section('an Italian letter into Spanish: a che clause in front, nothing to object, perché before a subjunctive, a comment at the end of a clause, a bracket inside a phrase, chi, a command with its pronoun joined, a signature'),
    newspaper_bastille_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_bastille_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_bastille_checks_1, newspaper_bastille_checks_2, newspaper_bastille_checks_3,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_bastille_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"l''" is the elision of "lo". "l''" is the elision of "la".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dell''" is the elision of "della". "dei" is the contraction of "di i".
"sulla" is the contraction of "su la". "nella" is the contraction of "in la". "nel" is the contraction of "in il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The word "per" begins the purpose. The word "da" begins the purpose. The word "di" begins the infinitive.
The noun "cane" means "dog". The noun "gatto" means "cat". The noun "topo" means "mouse". The noun "lupo" means "wolf".
"cani" is the plural of "cane". "gatti" is the plural of "gatto". "topi" is the plural of "topo". "lupi" is the plural of "lupo".
The feminine noun "volpe" means "fox". "volpi" is the plural of "volpe".
The noun "pane" means "bread". The noun "vino" means "wine". The noun "casa" means "house". "case" is the plural of "casa". The noun "libro" means "book".
The noun "fatto" means "fact". "fatti" is the plural of "fatto". The noun "motivo" means "reason". The noun "passato" means "past". The noun "progetto" means "project".
The feminine noun "necessità" means "need". "necessità" is the plural of "necessità".
The feminine noun "affermazione" means "affirmation".
The masculine noun "dott" means "doctor". "dott" is a title.
The masculine noun "magistrato" means "magistrate". "magistrati" is the plural of "magistrato". The feminine noun "mano" means "hand". "mani" is the plural of "mano".
The adjective "grande" means "big". "grandi" is the plural of "grande".
The masculine adjective "piccolo" means "small". The feminine adjective "piccola" means "small". "piccole" is the plural of "piccola".
The masculine adjective "stanco" means "tired". The adjective "semplice" means "simple".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangi" is the subjunctive of "mangia". "mangiate" is the imperative of "mangiano".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dorma" is the subjunctive of "dorme".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "dice" means "says". The verb "parla" means "speaks".
The verb "vigila" means "watches". "vigilare" is the infinitive of "vigila".
The verb "eccepisce" means "objects". "eccepire" is the infinitive of "eccepisce".
The verb "dimostra" means "demonstrates". "dimostrano" is the plural of "dimostra".
The verb "accade" means "happens". "accadde" is the past of "accade".
The verb "legge" means "reads". "leggi" is the second person of "legge".
The verb "corregge" means "corrects". "correggono" is the plural of "corregge". "correggete" is the imperative of "correggono".
The verb "sbaglia" means "errs". "sbaglio" is the first person of "sbaglia".
The verb "imita" means "imitates". The verb "redarguisce" means "rebukes".
The verb "stabilisce" means "establishes". "stabilire" is the infinitive of "stabilisce". "stabilisce" takes the question.
The verb "cerca" means "seeks". "cercato" is the participle of "cerca". The verb "consente" means "allows".
The auxiliary "ha" means "has". "è" is the auxiliary of the reflexive.
The verb "tratta" means "deals". "tratti" is the subjunctive of "tratta". "tratti" is the second person of "tratta".
The verb "pare" means "seems". The verb "risulta" means "results". "risulta" is intransitive.
"risulta" takes the clause. "pare" takes the clause.
The adjective "vigile" means "vigilant". "vigili" is the plural of "vigile". "vigili" is the subjunctive of "vigila".
The conjunction "nonostante" means "although".
The verb "vuole" means "wants". "voglia" is the subjunctive of "vuole". The verb "mura" means "walls". "murare" is the infinitive of "mura".
The verb "scappa" means "escapes". "scappando" is the gerund of "scappa".
The verb "pulisce" means "cleans". "pulite" is the participle of "pulisce". "pulite" is feminine. "pulite" is the plural of "pulita". "pulita" is the participle of "pulisce".
The verb "è" means "is". "sono" is the plural of "è". "sono" is the first person of "è". "sia" is the subjunctive of "è".
The intransitive verb "ne fa testo" means "testifies to it". "ne fanno testo" is the plural of "ne fa testo".
The intransitive verb "dorme" means "sleeps".
"che" is a relative. The conjunction "che" means "that". The word "chi" means "who". The word "chi" begins the relative.
"cui" is a relative. The word "cui" follows the preposition.
The pronoun "molti" means "many". The pronoun "molti" does not precede the verb.
The masculine determiner "molto" means "many". "molti" is the plural of "molto".
The relative "il quale" means "who".
The conjunction "e" means "and". The conjunction "ma" means "but". The conjunction "o" means "or".
The conjunction "perché" means "because". The conjunction "perché" means "so that". The conjunction "se" means "if".
The conjunction "prima ancora che" means "even before".
The preposition "come" means "as".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "su" means "on". The preposition "per" means "for". The preposition "da" means "from". The preposition "anziché" means "instead of".
The pronoun "lo" means "him". The pronoun "li" means "them". The pronoun "mi" means "me".
The pronoun "egli" means "he". The pronoun "egli" does not precede the verb.
The pronoun "nulla" means "nothing". The pronoun "nulla" does not precede the verb.
The possessive "nostro" means "our".
The adverb "qui" means "here". The adverb "peraltro" means "moreover". The adverb "ieri" means "yesterday". The adverb "qui da noi" means "here among us".
The impersonal pronoun "si" means "one". The reflexive pronoun "si" means "itself".').
newspaper_bastille_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The word "para" begins the purpose. The word "el" replaces the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "ratón" means "mouse". "ratones" is the plural of "ratón". The noun "lobo" means "wolf". The noun "zorro" means "fox".
The noun "pan" means "bread". The noun "vino" means "wine". The noun "casa" means "house". The noun "libro" means "book".
The noun "hecho" means "fact". The noun "motivo" means "reason". The noun "pasado" means "past". The noun "proyecto" means "project".
The feminine noun "necesidad" means "need". "necesidades" is the plural of "necesidad".
The feminine noun "afirmación" means "affirmation".
The masculine noun "médico" means "doctor".
The masculine noun "magistrado" means "magistrate". "magistrado" is a person. The feminine noun "mano" means "hand".
The adjective "grande" means "big". "grandes" is the plural of "grande".
The masculine adjective "pequeño" means "small". The feminine adjective "pequeña" means "small". "pequeñas" is the plural of "pequeña".
The masculine adjective "cansado" means "tired". The adjective "simple" means "simple".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "coma" is the subjunctive of "come". "comed" is the imperative of "comen".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "duerma" is the subjunctive of "duerme".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "dice" means "says". The verb "habla" means "speaks".
The verb "vigila" means "watches". "vigilar" is the infinitive of "vigila".
The verb "objeta" means "objects". "objetar" is the infinitive of "objeta".
The verb "demuestra" means "demonstrates". "demuestran" is the plural of "demuestra".
The verb "pasa" means "happens". "pasó" is the past of "pasa".
The verb "lee" means "reads". "lees" is the second person of "lee".
The verb "corrige" means "corrects". "corrigen" is the plural of "corrige". "corregid" is the imperative of "corrigen".
The verb "equivoca" means "errs". "equivoco" is the first person of "equivoca".
The verb "imita" means "imitates". The verb "reprende" means "rebukes".
The verb "establece" means "establishes". "establecer" is the infinitive of "establece".
The verb "busca" means "seeks". "buscado" is the participle of "busca". The verb "permite" means "allows". "permite" takes "a" before the person.
The auxiliary "ha" means "has".
The verb "trata" means "deals".
The verb "parece" means "seems". The verb "resulta" means "results".
The adjective "vigilante" means "vigilant". "vigilantes" is the plural of "vigilante".
The conjunction "aunque" means "although". The word "quién" means "who".
The noun "resultado" means "result". The verb "une" means "unites". "una" is the subjunctive of "une".
The verb "quiere" means "wants". The verb "mura" means "walls". "murar" is the infinitive of "mura".
The verb "huye" means "escapes". "huyendo" is the gerund of "huye".
The verb "limpia" means "cleans". "limpiadas" is the participle of "limpia". "limpiadas" is feminine.
The verb "es" means "is". "son" is the plural of "es".
The intransitive verb "da fe de ello" means "testifies to it". "dan fe de ello" is the plural of "da fe de ello".
"que" is a relative. The conjunction "que" means "that". The word "de" begins the clause.
The pronoun "muchos" means "many". The pronoun "muchos" does not precede the verb.
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "o" means "or".
The conjunction "porque" means "because". The conjunction "para que" means "so that". The conjunction "si" means "if".
The conjunction "incluso antes de que" means "even before".
The preposition "como" means "as".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "sobre" means "on". The preposition "para" means "for". The preposition "desde" means "from". The preposition "en vez de" means "instead of".
The pronoun "lo" means "him". The pronoun "los" means "them". The pronoun "me" means "me".
The pronoun "él" means "he". The pronoun "él" means "him". The pronoun "él" does not precede the verb.
The pronoun "ella" means "she". The pronoun "ella" means "her". The pronoun "ella" does not precede the verb.
The verb "divierte" means "amuses". "divirtió" is the past of "divierte". The preposition "con" means "with".
The pronoun "nada" means "nothing". The pronoun "nada" does not precede the verb.
The possessive "nuestro" means "our".
The adverb "aquí" means "here". The adverb "además" means "moreover". The adverb "ayer" means "yesterday". The adverb "aquí entre nosotros" means "here among us".
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".').

newspaper_bastille_checks_1 :-
    %% nothing to object
    nf_tr('Nulla da eccepire.', italian, spanish, B1),
    check('a pronoun that stands alone and the infinitive it is for, with no verb, which refused the line', B1, 'Nada para objetar.'),
    nf_tr('Nulla da eccepire sulla necessità di vigilare.', italian, spanish, B2),
    check('... and with no verb read a phrase''s `di'' and its infinitive are the phrase''s, the need to watch', B2,
          'Nada para objetar sobre la necesidad de vigilar.'),
    nf_tr('Nulla da eccepire perché il gatto dorme.', italian, spanish, B3),
    check('... and as the left side of a division, which refused the sentence', B3,
          'Nada para objetar porque el gato duerme.'),
    %% a connector before a subjunctive
    nf_tr('Il cane vigila perché il gatto non mangi il pane.', italian, spanish, B4),
    check('`perché'' before a subjunctive is so that, where it was because', B4,
          'El perro vigila para que el gato no come el pan.'),
    nf_tr('Il cane vigila perché il gatto non mangia il pane.', italian, spanish, B5),
    check('a GUARD: ... and before an indicative still because, which the first cut refused -- its cut came before the subjunctive test', B5,
          'El perro vigila porque el gato no come el pan.'),
    %% a comment at the end of a clause
    nf_tr('Il cane dorme, come, peraltro, accadde in passato.', italian, spanish, B6),
    check('a comment of `come'' at the end of a clause, with its insertion and its commas, where `come'' was how and the commas went', B6,
          'El perro duerme, como, además, pasó en pasado.'),
    nf_tr('Il cane dorme, come accadde in passato, ma il gatto mangia.', italian, spanish, B7),
    check('... and one before a connector ends the clause it is in, where it was written after the cat''s', B7,
          'El perro duerme, como pasó en pasado, pero el gato come.'),
    %% a bracket inside a phrase, and a list inside a bracket
    nf_tr('Il cane vede i gatti (leggi topi) grandi.', italian, spanish, B8),
    check('a bracket between a noun and its adjective is the phrase''s, written after it, which refused the sentence', B8,
          'El perro ve los gatos grandes (lees ratones).'),
    nf_tr('Il cane dorme (ma il gatto consente a lupi, volpi e topi di mangiare).', italian, spanish, B9),
    check('a clause in a bracket reads its commas as a sentence does, where the foxes were an adjective of the wolves', B9,
          'El perro duerme (pero el gato permite a lobos, zorros y ratones comer).'),
    %% two clauses after a preposition and its relative
    nf_tr('La casa in cui si è cercato e si cerca di mangiare il pane è grande.', italian, spanish, B10),
    check('a clause after a preposition and its relative may be two joined, which refused the sentence', B10,
          'La casa en la que se ha buscado y se busca comer el pan es grande.'),
    %% a clause with its `che'' left out, and an adjunct between commas inside one
    nf_tr('La casa non mi risulta sia grande.', italian, spanish, B11),
    check('a subjunctive with its `che'' left out is the verb''s clause, which refused the sentence', B11,
          'La casa no me resulta que es grande.'),
    nf_tr('Il cane dorme per il motivo che la casa, qui da noi, non mi risulta sia grande.', italian, spanish, B12),
    check('... and an adjunct between commas inside a noun''s clause, and `risulta'' leaves no gap for a relative', B12,
          'El perro duerme para el motivo de que la casa, aquí entre nosotros, no me resulta que es grande.').

newspaper_bastille_checks_2 :-
    %% an adjective between commas after a pronoun
    nf_tr('Il cane vede il libro che egli, stanco, legge.', italian, spanish, B13),
    check('an adjective between commas after a pronoun is said of it, inside a relative clause, which refused the sentence', B13,
          'El perro ve el libro que él, cansado, lee.'),
    %% a relative clause standing alone after a coordinator
    nf_tr('Il cane è grande: ma che mangia il pane.', italian, spanish, B14),
    check('a relative clause standing alone after a coordinator, which refused the sentence', B14,
          'El perro es grande: pero que come el pan.'),
    %% a clause of `che' in front
    nf_tr('Che il cane dorma sono molti i fatti che lo dimostrano.', italian, spanish, B15),
    check('a clause of `che'' in front of the sentence, and a copula whose subject comes after what it says, which refused the sentence', B15,
          'Que el perro duerme son muchos los hechos que lo demuestran.'),
    nf_tr('Che il cane dorma lo dimostrano i fatti.', italian, english, B16),
    check('... and where `lo'' takes it up the phrase after the verb is the subject, where the clause took `lo'' for its own', B16,
          'That the dog sleeps the facts demonstrate him.'),
    nf_tr('Che si tratti di un progetto lo dimostrano i fatti.', italian, spanish, B17),
    check('... and the lesson''s reflexive is a third person, where `tratti'' was you treat', B17,
          'Que se trata de un proyecto lo demuestran los hechos.'),
    %% a subordinate clause at the head with no comma, and a command with its pronoun
    nf_tr('Se il cane dorme il gatto mangia.', italian, spanish, B18),
    check('a subordinate clause at the head ends where the main clause''s verb begins, with no comma, which refused the sentence', B18,
          'Si el perro duerme el gato come.'),
    nf_tr('Se sbaglio correggetemi.', italian, spanish, B19),
    check('... and a command with its pronoun joined after it, which refused the sentence', B19, 'Si equivoco corregidme.'),
    nf_tr('Correggetemi mi.', italian, spanish, B20),
    check('... a capital at the head of one, and the same pronoun written again after it is that pronoun once', B20, 'Corregidme.'),
    nf_tr('Mangiatelo.', italian, spanish, B21),
    check('... and the object pronoun joined the same way', B21, 'Comedlo.'),
    %% even before
    nf_tr('Il cane dorme prima ancora che il gatto mangi.', italian, spanish, B22),
    check('`prima ancora che'' is even before, a connector English writes, which refused the sentence', B22,
          'El perro duerme incluso antes de que el gato come.'),
    %% names
    nf_tr('Dorme il dott Di Pietro.', italian, english, B23),
    check('a title and the name after it are one subject after the verb, and `Di'' begins the name, where it was `Of Pietro'' and the object', B23,
          'The doctor Di Pietro sleeps.'),
    nf_tr('Il cane vede Di Pietro.', italian, spanish, B24),
    check('... a name that begins with `Di'' is a person''s, where it was `De Pietro''', B24, 'El perro ve a Di Pietro.'),
    nf_tr('Il nostro "Robespierre" dorme.', italian, spanish, B25),
    check('a possessive after the article before a name is the determiner, which refused the sentence', B25,
          'Nuestro "Robespierre" duerme.').

newspaper_bastille_checks_3 :-
    %% a word that begins a relative
    nf_tr('Il cane redarguisce chi non lo imita.', italian, spanish, B26),
    check('`chi'' is the one who: a phrase and its relative word both, which refused the sentence', B26,
          'El perro reprende al que no lo imita.'),
    %% `si'' after an object pronoun
    nf_tr('Li si vede.', italian, english, B27),
    check('`si'' after an object pronoun is the impersonal one, where it was a reflexive nobody named and English refused', B27,
          'One sees them.'),
    %% a gerund alone
    nf_tr('Il cane dorme, scappando.', italian, spanish, B28),
    check('a gerund alone at the end of a clause, which refused the sentence', B28, 'El perro duerme, huyendo.'),
    %% an infinitive that takes a question
    nf_tr('Il cane cerca di stabilire se il gatto dorme o se il topo mangia.', italian, english, B29),
    check('an infinitive the lesson says takes a question takes two joined, where they were two conditions', B29,
          'The dog seeks to establish whether the cat sleeps or whether the mouse eats.'),
    %% a relative word with a comma after it
    nf_tr('Dorme il cane il quale, anziché mangiare il pane, vede il gatto.', italian, spanish, B30),
    check('a comma straight after a relative word opens an insertion in front of its clause, where it went after the verb', B30,
          'Duerme el perro que, en vez de comer el pan, ve el gato.'),
    %% a bracket in front of a nested clause
    nf_tr('Il cane stabilisce se (ieri) il gatto dorme.', italian, spanish, B31),
    check('a bracket at the head of a nested clause is its front, which refused the sentence', B31,
          'El perro establece si el gato duerme (ayer).'),
    %% a noun's clause with a copula
    nf_tr('Il cane parla dell''affermazione che la casa è grande.', italian, spanish, B32),
    check('a noun''s own clause may be a copula and what it says, where it was the verb''s', B32,
          'El perro habla de la afirmación de que la casa es grande.'),
    %% two adjectives before one noun and its relative clause
    nf_tr('Il cane vede le piccole e grandi case che dormono.', italian, english, B33),
    check('two adjectives before one noun with a relative clause after it are one phrase, where the small ones were a second thing', B33,
          'The dog sees the small and big houses that sleep.'),
    %% a participle''s own closing mark
    nf_tr('Il cane vede i magistrati di "mani pulite".', italian, spanish, B34),
    check('a phrase that closes on a participle''s own mark puts no second mark on the verb', B34,
          'El perro ve a los magistrados de "manos limpiadas".'),
    %% a signature whose title is a phrase
    nf_tr('Maria Rossi Roma il libro del gatto.', italian, spanish, B35),
    check('a signature and the next letter''s title as a phrase, which refused the line', B35,
          'Maria Rossi Roma el libro del gato.'),
    %% a word of several words at the head
    nf_tr('Ne fa testo il cane.', italian, spanish, B36),
    check('a head word the lesson knows only as part of a word of several loses its capital, which refused the sentence', B36,
          'Da fe de ello el perro.'),
    nf_tr('Ne fanno testo i gatti e i cani che dormono.', italian, spanish, B37),
    check('... and two phrases joined after it, the relative clause on the last, which refused the sentence', B37,
          'Dan fe de ello los gatos y los perros que duermen.'),
    %% what the controls found: a word spelled like a subjunctive, and `chi'
    %% with no verb before it
    nf_tr('I cani sono vigili nonostante il gatto dorma.', italian, spanish, B38),
    check('a GUARD: a subjunctive with its `che'' left out only after a verb the lesson says takes the clause -- `vigili'' is vigilant, and the first cut read it as the clause''s verb, Livata''s sixth', B38,
          'Los perros son vigilantes aunque el gato duerme.'),
    nf_tr('El resultado es una casa y el perro duerme.', spanish, english, B39),
    check('a GUARD: ... and Spanish''s lesson says it of no verb, where `una'' is the subjunctive of `unir'' too, the opera review''s eighth', B39,
          'The result is a house and the dog sleeps.'),
    nf_tr('Il cane dorme (ma chi mangia il pane).', italian, spanish, B40),
    check('a GUARD: `chi'' is the one who only after a verb, and in a bracket with none it asks, the Bosnian letter''s twelfth', B40,
          'El perro duerme (pero quién come el pan).'),
    nf_tr('Él se divirtió con ella.', spanish, english, B41),
    check('a GUARD: `si'' after an object pronoun is the impersonal one, and a subject pronoun is none -- `él'' means him after a preposition, and the first cut read `One amused him with her'', Tatoeba''s', B41,
          'He amused with her.').

%% ---- a Spanish report into Italian: a surname at the head, a verb that
%% takes the clause, a count alone, who said so, an impersonal perfect, a
%% relative clause with its subject after its verb, an absolute participle
%% (1.8.15) ----------------------------------------------------------------

newspaper_basque :-
    section('a Spanish report into Italian: a surname at the head, the person told before a clause, a count alone, who said so, an impersonal perfect, a relative clause with its subject after its verb, a front ending at a comma, an absolute participle'),
    newspaper_basque_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_basque_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_basque_checks_1, newspaper_basque_checks_2,
    reason_unlearn(italian), reason_unlearn(spanish),
    newspaper_basque_lesson2(spanish, ES2), reason_learn(ES2, spanish, _),
    newspaper_basque_lesson2(italian, IT2), reason_learn(IT2, italian, _),
    newspaper_basque_checks_3,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_basque_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person. The word "el" replaces the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". The noun "casa" means "house".
The feminine noun "situación" means "situation". "situaciones" is the plural of "situación".
The masculine adjective "redondo" means "round". The feminine adjective "redonda" means "round".
The masculine adjective "necesario" means "necessary". The feminine adjective "necesaria" means "necessary".
The number "tres" means "three". The number "cinco" means "five".
The verb "come" means "eats". "comen" is the plural of "come". "comido" is the participle of "come". "coma" is the subjunctive of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "duerma" is the subjunctive of "duerme".
The verb "ve" means "sees". "ven" is the plural of "ve". "vio" is the past of "ve". "vieron" is the past of "ven". "saw" is the past of "sees".
The verb "dice" means "says". "dijo" is the past of "dice". "said" is the past of "says".
The verb "declara" means "declares". "declara" takes the clause.
The verb "hace" means "makes". "hará" is the future of "hace".
The verb "llega" means "arrives".
The verb "lava" means "washes". "lavan" is the plural of "lava".
The verb "da" means "gives". "dado" is the participle of "da". "dada" is the participle of "da". "dada" is feminine.
"given" is the participle of "gives". "gave" is the past of "gives".
The auxiliary "ha" means "has".
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative.
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "entre" means "between". The preposition "según" means "according to". The preposition "después de" means "after".
The adverb "ayer" means "yesterday".
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".
The pronoun "la" means "her". The pronoun "lo" means "him".').

newspaper_basque_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i".
"nella" is the contraction of "in la". "nel" is the contraction of "in il". "alle" is the contraction of "a le". "al" is the contraction of "a il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". The noun "casa" means "house". The feminine noun "situazione" means "situation".
The masculine adjective "rotondo" means "round".
The masculine adjective "necessario" means "necessary". The feminine adjective "necessaria" means "necessary".
The number "tre" means "three". The number "cinque" means "five".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiato" is the participle of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "vede" means "sees". "vedono" is the plural of "vede". "vide" is the past of "vede". "videro" is the past of "vedono".
The verb "dice" means "says". "disse" is the past of "dice".
The verb "dichiara" means "declares".
The verb "fa" means "makes". "farà" is the future of "fa".
The verb "arriva" means "arrives".
The verb "lava" means "washes". "lavano" is the plural of "lava".
The verb "dà" means "gives". "dato" is the participle of "dà". "data" is the participle of "dà". "data" is feminine.
The auxiliary "ha" means "has". "è" is the auxiliary of the reflexive.
The verb "è" means "is". "sono" is the plural of "è".
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative.
The masculine pronoun "quello" means "that". "quelli" is the plural of "quello". The pronoun "quello" does not precede the verb.
The feminine pronoun "quella" means "that". "quelle" is the plural of "quella". The pronoun "quella" does not precede the verb.
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "tra" means "between". The preposition "dopo" means "after". The preposition "come" means "as".
The adverb "ieri" means "yesterday".
The impersonal pronoun "si" means "one". The reflexive pronoun "si" means "itself".').

newspaper_basque_checks_1 :-
    %% a surname the lesson knows as an adjective
    nf_tr('Redondo duerme.', spanish, italian, E1),
    check('a word the lesson knows only as an adjective, at the head and before its verb, is a name, which refused the sentence', E1,
          'Redondo dorme.'),
    %% the person told, before a clause of the verb's
    nf_tr('Maria declara a Omar que el perro duerme.', spanish, italian, E2),
    check('after a verb the lesson says takes the clause, the person is the one told and the `que'' clause the verb''s, where it was Omar''s relative clause', E2,
          'Maria dichiara a Omar che il cane dorme.'),
    nf_tr('Maria declara el pan que el perro come.', spanish, italian, E3),
    check('a GUARD: a phrase that is no person keeps its relative clause', E3,
          'Maria dichiara il pane che il cane mangia.'),
    %% an adjective before a clause of the verb's
    nf_tr('La casa hará necesario que el perro duerma.', spanish, italian, E4),
    check('an adjective before a clause of the verb''s is said of the clause, the masculine, where it agreed with the subject', E4,
          'La casa farà necessario che il cane dorme.'),
    %% a count alone
    nf_tr('El perro duerme entre las tres y las cinco.', spanish, italian, E5),
    check('an article and a count alone is a phrase whose noun was left out, which refused the sentence', E5,
          'Il cane dorme tra le tre e le cinque.'),
    nf_tr('El perro duerme a las tres.', spanish, italian, E6),
    check('... and after `a'' it is no person marked as the object, where it was `al tre''', E6,
          'Il cane dorme alle tre.'),
    nf_tr('El perro duerme entre las tres y las cinco.', spanish, english, E7),
    check('... and English writes the count with no `ones''', E7,
          'The dog sleeps between the three and the five.'),
    %% a reflexive after a coordinator
    nf_tr('El perro come el pan y se lava.', spanish, english, E8),
    check('a `se'' in a clause joined with nobody named is the shared subject''s own, where it was the impersonal one', E8,
          'The dog eats the bread and washes.'),
    %% who said so
    nf_tr('En la casa, según dijo Omar a Maria, el perro duerme.', spanish, italian, E9),
    check('who said so, between two commas: written back where it stood, with the word for `as'', which refused the sentence', E9,
          'Nella casa, come disse Omar a Maria, il cane dorme.'),
    nf_tr('Según dijo Redondo Terreros, el perro duerme.', spanish, italian, E10),
    check('... at the head of the sentence, and a speaker whose first name the lesson knows is one name, which refused the sentence', E10,
          'Come disse Redondo Terreros, il cane dorme.').

newspaper_basque_checks_2 :-
    %% the impersonal perfect
    nf_tr('Se ha comido el pan.', spanish, italian, E11),
    check('the impersonal word builds its perfect as the reflexive does, where it was `si ha mangiato''', E11,
          'Si è mangiato il pane.'),
    %% a quotation that opens on a reflexive
    nf_tr('Maria dice que el perro "se lava".', spanish, italian, E12),
    check('a quotation mark on the reflexive is put back on the verb group, where it was lost', E12,
          'Maria dice che il cane "si lava".'),
    %% the one that, and a relative clause with its subject after its verb
    nf_tr('El perro llega después de la que el gato come.', spanish, italian, E13),
    check('an article before a relative word heads no clause as the pronoun `her'' -- which refused the sentence here, and wrote `dopo lei che'' over the vocabulary', E13,
          'Il cane arriva dopo quella che il gatto mangia.'),
    nf_tr('El perro llega después de la que comen los gatos.', spanish, english, E14),
    check('a relative clause whose verb disagrees with its phrase has its subject after the verb, where it was her that ate the cats', E14,
          'The dog arrives after the one that the cats eat.'),
    nf_tr('Maria ve el pan que comen los perros de Omar.', spanish, english, E15),
    check('... and the `de'' phrases after that subject are its own, where English left them behind the verb', E15,
          'Maria sees the bread that the dogs of Omar eat.'),
    nf_tr('Maria ve el pan que comen los perros.', spanish, english, E16),
    check('... a singular phrase and a plural verb, where the clause had the dogs for its object', E16,
          'Maria sees the bread that the dogs eat.'),
    %% a front that ends at a comma
    nf_tr('En la casa que vieron ayer, el perro come el pan.', spanish, english, E17),
    check('a front ending at a comma with a phrase after it is tried first, which refused the sentence', E17,
          'In the house that they saw yesterday, the dog eats the bread.'),
    %% an absolute participle
    nf_tr('El perro come el pan dada la situación.', spanish, italian, E18),
    check('a GUARD: a participle before a phrase it agrees with is an absolute clause -- and Italian writes the same words from either reading', E18,
          'Il cane mangia il pane data la situazione.'),
    nf_tr('El perro come el pan dada la situación.', spanish, english, E19),
    check('... which only English shows: it was the bread''s reduced relative and the situation an object', E19,
          'The dog eats the bread given the situation.'),
    %% the builder: one singular for both genders
    %% (lines, not a search in one atom: sub_atom/5 over eleven megabytes did
    %% not come back)
    read_file_to_codes('library/reasoning/corpus/vocabulary/italian.txt', VC), atom_codes(VA, VC),
    atomic_list_concat(VLs, '\n', VA),
    yes_no(( nth1(B1, VLs, 'The noun "socialista" means "socialist".'),
             nth1(B2, VLs, '"socialisti" is the plural of "socialista".'),
             nth1(B3, VLs, '"socialiste" is the plural of "socialista".'), B1 < B2, B2 < B3,
             \+ memberchk('The feminine noun "socialista" means "socialist".', VLs) ), E20),
    check('the builder states a noun with one singular for both genders with no gender and the masculine plural first, where `los socialistas'' came out `le socialiste''', E20, yes),
    yes_no(( nth1(C1, VLs, 'The adjective "ottimista" means "optimistic".'),
             nth1(C2, VLs, '"ottimisti" is the plural of "ottimista".'), C1 < C2,
             nth1(C3, VLs, '"ottimiste" is the plural of "ottimista".'), C2 < C3, C3 - C1 =< 3,
             nth1(C4, VLs, '"ottimiste" is feminine.'), C4 =:= C3 + 1 ), E21),
    check('... and an adjective of that shape with both plurals, the feminine said to be, where it had the masculine plural alone and `las previsiones ... optimistas'' came out `ottimisti''', E21, yes).

%% what the controls found: a noun of both genders, an adjective of both
%% genders, an adjective before a relative clause after the copula, and a
%% relative clause after two phrases joined -- over lessons of their own
newspaper_basque_lesson2(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "solista" means "soloist". "solista" is not feminine. "solistas" is the plural of "solista".
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". The noun "casa" means "house".
The noun "ratón" means "mouse". "ratones" is the plural of "ratón". The noun "pedazo" means "piece".
The adjective "optimista" means "optimistic". "optimistas" is the plural of "optimista".
The adjective "neonazi" means "neo-nazi". "neonazis" is the plural of "neonazi".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "come" means "eats". "comen" is the plural of "come".
The verb "ve" means "sees". The verb "toca" means "touches". "tocan" is the plural of "toca".
The verb "es" means "is". "son" is the plural of "es". "será" is the future of "es". "serán" is the plural of "será".
The preposition "de" means "of".
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative.').

newspaper_basque_lesson2(italian, 'Italian is a language.
The feminine article "la" means "the". The masculine article "il" means "the".
"le" is the plural of "la". "i" is the plural of "il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "solista" means "soloist". "solista" is not feminine.
"solisti" is the plural of "solista". "soliste" is the plural of "solista". "soliste" is feminine.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". The noun "topo" means "mouse".
The noun "pane" means "bread". The noun "casa" means "house". "case" is the plural of "casa".
The noun "pezzo" means "piece". "pezzi" is the plural of "pezzo".
The adjective "ottimista" means "optimistic".
"ottimisti" is the plural of "ottimista". "ottimiste" is the plural of "ottimista". "ottimiste" is feminine.
The adjective "neonazista" means "neo-nazi".
"neonazisti" is the plural of "neonazista". "neonaziste" is the plural of "neonazista". "neonaziste" is feminine.
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "vede" means "sees". The verb "tocca" means "touches". "toccano" is the plural of "tocca".
The verb "è" means "is". "sono" is the plural of "è". "sarà" is the future of "è". "saranno" is the plural of "sarà".
The preposition "di" means "of".
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative.').

newspaper_basque_checks_3 :-
    nf_tr('Los solistas duermen.', spanish, italian, F1),
    check('a noun of both genders, which the lesson denies the feminine, takes the masculine article -- Italian''s first article is `la'', and it came out `Le solisti''', F1,
          'I solisti dormono.'),
    nf_tr('Las casas son optimistas.', spanish, italian, F2),
    check('an adjective of one singular for both genders takes the plural the lesson says is feminine after a feminine noun, where it took the first, `ottimisti''', F2,
          'Le case sono ottimiste.'),
    nf_tr('Los perros son optimistas.', spanish, italian, F3),
    check('a GUARD: ... and the first plural not said to be feminine after any other', F3,
          'I cani sono ottimisti.'),
    nf_tr('Serán neonazis que comen el pan.', spanish, italian, F4),
    check('a GUARD: an adjective before a relative clause after the COPULA is the subject''s, and no clause''s -- the first cut wrote `saranno neonazista'', the Spanish article''s fifth', F4,
          'Saranno neonazisti che mangiano il pane.'),
    nf_tr('Il cane mangia i pezzi di pane che toccano la casa.', italian, spanish, F5),
    check('a GUARD: a relative clause that agrees with no phrase it can hang on, and has an object of its own, reads as it stood -- the first cut refused it, and with it the islands report''s ninth, `lembi di terra che si chiamano Giglio'', and Livata''s last sentence', F5,
          'El perro come los pedazos de pan que tocan la casa.').

%% ---- an Italian letter into Spanish: a connecting adverb, what there is
%% after an adverb, but only, the ones that exist, a command of the first
%% person plural, a clause after `sembra', a date with its adjective, the
%% comment of who wrote it (1.8.16) ------------------------------------------

newspaper_giglio :-
    section('an Italian letter into Spanish: a connecting adverb, what there is after an adverb, but only, the ones that exist, the gender and the number a participle keeps, as in, the future of can, we as a subject of an intransitive verb, a command of the first person plural, a clause with its che left out before a phrase, a date with its adjective, who wrote it'),
    newspaper_giglio_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_giglio_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_giglio_checks_1, newspaper_giglio_checks_2,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_giglio_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person. The word "de" joins the date. The word "el" replaces the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "queso" means "cheese". The feminine noun "casa" means "house".
The noun "artículo" means "article". The noun "enviado" means "envoy". The feminine noun "fosa" means "pit".
The noun "julio" means "july". "julio" is a month.
The masculine adjective "cansado" means "tired". The feminine adjective "cansada" means "tired".
The adjective "existente" means "existent". "existentes" is the plural of "existente".
The masculine adjective "otro" means "other". The feminine adjective "otra" means "other". "otros" is the plural of "otro". "otras" is the plural of "otra".
The masculine adjective "último" means "last". The masculine adjective "solo" means "alone".
The verb "come" means "eats". "comen" is the plural of "come". "comemos" is the first person of "comen". "comamos" is the hortative of "come". "comer" is the infinitive of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "ve" means "sees". "visto" is the participle of "ve". "vista" is the participle of "ve". "vista" is feminine.
"vistos" is the participle of "ve". "vistos" is the plural of "visto". "vistas" is the participle of "ve". "vistas" is feminine. "vistas" is the plural of "vista".
The verb "acaba" means "finishes". "acaban" is the plural of "acaba". "acabamos" is the first person of "acaban". "acabemos" is the hortative of "acaba".
The verb "aparece" means "appears". "aparecido" is the participle of "aparece". "aparecidos" is the participle of "aparece". "aparecidos" is the plural of "aparecido".
The verb "escribe" means "writes". "escriben" is the plural of "escribe". "escrito" is the participle of "escribe".
The verb "parece" means "seems". "parecía" is the past of "parece".
The verb "es" means "is". "son" is the plural of "es". "era" is the past of "es".
The modal "puede" means "can". "podrá" is the future of "puede".
The verb "hay" means "there is". "hay" is the plural of "hay". "habrá" is the future of "hay".
The auxiliary "ha" means "has". "han" is the plural of "ha".
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "que" means "that". "que" is a relative.
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with". The preposition "por" means "by". The preposition "como" means "as".
The adverb "entonces" means "then". The adverb "por lo tanto" means "therefore". The adverb "en cambio" means "instead". The adverb "sólo" means "only". The adverb "más" means "more".
The pronoun "nos" means "us". The pronoun "lo" means "him".').

newspaper_giglio_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i".
"nel" is the contraction of "in il". "negli" is the contraction of "in gli". "nella" is the contraction of "in la". "al" is the contraction of "a il". "dal" is the contraction of "da il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not". The word "di" begins the infinitive.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane". The noun "formaggio" means "cheese". The feminine noun "casa" means "house". "case" is the plural of "casa".
The noun "articolo" means "article". "articoli" is the plural of "articolo". The noun "inviato" means "envoy". "inviati" is the plural of "inviato".
The noun "ministro" means "minister". "ministro" is a person.
The feminine noun "fossa" means "pit". "fosse" is the plural of "fossa".
The noun "luglio" means "july". "luglio" is a month.
The masculine adjective "stanco" means "tired". The feminine adjective "stanca" means "tired". "stanchi" is the plural of "stanco".
The adjective "esistente" means "existent". "esistenti" is the plural of "esistente".
The masculine adjective "altro" means "other". "altri" is the plural of "altro".
The masculine adjective "scorso" means "last". The masculine adjective "solo" means "alone".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiamo" is the first person of "mangiano". "mangiamo" is the hortative of "mangia". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "vede" means "sees". "visto" is the participle of "vede". "vista" is the participle of "vede". "vista" is feminine.
"visti" is the participle of "vede". "visti" is the plural of "visto". "viste" is the participle of "vede". "viste" is feminine. "viste" is the plural of "vista".
The intransitive verb "finisce" means "ends up". The verb "finisce" means "finishes". "finiscono" is the plural of "finisce". "finiamo" is the first person of "finiscono". "finiamo" is the hortative of "finisce".
The verb "appare" means "appears". "apparso" is the participle of "appare". "apparsi" is the participle of "appare". "apparsi" is the plural of "apparso".
The verb "scrive" means "writes". "scrivono" is the plural of "scrive". "scritto" is the participle of "scrive". "written" is the participle of "writes".
The verb "sembra" means "seems". "sembrava" is the past of "sembra". "sembra" takes the clause.
The verb "è" means "is". "sono" is the plural of "è". "era" is the past of "è". "fosse" is the past subjunctive of "è". "siate" is the imperative of "sono".
The modal "può" means "can". "potrà" is the future of "può".
The verb "vi è" means "there is". "vi sarà" is the future of "vi è". "vi saranno" is the plural of "vi sarà".
The auxiliary "ha" means "has". "hanno" is the plural of "ha".
The conjunction "e" means "and". The conjunction "ma" means "but". The conjunction "che" means "that". "che" is a relative.
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "con" means "with". The preposition "da" means "by". The preposition "come" means "as".
The adverb "quindi" means "then". The adverb "perciò" means "therefore". The adverb "invece" means "instead". The adverb "solo" means "only". The adverb "più" means "more".
The pronoun "ci" means "us". The pronoun "lo" means "him". The pronoun "mi" means "me".
The word "quello" replaces the noun. The masculine demonstrative "quello" means "that". The masculine pronoun "quello" means "that". "quelli" is the plural of "quello". The pronoun "quello" does not precede the verb.').

newspaper_giglio_checks_1 :-
    %% a connecting adverb before an adjective
    ( reason_ir('Siate perciò stanchi.', italian, IR1) -> true ; IR1 = none ),
    yes_no(IR1 = [ir(s(_, _, _, [adv(w(therefore, _)), adj(_)]), _)], C1),
    check('an adverb that joins its clause to the one before says nothing of the adjective after it, where it was the adjective''s intensifier, `therefore tired'', which Spanish refused', C1, yes),
    %% what there is, after the verb's adverbs
    nf_tr('Non vi saranno quindi altri pani.', italian, spanish, G2),
    check('... and before an adjective of what there is it is the clause''s too, where `quindi altri'' went after its noun, `panes entonces otros''', G2,
          'No habrá entonces otros panes.'),
    nf_tr('Non vi saranno quindi altri pani.', italian, english, G3),
    check('what there is may come after the verb''s adverbs, which English writes after `will'' -- `then'' was inside the phrase, `no then other breads'', and with it the clause''s and no more, the first cut read THEY will not be, `they will not there is''', G3,
          'There will then be no other breads.'),
    %% but only
    nf_tr('Il cane non mangia il pane, ma solo il formaggio.', italian, english, G4),
    check('adverbs after a comma and a coordinator are the phrase''s, where `ma solo'' was two adjectives, `but'' and `alone''', G4,
          'The dog does not eat the bread, but only the cheese.'),
    %% the ones that exist
    nf_tr('Il cane dorme con quelli esistenti.', italian, spanish, G5),
    check('after a word that replaces the noun, a word that is an adjective and nothing else is no noun by position: the existing ones, where it read as THOSE EXISTENTS, `esos existentes'' over the vocabulary', G5,
          'El perro duerme con los existentes.'),
    %% a participle's gender AND number
    nf_tr('Il cane vede le case del gatto viste dal formaggio.', italian, spanish, G6),
    check('a participle that differs from the noun before it in gender and in number keeps both, where only the gender went: `vista''', G6,
          'El perro ve las casas del gato vistas por el queso.'),
    %% a participle after a comma that does not agree with the phrase before it
    ( reason_ir('Le case dormono con il pane, viste dal cane.', italian, IR7) -> true ; IR7 = none ),
    yes_no(( IR7 = [ir(s(_, _, _, Cs7), _)], memberchk(pred(sees), Cs7) ), C7),
    check('a participle after a comma that differs from the phrase before it in number is the subject''s, where it was the bread''s aside', C7, yes),
    %% as in
    nf_tr('Il cane dorme come nella casa.', italian, spanish, G8),
    check('a preposition meaning `as'' takes a phrase with a preposition of its own, which refused the sentence', G8,
          'El perro duerme como en la casa.'),
    %% the future of can
    nf_tr('Il cane potrà dormire.', italian, english, G9),
    check('English''s `can'' has no future, and `will be able to'' says it, where the sentence was refused', G9,
          'The dog will be able to sleep.'),
    %% we, before an intransitive verb and its object
    nf_tr('Finiamo il pane.', italian, spanish, G10),
    check('a verb the lesson calls intransitive, with WE for the subject nobody named, keeps its object -- given up at once for a third person, it was refused', G10,
          'Acabamos el pan.').

newspaper_giglio_checks_2 :-
    %% the command of the first person plural
    nf_tr('Mangiamolo.', italian, spanish, G11),
    check('a form the lesson calls a hortative, with its pronoun joined, is the command of the first person plural, which refused the sentence', G11,
          'Comamoslo.'),
    nf_tr('Mangiamolo.', italian, english, G12),
    check('... which English writes with `let us''', G12,
          'Let us eat him.'),
    nf_tr('Let us eat the bread.', english, spanish, G13),
    check('... and reads', G13,
          'Comamos el pan.'),
    nf_tr('Mangiamolo lo di dormire.', italian, spanish, G14),
    check('... the same pronoun written again after it is that pronoun once, the letter''s `Finiamola la di considerare''', G14,
          'Comamoslo dormir.'),
    nf_tr('Mangiamo il pane.', italian, spanish, G15),
    check('a GUARD: with no pronoun joined it is what we do', G15,
          'Comemos el pan.'),
    %% a clause with its che left out, before a phrase
    nf_tr('Il cane ci sembrava fosse stanco.', italian, spanish, G16),
    check('a clause with its `che'' left out comes before the phrase where its verb is no determiner: `fosse'' was the plural of `fossa'', pits', G16,
          'El perro nos parecía que era cansado.'),
    %% a date with its adjective
    nf_tr('Il cane dorme il 12 luglio scorso.', italian, spanish, G17),
    check('a date keeps the word that joins it when an adjective follows the month, where it came out `el 12 julio último''', G17,
          'El perro duerme el 12 de julio último.'),
    nf_tr('Il cane dorme negli articoli apparsi il 12 luglio.', italian, spanish, G18),
    check('a participle''s number is its own, asked with the number given: `apparsi'' read as an absolute clause agreeing with the date', G18,
          'El perro duerme en los artículos aparecidos el 12 de julio.'),
    %% who wrote it, between two commas
    nf_tr('Il cane dorme, come invece hanno scritto gli inviati, negli articoli.', italian, spanish, G19),
    check('an adverb before the verb of who said so stays before it, and the phrase after the comment stays after it, where it moved into the clause before', G19,
          'El perro duerme, como en cambio han escrito los enviados, en los artículos.'),
    nf_tr('Il cane dorme, come hanno scritto gli inviati del gatto, negli articoli.', italian, english, G20),
    check('... and the speaker''s `of'' phrase is the speaker''s, where English said the envoys wrote OF the cat', G20,
          'The dog sleeps, as the envoys of the cat have written, in the articles.'),
    nf_tr('“Il gatto dorme” ha scritto il cane di Roma, Mario Rossi.', italian, english, G21),
    check('... with the name apposed after the last of them, which the controls found: the name was left with nothing to read it, and the speaker was the object of a verb nobody named -- Livata''s `ha spiegato il capitano ... di Subiaco, Alessio Falzone'' came out `ha explicado al capitán''', G21,
          '“The cat sleeps” the dog of Roma, Mario Rossi, has written.'),
    nf_tr('Il cane dorme, ha scritto il ministro del gatto.', italian, english, G22),
    check('... and at the end of a sentence too, where a speaker with the `of'' phrases after it is of its head''s class: the first cut found no person after the verb, the minister was the object of a verb nobody named and English refused, and 1.8.15 had the `of'' phrase as the verb''s -- the Solana report''s `explicó ayer el ministro de Asuntos Exteriores'', the same Italian from all three readings, which only the count showed', G22,
          'The dog sleeps, the minister of the cat has written.').

%% ---- a Spanish column into Italian: `and' inside a phrase, a sense by the
%% article's gender, a noun after a noun, an answer, a comparison of two
%% adjectives, the impersonal's participle, a verb before a gerund, the comma
%% after an apposition, the article of `de los que', two subjects after
%% their verb (1.8.17) --------------------------------------------------------

newspaper_england :-
    section('a Spanish column into Italian: and inside a preposition''s phrase, a sense by the article''s gender, an adjective after its verb, a noun after a noun, an answer before a comma, a comparison of two adjectives, a subject after its predicate, the impersonal''s participle, no elision before an article, a verb before a gerund, the comma after an apposition, the article of de los que, two subjects after their verb'),
    newspaper_england_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_england_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_england_checks_1, newspaper_england_checks_2,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_england_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The adverb "no" means "no". The word "a" precedes the person.
The word "más" begins the comparative. The adverb "más" means "more". The word "el" replaces the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The noun "hermano" means "brother". "hermano" is a person.
The noun "comportamiento" means "behaviour". The noun "rastro" means "trace". The noun "miedo" means "fear".
The feminine noun "población" means "population". "poblaciones" is the plural of "población".
The masculine noun "final" means "end". The feminine noun "final" means "final". "finales" is the plural of "final".
The noun "chico" means "lad". The noun "hincha" means "fan". "hinchas" is the plural of "hincha". "hincha" is not feminine.
The feminine noun "coincidencia" means "coincidence". The masculine noun "ridículo" means "ridicule". The noun "salto" means "jump".
The masculine adjective "rojo" means "red". The feminine adjective "roja" means "red". "rojos" is the plural of "rojo". "rojas" is the plural of "roja".
The masculine adjective "negro" means "black". "negros" is the plural of "negro".
The masculine adjective "blanco" means "white". "blancos" is the plural of "blanco".
The masculine adjective "largo" means "long". The feminine adjective "larga" means "long".
The adjective "grande" means "big". "grandes" is the plural of "grande".
The masculine adjective "inadvertido" means "unnoticed". The masculine adjective "ridículo" means "ridiculous".
The verb "civiliza" means "civilises". "civilizado" is the participle of "civiliza".
The adverb "poco" means "little". The masculine determiner "poco" means "little".
The adverb "casi" means "almost". The adverb "sólo" means "only".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comiendo" is the gerund of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme". "durmiendo" is the gerund of "duerme".
The verb "sigue" means "follows". The progressive verb "sigue" means "continues". "siguen" is the plural of "sigue".
The verb "deja" means "leaves". "dejado" is the participle of "deja".
The verb "entra" means "enters". "entre" is the subjunctive of "entra".
The verb "habla" means "speaks". "hablas" is the second person of "habla".
The verb "pasa" means "passes". The intransitive verb "pasa" means "happens". "pasado" is the participle of "pasa".
The intransitive verb "cabe" means "remains".
The verb "produce" means "produces". "producido" is the participle of "produce".
The verb "es" means "is". "son" is the plural of "es". "era" is the past of "es". "eran" is the plural of "era".
The auxiliary "ha" means "has". "han" is the plural of "ha". "haya" is the subjunctive of "ha".
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative. The conjunction "que" means "than".
The conjunction "aunque" means "although".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "por" means "for". The preposition "entre" means "among".
The pronoun "ello" means "this". The pronoun "ello" does not precede the verb.
The demonstrative "este" means "this". "estos" is the plural of "este". The feminine demonstrative "esta" means "this". "estas" is the plural of "esta".
The possessive "su" means "his".
The adjective "segundo" means "second". The masculine noun "segundo" means "second". The noun "encuentro" means "meeting".
The preposition "tras" means "after". "haber" is the infinitive of "ha". "comido" is the participle of "come".
The intransitive verb "para" means "stops". "paran" is the plural of "para".
The reflexive pronoun "se" means "itself". The impersonal pronoun "se" means "one".').

newspaper_england_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i".
"d''" is the elision of "di". "quest''" is the elision of "questo".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not". The adverb "no" means "no".
The word "più" begins the comparative. The adverb "più" means "more".
The word "quello" replaces the noun. The word "quella" replaces the noun.
The pronoun "quello" means "that". The pronoun "quello" does not precede the verb.
The masculine demonstrative "quello" means "that". "quelli" is the plural of "quello". The feminine demonstrative "quella" means "that". "quelle" is the plural of "quella".
The article "il" takes the possessive.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane".
The feminine noun "casa" means "house". "case" is the plural of "casa". The noun "fratello" means "brother". "fratello" is a person.
The noun "comportamento" means "behaviour". The feminine noun "traccia" means "trace". The feminine noun "paura" means "fear".
The feminine noun "popolazione" means "population". "popolazioni" is the plural of "popolazione". The noun "ragazzo" means "lad". "ragazzi" is the plural of "ragazzo".
The noun "tifoso" means "fan". "tifosi" is the plural of "tifoso".
The feminine noun "fine" means "end". The feminine noun "finale" means "final".
The feminine noun "coincidenza" means "coincidence". The noun "ridicolo" means "ridicule". The noun "salto" means "jump".
The masculine adjective "rosso" means "red". The feminine adjective "rossa" means "red". "rossi" is the plural of "rosso". "rosse" is the plural of "rossa".
The masculine adjective "nero" means "black". "neri" is the plural of "nero".
The masculine adjective "bianco" means "white". "bianchi" is the plural of "bianco".
The masculine adjective "lungo" means "long". The feminine adjective "lunga" means "long".
The adjective "grande" means "big". "grandi" is the plural of "grande".
The masculine adjective "inosservato" means "unnoticed".
The verb "civilizza" means "civilises". "civilizzato" is the participle of "civilizza".
"civilizzati" is the participle of "civilizza". "civilizzati" is the plural of "civilizzato".
The adverb "poco" means "little". The adverb "quasi" means "almost". The adverb "solo" means "only".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "continua" means "continues". "continuano" is the plural of "continua". "continua" takes "a" before the infinitive.
The verb "segue" means "follows". The verb "lascia" means "leaves". The verb "parla" means "speaks". "parli" is the second person of "parla".
The verb "avviene" means "happens". "avvenuto" is the participle of "avviene". "è" is the auxiliary of "avviene".
The verb "rimane" means "remains". "rimangono" is the plural of "rimane".
The verb "produce" means "produces". "prodotto" is the participle of "produce". "prodotta" is the participle of "produce". "prodotta" is feminine.
The verb "è" means "is". "sono" is the plural of "è". "era" is the past of "è". "erano" is the plural of "era".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "è" is the auxiliary of the reflexive.
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative. The conjunction "che" means "than".
"cui" is a relative. The word "cui" follows the preposition.
The conjunction "nonostante" means "although".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "per" means "for". The preposition "tra" means "among".
The masculine adjective "secondo" means "second". The feminine adjective "seconda" means "second". The masculine noun "secondo" means "second".
The feminine noun "riunione" means "meeting". The preposition "dopo" means "after". "avere" is the infinitive of "ha".
"mangiato" is the participle of "mangia". "mangiata" is the participle of "mangia". "mangiata" is feminine.
"lasciato" is the participle of "lascia". "lasciata" is the participle of "lascia". "lasciata" is feminine.
The transitive verb "ferma" means "stops". "fermano" is the plural of "ferma". The verb "cessa" means "stops". "cessano" is the plural of "cessa".
The pronoun "questo" means "this". The pronoun "questo" does not precede the verb.
The masculine demonstrative "questo" means "this". "questi" is the plural of "questo". The feminine demonstrative "questa" means "this". "queste" is the plural of "questa".
The possessive "suo" means "his".
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".').

newspaper_england_checks_1 :-
    %% `and' after a preposition, with a singular verb
    nf_tr('El perro de Juan y María come el pan.', spanish, english, E1),
    check('`and'' after a preposition with a singular verb joins inside the preposition''s phrase, where the subject was the dog AND María against a verb that says one -- the column''s `La final de copa entre Inglaterra y Alemania ha tenido'', `hanno avuto'' in Italian', E1,
          'The dog of Juan and María eats the bread.'),
    nf_tr('El perro de Juan y María comen el pan.', spanish, english, E2),
    check('a GUARD: with a plural verb the two are the subject', E2,
          'The dog of Juan and María eat the bread.'),
    %% a sense by the article's gender
    nf_tr('La final es larga.', spanish, english, E3),
    check('a noun the lesson states in both genders takes the meaning of its article''s gender: `la final'' is the final, where it was the end', E3,
          'The final is long.'),
    nf_tr('La final es larga.', spanish, italian, E4),
    check('... and the target''s word for it', E4, 'La finale è lunga.'),
    nf_tr('El final es largo.', spanish, english, E5),
    check('a GUARD: `el final'' is the end', E5, 'The end is long.'),
    %% a lone adjective after the verb
    ( reason_ir('El perro come el pan, aunque ha pasado casi inadvertido.', spanish, IR6) -> true ; IR6 = none ),
    yes_no(IR6 = [ir(join(comma, _, join(_, none, s(_, null(_, _), _, [adj(_)]))), _)], C6),
    check('a lone word the lesson knows only as an adjective is no subject after its verb: `aunque ha pasado casi inadvertido'' is it went almost unnoticed, where `unnoticed'' was what happened', C6, yes),
    %% a noun after a noun
    nf_tr('Los chicos hinchas duermen.', spanish, italian, E7),
    check('a noun after a noun, in its number, says what kind: the column''s `los muchachotes hinchas'', which was refused', E7,
          'I ragazzi tifosi dormono.'),
    %% an adverb before a participle is the participle's
    nf_tr('Los perros comen por su comportamiento poco civilizado.', spanish, italian, E8),
    check('an adverb before a participle ends no phrase at the determiner it also is, and the participle agrees with its own noun, where it agreed with the subject, `civilizzati''', E8,
          'I cani mangiano per il suo comportamento poco civilizzato.'),
    %% an answer before a comma
    nf_tr('No, el perro duerme.', spanish, italian, E9),
    check('an answer before a comma is no denial of the clause after it: `No, sería mucho pedir.'' came out `Non sarebbe molto chiedere''', E9,
          'No, il cane dorme.'),
    nf_tr('No, el perro duerme.', spanish, english, E10),
    check('... and English writes it as the answer', E10, 'No, the dog sleeps.'),
    %% a comparison of two adjectives
    nf_tr('Los perros más negros que blancos duermen.', spanish, italian, E11),
    check('an adjective with its degree and a term of comparison that is adjectives too is one phrase: `estas hordas más vikingas que británicas'', which was refused', E11,
          'I cani più neri che bianchi dormono.'),
    nf_tr('Los perros más negros que blancos duermen.', spanish, english, E12),
    check('... after the noun in English, and always the comparative -- the first cut wrote `blackest'' after the definite article', E12,
          'The dogs blacker than white sleep.').

newspaper_england_checks_2 :-
    %% the subject after its predicate, opening on a demonstrative
    nf_tr('Son rojas estas casas.', spanish, italian, F1),
    check('the phrase after a copula''s predicate is its subject when it opens on a demonstrative too, where only an article opened one', F1,
          'Sono rosse queste case.'),
    %% the impersonal's participle
    nf_tr('Se ha producido una coincidencia.', spanish, italian, F2),
    check('the participle after the impersonal `si'' agrees with the object, where it agreed with nobody, `si è prodotto''', F2,
          'Si è prodotta una coincidenza.'),
    %% no elision before an article
    nf_tr('El perro come por ello el pan.', spanish, italian, F3),
    check('a word that is no preposition is not elided before an article, which opens another phrase: `per quest''i tonti commenti''', F3,
          'Il cane mangia per questo il pane.'),
    nf_tr('El perro duerme de un salto.', spanish, italian, F4),
    check('a GUARD: a preposition is -- the first cut wrote `di un''', F4,
          'Il cane dorme d''un salto.'),
    %% a verb before a gerund
    nf_tr('El perro sigue durmiendo.', spanish, italian, F5),
    check('a verb before a gerund crosses by the meaning the lesson calls progressive, `continues'', where `sigue'' followed, and Italian writes it with the infinitive its verb takes', F5,
          'Il cane continua a dormire.'),
    nf_tr('El perro sigue durmiendo.', spanish, english, F6),
    check('... and English with the gerund', F6, 'The dog continues sleeping.'),
    nf_tr('El perro sigue el pan.', spanish, italian, F7),
    check('a GUARD: before a phrase it follows', F7, 'Il cane segue il pane.'),
    %% the comma after an apposition
    nf_tr('Juan, el hermano de María, duerme.', spanish, italian, F8),
    check('the comma between a subject and its verb is the source''s, and the one that closes an apposition: it was lost, `Juan, il fratello di María dorme''', F8,
          'Juan, il fratello di María, dorme.'),
    nf_tr('Juan, el hermano de María, duerme.', spanish, english, F9),
    check('... in English too', F9, 'Juan, the brother of María, sleeps.'),
    %% the article of `de los que'
    nf_tr('El perro de los que comen pan duerme.', spanish, italian, F10),
    check('the article between a preposition and the relative word agrees with the phrase it stands for: `el ridículo de los que los utilizan'' is of THOSE who use them, where it was `di cui''', F10,
          'Il cane di quelli che mangiano pane dorme.'),
    nf_tr('La casa de la que hablas es grande.', spanish, italian, F11),
    check('a GUARD: where it agrees, it is the relative word''s', F11,
          'La casa di cui parli è grande.'),
    %% two subjects after their verb
    nf_tr('Sólo cabe el perro, y el gato.', spanish, italian, F12),
    check('two phrases after a singular verb the lesson calls intransitive are its subject, with the comma or without it: `sólo cabe la paciencia, y el ridículo de ...'', where the second was an object of a verb that takes none', F12,
          'Solo rimangono il cane e il gatto.'),
    nf_tr('Cabe el perro y el gato.', spanish, italian, F13),
    check('... and without the comma', F13, 'Rimangono il cane e il gatto.'),
    %% what the controls found
    nf_tr('El perro deja un segundo encuentro.', spanish, italian, F14),
    check('a GUARD: a first word that is an adjective too is the adjective, and no noun after a noun: the first cut wrote `un secondo riunione'', as it wrote the Basque report''s `un segundo encuentro'' and the opera review''s `una ejemplar escena'' as `una copia scena''', F14,
          'Il cane lascia una seconda riunione.'),
    nf_tr('Se deja la casa, tras haber comido los panes.', spanish, italian, F15),
    check('a GUARD: the impersonal''s gender reaches its own perfect and nothing else: the first cut wrote `mangiata'', as it wrote the record report''s `dopo aver sofferta''', F15,
          'Si lascia la casa, dopo avere mangiato i pani.'),
    nf_tr('Se ha dejado la casa, tras haber comido los panes.', spanish, italian, F16),
    check('... and in a perfect, only its group: the participle of the perfect infinitive after it keeps the subject''s gender', F16,
          'Si è lasciata la casa, dopo avere mangiato i pani.'),
    nf_tr('Paran los perros.', spanish, italian, F17),
    check('a verb with its subject after it is chosen by its object as any verb is, and with none it is not the one the lesson calls transitive: the column''s `¿Pararán ... los bobalicones comentarios ...?'' came out `Fermeranno''', F17,
          'Cessano i cani.'),
    nf_tr('Los perros paran el pan.', spanish, italian, F18),
    check('a GUARD: with an object it is', F18, 'I cani fermano il pane.').

%% ---- an Italian letter into Spanish: the time of day, a day and its part,
%% a year in words, a denial after a coordinator, two adjectives of one noun,
%% a polite command, a purpose with its pronoun joined, a word said twice,
%% the reflexive passive's subject, the vocative and the answer between
%% dashes, a speaker after the verb with a clause of the speaker's own, bare nouns as
%% an object, a gerund in front, a signature with initials, the
%% experiencer, a comma after a coordinator, an adjective that is a
%% preposition too (1.8.18) --------------------------------------------------

newspaper_bovalino :-
    section('an Italian letter into Spanish: the time of day, a day and its part, a year in words, a denial after a coordinator, two adjectives of one noun, a polite command, a purpose with its pronoun joined, a word said twice, the reflexive passive''s subject, the vocative and the answer between dashes, a speaker after the verb with a clause of the speaker''s own, bare nouns as an object, a gerund in front, a signature with initials, the experiencer, a comma after a coordinator, an adjective that is a preposition too'),
    newspaper_bovalino_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_bovalino_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_bovalino_checks_1, newspaper_bovalino_checks_2, newspaper_bovalino_checks_3,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_bovalino_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The adverb "no" means "no". The word "a" precedes the person. The word "de" joins the date. The word "por" joins the time.
The word "para" begins the purpose. The mark "¿" begins the question.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "queso" means "cheese". The feminine noun "casa" means "house".
The noun "ministro" means "minister". "ministro" is a person. The noun "hermano" means "brother". "hermano" is a person.
The noun "profesor" means "professor". "profesor" is a person. "profesores" is the plural of "profesor".
The noun "señor" means "gentleman". "señor" is a person.
The noun "técnico" means "technician". "técnico" is a person. The noun "político" means "politician". "político" is a person.
The masculine adjective "técnico" means "technical". The masculine adjective "político" means "political".
The noun "país" means "country". "países" is the plural of "país". The noun "acercamiento" means "approach".
The feminine noun "misa" means "mass". The feminine noun "hora" means "hour".
The noun "año" means "year". "año" is a time. The noun "mes" means "month". "meses" is the plural of "mes".
The noun "comentario" means "comment". The feminine noun "guerra" means "war". The feminine noun "decisión" means "decision".
The noun "domingo" means "sunday". "domingo" is a time. The feminine noun "mañana" means "morning". "mañana" is a time.
The noun "julio" means "july". "julio" is a month.
The number "noventa y cinco" means "ninety-five". The number "dos" means "two".
The masculine adjective "nuevo" means "new". The masculine adjective "diverso" means "diverse".
The masculine adjective "cansado" means "tired". The feminine adjective "cansada" means "tired".
The masculine adjective "cercano" means "close". The adverb "cerca" means "near".
The masculine adjective "crítico" means "critical".
The masculine determiner "tanto" means "so much". "tantos" is the plural of "tanto".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comiendo" is the gerund of "come".
"pueden" is the plural of "puede". The modal "puede" means "can".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "ve" means "sees". "ven" is the plural of "ve". "ver" is the infinitive of "ve".
The verb "mira" means "looks". "mire" is the subjunctive of "mira".
The verb "pregunta" means "asks". "preguntado" is the participle of "pregunta".
The verb "contesta" means "answers". "contestado" is the participle of "contesta".
The verb "golpea" means "strikes". "golpeado" is the participle of "golpea".
The intransitive verb "gusta" means "pleases".
The verb "inserta" means "inserts". "insertará" is the future of "inserta".
The verb "es" means "is". "son" is the plural of "es". "era" is the past of "es". "eran" is the plural of "era". "ser" is the infinitive of "es".
"somos" is the first person of "son". "éramos" is the first person of "eran".
The auxiliary "está" means "is". "estar" is the infinitive of "está". The auxiliary "está" marks the state.
The modal "debe" means "must".
The auxiliary "ha" means "has". "he" is the first person of "ha".
The conjunction "y" means "and". The conjunction "o" means "or". The conjunction "que" means "that". "que" is a relative.
The conjunction "mientras" means "while". The conjunction "ya que" means "since".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with".
The preposition "en" means "on". The preposition "durante" means "during". The preposition "entre" means "among". The preposition "para" means "for".
The adverb "sólo" means "only". The adverb "sobre todo" means "above all".
The pronoun "me" means "me". The pronoun "le" means "him". The pronoun "lo" means "it". The pronoun "mí" means "me". The pronoun "mí" does not precede the verb.
The possessive "su" means "his".
The reflexive pronoun "se" means "itself". The impersonal pronoun "se" means "one".
The verb "viene" means "comes". The verb "da" means "gives". "dar" is the infinitive of "da". The noun "proyecto" means "blueprint".
The conjunction "pero" means "but". The adverb "también" means "also". The adverb "muy" means "very". The adjective "grande" means "big".
The adverb "en cambio" means "instead". "duerme" is the imperative of "duerme". The adverb "a veces" means "sometimes".
"puedo" is the first person of "puede". The preposition "desde" means "from". The verb "va" means "goes". "ido" is the participle of "va".').

newspaper_bovalino_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i". "delle" is the contraction of "di le".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "al" is the contraction of "a il". "alla" is the contraction of "a la".
"sul" is the contraction of "su il". "sulla" is the contraction of "su la". "sui" is the contraction of "su i".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not". The adverb "no" means "no". The word "per" begins the purpose.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane". The noun "formaggio" means "cheese". The feminine noun "casa" means "house". "case" is the plural of "casa".
The noun "ministro" means "minister". "ministro" is a person. "ministri" is the plural of "ministro".
The noun "fratello" means "brother". "fratello" is a person. "fratelli" is the plural of "fratello".
The noun "professore" means "professor". "professore" is a person.
The noun "signore" means "gentleman". "signore" is a person.
The noun "tecnico" means "technician". "tecnico" is a person. "tecnici" is the plural of "tecnico".
The noun "politico" means "politician". "politico" is a person. "politici" is the plural of "politico".
The masculine adjective "tecnico" means "technical". The masculine adjective "politico" means "political".
The noun "paese" means "country". The noun "approccio" means "approach".
The feminine noun "messa" means "mass". The feminine noun "ora" means "hour". "ore" is the plural of "ora".
The noun "anno" means "year". "anni" is the plural of "anno". "anno" is a time. The noun "mese" means "month". "mesi" is the plural of "mese".
The noun "commento" means "comment". The feminine noun "guerra" means "war". The feminine noun "decisione" means "decision".
The feminine noun "domenica" means "sunday". "domenica" is a time. The feminine noun "mattina" means "morning". "mattina" is a time.
The noun "luglio" means "july". "luglio" is a month.
The number "novantacinque" means "ninety-five". The number "due" means "two".
The masculine adjective "nuovo" means "new". The masculine adjective "diverso" means "diverse". The masculine determiner "diverso" means "several".
The masculine adjective "stanco" means "tired". The feminine adjective "stanca" means "tired".
The preposition "vicino" means "near". The masculine adjective "vicino" means "close".
The masculine adjective "critico" means "critical".
The masculine determiner "tanto" means "so much". "tanti" is the plural of "tanto".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangiando" is the gerund of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "vede" means "sees". "vedono" is the plural of "vede". "vedere" is the infinitive of "vede".
The verb "guarda" means "looks". "guardi" is the subjunctive of "guarda".
The verb "chiede" means "asks". "chiesto" is the participle of "chiede".
The verb "risponde" means "answers". "risposto" is the participle of "risponde".
The verb "colpisce" means "strikes". "colpito" is the participle of "colpisce". "colpisce" takes the experiencer.
The intransitive verb "piace" means "pleases".
The verb "inserisce" means "inserts". "inserirà" is the future of "inserisce".
The verb "è" means "is". "sono" is the plural of "è". "era" is the past of "è". "erano" is the plural of "era". "essere" is the infinitive of "è".
"siamo" is the first person of "sono". "eravamo" is the first person of "erano".
The auxiliary "sta" means "is". "stare" is the infinitive of "sta". The auxiliary "sta" marks the state.
The modal "deve" means "must". "dev" is the apocope of "deve". "possono" is the plural of "può". The modal "può" means "can".
The auxiliary "ha" means "has". "ho" is the first person of "ha".
The conjunction "e" means "and". The conjunction "o" means "or". The conjunction "che" means "that". "che" is a relative.
The conjunction "mentre" means "while". The conjunction "poiché" means "since".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "con" means "with".
The preposition "su" means "on". The preposition "durante" means "during". The preposition "tra" means "among". The preposition "per" means "for".
The adverb "soltanto" means "only". The adverb "soprattutto" means "above all".
The pronoun "mi" means "me". The dative pronoun "gli" means "him". The pronoun "lo" means "it". The pronoun "me" means "me". The pronoun "me" does not precede the verb.
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".
The possessive "suo" means "his".
The verb "viene" means "comes". The verb "dà" means "gives". "dare" is the infinitive of "dà". The noun "progetto" means "blueprint".
The conjunction "ma" means "but". The adverb "anche" means "also". The adverb "molto" means "very". The adjective "grande" means "big".
"struck" is the participle of "strikes".
The adverb "invece" means "instead". "dormi" is the imperative of "dorme". The adverb "talvolta" means "sometimes".
The preposition "da" means "from". "dalla" is the contraction of "da la". The pronoun "la" means "her".
The intransitive verb "va" means "goes". "è" is the auxiliary of "va". "andato" is the participle of "va". "andata" is the participle of "va". "andata" is feminine.').

newspaper_bovalino_checks_1 :-
    %% the time of day
    nf_tr('Il cane dorme durante la messa delle ore 9:30.', italian, spanish, B1),
    check('a time of day is one number, its colon inside it, where `9:30'' was three words and the sentence was refused', B1,
          'El perro duerme durante la misa de las horas 9:30.'),
    %% a day and its part
    nf_tr('Il cane dorme domenica mattina.', italian, spanish, B2),
    check('a day and its part are one time, which Spanish joins with the word the lesson says joins a time: `el domingo por la mañana'', where it was the morning''s Sunday', B2,
          'El perro duerme el domingo por la mañana.'),
    nf_tr('Il cane dorme domenica mattina.', italian, english, B3),
    check('... and English with nothing between them', B3, 'The dog sleeps sunday morning.'),
    %% a year in words
    nf_tr('Il cane dorme il 9 luglio novantacinque.', italian, spanish, B4),
    check('a number word after a month is the year, crossing by its meaning, where it was an adjective of the month', B4,
          'El perro duerme el 9 de julio de noventa y cinco.'),
    %% a denial after a coordinator
    nf_tr('Il cane mangia il pane e non il formaggio.', italian, spanish, B5),
    check('a denial after a coordinator with no verb after it is the second half''s: `un governo che duri 5 anni e non due mesi'' took the denial to the verb and said the opposite', B5,
          'El perro come el pan y no el queso.'),
    %% two adjectives of one noun
    nf_tr('Il nuovo e diverso cane dorme.', italian, spanish, B6),
    check('two adjectives joined before one noun are one phrase, where `diverso'' is the determiner `several'' too and the subject was two, the new one and several dog', B6,
          'El nuevo y diverso perro duerme.'),
    %% a polite command
    nf_tr('Guardi, il cane dorme.', italian, spanish, B7),
    check('a subjunctive alone before a comma, with nothing else in its piece, is the polite command: `Guardi, io voglio ...'', where it was you looking', B7,
          'Mire, el perro duerme.'),
    %% a purpose with its pronoun joined
    nf_tr('Il cane viene per mangiarlo.', italian, spanish, B8),
    check('a purpose''s infinitive may carry its pronoun joined, which refused the sentence', B8,
          'El perro viene para comerlo.'),
    %% a word said twice
    nf_tr('Il cane vede tanti, tanti gatti.', italian, spanish, B9),
    check('a determiner said twice before its noun is said twice, where the comma divided the sentence', B9,
          'El perro ve tantos, tantos gatos.'),
    %% the reflexive passive's subject
    nf_tr('Si possono mangiare i pani.', italian, spanish, B10),
    check('the phrase after a modal and its infinitive is the reflexive passive''s subject, and stands after the infinitive, where it stood between them', B10,
          'Se pueden comer los panes.'),
    %% the vocative and the answer between dashes
    nf_tr('Professore - gli ho chiesto - il cane dorme?', italian, spanish, B11),
    check('a word before a clause set between dashes is the one spoken to, and the clause stays where it stood; the question is the clause after it, and its opening mark goes there', B11,
          'Profesor – le he preguntado –, ¿el perro duerme?'),
    nf_tr('No - mi ha risposto -, il cane dorme.', italian, spanish, B12),
    check('... and the answer, a comma after the closing dash, where a hyphen before a comma was no dash', B12,
          'No – me ha contestado –, el perro duerme.'),
    %% a speaker after the verb with a clause of the speaker's own
    nf_tr('Professore - gli ha chiesto un signore mentre eravamo nella casa -, il cane dorme?', italian, spanish, B13),
    check('a reporting clause between dashes has its speaker after its verb, with a clause of the speaker''s own after it: the gentleman was what was asked', B13,
          'Profesor – le ha preguntado un señor mientras éramos en la casa –, ¿el perro duerme?').

newspaper_bovalino_checks_2 :-
    %% bare nouns as the object
    nf_tr('Il ministro inserirà tecnici o politici.', italian, spanish, C1),
    check('bare plurals after a verb that takes an object are its object where each is a noun too, and persons of no particular kind take no word before them: `insertará técnico o político'' was a predicate', C1,
          'El ministro insertará técnicos o políticos.'),
    nf_tr('Il ministro è tecnico.', italian, spanish, C2),
    check('a GUARD: after the copula they are the predicate', C2, 'El ministro es técnico.'),
    %% a gerund in front
    nf_tr('Soltanto mangiando il pane il cane dorme.', italian, spanish, C3),
    check('a gerund with its complements stands in front of a clause with no comma, as an adjunct, where the sentence was refused', C3,
          'El perro duerme sólo comiendo el pan.'),
    %% a signature with initials
    nf_tr('Mario Rossi Roma (r c) commento critico sulla guerra, decisione del ministro.', italian, spanish, C4),
    check('letters no lesson knows in a bracket are initials, written as they stood, and a title of bare phrases with commas between them follows the signature', C4,
          'Mario Rossi Roma (r c) comentario crítico en la guerra, decisión del ministro.'),
    %% the experiencer
    nf_tr('Mi ha colpito il nuovo approccio.', italian, english, C5),
    check('a verb the lesson says takes the experiencer has its subject after it, where the approach was what somebody nobody named struck', C5,
          'The new approach has struck me.'),
    nf_tr('Mi ha colpito il nuovo e diverso approccio.', italian, english, C6),
    check('... two adjectives of one noun among it', C6,
          'The new and diverse approach has struck me.'),
    nf_tr('Mi ha colpito il nuovo approccio del ministro, che dorme.', italian, english, C7),
    check('... and a relative clause after a comma, with a phrase of the verb''s after the subject, hangs on the last phrase', C7,
          'The new approach of the minister, who sleeps, has struck me.'),
    %% a comma after a coordinator
    nf_tr('Il cane dorme sul pane, sulla casa e, soprattutto, sul formaggio.', italian, spanish, C8),
    check('a coordinator between two complements may have a comma after it, before an insertion, and every comma is kept, where all three were lost', C8,
          'El perro duerme en el pan, en la casa y, sobre todo, en el queso.'),
    %% an adjective that is a preposition too
    nf_tr('Il cane dorme in un paese vicino, con il gatto.', italian, spanish, C9),
    check('a word that is a preposition and an adjective, after a noun and before a comma, is the phrase''s adjective, where it stood alone as an adverb, `en un país cerca''', C9,
          'El perro duerme en un país cercano, con el gato.'),
    %% dev, and the state's infinitive
    nf_tr('Il cane dev essere stanco.', italian, spanish, C10),
    check('`dev'' is the apocope of `deve'', which the letter writes with no apostrophe', C10,
          'El perro debe ser cansado.'),
    nf_tr('A me piace stare con il cane.', italian, spanish, C11),
    check('a word meaning `to'' and a pronoun that stands alone before a verb that pleases are the dative, and the infinitive after it is what pleases, the state''s where the lesson says so', C11,
          'Me gusta estar con el perro.'),
    %% no verb, a relative clause's verb in it
    nf_tr('Il progetto: dare il pane al cane che dorme.', italian, spanish, C12),
    check('a piece with no verb of its own reads, the verb of a relative clause in it being the clause''s: the letter''s `dare all''Italia un governo ..., ma anche molto attento verso i soggetti che vivono una vita disagiata''', C12,
          'El proyecto: dar el pan al perro que duerme.'),
    %% an adjective aside, and a coordinator after its comma
    nf_tr('Il cane vede un gatto nuovo, stanco del pane, ma anche molto grande.', italian, spanish, C13),
    check('an adjective set off after a noun takes the coordinator after its comma into the aside, with the adverbs and the adjective after it, which say more of the noun; every comma is kept', C13,
          'El perro ve un gato nuevo, cansado del pan, pero también muy grande.'),
    %% English of the speaker after the verb
    nf_tr('Professore - gli ha chiesto un signore mentre eravamo nella casa -, il cane dorme?', italian, english, C14),
    check('... in English, the gentleman the one who asked', C14,
          'Professor – a gentleman has asked him while we were in the house –, does the dog sleep?').

%% what the controls found
newspaper_bovalino_checks_3 :-
    nf_tr('Juan, en cambio, duerme.', spanish, italian, D1),
    check('a GUARD: a name before a comma in a statement is its subject, never who is spoken to -- read so, `duerme'' was a command, `Juan, invece, dormi''', D1,
          'Juan, invece, dorme.'),
    nf_tr('El hermano ve una casa grande y a veces cansada.', spanish, italian, D2),
    check('a GUARD: adverbs and an adjective after a coordinator inside a phrase are the phrase''s, and agree with its noun, where the phrase ended at `y'' and the adjective agreed with the subject', D2,
          'Il fratello vede una casa grande e talvolta stanca.'),
    nf_tr('Me puedo comer el pan.', spanish, english, D3),
    check('a modal with the first person''s reflexive on it is a modal still: no `to'' before its infinitive', D3,
          'I can eat the bread.'),
    nf_tr('È andata dalla casa.', italian, spanish, D4),
    check('the adjuncts before a subject after an intransitive verb never end on an article, which is the next phrase''s: `da la'' was a phrase of from with the pronoun her, and `casa'' the subject', D4,
          'Ha ido desde la casa.'),
    nf_tr('A mí me gusta el pan.', spanish, english, D5),
    check('a pronoun after `a'' that the clitic after it doubles is said once, where it was a phrase of `to'' as well', D5,
          'The bread pleases me.'),
    nf_tr('Il cane vede una casa grande, stanca del pane, ma anche molto stanca.', italian, spanish, D6),
    check('a coordinator, adverbs and an adjective after an aside''s comma are the same aside, and agree with its noun, where the adjective agreed with nobody: `pero también muy cansado'' of a house', D6,
          'El perro ve una casa grande, cansada del pan, pero también muy cansada.').

%% a small word in a name, a name with a hyphen and digits, a point inside a
%% word, a channel and its number, a town that begins with its article, a
%% name after a noun in small letters, a second aside, a reporting clause
%% after a quotation that closes on its word, an adverb before a
%% participle set off, a participle set off after an adjective with dashes
%% inside it, an adjective phrase between dashes, two verbs of one
%% relative clause, an adverb between a determiner and its noun, a count
%% and adjectives with no noun, an agent after adjuncts, either ... or
%% (1.8.19) ---------------------------------------------------------------

newspaper_puigbo :-
    section('a Spanish report into Italian: a small word in a name, a name with a hyphen and digits, a point inside a word, a channel and its number, a town that begins with its article, a name after a noun in small letters, a second aside, a reporting clause after a quotation that closes on its word, an adverb before a participle set off, a participle set off after an adjective, an adjective phrase between dashes, two verbs of one relative clause, an adverb between a determiner and its noun, a count and adjectives with no noun, an agent after adjuncts, either ... or'),
    newspaper_puigbo_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_puigbo_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_puigbo_checks_1, newspaper_puigbo_checks_2, newspaper_puigbo_checks_3, newspaper_puigbo_checks_4,
    reason_unlearn(italian), reason_unlearn(spanish).

newspaper_puigbo_lesson(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "queso" means "cheese". The feminine noun "casa" means "house". The feminine noun "salida" means "departure".
The noun "ministro" means "minister". "ministro" is a person. The noun "hermano" means "brother". "hermano" is a person.
The noun "editor" means "editor". "editor" is a person. "editores" is the plural of "editor".
The noun "grupo" means "group". The noun "canal" means "channel". "canales" is the plural of "canal".
The feminine noun "cadena" means "chain". The feminine noun "radio" means "radio". "radio" is feminine.
The noun "reparto" means "distribution". The feminine noun "licencia" means "licence".
The noun "mayo" means "may". "mayo" is a month.
The masculine adjective "nuevo" means "new". The masculine adjective "viejo" means "old".
The feminine adjective "nueva" means "new". "nuevas" is the plural of "nueva". The feminine adjective "vieja" means "old". "viejas" is the plural of "vieja".
The masculine adjective "próximo" means "next". The masculine adjective "grande" means "big". The feminine adjective "catalana" means "catalan".
The adverb "todavía" means "still". The adverb "recientemente" means "recently". The adverb "directamente" means "directly".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comido" is the participle of "come".
The verb "bebe" means "drinks". The verb "deja" means "leaves". "dejan" is the plural of "deja".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "sabe" means "knows". "sé" is the first person of "sabe". "sabe" takes the question.
The verb "continúa" means "continues". "continuará" is the future of "continúa".
The verb "limita" means "limits". "limitó" is the past of "limita". "limita" takes "a" before the infinitive.
The verb "contesta" means "answers". "contestar" is the infinitive of "contesta".
The verb "ficha" means "engages". "fichado" is the participle of "ficha".
The verb "capitanea" means "captains". "capitaneado" is the participle of "capitanea". "capitaneada" is the participle of "capitanea". "capitaneada" is feminine.
The verb "efectúa" means "effects". "efectuado" is the participle of "efectúa".
The adverb "bien" means "well". The adverb "tampoco" means "either". The masculine noun "bien" means "good".
The conjunction "y" means "and". The word "bien" begins the choice. The conjunction "o" means "or". The conjunction "o bien" means "or".
The conjunction "si" means "if". The conjunction "que" means "that". "que" is a relative.
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with".
The preposition "por" means "for". The preposition "por" means "by". The preposition "a principios de" means "at the start of".
The reflexive pronoun "se" means "itself". The impersonal pronoun "se" means "one".
The verb "conoce" means "knows". The pronoun "me" means "me".
The noun "parque" means "park". The masculine adjective "blindado" means "armoured". The verb "momifica" means "mummifies". "momificado" is the participle of "momifica".').

newspaper_puigbo_lesson(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i". "delle" is the contraction of "di le".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "al" is the contraction of "a il". "alla" is the contraction of "a la".
"dal" is the contraction of "da il". "dalla" is the contraction of "da la".
The article "lo" comes before a vowel. "l''" is the elision of "lo". "dello" is the contraction of "di lo". "dell''" is the elision of "dello".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane". The noun "formaggio" means "cheese".
The feminine noun "casa" means "house". "case" is the plural of "casa". The feminine noun "partenza" means "departure".
The noun "ministro" means "minister". "ministro" is a person. The noun "fratello" means "brother". "fratello" is a person.
The noun "redattore" means "editor". "redattore" is a person.
The noun "gruppo" means "group". The noun "canale" means "channel". "canali" is the plural of "canale".
The feminine noun "catena" means "chain". The feminine noun "radio" means "radio". "radio" is feminine.
The noun "riparto" means "distribution". The feminine noun "licenza" means "licence". "licenze" is the plural of "licenza".
The noun "maggio" means "may". "maggio" is a month.
The masculine adjective "nuovo" means "new". "nuovi" is the plural of "nuovo". The feminine adjective "nuova" means "new". "nuove" is the plural of "nuova".
The masculine adjective "vecchio" means "old". The feminine adjective "vecchia" means "old". "vecchie" is the plural of "vecchia".
The masculine adjective "prossimo" means "next". The adjective "grande" means "big". The feminine adjective "catalana" means "catalan".
The adverb "ancora" means "still". The adverb "recentemente" means "recently". The adverb "direttamente" means "directly".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangiato" is the participle of "mangia".
The verb "beve" means "drinks". The verb "lascia" means "leaves". "lasciano" is the plural of "lascia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "sa" means "knows". "so" is the first person of "sa". "sa" takes the question.
The verb "continua" means "continues". "continuerà" is the future of "continua".
The verb "limita" means "limits". "limitò" is the past of "limita". "limita" takes "a" before the infinitive.
The verb "risponde" means "answers". "rispondere" is the infinitive of "risponde".
The verb "ingaggia" means "engages". "ingaggiato" is the participle of "ingaggia".
The verb "capitana" means "captains". "capitanato" is the participle of "capitana". "capitanata" is the participle of "capitana". "capitanata" is feminine.
The verb "effettua" means "effects". "effettuato" is the participle of "effettua". "effettuata" is the participle of "effettua". "effettuata" is feminine.
"effettuati" is the participle of "effettua". "effettuati" is the plural of "effettuato". "effettuate" is the participle of "effettua". "effettuate" is feminine. "effettuate" is the plural of "effettuata".
The conjunction "e" means "and". The conjunction "o" means "either". The conjunction "o" means "or".
The conjunction "se" means "if". The conjunction "che" means "that". "che" is a relative.
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "con" means "with".
The preposition "per" means "for". The preposition "da" means "by". The preposition "agli inizi di" means "at the start of".
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".
The adverb "bene" means "well". The verb "conosce" means "knows". The pronoun "mi" means "me".
The noun "parco" means "park". The masculine adjective "blindato" means "armoured". The verb "mummifica" means "mummifies". "mummificato" is the participle of "mummifica".').

newspaper_puigbo_checks_1 :-
    %% a small word in a name
    nf_tr('El editor del Telenotícies migdia duerme.', spanish, italian, P1),
    check('a small word no lesson knows after an article and a name no lesson knows is the name''s: `del Telenotícies migdia'' names a news programme, and `migdia'' refused the sentence', P1,
          'Il redattore del Telenotícies migdia dorme.'),
    nf_tr('La salida de Omar del Telenotícies migdia duerme.', spanish, italian, P2),
    check('... and the contraction before it joins no name to the one before it: read as `Omar del Telenotícies'', one name, `migdia'' was left alone and the sentence refused', P2,
          'La partenza di Omar del Telenotícies migdia dorme.'),
    reason_untranslated('El editor del Telenotícies migdia pasea.', spanish, P2u),
    check('... and a refusal does not name the name''s word, only the word no lesson knows', P2u, [pasea]),
    %% a name with a hyphen and digits
    nf_tr('El perro de TV-3 duerme.', spanish, italian, P3),
    check('a name with a hyphen and digits is one name: `TV-3'' was the name `TV'' and a number below nought, and the sentence was refused', P3,
          'Il cane di TV-3 dorme.'),
    %% a point inside a word
    nf_tr('"Paral.lel continuará", se limitó a contestar Omar.', spanish, italian, P4),
    check('a point between two letters ends no sentence: `Paral.lel'' was cut there, and `lel'' was a word no lesson knows', P4,
          '"Paral.lel continuerà", si limitò a rispondere Omar.'),
    %% a channel and its number
    nf_tr('El perro de Canal 33 duerme.', spanish, italian, P5),
    check('a capitalised word with its number where no sentence begins is one name: `Canal 33'' was a channel and a count, with no article and no reading', P5,
          'Il cane di Canal 33 dorme.'),
    %% a town that begins with its article
    nf_tr('El perro duerme en Figueres, Gandesa y El Vendrell.', spanish, italian, P6),
    check('an article with its capital where no sentence begins, before a name, is the name''s: `Il Vendrell''', P6,
          'Il cane dorme in Figueres, Gandesa e El Vendrell.'),
    %% a name after a noun in small letters
    nf_tr('El perro duerme en la cadena de radio Ona Catalana.', spanish, italian, P7),
    check('a name of several words after a noun in small letters is the noun''s name, where `catalana'' is an adjective too and the phrase had no reading', P7,
          'Il cane dorme nella catena di radio Ona Catalana.').

newspaper_puigbo_checks_2 :-
    %% a second aside
    nf_tr('Omar, editor del grupo, hermano que come con Maria, duerme.', spanish, english, Q1),
    check('a second aside after the first is set off too: read as the clause''s own words the sentence was two pieces, the first with no verb and the second with nobody named, which English refuses -- and Italian writes the same words from either reading', Q1,
          'Omar, editor of the group, brother that eats with Maria, sleeps.'),
    %% a reporting clause after a quotation that closes on its word
    nf_tr('"No sé si el perro duerme", se limitó a contestar Omar.', spanish, english, Q2),
    check('after a quotation that closes on its last word, the reporting clause is read first: `se'' is the verb''s own and Omar who answered, where `se'' was the impersonal word and Omar what one answered; and the quotation is never divided at `si'', which was a condition', Q2,
          '"I do not know whether the dog sleeps", Omar limited to answer.'),
    %% an adverb after a front's comma, before the denial
    nf_tr('En la casa, todavía no sé si el perro duerme.', spanish, italian, Q3),
    check('an adverb after a front''s comma before the denial or the verb is the rest''s, and no front of its own: `Nella casa, ancora, non so''', Q3,
          'Nella casa, non so ancora se il cane dorme.'),
    %% an adverb before a participle set off
    nf_tr('Omar, recientemente fichado por el ministro, duerme.', spanish, italian, Q4),
    check('an adverb before a participle set off by commas is the participle''s, before it again: the commas were lost', Q4,
          'Omar, recentemente ingaggiato dal ministro, dorme.'),
    nf_tr('El perro ve a Omar, recientemente fichado por el ministro.', spanish, italian, Q5),
    check('... and at the end of the sentence, where the stop closes it: the agent was a phrase of `for''', Q5,
          'Il cane vede Omar, recentemente ingaggiato dal ministro.'),
    %% a participle set off after an adjective
    nf_tr('La casa grande, capitaneada por Omar, duerme.', spanish, italian, Q6),
    check('a participle with its agent set off after an adjective as after a noun: the commas were lost', Q6,
          'La casa grande, capitanata da Omar, dorme.'),
    %% an adjective phrase between dashes
    nf_tr('Omar - - próximo al ministro - - duerme.', spanish, italian, Q7),
    check('an adjective with its phrase between two dashes after a name is set off, where the sentence was refused with every word known', Q7,
          'Omar – prossimo al ministro – dorme.'),
    nf_tr('La cadena, capitaneada por Omar - - próximo al ministro - - y Maria, duerme.', spanish, italian, Q8),
    check('... inside a participle set off by commas, whose words have their own asides read first', Q8,
          'La catena, capitanata da Omar – prossimo al ministro – e Maria, dorme.').

newspaper_puigbo_checks_3 :-
    %% two verbs of one relative clause
    nf_tr('El perro que come y bebe duerme.', spanish, italian, R1),
    check('two verbs joined in one relative clause share its gap and its subject, where the clause ended at `y'' and the sentence was refused', R1,
          'Il cane che mangia e beve dorme.'),
    nf_tr('El perro ve el pan que comen y dejan los gatos.', spanish, english, R2),
    check('... and its subject after them, which the verbs'' number says: `that they eat and leave the cats''', R2,
          'The dog sees the bread that the cats eat and leave.'),
    %% an adverb between a determiner and its noun
    nf_tr('El grupo del todavía editor duerme.', spanish, italian, R3),
    check('an adverb between a determiner and its noun says when the noun holds, and stays before it, where it went to the end of the clause', R3,
          'Il gruppo dell''ancora redattore dorme.'),
    nf_tr('El grupo del todavía editor duerme.', spanish, english, R4),
    check('... in English too', R4, 'The group of the still editor sleeps.'),
    %% a count and adjectives with no noun
    nf_tr('El perro ve las 33 casas (21 nuevas y 12 viejas).', spanish, english, R5),
    check('a count and adjectives with no noun are a phrase whose noun was left out, where `nuevas'' was the noun and the bracket had no reading', R5,
          'The dog sees the 33 houses (21 new ones and 12 old ones).'),
    %% an agent after adjuncts, past a bracket
    nf_tr('El perro ve el reparto de las licencias (21 nuevas) efectuado a principios de mayo por el ministro.', spanish, italian, R6),
    check('a participle''s agent may come after adjuncts, and past a bracket the participle keeps its own gender and number: `(21 nuovi) effettuate ... per il ministro''', R6,
          'Il cane vede il riparto delle licenze (21 nuove) effettuato agli inizi di maggio dal ministro.'),
    nf_tr('El perro ve el pan comido en mayo por el gato.', spanish, italian, R7),
    check('... the agent after one adjunct, where it was a phrase of `for''', R7,
          'Il cane vede il pane mangiato in maggio dal gatto.'),
    %% either ... or
    nf_tr('El perro come bien el pan o bien el queso.', spanish, italian, R8),
    check('`bien'' before a choice with `o bien'' after it is either, where the sentence was refused', R8,
          'Il cane mangia o il pane o il formaggio.'),
    nf_tr('El perro come, bien directamente o bien con el gato, el pan.', spanish, english, R9),
    check('... and an adverb that is the first choice stays in it in English', R9,
          'The dog eats, either directly or with the cat, the bread.').

%% what the controls found
newspaper_puigbo_checks_4 :-
    nf_tr('El perro me conoce bien.', spanish, english, T1),
    check('a GUARD: `bien'' begins a choice and means none: said as `The conjunction "bien" means "either".'', either was a meaning of the adverb too -- `tampoco'' means it and is an adverb and nothing else, where `bien'' is a noun too and `well'' has no such word -- and `Él me conoce bien.'' came out `He knows me either.''', T1,
          'The dog knows me well.'),
    nf_tr('El perro ve un parque "blindado", "momificado", con el gato.', spanish, italian, T2),
    check('a GUARD: a participle alone after an adjective is one more of a list, and keeps its quotation marks: set off as an aside after `blindado'' it lost them', T2,
          'Il cane vede un parco "blindato", "mummificato", con il gatto.').

%% a headline noun spelled like a verb, a byline, a title with its name, a
%% count set off after a name, an example after a closing dash, who says so
%% with the place it was said at, the copula that is no comment, a comment
%% that opens on a coordinator, a relative clause joined to what was said of
%% an object, adjuncts between dashes, an interjection, a question after a
%% colon, a main clause at its subject's article, a denial before its verb,
%% an intransitive infinitive's subject after it, an infinitive with its
%% pronoun as a subject, a noun that takes the clause, less, the one at, chi
%% after a preposition, in modo da, a modal and the copula's infinitive, a
%% count of digits and a word, a number that is no noun, a question that is
%% no command (1.8.20) -----------------------------------------------------

newspaper_salvini :-
    section('an Italian interview into Spanish: a headline noun spelled like a verb, a byline, a title with its name, a count set off after a name, an example after a closing dash, who says so and where, the copula that is no comment, a comment that opens on a coordinator, a relative clause joined after an object, adjuncts between dashes, an interjection, a question after a colon, a denial before its verb, less, the one at, chi after a preposition, in modo da, a question that is no command'),
    newspaper_salvini_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_salvini_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_salvini_checks_1, newspaper_salvini_checks_2, newspaper_salvini_checks_3,
    newspaper_salvini_checks_4,
    reason_unlearn(italian), reason_unlearn(spanish).

%% each lesson in two parts, because a clause over a page (8 KB) cannot be
%% stored, and together they come near one
newspaper_salvini_lesson(L, Text) :-
    newspaper_salvini_part(L, 1, A), newspaper_salvini_part(L, 2, B), newspaper_salvini_part(L, 3, C),
    atomic_list_concat([A, ' ', B, ' ', C], Text).

newspaper_salvini_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person. The word "de" begins the clause.
The word "para" begins the purpose. The mark "¿" begins the question.
The word "el" replaces the noun. The word "lo" replaces the noun.
The word "más" begins the comparative. The adverb "más" means "more". The adverb "menos" means "less". The conjunction "que" means "than".
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house".
The noun "ministro" means "minister". "ministro" is a person. The noun "ministerio" means "ministry".
The noun "director" means "manager". "director" is a person.
The feminine noun "tasa" means "tax". "tasas" is the plural of "tasa".
The masculine adjective "caro" means "expensive". "caros" is the plural of "caro". The feminine adjective "cara" means "expensive". "caras" is the plural of "cara".
The masculine adjective "rico" means "rich". "ricos" is the plural of "rico".
The adjective "grande" means "big". "grandes" is the plural of "grande". The adjective "grave" means "grave".
The masculine adjective "cansado" means "tired". "cansados" is the plural of "cansado".
The masculine adjective "demasiado" means "too much". "demasiados" is the plural of "demasiado". The adverb "demasiado" means "too".
The noun "problema" means "problem". "problema" is not feminine. The noun "caso" means "case". "casos" is the plural of "caso".
The noun "aire" means "air". The noun "riesgo" means "risk". The noun "sur" means "south".
The feminine noun "universidad" means "university". "universidades" is the plural of "universidad".
The noun "viento" means "wind". "vientos" is the plural of "viento".
The number "veinte" means "twenty". The feminine noun "decena" means "ten". The number "decena" means "ten". The number "diez" means "ten".
The masculine noun "mil" means "thousand". "miles" is the plural of "mil". The number "mil" means "thousand".
The noun "año" means "year". The noun "credo" means "creed". The noun "importe" means "amount".
The noun "chico" means "lad". The noun "hincha" means "fan". "hinchas" is the plural of "hincha". "hincha" is not feminine.').

newspaper_salvini_part(spanish, 2, 'The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "coma" is the subjunctive of "come".
"comemos" is the first person of "comen". "comed" is the imperative of "comen".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "ve" means "sees". "ven" is the plural of "ve". "ver" is the infinitive of "ve". "visto" is the participle of "ve".
The verb "mira" means "looks". "miraba" is the past of "mira".
The verb "lava" means "washes". "lavar" is the infinitive of "lava".
The verb "cuesta" means "costs". "cuestan" is the plural of "cuesta". "costar" is the infinitive of "cuesta".
The verb "comienza" means "begins". "comienzan" is the plural of "comienza".
The verb "llega" means "arrives". "llegan" is the plural of "llega". "llegar" is the infinitive of "llega".
The verb "aclara" means "clarifies". "aclaran" is the plural of "aclara".
The verb "cree" means "believes". "creo" is the first person of "cree".
The verb "piensa" means "thinks". "piensan" is the plural of "piensa". "penséis" is the negative imperative of "piensan". "pensad" is the imperative of "piensan".
The verb "hincha" means "inflates". "hinchan" is the plural of "hincha". "hinchas" is the second person of "hincha".
The verb "trae" means "brings". "traído" is the participle of "trae". "traídos" is the plural of "traído". "traídos" is the participle of "trae".
The verb "es" means "is". "son" is the plural of "es". "somos" is the first person of "son". "soy" is the first person of "es". "ser" is the infinitive of "es".
The auxiliary "está" means "is". "estoy" is the first person of "está". The auxiliary "está" marks the state.
The modal "puede" means "can". "pueden" is the plural of "puede". "puedo" is the first person of "puede". "pueda" is the subjunctive of "puede". "poder" is the infinitive of "puede".
The auxiliary "ha" means "has". "han" is the plural of "ha". "habéis" is the second person of "han". "he" is the first person of "ha".
The verb "tiene" means "has".
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "que" means "that". "que" is a relative.
The conjunction "mientras" means "while". The conjunction "si" means "if". The conjunction "como si" means "as if".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "para" means "for".
The preposition "entre" means "among". The preposition "con" means "with". The preposition "desde" means "from". The preposition "dentro de" means "inside".
The preposition "como" means "like". The preposition "como" means "as".
The adverb "en cambio" means "instead". The adverb "al menos" means "at least". The adverb "por ejemplo" means "for example".
The adverb "mejor" means "better". The adverb "siempre" means "always". The adverb "bien" means "well". The adverb "mucho" means "much".
The masculine determiner "algún" means "some". "algunos" is the plural of "algún".
The pronoun "me" means "me". The pronoun "lo" means "it". The pronoun "nosotros" means "we". The pronoun "nosotros" does not precede the verb.
The reflexive pronoun "se" means "itself". The impersonal pronoun "se" means "one".
The interjection "ah" means "ah".').

%% ... and what the controls needed: `la' the pronoun as well as the
%% article, `loro' the possessive and the pronoun, a superlative, and a
%% participle that is an adjective too -- each as the vocabulary states it,
%% because a small lesson reproduces a fault only when it gives the word
%% every role the vocabulary does. (The word for `very' is `assai' here:
%% `molto' is `much' first in this lesson, for `costano molto', where the
%% vocabulary has it `very' first and writes `cuestan muy'.)
newspaper_salvini_part(italian, 3, 'The pronoun "la" means "her". The possessive "loro" means "their". The pronoun "loro" means "them". The pronoun "loro" does not precede the verb.
The adverb "assai" means "very". "grandissime" is the superlative of "grandi".
The verb "proibisce" means "forbids". "proibiscono" is the plural of "proibisce". "proibito" is the participle of "proibisce". "proibita" is the participle of "proibisce". "proibita" is feminine. "proibiti" is the participle of "proibisce". "proibiti" is the plural of "proibito". "proibite" is the participle of "proibisce". "proibite" is feminine. "proibite" is the plural of "proibita". "proibite" is the imperative of "proibiscono".
The masculine adjective "proibito" means "forbidden". "proibiti" is the plural of "proibito". The feminine adjective "proibita" means "forbidden". "proibite" is the plural of "proibita".').
newspaper_salvini_part(spanish, 3, 'The possessive "su" means "their". "sus" is the plural of "su". The adverb "muy" means "very".
The verb "prohíbe" means "forbids". "prohíben" is the plural of "prohíbe". "prohibido" is the participle of "prohíbe". "prohibida" is the participle of "prohíbe". "prohibida" is feminine. "prohibidos" is the participle of "prohíbe". "prohibidos" is the plural of "prohibido". "prohibidas" is the participle of "prohíbe". "prohibidas" is feminine. "prohibidas" is the plural of "prohibida".').


newspaper_salvini_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
"l''" is the elision of "il". "l''" is the elision of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i". "delle" is the contraction of "di le".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "al" is the contraction of "a il". "alla" is the contraction of "a la". "ai" is the contraction of "a i".
"all''" is the elision of "alla". "dell''" is the elision of "della". "dalla" is the contraction of "da la". "dal" is the contraction of "da il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not". The word "per" begins the purpose. The word "in modo da" begins the purpose.
The word "più" begins the comparative. The adverb "più" means "more". The adverb "meno" means "less". The adverb "di più" means "more".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane". The feminine noun "casa" means "house". "case" is the plural of "casa".
The noun "ministro" means "minister". "ministro" is a person. "ministri" is the plural of "ministro". The noun "ministero" means "ministry".
The noun "responsabile" means "manager". "responsabili" is the plural of "responsabile". "responsabile" is a person.
The feminine noun "tassa" means "tax". "tasse" is the plural of "tassa". The verb "tassa" means "taxes". "tassano" is the plural of "tassa".
The masculine adjective "caro" means "expensive". "cari" is the plural of "caro". The feminine adjective "cara" means "expensive". "care" is the plural of "cara".
The masculine adjective "ricco" means "rich". "ricchi" is the plural of "ricco".
The adjective "grande" means "big". "grandi" is the plural of "grande". The adjective "grave" means "grave".
The masculine adjective "stanco" means "tired". "stanchi" is the plural of "stanco".
The masculine adjective "troppo" means "too much". "troppi" is the plural of "troppo". The adverb "troppo" means "too".
The noun "problema" means "problem". "problema" is not feminine. The noun "caso" means "case". "casi" is the plural of "caso".
The feminine noun "aria" means "air". The noun "rischio" means "risk". "rischio" takes the clause.
The feminine noun "università" means "university". "università" is the plural of "università". The noun "sud" means "south".
The noun "vento" means "wind". "venti" is the plural of "vento".
The number "venti" means "twenty". The number "dieci" means "ten". The number "mila" means "thousand".
The noun "anno" means "year". "anni" is the plural of "anno". The noun "credo" means "creed". "credi" is the plural of "credo".
The noun "importo" means "amount".
The noun "ragazzo" means "lad". "ragazzi" is the plural of "ragazzo". The noun "appassionato" means "fan". "appassionati" is the plural of "appassionato".').

newspaper_salvini_part(italian, 2, 'The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangi" is the subjunctive of "mangia".
"mangiamo" is the first person of "mangiano". "mangiate" is the imperative of "mangiano".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme". "dorma" is the subjunctive of "dorme".
The verb "vede" means "sees". "vedono" is the plural of "vede". "vedere" is the infinitive of "vede". "visto" is the participle of "vede".
The verb "guarda" means "looks". "guardasse" is the past subjunctive of "guarda".
The verb "lava" means "washes". "lavare" is the infinitive of "lava".
The feminine noun "costa" means "coast". The verb "costa" means "costs". "costano" is the plural of "costa". "costare" is the infinitive of "costa".
The verb "comincia" means "begins". "cominciano" is the plural of "comincia".
The intransitive verb "arriva" means "arrives". "arrivano" is the plural of "arriva". "arrivare" is the infinitive of "arriva". "è" is the auxiliary of "arriva".
The verb "precisa" means "clarifies". "precisano" is the plural of "precisa". "precisa" takes the clause.
The verb "crede" means "believes". "credo" is the first person of "crede". "crede" takes the clause.
The verb "pensa" means "thinks". "pensano" is the plural of "pensa". "pensate" is the imperative of "pensano". "pensate" is the participle of "pensa". "pensate" is feminine. "pensa" takes the clause.
The verb "importa" means "matters". "importo" is the first person of "importa".
The verb "porta" means "brings". "portato" is the participle of "porta". "portati" is the plural of "portato". "portati" is the participle of "porta". "brought" is the participle of "brings".
The verb "è" means "is". "sono" is the plural of "è". "sono" is the first person of "è". "siamo" is the first person of "sono". "essere" is the infinitive of "è".
The modal "può" means "can". "possono" is the plural of "può". "posso" is the first person of "può". "possa" is the subjunctive of "può". "potere" is the infinitive of "può". "poter" is the infinitive of "può".
The auxiliary "ha" means "has". The verb "ha" means "has". "hanno" is the plural of "ha". "avete" is the second person of "hanno". "ho" is the first person of "ha". "seen" is the participle of "sees".
The conjunction "e" means "and". The conjunction "ed" means "and". The conjunction "ma" means "but". The conjunction "che" means "that". "che" is a relative. The conjunction "che" means "than".
The conjunction "mentre" means "while". The adverb "mentre" means "while". The conjunction "se" means "if". The conjunction "come se" means "as if".
The word "chi" means "who". The word "chi" begins the relative. The word "quello" replaces the noun. The pronoun "quello" means "that". The pronoun "quello" does not precede the verb.
The masculine demonstrative "quello" means "that". "quelli" is the plural of "quello".
The word "come" means "how". The preposition "come" means "like". The preposition "come" means "as".
The preposition "a" means "to". The preposition "ad" means "to". The preposition "di" means "of". "d''" is the elision of "di". The preposition "in" means "in".
The preposition "per" means "for". The preposition "tra" means "among". The preposition "con" means "with". The preposition "da" means "from". The preposition "dentro" means "inside".
The adverb "invece" means "instead". The adverb "almeno" means "at least". The adverb "per esempio" means "for example". The adverb "meglio" means "better".
The adverb "sempre" means "always". The adverb "bene" means "well". "ben" is the apocope of "bene". The adverb "molto" means "much".
The masculine pronoun "alcuno" means "some". "alcuni" is the plural of "alcuno". The pronoun "alcuno" does not precede the verb.
The pronoun "mi" means "me". The pronoun "lo" means "it". The dative pronoun "le" means "her". The pronoun "noi" means "we". The pronoun "noi" does not precede the verb.
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".
The interjection "ah" means "ah".').

%% a headline, a byline, who is spoken to, and what is set off inside a sentence
newspaper_salvini_checks_1 :-
    nf_tr('Tasse più care per mangiare meglio.', italian, spanish, S1),
    check('a headline that opens on a bare plural noun spelled like a verb is the noun first, with its purpose after it: `"tasse più care per studiare meglio"'', where `tasse'' read through the noun''s plural was a verb, THEY tax, and the headline was refused', S1,
          'Tasas más caras para comer mejor.'),
    nf_tr('Di Mario Rossi Roma - il cane dorme.', italian, spanish, S2),
    check('a byline: the preposition of `of'', a name, the place''s word and a dash before the sentence, written back as it stood, where the sentence was refused', S2,
          'De Mario Rossi Roma – el perro duerme.'),
    nf_tr('Ministro Rossi, il cane dorme?', italian, spanish, S3),
    check('a title and a name before a comma are who is spoken to, and the question is the clause after them: the minister was the question''s subject, with a comma before his verb', S3,
          'Ministro Rossi, ¿el perro duerme?'),
    nf_tr('Mario Rossi, 75 anni ben portati, dorme.', italian, spanish, S4),
    check('a count of four words set off after a NAME is its aside, as after a noun: read as the clause''s own, the years were the subject and the verb was plural, `duermen''', S4,
          'Mario Rossi, 75 años bien traídos, duerme.'),
    nf_tr('Mario Rossi, responsabile del ministero, 75 anni ben portati, dorme.', italian, english, S5),
    check('... and after another aside, whose closing comma opens it: read as a clause of its own, the name and its aside were no subject, and English refused a verb with nobody named', S5,
          'Mario Rossi, manager of the ministry, 75 years well brought, sleeps.'),
    nf_tr('I cani - precisano al ministero - per esempio quelli di Roma, mangiano il pane.', italian, spanish, S6),
    check('an example after a closing dash, to its comma, is an aside, and a verb that reports with the place it was said at is who says so, written after the sentence as 1.6.21 writes a reporting clause -- the sentence was refused', S6,
          'Los perros, por ejemplo los de Roma, comen el pan – aclaran al ministerio –.'),
    reason_ir('I cani - precisano al ministero - dormono.', italian, R7),
    yes_no(R7 = [ir(join(dashes, _, s(none, null(third, plural), g(clarifies, _, _, _), [pp(_, _)])), _)], S7),
    check('... and the dashes hold a reporting clause of the third person plural with nobody named, where they held a clause said OF the dogs, app/3', S7, yes),
    nf_tr('Sono troppi.', italian, spanish, S8),
    check('a predicate adjective the lesson knows only in the plural says the copula is the plural too: `sono'' is I am as well, and it came out `Soy demasiado''', S8,
          'Son demasiados.'),
    reason_ir('Il cane dorme, sono stanco, ma il gatto mangia.', italian, R9),
    yes_no(R9 = [ir(join(comma, join(comma, _, s(none, null(first, singular), g(is, _, _, _), _)), _), _)], S9),
    check('the copula between two commas is a clause of the sentence''s own, never the writer''s comment (w(Key, comment)): `in un certo senso sono troppi, sono d''accordo, ma ...''', S9, yes),
    reason_ir('Il cane mangia, ed è un problema grave, il pane.', italian, R10),
    yes_no(R10 = [ir(s(_, _, g(eats, _, _, _), [comment(clause(_)), obj(np(_, _, _, w(bread, _), _))]), _)], S10),
    check('a clause that opens on a coordinator and its verb, set between two commas, is a comment on the clause it interrupts, and the phrase after it is the verb''s object: read as a clause of its own, the bread was a second object of `è''', S10, yes),
    nf_tr('Il cane vede un gatto grande e che mangia il pane.', italian, spanish, S11),
    check('a relative clause joined by `e'' to what was said of an object, `un problema grave e che mi tormenta'', where the sentence was refused', S11,
          'El perro ve un gato grande y que come el pan.'),
    nf_tr('Il cane mangia il pane - almeno in alcuni casi - ma il gatto dorme.', italian, spanish, S12),
    check('adjuncts between two dashes and no verb are an aside of the phrase before them, written back between their dashes, where the sentence was refused', S12,
          'El perro come el pan – al menos en algunos casos – pero el gato duerme.'),
    reason_ir('Ah, il cane dorme.', italian, R13),
    yes_no(R13 = [ir(join(comma, gap([], [ans(_)]), _), _)], S13),
    check('an interjection before a comma stands where an answer does, `The interjection "ah" means "ah".'': it was a topic, a bare noun `ah''', S13, yes).

%% clauses: where they divide, what they deny, and who they are about
newspaper_salvini_checks_2 :-
    nf_tr('Il cane: avete visto il gatto?', italian, spanish, T1),
    check('a question after a heading and a colon is the second side, and its opening mark goes there, where the heading was asked', T1,
          'El perro: ¿habéis visto el gato?'),
    nf_tr('Il cane: avete visto il gatto?', italian, english, T2),
    check('... and English''s `you'' is the plural too, where English wrote nothing', T2,
          'The dog: have you seen the cat?'),
    nf_tr('Se il cane mangia il pane il gatto dorme.', italian, english, T3),
    check('a subordinate clause at the head with no comma ends before its main clause''s article too, not only before a verb: the cat was the bread''s, and English refused a verb with nobody named', T3,
          'If the dog eats the bread the cat sleeps.'),
    nf_tr('Credo che il cane dorma ma non posso vederlo.', italian, spanish, T4),
    check('a denial stands before the verb it denies: `ma non posso garantirlo'' denied the FIRST verb, `No creo que el perro duerme pero puedo verlo'', the claim turned round', T4,
          'Creo que el perro duerme pero no puedo verlo.'),
    nf_tr('Cominciano ad arrivare i cani.', italian, english, T5),
    check('a verb before `a'' and an infinitive the lesson calls intransitive has the phrase after them for its subject: the dogs were what they began to make arrive', T5,
          'The dogs begin to arrive.'),
    nf_tr('Mangiarlo è bene.', italian, spanish, T6),
    check('an infinitive with its pronoun joined is a subject, the pronoun its own, `discuterne ne è bene'', where the sentence was refused', T6,
          'Comerlo es bien.'),
    nf_tr('Lavarsi è bene.', italian, spanish, T7),
    check('... and with its reflexive joined, `dove iscriversi costava''', T7,
          'Lavarse es bien.'),
    nf_tr('Il cane vede il rischio che il gatto dorma.', italian, spanish, T8),
    check('a noun the lesson says takes the clause (`"rischio" takes the clause.'') has its own after `che'' where the clause''s subject stands first: it was a relative clause, the risk that the cat sleeps', T8,
          'El perro ve el riesgo de que el gato duerme.'),
    nf_tr('Al sud l''università costa meno e non credo possa costare di più.', italian, spanish, T9),
    check('a noun and then the verb that agrees with it are a subject and its verb, never a coast university: with `credo'' a creed too, the subject ran on and the sentence was refused', T9,
          'La universidad cuesta menos al sur y no creo que puede costar más.'),
    nf_tr('Il problema è che mentre il cane dorme noi mangiamo.', italian, spanish, T10),
    check('a subordinate clause at the head of a clause of `che'', its main clause after it with no comma, and `noi'' before a first person verb is we, never the object pronoun `us'': the sentence was refused', T10,
          'El problema es que mientras el perro duerme nosotros comemos.'),
    nf_tr('Sono stanco, ma non pensate che il cane dorma.', italian, spanish, T11),
    check('a denied command after a coordinator, where no statement can share the subject before it: `non'' was an adverb of the participle `pensate'', and the sentence was refused', T11,
          'Soy cansado, pero no penséis que el perro duerme.'),
    nf_tr('Il cane dorme come se il gatto guardasse.', italian, english, T12),
    check('English writes `as if'' as a connector, where it refused the sentence', T12,
          'The dog sleeps as if the cat looked.'),
    nf_tr('Mangiate il pane?', italian, spanish, T13),
    check('a question is no command: `mangiate'' is the form of no person the lesson states but the command, and `¿Comed el pan?'' was wrong where a refusal is not', T13,
          refused).

%% phrases: less, the one at, chi, and the numbers
newspaper_salvini_checks_3 :-
    nf_tr('I meno ricchi dormono.', italian, spanish, U1),
    check('the lesson''s word for `less'' before an adjective is its degree, as its word for `more'' is: it was an adverb of the verb, `Los ricos duermen menos''', U1,
          'Los menos ricos duermen.'),
    nf_tr('I meno ricchi dormono.', italian, english, U2),
    check('... and English writes `least'' and no `ones'' after it, where it wrote `The rich ones sleep less''', U2,
          'The least rich sleep.'),
    nf_tr('Il pane costa meno che quello al cane.', italian, spanish, U3),
    check('after the word for `than'', a word that replaces the noun takes any preposition as its own, and Spanish writes it word for word, `el al'', a stated cost: it was the pronoun `that'', `que que al perro''', U3,
          'El pan cuesta menos que el al perro.'),
    nf_tr('Il cane ha l''aria di chi dorme.', italian, spanish, U4),
    check('`chi'' after a preposition is the one who, as after a verb, where the sentence was refused', U4,
          'El perro tiene el aire del que duerme.'),
    nf_tr('Il gatto che sempre mangia il pane dorme.', italian, spanish, U5),
    check('an adverb alone in front of a relative clause''s verb stays before it: written after the object it came out the verb''s last word, `come el pan siempre''', U5,
          'El gato que siempre come el pan duerme.'),
    nf_tr('Il cane mangia in modo da dormire.', italian, spanish, U6),
    check('a word of several words the lesson states only as beginning the purpose is one word, `in modo da'', where the sentence was refused', U6,
          'El perro come para dormir.'),
    nf_tr('Il cane mangia in modo da poter dormire.', italian, english, U7),
    check('... and English''s `can'' has no base form: `to be able'', where English refused `to can''', U7,
          'The dog eats to be able to sleep.'),
    nf_tr('Può essere grande la casa del cane.', italian, english, U8),
    check('a modal before the copula''s infinitive, a predicate and then a phrase that agrees with the modal: the phrase is the subject, where English had nobody to say it of', U8,
          'The house of the dog can be big.'),
    nf_tr('Il cane ha 200 mila pani.', italian, spanish, U9),
    check('digits and a number word are one count: `mila'' was an adjective of the noun and came out `miles''', U9,
          'El perro tiene 200 mil panes.'),
    nf_tr('Il cane mangia tra i dieci e i venti pani.', italian, spanish, U10),
    check('a number is no noun after an article, and crosses by the word the lesson calls a number and no noun: it was `los decena y los vientos panes'', the winds', U10,
          'El perro come entre los diez y los veinte panes.'),
    nf_tr('Le università costano molto.', italian, spanish, U11),
    check('an invariable noun takes its number from the determiner''s reading as one: `le'' is the dative `her'' too, a singular, and the sentence was refused', U11,
          'Las universidades cuestan mucho.'),
    nf_tr('Il cane è visto dalla casa come importo per i gatti.', italian, spanish, U12),
    check('`come'' before a phrase with only adjuncts after it is `as'', never `how'' with a clause: `importo'' is I matter too, and the sentence was refused', U12,
          'El perro es visto desde la casa como importe para los gatos.'),
    nf_tr('Il caso più grave quello del cane.', italian, spanish, U13),
    check('a phrase and the one that says which, the copula left out between them as a headline leaves it out, where the sentence was refused', U13,
          'El caso más grave el del perro.'),
    nf_tr('In alcuni casi dentro la casa.', italian, spanish, U14),
    check('a line of adjuncts alone, two at least and a preposition''s phrase first, where it was refused', U14,
          'En algunos casos dentro de la casa.'),
    nf_tr('Il cane è all''1,4.', italian, spanish, U15),
    check('an elided article before a number keeps its apostrophe, where `all'' was a word no lesson knows', U15,
          'El perro es al 1,4.'),
    nf_tr('Los chicos hinchas duermen.', spanish, italian, U16),
    check('a GUARD: a noun after a noun in the plural says what kind though its singular is a verb''s form too -- the rule that a noun and the verb that agrees with it are a subject and its verb asks the singular only, and asked of every known word, as its first cut did, it refused this', U16,
          'I ragazzi appassionati dormono.').

%% what the controls found, each on its own words
newspaper_salvini_checks_4 :-
    nf_tr('Il cane vede le loro case.', italian, spanish, V1),
    check('an article before a possessive is the article: `le'' is the dative `her'' too, and `i medici stanno valutando le loro condizioni'' came out `le están evaluando sus condiciones''', V1,
          'El perro ve sus casas.'),
    nf_tr('Il cane dorme con la loro casa.', italian, spanish, V2),
    check('... and after a preposition, where `la'' was the pronoun `her'' on 1.8.19 too: `desde ella sus funciones''', V2,
          'El perro duerme con su casa.'),
    nf_tr('Il cane dorme con le grandissime case.', italian, spanish, V3),
    check('... and before the word for `very'' and an adjective, a superlative the tokeniser unfolded: `con ella muy pesadas acusaciones''', V3,
          'El perro duerme con las casas muy grandes.'),
    nf_tr('I cani sono stanchi: dormono, mangiano, dormono.', italian, spanish, V4),
    check('a GUARD: a verb between two commas with no speaker is a reporting clause only in the singular -- widened to either number, `ridono, scherzano, raccontano'' wrote `scherzano'' last', V4,
          'Los perros son cansados: duermen, comen, duermen.'),
    nf_tr('Il cane crede che il gatto dorme e mentre il pane costa, il gatto mangia.', italian, spanish, V5),
    check('a GUARD: a subordinate clause at the head of a clause of `che'' keeps the comma before its main clause, which a nested clause is read without', V5,
          'El perro cree que el gato duerme y mientras el pan cuesta, el gato come.'),
    nf_tr('Case proibite ai cani.', italian, spanish, V6),
    check('a GUARD: a headline''s bare plural noun and a PARTICIPLE after it is the headline participle''s (1.8.4), never the noun and an adjective: `Auto proibite nelle isole del sole.'' was refused, `forbidden'' being no adjective Spanish has', V6,
          'Casas prohibidas a los perros.').

newspaper_radio :-
    section('a Spanish report into Italian: an ordinal, a list whose items have phrases of their own, parts set off by semicolons, a sentence that is the list alone, a heading with all, both ... and, there was after an insertion, a quotation that opens on a participle, a relative clause set off in the first of two subjects, two bare plurals joined, all before a bare plural, a quoted run no lesson knows, titles in a bracket, even, two insertions after a relative word, a time with its own infinitive, the person set off again, a name after a name, a pronoun that is a person, a demonstrative''s apocope, an elision by the last word of several, a purpose after an aside'),
    newspaper_radio_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_radio_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_radio_checks_1, newspaper_radio_checks_2, newspaper_radio_checks_3, newspaper_radio_checks_4,
    newspaper_radio_checks_5,
    reason_unlearn(italian), reason_unlearn(spanish).

%% each lesson in two parts, because a clause over a page (8 KB) cannot be
%% stored
newspaper_radio_lesson(L, Text) :-
    newspaper_radio_part(L, 1, A), newspaper_radio_part(L, 2, B), atomic_list_concat([A, ' ', B], Text).

newspaper_radio_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "queso" means "cheese". The feminine noun "casa" means "house".
The noun "ministro" means "minister". "ministro" is a person. The noun "hermano" means "brother". "hermano" is a person.
The noun "amigo" means "friend". "amigo" is a person. The noun "hombre" means "man". "hombre" is a person.
The feminine noun "voz" means "voice". "voces" is the plural of "voz". "voz" is feminine.
The feminine noun "estrella" means "star". The feminine noun "onda" means "wave".
The noun "político" means "politician". "político" is a person.
The noun "deportista" means "sportsman". "deportista" is not feminine. "deportista" is a person.
The noun "artista" means "artist". "artista" is not feminine. "artista" is a person.
The noun "centro" means "centre". The feminine noun "dirección" means "direction". "direcciones" is the plural of "dirección".
The noun "aniversario" means "anniversary". The noun "momento" means "moment". "momento" is a time.
The noun "personaje" means "character". "personaje" is a person.
The feminine noun "proeza" means "exploit". The noun "desliz" means "slip". The noun "anuncio" means "ad".
The feminine noun "canción" means "song". "canciones" is the plural of "canción". "canción" is feminine.
The feminine noun "señal" means "signal". "señal" is feminine. The feminine noun "amistad" means "friendship". "amistad" is feminine.
The noun "antecesor" means "predecessor". "antecesor" is a person. The noun "martes" means "tuesday". "martes" is a time.
The noun "nieve" means "snow". "nieves" is the plural of "nieve". The noun "herrero" means "smith". "herrero" is a person.
The masculine noun "alto" means "height". The masculine adjective "alto" means "high".
The masculine noun "ejecutivo" means "executive". "ejecutivo" is a person. The masculine adjective "ejecutivo" means "executive".').

newspaper_radio_part(spanish, 2, 'The adverb "hoy" means "today". The adverb "ayer" means "yesterday". The masculine noun "ayer" means "yesterday". "ayer" is a time.
The intransitive verb "marca época" means "makes history". "marcó época" is the past of "marca época".
The preposition "hasta" means "until". The adverb "hasta" means "even". The adverb "entonces" means "then". The adverb "sin embargo" means "however". The adverb "también" means "also".
The conjunction "tanto" means "both". "como" is the partner of "tanto".
The preposition "como" means "like". The preposition "además de" means "besides". The preposition "así como" means "just like".
The masculine pronoun "éste" means "this". The pronoun "éste" does not precede the verb.
The feminine pronoun "toda" means "everything". "todas" is the plural of "toda". The pronoun "toda" does not precede the verb.
The masculine pronoun "todo" means "all". The feminine pronoun "toda" means "all".
The pronoun "otros muchos" means "many others". The pronoun "otros muchos" does not precede the verb. "otros muchos" is a person.
The demonstrative "ese" means "that". "esos" is the plural of "ese". The adjective "medio" means "half".
The masculine noun "medio de comunicación" means "mass medium". "medios de comunicación" is the plural of "medio de comunicación". The masculine noun "medio" means "medium".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comió" is the past of "come". "comieron" is the past of "comen".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "durmió" is the past of "duerme". "durmieron" is the past of "duermen".
The verb "ve" means "sees". "ven" is the plural of "ve". "vio" is the past of "ve". "ver" is the infinitive of "ve".
The verb "viene" means "comes". The verb "celebra" means "celebrates". "celebrar" is the infinitive of "celebra".
The verb "canta" means "sings". The verb "representa" means "represents". "representan" is the plural of "representa".
The verb "homenajea" means "honours". "homenajear" is the infinitive of "homenajea".
The verb "reúne" means "gathers". "reúnen" is the plural of "reúne". "reunió" is the past of "reúne". "reunieron" is the past of "reúnen".
The verb "asegura" means "ensures". "aseguró" is the past of "asegura". "asegura" takes the clause.
The verb "prepara" means "prepares". "preparado" is the participle of "prepara". "preparados" is the participle of "prepara". "preparados" is the plural of "preparado".
The verb "es" means "is". "son" is the plural of "es". "fue" is the past of "es".
The auxiliary "ha" means "has". "sido" is the participle of "es". "ha" is the auxiliary of "es".
The auxiliary "está" means "is". "están" is the plural of "está". The auxiliary "está" marks the state.
The verb "hay" means "there is". "hay" is the plural of "hay". "había" is the past of "hay". "hubo" is the past of "hay".
The conjunction "y" means "and". The conjunction "o" means "or". The conjunction "que" means "that". "que" is a relative.
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with".
The preposition "por" means "for". The preposition "desde" means "from". The word "para" begins the purpose. The preposition "para" means "for".
The intransitive verb "para" means "stops". The verb "para" means "stops".
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".
The number "dos" means "two".
The verb "envía" means "sends". "enviar" is the infinitive of "envía". The noun "orden" means "order". "órdenes" is the plural of "orden".
The verb "comparece" means "appears". "comparecer" is the infinitive of "comparece". The verb "habla" means "speaks". "hablar" is the infinitive of "habla".
The noun "equipo" means "team". The noun "campeón" means "champion". "campeón" is a person.').

newspaper_radio_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i". "delle" is the contraction of "di le".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "al" is the contraction of "a il". "alla" is the contraction of "a la".
"allo" is the contraction of "a lo". "dal" is the contraction of "da il".
The article "lo" comes before a vowel. The article "lo" comes before "sc". "l''" is the elision of "lo". "all''" is the elision of "allo".
The article "il" takes the year. "d''" is the elision of "di".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane". The noun "formaggio" means "cheese". The feminine noun "casa" means "house".
The noun "ministro" means "minister". "ministri" is the plural of "ministro". "ministro" is a person.
The noun "fratello" means "brother". "fratelli" is the plural of "fratello". "fratello" is a person.
The noun "amico" means "friend". "amico" is a person. The noun "uomo" means "man". "uomo" is a person.
The feminine noun "voce" means "voice". "voci" is the plural of "voce". "voce" is feminine.
The feminine noun "stella" means "star". "stelle" is the plural of "stella". The feminine noun "onda" means "wave". "onde" is the plural of "onda".
The noun "politico" means "politician". "politici" is the plural of "politico". "politico" is a person.
The noun "sportivo" means "sportsman". "sportivi" is the plural of "sportivo". "sportivo" is a person.
The noun "artista" means "artist". "artisti" is the plural of "artista". "artista" is not feminine. "artista" is a person.
The noun "centro" means "centre". The feminine noun "direzione" means "direction". "direzioni" is the plural of "direzione". "direzione" is feminine.
The noun "anniversario" means "anniversary". The noun "momento" means "moment". "momento" is a time.
The noun "personaggio" means "character". "personaggi" is the plural of "personaggio". "personaggio" is a person.
The feminine noun "prodezza" means "exploit". The feminine noun "scivolata" means "slip". The noun "annuncio" means "ad". "annunci" is the plural of "annuncio".
The feminine noun "canzone" means "song". "canzoni" is the plural of "canzone". "canzone" is feminine.
The noun "segnale" means "signal". The feminine noun "amicizia" means "friendship".
The noun "antenato" means "predecessor". "antenato" is a person. The noun "martedì" means "tuesday". "martedì" is a time.
The feminine noun "neve" means "snow". "nevi" is the plural of "neve". "neve" is feminine. The noun "fabbro" means "smith". "fabbro" is a person.
The adjective "alto" means "high". "alti" is the plural of "alto".
The noun "esecutivo" means "executive". "esecutivi" is the plural of "esecutivo". "esecutivo" is a person.').

newspaper_radio_part(italian, 2, 'The adverb "oggi" means "today". The adverb "ieri" means "yesterday". The masculine noun "ieri" means "yesterday". "ieri" is a time.
The intransitive verb "fa epoca" means "makes history". "fece epoca" is the past of "fa epoca".
The adverb "persino" means "even". The preposition "fino a" means "until". The adverb "allora" means "then". The adverb "però" means "however". The adverb "anche" means "also".
The conjunction "tanto" means "both". "quanto" is the partner of "tanto".
The preposition "come" means "like". The preposition "oltre a" means "besides". The preposition "così come" means "just like".
The pronoun "questo" means "this". The pronoun "questo" does not precede the verb. "quest''" is the elision of "questo".
The feminine pronoun "tutta" means "everything". "tutte" is the plural of "tutta". The pronoun "tutta" does not precede the verb.
The masculine pronoun "tutto" means "all". The feminine pronoun "tutta" means "all".
The pronoun "molti altri" means "many others". The pronoun "molti altri" does not precede the verb.
The demonstrative "quello" means "that". "quel" is the apocope of "quello". "quei" is the plural of "quel". The adjective "mezzo" means "half".
The masculine noun "mezzo di comunicazione" means "mass medium". "mezzi di comunicazione" is the plural of "mezzo di comunicazione". The masculine noun "mezzo" means "medium". "mezzi" is the plural of "mezzo".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangiò" is the past of "mangia". "mangiarono" is the past of "mangiano".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormì" is the past of "dorme". "dormirono" is the past of "dormono".
The verb "vede" means "sees". "vedono" is the plural of "vede". "vide" is the past of "vede". "vedere" is the infinitive of "vede".
The verb "viene" means "comes". The verb "celebra" means "celebrates". "celebrare" is the infinitive of "celebra".
The verb "canta" means "sings". The verb "rappresenta" means "represents". "rappresentano" is the plural of "rappresenta".
The verb "onora" means "honours". "onorare" is the infinitive of "onora".
The verb "riunisce" means "gathers". "riuniscono" is the plural of "riunisce". "riunì" is the past of "riunisce". "riunirono" is the past of "riuniscono".
The verb "assicura" means "ensures". "assicurò" is the past of "assicura". "assicura" takes the clause.
The verb "prepara" means "prepares". "preparato" is the participle of "prepara". "preparati" is the participle of "prepara". "preparati" is the plural of "preparato".
The verb "è" means "is". "sono" is the plural of "è". "fu" is the past of "è". "è" is the auxiliary of "è". "stato" is the participle of "è".
The verb "c''è" means "there is". "ci sono" is the plural of "c''è". "c''era" is the past of "c''è".
The conjunction "e" means "and". The conjunction "o" means "or". The conjunction "che" means "that". "che" is a relative.
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "con" means "with".
The preposition "da" means "from". The preposition "per" means "for". The word "per" begins the purpose.
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".
The number "due" means "two".
The verb "spedisce" means "sends". "spedire" is the infinitive of "spedisce". The noun "ordine" means "order". "ordini" is the plural of "ordine".
The verb "figura" means "appears". "figurare" is the infinitive of "figura". The verb "parla" means "speaks". "parlare" is the infinitive of "parla".
The feminine noun "squadra" means "team". The noun "campione" means "champion". "campione" is a person.
The masculine adjective "nuovo" means "new". The feminine adjective "nuova" means "new".').

newspaper_radio_checks_1 :-
    nf_tr('El perro celebra el 50º aniversario.', spanish, italian, R1),
    check('an ordinal is one word with its sign: the tokeniser dropped the `º'', and the fiftieth anniversary was `il 50 anniversario''', R1,
          'Il cane celebra il 50º anniversario.'),
    nf_tr('El perro celebra el 50º aniversario.', spanish, english, R2),
    check('... and English writes its own suffix', R2, 'The dog celebrates the 50th anniversary.'),
    nf_tr('Voces de un ayer que marcó época y estrellas de las ondas se reunieron.', spanish, italian, R3),
    check('two halves that open on a bare plural noun are two things, a preposition in the first or not; and a relative clause of one verb that takes nothing after it is closed', R3,
          'Voci d''un ieri che fece epoca e stelle delle onde si riunirono.'),
    nf_tr('Estrellas de hoy, políticos de ese centro, deportistas y artistas se reunieron.', spanish, italian, R4),
    check('a comma before an item of a list whose later commas are the list''s is one too, when the words on either side are a subject''s phrase: `de hoy políticos'' was of politicians', R4,
          'Stelle d''oggi, politici di quel centro, sportivi e artisti si riunirono.'),
    nf_tr('Políticos que comen pan, deportistas y artistas se reunieron.', spanish, italian, R5),
    check('a list''s own comma closes a relative clause: the clause ran on, and the sportsmen and the artists were what the politicians eat', R5,
          'Politici che mangiano pane, sportivi e artisti si riunirono.'),
    nf_tr('El perro viene desde todas direcciones.', spanish, italian, R6),
    check('a word that means `all'' before a bare plural noun is the phrase''s: read as the pronoun standing alone, it was from everything, `da tutto direzioni''', R6,
          'Il cane viene da tutte direzioni.'),
    nf_tr('Toda una proeza, tanto por el pan como por el queso.', spanish, italian, R7),
    check('a heading with all, and both ... and: `tanto'' was the determiner `so much'' and `como'' the preposition `like''', R7,
          'Tutta una prodezza, tanto per il pane quanto per il formaggio.'),
    nf_tr('Toda una proeza, tanto por el pan como por el queso.', spanish, english, R8),
    check('... and English''s own pair', R8, 'All an exploit, both for the bread and for the cheese.'),
    nf_tr('Hubo, sin embargo, un desliz.', spanish, italian, R9),
    check('there was, after an insertion between two commas: read with nobody named for its subject, `C''erano''', R9,
          'C''era, però, una scivolata.'),
    nf_tr('Hubo, sin embargo, un desliz.', spanish, english, R10),
    check('... and English writes the insertion where it stood', R10, 'There was, however, a slip.').

newspaper_radio_checks_2 :-
    nf_tr('El ministro aseguró que los perros están "preparados para la casa".', spanish, italian, Q1),
    check('a quotation that opens on a passive''s participle keeps its mark there', Q1,
          'Il ministro assicurò che i cani sono "preparati per la casa".'),
    nf_tr('Omar, que comió el pan, y Maria duermen.', spanish, italian, Q2),
    check('a relative clause set off in the first of two subjects keeps its commas, and the two are the plural''s subject: read with the commas out it was one man, `dorme''', Q2,
          'Omar, che mangiò il pane, e Maria dormono.'),
    nf_tr('El perro canta el "ja sóc aquí" de Omar.', spanish, italian, Q3),
    check('a quoted run with a word no lesson knows stands where the noun goes, and is written back word for word', Q3,
          'Il cane canta il "ja sóc aquí" d''Omar.'),
    nf_tr('El perro canta canciones (De España para todos, Elena Francis, Fantasía...) y hasta anuncios (Telefunken, La Lechera).', spanish, italian, Q4),
    check('titles in a bracket are written as they stood, points and all; and `hasta'' before a bare noun after a coordinator is even', Q4,
          'Il cane canta canzoni (De España para todos, Elena Francis, Fantasía...) e persino annunci (Telefunken, La Lechera).'),
    nf_tr('El perro vio al ministro que, en 1974, como señal de amistad, comió el pan.', spanish, italian, Q5),
    check('two insertions after a relative word, and a year after `que'' is no aside of it', Q5,
          'Il cane vide il ministro che, nel 1974, come segnale d''amicizia, mangiò il pane.'),
    nf_tr('Fue el momento de homenajear a dos personajes, Omar y Juan.', spanish, italian, Q6),
    check('a time with its own infinitive is a thing named, what follows the infinitive is its own, and the names set off after the person are the person again: `onorare a due''', Q6,
          'Fu il momento d''onorare due personaggi, Omar e Juan.'),
    nf_tr('El perro ve a Omar Pérez y Nieves Herrero.', spanish, italian, Q7),
    check('after a name and a coordinator a run of capitalised words is a name too: `nieves'' is snows and `herrero'' a smith to the lesson', Q7,
          'Il cane vede Omar Pérez e Nieves Herrero.'),
    nf_tr('Omar ve a dos "hermanos que representan a otros muchos".', spanish, italian, Q8),
    check('a word of several words may close a quotation on its last word, and a pronoun is of the class the lesson says its word is of: `"otros muchos" is a person.'', so the word before a person goes with it -- `a molti altri''', Q8,
          'Omar vede due "fratelli che rappresentano molti altri".').

newspaper_radio_checks_3 :-
    nf_tr('El perro come ese medio pan.', spanish, italian, P1),
    check('a demonstrative before its noun loses its ending where the article does: `quello mezzo pane''', P1,
          'Il cane mangia quel mezzo pane.'),
    nf_tr('El perro duerme además del amigo.', spanish, italian, P2),
    check('a word of several words elides by its last word: `oltre allo amico''', P2,
          'Il cane dorme oltre all''amico.'),
    nf_tr('El perro ve al amigo de éste en Roma.', spanish, italian, P3),
    check('no elision before a preposition, which opens another phrase: `di quest''in Roma''', P3,
          'Il cane vede l''amico di questo in Roma.'),
    nf_tr('El hombre que duerme se reunió.', spanish, english, P4),
    check('a clitic heads no phrase, and a subject ends on no reflexive: read as the phrase `one'', the reflexive was what the man sleeps, and over the vocabulary Italian wrote `L''uomo che dorme uno adunò''', P4,
          'The man that sleeps gathered.'),
    nf_tr('Los perros que comen pan se reunieron el martes, en la casa, para comer.', spanish, italian, P5),
    check('an aside before a purpose is no aside of a clause whose verb comes next: `para'' is also what `parar'' says', P5,
          'I cani che mangiano pane si riunirono il martedì, nella casa, per mangiare.'),
    nf_tr('El perro vio a Omar; el ministro de la casa, Juan Pérez; el gato y el hermano de Maria.', spanish, italian, P6),
    check('parts set off by semicolons carry a list on, and an apposition a semicolon closes is the phrase''s: read with the semicolons taken out, the people after the first were objects of their own', P6,
          'Il cane vide Omar; il ministro della casa, Juan Pérez; il gatto e il fratello di Maria.'),
    nf_tr('Los altos ejecutivos duermen.', spanish, italian, P8),
    check('among nouns that are all adjectives too, the one the lesson calls a person is the head: `alto'' is a height and `ejecutivo'' an executive, and by position the height was the head', P8,
          'Gli alti esecutivi dormono.'),
    nf_tr('También ministros como Omar; hermanos de la casa como Juan; así como el ministro Luis.', spanish, italian, P7),
    check('a sentence may be the list alone, going on from the one before', P7,
          'Anche ministri come Omar; fratelli della casa come Juan; così come il ministro Luis.').

%% what the controls found, each red on the first cut of 1.8.21 and green on
%% 1.8.20: the rules of this section asked of sentences they were not written
%% for
newspaper_radio_checks_4 :-
    nf_tr('El perro envía órdenes de comparecer al ministro.', spanish, italian, G1),
    check('GUARD: under a verb that is no copula, the person after a noun''s `de'' and its infinitive stays the verb''s: `enviar órdenes de comparecer al director'' sends them TO the director, and read as the infinitive''s object he was who appeared, `figurare il direttore''', G1,
          'Il cane spedisce ordini di figurare al ministro.'),
    nf_tr('El ministro ve a los hermanos por hablar de comer el pan.', spanish, italian, G2),
    check('GUARD: after a preposition and its infinitive the object already counted still counts: `por hablar ahora de ampliar la investigación'' was refused, `de'' with no object before it', G2,
          'Il ministro vede i fratelli per parlare di mangiare il pane.'),
    nf_tr('Omar, el hermano que ve los perros, los gatos y los panes, duerme.', spanish, italian, G3),
    check('GUARD: a comma before an item is a list''s only where the item opens on a bare plural noun: the list after `el hermano'' is its relative clause''s, and taken for the subject''s Omar and the brother were two, `dormono''', G3,
          'Omar, il fratello che vede i cani, i gatti e i pani, dorme.'),
    nf_tr('Il cane vede la nuova squadra campione.', italian, english, G4),
    check('GUARD: the person heads a phrase only among nouns that are ALL adjectives too: `il miglioramento didattico universitario giurisprudenza medicina'' made the person the head, and Spanish marked it as a person object; here the champion was the head and the team its adjective, `the new team champion''', G4,
          'The dog sees the new champion team.').

%% THE LINES A SAMPLE ADDS HAVE TWO READERS, AND THE DATA COLUMN FOUND THREE:
%% 1.8.20's own translator, over the store this report's lines were taught
%% into, wrote old sentences worse. Each guard below is red on the lesson as
%% 1.8.21 had it and green on the vocabulary's order now.
newspaper_radio_checks_5 :-
    nf_tr('El perro duerme hasta el martes.', spanish, italian, D1),
    check('GUARD: `hasta'' is `until'' before it is `even'': with the adverb''s line first every `hasta'' crossed as `even'', and `caerá hasta un 4%'' came out `cadrà persino un 4%''', D1,
          'Il cane dorme fino al martedì.'),
    nf_tr('Hasta entonces el perro duerme.', spanish, italian, D6),
    check('GUARD: and a word that is a preposition too is the preposition before an adverb: lifted as the adverb `even'' before `entonces'', `pero hasta entonces mantendrá'' came out `persino allora''', D6,
          'Il cane dorme fino a allora.'),
    nf_tr('Ieri è stato preparato il pane.', italian, english, D2),
    check('GUARD: `ieri'' is a noun for `un ieri'' and a TIME, so with no article it is no subject: `Ieri è stato inoltre approvato il documento'' read `Yesterday has been approved the document''', D2,
          'The bread has been prepared yesterday.'),
    nf_tr('Ayer ha sido preparado el pan.', spanish, english, D3),
    check('GUARD: and `ayer'' the same way', D3,
          'The bread has been prepared yesterday.'),
    nf_tr('I mezzi dormono.', italian, spanish, D4),
    check('GUARD: `medios de comunicación'' means `mass medium'', which no other word means: meaning `medium'' it came first for it, and `con oltre 50 mezzi'' came out `con más de 50 medios de comunicación''', D4,
          'Los medios duermen.'),
    nf_tr('Los medios de comunicación duermen.', spanish, italian, D5),
    check('and the media are still the media', D5,
          'I mezzi di comunicazione dormono.').

newspaper_fregene :-
    section('an Italian report into Spanish: a byline, a name in quotation marks, a noun alone before its verb, a phrase set off after a name, a bracket that opens on a preposition, adjectives after their noun with commas, a name after the last comma of a clause and between two clauses, a degree adverb before a participle, a gender the subject does not give, an adjective with its intensifier in front, a time and a connecting adverb in front, a quotation that opens and does not close, a bare noun before a clause of another person, an intensified adjective or participle alone, adjectives before a name, why, what after a verb that takes the question, a heading of phrases, a denial between a noun and its adjective, not only ... but, a joined relative, as, as when, a comparison of infinitives, so little, so much before a noun, a relative clause''s participle, everyone'),
    newspaper_fregene_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_fregene_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_fregene_checks_1, newspaper_fregene_checks_2, newspaper_fregene_checks_3, newspaper_fregene_checks_4,
    newspaper_fregene_checks_5, newspaper_fregene_checks_6, newspaper_fregene_checks_7,
    reason_unlearn(italian), reason_unlearn(spanish).

%% each lesson in four parts, because a clause over a page (8 KB) cannot be
%% stored. What the vocabulary gives a word, the lesson gives it too: `anche'
%% is also the plural of `anca', `le' also the dative `her', `alto' also a
%% height and the adverb `high', `contro' also the noun `con' -- without
%% those the old translator reads the sentences right by luck, and a check
%% could not tell the two apart
newspaper_fregene_lesson(L, Text) :-
    newspaper_fregene_part(L, 1, A), newspaper_fregene_part(L, 2, B), newspaper_fregene_part(L, 3, C),
    newspaper_fregene_part(L, 4, D),
    atomic_list_concat([A, ' ', B, ' ', C, ' ', D], Text).

newspaper_fregene_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The noun "hombre" means "man". "hombre" is a person.
The noun "padre" means "father". "padre" is a person. The noun "madre" means "mother". "madre" is feminine. "madre" is a person.
The feminine noun "mujer" means "woman". "mujer" is feminine. "mujer" is a person.
The noun "día" means "day". "día" is not feminine. "día" is a time.
The noun "motivo" means "reason". The noun "coraje" means "courage". The noun "peso" means "weight".
The noun "dolor" means "pain". "dolores" is the plural of "dolor".
The feminine noun "acusación" means "accusation". "acusaciones" is the plural of "acusación". "acusación" is feminine.
The feminine noun "tragedia" means "tragedy". The feminine noun "piscina" means "pool".
The noun "establecimiento" means "establishment". The noun "espejismo" means "mirage".
The feminine noun "indagación" means "inquiry". "indagación" is feminine.
The noun "médico" means "doctor". "médico" is a person. The noun "resultado" means "result".
The feminine noun "autopsia" means "autopsy".
The noun "artista" means "artist". "artista" is not feminine. "artista" is a person.
The noun "periodista" means "journalist". "periodista" is not feminine. "periodista" is a person.
The feminine noun "crítica" means "critic". "crítica" is a person.
The feminine noun "causa" means "cause". The feminine noun "lira" means "lira".
The noun "socorrista" means "lifeguard". "socorrista" is not feminine. "socorrista" is a person.
The feminine noun "cabeza" means "head". The feminine noun "cruz" means "cross". "cruz" is feminine. "cruces" is the plural of "cruz".
The noun "sol" means "sun". "soles" is the plural of "sol". The feminine noun "hora" means "hour". "hora" is a time.
The noun "gemelo" means "twin". "gemelo" is a person. The feminine noun "margarita" means "daisy".
The noun "belio" means "bel". The noun "joven" means "junior". "jóvenes" is the plural of "joven". "joven" is a person.
The masculine noun "desconocido" means "unknown". "desconocidos" is the plural of "desconocido".').

newspaper_fregene_part(spanish, 2, 'The masculine adjective "alto" means "tall". The masculine adjective "esbelto" means "slender". The masculine adjective "oscuro" means "dark".
The masculine adjective "bello" means "beautiful". The feminine adjective "bella" means "beautiful".
The masculine adjective "seguro" means "sure". The feminine adjective "segura" means "sure".
The masculine adjective "bueno" means "good". The adjective "indiferente" means "indifferent".
The masculine adjective "ocupado" means "busy". "ocupados" is the plural of "ocupado".
The adjective "pobre" means "poor". The adjective "joven" means "young".
The masculine adjective "desconocido" means "unknown". The masculine adjective "máximo" means "greatest".
The adverb "así" means "thus". The adverb "tan" means "so". The adverb "muy" means "very". The adverb "poco" means "little".
The adverb "sólo" means "only". The masculine adjective "solo" means "alone". The adverb "también" means "also".
The adverb "entonces" means "then". The adverb "de todos modos" means "anyway". The adverb "más" means "more".
The adverb "generalmente" means "generally". The adverb "hoy" means "today".
The masculine determiner "tanto" means "so much". The adverb "tanto" means "so much".
"sino" is the partner of "sólo".
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "que" means "that". "que" is a relative.
The word "más" begins the comparative. The conjunction "que" means "than". The mark "¿" begins the question. The word "qué" means "what".
The conjunction "si" means "if". The conjunction "porque" means "because". The word "por qué" means "why".
The conjunction "claro que" means "of course". The conjunction "así que" means "so". The conjunction "o mejor dicho" means "or rather".
The word "cuándo" means "when". The conjunction "cuando" means "when". The word "cómo" means "how". The preposition "como" means "as".
The pronoun "yo" means "I". The pronoun "él" means "he". The pronoun "él" means "him". The pronoun "él" does not precede the verb.
The pronoun "ellos" means "they". The pronoun "ellos" does not precede the verb.
The pronoun "todos" means "everyone". "todos" is the plural of "todo". The pronoun "todos" does not precede the verb.
The pronoun "nadie" means "nobody". The pronoun "nadie" does not precede the verb.
The pronoun "lo" means "him". The pronoun "lo" means "it".
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "desde" means "from".
The preposition "por" means "by". The preposition "para" means "for". The preposition "contra" means "against". The preposition "sobre" means "on".').

newspaper_fregene_part(spanish, 3, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comes" is the second person of "come".
The verb "ve" means "sees". "ven" is the plural of "ve". The verb "lee" means "reads".
The verb "es" means "is". "son" is the plural of "es". "será" is the future of "es". "soy" is the first person of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha". "he" is the first person of "ha". "habéis" is the second person of "han".
"sido" is the participle of "es". "ha" is the auxiliary of "es".
The verb "tiene" means "has".
The verb "hay" means "there is". "habrá" is the future of "hay".
The verb "hace" means "makes". "hecho" is the participle of "hace".
The verb "dice" means "says". The verb "pide" means "asks". The verb "hurga" means "rummages". "hurga" is the imperative of "hurga".
The verb "tira" means "throws". "tira" is the imperative of "tira".
The verb "entiende" means "understands". "entendido" is the participle of "entiende". "entiende" takes the question.
The intransitive verb "pasa" means "happens". "pasado" is the participle of "pasa".
The verb "dura" means "lasts". "durado" is the participle of "dura".
The verb "ama" means "loves". "amado" is the participle of "ama". "amada" is the participle of "ama". "amada" is feminine.
The verb "bautiza" means "baptises". "bautizado" is the participle of "bautiza". "bautizada" is the participle of "bautiza". "bautizada" is feminine.
The verb "sabe" means "knows". "sabido" is the participle of "sabe".
The transitive verb "conoce" means "knows". "conocido" is the participle of "conoce".
The verb "vende" means "sells". "vendido" is the participle of "vende". "vendida" is the participle of "vende". "vendida" is feminine.
The verb "quiere" means "wants". "quiero" is the first person of "quiere".
The verb "habla" means "speaks". "hablo" is the first person of "habla".
The verb "va" means "goes". "vamos" is the first person of "van". "van" is the plural of "va".
The verb "escribe" means "writes". "escrito" is the participle of "escribe".
The verb "mira" means "watches". "mirar" is the infinitive of "mira".
The verb "enamora" means "enamours". "enamora" is reflexive.
The verb "abre" means "opens". "abierto" is the participle of "abre". "abierta" is the participle of "abre". "abierta" is feminine.
The verb "efectúa" means "effects". "efectuado" is the participle of "efectúa". "efectuada" is the participle of "efectúa". "efectuada" is feminine.
The verb "nada" means "swims".
The verb "ocupa" means "occupies". "ocupado" is the participle of "ocupa". "ocupados" is the participle of "ocupa".').

newspaper_fregene_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i". "delle" is the contraction of "di le".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "al" is the contraction of "a il". "alla" is the contraction of "a la".
"dal" is the contraction of "da il". "sul" is the contraction of "su il". "sulla" is the contraction of "su la".
The article "lo" comes before a vowel. The article "lo" comes before "st".
"l''" is the elision of "lo". "l''" is the elision of "la". "dell''" is the elision of "della". "d''" is the elision of "di".
"s''" is the elision of "si". "cos''" is the elision of "cosa".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not". The adverb "non" means "not".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". The noun "pane" means "bread".
The feminine noun "casa" means "house". The noun "uomo" means "man". "uomo" is a person.
The noun "padre" means "father". "padre" is a person. The noun "madre" means "mother". "madre" is feminine. "madre" is a person.
The feminine noun "donna" means "woman". "donna" is a person.
The noun "giorno" means "day". "giorno" is a time. The noun "motivo" means "reason".
The noun "coraggio" means "courage". The noun "peso" means "weight". The noun "dolore" means "pain".
The feminine noun "accusa" means "accusation". "accuse" is the plural of "accusa".
The feminine noun "tragedia" means "tragedy". The feminine noun "piscina" means "pool".
The noun "stabilimento" means "establishment". The noun "miraggio" means "mirage".
The feminine noun "inchiesta" means "inquiry". The noun "medico" means "doctor". "medico" is a person.
The noun "risultato" means "result". "risultati" is the plural of "risultato". The feminine noun "autopsia" means "autopsy".
The noun "artista" means "artist". "artista" is not feminine. "artista" is a person.
The noun "giornalista" means "journalist". "giornalista" is not feminine. "giornalista" is a person.
The feminine noun "critica" means "critic". "critica" is a person. The feminine adjective "critica" means "critical".
The feminine noun "causa" means "cause". The feminine noun "lira" means "lira".
The noun "bagnino" means "lifeguard". "bagnino" is a person.
The feminine noun "testa" means "head". The feminine noun "croce" means "cross". "croce" is feminine.
The noun "sole" means "sun". The feminine noun "ora" means "hour". "ore" is the plural of "ora". "ora" is a time.
The noun "gemello" means "twin". "gemelli" is the plural of "gemello". "gemello" is a person.
The feminine noun "margherita" means "daisy".
The noun "bel" means "bel". "bel" is the apocope of "bello".
The noun "giovane" means "junior". "giovani" is the plural of "giovane". "giovane" is a person.
The preposition "contro" means "against". The masculine noun "contro" means "con".
"cui" is a relative. The word "cui" follows the preposition.
The masculine noun "luglio" means "july". "lugli" is the plural of "luglio". "luglio" is a month.').

newspaper_fregene_part(italian, 2, 'The masculine noun "alto" means "height". The masculine adjective "alto" means "tall". The adverb "alto" means "high". The masculine adjective "snello" means "slender". The masculine adjective "scuro" means "dark".
The masculine adjective "bello" means "beautiful". The feminine adjective "bella" means "beautiful".
The masculine adjective "sicuro" means "sure". The feminine adjective "sicura" means "sure".
The masculine adjective "buono" means "good". The adjective "indifferente" means "indifferent".
The masculine adjective "occupato" means "busy". "occupati" is the plural of "occupato".
The masculine adjective "povero" means "poor". The feminine adjective "povera" means "poor".
The adjective "giovane" means "young". "giovanissima" is the superlative of "giovane".
The masculine adjective "ignoto" means "unknown". "ignoti" is the plural of "ignoto".
The masculine adjective "massimo" means "greatest".
The adverb "così" means "thus". The adverb "così" means "so". The adverb "molto" means "very". The adverb "poco" means "little".
The adverb "solo" means "only". The masculine adjective "solo" means "alone".
The adverb "anche" means "also". The feminine noun "anca" means "hip". "anche" is the plural of "anca".
The adverb "poi" means "then". The adverb "comunque" means "anyway". The adverb "più" means "more".
The adverb "in genere" means "generally". The adverb "oggi" means "today".
The masculine determiner "tanto" means "so much". The adverb "tanto" means "as".
The conjunction "e" means "and". The conjunction "ma" means "but". The conjunction "che" means "that". "che" is a relative.
The word "più" begins the comparative. The conjunction "che" means "than".
The conjunction "se" means "if". The conjunction "perché" means "because". The word "perché" means "why".
The conjunction "certo che" means "of course". The conjunction "per cui" means "so". The conjunction "o meglio" means "or rather".
The word "quando" means "when". The word "come" means "how". The preposition "come" means "as".
The word "cosa" means "what". The feminine noun "cosa" means "thing".
The pronoun "io" means "I". The pronoun "lui" means "he". The pronoun "lui" means "him". The pronoun "lui" does not precede the verb.
The pronoun "loro" means "they". The pronoun "loro" means "them". The pronoun "loro" does not precede the verb. The dative pronoun "loro" means "them". The possessive "loro" means "their".
The pronoun "tutti" means "everyone". "tutti" is the plural of "tutto". The pronoun "tutti" does not precede the verb.
The pronoun "nessuno" means "nobody". The pronoun "nessuno" does not precede the verb.
The pronoun "lo" means "him". The pronoun "lo" means "it". The dative pronoun "le" means "her".
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "da" means "from".
The preposition "da" means "by". The preposition "per" means "for". The preposition "su" means "on". The word "per" begins the purpose.').

newspaper_fregene_part(italian, 3, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangi" is the second person of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede". The verb "legge" means "reads".
The verb "è" means "is". "sono" is the plural of "è". "sarà" is the future of "è". "sono" is the first person of "è".
"stato" is the participle of "è". "stata" is the participle of "è". "stata" is feminine. "è" is the auxiliary of "è".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "ho" is the first person of "ha". "avete" is the second person of "hanno".
The verb "ha" means "has".
The verb "c''è" means "there is". "ci sarà" is the future of "c''è".
The verb "fa" means "makes". "fatto" is the participle of "fa".
The verb "dice" means "says". The verb "chiede" means "asks". The verb "fruga" means "rummages". "fruga" is the imperative of "fruga".
The verb "butta" means "throws". "butta" is the imperative of "butta".
The verb "capisce" means "understands". "capito" is the participle of "capisce". "capisce" takes the question.
The intransitive verb "succede" means "happens". "successo" is the participle of "succede". "è" is the auxiliary of "succede".
The verb "dura" means "lasts". "durata" is the participle of "dura". "durata" is feminine. "durato" is the participle of "dura". "è" is the auxiliary of "dura".
The verb "ama" means "loves". "amato" is the participle of "ama". "amata" is the participle of "ama". "amata" is feminine.
The verb "battezza" means "baptises". "battezzato" is the participle of "battezza". "battezzata" is the participle of "battezza". "battezzata" is feminine.
The verb "conosce" means "knows". "conosciuto" is the participle of "conosce".
The verb "vende" means "sells". "venduto" is the participle of "vende". "venduta" is the participle of "vende". "venduta" is feminine.
The verb "vuole" means "wants". "voglio" is the first person of "vuole".
The verb "parla" means "speaks". "parlo" is the first person of "parla".
The verb "va" means "goes". "vanno" is the plural of "va". "andiamo" is the first person of "vanno".
The verb "scrive" means "writes". "scritto" is the participle of "scrive".
The verb "guarda" means "watches". "guardare" is the infinitive of "guarda".
The verb "innamora" means "enamours". "innamora" is reflexive.
The verb "apre" means "opens". "aperto" is the participle of "apre". "aperta" is the participle of "apre". "aperta" is feminine.
The verb "effettua" means "effects". "effettuato" is the participle of "effettua". "effettuata" is the participle of "effettua". "effettuata" is feminine.
The verb "nuota" means "swims". The verb "usa" means "uses". The verb "testa" means "tests". "testa" is the imperative of "testa".
The verb "accusa" means "accuses". "accusano" is the plural of "accusa".
The verb "critica" means "criticises".
The verb "occupa" means "occupies". "occupato" is the participle of "occupa". "occupati" is the participle of "occupa".
The verb "risulta" means "results". "risultato" is the participle of "risulta". "risultati" is the participle of "risulta".').


%% what the controls found, in the vocabulary's words and order: `tate' the
%% babysitters, `margherita' a name the lesson says it is, `talvolta' before
%% `a volte', `resta' said to take no object and not a meaning of it, `ellos'
%% no pronoun before its verb (part 2 above)
newspaper_fregene_part(spanish, 4, 'The adverb "a veces" means "sometimes".
The verb "queda" means "remains". "quedar" is the infinitive of "queda".
"saber" is the infinitive of "sabe".
The adjective "feliz" means "happy". The feminine noun "navidad" means "christmas".
The adjective "tal" means "such". The adverb "un poco" means "a bit".
The pronoun "ellos" means "them". The modal "puede" means "can". "pueden" is the plural of "puede".
The word "el" replaces the noun.
The masculine adjective "cansado" means "tired". The feminine adjective "cansada" means "tired".').

newspaper_fregene_part(italian, 4, 'The feminine noun "tata" means "babysitter". "tate" is the plural of "tata".
The verb "evacua" means "evacuates". "evacuato" is the participle of "evacua". "evacuata" is the participle of "evacua". "evacuata" is feminine.
"evacuate" is the participle of "evacua". "evacuate" is feminine. "evacuati" is the participle of "evacua". "evacuate" is the plural of "evacuata". "evacuati" is the plural of "evacuato".
"margherita" is a name.
The adverb "talvolta" means "sometimes". The adverb "a volte" means "sometimes".
The verb "resta" means "remains". The verb "resta" means "stays". "restare" is the infinitive of "resta". "resta" is intransitive.
The verb "sa" means "knows". "sapere" is the infinitive of "sa". "sa" takes the question.
The word "chi" means "who". The word "chi" begins the relative.
The masculine adjective "stanco" means "tired". The feminine adjective "stanca" means "tired".').

newspaper_fregene_checks_1 :-
    nf_tr('Di Massimo Lugli Roma - il cane dorme.', italian, spanish, F1),
    check('a byline''s name is every capitalised word between the head''s `of'' and the place: `massimo'' is the greatest and `lugli'' the plural of July to the lesson, and lowered as a month the surname refused the byline', F1,
          'De Massimo Lugli Roma – el perro duerme.'),
    nf_tr('Il cane mangia al "Gemelli".', italian, spanish, F2),
    check('one capitalised word in quotation marks where no sentence begins is a name, known or not: `al "Gemelli"'' is the hospital, and read as the word it was the twins, `a los "gemelos"''', F2,
          'El perro come al "Gemelli".'),
    nf_tr('Margherita non dorme.', italian, spanish, F3),
    check('a noun the lesson knows in the singular, alone before the word for `not'' or a verb, keeps its capital: `Margherita non sapeva nuotare'' is the girl, and lowered it was a daisy', F3,
          'Margherita no duerme.'),
    nf_tr('Il cane legge il "Sole 24 Ore".', italian, spanish, F4),
    check('a number may stand between the capitalised words of a quoted name: read as words the newspaper came out `el "sol 24 horas"''', F4,
          'El perro lee el "Sole 24 Ore".'),
    nf_tr('Cesare, il padre di Sofia, è un uomo alto.', italian, english, F5),
    check('a phrase with an article set off after a name, with the verb after its closing comma, is the name''s aside: read as a verbless piece and a clause the man was the subject after `è'', `a tall man is''', F5,
          'Cesare, the father of Sofia, is a tall man.'),
    nf_tr('Il cane dorme (contro ignoti).', italian, spanish, F6),
    check('a bracket that opens on a preposition is the preposition''s phrase: `contro'' is also the noun `con'', and read as a phrase first it had no Spanish', F6,
          'El perro duerme (contra desconocidos).'),
    nf_tr('"Il cane dorme" dice Carolyn, giornalista e critica.', italian, spanish, F7),
    check('after a name a list goes on in names or in phrases that open on a determiner, and two phrases joined after a speaker are the speaker''s: `dice Carolyn, giornalista e critica'' was a list of three, and refused', F7,
          '"El perro duerme" dice Carolyn, periodista y crítica.'),
    nf_tr('È un uomo alto, snello, scuro.', italian, spanish, F8),
    check('adjectives after their noun with commas between them are one list: `snello'' was a clause of its own, and the sentence was refused', F8,
          'Es un hombre alto, esbelto, oscuro.'),
    nf_tr('Un bel giorno il cane dorme.', italian, spanish, F9),
    check('an adjective crosses by the reading that IS an adjective: `bel'' is the apocope of `bello'' and the unit `bel'', whose meaning it crossed by first', F9,
          'El perro duerme un bello día.'),
    nf_tr('La casa è così bella.', italian, spanish, F10),
    check('an intensifier crosses by the meaning that says a degree: `così'' is `thus'' first, and before an adjective it is `so''', F10,
          'La casa es tan bella.').

newspaper_fregene_checks_2 :-
    nf_tr('Se ci sarà una causa non voglio una lira.', italian, spanish, G1),
    check('`there is'' has nobody for its subject, and a main clause may open on its denial: `se ci sarà una causa non voglio una lira'' took `non'' into the condition, which then said there would be none', G1,
          'Si habrá una causa no quiero una lira.'),
    nf_tr('Comunque se ci sarà una causa non voglio una lira.', italian, spanish, G2),
    check('a connecting adverb before a subordinate clause goes in front of the main clause: read as one clause the piece had two verbs, and was refused', G2,
          'Si habrá una causa de todos modos no quiero una lira.'),
    nf_tr('Non chiede il pane, Carolyn.', italian, spanish, G3),
    check('a name after the last comma of a clause whose subject nobody named is that subject, set at the end: read as an object it took the word before a person, `a Carolyn''', G3,
          'No pide el pan, Carolyn.'),
    nf_tr('Non chiede il pane, Carolyn.', italian, english, G4),
    check('... and English puts it first, and the comma goes with it', G4,
          'Carolyn does not ask the bread.'),
    nf_tr('Dormono loro.', italian, english, G5),
    check('... and `loro'' last after the verb is they: read as the dative it was `to them'', and English said `They sleep them.'' (Spanish writes `Duermen ellos.'' from either reading)', G5,
          'They sleep.'),
    nf_tr('La casa è stata molto amata.', italian, spanish, G6),
    check('a degree adverb between the auxiliary and the participle is the participle''s: lifted as the clause''s adverb it came out `amada muy''', G6,
          'La casa ha sido muy amada.'),
    nf_tr('È stata molto amata.', italian, spanish, G7),
    check('a subject that says no gender lets its participle say it: nobody named, and `amata'' is feminine', G7,
          'Ha sido muy amada.'),
    nf_tr('Io sono sicura.', italian, spanish, G8),
    check('... and its adjective: a first person says no gender, and `sicura'' does', G8,
          'Yo soy segura.'),
    nf_tr('Sofia è stata battezzata.', italian, spanish, G9),
    check('... and a name', G9,
          'Sofia ha sido bautizada.'),
    nf_tr('Giovanissima, s''innamora di un uomo.', italian, spanish, G10),
    check('an adjective with its intensifier in front of a sentence, before its comma, is the front: read with the commas out, `molto giovane'' was a phrase and the subject', G10,
          'Muy joven, se enamora de un hombre.'),
    nf_tr('Fruga nella casa, Carolyn, mangia il pane.', italian, spanish, G11),
    check('a name between two clauses, set off by commas, is the subject of both: read as three pieces the name alone was no clause, and the sentence was refused', G11,
          'Hurga en la casa, Carolyn, come el pan.'),
    nf_tr('Fruga nella casa, Carolyn, mangia il pane.', italian, english, G12),
    check('... and English puts it first, and the second clause shares it', G12,
          'Carolyn rummages in the house, eats the bread.').

newspaper_fregene_checks_3 :-
    reason_ir('Un giorno butta il pane.', italian, H1),
    check('a time in front makes what follows no command: `un giorno butta il pane'' tells what he did one day, and `butta'' is also the command, `Throw the bread''', H1,
          [ir(s(none,null(third,singular),g(throws,present,simple,no),[obj(np(det(article,the,w(the,lower)),none,[],w(bread,lower),singular)),at_time(np(det(article,a,w(a,lower)),none,[],w(day,lower),singular))]),46)]),
    nf_tr('Così il cane dorme.', italian, spanish, H2),
    check('an adverb at the head whose first meaning joins its sentence to the one before stays there: after the verb it was the way he sleeps', H2,
          'Así el perro duerme.'),
    nf_tr('Poi il cane dorme "lui è un artista.', italian, spanish, H3),
    check('a quotation that opens inside a sentence and does not close in it divides the sentence before its first word: read as one clause the piece had two verbs', H3,
          'Entonces el perro duerme "él es un artista.'),
    nf_tr('Testa andiamo a Roma, croce in Usa.', italian, spanish, H4),
    check('a bare noun before a clause of another person is what the clause hangs on, and a capital the lesson knows only as a verb''s form is a name: `testa'' was he tests and `Usa'' he uses', H4,
          'Cabeza vamos a Roma, cruz en Usa.'),
    nf_tr('Così bella.', italian, spanish, H5),
    check('an adjective with its intensifier says something of somebody, the copula and the subject left out', H5,
          'Tan bella.'),
    nf_tr('Così amata.', italian, spanish, H6),
    check('... and a participle with its degree adverb', H6,
          'Tan amada.'),
    nf_tr('Povera Margherita.', italian, spanish, H7),
    check('adjectives before one capitalised word with no determiner are a name''s: `margherita'' is a daisy to the lesson', H7,
          'Pobre Margherita.'),
    nf_tr('Certo che ha capito cos''è successo.', italian, spanish, H8),
    check('a question word after a verb that takes the question stands for what the clause leaves out, and `certo che'' is `of course''', H8,
          'Claro que ha entendido qué ha pasado.'),
    nf_tr('Perché il cane dorme?', italian, spanish, H9),
    check('the lesson says which word asks why: with none `perché'' was `because'', a question that answered itself', H9,
          '¿Por qué duerme el perro?'),
    nf_tr('Perché il cane dorme?', italian, english, H10),
    check('... and English asks it', H10,
          'Why does the dog sleep?'),
    nf_tr('Fregene, la tragedia in piscina il dolore e le accuse della madre.', italian, spanish, H11),
    check('an article and a noun in its number with a word meaning `of'' after it are a phrase, never a clitic and a verb: `le accuse della madre'' was THEY accusing her of the mother', H11,
          'Fregene, la tragedia en piscina el dolor y las acusaciones de la madre.').

newspaper_fregene_checks_4 :-
    nf_tr('Il cane mangia un peso non indifferente.', italian, spanish, J1),
    check('a denial between a noun and its adjective is the phrase''s, not the sentence''s: `un peso non indifferente'' is a weight that is not negligible', J1,
          'El perro come un peso no indiferente.'),
    nf_tr('Il cane mangia un peso non indifferente.', italian, english, J2),
    check('... in English too', J2,
          'The dog eats a not indifferent weight.'),
    nf_tr('Il cane vede non solo il gatto ma anche la casa.', italian, spanish, J3),
    check('not only ... but: a denial before `only'' is no denial of the verb, and the lesson''s partner of `sólo'' is `sino''', J3,
          'El perro ve no sólo el gato sino también la casa.'),
    nf_tr('Non solo il cane ma anche il gatto dorme.', italian, spanish, J4),
    check('... as a subject too, the verb agreeing with the second half: read word by word it was `El perro pero el gato no duermen sólo también''', J4,
          'No sólo el perro sino también el gato duerme.'),
    nf_tr('Non solo il cane ma anche il gatto dorme.', italian, english, J5),
    check('... and English''s own words', J5,
          'Not only the dog but also the cat sleeps.'),
    nf_tr('Il pane che ho fatto, non solo io ma anche Maria, è buono, il cane lo mangia.', italian, spanish, J6),
    check('... as an insertion between a subject and its verb, and the comma that closes it divides nothing: divided after it, the subject and the insertion were a clause with its verb left out', J6,
          'El pan que he hecho, no sólo yo sino también Maria, es bueno, el perro lo come.'),
    nf_tr('Il pane che ho fatto, non solo io ma il gatto, è buono, il cane lo mangia.', italian, spanish, J15),
    check('... and no coordinator inside it divides the sentence: at `ma'' both sides read, a verbless piece and `il gatto, è buono'', and English said `I not only but the cat'' -- the case''s `ma anche'' was kept whole only because `anche'' is also the plural of `anca'', a bare noun no clause begins on', J15,
          'El pan que he hecho, no sólo yo sino el gato, es bueno, el perro lo come.'),
    nf_tr('Il motivo per cui il cane dorme è il pane.', italian, spanish, J7),
    check('a preposition and the relative word joined as one word of the lesson''s open a relative clause: `per cui'' is also the conjunction `so''', J7,
          'El motivo para el que el perro duerme es el pan.'),
    nf_tr('Il motivo per cui il cane dorme è il pane.', italian, english, J8),
    check('... in English too', J8,
          'The reason for which the dog sleeps is the bread.'),
    nf_tr('Il cane va in Usa.', italian, spanish, J9),
    check('a capitalised word the lesson knows only as a verb''s form is a name after a preposition', J9,
          'El perro va en Usa.'),
    nf_tr('Il cane vede lo stabilimento "miraggio".', italian, spanish, J10),
    check('a noun in quotation marks after a noun says what kind, and is written after it: it was written before, `el "espejismo" establecimiento''', J10,
          'El perro ve el establecimiento "espejismo".'),
    nf_tr('Lui non è un artista come avete scritto.', italian, spanish, J11),
    check('`come'' after a phrase and before a clause is `as'': read as `how'' it was the question `cómo''', J11,
          'Él no es un artista como habéis escrito.'),
    nf_tr('I cani sono più occupati a mangiare il pane che a guardare il gatto.', italian, spanish, J12),
    check('a comparison whose second term is an infinitive with its preposition, and the word for `more'' before a participle is its degree: refused', J12,
          'Los perros son más ocupados a comer el pan que a mirar el gato.'),
    nf_tr('I cani sono più occupati a mangiare il pane che a guardare il gatto.', italian, english, J13),
    check('... in English too', J13,
          'The dogs are more occupied to eat the bread than to watch the cat.'),
    nf_tr('È come quando mangi il pane.', italian, spanish, J14),
    check('the word for `as'' before a clause of `when'' is as when: refused', J14,
          'Es como cuando comes el pan.').

newspaper_fregene_checks_5 :-
    nf_tr('È durata così poco.', italian, spanish, K1),
    check('a degree adverb before another adverb is that adverb''s: `così poco'' was `así poco''', K1,
          'Ha durado tan poco.'),
    nf_tr('La donna ha tanto coraggio.', italian, spanish, K2),
    check('a determiner that is an adverb too, before a noun in its number, is the phrase''s: `tanto coraggio'' ended before `tanto'' and came out `como coraje''', K2,
          'La mujer tiene tanto coraje.'),
    nf_tr('Il cane vede la casa che sarà venduta.', italian, spanish, K3),
    check('a relative clause''s participle agrees with the phrase it sits on: with a gap for a subject it came out `vendido''', K3,
          'El perro ve la casa que será vendida.'),
    nf_tr('Il cane vede un uomo alto e snello.', italian, english, K4),
    check('an adjective with a coordinator and an adjective after it ends no phrase: `un uomo alto e snello'' was a man, high, and slender', K4,
          'The dog sees a tall and slender man.'),
    nf_tr('Non è molto conosciuto.', italian, spanish, K5),
    check('a passive has an object by what it is, so its verb is chosen as a transitive one''s: `conocido'', where it was `sabido''', K5,
          'No es muy conocido.'),
    nf_tr('Tutti dormono.', italian, spanish, K6),
    check('a pronoun the lesson states as a plural is plural: `tutti'' is everyone, singular in English, and the plural verb refused it', K6,
          'Todos duermen.'),
    nf_tr('Tutti dormono.', italian, english, K7),
    check('... and English agrees with its own word', K7,
          'Everyone sleeps.'),
    nf_tr('Per oggi, i risultati dell''autopsia che sarà effettuata dal medico.', italian, spanish, K8),
    check('a participle the lesson calls a noun too, with no noun before it, is the phrase''s noun: `risultati'' is also what `risultare'' says of several things, and the sentence was refused', K8,
          'Para hoy, los resultados de la autopsia que será efectuada por el médico.'),
    nf_tr('Io non parlo per il bagnino ma in genere è così.', italian, english, K9),
    check('English leaves a second subject out only where the first is of the same person and number: `io ... ma in genere è così'' is I and then it, and elided it came out `I do not speak ... but is thus generally''', K9,
          refused),
    nf_tr('Il cane vede l''inchiesta (contro ignoti) aperta dal medico.', italian, spanish, K10),
    check('a bracket before a participle with its agent is the phrase''s: hung on the whole it had no reading', K10,
          'El perro ve la indagación (contra desconocidos) abierta por el médico.'),
    nf_tr('Oggi il cane dorme.', italian, spanish, K11),
    check('GUARD: an adverb at the head that joins nothing still goes after the verb, 1.6.8''s rule', K11,
          'El perro duerme hoy.'),
    nf_tr('Il cane dorme così.', italian, spanish, K12),
    check('GUARD: and standing alone `così'' is thus', K12,
          'El perro duerme así.'),
    nf_tr('Il cane mangia il pane ma dorme.', italian, english, K13),
    check('GUARD: and English still leaves out a second subject that is the first one', K13,
          'The dog eats the bread but sleeps.').

%% what reading the report whole found after the case above was written:
%% each red on the translator of that moment as well as on 1.8.24
newspaper_fregene_checks_6 :-
    nf_tr('Il cane dorme ma perché il gatto mangia?', italian, spanish, L1),
    check('a question that opens in the second clause is that clause''s: read as one question, `perché'' was `because'' and the sentence asked whether the dog sleeps -- `Sì, può essere che Margherita abbia avuto un malore ma perché nessuno le ha viste?''', L1,
          'El perro duerme pero ¿por qué come el gato?'),
    nf_tr('Il cane dorme ma perché il gatto mangia?', italian, english, L2),
    check('... and English asks it there', L2,
          'The dog sleeps but why does the cat eat?'),
    nf_tr('Il cane vede Maria o meglio Carla.', italian, spanish, L3),
    check('`or rather'' is a coordinator of two words: read as `o'' and the adverb `meglio'' the adverb went to the end of the clause, `È Margherita o meglio Malgorzata Dworak'' ... `de la pareja mejor''', L3,
          'El perro ve a Maria o mejor dicho Carla.'),
    nf_tr('Il cane vede Maria o meglio Carla.', italian, english, L4),
    check('... in English too', L4,
          'The dog sees Maria or rather Carla.').

%% what the controls found: the old controls read on the new store, each
%% sentence below the shape of a text the first cut of this version moved,
%% and the GUARDs pin what 1.8.24 already did right
newspaper_fregene_checks_7 :-
    nf_tr('Il cane mangia il pane perché il gatto dorme.', italian, spanish, M1),
    check('a question word that is a connector too asks only after a verb that takes the question: once the lesson said `perché'' asks why, `perché'' after the verb''s object read as `why'' -- `La sinistra l''ha attaccata perché ...'', `por qué'' in four old controls', M1,
          'El perro come el pan porque el gato duerme.'),
    nf_tr('Il cane sa perché il gatto dorme.', italian, spanish, M2),
    check('GUARD: and after a verb that takes the question it asks', M2,
          'El perro sabe por qué el gato duerme.'),
    nf_tr('El perro se enamora del gato.', spanish, italian, M3),
    check('a pronoun''s elision is written only before what the lesson says it comes before: the line that reads `s''innamora'' made `S''aumentarono le vendite'' and `come s''era annunciato'' of four old controls', M3,
          'Il cane si innamora del gatto.'),
    nf_tr('Il cane vede la Tate Gallery.', italian, spanish, M4),
    check('a capitalised noun no reading of its determiner can take is no noun of it: `tate'' is the plural of `tata'', and `la Tate Gallery'' read as the babysitters with `Gallery'' apposed, which nothing could write', M4,
          'El perro ve la Tate Gallery.'),
    nf_tr('Evacuata la Tate Gallery.', italian, english, M4b),
    check('... and after a headline''s participle, where the subject finder ended the phrase at `Tate'' and `la Tate'' alone had no reading: the twelve''s first sentence, refused on the full store after the check above was green', M4b,
          'The Tate Gallery has been evacuated.'),
    nf_tr('Il cane vede la "Casa".', italian, spanish, M5),
    check('GUARD: a quoted word the lesson knows that can be the noun of its determiner is the word: `la "Bastiglia"'' went through untranslated in three sentences of an old control', M5,
          'El perro ve la "casa".'),
    nf_tr('El perro a veces duerme.', spanish, italian, M6),
    check('GUARD: the dictionary''s word for `sometimes'' said again first: with `a volte'' first, an old control''s `a veces maleducada'' came out `a volte maleducata''', M6,
          'Il cane dorme talvolta.'),
    nf_tr('Il cane va a restare.', italian, spanish, M7),
    check('GUARD: a verb said to take no object, and not a meaning of it: `The intransitive verb "resta" means "remains".'' kept `remains'' for a clause with no object, and an infinitive crossed as `stays'', which Spanish has no word for -- `è costretto a restare per 25 anni''', M7,
          'El perro va a quedar.'),
    nf_tr('Resta il cane.', italian, english, M8),
    check('GUARD: ... and the verb that takes no object still has its subject after it (into English: Spanish writes `Queda el perro.'' from either reading, and English refuses a verb nobody is named for)', M8,
          'The dog remains.'),
    nf_tr('Poi ci sarà il pane.', italian, spanish, M9),
    check('a front with no comma before `there is'' is written in front: the connecting adverb kept there, the writer of `there is'' found it among the complements and wrote nothing -- `allora c''è spazio per qualche preoccupazione''', M9,
          'Entonces habrá el pan.'),
    nf_tr('Cosa ci sarà?', italian, spanish, M10),
    check('GUARD: `there is'' with nobody named and something asked for keeps the reading it had: the first cut refused every one with nobody named, and `che cosa ci sarebbe di male ...?'' had no other reading', M10,
          '¿Qué habrá?'),
    nf_tr('Il cane vuole sapere come il gatto dorme.', italian, spanish, M11),
    check('GUARD: `how'' after an infinitive that takes the question asks, and is `as'' only after a phrase: `bisognerebbe sapere come sono finiti lì'' came out `como''', M11,
          'El perro quiere saber cómo el gato duerme.'),
    nf_tr('Il cane vede la casa che vede chi è stanco.', italian, spanish, M12),
    check('GUARD: the clause of `chi'' has its own gap''s gender: written inside the clause on `casa'' it took the house''s, `cansada'' -- `chi in Italia (evidentemente a lui obbligato) non lo imita'' came out `obligada''', M12,
          'El perro ve la casa que ve al que es cansado.'),
    nf_tr('¡Feliz Navidad!', spanish, english, M13),
    check('GUARD: a noun the lesson knows after adjectives is a name only where the lesson says it is one: `Happy Christmas!'' came out `Happy Navidad!''', M13,
          'Happy Christmas!'),
    nf_tr('¿Qué tal un poco de pan?', spanish, english, M14),
    check('a question word that relates nothing is no phrase''s noun: `qué tal'' read as such what once `un poco'' could be read, where it was refused', M14,
          refused),
    nf_tr('Todos ellos pueden comer.', spanish, english, M15),
    check('GUARD: `ellos'' never stands before its verb as its object, which the lesson says: read as one, `Todos ellos pueden conducir.'' came out `Everyone can them drive.'' (the lesson says `ellos'' means `them'' as well, as the vocabulary does, or no arm could show it)', M15,
          refused).

newspaper_lotr :-
    section('a Spanish report into Italian: the last clause a coordinator follows, a main clause after a time clause, a verb''s plural that is no noun''s, the reflexive passive with adjuncts before its subject, a second person at the head spelled like a noun''s plural, a clitic after a preposition, a front that ends between an article''s adjective and its noun, a time clause with no comma before a clause that opens on its pronouns, the word for `very'' before an adjective that is a noun too, the accident, a modal before a perfect infinitive, the copula after a denial, a participle''s plural, a comma after a coordinator, the shared subject after a comma and a coordinator, a plural''s own gender'),
    newspaper_lotr_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_lotr_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_lotr_checks_1, newspaper_lotr_checks_2,
    reason_unlearn(italian), reason_unlearn(spanish).

%% each lesson in two parts, a clause over a page (8 KB) being one the store
%% cannot hold. What the vocabulary gives a word the lesson gives it too:
%% `diferencias' is also what `diferenciar' says to one person, `toma' is
%% also the command take, `pasan' the plural of the verb `pasa' where the
%% noun `pasa', a raisin, has its own, `son' also the noun sound, `alto'
%% also a height, `debe' also owes -- without those the old translator
%% reads the sentences right by luck, and a check could not tell the two
%% apart
newspaper_lotr_lesson(L, Text) :-
    newspaper_lotr_part(L, 1, A), newspaper_lotr_part(L, 2, B),
    atomic_list_concat([A, ' ', B], Text).

newspaper_lotr_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural. Every verb that ends in "e" takes "n" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The noun "hombre" means "man". "hombre" is a person.
The feminine noun "piedra" means "stone". The feminine noun "huella" means "footprint". The feminine noun "nieve" means "snow".
The feminine noun "toma" means "taking". The noun "inicio" means "beginning". The noun "efecto" means "effect".
The feminine noun "diferencia" means "difference". The feminine noun "compra" means "purchase".
The feminine noun "proporción" means "proportion". "proporciones" is the plural of "proporción".
The noun "error" means "error". "errores" is the plural of "error".
The noun "son" means "sound". "sones" is the plural of "son". The noun "alto" means "height".
The noun "plano" means "plane". The masculine adjective "plano" means "flat".
The noun "protagonista" means "protagonist". "protagonista" is not feminine. "protagonista" is a person.
The feminine noun "pasa" means "raisin".
The masculine adjective "alto" means "tall". "altísimo" is the superlative of "alto".
The adjective "siguiente" means "following". The adjective "real" means "real". "reales" is the plural of "real".
The adjective "protagonista" means "leading".
The adverb "muy" means "very". The adverb "poco" means "little". The adverb "sorprendentemente" means "surprisingly".
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "que" means "that". "que" is a relative.
The conjunction "cuando" means "when".
The pronoun "él" means "he". The pronoun "él" means "him". The pronoun "él" does not precede the verb.
The pronoun "lo" means "him". The pronoun "la" means "her". The pronoun "me" means "me".
The dative pronoun "les" means "them".
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with".
The preposition "frente a" means "compared with".
The noun "brazo" means "arm". The masculine adjective "izquierdo" means "left". "izquierdos" is the plural of "izquierdo".').

newspaper_lotr_part(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comido" is the participle of "come".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "es" means "is". "son" is the plural of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha". "haber" is the infinitive of "ha".
The verb "aparece" means "appears". The verb "desaparece" means "disappears". "desaparece" is the imperative of "desaparece".
The verb "apoya" means "backs".
The verb "pesa" means "weighs". "pesan" is the plural of "pesa".
The verb "diferencia" means "differentiates". "diferencias" is the second person of "diferencia".
The verb "compra" means "buys". "compras" is the second person of "compra".
The verb "olvida" means "forgets". "olvidó" is the past of "olvida". "olvida" takes the accident.
The verb "pasa" means "passes". "pasan" is the plural of "pasa".
The modal "debe" means "must". The verb "debe" means "owes". "deben" is the plural of "debe".
"debía" is the past of "debe". "debían" is the past of "deben".
The verb "toma" means "takes". "toma" is the imperative of "toma".
"seen" is the participle of "sees". "forgot" is the past of "forgets". "eaten" is the participle of "eats".
The verb "levanta" means "raises". "levantan" is the plural of "levanta".').

newspaper_lotr_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"nel" is the contraction of "in il". "nella" is the contraction of "in la".
"l''" is the elision of "lo". "l''" is the elision of "la". "all''" is the elision of "alla". "alla" is the contraction of "a la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". The noun "pane" means "bread".
The feminine noun "casa" means "house". The feminine noun "pietra" means "stone". "pietre" is the plural of "pietra".
The feminine noun "impronta" means "footprint". "impronte" is the plural of "impronta". The feminine noun "neve" means "snow".
The feminine noun "presa" means "taking". The noun "inizio" means "beginning". The noun "effetto" means "effect".
The adjective "seguente" means "following". The masculine adjective "alto" means "tall".
The adjective "reale" means "real". "reali" is the plural of "reale".
The adverb "molto" means "very". The adverb "poco" means "little". The adverb "sorprendentemente" means "surprisingly".
The conjunction "e" means "and". The conjunction "ma" means "but". The conjunction "che" means "that". "che" is a relative.
The conjunction "quando" means "when".
The impersonal pronoun "si" means "one". The reflexive pronoun "si" means "itself".
The preposition "in" means "in". The preposition "di" means "of". The preposition "a" means "to".
The noun "braccio" means "arm". "braccia" is the plural of "braccio". "braccia" is feminine.
The masculine adjective "sinistro" means "left". The feminine adjective "sinistra" means "left".
"sinistri" is the plural of "sinistro". "sinistre" is the plural of "sinistra".
The feminine noun "legge" means "law". "leggi" is the plural of "legge".
The feminine noun "procura" means "office". "procure" is the plural of "procura".').

newspaper_lotr_part(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "è" means "is". "sono" is the plural of "è".
The verb "appare" means "appears". The verb "scompare" means "disappears".
The verb "pende" means "hangs". "pesa" is the participle of "pende". "pesa" is feminine.
"pese" is the participle of "pende". "pese" is feminine. "pese" is the plural of "pesa".
The verb "pesa" means "weighs". "pesano" is the plural of "pesa".
The verb "dimentica" means "forgets". "dimenticano" is the plural of "dimentica".
"dimenticò" is the past of "dimentica". "dimenticarono" is the past of "dimenticano".
The verb "alza" means "raises". "alzano" is the plural of "alza".
The verb "legge" means "reads". "leggi" is the second person of "legge". The verb "procura" means "procures".').

newspaper_lotr_checks_1 :-
    nf_tr('Al inicio, cuando el perro duerme, el gato aparece y desaparece.', spanish, english, A1),
    check('the statement a coordinator follows is the last clause of what went before, however that was joined: after a front and a time clause the left side is join/3 and no clause of its own, and `desaparece'' was read as the command', A1,
          'To the beginning, when the dog sleeps, the cat appears and disappears.'),
    reason_ir('Cuando el perro duerme, se apoya en la casa.', spanish, IR2),
    ( IR2 = [ir(join(_, _, s(_, Su2, g(L2, _, _, _), _)), _)] -> R2 = Su2-L2 ; R2 = none ),
    check('a main clause after a time clause whose subject is a third person singular shares it: `se apoya'' is he leans, and read with nobody named the `se'' was the impersonal one, `one backs''', R2,
          null(third, singular)-reflexive(backs)),
    nf_tr('Los protagonistas pasan frente a la casa y los perros duermen.', spanish, english, A3),
    check('a verb''s plural is no noun''s where the lesson''s rule makes the noun another: `pasan'' is the plural of the verb `pasa'' and the noun, a raisin, has `pasas'' -- read as the noun, the leading raisins were the subject of `duermen''', A3,
          'The protagonists pass compared with the house and the dogs sleep.'),
    nf_tr('No se ven en la nieve las huellas.', spanish, english, A4),
    check('the reflexive passive with adjuncts before its subject: the subject was looked for right after the verb and found a preposition, and the pro-drop reading made somebody not see the footprints', A4,
          'The footprints are not seen in the snow.'),
    nf_tr('Diferencias en el plano son errores.', spanish, english, A5),
    check('a second person at the head spelled like a noun''s plural is tried last: `diferencias'' is also what `diferenciar'' says to one person, and read so `el plano son'' was the flat sound', A5,
          'Differences in the plane are errors.'),
    nf_tr('Compras pan.', spanish, english, A6),
    check('GUARD: and where no later place reads, the head is the verb as before', A6,
          'You buy bread.'),
    nf_tr('En la toma, cuando el perro duerme, el gato come.', spanish, english, A7),
    check('a clitic is never a preposition''s object: cut after `la'' the front was `in her'' and `toma'' the command take', A7,
          'In the taking, when the dog sleeps, the cat eats.'),
    nf_tr('El perro come con él.', spanish, english, A8),
    check('GUARD: a pronoun that does not precede the verb is one', A8,
          'The dog eats with him.'),
    nf_tr('En la siguiente toma, cuando el perro duerme, el gato come.', spanish, italian, A9),
    check('a front never ends between an article with its adjective and the noun after them: `en la siguiente'', the following one, left `toma'' to be the command take', A9,
          'Nella seguente presa, quando il cane dorme, il gatto mangia.'),
    nf_tr('Cuando el perro duerme se ve un gato.', spanish, english, A10),
    check('a time clause with no comma may be followed by a main clause that opens on its pronouns: the division was asked only where a verb group starts, which put `se'' in the time clause', A10,
          'When the dog sleeps one sees a cat.').

newspaper_lotr_checks_2 :-
    nf_tr('El altísimo Gandalf duerme.', spanish, italian, B1),
    check('the word for `very'' before a word that is an adjective too says it is one: `alto'' is also a height, the name was apposed to it, and nothing could write it', B1,
          'Il molto alto Gandalf dorme.'),
    nf_tr('El perro ve el pan que se les olvidó.', spanish, english, B2),
    check('what happened to somebody by accident is what they did: `"olvida" takes the accident.'', and the dative is the subject', B2,
          'The dog sees the bread that they forgot.'),
    nf_tr('Se me olvidó el pan.', spanish, english, B3),
    check('and in a main clause the thing forgotten is the object', B3,
          'I forgot the bread.'),
    nf_tr('Los perros debían haber comido el pan.', spanish, english, B4),
    check('a verb the lesson also calls a modal is the modal before a perfect infinitive too, and `must'''' past is `had to'': read as `owes'' it came out `owed to have eaten''', B4,
          'The dogs had to have eaten the bread.'),
    nf_tr('Las piedras pesan poco y no son reales.', spanish, english, B5),
    check('a verb''s form after the word for `not'' is the verb, a noun too or not: `son'' read as the noun sound made the stones weigh little and no sound', B5,
          'The stones weigh little and are not real.'),
    nf_tr('Las piedras pesan poco.', spanish, italian, B6),
    check('a verb''s plural is never a participle''s: `pesa'' is also the participle of `pendere'', and its plural `pese'' came out for `pesan''', B6,
          'Le pietre pesano poco.'),
    nf_tr('El perro duerme pero, sorprendentemente, el gato no come el pan.', spanish, italian, B7),
    check('a comma after a coordinator is the source''s: the insertion after it is the second clause''s front, and the comma before it was lost', B7,
          'Il cane dorme ma, sorprendentemente, il gatto non mangia il pane.'),
    nf_tr('El perro duerme, y come el pan.', spanish, english, B8),
    check('English leaves out a subject the clause before named after a comma and a coordinator too', B8,
          'The dog sleeps, and eats the bread.'),
    nf_tr('El perro levanta los brazos izquierdos.', spanish, italian, B9),
    check('a plural the lesson says is feminine gives its phrase the gender: `sus brazos izquierdos'' came out `i suoi braccia sinistri'', where `"braccia" is feminine.''', B9,
          'Il cane alza le braccia sinistre.'),
    nf_tr('Leggi procure.', italian, english, B10),
    check('GUARD: a bare noun alone is no subject before its verb, so the place right after a second person at the head comes after the head itself: `i presìdi (leggi procure)'' came out `(actos procuran)'', the laws doing it, where it was `lees fiscalías''', B10,
          'You read offices.').

newspaper_ciampi :-
    section('an Italian report into Spanish: an abbreviation and a number, a quotation in the plain mark with a reporting clause between dashes, a name before a colon, which as an indirect question, a participle with its reflexive joined, a name after a name, a pronoun after a preposition in a subject, an accusative pronoun and the subject after its verb, a quotation that opens on an adjunct the writer moves, letters spaced out, a quotation that closes at its comma, an absolute participle, a condition before a relative clause''s verb, a heading''s phrase before a clause of since, the parties, a noun''s plural that spells no verb''s, a comment between two commas that says nothing, a determiner that is a noun too, the object a verb''s sense counts, the participles after a copula''s perfect'),
    newspaper_ciampi_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_ciampi_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_ciampi_checks_1, newspaper_ciampi_checks_2, newspaper_ciampi_checks_3, newspaper_ciampi_checks_4, newspaper_ciampi_checks_5, newspaper_ciampi_checks_6,
    newspaper_ciampi_checks_7,
    reason_unlearn(spanish), reason_unlearn(italian).

%% each lesson in two parts, a clause over a page (8 KB) being one the store
%% cannot hold. What the vocabulary gives a word the lesson gives it too:
%% `legge' is the law and what a man reads, `parti' the plural of a birth and
%% of a party, `modifiche' the plural of a modification while the verb has
%% `modificano', `questa' a demonstrative and a pronoun, `noi' we and us,
%% `visto' a participle, `che' a conjunction and a relative word, `anche' the
%% adverb and the plural of a hip, `este' a demonstrative and the east --
%% without those the old translator reads the sentences right by luck, and a
%% check could not tell the two apart
newspaper_ciampi_lesson(L, Text) :-
    newspaper_ciampi_part(L, 1, A), newspaper_ciampi_part(L, 2, B),
    atomic_list_concat([A, ' ', B], Text).

newspaper_ciampi_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "del" is the contraction of "di il".
"della" is the contraction of "di la". "al" is the contraction of "a il".
"l''" is the elision of "lo". "l''" is the elision of "la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". The noun "pane" means "bread".
The feminine noun "casa" means "house". "case" is the plural of "casa". The feminine noun "notizia" means "news".
The masculine noun "articolo" means "article". "art" is the apocope of "articolo".
The masculine noun "comunicato" means "communique". The masculine noun "motivo" means "reason". "motivi" is the plural of "motivo".
The masculine noun "codice" means "code". The masculine noun "parto" means "birth". "parti" is the plural of "parto".
The feminine noun "parte" means "party". "parti" is the plural of "parte".
The feminine noun "modifica" means "modification". "modifiche" is the plural of "modifica".
The feminine noun "legge" means "law". "leggi" is the plural of "legge".
The feminine noun "vista" means "sight". The masculine noun "visto" means "visa".
The masculine adjective "grande" means "big". "grandi" is the plural of "grande".
The feminine adjective "buona" means "good". The adjective "inspiegabile" means "inexplicable".
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative. The conjunction "se" means "if".
The conjunction "visto che" means "since".
The pronoun "lo" means "it". The pronoun "lo" means "him".
The feminine demonstrative "questa" means "this". The pronoun "questa" means "this". The pronoun "questa" does not precede the verb.
The pronoun "noi" means "we". The pronoun "noi" means "us". The pronoun "noi" does not precede the verb.
The preposition "in" means "in". The preposition "di" means "of". The preposition "da" means "by". The preposition "a" means "to".
The word "quale" means "which". "quali" is the plural of "quale". "quali" is a relative.
The masculine noun "aumento" means "increase". The noun "tempo" means "time". "tempi" is the plural of "tempo". "dei" is the contraction of "di i".
The feminine noun "associazione" means "association". The adjective "nazionale" means "national". "nazionali" is the plural of "nazionale".
The masculine noun "magistrato" means "magistrate". "magistrati" is the plural of "magistrato". "magistrato" is a person.
The masculine adjective "certo" means "certain". The adverb "certo" means "certainly".
The preposition "secondo" means "according to". The adverb "secondo" means "second". The masculine noun "secondo" means "second".
The masculine adjective "secondo" means "second".
The adverb "anche" means "also". The feminine noun "anca" means "hip". "anche" is the plural of "anca".
The impersonal modal "bisogna" means "must". The verb "bisogna" means "needs". "bisognerà" is the future of "bisogna".
The impersonal pronoun "si" means "one". The reflexive pronoun "si" means "itself".
The masculine adjective "primo" means "first". The adverb "primo" means "first".
The masculine adjective "solo" means "alone". The adverb "solo" means "only".
The preposition "tra" means "among".
The masculine noun "verde" means "green". The masculine adjective "verde" means "green".
"lavata" is the participle of "lava". "lavata" is feminine. "lavati" is the participle of "lava". "lavati" is the plural of "lavato".
The pronoun "li" means "them". "gatti" is the plural of "gatto".').

newspaper_ciampi_part(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede".
"visto" is the participle of "vede". "visti" is the participle of "vede". "visti" is the plural of "visto".
"vista" is the participle of "vede". "vista" is feminine.
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è".
"stato" is the participle of "è". "stata" is the participle of "è". "stata" is feminine. "è" is the auxiliary of "è".
The verb "appare" means "appears". The verb "aggiunge" means "adds".
The verb "dice" means "says". "detto" is the participle of "dice".
The auxiliary "ha" means "has". "hanno" is the plural of "ha".
The verb "annuncia" means "announces". "annunciano" is the plural of "annuncia".
The verb "lava" means "washes". "lavato" is the participle of "lava".
The verb "chiama" means "calls". "chiamano" is the plural of "chiama".
The verb "legge" means "reads". "leggi" is the second person of "legge".
The verb "modifica" means "modifies". "modificano" is the plural of "modifica".
"modifichiamo" is the first person of "modificano". "modificarono" is the past of "modificano".
The modal "può" means "can". "possono" is the plural of "può". "possano" is the subjunctive of "possono".
"mangiare" is the infinitive of "mangia". "mangiato" is the participle of "mangia". "dormito" is the participle of "dorme".
The verb "esce" means "goes out". "uscito" is the participle of "esce". "uscita" is the participle of "esce". "uscita" is feminine.
"usciti" is the participle of "esce". "usciti" is the plural of "uscito". "uscite" is the participle of "esce".
"uscite" is feminine. "uscite" is the plural of "uscita". "è" is the auxiliary of "esce".
The verb "ritorna" means "returns".
The verb "arriva" means "arrives". "arrivato" is the participle of "arriva". "arrivata" is the participle of "arriva".
"arrivata" is feminine. "arrivati" is the participle of "arriva". "arrivati" is the plural of "arrivato".
"arrivate" is the participle of "arriva". "arrivate" is feminine. "arrivate" is the plural of "arrivata". "è" is the auxiliary of "arriva".').

newspaper_ciampi_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural. Every verb that ends in "e" takes "n" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The feminine noun "noticia" means "news".
The masculine noun "artículo" means "article". The masculine noun "comunicado" means "communique".
The masculine noun "motivo" means "reason". The masculine noun "código" means "code".
The masculine noun "parto" means "birth". The noun "parte" means "party". "parte" is feminine.
The feminine noun "modificación" means "modification". "modificaciones" is the plural of "modificación".
The feminine noun "ley" means "law". "leyes" is the plural of "ley".
The masculine adjective "grande" means "big". "grandes" is the plural of "grande".
The feminine adjective "buena" means "good". The adjective "inexplicable" means "inexplicable".
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative. The conjunction "si" means "if".
The conjunction "ya que" means "since".
The pronoun "lo" means "it". The pronoun "lo" means "him".
The feminine demonstrative "esta" means "this". The pronoun "esta" means "this". The pronoun "esta" does not precede the verb.
The masculine demonstrative "este" means "this". The masculine noun "este" means "east".
The pronoun "nosotros" means "we". The pronoun "nosotros" means "us". The pronoun "nosotros" does not precede the verb.
The preposition "en" means "in". The preposition "de" means "of". The preposition "por" means "by". The preposition "a" means "to".
The word "qué" means "what". The word "qué" means "which".
The pronoun "cuál" means "which". "cuáles" is the plural of "cuál".
The masculine noun "aumento" means "increase". The noun "tiempo" means "time". "tiempos" is the plural of "tiempo".
The feminine noun "asociación" means "association". The adjective "nacional" means "national". "nacionales" is the plural of "nacional".
The masculine noun "magistrado" means "magistrate". "magistrados" is the plural of "magistrado". "magistrado" is a person.
The masculine adjective "cierto" means "certain". The adverb "ciertamente" means "certainly".
The preposition "según" means "according to". The adverb "segundo" means "second". The adverb "también" means "also".
The impersonal modal "hay que" means "must". The modal "debe" means "must".
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".
The masculine adjective "primero" means "first". The adverb "primero" means "first". "primer" is the apocope of "primero".
The masculine adjective "solo" means "alone". The adverb "solo" means "only".
The preposition "entre" means "among".
"lavada" is the participle of "lava". "lavada" is feminine. The pronoun "los" means "them".
"llegada" is the participle of "llega". "llegada" is feminine.').

newspaper_ciampi_part(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "come" means "eats". "comen" is the plural of "come".
The verb "ve" means "sees". "ven" is the plural of "ve".
"visto" is the participle of "ve". "vistos" is the participle of "ve". "vistos" is the plural of "visto".
"vista" is the participle of "ve". "vista" is feminine.
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es".
"sido" is the participle of "es". "ha" is the auxiliary of "es".
The verb "aparece" means "appears". The verb "añade" means "adds".
The verb "dice" means "says". "dicho" is the participle of "dice".
The auxiliary "ha" means "has". "han" is the plural of "ha".
The verb "anuncia" means "announces".
The verb "lava" means "washes". "lavado" is the participle of "lava".
The verb "lee" means "reads".
The verb "llama" means "calls". "llaman" is the plural of "llama".
The verb "modifica" means "modifies". "modifican" is the plural of "modifica".
The modal "puede" means "can". "pueden" is the plural of "puede".
The verb "necesita" means "needs". "comer" is the infinitive of "come". "comido" is the participle of "come".
"dormido" is the participle of "duerme". "dormida" is the participle of "duerme". "dormida" is feminine.
"dormidos" is the participle of "duerme". "dormidos" is the plural of "dormido". "dormidas" is the participle of "duerme".
"dormidas" is feminine. "dormidas" is the plural of "dormida".
The verb "regresa" means "returns". The transitive verb "devuelve" means "returns".
The verb "sale" means "goes out". "salido" is the participle of "sale". The verb "llega" means "arrives". "llegado" is the participle of "llega".').

newspaper_ciampi_checks_1 :-
    nf_tr('Il cane vede l''art. 111.', italian, spanish, A1),
    check('a point after an abbreviation and before a number ends no sentence: `l''art. 111'' is the article 111, and cut at the point it was two pieces, `l''art'' and `111''', A1,
          'El perro ve el artículo 111.'),
    nf_tr('"Il cane dorme - aggiunge Maria - e il gatto mangia il pane".', italian, spanish, A2),
    check('a whole sentence in the plain mark with a reporting clause between dashes: the pair is the piece''s, and the piece was cut at its dashes with each part tokenised by itself. (Since 1.8.29 a reporting clause between two clauses, each naming its own subject, stays where it stood, dmid/1: 1.8.27 wrote it after the sentence, `... y el gato come el pan – añade Maria –".'')', A2,
          '"El perro duerme – añade Maria – y el gato come el pan".'),
    nf_tr('Maria: "Il cane dorme".', italian, spanish, A3),
    check('a name alone before a colon is who speaks: the piece is one word, and a lone capitalised word is a verb with its pronouns joined as often as a name', A3,
          'Maria: "El perro duerme".'),
    nf_tr('Il c s m dorme.', italian, spanish, A4),
    check('letters spaced out are an acronym: `c s m'' is the CSM, and read letter by letter it was three words no lesson knows', A4,
          'El CSM duerme.').

newspaper_ciampi_checks_2 :-
    nf_tr('Appare inspiegabile quali possano essere i motivi.', italian, spanish, B1),
    check('`which'' by itself is an indirect question and a pronoun where the lesson has one: `cuáles'', where it was the relative `que'' and then `qué'', which asks what', B1,
          'Aparece inexplicable cuáles pueden ser los motivos.'),
    nf_tr('Il cane vede in quali case il gatto dorme.', italian, spanish, B2),
    check('`which'' with its noun and the preposition before it: `en qué casas'', where the sentence was refused', B2,
          'El perro ve en qué casas el gato duerme.'),
    nf_tr('Il cane lavatosi dorme.', italian, spanish, B3),
    check('a participle carries the reflexive `si'' joined to it, read and not written: `lavatosi'' is the participle and the pronoun, where the word was unknown', B3,
          'El perro lavado duerme.'),
    nf_tr('Il cane Rex, Mario Rossi, dorme.', italian, spanish, B4),
    check('a name before an apposition after a determiner: `Rex'' is the dog''s name and `Mario Rossi'' the one set off after it, where the phrase had no reading', B4,
          'El perro Rex, Mario Rossi, duerme.'),
    nf_tr('I cani visti da noi dormono.', italian, spanish, B5),
    check('a pronoun right after a preposition is that preposition''s object, and no clitic before a verb: `visti da noi'' in a subject, where every subject with `da noi'' in it was refused', B5,
          'Los perros vistos por nosotros duermen.'),
    nf_tr('Il cane di questa legge.', italian, spanish, B6),
    check('GUARD: a pronoun a determiner is too stays no subject''s last word: `di questa legge'' is the law, where `questa'' the pronoun and `legge'' the verb wrote `El perro de esta lee''', B6,
          'El perro de esta ley.'),
    nf_tr('Lo annuncia un comunicato.', italian, english, B7),
    check('an object pronoun that is no dative is the verb''s one direct object, so the phrase after the verb that agrees with it is the subject: read with nobody named, English refused it', B7,
          'A communique announces it.'),
    nf_tr('Lo chiamano il cane.', italian, english, B8),
    check('GUARD: and never a phrase that does not agree with the verb: `Lo chiamano il cane'' is they call it the dog, the phrase singular and the verb plural, and with no agreement the sentence had no reading', B8,
          'They call it the dog.').

newspaper_ciampi_checks_3 :-
    nf_tr('Il cane dice che "nella casa il gatto dorme".', italian, spanish, C1),
    check('a quotation that opens on an adjunct the writer moves is the clause''s: the mark stood on the adjunct, written after the verb, and the closing mark on the verb: `el gato duerme'''' ''''en la casa''', C1,
          'El perro dice que "el gato duerme en la casa".'),
    nf_tr('"Il cane dorme, vista la casa", ha detto.', italian, spanish, C2),
    check('a quotation that closes at its comma with no speaker named: the last word before the comma carries the mark, and read as clauses `vista la casa'' was a headline passive, `la casa ha sido vista''', C2,
          '"El perro duerme, vista la casa", ha dicho.'),
    nf_tr('"Nella casa il gatto dorme", dice il cane.', italian, spanish, C3),
    check('GUARD: with the closing comma alone the division has always read it, marks and all: the first cut of the reading above wrote the mark after the verb and the adjunct outside', C3,
          '"El gato duerme en la casa", dice el perro.'),
    nf_tr('Il cane dorme, vista la casa.', italian, spanish, C4),
    check('an absolute participle after a comma agrees with the phrase after it: `vista la casa'', where the participle stayed masculine as the predicate of the clause before it', C4,
          'El perro duerme, vista la casa.'),
    nf_tr('Il cane vede la casa, che se il gatto dorme, mangia il pane.', italian, spanish, C5),
    check('a condition before a relative clause''s verb, a comma after it: the front of the clause, written in front of it, where the sentence was refused', C5,
          'El perro ve la casa, que si el gato duerme, come el pan.'),
    nf_tr('Il cane vede la casa, che se il gatto dorme, mangia il pane.', italian, english, C6),
    check('... and in English', C6,
          'The dog sees the house, which if the cat sleeps, eats the bread.'),
    nf_tr('Una buona notizia, visto che il cane dorme.', italian, spanish, C7),
    check('a heading''s phrase before a clause of since, where the clause has no reading of its own: `visto che'' is a conjunction of two words, and `visto'' a participle', C7,
          'Una buena noticia, ya que el perro duerme.'),
    nf_tr('Le parti dormono.', italian, spanish, C8),
    check('a form that is the plural of two takes the one whose gender is the determiner''s: `parti'' is the plural of `parto'' and of `parte'', and `le'' is feminine', C8,
          'Las partes duermen.'),
    nf_tr('Modifiche al codice.', italian, spanish, C9),
    check('a noun''s plural is no verb''s where the verb has one of its own: `modifiche'' is the modification''s and `modificano'' the verb''s, and the title was they modify', C9,
          'Modificaciones al código.'),
    nf_tr('Modificano il codice.', italian, spanish, C10),
    check('GUARD: and the verb''s own plural still reads', C10,
          'Modifican el código.'),
    nf_tr('Il cane, dorme la casa, mangia il pane.', italian, spanish, C11),
    check('a comment between two commas reports only when the verb says something or a person does: `dorme la casa'' is a verb, its subject after it and no object, and read as a report it was written after the sentence', C11,
          'El perro, duerme la casa, come el pan.'),
    %% (1.8.31: the comma that opened the reporting clause goes after the
    %% sentence with it, and the subject keeps none: this pinned `El perro,
    %% come el pan, dice Maria.', the subject's closing comma left between the
    %% dog and what it does)
    nf_tr('Il cane, dice Maria, mangia il pane.', italian, spanish, C12),
    check('GUARD: and one that does report still does, written after the sentence', C12,
          'El perro come el pan, dice Maria.').

newspaper_ciampi_checks_4 :-
    nf_tr('Secondo il cane bisogna mangiare il pane.', italian, spanish, D1),
    check('an impersonal modal has no subject before it: `secondo il cane'' is according to the dog and `bisogna'' is one must, where the dog was the subject of `debe'' and `secondo'' the adverb `second''', D1,
          'Hay que comer el pan según el perro.'),
    nf_tr('Anche secondo il cane, "bisogna mangiare il pane".', italian, spanish, D2),
    check('... and with a comma and a quotation, where the front is `también según el perro'' and what is said is one needing, the dog having been the one that needed', D2,
          'También según el perro, "se necesita comer el pan".'),
    nf_tr('Il cane dice che "bisogna mangiare il pane".', italian, spanish, D3),
    check('a quotation that opens on a verb written with the impersonal `se'' opens on the `se'': the mark stood after it, `se "necesita comer el pan"''', D3,
          'El perro dice que "se necesita comer el pan".'),
    nf_tr('Un aumento certo dei tempi.', italian, spanish, D4),
    check('an adjective that is an adverb too, right after the noun it agrees with and before an `of'' phrase, is the noun''s: `certo'' is certain, where the phrase ended at `aumento'' and it was `ciertamente''', D4,
          'Un aumento cierto de los tiempos.'),
    nf_tr('La casa certo dei tempi.', italian, spanish, D5),
    check('GUARD: and one that does not agree with it is the adverb still: `certo'' is masculine after a feminine noun', D5,
          'La casa ciertamente de los tiempos.'),
    nf_tr('Secondo l''associazione nazionale magistrati, il cane dorme.', italian, spanish, D6),
    check('a plural noun the lesson calls a person, after a noun and its adjective, is the name''s tail with its `of'' left out: `l''associazione nazionale magistrati'', which after `secondo'' and before a comma read as no phrase at all', D6,
          'Según la asociación nacional magistrados, el perro duerme.'),
    nf_tr('Secondo l''associazione nazionale magistrati, il cane dorme.', italian, english, D7),
    check('... and English puts it before its noun, in the singular', D7,
          'According to the national magistrate association, the dog sleeps.'),
    nf_tr('La casa ha mangiato, dormito.', italian, spanish, D8),
    check('a participle after the comma of a perfect clause is the perfect''s and never agrees: `dormito'' after `ha mangiato'' is `dormido'', where it was predicated of the subject, `dormida''', D8,
          'La casa ha comido, dormido.'),
    nf_tr('Las casas han salido, llegado.', spanish, italian, D9),
    check('GUARD: a verb whose perfect the lesson builds with the copula agrees, as the participle after it does: `sono uscite, arrivate''', D9,
          'Le case sono uscite, arrivate.').

newspaper_ciampi_checks_5 :-
    nf_tr('Il cane vede l''articolo 74, primo codice.', italian, spanish, E1),
    check('an ordinal before a noun it agrees with is the noun''s adjective: `articolo 74, primo comma'' is the first paragraph, and `primo'' is the adverb `first'' as well -- read as the clause''s adverb it stood after the phrase and lost its apocope', E1,
          'El perro ve el artículo 74, primer código.'),
    nf_tr('Il cane mangia solo pane.', italian, english, E2),
    check('GUARD: and only an ordinal: `solo pane'' is only bread, and `solo'' is an adjective too, which English says where the words are the same in Spanish, `alone bread''', E2,
          'The dog eats bread only.'),
    nf_tr('Il cane vede legge codice.', italian, spanish, E3),
    check('two bare nouns are a compound, the second after the first as it stood: a headline''s `legge inappellabilità'', which the writer put in front, `inapelabilidad ley''', E3,
          'El perro ve ley código.'),
    nf_tr('Il cane vede legge codice.', italian, english, E4),
    check('... and English puts the second before the first', E4,
          'The dog sees code law.'),
    nf_tr('Il cane vede verde codice.', italian, english, E5),
    check('GUARD: a first noun that is an adjective too keeps its reading: `verde'' is green before its noun, and the head is the second word', E5,
          'The dog sees green code.'),
    nf_tr('Il cane mangia "pane tra cane e gatto" e il gatto dorme.', italian, english, E6),
    check('a word that closes a quotation begins no clause: `accusa e difesa" e le posizioni ... assumono'' divided at the first `e'', and the defence was a subject beside the positions', E6,
          'The dog eats "bread among dog and cat" and the cat sleeps.'),
    nf_tr('Este gato duerme.', spanish, english, E7),
    check('GUARD: and never a determiner that is a noun too: `este'' is this and east, and `este gato'' is this cat, where the compound took the east for the noun and the cat for what kind, `cat east''', E7,
          'This cat sleeps.').

newspaper_ciampi_checks_6 :-
    nf_tr('Il cane ha visto la casa dei gatti, lavata.', italian, spanish, F1),
    check('a participle after the comma of a perfect clause takes the form the source gave it where that is not the masculine singular: `lavata'' is the house washed, and read as the perfect''s it was `lavado'', where it agreed with the dog', F1,
          'El perro ha visto la casa de los gatos, lavada.'),
    nf_tr('La casa ha visto il cane dei gatti, lavata.', italian, spanish, F2),
    check('GUARD: and one the subject''s gender happens to match keeps it: `Una madre che ha perso la figlia, annegata in una piscina'' came out `ahogado'' when every participle after a comma was the perfect''s', F2,
          'La casa ha visto el perro de los gatos, lavada.'),
    nf_tr('Il cane li ha visti, lavati.', italian, spanish, F3),
    check('GUARD: a plural form after a pronoun before the verb is the perfect''s, which agrees with that pronoun in Italian and not in Spanish: `li ha visti, lavati'' is `los ha visto, lavado''', F3,
          'El perro los ha visto, lavado.'),
    nf_tr('La casa è uscita, arrivata.', italian, spanish, F4),
    check('a participle after a verb whose perfect the source builds with the copula is the perfect''s: `è uscita, arrivata'' agrees with the subject in Italian and is invariable in Spanish, `ha salido, llegado'', where the feminine form was taken for the daughter drowned', F4,
          'La casa ha salido, llegado.'),
    nf_tr('Il cane ritorna nella casa, e il pane.', italian, spanish, F5),
    check('a verb''s sense by its object counts only the verb''s own: a phrase after a coordinator is the conjunct of the complement before it, `ritorna nella casa, e il pane'' returns to the house and to the bread, and read as an object of the verb it took the sense that takes one, `devuelve''', F5,
          'El perro regresa en la casa, y el pan.'),
    nf_tr('Il cane ritorna il pane.', italian, spanish, F6),
    check('GUARD: an object of its own takes that sense still', F6,
          'El perro devuelve el pan.'),
    nf_tr('Il cane ritorna il pane, e il gatto.', italian, spanish, F7),
    check('GUARD: ... with a coordinator after it too', F7,
          'El perro devuelve el pan, y el gato.'),
    nf_tr('La casa è uscita, lavata.', italian, spanish, F8),
    check('GUARD: a participle of a verb that takes `avere'' after a copula''s perfect is the subject''s predicate and agrees in both: `è uscita, lavata'' is `ha salido, lavada'', where every participle after such a perfect was taken for its elided part, `lavado''', F8,
          'La casa ha salido, lavada.'),
    nf_tr('Il cane ritorna a mangiare il pane.', italian, spanish, F9),
    check('a verb''s sense counts no object after an infinitive, which is the infinitive''s: `torna ad affilare gli artigli'' goes back to sharpen the claws and `ritorna a mangiare il pane'' is `regresa a comer el pan'', where the bread was taken for what is returned and it came out `devuelve''', F9,
          'El perro regresa a comer el pan.'),
    nf_tr('Bisognerà mangiare il pane.', italian, english, F10),
    check('English has no future of `must'', and `will have to'' says it: `bisognerà leggere le motivazioni'' was refused, with nothing to write for it', F10,
          'One will have to eat the bread.'),
    nf_tr('Il cane dorme e "anche il gatto mangia".', italian, spanish, G1),
    check('a quotation that opens on an adverb the reader lifts out is the clause''s, as one that opens on an adjunct is: `ma "già ora si può dire che ..."'' has its mark on `già'', which is written after the verb, and the marks stood there, `come" "también''', G1,
          'El perro duerme y "el gato come también".'),
    nf_tr('Il cane dorme e "anche il gatto mangia".', italian, english, G2),
    check('... and in English', G2,
          'The dog sleeps and "the cat eats also".'),
    nf_tr('Il cane dice che "anche si dice che il gatto dorme".', italian, spanish, G3),
    check('... and the closing mark a clause the quotation holds carries on its verb is given up with it: the quotation closed on `duerme'''' and again on the adverb after it', G3,
          'El perro dice que "se dice que el gato duerme también".'),
    nf_tr('Il cane dice che "si dice che il gatto dorme".', italian, spanish, G4),
    check('GUARD: with no adverb to write after it the clause''s closing mark stays on its verb', G4,
          'El perro dice que "se dice que el gato duerme".'),
    nf_tr('Il cane dorme e "il gatto mangia anche".', italian, spanish, G5),
    check('GUARD: and an adverb that stood at the end of the quotation is the clause''s last word as it always was', G5,
          'El perro duerme y "el gato come también".').

%% two the hunk arms found: each hunk of the diff against 1.8.26 put back
%% alone, and these two were red on no check -- rules that were right and
%% that nobody had pinned
newspaper_ciampi_checks_7 :-
    nf_tr('Los perros modifican el código.', spanish, italian, H1),
    check('a verb''s plural is written as the verb''s and never as the noun''s: the lesson states `modifiche'', the modification''s plural, before the verb''s `modificano'', and the writer took the first plural it found, `I cani modifiche il codice''', H1,
          'I cani modificano il codice.'),
    nf_tr('Li mangiano i cani.', italian, english, H2),
    check('an object pronoun and the subject after the verb, in the plural: `Li mangiano i cani'' is the dogs eating them, and without the generic reading''s refusal it was they eating them with the dogs a second object, `They eat them the dogs'' -- which the singular never reaches', H2,
          'The dogs eat them.').

newspaper_omnium :-
    section('a Spanish report into Italian: a phrase whose noun was left out after the indefinite article, more than before an adjective, after as a connector, a relative clause after a preposition whose article says which noun it hangs on, a subject''s relative clause set off by commas, the agent after a copula''s infinitive, quotation marks on a purpose, a preposition''s infinitive, a gerund, a participle and an elided article, a clause with its `que'' left out after a verb that takes one, both ... and with a pronoun, half of which between dashes, the person a relative clause is about, a purpose after a phrase, a verb of two words in the future, a purpose in front, a month in a date, a name the lesson knows as a verb''s form, a determiner that takes the article'),
    newspaper_omnium_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_omnium_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_omnium_checks_1, newspaper_omnium_checks_2, newspaper_omnium_checks_3, newspaper_omnium_checks_4,
    newspaper_omnium_checks_5, newspaper_omnium_checks_6, newspaper_omnium_checks_7,
    reason_unlearn(italian), reason_unlearn(spanish).

%% each lesson in two parts, a clause over a page (8 KB) being one the store
%% cannot hold. What the vocabulary gives a word the lesson gives it too:
%% `una' the article, the determiner and the subjunctive of `unir', `para'
%% the purpose word, the preposition and a verb's form, `más' the
%% comparative and the preposition `plus', `que' the conjunction, the
%% relative and the word for than, `caso' the case and what `casar' says
%% of oneself, `tanto' the determiner and the conjunction, `como' the
%% partner, the preposition and a verb's form, `él' he and him, `la' the
%% article and the pronoun, and in Italian `il quale' in its four forms --
%% without those the old translator reads some of these right by luck, and
%% a check could not tell the two apart
newspaper_omnium_lesson(L, Text) :-
    newspaper_omnium_part(L, 1, A), newspaper_omnium_part(L, 2, B),
    atomic_list_concat([A, ' ', B], Text).

newspaper_omnium_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
The feminine determiner "una" means "some". "unas" is the plural of "una".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural. Every verb that ends in "e" takes "n" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The feminine noun "carta" means "letter".
The masculine noun "caso" means "case". "caso" is the first person of "casa".
The feminine noun "mitad" means "half". "mitades" is the plural of "mitad".
The masculine noun "miembro" means "member". "miembro" is a person.
The adjective "probable" means "probable". The masculine adjective "grande" means "big". "grandes" is the plural of "grande".
The masculine adjective "único" means "only". The feminine adjective "única" means "only".
The determiner "cada" means "each". The determiner "cada" means "every".
The number "dos" means "two".
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative. The conjunction "que" means "than".
The conjunction "pero" means "but". The conjunction "después de que" means "after".
The adverb "después" means "afterwards". The adverb "después" means "after".
The word "quien" begins the relative. "quien" is a relative.
The relative "el cual" means "which". The relative "la cual" means "which".
The relative "los cuales" means "which". The relative "las cuales" means "which".
The word "más" begins the comparative. The adverb "más" means "more". The preposition "más" means "plus".
The word "para" begins the purpose. The preposition "para" means "for". The intransitive verb "para" means "stops".
The word "con el fin de" begins the purpose.
The preposition "en" means "in". The preposition "de" means "of". The preposition "por" means "by". The preposition "por" means "for".
The preposition "a" means "to". The preposition "con" means "with".
The pronoun "él" means "he". The pronoun "él" means "him". The pronoun "él" does not precede the verb.
The pronoun "lo" means "it". The pronoun "lo" means "him". The pronoun "la" means "her". The pronoun "la" means "it".
The masculine determiner "tanto" means "so much". The conjunction "tanto" means "both". "como" is the partner of "tanto".
"como" is the first person of "come". The preposition "como" means "like". The preposition "como" means "as".').

newspaper_omnium_part(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
"comido" is the participle of "come". "comiendo" is the gerund of "come".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es". "sido" is the participle of "es".
The auxiliary "está" means "is". "están" is the plural of "está". The auxiliary "está" marks the state.
The auxiliary "ha" means "has". "han" is the plural of "ha".
The modal "debe" means "must". "deben" is the plural of "debe".
The verb "agrega" means "adds". "agrega" takes the clause.
The verb "acusa" means "accuses". The verb "envía" means "sends". The verb "da" means "gives".
The verb "une" means "unites". "una" is the subjunctive of "une".
The verb "informa" means "reports". "informará" is the future of "informa".
The feminine determiner "ambas" means "both". The determiner "ambos" means "both". The pronoun "ambos" means "both".
The pronoun "ambos" does not precede the verb.
The feminine noun "marcha" means "march". The masculine noun "marzo" means "march". "marzo" is a month. The word "de" joins the date.
The verb "porta" means "carries".
The pronoun "esto" means "this". The pronoun "esto" does not precede the verb.
The verb "sabe" means "knows". The adverb "además" means "besides".
The adverb "así" means "thus". "así" is the first person of "asió". "asió" is the past of "ase". The verb "ase" means "grasps".
The masculine noun "trabajo" means "work". The verb "trabaja" means "works". "trabajo" is the first person of "trabaja".
The verb "hace" means "makes". "hecho" is the participle of "hace".
The adverb "entonces" means "then". The verb "resulta" means "results".
The conjunction "aunque" means "although". The verb "pasa" means "happens". "pasado" is the participle of "pasa".
The masculine noun "pasado" means "past". "haya" is the subjunctive of "ha". The verb "hay" means "there is".
"haya" is the subjunctive of "hay".
The verb "asume" means "assumes". "asume" is the imperative of "asume". The verb "decapita" means "beheads".
"decapite" is the subjunctive of "decapita". The pronoun "yo" means "I". The pronoun "me" means "me".
The adjective "cultural" means "cultural". The adjective "común" means "common".').

newspaper_omnium_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "del" is the contraction of "di il".
"della" is the contraction of "di la". "al" is the contraction of "a il". "ai" is the contraction of "a i".
"dei" is the contraction of "di i". "dal" is the contraction of "da il".
"l''" is the elision of "lo". "l''" is the elision of "la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread".
The feminine noun "casa" means "house". "case" is the plural of "casa". The feminine noun "lettera" means "letter".
The masculine noun "caso" means "case".
The feminine noun "metà" means "half". The masculine noun "membro" means "member". "membro" is a person.
The adjective "probabile" means "probable". The masculine adjective "grande" means "big".
The masculine adjective "unico" means "only". The feminine adjective "unica" means "only".
The determiner "ogni" means "each". The determiner "ogni" means "every".
The number "due" means "two".
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative. The word "che" means "than".
The conjunction "ma" means "but". The conjunction "dopo che" means "after".
"cui" is a relative. The word "cui" follows the preposition.
"quale" is a relative. "quali" is a relative. "quali" is the plural of "quale".
The word "più" begins the comparative. The adverb "più" means "more".
The word "per" begins the purpose. The preposition "per" means "for".
The word "al fine di" begins the purpose.
The preposition "in" means "in". The preposition "di" means "of". The preposition "da" means "by".
The preposition "a" means "to". The preposition "con" means "with".
The pronoun "lui" means "he". The pronoun "lui" means "him". The pronoun "lui" does not precede the verb.
The pronoun "lo" means "it". The pronoun "lo" means "him". The pronoun "la" means "her". The pronoun "la" means "it".
The masculine determiner "tanto" means "so much". The conjunction "tanto" means "both". "quanto" is the partner of "tanto".
The relative "il quale" means "who". The relative "la quale" means "who". The relative "i quali" means "who". The relative "le quali" means "who".').

newspaper_omnium_part(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangiato" is the participle of "mangia". "mangiando" is the gerund of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è".
"stato" is the participle of "è". "è" is the auxiliary of "è".
The auxiliary "sta" means "is". "stanno" is the plural of "sta".
The auxiliary "ha" means "has". "hanno" is the plural of "ha".
The modal "deve" means "must". "devono" is the plural of "deve".
The verb "aggiunge" means "adds".
The verb "accusa" means "accuses". The verb "invia" means "sends". The verb "dà" means "gives".
The verb "fa" means "makes". "farà" is the future of "fa". The verb "fa sapere" means "reports".
The masculine determiner "entrambi" means "both". "entrambi" is the plural of "entrambi". "entrambi" takes the article.
The feminine determiner "entrambe" means "both". "entrambe" is the plural of "entrambe". "entrambe" takes the article.
The feminine noun "marcia" means "march". The masculine noun "marzo" means "march". "marzo" is a month.
The pronoun "questo" means "this". The pronoun "questo" does not precede the verb.
The masculine demonstrative "questo" means "this". "quest''" is the elision of "questo".
The verb "sa" means "knows". The adverb "inoltre" means "besides". The adverb "così" means "thus".
The masculine noun "lavoro" means "work". The verb "lavora" means "works". "lavoro" is the first person of "lavora".
"fatto" is the participle of "fa". The verb "prende" means "grasps". "presi" is the past of "prende".
The adverb "quindi" means "then". The verb "risulta" means "results". "risulta" takes the clause.
The conjunction "nonostante" means "although". The verb "avviene" means "happens". "avvenuto" is the participle of "avviene".
"è" is the auxiliary of "avviene". The masculine noun "passato" means "past". The verb "c''è" means "there is".
The verb "assume" means "assumes". "assumi" is the imperative of "assume". The verb "decapita" means "beheads".
"decapito" is the first person of "decapita". The pronoun "io" means "I". The pronoun "mi" means "me".
The adjective "culturale" means "cultural".
The noun "comune" means "town council". "comune" is not feminine. The adjective "comune" means "common".
The feminine noun "corrente" means "current". The adjective "corrente" means "common".').

newspaper_omnium_checks_1 :-
    nf_tr('El perro ve dos casas, una para cada gato.', spanish, italian, A1),
    check('the indefinite article with its noun left out and a preposition after it is a phrase: `una para cada candidatura'' is one for each, and `una'' is the subjunctive of `unir'' too -- read as a clause, `para'' was the verb `stops'' and the sentence was refused', A1,
          'Il cane vede due case, una per ogni gatto.'),
    nf_tr('El perro ve dos casas, una para cada gato.', spanish, english, A2),
    check('... and in English', A2,
          'The dog sees two houses, one for each cat.'),
    nf_tr('En el más que probable caso, el perro duerme.', spanish, italian, A3),
    check('`more than'' before an adjective is the adjective''s: `el más que probable caso'', where `más'' was the preposition `plus'' and `que'' the relative, and the sentence was refused', A3,
          'Nel caso più che probabile, il cane dorme.'),
    nf_tr('En el más que probable caso, el perro duerme.', spanish, english, A4),
    check('... and in English', A4,
          'In the more than probable case, the dog sleeps.'),
    nf_tr('El perro duerme después de que el gato come el pan.', spanish, italian, A5),
    check('a conjunction of three words the lesson states: `después de que'' is after, where `después'' was the adverb and `de que'' a noun''s clause with no noun', A5,
          'Il cane dorme dopo che il gatto mangia il pane.'),
    nf_tr('El perro duerme después de que el gato come el pan.', spanish, english, A6),
    check('... and English writes `after'' as a connector, which it had no word for', A6,
          'The dog sleeps after the cat eats the bread.').

newspaper_omnium_checks_2 :-
    nf_tr('El perro envía una carta a los gatos en la que el pan duerme.', spanish, italian, B1),
    check('a relative clause after a preposition whose article is not the nearest noun''s number hangs on the noun before: `una carta a los 16.000 socios en la que'' is the letter, and read as the members'' clause the article disagreed and the sentence was refused', B1,
          'Il cane invia una lettera ai gatti in cui il pane dorme.'),
    nf_tr('El perro envía una carta a los gatos en la que el pan duerme.', spanish, english, B2),
    check('... and in English', B2,
          'The dog sends a letter to the cats in which the bread sleeps.'),
    nf_tr('El perro, que come el pan, duerme.', spanish, italian, B3),
    check('a subject''s relative clause set off by commas keeps them: `Esta propuesta, que debería ser refrendada ..., se produce'', where the subject is read with its commas out and both were lost', B3,
          'Il cane, che mangia il pane, dorme.'),
    nf_tr('El perro, que come el pan, duerme.', spanish, english, B4),
    check('... and English writes `which'' for one set off', B4,
          'The dog, which eats the bread, sleeps.'),
    nf_tr('El perro que come el pan duerme.', spanish, italian, B5),
    check('GUARD: and one with no commas has none', B5,
          'Il cane che mangia il pane dorme.'),
    nf_tr('El pan debe ser comido por el perro.', spanish, italian, B6),
    check('a copula''s infinitive and a participle are a passive, and `por'' after them is its agent: `debería ser refrendada por los miembros'', where the agent was a phrase of `for'', `per il cane''', B6,
          'Il pane deve essere mangiato dal cane.').

newspaper_omnium_checks_3 :-
    nf_tr('El perro acusa a Maria de "comer el pan".', spanish, italian, C1),
    check('a quotation that opens on the infinitive after a preposition opens there: `de "hacer trampa"'' came out `di fare trappola"'', the closing mark with no opening one', C1,
          'Il cane accusa Maria di "mangiare il pane".'),
    nf_tr('El perro come el pan "para dormir".', spanish, italian, C2),
    check('a quotation that opens on the purpose word opens on the purpose: `"para evitar ..."'' -- the word is a verb''s form too, and the mark was taken for one on the clause''s verb, `"mangia"''; and one that closes on its infinitive keeps both marks', C2,
          'Il cane mangia il pane "per dormire".'),
    nf_tr('El perro come el pan "para dormir" y el gato duerme.', spanish, italian, C3),
    check('... before a second clause too', C3,
          'Il cane mangia il pane "per dormire" e il gatto dorme.'),
    nf_tr('El perro está "comiendo" el pan.', spanish, italian, C4),
    check('a quotation on a progressive''s gerund, the last word of its group: `están "sufriendo"'' came out `stanno soffrendo'', the marks lost', C4,
          'Il cane sta "mangiando" il pane.'),
    nf_tr('El pan está "comido".', spanish, italian, C5),
    check('... and on a participle after the copula: `está "abierto a cualquier negociación"''', C5,
          'Il pane è "mangiato".'),
    nf_tr('La "única casa" duerme.', spanish, italian, C6),
    check('an elided article before a word that opens a quotation keeps the mark between them: `la "única preocupación"'' is `l''"unica preoccupazione"'', where the article joined the word and the mark was lost', C6,
          'L''"unica casa" dorme.'),
    nf_tr('La "única" casa duerme.', spanish, italian, C7),
    check('... and a word the quotation opens and closes on', C7,
          'L''"unica" casa dorme.').

newspaper_omnium_checks_4 :-
    nf_tr('Maria agrega el perro duerme.', spanish, italian, D1),
    check('a clause with its `que'' left out, in the indicative, after a verb the lesson says takes the clause: `agregó la "única preocupación" del sector renovador es decapitarle'', and the writer puts the word back', D1,
          'Maria aggiunge che il cane dorme.'),
    nf_tr('Maria agrega el pan.', spanish, italian, D2),
    check('GUARD: and a phrase alone is its object', D2,
          'Maria aggiunge il pane.'),
    nf_tr('Tanto él como el gato duermen.', spanish, italian, D3),
    check('both ... and with a pronoun that stands alone: `tanto él como los actuales miembros'', where `él'' is him too and the subject''s shape refused it', D3,
          'Tanto lui quanto il gatto dormono.'),
    nf_tr('Tanto él como el gato duermen.', spanish, english, D4),
    check('... and in English', D4,
          'Both he and the cat sleep.'),
    nf_tr('Los perros - - la mitad de los cuales duermen - - comen el pan.', spanish, italian, D5),
    check('half of which between dashes is the phrase''s aside, and the relative after its preposition takes the article of the noun it stands for: `la mitad de los cuales'' is `la metà dei quali'', where it was `di cui''', D5,
          'I cani – la metà dei quali dormono – mangiano il pane.'),
    nf_tr('Los perros - - la mitad de los cuales duermen - - comen el pan.', spanish, english, D6),
    check('... and in English, where the relative''s verb had a subject of its own, `which they sleep''', D6,
          'The dogs – the half of which sleep – eat the bread.').

newspaper_omnium_checks_5 :-
    nf_tr('Maria, a quien el perro ve, duerme.', spanish, italian, E1),
    check('the word before a person and a relative word is the relative clause''s object where the clause has a subject and no object of its own: `a quien el perro ve'' is whom the dog sees, `che'', where it was a phrase of `to'', `a cui''; and the commas are kept', E1,
          'Maria, che il cane vede, dorme.'),
    nf_tr('Maria, a quien el perro da el pan, duerme.', spanish, italian, E2),
    check('... and with an object of its own it is the one given to: `a quien los renovadores atribuyen un comportamiento'', `a cui''', E2,
          'Maria, a cui il cane dà il pane, dorme.'),
    nf_tr('El perro come con el gato con el fin de dormir.', spanish, italian, E3),
    check('a purpose word of several words after a phrase ends the phrase: `con la oposición con el fin de "encontrar ..."'', where the phrase ran on and the sentence was refused', E3,
          'Il cane mangia con il gatto per dormire.'),
    nf_tr('El perro come con el gato con el fin de dormir.', spanish, english, E4),
    check('... and in English', E4,
          'The dog eats with the cat to sleep.'),
    nf_tr('El perro informará el pan.', spanish, italian, E5),
    check('a verb of several words is made by its first word: `fa sapere'' is `farà sapere'', and the lesson states the forms of `fa'' and none of the whole, so the future was refused', E5,
          'Il cane farà sapere il pane.').

newspaper_omnium_checks_6 :-
    nf_tr('Para comer, el perro duerme.', spanish, italian, F1),
    check('a purpose in front, to its comma: `Para demostrarlo, esgrimió una papeleta'', where the piece had no reading', F1,
          'Per mangiare, il cane dorme.'),
    nf_tr('El perro duerme el 7 de marzo.', spanish, italian, F2),
    check('a month in a date is written with the word the lesson calls a month: `las elecciones del 7 de marzo'', where the first Italian word for `march'' is a march, `la 7 marcia''', F2,
          'Il cane dorme il 7 marzo.'),
    nf_tr('El perro da a Porta el pan.', spanish, italian, F3),
    check('a capitalised word the lesson knows only as a verb''s form is a name inside a sentence: `dijo haber propuesto a Porta la confección'', where `porta'' is what `portar'' says of one person and the phrase ran on through the article after it', F3,
          'Il cane dà a Porta il pane.'),
    nf_tr('El perro ve ambas casas.', spanish, italian, F4),
    check('a determiner the lesson says takes the article is written with it: `por ambas partes'' is `per entrambe le parti'', where it was `entrambe parti''', F4,
          'Il cane vede entrambe le case.').

%% three the hunk arms found: each hunk of the diff against 1.8.27 put back
%% alone, and these three were red on no check -- each carries a line of the
%% report's text, and nobody had pinned it
newspaper_omnium_checks_7 :-
    nf_tr('El perro come esto y duerme.', spanish, italian, G1),
    check('a word that could be elided is not elided before a coordinator: `para merecer todo esto y puede ser'' is `tutto questo e può essere'', where `questo'' is a determiner as well as a pronoun and was joined to the conjunction, `quest''e''', G1,
          'Il cane mangia questo e dorme.'),
    nf_tr('El perro sabe que el gato come, pero, además, duerme.', spanish, italian, G2),
    check('the comma after a coordinator opens the next clause''s insertion, never an aside of the clause before: `..., pero, aun así, dijo haber propuesto ...'', where the aside took the coordinator''s comma and nothing read the sentence', G2,
          'Il cane sa che il gatto mangia, ma, inoltre, dorme.'),
    nf_tr('"El gato come el pan; el perro duerme".', spanish, italian, G3),
    check('a whole sentence in the plain mark with a semicolon in it gives its two marks to the sentence: `"No sé ... yo mismo; así, trabajo hecho".'' was cut at its semicolon, each part tokenised by itself, and the first part''s mark closed on its own last word', G3,
          '"Il gatto mangia il pane; il cane dorme".'),
    nf_tr('Así, trabajo hecho.', spanish, italian, G4),
    check('a piece that opens on an adverb and a comma is a punctuated front, never a verb of the whole: `así, trabajo hecho'' is thus, job done, and `así'' is also what `asir'' says of the first person in the past -- read as that verb Italian wrote `presi'', I took. (The rest reads as `trabajo'', I work, and a participle: the Italian words are the same either way, and the IR is wrong -- a cost)', G4,
          'Così, lavoro fatto.'),
    nf_tr('Il cane risulta grande, quindi il gatto dorme.', italian, spanish, G5),
    check('GUARD: a clause with its `que'' left out in the indicative only straight after its verb: `è sempre risultato spento, quindi l''uomo aveva lanciato l''allarme'' is two clauses joined by `quindi'', and the first cut read the second as the clause of `risulta'', `entonces que el hombre'' -- Livata''s ninth', G5,
          'El perro resulta grande, entonces el gato duerme.'),
    nf_tr('El perro come, aunque haya pasado.', spanish, italian, G6),
    check('the subjunctive of the auxiliary before a participle is the perfect, never `there is'': a line of this report says `haya'' is what `hay'' says in the subjunctive too, and the England column''s `aunque haya pasado casi inadvertido'' came out `c''è passato'', the past a thing there was', G6,
          'Il cane mangia, nonostante è avvenuto.'),
    nf_tr('El perro sabe que asume el pan.', spanish, italian, G7),
    check('a clause read inside another is no command: `Apuntó que asume las críticas'' is that he takes them, and `asume'' is the imperative too -- read as one, `che assumi''', G7,
          'Il cane sa che assume il pane.'),
    nf_tr('El perro sabe que me decapite yo.', spanish, italian, G8),
    check('a present subjunctive''s first person is spelled as its third, and a sentence that names the first person may read it so: `puede ser que me decapite yo mismo'' is that I behead myself, where the one reading had `me'' for the object, `mi decapita''', G8,
          'Il cane sa che mi decapito io.'),
    nf_tr('En la carta a Omar, el perro duerme.', spanish, italian, G9),
    check('with no verb read, a person after `a'' is the preposition''s: `En declaraciones a Europa Press, Millàs consideró ...'', where the person object a front cannot take refused the sentence', G9,
          'Nella lettera a Omar, il cane dorme.'),
    nf_tr('El miembro de Omnium Cultural, Omar, duerme.', spanish, italian, G10),
    check('a name of capitals with an adjective the lesson knows in it is a name, with a name set off after it: `de la entidad catalanista Òmnium Cultural, Josep Millàs,''', G10,
          'Il membro di Omnium Cultural, Omar, dorme.'),
    nf_tr('La casa común duerme.', spanish, italian, G11),
    check('an adjective''s gender is the one the lesson states of the word, never one a rule about nouns proves: `comune'' is a noun too, and `Every noun that does not end in "a" is masculine'' made the adjective masculine -- the Solana report''s `seguridad común'' came out `sicurezza corrente''', G11,
          'La casa comune dorme.').

newspaper_astro :-
    section('an Italian report into Spanish: an article with its capital inside a phrase begins a name, a quoted title after a phrase, a plain mark whose blank stands on the wrong side, a phrase with an article set off after a phrase with a relative clause after it, an agent with its relative clause after a comma, a quotation that opens on a relative word, a relative clause whose gap is the subject of a clause the verb takes, the agent before its participle, a reporting clause between dashes between two clauses and between commas between two quotations, a time anywhere in a front, a front never inside a list, a count with a comma, a front that ends before an infinitive, a subject after its verb with its `di'' phrases, a name after a noun, a name before an adjective, a person the others agree with, a time after the word for by, an infinitive''s `a'', a copula''s complement, a modal with an adverb, a relative clause with an aside'),
    newspaper_astro_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_astro_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_astro_checks_1, newspaper_astro_checks_2, newspaper_astro_checks_3, newspaper_astro_checks_4,
    newspaper_astro_checks_5, newspaper_astro_checks_6, newspaper_astro_checks_7,
    reason_unlearn(italian), reason_unlearn(spanish).

%% each lesson in two parts, a clause over a page (8 KB) being one the store
%% cannot hold. What the vocabulary gives a word the lesson gives it too, and
%% in the vocabulary's order: `aeronautica' the noun first and the adjective
%% after it, `militare' the soldier (a person) and the adjective, `italiana'
%% the adjective and the noun (a person), `sapienza' wisdom, `prima' first,
%% `lui' he and him, `da' by and from, `che' that, than and a relative word,
%% `deve' owes and the modal -- without those the old translator reads some
%% of these right by luck, and a check could not tell the two apart
newspaper_astro_lesson(L, Text) :-
    newspaper_astro_part(L, 1, A), newspaper_astro_part(L, 2, B),
    atomic_list_concat([A, ' ', B], Text).

newspaper_astro_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a". "un''" is the elision of "una".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "nello" is the contraction of "in lo".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dello" is the contraction of "di lo".
"al" is the contraction of "a il". "alla" is the contraction of "a la". "allo" is the contraction of "a lo".
"dal" is the contraction of "da il". "dalla" is the contraction of "da la". "dallo" is the contraction of "da lo".
"sul" is the contraction of "su il". "sulla" is the contraction of "su la". "sullo" is the contraction of "su lo".
"l''" is the elision of "lo". "l''" is the elision of "la". "dell''" is the elision of "della". "nell''" is the elision of "nella".
"all''" is the elision of "alla". "dall''" is the elision of "dalla".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not". The word "che" means "than".
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". "pani" is the plural of "pane".
The feminine noun "casa" means "house". "case" is the plural of "casa". The feminine noun "tavola" means "table".
The masculine noun "libro" means "book". The masculine noun "corso" means "course".
The masculine noun "tema" means "topic". "tema" is not feminine.
The feminine noun "missione" means "mission". "missioni" is the plural of "missione". "missione" is feminine.
The masculine noun "spazio" means "space". The masculine noun "futuro" means "future".
The feminine noun "università" means "university". "università" is the plural of "università".
The feminine noun "sapienza" means "wisdom".
The masculine noun "astronauta" means "astronaut". "astronauta" is not feminine. "astronauta" is a person.
The masculine noun "genere" means "kind". The masculine noun "centro" means "centre".
The masculine noun "addestramento" means "training". The feminine noun "tuta" means "suit".
The masculine noun "bambino" means "child". "bambino" is a person.
The masculine noun "anno" means "year". "anno" is a time. The masculine noun "febbraio" means "february". "febbraio" is a month.
The masculine noun "scopo" means "aim". The feminine noun "possibilità" means "possibility".
The feminine noun "aeronautica" means "aeronautics". The masculine noun "militare" means "soldier". "militare" is a person.
The masculine adjective "umano" means "human". The feminine adjective "umana" means "human". "umane" is the plural of "umana".
The masculine adjective "primo" means "first". The feminine adjective "prima" means "first".
The masculine adjective "prossimo" means "next".
The feminine adjective "aeronautica" means "aeronautical". The adjective "militare" means "military".
The masculine determiner "altro" means "another". "altri" is the plural of "altro".
The masculine noun "martedì" means "tuesday". "martedì" is a time.
The masculine adjective "italiano" means "Italian". The feminine adjective "italiana" means "Italian".
The feminine noun "italiana" means "Italian". "italiana" is a person.
The masculine adjective "grande" means "big". The masculine adjective "stanco" means "tired". The feminine adjective "stanca" means "tired".
The number "due" means "two". The number "tre" means "three".
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative.
The masculine demonstrative "questo" means "this". The masculine possessive "tuo" means "your".
The preposition "in" means "in". The preposition "di" means "of". The preposition "da" means "by". The preposition "da" means "from".
The preposition "a" means "to". The preposition "con" means "with". The preposition "su" means "on". The preposition "per" means "for".
The pronoun "lui" means "he". The pronoun "lui" means "him". The pronoun "lui" does not precede the verb.
The adverb "poi" means "then".').

newspaper_astro_part(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangiato" is the participle of "mangia". "mangerà" is the future of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è". "stato" is the participle of "è".
"sarà" is the future of "è". "sia" is the subjunctive of "è". "è" is the auxiliary of "è".
The auxiliary "ha" means "has". "hanno" is the plural of "ha".
The verb "deve" means "owes". The modal "deve" means "must". "devono" is the plural of "deve".
The modal "può" means "can". "possono" is the plural of "può". "potrebbe" is the conditional of "può".
The verb "dice" means "says". "dice" takes the clause.
The pronoun "io" means "I". "mangio" is the first person of "mangia".
The verb "esiste" means "exists". "esiste" is intransitive.
The verb "parte" means "starts". "è" is the auxiliary of "parte".
The verb "diventa" means "becomes". "diventare" is the infinitive of "diventa". "è" is the auxiliary of "diventa".
The verb "sembra" means "seems". The verb "comincia" means "begins".
The verb "lava" means "washes". "lavare" is the infinitive of "lava".
The verb "spera" means "hopes". "spera" takes the clause. "spero" is the first person of "spera".
The verb "offre" means "offers". "offerto" is the participle of "offre".
The verb "usa" means "uses". "usato" is the participle of "usa". "usata" is the participle of "usa". "usata" is feminine.
The reflexive pronoun "si" means "itself".
"eaten" is the participle of "eats".
The verb "dispone" means "places". "disposto" is the participle of "dispone".
The feminine noun "laurea" means "degree". The verb "laurea" means "graduates". "laurea" is the imperative of "laurea".
The feminine noun "astronautica" means "astronautics". The feminine noun "parte" means "part".
The verb "riesce" means "manages". "riesce" takes "a" before the infinitive.
The feminine possessive "sua" means "his". The feminine adjective "sua" means "hers". The masculine adjective "grato" means "grateful".
The feminine noun "forma" means "form". The verb "forma" means "forms".').

newspaper_astro_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural. Every verb that ends in "e" takes "n" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The feminine noun "mesa" means "table". The masculine noun "libro" means "book".
The masculine noun "curso" means "course". The masculine noun "tema" means "topic". "tema" is not feminine.
The feminine noun "misión" means "mission". "misiones" is the plural of "misión".
The masculine noun "espacio" means "space". The masculine noun "futuro" means "future".
The feminine noun "universidad" means "university". "universidades" is the plural of "universidad".
The feminine noun "cordura" means "wisdom". The masculine noun "astronauta" means "astronaut". "astronauta" is not feminine. "astronauta" is a person.
The masculine noun "género" means "kind". The masculine noun "centro" means "centre".
The masculine noun "entrenamiento" means "training". The masculine noun "traje" means "suit".
The masculine noun "niño" means "child". "niño" is a person.
The masculine noun "año" means "year". "año" is a time. The masculine noun "febrero" means "february". "febrero" is a month.
The masculine noun "objetivo" means "aim". The feminine noun "posibilidad" means "possibility".
The feminine noun "aeronáutica" means "aeronautics". The masculine noun "militar" means "soldier". "militar" is a person.
The masculine adjective "humano" means "human". The feminine adjective "humana" means "human".
"humanos" is the plural of "humano". "humanas" is the plural of "humana".
The masculine adjective "primero" means "first". The feminine adjective "primera" means "first". "primer" is the apocope of "primero".
The masculine adjective "próximo" means "next".
The feminine adjective "aeronáutica" means "aeronautical". The adjective "militar" means "military".
The masculine determiner "otro" means "another". "otros" is the plural of "otro".
The masculine noun "martes" means "tuesday". "martes" is a time.
The masculine adjective "italiano" means "Italian". The feminine adjective "italiana" means "Italian".
The masculine adjective "grande" means "big". The masculine adjective "cansado" means "tired". The feminine adjective "cansada" means "tired".
The number "dos" means "two". The number "tres" means "three".
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative.
The masculine demonstrative "este" means "this". The possessive "tu" means "your".
The preposition "en" means "in". The preposition "en" means "on". The preposition "de" means "of".
The preposition "por" means "by". The preposition "desde" means "from".
The preposition "a" means "to". The preposition "con" means "with". The preposition "para" means "for".
The pronoun "él" means "he". The pronoun "él" means "him". The pronoun "él" does not precede the verb.
The adverb "luego" means "then".').

newspaper_astro_part(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "come" means "eats". "comer" is the infinitive of "come". "comido" is the participle of "come". "comerá" is the future of "come".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es". "sido" is the participle of "es".
"será" is the future of "es". "sea" is the subjunctive of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha".
The verb "debe" means "owes". The modal "debe" means "must". "deben" is the plural of "debe".
The modal "puede" means "can". "podría" is the conditional of "puede".
The verb "dice" means "says". "dice" takes the clause.
The verb "existe" means "exists". The verb "parte" means "starts".
The verb "llega a ser" means "becomes". "llegar a ser" is the infinitive of "llega a ser".
The verb "parece" means "seems". The verb "comienza" means "begins".
The verb "lava" means "washes". "lavar" is the infinitive of "lava".
The verb "espera" means "hopes". "espero" is the first person of "espera".
The verb "ofrece" means "offers". "ofrecido" is the participle of "ofrece".
The verb "usa" means "uses". "usado" is the participle of "usa".
The reflexive pronoun "se" means "itself".
The verb "dispone" means "places". "dispuesto" is the participle of "dispone".
The masculine noun "grado" means "degree". The verb "gradúa" means "graduates". "gradúa" is the imperative of "gradúa".
The feminine noun "astronáutica" means "astronautics".
The verb "logra" means "manages".
The possessive "su" means "his". The feminine adjective "suya" means "hers". The masculine adjective "agradecido" means "grateful".
The feminine noun "forma" means "form". The verb "forma" means "forms".
The word "qué" means "which". The verb "ignora" means "ignores". "ignoran" is the plural of "ignora". "ignora" takes the question.
The verb "trae" means "brings". "traerá" is the future of "trae".
The noun "consecuencia" means "consequence". "consecuencias" is the plural of "consecuencia".').

newspaper_astro_checks_1 :-
    nf_tr('Il cane dorme nell''università La Sapienza.', italian, spanish, A1),
    check('an article with its capital after a noun or a preposition begins a name: `presso la "scuola di ingegneria aerospaziale" dell''università La Sapienza'' names the university, and read as the article and the noun `sapienza'', wisdom, it came out `La Cordura''', A1,
          'El perro duerme en la universidad La Sapienza.'),
    nf_tr('Il cane dorme nell''università La Sapienza.', italian, english, A2),
    check('... and in English, where it was `The Wisdom''', A2,
          'The dog sleeps in the university La Sapienza.'),
    nf_tr('Il cane dorme sul tema "spazio al tuo futuro".', italian, spanish, A3),
    check('a quoted title after a phrase is the phrase''s, read as the complements it is and written after it: `sul tema "spazio al tuo futuro"'' is the theme called that, and the title''s first noun was the phrase''s noun with the theme for its adjective, `en el "espacio tema a tu futuro"''', A3,
          'El perro duerme en el tema "espacio a tu futuro".'),
    nf_tr('Il cane dorme sul tema "spazio al tuo futuro".', italian, english, A4),
    check('... and in English, where it was `on the "space topic to your future"''', A4,
          'The dog sleeps on the topic "space to your future".'),
    nf_tr('Il cane dorme sul tema" spazio al tuo futuro "".', italian, spanish, A5),
    check('two plain closing marks in a row, the first straight after a word, are a pair whose first mark lost its place, and it opens: the report''s own `sul tema" spazio al tuo futuro ""'' was refused, the title read as a clause of its own between two boundaries. The mark at the end is the source''s and is kept', A5,
          'El perro duerme en el tema "espacio a tu futuro"".'),
    nf_tr('Il cane dorme sul tema" spazio al tuo futuro "".', italian, english, A6),
    check('... and in English', A6,
          'The dog sleeps on the topic "space to your future"".'),
    nf_tr('Il cane vede il libro "grande".', italian, spanish, A7),
    check('GUARD: one word in quotation marks after a noun is no title -- it says what kind -- and stays the adjective it is', A7,
          'El perro ve el libro "grande".'),
    nf_tr('Il cane vede martedì il corso "missioni umane nello spazio".', italian, spanish, A8),
    check('GUARD: a time before a phrase and its title: the first cut found the title behind a cut that committed the phrase''s words to it before the phrase before it was asked, and `Parte martedì il corso "missioni umane nello spazio" con l''astronauta italiano'' had no phrase words at all -- refused, as this was', A8,
          'El perro ve martes el curso "misiones humanas en el espacio".').

newspaper_astro_checks_2 :-
    nf_tr('Il cane dorme con il gatto, il primo del genere, che mangia il pane.', italian, spanish, B1),
    check('a phrase with an article set off after a phrase, with a relative clause after its closing comma, is the phrase''s aside: `con il corso "missioni umane nello spazio", il primo del genere in Europa, che sarà tenuto ...'' is the course, the first of its kind, and read as the clause''s own the first one was a second object with the word before a person in front of it, `al primero''', B1,
          'El perro duerme con el gato, el primero del género, que come el pan.'),
    nf_tr('Il cane vede il corso "missioni umane nello spazio", il primo del genere, che il gatto mangia.', italian, spanish, B2),
    check('... and after a title, whose phrase takes the aside''s key with it', B2,
          'El perro ve el curso "misiones humanas en el espacio", el primero del género, que el gato come.'),
    nf_tr('Il cane mangia il pane offerto dal gatto, che dorme.', italian, spanish, B3),
    check('a reduced relative''s agent keeps the relative clause after its comma: `la possibilità offerta dall''università, che spero si concretizzi'' -- read to the comma the agent failed, and `dall''università'' was a phrase of `from'', `desde el gato''', B3,
          'El perro come el pan ofrecido por el gato, que duerme.'),
    nf_tr('Il cane mangia il pane offerto dal gatto, che dorme.', italian, english, B4),
    check('... and in English, where it was `the offered bread from the cat'' -- and with the comma read as the participle''s own complement, the relative clause was no aside of the agent and English wrote `that sleeps''', B4,
          'The dog eats the bread offered by the cat, which sleeps.'),
    nf_tr('Il cane vede la casa, "che è grande".', italian, spanish, B5),
    check('a quotation that opens on a relative word keeps its mark on the word the writer puts there: `a Colonia, "che però non è fornito di laboratori ...'' lost the mark with the relative word, and the quotation only closed', B5,
          'El perro ve la casa, "que es grande".'),
    nf_tr('Il cane vede la casa, "che è grande".', italian, english, B6),
    check('... and in English', B6,
          'The dog sees the house, "which is big".'),
    nf_tr('Il cane vede la casa, che spero sia grande.', italian, spanish, B7),
    check('a relative clause whose gap is the subject of a clause the verb takes, with its `che'' left out: `la possibilità ..., che spero si concretizzi'' is one I hope comes true, and read with the relative word for the object of `spero'' the clause had nobody for its subject -- `que espero que es grande'' put the left-out word back after the relative, which no language here says', B7,
          'El perro ve la casa, que espero es grande.'),
    nf_tr('Il cane vede la casa, che spero sia grande.', italian, english, B8),
    check('... and English, which cannot say `which I hope that is big'', refused it', B8,
          'The dog sees the house, which I hope is big.'),
    nf_tr('Il cane vede la tuta da lui usata.', italian, spanish, B9),
    check('the agent before its participle: `una studentessa che indossa la tuta da lui usata nelle missioni spaziali'' wears the suit HE used, and the phrase ended at `da'', `desde él usado''', B9,
          'El perro ve el traje usado por él.'),
    nf_tr('Il cane vede la tuta da lui usata.', italian, english, B10),
    check('... and in English, where it was `the suit from him used''', B10,
          'The dog sees the suit used by him.').

newspaper_astro_checks_3 :-
    nf_tr('Il cane dorme - dice Maria - il gatto mangia il pane.', italian, spanish, C1),
    check('a reporting clause between dashes, between two clauses each of its own, stays where it stood: `"che però non è fornito di laboratori - sottolinea Filippo Graziani, preside ... - gli astronauti devono poi concludere la preparazione ...'' had two clauses and nothing between them once the dashes were taken out, and was refused', C1,
          'El perro duerme – dice Maria – el gato come el pan.'),
    nf_tr('Il cane dorme - dice Maria - il gatto mangia il pane.', italian, english, C2),
    check('... and in English', C2,
          'The dog sleeps – Maria says – the cat eats the bread.'),
    nf_tr('Il cane - dice Maria - mangia il pane.', italian, spanish, C3),
    check('GUARD: and between a subject and its verb it goes after the sentence, as it always did -- the side after the dashes names no subject of its own', C3,
          'El perro come el pan – dice Maria –.'),
    nf_tr('Il cane vede la casa, "che non è grande - dice Maria - il gatto mangia il pane.', italian, spanish, C4),
    check('... and the report''s own shape, a relative clause in marks before the dashes: the reporting clause went after the sentence and the opening mark was lost, `que no es grande el gato come el pan – dice Maria –''', C4,
          'El perro ve la casa, "que no es grande – dice Maria – el gato come el pan.'),
    nf_tr('"Il cane dorme", dice Maria, "il gatto mangia il pane".', italian, spanish, C5),
    check('a reporting clause between two quotations, set off by commas, stays between them: `"gli italiani possono ricoprire un importantissimo ruolo ...", spiega Vittori, "nel corso cercherò ...'' was written with the speaker after both, inside the second quotation, `"el gato come el pan, dice Maria"''', C5,
          '"El perro duerme", dice Maria, "el gato come el pan".'),
    nf_tr('"Il cane dorme", dice Maria, "il gatto mangia il pane".', italian, english, C6),
    check('... and in English', C6,
          '"The dog sleeps", Maria says, "the cat eats the bread".'),
    nf_tr('"Il gatto dorme", dice Maria, "nel corso il cane mangia il pane.', italian, spanish, C7),
    check('... and a quotation that opens on a front the writer moves is the clause''s: the mark goes on the first word written, where it went with `nel corso'' into the middle, `el perro come el pan "en el curso''', C7,
          '"El gato duerme", dice Maria, "el perro come el pan en el curso.'),
    nf_tr('"Il gatto dorme", dice Maria, "nel corso il cane mangia il pane.', italian, english, C8),
    check('... and in English', C8,
          '"The cat sleeps", Maria says, "the dog eats the bread in the course.').

newspaper_astro_checks_4 :-
    nf_tr('A questo scopo il prossimo febbraio, il cane mangia il pane.', italian, spanish, D1),
    check('a time or a month anywhere in a front is when: `A questo scopo il prossimo 24 gennaio nel tempio di Adriano, a Roma, si terrà un''iniziativa ...'' has the date after a phrase of its own, and with a time taken only first the month was an object in front, and the sentence was refused', D1,
          'A este objetivo el próximo febrero, el perro come el pan.'),
    nf_tr('A questo scopo il prossimo febbraio, il cane mangia il pane.', italian, english, D2),
    check('... and in English', D2,
          'To this aim the next february, the dog eats the bread.'),
    nf_tr('Nel corso il cane dorme sulla casa, sulla tavola e sul libro.', italian, spanish, D3),
    check('a front with no comma goes after the clause''s complements and never into a list, between two phrases of one preposition: `nel corso cercherò di illustrare una missione ... sullo shuttle, sulla navicella Soyuz e la Iss'' went after the first, `en la casa en el curso, en la mesa''', D3,
          'El perro duerme en la casa, en la mesa y en el libro en el curso.'),
    nf_tr('Nel corso il cane dorme sulla casa, sulla tavola e sul libro.', italian, english, D4),
    check('... and in English', D4,
          'The dog sleeps on the house, on the table and on the book in the course.'),
    nf_tr('Il cane mangia altri due, tre pani.', italian, spanish, D5),
    check('a comma between two numbers before their noun is the count''s: `hanno bisogno di altri due, tre anni'' is two or three more years, and divided at the comma `altri due'' was another two, `otro dos''', D5,
          'El perro come otros dos, tres panes.'),
    nf_tr('Con il cane, che mangia il pane, dormire è grande.', italian, spanish, D6),
    check('a front ends at a comma with an infinitive after it, the subject an infinitive names: `con determinazione, impegno e la possibilità offerta dall''università, che spero si concretizzi, diventare astronauta è un obiettivo'' -- longest first, the relative clause ran over its comma and took the infinitive, and the front kept a comma too many, `dormir, es grande''', D6,
          'Con el perro, que come el pan, dormir es grande.'),
    nf_tr('Con il cane, che mangia il pane, dormire è grande.', italian, english, D7),
    check('... and English, whose verb had nobody for its subject, refused it', D7,
          'With the dog, which eats the bread, to sleep is big.').

newspaper_astro_checks_5 :-
    nf_tr('In Europa esiste un centro di addestramento.', italian, spanish, E1),
    check('the subject after an intransitive verb with an adjunct in front keeps its `di'' phrases: `Fino ad oggi in Europa esiste un solo centro di addestramento Esa'' -- the shortest phrase that agrees was the subject and the rest the verb''s, `Un centro existe en Europa de entrenamiento''', E1,
          'Un centro de entrenamiento existe en Europa.'),
    nf_tr('In Europa esiste un centro di addestramento.', italian, english, E2),
    check('... and in English', E2,
          'A centre of training exists in Europa.'),
    nf_tr('Il cane vede un centro di addestramento Esa.', italian, spanish, E3),
    check('a name of one word no lesson knows after a noun in small letters is the phrase''s apposed name: `un solo centro di addestramento Esa'' was refused', E3,
          'El perro ve un centro de entrenamiento Esa.'),
    nf_tr('Roma potrebbe diventare la Houston italiana.', italian, spanish, E4),
    check('a name right after the determiner, before a word that is an adjective too, is the phrase''s head: `potrebbe diventare la Houston italiana'' is the Italian Houston, and read with `italiana'', an Italian woman, for the noun, the city was set before it, `el italiano Houston''', E4,
          'Roma podría llegar a ser la Houston italiana.'),
    nf_tr('Il cane vede l''aeronautica militare.', italian, spanish, E5),
    check('among nouns that are adjectives too, the one the lesson calls a person is the head only where the others agree with it: `con il supporto dell''aeronautica militare'' is the air force, and `militare'', a soldier, is masculine, which the feminine `aeronautica'' could say nothing of -- Spanish marked it as a person object, `al aeronáutica militar''', E5,
          'El perro ve la aeronáutica militar.'),
    nf_tr('Il cane vede l''aeronautica militare.', italian, english, E6),
    check('... and in a noun''s place a meaning the lesson links to the noun is never passed over for its shape: `aeronautics'' ends as a verb''s third person does and gave way to the adjective''s `aeronautical'', `the aeronautical soldier'' -- the fault that wrote 1.8.20''s `una laurea in fisica'' as `en físico''', E6,
          'The dog sees the military aeronautics.').

newspaper_astro_checks_6 :-
    nf_tr('Il pane sarà mangiato dal prossimo anno.', italian, spanish, F1),
    check('a time after the word for `by'' in a passive is when, never its agent: `verrà istituzionalizzato ... già dal prossimo anno accademico'', where the year did it, `por el próximo año''', F1,
          'El pan será comido desde el próximo año.'),
    nf_tr('Il pane sarà mangiato dal prossimo anno.', italian, english, F2),
    check('... and in English, where it was `by the next year''', F2,
          'The bread will be eaten from the next year.'),
    nf_tr('Il cane mangia il pane offerto dal prossimo anno.', italian, spanish, F3),
    check('... and after the word for `by'' after a participle standing after its noun: the reduced relative''s agent was the year, `ofrecido por el próximo año''', F3,
          'El perro come el pan ofrecido desde el próximo año.'),
    nf_tr('Il cane comincia a lavarsi.', italian, spanish, F4),
    check('an infinitive with its pronoun joined keeps the `a'' before it: `Vittori, disposto a dedicarsi alla docenza'' lost it, and `comincia a lavarsi'' came out `comienza lavarse''', F4,
          'El perro comienza a lavarse.'),
    nf_tr('Il cane sembra un bambino.', italian, spanish, F5),
    check('a verb whose complement says what the subject is takes no word before a person after it: `potrebbe diventare la Houston italiana'' could become the city, a name and so a person, `llegar a ser a la Houston''; and `sembra un bambino'', 1.8.25''s stated cost, came out `parece a un niño''', F5,
          'El perro parece un niño.'),
    nf_tr('Il cane deve poi mangiare il pane.', italian, english, F6),
    check('a modal with an adverb between it and its infinitive is the modal: `gli astronauti devono poi concludere la preparazione'' must then finish it, and English said the dog owed to, `owes to eat''', F6,
          'The dog must eat the bread then.'),
    nf_tr('Un pane che Mario, disposto a dormire, mangia.', italian, spanish, F7),
    check('a phrase whose relative clause has an aside between its subject and its verb reads as a line with no verb of its own: `un''idea che Vittori, disposto a dedicarsi alla docenza ..., non esita a definire coraggiosa'' -- the comma that closes the aside was taken for one between two pieces, and the line was refused', F7,
          'Un pan que Mario, dispuesto a dormir, come.'),
    nf_tr('Un pane che Mario, disposto a dormire, mangia: il cane dorme.', italian, spanish, F8),
    check('... and before a colon', F8,
          'Un pan que Mario, dispuesto a dormir, come: el perro duerme.'),
    nf_tr('Con Vittori laurea in astronautica.', italian, spanish, F9),
    check('a headline that opens on a preposition and a name, then a bare noun the lesson calls an imperative too, with only prepositional phrases after it: `Con Vittori laurea in astronautica.'' is with Vittori, a degree in astronautics, and read as the command `laurea'', graduate, it came out `Gradúa en astronáutica con Vittori''', F9,
          'Con Vittori grado en astronáutica.'),
    nf_tr('Con Vittori laurea in astronautica.', italian, english, F10),
    check('... and in English, where it was `Graduate in astronautics with Vittori''', F10,
          'With Vittori degree in astronautics.'),
    nf_tr('Con Maria parte per Roma.', italian, spanish, F11),
    check('GUARD: only a form the lesson calls an imperative: `parte'' is the noun part and what `partire'' says, and `Con Maria parte per Roma'' is somebody leaving for Rome, as it always was -- read as a headline it was `Con Maria parte para Roma''', F11,
          'Parte para Roma con Maria.').

newspaper_astro_checks_7 :-
    nf_tr('Il cane dorme, "nella casa" il gatto mangia il pane.', italian, spanish, G1),
    check('GUARD: a quotation that opens on a front and closes inside it is the front''s, and the writer moves it with both its marks: the twelve''s `Il blitz è riuscito, "dal punto di vista tattico" l''operazione è considerata già conclusa'' came out on this version''s first cut with the whole clause quoted, `"la operación es considerada ya concluida desde el punto de vista táctico"''', G1,
          'El perro duerme, el gato come el pan "en la casa".'),
    nf_tr('Il cane è grato - dice Maria - al gatto che vede la sua forma grande.', italian, spanish, G2),
    check('GUARD: a reporting clause between dashes stays between two clauses only where the side after them opens on its subject: Fiat''s `Sarò per sempre grato - aggiunge Marchionne - al team di leadership ... che oggi assume la sua forma definitiva'' has the rest of one clause after the dashes, and the first cut read it as a clause of its own, with `forma'' for its verb and `la sua'' for its subject, `que hoy asume la suya forma definitiva''', G2,
          'El perro es agradecido al gato que ve su forma grande – dice Maria –.'),
    nf_tr('Il cane riesce a lavarsi.', italian, spanish, G3),
    check('GUARD: the `a'' before an infinitive with its pronoun joined is the verb''s own where the lesson says the verb takes it before its infinitive, and the writer asks the other language''s verb: the Fregene report''s `è riuscito a dirmi'' is `ha logrado decirme'', and the first cut wrote `ha logrado a decirme''', G3,
          'El perro logra lavarse.'),
    ( reason_ir('Los perros ignoran "qué consecuencias" traerá para la casa "la mesa que ve" el gato.', spanish, IRG4) -> true ; IRG4 = refused ),
    yes_no(IRG4 = [ir(s(_, _, g(ignores, _, _, _), [wh(_, _)]), _)], G4),
    check('GUARD: a quoted run that opens on its own article is a phrase of its own and no title: the Òmnium report''s `desconocen "qué consecuencias" reportará para la imagen de la entidad "la movida que está montando" el sector renovador'' -- read with the stir for the entity''s title, the rest read as a reporting clause, the sentence was divided after the first quoted run and `qué'' was an adjective, `ignorano "cose conseguenze"''. The question stays the verb''s', G4,
          yes),
    %% English's I is a capital with a quotation mark on it too: the
    %% writer's clauses that put a mark on a word came before the one that
    %% makes `i' a capital. Older than this version: 1.8.28 writes `"i eat'
    nf_tr('"Il cane dorme", dice Maria, "io mangio il pane.', italian, english, G5),
    check('English''s I is a capital with a quotation mark on it too: `", spiega Vittori, "nel corso cercherò di illustrare'' wrote `"i will search''', G5,
          '"The dog sleeps", Maria says, "I eat the bread.').

newspaper_senegal :-
    section('a Spanish report into Italian: what follows a coordinator or an adverb at the head is no command spelled as a third person, the word a verb puts before its question, adjectives joined before a name, a name of several words in small letters, a participle with its agent in front, a participle before its noun, an exclamation with no mark, whose, a heading in capitals with a name in it, a quotation that closes on a name, a reporting clause with its relative clause, the word before a person and a list, a front after a time clause that is whole, a participle with its agent as a second aside, a subordinate clause with asides and no comma, an adverb after the predicate adjective'),
    newspaper_senegal_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_senegal_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_senegal_checks_1, newspaper_senegal_checks_2, newspaper_senegal_checks_3,
    newspaper_senegal_checks_4, newspaper_senegal_checks_5,
    reason_unlearn(spanish), reason_unlearn(italian).

%% each lesson in two parts, a clause over a page (8 KB) being one the store
%% cannot hold. What the vocabulary gives a word the lesson gives it too, and
%% in the vocabulary's order: `duerme', `come' and `sabe' commands as well as
%% third persons, `pronto' the adjective prompt and the adverb soon,
%% `menudo' small and exclamative, `joven' a youngster and young, `les
%% lions' a lion and a name -- without those the old translator reads some of
%% these right by luck, and a check could not tell the two apart
newspaper_senegal_lesson(L, Text) :-
    newspaper_senegal_part(L, 1, A), newspaper_senegal_part(L, 2, B),
    atomic_list_concat([A, ' ', B], Text).

newspaper_senegal_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The masculine noun "perro" means "dog". The masculine noun "gato" means "cat". The masculine noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The masculine noun "nombre" means "name".
The masculine noun "hombre" means "man". "hombre" is a person.
The masculine noun "joven" means "youngster". "joven" is a person. "jóvenes" is the plural of "joven".
The adjective "joven" means "young".
The masculine noun "momento" means "moment". "momento" is a time.
The masculine noun "campeón" means "champion". "campeón" is a person.
The feminine noun "batalla" means "battle". The feminine noun "plaga" means "plague".
The masculine noun "escenario" means "stage". The feminine noun "federación" means "federation".
The masculine noun "técnico" means "coach". "técnico" is a person. The masculine noun "testigo" means "witness". "testigo" is a person.
The masculine noun "millón" means "million". "millones" is the plural of "millón". The feminine noun "persona" means "person". "persona" is a person.
The masculine noun "león" means "lion". The masculine noun "les lions" means "lion". "les lions" is the plural of "les lions". "les lions" is a name.
The feminine adjective "hermosa" means "beautiful". The feminine adjective "cautivadora" means "captivating".
The adjective "convaleciente" means "convalescent". The adjective "familiar" means "familiar".
The masculine adjective "pronto" means "prompt". The adverb "pronto" means "soon". The adverb "muy" means "very".
The masculine adjective "cansado" means "tired". The masculine adjective "grande" means "big". The adjective "gran" means "great".
The adverb "sólo" means "only". The adverb "ayer" means "yesterday". The adverb "luego" means "then".
The masculine adjective "menudo" means "small". "menudo" is exclamative.
The masculine determiner "cuyo" means "whose". "cuyo" is a relative.
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative.
The conjunction "si" means "if". The conjunction "cuando" means "when".
The word "quién" means "who".
The preposition "en" means "in". The preposition "de" means "of". The preposition "por" means "by". The preposition "por" means "for".
The preposition "a" means "to". The preposition "con" means "with". The preposition "sin" means "without".
The reflexive pronoun "se" means "itself". The pronoun "lo" means "him".').

newspaper_senegal_part(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
"duerme" is the imperative of "duerme". "duermas" is the negative imperative of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
"come" is the imperative of "come". "comas" is the negative imperative of "come".
The verb "sabe" means "knows". "saben" is the plural of "sabe". "sabe" is the imperative of "sabe". "sepas" is the negative imperative of "sabe".
The verb "posee" means "possesses". "posee" is the imperative of "posee". "poseas" is the negative imperative of "posee".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es". "sido" is the participle of "es". "será" is the future of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha". "hubiera" is the past subjunctive of "ha". "habría" is the conditional of "ha".
The verb "llega" means "arrives". "llega" is intransitive. "llegaron" is the past of "llegan". "llegan" is the plural of "llega".
The verb "pregunta" means "asks". "preguntar" is the infinitive of "pregunta". "pregunta" takes "por" before the question.
The verb "busca" means "searches". "buscado" is the participle of "busca".
The verb "encuentra" means "finds". "encontrado" is the participle of "encuentra".
The verb "hace" means "makes". "hará" is the future of "hace".
The verb "lidera" means "leads". "liderado" is the participle of "lidera". "liderados" is the participle of "lidera". "liderados" is the plural of "liderado".
The verb "salpica" means "taints". "salpicada" is the participle of "salpica". "salpicada" is feminine.
The verb "emociona" means "thrills". "emocionado" is the participle of "emociona".
The verb "rinde" means "surrenders". "rendido" is the participle of "rinde". The verb "entrega" means "hands". "entregado" is the participle of "entrega".
The verb "dice" means "says". "dijo" is the past of "dice". The verb "añade" means "adds". "añadió" is the past of "añade".
The verb "muestra" means "shows". "mostró" is the past of "muestra".
The verb "tiene" means "has". "teniendo" is the gerund of "tiene".
"led" is the participle of "leads". "said" is the past of "says". "found" is the participle of "finds".').

newspaper_senegal_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "del" is the contraction of "di il". "della" is the contraction of "di la".
"dal" is the contraction of "da il". "dalla" is the contraction of "da la". "al" is the contraction of "a il".
"l''" is the elision of "lo". "l''" is the elision of "la". "d''" is the elision of "di".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The masculine noun "cane" means "dog". "cani" is the plural of "cane". The masculine noun "gatto" means "cat". "gatti" is the plural of "gatto".
The masculine noun "pane" means "bread". The feminine noun "casa" means "house". The masculine noun "nome" means "name".
The masculine noun "uomo" means "man". "uomini" is the plural of "uomo". "uomo" is a person.
The masculine noun "giovane" means "youngster". "giovane" is a person. The adjective "giovane" means "young".
The masculine noun "momento" means "moment". "momento" is a time.
The masculine noun "campione" means "champion". "campione" is a person.
The feminine noun "battaglia" means "battle". The feminine noun "piaga" means "plague".
The masculine noun "palcoscenico" means "stage". The feminine noun "federazione" means "federation".
The masculine noun "tecnico" means "coach". "tecnici" is the plural of "tecnico". "tecnico" is a person. The masculine noun "testimone" means "witness". "testimoni" is the plural of "testimone". "testimone" is a person.
The masculine noun "milione" means "million". "milioni" is the plural of "milione". The feminine noun "persona" means "person". "persone" is the plural of "persona". "persona" is a person.
The masculine noun "leone" means "lion".
The feminine adjective "bella" means "beautiful". The adjective "accattivante" means "captivating".
The adjective "convalescente" means "convalescent". The adjective "familiare" means "familiar".
The masculine adjective "pronto" means "prompt". The adverb "presto" means "soon". The adverb "molto" means "very".
The masculine adjective "stanco" means "tired". The masculine adjective "grande" means "big". The adjective "grande" means "great".
The adverb "solo" means "only". The adverb "ieri" means "yesterday". The adverb "poi" means "then".
The masculine adjective "piccolo" means "small". The word "che" means "what".
The masculine determiner "il cui" means "whose". "il cui" is a relative.
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative.
The conjunction "se" means "if". The conjunction "quando" means "when".
The word "chi" means "who".
The preposition "in" means "in". The preposition "di" means "of". The preposition "da" means "by". The preposition "per" means "for".
The preposition "a" means "to". The preposition "con" means "with". The preposition "senza" means "without".
The reflexive pronoun "si" means "itself". The pronoun "lo" means "him".').

newspaper_senegal_part(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
"dormi" is the imperative of "dorme". "dormire" is the negative imperative of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangia" is the imperative of "mangia". "mangiare" is the negative imperative of "mangia".
The verb "sa" means "knows". "sanno" is the plural of "sa". "sappi" is the imperative of "sa".
The verb "possiede" means "possesses". "possiedi" is the imperative of "possiede".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è". "stato" is the participle of "è". "sarà" is the future of "è".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "aveva" is the past of "ha". "avrebbe" is the conditional of "ha".
The verb "arriva" means "arrives". "arrivano" is the plural of "arriva". "arrivarono" is the past of "arrivano".
The verb "chiede" means "asks". "chiedere" is the infinitive of "chiede".
The verb "cerca" means "searches". "cercato" is the participle of "cerca".
The verb "trova" means "finds". "trovato" is the participle of "trova".
The verb "fa" means "makes". "farà" is the future of "fa".
The verb "guida" means "leads". "guidato" is the participle of "guida". "guidati" is the participle of "guida". "guidati" is the plural of "guidato".
The verb "macchia" means "taints". "macchiata" is the participle of "macchia". "macchiata" is feminine.
The verb "emoziona" means "thrills". "emozionato" is the participle of "emoziona".
The verb "arrende" means "surrenders". "arreso" is the participle of "arrende". The verb "consegna" means "hands". "consegnato" is the participle of "consegna".
The verb "dice" means "says". "disse" is the past of "dice". The verb "aggiunge" means "adds". "aggiunse" is the past of "aggiunge".
The verb "mostra" means "shows". "mostrò" is the past of "mostra".
The verb "ha" means "has". "avendo" is the gerund of "ha".').

newspaper_senegal_checks_1 :-
    nf_tr('Y duerme.', spanish, italian, A1),
    check('what follows a coordinator at the head is no command spelled as a third person: `Y sabe lo que quiere: jugar de forma sencilla'' is and HE knows what he wants, and `sabe'' is also the command `know!'', which the imperative reader, tried before a third person nobody named, took -- `E conosci quello che vuole''', A1,
          'E dorme.'),
    nf_tr('Sólo duerme.', spanish, italian, A2),
    check('... and nor is what follows an adverb lifted from the head: `(sólo posee 5.000 licencias)'' came out `possiedi 5.000 licenze soltanto'', possess!', A2,
          'Dorme solo.'),
    nf_tr('Y no comas el pan.', spanish, italian, A3),
    check('GUARD: a denied command after a coordinator stays a command: the first cut refused every command there and read it as what he does not eat', A3,
          'E non mangiare il pane.'),
    nf_tr('Sólo cómelo.', spanish, italian, A4),
    check('GUARD: a command with its pronoun joined stays a command after a lifted adverb, as no person''s form takes a pronoun joined: the first cut refused `Solo levántate.''', A4,
          'Mangialo solo.'),
    nf_tr('El perro pregunta por quién come el pan.', spanish, italian, A5),
    check('the word a verb puts before its question is the verb''s: `sin preguntar por quién tiene delante'' is without asking who he has in front of him -- `"pregunta" takes "por" before the question.'' Read as a phrase of `por'', the question word was a person the asking was for and the clause after it had no reading', A5,
          'Il cane chiede chi mangia il pane.'),
    nf_tr('El perro duerme sin preguntar por quién come el pan.', spanish, italian, A6),
    check('... after its infinitive too, which is the article''s', A6,
          'Il cane dorme senza chiedere chi mangia il pane.').

newspaper_senegal_checks_2 :-
    nf_tr('La hermosa, joven y cautivadora Maria come el pan.', spanish, italian, B1),
    check('adjectives joined before a name are one phrase with it: `la hermosa, joven y cautivadora Senegal le concedió ayer la mayor alegría'' -- the subject was divided at `y'', whose guard asked for a noun at the end and not a name, and `joven'' was a youngster', B1,
          'La bella, giovane e accattivante Maria mangia il pane.'),
    nf_tr('La hermosa, joven y cautivadora Maria come el pan.', spanish, english, B2),
    check('... and in English', B2,
          'The beautiful, young and captivating Maria eats the bread.'),
    nf_tr('Llegaron les lions de Maria.', spanish, italian, B3),
    check('a name of several words in small letters, where the lesson says it is one (`"les lions" is a name.''), is a name in the number the lesson states and crosses as itself: `llegaron les lions de Bruno Metsu'' read as the noun it also is, a lion, singular, and no plural verb agreed with it', B3,
          'Arrivarono les lions di Maria.'),
    nf_tr('Llegaron les lions de Maria.', spanish, english, B4),
    check('... and in English, the subject first', B4,
          'Les lions of Maria arrived.'),
    nf_tr('Ayer, liderados por un joven, los perros comen el pan.', spanish, italian, B5),
    check('a participle with its agent in front, said of the subject, is written back in front in the subject''s number (fpart/4): `En un santiamén, liderados por un joven ..., ridiculizaron al campeón'' -- divided at the commas, the participle was a clause of its own, and here its agent a phrase of `for'', `guidati per un giovane''', B5,
          'Ieri, guidati da un giovane, i cani mangiano il pane.'),
    nf_tr('Un emocionado Juan come el pan.', spanish, italian, B6),
    check('a participle before its noun is said of it as an adjective before its noun is (pptc/1): `proclamó un emocionado Bruno Metsu'' -- the lesson gives the word no adjective, and the phrase had no reading', B6,
          'Un emozionato Juan mangia il pane.'),
    nf_tr('Un rendido y entregado Juan come el pan.', spanish, italian, B7),
    check('... two of them joined: `un rendido y entregado Roger Lemerre''', B7,
          'Un arreso e consegnato Juan mangia il pane.').

newspaper_senegal_checks_3 :-
    nf_tr('Menudo pan.', spanish, italian, C1),
    check('a word the lesson calls exclamative, at the head of its piece, says an exclamation with no `!'' after it: `Menudo inicio.'' -- what a start; read as the adjective small before a noun with no article, the piece was a phrase with nothing said of it and was refused', C1,
          'Che pane.'),
    nf_tr('Menudo pan.', spanish, english, C2),
    check('... and in English', C2, 'What bread.'),
    nf_tr('El joven cuyo perro come el pan duerme.', spanish, italian, C3),
    check('a relative that is the determiner of a phrase in its own clause: `un joven cuyo nombre se hará familiar muy pronto'' -- whose name. It stands in no gap, and agrees with its own phrase''s noun', C3,
          'Il giovane il cui cane mangia il pane dorme.'),
    nf_tr('El joven cuyo perro come el pan duerme.', spanish, english, C4),
    check('... and in English', C4, 'The youngster whose dog eats the bread sleeps.'),
    nf_tr('JUAN RENDIDO.', spanish, italian, C5),
    check('a word no lesson knows in a heading in capitals is a name, spelled with its capital: `LEMERRE RENDIDO.'' -- lowered, `lemerre'' was a word no lesson knows and the heading was refused', C5,
          'Juan arreso.'),
    nf_tr('"El perro es un gran Juan", dijo ayer el gato.', spanish, english, C6),
    check('a quotation that closes on a name is followed by its reporting clause: `"Ha sido un gran Senegal", dijo ayer un rendido y entregado Roger Lemerre'' -- the mark travels on the name, and the clause after it was read as a statement with nobody named and the speaker its object', C6,
          '"The dog is a great Juan", the cat said yesterday.'),
    nf_tr('"El perro duerme", añadió el técnico, que se mostró cansado.', spanish, italian, C7),
    check('a reporting clause whose speaker has a relative clause after a comma: `añadió el técnico, que se mostró "tremendamente desolado"'' -- the clause hangs on the speaker, where the phrase took the comma and the clause in and agreed with nothing; the relative clause came out before the reporting verb', C7,
          '"Il cane dorme", aggiunse il tecnico, che si mostrò stanco.').

newspaper_senegal_checks_4 :-
    nf_tr('El perro tiene por testigos a los técnicos y millones de personas.', spanish, italian, D1),
    check('the word before a person marks the class of a list''s first item: `teniendo por testigos directos a 62.561 espectadores y millones y millones de personas'' -- asked of both items, the millions were no persons, and the list was a phrase of `to'', `a i tecnici''', D1,
          'Il cane ha per testimoni i tecnici e milioni di persone.'),
    nf_tr('El perro ve a los técnicos y los gatos.', spanish, italian, D2),
    check('... whatever the second item is', D2,
          'Il cane vede i tecnici e i gatti.'),
    nf_tr('Cuando el perro duerme, en la casa, llegaron los gatos.', spanish, italian, D3),
    check('an adjunct between two commas after a clause of `when'' that has its verb is the MAIN clause''s front: `Cuando el mundo había girado su vista hacia Seúl, en el primer día del Mundial ..., llegaron les lions'' -- taken as an aside set in the time clause (1.8.14''s `che la "Bastiglia", qui da noi, non mi risulta''), the words had no comma left to divide at, and the sentence was refused', D3,
          'Quando il cane dorme, nella casa, i gatti arrivarono.'),
    nf_tr('Cuando el perro duerme, en la casa, llegaron los gatos.', spanish, english, D4),
    check('... and in English', D4, 'When the dog sleeps, in the house, the cats arrived.').

newspaper_senegal_checks_5 :-
    nf_tr('La FIFA, convaleciente de una batalla, salpicada por la plaga, ha buscado un escenario.', spanish, italian, E1),
    check('a participle with its agent is a second aside after a name''s first: `Si la FIFA, convaleciente de una cruenta batalla interna, salpicada por la plaga de la corrupción, hubiera buscado ...'' -- read as the subject''s reduced relative, its closing comma was lost, `macchiata dalla piaga ha cercato''', E1,
          'La FIFA, convalescente d''una battaglia, macchiata dalla piaga, ha cercato un palcoscenico.'),
    ( reason_ir('La federación, convaleciente de una batalla, salpicada por la plaga, ha buscado un escenario.', spanish, IRE2) -> true ; IRE2 = refused ),
    yes_no(IRE2 = [ir(s(_, app(app(_, aside, _), aside, part(taints, _)), _, _), _)], E2),
    check('... and after a noun''s adjective aside, where the text came out the same from a reduced relative and the subject''s comma (the IR)', E2, yes),
    nf_tr('Si la FIFA, convaleciente de una batalla, hubiera buscado un escenario no lo habría encontrado.', spanish, italian, E3),
    check('a subordinate clause with asides in it, and no comma before its main clause: the division there allowed no comma anywhere in the piece, and the article''s eighth sentence was refused. The main clause holds none, and the subordinate clause ends on none', E3,
          'Se la FIFA, convalescente d''una battaglia, aveva cercato un palcoscenico non l''avrebbe trovato.'),
    nf_tr('El nombre se hará familiar muy pronto.', spanish, italian, E4),
    check('a word that is an adjective and an adverb, last in the clause after the predicate adjective, is the clause''s adverb: `cuyo nombre se hará familiar muy pronto'' is familiar very soon -- read as the noun `familiar'' with `muy pronto'' its adjective, it was very prompt', E4,
          'Il nome si farà familiare molto presto.'),
    nf_tr('El nombre será familiar pronto.', spanish, italian, E5),
    check('... and with no degree word, where it was one list of two adjectives, `familiare pronto''', E5,
          'Il nome sarà familiare presto.').

newspaper_eco :-
    section('an Italian column into Spanish: a Roman numeral, who said so between dashes, names with commas to the end of the piece, a partitive pronoun beside a quantity, as one thing so another, a clause of since set off between a subject and its verb, a front that ends on a name apposed to its noun, a clause of che in front, an adjective alone for a subject, which by itself, a phrase in front taken up by a pronoun, an infinitive for a subject, the impersonal of a reflexive verb, a gerund cleft, not only ... but, the only ones not to, an article before an infinitive, a clause to compare with, how much, the partner of a denial'),
    newspaper_eco_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_eco_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_eco_checks_1, newspaper_eco_checks_2, newspaper_eco_checks_3, newspaper_eco_checks_4,
    newspaper_eco_checks_5, newspaper_eco_checks_6, newspaper_eco_checks_7, newspaper_eco_checks_8,
    newspaper_eco_checks_9, newspaper_eco_checks_10, newspaper_eco_checks_11, newspaper_eco_checks_12,
    reason_unlearn(italian), reason_unlearn(spanish).

%% each lesson in three parts, a clause over a page (8 KB) being one the store
%% cannot hold. What the vocabulary gives a word the lesson gives it too, and
%% in the vocabulary's order: `mondo' a noun and a verb's first person,
%% `fosse' pits and the copula's subjunctive, `calcoli' calculations and a
%% verb's second person, `colombo' a pigeon, `anche' hips, `morti' deaths and
%% the dead, `forse' maybe before perhaps, `i quali' the relative -- without
%% those the old translator reads some of these right by luck, and a check
%% could not tell the two apart
newspaper_eco_lesson(L, Text) :-
    newspaper_eco_part(L, 1, A), newspaper_eco_part(L, 2, B), newspaper_eco_part(L, 3, C),
    atomic_list_concat([A, ' ', B, ' ', C], Text).

newspaper_eco_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"l''" is the elision of "lo". "l''" is the elision of "la". "d''" is the elision of "di".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "nei" is the contraction of "in i".
"del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i". "degli" is the contraction of "di gli". "delle" is the contraction of "di le".
"dal" is the contraction of "da il". "dalla" is the contraction of "da la". "al" is the contraction of "a il". "alla" is the contraction of "a la". "ai" is the contraction of "a i". "agli" is the contraction of "a gli".
"sul" is the contraction of "su il". "sulla" is the contraction of "su la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not". The word "non" precedes the verb. The adverb "no" means "no".
The masculine noun "cane" means "dog". "cani" is the plural of "cane". The masculine noun "gatto" means "cat". "gatti" is the plural of "gatto".
The masculine noun "pane" means "bread". The feminine noun "casa" means "house". "case" is the plural of "casa".
The masculine noun "uomo" means "man". "uomini" is the plural of "uomo". "uomo" is a person.
The masculine noun "autore" means "author". "autori" is the plural of "autore". "autore" is a person.
The feminine noun "cosa" means "thing". "cose" is the plural of "cosa". The word "cosa" means "what".
The masculine noun "secolo" means "century". "secoli" is the plural of "secolo". "secolo" is a time.
The masculine noun "fatto" means "fact". "fatti" is the plural of "fatto". "fatto" is the participle of "fa". "fatto" takes the clause.
The masculine noun "mondo" means "world". "mondi" is the plural of "mondo". "mondo" is the first person of "monda".
The masculine noun "libro" means "book". The masculine noun "giardino" means "garden". The feminine noun "carne" means "meat".
The masculine noun "topo" means "mouse". "topi" is the plural of "topo". The masculine noun "continente" means "continent".
The masculine noun "profitto" means "profit". The feminine noun "terra" means "earth". The masculine noun "centro" means "centre".
The masculine noun "colombo" means "pigeon". The feminine noun "fossa" means "pit". "fosse" is the plural of "fossa".
The feminine noun "era" means "era". "ere" is the plural of "era".
The masculine noun "calcolo" means "calculation". "calcoli" is the plural of "calcolo".
The masculine adjective "nero" means "black". "neri" is the plural of "nero". The masculine adjective "bianco" means "white". "bianchi" is the plural of "bianco".
The adjective "grande" means "big". "grandi" is the plural of "grande". The masculine adjective "piccolo" means "small". The feminine adjective "piccola" means "small". "piccole" is the plural of "piccola". The masculine adjective "vecchio" means "old".
The masculine adjective "stanco" means "tired". The masculine adjective "rotondo" means "round". The masculine adjective "buono" means "good". "buoni" is the plural of "buono". The feminine adjective "buona" means "good".
The feminine adjective "bella" means "beautiful". "belle" is the plural of "bella". "bellissime" is the superlative of "belle".
The feminine adjective "piatta" means "flat". The masculine adjective "piatto" means "flat". The adjective "immobile" means "motionless".
The masculine adjective "pazzesco" means "crazy". "pazzeschi" is the plural of "pazzesco". The masculine adjective "preciso" means "precise". "precisi" is the plural of "preciso".
The masculine adjective "unico" means "only". "unici" is the plural of "unico". The adjective "speciale" means "special".
The masculine possessive "suo" means "his". The number "due" means "two".
The masculine adjective "greco" means "greek". The masculine noun "cristiano" means "christian". "cristiano" is a person. The masculine adjective "cristiano" means "christian".
The masculine adjective "solo" means "alone". "soli" is the plural of "solo". The adverb "solo" means "only".
The adverb "molto" means "very". The masculine determiner "molto" means "much". "molti" is the plural of "molto".
The masculine pronoun "alcuno" means "some". "alcuni" is the plural of "alcuno". The pronoun "alcuno" does not precede the verb.
The pronoun "quello" means "that". The pronoun "quello" does not precede the verb. The word "quello" replaces the noun.
The masculine demonstrative "quello" means "that". "quel" is the apocope of "quello". "quei" is the plural of "quel". "quelli" is the plural of "quello".
The feminine noun "morte" means "death". "morti" is the plural of "morte". The masculine adjective "morto" means "dead". "morti" is the plural of "morto".
The feminine demonstrative "questa" means "this". "queste" is the plural of "questa".').

newspaper_eco_part(italian, 2, 'The adverb "allora" means "then". The adverb "poi" means "then". The adverb "quindi" means "then".
The adverb "giustamente" means "precisely". The adverb "anche" means "also". "anche" is the plural of "anca".
The adverb "persino" means "even". The adverb "forse" means "maybe". The adverb "forse" means "perhaps". The adverb "almeno" means "at least". The adverb "ci" means "there". The adverb "bene" means "well".
The adverb "quanto" means "as much". "quanto" is the partner of "tanto". The word "quanto" means "how much".
The masculine determiner "tanto" means "so much". The conjunction "tanto" means "both". The adverb "tanto" means "as".
The adverb "così" means "thus". "così" is the partner of "come".
The word "come" means "how". The preposition "come" means "like". The preposition "come" means "as".
The conjunction "e" means "and". The conjunction "ed" means "and". The conjunction "ma" means "but". The conjunction "bensì" means "but".
The conjunction "che" means "that". "che" is a relative. The conjunction "se" means "if". The conjunction "mentre" means "while".
The conjunction "siccome" means "since". The conjunction "quando" means "when".
The conjunction "sia" means "both". "che" is the partner of "sia".
The conjunction "di quanto" means "than what". The word "tanto per" begins the purpose. The word "per" begins the purpose. The word "più" begins the comparative. The word "di" means "than". The adverb "più" means "more".
The word "chi" begins the relative. The word "chi" means "who". The word "che cosa" means "what". The word "quale" means "which". "quale" is a relative. "quali" is the plural of "quale". The relative "i quali" means "who".
The mark "¿" begins the question.
The preposition "in" means "in". The preposition "di" means "of". The preposition "da" means "by". The preposition "da" means "from". The preposition "per" means "for".
The preposition "a" means "to". The preposition "con" means "with". The preposition "su" means "on". The preposition "tra" means "among". The preposition "sino a" means "until".
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one". "ci" is the impersonal of "si".
The pronoun "lo" means "him". The pronoun "la" means "her". The pronoun "li" means "them".
The dative pronoun "le" means "her". The pronoun "le" means "them". The pronoun "gli" means "him".
The pronoun "ne" means "it". "ne" is partitive. The pronoun "ci" means "us". The pronoun "vi" means "you".
The pronoun "noi" means "we".
"superquark" is a name.').

newspaper_eco_part(italian, 3, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormi" is the imperative of "dorme". "dormire" is the negative imperative of "dorme". "dormire" is the infinitive of "dorme". "dormiva" is the past of "dorme". "dorma" is the subjunctive of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangiando" is the gerund of "mangia". "mangiava" is the past of "mangia".
The verb "sa" means "knows". "sanno" is the plural of "sa". "sapere" is the infinitive of "sa". "sapevano" is the past of "sanno". "sapessero" is the past subjunctive of "sanno".
The verb "dice" means "says". "dicono" is the plural of "dice". "dire" is the infinitive of "dice". "detto" is the participle of "dice". "dice" takes the clause. "dice" takes the question.
The verb "vuole" means "wants". "vogliono" is the plural of "vuole".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "crede" means "believes". "credere" is the infinitive of "crede". "crede" takes the clause.
The verb "decide" means "decides". "decidere" is the infinitive of "decide".
The verb "ritiene" means "believes". The verb "ritiene" means "retains". "ritengono" is the plural of "ritiene". "ritenuto" is the participle of "ritiene".
The verb "spiega" means "explains". "spiegato" is the participle of "spiega".
The verb "mostra" means "displays". "mostrato" is the participle of "mostra". The verb "mostra" means "shows".
The verb "sostiene" means "sustains". "sosteneva" is the past of "sostiene".
The intransitive verb "nasce" means "is born". "è" is the auxiliary of "nasce".
The verb "trae" means "extracts". "tratto" is the participle of "trae".
The verb "lava" means "washes". The verb "salva" means "saves".
The verb "cita" means "cites". "citare" is the infinitive of "cita".
The verb "fa" means "makes". "fanno" is the plural of "fa". "fare" is the infinitive of "fa".
The verb "guarda" means "looks". "guardano" is the plural of "guarda". "guardate" is the imperative of "guardano". "guardate" is the participle of "guarda". "guardate" is feminine. "guardate" is the plural of "guardata".
The verb "calcola" means "calculates". "calcoli" is the second person of "calcola".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è". "era" is the past of "è". "erano" is the past of "sono". "stato" is the participle of "è". "stati" is the participle of "è". "stati" is the plural of "stato". "è" is the auxiliary of "è". "è" is the auxiliary of the reflexive.
"fosse" is the past subjunctive of "è". "sia" is the subjunctive of "è". "siano" is the plural of "sia".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "aveva" is the past of "ha". "avevano" is the past of "hanno".
The verb "ha" means "has".
The verb "c''è" means "there is". "ci sono" is the plural of "c''è". "ci stesse" is the past subjunctive of "c''è".').

newspaper_eco_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The adverb "no" means "no". "sino" is the partner of "no". The word "a" precedes the person.
The masculine noun "perro" means "dog". The masculine noun "gato" means "cat". The masculine noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The masculine noun "hombre" means "man". "hombre" is a person.
The masculine noun "autor" means "author". "autores" is the plural of "autor". "autor" is a person.
The feminine noun "cosa" means "thing". The masculine noun "siglo" means "century". "siglo" is a time.
The masculine noun "hecho" means "fact". "hecho" is the participle of "hace".
The masculine noun "mundo" means "world". The masculine noun "libro" means "book". The masculine noun "jardín" means "garden".
The feminine noun "carne" means "meat". The masculine noun "ratón" means "mouse". "ratones" is the plural of "ratón". The masculine noun "continente" means "continent".
The masculine noun "beneficio" means "profit". The feminine noun "tierra" means "earth". The masculine noun "centro" means "centre". The masculine noun "cálculo" means "calculation".
The masculine adjective "negro" means "black". The masculine adjective "blanco" means "white". The adjective "grande" means "big". "grandes" is the plural of "grande".
The masculine adjective "pequeño" means "small". The feminine adjective "pequeña" means "small". "pequeñas" is the plural of "pequeña". The masculine adjective "viejo" means "old". The masculine adjective "cansado" means "tired". The masculine adjective "redondo" means "round".
The masculine adjective "bueno" means "good". The feminine adjective "buena" means "good". The feminine adjective "bella" means "beautiful". The feminine adjective "plana" means "flat". The masculine adjective "plano" means "flat".
The adjective "inmóvil" means "motionless". The masculine adjective "loco" means "crazy". The masculine adjective "preciso" means "precise".
The masculine adjective "único" means "only". "únicos" is the plural of "único". The adjective "especial" means "special".
The possessive "su" means "his". The number "dos" means "two". The masculine adjective "griego" means "greek".
The masculine noun "cristiano" means "christian". "cristiano" is a person. The masculine adjective "cristiano" means "christian".
The masculine adjective "solo" means "alone". The adverb "sólo" means "only". "sino" is the partner of "sólo". The adverb "muy" means "very".
The masculine pronoun "alguno" means "some". "algunos" is the plural of "alguno". The pronoun "alguno" does not precede the verb.
The masculine pronoun "ese" means "that". The pronoun "ese" does not precede the verb. The word "el" replaces the noun.
The masculine demonstrative "ese" means "that". "esos" is the plural of "ese".
The feminine noun "muerte" means "death". "muertes" is the plural of "muerte". The masculine adjective "muerto" means "dead". "muertos" is the plural of "muerto". The feminine demonstrative "esta" means "this". "estas" is the plural of "esta".').

newspaper_eco_part(spanish, 2, 'The adverb "entonces" means "then". The adverb "precisamente" means "precisely". The adverb "también" means "also".
The adverb "incluso" means "even". The adverb "quizás" means "maybe". The adverb "al menos" means "at least". The adverb "bien" means "well".
The adverb "cuanto" means "as much". "como" is the partner of "tanto". The word "cuánto" means "how much".
The masculine determiner "tanto" means "so much". The conjunction "tanto" means "both". The adverb "tanto" means "so much".
The adverb "así" means "thus". The word "cómo" means "how". The preposition "como" means "like". The preposition "como" means "as".
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "sino" means "but".
The conjunction "que" means "that". "que" is a relative. The conjunction "si" means "if". The conjunction "mientras" means "while".
The conjunction "ya que" means "since". The conjunction "cuando" means "when".
The conjunction "de lo que" means "than what". The word "para" begins the purpose. The word "de" begins the clause. The word "más" begins the comparative. The word "que" means "than". "mayor" is the comparative of "grande".
The word "quién" means "who". The word "qué" means "what". The pronoun "cuál" means "which". "cuáles" is the plural of "cuál". The relative "los cuales" means "which".
The mark "¿" begins the question.
The preposition "en" means "in". The preposition "de" means "of". The preposition "por" means "by". The preposition "desde" means "from". The preposition "para" means "for".
The preposition "a" means "to". The preposition "con" means "with". The preposition "entre" means "among". The preposition "hasta" means "until".
The reflexive pronoun "se" means "itself". The impersonal pronoun "se" means "one". The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The pronoun "lo" means "him". The pronoun "la" means "her". The pronoun "los" means "them". The pronoun "las" means "them". The dative pronoun "le" means "him".
The pronoun "nos" means "us". The pronoun "os" means "you". The pronoun "nosotros" means "we".
"superquark" is a name.').

newspaper_eco_part(spanish, 3, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme". "durmió" is the past of "duerme". "duerma" is the subjunctive of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comiendo" is the gerund of "come". "comió" is the past of "come".
The verb "sabe" means "knows". "saben" is the plural of "sabe". "saber" is the infinitive of "sabe". "supieron" is the past of "saben".
The verb "dice" means "says". "dicen" is the plural of "dice". "decir" is the infinitive of "dice". "dicho" is the participle of "dice". "dice" takes the clause.
The verb "quiere" means "wants". "quieren" is the plural of "quiere".
The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "cree" means "believes". "creen" is the plural of "cree". "creer" is the infinitive of "cree". "creído" is the participle of "cree".
The verb "decide" means "decides". "decidir" is the infinitive of "decide".
The verb "retiene" means "retains".
The verb "explica" means "explains". "explicado" is the participle of "explica".
The verb "muestra" means "displays". "mostrado" is the participle of "muestra". The verb "muestra" means "shows".
The verb "sostiene" means "sustains". "sostuvo" is the past of "sostiene".
The intransitive verb "nace" means "is born".
The verb "extrae" means "extracts". "extraído" is the participle of "extrae".
The verb "lava" means "washes". The verb "salva" means "saves".
The verb "cita" means "cites". "citar" is the infinitive of "cita".
The verb "hace" means "makes". "hacen" is the plural of "hace". "hacer" is the infinitive of "hace".
The verb "mira" means "looks". "miran" is the plural of "mira". "mirad" is the imperative of "miran".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es". "era" is the past of "es". "eran" is the past of "son". "sido" is the participle of "es".
"sea" is the subjunctive of "es". "sean" is the plural of "sea".
The verb "tiene" means "has". "tienen" is the plural of "tiene". "tenía" is the past of "tiene". "tenían" is the past of "tienen".
The auxiliary "ha" means "has". "han" is the plural of "ha". "había" is the past of "ha". "habían" is the plural of "había".
The verb "hay" means "there is". "hay" is the plural of "hay". "había" is the past of "hay".').

newspaper_eco_checks_1 :-
    nf_tr('Il cane dorme nel IV secolo.', italian, spanish, A1),
    check('a Roman numeral in capitals is a number, its own meaning in every language and written as the source wrote it: `Lattanzio nel IV secolo e il bizantino Cosma Indicopleuste nel VI'' -- in capitals it came through as an acronym, a name no phrase could hold, and the sentence was refused', A1,
          'El perro duerme en el IV siglo.'),
    nf_tr('Il cane dorme nel vii secolo.', italian, spanish, A2),
    check('... and in small letters, a word no lesson knows: `nel vii secolo Isidoro di Siviglia''', A2,
          'El perro duerme en el vii siglo.'),
    nf_tr('Era che - come ha mostrato il gatto - il cane dormiva.', italian, spanish, A3),
    check('who said so set off by dashes (w(Key, perd)) is written back where it stood, with its word for `as'' between its dashes: `Era che - come ha mostrato bene la trasmissione di Angela - i suoi avversari avevano fatto calcoli più precisi dei suoi'' was refused', A3,
          'Era que – como ha mostrado el gato – el perro durmió.'),
    nf_tr('Era che - come ha mostrato bene il gatto - il cane dormiva.', italian, spanish, A4),
    check('... with its adverb', A4,
          'Era que – como ha mostrado bien el gato – el perro durmió.'),
    nf_tr('Era che - come ha mostrato bene la casa del gatto - il cane dormiva.', italian, spanish, A5),
    check('... and its speaker''s `of'' phrase', A5,
          'Era que – como ha mostrado bien la casa del gato – el perro durmió.'),
    nf_tr('Il cane - come ha detto il gatto - mangia il pane.', italian, spanish, A6),
    check('... after a subject, where the word was the question''s `how'', `cómo ha dicho el gato''', A6,
          'El perro – como ha dicho el gato – come el pan.'),
    nf_tr('Il cane - come ha spiegato il gatto - mangia il pane.', italian, english, A7),
    check('... and in English, which 1.8.30 refused', A7,
          'The dog – as the cat has explained – eats the bread.'),
    nf_tr('Il cane, come ha detto il gatto, mangia il pane.', italian, spanish, A8),
    check('... and between commas, which 1.8.30 refused too', A8,
          'El perro, como ha dicho el gato, come el pan.').

newspaper_eco_checks_2 :-
    nf_tr('Lo sanno Maria, Carla, Luisa.', italian, spanish, B1),
    check('names with commas between them to the end of the piece are one list that needs no coordinator: `ma persino Pitagora, Parmenide, Eudosso, Platone, Aristotele, Euclide, Aristarco, Archimede - e gli unici ...'' -- with its commas the clause''s, the list had no reading and the sentence was refused', B1,
          'Lo saben Maria, Carla, Luisa.'),
    nf_tr('Lo sanno persino Maria, Carla, Luisa - e il cane dorme.', italian, spanish, B2),
    check('... or to a dash, the dash kept', B2,
          'Lo saben incluso Maria, Carla, Luisa – y el perro duerme.'),
    nf_tr('Lo sanno persino Luisa, Anna, Rosa.', italian, english, B3),
    check('... and in English, the subject first with the focus adverb before it', B3,
          'Even Luisa, Anna, Rosa know him.'),
    nf_tr('Lo sanno non solo Maria, ma persino Pitagora, Parmenide, Eudosso.', italian, spanish, B4),
    check('... as the second half of not only ... but, whose word after `but'' says the second half is more, `even'': `non solo Tolomeo ed Eratostene, ma persino Pitagora, ...''', B4,
          'Lo saben no sólo Maria, sino incluso Pitagora, Parmenide, Eudosso.'),
    nf_tr('Lo sanno Maria e Carla.', italian, spanish, B5),
    check('two joined after a plural verb are its subject: `Lo sapevano Tolomeo ed Eratostene'' is the two knowing it -- the finder ended a subject at a name, and read with nobody named they were a second object, `lo saben a Maria y Carla''', B5,
          'Lo saben Maria y Carla.'),
    nf_tr('Lo sanno Maria e Carla.', italian, english, B6),
    check('... which English shows with the subject first, where it wrote `They know him Maria and Carla''', B6,
          'Maria and Carla know him.'),
    nf_tr('Lo sanno Luisa, Anna e Rosa.', italian, spanish, B7),
    check('... three joined with a comma between two of them', B7,
          'Lo saben Luisa, Anna y Rosa.'),
    nf_tr('Lo mangia solo il cane.', italian, english, B8),
    check('a focus adverb before the subject after its verb is the subject''s: `ma persino Pitagora'', `solo Leucippo e Democrito'' -- read as the clause''s adverb, the subject was an object and English refused', B8,
          'Only the dog eats him.').

newspaper_eco_checks_3 :-
    nf_tr('Il cane ne mangia alcuni.', italian, spanish, C1),
    check('a partitive pronoun beside a quantity is said once (`"ne" is partitive.''): `tanto per citarne alcuni'' is to cite some of them, and crossed as `it'' it came out `para citarlo algunos''', C1,
          'El perro come algunos.'),
    nf_tr('Il cane ne sa tanto quanto il gatto.', italian, spanish, C2),
    check('... and beside as much as (asmuch/1): `i buoni medievali ne sapevano tanto quanto Colombo'' came out `lo conocieron tan cuanto a Colombo''', C2,
          'El perro sabe tanto como el gato.'),
    nf_tr('Il cane dorme, tanto per citarne alcuni.', italian, spanish, C3),
    check('... after the word of two that begins the purpose', C3,
          'El perro duerme, para citar algunos.'),
    nf_tr('Il cane dice che, come il gatto dorme, così il topo mangia il pane.', italian, spanish, C4),
    check('as one thing, so another (`"così" is the partner of "come".''): `che, come la chiesa si era sbagliata ..., così si stava sbagliando sull''evoluzionismo'' -- read as a comment between commas, the first clause went after the sentence and `così'' with the second', C4,
          'El perro dice que, como el gato duerme, así el ratón come el pan.'),
    nf_tr('I due autori, siccome il gatto dorme, mangiano il pane.', italian, spanish, C5),
    check('a clause with its subordinating word set off between a subject and its verb: `due autori cristiani ... i quali, siccome un passo della bibbia descriveva la terra ..., polemizzavano'' -- divided at its commas, with a count in the subject the sentence was refused', C5,
          'Los dos autores, ya que el gato duerme, comen el pan.'),
    nf_tr('Gli autori, siccome il gatto dorme, mangiano il pane.', italian, english, C6),
    check('... and with no count, where the authors were a verbless piece and the verb had nobody named: the same Spanish, and English says `they eat''', C6,
          'The authors, since the cat sleeps, eat the bread.'),
    nf_tr('Il cane vede gli uomini i quali, siccome il gatto dorme, mangiano il pane.', italian, spanish, C7),
    check('... after a relative word, whose insertion took adjuncts only', C7,
          'El perro ve a los hombres que, ya que el gato duerme, comen el pan.'),
    ( reason_ir('Siccome il cane dorme mentre il gatto mangia, Maria ha spiegato che il pane è buono.', italian, IRC8) -> true ; IRC8 = refused ),
    yes_no(IRC8 = [ir(join(comma, join(_, none, join(_, _, _)), s(_, name(maria), _, _)), _)], C8),
    check('a piece that opens on a subordinating word divides first at a comma, its head clause running to it: `Siccome molta gente pensa ... mentre tutti i sapienti ... la ritenevano ancora piatta, giustamente Angela ... ha spiegato'' -- divided at the last subordinating word first, `mentre'' took the main clause for its own second half, the same words in every language and the wrong IR', C8, yes),
    nf_tr('Siccome non è mangiando il pane che ci si salva, la cosa è buona.', italian, spanish, C9),
    check('... its head clause a gerund cleft with the impersonal of a reflexive verb: Agostino''s `siccome non è conoscendo la forma della terra che ci si salva l''anima, la questione gli appariva di scarso interesse''', C9,
          'Ya que no es comiendo el pan que uno se salva, la cosa es buena.'),
    nf_tr('Il cane dice che il gatto dorme, ma siccome non è mangiando il pane che ci si salva, la cosa è buona.', italian, spanish, C10),
    check('... after a comma and a coordinator: `che forse la terra era davvero sferica, ma siccome ...'' -- the whole tried as one statement first', C10,
          'El perro dice que el gato duerme, pero ya que no es comiendo el pan que uno se salva, la cosa es buena.'),
    nf_tr('Il cane dice che il gatto dorme, ma siccome il pane è buono, la cosa è buona.', italian, spanish, C11),
    check('... the comma before `ma'' kept, which 1.8.30 lost: `quizás pero ya que''', C11,
          'El perro dice que el gato duerme, pero ya que el pan es bueno, la cosa es buena.').

newspaper_eco_checks_4 :-
    nf_tr('Giustamente Maria, nella casa, ha spiegato che il cane dorme.', italian, spanish, D1),
    check('an insertion between a subject and its verb after a head adverb keeps its commas: `giustamente Angela, nel dialogo con un consulente scientifico, ha spiegato che ...'' -- read with every comma out, the dialogue was the subject''s own phrase and both commas were lost', D1,
          'Maria, en la casa, ha explicado precisamente que el perro duerme.'),
    nf_tr('Giustamente Maria, nella casa, ha spiegato che il cane dorme.', italian, english, D2),
    check('... and in English', D2,
          'Maria, in the house, has explained precisely that the dog sleeps.'),
    nf_tr('Il cane, ha detto il gatto, mangia il pane.', italian, spanish, D3),
    check('a reporting clause set between two commas after the subject goes after the sentence with both its commas, and the subject keeps none: the Ciampi report''s `La Legge, rileva ancora il presidente, "provocherà ..."'' came out `La Ley, "provocará ..."'', a comma between the law and what it does', D3,
          'El perro come el pan, ha dicho el gato.'),
    nf_tr('Poi il cane, ha detto il gatto, mangia il pane.', italian, spanish, D4),
    check('GUARD: ... after a head adverb too: the Ciampi report''s `Inoltre la legge approvata, ha rilevato ancora il presidente della repubblica, crea ...'', which 1.8.30 wrote right, came out on this version''s first cut `la ley aprobada, crea''', D4,
          'Entonces el perro come el pan, ha dicho el gato.'),
    nf_tr('Il cane, ha detto il gatto, mangia il pane e il topo dorme.', italian, spanish, D5),
    check('... and where the rest divides into clauses, the subject being the first clause''s', D5,
          'El perro come el pan y el ratón duerme, ha dicho el gato.'),
    nf_tr('Poi il cane, ha detto il gatto, mangia il pane e il topo dorme.', italian, spanish, D6),
    check('GUARD: ... which is the Ciampi report''s own shape, two clauses joined after the reporting clause: the second cut dropped the comma of one clause only, and that sentence kept it', D6,
          'Entonces el perro come el pan y el ratón duerme, ha dicho el gato.'),
    nf_tr('Nel IV secolo Maria mangiava il pane.', italian, spanish, D7),
    check('a front that ends on a name apposed to its noun leaves the rest its subject: `nel vii secolo Isidoro di Siviglia ... aveva calcolato'' is Isidore''s reckoning, and longest first the name was apposed to the century and the verb had nobody named', D7,
          'Maria comió el pan en el IV siglo.'),
    nf_tr('Nel IV secolo Maria (autore buono) mangiava il pane.', italian, spanish, D8),
    check('... a bracket after the name being the name''s: `Isidoro di Siviglia (autorità indiscutibile ...)''', D8,
          'Maria (autor bueno) comió el pan en el IV siglo.'),
    nf_tr('En Barcelona duerme.', spanish, italian, D9),
    check('GUARD: ... and only a name APPOSED to a noun: after the front''s own preposition the name is what the front is about, and the rest may name nobody -- the opera review''s `Si en Florencia, en su estreno, la producción recibió silbidos, en Barcelona pasó sin problemas'', which 1.8.30 read, was refused on the first cut', D9,
          'Dorme in Barcelona.').

newspaper_eco_checks_5 :-
    nf_tr('Che il cane dorma lo sanno non solo Maria e Carla, ma persino Luisa.', italian, spanish, E1),
    check('a clause of `che'' in front, the main clause holding a comma: `Che la terra fosse sferica lo sapevano non solo Tolomeo ed Eratostene, ma persino Pitagora'' -- no comma anywhere was asked, and the sentence had no reading', E1,
          'Que el perro duerme lo saben no sólo Maria y Carla, sino incluso Luisa.'),
    nf_tr('Che il cane dorma, guardate che il gatto mangia il pane.', italian, spanish, E2),
    check('... and one a comma sets off, the main clause opening on its verb, here a command: `Che poi queste cose le sapessero i dotti e i semplici no, guardate che ...'' -- read as a clause with no verb, `guardate'' was the participle, looked, said of nobody', E2,
          'Que el perro duerme, mirad que el gato come el pan.'),
    nf_tr('Che poi il cane dorma, guardate che il gatto mangia il pane.', italian, spanish, E3),
    check('... a connecting adverb at its head staying there', E3,
          'Que entonces el perro duerme, mirad que el gato come el pan.'),
    nf_tr('Ma immobile non vuole dire piatta.', italian, spanish, E4),
    check('an adjective alone at the head is the property it names, and the subject (adjs/1): `Ma immobile non voleva dire piatta'' -- read as the clause''s own, the verb had nobody named and the adjective was no phrase at all, and the sentence was refused', E4,
          'Pero inmóvil no quiere decir plano.'),
    nf_tr('Ma stanco non vuole dire vecchio.', italian, spanish, E5),
    check('... any word the lesson knows only as an adjective', E5,
          'Pero cansado no quiere decir viejo.'),
    nf_tr('Ma immobile non vuole dire piatta.', italian, english, E6),
    check('... and in English, where it is the subject: `vuole dire'' crosses word for word', E6,
          'But motionless does not want to say flat.'),
    nf_tr('Redondo come el pan.', spanish, italian, E7),
    check('GUARD: never the head of the sentence set in small letters, which a surname is as often: `Redondo declaró a Europa Press que ...'' is the man, and read as the property it came out on the first cut `Rotondo dichiarò''', E7,
          'Redondo mangia il pane.').

newspaper_eco_checks_6 :-
    nf_tr('Quale è la casa?', italian, spanish, F1),
    check('`which'' standing alone before its verb (whichp/2): `Quale era allora la materia del contendere ai tempi di Colombo?'' -- `era'' is an era too, and a word that asks only `which'' had no reading of its own', F1,
          '¿Cuál es la casa?'),
    nf_tr('Quali sono i cani?', italian, spanish, F2),
    check('... its plural', F2,
          '¿Cuáles son los perros?'),
    nf_tr('Quale era allora la casa?', italian, spanish, F3),
    check('... with an adverb after the verb', F3,
          '¿Cuál era entonces la casa?'),
    nf_tr('Quale è la casa?', italian, english, F4),
    check('... and in English, which 1.8.27 named the next lead: Tatoeba''s `¿Cuál es la palabra?'' reads now', F4,
          'Which is the house?'),
    nf_tr('Quali sono i cani?', italian, english, F5),
    check('...', F5,
          'Which are the dogs?'),
    nf_tr('Ma allora chi mangia il pane?', italian, spanish, F6),
    check('an adverb that joins its sentence to the one before may stand before the question word: `Ma allora chi aveva detto sia a Colombo che ai suoi avversari che la terra era sferica?'' -- read with the adverb first, no question word stood there and the sentence was refused', F6,
          '¿Pero entonces quién come el pan?'),
    nf_tr('Allora che cosa ha detto il cane?', italian, spanish, F7),
    check('... the subject after the verb, behind the adverb', F7,
          '¿Entonces qué ha dicho el perro?'),
    nf_tr('Allora chi mangia il pane?', italian, english, F8),
    check('... and in English', F8,
          'Then who eats the bread?').

newspaper_eco_checks_7 :-
    nf_tr('Queste cose le sanno gli uomini.', italian, spanish, G1),
    check('a phrase in front that a pronoun takes up, and a person after the verb: `Che poi queste cose le sapessero i dotti'' is that the learned knew these things -- read left to right the things were the subject, `le'' was `to her'' and the learned what the things knew', G1,
          'Saben estas cosas los hombres.'),
    nf_tr('Queste cose le sanno gli uomini e i gatti no.', italian, spanish, G2),
    check('... and a second half after a coordinator with its `no'' (nega/1): `e i semplici no''', G2,
          'Saben estas cosas los hombres y los gatos no.'),
    nf_tr('Queste cose le sanno gli autori e i gatti no.', italian, english, G3),
    check('... which English writes with `not'' before the phrase', G3,
          'The authors know these things and not the cats.'),
    nf_tr('È pazzesco mangiare il pane.', italian, english, G4),
    check('an infinitive after the predicate is what the predicate says of it (infs/2): `e quindi fosse pazzesco tentare di raggiungere il levante ...'' -- read left to right the infinitive had nothing to be and the piece was refused', G4,
          'To eat the bread is crazy.'),
    nf_tr('Il cane crede che il gatto sia stanco, e quindi sia pazzesco mangiare il pane.', italian, english, G5),
    check('... as a second clause of `che'' with its word left out, joined by a coordinator whose clause is in the subjunctive: 1.8.30 wrote `and then is crazy to eat the bread''', G5,
          'The dog believes that the cat is tired, and then to eat the bread is crazy.').

newspaper_eco_checks_8 :-
    nf_tr('Ci si lava.', italian, spanish, H1),
    check('`ci si'' is the impersonal `si'' before a reflexive verb (`"ci" is the impersonal of "si".''): `non è conoscendo la forma della terra che ci si salva l''anima'' -- read as it stands, `ci'' was `us'', `se nos lava''', H1,
          'Uno se lava.'),
    nf_tr('Non è mangiando il pane che ci si salva.', italian, spanish, H2),
    check('a gerund after the copula with `che'' and a clause after it is a cleft (cleft/2), the manner put in front: the copula takes no gerund, and the sentence had no reading', H2,
          'No es comiendo el pan que uno se salva.'),
    nf_tr('È mangiando il pane che il cane dorme.', italian, spanish, H3),
    check('... with no denial and a subject', H3,
          'Es comiendo el pan que el perro duerme.'),
    nf_tr('Il cane la ritiene piatta.', italian, spanish, H4),
    check('an adjective after the verb agrees with the object pronoun before it: `tutti i sapienti del tempo la ritenevano ancora piatta'' believed IT flat, and agreeing with the subject it came out `planos''', H4,
          'El perro la cree plana.'),
    nf_tr('Si era tratto il profitto da due autori.', italian, spanish, H5),
    check('the complements of an impersonal perfect are read in its aspect: `E si era tratto il massimo profitto da due autori cristiani'' drew profit FROM them, and read under the passive the copula first said, `da'' was their agent, `por dos autores''', H5,
          'Se había extraído el beneficio desde dos autores.').

newspaper_eco_checks_9 :-
    nf_tr('Lo sanno non solo Maria, ma anche Carla.', italian, spanish, I1),
    check('not only ... but keeps the comma the source set before `ma'' (c/1): read with the commas out, it was lost', I1,
          'Lo saben no sólo Maria, sino también Carla.'),
    nf_tr('Lo sanno non solo Maria, ma anche Carla.', italian, english, I2),
    check('... and after its verb it is the subject, in the plural (nonly/3): `Lo sapevano non solo Tolomeo ed Eratostene, ma persino Pitagora'' -- read with nobody named, the denial went to the verb and the halves were its objects', I2,
          'Not only Maria, but also Carla know him.'),
    nf_tr('Dormono non solo i cani, ma anche i gatti.', italian, spanish, I3),
    check('...', I3,
          'Duermen no sólo los perros, sino también los gatos.'),
    nf_tr('Non solo il cane ma anche il gatto dormono.', italian, spanish, I4),
    check('... in front of its verb, where 1.8.30 wrote `El perro pero el gato no duermen sólo también''', I4,
          'No sólo el perro sino también el gato duermen.'),
    nf_tr('Il cane dorme non solo nella casa ma anche nel giardino.', italian, spanish, I5),
    check('not only in one place but in another (nonlyc/3): `la chiesa si era sbagliata non solo sul geocentrismo ma anche sulla sfericità'' -- read as phrases, `solo'' was the adjective alone and `ma'' the `but'' that joins two clauses', I5,
          'El perro duerme no sólo en la casa sino también en el jardín.'),
    nf_tr('Il cane dorme non solo nella casa ma anche nel giardino.', italian, english, I6),
    check('... and in English, `sleeps alone not in the house'' before', I6,
          'The dog sleeps not only in the house but also in the garden.'),
    nf_tr('Gli unici a non dormire sono i cani.', italian, spanish, I7),
    check('the `to'' and an infinitive of a phrase, denied: `gli unici a non credervi erano stati solo Leucippo e Democrito'' is the only ones not to believe it, and with the infinitive refused there the subject was refused with it', I7,
          'Los únicos a no dormir son los perros.'),
    nf_tr('Gli unici a non dormire sono i cani.', italian, english, I8),
    check('... and in English, `not'' before the `to''', I8,
          'The only ones not to sleep are the dogs.'),
    nf_tr('Gli unici a non crederci sono i cani.', italian, spanish, I9),
    check('... with a pronoun joined to the infinitive, which is the infinitive''s and no clitic of the verb after it -- `ci'' crosses as `us'', a sense no lesson separates', I9,
          'Los únicos a no creernos son los perros.'),
    nf_tr('Il cane decide di non dormire.', italian, english, I10),
    check('a denied infinitive after a verb is that verb''s: read as a phrase of `di'', it came out `The dog decides of not to sleep''', I10,
          'The dog decides not to sleep.'),
    nf_tr('Il cane decide di non dormire.', italian, spanish, I11),
    check('... and `decide de no dormir''', I11,
          'El perro decide no dormir.').

newspaper_eco_checks_10 :-
    nf_tr('Il cane nasce dal fatto che, almeno sino a Maria, il gatto mangia il pane.', italian, spanish, J1),
    check('a noun''s clause of `che'' that opens on an insertion between two commas: `L''equivoco nasce dal fatto che, almeno sino a Copernico, sia il mondo greco che quello cristiano avevano ritenuto ...'' -- the nested reader had nothing for the comma, and the sentence was refused', J1,
          'El perro nace desde el hecho de que, al menos hasta Maria, el gato come el pan.'),
    nf_tr('Sia il mondo greco che quello cristiano dormono.', italian, spanish, J2),
    check('the word that replaces the noun and one adjective after it, though the lesson calls the adjective a noun too: `sia il mondo greco che quello cristiano'' is the Christian one, and read as the demonstrative before the noun `cristiano'' it was `ese cristiano''', J2,
          'Tanto el mundo griego como el cristiano duermen.'),
    nf_tr('Il mangiare è buono.', italian, spanish, J3),
    check('an article before an infinitive makes a noun of it (ninf/1): `la materia del contendere'' -- `contendere'' is no noun the lesson gives, and the question was refused', J3,
          'El comer es bueno.'),
    nf_tr('Il mangiare è buono.', italian, english, J4),
    check('... which English writes with the gerund', J4,
          'The eating is good.'),
    nf_tr('Quale era la cosa del mangiare?', italian, spanish, J5),
    check('... after a contraction', J5,
          '¿Cuál era la cosa del comer?'),
    nf_tr('Il cane dorme in bellissime case.', italian, spanish, J6),
    check('the word for `very'' before an adjective it does not agree with is the adjective''s: `in serissime storie della scienza'' -- the tokeniser unfolds the superlative to `molto serie'', and read as the determiner `molto'' the phrase had no reading', J6,
          'El perro duerme en casas muy bellas.'),
    nf_tr('Il cane dorme in molto belle case.', italian, spanish, J7),
    check('... as a writer may write it', J7,
          'El perro duerme en casas muy bellas.'),
    nf_tr('Lo speciale superquark di Maria è buono.', italian, spanish, J8),
    check('a word in small letters that the lesson says is a name and knows as nothing else (`"superquark" is a name.''): `lo speciale superquark di Piero Angela'' is the programme by its name', J8,
          'El especial superquark de Maria es bueno.').

newspaper_eco_checks_11 :-
    nf_tr('La casa è più grande di quanto il cane dice.', italian, spanish, K1),
    check('a comparison whose second term is a clause (cmpc/2), opened by the word the lesson names (`The conjunction "di quanto" means "than what".''): `fosse più ampia di quanto il genovese sosteneva'' -- with no term for a clause the comparison had no reading', K1,
          'La casa es mayor de lo que el perro dice.'),
    nf_tr('La casa è più grande di quanto il cane dice.', italian, english, K2),
    check('... which English writes with `than'' and the clause', K2,
          'The house is bigger than the dog says.'),
    nf_tr('Il cane crede che la casa fosse più grande di quanto il gatto sosteneva.', italian, spanish, K3),
    check('... in a clause of `che'', where the reading the sentence found instead took `fosse'' for the plural of `fossa'', a pit', K3,
          'El perro cree que la casa era mayor de lo que el gato sostuvo.'),
    nf_tr('Il cane dice quanto il gatto mangia.', italian, spanish, K4),
    check('how much, after a verb that takes the question (`"dice" takes the question.''): `che ci vogliono dire quanto Roma disti da Gerusalemme'' -- read as `as much'', Rome was a person marked as the object, `cuanto a Roma''', K4,
          'El perro dice cuánto el gato come.'),
    nf_tr('Il cane vuole dire quanto il gatto mangia.', italian, spanish, K5),
    check('... and after its infinitive', K5,
          'El perro quiere decir cuánto el gato come.'),
    nf_tr('Il cane non mangia il pane ma la carne.', italian, spanish, K6),
    check('`but'' after a denial is the partner the lesson names for its denial word (`"sino" is the partner of "no".''): `non rappresentavano la terra ma le terre note'' -- Spanish''s `pero'' says `yet''', K6,
          'El perro no come el pan sino la carne.'),
    nf_tr('Le case non sono grandi bensì piccole.', italian, spanish, K7),
    check('... `bensì'' too: `non avevano funzioni geografiche bensì simboliche''', K7,
          'Las casas no son grandes sino pequeñas.'),
    nf_tr('I cani non avevano case grandi bensì piccole (con il gatto al centro).', italian, spanish, K8),
    check('... with a bracket after it, which says something of the whole phrase and heads nothing: `funzioni geografiche bensì simboliche (con Gerusalemme al centro)'' -- the symbolic ones came out masculine, `pero pequeños''', K8,
          'Los perros no tenían casas grandes sino pequeñas (con el gato al centro).'),
    nf_tr('Il cane crede che tra l''Europa e l''Asia ci stesse un continente.', italian, spanish, K9),
    check('an elided form is the words it elides, and never an elided form alone: `tra l''Europa e l''Asia ci stesse un altro continente'' -- the second `l'''' was `him'' and Asia the subject of `there was''', K9,
          'El perro cree que había un continente entre el Europa y el Asia.').

newspaper_eco_checks_12 :-
    nf_tr('Maria nel suo Flat Earth ha mostrato che il cane dorme.', italian, spanish, L1),
    check('a name and the phrases after it that say which: `Jeffrey Burton Russell nel suo Inventing The Flat Earth (New York, 1991) ha mostrato ...'' -- the man in his book, and with a name for the book the phrase had no noun at all', L1,
          'Maria en su Flat Earth ha mostrado que el perro duerme.'),
    nf_tr('Maria nel suo Flat Earth (New York, 1991) ha mostrato che il cane dorme.', italian, spanish, L2),
    check('... and the bracket after it', L2,
          'Maria en su Flat Earth (New York, 1991) ha mostrado que el perro duerme.'),
    nf_tr('Che la terra fosse piatta lo sapevano non solo Tolomeo ed Eratostene, ma persino Pitagora, Parmenide, Eudosso - e gli unici a non crederci erano stati solo Leucippo e Democrito.', italian, spanish, L3),
    check('the article''s sixteenth sentence in small: a clause of `che'' in front, not only ... but with names to a dash, and the only ones not to', L3,
          'Que la tierra era plana lo supieron no sólo Tolomeo y Eratostene, sino incluso Pitagora, Parmenide, Eudosso – y los únicos a no creernos habían sido sólo Leucippo y Democrito.'),
    nf_tr('Il cane ha un libro di case e gatti unico.', italian, spanish, L4),
    check('GUARD: a phrase with no determiner agrees with the adjective after its noun only where the noun is a verb''s form too, as `fosse'' is: the Fiat report''s `un bagaglio di esperienze, punti di vista e competenze unico al mondo'' has the adjective agree with the baggage, and the first cut refused it', L4,
          'El perro tiene un libro de casas y gatos únicos.'),
    nf_tr('Quei morti dormono.', italian, spanish, L5),
    check('GUARD: the word that replaces the noun is never the form that stands only before a noun, the lesson''s apocope and its plural: the Bosnian letter''s `ma quei morti per le strade'' is those dead, and on the first cut it lost its demonstrative, `los muertos''', L5,
          'Esos muertos duermen.'),
    nf_tr('Il cane dorme tanto per il pane.', italian, spanish, L6),
    check('a word of several words that the lesson gives only as the purpose''s is joined only before an infinitive: `The word "tanto per" begins the purpose.'', written for `tanto per citarne alcuni'', made the Fregene report''s `No, non mi dispiace tanto per lei, ...'' a purpose with nothing to do, and on this store 1.8.30 and this version''s first cut refused the sentence that 1.8.30 reads on its own', L6,
          'El perro duerme como para el pan.'),
    nf_tr('Giustamente dorme il cane, come il gatto.', italian, spanish, L7),
    check('an adverb at the head leaves the rest its commas where a verb group opens the rest too, not only after one of its commas: the Fiat report''s `Ora è indispensabile ..., come annunciato, ...'' and the Fregene report''s `E adesso siamo di nuovo in tre, come prima.'' -- 1.8.30 lost those commas, and so did a cut of this version''s cost work that asked for the verb group after a comma only', L7,
          'Duerme el perro, como el gato precisamente.').

newspaper_arzalluz :-
    section('a Spanish report into Italian: a bracket inside a pair of plain quotation marks, a quotation that opens on an infinitive after a preposition and one that closes on a clause whose adverb the lift took out, not only one clause but another, a front before the clause of `that'' a verb of saying takes, a bare time and the lesson''s word for one, the subject of a verb of saying after it, a clause with its verb left out and its phrase `also'', a name that speaks with its relative clause, a noun that takes `to'' and an infinitive after `has'', a reflexive the source slipped on, the person told before `de que'', a purpose infinitive''s own person, a quoted adjective after a name, an infinitive with its own object, a name before a word that is a noun and a preposition'),
    newspaper_arzalluz_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_arzalluz_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_arzalluz_checks_1, newspaper_arzalluz_checks_2, newspaper_arzalluz_checks_3,
    newspaper_arzalluz_checks_4, newspaper_arzalluz_checks_5, newspaper_arzalluz_checks_6,
    newspaper_arzalluz_checks_7,
    reason_unlearn(spanish), reason_unlearn(italian).

%% each lesson in two parts, a clause over a page (8 KB) being one the store
%% cannot hold. What the vocabulary gives a word the lesson gives it too:
%% `derecho' a noun and an adjective, `vez' a time and a noun, `tres' a number,
%% `ultimátum' and `concluye' with the property that makes the clause after
%% `cuando concluya' the ultimatum's, the auxiliary with the forms of its
%% past subjunctive, and the verbs that take a clause with the word they put
%% before it
newspaper_arzalluz_lesson(L, Text) :-
    newspaper_arzalluz_part(L, 1, A), newspaper_arzalluz_part(L, 2, B),
    atomic_list_concat([A, ' ', B], Text).

newspaper_arzalluz_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The masculine noun "perro" means "dog". The masculine noun "gato" means "cat". The masculine noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The masculine noun "libro" means "book".
The masculine noun "técnico" means "coach". "técnico" is a person.
The masculine noun "hombre" means "man". "hombre" is a person.
The masculine noun "ultimátum" means "ultimatum". The masculine noun "martes" means "tuesday". "martes" is a time.
The feminine noun "vez" means "time". "veces" is the plural of "vez". "vez" is a time.
The masculine noun "derecho" means "right". The masculine adjective "derecho" means "right". "derechos" is the plural of "derecho".
The masculine noun "artículo" means "article". The masculine noun "chollo" means "bargain".
The masculine adjective "cansado" means "tired". The masculine adjective "nostálgico" means "nostalgic".
The adverb "realmente" means "really". The adverb "ayer" means "yesterday". The adverb "también" means "also".
The adverb "sólo" means "only". The number "tres" means "three".
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative.
The conjunction "si" means "if". The conjunction "como si" means "as if". The conjunction "cuando" means "when".
The conjunction "sino" means "but". "sino" is the partner of "sólo". "sino" takes the clause.
The preposition "en" means "in". The preposition "de" means "of". The preposition "por" means "by". The preposition "por" means "for".
The preposition "a" means "to". The preposition "con" means "with". The preposition "para" means "for".
The word "para" begins the purpose.
The reflexive pronoun "se" means "itself". The pronoun "lo" means "him". The dative pronoun "le" means "him".').

newspaper_arzalluz_part(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "hay" means "there is".
"duerme" is the imperative of "duerme". "duermas" is the negative imperative of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
"come" is the imperative of "come". "comas" is the negative imperative of "come".
The verb "da" means "gives". "dado" is the participle of "da". "dar" is the infinitive of "da".
The verb "tiene" means "has". "tienen" is the plural of "tiene". "tenemos" is the first person of "tienen".
The verb "lee" means "reads". The verb "ve" means "sees". "ven" is the plural of "ve".
The verb "niega" means "denies". "niegan" is the plural of "niega". "negó" is the past of "niega".
The verb "dice" means "says". "dijo" is the past of "dice".
The verb "advierte" means "warns". "advierte" takes the clause. "advierte" takes "de" before the clause.
The verb "recupera" means "recovers". "recuperó" is the past of "recupera".
The verb "retrata" means "portrays". "retratar" is the infinitive of "retrata".
The verb "concluye" means "concludes". "concluya" is the subjunctive of "concluye". "concluye" is intransitive.
The verb "va" means "goes". "vaya" is the subjunctive of "va". "ir" is the infinitive of "va".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha". "hubiera" is the past subjunctive of "ha". "hubieran" is the plural of "hubiera". "hubiéramos" is the first person of "hubieran".
The modal "debe" means "must". "deben" is the plural of "debe".
The verb "logra" means "attains". "lograr" is the infinitive of "logra".
The preposition "ante" means "in front of". The masculine noun "ante" means "elk".
"said" is the past of "says". "denied" is the past of "denies".').

newspaper_arzalluz_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "del" is the contraction of "di il". "della" is the contraction of "di la".
"dal" is the contraction of "da il". "dalla" is the contraction of "da la". "al" is the contraction of "a il". "ai" is the contraction of "a i".
"l''" is the elision of "lo". "l''" is the elision of "la". "d''" is the elision of "di".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The masculine noun "cane" means "dog". "cani" is the plural of "cane". The masculine noun "gatto" means "cat". "gatti" is the plural of "gatto".
The masculine noun "pane" means "bread". The feminine noun "casa" means "house". The masculine noun "libro" means "book".
The masculine noun "tecnico" means "coach". "tecnici" is the plural of "tecnico". "tecnico" is a person.
The masculine noun "uomo" means "man". "uomini" is the plural of "uomo". "uomo" is a person.
The masculine noun "ultimatum" means "ultimatum". The masculine noun "martedì" means "tuesday". "martedì" is a time.
The masculine noun "tempo" means "time". The feminine noun "volta" means "time". "volte" is the plural of "volta". "volta" is a time.
The masculine noun "diritto" means "right". The masculine noun "articolo" means "article". The masculine noun "affare" means "bargain".
The masculine adjective "stanco" means "tired". The masculine adjective "nostalgico" means "nostalgic".
The adverb "realmente" means "really". The adverb "ieri" means "yesterday". The adverb "anche" means "also".
The adverb "solo" means "only". The number "tre" means "three".
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative.
The conjunction "se" means "if". The conjunction "come se" means "as if". The conjunction "quando" means "when".
The conjunction "ma" means "but". "ma" is the partner of "solo".
The preposition "in" means "in". The preposition "di" means "of". The preposition "da" means "by". The preposition "per" means "for".
The preposition "a" means "to". The preposition "con" means "with".
The word "per" begins the purpose.
The reflexive pronoun "si" means "itself". The pronoun "lo" means "him". The dative pronoun "gli" means "him".').

newspaper_arzalluz_part(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "c''è" means "there is".
"dormi" is the imperative of "dorme". "dormire" is the negative imperative of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangia" is the imperative of "mangia". "mangiare" is the negative imperative of "mangia".
The verb "dà" means "gives". "dato" is the participle of "dà". "dare" is the infinitive of "dà".
The verb "ha" means "has". "hanno" is the plural of "ha". "abbiamo" is the first person of "hanno".
The verb "legge" means "reads". The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "nega" means "denies". "negano" is the plural of "nega". "negò" is the past of "nega".
The verb "dice" means "says". "disse" is the past of "dice".
The verb "avverte" means "warns". "avverte" takes the clause.
The verb "recupera" means "recovers". "recuperò" is the past of "recupera".
The verb "ritrae" means "portrays". "ritrarre" is the infinitive of "ritrae".
The verb "conclude" means "concludes". "conclude" is intransitive.
The verb "va" means "goes". "andare" is the infinitive of "va".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "aveva" is the past of "ha". "avevano" is the plural of "aveva". "avevamo" is the first person of "avevano". "avesse" is the past subjunctive of "ha". "avessero" is the plural of "avesse". "avessimo" is the first person of "avessero".
The modal "deve" means "must". "devono" is the plural of "deve".
The verb "riesce" means "attains". "riuscire" is the infinitive of "riesce".
The transitive verb "ottiene" means "attains". "ottenere" is the infinitive of "ottiene".
The preposition "davanti a" means "in front of".
"said" is the past of "says".').

newspaper_arzalluz_checks_1 :-
    nf_tr('"El perro come el pan (la casa), como si el gato duerme", dijo el técnico.', spanish, italian, A1),
    check('a bracket inside a pair of plain quotation marks is an aside of the quoted clause: `"se va con el chollo que le han dado (una cátedra en Nueva York), como si se le hubiéramos echado"'' -- the pair is left verbatim by tr_mid_marks/2, so its brackets reached the tokeniser as they stood and were dropped as punctuation, and the bracket''s words ran on into the clause as one more object of `han dado''', A1,
          '"Il cane mangia il pane (la casa), come se il gatto dorme", disse il tecnico.'),
    nf_tr('"El perro come el pan (la casa), como si el gato duerme", dijo el técnico.', spanish, english, A2),
    check('... and in English', A2,
          '"The dog eats the bread (the house), as if the cat sleeps", the coach said.'),
    nf_tr('El perro va a "comer el pan".', spanish, italian, A3),
    check('a quotation that opens on the infinitive after `a'' opens there (ainf with qinf): `que su partido se vaya a "tirar al monte"'' came out `si va a gettare al monte"'', the closing mark with no opening one', A3,
          'Il cane va a "mangiare il pane".'),
    nf_tr('El perro va a "comer el pan".', spanish, english, A4),
    check('... and in English', A4, 'The dog goes to "eat the bread".'),
    nf_tr('"El perro come el pan si realmente duerme", dijo el técnico.', spanish, italian, A5),
    check('a quotation that closes on the clause''s last word closes on the last word WRITTEN when the lift took an adverb out: `"... lo que nos parece si realmente es un nostálgico del franquismo", dijo Arzalluz'' came out `... del franchismo" realmente'', the quotation closed before the adverb the writer put at the end of the clause', A5,
          '"Il cane mangia il pane se dorme realmente", disse il tecnico.').

newspaper_arzalluz_checks_2 :-
    nf_tr('"No sólo duermen los perros, sino que comen el pan.', spanish, italian, B1),
    check('not only one clause but another: `"No sólo nos insultan, sino que mienten y lo saben'' -- the denial and the word for `only'' open the first clause, and after a comma the partner the lesson names for that word opens the second, with the word for `that'' where the lesson''s language puts one. Read clause by clause the denial went to the first verb and the word for `only'' was an adverb of it, `Non dormono i cani solo, ma che mangiano il pane'', and `sino'' a `but'' that joined nothing', B1,
          '"Non solo dormono i cani, ma mangiano il pane.'),
    nf_tr('No sólo duermen los perros, sino que comen el pan.', spanish, italian, B2),
    check('... with no quotation mark on the denial', B2,
          'Non solo dormono i cani, ma mangiano il pane.'),
    nf_tr('"Non solo dormono i cani, ma mangiano il pane.', italian, spanish, B3),
    check('... and the other way, where the lesson says the partner takes the word for `that'' before a clause (`"sino" takes the clause.'')', B3,
          '"No sólo duermen los perros, sino que comen el pan.').

newspaper_arzalluz_checks_3 :-
    nf_tr('Tres veces dijo que el gato duerme.', spanish, italian, C1),
    check('a front with no comma goes before the clause of `that'' the verb takes, which it is no part of: `Tres veces negó el líder peneuvista que su partido se vaya a "tirar al monte"'' is denied three times, and written after the clause `tre volte'' read as the clause''s own, the way a lifted adverb never is (1.8.6)', C1,
          'Disse tre volte che il gatto dorme.'),
    nf_tr('El perro duerme tres veces.', spanish, italian, C2),
    check('a bare time takes the lesson''s word for a time where it has one: `time'' is `tempo'' before it is `volta'', and `"volta" is a time.'' is the one written for an adjunct that names when -- `tre tempi'' for `tres veces'', which the lesson gave no plural, and the sentence was refused', C2,
          'Il cane dorme tre volte.'),
    nf_tr('Negó el técnico que el gato duerme.', spanish, english, C3),
    check('the subject of a verb of saying stands after it: `Tres veces negó el líder peneuvista que su partido se vaya a "tirar al monte"'' -- the leader denied it. Read left to right the phrase after the verb took the clause for a relative clause on it, the leader whom his party goes, and the verb had nobody for its subject: Italian wrote the same words, and English, which must put a subject first, refused it', C3,
          'The coach denied that the cat sleeps.'),
    nf_tr('Tres veces negó el técnico que el gato duerme.', spanish, italian, C4),
    check('... with its front, the three at once', C4,
          'Negò il tecnico tre volte che il gatto dorme.'),
    nf_tr('Tres veces negó el técnico que el gato duerme.', spanish, english, C5),
    check('... and in English', C5, 'The coach denied three times that the cat sleeps.'),
    nf_tr('Ayer dijo que el gato duerme.', spanish, italian, C6),
    check('GUARD: a lifted adverb stays before the clause of `that'', which is where a front goes now too (1.8.6)', C6,
          'Disse ieri che il gatto dorme.'),
    nf_tr('Dijo al técnico que el gato duerme.', spanish, italian, C7),
    check('... and the person told stays the person told: `dijo al técnico que el gato duerme'' is told the coach that, and the person''s relative clause was the clause -- the phrase an object, which the subject after a verb of saying then took for the one who says. The word before the person is the lesson''s `to'' again', C7,
          'Disse al tecnico che il gatto dorme.'),
    nf_tr('En la casa el perro es nostálgico que come el pan.', spanish, italian, C8),
    check('GUARD: a clause with no subject of its own after a predicate adjective is a relative clause read as a clause of `that'', and the front stays after it: `en las partes altas de las ciudades serán neonazis que destrozan la cabeza a un inmigrante'' with the front put between the two hung on the cities, `neonazisti nelle parti alte delle città che spaccano la testa'' (the Spanish article''s fifth)', C8,
          'Il cane è nostalgico che mangia il pane nella casa.').

newspaper_arzalluz_checks_4 :-
    nf_tr('El perro duerme y el gato también.', spanish, italian, D1),
    check('a clause with its verb left out and its phrase `also'': `La ley da para mucho y la voluntad del pueblo también'' -- the will of the people too. The coordinator joins the clause before it to a phrase and the word for `also'' after it, the gapped form a semicolon''s parts read and no clause read; the word goes in front in the lesson''s language, `e anche il gatto''', D1,
          'Il cane dorme e anche il gatto.'),
    nf_tr('El perro duerme y el gato también.', spanish, english, D2),
    check('... and in English, where `also'' follows', D2, 'The dog sleeps and the cat also.'),
    nf_tr('"El perro duerme", dijo Juan, que también come el pan.', spanish, italian, D3),
    check('a name that speaks hangs its relative clause on it (nrc/3), as a phrase does: `dijo Arzalluz, que también criticó al director del Euskobarómetro'' -- it was a clause of `that'' the verb took, and its adverb came out at its end, `che mangia il pane anche''', D3,
          '"Il cane dorme", disse Juan, che anche mangia il pane.'),
    nf_tr('"El perro duerme", dijo Juan, que también come el pan.', spanish, english, D4),
    check('... and in English, the clause set off after the name', D4,
          '"The dog sleeps", Juan, who also eats the bread, said.'),
    nf_tr('Los perros tienen derecho a comer el pan.', spanish, italian, D5),
    check('a noun that takes `to'' and an infinitive after the verb that means `has'' is its object: `tenemos derecho a pensar de él lo que nos parece'' -- `derecho'' is an adjective too, straight or right, which the complement reader took for a predicate agreeing with the subject, and the sentence was refused or read `abbiamo diritti a pensare''', D5,
          'I cani hanno diritto a mangiare il pane.').

newspaper_arzalluz_checks_5 :-
    nf_tr('El perro duerme, como si se le hubiéramos dado el pan.', spanish, italian, E1),
    check('a reflexive the source slipped on is read as nothing: `como si se le hubiéramos echado'' (the treebank''s own text) has a `se'' the verb cannot take beside the dative `le'', a blend of `como si le hubiéramos echado'' and `como si se le hubiese echado''; the sentence was refused', E1,
          'Il cane dorme, come se gli avevamo dato il pane.'),
    nf_tr('Se lo dije.', spanish, italian, E2),
    check('GUARD: `se lo dije'' keeps its refusal -- `se'' there is the dative before an accusative, and no reading of it is dropped', E2, refused),
    nf_tr('El perro advierte a los técnicos de que no deben comer el pan.', spanish, italian, E3),
    check('the person told before `de que'' and a clause whose subject is left out: `El líder del PNV previno a los suyos de que no deben albergar "miedo" alguno'' -- `de que'' after the person (`"previene" takes "de" before the clause.''), the clause the verb''s own: read on, the person was the object and the clause a relative clause on it, `d''i che''', E3,
          'Il cane avverte ai tecnici che non devono mangiare il pane.'),
    nf_tr('El perro advierte a los técnicos de que no deben comer el pan.', spanish, english, E4),
    check('... and in English', E4, 'The dog warns to the coaches that they must not eat the bread.'),
    nf_tr('El perro ve a los técnicos que comen el pan.', spanish, italian, E5),
    check('GUARD: a person with a relative clause after a verb that takes no clause stays a relative clause', E5,
          'Il cane vede i tecnici che mangiano il pane.'),
    nf_tr('El perro recupera el pan para "retratar" a Juan.', spanish, italian, E6),
    check('a purpose infinitive''s own person is its object: `recuperó la hemeroteca para "retratar" a Aznar'' -- what follows the infinitive is read afresh, and with the main clause''s object counted as seen the person after `a'' was `to Aznar'', `per ritrarre a Aznar''', E6,
          'Il cane recupera il pane per "ritrarre" Juan.'),
    nf_tr('El perro lee un libro de Juan "cansado".', spanish, italian, E7),
    check('a name followed by a quoted adjective is one phrase: `un artículo de Aznar "nostálgico del franquismo"'' -- read on, `Aznar "nostálgico"'' was a name and a quoted word, which no phrase reads, and the sentence was refused', E7,
          'Il cane legge un libro di Juan "stanco".').

newspaper_arzalluz_checks_7 :-
    nf_tr('Ayer el perro come "el pan".', spanish, italian, G1),
    check('GUARD: an adverb the lift took out from BEFORE the mark that opens a quotation is written outside it: `Ieri è stato inoltre approvato il documento su "la fine della vita umana"'' lifts `ieri'' and `inoltre'' from before the mark, and the closing mark moved to the last word written (the first cut of the `qe'' rule, which every quotation that closes on the clause''s last word got) went after `ayer'', or was lost where the writer has no place for it', G1,
          'Il cane mangia "il pane" ieri.'),
    nf_tr('Ayer el perro come "el pan".', spanish, english, G2),
    check('... and in English', G2, 'The dog eats "the bread" yesterday.'),
    nf_tr('Ayer hay un perro "en la casa".', spanish, italian, G3),
    check('GUARD: ... a `there is'' too: `E infine vi è rischio che la legge possa recare "un vulnus ... della giustizia"'' lifts `infine'' from before the mark, and the mark moved to the last word written was a qe among the complements of a clause the existential writer could not take: the sentence was refused', G3,
          'C''è un cane "nella casa" ieri.'),
    nf_tr('"Ayer hay un perro en la casa", dijo el técnico.', spanish, italian, G4),
    check('a quotation that opens on the adverb the lift took out has it inside: `"Ieri c''è un cane nella casa"'' closes on the last word written, `ieri'', and the existential writer takes the clause''s qs and qe (which it took neither of: the sentence was refused)', G4,
          '"C''è un cane nella casa ieri", disse il tecnico.'),
    nf_tr('"Ayer hay un perro en la casa", dijo el técnico.', spanish, english, G5),
    check('... and in English', G5, '"There is a dog in the house yesterday", the coach said.').

newspaper_arzalluz_checks_6 :-
    nf_tr('El perro duerme para lograr el pan.', spanish, italian, F1),
    check('an infinitive with its own object right after it takes the verb a clause with an object takes: `un acuerdo con ETA o con Batasuna para lograr una "tregua de hecho"'' -- `lograr'' is `riuscire'' where nothing is attained and `ottenere'' where something is (`The transitive verb "ottiene" means "attains".''), and the infinitive took the first verb, `per riuscire una tregua''', F1,
          'Il cane dorme per ottenere il pane.'),
    nf_tr('El perro va a lograr el pan.', spanish, italian, F2),
    check('... after `a'' as well', F2, 'Il cane va a ottenere il pane.'),
    nf_tr('El perro duerme para lograr.', spanish, italian, F3),
    check('GUARD: an infinitive with no object after it keeps the verb it had', F3, 'Il cane dorme per riuscire.'),
    nf_tr('El perro ve la casa del PNV ante el gato.', spanish, italian, F4),
    check('a name after the article is no noun for the determiner before a word that is a noun and a preposition: `la inquietud de ciertos sectores del PNV ante la ponencia aprobada'' -- `ante'' is an elk too, so `del PNV ante'' read as a determiner, a name between and a noun, which nothing reads, and the sentence was refused with every word known', F4,
          'Il cane vede la casa del PNV davanti al gatto.'),
    nf_tr('El perro ve la casa del PNV ante el gato.', spanish, english, F5),
    check('... and in English', F5, 'The dog sees the house of the PNV in front of the cat.'),
    nf_tr('El perro ve el gato ante el perro.', spanish, italian, F6),
    check('GUARD: the preposition after a noun with no name before it stays the preposition', F6,
          'Il cane vede il gatto davanti al cane.').

newspaper_cecchi :-
    section('an Italian report into Spanish: a participle or an adjective in front of its clause, a perfect infinitive after a preposition, a clause that leaves out its copula, `né'' between clauses, the state''s copula for a place, a quoted adverb after an article, a day of the week, the cleft with its copula first, an absolute phrase, a name of several words, a title before a name, `cioè'', a lesson''s adjective that stays after its noun, the pronouns joined to an infinitive, a quotation split by its report, a phrase set in front and taken up by a pronoun, a lead-in, a preposition before `how'', an infinitive joined to another, a subjunctive after `che'', `infatti'' in front, a phrase before `there is'', a noun after its article and adjective, an adverb that is no preposition''s object'),
    newspaper_cecchi_lesson(italian, IT), reason_learn(IT, italian, _),
    newspaper_cecchi_lesson(spanish, ES), reason_learn(ES, spanish, _),
    newspaper_cecchi_checks_1, newspaper_cecchi_checks_2, newspaper_cecchi_checks_3,
    newspaper_cecchi_checks_4, newspaper_cecchi_checks_5, newspaper_cecchi_checks_6,
    newspaper_cecchi_checks_7,
    reason_unlearn(italian), reason_unlearn(spanish).

%% each lesson in two parts, a clause over a page (8 KB) being one the store
%% cannot hold. What the vocabulary gives a word the lesson gives it too: `firma'
%% with its dictionary meaning first and the intransitive and the transitive
%% senses after it, `dietro' a preposition and an adverb, `passi' a noun and
%% a verb's second person and subjunctive at once (and `pasas' the Spanish
%% second person that shows it), `giochi' a noun and a verb's form, `ci sono'
%% with `hay' for its plural, and the state's copula marked
newspaper_cecchi_lesson(L, Text) :-
    newspaper_cecchi_part(L, 1, A), newspaper_cecchi_part(L, 2, B),
    atomic_list_concat([A, ' ', B], Text).

newspaper_cecchi_part(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "del" is the contraction of "di il". "della" is the contraction of "di la".
"dal" is the contraction of "da il". "dalla" is the contraction of "da la". "al" is the contraction of "a il". "alla" is the contraction of "a la". "ai" is the contraction of "a i".
"l''" is the elision of "lo". "l''" is the elision of "la". "d''" is the elision of "di".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The masculine noun "cane" means "dog". "cani" is the plural of "cane". The masculine noun "gatto" means "cat". "gatti" is the plural of "gatto".
The masculine noun "pane" means "bread". The feminine noun "casa" means "house". "case" is the plural of "casa". The masculine noun "libro" means "book".
The masculine noun "tecnico" means "coach". "tecnici" is the plural of "tecnico". "tecnico" is a person.
The masculine noun "avvocato" means "lawyer". "avvocato" is a person.
The masculine noun "timore" means "fear". The masculine noun "sfondo" means "background".
The masculine noun "gioco" means "game". "giochi" is the plural of "gioco".
The masculine noun "corriere" means "courier". The feminine noun "sera" means "evening".
The masculine noun "martedì" means "tuesday". "martedì" is a time.
The masculine adjective "stanco" means "tired". The masculine adjective "grande" means "big". "grandi" is the plural of "grande".
The masculine adjective "diretto" means "direct". The masculine adjective "rispettivo" means "respective". "rispettivi" is the plural of "rispettivo".
The adverb "qui" means "here". The adverb "anche" means "also". The adverb "quasi" means "almost". The adverb "infatti" means "in fact".
The conjunction "e" means "and". The conjunction "o" means "or". The conjunction "ma" means "but". The conjunction "né" means "nor".
The conjunction "che" means "that". "che" is a relative. The conjunction "cioè" means "that is". The conjunction "nonostante" means "although". The preposition "nonostante" means "despite".
The preposition "in" means "in". The preposition "di" means "of". The preposition "da" means "from". The preposition "per" means "for". The preposition "fra" means "among".
The preposition "a" means "to". The preposition "con" means "with". The preposition "dopo" means "after".
The preposition "dietro" means "behind". The adverb "dietro" means "back". The preposition "a seconda di" means "according to".
The word "come" means "how". The preposition "come" means "like".
The word "per" begins the purpose. The word "di" begins the infinitive. The word "a" begins the cleft.
The reflexive pronoun "si" means "itself". The pronoun "lo" means "him". The dative pronoun "gli" means "him".
The pronoun "lui" means "he". The pronoun "lui" means "him". The pronoun "lui" does not precede the verb.
"Corriere della Sera" is a name.
The pronoun "mi" means "me". The pronoun "ne" means "it". "ne" is partitive.
The pronoun "molti" means "many". The pronoun "molti" does not precede the verb.
The masculine noun "passo" means "step". "passi" is the plural of "passo".
The masculine adjective "suo" means "hers". The feminine adjective "sua" means "hers". "suoi" is the plural of "suo". "sue" is the plural of "sua".').

newspaper_cecchi_part(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
"dormirà" is the future of "dorme".
The verb "c''è" means "there is". "ci sono" is the plural of "c''è".
"dormi" is the imperative of "dorme". "dormire" is the negative imperative of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangiato" is the participle of "mangia".
"mangi" is the second person of "mangia". "mangi" is the subjunctive of "mangia".
"mangia" is the imperative of "mangia". "mangiare" is the negative imperative of "mangia".
The verb "ha" means "has". "hanno" is the plural of "ha". "abbiamo" is the first person of "hanno". "ce" is the particle of "ha".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "avere" is the infinitive of "ha". "aver" is the infinitive of "ha".
The verb "dice" means "says". "dicono" is the plural of "dice". "disse" is the past of "dice". "dice" takes the clause.
The verb "spera" means "hopes". "sperano" is the plural of "spera". "sperare" is the infinitive of "spera". "spera" takes the clause.
The verb "recupera" means "recovers". "recuperato" is the participle of "recupera".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è". "sarà" is the future of "è".
The verb "firma" means "endorses". The intransitive verb "firma" means "signs". The transitive verb "firma" means "signs". "firmano" is the plural of "firma".
The verb "gioca" means "plays". "giochi" is the second person of "gioca". "giochi" is the subjunctive of "gioca".
The verb "va" means "goes". "andare" is the infinitive of "va".
The verb "ci va" means "goes". "ci vanno" is the plural of "ci va". "andarci" is the infinitive of "ci va".
The verb "ce ne corre" means "has a long way". "ce ne corrono" is the plural of "ce ne corre".
"said" is the past of "says".
The verb "occupa" means "occupies". "occupare" is the infinitive of "occupa". The verb "comincia" means "begins". "comincia" takes "a" before the infinitive.
The verb "passa" means "passes". "passi" is the second person of "passa". "passi" is the subjunctive of "passa".
The adverb "soltanto" means "only".').

newspaper_cecchi_part(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural. Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The masculine noun "perro" means "dog". "perros" is the plural of "perro". The masculine noun "gato" means "cat". "gatos" is the plural of "gato". The masculine noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". "casas" is the plural of "casa". The masculine noun "libro" means "book".
The masculine noun "técnico" means "coach". "técnico" is a person.
The masculine noun "abogado" means "lawyer". "abogado" is a person.
The masculine noun "miedo" means "fear". The masculine noun "fondo" means "background".
The masculine noun "juego" means "game". "juegos" is the plural of "juego".
The masculine noun "correo" means "courier". The feminine noun "tarde" means "evening".
The masculine noun "martes" means "tuesday". "martes" is a time.
The masculine adjective "cansado" means "tired". The masculine adjective "grande" means "big". "grandes" is the plural of "grande".
The masculine adjective "directo" means "direct". The masculine adjective "respectivo" means "respective". "respectivos" is the plural of "respectivo".
The adjective "directo" does not precede the noun.
The adverb "aquí" means "here". The adverb "también" means "also". The adverb "casi" means "almost". The adverb "de hecho" means "in fact".
The conjunction "y" means "and". The conjunction "o" means "or". The conjunction "pero" means "but". The conjunction "ni" means "nor".
The conjunction "que" means "that". "que" is a relative. The conjunction "es decir" means "that is". The conjunction "a pesar de" means "although". The preposition "a pesar de" means "despite".
The preposition "en" means "in". The preposition "de" means "of". The preposition "desde" means "from". The preposition "para" means "for". The preposition "entre" means "among".
The preposition "a" means "to". The preposition "con" means "with". The preposition "tras" means "after".
The preposition "detrás de" means "behind". The adverb "atrás" means "back". The preposition "según" means "according to".
The word "cómo" means "how". The preposition "como" means "like".
The word "para" begins the purpose.
The article "el" takes the day.
The reflexive pronoun "se" means "itself". The pronoun "lo" means "him". The dative pronoun "le" means "him".
The pronoun "él" means "he". The pronoun "él" means "him".
The pronoun "me" means "me".
The pronoun "muchos" means "many". The pronoun "muchos" does not precede the verb.
The masculine adjective "suyo" means "hers". The feminine adjective "suya" means "hers". "suyos" is the plural of "suyo". "suyas" is the plural of "suya".').

newspaper_cecchi_part(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
"dormirá" is the future of "duerme".
The verb "hay" means "there is". "hay" is the plural of "hay".
"duerme" is the imperative of "duerme". "duermas" is the negative imperative of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comido" is the participle of "come".
"come" is the imperative of "come". "comas" is the negative imperative of "come".
The verb "tiene" means "has". "tienen" is the plural of "tiene". "tener" is the infinitive of "tiene".
The auxiliary "ha" means "has". "han" is the plural of "ha". "haber" is the infinitive of "ha".
The verb "dice" means "says". "dicen" is the plural of "dice". "dijo" is the past of "dice".
The verb "espera" means "hopes". "esperan" is the plural of "espera". "esperar" is the infinitive of "espera".
The verb "recupera" means "recovers". "recuperado" is the participle of "recupera".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es". "será" is the future of "es".
The auxiliary "está" means "is". "están" is the plural of "está". "estaba" is the past of "está". The auxiliary "está" marks the state.
The verb "avala" means "endorses". The verb "firma" means "signs". "firman" is the plural of "firma".
The verb "va" means "goes". "ir" is the infinitive of "va".
The verb "hay un trecho" means "has a long way".
"said" is the past of "says".
The verb "ocupa" means "occupies". "ocupar" is the infinitive of "ocupa". The verb "comienza" means "begins". "comienza" takes "a" before the infinitive.
The verb "pasa" means "passes". "pasas" is the second person of "pasa".
The adverb "solamente" means "only".').

newspaper_cecchi_checks_1 :-
    nf_tr('Il cane firma il libro.', italian, spanish, A1),
    check('a verb whose transitive sense is the intransitive one''s English crosses as that sense: `non ho firmato nessun contratto'' took the first meaning left, `endorses'', where `"firma" is intransitive'' had passed `signs'' over -- `The transitive verb "firma" means "signs".'' says it', A1,
          'El perro firma el libro.'),
    nf_tr('Il cane firma il libro.', italian, english, A2),
    check('... and in English', A2,
          'The dog signs the book.'),
    nf_tr('Stanco il cane.', italian, spanish, A3),
    check('an adjective in front of its subject, the copula left out: `Incerto il futuro di Funari'' was refused, the adjective for a clause with no verb', A3,
          'El perro es cansado.'),
    nf_tr('Stanco il cane.', italian, english, A4),
    check('... and in English', A4,
          'The dog is tired.'),
    nf_tr('Il cane non mangia né dorme.', italian, spanish, A5),
    check('`né'' between two clauses joins them as nor, the denial before the first: `non mangia né dorme'' was refused', A5,
          'El perro no come ni duerme.'),
    nf_tr('El perro no come ni duerme.', spanish, italian, A6),
    check('... and the other way', A6,
          'Il cane non mangia né dorme.'),
    nf_tr('Il cane è nella casa.', italian, spanish, A7),
    check('the state''s copula for a place, where the lesson marks one (`The auxiliary "está" marks the state.''): `Non sono stato a Milano'' is `no he estado'', never `no he sido''', A7,
          'El perro está en la casa.'),
    nf_tr('Il cane è a Milano.', italian, spanish, A8),
    check('... and a name for the place takes `en'', Italian''s `a'' being no word for it in Spanish', A8,
          'El perro está en Milano.'),
    nf_tr('Il gatto dice che il cane è nella casa, ma che il gatto dorme.', italian, spanish, A9),
    check('... and a comma after the place''s phrase is no phrase of another kind: `sono effettivamente in corso, ma che ...'' kept the plain copula', A9,
          'El gato dice que el perro está en la casa, pero que el gato duerme.'),
    nf_tr('Il cane è grande.', italian, spanish, A10),
    check('a GUARD: a clause that says no place keeps the plain copula', A10,
          'El perro es grande.').

newspaper_cecchi_checks_2 :-
    nf_tr('Il "qui" è grande.', italian, spanish, B1),
    check('an article and a quoted adverb are one phrase, the adverb written in its marks: `Il "qui" di cui parla'' was refused, the adverb being no noun an article takes', B1,
          'El "aquí" es grande.'),
    nf_tr('Il "qui" è grande.', italian, english, B2),
    check('... and in English', B2,
          'The "here" is big.'),
    nf_tr('Il cane dorme martedì.', italian, spanish, B3),
    check('a day of the week takes the article where the lesson says so (`The article "el" takes the day.''): `da martedì scorso'' is `desde el martes pasado''', B3,
          'El perro duerme el martes.'),
    nf_tr('El perro duerme el martes.', spanish, italian, B4),
    check('... and the other way, where Italian has none', B4,
          'Il cane dorme martedì.'),
    nf_tr('Non sarà lui a dormire.', italian, spanish, B5),
    check('the cleft with its copula first, the pronoun after the verb: `non sarà lui a dialogare'' is `no conversará él''', B5,
          'No dormirá él.'),
    nf_tr('Non sarà lui a dormire.', italian, english, B6),
    check('... and in English', B6,
          'He will not sleep.'),
    nf_tr('Il cane dorme e la casa come sfondo.', italian, spanish, B7),
    check('an absolute phrase after a coordinator takes the word for `with'': `e il tribunale di Milano come sfondo'' was refused', B7,
          'El perro duerme y con la casa como fondo.'),
    nf_tr('Il Corriere della Sera dorme.', italian, spanish, B8),
    check('a name of several words the lesson states is one word, as the text spells it: `dal Corriere della Sera'' came out `del Correo de la Tarde''', B8,
          'El Corriere della Sera duerme.'),
    nf_tr('Il Corriere della Sera dorme.', italian, english, B9),
    check('... and in English', B9,
          'The Corriere della Sera sleeps.'),
    nf_tr('Il Tecnico Mario Rossi dorme.', italian, spanish, B10),
    check('a title in capitals before a name is a noun: `il suo Avvocato Francesco Assumma'' was three capitalised words no determiner could take', B10,
          'El técnico Mario Rossi duerme.'),
    nf_tr('Il Tecnico Mario la Casa dorme.', italian, spanish, B11),
    check('... and a small article inside a name the lesson knows a word of is the name''s: `il direttore Gabriele la Porta''', B11,
          'El técnico Mario la Casa duerme.'),
    nf_tr('Il cane spera di dormire, cioè di mangiare il pane.', italian, spanish, B12),
    check('`cioè'' before what it says again, an infinitive or a clause: `e cioè di aver firmato il passaggio'' was refused', B12,
          'El perro espera dormir, es decir comer el pan.'),
    nf_tr('Il cane spera di dormire, cioè che il gatto mangia.', italian, spanish, B13),
    check('... and before a clause of `that''', B13,
          'El perro espera dormir, es decir que el gato come.').

newspaper_cecchi_checks_3 :-
    nf_tr('Un diretto avvocato dorme.', italian, spanish, C1),
    check('an adjective the lesson says never precedes the noun stays after it: `il suo diretto superiore'' is `su jefe directo'', where `un buon cane'' is `un buen perro''', C1,
          'Un abogado directo duerme.'),
    nf_tr('Stanco della casa, il cane dorme.', italian, spanish, C2),
    check('an adjective in front of the clause with its adjuncts, said of the subject: `Stanco del caldo, Paolo ...'' was refused', C2,
          'Cansado de la casa, el perro duerme.'),
    nf_tr('Recuperato in casa, il cane dorme.', italian, spanish, C3),
    check('... and a participle with adjuncts only: `Sottratto per qualche momento al mare, Cecchi Paone ...'' was refused', C3,
          'Recuperado en casa, el perro duerme.'),
    nf_tr('Il cane spera di occuparmene.', italian, spanish, C4),
    check('an infinitive with two pronouns joined, the first in the form it takes before another: `occuparmene'' is `occupare'', `mi'' and `ne'', the partitive said of nothing', C4,
          'El perro espera ocuparme.'),
    nf_tr('Il cane spera di occuparmene.', italian, english, C5),
    check('... and in English', C5,
          'The dog hopes to occupy me.'),
    nf_tr('O quasi: il cane dorme.', italian, spanish, C6),
    check('a lead-in, a coordinator and an adverb before the colon: `O quasi: perché il timore ...'' was refused', C6,
          'O casi: el perro duerme.'),
    nf_tr('Il timore di dormire ce l''ha.', italian, spanish, C7),
    check('a phrase set in front with the pronoun that takes it up, and its own complement after it: `Il timore di infastidire Funari ce l''ha'' is a fear he has, and read as the subject it said the fear had him', C7,
          'Tiene el miedo de dormir.'),
    nf_tr('Lo mangia il timore di dormire.', italian, spanish, C8),
    check('a GUARD: a subject with an infinitive of its own that stands after its verb is no phrase set in front: `Lo rende noto un comunicato del Quirinale'' lost its `lo'' and the communique became the object', C8,
          'Lo come el miedo de dormir.'),
    nf_tr('Il cane della casa lo mangia.', italian, spanish, C9),
    check('a GUARD: a subject with a phrase of its own that is no infinitive stays the subject before its verb and its pronoun: `Il comitato nazionale di bioetica lo ha preso in esame'' was a phrase set in front and the committee its object', C9,
          'El perro de la casa lo come.'),
    nf_tr('Il cane mangia il pane di soltanto la casa.', italian, spanish, C10),
    check('a GUARD: a word that says `only'' before the phrase of a preposition stays with it: `un aumento di soltanto il 1,4%'' wrote `soltanto'' at the end of the sentence', C10,
          'El perro come el pan de solamente la casa.').

newspaper_cecchi_checks_4 :-
    nf_tr('"Il cane dorme" dice il gatto.', italian, spanish, D1),
    check('a quotation split by its report keeps the comma that follows the quotation: `"il cane dorme" dice il gatto'' was `... dice el gato'' with the comma lost', D1,
          '"El perro duerme", dice el gato.'),
    nf_tr('"Il cane" dice il gatto, "dorme in casa".', italian, spanish, D2),
    check('a quotation that opens on the subject and goes on after the report: `"questa trattativa" dice Cecchi Paone, "ha scatenato voci"'' came out with the report last and the marks round words that were no quotation', D2,
          '"El perro", dice el gato, "duerme en casa".'),
    nf_tr('"Il cane" dice lui, "dorme in casa".', italian, spanish, D3),
    check('... and with a pronoun for the report, which never stands before a verb: `dice lui'' read as `lo dice''', D3,
          '"El perro", dice él, "duerme en casa".'),
    nf_tr('"Il cane non mangia" dice lui, "né dorme in casa".', italian, spanish, D4),
    check('a comma that ends the report stays before the quotation that follows: `"non andrei mai al Tg 4" dice lui, "né vorrei pestare i piedi a nessuno"'' lost it', D4,
          '"El perro no come", dice él, "ni duerme en casa".').

newspaper_cecchi_checks_5 :-
    nf_tr('Dopo aver mangiato il pane, il cane dorme.', italian, spanish, E1),
    check('a perfect infinitive after a preposition is the auxiliary''s and a participle: `dopo aver mandato in onda'' was `tras tener emitido'', and in front of its clause the front stopped at `aver''', E1,
          'Tras haber comido el pan, el perro duerme.'),
    nf_tr('Il cane dorme dopo aver mangiato il pane.', italian, spanish, E2),
    check('... after the clause', E2,
          'El perro duerme tras haber comido el pan.'),
    nf_tr('Cioè dopo aver mangiato il pane.', italian, spanish, E3),
    check('... and a clause that is nothing else, after a lead-in: `Cioè dopo aver mandato in onda l''ultimo "punto di svolta".'' read the participle for a passive and was refused or garbled', E3,
          'Es decir tras haber comido el pan.'),
    nf_tr('Dopo aver mangiato il pane, il cane dorme.', italian, english, E4),
    check('... and in English', E4,
          'After having eated the bread, the dog sleeps.'),
    nf_tr('Il cane dorme a seconda di come il gatto mangia.', italian, spanish, E5),
    check('a preposition before `how'', the clause its question: `a seconda di come saranno andate le proprie trattative'' was refused', E5,
          'El perro duerme según cómo el gato come.'),
    nf_tr('Il cane dorme a seconda di come il gatto mangia.', italian, english, E6),
    check('... and in English', E6,
          'The dog sleeps according to how the cat eats.').

newspaper_cecchi_checks_6 :-
    nf_tr('Il cane spera di mangiare il pane e di dormire.', italian, spanish, F1),
    check('an infinitive after `e di'' is the verb''s own where one of the clause stands before it: `spera di aver discusso ..., e di poter dire la sua'' kept `de''', F1,
          'El perro espera comer el pan y dormir.'),
    nf_tr('Il cane spera di mangiare il pane e di dormire.', italian, english, F2),
    check('... and in English', F2,
          'The dog hopes to eat the bread and to sleep.'),
    nf_tr('Lui spera che passi in casa.', italian, spanish, F3),
    check('a second person nobody named is no subjunctive''s third in a clause of `that'': `Lui spera che passi al Biscione'' was `espera que pasas'', you', F3,
          'Él espera que pasa en casa.'),
    nf_tr('Infatti il cane dorme.', italian, spanish, F4),
    check('`infatti'' at the head is in front, as the other adverbs that join a clause to the one before it are', F4,
          'De hecho el perro duerme.'),
    nf_tr('Infatti il cane dorme.', italian, english, F5),
    check('... and in English', F5,
          'In fact the dog sleeps.'),
    nf_tr('Il cane dice la sua.', italian, spanish, F6),
    check('a feminine singular possessive alone is a thing, with no word before a person: `dire la sua'' was `decir a la suya''', F6,
          'El perro dice la suya.'),
    nf_tr('Dietro le case ci sono molti cani.', italian, spanish, F7),
    check('a phrase before `there is'' is no second thing there is: `Dietro le voci ci sono molti ragazzi'' was `hay las voces a muchos niños atrás''', F7,
          'Hay muchos perros detrás de las casas.'),
    nf_tr('Il cane dorme dietro anche in casa.', italian, spanish, F8),
    check('an adverb that says `also'' is no preposition''s object: `se la porta dietro anche nel caso'' read `dietro anche'' as a phrase, `detrás de también''', F8,
          'El perro duerme atrás también en casa.').

newspaper_cecchi_checks_7 :-
    nf_tr('Il cane dorme, nonostante i rispettivi giochi.', italian, spanish, G1),
    check('an article and an adjective before a word that is a noun and a verb''s form, all of one number, are one phrase: `i rispettivi programmi'' read `programmi'' for a verb after a comma and a connector, and the sentence was refused', G1,
          'El perro duerme, a pesar de los respectivos juegos.'),
    nf_tr('E in casa, il cane dorme:', italian, spanish, G2),
    check('a sentence that ends on a colon is read as the piece, the connector at its head before any division: `E per quella data, Funari spera ...:'' divided at its first comma, `data'' a command', G2,
          'Y en casa, el perro duerme:').


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
    retract((follow(_, verb) :- mean(_, not))),
    assertz(mean(camina, walks)), assertz(verb(camina)), assertz(past_of('caminó', camina)),
    reason_translate('The dog walked.', S7),
    check('English''s regular -ed read back to its base, and the lesson''s stated past', S7, 'El perro caminó.'),
    reason_translate('El perro caminó.', E7),
    check('and -ed made, from the third person the lesson gave', E7, 'The dog walked.'),
    assertz(mean(nada, swims)), assertz(verb(nada)), assertz(past_of(swam, swims)),
    assertz((take_in(V8, ba, past) :- verb(V8), end_in(V8, a))),
    reason_translate('Maria swam.', S8),
    check('a past by RULE: `takes "ba" in the past''', S8, 'Maria nadaba.'),
    reason_translate('Maria nadaba.', E8),
    check('and read through the rule; English''s past as stated', E8, 'Maria swam.'),
    retract((take_in(_, ba, past) :- verb(_), end_in(_, a))),
    retract(past_of(swam, swims)), retract(verb(nada)), retract(mean(nada, swims)),
    retract(past_of('caminó', camina)), retract(verb(camina)), retract(mean(camina, walks)),
    retract(past_of('comió', come)),
    yes_no(reason_translate('The dog ate the bread.', _), R9),
    check('a past the lesson gives no form for: refused whole', R9, no),
    assertz(past_of('comió', come)),
    retract(neg(precede('él', verb))),
    reason_translate('Maria eats with him.', S10),
    check('without the denial él precedes the verb like every pronoun, but serves as a subject and still stands after a preposition', S10, 'Maria come con él.'),
    assertz(neg(precede('él', verb))),
    assertz(neg(follow(grande, noun))),
    reason_translate('The cat reads a big book.', S11),
    check('a denial of the order rule for one word: `"grande" does not follow the noun''', S11, 'El gato lee un grande libro.'),
    retract(neg(follow(grande, noun))),
    retract(person_of(como, come)),
    reason_translate('I eat the bread.', S12),
    check('a person the lesson gives no form for is the third''s form', S12, 'Yo come el pan.'),
    assertz(person_of(como, come)),
    retract(precede(a, person)),
    reason_translate('Maria sees Omar.', S13),
    check('without `the word "a" precedes the person'', nothing before Omar', S13, 'Maria ve Omar.'),
    reason_translate('Whom does Maria see?', S14),
    check('and whom is bare quién, which reads as who: the lesson said nothing to tell them apart', S14, '¿Quién ve Maria?'),
    reason_translate('Maria ve a Omar.', E13),
    check('and a before Omar is the preposition it is', E13, 'Maria sees to Omar.'),
    assertz(precede(a, person)),
    retract(contraction_of(al, 'a el')),
    reason_translate('Maria sees the friend.', S15),
    check('without the contraction, its two words', S15, 'Maria ve a el amigo.'),
    assertz(contraction_of(al, 'a el')).

%% ---- what it refuses, whole ----------------------------------------------------------

refusals :-
    section('refused whole, and reason_untranslated/2 says which word'),
    yes_no(reason_translate('The house is old.', _), R1),
    check('a word the lesson has no meaning for', R1, no),
    reason_untranslated('The house is old.', U1),
    check('named', U1, [old]),
    yes_no(reason_translate('Maria sleeps.', _), R2),
    check('no known word at all: which way is not even settled', R2, no),
    reason_untranslated('Maria sleeps.', U2),
    check('the name is not reported, the verb is', U2, [sleeps]),
    reason_untranslated('Maria sleeps under the house.', U2b),
    check('a preposition the lesson has no word for is reported too', U2b, [sleeps, under]),
    reason_translate('The house.', R3a),
    check('A HEADING OF ONE PHRASE READS NOW, an article and its noun -- `Il futuro.'' in the Ferlaino interview -- where this pinned the refusal before 1.8.6', R3a, 'La casa.'),
    reason_translate('The big house.', R3),
    check('AND ONE WITH ITS ADJECTIVES SINCE 1.8.7, where this pinned the refusal: a heading is a phrase that names', R3, 'La casa grande.'),
    yes_no(reason_translate('Big house.', _), R3b),
    check('a phrase with no article names nothing in particular and still has no verb', R3b, no),
    reason_untranslated('Big house.', U3),
    check('and nothing untranslated: the words are known, the shape is not', U3, []),
    reason_translate('Maria has 3 dogs.', R4),
    check('A NUMBER IN DIGITS CROSSES AS ITSELF: it has no mean/2 row and needs none, where before 1.6.14 the lookup found nothing and the phrase was refused', R4, 'Maria tiene 3 perros.'),
    yes_no(reason_translate('The house is big. The house is old.', _), R5),
    check('two sentences, one refused: both refused', R5, no),
    yes_no(reason_translate('Maria does not sleep.', _), R6),
    check('a denied verb the lesson does not know', R6, no),
    reason_untranslated('Maria does not sleep.', U6),
    check('reported as its base form, the word as typed', U6, [sleep]),
    reason_translate('The dog sees the cat and the dog eats the bread.', R7),
    check('two clauses joined READ now, where this pinned the refusal before 1.6.1', R7,
          'El perro ve el gato y el perro come el pan.'),
    reason_translate('Maria eats "bread".', R8),
    check('A WORD IN QUOTATION MARKS TRANSLATES NOW, marks and all: newspaper prose puts scare quotes round an ordinary word, and tr_words/2 used to FAIL on the token', R8,
          'Maria come "pan".'),
    reason_translate('Maria come "pan".', R8b),
    check('and back, the marks kept round the word the other language uses', R8b, 'Maria eats "bread".'),
    catch(( reason_translate('La casa es grande.', french, _), E9 = none ), error(E9, _), true),
    check('a language the lesson did not name', E9, domain_error(language, french)),
    catch(( reason_translate(42, _), E10 = none ), error(E10, _), true),
    check('not text', E10, type_error(text, 42)).

%% ---- the lesson outlined -------------------------------------------------------------

outline :-
    section('the lesson as an outline'),
    lesson_text(Text),
    reason_outline(Text, Lines),
    Lines = [L1|_],
    check('the class with the most said about it first: its members and its four rules', L1,
          'Noun ("casa", "perro", "gato", "mesa", "libro", "pan", "huevo", "leche", "ciudad", "amigo", "amiga" and "sábado"): every noun that ends in "a" is feminine; every noun that does not end in "a" is masculine; every noun that ends in a vowel takes "s" in the plural; every noun that ends in a consonant takes "es" in the plural.'),
    yes_no(memberchk('Adjective ("grande", "rojo", "roja", "pequeño" and "pequeña"): every adjective follows the noun; every adjective that ends in a vowel takes "s" in the plural.', Lines), O2),
    check('the adjectives, with both their rules', O2, yes),
    yes_no(memberchk('"casa", a noun: means "house".', Lines), O3),
    check('a word with its class and its meaning', O3, yes),
    yes_no(memberchk('"el", an article: masculine; means "the"; "los" is the plural of it.', Lines), O4),
    check('an article with its gender and its stated plural', O4, yes),
    yes_no(memberchk('"son": is the plural of "es"; "eran" is the past of it; "somos" is the person of it.', Lines), O5),
    check('a stated plural, a stated past and a stated person, from the other side', O5, yes),
    yes_no(memberchk('"él", a pronoun: means "he" and "him"; does not precede the verb.', Lines), O6),
    check('a pronoun with two meanings and its denial', O6, yes),
    yes_no(memberchk('"ha", an auxiliary: means "has"; "han" is the plural of it; "he" is the person of it; "has" is the person of it; "había" is the past of it.', Lines), O7),
    check('the auxiliary with its forms', O7, yes),
    yes_no(memberchk('Feminine: a noun that ends in "a".', Lines), O8),
    check('a definition: the condition with its object', O8, yes),
    yes_no(memberchk('Masculine: a noun that does not end in "a".', Lines), O9),
    check('and negated', O9, yes).

%% ---- the vocabulary build.pl wrote ------------------------------------------------
%%
%% corpus/vocabulary/<language>.txt: tens of thousands of lesson lines, in
%% the shapes above, written by library/reasoning/corpus/build.pl out of
%% Apertium's dictionaries. A page needs a store teach.pl has taught (a
%% minute or two); this case learns the lines that mention a handful of
%% words, which is a second and enough to hold the SHAPES to the reader
%% and the translator: a noun with its gender and plural, a noun that is
%% also a verb's form, a verb's sixteen forms, an English past the -ed rule
%% cannot make, a person, a gender denied of a word its rule would get
%% wrong, an adverb.

vocabulary :-
    section('the vocabulary: corpus/vocabulary/<language>.txt, the lesson lines build.pl writes'),
    normalise_corpus_dir(Dir),
    atom_concat(Dir, '/vocabulary/spanish.txt', EsFile), atom_concat(Dir, '/vocabulary/italian.txt', ItFile),
    vocabulary_lines(EsFile, EsLines), length(EsLines, NEs), yes_no(NEs >= 60000, BigEs),
    check('the Spanish vocabulary is at least sixty thousand lines', BigEs, yes),
    vocabulary_lines(ItFile, ItLines), length(ItLines, NIt), yes_no(NIt >= 45000, BigIt),
    check('the Italian one at least forty-five thousand', BigIt, yes),
    Words = [profesor, 'periódico', gato, negro, duerme, hermano, coche, nuevo, rey, visita, ama,
             hijo, hija, problema, 'está', hace, makes, muy, casa, perro,
             come, 'comería', quiere, necesita, puede, esto, nadie, alguien, otro, cada, mucho, este, esta, aquel, hay, cuatro, corre, runs, ve,
             comienza, considera, considerada, concluye, concluida, pone, peligro],
    findall(L, ( member(L, EsLines), vocabulary_mentions(L, Words) ), Picked),
    length(Picked, NP), yes_no(NP >= 150, Enough),
    check('the lines that mention forty-six words of it: at least a hundred and fifty, the verbs carrying twenty each', Enough, yes),
    atomic_list_concat(Picked, ' ', Text), reason_learn(Text, Terms), length(Terms, NT),
    yes_no(NT >= NP, Learned), check('every one of them read by the reader', Learned, yes),
    yes_no(( memberchk(noun(hermano), Terms), memberchk(masculine(hermano), Terms), memberchk(plural_of(hermanos, hermano), Terms), memberchk(person(hermano), Terms) ), V1),
    check('a noun: its gender, its plural, a person', V1, yes),
    yes_no(( memberchk(masculine(problema), Terms), memberchk(neg(feminine(problema)), Terms) ), V2),
    check('a masculine noun in -a: the gender the rule would get wrong, denied', V2, yes),
    yes_no(( memberchk(past_of(hizo, hace), Terms), memberchk(past_of(made, makes), Terms), memberchk(participle_of(hecho, hace), Terms) ), V3),
    check('a verb''s past on both sides, and its participle', V3, yes),
    reason_translate('El profesor lee el periódico en la casa.', T4),
    check('a noun that is an adjective too is the noun where the sentence puts it', T4, 'The professor reads the newspaper in the house.'),
    reason_translate('El gato negro duerme.', T5),
    check('two words the lesson calls nouns: the first, where adjectives follow the noun', T5, 'The black cat sleeps.'),
    reason_translate('Mi hermano tiene un coche nuevo.', T6),
    check('a noun that is a verb''s form too (hermano, to twin) reads as the subject', T6, 'My brother has a new car.'),
    reason_translate('El rey visitó la ciudad.', T7),
    check('a preterite the vocabulary states', T7, 'The king visited the city.'),
    reason_translate('Tom estaba en la casa.', T8),
    check('and an imperfect, stated as a past as well', T8, 'Tom was in the house.'),
    reason_translate('Tom hizo el pan.', T9),
    check('an English past the -ed rule cannot make', T9, 'Tom made the bread.'),
    reason_translate('Maria ama a tu hija.', T10),
    check('a person as the object, marked, of a verb the vocabulary gives', T10, 'Maria loves your daughter.'),
    reason_translate('El problema es grande.', T11),
    check('the denied gender read', T11, 'The problem is big.'),
    reason_translate('The problem is big.', T12),
    check('and written: el, by the masculine fact the denial lets through', T12, 'El problema es grande.'),
    reason_translate('My brother has a car.', T13),
    check('into Spanish over the vocabulary', T13, 'Mi hermano tiene un coche.'),
    reason_untranslated('El rey visitó la ciudad.', U14),
    check('every word known', U14, []),
    reason_translate_page('El gato negro duerme. El xyzzy come el pan.', Page),
    check('a page: each sentence its own, and one refused names its word', Page,
          ['El gato negro duerme.'-'The black cat sleeps.', 'El xyzzy come el pan.'-refused([xyzzy])]).

vocabulary_lines(File, Lines) :-
    read_file_to_codes(File, Codes), split_string(Codes, "\n", " \t\r", Ss),
    findall(L, ( member(S, Ss), S \== "", \+ sub_string(S, 0, 1, _, "#"), atom_string(L, S) ), Lines).

%% a line mentions one of the words: a mention is between quotation marks
vocabulary_mentions(Line, Words) :-
    split_string(Line, "\"", "", Parts), vocabulary_odd(Parts, Mentions),
    member(M, Mentions), atom_string(A, M), memberchk(A, Words), !.
vocabulary_odd([_, M|Rest], [M|Ms]) :- !, vocabulary_odd(Rest, Ms).
vocabulary_odd(_, []).

%% ---- the shapes a vocabulary brings ---------------------------------------------------
%%
%% Over the vocabulary lines the section above learned -- `"comer" is the
%% infinitive of "come"', `"comiendo" is the gerund of "come"', `"comería" is
%% the conditional of "come"', `The modal "puede" means "can"', `The
%% masculine demonstrative "este" means "this"', `The determiner "cada"
%% means "each"', `The pronoun "esto" means "this"' with `The pronoun "esto"
%% does not precede the verb', `The verb "hay" means "there is"', `The
%% number "cuatro" means "four"' -- and the auxiliary the grammar lesson
%% gives for the progressive, `The auxiliary "está" means "is"'. Every
%% sentence goes both ways, and `there was' is refused: no past of `hay' is
%% stated anywhere.

shapes :-
    section('the shapes a vocabulary brings: an infinitive, a modal, the progressive, the conditional, this and that, there is'),
    %% ---- 1.6.14: the shapes newspaper prose wants, over the real vocabulary
    reason_translate('Maria comienza a comer el pan.', N1),
    check('A PREPOSITION MEANING `to'' BEFORE AN INFINITIVE IS THE INFINITIVE, where the pp clause took the word and refused the sentence', N1, 'Maria begins to eat the bread.'),
    reason_translate('Maria quiere comer el pan y ver el gato.', N2),
    check('a conjunction between two complements, not inside a phrase (querer means wants since 1.8.0, whose extra line comes before the dictionary''s loves)', N2, 'Maria wants to eat the bread and to see the cat.'),
    reason_translate('Maria quiere poner en peligro la casa.', N3),
    check('a phrase ends at a determiner once it has its noun: `en peligro'' and then the object', N3, 'Maria wants to put in danger the house.'),
    reason_translate('La casa es considerada concluida.', N4),
    check('a participle predicated of the subject, after a passive that spent the copula', N4, 'The house is considered concluded.'),
    reason_translate('The house is considered concluded.', N5),
    check('and back, the participle agreeing with the subject', N5, 'La casa es considerada concluida.'),
    reason_translate('Maria wants to eat the bread.', S1),
    check('`to'' and a base form is the lesson''s infinitive', S1, 'Maria quiere comer el pan.'),
    reason_translate('Maria necesita comer el pan.', S2),
    check('and back, with another verb than querer', S2, 'Maria needs to eat the bread.'),
    reason_translate('Necesito dormir.', S3),
    check('a first person the vocabulary states, and its verb''s infinitive', S3, 'I need to sleep.'),
    reason_translate('Maria can eat the bread.', S4),
    check('a modal: the base form bare after it', S4, 'Maria puede comer el pan.'),
    reason_translate('Maria puede comer el pan.', S5),
    check('and back: can, never does', S5, 'Maria can eat the bread.'),
    reason_translate('Maria cannot eat.', S6),
    check('cannot is can denied', S6, 'Maria no puede comer.'),
    reason_translate('Maria no puede comer.', S7),
    check('and back', S7, 'Maria cannot eat.'),
    reason_translate('¿Puede Maria comer el pan?', S8),
    check('the modal fronts a question', S8, 'Can Maria eat the bread?'),
    reason_translate('Maria podría comer.', S9),
    check('the conditional of a modal is could', S9, 'Maria could eat.'),
    reason_translate('Maria could eat.', S10),
    check('and could is the past of can', S10, 'Maria pudo comer.'),
    reason_translate('Maria is eating the bread.', S11),
    check('the progressive: the auxiliary that means is, and the gerund', S11, 'Maria está comiendo el pan.'),
    reason_translate('Maria está comiendo el pan.', S12),
    check('and back', S12, 'Maria is eating the bread.'),
    reason_translate('The dogs were eating.', S13),
    check('in the past and the plural', S13, 'Los perros estaban comiendo.'),
    reason_translate('Estoy comiendo.', S14),
    check('in the first person, with no subject', S14, 'I am eating.'),
    reason_translate('¿Está comiendo Maria?', S15),
    check('a question, the subject after the group', S15, 'Is Maria eating?'),
    reason_translate('Maria would eat the bread.', S16),
    check('the conditional: would and the base form', S16, 'Maria comería el pan.'),
    reason_translate('Los perros comerían.', S17),
    check('and back, the plural the vocabulary states', S17, 'The dogs would eat.'),
    reason_translate('This dog eats.', S18),
    check('a demonstrative agrees like an article', S18, 'Este perro come.'),
    reason_translate('Estas casas son grandes.', S19),
    check('these is this in the plural', S19, 'These houses are big.'),
    reason_translate('These houses are big.', S20),
    check('and back, estas by the noun''s gender', S20, 'Estas casas son grandes.'),
    reason_translate('Maria sees that dog.', S21),
    check('that is aquel', S21, 'Maria ve aquel perro.'),
    reason_translate('Each dog eats.', S22),
    check('a determiner the vocabulary gives', S22, 'Cada perro come.'),
    reason_translate('Maria tiene otros perros.', S23),
    check('other is another in the plural', S23, 'Maria has other dogs.'),
    reason_translate('Many dogs eat.', S24),
    check('many is much in the plural', S24, 'Muchos perros comen.'),
    reason_translate('Esto es grande.', S25),
    check('a pronoun that stands alone, as the subject', S25, 'This is big.'),
    reason_translate('Maria sees this.', S26),
    check('and as the object, after the verb', S26, 'Maria ve esto.'),
    reason_translate('Nadie come el pan.', S27),
    check('nobody', S27, 'Nobody eats the bread.'),
    reason_translate('Is this big?', S28),
    check('this alone in a question is the subject, not a phrase', S28, '¿Esto es grande?'),
    reason_translate('There is a dog in the house.', S29),
    check('there is: the lesson''s verb, no subject', S29, 'Hay un perro en la casa.'),
    reason_translate('Hay un perro en la casa.', S30),
    check('and back', S30, 'There is a dog in the house.'),
    reason_translate('Hay perros.', S31),
    check('the copula in the number of what there is', S31, 'There are dogs.'),
    reason_translate('No hay perros.', S32),
    check('denied: there are no', S32, 'There are no dogs.'),
    reason_translate('There is no dog.', S33),
    check('and back, the article dropped', S33, 'No hay perro.'),
    reason_translate('¿Hay un perro?', S34),
    check('a question', S34, 'Is there a dog?'),
    reason_translate('Is there a dog?', S35),
    check('and back', S35, '¿Hay un perro?'),
    reason_translate('Maria tiene cuatro perros.', S36),
    check('a number the vocabulary gives', S36, 'Maria has four dogs.'),
    ( reason_translate('Había un perro.', S37) -> true ; S37 = refused ),
    check('there was: the past of hay is stated since the Bovalino letter (corpus/extra, `"había" is the past of "hay".''), where it was refused', S37, 'There was a dog.'),
    reason_translate('The cat is sleeping.', S38),
    check('a gerund by the -ing rule: sleep, sleeping', S38, 'El gato está durmiendo.'),
    reason_translate('The cat is running.', S39),
    check('and one the vocabulary states, run, running', S39, 'El gato está corriendo.'),
    reason_translate('El gato está corriendo.', S40),
    check('and back', S40, 'The cat is running.'),
    reason_translate('These are big.', S41),
    check('these alone: the first word for this that has a plural, so estos and not esto', S41, 'Estos son grandes.'),
    reason_translate('Estos son grandes.', S42),
    check('and back', S42, 'These are big.'),
    reason_translate('Maria sees these.', S43),
    check('and as the object', S43, 'Maria ve estos.'),
    reason_translate('¿Necesita comer Maria?', S44),
    check('an infinitive between the verb and its subject in a question', S44, 'Does Maria need to eat?'),
    reason_translate('Maria needs to see Omar.', S45),
    check('an infinitive and then a person as the object, marked', S45, 'Maria necesita ver a Omar.'),
    reason_translate('Maria may eat.', S46),
    check('may: the same word as can, which the dictionary says', S46, 'Maria puede comer.'),
    reason_translate('Maria might eat.', S47),
    check('might is may in the conditional', S47, 'Maria podría comer.'),
    reason_translate('Somebody is eating.', S48),
    check('somebody, standing alone', S48, 'Alguien está comiendo.'),
    reason_translate('Alguien está comiendo.', S49),
    %% (the dictionary's first meaning was `anybody', which Italian writes
    %% `nessuno', nobody: `Alguien debería estudiar el fenómeno' said the
    %% opposite of itself, and corpus/extra/ puts `somebody' first since 1.8.13)
    check('and back as somebody: the lesson''s first meaning, where the dictionary''s was anybody', S49, 'Somebody is eating.'),
    reason_translate('Maria estará comiendo.', S50),
    check('the future progressive, by the auxiliary''s stated future', S50, 'Maria will be eating.'),
    reason_translate('Which dog can sleep?', S51),
    check('which, with a modal', S51, '¿Qué perro puede dormir?'),
    reason_translate('Where is Maria eating?', S52),
    check('where, with the progressive', S52, '¿Dónde está comiendo Maria?'),
    reason_translate('¿No hay perro?', S53),
    check('there is, denied and asked', S53, 'Is there no dog?').

%% ---- the build, when the raw dictionaries are here --------------------------------
%%
%% tools/corpus/fetch.sh puts Apertium's dictionaries under corpus/raw/, which
%% is not committed; where they are, the Spanish vocabulary is built again
%% into a scratch directory and must come out byte for byte the committed
%% file -- the build is a function of its inputs, and a rebuild that
%% differed would be a change nobody made.

build :-
    section('the build: build.pl over corpus/raw reproduces the committed file'),
    %% (absolute, because the links below are made to it: with no
    %% $COCOLOG_LIBRARY the directory is the relative `library/...', a
    %% relative link resolves against the scratch directory it sits in, and
    %% the build read nothing and exited 1 with no reason given)
    normalise_corpus_dir(Dir0), absolute_file_name(Dir0, Dir),
    atom_concat(Dir, '/raw/apertium-spa.spa.dix', Spa),
    (   exists_file(Spa)
    ->  scratch(S), atom_concat(S, '/corpus', C), make_directory(C),
        atom_concat(C, '/vocabulary', CV), make_directory(CV),
        atom_concat(Dir, '/raw', Raw), atom_concat(C, '/raw', CRaw),
        shl(['ln -s ', Raw, ' ', CRaw]),
        %% `extra/' is an INPUT to the build exactly as `raw/' is -- the lines
        %% Apertium does not carry, appended by cb_extra/1 -- so the scratch
        %% corpus needs it or the built file is short by those lines
        atom_concat(Dir, '/extra', Extra), atom_concat(C, '/extra', CExtra),
        shl(['ln -s ', Extra, ' ', CExtra]),
        cocolog(Exe), sh_join(['COCOLOG_CORPUS=', C, ' ', Exe, ' -s library/reasoning/corpus/build.pl -- spanish 2>&1'], Cmd),
        proc_run(Cmd, 600000, _, Exit),
        check('build.pl -- spanish exits 0 over the raw dictionaries', Exit, 0),
        atom_concat(CV, '/spanish.txt', Built), atom_concat(Dir, '/vocabulary/spanish.txt', Committed),
        sh_join(['cmp -s ', Built, ' ', Committed], Cmp), sh_exit(Cmp, Same),
        check('and writes the committed file byte for byte', Same, 0),
        shl(['rm -rf ', S])
    ;   format("     (skipped: no corpus/raw/apertium-spa.spa.dix -- sh tools/corpus/fetch.sh)~n", [])
    ).
