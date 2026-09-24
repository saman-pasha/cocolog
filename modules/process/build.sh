#!/bin/sh
# Builds library(process) -- run, capture, spawn, wait, kill -- as a
# LOADABLE module.
#
#   CICILI   a Cicili checkout   (default $HOME/cicili)
#   OUT      where the .so lands (default ../../library, the default path)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}

# The SDK is symlinked in rather than named by a path -- the same trick
# every build.sh here uses.
ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/process.cicili" )

# -O3 is what actually optimises the .so: Cicili's --release governs how
# CICILI compiles, and this script compiles the emitted .c itself.
# _GNU_SOURCE because glibc shows POSIX_SPAWN_SETSID -- the session a
# proc_spawn/2 child gets -- only under it; Darwin's spawn.h has the flag
# in the open and ignores the macro.
"$CC" -shared -fPIC -O3 -D_GNU_SOURCE -o "$OUT/process.so" "$HERE/process.c"
echo "built $OUT/process.so"
