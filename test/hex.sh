#!/bin/sh
# library(hex) -- hexagonal-grid arithmetic, held to its IDENTITIES.
#
# Hex math is the rare surface whose correctness is a set of closed
# formulas: a ring at radius R has exactly 6R hexes, a disk exactly
# 1+3R(R+1), a line exactly distance+1, every neighbor is at distance
# one, six left-rotations are the identity, and offset and pixel
# conversions ROUND-TRIP. So this file checks the formulas over whole
# neighborhoods rather than spot values -- a spot value can be right by
# accident; forall over a 7x7 window cannot.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-56s %s\n' "$1" "$(echo "$2" | cut -c1-20)"
  else
    printf 'FAIL %-56s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

[ -x "$C" ] || { echo "SKIP (build cocolog first)"; exit 0; }

U="use_module(library(hex))"
q() { timeout 60 "$C" query "$U, $1" 2>/dev/null \
      | grep -aE '^answer\(.*\)$' | head -1 | sed 's/^answer(//; s/)$//'; }

echo "-- directions and neighbors"
check "six directions, nondeterministically" \
  "$(q "findall(D, hex_direction(D, _), L), length(L, N), write(answer(N)), nl")" "6"
check "every neighbor is at distance one" \
  "$(q "findall(N, ( hex_neighbor(hex(2, -1), _, N), hex_distance(hex(2, -1), N, 1) ), L), length(L, X), write(answer(X)), nl")" "6"
check "opposite directions cancel" \
  "$(q "hex_neighbor(hex(4, 4), 0, N1), hex_neighbor(N1, 3, N2), write(answer(N2)), nl")" "hex(4,4)"

echo
echo "-- distance is a metric"
check "the worked example" \
  "$(q "hex_distance(hex(0, 0), hex(3, -2), D), write(answer(D)), nl")" "3"
check "and symmetric over a window" \
  "$(q "findall(x, ( between(-2, 2, Q), between(-2, 2, R), hex_distance(hex(0, 1), hex(Q, R), D1), hex_distance(hex(Q, R), hex(0, 1), D2), D1 =\\= D2 ), Bad), length(Bad, N), write(answer(N)), nl")" "0"

echo
echo "-- rings and disks obey their formulas"
check "ring 1 has 6, ring 3 has 18" \
  "$(q "hex_ring(hex(0, 0), 1, L1), length(L1, A), hex_ring(hex(5, -3), 3, L3), length(L3, B), write(answer(A-B)), nl")" "6-18"
check "every ring hex is at exactly its radius" \
  "$(q "hex_ring(hex(1, 1), 3, L), findall(x, ( member(H, L), \\+ hex_distance(hex(1, 1), H, 3) ), Bad), length(Bad, N), write(answer(N)), nl")" "0"
check "disk 2 has 19, disk 3 has 37" \
  "$(q "hex_disk(hex(0, 0), 2, L2), length(L2, A), hex_disk(hex(-4, 7), 3, L3), length(L3, B), write(answer(A-B)), nl")" "19-37"
check "a disk is its rings, counted" \
  "$(q "hex_disk(hex(0, 0), 3, D), length(D, N), hex_ring(hex(0, 0), 0, R0), hex_ring(hex(0, 0), 1, R1), hex_ring(hex(0, 0), 2, R2), hex_ring(hex(0, 0), 3, R3), length(R0, A), length(R1, B), length(R2, C2), length(R3, E), M is A + B + C2 + E, ( N =:= M -> X = agree ; X = differ(N, M) ), write(answer(X)), nl")" "agree"

echo
echo "-- lines"
check "a line is distance+1 hexes, endpoints included" \
  "$(q "hex_line(hex(0, 0), hex(3, -2), L), length(L, N), L = [First|_], last(L, Last), write(answer(N-First-Last)), nl")" "4-hex(0,0)-hex(3,-2)"
check "every step of a line moves distance one" \
  "$(q "hex_line(hex(-2, 1), hex(4, -3), L), findall(x, ( append(_, [A, B|_], L), \\+ hex_distance(A, B, 1) ), Bad), length(Bad, N), write(answer(N)), nl")" "0"

echo
echo "-- rotation"
check "six left turns are the identity" \
  "$(q "hex_rotate(left, hex(3, -1), A), hex_rotate(left, A, B), hex_rotate(left, B, C0), hex_rotate(left, C0, D), hex_rotate(left, D, E), hex_rotate(left, E, F), write(answer(F)), nl")" "hex(3,-1)"
check "a right turn undoes a left" \
  "$(q "hex_rotate(left, hex(-2, 5), A), hex_rotate(right, A, B), write(answer(B)), nl")" "hex(-2,5)"

echo
echo "-- offsets round-trip, all four layouts, negatives included"
for layout in oddr evenr oddq evenq; do
  check "$layout over a 7x7 window" \
    "$(q "findall(x, ( between(-3, 3, Q), between(-3, 3, R), hex_offset($layout, hex(Q, R), Col, Row), offset_hex($layout, Col, Row, H2), H2 \\== hex(Q, R) ), Bad), length(Bad, N), write(answer(N)), nl")" "0"
done

echo
echo "-- pixels round-trip, both orientations"
for orient in pointy flat; do
  check "$orient at size 32" \
    "$(q "findall(x, ( between(-3, 3, Q), between(-3, 3, R), hex_pixel($orient, 32, hex(Q, R), X, Y), pixel_hex($orient, 32, X, Y, H2), H2 \\== hex(Q, R) ), Bad), length(Bad, N), write(answer(N)), nl")" "0"
done

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $failures failure(s)"
  exit 1
fi
