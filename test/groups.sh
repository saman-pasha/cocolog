#!/bin/sh
# Twelve interpreters at once, over four distinct machine states.
#
# FOUR GROUPS OF THREE. Each group is three interpreter processes taking turns
# on one machine; the four groups run at the same time against one server, and
# each group's members hand their machine back and forth through the database --
# nobody holds it for more than one turn, and no group can see another's state.
#
# WHAT IT IS ACTUALLY CHECKING, and why each part is there:
#
#   EACH STATE PRODUCES ITS FULL ANSWER SET, EXACTLY ONCE. A machine advanced by
#   three processes in turn must produce the same answers one process would --
#   none repeated because a turn was replayed, none missing because a save was
#   lost.
#
#   EVERY MEMBER OF EVERY GROUP DOES SOME OF THE WORK. If one worker took every
#   turn the test would pass while proving nothing about hand-off, so all three
#   turn counts are checked to be non-zero.
#
#   THE FOUR GROUPS DO NOT INTERFERE. The goals differ -- tom's descendants,
#   bob's descendants, who leads to zoe, who leads to jim -- and they OVERLAP in
#   the answers they can produce, so a state that had picked up another group's
#   work answers visibly wrong things rather than plausibly wrong ones.
#
# WHAT MAKES IT SAFE. Two things, in two different projects:
#
#   cocolog::machine_claim_named marks a machine as one worker's inside a
#   transaction, so two workers cannot both be advancing it; the losers wait and
#   take a later turn. Without it they would all load the same state, all
#   advance it, and the last save would throw the others' work away.
#
#   ZiguratIP serialises the two page-store streams that every connection's
#   thread shares. It did not always: an indexed WHERE walked a B-tree straight
#   through them holding no lock at all, so several clients reading and writing
#   at once read from each other's file position. See STATUS.md.
#
# NOTHING HERE IS ALLOWED TO HANG. Every step has a timeout and the workers have
# a wall clock, because the failure this test exists to catch is a worker
# BLOCKING -- on a lock, on a server that has stopped answering -- and a test
# whose failure mode is "wait forever" is useless for finding it. A run that goes
# wrong should be over in seconds and say what it was waiting for.
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
WORKER_TIMEOUT=${WORKER_TIMEOUT:-60}
SOCKET_TIMEOUT=${SOCKET_TIMEOUT:-10}

# How many turns a group must take before "all three took turns" is a claim
# about the scheduler rather than a coin toss. See the --steps note below: a
# fair split of N turns three ways starves somebody about 3*(2/3)^N of the
# time, so 20 is 0.09% per group and the four groups measure 34, 24, 60 and 60.
TURNS_FLOOR=${TURNS_FLOOR:-20}

if ! timeout "$SETUP_TIMEOUT" "$COCOLOG" --kb "$KB" --host "$HOST" --tcp "$PORT" \
       --timeout "$SOCKET_TIMEOUT" list >/dev/null 2>&1; then
  echo "SKIP no Zigurat server at $HOST:$PORT"
  exit 0
fi

CL="timeout $SETUP_TIMEOUT $COCOLOG --kb $KB --host $HOST --tcp $PORT --timeout $SOCKET_TIMEOUT"
WORK="timeout $WORKER_TIMEOUT $COCOLOG --kb $KB --host $HOST --tcp $PORT --timeout $SOCKET_TIMEOUT"

# The four groups, each with its goal and the answer set that goal must produce.
# Kept here rather than spread through the file, so that adding a fifth group is
# two lines.
# NOT `GROUPS': bash -- which is what macOS runs as /bin/sh -- makes
# GROUPS a readonly special array, the assignment dies, and under set -e
# the case exits before its first echo, printing NOTHING at all.
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

# CONSULT ASSERTS, IT DOES NOT REPLACE, so a run that consulted into a knowledge
# base a previous run had already filled would leave two copies of every clause
# -- and then every proof answers everything twice and the recursive one never
# terminates. The symptom reads exactly like a broken interpreter, which is why
# this line is here and not left to whoever cleans up after a failed run.
echo "loading the program"
$CL forget > "$OUT/forget.log"
# AND RECLAIM WHAT THE LAST RUN LEFT. `forget' deletes rows; under MVCC a
# deleted row is kept so that a transaction entitled to an earlier view can
# still read it, and nothing takes it away afterwards. Saving a machine rewrites
# its row, so one proof of thirty turns leaves twenty-nine dead ones -- and this
# suite runs twelve of them. Without this line the store grows by every run that
# has ever happened and every read walks past all of it: the same twelve
# interpreters took 12 seconds against an empty store and 60 against one a few
# hundred runs had been through, which is how this test came to fail on its
# WORKER_TIMEOUT with nothing wrong anywhere.
$CL vacuum > "$OUT/vacuum.log"
$CL consult "$ROOT/demo/family.pl" > "$OUT/consult.log"

# Anything left over from a previous run would be claimed by these workers.
for g in $GROUPSET; do $CL drop "state-$g" >/dev/null 2>&1 || true; done

echo "twelve interpreters, three per machine"
# THE WORKERS GO UP BEFORE THE WORK DOES, and that is not a nicety. Starting
# twelve processes takes long enough -- fork, exec, connect, hand-shake -- that
# the first few were finishing a machine before the last few were running, and a
# worker that arrives after its machine is gone can only report that there was
# nothing to do. Then the run passes every check about ANSWERS and fails the one
# that asks whether the group actually shared, which is the check the whole
# arrangement exists for. `cocolog work' waits for a machine it has never seen,
# so the honest order is: everybody up, then the work.
#
# --steps 1 is the smallest turn there is, and the size of the turn is what
# decides whether "all three took turns" is a claim about the scheduler or a
# coin toss. THAT DISTINCTION COST THIS CASE ITS ONLY FLAKE, so the arithmetic
# is written out rather than left as a feeling.
#
# The scheduler hands a released machine to whichever partner polls first,
# which over a whole run is a FAIR RANDOM SPLIT -- and it measured fair:
# sixteen runs put the smallest share of each group at or slightly above what
# a fair three-way split of the same number of turns predicts. A fair split of
# N turns among three workers leaves one of them with NONE about 3*(2/3)^N of
# the time, and that is not a bug to fix in the interpreter; it is a property
# of splitting a small number of turns three ways.
#
# At --steps 2 the four groups took 17, 12, 30 and 30 turns -- and 3*(2/3)^12
# is 2.3%, so group b alone failed about one run in forty. That is exactly the
# rate this case was flaking at. --steps 1 doubles every group's turn count for
# about 0.9s of wall clock, and TURNS_FLOOR below turns the premise into a
# checked precondition instead of an assumption, so a future change that makes
# the work smaller fails saying so rather than flaking a fortnight later.
#
# `set -e' is off around the workers: one that times out exits non-zero, and
# that is a result to report rather than a reason to abandon the run.
set +e
pids=""
for g in $GROUPSET; do
  for m in $MEMBERS; do
    $WORK --steps 1 --answers 0 work "$g$m" "state-$g" > "$OUT/$g$m.log" 2>&1 &
    pids="$pids $g$m:$!"
  done
done

echo "starting four machines"
for g in $GROUPSET; do
  $CL start "state-$g" "$(goal_of $g)" > "$OUT/start-$g.log"
done

timed_out=""
for pair in $pids; do
  w=${pair%%:*}; p=${pair##*:}
  if ! wait "$p"; then
    # 124 is what `timeout' exits with when it had to kill the command
    [ $? -eq 124 ] && timed_out="$timed_out $w"
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

# The answers of a machine, however many of its workers produced them. The
# numbering restarts each turn, so it is stripped.
answers_of() {
  g=$1
  cat "$OUT/$g"1.log "$OUT/$g"2.log "$OUT/$g"3.log 2>/dev/null \
    | grep -E '^  [0-9]+\. ' | sed 's/^ *[0-9]*\. //'
}

# grep -c prints 0 AND exits non-zero when it finds nothing, so a trailing
# `|| echo 0' appends a second line rather than supplying a default.
turns_of() { grep -c ': took ' "$OUT/$1.log" 2>/dev/null | head -1; }

for g in $GROUPSET; do
  got=$(answers_of "$g" | sort | tr '\n' ' ' | sed 's/ *$//')
  check "state-$g produced its full answer set" "$got" "$(answers_wanted $g)"
  check "state-$g answered nothing twice" \
    "$(answers_of "$g" | sort | uniq -d | wc -l | tr -d ' ')" "0"
done

# Every member of every group has to have done some of it, or the hand-off was
# never exercised and the run proves only that one worker can finish a machine.
#
# AND THE PREMISE IS CHECKED FIRST, because it is the premise that broke. The
# share check is only meaningful over enough turns: a fair three-way split of N
# leaves somebody with none about 3*(2/3)^N of the time, which at TURNS_FLOOR
# is under a tenth of a percent per group and at the twelve turns this case
# used to give group b was one run in forty. So the total is checked as well as
# the split, and a change that shrinks the work -- a smaller program, a bigger
# --steps, a faster proof -- fails HERE, naming the number, instead of turning
# back into an occasional red nobody can reproduce.
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

# And nothing is left suspended: a machine that finished is dropped.
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
