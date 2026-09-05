# Borrowed from SWI-Prolog

The files in this directory are **not cocolog's**. They are copied unmodified
from SWI-Prolog and carry their own copyright and licence in their headers.
Leave those headers alone: BSD-2-Clause permits the copy on the condition that
the notice, the conditions and the disclaimer travel with it.

| file | upstream path | licence |
|---|---|---|
| `dcg_basics.pl` | `library/dcg/basics.pl` | BSD-2-Clause |
| `dcg_high_order.pl` | `library/dcg/high_order.pl` | BSD-2-Clause |
| `pairs.pl` | `library/pairs.pl` | BSD-2-Clause |
| `assoc.pl` | `library/assoc.pl` | BSD-2-Clause |
| `ordsets.pl` | `library/ordsets.pl` | BSD-2-Clause |
| `yall.pl` | `library/yall.pl` | BSD-2-Clause |
| `aggregate.pl` | `library/aggregate.pl` | BSD-2-Clause |
| `ugraphs.pl` | `library/ugraphs.pl` | BSD-2-Clause |

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
| `pairs.pl` | md5 `62586454a8f61ed0deea4677fcf23f2b`, 187 lines |
| `assoc.pl` | md5 `e519afa46edc8d012064d87090fa7877`, 522 lines |
| `ordsets.pl` | md5 `e39b204972b0f467ccd4587dbe91e805`, 518 lines |
| `yall.pl` | md5 `91983f247a4684d0dc849d4e8409e802`, 574 lines |
| `aggregate.pl` | md5 `a4628e5414a10e58b32d365a9909fa49`, 721 lines |
| `ugraphs.pl` | md5 `d98ed91adeaf7c3426ea4c5b949c8df7`, 627 lines |

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
| `ord_intersection/3`, `ord_subtract/3` | `lib/lists.cicili`, standing in for `library(ordsets)` when it is not consulted |
| `type_error/2`, `domain_error/2`, `compound_name_arity/3` | `lib/builtins.cicili` -- ordsets.pl and assoc.pl call them by name |
| `Head => Body` | translated on assert to `Head :- !, Body` by `coco_assert` in `lib/kb.cicili`; see the comment there for what that approximation does and does not keep |
| `:- if` / `:- elif` / `:- else` / `:- endif` | conditional reading in `coco_consult`, with conditions decidable below the engine: `true`, `fail`, `\\+`, and `current_predicate(Name/Arity)` against the store -- which answers assoc.pl's probe for SWI's `$btree_find_node` VM intrinsic with the truthful no |
| `div` | the operator in `lib/syntax.cicili`, floored division in `lib/solve.cicili` |
| `copy_term_nat/2`, `instantiation_error/1`, `strip_module/3`, `compound_name_arguments/3`, `cyclic_term/1`, `acyclic_term/1` | `lib/builtins.cicili` -- yall.pl's runtime path. `copy_term_nat` IS `copy_term` here (no attributed variables), and `cyclic_term` answers no, consistently with an engine that assumes acyclic terms throughout |
| `'>>'(?, 0)` after a prefix operator | the reader: a quoted name, or any name with `(` right against it, begins an operand -- `coco_starts_term` in `lib/syntax.cicili` said no to infix-only names and mis-read yall's `meta_predicate` block as `>>`/2 |
| `:- dynamic system:goal_expansion/2` | the qualifier peels off in `coco_dynamic_spec`, the same rule a qualified clause head follows |
| `max(Expr, Witness)`, `min(Expr, Witness)` | added to the NATIVE `aggregate_all/3` in `lib/builtins.cicili`, which shadows the vendored clauses (builtins dispatch ahead of the store) -- the incremental `nb_setarg' paths in aggregate.pl are therefore never reached, which is as well: cocolog has no non-backtrackable assignment |
| `error:has_type(assoc, _)` (a module-qualified clause head) | the qualifier is stripped on assert -- one namespace |
| `:- module`, `:- use_module`, `:- autoload`, `:- meta_predicate`, `:- multifile` | accepted and ignored by `coco_directive` in `lib/kb.cicili` |
| `:- set_prolog_flag(generate_debug_info, false)` | accepted and ignored: cocolog never generates what it asks to switch off |

**Known divergences, recorded rather than papered over.**
`aggregate_all(count(Expr), Goal, R)`: SWI 9.0.4 reads the compound
template through its nested-template rules and answers `count(0)`;
cocolog's native builtin reads it as "count the solutions" -- which is
what SWI's own documentation says -- and answers their number. And
`foreach/2` (exported by aggregate.pl) reaches SWI's
`'$unbind_template'` VM intrinsic, which does not exist here, so calling
it raises existence_error. Nothing in cocolog or its tests uses either
shape; test/files/aggregate.pl covers everything both systems agree on.

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
cocolog --local run lib/swipl/dcg_basics.pl my_program.pl main
```

With more than one argument `run` takes the LAST as the goal, so `main` has to
be written out once a library is listed alongside the program.

`test/files.pl` consults them the same way for the conformance cases -- the
programs under `test/files/` are run by BOTH `swipl` and cocolog and their
output compared line for line, which is what proves the copy runs here as it
does there.
