# library/reasoning

Everything of the reasoning task lives here, and it is loaded with the
directory in the name:

    :- use_module(library(reasoning/reason)).
    :- use_module(library(reasoning/normalise)).
    :- use_module(library(reasoning/tagger)).

| file | what |
|---|---|
| `reason.pl` | a paragraph of controlled English in, predicates out: facts, `neg/1` facts, rules; `truth/2`, four-valued; `reason_refused/2`, which sentence would not parse |
| `normalise.pl` | the training data for the network: the grammar's twenty-three shapes as a generator with gold tags, ten noise transforms that carry the tags, and the assembler the round trip holds them to -- over the lexicon files in `lexicon/`, read as needed and never written into the code |
| `lexicon/` | the words, one class a file: 2500 census first names and some seventeen thousand WordNet words ranked by use; `SOURCES.md` says where each came from, and `tools/lexicon/build.pl` writes every file but the names from a WordNet 3.0 `dict` directory; `prose.txt` is eight thousand of WordNet's own example sentences, which nothing trains on and `tagger_refused/4` measures against |
| `tagger.pl` | the network: a tagger over library(tensor_expr) -- two embeddings, a GRU each way, a linear head -- trained on `normalise.pl`'s pairs and saved into the knowledge base; `tagger_normalise/4` takes prose to `reason.pl`'s terms, `tagger_evaluate/4` measures it on sentences training never saw and `tagger_refused/4` on sentences it must not read; a tagging the lexicon contradicts (`tagger_sane/2`, six rules) comes back X, outside, which the assembler refuses. Needs library(torch) to train or tag; its pure half loads anywhere |

The suite case for each is `test/reason.pl`, `test/normalise.pl` and
`test/tagger.pl`, and the lesson `tutorials/library/43-reason.pl`,
`44-normalise.pl` and `45-tagger.pl`. They
stay where the runners look -- `test/run.pl` takes `test/*.pl` and
`test/tutorials.pl` takes `tutorials/*/*.pl` -- because a case under
`library/` is a case nobody runs.

The loop is closed: `tagger.pl` trains in about eighty seconds on four
cores, over 300 sentences training never saw (seeds past the corpus)
0.9997 of the tags and 0.997 of the sentences are right, and of
forty-three hand-written sentences whose names, nouns, adjectives and
verbs are outside the lexicon forty-two give their terms -- `test/tagger.pl`
holds both, and puts a paragraph of such prose to `truth/2`.

The other half is what it refuses. Shown 875 sentences of real government
prose the first tagger "read" a tenth of them -- `Boston, Mass.` as
mass(boston) -- because every sentence it had ever seen had a reading.
Three ways of teaching the network to refuse (an outside tag on every
token of real prose, a sentence head over the shared states, a second
network) each cost a tenth of the hand-written sentences it should read.
What stayed is deterministic: six lexicon rules, `tagger_sane/2`, put to
every tagging before the assembler sees it, and a twelfth tag X for one
they contradict, which the assembler refuses. Measured, 0.93 to 0.94 of
WordNet's example sentences refused where the network alone refused 0.85,
0.96 of the government prose where it was 0.87, and the forty-three read
as before.

The corpus is the capability. Trained on 2048 pairs from the first
lexicon (ten names, twelve nouns, eleven shapes) the same network read its
own kind of sentence at 0.99 and lost `a small blue lamp` (no object had
carried two adjectives) and `lives in Lagos` (the only place it had seen
after a verb was an adjunct to drop). Each miss was a shape the generator
did not make, never the network, and each was fixed in `normalise.pl`:
twenty-three shapes and ten transforms now. The words were the other half:
a lexicon written by hand is a lexicon nobody grows, so it is files now,
`lexicon/`, census names and WordNet, and over those the corpus is the
lever twice over -- 8192 pairs read 0.96 of the sentences training never
saw whatever the step count, which is memorising; 16384 read 0.987 and
32768 read 0.993. What it still cannot know is a shape the grammar does
not read -- a definite subject, a passive -- and that is refused, never
quietly rewritten; the lesson's last section shows both.
