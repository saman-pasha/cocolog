#!/bin/sh
# The whole suite.
#
#   sh test/run.sh              everything
#   sh test/run.sh solve        one file
#   sh test/run.sh groups       just the four-interpreter one
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

CASES="term syntax solve state zigurat shared"
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

# groups.sh is not a .cicili case: it is four cocolog PROCESSES against one
# server, so it is a shell script and it needs the built program rather than a
# test binary. It runs last because it is the slowest and because everything
# above it has to be right for it to mean anything.
if [ -z "$1" ] || [ "$1" = groups ]; then
  printf '%-10s ' "groups"
  if [ ! -x "$ROOT/cocolog" ]; then
    echo "SKIP (build cocolog first)"
  else
    out=$(sh "$HERE/groups.sh" 2>&1) || true
    case $(echo "$out" | tail -1) in
      GREEN*) echo "GREEN" ;;
      SKIP*)  echo "SKIP" ;;
      *)      echo "$out" | tail -1
              echo "$out" | grep '^FAIL' | head -5
              red=$((red + 1)) ;;
    esac
  fi
fi

echo
echo "red: $red"
[ "$red" -eq 0 ]
