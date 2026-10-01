#!/bin/sh
# THE COCOLOG DOCKER IMAGES, BUILT ON THE CLOUD LINUX BOX of a Claude Code session:
#
#   sh tools/cloud/docker-build.sh [plain|full|both]     build, then smoke-test (default: both)
#   sh tools/cloud/docker-build.sh smoke IMAGE [CASE...] smoke-test an image that exists
#   sh tools/cloud/docker-build.sh save [plain|full|both]   the tarballs `make docker-save' makes
#   SAVE=1 ... [plain|full|both]                         build, smoke-test, then save
#   DRY_RUN=1 ... [plain|full|both]                      write the contexts and the derived
#                                                        Dockerfile, then stop: no daemon, no build
#
# `make docker' does not work on that box as it stands, and this script is what it needed. It
# builds the SAME TWO IMAGES under the SAME TAGS as the Makefile -- cocolog:VERSION and :latest
# with no optional part, cocolog:VERSION-ray-torch-numpy and :ray-torch-numpy with WITH_RAY
# WITH_TORCH WITH_NUMPY -- from the repo's own Dockerfile, which it never edits, and smoke-tests
# each with no network. Every point below was found by a build that failed or a check that said
# no, on 2026-10-01, in this order:
#
#  1. THE DAEMON IS NOT RUNNING at the start of a session, and it dies with the VM, which
#     restarts at every idle gap between turns (`uname -r' changes; dockerd and ziguratip are
#     gone; /var/lib/docker and the files stay). A build dies with it -- BuildKit keeps the steps
#     that finished -- so KEEP THE TURN ACTIVE while one runs. The daemon is started detached,
#     with no bridge and no iptables: builds use the host network, runs use none.
#  2. THE ONLY WAY OUT IS THE SESSION'S HTTPS PROXY, $HTTPS_PROXY (127.0.0.1:PORT, HTTPS only),
#     and its CA, /root/.ccr/ca-bundle.crt (/root/.ccr/README.md). THE PORT AND THE CA CHANGE AT
#     EVERY RESTART (44693, 37937 and 39445 in one afternoon), so both are read live and
#     nothing is written down.
#  3. A CONTAINER CANNOT REACH THAT PROXY, so the build runs `--network host', and the proxy and
#     the CA reach only the RUN steps that need them, from a bind-mounted context
#     (--build-context ccr=DIR): never a layer, never an ARG. The image carries no trace of
#     either -- checked: no proxy port in `docker history', no extra CA, no /ccr, apt's
#     sources back to http. THE AUTO-MODE SAFETY CHECK REFUSES `docker build --network host' AS A
#     CONTAINMENT ESCAPE UNTIL THE OWNER SAYS SO IN THE CHAT (they did: "go-ahead for docker
#     build --network host"). Ask first. Do not retry it in pieces.
#  4. apt GOES OVER https, THROUGH THE PROXY: the base image's sources are
#     http://archive.ubuntu.com and http://security.ubuntu.com, rewritten for the RUN and put
#     back after. The first version wrote its `sed' with | as the delimiter AND as the
#     alternation, matched nothing, and apt went out over plain http, past the proxy.
#  5. QUICKLISP'S HOST SPEAKS HTTP ONLY, which the proxy refuses (405). install-linux.sh
#     installs Quicklisp where $HOME/quicklisp/setup.lisp is missing, so the image gets a
#     stand-in setup.lisp that loads the same systems through ASDF from the Lisp libraries this
#     box already holds in $HOME/common-lisp (what Cicili itself runs on), copied with their
#     links resolved. THE IMAGE'S LISP LIBRARIES ARE THEREFORE THIS BOX'S AND NOT QUICKLISP'S:
#     the one way it differs from a `make docker' on a Mac.
#  6. THE DOCKERFILE IS DERIVED, NOT EDITED: its three network RUN blocks get the bind mount,
#     `. /ccr/on.sh' before and `. /ccr/off.sh' after, and two COPY lines bring the Lisp
#     libraries. The awk refuses, naming what it found, when the Dockerfile no longer has
#     exactly those three blocks -- the owner edits it, and a quiet mismatch would build
#     something else.
#  7. ANY CHANGE TO THE TREE REBUILDS THE INSTALL STEP, because `COPY . /opt/cocolog' comes before
#     it: 6 minutes for the plain image with apt's cache warm (1.24 GB, 298 MB saved), 9 for the
#     full one (3.05 GB, 686 MB saved; torch's wheel and raylib built from source) -- the
#     owner's Mac gave 1.26 GB and 3.07 GB.
#  8. THE ray CASE RUNS UNDER xvfb-run WITH `docker run --init': as PID 1 the script waits for ever
#     for the X server's ready signal and the case never starts (nine minutes at a load of 0.06).
#     Every case has a time limit, CASE_TIMEOUT seconds (900), so a hang is red and not endless.
#
# NOT HERE: A TAG OR A RELEASE. There is no `gh' on the box and a session's GitHub tools have
# no create-release or create-tag. Make them elsewhere, from the tarballs `save' leaves in
# dist/ (git-ignored, as for `make docker-save').
#
# Where `make docker' works (a Mac, a Linux desktop) use it. This script exits at once when
# there is no session proxy, so it cannot be run there by mistake.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../.." && pwd)
MODE=${1:-both}
WORK=${WORK:-${TMPDIR:-/tmp}/cocolog-docker}
DIST=${DIST:-$ROOT/dist}
bad=0
step() { printf '== %s\n' "$*"; }
say()  { printf '   %s\n' "$*"; }
die()  { printf 'DOCKER RED: %s\n' "$*" >&2; exit 1; }
USAGE="usage: docker-build.sh [plain|full|both] | smoke IMAGE [CASE...] | save [plain|full|both]"
WHAT=$MODE
case "$MODE" in
  plain|full|both) ;;
  smoke) [ $# -ge 2 ] || die "$USAGE" ;;
  save)  WHAT=${2:-both}; case "$WHAT" in plain|full|both) ;; *) die "$USAGE" ;; esac ;;
  *)     die "$USAGE" ;;
esac

command -v docker >/dev/null 2>&1 && command -v dockerd >/dev/null 2>&1 || die "docker and dockerd are not installed here"
[ -n "${HTTPS_PROXY:-}" ] || die "no HTTPS_PROXY: this is not a session box; use make docker"
[ -f /root/.ccr/ca-bundle.crt ] || die "no /root/.ccr/ca-bundle.crt: this is not a session box; use make docker"
VERSION=$(grep -o 'return "[0-9.]*"' "$ROOT/cocolog.cicili" | head -1 | grep -o '[0-9.][0-9.]*')   # the Makefile's own line
ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')
mkdir -p "$WORK"

ensure_daemon() {
  step "the daemon"
  if docker info >/dev/null 2>&1; then say "dockerd answers already"; return 0; fi
  say "starting dockerd, detached, with the live proxy for its pulls (log: $WORK/dockerd.log)"
  setsid env HTTPS_PROXY="$HTTPS_PROXY" https_proxy="$HTTPS_PROXY" SSL_CERT_FILE=/root/.ccr/ca-bundle.crt \
    dockerd --iptables=false --ip6tables=false --bridge=none > "$WORK/dockerd.log" 2>&1 < /dev/null &
  n=0
  until docker info >/dev/null 2>&1; do
    n=$((n + 1)); [ "$n" -le 60 ] || die "dockerd did not answer in a minute: $WORK/dockerd.log"; sleep 1
  done
  say "dockerd answers after ${n}s"
}

dbuild() {   # dbuild LOG DOCKER-BUILD-ARGS... : the one build line both images share
  log=$1; shift
  say "docker build --network host $* (log: $log)"
  t0=$(date +%s)
  docker build --network host --progress=plain \
    --build-context ccr="$WORK/ccr" --build-context lisp="$WORK/lisp" \
    -f "$WORK/Dockerfile.sandbox" "$@" "$ROOT" > "$log" 2>&1 \
    || { tail -25 "$log" | sed 's/^/   /' >&2; die "the build failed: $log"; }
  say "built in $(( $(date +%s) - t0 )) s"
}

smoke() {   # smoke IMAGE CASE... : every container with NO network; a red check is counted, not fatal
  img=$1; shift
  step "smoke test of $img, with no network"
  docker image inspect "$img" >/dev/null 2>&1 || die "no image $img here"
  v=$(docker run --rm --network none "$img" --version 2>&1) || :
  case "$v" in "cocolog "*) say "--version: $v" ;; *) say "RED --version said: $v"; bad=$((bad + 1)) ;; esac
  q=$(docker run --rm --network none "$img" query 'X is 6*7, write(X), nl' 2>&1 | head -1) || :
  if [ "$q" = 42 ]; then say "a query: 42"; else say "RED the query said: $q"; bad=$((bad + 1)); fi
  mkdir -p "$WORK/smoke-kb"
  docker run --rm --network none -v "$WORK/smoke-kb":/work "$img" --embed KB query 'retractall(smoke(_)), assertz(smoke(42))' >/dev/null 2>&1 || :
  e=$(docker run --rm --network none -v "$WORK/smoke-kb":/work "$img" --embed KB query 'smoke(X), write(X), nl' 2>&1 | head -1) || :
  if [ "$e" = 42 ]; then say "an --embed store, written by one container and read by a second: 42"; else say "RED the second container read: $e"; bad=$((bad + 1)); fi
  r=$(printf 'X is 6*7.\n' | docker run --rm -i --network none "$img" 2>&1) || :
  case "$r" in *"X = 42"*) say "the REPL from a pipe: X = 42" ;; *) say "RED the REPL said: $r"; bad=$((bad + 1)) ;; esac
  for c in "$@"; do
    rc=0; out=$(run_case "$img" "$c") || rc=$?
    if printf '%s\n' "$out" | grep -q "^$c  *GREEN"; then say "case $c: GREEN"
    elif [ "$rc" = 124 ] || [ "$rc" = 137 ]; then say "RED case $c: no answer in ${CASE_TIMEOUT:-900} s, stopped"; bad=$((bad + 1))
    else say "RED case $c: $(printf '%s\n' "$out" | tail -3 | tr '\n' ' ')"; bad=$((bad + 1)); fi
  done
}

run_case() {   # run_case IMAGE CASE : one case of the suite inside the image, with no network and a time limit
  # --init: AS PID 1, xvfb-run WAITS FOR EVER for the X server's ready signal (the case never
  # starts: nine minutes at a load of 0.06, 2026-10-01); under a real init the ray case takes 2 s
  case "$2" in
    ray) timeout -k 20 "${CASE_TIMEOUT:-900}" docker run --rm --init --network none -w /opt/cocolog --entrypoint xvfb-run "$1" -a cocolog -s test/run.pl -- ray 2>&1 ;;
    *)   timeout -k 20 "${CASE_TIMEOUT:-900}" docker run --rm --init --network none -w /opt/cocolog "$1" -s test/run.pl -- "$2" 2>&1 ;;
  esac
}

save_tarballs() {   # save_tarballs plain|full|both : as `make docker-save' makes them
  step "docker save, into $DIST"
  mkdir -p "$DIST"
  case "$1" in plain|both)
    docker save "cocolog:$VERSION" cocolog:latest | gzip -9 > "$DIST/cocolog-$VERSION-docker-$ARCH.tar.gz" ;;
  esac
  case "$1" in full|both)
    docker save "cocolog:$VERSION-ray-torch-numpy" cocolog:ray-torch-numpy | gzip -9 > "$DIST/cocolog-$VERSION-ray-torch-numpy-docker-$ARCH.tar.gz" ;;
  esac
  ( cd "$DIST" && sha256sum ./*.tar.gz | sed 's# \./# #' > SHA256SUMS )
  ls -l "$DIST"
}

finish() {
  step "images"
  docker images --format '{{.Repository}}:{{.Tag}}  {{.Size}}' | grep '^cocolog:' | sed 's/^/   /' || :
  [ "$bad" -eq 0 ] || die "$bad smoke check(s) red"
  step "done: every smoke check green"
}

# ---- the modes that need no build context -------------------------------------------------
case "$MODE" in
  smoke) shift; ensure_daemon; smoke "$@"; finish; exit 0 ;;
  save)  ensure_daemon; save_tarballs "$WHAT"; exit 0 ;;
esac

step "cocolog $VERSION, $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo 'no git'), from $ROOT; working files in $WORK"
[ -z "$(git -C "$ROOT" status --porcelain 2>/dev/null)" ] || say "the tree is NOT clean: the image holds it as it stands"

# ---- the proxy and the CA, from this session's live values -------------------------------
step "the proxy and CA context: $HTTPS_PROXY"
mkdir -p "$WORK/ccr"
cp /root/.ccr/ca-bundle.crt "$WORK/ccr/ca-bundle.crt"          # the public bundle; nothing else of /root/.ccr
cat > "$WORK/ccr/on.sh.in" <<'EOT'
# sourced at the start of a RUN: the proxy and the CA of this sandbox, for this RUN only
export https_proxy=@PROXY@ HTTPS_PROXY=@PROXY@
export SSL_CERT_FILE=/ccr/ca-bundle.crt CURL_CA_BUNDLE=/ccr/ca-bundle.crt GIT_SSL_CAINFO=/ccr/ca-bundle.crt
export REQUESTS_CA_BUNDLE=/ccr/ca-bundle.crt PIP_CERT=/ccr/ca-bundle.crt
mkdir -p /etc/apt/apt.conf.d
printf 'Acquire::https::Proxy "@PROXY@";\nAcquire::https::CaInfo "/ccr/ca-bundle.crt";\n' > /etc/apt/apt.conf.d/99ccr
[ -f /etc/apt/sources.list.d/ubuntu.sources ] && sed -i 's#http://\([a-z]*\.ubuntu\.com\)#https://\1#g' /etc/apt/sources.list.d/ubuntu.sources
true
EOT
sed "s|@PROXY@|$HTTPS_PROXY|g" "$WORK/ccr/on.sh.in" > "$WORK/ccr/on.sh"
cat > "$WORK/ccr/off.sh" <<'EOT'
# sourced at the end of a RUN: leaves apt and the environment as the plain Dockerfile would
rm -f /etc/apt/apt.conf.d/99ccr
[ -f /etc/apt/sources.list.d/ubuntu.sources ] && sed -i 's#https://\([a-z]*\.ubuntu\.com\)#http://\1#g' /etc/apt/sources.list.d/ubuntu.sources
unset https_proxy HTTPS_PROXY SSL_CERT_FILE CURL_CA_BUNDLE GIT_SSL_CAINFO REQUESTS_CA_BUNDLE PIP_CERT
true
EOT

# ---- the Lisp libraries and the Quicklisp stand-in ----------------------------------------
step "the Lisp libraries of this box, and the Quicklisp stand-in"
mkdir -p "$WORK/lisp/common-lisp" "$WORK/lisp/quicklisp"
for n in str cl-ppcre cl-change-case cl-unicode cl-flexi-streams cl-trivial-gray-streams; do
  [ -e "$HOME/common-lisp/$n" ] || die "$HOME/common-lisp/$n is missing: this box's Cicili setup does not hold it and Quicklisp cannot be reached"
  mkdir -p "$WORK/lisp/common-lisp/$n"
  cp -rL "$HOME/common-lisp/$n/." "$WORK/lisp/common-lisp/$n/"
done
cat > "$WORK/lisp/quicklisp/setup.lisp" <<'EOT'
;;; A stand-in for Quicklisp's setup.lisp, for a build that cannot reach beta.quicklisp.org (HTTP
;;; only; the session proxy carries HTTPS only). ql:quickload loads the system through ASDF from
;;; ~/common-lisp/, where tools/cloud/docker-build.sh put the libraries beforehand.
(require :asdf)
(defpackage :ql (:use :cl) (:export #:quickload))
(in-package :ql)
(defun quickload (systems &key silent &allow-other-keys)
  (declare (ignore silent))
  (dolist (s (if (listp systems) systems (list systems)))
    (asdf:load-system s))
  systems)
EOT
say "$(ls "$WORK/lisp/common-lisp" | tr '\n' ' ')"

# ---- the Dockerfile, derived ---------------------------------------------------------------
step "the Dockerfile, derived: $WORK/Dockerfile.sandbox"
awk '
function flush(   i, k, line, need, joined) {
  if (n == 0) return
  joined = ""
  for (i = 1; i <= n; i++) joined = joined "\n" b[i]
  need = index(joined, "apt-get update") || index(joined, "git clone -q https://github.com/saman-pasha/cicili.git") || index(joined, "sh install/install-linux.sh")
  if (!need) { for (i = 1; i <= n; i++) print b[i]; n = 0; return }
  wrapped++
  line = b[1]; sub(/^RUN /, "", line)
  if (line ~ /^--mount=/) {
    print b[1]; k = 2
    while (k <= n && b[k] ~ /^[ \t]+--mount=/) { print b[k]; k++ }
    print "    --mount=type=bind,from=ccr,target=/ccr \\"
  } else {
    print "RUN --mount=type=bind,from=ccr,target=/ccr \\"; k = 1
  }
  print "    . /ccr/on.sh \\"
  for (i = k; i <= n; i++) {
    line = b[i]
    if (i == 1) sub(/^RUN /, "", line)
    if (i == k) { sub(/^[ \t]+/, "", line); line = " && " line }
    if (i == n) { print line " \\"; print " && . /ccr/off.sh" } else print line
  }
  n = 0
}
{
  if (inrun) { b[++n] = $0; if ($0 !~ /\\$/) { inrun = 0; flush() } next }
  if ($0 ~ /^RUN /) { n = 0; b[++n] = $0; if ($0 ~ /\\$/) inrun = 1; else flush(); next }
  print
  if ($0 == "WORKDIR /opt/cocolog" && !copied) {
    print "COPY --from=lisp /common-lisp /root/common-lisp"
    print "COPY --from=lisp /quicklisp /root/quicklisp"
    copied = 1
  }
}
END {
  if (wrapped != 3 || !copied) {
    printf "the Dockerfile has changed: wanted 3 network RUN blocks to wrap and a WORKDIR /opt/cocolog to follow, found %d and %d\n", wrapped, copied + 0 > "/dev/stderr"
    exit 1
  }
}' "$ROOT/Dockerfile" > "$WORK/Dockerfile.sandbox" || die "cannot derive the Dockerfile; read point 6 of this script's header"
say "3 RUN blocks wrapped, 2 COPY lines added"

if [ "${DRY_RUN:-0}" = 1 ]; then step "DRY_RUN: the contexts and the derived Dockerfile are written; no daemon, no build"; exit 0; fi

# ---- the builds ---------------------------------------------------------------------------
ensure_daemon
case "$WHAT" in plain|both)
  step "the plain image: cocolog:$VERSION, cocolog:latest"
  dbuild "$WORK/build-plain.log" -t "cocolog:$VERSION" -t cocolog:latest
  smoke "cocolog:$VERSION" engine gc string ;;
esac
case "$WHAT" in full|both)
  step "the full image: cocolog:$VERSION-ray-torch-numpy, cocolog:ray-torch-numpy"
  dbuild "$WORK/build-full.log" --build-arg WITH_RAY=1 --build-arg WITH_TORCH=1 --build-arg WITH_NUMPY=1 \
    -t "cocolog:$VERSION-ray-torch-numpy" -t cocolog:ray-torch-numpy
  smoke "cocolog:$VERSION-ray-torch-numpy" engine gc string numpy langs clay ray ;;
esac
if [ "${SAVE:-0}" = 1 ]; then save_tarballs "$WHAT"; fi
finish
