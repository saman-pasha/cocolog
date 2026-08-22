# Working on cocolog

README.md says what cocolog is and STATUS.md what is proven. This says how to
work in here and what will bite you.

## cicili and ZiguratIP are frozen

**Only this repository may be modified.** The other two are inputs.

| repo | role | frozen at |
|---|---|---|
| `../cicili` | the language cocolog is written in; used at BUILD time | `00ca101` |
| `../ZiguratIP` | the database; used at RUN time and by `make schema` | `416b86f` |

No edits, commits, pushes, branch changes or `git add` in either. If a cocolog
problem traces to a bug in the engine or the transpiler, **report it with a
diagnosis and a proposed patch — do not apply it.** Six ZiguratIP engine faults
were found and fixed under an earlier, explicit authorisation; that
authorisation is withdrawn. Ask before assuming a new one.

What the freeze still allows: `make schema` compiles cocolog's OWN Parsi objects
into `$ZIGURATIP_HOME/ld`, and the server writes to `$ZIGURATIP_HOME/data`.
Neither dirties the ZiguratIP repo — `*.so` is gitignored there and `home/data`
has no tracked files — so `git status` in it stays empty. Verify that it does.

## Build and test

```sh
export CICILI=/home/user/cicili                  # a Cicili checkout, for sbcl
export ZIGURATIP_HOME=/home/user/ZiguratIP/home  # a built ZiguratIP home
make            # the C client and the cocolog program
make schema     # compile the Parsi objects into $ZIGURATIP_HOME
make test       # the suite
sh test/run.sh solve      # one case
```

The server, which the database tests need:

```sh
cd /home/user/ZiguratIP && ZIGURATIP_HOME=$PWD/home \
  LD_LIBRARY_PATH=$PWD/home/lib setsid ./home/bin/ziguratip
```

Start it detached. A plain `nohup … &` from a tool call does not survive the
turn, and what you get then is the next hazard.

## Three hazards, each of which has already cost a day

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
* **There is no character literal.** `(co-ch-between c "a" "z")` expands to the
  numeric comparison; write characters through the macros, or as their codes
  with a comment saying which character.
* **A function pointer in a variable is written as a `func` clause in type
  position.** `co_store_reset` in `lib/kb.cicili` is the worked example.

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

## Where things are

| path | what |
|---|---|
| `lib/term.cicili` | cells, unification, the trail, copying |
| `lib/syntax.cicili` | the reader and the writer, from one operator table |
| `lib/kb.cicili` | the clause store and its five backend hooks |
| `lib/solve.cicili` | the engine and the builtin table |
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

Run `make test` with a server up, and check the eight case lines. A change to
the knowledge base also wants proving **across processes** — one `cocolog`
invocation writing and a second, which consulted nothing, reading — because
that is the claim the project exists to make and an in-process test cannot make
it.
