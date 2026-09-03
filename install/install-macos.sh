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
#   CICILI=/path ZIGURATIP=/path ... checkouts elsewhere (default: beside this one,
#                                    cloned there when absent)
#
# Apple's clang comes with the Xcode command line tools, which Homebrew
# needs anyway; brew supplies sbcl, GNU libtool (glibtool, which Cicili
# links through), OpenSSL 3 for ZiguratIP's Cryptography and SocketIO, and
# pytorch when asked. The libcurl the curl module needs is in the SDK.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/.." && pwd)
OS=macos; LIBVAR=DYLD_LIBRARY_PATH; LOG=${LOG:-/tmp/cocolog-install}
BREW=$(brew --prefix 2>/dev/null || echo /usr/local)
. "$HERE/common.sh"

step "Xcode command line tools"
xcode-select -p >/dev/null 2>&1 || die "run: xcode-select --install   (Apple's clang, make, git and python3)"
cxx_ok 10 || die "${CICILI_CXX:-clang++} does not speak C++17"
say "$(${CICILI_CXX:-clang++} --version | head -1)"

if [ "${NO_PACKAGES:-0}" != 1 ]; then
  step "Homebrew packages"
  command -v brew >/dev/null 2>&1 || die "Homebrew is not installed: https://brew.sh"
  brew list --formula sbcl libtool openssl@3 >/dev/null 2>&1 || brew install sbcl libtool openssl@3
  say "sbcl libtool openssl@3"
  if [ "${WITH_TORCH:-0}" = 1 ]; then
    brew list --formula pytorch >/dev/null 2>&1 || { say "WITH_TORCH=1: brew install pytorch (this is large)"; brew install pytorch; }
    say "pytorch"
  fi
  if [ "${WITH_OPENCV:-0}" = 1 ]; then
    brew list --formula opencv >/dev/null 2>&1 || { say "WITH_OPENCV=1: brew install opencv (this is large)"; brew install opencv; }
    say "opencv"
  fi
fi
for t in make git curl sbcl glibtool python3; do command -v $t >/dev/null 2>&1 || die "$t is not on PATH"; done
[ -f "$BREW/include/openssl/ssl.h" ] || say "warning: no openssl/ssl.h under $BREW/include -- try: brew link openssl@3"

checkouts
lisp_side
build_ziguratip
build_cocolog
exports_hint
