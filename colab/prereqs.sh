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

# build-essential  make, and the libstdc++ headers and runtime that clang
#                  compiles and links against (tools/cc/cxx's
#                  --gcc-install-dir); nothing is compiled by gcc
# sbcl             runs Cicili, which emits every line of C in cocolog
#                  and in ZiguratIP's storage engine
# libtool-bin      /usr/bin/libtool ITSELF. Not `libtool': Debian and
#                  Ubuntu split them, and the `libtool' package ships
#                  libtoolize and the m4 macros while the script Cicili
#                  invokes is in libtool-bin. Installing the wrong one
#                  succeeds and leaves the build with no libtool.
# gnupg            gpg and gpgv, which verify quicklisp.lisp below
apt-get -qq install -y build-essential sbcl libtool-bin curl gnupg libcurl4-openssl-dev

# clang++ 16 OR NEWER. ZiguratIP and cocolog compile through
# tools/cc/cxx, which passes --gcc-install-dir so clang borrows a
# libstdc++ that has headers; the flag exists from clang 16. Colab's
# Ubuntu 22.04 image ships NO clang at all, and its apt has clang 14,
# which rejects the flag with `unsupported option' -- so this comes from
# apt.llvm.org. Every build is clang, the owner's rule: CICILI_CC and
# CICILI_CXX choose WHICH clang, and preflight.sh refuses a CICILI_CXX
# that is not one.
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
    echo "   CANNOT REACH apt.llvm.org; install clang 16+ by hand and re-run" >&2
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

# Quicklisp, for `str' and `cl-ppcre', in ~/quicklisp or $QUICKLISP_HOME,
# the two places THE BUILD FINDS IT. Every build runs `sbcl --script
# cicili.lisp', --script reads no ~/.sbclrc, and what loads Quicklisp
# there is cicili.lisp's own lines: since Cicili 1.0.1 they read
# $QUICKLISP_HOME and fall back to (user-homedir-pathname)/quicklisp/
# setup.lisp, which before was all they named. Against an older checkout
# a QUICKLISP_HOME anywhere else would install, pass every check below --
# each names $QL/setup.lisp -- and fail every build with `Component "str"
# not found'. So it is taken when $CICILI's cicili.lisp reads it, and
# refused by name otherwise, as install/common.sh's ql_home_ok does; it
# must be absolute, because each build reads it from a directory of its
# own. The same directory by another path is ~/quicklisp, and so is
# ~/quicklisp as a symlink to $QL, even before $QL exists.
case $QL in
  /*) ;;
  *) echo "   QUICKLISP_HOME=$QL is not an absolute path, and every build reads" >&2
     echo "   it from a directory of its own. Give it as /..., and re-run." >&2
     exit 1 ;;
esac
ql_home_ok() {
  q=$QL; while [ "${q%/}" != "$q" ]; do q=${q%/}; done
  [ "$q" = "$HOME/quicklisp" ] && return 0
  a=$(cd "$q" 2>/dev/null && pwd -P) || :
  b=$(cd "$HOME/quicklisp" 2>/dev/null && pwd -P) || :
  [ -n "$a" ] && [ "$a" = "$b" ] && return 0
  r=$(readlink "$HOME/quicklisp" 2>/dev/null) || :
  [ -n "$r" ] && [ "${r%/}" = "$q" ] && return 0
  return 1
}
if ql_home_ok; then
  :
elif grep -q 'getenv "QUICKLISP_HOME"' "$CICILI/cicili.lisp" 2>/dev/null; then
  echo "   QUICKLISP_HOME=$QL, which the Cicili at $CICILI reads -- keep it in"
  echo "   the environment of every build (os.environ in the notebook)"
else
  echo "   QUICKLISP_HOME=$QL is not $HOME/quicklisp, and the Cicili at $CICILI" >&2
  echo "   is older than 1.0.1, the first whose cicili.lisp reads QUICKLISP_HOME" >&2
  echo "   (sbcl --script reads no ~/.sbclrc, and an older one loads" >&2
  echo "   (user-homedir-pathname)/quicklisp/setup.lisp only). Update it" >&2
  echo "   (git -C $CICILI pull), unset QUICKLISP_HOME, or make $HOME/quicklisp" >&2
  echo "   a symlink to $QL, and re-run." >&2
  exit 1
fi

# AS QUICKLISP'S OWN PAGE SAYS (https://www.quicklisp.org/beta/), the way
# install/common.sh's quicklisp_get does it: quicklisp.lisp and its
# signature, the signature checked with gpgv against Quicklisp's release
# key -- held to the fingerprint that page publishes, because the key
# comes from the same server as the file -- and nothing installed unless
# it verifies; then (ql:add-to-init-file), so a notebook's own `!sbcl'
# loads it too. Not sourced from there: sourcing that file checks the
# ZIGURATIP and ZIGURATIP_HOME trees on the spot, which is no business of
# a file that installs packages. Everything goes in a directory of its
# own, removed after.
QL_KEY=D7A3489DDEFE32B7D0E7CC61307965AB028B5FF7
if [ ! -f "$QL/setup.lisp" ]; then
  echo "   installing Quicklisp into $QL"
  if ! command -v gpg >/dev/null 2>&1; then
    echo "   no gpg to verify quicklisp.lisp (apt-get install gnupg)" >&2; exit 1
  fi
  gpgv=$(command -v gpgv 2>/dev/null || command -v gpgv2 2>/dev/null) || {
    echo "   no gpgv to verify quicklisp.lisp (apt-get install gnupg)" >&2; exit 1; }
  qt=$(mktemp -d "${TMPDIR:-/tmp}/quicklisp.XXXXXX")
  # THE STEP THAT NEEDS beta.quicklisp.org. Named on failure rather than
  # left to `set -e', because "prereqs.sh exited 1" would send anyone
  # looking at apt. Colab has open outbound HTTPS; a sandbox may not.
  for f in quicklisp.lisp quicklisp.lisp.asc release-key.txt; do
    if ! curl -fsSL -o "$qt/$f" "https://beta.quicklisp.org/$f"; then
      rm -rf "$qt"
      echo "   CANNOT REACH beta.quicklisp.org for $f." >&2
      echo "   Cicili needs the systems 'str' and 'cl-ppcre' from Quicklisp." >&2
      echo "   On a machine with no route to it, install Quicklisp by hand" >&2
      echo "   into $QL and re-run." >&2
      exit 1
    fi
  done
  if ! gpg --homedir "$qt" --batch --dearmor < "$qt/release-key.txt" > "$qt/key.gpg" 2>/dev/null; then
    rm -rf "$qt"; echo "   gpg cannot read Quicklisp's release key -- nothing installed" >&2; exit 1
  fi
  if ! "$gpgv" --homedir "$qt" --keyring "$qt/key.gpg" --status-fd 1 "$qt/quicklisp.lisp.asc" "$qt/quicklisp.lisp" 2>/dev/null \
       | grep -q "^\[GNUPG:\] VALIDSIG .* $QL_KEY\$"; then
    rm -rf "$qt"
    echo "   quicklisp.lisp DOES NOT VERIFY against Quicklisp's release key" >&2
    echo "   $QL_KEY -- nothing installed." >&2
    exit 1
  fi
  echo "   quicklisp.lisp verified: signed by $QL_KEY"
  if ! sbcl --non-interactive --load "$qt/quicklisp.lisp" \
          --eval "(quicklisp-quickstart:install :path \"$QL/\")" >/dev/null; then
    rm -rf "$qt"
    echo "   (quicklisp-quickstart:install) failed -- run it by hand: sbcl --load quicklisp.lisp" >&2
    exit 1
  fi
  rm -rf "$qt"
else
  echo "   Quicklisp already at $QL"
fi
# (ql:add-to-init-file) asks for Enter and appends at every call, hence
# the newline and the look first.
if grep -qE 'quicklisp-init|setup\.lisp' "$HOME/.sbclrc" 2>/dev/null; then
  echo "   $HOME/.sbclrc loads Quicklisp already"
elif printf '\n' | sbcl --non-interactive --load "$QL/setup.lisp" --eval '(ql:add-to-init-file)' >/dev/null; then
  echo "   $HOME/.sbclrc loads Quicklisp now ((ql:add-to-init-file))"
else
  echo "   (ql:add-to-init-file) failed -- run sbcl --load $QL/setup.lisp and call it by hand" >&2
  exit 1
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
