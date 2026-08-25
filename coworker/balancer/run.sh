#!/bin/sh
# The balancer arrangement: three workers, no centre. See README.md.
#
# Each worker is one pipeline, and the order inside it is the point:
#
#   1. SEED its own third first -- its part, its responsibility -- into
#      its own knowledge base, part_ready/1 committed in the same turn;
#   2. only THEN poll its peers: a worker starts asking for others'
#      parts after its own work is done, never before, so nobody waits
#      on a worker that is itself still waiting;
#   3. FETCH the two thirds it lacks by reading the peers' chunk rows;
#   4. TRAIN the full model in --local -- long compute never sits
#      inside a database turn, where the server's idle timeout would
#      take the connection out from under it;
#   5. PUBLISH the finished model into its own knowledge base as one
#      short consult.
#
# Verification asks EVERY worker to test, and sends the predict probes
# round-robin across the three -- the balancer: any node answers, so
# queries go to whichever is up or nearest.
#
# The seeds travel as a handful of chunk rows (sixty samples each) and
# the writes are short turns, because a clause row has to fit in a page
# and a turn should not dawdle -- but the turns run CONCURRENTLY, as
# turns may: the hunt that once had this file serialising every write
# ended with the server exonerated (STATUS.md tells it).
#
# Each worker's connection is overridable, so the three can sit on
# three different servers:  PART1_OPTS="--host h1 --kb bal_part1" etc.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
C="$ROOT/cocolog"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/coco-balancer-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
BASE="--host $HOST --port $PORT --timeout 30"
PART1=${PART1_OPTS:-"$BASE --kb bal_part1"}
PART2=${PART2_OPTS:-"$BASE --kb bal_part2"}
PART3=${PART3_OPTS:-"$BASE --kb bal_part3"}

if [ ! -x "$C" ]; then
  echo "no cocolog binary -- make first"; exit 1
fi
if ! timeout 20 "$C" $PART1 list >/dev/null 2>&1; then
  echo "SKIP no Zigurat server at $HOST:$PORT"; exit 0
fi

for opts in "$PART1" "$PART2" "$PART3"; do
  timeout 60 "$C" $opts forget >/dev/null 2>&1
done

echo "== three workers: seed own third, then poll peers, fetch, train, publish"
for n in 1 2 3; do
  eval "opts=\$PART$n"
  (
    # own work first: the program, then one small turn of chunk rows
    # with the ready mark committed alongside them
    timeout 120 "$C" $opts consult "$HERE/worker.pl" > "$OUT/seed_$n.log" 2>&1
    timeout 120 "$C" $opts query "seed_part($n)" >> "$OUT/seed_$n.log" 2>&1

    # only now the peers: this worker's own part is already committed
    for m in 1 2 3; do
      [ "$m" = "$n" ] && continue
      eval "peer=\$PART$m"
      deadline=$(( $(date +%s) + 300 ))
      until timeout 30 "$C" $peer --answers 1 query "part_ready($m)" 2>/dev/null \
            | grep -q '^  1\.'; do
        if [ "$(date +%s)" -gt "$deadline" ]; then
          echo "worker $n: peer $m never became ready" >> "$OUT/work_$n.log"; exit 1
        fi
        sleep 2
      done
      timeout 60 "$C" $peer query "forall(samples_chunk(P, Q, Ch), format(\"samples_chunk(~w, ~w, ~q).~n\", [P, Q, Ch]))" \
        2>/dev/null | grep -a '^samples_chunk' > "$OUT/fetch_${n}_$m.pl"
    done
    # its own third comes back out of its own knowledge base too -- the
    # knowledge base is the source of truth, not the generator
    timeout 60 "$C" $opts query "forall(samples_chunk(P, Q, Ch), format(\"samples_chunk(~w, ~w, ~q).~n\", [P, Q, Ch]))" \
      2>/dev/null | grep -a '^samples_chunk' > "$OUT/own_$n.pl"

    FETCHED=$(ls "$OUT"/fetch_${n}_*.pl)
    "$C" run "$OUT/own_$n.pl" $FETCHED "$HERE/worker.pl" train_full \
      > "$OUT/raw_$n" 2>&1
    grep -a '^torch_' "$OUT/raw_$n" > "$OUT/model_$n.pl"
    [ -s "$OUT/model_$n.pl" ] || { echo "worker $n trained nothing" >> "$OUT/work_$n.log"; exit 1; }
    timeout 120 "$C" $opts consult "$OUT/model_$n.pl" > "$OUT/pub_$n.log" 2>&1
  ) &
done
wait
grep -ah '^trained' "$OUT"/raw_[123] 2>/dev/null | sed 's/^/   /'
cat "$OUT"/work_[123].log 2>/dev/null

echo "== every worker must answer the test"
failures=0
for n in 1 2 3; do
  eval "opts=\$PART$n"
  got=$(timeout 120 "$C" $opts query "test" 2>/dev/null | grep -c '^ok$')
  if [ "$got" = "1" ]; then
    echo "   worker $n: ok"
  else
    echo "   worker $n: FAIL"
    failures=$((failures + 1))
  fi
done

echo "== predictions, round-robin across the three"
i=1
for probe in "0.5, 0.0" "0.0, -1.0" "-0.35, 0.35" "0.7, 0.7" "-0.9, -0.4" "0.1, 0.45"; do
  eval "opts=\$PART$i"
  line=$(timeout 60 "$C" $opts query "probe($probe)" 2>/dev/null | grep -a '^ring')
  echo "   worker $i: $line"
  i=$(( i % 3 + 1 ))
done

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: three workers, one knowledge, any of them answers"
else
  echo "RED: $failures worker(s) failed the test"; exit 1
fi
