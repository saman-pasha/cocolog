#!/bin/sh
# Build ZiguratIP and cocolog on a fresh VM, with the errors VISIBLE.
#
# WHY NOT JUST `make'. Two things hide a failure here, and the notebook
# used to hit both:
#
#   1. ZIGURATIP'S TOP-LEVEL MAKE STEPS OVER FAILURES. It loops the
#      projects with `@- $(MAKE) -C ...', and the leading `-' tells make
#      to carry on. So the workspace prints "all done" and exits 0 having
#      skipped a library that would not compile. THE EXIT CODE IS NOT
#      EVIDENCE; the artifacts are, which is why every one is checked by
#      name below.
#
#   2. `| tail -n 3' SHOWS THE WRONG THREE LINES. A compiler reports the
#      error first and the summary last, so the tail of a broken build is
#      the linker's parting words about a file it never got. This script
#      keeps whole logs and, on failure, prints the lines that say what
#      went wrong -- with the project that owns them named.
#
# Reads CICILI, ZIGURATIP, ZIGURATIP_HOME and COCOLOG from the
# environment (colab/preflight.sh checks they point somewhere real).
#
#   sh colab/build.sh            # build both, verify, report
#
# Exit 0 means every artifact this stack needs exists.

set -u
CICILI=${CICILI:?set CICILI to a cicili checkout}
ZIGURATIP=${ZIGURATIP:?set ZIGURATIP to a ZiguratIP checkout}
ZIGURATIP_HOME=${ZIGURATIP_HOME:-$ZIGURATIP/home}
COCOLOG=${COCOLOG:?set COCOLOG to a cocolog checkout}
export CICILI ZIGURATIP ZIGURATIP_HOME COCOLOG
export LD_LIBRARY_PATH="$ZIGURATIP_HOME/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

LOGS=${LOGS:-/tmp/coco-build-logs}
mkdir -p "$LOGS"

# HOW LONG IT TOOK, MEASURED RATHER THAN CLAIMED. "The build takes a few
# minutes" is the kind of sentence that is written once and then quietly
# stops being true, and on a Colab VM it is the number a reader most
# wants before they walk away from the tab. So each stage times itself
# and the run prints its own total. A doc that says twelve minutes is a
# fact in a second place; this is the first place.
T0=$(date +%s)
stage_start() { STAGE_T=$(date +%s); }
stage_done()  { echo "   [$1: $(fmt_secs $(( $(date +%s) - STAGE_T )))]"; }
fmt_secs() {
  if [ "$1" -ge 60 ]; then echo "$(( $1 / 60 ))m $(( $1 % 60 ))s"; else echo "$1s"; fi
}

# A STALE ARTIFACT IS A LIE THIS SCRIPT WOULD OTHERWISE TELL. Checking
# that a file exists proves the LAST build made it, not this one -- so a
# re-run after a failure can find yesterday's binary and call the build
# green. On a fresh Colab VM there is nothing stale and it cannot happen;
# on a re-run it can, which is when a reader most needs the truth. So the
# one artifact that is cheap to remake -- the cocolog binary, a single
# link -- is deleted before its build, and its existence afterwards is
# evidence about THIS run. For ZiguratIP's fourteen libraries, deleting
# would mean a full rebuild every time; `CLEAN=1' asks for that when a
# previous run left the tree in a state worth distrusting.
if [ "${CLEAN:-0}" = 1 ]; then
  echo "== CLEAN=1: discarding both builds first"
  ( cd "$ZIGURATIP" && make clean ) >/dev/null 2>&1
  ( cd "$COCOLOG"   && make clean ) >/dev/null 2>&1
fi

# The lines a reader actually needs: the compiler's own error lines, the
# linker's undefined symbols, and Cicili's unhandled Lisp conditions --
# Cicili treats any unrecognised compiler chatter as fatal, so its
# failures read as a Lisp backtrace with the real cause near the top.
explain() {   # logfile label
  echo
  echo "---- what went wrong in $2 (from $1) ----"
  # the compiler's and the linker's own words
  grep -nE 'error:|Error [0-9]|undefined reference|undefined symbol|No such file or directory|command not found|cannot find -l' "$1" \
    | head -20
  # and Cicili's, which arrive as a Lisp condition: the BANNER line says
  # only that something was unhandled, and the line under it names the
  # cause -- so the banner alone, which is all a bare grep would show, is
  # the one line of that report worth nothing.
  grep -n -A3 'Unhandled' "$1" | head -8
  echo "---- (whole log: $1) ----"
}

# ---- ZiguratIP ---------------------------------------------------------
# THE RUNTIME DIRECTORIES THE SERVER WRITES INTO. home/data is where the
# page store lives, and a ZiguratIP clone did not carry it -- every other
# runtime directory has a .gitkeep and that one did not, so a fresh VM
# started the server once and got "cannot create the store file
# .../home/data/hexmap". Fixed at the root in ZiguratIP; kept here as
# well because this script also runs against checkouts older than that
# fix, and a mkdir -p costs nothing to be sure of.
mkdir -p "$ZIGURATIP_HOME/data" "$ZIGURATIP_HOME/ld" "$ZIGURATIP_HOME/catalog" \
         "$ZIGURATIP_HOME/log" "$ZIGURATIP_HOME/tmp"

stage_start
echo "== building ZiguratIP (Release)"
( cd "$ZIGURATIP" && make MODE=Release ) > "$LOGS/ziguratip.log" 2>&1
echo "   make exited $? -- which proves nothing here; checking artifacts"

# Every library the stack loads, by name. A missing one names its project,
# because "13 libraries instead of 14" is a fact nobody can act on.
missing=""
for pair in Core:Core StreamIO:StreamIO Type:Type Library:Library \
            Encoding:Encoding Compression:Compression \
            Cryptography:Cryptography Configuration:Configuration \
            Threading:Threading SocketIO:SocketIO Connector:Connector \
            HTTP:HTTP MVCCS:MVCCS-cicili Compiler:Compiler; do
  lib=${pair%%:*}; proj=${pair##*:}
  [ -f "$ZIGURATIP_HOME/lib/lib$lib.so" ] || missing="$missing lib$lib.so($proj)"
done
for b in parsi parsic ziguratip; do
  [ -x "$ZIGURATIP_HOME/bin/$b" ] || missing="$missing bin/$b"
done

if [ -n "$missing" ]; then
  echo "   ZIGURATIP BUILD INCOMPLETE, missing:$missing"
  explain "$LOGS/ziguratip.log" "the ZiguratIP build"
  exit 1
fi
echo "   ZiguratIP: $(ls "$ZIGURATIP_HOME"/lib/*.so | wc -l) libraries, $(ls "$ZIGURATIP_HOME"/bin | wc -l) executables"
stage_done ZiguratIP

# ---- the compiler pages, moved out of reach --------------------------
# System/compiler.parsi is a WEB PAGE whose POST handler is
#
#     CALL con.compile(request.post('code'))
#
# -- a compiler behind an HTTP form. This notebook exists to publish a
# READ-ONLY view of a knowledge base through a tunnel with no
# authentication on it, and those two things must never be true of the
# same server.
#
# AND IT IS NOT DEBRIS. `System' is in ZiguratIP's top-level PROJECTS
# list, so the ordinary `make MODE=Release' above compiles both pages
# into home/ld every single time. ZiguratIP's own tutorial said a fresh
# clone had none of them; a fresh Colab VM that had run nothing else
# proved otherwise, and the tunnel cell refused -- correctly, and with
# nowhere to go but the override. A refusal whose only way forward is
# `I_UNDERSTAND = True' teaches people to set I_UNDERSTAND.
#
# So they are MOVED, never deleted, with each object beside its
# catalogue entry so the pair cannot disagree, and it is said out loud.
# Nothing here needs them: Parsi objects are compiled offline by
# `parsi', which is the supported way and the reason the network
# compiler stays off. KEEP_COMPILER_PAGES=1 leaves them where they are
# -- for ZiguratIP's own compiler tutorial, which is the one workflow
# that wants the page and does not want a tunnel.
QUAR="$ZIGURATIP_HOME/ld-disabled"
if [ "${KEEP_COMPILER_PAGES:-0}" = 1 ]; then
  echo "== KEEP_COMPILER_PAGES=1: leaving the compiler pages loadable"
  echo "   DO NOT open a tunnel in front of this server."
else
  moved=""
  mkdir -p "$QUAR"
  for obj in COMPILER COMPILERDRAWER; do
    if [ -f "$ZIGURATIP_HOME/ld/lib_${obj}_.so" ]; then
      mv "$ZIGURATIP_HOME/ld/lib_${obj}_.so" "$QUAR/"
      moved="$moved lib_${obj}_.so"
    fi
    if [ -f "$ZIGURATIP_HOME/catalog/_${obj}_.conf" ]; then
      mv "$ZIGURATIP_HOME/catalog/_${obj}_.conf" "$QUAR/"
    fi
  done
  if [ -n "$moved" ]; then
    echo "== moved the compiler pages out of home/ld:$moved"
    echo "   They are a compiler behind an HTTP form and this build is"
    echo "   meant to be tunnelled. Moved, not deleted -- they are in"
    echo "   $QUAR"
    echo "   and mv restores them. KEEP_COMPILER_PAGES=1 skips this."
  fi
fi

# ---- cocolog -----------------------------------------------------------
stage_start
echo "== building cocolog"
rm -f "$COCOLOG/cocolog"           # so what stands afterwards is THIS build's
( cd "$COCOLOG" && make ) > "$LOGS/cocolog.log" 2>&1
rc=$?
if [ ! -x "$COCOLOG/cocolog" ]; then
  echo "   NO COCOLOG BINARY (make exited $rc)"
  explain "$LOGS/cocolog.log" "the cocolog build"
  exit 1
fi
echo "   cocolog built: $(ls -lh "$COCOLOG/cocolog" | awk '{print $5}')"
stage_done cocolog

# ---- the schema --------------------------------------------------------
# The Parsi objects: compiled INTO the ZiguratIP home, and the one step
# that must be redone after any engine change -- an object compiled
# against older engine headers does not fail politely, it takes the
# server down with a symbol lookup error on first use.
stage_start
echo "== compiling the Parsi objects into the home"
( cd "$COCOLOG" && make schema ) > "$LOGS/schema.log" 2>&1
n=$(ls "$ZIGURATIP_HOME"/ld/lib_COCOLOG* 2>/dev/null | wc -l)
if [ "$n" -lt 1 ]; then
  echo "   NO SCHEMA OBJECTS in $ZIGURATIP_HOME/ld"
  explain "$LOGS/schema.log" "make schema"
  exit 1
fi
echo "   $n cocolog objects in the home"
stage_done schema

# ---- the proof it runs -------------------------------------------------
# A binary that exists is not a binary that works: the one link pulls in
# the embedded engine and libtorch, and an ABI mismatch shows up HERE, on
# the first run, rather than at the link. So ask it something.
echo "== does it answer"
ans=$("$COCOLOG/cocolog" query "X is 6*7, write(X), nl" 2>&1 | tr -d '\r')
case "$ans" in
  *42*) echo "   cocolog answers: 42" ;;
  *)    echo "   COCOLOG DOES NOT RUN -- it said: $ans"; exit 1 ;;
esac

echo
echo "build GREEN in $(fmt_secs $(( $(date +%s) - T0 ))) -- ZiguratIP, cocolog, the schema, and a binary that answers"
echo "   (measured on THIS VM. Colab gives 2 cores; a machine with more"
echo "    cores finishes the ZiguratIP stage considerably sooner.)"
