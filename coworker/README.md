# Coworker tasks

Each directory here is one self-contained arrangement of cooperating
cocolog instances — its own README, its own Prolog, its own `run.sh` —
built on the same claim as everything else in this repository: **a
trained model is clauses**, so parts of a training job can live in
separate knowledge bases and travel between processes as terms.

Both tasks split one dataset three ways and give each third to its own
cocolog instance with its own knowledge base. They differ in topology:

| task | who ends up with the model | shape |
|---|---|---|
| [`accumulator/`](accumulator/) | one accumulator, downstream of three trainers | fan-in |
| [`balancer/`](balancer/) | every worker — any of the three answers | all-gather |

The knowledge bases live on a ZiguratIP server because the whole point
is *concurrent* cross-process work — trainers publishing while an
accumulator polls — and reads against the server are proven ground.
An embedded store belongs to one process at a time, so it cannot even
be polled while its trainer holds it. Each part's connection is an
environment variable (`PART1_OPTS` and friends in the `run.sh`s), so
the same scripts run against three *separate* servers — three machines,
three disks — by pointing each part somewhere else. Nothing in the
Prolog knows the difference.

Both tasks obey one discipline that is worth naming, because building
them is what surfaced the reason for it: **long compute never sits
inside a transaction, and anything big travels as a handful of chunked
rows** rather than one row per datum — training happens in `--local`
and only the short publish turns touch the server. The write turns run
**concurrently**, as turns may: building these tasks first made the
server look like it wedged and lost commits under overlapping writers,
and the hunt that followed (STATUS.md tells it) exonerated the server
on every count — what it found was cocolog quietly discarding a failed
commit, an O(N²) consult sync, and turns dawdling past the server's
idle timeout. All three are fixed; the discipline is what remains,
because it is simply how a fleet should behave.

Both need a built `cocolog` and a running server:

```sh
cd /path/to/ZiguratIP && ZIGURATIP_HOME=$PWD/home \
  LD_LIBRARY_PATH=$PWD/home/lib ./home/bin/ziguratip &
sh coworker/accumulator/run.sh
sh coworker/balancer/run.sh
```
