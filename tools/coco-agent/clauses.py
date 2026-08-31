"""A clause reader for cocolog source.

WHY NOT A REGEX. On lib/swipl/dcg_basics.pl a regex over clause heads answers
digit/1, digits/1, string/1, blank/0; what the store actually holds is digit/3,
digits/3, string/3, blank/2, because a DCG head occupies arity+2. A regex
blocklist is therefore under-broad IN EXACTLY THE ARITY THAT COLLIDES -- it
blocks a name nothing defines and lets the real one through. And without
stripping comment regions, yall.pl's `/** <module> */' header contributes a
bogus call/1..4, atom_concat/3 and maplist/3, and aggregate.pl's contributes
smallest_country/2.

This is not a full term parser. It splits a file into clauses and reads each
one's HEAD -- which is all the linter needs -- and it is careful about exactly
the four things that make that hard in Prolog: quoted atoms with doubled and
backslash escapes, 0'c character literals, comment regions, and nested
argument lists.
"""

import re

# The escapes cocolog's reader knows (lib/syntax.cicili:623-634). Anything
# else inside a quoted atom is a syntax error refusing the whole file.
KNOWN_ESCAPES = set("ntrabfv0\\'\"")


class Clause:
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
        self.directive = None      # (name, arity) of the directive's argument

    def key(self):
        return None if self.name is None else "%s/%d" % (self.name, self.arity)

    def __repr__(self):
        return "Clause(%s at %d:%d)" % (self.key(), self.line, self.col)


def _line_col(src, offset):
    """The interpreter only ever reports a BYTE OFFSET -- `syntax error at
    offset %lu' (lib/syntax.cicili:589) -- and there are no line numbers
    anywhere in the pipeline. Every finding converts here so a human gets
    file:line:col."""
    line = src.count("\n", 0, offset) + 1
    nl = src.rfind("\n", 0, offset)
    col = offset - nl if nl >= 0 else offset + 1
    return line, col


def split_clauses(src):
    """Every clause in SRC, with its offset. A clause ends at a `.' that is at
    depth 0, outside any quote, and followed by whitespace or end of input --
    which is the same rule the reader uses."""
    out = []
    i, n = 0, len(src)
    depth = 0
    start = None
    inq = None
    while i < n:
        c = src[i]

        if inq:
            if c == "\\" and i + 1 < n:
                i += 2
                continue
            if c == inq:
                if i + 1 < n and src[i + 1] == inq:   # '' is a quote, not an end
                    i += 2
                    continue
                inq = None
            i += 1
            continue

        # 0'c is a character literal: the quote is not a quote. 0'' and 0'\n
        # are the two that catch people (emacs/cocolog-mode.el says so too).
        if c == "0" and i + 1 < n and src[i + 1] == "'":
            if i + 2 < n and src[i + 2] == "'":
                i += 4 if (i + 3 < n and src[i + 3] == "'") else 3
            elif i + 2 < n and src[i + 2] == "\\":
                i += 4
            else:
                i += 3
            continue

        if c == "%":
            while i < n and src[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue

        if c in "'\"`":
            if start is None:
                start = i
            inq = c
            i += 1
            continue

        if not c.isspace() and start is None:
            start = i

        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "." and depth == 0:
            nxt = src[i + 1] if i + 1 < n else "\n"
            # A `.' ends a clause when whitespace or end-of-input follows, and
            # THAT TEST IS SUFFICIENT. An earlier version also required the
            # preceding character not to be a digit, meaning to skip the `.' in
            # 3.14 -- but that `.' is followed by a DIGIT and is already
            # excluded. What the extra guard actually did was refuse to end
            # `:- table foo/2.' and `:- dynamic p/1.', silently swallowing the
            # clause that followed and dropping its head from the blocklist.
            if nxt in " \t\r\n" and start is not None:
                line, col = _line_col(src, start)
                out.append(Clause(src[start:i + 1], start, line, col))
                start = None
        i += 1

    if start is not None and src[start:].strip():
        line, col = _line_col(src, start)
        out.append(Clause(src[start:], start, line, col))
    return out


def _arity(argtext):
    """Top-level commas in an argument list, counting nesting and quotes."""
    if not argtext.strip():
        return 0
    depth = 0
    n = 1
    inq = None
    i = 0
    while i < len(argtext):
        c = argtext[i]
        if inq:
            if c == "\\":
                i += 2
                continue
            if c == inq:
                if i + 1 < len(argtext) and argtext[i + 1] == inq:
                    i += 2
                    continue
                inq = None
            i += 1
            continue
        if c == "0" and i + 1 < len(argtext) and argtext[i + 1] == "'":
            i += 3
            continue
        if c in "'\"`":
            inq = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "," and depth == 0:
            n += 1
        i += 1
    return n


_NAME = re.compile(r"\s*(?::-\s*)?('(?:[^']|'')*'|[a-z][a-zA-Z0-9_]*)")


def read_head(cl):
    """Fill in name, arity, is_dcg, is_directive on CL."""
    text = cl.text
    body = text.lstrip()

    if body.startswith(":-") or body.startswith("?-"):
        cl.is_directive = True
        inner = body[2:].lstrip()
        m = _NAME.match(inner)
        if m:
            nm = m.group(1)
            rest = inner[m.end():]
            if rest.startswith("("):
                args, _ = _balanced(rest)
                cl.directive = (nm.strip("'"), _arity(args))
            else:
                # A PREFIX OPERATOR TAKES ITS ARGUMENT WITHOUT PARENTHESES.
                # `:- dynamic seen/1.' is dynamic/1; reading it as dynamic/0
                # made the linter reject eight files in its own calibration
                # corpus, every one of them correct.
                tail = rest.strip()
                if tail.endswith("."):
                    tail = tail[:-1]
                cl.directive = (nm.strip("'"), 1 if tail.strip() else 0)
        return cl

    m = _NAME.match(text)
    if not m:
        return cl
    name = m.group(1).strip("'")
    rest = text[m.end():]

    if rest.startswith("("):
        args, after = _balanced(rest)
        arity = _arity(args)
    else:
        arity, after = 0, rest

    # A DCG head occupies arity+2 in the store (lib/dcg.cicili:96-127
    # appends S0 and S). This is the whole reason for a reader.
    stripped = after.lstrip()
    if stripped.startswith("-->"):
        cl.is_dcg = True
        arity += 2
    elif stripped.startswith(",") and "-->" in after[:200]:
        # a pushback head: h, [x] --> ... is still a DCG head
        cl.is_dcg = True
        arity += 2

    cl.name, cl.arity = name, arity
    return cl


def _balanced(s):
    """S starts with `('. Answer the inside and what follows the match."""
    depth = 0
    inq = None
    i = 0
    while i < len(s):
        c = s[i]
        if inq:
            if c == "\\":
                i += 2
                continue
            if c == inq:
                if i + 1 < len(s) and s[i + 1] == inq:
                    i += 2
                    continue
                inq = None
            i += 1
            continue
        if c == "0" and i + 1 < len(s) and s[i + 1] == "'":
            i += 3
            continue
        if c in "'\"`":
            inq = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
            if depth == 0:
                return s[1:i], s[i + 1:]
        i += 1
    return s[1:], ""


def read_file(path):
    src = open(path, encoding="utf-8", errors="replace").read()
    return src, [read_head(c) for c in split_clauses(src)]


def heads(path):
    """The set of name/arity this file DEFINES (directives excluded)."""
    _, cls = read_file(path)
    return {c.key() for c in cls if c.key() and not c.is_directive}


def lexical_regions(src):
    """Byte ranges of SRC that are not plain code, as a sorted list of
    (start, end, kind) triples with kind "quote" or "comment".

    S1 IS A TEXTUAL RULE AND MOST OF ITS PATTERNS MEAN CODE, so it needs to know
    what is not code. Without this, `format("the classic `retract(X), fail'
    loop...")' -- a tutorial explaining the trap -- is reported as the trap, and
    a corpus of documentation lights up with findings about its own prose.

    THE KIND MATTERS, which is why they are not one list. Two rules -- F1's
    format column directives and E1's escapes -- live INSIDE a quote by
    construction, so they are marked `scan: text' and read quotes as code. But
    nothing is ever a finding inside a COMMENT: a comment naming `~t' is
    documentation of the rule, not a violation of it, and both of this repo's
    own files that name these forms name them in `%%' headers.

    Same lexical rules as split_clauses -- the doubled quote, the 0'c literal,
    `%' to end of line, /* */ -- because two scanners that disagree about where
    a string ends is exactly the bug this is meant to prevent.
    """
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == "0" and i + 1 < n and src[i + 1] == "'":
            if i + 2 < n and src[i + 2] == "'":
                j = i + (4 if (i + 3 < n and src[i + 3] == "'") else 3)
            elif i + 2 < n and src[i + 2] == "\\":
                j = i + 4
            else:
                j = i + 3
            out.append((i, min(j, n), "quote"))
            i = j
            continue
        if c == "%":
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append((i, j, "comment"))
            i = j
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append((i, j, "comment"))
            i = j
            continue
        if c in "'\"`":
            j = i + 1
            while j < n:
                if src[j] == "\\" and j + 1 < n:
                    j += 2
                    continue
                if src[j] == c:
                    if j + 1 < n and src[j + 1] == c:
                        j += 2
                        continue
                    j += 1
                    break
                j += 1
            out.append((i, min(j, n), "quote"))
            i = j
            continue
        i += 1
    return out


def in_region(regions, pos, kinds=("quote", "comment")):
    """Is byte POS inside a region of one of KINDS? Linear, because a .pl file
    is small and a bisect here would be the kind of cleverness that hides an
    off-by-one."""
    for a, b, kind in regions:
        if a <= pos < b:
            return kind in kinds
        if a > pos:
            return False
    return False
