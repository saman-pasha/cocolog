#!/bin/sh
# library(astar) -- shortest paths, held to an ORACLE and to walls.
#
# A pathfinder's classic failure is being almost right: a path that
# exists, connects, and costs one more than it should. So the strong
# check here is AGREEMENT -- on a hex grid with varied step costs, the
# heuristic search must answer the exact cost the zero-heuristic search
# (Dijkstra, the oracle this library also exports) answers, across a
# batch of start/goal pairs. The rest are the laws: paths connect step
# by step through the caller's own neighbor goal, walls force the
# detour they force, unreachable FAILS rather than erring, and the same
# question twice is the same path -- the pinned tiebreak, observed.
#
# The grid is library(hex)'s, because that is the caller this library
# was built for and the cross-library seam is worth one suite holding.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-56s %s\n' "$1" "$(echo "$2" | cut -c1-22)"
  else
    printf 'FAIL %-56s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

[ -x "$C" ] || { echo "SKIP (build cocolog first)"; exit 0; }

# The stage every check shares: a 9x9 hex disk, step cost 1 + ((Q*3+R*5) mod 3)
# so costs vary but are a pure function of the tile, and a wall.
STAGE="use_module(library(astar)), use_module(library(hex)),
  assertz(( on_grid(H) :- hex_distance(hex(0, 0), H, D), D =< 4 )),
  assertz(wall(hex(1, -1))), assertz(wall(hex(1, 0))), assertz(wall(hex(0, 1))),
  assertz(( cost_of(hex(Q, R), C) :- C is 1 + (Q * 3 + R * 5) mod 3 )),
  assertz(( step(A, B, C) :- hex_neighbor(A, _, B), on_grid(B), \\+ wall(B), cost_of(B, C) )),
  assertz(( heur(N, H) :- hex_distance(N, hex(3, 0), H) ))"

q() { timeout 120 "$C" query "$STAGE, $1" 2>/dev/null \
      | grep -aE '^answer\(.*\)$' | head -1 | sed 's/^answer(//; s/)$//'; }

echo "-- the laws"
check "start equals goal answers itself at zero" \
  "$(q "astar(hex(2, 2), hex(2, 2), step, heur, P, Cost), write(answer(P-Cost)), nl")" \
  "[hex(2,2)]-0"
check "a path connects, step by step, through the caller's goal" \
  "$(q "astar(hex(-3, 0), hex(3, 0), step, heur, P, _), findall(x, ( append(_, [A, B|_], P), \\+ step(A, B, _) ), Bad), length(Bad, N), write(answer(N)), nl")" "0"
check "its cost is the sum of its steps" \
  "$(q "astar(hex(-3, 0), hex(3, 0), step, heur, P, Cost), P = [_|Rest], findall(C, ( member(H, Rest), cost_of(H, C) ), Cs), sum_list(Cs, Sum), ( Sum =:= Cost -> X = agree ; X = differ(Cost, Sum) ), write(answer(X)), nl")" "agree"
check "the wall forces a detour longer than the crow flies" \
  "$(q "astar(hex(0, 0), hex(2, 0), step, heur, P, _), length(P, N), ( N > 3 -> X = detoured(N) ; X = through_the_wall(N) ), write(answer(X)), nl")" "detoured(6)"
check "unreachable fails, it does not err" \
  "$(q "assertz(( island_step(A, B, C) :- step(A, B, C), hex_distance(hex(0, 0), B, D), D =< 1 )), ( astar(hex(0, 0), hex(3, 0), island_step, heur, _, _) -> X = reached ; X = no_path ), write(answer(X)), nl")" "no_path"

echo
echo "-- the oracle: astar agrees with dijkstra on every pair"
check "twelve varied pairs, zero disagreements" \
  "$(q "findall(x, ( member(A-B, [hex(-3,0)-hex(3,0), hex(0,-4)-hex(0,4), hex(-2,-2)-hex(2,2), hex(4,-4)-hex(-4,4), hex(-4,0)-hex(2,2), hex(0,0)-hex(4,-2), hex(-1,-2)-hex(1,3), hex(3,-4)-hex(-3,4), hex(2,-4)-hex(-2,4), hex(-4,4)-hex(4,-4), hex(0,-2)-hex(0,3), hex(-2,0)-hex(3,-3)]), astar(A, B, step, heur, _, C1), shortest_path(A, B, step, _, C2), C1 =\\= C2 ), Bad), length(Bad, N), write(answer(N)), nl")" "0"

echo
echo "-- the pinned tiebreak"
check "the same question twice is the same path" \
  "$(q "astar(hex(-3, 2), hex(3, -2), step, heur, P1, _), astar(hex(-3, 2), hex(3, -2), step, heur, P2, _), ( P1 == P2 -> X = same ; X = DIFFER ), write(answer(X)), nl")" "same"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $failures failure(s)"
  exit 1
fi
