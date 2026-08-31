#!/bin/sh
# agent.sh -- natural language in, a verified cocolog program out.
#
#     sh tools/coco-agent/agent.sh "read a JSON file and count the keys"
#     sh tools/coco-agent/agent.sh --from gen/solver.pl "..."   # skip the model
#     sh tools/coco-agent/agent.sh --dry  "..."                 # show the prompt only
#
# THE MODEL CALL IS THE ONE THING HERE THAT IS NOT EXERCISED, and this script
# is arranged so that everything else is. `--from FILE' takes a candidate that
# already exists and runs the whole verification half against it, which is what
# the repair loop would do on every iteration; `--dry' prints exactly what would
# be sent. Between them, the only untested line is the one that needs a key.
#
# WHY library(llm) AND NOT curl DIRECTLY: it is the tier-2 library this
# repository already ships for exactly this, with the provider table, the
# 600-second default timeout (curl's 30 is wrong for a generation), and the
# single Content-Type header that took a tutorial to find.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"

FROM=""; DRY=0
while :; do
  case "$1" in
    --from) FROM="$2"; shift 2 ;;
    --dry)  DRY=1; shift ;;
    *) break ;;
  esac
done
REQ="$*"
[ -n "$REQ" ] || { echo 'usage: agent.sh [--from FILE.pl] [--dry] "REQUEST"' >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || { echo "agent.sh: needs python3" >&2; exit 2; }

# ---- the index, rebuilt if it is not there -------------------------------
[ -f "$HERE/blocklist.json" ]   || python3 "$HERE/build.py" >/dev/null || exit 2
[ -f "$HERE/surface.jsonl" ]    || python3 "$HERE/index.py" >/dev/null || exit 2

echo "== 1. route and assemble"
python3 "$HERE/assemble.py" --sizes "$REQ" || exit 2
echo

if [ "$DRY" = 1 ]; then
  echo "== the system prompt"
  python3 "$HERE/assemble.py" --show system "$REQ"
  echo
  echo "== the user turn"
  python3 "$HERE/assemble.py" --show user "$REQ"
  exit 0
fi

# ---- 2. the candidate ----------------------------------------------------
if [ -n "$FROM" ]; then
  CAND="$FROM"
  echo "== 2. candidate: $CAND (given, no model call)"
else
  echo "== 2. generate"
  # THE ONE UNEXERCISED LINE. library(llm) reads the key from the environment
  # by provider; with none set it fails at once and says which, rather than
  # sending an unauthenticated request and reporting a 401 three layers down.
  if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
    echo "   no ANTHROPIC_API_KEY or OPENAI_API_KEY in the environment."
    echo
    echo "   Everything before this point needs no key and just ran. Everything"
    echo "   after it needs no key either: pass --from FILE.pl to verify a"
    echo "   candidate that already exists, which is what the repair loop does"
    echo "   on every iteration."
    exit 3
  fi
  [ -x "$BIN" ] || { echo "   no binary at $BIN" >&2; exit 2; }
  WS=$(mktemp -d) || exit 2
  python3 "$HERE/assemble.py" --show system "$REQ" > "$WS/system.txt"
  python3 "$HERE/assemble.py" --show user   "$REQ" > "$WS/user.txt"
  # THROUGH THE ENVIRONMENT, NOT argv. cocolog answers exactly one
  # prolog flag -- `executable' -- so there is no current_prolog_flag(argv, _)
  # to read, and `run FILE... GOAL' takes the LAST argument as the goal.
  COCO_AGENT_SYSTEM="$WS/system.txt" \
  COCO_AGENT_USER="$WS/user.txt" \
  COCO_AGENT_OUT="$WS/out.json" \
  COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY" "$BIN" --local \
    run "$HERE/generate.pl" coco_generate \
    || { echo "   the model call failed"; exit 4; }
  CAND="$WS/candidate.pl"
  python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
if d.get("verdict") != "code":
    print(json.dumps(d, indent=1)); sys.exit(5)
open(sys.argv[2], "w").write(d["files"][0]["content"])
' "$WS/out.json" "$CAND" || exit 5
fi
echo

# ---- 3. the gates --------------------------------------------------------
echo "== 3. verify"
sh "$HERE/verify.sh" "$CAND"
