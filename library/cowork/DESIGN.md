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

> **STAGE 4 HAS SINCE SHIPPED TOO** — `cowork_post/2`, `cowork_poll/2` and
> `cowork_poll/3`, with 5 more checks. §6 carries the measurement and the one
> thing building it taught: a pipeline has to be PACED, and posting every
> frame regardless is a queue that grows. Posted answers come back on a
> channel of their own, so a `poll` can never take a `map`'s result nor a
> `map` a posted one — which is a check, not a hope.

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

### 5a. Stage 2, measured — the shape pays, and the target moved

**The shape pays.** A per-unit visibility walk over `library(hex)` — the disk within
sight range, each candidate tested by walking the line to it and stopping at the first
blocker, which is `side_visible/2`'s shape — against the sequential path, and the
answers compared term for term:

| | sequential | crew | |
|---|---|---|---|
| 60 units, 4 workers | 101 ms | 35 ms | 2.9× |
| 200 units, 4 workers | 309 ms | 112 ms | 2.8× |
| 200 units, 8 workers | 314 ms | 66 ms | 4.8× |

**identical answers in every run**, which is the check that matters more than the ratio.

**And the break-even is ~11 µs of dispatch per job.** The same 200 jobs on four workers,
with the work per job shrunk by reducing the sight range:

| per job, sequential | sequential total | crew | |
|---|---|---|---|
| 0.026 ms | 5.1 ms | 3.5 ms | 1.5× |
| 0.203 ms | 40.6 ms | 22.7 ms | 1.8× |
| 0.715 ms | 143.0 ms | 51.1 ms | 2.8× |
| 1.896 ms | 379.3 ms | 120.5 ms | 3.1× |

So a job pays from about **0.05 ms of compute** upward on four workers, and the speedup
approaches the worker count around 1 ms a job. Below ~15 µs the dispatch is the work.
That is the arithmetic §1 promised, now with a number in it.

**THE TARGET MOVED, AND THAT IS THE REAL STAGE-2 FINDING.** §5 put fog first on rung
188's title, "the fog was walked once per unit". Reading `game/fog.pl` shows rung 188 is
the rung that FIXED it: `side_visible_now/2` caches the visible set against a signature
of where every unit and city stands, and rung 188 moved that cache out of a store row
into a global. Fog is therefore no longer walked per unit per frame — only when
something moves. What is left to parallelise is one `side_visible/2` on a cache MISS
(43 ms when last measured, at rung 157, before the cache), plus `vis_signature/2`, which
runs on every call including the hits.

So stage 2 should be re-pointed before any CivV code is touched, and stage 0 — measure
one real turn — is now the blocking step rather than a formality. Rung 180's yields are
the better first candidate on today's evidence, and this document should not choose
between them from a commit title again.

---

## 6. The latency model: one frame behind

A 16 ms frame cannot be helped by moving work off the main thread and waiting for it —
the wait is the frame. Work moves off the loop only if its result is wanted **next**
frame: compute frame N+1's derived state while frame N draws, and read it with
`cowork_poll/2`, which fails rather than blocks when the answer is not ready.

**Measured, forty frames, four workers, each frame's derived state being every unit's
visibility:**

| | per frame | worst frame |
|---|---|---|
| the frame computes it itself | 35.4 ms | 46.3 ms |
| the frame posts it and polls | 3.7 ms | 5.2 ms |

Ten times cheaper, and the worst frame — the one a player feels — goes from 46 ms to 5.

**AND A PIPELINE HAS TO BE PACED.** That measurement hides a trap, and it was measured
falling into it. Posting every frame regardless is a queue that GROWS: the same forty
frames posted forty jobs, collected **twelve**, and left **twenty-eight** queued, each
stale by dozens of frames before anyone could look at it. The frame was cheap and the
work was pointless.

| | per frame | posted | collected | left queued |
|---|---|---|---|---|
| post every frame | 3.6 ms | 40 | 12 | **28** |
| one in flight | 3.3 ms | 4 | 3 | 1 |

**One in flight is the pattern** — post only when the last answer has come back. The
frame costs the same and nothing piles up. The library does not enforce it, because a
caller may legitimately want several outstanding; `cowork_poll/2` answering is what tells
you whether to post.

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

## 8a. What CivV measured, which answers most of §9

Reported by the CivV session against cocolog 1.2.8 with CivV's whole program
registered, and it corrects this document in two places:

| | this document said | CivV measured |
|---|---|---|
| thread create + join, bare | 3.134 ms | 3.12 ms |
| … with CivV's whole program registered | ~50 ms (extrapolated) | **14.0 ms** |
| CivV's entire mutable turn state | ~5,000 facts guessed | **471 facts** |
| a full snapshot to one worker | ~5.4 ms | **~0.5 ms** |

**§9's items 1 and 2 are answered, and the extrapolation was wrong the safe way.** CivV
has MORE clauses than the 3,000-clause module and starts in under two thirds the time,
so the store fill is **not linear in clauses**. Item 2 guessed predicates rather than
clauses; whatever the unit is, it is not the one §1 assumed. Item 4 is answered too: a
real turn's state is 471 facts, so a snapshot to eight workers is about 4 ms, not 43.

**AND THE COST IS PAID LAZILY, WHICH THIS DOCUMENT DID NOT KNOW.**
`cowork_start(4, [], _)` returns in **0.18 ms** — the threads exist, but a worker's store
is filled on its FIRST GOAL, so the 14 ms lands on whatever message the worker handles
first. Starting a crew at load is therefore still right and is no longer sufficient:
**warm it**, with `on_start(Goal)` or one throwaway `cowork_map/3`, or the first real
turn pays for four workers' store fills inside itself. That is also why the hang in §8b
appeared at a `cowork_tell/2` rather than at `cowork_start/3`.

None of this changes the thesis — workers are still long-lived, because 14 ms is still
most of a frame and a crew still answers thousands of jobs after paying it once — but
§1's arithmetic should be read with 14 ms in it rather than 50.

## 8b. The hang, found and fixed

`cowork_tell/2` asserted in every worker and waited for an acknowledgement, and a worker
sent one only if the assert had WORKED. A clause too long for a row raises
`resource_error(clause_length)` the moment a worker has a database under it — which is
every worker under `--embed` — so the worker fell out of its loop, nobody acked, and the
caller waited for ever on a channel nothing would ever be sent to.

Reproduced in three lines with no game in it (`cowork_tell(C, [3])`, exit 124), and in
the shape CivV met it: a 9,000-character clause under `--embed`. CivV's trigger was
`chronicle_snap/2`, whose rows each hold a whole sorted LIST of another predicate's
facts, so the terms are far larger than the fact count suggests — which is why a
same-sized trimmed set did not reproduce it.

**The ack carries the outcome now and is always sent**, and the worker loop catches so an
unexpected ball costs one message rather than the crew. A tell that could not be done
raises to its caller and names the reason. `test/cowork.pl` holds it in a CHILD with a
timeout, because a regression would hang the case rather than fail it.

**AND THE BOUND WAS NOT ENOUGH ON ITS OWN**, which CivV found next: a tell that
neither returned nor raised. A channel receive with a pattern CONSUMES what it dequeues
and only then unifies, so one stale `res(...)` left by a wait that gave up made the next
`cowork_tell/2` eat it, fail to match `ack(_, _)`, and FAIL — silently, where a caller
cannot tell a refusal from an empty answer. The same lost message then cost a later wait
its whole timeout, waiting for an acknowledgement that had already arrived and been
discarded. Both of their symptoms, one cause, and both in code written here.

Two things fix it. **Acknowledgements have a channel of their own** — three channels now,
three kinds of message, and no receive can see somebody else's. And **every wait drains
its channel first**, because a wait that gave up leaves workers still working and their
answers arrive afterwards addressed to nobody; without the drain the next map inherited
them and answered a question it had not been asked, measured as a map for `after(_)`
coming back `ok(slow(1,2))`. Results carry an index within their own map and indices
start again at one, so they cannot be told apart by name — only cleared at the one moment
nothing legitimate can be there.

**And the residual risk is fixed too, from the other end.** A worker CAN die before it
reads its first message — a store fill that raises — and the catch inside the loop cannot
help, because the loop was never reached. That is not fixable in the worker; it is
fixable by refusing to wait without a bound. Every wait now takes the crew's timeout
(60 s by default, `timeout(Ms)` at start) and a missing answer raises
`timeout_error(cowork, Missing)` naming how many never came. Generous enough that a cold
worker paying its store fill is never mistaken for a dead one, finite so a dead one is
never mistaken for a slow crew. **No wait in this library is unbounded.**

## 9. What to check before building on this

1. **The extrapolation.** 23.8 ms was measured at 3,000 clauses; ~50 ms for CivV's
   ~6,778 is arithmetic, not a measurement. Measure it with CivV's actual modules
   registered before sizing a crew.
2. **Whether the fill is linear in clauses or in predicates.** The plan assumes clauses.
   If it is predicates, a program with few large predicates starts far cheaper than this
   document says, and per-job workers come back onto the table.
3. ~~**Whether a worker needs a database connection.**~~ **ANSWERED TWICE.** A worker
   HAS one under `--embed` — `resource_error(clause_length)` fired inside one, and that
   error exists only when the store has a backend to measure a row against. Which turned
   out to be the bug rather than the answer: `cowork_tell/2` was WRITING each worker's
   snapshot through to the knowledge base, four clauses to two workers putting eight rows
   in the database, and deadlocking past a handful because both workers wanted the
   embedded store while the caller waited. `with_local_clauses/1` (1.2.11) mutes it, and
   a snapshot fact no longer has to fit a row either. What is still unwalked is whether a
   job can usefully READ the store under a crew.
4. **The real snapshot size.** 5,000 five-argument facts is a guess at a map; measure
   CivV's actual turn state before believing the 43 ms figure.
5. ~~**Whether `cowork_map/3` should bound its in-flight jobs.**~~ **ANSWERED, and the
   question was pointed at the wrong predicate.** `cowork_map/3` is already bounded by
   construction — one job per worker, and a worker gets its next only when its last
   answer arrives. It is `cowork_post/2` that is unbounded, which §6 measured leaving 28
   stale jobs queued. `cowork_pending/2` reports what is queued and not yet taken, which
   is the number a pipeline paces against.

6. **Whether a job can read the store, and what the embedded engine's one-call-at-a-time
   does to a crew.** The half of item 3 that is still open, and the first thing to walk
   before stage 3.
