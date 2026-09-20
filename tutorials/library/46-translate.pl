%% cocolog tutorial 46 -- library(reasoning/translate): a language lesson as a knowledge base.
%%
%% TIER 2: `use_module(library(reasoning/translate))', from library/reasoning/translate.pl.
%% Clauses only, over library(reasoning/reason): nothing to build, no model,
%% no lexicon, no store.
%%
%%     cocolog -s tutorials/library/46-translate.pl
%%
%% THE PROBLEM THIS SOLVES. Tutorial 43 reads a paragraph into facts and
%% rules and proves things over them. This lesson reads a paragraph that
%% TEACHES: one hundred and seventy-six lines of Spanish in the same
%% controlled English, and what comes out is a vocabulary as facts, a
%% grammar as rules -- gender, the order of an adjective, the plural, the
%% word that denies, the question words and the mark a question begins
%% with, the past, the future and the perfect of each verb, its first and
%% second persons, the pronouns and where they stand, the word that goes
%% before a person, two contractions -- and a translator
%% that asks the knowledge base and knows no word of Spanish itself.
%% Nothing was trained and nothing was written into the library for it:
%% the lesson is the whole of what the translator knows.
%%
%% A WORD IN QUOTATION MARKS IS MENTIONED, NOT USED. `"casa" means "house"'
%% is not about a house, it is about the word: mean(casa, house). `The noun
%% "casa"' says what the word is besides, noun(casa); `the feminine article
%% "la"' says two things, article(la) and feminine(la); and a rule may be
%% over the letters of a word -- `Every noun that ends in "a" is feminine'
%% is feminine(X) :- noun(X), end_in(X, a), with end_in/2 the library's so
%% that the rule RUNS.
%%
%% THE TRANSLATOR KNOWS WHAT TO ASK, AND NOTHING ELSE. What a word means,
%% mean/2; what it is, noun/1, adjective/1, verb/1, article/1; its gender,
%% feminine/1 and masculine/1, said of it or ruled; whether an adjective
%% follows its noun, follow(A, noun); its plural, plural_of/2 when the
%% lesson stated one (`"los" is the plural of "el"') and take_in(W, E,
%% plural) when a rule gives the ending (`Every noun that ends in a vowel
%% takes "s" in the plural'); its past and its future the same way; its
%% participle and the auxiliary of the perfect; its first and second
%% persons (`"como" is the first person of "come"'); the word for `not';
%% and whether a pronoun precedes the verb. The lesson answers in its own
%% words, and a lesson in Italian, or one whose rule is that every
%% adjective PRECEDES the noun, is read by the same clauses. Section 6
%% proves it by taking the order rule away, and section 14 by learning a
%% second lesson under its own name. What the translator knows on its own
%% is ENGLISH: `is' and `are', `does not' and `do not', `will', `has' and
%% `had', its pronouns, a plural by -s, `an' before a vowel -- the
%% library's own language, and the one the lesson is written in.

:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/translate)).

%% in three parts, because a clause over a page (8 KB) cannot be stored
lesson(Text) :- lesson_part(1, A), lesson_part(2, B), lesson_part(3, C), atomic_list_concat([A, ' ', B, ' ', C], Text).

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
The number "dos" means "two".
The number "tres" means "three".
The conjunction "y" means "and".').

main :-
    section_1, section_2, section_3, section_4, section_5, section_6, section_7, section_8, section_9, section_10,
    section_11, section_12, section_13, section_14, section_15,
    format("~nA lesson is a knowledge base; a translation is a proof over it.~ndone~n", []).

%% Each section its own clause: one clause holding the whole lesson ran over the
%% page a stored clause must fit in, which cocolint flags.

section_1 :-
    format("~n1. The lesson: one hundred and seventy-six lines of controlled English, and what they say~n", []),
    lesson(Text),
    reason_learn(Text, Terms),
    length(Terms, N),
    must('terms learned', N, 289),
    Terms = [T1, T2, T3|_],
    must('the language', T1, language(spanish)),
    must('a class fact about the word, then what it means', T2-T3, noun(casa)-mean(casa, house)),
    member((feminine(X4) :- B4), Terms), copy_term(X4-B4, x-B4c),
    must('a rule over the letters of a word', B4c, (noun(x), end_in(x, a))),
    member((follow(X5, noun) :- B5), Terms), copy_term(X5-B5, x-B5c),
    must('and the rule of order', B5c, adjective(x)),
    member((take_in(X6, es, plural) :- B6), Terms), copy_term(X6-B6, x-B6c),
    must('a rule of the plural, over a letter class', B6c, (noun(x), end_in(x, consonant))),
    must('and a plural said outright', [plural_of(los, el), plural_of(son, es)], [plural_of(los, el), plural_of(son, es)]),
    ( memberchk(person_of(como, come), Terms), memberchk(first(como), Terms) -> P7 = yes ; P7 = no ),
    must('`"como" is the first person of "come"'': the relation, and the adjective as a fact about the word', P7, yes),
    show('la, as the lesson put it', [article(la), feminine(la), mean(la, the)]).

section_2 :-
    format("~n2. The lesson questioned -- reason_ask/2 over the same knowledge base~n", []),
    reason_ask('Is "mesa" feminine? Is "perro" feminine? What does "perro" mean? Why is "mesa" feminine?', As),
    As = [A1, A2, A3, A4],
    must('yes, by the rule, with the body that proved', A1, yes(rule((feminine(mesa) :- noun(mesa), end_in(mesa, a))))),
    must('unknown: the lesson never said, and unknown is an answer', A2, unknown),
    must('the meaning, and that it was said', A3, [dog-fact]),
    must('the whole proof in sentences', A4, because('"mesa" is feminine because "mesa" is a noun and "mesa" ends in "a".')).

section_3 :-
    format("~n3. Into Spanish: the article and the adjective agree with the noun, the adjective follows it~n", []),
    reason_translate('The house is big.', S1),
    must('la, because casa ends in a; grande has no gender and fits any noun', S1, 'La casa es grande.'),
    reason_translate('The dog eats the bread.', S2),
    must('el twice: neither perro nor pan ends in a', S2, 'El perro come el pan.'),
    reason_translate('Maria has a red table.', S3),
    must('a name passes through; una and roja agree with mesa, and roja stands after it', S3, 'Maria tiene una mesa roja.'),
    reason_translate('The table is red.', S4),
    must('a bare adjective after the verb agrees with the subject', S4, 'La mesa es roja.'),
    reason_translate('The house is big. The dog eats the bread!', S5),
    must('two sentences, each ending as it ended', S5, 'La casa es grande. El perro come el pan!').

section_4 :-
    format("~n4. Into English: which way, the words say~n", []),
    reason_translate('La casa es grande.', E1),
    must('the words are the lesson''s, so the target is English', E1, 'The house is big.'),
    reason_translate('Maria tiene una mesa roja.', E2),
    must('the adjective back before its noun', E2, 'Maria has a red table.'),
    reason_translate('The dog eats the bread.', S2), reason_translate(S2, E3),
    must('the round trip', E3, 'The dog eats the bread.'),
    reason_translate('The cat reads a big book.', spanish, S6),
    must('or name the language: the name the lesson gave it', S6, 'El gato lee un libro grande.'),
    reason_translate(S6, english, E6),
    must('and english', E6, 'The cat reads a big book.').

section_5 :-
    format("~n5. What it refuses -- whole, never half -- and reason_untranslated/2~n", []),
    ( reason_translate('The house is old.', _) -> R1 = translated ; R1 = refused ),
    must('a word the lesson has no meaning for', R1, refused),
    reason_untranslated('The house is old.', U1),
    must('and which word to teach', U1, [old]),
    reason_untranslated('Maria sleeps under the house.', U2),
    must('a name is not reported; every other unknown word is', U2, [sleeps, under]),
    catch(( reason_translate('La casa es grande.', french, _), E7 = none ), error(E7, _), true),
    must('a language the lesson did not name', E7, domain_error(language, french)).

section_6 :-
    format("~n6. The order is the rule, not the code: take the rule away~n", []),
    retract((follow(X8, noun) :- adjective(X8))),
    reason_translate('Maria has a red table.', S8),
    must('without `every adjective follows the noun'', English''s order', S8, 'Maria tiene una roja mesa.'),
    assertz((follow(X9, noun) :- adjective(X9))),
    reason_translate('Maria has a red table.', S9),
    must('the rule back, the order back', S9, 'Maria tiene una mesa roja.'),
    reason_learn('The noun "mano" means "hand". "mano" is feminine.'),
    reason_translate('The hand is red.', S10),
    must('an exception the lesson states wins over the rule: feminine is asked first', S10, 'La mano es roja.').

section_7 :-
    format("~n7. The lesson outlined -- reason_outline/2 over the same text~n", []),
    lesson(Text),
    reason_outline(Text, Lines),
    Lines = [L1, L2|_],
    must('the class most is said about, with its members and its four rules', L1,
         'Noun ("casa", "perro", "gato", "mesa", "libro", "pan", "huevo", "leche", "ciudad", "amigo" and "amiga"): every noun that ends in "a" is feminine; every noun that does not end in "a" is masculine; every noun that ends in a vowel takes "s" in the plural; every noun that ends in a consonant takes "es" in the plural.'),
    must('then the pronouns, with the one rule over them', L2,
         'Pronoun ("yo", "tú", "él", "ella", "nosotros", "ellos", "me", "te", "lo", "la", "nos", "los" and "le"): every pronoun precedes the verb.'),
    memberchk('The verb: "es", "come", "lee", "tiene", "vive", "ve", "da" and "canta"; every verb that ends in "e" takes "n" in the plural; every verb that ends in "e" takes "rá" in the future; every verb that ends in "a" takes "rá" in the future; "no" precedes it.', Lines),
    memberchk('"el", an article: masculine; means "the"; "los" is the plural of it.', Lines),
    memberchk('Feminine: a noun that ends in "a".', Lines),
    show('a word''s own line, and a definition''s', ['"el", an article: masculine; means "the"; "los" is the plural of it.', 'Feminine: a noun that ends in "a".']).

section_8 :-
    format("~n8. The plural and the denial: the lesson's endings, its stated plurals, its word for not~n", []),
    reason_translate('The houses are big.', P1),
    must('las and casas by the ending rules, son as stated, grandes by the rule', P1, 'Las casas son grandes.'),
    reason_translate('The dogs do not eat the bread.', P2),
    must('a denial: the lesson''s word before the verb, and comen by the verb rule', P2, 'Los perros no comen el pan.'),
    reason_translate('Maria has an egg.', P3),
    must('an, which is English''s own, is a', P3, 'Maria tiene un huevo.'),
    reason_translate('Las casas no son grandes.', P4),
    must('back: are not', P4, 'The houses are not big.'),
    reason_translate('Maria no tiene una mesa roja.', P5),
    must('does not, with the base form', P5, 'Maria does not have a red table.'),
    reason_translate('Maria tiene unos libros.', P6),
    must('unos is the plural of un, and English has no plural a', P6, 'Maria has books.'),
    reason_ask('What is the plural of "el"? Why does "pan" take "es" in the plural?', A8),
    A8 = [A81, A82],
    must('a stated plural, asked for', A81, [los-fact]),
    must('a ruled one, explained', A82, because('"pan" takes "es" in the plural because "pan" is a noun and "pan" ends in a consonant.')).

section_9 :-
    format("~n9. Questions: yes or no, `what' for the object, `who' for the subject~n", []),
    reason_translate('Is the house big?', Q1),
    must('English fronts the copula; the lesson''s language keeps the statement''s order and opens with its mark', Q1, '¿La casa es grande?'),
    reason_translate('What does the dog eat?', Q2),
    must('what asks for the object, and the verb comes before the subject', Q2, '¿Qué come el perro?'),
    reason_translate('Who does not eat the bread?', Q3),
    must('who asks for the subject; a denial stays on the verb', Q3, '¿Quién no come el pan?'),
    reason_translate('¿Es grande la casa?', Q4),
    must('back, from the order Spanish prefers', Q4, 'Is the house big?'),
    reason_translate('¿Qué come Maria?', Q5),
    must('what does Maria eat', Q5, 'What does Maria eat?'),
    reason_translate('¿Los perros comen el pan?', Q6),
    must('do the dogs', Q6, 'Do the dogs eat the bread?').

section_10 :-
    format("~n10. The past: a form the lesson states, of the singular and of the plural; English's own -ed, was, were, did~n", []),
    reason_translate('The dog ate the bread.', PT1),
    must('the past the lesson stated for "come"; "ate" is English''s, stated too', PT1, 'El perro comió el pan.'),
    reason_translate('The dogs did not eat the bread.', PT2),
    must('did not says the past, and the plural form has its own', PT2, 'Los perros no comieron el pan.'),
    reason_translate('Was the house big?', PT3),
    must('was, fronted', PT3, '¿La casa era grande?'),
    reason_translate('¿Qué comió el perro?', PT4),
    must('what did', PT4, 'What did the dog eat?'),
    reason_translate('Las casas eran grandes.', PT5),
    must('were', PT5, 'The houses were big.'),
    reason_translate('Maria tenía una mesa roja.', PT6),
    must('had', PT6, 'Maria had a red table.').

section_11 :-
    format("~n11. Persons and pronouns: the lesson's first and second persons, its pronouns, and a subject the verb says~n", []),
    reason_translate('I eat the bread.', PP1),
    must('yo, and como: `"como" is the first person of "come"''', PP1, 'Yo como el pan.'),
    reason_translate('We were big.', PP2),
    must('the first person of the plural past', PP2, 'Nosotros fuimos grandes.'),
    reason_translate('She sees him.', PP3),
    must('him is lo, and every pronoun precedes the verb', PP3, 'Ella lo ve.'),
    reason_translate('Maria eats with him.', PP4),
    must('after a preposition, the pronoun the lesson says does not: `the pronoun "él" does not precede the verb''', PP4, 'Maria come con él.'),
    reason_translate('Comemos el pan.', PP5),
    must('no subject: comemos says we', PP5, 'We eat the bread.'),
    ( reason_translate('Come el pan.', _) -> PP6 = translated ; PP6 = refused ),
    must('come says he, she or it: refused rather than guessed', PP6, refused),
    reason_translate('Él no la ve.', PP7),
    must('a capital É is a capital; la before the verb is her', PP7, 'He does not see her.'),
    reason_translate('Te veo.', PP8),
    must('te could be you the subject, but veo says I: the object', PP8, 'I see you.'),
    reason_translate('Sus perros la ven.', PP9),
    must('su before a noun is a possessive; la after the noun is the object', PP9, 'His dogs see her.'),
    reason_translate('¿Comes el pan?', PP10),
    must('a question with no subject: comes says you', PP10, 'Do you eat the bread?').

section_12 :-
    format("~n12. The future and the perfect: an ending rule or a stated form, and the auxiliary the lesson names~n", []),
    reason_translate('The dog will eat the bread.', PF1),
    must('comerá: `every verb that ends in "e" takes "rá" in the future''', PF1, 'El perro comerá el pan.'),
    reason_translate('The house will not be big.', PF2),
    must('será, stated, and denied', PF2, 'La casa no será grande.'),
    reason_translate('I will eat the bread.', PF3),
    must('the first person of the future form', PF3, 'Yo comeré el pan.'),
    reason_translate('¿Qué comerá el perro?', PF4),
    must('what will', PF4, 'What will the dog eat?'),
    reason_translate('The dog has eaten the bread.', PF5),
    must('`the auxiliary "ha" means "has"'', and the participle stated', PF5, 'El perro ha comido el pan.'),
    reason_translate('I have not eaten.', PF6),
    must('the first person of the auxiliary, denied', PF6, 'Yo no he comido.'),
    reason_translate('The dogs had eaten the bread.', PF7),
    must('had: the past of the plural auxiliary', PF7, 'Los perros habían comido el pan.'),
    reason_translate('¿Ha comido el perro el pan?', PF8),
    must('the auxiliary first, the subject after the participle', PF8, 'Has the dog eaten the bread?'),
    reason_translate('Hemos comido.', PF9),
    must('hemos says we', PF9, 'We have eaten.').

section_13 :-
    format("~n13. Phrases, adverbs, numbers, two joined -- and where, when, which~n", []),
    reason_translate('Maria eats the bread with Omar in the house.', PH1),
    must('two prepositional phrases, in order', PH1, 'Maria come el pan con Omar en la casa.'),
    reason_translate('Maria has three dogs.', PH2),
    must('a number, the noun in the plural', PH2, 'Maria tiene tres perros.'),
    reason_translate('Maria and Omar eat the bread quickly.', PH3),
    must('two subjects joined are plural; the adverb last', PH3, 'Maria y Omar comen el pan rápidamente.'),
    reason_translate('The house is big and red.', PH4),
    must('two adjectives joined, agreeing', PH4, 'La casa es grande y roja.'),
    reason_translate('The dogs of Maria eat.', PH5),
    must('a phrase inside the subject', PH5, 'Los perros de Maria comen.'),
    reason_translate('Maria vive en la ciudad.', PH6),
    must('la before a noun is the article, not her', PH6, 'Maria lives in the city.'),
    reason_translate('Where does Maria live?', PH7),
    must('where: the lesson''s word, then the verb, then the subject', PH7, '¿Dónde vive Maria?'),
    reason_translate('¿Cuándo comerá Maria?', PH8),
    must('when will', PH8, 'When will Maria eat?'),
    reason_translate('Which dog eats the bread?', PH9),
    must('which takes its noun; qué means which as well as what', PH9, '¿Qué perro come el pan?'),
    reason_translate('¿Qué libro lee Maria?', PH10),
    must('a name alone after the verb: the object was asked', PH10, 'Which book does Maria read?').

section_14 :-
    format("~n14. A second lesson under its own name: reason_learn/3, and the words vote~n", []),
    reason_learn('Italian is a language. The noun "casa" means "house". The noun "cane" means "dog". The noun "pane" means "bread". The adjective "grande" means "big". The verb "è" means "is". The verb "mangia" means "eats". The feminine article "la" means "the". The masculine article "il" means "the". Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine. Every adjective follows the noun. "case" is the plural of "casa". "grandi" is the plural of "grande". "sono" is the plural of "è". "le" is the plural of "la". The word "non" means "not".', italian, Ts),
    length(Ts, N14),
    must('seventeen lines, twenty-eight terms, asserted as lesson(italian, Term)', N14, 28),
    reason_translate('Le case non sono grandi.', IT1),
    must('è, sono, non and le are Italian''s alone: from Italian', IT1, 'The houses are not big.'),
    reason_translate('Los perros no comen el pan.', IT2),
    must('and Spanish is still Spanish', IT2, 'The dogs do not eat the bread.'),
    ( reason_translate('The house is big.', _) -> IT3 = translated ; IT3 = refused ),
    must('English into which? both lessons fit equally: refused', IT3, refused),
    reason_translate('The house is big.', italian, IT4),
    must('so name it', IT4, 'La casa è grande.'),
    reason_translate('The houses are big.', spanish, IT5),
    must('casa is plural by a rule in one lesson and by a stated form in the other, and the lessons share nothing', IT5, 'Las casas son grandes.'),
    reason_translate('The houses are big.', italian, IT6),
    must('le case', IT6, 'Le case sono grandi.'),
    retractall(lesson(italian, _)).

section_15 :-
    format("~n15. A person as the object: the word the lesson puts before one, `whom', and a contraction~n", []),
    reason_translate('Maria sees Omar.', PA1),
    must('`the word "a" precedes the person'': a name is a person', PA1, 'Maria ve a Omar.'),
    reason_translate('Maria sees her friend.', PA2),
    must('`"amigo" is a person'': a phrase whose noun is one', PA2, 'Maria ve a su amigo.'),
    reason_translate('Maria sees the dog.', PA3),
    must('a dog is not', PA3, 'Maria ve el perro.'),
    reason_translate('Maria ve a Omar.', PA4),
    must('back: the word with a person after it and no object before it is the object', PA4, 'Maria sees Omar.'),
    reason_translate('Maria da el libro a Omar.', PA5),
    must('after an object it is the preposition it is', PA5, 'Maria gives the book to Omar.'),
    reason_translate('Whom does Maria see?', PA6),
    must('whom is who asked for as the object, and a person', PA6, '¿A quién ve Maria?'),
    reason_translate('¿A quién ve Maria?', PA7),
    must('and back', PA7, 'Whom does Maria see?'),
    reason_translate('¿Quién ve a Maria?', PA8),
    must('where the question word alone asks for the subject', PA8, 'Who sees Maria?'),
    reason_translate('Maria sees the friend.', PA9),
    must('`"al" is the contraction of "a el"'': written back as itself', PA9, 'Maria ve al amigo.'),
    reason_translate('Los perros del amigo comen.', PA10),
    must('and read as its words', PA10, 'The dogs of the friend eat.').

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
