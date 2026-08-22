#!/bin/sh
# The Files module, checked against SWI-Prolog.
#
# EVERY CASE IS ONE PROLOG FILE RUN TWICE -- once by swipl and once by cocolog,
# in a freshly made empty directory that is the same absolute path both times --
# and the two outputs compared byte for byte. A library that claims to be SWI's
# has to be checked against SWI rather than against its own author, and this is
# the only way to do that which cannot be fooled by the author's idea of what
# SWI does. It has already caught one: `file_name_extension' on '.bashrc'.
#
# It SKIPS when there is no swipl, because "no SWI here" and "the library is
# wrong" are different findings -- the same rule the database suites follow.
#
#   apt-get install swi-prolog-nox     # or your system's equivalent
#
# The sandbox is the same path for both runs so that anything derived from the
# working directory -- absolute_file_name/2, working_directory/2 -- compares
# equal. Each case gets a fresh one, and a case may leave whatever it likes.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
COCOLOG="$ROOT/cocolog"
SWIPL=${SWIPL:-swipl}
SANDBOX=${TMPDIR:-/tmp}/cocolog_files_sandbox

if ! command -v "$SWIPL" >/dev/null 2>&1; then
  echo "SKIP no $SWIPL to compare against"
  exit 0
fi
if [ ! -x "$COCOLOG" ]; then
  echo "SKIP no cocolog built at $COCOLOG"
  exit 0
fi

# Fixtures a case needs before it runs. Named after the case so that adding one
# is adding a branch here and a file next door, and so that a case that needs
# nothing says so by not appearing.
fixtures() {
  case "$1" in
    stat)
      printf 'hello' > "$SANDBOX/five.txt"
      : > "$SANDBOX/empty.txt"
      ln -s five.txt "$SANDBOX/link.txt"
      ;;
  esac
}

# One run of one system in a clean sandbox.
run_one() {
  rm -rf "$SANDBOX" && mkdir -p "$SANDBOX" || return 1
  fixtures "$1"
  shift
  ( cd "$SANDBOX" && "$@" ) 2>&1
}

failures=0
cases=${1:-$(ls "$HERE"/*.pl | sed 's|.*/||; s|\.pl$||')}

for c in $cases; do
  pl="$HERE/$c.pl"
  [ -f "$pl" ] || { echo "  $c: no such case"; failures=$((failures + 1)); continue; }

  swi=$(run_one "$c" "$SWIPL" -q -g main -t halt "$pl")
  coco=$(run_one "$c" "$COCOLOG" --local run "$pl" main)

  if [ "$swi" = "$coco" ]; then
    lines=$(printf '%s\n' "$swi" | grep -c .)
    echo "  $c: agrees with SWI on $lines line(s)"
  else
    echo "  $c: DIFFERS"
    printf '%s\n' "$swi"  > "$SANDBOX.swi.out"
    printf '%s\n' "$coco" > "$SANDBOX.coco.out"
    diff "$SANDBOX.swi.out" "$SANDBOX.coco.out" | sed 's/^/    /' | head -20
    failures=$((failures + 1))
  fi
done

rm -rf "$SANDBOX"
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
fi
echo "RED: $failures failure(s)"
exit 1
