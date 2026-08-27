#!/bin/sh
# The accumulator arrangement: three trainers, three knowledge bases,
# one accumulator downstream. See README.md beside this.
#
#   1. three cocolog instances train IN PARALLEL, each on its own third
#      of the data -- in --local, because long compute belongs outside
#      any transaction -- and each PUBLISHES its finished model into its
#      own knowledge base as one short consult;
#   2. the accumulator POLLS each knowledge base for the finished model
#      BY ITS NAME -- torch_model(rings, _) -- which flips exactly when
#      a part's publish turn commits, a turn being one transaction;
#   3. once all three answer, each part's model is read back out of its
#      knowledge base as clauses and the accumulator averages them,
#      saves the accumulated model into its own knowledge base, tests
#      it on held-out data, and predicts.
#
# The publishes are short concurrent consults, and they simply run: the
# hunt that once had this file serialising every write ended with the
# server exonerated (STATUS.md tells it). What stands is the discipline
# that survives the verdict: long compute in --local, never inside a
# database turn -- a turn that dawdles past the server's idle TIMEOUT
# loses its connection, and now says so loudly instead of losing data.
#
# Each part's connection is overridable, so the three parts can sit on
# three different servers:  PART1_OPTS="--host h1 --kb acc_part1" etc.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
C="$ROOT/cocolog"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/coco-accumulator-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
BASE="--host $HOST --tcp $PORT --timeout 30"
PART1=${PART1_OPTS:-"$BASE --kb acc_part1"}
PART2=${PART2_OPTS:-"$BASE --kb acc_part2"}
PART3=${PART3_OPTS:-"$BASE --kb acc_part3"}
MAIN=${MAIN_OPTS:-"$BASE --kb acc_main"}

if [ ! -x "$C" ]; then
  echo "no cocolog binary -- make first"; exit 1
fi
if ! timeout 20 "$C" $PART1 list >/dev/null 2>&1; then
  echo "SKIP no Zigurat server at $HOST:$PORT"; exit 0
fi

# a clean slate, so a re-run proves training and not leftovers
for opts in "$PART1" "$PART2" "$PART3" "$MAIN"; do
  timeout 60 "$C" $opts forget >/dev/null 2>&1
done

echo "== three trainers in parallel, each publishing its own part"
for n in 1 2 3; do
  eval "opts=\$PART$n"
  (
    "$C" run "$HERE/trainer.pl" "train_part($n)" > "$OUT/raw_$n" 2>&1
    grep -a '^torch_' "$OUT/raw_$n" > "$OUT/model_$n.pl"
    [ -s "$OUT/model_$n.pl" ] && timeout 120 "$C" $opts consult "$OUT/model_$n.pl" > "$OUT/pub_$n.log" 2>&1
  ) &
done

echo "== the accumulator asks each part for a model named rings"
deadline=$(( $(date +%s) + 300 ))
for n in 1 2 3; do
  eval "opts=\$PART$n"
  until timeout 30 "$C" $opts --answers 1 query "torch_model(rings, _)" 2>/dev/null \
        | grep -q '^  1\.'; do
    if [ "$(date +%s)" -gt "$deadline" ]; then
      echo "part $n never appeared -- its logs:"
      cat "$OUT/raw_$n" "$OUT/pub_$n.log" 2>/dev/null; exit 1
    fi
    sleep 2
  done
  echo "   part $n: published"
done
wait
grep -ah '^part ' "$OUT"/raw_[123] | sed 's/^/   /'

echo "== reading each part's model back out of its knowledge base"
for n in 1 2 3; do
  eval "opts=\$PART$n"
  timeout 60 "$C" $opts query "torch_model(rings, S), format(\"part_spec($n, ~q).~n\", [S]), forall(torch_params(rings, Q, Ch), format(\"part_chunk($n, ~w, ~q).~n\", [Q, Ch]))" \
    2>/dev/null | grep -a '^part_' > "$OUT/part_$n.pl"
  [ -s "$OUT/part_$n.pl" ] || { echo "part $n exported nothing"; exit 1; }
done

echo "== accumulate, test, predict"
timeout 300 "$C" $MAIN run "$OUT/part_1.pl" "$OUT/part_2.pl" "$OUT/part_3.pl" \
  "$HERE/accumulate.pl" accumulate | tee "$OUT/accumulate.log"

if grep -q '^ok$' "$OUT/accumulate.log"; then
  echo; echo "GREEN: accumulated from 3 parts, tested and predicted"
else
  echo; echo "RED: the accumulated model did not pass"; exit 1
fi
