#!/bin/sh
# equiv-lint.sh -- prove lint.pl and lint.py report the same thing.
#
#     sh tools/coco-agent/equiv-lint.sh
#
# THE REWRITE'S ACCEPTANCE TEST, and the reason lint.py is still in the tree.
# It is no longer the linter -- lint.sh, verify.sh's G1 and the suite all run
# lint.pl now -- but it is a second, independent implementation of the same
# rules, and a differential test against one is worth more than either alone.
# That is the role test/trace-diff.py already holds here: cocolog's own suite
# checks its four-port trace byte-for-byte against swipl's.
#
# BYTE FOR BYTE, not finding-for-finding: the message, the fix line, the
# citation and the summary. A cosmetic difference would read as a behavioural
# one to whoever hits it next.
#
# The last line is GREEN, RED or SKIP, so test/lint.sh can read it.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"

cd "$ROOT" || exit 0
command -v python3 >/dev/null 2>&1 || { echo "SKIP no python3"; exit 0; }
[ -x "$BIN" ] || { echo "SKIP no binary at $BIN"; exit 0; }
[ -f "$HERE/lint.pl" ] || { echo "SKIP no lint.pl"; exit 0; }

T=$(mktemp -d) || exit 0
trap 'rm -rf "$T"' EXIT

CORPUS=$(ls tutorials/basics/[0-9]*.pl tutorials/library/[0-9]*.pl library/*.pl 2>/dev/null)
SELF="$HERE/selftest/traps.pl"

python3 "$HERE/build.py" >/dev/null 2>&1
python3 "$HERE/traps.py" --facts >/dev/null 2>&1

python3 "$HERE/lint.py" $CORPUS > "$T/py-corpus.txt" 2>&1
python3 "$HERE/lint.py" "$SELF" > "$T/py-self.txt"   2>&1
sh    "$HERE/lint.sh" $CORPUS    > "$T/pl-corpus.txt" 2>&1
sh    "$HERE/lint.sh" "$SELF"    > "$T/pl-self.txt"   2>&1

rc=0
for pair in corpus self; do
  if ! diff -u "$T/py-$pair.txt" "$T/pl-$pair.txt" > "$T/d-$pair.txt" 2>&1; then
    echo "$pair differs (python < , cocolog > ):"
    head -20 "$T/d-$pair.txt" | sed 's/^/  /'
    rc=1
  fi
done

if [ $rc -eq 0 ]; then
  echo "GREEN: lint.pl and lint.py agree byte for byte -- $(tail -1 "$T/pl-corpus.txt"),"
  echo "       and $(tail -1 "$T/pl-self.txt") on selftest/traps.pl"
else
  echo "RED: the cocolog linter and the python one disagree"
fi
