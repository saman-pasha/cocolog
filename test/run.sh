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
[ -n "$1" ] && CASES="$1"

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
#   groups  twelve interpreters sharing four machine STATES
#   ruler   one interpreter writing the KNOWLEDGE BASE while eight read it
for c in files trace vacuum repl tunnel tensors library bigint zigurat-lib groups ruler; do
  [ -n "$1" ] && [ "$1" != "$c" ] && continue
  printf '%-10s ' "$c"
  if [ ! -x "$ROOT/cocolog" ]; then
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
