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

cxx_ok() {   # see ZiguratIP/install/common.sh: 16 on Linux, 10 on macOS -- and clang
  cxx=${CICILI_CXX:-clang++}  # only: every build here is clang, so another compiler fails this
  case "$cxx" in
    *clang*) v=$("$cxx" --version 2>/dev/null | grep -oE 'version [0-9]+' | grep -oE '[0-9]+' | head -1)
             [ "${v:-0}" -ge "$1" ] ;;
    *)       return 1 ;;
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

# EACH FILE A BUILD WRITES ITS OUTPUT TO MUST BE THIS USER'S TO WRITE. A run
# that was root's from end to end (before install-linux.sh handed the rest to
# the user who called sudo) left its logs in /tmp owned by root, and /tmp is
# sticky: the user's `> $LOG.ziguratip' then fails, the `|| true' after the
# build swallows it, and the artifact check reads root's OLD log and reports
# a failure that is not this run's.
log_ok() {
  for f in "$@"; do
    if [ -e "$f" ]; then [ -w "$f" ] || die "$f is not $(id -un)'s to write (an earlier run as root left it?) -- remove it, or LOG=/elsewhere"
    else [ -w "$(dirname "$f")" ] || die "cannot write $f -- LOG=/elsewhere"; fi
  done
}

# QUICKLISP AS ITS OWN PAGE SAYS (https://www.quicklisp.org/beta/): fetch
# quicklisp.lisp and its signature, check the signature against Quicklisp's
# release key, load it and install, then (ql:add-to-init-file) -- below, in
# lisp_side. The key comes from the same server as the file, so it is held to
# the fingerprint that page publishes. gpgv checks against a keyring of that
# one key and starts no agent; gpg only turns the armored key into a keyring.
# Everything goes in a directory of its own: a /tmp/quicklisp.lisp another
# user's run left is not this user's to overwrite.
QL_KEY=D7A3489DDEFE32B7D0E7CC61307965AB028B5FF7
quicklisp_get() {
  command -v gpg >/dev/null 2>&1 \
    || die "gpg is needed to verify quicklisp.lisp, as Quicklisp's instructions do -- install gnupg, or Quicklisp by hand into $QL, and re-run"
  gpgv=$(command -v gpgv 2>/dev/null || command -v gpgv2 2>/dev/null) \
    || die "gpgv is needed to verify quicklisp.lisp (it comes with gnupg) -- or install Quicklisp by hand into $QL and re-run"
  qt=$(mktemp -d "${TMPDIR:-/tmp}/quicklisp.XXXXXX")
  for f in quicklisp.lisp quicklisp.lisp.asc release-key.txt; do
    curl -fsSL -o "$qt/$f" "https://beta.quicklisp.org/$f" \
      || { rm -rf "$qt"; die "cannot reach beta.quicklisp.org for $f -- install Quicklisp by hand into $QL and re-run"; }
  done
  gpg --homedir "$qt" --batch --dearmor < "$qt/release-key.txt" > "$qt/key.gpg" 2>/dev/null \
    || { rm -rf "$qt"; die "gpg cannot read Quicklisp's release key"; }
  if ! "$gpgv" --homedir "$qt" --keyring "$qt/key.gpg" --status-fd 1 "$qt/quicklisp.lisp.asc" "$qt/quicklisp.lisp" 2>/dev/null \
       | grep -q "^\[GNUPG:\] VALIDSIG .* $QL_KEY\$"; then
    rm -rf "$qt"; die "quicklisp.lisp does not verify against Quicklisp's release key $QL_KEY -- nothing installed"
  fi
  say "quicklisp.lisp verified: signed by $QL_KEY"
  sbcl --non-interactive --load "$qt/quicklisp.lisp" \
       --eval "(quicklisp-quickstart:install :path \"$QL/\")" >/dev/null \
    || { rm -rf "$qt"; die "(quicklisp-quickstart:install) failed -- run it by hand: sbcl --load quicklisp.lisp"; }
  rm -rf "$qt"
}

# CICILI'S BUILD FINDS QUICKLISP ITSELF. Every build runs `sbcl --script
# cicili.lisp', and --script reads no ~/.sbclrc, so what loads Quicklisp
# there is cicili.lisp's own lines: since Cicili 1.0.1 they read
# $QUICKLISP_HOME and fall back to ~/quicklisp; before, they named
# (user-homedir-pathname)/quicklisp/setup.lisp and nothing else, and a
# QUICKLISP_HOME elsewhere installed, loaded cicili below (lisp_side names
# $QL/setup.lisp), and then every build died with `Component "str" not
# found'. So a QUICKLISP_HOME elsewhere is taken when $CICILI's cicili.lisp
# reads it -- exported for the builds below, and printed by exports_hint for
# the ones after -- and refused by name against an older checkout. It must
# be absolute: each build reads it from a directory of its own. The same
# directory by another path is ~/quicklisp, and so is $HOME/quicklisp as a
# symlink to $QL, even before $QL exists. Asked in lisp_side, not when this
# file is sourced: under sudo the packages' phase has root's $HOME, and the
# checkout is cloned by then.
ql_home_ok() {
  case $QL in /*) ;; *) die "QUICKLISP_HOME=$QL is not an absolute path, and every build reads it from a directory of its own -- give it as /..., and re-run" ;; esac
  q=$QL; while [ "${q%/}" != "$q" ]; do q=${q%/}; done
  [ "$q" = "$HOME/quicklisp" ] && return 0
  a=$(cd "$q" 2>/dev/null && pwd -P) || :
  b=$(cd "$HOME/quicklisp" 2>/dev/null && pwd -P) || :
  [ -n "$a" ] && [ "$a" = "$b" ] && return 0
  r=$(readlink "$HOME/quicklisp" 2>/dev/null) || :
  [ -n "$r" ] && [ "${r%/}" = "$q" ] && return 0
  if grep -q 'getenv "QUICKLISP_HOME"' "$CICILI/cicili.lisp" 2>/dev/null; then
    QUICKLISP_HOME=$QL; export QUICKLISP_HOME
    say "QUICKLISP_HOME=$QL, which the Cicili at $CICILI reads -- keep it exported for every build"
    return 0
  fi
  die "QUICKLISP_HOME=$QL is not $HOME/quicklisp, and the Cicili at $CICILI is older than 1.0.1, the first whose cicili.lisp reads QUICKLISP_HOME (sbcl --script reads no ~/.sbclrc, and an older one loads (user-homedir-pathname)/quicklisp/setup.lisp only) -- update it (git -C $CICILI pull), unset QUICKLISP_HOME, or make $HOME/quicklisp a symlink to $QL, and re-run"
}

lisp_side() {
  step "the Lisp systems Cicili is built from"
  ql_home_ok
  if [ ! -f "$QL/setup.lisp" ]; then
    say "installing Quicklisp into $QL"
    quicklisp_get
  fi
  # the last step of Quicklisp's instructions, so the user's own sbcl loads
  # it. (ql:add-to-init-file) asks for Enter and appends at every call, hence
  # the newline and the look first. Cicili's build loads Quicklisp itself,
  # from $QUICKLISP_HOME or ~/quicklisp (ql_home_ok).
  if grep -qE 'quicklisp-init|setup\.lisp' "$HOME/.sbclrc" 2>/dev/null; then
    say "$HOME/.sbclrc loads Quicklisp already"
  else
    printf '\n' | sbcl --non-interactive --load "$QL/setup.lisp" --eval '(ql:add-to-init-file)' >/dev/null \
      || die "(ql:add-to-init-file) failed -- run sbcl --load $QL/setup.lisp and call it by hand"
    say "$HOME/.sbclrc loads Quicklisp now ((ql:add-to-init-file))"
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

# THE RAYLIB library(ray) IS BUILT AGAINST, when WITH_RAY=1 asks for one.
# On macOS Homebrew's (install-macos.sh installs it; pkg-config finds it). On
# Linux there is no package for Ubuntu 24.04, so it is built here, beside the
# checkouts, the way modules/ray/build.sh's header says: the objects compiled
# PIC by the SHARED build, archived, because a .so cannot swallow raylib's
# default non-PIC archive. RAYLIB in the environment wins over all of it.
RAYLIB_TAG=${RAYLIB_TAG:-6.0}
ray_env() {
  [ "${WITH_RAY:-0}" = 1 ] || { say "no WITH_RAY=1: library(ray) will be SKIPPED below"; return 0; }
  if [ -n "${RAYLIB:-}" ]; then say "raylib: RAYLIB=$RAYLIB (from the environment)"; return 0; fi
  if [ "$OS" = macos ]; then say "raylib: Homebrew's, under $BREW"; return 0; fi
  RAYLIB=$SIDE/raylib; export RAYLIB
  if [ ! -f "$RAYLIB/lib/libraylib.a" ]; then
    # ONLY src/, over HTTP/1.1, three tries. The repository is mostly its
    # examples and their media, and a slow link broke the whole clone on an
    # HTTP/2 stream nine minutes in (`RPC failed; curl 92 HTTP/2 stream 5 was
    # not closed cleanly'); the library is a few megabytes of it.
    n=0
    until [ -f "$RAYLIB/src/raylib.h" ]; do
      n=$((n + 1)); [ "$n" -le 3 ] || die "cannot clone raylib $RAYLIB_TAG into $RAYLIB"
      rm -rf "$RAYLIB"
      git -c http.version=HTTP/1.1 -c advice.detachedHead=false clone -q --depth 1 --filter=blob:none --sparse \
          --branch "$RAYLIB_TAG" https://github.com/raysan5/raylib.git "$RAYLIB" \
        && git -C "$RAYLIB" sparse-checkout set src \
        || say "raylib: clone attempt $n failed"
    done
    ( cd "$RAYLIB/src" && make PLATFORM=PLATFORM_DESKTOP RAYLIB_LIBTYPE=SHARED CC="${CICILI_CC:-clang}" ) > "$LOG.raylib" 2>&1 \
      || { tail -8 "$LOG.raylib" | sed 's/^/   /'; die "raylib did not build  (whole log: $LOG.raylib)"; }
    mkdir -p "$RAYLIB/lib" && ar rcs "$RAYLIB/lib/libraylib.a" "$RAYLIB"/src/*.o
  fi
  say "raylib $RAYLIB_TAG: $RAYLIB, built PIC"
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
  ray_env
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
  [ -n "${QUICKLISP_HOME:-}" ] && echo "   export QUICKLISP_HOME=$QUICKLISP_HOME"
  if [ -n "${LIBTORCH:-}" ]; then
    echo "   export LIBTORCH=$LIBTORCH"
    echo "   export TORCH_INCLUDE=${TORCH_INCLUDE:-$LIBTORCH/include}"
    echo "   export TORCH_LIB=${TORCH_LIB:-$LIBTORCH/lib}"
  fi
  [ -n "${RAYLIB:-}" ] && echo "   export RAYLIB=$RAYLIB"
  say "then: cd $ROOT && make test          (the suite; the database cases SKIP without a server)"
  say "server: cd $ZIGURATIP && ZIGURATIP_HOME=\$PWD/home $LIBVAR=\$PWD/home/lib ./home/bin/ziguratip &"
}
