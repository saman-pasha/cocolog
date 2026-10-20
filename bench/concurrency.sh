#!/bin/sh
# Real threads, green threads, goroutines, Rust threads and coroutines, the same spin/1
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
#   rust        N std::threads: an OS thread each, as the real lane.
#   python      N asyncio tasks (when python3 is).
#
# THE LIGHT LANES (LIGHT_N tasks each doing true, joined):
#
#   light-real / light-green / light-goroutine / light-rust / light-python
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
# nothing. That is the model the benchmark measures. The Rust light lanes
# take OS_LIGHT_N too: std::thread is one OS thread a task.
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
STORE_N=${STORE_N:-$N}
STORE_K=${STORE_K:-10000}
STORE_M=${STORE_M:-20000}
ZIGURAT_HOST=${ZIGURAT_HOST:-127.0.0.1}
ZIGURAT_PORT=${ZIGURAT_PORT:-2160}
STORE_KB=${STORE_KB:-bench_concurrency}
STORE_DIAL="--kb $STORE_KB --host $ZIGURAT_HOST --tcp $ZIGURAT_PORT --timeout 120"

# THE SERVER LANE WANTS A timeout(1); a stock Mac has none, and perl's
# alarm survives exec (bench/langs.sh's fallback, the same).
if ! command -v timeout >/dev/null 2>&1; then
    if command -v gtimeout >/dev/null 2>&1; then
        timeout() { gtimeout "$@"; }
    else
        timeout() { _t=$1; shift; perl -e 'alarm shift; exec @ARGV or die "exec: $!"' "$_t" "$@"; }
    fi
fi
HAVE_STORE=
if timeout 20 "$COCO" $STORE_DIAL list >/dev/null 2>&1; then
    HAVE_STORE=1
fi

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

# THE GO BINARIES ARE BUILT ONCE, before any timing.
GOBIN=
GO_STORE=
if command -v go >/dev/null 2>&1; then
    GOBIN=${TMPDIR:-/tmp}/cocolog-concurrency-go.$$
    if ! go build -o "$GOBIN" bench/concurrency.go >/dev/null 2>&1; then
        GOBIN=
    fi
    GO_STORE=${TMPDIR:-/tmp}/cocolog-concurrency-sqlite.$$
    if ! go build -o "$GO_STORE" bench/concurrency_store.go >/dev/null 2>&1; then
        GO_STORE=
    fi
fi
STORE_DIR=${TMPDIR:-/tmp}/cocolog-concurrency-store.$$
STORE_DB=$STORE_DIR/f.sqlite3
STORE_EMB=$STORE_DIR/embed
# THE RUST BINARY is built once too, release mode: rustc -O, the check
# release optimization level.
RUSTBIN=
if command -v rustc >/dev/null 2>&1; then
    RUSTBIN=${TMPDIR:-/tmp}/cocolog-concurrency-rust.$$
    if ! rustc -O -o "$RUSTBIN" bench/concurrency.rs >/dev/null 2>&1; then
        RUSTBIN=
    fi
fi
cleanup() {
    if [ -n "$GOBIN" ]; then rm -f "$GOBIN"; fi
    if [ -n "$GO_STORE" ]; then rm -f "$GO_STORE"; fi
    if [ -n "$RUSTBIN" ]; then rm -f "$RUSTBIN"; fi
    rm -rf "$STORE_DIR"
}
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
if [ -n "$RUSTBIN" ]; then
    lane rust 0 "$RUSTBIN" work "$N" "$M"
else
    printf '%-15s SKIP (no rust)\n' rust
fi
if command -v "$PY" >/dev/null 2>&1; then
    lane python 0 "$PY" bench/concurrency.py work "$N" "$M"
else
    printf '%-15s SKIP (no python3)\n' python
fi

# ---- the store lanes: goroutines over SQLite against green over --embed -
#
# The store lanes of bench/langs.sh, in the world: K keyed rows, then M
# probes by each of N units at once. SQLite's is a file with a PRIMARY
# KEY, committed at the build; cocolog's is the MVCCS engine linked in
# (--embed), the rows asserted once and read by every task from the one
# store (2.9.0) with no lock. The store and the file are RESET outside
# the timed region, as langs.sh does, and the process that seeds and
# probes is the timed one: both sides pay their build.
mkdir -p "$STORE_DIR"
store_lane() {
    _name=$1
    _kind=$2
    _units=$3
    _best=
    _i=0
    while [ "$_i" -lt "$REPS" ]; do
        _i=$((_i + 1))
        rm -rf "$STORE_EMB" "$STORE_DB"
        mkdir -p "$STORE_EMB"
        case "$_kind" in
            sqlite) "$GO_STORE" build "$STORE_DB" "$STORE_K" >/dev/null 2>&1 || true ;;
            green)  "$COCO" --embed "$STORE_EMB" -s "$ROOT/bench/concurrency.pl" \
                        -- store_seed "$STORE_K" >/dev/null 2>&1 || true ;;
            zigurat)
                "$COCO" $STORE_DIAL forget >/dev/null 2>&1 || true
                "$COCO" $STORE_DIAL run "$ROOT/bench/concurrency.pl" \
                    "store_build($STORE_K)" >/dev/null 2>&1 || true ;;
        esac
        _t0=$(now)
        case "$_kind" in
            sqlite) _out=$("$GO_STORE" store "$STORE_DB" "$STORE_N" "$STORE_K" "$STORE_M" 2>&1) || true ;;
            green)  _out=$("$COCO" --embed "$STORE_EMB" -s "$ROOT/bench/concurrency.pl" \
                               -- store_run "$STORE_N" "$STORE_K" "$STORE_M" 2>&1) || true ;;
            zigurat) _out=$("$COCO" $STORE_DIAL -s "$ROOT/bench/concurrency.pl" \
                                -- store_run "$STORE_N" "$STORE_K" "$STORE_M" 2>&1) || true ;;
        esac
        _t1=$(now)
        case "$_out" in
            *"answer(done)"*) ;;
            *) printf '%-15s REFUSED: %s\n' "$_name" "$(printf '%s' "$_out" | head -1)"; return 0 ;;
        esac
        _dt=$((_t1 - _t0))
        if [ -z "$_best" ] || [ "$_dt" -lt "$_best" ]; then
            _best=$_dt
        fi
    done
    _ms=$(awk "BEGIN { printf \"%.1f\", $_best / 1000000 }")
    _us=$(awk "BEGIN { printf \"%.2f\", $_best / ($_units * 1000) }")
    printf '%-15s %10s ms %10s us/lookup\n' "$_name" "$_ms" "$_us"
}

printf '\nstore: %s units x %s keyed lookups over %s rows\n' "$STORE_N" "$STORE_M" "$STORE_K"
printf '%-15s %10s %14s\n' lane wall per-lookup
if [ -n "$GO_STORE" ]; then
    store_lane store-sqlite sqlite $((STORE_N * STORE_M))
else
    printf '%-15s SKIP (no go with cgo and libsqlite3)\n' store-sqlite
fi
store_lane store-green green $((STORE_N * STORE_M))
if [ -n "$HAVE_STORE" ]; then
    store_lane store-zigurat zigurat $((STORE_N * STORE_M))
else
    printf '%-15s SKIP (no server at %s:%s)\n' store-zigurat "$ZIGURAT_HOST" "$ZIGURAT_PORT"
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
if [ -n "$RUSTBIN" ]; then
    lane light-rust "$OS_LIGHT_N" "$RUSTBIN" light "$OS_LIGHT_N"
else
    printf '%-15s SKIP (no rust)\n' light-rust
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
if [ -n "$RUSTBIN" ]; then
    lane light-y-rust "$_y_real" "$RUSTBIN" lightyield "$OS_LIGHT_N" "$LIGHT_YIELDS"
else
    printf '%-15s SKIP (no rust)\n' light-y-rust
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
