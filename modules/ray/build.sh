#!/bin/sh
# Builds library(ray) -- raylib as cocolog predicates, a LOADABLE module.
#
#   CICILI   a Cicili checkout          (default $HOME/cicili)
#   RAYLIB   a raylib to build against  (default: the system's)
#   OUT      where the .so lands       (default ../../library)
#
# RAYLIB NAMES EITHER a raylib CHECKOUT built with PIC objects --
# `make PLATFORM=PLATFORM_DESKTOP RAYLIB_LIBTYPE=SHARED' in its src/,
# then `ar rcs lib/libraylib.a src/*.o' -- or an installed prefix with
# include/raylib.h and lib/libraylib.a. Unset, pkg-config and the usual
# prefixes are tried. THE ARCHIVE MUST BE PIC: a .so cannot swallow
# non-PIC objects, and raylib's default static build is not PIC, which
# is why the checkout recipe above goes through RAYLIB_LIBTYPE=SHARED.
#
# THE .so IS SELF-CONTAINED where the archive allows it: raylib is
# linked IN, so library/ray.so needs no rpath into wherever raylib was
# built -- only X11, m, pthread and dl, which are the system's. GL is
# not on the link line because glfw loads it at run time.
#
# It is not part of `make'. Run it when you want a window:
#
#   sh modules/ray/build.sh
#
# and test/ray.sh SKIPs, loudly, when the .so is not there.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}

# ---- find raylib -------------------------------------------------------
RAY_INC= ; RAY_LINK=
if [ -n "${RAYLIB:-}" ]; then
  if   [ -f "$RAYLIB/src/raylib.h" ]; then RAY_INC="$RAYLIB/src"
  elif [ -f "$RAYLIB/include/raylib.h" ]; then RAY_INC="$RAYLIB/include"
  fi
  if   [ -f "$RAYLIB/lib/libraylib.a" ]; then RAY_LINK="$RAYLIB/lib/libraylib.a"
  elif [ -f "$RAYLIB/src/libraylib.a" ]; then RAY_LINK="$RAYLIB/src/libraylib.a"
  fi
  if [ -z "$RAY_INC" ] || [ -z "$RAY_LINK" ]; then
    echo "ray: RAYLIB=$RAYLIB has no raylib.h + libraylib.a (src/ or include//lib/)" >&2
    exit 1
  fi
elif pkg-config --exists raylib 2>/dev/null; then
  RAY_INC=$(pkg-config --variable=includedir raylib)
  RAY_LINK=$(pkg-config --libs raylib)
elif [ -f /usr/local/include/raylib.h ]; then
  RAY_INC=/usr/local/include
  RAY_LINK="-L/usr/local/lib -lraylib"
elif [ -f /usr/include/raylib.h ]; then
  RAY_INC=/usr/include
  RAY_LINK=-lraylib
else
  echo "ray: no raylib -- set RAYLIB to a checkout (built PIC, see the header above)" >&2
  echo "     or install one so raylib.h is on the include path" >&2
  exit 1
fi

# The SDK is symlinked in rather than named by a path, exactly as
# modules/curl/build.sh does.
ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

mkdir -p "$OUT"
( cd "$CICILI" && CPATH="$RAY_INC${CPATH:+:$CPATH}" \
    sbcl --script cicili.lisp --release "$HERE/ray.cicili" )

# -O3 is what optimises the .so; Cicili's --release governs its own step.
"$CC" -shared -fPIC -O3 -I"$RAY_INC" -o "$OUT/ray.so" "$HERE/ray.c" \
    $RAY_LINK -lX11 -lm -lpthread -ldl
echo "built $OUT/ray.so"
