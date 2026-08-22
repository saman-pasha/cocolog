# Status

Where this stands, what is proven, and what is not. Written to be picked up
again rather than to look finished.

## Done and tested

Every suite below ends `GREEN`. The database ones **skip** rather than fail
when there is no server, because "no server here" and "the backend is wrong"
are different findings.

| suite | what it establishes |
|---|---|
| `test/term.cicili` | interning, unification, the trail undoing exactly, copying that renames consistently, the standard order, and the term DSL — 27 checks |
| `test/syntax.cicili` | the reader and the writer against each other: precedence, associativity, the spacing that decides whether `-(1)` reads back as a compound or an integer, lists, curly terms, quoting, radix and character literals — 41 checks |
| `test/solve.cicili` | backtracking, cut, negation, if-then-else, arithmetic, lists, term inspection, assert/retract, a 50000-deep deterministic recursion that must leave no choice points, and a failing goal that must not grow the heap — 57 checks |
| `test/state.cicili` | a machine run to one solution, frozen, its machine and store **freed**, thawed into new ones, and finishing the proof correctly; and `freeze(thaw(x)) == x` byte for byte |
| `test/zigurat.cicili` | the Cicili binding against a real server: every parameter width, a cursor, and a Text large enough to matter |
| `test/shared.cicili` | the whole claim — 25 checks. Six interpreters: one writes the knowledge base, a second built from nothing answers from it, a third suspends mid-proof and is freed, a fourth picks it up and finishes it, a fifth asserts at run time, a sixth sees the assertion. Then the same knowledge base read over HTTP, and a machine written over the binary protocol picked up over HTTP. |
| `test/groups.sh` | **four interpreters at once over two machine states** — see below |
| `client/probe.c` | the C client against a real server, including a clause made of nothing but the five HTML-escapable characters, asserted over the binary protocol and read back through a page unchanged |

## Concurrent writers: what was wrong, and what it took

`test/groups.sh` passes. Two groups of two: four `cocolog work` processes at
once, each group handing one machine back and forth through the database.
Each machine produces its full answer set, in order, **no answer twice**; both
members of each group take turns; nothing is left suspended. Run repeatedly, it
is stable.

Getting there turned up three separate faults, and only one of them was where
it looked.

### 1. A request written field by field wedges the connection

This was the big one, and it was **not** a concurrency bug at all — it needed
only one client.

The client wrote a request a field at a time: a length byte, then the bytes,
then the next type descriptor, each its own `send`. The server reads through a
`std::streambuf` (`SocketIO/socketbuf.cpp`) whose `underflow()` flushes the
replies IT has pending only when it is about to block on the socket. Feed it a
request in fragments and it is never quite about to block: it comes back round
its loop with the next fragment already in its get area, so it does not flush,
and the reply the client is waiting for sits in the server's put buffer. Both
ends then wait for each other, for ever.

Measured: a field-at-a-time client wedges after somewhere between thirty and
ninety calls on one connection, at no fixed point — and never once it is slowed
down enough to lose the race. Under `strace` two thousand calls pass without a
murmur, which is why this looked like a different bug every time it was caught:
a broken pipe here, a `NULL value` there, an empty procedure name in the server
log.

The fix is in `client/zigurat.c`: `wr()` accumulates into a small buffer and
`rd()` flushes it before waiting. One request, one write, one arrival, and the
server goes back to blocking — which is where it flushes. Two thousand calls on
one connection now pass, repeatedly.

### 2. ZiguratIP's storage engine is not safe under concurrent clients

`Memory::transaction` is `static thread_local` (`MVCCS/memory.hpp:203`), so
each connection's thread has its own transaction — but the two streams a
transaction reads and writes through, `_hexmap_io` and `_data_io`, are **one
pair shared by every thread**. `Memory::_pointer` seeks one of them and then
reads it, holding neither of the mutexes `Memory::truncate` takes over the same
streams. Two threads in there at once read from each other's file position.

What comes back is `hexmap ends inside the chunk at NNNNN`. With four clients
it is sometimes worse: the server dies and the store has to be thrown away.
Reproduced with a program that does nothing but claim and release one row —
no interpreter, no machine state, forty lines of C.

**ZiguratIP is not ours to fix.** cocolog uses it and modifies it; so cocolog
stays out of the engine's way instead:

* `zg_serialise` (`client/zigurat.c`) makes a connection take turns with every
  other process on a lock file, via `flock(2)`.
* The turn is **the transaction**, not the call. Releasing per call was tried
  first and is not enough — the server is still finishing with the store after
  the byte that ends a call, and a transaction left open holds rows either way.
  Held across the transaction there is no gap.
* It is on by default, at `${TMPDIR:-/tmp}/cocolog-HOST-PORT.turn`, so
  everything talking to one server queues behind everything else talking to
  that server. `--lock PATH` moves it; `--lock none` turns it off.

With that, four processes doing four hundred claim/release cycles run clean,
repeatedly, and the four-interpreter test passes.

**The limit of it:** `flock` holds between processes on one machine. Workers on
DIFFERENT machines share no such file and are not serialised, and against this
storage engine that is not safe. A lock that spanned hosts would have to live
somewhere both could see — which, for now, would mean the database, which is the
thing that cannot take the concurrency. Single-host worker pools only.

### 3. A worker had no way to recover, and no reason to share

Three smaller things, all in cocolog:

* **A server exception ends the connection**, not just the call —
  `loadzigurat.cpp` writes `EXCEPTION_THROWN` and breaks out of its request
  loop. The client now closes the socket when it sees that byte, so the failure
  is reported once in the right words instead of surfacing as
  `write failed: Broken pipe` several calls later; and `zg_reopen` dials again
  **down the same `zg_conn`**, so every `co_zg` holding the pointer survives the
  recovery.
* **A turn is all or nothing.** `cmd_step` buffers its answers and prints them
  only after the commit lands. A worker that printed as it went and then lost
  its connection would have announced answers that the rolled-back machine is
  going to produce again next turn — and the same answer twice is precisely
  what a suspendable machine exists to avoid. A lost turn is now retried by
  handing the machine back, so the partner may take it.
* **A worker yields after a turn.** Without it the process that has just put a
  machine down picks it straight back up: it is awake and connected and its
  partner is asleep between polls. One worker ran whole machines alone, which
  passes every check about answers and quietly fails the thing the design is
  for. `CO_YIELD_US` is longer than `CO_POLL_US`, and that is the whole
  mechanism.

## Known limitations, by choice

* **Workers must share a machine.** See the `flock` limit above.
* **The HTTP backend does not write.** One request is one transaction; a
  machine is a header row plus a row per chunk. Stated in
  `lib/zeytun-kb.cicili` and in `parsi/03-pages.parsi`.
* **A claim has no lease.** `cocolog::machine_release` puts a machine back, and
  a worker that loses its connection calls it — but one that is killed outright
  strands its machine as claimed, and only `cocolog drop` will clear it. A
  lease with an expiry would want a timestamp column and a clock the server
  agrees with.
* **Builtins are all deterministic.** One that could leave a choice point
  behind — `between/3`, `clause/2` — would need the engine's choice stack in
  its hands. They belong in a Prolog-level library instead, which does not yet
  exist.
* **Resuming assumes the clauses have not moved.** A choice point remembers a
  predicate by name and the position of the next clause to try, so retracting
  from underneath a suspended machine makes it resume at the wrong one. This is
  the hazard `retract` has always had against a running query; the fix is to
  hold a transaction over the clause tables.
* **`asserta` rewrites its whole predicate** in the database, because putting a
  clause at the front changes every later clause's ordinal. O(n) per assert and
  always right.
* **No error terms.** A goal that cannot be run reports through the engine's
  `err` string and stops the query, rather than throwing a Prolog `error/2`
  that a program could catch. `catch/3` and `throw/1` are not implemented.
* **No garbage collection.** The heap only grows within a solution; it is
  reclaimed on backtracking and on a new query. A long deterministic run that
  builds structure will grow until it ends.

## Not started

* A REPL. `cocolog query` runs one goal and exits.
* `findall/3`, `bagof/3`, `setof/3`.
* Strings as a type; `"abc"` reads as a code list, which is the ISO default.
* Any indexing on the first argument. A predicate's clauses are tried in order.
