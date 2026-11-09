# Building a small language model with cocolog: a grounded plan

Status of this document: a plan, **not** a result. It was written from reading
the cocolog repository (README, `modules/torch/README.md`, `library/tensor_expr.pl`,
`tutorials/tensor/35-gpt.pl`, `colab/COLAB.md`, `CLAUDE.md`, `STATUS.md`). Nothing
here was built or run. Every predicate named below was checked to exist in the
repo; whether it is fast enough or correct enough at the sizes proposed is
**unmeasured**, and each phase has an acceptance test so that gets measured early.

It replaces the earlier "four-pillar" LLM spec. That spec used predicates that
exist nowhere in the repo (`ccl_forward_pass`, `cocolog_current_state`,
`kbs_put_job`, `ModelPool`, ...), a decoder that could not run, and a storage
design the repo's own tensor docs argue against. Section 2 lists the fixes.

---

## 1. Goal and honest scope

| Tier | What | Verdict |
|---|---|---|
| A | Toy GPT: char-level, one block, trains in seconds | **Exists** (`tutorials/tensor/35-gpt.pl`) |
| B | Small real LM: BPE tokens, 1-20 M parameters, GPU-trained, Prolog sampler and constrained decoder | **Realistic**, this plan |
| C | Run someone else's pretrained weights (GPT-2, Llama class) | **Not supported.** No safetensors/GGUF loader found in the repo; would need a new module |
| D | Competitive, billions of parameters | **Out of scope** for this design (storage, compute and training-data limits, section 6) |

The honest pitch for Tier B is not "faster than PyTorch". It is: *a language model
whose weights, corpus, sessions and decoding rules are all ordinary facts and
clauses in one durable knowledge base*, with grammar-constrained generation
written as Prolog. That is what cocolog is distinctively good at.

## 2. Corrections to the earlier spec

| Earlier spec said | Reality in the repo | Use instead |
|---|---|---|
| Cicilang `.cpp` kernel with `own`/`tie`, built by `cicilang++` | Cicili is S-expression syntax; the shipped kernel was plain C++ with a naive triple-loop matmul | libtorch through `library(torch)`; write a Cicili module only if a missing op is needed (section 4, phase 3) |
| KV-cache and weights as `Text` columns in a Parsi table | Rows must fit a page; the repo stores tensors as `Vector<Double>` rows of 512 doubles, not text | `params_save/2`, `model_save/2` |
| KV-cache in the database | Tensor handles are process-local integers and are "deliberately not part of any machine's state" | Keep the KV cache in process memory; persist **token ids** only and rebuild the cache by prefill on resume |
| Freeze the whole machine (~15 KiB) to migrate an LLM session | A frozen machine holding a tensor handle finds it meaningless on thaw | Persist session state as facts (token ids, seed, step); use freeze only for agent proofs |
| `call_metered(Goal, Steps)` | It is `call_metered/4`: `call_metered(Goal, Limit, Used, Result)` | See `test/meter.pl` |
| Gas/consensus as "bit-exact" inference | An inference count is comparable within one engine only, excludes native tensor work, and GPU float math is not bit-exact across devices | Treat metering as a Prolog-step budget, nothing more |
| `top_p_filter` over raw logits returning "the first logit" as the token | Not a sampler | Section 4, phase 3 |
| `phrase(valid_json_response(_), PartialTokens)` after every token | Fails at token 1: a prefix is not a complete object | Prefix-viability state machine plus logit mask |
| `cocolog -g "..."` | Documented entry points are `-s FILE`, `run FILE GOAL`, `query GOAL` | Use those |

## 3. Architecture (three layers, not four)

```
 corpus (text)                                         client prompts
     |                                                       |
 [Prolog] tokenizer: encode/decode, BPE merges as facts      |
     |                                                       v
 token ids ---> [tensor files / KB rows]            [Prolog] session + sampler
                      |                                 |   ^   (temperature, top-k/p,
                      v                                 |   |    grammar mask)
              [libtorch via library(torch) + tensor_expr]  |   |
                 forward / grad / Adam  <-- weights as doubles in the KB
                      |                                 |
                      +---- params_save / params_load --+
                                     |
                  ZiguratIP store (--embed DIR, or server) = durable state
```

- **Compute:** libtorch (CPU or CUDA) through `library(torch)` and `library(tensor_expr)`.
- **Orchestration and decoding:** cocolog clauses. Tokenizer, training loop, sampler, grammar masks, session handling.
- **State:** the knowledge base. Weights (`params_save`), corpus ids, merges, sessions, eval logs.
- **Deliberately dropped from the critical path:** custom LLVM kernels and the blockchain/gas layer. They return as optional research items (phase 7).

## 4. Phases

Each phase ends with something that either passes or fails. Do not start the next
phase on a failed gate.

### Phase 0: Baseline (half a day)

Run the toy GPT and record numbers on your machine.

```sh
./cocolog --embed /tmp/tutorials run tutorials/tensor/35-gpt.pl train
./cocolog --embed /tmp/tutorials run tutorials/tensor/35-gpt.pl test
./cocolog --embed /tmp/tutorials run tutorials/tensor/35-gpt.pl predict
```

Also record `torch_cuda_available/1`, `torch_cuda_count/1`, wall-clock per
training step, and CPU vs GPU.

- **Gate:** the tutorial's own check passes (next-character accuracy at least 0.5 on unseen windows). Note the step time; every later estimate scales from it.
- **Read first:** `tensor_expr` is the path this tutorial uses (`:=`, `exec/1`, `adam_step/6`, `causal_mask/3`, `params_save/2`). It trains on **every position** with a causal mask. The `model_new([... attention(H), ffn(W) ...])` layer DSL is easier but its dense head reads the **last** position only, so it is the wrong tool for a language model.

### Phase 1: Tokenizer (1-2 weeks)

1. Start with a **byte or small-character vocabulary** (fixed alphabet, `id/2` both ways, as the tutorial does). Get the whole pipeline working before touching BPE.
2. Then BPE: learn merges **offline once**, store them as facts `merge(Rank, A, B, AB)`, and write `encode/2` and `decode/2` as clauses.
3. Tokenise the corpus **once**, write ids to a file, load with `tensor_load_csv/2` (or store as rows). Do not re-tokenise in the training loop.

- **Gate:** `decode(encode(Text)) == Text` over a held-out text set, including Unicode and empty input, written as a `check/3` case in `test/` style.
- **Risk:** Prolog BPE encoding speed on large corpora. Measure on 10 MB before committing to vocabulary size.

### Phase 2: Train a small GPT on real data (2-4 weeks)

Generalise `35-gpt.pl`: N layers, H heads, width D, context length T, vocabulary V,
all parameters. Keep the structure (pre-norm blocks, residuals, causal mask, GELU,
final layer norm, loss at every position).

What exists to build on: `adam_init/2`, `adam_step/6`, `sgd_step`, `cross_entropy`,
`layer_norm`, `gelu`, `softmax`, `index_rows`, `cat`, `params_save/2`,
`params_load/2`, `torch_seed/1`.

What the repo does **not** have (searched, not found), so budget for each:

| Missing | Why it matters | Workaround |
|---|---|---|
| Gradient clipping | Training instability on deeper models | Compute grad norm with tensor ops and scale in Prolog, or add an op to `modules/torch` |
| Weight decay / AdamW | Regularisation | Add decay to `adam_step` in Prolog |
| top-k / multinomial / cumsum | Sampling (phase 3) | Phase 3 |
| Mixed precision | Memory and speed | None; tensors are float32. Stay small |

Scale ladder, advancing only when the previous rung's gate passes:

1. 0.1 M parameters (like the tutorial, real corpus): proves the data path.
2. 1 M parameters.
3. 10 M parameters on a single 16 GB GPU (the Colab arrangement in `colab/COLAB.md` is the existing route: train on Colab, publish read-only over Zeytun, query from anywhere).

Checkpoint with `params_save/2` every K steps, then run `cocolog vacuum` after each
checkpoint burst, since each save leaves dead MVCC versions behind (README: a worked
store slows down).

- **Gate per rung:** validation loss clearly below a unigram and a bigram baseline computed in Prolog on the same split; training loss decreasing; a fixed-seed run reproduces its loss curve on the same machine.
- **Open question to settle in phase 0:** the training loop is a Prolog loop issuing libtorch calls. Measure its per-step overhead against the GPU kernel time. The README's CUDA-graph replay applies to forwards that **do not hold a parameter** (a closure holding a parameter is never captured), so it speeds up **inference**, not training.

### Phase 3: Inference and decoding (2-3 weeks)

**3a. Sampling.** `tensor_argmax/3` is the only selection op found. Two routes:

- Start in Prolog: `tensor_to_list` the last-position logits, then temperature, softmax, top-k or top-p, and sample with `random_float`. Fine for vocabularies up to a few thousand; slow for 32k+ per token.
- Then add `tensor_topk/..` and `tensor_multinomial/..` to `modules/torch` as a Cicili binding over libtorch. The repo rule is that a module comes only from a C/C++ API declared in a Cicili binding, never C pasted into `(code "...")`.

**3b. KV cache.** The tutorial recomputes the whole 8-token window every step. For
longer contexts, keep per-session key/value tensors as handles inside one process.
Persist only the token id list. On resume, prefill by running the prompt once.
Never put a cache in the database.

**3c. Constrained decoding.** The earlier idea of validating a full DCG parse after
each token cannot work. Do this instead:

1. Write the target format (JSON schema, SQL subset, ...) as a **deterministic state machine** over bytes: `next_state(State, Byte, State1)`.
2. Per step, for each candidate token, run its bytes through the machine from the current state; allowed tokens are those that do not hit a dead state.
3. Add a large negative number to disallowed logits (a tensor built from the allowed set, added inside the `softmax(...)` expression) and renormalise.
4. Keep a DCG over the **finished** output as a final validator.

- **Gate:** 1,000 fixed-seed generations under the JSON grammar all parse with a standard parser; with the mask off, a measurable fraction do not (that fraction is the evidence the mask matters). Throughput measured with and without the mask.

### Phase 4: Sessions and persistence (1-2 weeks)

- Weights: `params_save/2` into the store (`--embed DIR` for one process, the server for several). Doubles, 512 per row.
- Session: facts such as `session(Id, Seed, TokenIds)`. A few hundred bytes. Resume = reload weights, prefill, continue.
- Agent loops that are genuinely nested proofs can use the real machine suspend/resume (`cocolog --kb NAME start JOB "goal"`, then `step JOB` in any process). Do not freeze a machine for plain generation.
- Several workers: `library(cowork)` and the accumulator/balancer patterns in `coworker/`.

- **Gate:** kill the process mid-generation, restart, resume from stored token ids and seed, and get byte-identical continuation on the same device.

### Phase 5: Evaluation and regression (continuous)

- Held-out perplexity logged as facts after each checkpoint.
- Golden sample prompts with fixed seeds as `test/` cases (CPU only, tolerance not equality across devices).
- Per the repo's own testing notes: pass a case alone first, then the suite; the lint case runs before the suite.

### Phase 6 (optional): compare against a hosted model

`library(llm)` is a **client** for hosted model APIs (`llm_chat/2,3`, `llm_json/4`),
not an LLM implementation. Use it as a reference oracle: same prompts, compare
outputs and grammar-validity rates. It needs libcurl and a key.

### Phase 7 (optional research, only after Tier B works)

- Custom fused attention as a Cicili C++ module over libtorch/CUDA, if profiling shows the Prolog-driven op sequence is the bottleneck.
- Multi-node verification and gas (The Coco). Do not claim bit-exact verification of GPU output. A deterministic **CPU** reference path, or a tolerance-based check, is the honest version.

## 5. Milestone summary

| Phase | Deliverable | Gate |
|---|---|---|
| 0 | Baseline numbers | Tutorial passes; step time recorded |
| 1 | Tokenizer + tokenised corpus | Exact round trip |
| 2 | 10 M-parameter model on real text | Val loss beats uni/bigram; reproducible |
| 3 | Sampler, KV cache, grammar mask | 100% grammar-valid under mask; throughput measured |
| 4 | Durable sessions | Byte-identical resume |
| 5 | Eval + regression cases | Green, SKIPs counted |

## 6. Back-of-envelope capacity (rough estimates)

Assumptions: float32 compute, parameters stored as 8-byte doubles in 512-double rows,
training cost about 6 x parameters x tokens FLOPs, a T4-class GPU at about 8 TFLOPS peak
and about 30% sustained.

| Parameters | Stored weights | Rows | Training tokens | Rough training time |
|---|---|---|---|---|
| 10 M | about 80 MB | about 19,500 | 100 M | about 40 minutes |
| 100 M | about 800 MB | about 195,000 | 2 B | about 70 hours |
| 1 B | about 8 GB | about 1.95 M | 20 B | not practical on one T4 |
| 7 B | about 56 GB | about 13.7 M | n/a | not a target |

These are order-of-magnitude figures to decide whether a rung is worth attempting,
not predictions. Training on free Colab sessions also hits session limits.

## 7. Risks

1. **Prolog-driven training overhead** may dominate at small sizes. Measure in phase 0.
2. **Missing ops** (clipping, decay, top-k, multinomial) may force changes inside `modules/torch`.
3. **Store ageing:** repeated checkpoints leave dead rows; schedule `cocolog vacuum`.
4. **Tokenizer speed** in Prolog on large corpora.
5. **Bus factor:** the stack depends on Cicili and ZiguratIP, both by the same author, and a clang-only toolchain with a pinned Cicili commit.
6. **Reproducibility:** same-device reruns should match with fixed seeds; cross-device (CPU vs GPU) will not be bit-exact.

## 8. Not verified

- No build, no run, no timings. All performance claims are estimates or the repo authors' own statements.
- `modules/torch/README.md` describes the transformer layers as checked on CPU (libtorch 2.13.0) and CUDA path on a Colab T4; I did not reproduce that.
- `The Coco` and Cicili repositories were not inspected, so `library(poa)`, `library(pos)`, `library(settle)` and `library(ccl_llvm)` from the earlier spec remain unchecked.
- The Parsi syntax in the earlier spec was not matched against a working Parsi file; use the repo's `parsi/01-schema.parsi` as the model if a new table is ever needed.
