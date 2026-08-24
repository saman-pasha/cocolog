# Torch tutorials, one file each

Twenty-four networks, each a PyTorch-tutorial classic rewritten as a
standalone Prolog program against the Torch module. Every file carries
its own documentation and three goals, each meant to run as its OWN
process against the same store, because the trained model lives in the
knowledge base as terms, not in memory:

    ./cocolog-full --store /tmp/tutorials run tutorials/01-linear-regression.pl train
    ./cocolog-full --store /tmp/tutorials run tutorials/01-linear-regression.pl test
    ./cocolog-full --store /tmp/tutorials run tutorials/01-linear-regression.pl predict

`train` builds the data, fits the network, and `model_save`s it;
`test` `model_load`s it back and judges it against a threshold, exiting
nonzero on failure; `predict` loads it and answers for a few visible
inputs beside the truth. Data is generated in-file and deterministic
(a fixed `torch_seed` and a sin-hash noise), so nothing is downloaded
and every run agrees with the last.

| file | teaches |
|---|---|
| 01-linear-regression | one dense unit, mse, sgd |
| 02-multi-feature-regression | held-out testing, adam |
| 03-polynomial-features | feature engineering vs capacity |
| 04-sine-approximation | tanh hidden layer, universal approximation |
| 05-relu-approximation | relu hinges, depth |
| 06-logistic-regression | sigmoid head, bce, hand-counted accuracy |
| 07-xor | why the hidden layer exists |
| 08-two-moons | curved boundaries |
| 09-four-blobs | multiclass, nll, argmax accuracy |
| 10-spiral | depth, raw logits under cross_entropy |
| 11-dropout | regularisation, and OFF at predict time |
| 12-lr-schedule | step decay over plain sgd |
| 13-robust-mae | outliers, and judging by mae |
| 14-autoencoder | the 8-3-8 bottleneck |
| 15-denoising | noisy in, clean out |
| 16-multi-output | two targets in one head |
| 17-cnn-bars | conv, pool, flatten |
| 18-mini-lenet | two conv stages, shape flow |
| 19-batch-norm | buffers vs parameters |
| 20-save-load | what a model IS in the store |
| 21-lstm-sum | sequence input, recurrent accumulation |
| 22-embedding-lstm | token ids, embeddings, memory |
| 23-stacked-lstm | recurrent depth, weights through the store |
| 24-q-learning | reinforcement learning: fitted Q-iteration on a gridworld |

One cocolog property every file here respects: `run` CONSULTS the file
into the knowledge base, and the knowledge base is the store -- so the
second goal's process consults the same clauses AGAIN, and consulting
appends. A predicate defined once in the file exists twice in the second
process. For the goals that only matters as a duplicate solution nobody
asks for; for a data generator inside a findall it would double the rows
-- or, with a nondeterministic helper inside an inner findall, WIDEN
them. Every single-clause data helper here therefore ends in a cut,
which makes the first (and every) copy deterministic. Two tutorials
sharing a store would still shadow each other's train/test/predict, so
the runner gives each tutorial a store of its own.

`test/tutorials.sh` runs all three goals of every file against a
throwaway store per tutorial; `test/torch-nets.sh` is the same twenty-three networks
as one fast in-process suite. The module itself is documented in
`torch/README.md`.
