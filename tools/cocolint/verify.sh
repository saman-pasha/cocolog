#!/bin/sh
# verify.sh -- the gates of DESIGN.md section 7 that need no model.
#
#     sh tools/cocolint/verify.sh FILE.pl [FILE.pl ...]
#     sh tools/cocolint/verify.sh --gates G1,G4 FILE.pl
#
#   G0  shape      the file exists, reads, and names main/0
#   G1  cocolint   the dialect linter; HARD findings block
#   G2  consult    it loads cleanly under --local
#   G3  oracle     none of its predicates collided with a library's
#   G4  execute    `run FILE main' exits 0 AND the last line of stdout is `done'
#   G5  localise   only when G4 failed with no must/3 line: a --trace tail
#
# BOTH CONDITIONS IN G4, ALWAYS. Exit 0 alone is satisfied by `main :- true.',
# which is why test/tutorials.pl checks the same two things and why a generated
# program that proves nothing must not be able to pass.
#
# THE STREAMS ARE NEVER MERGED. stdout is block-buffered into a file (the only
# setvbuf in the tree is a swarm worker's log), stderr's buffering is a platform
# default -- so a merged capture's ordering is meaningless, and a timeout-killed
# run loses unflushed stdout. Two files, always.
#
# AND IT RUNS IN A SCRATCH DIRECTORY WITH NO library/ IN IT. The library path
# probes ./library relative to the WORKING DIRECTORY before <exedir>/library,
# so a candidate's own directory could otherwise shadow the real one -- and a
# cocolog run inside an untrusted tree would prefer THEIR library(lists).

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"
TIMEOUT="${COCO_VERIFY_TIMEOUT:-60}"

GATES=G0,G1,G2,G3,G4,G5
# THE GOAL IS NAMED, ALWAYS -- card row M1: with more than one argument after
# `run', the LAST is the goal, and a caller who leaves it out has the second
# file read as a term to prove. `main' is the default because that is what the
# entry-point contract asks a generated program for; a tool file names its own.
GOAL=main
while :; do
  case "$1" in
    --gates) GATES="$2"; shift 2 ;;
    --goal)  GOAL="$2";  shift 2 ;;
    *) break ;;
  esac
done
want() { case ",$GATES," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

[ -n "$1" ] || { echo "usage: verify.sh [--gates LIST] FILE.pl ..." >&2; exit 2; }

# Ours FIRST so a run cannot go green about somebody else's library, theirs
# KEPT because an exported path was exported on purpose.
COCOLOG_LIBRARY="$ROOT/library:${COCOLOG_LIBRARY}"
export COCOLOG_LIBRARY

FILES=""
for f in "$@"; do
  case "$f" in /*) FILES="$FILES $f" ;; *) FILES="$FILES $(pwd)/$f" ;; esac
done
FIRST=$(echo $FILES | awk '{print $1}')
NAME=$(basename "$FIRST")

export AGENT="$HERE"

fail() { echo "$1 FAIL  $2"; exit 1; }
pass() { echo "$1 pass  $2"; }
skip() { echo "$1 skip  $2"; }

# ---- G0: shape -----------------------------------------------------------
if want G0; then
  for f in $FILES; do
    [ -f "$f" ] || fail G0 "$f does not exist"
  done
  HAS=$(COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY" \
        "$BIN" --local run "$HERE/clauses.pl" "$HERE/ask.pl" ak_main \
        -- goal $FILES "$GOAL" 2>/dev/null)
  [ "$HAS" = yes ] || fail G0 "no $GOAL/0 -- the CLI names the goal and there is none"
  pass G0 "$NAME reads, and defines $GOAL/0"
fi

# ---- G1: cocolint --------------------------------------------------------
if want G1; then
  if false; then
    skip G1 "unreachable"
  else
    if OUT=$(sh "$HERE/lint.sh" $FILES 2>&1); then
      pass G1 "$(printf '%s' "$OUT" | tail -1)"
    else
      printf '%s\n' "$OUT" | sed 's/^/    /'
      fail G1 "HARD findings block. No process has started, so each message is exact."
    fi
  fi
fi

# ---- preflight: is every tier-2 library the file imports actually there? --
#
# PROBED AS A GOAL, NEVER AS A DIRECTIVE. The directive hook maps every
# non-zero return to success, including the -1 that means `not found on the
# library path', so a missing library makes `:- use_module(library(tcp)).'
# succeed in TOTAL SILENCE -- verified: empty stderr, exit 0. As a goal the
# same term raises, naming the library. Without this, a file that needs a
# library nobody built fails G4 with existence_error(procedure, tcp_listen/2),
# which names the predicate and not the cause.
MISSING=""
if [ -x "$BIN" ]; then
  for lib in $(grep -ho "use_module(library([a-z_0-9/]*))" $FILES 2>/dev/null \
               | sed 's/.*library(\(.*\))./\1/' | sort -u); do
    "$BIN" --local query "use_module(library($lib))" >/dev/null 2>&1 || \
      MISSING="$MISSING $lib"
  done
fi
if [ -n "$MISSING" ]; then
  for lib in $MISSING; do
    if [ -f "$ROOT/modules/$lib/build.sh" ]; then
      skip "--" "library($lib) is not on the path: sh modules/$lib/build.sh"
    else
      skip "--" "library($lib) is not on the path"
    fi
  done
  echo "-- skip  $NAME needs a library this checkout has not built"
  exit 0
fi

# ---- G2 + G3: consult, and the collision oracle -- ONE process -----------
if want G2 || want G3; then
  if [ ! -x "$BIN" ]; then
    skip G2 "no binary at $BIN"
  else
    ORC=$(sh "$HERE/oracle.sh" $FILES 2>&1)
    rc=$?
    case "$ORC" in
      *"did not consult cleanly"*)
        printf '%s\n' "$ORC" | sed 's/^/    /'
        fail G2 "did not consult -- the byte offset above is the highest-value repair signal there is" ;;
    esac
    want G2 && pass G2 "consulted cleanly"
    if want G3; then
      if [ $rc -eq 0 ]; then
        pass G3 "no collisions ($(printf '%s' "$ORC" | grep -c '^own') own, \
$(printf '%s' "$ORC" | grep -c '^hook') declared hooks)"
      else
        printf '%s\n' "$ORC" | grep -v '^own' | sed 's/^/    /'
        fail G3 "a predicate collided with a library's -- the clauses merged into that record"
      fi
    fi
  fi
fi

# ---- G4: execute ---------------------------------------------------------
G4RC=skip
if want G4; then
  if [ ! -x "$BIN" ]; then
    skip G4 "no binary at $BIN"
  else
    SCRATCH=$(mktemp -d) || exit 2
    ( cd "$SCRATCH" && timeout "$TIMEOUT" "$BIN" --local run $FILES "$GOAL" \
        >"$SCRATCH/run.out" 2>"$SCRATCH/run.err" )
    rc=$?
    LAST=$(tail -1 "$SCRATCH/run.out" 2>/dev/null)
    if [ "$rc" -eq 0 ] && [ "$LAST" = done ]; then
      pass G4 "exit 0 and the last line of stdout is \`done'"
      G4RC=pass
    else
      G4RC=fail
      # A `must/3' line names both values, which is the cheapest repair
      # evidence there is and needs no trace at all.
      MUST=$(grep 'BUT THIS LESSON SAYS' "$SCRATCH/run.out" 2>/dev/null | head -5)
      [ -n "$MUST" ] && printf '%s\n' "$MUST" | sed 's/^/    /'

      # AN existence_error NAMES THE PREDICATE AND NOT THE MODULE, which is
      # card row T1's second half and the reason it is worth a lookup: the
      # blocklist knows which tier-2 module registers every name, so the
      # message can say `sh modules/x509/build.sh' where the interpreter can
      # only say x509_validate/2. It catches the case the preflight cannot --
      # a file that CALLS a library it never declared, which 27-ca.pl does.
      EX=$(sed -n 's/.*existence_error(procedure,\([a-z_$][A-Za-z0-9_]*\)\/\([0-9]*\)).*/\1\/\2/p' \
           "$SCRATCH/run.err" 2>/dev/null | head -1)
      if [ -n "$EX" ] && [ -f "$HERE/blocklist.pl" ]; then
        OWNER=$(COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY" \
                "$BIN" --local run "$HERE/clauses.pl" "$HERE/ask.pl" ak_main \
                -- owner "$EX" 2>/dev/null)
        if [ -n "$OWNER" ]; then
          echo "    $EX belongs to library($OWNER), which this checkout has not built."
          [ -f "$ROOT/modules/$OWNER/build.sh" ] && \
            echo "    sh modules/$OWNER/build.sh"
          echo "    The file never declared it, so the preflight could not see it --"
          echo "    an existence_error names the predicate and not the module."
          rm -rf "$SCRATCH"
          echo "-- skip  $NAME calls library($OWNER), which is not built here"
          exit 0
        fi
      fi
      sed 's/^/    err: /' "$SCRATCH/run.err" 2>/dev/null | head -10
      [ "$rc" -eq 124 ] && echo "    (exit 124 is timeout's kill, after ${TIMEOUT}s)"
      if [ "$rc" -eq 0 ]; then
        echo "    exit 0 but the last line was [$LAST], not \`done'. Exit 0 alone"
        echo "    is satisfied by \`main :- true.'"
      fi
      # G5 -- ONLY when there is no must/3 line. With one, the trace adds
      # nothing the two values do not already say.
      if want G5 && [ -z "$MUST" ]; then
        ( cd "$SCRATCH" && timeout "$TIMEOUT" "$BIN" --local --trace run $FILES \
            "( $GOAL -> true ; true )" 2>"$SCRATCH/trace.err" >/dev/null )
        echo "    G5 -- the trace tail. What it localises is the innermost"
        echo "    sub-goal that ran out of ways, WITH ITS ARGUMENTS AS THEY"
        echo "    STOOD, at a call depth. Not a clause, a file or a line."
        grep -E '^[[:space:]]*(Call|Exit|Redo|Fail):' "$SCRATCH/trace.err" \
          2>/dev/null | tail -20 | sed 's/^/      /'
      fi
      rm -rf "$SCRATCH"
      fail G4 "the program did not prove"
    fi
    rm -rf "$SCRATCH"
  fi
fi

exit 0
