#!/bin/sh
# Runs the C connector probe against a server of its own.
#
#   Test/run-c-connector.sh
#
# IT BUILDS ITS OWN HOME. The probe inserts rows, and a transaction that is
# abandoned holds its locks until it is reaped -- so a run that fails half way
# can make the NEXT run block on a lock and look like a protocol bug. Rather
# than depend on the developer's home/data being in a good mood, this makes a
# throwaway ZIGURATIP_HOME under a temporary directory: the read-only parts are
# symlinked, the parts the server writes are its own, and the whole thing goes
# away at the end. What it proves is therefore reproducible from a clean
# checkout and cannot be poisoned by an earlier run.
#
# The cocolog objects are compiled with the parsi program, not sent over the
# wire: `compile' over a connection is refused unless COMPILER/REMOTE_MODE is
# TRUE, and it is FALSE by default because it is remote code execution.

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
TRUNK=$(cd "$HERE/.." && pwd)
REAL_HOME="$TRUNK/home"

if [ ! -x "$REAL_HOME/bin/ziguratip" ]; then
  echo "build first: make -C $TRUNK" >&2
  exit 1
fi
if [ ! -x "$REAL_HOME/bin/zgc-probe" ]; then
  echo "build the C connector first: make -C $TRUNK/CConnector" >&2
  exit 1
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/zgc-XXXXXX")
cleanup() {
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$WORK"
}
SERVER_PID=""
trap cleanup EXIT INT TERM

# Read-only: shared with the real home. Writable: this run's own.
for shared in bin lib include http; do
  ln -s "$REAL_HOME/$shared" "$WORK/$shared"
done
cp -R "$REAL_HOME/etc" "$WORK/etc"
cp -R "$REAL_HOME/ld"  "$WORK/ld"
cp -R "$REAL_HOME/catalog" "$WORK/catalog"
mkdir -p "$WORK/data" "$WORK/obj" "$WORK/tmp" "$WORK/log"

# Every table erased at startup, which is what makes the run repeatable, and
# quiet, because the probe's own output is the thing worth reading.
sed -i.bak 's/^RESET_MODE: .*/RESET_MODE: TRUE/; s/^TRACE_MODE: .*/TRACE_MODE: FALSE/' \
    "$WORK/etc/ziguratip.conf"
rm -f "$WORK/etc/ziguratip.conf.bak"

export ZIGURATIP_HOME="$WORK"
export DYLD_LIBRARY_PATH="$REAL_HOME/lib:$DYLD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$REAL_HOME/lib:$LD_LIBRARY_PATH"

echo "compiling the cocolog objects"
for step in "$TRUNK"/cocolog/0*.parsi; do
  if ! "$REAL_HOME/bin/parsi" "$step" > "$WORK/log/parsi.log" 2>&1; then
    echo "failed on $(basename "$step"):" >&2
    tail -5 "$WORK/log/parsi.log" >&2
    exit 1
  fi
done

LOG="$WORK/log/server.log"
echo "starting ziguratip (log: $LOG)"
"$REAL_HOME/bin/ziguratip" > "$LOG" 2>&1 &
SERVER_PID=$!

# Watching the log for "ready" is not enough -- the server prints that and then
# binds -- so wait until the port actually accepts a connection.
READY=0
i=0
while [ $i -lt 200 ]; do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then break; fi
  # IS THE PORT ANSWERING? library(tcp) is the question cocolog already has:
  # tcp_connect/3 FAILS rather than raising when nothing is listening.
  #
  # THE MARKER IS NOT DECORATION. `cocolog query GOAL' exits 0 whether the
  # goal proved or not -- it prints `false.' and returns 0 -- so a shell that
  # reads its exit status is testing nothing. Only `run FILE GOAL' ties the
  # two together. Measured both ways before this was written: query fail is
  # rc=0, run a failing main is rc=1. So the goal writes a word and grep is
  # the verdict.
  if COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY" \
     "$ROOT/cocolog" --local query "use_module(library(tcp)),
        tcp_connect('127.0.0.1', 2160, S), tcp_close(S), write(listening), nl" \
     2>/dev/null | grep -q '^listening'
  then
    READY=1
    break
  fi
  sleep 0.1
  i=$((i + 1))
done

if [ "$READY" -ne 1 ]; then
  echo "server did not come up:" >&2
  tail -20 "$LOG" >&2
  exit 1
fi

echo "server up, running the probe"
echo
"$REAL_HOME/bin/zgc-probe" 127.0.0.1 2160
STATUS=$?
exit $STATUS
