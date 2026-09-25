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

    %% THE COST, STATED: Spanish ATTACHES the pronoun to an affirmative
    %% imperative and accents the stem (`Comelo.', `Dame eso.'), and nothing
    %% in a lesson says either, so such a sentence is refused.
    yes_no(reason_ir('Comelo.', spanish, _), I14),
    check('an ATTACHED clitic is not read, and the header says so', I14, no),

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
    nf_tr('Dormono nella casa soltanto quelli che mangiano il pane.', italian, english, I12),
    check('an intransitive verb''s subject after its adjuncts carries its relative clause', I12,
          'Those that eat the bread sleep in the house only.'),
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
The adverb "poi" means "then".
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
The adverb "entonces" means "then".
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
    nf_tr('Poi il cane disse che il gatto dorme.', italian, spanish, M18),
    check('a lifted adverb goes before a `that'' clause, where it read as the clause''s', M18, 'El perro dijo entonces que el gato duerme.'),
    nf_tr('Poi il cane disse che il gatto dorme.', italian, english, M19),
    check('... and English writes it there too', M19, 'The dog said then that the cat sleeps.'),
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
    yes_no(IR20 = [ir(gap([obj(name(juan))], [obj(name(pedro)), sep, obj(co(w(',', lcomma), name(casa), _))|_]), _)], C20),
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
    ( reason_translate('Había un perro.', _) -> S37 = translated ; S37 = refused ),
    check('there was: no past of hay is stated, so refused', S37, refused),
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
    check('and back as anybody: the dictionary''s first meaning, kept as it is', S49, 'Anybody is eating.'),
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
    normalise_corpus_dir(Dir), atom_concat(Dir, '/raw/apertium-spa.spa.dix', Spa),
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
