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

A MOVED ANCHOR IS NOT A BROKEN CITATION when the anchor is unique in its
file.  The range is a finding aid there and nothing else -- if the text
appears exactly once, no range was ever distinguishing it from anything --
so the code moving is a fact about the code, not a defect in the card, and
--check accepts it, reports it, and --fix renumbers it.

The range earns its keep when the anchor is NOT unique, and then it is the
whole answer: `coco_arg_key', `coco_new_int' and `coco_num_value' each
appear in lib/ as a declaration, a definition and a use or two, and a range
that has drifted off the definition is now sitting on the declaration
saying something subtly different.  Nothing here can know which was meant,
so that stays a complaint for a human -- and it is not hypothetical: when
master rewrote lib/term.cicili under this card, the old checker's "it is at
line N" hint named the first occurrence and was wrong for all three.

An anchor that appears NOWHERE is the failure this file exists to catch.
The evidence for the claim has been deleted or rewritten, and the row needs
rereading rather than renumbering; the message says so in those words,
because the reflex on a red citation check is to reach for the line number.

    python3 traps.py --check          every anchor is there; drift is reported
    python3 traps.py --check --fix    ... and drifted cites are renumbered
    python3 traps.py --card           the card, regenerated from the rows
    python3 traps.py --patterns       the S1 pattern terms, one per line
"""

import io
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.environ.get("COCOLOG_ROOT", os.path.join(HERE, "..", "..")))
# Overridable so the suite can point the checker at a COPY with one cite
# broken on purpose. test/lint.sh exercises all three verdicts that way,
# and the real card is never written to by a test.
TRAPS = os.environ.get("COCOLOG_TRAPS", os.path.join(HERE, "traps.jsonl"))

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


# The vocabulary lint.pl's cl_at/4 implements, split by what its arguments
# are. Inside the DATA ones the argument is literal text or a character set --
# `lit(format)' names the word format, it does not call a constructor -- and
# validating there reported every literal in the table as an unknown functor.
CONSTRUCTORS_PATTERN = {"seq", "alt"}
CONSTRUCTORS_DATA = {"lit", "notword", "oneof", "noneof", "someof", "exactly"}
CONSTRUCTORS_NULLARY = {"ws", "bstart", "bend", "bol"}
CONSTRUCTORS = CONSTRUCTORS_PATTERN | CONSTRUCTORS_DATA | CONSTRUCTORS_NULLARY


def _bad_term(term):
    """Complaints about a pattern term: unbalanced, or an unknown constructor.

    NOT A PARSER, and it does not need to be -- cocolog reads the term for real
    when it consults traps.pl, and a malformed one fails loudly there. What
    this catches is the case that does NOT fail loudly: a well-formed term
    whose functor no clause of cl_at/4 matches, which loads fine and quietly
    never fires. `lit(foo' and `oneuf(bar)' are both caught, and so is a bare
    `bstrt' where `bstart' was meant.

    It is a stronger check than the re.compile it replaced, which could only
    say that a regex was a regex -- never that it was a rule anything
    implemented."""
    out = []
    stack = []          # enclosing functors, innermost last
    inq = False
    word = ""
    depth = 0
    i = 0

    def in_data():
        return any(f in CONSTRUCTORS_DATA for f in stack)

    while i < len(term):
        c = term[i]
        if inq:
            if c == "\\":
                i += 2
                continue
            if c == "'":
                inq = False
            i += 1
            continue
        if c == "'":
            inq = True
            word = ""
            i += 1
            continue
        if c == "(":
            depth += 1
            if not in_data() and word and word not in CONSTRUCTORS:
                out.append("unknown constructor %r -- lint.pl's cl_at/4 has no "
                           "clause for it, so the rule would never fire" % word)
            stack.append(word)
            word = ""
        elif c == ")":
            depth -= 1
            if depth < 0:
                out.append("unbalanced: a `)' with no `('")
                return out
            if not in_data() and word and word not in CONSTRUCTORS \
                    and not word.isdigit():
                out.append("unknown constructor %r" % word)
            word = ""
            if stack:
                stack.pop()
        elif c in ",[]":
            if not in_data() and word and word not in CONSTRUCTORS \
                    and not word.isdigit():
                out.append("unknown constructor %r" % word)
            word = ""
        elif c.isspace():
            word = ""
        else:
            word += c
        i += 1

    if depth != 0:
        out.append("unbalanced: %d unclosed `('" % depth)
    if inq:
        out.append("unbalanced: an unclosed quote")
    return out


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


def cite_status(rel, first, last, anchor, lines):
    """Where one cite stands, as (verdict, line, count).

    THE ANCHOR IS THE CLAIM AND THE RANGE IS ONLY A FINDING AID -- for a
    unique anchor, at least. If the text appears exactly once in the file
    then the range never distinguished anything, and a range that no longer
    contains it says the code MOVED, which is not a defect in the card. So
    that case is `drift': accepted, reported, and repairable with --fix.

    When the anchor appears more than once the range is load-bearing: it is
    the only thing separating the definition from the declaration and the
    three call sites, and a range that has drifted off one of them is now
    pointing at another. Nothing here can know which was meant, so that is
    `ambiguous' and a human has to choose -- exactly the case that made the
    checker's own "it is at line N" hint wrong for three rows when master
    moved lib/term.cicili under it.

    An anchor that appears nowhere is `gone': the evidence for the claim has
    been deleted or rewritten, which is the failure the card exists to catch.
    """
    whole = "".join(lines)
    n = whole.count(anchor)
    if anchor in "".join(lines[first - 1:last]):
        return "ok", None, n
    if n == 0:
        return "gone", None, 0
    at_line = whole[:whole.index(anchor)].count("\n") + 1
    return ("drift" if n == 1 else "ambiguous"), at_line, n


def anchor_lines(anchor, lines):
    """Every line the anchor starts on, 1-based. For the ambiguous message:
    naming the candidates is what lets a human pick one without grepping."""
    whole = "".join(lines)
    out, i = [], whole.find(anchor)
    while i >= 0:
        out.append(whole[:i].count("\n") + 1)
        i = whole.find(anchor, i + 1)
    return out


def check(rows):
    """(complaints, drifts). Empty complaints means the card is sound.

    A drift is (row id, anchor, old cite, new cite) and is NOT a complaint --
    see cite_status. --fix writes them back."""
    bad = []
    drifts = []
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
        # A PATTERN MUST BE A TERM lint.pl's matcher can read, and this checks
        # more than the regex compile it replaced: a regex that compiled could
        # still be a rule nobody had written a matcher for, whereas an unknown
        # constructor here is a rule that loads fine and silently never fires.
        if r.get("pattern"):
            for complaint in _bad_term(r["pattern"]):
                bad.append("%s: %s" % (rid, complaint))
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
            verdict, line, n = cite_status(rel, first, last, anchor, lines)
            if verdict == "ok":
                continue
            if verdict == "gone":
                bad.append("%s: anchor is GONE from %s -- the claim's evidence "
                           "was deleted or rewritten, so the row needs rereading, "
                           "not renumbering\n      %r" % (rid, rel, anchor))
                continue
            if verdict == "ambiguous":
                where = ", ".join(str(x) for x in anchor_lines(anchor, lines))
                bad.append("%s: anchor is not in %s:%d-%d and appears %d times "
                           "(lines %s) -- the range is what picks the site, so "
                           "which one this row means is yours to say\n      %r"
                           % (rid, rel, first, last, n, where, anchor))
                continue
            drifts.append((rid, anchor, at, "%s:%d" % (rel, line)))
    return bad, drifts


def fix(rows, drifts):
    """Rewrite the drifted cites in traps.jsonl, in place, and say how many.

    IT WRITES `path:LINE' AND NOT A WINDOW, because one line is all it knows.
    A range in the card is editorial -- somebody chose 782-808 to bracket a
    whole set_prolog_flag block -- and nothing here can reconstruct which of
    the moved block's lines they meant to include. Widening it back by hand
    keeps working: a wider range still contains the anchor, so it stays `ok'.

    SURGICAL, not a re-serialisation: json.dumps would reformat all
    thirty-six rows and bury a nine-line change in a seventy-two-line diff."""
    if not drifts:
        return 0
    want = {}
    for rid, anchor, old, new in drifts:
        want.setdefault(rid, []).append((anchor, old, new))
    lines = io.open(TRAPS, encoding="utf-8").readlines()
    n = 0
    for i, line in enumerate(lines):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        rid = json.loads(line).get("id")
        for anchor, old, new in want.get(rid, []):
            # Scope the replacement to the cite object carrying THIS anchor:
            # a row may cite two ranges and one of them may be another's.
            hit = _replace_in_cite(line, anchor, old, new)
            if hit is not None:
                lines[i] = line = hit
                n += 1
    io.open(TRAPS, "w", encoding="utf-8").writelines(lines)
    return n


def _replace_in_cite(line, anchor, old, new):
    """The raw JSONL line with `at' changed inside the cite holding `anchor'.

    None when no such cite is there. Brace-counting rather than a regex,
    because an anchor may legitimately contain a brace -- `(bitor ...)' does
    not, but a Cicili anchor easily could, and a regex over `{[^{}]*}' would
    silently match the wrong span the day one does."""
    a_j, o_j, n_j = json.dumps(anchor), json.dumps(old), json.dumps(new)
    i, depth, start, inq, esc = 0, 0, None, False, False
    while i < len(line):
        c = line[i]
        if inq:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                inq = False
        elif c == '"':
            inq = True
        elif c == "{":
            depth += 1
            if depth == 2:          # a cite object inside the row object
                start = i
        elif c == "}":
            if depth == 2 and start is not None:
                obj = line[start:i + 1]
                if a_j in obj and o_j in obj:
                    return line[:start] + obj.replace(o_j, n_j, 1) + line[i + 1:]
                start = None
            depth -= 1
        i += 1
    return None


def patterns(rows):
    """The S1 table: (id, term, why, cite, fix, scan).

    ONE RENDERING. These rows carried a Python regex too, back when a Python
    linter matched them; the terms are the rule now and the regexes are gone.
    A term says the same thing without the six silent divergences a POSIX
    engine brings to it -- and, unlike a regex, it says WHERE it matched,
    which is what a file:line:col finding needs.

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


def _q(a):
    """An atom, quoted for cocolog's reader. A quote escapes by doubling."""
    return "'" + str(a).replace("'", "''") + "'"


def facts(rows):
    """traps.jsonl as CLAUSES, which is what lint.pl consults.

    cl_trap(Id, Severity, Scan, Pattern, Why, Fix, Cite)

    PATTERN IS EMITTED AS A TERM, not as an atom: it is cocolog source.
    Everything else is an atom, quoted by doubling.

    THE MESSAGES ARE NOT COPIED INTO lint.pl. A rule and the evidence for it
    drifting apart is the failure this whole file was built to prevent, so
    there is one source -- traps.jsonl -- and two renderings of it, and
    test/lint.sh proves the renderings agree.
    """
    out = ["%% traps.pl -- GENERATED by tools/coco-agent/traps.py. Do not edit.",
           "%%",
           "%% cl_trap(Id, Severity, Scan, Pattern, Why, Fix, Cite)",
           "%%",
           "%%   Scan is `code' (a match inside a quote or a comment is not a",
           "%%   finding) or `text' (a quote counts as code; a comment still",
           "%%   does not). Only F1, L1 and E1 are `text', all three because the",
           "%%   form they look for lives INSIDE a quote by construction -- a",
           "%%   format directive, a list-cell atom, a character escape.",
           "%%",
           "%%   Pattern is a TERM, matched by cl_match/4. See lint.pl for the",
           "%%   vocabulary and for why it is not a regex.",
           ""]
    for r in rows:
        if not r.get("pattern"):
            continue
        cite = r["cite"][0]["at"] if r.get("cite") else "-"
        out.append("cl_trap(%s, %s, %s, %s, %s, %s, %s)." % (
            _q(r["id"]),
            _q(r["severity"].lower()),
            _q(r.get("scan", "code")),
            r["pattern"],
            _q(" ".join(r["why"].split())),
            _q(" ".join((r.get("fix") or "-").split())),
            _q(cite)))
    return "\n".join(out) + "\n"


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
    fixing = "--fix" in argv
    if "--patterns" in argv:
        for p in patterns(rows):
            print("%-4s %s" % (p[0], p[1]))
        return 0
    if "--facts" in argv:
        import os as _os
        fp = _os.path.join(HERE, "traps.pl")
        # Same staleness rule as build.py: traps.pl is generated from
        # traps.jsonl and from this file, and nothing else can change it.
        if "--if-stale" in argv and _os.path.exists(fp):
            src = max(_os.path.getmtime(TRAPS), _os.path.getmtime(__file__))
            if _os.path.getmtime(fp) >= src:
                return 0
        # ATOMIC, for the reason build.py's _write_atomic spells out: this
        # file is read by a cocolog process that another lint.sh may have
        # started while this one is writing.
        import tempfile as _tf
        _fd, _tmp = _tf.mkstemp(dir=HERE, prefix=".tmp-")
        with _os.fdopen(_fd, "w", encoding="utf-8") as fh:
            fh.write(facts(rows))
        _os.replace(_tmp, fp)
        print("traps: wrote %s (%d patterns)"
              % (_os.path.relpath(fp, ROOT), len(patterns(rows))))
        return 0
    if "--card" in argv:
        card(rows)
        return 0
    bad, drifts = check(rows)
    for b in bad:
        print("traps: " + b)
    # DRIFT IS NOT A COMPLAINT, and printing it under the same prefix would
    # make it read as one. It is reported because a range nobody refreshes
    # rots until the day its anchor stops being unique -- and that day the
    # message is `ambiguous', which costs a human a read of the code.
    for rid, anchor, old_at, new_at in drifts:
        print("traps: %s: %s moved to %s (unique anchor, accepted)\n      %r"
              % (rid, old_at, new_at, anchor))
    n = len(rows)
    if bad:
        print("traps: %d rows, %d complaints" % (n, len(bad)))
        return 1
    if fixing:
        wrote = fix(rows, drifts)
        print("traps: %d cite(s) renumbered in %s"
              % (wrote, os.path.relpath(TRAPS, ROOT)))
    cites = sum(len(r.get("cite", [])) for r in rows)
    pats = len(patterns(rows))
    print("traps: %d rows, %d cites all anchored%s, %d S1 pattern terms"
          % (n, cites,
             "" if not drifts or fixing else " (%d by a moved anchor)" % len(drifts),
             pats))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
