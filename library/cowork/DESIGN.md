# library(cowork) — a crew that outlives the turn, for a game with one heavy process

**A design document. Every number in it was MEASURED on this box, and §2 gives the
command for each.** Nothing here is estimated except where it says so in the same
sentence. The one extrapolation in the document is labelled as one.

> **STAGE 1 HAS SINCE SHIPPED.** `library/cowork.pl` and `test/cowork.pl`
> exist: start, stop, size, tell, forget, ask and map, 19 checks, and the
> tutorial is `tutorials/library/42-cowork.pl`. Two things came out of
> building it that this document did not predict. `cowork_ask/3` hands back
> the proven COPY and cannot bind the caller's variables — a goal crosses as
> text — so `cowork_ask/2` was added to unify the copy back, and it is the
> form to reach for. And a job calling a predicate the worker has no clauses
> for RAISES `existence_error` rather than failing, which is ordinary Prolog
> and worth knowing before it is met: `on_start(dynamic(F/A))` is how a
> caller who wants absence to be an ordinary no gets one. `cowork_post/2`
> and `cowork_poll/2` are still stage 4, as §4 says.

The occasion is CivV: one process, a `library(ray)` loop that owns its own frames, a
turn that already runs inside `run_isolated/2`, and two rungs that name where the time
goes — rung 180, "the yields were costing four fifths of every frame", and rung 188,
"the fog was walked once per unit". The question put to this design was how such a
program does more than one thing at a time.

---

## 0. Reading guide

| you want | go to |
|---|---|
| the one measurement that decides the whole shape | §1 |
| every number, and how to reproduce it | §2 |
| what can cross a thread and what cannot | §3 |
| the surface, and the two contracts that carry it | §4 |
| what to move out of the main loop, in payoff order | §5 |
| why the answer is "one frame behind" and not "faster" | §6 |
| the build plan, with a gate at each step | §7 |
| what this does NOT fix, and what can go wrong | §8 |
| what to check before building on this | §9 |

---

## 1. Thesis, and the measurement that forces it

**A worker thread costs 3.1 ms to start with the default modules and 23.8 ms once a
3,000-clause module is registered.** A thread's store begins empty and is filled from
the process-wide module registry on its first goal, so the price of starting one scales
with the size of the program, not with the size of the job. CivV registers roughly
6,778 clauses, which puts one worker near 50 ms — *an extrapolation from the 3,000-clause
measurement, and the first thing §9 says to check.*

Three frames to start a thread. So:

> **Workers are long-lived or they are nothing.** A crew is started once, at load,
> after `use_module` of the game and before the first turn. There is no such thing here
> as a parallel map that spawns and joins.

Everything below is a consequence. The static world — rules, terrain, the tech tree, the
generated `rules/gen/*` — is already in every worker for nothing, because every
registered module is. Only the *mutable* state has to cross a channel, and at 1.1 ms per
thousand facts that is a per-turn budget and not a per-frame one.

The rule for what is worth moving is therefore arithmetic, not taste: **a small query in,
a small answer out, real compute in between, against a world the worker already holds.**

---

## 2. The measurements, and how to reproduce them

Taken 2026-09-08 on the Mac (16 cores), cocolog 1.2.7.

| what | result |
|---|---|
| channel round trip, 10 facts (243 bytes of text) | 0.014 ms |
| … 100 facts (2,585 bytes) | 0.111 ms |
| … 1,000 facts (27,787 bytes) | 1.134 ms |
| … 5,000 facts (147,787 bytes) | 5.398 ms |
| thread create + join, default modules | 3.134 ms |
| **thread create + join, one 3,000-clause module registered** | **23.763 ms** |
| `run_isolated/2` | ~2.9 ms |
| `os_cpus/1` here | 16 |

The channel is **linear at about 27 MB/s**, which is what a canonical-text copy costs.
There is no cliff to design around — only a slope, and the slope is the budget.

Reproduce the transfer number with a list of five-argument facts sent through a channel
and received back, timed over twenty round trips, sizing the payload with
`term_to_atom/2` and `atom_length/2`. Reproduce the start number by timing fifty
`thread_create(true, I), thread_join(I, _)` pairs, once as-is and once with a
3,000-clause file loaded by `use_module/1` first. Both programs are four clauses; write
them fresh rather than trusting a copy in a document.

**The caps are 256 threads and 256 channels**, file-scope tables in `modules/thread`.

---

## 3. What crosses, and what does not

| | mechanism | cost |
|---|---|---|
| the static world | the module registry — free to every worker | paid once, at thread start |
| the turn's mutable state | a channel, as canonical text | 1.1 ms per 1,000 facts, each way |
| a query and its answer | a channel | ~0.01 ms at this size |
| the knowledge base | **nothing** — a thread has no connection | — |
| raylib draw calls | **nothing** — the GL context is not shareable | — |

A cocolog machine is an unguarded heap, so two threads cannot share one. That is not a
limitation to work around in this library; it is the reason the library has the shape it
has. A term crossing between machines is copied whatever the mechanism, and canonical
text is the copy this interpreter already trusts.

**A precondition, and it is recent.** `nb_setval/2`'s globals are per-store as of the
change now in the tree. CivV's render and fog caches assume exactly that, and before it
a crew using them was fatal: eight threads writing 800 globals each aborted the process,
three runs of three, against an unguarded `realloc` on a file-scope table. Do not build
this on a binary without that fix.

---

## 4. The surface

`library/cowork.pl` — **clauses only, over `library(thread)`**. No new C, no new build
dependency, and it works wherever `library(thread)` does. The primitives already exist;
what was missing was the pattern.

```prolog
cowork_start(+N, +Options, -Crew)   % on_start(Goal) warms each worker
cowork_tell(+Crew, +Clauses)        % broadcast a snapshot; each worker asserts its own
cowork_forget(+Crew, +Spec)         % drop it at the turn boundary
cowork_ask(+Crew, +Goal, -Answer)   % one job, blocking
cowork_map(+Crew, +Jobs, -Answers)  % scatter and gather
cowork_post(+Crew, +Job)            % fire and forget: autosave, PNG export
cowork_poll(+Crew, -Answer)         % collect a pipelined result, or fail
cowork_size(+Crew, -N)
cowork_stop(+Crew)
```

Two contracts carry it, and both are load-bearing.

**A JOB IS A QUERY, NEVER A MUTATION.** The only way state enters a worker is
`cowork_tell/2`. A job that asserts leaves a worker holding something no other worker
has, and the crew stops being interchangeable the moment one of them does it. A worker
proves its goal in its own machine — deliberately *not* under `run_isolated/2`, which
would throw away the snapshot the worker exists to hold.

**`cowork_map/3` REASSEMBLES BY INDEX.** Each job travels as `job(I, Goal)` and each
answer as `done(I, Answer)`, `failed(I)` or `error(I, Ball)`, and the results are keysorted
back into input order. This is not tidiness: everything this family claims about
deterministic replay depends on parallelism being invisible in the answer. A crew that
returned results in completion order would make the same match replay differently on a
busier machine.

An error is carried, not swallowed. A worker that throws sends the ball back and stays
in the crew; a worker that dies is a `failed(I)` its caller can see.

---

## 5. What to move, in payoff order

1. **Fog, per unit.** Rung 188 already says it was walked once per unit. Tiny input,
   tiny output, embarrassingly parallel — the cheapest possible test of whether any of
   this pays, which is why it is first rather than because it is the largest cost.
2. **Yields, per city.** Rung 180 says four fifths of a frame. Same shape.
3. **A\* paths.** About a hundred bytes each way against milliseconds of search: the
   best ratio in the game.
4. **AI decisions, per nation.** Large compute, a natural partition, no shared writes.
5. **Autosave and PNG export.** `cowork_post/2`; nothing waits for an answer.

What does not qualify, and why: anything whose *input* is the whole map, unless the
worker already holds the map. A 5,000-tile snapshot to eight workers is about 43 ms of
copying. Once a turn, that is affordable. Every frame, it is the whole frame.

---

## 6. The latency model: one frame behind

A 16 ms frame cannot be helped by moving work off the main thread and waiting for it —
the wait is the frame. Work moves off the loop only if its result is wanted **next**
frame: compute frame N+1's derived state while frame N draws, and read it with
`cowork_poll/2`, which fails rather than blocks when the answer is not ready.

So the honest description of what this buys is not "the game runs faster". It is:

* the frame stops paying for work whose answer it does not need yet, and
* a turn's independent work is divided by the number of cores.

Drawing itself never moves. The *collection* of a scene can be parallel; the draw calls
cannot, because the GL context belongs to the thread that opened the window.

---

## 7. The build plan, with a gate at each step

**Stage 0 — measure CivV's own split.** Instrument one real turn and publish where the
time goes. Everything after this is guessing without it, and the two rungs above are a
starting hypothesis, not a measurement of today's code.

**Stage 1 — `library(cowork)` and `test/cowork.pl`.** The case must hold: the same
answers as the sequential path, input ordering under out-of-order completion, a job that
fails, a job that throws, a crew that survives many turns of tell-and-forget, and the
start cost paid once rather than per job. Tutorial in the same commit, as the rule
requires.

**Stage 2 — fog only, in CivV, measured against the sequential path.** If it does not pay
here it will not pay anywhere, and the right response is to stop and say so.

**Stage 3 — yields. Stage 4 — pipelining. Stage 5 — the AI.**

Each stage is its own commit with its own measurement. A stage that does not beat the
sequential path is reverted, not tuned in place.

---

## 8. What this does not fix, and what can go wrong

It does not speed up one hot query — that is still one thread doing one proof. It does
not help the store write path, measured elsewhere at 2.3 ms a row. It does not make a
turn that is one long dependent chain any shorter.

* **Crew start is ~50 ms × N** (extrapolated). It belongs at load, never mid-game, and
  never in a menu transition.
* **Modules must be registered before the crew spawns.** The registry is the one
  unguarded thing in the threading story, and a thread reading it while another writes
  is the documented hazard.
* **A snapshot that grows to the whole map per turn eats the gains.** Send deltas; keep
  anything static in a module instead of in a message.
* **256 slots**, threads and channels alike.
* **Determinism must be proven, not assumed** — see the gate in stage 1.

---

## 9. What to check before building on this

1. **The extrapolation.** 23.8 ms was measured at 3,000 clauses; ~50 ms for CivV's
   ~6,778 is arithmetic, not a measurement. Measure it with CivV's actual modules
   registered before sizing a crew.
2. **Whether the fill is linear in clauses or in predicates.** The plan assumes clauses.
   If it is predicates, a program with few large predicates starts far cheaper than this
   document says, and per-job workers come back onto the table.
3. **Whether a worker needs a database connection.** `coco_m_kb_install` gives an
   isolated proof one; a plain thread has none. If a job must read the store, that path
   has to be walked before stage 2, and the embedded engine serialises calls anyway.
4. **The real snapshot size.** 5,000 five-argument facts is a guess at a map; measure
   CivV's actual turn state before believing the 43 ms figure.
5. **Whether `cowork_map/3` should bound its in-flight jobs.** An unbounded scatter into
   a bounded channel is backpressure; into an unbounded one it is a memory leak with a
   scheduler attached.
