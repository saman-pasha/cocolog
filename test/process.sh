#!/bin/sh
# modules/process/process.cicili -- run, capture, spawn, wait, kill.
#
# WHAT IS BEING PINNED:
#
#   A TIMEOUT KILLS AND ANSWERS 124, coreutils' own number, with the
#   partial output kept -- a timed-out test's half-log is the
#   diagnosis, and a suite that hangs is the one outcome with no
#   information in it.
#
#   OUTPUT CARRIES EVERY BYTE. Codes, not an atom -- an atom stops at
#   the first NUL and a captured log is exactly the text that carries
#   one. The test pushes a NUL through and counts.
#
#   A SPAWNED CHILD HAS ITS OWN SESSION and dies on proc_stop/1 --
#   fifteen first, nine after -- leaving no zombie, which proc_wait
#   inside proc_stop is for.
#
#   THE CHECK HARNESS TELLS THE TRUTH: check/3 says ok or FAIL and
#   remembers; checks_done says GREEN or RED and FAILS on red, so a
#   .pl suite's exit status carries its verdict.
#
#   AND ACROSS PROCESSES, the only version worth making here: one
#   cocolog runs ANOTHER cocolog through sh/2 and reads its answer --
#   the exact choreography every .sh suite in this family performs,
#   now available to a .pl one.

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

U="use_module(library(process))"

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi
. "$HERE/library-path.sh"
if [ ! -f "$ROOT/library/process.so" ]; then
  echo "SKIP (no library/process.so -- sh modules/process/build.sh)"
  exit 0
fi
if ! timeout 20 "$C" query "$U, proc_sleep(1), write(ok), nl" 2>/dev/null | grep -aq '\bok\b'; then
  echo "SKIP (library(process) will not load)"
  exit 0
fi

q() { timeout 60 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

echo "-- run and capture"
check "sh/2 captures, sh_exit/2 reports, sh/1 demands zero" \
  "$(q "sh_atom('printf hello', A), sh_exit('exit 7', E), ( sh('false') -> F = ran ; F = refused ), write(answer(A-E-F)), nl")" \
  "hello-7-refused"
check "a timeout kills the group and answers 124, output kept" \
  "$(q "proc_run('echo kept; sleep 30', 500, Out, E), atom_codes(A, Out), ( A == 'kept\\n' -> K = kept ; K = lost ), write(answer(E-K)), nl")" \
  "124-kept"
check "every byte crosses, NUL included" \
  "$(q "proc_run('head -c 3 /dev/zero', 5000, Out, 0), ( Out == [0, 0, 0] -> R = nuls ; R = Out ), write(answer(R)), nl")" \
  "nuls"

echo
echo "-- spawn, watch, stop"
check "a spawned child lives, is stopped, and is gone" \
  "$(q "proc_spawn('sleep 30', P), ( proc_running(P) -> R1 = up ; R1 = down ), proc_stop(P), ( proc_running(P) -> R2 = up ; R2 = down ), write(answer(R1-R2)), nl")" \
  "up-down"
check "proc_until polls a condition to its answer" \
  "$(q "proc_spawn('sleep 1', P), ( proc_until(proc_wait(P, 0, _), 5000, 100) -> R = ended ; R = still ), write(answer(R)), nl")" \
  "ended"

echo
echo "-- the harness, and the choreography across processes"
check "check/3 remembers and checks_done says RED by failing" \
  "$(q "check(good, x, x), check(bad, x, y), ( checks_done -> V = green ; V = red ), write(answer(V)), nl")" \
  "red"
check "one cocolog runs another and reads its answer" \
  "$(q "sh('\\\"$C\\\" query \\\"X is 6*7, write(X), nl\\\" 2>/dev/null | head -1', Cs), append(D, [10], Cs), atom_codes(A, D), write(answer(A)), nl")" \
  "42"

echo
if [ "$failures" -eq 0 ]; then echo "GREEN: 0 failure(s)"; else echo "RED: $failures failure(s)"; exit 1; fi
