"""cocolint -- a dialect linter for cocolog.

The deterministic half of the NL-to-cocolog agent in library/llm/DESIGN.md,
and useful on its own: a human runs it by hand on a .pl file and it says
which of this dialect's divergences the file has walked into.

Every rule below exists because the failure it catches is SILENT or nearly
so. A loud failure needs no linter -- the interpreter already names it.

  P1  the file does not read at all, reported at line:col rather than at
      the byte offset the interpreter gives
  D1  a directive outside the accepted fourteen, which ABORTS THE WHOLE
      CONSULT rather than being ignored
  N1  a head that collides with a clause-defined tier-1 name: the two sets
      of clauses merge, and which is tried first depends on how the file
      is run
  N2  a head that collides with a C-registered name: dispatched before the
      store, so your clauses are DEAD CODE
  N3  a head whose NAME is a control construct: no arity escapes it
  S1  a form this dialect refuses or silently reads differently
  T1  a call into a tier-2 library with no use_module, and the inverse
  C2  one name defined in two files of the same run
"""

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import clauses as R

ROOT = os.path.abspath(os.environ.get("COCOLOG_ROOT", os.path.join(HERE, "..", "..")))

# The fourteen. Ten in coco_directive (lib/kb.cicili:671-773) and four handled
# earlier by the reader's conditional compilation (:1140-1188). Anything else
# is `unsupported directive: NAME/ARITY' and coco_consult returns -1 for the
# whole file (:1196-1197).
DIRECTIVES = {
    "dynamic": (1,), "discontiguous": (1,), "multifile": (1,), "module": (2,),
    "meta_predicate": (1,), "op": (3,), "use_module": (1, 2),
    "autoload": (1, 2), "ensure_loaded": (1,), "set_prolog_flag": (2,),
    "if": (1,), "elif": (1,), "else": (0,), "endif": (0,),
}

TIER1_ALWAYS = {"apply", "builtins", "dcg", "files", "library", "lists", "zigurat",
                "assoc", "pairs", "ordsets", "yall", "aggregate", "ugraphs",
                "dcg_basics", "dcg_high_order"}

# S1: forms that compile and are wrong, each with the reason and a citation.
BANNED = [
    (r"format\s*\(\s*string\s*\(", "format/3 has no string(S) sink; there is no string type. "
     "The sinks are user_output user_error atom/1 chars/1,2 codes/1,2.",
     "lib/builtins.cicili:1120-1152", "use format(atom(A), ...)"),
    (r"~[t|+]", "format/2 has no column directives; ~t ~| and ~+ are refused BY NAME.",
     "lib/builtins.cicili:1015-1018", "pad by hand"),
    (r"\bwrite_canonical\s*\(", "write_canonical/1 KEEPS operators here -- it is identical to "
     "writeq/1, unlike ISO and SWI.", "lib/syntax.cicili:1414-1415",
     "write_term(T,[quoted(true),ignore_ops(true)])"),
    (r"\bb_setval\s*\(", "b_setval IS nb_setval -- the same C function. Nothing is "
     "backtrackable.", "lib/builtins.cicili:76-79", "thread an accumulator argument"),
    (r":-\s*initialization\s*\(", "initialization/1 is not a directive here and ABORTS THE "
     "WHOLE CONSULT.", "lib/kb.cicili:772", "name the goal on the CLI: cocolog run f.pl main"),
    (r":-\s*table\s*", "table/1 is not a prefix operator here, so the file does not even parse.",
     "lib/syntax.cicili:97-100", "remove it"),
    (r"\bstring_concat\s*\(|\bsplit_string\s*\(|\bsub_string\s*\(|\batom_string\s*\(",
     "no string type and none of these exist.", "card row X1",
     "atom_concat/3, sub_atom/5, atom_codes/2"),
    (r"'\[\|\]'", "a list cell is '.'/2 here, not SWI 7's '[|]'/2.",
     "lib/syntax.cicili:1305", "use '.'/2 or [_|_]"),
    (r"\bcall_with_inference_limit\s*\(", "spelled call_limited/3 here, deliberately, and it "
     "commits to the first solution where SWI's does not.", "lib/builtins.cicili:420-428",
     "call_limited/3"),
    (r"\bsetup_call_cleanup\s*\(|\bnb_current\s*\(|\bpredsort\s*\(|\bfreeze\s*\(|\bdif\s*\(",
     "absent from this dialect.", "card row X3", "write it out"),
    (r"\batan\s*\(\s*[^,()]+\s*,|\blog\s*\(\s*[^,()]+\s*,",
     "a two-argument arithmetic functor that does not exist. An unknown functor is "
     "UNCATCHABLY fatal -- coco_fail_err, no ball.", "lib/solve.cicili:1691",
     "atan(Y/X) plus a quadrant fix; log(N)/log(B)"),
    (r"\brandom\s*\(", "there is no random/1.", "card row A1",
     "a sin-based hash, as tutorials/torch/22 does"),
]

SEV = {"P1": "HARD", "D1": "HARD", "N1": "HARD", "N2": "HARD", "N3": "HARD",
       "S1": "HARD", "T1": "WARN", "C2": "HARD"}


def load_blocklist():
    p = os.path.join(HERE, "blocklist.json")
    if not os.path.exists(p):
        sys.stderr.write("cocolint: no blocklist.json -- run build.py first\n")
        sys.exit(2)
    return json.load(open(p))


class Finding:
    def __init__(self, path, line, col, rule, msg, fix=None, cite=None):
        self.path, self.line, self.col = path, line, col
        self.rule, self.msg, self.fix, self.cite = rule, msg, fix, cite
        self.severity = SEV.get(rule, "WARN")

    def render(self, rel):
        s = "%s:%d:%d %s %s %s" % (rel, self.line, self.col, self.severity, self.rule, self.msg)
        if self.fix:
            s += "\n    fix: " + self.fix
        if self.cite:
            s += "\n    see: " + self.cite
        return s


def lint_file(path, bl, imports_extra=()):
    rel = os.path.relpath(path, ROOT)
    out = []
    try:
        src, cls = R.read_file(path)
    except Exception as e:
        return [Finding(path, 1, 1, "P1", "cannot read: %s" % e)]

    # ---- which tier-2 libraries this file imports -------------------------
    imports = set(imports_extra)
    for c in cls:
        if c.is_directive and c.directive and c.directive[0] in ("use_module", "ensure_loaded"):
            m = re.search(r"library\s*\(\s*([a-z_0-9/]+)\s*\)", c.text)
            if m:
                imports.add(m.group(1).split("/")[-1])

    # ---- D1: directives ---------------------------------------------------
    for c in cls:
        if not c.is_directive or not c.directive:
            continue
        nm, ar = c.directive
        if nm not in DIRECTIVES:
            out.append(Finding(path, c.line, c.col, "D1",
                "`%s/%d' is not a directive here. An unsupported directive ABORTS THE "
                "WHOLE CONSULT -- the file loads nothing and cocolog exits 1." % (nm, ar),
                "the accepted set is: " + ", ".join(sorted(DIRECTIVES)),
                "lib/kb.cicili:772, consult returns -1 at :1196-1197"))
        elif ar not in DIRECTIVES[nm]:
            out.append(Finding(path, c.line, c.col, "D1",
                "`%s/%d' -- %s takes arity %s here." % (nm, ar, nm,
                    " or ".join(str(x) for x in DIRECTIVES[nm])),
                None, "lib/kb.cicili:671-773"))
        elif nm == "use_module":
            m = re.search(r"library\s*\(\s*([a-z_0-9]+)\s*\)", c.text)
            if m and m.group(1) in TIER1_ALWAYS:
                out.append(Finding(path, c.line, c.col, "T1",
                    "`library(%s)' is TIER 1 -- compiled in or preloaded. This directive "
                    "succeeds and does nothing." % m.group(1),
                    "delete it", "CLAUDE.md, the two tier-1 rows"))

    # ---- N1/N2/N3: collisions --------------------------------------------
    t1c, t1p = bl["tier1"]["c"], bl["tier1"]["clauses"]
    byname_c = {k.split("/")[0] for k in t1c if k.endswith("/*")}
    active_c, active_p = dict(t1c), dict(t1p)
    for mod in imports:
        e = bl["tier2"].get(mod)
        if e:
            active_c.update(e["c"])
            active_p.update(e["clauses"])

    seen = set()
    for c in cls:
        k = c.key()
        if not k or c.is_directive or k in seen:
            continue
        seen.add(k)
        nm = c.name
        dcg = " (a DCG head occupies arity+2)" if c.is_dcg else ""
        if nm in byname_c:
            out.append(Finding(path, c.line, c.col, "N3",
                "`%s' is a CONTROL CONSTRUCT, matched by interned id before the builtin "
                "table and before the store. No arity escapes it: your clauses are "
                "unreachable and no runtime check can see them." % nm,
                "rename it", "lib/solve.cicili:151-154, dispatched :1149-1351"))
        elif k in active_c:
            out.append(Finding(path, c.line, c.col, "N2",
                "`%s' is dispatched BEFORE the knowledge base%s. Your clauses are dead "
                "code -- they load, listing/1 shows them, and nothing calls them." % (k, dcg),
                "rename it", "lib/solve.cicili:1352-1386; defined in " + ", ".join(active_c[k])))
        elif k in active_p:
            out.append(Finding(path, c.line, c.col, "N1",
                "`%s' is already defined by %s%s. Consult APPENDS, so the two sets of "
                "clauses merge and which is tried first depends on how the file is run "
                "(`run' puts yours first, `-s' puts the library's)." % (
                    k, ", ".join(active_p[k]), dcg),
                "prefix it", "library/llm/DESIGN.md section 6.3"))

    # ---- S1: banned forms -------------------------------------------------
    for pat, msg, cite, fix in BANNED:
        for m in re.finditer(pat, src):
            # skip comment lines
            ls = src.rfind("\n", 0, m.start()) + 1
            if src[ls:m.start()].lstrip().startswith("%"):
                continue
            line, col = R._line_col(src, m.start())
            out.append(Finding(path, line, col, "S1", msg, fix, cite))

    out.sort(key=lambda f: (f.line, f.col))
    return out


def main(argv):
    paths = [a for a in argv if not a.startswith("-")]
    quiet = "-q" in argv or "--quiet" in argv
    if not paths:
        sys.stderr.write("usage: lint.py [-q] FILE.pl ...\n")
        return 2
    bl = load_blocklist()

    # C2 ONLY UNDER --manifest. C2 asks "do two files of ONE PROGRAM define
    # the same name", and a bag of unrelated files is not a program: run over
    # all 47 tutorials it reported main/0 forty-five times, which is true and
    # useless. The suite lints them as separate programs.
    manifest = "--manifest" in argv
    defined = {}
    findings = []
    for p in paths:
        for f in lint_file(p, bl):
            findings.append(f)
        try:
            for k in R.heads(p):
                defined.setdefault(k, []).append(os.path.relpath(p, ROOT))
        except Exception:
            pass
    for k, where in sorted(defined.items()) if manifest else []:
        if len(where) > 1:
            findings.append(Finding(paths[0], 1, 1, "C2",
                "`%s' is defined in %s. One run consults them all into one store and "
                "consult appends." % (k, " and ".join(where)), "keep it in one file"))

    hard = [f for f in findings if f.severity == "HARD"]
    warn = [f for f in findings if f.severity != "HARD"]
    if not quiet:
        for f in findings:
            print(f.render(os.path.relpath(f.path, ROOT)))
        if findings:
            print()
    print("cocolint: %d HARD, %d WARN over %d file(s)" % (len(hard), len(warn), len(paths)))
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
