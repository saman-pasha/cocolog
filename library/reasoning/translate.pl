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
%% above. What it has NOT is a comparison of two things (`richer THAN
%% Rome'), a `why', any other fragment with no verb, the preposition a verb
%% puts before its infinitive (`propone di punire' comes out `propone
%% punire': nothing a lesson says pairs the two), the imperfect apart from
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
    (   catch(( tr_read_ir(Piece, Stop, From, S), tr_write_ir(Into, S, Stop, Out0) ), _, fail) -> Out = Out0
    ;   atom_codes(A, Piece), reason_untranslated(A, From, Words), Out = refused(Words)
    ).

tr_each_ir([], _, []).
%% a piece with no word in it is no sentence and is passed over, never
%% refused: a stray mark between two stops (`!.') has nothing to translate
tr_each_ir([Piece-_|Ps], From, Ss) :- tr_piece_words(Piece, []), !, tr_each_ir(Ps, From, Ss).
tr_each_ir([Piece-Stop|Ps], From, [ir(S, Stop)|Ss]) :-
    tr_read_ir(Piece, Stop, From, S),
    tr_each_ir(Ps, From, Ss).

tr_read_ir(Piece, Stop, From, S) :-
    tr_piece_words(Piece, Words0), Words0 \== [],
    tr_from_side(From, Words0, Side),
    tr_head_lower(Side, Words0, Words1),
    tr_expand(Side, Words1, Words2),
    tr_multi(Side, Words2, Words),
    tr_kind(Stop, Kind), tr_exclaim(Stop),
    tr_into_ir(Side, Kind, Words, S).

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
    forall(member(T, Links), tr_learn_term(Language, T)).

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
tr_mean_links(Terms, Links) :- tr_mean_links(Terms, none, Links).
tr_mean_links([], _, []).
tr_mean_links([mean(W, E)|Ts], W0-C, [mean_as(W, E, C)|Ls]) :- W == W0, !, tr_mean_links(Ts, W0-C, Ls).
tr_mean_links([T|Ts], _, Ls) :-
    T =.. [C, W], atom(W), tr_link_class(C), !, tr_mean_links(Ts, W-C, Ls).
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
    findall(W, ( member(Piece-_, Pieces), tr_piece_words(Piece, Ws0c),
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
    ( Side == foreign -> tr_multi(foreign, Ws, Ws1) ; Ws1 = Ws ),
    member(w(W, Case), Ws1),
    ( Case \== upper ; en_question(W, _) ),
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
tr_each([Piece-Stop|Ps], Way, [Out|Outs]) :-
    tr_piece_words(Piece, Words0), Words0 \== [],
    tr_way(Way, Words0, From, To),
    tr_head_lower(From, Words0, Words1),
    tr_expand(From, Words1, Words2),
    tr_multi(From, Words2, Words),
    tr_translate(Words, From, To, Stop, Out),
    tr_each(Ps, Way, Outs).

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
tr_expand(foreign, [w(W, C)|Ws], Out) :-
    tr_solve(elision_of(W, F)), tr_solve(contraction_of(F, _)), !,
    tr_expand(foreign, [w(F, C)|Ws], Out).
tr_expand(foreign, [w(W, C)|Ws], Out) :-
    tr_solve(contraction_of(W, J)), atomic_list_concat([P1|Ps], ' ', J), Ps \== [], !,
    findall(w(P, lower), member(P, Ps), Rest), tr_expand(foreign, Ws, Out1),
    append([w(P1, C)|Rest], Out1, Out).
tr_expand(foreign, [W|Ws], [W|Out]) :- tr_expand(foreign, Ws, Out).

%% A WORD OF SEVERAL WORDS IS ONE WORD WHEN THE LESSON KNOWS IT AS ONE:
%% `junto a' (along with), `lavado de cerebro' (brainwashing), `tiene que'
%% (must), `c'è'. A lesson could always STATE one -- `The masculine noun
%% "toque de queda" means "curfew".' -- and the writer wrote it, but the
%% reader cut the text into single words and never put them back together,
%% so a multi-word word was write-only. Adjacent plain words are joined,
%% the LONGEST first (four, three, two), wherever the lesson knows the
%% joined form as a word; after a contraction is expanded, so `junto al'
%% is `junto a' and `el'. A word ending in an apostrophe joins with no space
%% (`c'' and `è' are `c'è'). Only on the lesson's side: English's own
%% multi-word forms (`there is') have readers of their own.
tr_multi(english, Ws, Ws) :- !.
tr_multi(foreign, [], []) :- !.
tr_multi(foreign, Ws0, [w(J, C)|Ws]) :-
    Ws0 = [w(_, C)|_],
    member(N, [4, 3, 2]), length(Ns, N), append(Ns, Rest, Ws0),
    forall(member(X, Ns), ( X = w(_, XC), memberchk(XC, [lower, upper]) )),
    tr_joined(Ns, J), tr_stated_word(J), !,
    tr_multi(foreign, Rest, Ws).
tr_multi(foreign, [W|Ws0], [W|Ws]) :- tr_multi(foreign, Ws0, Ws).

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
tr_contract(foreign, [o(W1, C), o(W2, _)|Os], Out) :-
    atomic_list_concat([W1, W2], ' ', J), tr_solve(contraction_of(K, J)), !,
    tr_contract(foreign, [o(K, C)|Os], Out).
%% AND AN ELIDED FORM IS WRITTEN WHEN A VOWEL FOLLOWS, joined to the word
%% after it: `la incolumita' is `l'incolumita'. It comes AFTER the
%% contraction above, so `di la' is `della' first and `dell'' second --
%% which is why the lesson states the elision of the contracted forms
%% (`"dell'" is the elision of "della"') and not of their parts.
tr_contract(foreign, [o(W1, C), o(W2, _)|Os], Out) :-
    tr_solve(elision_of(E, W1)), begin_with(W2, vowel), !,
    atom_concat(E, W2, J),
    tr_contract(foreign, [o(J, C)|Os], Out).
tr_contract(foreign, [O|Os], [O|Out]) :- tr_contract(foreign, Os, Out).
tr_contract(foreign, [], []).

%% the first word's capital is the sentence's, not the word's: a known
%% word at the head goes lower, so that when a question moves it it is
%% not `Es'; a name keeps its case
tr_head_lower(From, [w(W, upper)|Ws], [w(W, lower)|Ws]) :- ( tr_known_word(From, W) ; en_function(W) ), !.
tr_head_lower(_, Ws, Ws).

%% ---- the sentences, and their words ------------------------------------------

%% the text cut at `.', `!' and `?', each piece with the stop it ended on
%% (`.' when it had none), the blank ones dropped
tr_pieces(Text, Pieces) :- tr_codes(Text, Codes), tr_split(Codes, Pieces0), tr_quote_pieces(Pieces0, Pieces).

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
    tr_stop_parts(Stop, Before, S, After),
    atom_codes(P, Cs), append(Before, Cs, C1), append(C1, [S|After], C2),
    atom_codes(Sentence, C2).

tr_stop_parts(marks(Before, S, After), Before, S, After) :- !.
tr_stop_parts(S, [], S, []).

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
    tr_cut_at(Piece, 59, Parts),                                     % 59 is `;'
    tr_parts_words(Parts, Words).

tr_parts_words([P], Ws) :- !, tr_part_words(P, Ws).
tr_parts_words([P|Ps], Ws) :-
    tr_part_words(P, W1), tr_parts_words(Ps, W2),
    (   W1 == [] -> Ws = W2
    ;   W2 == [] -> Ws = W1
    ;   append(W1, [semicolon|W2], Ws)
    ).

tr_part_words(Codes, Ws) :-
    (   memberchk(0'-, Codes), tr_hyphen_name(Codes, Pre, Name, Post)
    ->  reason_tokens(Pre, T1), tr_words(T1, W1), tr_part_words(Post, W2),
        append(W1, [w(Name, upper)|W2], Ws)
    ;   reason_tokens(Codes, Tokens), tr_words(Tokens, Ws)
    ).

tr_cut_at(Codes, Sep, Parts) :-
    (   append(Before, [Sep|After], Codes) -> Parts = [Before|More], tr_cut_at(After, Sep, More)
    ;   Parts = [Codes]
    ).

%% the first capitalised word with a hyphen between two of its letters
tr_hyphen_name(Codes, Pre, Name, Post) :-
    append(Pre, Rest, Codes),
    ( Pre == [] -> true ; last(Pre, B), \+ tr_letter_code(B) ),
    tr_capital_start(Rest),
    tr_name_codes(Rest, NameCodes, Post),
    memberchk(0'-, NameCodes), !,
    atom_codes(Name, NameCodes).

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
tr_upto([C|Cs], [], C, Cs) :- memberchk(C, [46, 33, 63]), !.            % . ! ?
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
tr_kind(63, question) :- !.                                               % 63 is `?'
tr_kind(_, statement).

%% whether a piece ended on `!': a sentence with no verb reads only then
tr_exclaim(Stop) :- ( ( Stop == 33 ; Stop = marks(_, 33, _) ) -> nb_setval('$tr_exclaim', yes) ; nb_setval('$tr_exclaim', no) ).

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
    tr_list_commas(Side, Words0, Words),
    nb_setval('$tr_piece', Words),
    tr_read(Side, Kind, Words, S0),
    tr_cross(Side, S0, S).

%% out of the IR: the IR's side IS English, so the writer crosses from it
%% -- into the lesson's language as it always did, and into English by
%% the identity above
tr_from_ir(To, Kind, S, Stop, Out) :-
    nb_setval('$tr_from', english),
    tr_write(To, Kind, S, Outs),
    tr_join(To, Kind, Outs, Stop, Out).

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
tr_list_commas(Side, Ws0, Ws) :- tr_list_commas(Side, none, Ws0, Ws).
tr_list_commas(_, _, [], []).
%% A NAME BETWEEN TWO COMMAS AFTER A PHRASE IS AN APPOSITION: `El ministro del
%% Interior francés, Jean-Pierre Chevènement, ha provocado'. The commas and
%% the name travel as ONE word, w(Name, appos), which the phrase before it
%% takes where a name apposed to its noun goes and every writer puts back,
%% commas and all, after the noun.
tr_list_commas(Side, Prev, [comma|Ws0], [w(A, appos)|Ws]) :-
    Prev = w(_, _), tr_list_item(Side, Prev),
    append(Ns, [comma|Rest], Ws0), Ns \== [], forall(member(N, Ns), ( N = w(_, _), tr_name_word(Side, N) )), !,
    findall(C, ( member(w(N, _), Ns), tr_cap(N, C) ), Cs), atomic_list_concat(Cs, ' ', A),
    tr_list_commas(Side, w(A, appos), Rest, Ws).
tr_list_commas(Side, Prev, [comma|Ws0], [X|Ws]) :- !,
    (   Prev = w(_, _), tr_list_item(Side, Prev), tr_list_tail(Side, Ws0) -> X = w(',', lcomma) ; X = comma ),
    tr_list_commas(Side, X, Ws0, Ws).
tr_list_commas(Side, _, [W|Ws0], [W|Ws]) :- tr_list_commas(Side, W, Ws0, Ws).

tr_list_item(Side, W) :- ( tr_is(Side, W, noun) ; tr_is(Side, W, adjective) ), !.

tr_list_tail(Side, Ws) :-
    append(S, [C|Rest0], Ws), S \== [], C = w(_, _), tr_coord(Side, C), forall(member(X, S), tr_list_word(Side, X)), !,
    append(T, Rest, Rest0), T \== [], forall(member(X, T), tr_list_word(Side, X)),
    ( Rest == [] ; Rest = [N|_], \+ tr_list_word(Side, N), \+ ( N = w(_, _), tr_is(Side, N, verb) ) ), !.

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
tr_cross(Side, join(C0, A0, B0), join(C, A, B)) :- !,
    tr_cross_connector(Side, C0, C), tr_cross(Side, A0, A), tr_cross(Side, B0, B).
tr_cross(english, S0, S) :- !, tr_cross_which(S0, S).
tr_cross(foreign, s(Asked0, Subject0, g(L0, T, A, Neg), Comps0), s(Asked, Subject, g(L, T, A, Neg), Comps)) :-
    tr_lexeme_across(L0, english, L),
    tr_cross_asked(Asked0, Asked),
    tr_cross_subject(Asked, Subject0, Subject),
    tr_cross_comps(Comps0, Comps).

%% the connector of a join, across: a comma as itself, a word by its meaning
tr_cross_connector(_, comma, comma) :- !.
tr_cross_connector(_, w(',', lcomma), w(',', lcomma)) :- !.
tr_cross_connector(_, semicolon, semicolon) :- !.
tr_cross_connector(Side, w(W, C), w(T, C)) :-
    ( Side == english -> T = W ; tr_lexeme(foreign, W, L, _), tr_meanings_of(L, english, conjunction, [T|_]) ), !.

%% the English side crosses nothing, and normalises one thing: a `which'
%% question carries the words of its phrase, and the IR carries the phrase
tr_cross_which(s(Asked0, Subject0, G, Comps), s(Asked, Subject, G, Comps)) :-
    tr_cross_which_asked(Asked0, Asked),
    (   Subject0 = asked(_), Asked = subject(Q) -> Subject = asked(Q)
    ;   Subject = Subject0
    ).

tr_cross_which_asked(none, none) :- !.
tr_cross_which_asked(A0, A) :- A0 =.. [Kind, which(Ws, C)], !, tr_np(english, Ws, NP), A =.. [Kind, which_np(NP, C)].
tr_cross_which_asked(A, A).

%% what is asked, across: the question word by what it asks for, or the
%% phrase of a `which' read and crossed
tr_cross_asked(none, none) :- !.
tr_cross_asked(A0, A) :- A0 =.. [Kind, Q0], tr_cross_q(Kind, Q0, Q), A =.. [Kind, Q].

tr_cross_q(_, which(Ws, C), which_np(NP, C)) :- !, tr_side_here(Side), tr_np(Side, Ws, NP0), tr_cross_np(NP0, NP).
tr_cross_q(Kind, w(Q, C), w(QT, C)) :- tr_question_across(english, Kind, Q, QT).

%% the subject, across: the question word when the subject is what is
%% asked (already crossed), `there' as itself, a name as itself, and the
%% person and number of a pronoun or of nobody kept as they were read
tr_cross_subject(subject(Q), asked(_), asked(Q)) :- !.
tr_cross_subject(_, none, none) :- !.
tr_cross_subject(_, gap, gap) :- !.
tr_cross_subject(_, there, there) :- !.
tr_cross_subject(_, name(W), name(W)) :- !.
tr_cross_subject(_, null(P, N), null(P, N)) :- !.
tr_cross_subject(_, impersonal, impersonal) :- !.
tr_cross_subject(_, pronoun(P, N, w(W, C)), pronoun(P, N, w(T, C))) :- !, tr_pronoun_across(english, subject, w(W, C), P, N, T).
tr_cross_subject(A, co(C0, S1, S2), co(C, T1, T2)) :- !,
    tr_side_here(Side), tr_cross_connector(Side, C0, C), tr_cross_subject(A, S1, T1), tr_cross_subject(A, S2, T2).
tr_cross_subject(_, with(NP0, PPs0), with(NP, PPs)) :- !, tr_cross_np(NP0, NP), tr_cross_comps(PPs0, PPs).
tr_cross_subject(_, NP0, NP) :- tr_cross_np(NP0, NP).

%% a phrase, across: the noun's lexeme in English, the determiner as the
%% word of its kind (never the form -- the number inflects it on the way
%% out), a number word, and each adjective's first meaning
tr_cross_np(rc(NP0, Role0, S0), rc(NP, Role, S)) :- !,
    tr_cross_np(NP0, NP), tr_side_here(Side),
    (   Role0 = pp(w(P, C)) -> tr_word_across(w(P, lower), english, preposition, PT), Role = pp(w(PT, C))
    ;   Role = Role0
    ),
    tr_cross(Side, S0, S).
tr_cross_np(rel(NP0, L0, Cs0), rel(NP, L, Cs)) :- !,
    tr_cross_np(NP0, NP), tr_lexeme_across(L0, english, L), tr_cross_comps(Cs0, Cs).
tr_cross_np(adv(w(A, C)), adv(w(AT, C))) :- !, tr_word_across(w(A, lower), english, adverb, AT).
tr_cross_np(name(W), name(W)) :- !.
tr_cross_np(np(Det0, Num0, Adjs0, elided(G), Number), np(Det, Num, Adjs, elided(G), Number)) :- !,
    tr_cross_det(Det0, Det), tr_cross_num(Num0, Num), tr_cross_adjectives(Adjs0, Adjs).
tr_cross_np(ell(Det0, G, Number, PP0), ell(Det, G, Number, PP)) :- !,
    tr_cross_det(Det0, Det), tr_cross_comp(PP0, PP).
tr_cross_np(pronoun(w(W, C)), pronoun(w(T, C))) :- !, tr_pronoun_across(english, oblique, w(W, C), _, _, T).
tr_cross_np(co(C0, N1, N2), co(C, T1, T2)) :- !,
    tr_side_here(Side), tr_cross_connector(Side, C0, C), tr_cross_np(N1, T1), tr_cross_np(N2, T2).
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
tr_cross_det(det(Kind, DL, w(_, C)), det(Kind, T, w(T, C))) :- tr_word_across(w(DL, lower), english, Kind, T).

tr_cross_num(none, none) :- !.
tr_cross_num(w(MW, MC), w(MT, MC)) :- tr_word_across(w(MW, MC), english, number, MT).

tr_cross_adjectives([], []).
tr_cross_adjectives([A0|As0], [A|As]) :- tr_cross_adjective(A0, A), tr_cross_adjectives(As0, As).

tr_cross_adjective(deg(D, A0), deg(D, A)) :- !, tr_cross_adjective(A0, A).
tr_cross_adjective(pre(A0), pre(A)) :- !, tr_cross_adjective(A0, A).
tr_cross_adjective(w(W, appos), w(W, appos)) :- !.
tr_cross_adjective(int(w(A0, C), J0), int(w(A, C), J)) :- !,
    tr_word_across(w(A0, lower), english, adverb, A), tr_cross_adjective(J0, J).
tr_cross_adjective(w(W, C), T) :- tr_side_here(Side), tr_coord(Side, w(W, C)), !, tr_cross_connector(Side, w(W, C), T).
%% A NAME APPOSED TO A NOUN CROSSES AS ITSELF -- `il presidente Scalfaro' --
%% which is what being a name means, and without it the phrase read and the
%% crossing failed, so the sentence was refused with no shape missing.
tr_cross_adjective(w(W, upper), w(W, upper)) :- tr_side_here(Side), \+ tr_known_word(Side, W), !.
tr_cross_adjective(w(W, C), w(T, C)) :- tr_lexeme_here(W, WL), tr_meanings_of(WL, english, adjective, [T|_]).

%% the complements, across, each in its place
tr_cross_comps([], []).
tr_cross_comps([C0|Cs0], [C|Cs]) :- tr_cross_comp(C0, C), tr_cross_comps(Cs0, Cs).

tr_cross_comp(fr(C0), fr(C)) :- !, tr_cross_comp(C0, C).
tr_cross_comp(sep, sep) :- !.
tr_cross_comp(obj(NP0), obj(NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_comp(adj(Ws0), adj(Ws)) :- !, tr_cross_adjectives(Ws0, Ws).
tr_cross_comp(oc(NP0, Ws0), oc(NP, Ws)) :- !, tr_cross_np(NP0, NP), tr_cross_adjectives(Ws0, Ws).
tr_cross_comp(that(S0), that(S)) :- !, tr_side_here(Side), tr_cross(Side, S0, S).
tr_cross_comp(pp(w(P, C), NP0), pp(w(PT, C), NP)) :- !, tr_word_across(w(P, lower), english, preposition, PT), tr_cross_np(NP0, NP).
tr_cross_comp(adv(w(A, C)), adv(w(AT, C))) :- !, tr_word_across(w(A, lower), english, adverb, AT).
tr_cross_comp(purpose(L), purpose(LT)) :- !, tr_lexeme_across(L, english, LT).
tr_cross_comp(ger(L, Cs0), ger(LT, Cs)) :- !, tr_lexeme_across(L, english, LT), tr_cross_comps(Cs0, Cs).
tr_cross_comp(upon(L, Cs0), upon(LT, Cs)) :- !, tr_lexeme_across(L, english, LT), tr_cross_comps(Cs0, Cs).
tr_cross_comp(inf(L), inf(LT)) :- !, tr_lexeme_across(L, english, LT).
tr_cross_comp(pred(L), pred(LT)) :- !, tr_lexeme_across(L, english, LT).
tr_cross_comp(at_time(NP0), at_time(NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_comp(cnj(w(C, CC)), cnj(w(CT, CC))) :- !, tr_cross_connector(foreign, w(C, CC), w(CT, CC)).
tr_cross_comp(by(NP0), by(NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_comp(opron(w(W, C)), opron(w(T, C))) :- tr_pronoun_across(english, object, w(W, C), _, _, T).

%% ---- reading: a question into the statement's order -------------------------------

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
%% A SEMICOLON DIVIDES FIRST. Every other reading below is tried on the
%% whole piece before a division is looked for, which is right for a comma
%% -- a comma is often inside a clause -- and wasted on a semicolon, which
%% never is: measured, one 40-word sentence with a `;' in it spent 185 s
%% refusing itself in whole-sentence readings before the split was tried.
tr_read(Side, Kind, Words0, S) :-
    memberchk(semicolon, Words0),
    append(Left0, [semicolon|Right0], Words0),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right),
    tr_read(Side, Kind, Left, S1), tr_read(Side, statement, Right, S2), !,
    S = join(semicolon, S1, S2).
%% A STATEMENT IS READ FIRST WITH ITS COMMAS, and a comma after the verb
%% group is a complement of its own, sep, which every writer puts back:
%% `Il generale definisce la casa, escludendo che il paese domina' keeps
%% the comma before its gerund. The subject side is read with the commas
%% taken out, as before; and when this reading fails the one below, with
%% every comma taken out, is the one the reader always had.
tr_read(Side, statement, Words0, S) :-
    memberchk(comma, Words0), Words0 = [W0|_], W0 \== comma,
    tr_read_statement(Side, Words0, none, S), !.
tr_read(Side, Kind, Words0, S) :-
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
tr_read(Side, Kind, Words0, S) :-
    tr_uncomma(Words0, Plain),
    tr_normalise(Side, Kind, Plain, Words, Asked),
    \+ ( Kind == statement, Words0 = [_, comma|_] ),       % `Cucharada a cucharada, el chaval ...' is a punctuated front
    tr_adverbs_off(Side, Words, Rest, Advs), Advs \== [],
    tr_read_statement(Side, Rest, Asked, S0), S0 = s(A, Su, G, Comps0), !,
    append(Comps0, Advs, Comps),
    S = s(A, Su, G, Comps).
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
tr_read(Side, statement, Words0, S) :-
    Words0 = [W0|_], W0 \== comma,
    length(Words0, Len), Max is Len - 1, Max >= 1,
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    between(1, Max, Back), K is Max + 1 - Back, length(Front0, K), append(Front0, Rest0, Words0),
    \+ last(Front0, comma), Rest0 \== [], Rest0 \= [comma],
    tr_complements(Side, Front0, Front), Front \== [],
    forall(member(X, Front), tr_adjunct(X)),
    %% THE REST IS READ WITH ITS COMMAS FIRST, as a statement is: `... la
    %% tesi di una leggerezza, escludendo che ...' read without them made the
    %% gerund a complement of the clause and the comma was lost
    (   Rest0 \= [comma|_], memberchk(comma, Rest0), tr_read_statement(Side, Rest0, none, S0)
    ->  true
    ;   tr_uncomma(Rest0, Rest), Rest \== [],
        tr_read_statement(Side, Rest, none, S0)
    ),
    S0 = s(A, Su, G, Comps0), !,
    (   ( memberchk(comma, Front0) ; Rest0 = [comma|_] )
    ->  findall(fr(X), member(X, Front), Fr), append(Fr, Comps0, Comps)
    ;   tr_front_after(Comps0, Front, Comps)
    ),
    S = s(A, Su, G, Comps).

%% a front with no comma goes after the clause's own complements -- and
%% before the first comma among them, which is where the clause ended
tr_front_after(Comps0, Front, Comps) :-
    append(A, [sep|B], Comps0), !, append(A, Front, AF), append(AF, [sep|B], Comps).
tr_front_after(Comps0, Front, Comps) :- append(Comps0, Front, Comps).
tr_read(Side, question, Words0, S) :-
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
tr_read(Side, Kind, Words0, S) :-
    tr_clause_split(Side, Words0, Left, Conn, Right),
    tr_read(Side, Kind, Left, S1),
    tr_read(Side, statement, Right, S2), !,
    S = join(Conn, S1, S2).
%% A CONNECTOR AT THE HEAD JOINS THIS SENTENCE TO THE ONE BEFORE IT.
%% `Ma gia si parla di epurazioni' -- newspaper prose opens a sentence with
%% `Ma', `E', `Perche', and tr_clause_split/5 finds no left clause for it
%% because there is none IN THE SENTENCE. It is the same join with nothing
%% on its left, so the IR is join(Conn, none, S) and every writer puts the
%% connector first. What is lost is nothing: the connector is written back
%% where it stood.
tr_read(Side, Kind, Words0, S) :-
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
tr_read(Side, _, Words0, gap(Front, Back)) :-
    Words0 \== [],
    %% and one word of it at least is the lesson's: `¡Lárgate!' is a verb
    %% with its pronoun joined on, which no lesson here can say, and read as
    %% no verb at all it passed through untranslated as a name
    once(( member(w(KW, _), Words0), tr_known_word(Side, KW) )),
    \+ ( tr_uncomma(Words0, Plain), tr_group_from(Side, Plain, _, _, _) ),
    nb_setval('$tr_read_aspect', simple), nb_setval('$tr_read_group', none),
    (   append(F0, [comma|B0], Words0), \+ memberchk(comma, F0), F0 \== [], B0 \== []
    ->  tr_uncomma(F0, F), tr_uncomma(B0, B),
        tr_complements(Side, F, Front), tr_complements(Side, B, Back)
    ;   tr_global('$tr_piece', Piece), Piece == Words0, tr_global('$tr_exclaim', yes),
        Front = [], tr_uncomma(Words0, W), tr_complements(Side, W, Back)
    ), Back \== [], !.

%% every selection of the adverb words, KEEPING each one before lifting it
%% -- so the first solution lifts nothing (which the caller rejects) and
%% the ones after it lift as few as the reading needs.
tr_adverbs_off(_, [], [], []).
tr_adverbs_off(Side, [W|Ws], [W|Rest], Advs) :- tr_adverbs_off(Side, Ws, Rest, Advs).
tr_adverbs_off(Side, [W|Ws], Rest, [adv(W)|Advs]) :-
    tr_is(Side, W, adverb), tr_adverbs_off(Side, Ws, Rest, Advs).

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
tr_clause_split(Side, Words, Left, w(C, CC), Right) :-
    append(Left0, [w(C, CC)|Right0], Words),
    tr_connector(Side, C),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right).
tr_clause_split(_, Words, Left, comma, Right) :-
    append(Left0, [comma|Right0], Words),
    tr_clause_words(Left0, Left), tr_clause_words(Right0, Right).

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
fo_question_word([w(Q, C)|Ws], Words, Asked) :-
    tr_solve(mean(Q, E0)), en_question(E0, _), !,
    (   tr_solve(mean(Q, which)), Ws = [W1|_], fo_phrase_word(W1)
    ->  fo_np_words(Ws, NP, Rest),
        tr_group(foreign, Rest, [], _, _, After),
        (   fo_lone_subject(After) -> Asked = object(which(NP, C)) ; Asked = subject(which(NP, C)) ),
        Words = Rest
    ;   tr_solve(mean(Q, E)), en_question(E, Kind), Kind \== which, !,
        Asked =.. [Kind, w(Q, C)], Words = Ws
    ).
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

%% a phrase's number, through a reduced relative to the phrase it sits on --
%% `il coprifuoco imposto dai soldati' is singular, and without this clause
%% a rel/3 matched no np/5 and an inverted subject with a participle after
%% it was refused
fo_np_number(rel(NP, _, _), N) :- !, fo_np_number(NP, N).
fo_np_number(np(_, _, _, _, N), N).

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

fo_phrase_starts(w(W, upper)) :- \+ tr_known_word(foreign, W), !.
fo_phrase_starts(R) :- ( tr_determiner(foreign, R, _, _) ; tr_is(foreign, R, preposition) ; tr_subject_pronoun(foreign, R, _, _) ), !.

%% ---- reading: the statement -------------------------------------------------------

%% s(Asked, Subject, Group, Complements): the denial off, the verb group
%% found, the subject before it (with the object pronouns that stand
%% before the verb taken out), the complements after it
%% `there is': no subject of its own, and what there is as its first object
%% -- English's `there' and the copula, or `there will be'; the lesson's
%% verb that means `there is' (`hay'), which the question form may have
%% put after its phrase (`¿Hay un perro?' reads as `un perro hay')
tr_read_statement(Side, Words0, none, S) :-
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
tr_read_statement(Side, Words0, Asked, S) :-
    tr_negation(Side, Words0, Words, Neg),
    tr_group_from(Side, Words, Before, g(L, T, A, FP, FN), After),
    nb_setval('$tr_read_group', L),                           % for the complements: a bare base after a modal
    nb_setval('$tr_read_aspect', A),                          % and: a `by' phrase after a passive is its agent
    tr_uncomma(Before, BeforeU),                              % the subject side is read without its commas
    tr_split_clitics(Side, BeforeU, Asked, FP, FN, SubjectWords, Clitics0),
    tr_reflexive_off(Side, Clitics0, Clitics, L, LV),
    tr_subject(Side, Asked, SubjectWords, FP, FN, Subject0),
    %% A VERB THE LESSON CALLS REFLEXIVE TAKES `se' AS ITS OWN PRONOUN, never
    %% as the impersonal subject: `Se ha equivocado' is somebody erring, and
    %% `"equivoca" is reflexive.' says so; the subject is the one nobody named
    (   Subject0 == impersonal, LV == L, tr_solve(reflexive(L)), tr_reflexive_out(_)
    ->  Subject = null(FP, FN), LV1 = reflexive(L)
    ;   Subject = Subject0, LV1 = LV
    ),
    tr_complements(Side, After, Comps0), !,                   % the cut once the WHOLE statement read: `house'
                                                              % is a verb's form, and `The house is big' must
                                                              % go on to the group at `is' when `is big' is no complement
    findall(opron(W), member(W, Clitics), Cs),
    append(Cs, Comps0, Comps),
    tr_existential_fix(Side, s(Asked, Subject, g(LV1, T, A, Neg), Comps), S).
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
tr_read_statement(foreign, Words0, Asked, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    tr_group_from(foreign, Words, Before, g(L, T, A, FP, FN), After),
    Before \== [],
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', A),
    tr_solve(intransitive(L)),
    tr_complements(foreign, Before, Front),
    Front \== [], forall(member(X, Front), tr_adjunct(X)),
    tr_uncomma(After, AfterU),
    fo_subject_after(AfterU, FP, FN, SubjWords, Rest), SubjWords \== [],
    tr_subject(foreign, Asked, SubjWords, FP, FN, Subject),
    tr_complements(foreign, Rest, Back), !,
    append(Front, Back, Comps),
    S = s(Asked, Subject, g(L, T, A, Neg), Comps).

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
%%
%% THE COPULA IS WRITTEN BACK. A headline read this way comes out as the
%% full sentence in every language -- `La casa e stata evacuata', `The
%% house has been evacuated' -- because the IR carries the claim and not
%% the typography. What is lost is a headline's shape, not its meaning.
tr_read_statement(foreign, Words0, none, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    Words = [w(P, _)|After], After \== [],
    tr_participle_here(foreign, P, L),
    member(N, [singular, plural]),
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
tr_read_statement(Side, Words0, none, S) :-
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
tr_read_statement(foreign, Words0, none, S) :-
    tr_negation(foreign, Words0, Words, Neg),
    append(Clitics0, [w(V, _)|Rest], Words), \+ memberchk(comma, Clitics0),
    tr_imperative_here(foreign, Neg, V, L),
    forall(member(w(C, _), Clitics0), tr_clitic(none, C)),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', imperative),
    tr_reflexive_off(foreign, Clitics0, Clitics, L, LV),
    tr_complements(foreign, Rest, Comps0), !,
    findall(opron(W), member(W, Clitics), Cs),
    append(Cs, Comps0, Comps),
    S = s(none, none, g(LV, present, imperative, Neg), Comps).
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
tr_read_statement(foreign, Words0, Asked, S) :-
    Asked \= subject(_),
    tr_negation(foreign, Words0, Words, Neg),
    tr_group_from(foreign, Words, Before, g(L, T, A, third, singular), After),
    nb_setval('$tr_read_group', L),
    nb_setval('$tr_read_aspect', A),
    tr_uncomma(Before, BeforeU),
    tr_split_clitics(foreign, BeforeU, unsaid(Asked), third, singular, [], Clitics0),
    tr_reflexive_off(foreign, Clitics0, Clitics, L, LV),
    tr_complements(foreign, After, Comps0), !,
    findall(opron(W), member(W, Clitics), Cs),
    append(Cs, Comps0, Comps),
    S = s(Asked, null(third, singular), g(LV, T, A, Neg), Comps).
%% English's is the BASE FORM, and its denial keeps the `do' the negation
%% took the `not' out of: `Do not eat the bread.'
tr_read_statement(english, Words0, none, S) :-
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
tr_imperative_here(foreign, no, V, L) :-
    tr_solve(imperative_of(V, L)), \+ tr_holds(negative(V)), tr_known(foreign, L), !.
tr_imperative_here(foreign, yes, V, L) :-
    tr_solve(imperative_of(V, L)), tr_holds(negative(V)), tr_known(foreign, L), !.
tr_imperative_here(english, _, V, L) :- en_verb_form(V, L, present), !.

%% and the form out, for either
tr_imperative_form(L, no, F) :-
    once(( tr_solve(imperative_of(F0, L)), \+ tr_holds(negative(F0)) )), F = F0.
tr_imperative_form(L, yes, F) :-
    once(( tr_solve(imperative_of(F0, L)), tr_holds(negative(F0)) )), F = F0.

%% a gerund of a verb the lesson gives, on either side
tr_gerund_here(foreign, G, L) :- tr_solve(gerund_of(G, L)), tr_known(foreign, L), !.
tr_gerund_here(english, G, L) :- en_gerund(G, L), !.

%% the word a lesson gives for `that' before a clause: English's own, and
%% a conjunction of the lesson's that means it
tr_that_here(english, w(that, _)) :- !.
tr_that_here(foreign, w(W, _)) :-
    tr_lexeme(foreign, W, L, _), tr_class_of(L, conjunction), tr_solve(mean(L, that)), !.

tr_that_word(english, that) :- !.
tr_that_word(foreign, W) :- once(( tr_solve(mean(L, that)), tr_class_of(L, conjunction), W = L )).

%% what may stand before an inverted verb: an adjunct, never an object
tr_adjunct(sep).
tr_adjunct(adv(_)).
tr_adjunct(pp(_, _)).
tr_adjunct(at_time(_)).

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
tr_negation(foreign, Words, Rest, yes) :- append(A, [w(N, _)|B], Words), tr_solve(mean(N, not)), !, append(A, B, Rest).
tr_negation(_, Words, Words, no).

tr_negation_word(N) :- once(tr_solve(mean(N, not))).

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
tr_subject_shape(_, [w(W, _)], P, N) :- tr_subject_pronoun(foreign, W, P1, N1), !, P1 == P, N1 == N.
tr_subject_shape(_, [w(W, _)], P, N) :- tr_impersonal(foreign, W), !, P == third, N == singular.
tr_subject_shape(_, [w(W, upper)], _, _) :- \+ tr_known_word(foreign, W), !.
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
    \+ ( member(w(X, _), Words), tr_object_pronoun(foreign, X, _), \+ tr_determiner(foreign, w(X, lower), _, _) ),
    \+ ( last(Words, w(X, _)), tr_object_pronoun(foreign, X, _) ),
    %% nor a REFLEXIVE pronoun anywhere in it: `la casa si' is the phrase and
    %% the clitic, never a phrase with `si' for an adjective
    \+ ( member(w(X, _), Words), tr_reflexive_word(X) ),
    (   member(W, Words), tr_is(foreign, W, noun) -> true
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
    tr_group_at(Side, Rest, Group, After).

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
    tr_solve(participle_of(P, L)), tr_known(foreign, L), !.
%% ... AND AN ADVERB MAY STAND INSIDE IT, before the verb's participle: `non
%% sono state ANCORA accertate'. The two-word passive below then took `sono
%% state' for the passive of `stare' -- `stata' is the participle of `stare'
%% as well as of the copula, and the store answers `stare' first -- and read
%% `accertate' as a participle predicated of the subject, which is `are not
%% stood, even verified'. The adverbs go back at the head of what follows,
%% where the complement reader reads any adverb after the verb.
tr_group_at(foreign, [w(C, _), w(B, _)|R0], g(L, T, passive_perfect, Person, N), R) :-
    tr_adverb_prefix(R0, Advs, [w(P, _)|R1]), Advs \== [],
    tr_form(C, CL, N, T, Person),
    tr_solve(participle_of(B, BL)), tr_copula_lexeme(BL), tr_perfect_auxiliary(BL, CL),
    tr_solve(participle_of(P, L)), tr_known(foreign, L), !,
    append(Advs, R1, R).
tr_group_at(foreign, [w(A, _), w(P, _)|R], g(L, T, perfect, Person, N), R) :-
    tr_form(A, AL, N, T, Person), tr_solve(auxiliary(AL)), tr_solve(participle_of(P, L)), tr_known(foreign, L), !.
%% WHAT TELLS A PASSIVE FROM A PERFECT IS THE LESSON, not this code. Italian
%% builds the perfect of some verbs with `essere' too -- `e riuscito' is `has
%% succeeded', not `is succeeded' -- and nothing in a lesson says which verbs
%% those are. The rule above fires only for a word the lesson calls an
%% auxiliary, so `ha' takes the perfect and `e' falls through to here; a
%% lesson that called its copula an auxiliary would get the other reading.
%% The cost is stated rather than hidden: an intransitive perfect built with
%% the copula reads as a passive.
tr_group_at(foreign, [w(C, _), w(P, _)|R], g(L, T, passive, Person, N), R) :-
    tr_form(C, CL, N, T, Person), tr_copula_lexeme(CL),
    tr_solve(participle_of(P, L)), tr_known(foreign, L), !.
%% -- and NOT cut on the first reading: `sono' is the first person of `è'
%% and the plural of it, and which one it is in `Le case sono grandi' the
%% subject decides, so the statement reader backtracks into the next
tr_group_at(foreign, [w(V, _)|R], g(L, T, simple, Person, N), R) :-
    tr_form(V, L, N, T, Person), tr_verb_lexeme(L).

%% a verb of the lesson's, or a modal
tr_verb_lexeme(L) :- ( tr_class_of(L, verb) -> true ; tr_class_of(L, modal) ).

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
tr_subject(_, subject(Q), [], _, _, asked(Q)) :- !.
tr_subject(foreign, _, [], P, N, null(P, N)) :- !, ( P \== third ; N == plural ).
tr_subject(Side, _, [w(P, C)], _, _, pronoun(Person, Number, w(P, C))) :- tr_subject_pronoun(Side, P, Person, Number), !.
%% BEFORE the phrase below, on both sides: English's `one' is a number word
%% as well, and the lesson's word is a pronoun the phrase reader would take
%% for one
tr_subject(Side, _, [w(W, _)], _, _, impersonal) :- tr_impersonal(Side, W), !.
tr_subject(Side, _, Words, _, _, co(C, S1, S2)) :-
    tr_conjunction_split(Side, Words, W1, C, W2), !,
    tr_subject(Side, none, W1, third, singular, S1), tr_subject(Side, none, W2, third, singular, S2).
tr_subject(Side, _, Words, _, _, Subject) :- tr_np(Side, Words, Subject), !.
%% a phrase and the prepositional phrases after it: `the dogs of Maria'
tr_subject(Side, _, Words, _, _, with(NP, PPs)) :-
    append(NPWords, [P|PPWords], Words), tr_is(Side, P, preposition), NPWords \== [],
    tr_np(Side, NPWords, NP), tr_complements(Side, [P|PPWords], PPs),
    forall(member(X, PPs), X = pp(_, _)), !.

%% `Maria and Omar', `the bread and the egg': two phrases, each with a
%% noun, a name or a pronoun of its own
%% THE CONJUNCTION IS KEPT, which it was not: every phrase joined by one
%% travelled as and/2, so `el caldo o la sopa' came out `il brodo e la
%% minestra' -- a different claim. co(Conjunction, A, B) carries the word
%% the text joined them with, it crosses by its meaning like a connector
%% between clauses, and each writer puts the target's word for it back.
tr_conjunction_split(Side, Words, W1, W2) :- tr_conjunction_split(Side, Words, W1, _, W2).
tr_conjunction_split(Side, Words, W1, w(C, CC), W2) :-
    append(W1, [w(C, CC)|W2], Words), tr_coord(Side, w(C, lower)), W1 \== [], W2 \== [],
    \+ ( member(w(R, _), W1), tr_relative_word(Side, R) ),     % never inside a relative clause
    %% nor before a run of ADJECTIVES with nothing to head them: `la violencia
    %% gratuita juvenil, anárquica o xenófoba' is one violence, and split
    %% there `xenófoba' was a xenophobe and came out masculine
    \+ ( W1 = [_, _|_], forall(member(X, W2), ( tr_coord(Side, X) ; tr_is(Side, X, adjective) )) ),
    tr_headed(Side, W1), tr_headed(Side, W2), !.
tr_headed(Side, Ws) :- member(w(W, _), Ws), ( tr_is(Side, w(W, lower), noun) ; tr_is_name(Side, W) ; tr_subject_pronoun(Side, W, _, _) ; tr_object_pronoun(Side, W, _) ), !.
%% ... or a phrase whose noun was left out: `un grupo y el más débil'
tr_headed(Side, Ws) :- Ws = [D, _|_], tr_determiner(Side, D, _, article), tr_np(Side, Ws, NP), ( NP = np(_, _, _, elided(_), _) ; NP = ell(_, _, _, _) ), !.
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
tr_np(Side, Words, rc(NP, Role, S)) :-
    once(( member(w(RW, _), Words), tr_relative_word(Side, RW) )),    % no split is worth trying without one
    append(Core, Rest, Words), Core \== [],
    tr_relative_start(Side, Rest),
    \+ ( member(w(R0, _), Core), tr_relative_word(Side, R0) ),
    tr_relative_clause(Side, Rest, Role, S),
    tr_object_phrase(Side, Core, NP), !.
tr_np(Side, Words, rel(NP, L, Comps)) :-
    append(Core, [w(P, _)|Rest], Words), Core \== [],
    %% a clitic heads nothing: `la tesi' is the thesis, never `her, tended'
    \+ ( Side == foreign, Core = [w(C1, _)], tr_clitic(normal, C1) ),
    tr_participle_here(Side, P, L),
    tr_object_phrase(Side, Core, NP), NP \= rel(_, _, _),
    (   Rest == []
    ->  Comps = []
    ;   tr_reduced_agent(Side, Rest, Comps)
    ), !.
tr_np(Side, [w(W, upper)], name(W)) :- \+ tr_known_word(Side, W), !.
tr_np(Side, Words0, np(Det, Num, AdjsM, Noun, Number)) :-
    %% A POSSESSIVE AFTER AN ARTICLE IS THE PHRASE'S DETERMINER: `la sua
    %% casa' is his house, which Spanish writes `su casa' and Italian, whose
    %% lesson says `The article "il" takes the possessive', with the article
    %% back in front. Read as an adjective it was `la su identidad', and it
    %% crossed by the adjective's meaning -- `sua' is `hers' as one
    (   Side == foreign, Words0 = [A0, P0|Ws1], Ws1 \== [],
        tr_determiner(Side, A0, _, article), tr_determiner(Side, P0, PL, possessive)
    ->  Det = det(possessive, PL, P0), Words1 = Ws1
    ;   Words0 = [D|Ws1], tr_determiner(Side, D, DL, DK), Ws1 \== []
    ->  Det = det(DK, DL, D), Words1 = Ws1
    ;   Det = none, Words1 = Words0
    ),
    %% the count is the number before the noun -- at the head of what is left
    %% after the determiner, or, since 1.6.14, ANYWHERE among the adjectives
    %% before it: `solo due anni' is `only two years', and with the number
    %% left among them the writer asked the lesson for an ADJECTIVE meaning
    %% `two' and the phrase could not be written at all
    (   Words1 = [M|Ws2], tr_is(Side, M, number), Ws2 \== []
    ->  Num = M, Words2 = Ws2
    ;   append(Pre1, [M|Post1], Words1), tr_is(Side, M, number), Post1 \== [],
        forall(member(X1, Pre1), tr_adj_word(Side, X1))
    ->  Num = M, append(Pre1, Post1, Words2)
    ;   Num = none, Words2 = Words1
    ),
    Words2 \== [],
    tr_intensify(Side, Words2, Words3),
    tr_noun(Words3, Side, Noun0, Adjs0),
    tr_degree_of(Side, Det, Degree), tr_degrees(Side, Degree, [Noun0|Adjs0], [Noun|Adjs]),
    %% `The' alone is no phrase, whatever `el' means -- UNLESS the lesson
    %% also calls the word a noun or a pronoun, which is what `uno' is in
    %% `uno dei paesi': the masculine article and the word for `one'
    \+ ( tr_determiner(Side, Noun, _, _), \+ tr_is(Side, Noun, noun), \+ tr_is(Side, Noun, pronoun) ),
    \+ ( \+ tr_is(Side, Noun, noun), tr_is(Side, Noun, verb) ),   % nor is a verb's form the lesson calls no noun (`son grandes')
    \+ ( \+ tr_is(Side, Noun, noun), tr_is(Side, Noun, adverb) ), % nor a word known only as an adverb (`Después, en ...')
    forall(member(A, Adjs), ( tr_adj_word(Side, A) ; tr_apposed_name(Det, Words0, A) )),
    Noun = w(NW, _),
    %% the noun's number by the reading of it that IS a noun: `houses' is a
    %% verb's form too (to house), and known so before it is a plural
    ( tr_lexeme(Side, NW, NL, Number), tr_class(Side, NL, noun) -> true ; tr_lexeme(Side, NW, _, Number) ),
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
%% not -- `tr_np/3' above takes a lone capitalised word and two of them stay
%% two, because after a determiner the phrase's start is not in doubt and
%% bare it is: `Sabato Mladic' is a day and a surname.
tr_np(Side, [D|Ws], np(det(DK, DL, D), none, [], named(G, Ws), Number)) :-
    Ws \== [], tr_determiner(Side, D, DL, DK),
    forall(member(W, Ws), tr_name_word(Side, W)),
    tr_det_gender(Side, D, DL, G, Number), !.

%% a word of a name: capitalised, and no lesson knows it
tr_name_word(Side, w(W, upper)) :- \+ tr_known_word(Side, W).

%% A NAME APPOSED TO A NOUN: `il presidente Scalfaro', `la Tate Gallery' the
%% other way round. It stands where an adjective stands and crosses as
%% ITSELF, which is what being a name means -- and only at the END of a
%% phrase that has a DETERMINER, because bare `Sabato Mladic' is a day and a
%% surname and nothing says where one ends.
tr_apposed_name(Det, Words, w(W, upper)) :-
    Det \== none, last(Words, w(W, upper)).
tr_apposed_name(_, Words, w(W, appos)) :- last(Words, w(W, appos)).

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
tr_participle_here(english, P, L) :- en_passive_participle(P, L), !.

%% what may follow a reduced relative and belong to it: its agent, and
%% nothing else -- a phrase after it is the sentence's, not the participle's
tr_reduced_agent(Side, Ws, [by(NP)]) :-
    Ws = [P|Rest], tr_is(Side, P, preposition), tr_means_by(Side, P),
    tr_phrase_words(Side, Rest, PW, []), PW \== [], tr_phrase_np(Side, PW, NP).

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
tr_degree_of(foreign, _, comparative).

%% a word that may be an adjective in a phrase: known, and no preposition,
%% pronoun or verb -- or the `and' between two
tr_adj_word(_, deg(_, _)) :- !.
tr_adj_word(_, int(_, _)) :- !.
tr_adj_word(Side, A) :- tr_coord(Side, A), !.
tr_adj_word(Side, w(W, C)) :-
    tr_lexeme(Side, W, _, _),
    \+ tr_is(Side, w(W, C), preposition), \+ tr_object_pronoun(Side, W, _), \+ tr_subject_pronoun(Side, W, _, _),
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
    %% ... NOR AN ARTICLE, which a phrase has at most one of and at its
    %% head. `Sabado el perro come el pan' read `Sabado el perro' as one
    %% phrase with `saturday' and `the' for adjectives of `dog', so the
    %% fronted clause never saw it. A POSSESSIVE is still an adjective
    %% here, because `il suo quartier generale' is one phrase.
    \+ tr_determiner(Side, w(W, C), _, article),
    \+ ( Side == foreign, tr_reflexive_word(W) ).

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
    ;   Nouns == [] -> tr_noun_by_position(Words, Side, Noun)
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
    tr_complements(Side, Words, no, Comps).

%% ... with whether an object has been read: the word the lesson puts
%% before a person, with no object yet and a person after it, is the
%% OBJECT's (`Maria ve a Omar' is Omar); after an object it is the
%% preposition it is (`Maria da el libro a Omar' is to Omar)
tr_complements(_, [], _, []) :- !.
tr_complements(Side, [comma|Ws], Seen, [sep|Cs]) :- !, tr_complements(Side, Ws, Seen, Cs).
%% A `che' CLAUSE IS A COMPLEMENT, AND IT RUNS TO THE END OF ITS PIECE.
%% `escludendo che il militare voleva ...' -- the word the lesson gives for
%% `that' before a clause, and everything after it read as a statement of
%% its own. Taking the WHOLE rest rather than the shortest readable piece
%% is deliberate: a shortest-first append would stop at the first clause
%% that happens to read, which is never what `that' introduces.
tr_complements(Side, [W|Ws], _, [that(S)]) :-
    tr_that_here(Side, W), Ws \== [],
    tr_read_nested(Side, Ws, none, S), !.
%% A GERUND AFTER A CLAUSE'S COMPLEMENTS IS HOW THE CLAUSE WAS DONE:
%% `destrozan la cabeza a un inmigrante utilizando un bate de béisbol'. It
%% takes the rest of the words as its own complements, the way a `che'
%% clause does, and travels as ger(Lexeme, Complements); every language
%% here writes it as its own gerund in the same place.
tr_complements(Side, [w(G, _)|Ws], _, [ger(L, Cs)]) :-
    Ws \== [], tr_gerund_here(Side, G, L), \+ tr_is(Side, w(G, lower), noun),
    tr_complements(Side, Ws, Cs), !.
%% `AL' AND AN INFINITIVE IS THE MOMENT SOMETHING WAS DONE: `ha provocado el
%% escándalo al acusar a la institución' -- on accusing it. The lesson names
%% the word, `The word "al" begins the moment.', in the shape `The word
%% "per" begins the purpose.' already has; it is read as the words the
%% contraction stands for (`a el') with the infinitive after them, and the
%% rest of the words are the infinitive's complements. upon(Lexeme,
%% Complements) is the term; English writes `on' and the -ing form, and a
%% lesson that names no such word writes its gerund.
tr_complements(foreign, Ws0, _, [upon(F, Cs)]) :-
    Ws0 = [w(P, _), w(D, _), w(V, _)|Ws],
    tr_solve(begin(M, moment)), tr_solve(contraction_of(M, J)), atomic_list_concat([P, D], ' ', J),
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F),
    tr_complements(foreign, Ws, Cs), !.
tr_complements(english, [w(on, _), w(G, _)|Ws], _, [upon(L, Cs)]) :-
    en_gerund(G, L), tr_complements(english, Ws, Cs), !.
tr_complements(foreign, [w(P, _)|Ws], no, [obj(NP)|Cs]) :-
    tr_marker_word(P, Class),
    tr_phrase_words(foreign, Ws, PW, Rest), PW \== [],
    tr_phrase_np(foreign, PW, NP), tr_of_class(NP, Class), !,
    tr_complements(foreign, Rest, yes, Cs).
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
tr_complements(foreign, [w(P, _), w(V, _)|Ws], Seen, [purpose(F)|Cs]) :-
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
tr_complements(foreign, [w(P, _), w(V, _)|Ws], Seen, [inf(F)|Cs]) :-
    tr_means_to(P), tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements(foreign, Ws, Seen, Cs).
tr_complements(foreign, [w(V, _)|Ws], Seen, [inf(F)|Cs]) :-
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements(foreign, Ws, Seen, Cs).
tr_complements(english, [w(to, _), w(B, _)|Ws], Seen, [inf(L)|Cs]) :-
    en_infinitive(B, L), !,
    tr_complements(english, Ws, Seen, Cs).
tr_complements(english, [w(B, _)|Ws], Seen, [inf(L)|Cs]) :-
    tr_read_modal, en_infinitive(B, L), !,
    tr_complements(english, Ws, Seen, Cs).
%% TWO INFINITIVES UNDER ONE PURPOSE: `per definire "illegale" la decisione
%% E invocare il sostegno dei suoi soldati'. The conjunction is not inside a
%% phrase -- which is the splitter's `A e B' -- and it is not between two
%% clauses either, because the second half has no subject and no finite
%% verb. It is between two COMPLEMENTS, so it travels as one and writes
%% with the target's word for it.
tr_complements(Side, [C|Ws], Seen, [cnj(C)|Cs]) :-
    tr_coord(Side, C), ( tr_starts_infinitive(Side, Ws) ; Ws = [P|_], tr_is(Side, P, preposition) ), !,
    tr_complements(Side, Ws, Seen, Cs).
%% THE AGENT OF A PASSIVE IS NOT AN ADJUNCT: `dai soldati' is who did it,
%% and it travels as by/1 so that it writes with the TARGET's word for `by'.
%% Read as an ordinary pp/2 it would cross by the first meaning of `da',
%% which the lesson gives as `from' -- and `imposed from the soldiers' is
%% not what the sentence says.
tr_complements(Side, [P|Ws], Seen, [by(NP)|Cs]) :-
    tr_read_passive, tr_is(Side, P, preposition), tr_means_by(Side, P), !,
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [], tr_phrase_np(Side, PW, NP),
    tr_complements(Side, Rest, Seen, Cs).
%% AND A PREPOSITION'S OBJECT MAY BE AN ADVERB: `per sempre' is `for
%% ever', `para siempre', and every language writes it as the two words it
%% is. It rides pp/2 with adv/1 where the phrase goes, so the crossing and
%% both writers take it apart by the clauses they already had.
tr_complements(Side, [P|Ws], Seen, [pp(P, NP)|Cs]) :-
    tr_is(Side, P, preposition), !,
    (   Ws = [w(O, OC)|Rest], tr_object_pronoun_here(Side, Ws), \+ tr_relative_start(Side, Rest), \+ tr_ellipsis_start(Side, Ws)
    ->  NP = pronoun(w(O, OC))
    ;   tr_phrase_words(Side, Ws, PW, Rest), PW \== [], tr_phrase_np(Side, PW, NP)
    ->  true
    ;   Ws = [A|Rest], tr_is(Side, A, adverb), NP = adv(A)
    ),
    tr_complements(Side, Rest, Seen, Cs).
tr_complements(Side, [w(W, C)|Ws], Seen, [opron(w(W, C))|Cs]) :-
    tr_object_pronoun_here(Side, [w(W, C)|Ws]), \+ tr_relative_start(Side, Ws), \+ tr_ellipsis_start(Side, [w(W, C)|Ws]), !,
    tr_complements(Side, Ws, Seen, Cs).
tr_complements(Side, [A|Ws], Seen, [adv(A)|Cs]) :- tr_is(Side, A, adverb), !, tr_complements(Side, Ws, Seen, Cs).
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
tr_complements(Side, [w(P, _)|Ws], Seen, [pred(L)|Cs]) :-
    tr_participle_here(Side, P, L), !,
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
tr_complements(english, Ws, _, [oc(NP, As)|Cs]) :-
    tr_phrase_words(english, Ws, PW, Rest), PW \== [],
    append(PW0, As, PW), PW0 \== [], As \== [],
    tr_all_adjectives(english, As), \+ tr_all_adjectives(english, PW0),
    tr_phrase_np(english, PW0, NP), !,
    tr_complements(english, Rest, yes, Cs).
tr_complements(foreign, Ws, _, [oc(NP, As)|Cs]) :-
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
tr_complements(Side, Ws, Seen, [at_time(NP)|Cs]) :-
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [],
    tr_phrase_np(Side, PW, NP), tr_time_phrase(NP), !,
    tr_complements(Side, Rest, Seen, Cs).
tr_complements(Side, Ws, _, [C|Cs]) :-
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [],
    (   tr_all_adjectives(Side, PW) -> C = adj(PW)
    ;   tr_phrase_np(Side, PW, NP), C = obj(NP)
    ),
    tr_complements(Side, Rest, yes, Cs).

%% a phrase whose noun the lesson calls a time
tr_time_phrase(np(_, _, _, W, _)) :- tr_noun_of_lesson(W, Noun), tr_holds(time(Noun)).

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
    \+ ( catch(nb_getval('$tr_verb', V), _, fail), V == is ),
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
    (   PW0 \== [], Rest0 \== [], tr_relative_start(Side, Rest0)
    ->  append(PW0, Rest0, PW), Rest = []
    ;   PW = PW0, Rest = Rest0
    ).

%% AN ARTICLE AND A `de' PHRASE WITH NO NOUN BETWEEN THEM ARE ONE PHRASE:
%% `en los de clase media' -- in those of the middle class. The article
%% stands for a noun the sentence already said, and the preposition belongs
%% to it; without this the phrase ended at the preposition and was the
%% article alone, which reads as the object pronoun `los'.
tr_phrase_words0(Side, [D, P|Ws], [D, P|PW2], Rest) :-
    tr_determiner(Side, D, _, article), \+ tr_standalone_det(Side, D),
    tr_is(Side, P, preposition), tr_means_of(Side, P),
    tr_phrase_words0(Side, Ws, PW2, Rest), PW2 \== [], !.
tr_phrase_words0(Side, Words, PW, Rest) :-
    append(PW0, Rest0, Words), PW0 \== [],
    last(PW0, w(P, _)), tr_participle_here(Side, P, _),
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
        %% ... except a `de' after a coordinator and an article, which is
        %% the second half's own: `el pan de los gatos y el de los chicos'
        %% ended at the second `de' and left `el' as a phrase of one article
        ;   tr_is(Side, R, preposition),
            \+ ( tr_means_of(Side, R), append(_, [Co, LA], PW),
                 tr_coord(Side, Co), tr_determiner(Side, LA, _, article), \+ tr_standalone_det(Side, LA) )
        ;   tr_is(Side, R, adverb)
        %% an object pronoun ends a phrase that has begun; at its head it IS
        %% the phrase, which is reached only when the pronoun readings above
        %% stood down for a relative clause after it (`contra esos, que son')
        ;   PW \== [], tr_object_pronoun_here(Side, Rest),
            \+ ( last(PW, LW0), tr_coord(Side, LW0) )     % `sopas y otros': the pronoun is the second half
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
        ;   PW \== [], tr_determiner(Side, R, _, _),
            member(X, PW), tr_is(Side, X, noun),
            \+ ( last(PW, LW), tr_coord(Side, LW) ),
            \+ ( last(PW, LP), tr_is(Side, LP, preposition) )  % `y el de LOS chicos'
        %% ... and a coordinator before a PREPOSITION joins two complements,
        %% not two halves of this phrase: `en los barrios de la ciudad y en
        %% los de clase media' -- read as one phrase, `y' was an adjective of
        %% `ciudad' and came out `of the and city'
        ;   PW \== [], tr_coord(Side, R), Rest = [_, P2|_], tr_is(Side, P2, preposition)
        %% ... and so does a conjunction before an INFINITIVE: `un fax e
        %% invocare il sostegno' is the object and a second infinitive
        %% under the same purpose, never one phrase with `e' in it -- which
        %% is what the phrase splitter's `A e B' made of it, and it refused
        %% the sentence because the second half is no phrase.
        ;   Rest = [_|More], tr_coord(Side, R), tr_starts_infinitive(Side, More)
        ),
        %% asked only where a boundary was found, and not at every word
        \+ tr_degree_start(Side, Rest)              % `el más débil': `más' is a preposition too
    ), !.

%% an object pronoun standing as one: not an article or a possessive with
%% its noun after it -- `la casa', `los libros', English's `her house'
tr_object_pronoun_here(Side, [w(W, _)|Ws]) :-
    tr_object_pronoun(Side, W, _),
    \+ ( tr_determiner(Side, w(W, lower), _, _), Ws = [N|_], tr_content_word(Side, N) ).
tr_content_word(Side, N) :- ( tr_is(Side, N, noun) ; tr_is(Side, N, adjective) ; tr_is(Side, N, number) ), !.

tr_object_phrase(Side, [w(W, C)], pronoun(w(W, C))) :- tr_object_pronoun(Side, W, _), !.
tr_object_phrase(Side, Words, NP) :- tr_np(Side, Words, NP).

%% A PHRASE WHOSE NOUN THE SENTENCE LEFT OUT. `el más débil' is the weakest
%% one and `los de clase media' those of the middle class: an article and
%% then adjectives, or an article and a `de' phrase, with no noun. The noun
%% slot holds elided(Gender), the gender the article lends it -- the one
%% thing the missing noun would have said -- so every word written after it
%% agrees; and a `de' phrase travels as ell(Det, Gender, Number, PP).
tr_np(Side, [D|Ws], np(det(DK, DL, D), none, Adjs, elided(G), Number)) :-
    Ws \== [], tr_determiner(Side, D, DL, DK), DK == article, \+ tr_standalone_det(Side, D),
    tr_degree_of(Side, det(DK, DL, D), Degree), tr_degrees(Side, Degree, Ws, Adjs),
    Adjs \== [], forall(member(A, Adjs), ( A = deg(_, _) ; tr_is(Side, A, adjective) )),
    ( member(deg(_, _), Adjs) -> true ; \+ ( member(A, Ws), tr_is(Side, A, noun) ) ),
    tr_det_gender(Side, D, DL, G, Number), !.
tr_np(Side, [D, P|Ws], ell(det(DK, DL, D), G, Number, pp(P, NP))) :-
    tr_determiner(Side, D, DL, DK), DK == article, \+ tr_standalone_det(Side, D),
    tr_is(Side, P, preposition), tr_means_of(Side, P), Ws \== [],
    tr_object_phrase(Side, Ws, NP),
    tr_det_gender(Side, D, DL, G, Number), !.

%% the words that open a phrase whose noun was left out, and a degree word
%% before an adjective, which is no adverb standing alone
tr_ellipsis_start(Side, [D, P|_]) :- tr_determiner(Side, D, _, article), \+ tr_standalone_det(Side, D), tr_is(Side, P, preposition), tr_means_of(Side, P), !.

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
tr_relative_start(Side, [P, w(R, _)|_]) :- tr_is(Side, P, preposition), tr_relative_word(Side, R), !.
tr_relative_start(Side, [P, D, w(R, _)|_]) :-
    tr_is(Side, P, preposition), tr_determiner(Side, D, _, article), tr_relative_word(Side, R), !.

%% a relative word: English's own, or one the lesson calls one (`"que" is a
%% relative.')
tr_relative_word(english, W) :- !, memberchk(W, [that, which, who, whom]).
tr_relative_word(foreign, W) :- tr_solve(relative(W)), !.

%% the clause after a relative word, and what the word stands for in it
tr_relative_clause(Side, [w(R, _)|Ws], subject, S) :-
    tr_relative_word(Side, R), Ws \== [],
    tr_read_nested(Side, Ws, subject(rel), S0),
    S0 = s(_, asked(_), G, Comps), !,
    S = s(none, gap, G, Comps).
%% ... and the clause of an object or a preposition's object is read with
%% `rel' where a question's asked term goes: every statement shape that
%% insists on `none' -- an imperative, a headline, a gerund clause -- stands
%% down, because none of them can follow a relative word. Measured: `al que
%% pertenece' read `pertenece' as the IMPERATIVE it is spelled like and
%% wrote Italian's second person, `a cui appartieni'.
tr_relative_clause(Side, [w(R, _)|Ws], object, S) :-
    tr_relative_word(Side, R), Ws \== [],
    tr_read_nested(Side, Ws, rel, S0), !, tr_unrel(S0, S).
tr_relative_clause(Side, [P, w(R, _)|Ws], pp(P), S) :-
    tr_is(Side, P, preposition), tr_relative_word(Side, R), Ws \== [],
    tr_read_nested(Side, Ws, rel, S0), !, tr_unrel(S0, S).
tr_relative_clause(Side, [P, D, w(R, _)|Ws], pp(P), S) :-
    tr_is(Side, P, preposition), tr_determiner(Side, D, _, article), tr_relative_word(Side, R), Ws \== [],
    tr_read_nested(Side, Ws, rel, S0), !, tr_unrel(S0, S).

tr_unrel(s(_, Su, G, Cs), s(none, Su, G, Cs)).

%% a clause read inside another puts back the group the outer one is
%% reading, which its later complements ask about -- the mirror of
%% tr_write_nested/3
tr_read_nested(Side, Ws, Asked, S) :-
    tr_global('$tr_read_group', G), tr_global('$tr_read_aspect', A),
    (   tr_read_statement(Side, Ws, Asked, S0)
    ->  nb_setval('$tr_read_group', G), nb_setval('$tr_read_aspect', A), S = S0
    ;   nb_setval('$tr_read_group', G), nb_setval('$tr_read_aspect', A), fail
    ).

%% the word this lesson puts before an infinitive of purpose
tr_purpose_word(P) :- tr_lexeme(foreign, P, L, _), tr_solve(begin(L, purpose)), !.

%% the group being read is a modal, so a bare base form after it is its verb
tr_read_modal :- catch(nb_getval('$tr_read_group', L), _, fail), en_modal_out(L, _, _).

%% the group being read is a passive, so a `by' phrase after it is the agent
tr_read_passive :- catch(nb_getval('$tr_read_aspect', A), _, fail), memberchk(A, [passive, passive_perfect]).

%% a word of the lesson's that means `to' -- what a verb puts before its
%% infinitive (`tende AD accreditare')
tr_means_to(P) :- tr_lexeme(foreign, P, L, _), tr_solve(mean(L, to)), !.

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
    tr_comps_out(To, Front, none, singular, _, F1, FA), append(F1, FA, FO),
    tr_comps_out(To, Back, none, singular, _, B1, BA), append(B1, BA, BO),
    ( FO == [] -> Outs = BO ; append(FO, [o(',', comma)|BO], Outs) ).
tr_write(To, Kind, join(C, none, S2), Outs) :- !,
    tr_connector_out(To, C, CO),
    tr_write(To, Kind, S2, O2),
    append(CO, O2, Outs).
tr_write(To, Kind, join(C, S1, S2), Outs) :- !,
    tr_write(To, Kind, S1, O1),
    tr_connector_out(To, C, CO),
    tr_write(To, statement, S2, O2),
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
%% the complements the source set off in front are written in front, and the
%% comma after them
tr_write(To, Kind, s(Asked, Subject, G, Comps0), Outs) :-
    select(fr(_), Comps0, _), !,
    findall(C, member(fr(C), Comps0), Fr), findall(C, ( member(C, Comps0), C \= fr(_) ), Comps),
    %% each in the order it stood, an adverb among them too -- and every one
    %% of them written, or the sentence is refused: a findall here dropped a
    %% phrase it could not write and wrote the rest
    tr_fronts_out(To, Fr, FO),
    tr_write(To, Kind, s(Asked, Subject, G, Comps), O2),
    append(FO, [o(',', comma)|O2], Outs).
tr_write(To, Kind, s(Asked, Subject, g(L, T, A, Neg), Comps), Outs) :-
    ( L = reflexive(L0) -> true ; L0 = L ), nb_setval('$tr_verb', L0),
    tr_subject_out(To, Subject, SubjectOut, Person, Number, Noun),
    %% the subject's gender, for a passive participle to agree with
    ( Noun == none -> SG = masculine ; tr_gender(Noun, SG0), ( SG0 == none -> SG = masculine ; SG = SG0 ) ),
    nb_setval('$tr_subject_gender', SG),
    tr_asked_out(To, Asked, AskedOut),
    tr_lexeme_across(L, To, LT),
    tr_comps_out(To, Comps, Noun, Number, Clitics, CompOuts, Advs),
    (   To == english
    ->  en_group(LT, Person, Number, T, A, Neg, Statement, Front, Tail),
        append(CompOuts, Advs, Rest),
        en_assemble(Kind, Asked, AskedOut, SubjectOut, Statement, Front, Tail, Rest, Outs)
    ;   %% the impersonal word goes AFTER the object pronouns where the
        %% lesson says it follows them: Italian's `li si chiamerà'
        (   Subject == impersonal, SubjectOut = [o(ImpW, _)], tr_holds(follow(ImpW, pronoun))
        ->  append(Clitics, [o(ImpW, lower)], Clitics1), SubjectOut1 = []
        ;   Clitics1 = Clitics, SubjectOut1 = SubjectOut
        ),
        fo_group(LT, Person, Number, T, A, Neg, Clitics1, Group),
        append(CompOuts, Advs, Rest),
        fo_assemble(Asked, AskedOut, SubjectOut1, Group, Rest, Outs)
    ).

%% the verb's lexeme across: the English third person for the lesson's
%% verb, the lesson's verb for the English one -- `is' is `is' either way
%% as the copula, and the lesson's word for it
tr_lexeme_across(reflexive(L0), To, reflexive(LT)) :- !, tr_lexeme_across(L0, To, LT).
tr_lexeme_across(L, To, LT) :- tr_meanings_of(L, To, verb, [LT|_]).

%% the subject out, with its person and number for the verb and its noun
%% for the agreement of what is said of it
tr_subject_out(To, asked(w(Q, C)), [o(QT, C)], third, singular, none) :- !, tr_question_across(To, subject, Q, QT).
tr_subject_out(To, asked(which_np(NP, C)), [o(QT, C)|NPOut], third, Number, Noun) :- !,
    tr_which_word(To, QT), tr_np_out(To, NP, NPOut, Noun, Number).
tr_subject_out(_, none, [], third, singular, none) :- !.
tr_subject_out(_, name(W), [o(W, upper)], third, singular, none) :- !.
tr_subject_out(To, pronoun(P, N, w(W, C)), Outs, P, N, none) :- !,
    (   tr_pronoun_across(To, subject, w(W, C), P, N, T) -> Outs = [o(T, C)]
    ;   To == foreign, W == it -> Outs = []                                % `It rains': the verb says who
    ).
%% ... and a third person singular nobody named is refused in English:
%% he, she and it are three claims and the source made none of them
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
tr_subject_out(To, co(C, S1, S2), Outs, third, plural, none) :- !,
    tr_subject_out(To, S1, O1, _, _, _), tr_subject_out(To, S2, O2, _, _, _),
    tr_connector_out(To, C, CO), append(CO, O2, O3), append(O1, O3, Outs).
tr_subject_out(To, np(D, M, As, N, Number), Outs, third, Number, Noun) :- !, tr_np_out(To, np(D, M, As, N, Number), Outs, Noun, Number).
%% a phrase with a reduced relative on it is still a phrase: the person and
%% number are its noun's, and tr_np_out/5 writes the participle and the agent
tr_subject_out(To, rel(NP, L, Cs), Outs, third, Number, Noun) :- !, tr_np_out(To, rel(NP, L, Cs), Outs, Noun, Number).
tr_subject_out(To, rc(NP, R, S), Outs, third, Number, Noun) :- !, tr_np_out(To, rc(NP, R, S), Outs, Noun, Number).
%% the subject a relative word stands for is written as nothing: the verb
%% takes the person and number of the phrase the clause sits on
tr_subject_out(_, gap(P, N), [], P, N, none) :- !.
tr_subject_out(To, with(NP, PPs), Outs, third, Number, Noun) :-
    tr_np_out(To, NP, O1, Noun, Number), tr_comps_out(To, PPs, Noun, Number, _, O2, _), append(O1, O2, Outs).

%% the connector out: a comma as itself, a word through the lesson
tr_connector_out(_, comma, [o(',', comma)]) :- !.
tr_connector_out(_, w(',', lcomma), [o(',', comma)]) :- !.
tr_connector_out(_, semicolon, [o(';', comma)]) :- !.
tr_connector_out(To, w(W, C), [o(T, C)]) :- tr_word_across(w(W, lower), To, conjunction, T).

%% what a question word asks for, out: the word itself, or `which' with its phrase
tr_asked_out(_, none, []) :- !.
tr_asked_out(_, subject(_), []) :- !.                                    % the subject out already carries it
tr_asked_out(To, object(which_np(NP, C)), Outs) :- !,
    tr_which_word(To, QT), tr_np_out(To, NP, NPOut, _, _),
    tr_marker(To, NP, M), append(M, [o(QT, C)|NPOut], Outs).
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
tr_question_across(foreign, _, E, Q) :- tr_solve(mean(Q, E)), !.
tr_question_across(foreign, object, whom, Q) :- tr_solve(mean(Q, who)), !.       % whom is who as an object

tr_which_word(english, which).
tr_which_word(foreign, W) :- once(tr_solve(mean(W, which))).
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
%% AN ELIDED FORM IS THE WORD IT ELIDES, here as it is in tr_object_pronoun/3:
%% `La sinistra L'ha attaccata' split the clitic off correctly and then had no
%% meaning to cross it by, because an elision has no mean/2 row of its own.
tr_pronoun_across(To, Role, w(W, C), P, N, T) :-
    tr_solve(elision_of(W, F)), F \== W,
    tr_pronoun_across(To, Role, w(F, C), P, N, T), !.
tr_pronoun_across(foreign, Role, w(W, _), _, _, T) :-
    findall(T0, ( tr_solve(mean(T0, W)), tr_class_of(T0, pronoun) ), Ts0), Ts0 \== [],
    tr_pronouns_first(Ts0, Ts1),
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
    findall(T0, ( tr_solve(mean(T0, S)), tr_class_of(T0, pronoun) ), Ts0), tr_pronouns_first(Ts0, Ts),
    member(T1, Ts), ( Role == subject -> tr_subject_pronoun(foreign, T1, _, _) ; true ),
    tr_inflect(foreign, pronoun, T1, plural, T), !.
tr_pronoun_across(foreign, Role, w(W, _), _, _, T) :- Role \== subject, tr_solve(mean(T, W)), !.

%% the words that are pronouns and nothing else first: `esto' stands alone
%% where `este' is the demonstrative too, and a vocabulary gives the
%% demonstrative's line before the pronoun's
tr_pronouns_first(Ts, Out) :-
    findall(T, ( member(T, Ts), \+ tr_class_of(T, demonstrative), \+ tr_class_of(T, determiner) ), Pure),
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
tr_np_out(To, rc(NP, Role, S), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, NPOut, Noun, Number),
    tr_relative_out(To, Role, Noun, Number, RelOut),
    (   S = s(A, gap, G, Cs) -> S1 = s(A, gap(third, Number), G, Cs) ; S1 = S ),
    tr_write_nested(To, S1, SOut),
    append(NPOut, RelOut, O1), append(O1, SOut, Outs).
tr_np_out(To, rel(NP, L, Comps), Outs, Noun, Number) :- !,
    tr_np_out(To, NP, NPOut, Noun, Number),
    (   To == english
    ->  tr_lexeme_across(L, english, LT), en_participle_of(LT, PP)
    ;   tr_lexeme_across(L, foreign, LT),
        ( tr_gender(Noun, G0), G0 \== none -> G = G0 ; G = masculine ),
        tr_with_gender(G, tr_participle_agreeing(LT, Number, PP))
    ),
    tr_comps_out(To, Comps, Noun, Number, _, CompOuts, _),
    append(NPOut, [o(PP, lower)|CompOuts], Outs).
tr_np_out(To, adv(w(A, C)), [o(AT, C)], none, singular) :- !, tr_word_across(w(A, lower), To, adverb, AT).
tr_np_out(_, name(W), [o(W, upper)], none, singular) :- !.
%% a phrase whose noun was left out: the article and the adjectives, agreeing
%% with the gender the source's article lent it; English adds `one' unless
%% the adjective is a superlative, which stands alone (`the weakest')
tr_np_out(To, np(Det, none, Adjs, elided(G0), Number), Outs, elided(G), Number) :- !,
    ( G0 \== none -> G = G0 ; G = masculine ),
    tr_adjectives_out(To, Adjs, elided(G), Number, AdjOuts), tr_adj_words(AdjOuts, AOs),
    tr_det_out(To, Det, elided(G), Number, AOs, DetOut),
    (   To == english, \+ memberchk(deg(superlative, _), Adjs)
    ->  ( Number == plural -> One = [o(ones, lower)] ; One = [o(one, lower)] )
    ;   One = []
    ),
    append(DetOut, AOs, O1), append(O1, One, Outs).
%% ... and one with a `de' phrase: English's `those' or `the one'; the
%% lesson's article where it says the article REPLACES the noun (`The word
%% "el" replaces the noun.', Spanish's `los de'), and otherwise its pronoun
%% for `that' in the gender and the number (Italian's `quelli di')
tr_np_out(english, ell(_, _, Number, PP), Outs, none, Number) :- !,
    ( Number == plural -> Head = [o(those, lower)] ; Head = [o(the, lower), o(one, lower)] ),
    tr_comp_out(english, PP, none, Number, _, PPOut, _), append(Head, PPOut, Outs).
tr_np_out(foreign, ell(Det, G0, Number, PP), Outs, elided(G), Number) :- !,
    ( G0 \== none -> G = G0 ; G = masculine ),
    (   Det = det(_, DL, _), tr_meanings_of(DL, foreign, article, Ms), member(A, Ms), tr_solve(replace(A, noun))
    ->  tr_det_out(foreign, Det, elided(G), Number, [], Head)
    ;   findall(P, ( tr_solve(mean(P, that)), tr_class_of(P, pronoun) ), Ps), Ps \== [],
        tr_agree(foreign, Ps, elided(G), P1), tr_inflect(foreign, pronoun, P1, Number, PF), Head = [o(PF, lower)]
    ),
    tr_comp_out(foreign, PP, none, Number, _, PPOut, _), append(Head, PPOut, Outs).
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
tr_np_out(To, np(Det, Num, Adjs, w(NW, NC), Number), Outs, Noun, Number) :-
    tr_noun_lexeme(To, NW, Number, L, Noun),
    tr_inflect(To, noun, Noun, Number, NounForm),
    tr_adjectives_out(To, Adjs, Noun, Number, AdjOuts),
    tr_order(To, o(NounForm, NC), AdjOuts, Content),
    ( Num == none -> NumOut = [] ; Num = w(MW, MC), tr_word_across(w(MW, MC), To, number, MT), NumOut = [o(MT, MC)] ),
    tr_det_out(To, Det, Noun, Number, Content, DetOut),
    append(DetOut, NumOut, Front), append(Front, Content, Outs).

tr_lexeme_here(W, L) :- tr_side_here(Side), tr_lexeme(Side, W, L, _), !.

%% the phrase's noun as a lexeme, and its noun on the other side: the
%% reading of the word that is a noun in the phrase's number, with a
%% meaning the lesson calls a noun -- `houses' is a verb's form too (to
%% house, `aloja'), and a word known as one is known as itself first
tr_noun_lexeme(To, NW, Number, L, Noun) :-
    tr_side_here(Side),
    (   tr_lexeme(Side, NW, L0, Number), tr_meanings_of(L0, To, noun, [N0|_]), ( To == foreign -> tr_class_of(N0, noun) ; true )
    ->  L = L0, Noun = N0
    ;   tr_lexeme_here(NW, L), tr_meanings_of(L, To, noun, [Noun|_])
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
%% an adjective marked to stand before its noun: `pre' is no adjective the
%% lesson has a rule for, so tr_sides/3 puts it before the noun
tr_adjective_out(To, pre(A), Noun, Number, a(pre, Os)) :- !, tr_adjective_out(To, A, Noun, Number, a(_, Os)).
%% an adjective with its intensifier: the adverb first in every language,
%% the adjective agreeing as it would alone -- `così pacifica', `so peaceful'
tr_adjective_out(To, int(w(A, AC), J), Noun, Number, a(L, [o(AT, AC)|JO])) :- !,
    tr_word_across(w(A, lower), To, adverb, AT), tr_adjective_out(To, J, Noun, Number, a(L, JO)).
tr_adjective_out(To, w(W, C), Noun, Number, a(L, [o(T, C)])) :-
    tr_adjective_form(To, W, Noun, Number, L, T).
%% a degree: English's own ending, or the word the lesson puts in front
tr_adjective_out(To, deg(D, w(W, C)), Noun, Number, a(L, Outs)) :-
    tr_adjective_form(To, W, Noun, Number, L, T),
    (   To == english -> en_degree_out(D, T, C, Outs)
    ;   tr_degree_out(M), Outs = [o(M, lower), o(T, C)]
    ).

tr_adjective_form(To, W, Noun, Number, L, T) :-
    tr_lexeme_here(W, WL),
    tr_meanings_of(WL, To, adjective, Ms),
    tr_agree(To, Ms, Noun, L),
    tr_inflect(To, adjective, L, Number, T).

%% English puts an adjective before its noun; the lesson's language does what
%% its rule says of each adjective, follow(A, noun), and English's order otherwise
tr_order(english, Noun, Adjs0, Outs) :-
    tr_names_last(Adjs0, Adjs, Names),
    tr_adj_words(Adjs, Os), tr_adj_words(Names, Ns), append(Os, [Noun|Ns], Outs).
tr_order(foreign, Noun, Adjs0, Outs) :-
    tr_names_last(Adjs0, Adjs, Names), tr_adj_words(Names, Ns),
    tr_sides(Adjs, Before, After0), append(After0, Ns, After),
    append(Before, [Noun|After], Outs).

%% A NAME APPOSED TO A NOUN FOLLOWS IT IN EVERY LANGUAGE -- `il presidente
%% Scalfaro', `the president Scalfaro' -- and the adjective rules do not
%% place it: measured, `del Scalfaro presidente' and `Il Chevènement
%% ministro' before this
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
    (   tr_holds(follow(L, noun)) -> Before = Before1, append(Os, After1, After)
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
tr_det_form(Kind, DL, Noun, Number, Content, T) :-
    tr_meanings_of(DL, foreign, Kind, Ms),
    tr_gender(Noun, G),
    findall(M, ( member(M, Ms), G \== none, tr_gender(M, G) ), Gs), findall(M, ( member(M, Ms), tr_gender(M, none) ), Ns),
    append(Gs, Ns, Cands0), ( Cands0 == [] -> Cands = Ms ; Cands = Cands0 ),
    (   Content = [o(Next, _)|_], atom(Next), member(L0, Cands), tr_solve(come_before(L0, P)), begin_with(Next, P) -> L = L0
    ;   member(L0, Cands), \+ tr_solve(come_before(L0, _)) -> L = L0
    ;   Cands = [L|_]
    ), !,
    tr_inflect(foreign, Kind, L, Number, T).

%% the complements out: objects and predicates in place, the adverbs last,
%% and an object pronoun the lesson puts before the verb kept aside for it
tr_comps_out(_, [], _, _, [], [], []).
tr_comps_out(To, [C|Cs], Noun, Number, Clitics, Outs, Advs) :-
    tr_comp_out(To, C, Noun, Number, Clitic, Out, Adv),
    tr_comps_out(To, Cs, Noun, Number, Clitics1, Outs1, Advs1),
    append(Clitic, Clitics1, Clitics), append(Out, Outs1, Outs), append(Adv, Advs1, Advs).

tr_comp_out(_, sep, _, _, [], [o(',', comma)], []) :- !.
tr_comp_out(To, obj(NP), _, _, [], Outs, []) :- tr_np_out(To, NP, O1, _, _), tr_marker(To, NP, M), append(M, O1, Outs).
tr_comp_out(To, adj(Ws), Noun, Number, [], Outs, []) :- tr_adjectives_out(To, Ws, Noun, Number, As), tr_adj_words(As, Outs).
%% an object complement: the adjectives agree with the OBJECT, whose noun
%% and number tr_np_out/5 answers, and they go before the object in the
%% lesson's language and after it in English
tr_comp_out(To, oc(NP, Ws), _, _, [], Outs, []) :-
    tr_np_out(To, NP, O1, Noun, Number), tr_marker(To, NP, M), append(M, O1, Obj),
    tr_adjectives_out(To, Ws, Noun, Number, As), tr_adj_words(As, AOut),
    ( To == english -> append(Obj, AOut, Outs) ; append(AOut, Obj, Outs) ).
%% a `that' clause: the word, and the clause written as a statement
tr_comp_out(To, that(S), _, _, [], [o(W, lower)|SOut], []) :- !,
    tr_that_word(To, W), tr_write_nested(To, S, SOut).

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
tr_comp_out(To, ger(L, Cs), Noun, Number, [], [o(G, lower)|COut], []) :- !,
    tr_lexeme_across(L, To, LT), tr_gerund_out(To, LT, G),
    tr_comps_out(To, Cs, Noun, Number, _, CO, CA), append(CO, CA, COut).
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
    once(( tr_solve(begin(P0, purpose)), P = P0 )).
tr_comp_out(To, inf(L), _, _, [], Outs, []) :-
    tr_lexeme_across(L, To, LT),
    (   To == english
    ->  en_base(LT, B), ( tr_modal_verb -> Outs = [o(B, lower)] ; Outs = [o(to, lower), o(B, lower)] )
    ;   once(tr_solve(infinitive_of(Inf, LT))), Outs = [o(Inf, lower)]
    ).
tr_comp_out(english, opron(w(W, C)), _, _, [], [o(T, C)], []) :- tr_pronoun_across(english, object, w(W, C), _, _, T).
tr_comp_out(foreign, opron(w(W, C)), _, _, Clitics, Outs, []) :-
    tr_pronoun_across(foreign, object, w(W, C), _, _, T),
    ( tr_holds(precede(T, verb)) -> Clitics = [o(T, C)], Outs = [] ; Clitics = [], Outs = [o(T, C)] ).

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
    ->  tr_imperative_form(L, Neg, IF), VW = [o(IF, lower)]
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

tr_fronts_out(_, [], []).
tr_fronts_out(To, [C|Cs], Outs) :-
    tr_comp_out(To, C, none, singular, _, O1, A1), append(O1, A1, O),
    tr_fronts_out(To, Cs, Os), append(O, Os, Outs).

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
    en_copula_form(P, N, T, C), en_participle_of(L, PP),
    Front = o(C, lower),
    ( Neg == yes -> Tail = [o(not, lower), o(PP, lower)] ; Tail = [o(PP, lower)] ),
    Statement = [Front|Tail].
en_group(L, P, N, T, passive_perfect, Neg, Statement, Front, Tail) :- !,
    ( T == past -> H = had ; ( P == third, N == singular ) -> H = has ; H = have ),
    en_participle_of(L, PP),
    Front = o(H, lower),
    ( Neg == yes -> Tail = [o(not, lower), o(been, lower), o(PP, lower)] ; Tail = [o(been, lower), o(PP, lower)] ),
    Statement = [Front|Tail].

%% -- and `is' with a gerund after it (`is being careful') is CUT AND THEN
%% REFUSED on purpose: the copula has no progressive this writes, and
%% falling through to the clause below would put the stemmer on `is'
en_group(is, P, N, T, A, Neg, Statement, Front, Tail) :- !,
    A \== progressive,
    ( Neg == yes -> Not = [o(not, lower)] ; Not = [] ),
    (   A == perfect
    ->  en_have(P, N, T, H), Front = o(H, lower), append(Not, [o(been, lower)], Tail)
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
    ->  en_have(P, N, T, H), en_participle_of(L, PP), Front = o(H, lower), append(Not, [o(PP, lower)], Tail), Statement = [Front|Tail]
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

en_do(_, _, past, did) :- !.
en_do(third, singular, _, does) :- !.
en_do(_, _, _, do).

en_base(has, have) :- !.
en_base(V, B) :- reason_base(V, B).

%% the past of a verb the lesson gave in the third person: one the lesson
%% stated (`"ate" is the past of "eats"'), `had', or the regular -ed --
%% lived, carried, walked; the participle stated, or the past
en_past_of(V, P) :- tr_solve(past_of(P0, V)), !, P = P0.
en_past_of(has, had) :- !.
en_past_of(V, P) :- en_base(V, B), tr_english_ed(B, P).

en_participle_of(V, PP) :- tr_solve(participle_of(P0, V)), !, PP = P0.
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
                     \+ tr_determiner(foreign, w(M, lower), _, _) ), Ms5), Ms5 \== []
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
    ;   To == english, From == foreign, memberchk(Class, [noun, adjective]),
        Ms0 = [M1|_], tr_solve(mean_as(L, M1, _)), \+ tr_solve(mean_as(L, M1, Class)),
        findall(M, ( member(M, Ms0), tr_solve(mean_as(L, M, Class)) ), Ms3), Ms3 \== []
    ->  Ms = Ms3
    ;   To == english, tr_english_shaped(Class, Ms0, Ms1), Ms1 \== []
    ->  Ms = Ms1
    %% and the mirror of the determiner rule, for the other side: a word
    %% that names NOBODY is no head of a phrase either. Spanish gives `one'
    %% to the impersonal `se' and to `uno', and with no meaning classed a
    %% noun the first won -- `uno de los paises' came out `se de los ...'
    ;   To == foreign, memberchk(Class, [noun, adjective]),
        findall(M, ( member(M, Ms0), \+ tr_solve(impersonal(M)),
                     \+ tr_determiner(foreign, w(M, lower), _, _) ), Ms2), Ms2 \== []
    ->  Ms = Ms2
    ;   Ms = Ms0
    ).

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
tr_third_shaped(M) :- ( M == is ; M == has ; reason_base(M, B), B \== M ), !.

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
tr_lexeme(_, W, W, singular) :- tr_digits(W), !.
tr_lexeme(Side, W, W, singular) :- tr_known(Side, W).
tr_lexeme(english, an, a, singular) :- tr_known(english, a).
tr_lexeme(Side, W, S, plural) :- tr_solve(plural_of(W, S)), tr_known(Side, S).
tr_lexeme(foreign, W, S, plural) :- tr_rule_stem(W, plural, S), tr_known(foreign, S), tr_rule_plural(S, W).
tr_lexeme(english, W, S, plural) :- reason_base(W, S), S \== W, tr_known(english, S).
%% AN ELIDED FORM IS ITS OWN WORD: `l'' is `lo' or `la' with the vowel gone,
%% and everything the lesson says of what it elides is true of it. The
%% lesson names the pair (`"l'" is the elision of "lo"'), so a language
%% that elides nothing has no row here and this clause never fires.
tr_lexeme(foreign, W, S, N) :- tr_solve(elision_of(W, F)), tr_lexeme(foreign, F, S, N).

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
    (   L == none
    ->  findall(E, catch(clause(take_in(_, E, T), _), error(_, _), fail), Es0)
    ;   findall(E, ( tr_solve_plain(lesson(L, (take_in(_, E, T) :- _)))
                     ; tr_namespaced(L, take_in(_, E, T), F), catch(clause(F, _), error(_, _), fail) ), Es0)
    ),
    findall(E, ( member(E, Es0), atom(E) ), Es1), sort(Es1, Es).

tr_digits(W) :- atom(W), atom_codes(W, Cs), Cs \== [], forall(member(C, Cs), ( C >= 0'0, C =< 0'9 )).

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

%% a verb form of the lesson's language, taken apart: the lexeme, the
%% number, the tense, the person. A person form the lesson stated first
%% (`"como" is the first person of "come"'); a third person is a present
%% form, singular or plural, or the past or the future of one, or a stated
%% plural of such a tense form
tr_form(W, L, N, T, P) :-
    tr_solve(person_of(W, F)), ( tr_solve(first(W)) -> P = first ; tr_solve(second(W)) -> P = second ),
    tr_form_nt(F, L, N, T).
tr_form(W, L, N, T, third) :- tr_form_nt(W, L, N, T).

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
tr_inflect(To, _, S, plural, P) :- tr_solve(plural_of(P0, S)), \+ ( To == english, tr_known(foreign, S) ), !, P = P0.
tr_inflect(foreign, _, S, plural, P) :- !, tr_rule_plural(S, P).
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
%% `can', `might' of `may'; `must' and `should' have no other form
en_modal_form(can, can, present).      en_modal_form(could, can, past).
en_modal_form(may, may, present).      en_modal_form(might, may, conditional).
en_modal_form(must, must, present).    en_modal_form(should, should, present).
en_modal_out(can, present, can).       en_modal_out(can, past, could).      en_modal_out(can, conditional, could).
en_modal_out(may, present, may).       en_modal_out(may, past, might).      en_modal_out(may, conditional, might).
en_modal_out(must, present, must).     en_modal_out(should, present, should).

%% English's demonstratives and the determiners a lesson may give a word
%% for, each with its lexeme and its number: `these' is `this' in the
%% plural, `many' is `much', `other' is `another'; `some' is either
en_det(this, this, singular).       en_det(these, this, plural).
en_det(that, that, singular).       en_det(those, that, plural).
en_det(another, another, singular). en_det(other, another, plural).
en_det(much, much, singular).       en_det(many, much, plural).
en_det(each, each, singular).       en_det(every, every, singular).   en_det(little, little, singular).
en_det(several, several, plural).   en_det(both, both, plural).       en_det(few, few, plural).
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

%% what a word is: English's own tables first, then its lexeme's class --
%% which the lesson says of its own words, and an English word is what
%% any of its translations is
tr_is(english, w(W, _), preposition) :- en_preposition(W), !.
tr_is(english, w(W, _), conjunction) :- W == and, !.

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
tr_is(english, w(W, _), number) :- en_number(W), !.
tr_is(Side, w(W, _), Class) :- tr_lexeme(Side, W, L, _), tr_class(Side, L, Class), !.
tr_class(_, W, number) :- tr_digits(W), !.
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
tr_lesson(L, G) :- tr_namespaced(L, G, F), tr_solve_plain(F).
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
    tr_glue(As1, As),
    atomic_list_concat(As, ' ', S0),
    tr_cap(S0, S1),
    tr_stop_parts(Stop, Before, StopCode, After),
    atom_codes(S1, Cs), append(Cs, [StopCode], Cs1), atom_codes(Out0, Cs1),
    (   To == foreign, Kind == question, once(tr_solve(begin(M, question))) -> atom_concat(M, Out0, Out1)
    ;   Out1 = Out0
    ),
    %% the marks round a quoted sentence go outside everything, the
    %% question's own opening mark included: `"¿Cómo ...?".'
    atom_codes(Out1, C1), append(Before, C1, C2), append(C2, After, C3), atom_codes(Out, C3).

%% a comma at the end, or after another, is dropped: an apposition's closing
%% comma where the sentence ends, or where a clause's comma follows it
tr_tidy_commas([], []).
tr_tidy_commas([',', ','|As], Out) :- !, tr_tidy_commas([','|As], Out).
tr_tidy_commas([','], []) :- !.
tr_tidy_commas([A|As], [A|Out]) :- tr_tidy_commas(As, Out).

%% a comma joins the word before it with no space between
tr_glue([A, ','|Rest], Out) :- !, atom_concat(A, ',', A1), tr_glue([A1|Rest], Out).
tr_glue([A, ';'|Rest], Out) :- !, atom_concat(A, ';', A1), tr_glue([A1|Rest], Out).
tr_glue([A|As], [A|Out]) :- !, tr_glue(As, Out).
tr_glue([], []).

%% a quoted word gets its marks back: both for one word, the opening one on
%% the head of a run and the closing one on its last word
tr_word_text(_, T, qboth, A) :- !, atomic_list_concat(['"', T, '"'], A).
tr_word_text(_, T, qopen, A) :- !, atomic_list_concat(['"', T], A).
tr_word_text(_, T, qclose, A) :- !, atomic_list_concat([T, '"'], A).

tr_word_text(english, i, _, 'I') :- !.
tr_word_text(_, T, upper, A) :- !, tr_cap(T, A).
tr_word_text(_, T, _, T).

%% the first letter up: an ASCII one, or one of U+00E0..U+00FE, the two
%% bytes 195 and 160..190 in UTF-8 (`él' is `Él'); the division sign is
%% no letter
tr_cap(W, C) :- atom_codes(W, [195, B|R]), B >= 160, B =< 190, B =\= 183, !, B1 is B - 32, atom_codes(C, [195, B1|R]).
tr_cap(W, C) :- atom_codes(W, [F|R]), ( F >= 97, F =< 122 -> F1 is F - 32 ; F1 = F ), atom_codes(C, [F1|R]).
