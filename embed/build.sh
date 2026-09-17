#!/bin/sh
# Builds the embedded knowledge base: transpiles embed.cicili with Cicili
# and leaves embed.o (and a smoke binary) here. The engine, the generated
# schema and ZiguratIP's Core/StreamIO are reached through symlinks so the
# .cicili file itself carries no absolute paths.
#
#   CICILI     a Cicili checkout       (default $HOME/cicili)
#   ZIGURATIP  a ZiguratIP checkout    (default $HOME/ZiguratIP)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
ZIGURATIP=${ZIGURATIP:-$HOME/ZiguratIP}

ln -sfn "$ZIGURATIP/Core"                          "$HERE/Core"
ln -sfn "$ZIGURATIP/StreamIO"                      "$HERE/StreamIO"
ln -sfn "$ZIGURATIP/MVCCS-cicili/mvccs-lib.cicili" "$HERE/mvccs-lib.cicili"
ln -sfn "$ZIGURATIP/MVCCS-cicili/generated"        "$HERE/generated"
ln -sfn "$ZIGURATIP/home/lib"                      "$HERE/ziglib"

# MVCCS_DEBUG COMPILES THE ENGINE'S TRACING INTO THIS BINARY, and it is the
# only way to get it: Cicili's info!/warn!/debug! macros expand to nothing at
# the default level, so an ordinary cocolog carries no trace code at all.
# The engine is compiled INTO cocolog here, which is why the lever has to
# exist on this side too -- ZiguratIP's own build.sh takes the same variable,
# and MVCCS-cicili/README.md says which level answers which question.
#
#   MVCCS_DEBUG=info  make        every store open and commit, on stderr
#   MVCCS_DEBUG=warn  make        and the rare paths
#   MVCCS_DEBUG=debug make        and every read, window and clock value
#
# stderr, not stdout: cocolog's answers are on stdout and the suite parses
# them, so a trace that shared the channel would break what it came to debug.
DEBUG_FLAG=""
case "${MVCCS_DEBUG:-}" in
  info)   DEBUG_FLAG="--info"   ;;
  warn)   DEBUG_FLAG="--warn"   ;;
  debug)  DEBUG_FLAG="--debug"  ;;
  syslog) DEBUG_FLAG="--syslog" ;;
  "")     ;;
  *) echo "MVCCS_DEBUG must be one of: info warn debug syslog" >&2; exit 1 ;;
esac
[ -n "$DEBUG_FLAG" ] && echo "== embed: engine tracing compiled in at $MVCCS_DEBUG, on stderr"

cd "$CICILI" && sbcl --script cicili.lisp --release $DEBUG_FLAG "$HERE/embed.cicili"
