#!/bin/sh
# Builds library(regex) -- PCRE2, the full Perl-compatible regex engine,
# as a LOADABLE module.
#
#   CICILI   a Cicili checkout   (default $HOME/cicili)
#   OUT      where the .so lands (default ../../library, the default path)
#
# PCRE2 is an external library the way libcurl is for library(curl): it is
# not on the critical path of a cocolog build, and this module is built
# only when someone asks for it. libpcre2-dev (Debian/Ubuntu), pcre2-devel
# (Fedora) or `brew install pcre2` is what it wants; pkg-config's
# libpcre2-8 is how it is found, with pcre2-config and the two common
# prefixes as fallbacks.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}

PCRE_CFLAGS=
PCRE_LIBS=
if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists libpcre2-8 2>/dev/null; then
  PCRE_CFLAGS=$(pkg-config --cflags libpcre2-8)
  PCRE_LIBS=$(pkg-config --libs libpcre2-8)
elif command -v pcre2-config >/dev/null 2>&1; then
  PCRE_CFLAGS=$(pcre2-config --cflags)
  PCRE_LIBS=$(pcre2-config --libs8)
else
  for d in /usr/local /opt/homebrew /usr; do
    [ -f "$d/include/pcre2.h" ] || continue
    lib="$d/lib"
    [ -d "$d/lib64" ] && lib="$d/lib64"
    PCRE_CFLAGS="-I$d/include"
    PCRE_LIBS="-L$lib -lpcre2-8"
    break
  done
fi

if ! printf '#define PCRE2_CODE_UNIT_WIDTH 8\n#include <pcre2.h>\n' \
     | "$CC" $PCRE_CFLAGS -E -x c - >/dev/null 2>&1; then
  echo "regex: no PCRE2 headers -- apt-get install libpcre2-dev, dnf install pcre2-devel, or brew install pcre2" >&2
  exit 1
fi

# The SDK is symlinked in rather than named by a path, so regex.cicili
# carries none -- the same trick every build.sh here uses.
ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/regex.cicili" )

# -O3 is what actually optimises the .so: Cicili's --release governs how
# CICILI compiles, and this script compiles the emitted .c itself.
"$CC" -shared -fPIC -O3 -o "$OUT/regex.so" "$HERE/regex.c" \
    $PCRE_CFLAGS $PCRE_LIBS
echo "built $OUT/regex.so"
