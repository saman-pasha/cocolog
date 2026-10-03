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
%% TEACHES: one hundred and eighty-three lines of Spanish in the same
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
%% second lesson under its own name.
%%
%% AND EVERY LANGUAGE HAS TWO HALVES AND NO PAIR HAS ANY. A sentence is
%% read INTO an intermediate representation -- the reader's own shape
%% with English words in it -- and written FROM it into whichever
%% language is asked for, so Italian goes into Spanish with no English
%% sentence written and none read. Section 18 shows one term written into
%% all three. Three languages are three lessons and not six paths, and a
%% fourth is a fourth lesson: what travels exactly is the SHAPE, and what
%% travels through English is the vocabulary, because a lesson says what
%% a word means only as mean(Word, EnglishWord).
%%
%% AND SECTION 20 IS THE SHAPES NEWSPAPER PROSE IS MADE OF: a passive with
%% its agent, a reduced relative, an infinitive of purpose, an object
%% complement, a superlative, a subject after its verb, a headline with the
%% copula left out, and a gerund clause with a `that' clause inside it.
%% Twelve verbatim sentences of an Italian newspaper needed eleven such
%% structures, and every one of them turned out to be a SHAPE rather than a
%% vocabulary -- three of them wanting one line of lesson each and no new
%% grammar at all.
%%
%% What the translator knows on its own
%% is ENGLISH: `is' and `are', `does not' and `do not', `will', `has' and
%% `had', its pronouns, a plural by -s, `an' before a vowel -- the
%% library's own language, and the one the lesson is written in.

:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/translate)).
:- use_module(library(reasoning/normalise)).     % normalise_corpus_dir/1, section 16

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
The number "dos" means "two".
The number "tres" means "three".
The conjunction "y" means "and".').

main :-
    section_1, section_2, section_3, section_4, section_5, section_6, section_7, section_8, section_9, section_10,
    section_11, section_12, section_13, section_14, section_15,
    format("~n16. The vocabulary: eighty thousand lesson lines build.pl wrote from a dictionary, learned the same way~n", []),
    normalise_corpus_dir(CDir), atom_concat(CDir, '/vocabulary/spanish.txt', VFile),
    read_file_to_codes(VFile, VCodes), split_string(VCodes, "\n", " \t\r", VLines0),
    findall(VL, ( member(VS, VLines0), VS \== "", \+ sub_string(VS, 0, 1, _, "#"), atom_string(VL, VS) ), VLines),
    length(VLines, NV), show('lines in corpus/vocabulary/spanish.txt', NV),
    findall(VL, ( member(VL, VLines), split_string(VL, "\"", "", Parts), Parts = [_, W16|_], atom_string(WA16, W16), memberchk(WA16, [profesor, 'periódico', hermano, coche, nuevo, hace, hizo, makes, made]) ), Some),
    length(Some, NS16), show('the lines that mention a few of its words', NS16),
    forall(( member(VL, Some), sub_atom(VL, 0, _, _, 'The ') ), format("      ~w~n", [VL])),
    atomic_list_concat(Some, ' ', VText), reason_learn(VText, _),
    reason_translate('Mi hermano tiene un coche nuevo.', S16a),
    must('a page''s sentence over the vocabulary', S16a, 'My brother has a new car.'),
    reason_translate('El profesor lee el periódico.', S16b),
    must('a noun that is an adjective too is the noun where the sentence puts it', S16b, 'The professor reads the newspaper.'),
    reason_translate('Tom hizo el pan.', S16c),
    must('an English past the -ed rule cannot make, stated', S16c, 'Tom made the bread.'),
    show('to teach the whole of it once', 'cocolog --embed KB -s library/reasoning/teach.pl -- spanish'),
    show('and translate a page over the store', 'cocolog --embed KB -s library/reasoning/page.pl -- page.txt'),

    format("~n17. The shapes a vocabulary brings: an infinitive, a modal, the progressive, the conditional, this and that, there is~n", []),
    findall(VL, ( member(VL, VLines), mentions(VL, [come, 'comería', quiere, duerme, puede, esto, nadie, otro, cada, hay, cuatro, este, esta, aquel]) ), Some17),
    length(Some17, NS17), show('the lines that mention fourteen more words, anywhere in the line', NS17),
    atomic_list_concat(Some17, ' ', VText17), reason_learn(VText17, _),
    reason_translate('Maria wants to eat the bread.', S17a),
    must('`"comer" is the infinitive of "come"'': to and the base form', S17a, 'Maria quiere comer el pan.'),
    reason_translate('Maria puede comer el pan.', S17b),
    must('`The modal "puede" means "can"'': a modal, and the base bare after it', S17b, 'Maria can eat the bread.'),
    reason_translate('Maria cannot eat.', S17c),
    must('cannot', S17c, 'Maria no puede comer.'),
    reason_translate('Maria is eating the bread.', S17d),
    must('`The auxiliary "está" means "is"'' and `"comiendo" is the gerund of "come"'': the progressive', S17d, 'Maria está comiendo el pan.'),
    reason_translate('Los perros estaban comiendo.', S17e),
    must('and back, in the past', S17e, 'The dogs were eating.'),
    reason_translate('Maria comería el pan.', S17f),
    must('`"comería" is the conditional of "come"'': would', S17f, 'Maria would eat the bread.'),
    reason_translate('These houses are big.', S17g),
    must('`The feminine demonstrative "esta" means "this"'': agreeing like an article, these as its plural', S17g, 'Estas casas son grandes.'),
    reason_translate('Cada perro come.', S17h),
    must('`The determiner "cada" means "each"''', S17h, 'Each dog eats.'),
    reason_translate('Nadie come el pan.', S17i),
    must('`The pronoun "nadie" means "nobody"'': a pronoun that stands alone', S17i, 'Nobody eats the bread.'),
    reason_translate('Maria sees this.', S17j),
    must('and after the verb, since it does not precede it', S17j, 'Maria ve esto.'),
    reason_translate('There is a dog in the house.', S17k),
    must('`The verb "hay" means "there is"'': no subject, the phrase after it', S17k, 'Hay un perro en la casa.'),
    reason_translate('No hay perros.', S17l),
    must('and denied: there are no', S17l, 'There are no dogs.'),
    reason_translate('Maria tiene cuatro perros.', S17m),
    must('`The number "cuatro" means "four"''', S17m, 'Maria has four dogs.'),

    section_18,
    section_19,

    section_20,
    section_21,
    section_22,
    section_23,
    section_24,
    section_25,
    section_26,
    section_27,
    section_28,
    section_29,
    section_30,
    section_31,
    section_32,
    section_33,
    section_34,
    section_35,
    section_36,
    section_37,
    section_38,
    section_39,
    section_40,
    section_41,
    section_42,
    section_43,
    section_44,
    section_45,
    section_46,
    section_47,
    section_48,
    section_49,
    section_50,
    section_51,
    section_52,
    section_53,
    section_54,
    section_55,
    section_56,
    section_57,
    section_58,
    section_59,
    section_60,

    format("~nA lesson is a knowledge base; a translation is a proof over it.~ndone~n", []).

%% (sections 18 and 19 have predicates of their own: inline, they took
%% main/0 past the 7800 bytes a clause may have in a store's page)
section_18 :-
    format("~n18. The intermediate representation: Italian into Spanish, and no pair with a path of its own~n", []),
    reason_learn('Italian is a language. The noun "casa" means "house". The noun "cane" means "dog". The noun "pane" means "bread". The adjective "grande" means "big". The verb "è" means "is". The verb "mangia" means "eats". The feminine article "la" means "the". The masculine article "il" means "the". Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine. Every adjective follows the noun. "case" is the plural of "casa". "grandi" is the plural of "grande". "sono" is the plural of "è". "le" is the plural of "la". The word "non" means "not". The word "cosa" means "what".', italian, T18),
    length(T18, N18), show('a second lesson, eighteen lines, under its own name', N18),
    reason_languages(L18), show('and the languages this process now has', L18),
    reason_ir('Il cane non mangia il pane.', italian, IR18),
    show('one Italian sentence into the IR', IR18),
    findall(O18, ( member(W18, [italian, english, spanish]), reason_ir_text(IR18, W18, O18) ), Os18),
    must('THAT ONE TERM, written into all three', Os18,
         ['Il cane non mangia il pane.', 'The dog does not eat the bread.', 'El perro no come el pan.']),
    reason_translate('Cosa mangia il cane?', italian, spanish, S18a),
    must('a question, Italian into Spanish, with no English written', S18a, '¿Qué come el perro?'),
    reason_translate('¿Qué come el perro?', spanish, italian, S18b),
    must('and back, which is the same two halves the other way', S18b, 'Cosa mangia il cane?'),
    reason_translate('Le case non sono grandi.', italian, spanish, S18c),
    must('a stated plural one side and a ruled one the other', S18c, 'Las casas no son grandes.'),
    show('so a language is added by adding its lesson', 'reason_learn(Text, Language, Terms)').

section_19 :-
    format("~n19. The elision and the impersonal pronoun: two shapes the lesson already had~n", []),
    reason_learn('The noun "amico" means "friend". "l\'" is the elision of "il". "l\'" is the elision of "lo". "l\'" is the elision of "la". The impersonal pronoun "si" means "one".', italian, T19),
    length(T19, N19), show('five more lines of the Italian lesson', N19),
    reason_learn('The impersonal pronoun "se" means "one".', _),
    reason_tokens('L\'amico mangia il pane.', Tok19),
    show('the apostrophe ends the word and stays with it', Tok19),
    reason_translate('L\'amico mangia il pane.', italian, english, S19a),
    must('an elided article reads as what it elides', S19a, 'The friend eats the bread.'),
    reason_translate('The friend eats the bread.', english, italian, S19b),
    must('and is written back before a vowel, joined to the word after it', S19b, 'L\'amico mangia il pane.'),
    reason_translate('The dog eats the bread.', english, italian, S19c),
    must('a consonant takes the plain article', S19c, 'Il cane mangia il pane.'),
    reason_translate('Si mangia il pane.', italian, english, S19d),
    must('`The impersonal pronoun "si" means "one"'': a subject that names nobody', S19d, 'One eats the bread.'),
    reason_translate('Si mangia il pane.', italian, spanish, S19e),
    must('and into a language with a word of its own for it', S19e, 'Se come el pan.'),
    reason_ir('Si mangia il pane.', italian, IR19),
    show('what the IR carries is the subject, not a word of any language', IR19).

%% Each section its own clause: one clause holding the whole lesson ran over the
%% page a stored clause must fit in, which cocolint flags.

%% THE SHAPES NEWSPAPER PROSE IS MADE OF, which is what 1.6.1 to 1.6.8 were
%% for: twelve verbatim sentences of an Italian newspaper needed eleven
%% structures this had none of, and each one of them is a shape rather than a
%% vocabulary. The lesson below is thirty lines and says nothing new about
%% Italian -- the classes, the participles, the infinitive and the gerund are
%% all shapes the lesson already had.
lesson_20('Italian is a language.
The noun "casa" means "house". The noun "generale" means "general". The noun "paese" means "country".
The noun "soldati" means "soldiers". The noun "decisione" means "decision". "decisione" is feminine.
The masculine article "il" means "the". The feminine article "la" means "the".
The masculine article "i" means "the". The feminine article "le" means "the".
"i" is the plural of "il". "le" is the plural of "la". "case" is the plural of "casa".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
The verb "è" means "is". "sono" is the plural of "è".
"stato" is the participle of "è". "stata" is the participle of "è". "stata" is feminine.
The verb "domina" means "dominates". "dominava" is the past of "domina". "domina" is intransitive.
The verb "definisce" means "defines". The verb "impone" means "imposes".
The verb "evacua" means "evacuates". The verb "esclude" means "excludes".
"imposto" is the participle of "impone". "imposta" is the participle of "impone". "imposta" is feminine.
"evacuato" is the participle of "evacua". "evacuata" is the participle of "evacua". "evacuata" is feminine.
"definire" is the infinitive of "definisce". "escludendo" is the gerund of "esclude".
"evacua" is the imperative of "evacua". "evacuare" is the negative imperative of "evacua".
The adjective "illegale" means "illegal". The adjective "ricco" means "rich".
The adverb "qui" means "here". The adverb "più" means "more".
The preposition "da" means "by". The preposition "di" means "of". The preposition "per" means "for".
The word "per" begins the purpose. The word "più" begins the comparative.
The conjunction "che" means "that". The conjunction "e" means "and".
The adverb "sempre" means "always". The adverb "anche" means "also".
The noun "sabato" means "saturday". "sabato" is a time.
The pronoun "tutto" means "everything". The pronoun "tutto" does not precede the verb.
The preposition "a" means "to".
The verb "comincia" means "begins". "cominciare" is the infinitive of "comincia".
The verb "conclude" means "concludes".
"concluso" is the participle of "conclude". "conclusa" is the participle of "conclude". "conclusa" is feminine.
"definito" is the participle of "definisce". "definita" is the participle of "definisce". "definita" is feminine.
"evacuare" is the infinitive of "evacua".
Every adjective follows the noun.').

section_20 :-
    format("~n20. The shapes a newspaper is made of: a passive, a reduced relative, a purpose, a complement, a superlative, an inversion, a headline, a gerund clause, an imperative~n", []),
    lesson_20(L20), reason_learn(L20, italian, T20),
    length(T20, N20), show('a third lesson, thirty lines, under its own name', N20),
    reason_translate('La casa è evacuata da i soldati.', italian, english, S20a),
    must('the PASSIVE, and `da'' is the agent rather than the preposition it is', S20a,
         'The house is evacuated by the soldiers.'),
    reason_translate('Il paese imposto da i soldati domina.', italian, english, S20b),
    must('a REDUCED RELATIVE: a participle after the noun, with its agent inside the phrase', S20b,
         'The country imposed by the soldiers dominates.'),
    reason_translate('Il generale impone la decisione per definire il paese.', italian, english, S20c),
    must('`The word "per" begins the purpose'': an infinitive of PURPOSE', S20c,
         'The general imposes the decision to define the country.'),
    reason_translate('Il generale definisce illegale la decisione.', italian, english, S20d),
    must('an OBJECT COMPLEMENT, which Italian writes before its object and English after', S20d,
         'The general defines the decision illegal.'),
    reason_translate('Il generale definisce il paese più ricco.', italian, english, S20e),
    must('`The word "più" begins the comparative'': the article makes it the SUPERLATIVE', S20e,
         'The general defines the richest country.'),
    reason_translate('Qui dominava il generale.', italian, english, S20f),
    must('an INVERSION: a fronted adverb and `"domina" is intransitive'' put the subject after the verb', S20f,
         'Here the general dominated.'),
    reason_translate('Qui dominava il generale.', italian, italian, S20g),
    must('and an adverb in front is written back there, the subject after the verb (1.8.10)', S20g,
         'Qui dominava il generale.'),
    reason_translate('Evacuata la casa.', italian, english, S20h),
    must('a HEADLINE is a passive with the copula left out, not a fragment', S20h,
         'The house has been evacuated.'),
    reason_translate('Evacuata la casa.', italian, italian, S20i),
    must('and the copula is written back, so a headline read is a sentence written', S20i,
         'La casa è stata evacuata.'),
    reason_translate('Il generale definisce la casa, escludendo che il paese domina.', italian, english, S20j),
    must('a COMMA JOIN, a GERUND clause with no subject, and a `that'' clause inside it', S20j,
         'The general defines the house, excluding that the country dominates.'),
    reason_translate('Evacua la casa.', italian, english, S20l),
    must('an IMPERATIVE: no subject, and the form the lesson calls one', S20l,
         'Evacuate the house.'),
    reason_translate('Non evacuare la casa.', italian, english, S20m),
    must('and its DENIAL, which Italian builds on the infinitive and the lesson says so', S20m,
         'Do not evacuate the house.'),
    reason_translate('Evacuata la Tate Gallery.', italian, english, S20k),
    must('AN ARTICLE BEFORE A NAME, which needs no line of lesson at all', S20k,
         'The Tate Gallery has been evacuated.'),
    reason_ir('Evacuata la Tate Gallery.', italian, IR20),
    show('the name where the noun goes, with the gender the article lends it', IR20),
    show('and every one of them is a shape, so the words are the dictionary''s', 'corpus/vocabulary/italian.txt').

%% 1.6.14: what stands BESIDE the sentence. Newspaper prose puts an adverb
%% inside the verb group, a connector at the head and an adjunct before the
%% subject, and none of the three was read until this version. Every one is
%% tried only after the plain reading failed, so nothing in section 20
%% changed for them.
section_21 :-
    format("~n21. What stands beside the sentence: an adverb inside the group, a connector at the head, an adjunct before the subject~n", []),
    reason_translate('La casa è anche evacuata da i soldati.', italian, english, S21a),
    must('an adverb INSIDE the verb group, between the copula and the participle', S21a,
         'The house is evacuated by the soldiers also.'),
    reason_translate('Sempre il generale domina.', italian, english, S21b),
    must('and one at the head, before the subject -- written back after the verb, as a fronting always is', S21b,
         'The general dominates always.'),
    reason_translate('E il generale domina.', italian, english, S21c),
    must('a CONNECTOR at the head, joining this sentence to the one before it', S21c,
         'And the general dominates.'),
    reason_translate('Sabato il generale domina.', italian, english, S21d),
    must('a bare TIME phrase: `"sabato" is a time'', in the shape `"amigo" is a person'' already had', S21d,
         'The general dominates saturday.'),
    reason_translate('Il generale domina per sempre.', italian, english, S21e),
    must('a preposition whose object is an ADVERB', S21e,
         'The general dominates for always.'),
    reason_translate('Il generale comincia a definire il paese.', italian, english, S21f),
    must('a preposition meaning `to'' before an INFINITIVE is the infinitive', S21f,
         'The general begins to define the country.'),
    reason_translate('Il generale impone la decisione per definire il paese e evacuare la casa.', italian, english, S21g),
    must('a CONJUNCTION between two complements, not inside a phrase', S21g,
         'The general imposes the decision to define the country and to evacuate the house.'),
    reason_translate('La casa è definita conclusa.', italian, english, S21h),
    must('a PARTICIPLE predicated of the subject, after a passive that spent the copula', S21h,
         'The house is defined concluded.'),
    reason_translate('Il tutto domina.', italian, english, S21i),
    must('a determiner and a PRONOUN: the pronoun is the phrase''s head', S21i,
         'The everything dominates.'),
    reason_unlearn(italian).

%% 1.6.15: A REAL SPANISH ARTICLE INTO ITALIAN. El Periódico, 2 February
%% 1999 -- the AnCora document CESS-CAST-P-19990202-16, eleven sentences --
%% needed what the Italian sample did not: a relative clause with its own
%% pronoun, a list, a word of several words, when and how a thing was done,
%% a phrase whose noun was left out, what has no verb, and the forms Italian
%% chooses by the word after them. The two lessons below are the article's
%% shapes on a few words each; the article itself goes over the vocabulary
%% store, through page.pl.
section_22 :-
    format("~n22. A Spanish article into Italian: relatives, lists, words of several words, a noun left out, no verb, and the forms Italian chooses~n", []),
    lesson_22(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the article''s shapes, under its own name', NS),
    lesson_22(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('El perro come el caldo que el chico come.', spanish, italian, S22a),
    must('a RELATIVE CLAUSE with its own pronoun: `"que" is a relative''', S22a,
         'Il cane mangia il brodo che il ragazzo mangia.'),
    reason_translate('Es el grupo al que pertenece.', spanish, italian, S22b),
    must('for a preposition''s object: `The word "cui" follows the preposition''', S22b,
         'È il gruppo a cui appartiene.'),
    ( reason_translate('Es el grupo al que pertenece.', spanish, english, _) -> R22 = translated ; R22 = refused ),
    must('and English refuses a subject nobody named: he, she and it are three claims', R22, refused),
    reason_translate('El perro come pan, caldo y sopa.', spanish, italian, S22c),
    must('a LIST, with the commas the list''s own', S22c, 'Il cane mangia pane, brodo e minestra.'),
    reason_translate('Hay lavados de cerebro.', spanish, italian, S22d),
    must('a WORD OF SEVERAL WORDS, which a lesson states as one', S22d, 'Ci sono lavaggi del cervello.'),
    reason_translate('El ministro ha provocado el escándalo al acusar a la institución.', spanish, italian, S22e),
    must('`The word "al" begins the moment'': Italian''s gerund; lo before sc, l'' before a vowel', S22e,
         'Il ministro ha causato lo scandalo accusando l''istituzione.'),
    reason_translate('El perro come el pan de los gatos y el de los chicos.', spanish, italian, S22f),
    must('a NOUN LEFT OUT: `The word "el" replaces the noun'', and Italian''s pronoun where no article does', S22f,
         'Il cane mangia il pane dei gatti e quello dei ragazzi.'),
    reason_translate('¡El pan del perro!', spanish, italian, S22g),
    must('an EXCLAMATION with no verb', S22g, 'Il pane del cane!'),
    reason_translate('El perro come el pan; el gato, la sopa.', spanish, italian, S22h),
    must('after a semicolon, a clause that LEAVES OUT the verb of the one before it', S22h,
         'Il cane mangia il pane; il gatto, la minestra.'),
    reason_translate('El ministro se ha equivocado.', spanish, italian, S22i),
    must('the perfect of a reflexive: `"è" is the auxiliary of the reflexive''', S22i, 'Il ministro si è sbagliato.'),
    reason_translate('Se les llamará chicos.', spanish, italian, S22j),
    must('`The word "si" follows the pronoun''', S22j, 'Li si chiamerà ragazzi.'),
    reason_translate('La sacrosanta institución es grande.', spanish, italian, S22k),
    must('an adjective the source set BEFORE its noun stays there', S22k, 'La sacrosanta istituzione è grande.'),
    show('the article itself, over a store teach.pl taught both lessons',
         'cocolog --embed KB -s library/reasoning/page.pl -- article.txt italian spanish'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_22(spanish, 'Spanish is a language.
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
The verb "acusa" means "accuses". "acusar" is the infinitive of "acusa".
The verb "provoca" means "causes". "provocado" is the participle of "provoca".
The verb "equivoca" means "errs". "equivocado" is the participle of "equivoca". "equivoca" is reflexive.
The verb "golpea" means "hits".
The auxiliary "ha" means "has".
The verb "hay" means "there is".
The adverb "después" means "afterwards". The adverb "tan" means "so".
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
lesson_22(italian, 'Italian is a language.
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
The adverb "dopo" means "afterwards". The adverb "così" means "so".
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

%% 1.6.17: A SECOND ITALIAN ARTICLE INTO SPANISH. Monte Livata -- the
%% Italian UD ISDT document test-232..260, twenty-nine sentences of a rescue
%% told in quotations -- needed the copula of a STATE, a count with an adverb
%% before it, `of which' with no verb, `all' before a phrase, a DATIVE, the
%% `to' before an infinitive and a sentence of thanks with no verb. Each is a
%% line of lesson or a shape; the two lessons below show them on a few words.
section_23 :-
    format("~n23. An Italian article into Spanish: a state, a count, of which, all, a dative, to, thanks~n", []),
    lesson_23(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the article''s shapes, under its own name', NS),
    lesson_23(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Stiamo stanchi.', italian, spanish, S23a),
    must('`The auxiliary "está" marks the state.'': stare with no gerund is estar', S23a, 'Estamos cansados.'),
    reason_translate('Estamos cansados.', spanish, italian, S23b),
    must('and a lesson that says nothing of a state writes its plain copula', S23b, 'Siamo stanchi.'),
    reason_ir('Stiamo stanchi.', italian, IR23),
    show('the IR keeps the state apart from the copula', IR23),
    reason_translate('Il cane mangia oltre 50 pani.', italian, spanish, S23c),
    must('`The adverb "oltre" means "more than".'': a count with an adverb before it', S23c,
         'El perro come más de 50 panes.'),
    reason_translate('Il cane mangia 37 pani, di cui tre.', italian, spanish, S23d),
    must('OF WHICH with no verb, the relative agreeing with the object before it', S23d,
         'El perro come 37 panes, de los que tres.'),
    reason_translate('Il cane dorme tutta la notte.', italian, spanish, S23e),
    must('ALL before a determiner, agreeing with the noun', S23e, 'El perro duerme toda la noche.'),
    reason_translate('Gli abbiamo dato il pane.', italian, spanish, S23f),
    must('`The dative pronoun "gli" means "him".'': a DATIVE stays one', S23f, 'Le hemos dado el pan.'),
    reason_translate('Il cane va a mangiare il pane.', italian, spanish, S23g),
    must('the TO before an infinitive, kept', S23g, 'El perro va a comer el pan.'),
    reason_translate('Grazie ai cani!', italian, spanish, S23h),
    must('THANKS, with no verb', S23h, 'Gracias a los perros!'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_23(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "perro" means "dog". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "noche" means "night". "noche" is feminine.
The masculine adjective "cansado" means "tired". The feminine adjective "cansada" means "tired".
The masculine pronoun "todo" means "all". The feminine pronoun "toda" means "all".
The verb "come" means "eats". "comer" is the infinitive of "come".
The verb "duerme" means "sleeps". The verb "va" means "goes".
The verb "da" means "gives". "dado" is the participle of "da".
The verb "es" means "is". "son" is the plural of "es". "somos" is the first person of "son".
The auxiliary "está" means "is". "están" is the plural of "está". "estamos" is the first person of "están".
The auxiliary "está" marks the state. The verb "está" means "stays".
The auxiliary "ha" means "has". "han" is the plural of "ha". "hemos" is the first person of "han".
The pronoun "lo" means "him". The dative pronoun "le" means "him". Every pronoun precedes the verb.
"que" is a relative. The conjunction "que" means "that".
The preposition "a" means "to". The preposition "de" means "of".
The preposition "gracias a" means "thanks to".
The adverb "más de" means "more than". The number "tres" means "three".
The conjunction "y" means "and". The word "no" means "not".').
lesson_23(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
"ai" is the contraction of "a i".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "cane" means "dog". "cani" is the plural of "cane".
The noun "pane" means "bread". "pani" is the plural of "pane".
The noun "notte" means "night". "notte" is feminine.
The masculine adjective "stanco" means "tired". "stanchi" is the plural of "stanco".
The masculine pronoun "tutto" means "all". The feminine pronoun "tutta" means "all".
The pronoun "tutta" does not precede the verb.
The verb "mangia" means "eats". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". The verb "va" means "goes".
The verb "dà" means "gives". "dato" is the participle of "dà".
The verb "è" means "is". "sono" is the plural of "è". "siamo" is the first person of "sono".
The auxiliary "sta" means "is". "stanno" is the plural of "sta". "stiamo" is the first person of "stanno".
The verb "sta" means "stays".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "abbiamo" is the first person of "hanno".
The dative pronoun "gli" means "him". Every pronoun precedes the verb.
"che" is a relative. "cui" is a relative. The word "cui" follows the preposition.
The preposition "a" means "to". The preposition "di" means "of".
The preposition "grazie a" means "thanks to".
The adverb "oltre" means "more than". The number "tre" means "three".
The conjunction "e" means "and". The word "non" means "not".').

%% 1.6.21: A THIRD ITALIAN ARTICLE INTO SPANISH. The Fiat-Chrysler agreement
%% with Veba -- the Italian UD ISDT document test-261..281, twenty sentences
%% of figures, dates and quotations -- needed a percentage as one word, a
%% date, a heading that ends in its colon, reporting clauses between dashes
%% and between commas, a list that is the subject, `di' before an infinitive
%% and Spanish's apocope. A date, an apocope and the word that begins an
%% infinitive are lines of lesson (`The word "de" joins the date.',
%% `"primer" is the apocope of "primero".', `The word "di" begins the
%% infinitive.'); the rest are shapes, shown here on a few words.
section_24 :-
    format("~n24. An Italian business article into Spanish: percentages, a date, headings, reporting clauses~n", []),
    lesson_24(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the article''s shapes, under its own name', NS),
    lesson_24(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Il cane mangia il restante 41,46% del pane.', italian, spanish, S24a),
    must('a PERCENTAGE is one word with its sign, and a noun an adjective may describe', S24a,
         'El perro come el restante 41,46% del pan.'),
    reason_translate('Il cane mangia entro il 20 gennaio 2014.', italian, spanish, S24b),
    must('a DATE, joined by the word the lesson names', S24b, 'El perro come antes del 20 de enero de 2014.'),
    reason_translate('Il cane mangia entro il 20 gennaio 2014.', italian, english, S24c),
    must('and English puts the month first', S24c, 'The dog eats before January 20, 2014.'),
    reason_translate('Soddisfazione del cane:', italian, spanish, S24d),
    must('a HEADING: no verb, and no full stop after its colon', S24d, 'Satisfacción del perro:'),
    reason_translate('Il cane – dice Maria – mangia il pane.', italian, spanish, S24e),
    must('a reporting clause between two DASHES, written after the sentence', S24e, 'El perro come el pan – dice Maria –.'),
    reason_translate('Nella casa, dice Maria, il cane dorme.', italian, spanish, S24f),
    must('and one between two COMMAS, the front kept in front', S24f, 'En la casa, el perro duerme, dice Maria.'),
    reason_translate('Il cane, il gatto e il segretario dormono.', italian, spanish, S24g),
    must('a LIST at the head of the sentence is its subject', S24g, 'El perro, el gato y el secretario duermen.'),
    reason_translate('Il cane ci permette di mangiare il pane.', italian, spanish, S24h),
    must('DI and an infinitive after the verb, because `The word "di" begins the infinitive.'': Spanish writes it bare',
         S24h, 'El perro nos permite comer el pan.'),
    reason_translate('Il primo cane dorme nella grande casa.', italian, spanish, S24i),
    must('`"primer" is the apocope of "primero".'': before a singular noun', S24i, 'El primer perro duerme en la gran casa.'),
    reason_translate('La prima casa dorme.', italian, spanish, S24j),
    must('and only the form the lesson states one for', S24j, 'La primera casa duerme.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_24(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread".
The noun "casa" means "house". The noun "secretario" means "secretary".
The noun "satisfacción" means "satisfaction". "satisfacción" is feminine.
The masculine adjective "primero" means "first". The feminine adjective "primera" means "first".
The adjective "grande" means "big". The adjective "restante" means "remaining".
"primer" is the apocope of "primero". "gran" is the apocope of "grande".
The verb "come" means "eats". "comer" is the infinitive of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "dice" means "says". The verb "permite" means "allows".
The pronoun "nos" means "us". Every pronoun precedes the verb.
The preposition "de" means "of". The preposition "en" means "in".
The preposition "antes de" means "before". The conjunction "y" means "and".
The noun "enero" means "january". "enero" is a month. The word "de" joins the date.
The word "no" means "not".').
lesson_24(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
"del" is the contraction of "di il". "nel" is the contraction of "in il". "nella" is the contraction of "in la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "cane" means "dog". The noun "gatto" means "cat". The noun "pane" means "bread".
The noun "casa" means "house". The noun "segretario" means "secretary".
The noun "soddisfazione" means "satisfaction". "soddisfazione" is feminine.
The masculine adjective "primo" means "first". The feminine adjective "prima" means "first".
The adjective "grande" means "big". The adjective "restante" means "remaining".
The verb "mangia" means "eats". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "dice" means "says". The verb "permette" means "allows".
The pronoun "ci" means "us". Every pronoun precedes the verb.
The preposition "di" means "of". The preposition "in" means "in".
The preposition "entro" means "before". The conjunction "e" means "and".
The noun "gennaio" means "january". "gennaio" is a month.
The word "non" means "not". The word "di" begins the infinitive.').

%% 1.7.0: A SPANISH ARTICLE INTO ITALIAN, the other way from the three before
%% it. El Periódico of 2 February 2001 on old violins shown in Valencia --
%% AnCora's CESS-CAST-P-20010202-169, sixteen sentences -- quoted over two
%% sentences in the plain mark, used one verb in two senses, and said what
%% was proof of what. A verb's sense by its object is a line of lesson (`The
%% intransitive verb "destaca" means "stands out".'), and so are a comparative
%% that is a word of its own, the article Italian puts before a year and the
%% word Spanish puts before a noun's own clause; the rest are shapes, shown
%% here on a few words.
section_25 :-
    format("~n25. A Spanish article into Italian: plain quotation marks, a verb's sense by its object, a noun's own clause~n", []),
    lesson_25(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the article''s shapes, under its own name', NS),
    lesson_25(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('El constructor come el pan ", dice la familia.', spanish, italian, S25a),
    must('a PLAIN quotation mark with no word after it closes, and its reporting clause follows',
         S25a, 'Il costruttore mangia il pane", dice la famiglia.'),
    reason_translate('En la colección, destaca un violín.', spanish, italian, S25b),
    must('with no object `destaca'' is to STAND OUT, and the phrase after it is its subject',
         S25b, 'Nella collezione, un violino spicca.'),
    reason_translate('El constructor destaca las diferencias.', spanish, italian, S25c),
    must('and with one it is to highlight', S25c, 'Il costruttore evidenzia le differenze.'),
    reason_translate('Un violín llamado Ex VieuxTemps, de 1736, duerme.', spanish, italian, S25d),
    must('a NAME after a participle, spelled as the source spelled it, and a YEAR aside with Italian''s article',
         S25d, 'Un violino chiamato Ex VieuxTemps, del 1736, dorme.'),
    reason_translate('El constructor está considerado.', spanish, italian, S25e),
    must('the copula of a STATE and a participle is a passive', S25e, 'Il costruttore è considerato.'),
    reason_translate('Como prueba de que los violines duermen, los constructores comen el pan.', spanish, italian, S25f),
    must('a noun''s OWN CLAUSE after `de que'', ending at the comma',
         S25f, 'Come prova che i violini dormono, i costruttori mangiano il pane.'),
    reason_translate('El mejor de los constructores come algunas de las diferencias.', spanish, italian, S25g),
    must('a COMPARATIVE that is a word of its own, and a PARTITIVE that agrees with its noun',
         S25g, 'Il migliore dei costruttori mangia alcune delle differenze.'),
    reason_translate('Los constructores comen el pan, el próximo día 14.', spanish, italian, S25h),
    must('a number after its noun is its LABEL', S25h, 'I costruttori mangiano il pane, il prossimo giorno 14.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_25(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "violín" means "violin". "violines" is the plural of "violín".
The noun "constructor" means "builder". "constructores" is the plural of "constructor".
The noun "pan" means "bread". The noun "familia" means "family".
The noun "diferencia" means "difference". The noun "prueba" means "proof".
The noun "colección" means "collection". "colección" is feminine.
The noun "día" means "day". "día" is not feminine. "día" is a time.
The adjective "próximo" means "next". The adjective "ex" means "former".
The adjective "bueno" means "good". The adjective "mejor" means "good". "mejor" is the comparative of "bueno".
The intransitive verb "destaca" means "stands out". The verb "destaca" means "highlights".
The verb "come" means "eats". "comen" is the plural of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "dice" means "says".
The verb "llama" means "calls". "llamado" is the participle of "llama".
The verb "considera" means "considers". "considerado" is the participle of "considera".
The verb "es" means "is". The auxiliary "está" means "is".
The feminine pronoun "alguna" means "some". "algunas" is the plural of "alguna".
The pronoun "alguna" does not precede the verb. Every pronoun precedes the verb.
The conjunction "que" means "that". The word "de" begins the clause.
The preposition "de" means "of". The preposition "en" means "in".
The preposition "como" means "as". The conjunction "y" means "and".
The word "no" means "not".').
lesson_25(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "di il". "dei" is the contraction of "di i". "delle" is the contraction of "di le".
"nella" is the contraction of "in la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The article "il" takes the year.
The noun "violino" means "violin". "violini" is the plural of "violino".
The noun "costruttore" means "builder". "costruttori" is the plural of "costruttore".
The noun "pane" means "bread". The noun "famiglia" means "family".
The noun "differenza" means "difference". "differenze" is the plural of "differenza".
The noun "prova" means "proof". The noun "collezione" means "collection". "collezione" is feminine.
The noun "giorno" means "day". "giorno" is a time.
The adjective "prossimo" means "next". The adjective "ex" means "former".
The adjective "buono" means "good". The adjective "migliore" means "good". "migliore" is the comparative of "buono".
The intransitive verb "spicca" means "stands out". The verb "evidenzia" means "highlights".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "dice" means "says".
The verb "chiama" means "calls". "chiamato" is the participle of "chiama".
The verb "considera" means "considers". "considerato" is the participle of "considera".
The verb "è" means "is".
The masculine pronoun "alcuno" means "some". "alcuni" is the plural of "alcuno".
The feminine pronoun "alcuna" means "some". "alcune" is the plural of "alcuna".
The pronoun "alcuno" does not precede the verb. The pronoun "alcuna" does not precede the verb.
Every pronoun precedes the verb.
The conjunction "che" means "that".
The preposition "di" means "of". The preposition "in" means "in".
The preposition "come" means "as". The conjunction "e" means "and".
The word "non" means "not".').

%% 1.7.2: AN ITALIAN REPORT INTO SPANISH, on the national bioethics
%% committee -- the Italian UD VIT test document of fifteen sentences. It
%% opens with a headline colon and a dateline, says what is excluded and what
%% must be done with `venire' and `andare' before a participle, and puts a
%% relative clause after a comma. `venire' and `andare' are lines of lesson
%% (`The verb "viene" marks the passive.', `The verb "va" marks the duty.'),
%% the shape `The auxiliary "está" marks the state.' already had; the rest
%% are shapes, shown here on a few words.
section_26 :-
    format("~n26. An Italian report into Spanish: a dateline, a relative after a comma, the passive of venire and andare~n", []),
    lesson_26(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_26(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Il comitato: no all''eutanasia.', italian, spanish, S26a),
    must('a HEADLINE COLON: who speaks and what they say, and no verb on either side', S26a, 'El comité: no a la eutanasia.'),
    reason_translate('Roma - lo stato ha il diritto di favorire la famiglia.', italian, spanish, S26b),
    must('a DATELINE: the place and a dash, written back where they stood',
         S26b, 'Roma – el estado tiene el derecho de favorecer la familia.'),
    reason_translate('Un capitolo riassume la sperimentazione, che protegge la famiglia.', italian, english, S26c),
    must('a RELATIVE CLAUSE AFTER A COMMA is the phrase''s, which English says with `which''',
         S26c, 'A chapter summarises the experimentation, which protects the family.'),
    reason_translate('Viene esclusa ogni forma di eutanasia.', italian, spanish, S26d),
    must('`venire'' and a participle is the PASSIVE, and the phrase after it its subject',
         S26d, 'Es excluida cada forma de eutanasia.'),
    reason_translate('Viene esclusa ogni forma di eutanasia.', italian, english, S26e),
    must('which English writes first', S26e, 'Each form of euthanasia is excluded.'),
    reason_translate('Vanno attivate la terapia e la cura.', italian, spanish, S26f),
    must('`andare'' and a participle is what MUST be done, and two feminine subjects agree as feminine',
         S26f, 'Tienen que ser activadas la terapia y la cura.'),
    reason_translate('La forma viene esclusa, neanche se vi sia l''assenso.', italian, spanish, S26g),
    must('`if'' joins two clauses, `neanche'' is not even and `vi sia'' there is',
         S26g, 'La forma es excluida, ni siquiera si hay el asentimiento.'),
    reason_translate('La terapia va attivata, in modo che il malato dorme.', italian, spanish, S26h),
    must('a COMMA before a subordinating word is the source''s, and so that is three words',
         S26h, 'La terapia tiene que ser activada, de modo que el paciente duerme.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_26(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun.
The noun "comité" means "committee". The noun "estado" means "state". The noun "derecho" means "right".
The noun "terapia" means "therapy". The noun "cura" means "cure". The noun "forma" means "form".
The noun "eutanasia" means "euthanasia". The noun "capítulo" means "chapter".
The noun "experimentación" means "experimentation". "experimentación" is feminine.
The noun "familia" means "family". The noun "paciente" means "patient". The noun "asentimiento" means "assent".
The determiner "cada" means "each".
The verb "resume" means "summarises". The verb "protege" means "protects".
The verb "favorece" means "favours". "favorecer" is the infinitive of "favorece".
The verb "excluye" means "excludes". "excluido" is the participle of "excluye". "excluida" is the participle of "excluye".
"excluida" is feminine.
The verb "activa" means "activates". "activado" is the participle of "activa". "activada" is the participle of "activa".
"activadas" is the participle of "activa". "activada" is feminine. "activadas" is feminine.
"activadas" is the plural of "activada".
The verb "duerme" means "sleeps". The verb "tiene" means "has".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es".
The modal "tiene que" means "must". "tienen que" is the plural of "tiene que".
The verb "hay" means "there is".
The conjunction "y" means "and". The conjunction "si" means "if". The conjunction "de modo que" means "so that".
The adverb "ni siquiera" means "not even". The adverb "no" means "no".
"que" is a relative. The conjunction "que" means "that".
The preposition "a" means "to". The preposition "de" means "of".
The word "no" means "not".').
lesson_26(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a". The masculine article "lo" means "the".
"l''" is the elision of "il". "all''" is the elision of "alla". "alla" is the contraction of "a la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun.
The noun "comitato" means "committee". The noun "stato" means "state". The noun "diritto" means "right".
The noun "terapia" means "therapy". The noun "cura" means "cure". The noun "forma" means "form".
The noun "eutanasia" means "euthanasia". The noun "capitolo" means "chapter".
The noun "sperimentazione" means "experimentation". "sperimentazione" is feminine.
The noun "famiglia" means "family". The noun "malato" means "patient". The noun "assenso" means "assent".
The determiner "ogni" means "each".
The verb "riassume" means "summarises". The verb "protegge" means "protects".
The verb "favorisce" means "favours". "favorire" is the infinitive of "favorisce".
The verb "esclude" means "excludes". "esclusa" is the participle of "esclude". "esclusa" is feminine.
The verb "attiva" means "activates". "attivata" is the participle of "attiva". "attivate" is the participle of "attiva".
"attivata" is feminine. "attivate" is feminine. "attivate" is the plural of "attivata".
The verb "dorme" means "sleeps". The verb "ha" means "has".
The verb "è" means "is". "essere" is the infinitive of "è".
The verb "viene" means "comes". The verb "viene" marks the passive.
The verb "va" means "goes". "vanno" is the plural of "va". The verb "va" marks the duty.
The modal "deve" means "must".
The verb "vi è" means "there is". "vi sia" is the subjunctive of "vi è".
The conjunction "e" means "and". The conjunction "se" means "if". The conjunction "in modo che" means "so that".
The adverb "neanche" means "not even". The adverb "no" means "no".
"che" is a relative. The conjunction "che" means "that".
The preposition "a" means "to". The preposition "di" means "of".
The word "non" means "not".').

%% 1.8.0: A SPANISH FOOTBALL REPORT INTO ITALIAN, on Barça before a cup tie
%% at Ceuta -- the AnCora document CESS-CAST-P-20010103-120, twenty
%% sentences. What it needed is what a sports page does with its people: a
%% list of names that is the subject of the clause after a comma, a comma
%% that parts two names, `ni ... ni' before the verb and after it, a denial
%% kept in front of its verb, the impersonal `hay que', a verb's own
%% preposition before its infinitive (`"confía" takes "en" before the
%% infinitive.'), a subordinate clause at the head with an insertion after
%% its word, and more than an adjective. The lesson lines are the shapes a
%% lesson already had; the rest is shown here on a few words.
section_27 :-
    format("~n27. A Spanish football report into Italian: lists, names a comma parts, ni ... ni, hay que, more than~n", []),
    lesson_27(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_27(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Han comido pan, Rivaldo y Overmars no duermen.', spanish, italian, S27a),
    must('two NAMES and a verb after a comma are a clause of their own, never the end of a list',
         S27a, 'Hanno mangiato pane, Rivaldo e Overmars non dormono.'),
    reason_translate('Salvo la decisión de Rivaldo y Overmars, Serra Ferrer come pan y ha dormido.', spanish, italian, S27b),
    must('a COMMA BETWEEN TWO NAMES parts them, and the front ends there',
         S27b, 'Eccetto la decisione di Rivaldo e Overmars, Serra Ferrer mangia pane e ha dormito.'),
    reason_translate('No duermen ni el perro ni el gato.', spanish, italian, S27c),
    must('NI ... NI: a list that begins with its own connector, after a verb that takes no object',
         S27c, 'Non dormono né il cane né il gatto.'),
    reason_translate('El perro tampoco duerme.', spanish, italian, S27d),
    must('a DENYING ADVERB before its verb is written in front', S27d, 'Neanche il cane dorme.'),
    reason_translate('"Hay que comer pan", dijo.', spanish, italian, S27e),
    must('the IMPERSONAL MODAL, in a quotation that closes at a comma', S27e, '"Bisogna mangiare pane", disse.'),
    reason_translate('El perro confía en comer pan.', spanish, italian, S27f),
    must('a VERB''S OWN PREPOSITION before its infinitive, which the lesson says', S27f, 'Il cane confida di mangiare pane.'),
    reason_translate('Al margen de que, como todos, han comido pan, el perro duerme.', spanish, italian, S27g),
    must('a SUBORDINATE CLAUSE AT THE HEAD, with an insertion after its word',
         S27g, 'A parte il fatto che, come tutti, hanno mangiato pane, il cane dorme.'),
    reason_translate('La elección resulta más que cuestionable.', spanish, english, S27h),
    must('MORE THAN an adjective', S27h, 'The choice results more than questionable.'),
    reason_translate('El gato es más grande que el perro.', spanish, italian, S27i),
    must('and a comparison with a phrase, Italian''s `di'' before it', S27i, 'Il gatto è più grande del cane.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_27(spanish, 'Spanish is a language.
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
The verb "dice" means "says". "dijo" is the past of "dice".
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
lesson_27(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a". "dei" is the plural of "un".
"l''" is the elision of "il". "l''" is the elision of "la".
"al" is the contraction of "a il". "del" is the contraction of "di il". "nel" is the contraction of "in il".
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
The verb "dice" means "says". "disse" is the past of "dice".
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

%% AN ITALIAN REPORT INTO SPANISH, THE MONREALE ARTICLE (1.8.2): a
%% headline's command in the plural, a title before a name, a subject after
%% its modal and its adjuncts, a cleft, an absolute superlative, the
%% conditional perfect and an aside between the subject and its verb. The
%% lesson says each of them in a shape it already had: `"mangiate" is the
%% imperative of "mangiano".', `"monsignore" is a title.', `"finisce" is
%% intransitive.', `The word "a" begins the cleft.', `"pesantissimi" is the
%% superlative of "pesanti".' and `"avrebbe" is the conditional of "ha".'
section_28 :-
    format("~n28. An Italian report into Spanish: a command, a title, a subject after its verb, a cleft~n", []),
    lesson_28(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the report''s shapes, under its own name', NI),
    lesson_28(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('"Mangiate il pane".', italian, spanish, S28a),
    must('the PLURAL IMPERATIVE, stated of the plural form', S28a, '"Comed el pan".'),
    reason_translate('Non mangiate il pane.', italian, spanish, S28b),
    must('and its denial: Italian''s is the plural itself, Spanish''s a form of its own', S28b, 'No comáis el pan.'),
    reason_translate('Deve finire in tribunale il vescovo di Monreale monsignor Salvatore Cassisa.', italian, spanish, S28c),
    must('a SUBJECT AFTER ITS MODAL and its adjuncts, with a TITLE before a name apposed to it',
         S28c, 'Debe acabar ante los tribunales el obispo de Monreale monseñor Salvatore Cassisa.'),
    reason_translate('Deve finire in tribunale il vescovo di Monreale monsignor Salvatore Cassisa.', italian, english, S28d),
    must('English puts that subject first and capitalises the title',
         S28d, 'The bishop of Monreale Monsignor Salvatore Cassisa must end up in court.'),
    reason_translate('A chiederlo è la procura che vuole il pane, il gatto e il cane.', italian, spanish, S28e),
    must('a CLEFT: what is done, the copula, and who does it',
         S28e, 'Lo pide la fiscalía que quiere el pan, el gato y el perro.'),
    reason_translate('Il cane mangia i pani pesantissimi.', italian, spanish, S28f),
    must('an ABSOLUTE SUPERLATIVE is the word for very and the plain form', S28f, 'El perro come los panes muy pesados.'),
    reason_translate('Il cane, secondo il gatto, avrebbe mangiato il pane.', italian, english, S28g),
    must('the CONDITIONAL PERFECT, and an ASIDE between the subject and its verb',
         S28g, 'The dog, according to the cat, would have eaten the bread.'),
    reason_translate('Il cane, secondo il gatto, avrebbe mangiato il pane.', italian, spanish, S28h),
    must('and into Spanish', S28h, 'El perro, según el gato, habría comido el pan.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_28(italian, 'Italian is a language.
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
The verb "vuole" means "wants". "vogliono" is the plural of "vuole".
The verb "chiede" means "asks". "chiedere" is the infinitive of "chiede".
The intransitive verb "finisce" means "ends up". "finire" is the infinitive of "finisce".
The modal "deve" means "must".
The verb "è" means "is". "sono" is the plural of "è". "stato" is the participle of "è".
The auxiliary "ha" means "has". "hanno" is the plural of "ha". "avrebbe" is the conditional of "ha".
The pronoun "lo" means "it". Every pronoun precedes the verb.
"che" is a relative. The conjunction "che" means "that". The conjunction "e" means "and".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in".
The preposition "secondo" means "according to".
The adverb "in tribunale" means "in court".
The word "a" begins the cleft.
"ate" is the past of "eats". "eaten" is the participle of "eats".
The word "non" means "not".').
lesson_28(spanish, 'Spanish is a language.
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
The verb "quiere" means "wants". "quieren" is the plural of "quiere".
The verb "pide" means "asks".
The intransitive verb "acaba" means "ends up". "acabar" is the infinitive of "acaba".
The modal "debe" means "must".
The verb "es" means "is". "son" is the plural of "es". "sido" is the participle of "es".
The auxiliary "ha" means "has". "han" is the plural of "ha". "habría" is the conditional of "ha".
"ha" is the auxiliary of "es".
The pronoun "lo" means "it". Every pronoun precedes the verb.
"que" is a relative. The conjunction "que" means "that". The conjunction "y" means "and".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in".
The preposition "según" means "according to".
The adverb "ante los tribunales" means "in court".
The word "a" precedes the person.
"ate" is the past of "eats". "eaten" is the participle of "eats".
The word "no" means "not".').

section_29 :-
    format("~n29. A Spanish report into Italian: figures, a heading in capitals, a passive made with se~n", []),
    lesson_29(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_29(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('COMPACTO CONTRA CASETE.', spanish, italian, S29a),
    must('a HEADING IN CAPITALS is read as its words, with no verb before any', S29a, 'Compatto contro cassetta.'),
    reason_translate('El perro come el 4% del pan en el 2001.', spanish, italian, S29b),
    must('a NUMBER used as a noun is masculine, by the lesson''s rule', S29b, 'Il cane mangia il 4% del pane nel 2001.'),
    reason_translate('El perro continúa comiendo el pan.', spanish, italian, S29c),
    must('a verb''s own GERUND is the infinitive and the word the other language''s verb takes',
         S29c, 'Il cane continua a mangiare il pane.'),
    reason_translate('El perro come el pan hasta situarse en el 4%.', spanish, italian, S29d),
    must('an INFINITIVE WITH ITS REFLEXIVE after a preposition', S29d, 'Il cane mangia il pane fino a situarsi nel 4%.'),
    reason_translate('Los perros comen el pan de 22 empleados por empresa.', spanish, italian, S29e),
    must('a COUNT before its noun, and a bare noun after `por'' that is nobody''s agent',
         S29e, 'I cani mangiano il pane di 22 impiegati per impresa.'),
    reason_translate('El perro come el pan a corto-medio plazo durante el bienio 2000-2001.', spanish, italian, S29f),
    must('a word the lesson spells with a HYPHEN, and a RANGE of numbers as one word',
         S29f, 'Il cane mangia il pane a breve-medio termine durante il biennio 2000-2001.'),
    reason_translate('Los perros comen unos 980 panes.', spanish, english, S29g),
    must('an article the lesson calls an adverb too, before a number: a ROUGH COUNT', S29g, 'The dogs eat about 980 breads.'),
    reason_translate('Se venden los panes.', spanish, english, S29h),
    must('se and a PLURAL VERB: the phrase after it is the subject, and English writes the passive',
         S29h, 'The breads are sold.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_29(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". "unos" is the plural of "un".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every number is masculine.
The noun "perro" means "dog". The noun "pan" means "bread". "panes" is the plural of "pan".
The noun "casete" means "cassette". The noun "bienio" means "biennium". The noun "empresa" means "company".
The noun "empleado" means "employee". "empleado" is a person.
The adjective "compacto" means "compact".
The adverb "unos" means "about". The adverb "a corto-medio plazo" means "in the short to medium term".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
"comiendo" is the gerund of "come".
The verb "compacta" means "compacts". "compacto" is the first person of "compacta".
The verb "emplea" means "employs". "empleado" is the participle of "emplea".
"empleados" is the participle of "emplea". "empleados" is the plural of "empleado".
The verb "sitúa" means "situates". "situar" is the infinitive of "sitúa".
The verb "vende" means "sells". "venden" is the plural of "vende".
The verb "continúa" means "continues". "continúa" takes the gerund.
The reflexive pronoun "se" means "itself".
The preposition "de" means "of". The preposition "en" means "in". The preposition "contra" means "against".
The preposition "durante" means "during". The preposition "hasta" means "until".
The preposition "por" means "by". The preposition "por" means "for".
"sold" is the participle of "sells".').
lesson_29(italian, 'Italian is a language.
The feminine article "la" means "the". The masculine article "il" means "the". The masculine article "lo" means "the".
"le" is the plural of "la". "i" is the plural of "il". "gli" is the plural of "lo".
The article "lo" comes before a vowel.
"del" is the contraction of "di il". "nel" is the contraction of "in il".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every number is masculine.
The noun "cane" means "dog". "cani" is the plural of "cane".
The noun "pane" means "bread". "pani" is the plural of "pane".
The noun "cassetta" means "cassette". The noun "biennio" means "biennium". The noun "impresa" means "company".
The noun "impiegato" means "employee". "impiegati" is the plural of "impiegato".
The adjective "compatto" means "compact".
The adverb "circa" means "about". The adverb "a breve-medio termine" means "in the short to medium term".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
The verb "situa" means "situates". "situare" is the infinitive of "situa".
The verb "vende" means "sells". "vendono" is the plural of "vende".
The verb "continua" means "continues". "continua" takes "a" before the infinitive.
The reflexive pronoun "si" means "itself".
The preposition "di" means "of". The preposition "in" means "in". The preposition "contro" means "against".
The preposition "durante" means "during". The preposition "fino a" means "until".
The preposition "da" means "by". The preposition "per" means "for".
"sold" is the participle of "sells".').

section_30 :-
    format("~n30. An Italian report into Spanish: a list of islands, a clause between dashes, a participle after a comma~n", []),
    lesson_30(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the report''s shapes, under its own name', NI),
    lesson_30(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('I cani si chiamano Giglio, Eolie, Ustica e Ponza.', italian, spanish, S30a),
    must('a LIST OF NAMES, one of which the lesson knows as a noun', S30a, 'Los perros se llaman Giglio, Eolie, Ustica y Ponza.'),
    reason_translate('I cani sono vietati se non per sempre quantomeno per un giorno.', italian, spanish, S30b),
    must('IF NOT for ever, at least for a day: a connector and the adjunct it denies',
         S30b, 'Los perros son prohibidos si no para siempre al menos para un día.'),
    reason_translate('Grandi case dove i cani, i gatti e i topi sono vietati.', italian, spanish, S30c),
    must('a sentence that is ONE PHRASE AND A CLAUSE opened by where, a list at its head',
         S30c, 'Grandes casas donde los perros, los gatos y los ratones son prohibidos.'),
    reason_translate('Il cane vede le più grandi Eolie.', italian, spanish, S30d),
    must('a SUPERLATIVE between the article and a name', S30d, 'El perro ve las Eolie más grandes.'),
    reason_translate('Il pane è vietato dal 24 luglio al 25 agosto.', italian, spanish, S30e),
    must('a RANGE OF DAYS after a passive is when, and nobody''s agent',
         S30e, 'El pan es prohibido desde el 24 de julio al 25 de agosto.'),
    reason_translate('Il cane vede le Eolie, vietate al traffico, e l''isola di Ustica "vietata" dal 4 al 24 agosto.', italian, spanish, S30f),
    must('a PARTICIPLE AFTER A COMMA is the phrase''s, and one after a name agrees and keeps its marks',
         S30f, 'El perro ve las Eolie, prohibidas al tráfico, y la isla de Ustica "prohibida" desde el 4 al 24 de agosto.'),
    reason_translate('La casa - dove i cani sono vietati - è grande.', italian, spanish, S30g),
    must('a CLAUSE BETWEEN TWO DASHES that opens on where', S30g, 'La casa – donde los perros son prohibidos – es grande.'),
    reason_translate('Dormono nella casa soltanto quelli che mangiano il pane.', italian, english, S30h),
    %% (since 1.8.31 `soltanto' is the subject's, only those -- 1.8.4 read it
    %% as the clause's adverb and English wrote it last, `... in the house only.')
    must('an intransitive verb''s SUBJECT AFTER ITS ADJUNCTS, with its relative clause',
         S30h, 'Only those that eat the bread sleep in the house.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_30(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la". The masculine article "un" means "a".
"l''" is the elision of "la". "al" is the contraction of "a il". "dal" is the contraction of "da il".
"nella" is the contraction of "in la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every number is masculine.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "topo" means "mouse". "topi" is the plural of "topo".
The noun "pane" means "bread". The noun "casa" means "house". "case" is the plural of "casa".
The noun "isola" means "island". The noun "giglio" means "lily". The noun "traffico" means "traffic".
The noun "giorno" means "day".
The noun "luglio" means "july". "luglio" is a month. The noun "agosto" means "august". "agosto" is a month.
The adjective "grande" means "big". "grandi" is the plural of "grande".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". The verb "vede" means "sees".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dorme" is intransitive.
The verb "chiama" means "calls". "chiamano" is the plural of "chiama".
The verb "vieta" means "forbids". "vietato" is the participle of "vieta".
"vietata" is the participle of "vieta". "vietata" is feminine.
"vietati" is the participle of "vieta". "vietati" is the plural of "vietato".
"vietate" is the participle of "vieta". "vietate" is the plural of "vietata". "vietate" is feminine.
The verb "è" means "is". "sono" is the plural of "è".
The reflexive pronoun "si" means "itself".
The masculine pronoun "quello" means "that". "quelli" is the plural of "quello". The pronoun "quello" does not precede the verb.
"che" is a relative. The conjunction "e" means "and".
The conjunction "se" means "if". The word "dove" means "where".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in".
The preposition "da" means "from". The preposition "da" means "by". The preposition "per" means "for".
The adverb "più" means "more". The word "più" begins the comparative.
The adverb "sempre" means "always". The adverb "quantomeno" means "at least". The adverb "soltanto" means "only".
The word "non" means "not".').
lesson_30(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la". The masculine article "un" means "a".
"al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every number is masculine.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "ratón" means "mouse". "ratones" is the plural of "ratón".
The noun "pan" means "bread". The noun "casa" means "house". The noun "isla" means "island".
The noun "lirio" means "lily". The noun "tráfico" means "traffic". The noun "día" means "day". "día" is not feminine.
The noun "julio" means "july". "julio" is a month. The noun "agosto" means "august". "agosto" is a month.
The word "de" joins the date.
The adjective "grande" means "big". "grandes" is the plural of "grande".
The verb "come" means "eats". "comen" is the plural of "come". The verb "ve" means "sees".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "llama" means "calls". "llaman" is the plural of "llama".
The verb "prohíbe" means "forbids". "prohibido" is the participle of "prohíbe".
"prohibida" is the participle of "prohíbe". "prohibida" is feminine.
"prohibidos" is the participle of "prohíbe". "prohibidos" is the plural of "prohibido".
"prohibidas" is the participle of "prohíbe". "prohibidas" is the plural of "prohibida". "prohibidas" is feminine.
The verb "es" means "is". "son" is the plural of "es".
The reflexive pronoun "se" means "itself".
The masculine pronoun "aquél" means "that". "aquéllos" is the plural of "aquél". The pronoun "aquél" does not precede the verb.
"que" is a relative. The conjunction "y" means "and".
The conjunction "si" means "if". The conjunction "donde" means "where". The word "dónde" means "where".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in".
The preposition "desde" means "from". The preposition "por" means "by". The preposition "para" means "for".
The adverb "más" means "more". The word "más" begins the comparative.
The adverb "siempre" means "always". The adverb "al menos" means "at least". The adverb "sólo" means "only".
The word "no" means "not".').

section_31 :-
    format("~n31. A Spanish opera review into Italian: a clause between dashes, what stands beside a phrase, a name after its verb~n", []),
    lesson_31(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the review''s shapes, under its own name', NS),
    lesson_31(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('La luna - - el perro es grande - - es grande.', spanish, italian, S31a),
    must('two hyphens are ONE DASH, and a clause between two dashes stays where it stood',
         S31a, 'La luna – il cane è grande – è grande.'),
    reason_translate('Para recordar.', spanish, italian, S31b),
    must('a PURPOSE STANDING ALONE, and `para'' is no `parar'' there', S31b, 'Per ricordare.'),
    reason_translate('El perro ve el éxito, discreto pero al fin y al cabo éxito, de la casa.', spanish, italian, S31c),
    must('a word of FIVE words, in an aside of the noun before it',
         S31c, 'Il cane vede il successo, discreto ma dopotutto successo, della casa.'),
    reason_translate('El perro ve una escena de la casa, la más esperada por los aficionados.', spanish, italian, S31d),
    must('the MOST AWAITED one: an article, the degree word and a participle with its agent',
         S31d, 'Il cane vede una scena della casa, la più attesa dagli appassionati.'),
    reason_translate('Anderson ofreció una de sus mejores noches.', spanish, italian, S31e),
    must('ONE OF, the article with its noun left out', S31e, 'Anderson offrì una delle sue notti migliori.'),
    reason_translate('Anderson ofreció una de sus mejores noches.', spanish, english, S31f),
    must('... and a possessive makes a superlative in English', S31f, 'Anderson offered one of his best nights.'),
    reason_translate('Bajo la dirección de Bertrand de Billy, el perro come.', spanish, italian, S31g),
    must('a SMALL WORD BETWEEN TWO NAMES is the name''s', S31g, 'Sotto la direzione di Bertrand de Billy, il cane mangia.'),
    reason_translate('Se permite Vick una ironía.', spanish, italian, S31h),
    must('a bare NAME AFTER ITS VERB is the subject where a person object takes `a'', and it stays there',
         S31h, 'Si permette Vick un''ironia.'),
    reason_translate('Bros fue entonándose.', spanish, italian, S31i),
    must('`fue'' before a gerund is `ir'', and the GERUND CARRIES ITS REFLEXIVE', S31i, 'Bros andò intonandosi.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_31(spanish, 'Spanish is a language.
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
lesson_31(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the". The masculine article "lo" means "the".
"i" is the plural of "il". "le" is the plural of "la". "gli" is the plural of "lo".
The masculine article "un" means "a". The feminine article "una" means "a".
"l''" is the elision of "lo". "l''" is the elision of "la". "un''" is the elision of "una".
"del" is the contraction of "di il". "della" is the contraction of "di la". "delle" is the contraction of "di le".
"dagli" is the contraction of "da gli". "nella" is the contraction of "in la". "nel" is the contraction of "in il".
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

%% 1.8.6: AN ITALIAN INTERVIEW INTO SPANISH, Corrado Ferlaino on Maradona --
%% the Italian UD document VIT-9540..9566, twenty-seven sentences. What it
%% needed is what an interview puts round its claims: a time clause after
%% `that is', standing alone after a colon; `when' after the verb's object,
%% which opens no question; a section's name before a dash; the day BEFORE,
%% where `prima' is an adverb and a feminine adjective; an infinitive for a
%% subject; a reporting clause with no speaker between two dashes; a heading
%% of one phrase; and an adverb set before a clause the verb takes.
section_32 :-
    format("~n32. An Italian interview into Spanish: a time clause alone, a heading of one phrase, no speaker between dashes~n", []),
    lesson_32(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the interview''s shapes, under its own name', NI),
    lesson_32(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('Il cane mangia il pane: cioè quando gli altri dormono.', italian, spanish, S32a),
    must('THAT IS, and a time clause standing alone after a colon',
         S32a, 'El perro come el pan: es decir cuando los otros duermen.'),
    reason_translate('L''ha mangiato quando il gatto dormiva.', italian, spanish, S32b),
    must('WHEN after the verb''s object opens no question: `cuando'', not `cuándo''',
         S32b, 'Lo ha comido cuando el gato dormía.'),
    reason_translate('Calcio - il cane mangia il pane.', italian, spanish, S32c),
    must('a SECTION''S NAME before a dash, where `calcio'' is also I kick', S32c, 'Fútbol – el perro come el pan.'),
    reason_translate('Il giorno prima mangiò il pane.', italian, spanish, S32d),
    must('THE DAY BEFORE: `prima'' in the other gender is the adverb, and a time eats nothing',
         S32d, 'Comió el pan el día antes.'),
    reason_translate('Parlare con il cane è difficile.', italian, spanish, S32e),
    must('an INFINITIVE for a subject', S32e, 'Hablar con el perro es difícil.'),
    reason_translate('Il cane - continua - mangia il pane.', italian, spanish, S32f),
    must('a reporting clause with NO SPEAKER between two dashes', S32f, 'El perro come el pan – continúa –.'),
    reason_translate('Il futuro.', italian, spanish, S32g),
    must('a HEADING of one phrase', S32g, 'El futuro.'),
    reason_translate('Oggi il cane disse che il gatto dorme.', italian, spanish, S32h),
    must('an adverb goes BEFORE a clause the verb takes', S32h, 'El perro dijo hoy que el gato duerme.'),
    reason_translate('Servono due cani.', italian, english, S32i),
    must('`is needed'' inflects as the copula in English', S32i, 'Two dogs are needed.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_32(italian, 'Italian is a language.
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
The noun "presidente" means "president".
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
The conjunction "se" means "if". The preposition "a" means "to". The preposition "di" means "of". The preposition "con" means "with". The preposition "come" means "as".
The adjective "in grado" means "able".
The adverb "poi" means "then". The adverb "oggi" means "today".
The word "non" means "not". The word "non" precedes the verb.').
lesson_32(spanish, 'Spanish is a language.
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
The noun "persona" means "person". The noun "presidente" means "president".
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
The conjunction "si" means "if". The preposition "a" means "to". The preposition "de" means "of". The preposition "con" means "with". The preposition "como" means "as".
The adjective "capaz" means "able".
The adverb "entonces" means "then". The adverb "hoy" means "today".
The word "no" means "not". The word "no" precedes the verb.').

section_33 :-
    format("~n33. A Spanish report on an election into Italian: one person named twice, a share of a plural, a quotation on the verb~n", []),
    lesson_33(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the report''s shapes, under its own name', NI),
    lesson_33(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('El presidente y ex ministro votó.', spanish, italian, S33a),
    must('two nouns under ONE ARTICLE with a singular verb are one person', S33a, 'Il presidente e ex ministro votò.'),
    reason_translate('El voto de los perros.', spanish, italian, S33b),
    must('a HEADING with its de phrase', S33b, 'Il voto dei cani.'),
    reason_translate('Un 60% de los perros comen el pan.', spanish, italian, S33c),
    must('a SHARE OF A PLURAL takes a plural verb', S33c, 'Un 60% dei cani mangia il pane.'),
    reason_translate('El perro dice que el gato "come el pan".', spanish, italian, S33d),
    must('a QUOTATION that opens on the verb', S33d, 'Il cane dice che il gatto "mangia il pane".'),
    reason_translate('Los perros votaron cara a las elecciones.', spanish, italian, S33e),
    must('a WORD OF SEVERAL WORDS on each side, the Italian one contracted by its last word', S33e,
         'I cani votarono in vista delle elezioni.'),
    reason_translate('El perro come el pan e intenta comer la sopa.', spanish, italian, S33f),
    must('`e'', Spanish''s `y'' before the sound i', S33f, 'Il cane mangia il pane e tenta di mangiare la minestra.'),
    reason_translate('El perro come el pan e intenta comer la sopa.', spanish, english, S33g),
    must('and English leaves out a SUBJECT THE CLAUSE BEFORE NAMED', S33g, 'The dog eats the bread and tries to eat the soup.'),
    reason_translate('El perro es capaz de comer el pan bebiendo la leche.', spanish, italian, S33h),
    must('a GERUND after an infinitive after the copula', S33h, 'Il cane è capace di mangiare il pane bevendo il latte.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_33(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"dei" is the contraction of "di i". "delle" is the contraction of "di le".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every number is masculine.
The noun "cane" means "dog". "cani" is the plural of "cane". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". The noun "minestra" means "soup". The noun "latte" means "milk".
The noun "voto" means "vote". The feminine noun "elezione" means "election". "elezioni" is the plural of "elezione".
The noun "presidente" means "president". The noun "ministro" means "minister".
The adjective "ex" means "ex". The adjective "capace" means "able".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
The verb "beve" means "drinks". "bere" is the infinitive of "beve". "bevendo" is the gerund of "beve".
The verb "vota" means "votes". "votò" is the past of "vota". "votarono" is the plural of "votò".
The verb "tenta" means "tries". "tentare" is the infinitive of "tenta". "tenta" takes "di" before the infinitive.
The verb "dice" means "says". The verb "è" means "is".
The conjunction "che" means "that". The conjunction "e" means "and".
The preposition "di" means "of". The preposition "in vista di" means "ahead of".').
lesson_33(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every number is masculine.
The noun "perro" means "dog". The noun "gato" means "cat".
The noun "pan" means "bread". The noun "sopa" means "soup". The noun "leche" means "milk". "leche" is feminine.
The noun "voto" means "vote". The feminine noun "elección" means "election". "elecciones" is the plural of "elección".
The noun "presidente" means "president". The noun "ministro" means "minister".
The adjective "ex" means "ex". The adjective "capaz" means "able".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
The verb "bebe" means "drinks". "beber" is the infinitive of "bebe". "bebiendo" is the gerund of "bebe".
The verb "vota" means "votes". "votó" is the past of "vota". "votaron" is the plural of "votó".
The verb "intenta" means "tries". "intentar" is the infinitive of "intenta".
The verb "dice" means "says". The verb "es" means "is".
The conjunction "que" means "that". The conjunction "y" means "and". The conjunction "e" means "and".
The preposition "de" means "of". The preposition "cara a" means "ahead of".').

section_34 :-
    format("~n34. An Italian extract from the Washington Post into Spanish: of which with no verb, the one led by, a name among the adjectives~n", []),
    lesson_34(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the extract''s shapes, under its own name', NI),
    lesson_34(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('Il cane vede quattro gatti di cui solo uno, quello fissato dal cane, uscito dalla casa ...', italian, spanish, S34a),
    must('OF WHICH with no verb, THE ONE fixed by, and `da'' after a verb whose perfect takes the copula is `from''', S34a,
         'El perro ve cuatro gatos de los que sólo uno, el fijado por el perro, salido desde la casa...'),
    reason_translate('Il governo Dini successivo mangia il pane.', italian, spanish, S34b),
    must('a NAME AMONG THE ADJECTIVES keeps its place', S34b, 'El gobierno Dini sucesivo come el pan.'),
    reason_translate('L''Italia attuale vede il cane.', italian, spanish, S34c),
    must('an ELIDED ARTICLE says no gender, and the lesson says the name''s', S34c, 'La Italia actual ve el perro.'),
    reason_translate('Il governo vede quello di Berlusconi.', italian, spanish, S34d),
    must('`quello di'': a word that REPLACES THE NOUN', S34d, 'El gobierno ve al de Berlusconi.'),
    reason_translate('Nessun altro cane mangia il pane.', italian, spanish, S34e),
    must('a PRONOUN THAT IS AN ADJECTIVE TOO, before a noun', S34e, 'Ningún otro perro come el pan.'),
    reason_translate('(dal giornale) il cane mangia il pane.', italian, spanish, S34f),
    must('a BRACKET AT THE HEAD stands aside', S34f, '(desde el diario) el perro come el pan.'),
    reason_translate('Niente, se il cane mangia il pane.', italian, spanish, S34g),
    must('an ANSWER and its condition', S34g, 'Nada, si el perro come el pan.'),
    reason_translate('The Washington Post.', italian, spanish, S34h),
    must('a LINE OF NAMES is the name', S34h, 'The Washington Post.'),
    reason_translate('Il cane mangia il pil.', italian, spanish, S34i),
    must('an ACRONYM goes out in capitals', S34i, 'El perro come el PIB.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_34(italian, 'Italian is a language.
The masculine article "il" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "le" is the plural of "la".
"l''" is the elision of "la". "dal" is the contraction of "da il". "dalla" is the contraction of "da la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every number is masculine.
The noun "cane" means "dog". The noun "gatto" means "cat". "gatti" is the plural of "gatto".
The noun "pane" means "bread". The noun "casa" means "house".
The noun "governo" means "government". The noun "giornale" means "newspaper".
The masculine noun "pil" means "GDP". "pil" is an acronym. "italia" is feminine.
The adjective "successivo" means "successive". The adjective "attuale" means "current".
The verb "mangia" means "eats". The verb "vede" means "sees".
The verb "fissa" means "fixes". "fissato" is the participle of "fissa".
The verb "esce" means "exits". "uscito" is the participle of "esce".
The verb "è" means "is". "è" is the auxiliary of "esce".
"cui" is a relative. The word "cui" follows the preposition.
The conjunction "se" means "if".
The word "quello" replaces the noun. The pronoun "quello" means "that".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The pronoun "niente" means "nothing". The pronoun "niente" does not precede the verb.
The adverb "solo" means "only". The number "quattro" means "four".
The masculine determiner "nessuno" means "no". "nessun" is the apocope of "nessuno".
The masculine determiner "altro" means "another". The masculine adjective "altro" means "other". The masculine pronoun "altro" means "others". The pronoun "altro" does not precede the verb.
The preposition "di" means "of". The preposition "da" means "by". The preposition "da" means "from".').
lesson_34(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
"al" is the contraction of "a el". "del" is the contraction of "de el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every number is masculine.
The word "el" replaces the noun.
The noun "perro" means "dog". The noun "gato" means "cat".
The noun "pan" means "bread". The noun "casa" means "house".
The noun "gobierno" means "government". The noun "diario" means "newspaper".
The masculine noun "pib" means "GDP". "pib" is an acronym.
The adjective "sucesivo" means "successive". The adjective "actual" means "current".
The verb "come" means "eats". The verb "ve" means "sees".
The verb "fija" means "fixes". "fijado" is the participle of "fija".
The verb "sale" means "exits". "salido" is the participle of "sale".
"que" is a relative. The conjunction "que" means "that". The conjunction "si" means "if".
The pronoun "eso" means "that". The pronoun "eso" does not precede the verb.
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The pronoun "nada" means "nothing". The pronoun "nada" does not precede the verb.
The adverb "sólo" means "only". The number "cuatro" means "four".
The masculine determiner "ningún" means "no".
The masculine determiner "otro" means "another". The masculine adjective "otro" means "other". The masculine pronoun "otro" means "others". The pronoun "otro" does not precede the verb.
The preposition "a" means "to". The preposition "de" means "of". The preposition "por" means "by". The preposition "desde" means "from".
The word "a" precedes the person.').

section_35 :-
    format("~n35. A Spanish report on the Clinton inquiry into Italian: al and an infinitive in front, according to and who said so, a gerund with its pronoun, what it does is~n", []),
    lesson_35(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_35(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Al abrir la casa, el perro come el pan.', spanish, italian, S35a),
    must('AL AND AN INFINITIVE in front, to its comma: the moment, and the Italian gerund', S35a,
         'Aprendo la casa, il cane mangia il pane.'),
    reason_translate('El perro come el pan, según añadieron las fuentes.', spanish, italian, S35b),
    must('ACCORDING TO and a clause whose speaker follows its verb: who said so', S35b,
         'Il cane mangia il pane, come aggiunsero le fonti.'),
    reason_translate('El perro escribió a Maria, pidiéndole el pan.', spanish, italian, S35c),
    must('a verb that TAKES `a'' BEFORE THE PERSON writes to them, and a GERUND keeps its PRONOUN', S35c,
         'Il cane scrisse a Maria, chiedendogli il pane.'),
    reason_translate('La insistencia lo que hace es comer el pan.', spanish, italian, S35d),
    must('WHAT IT DOES: `lo'' replaces a noun, with a phrase in front of it', S35d,
         'L''insistenza quello che fa è mangiare il pane.'),
    reason_translate('La casa acusó a la mayoría de buscar el pan.', spanish, italian, S35e),
    must('an object after an infinitive is the INFINITIVE''S, and the person is the verb''s own', S35e,
         'La casa accusò la maggioranza di cercare il pane.'),
    reason_translate('El perro está siendo visto.', spanish, italian, S35f),
    must('the PROGRESSIVE OF A PASSIVE is the verb that marks the passive', S35f, 'Il cane viene visto.'),
    reason_translate('El perro está siendo visto.', spanish, english, S35g),
    must('... and English writes the copula''s progressive', S35g, 'The dog is being seen.'),
    reason_translate('La ministra, Janet Reno, come el pan.', spanish, italian, S35h),
    must('a NAME between commas runs on through a capitalised word the lesson knows', S35h,
         'Il ministro, Janet Reno, mangia il pane.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_35(spanish, 'Spanish is a language.
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
The adverb "a puerta cerrada" means "behind closed doors".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come".
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
lesson_35(italian, 'Italian is a language.
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
The adverb "a porte chiuse" means "behind closed doors".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
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

section_36 :-
    format("~n36. An Italian letter into Spanish: adjectives before a name and before a subject, two clauses of che, an object in front, the subject after its verb, a signature~n", []),
    lesson_36(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the letter''s shapes, under its own name', NI),
    lesson_36(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('Il cane mangia il pane con i nuovi, piccoli, Hitler.', italian, spanish, S36a),
    must('ADJECTIVES BETWEEN COMMAS before a name are one phrase', S36a,
         'El perro come el pan con los nuevos, pequeños, Hitler.'),
    reason_translate('Stanca e rossa, la casa dorme.', italian, spanish, S36b),
    must('ADJECTIVES IN FRONT of the subject stay there and agree with its noun', S36b,
         'Cansada y roja, la casa duerme.'),
    reason_translate('Il cane dice che la casa è grande e che il gatto mangia il pane.', italian, spanish, S36c),
    must('TWO CLAUSES OF `che'' joined by `e'' are both the verb''s', S36c,
         'El perro dice que la casa es grande y que el gato come el pan.'),
    reason_translate('Il cane mangia il pane senza rendersi conto che la casa è grande.', italian, spanish, S36d),
    must('a verb of TWO WORDS with its pronoun joined to the first, and `"da cuenta" takes "de" before the clause.''', S36d,
         'El perro come el pan sin darse cuenta de que la casa es grande.'),
    reason_translate('Il cane il pane non ce l''ha.', italian, spanish, S36e),
    must('an OBJECT IN FRONT taken up by a pronoun, and `"ce" is the particle of "ha".''', S36e,
         'El perro no tiene el pan.'),
    reason_translate('I cani mangiano il pane e sono grandi.', italian, spanish, S36f),
    must('a second clause with no subject takes the first one''s where its verb could be either', S36f,
         'Los perros comen el pan y son grandes.'),
    reason_translate('Il cane decide se il gatto mangia il pane.', italian, english, S36g),
    must('`"decide" takes the question.'': `se'' after it is WHETHER', S36g,
         'The dog decides whether the cat eats the bread.'),
    reason_translate('Forse è venuto il momento di mangiare il pane.', italian, spanish, S36h),
    must('an ADVERB IN FRONT stays there, and the subject after an intransitive verb keeps its noun''s infinitive', S36h,
         'Quizás ha venido el momento de comer el pan.'),
    reason_translate('Il cane cerca di stare nella casa.', italian, spanish, S36i),
    must('`stare'' is the infinitive of the STATE, `estar''', S36i, 'El perro busca estar en la casa.'),
    reason_translate('Maria Bianchi Roma - Milano P pane "rosso".', italian, spanish, S36j),
    must('a SIGNATURE and the next letter''s title: names, a dash, names and a noun with a quoted word', S36j,
         'Maria Bianchi Roma – Milano P pan "rojo".'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_36(italian, 'Italian is a language.
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
The adverb "solo" means "only". The adverb "forse" means "perhaps".').
lesson_36(spanish, 'Spanish is a language.
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
The mark "¿" begins the question.').

section_37 :-
    format("~n37. A Spanish report into Italian: a name in quotation marks, an aside after a name, a reporting clause at the end, a title before a name, an adjective in the lesson's order~n", []),
    lesson_37(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_37(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('El perro dice que "María come el pan" y que "el gato duerme".', spanish, italian, S37a),
    must('a NAME AT THE HEAD OF A QUOTATION keeps its capital and its mark, and a quotation may close on its verb', S37a,
         'Il cane dice che "María mangia il pane" e che "il gatto dorme".'),
    reason_translate('El perro ve a Juan Pérez, amigo del gato, en la casa.', spanish, italian, S37b),
    must('a phrase between commas after a name is the NAME''S ASIDE', S37b,
         'Il cane vede Juan Pérez, amico del gatto, nella casa.'),
    reason_translate('El perro, conocido en la casa como Rex, come el pan.', spanish, italian, S37c),
    must('a PARTICIPLE WITH ITS OWN PHRASES between commas is an aside of the subject', S37c,
         'Il cane, conosciuto nella casa come Rex, mangia il pane.'),
    reason_translate('El perro come el pan el Jueves.', spanish, italian, S37d),
    must('a DAY the source capitalises is written as a day', S37d, 'Il cane mangia il pane il giovedì.'),
    reason_translate('El perro come el pan, dice el ministro de la casa, Abel Matutes.', spanish, italian, S37e),
    must('a clause at the end whose subject is a PERSON reports the rest, and the name after the last comma is apposed', S37e,
         'Il cane mangia il pane, dice il ministro della casa, Abel Matutes.'),
    reason_ir('El perro come el pan, abre la puerta.', spanish, IR37f),
    show('... and a clause whose phrase after the verb is no person keeps it as its object', IR37f),
    reason_translate('El perro come la sopa común.', spanish, italian, S37g),
    must('an ADJECTIVE in the lesson''s order, where a feminine noun spelled `corrente'' came first', S37g,
         'Il cane mangia la minestra comune.'),
    reason_translate('El perro ve al señor Pérez.', spanish, italian, S37h),
    must('a noun before a name takes its SHORT FORM', S37h, 'Il cane vede il signor Pérez.'),
    reason_translate('La casa no es grande ni roja.', spanish, italian, S37i),
    must('`ni'' between two adjectives is NOR', S37i, 'La casa non è grande né rossa.'),
    reason_translate('El perro duerme si come el pan.', spanish, italian, S37j),
    must('after `si'' the verb is NO COMMAND', S37j, 'Il cane dorme se mangia il pane.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_37(spanish, 'Spanish is a language.
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
The preposition "por" means "by".').
lesson_37(italian, 'Italian is a language.
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
The preposition "da" means "by".').

section_38 :-
    format("~n38. An Italian letter into Spanish: a list of names, a name with its relative clause, a reflexive verb with its subject after it, the writer's comment, an exclamation, a signature~n", []),
    lesson_38(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the letter''s shapes, under its own name', NI),
    lesson_38(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('Il cane parla con Maria, Carla, Luisa e Ana.', italian, spanish, S38a),
    must('a LIST OF NAMES with commas is one list', S38a, 'El perro habla con Maria, Carla, Luisa y Ana.'),
    reason_translate('Maria che dorme mangia il pane.', italian, spanish, S38b),
    must('a NAME WITH ITS RELATIVE CLAUSE is a subject', S38b, 'Maria que duerme come el pan.'),
    reason_translate('Il cane dice che, ieri, proprio il gatto dorme.', italian, spanish, S38c),
    must('an ADVERB AFTER A FRONT''S COMMA stays before the subject', S38c, 'El perro dice que, ayer, precisamente el gato duerme.'),
    reason_ir('Mi si è stretto il cuore leggendo il libro.', italian, IR38d),
    show('a verb the lesson calls REFLEXIVE, with its pronoun before it, has its subject after it: the heart', IR38d),
    reason_translate('Mi si è stretto il cuore leggendo il libro.', italian, spanish, S38e),
    must('... which Spanish writes after the verb as Italian does', S38e, 'Se me ha apretado el corazón leyendo el libro.'),
    reason_translate('Il cane ha osato, sottolineo "osato", mangiare il pane.', italian, spanish, S38f),
    must('the WRITER''S OWN COMMENT between two commas stands where it stood, its word in its marks', S38f,
         'El perro ha osado, subrayo "osado", comer el pan.'),
    reason_translate('Mio dio, che tristezza!', italian, spanish, S38g),
    must('an EXCLAMATION''s what, and the mark Spanish opens one with', S38g, '¡Mi dios, qué tristeza!'),
    reason_translate('Maria Rossi Roma (RM) Bastiglia e termidoro.', italian, spanish, S38h),
    must('a SIGNATURE whose town ends on its province in brackets, and the next letter''s title', S38h,
         'Maria Rossi Roma (RM) Bastilla y termidor.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_38(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
"l''" is the elision of "lo". "l''" is the elision of "la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The noun "cane" means "dog". The noun "gatto" means "cat". The noun "pane" means "bread". The noun "vino" means "wine".
The noun "cuore" means "heart". The noun "libro" means "book". The noun "tristezza" means "sadness". The noun "dio" means "god".
The feminine noun "bastiglia" means "bastille". The masculine noun "termidoro" means "thermidor".
The verb "mangia" means "eats". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". The verb "parla" means "speaks". The verb "dice" means "says".
The verb "legge" means "reads". "leggendo" is the gerund of "legge".
The verb "sottolinea" means "underlines". "sottolineo" is the first person of "sottolinea".
The verb "osa" means "dares". "osato" is the participle of "osa".
The verb "stringe" means "tightens". "stretto" is the participle of "stringe". "stringe" is reflexive.
The verb "è" means "is".
"che" is a relative. The conjunction "che" means "that". The word "che" means "what".
The conjunction "e" means "and".
The preposition "a" means "to". The preposition "di" means "of". The preposition "con" means "with".
The auxiliary "ha" means "has". "è" is the auxiliary of the reflexive.
The pronoun "mi" means "me". The possessive "mio" means "my".
The adverb "ieri" means "yesterday". The adverb "proprio" means "precisely".
The reflexive pronoun "si" means "itself".').
lesson_38(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "a" precedes the person.
The noun "perro" means "dog". The noun "gato" means "cat". The noun "pan" means "bread". The noun "vino" means "wine".
The noun "corazón" means "heart". The noun "libro" means "book". The noun "tristeza" means "sadness". The noun "dios" means "god".
The feminine noun "bastilla" means "bastille". The masculine noun "termidor" means "thermidor".
The verb "come" means "eats". "comer" is the infinitive of "come".
The verb "duerme" means "sleeps". The verb "habla" means "speaks". The verb "dice" means "says".
The verb "lee" means "reads". "leyendo" is the gerund of "lee".
The verb "subraya" means "underlines". "subrayo" is the first person of "subraya".
The verb "osa" means "dares". "osado" is the participle of "osa".
The verb "aprieta" means "tightens". "apretado" is the participle of "aprieta".
The verb "es" means "is".
"que" is a relative. The conjunction "que" means "that". The word "qué" means "what".
The conjunction "y" means "and".
The preposition "a" means "to". The preposition "de" means "of". The preposition "con" means "with".
The auxiliary "ha" means "has".
The pronoun "me" means "me". The possessive "mi" means "my".
The adverb "ayer" means "yesterday". The adverb "precisamente" means "precisely".
The reflexive pronoun "se" means "itself".
The mark "¡" begins the exclamation.').

section_39 :-
    format("~n39. A Spanish column into Italian: the word for more before a participle, what a copula has last is its subject, a clause of the verb's after a phrase, a participle said of the object~n", []),
    lesson_39(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the column''s shapes, under its own name', NS),
    lesson_39(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('El perro come con una alegría más contenida.', spanish, italian, S39a),
    must('the WORD FOR MORE between a noun and its participle is the participle''s degree, agreeing with the noun', S39a,
         'Il cane mangia con un''allegria più contenuta.'),
    reason_translate('El perro come con una alegría más contenida.', spanish, english, S39b),
    must('... which English puts before the noun', S39b, 'The dog eats with a more contained joy.'),
    reason_translate('Los países, más modernizados, duermen.', spanish, italian, S39c),
    must('... and between two commas after a subject it stays where it stood', S39c, 'I paesi, più modernizzati, dormono.'),
    reason_ir('Es el precio lo que los hace deseados.', spanish, IR39d),
    show('WHAT A COPULA WITH NOBODY BEFORE IT HAS LAST IS ITS SUBJECT: the phrase whose noun a relative clause stands for', IR39d),
    reason_translate('Es el precio lo que los hace deseados.', spanish, italian, S39e),
    must('... the order kept, and the participle said of the object pronoun', S39e, 'È il prezzo quello che li fa desiderati.'),
    reason_translate('Es el precio lo que los hace deseados.', spanish, english, S39f),
    must('... and English puts the subject first', S39f, 'The one that makes them wished is the price.'),
    reason_ir('Descubren con sorpresa que el teléfono está vacío.', spanish, IR39g),
    show('a CLAUSE OF THE VERB''S after a phrase, where no relative clause reads: a copula with its adjective has no gap', IR39g),
    reason_translate('Ella es alta.', spanish, italian, S39h),
    must('a predicate adjective agrees with a PRONOUN subject''s gender', S39h, 'Lei è alta.'),
    reason_translate('Alguien debería comer el pan.', spanish, english, S39i),
    must('English''s conditional of must is SHOULD', S39i, 'Somebody should eat the bread.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_39(spanish, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not". The word "lo" replaces the noun.
The word "más" begins the comparative. The adverb "más" means "more". The preposition "más" means "plus".
The noun "perro" means "dog". The noun "pan" means "bread". The noun "alegría" means "joy". The noun "precio" means "price".
The noun "teléfono" means "telephone". The noun "sorpresa" means "surprise".
The noun "país" means "country". "países" is the plural of "país".
The masculine adjective "alto" means "tall". The feminine adjective "alta" means "tall".
The masculine adjective "vacío" means "empty". The feminine adjective "vacía" means "empty".
The verb "come" means "eats". "comer" is the infinitive of "come".
The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
The verb "contiene" means "contains". "contenido" is the participle of "contiene". "contenida" is the participle of "contiene". "contenida" is feminine.
The verb "moderniza" means "modernises". "modernizado" is the participle of "moderniza". "modernizados" is the participle of "moderniza". "modernizados" is the plural of "modernizado".
The verb "hace" means "makes".
The verb "desea" means "wishes". "deseado" is the participle of "desea". "deseados" is the participle of "desea". "deseados" is the plural of "deseado".
The verb "descubre" means "discovers". "descubren" is the plural of "descubre".
The verb "es" means "is".
The auxiliary "está" means "is". The auxiliary "está" marks the state. The verb "está" means "stays".
The modal "debe" means "must". "debería" is the conditional of "debe".
"que" is a relative. The conjunction "que" means "that".
The preposition "con" means "with".
The pronoun "lo" means "it". The pronoun "los" means "them". The pronoun "ella" means "she". The pronoun "alguien" means "somebody".').
lesson_39(italian, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
The article "lo" comes before a vowel.
"l''" is the elision of "lo". "l''" is the elision of "la". "un''" is the elision of "una".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The word "quello" replaces the noun. The pronoun "quello" means "that". The pronoun "quello" does not precede the verb.
The word "più" begins the comparative. The adverb "più" means "more".
The noun "cane" means "dog". The noun "pane" means "bread". The noun "allegria" means "joy". The noun "prezzo" means "price".
The noun "telefono" means "telephone". The noun "sorpresa" means "surprise".
The noun "paese" means "country". "paesi" is the plural of "paese".
The masculine adjective "alto" means "tall". The feminine adjective "alta" means "tall".
The feminine adjective "vuota" means "empty". The masculine adjective "vuoto" means "empty".
The verb "mangia" means "eats". "mangiare" is the infinitive of "mangia".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "contiene" means "contains". "contenuto" is the participle of "contiene". "contenuta" is the participle of "contiene". "contenuta" is feminine.
The verb "modernizza" means "modernises". "modernizzato" is the participle of "modernizza". "modernizzati" is the participle of "modernizza". "modernizzati" is the plural of "modernizzato".
The verb "fa" means "makes".
The verb "desidera" means "wishes". "desiderato" is the participle of "desidera". "desiderati" is the participle of "desidera". "desiderati" is the plural of "desiderato".
The verb "scopre" means "discovers". "scoprono" is the plural of "scopre".
The verb "è" means "is".
"che" is a relative. The conjunction "che" means "that".
The preposition "con" means "with".
The pronoun "lo" means "it". The pronoun "li" means "them". The pronoun "lei" means "she". The pronoun "qualcuno" means "somebody".').

section_40 :-
    format("~n40. An Italian letter into Spanish: nothing to object, perché before a subjunctive, a comment at the end of a clause, chi, a che clause in front, a command with its pronoun joined~n", []),
    lesson_40(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the letter''s shapes, under its own name', NI),
    lesson_40(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('Nulla da eccepire sulla necessità di vigilare.', italian, spanish, S40a),
    must('NOTHING TO OBJECT: a pronoun that stands alone and the infinitive it is for, with no verb', S40a,
         'Nada para objetar sobre la necesidad de vigilar.'),
    reason_translate('Il cane vigila perché il gatto non mangi il pane.', italian, spanish, S40b),
    must('`perché'' before a SUBJUNCTIVE is so that, the mood saying which of its two meanings', S40b,
         'El perro vigila para que el gato no come el pan.'),
    reason_translate('Il cane dorme, come, peraltro, accadde in passato.', italian, spanish, S40c),
    must('a COMMENT at the end of a clause, `as'', with its insertion and its commas', S40c,
         'El perro duerme, como, además, pasó en pasado.'),
    reason_translate('Il cane redarguisce chi non lo imita.', italian, spanish, S40d),
    must('`chi'' is the one who: the lesson says it begins the relative', S40d, 'El perro reprende al que no lo imita.'),
    reason_ir('Che il cane dorma lo dimostrano i fatti.', italian, IR40e),
    show('a CLAUSE OF `CHE'' IN FRONT, taken up again by `lo'': the phrase after the verb is its subject', IR40e),
    reason_translate('Che il cane dorma lo dimostrano i fatti.', italian, english, S40f),
    must('... which English writes with the subject first', S40f, 'That the dog sleeps the facts demonstrate him.'),
    reason_translate('Se sbaglio correggetemi.', italian, spanish, S40g),
    must('a COMMAND WITH ITS PRONOUN JOINED, after a clause of `se'' with no comma', S40g, 'Si equivoco corregidme.'),
    reason_translate('Il cane vede i gatti (leggi topi) grandi.', italian, spanish, S40h),
    must('a BRACKET between a noun and its adjective is the phrase''s, written after it', S40h,
         'El perro ve los gatos grandes (lees ratones).'),
    reason_translate('Li si vede.', italian, english, S40i),
    must('`si'' after an object pronoun is the IMPERSONAL one', S40i, 'One sees them.'),
    reason_translate('Dorme il dott Di Pietro.', italian, english, S40j),
    must('a TITLE and the name after it are one subject, and `Di'' begins the name', S40j, 'The doctor Di Pietro sleeps.'),
    reason_translate('La casa non mi risulta sia grande.', italian, spanish, S40k),
    must('a clause with its `che'' LEFT OUT before a subjunctive, after a verb the lesson says takes the clause', S40k,
         'La casa no me resulta que es grande.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_40(italian, 'Italian is a language.
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
The verb "vuole" means "wants". "voglia" is the subjunctive of "vuole". The verb "mura" means "walls". "murare" is the infinitive of "mura".
The verb "scappa" means "escapes". "scappando" is the gerund of "scappa".
The verb "pulisce" means "cleans". "pulite" is the participle of "pulisce". "pulite" is feminine. "pulite" is the plural of "pulita". "pulita" is the participle of "pulisce".
The verb "è" means "is". "sono" is the plural of "è". "sia" is the subjunctive of "è".
The intransitive verb "ne fa testo" means "testifies to it". "ne fanno testo" is the plural of "ne fa testo".
The intransitive verb "dorme" means "sleeps".
"che" is a relative. The conjunction "che" means "that". The word "chi" means "who". The word "chi" begins the relative.
"cui" is a relative. The word "cui" follows the preposition.
The pronoun "molti" means "many". The pronoun "molti" does not precede the verb.
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
lesson_40(spanish, 'Spanish is a language.
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
The pronoun "él" means "he". The pronoun "él" does not precede the verb.
The pronoun "nada" means "nothing". The pronoun "nada" does not precede the verb.
The possessive "nuestro" means "our".
The adverb "aquí" means "here". The adverb "además" means "moreover". The adverb "ayer" means "yesterday". The adverb "aquí entre nosotros" means "here among us".
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".').

section_41 :-
    format("~n41. A Spanish report into Italian: a surname at the head, the person told before a clause, a count alone, who said so, an impersonal perfect, a relative clause with its subject after its verb, an absolute participle~n", []),
    lesson_41(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_41(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Redondo duerme.', spanish, italian, S41a),
    must('a SURNAME the lesson knows only as an adjective, at the head and before its verb, is a name', S41a, 'Redondo dorme.'),
    reason_translate('Maria declara a Omar que el perro duerme.', spanish, italian, S41b),
    must('after a verb the lesson says TAKES THE CLAUSE, the person is the one told and the clause the verb''s', S41b,
         'Maria dichiara a Omar che il cane dorme.'),
    reason_translate('El perro duerme entre las tres y las cinco.', spanish, italian, S41c),
    must('an article and a COUNT ALONE is a phrase whose noun was left out', S41c, 'Il cane dorme tra le tre e le cinque.'),
    reason_translate('En la casa, según dijo Omar a Maria, el perro duerme.', spanish, italian, S41d),
    must('WHO SAID SO, between two commas, written back where it stood with the word for `as''', S41d,
         'Nella casa, come disse Omar a Maria, il cane dorme.'),
    reason_translate('Se ha comido el pan.', spanish, italian, S41e),
    must('the IMPERSONAL word builds its perfect as the reflexive does', S41e, 'Si è mangiato il pane.'),
    reason_ir('El perro llega después de la que comen los gatos.', spanish, IR41f),
    show('a RELATIVE CLAUSE whose verb disagrees with its phrase has its subject after the verb', IR41f),
    reason_translate('El perro llega después de la que comen los gatos.', spanish, english, S41g),
    must('... which English writes with the subject first', S41g, 'The dog arrives after the one that the cats eat.'),
    reason_translate('En la casa que vieron ayer, el perro come el pan.', spanish, english, S41h),
    must('a FRONT that ends at a comma with a phrase after it', S41h,
         'In the house that they saw yesterday, the dog eats the bread.'),
    reason_translate('El perro come el pan dada la situación.', spanish, english, S41i),
    must('a participle before a phrase it agrees with is an ABSOLUTE clause, and not the bread''s', S41i,
         'The dog eats the bread given the situation.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_41(spanish, 'Spanish is a language.
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
lesson_41(italian, 'Italian is a language.
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

section_42 :-
    format("~n42. An Italian letter into Spanish: a connecting adverb, what there is after an adverb, but only, the ones that exist, as in, the future of can, a command of the first person plural, a clause after sembra, a date with its adjective, who wrote it~n", []),
    lesson_42(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the letter''s shapes, under its own name', NS),
    lesson_42(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Non vi saranno quindi altri pani.', italian, spanish, S42a),
    must('an adverb that JOINS its clause to the one before is no intensifier of the adjective after it, and what there is comes after it', S42a,
         'No habrá entonces otros panes.'),
    reason_translate('Non vi saranno quindi altri pani.', italian, english, S42b),
    must('... which English writes after `will''', S42b, 'There will then be no other breads.'),
    reason_translate('Il cane non mangia il pane, ma solo il formaggio.', italian, english, S42c),
    must('ADVERBS after a comma and a coordinator are the phrase''s', S42c, 'The dog does not eat the bread, but only the cheese.'),
    reason_translate('Il cane dorme con quelli esistenti.', italian, spanish, S42d),
    must('after a word that REPLACES THE NOUN, an adjective and nothing else leaves the noun out', S42d, 'El perro duerme con los existentes.'),
    reason_translate('Il cane dorme come nella casa.', italian, spanish, S42e),
    must('AS takes a phrase with a preposition of its own', S42e, 'El perro duerme como en la casa.'),
    reason_translate('Il cane potrà dormire.', italian, english, S42f),
    must('English''s `can'' has no future: WILL BE ABLE TO', S42f, 'The dog will be able to sleep.'),
    reason_translate('Mangiamolo.', italian, spanish, S42g),
    must('a form the lesson calls a HORTATIVE, with its pronoun joined, is the command of the first person plural', S42g, 'Comamoslo.'),
    reason_translate('Mangiamolo.', italian, english, S42h),
    must('... let us', S42h, 'Let us eat him.'),
    reason_translate('Il cane ci sembrava fosse stanco.', italian, spanish, S42i),
    must('a clause with its CHE LEFT OUT comes before a phrase where its verb is no determiner', S42i, 'El perro nos parecía que era cansado.'),
    reason_translate('Il cane dorme negli articoli apparsi il 12 luglio scorso.', italian, spanish, S42j),
    must('a DATE with its adjective, and a participle''s own number', S42j, 'El perro duerme en los artículos aparecidos el 12 de julio último.'),
    reason_translate('Il cane dorme, come invece hanno scritto gli inviati del gatto, negli articoli.', italian, spanish, S42k),
    must('WHO WROTE IT, with an adverb before its verb and an `of'' phrase on its speaker, stays where it stood', S42k,
         'El perro duerme, como en cambio han escrito los enviados del gato, en los artículos.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_42(spanish, 'Spanish is a language.
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
lesson_42(italian, 'Italian is a language.
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

section_43 :-
    format("~n43. A Spanish column into Italian: and inside a phrase, a sense by the article's gender, a noun after a noun, an answer, a comparison of two adjectives, the impersonal's participle, a verb before a gerund, the comma after an apposition, the article of de los que, two subjects after their verb~n", []),
    lesson_43(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the column''s shapes, under its own name', NS),
    lesson_43(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('El perro de Juan y María come el pan.', spanish, english, S43a),
    must('AND after a preposition, with a singular verb, joins inside the preposition''s phrase', S43a, 'The dog of Juan and María eats the bread.'),
    reason_translate('La final es larga.', spanish, italian, S43b),
    must('a noun the lesson states in BOTH GENDERS takes the meaning of its article''s', S43b, 'La finale è lunga.'),
    reason_translate('Los chicos hinchas duermen.', spanish, italian, S43c),
    must('a NOUN AFTER A NOUN says what kind', S43c, 'I ragazzi tifosi dormono.'),
    reason_translate('No, el perro duerme.', spanish, english, S43d),
    must('an ANSWER before a comma denies nothing', S43d, 'No, the dog sleeps.'),
    reason_translate('Los perros más negros que blancos duermen.', spanish, italian, S43e),
    must('a COMPARISON of two adjectives is one phrase', S43e, 'I cani più neri che bianchi dormono.'),
    reason_translate('Se ha producido una coincidencia.', spanish, italian, S43f),
    must('the IMPERSONAL''s participle agrees with the object', S43f, 'Si è prodotta una coincidenza.'),
    reason_translate('El perro sigue durmiendo.', spanish, italian, S43g),
    must('a verb BEFORE A GERUND crosses by the meaning the lesson calls progressive', S43g, 'Il cane continua a dormire.'),
    reason_translate('Juan, el hermano de María, duerme.', spanish, italian, S43h),
    must('the COMMA that closes an apposition stays', S43h, 'Juan, il fratello di María, dorme.'),
    reason_translate('El perro de los que comen pan duerme.', spanish, italian, S43i),
    must('the article of DE LOS QUE agrees with what it stands for', S43i, 'Il cane di quelli che mangiano pane dorme.'),
    reason_translate('Sólo cabe el perro, y el gato.', spanish, italian, S43j),
    must('TWO PHRASES after a singular intransitive verb are its subject', S43j, 'Solo rimangono il cane e il gatto.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_43(spanish, 'Spanish is a language.
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
The reflexive pronoun "se" means "itself". The impersonal pronoun "se" means "one".').

lesson_43(italian, 'Italian is a language.
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
The pronoun "questo" means "this". The pronoun "questo" does not precede the verb.
The masculine demonstrative "questo" means "this". "questi" is the plural of "questo". The feminine demonstrative "questa" means "this". "queste" is the plural of "questa".
The possessive "suo" means "his".
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".').

section_1 :-
    format("~n1. The lesson: one hundred and eighty-three lines of controlled English, and what they say~n", []),
    lesson(Text),
    reason_learn(Text, Terms),
    length(Terms, N),
    must('terms learned', N, 300),
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
    must('seventeen lines, twenty-eight terms, held under the language''s own name', N14, 28),
    ( reason_lesson(italian, mean(casa, house)) -> IT0 = yes ; IT0 = no ),
    must('reason_lesson/2 answers for what it holds', IT0, yes),
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
    reason_unlearn(italian),
    ( reason_lesson(italian, mean(casa, house)) -> IT7 = yes ; IT7 = no ),
    must('and reason_unlearn/1 takes the whole lesson out again', IT7, no).

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

section_44 :-
    format("~n44. An Italian letter into Spanish: the time of day, a day and its part, a year in words, a denial after a coordinator, a polite command, a word said twice, the vocative between dashes, a speaker after the verb, bare nouns as an object, the experiencer, a comma after a coordinator, an adjective that is a preposition too~n", []),
    lesson_44(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the letter''s shapes, under its own name', NS),
    lesson_44(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Il cane dorme durante la messa delle ore 9:30.', italian, spanish, S44a),
    must('a TIME OF DAY is one number, its colon inside it', S44a, 'El perro duerme durante la misa de las horas 9:30.'),
    reason_translate('Il cane dorme domenica mattina.', italian, spanish, S44b),
    must('a DAY AND ITS PART are one time, joined by the word the lesson says joins a time', S44b, 'El perro duerme el domingo por la mañana.'),
    reason_translate('Il cane dorme il 9 luglio novantacinque.', italian, spanish, S44c),
    must('a YEAR IN WORDS after its month', S44c, 'El perro duerme el 9 de julio de noventa y cinco.'),
    reason_translate('Il cane mangia il pane e non il formaggio.', italian, spanish, S44d),
    must('a DENIAL AFTER A COORDINATOR is the second half''s', S44d, 'El perro come el pan y no el queso.'),
    reason_translate('Guardi, il cane dorme.', italian, spanish, S44e),
    must('a subjunctive alone before a comma is the POLITE COMMAND', S44e, 'Mire, el perro duerme.'),
    reason_translate('Il cane vede tanti, tanti gatti.', italian, spanish, S44f),
    must('a determiner SAID TWICE is said twice', S44f, 'El perro ve tantos, tantos gatos.'),
    reason_translate('Professore - gli ho chiesto - il cane dorme?', italian, spanish, S44g),
    must('the one SPOKEN TO, before a clause between dashes, and the question after them', S44g, 'Profesor – le he preguntado –, ¿el perro duerme?'),
    reason_translate('Professore - gli ha chiesto un signore mentre eravamo nella casa -, il cane dorme?', italian, english, S44h),
    must('a SPEAKER AFTER THE VERB between the dashes, with a clause of the speaker''s own', S44h, 'Professor – a gentleman has asked him while we were in the house –, does the dog sleep?'),
    reason_translate('Il ministro inserirà tecnici o politici.', italian, spanish, S44i),
    must('BARE PLURALS after a verb that takes an object are its object', S44i, 'El ministro insertará técnicos o políticos.'),
    reason_translate('Mi ha colpito il nuovo e diverso approccio.', italian, english, S44j),
    must('a verb that TAKES THE EXPERIENCER has its subject after it', S44j, 'The new and diverse approach has struck me.'),
    reason_translate('Il cane dorme sul pane, sulla casa e, soprattutto, sul formaggio.', italian, spanish, S44k),
    must('a COMMA AFTER A COORDINATOR, before an insertion, and every comma kept', S44k, 'El perro duerme en el pan, en la casa y, sobre todo, en el queso.'),
    reason_translate('Il cane dorme in un paese vicino, con il gatto.', italian, spanish, S44l),
    must('a word that is a PREPOSITION AND AN ADJECTIVE, after a noun and before a comma, is the adjective', S44l, 'El perro duerme en un país cercano, con el gato.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_44(spanish, 'Spanish is a language.
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
The conjunction "pero" means "but". The adverb "también" means "also". The adverb "muy" means "very". The adjective "grande" means "big".').

lesson_44(italian, 'Italian is a language.
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
"struck" is the participle of "strikes".').

section_45 :-
    format("~n45. A Spanish report into Italian: a small word in a name, a name with a hyphen and digits, a point inside a word, a channel and its number, a town that begins with its article, a second aside, a reporting clause after a quotation, an adverb before a participle set off, an adjective phrase between dashes, two verbs of one relative clause, an adverb between a determiner and its noun, a count with no noun, either ... or~n", []),
    lesson_45(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_45(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('El editor del Telenotícies migdia duerme.', spanish, italian, S45a),
    must('a SMALL WORD no lesson knows after an article and a name is the name''s', S45a, 'Il redattore del Telenotícies migdia dorme.'),
    reason_translate('El perro de TV-3 duerme.', spanish, italian, S45b),
    must('a name with a HYPHEN AND DIGITS is one name', S45b, 'Il cane di TV-3 dorme.'),
    reason_translate('"Paral.lel continuará", se limitó a contestar Omar.', spanish, italian, S45c),
    must('a POINT BETWEEN TWO LETTERS ends no sentence', S45c, '"Paral.lel continuerà", si limitò a rispondere Omar.'),
    reason_translate('El perro duerme en Figueres, Gandesa y El Vendrell.', spanish, italian, S45d),
    must('a town that BEGINS WITH ITS ARTICLE keeps it', S45d, 'Il cane dorme in Figueres, Gandesa e El Vendrell.'),
    reason_translate('Omar, editor del grupo, hermano que come con Maria, duerme.', spanish, english, S45e),
    must('a SECOND ASIDE is set off too, which English shows', S45e, 'Omar, editor of the group, brother that eats with Maria, sleeps.'),
    reason_translate('"No sé si el perro duerme", se limitó a contestar Omar.', spanish, english, S45f),
    must('after a quotation that closes on its word, the REPORTING CLAUSE first: Omar answered, and his `se'' is the verb''s', S45f, '"I do not know whether the dog sleeps", Omar limited to answer.'),
    reason_translate('Omar, recientemente fichado por el ministro, duerme.', spanish, italian, S45g),
    must('an ADVERB BEFORE A PARTICIPLE set off by commas stays before it', S45g, 'Omar, recentemente ingaggiato dal ministro, dorme.'),
    reason_translate('Omar - - próximo al ministro - - duerme.', spanish, italian, S45h),
    must('an ADJECTIVE PHRASE BETWEEN DASHES is set off', S45h, 'Omar – prossimo al ministro – dorme.'),
    reason_translate('El perro ve el pan que comen y dejan los gatos.', spanish, english, S45i),
    must('TWO VERBS of one relative clause share its gap and its subject', S45i, 'The dog sees the bread that the cats eat and leave.'),
    reason_translate('El grupo del todavía editor duerme.', spanish, english, S45j),
    must('an ADVERB BETWEEN A DETERMINER AND ITS NOUN stays before the noun', S45j, 'The group of the still editor sleeps.'),
    reason_translate('El perro ve las 33 casas (21 nuevas y 12 viejas).', spanish, english, S45k),
    must('a COUNT AND ADJECTIVES with no noun', S45k, 'The dog sees the 33 houses (21 new ones and 12 old ones).'),
    reason_translate('El perro come bien el pan o bien el queso.', spanish, italian, S45l),
    must('`bien'' before a choice with `o bien'' after it is EITHER', S45l, 'Il cane mangia o il pane o il formaggio.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_45(spanish, 'Spanish is a language.
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
The conjunction "y" means "and". The word "bien" begins the choice. The conjunction "o" means "or". The conjunction "o bien" means "or".
The conjunction "si" means "if". The conjunction "que" means "that". "que" is a relative.
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with".
The preposition "por" means "for". The preposition "por" means "by". The preposition "a principios de" means "at the start of".
The reflexive pronoun "se" means "itself". The impersonal pronoun "se" means "one".').

lesson_45(italian, 'Italian is a language.
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
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".').

section_46 :-
    format("~n46. An Italian interview into Spanish: a headline noun spelled like a verb, a byline, a title with its name, a count set off after a name, an example after a closing dash, who says so and where, a relative clause joined after an object, a denial before its verb, less, chi after a preposition, a clause at the head of a clause of che~n", []),
    lesson_46(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the interview''s shapes, under its own name', NS),
    lesson_46(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Tasse più care per mangiare meglio.', italian, spanish, S46a),
    must('a HEADLINE that opens on a plural noun spelled like a verb is the noun first', S46a, 'Tasas más caras para comer mejor.'),
    reason_translate('Di Mario Rossi Roma - il cane dorme.', italian, spanish, S46b),
    must('a BYLINE: of, a name, the place and a dash', S46b, 'De Mario Rossi Roma – el perro duerme.'),
    reason_translate('Ministro Rossi, il cane dorme?', italian, spanish, S46c),
    must('a TITLE AND A NAME before a comma are who is spoken to', S46c, 'Ministro Rossi, ¿el perro duerme?'),
    reason_translate('Mario Rossi, 75 anni ben portati, dorme.', italian, spanish, S46d),
    must('a COUNT set off after a name is its aside', S46d, 'Mario Rossi, 75 años bien traídos, duerme.'),
    reason_translate('I cani - precisano al ministero - per esempio quelli di Roma, mangiano il pane.', italian, spanish, S46e),
    must('an EXAMPLE after a closing dash, and who says so where, written after the sentence', S46e,
         'Los perros, por ejemplo los de Roma, comen el pan – aclaran al ministerio –.'),
    reason_translate('Sono troppi.', italian, spanish, S46f),
    must('an adjective the lesson knows ONLY IN THE PLURAL says the copula is plural too', S46f, 'Son demasiados.'),
    reason_translate('Il cane vede un gatto grande e che mangia il pane.', italian, spanish, S46g),
    must('a RELATIVE CLAUSE JOINED to what was said of an object', S46g, 'El perro ve un gato grande y que come el pan.'),
    reason_translate('Credo che il cane dorma ma non posso vederlo.', italian, spanish, S46h),
    must('a DENIAL stands before the verb it denies', S46h, 'Creo que el perro duerme pero no puedo verlo.'),
    reason_translate('Cominciano ad arrivare i cani.', italian, english, S46i),
    must('an INTRANSITIVE INFINITIVE has the phrase after it for its subject', S46i, 'The dogs begin to arrive.'),
    reason_translate('I meno ricchi dormono.', italian, spanish, S46j),
    must('the word for LESS before an adjective is its degree', S46j, 'Los menos ricos duermen.'),
    reason_translate('I meno ricchi dormono.', italian, english, S46k),
    must('and English writes least', S46k, 'The least rich sleep.'),
    reason_translate('Il cane ha l''aria di chi dorme.', italian, spanish, S46l),
    must('CHI after a preposition is the one who', S46l, 'El perro tiene el aire del que duerme.'),
    reason_translate('Il problema è che mentre il cane dorme noi mangiamo.', italian, spanish, S46m),
    must('a subordinate clause at the head of a CLAUSE OF CHE, and noi is we', S46m,
         'El problema es que mientras el perro duerme nosotros comemos.'),
    reason_translate('Può essere grande la casa del cane.', italian, english, S46n),
    must('a MODAL AND THE COPULA''S INFINITIVE, and the phrase after the predicate is the subject', S46n, 'The house of the dog can be big.'),
    reason_unlearn(spanish), reason_unlearn(italian).

%% each lesson in two parts, as the case has it, because together they come
%% near the page a stored clause must fit in
lesson_46(L, Text) :- lesson_46(L, 1, A), lesson_46(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_46(spanish, 1, 'Spanish is a language.
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

lesson_46(spanish, 2, 'The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "coma" is the subjunctive of "come".
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

lesson_46(italian, 1, 'Italian is a language.
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

lesson_46(italian, 2, 'The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangi" is the subjunctive of "mangia".
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

section_47 :-
    format("~n47. A Spanish report into Italian: an ordinal, a list whose items have phrases of their own, parts set off by semicolons, a heading with all, both ... and, there was after an insertion, a quotation that opens on a participle, two bare plurals joined, all before a bare plural, titles in a bracket, even, a time with its own infinitive, a demonstrative's apocope, an elision by the last word of several~n", []),
    lesson_47(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_47(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('El perro celebra el 50º aniversario.', spanish, italian, S47a),
    must('an ORDINAL is one word with its sign', S47a, 'Il cane celebra il 50º anniversario.'),
    reason_translate('El perro celebra el 50º aniversario.', spanish, english, S47b),
    must('and English writes its own suffix', S47b, 'The dog celebrates the 50th anniversary.'),
    reason_translate('Estrellas de hoy, políticos de ese centro, deportistas y artistas se reunieron.', spanish, italian, S47c),
    must('a LIST whose items have phrases of their own keeps its commas', S47c, 'Stelle d''oggi, politici di quel centro, sportivi e artisti si riunirono.'),
    reason_translate('El perro vio a Omar; el ministro de la casa, Juan Pérez; el gato y el hermano de Maria.', spanish, italian, S47d),
    must('PARTS SET OFF BY SEMICOLONS carry a list on', S47d, 'Il cane vide Omar; il ministro della casa, Juan Pérez; il gatto e il fratello di Maria.'),
    reason_translate('Toda una proeza, tanto por el pan como por el queso.', spanish, english, S47e),
    must('a HEADING WITH ALL, and BOTH ... AND by the partner the lesson names', S47e, 'All an exploit, both for the bread and for the cheese.'),
    reason_translate('Hubo, sin embargo, un desliz.', spanish, italian, S47f),
    must('THERE WAS after an insertion between two commas', S47f, 'C''era, però, una scivolata.'),
    reason_translate('El ministro aseguró que los perros están "preparados para la casa".', spanish, italian, S47g),
    must('a QUOTATION THAT OPENS ON A PARTICIPLE keeps its mark there', S47g, 'Il ministro assicurò che i cani sono "preparati per la casa".'),
    reason_translate('Voces de un ayer que marcó época y estrellas de las ondas se reunieron.', spanish, italian, S47h),
    must('TWO BARE PLURALS JOINED are two things', S47h, 'Voci d''un ieri che fece epoca e stelle delle onde si riunirono.'),
    reason_translate('El perro viene desde todas direcciones.', spanish, italian, S47i),
    must('ALL BEFORE A BARE PLURAL is the phrase''s', S47i, 'Il cane viene da tutte direzioni.'),
    reason_translate('El perro canta canciones (De España para todos, Elena Francis, Fantasía...) y hasta anuncios (Telefunken, La Lechera).', spanish, italian, S47j),
    must('TITLES IN A BRACKET as they stood, and EVEN', S47j, 'Il cane canta canzoni (De España para todos, Elena Francis, Fantasía...) e persino annunci (Telefunken, La Lechera).'),
    reason_translate('Fue el momento de homenajear a dos personajes, Omar y Juan.', spanish, italian, S47k),
    must('a TIME WITH ITS OWN INFINITIVE is a thing named', S47k, 'Fu il momento d''onorare due personaggi, Omar e Juan.'),
    reason_translate('El perro come ese medio pan.', spanish, italian, S47l),
    must('a DEMONSTRATIVE''S APOCOPE where the article has one', S47l, 'Il cane mangia quel mezzo pane.'),
    reason_translate('El perro duerme además del amigo.', spanish, italian, S47m),
    must('an ELISION BY THE LAST WORD of several', S47m, 'Il cane dorme oltre all''amico.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_47(L, Text) :- lesson_47(L, 1, A), lesson_47(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_47(spanish, 1, 'Spanish is a language.
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

lesson_47(spanish, 2, 'The adverb "hoy" means "today". The adverb "ayer" means "yesterday". The masculine noun "ayer" means "yesterday". "ayer" is a time.
The intransitive verb "marca época" means "makes history". "marcó época" is the past of "marca época".
The preposition "hasta" means "until". The adverb "hasta" means "even". The adverb "sin embargo" means "however". The adverb "también" means "also".
The conjunction "tanto" means "both". "como" is the partner of "tanto".
The preposition "como" means "like". The preposition "además de" means "besides". The preposition "así como" means "just like".
The masculine pronoun "éste" means "this". The pronoun "éste" does not precede the verb.
The feminine pronoun "toda" means "everything". "todas" is the plural of "toda". The pronoun "toda" does not precede the verb.
The masculine pronoun "todo" means "all". The feminine pronoun "toda" means "all".
The pronoun "otros muchos" means "many others". The pronoun "otros muchos" does not precede the verb. "otros muchos" is a person.
The demonstrative "ese" means "that". "esos" is the plural of "ese". The adjective "medio" means "half".
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
The auxiliary "está" means "is". "están" is the plural of "está". The auxiliary "está" marks the state.
The verb "hay" means "there is". "hay" is the plural of "hay". "había" is the past of "hay". "hubo" is the past of "hay".
The conjunction "y" means "and". The conjunction "o" means "or". The conjunction "que" means "that". "que" is a relative.
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "con" means "with".
The preposition "por" means "for". The preposition "desde" means "from". The word "para" begins the purpose. The preposition "para" means "for".
The intransitive verb "para" means "stops". The verb "para" means "stops".
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".
The number "dos" means "two".').

lesson_47(italian, 1, 'Italian is a language.
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

lesson_47(italian, 2, 'The adverb "oggi" means "today". The adverb "ieri" means "yesterday". The masculine noun "ieri" means "yesterday". "ieri" is a time.
The intransitive verb "fa epoca" means "makes history". "fece epoca" is the past of "fa epoca".
The adverb "persino" means "even". The preposition "fino a" means "until". The adverb "però" means "however". The adverb "anche" means "also".
The conjunction "tanto" means "both". "quanto" is the partner of "tanto".
The preposition "come" means "like". The preposition "oltre a" means "besides". The preposition "così come" means "just like".
The pronoun "questo" means "this". The pronoun "questo" does not precede the verb. "quest''" is the elision of "questo".
The feminine pronoun "tutta" means "everything". "tutte" is the plural of "tutta". The pronoun "tutta" does not precede the verb.
The masculine pronoun "tutto" means "all". The feminine pronoun "tutta" means "all".
The pronoun "molti altri" means "many others". The pronoun "molti altri" does not precede the verb.
The demonstrative "quello" means "that". "quel" is the apocope of "quello". "quei" is the plural of "quel". The adjective "mezzo" means "half".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangiò" is the past of "mangia". "mangiarono" is the past of "mangiano".
The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormì" is the past of "dorme". "dormirono" is the past of "dormono".
The verb "vede" means "sees". "vedono" is the plural of "vede". "vide" is the past of "vede". "vedere" is the infinitive of "vede".
The verb "viene" means "comes". The verb "celebra" means "celebrates". "celebrare" is the infinitive of "celebra".
The verb "canta" means "sings". The verb "rappresenta" means "represents". "rappresentano" is the plural of "rappresenta".
The verb "onora" means "honours". "onorare" is the infinitive of "onora".
The verb "riunisce" means "gathers". "riuniscono" is the plural of "riunisce". "riunì" is the past of "riunisce". "riunirono" is the past of "riuniscono".
The verb "assicura" means "ensures". "assicurò" is the past of "assicura". "assicura" takes the clause.
The verb "prepara" means "prepares". "preparato" is the participle of "prepara". "preparati" is the participle of "prepara". "preparati" is the plural of "preparato".
The verb "è" means "is". "sono" is the plural of "è". "fu" is the past of "è".
The verb "c''è" means "there is". "ci sono" is the plural of "c''è". "c''era" is the past of "c''è".
The conjunction "e" means "and". The conjunction "o" means "or". The conjunction "che" means "that". "che" is a relative.
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "con" means "with".
The preposition "da" means "from". The preposition "per" means "for". The word "per" begins the purpose.
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".
The number "due" means "two".').


section_48 :-
    format("~n48. An Italian report into Spanish: a byline, a name in quotation marks, adjectives after their noun, a name at the end of a clause and between two clauses, a degree adverb before a participle, the gender a subject does not give, an intensified adjective alone, why, what after a verb that takes the question, not only ... but, a comparison of infinitives, as when, so much before a noun~n", []),
    lesson_48(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_48(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Di Massimo Lugli Roma - il cane dorme.', italian, spanish, S48a),
    must('a BYLINE: every capitalised word between `of'' and the place is the name', S48a, 'De Massimo Lugli Roma – el perro duerme.'),
    reason_translate('Il cane mangia al "Gemelli".', italian, spanish, S48b),
    must('a capitalised word IN QUOTATION MARKS where no sentence begins is a name', S48b, 'El perro come al "Gemelli".'),
    reason_translate('È un uomo alto, snello, scuro.', italian, spanish, S48c),
    must('ADJECTIVES AFTER THEIR NOUN with commas between them', S48c, 'Es un hombre alto, esbelto, oscuro.'),
    reason_translate('Non chiede il pane, Carolyn.', italian, spanish, S48d),
    must('a NAME AFTER THE LAST COMMA of a clause is its subject', S48d, 'No pide el pan, Carolyn.'),
    reason_translate('Fruga nella casa, Carolyn, mangia il pane.', italian, english, S48e),
    must('a NAME BETWEEN TWO CLAUSES is the subject of both', S48e, 'Carolyn rummages in the house, eats the bread.'),
    reason_translate('È stata molto amata.', italian, spanish, S48f),
    must('a DEGREE ADVERB before the participle, and the GENDER the participle gives a subject that gives none', S48f, 'Ha sido muy amada.'),
    reason_translate('Così bella.', italian, spanish, S48g),
    must('an adjective WITH ITS INTENSIFIER, alone', S48g, 'Tan bella.'),
    reason_translate('Perché il cane dorme?', italian, english, S48h),
    must('WHY, the question word the lesson names', S48h, 'Why does the dog sleep?'),
    reason_translate('Certo che ha capito cos''è successo.', italian, spanish, S48i),
    must('WHAT after a verb that takes the question, and OF COURSE', S48i, 'Claro que ha entendido qué ha pasado.'),
    reason_translate('Non solo il cane ma anche il gatto dorme.', italian, spanish, S48j),
    must('NOT ONLY ... BUT, with the partner the lesson names', S48j, 'No sólo el perro sino también el gato duerme.'),
    reason_translate('I cani sono più occupati a mangiare il pane che a guardare il gatto.', italian, english, S48k),
    must('a COMPARISON OF INFINITIVES', S48k, 'The dogs are more occupied to eat the bread than to watch the cat.'),
    reason_translate('È come quando mangi il pane.', italian, spanish, S48l),
    must('AS WHEN', S48l, 'Es como cuando comes el pan.'),
    reason_translate('La donna ha tanto coraggio.', italian, spanish, S48m),
    must('SO MUCH before a noun', S48m, 'La mujer tiene tanto coraje.'),
    reason_translate('Se ci sarà una causa non voglio una lira.', italian, spanish, S48n),
    must('THERE IS has nobody for its subject, and the main clause opens on its denial', S48n, 'Si habrá una causa no quiero una lira.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_48(L, Text) :- lesson_48(L, 1, A), lesson_48(L, 2, B), lesson_48(L, 3, C), atomic_list_concat([A, ' ', B, ' ', C], Text).

lesson_48(spanish, 1, 'Spanish is a language.
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

lesson_48(spanish, 2, 'The masculine adjective "alto" means "tall". The masculine adjective "esbelto" means "slender". The masculine adjective "oscuro" means "dark".
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
The conjunction "claro que" means "of course". The conjunction "así que" means "so".
The word "cuándo" means "when". The conjunction "cuando" means "when". The word "cómo" means "how". The preposition "como" means "as".
The pronoun "yo" means "I". The pronoun "él" means "he". The pronoun "él" means "him". The pronoun "él" does not precede the verb.
The pronoun "ellos" means "they". The pronoun "ellos" does not precede the verb.
The pronoun "todos" means "everyone". "todos" is the plural of "todo". The pronoun "todos" does not precede the verb.
The pronoun "nadie" means "nobody". The pronoun "nadie" does not precede the verb.
The pronoun "lo" means "him". The pronoun "lo" means "it".
The impersonal pronoun "se" means "one". The reflexive pronoun "se" means "itself".
The preposition "a" means "to". The preposition "de" means "of". The preposition "en" means "in". The preposition "desde" means "from".
The preposition "por" means "by". The preposition "para" means "for". The preposition "contra" means "against". The preposition "sobre" means "on".').

lesson_48(spanish, 3, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
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

lesson_48(italian, 1, 'Italian is a language.
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

lesson_48(italian, 2, 'The masculine noun "alto" means "height". The masculine adjective "alto" means "tall". The adverb "alto" means "high". The masculine adjective "snello" means "slender". The masculine adjective "scuro" means "dark".
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
The conjunction "certo che" means "of course". The conjunction "per cui" means "so".
The word "quando" means "when". The word "come" means "how". The preposition "come" means "as".
The word "cosa" means "what". The feminine noun "cosa" means "thing".
The pronoun "io" means "I". The pronoun "lui" means "he". The pronoun "lui" means "him". The pronoun "lui" does not precede the verb.
The pronoun "loro" means "they". The pronoun "loro" means "them". The pronoun "loro" does not precede the verb. The dative pronoun "loro" means "them".
The pronoun "tutti" means "everyone". "tutti" is the plural of "tutto". The pronoun "tutti" does not precede the verb.
The pronoun "nessuno" means "nobody". The pronoun "nessuno" does not precede the verb.
The pronoun "lo" means "him". The pronoun "lo" means "it". The dative pronoun "le" means "her".
The reflexive pronoun "si" means "itself". The impersonal pronoun "si" means "one".
The preposition "a" means "to". The preposition "di" means "of". The preposition "in" means "in". The preposition "da" means "from".
The preposition "da" means "by". The preposition "per" means "for". The preposition "su" means "on". The word "per" begins the purpose.').

lesson_48(italian, 3, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
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


section_49 :-
    format("~n49. A Spanish report into Italian: the last clause a coordinator follows, a second person at the head spelled like a noun's plural, a clitic after a preposition, a time clause with no comma before the main clause's pronouns, the word for very before an adjective that is a noun too, the accident, a modal before a perfect infinitive, the copula after a denial, a verb's plural that is no participle's, a comma after a coordinator, a plural's own gender~n", []),
    lesson_49(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_49(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Al inicio, cuando el perro duerme, el gato aparece y desaparece.', spanish, english, S49a),
    must('the statement a coordinator follows is the LAST CLAUSE of what went before, and no command', S49a, 'To the beginning, when the dog sleeps, the cat appears and disappears.'),
    reason_translate('Diferencias en el plano son errores.', spanish, english, S49b),
    must('a SECOND PERSON AT THE HEAD spelled like a noun''s plural is tried last', S49b, 'Differences in the plane are errors.'),
    reason_translate('Compras pan.', spanish, english, S49c),
    must('and where nothing later reads, it is the verb', S49c, 'You buy bread.'),
    reason_translate('En la siguiente toma, cuando el perro duerme, el gato come.', spanish, italian, S49d),
    must('a CLITIC is never a preposition''s object, and a front never ends between an article''s adjective and its noun', S49d, 'Nella seguente presa, quando il cane dorme, il gatto mangia.'),
    reason_translate('Cuando el perro duerme se ve un gato.', spanish, english, S49e),
    must('a TIME CLAUSE WITH NO COMMA before a main clause that opens on its pronouns', S49e, 'When the dog sleeps one sees a cat.'),
    reason_translate('El altísimo Gandalf duerme.', spanish, italian, S49f),
    must('the word for VERY before a word that is an adjective too says it is one', S49f, 'Il molto alto Gandalf dorme.'),
    reason_translate('El perro ve el pan que se les olvidó.', spanish, english, S49g),
    must('THE ACCIDENT: `"olvida" takes the accident.'', and the dative is the subject', S49g, 'The dog sees the bread that they forgot.'),
    reason_translate('Los perros debían haber comido el pan.', spanish, english, S49h),
    must('a MODAL before a perfect infinitive, and must''s past', S49h, 'The dogs had to have eaten the bread.'),
    reason_translate('Las piedras pesan muy poco y no son reales.', spanish, english, S49i),
    must('THE COPULA AFTER A DENIAL, a noun too or not', S49i, 'The stones weigh very little and are not real.'),
    reason_translate('Las piedras pesan poco.', spanish, italian, S49j),
    must('a verb''s plural is NO PARTICIPLE''S', S49j, 'Le pietre pesano poco.'),
    reason_translate('El perro duerme pero, sorprendentemente, el gato no come el pan.', spanish, italian, S49k),
    must('A COMMA AFTER A COORDINATOR, the source''s', S49k, 'Il cane dorme ma, sorprendentemente, il gatto non mangia il pane.'),
    reason_translate('El perro levanta los brazos izquierdos.', spanish, italian, S49l),
    must('a PLURAL THE LESSON SAYS IS FEMININE gives its phrase the gender', S49l, 'Il cane alza le braccia sinistre.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_49(L, Text) :- lesson_49(L, 1, A), lesson_49(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_49(spanish, 1, 'Spanish is a language.
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

lesson_49(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
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

lesson_49(italian, 1, 'Italian is a language.
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
"sinistri" is the plural of "sinistro". "sinistre" is the plural of "sinistra".').

lesson_49(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "è" means "is". "sono" is the plural of "è".
The verb "appare" means "appears". The verb "scompare" means "disappears".
The verb "pende" means "hangs". "pesa" is the participle of "pende". "pesa" is feminine.
"pese" is the participle of "pende". "pese" is feminine. "pese" is the plural of "pesa".
The verb "pesa" means "weighs". "pesano" is the plural of "pesa".
The verb "dimentica" means "forgets". "dimenticano" is the plural of "dimentica".
"dimenticò" is the past of "dimentica". "dimenticarono" is the past of "dimenticano".
The verb "alza" means "raises". "alzano" is the plural of "alza".').

section_50 :-
    format("~n50. An Italian report into Spanish: an abbreviation and a number, a quotation in the plain mark with a reporting clause between dashes, a name before a colon, letters spaced out, which as an indirect question, a participle with its reflexive joined, a pronoun after a preposition in a subject, an accusative pronoun and the subject after its verb, a quotation that opens on an adjunct the writer moves, a quotation that closes at its comma, a condition before a relative clause's verb, a heading's phrase before a clause of since, the parties, a noun's plural that spells no verb's, a comment between two commas that says nothing, a name with its of left out, an impersonal modal, an adjective before an of phrase, a perfect's participles that never agree, an ordinal, two bare nouns, a closing mark that begins no clause, a participle in the form the source gave, the object a verb's sense counts~n", []),
    lesson_50(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_50(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Il cane vede l''art. 111.', italian, spanish, S50a),
    must('a point after an ABBREVIATION and before a number ends no sentence', S50a, 'El perro ve el artículo 111.'),
    reason_translate('"Il cane dorme - aggiunge Maria - e il gatto mangia il pane".', italian, spanish, S50b),
    must('a whole sentence in the PLAIN MARK with a reporting clause between dashes, which stays between its two clauses (1.8.29)', S50b, '"El perro duerme – añade Maria – y el gato come el pan".'),
    reason_translate('Maria: "Il cane dorme".', italian, spanish, S50c),
    must('a NAME ALONE BEFORE A COLON is who speaks', S50c, 'Maria: "El perro duerme".'),
    reason_translate('Il c s m dorme.', italian, spanish, S50d),
    must('LETTERS SPACED OUT are an acronym', S50d, 'El CSM duerme.'),
    reason_translate('Appare inspiegabile quali possano essere i motivi.', italian, spanish, S50e),
    must('WHICH by itself is an indirect question and a pronoun', S50e, 'Aparece inexplicable cuáles pueden ser los motivos.'),
    reason_translate('Il cane vede in quali case il gatto dorme.', italian, spanish, S50f),
    must('WHICH with its noun and the preposition before it', S50f, 'El perro ve en qué casas el gato duerme.'),
    reason_translate('Il cane lavatosi dorme.', italian, spanish, S50g),
    must('a participle carries the reflexive joined to it, read and not written', S50g, 'El perro lavado duerme.'),
    reason_translate('I cani visti da noi dormono.', italian, spanish, S50h),
    must('a pronoun right after a preposition is that preposition''s object, and no clitic', S50h, 'Los perros vistos por nosotros duermen.'),
    reason_translate('Lo annuncia un comunicato.', italian, english, S50i),
    must('an object pronoun that is no dative is the verb''s direct object: the SUBJECT AFTER ITS VERB', S50i, 'A communique announces it.'),
    reason_translate('Il cane dice che "nella casa il gatto dorme".', italian, spanish, S50j),
    must('a QUOTATION THAT OPENS ON AN ADJUNCT the writer moves is the clause''s', S50j, 'El perro dice que "el gato duerme en la casa".'),
    reason_translate('"Il cane dorme, vista la casa", ha detto.', italian, spanish, S50k),
    must('a QUOTATION THAT CLOSES AT ITS COMMA with no speaker named', S50k, '"El perro duerme, vista la casa", ha dicho.'),
    reason_translate('Il cane vede la casa, che se il gatto dorme, mangia il pane.', italian, spanish, S50l),
    must('a CONDITION before a relative clause''s verb', S50l, 'El perro ve la casa, que si el gato duerme, come el pan.'),
    reason_translate('Una buona notizia, visto che il cane dorme.', italian, spanish, S50m),
    must('a heading''s phrase before a clause of SINCE', S50m, 'Una buena noticia, ya que el perro duerme.'),
    reason_translate('Le parti dormono.', italian, spanish, S50n),
    must('a form that is the plural of two takes the one whose GENDER is the determiner''s', S50n, 'Las partes duermen.'),
    reason_translate('Modifiche al codice.', italian, spanish, S50o),
    must('a NOUN''S PLURAL is no verb''s where the verb has one of its own', S50o, 'Modificaciones al código.'),
    reason_translate('Il cane, dorme la casa, mangia il pane.', italian, spanish, S50p),
    must('a COMMENT BETWEEN TWO COMMAS reports only when a verb of saying or a person does', S50p, 'El perro, duerme la casa, come el pan.'),
    reason_translate('Secondo l''associazione nazionale magistrati, il cane dorme.', italian, spanish, S50q),
    must('the tail of a NAME with its `of'' left out is one phrase: a plural noun the lesson calls a person after a noun and its adjective', S50q, 'Según la asociación nacional magistrados, el perro duerme.'),
    reason_translate('Secondo il cane bisogna mangiare il pane.', italian, spanish, S50r),
    must('an IMPERSONAL MODAL has nobody for its subject, and a front stays a front', S50r, 'Hay que comer el pan según el perro.'),
    reason_translate('Un aumento certo dei tempi.', italian, spanish, S50s),
    must('an adjective before an `of'' phrase is the noun''s, and no adverb', S50s, 'Un aumento cierto de los tiempos.'),
    reason_translate('La casa ha mangiato, dormito.', italian, spanish, S50t),
    must('a participle after the comma of a perfect clause is the perfect''s and never agrees', S50t, 'La casa ha comido, dormido.'),
    reason_translate('Il cane vede l''articolo 74, primo codice.', italian, spanish, S50u),
    must('an ORDINAL before a noun it agrees with is the noun''s adjective, and `primo'' is the adverb `first'' as well', S50u, 'El perro ve el artículo 74, primer código.'),
    reason_translate('Il cane vede legge codice.', italian, spanish, S50v),
    must('TWO BARE NOUNS are a compound, the second after the first as it stood: a headline''s', S50v, 'El perro ve ley código.'),
    reason_translate('Il cane mangia "pane tra cane e gatto" e il gatto dorme.', italian, english, S50w),
    must('a word that CLOSES A QUOTATION begins no clause', S50w, 'The dog eats "bread among dog and cat" and the cat sleeps.'),
    reason_translate('Il cane ha visto la casa dei gatti, lavata.', italian, spanish, S50x),
    must('a participle after the comma of a perfect clause takes the FORM THE SOURCE GAVE IT where that is not the masculine singular', S50x, 'El perro ha visto la casa de los gatos, lavada.'),
    reason_translate('Il cane ritorna nella casa, e il pane.', italian, spanish, S50y),
    must('the OBJECT a verb''s sense counts is the verb''s own: a phrase after a coordinator is the conjunct of the complement before it, `regresa'' and not `devuelve''', S50y, 'El perro regresa en la casa, y el pan.'),
    reason_translate('Il cane ritorna il pane.', italian, spanish, S50z),
    must('... and an object of its own takes the sense that takes one', S50z, 'El perro devuelve el pan.'),
    reason_translate('Il cane ritorna a mangiare il pane.', italian, spanish, S50zz),
    must('... and no object AFTER AN INFINITIVE is the verb''s, it is the infinitive''s: `torna ad affilare gli artigli'' goes back to sharpen the claws', S50zz, 'El perro regresa a comer el pan.'),
    reason_translate('Bisognerà mangiare il pane.', italian, english, S50zy),
    must('ENGLISH HAS NO FUTURE OF `must'', and `will have to'' says it', S50zy, 'One will have to eat the bread.'),
    reason_translate('Il cane dorme e "anche il gatto mangia".', italian, spanish, S50zx),
    must('a quotation that opens on an adverb the reader LIFTS OUT is the clause''s: the marks stand round all the clause writes, the adverb after the verb inside them', S50zx, 'El perro duerme y "el gato come también".'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_50(L, Text) :- lesson_50(L, 1, A), lesson_50(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_50(spanish, 1, 'Spanish is a language.
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

lesson_50(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme".
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

lesson_50(italian, 1, 'Italian is a language.
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

lesson_50(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme".
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

section_51 :-
    format("~n51. A Spanish report into Italian: a phrase whose noun was left out after the indefinite article, more than before an adjective, after, a relative clause whose article says which noun it hangs on, a subject's relative clause set off by commas, the agent after a copula's infinitive, quotation marks on a purpose, a preposition's infinitive, a gerund, a participle and an elided article, a clause with its que left out, both ... and with a pronoun, half of which between dashes, the person a relative clause is about, a purpose after a phrase, a verb of two words in the future~n", []),
    lesson_51(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_51(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('El perro ve dos casas, una para cada gato.', spanish, italian, S51a),
    must('the INDEFINITE ARTICLE WITH ITS NOUN LEFT OUT and a preposition after it is a phrase', S51a, 'Il cane vede due case, una per ogni gatto.'),
    reason_translate('En el más que probable caso, el perro duerme.', spanish, english, S51b),
    must('MORE THAN before an adjective is the adjective''s', S51b, 'In the more than probable case, the dog sleeps.'),
    reason_translate('El perro duerme después de que el gato come el pan.', spanish, italian, S51c),
    must('AFTER, a conjunction of three words the lesson states', S51c, 'Il cane dorme dopo che il gatto mangia il pane.'),
    reason_translate('El perro envía una carta a los gatos en la que el pan duerme.', spanish, italian, S51d),
    must('a relative clause whose ARTICLE is not the nearest noun''s number hangs on the noun before', S51d, 'Il cane invia una lettera ai gatti in cui il pane dorme.'),
    reason_translate('El perro, que come el pan, duerme.', spanish, italian, S51e),
    must('a SUBJECT''S RELATIVE CLAUSE SET OFF BY COMMAS keeps them', S51e, 'Il cane, che mangia il pane, dorme.'),
    reason_translate('El pan debe ser comido por el perro.', spanish, italian, S51f),
    must('a copula''s INFINITIVE and a participle are a passive, and `por'' after them its AGENT', S51f, 'Il pane deve essere mangiato dal cane.'),
    reason_translate('El perro come el pan "para dormir".', spanish, italian, S51g),
    must('a QUOTATION ON A PURPOSE opens on its word and closes on its infinitive', S51g, 'Il cane mangia il pane "per dormire".'),
    reason_translate('El perro está "comiendo" el pan.', spanish, italian, S51h),
    must('... and on a progressive''s GERUND', S51h, 'Il cane sta "mangiando" il pane.'),
    reason_translate('La "única casa" duerme.', spanish, italian, S51i),
    must('an ELIDED ARTICLE before a word that opens a quotation keeps the mark between them', S51i, 'L''"unica casa" dorme.'),
    reason_translate('Maria agrega el perro duerme.', spanish, italian, S51j),
    must('a clause with its QUE LEFT OUT after a verb the lesson says takes the clause', S51j, 'Maria aggiunge che il cane dorme.'),
    reason_translate('Tanto él como el gato duermen.', spanish, english, S51k),
    must('BOTH ... AND with a pronoun that stands alone', S51k, 'Both he and the cat sleep.'),
    reason_translate('Los perros - - la mitad de los cuales duermen - - comen el pan.', spanish, italian, S51l),
    must('HALF OF WHICH between dashes: the relative takes the article of the noun it stands for', S51l, 'I cani – la metà dei quali dormono – mangiano il pane.'),
    reason_translate('Maria, a quien el perro ve, duerme.', spanish, italian, S51m),
    must('the PERSON A RELATIVE CLAUSE IS ABOUT, where the clause has a subject and no object of its own', S51m, 'Maria, che il cane vede, dorme.'),
    reason_translate('El perro come con el gato con el fin de dormir.', spanish, italian, S51n),
    must('a PURPOSE WORD OF SEVERAL WORDS after a phrase ends the phrase', S51n, 'Il cane mangia con il gatto per dormire.'),
    reason_translate('El perro informará el pan.', spanish, italian, S51o),
    must('a VERB OF SEVERAL WORDS is made by its first word', S51o, 'Il cane farà sapere il pane.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_51(L, Text) :- lesson_51(L, 1, A), lesson_51(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_51(spanish, 1, 'Spanish is a language.
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

lesson_51(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
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
The verb "informa" means "reports". "informará" is the future of "informa".').

lesson_51(italian, 1, 'Italian is a language.
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

lesson_51(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
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
The verb "fa" means "makes". "farà" is the future of "fa". The verb "fa sapere" means "reports".').

section_52 :-
    format("~n52. An Italian report into Spanish: an article with its capital begins a name, a quoted title after a phrase, a mark with its blank on the wrong side, a phrase set off after a phrase, an agent with its relative clause, a quotation on a relative word, a relative clause whose gap is in a clause the verb takes, the agent before its participle, a reporting clause between dashes or between two quotations, a time in a front, a front outside a list, a count with a comma, a subject after its verb with its of phrases, a name before an adjective, a noun's meaning, a time after by, a modal with an adverb, a headline with a noun spelled like a command~n", []),
    lesson_52(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the report''s shapes, under its own name', NI),
    lesson_52(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('Il cane dorme nell''università La Sapienza.', italian, spanish, S52a),
    must('an ARTICLE WITH ITS CAPITAL after a noun begins a name', S52a, 'El perro duerme en la universidad La Sapienza.'),
    reason_translate('Il cane dorme sul tema "spazio al tuo futuro".', italian, spanish, S52b),
    must('a QUOTED TITLE after a phrase is the phrase''s, written after it', S52b, 'El perro duerme en el tema "espacio a tu futuro".'),
    reason_translate('Il cane dorme sul tema" spazio al tuo futuro "".', italian, spanish, S52c),
    must('a plain mark whose BLANK STANDS ON THE WRONG SIDE opens the title', S52c, 'El perro duerme en el tema "espacio a tu futuro"".'),
    reason_translate('Il cane dorme con il gatto, il primo del genere, che mangia il pane.', italian, spanish, S52d),
    must('a phrase with an article SET OFF AFTER A PHRASE, a relative clause after its comma', S52d, 'El perro duerme con el gato, el primero del género, que come el pan.'),
    reason_translate('Il cane mangia il pane offerto dal gatto, che dorme.', italian, english, S52e),
    must('an AGENT keeps the relative clause after its comma', S52e, 'The dog eats the bread offered by the cat, which sleeps.'),
    reason_translate('Il cane vede la casa, "che è grande".', italian, spanish, S52f),
    must('a quotation that opens on a RELATIVE WORD keeps its mark', S52f, 'El perro ve la casa, "que es grande".'),
    reason_translate('Il cane vede la casa, che spero sia grande.', italian, english, S52g),
    must('a relative clause whose gap is the subject of a CLAUSE THE VERB TAKES', S52g, 'The dog sees the house, which I hope is big.'),
    reason_translate('Il cane vede la tuta da lui usata.', italian, spanish, S52h),
    must('the AGENT BEFORE ITS PARTICIPLE', S52h, 'El perro ve el traje usado por él.'),
    reason_translate('Il cane dorme - dice Maria - il gatto mangia il pane.', italian, spanish, S52i),
    must('a REPORTING CLAUSE BETWEEN DASHES, between two clauses, stays where it stood', S52i, 'El perro duerme – dice Maria – el gato come el pan.'),
    reason_translate('"Il cane dorme", dice Maria, "il gatto mangia il pane".', italian, english, S52j),
    must('... and one BETWEEN TWO QUOTATIONS', S52j, '"The dog sleeps", Maria says, "the cat eats the bread".'),
    reason_translate('A questo scopo il prossimo febbraio, il cane mangia il pane.', italian, spanish, S52k),
    must('a TIME anywhere in a front is when', S52k, 'A este objetivo el próximo febrero, el perro come el pan.'),
    reason_translate('Nel corso il cane dorme sulla casa, sulla tavola e sul libro.', italian, spanish, S52l),
    must('a FRONT goes after the clause and never into a LIST', S52l, 'El perro duerme en la casa, en la mesa y en el libro en el curso.'),
    reason_translate('Il cane mangia altri due, tre pani.', italian, spanish, S52m),
    must('a COUNT with a comma between its numbers', S52m, 'El perro come otros dos, tres panes.'),
    reason_translate('In Europa esiste un centro di addestramento.', italian, spanish, S52n),
    must('the SUBJECT AFTER AN INTRANSITIVE VERB keeps its of phrases', S52n, 'Un centro de entrenamiento existe en Europa.'),
    reason_translate('Roma potrebbe diventare la Houston italiana.', italian, spanish, S52o),
    must('a NAME before an adjective is the head, and a COPULA takes no word before a person', S52o, 'Roma podría llegar a ser la Houston italiana.'),
    reason_translate('Il cane vede l''aeronautica militare.', italian, english, S52p),
    must('a noun keeps its NOUN''S MEANING, and a person heads only what agrees with it', S52p, 'The dog sees the military aeronautics.'),
    reason_translate('Il pane sarà mangiato dal prossimo anno.', italian, spanish, S52q),
    must('a TIME after the word for by is when, never the agent', S52q, 'El pan será comido desde el próximo año.'),
    reason_translate('Il cane deve poi mangiare il pane.', italian, english, S52r),
    must('a MODAL with an adverb before its infinitive', S52r, 'The dog must eat the bread then.'),
    reason_translate('Con Vittori laurea in astronautica.', italian, spanish, S52s),
    must('a HEADLINE of a name and a bare noun spelled like a COMMAND', S52s, 'Con Vittori grado en astronáutica.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_52(L, Text) :- lesson_52(L, 1, A), lesson_52(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_52(italian, 1, 'Italian is a language.
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

lesson_52(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
"mangiato" is the participle of "mangia". "mangerà" is the future of "mangia".
The verb "vede" means "sees". "vedono" is the plural of "vede".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è". "stato" is the participle of "è".
"sarà" is the future of "è". "sia" is the subjunctive of "è". "è" is the auxiliary of "è".
The auxiliary "ha" means "has". "hanno" is the plural of "ha".
The verb "deve" means "owes". The modal "deve" means "must". "devono" is the plural of "deve".
The modal "può" means "can". "possono" is the plural of "può". "potrebbe" is the conditional of "può".
The verb "dice" means "says". "dice" takes the clause.
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
The feminine noun "astronautica" means "astronautics". The feminine noun "parte" means "part".').

lesson_52(spanish, 1, 'Spanish is a language.
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

lesson_52(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
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
The feminine noun "astronáutica" means "astronautics".').

section_53 :-
    format("~n53. A Spanish report into Italian: no command after a coordinator or a lifted adverb, the word before a question, adjectives before a name, a name in small letters, a participle in front, a participle before its noun, an exclamation, whose, a heading with a name, a quotation that closes on a name, a speaker's relative clause, the word before a person and a list, a front after a whole time clause, a second aside, a subordinate clause with asides, an adverb after the predicate~n", []),
    lesson_53(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_53(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Y duerme.', spanish, italian, S53a),
    must('after a COORDINATOR at the head, no command spelled as a third person', S53a, 'E dorme.'),
    reason_translate('Sólo duerme.', spanish, italian, S53b),
    must('... nor after an ADVERB lifted from the head', S53b, 'Dorme solo.'),
    reason_translate('Y no comas el pan.', spanish, italian, S53c),
    must('... where a DENIED command stays a command', S53c, 'E non mangiare il pane.'),
    reason_translate('El perro duerme sin preguntar por quién come el pan.', spanish, italian, S53d),
    must('the word a verb puts BEFORE ITS QUESTION is the verb''s', S53d, 'Il cane dorme senza chiedere chi mangia il pane.'),
    reason_translate('La hermosa, joven y cautivadora Maria come el pan.', spanish, italian, S53e),
    must('ADJECTIVES JOINED BEFORE A NAME are one phrase with it', S53e, 'La bella, giovane e accattivante Maria mangia il pane.'),
    reason_translate('Llegaron les lions de Maria.', spanish, italian, S53f),
    must('a NAME OF SEVERAL WORDS in small letters, where the lesson says it is one', S53f, 'Arrivarono les lions di Maria.'),
    reason_translate('Ayer, liderados por un joven, los perros comen el pan.', spanish, italian, S53g),
    must('a PARTICIPLE WITH ITS AGENT in front, in the subject''s number', S53g, 'Ieri, guidati da un giovane, i cani mangiano il pane.'),
    reason_translate('Un rendido y entregado Juan come el pan.', spanish, italian, S53h),
    must('PARTICIPLES BEFORE THEIR NOUN, said of it', S53h, 'Un arreso e consegnato Juan mangia il pane.'),
    reason_translate('Menudo pan.', spanish, italian, S53i),
    must('an EXCLAMATION with no mark', S53i, 'Che pane.'),
    reason_translate('El joven cuyo perro come el pan duerme.', spanish, english, S53j),
    must('WHOSE, the determiner of a phrase in its own clause', S53j, 'The youngster whose dog eats the bread sleeps.'),
    reason_translate('JUAN RENDIDO.', spanish, italian, S53k),
    must('a HEADING IN CAPITALS with a name in it', S53k, 'Juan arreso.'),
    reason_translate('"El perro es un gran Juan", dijo ayer el gato.', spanish, english, S53l),
    must('a quotation that CLOSES ON A NAME, and its reporting clause', S53l, '"The dog is a great Juan", the cat said yesterday.'),
    reason_translate('"El perro duerme", añadió el técnico, que se mostró cansado.', spanish, italian, S53m),
    must('a SPEAKER WITH A RELATIVE CLAUSE after a comma', S53m, '"Il cane dorme", aggiunse il tecnico, che si mostrò stanco.'),
    reason_translate('El perro tiene por testigos a los técnicos y millones de personas.', spanish, italian, S53n),
    must('the WORD BEFORE A PERSON marks a LIST whose first item is one', S53n, 'Il cane ha per testimoni i tecnici e milioni di persone.'),
    reason_translate('Cuando el perro duerme, en la casa, llegaron los gatos.', spanish, italian, S53o),
    must('a FRONT after a time clause that is WHOLE at its comma', S53o, 'Quando il cane dorme, nella casa, i gatti arrivarono.'),
    reason_translate('La FIFA, convaleciente de una batalla, salpicada por la plaga, ha buscado un escenario.', spanish, italian, S53p),
    must('a participle with its agent as a SECOND ASIDE', S53p, 'La FIFA, convalescente d''una battaglia, macchiata dalla piaga, ha cercato un palcoscenico.'),
    reason_translate('Si la FIFA, convaleciente de una batalla, hubiera buscado un escenario no lo habría encontrado.', spanish, italian, S53q),
    must('a SUBORDINATE CLAUSE WITH ASIDES and no comma before its main clause', S53q, 'Se la FIFA, convalescente d''una battaglia, aveva cercato un palcoscenico non l''avrebbe trovato.'),
    reason_translate('El nombre se hará familiar muy pronto.', spanish, italian, S53r),
    must('an ADVERB that is an adjective too, after the predicate adjective', S53r, 'Il nome si farà familiare molto presto.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_53(L, Text) :- lesson_53(L, 1, A), lesson_53(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_53(spanish, 1, 'Spanish is a language.
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

lesson_53(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
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

lesson_53(italian, 1, 'Italian is a language.
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

lesson_53(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
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

section_54 :-
    format("~n54. An Italian column into Spanish: a Roman numeral, who said so between dashes, names with commas to the end, a partitive pronoun, as one thing so another, since between a subject and its verb, a front that ends on a name, a clause of che in front, an adjective for a subject, which by itself, a phrase in front taken up by a pronoun, an infinitive for a subject, ci si, a gerund cleft, not only ... but, the only ones not to, an article before an infinitive, a clause to compare with, how much, the partner of a denial~n", []),
    lesson_54(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the column''s shapes, under its own name', NI),
    lesson_54(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('Il cane dorme nel IV secolo.', italian, spanish, S54a),
    must('a ROMAN NUMERAL is a number', S54a, 'El perro duerme en el IV siglo.'),
    reason_translate('Era che - come ha mostrato il gatto - il cane dormiva.', italian, spanish, S54b),
    must('WHO SAID SO BETWEEN DASHES, written back where it stood', S54b, 'Era que – como ha mostrado el gato – el perro durmió.'),
    reason_translate('Lo sanno persino Maria, Carla, Luisa - e il cane dorme.', italian, spanish, S54c),
    must('NAMES WITH COMMAS to a dash, and no coordinator', S54c, 'Lo saben incluso Maria, Carla, Luisa – y el perro duerme.'),
    reason_translate('Il cane dorme, tanto per citarne alcuni.', italian, spanish, S54d),
    must('a PARTITIVE PRONOUN beside a quantity is said once', S54d, 'El perro duerme, para citar algunos.'),
    reason_translate('Il cane dice che, come il gatto dorme, così il topo mangia il pane.', italian, spanish, S54e),
    must('AS ONE THING, SO ANOTHER', S54e, 'El perro dice que, como el gato duerme, así el ratón come el pan.'),
    reason_translate('I due autori, siccome il gatto dorme, mangiano il pane.', italian, spanish, S54f),
    must('a CLAUSE OF SINCE set off between a subject and its verb', S54f, 'Los dos autores, ya que el gato duerme, comen el pan.'),
    reason_translate('Nel IV secolo Maria mangiava il pane.', italian, spanish, S54g),
    must('a FRONT THAT ENDS ON A NAME apposed to its noun leaves the rest its subject', S54g, 'Maria comió el pan en el IV siglo.'),
    reason_translate('Che il cane dorma, guardate che il gatto mangia il pane.', italian, spanish, S54h),
    must('a CLAUSE OF CHE IN FRONT, and a command after its comma', S54h, 'Que el perro duerme, mirad que el gato come el pan.'),
    reason_translate('Ma immobile non vuole dire piatta.', italian, english, S54i),
    must('an ADJECTIVE ALONE at the head is the subject', S54i, 'But motionless does not want to say flat.'),
    reason_translate('Quali sono i cani?', italian, spanish, S54j),
    must('WHICH by itself', S54j, '¿Cuáles son los perros?'),
    reason_translate('Ma allora chi mangia il pane?', italian, spanish, S54k),
    must('a CONNECTING ADVERB before the question word', S54k, '¿Pero entonces quién come el pan?'),
    reason_translate('Queste cose le sanno gli autori e i gatti no.', italian, english, S54l),
    must('a PHRASE IN FRONT taken up by a pronoun, and a second half with its no', S54l, 'The authors know these things and not the cats.'),
    reason_translate('È pazzesco mangiare il pane.', italian, english, S54m),
    must('an INFINITIVE is what the predicate is said of', S54m, 'To eat the bread is crazy.'),
    reason_translate('Non è mangiando il pane che ci si salva.', italian, spanish, S54n),
    must('CI SI, and a GERUND CLEFT', S54n, 'No es comiendo el pan que uno se salva.'),
    reason_translate('Lo sanno non solo Maria, ma anche Carla.', italian, english, S54o),
    must('NOT ONLY ... BUT after its verb is the subject', S54o, 'Not only Maria, but also Carla know him.'),
    reason_translate('Il cane dorme non solo nella casa ma anche nel giardino.', italian, english, S54p),
    must('not only IN ONE PLACE but in another', S54p, 'The dog sleeps not only in the house but also in the garden.'),
    reason_translate('Gli unici a non dormire sono i cani.', italian, english, S54q),
    must('THE ONLY ONES NOT TO', S54q, 'The only ones not to sleep are the dogs.'),
    reason_translate('Il mangiare è buono.', italian, spanish, S54r),
    must('an ARTICLE BEFORE AN INFINITIVE makes a noun of it', S54r, 'El comer es bueno.'),
    reason_translate('La casa è più grande di quanto il cane dice.', italian, english, S54s),
    must('a CLAUSE TO COMPARE WITH', S54s, 'The house is bigger than the dog says.'),
    reason_translate('Il cane dice quanto il gatto mangia.', italian, spanish, S54t),
    must('HOW MUCH, after a verb that takes the question', S54t, 'El perro dice cuánto el gato come.'),
    reason_translate('Le case non sono grandi bensì piccole.', italian, spanish, S54u),
    must('BUT after a denial is the partner the lesson names', S54u, 'Las casas no son grandes sino pequeñas.'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_54(L, Text) :- lesson_54(L, 1, A), lesson_54(L, 2, B), lesson_54(L, 3, C), atomic_list_concat([A, ' ', B, ' ', C], Text).

lesson_54(italian, 1, 'Italian is a language.
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

lesson_54(italian, 2, 'The adverb "allora" means "then". The adverb "poi" means "then". The adverb "quindi" means "then".
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

lesson_54(italian, 3, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormi" is the imperative of "dorme". "dormire" is the negative imperative of "dorme". "dormire" is the infinitive of "dorme". "dormiva" is the past of "dorme". "dorma" is the subjunctive of "dorme".
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

lesson_54(spanish, 1, 'Spanish is a language.
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

lesson_54(spanish, 2, 'The adverb "entonces" means "then". The adverb "precisamente" means "precisely". The adverb "también" means "also".
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

lesson_54(spanish, 3, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme". "durmió" is the past of "duerme". "duerma" is the subjunctive of "duerme".
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

section_55 :-
    format("~n55. A Spanish report into Italian: a bracket inside a pair of plain quotation marks, a quotation that opens on an infinitive after a preposition, a quotation that closes on a clause whose adverb the lift took out, not only one clause but another, a front before the clause of `that'' a verb of saying takes, a bare time, the subject of a verb of saying after it, a clause with its verb left out and its phrase `also'', a name that speaks with its relative clause, a noun that takes `to'' and an infinitive after `has'', a reflexive the source slipped on, the person told before `de que'', a purpose infinitive''s own person, a quoted adjective after a name, an infinitive with its own object, a name before a word that is a noun and a preposition~n", []),
    lesson_55(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_55(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('"El perro come el pan (la casa), como si el gato duerme", dijo el técnico.', spanish, italian, S55a),
    must('a BRACKET inside a pair of plain quotation marks is an aside of the quoted clause', S55a, '"Il cane mangia il pane (la casa), come se il gatto dorme", disse il tecnico.'),
    reason_translate('El perro va a "comer el pan".', spanish, italian, S55b),
    must('a quotation that OPENS ON THE INFINITIVE after `a'' opens there', S55b, 'Il cane va a "mangiare il pane".'),
    reason_translate('"El perro come el pan si realmente duerme", dijo el técnico.', spanish, italian, S55c),
    must('a quotation that closes on the clause''s last word closes on the last word WRITTEN, when the lift took an adverb out', S55c, '"Il cane mangia il pane se dorme realmente", disse il tecnico.'),
    reason_translate('No sólo duermen los perros, sino que comen el pan.', spanish, italian, S55d),
    must('NOT ONLY ONE CLAUSE BUT ANOTHER, the partner the lesson names for the word for `only''', S55d, 'Non solo dormono i cani, ma mangiano il pane.'),
    reason_translate('"Non solo dormono i cani, ma mangiano il pane.', italian, spanish, S55e),
    must('... and the other way, where the partner takes the word for `that'' before its clause', S55e, '"No sólo duermen los perros, sino que comen el pan.'),
    reason_translate('Tres veces negó el técnico que el gato duerme.', spanish, italian, S55f),
    must('a FRONT goes before the clause of `that'' the verb takes, and the subject of a verb of saying stands after it', S55f, 'Negò il tecnico tre volte che il gatto dorme.'),
    reason_translate('Tres veces negó el técnico que el gato duerme.', spanish, english, S55g),
    must('... and in English, where it is the coach who denies', S55g, 'The coach denied three times that the cat sleeps.'),
    reason_translate('El perro duerme tres veces.', spanish, italian, S55h),
    must('a BARE TIME takes the lesson''s word for a time', S55h, 'Il cane dorme tre volte.'),
    reason_translate('Dijo al técnico que el gato duerme.', spanish, italian, S55i),
    must('the PERSON TOLD stays the person told, and the clause is the verb''s', S55i, 'Disse al tecnico che il gatto dorme.'),
    reason_translate('El perro duerme y el gato también.', spanish, italian, S55j),
    must('a clause with its VERB LEFT OUT and its phrase `also''', S55j, 'Il cane dorme e anche il gatto.'),
    reason_translate('"El perro duerme", dijo Juan, que también come el pan.', spanish, italian, S55k),
    must('a NAME that speaks hangs its relative clause on it', S55k, '"Il cane dorme", disse Juan, che anche mangia il pane.'),
    reason_translate('Los perros tienen derecho a comer el pan.', spanish, italian, S55l),
    must('a noun that takes `to'' and an infinitive after the verb that means `has''', S55l, 'I cani hanno diritto a mangiare il pane.'),
    reason_translate('El perro duerme, como si se le hubiéramos dado el pan.', spanish, italian, S55m),
    must('a REFLEXIVE the source slipped on is read as nothing', S55m, 'Il cane dorme, come se gli avevamo dato il pane.'),
    reason_translate('El perro advierte a los técnicos de que no deben comer el pan.', spanish, italian, S55n),
    must('the person told before `de que'' and a clause whose subject is left out', S55n, 'Il cane avverte ai tecnici che non devono mangiare il pane.'),
    reason_translate('El perro ve a los técnicos que comen el pan.', spanish, italian, S55o),
    must('... where a person with a relative clause after a verb that takes none stays a relative clause', S55o, 'Il cane vede i tecnici che mangiano il pane.'),
    reason_translate('El perro recupera el pan para "retratar" a Juan.', spanish, italian, S55p),
    must('a PURPOSE infinitive''s own person is its object', S55p, 'Il cane recupera il pane per "ritrarre" Juan.'),
    reason_translate('El perro lee un libro de Juan "cansado".', spanish, italian, S55q),
    must('a name followed by a QUOTED ADJECTIVE is one phrase', S55q, 'Il cane legge un libro di Juan "stanco".'),
    reason_translate('El perro duerme para lograr el pan.', spanish, italian, S55r),
    must('an INFINITIVE WITH ITS OWN OBJECT right after it takes the verb a clause with an object takes', S55r, 'Il cane dorme per ottenere il pane.'),
    reason_translate('El perro duerme para lograr.', spanish, italian, S55s),
    must('... and with no object it keeps the verb it had', S55s, 'Il cane dorme per riuscire.'),
    reason_translate('El perro ve la casa del PNV ante el gato.', spanish, italian, S55t),
    must('a NAME after the article is no noun for the determiner before a word that is a noun and a preposition', S55t, 'Il cane vede la casa del PNV davanti al gatto.'),
    reason_translate('Ayer el perro come "el pan".', spanish, italian, S55u),
    must('an adverb the lift took out from BEFORE the mark that opens a quotation is written outside it', S55u, 'Il cane mangia "il pane" ieri.'),
    reason_translate('Ayer hay un perro "en la casa".', spanish, italian, S55v),
    must('... a `there is'' too', S55v, 'C''è un cane "nella casa" ieri.'),
    reason_translate('"Ayer hay un perro en la casa", dijo el técnico.', spanish, italian, S55w),
    must('a quotation that opens on the adverb the lift took out has it inside', S55w, '"C''è un cane nella casa ieri", disse il tecnico.'),
    reason_translate('En la casa el perro es nostálgico que come el pan.', spanish, italian, S55x),
    must('a clause with no subject of its own after a predicate adjective is a relative clause, and a front stays after it', S55x, 'Il cane è nostalgico che mangia il pane nella casa.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_55(L, Text) :- lesson_55(L, 1, A), lesson_55(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_55(spanish, 1, 'Spanish is a language.
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

lesson_55(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
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

lesson_55(italian, 1, 'Italian is a language.
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

lesson_55(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
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

section_56 :-
    format("~n56. An Italian report into Spanish: a participle or an adjective in front of its clause, a perfect infinitive after a preposition, a clause that leaves out its copula, `né'' between clauses, the state''s copula for a place, a quoted adverb after an article, a day of the week, the cleft with its copula first, an absolute phrase, a name of several words, a title before a name, `cioè'', the pronouns joined to an infinitive, a quotation split by its report, a phrase set in front and taken up by a pronoun, a preposition before `how'', an infinitive joined to another, a subjunctive after `che'', `infatti'' in front, a phrase before `there is'', a noun after its article and adjective~n", []),
    lesson_56(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the report''s shapes, under its own name', NI),
    lesson_56(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('Il cane firma il libro.', italian, spanish, S56a),
    must('a verb whose TRANSITIVE SENSE is the intransitive one''s English crosses as that sense, not the dictionary''s first meaning', S56a, 'El perro firma el libro.'),
    reason_translate('Stanco il cane.', italian, spanish, S56b),
    must('an ADJECTIVE IN FRONT of its subject, the copula left out', S56b, 'El perro es cansado.'),
    reason_translate('Il cane non mangia né dorme.', italian, spanish, S56c),
    must('`né'' between two clauses joins them as NOR', S56c, 'El perro no come ni duerme.'),
    reason_translate('Il cane è a Milano.', italian, spanish, S56d),
    must('the STATE''S COPULA says where somebody is, and a name for the place takes `en''', S56d, 'El perro está en Milano.'),
    reason_translate('Il cane dorme martedì.', italian, spanish, S56e),
    must('a DAY of the week takes the article where the lesson says so', S56e, 'El perro duerme el martes.'),
    reason_translate('Non sarà lui a dormire.', italian, spanish, S56f),
    must('the CLEFT with its copula first, the pronoun after the verb', S56f, 'No dormirá él.'),
    reason_translate('Il cane dorme e la casa come sfondo.', italian, spanish, S56g),
    must('an ABSOLUTE PHRASE after a coordinator takes the word for `with''', S56g, 'El perro duerme y con la casa como fondo.'),
    reason_translate('Il Corriere della Sera dorme.', italian, spanish, S56h),
    must('a NAME OF SEVERAL WORDS the lesson states is one word, as the text spells it', S56h, 'El Corriere della Sera duerme.'),
    reason_translate('Il Tecnico Mario Rossi dorme.', italian, spanish, S56i),
    must('a TITLE in capitals before a name is a noun', S56i, 'El técnico Mario Rossi duerme.'),
    reason_translate('Il cane spera di dormire, cioè che il gatto mangia.', italian, spanish, S56j),
    must('`cioè'' before what it says again', S56j, 'El perro espera dormir, es decir que el gato come.'),
    reason_translate('Recuperato in casa, il cane dorme.', italian, spanish, S56k),
    must('a PARTICIPLE with adjuncts only, said of the subject, is written back in front', S56k, 'Recuperado en casa, el perro duerme.'),
    reason_translate('Il cane spera di occuparmene.', italian, spanish, S56l),
    must('an infinitive with TWO PRONOUNS joined, the partitive said of nothing', S56l, 'El perro espera ocuparme.'),
    reason_translate('"Il cane" dice lui, "dorme in casa".', italian, spanish, S56m),
    must('a quotation SPLIT BY ITS REPORT, a pronoun for the report', S56m, '"El perro", dice él, "duerme en casa".'),
    reason_translate('Il timore di dormire ce l''ha.', italian, spanish, S56n),
    must('a phrase SET IN FRONT and taken up by a pronoun is the verb''s object', S56n, 'Tiene el miedo de dormir.'),
    reason_translate('Lo mangia il timore di dormire.', italian, spanish, S56o),
    must('a subject with an infinitive of its own AFTER its verb is no phrase set in front, and its pronoun stays', S56o, 'Lo come el miedo de dormir.'),
    reason_translate('Il cane della casa lo mangia.', italian, spanish, S56p),
    must('a subject with a phrase of its own that is no infinitive stays the subject before its verb and its pronoun', S56p, 'El perro de la casa lo come.'),
    reason_translate('Il cane mangia il pane di soltanto la casa.', italian, spanish, S56q),
    must('a word that says `only'' before the phrase of a preposition stays with it', S56q, 'El perro come el pan de solamente la casa.'),
    reason_translate('Dopo aver mangiato il pane, il cane dorme.', italian, spanish, S56r),
    must('a PERFECT INFINITIVE after a preposition is the auxiliary''s and a participle', S56r, 'Tras haber comido el pan, el perro duerme.'),
    reason_translate('Il cane dorme a seconda di come il gatto mangia.', italian, spanish, S56s),
    must('a PREPOSITION BEFORE `how''', S56s, 'El perro duerme según cómo el gato come.'),
    reason_translate('Il cane spera di mangiare il pane e di dormire.', italian, spanish, S56t),
    must('an infinitive after `e di'' is the verb''s OWN', S56t, 'El perro espera comer el pan y dormir.'),
    reason_translate('Lui spera che passi in casa.', italian, spanish, S56u),
    must('a second person nobody named is no SUBJUNCTIVE''S THIRD in a clause of `that''', S56u, 'Él espera que pasa en casa.'),
    reason_translate('Infatti il cane dorme.', italian, spanish, S56v),
    must('`infatti'' at the head is IN FRONT', S56v, 'De hecho el perro duerme.'),
    reason_translate('Dietro le case ci sono molti cani.', italian, spanish, S56w),
    must('a phrase before `there is'' is no SECOND THING there is', S56w, 'Hay muchos perros detrás de las casas.'),
    reason_translate('Il cane dorme, nonostante i rispettivi giochi.', italian, spanish, S56x),
    must('an article and an adjective before a word that is a noun and a verb''s form are ONE PHRASE', S56x, 'El perro duerme, a pesar de los respectivos juegos.'),
    reason_translate('E in casa, il cane dorme:', italian, spanish, S56y),
    must('a sentence that ends on a COLON is read as the piece, its connector first', S56y, 'Y en casa, el perro duerme:'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_56(L, Text) :- lesson_56(L, 1, A), lesson_56(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_56(italian, 1, 'Italian is a language.
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

lesson_56(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
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

lesson_56(spanish, 1, 'Spanish is a language.
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

lesson_56(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
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

section_57 :-
    format("~n57. A Spanish report into Italian: a word in single quotation marks, a word no lesson knows alone in marks, a first name that is a noun too, a quotation that opens on its relative word, a denial in a clause with a preposition that is a verb's form, the phrases of one preposition before `without that'~n", []),
    lesson_57(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_57(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Los ''botiguers'' duermen.', spanish, italian, S57a),
    must('a word in SINGLE quotation marks is quoted, as in double ones, and a word no lesson knows, alone in marks, is kept as it stands', S57a, 'I "botiguers" dormono.'),
    reason_translate('Los "perros" duermen.', spanish, italian, S57b),
    must('a word the lesson knows, in marks, is translated inside them', S57b, 'I "cani" dormono.'),
    reason_translate('Salvador Bellido duerme.', spanish, italian, S57c),
    must('a FIRST NAME the lesson knows for a noun and says is a name is the name, when capital words follow it', S57c, 'Salvador Bellido dorme.'),
    reason_translate('El perro tiene un monopolio "que quita el pan".', spanish, italian, S57d),
    must('a quotation that OPENS ON THE RELATIVE WORD keeps its opening mark', S57d, 'Il cane ha un monopolio "che toglie il pane".'),
    reason_translate('El técnico dijo que el pan entre el perro y el gato no es malo.', spanish, italian, S57e),
    must('a preposition that is a verb''s form too is no verb of the clause where its denial is looked for', S57e, 'Il tecnico disse che il pane tra il cane e il gatto non è cattivo.'),
    reason_translate('El técnico dijo que el pan es malo para el perro y para el gato sin que el gato coma.', spanish, italian, S57f),
    must('two phrases of ONE PREPOSITION before `without that'' are not divided at their `y''', S57f, 'Il tecnico disse che il pane è cattivo per il cane e per il gatto senza che il gatto mangia.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_57(L, Text) :- lesson_57(L, 1, A), lesson_57(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_57(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not".
The masculine noun "perro" means "dog". The masculine noun "gato" means "cat". The masculine noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The masculine noun "técnico" means "coach". "técnico" is a person.
The masculine noun "hombre" means "man". "hombre" is a person.
The masculine noun "salvador" means "rescuer". "salvador" is a name.
The masculine noun "monopolio" means "monopoly".
The masculine adjective "malo" means "bad". "malos" is the plural of "malo".
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative.
The conjunction "sin que" means "without".
The preposition "en" means "in". The preposition "de" means "of". The preposition "con" means "with". The preposition "a" means "to".
The preposition "para" means "for". The preposition "entre" means "between".').

lesson_57(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "coma" is the subjunctive of "come".
The verb "tiene" means "has". "tienen" is the plural of "tiene".
The verb "dice" means "says". "dijo" is the past of "dice".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es".
The verb "entra" means "enters". "entre" is the subjunctive of "entra". "entran" is the plural of "entra".
The verb "para" means "stops". "paran" is the plural of "para".
The verb "provoca" means "causes". "provoque" is the subjunctive of "provoca".
The verb "quita" means "removes".
"said" is the past of "says".').

lesson_57(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "del" is the contraction of "di il". "della" is the contraction of "di la".
"al" is the contraction of "a il". "ai" is the contraction of "a i".
"l''" is the elision of "lo". "l''" is the elision of "la". "d''" is the elision of "di".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The masculine noun "cane" means "dog". "cani" is the plural of "cane". The masculine noun "gatto" means "cat". "gatti" is the plural of "gatto".
The masculine noun "pane" means "bread". The feminine noun "casa" means "house". The masculine noun "tecnico" means "coach". "tecnico" is a person.
The masculine noun "uomo" means "man". "uomo" is a person.
The masculine noun "salvatore" means "rescuer".
The masculine noun "monopolio" means "monopoly".
The masculine adjective "cattivo" means "bad". "cattivi" is the plural of "cattivo".
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative.
The conjunction "senza che" means "without".
The preposition "in" means "in". The preposition "di" means "of". The preposition "con" means "with". The preposition "a" means "to".
The preposition "per" means "for". The preposition "tra" means "between".').

lesson_57(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia".
The verb "ha" means "has". "hanno" is the plural of "ha".
The verb "dice" means "says". "disse" is the past of "dice".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è".
The verb "ferma" means "stops".
The verb "provoca" means "causes".
The verb "toglie" means "removes".
"said" is the past of "says".').

section_58 :-
    format("~n58. An Italian report into Spanish: an elided article before a digit, a ratio, a compound count, a copula that agrees with what follows, the perfect with `essere' and with `avere', `senza' and an infinitive, an infinitive question, `quanti', a question after a dashed aside~n", []),
    lesson_58(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('an Italian lesson of the report''s shapes, under its own name', NI),
    lesson_58(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('and a Spanish one', NS),
    reason_translate('Un bambino su sette vive.', italian, spanish, S58a),
    must('a RATIO is one phrase, an article, a noun, `su'' and a number: `un bambino su sette'' is `uno de cada siete niños''', S58a, 'Uno de cada siete niños vive.'),
    reason_translate('Vivono 6 milioni e 458 mila poveri.', italian, spanish, S58b),
    must('a COMPOUND COUNT heads a phrase of its own, though the noun after it is an adjective in the lesson', S58b, 'Viven 6 millones y 458 mil pobres.'),
    reason_translate('Il problema sono i cani.', italian, spanish, S58c),
    must('a COPULA agrees with the phrase after it, and the subject is written first: `il problema sono i cani'' is `los perros son el problema''', S58c, 'Los perros son el problema.'),
    reason_translate('El gasto ha aumentado.', spanish, italian, S58d),
    must('the PERFECT of a verb the lesson builds with `è'' is written with it when the clause has no object', S58d, 'La spesa è aumentata.'),
    reason_translate('El gobierno ha aumentado el gasto.', spanish, italian, S58e),
    must('... and with `ha'' when it has one', S58e, 'Il governo ha aumentato la spesa.'),
    reason_translate('Senza contare che il cane dorme.', italian, spanish, S58f),
    must('`senza'' and an infinitive, with a clause of `that'' after them, make a whole piece', S58f, 'Sin contar que el perro duerme.'),
    reason_translate('Come affrontare il problema?', italian, spanish, S58g),
    must('an INFINITIVE QUESTION has its question word, the infinitive and what it takes, with no subject and no tense', S58g, '¿Cómo afrontar el problema?'),
    reason_translate('Su due case quanti sono i cani?', italian, spanish, S58h),
    must('`quanti'' asks how many, after a front that counts', S58h, '¿Cuántos son los perros sobre dos casas?'),
    reason_translate('Il cane mangia il pane - dove vive il gatto - su due case quanti sono i cani?', italian, spanish, S58i),
    must('a question after an ASIDE between dashes is the last clause''s: the first is written as a statement, and the mark opens before the question', S58i, 'El perro come el pan – donde vive el gato – ¿cuántos son los perros sobre dos casas?'),
    reason_unlearn(italian), reason_unlearn(spanish).

lesson_58(L, Text) :- lesson_58(L, 1, A), lesson_58(L, 2, B), lesson_58(L, 3, C), atomic_list_concat([A, ' ', B, ' ', C], Text).

lesson_58(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "del" is the contraction of "di il". "della" is the contraction of "di la".
"dei" is the contraction of "di i". "al" is the contraction of "a il". "ai" is the contraction of "a i". "sul" is the contraction of "su il".
"l''" is the elision of "lo". "l''" is the elision of "la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The masculine noun "cane" means "dog". "cani" is the plural of "cane". The masculine noun "gatto" means "cat". "gatti" is the plural of "gatto".
The masculine noun "pane" means "bread". The feminine noun "casa" means "house". "case" is the plural of "casa".
The masculine noun "bambino" means "child". "bambini" is the plural of "bambino".
The masculine noun "nucleo" means "household". "nuclei" is the plural of "nucleo". The feminine noun "famiglia" means "family". "famiglie" is the plural of "famiglia".
The masculine noun "problema" means "problem". "problema" is not feminine. "problemi" is the plural of "problema".
The feminine noun "spesa" means "expense". The masculine noun "governo" means "government".
The feminine noun "metà" means "half". The masculine noun "giardino" means "garden".
The masculine noun "quadro" means "picture". The masculine noun "milione" means "million". "milioni" is the plural of "milione".
The masculine noun "numero" means "number". The masculine noun "grafico" means "graph".').
lesson_58(italian, 2, 'The number "mila" means "thousand". The number "sette" means "seven". The number "due" means "two".
The adjective "povero" means "poor". "poveri" is the plural of "povero".
The adjective "piccolo" means "small". The adjective "nero" means "black". The adjective "grafico" means "graphic". The adjective "francese" means "French".
The adjective "migliore" means "good". "migliore" is the comparative of "buono". The adjective "buono" means "good".
The masculine adjective "colpito" means "struck". "colpiti" is the plural of "colpito". The feminine adjective "colpita" means "struck". "colpite" is the plural of "colpita".
The word "più" begins the comparative. The adverb "più" means "more". The adverb "meno" means "less". The adverb "direttamente" means "directly".
The determiner "ogni" means "each". The pronoun "pochi" means "few". "pochi" is the plural of "poco".
The masculine pronoun "alcuno" means "some". "alcuni" is the plural of "alcuno". The pronoun "alcuno" does not precede the verb. The determiner "alcun" means "some". "alcuni" is the plural of "alcun".
The pronoun "loro" means "they". The pronoun "loro" means "them". The pronoun "loro" does not precede the verb. The possessive "loro" means "their". The pronoun "ciascuno" means "each". The determiner "ciascuno" means "each". The pronoun "ciascuno" does not precede the verb.
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb. The pronoun "lo" means "it".
The word "quello" replaces the noun. The masculine pronoun "quello" means "that". The masculine demonstrative "quello" means "that". The pronoun "quello" does not precede the verb. "quelli" is the plural of "quello".
The impersonal pronoun "si" means "one".
The word "dove" means "where". The word "come" means "how". The word "quanto" means "how much". The word "quanti" means "how many". The adverb "quanto" means "as much".
The conjunction "e" means "and". The conjunction "ma" means "but". The conjunction "che" means "that". "che" is a relative.
The conjunction "perché" means "because". The conjunction "perché" means "so that".
The conjunction "di quanto" means "than what".
The preposition "in" means "in". The preposition "di" means "of". The preposition "a" means "to". The preposition "con" means "with".
The preposition "su" means "on". The preposition "per" means "for". The preposition "senza" means "without". The preposition "da" means "by".').
lesson_58(italian, 3, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangiato" is the participle of "mangia".
The verb "vive" means "lives". "vivono" is the plural of "vive". "vivere" is the infinitive of "vive". "viva" is the subjunctive of "vive". "vivano" is the plural of "viva".
The adjective "vivo" means "alive". The feminine adjective "viva" means "alive". "vive" is the plural of "viva".
The verb "spende" means "spends". "spendono" is the plural of "spende".
The verb "è" means "is". "sono" is the plural of "è". "sono" is the first person of "è". "essere" is the infinitive of "è". "stato" is the participle of "è". "è" is the auxiliary of "è".
The verb "ha" means "has". "hanno" is the plural of "ha". The auxiliary "ha" means "has".
The verb "aumenta" means "increases". "aumentato" is the participle of "aumenta". "aumentata" is the participle of "aumenta". "aumentata" is feminine. "è" is the auxiliary of "aumenta".
The verb "finisce" means "finishes". "finito" is the participle of "finisce". "finita" is the participle of "finisce". "finita" is feminine. "è" is the auxiliary of "finisce".
The verb "penalizza" means "penalises". "penalizzato" is the participle of "penalizza". "penalizzati" is the participle of "penalizza". "penalizzati" is the plural of "penalizzato".
The verb "conta" means "counts". "contare" is the infinitive of "conta".
The verb "affronta" means "tackles". "affrontare" is the infinitive of "affronta".').

lesson_58(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not".
The masculine noun "perro" means "dog". The masculine noun "gato" means "cat". The masculine noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The masculine noun "niño" means "child". "niños" is the plural of "niño".
The masculine noun "núcleo" means "household". "núcleos" is the plural of "núcleo". The feminine noun "familia" means "family".
The masculine noun "problema" means "problem". "problema" is not feminine. "problemas" is the plural of "problema".
The masculine noun "gasto" means "expense". The masculine noun "gobierno" means "government".
The feminine noun "mitad" means "half". The masculine noun "jardín" means "garden".
The masculine noun "cuadro" means "picture". The masculine noun "millón" means "million". "millones" is the plural of "millón".
The masculine noun "número" means "number". The masculine noun "gráfico" means "graph".').
lesson_58(spanish, 2, 'The number "mil" means "thousand". The number "siete" means "seven". The number "dos" means "two".
The adjective "pobre" means "poor". "pobres" is the plural of "pobre".
The adjective "pequeño" means "small". The adjective "negro" means "black". The adjective "gráfico" means "graphic". The masculine adjective "francés" means "French". The feminine adjective "francesa" means "French".
The adjective "mejor" means "good". "mejor" is the comparative of "bueno". The adjective "bueno" means "good".
The masculine adjective "golpeado" means "struck". "golpeados" is the plural of "golpeado". The feminine adjective "golpeada" means "struck". "golpeadas" is the plural of "golpeada".
The word "más" begins the comparative. The adverb "más" means "more". The adverb "menos" means "less". The adverb "directamente" means "directly".
The determiner "cada" means "each". The pronoun "pocos" means "few". "pocos" is the plural of "poco".
The masculine pronoun "alguno" means "some". "algunos" is the plural of "alguno". The pronoun "alguno" does not precede the verb. The determiner "algún" means "some". "algunos" is the plural of "algún".
The pronoun "ellos" means "they". The pronoun "ellos" means "them". The pronoun "ellos" does not precede the verb. The pronoun "cada uno" means "each". The pronoun "cada uno" does not precede the verb.
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb. The pronoun "lo" means "it".
The word "el" replaces the noun. The pronoun "aquel" means "that". "aquellos" is the plural of "aquel". The pronoun "aquel" does not precede the verb.
The impersonal pronoun "se" means "one".
The word "dónde" means "where". The conjunction "donde" means "where". The word "cómo" means "how". The word "cuánto" means "how much". The word "cuántos" means "how many". The adverb "cuanto" means "as much". The mark "¿" begins the question.
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "que" means "that". "que" is a relative.
The conjunction "porque" means "because". The conjunction "de modo que" means "so that".
The conjunction "de lo que" means "than what".
The preposition "en" means "in". The preposition "de" means "of". The preposition "a" means "to". The preposition "con" means "with".
The preposition "sobre" means "on". The preposition "para" means "for". The preposition "sin" means "without". The preposition "por" means "by".').
lesson_58(spanish, 3, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comido" is the participle of "come".
The verb "vive" means "lives". "viven" is the plural of "vive". "vivir" is the infinitive of "vive".
The verb "gasta" means "spends". "gastan" is the plural of "gasta".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es". "sido" is the participle of "es".
The verb "tiene" means "has". "tienen" is the plural of "tiene". The auxiliary "ha" means "has". "han" is the plural of "ha". "ha" is the auxiliary of "es".
The verb "aumenta" means "increases". "aumentado" is the participle of "aumenta".
The verb "termina" means "finishes". "terminado" is the participle of "termina".
The verb "penaliza" means "penalises". "penalizado" is the participle of "penaliza". "penalizados" is the participle of "penaliza". "penalizados" is the plural of "penalizado".
The verb "cuenta" means "counts". "contar" is the infinitive of "cuenta".
The verb "afronta" means "tackles". "afrontar" is the infinitive of "afronta".').

section_59 :-
    format("~n59. A Spanish report into Italian: a share of a plural for a subject, a day after a participle, a phrase of `among' with a pronoun between commas, the participle after a perfect infinitive's copula, a day before a relative clause's verb~n", []),
    lesson_59(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the report''s shapes, under its own name', NS),
    lesson_59(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Parte de los perros comen el pan.', spanish, italian, S59a),
    must('a SHARE OF A PLURAL is the subject, and the plural''s verb agrees with it: `parte de los explosivos fueron colocados'' is `parte degli esplosivi ...'' -- `parte'' is the verb''s third person too, and a bare singular that is a verb''s form was no subject', S59a, 'Parte dei cani mangia il pane.'),
    reason_translate('Parte con los perros.', spanish, italian, S59b),
    must('... and with no plural after `de'' it is the verb still: he leaves with the dogs', S59b, 'Parte con i cani.'),
    reason_translate('Los perros comprados el domingo comen el pan.', spanish, italian, S59c),
    must('a DAY after a reduced relative''s participle is the participle''s own: `los hechos ocurridos el pasado domingo arrastran la situación'' is the facts that happened on Sunday', S59c, 'I cani comprati domenica mangiano il pane.'),
    reason_translate('Dos perros, entre ellos un gato, comen el pan.', spanish, italian, S59d),
    must('a phrase of AMONG with a pronoun between commas stands aside: `cuatro palestinos, entre ellos un niño de 10 años, y dos israelís, perdieron la vida'' -- `entre'' is the subjunctive of `entrar'' too, and was read as a clause of its own', S59d, 'Due cani, tra loro un gatto, mangiano il pane.'),
    reason_translate('Dos perros, entre ellos un gato, comen el pan.', spanish, english, S59e),
    must('... and English writes it as it stood', S59e, 'Two dogs, among them a cat, eat the bread.'),
    reason_translate('Los perros parecen haber sido vistos.', spanish, italian, S59f),
    must('the participle after a PERFECT INFINITIVE''S COPULA agrees with the subject: `parecen haber sido vistos'' is `sembrano essere stati visti'', not `essere stato visti''', S59f, 'I cani sembrano essere stati visti.'),
    reason_translate('Las casas parecen haber sido vistas.', spanish, italian, S59g),
    must('... in the feminine plural too', S59g, 'Le case sembrano essere state viste.'),
    reason_translate('Los perros parecen haber comido el pan.', spanish, italian, S59h),
    must('... and after `avere'' the participle agrees with nothing', S59h, 'I cani sembrano avere mangiato il pane.'),
    reason_translate('El perro que el domingo come el pan duerme.', spanish, italian, S59i),
    must('a DAY before a relative clause''s verb is its front, and the relative word its subject: `un niño que el domingo había resultado herido'' is the boy who was hurt on Sunday, not the day that was', S59i, 'Il cane che domenica mangia il pane dorme.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_59(L, Text) :- lesson_59(L, 1, A), lesson_59(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_59(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not".
The conjunction "y" means "and". The conjunction "que" means "that". "que" is a relative.
The masculine noun "perro" means "dog". The masculine noun "gato" means "cat". The masculine noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The feminine noun "parte" means "part".
The noun "domingo" means "sunday". "domingo" is a time. The article "el" takes the day.
The pronoun "ellos" means "they". The pronoun "ellos" means "them". The pronoun "ellos" does not precede the verb.
The number "dos" means "two". The number "cuatro" means "four".
The preposition "en" means "in". The preposition "de" means "of". The preposition "con" means "with". The preposition "entre" means "among".').
lesson_59(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "comido" is the participle of "come".
The verb "tiene" means "has". "tienen" is the plural of "tiene".
The verb "es" means "is". "son" is the plural of "es". "ser" is the infinitive of "es". "sido" is the participle of "es".
The verb "parte" means "leaves". "parten" is the plural of "parte".
The verb "compra" means "buys". "comprado" is the participle of "compra". "comprados" is the participle of "compra". "comprados" is the plural of "comprado".
The verb "ve" means "sees". "visto" is the participle of "ve". "vista" is the participle of "ve". "vista" is feminine. "vistos" is the participle of "ve". "vistos" is the plural of "visto". "vistas" is the participle of "ve". "vistas" is feminine. "vistas" is the plural of "vista".
The verb "parece" means "seems". "parecen" is the plural of "parece".
The auxiliary "ha" means "has". "han" is the plural of "ha". "haber" is the infinitive of "ha". "ha" is the auxiliary of "es".
The verb "entra" means "enters". "entre" is the subjunctive of "entra".
"bought" is the participle of "buys". "seen" is the participle of "sees". "been" is the participle of "is".').
lesson_59(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "del" is the contraction of "di il". "della" is the contraction of "di la".
"dei" is the contraction of "di i". "delle" is the contraction of "di le". "degli" is the contraction of "di gli". "al" is the contraction of "a il". "ai" is the contraction of "a i".
"l''" is the elision of "lo". "l''" is the elision of "la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The conjunction "e" means "and". The conjunction "che" means "that". "che" is a relative.
The masculine noun "cane" means "dog". "cani" is the plural of "cane". The masculine noun "gatto" means "cat". "gatti" is the plural of "gatto".
The masculine noun "pane" means "bread". The feminine noun "casa" means "house". The feminine noun "parte" means "part".
The feminine noun "domenica" means "sunday". "domenica" is a time.
The pronoun "loro" means "they". The pronoun "loro" means "them". The pronoun "loro" does not precede the verb.
The number "due" means "two". The number "quattro" means "four".
The preposition "in" means "in". The preposition "di" means "of". The preposition "con" means "with". The preposition "tra" means "among".').
lesson_59(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangiato" is the participle of "mangia".
The verb "ha" means "has". "hanno" is the plural of "ha". "avere" is the infinitive of "ha".
The verb "è" means "is". "sono" is the plural of "è". "essere" is the infinitive of "è". "è" is the auxiliary of "è".
"stato" is the participle of "è". "stata" is the participle of "è". "stata" is feminine. "stati" is the participle of "è". "stati" is the plural of "stato". "state" is the participle of "è". "state" is feminine. "state" is the plural of "stata".
The verb "compra" means "buys". "comprato" is the participle of "compra". "comprata" is the participle of "compra". "comprata" is feminine. "comprati" is the participle of "compra". "comprati" is the plural of "comprato".
The verb "parte" means "leaves". "partono" is the plural of "parte". "case" is the plural of "casa".
The verb "vede" means "sees". "visto" is the participle of "vede". "vista" is the participle of "vede". "vista" is feminine. "visti" is the participle of "vede". "visti" is the plural of "visto". "viste" is the participle of "vede". "viste" is feminine. "viste" is the plural of "vista".
The verb "sembra" means "seems". "sembrano" is the plural of "sembra".
The verb "entra" means "enters".
The auxiliary "ha" means "has".').

section_60 :-
    format("~n60. An Italian tribute into Spanish: `uno' and an adjective for a noun, dashes after a coordinator, a role after `da', `all' before a pronoun, a front before a connector's clause, a clause between dashes after an adverb, a relative's front after its preposition, a verb by its object in a gerund, a noun that is an adverb too, a phrase after an object and its comma~n", []),
    lesson_60(spanish, LS), reason_learn(LS, spanish, TS), length(TS, NS),
    show('a Spanish lesson of the tribute''s shapes, under its own name', NS),
    lesson_60(italian, LI), reason_learn(LI, italian, TI), length(TI, NI),
    show('and an Italian one', NI),
    reason_translate('Il cane era uno stoico.', italian, spanish, S60a),
    must('`UNO'' and an adjective for a noun: `Era uno stoico pratico'' is he was a practical stoic -- `uno'' is the pronoun for one too, and the lesson''s article is the word before `st'', `z'', `gn''', S60a, 'El perro era un estoico.'),
    reason_translate('Il cane dorme, ma - ora - il gatto mangia il pane.', italian, spanish, S60b),
    must('dashes after a coordinator are commas: `Mi piaceva, ma - di nuovo - non potevo dirglielo''', S60b, 'El perro duerme, pero, ahora, el gato come el pan.'),
    reason_translate('Maria mangia da studente.', italian, spanish, S60c),
    must('a bare noun for a person after `da'' is a role, as a student: the lesson says `The preposition "da" means "as a".'', never `as'', which would make `da quando'' a clause of comparison', S60c, 'Maria come como estudiante.'),
    reason_translate('Maria vede Giovanni e tutti gli amici.', italian, english, S60d),
    must('`tutti'' before its determiner ends no phrase: `Giovanni e tutti gli amici''', S60d, 'Maria sees Giovanni and all the friends.'),
    reason_translate('Il cane, per tutti noi, era una medaglia.', italian, spanish, S60e),
    must('`all'' before a plural pronoun is one phrase: `per tutti noi'' is for all of us, and `todos'' agrees with it', S60e, 'El perro, para todos nosotros, era una medalla.'),
    reason_translate('Ora, ogni volta che il cane dorme, il gatto mangia.', italian, english, S60f),
    must('a front and a clause that opens on a connector: `Per questo, ogni volta che andavamo a mangiare ..., gli ricordavo ...'' -- the front is a verbless part of its own', S60f, 'Now, whenever the dog sleeps, the cat eats.'),
    reason_translate('Il cane dorme ora - io mangio - e il gatto mangia.', italian, spanish, S60g),
    must('a clause between dashes after an adverb stays where it stood: `andavamo a mangiare insieme - o meglio: io mangiavo, lui testava ... - gli ricordavo''', S60g, 'El perro duerme ahora – yo como – y el gato come.'),
    reason_translate('Il cane dorme nella casa - e nella città - del gatto.', italian, spanish, S60h),
    must('dashes round a coordinator and a phrase of a preposition are commas, in the middle of a phrase: `dall''avventura - e dallo spettacolare naufragio - della "voce"''', S60h, 'El perro duerme en la casa, y en la ciudad, del gato.'),
    reason_translate('Il cane con cui spesso dorme mangia il pane.', italian, spanish, S60i),
    must('a relative''s front after its preposition: `con cui per decenni ha condotto una battaglia'' -- the adverb stays in its clause', S60i, 'El perro con el que a menudo duerme come el pan.'),
    reason_translate('Il cane che io abbia visto dorme.', italian, spanish, S60j),
    must('a present subjunctive''s first person in the perfect: `il capo che io abbia visto'' is the boss I have seen', S60j, 'El perro que yo he visto duerme.'),
    reason_translate('Il cane, dico, mangia il pane.', italian, spanish, S60k),
    must('who says so after a phrase, with a verb group after it, is the phrase''s aside: `Questo, devo dire, gli piaceva''', S60k, 'El perro, digo, come el pan.'),
    reason_translate('Qualcuno dei cani dorme.', italian, spanish, S60l),
    must('a pronoun that opens the subject and has a phrase of `of'' after it is no clitic: `Qualcuno dei suoi ragazzi affogasse''', S60l, 'Alguno de los perros duerme.'),
    reason_translate('Sapendo che il cane dorme, Maria mangia.', italian, spanish, S60m),
    must('a gerund''s verb by its object: `sapendo di non essere obbedito'' knows a thing -- `sabiendo'', and `conociendo'' with an object', S60m, 'Sabiendo que el perro duerme, Maria come.'),
    reason_translate('Maria dorme nel secondo piano.', italian, spanish, S60n),
    must('a noun that is an adverb too after an ordinal that is a noun too: `al terzo piano'' is on the third floor, and `piano'' is `slowly'' as well', S60n, 'Maria duerme en el segundo piso.'),
    reason_translate('Maria vede Giovanni, lo studente.', italian, spanish, S60o),
    must('a phrase after an object and its comma is the object''s apposition: `amava teneramente Marisa Rivolta, la sua compagna d''autunno'' -- no second object, and no marker of a person before it', S60o, 'Maria ve a Giovanni, el estudiante.'),
    reason_translate('Maria pubblica da studente a professore.', italian, spanish, S60p),
    must('a range of roles is no role: `da giudice di legittimità a giudice di merito'' is from judge to judge, never `como juez''', S60p, 'Maria publica desde estudiante a profesor.'),
    reason_translate('Maria vede tutti quelli con cui il cane dorme.', italian, spanish, S60q),
    must('the pronoun after `all'' is a personal one: `tutti quelli con cui ho lavorato'' is all of those, and `tutti noi'' all of us', S60q, 'Maria ve todos aquellos con los que el perro duerme.'),
    reason_translate('C''è ancora oggi un cane.', italian, spanish, S60r),
    must('the cut for a noun that is an adverb too is made after an ordinal only: `c''è ancora oggi gente'' is there are still today people, and `ancora'' is an anchor as well', S60r, 'Hay todavía hoy un perro.'),
    reason_unlearn(spanish), reason_unlearn(italian).

lesson_60(L, Text) :- lesson_60(L, 1, A), lesson_60(L, 2, B), atomic_list_concat([A, ' ', B], Text).

lesson_60(spanish, 1, 'Spanish is a language.
The masculine article "el" means "the". The feminine article "la" means "the".
"los" is the plural of "el". "las" is the plural of "la".
The masculine article "un" means "a". The feminine article "una" means "a".
"del" is the contraction of "de el". "al" is the contraction of "a el".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every noun that ends in a vowel takes "s" in the plural.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "no" means "not".
The conjunction "y" means "and". The conjunction "pero" means "but". The conjunction "que" means "that". "que" is a relative. The conjunction "porque" means "because".
The conjunction "cada vez que" means "whenever".
The masculine noun "perro" means "dog". The masculine noun "gato" means "cat". The masculine noun "pan" means "bread". "panes" is the plural of "pan".
The feminine noun "casa" means "house". The feminine noun "ciudad" means "city". "ciudades" is the plural of "ciudad". The masculine noun "amigo" means "friend".
The feminine noun "medalla" means "medal". The masculine noun "estudiante" means "student". "estudiante" is a person. "estudiantes" is the plural of "estudiante".
The masculine noun "piso" means "floor". The masculine noun "segundo" means "second". The masculine adjective "segundo" means "second". The adverb "despacio" means "slowly".
The masculine adjective "estoico" means "stoic".
The pronoun "nosotros" means "we". The pronoun "nosotros" means "us". The pronoun "nosotros" does not precede the verb.
The pronoun "yo" means "I". The pronoun "yo" does not precede the verb.
The pronoun "todos" means "everyone". The pronoun "todos" does not precede the verb. The masculine pronoun "todo" means "all". "todos" is the plural of "todo".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The pronoun "alguno" means "somebody".
The masculine demonstrative "aquel" means "that". "aquellos" is the plural of "aquel". The masculine pronoun "aquel" means "that". The pronoun "aquel" does not precede the verb.
The masculine noun "profesor" means "teacher". "profesor" is a person.
The adverb "ahora" means "now". The adverb "a menudo" means "often". The adverb "todavía" means "still". The adverb "hoy" means "today".
The preposition "en" means "in". The preposition "de" means "of". The preposition "con" means "with". The preposition "para" means "for". The preposition "desde" means "from". The preposition "como" means "as". The preposition "a" means "to". The word "a" precedes the person.').
lesson_60(spanish, 2, 'The verb "duerme" means "sleeps". "duermen" is the plural of "duerme". "dormir" is the infinitive of "duerme".
The verb "come" means "eats". "comen" is the plural of "come". "comer" is the infinitive of "come". "como" is the first person of "come". "comiendo" is the gerund of "come".
The verb "tiene" means "has". "tienen" is the plural of "tiene". The verb "hay" means "there is".
The verb "es" means "is". "era" is the past of "es". "son" is the plural of "es". "ser" is the infinitive of "es". "sido" is the participle of "es".
The verb "ve" means "sees". "visto" is the participle of "ve". "he" is the first person of "ha". "ha" is the auxiliary of "es".
The verb "sabe" means "knows". "sabiendo" is the gerund of "sabe". "saber" is the infinitive of "sabe".
The transitive verb "conoce" means "knows". "conociendo" is the gerund of "conoce". "conocer" is the infinitive of "conoce".
The verb "dice" means "says". "digo" is the first person of "dice". "decir" is the infinitive of "dice".
The verb "publica" means "publishes". "publicar" is the infinitive of "publica".
The auxiliary "ha" means "has". "han" is the plural of "ha". "haber" is the infinitive of "ha".
"seen" is the participle of "sees". "known" is the participle of "knows". "been" is the participle of "is".').
lesson_60(italian, 1, 'Italian is a language.
The masculine article "il" means "the". The masculine article "lo" means "the". The feminine article "la" means "the".
"i" is the plural of "il". "gli" is the plural of "lo". "le" is the plural of "la".
The masculine article "un" means "a". The masculine article "uno" means "a". The feminine article "una" means "a". The article "uno" comes before "st".
"nel" is the contraction of "in il". "nella" is the contraction of "in la". "del" is the contraction of "di il". "della" is the contraction of "di la". "dei" is the contraction of "di i". "al" is the contraction of "a il".
"l''" is the elision of "lo". "l''" is the elision of "la".
Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.
Every adjective follows the noun. Every pronoun precedes the verb.
The word "non" means "not".
The conjunction "e" means "and". The conjunction "ma" means "but". The conjunction "che" means "that". "che" is a relative. The conjunction "perché" means "because".
The conjunction "ogni volta che" means "whenever".
The masculine noun "cane" means "dog". "cani" is the plural of "cane". The masculine noun "gatto" means "cat". "gatti" is the plural of "gatto".
The masculine noun "pane" means "bread". The feminine noun "casa" means "house". The feminine noun "città" means "city". The masculine noun "amico" means "friend". "amici" is the plural of "amico".
The feminine noun "medaglia" means "medal". The masculine noun "studente" means "student". "studente" is a person.
The masculine noun "piano" means "floor". The masculine noun "secondo" means "second". The masculine adjective "secondo" means "second". The adverb "piano" means "slowly".
The masculine adjective "stoico" means "stoic".
The pronoun "noi" means "we". The pronoun "noi" means "us". The pronoun "noi" does not precede the verb.
The pronoun "io" means "I". The pronoun "io" does not precede the verb.
The pronoun "tutti" means "everyone". The pronoun "tutti" does not precede the verb. The masculine pronoun "tutto" means "all". "tutti" is the plural of "tutto".
The pronoun "uno" means "one". The pronoun "uno" does not precede the verb.
The pronoun "qualcuno" means "somebody".
The masculine demonstrative "quello" means "that". "quelli" is the plural of "quello". The masculine pronoun "quello" means "that". The pronoun "quello" does not precede the verb.
The masculine noun "professore" means "teacher". "professore" is a person.
The adverb "ora" means "now". The adverb "spesso" means "often". The adverb "ancora" means "still". The feminine noun "ancora" means "anchor". The adverb "oggi" means "today". The masculine noun "oggi" means "today".
The preposition "in" means "in". The preposition "di" means "of". The preposition "con" means "with". The preposition "per" means "for". The preposition "da" means "from". The preposition "da" means "as a". The preposition "come" means "as". The preposition "a" means "to".
"cui" is a relative. The word "cui" follows the preposition.').
lesson_60(italian, 2, 'The verb "dorme" means "sleeps". "dormono" is the plural of "dorme". "dormire" is the infinitive of "dorme".
The verb "mangia" means "eats". "mangiano" is the plural of "mangia". "mangiare" is the infinitive of "mangia". "mangio" is the first person of "mangia". "mangiando" is the gerund of "mangia".
The verb "ha" means "has". "hanno" is the plural of "ha". "avere" is the infinitive of "ha". "ha" is the auxiliary of "è". "abbia" is the subjunctive of "ha".
The verb "c''è" means "there is". "ci sono" is the plural of "c''è".
The verb "è" means "is". "era" is the past of "è". "sono" is the plural of "è". "essere" is the infinitive of "è". "è" is the auxiliary of "è". "stato" is the participle of "è".
The verb "vede" means "sees". "visto" is the participle of "vede".
The verb "sa" means "knows". "sapendo" is the gerund of "sa". "sapere" is the infinitive of "sa".
The transitive verb "conosce" means "knows". "conoscendo" is the gerund of "conosce". "conoscere" is the infinitive of "conosce".
The verb "dice" means "says". "dico" is the first person of "dice". "dire" is the infinitive of "dice".
The verb "pubblica" means "publishes". "pubblicare" is the infinitive of "pubblica".
The auxiliary "ha" means "has". "hanno" is the plural of "ha".
"seen" is the participle of "sees". "known" is the participle of "knows". "been" is the participle of "is".').


%% Duplicated at the foot of every tutorial on purpose: one you can copy
%% anywhere and run is worth six repeated lines, and one that needs a support
%% file beside it stops working the moment it moves.

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% a line mentions one of the words: a mention is between quotation marks,
%% and the odd parts of the line cut at them are the mentions
mentions(Line, Words) :-
    split_string(Line, "\"", "", Parts), mentioned(Parts, Ms),
    member(M, Ms), atom_string(A, M), memberchk(A, Words), !.
mentioned([_, M|Rest], [M|Ms]) :- !, mentioned(Rest, Ms).
mentioned(_, []).

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
