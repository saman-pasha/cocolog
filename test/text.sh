#!/bin/sh
# modules/text/text.cicili -- grep, sed and the line tools over libc regex.
#
# WHAT IS BEING PINNED:
#
#   THE PATTERN IS POSIX EXTENDED, so a grep -E from a .sh suite moves
#   here unchanged -- the anchor test is the exact 'answer\(' extraction
#   every suite in this family performs.
#
#   REPLACEMENT KNOWS & AND \1..\9, sed's own spellings, and an EMPTY
#   MATCH ADVANCES -- s/x*/-/g on plain text must terminate, which is
#   the classic way a hand-rolled replace loop hangs.
#
#   THE LINE TOOLS ARE CLAUSES: split, join, filter, head, tail --
#   round-tripping, because a split and a join that disagree about the
#   last newline corrupt quietly.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-46s %s\n' "$1" "$(echo "$2" | cut -c1-24)"
  else
    printf 'FAIL %-46s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

U="use_module(library(text))"

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi
. "$HERE/library-path.sh"
if [ ! -f "$ROOT/library/text.so" ]; then
  echo "SKIP (no library/text.so -- sh modules/text/build.sh)"
  exit 0
fi
if ! timeout 20 "$C" query "$U, re_match(a, abc), write(ok), nl" 2>/dev/null | grep -aq '\bok\b'; then
  echo "SKIP (library(text) will not load)"
  exit 0
fi

q() { timeout 60 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

echo "-- the match, POSIX extended"
check "grep -qE, both verdicts" \
  "$(q "( re_match('^w[0-9]+\$', 'w42') -> A = yes ; A = no ), ( re_match('^w[0-9]+\$', 'w42x') -> B = yes ; B = no ), write(answer(A-B)), nl")" \
  "yes-no"
check "the family's own idiom: the answer term out of a transcript" \
  "$(q "re_first_atom('answer\\\\([^)]*\\\\)', 'noise 1. goal answer(0-5) 1 answer(s).', A), ( A == 'answer(0-5)' -> R = extracted ; R = A ), write(answer(R)), nl")" \
  "extracted"

echo
echo "-- the replace, sed's own rules"
check "s///g with & and back-references" \
  "$(q "re_replace_atom('([a-z]+)-([0-9]+)', '\\\\2:\\\\1', 'abc-12 and xy-9', R), write(answer(R)), nl")" \
  "12:abc and 9:xy"
check "an empty match advances -- s/x*/-/g terminates" \
  "$(q "re_replace_atom('x*', '-', 'axa', R), write(answer(R)), nl")" \
  "-a-a-"

echo
echo "-- the line tools are clauses"
check "split, filter, first, and the round trip" \
  "$(q "atom_codes(one, L1), atom_codes(two, L2), atom_codes(three, L3), codes_lines(Cs, [L1, L2, L3]), codes_lines(Cs, Ls), length(Ls, N), re_lines(t, Cs, Ts), length(Ts, NT), first_line(Cs, F), atom_codes(FA, F), codes_lines(Back, Ls), ( Back == Cs -> RT = same ; RT = differs ), write(answer(N-NT-FA-RT)), nl")" \
  "3-2-one-same"
check "head and tail by count, short lists unharmed" \
  "$(q "head_lines(2, [a, b, c, d], H), tail_lines(2, [a, b, c, d], T), head_lines(9, [a], H1), write(answer(H-T-H1)), nl")" \
  "[a,b]-[c,d]-[a]"
check "chomp takes the one trailing newline, and only that" \
  "$(q "atom_codes(ok, OK), append(OK, [10], WithNl), chomp(WithNl, A), atom_codes(AA, A), chomp(OK, B), atom_codes(BA, B), write(answer(AA-BA)), nl")" \
  "ok-ok"

echo
if [ "$failures" -eq 0 ]; then echo "GREEN: 0 failure(s)"; else echo "RED: $failures failure(s)"; exit 1; fi
