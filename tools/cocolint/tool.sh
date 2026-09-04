#!/bin/sh
# tool.sh -- run one of the cocolog tools in this directory.
#
#     sh tools/cocolint/tool.sh build    [--if-stale]
#     sh tools/cocolint/tool.sh card     --check [--fix] | --facts | --card | --patterns
#     sh tools/cocolint/tool.sh index    [--check] [--no-run]
#     sh tools/cocolint/tool.sh assemble [--show system|user] [--sizes] "REQUEST"
#
# ONE DRIVER, BECAUSE THE FILE LIST IS THE ONLY THING THAT VARIES. These were
# `python3 build.py ...' and so on, and a tool that needs its dependencies
# named on the command line would otherwise put that list at seventeen call
# sites. `run FILE... GOAL -- ARGS' is the shape: cocolog consults each file,
# proves the goal, and everything after `--' reaches the program as argv.
#
# WHY NOT `-s': `-s FILE' loads exactly one file, and three of these four need
# clauses.pl or card.pl beside them. Where a tool stands alone -- trace-diff --
# test/trace.pl calls it with `-s' directly and does not come through here.
#
# `index' takes build.pl as well, and that is not a convenience: a module's
# surface row has to say which names the module really registers, and the two
# shapes that answer that -- the ("name" arity fn) table and the *X-prolog*
# half -- are already written, in build.pl, for the blocklist. Consulting them
# is what stops a third scanner over the same two shapes existing.
#
# Exits with the tool's own status: 1 when the goal fails, which is how a
# failing check reaches the shell.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"

[ -x "$BIN" ] || { echo "cocolint: no binary at $BIN" >&2; exit 2; }

TOOL=$1
[ -n "$TOOL" ] || { echo "usage: tool.sh build|card|index|assemble [args...]" >&2; exit 2; }
shift

case "$TOOL" in
  build)    FILES="$HERE/clauses.pl $HERE/build.pl";                       GOAL=bd_main ;;
  card)     FILES="$HERE/card.pl";                                        GOAL=cd_main ;;
  index)    FILES="$HERE/clauses.pl $HERE/build.pl $HERE/index.pl";       GOAL=ix_main ;;
  assemble) FILES="$HERE/clauses.pl $HERE/index.pl $HERE/card.pl $HERE/assemble.pl"
            GOAL=as_main ;;
  *) echo "cocolint: no tool named $TOOL" >&2; exit 2 ;;
esac

COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY" \
COCOLOG_ROOT="${COCOLOG_ROOT:-$ROOT}" \
  exec "$BIN" --local run $FILES "$GOAL" -- "$@"
