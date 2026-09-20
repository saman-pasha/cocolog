%% cocolog -- library(reasoning/translate): a language lesson as a knowledge
%% base, and a translation as a proof over it.
%%
%%     :- use_module(library(reasoning/translate)).
%%
%%     ?- reason_learn('Spanish is a language.
%%                      The noun "casa" means "house". The adjective "grande" means "big".
%%                      The verb "es" means "is". The feminine article "la" means "the".
%%                      Every noun that ends in "a" is feminine.
%%                      Every adjective follows the noun.'),
%%        reason_translate('The house is big.', S),
%%        reason_translate(S, E).
%%     S = 'La casa es grande.',
%%     E = 'The house is big.'
%%
%% TIER 2, clauses only, over library(reasoning/reason). NOTHING HERE KNOWS
%% A WORD OF SPANISH. The lesson is the controlled English -- a word in
%% quotation marks is MENTIONED and stands for itself, `the noun "casa"'
%% says what it is, `every noun that ends in "a" is feminine' is a rule --
%% read by reason_text/2 and asserted by reason_learn/1; and what this
%% library knows is WHAT TO ASK. Five questions, and the lesson's facts and
%% rules answer them, however the lesson put them:
%%
%%     mean(W, E)                      the lesson's word W means the English word E
%%     noun(W)  adjective(W)  verb(W)  article(W)      what a word is
%%     feminine(W)  masculine(W)       its gender, said of it or ruled
%%     follow(A, noun)                 the adjective A stands after its noun
%%     language(L)                     the language, `Spanish is a language'
%%
%% So a lesson in Italian, or one whose rule is `Every adjective precedes
%% the noun', is read by the same clauses -- and a lesson written as Prolog
%% facts in those shapes works with no sentence of English at all.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     reason_translate(+Text, -Translation)
%%         SIMPLE sentences, each a subject, a verb, and after it an object,
%%         an adjective or nothing; a subject or an object a name or a
%%         phrase -- an article or none, adjectives, a noun. From English
%%         into the language the lesson teaches, or from it into English:
%%         which way, the words say, a word the lesson gave a meaning being
%%         the lesson's and the meaning English. Translation is an atom, a
%%         sentence capitalised and ending as it ended. FAILS for a
%%         sentence it cannot translate, whole and never half: a word the
%%         lesson gives no meaning (a capitalised one is a name and passes
%%         through), no verb, two nouns in one phrase, a number, a word in
%%         quotation marks; reason_untranslated/2 names the words.
%%
%%     reason_translate(+Text, +Into, -Translation)
%%         The same, Into naming the language: english, or the name the
%%         lesson gave its own (`Spanish is a language.' is language(spanish),
%%         so `spanish'). Any other name is a domain_error.
%%
%%     reason_untranslated(+Text, -Words)
%%         The words of the text the lesson gives no meaning, names left
%%         out; [] when every word is known.
%%
%% ---- HOW A SENTENCE IS TRANSLATED ----------------------------------------
%%
%% Word by word, and the phrase is the unit of agreement. A sentence is
%% split at its VERB, the first word the lesson calls one, into the
%% subject phrase and what follows. A phrase is an article or none and
%% then its content: the noun is the word the lesson calls a noun, and
%% failing that the last word in English (the grammar's own rule) and, in
%% the lesson's language, the first when adjectives follow the noun there;
%% every other word is an adjective. Each word is looked up, mean(W, E)
%% read from whichever side the word is on, and where the target is the
%% lesson's language the ARTICLE and each ADJECTIVE are chosen among the
%% words the lesson gives for the English one by the gender of the noun:
%% one of the noun's gender first, one with no gender next (`grande'), the
%% first otherwise. A bare adjective after the verb agrees with the
%% subject's noun. An adjective goes after the noun when follow(A, noun)
%% proves and before it otherwise, which is English's order and the
%% default. A capitalised word the lesson does not know is a name and
%% passes through as written; the case of every word travels with it.
%%
%% ---- WHAT IT IS NOT ---------------------------------------------------
%%
%% It is not a translator of prose. One clause, present tense, third
%% person singular: no plural, no pronoun, no question, no negation, no
%% idiom -- a word means a word, and a lesson that wants `does not' writes
%% a word for it. ONE LANGUAGE BESIDE ENGLISH per knowledge base: mean/2
%% carries no language, so two lessons loaded together are one vocabulary.
%% And it decides nothing about a word the lesson left out: a sentence
%% with one is refused whole, never half translated, and
%% reason_untranslated/2 says which word to teach.

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
                 member(w(W, Case), Ws), Case \== upper, \+ tr_meaning(From, W, _) ),
            Ws0),
    list_to_set(Ws0, Words).

%% into English from the lesson's language, or into the language the lesson
%% named -- `Spanish is a language' is language(spanish)
tr_into(english, foreign, english) :- !.
tr_into(L, english, foreign) :- atom(L), tr_solve(language(L)), !.
tr_into(L, _, _) :- throw(error(domain_error(language, L), reason_translate/3)).

%% each sentence its own way when none was given: the words decide
tr_each([], _, []).
tr_each([Piece-Stop|Ps], Way, [Out|Outs]) :-
    reason_tokens(Piece, Tokens), tr_words(Tokens, Words), Words \== [],
    ( Way == any -> tr_direction(Words, From, To) ; Way = From-To ),
    tr_translate(Words, From, To, Stop, Out),
    tr_each(Ps, Way, Outs).

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

%% which way: a word the lesson gave a meaning is the lesson's, its meaning
%% is English; a word on both sides says nothing, and the majority decides
tr_direction(Words, From, To) :-
    tr_votes(Words, 0, 0, Foreign, English),
    (   Foreign > English -> From = foreign, To = english
    ;   English > Foreign -> From = english, To = foreign
    ).

tr_votes([], F, E, F, E).
tr_votes([w(W, _)|Ws], F0, E0, F, E) :-
    ( tr_meaning(foreign, W, _) -> Kf = 1 ; Kf = 0 ),
    ( tr_meaning(english, W, _) -> Ke = 1 ; Ke = 0 ),
    ( Kf =:= Ke -> F1 = F0, E1 = E0 ; F1 is F0 + Kf, E1 is E0 + Ke ),
    tr_votes(Ws, F1, E1, F, E).

%% ---- one sentence ------------------------------------------------------------

%% split at the verb: the subject before it, and after it an object phrase,
%% a bare adjective agreeing with the subject's noun, or nothing
tr_translate(Words, From, To, Stop, Out) :-
    append(Subject, [Verb|Rest], Words), Subject \== [], tr_is(From, Verb, verb), !,
    tr_phrase(Subject, From, To, SubjectOut, Noun),
    tr_word(Verb, From, To, verb, none, VerbOut),
    tr_after(Rest, From, To, Noun, RestOut),
    append(SubjectOut, [VerbOut|RestOut], Outs),
    tr_join(Outs, Stop, Out).

tr_after([], _, _, _, []) :- !.
tr_after([A], From, To, Noun, [Out]) :- tr_is(From, A, adjective), !, tr_word(A, From, To, adjective, Noun, Out).
tr_after(Words, From, To, _, Outs) :- tr_phrase(Words, From, To, Outs, _).

%% a phrase: an article or none, then its content; Noun is the content's
%% noun in the target language (or the name), what the article agrees with
tr_phrase([A|Content], From, To, [ArticleOut|ContentOut], Noun) :-
    tr_is(From, A, article), !,
    Content \== [],
    tr_content(Content, From, To, ContentOut, Noun),
    tr_word(A, From, To, article, Noun, ArticleOut).
tr_phrase(Content, From, To, ContentOut, Noun) :-
    tr_content(Content, From, To, ContentOut, Noun).

%% the content: a single capitalised word the lesson does not know is a
%% name; otherwise one noun and the rest adjectives, each agreeing with it,
%% in the target's order
tr_content([w(W, upper)], From, _, [o(W, upper)], W) :-
    \+ tr_meaning(From, W, _), !.
tr_content(Words, From, To, Outs, Noun) :-
    tr_noun(Words, From, NounWord, Adjectives),
    tr_word(NounWord, From, To, noun, none, o(Noun, Case)),
    tr_adjectives(Adjectives, From, To, Noun, AdjectiveOuts),
    tr_order(To, o(Noun, Case), AdjectiveOuts, Outs).

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

tr_adjectives([], _, _, _, []).
tr_adjectives([A|As], From, To, Noun, [O|Os]) :- tr_word(A, From, To, adjective, Noun, O), tr_adjectives(As, From, To, Noun, Os).

%% English puts an adjective before its noun; the lesson's language does what
%% its rule says of each adjective, follow(A, noun), and English's order otherwise
tr_order(english, Noun, Adjectives, Outs) :- append(Adjectives, [Noun], Outs).
tr_order(foreign, Noun, Adjectives, Outs) :-
    tr_sides(Adjectives, Before, After),
    append(Before, [Noun|After], Outs).

tr_sides([], [], []).
tr_sides([o(A, C)|As], Before, After) :-
    tr_sides(As, Before1, After1),
    (   tr_solve(follow(A, noun)) -> Before = Before1, After = [o(A, C)|After1]
    ;   Before = [o(A, C)|Before1], After = After1
    ).

%% ---- one word --------------------------------------------------------------------

%% the lesson's meanings for it -- of the class asked for, when the lesson
%% classes any of them -- and among those the one agreeing with the noun
%% where the target has gender; a capitalised word with no meaning is a
%% name and passes through. Out is o(Word, Case), the case travelling.
tr_word(w(W, Case), From, To, Class, Noun, o(T, Case)) :-
    findall(M, tr_meaning(From, W, M), Ms0),
    (   Ms0 == []
    ->  Case == upper, T = W
    ;   tr_of_class(Ms0, To, Class, Ms),
        tr_agree(To, Ms, Noun, T)
    ).

tr_of_class(Ms0, foreign, Class, Ms) :- findall(M, ( member(M, Ms0), tr_class_of(M, Class) ), Ms1), Ms1 \== [], !, Ms = Ms1.
tr_of_class(Ms0, _, _, Ms0).

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

%% ---- what the lesson says ------------------------------------------------------

%% mean(W, E) read from the side the word is on; `either' for a text whose
%% way the words did not settle
tr_meaning(foreign, W, E) :- tr_solve(mean(W, E)).
tr_meaning(english, E, W) :- tr_solve(mean(W, E)).
tr_meaning(either, W, M) :- ( tr_meaning(foreign, W, M) ; tr_meaning(english, W, M) ).

%% what a word is: the lesson says of its own words, and an English word is
%% what any of its translations is
tr_is(Side, w(W, _), Class) :- tr_class(Side, W, Class), !.
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

tr_cap(W, C) :- atom_codes(W, [F|R]), ( F >= 97, F =< 122 -> F1 is F - 32 ; F1 = F ), atom_codes(C, [F1|R]).
