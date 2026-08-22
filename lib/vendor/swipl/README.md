# Borrowed from SWI-Prolog

The files in this directory are **not cocolog's**. They are copied unmodified
from SWI-Prolog and carry their own copyright and licence in their headers.
Leave those headers alone: BSD-2-Clause permits the copy on the condition that
the notice, the conditions and the disclaimer travel with it.

| file | upstream path | licence |
|---|---|---|
| `dcg_basics.pl` | `library/dcg/basics.pl` | BSD-2-Clause |
| `dcg_high_order.pl` | `library/dcg/high_order.pl` | BSD-2-Clause |

Copyright (c) Jan Wielemaker, University of Amsterdam, VU University Amsterdam,
SWI-Prolog Solutions b.v. All rights reserved. cocolog is BSD-2-Clause too, so
there are no two licences to reconcile — see `../../LICENSE`.

## Which copy

| | |
|---|---|
| version | SWI-Prolog 9.0.4 (`swi-prolog-nox` 9.0.4+dfsg-3.1ubuntu4) |
| taken from | `/usr/lib/swi-prolog/library/dcg/` |
| taken on | 2026-08-22 |
| `dcg_basics.pl` | md5 `0e74fe430f1ef556ab2a1a88e3e21455`, 471 lines |
| `dcg_high_order.pl` | md5 `aca1f300040424e2d6b7fe76a5732761`, 227 lines |

The checksums are here so a later reader can tell a clean copy from an edited
one, and diff either against a newer upstream without first having to work out
which release it came from.

## Local changes

**None.** The point of a byte-identical copy is that `diff` against upstream is
meaningful. Everything these files needed was built in cocolog instead:

| what they use | where it came from |
|---|---|
| `-->`, `phrase/2,3`, `call_dcg/3` | `../../dcg.cicili` — written, not copied; see the head of that file for why |
| `*->` | the soft cut, `lib/solve.cicili` |
| `code_type/2` | `lib/builtins.cicili` |
| `must_be/2` | `lib/builtins.cicili`, standing in for `library(error)` |
| `ord_intersection/3`, `ord_subtract/3` | `lib/lists.cicili`, standing in for `library(ordsets)` |
| `:- module`, `:- use_module`, `:- meta_predicate`, `:- multifile` | accepted and ignored by `coco_directive` in `lib/kb.cicili` |

**`:- module/2`'s export list is ignored**, because cocolog has one namespace.
Every predicate in these files is callable, including the ones upstream keeps
private. That is a real difference in behaviour and not a shim.

## What is NOT copied

`boot/dcg.pl` — SWI's own translator. About half of it is source-position terms
and `q(M,C,Pos)` module qualification, machinery for a module system and an
error reporter cocolog does not have. What survives removing both is short
enough to write, and writing it keeps the core free of third-party code.

## Consulting them

They are ordinary Prolog files, not modules in cocolog's sense — nothing
registers them and no C is attached:

```sh
cocolog --local run lib/vendor/swipl/dcg_basics.pl my_program.pl main
```

With more than one argument `run` takes the LAST as the goal, so `main` has to
be written out once a library is listed alongside the program.

`test/files/run.sh` consults them the same way for the conformance cases, which
is what proves the copy runs here as it does there.
