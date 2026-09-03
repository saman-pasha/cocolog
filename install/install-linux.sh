#!/bin/sh
# cocolog on Debian, Ubuntu or Fedora, from a clone to a binary that answers, with
# ZiguratIP built beside it:
#
#   sh install/install-linux.sh
#
#   NO_PACKAGES=1 ...                no root, or apt already done
#   WITH_TORCH=1 ...                 pip-install torch so library(torch) builds (large)
#   CICILI=/path ZIGURATIP=/path ... checkouts elsewhere (default: beside this one,
#                                    cloned there when absent)
#   CICILI_CC=gcc CICILI_CXX=g++ ... build with gcc; no clang needed
#
# Idempotent. The compiler is installed before anything is made, because a
# make without one leaves ZiguratIP dependency files that poison the next
# make -- colab/prereqs.sh and colab/build.sh carry the same lesson.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/.." && pwd)
OS=linux; LIBVAR=LD_LIBRARY_PATH; BREW=""; LOG=${LOG:-/tmp/cocolog-install}
. "$HERE/common.sh"

if [ "${NO_PACKAGES:-0}" != 1 ]; then
  step "packages"
  SUDO=""; [ "$(id -u)" = 0 ] || SUDO=sudo
  if command -v apt-get >/dev/null 2>&1; then
    # ---- Debian, Ubuntu ------------------------------------------------
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get -qq update
    $SUDO apt-get -qq install -y build-essential make git curl ca-certificates sbcl libtool-bin libssl-dev zlib1g-dev libcurl4-openssl-dev python3 python3-dev python3-numpy libopencv-dev >/dev/null
    say "build-essential make git curl sbcl libtool-bin libssl-dev zlib1g-dev libcurl4-openssl-dev python3 python3-dev python3-numpy libopencv-dev"
    if ! cxx_ok 16; then
      case "${CICILI_CXX:-clang++}" in
        *clang*)
          # Ubuntu 22.04's apt has clang 14, and tools/cc/cxx passes
          # --gcc-install-dir, which exists from clang 16; Colab's image has
          # no clang at all. So: clang 18 from apt.llvm.org.
          say "clang++ 16+ not present -- installing clang 18 from apt.llvm.org"
          curl -fsSL -o /tmp/llvm.sh https://apt.llvm.org/llvm.sh || die "cannot reach apt.llvm.org"
          $SUDO bash /tmp/llvm.sh 18 >/dev/null
          for t in clang clang++; do
            $SUDO update-alternatives --install /usr/bin/$t $t /usr/bin/$t-18 100 >/dev/null
            $SUDO update-alternatives --set $t /usr/bin/$t-18 >/dev/null
          done ;;
        *) die "${CICILI_CXX} is too old for C++17" ;;
      esac
    fi
    if [ "${WITH_TORCH:-0}" = 1 ]; then
      say "WITH_TORCH=1: pip-installing torch (this is large)"
      $SUDO apt-get -qq install -y python3-pip >/dev/null
      python3 -m pip install -q torch
    fi
  elif command -v dnf >/dev/null 2>&1; then
    # ---- Fedora, and the Red Hat family with EPEL for sbcl --------------
    # Fedora's clang is 17 or newer, so it is taken as is; redhat-rpm-config
    # provides the hardened-cc1 specs file that home/etc/ziguratip-RedHat.conf
    # names in its CPP_FLAGS.
    $SUDO dnf -q install -y gcc gcc-c++ make git curl ca-certificates clang sbcl libtool openssl-devel zlib-devel libcurl-devel python3 python3-devel python3-numpy opencv-devel redhat-rpm-config >/dev/null
    say "gcc gcc-c++ make git curl clang sbcl libtool openssl-devel zlib-devel libcurl-devel python3 python3-devel python3-numpy opencv-devel redhat-rpm-config"
    cxx_ok 16 || case "${CICILI_CXX:-clang++}" in
      *clang*) die "this clang is older than 16 and tools/cc/cxx needs --gcc-install-dir; dnf install a newer clang, or CICILI_CC=gcc CICILI_CXX=g++" ;;
      *) die "${CICILI_CXX} is too old for C++17" ;;
    esac
    if [ "${WITH_TORCH:-0}" = 1 ]; then
      say "WITH_TORCH=1: pip-installing torch (this is large)"
      $SUDO dnf -q install -y python3-pip >/dev/null
      python3 -m pip install -q torch
    fi
  else
    say "neither apt-get nor dnf here -- needed: a C++17 compiler (clang 16+, or g++ 7+ with CICILI_CXX=g++),"
    say "make, git, curl, sbcl, GNU libtool, the OpenSSL, zlib, libcurl headers, python3. Checking for them:"
  fi
fi
cxx_ok 16 || die "no C++17 compiler for tools/cc: ${CICILI_CXX:-clang++} (clang 16+, or CICILI_CC=gcc CICILI_CXX=g++)"
for t in make git curl sbcl libtool python3; do command -v $t >/dev/null 2>&1 || die "$t is not on PATH"; done
say "compiler: $(${CICILI_CXX:-clang++} --version | head -1)"

checkouts
lisp_side
build_ziguratip
build_cocolog
exports_hint
