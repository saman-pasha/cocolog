#!/bin/sh
# tool.sh -- run one of the cocolog tools in this directory.
#
#     sh tools/coco-agent/tool.sh build    [--if-stale]
#     sh tools/coco-agent/tool.sh card     --check [--fix] | --facts | --card | --patterns
#     sh tools/coco-agent/tool.sh index    [--check] [--no-run]
#     sh tools/coco-agent/tool.sh assemble [--show system|user] [--sizes] "REQUEST"
#
# ONE DRIVER, BECAUSE THE FILE LIST IS THE ONLY THING THAT VARIES. These were
# `python3 build.py ...' and so on, and a tool that needs its dependencies
# named on the command line would otherwise put that list at seventeen call
# sites. `run FILE... GOAL -- ARGS' is the shape: cocolog consults each file,
# proves the goal, and everything after `--' reaches the program as argv.
#
# WHY NOT `-s': `-s FILE' loads exactly one file, and three of these four need
# clauses.pl or card.pl beside them. Where a tool stands alone -- trace-diff --
# test/trace.sh calls it with `-s' directly and does not come through here.
#
# Exits with the tool's own status: 1 when the goal fails, which is how a
# failing check reaches the shell.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"

[ -x "$BIN" ] || { echo "coco-agent: no binary at $BIN" >&2; exit 2; }

TOOL=$1
[ -n "$TOOL" ] || { echo "usage: tool.sh build|card|index|assemble [args...]" >&2; exit 2; }
shift

case "$TOOL" in
  build)    FILES="$HERE/clauses.pl $HERE/build.pl";                       GOAL=bd_main ;;
  card)     FILES="$HERE/card.pl";                                        GOAL=cd_main ;;
  index)    FILES="$HERE/clauses.pl $HERE/index.pl";                      GOAL=ix_main ;;
  assemble) FILES="$HERE/clauses.pl $HERE/index.pl $HERE/card.pl $HERE/assemble.pl"
            GOAL=as_main ;;
  *) echo "coco-agent: no tool named $TOOL" >&2; exit 2 ;;
esac

COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY" \
COCOLOG_ROOT="${COCOLOG_ROOT:-$ROOT}" \
  exec "$BIN" --local run $FILES "$GOAL" -- "$@"
