#!/bin/sh
# cocolint, for a human: `sh tools/coco-agent/lint.sh FILE.pl ...'
#
# Rebuilds the blocklist from source first, always. It is one pass over
# lib/, modules/, lib/swipl/ and library/ and it costs under a second, and a
# blocklist that is a day old is a linter that is confidently wrong about a
# name somebody added yesterday.
HERE=$(cd "$(dirname "$0")" && pwd)
command -v python3 >/dev/null 2>&1 || { echo "cocolint needs python3" >&2; exit 2; }
python3 "$HERE/build.py" >/dev/null || exit 2
exec python3 "$HERE/lint.py" "$@"
