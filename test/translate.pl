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
    adjuncts, newspaper_es, newspaper_it, newspaper_fiat, newspaper_valencia, newspaper_bio, questions, rules, refusals, outline, vocabulary, shapes, build,
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

    reason_translate('La casa imposta domina.', italian, english, D1),
    check('a participle after the noun is a reduced relative', D1, 'The house imposed dominates.'),

    reason_translate('The house imposed dominates.', english, italian, D2),
    check('and back, THE PARTICIPLE AGREEING with its own noun', D2, 'La casa imposta domina.'),

    reason_translate('Il pane imposto domina.', italian, english, D3),
    check('a masculine noun takes the other form', D3, 'The bread imposed dominates.'),

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

    reason_translate('Qui dominava il generale.', italian, english, V1),
    check('the adverb is fronted and the subject follows the verb', V1,
          'The general dominated here.'),

    reason_translate('Qui dominava il generale.', italian, spanish, V2),
    check('and into Spanish', V2, 'El general dominaba aqui.'),

    reason_ir('Qui dominava il generale.', italian, V3),
    check('the IR is an ordinary statement: the adjunct is a complement', V3,
          [ir(s(none, np(det(article, the, w(the, lower)), none, [], w(general, lower), singular),
                g(dominates, past, simple, no), [adv(w(here, lower))]), 46)]),

    reason_translate('Qui dominava il generale.', italian, italian, V4),
    check('THE FRONTING IS NOT WRITTEN BACK: the statement''s own order', V4,
          'Il generale dominava qui.'),

    reason_ir('Dominava il generale.', italian, V5),
    check('nothing fronted, so nothing says the phrase is the subject: it is the OBJECT, of a subject nobody named', V5,
          [ir(s(none, null(third, singular), g(dominates, past, simple, no),
                [obj(np(det(article, the, w(the, lower)), none, [], w(general, lower), singular))]), 46)]),

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
    yes_no(reason_translate('El pan del perro.', spanish, italian, _), N15),
    check('and a statement with none is still refused', N15, no),
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
    yes_no(reason_translate('The house.', _), R3),
    check('no verb', R3, no),
    reason_untranslated('The house.', U3),
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
    check('a conjunction between two complements, not inside a phrase (querer means loves before wants, which is the dictionary''s order)', N2, 'Maria loves to eat the bread and to see the cat.'),
    reason_translate('Maria quiere poner en peligro la casa.', N3),
    check('a phrase ends at a determiner once it has its noun: `en peligro'' and then the object', N3, 'Maria loves to put in danger the house.'),
    reason_translate('La casa es considerada concluida.', N4),
    check('a participle predicated of the subject, after a passive that spent the copula', N4, 'The house is considered concluded.'),
    reason_translate('The house is considered concluded.', N5),
    check('and back, the participle agreeing with the subject', N5, 'La casa es considerada concluida.'),
    reason_translate('Maria wants to eat the bread.', S1),
    check('`to'' and a base form is the lesson''s infinitive', S1, 'Maria quiere comer el pan.'),
    reason_translate('Maria necesita comer el pan.', S2),
    check('and back (querer means loves before wants, so another verb)', S2, 'Maria needs to eat the bread.'),
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
