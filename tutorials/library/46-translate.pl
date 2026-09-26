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
    show('so a language is added by adding its lesson', 'reason_learn(Text, Language, Terms)'),

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
    show('what the IR carries is the subject, not a word of any language', IR19),

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

    format("~nA lesson is a knowledge base; a translation is a proof over it.~ndone~n", []).

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
    must('an intransitive verb''s SUBJECT AFTER ITS ADJUNCTS, with its relative clause',
         S30h, 'Those that eat the bread sleep in the house only.'),
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
    reason_translate('Poi il cane disse che il gatto dorme.', italian, spanish, S32h),
    must('an adverb goes BEFORE a clause the verb takes', S32h, 'El perro dijo entonces que el gato duerme.'),
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
The adverb "poi" means "then".
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
The adverb "entonces" means "then".
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
