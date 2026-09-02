# A graph execution path for `library(torch)` — design

**The rule:** a program written for the CPU path runs unchanged under the
graph path. Same predicates, same arguments, same answers. The only thing
that moves is *when* the arithmetic happens, and the design below is the list
of everything that has to be true for that sentence to hold.

Status: **all three phases are built** (September 2026). Phase 1: `tensor_execution/1`,
recording, forcing, meta shapes, `tensor_force/1`, `tensor_graph_stats/1`, and
`test/torch-graph.sh` holding it to equality against eager on this Mac's CPU.
Phase 2: `tensor_parameter/2`, `tensor_agg/3`, `tensor_grad/3`, `tensor_step/4`,
`test/torch-grad.sh`, and tutorial 29, a training loop written in Prolog. Phase 3:
forced values living on the CUDA device and a recurring forward replayed as one
CUDA graph, `test/torch-replay.sh`, gated on a Colab T4.

---

## 1. Where the module stands, and why "lazy" fits it

Today a tensor is a C++ object and Prolog holds an **integer handle** into a
fixed table of owned `torch::Tensor*` (`ct_tensors[4096]`, `tensor_of`,
`tensor_adopt`). Every tensor predicate is one eager libtorch call:
`tensor_binary(add, A, B, C)` runs `a->add(*b)`, adopts the result into a
fresh slot, and unifies the slot number with `C`. Eleven producers make
tensors (`ct_binary_raw`, `ct_unary_raw`, `ct_scalar_raw`, `ct_reshape_raw`,
`ct_cat_raw`, `ct_index_rows_raw`, `ct_argmax_raw`, `ct_factory_raw`,
`ct_arange_raw`, `ct_eye_raw`, `ct_randperm_raw`, plus `tensor_load_csv`,
`tensor_from_list`, `tensor_rows`/`tensor_cols`, `tensor_standardise` and
`model_predict`); a handful of consumers read numbers out of them
(`tensor_to_list`, `tensor_item`, `tensor_reduce`, `tensor_shape`,
`$tensor_save`) or feed them to a model (`model_train`, `model_evaluate`,
`model_predict`). The Prolog half — `tensor_add/3`, `tensor_relu/2`,
`tensor_sum/2`, thirty clauses — is written over those builtins, so it
inherits whatever they do.

Three facts measured on 2026-09-02 shape the design:

* **The proof search itself is where a Prolog program spends its time**, at
  about 620 ns a resolution step, and nothing about a graph helps a single
  proof. The graph path is for the arithmetic a proof *does*, not for the
  proof.
* **An eager tensor op called from Prolog costs 5.5 µs**, of which the
  seven surrounding inferences are 4.3 µs and libtorch about 1.2 µs. On CPU
  there is no launch cost to remove, so on CPU the graph path buys no speed.
  What it buys there is *correctness of the design*, provable cheaply.
* **On a T4 the 28 tutorials ran 2.4× faster overall and 2.5× slower on the
  24 small ones**, because each step is a kernel launch plus a host round
  trip. That launch-bound regime is exactly what a recorded graph, replayed
  as one CUDA graph, removes — and it is the regime the tutorials live in.

So: the graph path is a *deferral* of the eleven producers, a *force* at the
consumers, and on CUDA a *replay* of what was recorded. Everything else is
the price of keeping the first sentence true.

## 2. The switch, and what it does not change

```prolog
tensor_execution(torch, eager).     % the default: what the module does today
tensor_execution(torch, graph).     % record, force at the seams, replay when it can
tensor_execution(X).         % asks
```

Module state, like `torch_device/1`. Every existing predicate keeps its name,
arity, modes and answers. No program needs a new predicate to *use* the graph
path; the new predicates below only *inspect* it or reach what eager could
never offer.

```prolog
tensor_force(T).            % execute what T depends on, now; true
tensor_graph_stats(S).      % S = stats(recorded(N), executed(M), replayed(R), pending(P))
```

## 3. The handle table becomes a table of nodes

A slot holds a `std::shared_ptr<CtNode>`:

```cpp
struct CtNode {
  int kind;                            // 0 value, 1 deferred
  int op;                              // producer + its op code, as today
  std::vector<std::shared_ptr<CtNode>> ins;   // BY POINTER, never by handle
  double scalar; std::vector<int64_t> ishape; long long n, dim;   // op arguments
  std::vector<int64_t> shape; c10::ScalarType dtype;              // known at record
  torch::Tensor value;                 // present once executed
  bool executed;
};
```

* **`tensor_of(h)` becomes `force(h)`**: a value node answers its tensor; a
  deferred node walks its inputs depth-first, executes each unexecuted node
  with the *same* `ct_*_raw` function eager uses today, stores the result,
  and answers it. One code path produces tensors in both modes; the graph
  path cannot drift from eager because it *is* eager, later.
* **Inputs are held by pointer, not by handle.** `tensor_free(T)` today frees
  a slot for reuse; under the graph path a dependant that named its input by
  handle would, after a free and a reuse, read a stranger's tensor. Holding
  the `shared_ptr` makes `tensor_free` mean "Prolog no longer names this",
  and the node lives exactly as long as something depends on it.
* **Shapes are known at record time.** Each producer computes its output
  shape and dtype when it records, by running the same op on libtorch's
  **meta device** — tensors with shape and no storage — so a shape error
  (`matmul` of `[3,4]` by `[5,6]`) is raised at the same predicate, with the
  same `domain_error`, as eager raises it. `tensor_shape/2` answers from the
  node without executing anything. This is the mechanism that keeps error
  *timing* identical for the whole class of errors a program can provoke
  with its shapes; §6 lists the class it cannot cover. Four producers have no meta kernel in
  every libtorch -- `abs`, `relu`, `index_rows`, `standardise` -- and for those
  the shape is written as a rule, since none can raise a shape error the rule
  would miss; `standardise` still refuses a training count past the rows at
  record time, as eager refuses it.

## 4. Which predicates record, which force, and which do neither

| predicate | eager | graph |
|---|---|---|
| `tensor_binary`, `tensor_unary`, `tensor_scalar`, `tensor_reshape`, `tensor_cat`, `tensor_index_rows`, `tensor_argmax`, `tensor_rows`, `tensor_cols`, `tensor_standardise` | compute | **record** a deferred node; shape by meta |
| `tensor_new(_, zeros\|ones, _)`, `tensor_full`, `tensor_eye`, `tensor_arange` | compute | **record** (deterministic leaves; executing them late is free) |
| `tensor_new(_, randn\|rand, _)`, `tensor_randperm` | compute | **execute now** — see §5 on random numbers |
| `tensor_from_list`, `tensor_load_csv`, `$tensor_load` | compute | **execute now** (the data is already here; a node would only copy it later) |
| `tensor_to_list`, `tensor_item`, `tensor_reduce`, `$tensor_save` | read | **force**, then read |
| `tensor_shape` | read | answer from the node, no force |
| `model_train`, `model_evaluate`, `model_predict`, `model_set_params` | consume | **force** the tensor arguments, then as eager; `model_predict`'s result is a value node |
| `tensor_free` | free the slot | drop Prolog's reference; the node lives while depended on |
| `torch_seed`, `torch_device`, everything about models | — | unchanged |

Nothing on this table changes an answer. The tutorials never compose tensor
ops in Prolog — they call `model_train` on loaded data — so under the graph
path they record a handful of `tensor_rows`/`tensor_standardise` nodes and
force them at `model_train`. That is the point: they must run identically,
and they are the first equivalence test (§7).

## 5. Random numbers: the one place order is observable

Eager draws random numbers in program order. A graph path that executed
`randn` at force time would draw them in *force* order, and two programs
that record the same nodes in different orders — or backtrack over one —
would see different numbers for the same `torch_seed`. That breaks the first
sentence silently, on exactly the tests that compare final losses.

So stochastic producers execute at record time (§4). They are leaves, they
are cheap, and the deterministic graph above them is then order-independent:
any topological order gives the same tensors, and on CPU the same kernels
give the same bits. This is why the equivalence suite can demand *equality*
on CPU rather than a tolerance.

## 6. What the graph path may legitimately do differently

Written down so the dialect card can carry them:

1. **Resource and VALUE errors move to the consumer.** Out-of-memory, a CUDA
   fault, a NaN-producing kernel, an `index_rows` index past the end -- errors
   that depend on what is *in* a tensor rather than on its shape: eager raises
   them at the op, graph at the force. Shape and dtype errors do not move (§3).
2. **Work on a failed branch never happens.** A node recorded on a branch
   that backtracks is never forced; `tensor_graph_stats/1` shows
   `recorded > executed`. Eager already did the work and leaked the slot.
   This is a difference in cost, not in answers.
3. **Handles are still process state.** Never trailed, never in a machine's
   frozen image, meaningless after a thaw — exactly as today. A deferred node
   that is never forced and never freed is a leak of one small struct rather
   than of a tensor.
4. **Device is invisible either way.** Today every handle is a CPU tensor and
   `model_train` moves batches to the model's device. Under the graph path a
   forced value lives on `ct_device` and is copied to the CPU when a
   consumer reads numbers, so `tensor_to_list` on a T4 costs one copy at the
   read instead of one per op. Prolog sees the same lists.

## 7. The gates, in order

**Gate A — this Mac, CPU, equality.** `test/torch-graph.sh`:

* every producer in §4, one goal each, run under `tensor_execution(torch, eager)` and
  again under `tensor_execution(torch, graph)` in a fresh process, `tensor_to_list`
  results compared as **equal**, not close;
* the composed case: a ten-op expression, forced once, compared equal; the
  same expression forced twice (a second `tensor_to_list`) executes nothing
  new — `tensor_graph_stats` says so;
* shape error timing: `tensor_binary(matmul, [3,4], [5,6])` raises the same
  `domain_error` at the same goal in both modes;
* the backtracking case: a node recorded in a branch that fails, then the
  program continues; `executed` stays 0 for it;
* `tensor_free` of an input that a live node depends on, then forcing the
  node: the right answer, not a stranger's tensor;
* random order: two `randn` leaves recorded, forced in the reverse order,
  equal to eager's draws under the same seed;
* the 28 tutorials' `train` goals with `tensor_execution(torch, graph)` prepended,
  compared to eager on final loss and accuracy — equal on CPU, because the
  training loop is C++ in both modes and only the data preparation is
  deferred.

**Gate B — this Mac, the payoff a CPU can show.** Autograd through a
recorded graph. As built: `tensor_parameter(T0, T)` answers a fresh LEAF that
requires gradient, with `T0`'s values; `tensor_agg(Op, T, T2)` is the one
reduction that stays a tensor, since a number cannot be differentiated;
`tensor_grad(Loss, [W…], [G…])` forces `Loss` — which under the graph path is
what builds libtorch's tape — and answers one gradient per parameter, zeros for
a parameter the loss never reached; `tensor_step(W, G, LR, W2)` answers
`W - LR·G` as a NEW leaf and leaves `W` as it was, so nothing is ever mutated
and a deferred node that still names the old parameter stays honest. Because
libtorch records its tape whenever an input requires grad, all four work under
eager too, and `test/torch-grad.sh` holds them equal across the two paths, to
the analytic least-squares gradient within 1e-6, and to `2W` for `sum(W·W)`
exactly. Tutorial 29 writes its loop in Prolog — 300 steps of plain SGD on a
three-input plane — hands the weights to a `dense(1)` model through
`model_set_params/2`, saves it, and its `test` process reloads a model no
`model_train` ever saw.

**Gate C — Colab, the T4.** As built, and with one correction to what was
written here first: replay cannot speed up the 28 tutorials, because their
loops live inside `model_train`'s C++ and record nothing; what the graph path
records is tensor work composed in Prolog. Two mechanisms, then. **Placement:**
under `tensor_execution(torch, graph)` with `torch_device(cuda)`, a leaf moves to the
device the first time a deferred node reads it, once and for good, a parameter
is re-made as a leaf there, forced values stay there, and consumers copy back;
eager never forces, so eager's handles stay CPU tensors as they always were.
**Replay:** the closure of a forced node — its undone nodes in dependency order
and the done leaves they read — is keyed by every shape, dtype, producer and
argument in it; the first force of a key runs plainly, the second is captured
as one `at::cuda::CUDAGraph` over static copies of its leaves and replayed,
and every later force copies the new leaf values into those buffers and
replays. A closure with a parameter requiring gradient is never captured,
since a replay builds no tape. Compiled in only where `libtorch_cuda` is
(`build.sh` decides by the library, not the header, which CPU builds ship too,
and finds the toolkit's `cuda_runtime.h`); elsewhere every force is plain.

Measured on the T4 on 2026-09-02, `test/torch-replay.sh` GREEN: every producer
within 1e-4 of the CPU path, most exactly; a forward forced six times on fresh
leaves executed its four nodes once and replayed five times, sums equal to the
CPU's; a closure with a parameter replayed zero times and its gradient matched
the CPU's within 1e-5. Tutorial 29's `heavy/3`, plain SGD in Prolog on
200000 rows by 64 features for 200 steps: the VM's two CPUs 3.8 s eager and
4.3 s graph, the T4 1.5 s including its start-up, and the same loss and the
same distance from the plane to six decimals on all three. At 20000 by 32 the
T4 was slower than the CPUs, 1.4 s to 0.8 s: the arithmetic has to be worth
the device's while, and the numbers say where that line is.

## 8. Phases, and their size

| phase | what | where | size |
|---|---|---|---|
| 1 | `CtNode`, the switch, record/force, meta shapes, stats, `tensor_force`; `test/torch-graph.sh` gate A | `coco-torch.cicili`, `coco-torch.cpp`, a test | ~500 lines, no engine change |
| 2 | `tensor_parameter/2`, `tensor_agg/3`, `tensor_grad/3`, `tensor_step/4`, tutorial 29 (the loop in Prolog); gate B | `coco-torch.cicili`, `test/torch-grad.sh`, one tutorial | ~200 lines, built |
| 3 | placement on the device, subgraph keys, CUDA graph capture and replay, `replayed` in the stats; gate C on the T4 | `coco-torch.cicili`, `build.sh`, `test/torch-replay.sh`, tutorial 29's `heavy/3` | ~200 lines, built; compiled in only with `libtorch_cuda` |

Nothing here touches the engine, the store, or the freeze discipline. The
resolution loop stays what it is; the graph sits beside it, behind the same
predicates, and the dialect card gets §6.
