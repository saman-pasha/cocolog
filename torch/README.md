# The Torch module — libtorch as cocolog predicates

A Prolog program loads a dataset, trains a network on it, and asserts
the trained model into Zigurat. One process, three modules doing what
each is for: **Files** finds and vouches for the data, **Torch** owns
the tensors and the training, and the **knowledge base** — wire or
embedded — is where anything durable goes.

```prolog
train :-
    exists_file('data.csv'),                       % Files
    tensor_load_csv('data.csv', All),              % Torch: [N rows, 4 cols]
    tensor_shape(All, [N, 4]),
    tensor_cols(All, 0, 3, X0),  tensor_cols(All, 3, 4, Y),
    NTrain is (N * 4) // 5,
    tensor_standardise(X0, NTrain, X),
    tensor_rows(X, 0, NTrain, XTr), tensor_rows(Y, 0, NTrain, YTr),
    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),
    model_new([input(3), dense(24, relu), dense(1)], M),
    model_train(M, XTr, YTr, [epochs(150), batch(24), lr(0.01),
                              shuffle(true), final_loss(L)]),
    model_evaluate(M, XTe, YTe, rmse, R),
    model_save(net1, M).                           % into Zigurat, as terms
```

**`tutorials/` holds twenty-three of these programs**, one file per
network -- regression to stacked LSTMs -- each documented in place with
`train`, `test` and `predict` goals meant to run as separate processes
against a store; `test/tutorials.sh` runs them all, and
`test/torch-nets.sh` is the same twenty-three as one fast in-process
suite.

`test/torch.sh` is that program, end to end: it trains (test rmse
≈ 0.03 on its dataset), saves, and a **fresh process** reloads the
model out of the store and reproduces the predictions.

**The north-star sample** is [demo/northstar.pl](../demo/northstar.pl)
over [demo/stars.csv](../demo/stars.csv) — 240 stars of a
Hertzsprung–Russell diagram, four classes. `train` learns the diagram
(held-out accuracy 1.00), asks what kind of star Polaris is, and saves
the model in Zigurat; `polaris`, a fresh process holding nothing but
the store, loads it back and answers again:

```console
$ ./cocolog --embed /tmp/northstar run demo/northstar.pl train
learned the diagram: train nll 0.0001, held-out accuracy 1.00
the model says Polaris is a supergiant
saved
$ ./cocolog --embed /tmp/northstar run demo/northstar.pl polaris
out of the store, the model still says Polaris is a supergiant
the_sky_agrees
```

The North Star is an F7 Ib yellow supergiant, and it sits in the faint,
small corner of that class — the dataset samples every axis
log-uniformly precisely so that corner is populated, and the demo's
first drafts, where it was not, are a lesson the file's comments keep.

## Building

```sh
make           # the ONE cocolog binary carries the torch module
```

It needs libtorch, resolved the way Cicili's `lib/cpp/torch` resolves
it: `$LIBTORCH` pointing at a standalone distribution, or the pip
`torch` package. The module registers through a weak symbol the
interpreter carries either way, so linking it in is all that plugs it
in — and in a binary linked without it the torch predicates would be
unknown procedures, as they should be.

## The predicates

Tensors — handles to float32 tensors; numbers cross as Prolog floats:

| predicate | is |
|---|---|
| `tensor_from_list(+L, -T)` | a list of numbers → `[N]`; a list of rows → `[R,C]` |
| `tensor_to_list(+T, -L)` | the inverse, rows for a matrix |
| `tensor_shape(+T, -Shape)` | the dimensions, as integers |
| `tensor_load_csv(+Path, -T)` | a rectangle of comma/space numbers → `[R,C]` |
| `tensor_rows(+T, +From, +To, -T2)` | rows `[From, To)`, a new tensor |
| `tensor_cols(+T, +From, +To, -T2)` | columns `[From, To)` |
| `tensor_standardise(+T, +NTrain, -T2)` | per column, statistics **from the first NTrain rows only** |
| `tensor_train_test(+T, +NTrain, -Tr, -Te)` | both halves at once |
| `tensor_free(+T)` | lets the handle go |
| `torch_seed(+N)` | libtorch's manual seed |

Models — a network described as terms, the whole layer vocabulary of
`lib/cpp/torch`'s DSL at run time. **The shape flows down the list**:
each layer's input is the previous layer's output, worked out at
`model_new`, so a mismatch is a refusal rather than a runtime surprise.

| layer | is |
|---|---|
| `input(N)` | a flat input of width N |
| `image(C,H,W)` | a picture input; `model_train`/`predict` reshape the flat rows themselves |
| `dense(W[,Act])` | `Linear`; `Act` ∈ relu, tanh, sigmoid, log_softmax, none (default) |
| `conv(F,K[,Act][,pad(P)][,stride(S)])` | `Conv2d`, pad 0 and stride 1 by default |
| `pool(K[,pad(P)][,stride(S)])` | max-pool, stride defaults to the kernel |
| `flatten` | picture → flat C·H·W |
| `dropout(P)` | `Dropout`; off automatically at predict/evaluate time |
| `norm` | `BatchNorm2d`; its running statistics are BUFFERS and travel with `model_params` |
| `sequence(L)` | a row is L steps; plain numbers reach the lstm as `[N,L,1]`, token ids stay `[N,L]` for an embedding |
| `embedding(V,D)` | `Embedding(V,D)`; directly after `sequence(L)`, the steps are integer token ids in `[0,V)` |
| `lstm(H)` | `LSTM(batch_first)`; stacks read the full sequence, the dense head after the last lstm reads its LAST step |

| predicate | is |
|---|---|
| `model_new(+Spec, -M)` | the layer list above |
| `model_train(+M, +X, +Y, +Opts)` | `epochs(N)` `batch(N)` `lr(F)` `optimiser(adam\|sgd)` `loss(mse\|nll\|cross_entropy\|bce)` `shuffle(true\|false)` `schedule(step, Every, Gamma)` `final_loss(-L)` |
| `model_predict(+M, +X, -T)` | forward, gradients off |
| `model_evaluate(+M, +X, +Y, +Metric, -S)` | `rmse`, `accuracy` (argmax vs labels), `mae` |
| `model_spec(+M, -Spec)` | the architecture back as terms |
| `model_params(+M, -L)` | every parameter AND buffer, flattened, as one list of floats |
| `model_set_params(+M, +L)` | the inverse |
| `model_save(+Name, +M)` | `model_spec` + `model_params`, asserted as `torch_model/3` |
| `model_load(+Name, -M)` | `torch_model/3` → `model_new` + `model_set_params` |
| `model_free(+M)` | lets the model go |

`loss(nll)` expects the last layer `log_softmax`; `loss(cross_entropy)`
takes raw logits. Both take integer class labels in `Y` and the module
converts them itself, because a float target failing deep inside
libtorch is the classic trap. `bce` is binary cross-entropy against
probabilities — end the network `dense(1, sigmoid)`.

Tensor operations — four generic predicates carry every family, and the
Coco half spells the friendly names over them:

| generic | ops | sugar |
|---|---|---|
| `tensor_unary(Op, A, C)` | neg abs exp log sqrt relu sigmoid tanh transpose | `tensor_neg/2` … `tensor_transpose/2` |
| `tensor_binary(Op, A, B, C)` | add sub mul div matmul | `tensor_add/3` … `tensor_matmul/3` |
| `tensor_scalar(Op, A, V, C)` | add sub mul div pow | — |
| `tensor_reduce(Op, T, X)` | sum mean max min std → a number | `tensor_sum/2` … `tensor_std/2` |

And the rest: `tensor_new(Shape, zeros\|ones\|randn\|rand, T)` (with
`tensor_zeros/2`-style sugar), `tensor_full/3`, `tensor_arange/2`,
`tensor_eye/2`, `tensor_randperm/2`, `tensor_argmax(T, Dim, T2)`,
`tensor_reshape(T, Shape, T2)`, `tensor_cat(TList, Dim, T2)`,
`tensor_index_rows(T, IdxT, T2)`, `tensor_item(T, X)`.

The device — one process-wide choice, made before `model_new`:

| predicate | is |
|---|---|
| `torch_device(+D)` | `cpu`, `cuda`, `cuda(N)`, or `auto` (cuda if available, else cpu) |
| `torch_cuda_available(-A)` | `true` or `false` |
| `torch_cuda_count(-N)` | how many CUDA devices libtorch sees |
| `torch_current_device(-D)` | `cpu` or `cuda(N)` |

`torch_device(cpu)` and `torch_device(auto)` always succeed. Naming
`cuda` (or an index) on a machine without it throws
`domain_error(cuda_available, ...)` — a refusal, never a silent
fallback, because "trained on the GPU" and "quietly trained on the CPU"
are different results. A model is built on whatever the device was at
its `model_new`, and its training batches follow it there.

The device never leaks into the term seam: tensor handles stay
CPU-side, `model_params` comes back through the CPU, and predictions
land as CPU tensors — so a model saved on a GPU box reloads onto
whatever device the next process chose, and `test/torch.sh`'s stored
predictions agree across machines.

## Handles are not terms — and that is the design

A tensor or model handle is an integer naming a process-local C++
object. It is deliberately **not** part of any machine's state: a
suspended machine carrying one finds it meaningless where it thaws,
exactly as it would a file descriptor. What suspends and what persists
is the model **as terms** — `model_spec/2` and `model_params/2` — and
`model_save/2` is nothing but those two and an assert. The knowledge
base does the rest, which is why a model saved against `--embed` (or a
server) is simply *there* for the next process.

## Where this sits

The C half is one Cicili C++ target, `coco-torch.cicili`: cocolog's
module API declared extern-C at its head, the predicates implemented
over Cicili's `lib/cpp/torch` declarations, the dispatcher and the
Coco half (`model_save`, `model_load`, `tensor_train_test`) at its
foot. The dynamic network is what `lib/cpp/torch`'s DSL builds at
expansion time, built at run time instead — same loop: per epoch one
permutation, per batch one gather, `zero_grad / forward / loss /
backward / step`.
