#!/bin/sh
# Compiles the cocolog objects in order. The schema has to exist before the
# procedures, because REQUIRES links against objects that must already be
# there.
#
# These are compiled with the parsi program rather than sent over a connection:
# `compile' over the wire is refused unless COMPILER/REMOTE_MODE is TRUE, and
# it is FALSE by default because it is remote code execution by design.
set -e

HERE=$(cd "$(dirname "$0")" && pwd)

# cocolog does not contain ZiguratIP and does not build it. What it needs is a
# ZiguratIP home that has already been built, and the parsi compiler inside it.
if [ -z "$ZIGURATIP_HOME" ]; then
  echo "cocolog: set ZIGURATIP_HOME to a built ZiguratIP home directory" >&2
  exit 1
fi
if [ ! -x "$ZIGURATIP_HOME/bin/parsi" ]; then
  echo "cocolog: no parsi compiler in $ZIGURATIP_HOME/bin -- build ZiguratIP first" >&2
  exit 1
fi

export DYLD_LIBRARY_PATH="$ZIGURATIP_HOME/lib:$DYLD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$ZIGURATIP_HOME/lib:$LD_LIBRARY_PATH"

# A CUSTOM CONFIGURATION, when the home's will not do. `parsi
# --config=<file>' compiles against a configuration other than
# $ZIGURATIP_HOME/etc/ziguratip.conf -- the owner's own pointer, and the
# way to change CPP_FLAGS without editing a file the pillar tracks. Set
# ZIGURATIP_CONF to use one; CLAUDE.md's macOS note says when.
conf=
[ -n "$ZIGURATIP_CONF" ] && conf="--config=$ZIGURATIP_CONF"
for step in "$HERE"/0*.parsi; do
  echo "==> $(basename "$step")"
  if ! "$ZIGURATIP_HOME/bin/parsi" "$step" $conf > "$HERE/.build.log" 2>&1; then
    echo "failed:" >&2
    tail -5 "$HERE/.build.log" >&2
    rm -f "$HERE/.build.log"
    exit 1
  fi
  tail -1 "$HERE/.build.log"
done
rm -f "$HERE/.build.log"

echo
echo "Compiled into $ZIGURATIP_HOME/ld:"
ls "$ZIGURATIP_HOME"/ld/*COCOLOG*.so 2>/dev/null | sed 's|.*/|  |'
