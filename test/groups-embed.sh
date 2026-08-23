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
COCOLOG="$ROOT/cocolog-embed"
KB=groups_test
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-groups-embed-XXXXXX")
STORE="$OUT/store"
trap 'rm -rf "$OUT"' EXIT INT TERM

if [ ! -x "$COCOLOG" ]; then
  echo "build first: make -C $ROOT embed" >&2
  exit 1
fi

SETUP_TIMEOUT=${SETUP_TIMEOUT:-20}
WORKER_TIMEOUT=${WORKER_TIMEOUT:-60}

CL="timeout $SETUP_TIMEOUT $COCOLOG --kb $KB --store $STORE"

GROUPS="a b c d"
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
$CL consult "$ROOT/demo/family.pl" > "$OUT/consult.log"

echo "starting four machines"
for g in $GROUPS; do
  $CL start "state-$g" "$(goal_of $g)" > "$OUT/start-$g.log"
done

echo "twelve interpreters, three per machine, as threads of one process"
PAIRS=""
for g in $GROUPS; do
  for m in $MEMBERS; do PAIRS="$PAIRS $g$m state-$g"; done
done
set +e
timeout "$WORKER_TIMEOUT" $COCOLOG --kb $KB --store "$STORE" \
  --steps 2 --answers 0 --out "$OUT" swarm $PAIRS
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

for g in $GROUPS; do
  got=$(answers_of "$g" | sort | tr '\n' ' ' | sed 's/ *$//')
  check "state-$g produced its full answer set" "$got" "$(answers_wanted $g)"
  check "state-$g answered nothing twice" \
    "$(answers_of "$g" | sort | uniq -d | wc -l | tr -d ' ')" "0"
done

for g in $GROUPS; do
  line=""
  shared=yes
  for m in $MEMBERS; do
    n=$(turns_of "$g$m")
    line="$line $g$m=$n"
    [ "$n" -gt 0 ] || shared=no
  done
  echo "     turns:$line"
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
  for g in $GROUPS; do
    for m in $MEMBERS; do echo "--- $g$m ---"; cat "$OUT/$g$m.log"; done
  done
  exit 1
fi
