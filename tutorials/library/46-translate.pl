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
%% TEACHES: twenty lines of Spanish in the same controlled English, and
%% what comes out is a vocabulary as facts, a grammar as rules, and a
%% translator that asks the knowledge base and knows no word of Spanish
%% itself. Nothing was trained and nothing was written into the library
%% for it: the lesson is the whole of what the translator knows.
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
%% follows its noun, follow(A, noun). The lesson answers in its own words,
%% and a lesson in Italian, or one whose rule is that every adjective
%% PRECEDES the noun, is read by the same clauses. Section 6 proves it by
%% taking the order rule away.

:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/translate)).

lesson('Spanish is a language.
The noun "casa" means "house".
The noun "perro" means "dog".
The noun "gato" means "cat".
The noun "mesa" means "table".
The noun "libro" means "book".
The noun "pan" means "bread".
The adjective "grande" means "big".
The masculine adjective "rojo" means "red".
The feminine adjective "roja" means "red".
The verb "es" means "is".
The verb "come" means "eats".
The verb "lee" means "reads".
The verb "tiene" means "has".
The masculine article "el" means "the".
The feminine article "la" means "the".
The masculine article "un" means "a".
The feminine article "una" means "a".
Every noun that ends in "a" is feminine.
Every noun that does not end in "a" is masculine.
Every adjective follows the noun.').

main :-
    format("~n1. The lesson: twenty lines of controlled English, and what they say~n", []),
    lesson(Text),
    reason_learn(Text, Terms),
    length(Terms, N),
    must('terms learned', N, 44),
    Terms = [T1, T2, T3|_],
    must('the language', T1, language(spanish)),
    must('a class fact about the word, then what it means', T2-T3, noun(casa)-mean(casa, house)),
    member((feminine(X4) :- B4), Terms), copy_term(X4-B4, x-B4c),
    must('a rule over the letters of a word', B4c, (noun(x), end_in(x, a))),
    member((follow(X5, noun) :- B5), Terms), copy_term(X5-B5, x-B5c),
    must('and the rule of order', B5c, adjective(x)),
    show('la, as the lesson put it', [article(la), feminine(la), mean(la, the)]),

    format("~n2. The lesson questioned -- reason_ask/2 over the same knowledge base~n", []),
    reason_ask('Is "mesa" feminine? Is "perro" feminine? What does "perro" mean? Why is "mesa" feminine?', As),
    As = [A1, A2, A3, A4],
    must('yes, by the rule, with the body that proved', A1, yes(rule((feminine(mesa) :- noun(mesa), end_in(mesa, a))))),
    must('unknown: the lesson never said, and unknown is an answer', A2, unknown),
    must('the meaning, and that it was said', A3, [dog-fact]),
    must('the whole proof in sentences', A4, because('"mesa" is feminine because "mesa" is a noun and "mesa" ends in "a".')),

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
    must('two sentences, each ending as it ended', S5, 'La casa es grande. El perro come el pan!'),

    format("~n4. Into English: which way, the words say~n", []),
    reason_translate('La casa es grande.', E1),
    must('the words are the lesson''s, so the target is English', E1, 'The house is big.'),
    reason_translate('Maria tiene una mesa roja.', E2),
    must('the adjective back before its noun', E2, 'Maria has a red table.'),
    reason_translate(S2, E3),
    must('the round trip', E3, 'The dog eats the bread.'),
    reason_translate('The cat reads a big book.', spanish, S6),
    must('or name the language: the name the lesson gave it', S6, 'El gato lee un libro grande.'),
    reason_translate(S6, english, E6),
    must('and english', E6, 'The cat reads a big book.'),

    format("~n5. What it refuses -- whole, never half -- and reason_untranslated/2~n", []),
    ( reason_translate('The house is small.', _) -> R1 = translated ; R1 = refused ),
    must('a word the lesson has no meaning for', R1, refused),
    reason_untranslated('The house is small.', U1),
    must('and which word to teach', U1, [small]),
    reason_untranslated('Maria sleeps in the house.', U2),
    must('a name is not reported; every other unknown word is', U2, [sleeps, in]),
    catch(( reason_translate('La casa es grande.', french, _), E7 = none ), error(E7, _), true),
    must('a language the lesson did not name', E7, domain_error(language, french)),

    format("~n6. The order is the rule, not the code: take the rule away~n", []),
    retract((follow(X8, noun) :- adjective(X8))),
    reason_translate('Maria has a red table.', S8),
    must('without `every adjective follows the noun'', English''s order', S8, 'Maria tiene una roja mesa.'),
    assertz((follow(X9, noun) :- adjective(X9))),
    reason_translate('Maria has a red table.', S9),
    must('the rule back, the order back', S9, 'Maria tiene una mesa roja.'),
    reason_learn('The noun "mano" means "hand". "mano" is feminine.'),
    reason_translate('The hand is red.', S10),
    must('an exception the lesson states wins over the rule: feminine is asked first', S10, 'La mano es roja.'),

    format("~n7. The lesson outlined -- reason_outline/2 over the same text~n", []),
    reason_outline(Text, Lines),
    Lines = [L1, L2|_],
    must('the class most is said about, with its members and its rules', L1,
         'Noun ("casa", "perro", "gato", "mesa", "libro" and "pan"): every noun that ends in "a" is feminine; every noun that does not end in "a" is masculine.'),
    must('then the adjectives', L2, 'Adjective ("grande", "rojo" and "roja"): every adjective follows the noun.'),
    memberchk('"la", an article: feminine; means "the".', Lines),
    memberchk('Feminine: a noun that ends in "a".', Lines),
    show('a word''s own line, and a definition''s', ['"la", an article: feminine; means "the".', 'Feminine: a noun that ends in "a".']),

    format("~nDone. A lesson is a knowledge base; a translation is a proof over it.~n", []).

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
