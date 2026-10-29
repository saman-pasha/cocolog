#!/bin/sh
# cocolog on macOS, from a clone to a binary that answers, with ZiguratIP
# built beside it. Everything that is not Apple's comes from Homebrew.
#
#   sh install/install-macos.sh
#
#   NO_PACKAGES=1 ...                Homebrew already has everything
#   WITH_TORCH=1 ...                 brew install pytorch, so library(torch) builds (large)
#   WITH_OPENCV=1 ...                brew install opencv, so library(opencv) builds -- where a
#                                    bottle exists; without one, a source build into ~/opencv4
#                                    is what modules/opencv/build.sh looks for
#   WITH_RAY=1 ...                   brew install raylib, so library(ray) builds
#   WITH_NUMPY=1 ...                 library(numpy), which embeds CPython: it wants a python3
#                                    with a shared libpython on PATH (pyenv has one), Python
#                                    3.9 or later (NumPy's floor); NumPy 1.26 or later is
#                                    pip-installed for THAT python3 when it has none
#   CICILI=/path ZIGURATIP=/path ... checkouts elsewhere (default: beside this one,
#                                    cloned there when absent)
#
# Apple's clang comes with the Xcode command line tools, which Homebrew
# needs anyway; brew supplies sbcl, GNU libtool (glibtool, which Cicili
# links through), OpenSSL 3 for ZiguratIP's Cryptography and SocketIO,
# gnupg to verify Quicklisp, and pytorch when asked. The libcurl the curl
# module needs is in the SDK.
#
# As yourself, never as root: Homebrew refuses root, and Quicklisp and
# ~/common-lisp, found through $HOME, would be root's -- in root's home, or
# owned by root in yours.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/.." && pwd)
OS=macos; LIBVAR=DYLD_LIBRARY_PATH; LOG=${LOG:-/tmp/cocolog-install}
BREW=$(brew --prefix 2>/dev/null || echo /usr/local)
. "$HERE/common.sh"
[ "$(id -u)" != 0 ] || die "run this as yourself, not as root: Homebrew refuses root, and the Lisp side would go to root's home, where your own sbcl never looks"

step "Xcode command line tools"
xcode-select -p >/dev/null 2>&1 || die "run: xcode-select --install   (Apple's clang, make, git and python3)"
cxx_ok 10 || die "${CICILI_CXX:-clang++} is not a clang 10+ (C++17) -- every build here is clang"
say "$(${CICILI_CXX:-clang++} --version | head -1)"

if [ "${NO_PACKAGES:-0}" != 1 ]; then
  step "Homebrew packages"
  command -v brew >/dev/null 2>&1 || die "Homebrew is not installed: https://brew.sh"
  brew list --formula sbcl libtool openssl@3 gnupg pcre2 >/dev/null 2>&1 || brew install sbcl libtool openssl@3 gnupg pcre2
  say "sbcl libtool openssl@3 gnupg pcre2"
  if [ "${WITH_TORCH:-0}" = 1 ]; then
    brew list --formula pytorch >/dev/null 2>&1 || { say "WITH_TORCH=1: brew install pytorch (this is large)"; brew install pytorch; }
    say "pytorch"
  fi
  if [ "${WITH_OPENCV:-0}" = 1 ]; then
    brew list --formula opencv >/dev/null 2>&1 || { say "WITH_OPENCV=1: brew install opencv (this is large)"; brew install opencv; }
    say "opencv"
  fi
  if [ "${WITH_RAY:-0}" = 1 ]; then
    brew list --formula raylib >/dev/null 2>&1 || { say "WITH_RAY=1: brew install raylib"; brew install raylib; }
    say "raylib"
  fi
fi
for t in make git curl sbcl glibtool; do command -v $t >/dev/null 2>&1 || die "$t is not on PATH"; done
if [ "${WITH_NUMPY:-0}" = 1 ] || [ "${WITH_TORCH:-0}" = 1 ]; then
  command -v python3 >/dev/null 2>&1 || die "python3 is not on PATH (WITH_NUMPY or WITH_TORCH)"
  py_floor python3
fi
if [ "${WITH_NUMPY:-0}" = 1 ]; then numpy_match; fi
# HOMEBREW'S HEADERS AND LIBRARIES, FOR EVERY COMPILE AND LINK BELOW. Neither
# this checkout's makefiles nor ZiguratIP's name a Homebrew path: they leave it
# to the compiler's own search, and Apple's clang searches /usr/local --
# Homebrew's prefix on an Intel Mac -- but not /opt/homebrew, its prefix on
# Apple silicon. And openssl@3 is keg-only on both (Homebrew's reason: a
# versioned formula) and linked into no prefix, so unless it was `brew link'ed
# by hand its headers were found nowhere. CPATH and LIBRARY_PATH are clang's
# own variables for this: exported for the builds this script runs, and
# printed with the exports at the end for the ones after it (make test builds
# test binaries too).
OSSL=$(brew --prefix openssl@3 2>/dev/null) || OSSL=
[ -f "$OSSL/include/openssl/ssl.h" ] || [ -f "$BREW/include/openssl/ssl.h" ] \
  || say "warning: no openssl/ssl.h under ${OSSL:-$BREW}/include -- brew install openssl@3"
CPATH="${OSSL:+$OSSL/include:}$BREW/include${CPATH:+:$CPATH}"; export CPATH
LIBRARY_PATH="${OSSL:+$OSSL/lib:}$BREW/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"; export LIBRARY_PATH
log_ok "$LOG.ziguratip" "$LOG.raylib" "$LOG.cocolog" "$LOG.schema"

checkouts
lisp_side
build_ziguratip
build_cocolog
exports_hint
