#!/bin/sh
# Build library(tensorflow): the tensor_* predicates over TensorFlow's C
# library, as a second backend behind library(torch)'s switch.
#
#   sh modules/tensorflow/build.sh
#
# LINUX ONLY, by design. It builds against the pip tensorflow package --
# `pip install tensorflow' -- whose wheel carries the C API headers under
# include/tensorflow/c and the library libtensorflow_cc.so.2 beside them;
# or name the two halves yourself:
#
#   export TF_INCLUDE=/opt/libtensorflow/include
#   export TF_LIB=/opt/libtensorflow/lib          # libtensorflow.so, the standalone download
#
# library(torch) must be built first: this module attaches to torch.so beside
# itself at load, and the torch module owns the switch and the predicates.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}
case "$(uname -s)" in
  Linux) ;;
  *) echo "tensorflow: SKIPPED -- this module is Linux only (the pip wheel's C library is built for it there)" >&2; exit 1 ;;
esac
if [ -z "${TF_INCLUDE:-}" ] || [ -z "${TF_LIB:-}" ]; then
  TF_ROOT=$(python3 -c "import tensorflow, os; print(os.path.dirname(tensorflow.__file__))" 2>/dev/null) || TF_ROOT=
  TF_INCLUDE=${TF_INCLUDE:-${TF_ROOT:+$TF_ROOT/include}}
  TF_LIB=${TF_LIB:-$TF_ROOT}
fi
if [ -z "$TF_INCLUDE" ] || [ ! -f "$TF_INCLUDE/tensorflow/c/c_api.h" ]; then
  echo "tensorflow: SKIPPED -- no tensorflow/c/c_api.h under ${TF_INCLUDE:-(unset)}: pip install tensorflow, or set TF_INCLUDE and TF_LIB" >&2
  exit 1
fi
TF_LINK=""
if [ -f "$TF_LIB/libtensorflow_cc.so.2" ]; then
  TF_LINK="-l:libtensorflow_cc.so.2 -l:libtensorflow_framework.so.2"
elif [ -f "$TF_LIB/libtensorflow.so" ]; then
  TF_LINK="-ltensorflow"
else
  echo "tensorflow: SKIPPED -- no libtensorflow_cc.so.2 or libtensorflow.so under $TF_LIB" >&2
  exit 1
fi
[ -f "$OUT/torch.so" ] || { echo "tensorflow: build library(torch) first (sh modules/torch/build.sh) -- this module attaches to torch.so" >&2; exit 1; }
mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/coco-tensorflow.cicili" )
"${CC:-${CICILI_CC:-clang}}" -shared -fPIC -O2 -std=c11 -Wno-unused-function \
    -I"$TF_INCLUDE" \
    -o "$OUT/tensorflow.so" "$HERE/coco-tensorflow.c" "$HERE/backend.c" \
    -L"$TF_LIB" $TF_LINK -ldl -lm \
    -Wl,-rpath,"$TF_LIB"
echo "built $OUT/tensorflow.so against $TF_LIB ($(python3 -c 'import tensorflow as tf; print(tf.__version__)' 2>/dev/null || echo 'a standalone libtensorflow'))"
