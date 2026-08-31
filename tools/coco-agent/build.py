"""Build the reserved-name blocklist from source, in one pass.

FIVE REGISTRATION SHAPES, and the fifth is the one an earlier pass missed:

  1  (DEFPARAMETER *X-predicates*/*builtins* '(("name" arity fn) ...))
  2  (DEFPARAMETER *X-prolog* (FORMAT NIL "~{~A ~}" (LIST "clause..." ...)))
  3  a hand-written strcmp chain under (== arity N)  -- torch and bigint only
  4  clause heads at column 0 in a .pl file          -- DCG heads at arity+2
  5  (DEFPARAMETER *construct-names* ...)            -- NO ARITY, any arity blocked

NO TOTAL IS AN ACCEPTANCE TEST. Two independent extractions this session got
464 and ~533 for tier 1, differing on $-prefixed internals, DCG arity and
comment stripping. The linter needs the SET, regenerated from source; a count
pinned in a test would just go stale and be edited to match.

TWO AXES, because the two halves fail differently:

  WHEN   tier 1 is always live; a module's names only once imported.
  HOW    a C-registered name is dispatched BEFORE the store
         (lib/solve.cicili:1352-1386), so redefining it is DEAD CODE.
         A clause-defined one is consulted into the same store and consult
         APPENDS, so redefining it merges the two sets of clauses.
"""

import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import clauses as R

ROOT = os.environ.get("COCOLOG_ROOT", os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ROOT = os.path.abspath(ROOT)


def _p(*a):
    return os.path.join(ROOT, *a)


# ANY name, not just an alphanumeric one. The first version of this required
# [a-zA-Z_] and therefore missed every OPERATOR builtin -- =/2, ==/2, is/2,
# </2, =../2 -- which is fifteen names in lib/ alone, and exactly the ones a
# generated program is most likely to redefine by accident.
C_TABLE = re.compile(r'\("([^"]+)"\s+(\d+)\s+[a-z_]')
STRCMP = re.compile(r'strcmp\s+name\s+"([^"]+)"')
CICILI_STR = re.compile(r'"((?:[^"\\]|\\.)*)"')


def _unescape(s):
    out, i = [], 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s):
            out.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(s[i + 1], s[i + 1]))
            i += 2
        else:
            out.append(s[i])
            i += 1
    return "".join(out)


def shape1_c_tables(files):
    """Shape 1: the (\"name\" arity fn) tables."""
    out = {}
    for f in files:
        src = open(f, encoding="utf-8", errors="replace").read()
        for m in C_TABLE.finditer(src):
            out.setdefault("%s/%s" % (m.group(1), m.group(2)), set()).add(f)
    return out


PROLOG_TABLE = re.compile(r"\(DEFPARAMETER\s+\*[a-z0-9-]+-prolog\*", re.I)


def _sexp_end(src, i):
    """The offset just past the s-expression opening at I, quotes respected."""
    depth, n, inq = 0, len(src), False
    while i < n:
        c = src[i]
        if inq:
            if c == "\\":
                i += 2
                continue
            if c == '"':
                inq = False
        elif c == '"':
            inq = True
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return n


def shape2_prolog_halves(files):
    """Shape 2: clauses living inside a `*X-prolog*' DEFPARAMETER. They are
    read with the SAME clause reader as a .pl file, after unescaping, so a DCG
    in a module's Coco half is recorded at arity+2 like any other.

    SCOPED TO THE TABLE, NOT TO EVERY STRING IN THE FILE, and the difference
    was 354 names. Scanning every literal turned "abs" out of the arithmetic
    strcmp chain into a clause `abs.' and recorded abs/0; the same went for
    "abc" out of a test, "access_mode" out of a mode check, and 351 others.
    Every one of them would have made the linter reject a program for defining
    a name nothing in cocolog defines -- the worst kind of false positive,
    because the message is confident and cites a file.

    The second guard is structural and cheap: a Prolog clause has a `('
    somewhere, or is a `:-' or a `-->'. A bare identifier is an atom, and an
    atom in a C string is not a program."""
    out = {}
    for f in files:
        src = open(f, encoding="utf-8", errors="replace").read()
        for t in PROLOG_TABLE.finditer(src):
            start = src.rfind("(", 0, t.end())
            start = t.start()
            region = src[start:_sexp_end(src, start)]
            for m in CICILI_STR.finditer(region):
                text = _unescape(m.group(1)).strip()
                if not text or not re.match(r"^'?[$a-z]", text):
                    continue
                if "(" not in text and ":-" not in text and "-->" not in text:
                    continue
                if not text.endswith("."):
                    text += "."
                for c in R.split_clauses(text):
                    R.read_head(c)
                    if c.key() and not c.is_directive:
                        out.setdefault(c.key(), set()).add(f)
    return out


def shape3_strcmp(files):
    """Shape 3: torch's and bigint's hand-written dispatch chains. No arity is
    recorded there, so the name is blocked at every arity -- written as
    `name/*' and matched by name."""
    out = {}
    for f in files:
        src = open(f, encoding="utf-8", errors="replace").read()
        for m in STRCMP.finditer(src):
            out.setdefault(m.group(1) + "/*", set()).add(f)
    return out


HOOK = re.compile(r"^[^:]*:-\s*fail\s*\.$", re.S)


def shape4_pl(files):
    """Clause heads at column 0 -- MINUS the hooks.

    A library clause of the form `H :- fail.' is not a definition, it is a
    DECLARED EXTENSION POINT: library/httpd.pl:683 is `httpd_page(_,_,_) :-
    fail.' precisely so a program can add its own pages, which is the whole
    design of that library. Blocking the name would tell every httpd user to
    rename the one predicate they are supposed to write.

    THE HOOKS ARE RETURNED TOO, not thrown away, because the collision oracle
    needs the same set. Measured over the 58-file corpus, the oracle and rule
    N1 agree on 57 files and disagree on exactly one: 16-httpd.pl's
    httpd_page/3, which the oracle calls COLLIDED (correctly -- the clauses do
    merge and current_predicate/1 does say no) and N1 stays quiet about
    (correctly -- it is the extension point the library exists to offer). Both
    are right about the mechanism and only one is right about the intent, so
    both must read the same list or they will drift apart."""
    out, hooks_out = {}, {}
    for f in files:
        try:
            src, cls = R.read_file(f)
            hooks = {c.key() for c in cls
                     if c.key() and not c.is_directive and HOOK.match(c.text.strip())}
            for k in hooks:
                hooks_out.setdefault(k, set()).add(f)
            for c in cls:
                k = c.key()
                if k and not c.is_directive and k not in hooks:
                    out.setdefault(k, set()).add(f)
        except Exception:
            pass
    return out, hooks_out


def shape5_constructs():
    """Shape 5: the control constructs. lib/solve.cicili:151-154, placed ahead
    of every builtin in *dispatch-names* (:158-163). NO ARITY IS RECORDED, so
    nothing you can name escapes -- which makes this the most absolute of the
    five and the one an earlier blocklist missed entirely."""
    src = open(_p("lib", "solve.cicili"), encoding="utf-8", errors="replace").read()
    m = re.search(r"\(DEFPARAMETER \*construct-names\*\s*'\((.*?)\)\)", src, re.S)
    if not m:
        return {}
    return {n + "/*": {"lib/solve.cicili"}
            for n in re.findall(r'"([^"]+)"', m.group(1))}


def build():
    lib_cicili = sorted(glob.glob(_p("lib", "*.cicili")))
    mod_cicili = sorted(glob.glob(_p("modules", "*", "*.cicili")))
    swipl_pl = sorted(glob.glob(_p("lib", "swipl", "*.pl")))
    lib_pl = sorted(glob.glob(_p("library", "*.pl")))

    t1_c = {}
    for d in (shape1_c_tables(lib_cicili), shape5_constructs()):
        for k, v in d.items():
            t1_c.setdefault(k, set()).update(v)
    t1_p, hooks = {}, {}
    swipl_heads, swipl_hooks = shape4_pl(swipl_pl)
    for d in (shape2_prolog_halves(lib_cicili), swipl_heads):
        for k, v in d.items():
            t1_p.setdefault(k, set()).update(v)
    for k, v in swipl_hooks.items():
        hooks.setdefault(k, set()).update(v)

    # tier 2, per module directory and per library file
    t2 = {}
    for f in mod_cicili:
        mod = os.path.basename(os.path.dirname(f))
        e = t2.setdefault(mod, {"c": {}, "p": {}})
        for k, v in shape1_c_tables([f]).items():
            e["c"].setdefault(k, set()).update(v)
        for k, v in shape3_strcmp([f]).items():
            e["c"].setdefault(k, set()).update(v)
        for k, v in shape2_prolog_halves([f]).items():
            e["p"].setdefault(k, set()).update(v)
    for f in lib_pl:
        mod = os.path.basename(f)[:-3]
        e = t2.setdefault(mod, {"c": {}, "p": {}})
        heads, hks = shape4_pl([f])
        for k, v in heads.items():
            e["p"].setdefault(k, set()).update(v)
        for k, v in hks.items():
            hooks.setdefault(k, set()).update(v)

    # A name registered in C is dispatched before the store, so the C set wins.
    # AND A CONSTRUCT NAME WINS AT EVERY ARITY, which is a separate line
    # because a construct is recorded with NO arity (`throw/*'): matching only
    # on the exact key left throw/1 in the clause set, where the prompt's
    # symbol block would have called it nondet. Asked directly, the store says
    # throw/1 is visible -- the oracle's documented blind spot -- so rule N3,
    # which matches on the name alone, is the only thing that catches it.
    names_c = {k[:-2] for k in t1_c if k.endswith("/*")}
    for k in list(t1_p):
        if k in t1_c or k.rsplit("/", 1)[0] in names_c:
            del t1_p[k]

    rel = lambda s: sorted(os.path.relpath(x, ROOT) for x in s)
    return {
        "tier1": {"c": {k: rel(v) for k, v in t1_c.items()},
                  "clauses": {k: rel(v) for k, v in t1_p.items()}},
        "tier2": {m: {"c": {k: rel(v) for k, v in e["c"].items()},
                      "clauses": {k: rel(v) for k, v in e["p"].items()}}
                  for m, e in t2.items()},
        # `H :- fail.' in a library: a declared extension point, not a
        # definition. Excluded from the blocklist above and recorded here so
        # the collision oracle can excuse the same names -- the two halves
        # disagree about exactly these, and only because one knows the intent.
        "hooks": {k: rel(v) for k, v in hooks.items()},
    }


def _q(a):
    """An atom, quoted for cocolog's reader. Doubling is how a quote escapes."""
    return "'" + a.replace("'", "''") + "'"


def facts(b):
    """The blocklist as CLAUSES, which is what lint.pl consults.

    A 39-FOLD DIFFERENCE, MEASURED. library(json) parses the 72 KB
    blocklist.json in 275ms; the same data as facts consults in 7ms, and every
    lookup afterwards rides first-argument indexing instead of walking an
    association list. The linter asks these questions once per clause head over
    a 58-file corpus, so the difference is the whole run.

    IT ALSO SIDESTEPS A BUG. json_parse/2 is documented `is det' and is not:
    any document containing true, false or null leaves a choice point whose
    second solution throws syntax_error([]). The hot path never touches it.

    The JSON stays -- build.py still writes it, the Python tools still read it,
    and it is the form a human greps. This is a second rendering of one
    extraction, not a second extraction.
    """
    out = ["%% blocklist.pl -- GENERATED by tools/coco-agent/build.py. Do not edit.",
           "%%",
           "%% cl_t1c(Name, Arity, File)    C-dispatched in tier 1; redefining it is",
           "%%                              DEAD CODE, because dispatch reaches the",
           "%%                              builtin table before the store.",
           "%%                              Arity -1 means a CONTROL CONSTRUCT, which",
           "%%                              is matched by name at every arity.",
           "%% cl_t1p(Name, Arity, File)    clause-defined in tier 1; redefining it",
           "%%                              APPENDS to the library's clauses.",
           "%% cl_t2c/cl_t2p(Mod, N, A)     tier 2, counted only when imported.",
           "%% cl_hook(Name, Arity, File)   a declared extension point (H :- fail.),",
           "%%                              which is a collision that is MEANT.",
           ""]
    # ONE FACT PER DEFINING FILE, not per name: three tier-1 names are defined
    # in two files each (ord_intersection/3 and ord_subtract/3 in both
    # lib/lists.cicili and lib/swipl/ordsets.pl), and a message that named only
    # the first would be quietly telling half the truth about where a
    # collision lands.
    for k, v in sorted(b["tier1"]["c"].items()):
        n, a = k.rsplit("/", 1)
        for f in v:
            out.append("cl_t1c(%s, %s, %s)." % (_q(n), -1 if a == "*" else a, _q(f)))
    for k, v in sorted(b["tier1"]["clauses"].items()):
        n, a = k.rsplit("/", 1)
        for f in v:
            out.append("cl_t1p(%s, %s, %s)." % (_q(n), a, _q(f)))
    for m, e in sorted(b["tier2"].items()):
        for k in sorted(e["c"]):
            n, a = k.rsplit("/", 1)
            out.append("cl_t2c(%s, %s, %s)." % (_q(m), _q(n), -1 if a == "*" else a))
        for k in sorted(e["clauses"]):
            n, a = k.rsplit("/", 1)
            out.append("cl_t2p(%s, %s, %s)." % (_q(m), _q(n), a))
    for k, v in sorted(b["hooks"].items()):
        n, a = k.rsplit("/", 1)
        out.append("cl_hook(%s, %s, %s)." % (_q(n), a, _q(v[0])))
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    b = build()
    out = _p("tools", "coco-agent", "blocklist.json")
    with open(out, "w") as fh:
        json.dump(b, fh, indent=1, sort_keys=True)
    t1c, t1p = len(b["tier1"]["c"]), len(b["tier1"]["clauses"])
    print("tier 1: %d C-dispatched (redefinition is dead code)" % t1c)
    print("        %d clause-defined (redefinition appends)" % t1p)
    print("tier 2: %d libraries/modules, blocked only when imported" % len(b["tier2"]))
    print("hooks : %d declared extension points, excused in both halves" % len(b["hooks"]))
    fp = _p("tools", "coco-agent", "blocklist.pl")
    with open(fp, "w") as fh:
        fh.write(facts(b))
    print("wrote %s and %s" % (os.path.relpath(out, ROOT), os.path.relpath(fp, ROOT)))
