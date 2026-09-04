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
# THE ONE COMPILER, for the test binaries too. Cicili names `gcc' (or, on
# Darwin, `clang') outright, and the shims in tools/cc are how that name
# reaches the wrappers -- which carry the flags a platform needs, and
# which the main build already goes through. The test targets used to be
# built with whatever the bare name resolved to, which is how they came
# to fail on a Mac while `make' succeeded beside them.
. "$ROOT/tools/cc/env.sh"

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
# binary. Most are cocolog SCRIPTS now -- test/<case>.pl, one process for the
# whole case, on test/prelude.pl -- and the rest are still shell. They run last
# because they are the slowest and because everything above them has to be
# right for them to mean anything.
#
#   files   the Files module, run against SWI-Prolog and compared line for line
#   trace   the four-port tracer, run against SWI-Prolog's and compared
#           port for port
#   vacuum  the reclaim pass: the verb in both arrangements, and the gate
#           on the vacuum_kb builtin
#   repl    the toplevel, piped: SWI's answer shapes, one session one
#           world, and a session's writes read by a second process
#   script  `-s FILE': load a script, prove main, and say so in the
#           EXIT CODE -- 0 exactly when main proved, where `query'
#           answers 0 for a goal that merely failed
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
#   engine  the engine's COMPLEXITY, which nothing else here checks: a
#           term representation can be perfectly correct and quadratic,
#           and this one was. A timeout with a hundred-fold margin rather
#           than a stopwatch with a threshold
#   meter   `call_metered/4': a goal under a ceiling, and WHAT IT COST.
#           The count is the engine's own and was never readable from
#           Prolog before -- so the checks are the ones a PRICE needs: it
#           measures rather than echoing the ceiling, it answers for a
#           goal that failed (a search is work), and two processes that
#           share nothing but the goal report the same number
#   os      library(os): which system, who am I, cores, the environment,
#           where a tool is -- each answer held to the shell's own
#           (uname, id, hostname, $HOME) so the promise is exact: what
#           a script would have got by shelling out, on either system,
#           without the shell
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
#   crypto  ZiguratIP's cryptography and its CA as cocolog predicates --
#           library(sha), library(aes), library(der), library(x509) and
#           library(ca). Held to published vectors where there are any
#           (FIPS 180, RFC 4231, NIST SP 800-38A, DER's own worked
#           examples) and to a round trip where there are not. The CA is
#           exercised for real: a key generated, a request made, a
#           certificate issued against ZiguratIP's sample authority,
#           validated, signed with and checked -- 74 checks
#   tutorials  all sixty-four tutorial files, as tests: eleven in
#           `basics/' and forty-two in `library/' and twenty-three in `opencv/' run their `main'
#           and must print `done', and forty-two in `tensor/' run
#           train, test and predict as three processes against a store
#           of their own. EVERY CLAIM IN basics/ AND library/ IS A
#           `must/3', so a lesson that stops being true fails and names
#           both answers -- which is how `once/1' and `ignore/1' were
#           found missing and `retractall/1' found a clause short.
#           The torch category SKIPs inside the case without libtorch
#   groups  twelve interpreters sharing four machine STATES
#   ruler   one interpreter writing the KNOWLEDGE BASE while eight read it
# The tier-2 libraries, for the .pl cases: ours first, the caller's kept.
# A .sh case sources this itself; sourcing it twice only repeats a path.
. "$HERE/library-path.sh"
for c in files trace vacuum repl script tunnel reconsult tensors torch-graph torch-grad torch-replay tensorflow library bigint zigurat-lib tcp engine meter thread process text os kbs http curl ray numpy opencv hex astar serialize httpd httpd-tls crypto tls zigurat-tls tutorials colab lint argv string directives groups ruler; do
  [ -n "$1" ] && [ "$1" != "$c" ] && continue
  printf '%-10s ' "$c"
  # `colab' reads the notebook and the scripts beside it and needs no binary,
  # so it must not be skipped for want of one. `lint' used to be exempt too,
  # when the linter was Python; it is cocolog now and skips honestly inside
  # the case.
  if [ ! -x "$ROOT/cocolog" ] && [ "$c" != colab ]; then
    echo "SKIP (build cocolog first)"
    continue
  fi
  t0=$(date +%s)
  # A CASE IS A COCOLOG SCRIPT where test/<c>.pl exists AND NO test/<c>.sh
  # does: `-s' loads it and proves main, THE EXIT CODE IS THE VERDICT -- 0
  # exactly when main proved, which checks_done withholds on any red check
  # -- and a `SKIP' line is a skip. One process for the whole case, where
  # the .sh spelling spawned one per check; test/prelude.pl says why, and
  # CivV's run.sh did it first. The .sh spelling drives the not-yet-
  # converted rest -- and wins where both exist, because a shell case may
  # keep a FIXTURE of its own name beside it (test/trace.pl is trace.sh's
  # program under the tracer, not a case, and was run as one once).
  if [ ! -f "$HERE/$c.sh" ] && [ -f "$HERE/$c.pl" ]; then
    # test/prelude.pl stands on library(process) for the harness and
    # library(text) for its pins; both are dependency-free modules of
    # `make modules', and a binary without them SKIPs by name, the way a
    # .sh case skips a library it cannot load
    if [ ! -f "$ROOT/library/process.so" ]; then
      out="SKIP (no library/process.so -- sh modules/process/build.sh)"; verdict=SKIP
    elif [ ! -f "$ROOT/library/text.so" ]; then
      out="SKIP (no library/text.so -- sh modules/text/build.sh)"; verdict=SKIP
    else
      out=$(cd "$ROOT" && timeout 3600 "$ROOT/cocolog" -s "test/$c.pl" 2>&1); rc=$?
      if echo "$out" | grep -aq '^SKIP'; then verdict=SKIP
      elif [ "$rc" -eq 0 ]; then verdict=GREEN
      else verdict=RED; fi
    fi
  else
    # `files' lives in its own directory because it is a harness plus a set
    # of Prolog files that are read by two different Prologs
    script="$HERE/$c.sh"
    [ "$c" = files ] && script="$HERE/files/run.sh"
    out=$(sh "$script" 2>&1) || true
    case $(echo "$out" | tail -1) in
      GREEN*) verdict=GREEN ;;
      SKIP*)  verdict=SKIP ;;
      *)      verdict=RED ;;
    esac
  fi
  # and how long it took, because a suite that is slow in one case and
  # says nothing about which is a suite nobody times twice
  t=$(( $(date +%s) - t0 ))
  case "$verdict" in
    GREEN) printf 'GREEN  %4ss\n' "$t" ;;
    SKIP)  printf 'SKIP   %4ss\n' "$t" ;;
    *)     printf '%s  %4ss\n' "$(echo "$out" | tail -1)" "$t"
           echo "$out" | grep -a '^FAIL' | head -5
           red=$((red + 1)) ;;
  esac
done

echo
echo "red: $red"
[ "$red" -eq 0 ]
