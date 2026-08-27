#!/bin/sh
# Builds library(torch) -- libtorch as cocolog predicates, as a LOADABLE
# module. Leaves torch.so on the library path.
#
#   CICILI     a Cicili checkout   (default $HOME/cicili)
#   LIBTORCH   a libtorch          (default: the pip torch package's)
#   OUT        where the .so lands (default ../../library)
#
# IT USED TO BE LINKED INTO THE BINARY, reached through a weak symbol. That
# meant EVERY cocolog link needed libtorch -- gigabytes of it, an -rpath
# baked into the binary, and a build that fails on any machine without it,
# for a module most programs never call. Now `use_module(library(torch))'
# finds it, and a cocolog built where libtorch is absent is a cocolog that
# works.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
OUT=${OUT:-$ROOT/library}

TORCH_LIB=${LIBTORCH:-$(python3 -c "import torch, os; print(os.path.join(os.path.dirname(torch.__file__), 'lib'))" 2>/dev/null)}
TORCH_INC=${LIBTORCH_INCLUDE:-$(python3 -c "import torch, os; print(os.path.join(os.path.dirname(torch.__file__), 'include'))" 2>/dev/null)}

if [ -z "$TORCH_LIB" ] || [ ! -d "$TORCH_LIB" ]; then
  echo "torch: no libtorch -- pip install torch, or set LIBTORCH" >&2
  exit 1
fi

mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/coco-torch.cicili" )

# The -rpath is the module's now, not the binary's, which is the point of
# the move: a cocolog with no torch.so beside it needs nothing from here.
g++ -shared -fPIC -O3 -std=c++17 \
    -Wno-c++20-extensions -Wno-parentheses-equality -Wno-dangling-else \
    -I"$TORCH_INC" -I"$TORCH_INC/torch/csrc/api/include" \
    -o "$OUT/torch.so" "$HERE/coco-torch.cpp" \
    -L"$TORCH_LIB" -ltorch -ltorch_cpu -lc10 \
    -Wl,-rpath,"$TORCH_LIB"
echo "built $OUT/torch.so"
