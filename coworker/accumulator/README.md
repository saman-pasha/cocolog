# accumulator — three trainers, one downstream model

Fan-in. The training data — 900 points on two concentric rings — is
split three ways by index, and each third belongs to its own cocolog
instance with its own knowledge base (`acc_part1`..`acc_part3`). The
three train **in parallel**, each on its own third — in `--local`,
because long compute belongs outside any transaction — and each
publishes its finished model into its own knowledge base as one short
consult of the model's stored form, `torch_model/2` and
`torch_params/3` clauses exactly as `model_save` lays them down.

The accumulator does not watch processes; it asks knowledge bases. Its
poll is the question itself — `torch_model(rings, _)` against each
part — and the answer flips exactly when a part's publish turn
commits, a turn being one transaction: there is no window where the
spec is visible and the parameter chunks are not.

One write turn at a time, cluster-wide: the publishes take a mutex in
`run.sh`, because the server does not survive overlapping clause-write
transactions yet (the hunt is on STATUS.md's list), and every write
turn is kept small for the same reason. The reads — the polling, the
read-back of the parts — run in parallel throughout; that half is
proven ground.

When all three answer, each part's model is exported as clauses —
`part_spec/2` and `part_chunk/3`, the parameters travelling in the same
120-float chunks `model_save` stores them in, because a clause row has
to fit in a page wherever it goes — and `accumulate.pl` does the rest
in Prolog: element-wise averaging of the three flat parameter lists
(one-shot federated averaging, sound here because every part seeds
torch identically and trains on a third of the same distribution),
`model_new` + `model_set_params` + `model_save` into the accumulator's
own knowledge base `acc_main`, then a test on the 150 held-out points
no trainer ever saw, and a prediction pass.

```sh
sh run.sh          # needs a built cocolog and a running server
```

| file | what |
|---|---|
| `trainer.pl` | the ring data, the shard split, `train_part/1` |
| `accumulate.pl` | chunk join, `avg3/4`, accumulate → test → predict |
| `run.sh` | wires it: parallel trainers, the poll, the export, the accumulate |

Each part's connection is an environment variable (`PART1_OPTS` etc.),
so the three trainers can sit on three different servers and the
accumulator on a fourth; the defaults put four knowledge bases on one.
