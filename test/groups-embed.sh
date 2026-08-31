#!/bin/sh
# The twelve-interpreter group test, EMBEDDED: the same four groups of
# three over the same four machine states as test/groups.sh, with the
# knowledge base inside the process instead of behind a server.
#
# WHAT CHANGES AND WHY. An embedded store belongs to one process at a
# time, so the arrangement differs from groups.sh in exactly two ways:
#
#   THE MACHINES START FIRST. groups.sh starts its workers first because
#   twelve processes take long enough to launch that early ones finished
#   machines before late ones existed. Here the setup steps are still one
#   process each (open store, do the thing, close), but the WORKERS are
#   twelve THREADS of a single `cocolog swarm' process -- and that process
#   cannot share the store with a concurrent `start'. So: state first,
#   then the swarm. The workers' claim logic is indifferent to the order.
#
#   ONE `swarm' INSTEAD OF TWELVE `work's. Each thread opens its own
#   embedded session and runs the very same work loop the processes run,
#   writing to --out DIR/WORKER.log so the checks below read the same
#   logs groups.sh reads.
#
# Everything checked is checked identically: full answer set exactly
# once per machine, and every member of every group took a turn.

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
KB=groups_test
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-groups-embed-XXXXXX")
# A fresh store by default; GROUPS_EMBED_STORE names a persistent one, for
# measuring what repeated runs do to a store that lives on -- it survives
# the run, only the logs are cleaned up.
STORE="${GROUPS_EMBED_STORE:-$OUT/store}"
trap 'rm -rf "$OUT"' EXIT INT TERM

if [ ! -x "$COCOLOG" ]; then
  echo "build first: make -C $ROOT embed" >&2
  exit 1
fi

SETUP_TIMEOUT=${SETUP_TIMEOUT:-20}
WORKER_TIMEOUT=${WORKER_TIMEOUT:-60}

# How many turns a group must take before "all three took turns" is a claim
# about the scheduler rather than a coin toss -- test/groups.sh carries the
# arithmetic. 20 is 0.09% per group; the four groups measure well above it.
TURNS_FLOOR=${TURNS_FLOOR:-20}

CL="timeout $SETUP_TIMEOUT $COCOLOG --kb $KB --embed $STORE"

# NOT `GROUPS' -- readonly in bash-as-sh; see groups.sh.
GROUPSET="a b c d"
MEMBERS="1 2 3"

goal_of() {
  case $1 in
    a) echo "ancestor(tom,X)" ;;
    b) echo "ancestor(bob,X)" ;;
    c) echo "ancestor(X,zoe)" ;;
    d) echo "ancestor(X,jim)" ;;
  esac
}

answers_wanted() {
  case $1 in
    a) echo "ancestor(tom,ann) ancestor(tom,bob) ancestor(tom,jim) ancestor(tom,liz) ancestor(tom,pat) ancestor(tom,zoe)" ;;
    b) echo "ancestor(bob,ann) ancestor(bob,jim) ancestor(bob,pat) ancestor(bob,zoe)" ;;
    c) echo "ancestor(bob,zoe) ancestor(jim,zoe) ancestor(pat,zoe) ancestor(tom,zoe)" ;;
    d) echo "ancestor(bob,jim) ancestor(pat,jim) ancestor(tom,jim)" ;;
  esac
}

echo "loading the program"
$CL forget > "$OUT/forget.log"
# AND RECLAIM WHAT THE LAST RUN LEFT -- see the same line in test/groups.sh.
# The embedded engine keeps deleted rows under MVCC exactly as the server
# does, and a persistent store ages exactly as the server's did: measured
# here, 25s, 50s, and then past the 60s WORKER_TIMEOUT by the third run.
# On the default fresh store this is a no-op that costs nothing.
$CL vacuum > "$OUT/vacuum.log"
$CL consult "$ROOT/demo/family.pl" > "$OUT/consult.log"

echo "starting four machines"
for g in $GROUPSET; do
  $CL start "state-$g" "$(goal_of $g)" > "$OUT/start-$g.log"
done

echo "twelve interpreters, three per machine, as threads of one process"
PAIRS=""
for g in $GROUPSET; do
  for m in $MEMBERS; do PAIRS="$PAIRS $g$m state-$g"; done
done
set +e
# --steps 1, and TURNS_FLOOR below, for the reason test/groups.sh writes out
# at length: the share check is a claim about the scheduler only when there
# are enough turns to split. This case is not in the suite's list, so it was
# never seen to flake, and more turns can only help it.
#
# BUT THE ARITHMETIC OVER THERE DOES NOT APPLY HERE, and saying so is the
# point of this note. groups.sh's twelve PROCESSES split their machine's
# turns fairly -- measured over sixteen runs, the smallest share sat at or
# above what a fair three-way split predicts -- so more turns is a real fix
# there. THE SWARM'S TWELVE THREADS DO NOT. Five runs of this case, at the
# --steps 1 below:
#
#   c1=6  c2=5  c3=51        d1=6  d2=17 d3=38
#   c1=3  c2=24 c3=35        d1=12 d2=35 d3=14
#   c1=2  c2=59 c3=1         d1=4  d2=51 d3=6
#   c1=1  c2=6  c3=55        d1=53 d2=1  d3=7
#   c1=3  c2=1  c3=58        d1=52 d2=3  d3=6
#
# One thread of three taking 59 turns of 62 is not a fair split by any
# reading, and a minimum of 1 recurs. So the share check here is still
# fragile -- a run that lands on 0 is possible in a way it is not in
# groups.sh -- and the cause is the swarm's own hand-off, not the number of
# turns. THAT IS A FINDING RECORDED HERE AND NOT FIXED: it wants the yield
# between threads looked at, and it is a different piece of work from the
# flake in groups.sh that this change was made for.
timeout "$WORKER_TIMEOUT" $COCOLOG --kb $KB --embed "$STORE" \
  --steps 1 --answers 0 --out "$OUT" swarm $PAIRS
swarm_rc=$?
[ "$swarm_rc" -eq 124 ] && echo "     TIMED OUT: the swarm"
set -e

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-46s %s\n' "$1" "$2"
  else
    printf 'FAIL %-46s got [%s] want [%s]\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

answers_of() {
  g=$1
  cat "$OUT/$g"1.log "$OUT/$g"2.log "$OUT/$g"3.log 2>/dev/null \
    | grep -E '^  [0-9]+\. ' | sed 's/^ *[0-9]*\. //'
}

turns_of() { grep -c ': took ' "$OUT/$1.log" 2>/dev/null | head -1; }

for g in $GROUPSET; do
  got=$(answers_of "$g" | sort | tr '\n' ' ' | sed 's/ *$//')
  check "state-$g produced its full answer set" "$got" "$(answers_wanted $g)"
  check "state-$g answered nothing twice" \
    "$(answers_of "$g" | sort | uniq -d | wc -l | tr -d ' ')" "0"
done

for g in $GROUPSET; do
  line=""
  shared=yes
  total=0
  for m in $MEMBERS; do
    n=$(turns_of "$g$m")
    line="$line $g$m=$n"
    total=$((total + n))
    [ "$n" -gt 0 ] || shared=no
  done
  echo "     turns:$line  (total $total)"
  check "group $g did enough turns to be worth splitting" \
    "$([ "$total" -ge "$TURNS_FLOOR" ] && echo yes || echo "no: $total < $TURNS_FLOOR")" \
    "yes"
  check "all three interpreters of group $g took turns" "$shared" "yes"
done

LEFT=$($CL list | grep -cE '^  state-' || true)
check "no machine left suspended" "$LEFT" "0"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  for g in $GROUPSET; do
    for m in $MEMBERS; do echo "--- $g$m ---"; cat "$OUT/$g$m.log"; done
  done
  exit 1
fi
