%% cocolog tutorial 45 -- library(reasoning/tagger): the network that reads typed text for the grammar.
%%
%% TIER 2: `use_module(library(reasoning/tagger))', from library/reasoning/tagger.pl.
%% Clauses only, over library(tensor_expr) and library(torch) -- and this
%% lesson TRAINS, so it needs library/torch.so built (sh modules/torch/build.sh).
%%
%%     cocolog -s tutorials/library/45-tagger.pl
%%
%% THE PROBLEM THIS SOLVES. Tutorial 43 ends on prose that
%% library(reasoning/reason) refuses, and tutorial 44 makes the data that
%% could teach a network to label every token -- subject, relation, object,
%% noise -- so that the assembler can rebuild a sentence in the grammar's
%% shapes. This lesson trains that network, in about half a minute on four
%% cores with no GPU, and closes the loop: typed prose in, the grammar's
%% terms out, and truth/2 answering questions about them.
%%
%% THE CORPUS IS THE CAPABILITY. The generator is unbounded in seeds and
%% bounded in variety, and variety is what carries a tagger to words it
%% never saw: fifty names, forty-eight nouns, twenty shapes, ten kinds of
%% noise, and 8192 pairs of them by default. Trained on 2048 the same
%% network lost `lives in Lagos' to the adjunct reading; on 8192 it reads
%% forty-two hand-written sentences out of forty-two (test/tagger.pl), and
%% the extra pairs cost seconds, because a training is priced by its
%% optimiser steps and not by its corpus.
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
    must('and the SHAPE travels beside the word: upper, lower, comma, upper', Shapes, [2, 1, 3, 2]),

    format("~n2. Training: 300 Adam steps over 8192 pairs, the loss printed every 40~n", []),
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
    Prose = 'Actually, Mia really likes Zed, obviously. Bob needs a ladder. In fact, every clerk that is not exempt must sign the form.',
    tagger_normalise(M, Prose, Controlled, Terms),
    show('controlled', Controlled),
    Terms = [T1, T2, T3, Rule],
    must('three facts, with Mia, Zed and the ladder copied', [T1, T2, T3], [like(mia, zed), ladder(ladder_1), need(bob, ladder_1)]),
    show('and a rule', Rule),
    forall(member(T, Terms), assertz(T)),
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
    format("   -- a shape the generator does not make is a shape the grammar does not read,~n", []),
    format("   and the tagger cannot reach past the grammar: what it gets wrong is REFUSED,~n", []),
    format("   never quietly rewritten. The fix is data -- a shape in library(reasoning/normalise)~n", []),
    format("   and a rule in library(reasoning/reason) -- and test/tagger.pl's forty-two~n", []),
    format("   hand-written sentences are how the next one is measured before it ships.~n", []),
    tagger_free(M),
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
