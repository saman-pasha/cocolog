#!/bin/sh
# Ask the engine of the mode and cocolog -- the Prolog this mode is
# written for -- the same questions, and compare their answers.  A graph
# that says a query succeeds when cocolog says it fails would be worse
# than no graph at all, so this is the check that matters most.  It runs
# every test query of the example files, every query of
# test/conformance-queries.txt, and every example the snippet pickers
# show -- what the mode traces, cocolog must prove, and what the mode
# offers, cocolog must run.
#
#   make coco            (or: tools/coco-diff.sh)
#
# Needs the cocolog binary from the repository root (`make' up there
# builds it); everything else is in the mode.  COCOLOG=/path/to/cocolog
# points it somewhere else.
set -eu

EMACS=${EMACS:-emacs}
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"
COCOLOG=${COCOLOG:-$here/../cocolog}

[ -x "$COCOLOG" ] || {
  echo "cocolog not found at $COCOLOG: build it at the repository root," >&2
  echo "or set COCOLOG=/path/to/cocolog" >&2
  exit 2
}

mine=$(mktemp -t cocolog-mine.XXXXXX)
trap 'rm -f "$mine"' EXIT

"$EMACS" -Q --batch -L . -L tools -l tools/conformance.el 2>/dev/null > "$mine"

COCOLOG="$COCOLOG" python3 - "$mine" <<'PY'
import os, re, subprocess, sys, tempfile

COCOLOG = os.environ['COCOLOG']
ROOT = os.path.dirname(os.path.abspath(COCOLOG))

# The library cocolog is given with every question: SWI's dcg/basics and
# yall as cocolog vendors them, then the few rules the engine's library
# has that the vendored files do not.
LIBRARY = [p for p in
           [os.path.join(ROOT, 'lib', 'swipl', 'dcg_basics.pl'),
            os.path.join(ROOT, 'lib', 'swipl', 'yall.pl'),
            'tools/coco-prelude.pl']
           if os.path.exists(p)]

def blocks_of(text):
    """The clause blocks of a Prolog file: (head-name-or-None, text).

    A block starts at a line whose first column opens a head -- a lower
    case name -- and runs to the next such line.  Directives, comments
    and operator-headed clauses keep a None name and are never dropped."""
    out, name, lines = [], None, []
    for line in text.split('\n'):
        m = re.match(r'([a-z][A-Za-z0-9_]*)', line)
        if m:
            if lines:
                out.append((name, '\n'.join(lines)))
            name, lines = m.group(1), [line]
        else:
            lines.append(line)
    if lines:
        out.append((name, '\n'.join(lines)))
    return out

def defined_names(text):
    """The predicate names a program defines at its first column."""
    return {name for name, _ in blocks_of(text) if name}

def calls(text, names):
    """Non-nil when the block TEXT mentions one of NAMES outside remarks."""
    bare = re.sub(r'%.*', '', text)
    return any(re.search(r'\b%s\b' % re.escape(n), bare) for n in names)

def filtered_library(program_text):
    """The library with the program's own predicates shadowed out.

    The engine resolves a program's own rules before its library's, the
    way a module's definition shadows an import.  cocolog consults into
    one namespace, so the same reading is made by leaving out every
    library clause for a predicate the program defines -- and, so no
    half-library rule is left calling across the seam, every library
    clause that reaches one of those, to a fixpoint."""
    lib = '\n'.join(open(p).read() for p in LIBRARY)
    # a /*...*/ remark reads like clauses to the line splitter below
    lib = re.sub(r'/\*.*?\*/', '', lib, flags=re.S)
    shadowed = defined_names(program_text)
    blocks = blocks_of(lib)
    dropped = {n for n, _ in blocks if n and n in shadowed}
    while True:
        more = {n for n, t in blocks
                if n and n not in dropped and calls(t, dropped)}
        if not more:
            break
        dropped |= more
    return '\n'.join(t for n, t in blocks if n is None or n not in dropped)

def variables(query):
    """The variables of the query, in order of first appearance.

    The engine names a solution by the variables written in the query,
    so cocolog is asked to print those same names.  A name inside a
    quoted atom or a string is text, not a variable, and a name that
    starts with an underscore says nothing worth comparing."""
    bare = re.sub(r"'(?:[^'\\]|\\.)*'", "''", query)
    bare = re.sub(r'"(?:[^"\\]|\\.)*"', '""', bare)
    seen, out = set(), []
    for m in re.finditer(r'\b([A-Z_][A-Za-z0-9_]*)\b', bare):
        name = m.group(1)
        if name.startswith('_') or name in seen:
            continue
        seen.add(name)
        out.append(name)
    return out

def error_text(stderr):
    """cocolog's uncaught exception, said the way the engine says it."""
    for line in stderr.splitlines():
        m = re.search(r'uncaught exception:\s*(.*)', line)
        if not m:
            continue
        term = m.group(1).strip()
        pi = re.search(r'existence_error\(procedure,\s*([^)]*)\)', term)
        if pi:
            return 'ERROR: unknown procedure ' + pi.group(1).strip()
        return 'ERROR: uncaught exception: ' + term
    return None

def ask(program_text, query):
    """What cocolog answers for QUERY against PROGRAM_TEXT, as one line.

    One --local run per query: consult the shadow-filtered library and
    the program, prove a goal that prints each solution as NAME=VALUE
    bindings on a line of its own, then join the first ten the way the
    engine joins its own.  Every printed line opens on a fresh one, so a
    query that writes cannot run its text into an answer."""
    q = query.strip().rstrip('.')
    names = variables(q)
    if names:
        fmt = '~n' + ','.join('%s=~q' % n for n in names) + '~n'
        goal = 'forall((%s), format("%s", [%s]))' % (q, fmt, ', '.join(names))
        keep = re.compile(r'^%s=' % re.escape(names[0]))
    else:
        goal = '( (%s) -> format("~ncoco_true~n", []) ; true )' % q
        keep = re.compile(r'^coco_true$')
    lib = tempfile.NamedTemporaryFile('w', suffix='.pl', delete=False)
    prog = tempfile.NamedTemporaryFile('w', suffix='.pl', delete=False)
    try:
        lib.write(filtered_library(program_text)); lib.close()
        prog.write(program_text); prog.close()
        try:
            run = subprocess.run([COCOLOG, '--local', 'run',
                                  lib.name, prog.name, goal],
                                 capture_output=True, text=True, timeout=60)
        except subprocess.TimeoutExpired:
            return '<timeout>'
    finally:
        os.unlink(lib.name)
        os.unlink(prog.name)
    err = error_text(run.stderr)
    if err:
        return err
    lines = [l for l in run.stdout.splitlines() if keep.match(l)]
    if not lines:
        return 'no solutions'
    if not names:
        return 'true'
    return ' ; '.join(lines[:10])

def norm(s):
    """Reduce an answer to what it says, not how it was written.

    The two writers differ in three harmless ways: an unbound variable
    is printed by its name here and as _123 there, they space terms
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

programs = {}
def program_text(path, inline):
    """The program a question is asked against: the fourth column when
    the line carries one -- a snippet brings its rule along -- and the
    file named by the first column otherwise."""
    if inline:
        return re.sub(r'\\(.)',
                      lambda m: {'n': '\n', 't': '\t'}.get(m.group(1),
                                                           m.group(1)),
                      inline)
    if path not in programs:
        programs[path] = open(path).read() if os.path.exists(path) else ''
    return programs[path]

agree = differ = 0
for line in open(sys.argv[1]):
    parts = (line.rstrip('\n').split('\t') + ['', '', ''])[:4]
    path, query, ours, inline = parts
    if not query:
        continue
    coco = ask(program_text(path, inline), query)
    if norm(ours) == norm(coco):
        agree += 1
    else:
        differ += 1
        print("DIFFERS  %s\n  ?- %s.\n    engine : %s\n    cocolog: %s"
              % (path, query.rstrip('.'), ours, coco))
print("\n%d queries, %d agree, %d differ" % (agree + differ, agree, differ))
sys.exit(1 if differ else 0)
PY
