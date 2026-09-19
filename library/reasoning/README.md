# library/reasoning

Everything of the reasoning task lives here, and it is loaded with the
directory in the name:

    :- use_module(library(reasoning/reason)).
    :- use_module(library(reasoning/normalise)).
    :- use_module(library(reasoning/tagger)).

| file | what |
|---|---|
| `reason.pl` | a paragraph of controlled English in, predicates out -- and, optionally, typed prose in through the shipped tagger (`reason_prose/2`, `reason_ask_prose/2`, loaded on first use): facts, `neg/1` facts, rules, and a question as a GOAL with a variable where `who`, `what` or `where` stood; `truth/2`, four-valued; `reason_ask/2`, a question answered with the fact, the rule or the denial it rests on; `reason_refused/2`, which sentence would not parse |
| `normalise.pl` | the training data for the network: the grammar's thirty-three shapes as a generator with gold tags, eleven noise transforms that carry the tags, and the assembler the round trip holds them to -- over the lexicon files in `lexicon/`, read as needed and never written into the code |
| `lexicon/` | the words, one class a file: 2500 census first names and some seventeen thousand WordNet words ranked by use for the generator, and in `known_*.txt` every SemCor-counted noun, verb, adjective and adverb for the tagger's judge; `SOURCES.md` says where each came from, and `tools/lexicon/build.pl` writes every file but the names from a WordNet 3.0 `dict` directory; `prose.txt` is eight thousand of WordNet's own example sentences, which nothing trains on and `tagger_refused/4` measures against |
| `model.rows` | the SHIPPED tagger: the model's rows as `tagger_export/2` writes them, eight thousand lines, which `tagger_pretrained/1` consults as a module when the knowledge base a program proves against holds no model named `tagger` of its own -- so a `--local` program reads prose with no training and no store; `sh tools/tagger/train.sh` writes it, two minutes with libtorch |
| `tagger.pl` | the network: a tagger over library(tensor_expr) -- two embeddings, a GRU each way, a linear head -- trained on `normalise.pl`'s pairs and saved into the knowledge base; `tagger_normalise/4` takes prose to `reason.pl`'s terms, `tagger_ask/3` answers a typed question, `tagger_pretrained/1` loads the model the knowledge base keeps or the shipped one, `tagger_evaluate/4` measures it on sentences training never saw and `tagger_refused/4` on sentences it must not read; a tagging the lexicon contradicts (`tagger_sane/2`, six rules) comes back X, outside, which the assembler refuses. Needs library(torch) to train or tag; its pure half loads anywhere |

The suite case for each is `test/reason.pl`, `test/normalise.pl` and
`test/tagger.pl`, and the lesson `tutorials/library/43-reason.pl`,
`44-normalise.pl` and `45-tagger.pl`. They
stay where the runners look -- `test/run.pl` takes `test/*.pl` and
`test/tutorials.pl` takes `tutorials/*/*.pl` -- because a case under
`library/` is a case nobody runs.

The loop is closed: `tagger.pl` trains in about eighty seconds on four
cores, over 300 sentences training never saw (seeds past the corpus)
0.9997 of the tags and 0.997 of the sentences are right, and of
forty-five hand-written sentences whose names, nouns, adjectives and
verbs are outside the lexicon forty-three or more give their terms --
`test/tagger.pl` holds both, and puts a paragraph of such prose, a place
after an object included, to `truth/2`.

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
thirty-three shapes and eleven transforms now -- four shapes a
place after an object, `rents a flat in Bristol', which a noise transform
had taught the network to DROP until the grammar learned to read it as
rent_in/3; a filler after a conjunction, `and, as far as I know,', a
position typed prose uses and the generator never had; and a second fact
about the same subject, `Priya is a baker and is licensed' or `and she is
licensed'. That last one is STATE carried from sentence to sentence: the
assembler supplies the subject a break left out, and the grammar resolves
`she', `he' or `they' to the subject of the last fact -- `Priya is a
baker. She is licensed.' is two facts about Priya, in `reason.pl` itself.
And six shapes are QUESTIONS: `Does Priya sell the bread?' is the goal
`sell(priya, bread)`, `Who rents a flat in Bristol?' the goal with a
variable where `who' stood, and `reason_ask/2` answers either against the
knowledge base with the REASON beside the answer -- the fact that was
said, the rule and the body that proved it, or the denial -- so
`tagger_ask/3` takes a typed question to an answer with its why. And the
judge that refuses a tagging the words contradict reads `known_*.txt`,
every counted word of WordNet, since the generator's nouns are things to
own and `Death put a period' had walked past a judge that never heard of
death: the same model went from 28 of 300 real sentences read to 11. The
words were the other half:
a lexicon written by hand is a lexicon nobody grows, so it is files now,
`lexicon/`, census names and WordNet, and over those the corpus is the
lever twice over -- 8192 pairs read 0.96 of the sentences training never
saw whatever the step count, which is memorising; 16384 read 0.987 and
32768 read 0.993. What it still cannot know is a shape the grammar does
not read -- a definite subject, a passive -- and that is refused, never
quietly rewritten; the lesson's last section shows both.
