#!/bin/sh
# Every tutorial, all three goals, each goal its own process: train saves the
# model into the store, test reloads and judges it, predict reloads and
# answers. EACH TUTORIAL GETS ITS OWN STORE: consulted clauses live in the
# knowledge base exactly as models do, so two tutorials sharing a store would
# also share their train/test/predict clauses -- and the first one consulted
# would answer for all of them. One store per tutorial is the honest
# arrangement, and it is what the headers document.
#
# SKIPs when the binary lacks the torch module, because "no libtorch here" and "the
# tutorials are wrong" are different findings.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-tutorials-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

if [ ! -x "$COCOLOG" ]; then
  echo "SKIP no cocolog built (make needs libtorch and a built ZiguratIP checkout)"
  exit 0
fi

failures=0
for pl in "$ROOT"/tutorials/[0-9]*.pl; do
  name=$(basename "$pl" .pl)
  STORE="$OUT/store-$name"
  bad=0
  for goal in train test predict; do
    if out=$(timeout 300 "$COCOLOG" --kb tutorials --store "$STORE" run "$pl" "$goal" 2>&1); then
      :
    else
      failures=$((failures + 1))
      bad=1
      echo "FAIL  $name $goal"
      echo "$out" | tail -3 | sed 's/^/      /'
      break
    fi
  done
  [ $bad -eq 0 ] && echo "ok    $name"
done

if [ $failures -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $failures failure(s)"
  exit 1
fi
