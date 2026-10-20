#!/bin/sh
# Real threads, green threads, goroutines and coroutines, the same spin/1
# work -- and the light lanes: many short tasks, then the same with a yield
# each round, where creation and switch cost is the question.
#
#     sh bench/concurrency.sh                 from the checkout root, after `make'
#     N=8 M=1000000 REPS=3 sh bench/concurrency.sh
#     LIGHT_N=10000 OS_LIGHT_N=1000 LIGHT_YIELDS=100 sh bench/concurrency.sh
#
# THE WORK LANES (N units, M steps each):
#
#   serial      one thread, N units in a row -- the baseline.
#   real        N threads of library(thread): an OS thread each, free to use
#               N cores.
#   green       N green threads of library(async): one process, a world of
#               eight workers (the caller and seven OS threads), tasks pinned
#               to a worker and preempted at a 10,000-step quantum.
#   goroutine   N Go goroutines: Go's runtime schedules them M:N over the OS
#               threads, so this lane may use the cores.
#   python      N asyncio tasks (when python3 is).
#
# THE LIGHT LANES (LIGHT_N tasks each doing true, joined):
#
#   light-real / light-green / light-goroutine / light-python
#   light-y-*  the same, each task yielding LIGHT_YIELDS times (a mutex
#               handoff for the OS threads, yield/0 for green, Gosched for
#               Go, sleep(0) for asyncio)
#
# The OS-thread light lanes use OS_LIGHT_N (default 1000), not LIGHT_N: a
# cocolog thread carries a machine and a store, and 10,000 of them is past
# what this Mac's user-process limit (2784) will start. A green world holds
# 1024 tasks and 64 channels, so its light lane runs in batches of 1023
# children plus the main, each batch one async_run -- the world's eight
# workers clone the caller's store once, and a spawn after that copies
# nothing. That is the model the benchmark measures.
#
# THE ONE-CORE LANE: real1 is the real-thread work lane under `taskset -c 0`
# (Linux), the like-for-like scheduler comparison with green. A Mac has no
# taskset and says SKIP.
#
# EVERY LANE is answer-gated: it must print answer(done). The first run of
# each is the warm-up; the minimum of REPS is printed. For the light lanes
# the per-task (or per-yield) cost is printed as well, because their N
# differs by lane for the reasons above.

set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
COCO="$ROOT/cocolog"

N=${N:-8}
M=${M:-1000000}
REPS=${REPS:-3}
LIGHT_N=${LIGHT_N:-10000}
OS_LIGHT_N=${OS_LIGHT_N:-1000}
LIGHT_YIELDS=${LIGHT_YIELDS:-10}

# the nanosecond clock: date where it has one, perl where it does not
if date +%N 2>/dev/null | grep -q '^[0-9]'; then
    now() { date +%s%N; }
elif command -v gdate >/dev/null 2>&1; then
    now() { gdate +%s%N; }
else
    now() { perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1e9'; }
fi

cpus=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo '?')

# THE PYENV SHIM IS NOT PYTHON (bench/langs.sh says why): resolve the
# name first, then look through a shim to the interpreter behind it.
PY=${PYTHON:-python3}
_pypath=$(command -v "$PY" 2>/dev/null || true)
case "$_pypath" in
    */.pyenv/shims/*) PY=$(pyenv which "$PY" 2>/dev/null || echo "$PY") ;;
    ?*) PY=$_pypath ;;
esac

# THE GO BINARY IS BUILT ONCE, before any timing.
GOBIN=
if command -v go >/dev/null 2>&1; then
    GOBIN=${TMPDIR:-/tmp}/cocolog-concurrency-go.$$
    if ! go build -o "$GOBIN" bench/concurrency.go >/dev/null 2>&1; then
        GOBIN=
    fi
fi
cleanup() { if [ -n "$GOBIN" ]; then rm -f "$GOBIN"; fi; }
trap cleanup EXIT

# one timed run of a lane, its output kept for the gate
lane_run() {
    shift   # the warm/timed label
    _out=$("$@" 2>&1) || true
    printf '%s\n' "$_out"
}

# lane NAME UNITS COMMAND...   (UNITS 0: print the wall only; else per unit)
lane() {
    _name=$1
    _units=$2
    shift 2
    _warm=$(lane_run warm "$@")
    case "$_warm" in
        *"answer(done)"*) ;;
        *) printf '%-15s REFUSED: %s\n' "$_name" "$(printf '%s' "$_warm" | head -1)"; return 0 ;;
    esac
    _best=
    _i=0
    while [ "$_i" -lt "$REPS" ]; do
        _i=$((_i + 1))
        _t0=$(now)
        _out=$(lane_run timed "$@")
        _t1=$(now)
        case "$_out" in
            *"answer(done)"*) ;;
            *) printf '%-15s REFUSED on a timed run\n' "$_name"; return 0 ;;
        esac
        _dt=$((_t1 - _t0))
        if [ -z "$_best" ] || [ "$_dt" -lt "$_best" ]; then
            _best=$_dt
        fi
    done
    _ms=$(awk "BEGIN { printf \"%.1f\", $_best / 1000000 }")
    if [ "$_units" -gt 0 ]; then
        _us=$(awk "BEGIN { printf \"%.2f\", $_best / ($_units * 1000) }")
        printf '%-15s %10s ms %10s us/unit\n' "$_name" "$_ms" "$_us"
    else
        printf '%-15s %10s ms\n' "$_name" "$_ms"
    fi
}

printf 'concurrency benchmark: %s cores; work N=%s M=%s; light N=%s (OS %s), yields %s\n\n' \
       "$cpus" "$N" "$M" "$LIGHT_N" "$OS_LIGHT_N" "$LIGHT_YIELDS"
printf '%-15s %10s\n' lane wall
lane serial    0 "$COCO" -s bench/concurrency.pl -- serial "$N" "$M"
lane real      0 "$COCO" -s bench/concurrency.pl -- real   "$N" "$M"
lane green     0 "$COCO" -s bench/concurrency.pl -- green  "$N" "$M"
if [ -n "$GOBIN" ]; then
    lane goroutine 0 "$GOBIN" work "$N" "$M"
else
    printf '%-15s SKIP (no go)\n' goroutine
fi
if command -v "$PY" >/dev/null 2>&1; then
    lane python 0 "$PY" bench/concurrency.py work "$N" "$M"
else
    printf '%-15s SKIP (no python3)\n' python
fi

printf '\nlight: %s tasks (OS threads %s), each true, joined\n' "$LIGHT_N" "$OS_LIGHT_N"
printf '%-15s %10s %14s\n' lane wall per-task
lane light-real      "$OS_LIGHT_N" "$COCO" -s bench/concurrency.pl -- light_real "$OS_LIGHT_N"
lane light-green     "$LIGHT_N"    "$COCO" -s bench/concurrency.pl -- light_green "$LIGHT_N"
if [ -n "$GOBIN" ]; then
    lane light-goroutine "$LIGHT_N" "$GOBIN" light "$LIGHT_N"
else
    printf '%-15s SKIP (no go)\n' light-goroutine
fi
if command -v "$PY" >/dev/null 2>&1; then
    lane light-python "$LIGHT_N" "$PY" bench/concurrency.py light "$LIGHT_N"
else
    printf '%-15s SKIP (no python3)\n' light-python
fi

printf '\nlight + yield: %s tasks (OS threads %s) x %s yields\n' "$LIGHT_N" "$OS_LIGHT_N" "$LIGHT_YIELDS"
printf '%-15s %10s %14s\n' lane wall per-yield
_y_real=$((OS_LIGHT_N * LIGHT_YIELDS))
_y_green=$((LIGHT_N * LIGHT_YIELDS))
lane light-y-real    "$_y_real"  "$COCO" -s bench/concurrency.pl -- light_real_yield "$OS_LIGHT_N" "$LIGHT_YIELDS"
lane light-y-green   "$_y_green" "$COCO" -s bench/concurrency.pl -- light_green_yield "$LIGHT_N" "$LIGHT_YIELDS"
if [ -n "$GOBIN" ]; then
    lane light-y-goroutine "$_y_green" "$GOBIN" lightyield "$LIGHT_N" "$LIGHT_YIELDS"
else
    printf '%-15s SKIP (no go)\n' light-y-goroutine
fi
if command -v "$PY" >/dev/null 2>&1; then
    lane light-y-python "$_y_green" "$PY" bench/concurrency.py lightyield "$LIGHT_N" "$LIGHT_YIELDS"
else
    printf '%-15s SKIP (no python3)\n' light-y-python
fi

printf '\none core: the real work lane under taskset -c 0\n'
if command -v taskset >/dev/null 2>&1; then
    lane real1 0 taskset -c 0 "$COCO" -s bench/concurrency.pl -- real "$N" "$M"
else
    printf '%-15s SKIP (no taskset on this system)\n' real1
fi
