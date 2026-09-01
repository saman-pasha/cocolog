#!/bin/sh
# Ask the engine of the mode and cocolog -- the Prolog this mode is
# written for -- the same questions, and compare their answers.  A graph
# that says a query succeeds when cocolog says it fails would be worse
# than no graph at all, so this is the check that matters most.  It runs
# every test query of the example files, every query of
# test/conformance-queries.txt, and every example the snippet pickers
# show -- what the mode traces, cocolog must prove, and what the mode
# offers, cocolog must run.
#
#   make coco            (or: tools/coco-diff.sh)
#
# Needs the cocolog binary from the repository root (`make' up there
# builds it); everything else is in the mode. There is no Python in it.  COCOLOG=/path/to/cocolog
# points it somewhere else.
set -eu

EMACS=${EMACS:-emacs}
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"
COCOLOG=${COCOLOG:-$here/../cocolog}

[ -x "$COCOLOG" ] || {
  echo "cocolog not found at $COCOLOG: build it at the repository root," >&2
  echo "or set COCOLOG=/path/to/cocolog" >&2
  exit 2
}

mine=$(mktemp -t cocolog-mine.XXXXXX)
trap 'rm -f "$mine"' EXIT

"$EMACS" -Q --batch -L . -L tools -l tools/conformance.el 2>/dev/null > "$mine"

# THE DIFFER IS COCOLOG. tools/coco-diff.pl reads the four-column answers
# emacs just wrote and asks cocolog the same questions -- one --local run per
# query, against the library with the program's own predicates shadowed out.
# It exits 1 if anything differs, which is what `make coco' reads.
COCOLOG="$COCOLOG" \
COCOLOG_LIBRARY="$here/../library:${COCOLOG_LIBRARY:-}" \
  "$COCOLOG" -s "$here/tools/coco-diff.pl" -- "$mine"
