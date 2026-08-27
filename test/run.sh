#!/bin/sh
# The whole suite.
#
#   sh test/run.sh              everything
#   sh test/run.sh solve        one file
#   sh test/run.sh groups       just the twelve-interpreter one
#   sh test/run.sh files        just the SWI conformance one
#   sh test/run.sh ruler        just the one-writer-many-readers one
#
# The database tests SKIP when there is no server, because "no server here" and
# "the backend is wrong" are different findings. To run them, raise a ZiguratIP
# server and compile the schema into its home first:
#
#   export ZIGURATIP_HOME=/path/to/ZiguratIP/home
#   make schema
#   $ZIGURATIP_HOME/bin/ziguratip &

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
SBCL=${SBCL:-sbcl}

if [ ! -f "$CICILI/cicili.lisp" ]; then
  echo "cocolog: set CICILI to a Cicili checkout (looked in $CICILI)" >&2
  exit 1
fi

CASES="term syntax solve module state zigurat shared"
# NAMING ONE CASE used to set CASES unconditionally, so `run.sh groups'
# -- an invocation this file's own header offers -- went looking for
# test/groups.cicili, failed to build it, and reported BUILD FAILED
# beside the GREEN of the case that then ran anyway. The cases below are
# the .cicili ones; a name that is not one of them belongs to the shell
# loop further down, and this loop should run nothing at all.
if [ -n "$1" ]; then
  if [ -f "$HERE/$1.cicili" ]; then CASES="$1"; else CASES=""; fi
fi

red=0
for c in $CASES; do
  printf '%-10s ' "$c"
  # Cicili takes the directory it starts in as where its own library lives, so
  # it is run from its own checkout with the target named absolutely.
  if ! (cd "$CICILI" && "$SBCL" --script cicili.lisp "$HERE/$c.cicili") > "$HERE/.$c.build" 2>&1; then
    echo "BUILD FAILED"
    tail -5 "$HERE/.$c.build"
    red=$((red + 1))
    continue
  fi
  rm -f "$HERE/.$c.build"
  out=$("$HERE/cocolog_${c}_test" 2>&1) || true
  last=$(echo "$out" | tail -1)
  case "$last" in
    GREEN*) echo "GREEN" ;;
    SKIP*)  echo "SKIP" ;;
    *)      case "$out" in
              SKIP*) echo "SKIP" ;;
              *) echo "$last"; echo "$out" | grep '^FAIL' | head -5; red=$((red + 1)) ;;
            esac ;;
  esac
done

# These are not .cicili cases: each drives the built PROGRAM rather than a test
# binary, so they are shell scripts. They run last because they are the slowest
# and because everything above them has to be right for them to mean anything.
#
#   files   the Files module, run against SWI-Prolog and compared line for line
#   trace   the four-port tracer, run against SWI-Prolog's and compared
#           port for port
#   vacuum  the reclaim pass: the verb in both arrangements, and the gate
#           on the vacuum_kb builtin
#   repl    the toplevel, piped: SWI's answer shapes, one session one
#           world, and a session's writes read by a second process
#   tunnel  the Zeytun reader behind a hostname-routing edge -- the local
#           rehearsal of the Cloudflare tunnel in colab/COLAB.md
#   tensors model parameters as Vector<Double> rows: the table on the
#           wire, the paged tensor page over HTTP, the chunk fallback
#   http    HTTP/1.1 as a grammar over those bytes -- the decoding checked
#           against Python's urllib, the whole thing against curl, and the
#           refusals (obs-fold, chunked, a short body) checked too
#   curl    the client half, over cicili's libcurl binding. SKIPs where
#           library/curl.so was never built, because libcurl is
#           deliberately NOT a dependency of the core binary
#   thread  threads that share nothing and channels that copy. Two of its
#           claims cannot be read off the code: that eight senders lose
#           nothing into one channel (counted, not timed) and that four
#           threads are really parallel (timed, because there is no other
#           way) -- the rest is semantics and cheap
#   httpd   the server half: routing, and the four ways a static file
#           server hands out what it was not asked for -- traversal,
#           encoded traversal, NUL truncation and source disclosure --
#           each checked with the file it would have leaked really on
#           disk. Most of it opens no port, because httpd_answer/3 is
#           the whole server minus the accept loop; the keep-alive cases
#           do, because holding ONE socket across several requests is the
#           thing under test and no client library can be asked to prove it
#   tcp     the socket seam: a handle that is NOT a file descriptor, a
#           timeout that fails rather than hanging, every byte surviving
#           a read, and one process reaching another
#   colab   the notebook and the scripts beside it, without a VM: the
#           two version declarations that live in THIS repository
#           agreeing, so that the only copy free to drift is the one
#           in somebody's browser -- which is what section 1 checks
#   groups  twelve interpreters sharing four machine STATES
#   ruler   one interpreter writing the KNOWLEDGE BASE while eight read it
for c in files trace vacuum repl tunnel tensors library bigint zigurat-lib tcp thread http curl httpd colab groups ruler; do
  [ -n "$1" ] && [ "$1" != "$c" ] && continue
  printf '%-10s ' "$c"
  # `colab' reads the notebook and the scripts beside it; it needs no
  # binary, so it must not be skipped for want of one.
  if [ ! -x "$ROOT/cocolog" ] && [ "$c" != colab ]; then
    echo "SKIP (build cocolog first)"
    continue
  fi
  # `files' lives in its own directory because it is a harness plus a set of
  # Prolog files that are read by two different Prologs
  script="$HERE/$c.sh"
  [ "$c" = files ] && script="$HERE/files/run.sh"
  out=$(sh "$script" 2>&1) || true
  case $(echo "$out" | tail -1) in
    GREEN*) echo "GREEN" ;;
    SKIP*)  echo "SKIP" ;;
    *)      echo "$out" | tail -1
            echo "$out" | grep '^FAIL' | head -5
            red=$((red + 1)) ;;
  esac
done

echo
echo "red: $red"
[ "$red" -eq 0 ]
