# The language benchmark: cocolog against CPython and SWI-Prolog

Five small programs, the same task in each language, every lane's answer
checked against every other's before a number may print. SWI-Prolog runs
the cocolog programs themselves, unedited, with `-O` and without (`swipl`
on the PATH or `SWIPL=...`, else those two lanes are skipped).

```sh
make                       # the binary under test is this checkout's
sh bench/langs.sh          # every lane; the server lane when one answers on 2160
```

| file | what |
|---|---|
| `langs.sh` | the harness: the lanes, the answer gate, the calibration, the two sizes |
| `langs/` | the five tasks, each as a Prolog program (cocolog and SWI-Prolog run the same file), a CPython program and a CPython + sqlite3 program |

**IT MOVED HERE FROM THE COCO** (`saman-pasha/coco`, `bench/`) on
2026-10-01, because what it measures is cocolog. The Coco's chain
benchmarks (`tps.sh`, `solana.sh`, `poh.sh`) and its written comparison
of the three languages,
[`languages.md`](https://github.com/saman-pasha/coco/blob/master/bench/languages.md),
stay there.

**The runs kept here start at 1.8.48.** Runs A to L -- from The Coco's
first, in August, to 1.8.44 -- were removed on 2026-10-03, the owner's
call; `git show f544cca:bench/README.md` still prints every one of them,
superseded readings and all.

What changed in the move: `langs.sh` reads its binary, library and server
from this checkout instead of The Coco's `test/config.sh`; it finds a
nanosecond clock and a `timeout` on a stock Mac; and it looks through a
pyenv shim to the interpreter behind it, which on the Mac costs seconds a
call. Two comments in `langs/lookup.pl` and `langs/lookup_sqlite.py` said
cocolog has no clause indexing; it has a first-argument index, and they
say so now. The programs are otherwise byte for byte The Coco's.

## Where it stands

`bench/langs.sh`, **Run N** -- 2026-10-03, cocolog 1.8.48, an Intel
i9-9880H Mac (16 GB, macOS 26.6.2), Python 3.11.13, SWI-Prolog 10.0.2. Per
rep, and the multiples of CPython and of SWI-Prolog with `-O` beside it:

| task (one rep) | cocolog --local | cpython | swipl -O | swipl | cocolog --embed | cocolog zigurat | cpython + sqlite3 |
|---|---|---|---|---|---|---|---|
| nrev, 400-element list | 0.004908 s (1.1x, 1.9x) | 0.004614 s | 0.002589 s | 0.002931 s | 0.005362 s | 0.005893 s | 0.005118 s (1.1x) |
| queens, all 92 solutions | 0.005242 s (2.4x, 2.8x) | 0.002198 s | 0.001840 s | 0.032128 s | 0.004827 s | 0.004735 s | 0.001972 s (0.9x) |
| loop, 100 000 additions | 0.012041 s (2.8x, 2.7x) | 0.004284 s | 0.004407 s | 0.090732 s | 0.012529 s | 0.011861 s | 0.026686 s (6.2x) |
| lookup, 1000 probes / 200 facts | 0.000341 s (4.6x, 2.3x) | 0.000074 s | 0.000151 s | 0.002096 s | 0.000361 s | 0.000331 s | 0.011921 s (161.1x) |
| sortnums, 5000 integers | 0.003162 s (1.8x, 1.9x) | 0.001764 s | 0.001682 s | 0.015741 s | 0.003225 s | 0.003205 s | 0.002433 s (1.4x) |

**As a language, 1.1-4.6x CPython and 1.9-2.8x SWI-Prolog at its best** --
and 5 to 7.5 times faster than `swipl` as installed, without `-O`, on four
tasks of five; 1.7 times slower on naive reverse, the one task with no
arithmetic in it, where the flag changes nothing. The three cocolog
arrangements are within 11 % of one another on every task but nrev, where
the socket is 20 % behind `--local`. CPython's lookup lane read a fixed cost
of 0.99 s and a `2R/R` of 1.55, so its per rep -- and the 4.6x beside
cocolog's -- is the least certain figure here (Run N's section).

**And cocolog is a state machine, not only a language: against python +
sqlite3, which keeps the same promises, cocolog's store is 33 times faster
at the thousand keyed probes (36x over the socket) and 2.1 times faster on
the counting loop (2.2x), where every addend is a row** -- level on nrev,
and 1.3 times slower on sortnums and 2.4 times on queens, computation over
data read once, where the sqlite lane runs at Python's own speed (sqlite
costs CPython 0.9-1.4x over its dict there, 6.2x on the loop's cursor):

| task (one rep) | cocolog --embed | cocolog zigurat | cpython + sqlite3 | cocolog against it |
|---|---:|---:|---:|---|
| lookup, 1000 probes / 200 facts | 0.000361 s | 0.000331 s | 0.011921 s | **33x faster** (36x) |
| loop, 100 000 additions | 0.012529 s | 0.011861 s | 0.026686 s | **2.1x faster** (2.2x) |
| nrev, 400-element list | 0.005362 s | 0.005893 s | 0.005118 s | level (1.05x; 1.15x slower) |
| sortnums, 5000 integers | 0.003225 s | 0.003205 s | 0.002433 s | 1.3x slower |
| queens, all 92 solutions | 0.004827 s | 0.004735 s | 0.001972 s | 2.4x slower |

**Run M**, the other run on 1.8.48, is on a Linux box (a four-vCPU Xeon
microVM, SWI-Prolog 9.0.4) and is read by its ratios: cocolog --local 1.1-4.6
times CPython and 1.9-3.9 times SWI-Prolog with `-O`, the embedded store 11
times faster than python + sqlite3 at the keyed probes and 2.0 times on the
counting loop.

**Run O**, on 1.8.54 and the store engine of ZiguratIP 0.1.21, is on a
Linux box again -- slower than Run M's, every lane 1.3 to 2.2 times its
Run M per rep -- and is read by its ratios too: cocolog --local 1.0-4.0
times CPython and 1.6-3.6 times SWI-Prolog with `-O`; against python +
sqlite3 the embedded store 16 times faster at the keyed probes (14x over
the socket), 2.1 times on the counting loop (2.2x) and 1.3 times on nrev,
and 1.6 times slower on sortnums (1.5x) and 2.7 times on queens (3.3x).
The lookup's wider gap is mostly sqlite's lane slowing on that box. Its
`--embed` start-up is 0.08 s, where Run M's read 0.01: the engine built
a 32 MB record cache at every open, which ZiguratIP 0.1.22 grows instead
-- 16-22 ms again (Run O's section).

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
partner is `sqlite`, not a dict. **SWI-Prolog is the Prolog**: `swi-O`
against `local` says how far cocolog's engine is from a mature one, read
against SWI with `-O` because a rival's slower flag flatters whoever
chose it; `swi`, as installed, stays beside it.

**What no rule can catch is which tasks were chosen.** Five small programs
are not a language, and these five include the ones cocolog is expected
to lose.

## The runs, oldest first

### Run M: the first Linux box, and the dead count -- 1.8.48

**The first run on a Linux box**, and the first on 1.8.48. A
four-vCPU Intel Xeon microVM at 2.10 GHz (Linux 6.18, 16 GB), Python 3.11.15
and SWI-Prolog 9.0.4 -- the Mac of Run N has 10.0.2 -- started at a load
average of 0.6 and took 651 s. It is not that Mac, and both rivals differ
with it, so read the ratios and not the seconds. Per rep:

| task (one rep) | cocolog --local | cpython | swipl -O | swipl | cocolog --embed | cocolog zigurat | cpython + sqlite3 |
|---|---|---|---|---|---|---|---|
| nrev, 400-element list | 0.004680 s (1.1x, 2.7x) | 0.004292 s | 0.001744 s | 0.001999 s | 0.005025 s | 0.004759 s | 0.005416 s (1.3x) |
| queens, all 92 solutions | 0.004439 s (2.5x, 2.2x) | 0.001776 s | 0.002016 s | 0.005008 s | 0.004440 s | 0.004193 s | 0.001688 s (1.0x) |
| loop, 100 000 additions | 0.011738 s (4.1x, 3.9x) | 0.002868 s | 0.002987 s | 0.012729 s | 0.011545 s | 0.012777 s | 0.022770 s (7.9x) |
| lookup, 1000 probes / 200 facts | 0.000330 s (4.6x, 2.5x) | 0.000072 s | 0.000131 s | 0.000470 s | 0.000338 s | 0.000318 s | 0.003827 s (53.2x) |
| sortnums, 5000 integers | 0.003226 s (2.4x, 1.9x) | 0.001317 s | 0.001691 s | 0.004226 s | 0.003099 s | 0.003615 s | 0.002188 s (1.7x) |

**As a language, cocolog is 1.1-4.6 times CPython and 1.9-3.9 times
SWI-Prolog at its best**, and faster than `swipl` as installed on four
tasks of five (queens 1.1x, loop 1.1x, sortnums 1.3x, lookup 1.4x) and 2.3
times slower on naive reverse, the one task with no arithmetic in it --
the Mac's shape (Run N) on another machine. **As a state machine** the embedded
store is 11.3 times faster than python + sqlite3 at the thousand keyed
probes (12.0x over the socket) and 2.0 times faster on the counting loop
(1.8x), level on nrev, and 1.4 times slower on sortnums (1.7x) and 2.6
times on queens (2.5x). The three cocolog arrangements are within 11 % of
one another on every task but sortnums, where the socket is 17 % behind the
embedded store. The lookup-shape table below is too coarse for a box this
fast -- two decimals of a second, 0.02 s at 200 and at 2 000 facts and
0.04 s against Python's 0.02 s at 20 000 -- and the per-rep column above is
the lookup's reading.

**What 1.8.48 is.** The dead count of 1.8.43 to 1.8.47 was short by one
cell for each distinct variable of a clause that died (the commit has the
story): `retract`, a reconsult and an initialization goal
that had run measured the dead by the heap copy's length, and since the
copy puts a variable in its slot the copy is that much shorter than the
clause's cells in the store. Nothing answered wrongly; the store compacted
later than it said. **The measurement that shows it** is not one of the
five tasks, none of which retracts or reconsults. A base of 1 500 clauses
of 3 000 distinct variables each (6 003 cells in the store, 3 003 in the
copy) with a thousand retracted and nothing asserted meanwhile, so that the
growth trigger cannot answer for the dead (`test/gc.pl` has it as a check):

| build | compactions in the drain | `store_used` before | `store_used` after |
|---|---:|---:|---:|
| 1.8.47 | 0 | 72 203 752 | 72 203 752 |
| 1.8.48 | 1 | 72 203 752 | 36 089 704 |

**And what it costs**, which is nothing that a pair can see: 1.8.47 against
1.8.48, whole processes, one sitting, the order flipping from pair to pair,
the reps those of a run over 1.2 s on 1.8.47. The five tasks, and `churn`,
a retract-and-assert loop on a clause of eight variables (the one place
this change can cost anything, once per retract: a read of the map's count,
a dereference and a tag test), 2 048 000 rounds a run:

| task | pairs | 1.8.47 | 1.8.48 | new / old | the pairs, new / old |
|---|---:|---:|---:|---:|---|
| nrev | 5 | 1.277 s | 1.277 s | 1.000 | 0.855 to 1.159 |
| queens | 5 | 2.282 s | 2.277 s | 0.998 | 0.918 to 1.076 |
| loop | 5 | 1.661 s | 1.658 s | 0.998 | 0.952 to 1.085 |
| lookup | 11 | 1.430 s | 1.416 s | 0.990 | 0.917 to 1.167 |
| sortnums | 11 | 1.721 s | 1.722 s | 1.001 | 0.903 to 1.115 |
| churn | 11 | 1.299 s | 1.294 s | 0.996 | 0.824 to 1.084 |
| sortnums, 1.8.47 against a copy of itself | 11 | 1.684 s | 1.684 s | 1.000 | 0.893 to 1.051 |

**Five pairs were not enough on this box.** The first round read sortnums
8.6 % slower in all five pairs (1.021, 1.050, 1.010, 1.150, 1.055), where
no code the change touches runs; eleven pairs read 0.1 % and the same binary
against a copy of itself read 0.0 %, with a single pair as far from 1 as 0.89
and 1.12. A pair on this microVM is good to about 10 %, its median over
eleven to a per cent, and a claim of a few per cent wants the eleven. Every
answer in every pair was the same.

The two programs behind the `churn` row and the drain table:

```prolog
:- dynamic c/9.
c(0, a, _, _, _, f(_, _), b, _, _).
tick(0) :- !.
tick(K) :-
    retract(c(N, A, B, C, D, E, F, G, H)),
    N1 is N + 1,
    assertz(c(N1, A, B, C, D, E, F, G, H)),
    K1 is K - 1,
    tick(K1).
reps(0, _) :- !.
reps(R, N) :- tick(N), R1 is R - 1, reps(R1, N).
main(N, Reps) :-          % main(1000, 2048) answers 2048000
    reps(Reps, N),
    c(S, _, _, _, _, _, _, _, _),
    format("answer(~w)~n", [S]).

:- dynamic w/1.
fill(0) :- !.
fill(K) :- functor(T, f, 3000), assertz(w(T)), K1 is K - 1, fill(K1).
drain(0) :- !.
drain(K) :- retract(w(_)), K1 is K - 1, drain(K1).
%% fill(1500), statistics(compactions, C0), statistics(store_used, U0),
%% drain(1000), statistics(compactions, C1), statistics(store_used, U1)
```

The run, as `sh bench/langs.sh` printed it:

```


cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.15 at /usr/local/bin/python3, cocolog 1.8.48 at /home/user/cocolog/cocolog
SWI-Prolog version 9.0.4 for x86_64-linux at /usr/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.18     0.004292      1.0x        -    1.86  cpython_process
   swi-O        1024    0.54     0.001744      0.4x     1.0x    1.77  swi_prolog_process_optimised
   swi          1024    0.18     0.001999      0.5x     1.1x    1.92  swi_prolog_process_as_installed
   local         256    0.23     0.004680      1.1x     2.7x    1.84  cocolog_local_in_memory_no_database
   embed         256    0.01     0.005025      1.2x     2.9x    2.00  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.06     0.004759      1.1x     2.7x    1.95  cocolog_server_one_kb_emptied
   sqlite        256    0.00     0.005416      1.3x        -    2.09  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.00     0.001776      1.0x        -    2.06  cpython_process
   swi-O        1024    0.00     0.002016      1.1x     1.0x    2.08  swi_prolog_process_optimised
   swi           256    0.15     0.005008      2.8x     2.5x    1.90  swi_prolog_process_as_installed
   local         512    0.01     0.004439      2.5x     2.2x    2.00  cocolog_local_in_memory_no_database
   embed         256    0.00     0.004440      2.5x     2.2x    2.03  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.12     0.004193      2.4x     2.1x    1.90  cocolog_server_one_kb_emptied
   sqlite       1024    0.09     0.001688      1.0x        -    1.95  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.16     0.002868      1.0x        -    1.90  cpython_process
   swi-O         512    0.16     0.002987      1.0x     1.0x    1.91  swi_prolog_process_optimised
   swi           128    0.28     0.012729      4.4x     4.3x    1.86  swi_prolog_process_as_installed
   local         128    0.00     0.011738      4.1x     3.9x    2.00  cocolog_local_in_memory_no_database
   embed         128    0.09     0.011545      4.0x     3.9x    1.94  cocolog_embedded_mvccs_fresh_store
   zigurat       128    0.00     0.012777      4.5x     4.3x    2.04  cocolog_server_one_kb_emptied
   sqlite         64    0.08     0.022770      7.9x        -    1.95  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python      32768    0.27     0.000072      1.0x        -    1.90  cpython_process
   swi-O       16384    0.13     0.000131      1.8x     1.0x    1.94  swi_prolog_process_optimised
   swi          4096    0.00     0.000470      6.5x     3.6x    2.04  swi_prolog_process_as_installed
   local        4096    0.03     0.000330      4.6x     2.5x    1.98  cocolog_local_in_memory_no_database
   embed        4096    0.03     0.000338      4.7x     2.6x    1.98  cocolog_embedded_mvccs_fresh_store
   zigurat      4096    0.24     0.000318      4.4x     2.4x    1.84  cocolog_server_one_kb_emptied
   sqlite        512    0.06     0.003827     53.2x        -    1.97  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.02     0.001317      1.0x        -    1.99  cpython_process
   swi-O        1024    0.00     0.001691      1.3x     1.0x    2.05  swi_prolog_process_optimised
   swi           256    0.15     0.004226      3.2x     2.5x    1.88  swi_prolog_process_as_installed
   local         512    0.09     0.003226      2.4x     1.9x    1.95  cocolog_local_in_memory_no_database
   embed         512    0.20     0.003099      2.4x     1.8x    1.89  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.00     0.003615      2.7x     2.1x    2.10  cocolog_server_one_kb_emptied
   sqlite       1024    0.06     0.002188      1.7x        -    1.97  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.02 s
   swi-O          0.03 s
   swi            0.04 s
   local          0.01 s
   embed          0.01 s
   zigurat        0.01 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.02         0.02         0.02         1x
       2000         0.02         0.02         0.02         1x
      20000         0.02         0.03         0.04         2x
```

### Run N: the Mac on 1.8.48

cocolog 1.8.48 -- the review's fixes of 1.8.45, the deterministic call, the
goal built in one piece and `is/2` by id of 1.8.46, and the dead count of
1.8.48 -- on an Intel i9-9880H Mac (16 GB, macOS 26.6.2), Python 3.11.13 and
SWI-Prolog 10.0.2 (Homebrew), started at a load average of 1.4, 12 min 38 s.
Docker Desktop was quit and the Zigurat server up. Every answer passed the
gate; the reading is the table in "Where it stands". Two things to read with
care:

* **CPython's lookup lane** calibrated to 16 384 reps and read a fixed cost
  of 0.99 s and a `2R/R` of 1.55, where every other lane reads 0.0-0.3 s and
  1.8-2.0. One of its three runs at R was slow, so (t(2R) - t(R)) / R comes
  out low -- 0.000074 s a rep -- and the 4.6x beside cocolog's lookup likely
  overstates the gap.
* **The lookup-shape table** is coarse here, as on the Linux box of Run M:
  two decimals of a second for runs of 0.16-0.21 s. It is flat, which is its
  whole claim.

```

cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.13 at /Users/a1/.pyenv/versions/3.11.13/bin/python3, cocolog 1.8.48 at /Users/a1/Projects/GitHub/cocolog/cocolog
SWI-Prolog version 10.0.2 for x86_64-darwin at /usr/local/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.16     0.004614      1.0x        -    1.88  cpython_process
   swi-O         512    0.16     0.002589      0.6x     1.0x    1.89  swi_prolog_process_optimised
   swi           512    0.20     0.002931      0.6x     1.1x    1.88  swi_prolog_process_as_installed
   local         256    0.20     0.004908      1.1x     1.9x    1.86  cocolog_local_in_memory_no_database
   embed         256    0.10     0.005362      1.2x     2.1x    1.93  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.00     0.005893      1.3x     2.3x    2.00  cocolog_server_one_kb_emptied
   sqlite        256    0.21     0.005118      1.1x        -    1.86  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.10     0.002198      1.0x        -    1.92  cpython_process
   swi-O         512    0.20     0.001840      0.8x     1.0x    1.83  swi_prolog_process_optimised
   swi            32    0.18     0.032128     14.6x    17.5x    1.85  swi_prolog_process_as_installed
   local         256    0.12     0.005242      2.4x     2.8x    1.92  cocolog_local_in_memory_no_database
   embed         256    0.28     0.004827      2.2x     2.6x    1.81  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.23     0.004735      2.2x     2.6x    1.84  cocolog_server_one_kb_emptied
   sqlite        512    0.19     0.001972      0.9x        -    1.84  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.15     0.004284      1.0x        -    1.88  cpython_process
   swi-O         256    0.18     0.004407      1.0x     1.0x    1.86  swi_prolog_process_optimised
   swi            16    0.16     0.090732     21.2x    20.6x    1.90  swi_prolog_process_as_installed
   local         128    0.16     0.012041      2.8x     2.7x    1.90  cocolog_local_in_memory_no_database
   embed         128    0.11     0.012529      2.9x     2.8x    1.94  cocolog_embedded_mvccs_fresh_store
   zigurat       128    0.24     0.011861      2.8x     2.7x    1.86  cocolog_server_one_kb_emptied
   sqlite         64    0.28     0.026686      6.2x        -    1.86  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python      16384    0.99     0.000074      1.0x        -    1.55  cpython_process
   swi-O        8192    0.33     0.000151      2.0x     1.0x    1.79  swi_prolog_process_optimised
   swi          1024    0.06     0.002096     28.3x    13.9x    1.97  swi_prolog_process_as_installed
   local        4096    0.16     0.000341      4.6x     2.3x    1.90  cocolog_local_in_memory_no_database
   embed        4096    0.23     0.000361      4.9x     2.4x    1.86  cocolog_embedded_mvccs_fresh_store
   zigurat      4096    0.29     0.000331      4.5x     2.2x    1.82  cocolog_server_one_kb_emptied
   sqlite        128    0.15     0.011921    161.1x        -    1.91  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.16     0.001764      1.0x        -    1.92  cpython_process
   swi-O        1024    0.20     0.001682      1.0x     1.0x    1.90  swi_prolog_process_optimised
   swi           128    0.17     0.015741      8.9x     9.4x    1.92  swi_prolog_process_as_installed
   local         512    0.16     0.003162      1.8x     1.9x    1.91  cocolog_local_in_memory_no_database
   embed         512    0.15     0.003225      1.8x     1.9x    1.92  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.18     0.003205      1.8x     1.9x    1.90  cocolog_server_one_kb_emptied
   sqlite        512    0.23     0.002433      1.4x        -    1.84  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.11 s
   swi-O          0.18 s
   swi            0.13 s
   local          0.13 s
   embed          0.11 s
   zigurat        0.16 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.18         0.18         0.17         1x
       2000         0.17         0.19         0.16         1x
      20000         0.16         0.21         0.18         1x

```

### Run O: 1.8.54, and the store under it ZiguratIP 0.1.21's

cocolog 1.8.54 (`eccfef8`) -- the engine of 1.8.48 with `mod` and `div`
comparing signs (1.8.50), `library(json)`'s two fixes and the translator's
samples -- built by clang with ZiguratIP's MVCCS engine at `e5ad96e` linked
in. Since Run M that engine maps a transaction's index entries in bulk at
its commit, keeps a plain index as sorted runs whose merges are paced, keeps
its free list by key and size, appends a key above every key where the last
one went, and counts the upper half of a merge's re-split right (the
`unmap_key` fix); the zigurat lane is ZiguratIP 0.1.21 started fresh for the
run, on 64 KiB pages (`COCOLOG_PAGE_SIZE=65536`). A four-vCPU Intel Xeon
microVM at 2.80 GHz (Linux 6.18, 16 GB) -- not Run M's 2.10 GHz host --
with Python 3.11.15 and SWI-Prolog 9.0.4, both as in Run M; 2026-10-04,
10 min 46 s, a load of 1.0 mid-run with the harness its only busy
process. Both store lanes ran the `e5ad96e` engine.
Every answer passed the gate.

**The box is slower than Run M's, for every lane**: each per rep is 1.3 to
2.2 times its Run M figure (CPython 1.3-2.1, `swipl -O` 1.3-1.9, cocolog
--local 1.4-1.9, the sqlite lane 1.4-2.2), so read the ratios. **As a
language**, cocolog --local is 1.0-4.0 times CPython and 1.6-3.6 times
SWI-Prolog with `-O` (Run M: 1.1-4.6 and 1.9-3.9), faster than `swipl` as
installed on four tasks of five (queens 1.02x, loop 1.05x, lookup 1.29x,
sortnums 1.48x) and 2.3 times slower on naive reverse -- Run M's shape.
**As a state machine**, against python + sqlite3:

| task (one rep) | cocolog --embed | cocolog zigurat | cpython + sqlite3 | cocolog against it | Run M |
|---|---:|---:|---:|---|---|
| lookup, 1000 probes / 200 facts | 0.000537 s | 0.000605 s | 0.008583 s | **16.0x faster** (14.2x) | 11.3x (12.0x) |
| loop, 100 000 additions | 0.019209 s | 0.017880 s | 0.039776 s | **2.07x faster** (2.22x) | 1.97x (1.78x) |
| nrev, 400-element list | 0.007054 s | 0.007047 s | 0.009038 s | 1.28x faster (1.28x) | 1.08x (1.14x) |
| sortnums, 5000 integers | 0.005517 s | 0.004991 s | 0.003353 s | 1.65x slower (1.49x) | 1.42x slower (1.65x) |
| queens, all 92 solutions | 0.006542 s | 0.007990 s | 0.002404 s | 2.72x slower (3.32x) | 2.63x slower (2.48x) |

Four things to read with care:

* **The lookup's wider gap is mostly sqlite's.** Its lane slowed 2.24 times
  against Run M, the most of any lane; the embedded store's 1.59. One run on
  another host says nothing about cocolog having moved.
* **None of the five tasks measures the store engine's changes.** A
  cocolog lane consults its program into the store and then runs it in
  memory (it is the sqlite lane whose loop sums a committed table), so the
  store lanes stay level with --local, as in every run; the insert path the
  engine's work was about is coco's `test/txs.pl`.
* **The three cocolog arrangements are within 24 % of one another**, where
  Run M's were within 11 % but for one task: --local's nrev 24 % behind the
  embedded store doing the same work in memory (calibrated to 128 reps, a
  `2R/R` of 2.13), the socket's queens 22 % behind the embedded store, the
  embedded sortnums 23 % behind --local, the socket's lookup 20 % behind
  --local. A pair on this kind of box is good to about 10 % (Run M), and
  this was a single run, not a pair: those spreads say the sitting was noisy
  and nothing about the arrangements.
* **The `--embed` start-up, 0.08 s where Run M read 0.01, is real, and it
  is the store engine's.** Measured after the run, seven alternating pairs
  of whole processes, a fresh store each: the 1.8.48 build of 2026-10-03,
  its engine from before ZiguratIP `8f3e3a5`, starts in 15-19 ms, 1.8.54 in
  69-93 ms, and --local in 11-18 ms in both. `8f3e3a5` sized the B-tree
  record cache for big trees -- 65 536 node slots and 262 144 key slots,
  ~32 MB -- and builds it at every open: a fresh store's process reaches
  36 MB of resident memory against 9 and takes 8 131 minor faults against
  1 393, and with `MVCCS_CACHE_NODES=1024 MVCCS_CACHE_KEYS=1024` or
  `MVCCS_NO_CACHE=1` it starts in 14-17 ms again. Every `--embed` process
  pays it once (a reopened store too: 39-63 ms), outside the per-rep
  column; a server pays it once at start. The cure is ZiguratIP's -- a
  cache that starts small and grows with the tree -- and is not in this
  build. It came the same evening as ZiguratIP 0.1.22 (`6a8f2f5`: each
  array starts at a sixteenth of its cap and grows four-fold as it
  misses): 1.8.54 rebuilt on it starts a fresh store in 16-22 ms against
  this build's 72-87 (seven alternating pairs), a reopened one in 15-21
  against 40-51, at 9 MB resident; a two-million-row table with a hashed
  tree index writes as fast either way (ABBA, pairs 0.988 and 1.020).

The lookup-shape table is coarse again (two decimals of a second) and flat,
which is its claim. The run, as `sh bench/langs.sh` printed it:

```

cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.15 at /usr/local/bin/python3, cocolog 1.8.54 at /home/user/build/cocolog/cocolog
SWI-Prolog version 9.0.4 for x86_64-linux at /usr/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.00     0.008995      1.0x        -    2.09  cpython_process
   swi-O         512    0.14     0.002983      0.3x     1.0x    1.92  swi_prolog_process_optimised
   swi           512    0.00     0.003794      0.4x     1.3x    2.07  swi_prolog_process_as_installed
   local         128    0.00     0.008713      1.0x     2.9x    2.13  cocolog_local_in_memory_no_database
   embed         256    0.06     0.007054      0.8x     2.4x    1.97  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.15     0.007047      0.8x     2.4x    1.92  cocolog_server_one_kb_emptied
   sqlite        256    0.00     0.009038      1.0x        -    2.05  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.00     0.002350      1.0x        -    2.03  cpython_process
   swi-O         512    0.34     0.002642      1.1x     1.0x    1.80  swi_prolog_process_optimised
   swi           256    0.12     0.007314      3.1x     2.8x    1.94  swi_prolog_process_as_installed
   local         256    0.00     0.007156      3.0x     2.7x    2.05  cocolog_local_in_memory_no_database
   embed         256    0.15     0.006542      2.8x     2.5x    1.92  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.00     0.007990      3.4x     3.0x    2.15  cocolog_server_one_kb_emptied
   sqlite        512    0.04     0.002404      1.0x        -    1.97  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.15     0.005225      1.0x        -    1.90  cpython_process
   swi-O         256    0.12     0.005513      1.1x     1.0x    1.92  swi_prolog_process_optimised
   swi            64    0.00     0.021024      4.0x     3.8x    2.08  swi_prolog_process_as_installed
   local         128    0.00     0.019972      3.8x     3.6x    2.09  cocolog_local_in_memory_no_database
   embed          64    0.00     0.019209      3.7x     3.5x    2.00  cocolog_embedded_mvccs_fresh_store
   zigurat        64    0.16     0.017880      3.4x     3.2x    1.88  cocolog_server_one_kb_emptied
   sqlite         32    0.03     0.039776      7.6x        -    1.98  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python      16384    0.00     0.000127      1.0x        -    2.04  cpython_process
   swi-O        8192    0.03     0.000225      1.8x     1.0x    1.98  swi_prolog_process_optimised
   swi          2048    0.16     0.000653      5.1x     2.9x    1.90  swi_prolog_process_as_installed
   local        4096    0.26     0.000506      4.0x     2.2x    1.89  cocolog_local_in_memory_no_database
   embed        2048    0.00     0.000537      4.2x     2.4x    2.00  cocolog_embedded_mvccs_fresh_store
   zigurat      2048    0.00     0.000605      4.8x     2.7x    2.06  cocolog_server_one_kb_emptied
   sqlite        128    0.00     0.008583     67.6x        -    2.08  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.22     0.001998      1.0x        -    1.90  cpython_process
   swi-O         512    0.00     0.002850      1.4x     1.0x    2.02  swi_prolog_process_optimised
   swi           256    0.08     0.006631      3.3x     2.3x    1.95  swi_prolog_process_as_installed
   local         256    0.29     0.004484      2.2x     1.6x    1.80  cocolog_local_in_memory_no_database
   embed         256    0.00     0.005517      2.8x     1.9x    2.10  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.03     0.004991      2.5x     1.8x    1.98  cocolog_server_one_kb_emptied
   sqlite        512    0.07     0.003353      1.7x        -    1.96  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.02 s
   swi-O          0.02 s
   swi            0.02 s
   local          0.01 s
   embed          0.08 s
   zigurat        0.02 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.02         0.02         0.04         2x
       2000         0.03         0.03         0.04         1x
      20000         0.04         0.04         0.05         1x

```
