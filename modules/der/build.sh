#!/bin/sh
# Builds library(der) -- Distinguished Encoding Rules as cocolog predicates, as a LOADABLE
# module. Leaves der.so on the library path.
#
#   CICILI     a Cicili checkout   (default $HOME/cicili)
#   ZIGURATIP  a BUILT ZiguratIP   (default $HOME/ZiguratIP)
#
# WHY LOADABLE, like everything else in modules/: linking libCryptography
# into the binary would put OpenSSL on the critical path of every build,
# an encoding most programs never call. A cocolog built where
# ZiguratIP is absent is a cocolog that works.
#
# EVERY TRANSITIVE DEPENDENCY IS NAMED, and that is not belt and braces.
# libCryptography needs libConfiguration and OpenSSL's libcrypto; naming
# only libCryptography links fine and then fails at `use_module' with
# `libConfiguration.so: cannot open shared object file' -- because the
# -rpath applies to what THIS link records as needed, and a library the
# loader reaches transitively is looked for on the system path instead.
#
# THE HEADERS ARE SYMLINKED IN rather than named by an absolute path, so
# der.cicili carries none -- the trick modules/bigint/build.sh uses.
# What is linked is the BUILT home's `include', so this needs a ZiguratIP
# that has been built, not merely cloned.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
ZIGURATIP=${ZIGURATIP:-$HOME/ZiguratIP}

if [ ! -f "$ZIGURATIP/home/include/der.hpp" ]; then
  echo "der: no der.hpp in $ZIGURATIP/home/include -- build ZiguratIP first" >&2
  exit 1
fi
ln -sfn "$ZIGURATIP/home/include" "$HERE/zigheaders"
ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

OUT=${OUT:-$ROOT/library}
mkdir -p "$OUT"

( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/der.cicili" )

"$CXX" -shared -fPIC -O3 -std=c++17 \
    -Wno-parentheses-equality -Wno-dangling-else \
    -I"$HERE/zigheaders" \
    -o "$OUT/der.so" "$HERE/coco-der.cpp" \
    -L"$ZIGURATIP/home/lib" \
    -lEncoding -lCore -lStreamIO \
    -Wl,-rpath,"$ZIGURATIP/home/lib"
echo "built $OUT/der.so"
