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
CICILI=${CICILI:-$HOME/cicili}
ZIGURATIP=${ZIGURATIP:-$HOME/ZiguratIP}

ln -sfn "$ZIGURATIP/Core"                          "$HERE/Core"
ln -sfn "$ZIGURATIP/StreamIO"                      "$HERE/StreamIO"
ln -sfn "$ZIGURATIP/MVCCS-cicili/mvccs-lib.cicili" "$HERE/mvccs-lib.cicili"
ln -sfn "$ZIGURATIP/MVCCS-cicili/generated"        "$HERE/generated"
ln -sfn "$ZIGURATIP/home/lib"                      "$HERE/ziglib"

cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/embed.cicili"
