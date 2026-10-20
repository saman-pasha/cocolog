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

**Run P**, on 1.8.57 and ZiguratIP 0.1.22, is on the same kind of box as
Run O: cocolog --local 0.8-4.4 times CPython -- naive reverse is FASTER
than CPython now, 0.8x -- and 1.2-2.3 times SWI-Prolog with `-O`, and
faster than `swipl` as installed on four tasks of five (1.15-1.49x).
Against python + sqlite3 the embedded store is 15 times faster at the keyed
probes (17x over the socket) and 1.7 times on the counting loop (1.3x),
and 1.3 times slower on sortnums (1.1x) and 2.8 times on queens (2.2x).
`--embed` starts in 0.02 s, the record cache that grows. Read its ratios
and not too closely: SWI's and CPython's lanes ran 1.0-1.47 times their Run
O per rep while cocolog's ran 0.78-1.12 times, more than the engine change
between them explains (Run P's section).

**Run Q**, on 1.9.1 -- an index on any argument, a body's first call in
registers, its leading arithmetic run as guards on entry, and every jump
padded off a 32-byte boundary -- on the same kind of box: cocolog --local
0.5-3.6 times CPython and 0.9-2.0 times SWI-Prolog with `-O`. Naive reverse
takes half CPython's time, and **sortnums is faster than SWI-Prolog with
`-O`**, 0.9x, the first task in these runs that is. Against python +
sqlite3 the embedded store is 20 times faster at the keyed probes (21x over
the socket), 6.0 times on the counting loop (5.5x), 1.8 times on nrev
(1.7x) and 1.5 times on sortnums (1.5x) -- faster on four tasks of five --
and 1.7 times slower on queens (1.7x). The engine change itself is measured
by the within-run pairs in STATUS.md, not by this run against Run P (Run
Q's section).

**Run R**, on 1.9.3 -- 1.9.2's names by id, and 1.9.3's environments: a
body's later goals and its constructs reached from one record instead of a
frame per goal -- on the same kind of box: cocolog --local 0.5-2.6 times
CPython and 0.8-1.6 times SWI-Prolog with `-O`. **The counting loop is level
with SWI-Prolog with `-O`** (0.98x) and sortnums ahead of it (0.76x), and
the lookup gap is 1.4x where Run Q's was 2.0x. Against python + sqlite3 the
embedded store is 26 times faster at the keyed probes (19x over the
socket), 6.3 times on the counting loop (7.1x), 2.0 times on nrev (1.6x)
and 1.7 times on sortnums (1.7x), and 1.8 times slower on queens (1.7x).
The engine change is again the within-run pairs in STATUS.md, not this run
against Run Q (Run R's section).

**Run S**, on 1.9.6 -- 1.9.4's collection inside a builtin's searches and
globals found by a hash, 1.9.5's core builtins done where they stand in an
environment, 1.9.6's fused guards and reclaimed tables -- on the same kind
of box: cocolog --local 0.6-2.3 times CPython and 0.7-1.6 times SWI-Prolog
with `-O`, the counting loop level with it again (1.04x) and sortnums ahead
(0.72x). Against python + sqlite3 the embedded store is 19 times faster at
the keyed probes (23x over the socket), 6.2 times on the counting loop
(5.5x), 1.5 times on nrev (1.7x) and 2.1 times on sortnums (1.8x), and 1.7
times slower on queens (1.9x). The rivals ran 0.68-1.03 times their Run R
per rep and cocolog --local 0.79-1.04, so the engine change is STATUS.md's
counts and pairs -- the lookup 24 % fewer instructions since 1.9.3 -- not
this run against Run R (Run S's section).

**Run T**, on 1.10.20 -- no engine stage since Run S; what came between,
the tracer's untraced clock, the journal, the backtrace and cyclic terms
written and walked, was held to the untraced engine's instruction count as
it landed -- on the same kind of box: cocolog --local 0.7-2.2 times CPython
and 1.0-1.9 times SWI-Prolog with `-O`, the loop 1.1x and sortnums level
(1.01x). Against python + sqlite3 the embedded store is 26 times faster at
the keyed probes (25x over the socket), 5.2 times on the counting loop
(5.9x), 1.4 times on nrev (2.2x) and 1.3 times on sortnums (1.3x), and 2.2
times slower on queens (2.1x). 1.10.20 executes what 1.9.6 did -- nrev,
queens and lookup within 0.07 % of its instructions less the jump padding,
and nrev 1.02 times its time in five alternating pairs -- so what moved
since Run S is the sitting: the rivals ran 0.72-1.18 times their Run S per
rep, and cocolog's three arrangements spread 60 % on nrev (Run T's
section).

**Run U**, on 2.2.5 -- 64-bit integers, text in characters and swipl's
floats and writer since Run T, each counted against the untraced engine as
it landed -- on another box: a 2.10 GHz Emerald Rapids Xeon, by its label
and its rivals' times Run M's kind of host, where Runs O to T ran on a
2.80 GHz Cascade Lake. cocolog --local is 0.9-2.9 times CPython and 1.0-2.0
times SWI-Prolog with `-O`, sortnums level (1.04x) and the loop 1.39x.
Against python + sqlite3 the embedded store is 19 times faster at the keyed
probes (19x over the socket), 5.0 times on the counting loop (5.0x), 1.16
times on nrev (1.16x) and 1.30 times on sortnums (1.37x), and 1.95 times
slower on queens (2.32x). The rivals gained more from the box than cocolog
did -- 0.54-1.17 times their Run T per rep, cocolog --local 0.72-1.02 --
and the engine runs 1.9.6's instructions (nrev 0.60 % more less the
padding, queens 2.1 % and lookup 1.1 % fewer) in 1.03 to 1.13 times its
time on nrev and the loop on this box. Against Run M, on such a host,
cocolog --local runs in 0.41-0.85 times 1.8.48's per rep and the rivals in
0.84-1.17 times theirs (Run U's section).

**Run V**, on 2.5.1 -- 2.3.0's logical update view, 2.4.0's Unix domain
sockets, 2.4.1's template library and cocolint's auto mode, and 2.5.0's
rationals on the four-bit cell tag since Run U, with 2.5.1's Darwin clock
and signed-zero fixes, which no lane here touches -- on **the same Mac as
Run N**: an Intel i9-9880H MacBookPro16,1, 16 GB, macOS 26.7.1 (Run N read
26.6.2), Python 3.11.13 and SWI-Prolog 10.0.2. cocolog --local is 0.9-2.0
times CPython and 1.1-2.0 times SWI-Prolog with `-O`, and faster than
`swipl` as installed on four tasks of five (queens 8.4x, loop 20.8x, lookup
9.9x, sortnums 9.1x), 1.26 times slower on naive reverse. Against python +
sqlite3 the embedded store is 61 times faster at the keyed probes (60x over
the socket), 6.2 times on the counting loop (5.7x), 1.25 times on nrev
(1.25x) and 1.42 times on sortnums (1.35x), and 1.86 times slower on queens
(1.69x). Against Run N, on this box, cocolog --local runs in 0.49-0.87 times
its per rep and the rivals in 0.93-1.50 times theirs, so the language gaps
narrowed and the store's leads moved; Run N's Python lookup lane, the one it
flagged as uncertain, read 0.000074 s a rep against this run's 0.000111 (Run
V's section).

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

**And a run is a reading of one sitting, not a regression test.** The host
is the cloud's to choose -- Run U's is not Run T's -- and one box drifts
about a fifth between runs of one build, so a ratio between two runs speaks
of two sittings. What a change to the engine is held to is its instruction
count, the same on any host: `sh tools/flow/zero.sh OLD NEW` counts nrev,
queens and lookup with the jump padding apart, and an engine change is
counted with it (CLAUDE.md, Measuring), with alternating pairs of the two
binaries in one sitting where time is the question. `test/langs.pl` holds
the benchmark's programs to the same answers, not to any time.

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

### Run P: 1.8.57, the engine's first two compiled-control stages

cocolog 1.8.57 (`6ce1f03`) -- Run O's engine with 1.8.55's two stages of
compiled control (a plain predicate's functor stamped so its goals skip
the dispatch questions, and the first goal of an entered clause carried in
the engine instead of a frame) and the load-time halt that commits
(1.8.57), built by clang in release mode, as Run O's was, with ZiguratIP's
MVCCS engine at `6a8f2f5` (0.1.22, the record cache that grows) linked in;
the zigurat lane is ZiguratIP 0.1.22 started fresh for the run, on 64 KiB
pages (`COCOLOG_PAGE_SIZE=65536`). The same kind of box as Run O, a
four-vCPU Intel Xeon microVM at 2.80 GHz (Linux 6.18, 16 GB), with Python
3.11.15 and SWI-Prolog 9.0.4; 2026-10-08, 11 min 14 s, a load of 0.06 at
the start and the harness the only busy process. Every answer passed the
gate.

**As a language**, cocolog --local is 0.8-4.4 times CPython and 1.2-2.3
times SWI-Prolog with `-O` (Run O: 1.0-4.0 and 1.6-3.6). **Naive reverse is
faster than CPython**, 0.8x, the first run where any task is. Against
`swipl` as installed cocolog is faster on four tasks of five (queens
1.39x, loop 1.37x, lookup 1.15x, sortnums 1.49x) and 2.0 times slower on
naive reverse, where `-O` changes nothing. **As a state machine**, against
python + sqlite3:

| task (one rep) | cocolog --embed | cocolog zigurat | cpython + sqlite3 | cocolog against it | Run O |
|---|---:|---:|---:|---|---|
| lookup, 1000 probes / 200 facts | 0.000634 s | 0.000536 s | 0.009203 s | **14.5x faster** (17.2x) | 16.0x (14.2x) |
| loop, 100 000 additions | 0.020532 s | 0.026158 s | 0.034049 s | **1.66x faster** (1.30x) | 2.07x (2.22x) |
| nrev, 400-element list | 0.005653 s | 0.007416 s | 0.015451 s | 2.73x faster (2.08x) | 1.28x (1.28x) |
| sortnums, 5000 integers | 0.004737 s | 0.003940 s | 0.003550 s | 1.33x slower (1.11x) | 1.65x slower (1.49x) |
| queens, all 92 solutions | 0.007478 s | 0.005902 s | 0.002719 s | 2.75x slower (2.17x) | 2.72x slower (3.32x) |

Four things to read with care:

* **The ratios moved more than the engine did.** Per rep against Run O,
  SWI-Prolog with `-O` ran 1.19-1.36 times slower in this sitting and
  CPython 0.99-1.47 times, while cocolog --local ran 0.78-1.12 times its Run
  O figure (nrev 0.82, queens 0.94, loop 0.78, lookup 1.12, sortnums 1.05).
  1.8.55's two stages, counted under `callgrind` on these same programs,
  take 14.0 % off nrev and 2.5-4.6 % off the other four (STATUS.md), so
  nrev's move is partly the engine and the rest of the shift is the
  sitting: the rivals slowed and cocolog did not. A within-run pair of the
  two builds is what would settle it; this is one run.
* **nrev's 2.7x against sqlite is mostly sqlite's lane**, which ran 1.71
  times its Run O per rep with a `2R/R` of 2.37 -- the least linear reading
  in the table.
* **The three cocolog arrangements spread wider than Run O's**: the socket's
  loop 67 % behind --local (a `2R/R` of 2.40) and the embedded loop 31 %,
  the embedded nrev 21 % ahead of it, the socket's sortnums 16 % ahead (a
  `2R/R` of 1.61). Each lane computes in memory after one consult, so a
  spread like that is the sitting's noise, which the `2R/R` column shows,
  and not the arrangements.
* **`--embed` starts in 0.02 s**, where Run O's read 0.08: ZiguratIP 0.1.22
  grows the B-tree record cache from a sixteenth of its cap instead of
  building all 32 MB at every open, the cure Run O's section measured
  before it reached a build.

The lookup-shape table is flat again, a constant 2x at 200, 2 000 and 20 000
facts. The run, as `sh bench/langs.sh` printed it:

```

cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.15 at /usr/local/bin/python3, cocolog 1.8.57 at /home/user/cocolog/cocolog
SWI-Prolog version 9.0.4 for x86_64-linux at /usr/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        128    0.02     0.008931      1.0x        -    1.98  cpython_process
   swi-O         512    0.00     0.003559      0.4x     1.0x    2.07  swi_prolog_process_optimised
   swi           512    0.00     0.003584      0.4x     1.0x    2.00  swi_prolog_process_as_installed
   local         256    0.00     0.007161      0.8x     2.0x    2.19  cocolog_local_in_memory_no_database
   embed         128    0.26     0.005653      0.6x     1.6x    1.74  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.00     0.007416      0.8x     2.1x    2.16  cocolog_server_one_kb_emptied
   sqlite        128    0.00     0.015451      1.7x        -    2.37  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.00     0.003461      1.0x        -    2.22  cpython_process
   swi-O         512    0.00     0.003356      1.0x     1.0x    2.08  swi_prolog_process_optimised
   swi           128    0.06     0.009281      2.7x     2.8x    1.96  swi_prolog_process_as_installed
   local         256    0.28     0.006697      1.9x     2.0x    1.86  cocolog_local_in_memory_no_database
   embed         256    0.00     0.007478      2.2x     2.2x    2.05  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.64     0.005902      1.7x     1.8x    1.70  cocolog_server_one_kb_emptied
   sqlite        512    0.04     0.002719      0.8x        -    1.97  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.00     0.006482      1.0x        -    2.11  cpython_process
   swi-O         256    0.00     0.006765      1.0x     1.0x    2.09  swi_prolog_process_optimised
   swi            64    0.00     0.021395      3.3x     3.2x    2.04  swi_prolog_process_as_installed
   local         128    0.56     0.015651      2.4x     2.3x    1.78  cocolog_local_in_memory_no_database
   embed          64    0.00     0.020532      3.2x     3.0x    2.07  cocolog_embedded_mvccs_fresh_store
   zigurat       128    0.00     0.026158      4.0x     3.9x    2.40  cocolog_server_one_kb_emptied
   sqlite         32    0.50     0.034049      5.3x        -    1.69  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python      16384    0.31     0.000128      1.0x        -    1.87  cpython_process
   swi-O        8192    0.00     0.000288      2.2x     1.0x    2.14  swi_prolog_process_optimised
   swi          2048    0.28     0.000648      5.1x     2.2x    1.83  swi_prolog_process_as_installed
   local        2048    0.00     0.000565      4.4x     2.0x    2.01  cocolog_local_in_memory_no_database
   embed        4096    0.00     0.000634      5.0x     2.2x    2.09  cocolog_embedded_mvccs_fresh_store
   zigurat      4096    0.14     0.000536      4.2x     1.9x    1.94  cocolog_server_one_kb_emptied
   sqlite        256    0.00     0.009203     71.9x        -    2.06  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.10     0.002227      1.0x        -    1.92  cpython_process
   swi-O         512    0.00     0.003865      1.7x     1.0x    2.20  swi_prolog_process_optimised
   swi           256    0.15     0.006994      3.1x     1.8x    1.92  swi_prolog_process_as_installed
   local         256    0.44     0.004701      2.1x     1.2x    1.73  cocolog_local_in_memory_no_database
   embed         256    0.10     0.004737      2.1x     1.2x    1.92  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.65     0.003940      1.8x     1.0x    1.61  cocolog_server_one_kb_emptied
   sqlite        256    0.12     0.003550      1.6x        -    1.89  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.03 s
   swi-O          0.02 s
   swi            0.02 s
   local          0.01 s
   embed          0.02 s
   zigurat        0.02 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.03         0.03         0.06         2x
       2000         0.03         0.03         0.05         2x
      20000         0.03         0.05         0.06         2x

```

### Run Q: 1.9.1, any argument indexed, calls in registers, guards, padded jumps

cocolog 1.9.1, the tree this section was committed with -- Run P's engine
(1.8.57's, unchanged through 1.9.0's `library(websocket)`) with an index on
any argument, the first call of a body written into registers, a body's
leading arithmetic and type tests run as guards when its clause is entered,
and every jump padded off a 32-byte boundary (`-mbranches-within-32B-boundaries`,
which `tools/cc` passes on x86-64 since: this box is a Cascade Lake, and
the JCC erratum's microcode keeps a jump on such a boundary out of the
uop cache) -- built by clang in release mode, with ZiguratIP's MVCCS engine
at `6a8f2f5` (0.1.22) linked in; the zigurat lane is ZiguratIP 0.1.22
started fresh for the run, on 64 KiB pages (`COCOLOG_PAGE_SIZE=65536`), its
Parsi objects rebuilt by clang that day (they had been gcc's). The same
kind of box as Runs O and P, a four-vCPU Intel Xeon microVM at 2.80 GHz
(Linux 6.18, 16 GB), with Python 3.11.15 and SWI-Prolog 9.0.4; 2026-10-08,
11 min 07 s, a load of 0.65 at the start and the harness the only busy
process. Every answer passed the gate.

**As a language**, cocolog --local is 0.5-3.6 times CPython and 0.9-2.0
times SWI-Prolog with `-O` (Run P: 0.8-4.4 and 1.2-2.3). Naive reverse
takes half CPython's time, and **sortnums is faster than SWI-Prolog with
`-O`**, 0.9x, the first task in these runs that is. Against `swipl` as
installed cocolog is faster on four tasks of five (queens 1.31x, loop
3.00x, lookup 1.51x, sortnums 3.08x) and 1.33 times slower on naive
reverse. **As a state machine**, against python + sqlite3 -- faster on four
tasks of five:

| task (one rep) | cocolog --embed | cocolog zigurat | cpython + sqlite3 | cocolog against it | Run P |
|---|---:|---:|---:|---|---|
| lookup, 1000 probes / 200 facts | 0.000395 s | 0.000383 s | 0.007887 s | **20.0x faster** (20.6x) | 14.5x (17.2x) |
| loop, 100 000 additions | 0.005872 s | 0.006379 s | 0.034982 s | **5.96x faster** (5.48x) | 1.66x (1.30x) |
| nrev, 400-element list | 0.004722 s | 0.004965 s | 0.008597 s | **1.82x faster** (1.73x) | 2.73x (2.08x) |
| sortnums, 5000 integers | 0.002099 s | 0.002144 s | 0.003109 s | **1.48x faster** (1.45x) | 1.33x slower (1.11x slower) |
| queens, all 92 solutions | 0.004628 s | 0.004652 s | 0.002707 s | 1.71x slower (1.72x) | 2.75x slower (2.17x) |

Four things to read with care:

* **The engine change is the within-run pairs, not this run against Run
  P.** This sitting's rivals ran 0.67-1.13 times their Run P per rep
  (CPython 0.68-1.13, SWI-Prolog with `-O` 0.67-0.93) and cocolog --local
  0.44-0.87 times (nrev 0.65, queens 0.87, loop 0.44, lookup 0.78, sortnums
  0.48). Nine alternating pairs of 1.9.0 against 1.9.1 in one sitting, and
  of the plain build against the padded one, are in STATUS.md's 1.9.1
  section; they are what say how much faster the engine got.
* **The loop against sqlite, 6.0x where Run P read 1.7x**, is the guards:
  `N > 0` and both `is` run as the clause is entered and the recursive call
  goes in registers (0.46 of 1.9.0's time in the pairs), while sqlite's lane
  read 1.03 times its Run P figure.
* **Queens is the one task sqlite still wins**, computation over data read
  once, where the sqlite lane runs at Python's own speed (1.1x its dict
  here); cocolog's queens moved least in the pairs too (0.72, and 0.99 more
  from the padding).
* **The three cocolog arrangements spread up to 21 %**, and the stores
  ahead of --local on four tasks (queens 21 %, loop 14 %, lookup 10-13 %,
  sortnums 6-8 %): each lane computes in memory after one consult, so the
  order is the sitting's noise -- --local's queens reads a `2R/R` of 2.26,
  the least linear figure in the table.

The lookup-shape table is flat again, a constant 2x at 200, 2 000 and 20 000
facts. The run, as `sh bench/langs.sh` printed it:

```

cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.15 at /usr/local/bin/python3, cocolog 1.9.1 at /home/user/cocolog/cocolog
SWI-Prolog version 9.0.4 for x86_64-linux at /usr/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.00     0.010086      1.0x        -    2.21  cpython_process
   swi-O         512    0.00     0.003307      0.3x     1.0x    2.04  swi_prolog_process_optimised
   swi           512    0.00     0.003498      0.3x     1.1x    2.02  swi_prolog_process_as_installed
   local         256    0.04     0.004640      0.5x     1.4x    1.97  cocolog_local_in_memory_no_database
   embed         256    0.03     0.004722      0.5x     1.4x    1.97  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.00     0.004965      0.5x     1.5x    2.04  cocolog_server_one_kb_emptied
   sqlite        128    0.07     0.008597      0.9x        -    1.94  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.00     0.002369      1.0x        -    2.06  cpython_process
   swi-O         512    0.10     0.002858      1.2x     1.0x    1.94  swi_prolog_process_optimised
   swi           256    0.18     0.007611      3.2x     2.7x    1.92  swi_prolog_process_as_installed
   local         256    0.00     0.005828      2.5x     2.0x    2.26  cocolog_local_in_memory_no_database
   embed         256    0.09     0.004628      2.0x     1.6x    1.93  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.35     0.004652      2.0x     1.6x    1.77  cocolog_server_one_kb_emptied
   sqlite        512    0.00     0.002707      1.1x        -    2.11  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.00     0.005646      1.0x        -    2.00  cpython_process
   swi-O         256    0.00     0.005886      1.0x     1.0x    2.06  swi_prolog_process_optimised
   swi            64    0.00     0.020494      3.6x     3.5x    2.08  swi_prolog_process_as_installed
   local         256    0.00     0.006831      1.2x     1.2x    2.07  cocolog_local_in_memory_no_database
   embed         256    0.20     0.005872      1.0x     1.0x    1.88  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.06     0.006379      1.1x     1.1x    1.97  cocolog_server_one_kb_emptied
   sqlite         32    0.19     0.034982      6.2x        -    1.86  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python      16384    0.03     0.000123      1.0x        -    1.99  cpython_process
   swi-O        8192    0.12     0.000219      1.8x     1.0x    1.94  swi_prolog_process_optimised
   swi          2048    0.10     0.000663      5.4x     3.0x    1.93  swi_prolog_process_as_installed
   local        4096    0.00     0.000440      3.6x     2.0x    2.04  cocolog_local_in_memory_no_database
   embed        4096    0.18     0.000395      3.2x     1.8x    1.90  cocolog_embedded_mvccs_fresh_store
   zigurat      4096    0.20     0.000383      3.1x     1.7x    1.89  cocolog_server_one_kb_emptied
   sqlite        256    0.00     0.007887     64.1x        -    2.01  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.26     0.002004      1.0x        -    1.89  cpython_process
   swi-O         512    0.17     0.002578      1.3x     1.0x    1.89  swi_prolog_process_optimised
   swi           256    0.00     0.007013      3.5x     2.7x    2.02  swi_prolog_process_as_installed
   local        1024    0.00     0.002277      1.1x     0.9x    2.06  cocolog_local_in_memory_no_database
   embed        1024    0.12     0.002099      1.0x     0.8x    1.95  cocolog_embedded_mvccs_fresh_store
   zigurat      1024    0.04     0.002144      1.1x     0.8x    1.98  cocolog_server_one_kb_emptied
   sqlite        512    0.22     0.003109      1.6x        -    1.88  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.02 s
   swi-O          0.01 s
   swi            0.02 s
   local          0.01 s
   embed          0.02 s
   zigurat        0.01 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.02         0.02         0.04         2x
       2000         0.02         0.03         0.05         2x
      20000         0.03         0.05         0.05         2x

```

### Run R: 1.9.3, a body's constructs reached from one record

cocolog 1.9.3, the tree this section was committed with -- Run Q's engine
with 1.9.2's names by id on five hot paths and 1.9.3's environments (a body
with an if-then-else, `\+`, `once/1`, `ignore/1` or a disjunction writes one
record when it is entered, and its later goals and the constructs' parts are
reached from it instead of from a frame each; STATUS.md) -- built by clang
in release mode with every jump padded, as Run Q's was, with ZiguratIP's
MVCCS engine at `6a8f2f5` (0.1.22) linked in; the zigurat lane is ZiguratIP
0.1.22 started fresh for the run, on 64 KiB pages (`COCOLOG_PAGE_SIZE=65536`).
The same kind of box as Runs O to Q, a four-vCPU Intel Xeon microVM at 2.80
GHz (Linux 6.18, 16 GB), with Python 3.11.15 and SWI-Prolog 9.0.4;
2026-10-09, 10 min 40 s, a load of 0.16 at the start and the harness the
only busy process. Every answer passed the gate.

**As a language**, cocolog --local is 0.5-2.6 times CPython and 0.8-1.6
times SWI-Prolog with `-O` (Run Q: 0.5-3.6 and 0.9-2.0). **The counting
loop is level with SWI-Prolog with `-O`**, 0.98x, and sortnums is ahead of
it, 0.76x (Run Q: 1.16x and 0.88x); the lookup is 1.4x (2.0x). Against
`swipl` as installed cocolog is faster on four tasks of five (queens 1.42x,
loop 3.66x, lookup 2.32x, sortnums 4.00x) and 1.62 times slower on naive
reverse. **As a state machine**, against python + sqlite3 -- faster on four
tasks of five:

| task (one rep) | cocolog --embed | cocolog zigurat | cpython + sqlite3 | cocolog against it | Run Q |
|---|---:|---:|---:|---|---|
| lookup, 1000 probes / 200 facts | 0.000355 s | 0.000481 s | 0.009088 s | **25.6x faster** (18.9x) | 20.0x (20.6x) |
| loop, 100 000 additions | 0.006140 s | 0.005408 s | 0.038409 s | **6.26x faster** (7.10x) | 5.96x (5.48x) |
| nrev, 400-element list | 0.005538 s | 0.007084 s | 0.011166 s | **2.02x faster** (1.58x) | 1.82x (1.73x) |
| sortnums, 5000 integers | 0.002165 s | 0.002119 s | 0.003588 s | **1.66x faster** (1.69x) | 1.48x (1.45x) |
| queens, all 92 solutions | 0.004899 s | 0.004644 s | 0.002689 s | 1.82x slower (1.73x) | 1.71x slower (1.72x) |

Four things to read with care:

* **The engine change is the within-run pairs, not this run against Run
  Q.** This sitting's rivals ran 0.89-1.08 times their Run Q per rep
  (CPython 0.89-1.03, SWI-Prolog with `-O` 0.97-1.08) and cocolog --local
  0.75-0.99 times (nrev 0.99, queens 0.85, loop 0.86, lookup 0.75, sortnums
  0.84) -- more than the engine change between them explains: the nine
  alternating pairs of 1.9.3 against 1.9.2 in STATUS.md read nrev 1.00,
  queens 0.95, loop 0.93, lookup 0.95 and sortnums 0.94, and 1.9.2 moved
  the bench tasks' instruction counts by 0 to 4.4 % (STATUS.md's 1.9.2
  section).
* **The lookup moved most, as its counts said it would**: its probe is a
  body that starts with a guard and goes on to an if-then-else, the case
  1.9.3's environments were built for (6.55 % fewer instructions). The
  lookup-shape table below reads 1x at 200 and 2 000 facts, where Run Q's
  read 2x at every size.
* **The sqlite lanes slowed** -- 1.30 times their Run Q per rep on nrev, 1.15
  on lookup and sortnums, 1.10 on the loop -- so the store's gains against
  them are partly theirs.
* **The three cocolog arrangements spread up to 55 %**: the socket's nrev
  behind --local by 55 % (a `2R/R` of 2.41, the least linear figure in the
  table) and its lookup by 45 % (2.21), the embedded nrev by 21 %, the stores
  ahead of --local on queens and the socket on the loop. Each lane computes
  in memory after one consult, so the order is the sitting's noise, which
  the `2R/R` column shows.

The run, as `sh bench/langs.sh` printed it:

```

cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.15 at /usr/local/bin/python3, cocolog 1.9.3 at /home/user/cocolog/cocolog
SWI-Prolog version 9.0.4 for x86_64-linux at /usr/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        128    0.23     0.009010      1.0x        -    1.84  cpython_process
   swi-O         512    0.00     0.003572      0.4x     1.0x    2.07  swi_prolog_process_optimised
   swi           512    0.39     0.002823      0.3x     0.8x    1.79  swi_prolog_process_as_installed
   local         512    0.35     0.004584      0.5x     1.3x    1.87  cocolog_local_in_memory_no_database
   embed         256    0.00     0.005538      0.6x     1.6x    2.06  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.00     0.007084      0.8x     2.0x    2.41  cocolog_server_one_kb_emptied
   sqlite        128    0.00     0.011166      1.2x        -    2.23  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.13     0.002357      1.0x        -    1.90  cpython_process
   swi-O         512    0.04     0.003045      1.3x     1.0x    1.98  swi_prolog_process_optimised
   swi           256    0.24     0.007053      3.0x     2.3x    1.88  swi_prolog_process_as_installed
   local         256    0.00     0.004979      2.1x     1.6x    2.04  cocolog_local_in_memory_no_database
   embed         256    0.12     0.004899      2.1x     1.6x    1.91  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.24     0.004644      2.0x     1.5x    1.91  cocolog_server_one_kb_emptied
   sqlite        512    0.00     0.002689      1.1x        -    2.13  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.08     0.005556      1.0x        -    1.95  cpython_process
   swi-O         256    0.02     0.006039      1.1x     1.0x    1.99  swi_prolog_process_optimised
   swi            64    0.00     0.021540      3.9x     3.6x    2.08  swi_prolog_process_as_installed
   local         256    0.21     0.005891      1.1x     1.0x    1.88  cocolog_local_in_memory_no_database
   embed         256    0.31     0.006140      1.1x     1.0x    1.84  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.45     0.005408      1.0x     0.9x    1.75  cocolog_server_one_kb_emptied
   sqlite         32    0.19     0.038409      6.9x        -    1.87  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       8192    0.00     0.000127      1.0x        -    2.02  cpython_process
   swi-O        8192    0.00     0.000233      1.8x     1.0x    2.00  swi_prolog_process_optimised
   swi          2048    0.00     0.000768      6.0x     3.3x    2.12  swi_prolog_process_as_installed
   local        4096    0.36     0.000331      2.6x     1.4x    1.79  cocolog_local_in_memory_no_database
   embed        4096    0.22     0.000355      2.8x     1.5x    1.87  cocolog_embedded_mvccs_fresh_store
   zigurat      4096    0.00     0.000481      3.8x     2.1x    2.21  cocolog_server_one_kb_emptied
   sqlite        256    0.00     0.009088     71.6x        -    2.14  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.43     0.001793      1.0x        -    1.68  cpython_process
   swi-O         512    0.26     0.002505      1.4x     1.0x    1.83  swi_prolog_process_optimised
   swi           256    0.00     0.007634      4.3x     3.0x    2.05  swi_prolog_process_as_installed
   local        1024    0.61     0.001907      1.1x     0.8x    1.76  cocolog_local_in_memory_no_database
   embed         512    0.04     0.002165      1.2x     0.9x    1.96  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.11     0.002119      1.2x     0.8x    1.91  cocolog_server_one_kb_emptied
   sqlite        512    0.00     0.003588      2.0x        -    2.03  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.02 s
   swi-O          0.03 s
   swi            0.02 s
   local          0.01 s
   embed          0.02 s
   zigurat        0.02 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.02         0.03         0.03         1x
       2000         0.03         0.02         0.03         1x
      20000         0.03         0.05         0.05         2x

```

### Run S: 1.9.6, a body's builtins done where they stand

cocolog 1.9.6, the tree this section was committed with -- Run R's engine
with 1.9.4's heap collection inside the searches a builtin starts and
globals found by a hash of their name, 1.9.5's core builtins done where
they stand in an environment (`is/2`, the comparisons and the type tests as
guards over its slots, `=/2`, `==/2` and `\==/2` read out of them, any other
called by its row), and 1.9.6's fused guards (an `is/2` or a comparison over
two slots or constants as one word) and its float and string tables
reclaimed in place (STATUS.md) -- built by clang in release mode with every
jump padded, as Runs Q and R were, with ZiguratIP's MVCCS engine at
`6a8f2f5` (0.1.22) linked in; the zigurat lane is ZiguratIP 0.1.22 started
fresh for the run, on 64 KiB pages (`COCOLOG_PAGE_SIZE=65536`). The same
kind of box as Runs O to R, a four-vCPU Intel Xeon microVM at 2.80 GHz
(Linux 6.18, 16 GB), with Python 3.11.15 and SWI-Prolog 9.0.4; 2026-10-10,
11 min 44 s, a load of 0.13 at the start and the harness the only busy
process. Every answer passed the gate.

**As a language**, cocolog --local is 0.6-2.3 times CPython and 0.7-1.6
times SWI-Prolog with `-O` (Run R: 0.5-2.6 and 0.8-1.6). **The counting
loop is still level with SWI-Prolog with `-O`**, 1.04x, and sortnums is
ahead of it, 0.72x (Run R: 0.98x and 0.76x); the lookup is 1.5x (1.4x).
Against `swipl` as installed cocolog is faster on four tasks of five (queens
1.76x, loop 2.93x, lookup 2.85x, sortnums 3.12x) and 1.27 times slower on
naive reverse (Run R: 1.62). **As a state machine**, against python +
sqlite3 -- faster on four tasks of five:

| task (one rep) | cocolog --embed | cocolog zigurat | cpython + sqlite3 | cocolog against it | Run R |
|---|---:|---:|---:|---|---|
| lookup, 1000 probes / 200 facts | 0.000314 s | 0.000265 s | 0.005964 s | **19.0x faster** (22.5x) | 25.6x (18.9x) |
| loop, 100 000 additions | 0.005788 s | 0.006604 s | 0.036159 s | **6.25x faster** (5.48x) | 6.26x (7.10x) |
| nrev, 400-element list | 0.004998 s | 0.004248 s | 0.007278 s | **1.46x faster** (1.71x) | 2.02x (1.58x) |
| sortnums, 5000 integers | 0.001618 s | 0.001909 s | 0.003353 s | **2.07x faster** (1.76x) | 1.66x (1.69x) |
| queens, all 92 solutions | 0.003737 s | 0.004091 s | 0.002161 s | 1.73x slower (1.89x) | 1.82x slower (1.73x) |

Four things to read with care:

* **The engine change is STATUS.md's counts and pairs, not this run against
  Run R.** This sitting's rivals ran 0.68-1.03 times their Run R per rep
  (CPython 0.68-0.92, SWI-Prolog with `-O` 0.74-1.03) and cocolog --local
  0.79-1.04 times (nrev 0.90, queens 0.79, loop 1.04, lookup 0.80, sortnums
  0.98). Counted under callgrind from 1.9.3 to 1.9.6, the lookup runs 24 %
  fewer instructions (1.9.4 -4.12 %, 1.9.5's builtins in place -17.02 %,
  1.9.6's fused guards -4.87 %), nrev 1.4 % fewer, the loop 1.1 %, sortnums
  0.5 % and queens 0.1 %. Timed, 1.9.4 over 1.9.3 read 0.97-1.03 on every
  task (fifteen pairs each), 1.9.5 over 1.9.4 (nine alternating pairs)
  lookup 0.80, loop 0.93, queens 0.98, sortnums 1.03 and nrev 1.10 --
  nrev's from where the step loop's functions landed, not from what they
  run -- and 1.9.6 took no clock. The lookup's gain does not show against
  SWI-Prolog with `-O`, whose probe ran 0.74 of its Run R (1.54x where Run R
  read 1.42x).
* **CPython's loop ran 0.68 of its Run R per rep**, with a fixed cost of
  0.38 s and a `2R/R` of 1.72, so the loop reads 1.6 times CPython where Run
  R's read 1.1, and level with SWI-Prolog with `-O` as before.
* **The sqlite lanes sped up** -- 0.65 of their Run R per rep on nrev, 0.66
  on lookup, 0.80-0.94 on the rest -- so the embedded store's lead fell at
  the keyed probes (25.6x to 19.0x) and on nrev (2.02x to 1.46x), while the
  socket's at the probes rose (18.9x to 22.5x), its own lane 0.55 of its
  Run R.
* **The three cocolog arrangements spread up to 21 %** (Run R: 55 %): the
  embedded nrev behind --local by 21 %, as in Run R, and its lookup by 18 %
  (a `2R/R` of 2.31); the embedded store ahead of --local on sortnums by
  13 % (1.60, the least linear figure in the table), the loop by 6 % and
  queens by 4 %; the socket within 8 % of --local on every task (nrev 3 %,
  where Run R's was 55 %). Each lane computes in memory after one consult,
  so the order is the sitting's noise, which the `2R/R` column shows.

The run, as `sh bench/langs.sh` printed it:

```

cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.15 at /usr/local/bin/python3, cocolog 1.9.6 at /home/user/cocolog/cocolog
SWI-Prolog version 9.0.4 for x86_64-linux at /usr/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.13     0.007297      1.0x        -    1.93  cpython_process
   swi-O         512    0.03     0.003097      0.4x     1.0x    1.98  swi_prolog_process_optimised
   swi           512    0.09     0.003243      0.4x     1.0x    1.95  swi_prolog_process_as_installed
   local         512    0.20     0.004118      0.6x     1.3x    1.92  cocolog_local_in_memory_no_database
   embed         256    0.00     0.004998      0.7x     1.6x    2.06  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.15     0.004248      0.6x     1.4x    1.93  cocolog_server_one_kb_emptied
   sqlite        256    0.22     0.007278      1.0x        -    1.89  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.14     0.001967      1.0x        -    1.93  cpython_process
   swi-O         512    0.14     0.002474      1.3x     1.0x    1.90  swi_prolog_process_optimised
   swi           256    0.00     0.006880      3.5x     2.8x    2.05  swi_prolog_process_as_installed
   local         512    0.11     0.003909      2.0x     1.6x    1.95  cocolog_local_in_memory_no_database
   embed         256    0.20     0.003737      1.9x     1.5x    1.83  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.00     0.004091      2.1x     1.7x    2.00  cocolog_server_one_kb_emptied
   sqlite       1024    0.00     0.002161      1.1x        -    2.01  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.38     0.003802      1.0x        -    1.72  cpython_process
   swi-O         256    0.00     0.005929      1.6x     1.0x    2.17  swi_prolog_process_optimised
   swi           128    0.00     0.017979      4.7x     3.0x    2.03  swi_prolog_process_as_installed
   local         256    0.00     0.006137      1.6x     1.0x    2.02  cocolog_local_in_memory_no_database
   embed         256    0.04     0.005788      1.5x     1.0x    1.97  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.04     0.006604      1.7x     1.1x    1.98  cocolog_server_one_kb_emptied
   sqlite         64    0.00     0.036159      9.5x        -    2.16  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python      16384    0.00     0.000117      1.0x        -    2.15  cpython_process
   swi-O        8192    0.35     0.000173      1.5x     1.0x    1.80  swi_prolog_process_optimised
   swi          2048    0.00     0.000757      6.5x     4.4x    2.25  swi_prolog_process_as_installed
   local        4096    0.00     0.000266      2.3x     1.5x    2.02  cocolog_local_in_memory_no_database
   embed        8192    0.00     0.000314      2.7x     1.8x    2.31  cocolog_embedded_mvccs_fresh_store
   zigurat      8192    0.00     0.000265      2.3x     1.5x    2.02  cocolog_server_one_kb_emptied
   sqlite        256    0.00     0.005964     51.0x        -    2.05  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.42     0.001453      1.0x        -    1.78  cpython_process
   swi-O        1024    0.00     0.002586      1.8x     1.0x    2.21  swi_prolog_process_optimised
   swi           256    0.00     0.005827      4.0x     2.3x    2.03  swi_prolog_process_as_installed
   local        1024    0.60     0.001866      1.3x     0.7x    1.76  cocolog_local_in_memory_no_database
   embed         512    0.56     0.001618      1.1x     0.6x    1.60  cocolog_embedded_mvccs_fresh_store
   zigurat      1024    0.26     0.001909      1.3x     0.7x    1.88  cocolog_server_one_kb_emptied
   sqlite        512    0.00     0.003353      2.3x        -    2.10  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.02 s
   swi-O          0.02 s
   swi            0.02 s
   local          0.01 s
   embed          0.02 s
   zigurat        0.02 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.03         0.03         0.02         1x
       2000         0.03         0.03         0.02         1x
      20000         0.03         0.05         0.05         2x

```

### Run T: 1.10.20, Run S's engine and what it has carried since

cocolog 1.10.20, the tree this section was committed with. No engine stage
came between Run S and it: what landed -- 1.10.6's core builtins raising
SWI's errors, 1.10.7's reader written once and emitted twice, 1.10.12's
tracer keeping the untraced clock, 1.10.15's journal, 1.10.17's backtrace,
1.10.18 and 1.10.19's cyclic terms written and walked -- sits on paths an
untraced run does not take, or pays a store or a decrement on one, and
each was held to the untraced engine's instruction count when it landed
(`tools/flow/zero.sh`). Built by clang in release mode with every jump
padded, as Runs Q to S were, by Cicili 2.0.1, whose C for this tree is
2.0.0's byte for byte; ZiguratIP's MVCCS engine at `01251f4` (1.0.0)
linked in, the embedded lane's store made on 64 KiB pages, 1.9.7's default
(Run S's was on 8 KiB); the zigurat lane is ZiguratIP 1.0.0 started fresh
for the run on a fresh store of 64 KiB pages. The same kind of box as Runs
O to S, a four-vCPU Intel Xeon microVM at 2.80 GHz (Linux 6.18, 16 GB),
with Python 3.11.15 and SWI-Prolog 9.0.4; 2026-10-12, 11 min 57 s, the
harness the only busy process (a one-minute load of 1.67 at the start: the
suite, just ended). Every answer passed the gate.

**As a language**, cocolog --local is 0.7-2.2 times CPython and 1.0-1.9
times SWI-Prolog with `-O` (Run S: 0.6-2.3 and 0.7-1.6): the loop 1.12x
and sortnums level, 1.01x (Run S: 1.04x and 0.72x), the lookup 1.16x
(1.54x), queens 1.43x (1.58x) and naive reverse 1.89x (1.33x). Against
`swipl` as installed cocolog is faster on four tasks of five (queens
2.24x, loop 3.48x, lookup 2.58x, sortnums 2.38x) and 1.79 times slower on
naive reverse (Run S: 1.27). **As a state machine**, against python +
sqlite3 -- faster on four tasks of five, as in Run S:

| task (one rep) | cocolog --embed | cocolog zigurat | cpython + sqlite3 | cocolog against it | Run S |
|---|---:|---:|---:|---|---|
| lookup, 1000 probes / 200 facts | 0.000221 s | 0.000228 s | 0.005643 s | **25.5x faster** (24.8x) | 19.0x (22.5x) |
| loop, 100 000 additions | 0.005626 s | 0.004967 s | 0.029366 s | **5.22x faster** (5.91x) | 6.25x (5.48x) |
| nrev, 400-element list | 0.005789 s | 0.003618 s | 0.008127 s | **1.40x faster** (2.25x) | 1.46x (1.71x) |
| sortnums, 5000 integers | 0.001980 s | 0.002080 s | 0.002604 s | **1.32x faster** (1.25x) | 2.07x (1.76x) |
| queens, all 92 solutions | 0.003995 s | 0.003873 s | 0.001854 s | 2.15x slower (2.09x) | 1.73x slower (1.89x) |

Four things to read with care:

* **What moved since Run S is the sitting, not the engine.** Counted under
  callgrind, 1.10.20 runs what 1.9.6 ran: the work less its jump padding
  is 66 063 647 instructions for nrev against 66 063 874, queens 0.034 %
  more and lookup 0.070 % fewer (with the padding, which every change
  moves, 0.15 % and 0.16 % more and 0.03 % fewer; `sh tools/flow/zero.sh`
  over the two binaries). Timed in five alternating pairs of the two
  binaries after the run (`run nrev.pl main(400,512)`, the wall clock),
  1.10.20 took 1.02 times 1.9.6's time, the pairs 0.94 to 1.08. This
  sitting's rivals ran 0.72-1.18 times their Run S per rep (CPython
  0.76-1.18, SWI-Prolog with `-O` 0.75-1.05, as installed 0.72-1.08,
  python + sqlite3 0.78-1.12) and cocolog --local 0.79-1.36 times (nrev
  1.36, queens 0.84, loop 0.82, lookup 0.79, sortnums 1.14).
* **nrev is the sitting's noisiest row.** cocolog's three arrangements,
  which compute alike after one consult, spread 60 % on it -- --local
  0.005582 s and the embedded store 0.005789 s with a `2R/R` of 2.29 and
  2.21, the socket 0.003618 s at 1.72 -- so its 1.89x against SWI-Prolog
  with `-O` and 1.79x against `swipl` belong to this sitting's --local
  lane; the pairs above say the engine's nrev is 1.9.6's.
* **The sqlite lanes moved against cocolog's on three rows.** python +
  sqlite3 ran sortnums at 0.78 of its Run S per rep while the embedded
  store ran it at 1.22, so that lead fell from 2.07x to 1.32x; the loop's
  fell from 6.25x to 5.22x, sqlite at 0.81 of its Run S and the store at
  0.97; at the probes the store ran 0.70 of its Run S and sqlite 0.95, so
  that lead rose from 19.0x to 25.5x.
* **Off nrev, the three cocolog arrangements spread up to 21 %** (Run S:
  21 %): queens behind --local by 21 % embedded and 17 % over the socket,
  the loop by 12 % embedded and level over the socket, the lookup by 5 %
  and 8 %, sortnums ahead by 7 % and 2 %. Each lane computes in memory
  after one consult, so the order is the sitting's.

The run, as `sh bench/langs.sh` printed it:

```

cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.15 at /usr/local/bin/python3, cocolog 1.10.20 at /home/user/cocolog/cocolog
SWI-Prolog version 9.0.4 for x86_64-linux at /usr/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.00     0.008412      1.0x        -    2.07  cpython_process
   swi-O         512    0.19     0.002954      0.4x     1.0x    1.89  swi_prolog_process_optimised
   swi           512    0.14     0.003113      0.4x     1.1x    1.92  swi_prolog_process_as_installed
   local         512    0.00     0.005582      0.7x     1.9x    2.29  cocolog_local_in_memory_no_database
   embed         256    0.00     0.005789      0.7x     2.0x    2.21  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.73     0.003618      0.4x     1.2x    1.72  cocolog_server_one_kb_emptied
   sqlite        256    0.00     0.008127      1.0x        -    2.01  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.88     0.001500      1.0x        -    1.63  cpython_process
   swi-O         512    0.16     0.002299      1.5x     1.0x    1.88  swi_prolog_process_optimised
   swi           256    0.00     0.007402      4.9x     3.2x    2.10  swi_prolog_process_as_installed
   local         512    0.79     0.003298      2.2x     1.4x    1.68  cocolog_local_in_memory_no_database
   embed         256    0.04     0.003995      2.7x     1.7x    1.96  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.13     0.003873      2.6x     1.7x    1.89  cocolog_server_one_kb_emptied
   sqlite       1024    0.18     0.001854      1.2x        -    1.92  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.00     0.004486      1.0x        -    2.04  cpython_process
   swi-O         256    0.25     0.004458      1.0x     1.0x    1.82  swi_prolog_process_optimised
   swi           128    0.06     0.017441      3.9x     3.9x    1.98  swi_prolog_process_as_installed
   local         256    0.22     0.005010      1.1x     1.1x    1.85  cocolog_local_in_memory_no_database
   embed         256    0.06     0.005626      1.3x     1.3x    1.96  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.34     0.004967      1.1x     1.1x    1.79  cocolog_server_one_kb_emptied
   sqlite         64    0.08     0.029366      6.5x        -    1.96  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python      16384    0.04     0.000099      1.0x        -    1.98  cpython_process
   swi-O        8192    0.10     0.000182      1.8x     1.0x    1.94  swi_prolog_process_optimised
   swi          4096    0.05     0.000545      5.5x     3.0x    1.98  swi_prolog_process_as_installed
   local        8192    0.25     0.000211      2.1x     1.2x    1.87  cocolog_local_in_memory_no_database
   embed        8192    0.26     0.000221      2.2x     1.2x    1.87  cocolog_embedded_mvccs_fresh_store
   zigurat      8192    0.06     0.000228      2.3x     1.3x    1.97  cocolog_server_one_kb_emptied
   sqlite        256    0.03     0.005643     57.0x        -    1.98  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.19     0.001645      1.0x        -    1.90  cpython_process
   swi-O        1024    0.01     0.002118      1.3x     1.0x    2.00  swi_prolog_process_optimised
   swi           256    0.21     0.005062      3.1x     2.4x    1.86  swi_prolog_process_as_installed
   local        1024    0.00     0.002130      1.3x     1.0x    2.04  cocolog_local_in_memory_no_database
   embed        1024    0.05     0.001980      1.2x     0.9x    1.98  cocolog_embedded_mvccs_fresh_store
   zigurat      1024    0.00     0.002080      1.3x     1.0x    2.01  cocolog_server_one_kb_emptied
   sqlite        512    0.14     0.002604      1.6x        -    1.90  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.02 s
   swi-O          0.02 s
   swi            0.02 s
   local          0.01 s
   embed          0.01 s
   zigurat        0.01 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.02         0.02         0.02         1x
       2000         0.02         0.02         0.02         1x
      20000         0.02         0.03         0.03         1x

```

### Run U: 2.2.5, on Run M's kind of host again

cocolog 2.2.5, the tree this section was committed with (master at
`0bc517d`, whose last two merges changed the reasoning library alone). What
came between Run T and it -- 1.10.28's growths out of line, which raise
resource_error(memory), 1.12's trail of values, one-step builtins and two
clocks, 1.13's text in characters and catch/3's frame dropped, 1.14's
shifts, 1.15's whole-run clock, 2.0.0's 64-bit integers, and 2.1 and 2.2's
floats and writer, swipl's -- was counted under callgrind as it landed
(`tools/flow/zero.sh`): 1.10.28 moved the work less its jump padding by
+0.63 % on nrev, -2.5 % on queens and -1.6 % on lookup, 2.0.0 by -0.16 %,
+0.26 % and +0.38 %, and all of it together is the second point below.
Built by clang in release mode with every jump padded, as Runs Q to T were,
by Cicili 3.0.0 (`9d74a5e`); ZiguratIP's MVCCS engine at `90d99b8` (1.0.1)
linked in, the embedded lane's store made fresh on 64 KiB pages; the
zigurat lane is ZiguratIP 1.0.1 started for the run, on the suites' store
of 64 KiB pages. **Not the box of Runs O to T**: a four-vCPU Intel Xeon
microVM at 2.10 GHz, family 6, model 207 (an Emerald Rapids; theirs was a
Cascade Lake, model 85, at 2.80 GHz) -- by its label and its rivals' times
Run M's kind of host -- Linux 6.18, 16 GB, with Python 3.11.15 and
SWI-Prolog 9.0.4; 2026-10-17, 11 min 14 s, the harness the only busy
process (a one-minute load of 0.11 at the start). Every answer passed the
gate.

**As a language**, cocolog --local is 0.9-2.9 times CPython and 1.0-2.0
times SWI-Prolog with `-O` (Run T: 0.7-2.2 and 1.0-1.9): sortnums level,
1.04x, the loop 1.39x (Run T: 1.01x and 1.12x), the lookup 1.52x (1.16x),
queens 1.70x (1.43x) and naive reverse 2.00x (1.89x). Against `swipl` as
installed cocolog is faster on four tasks of five (queens 1.79x, loop
2.93x, lookup 2.07x, sortnums 2.87x) and 1.81 times slower on naive
reverse (Run T: 1.79). **As a state machine**, against python + sqlite3 --
faster on four tasks of five, as in Runs S and T:

| task (one rep) | cocolog --embed | cocolog zigurat | cpython + sqlite3 | cocolog against it | Run T |
|---|---:|---:|---:|---|---|
| lookup, 1000 probes / 200 facts | 0.000205 s | 0.000204 s | 0.003968 s | **19.4x faster** (19.5x) | 25.5x (24.8x) |
| loop, 100 000 additions | 0.005035 s | 0.005045 s | 0.025017 s | **4.97x faster** (4.96x) | 5.22x (5.91x) |
| nrev, 400-element list | 0.003901 s | 0.003883 s | 0.004523 s | **1.16x faster** (1.16x) | 1.40x (2.25x) |
| sortnums, 5000 integers | 0.001802 s | 0.001705 s | 0.002343 s | **1.30x faster** (1.37x) | 1.32x (1.25x) |
| queens, all 92 solutions | 0.003219 s | 0.003817 s | 0.001648 s | 1.95x slower (2.32x) | 2.15x slower (2.09x) |

Four things to read with care:

* **The box moved every ratio, and against cocolog.** Against Run T,
  CPython ran 0.54-1.17 times its per rep (nrev 0.54, queens 1.17, loop
  0.65, lookup 0.76, sortnums 0.77), SWI-Prolog with `-O` 0.68-0.84, as
  installed 0.71-0.97, python + sqlite3 0.56-0.90 -- and cocolog --local
  0.72-1.02 (nrev 0.72, queens 0.99, loop 0.95, lookup 1.02, sortnums
  0.80). Every rival gained more from this box than cocolog did, so the
  gaps widened with no change of work: the loop from 1.12x SWI-Prolog with
  `-O` to 1.39x, the lookup from 1.16x to 1.52x. Against Run M, the last
  run on such a host, the rivals ran 0.84-1.17 times their per rep
  (CPython 0.96-1.06, SWI-Prolog with `-O` 0.95-1.15, as installed
  0.95-1.17, python + sqlite3 0.84-1.10) and cocolog --local 0.41-0.85
  times 1.8.48's -- the loop 2.5 times faster, sortnums 1.9, the lookup
  1.5, queens 1.35, nrev 1.17 -- so on this host's terms cocolog went from
  1.9-3.9 times SWI-Prolog with `-O` to 1.0-2.0.
* **The engine executes what 1.9.6 did, and on this box takes longer over
  it.** Counted under callgrind after the run, 2.2.5's work less its jump
  padding is 0.60 % more than 1.9.6's on nrev (66 480 220 instructions
  against 66 084 037), 2.10 % less on queens and 1.12 % less on lookup
  (`sh tools/flow/zero.sh` over Run S's binary and this one, both orders),
  and the counting loop, which zero.sh does not run, 1.04 % more with its
  padding (`main(100000,4)` less `main(100000,0)`). Timed in five
  alternating pairs of the two after the run (the --local lane's command
  at this run's reps, the wall clock), 2.2.5 took 1.11 times 1.9.6's time
  on nrev (the pairs 0.95-1.14), 1.13 on the loop (1.04-1.23), 1.06 on the
  lookup (1.05-1.31), 1.01 on queens (0.88-1.08) and on sortnums
  (0.83-1.07); a round-robin of six releases after that, five rounds, put
  nrev at 1.03 (0.99-1.09) and the loop at 1.09 (1.06-1.17). On nrev the
  releases between scatter with no step (1.10.27 0.97, 1.11.0 1.03, 1.15.0
  1.04, 2.2.1 1.10); on the loop every one from 1.10.27 on reads 1.03-1.09
  (1.08, 1.06, 1.03, 1.09), so whatever this box charges the loop came
  before 1.10.27. On the Cascade Lake, Run T's pairs put 1.10.20 at 1.02
  times 1.9.6 on nrev. Where this box spends the difference is not looked
  for: this VM has no hardware counters.
* **The three cocolog arrangements are within 6 % of one another on every
  task but queens over the socket**, 16 % behind --local, where Run T's
  spread 60 % on nrev and up to 21 % off it: nrev within 3 %, the loop 6 %
  (the embedded store and the socket behind), the lookup 5 % (both ahead),
  sortnums 6 % (the embedded store behind, the socket level). Each lane
  computes in memory after one consult, so the order is the sitting's.
* **The store's leads moved with the box, not the store.** At the probes
  from 25.5x to 19.4x, python + sqlite3 at 0.70 of its Run T per rep and
  the embedded store at 0.93; on nrev from 1.40x to 1.16x, sqlite at 0.56
  and the store at 0.67; on queens the store's gap closed from 2.15x to
  1.95x, sqlite at 0.89 and the store at 0.81; the loop (5.22x to 4.97x)
  and sortnums (1.32x to 1.30x) held.

The run, as `sh bench/langs.sh` printed it:

```

cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.15 at /usr/local/bin/python3, cocolog 2.2.5 at /home/user/cocolog/cocolog
SWI-Prolog version 9.0.4 for x86_64-linux at /usr/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.13     0.004545      1.0x        -    1.90  cpython_process
   swi-O        1024    0.10     0.001998      0.4x     1.0x    1.95  swi_prolog_process_optimised
   swi          1024    0.00     0.002213      0.5x     1.1x    2.00  swi_prolog_process_as_installed
   local         512    0.00     0.003997      0.9x     2.0x    2.08  cocolog_local_in_memory_no_database
   embed         512    0.00     0.003901      0.9x     2.0x    2.00  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.00     0.003883      0.9x     1.9x    2.03  cocolog_server_one_kb_emptied
   sqlite        256    0.34     0.004523      1.0x        -    1.77  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.00     0.001762      1.0x        -    2.03  cpython_process
   swi-O        1024    0.00     0.001923      1.1x     1.0x    2.00  swi_prolog_process_optimised
   swi           256    0.00     0.005861      3.3x     3.0x    2.06  swi_prolog_process_as_installed
   local         512    0.08     0.003277      1.9x     1.7x    1.96  cocolog_local_in_memory_no_database
   embed         512    0.09     0.003219      1.8x     1.7x    1.95  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.00     0.003817      2.2x     2.0x    2.13  cocolog_server_one_kb_emptied
   sqlite       1024    0.18     0.001648      0.9x        -    1.90  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.05     0.002923      1.0x        -    1.97  cpython_process
   swi-O         512    0.04     0.003422      1.2x     1.0x    1.98  swi_prolog_process_optimised
   swi           128    0.19     0.013976      4.8x     4.1x    1.91  swi_prolog_process_as_installed
   local         256    0.15     0.004764      1.6x     1.4x    1.89  cocolog_local_in_memory_no_database
   embed         256    0.10     0.005035      1.7x     1.5x    1.93  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.07     0.005045      1.7x     1.5x    1.95  cocolog_server_one_kb_emptied
   sqlite         64    0.00     0.025017      8.6x        -    2.05  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python      16384    0.05     0.000075      1.0x        -    1.96  cpython_process
   swi-O       16384    0.00     0.000141      1.9x     1.0x    2.06  swi_prolog_process_optimised
   swi          4096    0.21     0.000446      5.9x     3.2x    1.90  swi_prolog_process_as_installed
   local        8192    0.00     0.000215      2.9x     1.5x    2.03  cocolog_local_in_memory_no_database
   embed        8192    0.10     0.000205      2.7x     1.5x    1.94  cocolog_embedded_mvccs_fresh_store
   zigurat      8192    0.02     0.000204      2.7x     1.4x    1.99  cocolog_server_one_kb_emptied
   sqlite        512    0.09     0.003968     52.9x        -    1.96  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.16     0.001260      1.0x        -    1.89  cpython_process
   swi-O        1024    0.04     0.001645      1.3x     1.0x    1.98  swi_prolog_process_optimised
   swi           256    0.00     0.004885      3.9x     3.0x    2.03  swi_prolog_process_as_installed
   local        1024    0.08     0.001705      1.4x     1.0x    1.96  cocolog_local_in_memory_no_database
   embed        1024    0.00     0.001802      1.4x     1.1x    2.02  cocolog_embedded_mvccs_fresh_store
   zigurat      1024    0.00     0.001705      1.4x     1.0x    2.01  cocolog_server_one_kb_emptied
   sqlite        512    0.04     0.002343      1.9x        -    1.97  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.01 s
   swi-O          0.01 s
   swi            0.01 s
   local          0.01 s
   embed          0.03 s
   zigurat        0.02 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.03         0.02         0.02         1x
       2000         0.02         0.02         0.02         1x
      20000         0.02         0.03         0.03         1x

```

### Run V: 2.5.1, the Mac again

cocolog 2.5.1, the tree this section was committed with (master at
`d966687`, the 2.5.1 commit; this section is the commit after it). What came
between Run U and it: 2.3.0's logical update view for assert and retract,
whose probe reads `nprobe` (+0.32 % on nrev, counted under callgrind at the
time); 2.4.0's Unix domain sockets; 2.4.1's template library and cocolint's
auto mode; and 2.5.0's rationals with the four-bit cell tag, counted on this
Mac against the released 2.4.1 binary in five alternating pairs of user time:
nrev +4.7 % (1.258 s to 1.317 s), queens -0.1 % and lookup -1.3 %. 2.5.1's
two fixes -- the window clock's nanosecond source on Darwin and `-0.0`
through atom_number -- touch no lane here. Built by clang in release mode
with every jump padded, by Cicili 3.0.0 (`9d74a5e`); ZiguratIP's MVCCS
engine at `90d99b8` (1.0.1) linked in, the embedded lane's store made fresh
on 64 KiB pages; the zigurat lane is the server this box had up on 2160 (its
`--version` says 1.0.0; the checkout and the engine linked into cocolog are
90d99b8, 1.0.1). **The same Mac as Run N**: an Intel i9-9880H
MacBookPro16,1, 16 GB, macOS 26.7.1 (Run N read 26.6.2), 16 logical CPUs,
with Python 3.11.13 (the pyenv shim looked through) and SWI-Prolog 10.0.2
(Homebrew). 2026-10-19, 12 min 59 s; the Zigurat server was up. Every answer
passed the gate.

**As a language**, cocolog --local is 0.9-2.0 times CPython and 1.1-2.0
times SWI-Prolog with `-O`: naive reverse 0.87x CPython (1.62x swi-O),
sortnums 0.93x (1.07x), the loop 1.21x (1.39x), queens 1.80x (1.95x) and
the lookup 1.95x (1.54x). Against `swipl` as installed cocolog is faster on
four tasks of five -- queens 8.4x, loop 20.8x, lookup 9.9x, sortnums 9.1x
-- and 1.26 times slower on naive reverse, the one task with no arithmetic
in it, where the flag changes nothing. **As a state machine**, against
python + sqlite3 -- faster on four tasks of five:

| task (one rep) | cocolog --embed | cocolog zigurat | cpython + sqlite3 | cocolog against it | Run N |
|---|---:|---:|---:|---|---|
| lookup, 1000 probes / 200 facts | 0.000217 s | 0.000221 s | 0.013204 s | **60.8x faster** (59.7x) | 33x (36x) |
| loop, 100 000 additions | 0.005847 s | 0.006374 s | 0.036448 s | **6.23x faster** (5.72x) | 2.1x (2.2x) |
| nrev, 400-element list | 0.004261 s | 0.004257 s | 0.005328 s | **1.25x faster** (1.25x) | level (1.05x; 1.15x slower) |
| sortnums, 5000 integers | 0.001836 s | 0.001929 s | 0.002608 s | **1.42x faster** (1.35x) | 1.3x slower |
| queens, all 92 solutions | 0.004407 s | 0.004004 s | 0.002374 s | 1.86x slower (1.69x) | 2.4x slower |

Five things to read with care:

* **The same Mac as Run N, with a new OS and a faster cocolog.** Against
  Run N, cocolog --local ran 0.49-0.87 times its per rep (nrev 0.87, queens
  0.73, loop 0.49, lookup 0.64, sortnums 0.58), while CPython ran 0.97-1.50
  times its (lookup 1.50, loop 1.15, sortnums 1.12, nrev 1.05, queens
  0.97), SWI-Prolog with `-O` 0.93-1.06, as installed 1.00-1.37 and python
  + sqlite3 1.04-1.37 (loop 1.37, queens 1.20). macOS moved from 26.6.2 to
  26.7.1 between the runs, so part of every ratio is the OS; what is not the
  OS is the engine, which 1.8.48's did not have: the loop is the widest,
  cocolog 2.0 times its Run N per rep.
* **Run N's Python lookup lane was the one in doubt, and this run's is not.**
  Run N calibrated it to 16 384 reps and read a fixed cost of 0.99 s and a
  `2R/R` of 1.55 (every other lane 0.0-0.3 s and 1.8-2.0), so its 0.000074 s
  a rep was low and the 4.6x beside cocolog's lookup an overstatement. This
  run reads 0.000111 s, a fixed cost of 0.29 s and `2R/R` 1.86, so the
  lookup gap against CPython is 2.0x, not 4.6x -- the engine did not move
  the lookup, the lane did.
* **The engine since Run U is 2.5.0's rational cell and four-bit tag**, and
  Run U was on another box, so its per rep figures are not comparable with
  these. On this Mac against 2.4.1 the tag cost nrev +4.7 %, queens -0.1 %
  and lookup -1.3 % in five alternating pairs (2.5.0's commit); 2.5.1's
  clock and signed-zero fixes touch no lane. Where this run is read, it is
  read against Run N, the other run on this box.
* **The three cocolog arrangements are within 16 % on queens and within 7 %
  on every other task**: nrev 0.2 % (local 0.004254, embed 0.004261, zigurat
  0.004257), the loop 7 % (zigurat behind, embed 2 % ahead), the lookup 2 %,
  sortnums 5 % (zigurat behind). Each lane computes in memory after one
  consult, so the order is the sitting's.
* **The store's leads moved with both the engine and sqlite's lane**: the
  keyed probes from 33x to 60.8x (the store 0.60 of its Run N per rep,
  sqlite 1.11), the loop from 2.1x to 6.23x (the store 0.47, sqlite 1.37),
  nrev from level to 1.25x (the store 0.79, sqlite 1.04), sortnums from 1.3x
  slower to 1.42x faster (the store 0.57, sqlite 1.07) and queens from 2.4x
  slower to 1.86x (the store 0.91, sqlite 1.20). The lookup-shape table is
  flat for cocolog and CPython and grows for `swi -O`, as on the other
  boxes.

The run, as `sh bench/langs.sh` printed it:

```

cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements
python3 3.11.13 at /Users/a1/.pyenv/versions/3.11.13/bin/python3, cocolog 2.5.1 at /Users/a1/Projects/GitHub/cocolog/cocolog
SWI-Prolog version 10.0.2 for x86_64-darwin at /usr/local/bin/swipl
wall clock, median of three timed runs at each of two sizes
a lane calibrated to ONE rep prints its wall time instead of a rate:
at one rep the fixed cost and the work cannot be told apart

-- nrev: one naive reverse of a 400-element list
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.20     0.004867      1.0x        -    1.86  cpython_process
   swi-O         512    0.39     0.002627      0.5x     1.0x    1.78  swi_prolog_process_optimised
   swi           512    0.05     0.003387      0.7x     1.3x    1.97  swi_prolog_process_as_installed
   local         256    0.20     0.004254      0.9x     1.6x    1.85  cocolog_local_in_memory_no_database
   embed         256    0.20     0.004261      0.9x     1.6x    1.85  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.24     0.004257      0.9x     1.6x    1.82  cocolog_server_one_kb_emptied
   sqlite        256    0.19     0.005328      1.1x        -    1.88  cpython_sqlite3_file_indexed_committed

-- queens: one full 8-queens search, all 92 solutions
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        512    0.17     0.002123      1.0x        -    1.86  cpython_process
   swi-O        1024    0.12     0.001957      0.9x     1.0x    1.94  swi_prolog_process_optimised
   swi            32    0.31     0.032120     15.1x    16.4x    1.77  swi_prolog_process_as_installed
   local         256    0.15     0.003812      1.8x     1.9x    1.86  cocolog_local_in_memory_no_database
   embed         512    0.00     0.004407      2.1x     2.3x    2.09  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.24     0.004004      1.9x     2.0x    1.81  cocolog_server_one_kb_emptied
   sqlite        512    0.11     0.002374      1.1x        -    1.92  cpython_sqlite3_file_indexed_committed

-- loop: one hundred thousand additions, one at a time
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python        256    0.18     0.004926      1.0x        -    1.88  cpython_process
   swi-O         256    0.42     0.004292      0.9x     1.0x    1.72  swi_prolog_process_optimised
   swi             8    0.08     0.124089     25.2x    28.9x    1.92  swi_prolog_process_as_installed
   local         256    0.24     0.005960      1.2x     1.4x    1.87  cocolog_local_in_memory_no_database
   embed         256    0.23     0.005847      1.2x     1.4x    1.87  cocolog_embedded_mvccs_fresh_store
   zigurat       256    0.13     0.006374      1.3x     1.5x    1.92  cocolog_server_one_kb_emptied
   sqlite         32    0.05     0.036448      7.4x        -    1.96  cpython_sqlite3_file_indexed_committed

-- lookup: a thousand key lookups over 200 facts
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python      16384    0.29     0.000111      1.0x        -    1.86  cpython_process
   swi-O        8192    0.71     0.000141      1.3x     1.0x    1.62  swi_prolog_process_optimised
   swi           512    0.18     0.002155     19.4x    15.3x    1.86  swi_prolog_process_as_installed
   local        8192    0.18     0.000217      2.0x     1.5x    1.91  cocolog_local_in_memory_no_database
   embed        8192    0.16     0.000217      2.0x     1.5x    1.92  cocolog_embedded_mvccs_fresh_store
   zigurat      8192    0.19     0.000221      2.0x     1.6x    1.91  cocolog_server_one_kb_emptied
   sqlite        128    0.12     0.013204    119.0x        -    1.94  cpython_sqlite3_file_indexed_committed

-- sortnums: one generate-and-sort of 5000 integers
   lane         reps   fixed    per rep s     vs py vs swi-O    2R/R  arrangement
   python       1024    0.16     0.001971      1.0x        -    1.93  cpython_process
   swi-O        1024    0.44     0.001705      0.9x     1.0x    1.80  swi_prolog_process_optimised
   swi            64    0.18     0.016731      8.5x     9.8x    1.86  swi_prolog_process_as_installed
   local        1024    0.24     0.001832      0.9x     1.1x    1.89  cocolog_local_in_memory_no_database
   embed        1024    0.24     0.001836      0.9x     1.1x    1.89  cocolog_embedded_mvccs_fresh_store
   zigurat       512    0.26     0.001929      1.0x     1.1x    1.79  cocolog_server_one_kb_emptied
   sqlite        512    0.25     0.002608      1.3x        -    1.84  cpython_sqlite3_file_indexed_committed

start-up alone, the same wall clock, nothing but boot and exit:
   python         0.14 s
   swi-O          0.21 s
   swi            0.16 s
   local          0.14 s
   embed          0.13 s
   zigurat        0.17 s

the shape of the lookup gap -- a thousand probes, three sizes:
      facts     python s      swi-O s    cocolog s      ratio
        200         0.18         0.19         0.18         1x
       2000         0.18         0.20         0.18         1x
      20000         0.19         0.25         0.19         1x

```

## The concurrency benchmark

`bench/concurrency.sh` puts the concurrency models through two questions in
one repository. The **work lanes** run the same `spin` work (`M` steps) in
`N` units: serial, real threads, green threads, Go goroutines and Python
asyncio. The **light lanes** run many short tasks (10,000, or 1,000 OS
threads) that do `true` and are joined, then the same with a yield each
round -- creation and switch cost, where green is supposed to win. A
**one-core** lane runs the real work lane under `taskset` where the system
has it. Every lane prints `answer(done)`; a lane that fails, throws or
answers anything else is REFUSED and no number appears; the first run of
each lane is the warm-up, and the minimum of three timed runs is printed.
The wall is around the whole process, as in the language benchmark; real
threads and Go goroutines may use the cores, green threads and the Python
coroutines share one, and the core count is printed by the harness.

**CONCURRENCY RUN A** -- 2026-10-20, the working tree's build (cocolog
2.6.0; the numbers were taken on its 2.5.2 build, a version-only
change), a 16-core Intel Mac running Darwin 25.6.0. The
command `sh bench/concurrency.sh` with its defaults: work N=8, M=1,000,000;
light 10,000 tasks (1,000 OS threads), 10 yields each; REPS=3. Go 1.27.1;
the Go binary is built once before the timing. Python is the interpreter
behind the pyenv shim (the shim alone spends ~1.7 s and would be the lane).

Work lanes, N=8, M=1,000,000:

| lane | wall |
|---|---|
| serial | 474.3 ms |
| real threads (`library(thread)`, 8 OS threads) | 180.7 ms |
| green threads (`library(async)`, 8 green threads) | 1305.3 ms |
| goroutines (Go, 8 goroutines) | 95.8 ms |
| coroutines (`asyncio`, 8 tasks) | 573.9 ms |

Light lanes, tasks that do `true` and are joined (10,000 green/Go/Python,
1,000 OS threads -- the Mac's user-process limit is 2,784, and a cocolog
thread carries a machine and a store):

| lane | wall | per task |
|---|---|---|
| light-real (1,000 OS threads) | 121.2 ms | 121.21 us |
| light-green (10,000, 64 to a scheduler) | 321.6 ms | 32.16 us |
| light-goroutine (10,000) | 105.6 ms | 10.56 us |
| light-python (10,000 asyncio tasks) | 248.1 ms | 24.81 us |

Light + yield, 10 yields each:

| lane | wall | per yield |
|---|---|---|
| light-y-real (1,000 x 10, mutex handoff) | 162.5 ms | 16.25 us |
| light-y-green (10,000 x 10, `yield/0`) | 328.2 ms | 3.28 us |
| light-y-goroutine (10,000 x 10, `Gosched`) | 123.8 ms | 1.24 us |
| light-y-python (10,000 x 10, `sleep(0)`) | 365.9 ms | 3.66 us |

One core: `real1` says SKIP on this Mac -- there is no `taskset`; on Linux
it runs the real work lane under `taskset -c 0`.

What the columns say, and what they do not:

- **work lanes**: the CPU-bound wall. **serial** is the work alone (8,000,000
  steps on one core); **real threads** are 2.6x faster (eight OS threads
  over 16 cores); **green threads** are 2.75x SLOWER -- one core,
  cooperative, plus eight per-spawn store snapshots; **goroutines** are
  4.9x faster than serial and 1.9x faster than the real lane (Go schedules
  M:N over the cores; its loop is a tight Go loop, not the Prolog
  recursion, so this is not a like-for-like engine comparison); **asyncio**
  is 1.2x serial (one core, the GIL; the real interpreter, not the shim).
- **light lanes**: creation and join. Here green is what it is for:
  **32.16 us a task against the OS thread's 121.21** (~3.8x cheaper), and
  **3.28 us a yield against the mutex handoff's 16.25** (~5x cheaper),
  snapshot included. Go's goroutines are cheaper still (10.56 us a task,
  1.24 us a yield); Python's asyncio sits between. The counts differ by
  lane (the OS lane is capped at 1,000), which is why the table prints the
  per-task and per-yield cost rather than the wall alone.
- The green lane's per-spawn snapshot is the model's fixed cost: a green
  thread is a machine and a store of its own, filled from the caller's
  knowledge base, because a store belongs to one machine. It is the reason
  the work lane is slower and the light lane is still competitive.
- **one core**: without `taskset` the Mac cannot pin an OS thread; the
  lane is written and says SKIP. On Linux it is the fair scheduler
  comparison with green: the real work lane on one core against the green
  work lane.

So "is green faster than an OS thread?" depends on the question: **no**
for CPU-bound wall time on many cores, **yes** per task and per switch --
the light lanes measure that, and the work lane measures the other. The
green thread is a cocolog machine with a cocolog store, its writes its own;
the Python coroutine shares one interpreter's memory; the Go goroutines
share the Go runtime and may use the cores; the real threads share nothing
but the process.

A workload note found on the way: `between(1, 2000, _), fail` in a green
store is not a benchmark of the scheduler -- a library predicate with a
choice point per answer takes seconds there, against a recursion's
milliseconds, so `bench/spin.pl` is a recursion. That is a fact about the
green store's copied library clauses, not about the scheduler; it is why
`test/async.pl` works in `spin/1` too.


**CONCURRENCY RUN B** -- 2026-10-20, the shared-store model (cocolog 2.7.0's
first stage: no per-spawn store snapshot, one scheduler), the same command
`sh bench/concurrency.sh` and the same defaults as Run A, a 16-core Intel
Mac. The green lane's tasks now share the caller's store and name tables
and a spawn copies nothing; the scheduler is still one OS thread.

Work lanes, N=8, M=1,000,000:

| lane | wall |
|---|---|
| serial | 487.8 ms |
| real threads (8 OS threads) | 184.0 ms |
| green threads (8 green threads) | 505.1 ms |
| goroutines (Go, 8) | 99.6 ms |
| coroutines (asyncio, 8) | 576.3 ms |

Light lanes (10,000 tasks; 1,000 OS threads):

| lane | per task | per yield |
|---|---|---|
| real threads | 117.62 us | 16.12 us (mutex handoff) |
| green threads | 10.64 us | 1.07 us (`yield/0`) |
| goroutines | 10.45 us | 1.24 us (`Gosched`) |
| coroutines | 23.04 us | 3.58 us (`sleep(0)`) |

The green work lane is now 505.1 ms against serial's 487.8 (one core; Run
A's snapshot model was 1305.3). The light lane is 10.64 us a task against
the OS thread's 117.62 (~11x) and level with Go's 10.45, and 1.07 us a
yield against 16.12 (~15x) and Go's 1.24. The multi-core half (M:N, worker
threads over one store) is not in this run: the scheduler is still one OS
thread, which is why the work lane is the serial lane plus overhead while
Run A's per-spawn snapshots are gone.
