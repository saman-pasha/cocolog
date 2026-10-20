# library(async) — Go's go, yield, await and channels as green threads

`library/async.pl` is the clauses; the engine is `lib/green.cicili`, a
compiled-in module registered as `green` (no `.so` to build). It is TIER 1
SINCE 2.8.0: `lib/library.cicili` preloads it at start-up, so async
coroutines are on by default and `use_module(library(async))` is a no-op.
The lesson is `tutorials/library/54-async.pl`, the case `test/async.pl`, and
the numbers below are `bench/concurrency.sh`'s Concurrency Runs A-C.

Since it is tier 1, its names are GLOBAL: a program's own predicate named
`go/1,2`, `yield/0`, `await/1,2`, `await_all/1`, `async/2`, `future_ready/1`
or `channel/1,2,3`, `channel_send/2`, `channel_recv/2`, `channel_close/1` is
shadowed by the library's (the 2.8.0 suite's window and flowdebug fixtures
were renamed `rec` for it).

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

A green thread is a **machine of its own in a world of eight workers**
(2.8.0): the caller's thread is worker 0 and seven OS threads are workers
1..7. Each worker owns a STORE and a base machine of its own, built once
at `async_run/1,2` from a snapshot of the caller's knowledge base; a task
is pinned to the worker it was born on, and its atom, functor, string,
float, big and rat tables alias that worker's base. A spawn copies
nothing: it is a heap, a trail, a choice stack and an engine. A write a
task makes — `assertz/1`, `asserta/1`, `retract/1`, `dynamic/1`,
`abolish/1` and `nb_setval/2` — is REPLICATED to every other worker's
store before the builtin returns, so the caller, the main thread and the
host see it. Terms cross in canonical text through a channel, and a
result crosses as the goal term.

The scheduler is **M:N at a step quantum**: each worker picks the ready
tasks pinned to it, and a task that never yields is stopped at 10,000
steps (the engine's limit path, the continuation flushed and resumed), so
it cannot hold its worker; a foreign call still can. A world holds
**1024 tasks and 64 channels**. A worker with nothing to run waits on its
own condition variable; a deadlock (every task blocked, the main not
ended) is raised at `async_run/1,2`.

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
steps each, on a 16-core Intel Mac, cocolog 2.8.0 (Concurrency Run C, the
M:N world; Run B's 2.7.0 shared-store, one-scheduler model and Run A's
2.6.0 snapshot model are in bench/README.md):

| lane | wall |
|---|---|
| serial | 458.9 ms |
| real threads (library(thread), 8 OS threads) | 173.0 ms |
| green threads (library(async), 8 green threads on 8 workers) | 440.7 ms |
| goroutines (Go, 8) | 92.7 ms |
| coroutines (asyncio, 8) | 555.5 ms |

This is the CPU-bound wall, and the green lane now USES THE CORES: `time`
reports 450 % CPU, against the 2.7.0 one-scheduler 505.1 ms on one core.
The wall is still 440.7 against the real threads' 173.0, because the
green engine pays the world's setup (seven cloned stores), the quantum's
stop and flush every 10,000 steps, and a lock at every run boundary: the
same work is about 3.7 times the CPU per task. Real threads and goroutines
win a CPU-bound wall; the M:N model's win is that a blocking task no
longer holds every other task's core.

**Light lanes** — many short tasks that do `true` and are joined, then the
same with a yield each round. This is creation and switch cost, where green
is supposed to win:

| lane | per task | per yield |
|---|---|---|
| real threads (1,000) | 108.56 us | 12.72 us (mutex handoff) |
| green threads (10,000; batches of 1023) | 13.89 us | 5.83 us (`yield/0`) |
| goroutines (Go, 10,000) | 9.75 us | 1.20 us (`Gosched`) |
| coroutines (asyncio, 10,000) | 21.12 us | 3.43 us (`sleep(0)`) |

Green is **~7.8x cheaper per task** than a cocolog OS thread (13.89
against 108.56 us) and 1.4x Go's goroutines (9.75), and **~2.2x cheaper
per yield** (5.83 against 12.72); Go's `Gosched` is 4.9x cheaper than
`yield/0` now, where the 2.7.0 one-scheduler model measured 1.07 us. The
world pays a lock at every yield and every spawn; the 1023-task batch
makes the seven cloned stores' cost small per task but not nothing. The
counts differ by lane (the OS lane is capped at 1,000 on this Mac, whose
user-process limit is 2,784, and a cocolog thread carries a machine and a
store), so the per-task and per-yield columns are the comparison, not the
wall alone.

**One core**: `real1` runs the real work lane under `taskset -c 0` on Linux,
the like-for-like scheduler comparison with the world's workers. The Mac
has no taskset and the lane says SKIP; the green work lane above is the
eight-worker number, and its CPU (450 %) says the cores are used.

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
* **The task cap** is 1024 a world (2.8.0), fixed in the world's arrays;
  a spawn copies nothing, the world's clones are paid once at
  `async_run/1,2`.

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

The tree NOW holds stage 3 as built here: eight workers, each with a
store and a base machine cloned from the caller's at `async_run/1`, tasks
pinned and preempted at the step quantum, and the write replication of
`assertz`, `asserta`, `retract`, `dynamic`, `abolish` and `nb_setval`
across the stores before the builtin returns. The per-task heaps and the
cloned stores answer the shared-heap question without a relocating heap;
the tables' reclamation and the store's compaction are suspended while a
world runs. 2.6.0's released library was the per-spawn-snapshot model and
2.7.0's the shared-store single scheduler.

## Limits, stated where a reader meets them

* A signal delivered to a green thread's machine writes that machine's
  engine cell; a blocking foreign call defers the signal until it returns.
* A task is preempted at a 10,000-step quantum; a foreign call holds its
  worker.
* Each worker's store is a CLONE of the caller's at `async_run/1,2`, and
  `assertz/1`, `asserta/1`, `retract/1`, `dynamic/1`, `abolish/1` and
  `nb_setval/2` are replicated to every worker before they return.
  `b_setval/2`, a consult or load, a backend's fetch and a module's own C
  state belong to the worker that ran them. No reclamation or store
  compaction runs while a world does.
* 1024 tasks and 64 channels a world; a spawn copies nothing; a deadlock is
  the world's error.
* The world is M:N: the caller's thread and seven OS threads, eight stores.
* A library predicate with a choice point per answer (`between/3`) is slow
  in a green store; the benchmark's work is a recursion (`bench/spin.pl`),
  and `test/async.pl` says so.
* A goal is read in the new machine's module; a module-qualified goal is
  not carried as one.

`cocolog 2.8.0`, the M:N world: eight workers, cloned stores, replicated
writes and the step quantum. Reasoning stays 1.0.11.
