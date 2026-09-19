# library/reasoning

Everything of the reasoning task lives here, and it is loaded with the
directory in the name:

    :- use_module(library(reasoning/reason)).
    :- use_module(library(reasoning/normalise)).
    :- use_module(library(reasoning/tagger)).

| file | what |
|---|---|
| `reason.pl` | a paragraph of controlled English in, predicates out: facts, `neg/1` facts, rules; `truth/2`, four-valued; `reason_refused/2`, which sentence would not parse |
| `normalise.pl` | the training data for the network: the grammar's twenty shapes over a lexicon of some three hundred words as a generator with gold tags, ten noise transforms that carry the tags, and the assembler the round trip holds them to |
| `tagger.pl` | the network: a tagger over library(tensor_expr) -- two embeddings, a GRU each way, a linear head -- trained on `normalise.pl`'s pairs and saved into the knowledge base; `tagger_normalise/4` takes prose to `reason.pl`'s terms, `tagger_evaluate/4` measures it on sentences training never saw. Needs library(torch) to train or tag; its pure half loads anywhere |

The suite case for each is `test/reason.pl`, `test/normalise.pl` and
`test/tagger.pl`, and the lesson `tutorials/library/43-reason.pl`,
`44-normalise.pl` and `45-tagger.pl`. They
stay where the runners look -- `test/run.pl` takes `test/*.pl` and
`test/tutorials.pl` takes `tutorials/*/*.pl` -- because a case under
`library/` is a case nobody runs.

The loop is closed: `tagger.pl` trains in about thirty-five seconds on
four cores, over 300 sentences training never saw (seeds past the corpus)
every tag is right, and forty-two hand-written sentences whose names,
nouns, adjectives and verbs are outside the lexicon all give their terms
-- `test/tagger.pl` holds both, and puts a paragraph of such prose to
`truth/2`.

The corpus is the capability. Trained on 2048 pairs from the first
lexicon (ten names, twelve nouns, eleven shapes) the same network read its
own kind of sentence at 0.99 and lost `a small blue lamp` (no object had
carried two adjectives) and `lives in Lagos` (the only place it had seen
after a verb was an adjunct to drop). Each miss was a shape the generator
did not make, never the network, and each was fixed in `normalise.pl`:
fifty names, forty-eight nouns, twenty shapes, ten transforms, 8192 pairs
by default. The extra pairs cost seconds, because a training is priced by
its optimiser steps and not by its corpus. What it still cannot know is a
shape the grammar does not read -- a definite subject, a passive -- and
that is refused, never quietly rewritten; the lesson's last section shows
both.
