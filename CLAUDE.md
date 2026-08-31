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
`TCP_NODELAY` change described in STATUS.md — and, since the forget wedge,
two more: the unmap resume mark in the MVCCS engine and the
rollback-on-disconnect in the server's connection scope (the "APPLIED"
section below). Rebuild it and then `make schema` after touching it — see
the hazard below; a change to `MVCCS-cicili/mvccs-lib.cicili` also rebuilds
cocolog's EMBEDDED engine, which is transpiled from the same file through
the `embed/mvccs-lib.cicili` symlink.

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
arrangements — `--local`, the server, `--http`/`--https`, `--embed [DIR]`
— are runtime options, never builds. Local is the default; naming `--kb`, `--host`
or `--tcp` chooses the server, and a bare `--embed` opens the store at
`./KB`. There is no `--store`: `--embed` with its optional directory is
the one spelling, and a store named like a command verb is written `./run`.

The server, which the database tests need:

```sh
cd /home/user/ZiguratIP && ZIGURATIP_HOME=$PWD/home \
  LD_LIBRARY_PATH=$PWD/home/lib setsid ./home/bin/ziguratip
```

Start it detached. A plain `nohup … &` from a tool call does not survive the
turn, and what you get then is the next hazard.

**`ziguratip --config=<file>` runs a CUSTOM-CONFIGURED server without
touching `home/etc/ziguratip.conf`** — the owner's own pointer. A test
that needs different settings (TLS_MODE, ports, permissions) copies the
conf, edits the copy, and raises a second server on it; the home config
stays what it was. Without `--config` the usual lookup order applies.

### One compiler, and where it is written down

Everything here is built by **clang**: the client, the interpreter, the
embedded store, every `.so` under `library/`, and — over in ZiguratIP —
libCore and the server the tests talk to. That is not a preference, it is
a requirement of the arrangement: cocolog links ZiguratIP's C++ libraries
into its own binary and `dlopen`s modules into its own process, so a
mixed toolchain is one address space with two ABIs in it.

`tools/cc/` is the whole answer, in four small files, and `tools/cc/README`
is the long version. Two things in it are worth knowing before a build
surprises you:

* **Cicili names `gcc` outright** in `config.lisp` and takes no override.
  It is frozen, so the build puts `tools/cc` on `PATH` for that one step
  and keeps a `gcc`/`g++` pair there that exec the real compilers. The
  three-line Cicili patch that would retire them is in the README, offered
  and not applied.
* **`clang++` alone does not compile C++ on this box.** It borrows
  libstdc++ from the newest gcc it can find, which is gcc-14's runtime
  directory — crtbegin.o, libgcc_s.so, and not one header, because g++ is
  13.3. Every C++ file then dies at `fatal error: 'string' file not found`
  naming a header that is plainly installed. `tools/cc/cxx` works out
  which gcc install dir actually has a header set and passes
  `--gcc-install-dir`.

`make CICILI_CC=gcc CICILI_CXX=g++` builds with gcc, and ZiguratIP's
`make COMPILER=g++` does the same there. Nothing is load-bearing on clang;
what is load-bearing is that all of it agrees.

**`?=` DOES NOT DO WHAT YOU WANT FOR `CC` AND `CXX`.** make gives them
built-in values (`cc`, `g++`) whose origin is `default`, not `undefined`,
so `CXX ?= …` leaves `g++` in place. The final link went on being a gcc
link while every other line of the build said clang, and the only way to
see it was `readelf -p .comment`. Test the origin instead:

```make
ifeq ($(origin CXX),default)
CXX := $(CURDIR)/tools/cc/cxx
endif
```

**Clang is stricter, and Cicili treats compiler chatter as FATAL.** A
target compiled as C++ needs `-Wno-parentheses-equality` and
`-Wno-dangling-else` in its own `:compile` list, because the transpiler
emits `while ((x == 0))` and unbraced else-if chains and clang complains
about both. Without them the build stops with an `Unhandled SIMPLE-ERROR`
whose text is a warning. gcc ignores unknown `-Wno-` options, so the flags
travel to every platform. `cocolog.cicili`, `embed/embed.cicili` and all
three MVCCS-cicili targets carry them.

## Four hazards, each of which has already cost a day

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

**A store wiped under a server that is still dying answers writes and
keeps NONE.** `pkill`, then `rm -rf home/data/*` a breath later, then a
new server: every `query` says `1 answer(s)`, a second process reads
nothing back, and `:- dynamic` answers `dynamic: out of memory` -- from
the OLD binary as much as the new one, which is how an hour went to
suspecting an engine commit that was innocent. `pgrep ziguratip` must
print nothing before the `rm`; a clean restart afterwards is the whole
cure.

**`red: 0` does not mean the suite passed.** `zigurat`, `shared`, `groups` and
`ruler` SKIP rather than fail when there is no server, because "no server here"
and "the backend is wrong" are different findings — and the runner prints
`red: 0` either way. **Run `pgrep ziguratip` before believing a green run**, and
read the eight per-case lines rather than the last one.

**Rebuild the Parsi objects after ANY change to the ZiguratIP engine.** A `.so`
in `$ZIGURATIP_HOME/ld` compiled against old engine headers does not fail to
load politely; it takes the server down with `symbol lookup error`. `make schema`
after every engine build, always.

**An index changed in `parsi/01-schema.parsi` comes up EMPTY on a live store,
and the old trees stay as orphan pages.** The engine attaches an index it has
no catalogue record for with an empty root and maps nothing that was already
there, so every read through it answers nothing -- and a `forget` through it
deletes nothing, leaving the rows live and invisible. `cocolog vacuum` right
after the restart, before any base is touched: its TRUNCATE rebuilds every
index from the live rows. (Learned changing `cocolog::clauses` from two
single-column indexes to the composite `(kb, name)`.)

**A PAGE and a PROCEDURE of the same name are ONE compiled object**, and pages
compile last. `cocolog::predicates` was both, so the procedure's `.so` was
silently replaced and every call to it died with `undefined symbol: call`. That
is why the procedures are `predicates_of` and `props_of`. Check
`parsi/03-pages.parsi` before naming anything in `parsi/02-procedures.parsi`.

**A refused forget WAS a disconnected writer's debris — both causes are
fixed in ZiguratIP now, and the story stays here because the diagnosis cost
two sessions.** `lock wait timeout` on every touch of ONE knowledge base —
while every other base answered — meant a transaction nobody would finish
still held its row locks: the server never rolled back a disconnected
connection's transaction (`handle_client` in ZiguratIP's `loadzigurat.cpp`
left its loop with no rollback on any error path, and logged "Transaction
Closed" on the way out regardless), and the pooled thread kept the id
registered as live, so the lazy stale-lock breaker RIGHTLY refused to break
it. A server restart always cleared it — startup recovery rolls staged work
back; a session spent believing the wedge survived restarts and vacuums,
because every diagnostic forget was itself timing out mid-grind and
re-wedging the base it was diagnosing. What made the debris was a client
giving up mid-write, and the one-DELETE `forget_all` invited exactly that:
~10ms a row, ~30s for a 3 200-clause base on a FRESH store (CivV's rung-6
match). Both halves are now fixed at the source — see the section below —
so against a patched server a vanished client's transaction dies with its
connection, the whole-base forget is ONE atomic call again (a brief
predicate-at-a-time chunking of `cmd_forget` lived between diagnosis and
fix, and is retired), and a `lock wait timeout` today means a LIVE
contending writer, or a server old enough to predate the patch.
`test/vacuum.sh` pins forget's contract: count, emptiness with
declarations, idempotence.

### Two findings about ZiguratIP, diagnosed and then APPLIED

Both were first recorded here as proposals while ZiguratIP was frozen; the
owner unfroze it and both landed (MVCCS-cicili/mvccs-lib.cicili and
ziguratip/loadzigurat.cpp):

* **A vanished client's transaction rolls back with its connection.**
  `ConnectionScope`'s destructor — the one place stack unwinding guarantees
  on every way out of a handler, an error reply throwing into a dead stream
  included — now calls `rollback_transaction`. A transaction the client
  committed has nothing staged, so the clean path is a no-op. Verified: a
  20 000-clause consult killed mid-write leaves a clean base and the very
  next forget runs in 43ms where it used to wait its whole lock timeout.
* **One DELETE's unlinks were quadratic in the index value chain, and the
  UNMAP RESUME MARK made them one walk per chain.** `bt_unmap` finds a
  row's index entry by walking the key's value chain from the head — and a
  mass DELETE's i-th row walked past the i−1 entries the same statement had
  already staged dead, at two indexes per clause row. Entries join a chain
  at its HEAD, so any two rows sit in every index's chain in the same
  relative order they were inserted, and a scan deletes in chain order
  whichever index it rides — so each unmap now remembers where it ended,
  per (transaction, index, key), and the next one on that key starts there.
  The mark is a HINT and never an answer: a miss falls back to the head, so
  it can only save work, never lose an entry; and it is transaction-stamped
  because only an address this transaction itself staged dead is pinned
  against TRUNCATE. Measured: the same 3 227-clause whole-base forget went
  from 31s to **1.59s**. The engine's own gauntlet (consumer, contention,
  carryover, ageing) stays green.

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
  `modules/tcp/tcp.cicili` ended up written in raw C escapes for a day.
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

## Two tiers of library, and which one a thing belongs in

**TIER 1 — always present. No `use_module` needed, and none of it is
optional.** Registered before the first goal runs:

    apply  builtins  dcg  files  library  lists  zigurat
    assoc  pairs  ordsets  yall  aggregate  ugraphs  dcg_basics  dcg_high_order

The first row is Cicili modules compiled into the binary; the second is
SWI's own libraries, vendored in `lib/swipl` under their own BSD-2
headers and read from disk beside the binary at start-up by
`coco_library_preload`. **They are part of Prolog, not an optional
extra** — a program that must say `use_module(library(assoc))` before it
can use an association list is doing the interpreter's bookkeeping.
`use_module` on any of them still succeeds, at once, because a registered
module answers the call for nothing.

It is a load rather than an autoload because it MEASURED free: 469ms bare
against 459ms with all eight, then 441/446, then 458/443 — inside the
noise of a start-up dominated by the embedded store and libtorch. A
missing `lib/swipl` is not an error; the binary still boots.

**SO A `use_module` FOR ANY OF THEM IS A DIRECTIVE THAT DOES NOTHING**,
and none is written anywhere in this repository or in The Coco. It reads
like a dependency and is not one; the first two libraries here already
knew it (neither `http.pl` nor `httpd.pl` imports `lists`) and 26 lines
written out of habit for another Prolog have been removed — three in
`library/json.pl`, `xml.pl` and `html.pl`, eight in
`test/zigurat-lib.sh`, and 23 across The Coco. The list to check against
is the two rows above, and it can be checked rather than remembered:

```sh
D=$(mktemp -d); cp cocolog "$D/"          # a binary with no library/ beside it
COCOLOG_LIBRARY="$D/none" "$D/cocolog" query "use_module(library(lists)), write(yes), nl"
```

Answering `yes` from a directory with no library path at all is what
compiled-in means. Three places legitimately keep such a directive and
each says why in the file: `test/files/*.pl` and
`emacs/test/conformance.pl` are run by **swipl as well**, where the
import is required; and `test/library.sh` is the case that checks
`use_module` on a registered module succeeds at once.

**It measured free LOCALLY and cost 272 HTTP round trips over Zeytun**,
and finding out why paid for itself. `coco_assert` fetched the shared
predicate before adding each clause — *muted clauses included*. A module's
clause never writes through, so it has nothing to be appended to and
nothing to read first; `kb.cicili` now skips the fetch while the store is
muted. One `edge_fact(X)` through a Zeytun edge went from **440 requests
and 91.4 seconds to one request and 447ms** — and 168 of those requests
predated the vendored libraries entirely, from the Coco halves of the
modules compiled in. The lesson is the one in "Where things are" below,
arrived at the expensive way: **a start-up cost is not a cost until you
have measured it in the arrangement where a predicate is a page.**

**TIER 2 — on the library path, loaded when asked.**
`$COCOLOG_LIBRARY` (colon-separated), then `./library`, then
`<exedir>/library`, then `<exedir>/lib/swipl`:

| | |
|---|---|
| `library/*.pl` | clauses only — `http.pl`, HTTP/1.1 as a grammar; `httpd.pl`, a server whose pages are clauses; `json.pl`, `xml.pl`, `html.pl`, a term as a document; `ca.pl`, a certificate authority as rules; `kbs.pl`, many knowledge bases from one script -- every kb_* goal a process-proof over the wire, goals as terms |
| `library/*.so` | a Cicili module against `lib/sdk.cicili`, dlopen'd — built from `modules/` |

**`$COCOLOG_LIBRARY` IS A LIST, AND THE SUITE APPENDS TO IT RATHER THAN
REPLACING IT.** `test/library-path.sh` is the one place that sets it —
sourced by the ten cases that need a tier-2 library — and it puts this
checkout's `library/` at the FRONT and keeps whatever the caller had behind
it. Ours first so a suite cannot go green about somebody else's `httpd.pl`;
theirs kept because ten cases used to write `export
COCOLOG_LIBRARY="$ROOT/library"` and every one of them threw away a path
somebody had exported on purpose. So `COCOLOG_LIBRARY=/opt/my/modules sh
test/run.sh` now works. The Coco's `test/config.sh` does the same, and is
the one variable in that file which appends instead of deferring to the
environment — the two directories it names are not a default anybody could
have meant to replace.

**`modules/` IS WHERE A LOADABLE MODULE LIVES**, one directory each, all
the same shape: a `.cicili`, a `build.sh`, and output nobody commits.

| | needs | build |
|---|---|---|
| `modules/tcp` | nothing | `sh modules/tcp/build.sh` |
| `modules/thread` | nothing | `sh modules/thread/build.sh` |
| `modules/process` | nothing | `sh modules/process/build.sh` |
| `modules/text` | nothing | `sh modules/text/build.sh` |
| `modules/os` | nothing | `sh modules/os/build.sh` |
| `modules/curl` | libcurl | `sh modules/curl/build.sh` |
| `modules/bigint` | a **built** ZiguratIP | `sh modules/bigint/build.sh` |
| `modules/torch` | libtorch | `sh modules/torch/build.sh` |
| `modules/sha` | a **built** ZiguratIP | `sh modules/sha/build.sh` |
| `modules/aes` | a **built** ZiguratIP | `sh modules/aes/build.sh` |
| `modules/der` | a **built** ZiguratIP | `sh modules/der/build.sh` |
| `modules/x509` | a **built** ZiguratIP | `sh modules/x509/build.sh` |
| `modules/tls` | a **built** ZiguratIP | `sh modules/tls/build.sh` |

`make modules` builds every one that can be built here and says SKIPPED,
by name, for the rest. **None of them is part of `make`** — which is the
point: a cocolog with no libtorch, no ZiguratIP headers and no libcurl
still builds and still runs.

**A thing belongs in tier 2 when its dependency should not be
everybody's**, and that argument ate three modules that used to be tier 1.
tcp was swept into `cocolog.c` by the Makefile's wildcard; torch and
bigint were objects in the link reached through weak symbols, so **every
link needed libtorch and libCore** for two modules most programs never
call. The binary went from 936 KB to **585 KB** and `ldd` now shows no
torch at all. What is left of its C++ dependency is the embedded store,
which genuinely is part of the binary.

**The conversion is small and the same every time.** `coco-defmodule` —
which names an entry point the composition root calls — becomes
`coco-deflibrary`, or for the two C++ ones a hand-written
`coco_library_entry` **inside their `extern "C"` block**, because a
mangled entry point is one `dlsym` will not find. A loadable module holds
the engine as an OPAQUE pointer, so `(coco_new_int (-> e m) V)` — reaching
through the engine for its machine — becomes `(coco_m_new_int e V)`. And
the target names its own headers, instead of borrowing `cocolog.cicili`'s.

**Two things bite.** A file compiled ON ITS OWN must have no `DEFPACKAGE`:
it expands to an `EVAL-WHEN` that Cicili then reads as a Cicili form, and
the error is `unknown symbol: EVAL-WHEN`, which names the expansion and
not the cause. And **every `.pl` that calls a moved predicate now needs
the directive** — 27 tutorials, the coworkers, and the heredocs inside the
tests. `tensor_*` belongs to torch as much as `torch_*` does, which a
sweep looking only for the latter will miss.

**WHAT A `build.sh` MAKES IS NEVER COMMITTED**, and every module
directory here is the same shape: a `.cicili`, a `build.sh`, and output.
Output is the `.o`, the `.so`, the C or C++ Cicili generates, *and the
symlinks* — `modules/curl/sdk.cicili` points inside this checkout,
`modules/bigint/zigheaders` inside ZiguratIP's, and both dangle in anyone
else's clone. Five such files were tracked and are not now.

The mistake is easy because the output sits beside the sources —
`library/` holds `http.pl`, which *is* source — and because a transpile
is deterministic, so a stale artifact never looks stale. `make clean`
had been deleting two of these tracked files for a while, which means a
clean clone could dirty its own tree by cleaning.

**The test is to delete everything a `build.sh` makes and run it.** What
comes back was output; what does not was source. Both times it was worth
doing: `modules/curl/` came back with an implicitly declared `toupper`,
because nothing had ever compiled that file without a stale `curl.c`
beside it, and `modules/bigint/` came back byte for byte.

**THE PATH IS ANCHORED TO THE BINARY, not to the working directory**, and
that was a bug worth naming. `./library` finds what shipped only when
cocolog is run from its own checkout — an installed one, or one invoked
from a project directory, could not load its own libraries. And it was
not merely unhelpful: `./library` is a directory somebody else may
control, so a cocolog run inside an untrusted tree would prefer THEIR
`library(lists)` to its own. `/proc/self/exe` is the kernel's exact
answer to "which file am I" — no argv[0] guessing, correct through
symlinks. The caller's `$COCOLOG_LIBRARY` still comes first, because an
override that cannot override is not one.

## The three document libraries, and the rules they share

`library(json)`, `library(xml)` and `library(html)` go both ways: a term
out as a document, a document back in as a term. All six halves are DCGs,
all three answer **codes** when writing (an atom is a C string and stops
at the first NUL; codes are what `tcp_write/2` wants), and all three take
**codes or an atom** when reading.

| | write | read |
|---|---|---|
| the whole thing | `json_codes/2,3` `xml_codes/2,3` `html_codes/2,3` | `json_parse/2,3` `xml_parse/2,3` `html_parse/2,3` |
| as an atom | `json_atom/2,3` `xml_atom/2,3` `html_atom/2,3` | — the readers take an atom |
| to the output | `json_write/1,2` `xml_write/1,2` `html_write/1,2` | — |
| in your own grammar | `json_value//1` `xml_content//1` `html_content//1` | `json_input//1` `xml_input//1` `html_input//1` |

**THE ROUND TRIP IS THE REAL TEST.** Write a document, read it, write it
again, compare the two texts — a reader and a writer that disagree about
the same bytes are worse than either alone, and no amount of hand-written
expectations on each half finds a disagreement between them. Six cases in
`test/serialize.sh` do exactly that.

`html.pl` stands on `xml.pl` by NAME — `xml_escaped//1`,
`xml_text_codes/2`, `xml_no_nul/2` — rather than by copy. One namespace is
the reason that works, and a private copy of an escaper is how two
escapers end up disagreeing about the apostrophe. **The UTF-8 encoder IS
copied**, three times, and the distinction is the point: an escaper
encodes a POLICY, which drifts; RFC 3629 is a fixed transform, which
cannot, and copying it is what lets `json.pl` stand alone rather than
importing a markup library to read a `\uXXXX`.

**A CODE LIST IS A LIST, IN ALL THREE, and `str/1` is the way out.**
cocolog has no string type — `double_quotes` is `codes`, so `"hello"` IS
`[104,101,…]` — and a serialiser that guessed would turn a JSON array of
byte values into a word, or `element(p,[],["hello"])` into
`<p>104101108108111</p>`. That second one is not hypothetical: it is what
`xml.pl` did before the rule, and the case is in the suite. So a bare list
is an array (JSON) or an error (XML, HTML), and `str(X)` is how you say
you meant text.

**THEY THROW RATHER THAN GUESS.** An unbound variable is not `null`;
`foo(1)` is not `"foo(1)"`; `@(maybe)` is not a literal; `<br>text</br>`
is not markup. Every refusal names the term, because the alternative is a
document that parses into something else three days later.

Five places where they deliberately differ from each other, each because
the LANGUAGES differ:

* **`<br/>` vs `<br>`.** XML self-closes an empty element; HTML's void
  elements close by being themselves, and giving one children is an error.
* **`--` in a comment.** XML 1.0 forbids it outright with no escape, so
  `xml.pl` refuses; HTML5's tokenizer ends on `-->` and nothing else, so
  `html.pl` allows `--` and refuses `-->`.
* **`indent(N)`.** `xml.pl` has it and indents only element-only content,
  because a whitespace node between elements is what a schema-aware reader
  ignores and a text child makes the content *mixed*. `html.pl` has NO
  indent option: whitespace between two inline elements is a rendered
  space, so an indenter there would be a renderer that quietly edits.
* **An unknown entity.** `xml.pl` refuses it — XML declares entities in a
  DTD and an undeclared one is an error the spec names. `html.pl` leaves
  it as text, because HTML's table has two thousand names and a browser
  leaves anything not in it alone. That is what makes `AT&T` render as
  `AT&T`.
* **The shape that comes back.** `xml_parse/2` answers ONE element
  because XML requires exactly one root; `html_parse/2` answers a LIST
  because HTML does not — and a list is what `html_codes/2` takes at the
  top, so the two compose with no wrapper.

**The one security-shaped check in the three is `</script`**, in any case,
inside a `script` or `style` element — where escaping is not the answer,
because `a < b` must reach the JavaScript parser as `a < b`. That is also
why `json.pl` does not escape the solidus: the hazard lives at the
embedding, and it is caught there, by name. The parser is the other half
of the same rule: it reads a script verbatim to the matching end tag, so
what the writer refused to emit is exactly what would have broken the read.

**THERE IS NO DTD, AND THAT IS THE XXE ANSWER.** `xml.pl` skips the
DOCTYPE — internal subset and all — and has no code that could open a
file or a socket, so the whole external-entity family is structurally
impossible rather than defended against. An entity a DOCTYPE declared is
therefore never defined and `&whatever;` is an error naming it, which is
the honest answer: the parser cannot know what it expands to.

**`html.pl` IS NOT AN HTML5 TREE BUILDER**, and its header says so at
length. It handles void elements, raw text, optional end tags,
case-insensitive names, unquoted and bare attributes, a `<` that begins
no tag, and misnested end tags. It does NOT do implied
`<html>`/`<head>`/`<body>`, foster parenting, or the adoption agency. A
half tree builder is worse than none, because it produces a tree that
looks right and quietly is not the one a browser built.

**CSS PARSES IN `html.pl` TOO — `css_parse/2`, `css_declarations/2`,
and the writers `css_codes/atom/write` — because CSS lives inside HTML
twice**: a `<style>` element's raw text and a `style="..."` attribute,
both exactly what `html_parse/2` just handed you. A stylesheet is a
list of `rule(Selectors, Decls)` and `at/2,3` terms; `!important`
surfaces as `important(Value)`; properties fold to lower case except
case-sensitive `--custom` ones; and the scanner respects strings,
parens and brackets, so a `;` inside `url(...)` is content. It is NOT
a value parser or a selector-tree builder (a value and a selector come
back as the atoms they were written as, stated in the header), and it
throws rather than guesses in both directions — the writer checks with
the reader's own scanner, so nothing it emits reparses as a different
stylesheet. Round trips in `test/serialize.sh`, lesson in tutorial 14.

## ZiguratIP's cryptography, imported rather than rewritten

Four modules and one Prolog library, all tier 2, all with prefixes of
their own — nothing is called `zigurat_anything`:

| | is | links |
|---|---|---|
| `library(sha)` | `sha_hash/3`, `sha_hmac/4`, `sha_file/3` — SHA-1/224/256/384/512 | libCryptography |
| `library(aes)` | `aes_encrypt/4` (CBC), `aes_pad/2`, PKCS #7 | libCryptography |
| `library(der)` | `der_encode/2`, `der_decode/2` — DER as terms, both ways | **libEncoding only** |
| `library(x509)` | the whole `ca` tool: keygen, csr, issue, validate, sign, verify, encrypt, decrypt | libCryptography |
| `library(ca)` | clauses only: trusted roots, enrolment, and authorisation as a RULE | — |
| `library(tls)` | `library(tcp)` with a handshake in front of it | libSocketIO |

**THE SPLIT IS ARITHMETIC / GRAMMAR / POLICY**, and it is the answer to
"import it or write it in DCG":

* **Arithmetic is bound, never rewritten.** RSA modexp, AES rounds, the
  SHA compression function. A Prolog implementation is not merely slow,
  it cannot be made constant-time, so a private-key operation would leak
  by timing. There is no hash or cipher code in any of these files.
* **Grammar is Prolog.** `library(der)`'s C++ half knows ONE tag-length-value;
  walking a sequence of them is a two-clause recursion, and it is written
  as one. Note where the C++ gave up: `x509.cpp` reaches for OpenSSL's
  ASN.1 rather than hand-rolling DER.
* **Policy is clauses.** `ca_may/2` and `ca_covers/2` are four lines you
  can read, `listing/1` and argue with. That is the part that is better
  here than in any C++ stack.

**`library(der)` LINKS NO CIPHER**, which is worth stating: `Zigurat::DER`
lives in libEncoding beside base16/32/64, so everything a certificate is
made of can be taken apart with no OpenSSL in the process.

**KEYS ARE FILES, NOT TERMS**, and that is the one design decision to
preserve. A private key read into an atom would be on the heap, in the
trail, in every copy a channel made of the term holding it, and in the
knowledge base the moment anything asserted it. This project's whole
claim is that a clause is a row somebody else can read; a signing key is
the one thing that must never become one. `getenv/2` is how a pass
phrase arrives, for the same reason.

### Five things that cost time here, all recorded

* **A `:cpp #t` target must declare the SDK's prototypes RAW, inside
  `extern "C"`, before `(coco-sdk)`.** Otherwise C++ gives them C++
  linkage, the `.so` links cleanly, and `use_module` fails with
  `undefined symbol: _Z11coco_m_textP18coco_engine_opaquemPcm` — a
  mangled name for a function the interpreter exports unmangled.
  **Wrapping `(coco-sdk)` in `(extern-c ...)` is NOT the fix**: a macro
  must emit ONE form, and several leaves every symbol unregistered, so
  the next reference is `unknown symbol: coco_m_domain_error`.
* **`$`-prefixed predicate names must be QUOTED in a module's Prolog
  half.** `$` is a symbol character and `x` is alphanumeric, so
  `$x509_issue` is two tokens and the clause will not read — surfacing
  as `use_module: its clauses would not consult`, which names the module
  and not the line. `lib/builtins.cicili` writes `'$cp_member'`.
* **Which library a symbol is in is not guessable, and a miss LINKS
  FINE.** `DER::encode_oid` is in libEncoding, not libCore; a shared
  object may leave a symbol undefined, so it surfaced at `use_module`.
  `nm -D --defined-only` over `home/lib` settles it.
* **Name every transitive dependency.** `-rpath` applies to what THIS
  link records as needed; libCryptography's own libConfiguration is
  looked for on the system path. `libConfiguration.so: cannot open
  shared object file`, at `use_module`, from a link that succeeded.
* **`X509::issue`'s issuer argument is a NAME CONFIGURATION, not a
  certificate.** Handing it the issuer's `.crt` fails deep inside the
  configuration parser with `key error at line 1, '0\x82\x03...'` — a
  message about a config file, naming DER bytes, from a certificate
  routine. `ca/main_ca.cpp` documents `--issuer` as "issuer name
  configuration file".

### Four transports, spelled out

The arrangement a run uses is now named rather than inferred:

| | is | default port |
|---|---|---|
| `--tcp [PORT]` | the binary protocol, in the clear | 2160 |
| `--tls [PORT]` | the binary protocol over TLS | **2160** |
| `--http [PORT]` | Zeytun, plain HTTP | 80 |
| `--https [PORT]` | Zeytun over TLS | 443 |

**`--tls` KEEPS THE PORT AND `--https` CHANGES IT**, and the asymmetry is
ZiguratIP's rather than ours: `SERVER/TLS_MODE: TRUE` changes *what is
on* 2160, while 80 and 443 are two different ports. Read
`home/etc/ziguratip.conf` before assuming either.

**A CLIENT CERTIFICATE IS OPTIONAL, AND MANDATORY FOR PERMISSIONS.** Both,
and they are not in tension. `loadzigurat.cpp` accepts REQUIRED (the
default), OPTIONAL and NONE for `SERVER/TLS_CLIENT_AUTH`, and
`require_security()` demands only the SERVER's own certificate, key and
authority — so `--tls` with nothing but `--cacert` is a real arrangement.

What a certificate is *required* for is `SECURITY/PERMISSIONS_MODE`.
`zigurat_tls_handler` calls `Globals::set_peer(...)` for **every** TLS
peer, certificate or not, and `Globals::permits` opens with
`if (!_identified) return true;` — the header says it outright:
"Unidentified means a plain connection, where there is no peer to ask
about and everything is allowed — turning TLS on is what turns access
control on."

| connection | `PERMISSIONS_MODE: TRUE` reaches |
|---|---|
| plain | everything — unidentified |
| TLS, no client certificate | **nothing** — identified, empty subject, empty permissions |
| TLS with one | what the certificate grants |

That is the same permission list `library(ca)` reads out of a
certificate, on the other side of the same seam.

**A MISSING CLIENT CERTIFICATE IS NOT A FAILED HANDSHAKE.** Under TLS 1.3
the server does not examine what the client sent until the client has
finished talking, so `SSL_connect` SUCCEEDS and the refusal arrives as an
alert on the first read. `client/tls.c` keeps the reason in the handle
and `coco_client_tls_why` hands it back, so the client says
`read failed: tlsv13 alert certificate required -- this server wants a
client certificate: --cert and --key` rather than `read failed: Success`.
Every test that asserts a TLS-1.3 refusal must check what the peer
*reaches*, never whether the connect returned.

**`--port` IS DEPRECATED**, and still accepted: it is exactly `--tcp
PORT`. It named a number when there was one transport. Nothing warns —
the flag is a spelling, not a mistake, and a line on stderr every run
would land in the output of every script that pipes cocolog — and
nothing in this tree spells it any more. `test/zigurat-lib.sh` holds it
to both halves: that it still reaches the server, and that it says
nothing on stderr.

**`--tls` and `--https` together are refused**: one names a Zigurat and
the other a Zeytun, and a run reaches one knowledge base.

**One TLS unit, `client/tls.c`, for both clients**, because a handshake
is a handshake — and its functions are `coco_client_tls_*` rather than
`coco_tls_*` because `library(tls)`'s module already owns the latter and
both live in one process when a cocolog serves and queries at once.

### `--https`, and two bugs it uncovered in the arrangement it joined

The Zeytun client speaks TLS: `--https [PORT]` (443 by default) beside
`--http [PORT]` (80), with `--cacert`, `--capath`, `--cert`, `--key`,
`--key-pass` and `--insecure`. Both ports are now OPTIONAL, the way
`--embed`'s directory is — a querier behind Cloudflare should not have to
know what port an edge listens on.

**The TLS is in `client/tls.c` and nowhere else.** `zeytun.c` is
still libc and the sockets API: it reaches OpenSSL through six functions
behind an opaque pointer, and a build without OpenSSL compiles that
file's stub half so `--https` reports the missing feature by name rather
than failing to link. The Makefile probes for `<openssl/ssl.h>` and
defines `COCO_ZT_TLS` when it is there.

**The hostname is checked, not just the chain**, and that is the check a
hand-rolled client forgets: a certificate valid for somebody else is
exactly what a man in the middle presents.
`X509_VERIFY_PARAM_set1_host` is the instruction, and SNI takes the same
name — one decision rather than two.

**TWO REAL BUGS FELL OUT, both older than this change:**

* **`--http` dialled the binary server as well.** `open_connection` had
  no Zeytun branch, so a Zeytun run opened a connection on 2160 that it
  never used — and a querier that could only reach the HTTP edge got
  `no server at NAME:2160`. Which defeats the entire point of the
  tunnel. **It went unnoticed because the suite always has a server**:
  `test/tunnel.sh` raises its edge stand-in on localhost, where 2160 is
  answering too, so the extra connection succeeded and paid for nothing.
* **A failed Zeytun fetch was SILENT.** `coco_zt_fail` put the reason in
  `z->err` and answered 0, which the engine reads as "this predicate has
  no clauses" — so an unreachable edge, a refused certificate and an
  empty knowledge base were all `existence_error(procedure, p/1)`. That
  is unacceptable for a verification failure in particular: the whole
  purpose of checking a server's name is to REFUSE, and a refusal a
  reader cannot tell from an empty database is not one. It now prints
  `cocolog: Zeytun at HOST:PORT -- ...` on stderr. Only transport and
  HTTP errors reach it; a predicate with no clauses is a 200 with an
  empty body.

`test/tunnel.sh` gains a TLS-terminating edge stand-in — the arrangement
Cloudflare actually is — and checks a query through it, `--insecure`
going through loudly, and a **second** edge presenting a certificate for
a name nobody asked for, refused with `hostname mismatch`.

### `library(tls)`, and the objection that was wrong

**"cocolog has no stream layer" was the wrong reason not to bind TLS**,
and it is worth recording because it was written down here as settled.
`Zigurat::tlsstream` is a C++ iostream and there is genuinely nothing in
cocolog to hand one to — but nothing has to be. **The stream stays in
the module for its whole life and what crosses into Prolog is an INDEX
into a table**, which is exactly what `library(tcp)` does with a
descriptor. A TLS connection is no more a term than a socket is.

So `modules/tls` is `modules/tcp`'s shape: `Entry g_slots[256]`, each
either a listener or a connection, and a handle is a slot. An integer
this module did not hand out is not a connection — which is the
difference between a failed call and a closed stdout.

**The socket is ours in both directions**, and that is deliberate:
`coco_tls_connect` does `getaddrinfo`/`socket`/`connect` by hand rather
than using `tlsstream`'s host/service constructor, because owning the
descriptor is what lets `tls_read/4` put `SO_RCVTIMEO` on it. A
connection whose fd lives inside somebody else's stream can be waited on
for ever.

**`tls_read/4` is at-least-one-byte, at-most-max.** `peek()` blocks
until something arrives, `in_avail()` then says how much came with it.
A blocking `read(buf, max)` waits for ALL of max, so a reader asking for
4096 bytes of a 20-byte request never returns.

**Every refusal FAILS rather than raising** — a stranger, a certificate
this authority did not sign, and nobody arriving inside the timeout
alike, with `tls_why/1` to tell them apart. A server that raised would
stop serving everybody else because one impostor knocked.

**What the handshake answers is the interesting part.**
`tls_peer_subject/2` and `tls_peer_permissions/2` are settled during the
handshake, against the authority, before a byte moves — so a server does
not authenticate its peer and what is left is authorisation, which is a
`library(ca)` rule.

**`library(httpd)` DOES HTTPS NOW**, and only the transport changed. A
connection became a TAGGED TERM — `plain(S)` or `secure(S)`, a listener
carrying its credentials as `secure(S, Creds)` — and five predicates
dispatch on the tag: `httpd_sock_listen/3`, `_accept/4`, `_read/4`,
`_write/2`, `_close/1`. Routing, keep-alive, the path rules and
`httpd_answer/3` are the same code on both, which is the point of doing
it as a term rather than a flag: HTTPS cannot drift away from HTTP by
being maintained separately.

    httpd_serve(9443, [ tls([ certificate('node.crt'),
                              key('node.key'),
                              authority('ca.crt') ]),
                        workers(4) ]).

**The tag survives a channel**, so the worker pool is unchanged: a
channel copies in canonical text and `conn(secure(7))` reads back on
another machine exactly as `conn(7)` did.

**THE PEER'S IDENTITY REACHES A PAGE AS TWO SYNTHETIC HEADERS** —
`Tls-Peer-Subject` and `Tls-Peer-Permissions` — so a page reads them with
`http_header/3` like any other and needs no new predicate and no access
to the socket. `httpd_answer/3` stays a request in and bytes out, which
is what lets `test/httpd.sh` check every routing rule with no port open.

**THEY ARE STRIPPED FROM THE CLIENT'S REQUEST FIRST, on both
transports.** A client may send any header it likes; a server that merely
ADDED its own would leave two, with the client's first — which is the one
`http_header/3` finds. That is the standard reverse-proxy hole. On a
plain connection they are stripped and NOT replaced, so a page that
trusts them is closed to port 80 by construction. Both halves are in
`test/httpd-tls.sh`.

**`current_predicate/1` IS NOT AN AVAILABILITY PROBE**, and it cost a
debugging round here: it answers about the KNOWLEDGE BASE, and a
module's predicates are not clauses in it — so it says no for a library
that is loaded and working. The probe that replaced it, a call with a
throwaway port, raised `domain_error(port_number, 0)` from the library
that WAS there. The answer is to catch `existence_error` around the real
call and rethrow it with the build hint.

### And one finding about ZiguratIP, not applied

`x509.hpp` says `certificate_public_key` "yields a DER
SubjectPublicKeyInfo, the same shape the .pub files hold". It yields the
SPKI's **contents**: 289 bytes against `dont-use-public.key`'s 293,
which is exactly a four-byte `30 82 01 21` header. `der_wrap(48, K, S)`
puts it back. Documented in `modules/x509/x509.cicili` and in
`tutorials/library/26-x509.pl`; ZiguratIP is not patched for it.

## The engine was quadratic, and the fix is one call

**`coco_make` now dereferences every argument as it stores it**, in
`lib/term.cicili`. That one call is the difference between a linear
interpreter and a quadratic one, and it is worth knowing why.

An argument is kept as a REF cell pointing at the index it was given —
and `coco_arg` hands back a REF. So every structure built on a previous
one added a link, and **the continuation is exactly that**:
`$k(Goal, Barrier, Rest)` built on the `Rest` taken out of the last one.
A recursion 3 000 deep left a REF chain **8 999 links long**, and
`coco_deref` walked it on every engine step.

It was invisible until counted. `callgrind` put **85% of all instructions
in `coco_deref`**; an instrumented build showed 27 million hops with a
longest chain of 8 999. With the deref the longest is **2**.

| | before | after |
|---|---|---|
| `between(1,20000,_), fail` | 15 529 ms | **51 ms** |
| `findall` over 20 000 | 9 167 ms | **53 ms** |
| `between(1,100000,_), fail` | never finished | **226 ms** |
| naive reverse of 700 | 178 ms | 182 ms (noise) |

So it is enormous for deep recursion that backtracks, and free everywhere
else. `test/engine.sh` guards it with a **timeout at a hundred-fold
margin**, not a stopwatch with a threshold — the latter fails on a loaded
machine, and this property is coarse enough not to need the precision.

**Why deref-at-build is safe**, since it is the obvious worry: an argument
that is a bound variable gets stored as what it is bound *to*, and an undo
would put the variable back while the cell still pointed at the value. But
a cell built after a binding lives above that choice point's `heap_mark`,
and `coco_backtrack` sets `heap_len` back to the mark — so anything that
could see the stale value has already been dropped. It is the invariant the
WAM builds on, and the reason it dereferences into a structure too.

## Concurrency: share nothing, copy the term

`library(thread)` is threads and channels, and the shape is the one the
`swarm` command already had: **a thread gets its own machine, store and
engine.** A cocolog machine is an unguarded heap, a trail and an atom
table; two threads proving goals on one would corrupt it in a millisecond,
and locking at that level would be neither correct nor fast.

**So a channel copies**, in canonical text — the same form the database
stores clauses in, quoted and with operators ignored, so a term reads back
on a machine that never ran the same `op/3`. Two machines cannot share a
heap cell, so a term crossing between them is copied whatever the
mechanism; text is the copy this interpreter already trusts.

**What a thread can see, in one line each:**

- **every registered module** — linked-in ones, and anything `use_module`
  loaded *before* it started. The registry is process-wide and a fresh
  store consults all of it on the first goal.
- **nothing the parent asserted.** A thread's store starts empty, and it
  has no database connection — `db` is thread-local and null on a new
  thread, so a thread is a `--local` proof whatever the parent was.

**Register your modules before you spawn.** `use_module` writes the
process-wide registry, and a thread reading it while another writes is the
one unguarded thing there — unguarded because loading libraries at start-up
is what every program does, and a lock would sit on the first goal of every
proof in the process.

`coco_m_run_isolated` in `lib/module.cicili` is the seam: the engine's
lifetime belongs to the interpreter, pthreads and queues belong to the
module. A module *cannot* write it — `coco_engine` is opaque to anything
built against `lib/sdk.cicili`, so a module cannot declare one, let alone
stack-allocate the three a proof needs.

**`library(httpd)`'s `workers(N)` is what it is for.** One thread accepts
and posts connections down a channel; N workers each take one and hold it
for the whole conversation, keep-alive included. That split is the design:
accepting is the one thing that *must* be serialised — `library(tcp)`
hands out handle-table slots and nothing guards the allocation — and it is
also the one thing that costs nothing.

**A handle crosses threads because it is not a descriptor.** `coco_t_fd[256]`
is file-scope in tcp's `.so`, so a handle is an index into a table the whole
*process* shares. Only the accepting thread allocates; a worker uses one and
closes it.

**Measured**: one slow page 372 ms; four of them at once, one connection at
a time, **1 365 ms**; the same four through four workers, **419 ms**. The
pool is not faster at one request — it is what stops one slow request
holding every other client, which is what the keep-alive note called the
real exposure.

**A WORKER HAS THE DATABASE NOW**, and `coco_m_kb_install` in
`lib/module.cicili` is the seam that gave it one. `lib/module.cicili` can
make a machine and a store but cannot know whether this process is
`--local`, a socket, Zeytun or embedded — the composition root can, so it
installs a pair of hooks and every isolated proof opens a connection of its
own. One per thread, which is the `swarm` command's rule and the only one
that works. Connections NEST: the previous one is saved and restored, which
is what lets a worker hold one while each request opens another.

**EACH REQUEST IS ITS OWN TURN, and that is not a refinement.** A store
CACHES — the first proof to ask for `visit/1` marks the predicate loaded and
never asks again — and the Zigurat backend flushes a dirty predicate
WHOLESALE, so two workers each answering a write hold divergent pictures and
the second commit writes its stale copy over the first. Measured: three
sequential POSTs through a pool of three left **two** facts in the database,
with no concurrency involved at all. So a request runs through
`run_isolated/2`: fresh machine, fresh store, fresh connection, one commit
at the end, a rollback when the goal did not prove.

**WHICH ASKS ONE THING OF THE PROGRAM ABOVE IT, and the failure is a silent
404**: a worker's store is filled from the process-wide MODULE REGISTRY, so
pages must be loaded with `use_module` and not consulted, asserted, or
written into the file handed to `cocolog run`. `workers(0)` serves those
perfectly well, which is exactly how this is easy to meet in a demo and lose
the moment a pool is added. Four cases in `test/httpd.sh` hold both halves.

**Measured**: four threads doing four times the work of one took 1.7× the
time on four cores. Eight senders put 800 terms through one channel and all
800 arrived.

## Where things are

| path | what |
|---|---|
| `lib/term.cicili` | cells, unification, the trail, copying |
| `lib/syntax.cicili` | the reader and the writer, from one operator table, plus the run-time one `op/3` adds |
| `lib/kb.cicili` | the clause store and its five backend hooks |
| `lib/solve.cicili` | the engine and the builtin table |
| `lib/module.cicili` | the module seam and the API a module is written against |
| `lib/files.cicili` | SWI's Files library, as a module — mostly C. Also `get_time/1`, the wall clock, which was simply not there: nothing in cocolog could ask what time it is, so a certificate's validity window had nowhere to come from |
| `modules/tcp/tcp.cicili` | the socket seam: listen, connect, accept, read, write, close. A handle is an index into this module's own table, never a file descriptor |
| `lib/lists.cicili` | SWI's Lists library, as a module — mostly Prolog, because nondeterministic predicates cannot live in a C half |
| `lib/apply.cicili` | SWI's Apply library — clauses only, no C half |
| `lib/builtins.cicili` | the ISO core builtins cocolog was missing, plus `format/1,2,3`, `code_type/2` and `must_be/2`. **No failure-driven loops in here** — every builtin is deterministic, so `G, fail` runs the body once and then stops |
| `lib/dcg.cicili` | `-->` translation, `phrase/2,3`. Two generics: the translator sits BEFORE `kb` because `coco_assert` calls it, the module half after the engine |
| `lib/swipl/` | EIGHT of SWI's libraries — `assoc`, `pairs`, `ordsets`, `yall`, `aggregate`, `ugraphs`, `dcg/basics`, `dcg/high_order` — copied unmodified under their own BSD-2 headers and read at start-up. Do not edit them — see the README there |
| `lib/library.cicili` | `use_module`: run-time loading of `.pl` and dlopen'd `.so` libraries |
| `lib/sdk.cicili` | the module API over opaque types, for out-of-tree Cicili modules |
| `modules/` | the loadable modules: `tcp`, `thread`, `curl`, `bigint`, `torch`, and ZiguratIP's cryptography — `sha`, `aes`, `der`, `x509`. One directory each — a `.cicili`, a `build.sh`, output nobody commits — and none of them part of `make`. `embed/` is the same shape and is NOT here, because the embedded store really is part of the binary |
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

## The tutorials are documentation that RUNS

`tutorials/` has three categories and `test/tutorials.sh` runs all
seventy-three files as one suite case:

| | | needs |
|---|---|---|
| `tutorials/basics/` | eleven lessons, the language itself | nothing |
| `tutorials/library/` | thirty-seven lessons, one per library that ships | `$COCOLOG_LIBRARY` for tier 2 |
| `tutorials/torch/` | twenty-five networks, three processes each | libtorch |

**EVERY CLAIM IS A `must/3`**, in every basics and library file:

```prolog
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
```

So a lesson that stops being true FAILS, naming both answers, and a
tutorial cannot quietly document a language that has moved on. It is
repeated at the bottom of all forty files rather than shared,
deliberately: a tutorial you can copy anywhere and run is worth six
duplicated lines, and one that needs a support file beside it stops
working the moment it moves.

**Writing them found three real interpreter bugs**, which is the whole
argument for the shape:

* **`once/1` and `ignore/1` did not exist.** They are now CONTROL
  CONSTRUCTS in `lib/solve.cicili`, beside `\+` — `once(G)` is
  `coco_ite(G, $true, $fail)` and `ignore(G)` is `coco_ite(G, $true,
  $true)`. They were Prolog clauses for a day, which is how every
  textbook writes them and is the wrong shape here: a clause costs a
  frame, a `call` and a hand-written cut to say what the engine already
  has a construct for. As if-then-else the goal gets its cut barrier
  FROM THE CONSTRUCT, which is what makes `once/1` opaque to cut the way
  ISO 8.15.2 requires — `once((X > 1, !))` inside a `member/2` leaves
  the outer choice point alone, and there is nothing left to get wrong.
* **`flush_output/0` did not exist.** cocolog writes to the literal
  stdout, which the C library buffers by LINE at a terminal and by BLOCK
  everywhere else — so a program that prints a marker and then blocks
  prints nothing at all into a pipe or a file, and everything at once
  when it exits. Found by `test/tls.sh`: the server printed READY, the
  harness waited for it, and it arrived after the server gave up.
  Interactively it had always worked.
* **`retractall/1` was one clause short of correct.** It was written
  `retractall(H) :- retract(H), fail.` / `retractall(_).` — the classic
  failure-driven loop, and it retracts exactly ONE clause here, because
  **every builtin in cocolog is deterministic** and `retract/1` leaves
  no choice point to fail back into. It is now recursive over
  `copy_term/2`, which is also what keeps a partially-bound head from
  being narrowed by the first match.

That last one is the pattern to watch for anywhere in `lib/`: a
failure-driven loop written from habit against another Prolog is not
slow here, it is wrong, and it is wrong quietly.

**A NEW LIBRARY GETS A TUTORIAL IN THE SAME COMMIT.** `tutorials/library/`
is numbered one per library, so a gap is visible — and a library with no
`NN-name.pl` beside it is one nobody has demonstrated end to end. Each of
the twenty-nine found something while being written: a predicate that
did not exist, an arity that was wrong, `bigint_cmp/3` documented as
`-1/0/1` and actually answering `<`/`=`/`>`, `httpd_content_type/2` keyed
on the bare extension where `httpd_type/2` is the one that takes a file
name.

## modules/ray changes are validated downstream

The owner's rule: a change to modules/ray does NOT require the full
suite here -- run `sh test/ray.sh` (and the tutorial if the surface
changed) and let CivV's own suite exercise it fully, which it does
against real worlds. The full-suite discipline stands for everything
else.

## Before saying something works

Run `make test` with a server up, and read all **40** case lines (counted
from a run, not remembered; this said 39 and the suite has moved). A change to
the knowledge base also wants proving **across processes** — one `cocolog`
invocation writing and a second, which consulted nothing, reading — because
that is the claim the project exists to make and an in-process test cannot make
it.

**COUNT THE SKIPs.** `red: 0` is printed over a run where nothing happened
just as happily as over a real one, and the suite is deliberately built that
way: "no server here" and "the backend is wrong" are different findings, so
the first is never dressed up as the second. Seven cases — `zigurat`,
`shared`, `tunnel`, `tensors`, `zigurat-lib`, `groups`, `ruler` — SKIP
without a server, and `files` SKIPs without `swipl`
(`apt-get install swi-prolog-nox`). **A run that says `red: 0` with eight
SKIPs has not tested the database at all.**

### What macOS gets wrong, and the recipe

A Mac builds the whole family -- clang is native, and every layer came up
clean -- but each of these fails naming something other than its cause,
and every one has cost a session at least an hour:

* **A shared object may not leave the interpreter's symbols undefined,
  and neither may a program that links only the client archive.** Every
  loadable module refers to `coco_module_register` and the rest of the
  SDK, to be found in the cocolog that `dlopen`s it; every test binary
  refers to the TLS entry points and the embedded engine's, declared
  `weak` on Linux so a build without them links and leaves them null.
  Apple's linker says `ld: symbol(s) not found for architecture x86_64`
  to both, naming symbols that plainly exist. Two halves fix it:
  `client/zeytun.h`'s `COCO_WEAK` (and `zigurat.c`'s `CE_WEAK`) are
  `weak_import` on Darwin, and `tools/cc/cc` and `cxx` add
  `-Wl,-undefined,dynamic_lookup` to EVERY link step there -- Mach-O's
  `weak_import` still wants a definition at link time, and only dynamic
  lookup lets the reference stay open and bind to null at load, which is
  the behaviour every caller of those symbols checks for. Once, in the
  wrappers, rather than in every `build.sh` and `:link` list. **And the
  wrappers must be REACHED**: on Darwin Cicili names `clang` outright
  (its config.lisp says so), so `tools/cc` carries `clang` and `clang++`
  shims beside `gcc` and `g++` -- each takes itself off PATH before
  handing over, or the wrapper's `exec clang` would be the shim again --
  and `test/run.sh` sources `tools/cc/env.sh`, which it never had: the
  seven test binaries were built with whatever the bare name resolved
  to, and failed on a Mac beside a `make` that succeeded.
* **Apple's clang 21 defaults to C++14** (`__cplusplus 201402L`) where
  Ubuntu's defaults to gnu++17, and fires `-Wparentheses-equality` on
  the transpiler's `while ((x == 0))` in more places. Under C++14 there
  is no guaranteed copy elision, so ZiguratIP's engine died at `call to
  implicitly-deleted copy constructor of 'Zigurat::filestream'` on a
  line that is correct C++17. Every Cicili target that compiles C++ now
  says `-std=gnu++17` (gnu, for the statement expressions the transpiler
  emits), and every target here carries the `-Wno-` pair -- including
  the seven `test/*.cicili`, which used to inherit whatever the compiler
  felt like. Apple's SDK also marks `sprintf` deprecated, which is a
  warning, which Cicili treats as fatal: `-Wno-deprecated-declarations`
  rides beside it in the C++ targets.
* **There is no `/proc/self/exe`.** `lb_exedir` in `lib/library.cicili`
  asks `_NSGetExecutablePath` + `realpath` under `(@ifdef (code
  "__APPLE__"))` -- note the `code` payload: a bare symbol in an `@ifdef`
  is `unknown symbol: __APPLE__`, and a libc function `lib/std/c` does
  not declare (`_NSGetExecutablePath`, `realpath`) goes through the raw-C
  escape exactly as `files.cicili` reaches `realpath`. The engine now
  answers `current_prolog_flag(executable, P)` -- SWI's flag, and ONLY
  that flag -- and `library(kbs)` and CivV's suite read it instead of
  `/proc/self/exe`, which had failed silently and made every `kb_*` goal
  fail with nothing printed.
* **`make schema` dies inside libc++.** ZiguratIP's `memory.hpp` derives
  from `std::binary_function`, which C++17 removed and Apple's libc++
  actually deletes; the error is `no template named 'binary_function'`
  from the middle of `01-schema.parsi`. ZiguratIP is frozen, so the fix
  is the owner's own `--config` road: copy `home/etc/ziguratip.conf`
  somewhere, append `-D_LIBCPP_ENABLE_CXX17_REMOVED_BINARY_FUNCTION` to
  its `CPP_FLAGS`, and `ZIGURATIP_CONF=that-file make schema` --
  `parsi/build.sh` passes it through. The tracked configuration is
  untouched. ZiguratIP's own `System/` objects and `demo/` compile with
  the home configuration as they are.
* **After ANY engine rebuild, EVERY object in `home/ld` is stale**, and
  the server or `parsi` dies at `dlopen(...): Symbol not found:
  __ZN7Globals11echo_streamEv` -- a symbol the old engine had and the
  new one renamed. `make -C System clean && make -C System`, then each
  `demo/0*.parsi` through `parsi`, then `make schema` here. `nm -u
  home/ld/*.so | grep echo_stream` lists whoever is still behind.
* **The X11 that `xdotool` needs is XQuartz's**, and it ships with the
  XTEST extension off. `brew install xdotool` says so on the way in:
  `defaults write org.x.X11 enable_test_extensions -boolean true`, then
  restart X11. `raylib` for `modules/ray` is `brew install raylib`.
* **A raylib photograph is ONE FRAME BEHIND on macOS**, measured: a red
  frame, then a blue one, photographed, comes back red. After a single
  frame it is black. A program that screenshots draws the same frame
  twice first -- CivV's two renderers do -- and an overlay drawn twice
  had better be idempotent.
* **Ask `library(os)`, not a shell.** `os_is(darwin)`, `os_has(Tool)`,
  `os_lib_path_var(V)`, `os_tmp(T)`, `os_cpus(N)` are the questions the
  suites used to put to `uname`, `command -v`, `$TMPDIR` and `nproc` --
  answered by libc, the same clause on both systems. `modules/os`,
  tutorial 35, `test/os.sh`.
* **No `setsid`, no `LD_LIBRARY_PATH`, no `date +%N`, and `wc` pads.**
  Raise the server with `nohup` in a subshell and `DYLD_LIBRARY_PATH`;
  `timeout` is coreutils' (brew). `test/portable.sh` carries `now_ms`
  (perl's Time::HiRes -- BSD date prints a literal `3N`, and the
  arithmetic after it died with `value too great for base`, which is how
  a timing check came to call parallel threads "serial") and `detach`
  (setsid where it exists, plain elsewhere); `httpd.sh`, `curl.sh` and
  `thread.sh` source it. BSD `wc -c` left-pads its count: `tr -d " "`.
  `library(process)`'s `proc_spawn` calls the syscall and is unaffected.
* **A page that warms a store takes ~4x longer here** -- CivV's `/view`
  measured 12-13s against ~3s on the Linux box -- so a client's first
  read must wait for that, and a server's READY line is printed ~1.4s
  BEFORE its port opens. Wait for the port with `lsof -iTCP:PORT
  -sTCP:LISTEN`, never with a probe connection: `httpd`'s accept loop
  ENDS on a failed accept, and a bare TCP connect to a TLS listener is
  exactly that.

**The suite is 27 of 39 GREEN on a Mac, and the twelve are the tests'
own portability, not the interpreter's.** Every case a downstream
repository stands on is green there -- term syntax solve module state
zigurat shared script library bigint zigurat-lib meter thread process
text kbs curl ray hex astar serialize httpd httpd-tls crypto tls
zigurat-tls tutorials. The twelve that are not, and what each smells of:
`files` and `trace` (a byte-for-byte comparison against this machine's
swipl, which is a different release); `vacuum`, `repl`, `tensors`
(`rm` of a `$TMPDIR` scratch dir that is not empty -- BSD rm); `tunnel`
and `colab` (the Zeytun edge on privileged ports, and GNU tools);
`http` and `tcp` (a second process reaching a first -- `detach` and
timing); `engine` (a timing ratio); `groups` and `ruler` (`vacuum:
read failed: Resource temporarily unavailable` -- a socket read timing
out under a slow vacuum, worth a look of its own). None of them is a
CivV or Coco dependency, and none has been dressed up: read the
per-case lines, as always.

One engine self-test fails on this Mac and passes on Linux --
`contention_test`'s "rewrite vs index" (a writer rewriting one row under
a unique index while readers look it up: `[writer: unique key]` and the
row missing 4 times) -- and the gauntlet aborts the ZiguratIP `make`
after the artefacts are already built. It is a real finding about the
engine on Darwin and it is NOT fixed here; it is recorded for the owner.

### The two things a container gets wrong

Both cost a session time, and neither announces itself:

* **`$HOME` is not where the checkouts are.** Every `build.sh` defaults to
  `${CICILI:-$HOME/cicili}` and `${ZIGURATIP:-$HOME/ZiguratIP}`, which is
  right on a workstation and wrong wherever `$HOME` is `/root` and the
  repositories are somewhere else. Set both explicitly:

      export CICILI=/path/to/cicili ZIGURATIP=/path/to/ZiguratIP

  Getting it wrong fails LOUDLY but far from the cause — a Lisp backtrace
  about `embed/mvccs-lib.cicili` not existing, which is a SYMLINK
  `embed/build.sh` made, pointing wherever `$HOME` was the last time it ran.
  A stale symlink is not repaired by `make`; re-run the script, or delete it.

* **The server needs its own libraries on the path.** Started plainly,
  `ziguratip` dies at once with `libStreamIO.so: cannot open shared object
  file` — and then every database case SKIPs, so the suite still says
  `red: 0`. Raise it as:

      export ZIGURATIP_HOME=/path/to/ZiguratIP/home
      setsid env LD_LIBRARY_PATH="$ZIGURATIP_HOME/lib" \
        "$ZIGURATIP_HOME/bin/ziguratip" > /tmp/zig.log 2>&1 &

  `setsid` because a plain `&` from a tool call does not outlive the turn.
  Then CHECK it before trusting a green line — the answer should be a
  sentence, not a refusal:

      ./cocolog --kb main --host 127.0.0.1 --tcp 2160 --timeout 10 list
