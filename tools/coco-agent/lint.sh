#!/bin/sh
# cocolint -- the cocolog dialect linter, written in cocolog.
#
#     sh tools/coco-agent/lint.sh myprogram.pl [more.pl ...]
#
# Exits 1 if there is a HARD finding, 0 otherwise.
#
# THE INDEX IS NEVER STALE, and is rebuilt only when it is. blocklist.pl and
# traps.pl are generated from this checkout's own source, and a linter running
# against a stale blocklist reports collisions with names that have moved --
# worse than not running, because the message is confident. It used to rebuild
# unconditionally, which cost nothing while the reader was Python; the reader
# is clauses.pl now and that is four and a half seconds a run. --if-stale
# keeps the guarantee and drops the waste: a missing or out-of-date output is
# rebuilt, and nothing else is.
#
# THE FILE LIST GOES THROUGH THE ENVIRONMENT, not the goal term. cocolog HAS
# argv now -- `--' ends its own arguments and the tail reaches the program as
# `current_prolog_flag(argv, V)' -- so this could be `... cl_main -- $@'. It
# is not, and the reason is worth keeping: a path with a space in it survives
# a file with one path per line unambiguously, and the environment costs this
# script one mktemp. Rewriting it to argv would be a change with no defect
# behind it.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"

[ -n "$1" ] || { echo "usage: lint.sh FILE.pl ..." >&2; exit 2; }
[ -x "$BIN" ] || { echo "cocolint: no binary at $BIN" >&2; exit 2; }

sh "$HERE/tool.sh" build --if-stale >/dev/null || exit 2
sh "$HERE/tool.sh" card --facts --if-stale >/dev/null || exit 2

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
