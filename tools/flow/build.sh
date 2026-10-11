#!/bin/sh
# tools/flow/build.sh -- library(flowchart)'s tables, from the sources.
#
#     sh tools/flow/build.sh
#
# `make modules' runs it, after `make': it needs a built cocolog. It builds
# cocolint's blocklist when that is stale -- the SET of names, which
# tools/cocolint/build.pl reads out of lib/, modules/ and library/ -- and
# then tools/flow/tables.pl adds what a chart needs on top of the set: the
# C function that answers each module predicate, the line of its table row,
# and its modes. The result is library/flow/tables.pl, which git ignores,
# as it does the blocklist it is made from.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
cd "$ROOT"
[ -x ./cocolog ] || { echo "tools/flow/build.sh: no ./cocolog -- run make first" >&2; exit 1; }
sh tools/cocolint/tool.sh build --if-stale >/dev/null
COCOLOG_LIBRARY="$ROOT/library${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}" \
  ./cocolog -s tools/flow/tables.pl -- library/flow/tables.pl
