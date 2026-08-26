#!/bin/sh
# Transpiles the torch engine (coco-torch.cicili) with Cicili, against
# the libtorch that cicili's {$TORCH_*} tokens resolve -- $LIBTORCH, or
# the pip torch package. Leaves coco-torch.o here for `make torch'.
#
#   CICILI   a Cicili checkout   (default $HOME/cicili)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
CICILI=${CICILI:-$HOME/cicili}
cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/coco-torch.cicili"
