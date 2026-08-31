"""traps.jsonl -- the dialect card, as data, with every citation checked.

The card in library/llm/DESIGN.md section 4 is thirty-six rows of "SWI writes
X, cocolog needs Y, because <source citation>".  A citation nobody checks is a
citation that rots: a line number moves and the row goes on asserting a fact
about code that is no longer there.  So each row carries, beside its cite, an
ANCHOR -- a literal substring that must appear inside the cited line range --
and this file checks every one.

THE ANCHOR IS CODE, NEVER PROSE NEAR IT.  Comments are the part of a file that
gets rewritten without the behaviour changing, so anchoring on one gives a
check that passes while the claim quietly stops being true.  Row F1 anchors on
`(== d 116)' and not on the word "column"; row I1 on `coco_arg_key' and not on
the declaration's shouted comment above it, true though that comment is.

Two rows anchor on a comment anyway and say so here rather than pretending:
Z1's page-size limit lives in parsi/01-schema.parsi as a paragraph of measured
numbers with no code beside it, and R2's evidence IS the Prolog text of the
clauses in a *X-prolog* string table.  Both are quoted exactly.

    python3 traps.py --check          every cite resolves, every anchor is there
    python3 traps.py --card           the card, regenerated from the rows
    python3 traps.py --patterns       the S1 regexes, for lint.py
"""

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.environ.get("COCOLOG_ROOT", os.path.join(HERE, "..", "..")))
TRAPS = os.path.join(HERE, "traps.jsonl")

REQUIRED = ("id", "severity", "rule", "swi", "cocolog", "why", "cite")
SEVERITIES = ("HARD", "WARN", "PROMPT")


def load(path=TRAPS):
    rows = []
    with open(path, encoding="utf-8") as f:
        for n, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            try:
                rows.append(json.loads(line))
            except ValueError as e:
                sys.stderr.write("traps.jsonl:%d not JSON: %s\n" % (n, e))
                sys.exit(2)
    return rows


def parse_cite(at):
    """`path:LINE' or `path:A-B' -> (path, first, last), both 1-based inclusive."""
    path, _, span = at.rpartition(":")
    if not path:
        return None
    if "-" in span:
        a, _, b = span.partition("-")
    else:
        a = b = span
    try:
        return path, int(a), int(b)
    except ValueError:
        return None


def check(rows):
    """Every complaint, as a list of strings. Empty means the card is sound."""
    bad = []
    seen = set()
    for r in rows:
        rid = r.get("id", "<no id>")
        for k in REQUIRED:
            if k not in r:
                bad.append("%s: missing field %s" % (rid, k))
        if rid in seen:
            bad.append("%s: duplicate id" % rid)
        seen.add(rid)
        if r.get("scan", "code") not in ("code", "text"):
            bad.append("%s: scan %r is not code or text" % (rid, r.get("scan")))
        if r.get("severity") not in SEVERITIES:
            bad.append("%s: severity %r is not one of %s"
                       % (rid, r.get("severity"), "/".join(SEVERITIES)))
        # A row that names a linter rule and carries a pattern must have a
        # pattern that compiles -- lint.py loads these verbatim.
        if r.get("pattern"):
            try:
                re.compile(r["pattern"])
            except re.error as e:
                bad.append("%s: pattern does not compile: %s" % (rid, e))
        for c in r.get("cite", []):
            at, anchor = c.get("at"), c.get("anchor")
            if not at or anchor is None:
                bad.append("%s: a cite needs both `at' and `anchor'" % rid)
                continue
            p = parse_cite(at)
            if p is None:
                bad.append("%s: cite %r is not path:LINE or path:A-B" % (rid, at))
                continue
            rel, first, last = p
            full = os.path.join(ROOT, rel)
            if not os.path.exists(full):
                bad.append("%s: %s does not exist" % (rid, rel))
                continue
            with open(full, encoding="utf-8", errors="replace") as f:
                lines = f.readlines()
            if last > len(lines):
                bad.append("%s: %s has %d lines, cite names %d"
                           % (rid, rel, len(lines), last))
                continue
            region = "".join(lines[first - 1:last])
            if anchor not in region:
                # Say where it IS, if anywhere -- a moved line is the common
                # case and the fix is then one number.
                whole = "".join(lines)
                where = ""
                if anchor in whole:
                    at_line = whole[:whole.index(anchor)].count("\n") + 1
                    where = " (it is at line %d)" % at_line
                bad.append("%s: anchor not in %s:%d-%d%s\n      %r"
                           % (rid, rel, first, last, where, anchor))
    return bad


def patterns(rows):
    """The S1 table, for lint.py: (id, regex, why, cite, fix, scan).

    `scan' is "code" (the default: a match inside a quote or a comment is not
    a finding) or "text" (a quote counts as code; a comment still does not).
    Only F1 and E1 are "text", both by construction -- a format column
    directive and a \\xHH\\ escape live INSIDE a quote, so a rule that skipped
    quotes could never see either. Nothing scans comments: a comment naming
    `~t' documents the rule rather than breaking it."""
    out = []
    for r in rows:
        if not r.get("pattern"):
            continue
        cite = r["cite"][0]["at"] if r.get("cite") else None
        out.append((r["id"], r["pattern"], r["why"], cite, r.get("fix"),
                    r.get("scan", "code")))
    return out


def card(rows):
    """Section B of the dialect card, regenerated. Silent rows first, because a
    loud failure is repaired by a gate for free and needs no card row."""
    order = {"HARD": 0, "WARN": 1, "PROMPT": 2}
    rows = sorted(rows, key=lambda r: (order.get(r["severity"], 9), r["id"]))
    w = sys.stdout.write
    w("| id | SWI writes | cocolog needs | because |\n|---|---|---|---|\n")
    for r in rows:
        cite = "; ".join(c["at"] for c in r.get("cite", []))
        one = lambda s: s.replace("\n", " ").replace("|", "\\|")
        w("| **%s** | `%s` | %s | %s (`%s`) |\n"
          % (r["id"], one(r["swi"]), one(r["cocolog"]), one(r["why"]), cite))


def main(argv):
    rows = load()
    if "--patterns" in argv:
        for p in patterns(rows):
            print("%-4s %s" % (p[0], p[1]))
        return 0
    if "--card" in argv:
        card(rows)
        return 0
    bad = check(rows)
    for b in bad:
        print("traps: " + b)
    n = len(rows)
    if bad:
        print("traps: %d rows, %d complaints" % (n, len(bad)))
        return 1
    cites = sum(len(r.get("cite", [])) for r in rows)
    pats = len(patterns(rows))
    print("traps: %d rows, %d cites all anchored, %d S1 patterns" % (n, cites, pats))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
