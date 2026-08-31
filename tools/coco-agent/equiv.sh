#!/bin/sh
# equiv.sh -- prove clauses.pl reads a file the same way clauses.py does.
#
#     sh tools/coco-agent/equiv.sh
#
# THE REWRITE'S WHOLE ACCEPTANCE TEST. clauses.py is 375 lines of hand-rolled
# scanning; clauses.pl is a DCG. They are two implementations of one grammar,
# and the only honest way to swap the second in for the first is to show that
# on every .pl file in this tree they answer the same clause list -- not the
# same COUNT, which two scanners can agree on while disagreeing about where
# every clause starts, but the same offset, line, column, length, name, arity
# and kind, clause by clause.
#
# 94 files, ~2200 clauses. A single differing offset is a failure.
#
# The last line is GREEN, RED or SKIP, so test/lint.sh can read it.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"

cd "$ROOT" || exit 0
command -v python3 >/dev/null 2>&1 || { echo "SKIP no python3"; exit 0; }
[ -x "$BIN" ] || { echo "SKIP no binary at $BIN"; exit 0; }
[ -f "$HERE/clauses.pl" ] || { echo "SKIP no clauses.pl yet"; exit 0; }

COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY"
export COCOLOG_LIBRARY

T=$(mktemp -d) || exit 0
trap 'rm -rf "$T"' EXIT

# The corpus: every .pl this repository owns, including the vendored SWI
# libraries -- which are the hardest, because they were written for a Prolog
# with modules and carry the Module:Head clauses and the /** */ headers that
# broke the reader twice.
FILES=$(ls tutorials/basics/[0-9]*.pl tutorials/library/[0-9]*.pl library/*.pl \
           lib/swipl/*.pl tools/coco-agent/*.pl test/files/*.pl 2>/dev/null | sort)
N=$(printf '%s\n' "$FILES" | wc -l | tr -d ' ')

# ---- the Python side ------------------------------------------------------
python3 - $FILES > "$T/py.tsv" <<'PY'
import sys
sys.path.insert(0, "tools/coco-agent")
import clauses as R
for f in sys.argv[1:]:
    src, cs = R.read_file(f)
    for c in cs:
        if c.is_directive:
            kind = "directive(%s,%d)" % c.directive if c.directive else "directive"
        elif c.is_dcg:
            kind = "dcg"
        else:
            kind = "plain"
        print("%s\t%d\t%d\t%d\t%d\t%s\t%s\t%s" % (
            f, c.offset, c.line, c.col, len(c.text),
            c.name if c.name else "-",
            c.arity if c.arity is not None else -1, kind))
PY

# ---- the cocolog side -----------------------------------------------------
# THE FILE LIST GOES THROUGH THE ENVIRONMENT, not the goal term. cocolog has no
# argv -- current_prolog_flag/2 answers only `executable' -- so the two routes
# are a goal the shell has to quote, or getenv/2. A path with a space in it
# breaks the first and not the second.
printf '%s\n' "$FILES" > "$T/files.txt"
COCO_CC_FILES="$T/files.txt" timeout 300 "$BIN" --local \
  run "$HERE/clauses.pl" cc_dump > "$T/co.tsv" 2> "$T/co.err"
rc=$?

if [ $rc -ne 0 ]; then
  sed 's/^/  /' "$T/co.err" | head -20
  echo "RED: clauses.pl did not run (exit $rc)"
  exit 1
fi

PYN=$(wc -l < "$T/py.tsv" | tr -d ' ')
CON=$(wc -l < "$T/co.tsv" | tr -d ' ')

if diff -u "$T/py.tsv" "$T/co.tsv" > "$T/d.txt" 2>&1; then
  echo "GREEN: $CON clauses over $N files, identical to clauses.py in offset,"
  echo "       line, column, length, name, arity and kind"
else
  echo "python $PYN clauses, cocolog $CON -- first differences:"
  head -30 "$T/d.txt" | sed 's/^/  /'
  echo "  ($(grep -c '^[-+]' "$T/d.txt") differing lines in all)"
  echo "RED: clauses.pl and clauses.py disagree"
fi
