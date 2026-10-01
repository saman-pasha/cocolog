#!/bin/sh
# Builds library(clay) -- Clay's flex-box layout as cocolog predicates, a
# LOADABLE module.
#
#   CICILI   a Cicili checkout          (default $HOME/cicili)
#   OUT      where the .so lands        (default ../../library)
#
# IT NEEDS NOTHING. Clay is ONE header, clay.h, vendored beside this
# script (v0.14, zlib licence, its notice at the foot of the file), and
# its implementation is compiled into clay.c under CLAY_IMPLEMENTATION:
# no library is linked but libm. A renderer is somebody else's --
# library(clay_ray) draws the commands with library(ray), and a test
# holds them to numbers with no window at all.
#
# It is not part of `make'. Run it when you want a layout:
#
#   sh modules/clay/build.sh
#
# and test/clay.pl SKIPs, loudly, when the .so is not there.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}

# The SDK is symlinked in rather than named by a path, exactly as
# modules/curl/build.sh does.
ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

mkdir -p "$OUT"
( cd "$CICILI" && CPATH="$HERE${CPATH:+:$CPATH}" \
    sbcl --script cicili.lisp --release "$HERE/clay.cicili" )

# -O3 is what optimises the .so; Cicili's --release governs its own step.
# Clay's own unused-function warnings are its business, not this build's.
"$CC" -shared -fPIC -O3 -I"$HERE" -Wno-unused-function -o "$OUT/clay.so" "$HERE/clay.c" -lm
echo "built $OUT/clay.so"
