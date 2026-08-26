# Working on cocolog

README.md says what cocolog is and STATUS.md what is proven. This says how to
work in here and what will bite you.

## cicili and ZiguratIP are frozen

**Only this repository may be modified.** The other two are inputs.

| repo | role | frozen at |
|---|---|---|
| `../cicili` | the language cocolog is written in; used at BUILD time | `00ca101` |
| `../ZiguratIP` | the database; used at RUN time and by `make schema` | **unfrozen** |

**cicili stays frozen**: no edits, commits, pushes, branch changes or `git add`
in it. A cocolog problem that traces to the transpiler gets a diagnosis and a
proposed patch, not an applied one.

**ZiguratIP was unfrozen** to fix the twelve-worker slowdown, and carries the
`TCP_NODELAY` change described in STATUS.md. Rebuild it and then `make schema`
after touching it — see the hazard below.

What the freeze still allows: `make schema` compiles cocolog's OWN Parsi objects
into `$ZIGURATIP_HOME/ld`, and the server writes to `$ZIGURATIP_HOME/data`.
Neither dirties the ZiguratIP repo — `*.so` is gitignored there and `home/data`
has no tracked files — so `git status` in it stays empty. Verify that it does.

## Build and test

```sh
export CICILI=/home/user/cicili                  # a Cicili checkout, for sbcl
export ZIGURATIP=/home/user/ZiguratIP            # a BUILT ZiguratIP checkout
export ZIGURATIP_HOME=/home/user/ZiguratIP/home  # and its home
make            # the C client and the ONE cocolog binary (embedded store
                # and torch module linked in; needs libtorch too)
make schema     # compile the Parsi objects into $ZIGURATIP_HOME
make test       # the suite
sh test/run.sh solve      # one case
```

There is one `cocolog` binary and it is full: the four knowledge-base
arrangements — `--local`, the server, `--http`, `--embed [DIR]` — are
runtime options, never builds. Local is the default; naming `--kb`, `--host`
or `--port` chooses the server, and a bare `--embed` opens the store at
`./KB`. There is no `--store`: `--embed` with its optional directory is
the one spelling, and a store named like a command verb is written `./run`.

The server, which the database tests need:

```sh
cd /home/user/ZiguratIP && ZIGURATIP_HOME=$PWD/home \
  LD_LIBRARY_PATH=$PWD/home/lib setsid ./home/bin/ziguratip
```

Start it detached. A plain `nohup … &` from a tool call does not survive the
turn, and what you get then is the next hazard.

## Three hazards, each of which has already cost a day

**A slow suite is the store ageing, not your change.** Deleted rows are kept
under MVCC and nothing reclaims them, so every run leaves more behind and every
later read walks past it. Twelve workers went from 14s to 32s over five identical
runs. `test/groups.sh` allows 60s per worker, so a long-lived store will
eventually push it over — and that reads as a hang. Restart from a fresh
`$ZIGURATIP_HOME/data` if the numbers stop making sense. `cocolog vacuum` is
the answer on a store written since the schema went `NOT NULL` — `groups` and
`ruler` run it in setup, and README's "A worked store slows down. Truncate it."
has the numbers; a store from before that carries NULLs and can only be
restarted (STATUS.md says why).

Two things follow when a run does go wrong. A killed worker used to **strand
its machine as claimed**; since the turn became ONE transaction (claim
included), a dead or failed worker's claim rolls back with its turn and the
machine goes straight back to the pool — but a `list` after a bad run is
still worth a look, because a machine claimed by a *live* wedged worker
looks the same as it always did. And a wedged server answers NOBODY on any
knowledge base, so restart it before blaming whatever you were working on.

**`red: 0` does not mean the suite passed.** `zigurat`, `shared`, `groups` and
`ruler` SKIP rather than fail when there is no server, because "no server here"
and "the backend is wrong" are different findings — and the runner prints
`red: 0` either way. **Run `pgrep ziguratip` before believing a green run**, and
read the eight per-case lines rather than the last one.

**Rebuild the Parsi objects after ANY change to the ZiguratIP engine.** A `.so`
in `$ZIGURATIP_HOME/ld` compiled against old engine headers does not fail to
load politely; it takes the server down with `symbol lookup error`. `make schema`
after every engine build, always.

**A PAGE and a PROCEDURE of the same name are ONE compiled object**, and pages
compile last. `cocolog::predicates` was both, so the procedure's `.so` was
silently replaced and every call to it died with `undefined symbol: call`. That
is why the procedures are `predicates_of` and `props_of`. Check
`parsi/03-pages.parsi` before naming anything in `parsi/02-procedures.parsi`.

## Cicili, as it is actually written

Cicili is Lisp-syntax C. It is not C in parentheses, and these are the places
that read like C and are not:

* **A string literal is raw.** It reaches C untouched, so `"\n"` is two
  characters in the source and a newline only after the C compiler sees it. A
  string may **not** end in a backslash.
* **`defer` is a variable attribute of a `let` or `var` binding, not a
  statement** (`../cicili/doc/DOC-C.md`). Nothing in cocolog uses it yet, so
  there is no local example to copy.
* **`break` and `continue` are bare keyword symbols** — `break`, not `(break)`.
* **Use `bitand`, `bitor`, `xor`** — not `&`, `|`, `^`.
* **There is no character literal.** `(coco-ch-between c "a" "z")` expands to the
  numeric comparison; write characters through the macros, or as their codes
  with a comment saying which character.
* **A function pointer in a variable is written as a `func` clause in type
  position.** `coco_store_reset` in `lib/kb.cicili` is the worked example.

* **A string literal cannot contain a newline** — as a real newline it lands
  unescaped inside a C literal, as `\n` it is emitted as an escaped backslash.
  A module's Prolog half is therefore joined with spaces; see MODULES.md.
* **Lambda-list markers must be uppercase** in a macro: `&REST`, not `&rest`.
  Case is preserved, so the lowercase one is a different symbol and the macro
  is called with the wrong arity.
* **A macro emits ONE form.** Several from one macro leaves the symbols
  unregistered and the next reference is "unknown symbol".
* **`new` is a Cicili macro**, so a local of that name is read as a call to it.
* **A dotted initialiser** — `(var size_t n . 0)` — cannot be written inside a
  generic in this package, because `nil` there is `cocolog::nil` and the form
  is genuinely dotted. A static is zero anyway.
* **`(out (T *))` is wrong; `(out T *)` is right.** The parenthesised form
  emits a cast to a non-scalar type.
* **`(cast unsigned char x)` is wrong** — a cast takes ONE type token, so a
  two-word C type cannot be written. Mask instead: `(bitand (cast int c) 255)`.
* **A `let` declares locals; `block` does not.** `(block (char err [256]) ...)`
  fails with `unknown symbol: [`.
* **`for` takes a BINDING LIST, not a C-style init**: `(for ((size_t i . 0)) (< i n)
  ((++ i)) BODY)` — four parts, and the step is parenthesised. Writing
  `(for ((set i 0) (< i n) (++ i)) BODY)` fails with `The value 0 is not of type
  SEQUENCE`, which is a message about Lisp and says nothing about the loop.
* **Indexing is `(nth INDEX ARRAY)`** — index first — and there is no `aref`.
* **Arrays may have two dimensions** — `[]`, `[N]`, `[N][M]`, and no more. (This
  file briefly said the opposite: a `for`-loop error was blamed on the array
  beside it. `doc/DOC-C.md` says two, and two work.)
* **A `#define` is invisible to Cicili**: it is raw C, so a constant named in one
  is an `unknown symbol` when a Cicili form uses it. Write the number out, the
  way `files.cicili` writes 4096 rather than PATH_MAX.
* **`../cicili/lib/std/c/posix/` ALREADY DECLARES the POSIX structs**, members
  and all — `sockaddr_in`, `pollfd`, `addrinfo`, `stat_t` — and the prelude loads
  them before your file. Do not describe a system header again. What is missing
  is only the C typedef, because a Cicili type is one token and `struct pollfd`
  is two: `(@define (code "pollfd struct pollfd"))`, and **the name must match
  the one std declares the members under**. `pollfd_t` is a different name with
  no members, and `($ p fd)` then says `unknown struct type` — which is how
  `lib/tcp.cicili` ended up written in raw C escapes for a day.
* **`(code "...")` is the fire escape, not the door.** It is C that Cicili cannot
  see or type-check, and no front end can help it. Reach for a Cicili clause
  first, every time.
* **`$` chains**: `($ a b c)` is `a.b.c`. `(-> p m)` is `p->m`. `(=> o m args)`
  calls a function stored in a member, one level only.
* **An external `struct` needs a name**: `(@define (code "stat_t struct stat"))`,
  per `../cicili/doc/lib-std-c.md`. `(code "...")` is the raw-C escape for what
  `lib/std/c` does not declare — `glob` and `realpath`, in `lib/files.cicili`.

`../cicili/doc/` is the reference, and `../cicili/lib/README.md` an index of
what the language ships with. Read them rather than guessing at syntax — a
wrong guess usually compiles to something that fails much later.

The macro layer is where the work is. `*cell-tags*`, `*operators*`, `*builtins*`
and `*turn-outcomes*` each emit several things that must not drift apart —
**add to the table, never to the generated code.**

## Parsi, as it is actually written

* `IF cond BEGIN … END`, not `IF … THEN … END IF`.
* `<>` for not-equal.
* Names fold to upper case, so a column named `text` collides with the `Text`
  type — which is why the clause column is called `body`.
* A row must fit in a page. With the default 8192-byte page a `Text` of 8000
  stores and one of 8192 comes back `allocation overflow`, which is why machine
  state travels in 4000-byte chunks.

## Three tiers of library, and which one a thing belongs in

Reviewed because it had never been written down and the answer was not
what the directory layout suggests.

**TIER 1 — registered at start-up. Always there, `use_module` optional.**
`install_modules' in `cocolog.cicili' calls each one's registration:

    apply  bigint  builtins  dcg  files  library  lists  tcp  torch  zigurat

`use_module(library(lists))' succeeds instantly for these — the module is
already registered, so the call is a no-op that costs nothing. They are in
the binary because the binary would be crippled without them.

**TIER 2 — on the library path, loaded at run time.** `$COCOLOG_LIBRARY'
(colon-separated), then `./library'. Two kinds live here and
`use_module(library(Name))' finds either:

| | |
|---|---|
| `library/*.pl` | clauses only. `http.pl` — HTTP/1.1 as a grammar |
| `library/*.so` | a Cicili module against `lib/sdk.cicili`, dlopen'd. `curl.so` |

**A THING BELONGS IN TIER 2 WHEN ITS DEPENDENCY SHOULD NOT BE
EVERYBODY'S.** That is the whole rule. libcurl is a fine library and a
poor thing to require of someone who wants an interpreter and no network,
so `library(curl)` is a `.so` built by `sh lib/curl/build.sh` and is not
part of `make`. torch and bigint went the other way because the binary's
own story needs them.

**TIER 3 — shipped and NOT REACHABLE, which is a bug.**
`lib/vendor/swipl/` holds SWI's `assoc`, `pairs`, `ordsets`, `yall`,
`aggregate`, `ugraphs`, `dcg_basics` and `dcg_high_order`, vendored under
their own BSD-2 headers — and nothing puts that directory on the library
path. On a plain checkout:

    ?- use_module(library(assoc)).
    use_module: library(assoc): not found on the library path

They work only for a caller who sets `COCOLOG_LIBRARY` by hand, which no
test and no document tells them to do. Fixed by adding the directory to
the default path in `lib/library.cicili`.

The default path is relative to the WORKING DIRECTORY (`./library`), so a
cocolog run from elsewhere finds neither tier 2 nor the vendored set.
That is pre-existing and is the next thing to fix here.

## Where things are

| path | what |
|---|---|
| `lib/term.cicili` | cells, unification, the trail, copying |
| `lib/syntax.cicili` | the reader and the writer, from one operator table, plus the run-time one `op/3` adds |
| `lib/kb.cicili` | the clause store and its five backend hooks |
| `lib/solve.cicili` | the engine and the builtin table |
| `lib/module.cicili` | the module seam and the API a module is written against |
| `lib/files.cicili` | SWI's Files library, as a module — mostly C |
| `lib/tcp.cicili` | the socket seam: listen, connect, accept, read, write, close. A handle is an index into this module's own table, never a file descriptor |
| `lib/lists.cicili` | SWI's Lists library, as a module — mostly Prolog, because nondeterministic predicates cannot live in a C half |
| `lib/apply.cicili` | SWI's Apply library — clauses only, no C half |
| `lib/builtins.cicili` | the ISO core builtins cocolog was missing, plus `format/1,2,3`, `code_type/2` and `must_be/2` |
| `lib/dcg.cicili` | `-->` translation, `phrase/2,3`. Two generics: the translator sits BEFORE `kb` because `coco_assert` calls it, the module half after the engine |
| `lib/vendor/swipl/` | SWI's `dcg/basics` and `dcg/high_order`, copied unmodified under their own BSD-2 headers. Do not edit them — see the README there |
| `lib/library.cicili` | `use_module`: run-time loading of `.pl` and dlopen'd `.so` libraries |
| `lib/sdk.cicili` | the module API over opaque types, for out-of-tree Cicili modules |
| `lib/bigint/` | Zigurat's BigInt as predicates. A SUBDIRECTORY, so `$(wildcard lib/*.cicili)` does not sweep it into cocolog.c — it is its own translation unit, built by its own `build.sh` and linked at the end, because it is C++ and needs libCore. `torch/` and `embed/` are the same shape and still live at the top level |
| `lib/state.cicili` | freeze and thaw of a machine |
| `lib/zigurat-kb.cicili` | the binary-protocol backend (reads and writes) |
| `lib/zeytun-kb.cicili` | the HTTP backend (reads only) |
| `client/` | pure C, speaks the wire protocol, includes nothing of ZiguratIP |
| `parsi/` | the schema, procedures and pages compiled into a ZiguratIP home |

The store's hooks — `fetch`, `on_assert`, `on_retract`, `on_dynamic`, `warm` —
are the seam. Everything above them is written against the store and knows
nothing about where clauses come from. **A feature that touches the knowledge
base needs all three arrangements considered**: local (no hooks), Zigurat (all
five), Zeytun (`fetch` and `warm` only, because one HTTP request is one
transaction and a machine is many rows).

## Before saying something works

Run `make test` with a server up, and check the ten case lines. `files` also
SKIPs without `swipl` (`apt-get install swi-prolog-nox`) — another green line
that means nothing was run. A change to
the knowledge base also wants proving **across processes** — one `cocolog`
invocation writing and a second, which consulted nothing, reading — because
that is the claim the project exists to make and an in-process test cannot make
it.
