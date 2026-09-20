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
%%     mean(Q, what)  mean(Q, who)  mean(Q, where)  mean(Q, when)  mean(Q, which)   the question words
%%     begin(M, question)              the mark a question begins with (`The mark "¿" begins the question')
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
%%         an adverb, or nothing. A subject or an object is a name, a
%%         pronoun, a phrase -- an article, a possessive or a number,
%%         adjectives, a noun -- or two of those joined by `and'. The verb
%%         is in the present, the past or the future, simple or perfect
%%         (`has eaten', `had eaten'), denied or not, in any person. A
%%         statement, or a QUESTION when the sentence ends in `?': yes or
%%         no, `what' asking for the object, `who' for the subject, `where'
%%         and `when' for a place or a time, `which' with its noun for
%%         either. From English into the language a lesson teaches, or
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
%%     reason_untranslated(+Text, -Words)
%%         The words of the text no lesson gives a meaning, names and
%%         English's own function words left out; [] when every word is
%%         known.
%%
%%     reason_learn(+Text, +Language, -Terms)
%%         reason_text/2, and every term asserted UNDER THE LANGUAGE, as
%%         lesson(Language, Term): the translator proves them as if they
%%         were plain, and two lessons so learned share nothing -- `casa'
%%         may be feminine in one and its plural `case' in the other. A
%%         lesson learned plain (reason_learn/1) is the language with no
%%         name, and reason_ask/2 can question it; a lesson learned under a
%%         name is the translator's alone.
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
%% own object pronouns after it. A sentence of the lesson's language
%% with no subject takes the pronoun its verb says -- I, you, we, they --
%% and the denial's word goes before the verb, or after it when
%% follow(N, verb) proves. A capitalised word no lesson knows is a name
%% and passes through; the head of a sentence goes lower when it is a
%% word the lesson knows, because a question moves it.
%%
%% ---- WHAT IT IS NOT ---------------------------------------------------
%%
%% It is not a translator of prose. One clause with one verb: no relative
%% clause, no `because', no passive, no imperative, no `why' or `how', no
%% idiom -- a word means a word, and `is' is whichever word the lesson
%% gave for it first (a lesson with `es' and `está' for `is' gets `es').
%% A past that spells like a present form (`read') is read as the present.
%% And it decides nothing about a word a lesson left out: a sentence with
%% one is refused whole, never half translated, and reason_untranslated/2
%% says which word to teach.

:- use_module(library(reasoning/reason)).
:- dynamic lesson/2.

%% ---- the surface -----------------------------------------------------------

reason_translate(Text, Out) :-
    tr_pieces(Text, Pieces), Pieces \== [],
    tr_each(Pieces, any, Outs),
    atomic_list_concat(Outs, ' ', Out).

reason_translate(Text, Into, Out) :-
    tr_into(Into, Way),
    tr_pieces(Text, Pieces), Pieces \== [],
    tr_each(Pieces, Way, Outs),
    atomic_list_concat(Outs, ' ', Out).

reason_learn(Text, Language, Terms) :-
    reason_text(Text, Terms),
    forall(member(T, Terms), assertz(lesson(Language, T))).

reason_untranslated(Text, Words) :-
    tr_pieces(Text, Pieces),
    findall(W, ( member(Piece-_, Pieces), reason_tokens(Piece, Tokens), tr_words(Tokens, Ws),
                 member(w(W, Case), Ws), ( Case \== upper ; en_question(W, _) ),
                 \+ tr_known_anywhere(Ws, W) ),
            Ws0),
    list_to_set(Ws0, Words).

%% known on the side the words settle, or, when they settle nothing, on
%% any side of any lesson; English's own function words are known
tr_known_anywhere(Ws, W) :- en_function(W), !.
tr_known_anywhere(Ws, W) :- tr_way(any, Ws, From, _), !, tr_known_word(From, W).
tr_known_anywhere(_, W) :-
    tr_languages(Ls), member(L, Ls), tr_set_language(L),
    ( tr_known_word(foreign, W) ; tr_known_word(english, W) ), !.

%% into English, or into a language: one learned under that name, or the
%% plain lesson when it named itself so (`Spanish is a language')
tr_into(english, to_english) :- !.
tr_into(L, from_english(L)) :- atom(L), tr_solve_plain(lesson(L, mean(_, _))), !.
tr_into(L, from_english(none)) :- atom(L), tr_solve_plain(language(L)), !.
tr_into(L, _) :- throw(error(domain_error(language, L), reason_translate/3)).

tr_each([], _, []).
tr_each([Piece-Stop|Ps], Way, [Out|Outs]) :-
    reason_tokens(Piece, Tokens), tr_words(Tokens, Words0), Words0 \== [],
    tr_way(Way, Words0, From, To),
    tr_head_lower(From, Words0, Words),
    tr_translate(Words, From, To, Stop, Out),
    tr_each(Ps, Way, Outs).

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
tr_words([], []).
tr_words([word(W, C)|Ts], [w(W, C)|Ws]) :- !, tr_words(Ts, Ws).
tr_words([','|Ts], Ws) :- !, tr_words(Ts, Ws).

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
    findall(L, tr_solve_plain(lesson(L, mean(_, _))), L0), list_to_set(L0, L1),
    ( tr_solve_plain(mean(_, _)) -> Ls = [none|L1] ; Ls = L1 ).

tr_votes_in(L, Words, F, E) :- tr_set_language(L), tr_votes(Words, 0, 0, F, E).

tr_votes([], F, E, F, E).
tr_votes([w(W, _)|Ws], F0, E0, F, E) :-
    ( tr_known_word(foreign, W) -> Kf = 1 ; Kf = 0 ),
    ( tr_known_word(english, W) -> Ke = 1 ; Ke = 0 ),
    ( Kf =:= Ke -> F1 = F0, E1 = E0 ; F1 is F0 + Kf, E1 is E0 + Ke ),
    tr_votes(Ws, F1, E1, F, E).

%% one clear winner among the languages, or none
tr_winner(Vs, Which, L) :-
    findall(K-L0, ( member(v(L0, F, E), Vs), ( Which == from -> F > E, K = F ; E > F, K = E ) ), Cs),
    Cs \== [], keysort(Cs, S), last(S, K-L),
    \+ ( member(K-L2, S), L2 \== L ).

tr_set_language(L) :- nb_setval('$tr_language', L).
tr_language(L) :- ( catch(nb_getval('$tr_language', L0), _, fail) -> L = L0 ; L = none ).

%% ---- the whole sentence -----------------------------------------------------------

tr_translate(Words, From, To, Stop, Out) :-
    nb_setval('$tr_from', From),
    ( Stop == 63 -> Kind = question ; Kind = statement ),                 % 63 is `?'
    tr_read(From, Kind, Words, S),
    tr_write(To, Kind, S, Outs),
    tr_join(To, Kind, Outs, Stop, Out).

%% ---- reading: a question into the statement's order -------------------------------

tr_read(Side, Kind, Words0, S) :-
    tr_normalise(Side, Kind, Words0, Words, Asked),
    tr_read_statement(Side, Words, Asked, S).

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
en_unfront(_, [w(A, C)|Ws], Words) :-
    en_fronts(A), !,
    en_np_words(Ws, NP, Rest),
    append(NP, [w(A, C)|Rest], Words).
en_unfront(_, Ws, Ws).

en_fronts(A) :- memberchk(A, [does, do, did, will, has, have, had, am, is, are, was, were]).

%% the subject phrase at the head of the words: a pronoun, a name, or up to
%% and including the first word the lesson calls a noun -- failing that up
%% to the first verbal word
en_np_words([w(P, C)|Rest], [w(P, C)], Rest) :- en_subject(P, _, _), !.
en_np_words([w(W, upper)|Rest], [w(W, upper)], Rest) :- \+ tr_known_word(english, W), !.
en_np_words(Words, NP, Rest) :-
    append(NP0, Rest0, Words), NP0 \== [], last(NP0, N), tr_is(english, N, noun), !,
    en_np_pps(Rest0, PPs, Rest), append(NP0, PPs, NP).
en_np_words(Words, NP, Rest) :- append(NP, Rest, Words), NP \== [], Rest = [w(V, _)|_], ( en_fronts(V) ; en_verb_form(V, _, _) ), !.
en_np_words(Words, Words, []).

%% a phrase after a preposition after the noun belongs to it: `the dogs of Maria'
en_np_pps([w(P, C)|Ws], [w(P, C)|NP], Rest) :-
    en_preposition(P), en_np_words(Ws, NP, Rest), NP \== [], \+ ( NP = [w(V, _)|_], en_verb_form(V, _, _) ), !.
en_np_pps(Ws, [], Ws).

%% the lesson's question word, by its meaning; `which' takes the noun phrase
%% after it, and asks for the object when a name or a pronoun stands alone
%% after the verb (`¿Qué libro lee Maria?'), for the subject otherwise
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
%% content up to the verb group
fo_np_words([w(W, upper)|Rest], [w(W, upper)], Rest) :- \+ tr_known_word(foreign, W), !.
fo_np_words([w(P, C)|Rest], [w(P, C)], Rest) :- tr_subject_pronoun(foreign, P, _, _), !.
fo_np_words(Words, NP, Rest) :- append(NP, Rest, Words), NP \== [], tr_group(foreign, Rest, [], _, _, _), !.
fo_np_words(Words, Words, []).

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
tr_read_statement(Side, Words0, Asked, s(Asked, Subject, g(L, T, A, Neg), Comps)) :-
    tr_negation(Side, Words0, Words, Neg),
    tr_group(Side, Words, Before, g(L, T, A, FP, FN), _, After), !,
    tr_split_clitics(Side, Before, Asked, FP, FN, SubjectWords, Clitics),
    tr_subject(Side, Asked, SubjectWords, FP, FN, Subject),
    tr_complements(Side, After, Comps0),
    findall(opron(W), member(W, Clitics), Cs),
    append(Cs, Comps0, Comps).

%% English's `not' wherever it stands; the lesson's word for `not' wherever
%% it stands
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

%% an object pronoun; before a fronted verb, one that could not be the
%% subject standing in its place (`¿Ella come el pan?' is she, in order)
tr_clitic(fronted, C) :- !, tr_object_pronoun(foreign, C, _), \+ tr_subject_pronoun(foreign, C, _, _).
tr_clitic(_, C) :- tr_object_pronoun(foreign, C, _).

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

%% the verb group: at the first place one starts, the words before it and after it
tr_group(Side, Words, Before, Group, GroupWords, After) :-
    append(Before, Rest, Words),
    tr_group_at(Side, Rest, Group, After), !,
    append(GroupWords, After, Rest).

%% English: `will' and a base form; `has', `have' or `had' and a
%% participle; `does', `do' or `did' and a base form; a copula; a verb form
tr_group_at(english, [w(will, _), w(B, _)|R], g(L, future, simple, third, singular), R) :- en_verb_form(B, L, present), !.
tr_group_at(english, [w(H, _), w(P, _)|R], g(L, T, perfect, third, singular), R) :-
    memberchk(H, [has, have, had]), en_participle(P, L), !, ( H == had -> T = past ; T = present ).
tr_group_at(english, [w(D, _), w(B, _)|R], g(L, T, simple, third, singular), R) :-
    memberchk(D, [does, do, did]), en_verb_form(B, L, present), !, ( D == did -> T = past ; T = present ).
tr_group_at(english, [w(C, _)|R], g(is, T, simple, P, N), R) :- en_copula(C, P, N, T), !.
tr_group_at(english, [w(V, _)|R], g(L, T, simple, third, singular), R) :- en_verb_form(V, L, T), !.
%% the lesson's language: an auxiliary's form and a participle; a verb's form
tr_group_at(foreign, [w(A, _), w(P, _)|R], g(L, T, perfect, Person, N), R) :-
    tr_form(A, AL, N, T, Person), tr_solve(auxiliary(AL)), tr_solve(participle_of(P, L)), !.
tr_group_at(foreign, [w(V, _)|R], g(L, T, simple, Person, N), R) :-
    tr_form(V, L, N, T, Person), tr_class_of(L, verb), !.

%% the subject: what was asked, a pronoun, a name, two joined, a phrase --
%% or, in the lesson's language, nobody, and then the pronoun the verb's
%% person and number say
tr_subject(_, subject(Q), [], _, _, asked(Q)) :- !.
tr_subject(foreign, _, [], P, N, null(P, N)) :- !, ( P \== third ; N == plural ).
tr_subject(Side, _, [w(P, C)], _, _, pronoun(Person, Number, w(P, C))) :- tr_subject_pronoun(Side, P, Person, Number), !.
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
    forall(member(A, Adjs), tr_adj_word(Side, A)),
    Noun = w(NW, _), tr_lexeme(Side, NW, _, Number), !.

%% a word that may be an adjective in a phrase: known, and no preposition,
%% pronoun or verb -- or the `and' between two
tr_adj_word(Side, A) :- tr_is(Side, A, conjunction), !.
tr_adj_word(Side, w(W, C)) :-
    tr_lexeme(Side, W, _, _),
    \+ tr_is(Side, w(W, C), preposition), \+ tr_is(Side, w(W, C), verb), \+ tr_object_pronoun(Side, W, _), \+ tr_subject_pronoun(Side, W, _, _).

%% a determiner: English's articles and possessives; the lesson's, in
%% either number -- det(Kind, Lexeme, Word)
tr_determiner(english, w(the, _), the, article).
tr_determiner(english, w(a, _), a, article).
tr_determiner(english, w(an, _), a, article).
tr_determiner(english, w(P, _), P, possessive) :- en_possessive(P).
tr_determiner(foreign, w(W, _), L, article) :- tr_lexeme(foreign, W, L, _), tr_class_of(L, article).
tr_determiner(foreign, w(W, _), L, possessive) :- tr_lexeme(foreign, W, L, _), tr_class_of(L, possessive).

%% the noun of a phrase's content
tr_noun(Words, Side, Noun, Adjs) :-
    findall(W, ( member(W, Words), tr_is(Side, W, noun) ), Nouns),
    (   Nouns = [Noun] -> true
    ;   Nouns == [] -> tr_noun_by_position(Words, Side, Noun)
    ),
    select(Noun, Words, Adjs).

tr_noun_by_position(Words, english, Noun) :- last(Words, Noun).
tr_noun_by_position(Words, foreign, Noun) :- ( tr_holds(follow(_, noun)) -> Words = [Noun|_] ; last(Words, Noun) ).

%% the complements after the verb: a preposition and its phrase, an object
%% pronoun, an adverb, and otherwise a phrase (or two joined, or bare
%% adjectives) up to the next of those
tr_complements(_, [], []) :- !.
tr_complements(Side, [P|Ws], [pp(P, NP)|Cs]) :-
    tr_is(Side, P, preposition), !,
    (   Ws = [w(O, OC)|Rest], tr_object_pronoun_here(Side, Ws)
    ->  NP = pronoun(w(O, OC))
    ;   tr_phrase_words(Side, Ws, PW, Rest), PW \== [], tr_object_phrase(Side, PW, NP)
    ),
    tr_complements(Side, Rest, Cs).
tr_complements(Side, [w(W, C)|Ws], [opron(w(W, C))|Cs]) :-
    tr_object_pronoun_here(Side, [w(W, C)|Ws]), !,
    tr_complements(Side, Ws, Cs).
tr_complements(Side, [A|Ws], [adv(A)|Cs]) :- tr_is(Side, A, adverb), !, tr_complements(Side, Ws, Cs).
tr_complements(Side, Ws, [C|Cs]) :-
    tr_phrase_words(Side, Ws, PW, Rest), PW \== [],
    (   tr_conjunction_split(Side, PW, W1, W2) -> tr_object_phrase(Side, W1, N1), tr_object_phrase(Side, W2, N2), C = obj(and(N1, N2))
    ;   tr_all_adjectives(Side, PW) -> C = adj(PW)
    ;   tr_object_phrase(Side, PW, NP), C = obj(NP)
    ),
    tr_complements(Side, Rest, Cs).

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

%% bare adjectives, an `and' among them allowed: the predicate of a copula
tr_all_adjectives(Side, Words) :-
    Words \== [],
    forall(member(W, Words), ( tr_is(Side, W, adjective) ; tr_is(Side, W, conjunction) )),
    \+ forall(member(W, Words), tr_is(Side, W, conjunction)).

%% ---- writing ------------------------------------------------------------------

tr_write(To, Kind, s(Asked, Subject, g(L, T, A, Neg), Comps), Outs) :-
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
tr_subject_out(To, asked(which(NPWords, C)), [o(QT, C)|NPOut], third, Number, Noun) :- !,
    tr_which_word(To, QT), tr_side_here(Side), tr_np(Side, NPWords, NP), tr_np_out(To, NP, NPOut, Noun, Number).
tr_subject_out(_, name(W), [o(W, upper)], third, singular, none) :- !.
tr_subject_out(To, pronoun(P, N, w(W, C)), Outs, P, N, none) :- !,
    (   tr_pronoun_across(To, subject, w(W, C), P, N, T) -> Outs = [o(T, C)]
    ;   To == foreign, W == it -> Outs = []                                % `It rains': the verb says who
    ).
tr_subject_out(english, null(P, N), [o(T, lower)], P, N, none) :- !, en_subject(T, P, N), !.
tr_subject_out(To, and(S1, S2), Outs, third, plural, none) :- !,
    tr_subject_out(To, S1, O1, _, _, _), tr_subject_out(To, S2, O2, _, _, _),
    tr_and_word(To, And), append(O1, [o(And, lower)|O2], Outs).
tr_subject_out(To, np(D, M, As, N, Number), Outs, third, Number, Noun) :- !, tr_np_out(To, np(D, M, As, N, Number), Outs, Noun, Number).
tr_subject_out(To, with(NP, PPs), Outs, third, Number, Noun) :-
    tr_np_out(To, NP, O1, Noun, Number), tr_comps_out(To, PPs, Noun, Number, _, O2, _), append(O1, O2, Outs).

%% what a question word asks for, out: the word itself, or `which' with its phrase
tr_asked_out(_, none, []) :- !.
tr_asked_out(_, subject(_), []) :- !.                                    % the subject out already carries it
tr_asked_out(To, object(which(NPWords, C)), [o(QT, C)|NPOut]) :- !,
    tr_which_word(To, QT), tr_side_here(Side), tr_np(Side, NPWords, NP), tr_np_out(To, NP, NPOut, _, _).
tr_asked_out(To, Asked, [o(QT, C)]) :- Asked =.. [Kind, w(Q, C)], tr_question_across(To, Kind, Q, QT).

%% a question word across, by what it asks for: `qué' may mean `what' and
%% `which', and the object asked is `what'
tr_question_across(english, Kind, Q, E) :- tr_solve(mean(Q, E)), en_question(E, Kind), !.
tr_question_across(foreign, _, E, Q) :- tr_solve(mean(Q, E)), !.

tr_which_word(english, which).
tr_which_word(foreign, W) :- once(tr_solve(mean(W, which))).
tr_and_word(english, and).
tr_and_word(foreign, W) :- once(( tr_solve(mean(W, and)) )).

%% a pronoun across: English's by person and number, or by the meaning of
%% the lesson's (`ella' is `she'); the lesson's by the meaning of English's
%% -- as the subject one that may be a subject, as the object one the
%% lesson puts before the verb, after a preposition one it does not, or
%% one that serves as a subject too (`con nosotros', `con él')
tr_pronoun_across(english, subject, w(W, _), P, N, T) :- ( tr_solve(mean(W, E)), en_subject(E, P, N) -> T = E ; en_subject(T, P, N) ), !.
tr_pronoun_across(english, _, w(W, _), _, _, T) :- tr_solve(mean(W, E)), en_object(E), !, T = E.
tr_pronoun_across(english, _, w(W, _), _, _, T) :- tr_solve(mean(W, E)), en_object_of(E, T), !.
tr_pronoun_across(foreign, Role, w(W, _), _, _, T) :-
    findall(T0, ( tr_solve(mean(T0, W)), tr_class_of(T0, pronoun) ), Ts), Ts \== [],
    (   Role == subject -> member(T, Ts), tr_subject_pronoun(foreign, T, _, _)
    ;   Role == object, member(T, Ts), tr_holds(precede(T, verb)) -> true
    ;   Role == oblique, member(T, Ts), ( tr_subject_pronoun(foreign, T, _, _) ; \+ tr_holds(precede(T, verb)) ) -> true
    ;   Ts = [T|_]
    ), !.
tr_pronoun_across(foreign, Role, w(W, _), _, _, T) :- Role \== subject, tr_solve(mean(T, W)), !.

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
    tr_lexeme_here(NW, L),
    tr_meanings_of(L, To, noun, [Noun|_]),
    tr_inflect(To, noun, Noun, Number, NounForm),
    tr_adjectives_out(To, Adjs, Noun, Number, AdjOuts),
    tr_order(To, o(NounForm, NC), AdjOuts, Content),
    ( Num == none -> NumOut = [] ; Num = w(MW, MC), tr_word_across(w(MW, MC), To, number, MT), NumOut = [o(MT, MC)] ),
    tr_det_out(To, Det, Noun, Number, Content, DetOut),
    append(DetOut, NumOut, Front), append(Front, Content, Outs).

tr_lexeme_here(W, L) :- tr_side_here(Side), tr_lexeme(Side, W, L, _), !.
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

tr_comp_out(To, obj(NP), _, _, [], Outs, []) :- tr_np_out(To, NP, Outs, _, _).
tr_comp_out(To, adj(Ws), Noun, Number, [], Outs, []) :- tr_adjectives_out(To, Ws, Noun, Number, As), tr_adj_words(As, Outs).
tr_comp_out(To, pp(w(P, C), NP), _, _, [], [o(PT, C)|NPOut], []) :- tr_word_across(w(P, lower), To, preposition, PT), tr_np_out(To, NP, NPOut, _, _).
tr_comp_out(To, adv(w(A, C)), _, _, [], [], [o(AT, C)]) :- tr_word_across(w(A, lower), To, adverb, AT).
tr_comp_out(english, opron(w(W, C)), _, _, [], [o(T, C)], []) :- tr_pronoun_across(english, object, w(W, C), _, _, T).
tr_comp_out(foreign, opron(w(W, C)), _, _, Clitics, Outs, []) :-
    tr_pronoun_across(foreign, object, w(W, C), _, _, T),
    ( tr_holds(precede(T, verb)) -> Clitics = [o(T, C)], Outs = [] ; Clitics = [], Outs = [o(T, C)] ).

%% ---- the verb group out ---------------------------------------------------------

%% the lesson's verb in the subject's number, tense and person, the denial
%% and the object pronouns before it; the perfect as the auxiliary in that
%% form and the participle
fo_group(L, P, N, T, A, Neg, Clitics, Group) :-
    (   A == perfect
    ->  once(( tr_solve(auxiliary(Aux)), tr_solve(mean(Aux, _)) )),
        tr_make(Aux, N, T, P, AuxForm), once(tr_solve(participle_of(PP, L))), VW = [o(AuxForm, lower), o(PP, lower)]
    ;   tr_make(L, N, T, P, Form), VW = [o(Form, lower)]
    ),
    (   Neg == yes
    ->  tr_negation_word(No),
        ( tr_holds(follow(No, verb)) -> append(Clitics, VW, G1), append(G1, [o(No, lower)], Group)
        ; append([o(No, lower)|Clitics], VW, Group) )
    ;   append(Clitics, VW, Group)
    ).

%% English's verb group: the statement's words, and for a question the word
%% that fronts and the words that stay behind the subject
en_group(is, P, N, T, A, Neg, Statement, Front, Tail) :- !,
    ( Neg == yes -> Not = [o(not, lower)] ; Not = [] ),
    (   A == perfect
    ->  en_have(P, N, T, H), Front = o(H, lower), append(Not, [o(been, lower)], Tail)
    ;   T == future
    ->  Front = o(will, lower), append(Not, [o(be, lower)], Tail)
    ;   en_copula_form(P, N, T, C), Front = o(C, lower), Tail = Not
    ),
    Statement = [Front|Tail].
en_group(L, P, N, T, A, Neg, Statement, Front, Tail) :-
    en_base(L, B),
    ( Neg == yes -> Not = [o(not, lower)] ; Not = [] ),
    (   A == perfect
    ->  en_have(P, N, T, H), en_participle_of(L, PP), Front = o(H, lower), append(Not, [o(PP, lower)], Tail), Statement = [Front|Tail]
    ;   T == future
    ->  Front = o(will, lower), append(Not, [o(B, lower)], Tail), Statement = [Front|Tail]
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

%% the meanings of a lexeme on the other side -- of the class asked for,
%% when the lesson classes any of them (the lesson's language has classes;
%% English words are what their translations are)
tr_meanings_of(L, To, Class, Ms) :-
    tr_side_here(From),
    findall(M, tr_meaning(From, L, M), Ms0), Ms0 \== [],
    (   To == foreign, findall(M, ( member(M, Ms0), tr_class_of(M, Class) ), Ms1), Ms1 \== []
    ->  Ms = Ms1
    ;   Ms = Ms0
    ).

%% the noun's gender first, none next, the first candidate last
tr_agree(english, [M|_], _, M) :- !.
tr_agree(foreign, Ms, Noun, T) :-
    tr_gender(Noun, G),
    (   G \== none, member(T, Ms), tr_gender(T, G1), G1 == G -> true
    ;   member(T, Ms), tr_gender(T, none) -> true
    ;   Ms = [T|_]
    ).

%% feminine, masculine or none -- feminine asked first, so a word the
%% lesson said was feminine is, whatever a rule adds
tr_gender(W, G) :-
    (   W == none -> G = none
    ;   tr_solve(feminine(W)) -> G = feminine
    ;   tr_solve(masculine(W)) -> G = masculine
    ;   G = none
    ).

%% ---- forms: lexemes, number, tense, person ------------------------------------------

%% a word's lexeme on a side -- the form the lesson gave -- and its number:
%% the word itself when the lesson gave it; the singular of a plural the
%% lesson stated; in the lesson's language the singular whose ending rule
%% makes the word; in English a noun the stemmer takes back
tr_lexeme(Side, W, W, singular) :- tr_known(Side, W).
tr_lexeme(english, an, a, singular) :- tr_known(english, a).
tr_lexeme(Side, W, S, plural) :- tr_solve(plural_of(W, S)), tr_known(Side, S).
tr_lexeme(foreign, W, S, plural) :- tr_solve(mean(S, _)), tr_rule_plural(S, W).
tr_lexeme(english, W, S, plural) :- reason_base(W, S), S \== W, tr_known(english, S).

tr_known(foreign, W) :- tr_solve(mean(W, _)), !.
tr_known(english, E) :- tr_solve(mean(_, E)), !.

%% a word the lesson knows on a side, in any of its forms: a lexeme, a
%% plural, a verb's form, or one of English's own
tr_known_word(Side, W) :- tr_lexeme(Side, W, _, _), !.
tr_known_word(foreign, W) :- tr_form(W, _, _, _, _), !.
tr_known_word(english, W) :- en_verb_form(W, _, _), !.
tr_known_word(english, W) :- en_participle(W, _), !.
tr_known_word(english, W) :- ( en_subject(W, _, _) ; en_object(W) ; en_possessive(W) ; en_copula(W, _, _, _) ), !.

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
tr_tensed(W, T, F) :- ( T = past ; T = future ), tr_present_form(F), tr_solve(take_in(F, E, T)), atom(E), atom_concat(F, E, W).

%% the lesson's verbs in either number, for a rule to make a tense of
tr_present_form(F) :- tr_solve(mean(S, _)), tr_class_of(S, verb), ( F = S ; tr_number_form(S, plural, F) ).

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
tr_tense_form(F, T, P) :- tr_solve(take_in(F, E, T)), atom(E), atom_concat(F, E, P), !.

tr_person_form(F, third, F) :- !.
tr_person_form(F, P, Form) :- tr_solve(person_of(Form, F)), G =.. [P, Form], tr_solve(G), !.
tr_person_form(F, _, F).

%% a form in a number: the singular as it is; a plural the lesson stated
%% first, then in the lesson's language the singular with the ending its
%% rule gives, and in English a noun by -s, -es or -ies and anything else
%% unchanged. No rule, no plural: the sentence is refused.
tr_inflect(_, _, S, singular, S) :- !.
tr_inflect(To, _, S, plural, P) :- tr_solve(plural_of(P0, S)), !, P = P0.
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
    ;   memberchk(W, [and, not, will, am, are, was, were, be, been, a, an, the])
    ), !.

en_past_form(had, has).
en_past_form(W, L) :- tr_solve(past_of(W, L)), tr_known(english, L).
en_past_form(W, L) :- tr_english_ed_base(W, B), reason_third(B, L), tr_known(english, L), tr_class(english, L, verb).

en_participle(been, is).
en_participle(W, L) :- tr_solve(participle_of(W, L)), tr_known(english, L).
en_participle(W, L) :- W \== had, en_past_form(W, L), \+ en_copula(W, _, _, _).

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
tr_class(foreign, W, C) :- tr_class_of(W, C).
tr_class(english, E, C) :- tr_solve(mean(W, E)), tr_class_of(W, C).
tr_class_of(W, C) :-
    member(C, [article, possessive, verb, noun, adjective, pronoun, preposition, adverb, number, conjunction, auxiliary]),
    G =.. [C, W], tr_solve(G).

%% a subject pronoun, with its person and number: English's own, or the
%% lesson's by what it means. English writes `it' and `you' the same as a
%% subject and as an object, so a pronoun of the lesson's that means one
%% of those is a subject only when no other meaning of it is an object's
%% alone (`lo' means `him' and `it': an object, never a subject; `tú'
%% means `you' and may be either) -- and an object only when no other
%% meaning is a subject's alone (`ella' means `she' and `her', and is both)
tr_subject_pronoun(english, W, P, N) :- en_subject(W, P, N).
tr_subject_pronoun(foreign, W, P, N) :-
    tr_class_of(W, pronoun), tr_solve(mean(W, E)), en_subject(E, P, N),
    \+ ( en_object(E), tr_solve(mean(W, O)), en_object(O), \+ en_subject(O, _, _) ).
tr_object_pronoun(english, W, W) :- en_object(W).
tr_object_pronoun(foreign, W, E) :-
    tr_class_of(W, pronoun), tr_solve(mean(W, E)), en_object(E),
    \+ ( en_subject(E, _, _), tr_solve(mean(W, S)), en_subject(S, _, _), \+ en_object(S) ).

%% the lesson proved: plain, or under the language it was learned in --
%% its facts, its rules with their bodies, and the library's helpers
tr_solve(G) :- tr_language(L), tr_prove(L, G).
tr_prove(none, G) :- !, tr_solve_plain(G).
tr_prove(L, G) :- tr_lesson(L, G).

tr_lesson(_, G) :- tr_helper(G), !, tr_solve_plain(G).
tr_lesson(L, G) :- tr_solve_plain(lesson(L, G)).
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
en_number(W) :- memberchk(W, [one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve, twenty, thirty, forty, fifty, hundred, thousand]).
%% the words no lesson gives and none needs to: they carry a form, not a meaning
en_function(W) :- memberchk(W, [not, does, do, did, will, has, have, had, am, are, was, were, be, been, an]).

%% ---- the sentence back as text ---------------------------------------------------

tr_join(To, Kind, Outs, Stop, Out) :-
    findall(A, ( member(o(T, C), Outs), tr_word_text(To, T, C, A) ), As),
    atomic_list_concat(As, ' ', S0),
    tr_cap(S0, S1),
    atom_codes(S1, Cs), append(Cs, [Stop], Cs1), atom_codes(Out0, Cs1),
    (   To == foreign, Kind == question, once(tr_solve(begin(M, question))) -> atom_concat(M, Out0, Out)
    ;   Out = Out0
    ).

tr_word_text(english, i, _, 'I') :- !.
tr_word_text(_, T, upper, A) :- !, tr_cap(T, A).
tr_word_text(_, T, _, T).

%% the first letter up: an ASCII one, or one of U+00E0..U+00FE, the two
%% bytes 195 and 160..190 in UTF-8 (`él' is `Él'); the division sign is
%% no letter
tr_cap(W, C) :- atom_codes(W, [195, B|R]), B >= 160, B =< 190, B =\= 183, !, B1 is B - 32, atom_codes(C, [195, B1|R]).
tr_cap(W, C) :- atom_codes(W, [F|R]), ( F >= 97, F =< 122 -> F1 is F - 32 ; F1 = F ), atom_codes(C, [F1|R]).
