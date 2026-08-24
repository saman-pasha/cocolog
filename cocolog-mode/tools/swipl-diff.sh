#!/bin/sh
# Ask the engine of the mode and SWI-Prolog the same questions, and
# compare their answers.  A graph that says a query succeeds when SWI
# says it fails would be worse than no graph at all, so this is the
# check that matters most.
#
#   make swipl            (or: tools/swipl-diff.sh)
#
# Needs swipl on PATH; everything else is in the repository.
set -eu

EMACS=${EMACS:-emacs}
SWIPL=${SWIPL:-swipl}
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"

command -v "$SWIPL" >/dev/null 2>&1 || {
  echo "swipl not found: set SWIPL=/path/to/swipl" >&2
  exit 2
}

mine=$(mktemp -t cocolog-mine)
theirs=$(mktemp -t cocolog-swipl)
trap 'rm -f "$mine" "$theirs"' EXIT

"$EMACS" -Q --batch -L . -L tools -l tools/conformance.el 2>/dev/null > "$mine"

while IFS="$(printf '\t')" read -r file query answer; do
  # everything after -- is for the script; without it swipl would try to
  # load a query file that happens to end in .pl as a program of its own
  out=$("$SWIPL" -q -g true -t halt tools/swipl-query.pl -- "$file" "$query" 2>/dev/null | tr -d '\r' | head -1)
  printf '%s\t%s\t%s\n' "$file" "$query" "$out"
done < "$mine" > "$theirs"

python3 - "$mine" "$theirs" <<'PY'
import re, sys

def norm(s):
    """Reduce an answer to what it says, not how it was written.

    The two writers differ in three harmless ways: an unbound variable is
    printed by its name here and as _123 there, they space terms
    differently, and one parenthesises a lone operator atom."""
    s = s.strip()
    s = re.sub(r'\s+', '', s)
    parts = []
    for binding in split_bindings(s):
        if '=' in binding:
            name, _, value = binding.partition('=')
            value = re.sub(r'_G?\d+', '_', value)              # _123, _G123
            value = re.sub(r'\b[A-Z][A-Za-z0-9_]*\b', '_', value)  # a name still unbound
            value = re.sub(r'\((<|>|=)\)', r'\1', value)         # (<) and <
            binding = name + '=' + value
        parts.append(binding)
    return ','.join(parts)

def split_bindings(s):
    """Split "A=1,B=f(x,y)" into its bindings, not into its commas."""
    out, depth, current = [], 0, ''
    for ch in s:
        if ch in '([':
            depth += 1
        elif ch in ')]':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(current)
            current = ''
        else:
            current += ch
    if current:
        out.append(current)
    return out

def load(path):
    out = {}
    for line in open(path):
        parts = (line.rstrip('\n').split('\t') + ['', ''])[:3]
        out[(parts[0], parts[1])] = parts[2]
    return out

mine, theirs = load(sys.argv[1]), load(sys.argv[2])
agree = differ = 0
for key, ours in mine.items():
    swi = theirs.get(key, '<no answer>')
    if norm(ours) == norm(swi):
        agree += 1
    else:
        differ += 1
        print("DIFFERS  %s\n  ?- %s.\n    cocolog: %s\n    swipl  : %s"
              % (key[0], key[1], ours, swi))
print("\n%d queries, %d agree, %d differ" % (agree + differ, agree, differ))
sys.exit(1 if differ else 0)
PY
