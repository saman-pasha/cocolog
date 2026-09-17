# The part of the install that is the same on every OS. Sourced by
# install-linux.sh and install-macos.sh AFTER they have set HERE, ROOT,
# OS, LIBVAR, BREW and LOG and installed their packages. Not a program.
#
# ZiguratIP/install/common.sh is this file's twin for the first half; the
# two are kept standalone so that each repository installs on its own,
# whatever version of the other is beside it.
#
# In order: find or clone the two checkouts beside this one; give SBCL the
# four Lisp systems Cicili is built from; build ZiguratIP and check its
# ARTIFACTS; build cocolog, compile its Parsi objects into the ZiguratIP
# home, build the loadable modules that have their dependencies; ask the
# binary a question; and print the exports a shell needs afterwards.
SIDE=$(cd "$ROOT/.." && pwd)
CICILI=${CICILI:-$SIDE/cicili}
ZIGURATIP=${ZIGURATIP:-$SIDE/ZiguratIP}
ZIGURATIP_HOME=${ZIGURATIP_HOME:-$ZIGURATIP/home}
QL=${QUICKLISP_HOME:-$HOME/quicklisp}
SHIMS=$ROOT/colab/lisp
step() { printf '== %s\n' "$*"; }
say()  { printf '   %s\n' "$*"; }
die()  { printf 'INSTALL RED: %s\n' "$*" >&2; exit 1; }

# AND THE TWO MUST NAME THE SAME TREE, because ZiguratIP's MVCCS includes
# `../home/include/zexception.hpp' by a path relative to the CHECKOUT while
# every project stages its headers into $(ZIGURATIP_HOME)/include. If those
# disagree the headers land where MVCCS will not look and the build dies in
# mvccs.cpp naming a header that is plainly in the checkout.
#
# THE DEFAULT ABOVE IS WHY IT HAPPENS: `${ZIGURATIP_HOME:-$ZIGURATIP/home}'
# lets a value INHERITED FROM THE ENVIRONMENT beat a ZIGURATIP= passed on the
# command line, so the two silently name different trees. Reported from
# cicili-lang on a Colab runtime that exports ZIGURATIP_HOME from earlier
# work: the build staged into one tree, MVCCS looked in the other, and the
# completeness check -- which also reads $ZIGURATIP_HOME/lib -- found the
# STALE tree's thirteen libraries and reported "only libMVCCS.so missing"
# about a checkout that had built nothing at all. An afternoon, for want of
# this. Refused rather than overridden: an inherited home may be somebody's
# deliberate arrangement, and quietly ignoring it would be its own surprise.
#
# `|| :' ON BOTH, because a plain assignment takes the exit status of its
# command substitution, and `set -e' then kills the script before the
# fallback on the same line can run. Where $ZIGURATIP is not cloned yet --
# the fresh box this installer exists for, since `checkouts' below is what
# clones it -- the `cd' failed and dash exited 2 WITH NO OUTPUT AT ALL: no
# step line, no INSTALL RED, nothing for a reader to go on. The fallback was
# written for exactly that case and never ran, because the assignment IS the
# failing command.
zig_real=$(cd "$ZIGURATIP" 2>/dev/null && pwd -P) || :; [ -n "$zig_real" ] || zig_real=$ZIGURATIP
home_real=$(cd "$ZIGURATIP_HOME" 2>/dev/null && pwd -P) || :; [ -n "$home_real" ] || home_real=$ZIGURATIP_HOME
if [ "$home_real" != "$zig_real/home" ]; then
  printf 'INSTALL RED: ZIGURATIP and ZIGURATIP_HOME name different trees\n' >&2
  printf '   ZIGURATIP      = %s\n' "$ZIGURATIP" >&2
  printf '   ZIGURATIP_HOME = %s   (expected %s)\n' "$ZIGURATIP_HOME" "$zig_real/home" >&2
  printf '   ZiguratIP stages its headers into ZIGURATIP_HOME and its MVCCS\n' >&2
  printf '   includes them by a path relative to the CHECKOUT, so the two must\n' >&2
  printf '   be the same tree. An inherited ZIGURATIP_HOME is the usual cause:\n' >&2
  printf '   run with  env -u ZIGURATIP_HOME ...  or set both to match.\n' >&2
  exit 1
fi

cxx_ok() {   # see ZiguratIP/install/common.sh: 16 on Linux, 10 on macOS, g++ 7+
  cxx=${CICILI_CXX:-clang++}
  case "$cxx" in
    *clang*) v=$("$cxx" --version 2>/dev/null | grep -oE 'version [0-9]+' | grep -oE '[0-9]+' | head -1)
             [ "${v:-0}" -ge "$1" ] ;;
    *)       v=$("$cxx" -dumpversion 2>/dev/null | cut -d. -f1); [ "${v:-0}" -ge 7 ] ;;
  esac
}

checkouts() {
  step "the three checkouts, side by side"
  if [ -f "$CICILI/cicili.lisp" ]; then say "CICILI=$CICILI"
  else say "no Cicili at $CICILI -- cloning it there"; git clone -q https://github.com/saman-pasha/cicili.git "$CICILI"; fi
  if [ -f "$ZIGURATIP/Makefile.global" ]; then say "ZIGURATIP=$ZIGURATIP"
  else say "no ZiguratIP at $ZIGURATIP -- cloning it there"; git clone -q https://github.com/saman-pasha/ZiguratIP.git "$ZIGURATIP"; fi
  say "COCOLOG=$ROOT"
}

lisp_side() {
  step "the Lisp systems Cicili is built from"
  if [ ! -f "$QL/setup.lisp" ]; then
    say "installing Quicklisp into $QL"
    curl -fsSL -o /tmp/quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp \
      || die "cannot reach beta.quicklisp.org -- install Quicklisp by hand into $QL and re-run"
    sbcl --non-interactive --load /tmp/quicklisp.lisp \
         --eval "(quicklisp-quickstart:install :path \"$QL/\")" >/dev/null
  fi
  sbcl --non-interactive --load "$QL/setup.lisp" \
       --eval '(ql:quickload (list :str :cl-ppcre) :silent t)' >/dev/null
  say "str and cl-ppcre: present (Quicklisp)"
  mkdir -p "$HOME/common-lisp"
  cp -R "$SHIMS/sha1" "$SHIMS/base64" "$HOME/common-lisp/"
  if [ -L "$HOME/common-lisp/cicili" ] || [ ! -e "$HOME/common-lisp/cicili" ]; then
    ln -sfn "$CICILI" "$HOME/common-lisp/cicili"
    say "sha1 and base64 shims, and cicili -> $CICILI: in $HOME/common-lisp"
  else
    say "sha1 and base64 shims in $HOME/common-lisp; $HOME/common-lisp/cicili is a directory of its own and stays"
  fi
  sbcl --non-interactive --load "$QL/setup.lisp" --eval '(ql:quickload "cicili" :silent t)' >/dev/null 2>&1 \
    || die "SBCL cannot load the cicili system -- run sbcl and (ql:quickload \"cicili\") to see why"
  say "SBCL loads cicili"
}

build_ziguratip() {
  step "building ZiguratIP (Release) with $(${CICILI_CXX:-clang++} --version | head -1)"
  for d in "$ZIGURATIP"/*/*.depend; do
    [ -f "$d" ] && ! grep -q '\.o:' "$d" && rm -f "$d"     # rule-less: a make that had no compiler
  done
  mkdir -p "$ZIGURATIP_HOME/data" "$ZIGURATIP_HOME/ld" "$ZIGURATIP_HOME/catalog" "$ZIGURATIP_HOME/log" \
           "$ZIGURATIP_HOME/tmp" "$ZIGURATIP_HOME/obj" "$ZIGURATIP_HOME/lib" "$ZIGURATIP_HOME/bin"
  ( cd "$ZIGURATIP" && CICILI="$CICILI" ZIGURATIP_HOME="$ZIGURATIP_HOME" make MODE=Release ) > "$LOG.ziguratip" 2>&1 || true
  missing=""
  for lib in Core StreamIO Type Library Encoding Compression Cryptography Configuration \
             Threading SocketIO Connector HTTP MVCCS Compiler; do
    [ -f "$ZIGURATIP_HOME/lib/lib$lib.so" ] || missing="$missing lib$lib.so"
  done
  for b in parsi parsic ziguratip; do [ -x "$ZIGURATIP_HOME/bin/$b" ] || missing="$missing bin/$b"; done
  if [ -n "$missing" ]; then
    grep -nE 'error:|cannot find -l|library .* not found|Unhandled' "$LOG.ziguratip" | head -12 | sed 's/^/   /'
    die "ZiguratIP incomplete, missing:$missing  (whole log: $LOG.ziguratip)"
  fi
  say "$(ls "$ZIGURATIP_HOME"/lib/*.so | wc -l | tr -d ' ') libraries, $(ls "$ZIGURATIP_HOME/bin" | wc -l | tr -d ' ') executables in $ZIGURATIP_HOME"
}

torch_env() {   # which libtorch the torch module will be built against, if any
  if [ -n "${LIBTORCH:-}${TORCH_INCLUDE:-}" ]; then
    say "libtorch: LIBTORCH=${LIBTORCH:-} TORCH_INCLUDE=${TORCH_INCLUDE:-} TORCH_LIB=${TORCH_LIB:-} (from the environment)"
  elif [ "$OS" = macos ] && [ -f "$BREW/lib/libtorch.dylib" ]; then
    LIBTORCH=$BREW; TORCH_INCLUDE=$BREW/include; TORCH_LIB=$BREW/lib; export LIBTORCH TORCH_INCLUDE TORCH_LIB
    say "libtorch: Homebrew's pytorch, under $BREW"
  elif python3 -c 'import torch' >/dev/null 2>&1; then
    say "libtorch: the pip torch package"
  else
    say "no libtorch: library(torch) will be SKIPPED below (WITH_TORCH=1 installs one)"
  fi
}

build_cocolog() {
  step "building cocolog"
  ( cd "$ROOT" && rm -f cocolog && CICILI="$CICILI" ZIGURATIP="$ZIGURATIP" make ) > "$LOG.cocolog" 2>&1 || true
  if [ ! -x "$ROOT/cocolog" ]; then
    grep -nE -A2 'error:|Unhandled' "$LOG.cocolog" | head -14 | sed 's/^/   /'
    die "no cocolog binary  (whole log: $LOG.cocolog)"
  fi
  say "cocolog built: $(ls -lh "$ROOT/cocolog" | awk '{print $5}')"
  step "the Parsi objects, compiled into $ZIGURATIP_HOME/ld"
  ( cd "$ROOT" && CICILI="$CICILI" ZIGURATIP="$ZIGURATIP" ZIGURATIP_HOME="$ZIGURATIP_HOME" make schema ) > "$LOG.schema" 2>&1 \
    || { tail -8 "$LOG.schema" | sed 's/^/   /'; die "make schema failed  (whole log: $LOG.schema)"; }
  say "$(ls "$ZIGURATIP_HOME"/ld/lib_COCOLOG* 2>/dev/null | wc -l | tr -d ' ') objects"
  step "the loadable modules (SKIPPED names a missing dependency; sh modules/<m>/build.sh says which)"
  torch_env
  ( cd "$ROOT" && CICILI="$CICILI" ZIGURATIP="$ZIGURATIP" make modules ) 2>&1 | sed 's/^/   /'
  step "does it answer"
  ans=$("$ROOT/cocolog" query "X is 6*7, write(X), nl" 2>&1 | tr -d '\r')
  case "$ans" in *42*) say "cocolog answers: 42" ;; *) die "cocolog does not run -- it said: $ans" ;; esac
}

exports_hint() {
  step "installed. Put these in your shell profile:"
  echo "   export CICILI=$CICILI"
  echo "   export ZIGURATIP=$ZIGURATIP"
  echo "   export ZIGURATIP_HOME=$ZIGURATIP_HOME"
  echo "   export $LIBVAR=\$ZIGURATIP_HOME/lib"
  if [ -n "${LIBTORCH:-}" ]; then
    echo "   export LIBTORCH=$LIBTORCH"
    echo "   export TORCH_INCLUDE=${TORCH_INCLUDE:-$LIBTORCH/include}"
    echo "   export TORCH_LIB=${TORCH_LIB:-$LIBTORCH/lib}"
  fi
  say "then: cd $ROOT && make test          (the suite; the database cases SKIP without a server)"
  say "server: cd $ZIGURATIP && ZIGURATIP_HOME=\$PWD/home $LIBVAR=\$PWD/home/lib ./home/bin/ziguratip &"
}
