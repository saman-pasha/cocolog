#!/bin/sh
# Builds library(tcp) -- the socket seam, as a LOADABLE module.
#
#   CICILI   a Cicili checkout   (default $HOME/cicili)
#   OUT      where the .so lands (default ../../library, the default path)
#
# IT USED TO BE IN THE BINARY. `lib/tcp.cicili' was swept into cocolog.c by
# the Makefile's wildcard and registered by name from `install_modules', so
# every cocolog carried a socket layer whether or not it would ever open
# one -- and the headers it needed sat in cocolog.cicili, several files from
# the code that used them.
#
# The move cost two lines of real change: a loadable module holds the
# engine as an OPAQUE pointer, so `(coco_new_int (-> e m) V)' -- reaching
# through the engine for its machine -- became `(coco_m_new_int e V)',
# which is the SDK call that exists for exactly this. Everything else is
# the same file.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}

# The SDK is symlinked in rather than named by a path, so tcp.cicili
# carries none -- the same trick every build.sh here uses.
ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/tcp.cicili" )

# -O3 is what actually optimises the .so: Cicili's --release governs how
# CICILI compiles, and this script compiles the emitted .c itself.
"$CC" -shared -fPIC -O3 -o "$OUT/tcp.so" "$HERE/tcp.c"
echo "built $OUT/tcp.so"
