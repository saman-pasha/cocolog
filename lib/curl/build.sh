#!/bin/sh
# Builds library(curl) -- a LOADABLE module, not a linked-in one.
#
#   CICILI   a Cicili checkout   (default $HOME/cicili)
#   OUT      where the .so lands (default ../../library, the default path)
#
# WHY LOADABLE. bigint and torch are compiled into the one cocolog binary
# because the binary is useless without a store and this project's ML
# story is torch. libcurl is neither, and making it mandatory would put
# an HTTP client on the critical path of every build -- a Colab VM, a
# container, anyone who wants an interpreter and no network. So this is a
# .so on the library path, `use_module(library(curl))' finds it, and a
# cocolog built where libcurl is absent is a cocolog that works.
#
# IT IS NOT PART OF `make'. Run it when you want the client:
#
#   sh lib/curl/build.sh
#
# and test/curl.sh SKIPs, loudly, when the .so is not there.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
OUT=${OUT:-$ROOT/library}

if [ ! -f /usr/include/curl/curl.h ] && [ ! -f /usr/include/x86_64-linux-gnu/curl/curl.h ] \
   && ! curl-config --cflags >/dev/null 2>&1; then
  echo "curl: no curl/curl.h -- apt-get install libcurl4-openssl-dev" >&2
  exit 1
fi

# The SDK is symlinked in rather than named by a path, so curl.cicili
# carries none -- the same trick lib/bigint/build.sh uses for ZiguratIP's
# headers and embed/build.sh for the engine's sources.
ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/curl.cicili" )

# -O3 is what actually optimises the .so: Cicili's --release governs how
# CICILI compiles, and this script compiles the emitted .c itself.
gcc -shared -fPIC -O3 -o "$OUT/curl.so" "$HERE/curl.c" \
    $(curl-config --cflags 2>/dev/null) $(curl-config --libs 2>/dev/null || echo -lcurl)
echo "built $OUT/curl.so"
