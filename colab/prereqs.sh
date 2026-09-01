#!/bin/sh
# What to install before building, and it lives HERE rather than in the
# notebook cell.
#
# WHY THIS FILE EXISTS, and it is the second time the same lesson has
# been paid for in this directory. The package list used to be a line
# inside the notebook:
#
#     !apt-get -qq install -y build-essential sbcl libtool
#
# A notebook cell is a COPY of a fact that lives in the repository, and
# the two drift the moment either moves. When `libtool' turned out to be
# the wrong package -- the script Cicili invokes is in `libtool-bin' --
# the fix landed in the repo, the notebook cell in the user's BROWSER
# stayed as it was, and their next run cloned the corrected preflight,
# ran the stale apt line, and refused for the same reason a second time.
# Nothing was broken; the two halves were simply different ages.
#
# So the list is a file in the repo, the notebook calls it AFTER cloning,
# and a stale notebook still installs the right things -- because the
# only thing the cell still knows is where to find this.
#
#   sh colab/prereqs.sh
#
# Nothing here is quiet and nothing is forgiven: `-qq' with the output
# thrown away and `|| true' on the end is how the first version of this
# hid a failed install and cost a whole build.

set -e

echo "== installing what the build needs"

# THE PACKAGE LISTS GO STALE, and that is what breaks an install on a
# Colab image more often than anything else. Update first.
apt-get -qq update

# build-essential  gcc, g++ and make
# sbcl             runs Cicili, which emits every line of C in cocolog
#                  and in ZiguratIP's storage engine
# libtool-bin      /usr/bin/libtool ITSELF. Not `libtool': Debian and
#                  Ubuntu split them, and the `libtool' package ships
#                  libtoolize and the m4 macros while the script Cicili
#                  invokes is in libtool-bin. Installing the wrong one
#                  succeeds and leaves the build with no libtool.
apt-get -qq install -y build-essential sbcl libtool-bin curl libcurl4-openssl-dev

# clang++ 16 OR NEWER. ZiguratIP and cocolog compile through
# tools/cc/cxx, which passes --gcc-install-dir so clang borrows a
# libstdc++ that has headers; the flag exists from clang 16. Colab's
# Ubuntu 22.04 image ships NO clang at all, and its apt has clang 14,
# which rejects the flag with `unsupported option' -- so this comes from
# apt.llvm.org. (CICILI_CC=gcc CICILI_CXX=g++ is the documented way to
# build without clang; nothing here forbids it.)
#
# AND THE ORDER MATTERS: the compiler must exist BEFORE the first `make'.
# Each ZiguratIP project writes a <Project>-Linux-cxx.depend by running
# `cxx -MM' under `@-', so with no clang++ the file is written WITHOUT
# its object rules, is newer than every source, and every later build
# says `No rule to make target home/obj/x.o' until it is deleted. That
# cost three builds on the first Colab session that met it; CLEAN=1 is
# the cure after the fact.
clang_major() { "$1" --version 2>/dev/null | grep -oE 'version [0-9]+' | grep -oE '[0-9]+' | head -1; }
if [ "$(clang_major clang++)" -ge 16 ] 2>/dev/null; then
  echo "   clang++ $(clang_major clang++) already present"
else
  echo "   clang++ 16+ not present -- installing clang 18 from apt.llvm.org"
  if ! curl -fsSL -o /tmp/llvm.sh https://apt.llvm.org/llvm.sh; then
    echo "   CANNOT REACH apt.llvm.org; install clang 16+ by hand, or build with CICILI_CC=gcc CICILI_CXX=g++" >&2
    exit 1
  fi
  bash /tmp/llvm.sh 18 >/dev/null
  update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100
  update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100
  update-alternatives --set clang++ /usr/bin/clang++-18
  update-alternatives --set clang /usr/bin/clang-18
  echo "   clang++ -> $(clang++ --version | head -1)"
fi

# ---- and then the LISP side, which nothing checked until Colab -------
#
# THE FAILURE THIS EXISTS FOR. cicili.asd depends on four systems, and
# the build worked for years on a machine where all four happened to be
# reachable -- so nobody had to know that TWO OF THEM COME FROM NOWHERE.
# `str' and `cl-ppcre' are Quicklisp's. `sha1' and `base64' are small
# local systems that live in ~/common-lisp on the development machine
# and are published under those names nowhere at all. And ASDF finds a
# checkout by its source registry, never by the directory it is run
# from, so the cicili clone itself is invisible too.
#
# On a fresh VM that is one error -- "Component \"cicili\" not found" --
# and everything after it in the log is downstream: no libMVCCS.so, no
# parsi, no ziguratip. The build reported thirteen failures for one
# cause.
HERE=$(cd "$(dirname "$0")" && pwd)
CICILI=${CICILI:-/content/cicili}
QL=${QUICKLISP_HOME:-$HOME/quicklisp}

echo "== the Lisp systems Cicili is built from"

# Quicklisp, for `str' and `cl-ppcre'. cicili.lisp loads
# ~/quicklisp/setup.lisp itself when it is there, so this is the
# location it already looks in rather than a new convention.
if [ ! -f "$QL/setup.lisp" ]; then
  echo "   installing Quicklisp into $QL"
  # THE ONE STEP THAT NEEDS THE NETWORK. Named on failure rather than
  # left to `set -e', because "prereqs.sh exited 1" would send anyone
  # looking at apt. Colab has open outbound HTTPS; a sandbox may not.
  if ! curl -fsSL -o /tmp/quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp; then
    echo "   CANNOT REACH beta.quicklisp.org." >&2
    echo "   Cicili needs the systems 'str' and 'cl-ppcre' from Quicklisp," >&2
    echo "   and nothing else here downloads anything. On a machine with no" >&2
    echo "   route to it, install Quicklisp by hand into $QL and re-run." >&2
    exit 1
  fi
  sbcl --non-interactive --load /tmp/quicklisp.lisp \
       --eval "(quicklisp-quickstart:install :path \"$QL/\")" >/dev/null
else
  echo "   Quicklisp already at $QL"
fi

# Downloaded now, so that the BUILD does no network I/O and a broken
# network fails here, named, instead of inside a Lisp backtrace.
sbcl --non-interactive --load "$QL/setup.lisp" \
     --eval '(ql:quickload (list :str :cl-ppcre) :silent t)' >/dev/null
echo "   str and cl-ppcre: present"

# The two that Quicklisp does not have. See colab/lisp/README.md for
# why they are copied rather than reimplemented -- Cicili derives
# generated MODULE NAMES from this exact digest.
mkdir -p "$HOME/common-lisp"
cp -r "$HERE/lisp/sha1" "$HERE/lisp/base64" "$HOME/common-lisp/"
echo "   sha1 and base64 shims: installed into $HOME/common-lisp"

# And the checkout itself, which ASDF will not find by being run inside
# it. A symlink in ~/common-lisp is the default source registry's own
# convention, so nothing has to be configured.
if [ -f "$CICILI/cicili.asd" ]; then
  ln -sfn "$CICILI" "$HOME/common-lisp/cicili"
  echo "   cicili: $HOME/common-lisp/cicili -> $CICILI"
else
  echo "   cicili: NO cicili.asd at $CICILI -- preflight will refuse" >&2
fi

echo "   installed; colab/preflight.sh will say whether that was enough"
