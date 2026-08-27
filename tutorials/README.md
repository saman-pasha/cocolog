# The tutorials

Three categories, in the order you would read them.

| | | run one |
|---|---|---|
| [`basics/`](basics/) | the language: eleven lessons, no library needed | `./cocolog run tutorials/basics/01-facts-and-rules.pl main` |
| [`library/`](library/) | twenty-three lessons, one per library that ships | `COCOLOG_LIBRARY=$PWD/library ./cocolog run tutorials/library/01-lists.pl main` |
| [`torch/`](torch/) | twenty-four neural networks, three processes each | `./cocolog --embed /tmp/t run tutorials/torch/07-xor.pl train` |

## EVERY TUTORIAL IS A TEST, and that is the design

A file that prints whatever it computed is a file that goes quietly
wrong the day the language changes underneath it. So `basics/` and
`library/` make their claims through one helper:

```prolog
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
```

Every sentence a lesson asserts about cocolog is a goal that has to
hold. Get one wrong and `main` FAILS, naming both answers. `torch/`
does the same thing one level up: `test` exits nonzero when the network
it loaded misses its threshold.

**It has already paid.** Writing `basics/` found that `once/1` and
`ignore/1` did not exist, and that `retractall/1` was one clause short
of correct — a failure-driven loop that cannot work here, because every
builtin in cocolog is deterministic. Writing `library/` found that
`httpd_content_type/2` is keyed on the bare extension and `httpd_type/2`
is the one that takes a file name, and that `curl_get/2` was never the
API. Three fixes and a dozen corrections, from documentation that runs.

`sh test/tutorials.sh` runs all of it.

## THE CONVENTION, for whatever is added next

**A new library gets a tutorial in the same commit.** Not afterwards:
`library/` is numbered one per library and the gap is visible, which is
the point. A library with no `library/NN-name.pl` beside it is a library
nobody has demonstrated end to end, and the twenty-three that are there
each found something while being written.

The shape to copy is any file in `library/`: a header block saying what
tier it is in, what to import and what the surface looks like; a `main`
that walks the surface with `must/3`; and the two helpers repeated at
the bottom. **Repeated on purpose** — a tutorial you can copy anywhere
and run is worth six duplicated lines, and one that needs a support file
beside it stops working the moment it is moved.
