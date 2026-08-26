#!/bin/sh
# colab/: the notebook and the scripts beside it, checked without a VM.
#
# WHAT IS BEING PINNED, and why any of it is worth a case:
#
#   THE VERSION IS DECLARED TWICE, and it has to be. colab/VERSION is
#   the repository's answer; NOTEBOOK_VERSION inside the notebook is the
#   BROWSER's answer, and the whole point of the check in section 1 is
#   that the second one can be stale. A fact in two places will disagree
#   with itself eventually -- so the two copies that live in THIS
#   repository are compared here, and what remains free to drift is
#   exactly the copy that is supposed to: the one in somebody's browser.
#
#   A NOTEBOOK IS JSON, and a broken one fails in Colab rather than
#   here, twenty minutes into a session, with a message about a cell
#   nobody can see. It is cheap to parse it now: valid JSON, nbformat 4,
#   every cell well-formed, and every plain-Python cell parsing.
#
#   AND THE SCRIPTS THE NOTEBOOK CALLS MUST EXIST. The cell runs
#   prereqs.sh, preflight.sh and build.sh by name from the clone. A
#   renamed script is a build that dies on the VM and nowhere else.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COLAB="$ROOT/colab"
NB="$COLAB/cocolog_colab.ipynb"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-44s %s\n' "$1" "$2"
  else
    printf 'FAIL %-44s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

# A MISSING NOTEBOOK IS A FAILURE, NOT A SKIP -- once colab/ is here.
# `SKIP' means "this checkout has no colab/ to check"; it must not also
# mean "the notebook is not where everything says it is", which is
# exactly the state a half-finished rename leaves behind. red: 0 does
# not mean the suite passed, and a case that skips its own subject is
# how that happens.
if [ ! -d "$COLAB" ]; then echo "SKIP (no colab/ in this checkout)"; exit 0; fi
if [ ! -f "$NB" ]; then
  echo "FAIL the notebook is not at colab/$(basename "$NB")"
  echo "     colab/ holds: $(ls "$COLAB" | tr '\n' ' ')"
  echo "RED: 1 failure(s)"; exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then echo "SKIP (no python3 to read the notebook)"; exit 0; fi

check "colab/VERSION declares a version" \
  "$(head -1 "$COLAB/VERSION" 2>/dev/null | grep -cE '^[0-9]+$')" "1"

# The two declarations, compared. The notebook's is a Python assignment
# in the cell; the repository's is the first line of the file.
check "and the notebook carries the same one" \
  "$(python3 - "$NB" "$COLAB/VERSION" <<'PY'
import json, re, sys
nb = json.load(open(sys.argv[1]))
src = '\n'.join(''.join(c['source']) for c in nb['cells'] if c['cell_type'] == 'code')
m = re.search(r'^NOTEBOOK_VERSION\s*=\s*(\d+)\s*$', src, re.M)
want = open(sys.argv[2]).readline().strip()
print('agree' if m and m.group(1) == want else
      'notebook %s, VERSION %s' % (m.group(1) if m else 'undeclared', want))
PY
)" "agree"

check "the version is printed before anything is installed" \
  "$(python3 - "$NB" <<'PY'
import json, sys
nb = json.load(open(sys.argv[1]))
src = '\n'.join(''.join(c['source']) for c in nb['cells'] if c['cell_type'] == 'code')
print('first' if 'notebook v{NOTEBOOK_VERSION}' in src
      and src.index('NOTEBOOK_VERSION') < src.index('prereqs.sh') else 'buried')
PY
)" "first"

check "and a stale notebook is named rather than guessed at" \
  "$(python3 - "$NB" <<'PY'
import json, sys
nb = json.load(open(sys.argv[1]))
src = '\n'.join(''.join(c['source']) for c in nb['cells'] if c['cell_type'] == 'code')
print('named' if "colab/VERSION" in src and "Revert to saved" in src else 'silent')
PY
)" "named"

check "the notebook is valid JSON, nbformat 4, cells well-formed" \
  "$(python3 - "$NB" <<'PY'
import ast, json, sys
try:
    nb = json.load(open(sys.argv[1]))
except Exception as e:
    print('unreadable: %s' % e); raise SystemExit
if nb.get('nbformat') != 4:
    print('nbformat %s' % nb.get('nbformat')); raise SystemExit
for i, c in enumerate(nb['cells']):
    if c['cell_type'] not in ('code', 'markdown') \
       or not isinstance(c.get('source'), list) \
       or not all(isinstance(l, str) for l in c['source']):
        print('cell %d malformed' % i); raise SystemExit
    if c['cell_type'] == 'code' and ('outputs' not in c or 'execution_count' not in c):
        print('cell %d is code without outputs' % i); raise SystemExit
    if c['cell_type'] == 'code':
        s = ''.join(c['source'])
        if s.lstrip().startswith('!') or '\n!' in s:
            continue              # a Colab shell magic is not Python
        try:
            ast.parse(s)
        except SyntaxError as e:
            print('cell %d: %s' % (i, e)); raise SystemExit
print('ok')
PY
)" "ok"

# The cell calls these by name from the clone; a rename is a failure that
# can only happen on the VM.
for s in prereqs.sh preflight.sh build.sh; do
  check "the notebook's $s is there to be called" \
    "$([ -f "$COLAB/$s" ] && grep -q "$s" "$NB" && echo present || echo missing)" "present"
done

# THE RENAME HAS TO REACH THE DOCUMENTATION TOO. COLAB.md carries the
# link people actually click -- the raw colab.research.google.com URL --
# and a notebook renamed without it is a 404 for everyone but the person
# who did the renaming.
NBNAME=$(basename "$NB")
check "COLAB.md names the notebook that exists" \
  "$(grep -c "$NBNAME" "$COLAB/COLAB.md" 2>/dev/null | head -1)" "2"
# Only LINKS are policed, not prose: COLAB.md says what the notebook
# used to be called, on purpose, so that a stale bookmark's 404 has an
# explanation. A link target ends in `)' or `>'; a name being discussed
# ends in a backtick. That distinction is the whole check.
check "and every .ipynb LINK points at it" \
  "$(grep -ohE '[A-Za-z0-9_/.-]+\.ipynb[)>]' "$COLAB/COLAB.md" 2>/dev/null \
     | sed 's/.*\///; s/[)>]$//' | sort -u | grep -vc "^$NBNAME$")" "0"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
