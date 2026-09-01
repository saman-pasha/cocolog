#!/bin/sh
# `-s SCRIPT': load a script as a module, prove main, and SAY SO IN THE
# EXIT CODE.
#
# WHY THE FLAG EXISTS when `query "use_module('f'), main"` already runs
# a file: `query` answers 0 for "the engine ran", so a goal that merely
# FAILED -- a red test suite, say -- exits 0 and every shell driver above
# it must grep the transcript for a verdict line. `-s' is the same load
# with the honest exit: 0 exactly when `main' PROVED, 1 when it failed,
# raised, or the file would not consult. A test case in cocolog is then
# `cocolog -s test/case.pl` and the exit code IS the verdict -- which is
# what CivV's converted suite stands on.
#
# The one syntactic wrinkle is pinned here too: `-s' begins with a dash
# and is a COMMAND, chosen to read as every interpreter's script flag,
# so the option loop must hand it through rather than die on it as an
# unknown option -- with options before it still parsed (`--local -s f').

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-script-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-52s\n' "$1"
  else
    printf 'FAIL %-52s got [%s] want [%s]\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$ROOT/cocolog" ]; then
  echo "SKIP (no cocolog; make)"
  exit 0
fi
C="$ROOT/cocolog"

# ---- a green main: the output is the script's, the exit is 0 --------

cat > "$OUT/green.pl" <<'EOF'
greeting(hello).
main :- greeting(G), write(G), nl.
EOF
got=$("$C" -s "$OUT/green.pl" 2>&1); rc=$?
check "a proved main exits 0" "$rc" "0"
check "and the output is the script's own" "$got" "hello"

# ---- a red main: PLAIN FAILURE is exit 1, the fix over `query' ------

cat > "$OUT/red.pl" <<'EOF'
main :- 1 =:= 2.
EOF
"$C" -s "$OUT/red.pl" > /dev/null 2>&1; rc=$?
check "a failed main exits 1 -- where query says 0" "$rc" "1"

# ---- an exception is 1 too, said on stderr --------------------------

cat > "$OUT/throw.pl" <<'EOF'
main :- throw(sorrow).
EOF
# TWO, NOT ONE, and it is SWI's two: `swipl -q -g main -t halt' answers 0
# proved, 1 failed and 2 threw, so a caller can tell the goal that said no
# from the goal that broke. This used to be 1 either way.
err=$("$C" -s "$OUT/throw.pl" 2>&1 >/dev/null); rc=$?
check "an uncaught exception exits 2, as swipl does" "$rc" "2"
case "$err" in
  *sorrow*) check "and names the ball on stderr" yes yes ;;
  *)        check "and names the ball on stderr" "$err" "*sorrow*" ;;
esac

# ---- a file that is not there, and a missing argument ---------------

"$C" -s "$OUT/nosuch.pl" > /dev/null 2>&1; rc=$?
check "a missing file exits 1" "$rc" "1"
"$C" -s > /dev/null 2>&1; rc=$?
check "-s with no file exits 1" "$rc" "1"

# ---- options before the flag still parse ----------------------------

got=$("$C" --local -s "$OUT/green.pl" 2>&1); rc=$?
check "--local -s parses: the dash verb ends the options" "$rc-$got" "0-hello"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  exit 1
fi
