#!/bin/sh
# Consulting a file REPLACES the clauses it put in the store last time.
#
# WHAT IS BEING PINNED. A tutorial is three processes -- train, test,
# predict -- against one store, and each of them consults the same file.
# The store used to APPEND, so the second process held two copies of every
# clause and a generator without a cut answered once per copy: a batch of
# three became twelve pictures (tutorials/tensor/README.md keeps the
# story, and the cut convention it forced). Now every clause a consult
# reads is owned by the file, under its real path, and the first clause
# of each predicate the file defines takes the file's old clauses of it
# out before going in. Three things follow, and each is checked:
#
#   THE SAME FILE TWICE IS ONE COPY. A second process counting the file's
#   facts finds the number the file holds.
#
#   WHAT THE PROGRAM ASSERTED STAYS. An assertz into a predicate the file
#   defines survives the next consult of the file, beside the file's own
#   clauses -- and comes first, since the file's are added again after it.
#   A model saved into the store is exactly this, under other names.
#
#   AN EDITED FILE IS THE NEW FILE. The previous version's clauses go with
#   it; a reused store no longer answers with the file as it was.
#
# On the wire the owner travels with the clause as '$from'(Path, Clause)
# in the same text column, which the fetch takes off again -- so the same
# three claims hold against a Zigurat server, and are checked there when
# one answers; a row written before this existed is a bare clause and
# nobody's to replace, so an older store reads as it always did.
#
#   sh test/reconsult.sh

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
[ -x "$C" ] || { echo "SKIP (build cocolog first)"; exit 0; }

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-64s %s\n' "$1" "$2"
  else
    printf 'FAIL %-64s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}
answer() { grep -aoE 'answer\(.*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

D=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-reconsult-XXXXXX")
trap 'rm -rf "$D"' EXIT INT TERM
F="$D/prog.pl"
two() {
  cat > "$F" <<'PL'
fact(1).
fact(2).
count(N) :- findall(X, fact(X), L), length(L, N).
facts(L) :- findall(X, fact(X), L).
PL
}
three() {
  cat > "$F" <<'PL'
fact(1).
fact(2).
fact(3).
count(N) :- findall(X, fact(X), L), length(L, N).
facts(L) :- findall(X, fact(X), L).
PL
}
q() { timeout 60 "$C" --kb reconsult --embed "$D/store" run "$F" "$1" 2>&1 | answer; }

echo "-- the same file, twice, into one embedded store"
two
check "the first process counts the file's two facts" \
  "$(q "count(N), write(answer(N)), nl")" "2"
check "the second still counts two: replaced, not appended" \
  "$(q "count(N), write(answer(N)), nl")" "2"

echo
echo "-- what the program asserted survives the next consult of the file"
check "a fact the program asserts joins the file's two" \
  "$(q "assertz(fact(9)), count(N), write(answer(N)), nl")" "3"
check "and is still there after the file is consulted again" \
  "$(q "count(N), write(answer(N)), nl")" "3"

echo
echo "-- an edited file is the new file; the asserted clause stays and comes first"
three
check "three from the file now, and the asserted one" \
  "$(q "count(N), write(answer(N)), nl")" "4"
check "the old version's clauses are gone, the asserted one is kept ahead" \
  "$(q "facts(L), write(answer(L)), nl")" "[9,1,2,3]"

echo
echo "-- one file under two spellings of its path is one file"
check "consulted as ./prog.pl from its own directory, nothing doubles" \
  "$(cd "$D" && timeout 60 "$C" --kb reconsult --embed "$D/store" run ./prog.pl "count(N), write(answer(N)), nl" 2>&1 | answer)" "4"

echo
echo "-- and the same three claims over the wire, when a server answers"
HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
if timeout 20 "$C" --host "$HOST" --tcp "$PORT" --timeout 10 --kb reconsult_case list >/dev/null 2>&1; then
  W() { timeout 120 "$C" --host "$HOST" --tcp "$PORT" --timeout 60 --kb reconsult_case run "$F" "$1" 2>&1 | answer; }
  timeout 60 "$C" --host "$HOST" --tcp "$PORT" --timeout 60 --kb reconsult_case forget >/dev/null 2>&1
  two
  check "wire: the first process counts two" \
    "$(W "count(N), write(answer(N)), nl")" "2"
  check "wire: the second still counts two" \
    "$(W "count(N), write(answer(N)), nl")" "2"
  check "wire: an asserted fact survives the third" \
    "$(W "assertz(fact(9)), count(N), write(answer(N)), nl")" "3"
  three
  check "wire: the edited file replaces its own, keeps the asserted" \
    "$(W "facts(L), write(answer(L)), nl")" "[9,1,2,3]"
  timeout 60 "$C" --host "$HOST" --tcp "$PORT" --timeout 60 --kb reconsult_case forget >/dev/null 2>&1
else
  echo "     (no Zigurat server at $HOST:$PORT -- the wire half not run)"
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $failures failure(s)"; exit 1
fi
