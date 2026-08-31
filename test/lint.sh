#!/bin/sh
# cocolint over the calibration corpus: the 47 basics+library tutorials and
# the 10 library/*.pl, plus traps.py --check over the dialect card's citations.
#
# A FINDING HERE IS A LINTER BUG UNTIL SHOWN OTHERWISE, which is the whole
# point of calibrating against code known to work. The ten that survived are
# listed below with the argument for each, and the case pins the exact SET
# rather than a count: a new finding and a moved one both show up, where two
# findings that cancel out in a total would not.
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
[ -f "$AGENT/lint.py" ] || { echo "SKIP no tools/coco-agent"; exit 0; }

# ---- the dialect card's citations still point at the code they claim ------
CARD=$(python3 "$AGENT/traps.py" --check 2>&1)
CARD_RC=$?
echo "$CARD" | sed 's/^/  /'
echo

python3 "$AGENT/build.py" >/dev/null 2>&1 || { echo "SKIP blocklist would not build"; exit 0; }

CORPUS=$(ls "$ROOT"/tutorials/basics/[0-9]*.pl "$ROOT"/tutorials/library/[0-9]*.pl "$ROOT"/library/*.pl 2>/dev/null)
FILES=$(echo "$CORPUS" | wc -l | tr -d ' ')
OUT=$(python3 "$AGENT/lint.py" $CORPUS 2>&1)

# Every finding as `file rule [trap]', with the line number dropped: a line
# that moves because somebody added a comment is not a change in what the
# linter found, and pinning it would make this case fail for the wrong reason.
GOT=$(echo "$OUT" | sed -n 's/^\([^ :]*\):[0-9]*:[0-9]* \(HARD\|WARN\) \([A-Z0-9]*\) \(\[[A-Z0-9]*\] \)\?.*/\1 \2 \3 \4/p' \
      | sed 's/ *$//' | sort)

# ---- the seventeen, and why each is kept rather than silenced ------------
#
# TEN OF THE SEVENTEEN ARE TUTORIALS TEACHING THE VERY TRAP THE RULE
# ENFORCES, which is the most satisfying kind of true positive there is --
# and a standing argument that the rules are pointed at real divergences,
# because somebody thought each one worth a lesson:
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

# Two temporary files rather than a process substitution: test/run.sh runs
# each case with `sh', which on Debian is dash, and dash has no <( ).
TA=$(mktemp) ; TB=$(mktemp)
printf '%s\n' "$EXPECT" > "$TA"
printf '%s\n' "$GOT"    > "$TB"
DIFF=$(diff "$TA" "$TB" 2>/dev/null)
rm -f "$TA" "$TB"

# ---- and every rule still FIRES ------------------------------------------
#
# A CORPUS OF CORRECT CODE CANNOT SHOW THAT A RULE WORKS, only that it does
# not misfire -- so a rule whose pattern has quietly stopped matching is
# invisible above. selftest/traps.pl walks into every divergence on purpose,
# and this asserts that each one is still caught. It found two of its own:
# `\x41\' ends a string with a backslash, which cocolog forbids, so the
# literal ran to end of file and every later rule saw its match inside a
# quote; and L1's `'[|]'' is a quoted atom by construction, so it needed the
# same `scan: text' that F1 and E1 have.
SELF="$AGENT/selftest/traps.pl"
FIRED=$(python3 "$AGENT/lint.py" "$SELF" 2>&1 \
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
# ---- the oracle and rule N1 must agree, when there is a binary to ask ----
#
# TWO MECHANISMS FOR ONE QUESTION, and neither is sound alone. N1 reads a
# static blocklist extracted from source; the oracle asks the running binary
# which predicates the store calls the program's own, which is a different
# thing entirely (lib/builtins.cicili:1731-1753). They agree on all 58 files,
# and the one place they used to differ is the reason blocklist.json now
# records the hooks: 16-httpd.pl's httpd_page/3 is a collision that is MEANT.
#
# SKIPPED WITHOUT A BINARY rather than passed. The rest of this case needs
# none, which is why it runs in a tree that has never been built.
ORACLE="not run (no binary)"
if [ -x "$ROOT/cocolog" ]; then
  DIS=0
  for f in $CORPUS; do
    O=$(sh "$AGENT/oracle.sh" "$f" 2>/dev/null | sed -n 's/^COLLIDED  \([^ ]*\) .*/\1/p' | sort -u)
    L=$(python3 "$AGENT/lint.py" "$f" 2>/dev/null | sed -n "s/^.*HARD N1 \`\([^']*\)'.*/\1/p" | sort -u)
    if [ "$O" != "$L" ]; then
      DIS=$((DIS+1))
      echo "  oracle/N1 disagree on $f: oracle=[$(echo $O)] N1=[$(echo $L)]"
    fi
  done
  if [ "$DIS" -eq 0 ]; then
    ORACLE="agrees with N1 on all $FILES"
  else
    ORACLE="DISAGREES with N1 on $DIS file(s)"
  fi
fi

if [ $CARD_RC -ne 0 ]; then
  echo "RED: the dialect card has a citation that no longer resolves"
elif [ -n "$MISSING" ]; then
  echo "these rules did not fire on selftest/traps.pl:"
  printf '%s\n' "$MISSING" | sed 's/^/  /'
  echo "RED: a rule has stopped matching, and the corpus above cannot see that"
elif [ "${ORACLE#DISAGREES}" != "$ORACLE" ]; then
  echo "RED: the collision oracle and rule N1 do not agree"
elif [ -z "$DIFF" ]; then
  HARD=$(printf '%s\n' "$GOT" | grep -c HARD)
  WARN=$(printf '%s\n' "$GOT" | grep -c WARN)
  RULES=$(printf '%s\n' "$WANT" | sort -u | grep -c .)
  echo "all $RULES rules fired on selftest/traps.pl; oracle $ORACLE"
  # GREEN LAST, ALWAYS. test/run.sh discards each case's exit status and reads
  # the LAST LINE only -- a summary line printed after it makes the whole case
  # read as red, which is how this one first did.
  echo "GREEN: $HARD HARD, $WARN WARN over $FILES files -- the expected set exactly"
else
  echo "the set changed (expected < , got > ):"
  printf '%s\n' "$DIFF" | sed 's/^/  /'
  echo "RED: cocolint's findings over the calibration corpus are not the pinned set"
fi
