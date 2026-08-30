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

# NO CELL MAY DEPEND ON WHERE A PREVIOUS CELL LEFT THE PROCESS. A
# notebook cell inherits the last cell's working directory, so `./cocolog'
# is a bet on execution order -- and section 2 lost it the first time
# anyone ran the notebook without running section 4 first: the server
# cell used to %cd into ZiguratIP and %cd back, and section 2 runs
# before it. `./cocolog: Is a directory', because /content/cocolog is
# the checkout and the binary is inside it. Absolute paths everywhere,
# checked here so the next cell added does not reintroduce it.
check "no cell runs cocolog by a relative path" \
  "$(python3 - "$NB" <<'PYEOF'
import json, sys
nb = json.load(open(sys.argv[1]))
bad = []
for i, c in enumerate(nb['cells']):
    if c['cell_type'] != 'code':
        continue
    for line in ''.join(c['source']).split('\n'):
        code = line.split('#', 1)[0]          # a comment may DISCUSS it
        if './cocolog' in code or code.strip().startswith('%cd '):
            bad.append('cell %d: %s' % (i, line.strip()[:40]))
print('; '.join(bad) if bad else 'none')
PYEOF
)" "none"

# THE COMPILER PAGES MUST NOT SURVIVE THE BUILD. System/compiler.parsi
# is a web page whose POST handler compiles what you send it, and the
# ordinary ZiguratIP `make' produces it every time -- so a build meant
# to be tunnelled has to move it out of home/ld. Checked by RUNNING that
# part of build.sh against a fixture, because grepping for the code
# would pass on code that does not work.
FIX=$(mktemp -d)
mkdir -p "$FIX/home/ld" "$FIX/home/catalog"
touch "$FIX/home/ld/lib_COMPILER_.so" "$FIX/home/ld/lib_COMPILERDRAWER_.so" \
      "$FIX/home/ld/lib_CONNECTOR_.so" \
      "$FIX/home/catalog/_COMPILER_.conf" "$FIX/home/catalog/_CONNECTOR_.conf"
sed -n '/---- the compiler pages, moved out of reach/,/^fi$/p' "$COLAB/build.sh" > "$FIX/quar.sh"
{ printf 'set -u\nZIGURATIP_HOME=%s\n' "$FIX/home"; cat "$FIX/quar.sh"; } > "$FIX/quar2.sh" && mv "$FIX/quar2.sh" "$FIX/quar.sh"   # BSD sed has no GNU -i'1i'; prepend by hand
sh "$FIX/quar.sh" >/dev/null 2>&1

check "the build moves the compiler page out of home/ld" \
  "$(ls "$FIX/home/ld" | grep -c COMPILER || true)" "0"
check "and the drawer that renders it" \
  "$([ -f "$FIX/home/ld-disabled/lib_COMPILERDRAWER_.so" ] && echo quarantined || echo lost)" \
  "quarantined"
check "each object travels with its catalogue entry" \
  "$([ -f "$FIX/home/ld-disabled/_COMPILER_.conf" ] && echo together || echo split)" "together"
check "it is MOVED, not deleted" \
  "$([ -f "$FIX/home/ld-disabled/lib_COMPILER_.so" ] && echo recoverable || echo gone)" \
  "recoverable"
check "and every other page is left alone" \
  "$([ -f "$FIX/home/ld/lib_CONNECTOR_.so" ] && echo untouched || echo TAKEN)" "untouched"
check "a second build is a silent no-op" \
  "$(sh "$FIX/quar.sh" 2>&1 | wc -l | tr -d ' ')" "0"
check "KEEP_COMPILER_PAGES=1 leaves them and says so" \
  "$(touch "$FIX/home/ld/lib_COMPILER_.so"; \
     KEEP_COMPILER_PAGES=1 sh "$FIX/quar.sh" 2>&1 | grep -c 'DO NOT open a tunnel')" "1"
rm -rf "$FIX"

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
