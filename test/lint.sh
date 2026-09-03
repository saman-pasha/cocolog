#!/bin/sh
# cocolint over the calibration corpus, and the two rewrites it stands on.
#
# THE LINTER IS COCOLOG. tools/cocolint/clauses.pl and lint.pl are the whole
# of it; the Python they replaced is gone, and with it the differential check
# that proved the rewrite faithful. WHAT REPLACED THAT CHECK IS TWO FIXTURES
# AND A PROBE, and the trade is worth naming: a second implementation catches
# a regression by disagreeing, which is powerful and goes stale the moment
# nobody maintains it; a fixture catches one by being SPECIFIC about cases
# that actually broke something, and the store probe checks against the
# interpreter itself, which is better ground truth than any second reader.
#
# Five things are checked, in cost order:
#
#   1. the dialect card's 42 citations still point at the code they claim
#   2. the retrieval index's paths and anchors resolve
#   3. clauses.pl reads selftest/reader.pl into exactly reader.expected --
#      every shape that has ever fooled a clause reader here
#   4. every rule still fires on selftest/traps.pl
#   5. the findings over the corpus are still the pinned set, and the
#      blocklist still matches what the running store says
#
# A FINDING IN 5 IS A LINTER BUG UNTIL SHOWN OTHERWISE, which is the point of
# calibrating against code known to work. The twenty-two that survived are
# listed below with the argument for each.
#
#   sh test/lint.sh
#
# The last line is GREEN or SKIP, because test/run.sh discards a shell case's
# exit status and reads only that line.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
cd "$ROOT" || exit 0

AGENT="$ROOT/tools/cocolint"
[ -f "$AGENT/lint.pl" ] || { echo "SKIP no tools/cocolint"; exit 0; }
[ -x "$ROOT/cocolog" ] || { echo "SKIP no binary -- the linter is cocolog now"; exit 0; }

# ---- 1. the dialect card's citations -------------------------------------
CARD=$(sh "$AGENT/tool.sh" card --check 2>&1)
CARD_RC=$?
echo "$CARD" | sed 's/^/  /'

# ---- 1b. and the three verdicts the checker can reach --------------------
#
# THE ACCEPTING CASE IS THE ONE WORTH PINNING. card.pl takes a moved anchor
# on trust when the anchor is UNIQUE in its file -- the range was never
# distinguishing anything there, so the code moving is a fact about the code
# and not a defect in the card. That is a deliberate loosening, and a
# loosening nobody tests is one that quietly becomes "never fails".
#
# All three verdicts run against a COPY of traps.jsonl with one cite broken
# each way, through $COCOLOG_TRAPS; the real card is never written to. The
# breakages are chosen for what they prove: N1's anchor occurs ONCE in
# lib/kb.cicili (drift -- accepted), A2's `coco_new_int' occurs THREE times in
# lib/term.cicili as a macro, a declaration and a definition (ambiguous --
# refused, because the range is the only thing choosing between them), and an
# anchor nobody wrote is gone (refused; that row needs rereading, not
# renumbering).
VERDICTS=ok
VTMP=$(mktemp -d)
vcase() {                       # vcase NAME SED WANT-RC WANT-TEXT
  sed "$2" "$AGENT/traps.jsonl" > "$VTMP/traps.jsonl"
  OUT=$(COCOLOG_TRAPS="$VTMP/traps.jsonl" sh "$AGENT/tool.sh" card --check 2>&1)
  RC=$?
  if [ "$RC" != "$3" ]; then
    VERDICTS="BAD $1: rc=$RC, wanted $3"
  elif ! printf '%s' "$OUT" | grep -q "$4"; then
    VERDICTS="BAD $1: no \"$4\" in the output"
  fi
}
# THE SEDS NAME A ROW AND A FILE, NOT A LINE RANGE, and that is not tidiness:
# written with the ranges in them they broke the first time the engine moved,
# which is the exact failure the checker under test exists to absorb. A test
# for a drift detector must not itself drift.
vcase drift     '/"id": "N1"/ s|"lib/kb.cicili:[0-9-]*"|"lib/kb.cicili:1-5"|'       0 "unique anchor, accepted"
vcase ambiguous '/"id": "A2"/ s|"lib/term.cicili:[0-9-]*"|"lib/term.cicili:1-5"|'   1 "the range is what picks the site"
# The anchor this one breaks used to be `unsupported directive: %s/%u',
# which is not in the engine any more -- a directive is a goal now. Any
# anchor that really exists does the job; this is S2's.
vcase gone      's|set_prolog_flag: double_quotes takes|NO SUCH ANCHOR HERE|'       1 "is GONE from"
rm -rf "$VTMP"
if [ "$VERDICTS" = ok ]; then
  echo "  cites  : a moved anchor is accepted, an ambiguous or missing one is not"
else
  echo "  cites  : $VERDICTS"
fi

# ---- 2. the retrieval index ----------------------------------------------
IDX=$(sh "$AGENT/tool.sh" index --check --no-run 2>&1)
IDX_RC=$?
printf '%s\n' "$IDX" | sed 's/^/  /'
echo

sh "$AGENT/tool.sh" build >/dev/null 2>&1 || { echo "SKIP blocklist would not build"; exit 0; }
sh "$AGENT/tool.sh" card --facts >/dev/null 2>&1 || { echo "SKIP traps.pl would not build"; exit 0; }

# ---- 3. the reader reads its fixture exactly ------------------------------
#
# EVERY SHAPE THAT HAS EVER FOOLED A CLAUSE READER HERE, with the answer
# checked in: DCG heads at arity+2, a pushback head, the 0'c literal that is
# four characters and not three, a prefix directive taking its argument
# without parentheses, a `.' after a digit, a Module:Head clause, a quoted
# head with a doubled quote, a `.' inside a quoted atom, commas inside
# nesting, a /* */ spanning clauses, and a final clause with no `.' at all.
RF="$AGENT/selftest/reader.pl"
RT=$(mktemp)
printf '%s\n' "$RF" > "$RT"
GOTR=$(COCO_CC_BATCH= COCO_CC_FILES="$RT" \
       COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY" \
       "$ROOT/cocolog" --local run "$AGENT/clauses.pl" cc_dump 2>&1 \
       | sed "s|^$AGENT/selftest/||")
rm -f "$RT"
WANTR=$(grep -v '^#' "$AGENT/selftest/reader.expected" | grep -v '^$')
RA=$(mktemp) ; RB=$(mktemp)
printf '%s\n' "$WANTR" > "$RA"
printf '%s\n' "$GOTR"  > "$RB"
RDIFF=$(diff "$RA" "$RB" 2>/dev/null)
rm -f "$RA" "$RB"
if [ -z "$RDIFF" ]; then
  echo "  reader: $(printf '%s\n' "$GOTR" | grep -c .) clauses of selftest/reader.pl, exactly as pinned"
else
  echo "  reader: DIFFERS from selftest/reader.expected (expected < , got > ):"
  printf '%s\n' "$RDIFF" | sed 's/^/    /'
fi
echo

# ---- 5. the findings themselves ------------------------------------------
CORPUS=$(ls "$ROOT"/tutorials/basics/[0-9]*.pl "$ROOT"/tutorials/library/[0-9]*.pl "$ROOT"/library/*.pl 2>/dev/null)
FILES=$(echo "$CORPUS" | wc -l | tr -d ' ')
OUT=$(sh "$AGENT/lint.sh" $CORPUS 2>&1)
SELF=$(sh "$AGENT/lint.sh" "$AGENT/selftest/traps.pl" 2>&1)

# Every finding as `file rule [trap]', with the line number dropped: a line
# that moves because somebody added a comment is not a change in what the
# linter found, and pinning it would fail this case for the wrong reason.
#
# `sed -E' AND NOT A BASIC EXPRESSION: `\|' and `\?' are GNU extensions to
# BRE, and BSD sed -- every macOS -- matches neither. It does not fail
# loudly either; the whole extraction comes back EMPTY, which reads as
# "every rule stopped firing" three sections down. ERE is the one dialect
# both seds agree on.
GOT=$(echo "$OUT" | sed -nE 's/^([^ :]+):[0-9]+:[0-9]+ (HARD|WARN) ([A-Z0-9]+) (\[[A-Z0-9]+\] )?.*/\1 \2 \3 \4/p' \
      | sed 's/ *$//' | sort)

# ---- the twenty-two, and why each is kept rather than silenced -----------
#
# FOURTEEN OF THE TWENTY-TWO ARE TUTORIALS TEACHING THE VERY TRAP THE RULE
# ENFORCES, which is the most satisfying kind of true positive there is --
# and a standing argument that the rules point at real divergences, because
# somebody thought each one worth a lesson:
#
#   basics/07  S1 [R1]  `( retract(seen(_)), fail ; true )', written to show
#                       that the failure-driven loop removes exactly ONE
#                       clause. The lesson IS the finding.
#   library/04 S1 [F1]  `~t~20|' inside a catch/3 demonstrating the refusal.
#   basics/09  S1 [C2]  `catch(atom_length(_,_), error(_, context(Who,_)), …)',
#                       written to show the half of C2 that surprises people:
#                       the pattern does not fail to match, it matches by
#                       BINDING an unbound context slot, so the handler runs
#                       and reads back something it invented. The lesson says
#                       so in the comment above the line.
#   37-lint    S1 [H1] x2  the tutorial FOR the linter, writing `lit(halt)'
#                       as a pattern term. H1 looks for halt after one of
#                       ` \t\n,(;>' and a `(' is one of those, so naming the
#                       trap in the notation that catches it trips it. The
#                       alternative is to obscure the pattern the lesson
#                       exists to show, which is a worse trade than one line
#                       in this list.
#   basics/04, 21-bigint, 25-der  A1 x6  `1000000000000000000 * 997' and the
#                       wrapped answer, which 25-der calls "a wrong answer
#                       returned confidently".
#   38-main    S1 [P1]  the tutorial FOR argv, demonstrating that a flag
#                       cocolog does not have FAILS -- which it does by
#                       asking for one, `current_prolog_flag(bounded, _)'.
#                       P1 is right that this is a flag with no answer; the
#                       lesson's whole claim is that it has none. Naming the
#                       trap in the notation that catches it, exactly as
#                       37-lint does above.
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
#                       failure branch where the other 48 tutorials fail.
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
# THREE ARE NO-OP IMPORTS already named in CLAUDE.md:
#
#   26-x509, 27-ca, library/astar.pl  T1  use_module for a tier-1 library.
#
# AND ONE IS AN EXTENSION POINT THAT IS NOT DECLARED AS ONE:
#
#   39-tensor-expr  N1  defines expr//2, which library(tensor_expr) also
#                       defines -- ON PURPOSE. The grammar is open to a file's
#                       own clauses and the lesson is exactly that: one line
#                       of the tutorial adds `double(A)' to it. N1 is right
#                       about the mechanism -- consult APPENDS, so the two
#                       sets merge and which is tried first depends on how the
#                       file is run -- and it is harmless HERE only because
#                       every clause of the library's grammar cuts on a
#                       different functor, so `double(A)' reaches the file's
#                       clause either way. A library that wanted this excused
#                       would DECLARE the hook the way library(httpd) declares
#                       httpd_page/3, `H :- fail.', which the blocklist's
#                       shape 4 excuses in both halves. library(tensor_expr)
#                       does not, so the finding stands and is pinned; that is
#                       the owner's call to make, not the linter's.
EXPECT=$(cat <<'EOF'
library/astar.pl WARN T1
tutorials/basics/04-arithmetic.pl WARN A1 [A2]
tutorials/basics/04-arithmetic.pl WARN A1 [A2]
tutorials/basics/07-assert-and-retract.pl HARD S1 [R1]
tutorials/basics/09-exceptions.pl HARD S1 [C2]
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
tutorials/library/37-lint.pl HARD S1 [H1]
tutorials/library/37-lint.pl HARD S1 [H1]
tutorials/library/38-main.pl HARD S1 [P1]
tutorials/library/39-tensor-expr.pl HARD N1
EOF
)

echo "$OUT" | grep -E 'HARD|WARN' | grep -v '^ ' | sed 's/^/  /'
echo

# ---- every rule still FIRES ----------------------------------------------
#
# A CORPUS OF CORRECT CODE CANNOT SHOW THAT A RULE WORKS, only that it does
# not misfire -- so a rule whose pattern has quietly stopped matching is
# invisible above. selftest/traps.pl walks into every divergence on purpose,
# and this asserts each one is still caught. ERE here for the same reason
# as the extraction above: on BSD sed the BRE spelling matches nothing and
# reports every rule as dead.
FIRED=$(printf '%s\n' "$SELF" \
        | sed -nE 's/^[^ ]+ (HARD|WARN) ([A-Z0-9]+) (\[[A-Z0-9]+\])?.*/\2 \3/p' \
        | sed 's/ *$//' | sort -u)
WANT=$(sh "$AGENT/tool.sh" card --patterns | awk '{print "S1 [" $1 "]"}' | sort -u)
# D1 IS NOT IN THIS LIST ANY MORE. The rule retired with the divergence it
# named: a directive is a goal now, and an unsupported one is reported at
# load time rather than aborting the consult. What is left of that row is
# D2 -- `:- table p/1.' does not PARSE -- which is an S1 pattern and comes
# in through `card --patterns' above.
WANT="N1
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
# GENERATED FROM blocklist.pl, THE FACTS, not from the JSON -- one line per
# name and the same list the linter reads, so the probe cannot be testing a
# different extraction from the one it is checking. Operator names and the
# arity -1 control constructs are skipped: `=(_,_).' is not a clause anybody
# writes, and a construct is blocked at every arity so no single arity
# probes it.
gen() {   # gen FUNCTOR FILE
  awk -F"'" -v want="$1" '
    index($1, want "(") == 1 {
      n = $2; a = $3; gsub(/[^0-9-]/, "", a)
      if (a + 0 < 0) next
      if (n !~ /^[a-z][a-zA-Z0-9_]*$/) next
      if (seen[n "/" a]++) next
      if (a + 0 == 0) { print n "." ; next }
      s = ""
      for (i = 0; i < a + 0; i++) s = s (i ? ",_" : "_")
      print n "(" s ")."
    }' "$AGENT/blocklist.pl"
}
{ echo "myprog_marker(1)."; gen cl_t1p; } > "$PD/clauses.pl"
{ echo "myprog_marker(1)."; gen cl_t1c; } > "$PD/ctable.pl"
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
  echo "RED: the dialect card cites code that is gone, or cannot be told from its namesakes"
elif [ "${VERDICTS#BAD}" != "$VERDICTS" ]; then
  echo "RED: card.pl no longer sorts a moved citation from a broken one"
elif [ $IDX_RC -ne 0 ]; then
  echo "RED: the retrieval index names a path or an anchor that does not resolve"
elif [ -n "$RDIFF" ]; then
  echo "RED: clauses.pl no longer reads its own fixture the way it is pinned"
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
