%% cocolog -- library(reasoning/translate): a language lesson as a knowledge
%% base, and a translation as a proof over it.
%%
%%     :- use_module(library(reasoning/translate)).
%%
%%     ?- reason_learn('Spanish is a language.
%%                      The noun "casa" means "house". The adjective "grande" means "big".
%%                      The verb "es" means "is". The feminine article "la" means "the".
%%                      Every noun that ends in "a" is feminine.
%%                      Every adjective follows the noun.
%%                      Every noun that ends in a vowel takes "s" in the plural.
%%                      Every article that ends in a vowel takes "s" in the plural.
%%                      Every adjective that ends in a vowel takes "s" in the plural.
%%                      "son" is the plural of "es". "era" is the past of "es".
%%                      The word "no" means "not".'),
%%        reason_translate('The houses were not big.', S),
%%        reason_translate(S, E).
%%     S = 'Las casas no eran grandes.',
%%     E = 'The houses were not big.'
%%
%% TIER 2, clauses only, over library(reasoning/reason). NOTHING HERE KNOWS
%% A WORD OF SPANISH. The lesson is the controlled English -- a word in
%% quotation marks is MENTIONED and stands for itself, `the noun "casa"'
%% says what it is, `every noun that ends in "a" is feminine' is a rule --
%% read by reason_text/2 and asserted by reason_learn/1; and what this
%% library knows is WHAT TO ASK. The questions, and the lesson's facts and
%% rules answer them however the lesson put them:
%%
%%     mean(W, E)                      the lesson's word W means the English word E,
%%                                     a verb in the third person singular (`eats')
%%     noun(W)  adjective(W)  verb(W)  article(W)  possessive(W)  pronoun(W)
%%     preposition(W)  adverb(W)  number(W)  conjunction(W)  auxiliary(W)
%%                                     what a word is (`The noun "casa" means "house"')
%%     feminine(W)  masculine(W)       its gender, said of it or ruled
%%     follow(A, noun)                 the adjective A stands after its noun
%%     precede(P, verb)                the object pronoun P stands before the verb
%%     plural_of(P, W)                 P is the plural of W, said (`"los" is the plural of "el"')
%%     take_in(W, E, plural)           or ruled: W takes the ending E in the plural
%%     past_of(P, F)  future_of(P, F)  P is the past, the future, of the form F, said
%%     take_in(F, E, past)  take_in(F, E, future)      or ruled by an ending
%%     participle_of(P, F)             the participle, for the perfect (`"comido" is the participle of "come"')
%%     person_of(P, F)  first(P)  second(P)   the first and the second person of the form F
%%                                     (`"como" is the first person of "come"'); the third is the form
%%     mean(N, not)  follow(N, verb)   the word that denies, and whether it stands after the verb
%%     precede(W, person)  person(N)   the word that stands before a person as the object
%%                                     (`The word "a" precedes the person'), and which nouns
%%                                     are persons (`"amigo" is a person'); a name is one
%%     contraction_of(C, W)            a contraction and its words (`"al" is the contraction of "a el"')
%%     conditional_of(C, F)            the conditional of the form F (`"comería" is the conditional of "come"');
%%                                     English's is `would' and the base, `could', `might'
%%     infinitive_of(I, F)  gerund_of(G, F)   the infinitive and the gerund of F (`"comer" is the
%%                                     infinitive of "come"', `"comiendo" is the gerund of "come"');
%%                                     English's are `to' and the base, and the base and -ing
%%     modal(M)  mean(M, can)          a modal and the English one it means (`The modal "puede"
%%                                     means "can"'): a base form follows it bare
%%     auxiliary(A)  mean(A, is)       the auxiliary of the progressive (`The auxiliary "está"
%%                                     means "is"'), with a gerund after it; the one that means
%%                                     `has' is the perfect's
%%     demonstrative(D)  determiner(D)  `The masculine demonstrative "este" means "this"', `The
%%                                     determiner "cada" means "each"': a word in the article's
%%                                     place, agreeing like one; English's own are this and these,
%%                                     that and those, another and other, much and many
%%     pronoun(P)  mean(P, this)       a pronoun that stands alone (`The pronoun "esto" means
%%                                     "this"', `... "nadie" means "nobody"'): a subject or an
%%                                     object of the third person, after the verb
%%     mean(H, 'there is')             the verb of `there is' (`The verb "hay" means "there is"')
%%     mean(Q, what)  mean(Q, who)  mean(Q, where)  mean(Q, when)  mean(Q, which)   the question words
%%     begin(M, question)              the mark a question begins with (`The mark "¿" begins the question')
%%     elision_of(E, W)                the form W wears before a vowel (`"l'" is the elision of
%%                                     "lo"'): read as W wherever it stands, and written in
%%                                     W's place, joined to the word after it
%%     impersonal(P)  pronoun(P)  mean(P, one)     the pronoun of a sentence that names nobody
%%                                     (`The impersonal pronoun "si" means "one"'): a subject
%%                                     of the third person singular, which English writes `one'
%%     imperative_of(I, F)  negative(I)   the imperative of the form F (`"come" is the
%%                                     imperative of "come"'), and the NEGATIVE one said
%%                                     with the adjective (`"comas" is the negative
%%                                     imperative of "come"'): every language that has
%%                                     both builds the second on a different form --
%%                                     Spanish on its subjunctive, Italian on its
%%                                     infinitive -- and this asks for it by name
%%     subjunctive_of(S, F)  past(S)  the subjunctive of the form F (`"domini" is the
%%                                     subjunctive of "domina"'), the past one said with
%%                                     the adjective (`"dominasse" is the past subjunctive
%%                                     of "domina"', which is subjunctive_of and past both):
%%                                     read as the tense it stands for, and written back
%%                                     as the indicative
%%     intransitive(W)                 the verb takes no object (`"domina" is intransitive'),
%%                                     which is what lets a fronted adjunct put the subject
%%                                     after the verb (`Qui dominava il coprifuoco')
%%     conjunction(C)  mean(C, that)   the word that opens a subordinate clause
%%                                     (`The conjunction "che" means "that"')
%%     relative(R)  follow(R, preposition)   a relative word (`"que" is a relative'), and the
%%                                     one that stands after a preposition (`The word "cui"
%%                                     follows the preposition'); where none does, the
%%                                     preposition and the article that agrees (`al que')
%%     begin(M, moment)                the word that says, with an infinitive, WHEN a thing was
%%                                     done (`The word "al" begins the moment'); a language with
%%                                     no such word writes the gerund
%%     begin(M, infinitive)            the word that stands before a verb's infinitive where
%%                                     English puts `to' (`The word "di" begins the infinitive');
%%                                     a language with no such word reads a bare infinitive only
%%     replace(A, noun)                the article that stands for a noun the sentence left out
%%                                     (`The word "el" replaces the noun': `el de los chicos');
%%                                     where no article does, the pronoun that means `that'
%%     come_before(A, P)               the article's form before a word that begins with P or a
%%                                     vowel (`The article "lo" comes before "sc"')
%%     take(A, possessive)             the article a possessive is written with (`The article
%%                                     "il" takes the possessive': `il suo')
%%     auxiliary_of(A, V)              the perfect's auxiliary where it is not the one meaning
%%                                     `has': of a verb (`"è" is the auxiliary of "esce"'), of
%%                                     the reflexive, of the copula (`"ha" is the auxiliary of
%%                                     "es"'); after a copula the participle agrees
%%     reflexive(V)                    the verb's reflexive word is its own (`"equivoca" is
%%                                     reflexive'), so `se' before it names no subject
%%     follow(I, pronoun)              the impersonal word stands after the object pronouns
%%                                     (`The word "si" follows the pronoun': `li si chiamerà')
%%     language(L)                     the language, `Spanish is a language'
%%
%% A WORD OF SEVERAL WORDS IS ONE WORD wherever a lesson says so -- `The
%% preposition "junto a" means "along with"', `The masculine noun "lavado de
%% cerebro" means "brainwashing"' -- read as one on the lesson's side, the
%% longest first. And a meaning is kept WITH ITS CLASS (mean_as/3, derived
%% as the lesson is learned), so `culpable' is `guilty' where an adjective
%% stands and `culprit' where a noun does.
%%
%% So a lesson in Italian, or one whose rule is `Every adjective precedes
%% the noun', is read by the same clauses -- and a lesson written as Prolog
%% facts in those shapes works with no sentence of English at all. What
%% the translator knows on its own is ENGLISH, the library's language: its
%% articles, possessives and pronouns, the copula in every person and
%% tense (`am', `are', `was', `were'), `does', `do', `did', `will', `has',
%% `have' and `had' as the words that front a question and carry a denial
%% or a tense, `not', `an' before a vowel and no `a' in the plural, a
%% plural noun by -s, -es or -ies and a past by -ed unless the lesson says
%% otherwise (`"children" is the plural of "child"', `"ate" is the past of
%% "eats"', `"eaten" is the participle of "eats"'), and its question words.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     reason_translate(+Text, -Translation)
%%         SIMPLE sentences, each a subject, a verb, and after it an object,
%%         an adjective, a place or a time (`in the house', `with Omar'),
%%         an adverb, an infinitive (`wants to sleep', `can sleep'), or
%%         nothing. A subject or an object is a name, a pronoun, a phrase
%%         -- an article, a possessive, a demonstrative or a determiner,
%%         a number, adjectives, a noun -- or two of those joined by
%%         `and'. The verb is in the present, the past, the future or the
%%         conditional (`would eat'), simple, perfect (`has eaten', `had
%%         eaten') or progressive (`is eating', `was eating'), a modal
%%         (`can', `could', `may', `must', `should') with its verb after
%%         it, denied or not, in any person; and `there is' and `there
%%         are' with what there is (`There is a dog in the house', `There
%%         are no dogs'). A
%%         statement, or a QUESTION when the sentence ends in `?': yes or
%%         no, `what' asking for the object, `who' for the subject, `whom'
%%         for a person as the object, `where' and `when' for a place or a
%%         time, `which' with its noun for either. From English into the
%%         language a lesson teaches, or
%%         from it into English: which way, and which language when several
%%         lessons are loaded, the words say. Translation is an atom, a
%%         sentence capitalised and ending as it ended. FAILS for a
%%         sentence it cannot translate, whole and never half: a word the
%%         lesson gives no meaning (a capitalised one is a name and passes
%%         through), no verb, a form the lesson gives no rule or fact for,
%%         a number in digits, a word in quotation marks, or two languages
%%         the English words fit equally; reason_untranslated/2 names the
%%         words.
%%
%%     reason_translate(+Text, +Into, -Translation)
%%         The same, Into naming the language: english, or the name the
%%         lesson gave its own (`Spanish is a language.' is language(spanish),
%%         so `spanish') or was learned under (reason_learn/3). Any other
%%         name is a domain_error.
%%
%%     reason_translate(+Text, +From, +Into, -Translation)
%%         BETWEEN TWO LANGUAGES, through the intermediate representation:
%%         Italian into Spanish with no English sentence written and none
%%         read. From and Into are languages as Into is above, `english'
%%         among them, and From may be `any' to let the words vote for
%%         one. Both lessons must be in the knowledge base this proves
%%         against, each learned under its own name.
%%
%%     reason_languages(-Languages)
%%         Every language this process can read or write: `english', the
%%         pivot, and each lesson learned under a name -- with `none' for
%%         a lesson learned plain. ADDING A LANGUAGE IS ADDING ITS LESSON;
%%         nothing here is written per pair.
%%
%%     reason_ir(+Text, -IRs)
%%     reason_ir(+Text, +From, -IRs)
%%         The text into the intermediate representation, sentence by
%%         sentence: a list of ir(Sentence, Stop) where Sentence is the
%%         term below and Stop the code the sentence ended on. Fails on a
%%         sentence it cannot read.
%%
%%     reason_ir_text(+IRs, +Into, -Text)
%%         And back out of it, into any language. So one reading serves
%%         every target, and a page read once is written as many times as
%%         there are languages.
%%
%%     reason_translate_page(+Text, +From, +Into, -Lines)
%%         A page between two languages, each sentence its own as
%%         reason_translate_page/2,3 gives it.
%%
%%     reason_untranslated(+Text, -Words)
%%     reason_untranslated(+Text, +From, -Words)
%%         The words of the text no lesson gives a meaning, names and
%%         English's own function words left out; [] when every word is
%%         known.
%%
%%     reason_translate_page(+Text, -Lines)
%%     reason_translate_page(+Text, +Into, -Lines)
%%         A page: every sentence of the text on its own, as a list of
%%         Sentence-Translation, or Sentence-refused(Words) for one this
%%         does not translate, Words as reason_untranslated/2 names them.
%%         The page is never refused whole for one sentence in it.
%%
%%     reason_learn(+Text, +Language, -Terms)
%%         reason_text/2, and every term asserted UNDER THE LANGUAGE: the
%%         translator proves them as if they were plain, and two lessons
%%         so learned share nothing -- `casa' may be feminine in one and
%%         its plural `case' in the other. A lesson learned plain
%%         (reason_learn/1) is the language with no name, and
%%         reason_ask/2 can question it; a lesson learned under a name is
%%         the translator's alone.
%%
%%         A FACT IS HELD IN THE LANGUAGE'S OWN NAMESPACE --
%%         'spanish:mean'(casa, house) -- and a rule in lesson/2, because
%%         a rule's body must be proved through the lesson rather than by
%%         the engine. Nothing outside this file should name either
%%         shape: reason_lesson/2 reads and reason_unlearn/1 forgets.
%%
%%     reason_lesson(?Language, ?Term)
%%         What a named lesson holds, term by term, as reason_learn/3 was
%%         given them. Nondeterministic in both arguments.
%%
%%     reason_unlearn(+Language)
%%         Take a named lesson out again, whole. A lesson learned plain is
%%         not one, and is untouched.
%%
%% ---- THE INTERMEDIATE REPRESENTATION -------------------------------------
%%
%% EVERY LANGUAGE HAS TWO HALVES AND NO PAIR HAS ANY: a sentence is read
%% INTO the IR on its own language's side and written FROM the IR into
%% whichever language is asked for, so three languages are three lessons
%% and not six paths, and a fourth is a fourth lesson.
%%
%%     ir(s(Asked, Subject, g(Lexeme, Tense, Aspect, Denied), Complements), Stop)
%%
%% is the whole of it -- the same term the reader builds, with the words
%% in it ENGLISH. `Il cane non mangia il pane.' reads as
%%
%%     s(none, np(det(article, the, w(the, lower)), none, [], w(dog, lower), singular),
%%       g(eats, present, simple, yes),
%%       [obj(np(det(article, the, w(the, lower)), none, [], w(bread, lower), singular))])
%%
%% and that one term writes as `Il cane non mangia il pane.', `The dog
%% does not eat the bread.' and `El perro no come el pan.'
%%
%% WHAT TRAVELS EXACTLY IS THE SHAPE: the tense, the aspect, the denial,
%% the person, the number, what a question asks for, and every complement
%% in its place. What travels THROUGH ENGLISH is the vocabulary, and it
%% can be nothing else -- a lesson says what a word means only as
%% mean(Word, EnglishWord), so English is the one language every lesson
%% is written against. A sense English does not separate is a sense the
%% IR cannot separate, and a word one lesson gives that the other does
%% not refuses the sentence with that word named, as ever.
%%
%% ENGLISH IS THEREFORE ALREADY THE IR, which is what a pivot means: a
%% sentence read on the English side needs no crossing at all, and its
%% words stay as the text wrote them (`houses') where a crossed word is
%% the lexeme its meaning gave (`house', with the number beside it).
%% Both are English words and both write out the same, because every
%% consumer takes the lexeme first.
%%
%% The two halves are tr_into_ir/4 and tr_from_ir/5, and the crossing
%% walk tr_cross/3 between them makes exactly the lookups the writer
%% into English makes -- over the term, once, rather than over the words
%% coming out of it.
%%
%% ---- HOW A SENTENCE IS TRANSLATED ----------------------------------------
%%
%% A sentence is READ to one shape and WRITTEN from it: a subject, a verb
%% group (the lexeme, its tense, simple or perfect or progressive, passive,
%% a gerund or an imperative, denied or not), and the complements in order -- an object, a
%% predicative adjective, what the verb predicates OF its object
%% (`definire illegale la decisione', which the lesson's language writes
%% before the object and English after it), a prepositional phrase, the
%% agent of a passive, an infinitive, an infinitive of purpose, a
%% subordinate clause after the word that means `that', an object
%% pronoun, an adverb, a gerund that says how the thing was done, and
%% the lesson's word for the moment with an infinitive (`al acusar').
%% Several clauses in one sentence are a join, a comma, a semicolon or a
%% connecting word between two of these.
%%
%% A PHRASE CARRIES WHAT HANGS ON IT: a relative clause with its own
%% pronoun, for the subject, the object or a preposition's object (`el
%% grupo al que pertenece', rc(Phrase, Role, Clause)); two or more
%% phrases joined, a comma between the first ones (`pan, caldo y sopa');
%% a name between commas after it (`el ministro, Jean-Pierre
%% Chevènement,'); an adverb before one of its adjectives (`tan
%% pacífica'); and an adjective the source set BEFORE its noun where the
%% lesson's rule puts it after, which keeps its place in a language with
%% the same rule (`una paradossale educazione'). A phrase whose noun was
%% LEFT OUT is an article with adjectives (`el más débil') or with a `de'
%% phrase (`el de los chicos'), the article's gender standing for the
%% noun's. What has no verb reads in two places only: an exclamation
%% (`¡Atención al veneno!'), and after a semicolon the clause that leaves
%% out the verb of the one before it (`el gato, la sopa').
%%
%% AN IMPERATIVE HAS NO SUBJECT AND NAMES ONE ANYWAY -- the person spoken
%% to. It is read LAST, so a bare third person that was refused before is
%% all that changes, and only a form the lesson CALLS an imperative reads
%% as one: `Come el pan.' is `Eat the bread.' where `Comía el pan.' is a
%% subject nobody named (below). The cost of that is the other half of the same rule --
%% where a language spells the imperative like its third person the
%% sentence is genuinely ambiguous, and the imperative is the reading
%% taken, because it is the one that names its subject.
%%
%% THREE SHAPES PUT THE SUBJECT SOMEWHERE ELSE, or leave it out. A verb
%% the lesson calls INTRANSITIVE, with an adverb or a prepositional
%% phrase before it and nothing else, takes the phrase after it as its
%% SUBJECT (`Qui dominava il coprifuoco'); a PARTICIPLE at the head with
%% a phrase after it is a headline, read as the passive it leaves the
%% copula out of (`Evacuata la Tate Gallery.'); and a GERUND at the head
%% is a clause with no subject of its own, hung off the clause before it
%% by the comma join (`..., escludendo che il militare voleva ...').
%% Every one of them is written back in the statement's own order, with
%% the copula put back: what is lost is an emphasis or a typography, and
%% never a claim. A question is first
%% put in the statement's order: English's fronted `does', `did', `will',
%% `has' or copula goes back behind the subject, and in the lesson's
%% language a verb that came first takes the subject after it (`¿Come el
%% perro el pan?', `¿Es grande la casa?'); the question word is kept
%% aside with what it asks for, and `which' takes its noun phrase with it.
%%
%% Each word is looked up, mean(W, E) read from whichever side the word is
%% on, and a form is taken apart into its LEXEME -- the form the lesson
%% gave -- and what was done to it: the number (a stated plural, or the
%% ending its rule gives; in English -s, -es, -ies), the tense (a stated
%% past or future, or an ending; in English -ed, `was', `were', `had'),
%% the person (a stated first or second person of that form). Going the
%% other way the same steps are taken in turn -- number, tense, person --
%% and a form no fact or rule gives refuses the sentence. The perfect is
%% the auxiliary the lesson names (`The auxiliary "ha" means "has"') in
%% the subject's person and number and the participle the lesson stated;
%% English's is `has', `have' or `had' and a stated participle or the
%% regular past.
%%
%% The subject sets the person and the number: a name is third singular,
%% a pronoun what it is, two subjects joined are plural. A phrase is an
%% article, a possessive or a number -- a possessive AFTER an article
%% being the determiner, which a lesson that says `The article "il" takes
%% the possessive' writes with the article back in front (`la sua casa',
%% `su casa') -- then its content: the noun is the
%% word the lesson calls one (failing that the last word in English and,
%% where adjectives follow the noun, the first), and every other word is
%% an adjective; the noun's number is the phrase's. A phrase whose content
%% is CAPITALISED WORDS NO LESSON KNOWS is a name -- `la Tate Gallery', `la
%% Sidoti', which Italian writes far more often than English does -- and
%% there the ARTICLE says what the name cannot: its number, and its gender,
%% which travels in the IR so the other language agrees with it. Where the target is
%% the lesson's language the article, the possessive and each adjective
%% are chosen among the words the lesson gives for the English one by the
%% gender of the noun -- one of the noun's gender first, one with no
%% gender next, the first otherwise -- and put in the number; an
%% adjective goes after its noun when follow(A, noun) proves; an object
%% pronoun goes before the verb when precede(P, verb) proves, English's
%% own object pronouns after it. The word the lesson puts before a person
%% (`The word "a" precedes the person') goes before an object that is one
%% -- a name, a phrase whose noun the lesson calls a person, `whom' --
%% and read on the lesson's side, that word with a person after it and no
%% object before it IS the object (`Maria ve a Omar'), after an object
%% the preposition it is (`da el libro a Omar'); `whom' is `who' asked for
%% as the object, and a lesson need give no word for it. A contraction
%% the lesson states (`"al" is the contraction of "a el"') is read as its
%% words and written back as itself. A sentence of the lesson's language
%% with no subject takes the pronoun its verb says -- I, you, we, they;
%% and a third person SINGULAR is a subject nobody named, null(third,
%% singular), which the lesson's language writes as it came and English,
%% which must choose he, she or it, refuses --
%% and the denial's word goes before the verb, or after it when
%% follow(N, verb) proves. A capitalised word no lesson knows is a name
%% and passes through; the head of a sentence goes lower when it is a
%% word the lesson knows, because a question moves it.
%%
%% ---- WHAT IT IS NOT ---------------------------------------------------
%%
%% It is not a translator of prose. What it has is one clause with one
%% verb and its complements, several such joined by a comma or a
%% connecting word, a passive with its agent, a reduced relative (a
%% participle after a noun), an infinitive of purpose, an adjective in
%% the comparative or the superlative, a subordinate clause after `that',
%% a subject after its verb, a headline with the copula left out, a gerund
%% clause, an article before a name and an imperative -- and, since
%% 1.6.14, what stands BESIDE the sentence: an adverb wherever its
%% language puts one (inside the verb group, at the head, after the verb),
%% a connector at the head with no left clause in the sentence, a fronted
%% adjunct before the subject, a bare time phrase the lesson calls one, a
%% preposition whose object is an adverb or an infinitive, a conjunction
%% between two complements, and a participle predicated of the subject.
%% Since 1.6.15 it has a relative clause with its own pronoun, `how', a
%% list, a phrase whose noun was left out and the two verbless shapes
%% above; since 1.6.21 a percentage, a date, a heading that ends in its
%% colon, a sentence that is one phrase with its relative clause, a list
%% that is the subject, and a reporting clause between two dashes, between
%% two commas or after a quotation that closes inside its sentence -- the
%% last three written AFTER the sentence, whatever place the source gave
%% them. A QUOTATION THAT OPENS ON ITS VERB LOSES ITS OPENING MARK: the
%% mark travels on the word, and a verb is written from its lexeme. Since
%% 1.7.0 it has the plain quotation mark over two sentences, read by the
%% character after it; a verb's meaning by whether its clause has an object
%% (`The intransitive verb "destaca" means "stands out".'); a name after a
%% participle; a year aside, and the article a lesson says a year takes; the
%% copula of a state with a participle, as a passive; a noun's own clause
%% (`prueba de que ...', `The word "de" begins the clause.'); a number after
%% its noun as its label; a comparative that is a word of its own (`"mejor"
%% is the comparative of "bueno".'); and a partitive whose head agrees with
%% the noun it is taken from. Since 1.7.2 it has a dateline (`Roma - ...');
%% a headline colon with no verb on either side; a relative clause set off
%% after a comma; the passive of a verb a lesson says marks one (`The verb
%% "viene" marks the passive.'), what must be done (`The verb "va" marks the
%% duty.') and a passive's subject after it; and a comma kept before a
%% subordinating word. Since 1.8.0 it has a comparison of two things (`más
%% grande que el perro', `idénticos condicionantes que la ronda anterior')
%% and more than an adjective (`más que cuestionable'); the preposition a
%% verb puts before its infinitive where the lesson says so (`"confía"
%% takes "en" before the infinitive.'); `ni ... ni' before its verb and
%% after it; the impersonal modal (`The impersonal modal "hay que" means
%% "must".'); an intransitive verb with a dative before it and its subject
%% after it (`le gusta el buen fútbol'); two pronouns joined to an
%% infinitive (`jugárselo'); a clause in parentheses; a denying adverb kept
%% before its verb; a comment between two commas (`como parece probable'),
%% written after the sentence; a phrase whose noun was left out with a
%% relative clause (`el que sufrió el Madrid'); and a subordinate clause at
%% the head with an insertion after its word.
%% What it has NOT is a `why', any other fragment with no verb, the
%% preposition a verb puts before its infinitive where no lesson says it
%% (`propone di punire' comes out `propone punire'), the imperfect apart from
%% the preterite (both are the past), and any idiom -- a word
%% means a word, and `is' is whichever word the lesson gave for it first
%% (a lesson with `es' and `está' for `is' gets `es', and the progressive
%% takes the AUXILIARY that means `is'). `There is' is the present only:
%% a lesson states no past of `hay'.
%% A past that spells like a present form (`read') is read as the present.
%% A SUBJUNCTIVE IS READ AND NOT WRITTEN: English marks none where `che
%% il militare volesse' wants one and no lesson says which verbs take
%% one, so the mood is dropped and the form comes back as the indicative.
%% AN IMPERATIVE'S CLITIC MUST STAND BEFORE THE VERB, which is where a
%% DENIED one puts it (`No lo comas.'): Spanish joins the pronoun to an
%% affirmative imperative and accents the stem (`Comelo.', `Dame eso.'),
%% and no lesson can say either, so such a sentence is refused. Only the
%% singular is stated, so a plural imperative (`Comed el pan.') is one too.
%%
%% A NAME DOES NOT INFLECT and nothing crosses it, so a plural article
%% before one writes the article's plural and the name as it stands (`Le
%% Gallery' is `The Gallery', never `The Galleries'); and several
%% capitalised words are ONE name only after a determiner, because bare
%% there is nothing to say where one name ends and the next begins.
%% And it decides nothing about a word a lesson left out: a sentence with
%% one is refused whole, never half translated, and reason_untranslated/2
%% says which word to teach.

:- use_module(library(reasoning/reason)).
:- dynamic lesson/2.
:- dynamic lesson_language/1.
:- dynamic lesson_predicate/3.

%% ---- the surface -----------------------------------------------------------

%% A PAGE, sentence by sentence: what translates is translated and what
%% does not is named with the words no lesson knows, so a page is never
%% refused whole for one sentence in it. Lines is a list of Sentence-Out
%% where Out is the translation, or refused(Words) -- Words as
%% reason_untranslated/2 gives them, [] when every word was known and the
%% shape was not one this translates. Into is as in reason_translate/3,
%% or `any'.
reason_translate_page(Text, Lines) :- reason_translate_page(Text, any, Lines).
reason_translate_page(Text, Into, Lines) :-
    ( Into == any -> Way = any ; tr_into(Into, Way) ),
    tr_pieces(Text, Pieces),
    findall(Sentence-Out, ( member(Piece-Stop, Pieces), atom_codes(P0, Piece), tr_trim(P0, P1),
                            tr_stop_text(P1, Stop, Sentence),
                            tr_page_one(Piece, Stop, Way, Out) ),
            Lines).

tr_page_one(Piece, Stop, Way, Out) :-
    (   catch(tr_each([Piece-Stop], Way, [Out0]), _, fail) -> Out = Out0
    ;   atom_codes(A, Piece), reason_untranslated(A, Words), Out = refused(Words)
    ).

tr_trim(A, T) :- atom_codes(A, Cs), tr_trim_codes(Cs, Ds), atom_codes(T, Ds).
tr_trim_codes(Cs, Ds) :- append(Sp, Rest, Cs), \+ ( Sp = [C|_], C > 32 ), Rest = [C0|_], C0 > 32, !, tr_trim_end(Rest, Ds).
tr_trim_codes(Cs, Cs).
tr_trim_end(Cs, Ds) :- append(Ds, Sp, Cs), \+ ( member(C, Sp), C > 32 ), ( Ds = [] ; last(Ds, L), L > 32 ), !.

reason_translate(Text, Out) :-
    tr_pieces(Text, Pieces), Pieces \== [],
    tr_each(Pieces, any, Outs),
    atomic_list_concat(Outs, ' ', Out).

reason_translate(Text, Into, Out) :-
    tr_into(Into, Way),
    tr_pieces(Text, Pieces), Pieces \== [],
    tr_each(Pieces, Way, Outs),
    atomic_list_concat(Outs, ' ', Out).

%% ---- the IR, as a program reaches it -------------------------------------------

%% THE LANGUAGES: `english', the pivot, and every lesson learned under a
%% name -- plus `none' where a lesson was learned plain. Adding one is
%% adding its lesson: nothing here is written per pair.
reason_languages([english|Ls]) :- tr_languages(Ls).

%% a text into the IR, sentence by sentence: IRs is a list of ir(S, Stop)
%% where S is the sentence term with English words in it and Stop the
%% code the sentence ended on. From is a language, or `any' to let the
%% words vote for one. It FAILS on a sentence it cannot read -- use
%% reason_translate_page/4 for a page.
reason_ir(Text, IRs) :- reason_ir(Text, any, IRs).
reason_ir(Text, From, IRs) :-
    tr_pieces(Text, Pieces), Pieces \== [],
    tr_each_ir(Pieces, From, IRs).

%% and back out of it, into any language
reason_ir_text(IRs, Into, Text) :-
    tr_side_of(Into, _),
    tr_each_out(IRs, Into, Outs),
    atomic_list_concat(Outs, ' ', Text).

%% a text from one language into another, through the IR: no English
%% sentence is written and none is read, so `Il cane mangia il pane' goes
%% to `El perro come el pan' and the two lessons never meet.
%% THE TARGET'S LESSON IS SET BEFORE THE TEXT IS READ, because an English
%% source is read against a lesson -- what English words the reader knows
%% is what some lesson gives a meaning for -- and when the source is
%% English the only lesson that matters is the target's.
reason_translate(Text, From, Into, Out) :-
    tr_side_of(Into, _),
    reason_ir(Text, From, IRs),
    reason_ir_text(IRs, Into, Out).

%% ... a page of it: what translates is translated and what does not is
%% named, as reason_translate_page/2,3 does
reason_translate_page(Text, From, Into, Lines) :-
    tr_side_of(Into, _),
    tr_pieces(Text, Pieces),
    findall(Sentence-Out, ( member(Piece-Stop, Pieces), atom_codes(P0, Piece), tr_trim(P0, P1),
                            tr_stop_text(P1, Stop, Sentence),
                            tr_ir_page_one(Piece, Stop, From, Into, Out) ),
            Lines).

tr_ir_page_one(Piece, Stop, From, Into, Out) :-
    (   catch(( tr_read_ir(Piece, Stop, From, S, Stop1), tr_write_ir(Into, S, Stop1, Out0) ), _, fail) -> Out = Out0
    ;   atom_codes(A, Piece), reason_untranslated(A, From, Words), Out = refused(Words)
    ).

tr_each_ir([], _, []).
%% a piece with no word in it is no sentence and is passed over, never
%% refused: a stray mark between two stops (`!.') has nothing to translate
tr_each_ir([Piece-_|Ps], From, Ss) :- tr_piece_words(Piece, []), !, tr_each_ir(Ps, From, Ss).
tr_each_ir([Piece-Stop0|Ps], From, [ir(S, Stop)|Ss]) :-
    tr_read_ir(Piece, Stop0, From, S, Stop),
    tr_each_ir(Ps, From, Ss).

%% AN OPENING MARK ON THE FIRST WORD IS THE SENTENCE'S. The mark travels on
%% its word's case, and a word the reader makes a verb carries no case into
%% the IR: `"Hay que tomar precauciones", dijo.' came out `Bisogna prendere
%% precauzioni", disse.', and after a pronoun the capital went -- `"gli ho
%% dato riposo'. At the head of the sentence the mark is taken off the word
%% and put before the sentence, where tr_join/5 writes the marks a
%% quotation over several sentences already had.
tr_read_ir(Piece0, Stop0, From, S, Stop) :-
    tr_caps_piece(Piece0, Piece),
    tr_piece_words(Piece, Words00), Words00 \== [],
    tr_head_mark(Words00, Stop0, Words0t, Stop1),
    tr_from_side(From, Words0t, Side),
    tr_tail_mark(Side, Words0t, Stop1, Words0q, Stop),
    tr_quote_names(Side, Words0q, Words0),
    tr_particle_names(Side, first, Words0, Words0a),
    tr_month_lower(Side, Words0a, Words0b),
    tr_head_lower(Side, Words0b, Words1),
    tr_joined_words(Side, Words1, Words),
    tr_kind(Stop, Kind), tr_exclaim(Stop),
    tr_into_ir(Side, Kind, Words, S).

%% A HEADING IN CAPITALS: `COMPACTO CONTRA CASETE.' A newspaper sets a
%% section's title in capitals, and the tokeniser keeps only the FIRST
%% letter's case, so every word of it came through capitalised: `Casete',
%% a capital no lesson knows, passed through as a name, and `compacto' --
%% which is also what `compactar' says of oneself -- read as the verb, `I
%% compact Against Casete'. A piece with no small letter in it and three
%% capitals at least is a heading: its codes are lowered before a word is
%% read, and the reading with no verb is tried FIRST (tr_read0/4), because
%% the capitals are what says the piece has none. An ACRONYM in a sentence
%% of small letters -- `la consultora DBK' -- is the other case, and a name
%% spelled as the text spelled it (tr_hyphen_name/4).
tr_caps_piece(Piece0, Piece) :-
    \+ ( append(_, [C|Rest], Piece0), tr_small_code(C, Rest) ),
    tr_capitals(Piece0, 0, N), N >= 3, !,
    tr_lower_codes(Piece0, Piece), nb_setval('$tr_caps', yes).
tr_caps_piece(Piece, Piece) :- nb_setval('$tr_caps', no).

tr_small_code(C, _) :- C >= 0'a, C =< 0'z, !.
tr_small_code(195, [B|_]) :- B >= 159, B =< 191.

tr_capitals([], N, N).
tr_capitals([C|Cs], N0, N) :- C >= 0'A, C =< 0'Z, !, N1 is N0 + 1, tr_capitals(Cs, N1, N).
tr_capitals([195, B|Cs], N0, N) :- B >= 128, B =< 158, B =\= 151, !, N1 is N0 + 1, tr_capitals(Cs, N1, N).
tr_capitals([_|Cs], N0, N) :- tr_capitals(Cs, N0, N).

tr_lower_codes([], []).
tr_lower_codes([C|Cs], [L|Ls]) :- C >= 0'A, C =< 0'Z, !, L is C + 32, tr_lower_codes(Cs, Ls).
tr_lower_codes([195, B|Cs], [195, L|Ls]) :- B >= 128, B =< 158, B =\= 151, !, L is B + 32, tr_lower_codes(Cs, Ls).
tr_lower_codes([C|Cs], [C|Ls]) :- tr_lower_codes(Cs, Ls).

%% A NAME MAY BEGIN WITH A SMALL WORD: `ni De la Peña', `De la Peña, en
%% cambio, es baja'. Read as words it was `of the cliff' -- `peña' is a
%% noun -- and came out `Del Dirupo'. A capital on `De' where no sentence
%% begins, or on the word after its article, says the run is one name: `De',
%% an article and a capitalised word, anywhere; `De' or `Del' and a
%% capitalised word, anywhere but the head, where `De Madrid llegó' is a
%% preposition. The name keeps its capitals and passes through as a name.
tr_particle_names(english, _, Ws, Ws) :- !.
tr_particle_names(_, _, [], []) :- !.
tr_particle_names(Side, _, [w(de, C), w(A, lower), w(N, upper)|Ws0], [w(Name, upper)|Ws]) :-
    memberchk(C, [upper, qopen]), memberchk(A, [la, las, los, el]), !,
    tr_cap(N, NC), atomic_list_concat(['De', A, NC], ' ', Name),
    tr_particle_names(Side, later, Ws0, Ws).
tr_particle_names(Side, later, [w(P, upper), w(N, upper)|Ws0], [w(Name, upper)|Ws]) :-
    memberchk(P, [de, del]), !,
    tr_cap(P, PC), tr_cap(N, NC), atomic_list_concat([PC, NC], ' ', Name),
    tr_particle_names(Side, later, Ws0, Ws).
%% ... AND A SMALL WORD BETWEEN TWO NAMES IS THE NAME'S: `Bertrand de
%% Billy', `Lucia di Lammermoor' -- a conductor and an opera. Read as words,
%% `de' and `di' were prepositions and the name came out in two, `Bertrand
%% di Billy'. Both sides are words no lesson knows, and the small word is
%% one names are made with; the run passes through as one name.
tr_particle_names(Side, _, [w(A, upper), w(P, lower), w(B, upper)|Ws0], [w(Name, upper)|Ws]) :-
    memberchk(P, [de, di, da, del, van, von, du, der]),
    tr_name_word(Side, w(A, upper)), tr_name_word(Side, w(B, upper)), !,
    tr_cap(A, AC), tr_cap(B, BC), atomic_list_concat([AC, P, BC], ' ', Name),
    tr_particle_names(Side, later, Ws0, Ws).
%% ... AND A NAME WHOSE FIRST WORD THE LESSON KNOWS, AFTER A BARE PREPOSITION:
%% `il commento di Marco Taradash', `la cronaca ... di Marina Ripa Di Meana'.
%% `marco' is a frame and `marina' a navy to the vocabulary, so the run was a
%% noun with adjectives, and `Di' a preposition inside it; the Spanish came
%% out right for `Marco' by the chance that its word for frame is `marco',
%% and was refused for the other. After a preposition with no article, a run
%% of capitalised words with a word no lesson knows in it is one name, a
%% capitalised small word inside it included. With an article, `della Regione
%% Lazio', it stays a noun with the name apposed to it (1.6.17); a time stays
%% a time, `Sabato Mladic'; and a word with a digit ends the run, `a Sky
%% Tg24 Tornaboni' being a channel and a speaker.
tr_particle_names(Side, later, [P, W1|Ws0], [P, w(Name, upper)|Ws]) :-
    P = w(PW, lower), tr_is(Side, P, preposition), \+ tr_solve(contraction_of(PW, _)),
    W1 = w(X1, upper), \+ tr_digit_word(W1), tr_known_word(Side, X1),
    \+ ( tr_lexeme(Side, X1, L1, _), ( tr_holds(month(L1)) ; tr_holds(time(L1)) ) ),
    tr_cap_run(Ws0, Run, Ws1), Run \== [],
    once(( member(W, Run), tr_name_word(Side, W) )), !,
    findall(C, ( member(w(X, _), [W1|Run]), tr_cap(X, C) ), Cs), atomic_list_concat(Cs, ' ', Name),
    tr_particle_names(Side, later, Ws1, Ws).
tr_particle_names(Side, _, [W|Ws0], [W|Ws]) :- tr_particle_names(Side, later, Ws0, Ws).

%% the capitalised words after a name's first, a word with a digit ending
%% them, and a small word only between two of them
tr_cap_run([w(S, upper), W|Ws0], [w(S, upper)|Run], Ws) :-
    memberchk(S, [di, de, da, del, van, von, du, der]), W = w(_, upper), \+ tr_digit_word(W), !,
    tr_cap_run([W|Ws0], Run, Ws).
tr_cap_run([W|Ws0], [W|Run], Ws) :-
    W = w(S, upper), \+ memberchk(S, [di, de, da, del, van, von, du, der]), \+ tr_digit_word(W), !,
    tr_cap_run(Ws0, Run, Ws).
tr_cap_run(Ws, [], Ws).

%% A MONTH IS WRITTEN SMALL IN BOTH LANGUAGES, and a capital on one is the
%% writer's slip, not a name: `un mes de Febrero muy apretado' came out
%% `un mese di Febrero', the Spanish word passed through as somebody's name
%% -- AND A DAY, which is a time to the lesson: `la cumbre europea de
%% Colonia, que comienza el Jueves' came out `il Giovedì', the capital kept
tr_month_lower(english, Ws, Ws) :- !.
tr_month_lower(_, [], []).
tr_month_lower(Side, [w(W, upper)|Ws0], [w(W, lower)|Ws]) :-
    tr_lexeme(Side, W, L, _), ( tr_holds(month(L)) ; tr_holds(time(L)) ), !, tr_month_lower(Side, Ws0, Ws).
tr_month_lower(Side, [W|Ws0], [W|Ws]) :- tr_month_lower(Side, Ws0, Ws).

tr_head_mark([w(W, Q)|Ws], Stop0, [w(W, upper)|Ws], Stop) :- memberchk(Q, [qopen, qopenu]), !, tr_stop_open(Stop0, Stop).
tr_head_mark(Ws, Stop, Ws, Stop).
%% ... AND A CLOSING MARK ON THE LAST WORD OF A QUOTATION THAT OPENED AT THE
%% HEAD IS THE SENTENCE'S TOO: `"servono nove miliardi, ma prima il
%% tribunale potrebbe cancellare il Napoli".' The mark took the word's
%% capital with it, so `Napoli' was no name and the sentence was refused.
%% Taken off, the word is a name where no lesson knows it and a plain word
%% where one does, and the mark goes back before the stop.
tr_tail_mark(Side, Ws0, Stop0, Ws, Stop) :-
    tr_stop_parts(Stop0, [_|_], [], _, _),
    append(Front, [w(W, Q)], Ws0), memberchk(Q, [qclose, qcloseu]), !,
    ( tr_known_word(Side, W) -> C = lower ; C = upper ),
    append(Front, [w(W, C)], Ws),
    tr_stop_parts(Stop0, B, [], S, A), Stop = marks(B, [34], S, A).
tr_tail_mark(_, Ws, Stop, Ws, Stop).
%% ... AND A CAPITAL ON THE EDGE OF A QUOTATION INSIDE THE SENTENCE IS A
%% NAME WHERE THE LESSON DOES NOT KNOW THE WORD: `que "España ve con
%% simpatía la candidatura"'. The name is spelled with its mark, as a name
%% of several words in marks already is (`dal "Washington Post"'), which no
%% lesson knows and every writer puts back as it stood; a word the lesson
%% knows is the plain word with its mark, as it was.
tr_quote_names(_, [], []).
tr_quote_names(Side, [w(W, C)|Ws0], [w(W1, C1)|Ws]) :-
    tr_name_edge(C, Plain, Pre, Post), !,
    (   tr_known_word(Side, W) -> W1 = W, C1 = Plain
    ;   tr_cap(W, WC), atomic_list_concat([Pre, WC, Post], W1), C1 = upper
    ),
    tr_quote_names(Side, Ws0, Ws).
tr_quote_names(Side, [X|Ws0], [X|Ws]) :- tr_quote_names(Side, Ws0, Ws).
tr_name_edge(qopenu, qopen, '"', '').
tr_name_edge(qcloseu, qclose, '', '"').
tr_name_edge(qbothu, qboth, '"', '"').
tr_stop_open(marks(B, S, A), marks([34|B], S, A)) :- !.
tr_stop_open(marks(B, I, S, A), marks([34|B], I, S, A)) :- !.
tr_stop_open(S, marks([34], [], S, [])).

tr_each_out([], _, []).
tr_each_out([ir(S, Stop)|Ss], Into, [Out|Outs]) :-
    tr_write_ir(Into, S, Stop, Out),
    tr_each_out(Ss, Into, Outs).

%% the target's lesson is set for EVERY sentence, because reading the one
%% before it may have set the source's
tr_write_ir(Into, S, Stop, Out) :-
    tr_side_of(Into, Side),
    tr_kind(Stop, Kind),
    tr_from_ir(Side, Kind, S, Stop, Out).

%% the side a language is read and written on: English is the IR's own,
%% and a lesson's language is the foreign side with that lesson set
tr_side_of(english, english) :- !.
tr_side_of(L, foreign) :- tr_into(L, from_english(L1)), tr_set_language(L1).

%% ... and the side a text is read on when the language was not named:
%% the words vote, as they do for reason_translate/2
tr_from_side(any, Words, Side) :- !, tr_way(any, Words, Side, _).
tr_from_side(english, Words, english) :- !, tr_english_language(Words).
tr_from_side(L, _, Side) :- tr_side_of(L, Side).

%% READING ENGLISH NEEDS A LESSON NAMED, because the English words the
%% reader knows are the ones some lesson gives a meaning for. The words
%% choose it, as they do for reason_translate/2; a text that fits two
%% lessons equally keeps whichever language is already set, which is what
%% makes reason_translate/4 exact -- it sets the target's first.
tr_english_language(Words) :-
    tr_language(L0),
    tr_languages(Ls),
    findall(v(L, F, E), ( member(L, Ls), tr_votes_in(L, Words, F, E) ), Vs),
    ( tr_winner(Vs, into, L1) -> tr_set_language(L1) ; tr_set_language(L0) ).

reason_learn(Text, Language, Terms) :-
    reason_text(Text, Terms),
    assert_once(lesson_language(Language)),
    forall(member(T, Terms), tr_learn_term(Language, T)),
    tr_mean_links(Terms, Links),
    forall(member(T, Links), tr_learn_term(Language, T)),
    forall(tr_hyphen_link(Terms, T), tr_learn_term(Language, T)).

%% A WORD WITH A HYPHEN IS FOUND BY THE WORDS THE TOKENISER READS IN IT. `a
%% corto-medio plazo' is in the short to medium term, and the tokeniser reads
%% the hyphen between two letters as a blank, so the text's words are `a',
%% `corto', `medio' and `plazo' -- which no join of them spells as the lesson
%% does. The lesson spells the word as the text does, and each such word is
%% kept under the spelling a join makes of it as well, hyphen_spelling(Blank,
%% Word), which tr_join_word/2 asks when the plain join is no word.
tr_hyphen_link(Terms, hyphen_spelling(B, W)) :-
    member(T, Terms), ( T = mean(W, _) ; T = plural_of(W, _) ),
    atom(W), sub_atom(W, _, 1, _, '-'), !,
    atomic_list_concat(Parts, '-', W), atomic_list_concat(Parts, ' ', B), B \== W.

%% A MEANING KEEPS THE CLASS ITS SENTENCE GAVE IT. `The noun "culpable"
%% means "culprit".' and `The adjective "culpable" means "guilty".' say two
%% things each, and the terms keep them apart -- noun(culpable),
%% mean(culpable, culprit), adjective(culpable), mean(culpable, guilty) --
%% so a lesson could say what a word means and what classes it has and never
%% which meaning belongs to which class, and the first meaning won wherever
%% one had to be chosen: `Los hombres son culpables' came out `The men are
%% culprit'. The sentence DID say it; the reader's terms come in sentence
%% order with the class before the meaning, so the class fact nearest before
%% a mean/2 of the same word is the class of that meaning, and it is kept
%% as mean_as(Word, Meaning, Class). tr_meanings_of/4 asks it first.
%%
%% AND A VERB'S MEANING THE SENTENCE CALLS INTRANSITIVE IS LINKED UNDER THAT
%% NAME TOO: `The intransitive verb "destaca" means "stands out".' is what the
%% verb means when its clause has no object. The adjective is the SENTENCE's,
%% as the class is -- the reader gives verb(destaca), intransitive(destaca),
%% mean(destaca, 'stands out'), the class, its adjectives, the claim -- so it
%% is kept with the class and spent on the one meaning after it. 1.7.0 linked
%% every verb meaning of a word some sentence of the same text called
%% intransitive, so `The verb "destaca" means "highlights".' beside it was
%% intransitive too, and what a store held depended on which 400 lines a
%% teach had read together.
tr_mean_links(Terms, Links) :- tr_mean_links(Terms, none, Links).
tr_mean_links([], _, []).
tr_mean_links([mean(W, E)|Ts], W0-C-As, [mean_as(W, E, C)|Ls0]) :- W == W0, !,
    (   C == verb, memberchk(intransitive, As) -> Ls0 = [mean_as(W, E, intransitive)|Ls]
    %% ... and one the sentence calls TRANSITIVE is what the verb means with a
    %% phrase for its object, kept under the MEANING so that the writer, which
    %% has the meaning in hand, finds it by an indexed lookup
    ;   C == verb, memberchk(transitive, As) -> Ls0 = [transitive_sense(E, W)|Ls]
    ;   Ls0 = Ls
    ),
    tr_mean_links(Ts, W0-C-[], Ls).
tr_mean_links([T|Ts], _, Ls) :-
    T =.. [C, W], atom(W), tr_link_class(C), !, tr_mean_links(Ts, W-C-[], Ls).
tr_mean_links([T|Ts], W0-C-As, Ls) :-
    T =.. [A, W], W == W0, !, tr_mean_links(Ts, W0-C-[A|As], Ls).
tr_mean_links([_|Ts], Last, Ls) :- tr_mean_links(Ts, Last, Ls).

tr_link_class(C) :- memberchk(C, [noun, adjective, verb, adverb, preposition, pronoun, conjunction, article,
                                  possessive, demonstrative, determiner, modal, auxiliary, number]).

%% A FACT GOES IN THE LANGUAGE'S OWN NAMESPACE, AND A RULE STAYS IN
%% lesson/2. `lesson(Language, Term)' put the language atom in the first
%% argument of every row, and cocolog's first-argument index keys on that
%% -- so with a vocabulary in the store every mean(casa, X) lookup walked
%% the whole language. Measured on 280 933 terms, Italian and Spanish in
%% one store: one sentence took over FOUR MINUTES of user CPU against
%% 0.348 s on a plain single-language store of the same vocabulary. A
%% fact is asserted as 'spanish:mean'(casa, house) instead, so the index
%% keys on `casa' exactly as a plain lesson's does. The rules are few --
%% a few dozen a lesson against a hundred thousand facts -- and they must
%% NOT become real clauses, because the engine would then resolve their
%% BODIES against the plain knowledge base rather than through
%% tr_body/2; so they stay as they were, and lesson/2 now holds nothing
%% else.
tr_learn_term(L, (H :- B)) :- !, assertz(lesson(L, (H :- B))).
tr_learn_term(L, T) :-
    tr_namespaced(L, T, F),
    functor(F, N, A), assert_once(lesson_predicate(N, L, A)),
    assertz(F).

%% a goal of a named lesson, under the language's own name -- the same
%% arguments, so the index sees what it saw when the lesson was plain
tr_namespaced(L, G, F) :-
    G =.. [Name|Args],
    tr_prefix(L, P), atom_concat(P, Name, N),
    F =.. [N|Args].

%% the prefix on and off: atom_concat/3 has the (+,-,+) mode that takes
%% it off, where atomic_list_concat/2 cannot split at all
tr_prefix(L, P) :- atom_concat(L, ':', P).

assert_once(G) :- ( tr_solve_plain(G) -> true ; assertz(G) ).

%% what a named lesson holds, and how to forget one: nothing outside this
%% file names a row's shape, which is what let the shape change
reason_lesson(L, T) :- tr_solve_plain(lesson_language(L)), tr_lesson_term(L, T).

tr_lesson_term(L, (H :- B)) :- tr_solve_plain(lesson(L, (H :- B))).
tr_lesson_term(L, T) :-
    tr_solve_plain(lesson_predicate(N, L, A)),
    functor(F, N, A), tr_solve_plain(F),
    tr_plain_term(L, F, T).

tr_plain_term(L, F, T) :-
    F =.. [N|Args],
    tr_prefix(L, P), atom_concat(P, Name, N), !,
    T =.. [Name|Args].

reason_unlearn(L) :-
    forall(tr_solve_plain(lesson_predicate(N, L, A)),
           ( functor(F, N, A), retractall(F) )),
    retractall(lesson_predicate(_, L, _)),
    retractall(lesson(L, _)),
    retractall(lesson_language(L)).

reason_untranslated(Text, Words) :- reason_untranslated(Text, any, Words).

%% AND NAMING THE LANGUAGE SKIPS THE VOTE AND THE ENGLISH SIDE WITH IT.
%% With `any' the words must settle a language, and settling one asks
%% tr_known_word(english, W) -- which is mean(_, W), the UNBOUND
%% direction, where the index keys 0 and skips nothing. Named, every
%% question is asked with the lesson's word bound, and the walk is gone.
%% The page path knows the language it was given, so it says so.
reason_untranslated(Text, From, Words) :-
    tr_pieces(Text, Pieces),
    findall(W, ( member(Piece0-_, Pieces), tr_caps_piece(Piece0, Piece), tr_piece_words(Piece, Ws0c),
                 tr_uncomma(Ws0c, Ws), tr_unknown_in(From, Ws, W) ),
            Ws0),
    list_to_set(Ws0, Words).

%% THE SIDE THE WORDS SETTLE IS WORKED OUT ONCE FOR THE PIECE, not once
%% per word. tr_way/4 runs the VOTE -- every language against every word,
%% both sides -- and asking it inside the per-word loop made this
%% quadratic in the words with the languages on top: measured over a
%% vocabulary of two languages, ONE four-word sentence cost 84 383 344
%% inferences and 64 SECONDS. The vote is one pass now, and the language
%% it settled is put back before each word is tested, because the
%% fallback below sets its own while it walks the languages.
tr_unknown_in(From, Ws, W) :-
    (   From \== any, catch(tr_side_of(From, S0), _, fail)
    ->  Side = S0, tr_language(Voted)
    ;   tr_way(any, Ws, F0, _)
    ->  Side = F0, tr_language(Voted)
    ;   Side = none, Voted = none
    ),
    tr_languages(Ls),
    ( Side == foreign -> tr_joined_words(foreign, Ws, Ws1) ; Ws1 = Ws ),
    member(w(W, Case), Ws1),
    ( \+ memberchk(Case, [upper, qopenu, qcloseu, qbothu]) ; en_question(W, _) ),
    tr_set_language(Voted),
    \+ tr_known_anywhere(Side, Ls, W).

%% known on the side the words settle, or, when they settle nothing, on
%% any side of any lesson; English's own function words are known
tr_known_anywhere(_, _, W) :- en_function(W), !.
tr_known_anywhere(Side, _, W) :- Side \== none, !, tr_known_word(Side, W).
tr_known_anywhere(_, Ls, W) :-
    member(L, Ls), tr_set_language(L),
    ( tr_known_word(foreign, W) ; tr_known_word(english, W) ), !.

%% into English, or into a language: one learned under that name, or the
%% plain lesson when it named itself so (`Spanish is a language')
tr_into(english, to_english) :- !.
tr_into(L, from_english(L)) :- atom(L), tr_solve_plain(lesson_language(L)), !.
tr_into(L, from_english(none)) :- atom(L), tr_solve_plain(language(L)), !.
tr_into(L, _) :- throw(error(domain_error(language, L), reason_translate/3)).

tr_each([], _, []).
tr_each([Piece-_|Ps], Way, Outs) :- tr_piece_words(Piece, []), !, tr_each(Ps, Way, Outs).
tr_each([Piece0-Stop|Ps], Way, [Out|Outs]) :-
    tr_caps_piece(Piece0, Piece),
    tr_piece_words(Piece, Words0), Words0 \== [],
    tr_way(Way, Words0, From, To),
    tr_quote_names(From, Words0, Words0n),
    tr_head_lower(From, Words0n, Words1),
    tr_joined_words(From, Words1, Words),
    tr_translate(Words, From, To, Stop, Out),
    tr_each(Ps, Way, Outs).

%% THE WORDS A SENTENCE IS READ IN: a word of several words joined, the
%% contractions expanded, and the joins made again. A word of several words
%% may CONTAIN a contraction -- `vigili del fuoco' (firefighters),
%% `dall'alto' (from above) -- and then it is only found before `del' is
%% `di il'; or it may be made of what a contraction expands to -- `fin
%% dalle prime ore' is `fin da' and `le' -- and then it is only found after.
%% Once each way, the longest join first both times.
tr_joined_words(Side, Words0, Words) :-
    tr_multi(Side, Words0, Words1),
    tr_expand(Side, Words1, Words2),
    tr_multi(Side, Words2, Words3),
    tr_enclitics(Side, Words3, Words4),
    tr_enclitic_multi(Side, Words4, Words5),
    tr_particles(Side, Words5, Words).

%% A PARTICLE A VERB TAKES BEFORE ITS PRONOUNS SAYS NOTHING OF ITS OWN: `Io la
%% risposta non ce l'ho' is I do not have the answer, and `ce' is the `ci'
%% Italian's `avere' takes before a pronoun, which no other language has a
%% word for. The lesson says which verb takes it -- `"ce" is the particle of
%% "ha".' -- and it goes where pronouns and then a form of that verb follow
%% it; nothing writes it back, and `l'ho' is Italian too.
tr_particles(english, Ws, Ws) :- !.
tr_particles(foreign, [], []) :- !.
tr_particles(foreign, [w(P, _)|Ws0], Ws) :-
    tr_solve(particle_of(P, V)), tr_particle_before(Ws0, V), !,
    tr_particles(foreign, Ws0, Ws).
tr_particles(foreign, [W|Ws0], [W|Ws]) :- tr_particles(foreign, Ws0, Ws).

tr_particle_before([w(C, _)|Ws], V) :-
    ( tr_object_pronoun(foreign, C, _) ; tr_solve(elision_of(C, F)), tr_object_pronoun(foreign, F, _) ), !,
    Ws = [W2|Ws2],
    (   W2 = w(X, _), once(tr_form(X, V, _, _, _)) -> true
    ;   tr_particle_before([W2|Ws2], V)
    ).

%% A VERB OF SEVERAL WORDS CARRIES ITS PRONOUN ON THE FIRST OF THEM: `senza
%% rendersi conto che ...' is without realizing that -- `rendere conto' is
%% one verb the lesson states (`The verb "rende conto" means "realizes".'),
%% and the reflexive cut off `rendersi' (tr_enclitics/3) stands between its
%% words, so the join, made before the pronoun came off, never saw them
%% together. Read apart, `conto che non importa loro ...' was an account that
%% did not matter to them. They are joined here, and the pronouns follow the
%% verb they belong to, as a one-word infinitive's do.
tr_enclitic_multi(english, Ws, Ws) :- !.
tr_enclitic_multi(foreign, [], []) :- !.
tr_enclitic_multi(foreign, [w(A, C), E1|Ws0], Out) :-
    E1 = w(_, enclitic),
    ( Ws0 = [E2|Ws1], E2 = w(_, enclitic) -> Es = [E1, E2] ; Es = [E1], Ws1 = Ws0 ),
    member(N, [3, 2, 1]), length(Ns, N), append(Ns, Rest, Ws1),
    forall(member(X, Ns), ( X = w(_, XC), memberchk(XC, [lower, upper]) )),
    tr_join_word([w(A, lower)|Ns], J), !,
    append([w(J, C)|Es], Out1, Out),
    tr_enclitic_multi(foreign, Rest, Out1).
tr_enclitic_multi(foreign, [W|Ws0], [W|Ws]) :- tr_enclitic_multi(foreign, Ws0, Ws).

%% AN INFINITIVE CARRIES ITS PRONOUNS JOINED TO IT: `riprenderli' is
%% `riprendere' and `li', `ritrovarsi' is `ritrovare' and `si', `essersi' is
%% `essere' and `si', and Spanish's `recuperarlos' is `recuperar' and `los'.
%% A word the lesson does not know is cut into an infinitive -- the front of
%% it, or the front with the `e' Italian drops before a pronoun put back --
%% and a pronoun the lesson lets stand before a verb, or its reflexive one.
%% The pronoun travels as w(Pronoun, enclitic), so the complement reader
%% knows whose it is. Spanish's infinitives end in `r', so the same two
%% tries read both languages and neither is named here.
tr_enclitics(english, Ws, Ws) :- !.
tr_enclitics(foreign, [], []).
tr_enclitics(foreign, [w(W, C)|Ws0], Out) :-
    memberchk(C, [lower, upper]), \+ tr_known_word(foreign, W),
    tr_enclitic_parts(W, C, Out, Ws), !,
    tr_enclitics(foreign, Ws0, Ws).
tr_enclitics(foreign, [W|Ws0], [W|Ws]) :- tr_enclitics(foreign, Ws0, Ws).

%% THE KNOWN-WORD TEST IS ASKED ONCE A WORD, and the ways to cut the word
%% are tried after it. Written as a clause of tr_enclitics/3 each, every way
%% asked it again, so a word the lesson knows paid it once for each way --
%% and the third way, the gerund's, cost Tatoeba's 400 sentences 302 000
%% inferences of 35.1 million. Asked once, they cost 363 000 fewer, every
%% text the same.
tr_enclitic_parts(W, C, [w(Inf, C), w(Cl, enclitic)|Ws], Ws) :- tr_enclitic_split(W, Inf, Cl), !.
%% ... AND TWO OF THEM, the stem accented where the pair moved its stress:
%% `jugárselo' is `jugar', `se' and `lo', and Spanish writes the accent the
%% longer word needs. The accent comes off before the infinitive is looked
%% for.
tr_enclitic_parts(W, C, [w(Inf, C), w(Cl1, enclitic), w(Cl2, enclitic)|Ws], Ws) :-
    atom(W), member(N2, [2, 3]), sub_atom(W, B2, N2, 0, Cl2), B2 > 1, sub_atom(W, 0, B2, _, W1),
    tr_enclitic_word(Cl2),
    member(N1, [2, 3]), sub_atom(W1, B1, N1, 0, Cl1), B1 > 1, sub_atom(W1, 0, B1, _, Stem0),
    tr_enclitic_word(Cl1),
    tr_unaccent(Stem0, Stem),
    ( Inf = Stem ; atom_concat(Stem, e, Inf) ),
    tr_solve(infinitive_of(Inf, F)), tr_known(foreign, F), !.
%% ... AND A GERUND CARRIES ITS PRONOUN JOINED TO IT TOO: `fue entonándose'
%% is `entonando' and `se', the stem accented where the longer word moved
%% its stress, as `jugárselo' is
tr_enclitic_parts(W, C, [w(Stem, C), w(Cl, enclitic)|Ws], Ws) :-
    atom(W), member(N, [2, 3]), sub_atom(W, B, N, 0, Cl), B > 3, sub_atom(W, 0, B, _, Stem0),
    tr_enclitic_word(Cl), tr_unaccent(Stem0, Stem),
    tr_solve(gerund_of(Stem, F)), tr_known(foreign, F), !.

%% the vowels a written accent marks, back to plain: á é í ó ú, the UTF-8
%% bytes 195 and 161, 169, 173, 179, 186
tr_unaccent(W, P) :-
    atom_codes(W, Cs), tr_unaccent_codes(Cs, Ps), atom_codes(P, Ps).
tr_unaccent_codes([], []).
tr_unaccent_codes([195, B|Cs], [V|Ps]) :- memberchk(B-V, [161-0'a, 169-0'e, 173-0'i, 179-0'o, 186-0'u]), !,
    tr_unaccent_codes(Cs, Ps).
tr_unaccent_codes([C|Cs], [C|Ps]) :- tr_unaccent_codes(Cs, Ps).

%% (atom_concat/3 has no mode that splits an atom here: sub_atom/5 does, the
%% pronoun two or three letters long)
%% ... and a verb in `-rre' drops both letters: `porsi la stessa domanda'
%% is `porre' and `si', to ask oneself the question
tr_enclitic_split(W, Inf, Cl) :-
    atom(W), member(N, [2, 3]), sub_atom(W, B, N, 0, Cl), B > 1, sub_atom(W, 0, B, _, Stem),
    tr_enclitic_word(Cl),
    ( Inf = Stem ; atom_concat(Stem, e, Inf) ; sub_atom(Stem, _, 1, 0, r), atom_concat(Stem, re, Inf) ),
    tr_solve(infinitive_of(Inf, F)), tr_known(foreign, F), !.

tr_enclitic_word(Cl) :- tr_reflexive_word(Cl), !.
tr_enclitic_word(Cl) :- tr_object_pronoun(foreign, Cl, _), \+ tr_tonic_word(Cl), tr_holds(precede(Cl, verb)), !.

%% a contraction the lesson states -- `"al" is the contraction of "a el"' --
%% is read as its words, and written back as itself (tr_contract/3)
tr_expand(english, Ws, Ws) :- !.
tr_expand(foreign, [], []).
%% a comma is carried through untouched: it is no word and has nothing to
%% expand, and the clause splitter still needs to see it
tr_expand(foreign, [comma|Ws], [comma|Out]) :- !, tr_expand(foreign, Ws, Out).
tr_expand(foreign, [semicolon|Ws], [semicolon|Out]) :- !, tr_expand(foreign, Ws, Out).
%% AN ELIDED CONTRACTION IS UN-ELIDED FIRST: `dell'' is `della', which is
%% then read as its two words. Which of the forms an elision stands for is
%% taken as the first stated -- `dell'' elides `dello' and `della' alike --
%% because the two expand to the same preposition and the NOUN decides the
%% gender on the way out.
%% ... AND ITS ARTICLE STAYS ELIDED WHERE THE LESSON ELIDES IT: `dall'altra'
%% is `da' and `l'', never `da lo', because `lo' standing before `altra' is
%% the pronoun `him' -- measured, `è andata dall'altra' came out `ha ido
%% desde él otros'. The elided article is the lesson's word for both.
tr_expand(foreign, [w(W, C)|Ws], Out) :-
    tr_solve(elision_of(W, F)), tr_solve(contraction_of(F, J)),
    atomic_list_concat([P1, A], ' ', J), tr_solve(elision_of(E, A)), !,
    tr_expand(foreign, Ws, Out1),
    Out = [w(P1, C), w(E, lower)|Out1].
tr_expand(foreign, [w(W, C)|Ws], Out) :-
    tr_solve(elision_of(W, F)), tr_solve(contraction_of(F, _)), !,
    tr_expand(foreign, [w(F, C)|Ws], Out).
tr_expand(foreign, [w(W, C)|Ws], Out) :-
    tr_solve(contraction_of(W, J)), atomic_list_concat([P1|Ps], ' ', J), Ps \== [], !,
    findall(w(P, lower), member(P, Ps), Rest), tr_expand(foreign, Ws, Out1),
    append([w(P1, C)|Rest], Out1, Out).
%% AN ABSOLUTE SUPERLATIVE IS THE LESSON'S WORD FOR `very' AND THE PLAIN
%% FORM: `le pesantissime accuse' is the very heavy accusations. The
%% lesson states it -- `"pesantissime" is the superlative of "pesanti".',
%% the builder's line -- and read as two words it is the intensifier a
%% phrase already carries (`una familia tan pacífica'), so every writer
%% has it: `muy pesadas' and `very heavy'. English has no such form.
tr_expand(foreign, [w(W, C)|Ws], Out) :-
    tr_solve(superlative_of(W, B)), tr_solve(mean(V, very)), tr_solve(adverb(V)), !,
    tr_expand(foreign, Ws, Out1),
    Out = [w(V, C), w(B, lower)|Out1].
tr_expand(foreign, [W|Ws], [W|Out]) :- tr_expand(foreign, Ws, Out).

%% A WORD OF SEVERAL WORDS IS ONE WORD WHEN THE LESSON KNOWS IT AS ONE:
%% `junto a' (along with), `lavado de cerebro' (brainwashing), `tiene que'
%% (must), `c'è'. A lesson could always STATE one -- `The masculine noun
%% "toque de queda" means "curfew".' -- and the writer wrote it, but the
%% reader cut the text into single words and never put them back together,
%% so a multi-word word was write-only. Adjacent plain words are joined,
%% the LONGEST first (five, four, three, two -- `al fin y al cabo', after
%% all, is five), wherever the lesson knows the
%% joined form as a word; after a contraction is expanded, so `junto al'
%% is `junto a' and `el'. A word ending in an apostrophe joins with no space
%% (`c'' and `è' are `c'è'). Only on the lesson's side: English's own
%% multi-word forms (`there is') have readers of their own.
tr_multi(english, Ws, Ws) :- !.
tr_multi(foreign, [], []) :- !.
tr_multi(foreign, Ws0, [w(J, C)|Ws]) :-
    Ws0 = [w(_, C)|_],
    member(N, [5, 4, 3, 2]), length(Ns, N), append(Ns, Rest, Ws0),
    tr_multi_cases(Ns),
    tr_join_word(Ns, J), !,
    tr_multi(foreign, Rest, Ws).
%% ... AND ONE WHOSE LAST WORD CAME CONTRACTED WITH THE ARTICLE AFTER IT:
%% `alla luce della struttura' is `alla luce di' and `la struttura'. Before
%% the contractions are expanded the last word is `della', and after it the
%% first is `a la' -- so neither pass found the word, and the phrase was read
%% as `a la luz de ella'. Here the last word alone is expanded.
tr_multi(foreign, Ws0, [w(J, C), w(A, lower)|Ws]) :-
    Ws0 = [w(_, C)|_],
    member(N, [4, 3, 2]), length(Ns, N), append(Ns, Rest, Ws0),
    forall(member(X, Ns), ( X = w(_, XC), memberchk(XC, [lower, upper]) )),
    append(Front, [w(K, _)], Ns), tr_solve(contraction_of(K, KJ)), atomic_list_concat([P, A], ' ', KJ),
    append(Front, [w(P, lower)], Ns1), tr_join_word(Ns1, J), !,
    tr_multi(foreign, Rest, Ws).
tr_multi(foreign, [W|Ws0], [W|Ws]) :- tr_multi(foreign, Ws0, Ws).

%% the words of a join are plain words -- and the FIRST may open a quotation,
%% whose mark the join then carries: `"Hay que tomar precauciones", dijo.'
tr_multi_cases([w(_, C)|Ns]) :-
    memberchk(C, [lower, upper, qopen]),
    forall(member(X, Ns), ( X = w(_, XC), memberchk(XC, [lower, upper]) )).

%% the words joined into a word the lesson states: as the join spells it, or
%% as the lesson spells it with a hyphen where the join has a blank
tr_join_word(Ns, J) :-
    tr_joined(Ns, J0),
    ( tr_stated_word(J0) -> J = J0 ; tr_solve(hyphen_spelling(J0, J)) ).

%% A WORD OF SEVERAL WORDS IS ALWAYS STATED -- its meaning, and each form
%% of it (`"lavados de cerebro" is the plural of "lavado de cerebro"'),
%% because no ending rule makes the plural of a phrase -- so the join asks
%% the relations a form is stated in and nothing else. Asked through
%% tr_known_word/2, every join that is NO word walked the ending rules and
%% the tenses too, and the joins cost a Tatoeba run 1.8 s of its 26.
tr_stated_word(J) :-
    member(G, [mean(J, _), plural_of(J, _), person_of(J, _), past_of(J, _), future_of(J, _),
               participle_of(J, _), gerund_of(J, _), infinitive_of(J, _), conditional_of(J, _),
               subjunctive_of(J, _), imperative_of(J, _), elision_of(J, _), contraction_of(J, _)]),
    tr_solve(G), !.

tr_joined([w(A, _)], A) :- !.
tr_joined([w(A, _)|Ws], J) :-
    tr_joined(Ws, J1),
    ( sub_atom(A, _, 1, 0, '\'') -> atom_concat(A, J1, J) ; atomic_list_concat([A, ' ', J1], J) ).

tr_contract(english, Os, Os) :- !.
tr_contract(foreign, [o(W1, C1), o(W2, C2)|Os], Out) :-
    atomic_list_concat([W1, W2], ' ', J), tr_solve(contraction_of(K, J)), !,
    tr_join_case(C1, C2, C),
    tr_contract(foreign, [o(K, C)|Os], Out).
%% ... and a word of several words contracts by its LAST word: `junto a el
%% Rescate Alpino' is `junto al Rescate Alpino'
tr_contract(foreign, [o(W1, C1), o(W2, C2)|Os], Out) :-
    atom(W1), sub_atom(W1, B, 1, A, ' '), sub_atom(W1, _, A, 0, Last), \+ sub_atom(Last, _, _, _, ' '),
    atomic_list_concat([Last, W2], ' ', J), tr_solve(contraction_of(K, J)), !,
    sub_atom(W1, 0, B, _, Pre), atomic_list_concat([Pre, K], ' ', W),
    tr_join_case(C1, C2, C),
    tr_contract(foreign, [o(W, C)|Os], Out).
%% AND AN ELIDED FORM IS WRITTEN WHEN A VOWEL FOLLOWS, joined to the word
%% after it: `la incolumita' is `l'incolumita'. It comes AFTER the
%% contraction above, so `di la' is `della' first and `dell'' second --
%% which is why the lesson states the elision of the contracted forms
%% (`"dell'" is the elision of "della"') and not of their parts.
%% ... AND A CAPITAL AFTER THE ELISION IS KEPT: the joined word takes the
%% elided word's case, so `de Adjaria' came out `d'adjaria' and `a la Unión'
%% `all'unione'
tr_contract(foreign, [o(W1, C1), o(W2, C2)|Os], Out) :-
    tr_solve(elision_of(E, W1)), begin_with(W2, vowel), !,
    ( C2 == upper -> tr_cap(W2, W2C) ; W2C = W2 ),
    atom_concat(E, W2C, J), tr_join_case(C1, C2, C),
    tr_contract(foreign, [o(J, C)|Os], Out).
tr_contract(foreign, [O|Os], [O|Out]) :- tr_contract(foreign, Os, Out).
tr_contract(foreign, [], []).

%% TWO WORDS JOINED KEEP THE MARK THE SECOND ONE CLOSED: a quotation mark
%% travels in a word's case (tr_word_text/4), and the join kept the first
%% word's alone -- `"Procesad al obispo".' came out `"Processate
%% l'alfiere.', the elided article taking the noun that closed the quote
tr_join_case(qopen, C2, qboth) :- memberchk(C2, [qclose, qboth]), !.
tr_join_case(_, qclose, qclose) :- !.
tr_join_case(C1, _, C1).

%% the first word's capital is the sentence's, not the word's: a known
%% word at the head goes lower, so that when a question moves it it is
%% not `Es'; a name keeps its case
%% ... but not the first word of a NAME: `Monte Livata, ritrovati vivi' --
%% a capitalised NOUN the lesson knows before a word it does not is a
%% place's name, and lowered it was a mountain with a stranger's name after
%% it. A noun and nothing a verb: `¿Come Maria el pan?' is a verb and a
%% name, and kept capitalised the verb could not start the group.
%% NOR A TIME: `Sabato Mladic aveva spedito un fax' is a day and a surname,
%% and kept capitalised `Sabato' took `Mladic' for the name apposed to it
%% (tr_apposed_name/3), so the sentence read as a time phrase `Saturday
%% Mladic' and a subject nobody named. A day is lower case inside an
%% Italian or a Spanish sentence, so the capital at the head is the
%% sentence's -- and the lesson's `"sabato" is a time.' is what says so.
tr_head_lower(From, [w(W, upper)|Ws], [w(W, lower)|Ws]) :-
    ( tr_known_word(From, W) ; en_function(W) ),
    \+ ( Ws = [w(N, upper)|_], \+ tr_known_word(From, N), tr_name_head(From, W) ), !.
tr_head_lower(_, Ws, Ws).

tr_name_head(From, W) :-
    tr_lexeme(From, W, L, _), tr_class(From, L, noun), \+ tr_class(From, L, verb),
    \+ tr_time_lexeme(From, L), !.

%% a lexeme the lesson calls a time: its own word, or on the English side a
%% word of the lesson's that means it
tr_time_lexeme(foreign, L) :- tr_holds(time(L)), !.
tr_time_lexeme(english, E) :- tr_solve(mean(W, E)), tr_holds(time(W)), !.

%% ---- the sentences, and their words ------------------------------------------

%% the text cut at `.', `!' and `?', each piece with the stop it ended on
%% (`.' when it had none), the blank ones dropped
tr_pieces(Text, Pieces) :-
    tr_memo_reset,
    tr_codes(Text, Codes), tr_split(Codes, Pieces0), tr_quote_pieces(Pieces0, Pieces1),
    tr_speech_pieces(Pieces1, Pieces).

%% A SENTENCE IN QUOTATION MARKS: `"¿Cómo ha podido salir así?".' The mark
%% opens before the sentence and closes after its stop, so the splitter cut
%% `"¿Cómo ... así' with `?' and then `"' with `.' -- and the first piece read
%% as ONE quoted token, `¿' and all, while the second had no word at all.
%% The marks belong to the SENTENCE: they come off before its words are read
%% and go back round the translation, carried in the stop as
%% marks(Before, Stop, After), which tr_kind/2 and tr_join/5 look through.
tr_quote_pieces([], []).
tr_quote_pieces([P0-S0, P1-S1|Ps], [P-marks(Open, S0, Close)|Out]) :-
    integer(S0), tr_opening_mark(P0, Open, P), tr_closing_only(P1, Close0), !,
    append(Close0, [S1], Close),
    tr_quote_pieces(Ps, Out).
tr_quote_pieces([P-S|Ps], [P-S|Out]) :- tr_quote_pieces(Ps, Out).

%% a piece that opens with a quotation mark and never closes it
tr_opening_mark(Codes, Mark, Rest) :-
    tr_skip_blank(Codes, C1), tr_quote_mark(open, Mark, C1, Rest), Rest \== [],
    \+ ( append(_, Tail, Rest), tr_quote_mark(close, _, Tail, _) ).
%% a piece that is nothing but the closing mark
tr_closing_only(Codes, Mark) :-
    tr_skip_blank(Codes, C1), tr_quote_mark(close, Mark, C1, Rest), tr_blank(Rest).

tr_skip_blank([C|Cs], Out) :- C =< 32, !, tr_skip_blank(Cs, Out).
tr_skip_blank(Cs, Cs).

%% the marks: the plain one either way, the typographic pair (U+201C and
%% U+201D, three bytes each in UTF-8) and the angled pair (U+00AB, U+00BB)
tr_quote_mark(_, [34], [34|Rest], Rest).
tr_quote_mark(open, [226, 128, 156], [226, 128, 156|Rest], Rest).
tr_quote_mark(close, [226, 128, 157], [226, 128, 157|Rest], Rest).
tr_quote_mark(open, [194, 171], [194, 171|Rest], Rest).
tr_quote_mark(close, [194, 187], [194, 187|Rest], Rest).

%% the sentence's text with its stop, and its marks when it carries any
tr_stop_text(P, Stop, Sentence) :-
    tr_stop_parts(Stop, Before, Inner, S, After),
    atom_codes(P, Cs), append(Before, Cs, C1), append(C1, Inner, C1b), append(C1b, [S|After], C2),
    atom_codes(Sentence, C2).

%% the marks: Before the text, Inner between the text and its stop -- an
%% Italian quotation closes BEFORE the full stop, `funziona”.' -- and After
tr_stop_parts(marks(Before, S, After), Before, [], S, After) :- !.
tr_stop_parts(marks(Before, Inner, S, After), Before, Inner, S, After) :- !.
tr_stop_parts(S, [], [], S, []).

%% DIRECT SPEECH RUNS OVER SENTENCES, AND ITS MARKS ARE THE SENTENCES'.
%% `“Due bambini ... sono due eroi. È stato difficile riprenderli perché
%% erano incastrati in un dirupo” ha raccontato a Sky Tg24 Tornaboni.' opens
%% a quotation in one sentence and closes it in the next, and the tokeniser
%% saw neither half: an opening mark with no closing one in its piece ran as
%% ONE quoted token to the end of the piece -- commas stuck to their words,
%% `anni,' and `condizioni,' refused as unknown -- and a closing mark with
%% no opening one was dropped as punctuation, so the reporting clause after
%% it ran on into the quotation and nothing could read either.
%%
%% So the marks are taken off the piece before a word is read, and each
%% goes where it belongs. An opening mark at the HEAD of a piece goes in
%% front of the sentence, and a closing mark at its END between the text
%% and its stop, as the source had it (`funziona”.') -- both carried in the
%% stop, as tr_quote_pieces/2 carries a quoted question's. A closing mark
%% in the MIDDLE is where the quotation ends and a reporting clause begins,
%% a boundary the clause reader divides at (code 1, read as `endquote'). An
%% opening mark in the middle whose quotation does not close in the piece
%% (`spiegando che “si sono adoperate ...') marks the word after it (code
%% 2). A pair of marks inside one piece -- `parla di “miracolo”', `"dal
%% punto di vista tattico"' -- is left to the tokeniser as the quoted words
%% it always was. The plain mark opens and closes alike, so where it stands
%% says which (tr_speech_mark/4), and its closing one is code 7, read as
%% `endquote_plain' and written back as itself.
%%
%% A DASH BETWEEN WORDS IS A BOUNDARY TOO: `bisognerebbe sapere come sono
%% finiti lì – ha spiegato un soccorritore -.' sets its reporting clause
%% off with dashes, and the tokeniser dropped them as punctuation. An en or
%% em dash, and a hyphen with a blank before it and none of a word after
%% it, is code 3, read as `dash'. And a COLON divides a sentence's clauses
%% as a semicolon does -- `Le condizioni generali sono ottime: ridono,
%% scherzano, raccontano.' -- where the tokeniser dropped it too: code 4,
%% read as `colon'.
tr_speech_pieces([], []).
tr_speech_pieces([P0-S0|Ps], [P-S|Out]) :-
    %% (the marks in the MIDDLE are the text's whatever its stop: a piece
    %% that ends in `...' carries marks/4 for a stop, and `Tutta una serie di
    %% problemi (privatizzazioni, ...) vengono del tutto trascurati ...' lost
    %% its parentheses -- `una serie de privatizaciones problemas')
    ( integer(S0) -> tr_speech_piece(P0, S0, P, S) ; tr_mid_marks(P0, P), S = S0 ),
    tr_speech_pieces(Ps, Out).

tr_speech_piece(P0, S0, P, S) :-
    tr_head_open(P0, Before, P1),
    tr_tail_close(P1, Inner, P2),
    tr_mid_marks(P2, P),
    ( Before == [], Inner == [] -> S = S0 ; S = marks(Before, Inner, S0, []) ).

%% an opening mark at the head of the piece, and the piece without it --
%% a plain one only when nothing in the piece closes it, or a pair at the
%% head (`"Hola", dijo Tom') would lose its first mark and keep its second
tr_head_open(P0, Mark, P) :-
    tr_skip_blank(P0, C1), tr_speech_mark(open, Mark, C1, P),
    \+ ( Mark == [34], append(_, R, P), tr_speech_mark(close, [34], R, _) ), !.
%% ... and a CLOSING mark at the head, which closes nothing in its piece: a
%% text cut into sentences after each stop hands the mark that ends one
%% quotation to the sentence after it (`” Aspetto questo giorno ...'), and
%% read as a boundary in the middle it left nothing before it to be a
%% clause. It goes back where it stood, in front of the sentence.
tr_head_open(P0, Mark, P) :-
    tr_skip_blank(P0, C1), tr_speech_mark(close, Mark, C1, P), !.
tr_head_open(P, [], P).

%% a closing mark at its end, with no opening mark before it that it closes
tr_tail_close(P0, Mark, P) :-
    tr_trim_blank_end(P0, P1),
    append(P, M, P1), tr_speech_mark(close, Mark, M, []),
    \+ tr_opens_unclosed(P), !.
tr_tail_close(P, [], P).

tr_trim_blank_end(Cs, Ds) :- append(Ds, Sp, Cs), \+ ( member(C, Sp), C > 32 ), ( Ds = [] ; last(Ds, L), L > 32 ), !.

%% an opening mark in these codes that no closing mark after it closes
tr_opens_unclosed(Cs) :-
    append(_, Rest, Cs), tr_speech_mark(open, _, Rest, After),
    \+ ( append(_, R2, After), tr_speech_mark(close, _, R2, _) ), !.

%% the marks and dashes in the middle, each as its code: a closing mark
%% nothing before it opened, an opening mark nothing after it closes, a
%% dash; a pair of marks is left as it stands
tr_mid_marks([], []).
tr_mid_marks(Cs, Out) :-
    tr_speech_mark(close, M, Cs, Rest), !,
    ( M == [34] -> K = 7 ; K = 1 ), Out = [K|More], tr_mid_marks(Rest, More).
tr_mid_marks(Cs, Out) :-
    tr_speech_mark(open, M, Cs, Rest), !,
    (   append(Mid, R2, Rest), tr_speech_mark(close, C, R2, R3)
    ->  append(M, Mid, O1), append(O1, C, O2), append(O2, More, Out), tr_mid_marks(R3, More)
    ;   Out = [2|More], tr_mid_marks(Rest, More)
    ).
tr_mid_marks([226, 128, D|Cs], [3|More]) :- ( D == 147 ; D == 148 ), !, tr_mid_marks(Cs, More).
tr_mid_marks([C0, 45|Cs], [C0, 3|More]) :- C0 =< 32, \+ ( Cs = [D|_], D > 32 ), !, tr_mid_marks(Cs, More).
tr_mid_marks([D1, 58, D2|Cs], [D1, 58|More]) :- rt_digit(D1), rt_digit(D2), !, tr_mid_marks([D2|Cs], More).   % `20:45'
tr_mid_marks([58|Cs], [4|More]) :- !, tr_mid_marks(Cs, More).                  % 58 is `:'
tr_mid_marks([40|Cs], [5|More]) :- !, tr_mid_marks(Cs, More).                  % 40 is `('
tr_mid_marks([41|Cs], [6|More]) :- !, tr_mid_marks(Cs, More).                  % 41 is `)'
tr_mid_marks([C|Cs], [C|More]) :- tr_mid_marks(Cs, More).

%% the marks this reads: the typographic pair and the angled pair
tr_speech_mark(open, [226, 128, 156], [226, 128, 156|Rest], Rest).
tr_speech_mark(close, [226, 128, 157], [226, 128, 157|Rest], Rest).
tr_speech_mark(open, [194, 171], [194, 171|Rest], Rest).
tr_speech_mark(close, [194, 187], [194, 187|Rest], Rest).
%% ... AND THE PLAIN ONE, WHICH OPENS AND CLOSES ALIKE, SO WHERE IT STANDS
%% SAYS WHICH. El Periódico writes `"No es posible hacer una réplica ...
%% sin que un experto lo note.' and, a sentence later, `son únicos ", dijo
%% Claude Lebet' -- a quotation over two sentences in the mark a keyboard
%% has, with a blank before the closing one. A mark with a word right after
%% it opens; one with a blank, a stop, a comma or nothing after it closes.
%% The blank BEFORE a mark says nothing, because this source puts one on
%% both sides. Read as the typographic pair is read, the opening one goes
%% in front of its sentence and the closing one divides the quotation from
%% the clause that reports it; a pair inside one piece is left as it stood.
tr_speech_mark(open, [34], [34|Rest], Rest) :- Rest = [C|_], tr_word_code(C).
tr_speech_mark(close, [34], [34|Rest], Rest) :- \+ ( Rest = [C|_], tr_word_code(C) ).

%% a code a word can begin with: anything but a blank, a closing
%% punctuation mark or another quotation mark (`¿' and `¡' are 194, 191 and
%% 194, 161, so their first byte passes)
tr_word_code(C) :- C > 32, \+ memberchk(C, [33, 34, 41, 44, 46, 58, 59, 63]).

%% A PIECE'S WORDS, AND WHAT THE TOKENISER WOULD HAVE THROWN AWAY. Two
%% marks carry structure the reader needs and reason_tokens/2 drops:
%%
%% A SEMICOLON divides a sentence's clauses more strongly than a comma --
%% `se les llamará muchachos conflictivos; en los de clase media, chicos
%% difíciles' -- and the tokeniser drops it with no trace, so the clause
%% boundary went with it. The piece is cut at each `;' and the parts'
%% words joined by the atom `semicolon', which the clause splitter reads
%% as it reads a comma and the writer puts back.
%%
%% A HYPHEN INSIDE A CAPITALISED NAME is part of the name: `Jean-Pierre
%% Chevènement'. The tokeniser cut it into `jean' and `pierre' and lowered
%% both, so the name came back `Jean Pierre' at best. A capitalised run
%% with a hyphen between two letters is ONE word, spelled as the text
%% spelled it, which no lesson knows -- so it is a name, crosses as itself
%% and is written back whole. A lower-case hyphenated word is left to the
%% tokeniser, as before.
tr_piece_words(Piece, Words) :-
    tr_cut_seps(Piece, Parts),
    tr_parts_words(Parts, Words).

%% the piece cut at every boundary the tokeniser would drop, Codes, Sep,
%% Codes, ...: a semicolon, and the codes tr_speech_pieces/2 put in
tr_cut_seps(Codes, Parts) :-
    (   append(Before, [C|After], Codes), tr_sep_code(C, Sep)
    ->  Parts = [Before, Sep|More], tr_cut_seps(After, More)
    ;   Parts = [Codes]
    ).

tr_sep_code(59, semicolon).                                            % 59 is `;'
tr_sep_code(1, endquote).
tr_sep_code(7, endquote_plain).
tr_sep_code(3, dash).
tr_sep_code(4, colon).
tr_sep_code(5, lparen).
tr_sep_code(6, rparen).

%% a semicolon with nothing on one side of it is nothing; every other
%% boundary is kept where it stood, a dash that closes a clause included
%% -- and TWO DASHES WITH NOTHING BETWEEN THEM ARE ONE: AnCora spells an em
%% dash as two hyphens, `una inmensa luna - - el personaje principal ... - -
%% son dos de los elementos', and each pair is the one dash an editor wrote
tr_parts_words([P], Ws) :- !, tr_part_words(P, Ws).
tr_parts_words([P, Sep|Ps], Ws) :-
    tr_part_words(P, W1), tr_parts_words(Ps, W2),
    (   Sep == semicolon, W1 == [] -> Ws = W2
    ;   Sep == semicolon, W2 == [] -> Ws = W1
    ;   Sep == dash, W2 = [dash|_] -> append(W1, W2, Ws)
    ;   append(W1, [Sep|W2], Ws)
    ).

%% an opening mark whose quotation runs on past the piece marks the word
%% after it, which the writer gives the mark back
tr_part_words(Codes, Ws) :-
    append(Pre, [2|Post], Codes), !,
    tr_part_words(Pre, W1), tr_part_words(Post, W2),
    ( W2 = [w(W, C)|W3] -> tr_edge_case(C, qopen, Q), W2q = [w(W, Q)|W3] ; W2q = W2 ),
    append(W1, W2q, Ws).
%% A QUOTATION INSIDE A PIECE IS WORDS OF THE SENTENCE, READ AS WORDS. A
%% pair of marks was left to reason_tokens/2, which reads what stands
%% between them as ONE mentioned token -- the right reading for a lesson's
%% `"casa"' and the wrong one for newspaper prose, which quotes a whole
%% clause: `del 100% di Chrysler “ci permetterà di realizzare ... un
%% bagaglio di esperienze, punti di vista e competenze unico al mondo”'.
%% The token was then cut at its blanks and nothing else, so `esperienze,'
%% was a word with its comma on it and the sentence was refused for it; an
%% apostrophe, a written number and a hyphenated name inside the marks
%% were never read either. So the text between the marks is read by these
%% same clauses, as any other part of the piece is, and the marks go back
%% on its first and last words, which is the shape a quoted run already
%% had: qboth for one word, qopen and qclose round several.
tr_part_words(Codes, Ws) :-
    append(Pre, Rest, Codes), tr_quote_mark(open, OM, Rest, In0),
    append(Inside, Rest2, In0), tr_quote_mark(close, CM, Rest2, Post), !,
    tr_pre_words(Pre, W1), tr_part_words(Inside, WI0), tr_part_words(Post, W2),
    %% A NAME IN QUOTATION MARKS IS ONE NAME: `dal "Washington Post"'. The
    %% marks on the run's edges took the place of its words' capitals, which
    %% were what said it was a name, and the sentence was refused for two
    %% unknown words. Every word capitalised, two at least: one token, the
    %% name spelled as the text spelled it, marks and all, which no lesson
    %% knows and every writer puts back as it stood. One capitalised word is
    %% left a word: `la "Bastiglia"' is a word the lesson may know.
    (   WI0 = [_, _|_], forall(member(X, WI0), X = w(_, upper))
    ->  tr_trim_blank_end(Inside, In1), tr_skip_blank(In1, In2),
        append([OM, In2, CM], NCs), atom_codes(Name, NCs), WI = [w(Name, upper)]
    ;   tr_quote_edges(WI0, WI)
    ),
    append(W1, WI, W12), append(W12, W2, Ws).
%% ... AND AN ELIDED WORD BEFORE THE MARK KEEPS ITS APOSTROPHE: `nella
%% cronaca dell'"Assalto a Palazzo Farnese"' elides the article before a
%% title in marks. Cut at the mark, the words before it ended in the
%% apostrophe, which ends a word only when a letter follows it, so the
%% tokeniser dropped it and left `dell', a word no lesson knows
tr_pre_words(Pre, Ws) :-
    ( append(Pre0, [39], Pre) ; append(Pre0, [226, 128, 153], Pre) ),
    last(Pre0, C), rt_alpha(C), !,
    tr_part_words(Pre0, Ws0),
    (   append(Ws1, [w(W, WC)], Ws0)
    ->  atom_concat(W, '\'', WA), append(Ws1, [w(WA, WC)], Ws)
    ;   Ws = Ws0
    ).
tr_pre_words(Pre, Ws) :- tr_part_words(Pre, Ws).

%% A NUMBER IS WRITTEN BACK AS THE SOURCE WROTE IT. The tokeniser reads
%% `1.400' as the decimal 1.4 and drops the sign of `-10', which is right
%% for a sentence the reasoner reads and wrong for one a translator writes
%% back: Italian and Spanish both write a thousand and four hundred as
%% `1.400', and the sign of `-10 gradi' is the temperature. So a number with
%% a separator or a sign is taken out before the tokeniser sees it and
%% travels as ONE word, spelled as the text spelled it, which tr_digits/1
%% knows for a number. A bare run of digits is the tokeniser's, as before.
tr_part_words(Codes, Ws) :-
    tr_written_number(Codes, Pre, Num, Post), !,
    tr_part_words(Pre, W1), tr_part_words(Post, W2),
    append(W1, [w(Num, lower)|W2], Ws).
tr_part_words(Codes, Ws) :-
    (   ( memberchk(0'-, Codes) ; tr_inner_capital(Codes)
        ; tr_two_capitals(Codes), ( tr_has_small(Codes) ; tr_acronym_part(Codes) ) ),
        tr_hyphen_name(Codes, Pre, Name, Post)
    ->  reason_tokens(Pre, T1), tr_words(T1, W1), tr_part_words(Post, W2),
        append(W1, [w(Name, upper)|W2], Ws)
    ;   reason_tokens(Codes, Tokens), tr_words(Tokens, Ws)
    ).

%% the first number that carries a sign or a separator: a minus straight
%% before a digit where no letter or digit stands before it, then digits
%% with single points or commas between them
%%
%% A PERCENTAGE IS ONE WORD WITH ITS SIGN. `il restante 41,46% di Chrysler'
%% lost the sign: this clause took `41,46' out and the tokeniser dropped the
%% `%' after it as punctuation, so the sentence said forty-one of Chrysler.
%% And a bare `100%' went to the tokeniser as the number and the word
%% `percent', which no lesson of the lesson's language gives -- so `del
%% 100% di Chrysler' refused for a word the text never wrote. Italian,
%% Spanish and English all write the sign after the digits, so a number
%% with its `%' travels as ONE word, spelled as the text spelled it, and
%% tr_digits/1 knows it for a number.
tr_written_number(Codes, Pre, Num, Post) :-
    append(Pre, Rest, Codes),
    ( Pre == [] -> true ; last(Pre, B), \+ tr_letter_code(B), \+ rt_digit(B), B \== 0'., B \== 0', ),
    tr_number_run(Rest, NCs0, Post0),
    tr_number_written(NCs0, Post0, NCs, Post), !,
    atom_codes(Num, NCs).

tr_number_written(NCs0, [37|Post], NCs, Post) :- !, append(NCs0, [37], NCs).      % 37 is `%'
tr_number_written(NCs, Post, NCs, Post) :- ( memberchk(0'-, NCs) ; memberchk(0'., NCs) ; memberchk(0',, NCs) ; memberchk(0'/, NCs) ), !.

tr_number_run([0'-, D|Cs], [0'-, D|Ns], Post) :- rt_digit(D), !, tr_digit_run(Cs, Ns, Post).
tr_number_run([D|Cs], [D|Ns], Post) :- rt_digit(D), tr_digit_run(Cs, Ns, Post).
tr_digit_run([D|Cs], [D|Ns], Post) :- rt_digit(D), !, tr_digit_run(Cs, Ns, Post).
tr_digit_run([S, D|Cs], [S, D|Ns], Post) :- ( S == 0'. ; S == 0', ), rt_digit(D), !, tr_digit_run(Cs, Ns, Post).
%% ... and a RANGE, two numbers with a hyphen between them: `el bienio
%% 2000-2001' was two numbers and a lost hyphen, and no phrase has two
%% counts after its noun, so the sentence was refused
tr_digit_run([0'-, D|Cs], [0'-, D|Ns], Post) :- rt_digit(D), !, tr_digit_run(Cs, Ns, Post).
%% ... and two numbers with a SLASH between them: `via lo 0/2' was `el 0
%% 2', the slash dropped as punctuation and one thing named twice
tr_digit_run([0'/, D|Cs], [0'/, D|Ns], Post) :- rt_digit(D), !, tr_digit_run(Cs, Ns, Post).
tr_digit_run(Post, [], Post).

tr_cut_at(Codes, Sep, Parts) :-
    (   append(Before, [Sep|After], Codes) -> Parts = [Before|More], tr_cut_at(After, Sep, More)
    ;   Parts = [Codes]
    ).

%% the first capitalised word with a hyphen between two of its letters --
%% or with a CAPITAL after a small letter, which the tokeniser lowered too:
%% `un violín llamado Ex Von Szerdahely VieuxTemps' came back `Vieuxtemps'.
%% And a word ALL in capitals among small letters, an acronym: `la
%% consultora DBK' came back `Dbk'. A piece all in capitals is a heading,
%% lowered before this is asked (tr_caps_piece/2).
tr_hyphen_name(Codes, Pre, Name, Post) :-
    append(Pre, Rest, Codes),
    ( Pre == [] -> true ; last(Pre, B), \+ tr_letter_code(B) ),
    tr_capital_start(Rest),
    tr_name_codes(Rest, NameCodes, Post),
    ( memberchk(0'-, NameCodes) ; tr_inner_capital(NameCodes) ; tr_acronym(NameCodes) ), !,
    atom_codes(Name, NameCodes).

%% two capitals side by side, and a word of capitals alone: `DBK'
tr_two_capitals(Codes) :- append(_, [U1, U2|_], Codes), U1 >= 0'A, U1 =< 0'Z, U2 >= 0'A, U2 =< 0'Z, !.
tr_acronym(Codes) :- Codes = [_, _|_], \+ ( member(C, Codes), \+ ( C >= 0'A, C =< 0'Z ) ).
%% ... and a part that is ONE such word, which a bracket cut out of its
%% sentence: `la Unión Europea (UE)' -- its small letters are outside the
%% bracket, so the part had none and `UE' came back `Ue'. A piece all in
%% capitals was lowered before this (tr_caps_piece/2), so what is left is
%% an acronym
tr_acronym_part(Codes) :- tr_skip_blank(Codes, C1), tr_trim_blank_end(C1, C2), tr_acronym(C2).
tr_has_small(Codes) :- append(_, [C|Rest], Codes), tr_small_code(C, Rest), !.

%% a small letter with a capital straight after it
tr_inner_capital(Codes) :- append(_, [L, U|_], Codes), L >= 0'a, L =< 0'z, U >= 0'A, U =< 0'Z, !.

tr_name_codes([C|Cs], [C|Ns], Post) :- tr_letter_code(C), !, tr_name_codes(Cs, Ns, Post).
tr_name_codes([0'-, C|Cs], [0'-|Ns], Post) :- tr_letter_code(C), !, tr_name_codes([C|Cs], Ns, Post).
tr_name_codes(Post, [], Post).

tr_letter_code(C) :- ( C >= 0'a, C =< 0'z ; C >= 0'A, C =< 0'Z ; C >= 128 ), !.
tr_capital_start([C|_]) :- C >= 0'A, C =< 0'Z, !.
tr_capital_start([195, C|_]) :- C >= 128, C =< 158.

tr_codes(T, Cs) :- is_list(T), !, Cs = T.
tr_codes(T, Cs) :- atom(T), !, atom_codes(T, Cs).
tr_codes(T, Cs) :- string(T), !, string_codes(T, Cs).
tr_codes(T, _)  :- throw(error(type_error(text, T), reason_translate/2)).

tr_split([], []) :- !.
tr_split(Codes, Pieces) :-
    tr_upto(Codes, Piece, Stop, Rest),
    ( tr_blank(Piece) -> Pieces = More ; Pieces = [Piece-Stop|More] ),
    tr_split(Rest, More).

tr_upto([], [], 46, []).                                                % 46 is `.'
%% A POINT BETWEEN TWO DIGITS ENDS NO SENTENCE: `a 1.400 metri' is a
%% thousand and four hundred metres in Italian and Spanish alike, and cut
%% there it was two pieces, `... a 1' and `400 metri ...', neither of them
%% a sentence
tr_upto([D1, 46, D2|Cs], [D1, 46|P], Stop, Rest) :- rt_digit(D1), rt_digit(D2), !, tr_upto([D2|Cs], P, Stop, Rest).
%% THREE POINTS ARE ONE STOP, and they are written back: `non era nemmeno
%% in grado di riconoscere i suoi amici ...' trails off, and cut at its
%% first point it ended in a full stop and two empty pieces
tr_upto([46, 46, 46|Cs], [], marks([], [], 46, [46, 46]), Cs) :- !.
tr_upto([C|Cs], [], C, Cs) :- memberchk(C, [46, 33, 63]), !.            % . ! ?
%% A COLON BEFORE AN OPENING QUOTATION MARK ENDS THE SENTENCE: `Il presente:
%% "servono nove miliardi, ma prima il tribunale potrebbe cancellare il
%% Napoli".' -- what the heading announces is said in its own marks, and
%% read inside one piece the marks went on its first and last words, where
%% `Napoli' lost its capital with the closing one and was no name. Cut
%% there, the heading ends in its colon (and takes no full stop) and the
%% quotation is a sentence whose marks are the sentence's own.
tr_upto([58|Cs], [58], 46, Cs) :-                                        % 58 is `:'
    tr_skip_blank(Cs, C1), tr_quote_mark(open, _, C1, [C|_]), tr_word_code(C), !.
tr_upto([C|Cs], [C|P], Stop, Rest) :- tr_upto(Cs, P, Stop, Rest).

tr_blank(Cs) :- \+ ( member(C, Cs), C > 32 ).

%% the words with their case, w(Word, upper|lower); a comma is nothing, and
%% a number in digits or a quoted word is not a sentence this translates
%% A COMMA IS KEPT, because it is where a sentence's clauses divide and it
%% was dropped here before anything could see it. It travels as the atom
%% `comma' among the w/2 terms, and `tr_uncomma/2' takes them out again --
%% everything below the clause splitter expects a list of w/2 and nothing
%% else, so the commas are stripped the moment the split has read them.
%% A NUMBER IN DIGITS AND A WORD IN QUOTATION MARKS ARE WORDS HERE, and
%% neither was: tr_words/2 had a clause for word/2 and a comma and nothing
%% else, so a token of any other kind made it FAIL and the sentence produced
%% no words at all -- which is why `il premio da 200 milioni' and every
%% sentence carrying scare quotes refused before a word of grammar ran.
%%
%% They are the two tokens that pass through UNTRANSLATED. A number is the
%% same in every language and writes back as its digits; a word in quotation
%% marks is quoted in the text rather than mentioned -- newspaper prose puts
%% scare quotes round an ordinary word -- so it is read as the word it is
%% and the marks are written back round it. The case field carries them:
%% `qboth' for a single word, `qopen' and `qclose' round a run, which
%% tr_word_text/4 turns back into the marks and nothing else looks at.
tr_words([], []).
tr_words([word(W, C)|Ts], [w(W, C)|Ws]) :- !, tr_words(Ts, Ws).
tr_words([','|Ts], [comma|Ws]) :- !, tr_words(Ts, Ws).
tr_words([num(N)|Ts], [w(A, lower)|Ws]) :- !, format(atom(A), "~w", [N]), tr_words(Ts, Ws).
tr_words([quoted(Q)|Ts], Out) :- !,
    tr_quoted_words(Q, Qs), append(Qs, Ws, Out), tr_words(Ts, Ws).

%% a quoted token as its words, the marks kept on the run's edges
tr_quoted_words(Q, Qs) :-
    atom_string(Q, S), split_string(S, " ", " ", Parts0),
    findall(A, ( member(P, Parts0), P \== "", atom_string(A, P) ), As),
    tr_quoted_mark(As, Qs).
tr_quoted_mark([A], [w(A, qboth)]) :- !.
tr_quoted_mark(As, Qs) :-
    append([First|Mid0], [Last], As), !,
    findall(w(M, lower), member(M, Mid0), Mid),
    append([w(First, qopen)|Mid], [w(Last, qclose)], Qs).
tr_quoted_mark([], []).

%% the marks on the edges of a quoted run of words: both on its only word,
%% the opening one on its first and the closing one on its last; what is
%% not a word -- a comma -- carries no mark
tr_quote_edges(Ws0, Ws) :-
    findall(I, nth0(I, Ws0, w(_, _)), Is),
    (   Is = [I]
    ->  tr_mark_at(Ws0, I, qboth, Ws)
    ;   Is = [F|_], last(Is, L)
    ->  tr_mark_at(Ws0, F, qopen, Ws1), tr_mark_at(Ws1, L, qclose, Ws)
    ;   Ws = Ws0
    ).
tr_mark_at(Ws0, I, M, Ws) :- nth0(I, Ws0, w(W, C), Rest), tr_edge_case(C, M, M1), nth0(I, Ws, w(W, M1), Rest).
%% A CAPITAL ON A QUOTED RUN'S EDGE IS KEPT BESIDE ITS MARK until the side
%% is known (tr_quote_names/3): `señaló que "España ve con simpatía la
%% candidatura"' put the mark where the capital was, and `España' was no
%% name and no word, and the sentence was refused for it
tr_edge_case(upper, qopen, qopenu) :- !.
tr_edge_case(upper, qclose, qcloseu) :- !.
tr_edge_case(upper, qboth, qbothu) :- !.
tr_edge_case(_, M, M).

tr_uncomma([], []).
tr_uncomma([comma|Ws], Out) :- !, tr_uncomma(Ws, Out).
tr_uncomma([semicolon|Ws], Out) :- !, tr_uncomma(Ws, Out).
tr_uncomma([W|Ws], [W|Out]) :- tr_uncomma(Ws, Out).

%% ---- the languages, and which way --------------------------------------------
%%
%% A lesson learned plain is the language with no name; one learned under
%% a name is proved through lesson/2. The words vote: a word whose form
%% the lesson gives is the lesson's, its meaning is English, a word on
%% both sides says nothing. The language whose words the text uses most
%% is the one it is in; failing that the text is English, and goes into
%% the one language whose meanings it uses most -- two that fit equally
%% refuse it, and reason_translate/3 names one.

tr_way(any, Words, From, To) :-
    tr_languages(Ls), Ls \== [],
    findall(v(L, F, E), ( member(L, Ls), tr_votes_in(L, Words, F, E) ), Vs),
    (   tr_winner(Vs, from, L1) -> tr_set_language(L1), From = foreign, To = english
    ;   tr_winner(Vs, into, L2) -> tr_set_language(L2), From = english, To = foreign
    ).
tr_way(to_english, Words, foreign, english) :-
    tr_languages(Ls), Ls \== [],
    findall(v(L, F, E), ( member(L, Ls), tr_votes_in(L, Words, F, E) ), Vs),
    ( tr_winner(Vs, from, L1) -> true ; Ls = [L1] ),
    tr_set_language(L1).
tr_way(from_english(L), _, english, foreign) :- tr_set_language(L).

tr_languages(Ls) :-
    findall(L, tr_solve_plain(lesson_language(L)), L0), list_to_set(L0, L1),
    ( tr_solve_plain(mean(_, _)) -> Ls = [none|L1] ; Ls = L1 ).

tr_votes_in(L, Words, F, E) :- tr_set_language(L), tr_votes(Words, 0, 0, F, E).

tr_votes([], F, E, F, E).
%% a comma or a semicolon votes for nobody -- and with no clause for it the
%% vote FAILED, so a sentence with a comma was refused whenever the
%% language had to be voted for rather than named
tr_votes([M|Ws], F0, E0, F, E) :- atom(M), !, tr_votes(Ws, F0, E0, F, E).
tr_votes([w(W, _)|Ws], F0, E0, F, E) :-
    ( tr_known_word(foreign, W) -> Kf = 1 ; Kf = 0 ),
    ( tr_known_word(english, W) -> Ke = 1 ; Ke = 0 ),
    (   Kf =:= 1, Ke =:= 1
    ->  ( tr_lessons_own(W) -> F1 is F0 + 1, E1 = E0 ; F1 = F0, E1 = E0 )
    ;   F1 is F0 + Kf, E1 is E0 + Ke
    ),
    tr_votes(Ws, F1, E1, F, E).

%% a word the lesson gives that English knows only by inflecting it --
%% `ha', which the inflector reads as the base of `has' -- is the lesson's
tr_lessons_own(W) :- tr_lexeme(foreign, W, _, _), \+ tr_lexeme(english, W, _, _), \+ en_function(W), \+ en_own(W).

%% one clear winner among the languages, or none
tr_winner(Vs, Which, L) :-
    findall(K-L0, ( member(v(L0, F, E), Vs), ( Which == from -> F > E, K = F ; E > F, K = E ) ), Cs),
    Cs \== [], keysort(Cs, S), last(S, K-L),
    \+ ( member(K-L2, S), L2 \== L ).

tr_set_language(L) :- nb_setval('$tr_language', L).
tr_language(L) :- ( catch(nb_getval('$tr_language', L0), _, fail) -> L = L0 ; L = none ).

%% ---- the whole sentence -----------------------------------------------------------

tr_translate(Words, From, To, Stop, Out) :-
    tr_kind(Stop, Kind), tr_exclaim(Stop),
    tr_into_ir(From, Kind, Words, S),
    tr_from_ir(To, Kind, S, Stop, Out).

tr_kind(marks(_, S, _), K) :- !, tr_kind(S, K).
tr_kind(marks(_, _, S, _), K) :- !, tr_kind(S, K).
tr_kind(63, question) :- !.                                               % 63 is `?'
tr_kind(_, statement).

%% whether a piece ended on `!': a sentence with no verb reads only then
tr_exclaim(Stop) :- ( ( Stop == 33 ; Stop = marks(_, 33, _) ; Stop = marks(_, _, 33, _) ) -> nb_setval('$tr_exclaim', yes) ; nb_setval('$tr_exclaim', no) ).

%% ---- the intermediate representation ---------------------------------------------
%%
%% THE IR IS THE SENTENCE TERM WITH ENGLISH WORDS IN IT, and every
%% language has the two halves over it: tr_into_ir/4 reads a sentence on
%% that language's own side and crosses its words, tr_from_ir/5 writes
%% one out. So a language is added by giving its lesson, not by giving a
%% pair of languages a path of their own, and any two of them translate:
%% Italian into the IR, the IR into Spanish, with no English sentence
%% assembled and none re-parsed.
%%
%% What travels exactly is the SHAPE -- s(Asked, Subject, Group,
%% Complements): the tense, the aspect, the denial, the person, the
%% number, what a question asks for, and every complement in its place.
%% What travels through English is the VOCABULARY, and it can be nothing
%% else: a lesson says what a word means only as mean(Word, EnglishWord),
%% so English is the one language every lesson is written against. A
%% sense English does not separate is a sense the IR cannot separate.
%%
%% ENGLISH IS THEREFORE ALREADY THE IR, which is what a pivot means: a
%% sentence read on the English side needs no crossing, and its words
%% stay as the text wrote them (`houses'), where a crossed word is the
%% lexeme its meaning gave (`house' with the number beside it). Both are
%% English words and both write out the same, because every consumer
%% takes the lexeme first -- tr_noun_lexeme/5 reads either.

%% into the IR: read on this side, then cross every word into English
tr_into_ir(Side, Kind, Words0, S) :-
    nb_setval('$tr_from', Side),
    empty_assoc(NoFailures), nb_setval('$tr_failed', NoFailures), tr_memo_reset,
    nb_setval('$tr_no_command', no),
    tr_adj_lists(Side, Words0, WordsL),
    tr_asides(Side, WordsL, WordsA),
    tr_list_commas(Side, WordsA, Words),
    nb_setval('$tr_piece', Words), nb_setval('$tr_heading', none),
    tr_read(Side, Kind, Words, S0),
    tr_cross(Side, S0, S).

%% out of the IR: the IR's side IS English, so the writer crosses from it
%% -- into the lesson's language as it always did, and into English by
%% the identity above
%% EVERY SENTENCE STARTS WITH NO SUBJECT'S GENDER: a piece with no subject
%% sets none, and its participle agreed with the sentence BEFORE it -- the
%% Washington Post's last line, `estratto brano dell'articolo', came out
%% `extraído' after a masculine subject and `extraída' after `La Italia
%% actual', the same words translated two ways by where they stood
tr_from_ir(To, Kind, S, Stop, Out) :-
    nb_setval('$tr_from', english), tr_memo_reset, nb_setval('$tr_subject_gender', masculine),
    tr_write(To, Kind, S, Outs),
    tr_join(To, Kind, Outs, Stop, Out).

%% WHAT STANDS ASIDE FROM THE SENTENCE: a phrase in brackets -- `due
%% bambini (la figlia di 4 anni e il figlio del compagno di 5)', `vicino
%% Subiaco (Roma)' -- and an age between commas after a noun, `La donna, 36
%% anni, soccorsa dai carabinieri'. The tokeniser dropped the brackets and
%% their words ran into the sentence, and the age read as a list's third
%% item. Each is ONE item among the words, w(Key, paren) or w(Key, aside),
%% its words kept under Key until the crossing reads them on their own: the
%% phrase before takes it as the last thing it has (app/3), a bracket where
%% a complement may stand is one (paren/1), and every writer puts it back in
%% its marks. A bracket that never closes is dropped.
tr_asides(_, [], []).
tr_asides(Side, [lparen|Ws0], [w(K, paren)|Ws]) :-
    append(In, [rparen|Rest], Ws0), \+ memberchk(lparen, In), In \== [], !,
    tr_aside_key(K, In), tr_asides(Side, Rest, Ws).
tr_asides(Side, [lparen|Ws0], Ws) :- !, tr_asides(Side, Ws0, Ws).
tr_asides(Side, [rparen|Ws0], Ws) :- !, tr_asides(Side, Ws0, Ws).
tr_asides(Side, [W, comma, w(N, NC)|Ws0], [W, w(K, aside)|Ws]) :-
    W = w(_, _), tr_digits(N), tr_is(Side, W, noun),
    append(In0, [comma|Rest], Ws0), In = [w(N, NC)|In0], length(In, L), L =< 3,
    tr_np(Side, In, _), !,
    tr_aside_key(K, In), tr_asides(Side, Rest, Ws).
%% ... and a YEAR between a comma and the end of the sentence, or another
%% comma: `destaca un violín llamado Ex Von Szerdahely VieuxTemps, de
%% 1736.', `un stradivarius conocido como Golden Bell, de 1686.' It is the
%% date of the thing before it, not the clause's, and it goes back there.
tr_asides(Side, [W, comma, P, w(Y, YC)|Ws0], [W, w(K, aside)|Ws]) :-
    W = w(_, _), tr_year(Y), tr_is(Side, P, preposition),
    ( Ws0 == [] -> Rest = [] ; Ws0 = [comma|Rest] ), !,
    tr_aside_key(K, [P, w(Y, YC)]), tr_asides(Side, Rest, Ws).
%% ... AND AN ADJECTIVE PHRASE BETWEEN TWO COMMAS AFTER THE PHRASE IT
%% DESCRIBES: `una versión estilizada, conservadora en el mejor sentido del
%% término, y permite ...', `el éxito, discreto pero al fin y al cabo éxito,
%% de esta Lucia'. Read as the clause's own complements, its adjective
%% agreed with the SUBJECT -- `il risultato è una versione stilizzata,
%% conservatore' -- where it is the version's. It opens on an adjective in
%% the gender and the number of the word before the comma, a noun or an
%% adjective of that phrase, and reads as complements that open on it; it
%% goes back after the phrase, between its commas.
tr_asides(foreign, [W, comma, A|Ws0], [W, w(K, aside)|Ws]) :-
    W = w(_, _), A = w(_, _),
    ( tr_is(foreign, W, noun) ; tr_is(foreign, W, adjective) ), tr_is(foreign, A, adjective),
    append(In, [comma|Rest], [A|Ws0]), \+ memberchk(comma, In), Rest = [w(_, _)|_],
    \+ ( member(X, In), atom(X) ),
    tr_aside_agrees(W, A),
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    tr_complements(foreign, In, [adj(_)|_]), !,
    tr_aside_key(K, In), tr_asides(foreign, Rest, Ws).
%% ... AND A PHRASE WITH NO ARTICLE BETWEEN TWO COMMAS AFTER A NAME, which
%% says who the name is: `La candidatura de Solana, actual secretario
%% general de la OTAN, ha sido promovida ...', `a Carlos Westendorp, Alto
%% Representante Civil en Bosnia, explicó ...'. Read as the clause's own,
%% `actual' and `secretario' were adjectives of `Solana' -- a sunny slope,
%% to the vocabulary -- and with a name no lesson knows the sentence
%% divided at the comma and its participle agreed with the apposition. It
%% goes back after the name, between its commas -- and the comma that
%% closes it stays among the words, as the participle's above does:
%% `... a Carlos Westendorp, Alto Representante Civil en Bosnia, explicó
%% ayer el ministro' is divided there from the clause that reports it. Not
%% a run of names alone: `la ministra de Justicia, Janet Reno,' is a name
%% apposed to a phrase (tr_list_commas/3), and stays one.
tr_asides(foreign, [W, comma, A|Ws0], [W, w(K, aside), comma|Ws]) :-
    W = w(_, upper), A = w(_, _), \+ tr_determiner(foreign, A, _, _),
    %% (and it opens on a noun or an adjective, as `actual secretario' and
    %% `Alto Representante' do: after `Parlamento de Tbilisi, en una consulta
    %% que servirá ...' the whole clause up to the next comma was read as a
    %% phrase and refused, for 1.1 million inferences a sentence)
    once(( tr_is(foreign, A, noun) ; tr_is(foreign, A, adjective) )),
    append(In, [comma|Rest], [A|Ws0]), \+ memberchk(comma, In), Rest = [w(_, _)|_],
    \+ ( member(X, In), atom(X) ),
    \+ forall(member(X, In), tr_name_word(foreign, X)),
    %% (and not all in capitals: `Capri, Procida, Ischia, Giglio, Eolie e
    %% Ponza' -- `giglio' is a lily to the lesson, and `, Giglio,' was taken
    %% for what Ischia is, which broke the list and refused the sentence)
    \+ forall(member(X, In), X = w(_, upper)),
    once(( member(N, In), tr_is(foreign, N, noun) )),
    tr_apposition(In), !,
    tr_aside_key(K, In), tr_asides(foreign, Rest, Ws).
%% ... AND A PARTICIPLE WITH ITS AGENT BETWEEN TWO COMMAS AFTER A NAME OR A
%% NOUN: `la descripción visual de lord Arturo Bucklaw, interpretado por
%% Carlos Cosías, se permite Vick ...' -- the character, played by the
%% singer. The phrase it says it of is inside another (`la descripción ...
%% de lord ...'), where the complement reader's aside (tr_phrase_aside/4)
%% cannot reach, and read as the clause's own the sentence had no reading.
%% It goes back after that phrase between its commas, agreeing with it --
%% and the comma that closes it stays among the words, because it closes
%% the sentence's front as well: without it `Sólo en la descripción ...' was
%% written after the verb (the writer drops a comma after another)
tr_asides(foreign, [W, comma, w(P, PC)|Ws0], [W, w(K, aside), comma|Ws]) :-
    W = w(_, _), ( tr_name_word(foreign, W) ; tr_is(foreign, W, noun) ),
    tr_participle_here(foreign, P, _), \+ tr_is(foreign, w(P, lower), noun), \+ tr_is(foreign, w(P, lower), adjective),
    append(In0, [comma|Rest], Ws0), \+ memberchk(comma, In0), Rest = [w(_, _)|_],
    \+ ( member(X, In0), atom(X) ),
    ( In0 == [] -> true ; tr_reduced_agent(foreign, In0, _) ), !,
    tr_aside_key(K, [w(P, PC)|In0]), tr_asides(foreign, Rest, Ws).
%% ... AND A PARTICIPLE WITH ADJUNCTS OF ITS OWN: `El nombramiento del
%% primer responsable de la política exterior y de seguridad, conocido en
%% el argot comunitario como Mister PESC, está previsto que ...' -- known,
%% in the jargon, as Mister CFSP. `conocido' is an adjective and a noun as
%% well, which the clause above leaves alone, and read as the sentence's
%% own the commas were lost and the participle agreed with nothing. It
%% opens on a preposition after the participle, which an adjective phrase
%% of the kind above does not, and it goes back between its commas, the
%% closing one kept as the participle's above is.
tr_asides(foreign, [W, comma, w(P, PC)|Ws0], [W, w(K, aside), comma|Ws]) :-
    W = w(_, _), ( tr_name_word(foreign, W) ; tr_is(foreign, W, noun) ),
    tr_participle_here(foreign, P, _),
    append(In0, [comma|Rest], Ws0), In0 = [Pr|_], \+ memberchk(comma, In0), Rest = [w(_, _)|_],
    \+ ( member(X, In0), atom(X) ), tr_is(foreign, Pr, preposition),
    tr_participle_adjuncts(In0, _), !,
    tr_aside_key(K, [w(P, PC)|In0]), tr_asides(foreign, Rest, Ws).
%% ... AND A PARTICIPLE WITH ITS DEGREE: `Países como Alemania o Estados
%% Unidos, más modernizados desde todos los puntos de vista, han tardado más
%% que nosotros' -- more modernised from every point of view. `más' is no
%% participle, so the two clauses above let the commas go, and read as the
%% sentence's own the words before the verb were a clause with no verb of
%% their own and the verb's subject nobody. It goes back where it stood, the
%% lesson's word for `more' before the participle (part/2 with pdeg/1), and
%% after a word the lesson calls an adjective as well: `Estados Unidos'.
tr_asides(foreign, [W, comma, w(M, MC), w(P, PC)|Ws0], [W, w(K, aside), comma|Ws]) :-
    W = w(_, _), tr_degree_word(M),
    ( tr_name_word(foreign, W) ; tr_is(foreign, W, noun) ; tr_is(foreign, W, adjective) ),
    tr_participle_here(foreign, P, _), \+ tr_is(foreign, w(P, lower), noun), \+ tr_is(foreign, w(P, lower), adjective),
    append(In0, [comma|Rest], Ws0), \+ memberchk(comma, In0), Rest = [w(_, _)|_],
    \+ ( member(X, In0), atom(X) ),
    (   In0 == [] -> true
    ;   In0 = [Pr|_], tr_is(foreign, Pr, preposition),
        ( tr_reduced_agent(foreign, In0, _) -> true ; tr_participle_adjuncts(In0, _) )
    ), !,
    tr_aside_key(K, [w(M, MC), w(P, PC)|In0]), tr_asides(foreign, Rest, Ws).
%% ... AND A PHRASE BETWEEN TWO COMMAS THAT OPENS ON A WORD THAT REPLACES
%% THE NOUN, after a noun or a pronoun: `di cui solo uno, QUELLO GUIDATO DAL
%% MAGNATE TELEVISIVO SILVIO BERLUSCONI, uscito da elezioni generali' -- the
%% one it is, said again. Read as the clause's own, `quello' was the pronoun
%% `that' and the participle a predicate of nobody. It goes back after the
%% phrase between its commas.
tr_asides(foreign, [W, comma, Q|Ws0], [W, w(K, aside)|Ws]) :-
    W = w(_, _), Q = w(_, _), tr_noun_replacer(foreign, Q),
    ( tr_is(foreign, W, noun) ; tr_is(foreign, W, pronoun) ; tr_name_word(foreign, W) ),
    append(In0, [comma|Rest], Ws0), \+ memberchk(comma, In0), Rest = [w(_, _)|_],
    \+ ( member(X, In0), atom(X) ),
    tr_np(foreign, [Q|In0], _), !,
    tr_aside_key(K, [Q|In0]), tr_asides(foreign, Rest, Ws).
%% ... AND THE WRITER'S OWN COMMENT BETWEEN TWO COMMAS, a clause whose verb
%% is in the first person singular: `Quest'Uomo ... ha osato, sottolineo
%% "osato", dire che ...' -- I stress the word. Read as the sentence's own
%% clauses, the comment divided it, `ha osato' a clause of its own and
%% `dire che ...' what I stress. It stands where it stood, w(Key, comment),
%% and every writer puts it back there between its commas.
%% A VERB FORM AND NOTHING ELSE, after a word that opens no clause: Spanish's
%% `como' is I eat and `like', and `Al margen de que, como todos, han comido
%% pan' is an insertion after its connector (tr_read0/4), which the comment
%% took and refused the sentence.
%% -- AND SHORT, three words at most: `Sono una piccola imprenditrice di 29
%% anni, pacifista convinta, odio anche solo l'idea della guerra, della
%% violenza e della distruzione ...' is the sentence's own second clause, I
%% hate even the idea of war, and read as a comment it closed at the list's
%% comma and refused the letter's third sentence
tr_asides(foreign, [W, comma, w(V, VC)|Ws0], [W, w(K, comment)|Ws]) :-
    W = w(_, _), \+ tr_opens_clause(W), tr_form(V, L, singular, _, first), atom(L),
    ( tr_class_of(L, verb) ; tr_class_of(L, modal) ),
    \+ ( member(Cl, [preposition, conjunction, adverb]), tr_is(foreign, w(V, lower), Cl) ),
    append(In0, [comma|Rest], Ws0), \+ memberchk(comma, In0), Rest = [w(_, _)|_],
    length(In0, NIn), NIn =< 2,
    \+ ( member(X, In0), atom(X) ),
    In = [w(V, VC)|In0], tr_aside_reads(foreign, In), !,
    tr_aside_key(K, In), tr_asides(foreign, Rest, Ws).
%% ... and a clause between two DASHES that opens on a relative or a
%% question word: `E il Giglio - dove l'afflusso dei veicoli ... è vietato
%% dal 24 luglio al 25 agosto - ritorna alla dimensione dell'oasi'. It is
%% the island's, where the traffic is banned, and read as the sentence's
%% own clauses it was nothing; it goes back after the phrase between its
%% dashes, w(Key, dashed).
tr_asides(Side, [W, dash, w(R, RC)|Ws0], [W, w(K, dashed)|Ws]) :-
    W = w(_, _), ( tr_relative_word(Side, R) ; tr_indirect_word(Side, R, _) ),
    append(In0, [dash|Rest], Ws0), \+ memberchk(dash, In0), Rest \== [], !,
    tr_aside_key(K, [w(R, RC)|In0]), tr_asides(Side, Rest, Ws).
%% ... AND A WHOLE CLAUSE BETWEEN TWO DASHES, after a phrase and before the
%% rest of its sentence: `Un roble devastado y una inmensa luna - - el
%% personaje principal, Lucia, es el arquetipo de la locura operística - -
%% son dos de los elementos capitales ...'. It says something of the moon
%% and of nothing else in the sentence, and read as the sentence's own
%% clauses it was refused with every word known. It stands where it stood,
%% between its dashes -- but only a clause that reads as one, and never
%% one that reads as a REPORTING clause, `Sarò per sempre grato – aggiunge
%% Marchionne – al team', which the reader takes on its own and writes
%% after the sentence.
tr_asides(Side, [W, dash|Ws0], [W, w(K, dashed)|Ws]) :-
    W = w(_, _), Ws0 = [w(_, _)|_],
    append(In0, [dash|Rest], Ws0), \+ memberchk(dash, In0), Rest = [w(_, _)|_],
    In0 = [_, _|_], \+ memberchk(dash, Rest),
    tr_clause_words(In0, In1), tr_list_commas(Side, In1, In),     % `principal, Lucia,' is an apposition
    \+ tr_read_reporting(Side, In, _),
    tr_aside_reads(Side, In), !,
    tr_aside_key(K, In), tr_asides(Side, Rest, Ws).
tr_asides(Side, [W|Ws0], [W|Ws]) :- tr_asides(Side, Ws0, Ws).

%% the adjuncts after a participle: complements with no object in them,
%% read with no verb group around them
tr_participle_adjuncts(Ws, Cs) :-
    tr_global('$tr_read_group', G0), tr_global('$tr_read_aspect', A0),
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    (   tr_complements(foreign, Ws, Cs0), \+ memberchk(obj(_), Cs0)
    ->  nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0), Cs = Cs0
    ;   nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0), fail
    ).

%% a phrase, or a phrase and the prepositional phrases after it
tr_apposition(In) :- tr_np(foreign, In, _), !.
tr_apposition(In) :- tr_subject(foreign, none, In, third, singular, with(_, _)), !.

%% two words in one gender and one number: a word with no gender of its own
%% agrees with either
tr_aside_agrees(w(W, _), w(A, _)) :-
    tr_lexeme(foreign, W, WL, N), tr_lexeme(foreign, A, AL, N),
    tr_gender(WL, GW), tr_gender(AL, GA),
    ( GW == none ; GA == none ; GW == GA ), !.

%% a year, as digits: four of them, from 1100 to 2100
tr_year(Y) :- atom(Y), atom_length(Y, 4), atom_number(Y, N), integer(N), N >= 1100, N =< 2100.

tr_aside_key(K, Words) :-
    catch(nb_getval('$tr_aside_n', N0), _, N0 = 0), N is N0 + 1, nb_setval('$tr_aside_n', N),
    atom_concat('$aside', N, K), nb_setval(K, Words).

%% the words aside, read on the side they were written on and crossed: a
%% phrase if they are one, and otherwise complements
%% -- and a whole clause in brackets is read as one: `(los octavos de final
%% ya se disputarán a doble partido)' says something of its own
tr_aside_inner(K, Inner) :-
    nb_getval(K, Ws), tr_side_here(Side),
    (   %% a participle and its agent: part(Lexeme, Complements)
        Side == foreign, Ws = [w(P, _)|PR], tr_participle_here(foreign, P, L),
        \+ tr_is(foreign, w(P, lower), noun), \+ tr_is(foreign, w(P, lower), adjective),
        ( PR == [] -> Cs0 = [] ; tr_reduced_agent(foreign, PR, Cs0) )
    ->  tr_lexeme_across(L, english, LT), tr_cross_comps(Cs0, Cs), Inner = part(LT, Cs)
    %% ... and a participle with adjuncts of its own (tr_asides/3), in the
    %% gender and the number the source gave its form: `conocido' is the
    %% man in charge's, never the security's before the comma
    ;   Side == foreign, Ws = [w(P, _), Pr|PR], tr_participle_here(foreign, P, L),
        tr_is(foreign, Pr, preposition), tr_participle_adjuncts([Pr|PR], Cs0)
    ->  tr_lexeme_across(L, english, LT), tr_cross_comps(Cs0, Cs1),
        ( tr_holds(feminine(P)) -> G = feminine ; G = masculine ), tr_participle_number(P, N),
        Inner = part(LT, [agr(G), agrn(N)|Cs1])
    %% ... and a participle with its degree: `más modernizados desde ...'
    ;   Side == foreign, Ws = [w(M, _), w(P, _)|PR], tr_degree_word(M), tr_participle_here(foreign, P, L),
        (   PR == [] -> Cs0 = []
        ;   tr_reduced_agent(foreign, PR, Cs0) -> true
        ;   tr_participle_adjuncts(PR, Cs0)
        )
    ->  tr_lexeme_across(L, english, LT), tr_cross_comps(Cs0, Cs1),
        ( tr_holds(feminine(P)) -> G = feminine ; G = masculine ), tr_participle_number(P, N),
        Inner = part(LT, [pdeg(comparative), agr(G), agrn(N)|Cs1])
    ;   tr_np(Side, Ws, NP0) -> tr_cross_np(NP0, NP), Inner = np(NP)
    %% (a question word in an aside is a relative one: it hangs on a phrase)
    ;   tr_complements(Side, Ws, Cs00) -> tr_relative_wh1(Cs00, Cs0), tr_cross_comps(Cs0, Cs), Inner = comps(Cs)
    %% ... and an aside may open on its own coordinator: `in nome di una
    %% "pace" (ma la pace di chi e per chi)' -- but whose peace, and for whom
    ;   Ws = [C|Ws1], tr_coord(Side, C), tr_complements(Side, Ws1, Cs10)
    ->  tr_relative_wh1(Cs10, Cs1), tr_cross_comps([cnj(C)|Cs1], Cs), Inner = comps(Cs)
    ;   tr_aside_clause(Side, Ws, S) -> Inner = clause(S)
    %% ... and a QUESTION with no mark of its own: `(ma chi avrebbe potuto
    %% pensare di "mediare" con Hitler)' asks who could have, and read as a
    %% statement `chi' was nobody's subject. It is written back as the
    %% words were, the question word first and no mark added
    ;   tr_aside_question(Side, Ws, S) -> Inner = clause(S)
    ), !.
%% the words of a clause set aside read as a statement, and leave the
%% reading of the words around them as they were
tr_aside_reads(Side, Ws) :-
    tr_global('$tr_piece', P0), nb_setval('$tr_piece', Ws),
    (   tr_aside_clause_read(Side, Ws) -> nb_setval('$tr_piece', P0)
    ;   nb_setval('$tr_piece', P0), fail
    ).
tr_aside_clause_read(Side, Ws) :-
    tr_global('$tr_read_group', G0), tr_global('$tr_read_aspect', A0),
    (   tr_read(Side, statement, Ws, _)
    ->  nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0)
    ;   nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0), fail
    ).
tr_aside_question(Side, Ws, S) :-
    ( Ws = [C|Ws1], tr_coord(Side, C) -> true ; Ws1 = Ws ),
    Ws1 = [w(Q, _)|_], tr_asks(Side, Q),
    tr_global('$tr_read_group', G0), tr_global('$tr_read_aspect', A0),
    (   tr_read(Side, question, Ws, S0), tr_cross(Side, S0, S1)
    ->  nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0), S = S1
    ;   nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0), fail
    ).
tr_asks(english, Q) :- !, en_question(Q, _).
tr_asks(foreign, Q) :- tr_solve(mean(Q, E)), en_question(E, _), !.
tr_aside_clause(Side, Ws, S) :-
    tr_global('$tr_read_group', G0), tr_global('$tr_read_aspect', A0),
    (   tr_read(Side, statement, Ws, S0), tr_cross(Side, S0, S1)
    ->  nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0), S = S1
    ;   nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0), fail
    ).

%% ... and written back in its marks -- an adjective in it agreeing with the
%% phrase it stands after, where there is one
tr_aside_out(To, Kind, Inner, Outs) :- tr_aside_out(To, Kind, Inner, none, singular, Outs).
tr_aside_out(To, Kind, Inner, Noun, Number, Outs) :-
    tr_global('$tr_verb', V0), nb_setval('$tr_verb', none),      % no verb in it: no marker before a person
    (   Inner = np(NP) -> tr_np_out(To, NP, IO, _, _)
    ;   Inner = part(L, Cs0)
    ->  ( select(agr(GA), Cs0, Cs1) -> true ; Cs1 = Cs0, GA = none ),
        ( select(agrn(NA), Cs1, Cs2) -> true ; Cs2 = Cs1, NA = Number ),
        (   select(pdeg(D), Cs2, Cs)
        ->  ( To == english -> ( D == superlative -> DW = most ; DW = more ) ; tr_degree_out(DW) ), Deg = [o(DW, lower)]
        ;   Cs = Cs2, Deg = []
        ),
        (   To == english
        ->  tr_lexeme_across(L, english, LT), en_participle_of(LT, PP)
        ;   tr_lexeme_across(L, foreign, LT),
            ( GA \== none -> G = GA ; tr_gender(Noun, G0), G0 \== none -> G = G0 ; G = masculine ),
            tr_with_gender(G, tr_participle_agreeing(LT, NA, PP))
        ),
        tr_comps_out(To, Cs, Noun, Number, _, CO, CA), append([Deg, [o(PP, lower)], CO, CA], IO)
    ;   Inner = clause(S) -> tr_write(To, statement, S, IO)
    ;   Inner = comps(Cs), tr_comps_out(To, Cs, Noun, Number, _, CO, CA), append(CO, CA, IO)
    ),
    nb_setval('$tr_verb', V0),
    (   Kind == paren -> append([o('(', lower)|IO], [o(')', lower)], Outs)
    ;   Kind == dashed -> append([o('–', lower)|IO], [o('–', lower)], Outs)
    ;   append([o(',', comma)|IO], [o(',', comma)], Outs)
    ), !.

%% A COMMA INSIDE A LIST IS THE LIST'S, NOT THE CLAUSE'S. `contra compañeros
%% y vecinos, emigrantes y minorías', `la violencia gratuita juvenil,
%% anárquica o xenófoba': the comma stands where a coordinator could, and
%% the plain reading -- which reads with the commas taken out -- read the
%% first as neighbours who are migrants. A comma is the list's when the word
%% before it is a noun or an adjective and after it come phrase words, a
%% coordinator and phrase words again, and then no verb: `En la casa, el
%% perro y el gato duermen' is a fronted phrase and a subject, and the verb
%% after the list says so. Such a comma travels as w(',', lcomma), which
%% tr_coord/2 takes for a coordinator, so a phrase splits at it and an
%% adjective list keeps it, and every writer puts back a comma.
%% ... AND A LIST AT THE HEAD OF THE SENTENCE IS ITS SUBJECT, whatever
%% follows it: `Il lavoro, l'impegno e i risultati raggiunti da Chrysler
%% ... sono qualcosa di eccezionale'. The rule above wants no verb after the
%% list, which is what keeps `En la casa, el perro y el gato duermen' a
%% front and a subject -- and there a preposition stands before the comma.
%% So while every word from the head of the piece is a phrase's word (Head
%% is `yes'), the list's own tail decides alone.
tr_list_commas(Side, Ws0, Ws) :- tr_list_commas(Side, none, yes, Ws0, Ws).
tr_list_commas(_, _, _, [], []).
%% A NAME BETWEEN TWO COMMAS AFTER A PHRASE IS AN APPOSITION: `El ministro del
%% Interior francés, Jean-Pierre Chevènement, ha provocado'. The commas and
%% the name travel as ONE word, w(Name, appos), which the phrase before it
%% takes where a name apposed to its noun goes and every writer puts back,
%% commas and all, after the noun.
%% ... but not in a list of names: `si chiamano Giglio, Eolie, Ustica e
%% Ponza' -- `giglio' is a lily to the lesson, so the island before the
%% first comma was a noun with `Eolie' apposed to it, and the list was lost.
%% Names that go on after the second comma, to another comma or to a
%% coordinator, carry the list on.
tr_list_commas(Side, Prev, _, [comma|Ws0], [w(A, appos)|Ws]) :-
    %% (after a noun, an adjective -- or a NAME: `tuvo en Josep Bros, Edgardo,
    %% otro brillante jalón' is the singer and the role he sang, and read as
    %% the verb's object the role came out after `in', `Edgardo, altro')
    Prev = w(_, _), ( tr_list_item(Side, Prev) -> true ; tr_name_word(Side, Prev) ),
    %% (a name OPENS on a word no lesson knows and goes on through capitalised
    %% words, known or not: `la ministra de Justicia, Janet Reno, pidiéndole'
    %% -- `reno' is a reindeer to the lesson, and the name was lost)
    append(Ns, [comma|Rest], Ws0), Ns = [N1|Ns1], N1 = w(_, _), tr_name_word(Side, N1),
    forall(member(N, Ns1), N = w(_, upper)),
    \+ tr_names_go_on(Side, Rest), !,
    findall(C, ( member(w(N, _), Ns), tr_cap(N, C) ), Cs), atomic_list_concat(Cs, ' ', A),
    tr_list_commas(Side, w(A, appos), no, Rest, Ws).
%% ... AND ONE THAT ENDS THE PIECE, where the stop closes it: `explicó ayer el
%% ministro de Asuntos Exteriores, Abel Matutes.' With no comma after the
%% name, the clause before the name's comma read as a reporting clause SET IN
%% the sentence, and the name was left to the first clause as an object of
%% `mantendrá'. Two words at least, the first one no lesson knows: a single
%% name at the end is as likely the last of a list (`Giglio, Eolie, Ustica,
%% Capri') as an apposition.
tr_list_commas(Side, Prev, _, [comma|Ns], [w(A, appos)]) :-
    Prev = w(_, _), ( tr_list_item(Side, Prev) -> true ; tr_name_word(Side, Prev) ),
    Ns = [N1, _|_], N1 = w(_, _), tr_name_word(Side, N1),
    forall(member(N, Ns), N = w(_, upper)), !,
    findall(C, ( member(w(N, _), Ns), tr_cap(N, C) ), Cs), atomic_list_concat(Cs, ' ', A).
tr_list_commas(Side, Prev, Head, [comma|Ws0], [X|Ws]) :- !,
    (   Prev = w(_, _), tr_list_item(Side, Prev),
        ( tr_list_tail(Side, Ws0) ; Head == yes, tr_list_tail_head(Side, Ws0) )
    ->  X = w(',', lcomma), Head1 = Head
    ;   X = comma, Head1 = no
    ),
    tr_list_commas(Side, X, Head1, Ws0, Ws).
%% ... and so does a list at the head of a CLAUSE, after the word that opens
%% it: `Amene località dove le auto, le moto e i ciclomotori sono banditi'
%% -- the vehicles are the subject of `sono banditi', and with a verb after
%% the list the comma was the clause's
tr_list_commas(Side, _, Head, [W|Ws0], [W|Ws]) :-
    (   Head == yes, tr_list_word(Side, W) -> Head1 = yes
    ;   W = w(X, _), ( tr_relative_word(Side, X) ; tr_indirect_word(Side, X, _) ) -> Head1 = yes
    ;   Head1 = no
    ),
    tr_list_commas(Side, W, Head1, Ws0, Ws).

tr_list_item(Side, W) :- ( tr_is(Side, W, noun) ; tr_is(Side, W, adjective) ), !.
%% ... AND A NAME: `si unisce a Ferrara, Sgarbi, Previti e Andreotti' is ONE
%% list of four people. With the comma after a name left the clause's, the
%% reading with the commas taken out made one name of three, `a Ferrara
%% Sgarbi Previti y Andreotti', and `Pannella parla con Ferrara, Sgarbi,
%% Previti e Andreotti' read the other three as objects of `parla' -- `habla
%% con Ferrara, a Sgarbi, a Previti y Andreotti'
tr_list_item(Side, W) :- tr_name_word(Side, W), !.

%% A COMMA BETWEEN TWO ADJECTIVES BEFORE THEIR NOUN IS THE PHRASE'S: `con i
%% nuovi, piccoli, meschini, Hitler di questa fine secolo', the new, small,
%% petty Hitlers, was refused whole -- `, piccoli,' was taken for an aside
%% of `nuovi' (tr_asides/3), and a plain comma ends a phrase besides. After
%% a determiner, adjectives with commas between them and then a noun or a
%% name, a comma before it included, are one phrase, and each comma is the
%% ADJECTIVES' (w(',', acomma)): a coordinator to the adjectives, which keep
%% it and every writer puts back where the source had it, and never one a
%% phrase is divided at (tr_conjunction_split/5) -- the list's own comma
%% (lcomma) divides one. It is read before the asides are, so that none of
%% them sees a comma there.
tr_adj_lists(_, [], []).
tr_adj_lists(Side, [D|Ws0], [D|Ws]) :-
    D = w(_, _), tr_determiner(Side, D, _, _),
    tr_adj_commas(Side, Ws0, As, [N|Rest]),
    N = w(_, _), ( tr_is(Side, N, noun) ; tr_name_word(Side, N) ), !,
    append(As, [N|Ws1], Ws),
    tr_adj_lists(Side, Rest, Ws1).
tr_adj_lists(Side, [W|Ws0], [W|Ws]) :- tr_adj_lists(Side, Ws0, Ws).

%% two adjectives or more with a comma between each two, and perhaps one after
%% the last: the commas come back as the list's
tr_adj_commas(Side, [A, comma, B|Ws], [A, w(',', acomma)|Os], Rest) :-
    tr_comma_adj(Side, A), tr_comma_adj(Side, B), !,
    tr_adj_commas1(Side, [B|Ws], Os, Rest).
tr_adj_commas1(Side, [A, comma, B|Ws], [A, w(',', acomma)|Os], Rest) :-
    tr_comma_adj(Side, A), tr_comma_adj(Side, B), !,
    tr_adj_commas1(Side, [B|Ws], Os, Rest).
tr_adj_commas1(_, [A, comma|Ws], [A, w(',', acomma)], Ws) :- !.
tr_adj_commas1(_, [A|Ws], [A], Ws).

tr_comma_adj(Side, A) :- A = w(_, lower), tr_is(Side, A, adjective), tr_adj_word(Side, A), !.

tr_names_go_on(Side, Ws) :-
    append(Ns, [X|_], Ws), Ns \== [], forall(member(N, Ns), N = w(_, upper)),
    ( X == comma ; X = w(_, _), tr_coord(Side, X) ), !.

tr_list_tail(Side, Ws) :-
    append(S, [C|Rest0], Ws), S \== [], C = w(_, _), tr_coord(Side, C), tr_list_items(Side, S), !,
    append(T, Rest, Rest0), T \== [], forall(member(X, T), tr_list_word(Side, X)),
    ( Rest == [] ; Rest = [N|_], \+ tr_list_word(Side, N), \+ tr_verb_next(Side, Rest) ), !.

%% a verb next, or after a denial: `Han comido pan, Rivaldo y Overmars NO
%% ESTUVIERON en Gandía' -- the two names are the subject of a clause of
%% their own, and taken for the end of a list of what was eaten, the
%% bread, Rivaldo and Overmars, the sentence was divided at the `y'
tr_verb_next(Side, [N|Ns]) :-
    N = w(W, _),
    (   ( tr_is(Side, N, verb) ; Side == foreign, tr_verb_form_word(W) ) -> true
    ;   ( tr_negation_word(W) ; tr_denying_adverb(Side, N) ), tr_verb_next(Side, Ns)
    ).

%% the list's tail with anything after it: phrase words, a coordinator,
%% phrase words, and then something that is no phrase's word
tr_list_tail_head(Side, Ws) :-
    append(S, [C|Rest0], Ws), S \== [], C = w(_, _), tr_coord(Side, C), tr_list_items(Side, S), !,
    append(T, Rest, Rest0), T \== [], forall(member(X, T), tr_list_word(Side, X)),
    ( Rest == [] ; Rest = [N|_], \+ tr_list_word(Side, N) ), !.

%% THE ITEMS BEFORE THE COORDINATOR MAY HAVE COMMAS BETWEEN THEM: `i cani, i
%% gatti, i topi e i conigli' is one list of four. Held to words with no
%% comma, the tail after the FIRST comma was no list's, that comma stayed
%% the clause's, and the dogs became an object of their own beside a list
%% of three -- and at the head of a sentence, `Il cane, il gatto, il topo e
%% il coniglio mangiano il pane' read as a verbless piece, `the dog, the
%% cat', joined to a clause whose subject was the mouse and the rabbit.
%% A comma between two items, never at either end, never two together.
tr_list_items(Side, S) :-
    S = [X0|_], X0 \== comma, last(S, XL), XL \== comma,
    \+ append(_, [comma, comma|_], S),
    forall(member(X, S), ( X == comma ; tr_list_word(Side, X) )).

tr_list_word(Side, W) :-
    W = w(_, _), \+ tr_coord(Side, W),
    ( tr_is(Side, W, noun) ; tr_is(Side, W, adjective) ; tr_determiner(Side, W, _, _) ; tr_is(Side, W, number) ; W = w(_, upper) ), !.

%% ---- into the IR: the crossing walk ----------------------------------------------

%% the same lookups the writer into English makes, made once over the
%% term rather than over the words coming out of it -- so a sentence read
%% on the lesson's side becomes the same term an English sentence reads
%% as, and anything that can write one can write the other
%% two clauses joined: the connector crosses to English as the word it is,
%% and each side crosses as the sentence it is
tr_cross(_, none, none) :- !.
tr_cross(_, gap(F0, B0), gap(F, B)) :- !, tr_cross_comps(F0, F), tr_cross_comps(B0, B).
tr_cross(Side, q(S0), q(S)) :- !, tr_cross(Side, S0, S).
tr_cross(Side, join(C0, A0, B0), join(C, A, B)) :- !,
    tr_cross_connector(Side, C0, C), tr_cross(Side, A0, A), tr_cross(Side, B0, B).
tr_cross(english, S0, S) :- !, tr_cross_which(S0, S).
tr_cross(foreign, s(Asked0, Subject0, g(L0, T, A, Neg), Comps0), s(Asked, Subject, g(L, T, A, Neg), Comps)) :-
    tr_global('$tr_obj_gap', Gap), nb_setval('$tr_obj_gap', no),
    (   A == simple, tr_state_lexeme(L0) -> tr_lexeme_across(L0, english, L1), L = state(L1)
    ;   tr_verb_across(L0, A, Comps0, Gap, L)
    ),
    tr_cross_asked(Asked0, Asked),
    tr_cross_subject(Asked, Subject0, Subject),
    tr_cross_inf_comps(Comps0, Comps).

%% THE INFINITIVE AFTER A MODAL TAKES ITS SENSE BY THE CLAUSE'S OBJECT, as
%% the verb itself does (tr_verb_across/5): `deve finire in tribunale' has
%% none, so `finire' is the intransitive `ends up' and never `finishes'
tr_cross_inf_comps(Comps0, Comps) :-
    append(Pre0, [inf(IL)|Post0], Comps0), atom(IL), tr_intransitive_meanings(IL, [IM|_]),
    \+ ( member(C, Comps0), tr_object_comp(C) ), !,
    tr_cross_comps(Pre0, Pre), tr_cross_comps(Post0, Post), append(Pre, [inf(IM)|Post], Comps).
tr_cross_inf_comps(Comps0, Comps) :- tr_cross_comps(Comps0, Comps).

%% A VERB'S MEANING BY WHETHER ITS CLAUSE HAS AN OBJECT. `De la amplia
%% gama de instrumentos ..., destaca un violín' is a violin that STANDS
%% OUT, and `El constructor destacó algunas de las diferencias' a builder
%% who HIGHLIGHTED them: one verb, and what tells the senses apart is the
%% object, which nothing but the clause can say. A lesson gives the first
%% sense as the verb's intransitive one -- `The intransitive verb "destaca"
%% means "stands out".', which is also what lets the phrase after it be its
%% subject -- and a clause with no object takes it, where a clause with one
%% takes the first meaning that is not it. A relative clause whose relative
%% word IS the object has one (`el violín que destacó el experto'), which
%% the phrase that carries it says through '$tr_obj_gap', and a passive
%% has one by what it is. Everywhere else -- a reduced relative, a
%% participle, a verb with no such meaning -- tr_lexeme_across/3 passes the
%% intransitive meaning over, so the verb crosses as it always did.
%% -- AND A PRONOUN BEFORE AN INTRANSITIVE VERB WHOSE SUBJECT STANDS AFTER
%% IT IS WHO IT PLEASES: `Me gusta la escuela' has no object, and with `me'
%% counted as one `gusta' took the transitive `likes' and the school liked
%% me. The reader put the subject there (subj_here) because the lesson calls
%% the verb intransitive, so a pronoun before it can only be the dative.
tr_verb_across(L0, A, Comps, Gap, L) :-
    atom(L0), tr_intransitive_meanings(L0, Is), !,
    (   ( Gap == yes ; memberchk(A, [passive, passive_perfect])
        ; member(C, Comps), tr_object_comp(C), \+ tr_dative_here(L0, C, Comps) )
    ->  tr_lexeme_across(L0, english, L)
    ;   Is = [L|_]
    ).
tr_dative_here(L0, opron(_), Comps) :- memberchk(subj_here, Comps), tr_solve(intransitive(L0)), !.
%% A VERB THE LESSON ALSO CALLS A MODAL IS THE MODAL BEFORE AN INFINITIVE:
%% `deve' is `owes' and `must', and `La terapia deve essere attivata' owed
%% where it must -- a meaning shaped like a third person comes first in a
%% verb's place (tr_english_shaped/3), and no modal's ever is.
tr_verb_across(L0, _, [inf(_)|_], _, L) :-
    atom(L0), tr_class_of(L0, modal), tr_meanings_of(L0, english, modal, Ms),
    member(L, Ms), en_modal_out(L, _, _), !.
tr_verb_across(L0, _, _, _, L) :- tr_lexeme_across(L0, english, L).

tr_intransitive_meanings(L, Is) :- findall(M, tr_solve(mean_as(L, M, intransitive)), Is), Is \== [].

%% a complement that is the verb's object -- never a pronoun the reader
%% marked as the dative
tr_object_comp(obj(_)).
tr_object_comp(opron(W)) :- W \= dat(_).
tr_object_comp(oc(_, _)).
tr_object_comp(that(_)).
tr_object_comp(fr(C)) :- tr_object_comp(C).
tr_object_comp(frc(C)) :- tr_object_comp(C).
tr_object_comp(frn(C)) :- tr_object_comp(C).

%% THE COPULA OF A STATE IS NOT THE COPULA, and the IR keeps them apart:
%% `Stiamo a pezzi' is Spanish's `Estamos destrozados' and never `Somos'.
%% Both languages mean `is' by two words, and the one the lesson calls the
%% AUXILIARY (the progressive's `sta', `está') is the state's when it has no
%% gerund after it. The lexeme travels as state(is): English writes `is',
%% and a lesson writes the word it says marks the state (`The auxiliary
%% "está" marks the state.') or, saying nothing, its plain copula -- which
%% is Italian's `sono distrutti' for Spanish's `están destrozados'.
tr_state_lexeme(L) :- atom(L), tr_solve(auxiliary(L)), tr_solve(mean(L, is)), !.

tr_state_word(W) :- tr_solve(mark(W, state)), !.

%% the connector of a join, across: a comma as itself, a word by its meaning
tr_cross_connector(_, comma, comma) :- !.
tr_cross_connector(_, w(',', lcomma), w(',', lcomma)) :- !.
tr_cross_connector(_, w(',', acomma), w(',', acomma)) :- !.
tr_cross_connector(_, M, M) :- atom(M), memberchk(M, [semicolon, colon, endquote, endquote_comma, endquote_plain, endquote_plain_comma, dash, dashes, reported, aside]), !.
tr_cross_connector(Side, w(W, C), w(T, C)) :-
    ( Side == english -> T = W ; tr_lexeme(foreign, W, L, _), tr_meanings_of(L, english, conjunction, [T|_]) ), !.
tr_cross_connector(Side, wc(W0), wc(W)) :- !, tr_cross_connector(Side, W0, W).
%% the word that opens a comment between commas crosses as what it was read
%% as: `come si dice a Napoli' is as they say in Naples, and by `come''s
%% first meaning it was `how', which Spanish wrote `cómo se dice'
tr_cross_connector(_, cmt(w(_, C)), cmt(w(as, C))) :- !.

%% the English side crosses nothing, and normalises one thing: a `which'
%% question carries the words of its phrase, and the IR carries the phrase
tr_cross_which(s(Asked0, Subject0, G, Comps), s(Asked, Subject, G, Comps)) :-
    tr_cross_which_asked(Asked0, Asked),
    (   Subject0 = asked(_), Asked = subject(Q) -> Subject = asked(Q)
    ;   Subject = Subject0
    ).

tr_cross_which_asked(none, none) :- !.
tr_cross_which_asked(pp(P, which(Ws, C)), pp(P, which_np(NP, C))) :- !, tr_which_phrase(english, Ws, NP).
tr_cross_which_asked(A0, A) :- A0 =.. [Kind, which(Ws, C)], !, tr_which_phrase(english, Ws, NP), A =.. [Kind, which_np(NP, C)].
tr_cross_which_asked(A, A).

%% what is asked, across: the question word by what it asks for, or the
%% phrase of a `which' read and crossed
tr_cross_asked(none, none) :- !.
tr_cross_asked(pp(w(P, PC), Q0), pp(w(PT, PC), Q)) :- !, tr_prep_across(P, PT), tr_cross_q(pp, Q0, Q).
tr_cross_asked(A0, A) :- A0 =.. [Kind, Q0], tr_cross_q(Kind, Q0, Q), A =.. [Kind, Q].

tr_cross_q(_, which(Ws, C), which_np(NP, C)) :- !, tr_side_here(Side), tr_which_phrase(Side, Ws, NP0), tr_cross_which_np(NP0, NP).

%% THE PHRASE A `which' ASKS WITH MAY CARRY ITS OWN `di' PHRASES: `in che
%% razza di mondo' is what kind of world, and read as a phrase with no
%% preposition in it the question was refused -- the subject reader's
%% with/2, crossed and written as a subject's is
tr_which_phrase(Side, Ws, NP) :- tr_np(Side, Ws, NP), !.
tr_which_phrase(Side, Ws, with(NP, PPs)) :- tr_subject(Side, none, Ws, _, _, with(NP, PPs)).
tr_cross_which_np(with(NP0, PPs0), with(NP, PPs)) :- !, tr_cross_np(NP0, NP), tr_cross_comps(PPs0, PPs).
tr_cross_which_np(NP0, NP) :- tr_cross_np(NP0, NP).
tr_which_np_out(To, with(NP, PPs), Outs, Noun, Number) :- !, tr_subject_out(To, with(NP, PPs), Outs, _, Number, Noun).
tr_which_np_out(To, NP, Outs, Noun, Number) :- tr_np_out(To, NP, Outs, Noun, Number).
tr_cross_q(Kind, w(Q, C), w(QT, C)) :- tr_question_across(english, Kind, Q, QT).

%% the subject, across: the question word when the subject is what is
%% asked (already crossed), `there' as itself, a name as itself, and the
%% person and number of a pronoun or of nobody kept as they were read
tr_cross_subject(subject(Q), asked(_), asked(Q)) :- !.
tr_cross_subject(_, none, none) :- !.
tr_cross_subject(_, gap, gap) :- !.
tr_cross_subject(_, gap(P, N), gap(P, N)) :- !.
tr_cross_subject(_, there, there) :- !.
tr_cross_subject(_, name(W), name(W)) :- !.
tr_cross_subject(_, null(P, N), null(P, N)) :- !.
tr_cross_subject(_, addressee(N), addressee(N)) :- !.
tr_cross_subject(_, impersonal, impersonal) :- !.
tr_cross_subject(_, pronoun(P, N, w(W, C)), pronoun(P, N, w(T, C))) :- !, tr_pronoun_across(english, subject, w(W, C), P, N, T).
tr_cross_subject(A, nei(Co0), nei(Co)) :- !, tr_cross_subject(A, Co0, Co).
tr_cross_subject(A, one(Co0), one(Co)) :- !, tr_cross_subject(A, Co0, Co).
tr_cross_subject(A, co(C0, S1, S2), co(C, T1, T2)) :- !,
    tr_side_here(Side), tr_cross_connector(Side, C0, C), tr_cross_subject(A, S1, T1), tr_cross_subject(A, S2, T2).
tr_cross_subject(_, with(NP0, PPs0), with(NP, PPs)) :- !, tr_cross_np(NP0, NP), tr_cross_comps(PPs0, PPs).
tr_cross_subject(_, infs(L0, Cs0), infs(L, Cs)) :- !, tr_lexeme_across(L0, english, L), tr_cross_comps(Cs0, Cs).
tr_cross_subject(_, infs(L0, Cs0, C), infs(L, Cs, C)) :- !, tr_lexeme_across(L0, english, L), tr_cross_comps(Cs0, Cs).
tr_cross_subject(_, NP0, NP) :- tr_cross_np(NP0, NP).

%% a phrase, across: the noun's lexeme in English, the determiner as the
%% word of its kind (never the form -- the number inflects it on the way
%% out), a number word, and each adjective's first meaning
tr_cross_np(ncl(NP0, S0), ncl(NP, S)) :- !,
    tr_cross_np(NP0, NP), tr_side_here(Side), tr_cross(Side, S0, S).
tr_cross_np(nrc(NP0, Role0, S0), nrc(NP, Role, S)) :- !, tr_cross_np(rc(NP0, Role0, S0), rc(NP, Role, S)).
tr_cross_np(what_np(NP0), what_np(NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_np(rc(NP0, Role0, S0), rc(NP, Role, S)) :- !,
    tr_cross_np(NP0, NP), tr_side_here(Side),
    (   Role0 = pp(w(P, C)) -> tr_word_across(w(P, lower), english, preposition, PT), Role = pp(w(PT, C))
    ;   Role = Role0
    ),
    %% a relative word that is the object is the clause's object
    (   Role0 == object
    ->  nb_setval('$tr_obj_gap', yes),
        ( tr_cross(Side, S0, S) -> nb_setval('$tr_obj_gap', no) ; nb_setval('$tr_obj_gap', no), fail )
    ;   tr_cross(Side, S0, S)
    ).
tr_cross_np(app(NP0, year, Y), app(NP, year, Y)) :- !, tr_cross_np(NP0, NP).     % a year is its digits everywhere
tr_cross_np(app(NP0, label, N), app(NP, label, N)) :- !, tr_cross_np(NP0, NP).    % and so is a label
tr_cross_np(app(NP0, apposed, N), app(NP, apposed, N)) :- !, tr_cross_np(NP0, NP).  % and a name
tr_cross_np(app(NP0, Kind, K), app(NP, Kind, Inner)) :- !,
    tr_cross_np(NP0, NP), tr_aside_inner(K, Inner).
tr_cross_np(rel(NP0, L0, Cs0), rel(NP, L, Cs)) :- !,
    tr_cross_np(NP0, NP), tr_lexeme_across(L0, english, L), tr_cross_comps(Cs0, Cs).
tr_cross_np(adv(w(A, C)), adv(w(AT, C))) :- !, tr_word_across(w(A, lower), english, adverb, AT).
tr_cross_np(name(W), name(W)) :- !.
tr_cross_np(all(w(_, C), NP0), all(w(all, C), NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_np(np(Det0, Num0, Adjs0, elided(G), Number), np(Det, Num, Adjs, elided(G), Number)) :- !,
    tr_cross_det(Det0, Det), tr_cross_num(Num0, Num), tr_cross_adjectives(Adjs0, Adjs).
tr_cross_np(advp(w(A, C), NP0), advp(w(AT, C), NP)) :- !,
    tr_word_across(w(A, lower), english, adverb, AT), tr_cross_np(NP0, NP).
tr_cross_np(ell(Det0, G, Number, none), ell(Det, G, Number, none)) :- !, tr_cross_det(Det0, Det).
tr_cross_np(ell(Det0, G, Number, rel(Role0, S0)), ell(Det, G, Number, rel(Role, S))) :- !,
    tr_cross_det(Det0, Det),
    tr_cross_np(rc(np(none, none, [], elided(G), Number), Role0, S0), rc(_, Role, S)).
tr_cross_np(ell(Det0, G, Number, PP0), ell(Det, G, Number, PP)) :- !,
    tr_cross_det(Det0, Det), tr_cross_comp(PP0, PP).
tr_cross_np(pronoun(w(W, C)), pronoun(w(T, C))) :- !, tr_pronoun_across(english, oblique, w(W, C), _, _, T).
tr_cross_np(co(C0, N1, N2), co(C, T1, T2)) :- !,
    tr_side_here(Side), tr_cross_connector(Side, C0, C), tr_cross_np(N1, T1), tr_cross_np(N2, T2).
%% the article a lesson puts before a year is its language's, and comes off
tr_cross_np(np(det(article, _, _), none, [], w(Y, C), singular), np(none, none, [], w(Y, C), singular)) :-
    tr_year(Y), once(tr_solve(take(_, year))), !.
%% a name crosses as itself, gender and all: nothing in it is a word of any
%% language, so there is nothing to look up
tr_cross_np(np(Det0, Num0, Adjs0, named(G, Ws), Number), np(Det, Num, Adjs, named(G, Ws), Number)) :- !,
    tr_cross_det(Det0, Det), tr_cross_num(Num0, Num), tr_cross_adjectives(Adjs0, Adjs).
tr_cross_np(np(Det0, Num0, Adjs0, w(NW, NC), Number), np(Det, Num, Adjs, w(Noun, NC), Number)) :-
    tr_noun_lexeme(english, NW, Number, _, Noun),
    tr_cross_det(Det0, Det),
    tr_cross_num(Num0, Num),
    tr_cross_adjectives(Adjs0, Adjs).

tr_cross_det(none, none) :- !.
%% a possessive crosses by the meaning that IS a possessive: `loro' is they,
%% them and their, and `le loro condizioni' came out `they conditions'
tr_cross_det(det(possessive, DL, w(_, C)), det(possessive, T, w(T, C))) :-
    tr_side_here(foreign), tr_solve(mean(DL, T)), en_possessive(T), !.
tr_cross_det(det(Kind, DL, w(_, C)), det(Kind, T, w(T, C))) :- tr_word_across(w(DL, lower), english, Kind, T).

tr_cross_num(none, none) :- !.
tr_cross_num(w(MW, MC), w(MT, MC)) :- !, tr_word_across(w(MW, MC), english, number, MT).
tr_cross_num(adv_num(w(A, C), M0), adv_num(w(AT, C), M)) :- !,
    tr_word_across(w(A, lower), english, adverb, AT), tr_cross_num(M0, M).
tr_cross_num(nums(M10, C0, M20), nums(M1, C, M2)) :-
    tr_cross_num(M10, M1), tr_side_here(Side), tr_cross_connector(Side, C0, C), tr_cross_num(M20, M2).

tr_cross_adjectives([], []).
tr_cross_adjectives([A0|As0], [A|As]) :- tr_cross_adjective(A0, A), tr_cross_adjectives(As0, As).

tr_cross_adjective(deg(D, A0), deg(D, A)) :- !, tr_cross_adjective(A0, A).
tr_cross_adjective(pre(A0), pre(A)) :- !, tr_cross_adjective(A0, A).
tr_cross_adjective(w(W, appos), w(W, appos)) :- !.
tr_cross_adjective(int(w(A0, C), J0), int(w(A, C), J)) :- !,
    tr_word_across(w(A0, lower), english, adverb, A), tr_cross_adjective(J0, J).
tr_cross_adjective(w(W, C), T) :- tr_side_here(Side), tr_coord(Side, w(W, C)), !, tr_cross_coord(Side, w(W, C), T).
%% A NAME APPOSED TO A NOUN CROSSES AS ITSELF -- `il presidente Scalfaro' --
%% which is what being a name means, and without it the phrase read and the
%% crossing failed, so the sentence was refused with no shape missing.
tr_cross_adjective(w(W, upper), w(W, upper)) :- tr_side_here(Side), \+ tr_known_word(Side, W), !.
tr_cross_adjective(w(W, C), w(T, C)) :- tr_lexeme_here(W, WL), tr_meanings_of(WL, english, adjective, [T|_]).

%% A COORDINATOR AMONG ADJECTIVES CROSSES AS ONE -- English's `and', `or',
%% `nor' or `but', the meaning by which tr_coord_word/1 took the word for a
%% coordinator at all: `no habría sido prudente ni serio' is careful NOR
%% serious, and by `ni''s first meaning, `neither', the list had one more
%% adjective in its middle, which Italian wrote `prudente neanche serio'
tr_cross_coord(foreign, w(W, C), w(T, C)) :-
    W \== ',', tr_lexeme(foreign, W, L, _), tr_meanings_of(L, english, conjunction, Ms),
    member(T, Ms), memberchk(T, [and, or, nor, but]), !.
tr_cross_coord(Side, W, T) :- tr_cross_connector(Side, W, T).

%% the complements, across, each in its place
tr_cross_comps([], []).
tr_cross_comps([C0|Cs0], [C|Cs]) :- tr_cross_comp(C0, C), tr_cross_comps(Cs0, Cs).

tr_cross_comp(fr(C0), fr(C)) :- !, tr_cross_comp(C0, C).
tr_cross_comp(frc(C0), frc(C)) :- !, tr_cross_comp(C0, C).
tr_cross_comp(mid(C0), mid(C)) :- !, tr_cross_comp(C0, C).
tr_cross_comp(frn(C0), frn(C)) :- !, tr_cross_comp(C0, C).
tr_cross_comp(sep, sep) :- !.
tr_cross_comp(vq, vq) :- !.
tr_cross_comp(vqc, vqc) :- !.
tr_cross_comp(paren(K), paren(Inner)) :- !, tr_aside_inner(K, Inner).
tr_cross_comp(comment(K), comment(clause(S))) :- !, nb_getval(K, Ws), tr_side_here(Side), tr_aside_clause(Side, Ws, S).
tr_cross_comp(subj_here, subj_here) :- !.
tr_cross_comp(agr(G), agr(G)) :- !.
tr_cross_comp(agrn(N), agrn(N)) :- !.
tr_cross_comp(aside(C), aside(C)) :- !.
tr_cross_comp(pdeg(D), pdeg(D)) :- !.
tr_cross_comp(padv(w(A, C)), padv(w(AT, C))) :- !, tr_word_across(w(A, lower), english, adverb, AT).
tr_cross_comp(pcase(C), pcase(C)) :- !.
tr_cross_comp(appos(NP0), appos(NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_comp(topic(NP0), topic(NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_comp(obj(NP0), obj(NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_comp(adj(Ws0), adj(Ws)) :- !, tr_cross_adjectives(Ws0, Ws).
tr_cross_comp(oc(NP0, Ws0), oc(NP, Ws)) :- !, tr_cross_np(NP0, NP), tr_cross_adjectives(Ws0, Ws).
tr_cross_comp(that(S0), that(S)) :- !, tr_side_here(Side), tr_cross(Side, S0, S).
tr_cross_comp(wh(Q, S0), wh(Q, S)) :- !, tr_side_here(Side), tr_cross(Side, S0, S).
tr_cross_comp(rwh(Q, S0), rwh(Q, S)) :- !, tr_side_here(Side), tr_cross(Side, S0, S).
tr_cross_comp(pp(w(P, C), NP0), pp(w(PT, C), NP)) :- !, tr_prep_across(P, PT), tr_cross_np(NP0, NP).
tr_cross_comp(rpp(w(P, C), NP0), rpp(w(PT, C), NP)) :- !, tr_prep_across(P, PT), tr_cross_np(NP0, NP).
tr_cross_comp(adv(w(A, C)), adv(w(AT, C))) :- !, tr_word_across(w(A, lower), english, adverb, AT).
tr_cross_comp(purpose(L), purpose(LT)) :- !, tr_lexeme_across(L, english, LT).
tr_cross_comp(ger(reflexive(L), Cs0), ger(reflexive(LT), Cs)) :- !, tr_lexeme_across(L, english, LT), tr_cross_comps(Cs0, Cs).
tr_cross_comp(ger(L, Cs0), ger(LT, Cs)) :- !, tr_lexeme_across(L, english, LT), tr_cross_comps(Cs0, Cs).
tr_cross_comp(upon(L, Cs0), upon(LT, Cs)) :- !, tr_lexeme_across(L, english, LT), tr_cross_comps(Cs0, Cs).
%% the infinitive of the copula of a state is that copula's too: `o stare a
%% guardare' is to stand by, and crossed as plain `is' Spanish wrote `ser a
%% mirar', where the lesson's language says the state with its own verb
tr_cross_comp(inf(L), inf(state(LT))) :- tr_state_lexeme(L), !, tr_lexeme_across(L, english, LT).
tr_cross_comp(inf(L), inf(LT)) :- !, tr_lexeme_across(L, english, LT).
tr_cross_comp(ainf(w(_, C), L), ainf(w(to, C), LT)) :- !, tr_lexeme_across(L, english, LT).
tr_cross_comp(neg(C0), neg(C)) :- !, tr_cross_comp(C0, C).
tr_cross_comp(cmp(K, NP0), cmp(K, NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_comp(cmpp(A0, K, PP0), cmpp(A, K, PP)) :- !,
    ( A0 == none -> A = none ; A0 = w(W, C), tr_word_across(w(W, lower), english, adverb, AT), A = w(AT, C) ),
    tr_cross_comp(PP0, PP).
tr_cross_comp(mt(Ws0), mt(Ws)) :- !, tr_cross_adjectives(Ws0, Ws).
tr_cross_comp(nprep(w(P, C)), nprep(w(PT, C))) :- !, tr_prep_across(P, PT).
tr_cross_comp(pinf(w(P, C), cl(L, Cls0)), pinf(w(PT, C), cl(LT, Cls))) :- !,
    tr_prep_across(P, PT), tr_lexeme_across(L, english, LT),
    findall(X, ( member(Cl, Cls0), tr_cross_comp(opron(Cl), opron(X)) ), Cls).
tr_cross_comp(pinf(w(P, C), L), pinf(w(PT, C), LT)) :- !,
    tr_prep_across(P, PT), tr_lexeme_across(L, english, LT).
tr_cross_comp(infx(L, A, Cls0), infx(LT, A, Cls)) :- !,
    tr_lexeme_across(L, english, LT), maplist(tr_cross_enclitic, Cls0, Cls).
tr_cross_comp(pred(L), pred(LT)) :- !, tr_lexeme_across(L, english, LT).
tr_cross_comp(predq(L, C), predq(LT, C)) :- !, tr_lexeme_across(L, english, LT).
tr_cross_comp(at_time(NP0), at_time(NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_comp(cnj(w(C, CC)), cnj(w(CT, CC))) :- !, tr_cross_connector(foreign, w(C, CC), w(CT, CC)).
tr_cross_comp(by(NP0), by(NP)) :- !, tr_cross_np(NP0, NP).
%% A DATIVE PRONOUN STAYS ONE: `gli' is to him, and the IR keeps it apart
%% from `lo', him himself, so a lesson that says which of its pronouns are
%% datives writes one of them (`le', `les') -- English has one word for both
tr_cross_comp(opron(w(W, C)), opron(dat(w(T, C)))) :-
    tr_lexeme(foreign, W, L, _), tr_solve(dative(L)), !, tr_pronoun_across(english, object, w(W, C), _, _, T).
tr_cross_comp(opron(w(W, C)), opron(w(T, C))) :- tr_pronoun_across(english, object, w(W, C), _, _, T).

%% a pronoun joined to an infinitive: the reflexive is `refl' in the IR, as
%% the reflexive verb carries no pronoun of its own there; any other is the
%% English object pronoun it means
tr_cross_enclitic(Cl, refl) :- tr_reflexive_word(Cl), !.
tr_cross_enclitic(Cl, w(T, lower)) :- tr_pronoun_across(english, object, w(Cl, lower), _, _, T).

%% ---- reading: a question into the statement's order -------------------------------

%% A READING THAT FAILED FAILS AGAIN, AND IS NOT TRIED AGAIN. A sentence
%% with several commas is divided at each of them in turn, each side read
%% and each side divided again, so the same run of words is asked for over
%% and over: the tail after the second comma is read inside the division at
%% the first and again at the second. What failed is kept, for the piece
%% being read, in one assoc keyed on the words themselves, and asked for
%% before anything is tried; a reading that succeeds is the first and only
%% one (every clause below cuts), so there is nothing to keep for it.
tr_read(Side, Kind, Words, S) :-
    tr_global('$tr_no_command', NC), Key = k(Side, Kind, Words, NC),
    tr_failed_set(F0),
    (   get_assoc(Key, F0, _) -> fail
    ;   tr_read0(Side, Kind, Words, S0) -> tr_wh_after_object(S0, S)
    ;   tr_failed_set(F1), put_assoc(Key, F1, x, F2), nb_setval('$tr_failed', F2), fail
    ).

%% A QUESTION WORD AFTER THE VERB'S OWN OBJECT OPENS NO QUESTION. Right after
%% the verb it is the indirect question tr_complements0/4 reads (`sapere
%% come'), and after another complement tr_relative_wh/2 makes it the
%% relative one -- but an object PRONOUN stands before the verb and is no
%% complement there, so `l'abbiamo vinto quando gli altri erano vicini' was
%% the question `cuándo' in Spanish. It is the time the verb's object was
%% won at, rwh/2, as after any other complement. A dative is no object: `gli
%% ho chiesto quando arriva' asks.
tr_wh_after_object(s(A, Su, G, Cs0), s(A, Su, G, Cs)) :-
    memberchk(opron(w(_, _)), Cs0), memberchk(wh(_, _), Cs0), !,
    tr_relative_wh1(Cs0, Cs).
tr_wh_after_object(S, S).

tr_failed_set(F) :- ( catch(nb_getval('$tr_failed', F0), _, fail) -> F = F0 ; empty_assoc(F) ).

%% A SENTENCE MAY HOLD SEVERAL CLAUSES, and where they divide is a comma or
%% a connecting word -- `Il blitz e riuscito, l'operazione e considerata
%% conclusa', `La sinistra l'ha attaccata perche Pivetti non si e adeguata'.
%% Half the newspaper sample needs it and none of it could be reached before,
%% because the comma was dropped in tr_words/2 and tr_split/2 divides on `.',
%% `!' and `?' alone.
%%
%% THE WHOLE PIECE IS TRIED AS ONE STATEMENT FIRST, which is what makes this
%% a strict addition: every sentence that read before reads the same way and
%% by the same clauses. Only when that fails is a division looked for, and a
%% division is taken only when BOTH sides read as clauses of their own --
%% which is what keeps `la sua identita e la sua nazionalita' one subject
%% rather than two sentences, with no rule about phrases needed.
%% A HEADING IN CAPITALS IS READ WITH NO VERB FIRST (tr_caps_piece/2):
%% the whole piece, as the verbless reading reads a heading, and only when
%% that fails is it read as any other sentence
tr_read0(Side, statement, Words0, S) :-
    tr_global('$tr_caps', yes), tr_global('$tr_piece', Piece), Piece == Words0,
    tr_as_heading(Words0, tr_verbless(Side, Words0, S)), !.
%% A SEMICOLON DIVIDES FIRST. Every other reading below is tried on the
%% whole piece before a division is looked for, which is right for a comma
%% -- a comma is often inside a clause -- and wasted on a semicolon, which
%% never is: measured, one 40-word sentence with a `;' in it spent 185 s
%% refusing itself in whole-sentence readings before the split was tried.
tr_read0(Side, Kind, Words0, S) :-
    memberchk(semicolon, Words0),
    append(Left0, [semicolon|Right0], Words0),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right),
    tr_read(Side, Kind, Left, S1), tr_read(Side, statement, Right, S2), !,
    S = join(semicolon, S1, S2).
%% THE COPULA AFTER A COMMA DIVIDES FIRST TOO, WHERE IT IS ALSO A NOUN: `el
%% telefonino ... estaba vacío, era de pega' -- it WAS a fake. `era' is an
%% era as well, and every reading of the whole piece took it for one: after
%% the comma, a fake era the telephone was empty with, and with the commas
%% taken out a phrase, `vacío era de pega'. After a comma, with no article
%% before it, a form of the copula that opens a clause with nobody named for
%% its subject opens that clause.
tr_read0(Side, Kind, Words0, S) :-
    Side == foreign, memberchk(comma, Words0),
    append(Left0, [comma, W|More], Words0), Left0 \== [], \+ memberchk(comma, More),
    W = w(V, lower), tr_is(Side, W, noun),
    tr_form(V, L, _, _, _), atom(L), tr_copula_lexeme(L),
    tr_read(Side, statement, [W|More], S2), S2 = s(_, null(_, _), _, _),
    tr_clause_words(Left0, Left), tr_read(Side, Kind, Left, S1), !,
    S = join(comma, S1, S2).
%% A QUOTATION AND THE CLAUSE THAT REPORTS IT: `... incastrati in un dirupo”
%% ha raccontato a Sky Tg24 Tornaboni.' The closing mark is where the
%% quotation's own clause ends (tr_speech_pieces/2 made it `endquote'), and
%% what follows is a REPORTING clause, whose subject stands after its verb
%% in the lesson's languages -- read by tr_read_reporting/3, and failing that
%% as a statement like any other.
%% A comma after the closing mark -- `son únicos ", dijo Claude Lebet' --
%% is the source's, and it is written back after the mark.
tr_read0(Side, Kind, Words0, S) :-
    member(E, [endquote, endquote_plain]), memberchk(E, Words0),
    append(Left0, [E|Right0], Words0), \+ memberchk(E, Left0),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right),
    tr_read(Side, Kind, Left, S1),
    ( tr_read_reporting(Side, Right, S2) -> true ; tr_read(Side, statement, Right, S2) ), !,
    ( Right0 = [comma|_] -> atom_concat(E, '_comma', C) ; C = E ),
    S = join(C, S1, S2).
%% ... and the reporting clause set off with dashes, a closing dash or none:
%% `bisognerebbe sapere come sono finiti lì – ha spiegato un soccorritore -.'
%% -- and never ONE capitalised word before the dash that a phrase reads:
%% that is the dateline below, and `Calcio - nell'ambito della
%% presentazione ...' read here as a clause `calcio', I kick
tr_read0(Side, Kind, Words0, S) :-
    memberchk(dash, Words0),
    append(Left0, [dash|Right0], Words0), \+ memberchk(dash, Left0),
    \+ ( Left0 = [W1], tr_dateline_word(Side, W1, _) ),
    ( append(Right1, [dash], Right0) -> Conn = dashes ; Right1 = Right0, Conn = dash ),
    \+ memberchk(dash, Right1),
    tr_clause_words(Left0, Left), tr_clause_words(Right1, Right),
    tr_read(Side, Kind, Left, S1),
    ( tr_read_reporting(Side, Right, S2) -> true ; tr_read(Side, statement, Right, S2) ), !,
    S = join(Conn, S1, S2).
%% A DATELINE: `Roma - lo stato ha il diritto dovere di favorire ...'. A
%% news item opens with the place it was filed from and a dash, and the
%% sentence is what follows the dash -- which read as the clause above has
%% a lone name for a clause of its own, and was refused. The place is ONE
%% word the phrase reader takes for a name, at the head of the piece, and
%% it is written back where it stood, with its dash: `Roma – el estado
%% tiene ...'. A place of several words is not read, because a bare run of
%% capitalised words says nowhere where one name ends (tr_np/3).
%% ... AND A SECTION'S NAME IS ONE TOO, a noun the lesson knows: `Calcio -
%% nell'ambito della presentazione ..., il presidente del Napoli ricorda 25
%% anni del club' is filed under football, `Fútbol – ...'
tr_read0(Side, Kind, [W, dash|Right0], S) :-
    Right0 \== [], \+ memberchk(dash, Right0),
    tr_dateline_word(Side, W, NP),
    tr_clause_words(Right0, Right),
    tr_read(Side, Kind, Right, S2), !,
    S = join(dash, gap([], [obj(NP)]), S2).
%% A LETTER'S SIGNATURE AND THE NEXT LETTER'S TITLE: `Monica Ferretti
%% Genova - Sestri P pacifismo "mascalzone".' closes one letter with the
%% writer's name and town and opens the next with its title -- names, a dash,
%% names, and a noun with the word it puts in quotation marks. Nothing in it
%% is a clause and nothing is said of anything, so it was refused; the marks
%% are what make the phrase a title, and a bare noun with plain adjectives
%% stays refused (`Big house.'). Every writer puts it back as it stood.
tr_read0(Side, statement, Words0, join(dash, gap([], [obj(name(NL))]), gap([], [obj(name(NR)), obj(NP)]))) :-
    tr_global('$tr_piece', P0), P0 == Words0,
    append(LW, [dash|Rest], Words0), LW = [_, _|_], \+ memberchk(dash, Rest),
    forall(member(X, LW), X = w(_, upper)), tr_np(Side, LW, name(NL)),
    append(RW, TW, Rest), RW = [_|_], TW = [T1|_], T1 = w(_, lower),
    forall(member(X, RW), X = w(_, upper)), tr_np(Side, RW, name(NR)),
    tr_np(Side, TW, NP), NP = np(none, none, As, w(_, _), _),
    once(( member(w(_, Q), As), memberchk(Q, [qboth, qopen, qclose]) )), !.
%% ... AND ONE WHOSE TOWN ENDS ON ITS PROVINCE IN BRACKETS: `Clara Finetto
%% Giovanni Lupatoto (Vr) Bastiglia e termidoro.' is the writer, her town and
%% `(Vr)' for Verona, then the next letter's title, the Bastille and
%% Thermidor. The bracket is where the signature ends, and the title is bare
%% nouns joined, which nothing else here reads -- `Pane e vino.' standing
%% alone stays refused. Nothing is said of anything, and every writer puts it
%% back as it stood, join(aside, ...), the connector that writes nothing.
tr_read0(Side, statement, Words0, join(aside, gap([], [obj(name(NL)), paren(K)]), gap([], [obj(T)]))) :-
    tr_global('$tr_piece', P0), P0 == Words0,
    append(LW, [w(K, paren)|TW], Words0), LW = [_, _|_], TW = [_|_],
    forall(member(X, LW), X = w(_, upper)), tr_np(Side, LW, name(NL)),
    tr_bare_title(Side, TW, T), !.
%% bare nouns joined, each keeping the capital the title gave it -- the
%% capitalised word is a noun of the lesson's, never a name
tr_bare_title(Side, Ws, co(C, T1, T2)) :-
    tr_conjunction_split(Side, Ws, W1, C, W2), !,
    tr_bare_title(Side, W1, T1), tr_bare_title(Side, W2, T2).
tr_bare_title(Side, [w(W, WC)], np(none, none, [], w(W, WC), N)) :-
    tr_is(Side, w(W, lower), noun), ( tr_lexeme(Side, W, _, N) -> true ; N = singular ), !.
%% A PARENTHESIS AT THE HEAD SAYS WHERE WHAT FOLLOWS CAME FROM: `(dal
%% "Washington Post", 13 luglio 1995) estratto brano dell'articolo ...'.
%% After a phrase a parenthesis is the phrase's (paren/1 among the
%% complements); at the head there is nothing for it to belong to, and the
%% sentence is what follows it, read as the whole piece. It is the
%% dateline's shape with nothing between the two, join(aside, ...), and
%% it goes back where it stood.
%% WHAT FOLLOWS IS READ AS A HEADING, because a line that opens with its
%% source is a caption: `estratto brano dell'articolo pubblicato dal
%% giornale ...' names what it is with no article, which a sentence standing
%% alone may not (`Voto del perro.' stays refused).
tr_read0(Side, Kind, [w(K, paren)|Right], S) :-
    Right \== [],
    tr_global('$tr_piece', P0), P0 == [w(K, paren)|Right],
    nb_setval('$tr_piece', Right),
    (   tr_as_heading(Right, tr_read(Side, Kind, Right, S2)) -> nb_setval('$tr_piece', P0) ; nb_setval('$tr_piece', P0), fail ), !,
    S = join(aside, gap([], [paren(K)]), S2).
%% the one word of a dateline: a capitalised name no lesson knows, or a noun
%% the lesson knows (the head of a piece is lowered when it is known)
tr_dateline_word(Side, W, NP) :-
    W = w(WW, C),
    (   C == upper, tr_np(Side, [W], NP), NP = name(_) -> true
    ;   tr_is(Side, w(WW, lower), noun), tr_np(Side, [w(WW, lower)], NP), NP = np(none, none, [], _, _)
    ), !.
%% ... and one set INSIDE the sentence between two dashes: `Sarò per
%% sempre grato – aggiunge Marchionne – al team di leadership'. The
%% sentence reads with the insertion taken out, and the insertion is the
%% reporting clause, written after the sentence between its dashes -- which
%% is where Spanish and English put one as readily as in the middle.
tr_read0(Side, Kind, Words0, S) :-
    memberchk(dash, Words0),
    append(Left0, [dash|Right0], Words0), \+ memberchk(dash, Left0), Left0 \== [],
    append(Mid0, [dash|After0], Right0), \+ memberchk(dash, Mid0), After0 \== [], \+ memberchk(dash, After0),
    tr_clause_words(Mid0, Mid), tr_read_reporting(Side, Mid, S2),
    append(Left0, After0, Main0), tr_clause_words(Main0, Main),
    tr_read(Side, Kind, Main, S1), !,
    S = join(dashes, S1, S2).
%% ... and one set between two COMMAS: `Alla luce della struttura di
%% finanziamento dell'operazione Veba, sottolinea il Lingotto in una nota,
%% non è previsto un aumento di capitale'. Read as three clauses joined, the
%% first had no verb and took `struttura' for the imperative it is spelled
%% like; it is a phrase fronted to the third, and the second reports the
%% whole. The sentence reads with the insertion taken out and its comma
%% kept -- so the front is written back in front -- and the reporting
%% clause is written after it, after a comma.
tr_read0(Side, statement, Words0, S) :-
    memberchk(comma, Words0),
    append(Left0, [comma|Right0], Words0), Left0 \== [],
    append(Mid0, [comma|After0], Right0), Mid0 = [w(_, _)|_], After0 \== [],
    tr_clause_words(Mid0, Mid), tr_read_reporting(Side, Mid, S2),
    append(Left0, [comma|After0], Main), tr_read(Side, statement, Main, S1),
    %% ... and what it reports has a verb of its own: `En esta versión,
    %% además, cuenta con una June Anderson ... de la locura, la más esperada
    %% por los aficionados' had `cuenta' telling, and the fronts and the last
    %% phrase were left to be a sentence with no verb at all
    S1 \= gap(_, _), !,
    S = join(comma, S1, S2).
%% ... AND A COMMENT BETWEEN TWO COMMAS: `el técnico optará, como parece
%% probable, por mantener a Reina' -- `como' and a clause of its own, which
%% says how likely the rest is and belongs to no part of it. The sentence
%% reads with the comment and both its commas taken out, and the comment is
%% written after it, after a comma, as the reporting clause above is:
%% `... opterà per mantenere Reina, come sembra probabile.'
tr_read0(Side, statement, Words0, S) :-
    Side == foreign, memberchk(comma, Words0),
    append(Left0, [comma, w(C, CC)|Right0], Words0), Left0 \== [],
    tr_solve(mean(C, as)),
    append(Mid0, [comma|After0], Right0), Mid0 = [w(_, _)|_], After0 \== [],
    \+ memberchk(comma, Mid0),
    %% -- and it is its own clause's: with a colon after it, the colon divides
    %% first (below) and the comment stays before it. `... perché, come si
    %% dice a Napoli, l'abbiamo vinto a schiatto: cioè quando ...' wrote the
    %% saying after the clause that explains the spite
    \+ memberchk(colon, After0),
    tr_read_nested(Side, Mid0, none, S2),
    append(Left0, After0, Main), tr_read(Side, statement, Main, S1), !,
    S = join(comma, S1, join(cmt(w(C, CC)), none, S2)).
%% ... AND ONE AT THE END THAT SAYS WHO SAID SO: `El comité examinó la
%% posibilidad ..., según añadieron las mismas fuentes' -- as the same
%% sources added. `según' is the preposition `according to', and before a
%% clause it opens the comment above with a REPORTING clause in it, its
%% speaker after its verb and no object of its own; read as a clause of its
%% own, the sources were the object of somebody adding them. It is written
%% as the comment is, after a comma, with the lesson's word for `as':
%% `..., come aggiunsero le stesse fonti'
tr_read0(Side, statement, Words0, S) :-
    Side == foreign, memberchk(comma, Words0),
    append(Left0, [comma, w(C, CC)|Right], Words0), Left0 \== [], Right = [w(_, _)|_],
    \+ memberchk(comma, Right),
    once(( tr_solve(mean(C, as)) ; tr_solve(mean(C, 'according to')) )),
    tr_read_reporting(Side, Right, S2), S2 = s(_, Sub, _, _), Sub \= null(_, _),
    tr_clause_words(Left0, Left), tr_read(Side, statement, Left, S1), !,
    S = join(comma, S1, join(cmt(w(C, CC)), none, S2)).
%% ... AND ONE AT THE END AFTER A PLAIN COMMA: `El Gobierno español ...
%% mantendrá como candidato español a Carlos Westendorp, ..., explicó ayer el
%% ministro de Asuntos Exteriores, Abel Matutes.' No quotation mark says that
%% what went before was said, so the last clause is the reporting one only
%% when its subject after the verb is a PERSON -- a name, or a phrase whose
%% noun the lesson calls one. Read as a clause of its own, the minister was
%% the object of somebody explaining him; and `abrió la puerta' after a
%% comma is still somebody opening the door.
tr_read0(Side, statement, Words0, S) :-
    Side == foreign, memberchk(comma, Words0),
    append(Left0, [comma|Right], Words0), Left0 \== [], Right = [w(_, _)|_],
    \+ memberchk(comma, Right),
    %% (and the person is the clause's subject and nothing else's: `si disse
    %% subito dopo Hiroshima' is IT WAS SAID right after Hiroshima -- `si'
    %% names nobody, and the name is the object of `dopo', which is an adverb
    %% too. Read as the speaker, Spanish wrote `se dijo inmediatamente después
    %% Hiroshima'. tr_reporting/3 asks both as it reads, with `person')
    tr_reporting(person, Right, S2), S2 = s(_, _, _, Cs2),
    \+ memberchk(opron(_), Cs2),
    tr_clause_words(Left0, Left), tr_read(Side, statement, Left, S1), !,
    S = join(comma, S1, S2).
%% A QUOTATION THAT CLOSES INSIDE ITS PIECE, AND THE CLAUSE THAT REPORTS IT:
%% `L'acquisto da parte di Fiat del 100% di Chrysler “ci permetterà di
%% realizzare ... unico al mondo” aggiunge l'ad Sergio Marchionne.' The pair
%% of marks is the tokeniser's (the last quoted word carries qclose), so no
%% `endquote' divides the piece -- and the reporting clause ran on as the
%% quotation's own words. The piece divides after the quoted run when what
%% follows reads as a reporting clause; the marks travel on the words, so
%% the connector writes nothing.
tr_read0(Side, Kind, Words0, S) :-
    append(Left0, [w(Q, qclose)|Right0], Words0), Right0 = [w(_, _)|_],
    append(Left0, [w(Q, qclose)], LeftQ),
    tr_clause_words(Right0, Right), tr_read_reporting(Side, Right, S2),
    tr_clause_words(LeftQ, Left), tr_read(Side, Kind, Left, S1), !,
    S = join(reported, S1, S2).
%% A COLON AT THE END ANNOUNCES WHAT THE NEXT SENTENCE SAYS: `Dello stesso
%% tenore il commento del sindaco di Torino Piero Fassino:', `Soddisfazione
%% dalla Fim Cisl:'. There is nothing after it to be a clause, so the
%% sentence is read without it and the colon is written back after it --
%% and such a sentence is a HEADING, which may have no verb at all (the
%% verbless reading below asks for this piece by name).
tr_read0(Side, Kind, Words0, S) :-
    append(Left0, [colon], Words0), \+ memberchk(colon, Left0), Left0 \== [],
    tr_clause_words(Left0, Left),
    tr_global('$tr_heading', H0), nb_setval('$tr_heading', Left),
    (   tr_read(Side, Kind, Left, S1) -> nb_setval('$tr_heading', H0)
    ;   nb_setval('$tr_heading', H0), fail
    ), !,
    S = join(colon, S1, none).
%% A HEADLINE WITH A COLON: `Il comitato di bioetica: no all'eutanasia.'
%% -- who speaks, and what they say, and neither side has a verb. Each side
%% is read as a heading is (tr_as_heading/2), so either may be verbless and
%% a side with a verb reads as it always did, the verbless reading being
%% the last one tried. It goes BEFORE the clause below because a failure
%% is kept per word list and not per heading: read there first, a verbless
%% side would be remembered as unreadable, and a failure with the heading
%% set is one without it too.
tr_read0(Side, Kind, Words0, S) :-
    append(Left0, [colon|Right0], Words0), \+ memberchk(colon, Left0), Left0 \== [], Right0 \== [],
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right),
    tr_as_heading(Left, tr_read(Side, Kind, Left, S1)),
    tr_as_heading(Right, tr_read(Side, statement, Right, S2)), !,
    S = join(colon, S1, S2).
%% ... AND A QUESTION AFTER THE COLON IS THE SECOND CLAUSE'S: `E ora mi
%% domando: in che razza di mondo nasceranno i miei figli?' -- I wonder, and
%% then what I wonder. The mark ends the sentence and belongs to what the
%% colon announces; read as a question, the first clause asked nothing
tr_read0(Side, question, Words0, S) :-
    append(Left0, [colon|Right0], Words0), \+ memberchk(colon, Left0), Left0 \== [], Right0 \== [],
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right),
    tr_read(Side, statement, Left, S1), tr_read(Side, question, Right, S2), !,
    S = join(colon, S1, q(S2)).
%% A COLON DIVIDES AS A SEMICOLON DOES: `Le condizioni generali sono
%% ottime: ridono, scherzano, raccontano.' Two clauses, the second saying
%% what the first announced.
tr_read0(Side, Kind, Words0, S) :-
    memberchk(colon, Words0),
    append(Left0, [colon|Right0], Words0),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right),
    tr_read(Side, Kind, Left, S1), tr_read(Side, statement, Right, S2), !,
    S = join(colon, S1, S2).
%% a goal run with these words read as a heading, which may have no verb
tr_as_heading(Words, Goal) :-
    tr_global('$tr_heading', H0), nb_setval('$tr_heading', Words),
    (   call(Goal) -> nb_setval('$tr_heading', H0)
    ;   nb_setval('$tr_heading', H0), fail
    ).
%% A PURPOSE STANDING ALONE: `Para recordar.' -- a review's verdict, one to
%% remember. The first word is the one the lesson says begins the purpose
%% and the second an infinitive, and read as the verb the first is spelled
%% like -- `parar', to stop -- with a bare infinitive after it, it came out
%% `Detiene ricordare'. A whole piece that is the purpose, an infinitive and
%% its complements has no verb, and it is written as it stood: `Per
%% ricordare.', `To remember.'
tr_read0(foreign, statement, Words0, gap([], Comps)) :-
    Words0 = [w(P, _), w(V, _)|_], tr_purpose_word(P), tr_solve(infinitive_of(V, _)),
    tr_global('$tr_piece', Piece), Piece == Words0, \+ memberchk(comma, Words0),
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    tr_complements(foreign, Words0, Comps), Comps = [purpose(_)|_], !.
%% A PHRASE AND THEN WHAT IT DOES: `la insistencia de los republicanos en
%% buscar otros cargos para fortalecer el proceso contra Lewinsky lo que
%% hace es "desacreditar" la investigación' -- the insistence, what it does
%% is discredit the inquiry. The phrase stands in front with NO comma, and
%% the clause after it has for its subject a word that replaces a noun and a
%% relative clause (`lo que hace', tr_np/3). Read as one clause, `para' was
%% the verb `stops' and `lo' was him -- a WRONG reading, which is why this
%% comes before the plain ones below. The phrase travels in front, frn/1,
%% and every writer puts it back where it stood, its complements after it.
%% It is asked of a clause after `que' too (tr_read_nested/4), where the
%% sentence's own one stood.
tr_read0(foreign, statement, Words0, S) :- tr_topic_cleft(Words0, S), !.
tr_topic_cleft(Words0, S) :-
    once(( member(w(RW, _), Words0), tr_relative_word(foreign, RW) )),   % no split is worth trying without one
    append(Front0, [Q, w(R, RC)|Rest], Words0), Front0 = [_, _|_], Rest \== [],
    \+ memberchk(comma, Front0),
    tr_relative_word(foreign, R), tr_noun_replacer(foreign, Q),
    tr_subject(foreign, none, Front0, third, _, NP0),
    tr_read(foreign, statement, [Q, w(R, RC)|Rest], S0),
    S0 = s(A, Su, G, Comps0), Su = ell(_, _, _, rel(_, _)), !,
    ( NP0 = with(NP, PPs) -> true ; NP = NP0, PPs = [] ),
    findall(frn(X), member(X, [topic(NP)|PPs]), Fr), append(Fr, Comps0, Comps),
    S = s(A, Su, G, Comps).
%% A QUESTION WITH NO QUESTION WORD IS A STATEMENT WITH ITS MARK: `-
%% egoista e vigliacca, continuerà a cercare mediazioni impossibili ...?'
%% asks whether it will, in the statement's own order -- so it is read as the
%% statement it is, its commas and its front with it, and only the mark says
%% that it asks. Read with every comma taken out, the adjectives in front had
%% no reading at all and the comma before `senza' was lost.
tr_read0(foreign, question, Words0, S) :-
    memberchk(comma, Words0), Words0 = [W0|_], W0 \== comma,
    tr_uncomma(Words0, Plain), fo_question_word(Plain, _, none),
    tr_read0(foreign, statement, Words0, S), !.
%% A STATEMENT IS READ FIRST WITH ITS COMMAS, and a comma after the verb
%% group is a complement of its own, sep, which every writer puts back:
%% `Il generale definisce la casa, escludendo che il paese domina' keeps
%% the comma before its gerund. The subject side is read with the commas
%% taken out, as before; and when this reading fails the one below, with
%% every comma taken out, is the one the reader always had.
tr_read0(Side, statement, Words0, S) :-
    memberchk(comma, Words0), Words0 = [W0|_], W0 \== comma,
    tr_read_statement(Side, Words0, none, S), !.
tr_read0(Side, Kind, Words0, S) :-
    \+ tr_names_parted(Side, Words0),                       % two names a comma parts stay two
    \+ tr_name_opens_clause(Side, Words0),                  % and a comma before a name and its verb stays
    tr_uncomma(Words0, Plain),
    tr_normalise(Side, Kind, Plain, Words, Asked),
    tr_read_statement(Side, Words, Asked, S), !.
%% AN ADVERB STANDS WHEREVER ITS LANGUAGE LIKES, AND A STATEMENT READER
%% READS ONE ONLY AFTER THE VERB GROUP. `si sono anche appellati', `non
%% sono state ancora accertate', `e considerata gia conclusa' all put one
%% INSIDE the group, between the auxiliary and the participle, where
%% nothing was looking for it; `Velocemente il generale domina' and `Gia si
%% parla' put one at the head, before the subject. So a piece that did not
%% read as a statement is tried again with the adverb words LIFTED OUT of
%% it, and they come back as the adv/1 complements they would have been
%% after the verb.
%%
%% IT IS TRIED ONLY AFTER THE PLAIN READING FAILED, which is what makes it
%% a strict addition -- every sentence that read before reads by the same
%% clauses -- and fewest first, because tr_adverbs_off/4 keeps each word
%% before it lifts it: an adverb the complement reader can already take
%% stays where it is.
%%
%% AND THE POSITION IS NOT WRITTEN BACK. A lifted adverb becomes an
%% ordinary complement and every writer puts it after the verb, so `Gia si
%% parla' comes back as `Si parla gia' -- the same claim in the statement's
%% own order, which is what 1.6.8 already does with a fronted adjunct.
%%
%% THE COST IS A WORD THAT IS AN ADVERB AND SOMETHING ELSE BESIDES. Nothing
%% here can rescue a WRONG reading: `ancora' is an adverb, a noun (anchor)
%% and a verb in the vocabulary, so `mangia ancora il pane' reads as an
%% object and never reaches this clause. A refusal is what this repairs.
%% ... AND NOT OVER A PIECE A COMMA AND A CONNECTOR DIVIDE: `Io la risposta
%% non ce l'ho, ma quei morti ... e, soprattutto, sono un problema anche mio'
%% is two clauses, and every set of its adverbs lifted out of the whole was a
%% reading of the whole that failed -- 42 million of its 59. The division
%% further down reads each half, and each half lifts its own.
tr_read0(Side, Kind, Words0, S) :-
    \+ tr_names_parted(Side, Words0),
    \+ tr_name_opens_clause(Side, Words0),
    \+ ( Kind == statement, Words0 = [_, comma|_] ),       % `Cucharada a cucharada, el chaval ...' is a punctuated front
    \+ ( append(_, [comma, w(CW, _)|_], Words0), tr_connector(Side, CW) ),
    \+ ( append(_, [w(CW, CC), comma|_], Words0), tr_coord(Side, w(CW, CC)) ),   % `... e, soprattutto, sono'
    (   %% ... WITH THE COMMA BEFORE A RELATIVE WORD KEPT, which says the clause
        %% is the phrase's aside: `También se incrementaron las ventas de
        %% minidisc, que superaron ...' read with every comma out made the
        %% clause restrictive, and the comma was lost
        Kind == statement, append(_, [comma, w(RW, _)|_], Words0), tr_relative_word(Side, RW),
        tr_adverbs_off(Side, Words0, Rest, Advs0), Advs0 \== [], Rest = [R0|_], R0 \== comma,
        tr_read_statement(Side, Rest, none, S0), S0 = s(A, Su, G, Comps0)
    ->  Words = Words0
    ;   tr_uncomma(Words0, Plain),
        tr_normalise(Side, Kind, Plain, Words, Asked),
        tr_adverbs_off(Side, Words, Rest, Advs0), Advs0 \== [],
        tr_read_statement(Side, Rest, Asked, S0), S0 = s(A, Su, G, Comps0)
    ), !,
    tr_denials_in_front(Side, Words, Advs0, Advs),
    tr_advs_join(Side, Words, Comps0, Advs, Comps),
    S = s(A, Su, G, Comps).

%% THE LIFTED ADVERBS GO WHERE THEY WOULD HAVE STOOD AFTER THE VERB, which is
%% before a clause the verb takes: `poi disse che sarebbe passato per casa' is
%% THEN he said, and put after the `that' clause the adverb was the clause's,
%% `dijo que habría pasado para casa a tomar una maleta entonces'. ONLY ONE
%% THAT STOOD BEFORE THE WORD OPENING THE CLAUSE: the lift takes its words
%% from anywhere in the piece, and `No podemos pensar que antes de jugar esto
%% ya está ganado' lifted `ya' out of the `que' clause -- put before it, the
%% clause's `already' came out the thinking's, `pensare già che'
tr_advs_join(Side, Words, Comps0, Advs, Comps) :-
    Advs \== [], append(Pre, [C|Post], Comps0), tr_clause_comp(C), !,
    partition(tr_adv_before_clause(Side, Words), Advs, Before, After),
    append([Pre, Before, [C|Post], After], Comps).
tr_advs_join(_, _, Comps0, Advs, Comps) :- append(Comps0, Advs, Comps).

tr_adv_before_clause(Side, Words, A) :-
    ( A = adv(W) ; A = frn(adv(W)) ), !,
    append(B, [W|_], Words), \+ ( member(X, B), tr_clause_opener(Side, X) ), !.

%% a word that opens a clause a verb takes: `that', or a question word
tr_clause_opener(Side, X) :- tr_that_here(Side, X), !.
tr_clause_opener(Side, w(Q, _)) :- tr_indirect_word(Side, Q, _), !.

tr_clause_comp(that(_)).
tr_clause_comp(wh(_, _)).
tr_clause_comp(rwh(_, _)).

%% A DENYING ADVERB BEFORE ITS VERB STAYS THERE. `Ni siquiera ha comunicado
%% la decisión' and `Rivaldo y Overmars tampoco estuvieron' deny the verb
%% from in front of it, and the lesson's languages deny a verb with nothing
%% else when the word stands there -- `Neanche ha comunicato la decisione'.
%% Put after the verb it came out `Ha comunicato la decisione ai giocatori
%% neanche', which says nothing. One that stood before a verb travels as
%% frn/1, the front every writer puts first.
tr_denials_in_front(Side, Words, Advs0, Advs) :-
    findall(X, ( member(adv(W), Advs0),
                 (   tr_denying_adverb(Side, W), append(_, [W|After], Words),
                     member(w(V, _), After), tr_verb_form_word(V)
                 ->  X = frn(adv(W))
                 ;   X = adv(W)
                 ) ), Advs).
%% ... AND AN ADVERB AFTER A FRONT'S COMMA, BEFORE THE SUBJECT'S DETERMINER,
%% STAYS THERE TOO: `che, ieri, PROPRIO la sua assenza avrebbe potuto avere un
%% significato' is precisely his absence, and put after the verb it came out
%% `que, ayer, su ausencia habría podido tener un significado precisamente',
%% which says something else. Only there: an adverb at the head of a whole
%% piece keeps 1.6.8's rule and goes after the verb (`Siempre el perro come el
%% pan' is `The dog eats the bread always'), where the four pins of it stand.
tr_head_adverb_in_front(Side, Words, Advs0, Advs) :-
    findall(X, ( member(A, Advs0),
                 (   A = adv(W), Words = [W, D|_], D = w(_, _), tr_determiner(Side, D, _, _)
                 ->  X = frn(adv(W))
                 ;   X = A
                 ) ), Advs).
tr_denying_adverb(Side, w(W, _)) :-
    tr_lexeme(Side, W, L, _), tr_solve(mean(L, E)), memberchk(E, [neither, never, 'not even', 'not either', nowhere]), !.
%% A FRONTED ADJUNCT BEFORE THE SUBJECT. `Negli ambienti giudiziari si
%% tende ad accreditare la tesi' opens with a prepositional phrase that is
%% neither the subject nor part of one -- and the subject reader took `in
%% gli ambienti giudiziari si' for a phrase, failed inside it, and refused
%% the sentence. The inversion clause of 1.6.8 reads the same fronting with
%% the subject AFTER the verb, which an intransitive verb licenses; this
%% one reads it with the subject where it always was, and needs no property
%% of the verb because nothing is being moved.
%%
%% Only material that reads as ADJUNCTS may be taken -- an adverb or a
%% prepositional phrase, never an object -- which is what stops the front
%% swallowing the subject, and the LONGEST front is tried first, which is
%% what stops it stopping short: `Negli ambienti si tende' cut at two words
%% read `gli' as an object pronoun standing alone (nothing followed it to
%% say it was the article it is) and came out `Environments tend in hims'.
%% It is tried only after the plain reading failed, which is what makes it
%% a strict addition.
%%
%% THE FRONTING IS NOT WRITTEN BACK, exactly as 1.6.8 says of the other:
%% the adjuncts become ordinary complements and every writer puts them
%% after the verb.
%%
%% A STATEMENT'S FRONT IS READ WITH ITS COMMAS, and a phrase ends at one:
%% `en los de clase media, chicos difíciles y en las partes altas ...' read
%% with the commas taken out made `clase media chicos difíciles' one phrase.
%% And A FRONT THE SOURCE SET OFF WITH A COMMA IS WRITTEN BACK IN FRONT:
%% `Después, en los barrios marginales se les llamará ...' is a choice the
%% writer made, and each complement of it travels as fr(C) so every writer
%% puts it before the clause and the comma after it. A front with no comma
%% is written after the verb, as 1.6.8 does.
tr_read0(Side, statement, Words0, S) :-
    Words0 = [W0|_], W0 \== comma,
    %% a CONNECTOR at the head is the sentence's, never a front's first
    %% adjunct: `E a Cortina una frana ostruisce ...' took `E' for cnj(and)
    %% and wrote it after the verb, `... de Alemagna y a Cortina'
    \+ ( W0 = w(C0, _), tr_connector(Side, C0) ),
    length(Words0, Len), Max is Len - 1, Max >= 1,
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    between(1, Max, Back), K is Max + 1 - Back, length(Front0, K), append(Front0, Rest0, Words0),
    \+ last(Front0, comma), Rest0 \== [], Rest0 \= [comma],
    %% a front that opens on `al' and an infinitive ends at a comma: the
    %% clause takes the words to its first comma (tr_upon_rest/5), and asked
    %% at every length of front the rest of the sentence was read as its
    %% complements once a length -- 32 million inferences for `Al abrir la
    %% segunda audiencia ..., su presidente, Henry Hyde, sostuvo que ...'
    \+ ( Rest0 \= [comma|_], tr_upon_head(Side, Front0) ),
    %% the word for `not' is the verb's, never the end of a front: longest
    %% first, `Alla luce della struttura ..., non è previsto' took `non' as
    %% the front's last adverb and the verb lost its denial
    \+ ( last(Front0, w(NW, _)), tr_solve(mean(NW, not)) ),
    %% ... and so is a denying adverb: `..., ni siquiera ha comunicado'
    \+ ( last(Front0, LW), LW = w(_, _), tr_denying_adverb(Side, LW) ),
    %% ... and an adverb before a count is the count's: `Al cierre de los
    %% colegios, MÁS DE un 60% de los electores habían votado' -- longest
    %% first, the front took `más de' and wrote `..., oltre, un 60%'
    \+ ( last(Front0, LW2), LW2 = w(_, _), tr_is(Side, LW2, adverb), tr_count_follows(Side, Rest0) ),
    %% ... and an adverb after the front's comma and before a determiner is
    %% the rest's, standing before its subject: `che, ieri, proprio la sua
    %% assenza' took `ieri, proprio' for one front, and the writer's comma
    %% after a front came out `que, ayer, precisamente, su ausencia'
    \+ ( append(_, [comma, LW3], Front0), LW3 = w(_, _), tr_plain_adverb(Side, LW3),
         Rest0 = [D3|_], D3 = w(_, _), tr_determiner(Side, D3, _, _) ),
    tr_complements(Side, Front0, Front), Front \== [],
    (   tr_adjuncts(Front) -> Front1 = Front
    ;   Rest0 = [comma|_], Front = [obj(NP)], tr_topic(NP), tr_at_piece_head(Words0), Front1 = [topic(NP)]
    %% ... AND A BARE PHRASE THAT SAYS WHAT THE SUBJECT IS: `Retrato preciso
    %% de la aniquilación psicológica, Anderson ofreció una de sus mejores
    %% noches' -- a portrait, and Anderson is it. It has no determiner and no
    %% verb, and divided at its comma it was read as `retrato', I portray. It
    %% stands at the head of its sentence with its `of' phrases, and only
    %% before a subject that is named (Named below)
    ;   Rest0 = [comma|_], Front = [obj(NP)|PPs], NP = np(none, none, _, w(_, _), singular),
        forall(member(X, PPs), X = pp(_, _)), tr_at_piece_head(Words0),
        Front1 = [topic(NP)|PPs], Named = yes
    %% ... AND ADJECTIVES THAT SAY WHAT THE SUBJECT IS: `Egoista e vigliacca,
    %% continuerà a cercare mediazioni impossibili' -- selfish and cowardly,
    %% it will go on looking. At the head of the sentence and before its
    %% comma, in the number of the subject after it (Agree below), and each
    %% writer puts them back in front agreeing with that subject.
    ;   Rest0 = [comma|_], Front = [adj(FA)], tr_at_piece_head(Words0),
        Front1 = Front, Agree = FA
    ),
    %% THE REST IS READ WITH ITS COMMAS FIRST, as a statement is: `... la
    %% tesi di una leggerezza, escludendo che ...' read without them made the
    %% gerund a complement of the clause and the comma was lost
    %% -- after the front's own comma too: `En cambio, las ventas de casetes
    %% mantienen una evolución a la baja, concentrando ..., frente al ...'
    %% lost both commas after it, because the rest began with the front's
    (   ( Rest0 = [comma|RestC] -> true ; RestC = Rest0 ), RestC = [RC0|_], RC0 \== comma,
        memberchk(comma, RestC), tr_read_statement(Side, RestC, none, S0)
    ->  true
    %% (never with a comma out between two names, or before a name and its
    %% verb: `En la descripción de lord, Arturo Bucklaw, Vick se permite'
    %% made one person of the character and the director)
    ;   \+ tr_names_parted(Side, Rest0), \+ tr_name_opens_clause(Side, Rest0),
        tr_uncomma(Rest0, Rest), Rest \== [],
        tr_read_statement(Side, Rest, none, S0)
    ->  true
    %% ... and with its adverbs lifted, as a whole piece's are (tr_adverbs_off/4):
    %% `En su afán por esconder sus planes, ni siquiera ha comunicado ...'
    ;   \+ tr_names_parted(Side, Rest0), \+ tr_name_opens_clause(Side, Rest0),
        tr_uncomma(Rest0, Rest), Rest \== [],
        tr_adverbs_off(Side, Rest, Rest1, Advs0), Advs0 \== [],
        tr_read_statement(Side, Rest1, none, S1), S1 = s(A1, Su1, G1, C1),
        tr_denials_in_front(Side, Rest, Advs0, Advs10), tr_head_adverb_in_front(Side, Rest, Advs10, Advs1),
        tr_advs_join(Side, Rest, C1, Advs1, C2),
        S0 = s(A1, Su1, G1, C2)
    ),
    S0 = s(A, Su, G, Comps0),
    ( Named == yes -> Su \= null(_, _), Su \== none ; true ),
    ( nonvar(Agree) -> tr_front_adj_agrees(Side, Agree, Su) ; true ), !,
    %% ... and a front that asks WHERE or relates is written in front as well:
    %% `e da dove abbiamo poi ritrovato la mamma' went after its clause and
    %% came out `hemos recuperado la mamá desde donde'
    (   ( memberchk(comma, Front0) ; Rest0 = [comma|_] )
    ->  findall(fr(X), member(X, Front1), Fr), append(Fr, Comps0, Comps)
    ;   member(w(FX, _), Front0), ( tr_indirect_word(Side, FX, _) ; tr_relative_word(Side, FX) )
    ->  findall(frn(X), member(X, Front1), Fr), append(Fr, Comps0, Comps)
    ;   tr_front_after(Comps0, Front1, Comps)
    ),
    S = s(A, Su, G, Comps).

%% the adjectives in front agree in number with the subject after them,
%% where the subject says one
tr_front_adj_agrees(Side, As, Su) :-
    ( tr_front_number(Su, N) -> true ; N = any ),
    forall(( member(A, As), A = w(W, _), \+ tr_coord(Side, A) ),
           ( N == any ; tr_lexeme(Side, W, L, N), tr_class(Side, L, adjective) )).

tr_front_number(null(_, N), N) :- !.
tr_front_number(Su, N) :- tr_subject_number(Su, N).

%% a count: a number, or a determiner and a number (`un 60%')
tr_count_follows(Side, [W|_]) :- tr_count_word(Side, W), !.
tr_count_follows(Side, [D, W|_]) :- tr_determiner(Side, D, _, _), tr_count_word(Side, W), !.
tr_count_word(Side, W) :- tr_is(Side, W, number), !.
tr_count_word(_, w(W, _)) :- atom(W), sub_atom(W, 0, 1, _, F), char_type(F, digit(_)), !.

%% A PLACE A HEADLINE PUTS IN FRONT: `Monte Livata, ritrovati vivi donna e
%% bimbi scomparsi.' It is no adjunct -- it has no preposition -- and no
%% subject either, and only a comma after it and a NAME in it let it stand
%% there: a name, or a phrase with a name apposed to its noun. It is written
%% back in front, with its comma, as every punctuated front is.
%% ... AND IT TRAVELS AS topic(NP), NOT AS AN OBJECT: read as obj/1 it was
%% the verb's object to every rule that asks, and a name there took the word
%% the lesson puts before a person -- `Monreale, i pm vogliono Cassisa alla
%% sbarra.' came out `A Monreale, los fiscales quieren ...'
%% ... and only at the HEAD of its sentence, where a headline puts one: a
%% clause the sentence was divided into does not open on a topic, and
%% `Salvo la concesión de Rivaldo y Overmars, Serra Ferrer no quiere ...'
%% divided at its first `y' read `Overmars' as one before `Serra Ferrer'
tr_at_piece_head(Words) :- tr_global('$tr_piece', P), is_list(P), append(Words, _, P), !.
tr_topic(name(_)) :- !.
tr_topic(np(_, _, Adjs, _, _)) :- member(w(_, upper), Adjs), !.
tr_topic(np(_, _, _, named(_, _), _)).

%% a front with no comma goes after the clause's own complements -- and
%% before the first comma among them, which is where the clause ended
tr_front_after(Comps0, Front, Comps) :-
    append(A, [sep|B], Comps0), !, append(A, Front, AF), append(AF, [sep|B], Comps).
%% ... and before a phrase that carries a relative clause after a comma,
%% which runs to the end of its piece: `Por él suspiró Yehudi Menuhin, que
%% elogió su sonoridad' put `da lui' after the clause, where it read as the
%% clause's own, `che lodò la sua sonorità da lui'
tr_front_after(Comps0, Front, Comps) :-
    append(A, [C|B], Comps0), tr_carries_nrc(C), !, append(A, Front, AF), append(AF, [C|B], Comps).
tr_front_after(Comps0, Front, Comps) :- append(Comps0, Front, Comps).

tr_carries_nrc(obj(nrc(_, _, _))).
tr_carries_nrc(pp(_, nrc(_, _, _))).
tr_carries_nrc(by(nrc(_, _, _))).
tr_read0(Side, question, Words0, S) :-
    tr_uncomma(Words0, Plain),
    tr_normalise(Side, question, Plain, Words, Asked),
    length(Words, Len), Max is Len - 1, Max >= 1,
    %% the complement reader asks two globals the group sets, and no group
    %% has been read yet: left over from the sentence before, `dal punto di
    %% vista tattico' was taken for a PASSIVE'S AGENT and the front refused
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    between(1, Max, Back), K is Max + 1 - Back, length(Front0, K), append(Front0, Rest, Words),
    tr_complements(Side, Front0, Front), Front \== [],
    forall(member(X, Front), tr_adjunct(X)),
    tr_read_statement(Side, Rest, Asked, S0), S0 = s(A, Su, G, Comps0), !,
    append(Comps0, Front, Comps),
    S = s(A, Su, G, Comps).
%% A SUBORDINATE CLAUSE AT THE HEAD, WITH AN INSERTION AFTER ITS WORD: `Al
%% margen de que, como todos, han disfrutado de unos días de descanso,
%% curiosamente Rivaldo y Overmars tampoco estuvieron en Gandía'. A comma
%% straight after the connecting word opens an insertion, and it belongs to
%% the clause the word introduces -- divided at the comma after it, `como
%% todos' read as a clause of its own, `I eat everyone'. The clause runs
%% from the insertion to the next comma that leaves a clause after it, and
%% the IR is the one a comma division of `Si llueve, no salgo' gives, with
%% the connector's own comma kept: join(comma, join(wc(Conn), none, S1),
%% S2). With no clause after it, the sentence is the subordinate clause.
tr_read0(Side, Kind, [w(C, CC), comma|Words0], S) :-
    tr_connector(Side, C), \+ tr_coord(Side, w(C, CC)),
    append(Ins, [comma|R1], Words0), Ins \== [], \+ memberchk(comma, Ins), !,
    (   append(SubRest, [comma|Main0], R1), SubRest \== [], Main0 \== [],
        append(Ins, [comma|SubRest], Sub),
        tr_read(Side, statement, Sub, S1),
        tr_clause_words(Main0, Main), tr_read(Side, Kind, Main, S2)
    ->  S = join(comma, join(wc(w(C, CC)), none, S1), S2)
    ;   append(Ins, [comma|R1], Sub), tr_read(Side, Kind, Sub, S1),
        S = join(wc(w(C, CC)), none, S1)
    ).
%% A CONNECTOR AT THE HEAD IS READ BEFORE ANY DIVISION, AND WITH THE COMMAS
%% AFTER IT: `E il Giglio ... ritorna alla dimensione dell'oasi così come le
%% Eolie, interdette al traffico, e l'isola di Ustica'. The division below
%% came first, found the last `e' and read `l'isola di Ustica' as a clause of
%% its own -- `lo aísla de Ustica', somebody isolating somebody -- because
%% the one reading of the whole after the connector (further down) had lost
%% its commas and failed. What follows the connector is the sentence, so it
%% is read as one, as the whole piece.
%% ... A COORDINATING ONE: `Si bien X, Y' opens a clause that ends at the
%% comma, which the division reads right, and read as one piece the rest cost
%% Spanish's record report 14.4 million inferences a sentence against 5.7
tr_read0(Side, Kind, [w(C, CC)|Rest], S) :-
    Rest = [R1|_], R1 \== comma, tr_connector(Side, C), tr_coord(Side, w(C, CC)),
    tr_global('$tr_piece', P0), P0 == [w(C, CC)|Rest],
    nb_setval('$tr_piece', Rest),
    (   tr_read(Side, Kind, Rest, S1) -> nb_setval('$tr_piece', P0) ; nb_setval('$tr_piece', P0), fail ), !,
    S = join(w(C, CC), none, S1).
tr_read0(Side, Kind, Words0, S) :-
    tr_clause_split(Side, Words0, Left0, Conn0, Right),
    tr_quote_closed(Left0, Conn0, Left, Conn),
    tr_join_left(Side, Kind, Left, Conn, S1),
    tr_read_joined(Side, Conn, S1, Right, S2), !,
    (   Conn = both(C1, C2) -> S = join(C1, S1, join(C2, none, S2))
    ;   S = join(Conn, S1, S2)
    ).
%% the left side of a division: a clause -- or AN ANSWER WITH ITS CONDITION.
%% `Niente, se la maggiore preoccupazione è la stabilità.' answers the
%% question before it, nothing if that is the concern, and its left side is
%% one pronoun with no verb, which no clause reads. One pronoun the lesson
%% says stands alone (`The pronoun "niente" does not precede the verb.'),
%% before a connector that is no coordinator, is read as the verbless
%% phrase it is.
tr_join_left(Side, Kind, Left, _, S1) :- tr_read(Side, Kind, Left, S1), !.
tr_join_left(Side, _, [W], Conn, gap([], [obj(pronoun(W))])) :-
    ( Conn = both(comma, K) -> true ; K = Conn ), K = w(_, _), \+ tr_coord(Side, K),
    W = w(X, _), tr_is(Side, W, pronoun),
    tr_lexeme(Side, X, L, _), tr_solve(neg(precede(L, verb))), !.

%% A CLAUSE A COORDINATOR JOINS TO A STATEMENT IS NO COMMAND. `el
%% resultado es una versión estilizada ... y permite a los cantantes
%% concentrarse' goes on saying what the result does, and `permite' is the
%% imperative of `permitir' as well as its third person -- the imperative is
%% the reading a bare verb at the head takes (1.6.10), and it came out `e
%% permetti ai cantanti', you allow. After `y' and a statement the verb
%% shares the statement's subject, so the imperative stands down while the
%% right side is read ('$tr_no_command', which the failures kept per word
%% list are keyed on too); after a command, `Come el pan y bebe el vino',
%% it may be one again.
tr_read_joined(Side, Conn, S1, Right, S2) :-
    (   ( Conn = w(_, _) ; Conn = both(comma, K), K = w(_, _) ),
        ( Conn = w(_, _) -> tr_coord(Side, Conn) ; tr_coord(Side, K) ),
        S1 = s(_, _, g(_, _, A1, _), _), A1 \== imperative
    ->  tr_global('$tr_no_command', F0), nb_setval('$tr_no_command', yes),
        (   tr_read(Side, statement, Right, S20) -> nb_setval('$tr_no_command', F0)
        ;   nb_setval('$tr_no_command', F0), fail
        ),
        tr_shared_subject(Side, S1, Right, S20, S2)
    %% ... AND A CLAUSE AFTER A SUBORDINATING WORD IS NONE EITHER: `apoyará
    %% a Javier Solana si logra el consenso' -- if HE achieves it, and
    %% `logra' is the imperative of `lograr' as well, which came out `se
    %% riesci', if you achieve
    ;   ( Conn = w(_, _) -> K1 = Conn ; Conn = both(comma, K1), K1 = w(_, _) ),
        \+ tr_coord(Side, K1)
    ->  tr_global('$tr_no_command', F0), nb_setval('$tr_no_command', yes),
        (   tr_read(Side, statement, Right, S2) -> nb_setval('$tr_no_command', F0)
        ;   nb_setval('$tr_no_command', F0), fail
        )
    ;   tr_read(Side, statement, Right, S2)
    ).

%% A CLAUSE JOINED BY A COORDINATOR WITH NOBODY NAMED SHARES THE SUBJECT
%% BEFORE IT where its verb could say either: `quei morti ... mi fanno male
%% al cuore e, soprattutto, sono un problema anche mio' -- the deaths and the
%% camps ARE a problem of mine too, and `sono' is also `I am', which the
%% copula's singular predicate chose. When a word of the second clause is its
%% verb in both readings, the one the first clause's subject gives is taken.
tr_shared_subject(foreign, s(_, Su1, _, _), Right, s(A, null(P2, N2), g(L, T, Asp, Neg), Cs), S2) :-
    tr_shared_person(Su1, third, N1), (P2 \== third ; N2 \== N1),
    atom(L), member(w(W, _), Right), atom(W),
    tr_form(W, L, N2, T, P2), tr_form(W, L, N1, T, third), !,
    S2 = s(A, null(third, N1), g(L, T, Asp, Neg), Cs).
tr_shared_subject(_, _, _, S2, S2).

tr_shared_person(co(_, _, _), third, plural) :- !.
tr_shared_person(null(P, N), P, N) :- !.
tr_shared_person(pronoun(P, N, _), P, N) :- !.
tr_shared_person(Su, third, N) :- tr_phrase_subject(Su), tr_subject_number(Su, N).

%% A QUOTATION THAT CLOSES AT A COMMA LEAVES ITS MARK THERE. `... un mes de
%% Febrero muy apretado", explicó.': the closing mark was on `apretado', a
%% participle the IR carries as a predicate with no case, and it was lost.
%% It goes on the join instead, which writes a mark and a comma.
tr_quote_closed(Left0, comma, Left, endquote_plain_comma) :-
    append(F, [w(W, qclose)], Left0), !, append(F, [w(W, lower)], Left).
tr_quote_closed(Left, Conn, Left, Conn).

%% A CONNECTOR AT THE HEAD JOINS THIS SENTENCE TO THE ONE BEFORE IT.
%% `Ma gia si parla di epurazioni' -- newspaper prose opens a sentence with
%% `Ma', `E', `Perche', and tr_clause_split/5 finds no left clause for it
%% because there is none IN THE SENTENCE. It is the same join with nothing
%% on its left, so the IR is join(Conn, none, S) and every writer puts the
%% connector first. What is lost is nothing: the connector is written back
%% where it stood.
%% -- THE CLAUSE WITH ITS COMMAS FIRST: `Pese a que empezó frío, poco
%% expresivo, Bros fue entonándose' has two things said of how he began,
%% and read with the comma between them taken out they were one phrase,
%% `frío poco expresivo', a little expressive thing he began cold
tr_read0(Side, Kind, Words0, S) :-
    Words0 = [w(C, CC)|Rest0], Rest0 = [R0|_], R0 \== comma, memberchk(comma, Rest0),
    tr_connector(Side, C), \+ tr_coord(Side, w(C, CC)),
    tr_read(Side, Kind, Rest0, S1), !,
    S = join(w(C, CC), none, S1).
tr_read0(Side, Kind, Words0, S) :-
    tr_uncomma(Words0, [w(C, CC)|Rest]), Rest \== [],
    tr_connector(Side, C),
    tr_read(Side, Kind, Rest, S1), !,
    S = join(w(C, CC), none, S1).
%% A CLAUSE WITH NO VERB AT ALL IS ITS COMPLEMENTS, and two kinds of it are
%% ordinary prose: an exclamation, `¡Atención al veneno mental de la hora de
%% la sopa!', and a clause that leaves out the verb of the one before it,
%% `se les llamará muchachos conflictivos; en los de clase media, chicos
%% difíciles' -- the same calling, of other boys. Both are what is left
%% when the verb is taken out, so they read the same way: the words split
%% at their comma, if they have one, into what stood before the missing verb
%% and what stood after it, each read as complements. gap(Front, Back) is
%% the term, and every writer puts back the complements and the comma --
%% and never a verb, which is how all three languages write both kinds.
%%
%% IT IS TRIED LAST, AND ONLY WHERE NO WORD COULD START A VERB GROUP, so a
%% sentence with a verb in it is never read as one that lacks it. And a PART
%% of a sentence -- one side of a comma or a connector -- is verbless only in
%% the gapped form, a comma where the verb was: without that, any tail after
%% `o' read as a clause of its own, and `anárquica o xenófoba' lost its
%% last adjective to one.
%% A SENTENCE THAT IS ONE PHRASE WITH ITS RELATIVE CLAUSE: `Una scelta
%% strategica da cui ci attendiamo positive conseguenze', `Una buona notizia
%% che consolida definitivamente l'integrazione'. The verb is the relative
%% clause's, so the verbless reading below -- which wants no word that could
%% start a group -- stands down, and the phrase had no verb of its own to be
%% a statement. The whole piece is read as one phrase, and only a phrase
%% that carries a clause: a piece with no verb anywhere is the reading
%% below.
tr_read0(Side, statement, Words0, gap([], [obj(NP)])) :-
    tr_global('$tr_piece', Piece), Piece == Words0,
    \+ memberchk(comma, Words0),
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    tr_phrase_np(Side, Words0, NP), ( NP = rc(_, _, _) ; NP = rel(_, _, _) ), !.
%% ... AND A PHRASE WITH A CLAUSE OPENED BY A QUESTION WORD: `Amene località
%% dove le auto, le moto e i ciclomotori di gitanti e turisti sono banditi'
%% -- pleasant places where cars are banned. The complement reader reads it
%% as the phrase and a relative `where' (rwh/2), and the clause's verb had
%% shut out the verbless reading.
tr_read0(Side, statement, Words0, gap([], [obj(NP), rwh(Q, S)])) :-
    tr_global('$tr_piece', Piece), Piece == Words0,
    \+ memberchk(comma, Words0),
    %% -- and never a phrase whose head is a conjunction: `cioè quando gli
    %% altri erano vicini' is `that is' and a clause, and read here `that is'
    %% was the NOUN of a phrase the clause was said of
    Words0 = [W0|_], \+ tr_is(Side, W0, preposition), \+ tr_is(Side, W0, conjunction),
    once(( member(w(QW, _), Words0), tr_indirect_word(Side, QW, _) )),
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    tr_complements(Side, Words0, [obj(NP), rwh(Q, S)]), !.
%% (and a phrase with a participle after its noun is the same kind of
%% sentence, the headline's: `Auto proibite nelle isole del sole.' -- tried
%% BEFORE the verbless reading below, which took `proibite' for an adjective
%% no lesson of the other language has a word for)
%% ... AND A HEADLINE'S PARTICIPLE WITH ITS PHRASES AFTER IT: `Auto
%% proibite nelle isole del sole' is cars banned in the islands of the sun.
%% A reduced relative takes an agent after its participle and nothing else,
%% which is right inside a clause, where a phrase after the participle may
%% be the verb's; a whole piece with no verb has no verb to give it to. The
%% phrase is in the participle's number: `auto' is both.
tr_read0(Side, statement, Words0, gap([], [obj(rel(NP, L, Comps))])) :-
    tr_global('$tr_piece', Piece), Piece == Words0,
    \+ memberchk(comma, Words0),
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    append(Core, [w(P, PC)|Rest], Words0), Core \== [], Rest \== [],
    tr_participle_here(Side, P, L), tr_participle_number(P, PN),
    tr_object_phrase(Side, Core, NP0), NP0 \= rel(_, _, _), tr_np_in_number(Side, NP0, PN, NP),
    tr_complements(Side, Rest, Comps0), Comps0 \== [], tr_adjuncts(Comps0),
    tr_rel_agreement(Side, P, NP, Comps0, Comps1), tr_rel_case(PC, Comps1, Comps), !.

%% a phrase in a number its noun can be read in: `auto' is `car' and `cars'
tr_np_in_number(Side, np(D, M, As, w(NW, NC), N0), N, np(D, M, As, w(NW, NC), N)) :- !,
    ( N0 == N -> true ; tr_lexeme(Side, NW, _, N) ).
tr_np_in_number(_, NP, N, NP) :- fo_np_number(NP, N).

%% A CLAUSE OPENED BY `when' OR `where' MAY STAND ALONE, said of what came
%% before it: `l'abbiamo vinto a schiatto: cioè quando gli altri erano
%% vicini al traguardo' is the colon, `that is', and a time clause with no
%% clause of its own to hang on. It is the relative word's clause, rwh/2,
%% which a writer spells with the lesson's conjunction -- `cuando', where
%% the question is `cuándo'. Only these two: a `how' or a `why' standing
%% alone asks something.
tr_read0(Side, statement, [w(QW, _)|Ws], gap([], [rwh(Q, S)])) :-
    Ws \== [], tr_indirect_word(Side, QW, Q), memberchk(Q, [when, where]),
    tr_read_nested(Side, Ws, none, S), !.
%% ... AND ONE WHOSE MAIN CLAUSE FOLLOWS WITH NO COMMA: `Cuando pudieron
%% rescatar al accidentado descubrieron con cierta sorpresa que ...' -- when
%% they could rescue him, they found. Nothing marks where the time clause
%% ends but the main clause's verb, and read as one clause the piece had two
%% verbs and no reading. It divides before a word that starts a verb group,
%% the nearest first, where the time clause reads before it and a statement
%% after it -- never across a comma, which the division at a comma reads.
%% Nothing is written between the two, join(aside, ...), as the source put
%% nothing there.
tr_read0(Side, statement, [w(QW, _)|Ws], join(aside, gap([], [rwh(when, S1)]), S2)) :-
    Ws \== [], tr_indirect_word(Side, QW, when),
    append(Left, Right, Ws), Left \== [], \+ memberchk(comma, Left),
    Right = [w(_, _)|_], tr_group_at(Side, Right, _, _),
    tr_read_nested(Side, Left, none, S1),
    tr_read(Side, statement, Right, S2), !.
tr_read0(Side, _, Words0, S) :- tr_verbless(Side, Words0, S), !.
%% A NAME ALONE: `The Washington Post.' heads an extract with the paper it
%% came from, and no word of it is the lesson's, which the reading below
%% asks for. Two capitalised words at least, none the lesson knows: one such
%% word alone is a verb with its pronouns joined on as often as it is a
%% name (`¡Lárgate!'). It goes out as the source spelled it.
tr_verbless(Side, Words0, gap([], [obj(name(N))])) :-
    tr_global('$tr_piece', Piece), Piece == Words0,
    Words0 = [_, _|_], forall(member(W, Words0), tr_name_word(Side, W)),
    tr_np(Side, Words0, name(N)), !.
%% A PARTICIPLE STANDING ALONE IN A CLAUSE WITH NO VERB AGREES WITH THE FORM
%% THE SOURCE GAVE IT: `purché praticata con rigorosi controlli' is the
%% therapy, provided it is practised, and with no subject in the clause the
%% writer's gender was whatever the clause before it left -- `siempre que
%% practicado'. The form's own gender and number travel as agr/1 and agrn/1
%% beside it, the reduced relative's own two (1.6.21), and only when they
%% are not the default.
tr_verbless(Side, Words0, gap(Front, Back)) :-
    tr_verbless0(Side, Words0, gap(Front0, Back0)),
    tr_gap_agreement(Side, Words0, Front0, Front),
    tr_gap_agreement(Side, Words0, Back0, Back).
tr_gap_agreement(foreign, Words, Cs0, Cs) :-
    memberchk(pred(L), Cs0), member(w(P, _), Words), atom(P), tr_participle_here(foreign, P, L), !,
    ( tr_holds(feminine(P)) -> A1 = [agr(feminine)] ; A1 = [] ),
    ( tr_participle_number(P, plural) -> A2 = [agrn(plural)] ; A2 = [] ),
    append([Cs0, A1, A2], Cs).
tr_gap_agreement(_, _, Cs, Cs).
tr_verbless0(Side, Words0, gap(Front, Back)) :-
    Words0 \== [],
    %% and one word of it at least is the lesson's: `¡Lárgate!' is a verb
    %% with its pronoun joined on, which no lesson here can say, and read as
    %% no verb at all it passed through untranslated as a name
    once(( member(w(KW, _), Words0), tr_known_word(Side, KW) )),
    %% ... where a word that could start one is a noun, an adjective or a
    %% number as well: `a meno 5 gradi' -- `gradi' is also what `gradire'
    %% says to one person, and that one word shut the reading out
    tr_uncomma(Words0, Plain),
    \+ ( append(_, [W1|R1], Plain), tr_group_at(Side, [W1|R1], _, _), \+ tr_also_nominal(Side, W1) ),
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    %% -- the commas AFTER the first kept, where they part a list of what the
    %% sentence names: `Un Segunda B, un campo en mal estado, la presión de
    %% jugárselo todo a partido único y la motivación de unos y otros'
    (   append(F0, [comma|B0], Words0), \+ memberchk(comma, F0), F0 \== [], B0 \== []
    ->  tr_uncomma(F0, F),
        tr_complements(Side, F, Front),
        ( tr_complements(Side, B0, Back) -> true ; tr_uncomma(B0, B), tr_complements(Side, B, Back) )
    %% ... and a WHOLE sentence with no verb in it: an exclamation, or a
    %% news item's line that says something of what it names -- a phrase and
    %% an adjunct that is no `di' phrase of it, `Centotrentamila in partenza
    %% da Milano.' A phrase alone is still refused, `El pan del perro.':
    %% nothing is said of it --
    %% EXCEPT A HEADING, AN ARTICLE AND ITS NOUN: `Il futuro.' ends one part
    %% of an interview and opens the next, and a paper's heading says nothing
    %% of what it names by being one. `The house.' reads with it, which the
    %% refusals had pinned.
    %% ... WITH ITS ADJECTIVES AND ITS `DE' PHRASES: `El voto de los
    %% descontentos.' heads the second half of a report on an election, and
    %% it is `El pan del perro.' in shape, which the refusals had pinned too.
    %% A heading is a phrase that names, and nothing tells it from any other
    %% phrase standing alone -- so what stays refused is a phrase with no
    %% article, `Pan del perro.', which names nothing in particular.
    ;   (   tr_global('$tr_piece', Piece), Piece == Words0
        ;   tr_global('$tr_heading', H), H == Words0
        ),
        Front = [], tr_uncomma(Words0, W), tr_complements(Side, W, Back),
        (   tr_global('$tr_exclaim', yes) -> true
        ;   tr_global('$tr_heading', H2), H2 == Words0 -> true
        ;   tr_predicated(Side, Back) -> true
        ;   Back = [obj(np(det(article, _, _), none, _, w(_, _), _))|PPs],
            forall(member(X, PPs), ( X = pp(P, _), tr_means_of(Side, P) ))
        %% ... AND A SECTION'S NAME, ONE NOUN ALONE: `Lettere.' heads a
        %% paper's letters page, and a bare noun of one word names the section
        %% it opens. Two words with no article stay refused, `Big house.'
        ;   Words0 = [_], Back = [obj(np(none, none, [], w(_, _), _))]
        %% ... AND A BARE NOUN OF SOMEBODY NAMED: `Prudencia de Matutes.'
        %% heads the half of a report that is the minister's, and what it is
        %% of is someone named -- which is what `Pan del perro.' lacks, and
        %% that one stays refused
        ;   Back = [obj(np(none, none, _, w(_, _), _)), pp(P, name(_))], tr_means_of(Side, P)
        )
    ), Back \== [], !.
%% ... and the phrase is one the lesson knows: a capitalised word at the head
%% that no lesson knows is not taken for a name here, because a verb with
%% its pronouns joined on looks the same -- `Quédate ahí.', `Besa a Tomás.'
%% came out `Quédate here.' and `Besa to Tomás.'
tr_predicated(Side, [obj(NP)|Cs]) :-
    NP \= name(_), member(C, Cs), ( C = adv(_) ; C = pp(P, _), \+ tr_means_of(Side, P) ), !.
tr_also_nominal(Side, W) :- ( tr_is(Side, W, noun) ; tr_is(Side, W, adjective) ; tr_is(Side, W, number) ), !.

%% every selection of the adverb words, KEEPING each one before lifting it
%% -- so the first solution lifts nothing (which the caller rejects) and
%% the ones after it lift as few as the reading needs.
tr_adverbs_off(_, [], [], []).
tr_adverbs_off(Side, [W|Ws], [W|Rest], Advs) :- tr_adverbs_off(Side, Ws, Rest, Advs).
tr_adverbs_off(Side, [W|Ws], Rest, [adv(W)|Advs]) :-
    tr_plain_adverb(Side, W), tr_adverbs_off(Side, Ws, Rest, Advs).

%% the first division whose two sides both read: a connecting word the
%% lesson gives (`e', `ma', `perche'), or a bare comma. The connector
%% travels as the word it was written with and crosses through mean/2 like
%% every other word; a comma has no word and travels as the atom.
%% A SEMICOLON IS TRIED FIRST: it divides more strongly than a comma or a
%% connecting word, and a sentence that has one divides there before it
%% divides anywhere inside either half
tr_clause_split(_, Words, Left, semicolon, Right) :-
    append(Left0, [semicolon|Right0], Words),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right).
%% A SUBORDINATING WORD DIVIDES BEFORE A COORDINATING ONE, and the last of
%% them first: `raggiunti dagli uomini del soccorso alpino e speleologico che
%% li hanno trovati vigili e in buone condizioni NONOSTANTE le temperature
%% ... abbiano raggiunto i -10 gradi' is a finding and then the cold it was
%% found in, and divided at its first `e' both sides happened to read and
%% neither was a clause of the sentence -- the rescue came out `alpine' and
%% the rest `speleological that found them'. The `e's inside a phrase or a
%% clause are then read where they stand, inside the side that holds them.
tr_clause_split(Side, Words, Left, Conn, Right) :-
    findall(L0-X-R0, append(L0, [X|R0], Words), Splits0), reverse(Splits0, Splits),
    member(Left1-w(C, CC)-Right0, Splits),
    tr_connector(Side, C), \+ tr_coord(Side, w(C, CC)),
    %% `... in vacanza E MENTRE il compagno ...': a coordinator straight
    %% before the subordinating word joins the whole of what follows, and
    %% left on the first side it was read as the last word of a phrase
    (   append(Left0, [K], Left1), K = w(_, _), tr_coord(Side, K), Left0 \== []
    ->  Conn = both(K, w(C, CC))
    %% ... and a COMMA before it is the source's and is written back: `...
    %% la terapia del dolore, in modo che il malato possa ...' lost it
    ;   append(Left0, [comma], Left1), Left0 \== []
    ->  Conn = both(comma, w(C, CC))
    ;   Left0 = Left1, Conn = w(C, CC)
    ),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right).
%% ... AND NEVER BEFORE A BARE NOUN IN THE SINGULAR, which begins no clause
%% here: `Si bien la demanda de las familias en productos de ocio Y
%% entretenimiento mantuvo ...' divided at the `y', the first half read as
%% `although she sues her ...' and the second as `entertainment kept ...',
%% and the division at the comma after them, which is the sentence's, was
%% never tried (tr_bare_start/2).
%% -- and a COMMA before it is the source's, and is written back: `... no
%% son optimistas, y se prevé un mantenimiento' lost it
tr_clause_split(Side, Words, Left, Conn, Right) :-
    append(Left1, [w(C, CC)|Right0], Words),
    tr_connector(Side, C), tr_coord(Side, w(C, CC)),
    \+ tr_bare_start(Side, Right0),
    \+ tr_joins_phrases(Side, Left1, Right0),
    (   append(Left0, [comma], Left1), Left0 \== [] -> Conn = both(comma, w(C, CC)) ; Left0 = Left1, Conn = w(C, CC) ),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right).
%% ... NOR BETWEEN TWO PHRASES OF ONE PREPOSITION: `il responsabile
%% dell'ambiente E dei lavori pubblici' is one manager, of the environment and
%% of public works, and divided at that `e' the rest read with the second
%% phrase fronted and the sentence came out in pieces. The preposition after
%% the coordinator is the one the left side's last phrase opened on.
tr_joins_phrases(Side, Left, [P|_]) :-
    P = w(PW, _), tr_is(Side, P, preposition),
    append(_, [w(PW, _)|After], Left),
    \+ ( member(X, After), ( X == comma ; X = w(_, _), ( tr_is(Side, X, preposition) ; tr_coord(Side, X) ) ) ), !.
tr_clause_split(_, Words, Left, comma, Right) :-
    append(Left0, [comma|Right0], Words),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right).

%% THE REPORTING CLAUSE: its verb first and its SUBJECT AFTER IT, among its
%% complements -- `ha raccontato a Sky Tg24 Tornaboni', `ha spiegato un
%% soccorritore', `fa sapere, in una nota, la Regione Lazio spiegando che
%% ...' -- which is where both lesson languages put the speaker. The
%% quotation is what was said, so the clause has NO OBJECT of its own, and
%% that is what chooses among the places the subject could stand: read with
%% `Tg24' for the speaker, `Tornaboni' was left over as an object. A name
%% after the clause's last comma is its apposition (`il capitano ...,
%% Alessio Falzone'). The subject's place travels as subj_here among the
%% complements, so the lesson's writer puts it back where it stood, and
%% English's writes it first.
tr_read_reporting(foreign, Words0, S) :- tr_reporting(any, Words0, S), !.
%% ... AND ONE WITH NO SPEAKER AT ALL, the verb alone: `Gallo - continua -
%% mi ha lasciato una società disastrata' is the man quoted going on, and
%% the one who speaks is the one the sentences before named. Read as a
%% clause of its own it had nobody for a subject, and the dashes kept it
%% from the sentence around it; it is the reporting clause, in the third
%% person singular, and nothing is said of it but the verb.
tr_read_reporting(foreign, Words, s(none, null(third, singular), g(L, T, A, no), [])) :-
    Words = [w(_, _)|_],
    tr_group_from(foreign, Words, [], g(L, T, A, third, singular), []), atom(L), !.

%% the first clause of it, with the speaker it must have: `any' where a
%% quotation mark already says that something was said, and `person' where
%% only the speaker can say so (the reporting clause at the end of a
%% sentence, tr_read0/4) -- asked AS SOON AS the subject is read, and with no
%% pronoun before the verb, because the complements after it are the costly
%% part: read for every phrase the clause could have for its subject,
%% `avrebbe intascato tangenti ... e truffato la comunità ... (per la
%% valutazione ... di un terreno)' cost a million inferences to find that
%% none of them is a person
tr_reporting(Who, Words0, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    Words = [W0|_], W0 \== comma,
    ( Who == person -> Before = [] ; true ),
    tr_group_from(foreign, Words, Before, g(L, T, A, FP, FN), After),
    tr_uncomma(Before, BeforeU),
    forall(member(w(C, _), BeforeU), tr_clitic(normal, C)),
    nb_setval('$tr_read_group', L), nb_setval('$tr_read_aspect', A),
    append(Pre, SubjPost, After),
    %% (a speaker the clause must have stands after no preposition, which
    %% would govern it: `si disse subito dopo Hiroshima' is IT WAS SAID right
    %% after Hiroshima, and in `... del duomo arabo normanno di Monreale' the
    %% town is the cathedral's)
    \+ ( Who == person, last(Pre, P), P = w(_, _), tr_is(foreign, P, preposition) ),
    %% a name after a determiner is ONE name, and the speaker does not begin
    %% inside it: `cuenta con una June Anderson en plena forma' has June
    %% Anderson for a singer to count on, and cut after `June' it had
    %% `Anderson' telling the rest
    \+ ( SubjPost = [w(_, upper)|_], append(_, [D|Ns], Pre), Ns \== [], tr_determiner(foreign, D, _, _),
         forall(member(N, Ns), N = w(_, upper)) ),
    tr_report_subject(SubjPost, FP, FN, SW, Post),
    tr_subject(foreign, none, SW, FP, FN, Subject),
    ( Who == person -> tr_of_class(Subject, person) ; true ),
    tr_complements(foreign, Pre, C1), tr_complements(foreign, Post, C20),
    tr_report_appos(C20, C2),
    \+ memberchk(obj(_), C1), \+ memberchk(obj(_), C2), !,
    findall(opron(W), member(W, BeforeU), Cs),
    append(Cs, C1, C1a), append(C1a, [subj_here|C2], Comps),
    S = s(none, Subject, g(L, T, A, Neg), Comps).

%% the speaker: a run of capitalised words no lesson knows, which is one
%% name -- never one opening on a word with a digit in it, `Tg24' being a
%% channel's -- or a phrase agreeing with the verb
tr_report_subject([W1|Ws], P, N, SW, Rest) :-
    tr_name_word(foreign, W1), \+ tr_digit_word(W1), !,
    tr_name_run([W1|Ws], SW, Rest), P == third, N == singular.
%% -- and the phrase OPENS ON A DETERMINER. A bare noun after the verb is its
%% object in both lesson languages, never its subject: `Lei voleva fare una
%% passeggiata, ha sbagliato strada, ...' read `ha sbagliato strada' as a
%% clause REPORTING the rest, spoken by a road, and wrote it after the
%% sentence. `sottolinea il Lingotto', `ha spiegato un soccorritore' and
%% `aggiunge l'ad Sergio Marchionne' all open on one.
tr_report_subject(Words, P, N, SW, Rest) :-
    Words \= [comma|_],
    fo_np_words_after(Words, SW0, Rest0), SW0 = [D|_], tr_determiner(foreign, D, _, _),
    fo_agreeing(SW0, P, N),
    tr_report_name_after(SW0, Rest0, SW, Rest).

%% A NAME AFTER THE SPEAKER'S PHRASE IS THE SPEAKER'S: `spiega il segretario
%% nazionale Ferdinando Uliano', `aggiunge l'ad Sergio Marchionne'. The phrase
%% ends where the name begins, and the name after it was read as an object of
%% the verb -- which a reporting clause has none of, so the clause was
%% refused. The name's words join as ONE word, apposed to the phrase's noun
%% as `il presidente Scalfaro' is.
tr_report_name_after(SW0, Rest0, SW, Rest) :-
    tr_name_run(Rest0, [N1|Ns], Rest), \+ tr_digit_word(N1), !,
    findall(C, ( member(w(X, _), [N1|Ns]), tr_cap(X, C) ), Cs), atomic_list_concat(Cs, ' ', A),
    append(SW0, [w(A, upper)], SW).
tr_report_name_after(SW, Rest, SW, Rest).

tr_digit_word(w(W, _)) :- atom_codes(W, Cs), member(C, Cs), rt_digit(C), !.

%% a name after the clause's last comma is the apposition of the phrase
%% before it, and no object
tr_report_appos(Cs0, Cs) :-
    append(Front, [sep, obj(NP)], Cs0), NP = name(_), !, append(Front, [sep, appos(NP)], Cs).
%% ... and so is a PHRASE after it, with the phrases of `of' that complete
%% it: `commenta John Elkann, presidente di Fiat' -- read as the verb's
%% object the clause had one, was read as a statement instead, and the
%% speaker came out with the person marker in front, `comenta a John Elkann'
tr_report_appos(Cs0, Cs) :-
    append(Front, [sep, obj(NP)|Tail], Cs0), NP = np(_, _, _, _, _),
    forall(member(T, Tail), T = pp(_, _)), !,
    append(Front, [sep, appos(NP)|Tail], Cs).
tr_report_appos(Cs, Cs).

%% a side of a division: at least one word, and a comma of its own at the
%% edge is punctuation rather than another clause (`, perche ...')
tr_clause_words(Ws0, Ws) :-
    ( append([comma], W1, Ws0) -> true ; W1 = Ws0 ),
    ( append(Ws, [comma], W1) -> true ; Ws = W1 ),
    Ws \== [], \+ memberchk(Ws, [[comma]]),
    \+ ( Ws = [M], atom(M) ).

%% a word that joins two clauses: one the lesson calls a conjunction whose
%% meaning is one of English's connectors, or one of English's own
tr_connector(english, W) :- !, en_connector(W).
tr_connector(foreign, W) :-
    tr_lexeme(foreign, W, L, _), tr_class_of(L, conjunction),
    tr_solve(mean(L, E)), en_connector(E), !.

en_connector(and).  en_connector(but).  en_connector(or).
en_connector(because).  en_connector(so).  en_connector(while).
en_connector(although). en_connector('ever since').      % `sin da quando nel 2009 siamo stati scelti'
en_connector(without).                                   % `sin que un experto lo note'
en_connector(if).                                        % `neanche se vi sia l'assenso del paziente'
en_connector('so that').                                 % `in modo che il malato possa accostarsi'
en_connector('provided that').                           % `purché praticata con rigorosi controlli'
en_connector(since).                                     % `ya que nos espera un mes de febrero'
en_connector('not that').                                % `Non che la tranquillità ... sia garantita per tutti'
en_connector('apart from the fact that').               % `al margen de que, como todos, han disfrutado'
en_connector('that is').                                 % `l'abbiamo vinto a schiatto: cioè quando gli altri ...'
en_connector(as).                                        % `A medida que los precios ... se han abaratado, la extensión ...'

tr_normalise(_, statement, Words, Words, none) :- !.
tr_normalise(english, question, Words0, Words, Asked) :-
    en_question_word(Words0, Words1, Asked),
    en_unfront(Asked, Words1, Words).
tr_normalise(foreign, question, Words0, Words, Asked) :-
    fo_question_word(Words0, Words1, Asked),
    fo_unfront(Asked, Words1, Words).

%% English's question word, and what it asks for: `which' takes the noun
%% phrase after it, which is the object when `does', `will', `has' or the
%% copula follows with a subject and its verb after them (`Which book does
%% Maria read?', `Which book has Maria read?'), and the subject otherwise
%% (`Which dog will eat the bread?', `Which house is big?')
en_question_word([w(which, C)|Ws], Words, Asked) :- !,
    en_np_words(Ws, NP, Rest),
    (   Rest = [w(A, _)|R1], en_fronts(A), en_np_words(R1, S, R2), S \== [], R2 = [w(V, _)|_], ( en_verb_form(V, _, _) ; en_participle(V, _) )
    ->  Asked = object(which(NP, C)), Words = Rest
    ;   Asked = subject(which(NP, C)), Words = Rest
    ).
en_question_word([w(P, PC), w(which, C)|Ws], Words, pp(w(P, PC), which(NP, C))) :-
    en_preposition(P), !, en_np_words(Ws, NP, Words).
en_question_word([w(Q, C)|Ws], Ws, Asked) :- en_question(Q, Kind), !, Asked =.. [Kind, w(Q, C)].
en_question_word(Ws, Ws, none).

en_question(what, object).   en_question(whom, object).   en_question(who, subject).
en_question(where, place).   en_question(when, time).     en_question(which, which).
en_question(how, manner).

%% a fronted `does', `do', `did', `will', `has', `have', `had' or copula goes
%% back behind the subject phrase; not when the subject is what is asked
en_unfront(subject(_), Ws, Ws) :- !.
en_unfront(_, [w(A, AC), w(there, TC)|Ws], [w(there, TC), w(A, AC)|Ws]) :- en_fronts(A), !.      % `Is there a dog?'
en_unfront(_, [w(A, C)|Ws], Words) :-
    en_fronts(A), !,
    en_np_words(Ws, NP, Rest),
    append(NP, [w(A, C)|Rest], Words).
en_unfront(_, Ws, Ws).

en_fronts(A) :- memberchk(A, [does, do, did, will, would, has, have, had, am, is, are, was, were, can, could, may, might, must, should]).

%% the subject phrase at the head of the words: a pronoun, a name, or up to
%% and including the first word the lesson calls a noun -- failing that up
%% to the first verbal word
en_np_words([w(P, C)|Rest], [w(P, C)], Rest) :- en_subject(P, _, _), !.
en_np_words([w(P, C)|Rest], [w(P, C)], Rest) :- en_tonic(P, _), \+ en_phrase_follows(Rest), !.   % `Is this big?', not `Is this dog big?'
en_np_words([w(W, upper)|Rest], [w(W, upper)], Rest) :- \+ tr_known_word(english, W), !.
en_np_words(Words, NP, Rest) :-
    append(NP0, Rest0, Words), NP0 \== [], last(NP0, N), tr_is(english, N, noun), !,
    en_np_more(Rest0, More, Rest1), append(NP0, More, NP1),
    en_np_pps(Rest1, PPs, Rest), append(NP1, PPs, NP).

%% a noun, a number, or adjectives and then one: what makes `this' a
%% determiner rather than the pronoun standing alone
en_phrase_follows([W|_]) :- ( tr_is(english, W, noun) ; tr_is(english, W, number) ), !.
en_phrase_follows([W|Ws]) :- tr_is(english, W, adjective), en_phrase_follows(Ws).

%% ... and on over the NOUNS after that noun that are no verb's form, while
%% a verb still follows: `the black cat sleeps', where `black' is a noun
%% too by its translation and `cat' would have been left to the verb; not
%% `the cat black' of a fronted `Is the cat black?', which has no verb
%% left after it
en_np_more([W|Ws], [W|More], Rest) :-
    tr_is(english, W, noun), W = w(V, _), \+ en_verb_form(V, _, _), \+ en_fronts(V),
    member(w(V2, _), Ws), ( en_fronts(V2) ; en_verb_form(V2, _, _) ), !,
    en_np_more(Ws, More, Rest).
en_np_more(Ws, [], Ws).
en_np_words(Words, NP, Rest) :- append(NP, Rest, Words), NP \== [], Rest = [w(V, _)|_], ( en_fronts(V) ; en_verb_form(V, _, _) ), !.
en_np_words(Words, Words, []).

%% a phrase after a preposition after the noun belongs to it: `the dogs of Maria'
en_np_pps([w(P, C)|Ws], [w(P, C)|NP], Rest) :-
    en_preposition(P), en_np_words(Ws, NP, Rest), NP \== [], \+ ( NP = [w(V, _)|_], en_verb_form(V, _, _) ), !.
en_np_pps(Ws, [], Ws).

%% the lesson's question word, by its meaning; `which' takes the noun phrase
%% after it, and asks for the object when a name or a pronoun stands alone
%% after the verb (`¿Qué libro lee Maria?'), for the subject otherwise
%% the word the lesson puts before a person, then the question word: a
%% person asked for as the OBJECT -- `¿A quién ve Maria?' is whom, `¿A qué
%% amigo ve Maria?' which friend
fo_question_word([w(P, _), w(Q, C)|Ws], Words, Asked) :-
    tr_marker_word(P),
    tr_solve(mean(Q, E0)), en_question(E0, _), !,
    (   tr_solve(mean(Q, which)), Ws = [W1|_], fo_phrase_word(W1)
    ->  fo_np_words(Ws, NP, Words), Asked = object(which(NP, C))
    ;   Asked = object(w(Q, C)), Words = Ws
    ).
%% A PREPOSITION BEFORE THE QUESTION WORD ASKS FOR AN ADJUNCT: `in che
%% razza di mondo sarei nata?' is in what kind of world I would have been
%% born, and nothing is missing from the clause after it. The preposition
%% and the phrase travel as pp(Preposition, which(Phrase, Case)), whatever
%% word asked -- `che' means `what' in the lesson, and with a phrase after it
%% it is the determiner English writes `which'
%% -- the phrase the words that the lesson reads as one, up to a verb group:
%% the shortest cut took `in che razza di' and the verb `mondo', what
%% `mondare' says of oneself, and never tried the world
fo_question_word([w(P, PC), w(Q, C)|Ws], Words, pp(w(P, PC), which(NP, C))) :-
    tr_is(foreign, w(P, lower), preposition), \+ tr_marker_word(P),
    ( tr_solve(mean(Q, which)) ; tr_solve(mean(Q, what)) ), Ws = [W1|_], fo_phrase_word(W1), !,
    append(NP, Words, Ws), NP \== [], Words \== [],
    tr_group(foreign, Words, [], _, _, _), tr_which_phrase(foreign, NP, _).
fo_question_word([w(Q, C)|Ws], Words, Asked) :-
    tr_solve(mean(Q, E0)), en_question(E0, _), !,
    (   tr_solve(mean(Q, which)), Ws = [W1|_], fo_phrase_word(W1)
    ->  fo_np_words(Ws, NP, Rest),
        tr_group(foreign, Rest, [], _, _, After),
        (   fo_lone_subject(After) -> Asked = object(which(NP, C)) ; Asked = subject(which(NP, C)) ),
        Words = Rest
    ;   tr_solve(mean(Q, E)), en_question(E, Kind0), Kind0 \== which, !,
        ( Kind0 == object, fo_asks_subject(Ws) -> Kind = subject ; Kind = Kind0 ),
        Asked =.. [Kind, w(Q, C)], Words = Ws
    ).

%% WHAT A VERB THAT TAKES NO OBJECT ASKS IS ITS SUBJECT: `Che cosa sarebbe
%% accaduto?' is what would have happened, and a verb whose perfect takes the
%% copula (tr_unaccusative/1) has no object for `what' to be -- asked as the
%% object, the subject was nobody named, and English refused it
fo_asks_subject(Ws) :-
    tr_group(foreign, Ws, [], G, _, _), arg(1, G, L), atom(L), tr_unaccusative(L), !.
fo_question_word(Ws, Ws, none).

fo_phrase_word(W) :- ( tr_is(foreign, W, noun) ; tr_is(foreign, W, adjective) ; tr_determiner(foreign, W, _, _) ), !.

fo_lone_subject([w(W, upper)]) :- \+ tr_known_word(foreign, W), !.
fo_lone_subject([w(W, _)]) :- tr_subject_pronoun(foreign, W, _, _).

%% the noun phrase at the head: a name, a pronoun, or a determiner and its
%% content up to the verb group. THE SHAPE IS TRIED BEFORE THE CUT: a
%% determiner, adjectives, a noun and adjectives with the verb group right
%% after, and only then the shortest head the verb group follows -- because
%% with a vocabulary of thousands of verbs a noun is often a verb's form too
%% (`hermano' is the first person of `hermana', to twin), and the shortest
%% cut put the verb at `hermano' and left `Mi' as the subject.
fo_np_words([w(W, upper)|Rest], [w(W, upper)], Rest) :- \+ tr_known_word(foreign, W), !.
fo_np_words([w(P, C)|Rest], [w(P, C)], Rest) :- tr_subject_pronoun(foreign, P, _, _), !.
fo_np_words(Words, NP, Rest) :-
    Words = [w(D, _)|_], tr_determiner(foreign, w(D, lower), _, _),
    append(NP, Rest, Words), NP = [_|Content], Content \== [],
    tr_np_shape(foreign, Content), tr_group(foreign, Rest, [], _, _, _), !.
fo_np_words(Words, NP, Rest) :- append(NP, Rest, Words), NP \== [], tr_group(foreign, Rest, [], _, _, _), !.
fo_np_words(Words, Words, []).

%% adjectives, one noun, adjectives: the content of a phrase
tr_np_shape(Side, Content) :-
    append(Before, [N|After], Content), tr_is(Side, N, noun),
    forall(member(A, Before), tr_is(Side, A, adjective)),
    forall(member(A, After), tr_is(Side, A, adjective)), !.

%% a verb that came first takes its subject from after it: a bare adjective
%% right after the verb is the complement and the subject follows it
%% (`¿Es grande la casa?'); otherwise the first phrase, a name or a pronoun
fo_unfront(subject(_), Ws, Ws) :- !.
fo_unfront(_, Words, Words1) :-
    tr_negation(foreign, Words, W1, Neg),
    tr_group(foreign, W1, Before, g(_, _, _, P, N), Group, After),
    tr_split_clitics(foreign, Before, fronted, _, _, [], Clitics), !,
    fo_subject_after(After, P, N, Subject, Rest),
    append(Subject, Clitics, S1), append(S1, Group, S2), append(S2, Rest, W2),
    ( Neg == yes -> tr_negation_word(No), Words1 = [w(No, lower)|W2] ; Words1 = W2 ).
fo_unfront(_, Ws, Ws).

%% what follows the verb is its subject only when it agrees with it: after
%% `¿Comes ...?' nothing does, and the verb says who
fo_subject_after([A|After], P, N, Subject, [A]) :-
    tr_is(foreign, A, adjective), After \== [], fo_agreeing(After, P, N), !, Subject = After.
%% an infinitive between the verb and its subject stays where it is
%% (`¿Quiere comer Maria?'): it is no subject
fo_subject_after([w(V, C)|After], P, N, Subject, [w(V, C)|Rest]) :-
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !, fo_subject_after(After, P, N, Subject, Rest).
fo_subject_after(After, P, N, Subject, Rest) :-
    fo_np_words_after(After, Subject0, Rest0), Subject0 \== [], fo_agreeing(Subject0, P, N), !,
    Subject = Subject0, Rest = Rest0.
fo_subject_after(After, _, _, [], After).

fo_agreeing([w(W, _)], P, N) :- tr_subject_pronoun(foreign, W, P1, N1), !, P1 == P, N1 == N.
fo_agreeing([w(W, upper)], P, N) :- \+ tr_known_word(foreign, W), !, P == third, N == singular.
fo_agreeing(Words, third, N) :- tr_np(foreign, Words, NP), !, fo_np_number(NP, N1), N1 == N.
%% ... and a list that begins with its own connector is the list after it
fo_agreeing([w(C, _)|Words], third, plural) :- tr_neither_word(C), fo_agreeing(Words, third, plural), !.
%% two phrases joined are plural: `ritrovati vivi donna e bimbi scomparsi'
%% -- and three, the second half a list itself: `ni Rivaldo ni Overmars ni
%% De la Peña'
fo_agreeing(Words, third, plural) :-
    tr_conjunction_split(foreign, Words, W1, W2), tr_np(foreign, W1, _),
    ( tr_np(foreign, W2, _) -> true ; fo_agreeing(W2, third, plural) ), !.

%% a phrase's number, through a reduced relative to the phrase it sits on --
%% `il coprifuoco imposto dai soldati' is singular, and without this clause
%% a rel/3 matched no np/5 and an inverted subject with a participle after
%% it was refused
fo_np_number(rel(NP, _, _), N) :- !, fo_np_number(NP, N).
fo_np_number(all(_, NP), N) :- !, fo_np_number(NP, N).
fo_np_number(app(NP, _, _), N) :- !, fo_np_number(NP, N).
fo_np_number(np(_, _, _, _, N), N).
%% ... and a name is one, a capitalised word the lesson knows included
%% (tr_np/3 reads `va via Pellegrini' so): the plural of `pellegrino' it
%% also is said nothing of the man
fo_np_number(name(_), singular).

%% the subject after the verb: a name, a pronoun, or a phrase up to the next
%% determiner, name, pronoun or preposition
%% A REDUCED RELATIVE AND ITS AGENT STAY INSIDE THE SUBJECT, as they do in
%% tr_phrase_words/4 for a phrase before the verb: `Qui dominava il
%% coprifuoco imposto dai soldati' is the curfew-that-was-imposed
%% dominating, and the agent belongs to the participle rather than to the
%% sentence's verb.
fo_np_words_after(Words, Content, Rest) :-
    append(PW0, Rest0, Words), PW0 \== [],
    last(PW0, w(P, _)), tr_participle_here(foreign, P, _),
    Rest0 = [B|_], tr_is(foreign, B, preposition), tr_means_by(foreign, B),
    tr_reduced_agent(foreign, Rest0, _), !,
    append(PW0, Rest0, Content), Rest = [].
%% ... and a participle with a NAME after it, the whole name: `destaca un
%% violín llamado Ex Von Szerdahely VieuxTemps' ended the subject at the
%% first capitalised word the lesson does not know, which is `Von'
fo_np_words_after(Words, Content, Rest) :-
    append(PW0, Rest0, Words), PW0 = [_, _|_],
    last(PW0, w(P, _)), tr_participle_here(foreign, P, _),
    tr_cap_run(Rest0, NameWs, Rest1), NameWs \== [],
    tr_reduced_agent(foreign, NameWs, [obj(name(_))]), !,
    %% ... and what stands aside after the name is the phrase's too
    ( Rest1 = [w(K, aside)|Rest] -> append(NameWs, [w(K, aside)], NameWs1) ; NameWs1 = NameWs, Rest = Rest1 ),
    append(PW0, NameWs1, Content).
fo_np_words_after([w(W, upper)|Rest], [w(W, upper)], Rest) :- \+ tr_known_word(foreign, W), !.
fo_np_words_after([w(P, C)|Rest], [w(P, C)], Rest) :- tr_subject_pronoun(foreign, P, _, _), !.
%% A DETERMINER AND A RUN OF NAME WORDS IS ONE PHRASE, whole. The clause
%% below ends a phrase at the next capitalised unknown word, which is right
%% for `Maria' and wrong inside `la Tate Gallery' -- measured, the subject
%% came back `la Tate' with `Gallery' left over as the object.
fo_np_words_after([D|After], [D|Content], Rest) :-
    tr_determiner(foreign, D, _, _), After = [W|_], tr_name_word(foreign, W), !,
    tr_name_run(After, Content, Rest).
fo_np_words_after([D|After], [D|Content], Rest) :-
    tr_determiner(foreign, D, _, _), !,
    append(Content, Rest, After), Content \== [],
    ( Rest == [] -> true ; Rest = [R|_], fo_phrase_starts(R) ), !.
fo_np_words_after(Words, Words, []).

%% the longest run of capitalised words at the head of a word list
tr_cap_run([w(W, upper)|Ws], [w(W, upper)|Run], Rest) :- !, tr_cap_run(Ws, Run, Rest).
tr_cap_run(Ws, [], Ws).

fo_phrase_starts(w(W, upper)) :- \+ tr_known_word(foreign, W), !.
fo_phrase_starts(R) :- ( tr_determiner(foreign, R, _, _) ; tr_is(foreign, R, preposition) ; tr_subject_pronoun(foreign, R, _, _) ), !.
%% ... and a GERUND ends the phrase before it: `Mi si è stretto il cuore
%% leggendo nella cronaca ...' is the heart, and what it did while reading.
%% Taken into the phrase, `il cuore leggendo' was no phrase at all, no
%% subject was found after the verb, and the heart read as its object
fo_phrase_starts(w(G, _)) :- tr_gerund_here(foreign, G, _), !.

%% ---- reading: the statement -------------------------------------------------------

%% s(Asked, Subject, Group, Complements): the denial off, the verb group
%% found, the subject before it (with the object pronouns that stand
%% before the verb taken out), the complements after it
%% A STATEMENT THAT FAILED TO READ FAILS AGAIN, as a piece does (tr_read/4):
%% the fronted reading tries every front and the division every comma, and
%% each of them asks for the same run of words as a statement over and over.
%% Measured on `Di certo si sa solo che la famiglia era ... e mentre il
%% compagno della donna, Emanuele Tornaboni, era in pista a sciare, la madre
%% si è allontanata con i bambini': 171 statement readings, 35 of them
%% distinct, 35 s. Every clause below cuts, so a statement has one reading
%% and there is nothing to keep but the failures.
tr_read_statement(Side, Words, Asked, S) :-
    (   ground(Words-Asked)
    ->  Key = rs(Side, Words, Asked), tr_failed_set(F0),
        (   get_assoc(Key, F0, _) -> fail
        ;   tr_read_statement0(Side, Words, Asked, S0) -> tr_duty_fix(S0, S01), tr_cleft_fix(Side, S01, S1), tr_vq_add(Side, Words, S1, S)
        ;   tr_failed_set(F1), put_assoc(Key, F1, x, F2), nb_setval('$tr_failed', F2), fail
        )
    ;   tr_read_statement0(Side, Words, Asked, S0), tr_duty_fix(S0, S01), tr_cleft_fix(Side, S01, S1), tr_vq_add(Side, Words, S1, S)
    ).

%% A QUOTATION THAT OPENS ON THE VERB: `proclamar que su partido "había
%% obtenido sus objetivos electorales"' quotes from the auxiliary on, and the
%% mark travelled on a word the verb group took, which keeps no case -- so
%% the Italian closed a quotation it never opened. When the opening mark
%% stood on a verb's form, a denial or a clitic and nothing in the reading
%% kept it, the clause carries vq, which every writer puts back on the first
%% word of its verb group.
tr_vq_add(Side, Words, S0, S) :- tr_vq_open(Side, Words, S0, S1), tr_vq_close(Side, Words, S1, S).
tr_vq_open(foreign, Words, S0, S) :-
    memberchk(w(_, qopen), Words), S0 = s(A, Su, G, Cs),
    append(_, [w(QW, qopen)|_], Words),
    ( tr_verb_form_word(QW) ; tr_negation_word(QW) ; tr_object_pronoun(foreign, QW, _) ),
    \+ tr_has_mark(S0), !,
    S = s(A, Su, G, [vq|Cs]).
tr_vq_open(_, _, S, S).
%% ... AND ONE THAT CLOSES ON IT: `que "el presidente del Gobierno se
%% alegra" de que haya progresado' quotes to the verb, and the clause after
%% the mark is the verb's own. The mark travelled on the verb's form, which
%% keeps no case, so the quotation opened and never closed. The clause
%% carries vqc, which every writer puts back on the LAST word of its verb
%% group.
tr_vq_close(foreign, Words, S0, S) :-
    memberchk(w(_, qclose), Words), S0 = s(A, Su, G, Cs),
    append(_, [w(QW, qclose)|_], Words),
    ( tr_verb_form_word(QW) ; tr_participle_here(foreign, QW, _) ; tr_solve(infinitive_of(QW, _)) ),
    \+ tr_has_close_mark(S0), !,
    S = s(A, Su, G, [vqc|Cs]).
tr_vq_close(_, _, S, S).
tr_has_close_mark(vqc) :- !.
tr_has_close_mark(w(_, C)) :- atom(C), memberchk(C, [qclose, qboth]), !.
tr_has_close_mark(T) :- compound(T), T =.. [_|As], member(A, As), tr_has_close_mark(A), !.

tr_has_mark(vq) :- !.
tr_has_mark(w(_, C)) :- atom(C), memberchk(C, [qopen, qboth]), !.
tr_has_mark(T) :- compound(T), T =.. [_|As], member(A, As), tr_has_mark(A), !.

%% what must be done, as English reads `must be activated': the modal the
%% lesson gives for `must', the copula's infinitive and the participle
tr_duty_fix(s(A, Su, g(L, T, duty, Neg), Cs), s(A, Su, g(M, T, simple, Neg), [inf(C), pred(L)|Cs])) :- !,
    once(( tr_solve(mean(M, must)), tr_class_of(M, modal) )), tr_copula_lexeme(C).
tr_duty_fix(S, S).

%% WHAT A COPULA WITH NOBODY BEFORE IT HAS LAST IS ITS SUBJECT: `Es la
%% posibilidad de aumentar la libertad ... lo que los hace tan deseados' --
%% it is the possibility that makes them so desired, the thing that makes
%% them desired being what the sentence is about. Read left to right it was
%% a copula with nobody named and two objects, which Italian wrote back in
%% the order it stood and English, having nobody to put first, refused. A
%% phrase whose noun a relative clause stands for, last after something the
%% copula says, is the subject after its verb, and its place travels as
%% subj_here: the lesson's language keeps the order, `È la possibilità ...
%% quello che li fa così desiderati', and English puts the subject first.
%% `Es verdad lo que dices' is the same shape.
tr_cleft_fix(foreign, s(A, null(third, singular), g(L, T, simple, Neg), Cs0), s(A, E, g(L, T, simple, Neg), Cs)) :-
    tr_copula_lexeme(L), append(Pre, [obj(E)], Cs0), Pre \== [],
    E = ell(_, _, singular, rel(_, _)),
    \+ memberchk(subj_here, Pre), !,
    append(Pre, [subj_here], Cs).
tr_cleft_fix(_, S, S).

%% A SUBJECT THAT IS THERE IS READ BEFORE ONE THAT IS NOT. `Los informes son
%% muy buenos' is the reports being good -- and read left to right the first
%% verb it met was `informes', the second person of `informar', with `los'
%% the pronoun before it: `(tú) los informes', and `son muy buenos' an object
%% whose noun was `son', a sound. Every place a verb could start is tried
%% with a subject before it first, and only then with none, which is where
%% the lesson's languages leave it out. English names its subject always.
%% ONLY WHERE THE CLAUSE OPENS ON AN ARTICLE THAT IS AN OBJECT PRONOUN TOO,
%% BEFORE A WORD THAT IS A NOUN AND A VERB'S FORM, which is the shape that
%% misread. Tried on every statement, the pass with a subject walked every
%% later verb of a long sentence first -- Livata's `Di certo si sa solo che
%% la famiglia era ...' cost 7.2 million inferences more for the same
%% reading -- and asked of any article before such a word it still ran on
%% most Italian sentences, `l'acquisto', `la parte', `l'accordo': Fiat's
%% `Siamo particolarmente soddisfatti ...' cost 9.1 million where 1.7.2's
%% cost 4.6.
tr_subject_phase(foreign, none, Words, Phase) :- tr_article_verb_noun(Words), !, member(Phase, [said, unsaid]).
tr_subject_phase(_, _, _, any).

tr_article_verb_noun([D, w(V, _)|_]) :-
    D = w(DW, _), tr_determiner(foreign, D, _, _), tr_object_pronoun(foreign, DW, _),
    tr_is(foreign, w(V, lower), noun),
    tr_form(V, L, _, _, _), atom(L), ( tr_class_of(L, verb) ; tr_class_of(L, modal) ; tr_class_of(L, auxiliary) ), !.
tr_phase_subject(said, Ws) :- Ws \== [].
tr_phase_subject(unsaid, []).
tr_phase_subject(any, _).

%% `there is': no subject of its own, and what there is as its first object
%% -- English's `there' and the copula, or `there will be'; the lesson's
%% verb that means `there is' (`hay'), which the question form may have
%% put after its phrase (`¿Hay un perro?' reads as `un perro hay')
tr_read_statement0(Side, Words0, none, S) :-
    tr_negation(Side, Words0, Words, Neg0),
    tr_existential(Side, Words, L, T, After, Neg0, Neg),
    nb_setval('$tr_read_group', L),
    %% what there is is a PHRASE, read as one first: `Hay otros servidos con
    %% caldos' is others-that-were-served, and the complement reader took
    %% `otros' for an object pronoun and left the participle stranded
    (   tr_phrase_words(Side, After, PW, Rest), PW \== [], tr_phrase_np(Side, PW, NP),
        tr_complements(Side, Rest, More)
    ->  Comps = [obj(NP)|More]
    ;   tr_complements(Side, After, Comps), Comps = [obj(_)|_]
    ), !,
    S = s(none, there, g(L, T, simple, Neg), Comps).
%% A PASSIVE PUTS ITS SUBJECT AFTER ITSELF: `Viene esclusa ogni forma di
%% eutanasia diretta o di "eutanasia genetica"', `Vanno invece attivate la
%% terapia palliativa e la terapia del dolore'. A passive has no object --
%% what would have been its object is its subject -- so the phrase after it
%% that agrees with it in number is that subject, with every phrase that
%% says which one, up to the clause's first comma. Read by the pro-drop
%% readings it was the object of a verb that has none, the subject was
%% `they' or nobody, and the participle agreed with nothing. Only with
%% nothing before the group, which is where a subject would otherwise
%% stand; and the subject's place travels as subj_here, so the lesson's
%% writer keeps the source's order and English's writes the subject first.
%% -- and after a relative word that a preposition governs, whose clause is
%% a whole statement: `nel quale sono previste ulteriori contribuzioni da
%% parte di Chrysler Group al Veba' has the contributions foreseen, and the
%% passive reader stood down for the `rel' such a clause is read with -- so
%% they were an object, nobody was the subject, and Spanish wrote `son
%% previstos adicionales contribuciones', the participle agreeing with nothing
tr_read_statement0(foreign, Words0, Asked, S) :-
    ( Asked == none ; Asked == rel ),
    tr_negation(foreign, Words0, Words, Neg),
    tr_group_from(foreign, Words, [], g(L, T, A, third, N), After0),
    memberchk(A, [passive, passive_perfect, duty]),
    nb_setval('$tr_read_group', L), nb_setval('$tr_read_aspect', A),
    tr_adverb_prefix(After0, Advs, After),                  % `Vanno INVECE attivate' put its adverb here
    (   append(SubjW, [comma|Rest0], After) -> Rest = [comma|Rest0] ; SubjW = After, Rest = [] ),
    SubjW \== [], \+ memberchk(comma, SubjW),
    tr_subject(foreign, none, SubjW, third, N, Subject), Subject \= null(_, _),
    tr_number_agrees(foreign, Subject, N),
    tr_complements(foreign, Rest, Comps0), !,
    findall(adv(X), member(X, Advs), AC), append(AC, [subj_here|Comps0], Comps),
    S = s(none, Subject, g(L, T, A, Neg), Comps).
%% A PASSIVE MADE WITH THE REFLEXIVE, AND A PLURAL VERB: `También se
%% incrementaron las ventas de minidisc, que superaron ...' -- the sales went
%% up, and the verb agrees with them. With a singular verb the word is the
%% impersonal one, `se prevé un mantenimiento', which every writer here
%% writes; with a plural one it cannot be, and the pro-drop readings made
%% `they' increase the sales. The phrase after the verb that agrees with it
%% is its subject, as a passive's is (above), and the group is the
%% reflexive's passive, g(reflexive(L), T, passive, Neg): English writes its
%% passive, the lesson's language its reflexive and the verb (fo_group/8),
%% in the source's order.
tr_read_statement0(foreign, Words0, none, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    %% the group the words make, and only then asked whether it is a simple
    %% one: asked for a simple group, `si sono adoperate 37 associazioni'
    %% offered the copula alone, and a subject was looked for in every
    %% reading of `adoperate 37 associazioni ...' -- 5.5 million inferences
    %% of Livata's longest sentence, before the perfect read it
    tr_group_from(foreign, Words, [w(R, _)], G, After), G = g(L, T, simple, third, plural),
    tr_reflexive_word(R), atom(L),
    nb_setval('$tr_read_group', L), nb_setval('$tr_read_aspect', simple),
    tr_after_nrc(After, AfterU, Wrap),
    tr_subject_after(AfterU, third, plural, Rest, Subject0), Subject0 \= null(_, _),
    tr_number_agrees(foreign, Subject0, plural),
    tr_wrap_nrc(Wrap, Subject0, Rest, Subject),
    tr_complements(foreign, Rest, Comps0), !,
    S = s(none, Subject, g(reflexive(L), T, passive, Neg), [subj_here|Comps0]).
tr_read_statement0(Side, Words0, Asked, S) :- tr_read_generic(Side, Words0, Asked, S), !.
tr_read_generic(Side, Words0, Asked, S) :-
    tr_negation(Side, Words0, Words, Neg),
    tr_subject_phase(Side, Asked, Words, Phase),
    tr_group_from(Side, Words, Before0, g(L, T, A, FP, FN), After),
    nb_setval('$tr_read_group', L),                           % for the complements: a bare base after a modal
    nb_setval('$tr_read_aspect', A),                          % and: a `by' phrase after a passive is its agent
    tr_insertion_off(Side, Before0, Before, Mids),            % `Cassisa, secondo l'accusa, avrebbe'
    tr_uncomma(Before, BeforeU),                              % the subject side is read without its commas
    \+ tr_names_parted(Side, Before),                         % ... but never two names a comma parts
    \+ tr_name_after_comma(Side, Before),                     % ... nor a word and the name after its comma
    tr_split_clitics(Side, BeforeU, Asked, FP, FN, SubjectWords, Clitics0),
    tr_phase_subject(Phase, SubjectWords),
    tr_reflexive_off(Side, Clitics0, Clitics, L, LV),
    tr_subject(Side, Asked, SubjectWords, FP, FN, Subject0),
    tr_person_agrees(Side, Subject0, FP), tr_number_agrees(Side, Subject0, FN), tr_impersonal_agrees(Subject0, FP, FN),
    %% A BARE NOUN IN THE SINGULAR IS NO SUBJECT WHERE IT IS A VERB'S FORM TOO.
    %% The lesson's languages put a determiner before a singular subject, and
    %% `En esta versión, además, cuenta con una June Anderson en plena forma'
    %% read `cuenta con ... en plena' as the subject, an account, and `forma'
    %% as its verb, it forms -- where `cuenta' is the verb, it counts on her
    \+ ( Side == foreign, tr_bare_singular(Subject0), SubjectWords = [w(F1, _)|_],
         tr_form(F1, L1, _, _, _), atom(L1), tr_class_of(L1, verb) ),
    %% A VERB THE LESSON CALLS REFLEXIVE TAKES `se' AS ITS OWN PRONOUN, never
    %% as the impersonal subject: `Se ha equivocado' is somebody erring, and
    %% `"equivoca" is reflexive.' says so; the subject is the one nobody named
    (   Subject0 == impersonal, LV == L, tr_solve(reflexive(L)), tr_reflexive_out(_)
    ->  Subject = null(FP, FN), LV1 = reflexive(L)
    ;   Subject = Subject0, LV1 = LV
    ),
    tr_si_perfect(LV1, Subject, A, A1),
    tr_complements(Side, After, Comps00),
    %% A BARE NAME STRAIGHT AFTER THE VERB IS ITS SUBJECT where the lesson
    %% puts a word before a person who is the object (`The word "a" precedes
    %% the person.'): `se permite Vick alguna pequeña ironía' is Vick allowing
    %% himself some irony, and read with `se' for the impersonal subject the
    %% director was an object, `si permette Vick'. Without the word before
    %% him he cannot be one; `se' is then his reflexive.
    tr_name_subject(Side, Subject, FP, FN, L, LV1, Comps00, Subject2, LV2, Comps0),
    %% a verb the lesson calls intransitive, with nobody named before it, has
    %% its subject after it and no object: `Godranno di qualche boccata ...
    %% soltanto quelli che ...' read here as THEY enjoying those who chose,
    %% and the readers below that find the subject after the verb never ran.
    %% The reading gives up at once, or it went on to every later word that
    %% could be a verb -- 7.7 million inferences against 0.3 for that one
    %% -- and so has a verb the lesson calls reflexive, with its reflexive
    %% pronoun before it (tr_takes_subject_after/3)
    (   Side == foreign, Subject2 = null(_, _), tr_takes_subject_after(L, LV2, Before), memberchk(obj(_), Comps0)
    ->  !, fail
    ;   true
    ),
    %% A TIME IS NO SUBJECT OF A VERB WITH AN OBJECT. `L'anno era lungo' is
    %% about the year, and a determiner is what makes a time phrase one
    %% (tr_subject_shape/4) -- but `Il giorno prima caricò i compagni' is the
    %% day before, when HE loaded the team-mates, and read with the day for
    %% the subject, the day loaded them. The fronted adjunct reads it.
    \+ ( Side == foreign, tr_time_phrase(Subject2), memberchk(obj(_), Comps0) ),
    tr_null_copula_agrees(Subject2, L, A1, Comps0), !,        % the cut once the WHOLE statement read: `house'
                                                              % is a verb's form, and `The house is big' must
                                                              % go on to the group at `is' when `is big' is no complement
    findall(opron(W), member(W, Clitics), Cs),
    append([Mids, Cs, Comps0], Comps),
    tr_existential_fix(Side, s(Asked, Subject2, g(LV2, T, A1, Neg), Comps), S).
tr_bare_singular(np(none, none, _, w(_, _), singular)).
tr_bare_singular(with(NP, _)) :- tr_bare_singular(NP).

%% A PHRASE BEFORE THE VERB THAT A PRONOUN BEFORE THE VERB TAKES UP AGAIN IS
%% THE VERB'S OBJECT, SET IN FRONT: `Io la risposta non ce l'ho' is I do not
%% have the answer -- the answer said first, and `l'' saying it again. Read
%% as the sentence's subject, `io la risposta' was nothing at all. The phrase
%% opens on a determiner, and the pronoun is a third person in the phrase's
%% number; it only doubles the phrase, as `lo' doubles `todo', and goes. Every
%% writer puts the object after its verb: what is lost is the emphasis, not
%% the claim, as a fronting's is. Tried when nothing else read.
%% -- THE PRONOUN IS LOOKED FOR BEFORE THE PHRASE. Every statement that did not
%% read reaches this clause, and with the phrases parsed first every clitic
%% run before every verb -- `si disse', `si tende', `si trasformano' -- paid
%% for a phrase at every determiner before it: 53 million inferences over six
%% sentences of the controls that have no dislocation at all.
tr_read_statement0(foreign, Words0, none, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    tr_dislocation_hint(Words),
    tr_group_from(foreign, Words, Before, g(L, T, A, FP, FN), After),
    \+ memberchk(comma, Before),
    append(Front, Clitics0, Before), Clitics0 = [_|_],
    forall(member(w(C, _), Clitics0), tr_clitic(none, C)),
    select(w(R, _), Clitics0, Clitics1), tr_resumptive(R, NN),
    append(SubjW, NPW, Front), NPW = [D|_], tr_determiner(foreign, D, _, _),
    tr_np(foreign, NPW, NP), fo_np_number(NP, NN), !,
    tr_subject(foreign, none, SubjW, FP, FN, Subject),
    nb_setval('$tr_read_group', L), nb_setval('$tr_read_aspect', A),
    tr_reflexive_off(foreign, Clitics1, Clitics, L, LV),
    tr_complements(foreign, After, Comps0), \+ memberchk(obj(_), Comps0),
    findall(opron(W), member(W, Clitics), Cs),
    append(Cs, [obj(NP)|Comps0], Comps),
    S = s(none, Subject, g(LV, T, A, Neg), Comps).

%% -- AND A VERB GROUP IS ASKED FOR ONLY WHERE ONE COULD CARRY THE PRONOUN.
%% What the clause needs is a pronoun with a determiner and no comma before
%% it and a group after it, perhaps past more clitics; that is one
%% tr_group_at/4 at each such place, where tr_group_from/5 asks at every
%% word. And the phrase ends where the clitics begin, so the word before
%% them must be one a phrase can end on: `... e l'isola di Ustica' has
%% `isola', he isolates, after `l'', and `una valigia e lo vide' a group
%% after `lo', and a phrase ending on `e' was parsed at every determiner
%% before it -- ten, thirteen and four million inferences on three
%% sentences of the controls that have no dislocation. Nor may the words
%% open on a preposition: what stands before the phrase is its subject or
%% nothing, and `Negli ambienti giudiziari si tende ad accreditare la tesi'
%% is neither, whatever `tesi' is.
tr_dislocation_hint(Words) :-
    Words = [W1|_], \+ tr_preposition_only(W1),
    append(Pre, [w(R, _)|Post], Words), tr_resumptive(R, _),
    \+ memberchk(comma, Pre),
    tr_clitics_back(Pre, Front), last(Front, Last), \+ tr_no_phrase_end(Last),
    member(D, Front), tr_determiner(foreign, D, _, _),
    tr_group_past_clitics(Post), !.
tr_group_past_clitics(Ws) :- tr_group_at(foreign, Ws, _, _), !.
tr_group_past_clitics([w(C, _)|Ws]) :- tr_clitic(none, C), tr_group_past_clitics(Ws).
tr_clitics_back(Ws, Front) :-
    append(Front0, [w(C, _)], Ws), tr_clitic(none, C), !, tr_clitics_back(Front0, Front).
tr_clitics_back(Ws, Ws).
%% a word no phrase ends on: a coordinator, or a conjunction or a
%% preposition the lesson calls nothing a phrase can end with
tr_no_phrase_end(W) :- W = w(_, _), tr_coord(foreign, W), !.
tr_no_phrase_end(W) :- W = w(_, _),
    ( tr_is(foreign, W, conjunction) ; tr_is(foreign, W, preposition) ),
    tr_nothing_else(W), !.
tr_preposition_only(W) :- W = w(_, _), tr_is(foreign, W, preposition), tr_nothing_else(W),
    \+ tr_determiner(foreign, W, _, _), !.
tr_nothing_else(W) :-
    \+ tr_is(foreign, W, noun), \+ tr_is(foreign, W, pronoun),
    \+ tr_is(foreign, W, adjective), \+ tr_is(foreign, W, number).

%% the pronoun that takes the phrase up again: a third person object, in the
%% phrase's number -- an elided one is `lo' and `la' alike
tr_resumptive(R, N) :-
    ( tr_solve(elision_of(R, F)) -> true ; F = R ),
    tr_object_pronoun(foreign, F, E), memberchk(E-N, [it-singular, him-singular, her-singular, them-plural]), !.

%% ... and the name stays where it stood, subj_here among the complements:
%% `son únicos", dijo Claude Lebet, uno de los luthiers' is a speaker after
%% his verb, and moved in front it came out `Claude Lebet disse'
tr_name_subject(Side, Subject, FP, FN, L, LV, [obj(name(N))|Comps], name(N), LV1, [subj_here|Comps]) :-
    Side == foreign, ( Subject == impersonal ; Subject = null(third, singular) ),
    FP == third, FN == singular, tr_solve(precede(_, person)), !,
    ( Subject == impersonal, LV == L -> LV1 = reflexive(L) ; LV1 = LV ).
tr_name_subject(_, Subject, _, _, _, LV, Comps, Subject, LV, Comps).

%% AN ASIDE BETWEEN THE SUBJECT AND ITS VERB: `Monsignor Cassisa, secondo
%% l'accusa, avrebbe intascato tangenti' -- adjuncts between two commas, the
%% second right before the verb group. Read with the commas taken out they
%% were a phrase of the subject's (`Monseñor Cassisa según la acusación
%% habría embolsado'); each travels as mid(C), and every writer puts it
%% back after the subject with its commas. Tried first and given up when
%% the rest will not read with it, so a subject that is a list with commas
%% reads as it did.
tr_insertion_off(Side, Before0, Before, Mids) :-
    append(Before, [comma|InsW], Before0), Before \== [], \+ last(Before, comma),
    append(InsW0, [comma], InsW), InsW0 \== [], \+ memberchk(comma, InsW0),
    %% ... opening on a preposition or on an adverb: `la Pace, ALMENO nelle
    %% piccole isole del Belpaese, arriva per decreto' lost its commas, the
    %% islands became the peace's and `almeno' went to the end
    InsW0 = [P|_], ( tr_is(Side, P, preposition) ; tr_plain_adverb(Side, P) ),
    tr_complements(Side, InsW0, Cs), Cs \== [], forall(member(X, Cs), tr_adjunct(X)),
    findall(mid(X), member(X, Cs), Mids).
%% ... AND ONE THE APPOSITION BEFORE IT OPENS: `su constructor, Joseph
%% Guarnerius del Gesù, de Cremona (Italia), está considerado' -- the comma
%% after the name closes the name and opens the place, and the apposition
%% took it (tr_list_commas/3). Read as the subject's `of' phrase, the place's
%% own closing comma was lost: `di Cremona (Italia) è considerato'.
tr_insertion_off(Side, Before0, Before, Mids) :-
    append(Before, InsW, Before0), Before = [_|_], last(Before, w(_, appos)),
    append(InsW0, [comma], InsW), InsW0 = [P|_], \+ memberchk(comma, InsW0),
    tr_is(Side, P, preposition),
    tr_complements(Side, InsW0, Cs), Cs \== [], forall(member(X, Cs), tr_adjunct(X)),
    findall(mid(X), member(X, Cs), Mids).
tr_insertion_off(_, Before, Before, []).

%% INVERSION: A FRONTED ADJUNCT PUTS THE SUBJECT AFTER THE VERB.
%% `Qui solo due anni fa dominava il coprifuoco' is the curfew dominating
%% and not somebody dominating the curfew -- and what says so is the
%% material BEFORE the verb: an adverb or a prepositional phrase, never a
%% subject. That is the condition the languages themselves use, and it is
%% why `Mangia il pane' STAYS REFUSED: nothing is fronted there, so nothing
%% says the phrase after the verb is anything but the object, and a third
%% person with no subject could be anybody.
%%
%% AND THE FRONTING IS NOT ENOUGH, which one probe settled: `Ieri mangiava
%% il pane' came out `The bread ate yesterday', because a fronted adjunct
%% makes inversion POSSIBLE and never certain -- Italian reads that one as
%% pro-drop with an object, and what tells the two apart is whether the
%% verb takes an object at all. Nothing in a lesson said so, so the lesson
%% says it now: `"domina" is intransitive.', the bare-property shape
%% `"leche" is feminine.' already has, and reason.pl did not move. A verb
%% no lesson calls intransitive keeps its refusal, which is the honest
%% half of the trade: a wrong reading is worse than none.
%%
%% The agreement is checked, because fo_subject_after/5 is the question
%% form's own finder: the verb and the phrase must agree in person and
%% number before the phrase is taken for the subject.
%%
%% THE FRONTING IS READ AND NOT WRITTEN BACK. The adjuncts become ordinary
%% complements, in their own order, and every writer puts them after the
%% verb -- so `Qui dominava il generale' comes back as `Il generale dominava
%% qui', which is the same sentence in the statement's own order. What is
%% lost is an emphasis, not a claim.
tr_read_statement0(foreign, Words0, Asked, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    tr_group_from(foreign, Words, Before, g(L, T, A, FP, FN), After),
    Before \== [],
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', A),
    tr_solve(intransitive(L)),
    %% (only adverbs and pronouns before the verb are the reader below's,
    %% which finds the subject with its commas and a noun's own infinitive:
    %% `Forse è venuto il momento ... di porsi la stessa domanda ..., e
    %% decidere se ...'. Read here, `il momento' was the subject and `di
    %% porsi' the verb's, so the moment came to ask)
    \+ tr_adverbs_and_clitics(Before),
    %% a front the source set off with a comma is written back in front, as
    %% a statement's is: `De la amplia gama de instrumentos ..., destaca un
    %% violín'
    (   append(Before1, [comma], Before)
    ->  tr_complements(foreign, Before1, Front0), Front0 \== [],
        forall(member(X, Front0), tr_adjunct(X)), findall(fr(X), member(X, Front0), Front)
    ;   tr_complements(foreign, Before, Front),
        Front \== [], forall(member(X, Front), tr_adjunct(X))
    ),
    tr_uncomma(After, AfterU),
    fo_subject_after(AfterU, FP, FN, SubjWords, Rest), SubjWords \== [],
    tr_subject(foreign, Asked, SubjWords, FP, FN, Subject),
    tr_complements(foreign, Rest, Back), !,
    append(Front, Back, Comps),
    S = s(Asked, Subject, g(L, T, A, Neg), Comps).

%% AN INTRANSITIVE VERB WITH ONLY ITS PRONOUNS BEFORE IT HAS ITS SUBJECT
%% AFTER IT. `le gusta el buen fútbol' is the good football pleasing him, and
%% `Dominava il generale' the general dominating: a verb the lesson calls
%% intransitive takes no object, so the phrase after it that agrees with it
%% can only be what it says something of. Nothing in front is needed for
%% that, where the inversion above needs a front to make a verb the lesson
%% says NOTHING about read that way. The subject's place travels as
%% subj_here, so the lesson's writer keeps `gli piace il buon calcio' and
%% English's writes `The good football pleases him'.
tr_read_statement0(foreign, Words0, none, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    tr_group_from(foreign, Words, Before, g(L, T, A0, FP, FN), After),
    tr_takes_subject_after(L, none, Before),
    tr_uncomma(Before, BeforeU0),
    %% ... and adverbs before them, which are the clause's: `Forse è venuto
    %% il momento di porsi la stessa domanda' is the moment to ask it having
    %% come, perhaps
    tr_front_adverbs(BeforeU0, Advs, BeforeU),
    tr_split_clitics(foreign, BeforeU, unsaid(none), FP, FN, [], Clitics0),
    tr_reflexive_off(foreign, Clitics0, Clitics, L, LV),
    %% (the reflexive's perfect is made with the copula: `si è stretto' is no
    %% passive, as tr_read_generic/4 already says)
    tr_si_perfect(LV, none, A0, A),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', A),
    tr_after_nrc(After, AfterU, Wrap),
    %% A COMMA AND A COORDINATOR END AN INVERTED SUBJECT, and what follows
    %% them is the clause's: `È venuto il momento di porsi la stessa domanda
    %% che gli stati si posero ..., e decidere se ...'. Read with the commas
    %% out first, every length of subject read the relative clause again
    %% with the rest of the sentence in it -- 123 million inferences for
    %% that one, where the subject up to the comma is found at once
    (   Wrap == none, append(Zone, [comma, Co|Tail], After), Co = w(_, _), tr_coord(foreign, Co), Zone \== [],
        tr_uncomma(Zone, ZoneU),
        tr_subject_after(ZoneU, FP, FN, Rest1, Subject), Subject \= null(_, _),
        append(Rest1, [comma, Co|Tail], RestC1), tr_complements(foreign, RestC1, Back)
    ->  true
    ;   tr_subject_after(AfterU, FP, FN, Rest, Subject0), Subject0 \= null(_, _),
        tr_wrap_nrc(Wrap, Subject0, Rest, Subject),
        %% what follows the subject is read with the commas the source set
        (   Wrap == none, Rest \== [], tr_rest_commas(After, AfterU, Rest, RestC),
            tr_complements(foreign, RestC, Back0)
        ->  Back = Back0
        ;   tr_complements(foreign, Rest, Back)
        )
    ->  true
    %% ... and a subject that ends at a comma is looked for before it:
    %% `Regolamenta il ministro, ma senza penalizzare il vivere civile' read
    %% with its commas out ran `il ministro ma' on as one phrase, no subject
    %% read, and the imperative took the sentence -- regulate the minister
    ;   Wrap == none, append(Zone, [comma|Tail], After), Zone \== [], \+ memberchk(comma, Zone),
        tr_subject_after(Zone, FP, FN, Rest1, Subject), Subject \= null(_, _),
        append(Rest1, [comma|Tail], RestC), tr_complements(foreign, RestC, Back)
    ), !,
    findall(opron(W), member(W, Clitics), Cs),
    %% the adverbs stood in front and are written back there, where both
    %% languages and English put them: `Quizás ha venido el momento',
    %% `Perhaps the moment has come' -- written after the verb, it was `Ha
    %% venido quizás el momento', and `Qui dominava il generale' `Dominava
    %% qui il generale', which is neither the source's order nor a statement's
    findall(frn(adv(X)), member(X, Advs), AC),
    append([AC, Cs, [subj_here|Back]], Comps),
    S = s(none, Subject, g(LV, T, A, Neg), Comps).

%% A VERB THAT TAKES NO OBJECT: one the lesson calls intransitive, or one it
%% calls REFLEXIVE with its reflexive pronoun before it -- `Mi si è stretto il
%% cuore leggendo ...' is my heart tightening, `stringersi' being `stringere'
%% with nothing to tighten but itself, and `mi' who it happens to. Read with
%% nobody named for the subject, the heart was the verb's object: somebody
%% tightening it (`"stringe" is reflexive.', the shape `"equivoca" is
%% reflexive.' has)
%% (LV is the lexeme the reader already took the pronoun off, or `none' where
%% it has not yet: given unbound, `LV = reflexive(_)' held for every verb the
%% lesson calls reflexive, `si' or not, and `ha sbagliato strada' went through
%% the reader below on Livata's fifteenth sentence -- 3.8 million inferences
%% of 14.9)
tr_takes_subject_after(L, _, _) :- tr_solve(intransitive(L)), !.
tr_takes_subject_after(L, LV, Before) :-
    atom(L), tr_solve(reflexive(L)),
    ( LV = reflexive(_) -> true ; member(w(R, _), Before), tr_reflexive_word(R) ), !.

%% the plain adverbs at the head of the words before a verb, and the rest
tr_front_adverbs([W|Ws], [W|As], Rest) :- W = w(_, _), tr_plain_adverb(foreign, W), \+ tr_clitic(none, W), !,
    tr_front_adverbs(Ws, As, Rest).
tr_front_adverbs(Ws, [], Ws).

tr_adverbs_and_clitics(Before) :-
    tr_uncomma(Before, BU), tr_front_adverbs(BU, [_|_], Rest),
    forall(member(X, Rest), ( X = w(C, _), tr_clitic(none, C) )), !.

%% the words of After past the ones a reading of AfterU -- After with its
%% commas out -- took before Rest, with their commas kept
tr_rest_commas(After, AfterU, Rest, RestC) :-
    length(AfterU, NA), length(Rest, NR), K is NA - NR,
    tr_skip_words(After, K, RestC), RestC \== Rest.
tr_skip_words(Ws, 0, Ws) :- !.
tr_skip_words([comma|Ws], K, R) :- !, tr_skip_words(Ws, K, R).
tr_skip_words([_|Ws], K, R) :- K1 is K - 1, tr_skip_words(Ws, K1, R).

%% A RELATIVE CLAUSE AFTER A COMMA AT THE END OF AN INVERTED SUBJECT IS THE
%% SUBJECT'S: `si bien destaca el fuerte aumento experimentado por las ventas
%% de sencillos, que en 1999 absorbieron casi el 4% del mercado total'. The
%% words after the verb lost their commas before the subject was looked for,
%% so the clause ran on into the subject and no subject read; the verb was
%% then read with an object -- `evidenzia il forte aumento', highlights it --
%% where the lesson says it is the increase that stands out. The clause is
%% read on its own and hangs on the subject as it hangs on any phrase before
%% a comma (tr_phrase_nrc/3), and nothing may follow the subject but it.
tr_after_nrc(After, AfterU, nrc(Role, RS)) :-
    append(SW, [comma, w(RW, RC)|R1], After), \+ memberchk(comma, SW), SW \== [],
    tr_relative_word(foreign, RW),
    tr_relative_clause(foreign, [w(RW, RC)|R1], Role, RS), !,
    tr_uncomma(SW, AfterU).
tr_after_nrc(After, AfterU, none) :- tr_uncomma(After, AfterU).

tr_wrap_nrc(none, S, _, S) :- !.
%% ... on the last phrase of a subject that carries phrases (`las ventas DE
%% MINIDISC, que ...'), which is what with/2 is and no phrase is
tr_wrap_nrc(nrc(Role, RS), with(NP, PPs0), [], with(NP, PPs)) :-
    append(Pre, [pp(P, NP2)], PPs0), !, append(Pre, [pp(P, nrc(NP2, Role, RS))], PPs).
tr_wrap_nrc(nrc(Role, RS), S0, [], nrc(S0, Role, RS)) :- S0 \= with(_, _).

%% ... AND WITH ITS ADJUNCTS BEFORE THE SUBJECT, OR A MODAL BEFORE IT.
%% `Palermo - deve finire in tribunale l'arcivescovo di Monreale' is the
%% archbishop who must end up in court: the phrase after the verb's
%% adjuncts that agrees with it is the subject, read as an object it said
%% that somebody nobody named must finish him. A modal says nothing of an
%% object itself -- the infinitive after it does, and one the lesson calls
%% intransitive takes none, so the phrase is the modal's subject too. The
%% adjuncts stay where the source had them and the subject's place travels
%% as subj_here, so the lesson's writer keeps the order and English's puts
%% the subject first. Tried after the clause above, so a subject right
%% after its verb reads as it did.
tr_read_statement0(foreign, Words0, none, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    tr_group_from(foreign, Words, Before, g(L, T, A, FP, FN), After),
    tr_uncomma(Before, BeforeU),
    tr_split_clitics(foreign, BeforeU, unsaid(none), FP, FN, [], Clitics0),
    (   tr_solve(intransitive(L))
    ->  After1 = After, Inf = []
    ;   atom(L), tr_class_of(L, modal), After = [w(IW, _)|After1],
        tr_solve(infinitive_of(IW, IL)), tr_solve(intransitive(IL))
    ->  Inf = [inf(IL)]
    ),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', A),
    tr_reflexive_off(foreign, Clitics0, Clitics, L, LV),
    tr_uncomma(After1, AfterU),
    %% the words with the source's commas first, when the phrases before the
    %% subject have none: `... soltanto quelli che ... si chiamano Giglio,
    %% Eolie, Ustica, ...' read without them ran the names together
    (   memberchk(comma, After1), AfterW = After1 ; AfterW = AfterU ),
    append(Mid, SubjStart, AfterW), SubjStart \== [], \+ memberchk(comma, Mid),
    ( Inf == [] -> Mid \== [] ; true ),
    tr_complements(foreign, Mid, MidComps), forall(member(X, MidComps), tr_adjunct(X)),
    tr_subject_after(SubjStart, FP, FN, Rest, Subject), Subject \= null(_, _),
    tr_complements(foreign, Rest, Back), !,
    findall(opron(W), member(W, Clitics), Cs),
    append([Cs, Inf, MidComps, [subj_here|Back]], Comps),
    S = s(none, Subject, g(LV, T, A, Neg), Comps).

%% THE SUBJECT AFTER AN INTRANSITIVE VERB TAKES THE PHRASES THAT SAY WHICH
%% ONE: `l'arcivescovo di Monreale monsignor Salvatore Cassisa' is one
%% subject, and the finder of a question's subject ended it at `di' -- the
%% place and the person were then the verb's, an object among them. Only a
%% `di' phrase and a title with its name go with it, the longest run that
%% reads; anything else after the subject stays the verb's, as it was.
%% A SUBJECT WITH ITS RELATIVE CLAUSE TAKES THE REST OF THE WORDS: `Godranno
%% ... soltanto quelli che hanno scelto di trascorrere le proprie ferie ...'
%% is those who chose, and the finder ended the subject at `quelli' and read
%% `che hanno scelto' as a `that' clause of the verb's
tr_subject_after(Words, third, FN, [], Subject) :-
    once(( member(w(RW, _), Words), tr_relative_word(foreign, RW) )),
    %% (a phrase, so never a preposition or an adverb first: the reader
    %% above offers every place the subject could start, and each read the
    %% relative clause again before the head failed)
    Words = [W1|_], W1 = w(_, _), \+ tr_is(foreign, W1, preposition), \+ tr_plain_adverb(foreign, W1),
    tr_np(foreign, Words, Subject), Subject = rc(Head, _, _),
    tr_rc_head_number(Head, FN), !.
tr_subject_after(Words, FP, FN, Rest, Subject) :-
    FP == third, length(Words, Len), Len >= 3,
    Words = [W1|_], W1 = w(_, _), \+ tr_is(foreign, W1, preposition), \+ tr_plain_adverb(foreign, W1),
    between(3, Len, K0), K is Len + 3 - K0,
    length(SW, K), append(SW, Rest, Words),
    tr_subject(foreign, none, SW, FP, FN, Subject), Subject = with(_, PPs),
    %% ... and two `di' phrases joined: `Firma il responsabile dell'ambiente E
    %% DEI LAVORI PUBBLICI, Paolo Baratta' is the minister of both, and the
    %% subject ended at the first, the second and the name left to the verb
    %% ... and an infinitive the noun's `di' governs, with its object: `è
    %% venuto il momento DI PORSI LA STESSA DOMANDA'
    tr_subject_after_pps(PPs),
    \+ last(PPs, cnj(_)),
    tr_subject_number(Subject, N), N == FN, !.
tr_subject_after(Words, FP, FN, Rest, Subject) :-
    fo_subject_after(Words, FP, FN, SubjWords, Rest), SubjWords \== [],
    tr_subject(foreign, none, SubjWords, FP, FN, Subject).

tr_subject_after_pps([]).
tr_subject_after_pps([X|Xs]) :-
    (   X = pp(P, _), tr_means_of(foreign, P) -> Ys = Xs
    ;   X = pinf(P, _), tr_means_of(foreign, P) -> ( Xs = [obj(_)|Ys] -> true ; Ys = Xs )
    ;   X = nprep(P), tr_means_of(foreign, P), Xs = [infx(_, _, _)|Xs1] -> ( Xs1 = [obj(_)|Ys] -> true ; Ys = Xs1 )
    ;   ( X = appos(_) ; X = cnj(_) ) -> Ys = Xs
    ),
    tr_subject_after_pps(Ys).

tr_rc_head_number(pronoun(w(W, _)), N) :- !, tr_lexeme(foreign, W, _, N).
tr_rc_head_number(NP, N) :- fo_np_number(NP, N).

%% AN IMPERSONAL MODAL NAMES ITS SUBJECT BY WHAT IT IS. `Hay que tomar
%% precauciones' is one must take precautions: `hay que' has no subject and
%% could have none, and read as a verb nobody named it said `he must'. The
%% lesson says what it is -- `The impersonal modal "hay que" means "must".'
%% -- and the IR carries the impersonal subject a `se debe' or a `si deve'
%% carries, so every writer has one: `Bisogna prendere precauzioni', `One
%% must take precautions'.
tr_read_statement0(foreign, Words0, none, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    tr_group_from(foreign, Words, Before, g(L, T, A, third, singular), After),
    atom(L), tr_solve(impersonal(L)), tr_class_of(L, modal),
    tr_uncomma(Before, BeforeU),
    tr_split_clitics(foreign, BeforeU, unsaid(none), third, singular, [], Clitics),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', A),
    tr_complements(foreign, After, Comps0), !,
    findall(opron(W), member(W, Clitics), Cs),
    append(Cs, Comps0, Comps),
    S = s(none, impersonal, g(L, T, A, Neg), Comps).

%% A CLEFT: `A chiederlo è la procura di Palermo' is the prosecution asking
%% for it. Italian puts what is done first -- the word the lesson says
%% begins the cleft (`The word "a" begins the cleft.'), the infinitive and
%% the pronouns joined to it -- then the copula, and who does it last. It
%% reads as the statement it makes, in the copula's tense, with the
%% subject's place kept after the verb as subj_here: Spanish writes `Lo pide
%% la fiscalía de Palermo', and English's writer puts the subject first.
%% The words after the copula are read WITH their commas, as complements
%% are, and the subject is built from them: read as a subject side they
%% lost the commas of the list inside the relative clause (`accuse di
%% concussione, corruzione, falso ideologico e truffa').
tr_read_statement0(foreign, Words0, none, S) :-
    Words0 = [w(CW, _), w(IW, _)|Ws1], tr_solve(begin(CW, cleft)),
    tr_solve(infinitive_of(IW, L)), tr_known(foreign, L),
    append(Cls0, [w(Cop, CC)|SubjWords], Ws1), SubjWords \== [],
    forall(member(X, Cls0), X = w(_, enclitic)),
    tr_group_from(foreign, [w(Cop, CC)], [], g(CL, T, simple, third, N), []), tr_copula_lexeme(CL),
    nb_setval('$tr_read_group', L), nb_setval('$tr_read_aspect', simple),
    tr_complements(foreign, SubjWords, [obj(NP)|More]),
    ( More == [] -> Subject = NP ; tr_subject_comps(More), Subject = with(NP, More) ),
    tr_number_agrees(foreign, Subject, N), !,
    findall(opron(w(C, lower)), member(w(C, _), Cls0), Cs),
    append(Cs, [subj_here], Comps),
    S = s(none, Subject, g(L, T, simple, no), Comps).

%% A HEADLINE LEAVES THE COPULA OUT, AND IT IS NOT A FRAGMENT.
%% `Evacuata la Tate Gallery.' is `La Tate Gallery e stata evacuata' with
%% the copula dropped, which is what a headline does -- so it reads as the
%% PASSIVE it is, a participle at the head with the subject after it, and
%% the IR carries an ordinary statement. There is no fragment in the
%% grammar and this shape needed none.
%%
%% The participle agrees with the subject, and only its NUMBER is asked
%% for here: the gender says the same thing the subject's noun already
%% says, and fo_subject_after/5 checks the number as it checks a
%% question's.
%% ... THE PARTICIPLE'S OWN NUMBER, which the lesson states (`"processate"
%% is the plural of "processata".'): the number was taken from the phrase
%% alone, so `"processate il vescovo"' -- a plural feminine participle
%% before a masculine singular -- read as `the bishop has been processed'.
%%
%% THE COPULA IS WRITTEN BACK. A headline read this way comes out as the
%% full sentence in every language -- `La casa e stata evacuata', `The
%% house has been evacuated' -- because the IR carries the claim and not
%% the typography. What is lost is a headline's shape, not its meaning.
tr_read_statement0(foreign, Words0, none, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    Words = [w(P, _)|After], After \== [],
    tr_participle_here(foreign, P, L),
    tr_participle_number(P, N),
    tr_uncomma(After, AfterU),
    fo_subject_after(AfterU, third, N, SubjWords, Rest), SubjWords \== [],
    tr_subject(foreign, none, SubjWords, third, N, Subject),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', passive_perfect),
    tr_complements(foreign, Rest, Comps), !,
    S = s(none, Subject, g(L, present, passive_perfect, Neg), Comps).

%% A GERUND HEADS A CLAUSE OF ITS OWN, AND ITS SUBJECT IS THE ONE BEFORE
%% IT. `..., escludendo che il militare voleva ...' is `..., excluding that
%% the soldier wanted ...': a clause with a verb, no subject and no
%% auxiliary, which the join of 1.6.1 already knows how to hang off the
%% clause before it. The aspect carries it -- g(L, present, gerund, Neg) --
%% and the subject is `none', the one subject term the writers had no
%% clause for until now.
tr_read_statement0(Side, Words0, none, S) :-
    tr_negation(Side, Words0, Words, Neg),
    Words = [w(G, _)|Rest], Rest \== [],
    tr_gerund_here(Side, G, L),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', gerund),
    tr_complements(Side, Rest, Comps), !,
    S = s(none, none, g(L, present, gerund, Neg), Comps).

%% AN IMPERATIVE HAS NO SUBJECT AND NAMES ONE ANYWAY -- the person spoken
%% to -- so the aspect carries it and the subject is `none', beside the
%% gerund above. `Come el pan.', `No comas el pan.', `Mangia il pane.',
%% `Eat the bread.', `Do not eat the bread.'
%%
%% IT IS TRIED LAST, WHICH IS WHAT MAKES IT A STRICT ADDITION. A bare
%% third person with nothing in front of it was REFUSED -- 1.6.0's rule,
%% `Estaba cansado' could be anybody -- so every sentence that read before
%% reads by the same clauses, and what changes is only what used to refuse.
%%
%% AND ONLY A FORM THE LESSON CALLS AN IMPERATIVE READS AS ONE, which is
%% what keeps the two refusals apart. `come' is the imperative of `come'
%% and the third person of it besides, so `Come el pan.' is read; `comia'
%% is neither, so `Comia el pan.' keeps its refusal exactly as before. The
%% cost is the other half of that: where the two forms are spelled the
%% same the sentence is genuinely ambiguous and the imperative is the
%% reading taken, because it is the one that names its subject.
%%
%% A PRONOUN BEFORE IT MEANS IT WAS DENIED. Both languages join the pronouns
%% to an AFFIRMATIVE imperative -- `dame', `cómelo', `mangialo' -- and put
%% them before only a denied one, `no lo comas', `non lo mangiare'. So `Le
%% gusta el pan' and `Nos espera un mes' are statements about somebody
%% nobody named, where they had read as commands.
tr_read_statement0(foreign, Words0, none, S) :-
    \+ tr_global('$tr_no_command', yes),
    tr_negation(foreign, Words0, Words, Neg),
    append(Clitics0, [w(V, VC)|Rest], Words), \+ memberchk(comma, Clitics0), VC \== upper,
    ( Neg == no -> Clitics0 == [] ; true ),
    tr_imperative_here(foreign, Neg, V, F),
    tr_imperative_number(F, L, Subject),
    forall(member(w(C, _), Clitics0), tr_clitic(none, C)),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', imperative),
    tr_reflexive_off(foreign, Clitics0, Clitics, L, LV),
    tr_complements(foreign, Rest, Comps0), !,
    findall(opron(W), member(W, Clitics), Cs),
    append(Cs, Comps0, Comps),
    S = s(none, Subject, g(LV, present, imperative, Neg), Comps).
%% A THIRD PERSON SINGULAR WITH NOTHING BEFORE IT BUT CLITICS, READ LAST.
%% `Es la hora del caldo', `Se ha equivocado', `¿Cómo ha podido salir así?':
%% the lesson's languages leave out a subject the verb and the page before
%% it already say, and 1.6.0 refused every such sentence because nothing in
%% it says WHO -- `Estaba cansado' could be anybody. That is true and it is
%% a fact about ENGLISH, which must name a subject. Spanish and Italian need
%% not, so the reading is taken and the IR carries null(third, singular):
%% the lesson's writer leaves the subject out exactly as the source did, and
%% English's writer REFUSES it rather than guess he, she or it.
%%
%% IT IS TRIED AFTER THE IMPERATIVE, which is what keeps `Come el pan.' the
%% command it was; and after every other statement shape above, so a
%% sentence that read before reads by the same clause. What it changes is
%% only what used to refuse -- including a verb before its subject that no
%% lesson calls intransitive (`Dominava il generale.'), which now reads as a
%% null subject with an OBJECT, the plain Romance reading of those words.
tr_read_statement0(foreign, Words0, Asked, S) :-
    Asked \= subject(_),
    tr_negation(foreign, Words0, Words, Neg),
    tr_group_from(foreign, Words, Before, g(L, T, A, third, singular), After),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', A),
    tr_uncomma(Before, BeforeU),
    tr_split_clitics(foreign, BeforeU, unsaid(Asked), third, singular, [], Clitics0),
    tr_reflexive_off(foreign, Clitics0, Clitics, L, LV),
    tr_si_perfect(LV, null(third, singular), A, A1),
    tr_complements(foreign, After, Comps00), !,
    %% (and a bare name after the verb is its subject, as tr_read_generic/4 says)
    tr_name_subject(foreign, null(third, singular), third, singular, L, LV, Comps00, Subject, LV1, Comps0),
    findall(opron(W), member(W, Clitics), Cs),
    append(Cs, Comps0, Comps),
    S = s(Asked, Subject, g(LV1, T, A1, Neg), Comps).
%% English's is the BASE FORM, and its denial keeps the `do' the negation
%% took the `not' out of: `Do not eat the bread.'
tr_read_statement0(english, Words0, none, S) :-
    tr_negation(english, Words0, W1, Neg),
    ( Neg == yes, W1 = [w(do, _)|W2] -> true ; W2 = W1 ),
    W2 = [w(V, _)|Rest],
    tr_imperative_here(english, Neg, V, L),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', imperative),
    tr_complements(english, Rest, Comps), !,
    S = s(none, none, g(L, present, imperative, Neg), Comps).

%% the imperative of a verb the lesson gives: the form it states, and a
%% DENIED sentence wants the form it states for one -- Spanish's negative
%% imperative is not its affirmative (`come' against `no comas') and
%% Italian's is the infinitive (`non mangiare'), neither of which this
%% knows or needs to: the lesson says which form is which.
%% ... and never a word the lesson calls a preposition: `di' is what `dire'
%% says to one person and the `of' of every other sentence, and `Grazie
%% all'Arma dei carabinieri' came out `Say to the carabineers'
tr_imperative_here(foreign, _, V, _) :- tr_is(foreign, w(V, lower), preposition), !, fail.
tr_imperative_here(foreign, no, V, L) :-
    tr_solve(imperative_of(V, L)), \+ tr_holds(negative(V)), tr_imperative_known(L), !.
tr_imperative_here(foreign, yes, V, L) :-
    tr_solve(imperative_of(V, L)), tr_holds(negative(V)), tr_imperative_known(L), !.
%% ... and a PLURAL whose language states no denial of its own is denied
%% with itself: Italian's `non processate' (tr_imperative_plural_denied/2)
tr_imperative_here(foreign, yes, V, L) :-
    tr_solve(imperative_of(V, L)), tr_imperative_plural_denied(V, L), tr_imperative_known(L), !.
tr_imperative_here(english, _, V, L) :- en_verb_form(V, L, present), !.

%% THE PLURAL IMPERATIVE IS STATED OF THE PLURAL FORM -- `"processate" is
%% the imperative of "processano".', as the past of a plural is -- so the
%% form it is stated of says the number, and the plural's subject is the
%% people spoken to, addressee(plural). The singular keeps `none', the
%% subject it has had since 1.6.10. `"processate il vescovo".' is a
%% headline's command, `"procesad al obispo".', and with no plural stated
%% it read as a passive whose participle agreed with nothing.
tr_imperative_number(F, L, addressee(plural)) :- tr_solve(plural_of(F, L)), !.
tr_imperative_number(L, L, none).

%% the form an imperative is stated of is the lesson's verb: the lexeme,
%% or the plural of one (a plural form has no meaning of its own)
tr_imperative_known(F) :- tr_known(foreign, F), !.
tr_imperative_known(F) :- tr_solve(plural_of(F, L)), tr_known(foreign, L), !.

%% a plural imperative is its own denial where the lesson states none for
%% its form: Spanish says `no comáis', Italian `non processate'. Only the
%% PLURAL: a singular with no denial stated is the third person it is
%% spelled like, `Non mangia il pane', he does not eat the bread.
tr_imperative_plural_denied(V, F) :-
    \+ tr_holds(negative(V)), tr_solve(plural_of(F, _)),
    \+ ( tr_solve(imperative_of(V2, F)), tr_holds(negative(V2)) ).

%% and the form out, for either
tr_imperative_form(L, no, F) :-
    once(( tr_solve(imperative_of(F0, L)), \+ tr_holds(negative(F0)) )), F = F0.
tr_imperative_form(L, yes, F) :-
    once(( tr_solve(imperative_of(F0, L)), tr_holds(negative(F0)) )), F = F0.
%% ... in the number the subject says: the plural's is stated of the plural
%% form, and its denial is the affirmative where the lesson states none
tr_imperative_form(L, singular, Neg, F) :- !, tr_imperative_form(L, Neg, F).
tr_imperative_form(L, plural, Neg, F) :-
    once(tr_solve(plural_of(Pl, L))),
    (   tr_imperative_form(Pl, Neg, F) -> true
    ;   Neg == yes, tr_imperative_form(Pl, no, F), tr_imperative_plural_denied(F, Pl)
    ).

%% a gerund of a verb the lesson gives, on either side
tr_gerund_here(foreign, G, L) :- tr_solve(gerund_of(G, L)), tr_known(foreign, L), !.
tr_gerund_here(english, G, L) :- en_gerund(G, L), !.

%% the word a lesson gives for `that' before a clause: English's own, and
%% a conjunction of the lesson's that means it
tr_that_here(english, w(that, _)) :- !.
tr_that_here(foreign, w(W, _)) :-
    tr_lexeme(foreign, W, L, _), tr_class_of(L, conjunction), tr_solve(mean(L, that)), !.

%% how, where, when and why: the words that open an indirect question
tr_indirect_word(english, W, W) :- memberchk(W, [how, where, when, why]), !.
tr_indirect_word(foreign, W, Q) :-
    tr_lexeme(foreign, W, L, _), tr_solve(mean(L, Q)), memberchk(Q, [how, where, when, why]), !.

tr_if_word(W) :- tr_lexeme(foreign, W, L, _), tr_solve(mean(L, if)), tr_class_of(L, conjunction), !.

tr_that_word(english, that) :- !.
tr_that_word(foreign, W) :- once(( tr_solve(mean(L, that)), tr_class_of(L, conjunction), W = L )).

%% the complements of a front are adjuncts -- and an infinitive's own
%% object after it: `En su afán por esconder sus planes, ...' hides the
%% plans, and the front was refused for an object in it
tr_adjuncts([]).
tr_adjuncts([X|Xs]) :- tr_adjunct(X), tr_adjuncts_after(X, Xs).
tr_adjuncts_after(pinf(_, _), [obj(_)|Xs]) :- !, tr_adjuncts(Xs).
tr_adjuncts_after(_, Xs) :- tr_adjuncts(Xs).

%% what may stand before an inverted verb: an adjunct, never an object
tr_adjunct(sep).
tr_adjunct(adv(_)).
tr_adjunct(pp(_, _)).
tr_adjunct(at_time(_)).
tr_adjunct(pinf(_, _)).                               % `invece di andare da una parte, ...'
tr_adjunct(cnj(_)).                                   % `nella vita di ogni grande organizzazione E delle sue persone'
tr_adjunct(upon(_, _)).                               % `Al abrir la segunda audiencia pública ..., su presidente sostuvo'

tr_existential(english, [w(there, _), w(C, _)|After0], 'there is', T, After, Neg0, Neg) :-
    en_copula(C, third, _, T), tr_existential_no(After0, After, Neg0, Neg).
tr_existential(english, [w(there, _), w(will, _), w(be, _)|After0], 'there is', future, After, Neg0, Neg) :-
    tr_existential_no(After0, After, Neg0, Neg).
tr_existential(foreign, [w(V, _)|After], L, T, After, Neg, Neg) :-
    tr_form(V, L, _, T, third), tr_solve(mean(L, 'there is')).

%% `there is no dog': the denial as a determiner
tr_existential_no([w(no, _)|After], After, _, yes) :- !.
tr_existential_no(After, After, Neg, Neg).

%% the phrase a fronted `hay' took for its subject is what there is
tr_existential_fix(foreign, s(Asked, Subject, g(L, T, simple, Neg), Comps), s(Asked, there, g(L, T, simple, Neg), [obj(Subject)|Comps])) :-
    Subject = np(_, _, _, _, _), tr_solve(mean(L, 'there is')), !.
tr_existential_fix(_, S, S).

%% English's `not' wherever it stands, and `cannot' as `can' denied; the
%% lesson's word for `not' wherever it stands
tr_negation(english, Words, Rest, yes) :- append(A, [w(cannot, C)|B], Words), !, append(A, [w(can, C)|B], Rest).
tr_negation(english, Words, Rest, yes) :- append(A, [w(not, _)|B], Words), !, append(A, B, Rest).
%% ... and not a denial that stands before an INFINITIVE after the head of
%% the sentence: `è facile NON ritrovarsi più' denies the getting lost, and
%% taken as the sentence's it said `it is not easy' -- the opposite claim.
%% The complement reader reads it where it stands (neg/1). At the head it is
%% still the sentence's: `Non mangiare il pane' is the negative imperative.
%% NOR A DENIAL INSIDE A CLAUSE THAT STARTED BEFORE IT: `stanno valutando le
%% loro condizioni, che NON destano preoccupazione' denies the concern, and
%% taken as the sentence's it said the doctors were not assessing. A relative
%% word, a `che', a question word or a connecting word before the denial
%% opens a clause of its own, which reads its own denial when its turn comes.
%% -- UNLESS THAT CLAUSE HAS HAD ITS VERB: `el grupo de jugadores que
%% deberán resolver este ingrato compromiso NO figuran ...' is finished at
%% `compromiso', and the denial is the verb's after it; given to the
%% relative clause it said the players must not solve it. A verb form the
%% lesson calls no noun, between the clause's first word and the denial, is
%% that verb.
tr_negation(foreign, Words, Rest, yes) :-
    append(A, [w(N, _)|B], Words), tr_solve(mean(N, not)),
    \+ ( A \== [], tr_starts_infinitive(foreign, B) ),
    \+ ( append(_, [w(X, XC)|Between], A), tr_opens_clause(w(X, XC)),
         \+ ( member(w(V, _), Between), tr_verb_form_word(V) ) ), !,
    append(A, B, Rest).
tr_negation(_, Words, Words, no).

tr_negation_word(N) :- once(tr_solve(mean(N, not))).

tr_opens_clause(w(X, _)) :- tr_relative_word(foreign, X), !.
tr_opens_clause(W) :- tr_that_here(foreign, W), !.
tr_opens_clause(w(X, _)) :- tr_indirect_word(foreign, X, _), !.
%% ... but not a COORDINATOR, which joins two phrases of one subject as
%% often as two clauses: `La sua identità E la sua nazionalità non sono
%% state accertate' denies the one verb there is, and with `e' taken for a
%% clause's start the denial was left over and read as an adverb -- `han
%% sido verificados todavía no', the claim turned round. A second clause
%% after a coordinator is the division's to read (tr_read/4), where each
%% half reads its own denial; what the whole-statement reading can take
%% after one is only what tr_after_coord/2 admits -- an infinitive, a
%% preposition, a participle standing alone -- and the rule above keeps a
%% denial before an infinitive where it stands.
tr_opens_clause(w(X, C)) :- tr_connector(foreign, X), \+ tr_coord(foreign, w(X, C)), !.

%% object pronouns at the end of what stands before the verb (`Maria lo
%% ve'): the longest subject that has a subject's shape, the rest object
%% pronouns -- `Ellos la ven' is they and her, never nobody and them
tr_split_clitics(english, Before, _, _, _, Before, []) :- !.
tr_split_clitics(foreign, Before, Asked, P, N, Subject, Clitics) :-
    length(Before, Len), between(0, Len, K), length(Clitics, K),
    append(Subject, Clitics, Before),
    forall(member(w(C, _), Clitics), tr_clitic(Asked, C)),
    tr_subject_shape(Asked, Subject, P, N), !.

%% A REFLEXIVE PRONOUN BELONGS TO THE VERB, NOT TO THE SENTENCE. `si e
%% adeguata', `si sono appellati': the `si' is part of what the verb means,
%% not a thing the subject did it to -- so it comes OFF the clitics and the
%% lexeme is wrapped, `g(reflexive(L), T, A, Neg)'. It travels that way
%% because the reflexive is the VERB's property: a language with a reflexive
%% pronoun writes it back, and English, which has none there, drops it.
%%
%% THE COST IS A TRUE REFLEXIVE, AND IT IS STATED. `si lava' is `washes
%% himself' and comes out `washes'. Italian spells a lexical reflexive and a
%% true one the same way and nothing in a lesson tells them apart; the
%% lexical one is what newspaper prose is made of (`appellarsi', `adeguarsi',
%% `riferirsi'), so that is the reading taken, and the other is wrong.
%%
%% AND `si' IS THE IMPERSONAL WORD TOO, which needs no rule to separate: the
%% impersonal has NOTHING before the verb but itself and is read as the
%% subject, the reflexive has a subject of its own and is read here.
tr_reflexive_off(foreign, Cs0, Cs, L, reflexive(L)) :-
    select(w(R, _), Cs0, Cs), tr_reflexive_word(R), !.
tr_reflexive_off(_, Cs, Cs, L, L).

%% A SUBJECT NOBODY NAMED TAKES THE NUMBER OF WHAT THE COPULA SAYS IT IS:
%% `sono due eroi' is they -- `sono' is also I, and read first it came out
%% `Soy dos héroes'. The phrase after the copula agrees with the subject, so
%% its number decides between the verb's two readings.
tr_null_copula_agrees(null(_, N), L, A, [obj(NP)|_]) :-
    memberchk(A, [simple, perfect]), atom(L), tr_copula_lexeme(L), fo_np_number(NP, NN), !, NN == N.
tr_null_copula_agrees(_, _, _, _).

%% A PHRASE IS A THIRD PERSON. The subject reader took the verb's person on
%% trust, so `Monte Livata, ritrovati vivi donna' read `vivi' -- you live --
%% as the verb of `Monte Livata retrieved', and the headline came out as a
%% mountain living. A name, a phrase and everything built on one takes a
%% verb in the third person; a pronoun, two joined and nobody say their own.
%% The LESSON's side only: English's `are' is you, we and they alike, and
%% its reader gives the one reading `second' -- `The houses are big' would
%% be refused.
tr_person_agrees(foreign, S, P) :- tr_phrase_subject(S), !, P == third.
tr_person_agrees(_, _, _).

%% A COMMA BETWEEN TWO NAMES PARTS THEM. The subject side is read without
%% its commas, and a run of capitalised words is one name -- so `Salvo la
%% concesión de Rivaldo y Overmars, Serra Ferrer no quiere correr riesgos'
%% gave the coach's name the player's in front of it, `Overmars Serra
%% Ferrer', and `Salvo' was a verb, I save. A list's commas and an
%% apposition's are words of their own by now (tr_list_commas/3), so a
%% bare comma between two names is where a front ends.
%% ... and a capitalised NOUN after the comma is a name there too, since a
%% name goes on through one (tr_np/3, `Javier Solana'): read with its commas
%% out, `Juan, Pedro, Casa, María y Ana duermen' had `Pedro Casa María' for
%% one name
tr_names_parted(Side, Words) :-
    append(_, [W1, comma, W2|_], Words), W1 = w(_, upper), W2 = w(_, upper),
    tr_name_word(Side, W1), ( tr_name_word(Side, W2) ; tr_is(Side, W2, noun) ), !.
%% ... AND A SUBJECT DOES NOT RUN ACROSS A COMMA INTO THE NAME THAT ENDS IT:
%% `Pese a que empezó frío, poco expresivo, Bros fue entonándose' divided at
%% its first comma read `poco expresivo Bros' as one subject, a little
%% expressive thing called Bros. What stands before the comma is the clause
%% before's, and the name is the subject on its own.
%% ... which is what a comma before a name and a verb says of the whole
%% piece: read with its commas taken out, the word before the comma ran
%% into the name
tr_name_opens_clause(Side, Words) :-
    append(_, [W1, comma, W2, w(V, _)|_], Words), W1 = w(_, _), \+ tr_name_word(Side, W1),
    W2 = w(_, upper), tr_name_word(Side, W2), tr_verb_form_word(V), !.
tr_name_after_comma(Side, Words) :-
    append(_, [W1, comma, W2], Words), W1 = w(_, _), \+ tr_name_word(Side, W1),
    W2 = w(_, upper), tr_name_word(Side, W2), !.

%% ... AND IN ITS OWN NUMBER: `e il bambino su una roccia, poi si sono fatti
%% forza' read the boy on a rock as the subject of `si sono fatti' and wrote
%% `se ha hecho fuerza', one boy for the two children the plural said. A
%% phrase whose number is its noun's must agree with the verb that has it.
%% ... EXCEPT A SHARE OF A PLURAL: `más de un 60% de los electores habían
%% votado' agrees with the voters, as `la mayoría de los electores votaron'
%% does, and both languages allow it. The head is a percentage, or a noun
%% the lesson says means majority or minority, and a `de' phrase in the
%% plural follows it.
tr_number_agrees(foreign, with(NP0, [pp(P, NP2)|_]), plural) :-
    ( NP0 = all(_, NP) -> true ; NP = NP0 ),                % `tutta una serie di problemi'
    NP = np(_, _, _, w(W, _), singular), tr_share_word(W),
    tr_means_of(foreign, P), tr_subject_number(NP2, plural), !.
tr_number_agrees(foreign, S, N) :- tr_subject_number(S, SN), !, SN == N.
tr_number_agrees(_, _, _).

tr_share_word(W) :- atom(W), sub_atom(W, _, 1, 0, '%'), !.
%% ... and a SERIES of them: `una serie di problemi (...) vengono trascurati'
tr_share_word(W) :- tr_lexeme(foreign, W, L, _), tr_solve(mean(L, E)), memberchk(E, [majority, minority, series]), !.

tr_subject_number(np(_, _, _, W, N), N) :- W \= elided(_), W \= named(_, _).
%% ... and a bare name is ONE: `curiosamente Rivaldo y Overmars tampoco
%% estuvieron' divided at its `y', and `Overmars tampoco estuvieron' read as
%% a clause of its own with one man for the plural's subject
tr_subject_number(name(_), singular).
tr_subject_number(with(NP, _), N) :- tr_subject_number(NP, N).
tr_subject_number(all(_, NP), N) :- tr_subject_number(NP, N).
tr_subject_number(app(NP, _, _), N) :- tr_subject_number(NP, N).

%% ... and the impersonal `si' takes the third person SINGULAR: `si sono
%% fatti forza', `si sono mossi' are they, and the reflexive -- read as the
%% impersonal the plural came out `se ha hecho', one person where there were
%% two. With a plural verb the `si' is the verb's own, and the subject the
%% one nobody named.
tr_impersonal_agrees(impersonal, P, N) :- !, P == third, N == singular.
tr_impersonal_agrees(_, _, _).

tr_phrase_subject(np(_, _, _, _, _)).
tr_phrase_subject(name(_)).
tr_phrase_subject(rel(_, _, _)).
tr_phrase_subject(rc(_, _, _)).
tr_phrase_subject(ncl(_, _)).
tr_phrase_subject(app(_, _, _)).
tr_phrase_subject(all(_, _)).
tr_phrase_subject(with(_, _)).

%% THE COPULA IS THE PERFECT'S AUXILIARY AFTER `si', AND THE LESSON SAYS SO:
%% `"è" is the auxiliary of the reflexive.' With no `si' before it, the
%% copula and a participle are a passive -- and so `si è adeguata' was read
%% as `is adapted', which is how `no se es adaptado' came out of the
%% newspaper sample. After the reflexive or the impersonal `si' they are the
%% perfect: `si è adeguata' has adapted, `si era temuto il peggio' one had
%% feared the worst. A lesson that names no such auxiliary keeps its passive.
tr_si_perfect(LV, Subject, passive, perfect) :-
    ( LV = reflexive(_) ; Subject == impersonal ), tr_solve(auxiliary_of(_, reflexive)), !.
tr_si_perfect(_, _, A, A).

%% a pronoun the lesson calls reflexive
tr_reflexive_word(R) :- tr_lexeme(foreign, R, RL, _), tr_class_of(RL, pronoun), tr_solve(reflexive(RL)), !.

%% an object pronoun that is no tonic one (`esto', `estas' stand after the
%% verb, never before it); before a fronted verb, one that could not be
%% the subject standing in its place (`¿Ella come el pan?' is she, in order)
tr_clitic(fronted, C) :- !, tr_object_pronoun(foreign, C, _), \+ tr_tonic_word(C), \+ tr_subject_pronoun(foreign, C, _, _).
tr_clitic(_, C) :- tr_reflexive_word(C), !.
tr_clitic(_, C) :- tr_object_pronoun(foreign, C, _), \+ tr_tonic_word(C).

%% a word of the lesson's that means one of English's pronouns standing alone
tr_tonic_word(C) :- tr_lexeme(foreign, C, L, _), tr_solve(mean(L, E)), en_tonic(E, _), !.

%% what may stand as the subject: nothing when the subject is asked for or
%% comes after a fronted verb, or when the verb says who (I, you, we,
%% they: never a third person singular, who could be anybody); one
%% pronoun agreeing with the verb; one name; two subjects joined; a phrase
%% with a noun the lesson knows, or headed by a determiner or a number,
%% no object pronoun in it that is not an article too, and none at its end
%% (`Sus perros la ven': the dogs, and her)
%% a relative word as the subject stands for the phrase before it, which is
%% a third person: `lo que quiero' is what I love, and read with `que' for
%% the subject it came out `that loves'
tr_subject_shape(subject(rel), Words, P, _) :- !, Words == [], P == third.
tr_subject_shape(subject(_), Words, _, _) :- !, Words == [].
tr_subject_shape(fronted, Words, _, _) :- !, Words == [].
tr_subject_shape(unsaid(_), Words, _, _) :- !, Words == [].
tr_subject_shape(_, [], P, N) :- !, ( P \== third ; N == plural ).
%% WHAT STANDS ASIDE AFTER A SUBJECT IS NO WORD OF ITS SHAPE: `Carlos
%% Westendorp, Alto Representante Civil en Bosnia, ...' is a name and what
%% it is, and the name's shape is the name's alone -- with the aside's key
%% counted as a word the phrase had no noun and the sentence was refused
tr_subject_shape(A, Words, P, N) :-
    append(Core, [w(_, Kind)], Words), memberchk(Kind, [aside, paren, dashed]), Core = [_|_], !,
    tr_subject_shape(A, Core, P, N).
tr_subject_shape(_, [w(W, _)], P, N) :- tr_subject_pronoun(foreign, W, P1, N1), !, P1 == P, N1 == N.
tr_subject_shape(_, [w(W, _)], P, N) :- tr_impersonal(foreign, W), !, P == third, N == singular.
tr_subject_shape(_, [w(W, upper)], _, _) :- \+ tr_known_word(foreign, W), !.
tr_subject_shape(_, [W1, W2|Ws], P, N) :-
    forall(member(W, [W1, W2|Ws]), tr_name_word(foreign, W)), !, P == third, N == singular.
%% AN INFINITIVE AND WHAT IT TAKES (tr_subject/6's infs/2), in the third
%% person singular: `parlare con Diego era ...' has no noun in it, and the
%% shape below wants one
tr_subject_shape(_, [w(V, _)|_], P, N) :-
    P == third, N == singular, tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !.
%% A DETERMINER AND A PRONOUN IS A PHRASE WHOSE HEAD IS THE PRONOUN.
%% `Il tutto avviene' is `The whole happens' -- and the guard below refuses
%% any object pronoun in a subject phrase, which is right for `Sus perros la
%% ven' (the dogs, and her) and wrong here, where the pronoun is the only
%% content word the phrase has. A word that is a determiner too is no head,
%% which is the `uno' rule of 1.6.7 said from this side.
tr_subject_shape(_, [D, w(X, _)], _, _) :-
    tr_determiner(foreign, D, _, _),
    tr_is(foreign, w(X, lower), pronoun),
    \+ tr_determiner(foreign, w(X, lower), _, _), !.
%% A WORD THAT REPLACES A NOUN AND A RELATIVE CLAUSE is a phrase whose noun
%% was left out: `lo que hace es "desacreditar" la investigación', what it
%% does. `lo' is an object pronoun too, which the guard below refuses in a
%% subject, and it is no determiner either
tr_subject_shape(_, [Q, w(R, _)|_], P, N) :-
    P == third, N == singular, tr_noun_replacer(foreign, Q), tr_relative_word(foreign, R), !.
tr_subject_shape(_, Words, _, _) :-
    tr_conjunction_split(foreign, Words, W1, W2), !,
    tr_subject_shape(none, W1, third, singular), tr_subject_shape(none, W2, third, singular).
tr_subject_shape(_, Words, _, _) :-
    %% A BARE TIME PHRASE IS NOT A SUBJECT. `Qui solo due anni fa dominava
    %% il coprifuoco' is the curfew dominating and `solo due anni' is when;
    %% the plain reading took it for the subject, which is a WRONG reading
    %% rather than a refusal and the worse of the two. A DETERMINER makes it
    %% one again -- `L'anno era lungo' is about the year -- so the rule is
    %% as narrow as the shape that needs it.
    \+ ( Words = [W0|_], \+ tr_determiner(foreign, W0, _, _),
         tr_np(foreign, Words, NP0), tr_time_phrase(NP0) ),
    %% -- in the phrase's OWN words, which end at a relative word: `Los
    %% violines que se exponen han mejorado' has its reflexive inside the
    %% relative clause, where it is the clause's and no adjective of the
    %% phrase, and refused there the sentence read with no verb at all.
    %% ONLY A RELATIVE CLAUSE THAT OPENS NO FURTHER CLAUSE: Livata's `... che
    %% li hanno trovati vigili e in buone condizioni nonostante le
    %% temperature ... abbiano raggiunto' offered twenty-seven words before
    %% `abbiano' as a subject, their `li' after `che', and the one-statement
    %% reading parsed all of them before the division at `nonostante' read
    %% the sentence: 8.3 million inferences became 13.6. A subject's relative
    %% clause runs to the subject's verb; one that opens another clause on
    %% the way is two clauses, and the pronoun in it is the old refusal.
    (   append(Own, [w(RW, _)|RelWs], Words), tr_relative_word(foreign, RW),
        \+ ( member(X, RelWs), tr_opens_clause(X) )
    ->  true
    ;   Own = Words
    ),
    \+ ( member(w(X, _), Own), tr_object_pronoun(foreign, X, _), \+ tr_determiner(foreign, w(X, lower), _, _),
         %% ... but `all' before a determiner is the phrase's own, all/2:
         %% `Tutta una serie di problemi (...) vengono trascurati', and
         %% `tutta' is the pronoun `everything' as well
         \+ ( Own = [w(X, _), D1|_], tr_all_word(foreign, X), tr_determiner(foreign, D1, _, _) ) ),
    %% -- and at its end a CLITIC, never a pronoun that stands alone after its
    %% determiner: `Gli altri erano vicini' is the others, and `altri' means
    %% `others', which an object may be as well as a subject. ONLY AFTER A
    %% DETERMINER, where the pronoun heads the phrase: after a preposition it
    %% ends the phrase's `in' phrase, and `Due bambini ..., in quelle
    %% condizioni, a meno 5 gradi' read `quelle' there, and `condizioni' as
    %% its verb
    \+ ( last(Words, w(X, _)), tr_object_pronoun(foreign, X, _),
         \+ ( tr_tonic_word(X), append(_, [D, w(X, _)], Words), tr_determiner(foreign, D, _, _) ) ),
    %% nor a REFLEXIVE pronoun anywhere in it: `la casa si' is the phrase and
    %% the clitic, never a phrase with `si' for an adjective
    \+ ( member(w(X, _), Own), tr_reflexive_word(X) ),
    (   member(W, Words), tr_is(foreign, W, noun) -> true
    %% ... or a NAME with its relative clause: `E Pannella che si unisce a
    %% Ferrara ... non ha pensato', `Maria che dorme mangia'. A name is no
    %% noun to the lesson, so a clause with no noun in it refused the
    %% subject, and one with a noun (`Maria che mangia il pane') passed by
    %% the clause's noun
    ;   Own \== Words, Own = [_|_], forall(member(N0, Own), tr_name_word(foreign, N0)) -> true
    ;   Words = [D, _|_], ( tr_determiner(foreign, D, _, _) ; tr_is(foreign, D, number) )
    ).

%% the verb group at the first place one starts WHOSE SUBJECT READS, for a
%% statement: with a vocabulary of thousands of verbs a noun is often a
%% verb's form too -- `hermano' is the first person of `hermana', to twin
%% -- and the first place a group starts in `Mi hermano tiene un coche' is
%% `hermano', which leaves `Mi' as the subject. The place is tried in
%% order and the reader goes on to the next when nothing before it is a
%% subject
tr_group_from(Side, Words, Before, Group, After) :-
    append(Before, Rest, Words),
    \+ tr_named_there(Side, Before, Rest),
    \+ tr_article_before(Side, Before),
    tr_group_at(Side, Rest, Group, After).

%% A PREPOSITION AND ITS ARTICLE ARE FOLLOWED BY THE ARTICLE'S NOUN, NEVER BY
%% A VERB: `Auto proibite nelle isole del sole' read `isole' as what
%% `isolare' says to one person, after `in le', and the headline came out as
%% a clause about isolating. An article with no preposition before it may
%% still be a pronoun before its verb (`la mangia').
tr_article_before(Side, Before) :-
    append(_, [P, D], Before), P = w(_, _), D = w(_, _),
    tr_is(Side, P, preposition), tr_determiner(Side, D, _, article), !.

%% A WORD WITH ITS CAPITAL INSIDE A SENTENCE IS A NAME, NOT A VERB: `Grazie
%% all'Arma dei carabinieri' -- `arma' is also `he arms', and a verb
%% there shut out the one reading the sentence has, which has none. The
%% head of a sentence was lowered when the lesson knows it (tr_head_lower/3),
%% so what still has its capital past the head was written with one --
%% and that is true of the head of any PART of a sentence too: the fronted
%% reading reads `Arma dei carabinieri' as a statement of its own, where
%% the capital is the only sign left.
tr_named_there(foreign, _, [w(_, upper)|_]) :- !.

%% the verb group: at the first place one starts, the words before it and after it
tr_group(Side, Words, Before, Group, GroupWords, After) :-
    append(Before, Rest, Words),
    tr_group_at(Side, Rest, Group, After), !,
    append(GroupWords, After, Rest).

%% English: `will' and a base form, or `be' and a gerund; `would' and a
%% base form; `has', `have' or `had' and a participle; `does', `do' or
%% `did' and a base form; a modal the lesson gives a word for, in its
%% tense; a copula and a gerund; a copula; a verb form
tr_group_at(english, [w(will, _), w(be, _), w(G, _)|R], g(L, future, progressive, third, singular), R) :- en_gerund(G, L), !.
tr_group_at(english, [w(will, _), w(B, _)|R], g(L, future, simple, third, singular), R) :- en_verb_form(B, L, present), !.
tr_group_at(english, [w(would, _), w(B, _)|R], g(L, conditional, simple, third, singular), R) :- en_verb_form(B, L, present), !.
%% ENGLISH'S PASSIVE PERFECT GOES ABOVE ITS PERFECT, for the reason the
%% lesson's own does: `been' is the participle of `is', so `has been
%% evacuated' read as a perfect is `has been' with `evacuated' left over and
%% the sentence refused. Measured before this clause moved -- `The house has
%% been evacuated.' and `The house had been evacuated.' were both refused on
%% the English side while the WRITER produced exactly those words, so a
%% passive perfect could not round-trip through English at all.
%%
%% It is safe by what it requires: the middle word must be `been', so `has
%% eaten the bread' matches nothing here and falls through as before.
tr_group_at(english, [w(H, _), w(been, _), w(P, _)|R], g(L, T, passive_perfect, third, singular), R) :-
    memberchk(H, [has, have, had]), en_passive_participle(P, L), !, ( H == had -> T = past ; T = present ).
tr_group_at(english, [w(H, _), w(P, _)|R], g(L, T, perfect, third, singular), R) :-
    memberchk(H, [has, have, had]), en_participle(P, L), !, ( H == had -> T = past ; T = present ).
tr_group_at(english, [w(D, _), w(B, _)|R], g(L, T, simple, third, singular), R) :-
    memberchk(D, [does, do, did]), en_verb_form(B, L, present), !, ( D == did -> T = past ; T = present ).
tr_group_at(english, [w(M, _)|R], g(L, T, simple, third, singular), R) :-
    en_modal_form(M, L, T), tr_known(english, L), tr_class(english, L, modal), !.
tr_group_at(english, [w(C, _), w(G, _)|R], g(L, T, progressive, P, N), R) :- en_copula(C, P, N, T), en_gerund(G, L), !.
%% English's passive: `is considered', `was thrown'. It
%% is tried BEFORE the plain copula, or `is considered' would read as the
%% copula with an adjective after it -- and it is refused for a word the
%% lesson also calls an ADJECTIVE, which is what keeps `She is licensed' the
%% adjective sentence it was. The PERFECT passive, `has been thrown', is
%% above with the perfect it has to beat.
tr_group_at(english, [w(C, _), w(P, _)|R], g(L, T, passive, Per, N), R) :-
    en_copula(C, Per, N, T), en_passive_participle(P, L), !.
tr_group_at(english, [w(C, _)|R], g(is, T, simple, P, N), R) :- en_copula(C, P, N, T), !.
tr_group_at(english, [w(V, _)|R], g(L, T, simple, third, singular), R) :- en_verb_form(V, L, T), !.
%% the lesson's language: the auxiliary that means `is' and a gerund, the
%% progressive; an auxiliary's form and a participle, the perfect; a
%% verb's or a modal's form
tr_group_at(foreign, [w(A, _), w(G, _)|R], g(L, T, progressive, Person, N), R) :-
    tr_form(A, AL, N, T, Person), tr_solve(auxiliary(AL)), tr_solve(mean(AL, is)), tr_solve(gerund_of(G, L)), tr_known(foreign, L), !.
%% THE PASSIVE: the copula and a participle (`e considerata'), and the
%% PERFECT passive with the copula's own participle between them (`e stato
%% gettato', `ha sido evacuada'). The three-word reading is tried FIRST --
%% before the perfect just below and before the two-word passive -- or its
%% middle word would be taken for the verb: `ha sido evacuada' read as a
%% perfect is `has been' with `evacuada' left over, which is how Spanish's
%% own passive perfect was refused outright until 1.6.8.
%%
%% AND WHICH WORD CARRIES THE TENSE IS THE LESSON'S, NOT THIS CODE'S.
%% Italian builds the copula's perfect with the copula (`e stata evacuata')
%% and Spanish with the auxiliary (`ha sido evacuada'), and nothing else in
%% a lesson tells them apart -- so the lesson says it, in the shape
%% `"los" is the plural of "el"' already has: `"ha" is the auxiliary of
%% "es".' The copula itself is the default, so a lesson that says nothing
%% writes what it wrote before.
tr_group_at(foreign, [w(C, _), w(B, _), w(P, _)|R], g(L, T, passive_perfect, Person, N), R) :-
    tr_form(C, CL, N, T, Person),
    tr_solve(participle_of(B, BL)), tr_copula_lexeme(BL), tr_perfect_auxiliary(BL, CL),
    tr_solve(participle_of(P, L)), tr_known(foreign, L), tr_participle_agrees(P, N), !.
%% ... AND AN ADVERB MAY STAND INSIDE IT, before the verb's participle: `non
%% sono state ANCORA accertate'. The two-word passive below then took `sono
%% state' for the passive of `stare' -- `stata' is the participle of `stare'
%% as well as of the copula, and the store answers `stare' first -- and read
%% `accertate' as a participle predicated of the subject, which is `are not
%% stood, even verified'. The adverbs go back at the head of what follows,
%% where the complement reader reads any adverb after the verb.
%% The participle's number chooses among the copula's readings, as it does
%% in the clause above: `sono' is I am before it is they are, and cut on
%% the first `I generali non sono stati ancora accertati' had a first
%% person no phrase agrees with, and read only once the adverb was lifted.
tr_group_at(foreign, [w(C, _), w(B, _)|R0], g(L, T, passive_perfect, Person, N), R) :-
    tr_adverb_prefix(R0, Advs, [w(P, _)|R1]), Advs \== [],
    tr_form(C, CL, N, T, Person),
    tr_solve(participle_of(B, BL)), tr_copula_lexeme(BL), tr_perfect_auxiliary(BL, CL),
    tr_solve(participle_of(P, L)), tr_known(foreign, L), tr_participle_agrees(P, N), !,
    append(Advs, R1, R).
%% -- an auxiliary that means HAS: the one that means `is' is the
%% progressive's and the state's (`está comiendo', `está considerado'), and
%% `Su constructor está considerado como el Van Gogh' came out `has
%% considered'
tr_group_at(foreign, [w(A, _), w(P, _)|R], g(L, T, perfect, Person, N), R) :-
    tr_form(A, AL, N, T, Person), tr_solve(auxiliary(AL)), \+ tr_solve(mean(AL, is)),
    tr_solve(participle_of(P, L)), tr_known(foreign, L), !.
%% ... AND AN ADVERB MAY STAND BETWEEN THE AUXILIARY AND THE PARTICIPLE OF
%% ANY OF THEM: `è SEMPRE risultato spento', `si era QUINDI temuto il
%% peggio', `abbiamo POI ritrovato la mamma'. Without this the copula alone
%% was the group and the participle a bare predicate after it, which is how
%% `Se era entonces temido lo peor' came out. The group is read with the
%% adverbs taken out and they go back at the head of what follows, as the
%% passive perfect's do above.
tr_group_at(foreign, [w(C, CC)|R0], G, R) :-
    tr_adverb_prefix(R0, Advs, [w(P, PC)|R1]), Advs \== [],
    tr_solve(participle_of(P, _)),
    tr_group_at(foreign, [w(C, CC), w(P, PC)|R1], G, R2),
    G = g(_, _, A, _, _), memberchk(A, [perfect, passive, duty]), !,
    append(Advs, R2, R).
%% A VERB THE LESSON SAYS BUILDS ITS PERFECT WITH THE COPULA IS READ AS THAT
%% PERFECT: `"è" is the auxiliary of "risulta".' makes `è risultato spento'
%% has turned out off, and `sono caduti', `sono proseguite' has fallen, has
%% gone on -- where the passive just below read the same two words as `is
%% resulted', and the Spanish came out `es resultado'. The writer has used
%% the same line since 1.6.15 to write `è riuscito'; this is its reading. It
%% goes before the passive because it is the narrower of the two: only a
%% verb the lesson names.
%% The copula's OWN perfect is the same shape: `sono stati eroici' has been,
%% where the lesson names no other word for it (tr_perfect_auxiliary/2).
tr_group_at(foreign, [w(C, _), w(P, _)|R], g(L, T, perfect, Person, N), R) :-
    tr_form(C, CL, N, T, Person), tr_copula_lexeme(CL),
    tr_solve(participle_of(P, L)),
    ( tr_solve(auxiliary_of(CL, L)) -> true ; tr_copula_lexeme(L), tr_perfect_auxiliary(L, CL) ),
    tr_known(foreign, L), tr_participle_agrees(P, N), !.
%% WHAT TELLS A PASSIVE FROM A PERFECT IS THE LESSON, not this code. Italian
%% builds the perfect of some verbs with `essere' too -- `e riuscito' is `has
%% succeeded', not `is succeeded' -- and nothing in a lesson says which verbs
%% those are. The rule above fires only for a word the lesson calls an
%% auxiliary, so `ha' takes the perfect and `e' falls through to here; a
%% lesson that called its copula an auxiliary would get the other reading.
%% The cost is stated rather than hidden: an intransitive perfect built with
%% the copula reads as a passive.
%% A VERB THE LESSON SAYS MARKS THE PASSIVE BUILDS ONE WITH A PARTICIPLE:
%% `Viene esclusa ogni forma di eutanasia diretta' is `is excluded', and
%% Italian says it with `venire' as readily as with the copula. Read as the
%% verb it also is, it came out `comes excluded'. `The verb "viene" marks
%% the passive.' is the line, the shape `The auxiliary "está" marks the
%% state.' already has, so reason.pl did not move; a language that says
%% nothing keeps its copula's passive alone.
%% ... AND ONE THAT MARKS THE DUTY SAYS WHAT MUST BE DONE: `Vanno invece
%% attivate la terapia palliativa e la terapia del dolore' is `must be
%% activated', `andare' and a participle. The group is duty(L); the
%% statement reader writes it out as the modal, the copula's infinitive and
%% the participle (tr_duty_fix/2), which is what English's `must be
%% activated' reads as, so every writer already has it.
tr_group_at(foreign, [w(V, _), w(P, _)|R], g(L, T, A, Person, N), R) :-
    tr_form(V, VL, N, T, Person), tr_solve(mark(VL, M)), memberchk(M-A, [passive-passive, duty-duty]),
    tr_solve(participle_of(P, L)), tr_known(foreign, L), tr_participle_agrees(P, N), !.
%% ... and the copula of a STATE with a participle is a passive too: Spanish
%% says what a thing is held to be with `estar', `está considerado como el
%% Van Gogh de la luthiere', and Italian and English with the copula
tr_group_at(foreign, [w(C, _), w(P, _)|R], g(L, T, passive, Person, N), R) :-
    tr_form(C, CL, N, T, Person), ( tr_copula_lexeme(CL) -> true ; tr_state_lexeme(CL) ),
    tr_solve(participle_of(P, L)), tr_known(foreign, L), tr_participle_agrees(P, N), !.
%% -- and NOT cut on the first reading: `sono' is the first person of `è'
%% and the plural of it, and which one it is in `Le case sono grandi' the
%% subject decides, so the statement reader backtracks into the next
tr_group_at(foreign, [w(V, _)|R], g(L, T, simple, Person, N), R) :-
    tr_form(V, L, N, T, Person), tr_verb_lexeme(L).

%% a verb of the lesson's, or a modal
tr_verb_lexeme(L) :- ( tr_class_of(L, verb) -> true ; tr_class_of(L, modal) ).

%% A PARTICIPLE AFTER THE COPULA AGREES WITH THE SUBJECT, SO IT SAYS THE
%% NUMBER the copula's form may not: `sono' is the first person singular and
%% the third plural, and `si sono mossi', `sono caduti', `sono stati eroici'
%% came out `me he movido', `he caído', `soy sido' until the plural
%% participle was allowed to decide. A participle the lesson states as the
%% plural of another is plural; any other is singular. A language whose
%% participle does not agree -- Spanish's `sido' is one form -- states no
%% plural for it, and every number passes.
tr_participle_agrees(P, N) :-
    (   tr_solve(plural_of(P, S)), tr_solve(participle_of(S, _)) -> N == plural
    ;   tr_solve(plural_of(_, P)) -> N == singular
    ;   true
    ), !.

%% the copula's lexeme: the verb the lesson gives for `is', never an
%% auxiliary it named for the perfect or the progressive
tr_copula_lexeme(L) :- tr_solve(mean(L, is)), tr_class_of(L, verb), \+ tr_solve(auxiliary(L)), !.

%% the adverbs at the head of a run of words, the longest run first
tr_adverb_prefix([A|Ws], [A|As], Rest) :- tr_is(foreign, A, adverb), tr_adverb_prefix(Ws, As, Rest).
tr_adverb_prefix(Ws, [], Ws).

%% the word that builds the COPULA's own perfect: the one a lesson names
%% (`"ha" is the auxiliary of "es"'), and the copula itself where no lesson
%% says otherwise, which is Italian's `e stata'. The participle after it
%% agrees with whatever forms the lesson gives it to agree with -- four in
%% Italian, and in Spanish the one invariable `sido', which is the language
%% saying the same thing through its data.
tr_perfect_auxiliary(CL, Aux) :- tr_solve(auxiliary_of(A, CL)), !, Aux = A.
tr_perfect_auxiliary(CL, CL).

%% a participle that may head a passive: one of a verb the lesson gives, and
%% NOT a word it also calls an adjective
en_passive_participle(P, L) :- en_participle(P, L), \+ tr_class(english, P, adjective).

%% the subject: what was asked, a pronoun, a name, two joined, a phrase --
%% or, in the lesson's language, nobody, and then the pronoun the verb's
%% person and number say
%% (a relative word asked for as the subject keeps the verb's number:
%% tr_relative_clause/4 hands it to the gap)
tr_subject(_, subject(Q), [], P, N, asked(Q1)) :- !, ( Q == rel -> Q1 = rel(P, N) ; Q1 = Q ).
tr_subject(foreign, _, [], P, N, null(P, N)) :- !, ( P \== third ; N == plural ).
tr_subject(Side, _, [w(P, C)], _, _, pronoun(Person, Number, w(P, C))) :- tr_subject_pronoun(Side, P, Person, Number), !.
%% BEFORE the phrase below, on both sides: English's `one' is a number word
%% as well, and the lesson's word is a pronoun the phrase reader would take
%% for one
tr_subject(Side, _, [w(W, _)], _, _, impersonal) :- tr_impersonal(Side, W), !.
%% (the cut after BOTH halves read: `la storia della scomparsa E del
%% ritrovamento' splits, the second half is no subject, and a cut at the
%% split shut out the one subject the sentence has)
%% -- and never a bare noun after a first half with a preposition in it:
%% `la demanda de las familias en productos de ocio y entretenimiento' is
%% one demand, for leisure and entertainment, and split there the subject
%% was two things against a verb that says one, the cut shut out the
%% reading below, and the sentence was divided at the `y' instead
%% ... AND TWO NOUNS UNDER ONE ARTICLE WITH A SINGULAR VERB ARE ONE PERSON:
%% `el actual presidente y ex ministro ... Eduard Shevardnadze' is one man,
%% and read as two the verb that says one came out plural in Italian,
%% `votarono'. The second noun has no determiner of its own; the term is
%% one/1, which every writer takes for the singular the source said.
tr_subject(Side, _, Words, _, N, Subject) :-
    tr_conjunction_split(Side, Words, W1, C, W2),
    \+ ( member(P1, W1), tr_is(Side, P1, preposition), \+ tr_phrase_marked(Side, W2) ),
    tr_subject(Side, none, W1, third, singular, S1), tr_subject(Side, none, W2, third, singular, S2), !,
    (   N == singular, tr_determined(S1), tr_undetermined(S2)
    ->  Subject = one(co(C, S1, S2))
    ;   Subject = co(C, S1, S2)
    ).

tr_determined(np(det(_, _, _), _, _, _, _)) :- !.
tr_determined(with(NP, _)) :- tr_determined(NP).
tr_undetermined(np(none, none, _, w(_, _), singular)) :- !.
tr_undetermined(with(NP, _)) :- tr_undetermined(NP).

%% a phrase that says it begins: a determiner, a number, a name or a pronoun
tr_phrase_marked(Side, [W|_]) :-
    (   tr_determiner(Side, W, _, _) ; tr_is(Side, W, number) ; W = w(_, upper)
    ;   W = w(X, _), ( tr_subject_pronoun(Side, X, _, _) ; tr_object_pronoun(Side, X, _) )
    ), !.
%% A LIST THAT BEGINS WITH ITS OWN CONNECTOR: `no figuran ni Rivaldo ni
%% Overmars ni De la Peña'. The first `ni' joins nothing -- it says the
%% list is a denial from its first word -- so the list is read without it
%% and the IR keeps it as nei/1, which every writer gives its first word
%% back: `né Rivaldo né Overmars né De la Peña', `neither ... nor ...'.
tr_subject(foreign, _, [w(C, _)|Words], _, _, nei(co(W, S1, S2))) :-
    tr_neither_word(C),
    tr_conjunction_split(foreign, Words, W1, W, W2), W = w(C2, _), C2 == C,
    tr_subject(foreign, none, W1, third, singular, S1), tr_subject(foreign, none, W2, third, singular, S2), !.
%% AN INFINITIVE AND WHAT IT TAKES ARE A SUBJECT: `essere presidente di
%% questa società è la cosa più difficile del mondo', `parlare con Diego era
%% come parlare con due persone diverse'. What is done is the subject, and
%% the verb after it is in the third person singular. infs(Lexeme,
%% Complements) is the term: English writes `to' and the base form, the
%% lesson's language its infinitive, each with the complements after it.
%% -- AND A QUOTATION THAT OPENS ON THE INFINITIVE KEEPS ITS MARK: `sostuvo
%% que "cometer perjurio no es aceptable"' lost the opening one, because
%% infs/2 carries a lexeme and no case; infs/3 carries the mark as well
tr_subject(foreign, _, [w(V, VC)|Ws], third, singular, Subj) :-
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F),
    tr_complements(foreign, Ws, no, Cs), !,
    ( memberchk(VC, [qopen, qboth]) -> Subj = infs(F, Cs, VC) ; Subj = infs(F, Cs) ).
tr_subject(Side, _, Words, _, _, Subject) :- tr_np(Side, Words, Subject), !.
%% a phrase and the prepositional phrases after it: `the dogs of Maria'
%% ... and whatever else a phrase carries that is no object and no clause:
%% `la storia a lieto fine DELLA scomparsa E DEL ritrovamento di una donna,
%% 36 anni, e due bambini (...), SPARITI IERI sul Monte Livata vicino
%% Subiaco (Roma) deve essere ancora completamente chiarita' -- the story,
%% with everything that says which story, is what must be cleared up
%% -- and the word the lesson puts before a person is a preposition there,
%% never the mark of an object: `La visita a Ceuta presenta ...' is the
%% visit to Ceuta, and read as `visits Ceuta' the subject was refused
%% -- AND NEVER AN ARTICLE ALONE BEFORE IT: `Los más destacados luthiers del
%% mundo' divided at `más', which is the preposition `plus' as well as the
%% comparative, and took `los' for the phrase -- the pronoun it also is --
%% so the subject was one thing against a plural verb and the cut after it
%% shut out the superlative the sentence is
tr_subject(Side, _, Words, _, _, with(NP, PPs)) :-
    append(NPWords, [P|PPWords], Words), tr_is(Side, P, preposition), NPWords \== [],
    \+ ( NPWords = [D1], tr_determiner(Side, D1, _, _), \+ tr_standalone_det(Side, D1) ),   % `uno dei Paesi' does
    tr_np(Side, NPWords, NP), tr_complements(Side, [P|PPWords], yes, PPs0),
    tr_noun_infinitive(Side, P, PPs0, PPs1),
    tr_title_appos(PPs1, PPs),
    tr_subject_comps(PPs), !.

%% A `di' AND AN INFINITIVE WITH ITS PRONOUNS AFTER A SUBJECT'S NOUN ARE THE
%% NOUN'S: `è venuto il momento di porsi la stessa domanda' is the time to
%% ask oneself the question. The lesson says `di' begins the infinitive,
%% which makes it the verb's after a verb (infx/3 alone), and a subject has
%% no verb to give it to -- read that way the subject was refused and the
%% moment became the time the verb happened at. The preposition travels as
%% nprep/1, which the lesson's writer spells (`el momento de plantearse').
tr_noun_infinitive(foreign, P, [infx(F, A, Cls)|Cs], [nprep(P), infx(F, A, Cls)|Cs]) :-
    P = w(PW, _), tr_means_of(PW), !.
tr_noun_infinitive(_, _, Cs, Cs).

%% A TITLE AND ITS NAME AFTER THE PHRASE ARE ITS APPOSITION: `l'arcivescovo
%% di Monreale monsignor Salvatore Cassisa' is one person, and the phrase
%% after the `di' phrase is no object -- a subject has none
tr_title_appos([], []).
tr_title_appos([obj(NP)|Xs], [appos(NP)|Ys]) :- tr_title_np(NP), !, tr_title_appos(Xs, Ys).
tr_title_appos([X|Xs], [X|Ys]) :- tr_title_appos(Xs, Ys).

tr_title_np(np(none, none, [w(_, upper)], w(TW, _), singular)) :- tr_title_word(foreign, TW), !.
tr_title_np(np(none, none, [w(_, upper)], w(TW, _), singular)) :- tr_title_word(english, TW).

tr_title_word(foreign, W) :- tr_lexeme(foreign, W, L, _), tr_solve(title(L)), !.
tr_title_word(english, W) :- tr_solve(mean(F, W)), tr_solve(title(F)), !.

%% ... an infinitive among them with its own object: `Esta obsesión por
%% eliminar cualquier signo de relajación le ha llevado ...' is an obsession
%% with getting rid of every sign of it
%% -- and a PURPOSE with its object: `la insistencia de los republicanos en
%% buscar otros cargos PARA FORTALECER EL PROCESO contra Lewinsky' is one
%% phrase, the insistence, and with the purpose refused there it had none
tr_subject_comps([]).
tr_subject_comps([pinf(_, _), obj(_)|Xs]) :- !, tr_subject_comps(Xs).
tr_subject_comps([nprep(_), infx(_, _, _), obj(_)|Xs]) :- !, tr_subject_comps(Xs).
tr_subject_comps([nprep(_), infx(_, _, _)|Xs]) :- !, tr_subject_comps(Xs).
tr_subject_comps([purpose(_), obj(_)|Xs]) :- !, tr_subject_comps(Xs).
tr_subject_comps([X|Xs]) :- tr_subject_comp(X), tr_subject_comps(Xs).

tr_subject_comp(pp(_, _)).
tr_subject_comp(appos(_)).
tr_subject_comp(pinf(_, _)).
tr_subject_comp(purpose(_)).
tr_subject_comp(cnj(_)).
tr_subject_comp(pred(_)).
tr_subject_comp(predq(_, _)).
tr_subject_comp(adv(_)).
tr_subject_comp(sep).
tr_subject_comp(paren(_)).
tr_subject_comp(at_time(_)).

%% `Maria and Omar', `the bread and the egg': two phrases, each with a
%% noun, a name or a pronoun of its own
%% THE CONJUNCTION IS KEPT, which it was not: every phrase joined by one
%% travelled as and/2, so `el caldo o la sopa' came out `il brodo e la
%% minestra' -- a different claim. co(Conjunction, A, B) carries the word
%% the text joined them with, it crosses by its meaning like a connector
%% between clauses, and each writer puts the target's word for it back.
tr_conjunction_split(Side, Words, W1, W2) :- tr_conjunction_split(Side, Words, W1, _, W2).
tr_conjunction_split(Side, Words, W1, w(C, CC), W2) :-
    append(W1, [w(C, CC)|W2], Words), CC \== acomma, tr_coord(Side, w(C, lower)), W1 \== [], W2 \== [],
    \+ ( W2 = [P0|_], tr_is(Side, P0, preposition) ),         % `e DEL ritrovamento' joins two phrases' prepositions
    \+ ( member(w(R, _), W1), tr_relative_word(Side, R) ),     % never inside a relative clause
    %% nor before a run of ADJECTIVES with nothing to head them: `la violencia
    %% gratuita juvenil, anárquica o xenófoba' is one violence, and split
    %% there `xenófoba' was a xenophobe and came out masculine
    \+ ( W1 = [_, _|_], forall(member(X, W2), ( tr_coord(Side, X) ; tr_is(Side, X, adjective) )) ),
    %% nor between two ADJECTIVES before one noun: `i loro assurdi e folli
    %% scopi' is their absurd and mad aims -- `assurdi' is also the noun
    %% `absurdities', and split there the aims were a second thing
    \+ ( W1 = [D1|_], tr_determiner(Side, D1, _, _), last(W1, L1), tr_is(Side, L1, adjective),
         W2 = [A2|_], tr_is(Side, A2, adjective), \+ tr_determiner(Side, A2, _, _),
         last(W2, N2), tr_is(Side, N2, noun) ),
    tr_headed(Side, W1), tr_headed(Side, W2), !.
tr_headed(Side, Ws) :- member(w(W, _), Ws), ( tr_is(Side, w(W, lower), noun) ; tr_is_name(Side, W) ; tr_subject_pronoun(Side, W, _, _) ; tr_object_pronoun(Side, W, _) ), !.
%% ... or a phrase whose noun was left out: `un grupo y el más débil'
tr_headed(Side, Ws) :- Ws = [D, _|_], tr_determiner(Side, D, _, article), tr_np(Side, Ws, NP), ( NP = np(_, _, _, elided(_), _) ; NP = ell(_, _, _, _) ), !.
%% ... or a pronoun that stands alone: `un elicottero della forestale e UNO
%% della Guardia di finanza' is one more helicopter, the noun said once
tr_headed(foreign, [w(W, _)|_]) :- tr_lexeme(foreign, W, L, _), tr_class_of(L, pronoun), tr_solve(neg(precede(L, verb))), !.
%% ... or a count with its noun left out: `oltre 50 mezzi e 130 circa' is
%% vehicles and a hundred and thirty people, the number standing for them
tr_headed(_, Ws) :- last(Ws, w(W, _)), tr_digits(W), !.
tr_is_name(Side, W) :- \+ tr_known_word(Side, W), \+ en_function(W), \+ en_subject(W, _, _).

%% a phrase: a name; or a determiner or none, a number or none, then the
%% content -- one noun (the word the lesson calls one, failing that the last
%% word in English and, where adjectives follow the noun, the first) and
%% the rest adjectives, an `and' among them kept
%% A PARTICIPLE AFTER THE NOUN IS A REDUCED RELATIVE: `il coprifuoco imposto
%% dai soldati' is the curfew THAT WAS imposed by the soldiers, and `le
%% autorita costituite' the authorities that were constituted. It is a
%% passive relative clause with the copula and the pronoun left out, and both
%% languages and English put it in the same place -- after the noun -- which
%% is why one shape writes into all three.
%%
%% `rel(NP, Lexeme, Comps)' is the term: the phrase, the verb's lexeme
%% (English in the IR like every other), and what belongs to the participle,
%% which is the agent when there is one. The lexeme rather than the FORM,
%% because the form must agree with the noun on the way out and the writer
%% picks it exactly as a passive does.
%% A RELATIVE CLAUSE WITH ITS OWN PRONOUN: `esos, que son culpables', `el
%% caldo que el pequeño aprende', `el grupo social al que pertenece'.
%% rc(Phrase, Role, Clause) is the term: the phrase it sits on, what the
%% relative word stands for in the clause -- subject, object, or the object
%% of a preposition, pp(P) -- and the clause as a sentence of the IR with
%% that one thing left out. A subject left out is `gap', and the writer
%% gives it the PHRASE's person and number, which is what the verb agreed
%% with; an object or a preposition's object is simply not there.
%%
%% THE SUBJECT READING IS TRIED FIRST: `que come el pan' is the phrase
%% eating, and only when nothing may stand before the verb does it fail and
%% the object reading take the whole clause as a statement of its own.
tr_np(Side, Words, app(NP, Kind, K)) :-
    append(Core, [w(K, Kind)], Words), memberchk(Kind, [paren, aside, dashed]), Core \== [], !,
    tr_np(Side, Core, NP).
%% A TITLE AND THE NAME IT GOES WITH: `la descripción visual de lord Arturo
%% Bucklaw' -- a noun of the lesson's in small letters, and a name of two
%% words or more after it, which is one person with his title. A name
%% apposed to a noun stands only after a determiner (`il presidente
%% Scalfaro'), so with none the name was a sentence's subject of its own,
%% `Arturo Bucklaw Vick'. The name's words join as one, apposed to the
%% noun, and cross as themselves: `lord Arturo Bucklaw'.
tr_np(foreign, [w(NW, lower), W1, W2|Ws], np(none, none, [w(Name, upper)], w(NW, lower), Number)) :-
    tr_is(foreign, w(NW, lower), noun),
    forall(member(X, [W1, W2|Ws]), tr_name_word(foreign, X)), !,
    ( tr_lexeme(foreign, NW, _, Number) -> true ; Number = singular ),
    findall(C, ( member(w(X1, _), [W1, W2|Ws]), tr_cap(X1, C) ), Cs), atomic_list_concat(Cs, ' ', Name).
%% ... and a NAME with a name apposed to it between commas (tr_list_commas/3):
%% `en Josep Bros, Edgardo,' is the singer and the role he sang
tr_np(Side, Words, app(NP, apposed, w(W, appos))) :-
    append(Core, [w(W, appos)], Words), Core = [_|_], forall(member(X, Core), tr_name_word(Side, X)), !,
    tr_np(Side, Core, NP).
%% ... and a capitalised word the lesson knows, read as the name it stands
%% for there: `la ministra de Justicia, Janet Reno,' -- after `de' the word
%% is a name (tr_np/3), and the apposition after it refused the phrase
tr_np(Side, Words, app(NP, apposed, w(W, appos))) :-
    append(Core, [w(W, appos)], Words), Core = [w(_, upper)], tr_np(Side, Core, NP), NP = name(_), !.
%% ... and a name with a DETERMINER before it: `del actual presidente y ex
%% ministro ... de la antigua URSS, Eduard Shevardnadze,' -- the phrase is
%% an article and a name (named/2), which takes no adjective after it, so
%% the name apposed to it refused the whole sentence
tr_np(Side, Words, app(NP, apposed, w(W, appos))) :-
    append(Core, [w(W, appos)], Words), Core = [D, _|_], tr_determiner(Side, D, _, _),
    last(Core, L), tr_name_word(Side, L),
    tr_np(Side, Core, NP), NP = np(_, _, _, named(_, _), _), !.
%% A NOUN AND THE CLAUSE THAT SAYS WHAT IT IS: `Como prueba de que los
%% violines ... han mejorado con el tiempo, los solistas ...' is proof THAT
%% the violins have improved. The clause runs to the end of the phrase's
%% words, as a `che' clause runs to the end of its piece, and each writer
%% puts its own words before it: Spanish its `de que', Italian `che',
%% English `that'.
%% -- and after its last comma it has adjuncts only: `... han mejorado con
%% el tiempo, los solistas de la Orquesta de Valencia ofrecerán un
%% concierto' offered the soloists as what the violins had improved, and
%% then `los' alone as their object pronoun, and either way the main clause
%% was left with nobody to offer the concert. A phrase after the comma
%% begins the next clause, so the front ends before it.
tr_np(foreign, Words, ncl(NP, S)) :-
    append(Core, [P, W|Rest], Words), Core \== [], Rest \== [],
    tr_clause_opener(foreign, [P, W]), !,
    tr_object_phrase(foreign, Core, NP),
    tr_read_nested(foreign, Rest, none, S),
    \+ ( S = s(_, _, _, Cs), append(_, [sep|After], Cs), \+ memberchk(sep, After),
         member(C, After), \+ tr_adjunct(C) ).
tr_np(Side, Words, rc(NP, Role, S)) :-
    once(( member(w(RW, _), Words), tr_relative_word(Side, RW) )),    % no split is worth trying without one
    append(Core, Rest, Words), Core \== [],
    tr_relative_start(Side, Rest),
    \+ ( member(w(R0, _), Core), tr_relative_word(Side, R0) ),
    %% a clitic that replaces a noun is that noun's place, never a pronoun
    %% the clause is about: `lo que hace' is what it does (the phrase a
    %% noun replacer opens, below), and read as `him that' it came out `Him
    %% that is to discredit the research ago'
    \+ ( Side == foreign, Core = [Q1], Q1 = w(C1, _), tr_clitic(normal, C1), tr_noun_replacer(foreign, Q1) ),
    tr_relative_clause(Side, Rest, Role, S),
    tr_object_phrase(Side, Core, NP), !.
%% ... AND `CHE' STRAIGHT AFTER THE NOUN, WITH A CLAUSE THAT HAS ITS OWN
%% SUBJECT AND ITS OWN OBJECT: `della notizia che finalmente il fondo Veba e
%% Fiat hanno raggiunto l'accordo' is the news THAT they reached it. Such a
%% clause leaves no gap for a relative to fill, so it is no relative clause
%% (tr_relative_clause/4 says so of the object) -- it is the noun's own, and
%% Spanish writes it `la noticia de que'.
%% -- AND TWO CHEAP TESTS COME BEFORE THE READ, because the read is the rest
%% of the sentence and this is asked of every phrase with a `che' in it: the
%% phrase before it ends in a noun, and the clause's subject stands first,
%% after its adverbs. Without them `los violonchelos que se exponen ...' read
%% every word after `que' to the end of Valencia's last sentence, 28 s to 44.
tr_np(foreign, Words, ncl(NP, S)) :-
    append(Core, [W|Rest], Words), Core \== [], Rest \== [],
    tr_that_here(foreign, W), W = w(T, _), tr_relative_word(foreign, T),
    \+ ( member(w(R0, _), Core), tr_relative_word(foreign, R0) ),
    last(Core, H), tr_is(foreign, H, noun),
    tr_subject_first(Rest),
    tr_object_phrase(foreign, Core, NP),
    tr_read_nested(foreign, Rest, none, S),
    S = s(_, Su, _, Cs), Su \= null(_, _), Su \== none, memberchk(obj(_), Cs), !.

%% a clause whose subject stands first: after its adverbs, a determiner, a
%% name or a count
tr_subject_first([W|Ws]) :- tr_plain_adverb(foreign, W), !, tr_subject_first(Ws).
tr_subject_first([W|_]) :- tr_determiner(foreign, W, _, _), !.
tr_subject_first([W|_]) :- tr_name_word(foreign, W), !.
tr_subject_first([W|_]) :- tr_count_word(foreign, W).
%% THE MOST AWAITED BY THE FANS: `una ejemplar escena de la locura, la más
%% esperada por los aficionados' -- an article, the word for `more' and a
%% participle with its agent, the scene's noun said once. The article made
%% no phrase with `más' after it, so `la' was read as the pronoun `her' and
%% put before the verb of the clause. The phrase is the article's with its
%% noun left out, and the participle carries the degree the article makes
%% of it, pdeg(Degree) among its complements: `la più attesa dagli
%% appassionati', `the one most awaited by the fans'.
tr_np(foreign, [D, w(M, _), w(P, PC)|Rest], rel(np(det(DK, DL, D), none, [], elided(G), Number), L, Comps)) :-
    tr_degree_word(M),                                 % the rare word first: this is asked of every phrase
    tr_determiner(foreign, D, DL, DK), DK == article, \+ tr_standalone_det(foreign, D),
    tr_participle_here(foreign, P, L), \+ tr_is(foreign, w(P, lower), adjective),
    tr_det_gender(foreign, D, DL, G, Number), tr_participle_agrees(P, Number),
    ( Rest == [] -> Comps0 = [] ; tr_reduced_agent(foreign, Rest, Comps0) ),
    tr_degree_of(foreign, det(DK, DL, D), Degree),
    tr_rel_case(PC, [pdeg(Degree)|Comps0], Comps), !.
%% AN ADVERB BETWEEN A NOUN AND ITS PARTICIPLE IS THE PARTICIPLE'S: `en
%% sesiones a puerta cerrada centradas en las consecuencias' are sessions held
%% behind closed doors and centred on the consequences. The phrase ended at
%% the adverb, and the participle after it was said of the sentence's subject
%% and agreed with it, `centrati'. The adverb travels as padv/1, and every
%% writer puts it BEFORE the participle, where the source had it: written
%% after it as an ordinary complement, `un mes de Febrero muy apretado' came
%% out `stretto molto', where 1.8.8 had read the intensifier and written
%% `molto stretto'.
tr_np(foreign, Words, rel(NP, L, [padv(A)|Comps])) :-
    append(Core, [A, w(P, PC)|Rest], Words), Core = [_|_],
    A = w(_, _), tr_plain_adverb(foreign, A), \+ tr_is(foreign, A, preposition),
    tr_participle_here(foreign, P, L), \+ tr_is(foreign, w(P, lower), noun),
    tr_headed(foreign, Core),
    tr_object_phrase(foreign, Core, NP), NP \= rel(_, _, _), \+ tr_clause_phrase(NP),
    ( Rest == [] -> Comps0 = [] ; tr_ptc_complements(foreign, L, Rest, Comps0) ),
    tr_rel_agreement(foreign, P, NP, Comps0, Comps1), tr_rel_case(PC, Comps1, Comps), !.
%% A PARTICIPLE AFTER A RELATIVE CLAUSE IS THE CLAUSE'S: `lo que los hace tan
%% deseados' makes them so desired, and read as the phrase's reduced relative
%% it was `the one that makes them, so desired'. A phrase that ends in a
%% clause takes no participle after it; the clause reads it.
tr_clause_phrase(rc(_, _, _)) :- !.
tr_clause_phrase(nrc(_, _, _)) :- !.
tr_clause_phrase(ell(_, _, _, rel(_, _))) :- !.
tr_adverb_before_participle(foreign, PW, [A, w(P, _)|_]) :-
    A = w(_, _), \+ tr_is(foreign, A, preposition),
    member(X, PW), tr_is(foreign, X, noun),
    tr_participle_here(foreign, P, _), \+ tr_is(foreign, w(P, lower), noun), !.
%% THE WORD FOR `more' BETWEEN A NOUN AND ITS PARTICIPLE IS THE PARTICIPLE'S
%% DEGREE: `con una adhesión más limitada, más contenida' is a more limited
%% adherence. `más' is also the preposition `plus', so the phrase ended at
%% it, and the participle after it was said of the sentence's subject and
%% agreed with it, `più limitati'. The phrase runs on over the pair, and
%% tr_np/3 reads it as the reduced relative with pdeg/1 that `la más
%% esperada' already is -- a comparative after an indefinite article, a
%% superlative after a definite one, which is what the article says of an
%% adjective too.
tr_degree_before_participle(foreign, PW, [w(M, _), w(P, _)|_]) :-
    tr_degree_word(M),                                 % the rare word first: asked at every boundary
    member(X, PW), tr_is(foreign, X, noun),
    tr_participle_here(foreign, P, _), \+ tr_is(foreign, w(P, lower), noun), !.
%% (the lesson's word for `more' is looked for first: tr_np/3 is asked of
%% every word list a phrase might be, and walking each one for a degree
%% word cost the controls 1.2 million inferences in one sentence)
tr_np(foreign, Words, rel(NP, L, Comps)) :-
    once(( tr_solve(begin(DW, comparative)), memberchk(w(DW, _), Words) )),
    append(Core, [w(M, _), w(P, PC)|Rest], Words), Core = [_|_],
    tr_degree_word(M),
    tr_participle_here(foreign, P, L), \+ tr_is(foreign, w(P, lower), noun),
    \+ tr_is(foreign, w(P, lower), adjective),         % an adjective is tr_degrees/4's to fold
    tr_headed(foreign, Core),
    tr_object_phrase(foreign, Core, NP), NP = np(Det, _, _, _, _),
    ( Rest == [] -> Comps0 = [] ; tr_ptc_complements(foreign, L, Rest, Comps0) ),
    tr_degree_of(foreign, Det, Degree),
    tr_rel_agreement(foreign, P, NP, [pdeg(Degree)|Comps0], Comps1), tr_rel_case(PC, Comps1, Comps), !.
tr_np(Side, Words, rel(NP, L, Comps)) :-
    append(Core, [w(P, PC)|Rest], Words), Core \== [],
    %% a clitic heads nothing: `la tesi' is the thesis, never `her, tended'
    \+ ( Side == foreign, Core = [w(C1, _)], tr_clitic(normal, C1) ),
    %% ... and a word that replaces the noun is no phrase of its own before a
    %% participle: `quello guidato dal magnate' is the one the tycoon led,
    %% the ellipsis read further down, and taken here it was the pronoun
    %% `that', led
    \+ ( Side == foreign, Core = [Q1], tr_noun_replacer(foreign, Q1) ),
    %% ... nor does an article alone before a word that is a NOUN as well as
    %% a participle: `delle coperte' is blankets, not `the covered ones'
    \+ ( Core = [D1], tr_determiner(Side, D1, _, _), tr_is(Side, w(P, lower), noun) ),
    %% ... nor anything with no noun of its own before one: `a doble partido'
    %% is a two-legged match, `partido' the noun, and read as `double, split'
    %% the adjective was a noun by its place and the match a participle
    \+ ( tr_is(Side, w(P, lower), noun), \+ tr_headed(Side, Core) ),
    %% ... nor a bare count before a word that is a noun too: `una media de 22
    %% empleados por empresa' is twenty-two employees, and read as the number
    %% and the participle of `emplear' it came out `22 impiegato' (a
    %% percentage is no count: `del 41,5% detenuta dal fondo' stays)
    \+ ( Core = [w(Nm, _)], tr_digits(Nm), \+ tr_percent(Nm), tr_is(Side, w(P, lower), noun) ),
    %% ... nor a word shortened to stand before a noun: `en mal estado' is in
    %% bad shape, and `mal' is `malo' there and nothing else
    \+ ( Side == foreign, Core = [w(A1, _)], tr_solve(apocope_of(A1, _)) ),
    tr_participle_here(Side, P, L),
    %% a participle the lesson calls an ADJECTIVE too, with no agent after
    %% it, is the adjective: `la donna dispersa' is missing, and read as the
    %% participle of `disperdere' she had been dispersed
    \+ ( Rest == [], tr_is(Side, w(P, lower), adjective) ),
    %% ... nor a determiner and its adjectives, with no agent after: `el
    %% mejor sentido del término' is the best sense, and read as the best
    %% one, felt, it came out `il migliore sentito' (asked of a participle
    %% only: asked of every last word, it cost Livata's sentences 3 %)
    \+ ( Rest == [], Core = [D2, _|_], tr_determiner(Side, D2, _, _), tr_is(Side, w(P, lower), noun),
         Core = [_|As2], forall(member(A2, As2), ( A2 = deg(_, _) ; A2 = w(M2, _), ( tr_is(Side, A2, adjective) ; Side == foreign, tr_degree_word(M2) ) )) ),
    tr_object_phrase(Side, Core, NP), NP \= rel(_, _, _), \+ tr_clause_phrase(NP),
    (   Rest == []
    ->  Comps0 = []
    ;   tr_ptc_complements(Side, L, Rest, Comps0)
    ),
    tr_rel_agreement(Side, P, NP, Comps0, Comps1), tr_rel_case(PC, Comps1, Comps), !.
%% A PARTICIPLE THAT DOES NOT AGREE WITH THE NOUN BEFORE IT AGREES WITH A
%% NOUN FURTHER BACK: `la partecipazione del 41,5% detenuta dal fondo' -- the
%% share is held, and the percentage between them is masculine. The IR has
%% no phrase of `di' inside a phrase, so the relative hangs on the nearest
%% noun; the gender the source gave the participle travels with it,
%% agr(Gender) among its complements, and the writer agrees with that.
tr_rel_agreement(foreign, P, np(_, _, _, w(NW, _), _), Cs, [agr(PG)|Cs]) :-
    ( tr_solve(feminine(P)) -> PG = feminine ; PG = masculine ),
    tr_lexeme(foreign, NW, L, _), tr_gender(L, NG),
    ( NG == none -> PG == feminine ; NG \== PG ), !.            % a percentage has no gender to agree with
%% ... and a NAME has no gender to agree with, so the participle's own goes:
%% `l'isola di Ustica "proibita"' -- the island is banned, and the noun
%% nearest the participle is the name
tr_rel_agreement(foreign, P, name(_), Cs, [agr(feminine)|Cs]) :- tr_solve(feminine(P)), !.
%% ... AND IN NUMBER: `la lista delle priorità fissata dal governo' -- the
%% list is set, singular, and `priorità' is plural by its article, so
%% `fijadas' agreed with the priorities. The participle's own number
%% travels as agrn(Number) when it is not the phrase's.
tr_rel_agreement(foreign, P, np(_, _, _, w(_, _), N), Cs, [agrn(PN)|Cs]) :-
    tr_participle_number(P, PN), PN \== N, !.
tr_rel_agreement(_, _, _, Cs, Cs).

%% the participle's own case, where it is not plain: the quotation marks of
%% `l'isola di Ustica "proibita"' travel with it and go back round it
tr_rel_case(lower, Cs, Cs) :- !.
tr_rel_case(upper, Cs, Cs) :- !.
tr_rel_case(C, Cs, [pcase(C)|Cs]).

%% ALL THE NIGHT: `le ricerche sono proseguite tutta la notte', `toda la
%% noche'. A word the lesson says means `all', before a determiner, is no
%% pronoun standing alone but the phrase's own, and it agrees with the
%% phrase's noun -- read as the pronoun it also is, it was `everything' and
%% came out `todo la noche'.
tr_np(Side, [w(T, TC), D|Ws], all(w(T, TC), NP)) :-
    tr_all_word(Side, T), tr_determiner(Side, D, _, _),
    tr_np(Side, [D|Ws], NP), NP = np(_, _, _, _, _), !.
tr_np(Side, [w(W, upper)], name(W)) :- \+ tr_known_word(Side, W), !.
%% A CAPITALISED NOUN STANDING ALONE AS A PHRASE INSIDE A SENTENCE IS A NAME,
%% even one the lesson knows: `en Valencia' is the city, where the
%% vocabulary's `valencia' is the chemist's valency and came out `Valenzia',
%% and `di Pale' is the town the dictionary made `Retablos'. The head of a
%% sentence is lowered before this when the lesson knows the word, so what
%% arrives capitalised is inside the sentence; a common noun there has its
%% article (`dei Paesi', `all'Arma'), which this one-word phrase has not.
%% Only on the lesson's side -- English capitalises its days and months --
%% and never a pronoun.
%% ... but never a word of several words the lesson states as one: `de
%% Asuntos Exteriores' is the ministry, and a town is not named with a
%% phrase the lesson knows (tr_multi/3 joined it)
%% ... AND ONE THE LESSON KNOWS AS AN ADJECTIVE: `Alto Representante Civil
%% en Bosnia' -- `bosnia' is the feminine of Bosnian to the vocabulary, and
%% read as an adjective with its noun left out it came out `in Bosniaco'
tr_np(foreign, [w(W, upper)], name(W)) :-
    \+ sub_atom(W, _, _, _, ' '),
    ( tr_is(foreign, w(W, lower), noun) ; tr_is(foreign, w(W, lower), adjective) ),
    \+ tr_is(foreign, w(W, lower), pronoun), !.
%% SEVERAL CAPITALISED WORDS NO LESSON KNOWS ARE ONE NAME, bare as well as
%% after a determiner: `Alexia Canestrari ha raccontato', `a Sky Tg24'.
%% What kept a bare run apart was `Sabato Mladic' -- a day and a surname --
%% and `sabato' is a word the lesson KNOWS, so a run of words it knows none
%% of cannot be that. The name is written as the source spelled its words.
%% A DATE IS A PHRASE: the day is its count and the month its noun, which
%% is how `il 20 gennaio' already read -- and the YEAR after the month is
%% the phrase's own, app(Phrase, year, Year), where it was an adjective in
%% digits and refused the phrase. Which nouns are months is the lesson's
%% (`"gennaio" is a month.'), and so is the word a language joins a date's
%% parts with (`The word "de" joins the date.': `el 20 de enero de 2014'),
%% which comes off before the phrase is read.
tr_np(Side, Words, app(NP, year, w(Y, lower))) :-
    append(Core0, [w(Y, _)], Words), tr_digits(Y), \+ tr_percent(Y),
    ( append(Core, [J], Core0), tr_date_join(Side, J) -> true ; Core = Core0 ),
    last(Core, M), tr_month(Side, M),
    tr_np(Side, Core, NP), !.
%% A NUMBER AFTER A NOUN IS ITS LABEL: `el próximo día 14' is the day
%% numbered fourteen -- a date with its month left out, which a newspaper
%% writes when the month is this one. It travels as app(Phrase, label,
%% Number) and every writer puts the number back after the noun. Only after
%% a noun the lesson knows, so `el 20' and a count before its noun read as
%% they did.
tr_np(Side, Words, app(NP, label, w(N, NC))) :-
    append(Core, [w(N, NC)], Words), Core = [_, _|_], tr_digits(N), \+ tr_percent(N),
    last(Core, LW), tr_is(Side, LW, noun),
    tr_np(Side, Core, NP), NP = np(_, _, _, _, _), !.
%% A TITLE BEFORE A NAME IS A PHRASE: `monsignor Salvatore Cassisa',
%% `Monsignor Cassisa'. The lesson says which nouns are titles -- `"monsignore"
%% is a title.' -- because a title takes no article before a name in either
%% of the lesson's languages, and nothing else in the phrase says where it
%% begins. The name's words join as one, apposed to the title as `il
%% presidente Scalfaro' has its name, and each writer puts the title first.
tr_np(Side, [w(TW, _)|Ns], np(none, none, [w(A, upper)], w(TW, lower), singular)) :-
    Ns \== [], tr_title_word(Side, TW),
    %% every capitalised word after the title is the name's, one the lesson
    %% knows included: `Salvatore' is a rescuer in the vocabulary
    forall(member(N, Ns), N = w(_, upper)), !,
    findall(C, ( member(w(X, _), Ns), tr_cap(X, C) ), Cs), atomic_list_concat(Cs, ' ', A).
%% (a word the lesson knows only as a VERB's form is a name's too, in a run
%% with a name in it: `interpretado por Carlos Cosías' -- `cosías' is what
%% `coser' says to one person, and the singer was no name at all)
tr_np(Side, [W1, W2|Ws], name(N)) :-
    forall(member(W, [W1, W2|Ws]), tr_name_part(Side, W)),
    once(( member(W0, [W1, W2|Ws]), tr_name_word(Side, W0) )), !,
    findall(C, ( member(w(X, _), [W1, W2|Ws]), tr_cap(X, C) ), Cs), atomic_list_concat(Cs, ' ', N).
%% ... AND A NAME'S LATER WORDS MAY BE WORDS THE LESSON KNOWS, after a first
%% word no lesson does: `apoyará a Javier Solana' -- `solana' is a sunny
%% slope to the vocabulary, and the object was refused as a name and a
%% noun. A known FIRST word is what keeps `Sabato Mladic' a day and a
%% surname, and it still does.
tr_np(foreign, [W1, W2|Ws], name(N)) :-
    tr_name_word(foreign, W1),
    forall(member(W, [W2|Ws]), ( W = w(_, upper), ( tr_name_part(foreign, W) ; tr_is(foreign, W, noun) ) )), !,
    findall(C, ( member(w(X, _), [W1, W2|Ws]), tr_cap(X, C) ), Cs), atomic_list_concat(Cs, ' ', N).
tr_name_part(Side, W) :- tr_name_word(Side, W), !.
tr_name_part(foreign, W) :-
    W = w(X, upper), \+ tr_is(foreign, W, noun), \+ tr_is(foreign, W, adjective),
    \+ tr_is(foreign, W, preposition), \+ tr_determiner(foreign, W, _, _), tr_verb_form_word(X), !.
%% ENGLISH PUTS A BARE PARTICIPLE BEFORE ITS NOUN, and it is read there as
%% the reduced relative the writer made of it (tr_np_out/5): `the imposed
%% house' is `la casa imposta'. Only right before the noun, and never a word
%% a lesson gives as an adjective, which `tired' is.
tr_np(english, Words, rel(NP, L, [])) :-
    append(Pre, [w(P, PC), N], Words), Pre \== [],
    en_participle(P, L), \+ tr_is(english, w(P, PC), adjective), \+ en_own(P),
    append(Pre, [N], Words1), tr_np(english, Words1, NP), NP = np(_, _, _, w(_, _), _), !.
tr_np(Side, Words00, np(Det, Num, AdjsM, Noun, Number)) :-
    tr_tail_name(Side, Words00, Words0),
    %% A POSSESSIVE AFTER AN ARTICLE IS THE PHRASE'S DETERMINER: `la sua
    %% casa' is his house, which Spanish writes `su casa' and Italian, whose
    %% lesson says `The article "il" takes the possessive', with the article
    %% back in front. Read as an adjective it was `la su identidad', and it
    %% crossed by the adjective's meaning -- `sua' is `hers' as one
    (   Side == foreign, Words0 = [A0, P0|Ws1], Ws1 \== [],
        tr_determiner(Side, A0, _, article), tr_determiner(Side, P0, PL, possessive)
    ->  Det = det(possessive, PL, P0), Words1 = Ws1
    %% A DETERMINER THE LESSON CALLS AN ADVERB TOO, BEFORE A NUMBER, IS THE
    %% COUNT'S ADVERB: `unos 980 trabajadores' is about 980 of them (`The
    %% adverb "unos" means "about".'), and read as the article it came out
    %% `dei 980 lavoratori', which no Italian writes
    ;   Words0 = [D, M|Ws1], Ws1 \== [], D = w(_, _), tr_is(Side, D, adverb), tr_is(Side, M, number),
        tr_determiner(Side, D, _, _)
    ->  Det = none, Words1 = Words0
    ;   Words0 = [D|Ws1], tr_determiner(Side, D, DL, DK), Ws1 \== []
    ->  Det = det(DK, DL, D), Words1 = Ws1
    ;   Det = none, Words1 = Words0
    ),
    %% the count is the number before the noun -- at the head of what is left
    %% after the determiner, or, since 1.6.14, ANYWHERE among the adjectives
    %% before it: `solo due anni' is `only two years', and with the number
    %% left among them the writer asked the lesson for an ADJECTIVE meaning
    %% `two' and the phrase could not be written at all
    %% ... and a count may carry an adverb before it or be two numbers
    %% joined: `a meno 5 gradi' (at minus five degrees), `con oltre 50 mezzi',
    %% `bambini di 4 e 5 anni'
    %% (the count's adverb is NA and not A: the forall below names its own
    %% A, and with the adverb bound to it `member(A, Adjs)' matched nothing,
    %% so every adjective after such a count passed unchecked)
    (   Words1 = [NA, M|Ws2], NA = w(_, _), tr_is(Side, NA, adverb), \+ tr_is(Side, NA, adjective),
        tr_is(Side, M, number), Ws2 \== []
    ->  Num = adv_num(NA, M), Words2 = Ws2
    ;   Words1 = [M1, NC, M2|Ws2], tr_is(Side, M1, number), tr_coord(Side, NC), tr_is(Side, M2, number), Ws2 \== []
    ->  Num = nums(M1, NC, M2), Words2 = Ws2
    ;   Words1 = [M|Ws2], tr_is(Side, M, number), Ws2 \== []
    ->  Num = M, Words2 = Ws2
    ;   append(Pre1, [M|Post1], Words1), tr_is(Side, M, number), Post1 \== [],
        forall(member(X1, Pre1), tr_adj_word(Side, X1))
    ->  Num = M, append(Pre1, Post1, Words2)
    ;   Num = none, Words2 = Words1
    ),
    Words2 \== [],
    tr_date_day(Side, Num, Words2, Words2d),
    tr_intensify(Side, Words2d, Words3),
    tr_noun(Words3, Side, Noun0, Adjs0),
    %% A COORDINATOR AMONG THE ADJECTIVES JOINS TWO OF THEM, never one to a
    %% noun: `donna e bimbi scomparsi' is two phrases, and read as one whose
    %% adjectives were `and' and `children' it was a singular subject, which
    %% the plural headline participle before it (`ritrovati') refused
    \+ ( append(_, [Co, X|_], Adjs0), tr_coord(Side, Co), X = w(_, _),
         tr_is(Side, X, noun), \+ tr_is(Side, X, adjective) ),
    %% ... nor one standing NEXT TO the noun, which joins an adjective to the
    %% noun itself: `Egoista e vigliacca, continuerà ...' is selfish and
    %% cowardly, a front that says what the subject is (tr_read0/4), and read
    %% as the noun `egoist' with `and' and `cowardly' for adjectives it was the
    %% subject of `continuerà' -- the clause's own subject, which nobody named
    \+ ( ( append(_, [Noun0, Co2|_], Words3) ; append(_, [Co2, Noun0|_], Words3) ), Co2 = w(_, _), tr_coord(Side, Co2) ),
    tr_degree_of(Side, Det, Degree), tr_degrees(Side, Degree, [Noun0|Adjs0], [Noun|Adjs]),
    %% `The' alone is no phrase, whatever `el' means -- UNLESS the lesson
    %% also calls the word a noun or a pronoun, which is what `uno' is in
    %% `uno dei paesi': the masculine article and the word for `one'
    \+ ( tr_determiner(Side, Noun, _, _), \+ tr_is(Side, Noun, noun), \+ tr_is(Side, Noun, pronoun) ),
    \+ ( \+ tr_is(Side, Noun, noun), tr_is(Side, Noun, verb) ),   % nor is a verb's form the lesson calls no noun (`son grandes')
    \+ ( \+ tr_is(Side, Noun, noun), tr_is(Side, Noun, adverb) ), % nor a word known only as an adverb (`Después, en ...')
    %% nor an AUXILIARY or a modal the lesson calls no noun: `han mejorado'
    %% after a relative clause read as a phrase `han' with the participle
    %% on it, `the has improved', and the clause ran on past its own verb
    \+ ( \+ tr_is(Side, Noun, noun), ( tr_is(Side, Noun, auxiliary) ; tr_is(Side, Noun, modal) ) ),
    %% nor a CONJUNCTION the lesson calls nothing a phrase can be: `senza
    %% rendersi conto che, come il loro predecessore, non importa ...' read
    %% `che' as a phrase, `what', and the rest as a clause about how
    \+ ( Side == foreign, tr_is(Side, Noun, conjunction),
         \+ tr_is(Side, Noun, noun), \+ tr_is(Side, Noun, pronoun), \+ tr_is(Side, Noun, adjective) ),
    %% nor an ADJECTIVE that is no noun after an article: `l'altra' is the
    %% other one, a noun left out, which the clause further down reads and
    %% writes agreeing -- taken for the noun here it came out `el otro'
    \+ ( Det = det(article, _, _), \+ tr_is(Side, Noun, noun), tr_is(Side, Noun, adjective) ),
    forall(member(A, Adjs), ( tr_adj_word(Side, A) ; tr_apposed_name(Det, Words0, A) )),
    \+ ( last(Adjs, LA), LA = w(_, _), tr_coord(Side, LA) ),       % a conjunction joins two adjectives, never ends them
    %% AN ADVERB THAT IS AN ADJECTIVE'S FORM TOO, AFTER THE NOUN AND IN THE
    %% OTHER GENDER, IS THE ADVERB: `il giorno prima caricò i compagni' is the
    %% day before, and read with `prima' -- first, feminine -- for an
    %% adjective of the masculine `giorno' it was the first day, which loaded
    %% the team-mates
    \+ ( Side == foreign, append(_, [Noun|After], Words3), member(A, After), A = w(_, _),
         tr_is(Side, A, adverb), tr_is(Side, A, adjective), tr_genders_differ(Noun, A) ),
    Noun = w(NW, _),
    %% the noun's number by the reading of it that IS a noun: `houses' is a
    %% verb's form too (to house), and known so before it is a plural
    ( tr_lexeme(Side, NW, NL, Number0), tr_class(Side, NL, noun) -> true ; tr_lexeme(Side, NW, _, Number0) ),
    tr_invariable_number(Side, NW, Det, Adjs, Number0, Number),
    %% AN ADJECTIVE THE SOURCE SET BEFORE ITS NOUN STAYS BEFORE IT, where the
    %% language puts adjectives after the noun and so a word before one was a
    %% choice: `una paradójica educación familiar', `la sacrosanta
    %% institución'. It travels as pre(Adjective) and the lesson's writer
    %% puts it before the noun whatever its rule says; English puts every
    %% adjective there anyway.
    (   Side == foreign, tr_holds(follow(_, noun)), append(PreWs, [Noun|_], Words3), PreWs \== []
    ->  tr_mark_pre(Side, Adjs, PreWs, AdjsM)
    ;   AdjsM = Adjs
    ), !.

%% two words each in a gender the lesson states, and not in one: `giorno'
%% and `prima' -- never a word with no gender of its own, and never the
%% degree word, which has neither a gender nor a number (`i paesi più
%% ricchi')
tr_genders_differ(N, A) :-
    N = w(NW, _), A = w(AW, _),
    tr_lexeme(foreign, NW, NL, _), tr_gender(NL, GN), GN \== none,
    tr_lexeme(foreign, AW, AL, _), tr_gender(AL, GA), GA \== none, GN \== GA,
    \+ tr_aside_agrees(N, A), !.

%% A NOUN THAT IS ITS OWN PLURAL TAKES ITS NUMBER FROM WHAT AGREES WITH IT:
%% `unità cinofile' is canine UNITS, and `unità' read first as the singular
%% it also is came out `unidad canina'. A determiner or an adjective the
%% lesson knows only in the plural says which.
tr_invariable_number(Side, NW, Det, Adjs, singular, plural) :-
    tr_lexeme(Side, NW, _, plural),
    (   Det = det(_, _, DW), DW = w(_, _), tr_plural_only(Side, DW) -> true
    ;   member(A, Adjs), A = w(_, _), tr_plural_only(Side, A)
    ), !.
tr_invariable_number(_, _, _, _, N, N).

tr_plural_only(Side, w(W, _)) :- tr_lexeme(Side, W, _, plural), \+ tr_lexeme(Side, W, _, singular), !.

%% the day's join word comes off between the count and the month: `el 20
%% DE enero'
tr_date_day(Side, Num, [J, M], [M]) :- Num \== none, tr_date_join(Side, J), tr_month(Side, M), !.
tr_date_day(_, _, Ws, Ws).

%% the join word INSIDE a date ends no phrase: a day before it and a month
%% after it, or a month before it and a year after it
tr_date_inside(Side, PW, [J, N|_]) :-
    tr_date_join(Side, J), last(PW, P),
    (   P = w(D, _), tr_digits(D), tr_month(Side, N)
    ;   tr_month(Side, P), N = w(Y, _), tr_digits(Y)
    ), !.

%% a month: English's own twelve, or a word the lesson says is one
tr_month(english, w(W, _)) :- !, en_month(W).
tr_month(foreign, w(W, _)) :- tr_lexeme(foreign, W, L, _), tr_solve(month(L)), !.

%% the word the lesson joins a date's parts with; English has none
tr_date_join(foreign, w(J, _)) :- tr_solve(join(J, date)), !.

tr_mark_pre(_, [], _, []).
tr_mark_pre(Side, [A|As], Pre, [B|Bs]) :-
    ( A = w(_, _), memberchk(A, Pre), \+ tr_coord(Side, A) -> B = pre(A) ; B = A ),
    tr_mark_pre(Side, As, Pre, Bs).
%% AN ARTICLE BEFORE A NAME IS A PHRASE WHOSE NOUN IS THE NAME, and Italian
%% puts one there far more often than English does -- `la Tate Gallery', `la
%% Sidoti'. The clause above looks for a noun the lesson knows and a name is
%% the one word no lesson can know, so before this the whole phrase was
%% refused: `Evacuata la Gallery.' came back `unknown: []', a SHAPE refusal
%% with no shape missing.
%%
%% It is the ordinary phrase with `named(Gender, Words)' where the noun goes,
%% so the number, the determiner and every writer that takes a phrase apart
%% by np/5 are untouched -- and the NAME IS NOT CROSSED, which is the whole
%% point of it being a name.
%%
%% THE GENDER IS THE SOURCE ARTICLE'S, because a name has none of its own.
%% `la Tate Gallery' is feminine because the lesson calls `la' feminine, and
%% that gender travels in the IR so Spanish writes `la' and the participle of
%% a passive agrees (`La Tate Gallery e stata evacuata'). Read on the ENGLISH
%% side there is no gender to read, so the IR carries `none' and the lesson's
%% writer falls back to the masculine: `The Tate Gallery' into Italian is `Il
%% Tate Gallery', which is the cost and is stated rather than guessed at.
%%
%% Several capitalised words after the determiner are ONE name. Bare, they are
%% one only when the lesson knows none of them (tr_np/3 above), because
%% after a determiner the phrase's start is not in doubt and bare it is:
%% `Sabato Mladic' is a day and a surname.
%% ... AND A RUN WHOSE LAST WORD NO LESSON KNOWS is one too, when no word of
%% it is a noun the lesson knows: `el Van Gogh de la luthiere', where `van'
%% is the plural of a verb's form. A known noun keeps the ordinary reading,
%% so `la Casa Bianca' is still the white house.
tr_np(Side, [D|Ws], np(det(DK, DL, D), none, [], named(G, Ws), Number)) :-
    Ws \== [], tr_determiner(Side, D, DL, DK),
    (   forall(member(W, Ws), tr_name_word(Side, W)) -> true
    ;   Ws = [_, _|_], forall(member(W, Ws), W = w(_, upper)),
        last(Ws, WL), tr_name_word(Side, WL),
        \+ ( member(w(X, _), Ws), tr_is(Side, w(X, lower), noun) )
    ),
    tr_det_gender(Side, D, DL, G0, Number), tr_name_gender(Side, D, Ws, G0, G), !.
%% ... AND ADJECTIVES AFTER THE NAME: `L'Italia attuale ha le forme della
%% democrazia' was refused whole, the name taking no word after it. The
%% name's words and then adjectives the lesson knows, placed by each writer
%% where its language puts an adjective (`la Italia actual').
tr_np(foreign, [D|Ws0], np(det(DK, DL, D), none, Adjs, named(G, Ws), Number)) :-
    Ws0 = [W1, _|_], tr_name_word(foreign, W1),
    append(Ws, Adjs, Ws0), Ws \== [], Adjs \== [],
    forall(member(W, Ws), tr_name_word(foreign, W)),
    forall(member(A, Adjs), ( A = w(_, lower), tr_adj_word(foreign, A), tr_is(foreign, A, adjective) )),
    tr_determiner(foreign, D, DL, DK),
    tr_det_gender(foreign, D, DL, G0, Number), tr_name_gender(foreign, D, Ws, G0, G), !.

%% AN ELIDED ARTICLE SAYS NO GENDER -- `l'' is `lo' and `la' alike -- so a
%% name after one takes the gender the lesson states of it: `l'Italia',
%% `"italia" is feminine.' Without one it is the article's first reading.
tr_name_gender(foreign, w(DW, _), [w(N, _)|_], _, G) :-
    tr_solve(elision_of(DW, _)),
    ( tr_holds(feminine(N)) -> G = feminine ; tr_holds(masculine(N)) -> G = masculine ), !.
tr_name_gender(_, _, _, G, G).
%% ... AND ADJECTIVES MAY STAND BETWEEN THE DETERMINER AND THE NAME: `le più
%% canicolari Eolie', the most sweltering of the islands, had no reading at
%% all. Each stays before the name as the source set it (pre/1), a degree
%% word makes it a superlative as the article says, and every writer agrees
%% it with the gender the name carries.
%% (the run of name words at the END is the name, found once: tried at every
%% split of every phrase with a determiner, the reading cost Valencia's
%% sentence of names a quarter again)
tr_np(Side, [D|Ws0], np(det(DK, DL, D), none, AdjsM, named(G, Ws), Number)) :-
    Ws0 = [_, _|_], last(Ws0, WL), tr_name_word(Side, WL),
    reverse(Ws0, Rev), tr_name_run_rev(Side, Rev, RevNames, RevPre),
    %% (the adjectives' comma may stand before the name: `i nuovi, piccoli,
    %% meschini, Hitler', tr_adj_lists/3)
    ( RevPre = [w(',', acomma), LastPre|_] -> true ; RevPre = [LastPre|_] ),
    ( LastPre = deg(_, LA) -> true ; LA = LastPre ),
    tr_is(Side, LA, adjective),                                          % the word before the name
    tr_determiner(Side, D, DL, DK),
    reverse(RevNames, Ws), reverse(RevPre, Pre0),
    tr_degree_of(Side, det(DK, DL, D), Degree), tr_degrees(Side, Degree, Pre0, Pre),
    Pre = [P1|_], \+ ( P1 = w(_, _), tr_coord(Side, P1) ),
    forall(member(A, Pre), ( A \= w(_, _) -> tr_adj_word(Side, A)
                           ; A = w(',', acomma) -> true
                           ; \+ tr_coord(Side, A), tr_adj_word(Side, A), tr_is(Side, A, adjective) )),
    findall(B, ( member(A, Pre), ( Side == foreign, A = w(_, _), \+ tr_coord(Side, A) -> B = pre(A) ; B = A ) ), AdjsM),
    tr_det_gender(Side, D, DL, G0, Number), tr_name_gender(Side, D, Ws, G0, G), !.

tr_name_run_rev(Side, [W|Ws], [W|Ns], Rest) :- tr_name_word(Side, W), !, tr_name_run_rev(Side, Ws, Ns, Rest).
tr_name_run_rev(_, Ws, [], Ws).

%% A NAME'S FIRST WORDS MAY BE WORDS THE LESSON KNOWS: `dal giornalista rai
%% Salvatore Biazzo' is one man, and `Salvatore' is a saviour in the
%% vocabulary -- read as an adjective of the noun it crossed as `Salvador',
%% and `un libro Home Video' had two words where the apposed name takes one.
%% A run of capitalised words at the end of a phrase, after a word without a
%% capital, one of which no lesson knows, is one name, spelled as the source
%% spelled it, apposed to the noun as `il presidente Scalfaro' is (`video'
%% is a word of the lesson's; `la Casa Bianca', every word known, is still
%% the white house). APPOSED TO A NOUN, which the words before it must have:
%% after an article alone the run is the phrase's head, and `sul Monte
%% Livata' made one name of it, left the phrase no noun, and refused Livata's
%% second sentence -- 99.5 million inferences where 1.8.5 read it in 32
tr_tail_name(foreign, Words0, Words) :-
    append(Front, Run, Words0), Front = [_|_], Run = [_, _|_],
    last(Front, F), F = w(_, FC), FC \== upper,
    forall(member(X, Run), X = w(_, upper)),
    once(( member(L, Run), tr_name_word(foreign, L) )),
    once(( member(w(NW, _), Front), tr_is(foreign, w(NW, lower), noun) )), !,
    findall(C, ( member(w(X, _), Run), tr_cap(X, C) ), Cs), atomic_list_concat(Cs, ' ', N),
    append(Front, [w(N, upper)], Words).
tr_tail_name(_, Words, Words).

%% a word of a name: capitalised, and no lesson knows it
tr_name_word(Side, w(W, upper)) :- \+ tr_known_word(Side, W).

%% A NAME APPOSED TO A NOUN: `il presidente Scalfaro', `la Tate Gallery' the
%% other way round. It stands where an adjective stands and crosses as
%% ITSELF, which is what being a name means -- and only at the END of a
%% phrase that has a DETERMINER, because bare `Sabato Mladic' is a day and a
%% surname and nothing says where one ends.
%% ... after a determiner, or after a noun written with its capital: `Monte
%% Livata', `Regione Lazio' are one place each, with no article in front
tr_apposed_name(Det, Words, w(W, upper)) :-
    ( Det \== none -> true ; Words = [w(_, upper), _|_] ),
    last(Words, w(W, upper)).
tr_apposed_name(_, Words, w(W, appos)) :- last(Words, w(W, appos)).
%% ... AND ADJECTIVES MAY FOLLOW IT, on the lesson's side and after a
%% determiner: `il governo Dini successivo' is the Dini government that came
%% after. With the name held to the phrase's end the adjective was left
%% over as a complement of its own, and the reduced relative that ended on
%% that phrase lost its agent: `pubblicato dal giornale' came out `emitido
%% desde el diario', published FROM it.
tr_apposed_name(Det, Words, w(W, upper)) :-
    Det \== none,
    append(_, [w(W, upper)|After], Words), After = [_|_],
    forall(member(A, After), ( A = w(_, lower), tr_is(foreign, A, adjective) )), !.

%% the gender of the determiner a writer chose, where the phrase carried none
tr_written_gender(foreign, [o(DW, _)|_], G) :- tr_lexeme(foreign, DW, DL, _), tr_gender(DL, G), G \== none, !.
tr_written_gender(_, _, none).

%% the run of them at the head of a list, and what is left after it
tr_name_run([W|Ws], [W|Cs], Rest) :- tr_name_word(foreign, W), !, tr_name_run(Ws, Cs, Rest).
tr_name_run(Ws, [], Ws).

%% what a determiner says about a phrase whose noun cannot say it itself
tr_det_gender(english, _, _, none, singular) :- !.
tr_det_gender(foreign, w(DW, _), DL, G, Number) :-
    ( tr_lexeme(foreign, DW, DL, N0) -> Number = N0 ; Number = singular ),
    tr_gender(DL, G).

%% a participle of a verb the lesson gives, on either side
tr_participle_here(foreign, P, L) :- tr_solve(participle_of(P, L)), tr_known(foreign, L), !.

%% a participle's number: plural when the lesson states it as the plural of
%% its singular, as the builder does for every participle that inflects
tr_participle_number(P, plural) :- tr_solve(plural_of(P, _)), !.
tr_participle_number(_, singular).
tr_participle_here(english, P, L) :- en_passive_participle(P, L), !.

%% what may follow a reduced relative and belong to it: its agent, and
%% nothing else -- a phrase after it is the sentence's, not the participle's
%% ... and what follows the agent is the participle's too, when it is only
%% adjuncts: `i risultati raggiunti da Chrysler negli ultimi quattro anni e
%% mezzo' were reached by Chrysler IN those years, and with the agent held to
%% the end of the phrase `da Chrysler' was read as where they came from
%% ... or a NAME, which is what the participle says of its noun: `un violín
%% llamado Ex Von Szerdahely VieuxTemps' is the violin CALLED that. It
%% travels as the participle's object and is written back as itself.
%% After such a participle EVERY capitalised word is the name's, one the
%% lesson knows among them: `Ex' is the adjective `former' to the lesson,
%% and the violin is the `Ex Von Szerdahely VieuxTemps'.
tr_reduced_agent(Side, Ws, [obj(name(N))]) :-
    Ws = [w(_, upper)|_], tr_np(Side, Ws, name(N)), !.
tr_reduced_agent(Side, Ws, [obj(name(N))]) :-
    Ws = [w(_, upper), _|_], forall(member(W, Ws), W = w(_, upper)),
    member(W1, Ws), tr_name_word(Side, W1), !,
    findall(C, ( member(w(X, _), Ws), tr_cap(X, C) ), Cs), atomic_list_concat(Cs, ' ', N).
%% ... and a RANGE OF DAYS, which is when the participle holds: `l'isola di
%% Ustica "proibita" dal primo al 31 agosto'
tr_reduced_agent(Side, Ws, Cs) :-
    Ws = [P|Rest], tr_is(Side, P, preposition), tr_date_range(Side, Rest),
    tr_complements(Side, Ws, Cs), Cs \== [], tr_adjuncts(Cs), \+ memberchk(sep, Cs), !.
tr_reduced_agent(Side, Ws, [by(NP)|Cs]) :-
    Ws = [P|Rest], tr_is(Side, P, preposition), tr_means_by(Side, P), \+ tr_bare_start(Side, Rest),
    \+ tr_date_range(Side, Rest),
    tr_phrase_words(Side, Rest, PW, Rest2), PW \== [], tr_phrase_np(Side, PW, NP),
    (   Rest2 == [] -> Cs = []
    ;   tr_complements(Side, Rest2, Cs), Cs \== [], forall(member(C, Cs), tr_adjunct(C))
    ).

%% WHAT FOLLOWS A PARTICIPLE STANDING AFTER ITS NOUN: the agent and its
%% adjuncts (tr_reduced_agent/3) -- BUT A VERB WHOSE PERFECT TAKES THE COPULA
%% HAS NO PASSIVE, SO NO AGENT: `uno uscito da elezioni generali' came FROM
%% the elections, and read as the agent it was `salido por elecciones', gone
%% out by them. The lesson says which verbs those are -- `"è" is the
%% auxiliary of "esce".', a line since 1.6.17 -- and the phrase after the
%% preposition is an ordinary one, pp/2.
%% NOT `intransitive', which the first cut asked: that says a verb MAY take
%% no object (1.6.8's inversion), and `"domina" is intransitive.' made the
%% opera review's `la función dominada por la excepcional Anderson' come out
%% `dominata per', the agent lost. `dominare' takes `avere'.
tr_ptc_complements(Side, L, [P|R2], [pp(P, NP)|Cs]) :-
    Side == foreign, tr_unaccusative(L), tr_is(Side, P, preposition), !,
    tr_phrase_rest(Side, R2, NP, R3),
    (   R3 == [] -> Cs = []
    ;   tr_complements(Side, R3, Cs), Cs \== [], forall(member(C, Cs), tr_adjunct(C))
    ).
tr_ptc_complements(Side, _, Rest, Comps) :- tr_reduced_agent(Side, Rest, Comps).
tr_unaccusative(L) :- tr_solve(auxiliary_of(A, L)), tr_copula_lexeme(A), !.

%% A BARE NOUN IN THE SINGULAR IS NOBODY WHO DID ANYTHING: `una media de 22
%% empleados por empresa' is twenty-two to a company, and `por' is `by' as
%% well, so `empleados' was taken for the participle and the company for
%% who employed them -- `22 impiegato da impresa'. An agent has a
%% determiner, a number or a name (`por la consultora', `dai soldati', `da
%% Chrysler'); a noun alone after the word, lower case and singular, says
%% how many or how -- `por empresa', `por unanimidad' -- and reads as the
%% phrase of any other preposition.
%% -- and a noun that is a verb's form as well may begin a clause: `juegan
%% muy ordenados y SON muy competitivos' is two clauses, and `son' is a
%% sound too, so read as one the second verb came out `suono'
tr_bare_start(Side, [W|_]) :-
    W = w(X, lower), \+ tr_determiner(Side, W, _, _), \+ tr_is(Side, W, number), \+ tr_is(Side, W, pronoun),
    tr_is(Side, W, noun), \+ tr_is(Side, W, adjective), \+ tr_is(Side, W, verb),
    tr_lexeme(Side, X, _, singular), !.

%% A DEGREE IS A DEGREE OF AN ADJECTIVE, and the two sides mark it in
%% different places. The lesson's language puts a WORD in front -- `piu
%% ricco', `mas rico' -- which the lesson names (`The word "piu" begins the
%% comparative.', the shape `The word "per" begins the purpose' already
%% has), and that one word spells the comparative and the superlative
%% alike: what tells them apart is the ARTICLE, `il paese piu ricco' being
%% the richest country and `un paese piu ricco' a richer one. English marks
%% it on the adjective itself, richer and richest, with `more' and `most'
%% for the words its endings will not take.
%%
%% So it travels as deg(Degree, w(Word, Case)) among the adjectives, and
%% the DEGREE is what English needs: the foreign writer spells both the
%% same and lets its own article say which.
tr_degrees(_, _, [], []).
tr_degrees(english, D, [w(M, _), w(W, C)|Ws], [deg(D1, w(W, C))|Os]) :-
    en_degree_marker(M, D1), tr_is(english, w(W, C), adjective), !,
    tr_degrees(english, D, Ws, Os).
%% ... and `more'/`most' alone is NOT one, or `more bread' would read as
%% the comparative of `much' and cross as a word. The pair above is the
%% only reading they have here.
tr_degrees(english, D, [w(W, C)|Ws], [deg(D1, w(L, C))|Os]) :-
    \+ en_degree_marker(W, _), en_degree_word(W, D1, L), !,
    tr_degrees(english, D, Ws, Os).
%% ... AND A WORD THAT IS A COMPARATIVE BY ITSELF: `el mejor de los
%% intérpretes' is the best of them, and the dictionary gives `mejor' only
%% as `good', so it came out `il buono degli interpreti'. The lesson says
%% which words these are -- `"mejor" is the comparative of "bueno".' -- and
%% the degree travels on the plain adjective, as the one `más' marks does.
tr_degrees(foreign, D, [w(W, C)|Ws], [deg(D, w(B, C))|Os]) :-
    tr_lexeme(foreign, W, L, _), tr_solve(comparative_of(L, B)), !,
    tr_degrees(foreign, D, Ws, Os).
tr_degrees(foreign, D, [w(M, _), w(W, C)|Ws], [deg(D, w(W, C))|Os]) :-
    tr_degree_word(M), tr_is(foreign, w(W, C), adjective), !,
    tr_degrees(foreign, D, Ws, Os).
%% AND THE PHRASE DECIDES LAST, which is why this clause exists: the
%% complements are folded before the phrase inside them is, at the
%% comparative, because a bare predicate has no article to read -- so an
%% object's own article must be allowed to make it a superlative after all.
%% Only on the lesson's side: English took the degree off the WORD.
tr_degrees(foreign, D, [deg(_, A)|Ws], [deg(D, A)|Os]) :- !, tr_degrees(foreign, D, Ws, Os).
tr_degrees(Side, D, [W|Ws], [W|Os]) :- tr_degrees(Side, D, Ws, Os).

%% the word this lesson puts in front of a comparative
tr_degree_word(M) :- tr_lexeme(foreign, M, L, _), tr_solve(begin(L, comparative)), !.
tr_degree_out(W) :- once(( tr_solve(begin(W0, comparative)), W = W0 )).

%% a phrase whose determiner is the definite article makes a superlative of
%% the degree inside it, and every other determiner a comparative
tr_degree_of(english, _, comparative).
tr_degree_of(foreign, det(article, DL, _), superlative) :- tr_solve(mean(DL, the)), !.
%% ... and so does a possessive: `sus mejores noches' is her BEST nights,
%% `le sue migliori serate', where it came out `her better nights'
tr_degree_of(foreign, det(possessive, _, _), superlative) :- !.
tr_degree_of(foreign, _, comparative).

%% a word that may be an adjective in a phrase: known, and no preposition,
%% pronoun or verb -- or the `and' between two
tr_adj_word(_, deg(_, _)) :- !.
tr_adj_word(_, int(_, _)) :- !.
tr_adj_word(Side, A) :- tr_coord(Side, A), !.
tr_adj_word(Side, w(W, C)) :-
    tr_lexeme(Side, W, _, _),
    \+ tr_is(Side, w(W, C), preposition),
    %% no pronoun -- unless the lesson calls it an adjective too: `un altro
    %% provvedimento', `nessun altro provvedimento' is another measure, and
    %% `altro' is the pronoun `others' as well, so the phrase was refused
    \+ ( ( tr_object_pronoun(Side, W, _) ; tr_subject_pronoun(Side, W, _, _) ), \+ tr_is(Side, w(W, C), adjective) ),
    %% no verb's form -- unless the lesson calls it an adjective too: `clase
    %% media' is the middle class, and `media' is also what `mediar' says
    \+ ( tr_is(Side, w(W, C), verb), \+ tr_is(Side, w(W, C), adjective) ),
    %% ... NOR A WORD THE LESSON KNOWS ONLY AS AN ADVERB. `Qui solo due
    %% anni fa dominava il coprifuoco' read `qui solo due anni' as ONE
    %% phrase with `here' for an adjective of `years', so the plain reading
    %% won and the fronted clause never saw it. A word that is an adjective
    %% too (`solo', `molto') is still one, which is the judge's own rule in
    %% library(reasoning/tagger) said from this side.
    \+ ( tr_is(Side, w(W, C), adverb), \+ tr_is(Side, w(W, C), adjective) ),
    %% ... NOR A CONJUNCTION, A MODAL OR AN AUXILIARY. `descanso porque hay
    %% que dosificar' read as ONE phrase whose noun was `descanso' and whose
    %% adjectives were `because' and `must', and `riesgos y ha reclamado' as
    %% risks described by `has'; each of the three begins or carries a
    %% clause and describes no noun. A coordinator between two adjectives is
    %% read above, before this clause.
    \+ ( ( tr_is(Side, w(W, C), conjunction) ; tr_is(Side, w(W, C), modal) ; tr_is(Side, w(W, C), auxiliary) ),
         \+ tr_is(Side, w(W, C), adjective) ),
    %% ... NOR AN ARTICLE, which a phrase has at most one of and at its
    %% head. `Sabado el perro come el pan' read `Sabado el perro' as one
    %% phrase with `saturday' and `the' for adjectives of `dog', so the
    %% fronted clause never saw it. A POSSESSIVE is still an adjective
    %% here, because `il suo quartier generale' is one phrase.
    \+ tr_determiner(Side, w(W, C), _, article),
    \+ ( Side == foreign, tr_reflexive_word(W) ),
    %% ... NOR A RELATIVE WORD, which begins a clause and never describes a
    %% noun: `uno della Guardia di finanza CHE hanno pattugliato' read `che'
    %% as `what' and made it a finance's adjective
    \+ ( Side == foreign, tr_relative_word(foreign, W) ),
    %% ... NOR A NUMBER IN DIGITS, which counts a phrase and never describes
    %% one: `oltre 50 mezzi e 130 circa' took `e 130' for adjectives of
    %% `mezzi', and no language had an adjective to write for them
    \+ tr_digits(W).

%% a determiner: English's articles, possessives, demonstratives and the
%% determiners a lesson may give a word for (`each', `another', `many');
%% the lesson's, in either number -- det(Kind, Lexeme, Word)
tr_determiner(english, w(the, _), the, article).
tr_determiner(english, w(a, _), a, article).
tr_determiner(english, w(an, _), a, article).
tr_determiner(english, w(P, _), P, possessive) :- en_possessive(P).
tr_determiner(english, w(W, _), L, demonstrative) :- en_det(W, L, _), en_demonstrative(L).
tr_determiner(english, w(W, _), L, determiner) :- en_det(W, L, _), \+ en_demonstrative(L).
tr_determiner(foreign, w(W, _), L, article) :- tr_lexeme(foreign, W, L, _), tr_class_of(L, article).
tr_determiner(foreign, w(W, _), L, possessive) :- tr_lexeme(foreign, W, L, _), tr_class_of(L, possessive).
tr_determiner(foreign, w(W, _), L, demonstrative) :- tr_lexeme(foreign, W, L, _), tr_class_of(L, demonstrative).
tr_determiner(foreign, w(W, _), L, determiner) :- tr_lexeme(foreign, W, L, _), tr_class_of(L, determiner).

%% the noun of a phrase's content: the one word the lesson calls a noun;
%% none, or SEVERAL -- `el gato negro', where a vocabulary of any size calls
%% `negro' a noun as well as an adjective -- by position among them, the
%% first where adjectives follow the noun and the last otherwise
tr_noun(Words, Side, Noun, Adjs) :-
    findall(W, ( member(W, Words), tr_is(Side, W, noun) ), Nouns),
    (   Nouns = [Noun] -> true
    %% ... and a PREPOSITION is no noun by its place: `quello di Berlusconi'
    %% took `di' for the noun of `quello' with the name apposed to it, and
    %% wrote `ese de Berlusconi' from an IR that said `that of'
    ;   Nouns == [] -> tr_noun_by_position(Words, Side, Noun), \+ tr_is(Side, Noun, preposition)
    %% ... and among several, the ONE that cannot be an adjective: `un esnob
    %% bate de béisbol' has `esnob' (a snob, and snobbish) before its noun,
    %% and position alone made the snob the head
    ;   findall(W, ( member(W, Nouns), \+ tr_is(Side, W, adjective) ), [Noun]) -> true
    ;   tr_noun_by_position(Nouns, Side, Noun)
    ),
    select(Noun, Words, Adjs).

tr_noun_by_position(Words, english, Noun) :- last(Words, Noun).
tr_noun_by_position(Words, foreign, Noun) :- ( tr_holds(follow(_, noun)) -> Words = [Noun|_] ; last(Words, Noun) ).

%% the complements after the verb: a preposition and its phrase, an object
%% pronoun, an adverb, and otherwise a phrase (or two joined, or bare
%% adjectives) up to the next of those
tr_complements(Side, Words0, Comps) :-
    tr_degrees(Side, comparative, Words0, Words),      % `e piu ricco' is richer: no article, no superlative
    tr_complements(Side, Words, no, Comps0),
    tr_relative_wh(Comps0, Comps).

%% A QUESTION WORD AFTER A PHRASE IS A RELATIVE ONE: `all'ospedale di
%% Subiaco DOVE i medici ...' is the hospital where, and Spanish spells that
%% `donde' where its question is `dónde'. Right after the verb it is the
%% indirect question it was (`sapere come'); after another complement it
%% travels as rwh/2, which a writer spells with its relative word for it.
tr_relative_wh([], []).
tr_relative_wh([C|Cs0], [C|Cs]) :- tr_relative_wh1(Cs0, Cs).
tr_relative_wh1([], []).
tr_relative_wh1([wh(Q, S)|Cs0], [rwh(Q, S)|Cs]) :- Q \== whether, !, tr_relative_wh1(Cs0, Cs).    % whether asks, never relates
tr_relative_wh1([C|Cs0], [C|Cs]) :- tr_relative_wh1(Cs0, Cs).

%% THE COMPLEMENTS OF A WORD LIST ARE READ ONCE A SENTENCE, UNDER WHAT THE
%% READING DEPENDS ON. Every reading of a statement reads the complements of
%% what follows its verb, and the same rest of a sentence comes back under
%% the next reading: over the three longest sentences of Monte Livata, 583
%% readings of 409 distinct ones. The reader asks three things besides the
%% words and whether an object was read -- the group and the aspect being
%% read (a modal, the copula, a passive, no verb at all) and the side -- so
%% the key carries all five; and a clause read inside it puts the group and
%% the aspect back (tr_read_nested/4), so nothing leaks in or out. The reader
%% is all but deterministic -- those 409 readings gave 96 solutions between
%% them and none gave more than one -- so every solution is kept, as a
%% word's lexemes are (tr_memo/4), and a caller that cuts sees the same
%% first one. Only a ground word list is kept: a key with a variable in it
%% is not one a later call could find.
tr_complements(Side, Ws, Seen, Cs) :-
    Ws = [T|_], ground(Ws-Seen), tr_token_atom(T, W0), !,
    tr_global('$tr_read_group', G), tr_global('$tr_read_aspect', A), tr_side_here(F),
    atom_concat('c|', W0, W),
    tr_memo(cm(Side, Seen, G, A, F, Ws, W), Cs0, tr_complements0(Side, Ws, Seen, Cs0), Sols),
    member(Cs, Sols).
tr_complements(Side, Ws, Seen, Cs) :- tr_complements0(Side, Ws, Seen, Cs).

%% the atom a token's table is named after
tr_token_atom(w(W, _), W) :- atomic(W), !.
tr_token_atom(T, T) :- atom(T).

%% ... with whether an object has been read: the word the lesson puts
%% before a person, with no object yet and a person after it, is the
%% OBJECT's (`Maria ve a Omar' is Omar); after an object it is the
%% preposition it is (`Maria da el libro a Omar' is to Omar)
tr_complements0(_, [], _, []) :- !.
%% A COMMA, A COORDINATOR AND A PHRASE: `situaban como favoritos a la Unión
%% de Ciudadanos de Georgia, el partido de Shevardnadze, Y EL BLOQUE
%% Renovación'. Neither language puts a comma before the coordinator of a
%% list, so that comma closes the phrase set off before it, and the phrase
%% after the coordinator joins the objects before it. Read with every comma
%% out, the phrases on either side became one, `de Shevardnadze y el
%% bloque', and both commas were lost. It travels as sep and cnj/1, which
%% every writer puts back where they stood.
tr_complements0(foreign, [comma, C|Ws], Seen, [sep, cnj(C)|Cs]) :-
    C = w(_, _), tr_coord(foreign, C), Ws = [D|_], tr_determiner(foreign, D, _, _), !,
    tr_complements(foreign, Ws, Seen, Cs).
tr_complements0(Side, [comma|Ws], Seen, [sep|Cs]) :- !, tr_complements(Side, Ws, Seen, Cs).
tr_complements0(Side, [w(K, paren)|Ws], Seen, [paren(K)|Cs]) :- !, tr_complements(Side, Ws, Seen, Cs).
tr_complements0(Side, [w(K, comment)|Ws], Seen, [comment(K)|Cs]) :- !, tr_complements(Side, Ws, Seen, Cs).
%% AN EXCLAMATION'S `what' AND ITS PHRASE: `Mio dio, che tristezza!' -- what
%% sadness. The word the lesson gives for `what' asks nothing there, and
%% before a noun with no article it is the exclamation's; read as anything
%% else the sentence had no reading. Only in a sentence that ends in `!':
%% elsewhere `che libro' is a question's, which book. what_np/1 is the term,
%% and each writer puts its own word for `what' before the phrase
tr_complements0(Side, [w(Q, _)|Ws], Seen, [obj(what_np(NP))|Cs]) :-
    tr_global('$tr_exclaim', yes), Ws = [_|_], tr_what_word(Side, Q),
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [], tr_phrase_np(Side, PW, NP), NP = np(none, _, _, _, _), !,
    tr_complements(Side, Rest, Seen, Cs).
%% A COMPARISON: `más grande que el perro', `idénticos condicionantes que la
%% ronda anterior'. The lesson's word for `than' before a phrase and no verb
%% is neither a relative word nor the start of a clause; it travels as
%% cmp(Kind, Phrase) -- `equal' where the sentence has a word meaning `same'
%% or `identical' before it, `more' otherwise -- and English writes `as' or
%% `than', and each lesson its own word for `than' (`del turno precedente').
tr_complements0(foreign, [w(Q, _)|Ws], Seen, [cmp(Kind, NP)|Cs]) :-
    tr_comparison_start(foreign, [w(Q, lower)|Ws]),
    tr_phrase_rest(foreign, Ws, NP, Rest), !,
    ( tr_equative_piece(Q) -> Kind = equal ; Kind = more ),
    tr_complements(foreign, Rest, Seen, Cs).
%% ... AND A COMPARISON WHOSE SECOND TERM HAS A PREPOSITION: `un 2,4% menos
%% que en el ejercicio precedente' is two point four per cent less than in
%% the year before. The phrase after the preposition is no noun's -- `que' was
%% read as the noun of a phrase, `than', which wrote the right words by
%% accident until a conjunction stopped being a noun -- and it travels as
%% cmpp(Adverb, Kind, pp(P, NP)): English's `less than in', a lesson's
%% adverb and its conjunction for `than' before the preposition, `meno che
%% nell'esercizio'. The adverb before `than' travels inside it, because
%% English writes a lone adverb after every complement, `than in the house
%% less'.
tr_complements0(foreign, [A, w(Q, _), P|Ws], Seen, [cmpp(A, more, PP)|Cs]) :-
    A = w(_, _), tr_plain_adverb(foreign, A),
    P = w(_, _), tr_is(foreign, P, preposition),
    tr_solve(mean(Q, than)), \+ tr_class_of(Q, preposition),
    tr_complements(foreign, [P|Ws], Seen, [PP|Cs]), PP = pp(_, _), !.
tr_complements0(foreign, [w(Q, _), P|Ws], Seen, [cmpp(none, Kind, PP)|Cs]) :-
    P = w(_, _), tr_is(foreign, P, preposition),
    tr_solve(mean(Q, than)), \+ tr_class_of(Q, preposition), tr_compared_before(Q),
    tr_complements(foreign, [P|Ws], Seen, [PP|Cs]), PP = pp(_, _), !,
    ( tr_equative_piece(Q) -> Kind = equal ; Kind = more ).
tr_complements0(english, [A, w(than, _), P|Ws], Seen, [cmpp(A, more, PP)|Cs]) :-
    A = w(_, _), tr_is(english, A, adverb),
    P = w(_, _), tr_is(english, P, preposition),
    tr_complements(english, [P|Ws], Seen, [PP|Cs]), PP = pp(_, _), !.
%% MORE THAN AN ADJECTIVE: `esa elección resulta más que cuestionable'. The
%% word that begins the comparative, the lesson's word for `than' and
%% adjectives with no phrase after them -- read as a comparison it made
%% `que cuestionable' a phrase whose noun was `que', and `más' a preposition.
%% mt(Adjectives) is the term, and each writer says it in its own words:
%% English `more than', and a lesson its comparative word and the word it
%% calls a CONJUNCTION meaning `than' (tr_than_word/2), `più che'.
tr_complements0(foreign, [w(M, _), w(Q, _)|Ws], Seen, [mt(As)|Cs]) :-
    tr_degree_word(M), tr_solve(mean(Q, than)),
    tr_phrase_words(foreign, Ws, As, Rest), As \== [], tr_all_adjectives(foreign, As), !,
    tr_complements(foreign, Rest, Seen, Cs).
tr_complements0(english, [w(more, _), w(than, _)|Ws], Seen, [mt(As)|Cs]) :-
    tr_phrase_words(english, Ws, As, Rest), As \== [], tr_all_adjectives(english, As), !,
    tr_complements(english, Rest, Seen, Cs).
%% A `che' CLAUSE IS A COMPLEMENT, AND IT RUNS TO THE END OF ITS PIECE.
%% `escludendo che il militare voleva ...' -- the word the lesson gives for
%% `that' before a clause, and everything after it read as a statement of
%% its own. Taking the WHOLE rest rather than the shortest readable piece
%% is deliberate: a shortest-first append would stop at the first clause
%% that happens to read, which is never what `that' introduces.
%% ... AFTER THE WORD THE VERB TAKES BEFORE A CLAUSE: `se da cuenta DE QUE
%% ...' is realizing that, and the lesson says so (`"da cuenta" takes "de"
%% before the clause.'); the word is the verb's, and each writer puts back
%% what its own verb takes
tr_complements0(foreign, [w(P, _), W|Ws], Seen, Cs) :-
    tr_global('$tr_read_group', G), atom(G), tr_solve(take_before(G, P, clause)),
    tr_that_here(foreign, W), Ws \== [],
    tr_complements0(foreign, [W|Ws], Seen, Cs), Cs = [that(_)|_], !.
%% AN INDIRECT QUESTION AFTER A VERB THAT TAKES ONE: `decidere se ci
%% costerebbe più caro intervenire' is to decide WHETHER it would cost more,
%% and the word for `if' there opens no condition. The lesson says which
%% verbs take a question -- `"decide" takes the question.', the shape
%% `"continúa" takes the gerund.' has -- and without one `se' stays the
%% connector it is (`Il cane dorme se piove'). Read as a condition, `e
%% decidere' was a clause of its own and the sentence cost 67 million
%% inferences finding that out. It travels as wh(whether, Clause), after
%% the verb or after the infinitive the verb is.
tr_complements0(foreign, [w(W, _)|Ws], _, [wh(whether, S)]) :-
    Ws \== [], tr_if_word(W),
    tr_global('$tr_read_group', G), atom(G), tr_solve(take(G, question)),
    tr_read_nested(foreign, Ws, none, S), !.
tr_complements0(foreign, [w(V, _), w(W, _)|Ws], _, [inf(F), wh(whether, S)]) :-
    Ws \== [], tr_if_word(W),
    tr_solve(infinitive_of(V, F)), tr_solve(take(F, question)),
    tr_read_nested(foreign, Ws, none, S), !.
%% ... AND TWO OF THEM JOINED ARE TWO: `senza rendersi conto che non importa
%% loro null'altro che perseguire i loro scopi E CHE l'unico linguaggio che
%% parlano è quello della violenza' -- that nothing else matters to them, and
%% that the only language they speak is violence. Read as one clause the
%% second `che' had nothing to be, and the sentence was refused. Each is read
%% on its own and the coordinator stands between them, cnj/1.
tr_complements0(Side, [W|Ws], _, [that(S1), cnj(C), that(S2)]) :-
    tr_that_here(Side, W), W = w(T, _),
    append(W1, [C, w(T2, _)|Ws2], Ws), T2 == T, W1 \== [], Ws2 \== [],
    C = w(_, _), tr_coord(Side, C),
    tr_that_clause(Side, W1, S1), tr_that_clause(Side, Ws2, S2), !.
tr_complements0(Side, [W|Ws], _, [that(S)]) :-
    tr_that_here(Side, W), Ws \== [],
    tr_that_clause(Side, Ws, S), !.

%% the clause after `che', read as a statement -- and a comma STRAIGHT AFTER
%% the word opens an insertion in front of it: `senza rendersi conto che,
%% come il loro predecessore, non importa loro null'altro che ...' is like
%% their predecessor, nothing else matters to them. Read with the commas
%% out, `loro predecessore' was a subject and `come ... loro' an adjunct,
%% `de que predecesor no les importa ... como el ellos'. It is the clause's
%% front, and it travels as frc/1, which every writer puts back with a comma
%% before it as well as after.
%% (read as a whole statement is, whose front may end at a comma -- the
%% nested reader's front has none -- and the reader's globals put back)
tr_that_clause(Side, [comma|Ws], S) :- !,
    Ws = [_|_],
    tr_global('$tr_read_group', G0), tr_global('$tr_read_aspect', A0),
    (   tr_read(Side, statement, Ws, S0) -> nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0)
    ;   nb_setval('$tr_read_group', G0), nb_setval('$tr_read_aspect', A0), fail
    ),
    S0 = s(A, Su, G, Cs0), append(Pre, [fr(X)|Post], Cs0), \+ memberchk(fr(_), Pre), !,
    append(Pre, [frc(X)|Post], Cs), S = s(A, Su, G, Cs).
tr_that_clause(Side, Ws, S) :- tr_read_nested(Side, Ws, none, S).
%% A QUESTION WORD AFTER THE VERB OPENS AN INDIRECT QUESTION, and it runs to
%% the end of its piece as a `che' clause does: `bisognerebbe sapere COME
%% sono finiti lì', `Non si sa come possa essere successo', `all'ospedale
%% DOVE i medici stanno valutando'. wh(Word, Clause) is the term, the English
%% question word and the clause read as a statement; each writer puts the
%% target's word for it in front, as a question's is.
%% ... BUT NOT A WORD THAT IS A PREPOSITION TOO WHEN A PHRASE IS ALL THAT
%% FOLLOWS IT: `come dividendo straordinario' is AS an extraordinary
%% dividend, and read as `how' the phrase had to be a clause, so the noun
%% was taken for the gerund it is spelled like and came out `cómo
%% dividiendo extraordinario'.
tr_complements0(Side, [w(W, _)|Ws], _, [wh(Q, S)]) :-
    Ws \== [], tr_indirect_word(Side, W, Q),
    \+ ( tr_is(Side, w(W, lower), preposition), tr_phrase_words(Side, Ws, PW, []), PW \== [], tr_phrase_np(Side, PW, _) ),
    tr_read_nested(Side, Ws, none, S), !.
%% A GERUND AFTER A CLAUSE'S COMPLEMENTS IS HOW THE CLAUSE WAS DONE:
%% `destrozan la cabeza a un inmigrante utilizando un bate de béisbol'. It
%% takes the rest of the words as its own complements, the way a `che'
%% clause does, and travels as ger(Lexeme, Complements); every language
%% here writes it as its own gerund in the same place.
%% ... WITH ITS REFLEXIVE, the verb's as in a group: `Bros fue entonándose
%% hasta conseguir triunfar' is getting into his voice, ger(reflexive(L),
%% Complements) -- and NEVER AFTER THE COPULA, which takes no gerund in the
%% lesson's languages: `fue' is the past of `ser' and of `ir', and a gerund
%% after it says it is `ir', going on doing a thing, `andò intonandosi'
tr_complements0(foreign, [w(G, _), w(Cl, enclitic)|Ws], _, [ger(reflexive(L), Cs)]) :-
    \+ tr_copula_group, tr_reflexive_word(Cl),
    tr_gerund_here(foreign, G, L), tr_complements(foreign, Ws, Cs), !.
%% ... AND WITH A PRONOUN OF ITS OWN JOINED TO IT: `pidiéndole que designara
%% a un fiscal' asks her to appoint one. The pronoun is the gerund's object,
%% and read as a phrase of its own it headed a relative clause, `le que
%% designara', him who appointed; it travels as opron/1 first among the
%% gerund's complements, and the lesson's writer joins it back on
tr_complements0(foreign, [w(G, _), w(Cl, enclitic)|Ws], _, [ger(L, [opron(w(Cl, lower))|Cs])]) :-
    \+ tr_copula_group, \+ tr_reflexive_word(Cl),
    tr_gerund_here(foreign, G, L), tr_complements(foreign, Ws, Cs), !.
tr_complements0(Side, [w(G, _)|Ws], _, [ger(L, Cs)]) :-
    Ws \== [], \+ ( Side == foreign, tr_copula_group ),
    tr_gerund_here(Side, G, L), \+ tr_is(Side, w(G, lower), noun),
    tr_complements(Side, Ws, Cs), !.
%% the group being read is the copula's
tr_copula_group :- tr_global('$tr_read_group', GL), atom(GL), GL \== none, tr_copula_lexeme(GL), !.
%% `AL' AND AN INFINITIVE IS THE MOMENT SOMETHING WAS DONE: `ha provocado el
%% escándalo al acusar a la institución' -- on accusing it. The lesson names
%% the word, `The word "al" begins the moment.', in the shape `The word
%% "per" begins the purpose.' already has; it is read as the words the
%% contraction stands for (`a el') with the infinitive after them, and the
%% rest of the words are the infinitive's complements. upon(Lexeme,
%% Complements) is the term; English writes `on' and the -ing form, and a
%% lesson that names no such word writes its gerund.
%% -- AND IT ENDS AT ITS FIRST COMMA: `Al abrir la audiencia, Hyde sostuvo
%% que ...' took the comma and `Hyde' for the infinitive's, so the front
%% swallowed the subject and the clause after it had nobody to say it
tr_complements0(foreign, Ws0, Seen, [upon(F, Cs)|More]) :-
    Ws0 = [w(P, _), w(D, _), w(V, _)|Ws],
    tr_solve(begin(M, moment)), tr_solve(contraction_of(M, J)), atomic_list_concat([P, D], ' ', J),
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F),
    tr_upon_rest(foreign, Ws, Seen, Cs, More), !.
tr_complements0(english, [w(on, _), w(G, _)|Ws], Seen, [upon(L, Cs)|More]) :-
    en_gerund(G, L), tr_upon_rest(english, Ws, Seen, Cs, More), !.
tr_upon_head(foreign, [w(P, _), w(D, _), w(V, _)|_]) :-
    tr_solve(begin(M, moment)), tr_solve(contraction_of(M, J)), atomic_list_concat([P, D], ' ', J),
    tr_solve(infinitive_of(V, _)), !.
tr_upon_head(english, [w(on, _), w(G, _)|_]) :- en_gerund(G, _), !.
tr_upon_rest(Side, Ws, Seen, Cs, More) :-
    (   append(Ws1, [comma|Ws2], Ws), \+ memberchk(comma, Ws1), Ws1 \== []
    ->  tr_complements(Side, Ws1, Cs), tr_complements(Side, [comma|Ws2], Seen, More)
    ;   tr_complements(Side, Ws, Cs), More = []
    ).
tr_complements0(foreign, [w(P, PC)|Ws], no, Out) :-
    tr_marker_word(P, Class),
    tr_phrase_words(foreign, Ws, PW, Rest), PW \== [],
    tr_phrase_np(foreign, PW, NP), tr_of_class(NP, Class), !,
    tr_complements(foreign, Rest, yes, Cs),
    %% ... AND AN OBJECT AFTER IT MAKES IT THE INDIRECT ONE: `ha reclamado a
    %% los jugadores la máxima concentración' asked the players for it, and
    %% read as the object they came out `ha reclamato i giocatori la massima
    %% concentrazione', two objects and no `to'
    %% -- BUT ONLY AN OBJECT OF THE VERB ITSELF: the complements are one
    %% flat list, and an object after an infinitive is the infinitive's.
    %% `acusó a la mayoría de buscar el pan' accuses the majority of
    %% seeking the bread, and with the bread counted it came out `accusò
    %% alla maggioranza'
    %% -- AND A VERB THE LESSON SAYS TAKES THE WORD BEFORE A PERSON IS
    %% WRITTEN TO THEM, never done to them: `escribieron a la ministra' came
    %% out `scrissero la ministra'. `"escribe" takes "a" before the person.'
    %% is the shape `"confida" takes "di" before the infinitive.' already has
    (   ( tr_verb_object(Cs) ; tr_takes_before_person(P) ) -> Out = [pp(w(P, PC), NP)|Cs] ; Out = [obj(NP)|Cs] ).
tr_takes_before_person(P) :-
    tr_global('$tr_read_group', G), atom(G), G \== none, tr_solve(take_before(G, P, person)), !.
tr_verb_object([C|Cs]) :- ( C = obj(_) -> true ; \+ tr_verbal_comp(C), tr_verb_object(Cs) ).
tr_verbal_comp(inf(_)).
tr_verbal_comp(infx(_, _, _)).
tr_verbal_comp(pinf(_, _)).
tr_verbal_comp(ainf(_, _)).
tr_verbal_comp(purpose(_)).
%% AN INFINITIVE WITH ITS OWN PRONOUNS, OR IN THE PERFECT: `riprenderli'
%% (to recover them), `ritrovarsi' (to find oneself), `di aver lasciato i
%% piccoli' (to have left the little ones), `di essersi persa' (to have got
%% lost), `possa essere successo' (may have happened). The perfect's
%% auxiliary is an infinitive the lesson gives -- of its auxiliary, or of
%% the copula where the lesson says the verb or the reflexive builds its
%% perfect with it -- and the pronouns are the ones tr_enclitics/3 cut off.
%% It travels as infx(Lexeme, simple|perfect, Pronouns); an infinitive with
%% neither is still inf/1, so nothing that read before reads differently.
%%
%% A PREPOSITION MEANING `of' OR `to' IN FRONT OF ONE IS ITS OWN: `ha
%% raccontato DI aver avuto un problema' -- the complementiser Italian puts
%% before an infinitive after a verb of saying -- and the IR carries the
%% infinitive alone, the stated cost of tr_means_to/1 below.
%% -- AND AFTER AN OBJECT A `de' IS THE NOUN'S, AS IT IS BEFORE A PLAIN
%% INFINITIVE (pinf/2): `la presión de jugárselo todo' is the pressure of
%% risking it all, and the preposition travels as nprep/1 before the
%% infinitive, which the lesson's writer spells and English's leaves out
%% (`the pressure to risk everything')
%% -- unless the lesson says the word BEGINS THE INFINITIVE, which is the
%% verb's: `di aver avuto un problema e di aver lasciato i bimbi' has an
%% object before its second `di', and read as the problem's it came out `y
%% de haber dejado'
tr_complements0(foreign, Ws0, Seen, Out) :-
    ( Ws0 = [w(P, PC)|Ws1], ( tr_means_to(P) ; tr_means_of(P) ) -> Pre = w(P, PC) ; Ws1 = Ws0, Pre = none ),
    tr_infinitive_group(Ws1, F, Asp, Cls0, Ws), !,
    tr_complements(foreign, Ws, Seen, Cs),
    tr_undouble(Cls0, Cs, Cls),
    (   Pre = w(PW, _), tr_means_of(PW), Seen == yes, \+ tr_solve(begin(PW, infinitive))
    ->  Out = [nprep(Pre), infx(F, Asp, Cls)|Cs]
    ;   Out = [infx(F, Asp, Cls)|Cs]
    ).

%% A PRONOUN THAT ONLY DOUBLES `todo' IS NOT A SECOND OBJECT. Spanish says
%% `jugárselo todo', `se lo comió todo' -- the pronoun and the word for
%% everything are one object said twice -- and Italian says it once,
%% `giocarsi tutto'. Where the complements have the word for everything, a
%% pronoun joined to the infinitive that is no reflexive goes.
tr_undouble(Cls0, Cs, Cls) :-
    member(C, Cs), ( C = opron(w(T, _)) ; C = obj(pronoun(w(T, _))) ),
    tr_lexeme(foreign, T, L, _), tr_solve(mean(L, everything)), !,
    exclude(tr_plain_enclitic, Cls0, Cls).
tr_undouble(Cls, _, Cls).
tr_plain_enclitic(Cl) :- \+ tr_reflexive_word(Cl).
%% A DENIED INFINITIVE, the denial its own (tr_negation/4 leaves it where
%% it stands): `è facile non ritrovarsi più' -- not to find oneself.
tr_complements0(foreign, [w(N, _)|Ws0], Seen, [neg(C)|Cs]) :-
    tr_solve(mean(N, not)), tr_starts_infinitive(foreign, Ws0),
    tr_complements(foreign, Ws0, Seen, [C|Cs]), ( C = inf(_) ; C = infx(_, _, _) ), !.
%% A PREPOSITION THE VERB TAKES BEFORE AN INFINITIVE IS THE VERB'S, NOT THE
%% SENTENCE'S. `confía EN repetir el guión' is trusting to repeat it, and
%% Italian's verb takes another word there: `confida DI ripetere'. Carried
%% as a phrase, the preposition crossed as `in' and came out `affida in
%% ripetere'. The lesson says which word a verb takes -- `"confía" takes
%% "en" before the infinitive.' -- the IR carries the infinitive alone, and
%% each writer puts back what ITS verb takes (tr_verb_takes/1).
tr_complements0(foreign, [w(P, _), w(V, _)|Ws], Seen, [inf(F)|Cs]) :-
    tr_global('$tr_read_group', G), atom(G), tr_solve(take_before(G, P, infinitive)),
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements(foreign, Ws, Seen, Cs).
%% A PREPOSITION BEFORE AN INFINITIVE: `invece di andare da una parte' --
%% instead of going, en vez de ir. The lesson's languages put the infinitive
%% after a preposition where English puts the -ing form; pinf(Preposition,
%% Lexeme) is the term, and the infinitive's own complements follow it.
%% ... AND WITH THE REFLEXIVE JOINED TO IT: `hasta situarse en 61,9
%% millones de unidades' is until it stood at 61.9 million, and the `se' cut
%% off the infinitive (tr_enclitics/3) was read as a pronoun of its own, the
%% impersonal one -- `fino situare uno in'. The reflexive is the verb's, as
%% it is in a group: pinf(Preposition, reflexive(Lexeme)).
tr_complements0(foreign, [w(P, C), w(V, _), w(Cl, enclitic)|Ws], Seen, [pinf(w(P, C), reflexive(F))|Cs]) :-
    tr_is(foreign, w(P, C), preposition), \+ tr_means_to(P), \+ tr_means_of(P), \+ tr_purpose_word(P),
    tr_reflexive_word(Cl),
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements_after_inf(w(P, C), F, Ws, Seen, Cs).
%% ... AND WITH ANOTHER PRONOUN JOINED TO IT: `sin pedirles grandes
%% exigencias' is without asking THEM, and the `les' cut off the infinitive
%% was read as a pronoun of the clause, which the lesson's writer puts before
%% the clause's verb -- `e gli permette ... senza chiedere'. The pronouns are
%% the infinitive's, one or two: pinf(Preposition, cl(Lexeme, Pronouns)).
tr_complements0(foreign, [w(P, C), w(V, _), w(Cl, enclitic)|Ws0], Seen, [pinf(w(P, C), cl(F, Cls))|Cs]) :-
    tr_is(foreign, w(P, C), preposition), \+ tr_means_to(P), \+ tr_means_of(P), \+ tr_purpose_word(P),
    \+ tr_reflexive_word(Cl),
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F),
    ( Ws0 = [w(Cl2, enclitic)|Ws] -> Cls = [w(Cl, lower), w(Cl2, lower)] ; Cls = [w(Cl, lower)], Ws = Ws0 ), !,
    tr_complements_after_inf(w(P, C), F, Ws, Seen, Cs).
tr_complements0(foreign, [w(P, C), w(V, _)|Ws], Seen, [pinf(w(P, C), F)|Cs]) :-
    tr_is(foreign, w(P, C), preposition), \+ tr_means_to(P), \+ tr_means_of(P), \+ tr_purpose_word(P),
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements_after_inf(w(P, C), F, Ws, Seen, Cs).
%% ... and with an ARTICLE between them, the infinitive used as a noun:
%% `il loro incessante impegno NEL realizzare il progetto' is in carrying it
%% out, and `nel' is `in' and `il'. The article says nothing a writer needs
%% -- Spanish writes `en realizar' and English `in carrying out' -- so it
%% goes, and the preposition and the infinitive are what they were above.
tr_complements0(foreign, [w(P, C), D, w(V, _)|Ws], Seen, [pinf(w(P, C), F)|Cs]) :-
    tr_is(foreign, w(P, C), preposition), \+ tr_means_to(P), \+ tr_means_of(P), \+ tr_purpose_word(P),
    tr_determiner(foreign, D, _, article),
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements_after_inf(w(P, C), F, Ws, Seen, Cs).
%% A PREPOSITION MEANING `of' BEFORE A PLAIN INFINITIVE: `ci permetterà DI
%% realizzare la nostra visione', `la nostra visione DI creare un
%% costruttore'. Only a perfect infinitive or one with a pronoun joined to it
%% had a reading after `di', so both refused. Straight after the verb the
%% word is the verb's and every language here has its own way with it --
%% Spanish writes `nos permitirá realizar', bare, and English `to realize'
%% -- so it is the plain infinitive; after an OBJECT it belongs to the noun
%% before it, `la visión DE crear', and it keeps its preposition as pinf/2.
%% STRAIGHT AFTER THE VERB ONLY WHERE THE LESSON SAYS THE WORD BEGINS AN
%% INFINITIVE -- `The word "di" begins the infinitive.', the purpose word's
%% shape -- because Italian's `di' is what English's `to' is and Spanish's
%% `de' is not: `Él me acaba de enviar un mensaje' read as `He finishes me
%% to send a message', where `acabar de' is `has just', and it had been
%% refused. Nothing in a lesson says which verbs take which word, so a
%% language whose lesson says nothing keeps the refusal.
tr_complements0(foreign, [w(P, C), w(V, _)|Ws], Seen, [Inf|Cs]) :-
    tr_means_of(P), tr_solve(infinitive_of(V, F)), tr_known(foreign, F),
    ( Seen == yes -> Inf = pinf(w(P, C), F), Prep = w(P, C) ; tr_infinitive_mark(P), Inf = inf(F), Prep = none ), !,
    tr_complements_after_inf(Prep, F, Ws, Seen, Cs).
tr_infinitive_mark(P) :- tr_lexeme(foreign, P, L, _), tr_solve(begin(L, infinitive)), !.

%% WHAT FOLLOWS A PREPOSITION AND ITS INFINITIVE IS THE INFINITIVE'S, and
%% after the copula that matters: `es partidario de continuar con las
%% reformas y anclar a su país en Occidente SOLICITANDO el ingreso en la
%% OTAN' -- the gerund says how the anchoring is done, and read as the
%% copula's it was refused, because the copula takes no gerund. The rest is
%% read with the infinitive as the group being read.
%% ... AND AN INFINITIVE JOINED TO IT IS UNDER THE SAME PREPOSITION: `es
%% partidario de continuar con las reformas Y ANCLAR a su país' -- the copula
%% takes no bare infinitive, so the second is what `de' governs too, and
%% English wrote `of continuing ... and to anchor'. It travels as pinf/2 with
%% the first one's preposition.
tr_complements_after_inf(Prep, F, Ws, Seen, Cs) :-
    tr_copula_group, atom(F), !,
    tr_global('$tr_read_group', G0), nb_setval('$tr_read_group', F),
    (   tr_complements(foreign, Ws, Seen, Cs0) -> nb_setval('$tr_read_group', G0)
    ;   nb_setval('$tr_read_group', G0), fail
    ),
    tr_share_prep(Prep, Cs0, Cs).
%% (and after an infinitive the word before a clause is the infinitive's:
%% `sin darse cuenta de que ...')
tr_complements_after_inf(_, F, [w(P, _), W|Ws], Seen, Cs) :-
    atom(F), tr_solve(take_before(F, P, clause)), tr_that_here(foreign, W), Ws \== [],
    tr_complements(foreign, [W|Ws], Seen, Cs), Cs = [that(_)|_], !.
tr_complements_after_inf(_, _, Ws, Seen, Cs) :- tr_complements(foreign, Ws, Seen, Cs).

tr_share_prep(Prep, Cs0, Cs) :-
    Prep \== none, append(Pre, [cnj(K), inf(F2)|Post], Cs0),
    \+ memberchk(cnj(_), Pre), \+ memberchk(inf(_), Pre), !,
    append(Pre, [cnj(K), pinf(Prep, F2)|Post], Cs).
tr_share_prep(_, Cs, Cs).
%% an infinitive: the lesson's (`"comer" is the infinitive of "come"'), or
%% English's `to' and a base form, and a bare base form after a modal
%% A PURPOSE IS AN INFINITIVE WITH A WORD IN FRONT OF IT: `per definire' is
%% `to define', `para definir'. The lesson names the word -- `The word "per"
%% begins the purpose.' -- which is the shape `The mark "¿" begins the
%% question' already uses, so no grammar moved for it.
%%
%% ENGLISH LOSES THE DISTINCTION AND THAT IS ENGLISH'S DOING, not a gap here.
%% `wants to eat' and `came to eat' are the same three words, so English
%% writes a purpose exactly as it writes a plain infinitive, and an English
%% source is read as the plain one. Italian into Spanish keeps the mark
%% because both languages make it; Italian into English and back loses it.
tr_complements0(foreign, [w(P, _), w(V, _)|Ws], Seen, [purpose(F)|Cs]) :-
    tr_purpose_word(P), tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements(foreign, Ws, Seen, Cs).
%% A PREPOSITION MEANING `to' BEFORE AN INFINITIVE IS THE INFINITIVE.
%% `si tende AD accreditare la tesi', `comienza A comer' -- the word belongs
%% to the verb and not to a phrase, and without this clause the pp/2 clause
%% below took it, cut, and refused the sentence for want of a phrase after
%% it. The purpose clause above is the same shape with the word the lesson
%% calls the purpose's.
%%
%% WHICH PREPOSITION A VERB WANTS IS NOT IN THE IR, and that is the cost.
%% English writes its own `to' and the lesson's language writes the bare
%% infinitive, so `si tende ad accreditare' comes back `se tiende
%% acreditar': the word is lost, because nothing a lesson says pairs a verb
%% with the preposition its infinitive takes.
%% THE `to' BEFORE AN INFINITIVE IS KEPT: `andare a chiedere aiuto' is `ir a
%% pedir ayuda', and dropped it came out `ir pedir'. It travels as ainf/2 and
%% English writes its own `to' either way; the lesson's writer puts its word
%% for `to' back, which is right after the verbs of going and beginning that
%% take one, and wrong after the few that take none (`riuscire a', `lograr')
tr_complements0(foreign, [w(P, PC), w(V, _)|Ws], Seen, [ainf(w(P, PC), F)|Cs]) :-
    tr_means_to(P), tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements(foreign, Ws, Seen, Cs).
tr_complements0(foreign, [w(V, _)|Ws], Seen, [inf(F)|Cs]) :-
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements(foreign, Ws, Seen, Cs).
tr_complements0(english, [w(to, _), w(B, _)|Ws], Seen, [inf(L)|Cs]) :-
    en_infinitive(B, L), !,
    tr_complements(english, Ws, Seen, Cs).
tr_complements0(english, [w(B, _)|Ws], Seen, [inf(L)|Cs]) :-
    tr_read_modal, en_infinitive(B, L), !,
    tr_complements(english, Ws, Seen, Cs).
%% TWO INFINITIVES UNDER ONE PURPOSE: `per definire "illegale" la decisione
%% E invocare il sostegno dei suoi soldati'. The conjunction is not inside a
%% phrase -- which is the splitter's `A e B' -- and it is not between two
%% clauses either, because the second half has no subject and no finite
%% verb. It is between two COMPLEMENTS, so it travels as one and writes
%% with the target's word for it.
tr_complements0(Side, [C|Ws], Seen, [cnj(C)|Cs]) :-
    tr_coord(Side, C), tr_after_coord(Side, Ws), !,
    tr_complements(Side, Ws, Seen, Cs).
%% ... AND A SUBORDINATING WORD BEFORE A DENIED ADJUNCT: `sono banditi SE NON
%% per sempre quantomeno per qualche giorno' -- if not for ever, at least for
%% some days. No verb follows it, so no clause does; read as a phrase, `se'
%% was the noun of one, because a word no lesson calls a noun is a phrase's
%% noun by position, and the IR said the cars were banned an `if'.
%% The denial and the adjunct after it are one complement, neg/1.
tr_complements0(Side, [C|Ws], Seen, [cnj(C), neg(C1)|Cs]) :-
    C = w(CW, _), tr_connector(Side, CW), \+ tr_coord(Side, C),
    Ws = [w(N, _)|Ws1], ( Side == english -> N == not ; tr_negation_word(N) ), tr_after_coord(Side, Ws1), !,
    tr_complements(Side, Ws1, Seen, [C1|Cs]), tr_adjunct(C1).
%% OF WHICH, WITH NO VERB: `si sono adoperate 37 associazioni di protezione
%% civile, di cui tre di unità cinofile' -- three of them, of canine units.
%% A preposition and the relative the lesson says follows one (`"cui"
%% follows the preposition'), then a phrase and nothing that is a verb. It
%% travels as rpp/2, and each writer puts its own relative after the
%% preposition: English's `of which', Spanish's `de las que' with the
%% article agreeing with the OBJECT before it, which is what the which is.
%% -- and ADVERBS BEFORE ITS PHRASE are the phrase's: `di cui SOLO uno' is
%% only one of them, advp(Adverb, Phrase), which every writer puts in front
tr_complements0(Side, [P, w(R, _)|Ws0], Seen, [rpp(P, NP)|Cs]) :-
    tr_rel_after_prep(Side, R), tr_is(Side, P, preposition),
    tr_lead_adverbs(Side, Ws0, As, Ws),
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [], tr_phrase_np(Side, PW, NP0), !,
    tr_advp(As, NP0, NP),
    tr_complements(Side, Rest, Seen, Cs).
tr_lead_adverbs(Side, [A|Ws0], [A|As], Ws) :-
    Ws0 = [_|_], A = w(_, _), tr_plain_adverb(Side, A), \+ tr_is(Side, A, preposition), !,
    tr_lead_adverbs(Side, Ws0, As, Ws).
tr_lead_adverbs(_, Ws, [], Ws).
tr_advp([], NP, NP).
tr_advp([A|As], NP0, advp(A, NP)) :- tr_advp(As, NP0, NP).
%% THE AGENT OF A PASSIVE IS NOT AN ADJUNCT: `dai soldati' is who did it,
%% and it travels as by/1 so that it writes with the TARGET's word for `by'.
%% Read as an ordinary pp/2 it would cross by the first meaning of `da',
%% which the lesson gives as `from' -- and `imposed from the soldiers' is
%% not what the sentence says.
tr_complements0(Side, [P|Ws], Seen, [by(NP)|Cs]) :-
    tr_read_passive, tr_is(Side, P, preposition), tr_means_by(Side, P), \+ tr_bare_start(Side, Ws),
    \+ tr_date_range(Side, Ws), !,
    tr_phrase_rest(Side, Ws, NP, Rest),
    tr_complements(Side, Rest, Seen, Cs).

%% ... BUT A DAY IS NOBODY'S AGENT: `è vietato DAL 24 luglio al 25 agosto',
%% `"proibita" dal primo al 31 agosto' -- from one day to another, and read
%% as the agent the day had done the banning, `por el 24 de julio'. The
%% phrase is a date, or the start of a range whose end is one.
%% ... and a range ends at `to': `dal gatto nel 2014' is the cat, and a year
tr_means_to(english, to) :- !.
tr_means_to(foreign, W) :- tr_lexeme(foreign, W, L, _), tr_solve(mean(L, to)), !.
%% It is asked of the words and not of their phrases, because it is asked
%% after every participle a preposition follows: read as phrases, the rest of
%% Livata's `soccorsa dai carabinieri, è stata trasportata ...' cost its
%% sentence half as much again.
tr_date_range(Side, Ws0) :-
    ( Ws0 = [D|Ws], tr_determiner(Side, D, _, article) -> true ; Ws = Ws0 ),
    (   Ws = [w(N, _), M|_], tr_digits(N), tr_month(Side, M) -> true                 % `dal 24 luglio'
    ;   append(Pre, [P2|Ws2], Ws), Pre \== [], length(Pre, K), K =< 2,                 % `dal 4 al 24 agosto',
        P2 = w(PW, _), tr_is(Side, P2, preposition), tr_means_to(Side, PW),          % `dal primo al 31 agosto'
        ( Ws2 = [D2, w(N2, _)|_], tr_determiner(Side, D2, _, article) -> true ; Ws2 = [w(N2, _)|_] ),
        tr_digits(N2)
    ), !.
%% AND A PREPOSITION'S OBJECT MAY BE AN ADVERB: `per sempre' is `for
%% ever', `para siempre', and every language writes it as the two words it
%% is. It rides pp/2 with adv/1 where the phrase goes, so the crossing and
%% both writers take it apart by the clauses they already had.
%% A WORD THAT IS A PREPOSITION AND AN ADVERB IS THE ADVERB WHEN NO PHRASE
%% FOLLOWS IT: `130 circa tra uomini e donne' -- about a hundred and thirty,
%% and `circa' is `concerning' too. The preposition is committed to only
%% once its phrase has read.
tr_complements0(Side, [P|Ws], Seen, [pp(P, NP)|Cs]) :-
    tr_is(Side, P, preposition),
    (   Ws = [w(O, OC)|Rest], tr_object_pronoun_here(Side, Ws), \+ tr_relative_start(Side, Rest), \+ tr_ellipsis_start(Side, Ws)
    ->  NP = pronoun(w(O, OC)), Phrase = no
    ;   tr_phrase_rest(Side, Ws, NP, Rest)
    ->  Phrase = yes
    ;   Ws = [A|Rest], tr_is(Side, A, adverb), NP = adv(A)
    ->  Phrase = no
    ;   \+ tr_is(Side, P, adverb)
    ->  fail
    ), !,
    tr_after_phrase(Phrase, Side, Rest, Seen, Cs).

%% A `de' AND AN INFINITIVE AFTER A PREPOSITION'S PHRASE ARE THAT PHRASE'S:
%% `apeló a la necesidad de ser humildes' is the need to be humble, and it
%% keeps its preposition as it does after an object (pinf/2)
%% -- BUT NOT A WORD THE LESSON SAYS BEGINS THE INFINITIVE, which is the
%% verb's: `aveva riferito ai carabinieri di aver lasciato i piccoli' is
%% telling them to have left the children, and read as the carabinieri's
%% `di' it came out `de tener dejado'. Spanish says nothing of `de' there,
%% and `la necesidad de ser humildes' keeps its reading.
tr_after_phrase(yes, foreign, [w(P, C), w(V, _)|Ws], Seen, [pinf(w(P, C), F)|Cs]) :-
    tr_means_of(P), \+ tr_solve(begin(P, infinitive)),
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements(foreign, Ws, Seen, Cs).
tr_after_phrase(_, Side, Ws, Seen, Cs) :- tr_complements(Side, Ws, Seen, Cs).
tr_complements0(Side, [w(W, C)|Ws], Seen, [opron(w(W, C))|Cs]) :-
    tr_object_pronoun_here(Side, [w(W, C)|Ws]), \+ tr_relative_start(Side, Ws), \+ tr_ellipsis_start(Side, [w(W, C)|Ws]), !,
    tr_complements(Side, Ws, Seen, Cs).
%% AN ADVERB BEFORE A PREDICATE ADJECTIVE IS THE ADJECTIVE'S: `Esto es muy
%% gracioso' is very funny, and read as the clause's adverb it came out `This
%% is funny very' -- the intensifier a phrase carries (tr_intensify/3), which
%% `graciosísimo' is too once the lesson states it a superlative
%% -- but never a participle, which stands after its verb predicated of the
%% subject (the clause below): `juegan muy ordenados' is `giocano molto
%% ordinati', and taken as the adjective `orderly' Italian had no word for it
tr_complements0(Side, [A, J|Ws], _, [adj([int(A, J)|Js])|Cs]) :-
    tr_intensifier(Side, A, J), \+ ( J = w(JW, _), tr_participle_here(Side, JW, _) ),
    tr_phrase_words(Side, [J|Ws], [J|Js], Rest), tr_all_adjectives(Side, [J|Js]), !,
    tr_complements(Side, Rest, yes, Cs).
%% (an ARTICLE the lesson calls an adverb is no adverb here: `emplean unos
%% 980 trabajadores' is about 980 of them, tr_np/3's count, and read here it
%% was `employ 980 workers about' -- and `emplean unos trabajadores' came out
%% `employ about industrious')
tr_complements0(Side, [A|Ws], Seen, [adv(A)|Cs]) :-
    tr_plain_adverb(Side, A), !, tr_complements(Side, Ws, Seen, Cs).

%% an adverb that is no article: `unos' is `about' before a number (tr_np/3)
%% and an article everywhere else, and as an adverb anywhere a phrase begins
%% it cut `unas ventas' off before its article
tr_plain_adverb(Side, A) :- tr_is(Side, A, adverb), \+ tr_determiner(Side, A, _, article).
%% A PARTICIPLE STANDING ALONE AFTER THE VERB IS PREDICATED OF THE SUBJECT.
%% `l'operazione e considerata gia CONCLUSA' -- the passive says what was
%% done to it and the participle says what it now is, which is the copula's
%% own complement with the copula already spent on the passive. A bare
%% adjective was read as adj/1 by the last clause below and a participle is
%% no adjective of any lesson, so the sentence was refused.
%%
%% IT CARRIES THE LEXEME AND NOT THE FORM, exactly as 1.6.4's reduced
%% relative does, because the form has to agree on the way out -- with the
%% SUBJECT here, which is the gender the writer already holds, so
%% tr_participle_agreeing/3 needs nothing wrapped round it.
%% ... AND ONE IN QUOTATION MARKS KEEPS THEM: `sottolineo "osato"' stresses
%% the word, and pred/1 carries a lexeme and no case, so the marks were lost,
%% `subrayo osado'. predq(Lexeme, Case) is the same complement with the case
%% the source gave it.
tr_complements0(Side, [w(P, PC)|Ws], Seen, [Pred|Cs]) :-
    tr_participle_here(Side, P, L), !,
    ( memberchk(PC, [qboth, qopen, qclose]) -> Pred = predq(L, PC) ; Pred = pred(L) ),
    tr_complements(Side, Ws, Seen, Cs).
%% AN OBJECT COMPLEMENT IS WHAT THE VERB PREDICATES OF ITS OBJECT --
%% `definire illegale la decisione', `declarar ilegal la decision', `define
%% the decision illegal'. The two sides put it in OPPOSITE places, the
%% lesson's language before the object and English after it, so it travels
%% as oc(Object, Adjectives) and each writer puts it where its own language
%% wants it. The adjectives agree with the OBJECT and not with the subject.
%%
%% WHAT TELLS IT FROM AN ORDINARY OBJECT IS NOT THE SAME THING IN THE TWO
%% LANGUAGES, which is why there are two clauses rather than one. In English
%% it is the POSITION: an attributive adjective goes before its noun, so a
%% phrase-final one can only be predicative. In the lesson's language an
%% adjective before its noun is ordinary (`buono pane'), and what marks the
%% complement is the DETERMINER after the adjectives -- `illegale la
%% decisione' has one and `buono pane' has none. Both are read before the
%% ordinary phrase, because the ordinary reading takes either shape
%% otherwise: `the decision illegal' as `the illegal decision', and
%% `illegale la decisione' as one phrase with the article among its
%% adjectives.
%%
%% AND THE OBJECT MUST BE AN OBJECT, which is what `\+ tr_all_adjectives'
%% says: a bare adjective reads as a phrase of its own, so `is big and red'
%% offered `big' as the object and `and red' as the complement of it, and
%% the copula's own predicate came out as one.
%%
%% AND NEITHER IS GUARDED BY WHETHER AN OBJECT HAS BEEN READ, because the
%% sample's own sentence has one already: `manda un fax per definire
%% illegale la decisione' gives the main verb its object and the purpose
%% infinitive a complement of its own. The shape is the guard, and the
%% `Seen' flag belongs to the word the lesson puts before a person.
tr_complements0(english, Ws, _, [oc(NP, As)|Cs]) :-
    tr_phrase_words(english, Ws, PW, Rest), PW \== [],
    append(PW0, As, PW), PW0 \== [], As \== [],
    tr_all_adjectives(english, As), \+ tr_all_adjectives(english, PW0),
    tr_phrase_np(english, PW0, NP), !,
    tr_complements(english, Rest, yes, Cs).
tr_complements0(foreign, Ws, _, [oc(NP, As)|Cs]) :-
    \+ tr_read_copula,                                  % the copula's adjective is its own predicate
    append(As, Rest0, Ws), As \== [], tr_all_adjectives(foreign, As),
    Rest0 = [D|_], tr_determiner(foreign, D, _, _),
    tr_phrase_words(foreign, Rest0, PW, Rest), PW \== [],
    tr_phrase_np(foreign, PW, NP), !,
    tr_complements(foreign, Rest, yes, Cs).
%% A BARE TIME PHRASE IS AN ADJUNCT AND NOT AN OBJECT. `Sabato Mladic
%% aveva spedito un fax' is `On Saturday Mladic had sent a fax' -- and none
%% of the three languages puts a preposition there, so the subject reader
%% took `Sabato Mladic' for one phrase, found `Mladic' was no adjective of
%% its noun, and refused the sentence. WHICH NOUNS ARE TIMES IS THE
%% LESSON'S, in the bare-class shape `"amigo" is a person.' already has, so
%% reason.pl did not move -- and being an adjunct is what lets the fronted
%% clause above take it.
%% A LONE WORD THAT IS AN ADVERB TOO IS THE ADVERB: `Ora è indispensabile
%% procedere' is now, and `ora' is also the hour the lesson calls a time --
%% read as a bare time phrase it came out `proceder a invertir hora'. A bare
%% singular time noun is an adjunct only where it names a day (`Sabato
%% Mladic'), which is no adverb.
tr_complements0(Side, Ws, Seen, [at_time(NP)|Cs]) :-
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [],
    \+ ( PW = [W1], tr_is(Side, W1, adverb) ),
    tr_phrase_np(Side, PW, NP), tr_time_phrase(NP), !,
    tr_complements(Side, Rest, Seen, Cs).
tr_complements0(Side, Ws, _, [obj(NP)]) :-
    tr_phrase_nrc(Side, Ws, NP), !.
%% (and an object with a participle after its comma, tr_phrase_aside/4)
tr_complements0(Side, Ws, _, [obj(NP)|Cs]) :-
    tr_phrase_aside(Side, Ws, NP, Rest), !,
    tr_complements(Side, Rest, yes, Cs).
%% ... and the phrase of an article, the word for `more' and a participle
%% with its agent (tr_np/3's rel/3 with pdeg/1): `..., la más esperada por
%% los aficionados' -- the phrase words end at `la', which the pronoun
%% reading then took. The longest agent first.
tr_complements0(foreign, [D, w(M, MC), w(P, PC)|Ws], Seen, [obj(NP)|Cs]) :-
    tr_determiner(foreign, D, _, article), tr_degree_word(M), tr_participle_here(foreign, P, _),
    length(Ws, N), between(0, N, I), K is N - I, length(AW, K), append(AW, Rest, Ws),
    tr_np(foreign, [D, w(M, MC), w(P, PC)|AW], NP), NP = rel(_, _, _), !,
    tr_complements(foreign, Rest, Seen, Cs).
%% AN ADJECTIVE LIST DOES NOT END ON ITS COORDINATOR: `el éxito, discreto
%% pero al fin y al cabo éxito, de esta Lucia' -- the phrase's words ran on
%% to `pero', and `but' came out as one of the adjectives. What follows the
%% coordinator is no adjective, so the coordinator joins the adjectives to
%% it, as cnj/1 joins two complements.
%% (the list's first word must be one, which is cheap to ask and is asked
%% first: asked of every word list, the phrase words cost Livata's sentences
%% 5 to 13 % more to read -- and the list is three words at least, an
%% adjective, the coordinator and what it joins them to, which is free to
%% ask and saves Tatoeba's 400 sentences 55 000 inferences)
tr_complements0(Side, Ws, _, [adj(As), cnj(K)|Cs]) :-
    Ws = [A1, _, _|_], tr_predicate_word(Side, A1),
    tr_phrase_words(Side, Ws, PW, Rest), Rest \== [],
    append(As, [K], PW), As \== [], K = w(_, _), tr_coord(Side, K),
    tr_all_adjectives(Side, As), \+ tr_verbless_thing(Side, As), !,
    tr_complements(Side, Rest, yes, Cs).
%% AN ADJECTIVE AND THE CLAUSE SAID OF IT: `Es difícil que el perro coma',
%% `Hoy es más difícil que pase algo así' -- difficult THAT it happens. The
%% phrase's words ran on through `que' as a relative clause on `difícil',
%% and Italian wrote the same words from that reading; the adjectives are
%% the predicate, and the clause after them the `that' clause it is. It is
%% tried before the phrase reader below, which is what keeps the relative
%% reading from being the one taken -- a guard in tr_np/3 refusing a
%% relative clause on bare adjectives bought nothing beside it, measured,
%% and cost 0.7 million inferences in one sentence of the controls.
%% (and nothing is committed to until the clause reads: `más grande que el
%% perro' is the comparison the reader below finds)
tr_complements0(foreign, Ws, Seen, [adj(As)|Cs]) :-
    Ws = [A1, _, _|_], tr_predicate_word(foreign, A1),
    append(As, [W|More], Ws), As \== [], tr_that_here(foreign, W), More \== [],
    tr_all_adjectives(foreign, As), \+ tr_verbless_thing(foreign, As),
    tr_complements0(foreign, [W|More], Seen, Cs), Cs = [that(_)|_], !.
tr_complements0(Side, Ws, _, [C|Cs]) :-
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [],
    (   tr_all_adjectives(Side, PW), \+ tr_verbless_thing(Side, PW) -> C = adj(PW)
    ;   tr_phrase_np(Side, PW, NP), C = obj(NP)
    ),
    tr_complements(Side, Rest, yes, Cs).

%% A RELATIVE CLAUSE AFTER A COMMA SAYS SOMETHING MORE OF THE PHRASE BEFORE
%% IT: `Un capitolo riassume la sperimentazione sul vaccino contro la
%% pertosse, che ha fatto passare la protezione ... dal 30 al 90%.' The
%% phrase ends at the comma (tr_phrase_words/4), and what followed it was
%% read as a `che' clause of the VERB's -- `summarises ..., that has made'
%% with nobody for its subject -- which no writer could write. It is the
%% phrase's, set off with a comma, and it runs to the end of its piece as a
%% `che' clause does. nrc(Phrase, Role, Clause) is the term, rc/3's shape,
%% and every writer puts the comma back before the relative word. It hangs
%% on the LAST phrase before the comma, which is where every language here
%% writes it, whichever phrase the clause is about.
tr_phrase_nrc(Side, Ws, nrc(NP, Role, S)) :-
    append(_, [comma|After], Ws), tr_nrc_start(Side, After), !,
    tr_phrase_words(Side, Ws, PW, [comma|R1]), PW \== [],
    tr_nrc_start(Side, R1), \+ tr_all_adjectives(Side, PW),
    tr_relative_clause(Side, R1, Role, S),
    tr_phrase_np(Side, PW, NP), !.

%% what opens such a clause: the relative word, or a preposition before it
%% and an article between them -- `joyas de este tipo de instrumentos, POR
%% LAS QUE el mejor de los intérpretes perdería la cabeza', which read as a
%% clause of the verb's came out `per le che'
tr_nrc_start(Side, [w(RW, _)|_]) :- tr_relative_word(Side, RW), !.
tr_nrc_start(Side, [P, w(RW, _)|_]) :- tr_is(Side, P, preposition), tr_relative_word(Side, RW), !.
tr_nrc_start(Side, [P, D, w(RW, _)|_]) :-
    tr_is(Side, P, preposition), tr_determiner(Side, D, _, article), tr_relative_word(Side, RW), !.

%% a phrase's words read as its phrase, and a relative clause after a comma
%% with them: the rest is what follows, and nothing does after such a clause
tr_phrase_rest(Side, Ws, NP, []) :- tr_phrase_nrc(Side, Ws, NP), !.
tr_phrase_rest(Side, Ws, NP, Rest) :- tr_phrase_aside(Side, Ws, NP, Rest), !.
tr_phrase_rest(Side, Ws, NP, Rest) :-
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [], tr_phrase_np(Side, PW, NP).

%% A PARTICIPLE AFTER A COMMA IS THE PHRASE'S TOO: `le più canicolari Eolie,
%% interdette al traffico dal 4 al 24 agosto, e l'isola di Ustica' -- the
%% islands closed to traffic. Read with the commas taken out, `al traffico e
%% l'isola' was one phrase, the island joined to the traffic. It is a reduced
%% relative with the participle's own adjuncts up to the next comma, and
%% aside(Closed) among them says whether a comma closed it, so every writer
%% puts back the commas the source had; a coordinator after the closing
%% comma joins a second phrase to the first.
%% ... AND A PARTICIPLE WITH ITS DEGREE, AFTER A PHRASE THAT HAS ONE:
%% `una adhesión más limitada, más contenida' is a more limited, more
%% restrained adherence -- the phrase before the comma is itself a reduced
%% relative (tr_np/3), and the participle after it agrees with the same noun,
%% where read with the phrase refused it was said of the sentence's subject
%% and came out `più contenuti'.
tr_phrase_aside(Side, Ws, NP, Rest) :-
    append(PW, [comma|R0], Ws), PW \== [], \+ memberchk(comma, PW),
    (   R0 = [w(M, _), w(P, PC)|R1], Side == foreign, tr_degree_word(M) -> Deg = yes
    ;   R0 = [w(P, PC)|R1], Deg = no
    ),
    tr_participle_here(Side, P, L), \+ tr_is(Side, w(P, lower), noun),
    (   append(CW, [comma|R2], R1), \+ memberchk(comma, CW) -> Closed = yes
    ;   CW = R1, R2 = [], Closed = no
    ),
    (   CW == [] -> Cs0 = []
    ;   tr_complements(Side, CW, Cs0), tr_adjuncts(Cs0), \+ memberchk(sep, Cs0)
    ),
    tr_phrase_np(Side, PW, NP1), ( NP1 = np(_, _, _, _, _) -> true ; NP1 = rel(np(_, _, _, _, _), _, _) ),
    tr_np_head(NP1, H1),
    (   Deg == yes -> H1 = np(Det1, _, _, _, _), tr_degree_of(foreign, Det1, Degree), Cs00 = [pdeg(Degree)|Cs0]
    ;   Cs00 = Cs0
    ),
    tr_rel_agreement(Side, P, H1, Cs00, Cs1), tr_rel_case(PC, Cs1, Cs),
    A = rel(NP1, L, [aside(Closed)|Cs]),
    (   Closed == yes, R2 = [C|R3], C = w(_, _), tr_coord(Side, C), R3 \== [],
        tr_phrase_rest(Side, R3, NP2, Rest0)
    ->  NP = co(C, A, NP2), Rest = Rest0
    ;   NP = A, Rest = R2
    ).

%% A WORD STANDING ALONE IN A CLAUSE WITH NO VERB IS A THING NAMED, NOT ONE
%% PREDICATED, because nothing is there to predicate it of: `Grazie
%% all'Arma ..., a Provincia, Regione Lazio, volontari, ai cani' thanks the
%% volunteers, and `volontari' -- a noun and an adjective -- read first as
%% the adjective came out `voluntario', one thing and voluntary. Only a word
%% the lesson calls a noun too, and only where no verb was read (the gapped
%% clause and a front, tr_read0/4, which set the group to none).
tr_verbless_thing(Side, [W]) :- tr_global('$tr_read_group', none), tr_is(Side, W, noun), !.

%% a phrase whose noun the lesson calls a time
tr_time_phrase(np(_, _, _, W, _)) :- tr_noun_of_lesson(W, Noun), tr_holds(time(Noun)).
tr_time_phrase(app(NP, label, _)) :- tr_time_phrase(NP).

%% what may follow a conjunction between two complements: an infinitive or
%% a preposition, or an adverb and then one of those -- `di aver lasciato i
%% bimbi ... ma POI di essersi persa'
tr_after_coord(Side, Ws) :- ( tr_starts_infinitive(Side, Ws) ; Ws = [P|_], tr_is(Side, P, preposition) ), !.
%% ... or a participle standing alone, the verb before it understood: `gli
%% abbiamo messo delle coperte E AFFIDATI al 118'
tr_after_coord(Side, [w(P, C)|_]) :- tr_participle_here(Side, P, _), \+ tr_is(Side, w(P, C), adjective), !.
tr_after_coord(Side, [A|Ws]) :- tr_is(Side, A, adverb), tr_after_coord(Side, Ws).

%% what may follow a conjunction standing between two complements
tr_starts_infinitive(foreign, [w(V, _)|_]) :- tr_solve(infinitive_of(V, _)), !.
tr_starts_infinitive(english, [w(to, _), w(_, _)|_]).

%% a phrase, or two joined
%% ... and the second half is a list again, split at its own first
%% coordinator: `compañeros y vecinos, emigrantes y minorías' is four
%% phrases, and read once it was one phrase and a noun with three adjectives
tr_phrase_np(Side, PW, co(C, N1, N2)) :-
    tr_conjunction_split(Side, PW, W1, C, W2), !, tr_object_phrase(Side, W1, N1), tr_phrase_np(Side, W2, N2).
tr_phrase_np(Side, PW, NP) :- tr_object_phrase(Side, PW, NP).

%% the word the lesson puts before an object of a class -- `The word "a"
%% precedes the person' -- and whether a phrase is of that class: a name
%% is a person (and a name), a phrase is what the lesson calls its noun,
%% two joined are when both are, and `whom' asks for a person. The rule
%% over pronouns and the verb is not a marker.
tr_marker_word(P) :- tr_marker_word(P, _).
tr_marker_word(P, Class) :- tr_solve(precede(P, Class)), Class \== verb, !.

tr_of_class(person, person) :- !.
tr_of_class(rc(NP, _, _), Class) :- !, tr_of_class(NP, Class).
tr_of_class(nrc(NP, _, _), Class) :- !, tr_of_class(NP, Class).
tr_of_class(ncl(NP, _), Class) :- !, tr_of_class(NP, Class).
tr_of_class(app(NP, _, _), Class) :- !, tr_of_class(NP, Class).
tr_of_class(all(_, NP), Class) :- !, tr_of_class(NP, Class).
%% a noun the sentence left out is of the class its sentence needs: `a un
%% grupo y el más débil' is two of the same thing
tr_of_class(np(_, _, _, elided(_), _), _) :- !.
tr_of_class(ell(_, _, _, _), _) :- !.
tr_of_class(name(_), Class) :- !, ( Class == name ; Class == person ), !.
tr_of_class(co(_, A, B), Class) :- !, tr_of_class(A, Class), tr_of_class(B, Class).
tr_of_class(np(_, _, _, W, _), Class) :- tr_noun_of_lesson(W, Noun), G =.. [Class, Noun], tr_holds(G).

%% a phrase's noun as the lesson's word: read on the lesson's side it is
%% the lexeme, read in English it is the lexeme's first meaning
tr_noun_of_lesson(w(NW, _), Noun) :-
    tr_side_here(Side),
    (   Side == foreign -> tr_lexeme(foreign, NW, Noun, _)
    ;   tr_lexeme(english, NW, L, _), tr_meanings_of(L, foreign, noun, [Noun|_])
    ), !.

%% the marker before an object out, in the lesson's language: `a Omar' --
%% never after the copula, whose complement is no object (`son nuestros
%% amigos')
tr_marker(foreign, What, [o(P, lower)]) :-
    \+ ( catch(nb_getval('$tr_verb', V), _, fail), ( memberchk(V, [is, none]) ; V = refl(_) ) ),    % nor where there is no verb at all
    tr_marker_word(P, Class), tr_of_class(What, Class), !.
tr_marker(_, _, []).

%% the words of one phrase: up to the next preposition, adverb or object pronoun
%% A REDUCED RELATIVE AND ITS AGENT STAY INSIDE THE PHRASE, or the phrase
%% would end at the preposition and the agent would hang on the sentence's
%% verb instead of on the participle it belongs to.
%% A RELATIVE CLAUSE STAYS INSIDE ITS PHRASE AND RUNS TO THE END OF IT:
%% `contra "esos", que son culpables de "todo"', `el caldo que el pequeño
%% aprende en familia', `el grupo social al que pertenece'. The phrase's own
%% words end where a relative word starts (tr_phrase_words0/4 stops there),
%% and everything from that word on is the clause -- which is what the
%% `che'/`that' complement of 1.6.8 already does, for the reason it gives:
%% a shortest-first cut would end the clause at the first place that reads.
tr_phrase_words(Side, Words, PW, Rest) :-
    tr_phrase_words0(Side, Words, PW0, Rest0),
    (   PW0 \== [], Rest0 \== [], \+ tr_comparison_start(Side, Rest0),
        ( tr_relative_start(Side, Rest0) -> true ; tr_clause_opener(Side, Rest0) )
    ->  (   append(PW0, Rest0, PW), Rest = []
        %% ... OR THE PHRASE ALONE, where a preposition and the relative that
        %% follows one open a part with NO VERB: `quattro governi di cui solo
        %% uno ... uscito da elezioni generali' is four governments, of which
        %% only one came from elections -- read as a relative clause it had
        %% no verb and the sentence was refused, where the same words after
        %% a comma read (rpp/2). Asked only when the clause reading failed.
        ;   Rest0 = [P, w(R, _)|_], tr_is(Side, P, preposition), tr_rel_after_prep(Side, R),
            PW = PW0, Rest = Rest0
        %% ... OR THE PHRASE AND ITS CLAUSE UP TO A SECOND RELATIVE THAT OPENS
        %% ON AN ARTICLE: `de los ciudadanos que ofrecen estos inventos LO QUE
        %% los hace tan deseados' -- the clause ends where the phrase whose
        %% noun a relative clause stands for begins (tr_relative_clause/4).
        %% Asked only when the reading to the end failed.
        ;   Side == foreign, append(RC, [D, w(Q, QC)|After], Rest0), RC = [_, _|_], After \== [],
            tr_relative_word(Side, Q), ( tr_determiner(Side, D, _, article) -> true ; tr_noun_replacer(Side, D) ),
            append(PW0, RC, PW), Rest = [D, w(Q, QC)|After]
        %% ... OR THE PHRASE ALONE BEFORE A CLAUSE OF THE VERB'S: `descubrieron
        %% con cierta sorpresa QUE el telefonino ... estaba vacío' -- a phrase
        %% between the verb and the `that' clause it takes, where no relative
        %% clause reads (tr_relative_clause/4). Only a clause whose subject
        %% stands first, as a `that' clause's does: `dagli uomini del soccorso
        %% alpino e speleologico CHE LI hanno trovati vigili' is the men's
        %% relative clause with its subject left out, and taken for the verb's
        %% clause it read with the rest of Livata's sixth sentence as one
        %% statement, `despiertos y condiciones ... en bienes', before the
        %% division at `nonostante' was tried -- and only a PHRASE, with a
        %% noun: `si sa solo che la famiglia era ...' offered `solo' alone,
        %% and every reading of the rest was tried under it
        ;   Side == foreign, Rest0 = [T|After], tr_that_here(Side, T), tr_subject_first(After),
            once(( member(X0, PW0), tr_is(Side, X0, noun) )),
            PW = PW0, Rest = Rest0
        )
    ;   PW = PW0, Rest = Rest0
    ).

%% a word that is a noun too, after a phrase that is a determiner and no
%% noun yet
tr_noun_after_det(Side, [D|Mid], R) :-
    tr_determiner(Side, D, _, _), tr_is(Side, R, noun),
    \+ ( member(X, Mid), tr_is(Side, X, noun) ), !.

%% an adverb at the head of a phrase and a number after it is the phrase's
%% own count, whatever else the word is: `con oltre 50 mezzi' is with more
%% than fifty, and `oltre' is a preposition too, which ended the phrase
%% before it began
tr_counting_adverb(Side, [], [A, M|_]) :-
    tr_is(Side, A, adverb), tr_is(Side, M, number),
    \+ tr_determiner(Side, M, _, _), !.          % `en conjunto UNOS 980': the article is no count

%% AN ARTICLE AND A `de' PHRASE WITH NO NOUN BETWEEN THEM ARE ONE PHRASE:
%% `en los de clase media' -- in those of the middle class. The article
%% stands for a noun the sentence already said, and the preposition belongs
%% to it; without this the phrase ended at the preposition and was the
%% article alone, which reads as the object pronoun `los'.
tr_phrase_words0(Side, [D, P|Ws], [D, P|PW2], Rest) :-
    ( tr_determiner(Side, D, _, article), \+ tr_standalone_det(Side, D) -> true ; tr_noun_replacer(Side, D) ),
    tr_is(Side, P, preposition), tr_means_of(Side, P),
    tr_phrase_words0(Side, Ws, PW2, Rest), PW2 \== [], !.
tr_phrase_words0(Side, Words, PW, Rest) :-
    append(PW0, Rest0, Words), PW0 \== [],
    last(PW0, w(P, _)), tr_participle_here(Side, P, _),
    %% ... a participle closing a phrase with no preposition in it: `la
    %% partecipazione del 41,5% detenuta dal fondo' is the share and then
    %% what holds it, and taken whole it was one phrase with a phrase of `di'
    %% inside, which no phrase reads, so the sentence was refused
    %% -- and no VERB before the participle either: `I piccoli sono stati
    %% raggiunti dagli uomini ...' is a clause, and it was asked as a phrase
    %% once for every place a verb could start after it -- each time reading
    %% the agent and, since the agent may take adjuncts, the rest of that
    %% region as complements: 8.5 million inferences to 16.2 for Livata's
    %% sixth sentence, and 8.0 with this
    append(Front, [_], PW0),
    %% ... and no COMMA, which ends a phrase as it does below: `una escena,
    %% la más esperada por los aficionados' ran on to the participle and
    %% was one phrase with a comma in it, which no phrase reads
    \+ memberchk(comma, Front),
    \+ ( member(Q, Front), ( tr_is(Side, Q, preposition) ; tr_is(Side, Q, verb) ),
         \+ tr_is(Side, Q, noun), \+ tr_is(Side, Q, adjective) ),
    Rest0 = [B|_], tr_is(Side, B, preposition), tr_means_by(Side, B),
    tr_reduced_agent(Side, Rest0, _), !,
    append(PW0, Rest0, PW), Rest = [].
tr_phrase_words0(Side, Words, PW, Rest) :-
    append(PW, Rest, Words),
    (   Rest == []
    ->  true
    ;   Rest = [R|_],
        (   R == comma
        ;   PW \== [], tr_relative_start(Side, Rest)
        %% a gerund ends the phrase before it: `a un inmigrante utilizando un
        %% bate' is the phrase and then how it was done
        ;   PW \== [], R = w(G, _), tr_gerund_here(Side, G, _), \+ tr_is(Side, R, noun)
        %% ... and so does an infinitive: `è stato difficile riprenderli' is
        %% an adjective and then what was difficult, never one phrase
        ;   PW \== [], tr_starts_infinitive(Side, Rest), \+ tr_is(Side, R, noun)
        %% ... and a question word: `all'ospedale di Subiaco DOVE i medici'
        ;   PW \== [], R = w(QW, _), tr_indirect_word(Side, QW, _)
        %% ... except a `de' after a coordinator and an article, which is
        %% the second half's own: `el pan de los gatos y el de los chicos'
        %% ended at the second `de' and left `el' as a phrase of one article
        ;   tr_is(Side, R, preposition), \+ tr_counting_adverb(Side, PW, Rest), \+ tr_date_inside(Side, PW, Rest),
            \+ ( tr_means_of(Side, R), append(_, [Co, LA], PW),
                 tr_coord(Side, Co), tr_determiner(Side, LA, _, article), \+ tr_standalone_det(Side, LA) ),
            %% ... nor a word that is a NOUN too, after a determiner and before
            %% the phrase has a noun: `optó por una vía más instintiva' is a
            %% way, and `vía' is also the preposition `via', which ended the
            %% phrase at `una'
            \+ tr_noun_after_det(Side, PW, R)
        ;   tr_plain_adverb(Side, R), \+ tr_counting_adverb(Side, PW, Rest),
            %% ... but not a word that is an ADJECTIVE too while the phrase has
            %% no noun yet: `fin dalle prime ore' is the first hours, and
            %% `prime' is also `before' -- the phrase ended at its article
            \+ ( tr_is(Side, R, adjective), \+ ( member(X0, PW), tr_is(Side, X0, noun) ) ),
            %% ... nor a NOUN too, right after a determiner: `solo la via della
            %% mediazione' is the way, and `via' is also `away' -- the
            %% phrase ended at `la', which was then the pronoun `her'
            \+ tr_noun_after_det(Side, PW, R),
            %% ... nor an adverb with the phrase's PARTICIPLE after it (tr_np/3
            %% reads the pair): `sesiones a puerta cerrada centradas en ...'
            \+ tr_adverb_before_participle(Side, PW, Rest)
        %% an object pronoun ends a phrase that has begun; at its head it IS
        %% the phrase, which is reached only when the pronoun readings above
        %% stood down for a relative clause after it (`contra esos, que son')
        ;   PW \== [], tr_object_pronoun_here(Side, Rest),
            \+ ( last(PW, LW0), tr_coord(Side, LW0) ),    % `sopas y otros': the pronoun is the second half
            \+ ( last(PW, LD0), tr_determiner(Side, LD0, _, article) )   % `l'altra': an article is no phrase alone
        %% ... AND A DETERMINER AFTER A PHRASE THAT ALREADY HAS ITS NOUN
        %% STARTS THE NEXT ONE. `mettere in pericolo LA casa' -- the
        %% infinitive's phrase is `pericolo' and the object is `la casa',
        %% and with no boundary here the three words were one phrase with
        %% an article among its adjectives and the sentence was refused.
        %%
        %% THE NOUN IS WHAT MAKES IT SAFE, and a plain `PW \== []' was not:
        %% `dal suo quartier generale' cut after `il', which is a phrase of
        %% one article, and a sentence that read before stopped reading.
        %% A determiner before this phrase's noun is this phrase's own.
        %%
        %% AND NOT AFTER A CONJUNCTION, which the case caught at once: `el
        %% pan y el huevo' cut before the second `el' and wrote `el y pan
        %% el huevo'. A determiner after `y' opens the second half of a
        %% phrase the splitter is about to take apart, not a new phrase.
        %% -- a NUMBER last in the phrase is a noun for that too: `concentrando en
        %% 1999 el 17,1% del total', `se estima en 45 el número de empresas' --
        %% a year, or a count with its noun left out, and read on through the
        %% article `1999 el 17,1%' was one phrase and the sentence refused
        ;   PW \== [], tr_determiner(Side, R, _, _),
            %% ... but a word that is an ADJECTIVE too starts one only with a
            %% word after it for it to head: `con due persone diverse' is
            %% different people, and `diverse' is `several' as well -- cut
            %% there, it was an adjective of the clause's own and agreed with
            %% the subject, `dos personas diverso'
            \+ ( tr_is(Side, R, adjective), \+ ( Rest = [_, N0|_], N0 = w(_, _), \+ tr_is(Side, N0, preposition) ) ),
            member(X, PW), ( tr_is(Side, X, noun) ; tr_name_word(Side, X) ; last(PW, X), tr_is(Side, X, number) ),
            \+ ( last(PW, LW), tr_coord(Side, LW) ),
            \+ ( last(PW, LP), tr_is(Side, LP, preposition) )  % `y el de LOS chicos'
        %% ... A NAME IS A PHRASE'S NOUN FOR THAT, and a number after one starts
        %% the next phrase too: `acquisirà da Veba LA partecipazione' and
        %% `verserà a Veba 3,65 miliardi' put a short phrase with its
        %% preposition before the object, and the name no lesson knows was no
        %% noun to end at -- so `Veba la partecipazione' was one phrase with
        %% an article among its adjectives, and the sentence was refused
        ;   PW \== [], last(PW, LN), tr_name_word(Side, LN), tr_is(Side, R, number)
        %% ... and an ADJECTIVE after a name is no part of its phrase: `Capri,
        %% Procida, Ischia, Giglio, Eolie e Ponza off limits per i turisti' is
        %% the islands and then what they are, a clause with its verb left
        %% out, and the name with the adjective after it read as no phrase
        ;   PW \== [], last(PW, LN2), tr_name_word(Side, LN2), R = w(_, lower),
            tr_is(Side, R, adjective), \+ tr_is(Side, R, noun),
            %% ... unless the name is APPOSED to a noun after a determiner:
            %% `il governo Dini successivo' is one phrase, the government that
            %% came after, and tr_apposed_name/3 reads the adjective there
            \+ ( PW = [D5|_], tr_determiner(Side, D5, _, _),
                 member(N5, PW), N5 \== LN2, tr_is(Side, N5, noun) )
        %% ... AND A TITLE BEFORE A NAME STARTS THE NEXT PHRASE: `di Monreale
        %% monsignor Salvatore Cassisa' is the place and then the person, the
        %% title taking no article to say so (tr_np/3's title clause)
        ;   PW \== [], R = w(TW, _), Rest = [_, w(_, upper)|_], tr_title_word(Side, TW),
            member(X1, PW), ( tr_is(Side, X1, noun) ; X1 = w(_, upper) )
        %% ... AND A NOUN IN THE OTHER NUMBER, AFTER A PHRASE THAT HAS ITS
        %% NOUN, BEGINS THE NEXT PHRASE: `portando a conoscenza di un comitato
        %% etico TEMPI e modi della terapia' is the committee, and then the
        %% times and ways it is told of. With no boundary `tempi' -- a word
        %% the lesson knows only as a noun -- was an adjective of `comitato'
        %% and came out `un templo comité'. An adjective agrees with its noun,
        %% so a word that is no adjective and has no form in the phrase's
        %% number is no part of it. Only on the lesson's side: English puts a
        %% noun of either number before its head (`the university students').
        %% -- and never across a coordinator, which joins two phrases the
        %% splitter takes apart: `pan y huevos' cut before `huevos'
        ;   Side == foreign, PW \== [], R = w(RW, _), tr_is(Side, R, noun), \+ tr_is(Side, R, adjective),
            \+ ( member(CW, PW), tr_coord(Side, CW) ),
            member(w(XW, XC), PW), tr_is(Side, w(XW, XC), noun),
            findall(XN0, tr_lexeme(Side, XW, _, XN0), XNs0), sort(XNs0, [XN]),
            \+ tr_lexeme(Side, RW, _, XN)
        %% ... and after a run of ADJECTIVES with no noun, which is a
        %% predicate: `sono stati eroici UN'intera notte' is heroic, and then
        %% for how long -- read as one phrase it had an article among its
        %% adjectives and no reading at all
        ;   PW \== [], tr_determiner(Side, R, _, article), \+ tr_standalone_det(Side, R),
            tr_all_adjectives(Side, PW), \+ ( last(PW, LW2), tr_coord(Side, LW2) )
        %% ... and a coordinator before a PREPOSITION joins two complements,
        %% not two halves of this phrase: `en los barrios de la ciudad y en
        %% los de clase media' -- read as one phrase, `y' was an adjective of
        %% `ciudad' and came out `of the and city'
        ;   PW \== [], tr_coord(Side, R), Rest = [_, P2|_], tr_is(Side, P2, preposition)
        %% ... and so does one before a participle standing alone: `delle
        %% coperte e affidati al 118' is the blankets, and then entrusted
        ;   PW \== [], tr_coord(Side, R), Rest = [_, w(P4, C4)|_], tr_participle_here(Side, P4, _),
            \+ tr_is(Side, w(P4, C4), adjective), \+ tr_is(Side, w(P4, C4), noun)
        %% ... and so does a conjunction before an INFINITIVE: `un fax e
        %% invocare il sostegno' is the object and a second infinitive
        %% under the same purpose, never one phrase with `e' in it -- which
        %% is what the phrase splitter's `A e B' made of it, and it refused
        %% the sentence because the second half is no phrase.
        ;   Rest = [_|More], tr_coord(Side, R), tr_starts_infinitive(Side, More)
        %% ... and one before an ADVERB that one of those follows: `chiedere
        %% aiuto MA POI di essersi persa' is help, and then the other thing
        %% she said -- read as one phrase, `ma' was an adjective of `aiuto'
        ;   PW \== [], Rest = [_, A3|More3], tr_coord(Side, R), tr_is(Side, A3, adverb), \+ tr_is(Side, A3, adjective),
            tr_after_coord(Side, [A3|More3])
        ),
        %% asked only where a boundary was found, and not at every word
        \+ tr_degree_start(Side, Rest),             % `el más débil': `más' is a preposition too
        \+ tr_degree_before_participle(Side, PW, Rest)   % `una adhesión más limitada'
    ), !.

%% an object pronoun standing as one: not an article or a possessive with
%% its noun after it -- `la casa', `los libros', English's `her house'
tr_object_pronoun_here(Side, [w(W, _)|Ws]) :-
    tr_object_pronoun(Side, W, _),
    \+ ( tr_determiner(Side, w(W, lower), _, K), Ws = [N|_], tr_content_word(Side, N),
         %% ... a POSSESSIVE before a pronoun is none: `non importa loro
         %% null'altro' is to them, nothing else -- `nulla' is also the
         %% adjective `invalid', and `loro' was their nothing
         \+ ( K == possessive, tr_is(Side, N, pronoun) ) ),
    \+ ( tr_all_word(Side, W), Ws = [D|_], tr_determiner(Side, D, _, _) ).
tr_content_word(Side, N) :- ( tr_is(Side, N, noun) ; tr_is(Side, N, adjective) ; tr_is(Side, N, number) ), !.
%% ... and so is an adjective the complements were folded to a degree of
%% before this is asked: `Eres la mejor', `Eres la más buena' are the best
%% one, and read as the pronoun `la' they came out `You are her better'
tr_content_word(_, deg(_, _)) :- !.
%% ... and so is the lesson's word for `more' before a participle it has
%% not folded: `la más esperada por los aficionados' is the most awaited one
tr_content_word(foreign, w(M, _)) :- tr_degree_word(M), !.
%% ... and so is a NAME: `dalla Fim Cisl' is `da', the article and the
%% union's name, and read as the pronoun `la' before a stranger it came out
%% `desde ella Fim Cisl'
tr_content_word(Side, N) :- tr_name_word(Side, N), !.

%% a word that means `all': English's own, or one the lesson gives
tr_all_word(english, all) :- !.
tr_all_word(foreign, T) :- tr_lexeme(foreign, T, L, _), tr_solve(mean(L, all)), !.

tr_object_phrase(Side, [w(W, C)], pronoun(w(W, C))) :- tr_object_pronoun(Side, W, _), !.
tr_object_phrase(Side, Words, NP) :- tr_np(Side, Words, NP).

%% A PHRASE WHOSE NOUN THE SENTENCE LEFT OUT. `el más débil' is the weakest
%% one and `los de clase media' those of the middle class: an article and
%% then adjectives, or an article and a `de' phrase, with no noun. The noun
%% slot holds elided(Gender), the gender the article lends it -- the one
%% thing the missing noun would have said -- so every word written after it
%% agrees; and a `de' phrase travels as ell(Det, Gender, Number, PP).
%% ... AND A COUNT BEFORE THE ADJECTIVES: `Los dos primeros se han quedado
%% en casa' is the first two, the players left out, and with the number
%% where the adjectives were looked for the phrase was refused
tr_np(Side, [D, M|Ws], np(det(DK, DL, D), M, Adjs, elided(G), Number)) :-
    Ws \== [], tr_determiner(Side, D, DL, DK), DK == article, \+ tr_standalone_det(Side, D),
    tr_is(Side, M, number),
    tr_np(Side, [D|Ws], np(_, none, Adjs, elided(G), Number)), !.
tr_np(Side, [D|Ws], np(det(DK, DL, D), none, Adjs, elided(G), Number)) :-
    Ws \== [], tr_determiner(Side, D, DL, DK), DK == article, \+ tr_standalone_det(Side, D),
    tr_degree_of(Side, det(DK, DL, D), Degree), tr_degrees(Side, Degree, Ws, Adjs),
    Adjs \== [], forall(member(A, Adjs), ( A = deg(_, _) ; tr_is(Side, A, adjective) )),
    ( member(deg(_, _), Adjs) -> true ; \+ ( member(A, Ws), tr_is(Side, A, noun) ) ),
    tr_det_gender(Side, D, DL, G0, Number),
    %% an ELIDED article says no gender -- `l'' is `lo' and `la' alike -- and
    %% the adjective after it does: `dall'altra' is the other one, feminine
    (   D = w(DW, _), tr_solve(elision_of(DW, _)),
        member(w(AW, _), Adjs), tr_lexeme(Side, AW, AL, _), tr_gender(AL, AG), AG \== none
    ->  G = AG
    ;   G = G0
    ), !.
%% ... AND ONE WHOSE NOUN A RELATIVE CLAUSE STANDS FOR: `un descalabro como
%% el que sufrió el Madrid en Toledo' is like the one Madrid suffered. The
%% article and the clause are the whole phrase, rel(Role, Clause) where a
%% `de' phrase would be, and each writer says `quello che', `el que', `the
%% one that'.
tr_np(Side, [D, w(R, RC)|Ws], ell(det(DK, DL, D), G, Number, rel(Role, S))) :-
    Side == foreign, Ws \== [],
    tr_determiner(Side, D, DL, DK), DK == article, \+ tr_standalone_det(Side, D),
    tr_relative_word(Side, R),
    tr_relative_clause(Side, [w(R, RC)|Ws], Role, S), Role \= pp(_),
    tr_det_gender(Side, D, DL, G, Number), !.
tr_np(Side, [D, P|Ws], ell(det(DK, DL, D), G, Number, pp(P, NP))) :-
    tr_determiner(Side, D, DL, DK), DK == article, \+ tr_standalone_det(Side, D),
    tr_is(Side, P, preposition), tr_means_of(Side, P), Ws \== [],
    tr_object_phrase(Side, Ws, NP),
    tr_det_gender(Side, D, DL, G, Number), !.
%% ... AND ONE OPENED BY A WORD THAT REPLACES THE NOUN (tr_noun_replacer/2):
%% `ha superato in durata quello di Berlusconi' is Berlusconi's government,
%% and read as the pronoun `that' it came out `eso de Berlusconi'. It
%% travels as the phrase an article would open -- the lesson's article for
%% `the', in the word's own gender and number -- so Spanish writes `el de'
%% and English `the one of'.
tr_np(foreign, [Q, P|Ws], ell(det(article, AL, Q), G, Number, pp(P, NP))) :-
    Ws \== [], tr_noun_replacer(foreign, Q), Q = w(QW, _),
    tr_is(foreign, P, preposition), tr_means_of(foreign, P),
    tr_object_phrase(foreign, Ws, NP),
    tr_lexeme(foreign, QW, L, Number), tr_gender(L, G),
    once(( tr_solve(mean(AL, the)), tr_class_of(AL, article) )), !.

%% ... AND ONE WITH A RELATIVE CLAUSE AFTER IT, WHAT SOMETHING DOES: `lo
%% que hace es "desacreditar" la investigación' -- the word the lesson says
%% replaces a noun (`The word "lo" replaces the noun.'), with the clause
%% where the `de' phrase is above, as `el que sufrió el Madrid' has it.
%% Read as the pronoun `lo', it came out `him that is ... ago'
tr_np(foreign, [Q, w(R, RC)|Ws], ell(det(article, AL, Q), G, Number, rel(Role, S))) :-
    Ws \== [], tr_noun_replacer(foreign, Q), Q = w(QW, _),
    tr_relative_word(foreign, R),
    tr_relative_clause(foreign, [w(R, RC)|Ws], Role, S), Role \= pp(_),
    tr_lexeme(foreign, QW, L, Number), tr_gender(L, G0), ( G0 == none -> G = masculine ; G = G0 ),
    once(( tr_solve(mean(AL, the)), tr_class_of(AL, article) )), !.
%% ... AND ONE WITH A PARTICIPLE AFTER IT: `quello guidato dal magnate
%% televisivo Silvio Berlusconi' is the one the tycoon led. It is the
%% reduced relative (rel/3) of a phrase whose noun was left out with nothing
%% after its head, ell(Det, G, N, none), so Spanish writes `el conducido
%% por', Italian `quello guidato da' and English `the one led by'.
tr_np(foreign, [Q, w(P, PC)|Rest], rel(ell(det(article, AL, Q), G, Number, none), L, Comps)) :-
    tr_noun_replacer(foreign, Q), Q = w(QW, _),
    tr_participle_here(foreign, P, L), \+ tr_is(foreign, w(P, lower), noun),
    \+ ( Rest == [], tr_is(foreign, w(P, lower), adjective) ),
    tr_lexeme(foreign, QW, QL, Number), tr_gender(QL, G), tr_participle_agrees(P, Number),
    ( Rest == [] -> Comps0 = [] ; tr_ptc_complements(foreign, L, Rest, Comps0) ),
    tr_rel_case(PC, Comps0, Comps),
    once(( tr_solve(mean(AL, the)), tr_class_of(AL, article) )), !.

%% the words that open a phrase whose noun was left out, and a degree word
%% before an adjective, which is no adverb standing alone
tr_ellipsis_start(Side, [D, P|_]) :-
    ( tr_determiner(Side, D, _, article), \+ tr_standalone_det(Side, D) -> true ; tr_noun_replacer(Side, D) ),
    tr_is(Side, P, preposition), tr_means_of(Side, P), !.
%% ... and a word that replaces the noun before a participle: `vede quello
%% guidato dal gatto' is the one the cat led (tr_np/3's rel/3 on ell/4), and
%% read as the pronoun `that' with a participle after it, `eso conducido'
tr_ellipsis_start(foreign, [Q, w(P, _)|_]) :-
    tr_noun_replacer(foreign, Q), tr_participle_here(foreign, P, _), \+ tr_is(foreign, w(P, lower), noun), !.

%% A WORD THE LESSON SAYS STANDS FOR A NOUN THE SENTENCE LEFT OUT, where its
%% language has no article for it: Italian's `quello di Berlusconi' is
%% Berlusconi's one. `The word "quello" replaces the noun.' is the line
%% Spanish's `el' has had since 1.6.15.
tr_noun_replacer(foreign, w(Q, _)) :-
    atom(Q), \+ tr_determiner(foreign, w(Q, lower), _, article),
    tr_lexeme(foreign, Q, L, _), tr_solve(replace(L, noun)), !.

%% AN ARTICLE THE LESSON ALSO CALLS A PRONOUN STANDING ALONE HEADS ITS OWN
%% PHRASE. `uno' is the masculine article and the pronoun `one', and `The
%% pronoun "uno" does not precede the verb' is what says it stands alone --
%% so `uno dei paesi' is one of the countries, as 1.6.7 read it, and never
%% an article whose noun was left out. A clitic (`la', `los') carries no
%% such denial, and `los de clase media' stays the ellipsis it is.
tr_standalone_det(foreign, w(W, _)) :- tr_lexeme(foreign, W, L, _), tr_solve(neg(precede(L, verb))), !.
tr_degree_start(foreign, [w(M, _), A|_]) :- tr_degree_word(M), tr_is(foreign, A, adjective), !.
tr_degree_start(english, [w(M, _), A|_]) :- en_degree_marker(M, _), tr_is(english, A, adjective), !.
tr_degree_start(Side, [A, J|_]) :- tr_intensifier(Side, A, J), !.

%% an adverb before an adjective inside a phrase is the adjective's: `una
%% familia tan pacífica' is so peaceful a family, and read as an adverb of
%% the sentence it came out after the verb, the adjective left behind
tr_intensifier(Side, A, J) :-
    A = w(M, _), tr_adverb_word(Side, A), \+ tr_is(Side, A, adjective), \+ tr_is(Side, A, noun),
    \+ tr_determiner(Side, A, _, article),
    \+ ( Side == english, en_degree_marker(M, _) ), \+ ( Side == foreign, tr_degree_word(M) ),
    J = w(_, _), tr_is(Side, J, adjective).

%% an adverb does not inflect, so on the lesson's side the word itself is
%% asked: this runs on every word of every phrase the reader tries
tr_adverb_word(foreign, w(M, _)) :- !, tr_solve(adverb(M)).
tr_adverb_word(Side, A) :- tr_is(Side, A, adverb).

tr_intensify(_, [], []).
tr_intensify(Side, [A, J|Ws], [int(A, J)|Os]) :- tr_intensifier(Side, A, J), !, tr_intensify(Side, Ws, Os).
tr_intensify(Side, [W|Ws], [W|Os]) :- tr_intensify(Side, Ws, Os).

%% a word that means `of': English's own, or the lesson's
tr_means_of(english, w(of, _)) :- !.
tr_means_of(foreign, w(W, _)) :- tr_lexeme(foreign, W, L, _), tr_solve(mean(L, of)), !.

%% the words that open a relative clause: the relative word itself, a
%% preposition before it (`a cui'), or a preposition and an article before
%% it (`a el que', which is how `al que' reads once the contraction is
%% expanded)
tr_relative_start(Side, [w(R, _)|_]) :- tr_relative_word(Side, R), !.
tr_relative_start(Side, [P, w(R, _)|_]) :-
    tr_is(Side, P, preposition), tr_relative_word(Side, R), \+ tr_clause_opener(Side, [P, w(R, lower)]), !.

%% A NOUN'S OWN CLAUSE OPENS WITH THE WORD THE LESSON SAYS BEGINS IT and the
%% word for `that': Spanish's `prueba de que ...' (`The word "de" begins the
%% clause.'). Read as a relative after a preposition it was `proof of
%% which', and the clause took the phrase after the comma for its object.
tr_clause_opener(foreign, [w(P, _), W|_]) :-
    tr_lexeme(foreign, P, PL, _), tr_solve(begin(PL, clause)), tr_that_here(foreign, W), !.
tr_relative_start(Side, [P, D, w(R, _)|_]) :-
    tr_is(Side, P, preposition), \+ ( P = w(PW, _), tr_solve(mean(PW, like)) ),     % `como el que' compares
    tr_determiner(Side, D, _, article), tr_relative_word(Side, R), !.

%% the lesson's word for `than', and a phrase after it with no verb in it
%% -- and SOMETHING COMPARED BEFORE IT: the word that begins the comparative
%% or a word meaning same, identical or equal (tr_compared_before/1). Italian
%% says `than' with `di' before a phrase (`più grande del cane'), and without
%% this every `di' was one: the controls read `la historia de la
%% desaparición' as the story THAN the disappearance and wrote `que'.
%% -- AND NOT A PREPOSITION: Italian's `di' is `than' after `più' and `of'
%% in the superlative the same words make, `i Paesi più ricchi del mondo',
%% and only the article tells the two apart; read as `than' the twelve's
%% richest countries were refused, and `Dello stesso tenore il commento del
%% sindaco' compared everything after `stesso'. The lesson's word is still
%% the one written for `than' before a phrase (tr_than_word/2), so Spanish's
%% comparisons go into Italian, and an Italian one is read as `of'.
%% -- AND NOT A CLAUSE IN THE SUBJUNCTIVE: `Hoy es más difícil que pase algo
%% así' is harder THAT something like it happens, and `pase' is a pass as well
%% as the subjunctive of `pasar', so the comparison took it for a noun, more
%% difficult than a pass. A word the lesson states as a subjunctive right
%% after the word for `than' opens a clause.
tr_comparison_start(foreign, [w(Q, _)|Ws]) :-
    Ws \== [], tr_solve(mean(Q, than)), \+ tr_class_of(Q, preposition),
    tr_compared_before(Q),
    \+ ( member(w(V, _), Ws), tr_verb_form_word(V), \+ tr_is(foreign, w(V, lower), adjective) ),
    \+ ( Ws = [w(V1, _)|_], atom(V1), tr_subjunctive_word(V1) ), !.

%% (`"pasara" is the past subjunctive of "pasa".' is subjunctive_of/2 too, and
%% past/1 beside it)
tr_subjunctive_word(V) :- tr_solve(subjunctive_of(V, _)), !.

tr_compared_before(Q) :-
    tr_global('$tr_piece', Ws), is_list(Ws), append(Before, [w(Q, _)|_], Ws),
    member(w(W, _), Before),
    (   tr_degree_word(W)
    ;   tr_lexeme(foreign, W, L, _), tr_solve(mean(L, E)), memberchk(E, [same, identical, equal, less])
    ), !.

%% the lesson's word for `than': before an adjective the one it calls a
%% CONJUNCTION (`più che discutibile'), before a phrase one it does not
%% (`più ricco del mondo'), and the first it gives where it has only one
%% kind -- Spanish's `que' serves both
tr_than_word(adjective, W) :- tr_solve(mean(W, than)), tr_class_of(W, conjunction), !.
tr_than_word(phrase, W) :- tr_solve(mean(W, than)), \+ tr_class_of(W, conjunction), !.
tr_than_word(_, W) :- once(tr_solve(mean(W, than))).

%% a form of a verb of the lesson's -- a verb, a modal or an auxiliary --
%% that the lesson calls no noun. tr_form/5 alone answers for any word the
%% lesson knows, `el' among them, as its own third person.
tr_verb_form_word(V) :-
    tr_form(V, L, _, _, _), atom(L),
    ( tr_class_of(L, verb) ; tr_class_of(L, modal) ; tr_class_of(L, auxiliary) ),
    \+ tr_is(foreign, w(V, lower), noun), !.

%% the sentence says the two things are the same: a word before the
%% comparison meaning `same', `identical' or `equal'
tr_equative_piece(Q) :-
    tr_global('$tr_piece', Ws), is_list(Ws), append(Before, [w(Q, _)|_], Ws),
    member(w(W, _), Before), tr_lexeme(foreign, W, L, _), tr_solve(mean(L, E)),
    memberchk(E, [same, identical, equal]), !.

%% a relative word: English's own, or one the lesson calls one (`"que" is a
%% relative.')
tr_relative_word(english, W) :- !, memberchk(W, [that, which, who, whom]).
tr_relative_word(foreign, W) :- tr_solve(relative(W)), !.

%% the clause after a relative word, and what the word stands for in it
%% (and never with a second object that a relative clause stands for, after
%% one of its own: `los ciudadanos que ofrecen estos inventos LO QUE los hace
%% tan deseados' -- the clause is the citizens' and the phrase after it the
%% copula's subject, tr_cleft_fix/3; read as the clause's second object no
%% writer could write it, and the sentence was refused)
tr_relative_clause(Side, [w(R, _)|Ws], subject, S) :-
    tr_relative_word(Side, R), Ws \== [],
    tr_read_nested(Side, Ws, subject(rel), S0),
    S0 = s(_, asked(Q), G, Comps),
    \+ append(_, [obj(_), obj(ell(_, _, _, rel(_, _)))], Comps), !,
    %% THE GAP KEEPS THE NUMBER ITS VERB HAD. `gli uomini del soccorso alpino
    %% e speleologico che li hanno trovati' hangs the clause on the nearest
    %% phrase, the rescue, where it belongs to the men -- and written in the
    %% PHRASE's number `hanno' came out `ha'. The source's own agreement is
    %% the one thing here that knows which, so the writer takes it.
    ( Q = rel(P, N) -> Gap = gap(P, N) ; Gap = gap ),
    S = s(none, Gap, G, Comps).
%% ... and the clause of an object or a preposition's object is read with
%% `rel' where a question's asked term goes: every statement shape that
%% insists on `none' -- an imperative, a headline, a gerund clause -- stands
%% down, because none of them can follow a relative word. Measured: `al que
%% pertenece' read `pertenece' as the IMPERATIVE it is spelled like and
%% wrote Italian's second person, `a cui appartieni'.
%% ... and the relative word is the object only where the clause has none of
%% its own: `las reformas, que al igual que en la mayoría de las
%% exrepúblicas soviéticas, no han traído a Georgia la prosperidad' is the
%% reforms bringing no prosperity, and read with `que' for the object the
%% majority became the clause's subject and the prosperity its object too
%% -- nor where a copula already has what it says: `descubrieron con cierta
%% sorpresa que el telefonino ... estaba vacío' found THAT the mobile was
%% empty, and read as the surprise the mobile was empty the `que' clause was
%% the surprise's and no clause of the verb's
tr_relative_clause(Side, [w(R, _)|Ws], object, S) :-
    tr_relative_word(Side, R), Ws \== [],
    tr_read_nested(Side, Ws, rel, S0), \+ ( S0 = s(_, _, _, Cs0), memberchk(obj(_), Cs0) ),
    \+ ( S0 = s(_, _, g(L0, _, simple, _), Cs1), memberchk(adj(_), Cs1), ( tr_copula_lexeme(L0) ; tr_state_lexeme(L0) ) ), !,
    tr_unrel(S0, S).
tr_relative_clause(Side, [P, w(R, _)|Ws], pp(P), S) :-
    tr_is(Side, P, preposition), tr_relative_word(Side, R), Ws \== [],
    tr_read_nested(Side, Ws, rel, S0), !, tr_unrel(S0, S).
%% -- never after `como': `como el que sufrió' is like the one that, and no
%% relative clause has `like' for its preposition
tr_relative_clause(Side, [P, D, w(R, _)|Ws], pp(P), S) :-
    tr_is(Side, P, preposition), \+ ( P = w(PW, _), tr_solve(mean(PW, like)) ),
    tr_determiner(Side, D, _, article), tr_relative_word(Side, R), Ws \== [],
    tr_read_nested(Side, Ws, rel, S0), !, tr_unrel(S0, S).

%% ... AND WITH ITS ADJUNCTS BEFORE ITS VERB: `las ventas de sencillos, que
%% en 1999 absorbieron casi el 4% del mercado total' -- the gap and then
%% when. Only a front that opens on a preposition or an adverb is looked
%% for, and it goes after the verb, as a statement's front with no comma
%% does (tr_front_after/3).
%% ... AND A COMMA AFTER THE FRONT SETS IT OFF, as a statement's: `que al
%% igual que en la mayoría de las exrepúblicas soviéticas, no han traído'
%% -- the front stops at the comma, the verb is after it, and the front is
%% written back in front with its comma (fr/1).
tr_relative_clause(Side, [w(R, _)|Ws], subject, S) :-
    tr_relative_word(Side, R), Ws = [F1, _|_],
    ( tr_is(Side, F1, preposition) ; tr_is(Side, F1, adverb) ),
    tr_front_max(Side, Ws, no, Max),
    append(Front0, _, Max), Front0 \== [], append(Front0, Rest0, Ws), Rest0 \== [],
    ( Rest0 = [comma|Rest] -> Set = yes ; Rest = Rest0, Set = no ), Rest \== [],
    tr_gap_verb_next(Side, Rest),
    tr_complements(Side, Front0, Front), Front \== [], tr_adjuncts(Front),
    tr_read_nested(Side, Rest, subject(rel), S0),
    S0 = s(_, asked(Q), G, Comps0), !,
    ( Q = rel(P, N) -> Gap = gap(P, N) ; Gap = gap ),
    (   Set == yes
    ->  findall(fr(X), member(X, Front), Fr), append(Fr, Comps0, Comps)
    ;   tr_front_after(Comps0, Front, Comps)
    ),
    S = s(none, Gap, G, Comps).

tr_unrel(s(_, Su, G, Cs), s(none, Su, G, Cs)).

%% what follows the front when the relative word is the subject: the verb,
%% with a denial or a clitic before it -- never a subject of its own. `la
%% notizia che finalmente il fondo Veba e Fiat hanno raggiunto l'accordo' is
%% no relative clause at all, and every front of it was read and then every
%% reading of the rest as a clause with its subject gone
tr_gap_verb_next(Side, Rest) :-
    ( Side == english -> tr_negation(english, Rest, Ws, _) ; Ws = Rest ),
    tr_gap_verb_next0(Side, Ws), !.
tr_gap_verb_next0(foreign, [w(X, _)|Ws]) :- tr_negation_word(X), !, tr_gap_verb_next0(foreign, Ws).
tr_gap_verb_next0(foreign, [w(C, _)|Ws]) :- Ws \== [], tr_clitic(after, C), tr_gap_verb_next0(foreign, Ws), !.
tr_gap_verb_next0(Side, Ws) :- tr_group_at(Side, Ws, _, _), !.
%% the longest front of adjuncts the words allow: up to a comma, and up to
%% a determiner no preposition governs -- `che finalmente IL fondo' is a
%% subject, and `fondo' is also what `fondere' says of oneself, so the rest
%% after it looked like a verb and every longer front was read in turn
tr_front_max(_, [], _, []).
tr_front_max(_, [comma|_], _, []) :- !.
tr_front_max(Side, [W|_], no, []) :- tr_determiner(Side, W, _, _), !.
tr_front_max(Side, [W|Ws], P0, [W|Max]) :-
    ( P0 == yes -> P = yes ; tr_is(Side, W, preposition) -> P = yes ; P = no ),
    tr_front_max(Side, Ws, P, Max).

%% a clause read inside another puts back the group the outer one is
%% reading, which its later complements ask about -- the mirror of
%% tr_write_nested/3
tr_read_nested(Side, Ws, Asked, S) :-
    tr_global('$tr_read_group', G), tr_global('$tr_read_aspect', A),
    (   Side == foreign, Asked == none, tr_topic_cleft(Ws, S0)
    ->  nb_setval('$tr_read_group', G), nb_setval('$tr_read_aspect', A), S = S0
    ;   tr_read_statement(Side, Ws, Asked, S0)
    ->  nb_setval('$tr_read_group', G), nb_setval('$tr_read_aspect', A), S = S0
    ;   Asked == none, tr_nested_front(Side, Ws, S0)
    ->  nb_setval('$tr_read_group', G), nb_setval('$tr_read_aspect', A), S = S0
    ;   Asked == none, tr_nested_join(Side, Ws, S0)
    ->  nb_setval('$tr_read_group', G), nb_setval('$tr_read_aspect', A), S = S0
    ;   nb_setval('$tr_read_group', G), nb_setval('$tr_read_aspect', A), fail
    ).

%% A CLAUSE INSIDE A SENTENCE MAY BE TWO, JOINED BY A CONNECTOR: `decidere se
%% ci costerebbe più caro intervenire o stare a guardare MENTRE si consuma un
%% altro olocausto E l'intero popolo bosniaco viene distrutto' asks whether
%% one thing would cost more than another while two things happen. Only the
%% whole sentence was ever divided at a connector, so the question read as
%% nothing and the sentence went through every other reading first -- 110
%% million inferences to find the division at the top. Each side reads as a
%% clause, the left one whole and the right one perhaps two again, the
%% leftmost division that reads first.
%% (never a coordinator before an infinitive, which joins two infinitives:
%% `intervenire O STARE a guardare' is one choice between two acts)
%% (nor a connector after a COMMA or a CLOSING QUOTATION MARK, which divide
%% the sentence the nested clause stands in: `sostuvo que "cometer perjurio
%% no es aceptable y debe tener consecuencias", por lo que el comité se
%% propone ...' -- divided there inside the `que' clause, the committee's
%% intention was part of what Hyde said)
%% (and after a coordinator the right side shares the left's subject and is
%% no command, as a whole sentence's is (tr_read_joined/5): `debe tener
%% consecuencias' read alone was a command, `devi')
tr_nested_join(Side, Ws, join(w(W, WC), S1, S2)) :-
    append(L, [w(W, WC)|R], Ws), L = [_|_], R = [_|_],
    \+ last(L, comma), \+ last(L, w(_, qclose)), \+ tr_comma_before(L, w(W, WC)),
    tr_connector(Side, W),
    \+ ( tr_coord(Side, w(W, WC)), R = [w(V, _)|_], tr_solve(infinitive_of(V, _)) ),
    tr_read_statement(Side, L, none, S1),
    (   tr_coord(Side, w(W, WC)), S1 = s(_, _, g(_, _, A1, _), _), A1 \== imperative
    ->  tr_global('$tr_no_command', F0), nb_setval('$tr_no_command', yes),
        (   tr_read_nested(Side, R, none, S20) -> nb_setval('$tr_no_command', F0)
        ;   nb_setval('$tr_no_command', F0), fail
        ),
        tr_shared_subject(Side, S1, R, S20, S2)
    ;   tr_read_nested(Side, R, none, S2)
    ), !.

%% ... the comma looked for in the piece, because a nested clause is read with
%% its commas out: `pidiéndole que designara un fiscal ... de fondos
%% electorales, pero su petición fue rechazada' divided at `pero' inside the
%% `que' clause, and the comma the sentence divides at was lost
tr_comma_before(L, C) :-
    last(L, X), tr_global('$tr_piece', P), is_list(P), append(_, [X, comma, C|_], P), !.

%% A CLAUSE INSIDE A SENTENCE MAY HAVE A FRONT OF ITS OWN: `que antes de
%% jugar esto ya está ganado' puts `before playing' before its subject. The
%% shortest front of adjuncts that leaves a statement is taken -- a longer
%% one would take `esto' for what is played -- and it goes after the
%% clause's own complements, as a front with no comma does (1.6.8).
%% -- and it begins with a PREPOSITION OR AN ADVERB, which an adjunct does:
%% tried on every clause that failed to read, the walk over every front
%% cost Livata's `... che la famiglia era ...' 7.7 million inferences more
%% and found nothing
tr_nested_front(Side, Ws, s(A, Su, G, Comps)) :-
    Ws = [W1|_], W1 = w(_, _), ( tr_is(Side, W1, preposition) ; tr_is(Side, W1, adverb) ),
    append(Front0, Rest, Ws), Front0 = [_|_], Rest = [_|_], \+ memberchk(comma, Front0),
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    tr_complements(Side, Front0, Front), Front \== [], tr_adjuncts(Front),
    tr_read_statement(Side, Rest, none, s(A, Su, G, Comps0)), !,
    tr_front_after(Comps0, Front, Comps).

%% the word this lesson puts before an infinitive of purpose
tr_purpose_word(P) :- tr_lexeme(foreign, P, L, _), tr_solve(begin(L, purpose)), !.

%% the group being read is a modal, so a bare base form after it is its verb
tr_read_modal :- catch(nb_getval('$tr_read_group', L), _, fail), en_modal_out(L, _, _).

%% the group being read is the copula's: `sono stati eroici un'intera notte'
%% is heroic for a whole night, and the adjective before a determiner is its
%% predicate, never an object complement of a night
tr_read_copula :- catch(nb_getval('$tr_read_group', L), _, fail), atom(L), tr_copula_lexeme(L).

%% the group being read is a passive, so a `by' phrase after it is the agent
tr_read_passive :- catch(nb_getval('$tr_read_aspect', A), _, fail), memberchk(A, [passive, passive_perfect, duty]).

%% a word of the lesson's that means `to' -- what a verb puts before its
%% infinitive (`tende AD accreditare')
tr_means_to(P) :- tr_lexeme(foreign, P, L, _), tr_solve(mean(L, to)), !.
tr_means_of(P) :- tr_lexeme(foreign, P, L, _), tr_solve(mean(L, of)), !.

%% the infinitive group of infx/3: the perfect with a pronoun joined to its
%% auxiliary, the perfect, and the infinitive with a pronoun joined to it
tr_infinitive_group([w(A, _), w(Cl, enclitic), w(P, _)|Ws], F, perfect, [Cl], Ws) :-
    tr_perfect_infinitive(A, P, F, [Cl]), !.
tr_infinitive_group([w(A, _), w(P, _)|Ws], F, perfect, [], Ws) :-
    tr_perfect_infinitive(A, P, F, []), !.
tr_infinitive_group([w(V, _), w(Cl1, enclitic), w(Cl2, enclitic)|Ws], F, simple, [Cl1, Cl2], Ws) :-
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !.
tr_infinitive_group([w(V, _), w(Cl, enclitic)|Ws], F, simple, [Cl], Ws) :-
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !.

%% an auxiliary's infinitive and a participle: the auxiliary's own, or the
%% copula's where the lesson says the verb -- or, with the reflexive joined
%% to it, the reflexive -- builds its perfect with the copula
tr_perfect_infinitive(A, P, F, Cls) :-
    tr_solve(infinitive_of(A, AL)),
    tr_solve(participle_of(P, F)), tr_known(foreign, F),
    (   tr_solve(auxiliary(AL))
    ->  true
    ;   tr_copula_lexeme(AL),
        (   tr_solve(auxiliary_of(AL, F)) -> true
        ;   member(Cl, Cls), tr_reflexive_word(Cl), tr_solve(auxiliary_of(AL, reflexive))
        )
    ), !.

%% a word that means `by': English's own, or one the lesson gives for it
tr_means_by(english, w(by, _)) :- !.
tr_means_by(foreign, w(W, _)) :- tr_lexeme(foreign, W, L, _), tr_solve(mean(L, by)), !.

%% English's base form of a verb the lesson gives (`sleep' for `sleeps'),
%% never one of English's own words
en_infinitive(be, is) :- !.
en_infinitive(have, has) :- !.
en_infinitive(B, L) :- \+ en_own(B), reason_third(B, L), L \== B, tr_known(english, L), tr_class(english, L, verb).

%% ---- English's degrees --------------------------------------------------------
%% richer and richest, more careful and most careful, and the handful that
%% are neither. BOTH FORMS ARE READ whatever the rule would write, so `more
%% rich' comes back as the comparative and is written `richer' -- a round
%% trip through English normalises the spelling, which is the better
%% English of the two.

en_irregular_degree(good, better, best).
en_irregular_degree(well, better, best).
en_irregular_degree(bad, worse, worst).
en_irregular_degree(far, further, furthest).
en_irregular_degree(little, less, least).
en_irregular_degree(much, more, most).
en_irregular_degree(many, more, most).

en_degree_marker(more, comparative).
en_degree_marker(most, superlative).

en_degree_suffix(comparative, er).
en_degree_suffix(superlative, est).

%% reading a form: an irregular, or an ending taken off a word the lesson
%% knows as an adjective
en_degree_word(F, comparative, L) :- en_irregular_degree(L0, F, _), !, L = L0.
en_degree_word(F, superlative, L) :- en_irregular_degree(L0, _, F), !, L = L0.
en_degree_word(F, D, L) :-
    en_degree_suffix(D, Suf), atom_concat(Stem, Suf, F),
    en_degree_stem(Stem, L), tr_known(english, L), tr_class(english, L, adjective).

%% what an ending may have done to the word: nothing, an `e' dropped
%% (larger), a letter doubled (bigger), a `y' made `i' (happier)
en_degree_stem(Stem, Stem).
en_degree_stem(Stem, L) :- atom_concat(Stem, e, L).
en_degree_stem(Stem, L) :-
    atom_length(Stem, N), N > 2, M is N - 1,
    sub_atom(Stem, M, 1, 0, C), sub_atom(Stem, 0, M, _, L), sub_atom(L, _, 1, 0, C).
en_degree_stem(Stem, L) :- atom_concat(S1, i, Stem), atom_concat(S1, y, L).

%% writing one: the irregular, the ending where English gives one, and
%% `more'/`most' otherwise
en_degree_out(D, L, C, [o(F, C)]) :-
    en_irregular_degree(L, Cm, Sp), !, ( D == comparative -> F = Cm ; F = Sp ).
en_degree_out(D, L, C, [o(F, C)]) :-
    en_short_adjective(L), !,
    en_degree_suffix(D, Suf), en_degree_base(L, Stem), atom_concat(Stem, Suf, F).
en_degree_out(D, L, C, [o(M, lower), o(L, C)]) :- en_degree_marker(M, D), !.

%% the stem an ending is added to
en_degree_base(L, Stem) :- atom_concat(Stem, e, L), !.
en_degree_base(L, Stem) :- atom_concat(S1, y, L), !, atom_concat(S1, i, Stem).
en_degree_base(L, Stem) :- en_doubles(L), !, sub_atom(L, _, 1, 0, C), atom_concat(L, C, Stem).
en_degree_base(L, L).

%% a word of one syllable ending consonant-vowel-consonant doubles it
en_doubles(L) :-
    atom_length(L, N), N >= 3, en_syllables(L, 1),
    A is N - 3, sub_atom(L, A, 3, 0, Last3), atom_chars(Last3, [C1, V, C2]),
    \+ en_vowel(C1), en_vowel(V), \+ en_vowel(C2), \+ memberchk(C2, [w, x, y]).

en_vowel(V) :- memberchk(V, [a, e, i, o, u, y]).

%% ONE SYLLABLE, OR TWO ENDING IN `y', is what English gives an ending to.
%% The cost is stated: `narrow' and `simple' take `more' here where a
%% grammar allows narrower and simpler, and both are still READ.
en_short_adjective(L) :-
    en_syllables(L, N), ( N =< 1 -> true ; N =:= 2, atom_concat(_, y, L) ).

%% vowel groups, with a silent final `e' not counted
en_syllables(W, N) :-
    atom_chars(W, Cs0),
    ( append(Cs1, [e], Cs0), Cs1 \== [] -> Cs = Cs1 ; Cs = Cs0 ),
    en_groups(Cs, no, 0, N0), ( N0 < 1 -> N = 1 ; N = N0 ).

en_groups([], _, N, N).
en_groups([C|Cs], Prev, N0, N) :-
    (   en_vowel(C) -> ( Prev == yes -> N1 = N0 ; N1 is N0 + 1 ), P = yes
    ;   N1 = N0, P = no
    ),
    en_groups(Cs, P, N1, N).

%% bare adjectives, an `and' among them allowed: the predicate of a copula
tr_all_adjectives(Side, Words) :-
    Words \== [],
    forall(member(W, Words), tr_predicate_word(Side, W)),
    \+ forall(member(W, Words), tr_coord(Side, W)).

tr_predicate_word(_, deg(_, _)) :- !.
%% A CAPITALISED WORD INSIDE A SENTENCE IS NO ADJECTIVE on the lesson's side,
%% where the head was lowered when the lesson knows it (tr_head_lower/3):
%% `se a Milano va via Pellegrini' is the man, and `pellegrini' is also the
%% plural of `pellegrino', wandering -- read as what he was, the subject
%% nobody named went away and Pellegrini became `Peregrino'
tr_predicate_word(foreign, w(_, upper)) :- !, fail.
tr_predicate_word(Side, W) :- tr_is(Side, W, adjective), !.
tr_predicate_word(Side, W) :- tr_coord(Side, W).

%% ---- writing ------------------------------------------------------------------

%% `there is': English's `there', the copula in the number of what there is
%% (`There are dogs') and `no' for the denial with the article dropped
%% (`There is no dog'); the lesson's verb and the phrase, no subject
%% two clauses joined: the first, the connector, the second. Only the
%% first carries the sentence's KIND -- a question mark belongs to the whole
%% -- and a comma is written with no space before it (tr_join/5).
tr_write(To, _, gap(Front, Back), Outs) :- !,
    nb_setval('$tr_verb', none),                       % no verb: an object is no verb's, and takes no marker
    tr_gap_comps_out(To, Front, FO), tr_gap_comps_out(To, Back, BO),
    ( FO == [] -> Outs = BO ; append(FO, [o(',', comma)|BO], Outs) ).
%% the complements of a clause with no verb, a participle among them agreeing
%% with the form the source gave it (agr/1, agrn/1) and the gender put back
tr_gap_comps_out(To, Cs0, Out) :-
    ( select(agr(G), Cs0, Cs1) -> true ; Cs1 = Cs0, G = none ),
    ( select(agrn(N), Cs1, Cs) -> true ; Cs = Cs1, N = singular ),
    (   G == none
    ->  tr_comps_out(To, Cs, none, N, _, O1, A1)
    ;   ( catch(nb_getval('$tr_subject_gender', Old), _, fail) -> true ; Old = masculine ),
        nb_setval('$tr_subject_gender', G),
        (   tr_comps_out(To, Cs, none, N, _, O1, A1) -> nb_setval('$tr_subject_gender', Old)
        ;   nb_setval('$tr_subject_gender', Old), fail
        )
    ),
    append(O1, A1, Out).
%% -- and a clause after a SUBORDINATING word is no question of its own,
%% whatever the sentence is: `¿Y si soy pobre?' came out `And if am I poor?'
tr_write(To, Kind, join(C, none, S2), Outs) :- !,
    tr_connector_out(To, C, CO),
    ( ( C = w(T, _) ; C = wc(w(T, _)) ), atom(T), en_connector(T), \+ tr_coord(english, w(T, lower)) -> K2 = statement ; K2 = Kind ),
    tr_write(To, K2, S2, O2),
    append(CO, O2, Outs).
%% ... and a question after a colon is the SECOND clause's (tr_read0/4):
%% the first is written as the statement it is
%% -- and the lesson's opening mark opens it there: `...: ¿en qué raza de
%% mundo nacerán mis hijos?'
tr_write(To, _, join(C, S1, q(S2)), Outs) :- !,
    tr_write(To, statement, S1, O1), tr_connector_out(To, C, CO),
    tr_write(To, question, S2, O20),
    ( To == foreign, once(tr_solve(begin(M, question))) -> O2 = [o(M, lower)|O20] ; O2 = O20 ),
    append(O1, CO, Front), append(Front, O2, Outs).
tr_write(To, Kind, join(C, S1, none), Outs) :- !,
    tr_write(To, Kind, S1, O1), tr_connector_out(To, C, CO), append(O1, CO, Outs).
tr_write(To, Kind, join(C, S1, S2), Outs) :- !,
    tr_write(To, Kind, S1, O1),
    tr_connector_out(To, C, CO),
    %% ENGLISH LEAVES OUT A SUBJECT THE CLAUSE BEFORE NAMED: `Abachidze
    %% prefiere poner el acento en la corrupción e intenta aglutinar el
    %% voto' is one man doing both, and the second clause's subject nobody
    %% named refused the sentence -- `... and tries to agglutinate'
    (   To == english, C = w(CW, _), memberchk(CW, [and, or, but]),
        S1 = s(_, Su1, _, _), Su1 \= null(_, _), Su1 \== none, S2 = s(_, null(third, _), _, _)
    ->  nb_setval('$tr_elide', yes)
    ;   true
    ),
    tr_write(To, statement, S2, O20), nb_setval('$tr_elide', no),
    ( C == dashes -> append(O20, [o('–', lower)], O2) ; O2 = O20 ),       % and the dash that closes it
    append(O1, CO, Front), append(Front, O2, Outs).
tr_write(To, Kind, s(none, there, g(L, T, simple, Neg), [obj(NP)|More]), Outs) :- !,
    nb_setval('$tr_verb', L),
    tr_lexeme_across(L, To, LT),
    tr_np_out(To, NP, NPOut0, _, Number),
    tr_comps_out(To, More, none, Number, _, RestOuts, Advs), append(RestOuts, Advs, Rest),
    (   To == english
    ->  (   Neg == yes
        ->  ( NP = np(det(article, _, _), _, _, _, _) -> NPOut0 = [_|NPOut] ; NPOut = NPOut0 ), Tail0 = [o(no, lower)|NPOut]
        ;   Tail0 = NPOut0
        ),
        (   T == future -> Front = o(will, lower), Tail = [o(be, lower)|Tail0]
        ;   en_copula_form(third, Number, T, C), Front = o(C, lower), Tail = Tail0
        ),
        en_assemble(Kind, none, [], [o(there, lower)], [Front|Tail], Front, Tail, Rest, Outs)
    ;   fo_group(LT, third, Number, T, simple, Neg, [], Group),        % `ci sono' agrees; `hay' has one form
        append(NPOut0, Rest, After),
        fo_assemble(none, [], [], Group, After, Outs)
    ).
%% ... and a front that asks where or relates, in front with no comma
tr_write(To, Kind, s(Asked, Subject, G, Comps0), Outs) :-
    select(frn(_), Comps0, _), \+ memberchk(fr(_), Comps0), \+ memberchk(frc(_), Comps0), !,  % a punctuated front goes first
    findall(C, member(frn(C), Comps0), Fr), findall(C, ( member(C, Comps0), C \= frn(_) ), Comps),
    tr_fronts_out(To, Fr, FO),
    tr_write(To, Kind, s(Asked, Subject, G, Comps), O2),
    append(FO, O2, Outs).
%% AN ASIDE AFTER THE SUBJECT goes back after it, between its commas: the
%% sentence is written without it and the subject's words, which every
%% writer puts first in a statement, are found at its head
tr_write(To, Kind, s(none, Subject, G, Comps0), Outs) :-
    select(mid(_), Comps0, _), !,
    findall(C, member(mid(C), Comps0), Mid), findall(C, ( member(C, Comps0), C \= mid(_) ), Comps),
    tr_write(To, Kind, s(none, Subject, G, Comps), O2),
    (   tr_subject_out(To, Subject, SO, _, _, _), SO \== [], append(SO, After, O2),
        tr_fronts_out(To, Mid, MO)
    ->  append([SO, [o(',', comma)], MO, [o(',', comma)], After], Outs)
    ;   tr_fronts_out(To, Mid, MO), append(O2, MO, Outs)
    ).
%% the complements the source set off in front are written in front, and the
%% comma after them
tr_write(To, Kind, s(Asked, Subject, G, Comps0), Outs) :-
    ( memberchk(fr(_), Comps0) ; memberchk(frc(_), Comps0) ), !,
    findall(C, ( member(X, Comps0), ( X = fr(C) ; X = frc(C) ) ), Fr),
    findall(C, ( member(C, Comps0), C \= fr(_), C \= frc(_) ), Comps),
    %% (a front the clause's word set off with a comma before it too: `de
    %% que, como su predecesor, no les importa ...', frc/1)
    ( memberchk(frc(_), Comps0) -> Lead = [o(',', comma)] ; Lead = [] ),
    %% each in the order it stood, an adverb among them too -- and every one
    %% of them written, or the sentence is refused: a findall here dropped a
    %% phrase it could not write and wrote the rest
    %% (adjectives in front agree with the subject: `Egoístas y cobardes,
    %% continuarán ...', and in its gender where it names a noun: `Cansada y
    %% roja, la casa duerme', where they were written masculine)
    ( tr_front_number(Subject, FN) -> true ; FN = singular ),
    (   Subject \= null(_, _), tr_subject_out(To, Subject, _, _, _, FNoun) -> true ; FNoun = none ),
    tr_fronts_out(To, Fr, FNoun, FN, FO),
    tr_write(To, Kind, s(Asked, Subject, G, Comps), O2),
    append([Lead, FO, [o(',', comma)|O2]], Outs).
%% A REPORTING CLAUSE KEEPS ITS SUBJECT WHERE THE SOURCE HAD IT, after the
%% verb and among the complements -- `ha contado a Sky Tg24 Tornaboni' --
%% which is where the lesson's language puts a speaker too. English writes
%% its subject first, and the place is simply dropped there.
tr_write(english, Kind, s(Asked, Subject, G, Comps0), Outs) :-
    append(Pre, [subj_here|Post], Comps0), !,
    append(Pre, Post, Comps), tr_write(english, Kind, s(Asked, Subject, G, Comps), Outs).
tr_write(foreign, _, s(none, Subject, g(L, T, A, Neg), Comps0), Outs) :-
    append(Pre, [subj_here|Post], Comps0), !,
    ( L = reflexive(L0) -> true ; L = state(L0) -> true ; L0 = L ), nb_setval('$tr_verb', L0),
    tr_subject_out(foreign, Subject, SubjectOut, Person, Number, Noun),
    tr_subject_gender_of(Subject, Noun, SG),
    nb_setval('$tr_subject_gender', SG),
    tr_lexeme_across(L, foreign, LT),
    tr_comps_out(foreign, Pre, Noun, Number, Cl1, O1, A1),
    tr_comps_out(foreign, Post, Noun, Number, Cl2, O2, A2),
    append(Cl1, Cl2, Clitics),
    fo_group(LT, Person, Number, T, A, Neg, Clitics, Group),
    tr_concat([Group, O1, SubjectOut, O2, A1, A2], Outs).
tr_write(To, Kind, s(Asked, Subject, g(L, T, A, Neg0), Comps00), Outs) :-
    %% the quotation that opened on the verb, and the one that closed on it
    %% (tr_vq_add/4)
    ( selectchk(vq, Comps00, Comps0q) -> VQ = yes ; Comps0q = Comps00, VQ = no ),
    ( selectchk(vqc, Comps0q, Comps) -> VQC = yes ; Comps = Comps0q, VQC = no ),
    %% a denied list BEFORE its verb is the whole denial: `Né Rivaldo né
    %% Overmars figurano', `Neither Rivaldo nor Overmars appears' -- with the
    %% verb denied as well it said the opposite in both
    ( Subject = nei(_) -> Neg = no ; Neg = Neg0 ),
    %% a reflexive verb is its own object, so no phrase after it takes the
    %% word the lesson puts before a person: `si è fatta male alla spalla,
    %% il bimbo alla manina' is the boy too, never `al niño'
    ( L = reflexive(L0) -> V = refl(L0) ; L = state(L0) -> V = L0 ; L0 = L, V = L0 ), nb_setval('$tr_verb', V),
    %% ... and the other way round: an impersonal subject with a modal is
    %% written as the lesson's impersonal modal when it has one, and then
    %% the modal is the whole of the subject: `si deve' is `hay que' -- so
    %% the lesson's impersonal word is not asked for, and a lesson that has
    %% `bisogna' and no impersonal `si' writes `Bisogna mangiare pane'
    (   To == foreign, Subject == impersonal, tr_impersonal_modal(L, IM)
    ->  LT = IM, ImpDrop = yes, SubjectOut = [], Person = third, Number = singular, Noun = none
    ;   tr_subject_out(To, Subject, SubjectOut, Person, Number, Noun),
        tr_verb_out(To, L, Comps, LT), ImpDrop = no
    ),
    %% the subject's gender, for a passive participle to agree with
    tr_subject_gender_of(Subject, Noun, SG),
    nb_setval('$tr_subject_gender', SG),
    tr_asked_out(To, Asked, AskedOut),
    %% A GERUND STRAIGHT AFTER THE VERB IS THE VERB'S OWN, and a language may
    %% say it with an infinitive: `el disco compacto continúa aumentando su
    %% penetración' is `continua a aumentare' in Italian, where the gerund
    %% came out as itself, `continua accrescendo'. The lesson says which word
    %% its verb takes before an infinitive (`"continua" takes "a" before the
    %% infinitive.'), and a gerund that is the clause's only complement is
    %% written that way; one after an object is how the clause was done.
    (   To == foreign, Comps = [ger(GL, GCs)], tr_verb_takes(_)
    ->  Comps1 = [pger(GL, GCs)]
    ;   Comps1 = Comps
    ),
    tr_comps_out(To, Comps1, Noun, Number, Clitics, CompOuts, Advs),
    (   To == english
    ->  en_group(LT, Person, Number, T, A, Neg, Statement0, Front, Tail),
        tr_vq_mark(VQ, Statement0, Statement1), tr_vqc_mark(VQC, Statement1, Statement),
        append(CompOuts, Advs, Rest),
        en_assemble(Kind, Asked, AskedOut, SubjectOut, Statement, Front, Tail, Rest, Outs)
    ;   %% the impersonal word goes AFTER the object pronouns where the
        %% lesson says it follows them: Italian's `li si chiamerà'
        (   ImpDrop == yes
        ->  Clitics1 = Clitics, SubjectOut1 = []
        ;   Subject == impersonal, SubjectOut = [o(ImpW, _)], tr_holds(follow(ImpW, pronoun))
        ->  append(Clitics, [o(ImpW, lower)], Clitics1), SubjectOut1 = []
        %% ... and after the denial, as a pronoun before the verb is: `Non si
        %% sa', `No se sabe' -- written as a subject it came out `se no sabe'
        ;   Subject == impersonal, Neg == yes, SubjectOut = [o(ImpW, _)]
        ->  Clitics1 = [o(ImpW, lower)|Clitics], SubjectOut1 = []
        ;   Clitics1 = Clitics, SubjectOut1 = SubjectOut
        ),
        %% THE PROGRESSIVE OF A PASSIVE IS THE VERB THE LESSON SAYS MARKS THE
        %% PASSIVE, where it names one: `está siendo presionado' is `is being
        %% pressured', and Italian says `viene pressato' -- `sta essendo
        %% pressato' is a progressive Italian does not build. A lesson that
        %% names no such verb writes its copula's progressive, as Spanish does
        (   A == progressive, L == is, Comps = [pred(_)|_], tr_solve(mark(PV, passive))
        ->  LT1 = PV, A1 = simple
        ;   LT1 = LT, A1 = A
        ),
        fo_group(LT1, Person, Number, T, A1, Neg, Clitics1, Group0),
        tr_vq_mark(VQ, Group0, Group1), tr_vqc_mark(VQC, Group1, Group),
        append(CompOuts, Advs, Rest),
        fo_assemble(Asked, AskedOut, SubjectOut1, Group, Rest, Outs)
    ).

tr_vq_mark(yes, [o(W, C0)|Os], [o(W, C)|Os]) :- !, ( C0 == qclose -> C = qboth ; C = qopen ).
tr_vq_mark(_, Os, Os).
tr_vqc_mark(yes, Os0, Os) :- append(Front, [o(W, C0)], Os0), !,
    ( C0 == qopen -> C = qboth ; C = qclose ), append(Front, [o(W, C)], Os).
tr_vqc_mark(_, Os, Os).

%% the verb's lexeme across: the English third person for the lesson's
%% verb, the lesson's verb for the English one -- `is' is `is' either way
%% as the copula, and the lesson's word for it
%% a reflexive verb is written with its pronoun, so a word of the lesson that
%% already carries one is passed over for it: `realizes' is `se da cuenta' to
%% a lesson that states the idiom whole (`Ci si rende conto che ...', read as
%% one word), and written with the pronoun of `sin darse cuenta' it came out
%% `se se da cuenta'
tr_lexeme_across(reflexive(L0), To, reflexive(LT)) :- !,
    (   To == foreign, tr_meanings_of(L0, foreign, verb, Ms), member(LT, Ms), \+ tr_carries_reflexive(LT) -> true
    ;   tr_lexeme_across(L0, To, LT)
    ).
tr_lexeme_across(state(L0), To, LT) :- !,
    ( To == foreign, tr_state_word(W) -> LT = W ; tr_lexeme_across(L0, To, LT) ).
tr_lexeme_across(L, To, LT) :-
    tr_meanings_of(L, To, verb, Ms),
    (   To == english, atom(L), tr_intransitive_meanings(L, Is), member(LT, Ms), \+ memberchk(LT, Is) -> true
    %% an impersonal modal is written only for the impersonal subject (above)
    ;   To == foreign, member(LT, Ms), \+ tr_solve(impersonal(LT)) -> true
    ;   Ms = [LT|_]
    ).

tr_carries_reflexive(W) :-
    atom(W), atomic_list_concat(Ps, ' ', W), Ps = [_, _|_], member(P, Ps), tr_reflexive_word(P), !.

%% A VERB'S SENSE BY ITS OBJECT, WRITTEN. `Conozco al entrenador' knows a
%% person and `sé que' knows a fact, and Italian says the two with two verbs
%% -- `conosco l'allenatore', `so che' -- where English has one. The lesson
%% says which of its verbs takes a phrase for its object: `The transitive
%% verb "conosce" means "knows".' A clause with such an object takes that
%% verb; any other takes the first verb meaning it that is not it.
tr_verb_out(foreign, L, Comps, LT) :-
    atom(L), tr_solve(transitive_sense(L, W)), !,
    (   member(obj(_), Comps) -> LT = W
    ;   tr_meanings_of(L, foreign, verb, Ms), member(LT, Ms), LT \== W -> true
    ;   LT = W
    ).
tr_verb_out(To, L, _, LT) :- tr_lexeme_across(L, To, LT).

%% the lesson's impersonal modal for a modal meaning, if it gives one
tr_impersonal_modal(L, IM) :-
    atom(L), tr_meanings_of(L, foreign, modal, Ms), member(IM, Ms),
    tr_solve(impersonal(IM)), tr_class_of(IM, modal), !.

%% the subject out, with its person and number for the verb and its noun
%% for the agreement of what is said of it
tr_subject_out(To, asked(w(Q, C)), [o(QT, C)], third, singular, none) :- !, tr_question_across(To, subject, Q, QT).
tr_subject_out(To, asked(which_np(NP, C)), [o(QT, C)|NPOut], third, Number, Noun) :- !,
    tr_which_word(To, QT), tr_which_np_out(To, NP, NPOut, Noun, Number).
tr_subject_out(_, none, [], third, singular, none) :- !.
%% the people a plural imperative speaks to: no word in any language, and
%% the number for the verb (tr_imperative_number/3)
tr_subject_out(_, addressee(N), [], second, N, none) :- !.
tr_subject_out(_, name(W), [o(W, upper)], third, singular, none) :- !.
tr_subject_out(To, pronoun(P, N, w(W, C)), Outs, P, N, none) :- !,
    (   tr_pronoun_across(To, subject, w(W, C), P, N, T) -> Outs = [o(T, C)]
    ;   To == foreign, W == it -> Outs = []                                % `It rains': the verb says who
    ).
%% ... and a third person singular nobody named is refused in English:
%% he, she and it are three claims and the source made none of them
tr_subject_out(english, null(P, N), [], P, N, none) :- tr_global('$tr_elide', yes), !, nb_setval('$tr_elide', no).
tr_subject_out(english, null(third, singular), _, _, _, _) :- !, fail.
tr_subject_out(english, null(P, N), [o(T, lower)], P, N, none) :- !, en_subject(T, P, N), !.
%% a language whose verb says who needs no subject written: what the IR
%% carries is the person and the number, and the verb group takes them
tr_subject_out(foreign, null(P, N), [], P, N, none) :- !.
%% the impersonal subject out: the lesson's own word, which stands before
%% the verb as the pronoun it is; English says `one'. The word is asked for
%% with its first argument unbound, which keys 0 and walks the predicate --
%% impersonal/1 is one row a language, so the walk is one row.
tr_subject_out(english, impersonal, [o(one, lower)], third, singular, none) :- !.
tr_subject_out(foreign, impersonal, [o(W, lower)], third, singular, none) :- !,
    tr_solve(impersonal(W)), tr_class_of(W, pronoun), !.
%% two joined agree as FEMININE when both are, which is the one case where
%% the lessons' languages do not write the masculine: `la terapia palliativa
%% e la terapia del dolore' are `attivate', and written with no noun to
%% agree with they came out `activados'. The first noun stands for both.
%% ... and a list that began with its connector gets it back in front: the
%% lesson's word before the first, and English's `neither ... nor ...'
tr_subject_out(To, nei(Co0), Outs, third, plural, Noun) :- !,
    ( To == english -> tr_nor(Co0, Co) ; Co = Co0 ),
    tr_subject_out(To, Co, O1, _, _, Noun),
    (   To == english -> CO = [o(neither, lower)]
    ;   Co = co(C, _, _), tr_connector_out(To, C, CO)
    ),
    append(CO, O1, Outs).
tr_subject_out(To, one(co(C, S1, S2)), Outs, third, singular, Noun) :- !,
    tr_subject_out(To, S1, O1, _, _, Noun), tr_subject_out(To, S2, O2, _, _, _),
    tr_connector_out(To, C, CO), append(CO, O2, O3), append(O1, O3, Outs).
tr_subject_out(To, co(C, S1, S2), Outs, third, plural, Noun) :- !,
    tr_subject_out(To, S1, O1, _, _, N1), tr_subject_out(To, S2, O2, _, _, N2),
    (   To == foreign, N1 \== none, N2 \== none, tr_gender(N1, feminine), tr_gender(N2, feminine)
    ->  Noun = N1
    ;   Noun = none
    ),
    tr_connector_out(To, C, CO), append(CO, O2, O3), append(O1, O3, Outs).
tr_subject_out(To, np(D, M, As, N, Number), Outs, third, Number, Noun) :- !, tr_np_out(To, np(D, M, As, N, Number), Outs, Noun, Number).
%% a phrase with a reduced relative on it is still a phrase: the person and
%% number are its noun's, and tr_np_out/5 writes the participle and the agent
tr_subject_out(To, rel(NP, L, Cs), Outs, third, Number, Noun) :- !, tr_np_out(To, rel(NP, L, Cs), Outs, Noun, Number).
tr_subject_out(To, rc(NP, R, S), Outs, third, Number, Noun) :- !, tr_np_out(To, rc(NP, R, S), Outs, Noun, Number).
%% ... and in English, where the verb comes after it, the aside closes with
%% its comma: `The dog, who eats the bread, stands out.'
tr_subject_out(english, nrc(NP, R, S), Outs, third, Number, Noun) :- !,
    tr_np_out(english, nrc(NP, R, S), Outs0, Noun, Number), append(Outs0, [o(',', comma)], Outs).
tr_subject_out(To, nrc(NP, R, S), Outs, third, Number, Noun) :- !, tr_np_out(To, nrc(NP, R, S), Outs, Noun, Number).
tr_subject_out(To, ncl(NP, S), Outs, third, Number, Noun) :- !, tr_np_out(To, ncl(NP, S), Outs, Noun, Number).
tr_subject_out(To, all(W, NP), Outs, third, Number, Noun) :- !, tr_np_out(To, all(W, NP), Outs, Noun, Number).
%% a phrase whose noun was left out, as a subject: `lo que hace es ...' --
%% ell/4 had no clause here, and a subject the writer cannot take apart
%% fails the sentence without a word (the 1.6.4 rule, a third time)
tr_subject_out(To, ell(D, G, N0, T), Outs, third, Number, Noun) :- !, tr_np_out(To, ell(D, G, N0, T), Outs, Noun, Number).
tr_subject_out(To, app(NP, K, I), Outs, third, Number, Noun) :- !, tr_np_out(To, app(NP, K, I), Outs, Noun, Number).
%% the subject a relative word stands for is written as nothing: the verb
%% takes the person and number of the phrase the clause sits on
tr_subject_out(_, gap(P, N), [], P, N, none) :- !.
%% an infinitive and its complements: `to be president of this club',
%% `ser presidente de esta sociedad'
tr_subject_out(To, infs(L, Cs, C), [o(W1, C)|Outs], third, singular, none) :- !,
    tr_subject_out(To, infs(L, Cs), [o(W1, _)|Outs], third, singular, none).
tr_subject_out(To, infs(L, Cs), Outs, third, singular, none) :- !,
    tr_lexeme_across(L, To, LT),
    (   To == english -> en_base(LT, B), V = [o(to, lower), o(B, lower)]
    ;   once(tr_solve(infinitive_of(Inf, LT))), V = [o(Inf, lower)]
    ),
    tr_comps_out(To, Cs, none, singular, [], O2, A2), append([V, O2, A2], Outs).
tr_subject_out(To, with(NP, PPs), Outs, third, Number, Noun) :-
    (   To == foreign, PPs = [PP|_], tr_partitive_gender(NP, PP, G)
    ->  tr_with_partitive(G, tr_np_out(To, NP, O1, Noun, Number))
    ;   tr_np_out(To, NP, O1, Noun, Number)
    ),
    tr_comps_out(To, PPs, Noun, Number, _, O2, A2), append([O1, O2, A2], Outs0),
    %% ... and in English an aside on the last phrase closes with its comma,
    %% as one on the subject itself does: `The sales of minidisc, which
    %% surpassed ..., were increased'
    (   To == english, last(PPs, pp(_, nrc(_, _, _))) -> append(Outs0, [o(',', comma)], Outs) ; Outs = Outs0 ).

%% the connector out: a comma as itself, a word through the lesson
tr_connector_out(_, comma, [o(',', comma)]) :- !.
tr_connector_out(_, w(',', lcomma), [o(',', comma)]) :- !.
tr_connector_out(_, w(',', acomma), [o(',', comma)]) :- !.
tr_connector_out(_, semicolon, [o(';', comma)]) :- !.
tr_connector_out(_, colon, [o(':', comma)]) :- !.
tr_connector_out(_, endquote, [o('”', comma)]) :- !.
tr_connector_out(_, endquote_comma, [o('”', comma), o(',', comma)]) :- !.
tr_connector_out(_, endquote_plain, [o('"', comma)]) :- !.
tr_connector_out(_, endquote_plain_comma, [o('"', comma), o(',', comma)]) :- !.
tr_connector_out(_, dash, [o('–', lower)]) :- !.
tr_connector_out(_, dashes, [o('–', lower)]) :- !.
tr_connector_out(_, reported, []) :- !.
tr_connector_out(_, aside, []) :- !.
tr_connector_out(To, w(W, C), [o(T, C)]) :- tr_word_across(w(W, lower), To, conjunction, T).
%% a connecting word and the comma after it, which opens an insertion
tr_connector_out(To, wc(W), Outs) :- tr_connector_out(To, W, O), append(O, [o(',', comma)], Outs).
%% ... and the one a comment opens with, English's `as', by the lesson's
%% preposition for it (`como', `come'): its first word for `as' is `tan'
tr_connector_out(To, cmt(w(W, C)), [o(T, C)]) :-
    ( To == english -> T = W ; tr_word_across(w(W, lower), To, preposition, T) ).

%% what a question word asks for, out: the word itself, or `which' with its phrase
tr_asked_out(_, none, []) :- !.
tr_asked_out(_, subject(_), []) :- !.                                    % the subject out already carries it
tr_asked_out(To, object(which_np(NP, C)), Outs) :- !,
    tr_which_word(To, QT), tr_which_np_out(To, NP, NPOut, _, _),
    tr_marker(To, NP, M), append(M, [o(QT, C)|NPOut], Outs).
tr_asked_out(To, pp(w(P, PC), which_np(NP, C)), [o(PT, PC), o(QT, C)|NPOut]) :- !,
    ( To == english -> PT = P ; tr_word_across(w(P, lower), To, preposition, PT) ),
    tr_which_word(To, QT), tr_which_np_out(To, NP, NPOut, _, _).
tr_asked_out(To, object(w(Q, C)), Outs) :- tr_asks_person(Q), !,
    tr_question_across(To, object, Q, QT), tr_marker(To, person, M), append(M, [o(QT, C)], Outs).
tr_asked_out(To, Asked, [o(QT, C)]) :- Asked =.. [Kind, w(Q, C)], tr_question_across(To, Kind, Q, QT).

%% `whom', or a word of the lesson's that means `who' or `whom', asks for a person
tr_asks_person(Q) :- ( Q == whom ; tr_solve(mean(Q, whom)) ; tr_solve(mean(Q, who)) ), !.

%% a question word across, by what it asks for: `qué' may mean `what' and
%% `which', and the object asked is `what'
tr_question_across(To, _, Q, Q) :- tr_side_here(From), From == To, !.
tr_question_across(english, Kind, Q, E) :- tr_solve(mean(Q, E)), en_question(E, Kind), !.
tr_question_across(english, object, Q, whom) :- tr_solve(mean(Q, who)), !.       % who, asked for as the object
tr_question_across(english, subject, Q, what) :- tr_solve(mean(Q, what)), !.     % what, asked for as the subject
tr_question_across(foreign, _, E, Q) :- tr_solve(mean(Q, E)), !.
tr_question_across(foreign, object, whom, Q) :- tr_solve(mean(Q, who)), !.       % whom is who as an object

tr_which_word(english, which).
tr_which_word(foreign, W) :- once(tr_solve(mean(W, which))).
%% the word for `what', an exclamation's: English's own, and the lesson's
%% first word of one word that means it -- `che cosa' is Italian's too
tr_what_word(english, what) :- !.
tr_what_word(foreign, W) :- atom(W), !, once(tr_solve(mean(W, what))).
tr_what_word(foreign, W) :- once(( tr_solve(mean(W, what)), atom(W), \+ sub_atom(W, _, _, _, ' ') )).
tr_and_word(english, and).
tr_and_word(foreign, W) :- once(( tr_solve(mean(W, and)) )).

%% a pronoun across: English's by person and number, or by the meaning of
%% the lesson's (`ella' is `she'); the lesson's by the meaning of English's
%% -- as the subject one that may be a subject, as the object one the
%% lesson puts before the verb, after a preposition one it does not, or
%% one that serves as a subject too (`con nosotros', `con él')
tr_pronoun_across(To, _, w(W, _), _, _, W) :- tr_side_here(From), From == To, !.
tr_pronoun_across(english, subject, w(W, _), P, N, T) :- tr_solve(mean(W, E)), en_subject(E, P, N), !, T = E.
tr_pronoun_across(english, _, w(W, _), _, _, T) :- tr_tonic_across(W, T), !.
tr_pronoun_across(english, subject, w(W, _), P, N, T) :- tr_solve(mean(W, _)), en_subject(T, P, N), !.
tr_pronoun_across(english, _, w(W, _), _, _, T) :- tr_solve(mean(W, E)), en_object(E), !, T = E.
tr_pronoun_across(english, _, w(W, _), _, _, T) :- tr_solve(mean(W, E)), en_object_of(E, T), !.
tr_pronoun_across(english, _, w(W, _), _, _, T) :- tr_solve(mean(W, E)), en_reflexive(E), !, T = E.
%% AN ELIDED FORM IS THE WORD IT ELIDES, here as it is in tr_object_pronoun/3:
%% `La sinistra L'ha attaccata' split the clitic off correctly and then had no
%% meaning to cross it by, because an elision has no mean/2 row of its own.
tr_pronoun_across(To, Role, w(W, C), P, N, T) :-
    tr_solve(elision_of(W, F)), F \== W,
    tr_pronoun_across(To, Role, w(F, C), P, N, T), !.
tr_pronoun_across(foreign, Role, w(W, _), _, _, T) :-
    findall(T0, ( tr_solve(mean(T0, W)), tr_class_of(T0, pronoun) ), Ts0), Ts0 \== [],
    tr_pronouns_first(W, Ts0, Ts1),
    %% and with nothing to agree with, a feminine one last: `others' is
    %% `altro' and `altra', and the IR carries no gender for a pronoun
    (   en_tonic(W, _)
    ->  findall(X, ( member(X, Ts1), \+ tr_holds(feminine(X)) ), NotF), findall(X, ( member(X, Ts1), tr_holds(feminine(X)) ), Fem),
        append(NotF, Fem, Ts)
    ;   Ts = Ts1                                     % `her' says its gender itself
    ),
    (   Role == subject -> member(T0, Ts), tr_subject_pronoun(foreign, T0, _, _)
    ;   Role == object, member(T0, Ts), tr_holds(precede(T0, verb)) -> true
    ;   Role == oblique, member(T0, Ts), ( tr_subject_pronoun(foreign, T0, _, _) ; \+ tr_holds(precede(T0, verb)) ) -> true
    ;   Ts = [T0|_]
    ), !,
    %% a pronoun English says is plural goes out in its plural where the
    %% lesson states one: `others' is `altro' in the dictionary and `altri'
    %% in the sentence
    ( en_tonic(W, plural), tr_inflect(foreign, pronoun, T0, plural, TP) -> T = TP ; T = T0 ).
%% `these', `those': the first word for the singular that HAS a plural --
%% `esto' stands alone and has none, `este' has `estos'
tr_pronoun_across(foreign, Role, w(W, _), _, _, T) :-
    en_tonic_plural(S, W),
    findall(T0, ( tr_solve(mean(T0, S)), tr_class_of(T0, pronoun) ), Ts0), tr_pronouns_first(S, Ts0, Ts),
    member(T1, Ts), ( Role == subject -> tr_subject_pronoun(foreign, T1, _, _) ; true ),
    tr_inflect(foreign, pronoun, T1, plural, T), !.
tr_pronoun_across(foreign, Role, w(W, _), _, _, T) :- Role \== subject, tr_solve(mean(T, W)), !.

%% the words that are pronouns and nothing else first: `esto' stands alone
%% where `este' is the demonstrative too, and a vocabulary gives the
%% demonstrative's line before the pronoun's
%% -- and a word whose FIRST sentence meaning E was a pronoun's: Italian's
%% `questo' is the demonstrative and the pronoun both, and has no neuter
%% beside it, so the rule above put the dictionary's `codesto' first and
%% `esto ya está ganado' came out `codesto è vinto'; the lesson that says
%% `The pronoun "questo" means "this".' before anything else is choosing it
tr_pronouns_first(E, Ts, Out) :-
    findall(T, ( member(T, Ts),
                 ( \+ tr_class_of(T, demonstrative), \+ tr_class_of(T, determiner)
                 ; once(tr_solve(mean_as(T, E, C))), C == pronoun
                 ) ), Pure),
    findall(T, ( member(T, Ts), \+ memberchk(T, Pure) ), Rest),
    append(Pure, Rest, Out).

%% a pronoun of the lesson's that stands alone (`esto', `nadie'), in
%% English: what it means, and `these' for `this' in the plural
tr_tonic_across(W, T) :-
    tr_lexeme(foreign, W, L, N),
    %% the meaning its PRONOUN sentence gave first: `otro' is the determiner
    %% `another' and the pronoun `others', and a pronoun is the second
    (   tr_solve(mean_as(L, E, pronoun)), en_tonic(E, _) -> true
    ;   tr_solve(mean(L, E)), en_tonic(E, _)
    ), !,
    ( N == plural, en_tonic_plural(E, P) -> T = P ; T = E ).

%% English's object form of a subject pronoun, for a lesson that gave
%% `él' as `he' only
en_object_of(i, me). en_object_of(you, you). en_object_of(he, him). en_object_of(she, her).
en_object_of(it, it). en_object_of(we, us). en_object_of(they, them).
%% English's reflexive pronouns: what `sé' and `sí' mean after a preposition
en_reflexive(itself). en_reflexive(himself). en_reflexive(herself). en_reflexive(oneself).
en_reflexive(themselves). en_reflexive(myself). en_reflexive(yourself). en_reflexive(ourselves).

%% a phrase out: the determiner and each adjective agreeing with the noun
%% in gender and number, a number word as it is, the adjectives before or
%% after the noun as the rule says; Noun is the target noun's lexeme
%% the phrase, then the participle AGREEING with its noun, then the agent.
%% English agrees with nothing and takes the participle as it is; the
%% lesson's language picks the form the way a passive does, so the gender it
%% reads is the phrase's own and not the sentence's subject.
%% a phrase and its relative clause: the relative word for the role, then
%% the clause with the gap left out and, where the subject is the gap, the
%% verb in the PHRASE's number
%% the noun's own clause out: the phrase, the word the target's lesson
%% says begins such a clause if it names one, its word for `that', the clause
tr_np_out(To, ncl(NP, S), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, NPOut, Noun, Number),
    (   To == foreign, once(tr_solve(begin(B, clause))) -> BOut = [o(B, lower)] ; BOut = [] ),
    tr_that_word(To, TW),
    tr_write_nested(To, S, SOut),
    append([NPOut, BOut, [o(TW, lower)], SOut], Outs).
tr_np_out(To, rc(NP, Role, S), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, NPOut, Noun, Number),
    tr_relative_out(To, Role, Noun, Number, RelOut),
    (   S = s(A, gap, G, Cs) -> S1 = s(A, gap(third, Number), G, Cs) ; S1 = S ),
    tr_write_nested(To, S1, SOut),
    append(NPOut, RelOut, O1), append(O1, SOut, Outs).
%% ... and the one the source set off with a comma, which English writes
%% with `which', or `who' for a person, and never with `that'
tr_np_out(To, what_np(NP), [o(QW, lower)|Outs], Noun, Number) :- !,
    tr_what_word(To, QW), tr_np_out(To, NP, Outs, Noun, Number).
tr_np_out(To, nrc(NP, Role, S), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, NPOut, Noun, Number),
    (   To == english, Role \= pp(_)
    ->  ( tr_of_class(NP, person) -> RelOut = [o(who, lower)] ; RelOut = [o(which, lower)] )
    ;   tr_relative_out(To, Role, Noun, Number, RelOut)
    ),
    (   S = s(A, gap, G, Cs) -> S1 = s(A, gap(third, Number), G, Cs) ; S1 = S ),
    tr_write_nested(To, S1, SOut),
    append([NPOut, [o(',', comma)], RelOut, SOut], Outs).
%% A DATE OUT: the lesson's language puts the day, its join word and the
%% month in the phrase's own order -- `il 20 gennaio', `el 20 de enero' --
%% and English puts the month first with no article, `January 20'. The year
%% follows with the join word again, or in English after a comma when a day
%% was written: `el 20 de enero de 2014', `January 20, 2014'.
tr_np_out(To, app(NP, year, w(Y, C)), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, O1, Noun, Number),
    (   To == english -> ( NP = np(_, w(_, _), _, _, _) -> Sep = [o(',', comma)] ; Sep = [] )
    ;   tr_date_join_out(Sep)
    ),
    append([O1, Sep, [o(Y, C)]], Outs).
tr_np_out(To, np(Det, Num, [], w(NW, NC), Number), Outs, Noun, Number) :-
    Num = w(_, _), tr_month(english, w(NW, NC)), !,
    tr_noun_lexeme(To, NW, Number, _, Noun),
    tr_num_out(To, Num, NumOut),
    (   To == english
    ->  Outs = [o(Noun, upper)|NumOut]
    ;   tr_inflect(To, noun, Noun, Number, NounForm),
        tr_det_out(To, Det, Noun, Number, [o(NounForm, NC)], DetOut),
        tr_date_join_out(Sep),
        append([DetOut, NumOut, Sep, [o(NounForm, NC)]], Outs)
    ).
tr_np_out(To, app(NP, label, w(N, C)), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, O1, Noun, Number), append(O1, [o(N, C)], Outs).
tr_np_out(To, app(NP, apposed, w(N, _)), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, O1, Noun, Number), append(O1, [o(',', comma), o(N, upper), o(',', comma)], Outs).
tr_np_out(To, app(NP, Kind, Inner), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, O1, Noun, Number), tr_aside_out(To, Kind, Inner, Noun, Number, O2), append(O1, O2, Outs).
%% A YEAR TAKES THE ARTICLE WHERE THE LESSON SAYS SO: `The article "il"
%% takes the year.' Spanish's `un violín de 1736' is Italian's `un violino
%% del 1736', and English's `of 1736'. The IR carries the year bare --
%% the reader takes such an article off again (tr_cross_np/2) -- so the
%% article is the language's, written where its lesson puts it.
%% The article is the one the lesson names, because a year has no gender
%% for an article to agree with.
tr_np_out(foreign, np(none, none, [], w(Y, C), singular), [o(A, lower), o(Y, C)], none, singular) :-
    tr_year(Y), once(tr_solve(take(A, year))), !.
%% ... AND ENGLISH PUTS A BARE PARTICIPLE BEFORE ITS NOUN: `la valutazione
%% gonfiata' is the inflated valuation, and after the noun it read `the
%% evaluation inflated of a terrain'. A participle with its agent or an
%% adjunct stays after it, `the curfew imposed by the soldiers'.
%% -- with its degree too: `una adhesión más limitada' is a more limited
%% adherence
tr_np_out(english, rel(np(Det, Num, Adjs, w(NW, NC), Nb), L, Comps0), Outs, Noun, Number) :-
    \+ ( member(C, Comps0), C \= agr(_), C \= agrn(_), C \= pdeg(_) ),
    tr_lexeme_across(L, english, LT), en_participle_of(LT, PP),
    (   memberchk(pdeg(D), Comps0)
    ->  ( D == superlative -> DW = most ; DW = more ), P1 = ptcd(DW, PP)
    ;   P1 = ptc(PP)
    ),
    append(Adjs, [P1], Adjs1),
    tr_np_out(english, np(Det, Num, Adjs1, w(NW, NC), Nb), Outs, Noun, Number), !.
tr_np_out(To, rel(NP, L, Comps0), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, NPOut0, Noun, Number),
    ( select(agr(GA), Comps0, Comps01) -> true ; Comps01 = Comps0, GA = none ),
    ( select(agrn(NA), Comps01, Comps1) -> PNumber = NA ; Comps1 = Comps01, PNumber = Number ),
    %% an aside after a comma: the commas the source had, before the
    %% participle and after its adjuncts
    (   select(aside(Cl), Comps1, Comps2)
    ->  append(NPOut0, [o(',', comma)], NPOut), ( Cl == yes -> Close = [o(',', comma)] ; Close = [] )
    ;   Comps2 = Comps1, NPOut = NPOut0, Close = []
    ),
    ( select(pcase(PC), Comps2, Comps3) -> true ; Comps3 = Comps2, PC = lower ),
    %% the degree the participle carries: the lesson's word for `more', or
    %% English's `most' and `more' (the most awaited)
    (   select(pdeg(D), Comps3, Comps4)
    ->  ( To == english -> ( D == superlative -> DW = most ; DW = more ) ; tr_degree_out(DW) ), Deg = [o(DW, lower)]
    ;   Comps4 = Comps3, Deg = []
    ),
    %% ... and the adverb that stood before the participle, before it again
    (   select(padv(w(A, AC)), Comps4, Comps)
    ->  tr_word_across(w(A, lower), To, adverb, AT), Adv = [o(AT, AC)]
    ;   Comps = Comps4, Adv = []
    ),
    (   To == english
    ->  tr_lexeme_across(L, english, LT), en_participle_of(LT, PP)
    ;   tr_lexeme_across(L, foreign, LT),
        ( GA \== none -> G = GA ; tr_gender(Noun, G0), G0 \== none -> G = G0 ; G = masculine ),
        tr_with_gender(G, tr_participle_agreeing(LT, PNumber, PP))
    ),
    tr_comps_out(To, Comps, Noun, Number, _, CompOuts, _),
    append([NPOut, Adv, Deg, [o(PP, PC)|CompOuts], Close], Outs).
tr_np_out(To, adv(w(A, C)), [o(AT, C)], none, singular) :- !, tr_word_across(w(A, lower), To, adverb, AT).
%% an adverb on a phrase goes in front of it in every language: `solo uno',
%% `only one'
tr_np_out(To, advp(w(A, C), NP), [o(AT, C)|Outs], Noun, Number) :- !,
    tr_word_across(w(A, lower), To, adverb, AT), tr_np_out(To, NP, Outs, Noun, Number).
tr_np_out(_, name(W), [o(W, upper)], none, singular) :- !.
%% `all' before the phrase, agreeing with its noun in the lesson's language
tr_np_out(english, all(w(_, C), NP), [o(all, C)|O], Noun, Number) :- !, tr_np_out(english, NP, O, Noun, Number).
tr_np_out(foreign, all(w(_, C), NP), [o(AW, C)|O], Noun, Number) :- !,
    tr_np_out(foreign, NP, O, Noun, Number),
    findall(A, ( tr_solve(mean(A, all)), tr_class_of(A, pronoun) ), As), As \== [],
    tr_agree(foreign, As, Noun, A1), tr_inflect(foreign, pronoun, A1, Number, AW).
%% a phrase whose noun was left out: the article and the adjectives, agreeing
%% with the gender the source's article lent it; English adds `one' unless
%% the adjective is a superlative, which stands alone (`the weakest')
%% -- and its count after the article, as it stood: `los dos primeros'
tr_np_out(To, np(Det, Num, Adjs, elided(G0), Number), Outs, elided(G), Number) :- !,
    ( G0 \== none -> G = G0 ; G = masculine ),
    tr_adjectives_out(To, Adjs, elided(G), Number, AdjOuts), tr_adj_words(AdjOuts, AOs),
    tr_num_out(To, Num, NumOut), append(NumOut, AOs, After),
    tr_det_out(To, Det, elided(G), Number, After, DetOut),
    (   To == english, \+ memberchk(deg(superlative, _), Adjs)
    ->  ( Number == plural -> One = [o(ones, lower)] ; One = [o(one, lower)] )
    ;   One = []
    ),
    append(DetOut, After, O1), append(O1, One, Outs).
%% ... and one with a `de' phrase: English's `those' or `the one'; the
%% lesson's article where it says the article REPLACES the noun (`The word
%% "el" replaces the noun.', Spanish's `los de'), and otherwise its pronoun
%% for `that' in the gender and the number (Italian's `quelli di')
%% -- and after the INDEFINITE article it is `one of': `una de sus mejores
%% noches' is one of her best nights, and it came out `quella delle sue
%% notti', that one; the lesson's pronoun for `one' that stands alone
%% (`uno'), or the article where the gender has no such pronoun (`una')
tr_np_out(english, ell(det(article, a, _), _, Number, PP), Outs, none, Number) :- !,
    tr_ell_tail(english, PP, none, Number, PPOut), append([o(one, lower)], PPOut, Outs).
tr_np_out(foreign, ell(Det, G0, Number, PP), Outs, elided(G), Number) :-
    Det = det(article, a, _), !,
    ( G0 \== none -> G = G0 ; G = masculine ),
    findall(P, ( tr_solve(mean(P, one)), tr_class_of(P, pronoun), tr_solve(neg(precede(P, verb))) ), Ps),
    (   Ps \== [], tr_agree(foreign, Ps, elided(G), P1), tr_gender(P1, PG), ( PG == G ; PG == none, G == masculine )
    ->  Head = [o(P1, lower)]
    ;   tr_det_out(foreign, Det, elided(G), Number, [], Head)
    ),
    tr_ell_tail(foreign, PP, elided(G), Number, PPOut), append(Head, PPOut, Outs).
tr_np_out(english, ell(_, _, Number, PP), Outs, none, Number) :- !,
    ( Number == plural -> Head = [o(those, lower)] ; Head = [o(the, lower), o(one, lower)] ),
    tr_ell_tail(english, PP, none, Number, PPOut), append(Head, PPOut, Outs).
tr_np_out(foreign, ell(Det, G0, Number, PP), Outs, elided(G), Number) :- !,
    ( G0 \== none -> G = G0 ; G = masculine ),
    (   Det = det(_, DL, _), tr_meanings_of(DL, foreign, article, Ms), member(A, Ms), tr_solve(replace(A, noun))
    ->  tr_det_out(foreign, Det, elided(G), Number, [], Head)
    ;   findall(P, ( tr_solve(mean(P, that)), tr_class_of(P, pronoun) ), Ps), Ps \== [],
        tr_agree(foreign, Ps, elided(G), P1), tr_inflect(foreign, pronoun, P1, Number, PF), Head = [o(PF, lower)]
    ),
    tr_ell_tail(foreign, PP, elided(G), Number, PPOut), append(Head, PPOut, Outs).

%% what follows the head of a phrase whose noun was left out: its `de'
%% phrase, or the relative word and its clause -- or nothing, where a
%% participle after it is the reduced relative's (`quello guidato da')
tr_ell_tail(_, none, _, _, []) :- !.
tr_ell_tail(To, rel(Role, S0), Noun, Number, Outs) :- !,
    tr_relative_out(To, Role, Noun, Number, RelOut),
    ( S0 = s(A, gap, G, Cs) -> S = s(A, gap(third, Number), G, Cs) ; S = S0 ),
    tr_write_nested(To, S, SOut), append(RelOut, SOut, Outs).
tr_ell_tail(To, PP, _, Number, Outs) :- tr_comp_out(To, PP, none, Number, _, Outs, _).
%% a pronoun's number is the one English gives it -- `those' is plural, and a
%% relative clause on it must say `che sono', never `che e'
tr_np_out(To, pronoun(w(W, C)), [o(T, C)], none, N) :- !,
    tr_pronoun_across(To, oblique, w(W, C), _, _, T),
    ( tr_side_here(english), en_tonic(W, N0) -> N = N0 ; N = singular ).
tr_np_out(To, co(C, N1, N2), Outs, none, plural) :- !,
    tr_np_out(To, N1, O1, _, _), tr_np_out(To, N2, O2, _, _),
    tr_connector_out(To, C, CO), append(CO, O2, O3), append(O1, O3, Outs).
%% a name goes out as the words it is, with the determiner agreeing against
%% the gender the phrase carries rather than against a noun there is none of
tr_np_out(To, np(Det, none, [], named(G0, Ws), Number), Outs, named(G, Ws), Number) :- !,
    findall(o(W, upper), member(w(W, upper), Ws), Content),
    tr_det_out(To, Det, named(G0, Ws), Number, Content, DetOut),
    %% AND WHERE THE IR CARRIES NO GENDER THE WRITTEN ARTICLE SUPPLIES ONE,
    %% which is the reading rule seen from the other side. An English source
    %% gives `none', the article is then chosen by the lesson's own order,
    %% and everything after it -- a participle agreeing, an adjective --
    %% must agree with the word actually written or the sentence disagrees
    %% with itself: measured, `La Tate Gallery e stato evacuato'.
    ( G0 \== none -> G = G0 ; tr_written_gender(To, DetOut, G) ),
    append(DetOut, Content, Outs).
%% ... and with its adjectives, placed as a noun's are and agreeing with the
%% gender the name carries
tr_np_out(To, np(Det, none, Adjs, named(G0, Ws), Number), Outs, named(G, Ws), Number) :- !,
    findall(o(W, upper), member(w(W, upper), Ws), Name),
    tr_adjectives_out(To, Adjs, named(G0, Ws), Number, AdjOuts),
    tr_order(To, '$name', AdjOuts, Content0),
    append(Before, ['$name'|After], Content0), append([Before, Name, After], Content),
    tr_det_out(To, Det, named(G0, Ws), Number, Content, DetOut),
    ( G0 \== none -> G = G0 ; tr_written_gender(To, DetOut, G) ),
    append(DetOut, Content, Outs).
%% A NOUN WITH A NAME APPOSED TO IT TAKES ITS SHORT FORM where the lesson
%% states one: `al señor Westendorp' is `al signor Westendorp'. `"signor" is
%% the apocope of "signore".' was asked only of a title with no article (below),
%% and a phrase with its article came out `al signore Westendorp'.
tr_name_apocope(foreign, Adjs, singular, Noun, _, A) :-
    member(w(W, upper), Adjs), tr_name_out([o(W, upper)]),
    tr_solve(apocope_of(A, Noun)), !.
tr_name_apocope(_, _, _, _, F, F).
%% English capitalises a title before a name: `Monsignor Salvatore Cassisa'
tr_np_out(english, np(none, none, [w(A, upper)], w(NW, _), singular), [o(Noun, upper), o(A, upper)], Noun, singular) :-
    tr_noun_lexeme(english, NW, singular, _, Noun), tr_title_word(english, Noun), !.
%% ... and the lesson's language writes the title's short form where it
%% states one: `monsignor Salvatore Cassisa', `"monsignor" is the apocope of
%% "monsignore".', as an adjective's is written before its noun
tr_np_out(foreign, np(none, none, [w(A, upper)], w(NW, NC), singular), [o(T, NC), o(A, upper)], Noun, singular) :-
    tr_noun_lexeme(foreign, NW, singular, _, Noun), tr_title_word(foreign, Noun), !,
    ( tr_solve(apocope_of(T0, Noun)) -> T = T0 ; T = Noun ).
tr_np_out(To, np(Det, Num, Adjs, w(NW, NC), Number), Outs, Noun, Number) :-
    tr_noun_lexeme(To, NW, Number, L, Noun),
    tr_inflect(To, noun, Noun, Number, NounForm0),
    tr_name_apocope(To, Adjs, Number, Noun, NounForm0, NounForm),
    tr_adjectives_out(To, Adjs, Noun, Number, AdjOuts),
    tr_order(To, o(NounForm, NC), AdjOuts, Content0),
    tr_edge_marks(Content0, Content),
    tr_num_out(To, Num, NumOut),
    %% the determiner's form is chosen by the word written after it, which is
    %% the count when there is one: `los dos últimos años' is `i due ultimi
    %% anni', and chosen by the noun it came out `gli due ultimi anni'
    append(NumOut, Content, After),
    tr_det_out(To, Det, Noun, Number, After, DetOut),
    append(DetOut, After, Outs).

tr_date_join_out(Sep) :- ( tr_solve(join(J, date)) -> Sep = [o(J, lower)] ; Sep = [] ).

%% A QUOTATION THAT OPENS OR CLOSES ON A PHRASE OPENS OR CLOSES ON ITS EDGE,
%% whatever order the language puts its words in: `sus objetivos
%% electorales"' closed on the adjective, English puts the adjective first,
%% and the mark came out `his electoral" aims'. A mark on one word alone
%% (qboth) stays where it is.
tr_edge_marks(Cs0, Cs) :-
    Cs0 = [_, _|_], \+ memberchk(o(_, qboth), Cs0),
    ( memberchk(o(_, qopen), Cs0) -> Open = yes ; Open = no ),
    ( memberchk(o(_, qclose), Cs0) -> Close = yes ; Close = no ),
    ( Open == yes ; Close == yes ), !,
    findall(o(W, C), ( member(o(W, C0), Cs0), ( memberchk(C0, [qopen, qclose]) -> C = lower ; C = C0 ) ), [o(F, FC0)|Rest0]),
    ( Open == yes -> FC = qopen ; FC = FC0 ),
    append(Mid, [o(L, LC0)], Rest0),
    ( Close == yes -> LC = qclose ; LC = LC0 ),
    append([o(F, FC)|Mid], [o(L, LC)], Cs).
tr_edge_marks(Cs, Cs).

%% a phrase's count out: a number, an adverb and a number, two joined
tr_num_out(_, none, []) :- !.
tr_num_out(To, w(MW, MC), [o(MT, MC)]) :- !, tr_word_across(w(MW, MC), To, number, MT).
tr_num_out(To, adv_num(w(A, C), M), [o(AT, C)|MO]) :- !, tr_word_across(w(A, lower), To, adverb, AT), tr_num_out(To, M, MO).
tr_num_out(To, nums(M1, C, M2), Outs) :-
    tr_num_out(To, M1, O1), tr_connector_out(To, C, CO), tr_num_out(To, M2, O2), append([O1, CO, O2], Outs).

tr_lexeme_here(W, L) :- tr_side_here(Side), tr_lexeme(Side, W, L, _), !.

%% the phrase's noun as a lexeme, and its noun on the other side: the
%% reading of the word that is a noun in the phrase's number, with a
%% meaning the lesson calls a noun -- `houses' is a verb's form too (to
%% house, `aloja'), and a word known as one is known as itself first
tr_noun_lexeme(To, NW, Number, L, Noun) :-
    tr_side_here(Side),
    (   tr_lexeme(Side, NW, L0, Number), tr_meanings_of(L0, To, noun, [N0|_]), ( To == foreign -> tr_class_of(N0, noun) ; true )
    ->  L = L0, Noun = N0
    ;   tr_lexeme_here(NW, L), tr_meanings_of(L, To, noun, Ms),
        %% a partitive's head takes the gender tr_with_partitive/2 set
        (   tr_global('$tr_partitive', G), G \== none, member(Noun, Ms), tr_gender(Noun, G) -> true
        ;   Ms = [Noun|_]
        )
    ).

%% A PARTITIVE'S HEAD AGREES WITH THE NOUN OF ITS `of' PHRASE: `algunas de
%% las diferencias' is `alcune delle differenze', where the head has no noun
%% of its own to agree with and the lesson's first word for `some' was the
%% masculine -- `alcuni delle differenze'. The head is a phrase with nothing
%% but its word; the gender is the one the target gives the other noun.
tr_partitive_gender(np(none, none, [], w(_, _), _), pp(w(of, _), NP2), G) :-
    tr_np_head(NP2, np(_, _, _, w(NW2, _), N2)),
    tr_noun_lexeme(foreign, NW2, N2, _, Noun2), tr_gender(Noun2, G), G \== none, !.

%% the phrase at the head of what hangs on it: `las diferencias que
%% distinguen ...' is a relative clause on the differences
tr_np_head(np(D, M, A, N, Nb), np(D, M, A, N, Nb)) :- !.
tr_np_head(rc(NP, _, _), H) :- !, tr_np_head(NP, H).
tr_np_head(nrc(NP, _, _), H) :- !, tr_np_head(NP, H).
tr_np_head(what_np(NP), H) :- !, tr_np_head(NP, H).
tr_np_head(rel(NP, _, _), H) :- !, tr_np_head(NP, H).
tr_np_head(app(NP, _, _), H) :- !, tr_np_head(NP, H).
tr_np_head(ncl(NP, _), H) :- tr_np_head(NP, H).

tr_with_partitive(G, Goal) :-
    tr_global('$tr_partitive', G0), nb_setval('$tr_partitive', G),
    (   call(Goal) -> nb_setval('$tr_partitive', G0)
    ;   nb_setval('$tr_partitive', G0), fail
    ).
tr_side_here(Side) :- ( catch(nb_getval('$tr_from', S0), _, fail) -> Side = S0 ; Side = english ).

%% each adjective as a(Lexeme, Out); an `and' among them as the conjunction
tr_adjectives_out(_, [], _, _, []).
tr_adjectives_out(To, [A|As], Noun, Number, [O|Os]) :-
    (   tr_side_here(Side), tr_coord(Side, A)
    ->  tr_connector_out(To, A, [O0]), O = c(O0)
    ;   tr_adjective_out(To, A, Noun, Number, O)
    ),
    tr_adjectives_out(To, As, Noun, Number, Os).

%% A NAME APPOSED TO A NOUN IS WRITTEN AS ITSELF, in every language, and it
%% agrees with nothing: `il presidente Scalfaro', `el presidente Scalfaro',
%% `the president Scalfaro'. It is the one word no lesson can know.
tr_adjective_out(_, w(W, upper), _, _, a(W, [o(W, upper)])) :-
    tr_side_here(Side), \+ tr_known_word(Side, W), !.
tr_adjective_out(_, w(W, appos), _, _, a(W, [o(',', comma), o(W, upper), o(',', comma)])) :- !.
tr_adjective_out(english, ptc(PP), _, _, a(PP, [o(PP, lower)])) :- !.     % a bare participle, English's own word
tr_adjective_out(english, ptcd(DW, PP), _, _, a(PP, [o(DW, lower), o(PP, lower)])) :- !.   % ... and with its degree
%% an adjective marked to stand before its noun: `pre' is no adjective the
%% lesson has a rule for, so tr_sides/3 puts it before the noun
tr_adjective_out(To, pre(A), Noun, Number, a(pre, Os)) :- !,
    tr_adjective_out(To, A, Noun, Number, a(_, Os0)), tr_apocope(To, Number, Os0, Os).

%% AN ADJECTIVE BEFORE A SINGULAR NOUN MAY LOSE ITS ENDING: `dal primo
%% momento' is `desde el PRIMER momento' and `ogni grande organizzazione'
%% `cada GRAN organización' -- written `el primero momento', `cada grande
%% organización', which no Spanish page prints. The lesson states the short
%% form (`"primer" is the apocope of "primero".'), and only of the form that
%% loses it: `primera' states none, so a feminine noun keeps the whole word.
tr_apocope(foreign, singular, [o(T, C)], [o(A, C)]) :- tr_solve(apocope_of(A, T)), !.
tr_apocope(_, _, Os, Os).
%% an adjective with its intensifier: the adverb first in every language,
%% the adjective agreeing as it would alone -- `così pacifica', `so peaceful'
tr_adjective_out(To, int(w(A, AC), J), Noun, Number, a(L, [o(AT, AC)|JO])) :- !,
    tr_word_across(w(A, lower), To, adverb, AT), tr_adjective_out(To, J, Noun, Number, a(L, JO)).
tr_adjective_out(To, w(W, C), Noun, Number, a(L, [o(T, C)])) :-
    tr_adjective_form(To, W, Noun, Number, L, T).
%% a degree: English's own ending, or the word the lesson puts in front
%% -- and where the lesson has a word that is the comparative by itself,
%% that word: `il migliore degli interpreti', never `il più buono'
tr_adjective_out(To, deg(D, w(W, C)), Noun, Number, a(L, Outs)) :-
    tr_adjective_form(To, W, Noun, Number, L, T),
    (   To == english -> en_degree_out(D, T, C, Outs)
    ;   tr_synthetic_comparative(W, CW) -> tr_inflect(To, adjective, CW, Number, CT), Outs = [o(CT, C)]
    ;   tr_degree_out(M), Outs = [o(M, lower), o(T, C)]
    ).

%% the lesson's comparative of an adjective that means W, whichever of its
%% forms the phrase chose: `buona' agrees with `la', and `migliore' is stated
%% of `buono'
tr_synthetic_comparative(W, CW) :- tr_solve(comparative_of(CW, B)), tr_solve(mean(B, W)), !.

tr_adjective_form(To, W, Noun, Number, L, T) :-
    tr_lexeme_here(W, WL),
    tr_meanings_of(WL, To, adjective, Ms),
    tr_agree_adjective(To, Ms, Noun, L),
    tr_inflect(To, adjective, L, Number, T).

%% AN ADJECTIVE THAT AGREES IS TAKEN IN THE LESSON'S ORDER, one of no gender
%% among them -- the rule the determiners follow (tr_det_form/6). A word's
%% gender is what the lesson says of the WORD, whatever its class, and
%% `corrente' is a feminine NOUN: asked for a feminine adjective meaning
%% common first, `la seguridad común' came out `la sicurezza corrente', where
%% the lesson's first word, `comune', has no gender and agrees with anything.
tr_agree_adjective(english, [M|_], _, M) :- !.
tr_agree_adjective(foreign, Ms, Noun, T) :-
    tr_gender(Noun, G), G \== none,
    member(T, Ms), tr_gender(T, G1), ( G1 == G ; G1 == none ), !.
%% ... AND ONE SAID OF A SUBJECT WITH NO NOUN AGREES WITH THE SUBJECT'S
%% GENDER, as a participle does (tr_participle_agreeing/3): `Ella es alta',
%% and `el telefonino ... estaba vacío, era de pega', the second clause's
%% subject nobody, where the first meaning the lesson gave was taken and it
%% came out `era finta'
tr_agree_adjective(foreign, Ms, none, T) :-
    tr_subject_gender(G), member(T, Ms), tr_gender(T, G1), ( G1 == G ; G1 == none ), !.
tr_agree_adjective(foreign, Ms, Noun, T) :- tr_agree(foreign, Ms, Noun, T).

%% English puts an adjective before its noun; the lesson's language does what
%% its rule says of each adjective, follow(A, noun), and English's order otherwise
tr_order(english, Noun, Adjs0, Outs) :-
    tr_names_last(Adjs0, Adjs, Names),
    tr_adj_words(Adjs, Os), tr_adj_words(Names, Ns), append(Os, [Noun|Ns], Outs).
tr_order(foreign, Noun, Adjs, Outs) :-
    tr_sides(Adjs, Before, After),
    append(Before, [Noun|After], Outs).

%% A NAME APPOSED TO A NOUN FOLLOWS IT IN EVERY LANGUAGE -- `il presidente
%% Scalfaro', `the president Scalfaro' -- and the adjective rules do not
%% place it: measured, `del Scalfaro presidente' and `Il Chevènement
%% ministro' before this. In English it goes after the noun; in the
%% lesson's language it keeps its place among the adjectives that follow the
%% noun (tr_sides/3), because the source put it there: `il magnate televisivo
%% Silvio Berlusconi' has the adjective first and `il governo Dini
%% successivo' the name, and written with the names last the second came out
%% `el gobierno sucesivo Dini'
tr_names_last([], [], []).
tr_names_last([a(W, Os)|As], Adjs, [a(W, Os)|Ns]) :- tr_name_out(Os), !, tr_names_last(As, Adjs, Ns).
tr_names_last([A|As], [A|Adjs], Ns) :- tr_names_last(As, Adjs, Ns).
tr_name_out([o(',', comma)|_]) :- !.
tr_name_out([o(W, upper)]) :- tr_side_here(Side), \+ tr_known_word(Side, W).

tr_adj_words([], []).
tr_adj_words([a(_, Os0)|As], Os) :- tr_adj_words(As, Os1), append(Os0, Os1, Os).
tr_adj_words([c(O)|As], [O|Os]) :- tr_adj_words(As, Os).

tr_sides([], [], []).
tr_sides([c(O)|As], Before, After) :- !,
    tr_sides(As, Before1, After1),
    ( After1 == [] -> Before = [O|Before1], After = After1 ; Before = Before1, After = [O|After1] ).
tr_sides([a(L, Os)|As], Before, After) :-
    tr_sides(As, Before1, After1),
    (   ( tr_name_out(Os) ; tr_holds(follow(L, noun)) ) -> Before = Before1, append(Os, After1, After)
    ;   append(Os, Before1, Before), After = After1
    ).

%% the determiner out: English's `the' either way, `a' in the singular --
%% `an' before a vowel -- and nothing in the plural, a possessive as it is;
%% the lesson's by the gender and the number of the noun
tr_det_out(_, none, _, _, _, []) :- !.
tr_det_out(english, det(Kind, DL, w(_, C)), _, Number, Content, Outs) :- !,
    tr_word_across(w(DL, lower), english, Kind, T),
    (   Kind == possessive -> Outs = [o(T, C)]
    ;   memberchk(Kind, [demonstrative, determiner]) -> en_det_number(T, Number, T1), Outs = [o(T1, C)]
    ;   T == the -> Outs = [o(the, C)]
    ;   Number == plural -> Outs = []
    ;   Content = [o(First, _)|_], begin_with(First, vowel) -> Outs = [o(an, C)]
    ;   Outs = [o(a, C)]
    ).
%% A POSSESSIVE TAKES THE ARTICLE IN FRONT OF IT where the lesson says so
%% (`The article "il" takes the possessive.'): Italian's `i suoi figli', and
%% `de sus hijos' is `dei suoi figli' once the contraction is made
tr_det_out(foreign, det(possessive, DL, W), Noun, Number, Content, Outs) :-
    once(( tr_solve(take(A, possessive)), tr_class_of(A, article) )), !,
    tr_det_form(possessive, DL, Noun, Number, Content, PT), W = w(_, C),
    tr_det_out(foreign, det(article, the, w(the, lower)), Noun, Number, [o(PT, C)|Content], AOut),
    append(AOut, [o(PT, lower)], Outs).
tr_det_out(foreign, det(Kind, DL, w(_, C)), Noun, Number, Content, [o(T, C)]) :-
    tr_det_form(Kind, DL, Noun, Number, Content, T).

%% THE FORM OF A DETERMINER IS CHOSEN BY THE WORD AFTER IT where the lesson
%% says so: `The article "lo" comes before "sc".', `... before a vowel.' --
%% so `lo scandalo', `uno scandalo', and before a vowel `lo', which the
%% elision makes `l'' and the contractions `dell'' and `degli'. Among the
%% determiners of the noun's gender, one whose come_before/2 matches the
%% next word; failing that the first with no such rule, which is the
%% ordinary `il'; failing that the first.
%% THE DETERMINERS THAT AGREE ARE TAKEN IN THE LESSON'S ORDER, one of no
%% gender among them: `cualquier signo' is `qualsiasi segno', and with the
%% noun's gender asked first the dictionary's masculine `molto', an adverb
%% it also lists as a determiner meaning any, came before the lesson's word
%% and wrote `molto segno'.
tr_det_form(Kind, DL, Noun, Number, Content, T) :-
    tr_meanings_of(DL, foreign, Kind, Ms),
    tr_gender(Noun, G),
    findall(M, ( member(M, Ms), ( G == none ; tr_gender(M, G) ; tr_gender(M, none) ) ), Cands0),
    ( Cands0 == [] -> Cands = Ms ; Cands = Cands0 ),
    (   Content = [o(Next, _)|_], atom(Next), member(L0, Cands), tr_solve(come_before(L0, P)), begin_with(Next, P) -> L = L0
    ;   member(L0, Cands), \+ tr_solve(come_before(L0, _)) -> L = L0
    ;   Cands = [L|_]
    ), !,
    tr_inflect(foreign, Kind, L, Number, T).

%% the complements out: objects and predicates in place, the adverbs last,
%% and an object pronoun the lesson puts before the verb kept aside for it
tr_comps_out(_, [], _, _, [], [], []).
%% ... but in English an adverb before a QUANTITY is the quantity's: `muy
%% pocos elementos' is very few elements, and put last it was `few elements
%% very'
tr_comps_out(english, [adv(w(A, C)), obj(NP)|Cs], Noun, Number, Clitics, [o(AT, C)|Outs], Advs) :-
    NP = np(det(determiner, L, _), _, _, _, _), memberchk(L, [little, much]), !,
    tr_word_across(w(A, lower), english, adverb, AT),
    tr_comps_out(english, [obj(NP)|Cs], Noun, Number, Clitics, Outs, Advs).
%% ... and an adverb before a comparison is the comparison's: `han tardado
%% más que nosotros' took more than us, and put last it was `have taken than
%% us ... more'
tr_comps_out(english, [adv(w(A, C)), cmp(K, X)|Cs], Noun, Number, Clitics, [o(AT, C)|Outs], Advs) :- !,
    tr_word_across(w(A, lower), english, adverb, AT),
    tr_comps_out(english, [cmp(K, X)|Cs], Noun, Number, Clitics, Outs, Advs).
%% ... and English, which writes its adverbs after the complements, writes
%% them before a clause the verb takes, where the reader put them
%% (tr_advs_join/3): `he said then that ...', never `that ... then'
tr_comps_out(english, Cs, Noun, Number, Clitics, Outs, Advs) :-
    append(Pre, [C|Post], Cs), Pre \== [], tr_clause_comp(C), memberchk(adv(_), Pre), !,
    tr_comps_out(english, Pre, Noun, Number, Cl1, O1, A1),
    tr_comps_out(english, [C|Post], Noun, Number, Cl2, O2, Advs),
    append(Cl1, Cl2, Clitics), append([O1, A1, O2], Outs).
%% A PARTICIPLE AFTER AN OBJECT PRONOUN IS SAID OF THE OBJECT: `lo que los
%% hace tan deseados' makes THEM so desired, and agreeing with the subject it
%% came out `li fa così desiderato'. The pronoun says the number and, where
%% it has one, the gender: English's `them' is plural and `her' feminine.
tr_comps_out(foreign, Cs0, Noun, Number, Clitics, Outs, Advs) :-
    Cs0 = [opron(w(P, _))|_], tr_object_agreement(P, G, N),
    append(Pre, [pred(L)|Post], Cs0), !,
    append(Pre, [opred(L, G, N)|Post], Cs),
    tr_comps_out(foreign, Cs, Noun, Number, Clitics, Outs, Advs).
%% AN INFINITIVE JOINED TO ANOTHER IS THE SAME VERB'S: `quiere continuar con
%% las reformas y anclar a su país' -- both are what he wants, and with the
%% first infinitive the verb being written, the second took the word
%% `continuare' takes, `e a ancorare'
tr_comps_out(foreign, [cnj(K)|Cs], Noun, Number, Clitics, Outs, Advs) :-
    Cs = [inf(_)|_], tr_global('$tr_inf_governor', gov(V, V0)), tr_global('$tr_verb', V1), V1 == V, !,
    nb_setval('$tr_verb', V0),
    tr_comp_out(foreign, cnj(K), Noun, Number, Clitic, Out, Adv),
    tr_comps_out(foreign, Cs, Noun, Number, Clitics1, Outs1, Advs1),
    append(Clitic, Clitics1, Clitics), append(Out, Outs1, Outs), append(Adv, Advs1, Advs).
tr_comps_out(To, [C|Cs], Noun, Number, Clitics, Outs, Advs) :-
    (   To == foreign, C = obj(NP), Cs = [PP|_], tr_partitive_gender(NP, PP, G)
    ->  tr_with_partitive(G, tr_comp_out(To, C, Noun, Number, Clitic, Out, Adv))
    ;   tr_comp_out(To, C, Noun, Number, Clitic, Out, Adv)
    ),
    tr_comps_out(To, Cs, Noun, Number, Clitics1, Outs1, Advs1),
    append(Clitic, Clitics1, Clitics), append(Out, Outs1, Outs), append(Adv, Advs1, Advs).

%% the gender and the number an object pronoun gives a participle said of it
tr_object_agreement(them, masculine, plural).
tr_object_agreement(her, feminine, singular).
tr_object_agreement(him, masculine, singular).
tr_object_agreement(it, masculine, singular).

tr_comp_out(_, sep, _, _, [], [o(',', comma)], []) :- !.
tr_comp_out(_, vq, _, _, [], [], []) :- !.
tr_comp_out(_, vqc, _, _, [], [], []) :- !.
tr_comp_out(To, appos(NP), _, _, [], Outs, []) :- !, tr_np_out(To, NP, Outs, _, _).
tr_comp_out(To, topic(NP), _, _, [], Outs, []) :- !, tr_np_out(To, NP, Outs, _, _).
tr_comp_out(To, obj(NP), _, _, [], Outs, []) :-
    tr_np_out(To, NP, O1, AN, ANb), nb_setval('$tr_ant', a(AN, ANb)),      % what an `of which' after it agrees with
    tr_marker(To, NP, M), append(M, O1, Outs).
tr_comp_out(To, adj(Ws), Noun, Number, [], Outs, []) :- tr_adjectives_out(To, Ws, Noun, Number, As), tr_adj_words(As, Outs).
%% an object complement: the adjectives agree with the OBJECT, whose noun
%% and number tr_np_out/5 answers, and they go before the object in the
%% lesson's language and after it in English
tr_comp_out(To, oc(NP, Ws), _, _, [], Outs, []) :-
    tr_np_out(To, NP, O1, Noun, Number), tr_marker(To, NP, M), append(M, O1, Obj),
    tr_adjectives_out(To, Ws, Noun, Number, As), tr_adj_words(As, AOut),
    ( To == english -> append(Obj, AOut, Outs) ; append(AOut, Obj, Outs) ).
%% a `that' clause: the word, and the clause written as a statement
tr_comp_out(To, paren(Inner), _, _, [], Outs, []) :- !, tr_aside_out(To, paren, Inner, Outs).
tr_comp_out(To, comment(Inner), _, _, [], Outs, []) :- !, tr_aside_out(To, comment, Inner, Outs).
tr_comp_out(To, neg(C), Noun, Number, [], [o(No, lower)|Outs], []) :- !,
    ( To == english -> No = not ; tr_negation_word(No) ),
    tr_comp_out(To, C, Noun, Number, [], Outs, []).
%% a noun's preposition before its infinitive: the lesson's word, and none
%% in English, whose infinitive has its own `to'
tr_comp_out(english, nprep(_), _, _, [], [], []) :- !.
tr_comp_out(foreign, nprep(w(P, C)), _, _, [], [o(PT, C)], []) :- !, tr_word_across(w(P, lower), foreign, preposition, PT).
%% a comparison: English's `than' or `as', and the lesson's word for `than'
tr_comp_out(english, cmp(K, NP), _, _, [], [o(W, lower)|NPOut], []) :- !,
    ( K == equal -> W = as ; W = than ), tr_np_out(english, NP, NPOut, _, _).
tr_comp_out(foreign, cmp(_, NP), _, _, [], [o(W, lower)|NPOut], []) :- !,
    tr_than_word(phrase, W), tr_np_out(foreign, NP, NPOut, _, _).
%% ... and before a preposition, the lesson's conjunction for `than'
tr_comp_out(english, cmpp(A, K, PP), N, Nb, [], Outs, []) :- !,
    ( A = w(AW, AC) -> AO = [o(AW, AC)] ; AO = [] ),
    ( K == equal -> W = as ; W = than ), tr_comp_out(english, PP, N, Nb, [], PPO, []),
    append(AO, [o(W, lower)|PPO], Outs).
tr_comp_out(foreign, cmpp(A, _, PP), N, Nb, [], Outs, []) :- !,
    ( A = w(AW, AC) -> tr_word_across(w(AW, lower), foreign, adverb, AT), AO = [o(AT, AC)] ; AO = [] ),
    tr_than_word(adjective, W), tr_comp_out(foreign, PP, N, Nb, [], PPO, []),
    append(AO, [o(W, lower)|PPO], Outs).
%% more than an adjective: `more than questionable', `più che discutibile'
tr_comp_out(english, mt(Ws), Noun, Number, [], [o(more, lower), o(than, lower)|Outs], []) :- !,
    tr_adjectives_out(english, Ws, Noun, Number, As), tr_adj_words(As, Outs).
tr_comp_out(foreign, mt(Ws), Noun, Number, [], [o(M, lower), o(T, lower)|Outs], []) :- !,
    tr_degree_out(M), tr_than_word(adjective, T),
    tr_adjectives_out(foreign, Ws, Noun, Number, As), tr_adj_words(As, Outs).
%% ... an infinitive with its pronouns: English's -ing form and the object
%% pronouns after it, the lesson's infinitive with its own joined to it --
%% a dative as the lesson's dative (`chiedergli')
tr_comp_out(english, pinf(w(P, C), cl(L, Cls)), _, _, [], [o(PT, C), o(G, lower)|Objs], []) :- !,
    tr_word_across(w(P, lower), english, preposition, PT), tr_lexeme_across(L, english, LT),
    en_gerund_of(LT, G),
    findall(o(T, lower), ( member(X, Cls), ( X = dat(w(T, _)) -> true ; X = w(T, _) ) ), Objs).
tr_comp_out(foreign, pinf(w(P, C), cl(L, Cls)), _, _, [], [o(PT, C), o(Inf, lower)], []) :- !,
    tr_word_across(w(P, lower), foreign, preposition, PT), tr_lexeme_across(L, foreign, LT),
    findall(F, ( member(X, Cls), tr_pinf_clitic_out(X, F) ), Ps),
    once(tr_solve(infinitive_of(Inf0, LT))), tr_joined_infinitive(Inf0, Ps, Inf),
    tr_infinitive_verb(L).
tr_comp_out(english, pinf(w(P, C), L), _, _, [], [o(PT, C), o(G, lower)], []) :- !,
    tr_word_across(w(P, lower), english, preposition, PT), tr_lexeme_across(L, english, LT0),
    ( LT0 = reflexive(LT) -> true ; LT = LT0 ),                  % English has no reflexive there
    en_gerund_of(LT, G).
tr_comp_out(foreign, pinf(w(P, C), L), _, _, [], [o(PT, C), o(Inf, lower)], []) :- !,
    tr_word_across(w(P, lower), foreign, preposition, PT), tr_lexeme_across(L, foreign, LT0),
    ( LT0 = reflexive(LT) -> tr_reflexive_out(R), Ps = [R] ; LT = LT0, Ps = [] ),
    once(tr_solve(infinitive_of(Inf0, LT))), tr_joined_infinitive(Inf0, Ps, Inf),
    tr_infinitive_verb(L).
%% WHAT FOLLOWS AN INFINITIVE IS THE INFINITIVE'S, and a person there is its
%% object: `non era in grado di riconoscere i suoi amici' is `no era capaz de
%% reconocer a sus amigos', and with the copula still the verb being written
%% the word before a person was left out -- a copula's complement is no
%% object (tr_marker/3)
%% ... and it remembers the verb it took the place of, which governs an
%% infinitive joined to it (tr_comps_out/7)
tr_infinitive_verb(L0) :-
    ( L0 = reflexive(L) -> V = refl(L) ; V = L0 ),
    ( tr_global('$tr_verb', V0) -> nb_setval('$tr_inf_governor', gov(V, V0)) ; true ),
    nb_setval('$tr_verb', V).
%% ... after the word the verb takes before a clause, where the lesson
%% states one: `sin darse cuenta DE que ...', `"da cuenta" takes "de" before
%% the clause.'
tr_comp_out(To, that(S), _, _, [], Outs, []) :- !,
    ( To == foreign, tr_verb_takes(P, clause) -> Pre = [o(P, lower)] ; Pre = [] ),
    tr_that_word(To, W), tr_write_nested(To, S, SOut),
    append(Pre, [o(W, lower)|SOut], Outs).
%% (`whether' is English's own, and the lesson's word for `if' says it)
tr_comp_out(To, wh(whether, S), _, _, [], [o(W, lower)|SOut], []) :- !,
    ( To == english -> W = whether ; once(( tr_solve(mean(W, if)), tr_class_of(W, conjunction) )) ),
    tr_write_nested(To, S, SOut).
tr_comp_out(To, wh(Q, S), _, _, [], [o(W, lower)|SOut], []) :- !,
    tr_question_across(To, _, Q, W), tr_write_nested(To, S, SOut).
%% the relative one: a conjunction the lesson gives the meaning, before the
%% question word -- `donde' before `dónde'
tr_comp_out(To, rwh(Q, S), _, _, [], [o(W, lower)|SOut], []) :- !,
    (   To == foreign, tr_solve(mean(W0, Q)), tr_class_of(W0, conjunction) -> W = W0
    ;   tr_question_across(To, _, Q, W)
    ), !, tr_write_nested(To, S, SOut).

%% A CLAUSE WRITTEN INSIDE ANOTHER PUTS BACK WHAT IT SET. tr_write/4 keeps
%% the verb and the subject's gender in globals for what it writes after
%% its complements -- a passive's participle agreeing, a bare base after a
%% modal -- and a `that' clause or a relative clause is written in the
%% middle of the complements, so without this the OUTER clause's
%% participle agreed with the inner clause's subject.
tr_write_nested(To, S, Out) :-
    tr_global('$tr_verb', V), tr_global('$tr_subject_gender', G),
    (   tr_write(To, statement, S, Out0)
    ->  nb_setval('$tr_verb', V), nb_setval('$tr_subject_gender', G), Out = Out0
    ;   nb_setval('$tr_verb', V), nb_setval('$tr_subject_gender', G), fail
    ).

tr_global(K, V) :- ( catch(nb_getval(K, V0), _, fail) -> V = V0 ; V = none ).

%% THE RELATIVE WORD OUT. For a subject or an object every language here has
%% one word -- `that', `che', `que' -- the relative the lesson gives that
%% means `that'. After a preposition English writes `which' and a lesson
%% writes the relative it says follows a preposition (`"cui" follows the
%% preposition', Italian's `a cui'); a lesson with none writes the article
%% agreeing with the phrase and then its relative, which is Spanish's `al
%% que', `a la que' once the contraction is made.
tr_relative_out(english, pp(w(P, C)), _, _, [o(P, C), o(which, lower)]) :- !.
tr_relative_out(english, _, _, _, [o(that, lower)]) :- !.
tr_relative_out(foreign, pp(w(P, C)), Noun, Number, Outs) :- !,
    tr_word_across(w(P, lower), foreign, preposition, PT),
    (   once(( tr_solve(relative(R0)), tr_holds(follow(R0, preposition)) ))
    ->  Outs = [o(PT, C), o(R0, lower)]
    ;   tr_relative_that(R),
        tr_det_out(foreign, det(article, the, w(the, lower)), Noun, Number, [], DOut),
        append([o(PT, C)|DOut], [o(R, lower)], Outs)
    ).
tr_relative_out(foreign, _, _, _, [o(R, lower)]) :- tr_relative_that(R).

tr_relative_that(R) :- once(( tr_solve(relative(R0)), tr_solve(mean(R0, that)) )), R = R0.

%% the relative that stands after a preposition: English's `which', and the
%% one a lesson says follows a preposition
tr_rel_after_prep(english, which) :- !.
tr_rel_after_prep(foreign, R) :- atom(R), tr_solve(relative(R)), tr_holds(follow(R, preposition)), !.

%% ... written after its preposition, agreeing with the object before it
tr_comp_out(To, rpp(w(P, C), NP), _, _, [], Outs, []) :- !,
    tr_global('$tr_ant', A), ( A = a(AN, ANb) -> true ; AN = none, ANb = singular ),
    tr_relative_out(To, pp(w(P, C)), AN, ANb, RO),
    tr_np_out(To, NP, NO, _, _), append(RO, NO, Outs).
tr_comp_out(To, pp(w(P, C), NP), _, _, [], [o(PT, C)|NPOut], []) :- tr_word_across(w(P, lower), To, preposition, PT), tr_np_out(To, NP, NPOut, _, _).
tr_comp_out(To, by(NP), _, _, [], [o(By, lower)|NPOut], []) :-
    tr_by_word(To, By), tr_np_out(To, NP, NPOut, _, _).
%% ENGLISH PUTS AN ADVERB AFTER THE OTHER COMPLEMENTS, THE LESSON'S LANGUAGE
%% WHERE THE SOURCE HAD IT: `salir así en una familia tan pacífica' written
%% with its adverb last came out `uscire in una famiglia così pacifica
%% così', two words for one and the first in the wrong place
tr_comp_out(english, adv(w(A, C)), _, _, [], [], [o(AT, C)]) :- !, tr_word_across(w(A, lower), english, adverb, AT).
tr_comp_out(foreign, adv(w(A, C)), _, _, [], [o(AT, C)], []) :- tr_word_across(w(A, lower), foreign, adverb, AT).
%% a participle predicated of the subject: English's own form, the lesson's
%% language agreeing with the subject as a passive's does
tr_comp_out(english, pred(L), _, _, [], [o(PP, lower)], []) :- !,
    tr_lexeme_across(L, english, LT), en_participle_of(LT, PP).
tr_comp_out(foreign, pred(L), _, Number, [], [o(PP, lower)], []) :- !,
    tr_lexeme_across(L, foreign, LT), tr_participle_agreeing(LT, Number, PP).
tr_comp_out(To, predq(L, C), N, Nb, Cl, [o(PP, C)], A) :- !, tr_comp_out(To, pred(L), N, Nb, Cl, [o(PP, _)], A).
%% ... and one said of the object, in the object pronoun's gender and number
%% (tr_comps_out/7)
tr_comp_out(foreign, opred(L, G, N), _, _, [], [o(PP, lower)], []) :- !,
    tr_lexeme_across(L, foreign, LT), tr_with_gender(G, tr_participle_agreeing(LT, N, PP)).
%% a time phrase, bare in every language; a conjunction between two
%% complements, by the target's word for it
tr_comp_out(To, at_time(NP), _, _, [], Outs, []) :- !, tr_np_out(To, NP, Outs, _, _).
tr_comp_out(To, cnj(w(C, CC)), _, _, [], Outs, []) :- !, tr_connector_out(To, w(C, CC), Outs).
%% an infinitive: English's `to' and the base form, the base alone after a
%% modal; the lesson's infinitive of its verb
%% the purpose out: English's `to' and the base, which is what it writes for
%% a plain infinitive too; the lesson's own word and its infinitive
%% a gerund with its complements, and `upon': English's -ing, after `on'
%% for the second; the lesson's gerund, or its word for the moment and the
%% infinitive when it names one
tr_comp_out(To, ger(reflexive(L), Cs), Noun, Number, [], [o(G, lower)|COut], []) :- !,
    tr_lexeme_across(L, To, LT), tr_gerund_out(To, LT, G0),
    ( To == foreign, tr_reflexive_out(R) -> atom_concat(G0, R, G) ; G = G0 ),   % English has no reflexive there
    tr_comps_out(To, Cs, Noun, Number, _, CO, CA), append(CO, CA, COut).
%% ... and the pronouns that stand before a verb are joined to a gerund,
%% as they are to an infinitive: `chiedendogli' (no accent is written: a
%% lesson cannot say where Spanish's `pidiéndole' puts one)
tr_comp_out(To, ger(L, Cs), Noun, Number, [], [o(G, lower)|COut], []) :- !,
    tr_lexeme_across(L, To, LT), tr_gerund_out(To, LT, G0),
    tr_comps_out(To, Cs, Noun, Number, Cl, CO, CA), append(CO, CA, COut),
    findall(P, member(o(P, _), Cl), Ps), atomic_list_concat([G0|Ps], G).
tr_comp_out(foreign, pger(L, Cs), Noun, Number, [], [o(P, lower), o(Inf, lower)|COut], []) :- !,
    tr_verb_takes(P), tr_lexeme_across(L, foreign, LT), once(tr_solve(infinitive_of(Inf, LT))),
    tr_comps_out(foreign, Cs, Noun, Number, _, CO, CA), append(CO, CA, COut).
tr_comp_out(english, upon(L, Cs), Noun, Number, [], [o(on, lower), o(G, lower)|COut], []) :- !,
    tr_lexeme_across(L, english, LT), en_gerund_of(LT, G),
    tr_comps_out(english, Cs, Noun, Number, _, CO, CA), append(CO, CA, COut).
tr_comp_out(foreign, upon(L, Cs), Noun, Number, [], Outs, []) :- !,
    tr_lexeme_across(L, foreign, LT),
    (   once(tr_solve(begin(M, moment))), once(tr_solve(infinitive_of(Inf, LT)))
    ->  Head = [o(M, lower), o(Inf, lower)]
    ;   tr_gerund_out(foreign, LT, G), Head = [o(G, lower)]
    ),
    tr_comps_out(foreign, Cs, Noun, Number, _, CO, CA), append(CO, CA, COut), append(Head, COut, Outs).
tr_comp_out(english, purpose(L), _, _, [], [o(to, lower), o(B, lower)], []) :- !,
    tr_lexeme_across(L, english, LT), en_base(LT, B).
tr_comp_out(foreign, purpose(L), _, _, [], [o(P, lower), o(Inf, lower)], []) :- !,
    tr_lexeme_across(L, foreign, LT), once(tr_solve(infinitive_of(Inf, LT))),
    once(( tr_solve(begin(P0, purpose)), P = P0 )),
    tr_infinitive_verb(L).
tr_comp_out(english, ainf(_, L), N, Nb, Cl, Outs, A) :- !, tr_comp_out(english, inf(L), N, Nb, Cl, Outs, A).
tr_comp_out(foreign, ainf(w(P, C), L), _, _, [], [o(PT, C), o(Inf, lower)], []) :- !,
    tr_word_across(w(P, lower), foreign, preposition, PT),
    tr_lexeme_across(L, foreign, LT), once(tr_solve(infinitive_of(Inf, LT))).
tr_comp_out(To, inf(L), _, _, [], Outs, []) :-
    tr_lexeme_across(L, To, LT),
    (   To == english
    ->  en_base(LT, B), ( tr_modal_verb -> Outs = [o(B, lower)] ; Outs = [o(to, lower), o(B, lower)] )
    ;   tr_verb_takes_gerund
    ->  tr_gerund_out(foreign, LT, G), Outs = [o(G, lower)], tr_infinitive_verb(L)
    ;   once(tr_solve(infinitive_of(Inf, LT))),
        ( tr_verb_takes(P) -> Outs = [o(P, lower), o(Inf, lower)] ; Outs = [o(Inf, lower)] ),
        tr_infinitive_verb(L)
    ).

%% ... and the verb being written takes the GERUND where the other language
%% writes an infinitive: `continua a aumentare' is `continúa aumentando', and
%% the lesson says so, `"continúa" takes the gerund.'
tr_verb_takes_gerund :-
    tr_global('$tr_verb', V0), ( V0 = refl(V) -> true ; V = V0 ), atom(V),
    tr_lexeme_across(V, foreign, VT), atom(VT),
    tr_solve(take(VT, gerund)), !.
%% the word the verb being written takes before an infinitive, where the
%% lesson states one: `"confida" takes "di" before the infinitive.'
tr_verb_takes(P) :- tr_verb_takes(P, infinitive).
tr_verb_takes(P, Class) :-
    tr_global('$tr_verb', V0),
    (   V0 = refl(V) -> atom(V), tr_lexeme_across(reflexive(V), foreign, reflexive(VT))     % the word it was written as
    ;   atom(V0), tr_lexeme_across(V0, foreign, VT)
    ), atom(VT),
    tr_solve(take_before(VT, P, Class)), !.
%% AN INFINITIVE WITH ITS OWN PRONOUNS OR IN THE PERFECT: English writes
%% `to', `have' and the participle, and its object pronouns after them; the
%% lesson's language joins the pronouns to the infinitive -- its auxiliary's,
%% in the perfect -- with the `e' an Italian infinitive ends in dropped, and
%% the reflexive as its own reflexive pronoun: `riprenderli', `recuperarlos',
%% `essersi persa', `haberse perdido'. English has no pronoun for the
%% reflexive there and writes none.
tr_comp_out(english, infx(L, Asp, Cls), _, _, [], Outs, []) :- !,
    tr_lexeme_across(L, english, LT),
    (   Asp == perfect -> en_participle_of(LT, PP), V = [o(have, lower), o(PP, lower)]
    ;   en_base(LT, B), V = [o(B, lower)]
    ),
    ( tr_modal_verb -> To = [] ; To = [o(to, lower)] ),
    findall(o(T, lower), member(w(T, _), Cls), Objs),
    append([To, V, Objs], Outs).
tr_comp_out(foreign, infx(L, Asp, Cls), _, _, [], Outs, []) :- !,
    tr_lexeme_across(L, foreign, LT),
    maplist(tr_enclitic_out, Cls, Ps),
    (   Asp == perfect
    ->  tr_infinitive_auxiliary(LT, Cls, AuxInf), tr_joined_infinitive(AuxInf, Ps, J),
        once(tr_solve(participle_of(PP, LT))), Outs = [o(J, lower), o(PP, lower)]
    ;   once(tr_solve(infinitive_of(Inf, LT))), tr_joined_infinitive(Inf, Ps, J), Outs = [o(J, lower)]
    ).
tr_comp_out(english, opron(dat(W)), N, Nb, Cl, Outs, A) :- !, tr_comp_out(english, opron(W), N, Nb, Cl, Outs, A).
tr_comp_out(english, opron(w(W, C)), _, _, [], [o(T, C)], []) :- tr_pronoun_across(english, object, w(W, C), _, _, T).
tr_comp_out(foreign, opron(dat(w(W, C))), _, _, Clitics, Outs, []) :-
    tr_dative_word(W, T), !,
    ( tr_holds(precede(T, verb)) -> Clitics = [o(T, C)], Outs = [] ; Clitics = [], Outs = [o(T, C)] ).
tr_comp_out(foreign, opron(dat(W)), N, Nb, Cl, Outs, A) :- !, tr_comp_out(foreign, opron(W), N, Nb, Cl, Outs, A).
tr_comp_out(foreign, opron(w(W, C)), _, _, Clitics, Outs, []) :-
    tr_pronoun_across(foreign, object, w(W, C), _, _, T),
    ( tr_holds(precede(T, verb)) -> Clitics = [o(T, C)], Outs = [] ; Clitics = [], Outs = [o(T, C)] ).

tr_pinf_clitic_out(dat(w(W, _)), T) :- tr_dative_word(W, T), !.
tr_pinf_clitic_out(dat(W), T) :- !, tr_enclitic_out(W, T).

%% the lesson's dative for an English pronoun, one that stands before the
%% verb first: `gli' and `loro' are both to them, and `loro' stands after the
%% verb and is never joined to one -- the line that lets `non importa loro'
%% read made the writer's first dative `loro', and `senza chiedergli' came
%% out `chiederloro'
tr_dative_word(W, T) :- tr_solve(mean(T, W)), tr_solve(dative(T)), tr_holds(precede(T, verb)), !.
tr_dative_word(W, T) :- tr_solve(mean(T, W)), tr_solve(dative(T)), !.
tr_pinf_clitic_out(W, T) :- tr_enclitic_out(W, T).

tr_enclitic_out(refl, R) :- tr_reflexive_out(R), !.
tr_enclitic_out(w(T, C), F) :- tr_pronoun_across(foreign, object, w(T, C), _, _, F).

%% the infinitive with the pronouns joined, the `e' it ends in dropped first
tr_joined_infinitive(Inf, [], Inf) :- !.
%% a verb of several words takes its pronouns on the first: `darse cuenta',
%% `rendersi conto'
tr_joined_infinitive(Inf, Ps, J) :-
    sub_atom(Inf, B, 1, _, ' '), !,
    sub_atom(Inf, 0, B, _, First), B1 is B + 1, sub_atom(Inf, B1, _, 0, Rest),
    tr_joined_infinitive(First, Ps, J1), atomic_list_concat([J1, ' ', Rest], J).
tr_joined_infinitive(Inf, Ps, J) :-
    ( atom_concat(Stem, e, Inf) -> true ; Stem = Inf ),
    atomic_list_concat([Stem|Ps], J).

%% the perfect's auxiliary as an infinitive: the copula's where the lesson
%% says the verb or the reflexive builds its perfect with it, and otherwise
%% the infinitive of the auxiliary that means `has'
tr_infinitive_auxiliary(LT, Cls, Inf) :-
    (   tr_solve(auxiliary_of(A, LT)) -> true
    ;   memberchk(refl, Cls), tr_solve(auxiliary_of(A, reflexive)) -> true
    ;   tr_solve(auxiliary(A)), tr_solve(mean(A, has)) -> true
    ),
    once(tr_solve(infinitive_of(Inf, A))).

tr_gerund_out(english, LT, G) :- !, en_gerund_of(LT, G).
tr_gerund_out(foreign, LT, G) :- once(tr_solve(gerund_of(G, LT))).

%% the target's word for `by': English's own, or the one its lesson gives
tr_by_word(english, by) :- !.
tr_by_word(foreign, By) :- once(tr_solve(mean(By, by))).

%% the verb group being written is a modal
tr_modal_verb :-
    catch(nb_getval('$tr_verb', V), _, fail), tr_side_here(Side),
    ( Side == english -> en_modal_out(V, _, _) ; tr_class_of(V, modal) ).

%% ---- the verb group out ---------------------------------------------------------

%% the lesson's verb in the subject's number, tense and person, the denial
%% and the object pronouns before it; the perfect as the auxiliary that
%% means `has' in that form and the participle, the progressive as the one
%% that means `is' and the gerund
%% the lesson's language puts its reflexive pronoun back, before the verb
%% with the other clitics
%% -- UNLESS ITS OWN VERB IS NOT ONE. Spanish's `quedarse' is reflexive and
%% Italian's `rimanere' is not: `se han quedado en casa' is `sono rimasti a
%% casa', and written back it came out `si sono rimasti'. The lesson says it
%% of the word: `"rimane" is not reflexive.'
%% the reflexive's passive: the reflexive pronoun and the verb in the
%% subject's person and number, `si aumentarono le vendite', `se venden
%% casas' -- the construction's pronoun, which a verb the lesson says is not
%% reflexive still takes
fo_group(reflexive(L), P, N, T, passive, Neg, Clitics, Group) :- !,
    ( tr_reflexive_out(R) -> Cs = [o(R, lower)|Clitics] ; Cs = Clitics ),
    fo_group(L, P, N, T, simple, Neg, Cs, Group).
fo_group(reflexive(L), P, N, T, A, Neg, Clitics, Group) :-
    atom(L), tr_solve(neg(reflexive(L))), !,
    fo_group(L, P, N, T, A, Neg, Clitics, Group).
fo_group(reflexive(L), P, N, T, A, Neg, Clitics, Group) :- !,
    ( tr_reflexive_out(R) -> Cs = [o(R, lower)|Clitics] ; Cs = Clitics ),
    nb_setval('$tr_refl', yes),
    (   fo_group(L, P, N, T, A, Neg, Cs, Group) -> nb_setval('$tr_refl', no)
    ;   nb_setval('$tr_refl', no), fail
    ).
fo_group(L, P, N, T, A, Neg, Clitics, Group) :-
    (   A == passive
    ->  tr_copula_lexeme(CL), tr_make(CL, N, T, P, CForm),
        tr_participle_agreeing(L, N, PP), VW = [o(CForm, lower), o(PP, lower)]
    ;   A == passive_perfect
    ->  tr_copula_lexeme(CL), tr_perfect_auxiliary(CL, Aux), tr_make(Aux, N, T, P, CForm),
        tr_participle_agreeing(CL, N, Been), tr_participle_agreeing(L, N, PP),
        VW = [o(CForm, lower), o(Been, lower), o(PP, lower)]
    ;   A == perfect
    ->  fo_perfect_aux(L, Aux), tr_make(Aux, N, T, P, AuxForm),
        %% built with the copula, the participle agrees with the subject:
        %% `si è sbagliato', `è uscita'
        (   tr_copula_lexeme(Aux) -> tr_participle_agreeing(L, N, PP) ; once(tr_solve(participle_of(PP, L))) ),
        VW = [o(AuxForm, lower), o(PP, lower)]
    ;   A == gerund
    ->  once(tr_solve(gerund_of(G, L))), VW = [o(G, lower)]
    ;   A == imperative
    ->  tr_imperative_form(L, N, Neg, IF), VW = [o(IF, lower)]
    ;   A == progressive
    ->  tr_auxiliary(is, Aux), tr_make(Aux, N, T, P, AuxForm), once(tr_solve(gerund_of(G, L))), VW = [o(AuxForm, lower), o(G, lower)]
    ;   tr_make(L, N, T, P, Form), VW = [o(Form, lower)]
    ),
    (   Neg == yes
    ->  tr_negation_word(No),
        ( tr_holds(follow(No, verb)) -> append(Clitics, VW, G1), append(G1, [o(No, lower)], Group)
        ; append([o(No, lower)|Clitics], VW, Group) )
    ;   append(Clitics, VW, Group)
    ).

tr_fronts_out(To, Cs, Outs) :- tr_fronts_out(To, Cs, none, singular, Outs).
tr_fronts_out(_, [], _, _, []).
tr_fronts_out(To, [C|Cs], Noun0, Number, Outs) :-
    ( C = adj(_) -> Noun = Noun0 ; Noun = none ),                    % only an adjective agrees
    tr_comp_out(To, C, Noun, Number, _, O1, A1), append(O1, A1, O),
    tr_fronts_out(To, Cs, Noun, Number, Os), append(O, Os, Outs).

%% THE PERFECT'S AUXILIARY IS THE LESSON'S TO NAME: `"è" is the auxiliary of
%% the reflexive.' makes Italian's `si è sbagliato' where it wrote `si ha
%% sbagliato', and `"è" is the auxiliary of "esce".' names one verb; the
%% one that means `has' otherwise, as it always was.
fo_perfect_aux(L, Aux) :-
    (   tr_global('$tr_refl', yes), tr_solve(auxiliary_of(A0, reflexive)) -> Aux = A0
    ;   tr_solve(auxiliary_of(A0, L)) -> Aux = A0
    ;   tr_auxiliary(has, Aux)
    ), !.

%% A PARTICIPLE IN A PASSIVE AGREES WITH ITS SUBJECT, and picking the form
%% is what the four `participle_of' rows are for. The gender is the SUBJECT
%% PHRASE's, read out of the global the writer set, and the number comes
%% with it; a form is chosen by asking what the lesson says of the word
%% itself -- `"considerata" is feminine.' -- exactly as an adjective is
%% chosen among the words a meaning gives.
%%
%% THE MASCULINE SINGULAR IS THE FALLBACK and it is stated first by the
%% builder, so a lesson that gives one form writes what it wrote before.
tr_participle_agreeing(L, N, PP) :-
    tr_subject_gender(G),
    findall(P, tr_solve(participle_of(P, L)), Ps0), Ps0 \== [],
    (   member(P, Ps0), tr_participle_is(P, Ps0, G, N) -> PP = P
    ;   Ps0 = [PP|_]
    ), !.
tr_participle_agreeing(L, _, PP) :- once(tr_solve(participle_of(PP, L))).

%% a participle form's own gender and number: the gender the lesson states
%% of the word, and the number by whether it is another form's plural
tr_participle_is(P, Ps, G, N) :-
    ( G == feminine -> tr_holds(feminine(P)) ; \+ tr_holds(feminine(P)) ),
    (   N == plural
    ->  member(S, Ps), S \== P, tr_solve(plural_of(P, S))
    ;   \+ ( member(S, Ps), S \== P, tr_solve(plural_of(P, S)) )
    ).

%% run a goal with the gender a participle must agree with, and put back
%% whatever the enclosing sentence had set -- a reduced relative agrees with
%% its OWN noun, not with the subject of the sentence it sits in
tr_with_gender(G, Goal) :-
    ( catch(nb_getval('$tr_subject_gender', Old), _, fail) -> true ; Old = masculine ),
    nb_setval('$tr_subject_gender', G),
    ( call(Goal) -> R = yes ; R = no ),
    nb_setval('$tr_subject_gender', Old),
    R == yes.

%% the gender of the subject the writer is putting out, set by tr_write/4
tr_subject_gender(G) :- ( catch(nb_getval('$tr_subject_gender', G0), _, fail) -> G = G0 ; G = masculine ).
%% the gender a clause's subject gives what agrees with it: its noun's, and
%% where it has none a pronoun's -- `Ella es alta' is `Lei è alta', where the
%% pronoun gave nothing and it came out `alto' -- and the masculine otherwise
tr_subject_gender_of(Subject, Noun, SG) :-
    (   Noun \== none, tr_gender(Noun, SG0), SG0 \== none -> SG = SG0
    ;   Subject = pronoun(_, _, w(she, _)) -> SG = feminine
    ;   SG = masculine
    ).

%% the word this lesson uses for a reflexive, if it has one
tr_reflexive_out(R) :- tr_solve(reflexive(R)), tr_class_of(R, pronoun), !.

%% the auxiliary that means `has' (the perfect) or `is' (the progressive):
%% the one so meant, and for the perfect the first the lesson names at
%% all, as before a lesson said what its auxiliary meant
tr_auxiliary(has, Aux) :- tr_solve(auxiliary(Aux)), tr_solve(mean(Aux, has)), !.
tr_auxiliary(has, Aux) :- tr_solve(auxiliary(Aux)), tr_solve(mean(Aux, _)), !.
tr_auxiliary(is, Aux) :- tr_solve(auxiliary(Aux)), tr_solve(mean(Aux, is)), !.

%% English's verb group: the statement's words, and for a question the word
%% that fronts and the words that stay behind the subject. A modal is its
%% own word in the tense (`can', `could'), never `does', and `cannot' denied
en_group(L, _, _, T, simple, Neg, Statement, Front, Tail) :- en_modal_out(L, _, _), !,
    en_modal_out(L, T, M),
    (   Neg == yes -> ( M == can -> Front = o(cannot, lower), Tail = [] ; Front = o(M, lower), Tail = [o(not, lower)] )
    ;   Front = o(M, lower), Tail = []
    ),
    Statement = [Front|Tail].
%% ENGLISH DROPS IT: there is no reflexive pronoun in `the generals appealed',
%% and writing one would say something the Italian does not.
en_group(reflexive(L), P, N, T, A, Neg, Statement, Front, Tail) :- !,
    en_group(L, P, N, T, A, Neg, Statement, Front, Tail).

%% English's passive: the copula in the subject's person and number and the
%% participle; the perfect passive `has been' and the participle. English
%% has no agreement to make, so the participle is simply the one the lesson
%% gave or -ed makes.
en_group(L, P, N, T, passive, Neg, Statement, Front, Tail) :- !,
    en_participle_of(L, PP),
    (   T == future -> Front = o(will, lower), Be = [o(be, lower)]
    ;   T == conditional -> Front = o(would, lower), Be = [o(be, lower)]
    ;   en_copula_form(P, N, T, C), Front = o(C, lower), Be = []
    ),
    ( Neg == yes -> Not = [o(not, lower)] ; Not = [] ),
    append([Not, Be, [o(PP, lower)]], Tail),
    Statement = [Front|Tail].
en_group(L, P, N, T, passive_perfect, Neg, Statement, Front, Tail) :- !,
    en_perfect_front(P, N, T, Front, Have),
    en_participle_of(L, PP),
    ( Neg == yes -> Not = [o(not, lower)] ; Not = [] ),
    append([Not, Have, [o(been, lower), o(PP, lower)]], Tail),
    Statement = [Front|Tail].

%% the copula's imperative is `be', denied `do not be': `Estate contento.'
%% came out `Is happy.'
en_group(is, _, _, _, imperative, Neg, Statement, Front, Tail) :- !,
    (   Neg == yes -> Front = o(do, lower), Tail = [o(not, lower), o(be, lower)]
    ;   Front = o(be, lower), Tail = []
    ),
    Statement = [Front|Tail].
%% -- and `is' with a gerund after it (`is being careful') is CUT AND THEN
%% REFUSED on purpose: the copula has no progressive this writes, and
%% falling through to the clause below would put the stemmer on `is'
%% A VERB OF SEVERAL WORDS THAT OPENS ON THE COPULA IS THE COPULA'S: `servono
%% nove miliardi' is `nine billions ARE needed', and inflected by its base
%% it was `be needed'
en_group(L, P, N, T, A, Neg, [Front|Tail], Front, Tail) :-
    L \== is, en_phrasal(L, is, Pt), !,
    en_group(is, P, N, T, A, Neg, _, Front, T0), append(T0, [o(Pt, lower)], Tail).
%% (the copula's own progressive, `is being', is the general clause's below:
%% with the cut first, `El comité está siendo presionado' had no English)
en_group(is, P, N, T, A, Neg, Statement, Front, Tail) :- A \== progressive, !,
    ( Neg == yes -> Not = [o(not, lower)] ; Not = [] ),
    (   A == perfect
    ->  en_perfect_front(P, N, T, Front, Have), append([Not, Have, [o(been, lower)]], Tail)
    ;   T == future
    ->  Front = o(will, lower), append(Not, [o(be, lower)], Tail)
    ;   T == conditional
    ->  Front = o(would, lower), append(Not, [o(be, lower)], Tail)
    ;   en_copula_form(P, N, T, C), Front = o(C, lower), Tail = Not
    ),
    Statement = [Front|Tail].
%% ENGLISH'S IMPERATIVE IS THE BASE FORM, and its denial is `do not' --
%% never `does not', because an imperative has no person to agree with.
en_group(L, _, _, _, imperative, Neg, Statement, Front, Tail) :- !,
    en_base(L, B),
    (   Neg == yes
    ->  Front = o(do, lower), Tail = [o(not, lower), o(B, lower)], Statement = [Front|Tail]
    ;   Front = o(B, lower), Tail = [], Statement = [Front]
    ).
en_group(L, _, _, _, gerund, Neg, Statement, Front, []) :- !,
    en_gerund_of(L, G), Front = o(G, lower),
    ( Neg == yes -> Statement = [o(not, lower), Front] ; Statement = [Front] ).
en_group(L, P, N, T, A, Neg, Statement, Front, Tail) :-
    en_base(L, B),
    ( Neg == yes -> Not = [o(not, lower)] ; Not = [] ),
    (   A == perfect
    ->  en_perfect_front(P, N, T, Front, Have), en_participle_of(L, PP),
        append([Not, Have, [o(PP, lower)]], Tail), Statement = [Front|Tail]
    ;   A == progressive
    ->  en_gerund_of(L, G),
        (   T == future -> Front = o(will, lower), append(Not, [o(be, lower), o(G, lower)], Tail)
        ;   T == conditional -> Front = o(would, lower), append(Not, [o(be, lower), o(G, lower)], Tail)
        ;   en_copula_form(P, N, T, C), Front = o(C, lower), append(Not, [o(G, lower)], Tail)
        ),
        Statement = [Front|Tail]
    ;   T == future
    ->  Front = o(will, lower), append(Not, [o(B, lower)], Tail), Statement = [Front|Tail]
    ;   T == conditional
    ->  Front = o(would, lower), append(Not, [o(B, lower)], Tail), Statement = [Front|Tail]
    ;   en_do(P, N, T, D), Front = o(D, lower), append(Not, [o(B, lower)], Tail),
        (   Neg == yes -> Statement = [Front|Tail]
        ;   T == past -> en_past_of(L, Past), Statement = [o(Past, lower)]
        ;   P == third, N == singular -> Statement = [o(L, lower)]
        ;   Statement = [o(B, lower)]
        )
    ).

en_copula_form(first, singular, present, am) :- !.
en_copula_form(third, singular, present, is) :- !.
en_copula_form(_, _, present, are) :- !.
en_copula_form(first, singular, past, was) :- !.
en_copula_form(third, singular, past, was) :- !.
en_copula_form(_, _, past, were).

en_have(_, _, past, had) :- !.
en_have(third, singular, _, has) :- !.
en_have(_, _, _, have).

%% the perfect's front in a tense: `has', `had' -- and `will have', `would
%% have', where the lesson's conditional perfect (`avrebbe intascato', what
%% a newspaper says was alleged) came out `has pocketed'
en_perfect_front(_, _, future, o(will, lower), [o(have, lower)]) :- !.
en_perfect_front(_, _, conditional, o(would, lower), [o(have, lower)]) :- !.
en_perfect_front(P, N, T, o(H, lower), []) :- en_have(P, N, T, H).

en_do(_, _, past, did) :- !.
en_do(third, singular, _, does) :- !.
en_do(_, _, _, do).

en_base(has, have) :- !.
en_base(V, B) :- en_phrasal(V, V1, P), !, en_base(V1, B1), atomic_list_concat([B1, P], ' ', B).
en_base(V, B) :- reason_base(V, B).

%% A VERB OF TWO WORDS INFLECTS ITS FIRST: `ends up' is `must end up',
%% `ended up', `ending up' -- where the stemmer took the whole atom and
%% wrote `must ends up'. The lesson gives such a verb as it gives any other,
%% in the third person (`The intransitive verb "finisce" means "ends up".').
en_phrasal(V, V1, P) :- atom(V), sub_atom(V, Bf, 1, _, ' '), !, sub_atom(V, 0, Bf, _, V1), Af is Bf + 1, sub_atom(V, Af, _, 0, P).

%% the past of a verb the lesson gave in the third person: one the lesson
%% stated (`"ate" is the past of "eats"'), `had', or the regular -ed --
%% lived, carried, walked; the participle stated, or the past
en_past_of(V, P) :- tr_solve(past_of(P0, V)), !, P = P0.
en_past_of(has, had) :- !.
en_past_of(V, P) :- en_phrasal(V, V1, Pt), !, en_past_of(V1, P1), atomic_list_concat([P1, Pt], ' ', P).
en_past_of(V, P) :- en_base(V, B), tr_english_ed(B, P).

en_participle_of(V, PP) :- tr_solve(participle_of(P0, V)), !, PP = P0.
en_participle_of(V, PP) :- en_phrasal(V, V1, Pt), !, en_participle_of(V1, P1), atomic_list_concat([P1, Pt], ' ', PP).
en_participle_of(V, PP) :- en_past_of(V, PP).

tr_english_ed(B, P) :- sub_atom(B, _, 1, 0, e), !, atom_concat(B, d, P).
tr_english_ed(B, P) :- reason_third(B, T), atom_concat(Stem, ies, T), !, atom_concat(Stem, ied, P).
tr_english_ed(B, P) :- atom_concat(B, ed, P).

%% the gerund of a verb the lesson gave in the third person: one the lesson
%% stated (`"running" is the gerund of "runs"'), `being', `having', or the
%% base and -ing by the rule below
en_gerund_of(V, G) :- tr_solve(gerund_of(G0, V)), !, G = G0.
en_gerund_of(is, being) :- !.
en_gerund_of(has, having) :- !.
en_gerund_of(V, G) :- en_phrasal(V, V1, Pt), !, en_gerund_of(V1, G1), atomic_list_concat([G1, Pt], ' ', G).
en_gerund_of(V, G) :- en_base(V, B), tr_english_ing(B, G).

%% -ing on a base: ie becomes y (lying), a final e goes unless another e, a
%% y or an o precedes it (making, seeing, dyeing, hoeing); `being' is its
%% own. A doubled consonant (running) is no rule of this, and is a line of
%% the lesson's -- corpus/build.pl writes one for every verb this rule
%% gets wrong, which is why the rule is the translator's and not copied
tr_english_ing(be, being) :- !.
tr_english_ing(B, G) :- atom_concat(S, ie, B), !, atom_concat(S, ying, G).
tr_english_ing(B, G) :- atom_concat(S, e, B), \+ sub_atom(S, _, 1, 0, e), \+ sub_atom(S, _, 1, 0, y), \+ sub_atom(S, _, 1, 0, o), !, atom_concat(S, ing, G).
tr_english_ing(B, G) :- atom_concat(B, ing, G).

%% ---- assembling the sentence -----------------------------------------------------

en_assemble(statement, _, _, Subject, Statement, _, _, Rest, Outs) :- !,
    tr_concat([Subject, Statement, Rest], Outs).
en_assemble(question, Asked, AskedOut, Subject, Statement, Front, Tail, Rest, Outs) :-
    (   Asked = subject(_) -> tr_concat([Subject, Statement, Rest], Outs)
    ;   tr_concat([AskedOut, [Front], Subject, Tail, Rest], Outs)
    ).

fo_assemble(none, _, Subject, Group, Rest, Outs) :- !, tr_concat([Subject, Group, Rest], Outs).
fo_assemble(subject(_), _, Subject, Group, Rest, Outs) :- !, tr_concat([Subject, Group, Rest], Outs).
fo_assemble(_, AskedOut, Subject, Group, Rest, Outs) :- tr_concat([AskedOut, Group, Subject, Rest], Outs).

tr_concat([], []).
tr_concat([L|Ls], Outs) :- tr_concat(Ls, Rest), append(L, Rest, Outs).

%% ---- one word across --------------------------------------------------------------

%% a word's lexeme on this side, its meanings on the other of the class
%% asked for, the first of them
%% THE AGENT'S `by' BELONGS TO THE PASSIVE. Spanish's `por' is `by' after a
%% passive -- read there as by/1, never as a phrase -- and `for', `through'
%% or `because of' everywhere else: `por una lesión' is out for an injury,
%% `optó por una vía' opted for a way, and crossed by its first meaning they
%% came out `da una lesione', `da una via', the agent's `da'. A phrase with
%% a preposition that is no agent crosses by its first meaning that is not
%% `by', when the lesson gives it another.
tr_prep_across(P, PT) :-
    tr_word_across(w(P, lower), english, preposition, PT0),
    (   PT0 == by, tr_side_here(Side), Side == foreign, tr_lexeme(foreign, P, L, _),
        tr_meanings_of(L, english, preposition, Ms), member(PT, Ms), PT \== by
    ->  true
    ;   PT = PT0
    ).

tr_word_across(w(W, _), To, Class, T) :-
    tr_side_here(Side),
    tr_lexeme(Side, W, L, _), !,
    tr_meanings_of(L, To, Class, [T|_]).
tr_word_across(w(W, upper), _, _, W).

%% THE SAME SIDE ON BOTH ENDS IS THE WORD ITSELF. Every crossing is a
%% lookup from the side a sentence was READ on into the side it is
%% WRITTEN to, and the IR's side is English -- so writing an IR back
%% into English asks a word for its meaning on its own side, and the
%% answer is the word. Without this the lookup would go the other way
%% (mean/2 is the lesson's word to English's) and answer the lesson's
%% word for it. The three across predicates each get the rule, because
%% each is a crossing: a meaning, a pronoun and a question word.
tr_meanings_of(L, To, _, [L]) :- tr_side_here(From), From == To, !.
%% AND A NUMBER IS ITSELF IN EVERY LANGUAGE. `200' is 200 in Italian,
%% Spanish and English alike, so it has no mean/2 row and nothing to look
%% up -- and without this clause the lookup found no meaning at all and the
%% phrase was refused: `il premio da 200 milioni' came back `unknown: []',
%% a shape refusal with no shape missing, where `da due milioni' read.
tr_meanings_of(L, _, _, [L]) :- tr_digits(L), !.

%% the meanings of a lexeme on the other side -- of the class asked for,
%% when the lesson classes any of them (the lesson's language has classes;
%% English words are what their translations are)
tr_meanings_of(L, To, Class, Ms) :-
    tr_side_here(From),
    findall(M, tr_meaning(From, L, M), Ms0), Ms0 \== [],
    %% THE CLASS LINKS ARE ASKED FOR A NOUN AND AN ADJECTIVE ONLY. The
    %% dictionary's links for the other classes are noise to this: `más'
    %% is a preposition meaning `plus', `largo' an adverb meaning `largo',
    %% `dónde' an adverb meaning `whither' -- and the class-first lookup
    %% wrote `We need plus food' where the first meaning had been right
    (   To == foreign, memberchk(Class, [noun, adjective]),
        findall(M, ( member(M, Ms0), tr_solve(mean_as(M, L, Class)) ), Ms4), Ms4 \== []
    ->  Ms = Ms4
    %% ... and when no word means it IN that class, a word that means it in
    %% some class its sentence gave, before a word of the class that means
    %% something else: `el pequeño' is the small one, and `minuto' is a noun
    %% only as a minute
    %% -- and never a word that names NOBODY or a determiner, the filter
    %% below applied here too: `uno dei paesi' crossed as `se de los
    %% países', the impersonal `se' being the first word of the lesson's
    %% that means `one' in any class
    ;   To == foreign, memberchk(Class, [noun, adjective]),
        findall(M, ( member(M, Ms0), tr_solve(mean_as(M, L, _)), \+ tr_solve(impersonal(M)),
                     \+ tr_det_no_head(M) ), Ms5), Ms5 \== []
    ->  Ms = Ms5
    %% ... toward the lesson's side the same link picks among its words:
    %% `minuto' is a noun (a minute) and an adjective meaning `small', and
    %% a noun's place asking for `small' must not take it for the noun
    ;   To == foreign, findall(M, ( member(M, Ms0), tr_class_of(M, Class) ), Ms1), Ms1 \== []
    ->  Ms = Ms1
    %% the meanings the lesson gave THIS word IN THIS CLASS, when its
    %% sentences said so (tr_mean_links/2): `culpable' in an adjective's
    %% place is `guilty', never the noun's `culprit'
    %% -- and only when the FIRST meaning is linked to another class, so a
    %% meaning the lesson gave with no class (`The word "dónde" means
    %% "where"') is never passed over for one the dictionary classed
    %% ... and an ADVERB the same way: `Ora è indispensabile' is now, and
    %% `ora' is first the hour, a meaning the lesson classed a noun
    %% ... and a DEMONSTRATIVE and a DETERMINER, whose links come from the
    %% dictionary's determiner entries: `este' is the noun `east' first and
    %% `estos instrumentos' came out `East instruments', where Italian has
    %% no demonstrative meaning east and the sentence was refused; and
    %% `ninguna' is the pronoun `none' before it is the determiner `no'
    %% ... and a QUESTION WORD is no noun: `la cosa più difficile del mondo'
    %% is the hardest thing, and `cosa' means `what' first, a question word
    %% of the hand lesson's and a meaning with no class, which the rule
    %% below leaves first -- written as a noun it came out `el qué'
    ;   To == english, From == foreign, Class == noun,
        Ms0 = [M1|_], en_question(M1, _),
        findall(M, ( member(M, Ms0), tr_solve(mean_as(L, M, noun)) ), Ms8), Ms8 \== []
    ->  Ms = Ms8
    ;   To == english, From == foreign, memberchk(Class, [noun, adjective, adverb, demonstrative, determiner]),
        Ms0 = [M1|_], tr_solve(mean_as(L, M1, _)), \+ tr_solve(mean_as(L, M1, Class)),
        findall(M, ( member(M, Ms0), tr_solve(mean_as(L, M, Class)) ), Ms3), Ms3 \== []
    ->  Ms = Ms3
    %% ... and a PREPOSITION crosses by what the lesson gave it as one:
    %% `come dividendo straordinario' is as a dividend, and `come' is first
    %% `how', from a sentence that named no class -- which is right for
    %% `come possa essere successo' and was written `cómo dividendo'. The
    %% reader read it as a preposition, so the meaning is a preposition's.
    %% -- ONLY WHEN THE FIRST MEANING HAS NO CLASS AT ALL, the hand lesson's
    %% closed word. Where the dictionary put another class first the order
    %% stands, because a preposition is the class the reader is least sure
    %% of: it reads one by its place before a phrase, and a degree word
    %% stands in the same place -- `más despacio' crossed `más' by its
    %% preposition link, `plus', and `Speak more slowly.' came out `Speak
    %% plus slowly.'
    %% -- AND WHEN IT IS A CONJUNCTION'S, which takes a clause and never a
    %% phrase: `nonostante la continua incertezza' is DESPITE it, and
    %% `nonostante' is first `although', from a lesson that reads the
    %% conjunction; with the order standing it went out `although the
    %% continuous uncertainty', which Spanish could not write
    ;   To == english, From == foreign, Class == preposition,
        Ms0 = [M1|_], ( \+ tr_solve(mean_as(L, M1, _)) -> true ; tr_solve(mean_as(L, M1, conjunction)) ),
        findall(M, ( member(M, Ms0), tr_solve(mean_as(L, M, preposition)) ), Ms6), Ms6 \== []
    ->  Ms = Ms6
    ;   To == english, tr_english_shaped(Class, Ms0, Ms1), Ms1 \== []
    ->  Ms = Ms1
    %% and the mirror of the determiner rule, for the other side: a word
    %% that names NOBODY is no head of a phrase either. Spanish gives `one'
    %% to the impersonal `se' and to `uno', and with no meaning classed a
    %% noun the first won -- `uno de los paises' came out `se de los ...'
    ;   To == foreign, memberchk(Class, [noun, adjective]),
        findall(M, ( member(M, Ms0), \+ tr_solve(impersonal(M)),
                     \+ tr_det_no_head(M) ), Ms2), Ms2 \== []
    ->  Ms = Ms2
    ;   Ms = Ms0
    ).

%% A DETERMINER IS NO HEAD, UNLESS THE LESSON SAYS IT STANDS ALONE. Italian
%% `uno' is the article before `sc' AND the pronoun `one', so the filter
%% above dropped it with the article and kept the impersonal `si': `uno de
%% los violines' came out `Si dei violini'. `The pronoun "uno" does not
%% precede the verb.' is what says it heads a phrase of its own.
tr_det_no_head(M) :-
    tr_determiner(foreign, w(M, lower), _, _), \+ tr_standalone_det(foreign, w(M, lower)).

%% English words are what their translations are, but their shape says
%% something too: a verb a lesson gives is a third person (`eats',
%% `visits'), so in a verb's place a meaning shaped like one comes first,
%% and in a noun's or an adjective's place one that is not -- `visita' means
%% visit and visits, and which one is where the word stands
tr_english_shaped(verb, Ms0, Ms) :- !, findall(M, ( member(M, Ms0), tr_third_shaped(M) ), Ms).
%% ... and a phrase's head is never a DETERMINER, which is what `uno' needs:
%% the lesson says it is an article meaning `a' and a pronoun meaning
%% `one', and nothing in a lesson says which meaning belongs to which
%% class -- so `uno dei paesi' wrote `a of the countries' by taking the
%% first. A meaning that is one of English's own determiners is not a noun
%% and not an adjective; if that leaves nothing, the unfiltered list stands.
tr_english_shaped(Class, Ms0, Ms) :- memberchk(Class, [noun, adjective]), !,
    findall(M, ( member(M, Ms0), \+ tr_third_shaped(M), \+ tr_determiner(english, w(M, lower), _, _) ), Ms).
%% ... AND AN ADVERB'S PLACE WANTS A MEANING THAT IS ONE. `ancora' is an
%% adverb, a noun and a verb in the vocabulary -- anchor, anchors, even --
%% and a lesson says what a word MEANS and what classes it has and never
%% which meaning belongs to which class, so the first one won and `non sono
%% state ancora accertate' came out `have not been evacuated ANCHOR'.
%%
%% THE TEST NEEDS NO ENGLISH WORD LIST, and that is what makes it a rule
%% rather than a table: an English word is an adverb when some word the
%% lesson calls an adverb AND NOTHING ELSE means it. `even' is meant by
%% `perfino' and `persino', which are adverbs and nothing else; `anchor' is
%% meant by `ancora' alone, which is three things. Same shape as the
%% determiner filter above, and it falls back to the unfiltered list the
%% same way, so a lesson too small to hold a witness loses nothing.
tr_english_shaped(adverb, Ms0, Ms) :- !,
    findall(M, ( member(M, Ms0), tr_adverb_witness(M) ), Ms).
tr_english_shaped(_, _, []).
%% -- and never a word in `-us': the stemmer takes the `s' off `previous'
%% and `serious' as off `eats', so `la ronda anterior' was the ANTERIOR
%% round, `previous' being passed over in an adjective's place as a verb's
%% third person. No English verb's base ends in `u'.
tr_third_shaped(M) :- ( M == is ; M == has ; \+ sub_atom(M, _, 2, 0, us), reason_base(M, B), B \== M ), !.

%% a word the lesson calls an adverb and no other open class
tr_adverb_witness(M) :-
    tr_solve(mean(W, M)), tr_class_of(W, adverb),
    \+ tr_class_of(W, noun), \+ tr_class_of(W, verb), \+ tr_class_of(W, adjective), !.

%% the noun's gender first, none next, the first candidate last
tr_agree(english, [M|_], _, M) :- !.
tr_agree(foreign, Ms, Noun, T) :-
    tr_gender(Noun, G),
    (   G \== none, member(T, Ms), tr_gender(T, G1), G1 == G -> true
    ;   member(T, Ms), tr_gender(T, none) -> true
    ;   Ms = [T|_]
    ).

%% feminine, masculine or none -- feminine asked first, so a word the
%% lesson said was feminine is, whatever a rule adds; and a denial wins
%% over a rule, so `"problema" is not feminine' beside `Every noun that
%% ends in "a" is feminine' makes the word what the lesson's masculine
%% says of it, the way `The pronoun "él" does not precede the verb' does
%% a phrase whose noun is a NAME carries its gender, because no lesson can be
%% asked what a name is
tr_gender(named(G0, _), G) :- !, G = G0.
tr_gender(elided(G0), G) :- !, G = G0.
tr_gender(W, G) :-
    (   W == none -> G = none
    ;   tr_holds(feminine(W)) -> G = feminine
    ;   tr_holds(masculine(W)) -> G = masculine
    ;   G = none
    ).

%% ---- forms: lexemes, number, tense, person ------------------------------------------

%% a word's lexeme on a side -- the form the lesson gave -- and its number:
%% the word itself when the lesson gave it; the singular of a plural the
%% lesson stated; in the lesson's language the singular whose ending rule
%% makes the word; in English a noun the stemmer takes back
%% A NUMBER IN DIGITS IS ITS OWN LEXEME ON EVERY SIDE. It is the one word
%% no lesson gives and none needs to: `200' is 200 in every language, so it
%% is known, it is a number, and it crosses as itself.
tr_lexeme0(_, W, W, singular) :- tr_digits(W), !.
tr_lexeme0(Side, W, W, singular) :- tr_known(Side, W).
tr_lexeme0(english, an, a, singular) :- tr_known(english, a).
tr_lexeme0(Side, W, S, plural) :- tr_solve(plural_of(W, S)), tr_known(Side, S).
tr_lexeme0(foreign, W, S, plural) :- tr_rule_stem(W, plural, S), tr_known(foreign, S), tr_rule_plural(S, W).
tr_lexeme0(english, W, S, plural) :- reason_base(W, S), S \== W, tr_known(english, S).
%% AN ELIDED FORM IS ITS OWN WORD: `l'' is `lo' or `la' with the vowel gone,
%% and everything the lesson says of what it elides is true of it. The
%% lesson names the pair (`"l'" is the elision of "lo"'), so a language
%% that elides nothing has no row here and this clause never fires.
tr_lexeme0(foreign, W, S, N) :- tr_solve(elision_of(W, F)), tr_lexeme(foreign, F, S, N).
%% ... AND SO IS A SHORTENED ONE: `cualquier signo' is `cualquiera' before a
%% noun and `mal estado' is `malo' (`"cualquier" is the apocope of
%% "cualquiera".'), which the writer already wrote (tr_apocope/4) and the
%% reader could not read back: `cualquier' was a word nobody knew.
tr_lexeme0(foreign, W, S, N) :- tr_solve(apocope_of(W, F)), tr_lexeme(foreign, F, S, N).
%% ... AND ITS PLURAL IS THE FULL WORD'S: `quei morti' is those dead, and
%% the lesson says `"quei" is the plural of "quel".' of the shortened form
%% the noun follows -- the plural clause above asks the singular to be known,
%% and `quel' is known only as what it shortens
tr_lexeme0(foreign, W, S, plural) :- tr_solve(plural_of(W, A)), tr_solve(apocope_of(A, F)), tr_lexeme(foreign, F, S, singular).

%% A WORD'S LEXEMES ARE ASKED FOR ONCE A SENTENCE. Every reading asks them
%% again -- the group finder of each word, the phrase reader of each run --
%% and a sentence of thirty-five words asked 204 829 times for about sixty
%% words: all of them are kept, in order, the first time a word is asked
%% for under the lesson that is set, and the store is emptied wherever a
%% text or a sentence starts (tr_memo_reset/0), because a program may
%% change its lesson between two calls.
tr_lexeme(Side, W, L, N) :-
    (   atom(W), atom(Side)
    ->  tr_language(Lang), tr_memo(lx(Lang, Side, W), L1-N1, tr_lexeme0(Side, W, L1, N1), Sols),
        member(L-N, Sols)
    ;   tr_lexeme0(Side, W, L, N)
    ).

%% every solution of Goal as Template, kept under Key until the next reset.
%% A KEY'S LAST ARGUMENT IS A WORD, AND EACH WORD HAS A GLOBAL OF ITS OWN.
%% A global is copied every time it is read, so one table for the whole
%% sentence cost 62 us a lookup at five hundred entries -- more than most of
%% what it saved; a word's own table holds a handful and costs about two.
%% A reset is a new GENERATION, and a table stamped with an older one is
%% empty: a list of the tables a sentence touched missed every table that
%% already existed, and a lesson changed between two calls read stale
%% answers -- the case caught it, `what' still known after its line went.
%%
%% THE LIST IS KEPT BEFORE IT IS MATCHED AGAINST SOLS. A caller may pass a
%% pattern -- tr_is/3 asks for `[_|_]', whether there is any solution at
%% all -- and findall/3 straight into the pattern FAILED for a word with no
%% solution, before the list was kept: a class test that answered no was
%% never kept, and most class tests answer no. Over the three longest
%% sentences of Monte Livata, 127 006 of 151 166 class tests were asked
%% again from the lesson.
%%
%% AND A WORD'S TABLE IS A LIST, searched by memberchk/2. get_assoc/3 is
%% clauses -- 23 inferences to find one key among seventeen -- where
%% memberchk/2 is one call into C. Every key is ground (an atom from a
%% global, or the words a caller checked with ground/1), so unifying a key
%% finds exactly what comparing it found.
tr_memo(Key, Template, Goal, Sols) :-
    functor(Key, _, A), arg(A, Key, W),
    atom_concat('$tr_w|', W, G),
    tr_memo_generation(Gen),
    (   catch(nb_getval(G, g(Gen0, M1)), _, fail), Gen0 == Gen -> M0 = M1
    ;   M0 = []
    ),
    (   memberchk(Key-Sols0, M0) -> Sols = Sols0
    ;   findall(Template, Goal, Sols0),
        (   catch(nb_getval(G, g(Gen1, M2)), _, fail), Gen1 == Gen -> M3 = M2
        ;   M3 = []
        ),
        nb_setval(G, g(Gen, [Key-Sols0|M3])),
        Sols = Sols0
    ).

tr_memo_generation(G) :- ( catch(nb_getval('$tr_gen', G0), _, fail) -> G = G0 ; G = 0 ).

tr_memo_reset :- tr_memo_generation(G0), G is G0 + 1, nb_setval('$tr_gen', G).

%% THE FORM IS TAKEN APART, NEVER MATCHED AGAINST EVERY WORD. A rule-made
%% form -- `casas' by `takes "s" in the plural', `comerá' by `takes "rá" in
%% the future' -- used to be found by walking every lexeme of the lesson
%% and inflecting each to see whether it came out as the form: 3 000
%% words of vocabulary made one sentence cost 2.8 s, and the cost grew
%% with the lesson. The endings a rule can add are the few the rules
%% name, so the form loses each of them in turn and the stem left is
%% looked up, which is an indexed call whatever the lesson's size; the
%% rule is then checked of that stem as before.
tr_rule_stem(W, T, S) :- tr_endings(T, Es), member(E, Es), atom_concat(S, E, W), S \== ''.

%% the endings the lesson's rules give for a tense or the plural: the
%% heads of its take_in/3 rules, plain or under the language.
%%
%% THE HEADS ARE ENUMERATED WITH clause/2 AND NOT CALLED, because calling
%% take_in(_, E, T) leaves the FIRST argument unbound -- and an unbound
%% first argument keys 0 and skips nothing, so the call walked the whole
%% predicate. tr_endings/2 is asked on nearly every inflection, so over a
%% vocabulary that one line was the entire cost of a sentence: measured
%% on one language taught under a name, 11.522 s with the call and
%% 0.264 s with clause/2 -- 43x, against a plain lesson's 0.279 s.
%%
%% TWO READINGS DIED GETTING HERE. A blanket reverse index (1.4.1) gave
%% every arity-2 relation a copy keyed the other way and was WORSE on
%% every axis; and the meta-interpreted rules of a named lesson, which
%% looked like the answer because a plain lesson's rules are real
%% clauses, are innocent -- a store whose rules still go through
%% tr_body/2 reads in 0.234 s once this line is fixed. The mechanism was
%% right from the first probe and both fixes built on it were wrong: the
%% answer was to stop asking the unbound question, not to index it.
tr_endings(T, Es) :-
    tr_language(L),
    ( atom(T) -> tr_memo(en(L, T), Es0, tr_endings0(L, T, Es0), [Es1]), Es = Es1 ; tr_endings0(L, T, Es) ).

tr_endings0(L, T, Es) :-
    (   L == none
    ->  findall(E, catch(clause(take_in(_, E, T), _), error(_, _), fail), Es0)
    ;   findall(E, ( tr_solve_plain(lesson(L, (take_in(_, E, T) :- _)))
                     ; tr_namespaced(L, take_in(_, E, T), F), catch(clause(F, _), error(_, _), fail) ), Es0)
    ),
    findall(E, ( member(E, Es0), atom(E) ), Es1), sort(Es1, Es).

tr_digits(W) :- atom(W), atom_codes(W, Cs), Cs \== [], forall(member(C, Cs), ( C >= 0'0, C =< 0'9 )), !.
%% ... and a number as the text wrote it, sign and separators kept
%% (tr_written_number/4): `1.400', `-10', `41,5'
tr_digits(W) :- atom(W), atom_codes(W, Cs), tr_number_run(Cs, Ns, []), Ns == Cs, !.
%% ... and a percentage, the number with its sign: `41,46%', `100%'
tr_digits(W) :- tr_percent(W).
tr_percent(W) :- atom(W), sub_atom(W, B, 1, 0, '%'), B > 0, sub_atom(W, 0, B, 1, N), tr_digits(N).

tr_known(_, W) :- tr_digits(W), !.
tr_known(foreign, W) :- tr_solve(mean(W, _)), !.
tr_known(english, E) :- tr_solve(mean(_, E)), !.

%% a word the lesson knows on a side, in any of its forms: a lexeme, a
%% plural, a verb's form, or one of English's own
tr_known_word(Side, W) :- tr_lexeme(Side, W, _, _), !.
tr_known_word(foreign, W) :- tr_form(W, _, _, _, _), !.
tr_known_word(foreign, W) :- tr_solve(participle_of(W, F)), tr_known(foreign, F), !.       % of a verb of the lesson's
tr_known_word(english, W) :- en_verb_form(W, _, _), !.
tr_known_word(english, W) :- en_participle(W, _), !.
tr_known_word(english, W) :- en_gerund(W, _), !.
tr_known_word(english, W) :- ( en_subject(W, _, _) ; en_object(W) ; en_possessive(W) ; en_copula(W, _, _, _) ), !.
tr_known_word(english, W) :- ( en_det(W, _, _) ; en_tonic(W, _) ; en_modal_form(W, _, _) ), !.
tr_known_word(english, whom) :- tr_known(english, who), !.
tr_known_word(foreign, W) :- tr_solve(contraction_of(W, _)), !.
tr_known_word(foreign, W) :- tr_solve(elision_of(W, F)), tr_known_word(foreign, F), !.
tr_known_word(foreign, W) :- ( tr_solve(infinitive_of(W, F)) ; tr_solve(gerund_of(W, F)) ), tr_known(foreign, F), !.
tr_known_word(foreign, W) :- tr_solve(imperative_of(W, F)), tr_imperative_known(F), !.       % `Comed el pan.'

%% ... every reading of a form, kept once a sentence: 23 915 calls over one
%% sentence of thirty-five words before it was
tr_form(W, L, N, T, P) :-
    (   atom(W)
    ->  tr_language(Lang), tr_memo(fm(Lang, W), f(L1, N1, T1, P1), tr_form0(W, L1, N1, T1, P1), Sols),
        member(f(L, N, T, P), Sols)
    ;   tr_form0(W, L, N, T, P)
    ).

%% a verb form of the lesson's language, taken apart: the lexeme, the
%% number, the tense, the person. A person form the lesson stated first
%% (`"como" is the first person of "come"'); a third person is a present
%% form, singular or plural, or the past or the future of one, or a stated
%% plural of such a tense form
tr_form0(W, L, N, T, P) :-
    tr_solve(person_of(W, F)), ( tr_solve(first(W)) -> P = first ; tr_solve(second(W)) -> P = second ),
    tr_form_nt(F, L, N, T).
tr_form0(W, L, N, T, third) :- tr_form_nt(W, L, N, T).

%% A TENSE STEP CAN COME BACK TO WHERE IT STARTED, so the forms already
%% stepped through are carried and never stepped through twice. `parar' has
%% the indicative `para' and the subjunctive `pare'; `parir' has the
%% indicative `pare' and the subjunctive `para'. BOTH ROWS ARE TRUE and
%% together they are a two-cycle, which tr_tensed(W, present, F) -- the
%% subjunctive step of 1.6.8 -- walked for ever: `Mira para otro lado.' never
%% finished where its four neighbours cost 0.1 to 0.3 s. The FIRST solution
%% was always instant, so only a caller that asks for all of them saw it.
tr_form_nt(W, L, N, T) :- tr_form_nt(W, L, N, T, [W]).

tr_form_nt(W, W, singular, present, _) :- tr_known(foreign, W).
tr_form_nt(W, L, plural, present, _) :- tr_lexeme(foreign, W, L, plural).
tr_form_nt(W, L, N, T, Seen) :-
    tr_tensed(W, T, F), \+ memberchk(F, Seen),
    tr_form_nt(F, L, N, present, [F|Seen]).
tr_form_nt(W, L, plural, T, Seen) :-
    tr_solve(plural_of(W, F)), tr_tensed(F, T, F0), \+ memberchk(F0, Seen),
    tr_form_nt(F0, L, singular, present, [F0|Seen]).

%% a tense form of a present form: stated, or made by an ending rule
tr_tensed(W, past, F) :- tr_solve(past_of(W, F)).
tr_tensed(W, future, F) :- tr_solve(future_of(W, F)).
tr_tensed(W, conditional, F) :- tr_solve(conditional_of(W, F)).
%% A SUBJUNCTIVE IS READ AS THE TENSE IT STANDS FOR AND WRITTEN BACK AS
%% THE INDICATIVE. English marks no subjunctive where `che il militare
%% volesse' wants one, and nothing a lesson says tells which verbs take one
%% -- so the mood is read and dropped, and `volesse' comes back `voleva'.
%% The cost is stated in the header; the alternative is refusing the clause.
tr_tensed(W, present, F) :- tr_solve(subjunctive_of(W, F)), \+ tr_holds(past(W)).
tr_tensed(W, past, F) :- tr_solve(subjunctive_of(W, F)), tr_holds(past(W)).
tr_tensed(W, T, F) :- ( T = past ; T = future ; T = conditional ), tr_rule_stem(W, T, F), tr_present_form(F), tr_solve(take_in(F, E, T)), atom(E), atom_concat(F, E, W).

%% a present form of one of the lesson's verbs, in either number, for a
%% rule to have made a tense of: the lexeme, or a plural of one
tr_present_form(F) :- tr_known(foreign, F), tr_verb_lexeme(F), !.
tr_present_form(F) :- tr_lexeme(foreign, F, S, plural), tr_verb_lexeme(S), !.

tr_rule_plural(S, P) :- tr_solve(take_in(S, E, plural)), atom(E), atom_concat(S, E, P).

%% a form of the lesson's language MADE: the number, the tense, the person
%% -- number then tense (`comieron' is the past of `comen'), or tense then
%% number (`comerán' is the plural of `comerá'), whichever the lesson
%% states; a person the lesson gave no form for is the third's
tr_make(L, N, T, P, Form) :-
    (   tr_number_form(L, N, F1), tr_tense_form(F1, T, F2)
    ;   T \== present, tr_tense_form(L, T, F1), tr_number_form(F1, N, F2)
    ),
    tr_person_form(F2, P, Form), !.

tr_number_form(F, singular, F).
%% A VERB'S PLURAL IS NEVER A PERSON OF THE SAME FORM. `cuenta' is a noun
%% (an account) and a verb, the lesson states the noun's plural first, and
%% `raccontano' came out `cuentas' -- which is the noun's plural and the
%% verb's own second person. The verb's plural is asked for first among the
%% forms that are no person of it, and any stated plural after that.
tr_number_form(F, plural, P) :- tr_solve(plural_of(P, F)), \+ tr_solve(person_of(P, F)), !.
tr_number_form(F, plural, P) :- tr_solve(plural_of(P, F)), !.
tr_number_form(F, plural, P) :- tr_rule_plural(F, P).

tr_tense_form(F, present, F) :- !.
tr_tense_form(F, past, P) :- tr_solve(past_of(P, F)), !.
tr_tense_form(F, future, P) :- tr_solve(future_of(P, F)), !.
tr_tense_form(F, conditional, P) :- tr_solve(conditional_of(P, F)), !.
tr_tense_form(F, T, P) :- tr_solve(take_in(F, E, T)), atom(E), atom_concat(F, E, P), !.

tr_person_form(F, third, F) :- !.
tr_person_form(F, P, Form) :- tr_solve(person_of(Form, F)), G =.. [P, Form], tr_solve(G), !.
tr_person_form(F, _, F).

%% a form in a number: the singular as it is; a plural the lesson stated
%% first, then in the lesson's language the singular with the ending its
%% rule gives, and in English a noun by -s, -es or -ies and anything else
%% unchanged. No rule, no plural: the sentence is refused.
tr_inflect(_, _, S, singular, S) :- !.
%% a plural the lesson stated -- but not, in English, of a word that is the
%% LESSON's too: `"redes" is the plural of "red"' is about the Spanish net,
%% and English's red is red in the plural
%% -- nor of any FORM of the lesson's: `"casen" is the plural of "case"' is
%% Spanish's subjunctive, and English's other cases came out `casen'
tr_inflect(To, _, S, plural, P) :-
    tr_solve(plural_of(P0, S)), \+ ( To == english, ( tr_known(foreign, S) ; tr_stated_word(S) ) ), !, P = P0.
tr_inflect(foreign, _, S, plural, P) :- !, tr_rule_plural(S, P).
%% -- and a noun of several words with `of' in it takes the ending on the
%% word before `of': `todos los puntos de vista' is all the points of view,
%% where the ending went last, `point of views'
tr_inflect(english, noun, S, plural, P) :-
    sub_atom(S, B, _, A, ' of '), B > 0, !,
    sub_atom(S, 0, B, _, H), sub_atom(S, _, A, 0, T),
    reason_third(H, HP), atomic_list_concat([HP, ' of ', T], P).
tr_inflect(english, noun, S, plural, P) :- !, reason_third(S, P).
tr_inflect(english, _, S, plural, S).

%% ---- English's verb forms ---------------------------------------------------------

%% a verb form of English: the third person the lesson gave, the base form
%% whose third person it gave, a past the lesson stated or -ed makes, and
%% the copula's own; a participle stated, `been', or a regular past
en_verb_form(be, is, present) :- !.
en_verb_form(W, W, present) :- tr_known(english, W), tr_class(english, W, verb).
en_verb_form(W, L, present) :- \+ en_own(W), reason_third(W, L), W \== L, tr_known(english, L), tr_class(english, L, verb).
en_verb_form(W, is, T) :- en_copula(W, _, _, T).
en_verb_form(W, L, past) :- \+ en_own(W), en_past_form(W, L).

%% one of English's own words is never a verb form, whatever the inflector
%% makes of it: `I' is not the base of `is'. `have', `do' and `did' are
%% not here: they are the bases and the past of verbs a lesson may give
en_own(W) :-
    (   en_subject(W, _, _) ; en_object(W) ; en_possessive(W) ; en_preposition(W) ; en_question(W, _)
    ;   en_det(W, _, _) ; en_tonic(W, _) ; en_modal_form(W, _, _)
    ;   memberchk(W, [and, not, will, would, am, are, was, were, be, been, being, a, an, the, there, cannot])
    ), !.

en_past_form(had, has).
en_past_form(W, L) :- tr_solve(past_of(W, L)), tr_known(english, L).
en_past_form(W, L) :- tr_english_ed_base(W, B), reason_third(B, L), tr_known(english, L), tr_class(english, L, verb).

en_participle(been, is).
en_participle(W, L) :- tr_solve(participle_of(W, L)), tr_known(english, L).
en_participle(W, L) :- W \== had, en_past_form(W, L), \+ en_copula(W, _, _, _).

%% a gerund: one the lesson stated (`"running" is the gerund of "runs"'),
%% `being', `having', or -ing taken off -- with the e put back (making),
%% a doubled consonant undoubled (running) or ie for y (lying) -- and the
%% base's third person a verb the lesson gives
en_gerund(W, L) :- tr_solve(gerund_of(W, L0)), tr_known(english, L0), !, L = L0.
en_gerund(being, is) :- !.
en_gerund(having, has) :- !.
en_gerund(W, L) :- \+ en_own(W), tr_english_ing_base(W, B), \+ en_own(B), reason_third(B, L), tr_known(english, L), tr_class(english, L, verb), !.

tr_english_ing_base(W, B) :- atom_concat(B0, ing, W), B0 \== '', tr_english_ing_bases(B0, B).
tr_english_ing_bases(B0, B0).
tr_english_ing_bases(B0, B) :- atom_concat(B0, e, B).
tr_english_ing_bases(B0, B) :- sub_atom(B0, _, 1, 0, C), atom_concat(B, C, B0), sub_atom(B, _, 1, 0, C).   % runn -> run
tr_english_ing_bases(B0, B) :- atom_concat(S, y, B0), atom_concat(S, ie, B).                          % ly -> lie

%% English's modals: the word a lesson gives (`can', `may', `must',
%% `should') and its tenses -- `could' is the past and the conditional of
%% `can', `might' of `may', and `should' is what `must' says in the
%% conditional: `Alguien debería estudiar el fenómeno' is somebody should,
%% where English had no form for it and the sentence was refused; read, a
%% `should' is its own word, and `must' has no past
en_modal_form(can, can, present).      en_modal_form(could, can, past).
en_modal_form(may, may, present).      en_modal_form(might, may, conditional).
en_modal_form(must, must, present).    en_modal_form(should, should, present).
en_modal_out(can, present, can).       en_modal_out(can, past, could).      en_modal_out(can, conditional, could).
en_modal_out(may, present, may).       en_modal_out(may, past, might).      en_modal_out(may, conditional, might).
en_modal_out(must, present, must).     en_modal_out(must, conditional, should).
en_modal_out(should, present, should).

%% English's demonstratives and the determiners a lesson may give a word
%% for, each with its lexeme and its number: `these' is `this' in the
%% plural, `many' is `much', `few' is `little', `other' is `another'; `some'
%% is either. (`few' is `little''s plural because the lessons' `poco' is one
%% determiner in both numbers: `muy pocos elementos' is `very few elements'
%% and `molto pochi elementi', where a `few' of its own came out `poco'.)
en_det(this, this, singular).       en_det(these, this, plural).
en_det(that, that, singular).       en_det(those, that, plural).
en_det(another, another, singular). en_det(other, another, plural).
en_det(much, much, singular).       en_det(many, much, plural).
en_det(little, little, singular).   en_det(few, little, plural).
en_det(each, each, singular).       en_det(every, every, singular).
en_det(several, several, plural).   en_det(both, both, plural).
en_det(some, some, any).            en_det(such, such, any).
en_demonstrative(this). en_demonstrative(that).

%% a determiner in the number of its noun: the word of that number with
%% the same lexeme, the one for either, or the word as it is
en_det_number(T, Number, T1) :-
    (   en_det(T, L, _) -> ( en_det(T1, L, Number) -> true ; en_det(T1, L, any) -> true ; T1 = T )
    ;   T1 = T
    ).

%% the pronouns that stand alone, third person, with their number
en_tonic(this, singular).      en_tonic(that, singular).      en_tonic(these, plural).      en_tonic(those, plural).
en_tonic(something, singular). en_tonic(anything, singular).  en_tonic(everything, singular). en_tonic(nothing, singular).
en_tonic(somebody, singular).  en_tonic(anybody, singular).   en_tonic(nobody, singular).   en_tonic(everybody, singular).
en_tonic(someone, singular).   en_tonic(anyone, singular).    en_tonic(everyone, singular).
en_tonic(all, plural).         en_tonic(another, singular).   en_tonic(both, plural).       en_tonic(many, plural).
en_tonic(few, plural).         en_tonic(several, plural).     en_tonic(none, singular).     en_tonic(others, plural).
en_tonic_plural(this, these).  en_tonic_plural(that, those).

%% walked -> walk, lived -> live, carried -> carry: the bases an -ed form may have
tr_english_ed_base(W, B) :- atom_concat(Stem, ied, W), atom_concat(Stem, y, B).
tr_english_ed_base(W, B) :- atom_concat(Stem, ed, W), ( B = Stem ; atom_concat(Stem, e, B) ).

%% ---- what the lesson says ------------------------------------------------------

%% mean(W, E) read from the side the word is on
tr_meaning(foreign, W, E) :- tr_solve(mean(W, E)).
tr_meaning(english, E, W) :- tr_solve(mean(W, E)).

%% what a word is, asked once a sentence for each word and class (tr_memo/4):
%% 47 806 times over the thirty-five words of one sentence before it was kept
tr_is(Side, X, Class) :-
    (   X = w(W, _), atom(W), atom(Side)
    ->  tr_language(Lang),
        (   atom(Class) -> tr_memo(is(Lang, Side, Class, W), x, tr_is0(Side, w(W, lower), Class), [_|_])
        ;   var(Class) -> tr_memo(is1(Lang, Side, W), C1, tr_is0(Side, w(W, lower), C1), [Class])
        ;   tr_is0(Side, X, Class)
        )
    ;   tr_is0(Side, X, Class)
    ).

%% what a word is: English's own tables first, then its lexeme's class --
%% which the lesson says of its own words, and an English word is what
%% any of its translations is
tr_is0(english, w(W, _), preposition) :- en_preposition(W), !.
tr_is0(english, w(W, _), conjunction) :- W == and, !.

%% A CONJUNCTION THAT JOINS TWO PHRASES COORDINATES THEM: `and', `or',
%% `nor', `but'. The lessons call `que' and `che' conjunctions too -- they
%% mean `that' -- and inside a phrase every test used to be `any
%% conjunction', so `el caldo que el pequeño aprende' split at `que' into two
%% phrases joined by `that'. A relative clause needs that word to be what it
%% is, so a phrase is joined only by a coordinator, known by its English
%% meaning.
tr_coord(_, w(',', _)) :- !.                     % the list comma, however a caller spells its case
tr_coord(english, w(W, _)) :- !, memberchk(W, [and, or, nor, but]).
tr_coord(foreign, w(W, _)) :- tr_coord_word(W), !.

%% A CONJUNCTION DOES NOT INFLECT, so the word itself is asked, and an
%% elided one for what it elides. Through tr_lexeme/4 each test walked the
%% plurals and every ending rule of the lesson: ten thousand tests over a
%% Tatoeba run of four hundred sentences, the largest new cost in it.
tr_coord_word(W) :- tr_solve(conjunction(W)), tr_solve(mean(W, E)), memberchk(E, [and, or, nor, but]), !.
tr_coord_word(W) :- tr_solve(elision_of(W, F)), tr_coord_word(F).

%% a coordinator that denies: `ni', `né'
tr_neither_word(C) :- tr_solve(conjunction(C)), tr_solve(mean(C, E)), memberchk(E, [neither, nor]), !.

%% English joins a denied list with `nor' after its `neither'
tr_nor(co(w(_, C), A, B0), co(w(nor, C), A, B)) :- !, tr_nor(B0, B).
tr_nor(X, X).
tr_is0(english, w(W, _), number) :- en_number(W), !.
%% AN ADVERB, A PREPOSITION AND A CONJUNCTION HAVE NO PLURAL, so the lesson's
%% word is one of them only as ITSELF, or as what it elides -- never as the
%% plural of a word that is one. `The adverb "ora" means "now"' made `ore',
%% the hours, an adverb too, and `sin dalle prime ore' read as `the first
%% ones' and then `now': `desde las primeras ahora'.
tr_is0(foreign, w(W, _), Class) :-
    atom(Class), memberchk(Class, [adverb, preposition, conjunction]), !,
    tr_lexeme(foreign, W, L, singular), tr_class(foreign, L, Class), !.
tr_is0(Side, w(W, _), Class) :- tr_lexeme(Side, W, L, _), tr_class(Side, L, Class), !.
tr_class(_, W, number) :- tr_digits(W), !.
%% A PERCENTAGE IS A NOUN AS WELL: `il restante 41,46% di Chrysler' is the
%% remaining share, an adjective and the thing it describes -- and read as a
%% count with its noun left out, the adjective had nothing to describe and
%% the phrase was refused. Asked for a class it does not name, the number
%% comes first, as it always did.
tr_class(_, W, noun) :- tr_percent(W), !.
tr_class(foreign, W, C) :- tr_class_of(W, C).
tr_class(english, E, C) :- tr_solve(mean(W, E)), tr_class_of(W, C).
tr_class_of(W, C) :-
    member(C, [article, possessive, verb, noun, adjective, pronoun, preposition, adverb, number, conjunction, auxiliary,
               modal, demonstrative, determiner]),
    G =.. [C, W], tr_solve(G).

%% a subject pronoun, with its person and number: English's own, or the
%% lesson's by what it means. English writes `it' and `you' the same as a
%% subject and as an object, so a pronoun of the lesson's that means one
%% of those is a subject only when no other meaning of it is an object's
%% alone (`lo' means `him' and `it': an object, never a subject; `tú'
%% means `you' and may be either) -- and an object only when no other
%% meaning is a subject's alone (`ella' means `she' and `her', and is both)
tr_subject_pronoun(english, W, P, N) :- en_subject(W, P, N).
tr_subject_pronoun(english, W, third, N) :- en_tonic(W, N).
tr_subject_pronoun(foreign, W, P, N) :-
    tr_class_of(W, pronoun), tr_solve(mean(W, E)), en_subject(E, P, N),
    \+ ( en_object(E), tr_solve(mean(W, O)), en_object(O), \+ en_subject(O, _, _) ).
%% a pronoun that stands alone (`esto', `nadie', `estos'): the third person,
%% in the number of its form
tr_subject_pronoun(foreign, W, third, N) :- tr_lexeme(foreign, W, L, N), tr_class_of(L, pronoun), tr_solve(mean(L, E)), en_tonic(E, _).
%% AN IMPERSONAL PRONOUN IS A SUBJECT THAT NAMES NOBODY: `si parla di
%% epurazioni', `se habla de purgas' -- the sentence says that purges are
%% spoken of and never who speaks. The lesson says which word it is (`The
%% impersonal pronoun "si" means "one"'), so the construction travels as
%% data; English has no clitic and writes `one'.
%%
%% A THIRD PERSON SINGULAR WITH NO SUBJECT IS STILL REFUSED, which is the
%% rule this sits beside rather than against: `Estaba cansado' could be
%% anybody, and nothing in it says otherwise. The impersonal word IS that
%% something, which is why the shape reads only with it there.
tr_impersonal(foreign, W) :- tr_lexeme(foreign, W, L, _), tr_class_of(L, pronoun), tr_solve(impersonal(L)), !.
tr_impersonal(english, one).

tr_object_pronoun(english, W, W) :- en_object(W).
tr_object_pronoun(english, W, W) :- en_tonic(W, _).
tr_object_pronoun(foreign, W, E) :-
    tr_class_of(W, pronoun), tr_solve(mean(W, E)), en_object(E),
    \+ ( en_subject(E, _, _), tr_solve(mean(W, S)), en_subject(S, _, _), \+ en_object(S) ).
tr_object_pronoun(foreign, W, E) :- tr_lexeme(foreign, W, L, _), tr_class_of(L, pronoun), tr_solve(mean(L, E)), en_tonic(E, _).
%% A REFLEXIVE THAT STANDS AFTER ITS PREPOSITION IS AN OBJECT PRONOUN TOO:
%% `davanti a sé' is in front of oneself, and read as a noun `itself' the
%% phrase after it ended nowhere, so `non si ha davanti a sé nessun altra
%% scelta' was refused where the same words at the end read. Only one the
%% lesson says does not precede the verb: the clitic `si' is the verb's own
%% (reflexive/1, impersonal/1) and is never an object here.
tr_object_pronoun(foreign, W, E) :-
    tr_class_of(W, pronoun), tr_solve(neg(precede(W, verb))), tr_solve(mean(W, E)), en_reflexive(E).
%% AN ELIDED FORM IS THE WORD IT ELIDES. `La sinistra L'ha attaccata' is
%% `la ha attaccata', and the clitic was read as no pronoun at all, because
%% the clauses above ask tr_class_of/2 of the WORD and an elision has no
%% class of its own -- tr_lexeme/4 reads it, tr_class_of/2 does not.
tr_object_pronoun(foreign, W, E) :-
    tr_solve(elision_of(W, F)), tr_object_pronoun(foreign, F, E).

%% the lesson proved: plain, or under the language it was learned in --
%% its facts, its rules with their bodies, and the library's helpers
tr_solve(G) :- tr_language(L), tr_prove(L, G).
tr_prove(none, G) :- !, tr_solve_plain(G).
tr_prove(L, G) :- tr_lesson(L, G).

tr_lesson(_, G) :- tr_helper(G), !, tr_solve_plain(G).
%% A NUMBER IN DIGITS IS A NUMBER to the lesson's rules as well: `Every
%% number is masculine.' is how a lesson says `il 4%' and `el 2001', and a
%% number written in digits is no word a lesson could have called one. With
%% no gender at all `el 1,4%' went out as `la 1,4%' and `en el 2001' as
%% `nella 2001', the first article the lesson gives for `the'.
tr_lesson(_, number(W)) :- atom(W), tr_digits(W), !.
%% -- AND ONLY A PREDICATE THE LESSON STATED IS CALLED. A relation of which
%% a language states no fact -- no Spanish fact is a `particle_of' or an
%% `elision_of' -- raised `existence_error' the first time a process asked
%% it, and the engine WARMS the whole store before it throws, so another
%% process's declaration is found: 0.8 s on a 352 MB store, once a name,
%% two or three names in every process. The registry learning writes
%% (lesson_predicate/3, declared here, so asking it never raises) says
%% which names the lesson has -- asked as a condition, because a cut here
%% would shut out the rules below: `precede' has facts AND `Every pronoun
%% precedes the verb', and behind a cut `no lo vio' came out `no vio lo'.
tr_lesson(L, G) :-
    tr_namespaced(L, G, F), functor(F, N, A),
    ( lesson_predicate(N, L, A) -> tr_solve_plain(F) ).
tr_lesson(L, G) :- tr_solve_plain(lesson(L, (G :- B))), tr_body(L, B).

tr_body(L, (A, B)) :- !, tr_body(L, A), tr_body(L, B).
tr_body(L, \+ G) :- !, \+ tr_body(L, G).
tr_body(_, true) :- !.
tr_body(L, G) :- tr_lesson(L, G).

tr_helper(end_in(_, _)).    tr_helper(end_with(_, _)).
tr_helper(begin_with(_, _)). tr_helper(start_with(_, _)).

%% a lesson that says nothing proves nothing: silence, never an error
tr_solve_plain(Goal) :- catch(Goal, error(existence_error(procedure, _), _), fail).

%% what a rule says, unless the lesson denied it of this word: `Every
%% pronoun precedes the verb. The pronoun "él" does not precede the verb.'
tr_holds(G) :- \+ tr_solve(neg(G)), tr_solve(G).

%% ---- English's own words ----------------------------------------------------------

en_subject(i, first, singular).      en_subject(you, second, singular).
en_subject(he, third, singular).     en_subject(she, third, singular).   en_subject(it, third, singular).
en_subject(we, first, plural).       en_subject(they, third, plural).
en_object(me).  en_object(you). en_object(him). en_object(her). en_object(it). en_object(us). en_object(them).
en_possessive(my). en_possessive(your). en_possessive(his). en_possessive(her). en_possessive(its). en_possessive(our). en_possessive(their).
en_copula(am, first, singular, present).   en_copula(is, third, singular, present).   en_copula(are, second, singular, present).
en_copula(are, third, plural, present).     en_copula(was, third, singular, past).     en_copula(were, third, plural, past).
en_preposition(in).  en_preposition(on).  en_preposition(at).   en_preposition(with).  en_preposition(to).
en_preposition(from). en_preposition(of). en_preposition(for).  en_preposition(by).    en_preposition(under).
en_preposition(over). en_preposition(near). en_preposition(behind). en_preposition(before). en_preposition(after).
en_preposition(into). en_preposition(about). en_preposition(between). en_preposition(without).
en_month(W) :- memberchk(W, [january, february, march, april, may, june, july, august, september, october, november, december]).
en_number(W) :- memberchk(W, [one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve, thirteen, fourteen, fifteen,
                              sixteen, seventeen, eighteen, nineteen, twenty, thirty, forty, fifty, sixty, seventy, eighty, ninety,
                              hundred, thousand, million]).
%% the words no lesson gives and none needs to: they carry a form, not a meaning
en_function(W) :- memberchk(W, [not, does, do, did, will, would, has, have, had, am, are, was, were, be, been, an, there, cannot]).

%% ---- the sentence back as text ---------------------------------------------------

tr_join(To, Kind, Outs0, Stop, Out) :-
    tr_contract(To, Outs0, Outs),
    findall(A, ( member(o(T, C), Outs), tr_word_text(To, T, C, A) ), As0),
    tr_tidy_commas(As0, As1),
    tr_glue(As1, As2), tr_glue_mark(To, As2, As),
    atomic_list_concat(As, ' ', S0),
    tr_cap_head(S0, S1),
    tr_stop_parts(Stop, Before, Inner, StopCode, After),
    atom_codes(S1, Cs), append(Cs, Inner, Cs0),
    %% a sentence that ends in its colon takes no full stop after it: the
    %% text had none, and a piece with no stop is given `.' by tr_upto/4
    ( StopCode == 46, Inner == [], last(Cs, 58) -> Cs1 = Cs0 ; append(Cs0, [StopCode], Cs1) ),     % 58 is `:'
    atom_codes(Out0, Cs1),
    (   To == foreign, Kind == question, once(tr_solve(begin(M, question))), \+ memberchk(o(M, _), Outs) -> atom_concat(M, Out0, Out1)
    %% ... AND AN EXCLAMATION'S, where the lesson has one: `The mark "¡"
    %% begins the exclamation.' -- `Mio dio, che tristezza!' came out with
    %% no opening mark in Spanish
    ;   To == foreign, StopCode == 33, once(tr_solve(begin(M, exclamation))) -> atom_concat(M, Out0, Out1)
    ;   Out1 = Out0
    ),
    %% the marks round a quoted sentence go outside everything, the
    %% question's own opening mark included: `"¿Cómo ...?".'
    atom_codes(Out1, C1), append(Before, C1, C2), append(C2, After, C3), atom_codes(Out, C3).

%% the lesson's opening mark joins the word after it, where a clause after a
%% colon carries one (tr_write/4)
tr_glue_mark(foreign, As0, As) :- once(tr_solve(begin(M, question))), append(Pre, [M, A|Post], As0), !,
    atom_concat(M, A, MA), append(Pre, [MA|Post], As).
tr_glue_mark(_, As, As).

%% a comma at the end, or after another, is dropped: an apposition's closing
%% comma where the sentence ends, or where a clause's comma follows it
tr_tidy_commas([], []).
tr_tidy_commas([',', ','|As], Out) :- !, tr_tidy_commas([','|As], Out).
tr_tidy_commas([','], []) :- !.
tr_tidy_commas([A|As], [A|Out]) :- tr_tidy_commas(As, Out).

%% a comma joins the word before it with no space between
tr_glue(['(', A|Rest], Out) :- !, atom_concat('(', A, A1), tr_glue([A1|Rest], Out).
tr_glue([A, ')'|Rest], Out) :- !, atom_concat(A, ')', A1), tr_glue([A1|Rest], Out).
tr_glue([A, ','|Rest], Out) :- !, atom_concat(A, ',', A1), tr_glue([A1|Rest], Out).
tr_glue([A, ';'|Rest], Out) :- !, atom_concat(A, ';', A1), tr_glue([A1|Rest], Out).
tr_glue([A, ':'|Rest], Out) :- !, atom_concat(A, ':', A1), tr_glue([A1|Rest], Out).
tr_glue([A, '”'|Rest], Out) :- !, atom_concat(A, '”', A1), tr_glue([A1|Rest], Out).
tr_glue([A, '"'|Rest], Out) :- !, atom_concat(A, '"', A1), tr_glue([A1|Rest], Out).
tr_glue([A|As], [A|Out]) :- !, tr_glue(As, Out).
tr_glue([], []).

%% a quoted word gets its marks back: both for one word, the opening one on
%% the head of a run and the closing one on its last word
%% A WORD THE LESSON CALLS AN ACRONYM GOES OUT IN CAPITALS: a lesson keeps
%% every word it quotes in small letters, so `"PIB"' is `pib' to it and `la
%% crescita del suo pil' came out `el crecimiento de su pib'. `"pib" is an
%% acronym.' says it, and the marks and the head's capital apply after.
tr_word_text(foreign, T0, C, A) :- atom(T0), tr_solve(acronym(T0)), !, upcase_atom(T0, T), tr_word_text(none, T, C, A).
tr_word_text(_, T, qboth, A) :- !, atomic_list_concat(['"', T, '"'], A).
tr_word_text(_, T, qopen, A) :- !, atomic_list_concat(['"', T], A).
tr_word_text(_, T, qclose, A) :- !, atomic_list_concat([T, '"'], A).

tr_word_text(english, i, _, 'I') :- !.
tr_word_text(_, T, upper, A) :- !, tr_cap(T, A).
tr_word_text(_, T, _, T).

%% the sentence's first letter up, past a quotation mark that opens it:
%% `"Gli ho dato riposo'
tr_cap_head(S0, S) :-
    atom_codes(S0, Cs0),
    (   Cs0 = [34|Rest] -> atom_codes(R0, Rest), tr_cap(R0, R), atom_concat('"', R, S)
    ;   Cs0 = [226, 128, 156|Rest] -> atom_codes(R0, Rest), tr_cap(R0, R), atom_concat('“', R, S)
    ;   tr_cap(S0, S)
    ).

%% the first letter up: an ASCII one, or one of U+00E0..U+00FE, the two
%% bytes 195 and 160..190 in UTF-8 (`él' is `Él'); the division sign is
%% no letter
tr_cap(W, C) :- atom_codes(W, [195, B|R]), B >= 160, B =< 190, B =\= 183, !, B1 is B - 32, atom_codes(C, [195, B1|R]).
tr_cap(W, C) :- atom_codes(W, [F|R]), ( F >= 97, F =< 122 -> F1 is F - 32 ; F1 = F ), atom_codes(C, [F1|R]).
