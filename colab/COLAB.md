# Train on a Colab GPU, query from anywhere

Everything here is in [`cocolog_colab.ipynb`](cocolog_colab.ipynb) beside this file.
This explains the arrangement and why it holds, so you can change it rather
than only run it.

**Open it in Colab:**

<https://colab.research.google.com/github/saman-pasha/cocolog/blob/master/colab/cocolog_colab.ipynb>

That link is the notebook itself, loaded from this repository — not a
copy. It was `Coco_Colab.ipynb` until it was renamed, so a bookmark from
before that will 404; there is nothing to migrate, just open the URL
above. A copy you saved to your own Drive is a copy and will not follow
this repository at all.

---

## How long it takes

**About twelve minutes on a Colab VM**, measured on a 2-core / 12.7 GB
Ubuntu 22.04 runtime — the standard shape Colab hands out, GPU or not.
That is a fresh build of all three: ZiguratIP's fourteen libraries and
five executables, the transpile of cocolog through Cicili and its one
link against libtorch, and the Parsi objects compiled into the home.

The build **times itself** and prints each stage, so the number above is
a data point rather than the authority:

```
   ZiguratIP: 14 libraries, 5 executables
   [ZiguratIP: 3m 38s]
   cocolog built: 906K
   [cocolog: 2m 49s]
   37 cocolog objects in the home
   [schema: 30s]
   cocolog answers: 42

build GREEN in 6m 58s
```

Those are from a **4-core** machine, and Colab's two cores roughly
double the total — which is about the ratio you would expect, because
ZiguratIP is the part that scales: fourteen ordinary C++ projects, built
in sequence but each parallel inside. The cocolog stage is dominated by
a single-threaded transpile and one link and barely moves with cores,
which is why it is the larger share of the twelve minutes on Colab and
the smaller share here.

A re-run is much shorter: only `CLEAN=1` discards ZiguratIP, and without
it `make` rebuilds just what changed. The cocolog binary is deleted
before its stage every time on purpose, so its existence afterwards is
evidence about *this* run rather than the last one — that costs the
cocolog stage in full and is worth it.

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
| `Component "cicili" not found`, then `cannot find -lMVCCS`, then no `parsi`, no `ziguratip` | **one** cause with thirteen symptoms: ASDF could not load Cicili. `cicili.asd` depends on `sha1`, `base64`, `str` and `cl-ppcre`, and the first two are published under those names nowhere — they were simply present in `~/common-lisp` on the development machine. ASDF also finds a checkout by its source registry, never by the directory it is run from | `colab/prereqs.sh` installs Quicklisp for `str` and `cl-ppcre`, copies the two shims out of `colab/lisp/`, and symlinks the Cicili checkout into `~/common-lisp`. Preflight now *loads the system* rather than looking for a file — see `colab/lisp/README.md` |
| `fatal error: /home/user/ZiguratIP/StreamIO/binarystream.hpp: No such file` | ZiguratIP spelled one developer's home into `.cicili` includes, link flags and test sources **51 times**, so the workspace built on exactly one machine | fixed in ZiguratIP: the engine includes the published headers the way every other project does. Proved by building a clone at a different path from clean |
| preflight refuses for a reason you already fixed | your BROWSER still holds the old notebook: `git reset --hard` updates the files on disk, not the cell you are running | section 1 now prints both versions and shouts when they differ — *File → Revert to saved*, then re-run. The package list lives in `colab/prereqs.sh`, so a stale notebook still installs the right things |
| `libtool MISSING` although `apt-get install libtool` just succeeded | Debian and Ubuntu **split the package**: `libtool` ships `libtoolize` and the m4 macros, and the `/usr/bin/libtool` script Cicili invokes is in **`libtool-bin`** | `apt-get install -y libtool-bin`; the notebook installs that one now |
| thirteen libraries, or a server that dies on its first insert | one project failed and the workspace carried on | `colab/build.sh` names it; read its log under `/tmp/coco-build-logs/` |
| undefined `c10::` symbols, full of `__cxx11`, at the **final** link | the `torch` wheel was built with `_GLIBCXX_USE_CXX11_ABI=0` and `g++` spells `std::string` the other way | preflight prints the wheel's ABI and **warns without stopping** — everything except the torch link is indifferent to it. The flag would have to reach every C++ unit that touches libtorch, and Cicili's `{$…}` tokens have no ABI among them, so the fix is a matching wheel (`pip install` a torch built ABI=1) rather than a flag at the end |
| a Lisp backtrace ending the cocolog build | Cicili treats any unrecognised compiler chatter as fatal, and the **line under** its `Unhandled …` banner names the cause | `colab/build.sh` prints that line; a new compiler warning class usually wants silencing in the target's own `:compile` list |
| `Zeytun: no page 'SETUP'` / 404 from the *Load demo* link on Zeytun's index page | that link is **ZiguratIP's demo**, compiled by its `demo/build.sh` from `demo/03-pages.parsi`. This notebook does not build the demo — it builds cocolog's own Parsi objects and nothing else — so the page genuinely is not there | nothing to fix: the 404 is correct, and the knowledge base is reached through `--https` rather than that page. **Section 4b compiles the demo** if you want the link to work — note it needs a ZiguratIP carrying the `engine_key64(const char*)` overload, because before that the demo would not compile at all |
| the build looks fine but re-running says green instantly | a stale artifact from the previous run | `CLEAN=1 sh colab/build.sh` |
| `preflight RED` with nothing else to go on | the notebook used to discard the report | fixed: the refusal now carries the `MISSING` lines with it. If you still see a bare RED, run `sh colab/preflight.sh` by hand — the report is the answer |
| `build RED -- the report above names the cause`, and no report above it | same flaw, one cell down: the build's output was streamed and never captured, so a long build scrolled its cause away and a pasted tail carried only the exception | fixed in v2: the build is streamed **and** captured, and the refusal carries the lines that named the failure. Whole logs stay under `/tmp/coco-build-logs/` — `!cat /tmp/coco-build-logs/*.log` |
| `no GPU visible` on a runtime that IS set to GPU | the check asked only torch, with `2>&1` over the answer, so the reason was discarded and the report blamed a menu you had already used | fixed in v2: `nvidia-smi` is asked **first**. A driver that sees a GPU while torch will not use it is a torch/CUDA problem and prints both sides; no driver at all is a VM with no GPU attached — see below |
| `clang++: not found`, or `unsupported option '--gcc-install-dir=…'` | Colab's image ships no clang, and Ubuntu 22.04's apt has clang 14; `tools/cc/cxx` passes a flag that exists from clang 16 | `prereqs.sh` now installs clang 18 from apt.llvm.org when no clang 16+ is present, and `preflight.sh` checks the version instead of assuming. `CICILI_CC=gcc CICILI_CXX=g++` is the documented way to build without clang |
| `No rule to make target '…/home/obj/x.o'` from every ZiguratIP project, on a **second** attempt | the first attempt ran with no working `clang++`; each project's `<Project>-Linux-cxx.depend` was written by `cxx -MM` under `@-`, so it exists, is newer than every source, and has no object rules | `CLEAN=1`, or delete `ZiguratIP/*/*.depend`. Installing the compiler before the first `make` is what prereqs.sh's order is for; this row cost three builds |
| `cannot find -lConfiguration` while linking `libCryptography.so` on a **fresh** tree, then `-lCryptography`, `-lSocketIO`, `-lConnector`, `-lCompiler` in turn | ZiguratIP's top-level project list built Cryptography before Configuration, which it links; nine libraries out of fourteen, and an incremental tree never shows it | fixed in ZiguratIP's `PROJECTS` order; `build.sh` also runs a second `make` pass when the first leaves artifacts missing, which covers older checkouts and costs seconds on a complete tree |

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
| everywhere else | querying cocologs, browsers | `--https --host NAME.trycloudflare.com`, read only |

A PROGRAM behind the tunnel reads the same pages the same way:
`library(curl)` speaks https natively, so
`curl_get('https://NAME.trycloudflare.com/cocolog/predicates.zt?kb=brain', S, B)`
fetches a Zeytun page from inside a query, verified against the system
roots -- which is all a trycloudflare certificate needs. **The notebook's
section 7b runs exactly this**, against the real tunnel when section 6
opened one and over loopback otherwise, and answers
`200-page_lists_the_model` once section 5 has trained. `test/tunnel.sh`
holds both readers against a local TLS edge: the `--https` arrangement,
and a `curl_get` with an https URL -- including that a certificate the
caller did not vouch for is refused, because verification defaulting to
ON is the client's security posture.

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

What must stay unpublished is the Parsi **compiler pages**.
`System/compiler.parsi` is a web page whose POST handler is
`CALL con.compile(request.post('code'))` — a compiler behind an HTTP
form — and `compilerdrawer.parsi` renders it.

**They are not leftovers; `make` builds them.** `System` is in
ZiguratIP's top-level `PROJECTS` list, so an ordinary
`make MODE=Release` compiles both into `home/ld` on any machine. A fresh
Colab VM that had run nothing else hit the tunnel cell's refusal with
exactly those two objects; ZiguratIP's tutorial said a fresh clone had
none, and has been corrected.

So `colab/build.sh` **moves them out of `home/ld` after the build**, into
`$ZIGURATIP_HOME/ld-disabled`, each object beside its catalogue entry,
and says so. Moved rather than deleted: `mv` restores them. Nothing here
needs them — Parsi objects are compiled offline by `parsi`, which is the
supported route and the reason the network compiler stays off.
`KEEP_COMPILER_PAGES=1` skips it, for ZiguratIP's own compiler tutorial,
which is the one workflow that wants the page and does not want a
tunnel.

The tunnel cell still refuses if it finds one loadable — the build
moving them is convenience, the refusal is the guarantee, and the two
are deliberately not the same mechanism. If you ever see that refusal,
the answer is to move the page, not to set `I_UNDERSTAND`: a refusal
whose only way forward is the override teaches people to use the
override. And
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

**AND SO DOES cocolog NOW.** The client speaks TLS, so a querier uses the
URL Cloudflare actually printed:

```sh
cocolog --host NAME.trycloudflare.com --https --kb brain
```

`--https` defaults to port 443 and `--http` to 80, so neither has to be
written out. The server's certificate is checked against the **system**
authorities — Cloudflare's is public — and **so is the hostname**, which
is the check that makes the tunnel worth anything: a certificate valid
for somebody else is exactly what a man in the middle presents.

The plaintext spelling still works and is still port 80:

```sh
cocolog --host NAME.trycloudflare.com --http --kb brain
```

but there is no longer a reason to prefer it.

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
* **The HTTP→HTTPS redirect is no longer a hazard.** It used to be: the
  client spoke plaintext only, and a tunnel that started redirecting
  would have answered `the server answered: HTTP/1.1 301 Moved
  Permanently` with a TLS shim as the only fix. `--https` is that fix,
  in the client.

## SSH into the VM, when a machine of yours should drive it

**`cocolog_vm.ipynb` is this section as a notebook of its own**: the tunnel
cell, a keep-alive that touches the GPU once a minute, and an optional cell that
builds the stack with `install/install-linux.sh`. Open it when the VM is to be
driven from outside and nothing else; the notebook below is the one that trains
and serves from cells.

Section 1b is the one cell that is not for the notebook's own use: it lets
some machine of yours — a Claude Code session on a laptop was the first —
build, train and measure over an SSH tunnel instead of through cells.

**What it does.** Installs `openssh-server`, allows root login by **public
key only** with passwords off, and runs `cloudflared tunnel --url
ssh://127.0.0.1:22`: the VM dials *out*, nothing listens on the internet,
and only a holder of an authorised private key gets in. The `sshd` runs
on a config of its own, `/content/sshd_config`, because Colab's
`/etc/ssh/sshd_config` says `Port 2222` on loopback and that port is
Colab's already — with the stock config `sshd` binds nothing, exits, and
the tunnel answers `502 Bad gateway` to every client. The first session
found that the hard way. The client side is
one line, with `cloudflared` installed (`brew install cloudflared` on a
Mac), and the cell prints it with the host filled in:

    ssh -o ProxyCommand="cloudflared access ssh --hostname %h" root@<host>.trycloudflare.com

**Where the key comes from, and where it does not.** No key is stored in
the notebook — the repository is public, and a key in it would be a key in
everybody's copy. The cell reads the Colab secret `SSH_PUBKEY` (the key
icon in Colab's left bar: paste a public key, allow the notebook access,
and it is there for every session under that Google account) or, failing
that, the public keys `GITHUB_USER` publishes at `github.com/<user>.keys`.
Set `GITHUB_USER = ''` to insist on the secret; with neither, the cell
stops before it installs anything.

**The session has the build's environment.** `/root/.ssh/environment`
carries `CICILI`, `ZIGURATIP`, `ZIGURATIP_HOME`, `COCOLOG` and
`LD_LIBRARY_PATH` exactly as section 1 sets them, so `sh colab/prereqs.sh`,
`preflight.sh` and `build.sh` run over the tunnel as they do in the cell,
and so does `nvidia-smi`.

**The rules.** Colab's usage restrictions list "using a remote desktop or
SSH" among the things disallowed on its runtimes, beside mining and
proxies. In practice the cost is a killed runtime, and repeat offences can
cost Colab access on the account. The cell does nothing until it is run —
though *Runtime → Run all* does run it, so skip it or leave it keyless if
that matters — and it is your account: the decision is yours, made once
per session, never as a side effect of the build.

## The GPU

Give the notebook a GPU runtime (*Runtime → Change runtime type → GPU*).
The torch module takes it with one goal — `torch_device(auto)` picks
`cuda` when it is available — so training a tutorial on the GPU is:

```sh
./cocolog --kb brain run tutorials/torch/07-xor.pl "torch_device(auto), train"
```

Tensors live on the model's device and every answer comes back to the
CPU, so what reaches the knowledge base is device-free — which is
exactly why a model trained on Colab's GPU predicts on a laptop's CPU.

## Querying, from each place

**Another Colab**: run the notebook's build cells (no GPU needed, no
server, no tunnel), then

```sh
./cocolog --host NAME.trycloudflare.com --https --kb brain \
  query "model_load(xor, M), model_predict(M, [[0.0,1.0]], P)"
```

**Your own machine**: a built cocolog and the URL are enough — the
toplevel runs in the `--http` arrangement like any other:

```console
$ cocolog --host NAME.trycloudflare.com --https --kb brain
?- model_load(xor, M), model_predict(M, [[0.0,1.0]], P).
```

**A browser**: the `https://` URL serves Zeytun's pages directly.

**A program**: `library(curl)` fetches the same pages from inside a
query, https and verified against the system roots, no flags required
-- notebook section 7b is the runnable version:

```prolog
?- use_module(library(curl)),
   curl_get('https://NAME.trycloudflare.com/cocolog/predicates.zt?kb=brain', S, B).
```

What a querier cannot do is write or claim machines — `assertz` needs
the store's write hook and `work` needs the binary port, and neither
crosses the tunnel. Workers belong on the VM beside the server.
