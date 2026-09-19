%% cocolog tutorial 45 -- library(reasoning/tagger): the network that reads typed text for the grammar.
%%
%% TIER 2: `use_module(library(reasoning/tagger))', from library/reasoning/tagger.pl.
%% Clauses only, over library(tensor_expr) and library(torch) -- and this
%% lesson TRAINS, so it needs library/torch.so built (sh modules/torch/build.sh),
%% and about two minutes on four cores.
%%
%%     cocolog -s tutorials/library/45-tagger.pl
%%
%% THE PROBLEM THIS SOLVES. Tutorial 43 ends on prose that
%% library(reasoning/reason) refuses, and tutorial 44 makes the data that
%% could teach a network to label every token -- subject, relation, object,
%% noise -- so that the assembler can rebuild a sentence in the grammar's
%% shapes. This lesson trains that network, in about eighty seconds on four
%% cores with no GPU, and closes the loop: typed prose in, the grammar's
%% terms out, and truth/2 answering questions about them -- and shows the
%% other half, real prose it must not read, refused.
%%
%% THE CORPUS IS THE CAPABILITY. The generator is unbounded in seeds and
%% bounded in variety, and variety is what carries a tagger to words it
%% never saw: thirty-three shapes, eleven kinds of noise, and a lexicon that is
%% files beside the library -- 2500 census names and some seventeen
%% thousand WordNet words, library/reasoning/lexicon/ -- and 16384 pairs
%% of them by default. Over that lexicon 8192 pairs read 0.96 of the
%% sentences training never saw whatever the step count, which is
%% memorising; 16384 read 0.987 and 32768 read 0.993: a corpus too large
%% to memorise is what makes a tagger generalise, and the extra pairs cost
%% seconds, because a training is priced by its optimiser steps.
%%
%% NOTHING IS GENERATED. The network never writes a word: it labels the
%% words it was given, the assembler copies them, and the grammar reads the
%% result or refuses it. So a name or a noun the network has never seen is
%% copied into the term, and a wrong label costs a refusal the program can
%% see -- never a sentence that was quietly rewritten.

:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).
:- use_module(library(reasoning/tagger)).

main :-
    format("~n1. The vocabulary and the encoding, before any tensor~n", []),
    normalise_corpus(64, Pairs),
    tagger_vocabulary(Pairs, V), tagger_size(V, NV),
    show('words in 64 pairs, plus <pad> and <unk>', NV),
    tagger_word_id(V, alice, IdAlice), show('the id of alice', IdAlice),
    tagger_word_id(V, zed, IdZed),
    must('a word never seen is 1, <unk>', IdZed, 1),
    tagger_encode(V, [word(alice, upper), word(owns, lower), ',', word(zed, upper)], _, Shapes),
    must('and the SHAPE travels beside the word: upper, lower with -s, comma, upper again (a name whatever it ends in)', Shapes, [2, 4, 3, 2]),

    format("~n2. Training: 400 Adam steps over 16384 pairs, the loss printed every 40~n", []),
    tagger_train(lesson, [verbose(true)]),
    tagger_load(lesson, M),
    format("   saved under `lesson', loaded back~n", []),

    format("~n3. A noisy sentence, with a name the network never saw~n", []),
    Text3 = 'Well, Zed really owns a red car, obviously.',
    reason_tokens(Text3, Toks0), append(Toks3, ['.'], Toks0),
    tagger_tag(M, Toks3, Tags3),
    show('tokens', Toks3),
    must('tags: the fillers and the adverb D, Zed S, owns R, a T, red A, car O', Tags3, ['D', 'D', 'S', 'D', 'R', 'T', 'A', 'O', 'D', 'D']),
    normalise_assemble(Toks3, Tags3, Asm3),
    must('assembled', Asm3, 'Zed owns a red car.'),

    format("~n4. Prose to predicates, and then questions -- the loop closed~n", []),
    Prose = 'Actually, Mia really likes Zed, obviously. Bob needs a ladder. In fact, every clerk that is not exempt must sign the form. Dana rents a flat in Bristol. Dana is a tenant and, as far as I know, is not late. Well, does Dana rent a flat in Bristol?',
    tagger_normalise(M, Prose, Controlled, Terms),
    show('controlled', Controlled),
    Terms = [T1, T2, T3, Rule, T5, T6, T7, T8, Q9],
    must('three facts, with Mia, Zed and the ladder copied', [T1, T2, T3], [like(mia, zed), ladder(ladder_1), need(bob, ladder_1)]),
    show('and a rule', Rule),
    must('and a place after an object kept: rent_in/3', [T5, T6], [flat(flat_1), rent_in(dana, flat_1, bristol)]),
    must('and a filler after the conjunction dropped, the subject the second clause left out supplied', [T7, T8], [tenant(dana), neg(late(dana))]),
    ( Q9 = question((flat(F9), rent_in(dana, F9b, bristol))), F9 == F9b, var(F9) -> G9 = a_goal_with_a_variable ; G9 = Q9 ),
    must('and a question is a GOAL, the flat it asks about a variable', G9, a_goal_with_a_variable),
    forall(( member(T, Terms), \+ functor(T, question, _) ), assertz(T)),
    tagger_ask(M, 'Does Dana rent a flat in Bristol?', [A9a]), must('asked, once the facts are in: yes, and the reason is the fact', A9a, yes(fact)),
    tagger_ask(M, 'Who is a tenant?', [A9b]), must('who is a tenant', A9b, [dana-fact]),
    tagger_ask(M, 'Is Dana late?', [A9c]), must('is Dana late -- no, the text denied it', A9c, no(denied(neg(late(dana))))),
    assertz(clerk(ann)),
    truth(like(mia, zed), V1), must('truth(like(mia, zed))', V1, true),
    truth(like(zed, mia), V2), must('truth(like(zed, mia)) -- nothing said so', V2, unknown),
    truth(must_sign(ann, form), V3), must('truth(must_sign(ann, form)) -- Ann is a clerk and not exempt', V3, true),

    format("~n5. Measured on 200 sentences training never saw -- seeds past the corpus~n", []),
    tagger_evaluate(M, 30001, 200, report(Tok, Sent, Acc, _)),
    show('tags right, a token', Tok),
    show('sentences with every tag right', Sent),
    show('assembled and parsed to the clean terms', Acc),
    ( Tok >= 0.97 -> Ok5 = yes ; Ok5 = no ),
    must('at least 0.97 of the tags', Ok5, yes),

    format("~n6. What it cannot know, and how that shows~n", []),
    ( tagger_normalise(M, 'The dog sleeps.', _, _) -> R6 = read ; R6 = refused ),
    must('a definite subject is no shape the generator makes: refused', R6, refused),
    ( tagger_normalise(M, 'The badge is held by Zed.', _, _) -> R7 = read ; R7 = refused ),
    must('a passive is no shape either: refused', R7, refused),
    ( tagger_normalise(M, 'Boston, Mass.', _, _) -> R8 = read ; R8 = refused ),
    must('real prose the lexicon contradicts -- Boston tagged subject, Mass. a relation: refused', R8, refused),
    tagger_refused(M, 6001, 100, Rate),
    show('of 100 real sentences from prose.txt, WordNet''s own examples, refused', Rate),
    format("   -- a shape the generator does not make is a shape the grammar does not read,~n", []),
    format("   and the tagger cannot reach past the grammar: what it gets wrong is REFUSED,~n", []),
    format("   never quietly rewritten. And what the grammar WOULD read -- `Vulpine cunning.'~n", []),
    format("   as cunning(vulpine) -- the lexicon refuses first: a tagging it contradicts~n", []),
    format("   comes back X throughout. The fix for a miss is data -- a shape in~n", []),
    format("   library(reasoning/normalise), a rule in library(reasoning/reason) -- and~n", []),
    format("   test/tagger.pl's forty-three hand-written sentences are how the next one is~n", []),
    format("   measured before it ships.~n", []),
    tagger_free(M),

    format("~n7. And without training: the shipped model, library/reasoning/model.rows~n", []),
    (   catch(tagger_pretrained(Pre), error(existence_error(tagger, pretrained), _), fail)
    ->  ( tagger_normalise(Pre, 'Honestly, Kim rents a small flat in Oslo.', C70, T70) -> true ; C70 = refused, T70 = refused ),
        show('controlled', C70),
        must('read by a model nobody here trained', T70, [flat(flat_1), small(flat_1), rent_in(kim, flat_1, oslo)]),
        tagger_free(Pre)
    ;   format("   (no shipped model: sh tools/tagger/train.sh writes it)~n", [])
    ),
    nl, write(done), nl.

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
