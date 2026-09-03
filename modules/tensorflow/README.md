# The TensorFlow module — the tensor predicates over TensorFlow's C library

`library(tensorflow)` is the SECOND BACKEND of the `tensor_*` predicates.
`library(torch)` owns the predicates and the switch,
`tensor_execution(Backend, Mode)`; this module registers itself with it
at load, and while `tensor_execution(tensorflow, _)` is in force every
`tensor_*` call is handed here. One surface, two implementations, never
both at once; the `model_*` predicates stay libtorch's.

```prolog
:- use_module(library(torch)).          % first: the predicates and the switch are its
:- use_module(library(tensorflow)).     % attaches to torch.so beside itself
?- tensor_execution(tensorflow, graph). % from here, every tensor_* is TensorFlow's
?- tensor_execution(B, M).              % B = tensorflow, M = graph
?- tensorflow_version(V).               % V = '2.20.0'
```

## Two modes, one mechanism

| `tensor_execution(tensorflow, …)` | what a producer does | gradients |
|---|---|---|
| `eager` | a `TFE_Execute`, now, on the device; a handle holds a `TFE_TensorHandle`. A producer that a PARAMETER reaches also RECORDS what it did — the operation, its attributes, its inputs — which is the tape | the recorded structure, compiled and differentiated as below; the forward pass is recomputed inside the gradient's call |
| `graph` | only records; a read runs what it needs | the same, and one call a step computes the loss, the gradients and the new parameters together |

Under both, a read of a recorded tensor and a gradient collect the CLOSURE
of what they need — the nodes down to the values they rest on — key it by
structure, and the first time a key is seen compile it, once: a `TF_Graph`
of placeholders and operations, `TF_AddGradients` over it for a gradient
(TensorFlow's own symbolic differentiation), and the whole made a
TensorFlow FUNCTION the eager runtime calls, with the leaves' handles as
its arguments and handles as its results. Nothing crosses to the host: a
parameter lives on the device and the function that steps it finds it
there, which is what `tf.function` is, done from C. Every later time the
same key is one call. So a program is the same program on either path,
and the same program it is on `library(torch)`: tutorial 31 fits eager
then graph in one process and checks the two IDENTICAL, on either
library, and the file never names one.

The graph grows with the DISTINCT SHAPES OF COMPUTATION a program has,
not with its steps, and `tensor_graph_stats/1` counts nodes recorded,
nodes given a value, and calls that were REPLAYS of a compiled key. A
node keeps its structure after it has a value only while a parameter is
under it, so a loss read by `item` can still be differentiated by `grad`
after it; a node with none under it — an optimiser's moments, a metric —
is a value and lets its inputs go; a parameter made by `tensor_step/4` is
a boundary, a value and nothing behind it; and a node the program has
dropped but the tape still holds keeps its recipe and lets its VALUE go,
since a gradient recomputes it from the leaves. Which nodes of a closure
are RESULTS of the call — the ones the program still names, the
parameters, the one asked for — is part of the key, because a function's
outputs are fixed when it is made. Under `graph` a shape is known with
nothing executed (by rule at the record, or `TF_GraphGetTensorShape` on
the compiled closure), a shape error is refused at the goal that adds the
operation, and a random leaf — `randn`, `rand`, `randperm` — draws ONCE,
through the eager context, and is a value: a random operation in a graph
would redraw at every run, and a leaf read twice would not be one leaf.
The draws are the STATELESS random ops, seeded by the seed and the draw's
number, so `tensorflow_seed/1` set again gives the draws again — the
stateful ones keep a generator per seed in the eager runtime and would
continue their stream.

The device is the third argument of the switch,
`tensor_execution(tensorflow, Mode, cpu | cuda | auto)`: every operation
and every call is pinned to it, a float made on the host goes to it at
birth, and `auto` -- the default -- takes the first GPU when there is one.
`cuda` on a machine without one runs on the CPU and says so on stderr. The
choice governs what the NEXT producer does; a value already made stays
where it is, and is copied when an operation on the other device reads it.

## Where a model trains, and where it runs

Three questions the owner asked, answered by runs:

1. *Trained under `graph` on a GPU, predicting under `eager` on a CPU?*
   Yes. `params_save` writes each parameter as its shape and its numbers
   into the knowledge base, and `params(Name)` rebuilds them on whatever
   backend, device and mode are current when it loads, so a store belongs
   to no library and no device. The device is the switch's third argument,
   `tensor_execution(Backend, Mode, cpu | cuda | auto)`, on either library
   and independent of the mode: `auto` takes cuda when there is one, and
   `cuda` on a machine without one runs on the CPU and says so.
2. *Is `eager` the way to hand work to the GPU and keep the CPU free?* No:
   `eager` and `graph` are about WHEN, not WHERE, and either mode runs on
   either device. Eager computes each goal as it runs, so a value or a
   shape is readable at any point and an error surfaces at its goal --
   preprocessing, prediction, debugging. Graph records and makes one
   compiled call a step, so the CPU does the least driving. Handing work to
   the GPU is the third argument, and graph relieves the CPU more than eager
   does, one call standing for hundreds of launches.
3. *Trained on TensorFlow, tested on torch, and the reverse?* Yes, both
   ways, and run: tutorial 31 trained under `(tensorflow, graph)`, then
   tested under `(torch, graph)` and predicted under `(torch, eager)` from
   the same store, rmse 0.0018, and trained on torch, tested and predicted
   on TensorFlow, rmse 0.0011; 32's ResNet trained on either and tested on
   the other, accuracy 1.00 both ways.
   Two caveats: only the `tensor_*` programs, 29 onward, are portable --
   1 to 28 use libtorch's `model_*` modules, which have no TensorFlow side;
   and the two libraries agree within float tolerance, not bit for bit, and
   draw different random numbers from one seed, so weights trained on each
   differ.
4. *Is the difference between `eager` and `graph` only the gradient?* No:
   both differentiate, on both libraries. The difference is WHEN work
   runs. Eager executes each producer as its goal runs, so every handle has
   a value at once; graph records, and nothing runs until a read, when the
   whole closure -- a training step's loss, gradients and new parameters --
   is compiled once per structure and thereafter runs as ONE call (torch:
   a lazy graph with CUDA-graph replay; TensorFlow: one function). What
   follows from that: on a GPU graph is the faster path, since one call
   stands for hundreds of launches and the CPU drives less; under graph
   the intermediates a program never names are never kept, so it holds
   less; a runtime error surfaces at the read rather than at the goal
   (shape errors are refused at the goal under both, by rule); and under
   TensorFlow eager a gradient recomputes its forward pass inside the
   gradient's call, a cost graph does not pay. `tensor_graph_stats/1`
   shows the two: recorded and replayed count under graph, executed
   under eager.

## What it costs, measured, against the bar

The owner's bar for a second backend is plain: a tutorial under
TensorFlow must finish within 1.5 times the seconds torch took for it on
the same T4. **The draft before this one did not meet it**, on any of
the ten, each cut at its budget with training unfinished: about two to
three times torch's, at a GPU utilisation near zero — the time was the
host round trip, every leaf fed from host memory and every result fetched
back each step, and two session runs a step, the loss and then the
gradient. What it did meet: the gate, and quality, since 32's ResNet
trained to test accuracy 1.00 and 33's U-Net to IoU 0.917 on this
library, the same files, when given the time.

This draft, the fourth, takes both away — device-resident handles, one
call a step — and adds the eager gradient. **On the T4 it meets the bar
on the nine tutorials that compute for longer than a few seconds, within
1.05 times torch or under it, and misses it on the two shortest by a
process start-up.** The same files, `train` then `test` under
`tensor_execution(Backend, graph, auto)`, wall-clock seconds including
start-up, each pair one after the other on a Colab VM — a Tesla T4,
two host cores, torch 2.11.0+cu128 and TensorFlow 2.20.0 from pip —
with the GPU's utilisation sampled once a second while each ran:

| tutorial | torch, T4 | TensorFlow, T4 | GPU busy, torch / TensorFlow | quality, torch / TensorFlow |
|---|---|---|---|---|
| 31 tensor expressions | 2 s + 1 s | 3 s + 2 s | 3% / 3% | rmse 0.0011 / 0.0018; eager and graph identical on both |
| 32 ResNet | 4 s + 2 s | 6 s + 2 s | 8% / 9% | test accuracy 1.00 / 1.00 |
| 33 U-Net | 5 s + 2 s | 5 s + 2 s | 8% / 8% | test IoU 0.903 / 0.865 |
| 34 transformer encoder | 20 s + 1 s | 20 s + 2 s | 13% / 11% | test accuracy 1.00 / 0.97 |
| 35 GPT | 24 s + 2 s | 23 s + 4 s | 13% / 11% | next-character accuracy 0.87 / 0.87 |
| 36 VAE | 11 s + 1 s | 12 s + 2 s | 9% / 9% | reconstruction pixel accuracy 1.000 / 1.000 |
| 37 GAN | 106 s + 1 s | 102 s + 2 s | 11% / 10% | 0.95 / 0.95 within 0.15 of the ring, 12 of 12 sectors |
| 38 GCN | 3 s + 1 s | 4 s + 2 s | 2% / 2% | 32 / 33 of 34 members, 0.941 / 0.971 |
| 39 RealNVP | 40 s + 1 s | 35 s + 2 s | 11% / 8% | NLL 0.645 / 0.525 against a Gaussian's 1.932 |
| 40 DDPM | 46 s + 1 s | 48 s + 2 s | 9% / 6% | 0.87 / 0.91 within 0.15 of the ring, 12 of 12 sectors |
| 41 seq2seq with attention | 28 s + 1 s | 27 s + 2 s | 16% / 14% | token accuracy 0.98 / 0.97 |

Every `test` says ok. Neither library keeps the T4 busy, at a tenth or
less: every tensor here is kilobytes, a step is dozens of launches, and
the Prolog that composes them runs on the VM's two host cores, as the
torch table in the main README found before. On 31 and 38, three and four
seconds of training, TensorFlow reads 1.7 to 1.9 times torch, measured
to the millisecond, and the profile says where: the first call of a
closure that uses a kernel for the first time pays for loading it —
0.5 s for 38's forward, 0.7 s for its gradient, 1.2 s for 34's first
forward — a cost per process that torch pays less of, and that two
hundred steps of a two-second tutorial cannot spread. Turning Grappler
off changed nothing; a smaller start would need the library to load less.

**The first run on the T4 met the bar on none of them**, and the calls
were not the reason. `COCO_TF_TRACE=1` prints a line per call and, at
exit, what the run cost by phase — calls, closures, compiles, device
copies, eager operations, reads — and put tutorial 34's calls at
6.7 s of its 31 s and its 101,721 device copies at 7.9 s: Adam makes
seven scalar operands per parameter per step, the betas, the epsilon,
the corrected rate, and each was a host tensor copied to the device at
birth. A scalar value is one device tensor now, shared by every slot
that holds it, and a step copies its corrected rate and nothing else: 34
fell from 31 s to 20 s, 36 from 19 s to 13 s. `COCO_TF_XLA=N` compiles a
closure with XLA after its Nth call; on the T4 it took a fifth off the
calls and little off the total, and is left as the measured knob it is.
And before either library could be measured, torch had to be fixed:
under `auto` it set its device to `cuda` with no index, every tensor
lives on `cuda:0`, and torch's comparison of the two said different —
so each parameter was re-made a detached leaf at every touch, and thirty
tutorials trained to chance without one error. `cuda`, index 0, compared
equal, which is why every gate had passed. The test is by type now, and
a parameter read twice under `auto` is in `test/torch-grad.sh`.

The same on a Mac's CPU, TensorFlow 2.21.0 from Homebrew (a build
without AVX2/FMA, as it says at start) against libtorch 2.13.0, the same
files and goals, each pair measured one after the other on an otherwise
idle machine:

| tutorial | torch, CPU | TensorFlow, CPU | quality, torch / TensorFlow |
|---|---|---|---|
| 31 tensor expressions | 1 s + 0 s | 1 s + 1 s | rmse 0.0011 / 0.0018; eager and graph identical on both |
| 32 ResNet | 4 s + 1 s | 3 s + 1 s | test accuracy 1.00 / 1.00 |
| 33 U-Net | 4 s + 1 s | 4 s + 1 s | test IoU 0.903 / 0.865 |
| 34 transformer encoder | 16 s + 1 s | 15 s + 1 s | test accuracy 1.00 / 1.00 |
| 35 GPT | 25 s + 2 s | 23 s + 2 s | next-character accuracy 0.87 / 0.87 |
| 36 VAE | 7 s + 1 s | 7 s + 0 s | reconstruction pixel accuracy 1.000 / 1.000 |
| 37 GAN | 134 s + 1 s | 65 s + 1 s | 0.95 / 0.95 within 0.15 of the ring, 12 of 12 sectors |
| 38 GCN | 1 s + 1 s | 1 s + 1 s | 32 / 33 of 34 members, 0.941 / 0.971 |
| 39 RealNVP | 85 s + 1 s | 24 s + 1 s | NLL 0.649 / 0.545 against a Gaussian's 1.932 |
| 40 DDPM | 45 s + 1 s | 41 s + 1 s | 0.86 / 0.91 within 0.15 of the ring, 12 of 12 sectors |
| 41 seq2seq with attention | 21 s + 1 s | 18 s + 1 s | token accuracy 0.98 / 0.97 |

Every `test` here says ok too; on this CPU TensorFlow is at or under
torch's time on all eleven, and well under on the two that run longest,
the GAN and the flow. The road here was four drafts, each found wrong
by a run. The first built the graph one predicate at a time
and ran a session per read: quadratic in the steps, 360 s for 200 steps
of tutorial 31's fit. The second keyed and compiled closures, but forced
every step's result at once — twenty session runs a step for a
transformer — and let an optimiser's moments hold every step before them
alive, until the handle table filled forty steps into 32. The third made
a step a boundary, kept structure only under a parameter, took shapes by
rule, hashed the keys, fed a scalar as data rather than keying its value
(Adam's bias-corrected rate changes every step, and each step was a new
key), and set `allow_growth`, so TensorFlow held 185 MiB at rest instead
of the whole card — the 13.8 GB the owner read, rightly, as the sign of a
problem, was the allocator's habit hiding the graph's growth. It still fed
and fetched through the host, ran the loss and the gradient as two
sessions, and had no eager gradient at all, the C eager API having no
tape. The fourth is above.

## What is here

`backend.c` is the back end: TensorFlow's C API, wrapped once, in C, as
the operations the predicates ask for — every producer, the answers, the
closure, its key, its compilation and its call as a function of the eager
runtime, the gradient. `coco-tensorflow.cicili` is the front end: the
dispatcher the torch module hands calls to, the arguments read out of the
engine, the answers put back; and the module's own two predicates,
`tensorflow_version/1` and `tensorflow_seed/1`. The seam in the torch
module is `coco_tensor_backend_set`, C linkage, found with `dlsym` on
`torch.so` beside this file at load; the mode is read from
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

`sh modules/tensorflow/build.sh` builds `library/tensorflow.so`: on Linux
against the pip `tensorflow` package — its wheel carries the C API headers
under `include/tensorflow/c` and `libtensorflow_cc.so.2` beside them — on
macOS against Homebrew's `libtensorflow`, the C library and its headers;
anywhere against a standalone libtensorflow named by `TF_INCLUDE` and
`TF_LIB`. Where none is found the script says SKIPPED, as `make modules`
reports it; `library(torch)` must be built first, since this module
attaches to `torch.so` beside itself.

**Versions this was built and gated against**: TensorFlow **2.20.0** (pip,
Ubuntu 22.04, the Colab VM, where it placed the work on a Tesla T4), with
`library(torch)` on torch **2.11.0+cu128** from pip there; and, on a
Mac's CPU, libtensorflow **2.21.0** from Homebrew, where this draft's gate
and every tutorial ran. The module is plain C over the C API, which is
why one build script serves both. The C API it uses — `c_api.h` and
`eager/c_api.h`, with `TF_GraphToFunction` and `TFE_ContextAddFunction`
— has been stable since TensorFlow 2.x began, so an earlier 2.x should
build; none other was tried.

`test/tensorflow.sh` is the gate: every producer under `(tensorflow,
eager)` within 1e-5 of the torch backend; under `(tensorflow, graph)` the
least-squares gradient equal to torch's, a step, a parameter the loss
never reached, the shape before anything runs and a shape error refused;
under `(tensorflow, eager)` the same gradients, a loss read by `item`
first still differentiating, a gradient twice of one loss; and tutorial
31's fit on this library IDENTICAL across its two paths and within a
tolerance of torch's numbers. It SKIPs where the module is not built, so
`make test` is unchanged on a Mac without the hand build.
