#!/bin/sh
# G2+G3 -- consult the candidate and ask the store which of its predicates it
# calls its own. A name that collided with a tier-1 library is ABSENT.
#
#     sh tools/coco-agent/oracle.sh myprogram.pl
#
# Answers one line per predicate, `own' or `COLLIDED', and exits 1 if anything
# collided. See tools/coco-agent/oracle.pl for the mechanism and its blind
# spot, and DESIGN.md section 16.1 for the run that confirmed it.
#
# --local ONLY, deliberately. Under --kb or --embed the store is warmed before
# enumerating, so every predicate any other process wrote to that base joins
# the answer and the difference stops being about this file.
#
# NO BASELINE SUBTRACTION. The design provided for one; measured, the tier-1
# baseline is EMPTY -- an otherwise-bare candidate yields its own predicates
# and coco_oracle/0, nothing else -- so there is nothing to subtract.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"

[ -n "$1" ] || { echo "usage: oracle.sh FILE.pl ..." >&2; exit 2; }
[ -x "$BIN" ] || { echo "oracle.sh: no cocolog binary at $BIN" >&2; exit 2; }

FILES=""
for f in "$@"; do
  case "$f" in /*) FILES="$FILES $f" ;; *) FILES="$FILES $(pwd)/$f" ;; esac
done

# A SCRATCH DIRECTORY WITH NO library/ IN IT: the library path probes ./library
# relative to the working directory before <exedir>/library, so running here
# would let a candidate's own directory shadow the real one.
SCRATCH=$(mktemp -d) || exit 2
OUT=$(cd "$SCRATCH" && timeout 60 "$BIN" --local run $FILES "$HERE/oracle.pl" coco_oracle 2>&1)
rc=$?
rm -rf "$SCRATCH"

case "$OUT" in
  *coco_oracle_end*) ;;
  *) echo "$OUT" >&2
     echo "oracle.sh: the candidate did not consult cleanly (exit $rc)" >&2
     exit 2 ;;
esac

VISIBLE=$(printf '%s\n' "$OUT" | sed -n 's/^coco_oracle_name \(.*\) \([0-9][0-9]*\)$/\1\/\2/p' \
          | grep -v '^coco_oracle/0$' | sort -u)

# DECLARED comes from the same clause reader the linter uses, so the two halves
# cannot disagree about what a DCG head's arity is.
DECLARED=$(python3 -c '
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath("'"$HERE"'/x")))
import ccbatch as R
ks = set()
for p in sys.argv[1:]:
    ks |= set(R.heads(p))
for k in sorted(ks):
    print(k)
' $FILES)

# A DECLARED EXTENSION POINT IS A COLLISION THAT IS MEANT. library/httpd.pl's
# `httpd_page(_,_,_) :- fail.' exists so a program can add its own pages, and a
# program that does so really does merge into that record and really does
# vanish from current_predicate/1 -- the oracle is not wrong, it just cannot
# know the intent. The list comes from blocklist.json, which is where the
# linter's N1 gets it too, so the two halves cannot drift apart.
[ -f "$HERE/blocklist.json" ] || python3 "$HERE/build.py" >/dev/null 2>&1
HOOKS=$(python3 -c '
import json, sys
try:
    print("\n".join(sorted(json.load(open(sys.argv[1]))["hooks"])))
except Exception:
    pass
' "$HERE/blocklist.json")

bad=0
for k in $DECLARED; do
  if printf '%s\n' "$VISIBLE" | grep -qxF "$k"; then
    echo "own       $k"
  elif printf '%s\n' "$HOOKS" | grep -qxF "$k"; then
    echo "hook      $k -- a declared extension point (H :- fail.) in a library."
    echo "          The clauses merge on purpose; that is what the hook is for."
  else
    echo "COLLIDED  $k -- the store folded it into a library's record, so it is"
    echo "          invisible to current_predicate/1 and its clauses merged."
    bad=1
  fi
done

exit $bad
