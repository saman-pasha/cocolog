# Train on a Colab GPU, query from anywhere

Everything here is in [`Coco_Colab.ipynb`](Coco_Colab.ipynb) beside this file.
This explains the arrangement and why it holds, so you can change it rather
than only run it.

**Open it in Colab:**

<https://colab.research.google.com/github/saman-pasha/cocolog/blob/master/colab/Coco_Colab.ipynb>

---

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
