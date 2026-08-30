#!/bin/sh
# The engine's COMPLEXITY, which no other case here checks.
#
# Every other test asks whether an answer is right. These ask whether it
# arrives in the time the algorithm says it should -- and they exist because
# a term representation can be perfectly correct and quadratic, which is
# exactly what this one was until `coco_make' started dereferencing the
# arguments it stores.
#
# THE GUARD IS A TIMEOUT WITH A HUNDRED-FOLD MARGIN, not a stopwatch with a
# threshold. `between(1, 100000, _), fail' takes about 230ms here and took
# MINUTES before the fix; a limit of 30 seconds passes on any machine that
# can run the suite at all and fails the moment the chain comes back. A
# ratio test between two sizes would be more precise and would also fail on
# a loaded CI box, which is a worse trade for a property this coarse.
#
# WHAT WENT WRONG, so the next person recognises it: a compound's argument
# was stored as a REF cell pointing at whatever index it was handed, and
# `coco_arg' hands back a REF. So every structure built on a previous one --
# the continuation `$k(Goal, Barrier, Rest)' above all -- added a link, and
# `coco_deref' walked the whole chain on every engine step. A recursion
# 3000 deep left a chain 8999 links long and 85% of the program's
# instructions were in deref.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"

# MILLISECONDS, PORTABLY. `date +%s%3N` is GNU; BSD date prints the
# `3N` as literal text, the shell arithmetic on it collapses, and the
# shape check below then compared garbage with garbage -- which read as
# quadratic and made this case RED on every Mac while the engine was
# fine. perl ships on both.
ms() { perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000'; }

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-52s %s\n' "$1" "$2"
  else
    printf 'FAIL %-52s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi

D=/tmp/coco-engine-test
rm -rf "$D"; mkdir -p "$D"

# ---- deep backtracking stays linear ---------------------------------

cat > "$D/between.pl" <<'PL'
main :- ( between(1, 100000, _), fail ; true ), write(done), nl.
PL
got=$(timeout 30 "$C" run "$D/between.pl" main 2>/dev/null | tail -1)
check "100000 solutions from between/3 finish at all" "$got" "done"

# findall over the same range: the collection walks the continuation too,
# and was 9.2 SECONDS at 20000 where it is now 53ms.
cat > "$D/findall.pl" <<'PL'
main :- findall(X, between(1, 100000, X), L), length(L, 100000), write(done), nl.
PL
got=$(timeout 30 "$C" run "$D/findall.pl" main 2>/dev/null | tail -1)
check "and findall over 100000 collects them" "$got" "done"

# THE SHAPE, not just the total. Ten times the work in far less than a
# hundred times the time is the difference between linear and quadratic,
# and the bound is loose enough that only the quadratic case can fail it.
small=$( { cat > "$D/s.pl" <<'PL'
main :- ( between(1, 10000, _), fail ; true ).
PL
  S=$(ms); timeout 60 "$C" run "$D/s.pl" main >/dev/null 2>&1
  E=$(ms); echo $((E-S)); } )
big=$( { cat > "$D/b.pl" <<'PL'
main :- ( between(1, 100000, _), fail ; true ).
PL
  S=$(ms); timeout 120 "$C" run "$D/b.pl" main >/dev/null 2>&1
  E=$(ms); echo $((E-S)); } )
printf '     10000 in %sms, 100000 in %sms\n' "$small" "$big"
check "ten times the range costs well under ten times squared" \
  "$(awk -v a="$small" -v b="$big" 'BEGIN { print (a > 0 && b < a * 25) ? "linear-ish" : "quadratic" }')" \
  "linear-ish"

# ---- deep recursion without backtracking ----------------------------
# This was always fast, and is here so a future fix to the above cannot
# quietly trade it away.
cat > "$D/deep.pl" <<'PL'
count(0) :- !.
count(N) :- M is N - 1, count(M).
main :- count(500000), write(done), nl.
PL
got=$(timeout 30 "$C" run "$D/deep.pl" main 2>/dev/null | tail -1)
check "500000 deep deterministic recursion still finishes" "$got" "done"

# ---- and the answers are still the answers --------------------------
# A representation change that made everything fast and one thing wrong
# would pass every case above. sub_atom/5 and findall/3 both build terms on
# terms, which is where the dereferencing happens.
q() { timeout 60 "$C" query "$1" 2>/dev/null \
      | grep -a '^answer(' | head -1 | sed 's/^answer(//; s/)$//'; }
check "a shared variable is still shared after building" \
  "$(q "X = f(Y), Y = 7, X = f(Z), write(answer(Z)), nl")" "7"
check "an unbound variable in a structure still binds later" \
  "$(q "T = p(A, A), T = p(1, B), write(answer(B)), nl")" "1"
check "and backtracking still unbinds through a structure" \
  "$(q "( member(X, [1,2,3]), T = q(X), T = q(2) -> write(answer(X))
        ; write(answer(none)) ), nl")" "2"
check "findall copies, so its answers outlive the search" \
  "$(q "findall(A-B, member(A-B, [1-x, 2-y]), L), write(answer(L)), nl")" "[1-x,2-y]"

rm -rf "$D"
echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
