#!/bin/sh
# Four interpreters at once, over two distinct machine states.
#
# TWO GROUPS OF TWO. Group A is two interpreter processes that take turns on
# machine `state-a'; group B is two more taking turns on `state-b'. All four run
# concurrently against one server, and each group's two members hand their
# machine back and forth through the database -- neither of them holds it for
# more than one turn, and neither group can see the other's state.
#
# WHAT IT IS ACTUALLY CHECKING, and why each part is there:
#
#   EACH STATE PRODUCES ITS FULL ANSWER SET, EXACTLY ONCE. A machine advanced
#   by two processes in turn must produce the same six answers, in the same
#   order, that one process would -- no answer repeated because a turn was
#   replayed, none missing because a save was lost.
#
#   BOTH MEMBERS OF EACH GROUP DO SOME OF THE WORK. If one worker took every
#   turn, the test would pass while proving nothing about hand-off, so the turn
#   counts are checked to be non-zero on both sides.
#
#   THE TWO GROUPS DO NOT INTERFERE. The goals differ -- one asks about tom's
#   descendants, the other about who leads to zoe -- so a state that had picked
#   up the other group's work would answer visibly wrong things.
#
# WHAT MAKES IT SAFE. cocolog::machine_claim_named marks a machine as one
# worker's inside a transaction, so two workers cannot both be advancing it;
# the loser waits and takes the next turn. Without that the two would both load
# the same state, both advance it and both save, and the second save would
# silently throw the first one's work away.
#
# NOTHING HERE IS ALLOWED TO HANG. Every step has a timeout and the workers
# have a wall clock, because the failure this test exists to catch is a worker
# BLOCKING -- on a lock, on a server that has stopped answering -- and a test
# whose failure mode is "wait forever" is useless for finding it. A run that
# goes wrong should be over in seconds and say what it was waiting for.
#
#   SETUP_TIMEOUT  each consult/start/drop/list call
#   WORKER_TIMEOUT the whole of one worker
#   SOCKET_TIMEOUT what cocolog itself waits on one socket operation

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
KB=groups_test
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-groups-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

if [ ! -x "$COCOLOG" ]; then
  echo "build first: make -C $ROOT" >&2
  exit 1
fi

HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}

SETUP_TIMEOUT=${SETUP_TIMEOUT:-20}
WORKER_TIMEOUT=${WORKER_TIMEOUT:-30}
SOCKET_TIMEOUT=${SOCKET_TIMEOUT:-5}

if ! timeout "$SETUP_TIMEOUT" "$COCOLOG" --kb "$KB" --host "$HOST" --port "$PORT" \
       --timeout "$SOCKET_TIMEOUT" list >/dev/null 2>&1; then
  echo "SKIP no Zigurat server at $HOST:$PORT"
  exit 0
fi

CL="timeout $SETUP_TIMEOUT $COCOLOG --kb $KB --host $HOST --port $PORT --timeout $SOCKET_TIMEOUT"
WORK="timeout $WORKER_TIMEOUT $COCOLOG --kb $KB --host $HOST --port $PORT --timeout $SOCKET_TIMEOUT"

# CONSULT ASSERTS, IT DOES NOT REPLACE, so a run that consulted into a
# knowledge base a previous run had already filled would leave two copies of
# every clause -- and then every proof answers everything twice and the
# recursive one never terminates. The symptom reads exactly like a broken
# interpreter, which is why this line is here and not left to whoever cleans up
# after a failed run.
echo "loading the program"
$CL forget > "$OUT/forget.log"
$CL consult "$ROOT/demo/family.pl" > "$OUT/consult.log"

# Anything left over from a previous run would be claimed by these workers.
for stale in state-a state-b; do $CL drop "$stale" >/dev/null 2>&1 || true; done

echo "starting two machines"
$CL start state-a "ancestor(tom,X)"  > "$OUT/start-a.log"
$CL start state-b "ancestor(X,zoe)"  > "$OUT/start-b.log"

echo "four interpreters, two per machine"
# --steps 8 is small on purpose: it forces each machine through several turns,
# so the two workers of a group really do have to hand it over.
#
# `set -e' is off around the workers: one that times out exits non-zero, and
# that is a result to report rather than a reason to abandon the run.
set +e
$WORK --steps 8 --answers 0 work a1 state-a > "$OUT/a1.log" 2>&1 & A1PID=$!
$WORK --steps 8 --answers 0 work a2 state-a > "$OUT/a2.log" 2>&1 & A2PID=$!
$WORK --steps 8 --answers 0 work b1 state-b > "$OUT/b1.log" 2>&1 & B1PID=$!
$WORK --steps 8 --answers 0 work b2 state-b > "$OUT/b2.log" 2>&1 & B2PID=$!

timed_out=""
for pair in "a1 $A1PID" "a2 $A2PID" "b1 $B1PID" "b2 $B2PID"; do
  set -- $pair
  if ! wait "$2"; then
    # 124 is what `timeout' exits with when it had to kill the command
    [ $? -eq 124 ] && timed_out="$timed_out $1"
  fi
done
[ -n "$timed_out" ] && echo "     TIMED OUT:$timed_out"
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

# The answers of a machine, in the order they were produced, however many
# workers produced them. The numbering restarts each turn, so it is stripped.
answers_of() {
  cat "$OUT/$1.log" "$OUT/$2.log" 2>/dev/null \
    | grep -E '^  [0-9]+\. ' | sed 's/^ *[0-9]*\. //'
}

# grep -c prints 0 AND exits non-zero when it finds nothing, so a trailing
# `|| echo 0' appends a second line rather than supplying a default.
turns_of() { grep -c ': took ' "$OUT/$1.log" 2>/dev/null | head -1; }

# Group A asked for tom's descendants. Six of them, and each exactly once --
# but the ORDER across two workers is the order the machine produced them,
# which is the thing a lost or replayed turn would disturb.
A=$(answers_of a1 a2 | sort | tr '\n' ' ' | sed 's/ *$//')
check "state-a produced its full answer set" "$A" \
  "ancestor(tom,ann) ancestor(tom,bob) ancestor(tom,jim) ancestor(tom,liz) ancestor(tom,pat) ancestor(tom,zoe)"

B=$(answers_of b1 b2 | sort | tr '\n' ' ' | sed 's/ *$//')
check "state-b produced its full answer set" "$B" \
  "ancestor(bob,zoe) ancestor(jim,zoe) ancestor(pat,zoe) ancestor(tom,zoe)"

check "state-a answered nothing twice" \
  "$(answers_of a1 a2 | sort | uniq -d | wc -l | tr -d ' ')" "0"
check "state-b answered nothing twice" \
  "$(answers_of b1 b2 | sort | uniq -d | wc -l | tr -d ' ')" "0"

# Both members of each group have to have done some of it, or the hand-off was
# never exercised and the run proves only that one worker can finish a machine.
A1=$(turns_of a1); A2=$(turns_of a2)
B1=$(turns_of b1); B2=$(turns_of b2)
echo "     turns: a1=$A1 a2=$A2 b1=$B1 b2=$B2"
check "both interpreters of group A took turns" \
  "$([ "$A1" -gt 0 ] && [ "$A2" -gt 0 ] && echo yes || echo no)" "yes"
check "both interpreters of group B took turns" \
  "$([ "$B1" -gt 0 ] && [ "$B2" -gt 0 ] && echo yes || echo no)" "yes"

# And nothing is left suspended: a machine that finished is dropped.
LEFT=$($CL list | grep -cE '^  state-' || true)
check "no machine left suspended" "$LEFT" "0"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  for w in a1 a2 b1 b2; do echo "--- $w ---"; cat "$OUT/$w.log"; done
  exit 1
fi
