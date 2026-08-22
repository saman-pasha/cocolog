#!/bin/sh
# One interpreter writes the program; eight others read it while it does.
#
# THE OTHER HALF OF THE CLAIM. test/groups.sh is many interpreters sharing
# machine STATE. This is many interpreters sharing the KNOWLEDGE BASE: a ruler
# process asserts facts and rules one at a time, and eight querier processes ask
# questions of the same knowledge base at the same time, against the same
# server, with no coordination beyond the database itself.
#
# WHAT IT IS CHECKING, and why each part is there:
#
#   A QUERIER NEVER SEES A HALF-WRITTEN PROGRAM. Every answer a querier gives
#   has to be an answer the finished program would also give. A rule asserted
#   before the facts it needs is not wrong -- it just proves nothing yet -- so
#   the check is one-sided on purpose: no answer may ever be OUTSIDE the final
#   answer set. Anything else means a querier read a clause that was never
#   committed, or read half of one.
#
#   THE PROGRAM REALLY IS BEING WRITTEN WHILE THEY READ. The ruler asserts with
#   a pause between clauses, so the queriers span the whole of it rather than
#   all arriving after the last write. The count of clauses seen has to GROW
#   across the run, or the queriers were only ever reading a finished program
#   and the test proves nothing about concurrency.
#
#   AND AT THE END EVERYONE AGREES. Once the ruler has finished, a fresh query
#   must produce the complete answer set -- so nothing was lost by being written
#   under contention.
#
# WHY IT IS A DIFFERENT SHAPE OF LOAD FROM groups.sh. The queriers do not claim
# anything and never write, so this is one writer against eight readers of the
# same rows -- the case where a reader can catch a row mid-rewrite, and where an
# indexed lookup and an index update run at the same moment.

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
KB=ruler_test
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-ruler-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

if [ ! -x "$COCOLOG" ]; then
  echo "build first: make -C $ROOT" >&2
  exit 1
fi

HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
SETUP_TIMEOUT=${SETUP_TIMEOUT:-20}
QUERIER_TIMEOUT=${QUERIER_TIMEOUT:-60}
SOCKET_TIMEOUT=${SOCKET_TIMEOUT:-10}
QUERIERS=${QUERIERS:-8}

if ! timeout "$SETUP_TIMEOUT" "$COCOLOG" --kb "$KB" --host "$HOST" --port "$PORT" \
       --timeout "$SOCKET_TIMEOUT" list >/dev/null 2>&1; then
  echo "SKIP no Zigurat server at $HOST:$PORT"
  exit 0
fi

CL="timeout $SETUP_TIMEOUT $COCOLOG --kb $KB --host $HOST --port $PORT --timeout $SOCKET_TIMEOUT"
QY="timeout $QUERIER_TIMEOUT $COCOLOG --kb $KB --host $HOST --port $PORT --timeout $SOCKET_TIMEOUT"

# The program, one clause per line, in the order the ruler asserts it. The rules
# come FIRST and the facts after, so that for most of the run there are rules
# whose facts have not arrived -- which is the state a querier must handle by
# proving nothing rather than by proving something wrong.
cat > "$OUT/program" <<'EOF'
ancestor(X,Y) :- parent(X,Y).
ancestor(X,Y) :- parent(X,Z), ancestor(Z,Y).
parent(tom,bob).
parent(tom,liz).
parent(bob,ann).
parent(bob,pat).
parent(pat,jim).
parent(jim,zoe).
EOF

CLAUSES=$(wc -l < "$OUT/program" | tr -d ' ')

# Every ancestor/2 the finished program can prove. A querier that answers
# anything not in here read something that was never true.
FINAL="ancestor(bob,ann) ancestor(bob,jim) ancestor(bob,pat) ancestor(bob,zoe) \
ancestor(jim,zoe) ancestor(pat,jim) ancestor(pat,zoe) ancestor(tom,ann) \
ancestor(tom,bob) ancestor(tom,jim) ancestor(tom,liz) ancestor(tom,pat) \
ancestor(tom,zoe)"

echo "emptying the knowledge base"
$CL forget > "$OUT/forget.log"

echo "one ruler writing $CLAUSES clause(s), $QUERIERS queriers reading"
set +e

# The queriers go up first, so that they are already asking by the time the
# first clause lands -- the same reason groups.sh starts its workers first.
# A QUERIER RUNS UNTIL THE RULER IS FINISHED, not for a fixed number of turns.
# A fixed count is a race against how long the writing takes: eight queriers
# doing forty quick queries each were all done inside two seconds, the ruler was
# eight seconds writing, and every one of them answered `false' to a knowledge
# base that had nothing in it yet. The run passed every check about what may not
# be answered and proved nothing at all, which is the failure mode this file
# exists to avoid.
q=1
while [ "$q" -le "$QUERIERS" ]; do
  (
    n=0
    while [ ! -f "$OUT/ruler-done" ] && [ "$n" -lt 400 ]; do
      # `--answers 0' is every answer, not the first ten: a querier that stopped
      # early could not produce an answer outside the set and the check would
      # pass without looking at most of the program.
      $QY --answers 0 query "ancestor(X,Y)" 2>&1 | sed "s/^/q$q /"
      n=$((n + 1))
    done
  ) > "$OUT/q$q.log" 2>&1 &
  q=$((q + 1))
done

# And now the program arrives, one clause at a time.
sleep 1
n=1
while [ "$n" -le "$CLAUSES" ]; do
  sed -n "${n}p" "$OUT/program" > "$OUT/clause"
  $CL consult "$OUT/clause" >> "$OUT/ruler.log" 2>&1
  sleep 1
  n=$((n + 1))
done
# One more round of queries against the finished program before they stop, so
# that the last thing every querier saw is the whole of it.
sleep 2
touch "$OUT/ruler-done"
echo "ruler done"

wait
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

# Everything every querier ever answered.
seen=$(cat "$OUT"/q*.log | grep -E '^q[0-9]+ +[0-9]+\. ' | sed 's/^q[0-9]* *[0-9]*\. //' | sort -u)

# One-sided: nothing outside the finished program's answers.
outside=""
for a in $seen; do
  case " $FINAL " in
    *" $a "*) ;;
    *) outside="$outside $a" ;;
  esac
done
check "no querier answered outside the program" "$(echo $outside)" ""

# Nobody fell over, and nobody was refused.
check "no querier hit an error" \
  "$(cat "$OUT"/q*.log | grep -cE 'refused|failed|cannot|no server' | head -1)" "0"
check "the ruler wrote every clause" \
  "$(grep -c 'consulted 1 clause' "$OUT/ruler.log" | head -1)" "$CLAUSES"

# The program was genuinely growing while they read: the first query of the run
# and the last must not have seen the same thing.
first=$(cat "$OUT"/q*.log | grep -cE '^q[0-9]+ +1\. ' | head -1)
check "queriers ran while it was being written" \
  "$([ "$first" -gt 0 ] && echo yes || echo no)" "yes"

early=$(head -40 "$OUT/q1.log" | grep -cE '^q1 +[0-9]+\. ' | head -1)
late=$(tail -40 "$OUT/q1.log" | grep -cE '^q1 +[0-9]+\. ' | head -1)
echo "     q1 answered $early time(s) in its first queries, $late in its last"
check "the knowledge base grew under them" \
  "$([ "$late" -gt "$early" ] && echo yes || echo no)" "yes"

# And the finished program proves everything, from a process that took no part.
final_now=$($CL --answers 0 query "ancestor(X,Y)" | grep -E '^  [0-9]+\. ' \
  | sed 's/^ *[0-9]*\. //' | sort | tr '\n' ' ' | sed 's/ *$//')
check "the finished program proves all of it" "$final_now" "$(echo $FINAL)"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  echo "--- ruler ---"; cat "$OUT/ruler.log"
  echo "--- q1 ---";    head -30 "$OUT/q1.log"
  exit 1
fi
