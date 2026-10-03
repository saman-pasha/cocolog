#!/bin/sh
# cocolog against CPython and SWI-Prolog, the same task, in all three
# arrangements.
#
# `bench/languages.md' compares the two languages across every aspect and
# stops short of one sentence, on purpose: "the sentence `cocolog is
# faster/slower than X' is not written here because no harness printed
# it." This is the harness. It prints it.
#
# MOVED HERE FROM THE COCO (saman-pasha/coco, bench/langs.sh), with its
# programs and every run it ever printed (bench/README.md). It measures
# cocolog, so it lives with cocolog; The Coco's chain benchmarks stay there.
#
#     sh bench/langs.sh            from the checkout root, after `make'
#
# THE RULES ARE THE COCO'S TPS HARNESS'S (bench/harness.pl over there),
# adapted, because a number is the easiest thing in this repository to get
# wrong in a way nobody can see:
#
#   1. THE ANSWER IS VERIFIED, LANE AGAINST LANE. Every implementation
#      prints `answer(X)' and every lane must print the SAME X or the
#      task is REFUSED and no number appears. Rule 1 over there counts
#      rows to catch a transaction that did not commit; here it catches
#      the likelier fraud -- two programs that ran different work and
#      were compared anyway.
#   2. THE RUN IS LONG ENOUGH. Reps are CALIBRATED per lane by doubling
#      until the run clears a second, so no reading is start-up wearing
#      a number's clothes -- and the lanes therefore run different rep
#      counts, which is why every task's unit answers the same value
#      however many times it is repeated.
#   3. THE ARRANGEMENT IS NAMED, on every row. `local' has no database in
#      it. `embed' is the MVCCS engine linked into the process. `zigurat'
#      is the same store over a socket. Three different claims.
#   4. THE CLOCK IS THE WALL, around the whole process, which is what a
#      person waiting for an answer actually experiences.
#   5. THE FIRST RUNS ARE THROWN AWAY -- the calibration runs are the
#      warm-up, and the timed runs come after.
#
# AND ONE MORE, WHICH THIS COMPARISON NEEDS AND THE TPS HARNESS DOES NOT:
# EVERY LANE IS MEASURED AT TWO SIZES, R and 2R, so a fixed cost can be
# separated from a marginal one. Consulting a program into a store,
# opening a turn and committing it are paid ONCE per run; the task itself
# is paid per rep. A single wall time adds them together and calls the
# sum a speed. Two points take them apart:
#
#   fixed    ~ 2*t(R) - t(2R)        what the run costs before any work
#   per rep  ~ (t(2R) - t(R)) / R    what the work itself costs
#   2R/R     = t(2R) / t(R)          the SHAPE, and the column to read
#                                    first: 2.0 is linear, and anything
#                                    much above it means doubling the
#                                    work more than doubles the time
#
# AND THE CATEGORY ERROR THIS BENCHMARK REFUSES TO MAKE: PYTHON IS A
# LANGUAGE, COCOLOG IS A LANGUAGE AND A STATE MACHINE. A dict is memory --
# not durable, not transactional, invisible to any other process, gone
# when the interpreter exits. cocolog's `embed' and `zigurat' are a
# DATABASE: rows that outlive the process, a turn that commits or does
# not, a second process that reads what the first wrote. Timing those
# against a dict measures the guarantees rather than the engine, and it
# flatters Python for offering less.
#
# So the readings are read in two families, and the report says which:
#
#   AS A LANGUAGE   python against `local'. Both are an algorithm in
#                   memory with nothing kept. This is the fair pairing,
#                   and it is the one where "cocolog is slow" is a claim
#                   about cocolog rather than about durability.
#   AS A STATE      python+sqlite3 against `embed' and `zigurat' -- a
#   MACHINE         file on disk, an index on the key, the build
#                   committed as one transaction, against the same
#                   promises kept by rows.
#
# And the third column has no counterpart at all: a suspended machine any
# process can finish, a clause that IS a row another program queries, a
# turn that is the store's transaction. Those are not faster or slower
# than Python. They are absent from it, and a speed table cannot say so.
#
# AND THE SECOND YARDSTICK IS A PROLOG. CPython says what an algorithm
# costs in a language people reach for; it cannot say whether cocolog is a
# good PROLOG, because a dict is not a clause and a while loop is not a
# backtracking search. SWI-Prolog runs the very same `.pl' files, unedited,
# twice: `swi-O' is `swipl -O', which compiles arithmetic into the virtual
# machine's own instructions, and `swi' is `swipl' as installed, where
# `optimise' is false and every `is/2' builds its expression as a term and
# calls a predicate on it. Both run `swipl -f none -q [-O] -g main(N,R)
# -t halt FILE', so no init file of whoever runs it changes what is
# measured, and both answers pass the same gate as every other lane.
#
# `vs swi-O' IS READ AGAINST SWI AT ITS BEST, because a benchmark that
# picks the slower of two flags for its rival flatters itself. The first
# run with SWI in it had only the `swi' lane and read cocolog FASTER than
# SWI on four tasks of five; with `-O' the same box reads SWI's counting
# loop nine times faster (0.18 s against 1.61 for sixteen reps -- 787
# collections and half a second of system time without it, one with it).
# The `swi' row stays, because it is what typing `swipl FILE' gets, and
# its `vs swi-O' says what the flag is worth on that task.
#
# WHAT NO RULE CAN CATCH is which tasks were chosen -- `harness.pl' says
# it and it is truer here than anywhere: five small programs are not a
# language. These five were picked to include the ones cocolog is
# expected to LOSE, because a benchmark whose author chose the workload
# and won it says nothing at all.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)

# THIS CHECKOUT'S BINARY AND LIBRARY, and the server where the suite looks
# for one. The Coco read all four from its coco.yaml; each is an override
# here and nothing else.
C="${COCOLOG_BIN:-$ROOT/cocolog}"
COCOLOG_LIBRARY="$ROOT/library${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}"
export COCOLOG_LIBRARY
ZIGURAT_HOST=${ZIGURAT_HOST:-127.0.0.1}
ZIGURAT_PORT=${ZIGURAT_PORT:-2160}
ZIGURAT_DIAL="--host $ZIGURAT_HOST --tcp $ZIGURAT_PORT"

# THE CLOCK IS NANOSECONDS OR IT IS NOTHING. GNU date has %N; an older BSD
# date prints a literal N, which `$((...))' refuses halfway through a run.
# So the clock is found once: date when it can, else gdate, else perl's
# Time::HiRes, which every Mac carries.
if date +%N | grep -q '^[0-9]'; then now() { date +%s%N; }
elif command -v gdate >/dev/null 2>&1; then now() { gdate +%s%N; }
else now() { perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1e9'; }
fi

# AND THE CAP NEEDS A timeout(1), which a stock Mac does not have. perl's
# alarm survives exec, so the fallback kills what it runs the way timeout
# would, with a signal at the deadline.
if ! command -v timeout >/dev/null 2>&1; then
  if command -v gtimeout >/dev/null 2>&1; then timeout() { gtimeout "$@"; }
  else timeout() { _t=$1; shift; perl -e 'alarm shift; exec @ARGV or die "exec: $!"' "$_t" "$@"; }
  fi
fi

# THE PYENV SHIM IS NOT PYTHON. A run on the Mac found `python3' resolving
# through a shim that spends 1.8-3.7 s deciding which interpreter to start
# -- on 2026-10-01, on the same box, 2.0 s against the real binary's 0.14
# -- and the shim alone clears the one-second floor, so it would poison
# every python lane's calibration. PYTHON names an interpreter outright;
# else a shim is looked through.
PY=${PYTHON:-python3}
case "$(command -v "$PY" 2>/dev/null)" in
  */.pyenv/shims/*) PY=$(pyenv which "$PY" 2>/dev/null || echo "$PY") ;;
esac
L="$ROOT/bench/langs"
EMB="${TMPDIR:-/tmp}/coco-langbench-kb"
DBF="${TMPDIR:-/tmp}/coco-langbench.db"
KB=bench_langs
DIAL="$ZIGURAT_DIAL --timeout 120"
MIN_NS=1200000000          # a run under 1.2s is not a measurement
CAP_NS=25000000000         # and one over 25s is a calibration that ran away

if [ ! -x "$C" ]; then echo "no cocolog binary at $C"; exit 1; fi
command -v "$PY" >/dev/null || { echo "SKIP no python3"; exit 0; }

SWI=${SWIPL:-swipl}
LANES="python local embed"
if command -v "$SWI" >/dev/null 2>&1; then
  LANES="python swi-O swi local embed"
else
  echo "note: no SWI-Prolog ($SWI) on PATH -- the swi-O and swi lanes are skipped"
fi
if timeout 20 "$C" $DIAL --kb "$KB" list >/dev/null 2>&1; then
  LANES="$LANES zigurat"
else
  echo "note: no Zigurat server at $ZIGURAT_HOST:$ZIGURAT_PORT -- the zigurat lane is skipped"
fi

# NOTHING MAY RUN AWAY, AND NOTHING MAY BE LEFT BEHIND. A stray from an
# earlier run burning a core is not noise, it is a wrong answer: the
# first draft of this file measured a whole table against a leftover
# `--embed lookup' that had been running for eighteen minutes, and the
# store lanes came out FASTER than in memory, which is impossible. Every
# run is capped, and every run of this script starts by killing what a
# previous one may have left. (Bracketed, or the pattern matches the
# shell running it.)
RUN_CAP=180
pkill -f "[b]ench/langs/" 2>/dev/null
sleep 1

# One timed run. Prints "<nanoseconds> <answer>". The store lanes are
# RESET first, outside the timed region: a fresh embedded store, an
# emptied knowledge base. That reset is part of the arrangement and not
# part of the number.
run_once() {
  _lane=$1; _task=$2; _n=$3; _reps=$4
  case $_lane in
    python)  set -- timeout $RUN_CAP "$PY" "$L/$_task.py" "$_n" "$_reps" ;;
    swi-O)   set -- timeout $RUN_CAP "$SWI" -f none -q -O -g "main($_n,$_reps)" -t halt "$L/$_task.pl" ;;
    swi)     set -- timeout $RUN_CAP "$SWI" -f none -q -g "main($_n,$_reps)" -t halt "$L/$_task.pl" ;;
    local)   set -- timeout $RUN_CAP "$C" run "$L/$_task.pl" "main($_n,$_reps)" ;;
    embed)   rm -rf "$EMB"; mkdir -p "$EMB"
             set -- timeout $RUN_CAP "$C" --embed "$EMB" run "$L/$_task.pl" "main($_n,$_reps)" ;;
    zigurat) timeout 120 "$C" $DIAL --kb "$KB" forget >/dev/null 2>&1
             set -- timeout 300 "$C" $DIAL --kb "$KB" run "$L/$_task.pl" "main($_n,$_reps)" ;;
    sqlite)  rm -f "$DBF"
             set -- timeout $RUN_CAP "$PY" "$L/${_task}_sqlite.py" "$_n" "$_reps" "$DBF" ;;
  esac
  _s=$(now)
  _out=$("$@" 2>&1)
  _e=$(now)
  _ans=$(echo "$_out" | grep -aoE '^answer\([^)]*\)' | head -1)
  echo "$((_e - _s)) ${_ans:-NONE}"
}

# THE LABEL IS A FUNCTION, NOT A SUBSTITUTION. A multi-line `case`
# inside `$(...)` parses on dash and dies on macOS bash-as-sh
# ("syntax error near unexpected token newline"), which mangled every
# label column of the first run on a Mac while the numbers printed
# fine around it. A named function parses everywhere.
arr_name() {
  case $1 in
    python)  echo cpython_process ;;
    swi-O)   echo swi_prolog_process_optimised ;;
    swi)     echo swi_prolog_process_as_installed ;;
    local)   echo cocolog_local_in_memory_no_database ;;
    embed)   echo cocolog_embedded_mvccs_fresh_store ;;
    zigurat) echo cocolog_server_one_kb_emptied ;;
    sqlite)  echo cpython_sqlite3_file_indexed_committed ;;
  esac
}

median3() { printf '%s\n%s\n%s\n' "$1" "$2" "$3" | sort -n | sed -n 2p; }

# Double the reps until the run clears the floor. The runs spent here are
# the warm-up the fifth rule asks for.
calibrate() {
  _lane=$1; _task=$2; _n=$3
  _r=1
  while : ; do
    set -- $(run_once "$_lane" "$_task" "$_n" "$_r")
    [ "$1" -ge "$MIN_NS" ] && { echo "$_r"; return; }
    [ "$1" -ge "$CAP_NS" ] && { echo "$_r"; return; }
    _r=$((_r * 2))
    [ "$_r" -gt 100000000 ] && { echo "$_r"; return; }
  done
}

secs() { awk -v n="$1" 'BEGIN { printf "%.2f", n / 1000000000 }'; }

echo
echo "cocolog vs CPython and SWI-Prolog -- same task, same answer, four arrangements"
echo "python3 $("$PY" --version 2>&1 | cut -d' ' -f2) at $(command -v "$PY"), $("$C" --version) at $C"
case " $LANES " in *" swi-O "*) echo "$("$SWI" --version) at $(command -v "$SWI")" ;; esac
echo "wall clock, median of three timed runs at each of two sizes"
echo "a lane calibrated to ONE rep prints its wall time instead of a rate:"
echo "at one rep the fixed cost and the work cannot be told apart"
echo

# task  N     what one rep is
TASKS="nrev:400:one naive reverse of a 400-element list
queens:8:one full 8-queens search, all 92 solutions
loop:100000:one hundred thousand additions, one at a time
lookup:200:a thousand key lookups over 200 facts
sortnums:5000:one generate-and-sort of 5000 integers"

echo "$TASKS" | while IFS=: read -r task n what; do
  [ -z "$task" ] && continue
  echo "-- $task: $what"
  printf '   %-8s %8s %7s %12s %9s %8s %7s  %s\n' lane reps fixed 'per rep s' 'vs py' 'vs swi-O' '2R/R' arrangement
  _ref=""; _pyrate=""; _swirate=""
  _lanes=$LANES
  [ -f "$L/${task}_sqlite.py" ] && _lanes="$_lanes sqlite"
  for lane in $_lanes; do
    r=$(calibrate "$lane" "$task" "$n")
    a1=$(run_once "$lane" "$task" "$n" "$r"); a2=$(run_once "$lane" "$task" "$n" "$r"); a3=$(run_once "$lane" "$task" "$n" "$r")
    b1=$(run_once "$lane" "$task" "$n" "$((r * 2))"); b2=$(run_once "$lane" "$task" "$n" "$((r * 2))"); b3=$(run_once "$lane" "$task" "$n" "$((r * 2))")
    ans=$(echo "$a1" | cut -d' ' -f2)
    tR=$(median3 "$(echo "$a1" | cut -d' ' -f1)" "$(echo "$a2" | cut -d' ' -f1)" "$(echo "$a3" | cut -d' ' -f1)")
    t2R=$(median3 "$(echo "$b1" | cut -d' ' -f1)" "$(echo "$b2" | cut -d' ' -f1)" "$(echo "$b3" | cut -d' ' -f1)")

    # THE ANSWER GATE. Python is the reference because it is the lane
    # nobody here wrote the engine for.
    if [ -z "$_ref" ]; then _ref=$ans; fi
    if [ "$ans" != "$_ref" ] || [ "$ans" = "NONE" ]; then
      printf '   %-8s %8s %7s %12s %9s %8s %7s  REFUSED: answered %s, not %s\n' \
        "$lane" "$r" - - - - - "$ans" "$_ref"
      continue
    fi

    # A READING AT ONE REP CANNOT SEPARATE THE TWO COSTS, and must not
    # pretend to. With R=1 the second point is a single extra rep, so
    # t(2R) - t(R) is one rep plus this container's noise -- and when the
    # fixed cost is a hundred seconds, that difference is noise ALONE.
    # The first draft printed what came out of the formula: a ratio of
    # 1163220x for the server's lookup lane, and 0.0x for its sort. Both
    # are arithmetic, neither is a measurement. What IS honest at one rep
    # is the wall time itself, so that is what the row carries.
    if [ "$r" -le 1 ]; then
      printf '   %-8s %8s %7s %12s %9s %8s %7s  %s\n' "$lane" "$r" "$(secs $tR)" \
        'one rep' 'no rate' - - \
        "$(arr_name "$lane")"
      continue
    fi
    per=$(awk -v a="$tR" -v b="$t2R" -v r="$r" 'BEGIN { d = (b - a) / r / 1000000000; printf "%.6f", (d > 0 ? d : 0) }')
    fix=$(awk -v a="$tR" -v b="$t2R" 'BEGIN { f = (2 * a - b) / 1000000000; printf "%.2f", (f > 0 ? f : 0) }')
    if [ "$lane" = python ]; then
      _pyrate=$per; rel="1.0x"
    else
      rel=$(awk -v p="$per" -v q="$_pyrate" 'BEGIN { printf "%.1fx", (q > 0 ? p / q : 0) }')
    fi
    # Against SWI only from its own row down: python's row is read before
    # SWI's rate exists, and it is the `vs py' column's reference anyway.
    # sqlite's partner is a store, not a Prolog in memory, so it has none.
    [ "$lane" = swi-O ] && _swirate=$per
    if [ -n "$_swirate" ] && [ "$lane" != sqlite ]; then
      rels=$(awk -v p="$per" -v q="$_swirate" 'BEGIN { printf "%.1fx", (q > 0 ? p / q : 0) }')
    else
      rels=-
    fi
    dbl=$(awk -v a="$tR" -v b="$t2R" 'BEGIN { printf "%.2f", (a > 0 ? b / a : 0) }')
    printf '   %-8s %8s %7s %12s %9s %8s %7s  %s\n' "$lane" "$r" "$fix" "$per" "$rel" "$rels" "$dbl" \
      "$(arr_name "$lane")"
  done
  echo
done

echo "start-up alone, the same wall clock, nothing but boot and exit:"
for lane in $LANES; do
  case $lane in
    python)  s=$(now); "$PY" -c pass >/dev/null 2>&1; e=$(now) ;;
    swi-O)   s=$(now); "$SWI" -f none -q -O -g halt >/dev/null 2>&1; e=$(now) ;;
    swi)     s=$(now); "$SWI" -f none -q -g halt >/dev/null 2>&1; e=$(now) ;;
    local)   s=$(now); "$C" query true >/dev/null 2>&1; e=$(now) ;;
    embed)   rm -rf "$EMB"; mkdir -p "$EMB"; s=$(now); "$C" --embed "$EMB" query true >/dev/null 2>&1; e=$(now) ;;
    zigurat) s=$(now); timeout 60 "$C" $DIAL --kb "$KB" query true >/dev/null 2>&1; e=$(now) ;;
  esac
  printf '   %-8s %10s s\n' "$lane" "$(secs $((e - s)))"
done
rm -rf "$EMB"; rm -f "$DBF"
echo

# ---- and the one that is not a constant factor ------------------------
#
# `lookup' was the task where the two systems differed in KIND rather than
# in speed: SQLite's PRIMARY KEY is an index and cocolog tried clauses in
# order, so the gap was not a factor but a slope -- 8x at 200 facts, 428x
# at 20 000, in the first run of all. cocolog has a first-argument index
# now and the slope is flat. The same thousand probes still run over three
# sizes of database, in the lanes that can do it quickly, read DOWN the
# column: a return to a slope is the regression this table exists to show.
# SWI's column (`-O') is its just-in-time index on the first argument, the
# same promise.
echo "the shape of the lookup gap -- a thousand probes, three sizes:"
printf '   %8s %12s %12s %12s %10s\n' facts 'python s' 'swi-O s' 'cocolog s' ratio
for n in 200 2000 20000; do
  s=$(now); timeout $RUN_CAP "$PY" "$L/lookup.py" "$n" 20 >/dev/null 2>&1; e=$(now); pt=$((e - s))
  st=-
  case " $LANES " in *" swi-O "*)
    s=$(now); timeout $RUN_CAP "$SWI" -f none -q -O -g "main($n,20)" -t halt "$L/lookup.pl" >/dev/null 2>&1; e=$(now)
    st=$(secs $((e - s))) ;;
  esac
  s=$(now); timeout $RUN_CAP "$C" run "$L/lookup.pl" "main($n,20)" >/dev/null 2>&1; e=$(now); ct=$((e - s))
  printf '   %8s %12s %12s %12s %10s\n' "$n" "$(secs $pt)" "$st" "$(secs $ct)" \
    "$(awk -v a="$ct" -v b="$pt" 'BEGIN { printf "%.0fx", (b > 0 ? a / b : 0) }')"
done
echo
