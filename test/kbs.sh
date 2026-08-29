#!/bin/sh
# library/kbs.pl -- many knowledge bases from one script.
#
# WHAT IS BEING PINNED:
#
#   TWO BASES, ONE STORY. A script seeds kbs_case_a and kbs_case_b and
#   reads DIFFERENT answers back from each -- the claim the .sh suites
#   made by spawning cocolog per touch, now one clause per touch.
#
#   GOALS ARE TERMS. enroll-style goals carry quoted atoms
#   ('Two Words') through term_to_atom untouched -- the quote-doubling
#   that eats shell suites is gone, and the pin proves the atom came
#   back whole.
#
#   EVERY TOUCH IS STILL A PROCESS-PROOF. kb_run spawns; that is the
#   point, not a workaround -- a store half exists to show a second
#   process sees the rows. The across-processes claim is the library's
#   own definition.

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

U="use_module(library(kbs))"
HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi
. "$HERE/library-path.sh"
if [ ! -f "$ROOT/library/process.so" ] || [ ! -f "$ROOT/library/text.so" ]; then
  echo "SKIP (kbs rides process.so and text.so -- sh modules/process/build.sh; sh modules/text/build.sh)"
  exit 0
fi
if ! timeout 20 "$C" --host "$HOST" --tcp "$PORT" --timeout 10 --kb kbs_case_a list >/dev/null 2>&1; then
  echo "SKIP (no Zigurat server at $HOST:$PORT)"
  exit 0
fi

q() { timeout 300 "$C" query "$U, $1" 2>/dev/null \
      | grep -a '^final(' | head -1 | sed 's/^final(//; s/)$//'; }

echo "-- two bases, one story"
check "seed two bases, read two different answers" \
  "$(q "kb_forget(kbs_case_a), kb_forget(kbs_case_b), kb_run(kbs_case_a, assertz(color(red))), kb_run(kbs_case_a, assertz(color(green))), kb_run(kbs_case_b, assertz(color(blue))), kb_answer(kbs_case_a, ( findall(X, color(X), Xs), write(answer(Xs)), nl ), A), kb_answer(kbs_case_b, ( findall(X, color(X), Xs), write(answer(Xs)), nl ), B), write(final(A-B)), nl")" \
  "answer([red,green])-answer([blue])"
check "a term goal carries its quoted atom whole" \
  "$(q "kb_run(kbs_case_a, assertz(unit(w, 'Two Words'))), kb_answer(kbs_case_a, ( unit(w, N), write(answer(N)), nl ), A), write(final(A)), nl")" \
  "answer(Two Words)"
check "a failing goal is a failing kb_run, and the base stands" \
  "$(q "( kb_run(kbs_case_a, no_such_thing_here(1)) -> R = proved ; R = refused ), kb_answer(kbs_case_a, ( findall(X, color(X), Xs), write(answer(Xs)), nl ), A), write(final(R-A)), nl")" \
  "refused-answer([red,green])"
check "kb_fresh empties and reloads in one word" \
  "$(q "kb_fresh(kbs_case_a, []), ( kb_run(kbs_case_a, color(_)) -> R = still ; R = empty ), kb_forget(kbs_case_b), write(final(R)), nl")" \
  "empty"

echo
if [ "$failures" -eq 0 ]; then echo "GREEN: 0 failure(s)"; else echo "RED: $failures failure(s)"; exit 1; fi
