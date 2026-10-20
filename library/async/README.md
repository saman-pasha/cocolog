# library(async) — Go's go, yield, await and channels as green threads

`library/async.pl` is the clauses; the engine is `lib/green.cicili`, a
compiled-in module registered as `green` (no `.so` to build). The lesson is
`tutorials/library/54-async.pl`, the case `test/async.pl`, and the numbers
below are `bench/concurrency.sh`'s Concurrency Run A.

## The surface

    async_run(:Goal)                 run Goal as green thread 0
    async_run(:Goal, -Result)        ... and answer the goal as instantiated
    go(:Goal) / go(:Goal, -Id)       start a green thread
    yield/0                          give the scheduler its turn now
    await(+Id) / await(+Id, -Result) join; rethrow its exception
    await_all(+Ids)
    async(:Goal, -Future)            go/2's future spelling
    future_ready(+Id)
    channel(-C) / channel(+Size, -C) a rendezvous (0) or a buffered queue
    channel_send(+C, +Term)          blocks when full
    channel_recv(+C, -Term)          blocks when empty; fails when closed
    channel_close(+C)

A result is the goal as instantiated, in canonical text:

    ?- async_run((go(member(X, [a,b,c]), F), await(F, R)), Answer).
    Answer = (go(member(a,[a,b,c]),0), await(0,member(a,[a,b,c]))).

The caller's `X` is not bound: the answer is a copy. A thread that fails
makes `await` fail; one that throws makes it throw the same ball; a deadlock
(every thread blocked, the main one not ended) is raised at `async_run`,
where the program can catch it. Everything runs under `async_run/1,2`; a
`go/1` outside it says so by name.

## The model

A green thread is a **machine and a store of its own**, stepped by a
cooperative scheduler in the process — no OS thread per task. At spawn the
store is filled from a **snapshot** of the caller's knowledge base, because
a store belongs to one machine (its atom and functor tables are the store's)
and `coco_thaw` empties the store it thaws into. What one green thread
asserts stays its own; the main green thread and the host do not see it.
Terms cross in canonical text through a channel, and a result crosses as
the goal term.

The scheduler is **cooperative**: a thread runs until `yield/0`, `await/2`,
a channel block, or its end. A tight loop holds the scheduler — a green
thread is not preempted (see the step-limit note below). A scheduler holds
**64 threads and 64 channels**.

The engine's side is small: a thread is a `coco_machine` + `coco_engine` +
`coco_store`; a cooperative stop writes 128 into the engine's `halted` cell
(the green code, below the signal range), `coco_halted_step` flushes the
continuation and stops the run, and the scheduler resumes by calling
`coco_engine_next` again. The continuation is on the machine's heap, not the
C stack, so a green thread needs no stack copying.

The status of a thread is a text term the scheduler carries:

    '$async'(ok, Goal)   first solution, the goal instantiated
    '$async'(failed)     it failed
    '$async'(error, Ball) it threw Ball
    '$async'(closed)     a channel closed under a receive

A waiter's `await`/`recv` records the cell its status argument stands in;
the scheduler unifies the status there before the waiter resumes. Channels
are queues of text; an unbuffered channel is a rendezvous, a buffered one a
ring of the size asked.

## Performance: green versus OS threads

The answer depends on the question, and `bench/concurrency.sh` asks both.

**Work lanes** — the same `spin` (M steps) in N units, 8 units, 1,000,000
steps each, on a 16-core Intel Mac, cocolog 2.6.0 (the numbers were taken on
its 2.5.2 build; 2.6.0 changes the version and this plan):

| lane | wall |
|---|---|
| serial | 474.3 ms |
| real threads (library(thread), 8 OS threads) | 180.7 ms |
| green threads (library(async), 8 green threads) | 1305.3 ms |
| goroutines (Go, 8) | 95.8 ms |
| coroutines (asyncio, 8) | 573.9 ms |

This is the CPU-bound wall. Real threads use the cores and win; green runs
on one core and is 2.75x *slower* than serial — the work itself plus eight
per-spawn store snapshots. For CPU-bound work on many cores, green threads
cannot beat OS threads; that is Amdahl, not a defect.

**Light lanes** — many short tasks that do `true` and are joined, then the
same with a yield each round. This is creation and switch cost, where green
is supposed to win:

| lane | per task | per yield |
|---|---|---|
| real threads (1,000) | 121.21 us | 16.25 us (mutex handoff) |
| green threads (10,000) | 32.16 us | 3.28 us (`yield/0`) |
| goroutines (Go, 10,000) | 10.56 us | 1.24 us (`Gosched`) |
| coroutines (asyncio, 10,000) | 24.81 us | 3.66 us (`sleep(0)`) |

Green is **~3.8x cheaper per task** than a cocolog OS thread and **~5x
cheaper per yield** — the snapshot included. The counts differ by lane (the
OS lane is capped at 1,000 on this Mac, whose user-process limit is 2,784,
and a cocolog thread carries a machine and a store), so the per-task and
per-yield columns are the comparison, not the wall alone. Go's goroutines
are cheaper still; they are the same green idea in a runtime that shares
its heap.

**One core**: `real1` runs the real work lane under `taskset -c 0` on Linux,
the like-for-like scheduler comparison with green. The Mac has no taskset
and the lane says SKIP. On the Mac, `green` is one core already; its work
number above is that comparison with the per-spawn snapshot added.

The harness rebuilds the Go binary once, resolves the Python behind a pyenv
shim (the shim alone is ~1.7 s), throws the first run of each lane away, and
refuses a lane whose answer is not `answer(done)`.

## Toward Go's small-stack shared-heap goroutine

Go's goroutine is a small growable stack and a shared heap, scheduled M:N
over OS threads. Could cocolog's green threads be that? In stages, yes; not
as they stand.

* **The C stack is not the blocker.** The Prolog continuation is on the
  machine's heap (`'$k'` frames, environments), not on the C stack; the
  engine stops cleanly at a builtin/safe point, and the scheduler resumes by
  calling the loop again. A small stack is the engine's shallow C usage, not
  a goroutine stack to copy. The per-goroutine machine's heap can start
  small and grow.
* **A single shared Prolog heap is not compatible with the current
  backtracking.** The heap is stack-disciplined: a choice point's mark
  truncates everything above it on backtracking, and another goroutine's
  cells above that mark would be truncated with it. Go's exact shared heap
  would require a garbage-collected heap with relocation, or per-goroutine
  regions addressed through a region id — a rewrite of the term layer, not
  an option for this library.
* **A shared STORE with per-goroutine heaps is the feasible middle.** The
  knowledge base is already a separate cell array (`coco_store`), and a
  store is shared by clauses, not by the stack. The next step is:
  1. a shared atom/functor table (the machine's interning fields become a
     pointer to a shared table; store clauses' atom ids mean the same to
     every goroutine);
  2. a store-level registry of the green machines, so the logical update
     view's walks (`coco_frames_on`, the tombstone stamps, the sweeps)
     see every goroutine's frames, not just the writing machine's;
  3. a spawn that creates only a small machine + engine and copies the goal
     — no store snapshot. Asserts become visible across goroutines, and the
     light lane's per-task cost drops by the snapshot.
  That is a medium engine change (the store's multi-machine frame tracking
  is the delicate part), and it is the design to reach for next.
* **M:N over the cores is a further, larger step.** The store and the
  engine are single-threaded; running green threads on several OS threads
  needs locking or atomics in the store and the engine — the reason
  `library(thread)` gives every thread its own store and shares nothing.
  The green scheduler is one OS thread. The Go lane's cores are not
  matched by this library.
* **Preemption at step boundaries is possible now.** The green stop (128)
  is a clean stop/resume path; the engine's `max_steps` limit is the
  `cocolog step` freeze scheduler's stop, and a direct continuation after
  "inference limit reached" restarts the clause (found by
  `between(1,2000,_), fail`). A future quantum should count steps and stop
  with the green code, not use `max_steps`.
* **The 64-thread cap** can rise once the per-spawn cost falls; today each
  spawn pays the snapshot and the scheduler's table is fixed.

So: the exact Go model (one shared heap, small copied stacks, M:N) is not a
small change to this engine. It is the target of the stages below, a
staged engine-concurrency project, and the stages are:

1. **Shared names and store, per-goroutine heaps.** The machine's atom,
   functor, string, float, big and rat tables move behind one shared
   `coco_names` (an rwlock for intern/grow; the engine's hot paths keep
   their cached ids). Every green machine is a heap, a trail, a choice
   stack and an engine over the shared names and the caller's store; a
   spawn copies the goal and nothing else. The store's writes are refused
   until stage 2, so the shared store is read-only.
2. **A concurrency-safe store.** Stable clause identity and order (an
   asserta must not shift another goroutine's clause index), per-predicate
   atomic frame bookkeeping replacing the `framed` writes, atomic
   publication of a compiled clause and of an argument index, a global lock
   for the rare writes, and a stop-the-world barrier for asserta, retract
   and compaction. The reader stays lock-free on the cached paths; the
   update view's tombs and sweeps learn every machine's frames.
3. **M:N.** Worker OS threads, each a scheduler over its own run queue; a
   task's machine may migrate because its terms name the shared tables;
   cross-worker await and channels under a lock; the main task on the
   caller's thread. The store's single connection and hooks are serialized
   under the write lock.
4. **Proof by the suite and the benchmark**: the work lane's green tasks
   must use the cores, the light lane must keep its per-task cost, and the
   full suite (with a server) must be green.

The tree released as 2.6.0 is the per-store-snapshot model. The shared
names and store, the concurrency-safe store and M:N are the stages above,
and they follow this release.

## Limits, stated where a reader meets them

* A signal delivered to a green thread's machine writes that machine's
  engine cell; a blocking foreign call defers the signal until it returns.
* A green thread is cooperative (no preemption yet); a tight loop holds the
  scheduler.
* The store is a snapshot: a child does not see another's writes, nor the
  host's after spawn.
* 64 threads and 64 channels a scheduler; a spawn pays the snapshot; a
  deadlock is the scheduler's error.
* A library predicate with a choice point per answer (`between/3`) is slow
  in a green store; the benchmark's work is a recursion (`bench/spin.pl`),
  and `test/async.pl` says so.
* A goal is read in the new machine's module; a module-qualified goal is
  not carried as one.

`cocolog 2.6.0`. The shared-store multi-core model is the plan above, not
this release: 2.6.0's green library is the per-store-snapshot model. The
stages are the next work. Reasoning stays 1.0.11.
