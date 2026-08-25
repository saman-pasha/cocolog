# balancer — three workers, no centre

All-gather. The same 900 ring points as the accumulator's, split the
same three ways — but here every worker **owns** its third, in its own
knowledge base (`bal_part1`..`bal_part3`), and there is no fourth
instance downstream: each worker fetches the two thirds it lacks from
its peers, trains a full model on the union, and publishes it into its
own knowledge base. When the dust settles all three hold the same
knowledge learned the same way, so **any of them answers** — `run.sh`
asks every worker to pass the held-out test and then sends the predict
probes round-robin across the three, which is what makes it a
balancer: queries go to whichever node is up or nearest.

The choreography is knowledge-base-shaped end to end. A worker's third
goes in as a handful of `samples_chunk/3` rows — sixty samples to a
row, the way machine state travels in 4000-byte chunks and model
parameters in 120-float ones, because a clause row has to fit in a
page — with `part_ready/1` asserted in the same turn, so a peer that
sees the mark sees every chunk with it. Waiting for a peer IS asking
its knowledge base for `part_ready/1`; fetching IS reading its chunk
rows back out. Training runs in `--local` (long compute belongs
outside any transaction) over the worker's own rows plus the two
fetched parts, and the finished model publishes as one short consult.

The order inside each worker is the point: a worker seeds **its own
third first** and only then starts polling its peers — own work done
before asking after anyone else's, so nobody waits on a worker that is
itself still waiting. The turns run **concurrently**, as turns may:
this file once serialised every write through a mutex, until the hunt
that the apparent wedges provoked ended with the server exonerated
(STATUS.md tells it).

```sh
sh run.sh          # needs a built cocolog and a running server
```

| file | what |
|---|---|
| `worker.pl` | the ring data, chunked seeding, `train_full/0`, `test/0`, `probe/2` |
| `run.sh` | the choreography: seed, wait, fetch, train, publish, verify |

Each worker's connection is an environment variable (`PART1_OPTS`
etc.), so the three can sit on three different servers; the defaults
put three knowledge bases on one.
