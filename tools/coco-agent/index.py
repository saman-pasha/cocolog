"""index.py -- the three retrieval files, built from the repository itself.

Increment 5 of library/llm/DESIGN.md section 13. Nothing here is written by
hand except capabilities.json's twenty topic rows, and the builder validates
every path and every anchor those name.

    python3 index.py                 build all three, report
    python3 index.py --check         validate without writing
    python3 index.py --no-run        skip recording exemplar stdout

  surface.jsonl     one row per library: its own %% header block, verbatim,
                    plus the name/arity it DOCUMENTS
  exemplars.jsonl   whole files and anchored spans, with what they print
  capabilities.json the topic table, every path in it checked

A HEADER BLOCK IS THE ONLY AUTHORITY ON WHAT A LIBRARY OFFERS. library/json.pl
has seventy clause heads and documents ten; a clause-head listing would offer
json_hex4/3 as API, and a model handed that will call it. So the surface is
what the file says about itself -- the leading %% block, and every `%% name(...)'
doc line whose name the file actually defines. That last condition matters:
without it, prose naming split_string/4 as a thing cocolog does NOT have would
enter the index as a thing it does.

EXEMPLARS ARE ANCHORED BY SUBSTRING, NEVER BY LINE. A line-range citation rots
faster than a file citation, and silently: the span still resolves, it just
teaches half a predicate. Each anchor must match EXACTLY ONCE or the build
fails, which is eight lines of code against a prompt that quietly goes wrong
after an unrelated edit.

AND THEY ARE RUN. Each runnable exemplar carries the stdout `cocolog --local
run FILE main' actually produced, recorded at index time. It is the only
grounding signal in the repository a stale comment cannot corrupt: the model
sees behaviour, not just appearance. Free, because test/tutorials.sh already
runs all 47.
"""

import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import clauses as R

ROOT = os.path.abspath(os.environ.get("COCOLOG_ROOT", os.path.join(HERE, "..", "..")))
BIN = os.environ.get("COCOLOG_BIN", os.path.join(ROOT, "cocolog"))

# Tier 1 is compiled in or preloaded and needs no import; tier 2 sits on the
# library path. The distinction is the WHEN axis the linter uses too.
TIER1_PL = "lib/swipl"
TIER2_PL = "library"

# `%%   name(+A, -B)' or `%%   name//1' or `%%   name/3', at any indent. The
# name must be one the file DEFINES, or prose about a predicate that does not
# exist here would enter the index as one that does.
DOC = re.compile(r"^%%\s+'?([a-z_$][A-Za-z0-9_]*)'?\s*(?:/(\d+)|//(\d+)|\(([^)]*)\))")


def header_block(src):
    """The leading run of %% lines: the file's own account of itself. Ends at
    the first line that is not a %% comment, blank lines inside it kept."""
    out = []
    for line in src.split("\n"):
        if line.startswith("%%"):
            out.append(line)
        elif not line.strip() and out:
            out.append(line)
        else:
            break
    while out and not out[-1].strip():
        out.pop()
    return "\n".join(out)


def documented(path, src):
    """name/arity this file documents, cross-checked against what it defines."""
    heads = set(R.heads(path))
    found = {}
    for line in src.split("\n"):
        m = DOC.match(line.rstrip())
        if not m:
            continue
        nm = m.group(1)
        if m.group(2):
            ars = [int(m.group(2))]
        elif m.group(3):
            ars = [int(m.group(3)) + 2]          # a DCG head occupies arity+2
        else:
            ars = [R._arity(m.group(4))]
        for ar in ars:
            k = "%s/%d" % (nm, ar)
            if k in heads:
                found[k] = True
    return sorted(found)


def surface():
    rows = []
    for tier, d in ((2, TIER2_PL), (1, TIER1_PL)):
        full = os.path.join(ROOT, d)
        if not os.path.isdir(full):
            continue
        for name in sorted(os.listdir(full)):
            if not name.endswith(".pl"):
                continue
            rel = os.path.join(d, name)
            p = os.path.join(ROOT, rel)
            src = open(p, encoding="utf-8", errors="replace").read()
            h = header_block(src)
            rows.append({
                "path": rel,
                "module": name[:-3],
                "tier": tier,
                "import": None if tier == 1 else ":- use_module(library(%s))." % name[:-3],
                "header": h,
                "header_bytes": len(h),
                "documented": documented(p, src),
                "heads": len(set(R.heads(p))),
            })
    return rows


# ---- the exemplars, by capability tag ------------------------------------
#
# Seven rows, from DESIGN.md section 9.1. A row with no span is the WHOLE file:
# for a template, half a file is worse than none, because what is being taught
# is the shape.
EXEMPLARS = [
    {"tag": "self-checking program", "path": "tutorials/basics/01-facts-and-rules.pl",
     "why": "the template for most requests: header, sections, main walking claims, "
            "the two helpers repeated at the foot"},
    {"tag": "assert/retract", "path": "tutorials/basics/07-assert-and-retract.pl",
     "why": "the correct retract recursion, and it COUNTS the removals -- the "
            "failure-driven loop it shows first removes exactly one clause"},
    {"tag": "grammar", "path": "tutorials/basics/10-grammars.pl",
     "why": "a DCG over codes, 0'0 character literals, { } placement"},
    {"tag": "tier-2 library", "path": "library/astar.pl",
     "why": "the shortest complete library in the tree -- the full header template "
            "plus the callback idiom. Shipped WITH its own two defects named (a "
            "no-op tier-1 use_module at line 41, and two unprefixed helpers): "
            "showing a real file and what is wrong with it beats a sanitised one"},
    {"tag": "parser: dispatch", "path": "library/json.pl",
     "start_anchor": "json_emit(V, _, _) --> { var(V) }",
     "end_anchor": "json_raw([C|Cs]) --> [C], json_raw(Cs).",
     "why": "ordered-clause DCG dispatch, the var/1 guard first, the type_error "
            "catch-all last, and the bound-code-list-is-a-call rule that nothing "
            "in an SWI corpus teaches"},
    {"tag": "cross-process", "path": "tutorials/library/34-kbs.pl",
     "why": "goals as terms, marker-line verdicts, the honest-skip idiom"},
    {"tag": "bulk KB write", "path": "coworker/balancer/worker.pl",
     "why": "chunk, then the completion mark, in one turn; every clause ends in a "
            "cut because consult appends"},
]


def resolve(row, src, path):
    """Anchors to offsets. EXACTLY ONCE or the build fails -- an anchor that
    matches twice is a span nobody chose, and one that matches none is a span
    that has moved."""
    bad = []
    a = row.get("start_anchor")
    b = row.get("end_anchor")
    if a is None and b is None:
        return 0, len(src), bad
    for which, anc in (("start_anchor", a), ("end_anchor", b)):
        if anc is None:
            bad.append("%s: %s missing (a span needs both)" % (path, which))
            continue
        n = src.count(anc)
        if n != 1:
            bad.append("%s: %s matches %d times, needs exactly 1: %r"
                       % (path, which, n, anc))
    if bad:
        return None, None, bad
    i = src.index(a)
    j = src.index(b) + len(b)
    if j <= i:
        bad.append("%s: end_anchor is before start_anchor" % path)
        return None, None, bad
    return i, j, bad


def record_stdout(path):
    """What `cocolog --local run FILE main' prints. None when the file has no
    main/0 -- a library is exercised by its tutorial, not by itself."""
    p = os.path.join(ROOT, path)
    if "main/0" not in set(R.heads(p)):
        return None, "no main/0: a library is run by its tutorial, not by itself"
    if not os.path.exists(BIN):
        return None, "no binary at %s" % os.path.relpath(BIN, ROOT)
    env = dict(os.environ)
    env["COCOLOG_LIBRARY"] = os.path.join(ROOT, "library") + ":" + env.get("COCOLOG_LIBRARY", "")
    try:
        r = subprocess.run([BIN, "--local", "run", p, "main"], cwd=ROOT, env=env,
                           capture_output=True, timeout=120)
    except Exception as e:
        return None, "did not run: %s" % e
    if r.returncode != 0:
        return None, "exit %d: %s" % (r.returncode, r.stderr.decode("utf-8", "replace").strip()[:200])
    return r.stdout.decode("utf-8", "replace"), None


def exemplars(run=True):
    rows, bad = [], []
    for row in EXEMPLARS:
        p = os.path.join(ROOT, row["path"])
        if not os.path.exists(p):
            bad.append("%s: does not exist" % row["path"])
            continue
        src = open(p, encoding="utf-8", errors="replace").read()
        i, j, b = resolve(row, src, row["path"])
        bad += b
        if i is None:
            continue
        out = dict(row)
        out["bytes"] = j - i
        out["whole_file"] = "start_anchor" not in row
        if run:
            got, why = record_stdout(row["path"])
            out["recorded_stdout"] = got
            out["recorded_stdout_absent"] = why
        rows.append(out)
    return rows, bad


# ---- the topic table -----------------------------------------------------
#
# HAND-WRITTEN AND VALIDATED, which is the whole of section 9.2's argument
# against embeddings: what retrieval would serve here is an exact-match problem
# over a few dozen documents with one hand-labelled topic each, not a
# similarity problem. Twenty rows fit on a page and every path is checked.
CAPABILITIES = [
    {"topic": "JSON", "words": ["json", "serialise", "serialize", "api payload"],
     "libraries": ["json"], "exemplars": ["parser: dispatch"], "arrangement": "local"},
    {"topic": "XML or HTML", "words": ["xml", "html", "markup", "scrape", "css", "stylesheet"],
     "libraries": ["xml", "html"], "exemplars": ["parser: dispatch"], "arrangement": "local"},
    {"topic": "an HTTP client", "words": ["fetch", "http request", "download", "rest", "curl"],
     "libraries": ["http", "curl"], "exemplars": ["tier-2 library"], "arrangement": "local"},
    {"topic": "an HTTP server", "words": ["serve", "web server", "endpoint", "route", "page"],
     "libraries": ["httpd", "html"], "exemplars": ["tier-2 library"], "arrangement": "local"},
    {"topic": "TLS or certificates", "words": ["tls", "https", "certificate", "ca", "x509", "sign"],
     "libraries": ["x509", "ca", "tls", "der", "sha"], "exemplars": ["tier-2 library"],
     "arrangement": "local"},
    {"topic": "hashing or ciphers", "words": ["sha", "hash", "hmac", "aes", "encrypt"],
     "libraries": ["sha", "aes"], "exemplars": ["tier-2 library"], "arrangement": "local"},
    {"topic": "sockets", "words": ["socket", "tcp", "listen", "connect", "port"],
     "libraries": ["tcp"], "exemplars": ["tier-2 library"], "arrangement": "local"},
    {"topic": "threads", "words": ["thread", "concurrent", "worker", "parallel", "channel"],
     "libraries": ["thread"], "exemplars": ["bulk KB write"], "arrangement": "local"},
    {"topic": "processes", "words": ["subprocess", "spawn", "exec", "shell out"],
     "libraries": ["process"], "exemplars": ["tier-2 library"], "arrangement": "local"},
    {"topic": "the knowledge base", "words": ["knowledge base", "database", "persist", "store",
                                              "across processes", "shared"],
     "libraries": ["kbs"], "exemplars": ["cross-process", "bulk KB write"], "arrangement": "kb"},
    {"topic": "an embedded store", "words": ["embedded", "single file", "no server", "local store"],
     "libraries": [], "exemplars": ["bulk KB write"], "arrangement": "embed"},
    {"topic": "a grammar or parser", "words": ["parse", "grammar", "dcg", "tokenize", "lexer"],
     "libraries": [], "exemplars": ["grammar", "parser: dispatch"], "arrangement": "local"},
    {"topic": "search or pathfinding", "words": ["shortest path", "a*", "astar", "route",
                                                 "search", "graph"],
     "libraries": ["astar"], "exemplars": ["tier-2 library"], "arrangement": "local"},
    {"topic": "hex grids", "words": ["hex", "hexagonal", "tile", "map"],
     "libraries": ["hex"], "exemplars": ["tier-2 library"], "arrangement": "local"},
    {"topic": "big integers", "words": ["bignum", "big integer", "arbitrary precision", "rsa"],
     "libraries": ["bigint"], "exemplars": ["tier-2 library"], "arrangement": "local"},
    {"topic": "tensors or a model", "words": ["tensor", "neural", "train", "torch", "model"],
     "libraries": ["torch"], "exemplars": ["self-checking program"], "arrangement": "local"},
    {"topic": "a language model", "words": ["llm", "chat", "prompt", "completion", "openai",
                                            "anthropic"],
     "libraries": ["llm", "curl", "json"], "exemplars": ["tier-2 library"], "arrangement": "local"},
    {"topic": "files and paths", "words": ["file", "directory", "path", "read a file"],
     "libraries": [], "exemplars": ["self-checking program"], "arrangement": "local"},
    {"topic": "text and atoms", "words": ["string", "text", "atom", "split", "join", "case"],
     "libraries": ["text"], "exemplars": ["self-checking program"], "arrangement": "local"},
    {"topic": "the operating system", "words": ["platform", "which os", "cpus", "temp dir",
                                                "environment"],
     "libraries": ["os"], "exemplars": ["self-checking program"], "arrangement": "local"},
    {"topic": "assert and retract", "words": ["assert", "retract", "remember", "counter",
                                              "mutable"],
     "libraries": [], "exemplars": ["assert/retract"], "arrangement": "local"},
]


def check_capabilities(surf, exs):
    """Every library named must have a surface row; every exemplar tag must
    exist. A topic table that names a library nobody ships is a prompt that
    tells the model to import something that is not there."""
    bad = []
    mods = {r["module"] for r in surf}
    # tier-2 C modules have no .pl, so they are named by directory instead
    for d in ("modules",):
        full = os.path.join(ROOT, d)
        if os.path.isdir(full):
            mods |= {n for n in os.listdir(full)
                     if os.path.isdir(os.path.join(full, n))}
    tags = {r["tag"] for r in exs}
    seen = set()
    for c in CAPABILITIES:
        if c["topic"] in seen:
            bad.append("capabilities: duplicate topic %r" % c["topic"])
        seen.add(c["topic"])
        for m in c["libraries"]:
            if m not in mods:
                bad.append("capabilities: %r names library(%s), which does not ship"
                           % (c["topic"], m))
        for t in c["exemplars"]:
            if t not in tags:
                bad.append("capabilities: %r names exemplar tag %r, which is not one"
                           % (c["topic"], t))
        if c["arrangement"] not in ("local", "kb", "embed", "http"):
            bad.append("capabilities: %r names arrangement %r"
                       % (c["topic"], c["arrangement"]))
    return bad


def thin_surface(surf):
    """Tier-2 libraries whose header documents almost nothing.

    NOT A BUILD FAILURE, A REPORT. CLAUDE.md's house style asks a header for
    "the public surface as an indented signature list", and where one is
    missing the index cannot invent it -- so the honest thing is to say which
    library will be under-served rather than to quietly serve one name. As of
    writing that is library(kbs), whose header explains the design at length
    and names its predicates only inside running prose."""
    return [r for r in surf if r["tier"] == 2 and len(r["documented"]) <= 1]


def main(argv):
    run = "--no-run" in argv
    surf = surface()
    exs, bad = exemplars(run=not run)
    bad += check_capabilities(surf, exs)

    for b in bad:
        print("index: " + b)
    if bad:
        return 1

    if "--check" not in argv:
        with open(os.path.join(HERE, "surface.jsonl"), "w", encoding="utf-8") as f:
            for r in surf:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")
        with open(os.path.join(HERE, "exemplars.jsonl"), "w", encoding="utf-8") as f:
            for r in exs:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")
        with open(os.path.join(HERE, "capabilities.json"), "w", encoding="utf-8") as f:
            json.dump(CAPABILITIES, f, indent=1, ensure_ascii=False)

    t2 = [r for r in surf if r["tier"] == 2]
    hdr = sum(r["header_bytes"] for r in t2)
    doc = sum(len(r["documented"]) for r in t2)
    hds = sum(r["heads"] for r in t2)
    ran = sum(1 for r in exs if r.get("recorded_stdout"))
    print("surface : %d tier-2 libraries, %d KB of header, %d documented of %d heads"
          % (len(t2), hdr // 1024, doc, hds))
    print("          %d tier-1 vendored libraries" % (len(surf) - len(t2)))
    print("exemplar: %d rows, %d with recorded stdout, all anchors matched once"
          % (len(exs), ran))
    print("capabil.: %d topics, every library and tag checked" % len(CAPABILITIES))
    for r in thin_surface(t2):
        print("thin    : library(%s) documents %d of %d heads -- its header has no "
              "signature list, so the index cannot offer a surface for it"
              % (r["module"], len(r["documented"]), r["heads"]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
