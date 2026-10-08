#!/bin/sh
# cocolog on Debian, Ubuntu or Fedora, from a clone to a binary that answers, with
# ZiguratIP built beside it:
#
#   sh install/install-linux.sh
#
#   NO_PACKAGES=1 ...                no root, or apt already done
#   WITH_TORCH=1 ...                 pip-install torch so library(torch) builds (large;
#                                    TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu
#                                    takes the CPU-only wheels; TORCH_SPEC picks the
#                                    version, torch==2.13.* unless told: 2.14's headers
#                                    need C++20, and the module is C++17)
#   WITH_NUMPY=1 ...                 python3 with its headers and NumPy, so library(numpy)
#                                    builds -- the one module that embeds CPython, until
#                                    it is rewritten without it; nothing else needs Python
#   WITH_OPENCV=1 ...                OpenCV 4 from the distribution, so library(opencv)
#                                    builds (large)
#   WITH_RAY=1 ...                   raylib RAYLIB_TAG (6.0) built from source beside the
#                                    checkouts, its X11 and GL headers, and Xvfb, so
#                                    library(ray) builds and runs with no screen
#   CICILI=/path ZIGURATIP=/path ... checkouts elsewhere (default: beside this one,
#                                    cloned there when absent)
#   CICILI_CC=... CICILI_CXX=...     a particular clang (clang-18, a path); every build
#                                    here is clang, and a compiler that is not is refused
#   sudo sh install/install-linux.sh the packages as root, then the rest as the user who
#                                    called sudo, in that user's own home
#
# Idempotent. The compiler is installed before anything is made, because a
# make without one leaves ZiguratIP dependency files that poison the next
# make -- colab/prereqs.sh and colab/build.sh carry the same lesson.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/.." && pwd)
TORCH_SPEC=${TORCH_SPEC:-torch==2.13.*}
OS=linux; LIBVAR=LD_LIBRARY_PATH; BREW=""; LOG=${LOG:-/tmp/cocolog-install}
. "$HERE/common.sh"

if [ "${NO_PACKAGES:-0}" != 1 ]; then
  step "packages"
  SUDO=""; [ "$(id -u)" = 0 ] || SUDO=sudo
  if command -v apt-get >/dev/null 2>&1; then
    # ---- Debian, Ubuntu ------------------------------------------------
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get -qq update
    $SUDO apt-get -qq install -y build-essential make git curl ca-certificates sbcl libtool-bin libssl-dev zlib1g-dev libcurl4-openssl-dev >/dev/null
    say "build-essential make git curl sbcl libtool-bin libssl-dev zlib1g-dev libcurl4-openssl-dev"
    if [ "${WITH_NUMPY:-0}" = 1 ]; then
      $SUDO apt-get -qq install -y python3 python3-dev python3-numpy >/dev/null
      say "WITH_NUMPY=1: python3 python3-dev python3-numpy"
    fi
    if [ "${WITH_OPENCV:-0}" = 1 ]; then
      $SUDO apt-get -qq install -y libopencv-dev >/dev/null
      say "WITH_OPENCV=1: libopencv-dev"
    fi
    if [ "${WITH_RAY:-0}" = 1 ]; then
      # raylib is not packaged for Ubuntu 24.04, so common.sh builds it; these
      # are its X11, GL and audio headers, and the X server a window needs
      # where there is no screen (test/ray.pl runs under xvfb-run there)
      $SUDO apt-get -qq install -y libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libgl1-mesa-dev libasound2-dev xvfb xauth >/dev/null
      say "WITH_RAY=1: libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libgl1-mesa-dev libasound2-dev xvfb xauth"
    fi
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
        *) die "CICILI_CXX=${CICILI_CXX} is not clang -- every build here is clang" ;;
      esac
    fi
    if [ "${WITH_TORCH:-0}" = 1 ]; then
      say "WITH_TORCH=1: pip-installing torch (this is large)"
      $SUDO apt-get -qq install -y python3-pip >/dev/null
      # Ubuntu 24.04 marks its python externally managed (PEP 668) and pip
      # refuses a system-wide install until told; TORCH_INDEX_URL picks the
      # wheels (https://download.pytorch.org/whl/cpu: CPU-only, far smaller)
      python3 -m pip install -q ${TORCH_INDEX_URL:+--index-url "$TORCH_INDEX_URL"} "$TORCH_SPEC" \
        || python3 -m pip install -q --break-system-packages ${TORCH_INDEX_URL:+--index-url "$TORCH_INDEX_URL"} "$TORCH_SPEC"
    fi
  elif command -v dnf >/dev/null 2>&1; then
    # ---- Fedora, and the Red Hat family with EPEL for sbcl --------------
    # Fedora's clang is 17 or newer, so it is taken as is. gcc-c++ is here
    # for libstdc++'s headers and runtime, which clang compiles and links
    # against; nothing is compiled by gcc.
    $SUDO dnf -q install -y gcc gcc-c++ make git curl ca-certificates clang sbcl libtool openssl-devel zlib-devel libcurl-devel redhat-rpm-config >/dev/null
    say "gcc gcc-c++ make git curl clang sbcl libtool openssl-devel zlib-devel libcurl-devel redhat-rpm-config"
    if [ "${WITH_NUMPY:-0}" = 1 ]; then
      $SUDO dnf -q install -y python3 python3-devel python3-numpy >/dev/null
      say "WITH_NUMPY=1: python3 python3-devel python3-numpy"
    fi
    if [ "${WITH_OPENCV:-0}" = 1 ]; then
      $SUDO dnf -q install -y opencv-devel >/dev/null
      say "WITH_OPENCV=1: opencv-devel"
    fi
    if [ "${WITH_RAY:-0}" = 1 ]; then
      $SUDO dnf -q install -y libX11-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel mesa-libGL-devel alsa-lib-devel xorg-x11-server-Xvfb xorg-x11-xauth >/dev/null
      say "WITH_RAY=1: libX11-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel mesa-libGL-devel alsa-lib-devel xorg-x11-server-Xvfb xorg-x11-xauth"
    fi
    cxx_ok 16 || case "${CICILI_CXX:-clang++}" in
      *clang*) die "this clang is older than 16 and tools/cc/cxx needs --gcc-install-dir; dnf install a newer clang" ;;
      *) die "CICILI_CXX=${CICILI_CXX} is not clang -- every build here is clang" ;;
    esac
    if [ "${WITH_TORCH:-0}" = 1 ]; then
      say "WITH_TORCH=1: pip-installing torch (this is large)"
      $SUDO dnf -q install -y python3-pip >/dev/null
      # Ubuntu 24.04 marks its python externally managed (PEP 668) and pip
      # refuses a system-wide install until told; TORCH_INDEX_URL picks the
      # wheels (https://download.pytorch.org/whl/cpu: CPU-only, far smaller)
      python3 -m pip install -q ${TORCH_INDEX_URL:+--index-url "$TORCH_INDEX_URL"} "$TORCH_SPEC" \
        || python3 -m pip install -q --break-system-packages ${TORCH_INDEX_URL:+--index-url "$TORCH_INDEX_URL"} "$TORCH_SPEC"
    fi
  else
    say "neither apt-get nor dnf here -- needed: clang 16+ with libstdc++'s headers,"
    say "make, git, curl, sbcl, GNU libtool, the OpenSSL, zlib, libcurl headers (python3 too for WITH_NUMPY or WITH_TORCH). Checking for them:"
  fi
fi

# THE REST IS THE CALLING USER'S. Quicklisp and the ~/common-lisp tree are
# found through $HOME -- SBCL's (user-homedir-pathname), ASDF's search of
# ~/common-lisp -- and under `sudo sh install/install-linux.sh' $HOME is
# /root: both went to root's home, owned by root, where the user's own sbcl
# never looks, and the builds beside them were root's too. So the packages
# go in as root, and everything after them runs again as the user who
# called sudo, in that user's own home (-H), with NO_PACKAGES=1 and this
# run's options. A root login with no sudo (a container, Colab) is in its
# own home already and goes on.
if [ "$(id -u)" = 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
  say "packages done as root; the rest as $SUDO_USER, in $(getent passwd "$SUDO_USER" | cut -d: -f6)"
  set -- NO_PACKAGES=1
  for v in CICILI ZIGURATIP ZIGURATIP_HOME QUICKLISP_HOME CICILI_CC CICILI_CXX LOG \
           WITH_TORCH WITH_NUMPY WITH_OPENCV WITH_RAY TORCH_INDEX_URL TORCH_SPEC \
           RAYLIB RAYLIB_TAG LIBTORCH TORCH_INCLUDE TORCH_LIB; do
    if eval "[ -n \"\${$v+set}\" ]"; then eval "set -- \"\$@\" \"$v=\$$v\""; fi
  done
  exec sudo -u "$SUDO_USER" -H env "$@" sh "$HERE/install-linux.sh"
fi

cxx_ok 16 || die "no clang 16+ for tools/cc: ${CICILI_CXX:-clang++}"
for t in make git curl sbcl libtool; do command -v $t >/dev/null 2>&1 || die "$t is not on PATH"; done
# PYTHON ONLY WHEN ASKED FOR: library(numpy) embeds CPython and torch comes
# from pip; nothing else cocolog builds or runs needs it
if [ "${WITH_NUMPY:-0}" = 1 ] || [ "${WITH_TORCH:-0}" = 1 ]; then
  command -v python3 >/dev/null 2>&1 || die "python3 is not on PATH (WITH_NUMPY or WITH_TORCH)"
fi
say "compiler: $(${CICILI_CXX:-clang++} --version | head -1)"

checkouts
lisp_side
build_ziguratip
build_cocolog
exports_hint
