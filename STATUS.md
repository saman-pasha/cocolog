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
| `client/probe.c` | the C client against a real server, including a clause made of nothing but the five HTML-escapable characters, asserted over the binary protocol and read back through a page unchanged |

## The open problem: concurrent writers

**`test/groups.sh` does not pass yet.** It is the arrangement the project is
ultimately for — two groups of two interpreters, four processes at once over
two distinct machine states, each group handing its machine back and forth
through the database — and it is written and committed. What happens is:

* Each worker on its own works correctly. `cocolog work NAME MACHINE` claims,
  advances and re-suspends a machine, repeatedly, and several turns in sequence
  produce exactly the answers one process would.
* Run **concurrently**, the workers get `write failed: Broken pipe`, and the
  server log shows `function error: NULL value` and one
  `hexmap ends inside the chunk at NNNNN`.

What is established about it so far:

1. **A server-side exception closes the connection.** `loadzigurat.cpp` writes
   `EXCEPTION_THROWN`, breaks out of the request loop and closes. So any
   failure — including a lock conflict — is fatal to that worker's connection,
   not merely to the call. **A concurrent worker must reconnect after a failed
   call**, and `cocolog` does not yet.
2. **Abandoned transactions hold locks.** A worker that dies mid-turn leaves
   its locks until the transaction is reaped, and the next run then blocks on
   them and looks like a protocol bug. This is why `test/run-c-connector.sh`
   builds a throwaway `ZIGURATIP_HOME`.
3. The `NULL value` error has **not** been traced to a specific statement yet.
   It appears only under concurrency; `cocolog::machine_claim_named` run
   sequentially is fine. The next step is to reproduce it with two processes
   doing nothing but claim/release, and if it is in the storage engine rather
   than in the Parsi, to say so and design around it rather than patch
   ZiguratIP.

Until that is settled, the honest description of the system is: **a machine's
state moves correctly between interpreters, and several interpreters can read
one knowledge base at once; several interpreters WRITING at once is not yet
proven.** `test/shared.cicili` exercises six interpreters but sequentially.

A likely shape for the fix, in order of preference:

* reconnect-and-retry in the worker, with a bounded backoff, since the server
  ends the connection rather than the call;
* an explicit `zg_isolate` per worker, if the default level is what the
  conflicts come from;
* a lease with an expiry on a claim, so a worker that dies does not strand a
  machine — the claim today has no timeout and `cocolog::machine_release` has
  to be called by hand.

## Known limitations, by choice

* **The HTTP backend does not write.** One request is one transaction; a
  machine is a header row plus a row per chunk. Stated in
  `lib/zeytun-kb.cicili` and in `parsi/03-pages.parsi`.
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
