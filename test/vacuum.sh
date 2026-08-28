#!/bin/sh
# The store's two hygiene verbs -- forget and the vacuum -- in both
# arrangements, with the vacuum's gate.
#
# WHAT IT IS CHECKING, and why each part is there:
#
#   FORGET KEEPS ITS CONTRACT CHUNKED. A whole-base forget runs predicate
#   at a time (see cmd_forget in cocolog.cicili for the measured why); the
#   count, the emptiness -- declarations included -- and idempotence must
#   not depend on how the deleting is carved.
#
#   THE VERB RECLAIMS AND ONLY RECLAIMS. `forget' deletes every clause; the
#   vacuum after it must answer the same live count twice -- an unchanged
#   second answer is the statement that there was nothing left to reclaim --
#   and a knowledge base consulted AFTER a vacuum must answer queries exactly
#   as it would in a store that was never vacuumed. Live rows are untouched;
#   that is what makes it a vacuum and not an emptying.
#
#   THE BUILTIN IS GATED. `vacuum_kb' without `--vacuum' must raise
#   permission_error(vacuum, knowledge_base, _) -- a refusal, never a quiet
#   success -- because the pass spends the store's point-in-time reads and
#   that is the operator's decision, not the program's. With `--vacuum' it
#   must succeed and answer the live count.
#
# The embedded half always runs, the store being in the one binary; the wire
# half SKIPs without a server, because "no server here" and "the vacuum is
# wrong" are different findings.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-vacuum-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-52s %s\n' "$1" "$2"
  else
    printf 'FAIL %-52s got [%s] want [%s]\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

printf 'p(1).\np(2).\np(3).\nq(a).\nq(b).\n:- dynamic d/1.\n' > "$OUT/facts.pl"

# One arrangement's whole story, parameterised on how to reach the store.
# $1 is a label, the rest is the cocolog command up to but excluding the verb.
exercise() {
  label=$1; shift

  # FORGET'S CONTRACT FIRST, because a whole-base forget is no longer one
  # DELETE: it goes predicate at a time -- collected from the clause rows
  # and the declarations, each in a transaction of its own, a final sweep
  # for the rest -- so no single transaction outruns a client's timeout
  # (the one-DELETE forget measured ~10ms a row and a client that gave up
  # mid-call left the base wedged behind the abandoned locks). The
  # contract that must survive the chunking: the count is the clause
  # count, everything goes -- a declared-but-empty dynamic included, the
  # half only the declarations know -- and a second forget finds nothing.
  "$@" consult "$OUT/facts.pl" >/dev/null 2>&1
  forgot=$("$@" forget 2>&1)
  check "$label: forget answers the clause count" \
    "$(echo "$forgot" | grep -c '^forgot 5 clause')" "1"
  gone=$("$@" query "catch(p(_), error(existence_error(procedure, _), _), (write(gone), nl))" 2>&1)
  check "$label: a forgotten predicate is gone, not empty" \
    "$(echo "$gone" | grep -c '^gone$')" "1"
  dgone=$("$@" query "catch(d(_), error(existence_error(procedure, _), _), (write(gone), nl))" 2>&1)
  check "$label: the declared-but-empty dynamic went too" \
    "$(echo "$dgone" | grep -c '^gone$')" "1"
  again=$("$@" forget 2>&1)
  check "$label: and a second forget finds nothing" \
    "$(echo "$again" | grep -c '^forgot 0 clause')" "1"

  "$@" consult "$OUT/facts.pl" >/dev/null 2>&1
  "$@" forget >/dev/null 2>&1

  first=$("$@" vacuum 2>&1)
  second=$("$@" vacuum 2>&1)
  check "$label: the vacuum verb reclaims" \
    "$(echo "$first" | grep -c '^vacuumed; ')" "1"
  check "$label: and a second pass finds nothing more" \
    "$(test "$first" = "$second" && echo same)" "same"

  refused=$("$@" query "catch(vacuum_kb, error(permission_error(vacuum, knowledge_base, _), _), (write(refused), nl))" 2>&1)
  check "$label: vacuum_kb without --vacuum is refused" \
    "$(echo "$refused" | grep -c '^refused$')" "1"

  allowed=$("$@" --vacuum query "vacuum_kb(Live), integer(Live), write(allowed), nl" 2>&1)
  check "$label: and with --vacuum it answers the live count" \
    "$(echo "$allowed" | grep -c '^allowed$')" "1"

  "$@" consult "$OUT/facts.pl" >/dev/null 2>&1
  after=$("$@" --vacuum query "vacuum_kb, findall(X, p(X), L), write(L), nl" 2>&1)
  check "$label: live clauses survive the pass" \
    "$(echo "$after" | grep -c '^\[1,2,3\]$')" "1"
  "$@" forget >/dev/null 2>&1
}

# ---- embedded: the store inside the process -------------------------
if [ -x "$ROOT/cocolog" ]; then
  echo "the embedded arrangement"
  exercise embed "$ROOT/cocolog" --kb vacuum_test --embed "$OUT/store"
else
  echo "embed: SKIP (no cocolog; make)"
fi

# ---- wire: the store behind a server --------------------------------
HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
if [ -x "$ROOT/cocolog" ] && \
   timeout 20 "$ROOT/cocolog" --kb vacuum_test --host "$HOST" --tcp "$PORT" \
     --timeout 10 list >/dev/null 2>&1; then
  echo "the wire arrangement"
  exercise wire timeout 60 "$ROOT/cocolog" --kb vacuum_test --host "$HOST" --tcp "$PORT" --timeout 10
else
  echo "wire: SKIP no Zigurat server at $HOST:$PORT"
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  exit 1
fi
