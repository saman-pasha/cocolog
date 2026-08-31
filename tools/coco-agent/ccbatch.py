"""The clause reader, backed by clauses.pl instead of by Python.

WHY THIS EXISTS. clauses.pl is the only clause reader now, and it is a cocolog
process -- so the Python tools that still need one (build.py and index.py) have
to talk to it. A subprocess per call is 6ms and they make 615 calls, which
measured 3.7 seconds against the 0.19 the old in-process reader took. So this
batches: every document is handed over in ONE length-prefixed file and the
answers come back in one go.

    import ccbatch as R
    R.prime([...])          optional: one process for a known workload
    R.read_file(path)       -> (src, [Clause])
    R.heads(path)           -> {"name/arity", ...}
    R.split_clauses(src)    -> [Clause]
    R.read_head(clause)     -> clause, already read
    R._arity(argtext)       -> int

PRIMING IS AN OPTIMISATION AND NOTHING ELSE. Every entry point works without
it, falling back to a batch of one, so a caller that forgets to prime is slow
and never wrong. That is deliberate: the alternative -- a cache that must be
filled before it is correct -- fails silently the first time somebody adds a
call site.

BYTES, NOT CHARACTERS. cocolog reads bytes and reports byte offsets, because
that is what the interpreter's own `syntax error at offset %lu' counts. This
decodes latin-1 so one byte is one character and a Python slice at a cocolog
offset lands where cocolog said. A file with non-ASCII in it would therefore
get byte columns, which is exactly what cocolog's own error messages give.
"""

import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.environ.get("COCOLOG_ROOT", os.path.join(HERE, "..", "..")))
BIN = os.environ.get("COCOLOG_BIN", os.path.join(ROOT, "cocolog"))

# How many documents went to cocolog, and in how many processes. Printed by
# build.py so a regression in batching is visible rather than merely slow.
STATS = {"documents": 0, "processes": 0, "cached": 0}


class Clause:
    """A clause, as build.py and index.py expect one. `text' is a slice of the
    document it came from."""

    __slots__ = ("text", "offset", "line", "col", "name", "arity", "is_dcg",
                 "is_directive", "directive")

    def __init__(self, text, offset, line, col):
        self.text = text
        self.offset = offset
        self.line = line
        self.col = col
        self.name = None
        self.arity = None
        self.is_dcg = False
        self.is_directive = False
        self.directive = None

    def key(self):
        return None if self.name is None else "%s/%d" % (self.name, self.arity)

    def __repr__(self):
        return "Clause(%s at %d:%d)" % (self.key(), self.line, self.col)


_cache = {}


def _run(texts):
    """One cocolog process for a list of documents. Answers a list of clause
    lists, in the same order."""
    if not texts:
        return []
    if not os.path.exists(BIN):
        raise RuntimeError("ccbatch: no cocolog binary at %s -- it is the "
                           "clause reader now" % BIN)
    blob = b"".join(b"%d\n%s" % (len(t.encode("latin-1")), t.encode("latin-1"))
                    for t in texts)
    import tempfile
    fd, path = tempfile.mkstemp(prefix="ccbatch-")
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(blob)
        env = dict(os.environ)
        env["COCO_CC_BATCH"] = path
        env["COCOLOG_LIBRARY"] = os.path.join(ROOT, "library") + ":" + \
            env.get("COCOLOG_LIBRARY", "")
        r = subprocess.run([BIN, "--local", "run",
                            os.path.join(HERE, "clauses.pl"), "cc_batch"],
                           cwd=ROOT, env=env, capture_output=True)
    finally:
        os.unlink(path)
    if r.returncode != 0:
        raise RuntimeError("ccbatch: clauses.pl failed (exit %d): %s"
                           % (r.returncode,
                              r.stderr.decode("utf-8", "replace").strip()[:300]))
    STATS["documents"] += len(texts)
    STATS["processes"] += 1
    return _parse(r.stdout.decode("latin-1"), texts)


def _parse(out, texts):
    """`=<i>' opens a document; every row after it is one clause."""
    per = [[] for _ in texts]
    cur = None
    for line in out.split("\n"):
        if not line:
            continue
        if line[0] == "=":
            cur = int(line[1:])
            continue
        if cur is None:
            raise RuntimeError("ccbatch: a clause row before any document marker")
        f = line.split("\t")
        if len(f) != 7:
            raise RuntimeError("ccbatch: malformed row %r" % line)
        off, ln, col, length, name, arity, kind = f
        off, ln, col, length = int(off), int(ln), int(col), int(length)
        c = Clause(texts[cur][off:off + length], off, ln, col)
        if kind.startswith("directive"):
            c.is_directive = True
            if kind != "directive":
                inner = kind[len("directive("):-1]
                dn, _, da = inner.rpartition(",")
                c.directive = (dn, int(da))
        elif arity != "-1":
            c.is_dcg = (kind == "dcg")
            c.name = name
            c.arity = int(arity)
        # `-' AND -1 ARE THE WIRE'S SPELLING OF nohead. Read back as a name
        # they would make key() answer `-/-1' and put two phantom entries in
        # the blocklist -- aggregate.pl and yall.pl each have one clause whose
        # head this reader declines to read.
        per[cur].append(c)
    # A DOCUMENT THAT PRODUCED NO MARKER IS A PROTOCOL FAILURE, not an empty
    # file: cc_batch emits `=<i>' for every document including an empty one, so
    # a missing marker means the framing slipped and the answers after it
    # belong to the wrong document.
    seen = out.count("\n=") + (1 if out.startswith("=") else 0)
    if seen != len(texts):
        raise RuntimeError("ccbatch: sent %d documents, got %d markers"
                           % (len(texts), seen))
    return per


def prime(texts):
    """Read every one of TEXTS in a single process, into the cache."""
    want = []
    seen = set()
    for t in texts:
        if t not in _cache and t not in seen:
            seen.add(t)
            want.append(t)
    for t, cs in zip(want, _run(want)):
        _cache[t] = cs


def split_clauses(src):
    if src in _cache:
        STATS["cached"] += 1
        return _cache[src]
    _cache[src] = _run([src])[0]
    return _cache[src]


def read_head(cl):
    """A no-op: the head was read on the cocolog side. Kept so a call site can
    use either reader unchanged."""
    return cl


def read_source(path):
    """The file as latin-1, so a slice at a cocolog byte offset is that byte."""
    with open(path, "rb") as f:
        return f.read().decode("latin-1")


def read_file(path):
    src = read_source(path)
    return src, split_clauses(src)


def heads(path):
    _, cls = read_file(path)
    return {c.key() for c in cls if c.key() and not c.is_directive}


def _arity(argtext):
    """The arity of an argument list, by asking the reader what `p(...)' is.

    ROUTED THROUGH THE SAME GRAMMAR rather than reimplemented, because a second
    comma counter that disagrees about a 0'c literal or a quoted atom is
    exactly the bug this whole rewrite removed -- and that one really happened. index.py calls it about ninety
    times per run and every one is a cache hit after priming."""
    if not argtext.strip():
        return 0
    doc = "p(" + argtext + ")."
    cs = split_clauses(doc)
    if not cs or cs[0].arity is None:
        return 0
    return cs[0].arity


def arity_doc(argtext):
    """The document _arity would send, so a caller can prime it."""
    return "p(" + argtext + ")." if argtext.strip() else None
