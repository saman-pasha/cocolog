#!/bin/sh
# Build library(numpy): numpy arrays as cocolog predicates, over numpy's C
# API, as a LOADABLE module.
#
#   sh modules/numpy/build.sh
#
# It builds against the python3 on the path -- or $PYTHON, a virtualenv's
# bin/python3 or a second install -- which must carry numpy and a SHARED
# libpython: numpy's C API is a table a running CPython fills in, so the
# module links the interpreter and starts one at its first predicate. The
# flags are asked of the interpreter, never guessed:
#
#   sysconfig.get_paths()['include']          where Python.h is
#   numpy.get_include()                       where arrayobject.h is
#   sysconfig.get_config_var('LIBDIR')        where libpython is
#   sysconfig.get_config_var('LDVERSION')     python3.11, python3.11d ...
#
# A Debian/Ubuntu `python3-dev', a Fedora `python3-devel', a pyenv build or
# Homebrew's python3 all answer; a Python built without --enable-shared has
# no libpython to link and is SKIPPED by name.
#
#   CICILI   a Cicili checkout   (default $HOME/cicili)
#   OUT      where the .so lands (default ../../library, the default path)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}
PY=${PYTHON:-python3}

command -v "$PY" >/dev/null 2>&1 || { echo "numpy: SKIPPED -- no $PY on the path" >&2; exit 1; }
PY_INC=$("$PY" -c 'import sysconfig; print(sysconfig.get_paths()["include"])' 2>/dev/null) \
  || { echo "numpy: SKIPPED -- $PY has no sysconfig" >&2; exit 1; }
[ -f "$PY_INC/Python.h" ] \
  || { echo "numpy: SKIPPED -- no Python.h under $PY_INC (apt-get install python3-dev / dnf install python3-devel)" >&2; exit 1; }
NP_INC=$("$PY" -c 'import numpy; print(numpy.get_include())' 2>/dev/null) \
  || { echo "numpy: SKIPPED -- $PY has no numpy ($PY -m pip install numpy)" >&2; exit 1; }
PY_LIBDIR=$("$PY" -c 'import sysconfig; print(sysconfig.get_config_var("LIBDIR") or "")')
PY_LDVER=$("$PY" -c 'import sysconfig; print(sysconfig.get_config_var("LDVERSION") or "")')
PY_LIBS=$("$PY" -c 'import sysconfig; print(" ".join(v for v in (sysconfig.get_config_var("LIBS") or "", sysconfig.get_config_var("SYSLIBS") or "") if v))')
PY_FRAMEWORK=$("$PY" -c 'import sysconfig; print(sysconfig.get_config_var("PYTHONFRAMEWORK") or "")')
PY_PREFIX=$("$PY" -c 'import sysconfig; print(sysconfig.get_config_var("PYTHONFRAMEWORKPREFIX") or "")')

if [ -f "$PY_LIBDIR/libpython$PY_LDVER.so" ] || [ -f "$PY_LIBDIR/libpython$PY_LDVER.dylib" ]; then
  PY_LINK="-L$PY_LIBDIR -lpython$PY_LDVER -Wl,-rpath,$PY_LIBDIR"
elif [ -n "$PY_FRAMEWORK" ] && [ -n "$PY_PREFIX" ]; then
  PY_LINK="-F$PY_PREFIX -framework $PY_FRAMEWORK"
else
  echo "numpy: SKIPPED -- no shared libpython$PY_LDVER under $PY_LIBDIR (a Python built with --enable-shared, or a framework build)" >&2
  exit 1
fi

# The SDK is symlinked in rather than named by a path, so numpy.cicili
# carries none -- the same trick every build.sh here uses.
ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/numpy.cicili" )

# -O3 is what optimises the .so: Cicili's --release governs how Cicili
# compiles, and this script compiles the emitted C itself. The feature
# macros Python.h sets after the std prelude's headers are redefinitions
# to the same values, which is why -Wno-macro-redefined is here and not a
# reorder of the includes.
"$CC" -shared -fPIC -O3 -DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION \
    -Wno-unused-function -Wno-macro-redefined -Wno-deprecated-declarations \
    -I"$PY_INC" -I"$NP_INC" \
    -o "$OUT/numpy.so" "$HERE/numpy.c" \
    $PY_LINK $PY_LIBS -lm
echo "built $OUT/numpy.so against $PY ($("$PY" -c 'import sys, numpy; print("python " + sys.version.split()[0] + ", numpy " + numpy.__version__)'))"
