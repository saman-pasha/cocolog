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

## Two ways to write one

A module author has exactly two languages, and the choice is per-half,
not per-module:

**Coco** — ordinary Prolog. A library that is only clauses is a `.pl`
file, full stop: no build, no registration code, nothing to compile.
Put it on the library path and `use_module(library(Name))` loads it;
`lib/apply.cicili` is the linked-in proof that a clauses-only module is
a complete module.

**Cicili, against the module API** — for the C half: the predicates
Prolog cannot reach on its own. It is written in Cicili, always — the
macro layer is where the module machinery lives (`coco-defmodule`,
`coco-emit-module-dispatch`, `coco-mod-args` each generate what must
not drift apart), and a module written in raw C would be outside every
one of those guarantees. Raw C has no place in a module; `(code ...)`
escapes exist for the corner libc Cicili does not declare, and that is
their whole license.

And a Cicili module lives in one of two places:

* **linked into the build** — imported by `cocolog.cicili`, registered
  in `install_modules`. The five shipped libraries and torch live here.
* **compiled to a shared object** — written against `lib/sdk.cicili`
  instead of `lib/module.cicili` (same macros, same API, opaque engine
  types), emitted to C by Cicili, built with `gcc -shared -fPIC`, and
  loaded at run time by `use_module(library(Name))`. `test/hoot.cicili`
  is the complete worked example, twenty lines. This is how a project
  that USES cocolog — The Coco — ships its own C-half predicates
  without cocolog carrying them.

Both places obey every rule below; a loadable module is not a way
around the seam, it is the seam, reached later.

## Loading at run time: use_module, like SWI's

`use_module(library(Name))` — as a goal, and as a `:- use_module(...)`
directive in a consulted file — resolves Name in order:

1. **a registered module** of that name: linked into the build, or
   loaded earlier in this process — nothing to find, the answer is yes;
2. **`Name.so` on the library path** — dlopen'd, its
   `coco_library_entry` called, which registers it exactly as a
   linked-in module registers;
3. **`Name.pl` on the library path** — registered as a clauses-only
   module, so it reloads after a store reset (a thaw), never writes
   through to the knowledge base, and never loads twice.

The library path is `$COCOLOG_LIBRARY` (colon-separated directories),
then `./library`. `library(Dir/Name)` names a subdirectory, as in SWI's
`library(dcg/basics)`. A plain atom instead of `library(...)` is a file
path, tried as written and then with `.pl`. `use_module/2` accepts and
ignores the import list — cocolog has one namespace, as recorded below —
and `ensure_loaded/1` is the same act.

What loading means, honestly: a library loads **into this process**,
exactly as in SWI. Its clauses are muted — they belong to the library,
not to the knowledge base — so a second process on the same database
does not see them unless it, too, says use_module. A program that wants
clauses shared across processes consults them into the knowledge base;
the two are different acts and stay so, and `test/library.sh` proves
the difference across processes.

The two spellings differ in one place: as a **goal**, a library that
cannot be found or loaded throws a catchable error; as a **directive**,
a library that is not found is passed over in silence — a file borrowed
from SWI names libraries this build carries under other arrangements —
while one that was found and would not load says so on stderr and lets
the file go on reading.

The `.so` contract, whole: export `int coco_library_entry(void)` (the
`coco-deflibrary` macro writes it), register through
`coco_module_register` — resolved from the cocolog binary itself, which
is linked `-rdynamic` exactly for this — and return the ABI version
built against. **This is ABI version 1**; the loader refuses any other
by name.

## Errors are thrown, and they are SWI's

A module predicate that cannot do what it was asked raises the term SWI raises:

```prolog
catch(msort(notalist, _), error(type_error(T, V), _), true).
%  T = list, V = notalist  --  in both systems
```

`coco_m_type_error`, `coco_m_instantiation_error`, `coco_m_domain_error`,
`coco_m_existence_error` and `coco_m_error` all **throw**. Each answers what its
caller should return: **2** when a `catch/3` took the ball — the engine is by
then pointed at the recovery goal and 2 is how a builtin says *leave my
continuation alone* — and −1 when nothing caught it. A predicate writes
`(return (coco_m_type_error e "list" t))` and does not care which happened.

The second argument of `error/2` is left **unbound**. SWI puts a
`context(Module:Name/Arity, Message)` there and no two systems agree on its
contents; matching on `error(Formal, _)` is what portable code does and is all
that can be compared.

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

  (func cl_now ((coco_engine * e) (size_t g)) (out int)
        (coco-mod-args e g ((t 0))
          (return (coco_m_unify_int e t (cast i64 (time nil))))))

  (func cl_sleep ((coco_engine * e) (size_t g)) (out int)
        (coco-mod-args e g ((n 0))
          (let ((i64 v . 0))
            (if (not (coco_m_int e n (aof v)))
                (return (coco_m_type_error e "an integer" n)))
            (sleep (cast unsigned v))
            (return 1))))

  (static) (coco-emit-module-dispatch cl_dispatch *clock-predicates*)
  (coco-defmodule cl_module "clock" cl_dispatch *clock-prolog*)

  ) ; impl-clock
```

and in the target, after the imports and generic instantiations:

```lisp
(coco_module_init)
(cl_module)
```

`coco-emit-module-dispatch` reads the table and emits the dispatcher **grouped by
arity**, so a goal of arity 3 is never compared against a predicate of arity 1.
It is `*builtins*` in `lib/solve.cicili` one module along: add a line to the
table and write the function, and the dispatcher cannot fall out of step with
it because it is generated from it.

## AND IT GETS A TUTORIAL, in the same commit

`tutorials/library/` is numbered **one file per library**, tier 1 and
tier 2 alike, so a gap in the numbering is a library nobody has
demonstrated end to end. A new module or a new `library/*.pl` is not
finished until there is a `tutorials/library/NN-name.pl` beside it and
`sh test/tutorials.sh` is green.

It is not ceremony, and the crypto modules are the latest evidence:
writing `tutorials/library/26-x509.pl` is what established that
`x509_public_key/2` answers the CONTENTS of a SubjectPublicKeyInfo and
not the whole structure, four bytes short of what its own header
promises. Every claim in such a file is a `must/3` — `Got ==
Want`, or the file fails naming both answers — so the tutorial is a
test of the surface as documented, and writing the twenty-eight that
exist found something every time: `bigint_cmp/3` answering `<`, `=`,
`>` where the README said `-1/0/1`; `curl_get/2` never having been the
API; `httpd_content_type/2` keyed on the bare extension where
`httpd_type/2` is the one that takes a file name; `tensor_new/3` taking
a KIND (`zeros`, `randn`) and `tensor_from_list/2` being the one that
takes data. A surface nobody has walked end to end has drifted from its
documentation, always.

Copy any file in `tutorials/library/` for the shape: a header block
saying which tier, what to import and what the surface is; a `main`
that walks that surface with `must/3`; and `show/2` and `must/3`
repeated at the bottom. Repeated, not shared — a tutorial that needs a
support file beside it stops working the moment it is moved.

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

## library(zigurat): the connection, steered from Prolog

When the knowledge base rides a Zigurat connection (`--kb`/`--host`/
`--port`, or `--embed`), `use_module(library(zigurat))` hands the program
the connection the store's own hooks already write through — the same RPC
surface ZiguratIP's Connector offers its C++ clients (`call`, `compile`,
`isolate`, `auto_commit`, `commit`, `rollback`), reached through the
store's `conn` hook rather than a second socket:

| predicate | wire verb | what it does |
|---|---|---|
| `zigurat_begin/0` | — (an `echo` round-trip) | the server opens a transaction with the connection and after every commit/rollback at the next statement; this proves the connection lives so `begin, work, commit` reads as written |
| `zigurat_commit/0` | `commit` | commit NOW, before the turn's own commit |
| `zigurat_rollback/0` | `rollback` | take the uncommitted work back NOW |
| `zigurat_isolation/1` | `isolate` | `read_uncommitted`, `read_committed`, `repeatable_read`, `snapshot`, `serializable` |
| `zigurat_auto_commit/1` | `auto_commit` | `true`/`false`: commit after every procedure call, server-side |
| `zigurat_transaction_id/1` | — | the id the server answered at connect |
| `zigurat_compile/1` | `compile` | Parsi source — DDL and procedures — to the server's own compiler; refused (catchably) unless the operator set `COMPILER/REMOTE_MODE TRUE` |
| `zigurat_call/2,3` | `call` | a compiled procedure, arguments typed by shape: a bare integer travels as Long, a float as Double, an atom as String, and `int(N)`, `bool(B)`, `text(A)` pick the narrower types; `/3` unifies its Reply with a list — a RETURNS value as itself, each cursor row as a list of its fields (nulls as `null`, strings as atoms, vectors as lists) |

Under `--local` every one of them throws `error(cocolog_error(...), _)` —
a local store has no connection to steer. `--http` likewise. An embedded
store answers the transaction verbs; a `/3` Reply is the wire's alone,
because only the wire's fields carry the type descriptors a generic
reader needs. `test/zigurat-lib.sh` is the proof, commit and rollback
across processes included.

## The rules a module predicate must obey

These are not style.

**It is deterministic.** It answers 1 once, 0, or −1 with the engine's `err`
filled in, and it never makes a choice point — it has no access to the choice
stack, deliberately, so that no module can break the invariant cocolog's
suspension depends on. A predicate that wants to answer several times returns a
**list** and lets a clause in the Coco half take it apart. That is also what
makes it work after a machine has been frozen and thawed in another process.

**It leaves nothing behind when it fails.** Bindings made on the way to
discovering the answer is 0 have to be undone: `coco_m_mark` first, `coco_m_undo`
back to it. The engine winds the trail back at a choice point, and a builtin
that fails is not one.

**It does not keep a term index across a call.** The heap moves. An index is
good for the length of one call. That is also why a module has no per-session
state: state a frozen machine cannot carry is state that comes back wrong
somewhere else.

## The API a module is written against

| | |
|---|---|
| `coco_m_arg(e, g, i)` | argument *i*, dereferenced |
| `coco_m_machine(e)` | the machine, for the term DSL |
| `coco_m_mark(e)` / `coco_m_undo(e, mark)` | the trail, for a predicate that may fail |
| `coco_m_is_var` / `coco_m_is_atom` | what a term is |
| `coco_m_atom(e, t)` | an atom's name, or null |
| `coco_m_int` / `coco_m_float` | a number, or 0 |
| `coco_m_text(e, t, buf, cap)` | an atom, an integer **or a code list** as a string |
| `coco_m_unify(e, t, u)` | plain unification |
| `coco_m_unify_atom` / `_int` / `_float` | unify with a fresh constant |
| `coco_m_nil` / `coco_m_cons` / `coco_m_atom_list` | building a list |
| `coco_m_error(e, what, detail)` | −1, with a message |
| `coco_m_type_error(e, want, got)` | −1, naming the term that was wrong |

`coco_m_text` accepting a code list is not politeness: cocolog reads `"abc"` as a
code list, so without it every double-quoted file name in a program would be a
type error.

`coco-mod-args` binds arguments by position and is sugar for the `let` of
`coco_m_arg` calls that every predicate starts with.

## What a module cannot do

* **Define an operator.** The reader's table is fixed at build time. This is a
  real gap: a module whose predicates want infix syntax cannot have it.
* **Leave a choice point**, or see the choice stack. The price of being
  suspendable.
* **Register another module from its predicates.** A build decides what it
  links and `use_module` decides what joins at run time -- but a predicate
  mid-call cannot swell the registry underneath the engine.

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

`apply` has **no C half at all** — `coco-defmodule` takes `nil` for the
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

**It used to fail where SWI throws.** It does not any more: the module API's
error constructors raise the term SWI raises, and `test/files/catch.pl`
compares them. A predicate that cannot do what it was asked reports
`error(type_error(list, notalist), _)` and a program catches it with the
portable `catch(G, error(type_error(T, V), _), R)`.

`delete_file/1` on a file that is not there is still a plain failure rather
than an `existence_error` — the operating system's reasons are not modelled,
only the argument errors are.

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

## Grammars, and a library that is borrowed rather than written

`lib/dcg.cicili`, and `lib/swipl/`.

### The translator is C, and lives below the engine

Every clause reaches the store through `coco_assert`, and `coco_assert` holds a
machine and a store — **not an engine**. A translator written in Prolog could
only be reached by running a goal, and there is nothing there to run one with.
So the rewriting is Cicili, and `lib/dcg.cicili` is imported before `kb`.

That placement is what makes `-->` mean one thing by all three routes: consulted
from a file, asserted by a running program, or arriving from the database. It
also settles the bootstrap question that would otherwise exist — a translator
written in the notation it exists to translate.

The file therefore has **two generics**. `decl-dcg`/`impl-dcg` is the translator
and goes before `kb`; `decl-dcg-module`/`impl-dcg-module` is the module half and
goes after the engine, because it calls it.

### phrase/2,3 is a clause, not a builtin

A builtin cannot call what it built. It answers 1 and the engine puts the
caller's continuation back; there is no way from inside one to say "and now run
this". So the C half translates and hands the goal back, and one clause does the
calling:

```prolog
phrase(G, L)    :- phrase(G, L, []).
phrase(G, L, R) :- '$dcg_goal'(G, L, R, Goal), call(Goal).
```

Going through `call/1` is also what makes a `!` inside a grammar body local to
it, which is what it should be.

### Why SWI's boot/dcg.pl is not copied

It is 375 lines, of which about half are source-position terms and `q(M,C,Pos)`
module qualification threaded through every clause — machinery for a module
system and an error reporter cocolog does not have. Its own author's comment
reads *"It's a nice mess now and it should be redone from scratch."* What
survives removing both is short enough to write, and writing it keeps the core
free of third-party code.

**The shapes are SWI's**, and `test/files/dcg.pl` holds them to it: terminals,
`{}/1`, `!`, `,`, `;`, `->`, `*->`, `\+`, `call//N`, a variable body, and
pushback. What is *not* compared is the translated clause's exact body — SWI's
compiler lifts a leading unification into the head, so `clause/2` there shows
`greeting([hello|S1], S) :- name(S1, S)` where cocolog leaves the unification in
the body. Both prove the same things in the same order; pinning it would be
testing SWI's clause compiler rather than this translation. cocolog's own shape
is checked in `test/solve.cicili`.

### Two libraries ARE copied

`library(dcg/basics)` and `library(dcg/high_order)`, byte for byte, into
`lib/swipl/`. They are BSD-2-Clause; so is cocolog, so there are no two
licences to reconcile. **Nothing in them is edited** — the point of an
unmodified copy is that `diff` against a newer upstream is meaningful, and
`lib/swipl/README.md` carries the version, date and checksums that make
that possible.

Everything they needed was built here instead:

| what the copy uses | what was built |
|---|---|
| `*->` | the soft cut, in `lib/solve.cicili` |
| `format(codes(H,T), ...)` | `format/1,2,3`, above |
| `with_output_to/2` | above |
| `code_type/2`, `must_be/2`, `string/1` | above |
| `ord_intersection/3`, `ord_subtract/3` | the Lists module, standing in for `library(ordsets)` |
| `:- module`, `:- use_module`, `:- meta_predicate`, `:- multifile` | accepted and ignored by `coco_directive` |

**`:- module/2`'s export list is ignored.** cocolog has one namespace, so every
predicate in a vendored file is callable, including the ones upstream keeps
private. That is a real difference in behaviour and is recorded rather than
papered over.

### `http_request/3`: what was not this request

    http_request(Codes, Request, Rest)

`Rest` is the bytes after the body `Content-Length` accounted for — none on a
connection carrying one request, and the beginning of the *next* one on a
persistent connection where both arrived in the same read.

**It is the same rule as `http_request/2`'s, read forwards.** Believing
`Content-Length` exactly is what stops two requests being read as one;
handing back what is left over is what lets the second be read as *itself*.
`http_request/2` discarded it, which is safe but loses a pipelined request —
and a server that instead read past the length would be the smuggling bug
`library(http)`'s own header warns about. `library(httpd)` parses `Rest`
before going back to the socket, so a pipelined pair costs one read.

### A goal under a ceiling: `call_limited/3`

    call_limited(Goal, Limit, Result)

Runs `Goal` spending at most `Limit` inferences. `Result` is `true` if it
succeeded or `inference_limit_exceeded` if the ceiling stopped it; the whole
call **fails** if `Goal` failed, so it drops in where `once/1` was. A `Limit`
below 1 is a `domain_error(positive_integer, _)` and **not** "no limit" —
zero is how `max_steps` spells unbounded one layer down, so a caller asking
for nothing would otherwise have got everything.

**It is not named `call_with_inference_limit/3`, on purpose.** SWI's keeps the
goal's choice points alive; this commits to the first solution, because the
nested engine that carries the ceiling dies with its own choice stack. The
rule is the one `lib/builtins.cicili` already states about `bagof` and
`setof`: *a predicate that agrees with SWI until it does not is worse than one
that never claimed to.* Somebody porting code gets an existence error and
reads this, rather than a program that works until a page backtracks.

**Why it exists at all.** `max_steps` belonged to the composition root —
`cocolog step` was the only thing that ever set it — so nothing a *program*
ran could be bounded from inside a program. `library(httpd)` cannot live with
that: it serves one connection at a time, so a page that loops is not a slow
request, it is the end of the service.

**The ceiling narrows, never widens.** A goal asking for a million inferences
inside a `cocolog step` with a thousand left gets the thousand. `findall/3`
already narrows this way, and a fence that could *raise* a budget would be a
way around the outer one rather than a limit under it.

**What survives and what does not.** Bindings survive a success and are undone
by the ceiling — a half-run goal must not answer with half a term. What the
ceiling does *not* undo is anything the goal **asserted**: the trail comes
back, the store does not shrink. That is the property `assert` itself relies
on, and a page that writes should do it last.

**An exception inside is an exception outside**, and that took a field on the
engine. The nested engine unwinds its own stack, so the ball's term is gone by
the time control is back — except that `coco_throw` puts every ball in the
*store* before it unwinds, and `coco_engine` now records which cell. It is read
back and thrown again in the outer engine, where an enclosing `catch/3` matches
it exactly as it would have without the fence.

That is not a nicety. The first version of the builtin let an exception out as
a message only, and wrapping a page in it turned every page error into a dead
request handler; the suite caught it in one run. **`findall/3` still has the
older behaviour** — an uncaught throw inside it ends the query with a message
no `catch/3` sees. The machinery to fix it is now in place; changing a core
predicate wants its own case, so it was not done in passing.

### The soft cut

`(C *-> T ; E)` runs `T` for **every** solution of `C`, not just the first — so
the alternative holding `E` has to go while `C`'s own choice points stay. A cut
will not do: it truncates the stack to a height, and everything `C` pushed is
above the frame holding `E`.

`'$softcut'(H)` kills the one frame at `H` instead, by changing its **kind** to
`COCO_CH_DEAD`. A kind and not a flag, because the frames travel in a frozen
machine as a fixed row of numbers and the kind is already one of them — a new
field would change that format for every blob ever written, while a new kind is
a value no old blob contains. It cannot simply be popped: every barrier, every
`$cut` height and every restored `nchoices` is an index into that array.

## The three document libraries: a term as a document, and back

`library(json)`, `library(xml)` and `library(html)` go both ways. They are
tier 2, pure clauses, and they need no `.so`:

    use_module(library(json)).
    use_module(library(xml)).
    use_module(library(html)).

| | writing | reading |
|---|---|---|
| codes | `json_codes/2,3` `xml_codes/2,3` `html_codes/2,3` | `json_parse/2,3` `xml_parse/2,3` `html_parse/2,3` |
| an atom | `json_atom/2,3` `xml_atom/2,3` `html_atom/2,3` | the readers take codes **or** an atom |
| the output | `json_write/1,2` `xml_write/1,2` `html_write/1,2` | |
| a grammar | `json_value//1` `xml_content//1` `html_content//1` | `json_input//1` `xml_input//1` `html_input//1` |

`json_parse/3` is the STREAMING one — `json_parse(+Codes, -Term, -Rest)`,
where `Rest` is what was not this value. It is `http_request/3`'s rule applied
here: a socket hands you what arrived, which may be one value and the start
of the next. The other two take options in the third argument instead.

**The shapes differ, and the languages are why.** `xml_parse/2` answers ONE
element, because XML requires exactly one root; `html_parse/2` answers a
LIST, because HTML does not — and a list is what `html_codes/2` takes at the
top, so the two compose with no wrapper.

**`_codes` IS THE PRIMITIVE and the other three stand on it.** An atom in
cocolog is a C string and stops at the first NUL; codes carry every byte, are
what `tcp_write/2` takes, and concatenate without a round trip. `_atom` is
there for when an atom is genuinely what you have to produce, and `_write`
goes to the current output through `~s` rather than through an atom.

**The `//1` nonterminal is for a caller already building codes**, which is
what a page assembling its own body is. It emits compactly, because a
fragment being assembled has no level to indent to.

### The terms

| | JSON | XML / HTML |
|---|---|---|
| an object / an element | `json([K-V, …])`, also `K=V` and `K:V` | `element(Name, Attrs, Kids)` |
| a sequence | a list | the `Kids` list |
| text | an atom, or `str(X)` | an atom or number, or `str(X)` |
| a number | a number | text |
| the literals | `@(true)`, `@(false)`, `@(null)` | — |
| verbatim | — | `raw(Text)` |
| the rest | — | `comment/1`, `cdata/1` (XML), `pi/1` (XML) |

Attributes are `Name=Value` or `Name-Value`; HTML also takes a bare `Name`,
which is the minimised form, and XML refuses one because XML has none.

### `str/1`, and why it is not optional

cocolog has no string type. `double_quotes` is `codes`, so `"hello"` IS
`[104, 101, 108, 108, 111]` and nothing in the term says which you meant.

    json_atom("hi", A).                     A = '[104,105]'      an array
    json_atom(str("hi"), A).                A = '"hi"'           a string
    xml_atom(element(p,[],["hi"]), A).      type_error(xml_node, [104,105])
    xml_atom(element(p,[],[str("hi")]), A). A = '<p>hi</p>'

**The XML error is there because the alternative was measured**: before the
rule, that call answered `<p>104105</p>`. A serialiser that guesses is one
that is silently wrong, and silently wrong markup is found by whoever reads
the page, days later.

### The options

    indent(N)        JSON and XML. Absent or 0 is compact.
    header(true)     XML: <?xml version="1.0" encoding="UTF-8"?>
    header(Enc)      XML: the same, with Enc as the encoding
    doctype(Text)    XML: <!DOCTYPE Text>
    doctype(true)    HTML: <!DOCTYPE html>
    doctype(Text)    HTML: <!DOCTYPE Text>, for a legacy one

**`library(html)` has no `indent`, on purpose.** `library(xml)` indents an
element whose children are ALL elements and leaves mixed content on one line,
because a whitespace node between elements is what a schema-aware reader
already ignores. HTML has no such rule: whitespace between two inline
elements is a rendered space, so `<span>a</span><span>b</span>` and the same
across two lines are different pages. An indenter there would be a renderer
that quietly edits.

### Serving one from a page

`httpd_page/3`'s reply takes an atom body, so a page that answers JSON is one
line longer than a page that answers text:

    httpd_page('/api/stock', _, reply(200, ['Content-Type'-'application/json'], Body)) :-
        findall(json([item-I, n-N]), stock(I, N), Rows),
        json_atom(json([stock-Rows]), Body).

    httpd_page('/', _, reply(200, [], Body)) :-
        html_atom(element(html, [], [element(body, [], [element(p, [], ['hello'])])]),
                  Body, [doctype(true)]).

### What they refuse

Every one of these throws, naming the term, rather than emitting something
plausible:

| | |
|---|---|
| an unbound variable | `instantiation_error` — a hole is not `null` |
| `foo(1)` as JSON | `type_error(json_term, foo(1))` |
| `@(maybe)` | `type_error(json_term, @(maybe))` — there are three literals |
| an infinite or NaN float | `type_error(json_number, …)` — JSON has no spelling for either |
| a list among the children | `type_error(xml_node, …)` / `html_node` — see `str/1` above |
| a bare attribute in XML | `type_error(xml_attribute, …)` |
| `<br>` with children | `domain_error(html_empty_content, …)` |
| `--` in an XML comment | `domain_error(xml_comment, …)` — XML 1.0 has no escape for it |
| `-->` in an HTML comment | `domain_error(html_comment, …)` |
| `cdata/1` in HTML | `type_error(html_node, …)` — HTML5 has no CDATA sections |
| a NUL byte in XML text | `domain_error(xml_text, …)` — unwritable, and it would truncate the atom |
| `</script` inside a `script` | `domain_error(html_raw_text, script)` |

**That last one is the only security-shaped check in the three**, and it is
there because escaping is NOT the answer inside a `script`: `a < b` must
reach the JavaScript parser as `a < b`, so the content goes out untouched and
the end tag is the whole risk. The check is case-insensitive because the HTML
tokenizer is — `</ScRiPt` closes the element just as well.

It is also why `library(json)` does not escape the solidus. `\/` is legal JSON
and pointless; the hazard lives at the EMBEDDING, and there it is caught by
name rather than by a habit three layers away.

**`library(html)` calls `library(xml)`'s escapers by name** — `xml_escaped//1`,
`xml_text_codes/2`, `xml_no_nul/2` — rather than copying them. One namespace
is what makes that work, and a private copy of an escaper is how two escapers
end up disagreeing about the apostrophe.

**And the UTF-8 encoder IS copied, three times**, which is the same argument
read the other way. An escaper encodes a POLICY — which characters this
project decided to escape — and two copies of a policy drift. RFC 3629 is a
FIXED TRANSFORM that cannot, and copying it is what lets `library(json)` stand
alone rather than importing a markup library in order to read a `\uXXXX`.

### Reading

    json_parse('{"a":[1,true]}', T).     T = json([a-[1, @(true)]])
    xml_parse('<p>a &lt; b</p>', T).     T = element(p, [], ['a < b'])
    html_parse('<ul><li>x<li>y</ul>', T).
        T = [element(ul, [], [element(li,[],[x]), element(li,[],[y])])]

**A JSON string comes back as an ATOM**, which is the inverse of the writer's
rule and what makes the round trip close. It also means the empty string is
`''` and not `[]`, which is the distinction the writer needs to tell a string
from an array.

**XML text comes back as one node per RUN.** A stretch of characters, an
entity reference and a CDATA section next to each other are one atom, because
they are one text node to XML. CDATA comes back as TEXT rather than as
`cdata/1`: the section is a SPELLING of character data, not a kind of node,
and `<p><![CDATA[a<b]]></p>` and `<p>a&lt;b</p>` are the same document. The
writer still has `cdata/1` for when you want that spelling going out.

`space(remove)` drops text nodes that are ENTIRELY whitespace, which is what
turns an indented document back into the tree somebody meant. It never TRIMS
a node that has other characters in it — that would be editing content, which
is the line the writer draws when it refuses to indent mixed content.

### THE ROUND TRIP IS THE REAL TEST

    json_atom(T, A1), json_parse(A1, T2), json_atom(T2, A2).    % A1 == A2

A reader and a writer that disagree about the same bytes are worse than
either one alone, and no amount of hand-written expectations on each half
finds a disagreement between them. Six cases in `test/serialize.sh` write,
read and write again, for all three libraries, and compare the texts.

### There is no DTD, and that is the XXE answer

`library(xml)` SKIPS the DOCTYPE declaration — internal subset and all — and
has no code that could open a file or a socket. There is no fetching in the
library at all, so the whole external-entity family is structurally
impossible rather than defended against.

An entity a DOCTYPE declared is therefore never defined, so `&whatever;` in
the content is an error naming the entity — the parser cannot know what it
expands to and will not guess. The five predefined entities and numeric
character references are all that exist.

**`library(html)` does the opposite with an unknown entity and leaves it as
TEXT**, which is the languages differing again rather than laxity: HTML has a
fixed table of some two thousand names and a browser leaves anything not in
it as literal characters. It is what makes `AT&T` render as `AT&T` on every
page that ever wrote it that way.

### `library(html)` is not an HTML5 tree builder

Said plainly because the difference matters. The standard's algorithm is a
tokenizer, an insertion-mode state machine, the adoption agency for misnested
formatting, foster parenting for content stranded in a table, and implied
`<html>`, `<head>` and `<body>` around everything — thousands of lines and a
conformance suite. A HALF one is worse than none: it produces a tree that
looks right and quietly is not the one a browser built.

What it DOES handle is the part that actually differs from XML in documents
people write:

| | |
|---|---|
| void elements | no children, no end tag; `<br>` and `<br/>` are the same |
| `script`, `style` | raw text, read verbatim to the matching end tag, case-insensitively |
| `textarea`, `title` | escapable raw text: no nesting, but entities resolve |
| optional end tags | `html_closes/2` — `<li>` closes `<li>`, `<tr>` closes `<td>`, a block element closes `<p>` |
| misnested end tags | `</div>` with a `<span>` still open closes both, as a browser does |
| names | downcased, because HTML's are case-insensitive |
| attributes | double-quoted, single-quoted, unquoted, or bare |
| a stray `<` | text, not a broken tag — `a < b` in a paragraph is three characters |
| a stray end tag | discarded where it surfaces |

What it does NOT do: implied `html`/`head`/`body`, foster parenting, the
adoption agency. Feed it a document written by a person or by `html_codes/2`
and you get that document's tree; feed it something a browser has to repair
and you get the tree as written, not the tree as rendered.

### When a document will not parse

All three THROW, and the ball carries where:

    error(syntax_error(What), json_at(Snippet))
    error(syntax_error(What), xml_at(Snippet))
    error(syntax_error(What), html_at(Snippet))

`What` is what was expected — sometimes a compound, like
`mismatched_end_tag(a, b)` or `unclosed_element(a)` — and `Snippet` is the
first forty bytes that were there instead, as an atom. **A snippet rather than
an offset**, because an offset is only useful with the document beside it and
forty bytes of what was actually there is readable in a log by somebody who
has not got the file.

`library(json)` is RFC 8259 including the parts people leave out, and each of
these is a place where two implementations disagree about the same bytes:

| | |
|---|---|
| `01` | a leading zero is not a number |
| `+1`, `.5`, `5.` | none of them is in the grammar |
| `[1,]` | after a comma the grammar requires another value |
| a raw control byte in a string | must be escaped |
| `12345678901234567890` | past 64 bits — `number_codes/2` answers -1 for it without complaining, so the digits are written back and compared |
| a lone surrogate | there is no UTF-8 for half a character |
| `\u0000` | an atom stops there, so the parser would answer a shorter string than the document held |

That last one is the only place the round trip is not total, and it is
one-directional: the writer can still emit a NUL that arrived some other way.

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

`findall/3` `findall/4` `bagof/3` `setof/3` `forall/2` `aggregate_all/3` ·
`keysort/2` · `op/3` `current_op/3` · `between/3` `succ/2`
`plus/3` · `ground/1` `term_variables/2` `unify_with_occurs_check/2` ·
`atom_chars/2` `char_code/2` `number_chars/2` `atom_number/2` `upcase_atom/2`
`downcase_atom/2` `term_to_atom/2` `sub_atom/5` `atomic_list_concat/2`
`atomic_list_concat/3` · `writeq/1` `print/1` `write_term/2` `tab/1` ·
`clause/2` `current_predicate/1` `retractall/1` `abolish/1` ·
`nb_setval/2` `nb_getval/2` `b_setval/2` `b_getval/2` · `halt/1`.

(`length/2`, `msort/2`, `sort/2` and `sort/4` are in the Lists module, which
needed them first.)

### What was added alongside the ISO core

`format/1,2,3`, `with_output_to/2`, `code_type/2`, `char_type/2`, `must_be/2`
and `is_of_type/2`, and `string/1`.

None of these is ISO. They are here because SWI's `library(dcg/basics)` calls
them and cocolog is meant to run that file unmodified — and because `format/2`
is the predicate a Prolog program reaches for more than any other, so its
absence was a hole rather than a choice.

**`format/2` has no column directives.** `~t`, `~|` and `~+` lay text out in
fields by measuring what has been written since the last column stop, which is
a second pass this does not make. They raise an error naming themselves rather
than being ignored — silently dropping them turns a table into a run-on line
and blames the program. Everything else is there: `~w ~q ~p ~a ~d ~D ~s ~c ~e
~f ~g ~r ~R ~n ~i ~~`, the numeric and `~*` argument prefixes, and the
`atom(A)`, `codes(C)`, `codes(H,T)`, `chars(C)`, `chars(H,T)`, `user_output`
and `user_error` sinks. The difference-list sinks are not decoration: they are
what makes `format(codes(H,T), '~d', [I])` work as a grammar body, which is how
SWI's `dcg/basics` generates every number it can also parse.

**`code_type/2` was written against a running SWI, not against its manual**,
because the two disagree. The manual calls `alpha` "a letter or digit"; the
implementation says letters only. `to_upper(L)` reads as though `L` were the
uppercase and it is the lowercase — `dcg/basics` depends on that, in
`alpha_to_lower//1`. `test/files/ctype.pl` walks every code from 0 to 127
through every category in both systems, which is the only way either of those
would have been got right.

**`string/1` always fails, and that is the answer rather than a stub.** cocolog
has no string type, so nothing is a string. It exists because library code
branches on it: SWI's `string_without//2` asks `string(End)` to decide whether
to convert its argument and falls through to the code-list clause when the
answer is no — which is the clause cocolog wants. A missing `string/1` raises
there instead, and the fall-through never happens.

**`with_output_to/2` redirects file descriptor 1**, not a stream this code
passes around, because cocolog writes to the literal `stdout` in some seventy
places. It uses a temporary file and not a pipe: a pipe holds 64K and a goal
that printed more would block for ever with nobody reading. The goal runs in a
nested engine, so — like `findall/3` — it cannot be suspended. A machine frozen
inside one would have to freeze a redirected file descriptor with it.

### An undefined predicate raises

Calling something nobody defined used to fail quietly. It now raises
`existence_error(procedure, Name/Arity)`, which is what SWI does and what every
library written against SWI expects.

**No clauses is not the same as undefined.** A predicate declared `dynamic`, or
brought into being by an `assert` and emptied again by a `retract`, exists and
simply has nothing to prove — so it fails. Asserting into a predicate is what
makes it dynamic, which is SWI's rule and the thing that makes the distinction
hold: without it, `assertz(f(1)), retract(f(1)), f(_)` would raise where every
other Prolog fails.

### findall had to be an engine service

It runs a goal to exhaustion, and a module cannot see the engine. So
`lib/solve.cicili` grew `coco_engine_findall`, which starts a **nested engine**
on the same machine and store, and the module calls it. `forall/2` and
`aggregate_all/3` are built on the same service.

**The solutions travel through the store, not the heap.** Backtracking
truncates the heap to the choice point's mark, so a copy made on the heap
during the search is gone by the time the search ends — the collection would
come back empty, or pointing at cells that had been reused. The store never
shrinks, which is the property `assert` already relies on.

The inner search spends the outer one's remaining step budget, so a `cocolog
step` with a limit cannot be overrun by a `findall` inside it.

### bagof/3 and setof/3 backtrack, so they are clauses

They are **not** `findall` plus a sort. They answer once per distinct binding of
the goal's **free variables** — the ones that appear in the goal, do not appear
in the template, and were not quantified away with `^`:

```prolog
p(1,a). p(2,b). p(3,a). p(1,c).

?- bagof(X, p(X,Y), L).
Y = a, L = [1,3] ;  Y = b, L = [2] ;  Y = c, L = [1].
```

And they **fail** where `findall` answers `[]`. That is the other half of what
makes them different predicates.

The whole implementation is: work out the witness, collect `Witness-Template`
pairs with `findall`, `keysort` them, group the runs, and hand the groups to
`member/2` — which is where the backtracking comes from, and is why this is in
the Coco half rather than in C. `keysort/2` is `sort(1, @=<, ...)`, and its
**stability matters**: the order within a group is the order the solutions came
in.

Two details that are easy to get wrong and are why the tests exist: the witness
variables are subtracted **by identity** (`==`), because two distinct free
variables unify with each other while being different witnesses entirely; and
the group keys are compared with `==` rather than `=`, because unifying them
would merge two groups whose witnesses merely happen to unify.

### What is still missing

Nothing from the list this module set out to close. What remains are the
families cocolog has no architecture for — streams, modules, threads, tabling,
the foreign interface — and the two places `STATUS.md` records where this
reader and SWI's are lenient about different things.


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
`$`-prefixed `$len` `$rev` `$nth0`. Sorting goes through `coco_compare`, the same
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

`msort(notalist, _)` raises `type_error(list, notalist)` here now, as it does
there. `length(_, -1)` is still a plain failure where SWI raises a
`domain_error`, which is the last of these left.
