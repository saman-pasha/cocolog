#!/bin/sh
# Builds library(bigint) -- Zigurat's BigInt as cocolog predicates, as a
# LOADABLE module. Leaves bigint.so on the library path.
#
# IT USED TO BE LINKED INTO THE BINARY, reached through a weak symbol so a
# build without it left the predicates undefined. That worked, and it meant
# every cocolog link needed libCore from a BUILT ZiguratIP -- for a
# big-integer library most programs never call. Now `use_module(library(
# bigint))' finds it, and a cocolog built where ZiguratIP is absent is a
# cocolog that works.
#
#   CICILI     a Cicili checkout   (default $HOME/cicili)
#   ZIGURATIP  a BUILT ZiguratIP   (default $HOME/ZiguratIP)
#
# THE HEADERS ARE SYMLINKED IN rather than named by an absolute path, so
# bigint.cicili carries none: the same trick embed/build.sh uses for the
# engine's sources. What is linked is the BUILT home's `include', which
# is where ZiguratIP publishes bigint.hpp and the two headers it pulls
# in -- so this needs a ZiguratIP that has been built, not merely cloned.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
ZIGURATIP=${ZIGURATIP:-$HOME/ZiguratIP}

if [ ! -f "$ZIGURATIP/home/include/bigint.hpp" ]; then
  echo "bigint: no bigint.hpp in $ZIGURATIP/home/include -- build ZiguratIP first" >&2
  exit 1
fi
ln -sfn "$ZIGURATIP/home/include" "$HERE/zigheaders"

OUT=${OUT:-$ROOT/library}
mkdir -p "$OUT"

( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/bigint.cicili" )

# -fPIC and -shared are the difference between the old .o and this .so; the
# rest is what the Makefile used to pass at link time, moved here where the
# module that needs it lives.
"$CXX" -shared -fPIC -O3 -std=c++17 \
    -Wno-parentheses-equality -Wno-dangling-else \
    -I"$HERE/zigheaders" \
    -o "$OUT/bigint.so" "$HERE/coco-bigint.cpp" \
    -L"$ZIGURATIP/home/lib" -lCore -lStreamIO \
    -Wl,-rpath,"$ZIGURATIP/home/lib"
echo "built $OUT/bigint.so"
