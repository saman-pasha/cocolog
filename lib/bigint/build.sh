#!/bin/sh
# Transpiles library(bigint) -- Zigurat's BigInt as cocolog predicates.
# Leaves coco-bigint.o here for the one link in the Makefile.
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
CICILI=${CICILI:-$HOME/cicili}
ZIGURATIP=${ZIGURATIP:-$HOME/ZiguratIP}

if [ ! -f "$ZIGURATIP/home/include/bigint.hpp" ]; then
  echo "bigint: no bigint.hpp in $ZIGURATIP/home/include -- build ZiguratIP first" >&2
  exit 1
fi
ln -sfn "$ZIGURATIP/home/include" "$HERE/zigheaders"

cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/bigint.cicili"
