#!/bin/sh
# EVERY TUTORIAL, ALL THREE CATEGORIES.
#
#   basics/   eleven files, one process each, goal `main'. No library, no
#             database, no build flag.
#   library/  twenty-three files, one process each, goal `main'. Tier 2
#             needs $COCOLOG_LIBRARY, which library-path.sh sets.
#   torch/    twenty-four networks, THREE processes each and a store per
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
# TWO KINDS OF SKIP, both because "not built here" and "wrong" are
# different findings: the torch category needs the torch module, and
# `library/22-torch.pl' needs it too.

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

failures=0
skipped=0

# ---- basics and library: one process, goal `main' ---------------------
for pl in "$ROOT"/tutorials/basics/[0-9]*.pl "$ROOT"/tutorials/library/[0-9]*.pl; do
  name=$(basename "$(dirname "$pl")")/$(basename "$pl" .pl)
  case "$name:$HAVE_TORCH" in
    library/22-torch:no)
      skipped=$((skipped + 1)); echo "SKIP  $name (no torch module)"; continue ;;
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
  echo "SKIP  torch/ (24 tutorials, no torch module)"
else
  for pl in "$ROOT"/tutorials/torch/[0-9]*.pl; do
    name=torch/$(basename "$pl" .pl)
    STORE="$OUT/store-$(basename "$pl" .pl)"
    bad=0
    for goal in train test predict; do
      if out=$(timeout 300 "$COCOLOG" --kb tutorials --embed "$STORE" run "$pl" "$goal" 2>&1); then
        :
      else
        failures=$((failures + 1))
        bad=1
        echo "FAIL  $name $goal"
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
