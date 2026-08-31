#!/bin/sh
# cocolint over the calibration corpus, and the two rewrites it stands on.
#
# THE LINTER IS COCOLOG NOW. tools/coco-agent/lint.pl and clauses.pl replaced
# lint.py and clauses.py, which stay in the tree as DIFFERENTIAL ORACLES -- a
# second, independent implementation of the same rules, which is worth more
# than either alone. That is the role test/trace-diff.py already holds here:
# cocolog's own suite checks its four-port trace byte-for-byte against swipl's.
#
# Five things are checked, in cost order:
#
#   1. the dialect card's 43 citations still point at the code they claim
#   2. the retrieval index's paths and anchors resolve
#   3. clauses.pl reads every .pl in this tree exactly as clauses.py does
#   4. lint.pl reports exactly what lint.py reports, byte for byte
#   5. the findings over the corpus are still the pinned set, every rule still
#      fires on selftest/traps.pl, and the blocklist still matches the store
#
# A FINDING IN 5 IS A LINTER BUG UNTIL SHOWN OTHERWISE, which is the point of
# calibrating against code known to work. The seventeen that survived are
# listed below with the argument for each.
#
#   sh test/lint.sh
#
# The last line is GREEN or SKIP, because test/run.sh discards a shell case's
# exit status and reads only that line.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
cd "$ROOT" || exit 0

if ! command -v python3 >/dev/null 2>&1; then
  echo "SKIP no python3"
  exit 0
fi

AGENT="$ROOT/tools/coco-agent"
[ -f "$AGENT/lint.pl" ] || { echo "SKIP no tools/coco-agent"; exit 0; }
[ -x "$ROOT/cocolog" ] || { echo "SKIP no binary -- the linter is cocolog now"; exit 0; }

# ---- 1. the dialect card's citations -------------------------------------
CARD=$(python3 "$AGENT/traps.py" --check 2>&1)
CARD_RC=$?
echo "$CARD" | sed 's/^/  /'

# ---- 2. the retrieval index ----------------------------------------------
IDX=$(python3 "$AGENT/index.py" --check --no-run 2>&1)
IDX_RC=$?
printf '%s\n' "$IDX" | sed 's/^/  /'
echo

python3 "$AGENT/build.py" >/dev/null 2>&1 || { echo "SKIP blocklist would not build"; exit 0; }
python3 "$AGENT/traps.py" --facts >/dev/null 2>&1 || { echo "SKIP traps.pl would not build"; exit 0; }

# ---- 3. clauses.pl == clauses.py -----------------------------------------
EQ=$(sh "$AGENT/equiv.sh" 2>&1)
printf '%s\n' "$EQ" | sed 's/^/  /'
# GREEN OR SKIP ANYWHERE, not on the last line: both harnesses print a
# two-line GREEN, and reading tail -1 made this case report a disagreement
# that did not exist.
EQ_OK=$(printf '%s\n' "$EQ" | grep -c '^\(GREEN\|SKIP\)')

# ---- 4. lint.pl == lint.py -----------------------------------------------
EQL=$(sh "$AGENT/equiv-lint.sh" 2>&1)
printf '%s\n' "$EQL" | sed 's/^/  /'
EQL_OK=$(printf '%s\n' "$EQL" | grep -c '^\(GREEN\|SKIP\)')
echo

# ---- 5. the findings themselves ------------------------------------------
CORPUS=$(ls "$ROOT"/tutorials/basics/[0-9]*.pl "$ROOT"/tutorials/library/[0-9]*.pl "$ROOT"/library/*.pl 2>/dev/null)
FILES=$(echo "$CORPUS" | wc -l | tr -d ' ')
OUT=$(sh "$AGENT/lint.sh" $CORPUS 2>&1)
SELF=$(sh "$AGENT/lint.sh" "$AGENT/selftest/traps.pl" 2>&1)

# Every finding as `file rule [trap]', with the line number dropped: a line
# that moves because somebody added a comment is not a change in what the
# linter found, and pinning it would fail this case for the wrong reason.
GOT=$(echo "$OUT" | sed -n 's/^\([^ :]*\):[0-9]*:[0-9]* \(HARD\|WARN\) \([A-Z0-9]*\) \(\[[A-Z0-9]*\] \)\?.*/\1 \2 \3 \4/p' \
      | sed 's/ *$//' | sort)

# ---- the seventeen, and why each is kept rather than silenced ------------
#
# TEN OF THE SEVENTEEN ARE TUTORIALS TEACHING THE VERY TRAP THE RULE
# ENFORCES, which is the most satisfying kind of true positive there is --
# and a standing argument that the rules point at real divergences, because
# somebody thought each one worth a lesson:
#
#   basics/07  S1 [R1]  `( retract(seen(_)), fail ; true )', written to show
#                       that the failure-driven loop removes exactly ONE
#                       clause. The lesson IS the finding.
#   library/04 S1 [F1]  `~t~20|' inside a catch/3 demonstrating the refusal.
#   basics/04, 21-bigint, 25-der  A1 x6  `1000000000000000000 * 997' and the
#                       wrapped answer, which 25-der calls "a wrong answer
#                       returned confidently".
#   basics/10  N1 x2    defines digits//1 and digit//1, which are also
#                       dcg_basics' at arity 3. A real collision, and the two
#                       definitions DIFFER -- the tutorial's wants at least
#                       one digit, dcg_basics' allows none. Latent rather than
#                       harmful only because their first solutions agree.
#
# FOUR ARE REAL FINDINGS IN THE TREE, left for the owner rather than quietly
# edited:
#
#   29-ray, 30-hex, 31-astar  S1 [H1]  their must/3 calls halt(1) on the
#                       failure branch where the other 44 tutorials fail.
#                       The exit code coincides, so it works; what it costs is
#                       the remaining checks and any stdout not yet flushed --
#                       the failure mode CLAUDE.md records under flush_output.
#   36-llm     Z1       its main/0 is ~15 KB stored, twice the page budget.
#                       Harmless only because the tutorial runs --local. The
#                       same clause under a store is lost SILENTLY -- measured
#                       under --embed: 8000 bytes reads back from a second
#                       process, 8020 does not, and the writing process exits
#                       0 with empty stderr both times.
#
# AND THREE ARE NO-OP IMPORTS already named in CLAUDE.md:
#
#   26-x509, 27-ca, library/astar.pl  T1  use_module for a tier-1 library.
EXPECT=$(cat <<'EOF'
library/astar.pl WARN T1
tutorials/basics/04-arithmetic.pl WARN A1 [A2]
tutorials/basics/04-arithmetic.pl WARN A1 [A2]
tutorials/basics/07-assert-and-retract.pl HARD S1 [R1]
tutorials/basics/10-grammars.pl HARD N1
tutorials/basics/10-grammars.pl HARD N1
tutorials/library/04-builtins.pl HARD S1 [F1]
tutorials/library/21-bigint.pl WARN A1 [A2]
tutorials/library/21-bigint.pl WARN A1 [A2]
tutorials/library/25-der.pl WARN A1 [A2]
tutorials/library/25-der.pl WARN A1 [A2]
tutorials/library/26-x509.pl WARN T1
tutorials/library/27-ca.pl WARN T1
tutorials/library/29-ray.pl HARD S1 [H1]
tutorials/library/30-hex.pl HARD S1 [H1]
tutorials/library/31-astar.pl HARD S1 [H1]
tutorials/library/36-llm.pl WARN Z1 [Z1]
EOF
)

echo "$OUT" | grep -E 'HARD|WARN' | grep -v '^ ' | sed 's/^/  /'
echo

# ---- every rule still FIRES ----------------------------------------------
#
# A CORPUS OF CORRECT CODE CANNOT SHOW THAT A RULE WORKS, only that it does
# not misfire -- so a rule whose pattern has quietly stopped matching is
# invisible above. selftest/traps.pl walks into every divergence on purpose,
# and this asserts each one is still caught.
FIRED=$(printf '%s\n' "$SELF" \
        | sed -n 's/^[^ ]* \(HARD\|WARN\) \([A-Z0-9]*\) \(\[[A-Z0-9]*\]\)\?.*/\2 \3/p' \
        | sed 's/ *$//' | sort -u)
WANT=$(python3 "$AGENT/traps.py" --patterns | awk '{print "S1 [" $1 "]"}' | sort -u)
WANT="D1
N1
N2
N3
T1
A1 [A2]
Z1 [Z1]
$WANT"
MISSING=$(printf '%s\n' "$WANT" | sort -u | while read -r r; do
            [ -n "$r" ] || continue
            printf '%s\n' "$FIRED" | grep -qxF "$r" || echo "$r"
          done)

# ---- the blocklist, probed against the running store ---------------------
#
# THE STRONGEST CHECK HERE, and it costs two processes. One file defines EVERY
# clause-defined tier-1 name at its recorded arity and asks the oracle: each
# must come back COLLIDED, the store itself confirming the extraction got the
# name and the arity right. A second does the same for the C-dispatched names
# and expects the opposite -- they come back `own', because a C name's record
# has library = 0 -- which is the oracle's blind spot, measured not asserted.
#
# It has paid for itself three times: `sandbox/0' was a name nothing defines
# (aggregate.pl writes `sandbox:safe_meta_predicate' and cocolog stores that
# under the HEAD); `throw/1' sat in the clause set where the prompt would have
# called it nondet; and gating clauses.pl itself found a 0'c literal misread
# by BOTH clause readers at once.
PROBE="skipped"
PD=$(mktemp -d)
python3 - "$AGENT/blocklist.json" "$PD" <<'PY'
import json, sys
b = json.load(open(sys.argv[1])); d = sys.argv[2]
def emit(keys, path):
    with open(d + "/" + path, "w") as f:
        f.write("myprog_marker(1).\n")
        n = 0
        for k in sorted(keys):
            nm, ar = k.rsplit("/", 1)
            if ar == "*" or not nm.replace("_", "").isalnum() or not nm[:1].islower():
                continue
            ar = int(ar)
            f.write("%s%s.\n" % (nm, "(%s)" % ",".join("_" * ar) if ar else ""))
            n += 1
    return n
emit(b["tier1"]["clauses"], "clauses.pl")
emit(b["tier1"]["c"], "ctable.pl")
PY
CL=$(sh "$AGENT/oracle.sh" "$PD/clauses.pl" 2>/dev/null)
CT=$(sh "$AGENT/oracle.sh" "$PD/ctable.pl" 2>/dev/null)
rm -rf "$PD"
LEAK=$(printf '%s\n' "$CL" | grep '^own' | grep -vc myprog_marker)
NC=$(printf '%s\n' "$CL" | grep -c '^COLLIDED')
NB=$(printf '%s\n' "$CT" | grep '^own' | grep -vc myprog_marker)
if [ "$LEAK" -eq 0 ]; then
  PROBE="$NC of $NC clause-defined names confirmed taken by the store; $NB C-dispatched names come back visible, which is the blind spot N2 covers"
else
  PROBE="BAD: $LEAK clause-defined name(s) the blocklist blocks are free in the store"
  printf '%s\n' "$CL" | grep '^own' | grep -v myprog_marker | sed 's/^/  /'
fi

# ---- the verdict ---------------------------------------------------------
TA=$(mktemp) ; TB=$(mktemp)
printf '%s\n' "$EXPECT" > "$TA"
printf '%s\n' "$GOT"    > "$TB"
DIFF=$(diff "$TA" "$TB" 2>/dev/null)
rm -f "$TA" "$TB"

if [ $CARD_RC -ne 0 ]; then
  echo "RED: the dialect card has a citation that no longer resolves"
elif [ $IDX_RC -ne 0 ]; then
  echo "RED: the retrieval index names a path or an anchor that does not resolve"
elif [ "$EQ_OK" -eq 0 ]; then
  echo "RED: clauses.pl and clauses.py disagree about what a clause is"
elif [ "$EQL_OK" -eq 0 ]; then
  echo "RED: lint.pl and lint.py disagree about what a finding is"
elif [ "${PROBE#BAD}" != "$PROBE" ]; then
  echo "RED: the blocklist and the running store disagree about a reserved name"
elif [ -n "$MISSING" ]; then
  echo "these rules did not fire on selftest/traps.pl:"
  printf '%s\n' "$MISSING" | sed 's/^/  /'
  echo "RED: a rule has stopped matching, and the corpus above cannot see that"
elif [ -z "$DIFF" ]; then
  HARD=$(printf '%s\n' "$GOT" | grep -c HARD)
  WARN=$(printf '%s\n' "$GOT" | grep -c WARN)
  RULES=$(printf '%s\n' "$WANT" | sort -u | grep -c .)
  echo "all $RULES rules fired on selftest/traps.pl"
  echo "probe: $PROBE"
  # GREEN LAST, ALWAYS. test/run.sh discards each case's exit status and reads
  # the LAST LINE only -- a summary printed after it makes the case read red.
  echo "GREEN: $HARD HARD, $WARN WARN over $FILES files -- the expected set exactly"
else
  echo "the set changed (expected < , got > ):"
  printf '%s\n' "$DIFF" | sed 's/^/  /'
  echo "RED: cocolint's findings over the calibration corpus are not the pinned set"
fi
