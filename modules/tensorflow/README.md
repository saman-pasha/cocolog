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

## What it costs, measured

The first draft built the graph one predicate at a time and ran a session
per read: eager execution done badly, and quadratic in the steps — 5 s for
20 steps of tutorial 31's fit, 82 s for 100, 360 s for 200, on the Colab
VM, since every step made the graph longer and `TF_AddGradients` walks it
each call. The second draft is the one above, TensorFlow's own idea of a
graph, and the same fit takes 3 s for 200 steps, start-up included —
about 8 ms a step, three session runs — and tutorial 32's ResNet trains
in 74 s. Three refinements it needed on the way, each found by a run
that failed: a node keeps its structure after it has a value only when a
parameter lies under it, or an optimiser's chain of moments holds every
step before it alive and the handle table fills; the shape of a recorded
node comes from a rule per operation rather than from compiling its
prefix, or recording alone compiles thousands of operations; and the keys
are hashed before they are compared. The first draft was the wrong design
and the owner said so; this README keeps the numbers of both so that the
reason stays legible.

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
