#!/bin/sh
# The balancer arrangement: three workers, no centre. See README.md.
#
#   1. each worker SEEDS its own third of the training data into its
#      own knowledge base -- its part, its responsibility -- with
#      part_ready/1 committed last;
#   2. each worker WAITS for its peers by asking their knowledge bases
#      for part_ready/1, then FETCHES their thirds as train_sample/3
#      clauses -- reads, running freely in parallel;
#   3. each worker trains a FULL model in --local on its own third plus
#      the two fetched ones, and publishes it into its own knowledge
#      base -- so all three end holding the same knowledge learned the
#      same way;
#   4. verification asks EVERY worker to test, and sends the predict
#      probes round-robin across the three -- the balancer: any node
#      answers, so queries can go to whichever is up or nearest.
#
# ONE WRITE TURN AT A TIME, cluster-wide, taken through a mkdir mutex:
# the server does not survive overlapping clause-write transactions yet
# (the hunt in STATUS.md), and a write turn stays small for the same
# reason. Reads -- the ready-polling, the fetches, the tests -- run in
# parallel throughout; that half is proven ground.
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

# one write turn at a time -- see the header
write_turn() {
  until mkdir "$OUT/one-writer" 2>/dev/null; do sleep 1; done
  timeout 120 "$@"
  rc=$?
  rmdir "$OUT/one-writer"
  return $rc
}

for opts in "$PART1" "$PART2" "$PART3"; do
  timeout 60 "$C" $opts forget >/dev/null 2>&1
done

echo "== each worker seeds its own third, in parallel"
for n in 1 2 3; do
  eval "opts=\$PART$n"
  (
    # the program once, then one small turn: a few chunk rows and the
    # ready mark, committed together
    write_turn "$C" $opts consult "$HERE/worker.pl" > "$OUT/seed_$n.log" 2>&1
    write_turn "$C" $opts query "seed_part($n)" >> "$OUT/seed_$n.log" 2>&1
  ) &
done

echo "== each worker waits for its peers, fetches their parts, trains, publishes"
for n in 1 2 3; do
  eval "opts=\$PART$n"
  (
    # its own part_ready included: a worker's own seeding is a peer too,
    # as far as ordering goes
    for m in 1 2 3; do
      eval "peer=\$PART$m"
      deadline=$(( $(date +%s) + 300 ))
      until timeout 30 "$C" $peer --answers 1 query "part_ready($m)" 2>/dev/null \
            | grep -q '^  1\.'; do
        if [ "$(date +%s)" -gt "$deadline" ]; then
          echo "worker $n: part $m never became ready" >> "$OUT/work_$n.log"; exit 1
        fi
        sleep 2
      done
      [ "$m" = "$n" ] && continue
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
    write_turn "$C" $opts consult "$OUT/model_$n.pl" > "$OUT/pub_$n.log" 2>&1
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
