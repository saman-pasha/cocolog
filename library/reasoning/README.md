# library/reasoning

Everything of the reasoning task lives here, and it is loaded with the
directory in the name:

    :- use_module(library(reasoning/reason)).
    :- use_module(library(reasoning/normalise)).

| file | what |
|---|---|
| `reason.pl` | a paragraph of controlled English in, predicates out: facts, `neg/1` facts, rules; `truth/2`, four-valued; `reason_refused/2`, which sentence would not parse |
| `normalise.pl` | the training data for the network that will feed it: the grammar's shapes as a generator with gold tags, noise transforms that carry the tags, and the assembler the round trip holds them to |

The suite case for each is `test/reason.pl` and `test/normalise.pl`, and
the lesson `tutorials/library/43-reason.pl` and `44-normalise.pl`. They
stay where the runners look -- `test/run.pl` takes `test/*.pl` and
`test/tutorials.pl` takes `tutorials/*/*.pl` -- because a case under
`library/` is a case nobody runs.

The network itself is not here yet; `normalise.pl`'s header says what it
will be and what this file decides about it.
