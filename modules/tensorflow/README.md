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
3. *Trained on TensorFlow, tested on torch?* Yes, and run: tutorial 31
   trained under `(tensorflow, graph)`, then tested under `(torch, graph)`
   and predicted under `(torch, eager)` from the same store, rmse 0.0018;
   32's ResNet trained on TensorFlow and tested on torch, accuracy 1.00.
   Two caveats: only the `tensor_*` programs, 29 onward, are portable --
   1 to 28 use libtorch's `model_*` modules, which have no TensorFlow side;
   and the two libraries agree within float tolerance, not bit for bit, and
   draw different random numbers from one seed, so weights trained on each
   differ.

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
call a step — and adds the eager gradient. **Its T4 numbers are not yet
taken**: the VM went before it was written, and the bar is a T4 bar. What
is measured is a Mac's CPU, TensorFlow 2.21.0 from Homebrew (a build
without AVX2/FMA, as it says at start) against libtorch 2.13.0, the same
files, `train` then `test`, wall-clock seconds including start-up:

| tutorial | torch, CPU | TensorFlow, CPU | quality on TensorFlow |
|---|---|---|---|
| 31 tensor expressions | 200 steps eager and graph, identical | identical, both paths | rmse 0.0018 |
| 32 ResNet | 3 s + 1 s | 4 s + 1 s | test accuracy 1.00 |
| 33 U-Net | 4 s + 1 s | 4 s + 1 s | test IoU 0.865 (torch 0.903) |
| 34 transformer encoder | 18 s + 1 s | 16 s + 1 s | test accuracy 1.00 |
| 35 GPT | 30 s + 2 s | 26 s + 2 s | next-character accuracy 0.87 |
| 36 VAE | 8 s + 1 s | 8 s + 1 s | reconstruction pixel accuracy 1.000 |
| 37 GAN | 123 s + 1 s | 69 s + 1 s | 0.95 within 0.15 of the ring, 12 of 12 sectors |
| 38 GCN | 1 s + 2 s | 2 s + 1 s | 33 of 34 members, 0.971 |
| 39 RealNVP | 79 s + 1 s | 23 s + 1 s | NLL 0.545 against a Gaussian's 1.932 (torch 0.649) |
| 40 DDPM | 42 s + 1 s | 35 s + 1 s | 0.91 within 0.15 of the ring, 12 of 12 sectors |
| 41 seq2seq with attention | 19 s + 0 s | 16 s + 1 s | token accuracy 0.97 (torch 0.98) |

Every `test` above says ok, its threshold met. The T4 row for each waits
for the next VM. The road here was four drafts, each
found wrong by a run. The first built the graph one predicate at a time
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

**Linux only, by design.** `sh modules/tensorflow/build.sh` builds
`library/tensorflow.so` against the pip `tensorflow` package — its wheel
carries the C API headers under `include/tensorflow/c` and
`libtensorflow_cc.so.2` beside them — or against a standalone
libtensorflow named by `TF_INCLUDE` and `TF_LIB`. Elsewhere the script
says SKIPPED, as `make modules` reports it; `library(torch)` must be built first.

**Versions this was built and gated against**: TensorFlow **2.20.0** (pip,
Ubuntu 22.04, the Colab VM, where it placed the work on a Tesla T4), with
`library(torch)` on torch **2.11.0+cu128** from pip there; and, for this
draft's gate on a Mac's CPU, libtensorflow **2.21.0** from Homebrew, by a
hand build of the same two files against its `include` and `lib` — the
module is plain C over the C API, which is why that works, and the script
stays Linux only on purpose. The C API it uses — `c_api.h` and
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
