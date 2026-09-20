# library/reasoning/corpus

Controlled English that TEACHES, kept as data: one file a lesson, one
sentence a line, in the English `library(reasoning/reason)` reads -- a word
between quotation marks is MENTIONED and stands for itself, so `The noun
"casa" means "house".` is `noun(casa), mean(casa, house)`. A line beginning
`#` is a comment.

| file | what |
|---|---|
| `spanish.txt` | the Spanish lesson of `test/translate.pl` and `tutorials/library/46-translate.pl`: 176 lines, the vocabulary as facts about words, the grammar as rules over the classes |
| `italian.txt` | the Italian lesson learned beside it under its own name: 18 lines |

Three things read this directory, and none of them holds a word of it:

* `library(reasoning/normalise)` generates its LESSON shapes from the words
  in here -- the mentioned words, the classes said of them (`noun`,
  `article`, `pronoun`), the adjectives (`feminine`), the forms (`the plural
  of`, `the first person of`), the relations (`means`, `precedes`, `takes ...
  in the plural`) -- through `normalise_lexicon/2` with `mention`, `wclass`,
  `wadj`, `form`, `wverb`, `wobj` and `wplace`, and lists the lines
  themselves with `normalise_lessons/1`. A lesson that uses a shape or a
  word these files lack is one the tagger was never shown, and the fix is a
  line here, not a word in the code.
* `library(reasoning/tagger)`'s judge lets a sentence about a mentioned word
  be related only by a verb some lesson here uses, and
  `tagger_lessons/4` measures the shipped tagger on these lines with their
  quotation marks taken off -- `The noun casa means house.` -- read back to
  the same terms.
* `tools/tagger/train.sh` trains on the generator, so every word here is
  in the shipped model's world.

`$COCOLOG_CORPUS` names another directory; otherwise it is
`reasoning/corpus` under the first library directory that has one, as the
lexicon beside it is found. Nothing trains on data the tree does not hold:
a sentence worth teaching the tagger goes in a file here, and the file is
committed.
