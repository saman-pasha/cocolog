#!/bin/sh
# The four-port tracer, held to SWI-Prolog: both are asked the same
# queries over test/trace.pl with the tracer on, and the port lines are
# compared one for one -- Call, Exit, Redo and Fail, in order, at the
# same relative depths, over the same goals.
#
# Normalised before comparing: the depth base (SWI's toplevel starts
# around ten frames deep, cocolog at one), the names of unbound
# variables (_438 there, _G34 here), and the writers' spacing.
#
# SKIPs without swipl, because "no SWI here" and "the tracer is wrong"
# are different findings.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
SWIPL=${SWIPL:-swipl}

command -v "$SWIPL" >/dev/null 2>&1 || {
  echo "SKIP (no swipl on PATH; apt-get install swi-prolog-nox)"
  exit 0
}
[ -x "$COCOLOG" ] || { echo "SKIP (build cocolog first)"; exit 0; }

fails=0
total=0

# every query is wrapped in ( Q -> true ; true ) on BOTH sides, so a
# failing query is a traced failure rather than a differing toplevel
run_case() {
  q="$1"
  total=$((total + 1))
  swi=$(yes '' | timeout 20 "$SWIPL" -q -g "leash(-all), consult('$HERE/trace.pl'), trace, ( $q -> true ; true ), notrace, halt" -t halt 2>&1)
  coco=$(timeout 20 "$COCOLOG" --trace run "$HERE/trace.pl" "( $q -> true ; true )" 2>&1 >/dev/null)
  if "$COCOLOG" --local run "$HERE/trace-diff.pl" td_main -- "$q" "$swi" "$coco"; then
    printf 'ok   %s\n' "$q"
  else
    printf 'FAIL %s\n' "$q"
    fails=$((fails + 1))
  fi
}

run_case "anc(tom, X), fail"
run_case "anc(tom, ann)"
run_case "anc(ann, X)"
run_case "sum([1,2], S)"
run_case "sum([1,2,3], S), S > 5"
run_case "pick(X), fail"
run_case "pick(b)"
run_case "fst(X, [7,8])"
run_case "memb(X, [1,2]), X > 1"
run_case "memb(9, [1,2])"
run_case "classify(-3, C)"
run_case "classify(0, C)"
run_case "classify(7, C)"
run_case "either(5)"
run_case "either(1)"
run_case "3 < 2"
run_case "X = f(Y)"
run_case "atom(foo)"
run_case "X is 2 + 2, X > 3"
run_case "np(2)"
run_case "np(1)"

if [ "$fails" -eq 0 ]; then
  echo "GREEN: $total queries traced identically"
else
  echo "RED: $fails of $total differ"
  exit 1
fi
