#!/bin/sh
# Builds library(torch) -- libtorch as cocolog predicates, as a LOADABLE
# module. Leaves torch.so on the library path.
#
#   CICILI     a Cicili checkout   (default $HOME/cicili)
#   OUT        where the .so lands (default ../../library)
#
# ---- WHERE LIBTORCH IS: THREE VARIABLES, ALL OF THEM READ ---------------
#
#   LIBTORCH       the ROOT that holds include/ and lib/ -- the standalone
#                  download, or an install that kept the two together
#                  (Homebrew and a `make install' on macOS: LIBTORCH=/usr/local)
#   TORCH_INCLUDE  the include directory, when it is not $LIBTORCH/include
#   TORCH_LIB      the lib directory, when it is not $LIBTORCH/lib
#
# THE TWO SPECIFIC ONES WIN OVER THE ROOT, and they exist because an
# INSTALLED libtorch is not always a root: a Debian `libtorch-dev' puts the
# headers under /usr/include and the shared objects under
# /usr/lib/<triple>, and no single directory holds both. A machine that
# does keep them together says so in one line and the other two are
# derived. $TORCH_ROOT is read as well, because that is Cicili's second
# spelling of $LIBTORCH. When none of them is set the pip `torch' package
# is asked, whose directory IS a root.
#
# AND THEY ARE CICILI'S VARIABLES TOO. Cicili's {$TORCH_*} tokens resolve
# from $LIBTORCH/$TORCH_ROOT alone, so a root worked out here is EXPORTED
# before the transpile -- the headers the .cpp is written against are then
# the headers it is compiled against, on a machine that never had pip.
#
# THE CHECK IS FOR FILES, NOT FOR DIRECTORIES. `torch/csrc/api/include/torch/torch.h'
# is the header this module includes and `libtorch' the library it links,
# with the suffix left to the platform (.dylib, .so, .a) -- an empty
# /usr/local/include is not a libtorch, and saying so here costs one line
# instead of a page of C++ diagnostics.
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
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}

TORCH_ROOT=${LIBTORCH:-${TORCH_ROOT:-}}
if [ -z "$TORCH_ROOT" ] && { [ -z "${TORCH_INCLUDE:-}" ] || [ -z "${TORCH_LIB:-}" ]; }; then
  TORCH_ROOT=$(python3 -c "import torch, os; print(os.path.dirname(torch.__file__))" 2>/dev/null) || TORCH_ROOT=
fi
TORCH_INCLUDE=${TORCH_INCLUDE:-${TORCH_ROOT:+$TORCH_ROOT/include}}
TORCH_LIB=${TORCH_LIB:-${TORCH_ROOT:+$TORCH_ROOT/lib}}

TORCH_API_INCLUDE="$TORCH_INCLUDE/torch/csrc/api/include"
have_headers=0
if [ -n "$TORCH_INCLUDE" ] && [ -f "$TORCH_API_INCLUDE/torch/torch.h" ]; then have_headers=1; fi
have_library=0
if [ -n "$TORCH_LIB" ]; then
  for ext in dylib so a; do
    if [ -f "$TORCH_LIB/libtorch.$ext" ]; then have_library=1; fi
  done
fi

if [ "$have_headers" = 0 ] || [ "$have_library" = 0 ]; then
  cat >&2 <<MESSAGE
torch: no libtorch here.

  headers  ${TORCH_INCLUDE:-(unset)} -- $( [ "$have_headers" = 1 ] && echo "torch/torch.h found" || echo "no torch/csrc/api/include/torch/torch.h" )
  library  ${TORCH_LIB:-(unset)} -- $( [ "$have_library" = 1 ] && echo "libtorch found" || echo "no libtorch.dylib, .so or .a" )

Name the ROOT that holds include/ and lib/:

  export LIBTORCH=/usr/local          # Homebrew, or a make install
  export LIBTORCH=/opt/libtorch       # the standalone download

or the two halves, on a machine that splits them:

  export TORCH_INCLUDE=/usr/include
  export TORCH_LIB=/usr/lib/x86_64-linux-gnu

or install the pip package (pip install torch), which is asked when none
of them is set.
MESSAGE
  exit 1
fi

# Cicili resolves {$TORCH_*} from the root alone, so give it one.
if [ -z "${LIBTORCH:-}" ]; then
  LIBTORCH=${TORCH_ROOT:-$(dirname "$TORCH_INCLUDE")}
fi
export LIBTORCH

# CUDA GRAPH REPLAY IS COMPILED IN ONLY WHERE THE CUDA LIBRARY IS. The header
# ATen/cuda/CUDAGraph.h ships with CPU-only builds too (Homebrew's does), so
# the header proves nothing; libtorch_cuda beside libtorch does.
CUDA_FLAGS=""; CUDA_LIBS=""
for ext in so dylib; do
  if [ -f "$TORCH_LIB/libtorch_cuda.$ext" ]; then
    CUDA_FLAGS="-DCOCO_TORCH_CUDA=1"; CUDA_LIBS="-ltorch_cuda -lc10_cuda"
  fi
done
# libtorch's CUDA headers include the toolkit's cuda_runtime.h, which is not
# theirs to ship: it is under $CUDA_HOME, /usr/local/cuda, or the nvidia pip
# package a pip torch depends on. Name whichever is here, or compile replay out.
if [ -n "$CUDA_FLAGS" ]; then
  CUDA_INC=""
  for d in "${CUDA_HOME:-}/include" /usr/local/cuda/include \
           "$(python3 -c 'import nvidia.cuda_runtime, os; print(os.path.join(os.path.dirname(nvidia.cuda_runtime.__file__), "include"))' 2>/dev/null)"; do
    if [ -n "$d" ] && [ -f "$d/cuda_runtime.h" ]; then CUDA_INC="-I$d"; break; fi
  done
  if [ -z "$CUDA_INC" ]; then
    echo "torch: libtorch_cuda is here but no cuda_runtime.h under CUDA_HOME, /usr/local/cuda or the nvidia pip package -- replay compiled out"
    CUDA_FLAGS=""; CUDA_LIBS=""
  else
    CUDA_FLAGS="$CUDA_FLAGS $CUDA_INC"
  fi
fi
echo "torch: cuda graph replay $( [ -n "$CUDA_FLAGS" ] && echo "compiled in (libtorch_cuda found)" || echo "compiled out (no libtorch_cuda in $TORCH_LIB)" )"
mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/coco-torch.cicili" )

# The -rpath is the module's now, not the binary's, which is the point of
# the move: a cocolog with no torch.so beside it needs nothing from here.
"$CXX" -shared -fPIC -O3 -std=c++17 $CUDA_FLAGS \
    -Wno-c++20-extensions -Wno-parentheses-equality -Wno-dangling-else \
    -I"$TORCH_INCLUDE" -I"$TORCH_API_INCLUDE" \
    -o "$OUT/torch.so" "$HERE/coco-torch.cpp" \
    -L"$TORCH_LIB" -ltorch -ltorch_cpu -lc10 $CUDA_LIBS \
    -Wl,-rpath,"$TORCH_LIB"
echo "built $OUT/torch.so"
