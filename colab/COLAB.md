# Train on a Colab GPU, query from anywhere

Everything here is in [`Coco_Colab.ipynb`](Coco_Colab.ipynb) beside this file.
This explains the arrangement and why it holds, so you can change it rather
than only run it.

**Open it in Colab:**

<https://colab.research.google.com/github/saman-pasha/cocolog/blob/master/colab/Coco_Colab.ipynb>

---

## Which version am I running?

Two answers, and the whole reason this section exists is that they can
differ:

* **the repository** — `colab/VERSION`, first line, and the three
  commits the build was made from;
* **the notebook in your browser** — `NOTEBOOK_VERSION` in section 1's
  cell, which is whatever Colab last loaded.

Section 1 prints both before it installs anything, and shouts when they
disagree. That is deliberate: `git reset --hard` updates the files on
disk and **cannot touch the cells already loaded in your browser**, so a
corrected fix can sit on disk while the same run fails for the same
reason twice. It has happened here, and the second time cost a round
trip to work out why.

The mismatch is a **warning, not a refusal**. Everything the build
actually does lives in `prereqs.sh`, `preflight.sh` and `build.sh`, which
arrive with the clone — that is the point of their being scripts — so an
older notebook usually still builds. Stopping a working build over a
number would be the worse mistake, the same judgement the preflight
makes about the torch ABI.

**Paste that header with any bug report.** Three commits and a version
turn "the build failed" into a question somebody can answer.

To pick up new cells: *File → Revert to saved*, then re-run section 1.

`colab/VERSION` is bumped when a notebook **cell** changes. A change to
one of the scripts does not need one.

## When the build fails

Section 1 checks the VM before it builds and checks the build by its
artifacts afterwards, because the two things that used to hide a failure
here are both in the build itself:

* **`ZiguratIP`'s top-level `make` steps over a project that fails.** It
  loops with `@- $(MAKE) -C …`, and the leading dash says carry on — so
  the workspace prints *all done* and exits 0 having skipped a library
  that would not compile. `colab/build.sh` checks all fourteen libraries
  and three executables **by name**, and names the project a missing one
  belongs to.
* **`| tail -n 3` shows the wrong three lines.** A compiler reports the
  error first and the summary last, so the tail of a broken build is the
  linker's parting words about a file it never got. Whole logs are kept
  under `/tmp/coco-build-logs/`, and a failure prints the lines that say
  why.

Run them by hand, in that order, when a cell has gone wrong:

```sh
cd /content/cocolog
sh colab/prereqs.sh       # install what the build needs
sh colab/preflight.sh     # what this VM has, and what it lacks
sh colab/build.sh         # both builds, checked by artifact
CLEAN=1 sh colab/build.sh # after a failure left a tree worth distrusting
```

The ones that have actually bitten:

| what you see | what it is | the fix |
|---|---|---|
| `sbcl: not found` inside a sub-make | the image's package lists were stale, so the install failed — silently, in the old cell | `apt-get update` first; the cell does it now, and preflight refuses to continue without `sbcl` |
| preflight refuses for a reason you already fixed | your BROWSER still holds the old notebook: `git reset --hard` updates the files on disk, not the cell you are running | section 1 now prints both versions and shouts when they differ — *File → Revert to saved*, then re-run. The package list lives in `colab/prereqs.sh`, so a stale notebook still installs the right things |
| `libtool MISSING` although `apt-get install libtool` just succeeded | Debian and Ubuntu **split the package**: `libtool` ships `libtoolize` and the m4 macros, and the `/usr/bin/libtool` script Cicili invokes is in **`libtool-bin`** | `apt-get install -y libtool-bin`; the notebook installs that one now |
| thirteen libraries, or a server that dies on its first insert | one project failed and the workspace carried on | `colab/build.sh` names it; read its log under `/tmp/coco-build-logs/` |
| undefined `c10::` symbols, full of `__cxx11`, at the **final** link | the `torch` wheel was built with `_GLIBCXX_USE_CXX11_ABI=0` and `g++` spells `std::string` the other way | preflight prints the wheel's ABI and **warns without stopping** — everything except the torch link is indifferent to it. The flag would have to reach every C++ unit that touches libtorch, and Cicili's `{$…}` tokens have no ABI among them, so the fix is a matching wheel (`pip install` a torch built ABI=1) rather than a flag at the end |
| a Lisp backtrace ending the cocolog build | Cicili treats any unrecognised compiler chatter as fatal, and the **line under** its `Unhandled …` banner names the cause | `colab/build.sh` prints that line; a new compiler warning class usually wants silencing in the target's own `:compile` list |
| the build looks fine but re-running says green instantly | a stale artifact from the previous run | `CLEAN=1 sh colab/build.sh` |
| `preflight RED` with nothing else to go on | the notebook used to discard the report | fixed: the refusal now carries the `MISSING` lines with it. If you still see a bare RED, run `sh colab/preflight.sh` by hand — the report is the answer |
| `build RED -- the report above names the cause`, and no report above it | same flaw, one cell down: the build's output was streamed and never captured, so a long build scrolled its cause away and a pasted tail carried only the exception | fixed in v2: the build is streamed **and** captured, and the refusal carries the lines that named the failure. Whole logs stay under `/tmp/coco-build-logs/` — `!cat /tmp/coco-build-logs/*.log` |
| `no GPU visible` on a runtime that IS set to GPU | the check asked only torch, with `2>&1` over the answer, so the reason was discarded and the report blamed a menu you had already used | fixed in v2: `nvidia-smi` is asked **first**. A driver that sees a GPU while torch will not use it is a torch/CUDA problem and prints both sides; no driver at all is a VM with no GPU attached — see below |

A binary that exists is not a binary that works — the one link pulls in
the embedded engine and libtorch, and an ABI mismatch surfaces on the
first run rather than at the link — so the last thing `build.sh` does is
ask cocolog for `6*7` and want `42` back.

## When the runtime says GPU and the VM has none

Preflight asks the **driver** before it asks torch, because the two
answers can differ and they have different cures:

* **`nvidia-smi` sees a GPU, torch will not use it.** Nothing in the
  Runtime menu helps. The report prints the card, torch's version and
  the CUDA it was built for, torch's own device count, the driver
  version, and whatever torch said on stderr. That mismatch is the
  finding.
* **`nvidia-smi` finds no device.** The VM genuinely has no GPU, and if
  the dropdown already reads GPU then **the dropdown is not the
  answer**. Check *Runtime → View resources* for a GPU line; then
  *Runtime → Disconnect and delete runtime* and reconnect. Colab hands
  back a CPU VM when the GPU quota is spent **and leaves the runtime
  type reading GPU**, which looks identical from inside the VM to a
  runtime type changed without reconnecting.

Neither stops the build. Everything except the speed of training is
indifferent to it, and `torch_device(auto)` takes `cpu` without
complaint — so a CPU session still builds, still serves, still answers.

## What you end up with

One Colab VM training on its GPU, and the trained knowledge readable by
everyone else — another Colab, your laptop's `?- ` prompt, a browser —
with nothing but a URL:

| where | what runs | how it reaches the knowledge base |
|---|---|---|
| the Colab VM | ZiguratIP server + the training cocolog | binary protocol, loopback (`--kb brain`) |
| Google Drive | the knowledge base between sessions | snapshot in before the server starts, out after it stops |
| Cloudflare | a quick tunnel in front of Zeytun (port 2190) | `cloudflared` dials **out**; the URL forwards down it |
| everywhere else | querying cocologs, browsers | `--http 80 --host NAME.trycloudflare.com`, read only |

The reason this composes at all is the project's one claim: **a trained
model is clauses.** `model_save/2` is `model_spec/2` and `model_params/2`
and an assert, so what training produces is rows — and rows travel over
Zeytun like any others. A querier does `model_load(xor, M),
model_predict(M, ...)` and the spec and the weights arrive as terms over
HTTP; the prediction itself runs on the querier's own CPU. Train on the
GPU once, predict anywhere, no model file ever copied.

## Why this shape is safe to publish

Zeytun's knowledge-base backend (`lib/zeytun-kb.cicili`) fills only the
`fetch` and `warm` hooks — it **cannot write**, by construction, not by
configuration. So the tunnel publishes a read-only view: an
`assertz/1` from a querier fails with the hook absent, and the one
writer is the trainer on the VM's loopback, where the binary port stays.
One writer, many readers, enforced by which port is public.

What must stay unpublished is what ZiguratIP's own Colab tutorial
already guards: the Parsi **compiler pages**. The tunnel cell refuses to
open when one is loadable — read [the warning in ZiguratIP's
tutorial](https://github.com/saman-pasha/ZiguratIP/blob/master/colab/TUTORIAL.md)
before overriding it. And
a quick tunnel has **no authentication**: anyone with the URL reads
every knowledge base the server holds. Keep it short-lived, and do not
point one at data you care about.

## Google Drive, the proven way

Colab VMs are ephemeral; Drive is not. But **the engine never runs
against the Drive mount** — Drive is a FUSE filesystem with its own
consistency story, and a database's paging is not what it is for. The
discipline is ZiguratIP's, proven in its own Colab notebook:

* **restore before start**: copy the snapshot from Drive onto the VM's
  local disk, then start the server;
* **snapshot after a clean stop**: there is no write-ahead log, so a
  snapshot taken mid-write is a torn store — the notebook refuses to
  snapshot while the server runs;
* **three directories travel together**: `data` (the rows), `catalog`
  (what links against what) and `ld` (the compiled objects), plus a
  `MANIFEST` naming the commits they were built from, so a snapshot
  restored onto a different build says so instead of failing twenty
  minutes later with an undefined symbol.

## Cloudflare, and what the client had to learn

A quick tunnel needs no account: `cloudflared tunnel --url
http://localhost:2190` prints a `https://NAME.trycloudflare.com` URL and
forwards it down an **outbound** connection — nothing has to reach into
the VM, which also routes around Colab's own port proxy (measured broken;
ZiguratIP's tutorial has the story). Browsers use the `https://` URL.
cocolog's client speaks plain HTTP, so a querier uses port 80 of the
same hostname:

```sh
cocolog --host NAME.trycloudflare.com --http 80 --kb brain
```

The edge routes by the `Host` header, and the hostname is registered
**bare** — so on the default ports the client now sends `Host: name`
rather than `Host: name:80` (`client/zeytun.c`; an edge answers for
nobody under the port-qualified spelling). `test/tunnel.sh` — the
suite's `tunnel` case — is the local rehearsal: a hostname-routing edge
stand-in on ports 80 and 18080 that admits only the exact registered
name and forwards verbatim, which is what the Cloudflare edge and
`cloudflared` do for real.

Two honest limits:

* **Latency multiplies.** The knowledge base is fetched lazily, a page
  per predicate, each its own request — a query that walks many
  predicates makes many round trips through the tunnel. Fine for
  queries and demos; not a benchmark. (`--timeout` may want raising on
  a slow link.)
* **Should Cloudflare ever force the HTTP→HTTPS redirect** on quick
  tunnels, the client would report `the server answered: HTTP/1.1 301
  Moved Permanently` — the fix then is a TLS shim in front of the
  client, not anything on the VM.

## The GPU

Give the notebook a GPU runtime (*Runtime → Change runtime type → GPU*).
The torch module takes it with one goal — `torch_device(auto)` picks
`cuda` when it is available — so training a tutorial on the GPU is:

```sh
./cocolog --kb brain run tutorials/07-xor.pl "torch_device(auto), train"
```

Tensors live on the model's device and every answer comes back to the
CPU, so what reaches the knowledge base is device-free — which is
exactly why a model trained on Colab's GPU predicts on a laptop's CPU.

## Querying, from each place

**Another Colab**: run the notebook's build cells (no GPU needed, no
server, no tunnel), then

```sh
./cocolog --host NAME.trycloudflare.com --http 80 --kb brain \
  query "model_load(xor, M), model_predict(M, [[0.0,1.0]], P)"
```

**Your own machine**: a built cocolog and the URL are enough — the
toplevel runs in the `--http` arrangement like any other:

```console
$ cocolog --host NAME.trycloudflare.com --http 80 --kb brain
?- model_load(xor, M), model_predict(M, [[0.0,1.0]], P).
```

**A browser**: the `https://` URL serves Zeytun's pages directly.

What a querier cannot do is write or claim machines — `assertz` needs
the store's write hook and `work` needs the binary port, and neither
crosses the tunnel. Workers belong on the VM beside the server.
