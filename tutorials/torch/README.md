# Torch: forty-one networks, one file each

*One of three tutorial categories — `../basics/` is the language,
`../library/` is what ships, and this is the deep end.*

Twenty-four networks, each a PyTorch-tutorial classic rewritten as a
standalone Prolog program against the Torch module. Every file carries
its own documentation and three goals, each meant to run as its OWN
process against the same store, because the trained model lives in the
knowledge base as terms, not in memory:

    ./cocolog --embed /tmp/tutorials run tutorials/torch/01-linear-regression.pl train
    ./cocolog --embed /tmp/tutorials run tutorials/torch/01-linear-regression.pl test
    ./cocolog --embed /tmp/tutorials run tutorials/torch/01-linear-regression.pl predict

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
| 25-char-lm | a character-level language model, trained on cocolog itself |
| 26-char-transformer | the same model as a transformer, and what that does and does not buy |
| 27-induction | where attention actually wins, and the two-layer circuit it needs |
| 28-source-lm | a character model trained on cocolog's own source; `heavy/1` trains on all five groups of it -- the torch lessons and cocolint's own source included -- filling the cap ROUND ROBIN so every group is in every cap, and loads it a file at a time, each inside its own `free_list/2` scope -- a GPU workload, which scales itself down where there is no CUDA device |
| 29-sgd-by-hand | the training loop written in Prolog: tensor_grad/3, tensor_step/4, and weights handed to a model; `heavy/3` is its GPU workload, scaled down where there is no CUDA device |
| 30-two-paths | one program, two execution paths: the same clauses fitted under `eager` and under `graph` in one process, held identical, and what only the graph path can do -- A GPU TUTORIAL: it puts itself on the CUDA device, and without one it says so and stops |
| 31-tensor-expressions | tutorial 30 again, in the syntax the predicates were asking for: `L := mean((X matmul W + B - Y) ^ 2.0)`, with `matmul` an infix operator, one prefix operator per unary predicate, and a DCG, `expr//2`, that turns an expression into the list of tensor goals it stands for -- the same list under both paths -- on six rows |
| 32-resnet | residual blocks as expressions: `relu(H + conv(relu(conv(H))))`, a stem, two blocks, a pool, global average pooling; three shapes in noisy 8x8 pictures; conv2d/3 is nine shifted matmuls in a pixels-as-rows layout |
| 33-unet | down, across, and up with the skip: two levels, `cat/2` joining the upsampled features to the encoder's, a sigmoid per pixel, `bce/2`; a rectangle masked out of noise, judged by IoU |
| 34-transformer-encoder | one encoder block in the open: embeddings, pre-norm multi-head attention through `cols/3` and `cat/2`, the feed-forward, mean pooling; a batch of sequences as ONE score matrix under `block_mask/3`; does a token repeat |
| 35-gpt | the same block under `causal_mask/3` with a head at every position: a character model of a small text, and `predict` continues a prompt greedily, its own output fed back |
| 36-vae | the reparameterisation trick as one expression, `Mu + exp(LogVar * 0.5) * randn(S)`; reconstruction plus KL; a 3x3 walk over the two-dimensional latent plane, decoded and drawn |
| 37-gan | two networks and a loss each, the generator's gradient flowing THROUGH the discriminator; a ring of points; Adam at beta1 0.5 is the one setting that keeps the generator from collapsing onto an arc |
| 38-gcn | a graph convolution is one matmul more than a dense layer, `A X W` with A the normalised adjacency; Zachary's karate club, two labelled members, thirty-two placed by the graph alone |
| 39-realnvp | four affine coupling layers, run forwards for the likelihood and backwards for a sample; two moons; the NLL held against a fitted Gaussian's, and a density stated for a point |
| 40-ddpm | the forward process as a schedule, the network learning the noise, sampling as fifty steps back; the same ring as 37, drawn at three moments of the sampling |
| 41-seq2seq-attention | an encoder GRU, a decoder GRU, and additive attention between them, the GRU cell four expressions; sequences reversed, teacher forcing, the decoder feeding itself at test, and the attention weights printed |

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
`modules/torch/README.md`.
