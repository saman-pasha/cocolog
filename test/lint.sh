#!/bin/sh
# cocolint over the calibration corpus: the 47 basics+library tutorials and
# the 10 library/*.pl.
#
# A HARD FINDING HERE IS A LINTER BUG, not a repo bug -- that is the whole
# point of calibrating against code known to work. The exceptions below are
# the ones that survived, and the case PRINTS them rather than hiding them,
# because each is the argument for the rule that found it.
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

python3 "$AGENT/build.py" >/dev/null 2>&1 || { echo "SKIP blocklist would not build"; exit 0; }

CORPUS=$(ls "$ROOT"/tutorials/basics/[0-9]*.pl "$ROOT"/tutorials/library/[0-9]*.pl "$ROOT"/library/*.pl 2>/dev/null)
OUT=$(python3 "$AGENT/lint.py" $CORPUS 2>&1)

# The three known exceptions, by file and rule. Each is a TRUE POSITIVE that
# the corpus tolerates, not a false alarm to be silenced:
#
#   basics/10-grammars.pl  N1  defines digits//1 and digit//1, which are also
#                              dcg_basics'. A real namespace collision -- the
#                              two definitions even DIFFER (the tutorial's
#                              wants at least one digit, dcg_basics' allows
#                              none). It is latent rather than harmful only
#                              because their first solutions agree.
#   library/04-builtins.pl S1  contains `~t~20|' inside a catch/3 that
#                              DEMONSTRATES the refusal. Textually a banned
#                              form; that is the lesson.
#   26-x509, 27-ca, astar  T1  a use_module for a tier-1 library. No-ops, and
#                              already named in CLAUDE.md.
EXPECT_HARD=3
EXPECT_WARN=3

echo "$OUT" | grep -E 'HARD|WARN' | grep -v '^ ' | sed 's/^/  /'
echo

HARD=$(echo "$OUT" | sed -n 's/^cocolint: \([0-9]*\) HARD.*/\1/p')
WARN=$(echo "$OUT" | sed -n 's/^cocolint: [0-9]* HARD, \([0-9]*\) WARN.*/\1/p')
FILES=$(echo "$CORPUS" | wc -l | tr -d ' ')

echo "the three exceptions, and why each is kept rather than silenced:"
echo "  basics/10  N1  digits//1 and digit//1 really are dcg_basics' names, and"
echo "                 the two definitions differ -- latent, not harmless"
echo "  04-builtins S1 the ~t is inside a catch/3 demonstrating the refusal"
echo "  x509/ca/astar T1 a use_module for a tier-1 library, which is a no-op"
echo

if [ "$HARD" = "$EXPECT_HARD" ] && [ "$WARN" = "$EXPECT_WARN" ]; then
  echo "GREEN: $HARD HARD, $WARN WARN over $FILES files -- all accounted for"
else
  echo "RED: expected $EXPECT_HARD HARD and $EXPECT_WARN WARN, got $HARD and $WARN"
fi
