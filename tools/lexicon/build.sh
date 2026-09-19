#!/bin/sh
# Writes library/reasoning/lexicon/{noun,class,adj,vt,vi,vpp,adverb,place}.txt
# from WordNet 3.0, with the cocolog beside this script -- tools/lexicon/build.pl
# is the program, this only sets the library path. proper.txt is not touched.
#
#   WORDNET   WordNet 3.0's dict directory (default /usr/share/wordnet;
#             apt install wordnet-base; Homebrew: /usr/local/share/wordnet or /opt/homebrew/share/wordnet)
#   any further arguments go to build.pl: --cap CLASS=N, --out DIR
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
[ -x "$ROOT/cocolog" ] || { echo "lexicon: no ./cocolog built in $ROOT" >&2; exit 1; }
cd "$ROOT"
COCOLOG_LIBRARY="$ROOT/library${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}" \
  exec ./cocolog -s tools/lexicon/build.pl -- --wordnet "${WORDNET:-/usr/share/wordnet}" "$@"
