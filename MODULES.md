# Modules: a bridge between C and Coco

A module is a piece of cocolog written by somebody else. It carries two halves
and either may be empty:

* **the C half** — predicates written in Cicili, for the things Prolog cannot
  reach on its own: a syscall, a clock, a socket.
* **the Coco half** — ordinary clauses, consulted into the session when the
  module loads. Everything that is clearer said in Prolog belongs here, and
  most of a library usually does.

A program cannot tell which half a predicate came from, and that is the point.

`lib/files.cicili` is the worked example: SWI-Prolog's file-system predicates,
seventeen in C and seven in Prolog on top of them.

## Writing one

Two tables and two macro calls. Here is a whole module:

```lisp
(DEFPARAMETER *clock-predicates*
  '(("now"     1 cl_now)
    ("sleep"   1 cl_sleep)))

(DEFPARAMETER *clock-prolog*
  (FORMAT NIL "~{~A ~}"
          (LIST "later(Seconds, T) :- now(N), T is N + Seconds.")))

(generic impl-clock
  ()

  (func cl_now ((co_engine * e) (size_t g)) (out int)
        (co-mod-args e g ((t 0))
          (return (co_m_unify_int e t (cast i64 (time nil))))))

  (func cl_sleep ((co_engine * e) (size_t g)) (out int)
        (co-mod-args e g ((n 0))
          (let ((i64 v . 0))
            (if (not (co_m_int e n (aof v)))
                (return (co_m_type_error e "an integer" n)))
            (sleep (cast unsigned v))
            (return 1))))

  (static) (co-emit-module-dispatch cl_dispatch *clock-predicates*)
  (co-defmodule cl_module "clock" cl_dispatch *clock-prolog*)

  ) ; impl-clock
```

and in the target, after the imports and generic instantiations:

```lisp
(co_module_init)
(cl_module)
```

`co-emit-module-dispatch` reads the table and emits the dispatcher **grouped by
arity**, so a goal of arity 3 is never compared against a predicate of arity 1.
It is `*builtins*` in `lib/solve.cicili` one module along: add a line to the
table and write the function, and the dispatcher cannot fall out of step with
it because it is generated from it.

## Where a module's predicates sit

A goal is tried as

1. a control construct — `,` `;` `->` `\+` `call` `!`
2. a **core builtin** — `*builtins*` in `lib/solve.cicili`
3. a **module predicate**
4. the knowledge base

So a module can add to the language but cannot quietly redefine `=` or `is`
underneath a program written before it was installed; and a module predicate is
not shadowed by a clause somebody asserted. When two modules claim one name,
the first registered wins — which makes the order in the target the order of
precedence.

## The rules a module predicate must obey

These are not style.

**It is deterministic.** It answers 1 once, 0, or −1 with the engine's `err`
filled in, and it never makes a choice point — it has no access to the choice
stack, deliberately, so that no module can break the invariant cocolog's
suspension depends on. A predicate that wants to answer several times returns a
**list** and lets a clause in the Coco half take it apart. That is also what
makes it work after a machine has been frozen and thawed in another process.

**It leaves nothing behind when it fails.** Bindings made on the way to
discovering the answer is 0 have to be undone: `co_m_mark` first, `co_m_undo`
back to it. The engine winds the trail back at a choice point, and a builtin
that fails is not one.

**It does not keep a term index across a call.** The heap moves. An index is
good for the length of one call. That is also why a module has no per-session
state: state a frozen machine cannot carry is state that comes back wrong
somewhere else.

## The API a module is written against

| | |
|---|---|
| `co_m_arg(e, g, i)` | argument *i*, dereferenced |
| `co_m_machine(e)` | the machine, for the term DSL |
| `co_m_mark(e)` / `co_m_undo(e, mark)` | the trail, for a predicate that may fail |
| `co_m_is_var` / `co_m_is_atom` | what a term is |
| `co_m_atom(e, t)` | an atom's name, or null |
| `co_m_int` / `co_m_float` | a number, or 0 |
| `co_m_text(e, t, buf, cap)` | an atom, an integer **or a code list** as a string |
| `co_m_unify(e, t, u)` | plain unification |
| `co_m_unify_atom` / `_int` / `_float` | unify with a fresh constant |
| `co_m_nil` / `co_m_cons` / `co_m_atom_list` | building a list |
| `co_m_error(e, what, detail)` | −1, with a message |
| `co_m_type_error(e, want, got)` | −1, naming the term that was wrong |

`co_m_text` accepting a code list is not politeness: cocolog reads `"abc"` as a
code list, so without it every double-quoted file name in a program would be a
type error.

`co-mod-args` binds arguments by position and is sugar for the `let` of
`co_m_arg` calls that every predicate starts with.

## What a module cannot do

* **Define an operator.** The reader's table is fixed at build time. This is a
  real gap: a module whose predicates want infix syntax cannot have it.
* **Leave a choice point**, or see the choice stack. The price of being
  suspendable.
* **Register another module.** A build decides what it contains.

## Three things about Cicili that this hit

Written down because each cost an hour and none is guessable.

**A string literal cannot contain a newline** — by either route. Written as a
real newline it lands unescaped inside a C string literal, which does not
compile; written as `\n` it is emitted as an escaped backslash and arrives at
the reader as two characters. So a Coco half is joined with **spaces**, which
Prolog does not mind at all — a clause ends at its `.`, not at a line ending —
and its commentary lives outside the string, where a `%` cannot swallow the
rest of the program for want of a newline after it.

**Lambda-list markers must be uppercase.** `&REST`, not `&rest`. Cicili's
reader preserves case, so a lowercase one is the symbol `|&rest|` rather than
`COMMON-LISP:&REST`, and the macro is then called with the wrong arity in a way
whose error message names neither.

**A macro emits one form.** Emitting several from one macro leaves the symbols
unregistered and the next reference to them is "unknown symbol". That is why a
module is two macro calls and not one, and why the registry is written out
rather than generated.

Two smaller ones: `new` is a Cicili macro, so a local of that name is read as a
call to it; and a dotted initialiser (`(var size_t n . 0)`) cannot be written
inside a generic in a package where `nil` is `cocolog::nil` — a static is zero
anyway.

## Four libraries, across the whole range

The modules that ship are deliberately spread, because between them they show
what each half is for.

| | Files | Lists | Apply | Builtins |
|---|---|---|---|---|
| C half | 17 predicates | 7 | **none** | 31 |
| Coco half | 5 | 30-odd | 17 | 12 |
| why | a file system is a syscall away | a list predicate is two clauses — **and most must be nondeterministic** | a goal applied to a list is `call/N` and nothing else | the core the engine could not reach on its own |

`apply` has **no C half at all** — `co-defmodule` takes `nil` for the
dispatcher — and it works, which is the cleanest demonstration the seam gets.

**That second reason is the important one.** `member/2`, `select/3`, `append/3`
and `permutation/2` each answer many times, and a module's C half cannot: it
has no access to the choice stack, deliberately. Written in C they would work
until the first `cocolog step`. Written as clauses, the *engine* provides the
choice points, and a machine frozen mid-backtrack can be thawed in another
process and go on.

So the rule is not "C is for speed and Prolog is for convenience". It is:

* **nondeterministic → the Coco half**, always;
* **needs the outside world, or the whole list at once → the C half**;
* **both → a `$`-prefixed primitive in C wrapped in a clause**, which is how
  `length/2` is a single C walk for a proper list and still generative for
  `length(L, 3)`, and how `file_name_extension/3` splits one way and joins the
  other.

## The Files library

`lib/files.cicili`. SWI-Prolog's manual section *Files*, written to **match**
SWI rather than to resemble it.

In C: `exists_file/1` `exists_directory/1` `access_file/2` `size_file/2`
`time_file/2` `delete_file/1` `rename_file/2` `make_directory/1`
`delete_directory/1` `directory_files/2` `expand_file_name/2`
`absolute_file_name/2` `same_file/2` `read_link/3` `tmp_file/2`
`working_directory/2` `is_absolute_file_name/1`.

In Prolog, on three C primitives: `file_base_name/2` `file_directory_name/2`
`file_name_extension/3` `prolog_to_os_filename/2` `make_directory_path/1`.

### It is checked against a real SWI

`test/files/*.pl` are Prolog programs run **twice** — once by `swipl` and once
by `cocolog --local run` — in a freshly made empty directory that is the same
absolute path both times, and their output compared byte for byte. `sh
test/files/run.sh`. It skips when there is no `swipl`, because "no SWI here"
and "the library is wrong" are different findings.

That is the only way to check a claim of compatibility that cannot be fooled by
the author's idea of what SWI does, and it earned itself immediately:
`file_name_extension(B, E, '.bashrc')` gives `B = ''` and `E = bashrc` in SWI —
a leading dot **is** an extension separator — and the first version of this
library had the rule everybody would guess instead.

The edges the tests pin down, all read off a running SWI 9:

```
file_base_name('/a/b/', X)            X = b        trailing slash first
file_directory_name('/a/b/', X)       X = '/a'
file_directory_name(abc, X)           X = '.'
file_name_extension(B, E, 'a.b.c')    B = 'a.b', E = c
file_name_extension(B, E, '/a/b.d/c') E = ''       a dot in a DIRECTORY is not one
file_name_extension(x, '.md', F)      F = 'x.md'   a dotted Ext is taken as given
working_directory(W, W)               W ends in '/'
directory_files/2                     includes '.' and '..'
access_file(missing, none)            true
expand_file_name(no_match, L)         L = []       not a failure
absolute_file_name/2                  normalises '.' and '..'; does not require
                                      existence; does not resolve symlinks
```

### Where it parts from SWI

**SWI throws where this fails.** `delete_file/1` on a file that is not there is
an `existence_error` in SWI and simply false here, because cocolog has no error
terms and no `catch/3` — see `STATUS.md`. Anything that fails for a reason the
caller could not have tested for first reports through the engine's `err`,
which stops the query rather than being catchable. The shared tests therefore
stay on the paths where the two agree; this is the list of what they cannot
cover, rather than a set of quietly skipped cases.

**Not implemented:** `tmp_file_stream/3` and everything else that hands back a
stream, because cocolog has no streams — there is no `open/3`, so there is
nothing for such a predicate to answer with. `absolute_file_name/3` takes an
option list whose useful members each imply machinery this library does not
have; the /2 form is complete.

**The writer used to disagree with SWI about spacing** — `write(a-b)` gave
`a - b` — which meant the shared tests could not print a compound term at all.
It does not any more: `lib/syntax.cicili` now puts a space exactly where the
two tokens would otherwise lex as one, which is SWI's rule and the reader's own
tokeniser read backwards. `test/syntax.cicili` pins it, and `clumped/2` is
printed whole in `lists_shape.pl` rather than taken apart.

## The Apply library

`lib/apply.cicili`. All seventeen exports of SWI's `library(apply)`:
`maplist/2..5`, `foldl/4..7`, `scanl/4..7`, `include/3`, `exclude/3`,
`partition/4`, `partition/5`, `convlist/3`.

Not one line of C. Every one of them is a goal applied to the elements of a
list — `call(Goal, X)` — so every one is two or three clauses. **They are as
nondeterministic as what they are given:** `maplist(member, Xs, Yss)`
backtracks because `member/2` does, and that falls out of their being clauses
rather than being arranged for.

## The Builtins library

`lib/builtins.cicili`. SWI has **655** built-in predicates. Most cannot exist
here and it is worth saying which rather than leaving a reader to find out:
everything stream-shaped (there is no `open/3`, so nothing to answer with),
everything module-shaped, threads, tabling, the foreign interface, SWI's own
`prolog_*` introspection, and the string family — cocolog reads `"abc"` as a
code list, which is the ISO default, so `string_concat/3` has no type to work
on.

**What is left is the ISO core, and that is what this module is.** The set was
computed rather than remembered: the ISO built-in predicates plus the SWI
extras everyone treats as core, minus the forty-eight cocolog already had.
Thirty-eight remained, and they are all here:

`findall/3` `findall/4` `forall/2` `aggregate_all/3` · `between/3` `succ/2`
`plus/3` · `ground/1` `term_variables/2` `unify_with_occurs_check/2` ·
`atom_chars/2` `char_code/2` `number_chars/2` `atom_number/2` `upcase_atom/2`
`downcase_atom/2` `term_to_atom/2` `sub_atom/5` `atomic_list_concat/2`
`atomic_list_concat/3` · `writeq/1` `print/1` `write_term/2` `tab/1` ·
`clause/2` `current_predicate/1` `retractall/1` `abolish/1` ·
`nb_setval/2` `nb_getval/2` `b_setval/2` `b_getval/2` · `halt/1`.

(`length/2`, `msort/2`, `sort/2` and `sort/4` are in the Lists module, which
needed them first.)

### findall had to be an engine service

It runs a goal to exhaustion, and a module cannot see the engine. So
`lib/solve.cicili` grew `co_engine_findall`, which starts a **nested engine**
on the same machine and store, and the module calls it. `forall/2` and
`aggregate_all/3` are built on the same service.

**The solutions travel through the store, not the heap.** Backtracking
truncates the heap to the choice point's mark, so a copy made on the heap
during the search is gone by the time the search ends — the collection would
come back empty, or pointing at cells that had been reused. The store never
shrinks, which is the property `assert` already relies on.

The inner search spends the outer one's remaining step budget, so a `cocolog
step` with a limit cannot be overrun by a `findall` inside it.

### What is still missing, and why

Each for a reason rather than for want of time:

* **`catch/3` and `throw/1`.** A catch is a new kind of choice-point frame, and
  every kind of frame has to be written into a frozen machine and read back
  (`lib/state.cicili`). It is the suspension format that makes this a change
  rather than an addition. This is also the reason SWI throws where cocolog
  fails, which is the one divergence the shared tests cannot cross.
* **`bagof/3` and `setof/3`.** Not `findall` plus a sort. They **backtrack over
  the bindings of the free variables** of the goal, answering one group per
  witness, and that needs the engine to enumerate the groups. Shipping
  findall-and-sort under those names would be a predicate that agrees with SWI
  until the first free variable and then quietly does not.
* **`op/3` and `current_op/3`.** The reader's operator table is emitted from
  `*operators*` at build time, which is what keeps the reader and the writer
  from disagreeing. A run-time table is a real change to `lib/syntax.cicili`
  and to what a frozen machine has to carry.

## The Lists library

`lib/lists.cicili`. All **thirty-six** exported predicates of SWI's
`library(lists)`, read off a running SWI rather than off a memory of one:

`append/2` `append/3` `clumped/2` `delete/3` `flatten/2` `intersection/3`
`is_set/1` `last/2` `list_to_set/2` `max_list/2` `max_member/2` `max_member/3`
`member/2` `memberchk/2` `min_list/2` `min_member/2` `min_member/3` `nextto/3`
`nth0/3` `nth0/4` `nth1/3` `nth1/4` `numlist/3` `permutation/2` `prefix/2`
`proper_length/2` `reverse/2` `same_length/2` `select/3` `select/4`
`selectchk/3` `selectchk/4` `subset/2` `subtract/3` `sum_list/2` `union/3`.

Plus four SWI **builtins** that are not part of `library(lists)` and that
cocolog did not have — `length/2`, `msort/2`, `sort/2`, `sort/4`. Half the
library cannot be written without them and the shared tests could not compare
without them either, so they are here and marked as what they are.

In C, and only these: `msort/2` `sort/2` `sort/4` `memberchk/2` and the
`$`-prefixed `$len` `$rev` `$nth0`. Sorting goes through `co_compare`, the same
standard order `compare/3` and the clause store already use, so a sorted list
and a `@<` test in a program cannot disagree. `sort/4` is an insertion sort
rather than `qsort`, because it has to be **stable**: it compares the key and
not the rest of the term, so two entries with equal keys are distinguishable
and the order they arrived in is observable.

Everything else is clauses.

### It needed one thing from the engine

`max_member/3` and `min_member/3` take a comparison predicate, so they are
`call(Pred, A, B)` and nothing else — and cocolog had `call/1` only. `call/N`
is now in `lib/solve.cicili`: it rebuilds the goal as the closure's own
arguments followed by the call's, so `call(plus(1), 2, X)` is `plus(1, 2, X)`,
and it is opaque to cut exactly as `call/1` is.

### Where it parts from SWI

The same one place as Files, and no other: **SWI throws where this fails.**
`msort(notalist, _)` is a `type_error` there and false here; `length(_, -1)` is
a `domain_error` there and false here. `test/files/lists_edge.pl` says so at
the top rather than quietly omitting them.
