# The TensorFlow module — the tensor predicates over TensorFlow's C library

`library(tensorflow)` is the SECOND BACKEND of the `tensor_*` predicates.
`library(torch)` owns the predicates and the switch,
`tensor_execution(Backend, Mode)`; this module registers itself with it
at load, and while `tensor_execution(tensorflow, _)` is in force every
`tensor_*` call is handed here. One surface, two implementations, never
both at once; the `model_*` predicates stay libtorch's.

```prolog
:- use_module(library(torch)).          % first: the predicates and the switch are its
:- use_module(library(tensorflow)).     % Linux; attaches to torch.so beside itself
?- tensor_execution(tensorflow, graph). % from here, every tensor_* is TensorFlow's
?- tensor_execution(B, M).              % B = tensorflow, M = graph
?- tensorflow_version(V).               % V = '2.20.0'
```

## Two modes, and what each can do

| `tensor_execution(tensorflow, …)` | what a producer does | gradients |
|---|---|---|
| `eager` | a `TFE_Execute`, now; a handle holds a `TFE_TensorHandle` | **none** — TensorFlow's eager C API has no tape, and `tensor_grad/3` says so |
| `graph` | RECORDS a node: the operation, its attributes, its inputs. A read collects the closure of what it needs, keys it by structure, compiles the key ONCE into placeholders and operations, and after that the same structure is one session run with the current values fed in | `TF_AddGradients` over the compiled closure, once per key — TensorFlow's own symbolic differentiation — and thereafter a run |

So a training loop wants `(tensorflow, graph)`, which is TensorFlow's
native arrangement anyway — a graph built once and run many times with
fresh values — and `eager` is for forward-only work. The graph grows with
the DISTINCT SHAPES OF COMPUTATION a program has, not with its steps, and
`tensor_graph_stats/1` counts nodes recorded, nodes given a value, and
runs that were REPLAYS of a compiled key. A node keeps its structure after
it has a value, so a loss read by `item` can still be differentiated by
`grad` after it; a node holds its inputs alive by reference until it is
freed. Under `graph` a shape is known with nothing executed
(`TF_GraphGetTensorShape` on the compiled closure), a shape error is
refused at the goal that adds the operation, with TensorFlow's own words,
and a random leaf — `randn`, `rand`, `randperm` — draws ONCE, through the
eager context, and is a value: a random operation in a graph would redraw
at every run, and a leaf read twice would not be one leaf.
`tensor_step/4` answers a new leaf, so a step never drags the history
behind it.

## What it costs, measured, against the bar

The owner's bar for a second backend is plain: a tutorial under
TensorFlow must finish within 1.5 times the seconds torch took for it on
the same T4. **It does not meet it, yet.** On the Colab VM, two by two,
each within its budget: 34 took 35 s of 32, 35 41 s of 39, 40 71 s of
69, 37 160 s of 158, 38 10 s of 8, 36 19 s of 17, 41 49 s of 47, 39 63 s
of 62, 32 11 s of 9, 33 13 s of 11 -- every one over, by a little, at a
GPU utilisation near zero. What it does meet: the gate, GREEN on all 43
checks; and quality, since 32's ResNet trained to test accuracy 1.00 and
33's U-Net to IoU 0.917 on this library, the same files, when given the
time (77 s and 239 s on the build before the step became a boundary).

The road here was three wrong drafts, each found by a run. The first
built the graph one predicate at a time and ran a session per read:
quadratic in the steps, 360 s for 200 steps of tutorial 31's fit. The
second keyed and compiled closures, but forced every step's result at
once -- twenty session runs a step for a transformer -- and let an
optimiser's moments hold every step before them alive, until the handle
table filled forty steps into 32. The third, this one: a step is recorded
and marked a parameter, the next loss's one run computes all the new
parameters and moments together, the gradient is the second run; a node
keeps its structure only while a parameter lies under it; shapes come by
rule; keys are hashed; and `allow_growth` is set, so TensorFlow holds
185 MiB at rest and at most 420 MiB through the tutorials instead of the
whole card -- the 13.8 GB the owner read, rightly, as the sign of a
problem, was the allocator's habit hiding the graph's growth. Tutorial
31's fit: 200 steps in 4 s.

The measurement was taken before the VM went: three steps of 32 gave
five replays, six steps eight -- one replay and one COMPILE a step. Adam's
bias-corrected learning rate changes every step, and a scalar's value was
in the key as if it were structure, so every loss was a new key. A scalar
operand is data now, fed each run and keyed by its shape alone; axes,
shapes and slice bounds stay in the key, since they are the structure.
After that: two replays a step, 40 for 20 steps, and 20 steps of the
ResNet in 5 s with start-up, where 80 took 77 s two drafts before. And
against the bar, two by two on the T4, each cut at its budget:

| tutorial | budget, 1.5 x torch's | TensorFlow, this draft |
|---|---|---|
| 32 ResNet | 9 s | over, cut at 13 s |
| 33 U-Net | 11 s | over, cut at 14 s |
| 34 transformer encoder | 32 s | over, cut at 35 s |
| 35 GPT | 39 s | over, cut at 40 s |
| 36 VAE | 17 s | over, cut at 19 s |
| 37 GAN | 158 s | over, cut at 160 s |
| 38 GCN | 8 s | over, cut at 13 s |
| 39 RealNVP | 62 s | over, cut at 64 s |
| 40 DDPM | 69 s | over, cut at 72 s |
| 41 seq2seq with attention | 47 s | over, cut at 51 s |

**None of the ten meets the bar.** Each was cut at its budget with its
training unfinished, so the true factor is not known beyond "more than
1.5"; from 20 steps of 32 in 5 s it is about two to three times torch's
on this card. The gate is GREEN and the quality, given the time, is
torch's; the speed is not, yet. The next step is known and not yet
taken: a gradient run already computes the loss's whole closure, so the
loss run before it is a second run for nothing -- fetch the loss and the
new parameters from the gradient's run and a step is ONE session run,
which is where the factor of two lives.

## What is here

`backend.c` is the back end: TensorFlow's C API, wrapped once, in C, as
the operations the predicates ask for — every producer, the answers, the
gradient, the session with its feeds. `coco-tensorflow.cicili` is the
front end: the dispatcher the torch module hands calls to, the arguments
read out of the engine, the answers put back; and the module's own two
predicates, `tensorflow_version/1` and `tensorflow_seed/1`. The seam in
the torch module is `coco_tensor_backend_set`, C linkage, found with
`dlsym` on `torch.so` beside this file at load; the mode is read from
`coco_tensor_graph_mode`.

Every predicate of the surface answers here: `tensor_from_list/2`,
`tensor_to_list/2`, `tensor_shape/2`, `tensor_item/2`, `tensor_new/3`,
`tensor_full/3`, `tensor_eye/2`, `tensor_arange/2`, `tensor_randperm/2`,
`tensor_unary/3`, `tensor_binary/4`, `tensor_scalar/4`, `tensor_agg/3`,
`tensor_reduce/3`, `tensor_argmax/3`, `tensor_reshape/3`, `tensor_cat/3`,
`tensor_index_rows/3`, `tensor_rows/4`, `tensor_cols/4`,
`tensor_standardise/3`, `tensor_parameter/2`, `tensor_step/4`,
`tensor_grad/3`, `tensor_force/1`, `tensor_free/1`,
`tensor_graph_stats/1`, `tensor_load_csv/2` — and through them
`library(tensor_expr)`'s whole grammar, and the tutorials written in it.

## Building, and where

**Linux only, by design.** `sh modules/tensorflow/build.sh` builds
`library/tensorflow.so` against the pip `tensorflow` package — its wheel
carries the C API headers under `include/tensorflow/c` and
`libtensorflow_cc.so.2` beside them — or against a standalone
libtensorflow named by `TF_INCLUDE` and `TF_LIB`. Elsewhere the script
says SKIPPED, as `make modules` reports it; `library(torch)` must be built first.

**Versions this was built and gated against**: TensorFlow **2.20.0** (pip,
Ubuntu 22.04, the Colab VM, where it placed the work on a Tesla T4), with
`library(torch)` on torch **2.11.0+cu128** from pip there. The C API it
uses — `c_api.h` and `eager/c_api.h` — has been stable since TensorFlow 2.x
began, so an earlier 2.x should build; none other was tried.

`test/tensorflow.sh` is the gate: every producer under `(tensorflow,
eager)` within 1e-5 of the torch backend, the least-squares gradient
under `(tensorflow, graph)` equal to torch's, a step, a random leaf read
twice, the shape before anything runs, the refusal under eager, and
tutorial 31's fit on the other library within a tolerance. It SKIPs where
the module is not built, so `make test` is unchanged on a Mac.
