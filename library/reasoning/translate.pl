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
%%                      "son" is the plural of "es". The word "no" means "not".'),
%%        reason_translate('The houses are not big.', S),
%%        reason_translate(S, E).
%%     S = 'Las casas no son grandes.',
%%     E = 'The houses are not big.'
%%
%% TIER 2, clauses only, over library(reasoning/reason). NOTHING HERE KNOWS
%% A WORD OF SPANISH. The lesson is the controlled English -- a word in
%% quotation marks is MENTIONED and stands for itself, `the noun "casa"'
%% says what it is, `every noun that ends in "a" is feminine' is a rule --
%% read by reason_text/2 and asserted by reason_learn/1; and what this
%% library knows is WHAT TO ASK. Seven questions, and the lesson's facts and
%% rules answer them, however the lesson put them:
%%
%%     mean(W, E)                      the lesson's word W means the English word E,
%%                                     a verb in the third person singular (`eats')
%%     noun(W)  adjective(W)  verb(W)  article(W)      what a word is
%%     feminine(W)  masculine(W)       its gender, said of it or ruled
%%     follow(A, noun)                 the adjective A stands after its noun
%%     plural_of(P, W)                 P is the plural of W, said (`"los" is the plural of "el"')
%%     take_in(W, E, plural)           or ruled: W takes the ending E in the plural
%%                                     (`Every noun that ends in a vowel takes "s" in the plural')
%%     mean(N, not)  follow(N, verb)   the word that denies, and whether it stands after the verb
%%     mean(Q, what)  mean(Q, who)    the question words (`The word "qué" means "what"')
%%     begin(M, question)              the mark a question begins with (`The mark "¿" begins the question')
%%     language(L)                     the language, `Spanish is a language'
%%
%% So a lesson in Italian, or one whose rule is `Every adjective precedes
%% the noun', is read by the same clauses -- and a lesson written as Prolog
%% facts in those shapes works with no sentence of English at all. What
%% the translator knows on its own is ENGLISH, the library's language: the
%% copula is `is' and `are', `not' stands after it and `does not' or `do
%% not' before any other verb with its base form, a question fronts the
%% copula or `does' and `do', `what' asks for the object and `who' for the
%% subject, a plural noun ends in -s, -es or -ies unless the lesson says
%% otherwise (`"children" is the plural of "child"'), `a' is `an' before
%% a vowel and nothing in the plural, and `the' is `the' either way.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     reason_translate(+Text, -Translation)
%%         SIMPLE sentences, each a subject, a verb, and after it an object,
%%         an adjective or nothing; a subject or an object a name or a
%%         phrase -- an article or none, adjectives, a noun -- singular or
%%         plural; the verb denied or not; a statement, or a QUESTION when
%%         the sentence ends in `?': yes or no, `what' asking for the
%%         object, `who' for the subject. From English into the language
%%         the lesson teaches, or from it into English: which way, the
%%         words say, a word the lesson gave a meaning being the lesson's
%%         and the meaning English. Translation is an atom, a sentence
%%         capitalised and ending as it ended. FAILS for a sentence it
%%         cannot translate, whole and never half: a word the lesson gives
%%         no meaning (a capitalised one is a name and passes through), no
%%         verb, two nouns in one phrase, a plural the lesson gives no rule
%%         for, a denial with no word for `not', a question word the
%%         lesson gives no word for, a number, a word in quotation marks;
%%         reason_untranslated/2 names the words.
%%
%%     reason_translate(+Text, +Into, -Translation)
%%         The same, Into naming the language: english, or the name the
%%         lesson gave its own (`Spanish is a language.' is language(spanish),
%%         so `spanish'). Any other name is a domain_error.
%%
%%     reason_untranslated(+Text, -Words)
%%         The words of the text the lesson gives no meaning, names and
%%         English's own function words left out; [] when every word is
%%         known.
%%
%% ---- HOW A SENTENCE IS TRANSLATED ----------------------------------------
%%
%% Word by word, and the phrase is the unit of agreement. A denial is
%% taken off first -- English's `not' with the `does' or `do' before it,
%% or the lesson's word for `not' wherever it stands -- and put back on
%% the verb in the target: `no come', or `does not eat', `is not'. Then the
%% sentence is split at its VERB, the first word whose LEXEME the lesson
%% calls one, into the subject phrase and what follows. A lexeme is the
%% form the lesson gave -- the word itself, or the singular a plural is
%% made from: a plural the lesson stated, one its ending rules make, or in
%% English a noun by the stemmer and a verb by its third person. A phrase
%% is an article or none and then its content: the noun is the word the
%% lesson calls a noun, and failing that the last word in English (the
%% grammar's own rule) and, in the lesson's language, the first when
%% adjectives follow the noun there; every other word is an adjective.
%% The noun's NUMBER is the phrase's, and the subject's is the verb's.
%% Each word is looked up, mean(W, E) read from whichever side the word is
%% on, and where the target is the lesson's language the ARTICLE and each
%% ADJECTIVE are chosen among the words the lesson gives for the English
%% one by the gender of the noun -- one of the noun's gender first, one
%% with no gender next (`grande'), the first otherwise -- and then put in
%% the number: a plural the lesson stated, or the singular with the ending
%% its rule gives. A bare adjective after the verb agrees with the subject's
%% noun in both. An adjective goes after the noun when follow(A, noun)
%% proves and before it otherwise, which is English's order and the
%% default. A capitalised word the lesson does not know is a name and
%% passes through as written; the case of every word travels with it,
%% except that the head of a sentence goes lower when the lesson knows the
%% word, since a question moves it. A QUESTION is the sentence that ended
%% in `?': the question word first if there is one (the lesson's
%% vocabulary, `what' for the object and `who' for the subject), then
%% English's `does', `do' or the copula fronted, and the rest in the
%% statement's order; the lesson's language asks in the statement's order
%% too, except that after a question word asking for the object the verb
%% comes before the subject (`¿Qué come el perro?'), and it is read in
%% either order (`¿Es grande la casa?' as well). The mark the lesson says
%% begins the question goes before the first word.
%%
%% ---- WHAT IT IS NOT ---------------------------------------------------
%%
%% It is not a translator of prose. One clause, present tense, third
%% person: no pronoun, no tense, no `where', `when' or `which', no idiom
%% -- a word means a word. ONE LANGUAGE BESIDE ENGLISH per knowledge base: mean/2 carries no
%% language, so two lessons loaded together are one vocabulary. And it
%% decides nothing about a word the lesson left out: a sentence with one
%% is refused whole, never half translated, and reason_untranslated/2
%% says which word to teach.

:- use_module(library(reasoning/reason)).

%% ---- the surface -----------------------------------------------------------

reason_translate(Text, Out) :-
    tr_pieces(Text, Pieces), Pieces \== [],
    tr_each(Pieces, any, Outs),
    atomic_list_concat(Outs, ' ', Out).

reason_translate(Text, Into, Out) :-
    tr_into(Into, From, To),
    tr_pieces(Text, Pieces), Pieces \== [],
    tr_each(Pieces, From-To, Outs),
    atomic_list_concat(Outs, ' ', Out).

reason_untranslated(Text, Words) :-
    tr_pieces(Text, Pieces),
    findall(W, ( member(Piece-_, Pieces), reason_tokens(Piece, Tokens), tr_words(Tokens, Ws),
                 ( tr_direction(Ws, From, _) -> true ; From = either ),
                 member(w(W, Case), Ws), ( Case \== upper ; tr_asked_by(W, _) ),
                 \+ tr_lexeme(From, W, _, _), \+ tr_function_word(From, W) ),
            Ws0),
    list_to_set(Ws0, Words).

%% English's own words the translator knows, which no lesson gives
tr_function_word(Side, W) :- Side \== foreign, memberchk(W, [not, does, do, an]).

%% into English from the lesson's language, or into the language the lesson
%% named -- `Spanish is a language' is language(spanish)
tr_into(english, foreign, english) :- !.
tr_into(L, english, foreign) :- atom(L), tr_solve(language(L)), !.
tr_into(L, _, _) :- throw(error(domain_error(language, L), reason_translate/3)).

%% each sentence its own way when none was given: the words decide
tr_each([], _, []).
tr_each([Piece-Stop|Ps], Way, [Out|Outs]) :-
    reason_tokens(Piece, Tokens), tr_words(Tokens, Words0), Words0 \== [],
    ( Way == any -> tr_direction(Words0, From, To) ; Way = From-To ),
    tr_head_lower(From, Words0, Words),
    tr_translate(Words, From, To, Stop, Out),
    tr_each(Ps, Way, Outs).

%% the first word's capital is the sentence's, not the word's: a known word
%% at the head goes lower, so that when a question moves it (`Is the house
%% big?' to `¿La casa es grande?') it is not `Es'; a name keeps its case
tr_head_lower(From, [w(W, upper)|Ws], [w(W, lower)|Ws]) :- ( tr_lexeme(From, W, _, _) ; tr_function_word(From, W) ), !.
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
%% a number or a quoted word is not a sentence this translates
tr_words([], []).
tr_words([word(W, C)|Ts], [w(W, C)|Ws]) :- !, tr_words(Ts, Ws).
tr_words([','|Ts], Ws) :- !, tr_words(Ts, Ws).

%% which way: a word whose lexeme the lesson gave is the lesson's, its
%% meaning is English; a word on both sides says nothing, and the majority
%% decides
tr_direction(Words, From, To) :-
    tr_votes(Words, 0, 0, Foreign, English),
    (   Foreign > English -> From = foreign, To = english
    ;   English > Foreign -> From = english, To = foreign
    ).

tr_votes([], F, E, F, E).
tr_votes([w(W, _)|Ws], F0, E0, F, E) :-
    ( tr_lexeme(foreign, W, _, _) -> Kf = 1 ; Kf = 0 ),
    ( tr_lexeme(english, W, _, _) -> Ke = 1 ; Ke = 0 ),
    ( Kf =:= Ke -> F1 = F0, E1 = E0 ; F1 is F0 + Kf, E1 is E0 + Ke ),
    tr_votes(Ws, F1, E1, F, E).

%% ---- one sentence ------------------------------------------------------------

%% a statement, or a question when the sentence ended in `?'
tr_translate(Words, From, To, 63, Out) :- !, tr_question(Words, From, To, Out).      % 63 is `?'
tr_translate(Words, From, To, Stop, Out) :- tr_statement(Words, From, To, Stop, Out).

%% the denial off, then split at the verb: the subject before it, and after
%% it an object phrase, a bare adjective agreeing with the subject, or nothing
tr_statement(Words0, From, To, Stop, Out) :-
    tr_negation(From, Words0, Words, Neg),
    append(Subject, [Verb|Rest], Words), Subject \== [], tr_verb(From, Verb, Lexeme), !,
    tr_phrase(Subject, From, To, SubjectOut, Noun, Number),
    tr_verb_out(From, To, Lexeme, Number, Neg, Verb, VerbOuts),
    tr_after(Rest, From, To, Noun, Number, RestOut),
    append(SubjectOut, VerbOuts, Front), append(Front, RestOut, Outs),
    tr_join(Outs, Stop, Out).

%% ---- a question -----------------------------------------------------------------
%%
%% Three forms. A yes-or-no question; `what' asking for the object; `who'
%% asking for the subject. The question word stands first in both
%% languages and is the lesson's vocabulary (`The word "qué" means "what"');
%% what it asks for is missing from its place. English fronts `does' or
%% `do' before the subject and the base form after it, or the copula
%% itself, and that is the translator's own; the lesson's language asks in
%% the statement's order, except that after a question word asking for
%% the object the verb comes before the subject (`¿Qué come el perro?'),
%% and it is read in either order (`¿Es grande la casa?' too). A mark the
%% lesson says begins the question (`The mark "¿" begins the question') is
%% put before the first word, and the sentence ends in `?'.

tr_question(Words0, From, To, Out) :-
    tr_asked(From, Words0, Words1, Asked, QW),
    tr_fronted(From, Words1, Words2, Front),
    tr_negation(From, Words2, Words, Neg),
    tr_question_parts(From, Asked, Front, Words, Subject, Verb, Lexeme, Rest), !,
    (   Asked == subject -> SubjectOut = [], Noun = none, Number = singular
    ;   Subject \== [], tr_phrase(Subject, From, To, SubjectOut, Noun, Number)
    ),
    tr_after(Rest, From, To, Noun, Number, RestOut),
    tr_meanings(From, Lexeme, verb, To, [V|_]),
    (   QW == none -> QWOut = []
    ;   QW = w(Q, QC), tr_lexeme(From, Q, QL, _), tr_meanings(From, QL, word, To, [QT|_]), QWOut = [o(QT, QC)]   % never a name
    ),
    Verb = w(_, Case),
    tr_question_words(To, Asked, V, Number, Neg, SubjectOut, RestOut, QWOut, Case, Outs),
    tr_join_question(To, Outs, Out).

%% the question word first, if any: what it asks for, by its English word
tr_asked(english, [w(Q, C)|Ws], Ws, Asked, w(Q, C)) :- tr_asked_by(Q, Asked), !.
tr_asked(foreign, [w(Q, C)|Ws], Ws, Asked, w(Q, C)) :- tr_solve(mean(Q, E)), tr_asked_by(E, Asked), !.
tr_asked(_, Ws, Ws, none, none).

tr_asked_by(what, object).
tr_asked_by(whom, object).
tr_asked_by(who, subject).

%% English fronts `does' or `do', or the copula itself
tr_fronted(english, [w(A, _)|Ws], Ws, aux) :- memberchk(A, [does, do]), !.
tr_fronted(english, [w(C, Case)|Ws], Ws, copula(w(C, Case))) :- memberchk(C, [is, are]), !.
tr_fronted(_, Ws, Ws, none).

%% the subject, the verb and the rest: with the subject asked, the verb
%% comes first; with the copula fronted it is the verb, and the subject is
%% the noun phrase after it (all of it when the object is asked); with
%% `does' fronted the verb is the base form after the subject; otherwise
%% the statement's order -- or the verb first, and then the subject after
%% it, the whole rest when the object is asked
tr_question_parts(From, subject, Front, Words, [], Verb, Lexeme, Rest) :- !,
    ( Front = copula(Verb) -> Rest = Words ; Words = [Verb|Rest] ),
    tr_verb(From, Verb, Lexeme).
tr_question_parts(From, Asked, copula(Verb), Words, Subject, Verb, Lexeme, Rest) :- !,
    tr_verb(From, Verb, Lexeme),
    ( Asked == object -> Subject = Words, Rest = [] ; tr_np_split(From, Words, Subject, Rest) ).
tr_question_parts(From, _, aux, Words, Subject, Verb, Lexeme, Rest) :- !,
    append(Subject, [Verb|Rest], Words), Subject \== [], tr_verb(From, Verb, Lexeme), !.
tr_question_parts(From, Asked, none, Words, Subject, Verb, Lexeme, Rest) :-
    append(Before, [Verb|After], Words), tr_verb(From, Verb, Lexeme), !,
    (   Before \== [] -> Subject = Before, Rest = After
    ;   Asked == object -> Subject = After, Rest = []
    ;   tr_inverted_split(From, After, Subject, Rest)
    ).

%% English's noun phrase at the head of the words: a name, or up to and
%% including the first word the lesson calls a noun
tr_np_split(From, [w(W, upper)|Rest], [w(W, upper)], Rest) :- \+ tr_lexeme(From, W, _, _), !.
tr_np_split(From, Words, NP, Rest) :- append(NP, Rest, Words), last(NP, N), tr_is(From, N, noun), !.
tr_np_split(_, Words, Words, []).

%% the verb came first: the subject is the name or the phrase after it, up
%% to the next article or name; or, when a bare adjective follows the verb
%% (`¿Es grande la casa?'), that adjective is the rest and the subject is
%% what follows it
tr_inverted_split(From, [w(W, upper)|Rest], [w(W, upper)], Rest) :- \+ tr_lexeme(From, W, _, _), !.
tr_inverted_split(From, [A|After], [A|Content], Rest) :-
    tr_is(From, A, article), !,
    append(Content, Rest, After), Content \== [],
    ( Rest == [] -> true ; Rest = [R|_], ( tr_is(From, R, article) ; R = w(_, upper) ) ), !.
tr_inverted_split(From, [A|Subject], Subject, [A]) :- tr_is(From, A, adjective), Subject \== [].

%% the words of the question in the target's order
tr_question_words(english, Asked, V, Number, Neg, Subject, Rest, QW, Case, Outs) :-
    ( Neg == yes -> Not = [o(not, Case)] ; Not = [] ),
    (   Asked == subject
    ->  tr_english_verb(V, singular, Neg, VW), tr_os(VW, Case, VO), tr_concat([QW, VO, Rest], Outs)
    ;   V == is
    ->  ( Number == plural -> C = are ; C = is ),
        tr_concat([QW, [o(C, Case)], Subject, Not, Rest], Outs)
    ;   tr_english_base(V, B),
        ( Number == plural -> A = do ; A = does ),
        tr_concat([QW, [o(A, Case)], Subject, Not, [o(B, Case)], Rest], Outs)
    ).
tr_question_words(foreign, Asked, V, Number, Neg, Subject, Rest, QW, Case, Outs) :-
    tr_inflect(foreign, verb, V, Number, VF),
    (   Neg == yes
    ->  once(tr_solve(mean(N, not))), ( tr_solve(follow(N, verb)) -> VW = [VF, N] ; VW = [N, VF] )
    ;   VW = [VF]
    ),
    tr_os(VW, Case, VO),
    (   Asked == subject -> tr_concat([QW, VO, Rest], Outs)
    ;   Asked == object -> tr_concat([QW, VO, Subject], Outs)
    ;   tr_concat([Subject, VO, Rest], Outs)
    ).

tr_os(Words, Case, Os) :- findall(o(W, Case), member(W, Words), Os).
tr_concat([], []).
tr_concat([L|Ls], Outs) :- tr_concat(Ls, Rest), append(L, Rest, Outs).

%% English's `not', and the `does' or `do' before it; the lesson's word for
%% `not' wherever it stands
tr_negation(english, Words, Rest, yes) :-
    append(A, [w(not, _)|B], Words), !,
    ( append(A0, [w(D, _)], A), memberchk(D, [does, do]) -> A1 = A0 ; A1 = A ),
    append(A1, B, Rest).
tr_negation(foreign, Words, Rest, yes) :-
    append(A, [w(N, _)|B], Words), tr_solve(mean(N, not)), !,
    append(A, B, Rest).
tr_negation(_, Words, Words, no).

%% the verb: the first word whose lexeme the lesson calls one
tr_verb(From, w(W, _), Lexeme) :- tr_lexeme(From, W, Lexeme, _), tr_class(From, Lexeme, verb), !.

tr_after([], _, _, _, _, []) :- !.
tr_after([A], From, To, Noun, Number, [Out]) :-
    tr_is(From, A, adjective), !,
    tr_word(A, From, To, adjective, Noun, Number, Out).
tr_after(Words, From, To, _, _, Outs) :- tr_phrase(Words, From, To, Outs, _, _).

%% a phrase: an article or none, then its content; Noun is the content's
%% noun in the target language (its singular, or the name), Number the
%% content's, and the article agrees with both -- or is nothing, as
%% English's `a' is in the plural
tr_phrase([A|Content], From, To, Outs, Noun, Number) :-
    tr_is(From, A, article), !,
    Content \== [],
    tr_content(Content, From, To, ContentOut, Noun, Number),
    tr_article(A, From, To, Noun, Number, ContentOut, ArticleOut),
    append(ArticleOut, ContentOut, Outs).
tr_phrase(Content, From, To, ContentOut, Noun, Number) :-
    tr_content(Content, From, To, ContentOut, Noun, Number).

%% the content: a single capitalised word the lesson does not know is a
%% name; otherwise one noun and the rest adjectives, each agreeing with it
%% in gender and number, in the target's order
tr_content([w(W, upper)], From, _, [o(W, upper)], W, singular) :-
    \+ tr_lexeme(From, W, _, _), !.
tr_content(Words, From, To, Outs, Noun, Number) :-
    tr_noun(Words, From, w(NW, NC), Adjectives),
    tr_lexeme(From, NW, NL, Number),
    tr_meanings(From, NL, noun, To, [Noun|_]),
    tr_inflect(To, noun, Noun, Number, NounForm),
    tr_adjectives(Adjectives, From, To, Noun, Number, AdjectiveOuts),
    tr_order(To, o(NounForm, NC), AdjectiveOuts, Outs).

%% the noun: the one word the lesson calls a noun; when it calls none the
%% last word in English, the grammar's own rule, and in the lesson's
%% language the first when adjectives follow the noun there. Two nouns in
%% one phrase is a phrase this does not read.
tr_noun(Words, From, Noun, Adjectives) :-
    findall(W, ( member(W, Words), tr_is(From, W, noun) ), Nouns),
    (   Nouns = [Noun] -> true
    ;   Nouns == [] -> tr_noun_by_position(Words, From, Noun)
    ),
    select(Noun, Words, Adjectives).

tr_noun_by_position(Words, english, Noun) :- last(Words, Noun).
tr_noun_by_position(Words, foreign, Noun) :- ( tr_solve(follow(_, noun)) -> Words = [Noun|_] ; last(Words, Noun) ).

%% each adjective as a(Lexeme, Out): the target's singular for the order
%% rule to ask about, and the word as it goes out
tr_adjectives([], _, _, _, _, []).
tr_adjectives([A|As], From, To, Noun, Number, [a(L, O)|Os]) :-
    tr_word(A, From, To, adjective, Noun, Number, O, L),
    tr_adjectives(As, From, To, Noun, Number, Os).

%% English puts an adjective before its noun; the lesson's language does what
%% its rule says of each adjective, follow(A, noun), and English's order otherwise
tr_order(english, Noun, Adjectives, Outs) :- findall(O, member(a(_, O), Adjectives), Os), append(Os, [Noun], Outs).
tr_order(foreign, Noun, Adjectives, Outs) :-
    tr_sides(Adjectives, Before, After),
    append(Before, [Noun|After], Outs).

tr_sides([], [], []).
tr_sides([a(L, O)|As], Before, After) :-
    tr_sides(As, Before1, After1),
    (   tr_solve(follow(L, noun)) -> Before = Before1, After = [O|After1]
    ;   Before = [O|Before1], After = After1
    ).

%% the article: English's `the' either way, `a' in the singular -- `an'
%% before a vowel -- and nothing in the plural; the lesson's language's by
%% the gender and the number of the noun
tr_article(A, From, english, _, Number, ContentOut, Outs) :- !,
    A = w(_, Case),
    tr_word(A, From, english, article, none, singular, o(T, _)),
    (   T == the -> Outs = [o(the, Case)]
    ;   Number == plural -> Outs = []
    ;   ContentOut = [o(First, _)|_], begin_with(First, vowel) -> Outs = [o(an, Case)]
    ;   Outs = [o(a, Case)]
    ).
tr_article(A, From, foreign, Noun, Number, _, [Out]) :-
    tr_word(A, From, foreign, article, Noun, Number, Out).

%% ---- the verb ------------------------------------------------------------------

%% the verb in the target, in the subject's number, denied or not: the
%% lesson's language puts its word for `not' before the verb, or after it
%% when follow(N, verb) proves; English is the translator's own
tr_verb_out(From, To, Lexeme, Number, Neg, w(_, Case), Outs) :-
    tr_meanings(From, Lexeme, verb, To, [V|_]),
    (   To == english
    ->  tr_english_verb(V, Number, Neg, Words)
    ;   tr_inflect(foreign, verb, V, Number, VF),
        (   Neg == yes
        ->  once(tr_solve(mean(N, not))),
            ( tr_solve(follow(N, verb)) -> Words = [VF, N] ; Words = [N, VF] )
        ;   Words = [VF]
        )
    ),
    findall(o(W, Case), member(W, Words), Outs).

%% English's verb: the copula is `is' or `are' and takes `not' after it;
%% any other verb is the third person the lesson gave in the singular, its
%% base in the plural, and `does not' or `do not' with the base when denied
tr_english_verb(is, Number, Neg, Words) :- !,
    ( Number == plural -> C = are ; C = is ),
    ( Neg == yes -> Words = [C, not] ; Words = [C] ).
tr_english_verb(V, Number, Neg, Words) :-
    tr_english_base(V, B),
    (   Neg == yes -> ( Number == plural -> Words = [do, not, B] ; Words = [does, not, B] )
    ;   Number == plural -> Words = [B]
    ;   Words = [V]
    ).

tr_english_base(has, have) :- !.
tr_english_base(V, B) :- reason_base(V, B).

%% ---- one word --------------------------------------------------------------------

%% one word into the other language: its lexeme's meanings of the class
%% asked for, among those the one agreeing with the noun where the target
%% has gender, and that in the number; a capitalised word with no lexeme
%% is a name and passes through. Out is o(Word, Case), the case travelling;
%% Lexeme is the target's singular, which the order rule is asked about.
tr_word(Word, From, To, Class, Noun, Number, Out) :- tr_word(Word, From, To, Class, Noun, Number, Out, _).
tr_word(w(W, Case), From, To, Class, Noun, Number, o(T, Case), L) :-
    (   tr_lexeme(From, W, S, _)
    ->  tr_meanings(From, S, Class, To, Ms),
        tr_agree(To, Ms, Noun, L),
        tr_inflect(To, Class, L, Number, T)
    ;   Case == upper, T = W, L = W
    ).

%% the meanings of a lexeme on the other side -- of the class asked for,
%% when the lesson classes any of them (the lesson's language has classes;
%% English words are what their translations are)
tr_meanings(From, L, Class, To, Ms) :-
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

%% ---- number: a lexeme, and a form in a number -------------------------------------

%% a word's lexeme on a side -- the form the lesson gave -- and its number:
%% the word itself when the lesson gave it; the singular of a plural the
%% lesson stated; in the lesson's language the singular whose ending rule
%% makes the word; in English a noun the stemmer takes back, `are' and
%% `have', and a base form whose third person the lesson gave
tr_lexeme(Side, W, W, singular) :- tr_known(Side, W).
tr_lexeme(english, an, a, singular) :- tr_known(english, a).
tr_lexeme(Side, W, S, plural) :- tr_solve(plural_of(W, S)), tr_known(Side, S).
tr_lexeme(foreign, W, S, plural) :- tr_solve(mean(S, _)), tr_rule_plural(S, W).
tr_lexeme(english, W, S, plural) :- tr_english_singular(W, S), tr_known(english, S).

tr_english_singular(are, is).
tr_english_singular(have, has).
tr_english_singular(W, S) :- reason_base(W, S), S \== W.
tr_english_singular(W, S) :- reason_third(W, S).

tr_known(foreign, W) :- tr_solve(mean(W, _)), !.
tr_known(english, E) :- tr_solve(mean(_, E)), !.

%% a form in a number: the singular as it is; a plural the lesson stated
%% first, then in the lesson's language the singular with the ending its
%% rule gives, and in English a noun by -s, -es or -ies and anything else
%% unchanged (the verb is tr_english_verb/4's). No rule, no plural: the
%% sentence is refused.
tr_inflect(_, _, S, singular, S) :- !.
tr_inflect(To, _, S, plural, P) :- tr_solve(plural_of(P0, S)), !, P = P0.
tr_inflect(foreign, _, S, plural, P) :- !, tr_rule_plural(S, P).
tr_inflect(english, noun, S, plural, P) :- !, reason_third(S, P).
tr_inflect(english, _, S, plural, S).

tr_rule_plural(S, P) :- tr_solve(take_in(S, E, plural)), atom(E), atom_concat(S, E, P).

%% ---- what the lesson says ------------------------------------------------------

%% mean(W, E) read from the side the word is on; `either' for a text whose
%% way the words did not settle
tr_meaning(foreign, W, E) :- tr_solve(mean(W, E)).
tr_meaning(english, E, W) :- tr_solve(mean(W, E)).

%% what a word is: its lexeme's class, which the lesson says of its own
%% words, and an English word is what any of its translations is
tr_is(Side, w(W, _), Class) :- tr_lexeme(Side, W, L, _), tr_class(Side, L, Class), !.
tr_class(foreign, W, C) :- tr_class_of(W, C).
tr_class(english, E, C) :- tr_solve(mean(W, E)), tr_class_of(W, C).
tr_class_of(W, C) :- member(C, [article, verb, noun, adjective]), G =.. [C, W], tr_solve(G).

%% a lesson that says nothing proves nothing: silence, never an error
tr_solve(Goal) :- catch(Goal, error(existence_error(procedure, _), _), fail).

%% ---- the sentence back as text ---------------------------------------------------

tr_join(Outs, Stop, Out) :-
    findall(A, ( member(o(T, C), Outs), ( C == upper -> tr_cap(T, A) ; A = T ) ), As),
    atomic_list_concat(As, ' ', S0),
    tr_cap(S0, S1),
    atom_codes(S1, Cs), append(Cs, [Stop], Cs1), atom_codes(Out, Cs1).

%% a question ends in `?', and in the lesson's language begins with the
%% mark the lesson says begins one, begin(M, question) -- `the question',
%% definite: `a question' would introduce an individual whose class is the
%% reader's own question/1 wrapper, and `begin', not `open', which is a
%% stream builtin's name
tr_join_question(To, Outs, Out) :-
    tr_join(Outs, 63, Out0),                                                % 63 is `?'
    (   To == foreign, once(tr_solve(begin(M, question))) -> atom_concat(M, Out0, Out)
    ;   Out = Out0
    ).

tr_cap(W, C) :- atom_codes(W, [F|R]), ( F >= 97, F =< 122 -> F1 is F - 32 ; F1 = F ), atom_codes(C, [F1|R]).
