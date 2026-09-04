# WHICH clang, CHOSEN rather than inherited. Sourced by ./cc and ./cxx.
#
# `clang' as a bare name is whatever PATH answers first, and on a Mac with
# Homebrew's LLVM installed that is Homebrew's -- /usr/local/opt/llvm/bin
# comes before /usr/bin in an ordinary login PATH. So the compiler this
# repository builds with changed the day somebody ran `brew install llvm',
# silently, and would change back under a PATH that did not have it. A
# build that picks its own compiler by accident cannot be reasoned about,
# and this directory exists precisely because the choice has to be made
# once and made everywhere.
#
# THE CHOICE IS HOMEBREW'S LLVM WHERE IT IS INSTALLED. It is the newer
# compiler (23.1.0 against Apple's 21.0.0 here) and the one whose libc++
# headers have had the transitive includes taken out, so it says at compile
# time what other platforms would only say later -- ZiguratIP's
# Core/utility.hpp calling std::back_inserter with only <algorithm>
# included is a real omission, and Homebrew's clang is what found it.
#
# ONE libc++ IN THE PROCESS, THOUGH, AND IT IS THE SYSTEM'S. Homebrew's
# clang compiles against its own headers and still links /usr/lib/libc++.1.dylib,
# which is what ZiguratIP's libCore, every module .so and the binary itself
# already link -- checked with `otool -L'. Nothing here adds
# -L/usr/local/opt/llvm/lib/c++ or an rpath to it, and nothing should: two
# libc++ runtimes in one address space is exactly the hazard the README
# means by "the compiler is not a per-repository choice", since cocolog
# links ZiguratIP's C++ libraries into its own binary and dlopen's modules
# into its own process.
#
# $CICILI_CC and $CICILI_CXX still win over all of it, which is how
# `make CICILI_CC=gcc CICILI_CXX=g++' and Apple's own clang stay reachable:
#
#     make CICILI_CC=/usr/bin/clang CICILI_CXX=/usr/bin/clang++
#
coco_compiler() {          # coco_compiler cc|cxx -> the program to exec
  case "$1" in
    cc) _coco_bare=clang;   _coco_set=$CICILI_CC ;;
    *)  _coco_bare=clang++; _coco_set=$CICILI_CXX ;;
  esac
  if [ -n "$_coco_set" ]; then printf '%s\n' "$_coco_set"; return 0; fi
  case "$(uname -s)" in
    Darwin)
      # $HOMEBREW_PREFIX first where the caller has one, then the two
      # prefixes brew actually uses: Apple Silicon, then Intel.
      for _coco_dir in "${HOMEBREW_PREFIX:-/nonexistent}/opt/llvm/bin" \
                       /opt/homebrew/opt/llvm/bin \
                       /usr/local/opt/llvm/bin; do
        if [ -x "$_coco_dir/$_coco_bare" ]; then
          printf '%s\n' "$_coco_dir/$_coco_bare"; return 0
        fi
      done ;;
  esac
  printf '%s\n' "$_coco_bare"
}
