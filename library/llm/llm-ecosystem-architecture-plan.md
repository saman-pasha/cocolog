# LLM System Architecture Specification: A Durable Neuro-Symbolic Engine on Cicilang, Cocolog, ZiguratIP, and The Coco

The construction of Large Language Model (LLM) architectures traditionally faces severe trade-offs between execution speed and operational state control. Conventional Python-based deep learning frameworks rely on heavy garbage collectors, fragile process-bound state, and opaque external orchestration. By contrast, the unified ecosystem formed by **Cicilang**, **Cocolog**, **ZiguratIP**, and **The Coco** enables a neuro-symbolic LLM architecture: high-throughput matrix compute is executed in compiled native code with zero garbage-collection overhead, model weights and context caches are persisted in transactional database tables, and sampling logic, constrained decoding, and agent reasoning are orchestrated inside a durable, position-independent logic engine.

This document details the architectural specification, component division of labor, memory management protocols, persistence mechanisms, and implementation roadmap for building a production-grade LLM system on this foundation.

---

## 1. System Topology & Architectural Division of Labor

The proposed LLM system decouples low-level tensor arithmetic from high-level reasoning and storage. The system comprises four distinct layers, each mapped to a pillar of the ecosystem:

| Architectural Layer | Primary Pillar | Operational Role | Key Capabilities & Mechanics |
| :--- | :--- | :--- | :--- |
| **Compute Engine** | **Cicilang** | High-performance tensor kernels & LLVM IR lowering | Zero-GC memory safety via affine ownership (`own`, `move`, `tie`), native PyTorch bindings (`library(torch)`), direct LLVM IR emission (`library(ccl_llvm)`). |
| **Storage & Persistence** | **ZiguratIP** | Weight management & KV-cache persistence | MVCCS page stores (`data`/`hexmap`), B-tree indexing, 5 ANSI isolation levels (including `SNAPSHOT`), weight retention via `ModelPool`. |
| **Logic & Orchestration** | **Cocolog** | Samplers, DCG decoding & agent state machines | Flat 64-bit cell term heap, position-independent ASCII state snapshots, green thread scheduling (`go`, `yield`, `await`), deterministic step metering (`max_steps`). |
| **Consensus & Distribution** | **The Coco** | Multi-node verification & tokenized gas settlement | Consensus as clauses, Proof-of-Authority (`library(poa)`), Proof-of-Stake (`library(pos)`), gas tracking via `call_metered/4`. |

As documented in the ecosystem specifications, data exchange across these boundaries is strictly controlled through explicit interfaces rather than arbitrary shared memory. Cicilang manages hot-path execution, standardizing computational memory layout; ZiguratIP provides durable storage with transactional guarantees; Cocolog evaluates logical rules and manages proof continuations; and The Coco validates execution across distributed nodes.

---

## 2. Compute Layer: Native Tensor Operations & LLVM Lowering in Cicilang

High-throughput transformer operations—such as multi-head attention, rotary positional embeddings, and feed-forward matrix multiplications—demand deterministic performance without runtime pauses. Cicilang satisfies these requirements by compiling directly to native machine code through LLVM Intermediate Representation text lowering without emitting intermediate C code.

### 2.1 Compile-Time Ownership & Zero-GC Memory Management
To manage large GPU and host memory buffers safely, the compute engine enforces Cicilang's compile-time affine ownership rules:

* **Linear Ownership (`own`)**: Allocations of model weights and active sequence buffers are declared with `own` pointers. Every owner must be consumed exactly once on every execution path (via explicit free, return, or move into a consumer parameter).
* **Move Semantics (`move`)**: Transferring tensor ownership across pipeline stages (e.g., from an embedding lookup to an attention block) uses `move(p)` semantics, invalidating the source reference at compile time to prevent double frees (`use_after_move`).
* **Lifetime Borrowing & Ties (`borrow`, `tie`)**: Temporary tensor slices and views are passed as plain pointer borrows or tied values (`x tie y`). A borrowed reference is restricted from escaping its owner's scope or being stored in long-lived global structures, preventing dangling pointers.

As specified in the Cicilang compiler rules, any violation of these ownership paths is caught during parse-time analysis and rejected with line-specific compiler diagnostics before code lowering occurs.

### 2.2 LLVM IR Lowering & C++ Interoperability
Cicilang transforms parsed source constructs directly into LLVM Intermediate Representation text via `library(ccl_llvm)`. This enables custom compute kernels to benefit from LLVM 18+ optimization passes (including `-O3` vectorization and autovectorized SIMD/AVX routines).

Furthermore, Cicilang maintains full alignment with the Itanium C++ ABI. This permits the LLM compute layer to link seamlessly against established native deep learning frameworks—such as LibTorch (`library(torch)`) or TensorFlow (`library(tensorflow)`)—without ABI translation overhead or wrapper friction.

---

## 3. Storage Layer: Weight & State Persistence with ZiguratIP (MVCCS)

Persisting model weights and sequence context across inference steps is handled by **ZiguratIP**, utilizing its Multi-Version Concurrency Control Storage engine (**MVCCS**).

### 3.1 Physical Data Page Layout & B-Tree Indexing
As documented in the ZiguratIP storage engine manual, data is persisted across two physical files in the `home/data/` runtime directory:
1. **`data`**: Contains fixed 64 KiB data pages holding raw tensor chunks, row records, and context blocks.
2. **`hexmap`**: Serves as a chunk allocation map, tracking page usage and row slice offsets.

Rows are identified using SHA-1 keys and indexed using templated B-tree structures. For LLM sequence lookups, token embeddings and position-indexed key-value (KV) caches are mapped directly to indexed table rows, enabling high-performance key-value probes.

### 3.2 Transactional Snapshot Isolation & ModelPool Caching
To support multi-threaded inference without data corruption or lock contention, MVCCS provides five ANSI isolation levels: `READ-UNCOMMITTED`, `READ-COMMITTED`, `REPEATABLE-READ`, `SNAPSHOT`, and `SERIALIZABLE`.

The LLM architecture leverages `SNAPSHOT` isolation for autoregressive token generation:
* Concurrent worker threads read a consistent, lock-free view of model weights and historical sequence context as of their transaction start timestamp.
* Weights are managed via ZiguratIP's `ModelPool` mechanism, ensuring large parameters remain loaded in shared page memory across successive requests rather than being re-initialized on every invocation.
* Because MVCCS uses non-destructive deletes (marking soft-deletion flags without overwriting historical data in-place), previous context states remain queryable for prompt branching and beam-search evaluations.

---

## 4. Reasoning Layer: Autoregressive Decoder & State Orchestration in Cocolog

While tensor kernels compute raw logit vectors, the decoding process, token sampling, constrained grammar enforcement, and multi-step agent planning are managed within **Cocolog**.

### 4.1 Position-Independent Term Heap & Resumable Proof States
Cocolog departs from standard Prolog implementations by avoiding pointers and recursive C stack calls. Instead:
* **Cell Array Term Heap**: Terms are indices into a flat array of 64-bit cells.
* **Explicit Continuations**: Pending goals are maintained on the heap as explicit Prolog terms formatted as `'$k'(Goal, Barrier, Rest)`.
* **Integer Choice Points**: Choice points are stored in a flat array of integer frames containing heap marks, trail marks, and predicate indices.

Because all references are array-relative indices, an active inference session can be frozen at any step. The entire execution state—represented as approximately 15 KiB of ASCII text—can be written to a ZiguratIP table, suspended, migrated to a different server process, and thawed to resume computation seamlessly.

### 4.2 Constrained DCG Decoding & Green Thread Scheduling
1. **Definite Clause Grammar (DCG) Constraints**: Output token streams are filtered using Prolog DCGs (`library(dcg_basics)`). Logits produced by Cicilang tensor operations are masked against active DCG rules, guaranteeing that generated text strictly conforms to required schemas (such as valid JSON, SQL, or specialized domain syntaxes) at sampling time.
2. **Green-Thread Concurrency**: Multi-agent sessions operate as lightweight green threads (`go`, `yield`, `await`, channels) running over a shared Cocolog store. As detailed in the Cocolog runtime documentation, the green scheduler preempts long-running logic tasks every 10,000 steps, ensuring fair allocation of CPU resources across parallel inference channels.
3. **Deterministic Step Metering**: Execution limits are enforced via `max_steps` and `call_metered/4`, allowing system administrators to bound token generation and reasoning proofs deterministically.

---

## 5. Metaprogramming Layer: Code Generation via Cocolog Macros

To maintain tight integration between Cicilang implementation types and Cocolog reasoning facts, the architecture uses parse-time **Cocolog Macros**.

### 5.1 AST Transformation & Symbol Table Introspection
As established in the Cicilang repository documentation, macros written in Prolog (`.pl` files) or embedded inline via `#cocolog ... #end` blocks execute during compilation over the Abstract Syntax Tree (AST). Macros have full access to the compiler's symbol table through inspection predicates:
* `ccl_type_of/2`: Queries the inferred type of active variables or expressions.
* `ccl_size_of/2`: Determines byte alignment and structure layout requirements.

### 5.2 Automated Binding & Boilerplate Generation
During LLM toolchain compilation, macros perform three critical generation functions:
1. **Tensor Struct Generation**: Auto-generates C-compatible struct layouts and destructor cleanup routines (`autodrop`) for model configuration parameters.
2. **Fact Exporter Adapters**: Scaffolds visitor functions that dump live runtime execution state into Cocolog fact predicates (e.g., `tensor_shape/3`, `active_context_length/2`).
3. **Dual-Location Diagnostics**: When a generated macro call fails, Cicilang provides error reporting that explicitly identifies both the user's invocation line and the originating macro clause line (tagged with `note: expanded from macro`).

---

## 6. Consensus & Distribution Layer: Decentralized Governance via The Coco

For multi-node LLM deployments, model training verification, and tokenized inference billing, the system integrates **The Coco**.

### 6.1 Consensus as Clauses & Gas as Inference Count
The Coco frames blockchain ledgers as knowledge bases and consensus logic as Prolog clauses. In this layer:
* **Gas Accounting**: Rather than relying on arbitrary price tables, gas is defined directly as Cocolog's deterministic inference count (`max_steps`). Two independent nodes executing the same token generation proof compute the exact same fee byte-for-byte.
* **Proof-of-Authority & Proof-of-Stake**: Node validation and consensus are governed by `library(poa)` and `library(pos)`, where validator weights are represented as bonded balance entries on the ledger.

### 6.2 Settlement & Bit-Exact Verification
As demonstrated in The Coco repository, verification tasks balance bit-exact native execution with declarative policy:
* Low-level cryptographic checks (such as secp256k1 signatures, Keccak hashes, or array comparisons) run in Cicilang or compiled C++ modules (`modules/crypto`).
* Node interaction policies, peer synchronization (`library(btc_peers)`), and mempool management rules are written as inspectable Prolog clauses.
* Model output acceptance or fine-tuning verification is settled using `library(settle)` by executing held-out evaluation tests against candidate responses.

---

## 7. Phased Implementation Roadmap

The execution plan is organized into four sequential milestones to ensure thorough validation of every subsystem:

```text
PHASE 1: Tensor Core & C++ FFI Bindings
· Compile custom vector routines in Cicilang to LLVM IR via library(ccl_llvm)
· Bind LibTorch/TensorFlow C++ APIs using Cocolog tier-2 library(torch)
       |
       v
PHASE 2: Persistent Storage & KV-Cache Layer
· Implement ZiguratIP MVCCS tables for model weights and KV-caches
· Configure SNAPSHOT isolation level and ModelPool page caching
       |
       v
PHASE 3: Constrained Decoder & Durable Agent Loop
· Build DCG grammar masks for logit sampling in Cocolog
· Implement 15 KB ASCII state freeze/thaw workflows for agent session migration
       |
       v
PHASE 4: Multi-Node Distribution & Consensus
· Wrap inference pipeline in The Coco consensus clauses
· Enable deterministic gas metering via call_metered/4 and library(poa)
```

### Milestone Specifications

1. **Phase 1 (Tensor Core & FFI)**: Validate Cicilang memory safety (`own`/`move`) on custom attention routines. Confirm zero-overhead execution of native C++ tensor libraries through `library(torch)`.
2. **Phase 2 (Persistent Storage)**: Benchmark MVCCS indexed lookups for sequence context tables. Ensure `ModelPool` retains loaded weights across concurrent execution transactions.
3. **Phase 3 (Constrained Decoder & Resumable Logic)**: Verify that DCGs enforce schema-compliant token sampling. Test freezing a mid-generation execution state into ASCII data and thawing it in a separate process.
4. **Phase 4 (Consensus & Settlement)**: Deploy multi-node inference validation using The Coco ledger clauses, enforcing deterministic inference metering (`max_steps`) across all peer nodes.
