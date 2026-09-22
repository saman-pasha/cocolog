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
%%     language(L)                     the language, `Spanish is a language'
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
%% group (the lexeme, its tense, simple or perfect, denied or not), and
%% the complements in order -- an object, a predicative adjective, a
%% prepositional phrase, an object pronoun, an adverb. A question is first
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
%% article, a possessive or a number, then its content: the noun is the
%% word the lesson calls one (failing that the last word in English and,
%% where adjectives follow the noun, the first), and every other word is
%% an adjective; the noun's number is the phrase's. Where the target is
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
%% with no subject takes the pronoun its verb says -- I, you, we, they --
%% and the denial's word goes before the verb, or after it when
%% follow(N, verb) proves. A capitalised word no lesson knows is a name
%% and passes through; the head of a sentence goes lower when it is a
%% word the lesson knows, because a question moves it.
%%
%% ---- WHAT IT IS NOT ---------------------------------------------------
%%
%% It is not a translator of prose. One clause with one verb and at most
%% an infinitive after it: no relative clause, no `because', no passive,
%% no imperative, no subjunctive, no `why' or `how', no idiom -- a word
%% means a word, and `is' is whichever word the lesson gave for it first
%% (a lesson with `es' and `está' for `is' gets `es', and the progressive
%% takes the AUXILIARY that means `is'). `There is' is the present only:
%% a lesson states no past of `hay'.
%% A past that spells like a present form (`read') is read as the present.
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
                            atom_codes(StopA, [Stop]), atom_concat(P1, StopA, Sentence),
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
                            atom_codes(StopA, [Stop]), atom_concat(P1, StopA, Sentence),
                            tr_ir_page_one(Piece, Stop, From, Into, Out) ),
            Lines).

tr_ir_page_one(Piece, Stop, From, Into, Out) :-
    (   catch(( tr_read_ir(Piece, Stop, From, S), tr_write_ir(Into, S, Stop, Out0) ), _, fail) -> Out = Out0
    ;   atom_codes(A, Piece), reason_untranslated(A, From, Words), Out = refused(Words)
    ).

tr_each_ir([], _, []).
tr_each_ir([Piece-Stop|Ps], From, [ir(S, Stop)|Ss]) :-
    tr_read_ir(Piece, Stop, From, S),
    tr_each_ir(Ps, From, Ss).

tr_read_ir(Piece, Stop, From, S) :-
    reason_tokens(Piece, Tokens), tr_words(Tokens, Words0), Words0 \== [],
    tr_from_side(From, Words0, Side),
    tr_head_lower(Side, Words0, Words1),
    tr_expand(Side, Words1, Words),
    tr_kind(Stop, Kind),
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
    forall(member(T, Terms), tr_learn_term(Language, T)).

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
    findall(W, ( member(Piece-_, Pieces), reason_tokens(Piece, Tokens), tr_words(Tokens, Ws0c),
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
    member(w(W, Case), Ws),
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
tr_each([Piece-Stop|Ps], Way, [Out|Outs]) :-
    reason_tokens(Piece, Tokens), tr_words(Tokens, Words0), Words0 \== [],
    tr_way(Way, Words0, From, To),
    tr_head_lower(From, Words0, Words1),
    tr_expand(From, Words1, Words),
    tr_translate(Words, From, To, Stop, Out),
    tr_each(Ps, Way, Outs).

%% a contraction the lesson states -- `"al" is the contraction of "a el"' --
%% is read as its words, and written back as itself (tr_contract/3)
tr_expand(english, Ws, Ws) :- !.
tr_expand(foreign, [], []).
%% a comma is carried through untouched: it is no word and has nothing to
%% expand, and the clause splitter still needs to see it
tr_expand(foreign, [comma|Ws], [comma|Out]) :- !, tr_expand(foreign, Ws, Out).
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
tr_pieces(Text, Pieces) :- tr_codes(Text, Codes), tr_split(Codes, Pieces).

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
    tr_kind(Stop, Kind),
    tr_into_ir(From, Kind, Words, S),
    tr_from_ir(To, Kind, S, Stop, Out).

tr_kind(63, question) :- !.                                               % 63 is `?'
tr_kind(_, statement).

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
tr_into_ir(Side, Kind, Words, S) :-
    nb_setval('$tr_from', Side),
    tr_read(Side, Kind, Words, S0),
    tr_cross(Side, S0, S).

%% out of the IR: the IR's side IS English, so the writer crosses from it
%% -- into the lesson's language as it always did, and into English by
%% the identity above
tr_from_ir(To, Kind, S, Stop, Out) :-
    nb_setval('$tr_from', english),
    tr_write(To, Kind, S, Outs),
    tr_join(To, Kind, Outs, Stop, Out).

%% ---- into the IR: the crossing walk ----------------------------------------------

%% the same lookups the writer into English makes, made once over the
%% term rather than over the words coming out of it -- so a sentence read
%% on the lesson's side becomes the same term an English sentence reads
%% as, and anything that can write one can write the other
%% two clauses joined: the connector crosses to English as the word it is,
%% and each side crosses as the sentence it is
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
tr_cross_subject(_, there, there) :- !.
tr_cross_subject(_, name(W), name(W)) :- !.
tr_cross_subject(_, null(P, N), null(P, N)) :- !.
tr_cross_subject(_, impersonal, impersonal) :- !.
tr_cross_subject(_, pronoun(P, N, w(W, C)), pronoun(P, N, w(T, C))) :- !, tr_pronoun_across(english, subject, w(W, C), P, N, T).
tr_cross_subject(A, and(S1, S2), and(T1, T2)) :- !, tr_cross_subject(A, S1, T1), tr_cross_subject(A, S2, T2).
tr_cross_subject(_, with(NP0, PPs0), with(NP, PPs)) :- !, tr_cross_np(NP0, NP), tr_cross_comps(PPs0, PPs).
tr_cross_subject(_, NP0, NP) :- tr_cross_np(NP0, NP).

%% a phrase, across: the noun's lexeme in English, the determiner as the
%% word of its kind (never the form -- the number inflects it on the way
%% out), a number word, and each adjective's first meaning
tr_cross_np(name(W), name(W)) :- !.
tr_cross_np(pronoun(w(W, C)), pronoun(w(T, C))) :- !, tr_pronoun_across(english, oblique, w(W, C), _, _, T).
tr_cross_np(and(N1, N2), and(T1, T2)) :- !, tr_cross_np(N1, T1), tr_cross_np(N2, T2).
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

tr_cross_adjective(w(W, C), w(and, C)) :- tr_side_here(Side), tr_is(Side, w(W, C), conjunction), !.
tr_cross_adjective(w(W, C), w(T, C)) :- tr_lexeme_here(W, WL), tr_meanings_of(WL, english, adjective, [T|_]).

%% the complements, across, each in its place
tr_cross_comps([], []).
tr_cross_comps([C0|Cs0], [C|Cs]) :- tr_cross_comp(C0, C), tr_cross_comps(Cs0, Cs).

tr_cross_comp(obj(NP0), obj(NP)) :- !, tr_cross_np(NP0, NP).
tr_cross_comp(adj(Ws0), adj(Ws)) :- !, tr_cross_adjectives(Ws0, Ws).
tr_cross_comp(pp(w(P, C), NP0), pp(w(PT, C), NP)) :- !, tr_word_across(w(P, lower), english, preposition, PT), tr_cross_np(NP0, NP).
tr_cross_comp(adv(w(A, C)), adv(w(AT, C))) :- !, tr_word_across(w(A, lower), english, adverb, AT).
tr_cross_comp(inf(L), inf(LT)) :- !, tr_lexeme_across(L, english, LT).
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
tr_read(Side, Kind, Words0, S) :-
    tr_uncomma(Words0, Plain),
    tr_normalise(Side, Kind, Plain, Words, Asked),
    tr_read_statement(Side, Words, Asked, S), !.
tr_read(Side, Kind, Words0, S) :-
    tr_clause_split(Side, Words0, Left, Conn, Right),
    tr_read(Side, Kind, Left, S1),
    tr_read(Side, statement, Right, S2), !,
    S = join(Conn, S1, S2).

%% the first division whose two sides both read: a connecting word the
%% lesson gives (`e', `ma', `perche'), or a bare comma. The connector
%% travels as the word it was written with and crosses through mean/2 like
%% every other word; a comma has no word and travels as the atom.
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
    Ws \== [], \+ memberchk(Ws, [[comma]]).

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
fo_agreeing(Words, third, N) :- tr_np(foreign, Words, np(_, _, _, _, N1)), !, N1 == N.

%% the subject after the verb: a name, a pronoun, or a phrase up to the next
%% determiner, name, pronoun or preposition
fo_np_words_after([w(W, upper)|Rest], [w(W, upper)], Rest) :- \+ tr_known_word(foreign, W), !.
fo_np_words_after([w(P, C)|Rest], [w(P, C)], Rest) :- tr_subject_pronoun(foreign, P, _, _), !.
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
    tr_complements(Side, After, Comps), Comps = [obj(_)|_], !,
    S = s(none, there, g(L, T, simple, Neg), Comps).
tr_read_statement(Side, Words0, Asked, S) :-
    tr_negation(Side, Words0, Words, Neg),
    tr_group_from(Side, Words, Before, g(L, T, A, FP, FN), After),
    nb_setval('$tr_read_group', L),                           % for the complements: a bare base after a modal
    tr_split_clitics(Side, Before, Asked, FP, FN, SubjectWords, Clitics),
    tr_subject(Side, Asked, SubjectWords, FP, FN, Subject),
    tr_complements(Side, After, Comps0), !,                   % the cut once the WHOLE statement read: `house'
                                                              % is a verb's form, and `The house is big' must
                                                              % go on to the group at `is' when `is big' is no complement
    findall(opron(W), member(W, Clitics), Cs),
    append(Cs, Comps0, Comps),
    tr_existential_fix(Side, s(Asked, Subject, g(L, T, A, Neg), Comps), S).

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

%% an object pronoun that is no tonic one (`esto', `estas' stand after the
%% verb, never before it); before a fronted verb, one that could not be
%% the subject standing in its place (`¿Ella come el pan?' is she, in order)
tr_clitic(fronted, C) :- !, tr_object_pronoun(foreign, C, _), \+ tr_tonic_word(C), \+ tr_subject_pronoun(foreign, C, _, _).
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
tr_subject_shape(subject(_), Words, _, _) :- !, Words == [].
tr_subject_shape(fronted, Words, _, _) :- !, Words == [].
tr_subject_shape(_, [], P, N) :- !, ( P \== third ; N == plural ).
tr_subject_shape(_, [w(W, _)], P, N) :- tr_subject_pronoun(foreign, W, P1, N1), !, P1 == P, N1 == N.
tr_subject_shape(_, [w(W, _)], P, N) :- tr_impersonal(foreign, W), !, P == third, N == singular.
tr_subject_shape(_, [w(W, upper)], _, _) :- \+ tr_known_word(foreign, W), !.
tr_subject_shape(_, Words, _, _) :-
    tr_conjunction_split(foreign, Words, W1, W2), !,
    tr_subject_shape(none, W1, third, singular), tr_subject_shape(none, W2, third, singular).
tr_subject_shape(_, Words, _, _) :-
    \+ ( member(w(X, _), Words), tr_object_pronoun(foreign, X, _), \+ tr_determiner(foreign, w(X, lower), _, _) ),
    \+ ( last(Words, w(X, _)), tr_object_pronoun(foreign, X, _) ),
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
tr_group_at(english, [w(H, _), w(P, _)|R], g(L, T, perfect, third, singular), R) :-
    memberchk(H, [has, have, had]), en_participle(P, L), !, ( H == had -> T = past ; T = present ).
tr_group_at(english, [w(D, _), w(B, _)|R], g(L, T, simple, third, singular), R) :-
    memberchk(D, [does, do, did]), en_verb_form(B, L, present), !, ( D == did -> T = past ; T = present ).
tr_group_at(english, [w(M, _)|R], g(L, T, simple, third, singular), R) :-
    en_modal_form(M, L, T), tr_known(english, L), tr_class(english, L, modal), !.
tr_group_at(english, [w(C, _), w(G, _)|R], g(L, T, progressive, P, N), R) :- en_copula(C, P, N, T), en_gerund(G, L), !.
tr_group_at(english, [w(C, _)|R], g(is, T, simple, P, N), R) :- en_copula(C, P, N, T), !.
tr_group_at(english, [w(V, _)|R], g(L, T, simple, third, singular), R) :- en_verb_form(V, L, T), !.
%% the lesson's language: the auxiliary that means `is' and a gerund, the
%% progressive; an auxiliary's form and a participle, the perfect; a
%% verb's or a modal's form
tr_group_at(foreign, [w(A, _), w(G, _)|R], g(L, T, progressive, Person, N), R) :-
    tr_form(A, AL, N, T, Person), tr_solve(auxiliary(AL)), tr_solve(mean(AL, is)), tr_solve(gerund_of(G, L)), tr_known(foreign, L), !.
tr_group_at(foreign, [w(A, _), w(P, _)|R], g(L, T, perfect, Person, N), R) :-
    tr_form(A, AL, N, T, Person), tr_solve(auxiliary(AL)), tr_solve(participle_of(P, L)), tr_known(foreign, L), !.
%% -- and NOT cut on the first reading: `sono' is the first person of `è'
%% and the plural of it, and which one it is in `Le case sono grandi' the
%% subject decides, so the statement reader backtracks into the next
tr_group_at(foreign, [w(V, _)|R], g(L, T, simple, Person, N), R) :-
    tr_form(V, L, N, T, Person), tr_verb_lexeme(L).

%% a verb of the lesson's, or a modal
tr_verb_lexeme(L) :- ( tr_class_of(L, verb) -> true ; tr_class_of(L, modal) ).

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
tr_subject(Side, _, Words, _, _, and(S1, S2)) :-
    tr_conjunction_split(Side, Words, W1, W2), !,
    tr_subject(Side, none, W1, third, singular, S1), tr_subject(Side, none, W2, third, singular, S2).
tr_subject(Side, _, Words, _, _, Subject) :- tr_np(Side, Words, Subject), !.
%% a phrase and the prepositional phrases after it: `the dogs of Maria'
tr_subject(Side, _, Words, _, _, with(NP, PPs)) :-
    append(NPWords, [P|PPWords], Words), tr_is(Side, P, preposition), NPWords \== [],
    tr_np(Side, NPWords, NP), tr_complements(Side, [P|PPWords], PPs),
    forall(member(X, PPs), X = pp(_, _)), !.

%% `Maria and Omar', `the bread and the egg': two phrases, each with a
%% noun, a name or a pronoun of its own
tr_conjunction_split(Side, Words, W1, W2) :-
    append(W1, [w(C, _)|W2], Words), tr_is(Side, w(C, lower), conjunction), W1 \== [], W2 \== [],
    tr_headed(Side, W1), tr_headed(Side, W2), !.
tr_headed(Side, Ws) :- member(w(W, _), Ws), ( tr_is(Side, w(W, lower), noun) ; tr_is_name(Side, W) ; tr_subject_pronoun(Side, W, _, _) ; tr_object_pronoun(Side, W, _) ), !.
tr_is_name(Side, W) :- \+ tr_known_word(Side, W), \+ en_function(W), \+ en_subject(W, _, _).

%% a phrase: a name; or a determiner or none, a number or none, then the
%% content -- one noun (the word the lesson calls one, failing that the last
%% word in English and, where adjectives follow the noun, the first) and
%% the rest adjectives, an `and' among them kept
tr_np(Side, [w(W, upper)], name(W)) :- \+ tr_known_word(Side, W), !.
tr_np(Side, Words0, np(Det, Num, Adjs, Noun, Number)) :-
    ( Words0 = [D|Ws1], tr_determiner(Side, D, DL, DK), Ws1 \== [] -> Det = det(DK, DL, D), Words1 = Ws1 ; Det = none, Words1 = Words0 ),
    ( Words1 = [M|Ws2], tr_is(Side, M, number), Ws2 \== [] -> Num = M, Words2 = Ws2 ; Num = none, Words2 = Words1 ),
    Words2 \== [],
    tr_noun(Words2, Side, Noun, Adjs),
    \+ tr_determiner(Side, Noun, _, _),                  % `The' alone is no phrase, whatever `el' means
    \+ ( \+ tr_is(Side, Noun, noun), tr_is(Side, Noun, verb) ),   % nor is a verb's form the lesson calls no noun (`son grandes')
    forall(member(A, Adjs), tr_adj_word(Side, A)),
    Noun = w(NW, _),
    %% the noun's number by the reading of it that IS a noun: `houses' is a
    %% verb's form too (to house), and known so before it is a plural
    ( tr_lexeme(Side, NW, NL, Number), tr_class(Side, NL, noun) -> true ; tr_lexeme(Side, NW, _, Number) ), !.

%% a word that may be an adjective in a phrase: known, and no preposition,
%% pronoun or verb -- or the `and' between two
tr_adj_word(Side, A) :- tr_is(Side, A, conjunction), !.
tr_adj_word(Side, w(W, C)) :-
    tr_lexeme(Side, W, _, _),
    \+ tr_is(Side, w(W, C), preposition), \+ tr_is(Side, w(W, C), verb), \+ tr_object_pronoun(Side, W, _), \+ tr_subject_pronoun(Side, W, _, _).

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
    ;   tr_noun_by_position(Nouns, Side, Noun)
    ),
    select(Noun, Words, Adjs).

tr_noun_by_position(Words, english, Noun) :- last(Words, Noun).
tr_noun_by_position(Words, foreign, Noun) :- ( tr_holds(follow(_, noun)) -> Words = [Noun|_] ; last(Words, Noun) ).

%% the complements after the verb: a preposition and its phrase, an object
%% pronoun, an adverb, and otherwise a phrase (or two joined, or bare
%% adjectives) up to the next of those
tr_complements(Side, Words, Comps) :- tr_complements(Side, Words, no, Comps).

%% ... with whether an object has been read: the word the lesson puts
%% before a person, with no object yet and a person after it, is the
%% OBJECT's (`Maria ve a Omar' is Omar); after an object it is the
%% preposition it is (`Maria da el libro a Omar' is to Omar)
tr_complements(_, [], _, []) :- !.
tr_complements(foreign, [w(P, _)|Ws], no, [obj(NP)|Cs]) :-
    tr_marker_word(P, Class),
    tr_phrase_words(foreign, Ws, PW, Rest), PW \== [],
    tr_phrase_np(foreign, PW, NP), tr_of_class(NP, Class), !,
    tr_complements(foreign, Rest, yes, Cs).
%% an infinitive: the lesson's (`"comer" is the infinitive of "come"'), or
%% English's `to' and a base form, and a bare base form after a modal
tr_complements(foreign, [w(V, _)|Ws], Seen, [inf(F)|Cs]) :-
    tr_solve(infinitive_of(V, F)), tr_known(foreign, F), !,
    tr_complements(foreign, Ws, Seen, Cs).
tr_complements(english, [w(to, _), w(B, _)|Ws], Seen, [inf(L)|Cs]) :-
    en_infinitive(B, L), !,
    tr_complements(english, Ws, Seen, Cs).
tr_complements(english, [w(B, _)|Ws], Seen, [inf(L)|Cs]) :-
    tr_read_modal, en_infinitive(B, L), !,
    tr_complements(english, Ws, Seen, Cs).
tr_complements(Side, [P|Ws], Seen, [pp(P, NP)|Cs]) :-
    tr_is(Side, P, preposition), !,
    (   Ws = [w(O, OC)|Rest], tr_object_pronoun_here(Side, Ws)
    ->  NP = pronoun(w(O, OC))
    ;   tr_phrase_words(Side, Ws, PW, Rest), PW \== [], tr_phrase_np(Side, PW, NP)
    ),
    tr_complements(Side, Rest, Seen, Cs).
tr_complements(Side, [w(W, C)|Ws], Seen, [opron(w(W, C))|Cs]) :-
    tr_object_pronoun_here(Side, [w(W, C)|Ws]), !,
    tr_complements(Side, Ws, Seen, Cs).
tr_complements(Side, [A|Ws], Seen, [adv(A)|Cs]) :- tr_is(Side, A, adverb), !, tr_complements(Side, Ws, Seen, Cs).
tr_complements(Side, Ws, _, [C|Cs]) :-
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [],
    (   tr_all_adjectives(Side, PW) -> C = adj(PW)
    ;   tr_phrase_np(Side, PW, NP), C = obj(NP)
    ),
    tr_complements(Side, Rest, yes, Cs).

%% a phrase, or two joined
tr_phrase_np(Side, PW, and(N1, N2)) :-
    tr_conjunction_split(Side, PW, W1, W2), !, tr_object_phrase(Side, W1, N1), tr_object_phrase(Side, W2, N2).
tr_phrase_np(Side, PW, NP) :- tr_object_phrase(Side, PW, NP).

%% the word the lesson puts before an object of a class -- `The word "a"
%% precedes the person' -- and whether a phrase is of that class: a name
%% is a person (and a name), a phrase is what the lesson calls its noun,
%% two joined are when both are, and `whom' asks for a person. The rule
%% over pronouns and the verb is not a marker.
tr_marker_word(P) :- tr_marker_word(P, _).
tr_marker_word(P, Class) :- tr_solve(precede(P, Class)), Class \== verb, !.

tr_of_class(person, person) :- !.
tr_of_class(name(_), Class) :- !, ( Class == name ; Class == person ), !.
tr_of_class(and(A, B), Class) :- !, tr_of_class(A, Class), tr_of_class(B, Class).
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
tr_phrase_words(Side, Words, PW, Rest) :-
    append(PW, Rest, Words),
    ( Rest == [] -> true ; Rest = [R|_], ( tr_is(Side, R, preposition) ; tr_is(Side, R, adverb) ; tr_object_pronoun_here(Side, Rest) ) ), !.

%% an object pronoun standing as one: not an article or a possessive with
%% its noun after it -- `la casa', `los libros', English's `her house'
tr_object_pronoun_here(Side, [w(W, _)|Ws]) :-
    tr_object_pronoun(Side, W, _),
    \+ ( tr_determiner(Side, w(W, lower), _, _), Ws = [N|_], tr_content_word(Side, N) ).
tr_content_word(Side, N) :- ( tr_is(Side, N, noun) ; tr_is(Side, N, adjective) ; tr_is(Side, N, number) ), !.

tr_object_phrase(Side, [w(W, C)], pronoun(w(W, C))) :- tr_object_pronoun(Side, W, _), !.
tr_object_phrase(Side, Words, NP) :- tr_np(Side, Words, NP).

%% the group being read is a modal, so a bare base form after it is its verb
tr_read_modal :- catch(nb_getval('$tr_read_group', L), _, fail), en_modal_out(L, _, _).

%% English's base form of a verb the lesson gives (`sleep' for `sleeps'),
%% never one of English's own words
en_infinitive(be, is) :- !.
en_infinitive(have, has) :- !.
en_infinitive(B, L) :- \+ en_own(B), reason_third(B, L), L \== B, tr_known(english, L), tr_class(english, L, verb).

%% bare adjectives, an `and' among them allowed: the predicate of a copula
tr_all_adjectives(Side, Words) :-
    Words \== [],
    forall(member(W, Words), ( tr_is(Side, W, adjective) ; tr_is(Side, W, conjunction) )),
    \+ forall(member(W, Words), tr_is(Side, W, conjunction)).

%% ---- writing ------------------------------------------------------------------

%% `there is': English's `there', the copula in the number of what there is
%% (`There are dogs') and `no' for the denial with the article dropped
%% (`There is no dog'); the lesson's verb and the phrase, no subject
%% two clauses joined: the first, the connector, the second. Only the
%% first carries the sentence's KIND -- a question mark belongs to the whole
%% -- and a comma is written with no space before it (tr_join/5).
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
    ;   fo_group(LT, third, singular, T, simple, Neg, [], Group),
        append(NPOut0, Rest, After),
        fo_assemble(none, [], [], Group, After, Outs)
    ).
tr_write(To, Kind, s(Asked, Subject, g(L, T, A, Neg), Comps), Outs) :-
    nb_setval('$tr_verb', L),
    tr_subject_out(To, Subject, SubjectOut, Person, Number, Noun),
    tr_asked_out(To, Asked, AskedOut),
    tr_lexeme_across(L, To, LT),
    tr_comps_out(To, Comps, Noun, Number, Clitics, CompOuts, Advs),
    (   To == english
    ->  en_group(LT, Person, Number, T, A, Neg, Statement, Front, Tail),
        append(CompOuts, Advs, Rest),
        en_assemble(Kind, Asked, AskedOut, SubjectOut, Statement, Front, Tail, Rest, Outs)
    ;   fo_group(LT, Person, Number, T, A, Neg, Clitics, Group),
        append(CompOuts, Advs, Rest),
        fo_assemble(Asked, AskedOut, SubjectOut, Group, Rest, Outs)
    ).

%% the verb's lexeme across: the English third person for the lesson's
%% verb, the lesson's verb for the English one -- `is' is `is' either way
%% as the copula, and the lesson's word for it
tr_lexeme_across(L, To, LT) :- tr_meanings_of(L, To, verb, [LT|_]).

%% the subject out, with its person and number for the verb and its noun
%% for the agreement of what is said of it
tr_subject_out(To, asked(w(Q, C)), [o(QT, C)], third, singular, none) :- !, tr_question_across(To, subject, Q, QT).
tr_subject_out(To, asked(which_np(NP, C)), [o(QT, C)|NPOut], third, Number, Noun) :- !,
    tr_which_word(To, QT), tr_np_out(To, NP, NPOut, Noun, Number).
tr_subject_out(_, name(W), [o(W, upper)], third, singular, none) :- !.
tr_subject_out(To, pronoun(P, N, w(W, C)), Outs, P, N, none) :- !,
    (   tr_pronoun_across(To, subject, w(W, C), P, N, T) -> Outs = [o(T, C)]
    ;   To == foreign, W == it -> Outs = []                                % `It rains': the verb says who
    ).
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
tr_subject_out(To, and(S1, S2), Outs, third, plural, none) :- !,
    tr_subject_out(To, S1, O1, _, _, _), tr_subject_out(To, S2, O2, _, _, _),
    tr_and_word(To, And), append(O1, [o(And, lower)|O2], Outs).
tr_subject_out(To, np(D, M, As, N, Number), Outs, third, Number, Noun) :- !, tr_np_out(To, np(D, M, As, N, Number), Outs, Noun, Number).
tr_subject_out(To, with(NP, PPs), Outs, third, Number, Noun) :-
    tr_np_out(To, NP, O1, Noun, Number), tr_comps_out(To, PPs, Noun, Number, _, O2, _), append(O1, O2, Outs).

%% the connector out: a comma as itself, a word through the lesson
tr_connector_out(_, comma, [o(',', comma)]) :- !.
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
tr_pronoun_across(foreign, Role, w(W, _), _, _, T) :-
    findall(T0, ( tr_solve(mean(T0, W)), tr_class_of(T0, pronoun) ), Ts0), Ts0 \== [],
    tr_pronouns_first(Ts0, Ts),
    (   Role == subject -> member(T, Ts), tr_subject_pronoun(foreign, T, _, _)
    ;   Role == object, member(T, Ts), tr_holds(precede(T, verb)) -> true
    ;   Role == oblique, member(T, Ts), ( tr_subject_pronoun(foreign, T, _, _) ; \+ tr_holds(precede(T, verb)) ) -> true
    ;   Ts = [T|_]
    ), !.
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
    tr_lexeme(foreign, W, L, N), tr_solve(mean(L, E)), en_tonic(E, _), !,
    ( N == plural, en_tonic_plural(E, P) -> T = P ; T = E ).

%% English's object form of a subject pronoun, for a lesson that gave
%% `él' as `he' only
en_object_of(i, me). en_object_of(you, you). en_object_of(he, him). en_object_of(she, her).
en_object_of(it, it). en_object_of(we, us). en_object_of(they, them).

%% a phrase out: the determiner and each adjective agreeing with the noun
%% in gender and number, a number word as it is, the adjectives before or
%% after the noun as the rule says; Noun is the target noun's lexeme
tr_np_out(_, name(W), [o(W, upper)], none, singular) :- !.
tr_np_out(To, pronoun(w(W, C)), [o(T, C)], none, singular) :- !, tr_pronoun_across(To, oblique, w(W, C), _, _, T).
tr_np_out(To, and(N1, N2), Outs, none, plural) :- !,
    tr_np_out(To, N1, O1, _, _), tr_np_out(To, N2, O2, _, _), tr_and_word(To, And), append(O1, [o(And, lower)|O2], Outs).
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
    (   tr_side_here(Side), tr_is(Side, A, conjunction)
    ->  tr_and_word(To, And), A = w(_, C), O = c(o(And, C))
    ;   tr_adjective_out(To, A, Noun, Number, O)
    ),
    tr_adjectives_out(To, As, Noun, Number, Os).

tr_adjective_out(To, w(W, C), Noun, Number, a(L, o(T, C))) :-
    tr_lexeme_here(W, WL),
    tr_meanings_of(WL, To, adjective, Ms),
    tr_agree(To, Ms, Noun, L),
    tr_inflect(To, adjective, L, Number, T).

%% English puts an adjective before its noun; the lesson's language does what
%% its rule says of each adjective, follow(A, noun), and English's order otherwise
tr_order(english, Noun, Adjs, Outs) :- tr_adj_words(Adjs, Os), append(Os, [Noun], Outs).
tr_order(foreign, Noun, Adjs, Outs) :-
    tr_sides(Adjs, Before, After),
    append(Before, [Noun|After], Outs).

tr_adj_words([], []).
tr_adj_words([a(_, O)|As], [O|Os]) :- tr_adj_words(As, Os).
tr_adj_words([c(O)|As], [O|Os]) :- tr_adj_words(As, Os).

tr_sides([], [], []).
tr_sides([c(O)|As], Before, After) :- !,
    tr_sides(As, Before1, After1),
    ( After1 == [] -> Before = [O|Before1], After = After1 ; Before = Before1, After = [O|After1] ).
tr_sides([a(L, O)|As], Before, After) :-
    tr_sides(As, Before1, After1),
    (   tr_holds(follow(L, noun)) -> Before = Before1, After = [O|After1]
    ;   Before = [O|Before1], After = After1
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
tr_det_out(foreign, det(Kind, DL, w(_, C)), Noun, Number, _, [o(T, C)]) :-
    tr_meanings_of(DL, foreign, Kind, Ms),
    tr_agree(foreign, Ms, Noun, L),
    tr_inflect(foreign, Kind, L, Number, T).

%% the complements out: objects and predicates in place, the adverbs last,
%% and an object pronoun the lesson puts before the verb kept aside for it
tr_comps_out(_, [], _, _, [], [], []).
tr_comps_out(To, [C|Cs], Noun, Number, Clitics, Outs, Advs) :-
    tr_comp_out(To, C, Noun, Number, Clitic, Out, Adv),
    tr_comps_out(To, Cs, Noun, Number, Clitics1, Outs1, Advs1),
    append(Clitic, Clitics1, Clitics), append(Out, Outs1, Outs), append(Adv, Advs1, Advs).

tr_comp_out(To, obj(NP), _, _, [], Outs, []) :- tr_np_out(To, NP, O1, _, _), tr_marker(To, NP, M), append(M, O1, Outs).
tr_comp_out(To, adj(Ws), Noun, Number, [], Outs, []) :- tr_adjectives_out(To, Ws, Noun, Number, As), tr_adj_words(As, Outs).
tr_comp_out(To, pp(w(P, C), NP), _, _, [], [o(PT, C)|NPOut], []) :- tr_word_across(w(P, lower), To, preposition, PT), tr_np_out(To, NP, NPOut, _, _).
tr_comp_out(To, adv(w(A, C)), _, _, [], [], [o(AT, C)]) :- tr_word_across(w(A, lower), To, adverb, AT).
%% an infinitive: English's `to' and the base form, the base alone after a
%% modal; the lesson's infinitive of its verb
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

%% the verb group being written is a modal
tr_modal_verb :-
    catch(nb_getval('$tr_verb', V), _, fail), tr_side_here(Side),
    ( Side == english -> en_modal_out(V, _, _) ; tr_class_of(V, modal) ).

%% ---- the verb group out ---------------------------------------------------------

%% the lesson's verb in the subject's number, tense and person, the denial
%% and the object pronouns before it; the perfect as the auxiliary that
%% means `has' in that form and the participle, the progressive as the one
%% that means `is' and the gerund
fo_group(L, P, N, T, A, Neg, Clitics, Group) :-
    (   A == perfect
    ->  tr_auxiliary(has, Aux), tr_make(Aux, N, T, P, AuxForm), once(tr_solve(participle_of(PP, L))), VW = [o(AuxForm, lower), o(PP, lower)]
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

%% the meanings of a lexeme on the other side -- of the class asked for,
%% when the lesson classes any of them (the lesson's language has classes;
%% English words are what their translations are)
tr_meanings_of(L, To, Class, Ms) :-
    tr_side_here(From),
    findall(M, tr_meaning(From, L, M), Ms0), Ms0 \== [],
    (   To == foreign, findall(M, ( member(M, Ms0), tr_class_of(M, Class) ), Ms1), Ms1 \== []
    ->  Ms = Ms1
    ;   To == english, tr_english_shaped(Class, Ms0, Ms1), Ms1 \== []
    ->  Ms = Ms1
    ;   Ms = Ms0
    ).

%% English words are what their translations are, but their shape says
%% something too: a verb a lesson gives is a third person (`eats',
%% `visits'), so in a verb's place a meaning shaped like one comes first,
%% and in a noun's or an adjective's place one that is not -- `visita' means
%% visit and visits, and which one is where the word stands
tr_english_shaped(verb, Ms0, Ms) :- !, findall(M, ( member(M, Ms0), tr_third_shaped(M) ), Ms).
tr_english_shaped(Class, Ms0, Ms) :- memberchk(Class, [noun, adjective]), !, findall(M, ( member(M, Ms0), \+ tr_third_shaped(M) ), Ms).
tr_english_shaped(_, _, []).
tr_third_shaped(M) :- ( M == is ; M == has ; reason_base(M, B), B \== M ), !.

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

tr_form_nt(W, W, singular, present) :- tr_known(foreign, W).
tr_form_nt(W, L, plural, present) :- tr_lexeme(foreign, W, L, plural).
tr_form_nt(W, L, N, T) :- tr_tensed(W, T, F), tr_form_nt(F, L, N, present).
tr_form_nt(W, L, plural, T) :- tr_solve(plural_of(W, F)), tr_tensed(F, T, F0), tr_form_nt(F0, L, singular, present).

%% a tense form of a present form: stated, or made by an ending rule
tr_tensed(W, past, F) :- tr_solve(past_of(W, F)).
tr_tensed(W, future, F) :- tr_solve(future_of(W, F)).
tr_tensed(W, conditional, F) :- tr_solve(conditional_of(W, F)).
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
    tr_glue(As0, As),
    atomic_list_concat(As, ' ', S0),
    tr_cap(S0, S1),
    atom_codes(S1, Cs), append(Cs, [Stop], Cs1), atom_codes(Out0, Cs1),
    (   To == foreign, Kind == question, once(tr_solve(begin(M, question))) -> atom_concat(M, Out0, Out)
    ;   Out = Out0
    ).

%% a comma joins the word before it with no space between
tr_glue([A, ','|Rest], Out) :- !, atom_concat(A, ',', A1), tr_glue([A1|Rest], Out).
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
