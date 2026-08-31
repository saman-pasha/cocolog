#!/bin/sh
# cocolint -- the cocolog dialect linter, written in cocolog.
#
#     sh tools/coco-agent/lint.sh myprogram.pl [more.pl ...]
#
# Exits 1 if there is a HARD finding, 0 otherwise.
#
# THE INDEX IS REBUILT FIRST, ALWAYS. blocklist.pl and traps.pl are generated
# from this checkout's own source, they take under a second, and a linter
# running against a stale blocklist reports collisions with names that have
# moved -- which is worse than not running, because the message is confident.
#
# THE FILE LIST GOES THROUGH THE ENVIRONMENT, not the goal term: cocolog has
# no argv, so the alternative is a goal the shell has to quote, and a path
# with a space in it breaks that.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"

[ -n "$1" ] || { echo "usage: lint.sh FILE.pl ..." >&2; exit 2; }
[ -x "$BIN" ] || { echo "cocolint: no binary at $BIN" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "cocolint: needs python3 to build the index" >&2; exit 2; }

python3 "$HERE/build.py" >/dev/null || exit 2
python3 "$HERE/traps.py" --facts >/dev/null || exit 2

T=$(mktemp) || exit 2
trap 'rm -f "$T"' EXIT
for f in "$@"; do
  case "$f" in /*) printf '%s\n' "$f" ;; *) printf '%s\n' "$(pwd)/$f" ;; esac
done > "$T"

COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY" \
COCOLOG_ROOT="$ROOT" \
COCO_LINT_FILES="$T" \
  "$BIN" --local run \
    "$HERE/blocklist.pl" "$HERE/traps.pl" "$HERE/clauses.pl" "$HERE/lint.pl" \
    cl_main
