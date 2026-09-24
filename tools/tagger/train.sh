#!/bin/sh
# Writes library/reasoning/model.rows -- the shipped tagger, the rows
# tagger_export/2 writes, which tagger_pretrained/1 loads when the
# knowledge base a program proves against holds no model of its own --
# with the cocolog beside this script. library/reasoning/generate.pl
# writes the training data first, as files under
# library/reasoning/generated/ (committed, so the data the shipped model
# learned from is in the tree), and library/reasoning/train.pl trains on
# training.txt and measures; this only arranges the stores: it trains
# into a scratch --embed store and exports from it. (A store was the
# shipped form once and is not: sixteen megabytes for three of live rows,
# never shrinking below its high-water mark, in one machine's byte order.)
#
#   sh tools/tagger/train.sh [FILE]     FILE defaults to library/reasoning/model.rows
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
[ -x "$ROOT/cocolog" ] || { echo "tagger: no ./cocolog built in $ROOT" >&2; exit 1; }
cd "$ROOT"
FILE=${1:-library/reasoning/model.rows}
export COCOLOG_LIBRARY="$ROOT/library${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
./cocolog -s library/reasoning/generate.pl
./cocolog --embed "$TMP/train" -s library/reasoning/train.pl
./cocolog --embed "$TMP/train" query "use_module(library(reasoning/tagger)), tagger_export(tagger, '$FILE')" > /dev/null
echo "tagger: wrote $FILE ($(du -sh "$FILE" | cut -f1))"
