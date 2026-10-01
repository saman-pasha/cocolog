# The language benchmark: cocolog against CPython

Five small programs, the same task in each language, every lane's answer
checked against every other's before a number may print.

```sh
make                       # the binary under test is this checkout's
sh bench/langs.sh          # every lane; the server lane when one answers on 2160
```

| file | what |
|---|---|
| `langs.sh` | the harness: the lanes, the answer gate, the calibration, the two sizes |
| `langs/` | the five tasks, each as a cocolog program, a CPython program and a CPython + sqlite3 program |

**IT MOVED HERE FROM THE COCO** (`saman-pasha/coco`, `bench/`) on
2026-10-01, because what it measures is cocolog. It brought its programs
and every run it ever printed, below, none of them deleted: a superseded
reading is a different claim, not a wrong one, and a benchmark that keeps
only its best number is a benchmark nobody can check. The Coco's chain
benchmarks (`tps.sh`, `solana.sh`, `poh.sh`) and its written comparison
of the three languages,
[`languages.md`](https://github.com/saman-pasha/coco/blob/master/bench/languages.md),
stay there.

What changed in the move: `langs.sh` reads its binary, library and server
from this checkout instead of The Coco's `test/config.sh`; it finds a
nanosecond clock and a `timeout` on a stock Mac; and it looks through a
pyenv shim to the interpreter behind it, which Run H found costing seconds
a call. Two comments in `langs/lookup.pl` and `langs/lookup_sqlite.py` said
cocolog has no clause indexing; it has had a first-argument index since
Run C, and they say so now. The programs are otherwise byte for byte The
Coco's.

## Where it stands

`bench/langs.sh`, **Run J** -- 2026-10-01, cocolog 1.8.36, the box of Runs
H and I (Intel i9-9880H, 16 GB, macOS 26.6.2, Python 3.11.13). Per rep, and
the multiple of CPython beside it:

| task (one rep) | cocolog --local | cpython | cocolog --embed | cocolog zigurat | cpython + sqlite3 |
|---|---|---|---|---|---|
| nrev, 400-element list | 0.051387 s (9.8x) | 0.005259 s | 0.051739 s (9.8x) | 0.050893 s (9.7x) | 0.005043 s (1.0x) |
| queens, all 92 solutions | 0.036254 s (17.2x) | 0.002109 s | 0.038645 s (18.3x) | 0.037006 s (17.5x) | 0.002153 s (1.0x) |
| loop, 100 000 additions | 0.097526 s (21.7x) | 0.004491 s | 0.092748 s (20.7x) | 0.095675 s (21.3x) | 0.028220 s (6.3x) |
| lookup, 1000 probes / 200 facts | 0.002013 s (18.3x) | 0.000110 s | 0.001742 s (15.8x) | 0.001825 s (16.6x) | 0.011699 s (106.4x) |
| sortnums, 5000 integers | 0.012551 s (6.8x) | 0.001844 s | 0.013382 s (7.3x) | 0.012737 s (6.9x) | 0.002653 s (1.4x) |

**As a language, 7-22x CPython on this box**, the three cocolog
arrangements within a few percent of one another on every task. **As a
state machine the column still splits by where the work is**: over durable
data that the work only reads, sqlite costs CPython 1.0-1.4x over its dict;
where the work IS the store, the cursor's addends cost it 6.3x on the
counting loop, and the thousand keyed probes cost python + sqlite3 6.7x what
they cost `--embed`.

**And cocolog has lost ground since Run I on this box**, by more than the
box moved: per rep, queens +63% where CPython moved +7%, nrev +48% (CPython
+26%), sortnums +25% (+6%), loop +22% (+7%); lookup is level. **1.8.36 is
not the cause** -- paired against 1.8.35 in one sitting it is level on
queens and 15-23% faster on the other three (Run J's section). **And paired
against Run I's own source** -- `ad3660d`, built the same day by the same
Cicili and clang -- 1.8.37 takes 57% longer on queens, 31% on nrev, 13% on
loop and sortnums, and 6% less on lookup. Same transpiler, same box, one
sitting: the cost is in cocolog's own changes since 2026-08-31. Which of
the 351 commits is not found; a bisection between the two would find it.

## The rules

`langs.sh`'s header is the authority; in short:

1. **The answer is verified, lane against lane.** Every program prints
   `answer(X)`, and a lane whose X differs from Python's is REFUSED and
   prints no number.
2. **The run is long enough.** Reps are calibrated per lane, doubling
   until a run clears 1.2 s, so no reading is start-up.
3. **The arrangement is named on every row**: `local` has no database,
   `embed` is the MVCCS engine linked in, `zigurat` the same store over a
   socket, `sqlite` a CPython with a committed, indexed file.
4. **The clock is the wall**, around the whole process.
5. **The calibration runs are the warm-up**; the timed runs come after.
6. **Every lane is measured at R and 2R**, so a fixed cost can be told
   from a per-rep one; `2R/R` near 2.0 is linear. A lane that calibrates
   to ONE rep prints its wall time instead of a rate.

And the pairing: **Python is a language; cocolog is a language and a
state machine.** `python` against `local` is the language comparison;
`embed` and `zigurat` keep durable rows in a committed turn, so their
partner is `sqlite`, not a dict.

**What no rule can catch is which tasks were chosen.** Five small programs
are not a language, and these five include the ones cocolog is expected
to lose.

## The runs, oldest first

**Runs A to I were taken in The Coco's tree** and are copied here as its
`bench/README.md` printed them; their paths and cross-references
(`harness.pl`, `languages.md`, Run E, rung 5) are The Coco's. Run H's
`poh.sh` transcript is The Coco's chain and stays there.

### cocolog against CPython, on the same five programs

`sh bench/langs.sh`. This is the number `languages.md` spent a whole
section declining to state, and the answer is that **cocolog is slow --
between one and two orders of magnitude slower than CPython -- and the
spread across tasks is the useful part.**

The rules are `harness.pl`'s, adapted: every lane must answer the SAME
value or nothing is printed; reps are calibrated per lane so no reading
is start-up wearing a number's clothes; the arrangement is named on
every row; the clock is the wall. Two additions this comparison needed:
each lane is measured at R and 2R so a fixed cost can be told from a
per-unit one, and **a lane that calibrates to one rep prints its wall
time instead of a rate**, because at one rep the two cannot be
separated.

**PYTHON IS A LANGUAGE AND COCOLOG IS A LANGUAGE PLUS A STATE MACHINE**,
so the rows are read in two families. `python` against `local` is the
language comparison: an algorithm in memory, nothing kept, on both
sides. `embed` and `zigurat` are a DATABASE -- durable rows, a
committed turn, a second process that can read them -- and their fair
partner is not a dict but `sqlite`, which is in the lookup table for
exactly that reason.

Both runs are kept, oldest first, per this file's own rule. **Run A is
superseded and not deleted**: it printed two rows the one-rep rule now
refuses (a lookup ratio of 1163220x and a sort ratio of 0.0x, both
arithmetic out of two runs dominated by fixed cost), and its numbers
were taken while a stray `--embed lookup` from a killed run was burning
a core -- which is why its store lanes came out FASTER than memory, an
impossibility that is what led to the cap and the stray-killer at the
top of the script.

#### Run A, superseded (a stray process on the box, and no one-rep rule)

```
cocolog vs CPython -- same task, same answer, four arrangements
python3 3.11.15, cocolog cocolog at /home/user/cocolog/cocolog
wall clock, median of three timed runs at each of two sizes

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.01     0.006650      1.0x    1.99  cpython_process
   local          32    0.00     0.072650     10.9x    2.58  cocolog_local_in_memory_no_database
   embed          32    0.00     0.043933      6.6x    2.02  cocolog_embedded_mvccs_fresh_store
   zigurat        32    0.00     0.046407      7.0x    2.01  cocolog_server_one_kb_emptied

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.00     0.001891      1.0x    2.01  cpython_process
   local          64    0.03     0.024636     13.0x    1.98  cocolog_local_in_memory_no_database
   embed          64    0.03     0.025542     13.5x    1.98  cocolog_embedded_mvccs_fresh_store
   zigurat        64    0.08     0.024302     12.9x    1.95  cocolog_server_one_kb_emptied

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        512    0.04     0.003156      1.0x    1.98  cpython_process
   local          16    0.00     0.196926     62.4x    2.83  cocolog_local_in_memory_no_database
   embed          16    0.00     0.214648     68.0x    3.08  cocolog_embedded_mvccs_fresh_store
   zigurat        16    0.00     0.107104     33.9x    2.02  cocolog_server_one_kb_emptied

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python      16384    0.00     0.000075      1.0x    2.01  cpython_process
   local         256    0.00     0.006246     83.3x    2.00  cocolog_local_in_memory_no_database
   embed           1   17.03     0.230906   3078.7x    1.01  cocolog_embedded_mvccs_fresh_store
   zigurat         1  125.52    87.241509 1163220.1x    1.41  cocolog_server_one_kb_emptied
   sqlite        512    0.00     0.004568     60.9x    2.01  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.00     0.001455      1.0x    2.02  cpython_process
   local         128    0.00     0.016594     11.4x    2.15  cocolog_local_in_memory_no_database
   embed         128    0.00     0.015543     10.7x    2.07  cocolog_embedded_mvccs_fresh_store
   zigurat         1    6.82     0.000000      0.0x    1.00  cocolog_server_one_kb_emptied

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.02 s
   local          0.01 s
   embed          0.01 s
   zigurat        0.01 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s    cocolog s      ratio
        200         0.02         0.13         8x
       2000         0.02         0.82        48x
      20000         0.02         8.15       428x
```

#### Run B, the reading

```
cocolog vs CPython -- same task, same answer, four arrangements
python3 3.11.15, cocolog cocolog at /home/user/cocolog/cocolog
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.02     0.006625      1.0x    1.99  cpython_process
   local          32    0.00     0.045423      6.9x    2.02  cocolog_local_in_memory_no_database
   embed          32    0.00     0.043098      6.5x    2.02  cocolog_embedded_mvccs_fresh_store
   zigurat         1    9.50      one rep   no rate       -  cocolog_server_one_kb_emptied

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.06     0.001754      1.0x    1.97  cpython_process
   local          64    0.00     0.025445     14.5x    2.03  cocolog_local_in_memory_no_database
   embed          64    0.00     0.025698     14.7x    2.00  cocolog_embedded_mvccs_fresh_store
   zigurat         1   10.72      one rep   no rate       -  cocolog_server_one_kb_emptied

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        512    0.01     0.003186      1.0x    1.99  cpython_process
   local          16    0.00     0.110096     34.6x    2.07  cocolog_local_in_memory_no_database
   embed          16    0.00     0.103884     32.6x    2.00  cocolog_embedded_mvccs_fresh_store
   zigurat         1    5.08      one rep   no rate       -  cocolog_server_one_kb_emptied

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python      16384    0.00     0.000075      1.0x    2.00  cpython_process
   local         256    0.10     0.005979     79.7x    1.94  cocolog_local_in_memory_no_database
   embed           1   17.18      one rep   no rate       -  cocolog_embedded_mvccs_fresh_store
   zigurat         1       -            -         -       -  REFUSED: answered NONE, not answer(413500)
   sqlite        512    0.00     0.004530     60.4x    2.00  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.02     0.001408      1.0x    1.98  cpython_process
   local         128    0.00     0.016738     11.9x    2.17  cocolog_local_in_memory_no_database
   embed         128    0.00     0.019811     14.1x    2.40  cocolog_embedded_mvccs_fresh_store
   zigurat         1    9.00      one rep   no rate       -  cocolog_server_one_kb_emptied

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.01 s
   local          0.01 s
   embed          0.01 s
   zigurat        0.01 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s    cocolog s      ratio
        200         0.02         0.13         7x
       2000         0.02         0.82        49x
      20000         0.02         7.95       411x
```

**What survives both runs, and the container's own noise** -- this file
has already measured 39-56% swings between runs of byte-identical
machine code, so only order-of-magnitude claims are safe:

* **In memory, cocolog is 7-11x slower on list building, 13-15x on
  backtracking search, 11-14x on generate-and-sort, 35-62x on a tight
  counting loop, and 80-83x on a keyed lookup over 200 facts.** Search
  is its best showing, which is the thing a Prolog engine is for; the
  counting loop is its worst, which is the per-inference cost of a
  continuation-passing interpreter with no compilation step.
* **Start-up is not the reason, and the guess that it was is dead**:
  every arrangement boots in 0.01s, the same as Python.
* **Reading costs a constant; writing costs a fortune.** On every
  compute task the embedded store is within a few percent of the
  in-memory arrangement, so the database does not slow the thinking
  down. But 200 `assertz` plus a thousand probes cost 17.2s embedded,
  and over the server the same work did not finish inside a 300-second
  cap -- the answer gate refused to print a number for it, which is the
  most useful thing it could have said.
* **Durability is not free in Python either**: the sqlite lane, with an
  index and one committed transaction, is 60x slower than the dict it
  replaces.
* **The lookup gap is a slope, not a factor** -- 7x at 200 facts, 49x at
  2000, 411x at 20000, against a flat Python dict. That is
  `languages.md`'s "no clause indexing" sentence with numbers on it, and
  first-argument indexing is the one change that would move it. It is
  cocolog's to make.

#### Run C: cocolog made both changes, and the two worst readings are gone

**THE BENCHMARK WAS THE POINT.** Two of Run B's readings named specific
defects rather than a slow interpreter, both were diagnosed in cocolog, and
both were fixed THERE on their own merits with that repository's own gate --
39 of 39 GREEN, `red: 0`, no SKIPs, on a fresh store. The Coco changed
nothing; it measured, and the pillar answered.

* **The turn's writes are batched.** Writing a clause through re-sends the
  whole predicate, and the batching that made a CONSULT cheap was switched
  off before the goal ran -- so `assertz` in a loop paid a
  forget-and-resend per clause.
* **Clauses are indexed on their first argument.** A call used to COPY each
  clause onto the heap and unify its head, so a probe into a table of facts
  copied the table.

The run as it printed:

```

cocolog vs CPython -- same task, same answer, four arrangements
python3 3.11.15, cocolog cocolog at /home/user/cocolog/cocolog
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.01     0.006611      1.0x    1.99  cpython_process
   local          64    0.00     0.102208     15.5x    3.36  cocolog_local_in_memory_no_database
   embed          32    0.06     0.035925      5.4x    1.95  cocolog_embedded_mvccs_fresh_store
   zigurat        32    0.00     0.041589      6.3x    2.08  cocolog_server_one_kb_emptied

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.06     0.001772      1.0x    1.97  cpython_process
   local          64    0.04     0.025366     14.3x    1.97  cocolog_local_in_memory_no_database
   embed          64    0.03     0.024442     13.8x    1.98  cocolog_embedded_mvccs_fresh_store
   zigurat        64    0.02     0.026193     14.8x    1.99  cocolog_server_one_kb_emptied

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        512    0.04     0.003141      1.0x    1.98  cpython_process
   local          16    0.00     0.106376     33.9x    2.07  cocolog_local_in_memory_no_database
   embed          16    0.00     0.124958     39.8x    2.22  cocolog_embedded_mvccs_fresh_store
   zigurat        16    0.00     0.117044     37.3x    2.22  cocolog_server_one_kb_emptied

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python      16384    0.00     0.000076      1.0x    2.00  cpython_process
   local        1024    0.00     0.003614     47.6x    2.58  cocolog_local_in_memory_no_database
   embed         512    0.06     0.002291     30.1x    1.95  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.23     0.002494     32.8x    1.85  cocolog_server_one_kb_emptied
   sqlite        512    0.06     0.004432     58.3x    1.97  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.07     0.001392      1.0x    1.96  cpython_process
   local         128    0.04     0.012735      9.1x    1.98  cocolog_local_in_memory_no_database
   embed         128    0.00     0.012850      9.2x    2.00  cocolog_embedded_mvccs_fresh_store
   zigurat       128    0.22     0.013391      9.6x    1.89  cocolog_server_one_kb_emptied

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.01 s
   local          0.01 s
   embed          0.01 s
   zigurat        0.01 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s    cocolog s      ratio
        200         0.02         0.06         3x
       2000         0.02         0.06         3x
      20000         0.02         0.09         4x
```

The four columns, on the lookup task -- a thousand key lookups over 200
facts, per sweep, Run B against Run C:

| | cocolog --local | cpython | cocolog --embed | cpython + sqlite3 |
|---|---|---|---|---|
| arrangement | in memory, no database | dict, in memory | MVCCS in-process | file, PRIMARY KEY index, one commit |
| **Run B** | 0.005979 s (79.7x) | 0.000075 s | one rep, **17.18 s wall** | 0.004530 s (60.4x) |
| **Run C** | 0.003614 s (47.6x) | 0.000076 s | **0.002291 s (30.1x)** | 0.004432 s (58.3x) |

And the slope, which is the reading this whole file existed to produce --
`--local`, so no store is in it at all:

| facts | Run B | Run C |
|---|---|---|
| 200 | 7x | **3x** |
| 2 000 | 49x | **3x** |
| 20 000 | 411x | **4x** |

**A ratio that grew with N was the signature.** It is flat now, and that is
the whole of the first-argument index in one line.

The other four tasks, per rep, the same four columns (only `lookup` has a
durable-Python counterpart written, so the fourth column is empty by
construction rather than by omission):

| task (one rep) | cocolog --local | cpython | cocolog --embed | cpython + sqlite3 |
|---|---|---|---|---|
| nrev, 400-element list | ~0.0387 s (5.9x) † | 0.006611 s | 0.035925 s (5.4x) | -- |
| queens, all 92 solutions | 0.025366 s (14.3x) | 0.001772 s | 0.024442 s (13.8x) | -- |
| loop, 100 000 additions | 0.106376 s (33.9x) | 0.003141 s | 0.124958 s (39.8x) | -- |
| lookup, 1000 probes / 200 facts | 0.003614 s (47.6x) | 0.000076 s | 0.002291 s (30.1x) | 0.004432 s (58.3x) |
| sortnums, 5000 integers | 0.012735 s (9.1x) | 0.001392 s | 0.012850 s (9.2x) | -- |

**Three things this run does NOT get to claim**, and they are here because
a benchmark that reports only what flatters it is not one:

* **† The `nrev local` row the harness printed is wrong**, and its own
  shape column said so: `2R/R` of **3.36**, where 2.0 is linear. It printed
  0.102208 s and 15.5x. Re-measured at R=64, three runs: 0.039391,
  0.039185, 0.038652 -- so about **5.9x**, an improvement on Run B's 6.9x.
  The R=128 point swung 0.0387-0.0624 across three runs, which is what
  poisoned the second measurement. Container noise, not a regression, and
  the table above carries the re-measurement with a dagger rather than the
  harness's number.
* **The whole `zigurat` column is CONFOUNDED and is not in the tables.**
  It went from "one rep, no rate" (5-11 s wall each, and a REFUSAL on
  lookup) to real rates -- nrev 0.041589, queens 0.026193, loop 0.117044,
  lookup 0.002494, sortnums 0.013391. But the server was restarted on a
  FRESH store between the two runs and Run B measured a 76 MB aged one.
  Some of that column is the fix and some is the restart, and this run
  cannot separate them. `--embed` is clean, because it builds a fresh store
  per run in both.
* **`embed` beating `local` on lookup is not a finding.** 0.002291 against
  0.003614, with the local row's shape at 2.58 -- inside the noise. An
  in-memory lane cannot really be slower than the same lane with a database
  under it.

What DID change, stated as narrowly as the evidence allows: the lookup
slope is flat, the embedded store went from refusing to give a rate at all
to beating Python's own durable store on the same task, and the server lane
answers a task it could not finish inside a 300-second cap. What did NOT
change is cocolog as a LANGUAGE -- 6-34x CPython on the four compute tasks,
because neither fix touches the per-inference cost of a
continuation-passing interpreter with no compilation step. That number is
still the honest one, and it is still the one nobody has attacked.

### Run H: a second box -- macOS, and the first honest zigurat column

**THE BOX CHANGED, SO NOTHING HERE COMPARES ACROSS RUNS WITHOUT SAYING
SO.** Every run above was one Linux machine; this one is a Mac -- Intel
i9-9880H (8 cores/16 threads, 2.3 GHz), 16 GB, macOS, Python 3.11.13,
cocolog at master (mapped embedded store), ZiguratIP server on the same
box with the mapped store and the (kb, name) composite index. Rule 6
applies with both hands: same-run columns compare, cross-run columns are
two claims about two computers.

And one harness finding before any number: **the pyenv shim is not
Python.** `python3` on this box resolves through a pyenv shim that costs
1.8-3.7 s per invocation before the interpreter exists; the real binary
boots in 0.13 s. The shim would have poisoned every python lane's
calibration (the shim alone clears the one-second floor), so the bench
ran with the real interpreter first on PATH. A wrapper that spends
seconds deciding which Python to run is part of nobody's language.

**Two harness findings before the numbers, both fixed in this commit:**
the arrangement-label column was a multi-line `case` inside `$(...)`,
which dash parses and macOS bash-as-sh refuses -- the first run printed
every number correctly and mangled every label beside it, so the label
is a named function now (`arr_name`); and `library(spine)` would not
LINK on a Mac at all, because The Coco's `tools/cc` wrappers had
drifted from cocolog's and lacked the Darwin
`-Wl,-undefined,dynamic_lookup` rule a loadable module needs -- the
wrappers are cocolog's own two files again, copied whole.

**What the run found:**

* **The `zigurat` column is a measurement at last.** Run B refused it,
  Run C confounded it; here it calibrated to real rep counts on all
  five tasks and landed within a few percent of `local` and `--embed`
  on every one -- nrev 7.4x, queens 11.1x, loop 18.6x, lookup 19.5x,
  sortnums 6.0x against python's 1.0x. A turn over a socket, committed
  against a store the harness empties per run, costs this workload
  nothing the two-point method can see: the pipelined client, the
  turn-wide write batch and the mapped store are the difference between
  this column and Run B's five-to-eleven-second walls.
* **As a language, 6-19x CPython on this box** -- search and sort at
  6-11x, the tight loop and the keyed probe at 19x. The Linux box read
  6-34x; the shape (search best, loop worst) survives the box change,
  the constants do not, and per rule 6 neither number corrects the
  other.
* **Durability costs Python more than it costs cocolog here.** The one
  task with a durable Python counterpart has python + sqlite3 at
  0.012222 s per thousand probes against `--embed`'s 0.001850 s --
  6.6x, same run, same promises (a file, an index, a commit).
* **The slope stayed flat, but the slope TABLE is boot-dominated on
  this box** -- every wall in it sits within 0.06 s of the lane's own
  start-up, so its `1x` ratios claim boot parity, not engine parity.
  The engine reading is cocolog's own column: 0.20 s at 200 facts,
  0.22 s at 20 000.
* **The spine produces at 4.1-4.2M ticks/s and four verifiers audit it
  3.1-3.6x faster than one** (the Linux box: 3.2M and 3.9x -- more
  cores in that ratio's denominator, per rule 6 again). The clause
  oracle agrees with the C module at both sizes and costs 11x.

#### `langs.sh`, the clean transcript

```

cocolog vs CPython -- same task, same answer, four arrangements
python3 3.11.13, cocolog cocolog at /Users/a1/Projects/GitHub/cocolog/cocolog
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.23     0.004751      1.0x    1.84  cpython_process
   local          32    0.48     0.030445      6.4x    1.67  cocolog_local_in_memory_no_database
   embed          32    0.23     0.034478      7.3x    1.83  cocolog_embedded_mvccs_fresh_store
   zigurat        32    0.22     0.035045      7.4x    1.84  cocolog_server_one_kb_emptied

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.14     0.001989      1.0x    1.93  cpython_process
   local          64    0.17     0.021928     11.0x    1.89  cocolog_local_in_memory_no_database
   embed          64    0.19     0.021807     11.0x    1.88  cocolog_embedded_mvccs_fresh_store
   zigurat        64    0.20     0.022148     11.1x    1.88  cocolog_server_one_kb_emptied

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.16     0.004218      1.0x    1.87  cpython_process
   local          16    0.16     0.078728     18.7x    1.88  cocolog_local_in_memory_no_database
   embed          16    0.18     0.079328     18.8x    1.88  cocolog_embedded_mvccs_fresh_store
   zigurat        16    0.23     0.078531     18.6x    1.85  cocolog_server_one_kb_emptied

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python      16384    0.16     0.000097      1.0x    1.91  cpython_process
   local        1024    0.20     0.001815     18.7x    1.90  cocolog_local_in_memory_no_database
   embed        1024    0.17     0.001850     19.1x    1.92  cocolog_embedded_mvccs_fresh_store
   zigurat      1024    0.18     0.001896     19.5x    1.92  cocolog_server_one_kb_emptied
   sqlite        128    0.11     0.012222    126.0x    1.93  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.19     0.001700      1.0x    1.90  cpython_process
   local         128    0.17     0.010233      6.0x    1.89  cocolog_local_in_memory_no_database
   embed         128    0.20     0.010259      6.0x    1.87  cocolog_embedded_mvccs_fresh_store
   zigurat       128    0.21     0.010241      6.0x    1.86  cocolog_server_one_kb_emptied

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.11 s
   local          0.10 s
   embed          0.11 s
   zigurat        0.16 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s    cocolog s      ratio
        200         0.17         0.20         1x
       2000         0.16         0.19         1x
      20000         0.17         0.22         1x

```

The first attempt of the same day -- the one with the mangled labels --
agreed within noise on every reading (per rep: nrev 6.2/7.2/7.0x, queens
11.3/11.2/10.9x, loop 19.0/18.6/18.8x, lookup 19.2/19.4/19.6x with
sqlite 124.7x, sortnums 6.2/6.2/5.9x), so the table above rests on two
runs of three medians each rather than one.

### Run I: the state-machine column, filled

Run H's table carried `--` in four of its five sqlite cells, because
`langs/` had a durable-Python counterpart written only for lookup. The
owner asked for the column whole, so the four counterparts now exist --
each to `lookup_sqlite.py`'s own pairing rule (a file on disk, the
task's data built as rows in one committed transaction, every rep
reading it back through the database), each verified against its python
twin by the answer gate before any number printed:

* `nrev_sqlite.py` -- the 400-element list is a table; each rep reads
  it back in key order and does the same quadratic reverse in memory.
* `queens_sqlite.py` -- the board's domain is a table; the search is
  the same backtracking in memory, which is also what cocolog's store
  lanes do with it. Its row reading close to plain cpython is the
  finding, not a flaw: durability costs a search nothing, either side.
* `loop_sqlite.py` -- the addends 1..N are rows and every rep sums
  them one cursor row at a time: the store pays per step, beside
  cocolog's lanes paying an inference per step.
* `sortnums_sqlite.py` -- the LCG values are rows and each rep asks
  the database itself for them in order (`ORDER BY v`, no index on v):
  the one counterpart where the work goes THROUGH the store, because
  sorting is a thing a store does.

Same box as Run H, same rules, one run of three medians at two sizes:

```

cocolog vs CPython -- same task, same answer, four arrangements
python3 3.11.13, cocolog cocolog at /Users/a1/Projects/GitHub/cocolog/cocolog
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.37     0.004186      1.0x    1.74  cpython_process
   local          32    0.18     0.034682      8.3x    1.86  cocolog_local_in_memory_no_database
   embed          32    0.18     0.035370      8.4x    1.87  cocolog_embedded_mvccs_fresh_store
   zigurat        32    0.22     0.034849      8.3x    1.83  cocolog_server_one_kb_emptied
   sqlite        256    0.17     0.004852      1.2x    1.88  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.16     0.001973      1.0x    1.93  cpython_process
   local          64    0.12     0.022249     11.3x    1.93  cocolog_local_in_memory_no_database
   embed          64    0.18     0.021706     11.0x    1.88  cocolog_embedded_mvccs_fresh_store
   zigurat        64    0.19     0.021999     11.2x    1.88  cocolog_server_one_kb_emptied
   sqlite       1024    0.17     0.001957      1.0x    1.92  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.16     0.004188      1.0x    1.87  cpython_process
   local          16    0.13     0.080093     19.1x    1.91  cocolog_local_in_memory_no_database
   embed          16    0.14     0.081349     19.4x    1.90  cocolog_embedded_mvccs_fresh_store
   zigurat        16    0.19     0.079177     18.9x    1.87  cocolog_server_one_kb_emptied
   sqlite         64    0.16     0.028561      6.8x    1.92  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python      16384    0.36     0.000096      1.0x    1.81  cpython_process
   local        1024    0.33     0.001773     18.5x    1.84  cocolog_local_in_memory_no_database
   embed        1024    0.13     0.001886     19.6x    1.94  cocolog_embedded_mvccs_fresh_store
   zigurat      1024    0.27     0.001820     19.0x    1.87  cocolog_server_one_kb_emptied
   sqlite        128    0.14     0.012229    127.4x    1.92  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.14     0.001744      1.0x    1.93  cpython_process
   local         128    0.20     0.010062      5.8x    1.87  cocolog_local_in_memory_no_database
   embed         128    0.18     0.010205      5.9x    1.88  cocolog_embedded_mvccs_fresh_store
   zigurat       128    0.19     0.010286      5.9x    1.87  cocolog_server_one_kb_emptied
   sqlite        512    0.18     0.002480      1.4x    1.88  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.12 s
   local          0.10 s
   embed          0.12 s
   zigurat        0.16 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s    cocolog s      ratio
        200         0.17         0.18         1x
       2000         0.16         0.19         1x
      20000         0.17         0.22         1x

```

**The reading.** The filled column is two findings at once. Where the
task is computation over durable data, sqlite's premium over the bare
dict is 1.0-1.4x -- the same near-nothing cocolog's own store lanes pay
over `--local` -- so the pair's gap stays the LANGUAGE gap, and that is
symmetric honesty: a store attached slows nobody's thinking. Where the
work is per-row store traffic, the sides trade: the cursor hands sqlite
its addends at 6.8x the dict's price on the loop, and on the thousand
keyed probes -- the one task where every rep hammers the store by key --
cocolog's `--embed` answers 6.5x faster than sqlite's indexed,
committed file. The lanes Run H and Run I share agree within the box's
few-percent band throughout; nrev's python side drifted from 0.004751
to 0.004186 and its ratios moved with it -- the band, not a change.

### Run J: moved into cocolog, and 1.8.36

**The first run in cocolog's tree**, on the box of Runs H and I -- Intel
i9-9880H, 16 GB, now macOS 26.6.2 -- with cocolog 1.8.36, whose heap is
collected between engine steps, and Python 3.11.13: the real interpreter,
which `langs.sh` now finds behind the pyenv shim by itself (the shim costs
2.0 s a call on this box today; the interpreter 0.14 s). The ZiguratIP
server was restarted first, having been up twelve days, and vacuumed to
141 live rows.

**The first attempt is superseded, and kept.** It started at 15:08 while
Docker Desktop was being installed on the same box -- a 645 MB image
unpacked and copied, the one-minute load average at 9.8 -- and it read the
way a contended box reads: `--local` slower than `--embed` on nrev, 11.9x
where the clean run says 9.8x. It was stopped after a task and a half:

```

cocolog vs CPython -- same task, same answer, four arrangements
python3 3.11.13 at /Users/a1/.pyenv/versions/3.11.13/bin/python3, cocolog 1.8.36 at /Users/a1/Projects/GitHub/cocolog/cocolog
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.18     0.004975      1.0x    1.88  cpython_process
   local          32    0.00     0.059312     11.9x    2.02  cocolog_local_in_memory_no_database
   embed          32    0.33     0.048942      9.8x    1.83  cocolog_embedded_mvccs_fresh_store
   zigurat        32    0.29     0.051421     10.3x    1.85  cocolog_server_one_kb_emptied
   sqlite        256    0.10     0.005473      1.1x    1.93  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        512    0.37     0.002065      1.0x    1.74  cpython_process
   local          32    0.16     0.040009     19.4x    1.89  cocolog_local_in_memory_no_database
```

**What the clean run reads, against Run I**, the same box a month and 351
cocolog commits earlier: CPython moved +6% to +26% per rep, cocolog's
in-memory lane +14% (lookup) to +63% (queens). The ratios grew on four of
the five tasks -- nrev 8.3x to 9.8x, queens 11.3x to 17.2x, loop 19.1x to
21.7x, sortnums 5.8x to 6.8x; lookup held at 18.5x and 18.3x. The two-point
shape is clean throughout (`2R/R` 1.73-1.97), the start-ups are 0.12-0.18 s
on all four lanes, and the lookup slope stays flat within boot noise: 0.22 s
to 0.29 s across a hundredfold more facts.

**Paired, 1.8.36 is not what slowed it.** The same programs, five
alternating rounds of 1.8.35 and 1.8.36 in one sitting, whole-process wall,
median:

| program | 1.8.35 | 1.8.36 | 1.8.36, collector off |
|---|---:|---:|---:|
| `nrev` x32 | 2.054 s | **1.751 s** | 2.054 s |
| `queens` x64 | 2.432 s | 2.442 s | |
| `loop` x32 | 4.005 s | **3.081 s** | |
| `sortnums` x256 | 4.169 s | **3.344 s** | |

The collector makes the three allocating tasks 15-23% faster and leaves the
search where it was; with it switched off (`COCOLOG_GC_CELLS` past the
heap) nrev is 1.8.35 again to the millisecond.

**And against Run I's own cocolog**, the same way: `ad3660d` taken out of
git and built beside 1.8.37 by the same Cicili and the same clang, five
alternating rounds, after the Docker build on this box had finished and
its VM was stopped:

| program | `ad3660d` | 1.8.37 | 1.8.37 / `ad3660d` |
|---|---:|---:|---:|
| `nrev` x32 | 1.322 s | 1.731 s | 1.31 |
| `queens` x64 | 1.569 s | 2.467 s | 1.57 |
| `loop` x32 | 2.770 s | 3.127 s | 1.13 |
| `lookup` x1024 | 2.136 s | 2.003 s | 0.94 |
| `sortnums` x256 | 3.079 s | 3.492 s | 1.13 |

The transpiler and the box are the same on both sides of each pair, so
what Run I to Run J shows is cocolog's own: its search takes 57% longer
than a month ago, and its allocating tasks 13-31% longer even after the
collector took 15-23% back. Which of the 351 commits between them did it is not
found here.

```

cocolog vs CPython -- same task, same answer, four arrangements
python3 3.11.13 at /Users/a1/.pyenv/versions/3.11.13/bin/python3, cocolog 1.8.36 at /Users/a1/Projects/GitHub/cocolog/cocolog
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.11     0.005259      1.0x    1.92  cpython_process
   local          32    0.21     0.051387      9.8x    1.89  cocolog_local_in_memory_no_database
   embed          32    0.15     0.051739      9.8x    1.92  cocolog_embedded_mvccs_fresh_store
   zigurat        32    0.38     0.050893      9.7x    1.81  cocolog_server_one_kb_emptied
   sqlite        256    0.26     0.005043      1.0x    1.83  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        512    0.18     0.002109      1.0x    1.86  cpython_process
   local          32    0.22     0.036254     17.2x    1.84  cocolog_local_in_memory_no_database
   embed          32    0.19     0.038645     18.3x    1.87  cocolog_embedded_mvccs_fresh_store
   zigurat        32    0.23     0.037006     17.5x    1.84  cocolog_server_one_kb_emptied
   sqlite        512    0.15     0.002153      1.0x    1.88  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python        256    0.16     0.004491      1.0x    1.88  cpython_process
   local          16    0.15     0.097526     21.7x    1.91  cocolog_local_in_memory_no_database
   embed          16    0.26     0.092748     20.7x    1.85  cocolog_embedded_mvccs_fresh_store
   zigurat        16    0.26     0.095675     21.3x    1.85  cocolog_server_one_kb_emptied
   sqlite         32    0.34     0.028220      6.3x    1.73  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python      16384    0.06     0.000110      1.0x    1.97  cpython_process
   local        1024    0.06     0.002013     18.3x    1.97  cocolog_local_in_memory_no_database
   embed        1024    0.32     0.001742     15.8x    1.85  cocolog_embedded_mvccs_fresh_store
   zigurat      1024    0.18     0.001825     16.6x    1.91  cocolog_server_one_kb_emptied
   sqlite        128    0.30     0.011699    106.4x    1.83  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py    2R/R  arrangement
   python       1024    0.17     0.001844      1.0x    1.92  cpython_process
   local         128    0.24     0.012551      6.8x    1.87  cocolog_local_in_memory_no_database
   embed         128    0.07     0.013382      7.3x    1.96  cocolog_embedded_mvccs_fresh_store
   zigurat       128    0.30     0.012737      6.9x    1.85  cocolog_server_one_kb_emptied
   sqlite        512    0.22     0.002653      1.4x    1.86  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.14 s
   local          0.12 s
   embed          0.14 s
   zigurat        0.18 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s    cocolog s      ratio
        200         0.20         0.22         1x
       2000         0.18         0.24         1x
      20000         0.21         0.29         1x
```
