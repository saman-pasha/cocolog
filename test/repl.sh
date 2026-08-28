#!/bin/sh
# The toplevel, piped: bare `cocolog` with goals on stdin.
#
# WHAT IT IS CHECKING, and why each part is there:
#
#   ANSWERS WEAR THE QUERY'S OWN NAMES. `X = 41 + 1, Y is X.` answers
#   `X = 41+1, Y = 42.` -- the reader's variable-name table survives into
#   the printing, which is the one thing `query` (whose machine may have
#   been thawed from a store that never had the names) cannot promise.
#
#   THE ALIAS RULES ARE SWI'S, taken from a live SWI toplevel and held to:
#   a still-unbound shared cell is named for the LAST variable standing on
#   it (`X = Y.` answers `X = Y.`; `f(A,B) = f(B,A).` answers `A = B.`),
#   a value shows the name and not the writer's `_G` cell (`X = f(Z), Y =
#   Z.` answers `X = f(Y), Z = Y.`), and a `_'-named variable names cells
#   without ever getting a line (`X = f(_Q).` answers `X = f(_Q).`).
#
#   THE PUNCTUATION IS HONEST. A determinate answer ends `.` with nobody
#   asked; one that left a choice point waits for `;`, and the `;` a
#   terminal would have echoed is restored to piped output, so `member`
#   reads `X = a ;` `X = b ;` `false.`
#
#   ONE SESSION IS ONE WORLD. What a goal asserts or consults, the next
#   goal sees; a syntax error costs the goal and not the session; `halt.`
#   leaves with 0.
#
#   THE STORE ARRANGEMENTS ARE THE SAME TOPLEVEL. Against the embedded
#   store and the server, a piped session's writes must be read by a
#   SECOND process that consulted nothing -- the claim the project exists
#   to make. The wire half SKIPs without a server.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-repl-XXXXXX")
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

# ---- local: names, aliases, punctuation, the session ----------------

got=$(printf 'X = 41 + 1, Y is X.\n' | "$C" 2>/dev/null)
check "names survive into the answer" "$got" "X = 41+1,
Y = 42."

got=$(printf 'member(X, [a,b]).\n;\n;\n' | "$C" 2>/dev/null)
check "; asks again, the echo restored, false closes" "$got" "X = a ;
X = b ;
false."

got=$(printf 'true.\n' | "$C" 2>/dev/null)
check "no variables says true" "$got" "true."

got=$(printf 'fail.\n' | "$C" 2>/dev/null)
check "no solutions says false" "$got" "false."

got=$(printf 'X = Y.\n' | "$C" 2>/dev/null)
check "a shared cell is named for its last variable" "$got" "X = Y."

got=$(printf 'X = f(Z), Y = Z.\n' | "$C" 2>/dev/null)
check "a value shows the name, not the _G cell" "$got" "X = f(Y),
Z = Y."

got=$(printf 'f(A,B) = f(B,A).\n' | "$C" 2>/dev/null)
check "swapped pairs collapse as SWI collapses them" "$got" "A = B."

got=$(printf 'X = f(_Q).\n' | "$C" 2>/dev/null)
check "_named variables name cells but get no line" "$got" "X = f(_Q)."

got=$(printf '_ = 1.\n' | "$C" 2>/dev/null)
check "a binding all underscores is just true" "$got" "true."

got=$(printf 'X =\n[a,\nb].\n' | "$C" 2>/dev/null)
check "a goal is read to its full stop, lines apart" "$got" "X = [a,b]."

got=$(printf 'foo(.\nX = ok.\n' | "$C" 2>/dev/null)
check "a syntax error costs the goal, not the session" "$got" "X = ok."

got=$(printf 'mystery(9).\nX = still_here.\n' | "$C" 2>/dev/null)
check "an unknown procedure costs the goal, not the session" "$got" "X = still_here."

got=$(printf 'mystery(9).\n' | "$C" 2>&1 >/dev/null)
case "$got" in
  *existence_error*) check "and says existence_error on stderr" yes yes ;;
  *) check "and says existence_error on stderr" "$got" "existence_error" ;;
esac

# fact/1's second answer is determinate -- the store knows its last clause
# -- so it closes with `.' where member/2, whose alternatives live in a
# recursive clause body, waits a third time and closes with false
got=$(printf 'assertz(fact(one)).\nassertz(fact(two)).\nfact(X).\n;\n' | "$C" 2>/dev/null)
check "what one goal asserts the next goal sees" "$got" "true.
true.
X = one ;
X = two."

# retract respects the body (the shorthand IS (H :- true), so a
# same-headed rule survives a fact's retract -- kb.cicili, a CivV
# capture's finding) while retractall keeps SWI's wider head-only
# contract and takes the rule too. The transcript is a live SWI's.
got=$(printf 'assertz(f(a)), assertz((f(X) :- X == b)), assertz(f(c)).\nretract(f(a)).\nf(b), !.\nf(a).\nretractall(f(_)).\nf(b).\n' | "$C" 2>/dev/null)
check "retract minds the body; retractall removes rules too" "$got" "true.
true.
true.
false.
true.
false."

printf 'p(1).\np(2).\nq(X) :- p(X), X > 1.\n' > "$OUT/fam.pl"
got=$(printf "['%s/fam'].\nq(X).\nconsult('%s/fam.pl').\n" "$OUT" "$OUT" | "$C" 2>/dev/null)
check "[file] and consult(file), .pl found for itself" "$got" "true.
X = 2.
true."

printf 'halt.\n' | "$C" >/dev/null 2>&1
check "halt. leaves with 0" "$?" "0"

# ---- the terminal: the line editor and the history ------------------
# Through a pseudo-terminal from script(1), so isatty is true and the
# editor runs; the editing is proven by what the READER got -- an answer
# can only say `X = 1.' if the backspaces really deleted -- and the
# history by a second session recalling the first one's goal with C-p.

if command -v script >/dev/null 2>&1 && \
   script -qec true /dev/null >/dev/null 2>&1; then
  H="$OUT/hist"; mkdir -p "$H"
  got=$(printf 'X = abcX\b\b\b\b1.\nhalt.\n' | HOME="$H" script -qec "$C" /dev/null \
        | tr -d '\r' | grep -c '^X = 1\.$')
  check "tty: backspace edits the line the reader gets" "$got" "1"
  got=$(printf 'X = 13\033[D2\005.\nhalt.\n' | HOME="$H" script -qec "$C" /dev/null \
        | tr -d '\r' | grep -c '^X = 123\.$')
  check "tty: left arrow inserts, C-e goes to the end" "$got" "1"
  got=$(grep -c '^X = 1\.$' "$H/.cocolog_history" 2>/dev/null)
  check "tty: the goal as edited lands in the history file" "$got" "1"
  H2="$OUT/hist2"; mkdir -p "$H2"
  printf 'X = recall_probe.\nhalt.\n' | HOME="$H2" script -qec "$C" /dev/null >/dev/null 2>&1
  got=$(printf '\020\020\n' | HOME="$H2" script -qec "$C" /dev/null \
        | tr -d '\r' | grep -c '^X = recall_probe\.$')
  check "tty: C-p recalls a previous session's goal" "$got" "1"
else
  echo "tty: SKIP (no script(1) for a pseudo-terminal)"
fi

# ---- embed: a piped session writes, a second process reads ----------

printf "assertz(kept(embed_round_trip)).\nhalt.\n" | \
  "$C" --embed "$OUT/KB" --kb repl_test >/dev/null 2>&1
got=$("$C" --embed "$OUT/KB" --kb repl_test query 'kept(X)' 2>/dev/null | head -1)
check "embed: the session's assert reaches a second process" "$got" "  1. kept(embed_round_trip)"

# ---- wire: the same, through a server -------------------------------

HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
if timeout 20 "$C" --kb repl_test --host "$HOST" --tcp "$PORT" \
     --timeout 10 list >/dev/null 2>&1; then
  printf "assertz(kept(wire_round_trip)).\nhalt.\n" | \
    timeout 60 "$C" --kb repl_test --host "$HOST" --tcp "$PORT" --timeout 10 >/dev/null 2>&1
  got=$(timeout 60 "$C" --kb repl_test --host "$HOST" --tcp "$PORT" --timeout 10 \
          query 'kept(X)' 2>/dev/null | head -1)
  check "wire: the session's assert reaches a second process" "$got" "  1. kept(wire_round_trip)"
  timeout 60 "$C" --kb repl_test --host "$HOST" --tcp "$PORT" --timeout 10 \
    forget >/dev/null 2>&1
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
