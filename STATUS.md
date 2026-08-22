# Status

Where this stands, what is proven, and what is not. Written to be picked up
again rather than to look finished.

## Done and tested

`make test` ends `red: 0`. The database suites **skip** rather than fail when
there is no server, because "no server here" and "the backend is wrong" are
different findings.

| suite | what it establishes |
|---|---|
| `test/term.cicili` | interning, unification, the trail undoing exactly, copying that renames consistently, the standard order, and the term DSL — 27 checks |
| `test/syntax.cicili` | the reader and the writer against each other: precedence, associativity, the spacing that decides whether `-(1)` reads back as a compound or an integer, lists, curly terms, quoting, radix and character literals — 41 checks |
| `test/solve.cicili` | backtracking, cut, negation, if-then-else, arithmetic, lists, term inspection, assert/retract, a 50000-deep deterministic recursion that must leave no choice points, and a failing goal that must not grow the heap — 57 checks |
| `test/state.cicili` | a machine run to one solution, frozen, its machine and store **freed**, thawed into new ones, and finishing the proof correctly; and `freeze(thaw(x)) == x` byte for byte |
| `test/zigurat.cicili` | the Cicili binding against a real server: every parameter width, a cursor, and a Text large enough to matter |
| `test/shared.cicili` | six interpreters in sequence — one writes the knowledge base, a second built from nothing answers from it, a third suspends mid-proof and is freed, a fourth picks it up and finishes it, a fifth asserts at run time, a sixth sees it. Then the same knowledge base over HTTP, and a machine written over the binary protocol picked up over HTTP — 25 checks |
| `test/groups.sh` | **twelve interpreters at once over four machine states** — below |
| `test/ruler.sh` | **one interpreter writing the knowledge base while eight read it** — below |
| `client/probe.c` | the C client against a real server, including a clause made of nothing but the five HTML-escapable characters, asserted over the binary protocol and read back through a page unchanged |

## Twelve interpreters, four states

`test/groups.sh`. Four groups of three: twelve `cocolog work` processes at once,
each group taking turns on one machine and handing it back and forth through the
database. Every machine produces its full answer set with **no answer twice**,
every member of every group takes turns, and nothing is left suspended.

```
     turns: a1=6 a2=4 a3=7
     turns: b1=4 b2=4 b3=4
     turns: c1=10 c2=10 c3=10
     turns: d1=11 d2=7 d3=12
GREEN: 0 failure(s)
```

Three things had to be right, and each was wrong first.

**The claim has to be SERIALIZABLE.** It is a read followed by a write of the
row it read: find an idle machine, then mark it. At READ COMMITTED — which is
what every other procedure runs at, and rightly — two workers arriving together
both see `suspended`, both take it, and both advance the same state from the same
point. The answers come out twice. It is the one place in cocolog that needs the
strongest level, and ZiguratIP's SERIALIZABLE excludes only other SERIALIZABLE
transactions, so twelve claims queue for microseconds each while the work that
matters — loading, proving, saving — goes on at READ COMMITTED all at once.

**An empty claim means two different things.** The machine is either gone —
proved out and dropped — or busy in a partner, which is the normal state of
affairs and no reason at all to stop. Treating the second as the first made every
machine get finished by whichever worker reached it first.

**And "gone" is not proof the first time you see it.** Saving a machine deletes
its row and inserts a replacement, and the replacement can land at an address the
scan has already passed, so for the length of that transaction a reader sees
neither version. A worker therefore gives up only after the machine has been out
of sight *continuously* for `CO_GONE_CONFIRM` polls — and waits far longer for
one it has never seen at all, because absence before the first sighting means
"not created yet". That is what lets a pool of twelve be started before the work
exists, which is the only way to start twelve without the first few finishing
before the last are running.

That last number is a heuristic and is allowed to be: what it decides is only
**when a worker goes home**. It cannot make two workers advance one machine, lose
a turn, or produce an answer twice. The claim settles all of that exactly.

## One ruler, eight queriers

`test/ruler.sh`. One process asserts a program one clause at a time — rules
first, so that for most of the run there are rules whose facts have not arrived —
while eight others query the same knowledge base against the same server.

The check is deliberately one-sided: **no querier may ever answer anything
outside the finished program's answer set**. A rule that cannot prove anything
yet is not wrong, it is early. Anything else means a querier read a clause that
was never committed, or half of one. The suite also checks that the queriers were
genuinely reading while it was being written — the number of answers has to grow
across the run, or they were only ever reading a finished program and the run
proved nothing about concurrency.

## What had to be fixed in ZiguratIP

cocolog began as a client that modified nothing. Most of what follows was found
by pointing twelve of them at one server, and it is fixed in ZiguratIP itself now
rather than worked around here. See its `doc/concurrency.md`.

* **The B-tree indexes took no lock on the shared page streams.** Two clients
  doing `WHERE indexed_column == value` at once read from each other's file
  position: `hexmap ends inside the chunk at NNNNN`, and often enough a dead
  server and a store to throw away.
* **`TRANSACTION ISOLATION LEVEL` had never compiled.** The generated C++ used
  `->` on a value member, so every procedure carrying the documented clause
  failed to build.
* **An isolation level outlived the transaction that set it**, and with
  SERIALIZABLE that leaked a server-wide semaphore slot — one client did all the
  work and the rest hung.
* **`SERVER/POOL_SIZE` shipped as 5**, which is the most clients that can be
  connected at once. The twelve did not get an error; they got silence until
  their own sockets timed out.

## Known limitations, by choice

* **`--lock` is off by default and should stay off.** It makes cocolog processes
  take turns through a `flock`, one per transaction, which is what a server that
  cannot take concurrent clients needs and is about as concurrent as a queue. It
  is kept for talking to a ZiguratIP without the fixes above.
* **A claim has no lease.** `cocolog::machine_release` puts a machine back, and a
  worker that loses its connection calls it — but one killed outright strands its
  machine as claimed, and only `cocolog drop` clears it. A lease with an expiry
  would want a timestamp column and a clock the server agrees with.
* **The HTTP backend does not write.** One request is one transaction; a machine
  is a header row plus a row per chunk. Stated in `lib/zeytun-kb.cicili` and in
  `parsi/03-pages.parsi`.
* **`consult` asserts, it does not replace.** Consult the same file twice and
  every proof answers everything twice; `cocolog forget` is how a knowledge base
  is emptied.
* **Builtins are all deterministic.** One that could leave a choice point behind
  — `between/3`, `clause/2` — would need the engine's choice stack in its hands.
  They belong in a Prolog-level library instead, which does not yet exist.
* **Resuming assumes the clauses have not moved.** A choice point remembers a
  predicate by name and the position of the next clause to try, so retracting
  from underneath a suspended machine makes it resume at the wrong one. This is
  the hazard `retract` has always had against a running query; the fix is to hold
  a transaction over the clause tables.
* **`asserta` rewrites its whole predicate** in the database, because putting a
  clause at the front changes every later clause's ordinal. O(n) per assert and
  always right.
* **No error terms.** A goal that cannot be run reports through the engine's
  `err` string and stops the query, rather than throwing a Prolog `error/2` a
  program could catch. `catch/3` and `throw/1` are not implemented.
* **No garbage collection.** The heap only grows within a solution; it is
  reclaimed on backtracking and on a new query. A long deterministic run that
  builds structure will grow until it ends.

## Not started

* A REPL. `cocolog query` runs one goal and exits.
* `findall/3`, `bagof/3`, `setof/3`.
* Strings as a type; `"abc"` reads as a code list, which is the ISO default.
* Any indexing on the first argument. A predicate's clauses are tried in order.
