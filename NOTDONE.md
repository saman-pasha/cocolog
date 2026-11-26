# What is not done

As of cocolog 3.78.21 (`1f921d5`), 2026-11-26.

This file lists what STATUS.md's entries left NOT DONE and is still open.
Each item was checked against the entries after it and, where there was
doubt, against the binary and swipl 9.0.4. Each item names the entry it
comes from: "3.0.3" is the STATUS.md entry whose heading ends `(3.0.3)`, and
that entry has the detail.

## Gaps against swipl

- **Postfix operators** (3.2.0). `op(200, xf, ff)` raises
  `domain_error(operator_specifier, xf)`. swipl accepts `xf` and `yf`, and
  reads `a ff` as `ff(a)`.
- **Dicts** (3.2.0). `_{a:1}` is a syntax error (`operator_expected`).
  swipl reads it as a dict, and has the `.` operator that dicts use.
- **`thread_initialization/1`** (3.2.0; COMPAT.md has the row). It runs its
  goal now and never again. swipl runs it again at the start of every
  thread created after it.
- **`thread_create/3`**, found while checking the item above.
  library(thread) has only `thread_create/2`, so a call of
  `thread_create/3` raises an unknown-procedure error.
- **Including a library cocolog compiles in** (3.5.0, 3.13.1; COMPAT.md has
  the row). `:- include(library(lists))` raises
  `existence_error(source_sink, library(lists))`. swipl reads the
  library's source, whose `module/2` makes the rest of the including file
  that module's. library(flow/chart) and cocolint read nothing for it
  either.
- **The suggestions after an unknown procedure** (3.3.0):
  - The REPL never corrects a goal. swipl's toplevel asks
    `Correct to: "foo(x)"?` when exactly one name is near.
  - A library predicate is suggested only where swipl's system module has
    it. swipl also suggests one after its autoload has loaded it.
  - Predicates of a loadable module (a `.so`) are never suggested, nor
    predicates a remote store holds that this process has not read.
  - A name past ASCII is compared byte by byte, where swipl compares
    characters. This one has not been re-checked since 3.3.0.

## cocolog's own limits

- **A module's file read again** (2.14.0):
  - Rows an earlier process's consult wrote, for a predicate the new text no
    longer defines, stay if this process has not read that predicate. The
    drop walks only the predicates this process holds.
  - A library(thread) thread's store keeps the module as that thread loaded
    it. A re-read changes only the store that does the reading.
  - The module registry keeps every text it ever held, one more for each
    re-read. This is a stated leak.
- **The embedded store** (3.0.3):
  - A store whose hexmap (its page map) was emptied opens as an empty store
    and says nothing. The engine frees any page its hexmap does not cover,
    and that state cannot be told apart from a first commit that was killed
    before its hexmap was written.
  - `sequence has no memory to read` is not counted as damage.
  - A process that holds a store, runs a second cocolog over the same store
    and waits for it, waits forever: the child waits for the parent's lock.
    Nothing in the tree does this.
  - Each library(flow/debug) window over `embed(Dir)` gives its child a copy
    of the store, so with `windows=N` every window running at once holds a
    copy of the store's size on disk.
- **Deep expressions** (3.61.0). Past an expression's 101st compound, the
  evaluator walks the whole expression to ask whether it is cyclic. Only a
  raise, or a run that never ends, distinguishes a cyclic expression
  without that walk. Asking only at that point would need every raise in
  the evaluator behind one test, and a count in the walk that evaluates
  deep expressions.
- **ZiguratIP under refused memory** (3.62.7):
  - A fresh page whose entry is refused leaks until the store's next open.
  - A B-tree map that a refusal stops part way is rolled back as any staged
    row is. The sweep tests this for the indexes cocolog's writes reach;
    nothing tests it for a split of a root.
  - The sweep's fixtures never reach a log merge. The frees after a commit's
    intention are checked by reading the code, and by `rr_tail` for the free
    list alone.
  - A growth given less than it asked for stops the engine at its next
    step. So an assert whose row was already written can raise afterwards.
- **`vacuum_kb/0,1`** (3.63.1). It still flushes the host's dirty list
  before its pass (`coco_zg_vacuum` in lib/zigurat-kb.cicili). A green task
  that then changes a predicate the turn changed, by anything but an
  append (a retract, an `asserta`), can wait on it, as every task did
  through 3.63.0.
- **A write to a pipe whose reader falls behind** (3.64.4). library(stream)'s
  writes and the console's own output wait once the pipe's buffer fills,
  and are not declared foreign calls. In a green world the waiting task
  holds up every write meanwhile.
- **valgrind with a small `--main-stacksize`** (3.78.10). Below
  min(RLIMIT_STACK, 16 MB), the first thread's stack reserve still runs past
  the stack valgrind made, because the program cannot ask valgrind its size.
  Such a run needs a `ulimit -s` no larger than the stack it gives valgrind.
- **Sweeping dead clauses in a green world** (3.78.21):
  - A world holds one question at a time. A sweep attempt for another
    predicate is turned down while one is owed, even though nothing may
    hold a frame on it.
  - A task running a long nested search keeps a question owed for the whole
    search, and every sweep attempt in the world is turned down meanwhile.
    The write barrier used before would have waited just as long.
  - A loop over five or more predicates with dead clauses writes a charge
    slot back at each change of predicate.
  - Restoring `tback` and the probe's doubling of it are stores with no
    lock. A lost store only delays the next attempt by one doubling.

## Kept on purpose

These are choices, not oversights. Each is stated in the STATUS.md entry
named, and most have a row in COMPAT.md.

- Modules are one namespace (3.4.0, 3.6.0). `use_module/1` of a file with no
  `module/2` loads it, where swipl refuses it. Two modules may define one
  name. A module's import list is not read.
- A store made after a module's read failed passes that module by. swipl's
  thread sees what the module defined before the error (3.6.0).
- `[123]` names the file `{`, because a list of codes is one name. swipl's
  is a list of one file, `'123'` (3.4.0).
- A directory reached through a link is named by the path given. swipl
  names it by the first path it met it through (3.4.0).
- An include of a file already open on the way down to it, or 64 files
  deep, is refused. swipl reads it again forever (3.5.0).
- A variable in a report is written `_G` and a heap position. swipl writes
  `_` and a number (3.4.0).

## Not re-checked

- When a directory is named as the `-s` script, the message keeps the
  comment `(is a directory)`. swipl's include prints that comment and its
  script load does not (3.5.0).
- The guard in `lb_mod_unloaded` for a module compiled in or loaded from a
  `.so` has no case in the tree that reaches it, because every `.so` here
  has clauses in its Prolog half (3.6.0).

## Closed since

These were NOT DONE in an earlier entry and have been done since. They are
listed so that nobody looks for them again.

- `print_message/2` and `sumlist/2` (2.16.0).
- `term_to_atom/2` of a text with more after its term (`'1.0 x'`) raises
  swipl's `syntax_error(operator_expected)` with swipl's
  `string("1.0 x . ", 3)`. Checked on 3.78.21.
- swipl's declaration operators, `table`, `thread_local`, `volatile`,
  `module_transparent` and `public` at 1150 fx (3.2.0).
- The `However, there are definitions for:` lines after an unknown
  procedure (3.3.0).
- A load's relative path looked for beside the loading file first; swipl's
  `Dir/File` specs, its existence errors, and absolute paths in messages
  (3.4.0).
- `include/1` (3.5.0), and an include of a list of codes (3.13.1).
- An error that ends a nested load is reported at its directive (3.6.0).
- A nested file's `initialization(G, main)` runs after the whole load
  (3.7.0).
- `sleep/1` (3.8.0) and `writeln/2` (3.9.0).
- A syntax error's id, term, place and message (3.10.0, 3.11.0).
- Grammar rules and `dcg_translate_rule/2` (3.13.0), and `expand_term/2`
  with the expansion hooks (3.14.0).
- A quoted operator, the spaces around it, and `term_to_atom/2`'s control
  characters (3.15.1).
- library(stream)'s errors (3.16.0).
- A load's singleton and not-together warnings (3.17.0), including clauses
  split by an include (checked on 3.78.21), and the compiler's warnings
  (3.19.1, 3.19.5).
- The layout of `listing/1` and `portray_clause/1` (3.18.0).
- A retract whose write-through the store refuses now raises (3.64.7).
- The note in 3.62.5 about `$` guards was a misreading, corrected in 3.62.7:
  `a :- $, p(_)` over two clauses of p/1 raises
  `determinism_error(p/1, det, nondet, guard_in_caller)` in both systems.

## Stale lines in CLAUDE.md

- The bullet "A float is written as SWI 9 writes it" still says
  `term_to_atom/2` reads the first term of its text and ignores the rest.
  It raises swipl's syntax error now (above).
- The bullet on dispatch ("Dispatch is construct, C builtin, module, store")
  still says cocolog loads the clauses of one name that are not together in
  a file without a word. The load has warned as swipl's does since 3.17.0.
