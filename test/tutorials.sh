#!/bin/sh
# EVERY TUTORIAL, ALL THREE CATEGORIES.
#
#   basics/   eleven files, one process each, goal `main'. No library, no
#             database, no build flag.
#   library/  forty-one files, one process each, goal `main'. Tier 2
#             needs $COCOLOG_LIBRARY, which library-path.sh sets.
#   tensor/   forty-two networks, THREE processes each and a store per
#             tutorial: train saves the model into the store, test reloads
#             and judges it, predict reloads and answers.
#
# WHY THE FIRST TWO ARE TESTS AT ALL: every claim in them is a `must/3',
# so a lesson that stops being true FAILS and names both answers. That is
# not decoration -- writing them found that `once/1' and `ignore/1' did
# not exist and that `retractall/1' was a clause short of correct.
#
# EACH TORCH TUTORIAL GETS ITS OWN STORE: consulted clauses live in the
# knowledge base exactly as models do, so two tutorials sharing a store
# would also share their train/test/predict clauses -- and the first one
# consulted would answer for all of them.
#
# THREE KINDS OF SKIP, all because "not built here" and "wrong" are
# different findings: the torch category needs the torch module,
# `library/22-torch.pl' needs it too, 23 to 28 need ZiguratIP's
# cryptography and its sample certificate directory, 29 needs the ray
# module and 40 the numpy one.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-tutorials-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

if [ ! -x "$COCOLOG" ]; then
  echo "SKIP no cocolog built (make needs libtorch and a built ZiguratIP checkout)"
  exit 0
fi

. "$HERE/library-path.sh"

# Is the torch module loadable? Ask it, rather than looking for a file:
# the module may be compiled in, beside the binary, or on the path.
if "$COCOLOG" query "use_module(library(torch)), torch_cuda_available(_)" \
     >/dev/null 2>&1; then
  HAVE_TORCH=yes
else
  HAVE_TORCH=no
fi

# The same question for ZiguratIP's cryptography: four modules that need a
# BUILT ZiguratIP, and a sample authority to read. 26 and 27 also want the
# certificate directory, which only exists in a built home.
CERT="${ZIGURATIP:-$HOME/ZiguratIP}/home/etc/cert"
if "$COCOLOG" query "use_module(library(x509)), use_module(library(der)), use_module(library(tls))" \
     >/dev/null 2>&1 && [ -f "$CERT/dont-use-certificate.crt" ]; then
  HAVE_CRYPTO=yes
else
  HAVE_CRYPTO=no
fi

# And for the window: the lesson opens none (it cannot assume a display,
# as the curl lesson cannot assume a network), so loadable is enough.
if "$COCOLOG" query "use_module(library(ray))" >/dev/null 2>&1; then
  HAVE_RAY=yes
else
  HAVE_RAY=no
fi

# And for the arrays: the module starts an interpreter at its first
# predicate, so loadable is asked with one, not with use_module alone.
if "$COCOLOG" query "use_module(library(numpy)), np_zeros([1], A), np_free(A)" >/dev/null 2>&1; then
  HAVE_NUMPY=yes
else
  HAVE_NUMPY=no
fi

failures=0
skipped=0

# ---- basics and library: one process, goal `main' ---------------------
for pl in "$ROOT"/tutorials/basics/[0-9]*.pl "$ROOT"/tutorials/library/[0-9]*.pl; do
  name=$(basename "$(dirname "$pl")")/$(basename "$pl" .pl)
  case "$name:$HAVE_TORCH" in
    library/22-torch:no|library/39-tensor-expr:no)
      skipped=$((skipped + 1)); echo "SKIP  $name (no torch module)"; continue ;;
  esac
  case "$name:$HAVE_CRYPTO" in
    library/23-sha:no|library/24-aes:no|library/25-der:no|library/26-x509:no|library/27-ca:no|library/28-tls:no)
      skipped=$((skipped + 1))
      echo "SKIP  $name (no ZiguratIP cryptography built)"; continue ;;
  esac
  case "$name:$HAVE_RAY" in
    library/29-ray:no)
      skipped=$((skipped + 1)); echo "SKIP  $name (no ray module)"; continue ;;
  esac
  case "$name:$HAVE_NUMPY" in
    library/40-numpy:no)
      skipped=$((skipped + 1)); echo "SKIP  $name (no numpy module)"; continue ;;
  esac
  # FROM THE REPO ROOT, which `library/03-files.pl' depends on: it reads
  # its own source through the relative path the header tells you to use.
  if out=$(cd "$ROOT" && timeout 300 "$COCOLOG" run "$pl" main 2>&1) \
     && [ "$(printf '%s\n' "$out" | tail -1)" = done ]; then
    echo "ok    $name"
  else
    failures=$((failures + 1))
    echo "FAIL  $name"
    printf '%s\n' "$out" | tail -4 | sed 's/^/      /'
  fi
done

# ---- torch: three processes and a store each --------------------------
if [ "$HAVE_TORCH" = no ]; then
  skipped=$((skipped + 1))
  echo "SKIP  tensor/ (42 tutorials, no torch module)"
else
  for pl in "$ROOT"/tutorials/tensor/[0-9]*.pl; do
    name=tensor/$(basename "$pl" .pl)
    STORE="$OUT/store-$(basename "$pl" .pl)"
    bad=0
    # TWENTY MINUTES, AND 27-induction IS WHY. Its `train' fits four
    # models at 60 epochs each -- MEASURED at 8m10s wall, 3723s of CPU
    # at 791%, on an i9-9880H running libtorch on the CPU. The 300s that
    # every other goal here finishes inside killed it at rc=124, and a
    # kill takes the output with it: the case printed `FAIL
    # tensor/27-induction train' over three blank lines, with no way to
    # tell a slow model from a broken one. A budget must be bigger than
    # the thing it is measuring, and a timeout should say it is one.
    for goal in train test predict; do
      if out=$(timeout 1200 "$COCOLOG" --kb tutorials --embed "$STORE" run "$pl" "$goal" 2>&1); then
        :
      else
        rc=$?
        failures=$((failures + 1))
        bad=1
        if [ "$rc" = 124 ]; then
          echo "FAIL  $name $goal (TIMEOUT at 1200s -- no output survives a kill)"
        else
          echo "FAIL  $name $goal"
        fi
        printf '%s\n' "$out" | tail -3 | sed 's/^/      /'
        break
      fi
    done
    [ $bad -eq 0 ] && echo "ok    $name"
  done
fi

if [ $failures -eq 0 ]; then
  echo "GREEN: 0 failure(s), $skipped skip(s)"
else
  echo "RED: $failures failure(s), $skipped skip(s)"
  exit 1
fi
