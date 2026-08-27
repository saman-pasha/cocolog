#!/bin/sh
# Builds library(thread) -- threads that share nothing, channels that copy.
#
#   CICILI   a Cicili checkout   (default $HOME/cicili)
#   OUT      where the .so lands (default ../../library)
#
# NEEDS NOTHING BUT PTHREADS, which is why it is a module and not a
# dependency: -lpthread is in the C library on every system this runs on,
# and a cocolog that never spawns a thread never loads this.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}

ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/thread.cicili" )

"$CC" -shared -fPIC -O3 -o "$OUT/thread.so" "$HERE/thread.c" -lpthread
echo "built $OUT/thread.so"
