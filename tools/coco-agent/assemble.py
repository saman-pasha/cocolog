"""assemble.py -- the prompt, built from the index and nothing else.

Increment 9's deterministic half: everything up to the model call. It reads
traps.jsonl, blocklist.json and the three index files and prints exactly what
would be sent, so the budget ladder can be checked without spending a token.

    python3 assemble.py "read a JSON file and count the keys"
    python3 assemble.py --show system  "..."      just the system prompt
    python3 assemble.py --sizes        "..."      the ladder, block by block

THE ROUTER HERE IS A STUB, and says so. DESIGN.md section 10 makes routing a
model call; what this does is keyword-match capabilities.json, which is the
exact-match half that file exists for (section 9.2: "not a similarity
problem"). Its verdict is a starting point a model replaces, not a decision.

ORDER IS THE ARGUMENT, and it is stated as a hypothesis rather than a finding
(DESIGN.md section 9 says so, and schedules an ablation): framing first because
it reframes everything after it; the tier inventory early because it is
reference consulted while planning; exemplars in the middle, the largest block
and the one whose position matters least; the divergence table LATE, nearest
the generation, because those are the reflexes being overridden and recency is
the cheapest lever there is; the naming law last, for the same reason.

THE BUDGET LADDER DROPS IN ONE ORDER AND NEVER TOUCHES TWO BLOCKS. Block E --
the reserved short names -- and the router verdict stay whatever else goes,
because E is the one place the model needs a BLOCKLIST rather than a
vocabulary: the temptation is to NAME a helper, not to call one.
"""

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import traps as T

ROOT = os.path.abspath(os.environ.get("COCOLOG_ROOT", os.path.join(HERE, "..", "..")))

USER_CAP = 24000          # hard cap on the user turn, DESIGN.md section 9
TOK = 4                   # chars per token, the usual rough rule; stated, not measured


def est(s):
    return (len(s) + TOK - 1) // TOK


def load(name):
    p = os.path.join(HERE, name)
    if not os.path.exists(p):
        sys.stderr.write("assemble: no %s -- run index.py and build.py first\n" % name)
        sys.exit(2)
    if name.endswith(".jsonl"):
        return [json.loads(l) for l in open(p, encoding="utf-8") if l.strip()]
    return json.load(open(p, encoding="utf-8"))


# ---- Card A, C, D, E: the fixed halves -----------------------------------

CARD_A = """You are writing cocolog, not SWI-Prolog. cocolog is a Prolog whose clauses are
rows in a database. It is close enough to SWI that your instincts will compile, and far
enough that they will be wrong. Where this card and your priors differ, this card wins.
Every row below exists because someone lost a day to it. Three of them fail SILENTLY."""

CARD_C = """HOUSE STYLE.

File shape. A %% header block first: (1) one line naming the thing, (2) tier and how to
import it, (3) the public surface as an indented signature list, (4) what it refuses to
guess, (5) honest limits. Then directives. Then code in %% ---- section ---- bands.

Comment voice. A capitalised decision clause, then the failure it prevents. Never restate
the code.

Throw rather than guess. Every writer ends with a catch-all clause that throws naming the
term. The second argument of error/2 names the PUBLIC entry point.

Codes out, codes-or-atom in. Writers answer codes (*_codes/2,3) with *_atom/2,3 as a
convenience; readers take either through a three-clause normaliser whose last clause throws.

Options are a list of one-argument terms, every one with a default, all defaults in one
place, none required.

Determinism is stated. A clause meant to be deterministic carries a cut and a comment
saying why -- but see row I1: do not add one the engine already gives you."""

CARD_D = """THE ENTRY-POINT CONTRACT.

No entry directive exists. The CLI names the goal:

    cocolog --local run FILE... main

exit 0 if and only if main proved. Do not call halt. End main with format("done~n"); the
harness requires that as the last line of stdout, because exit 0 alone is satisfied by
`main :- true.'

Every claim your program makes about itself is a must/3, and this block is repeated
VERBATIM at the foot of every file -- deliberately duplicated, so a program you copy
anywhere still runs:

    show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

    must(Label, Got, Want) :-
        (   Got == Want
        ->  format("   ~w = ~q~n", [Label, Got])
        ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
            fail
        ).

Call flush_output after any progress marker a long run prints: stdout is block-buffered
into a pipe and a killed run loses what it has not flushed."""

CARD_E = """THE NAMING LAW.

Every predicate you define is prefixed with the program's own name -- helpers, DCG
non-terminals, and main's callees included. You may CALL only: a name in the SYMBOLS block
of this request, a name you define in this file, or one of the 22 control constructs. A
gate checks this against the running binary and rejects collisions by name."""


def card_b(rows):
    """The divergence table, silent failures first: a loud failure is repaired
    by a gate for free and does not need to be in the prompt at all."""
    order = {"HARD": 0, "WARN": 1, "PROMPT": 2}
    rows = sorted(rows, key=lambda r: (order.get(r["severity"], 9), r["id"]))
    out = ["THE DIVERGENCE TABLE. SWI writes | cocolog needs | because.", ""]
    for r in rows:
        one = lambda s: " ".join(s.split())
        out.append("%-4s %s" % (r["id"], one(r["swi"])))
        out.append("     -> %s" % one(r["cocolog"]))
        out.append("        %s" % one(r["why"]))
        if r.get("empirical"):
            out.append("        MEASURED: %s" % one(r["empirical"]))
        out.append("")
    return "\n".join(out)


def short_names(bl):
    """Block E: the single-word, no-underscore tier-1 names.

    CHEAP, AND THE ONE PLACE A BLOCKLIST BEATS A VOCABULARY. Everything else in
    the prompt tells the model what it MAY call; this tells it what it may not
    NAME, because the temptation these names meet is to invent a helper called
    `step' or `insert', not to call one."""
    ks = set(bl["tier1"]["c"]) | set(bl["tier1"]["clauses"])
    short = sorted(k for k in ks
                   if "_" not in k.split("/")[0]
                   and k.split("/")[0].isalpha()
                   and len(k.split("/")[0]) > 2)
    return short


def system_prompt(traps, bl, surf):
    t1c, t1p = len(bl["tier1"]["c"]), len(bl["tier1"]["clauses"])
    inv = [
        "TIER 1 -- always present, no use_module needed, none of it optional:",
        "    apply builtins dcg files library lists zigurat",
        "    assoc pairs ordsets yall aggregate ugraphs dcg_basics dcg_high_order",
        "  %d names are dispatched in C BEFORE the knowledge base (redefining one is" % t1c,
        "  dead code); %d are clauses consulted into the same store (redefining one" % t1p,
        "  APPENDS to them). A use_module for any of these is a directive that does",
        "  nothing -- none is written anywhere in this repository.",
        "",
        "TIER 2 -- on the library path, loaded when asked:",
    ]
    for r in sorted(surf, key=lambda r: r["module"]):
        if r["tier"] != 2:
            continue
        inv.append("    library(%-6s)  %s" % (r["module"], r["documented"][0]
                                              if r["documented"] else "(header has no signature list)"))
    return "\n\n".join([
        CARD_A,
        "\n".join(inv),
        "[EXEMPLARS -- inserted per request]",
        CARD_C,
        card_b(traps),
        CARD_D,
        CARD_E,
    ])


def route(request, caps):
    """The stub router: keyword match, longest phrase first so `http request'
    beats `request'. A model replaces this; capabilities.json is the table
    either way."""
    low = request.lower()
    hits = []
    for c in caps:
        for w in sorted(c["words"], key=len, reverse=True):
            if w in low:
                hits.append((c, w))
                break
    arr = "local"
    for c, _ in hits:
        if c["arrangement"] != "local":
            arr = c["arrangement"]
            break
    libs, tags = [], []
    for c, _ in hits:
        for m in c["libraries"]:
            if m not in libs:
                libs.append(m)
        for t in c["exemplars"]:
            if t not in tags:
                tags.append(t)
    if not tags:
        tags = ["self-checking program"]
    return {"topics": [c["topic"] for c, _ in hits],
            "matched": [w for _, w in hits],
            "arrangement": arr,
            "tier2_imports": libs,
            "exemplar_tags": tags,
            "router": "STUB -- keyword match over capabilities.json, not a model verdict"}


def user_turn(request, verdict, surf, exs, bl):
    """Blocks A-F, then the ladder. Returns (text, [(block, tokens, kept)])."""
    by_tag = {r["tag"]: r for r in exs}
    by_mod = {r["module"]: r for r in surf}

    blocks = []
    blocks.append(("A. the request", "THE REQUEST, VERBATIM:\n\n" + request.strip(), True))
    blocks.append(("B. router verdict",
                   "ROUTER VERDICT:\n\n" + json.dumps(verdict, indent=1), True))

    # C. surface: the header block of each imported library, verbatim
    for m in verdict["tier2_imports"]:
        r = by_mod.get(m)
        if r:
            blocks.append(("C. surface library(%s)" % m,
                           "LIBRARY(%s) -- its own header, verbatim:\n\n%s\n\nIMPORT: %s"
                           % (m, r["header"], r["import"]), True))

    # D. symbols: the closed vocabulary
    #
    # THE FULL RESERVED TABLE IS DELIBERATELY NOT HERE. DESIGN.md section 9
    # says so outright: it is ~2k tokens the model cannot reliably apply while
    # generating, and which the gate checks perfectly. What a generator needs
    # is a VOCABULARY -- the names it may call -- and the blocklist half of the
    # job belongs to block E and to G1.
    #
    # So: every C-dispatched name (that set IS the `det' set, which is the
    # distinction that changes how code is written -- a C builtin answers once
    # and a clause backtracks), the everyday clause-defined names from the
    # tier-1 modules written in this repository, and exactly the imported
    # tier-2 libraries. The eight vendored SWI libraries are NAMED rather than
    # listed: they are SWI's own files, unmodified, and SWI's documentation of
    # them applies -- 260 rows of assoc and ugraphs internals would cost a
    # fifth of the turn to say what one sentence says.
    EVERYDAY = ("lib/builtins.cicili", "lib/lists.cicili", "lib/apply.cicili",
                "lib/dcg.cicili", "lib/files.cicili")
    sym = ["THE NAMES THAT EXIST. Anything else raises existence_error at run time.",
           "`det' means a C table entry: it answers ONCE and leaves no choice point,",
           "so a failure-driven loop over one runs the body exactly once.",
           "`nondet' means Prolog clauses: it backtracks.",
           "",
           "Also present and not listed: assoc pairs ordsets yall aggregate ugraphs",
           "dcg_basics dcg_high_order -- SWI's own files, vendored unmodified, and",
           "SWI's documentation of them applies. They need no use_module.",
           ""]
    for k in sorted(bl["tier1"]["c"]):
        if not k.startswith("$"):
            sym.append("  %-28s det" % k)
    everyday = ["THE TIER-1 LIBRARY PREDICATES. All nondet -- they are clauses, so they",
                "backtrack, which is what makes a failure-driven loop work over one and",
                "not over a C builtin.", ""]
    for k in sorted(bl["tier1"]["clauses"]):
        if k.startswith("$"):
            continue
        if any(f in EVERYDAY for f in bl["tier1"]["clauses"][k]):
            everyday.append("  %s" % k)
    for m in verdict["tier2_imports"]:
        e = bl["tier2"].get(m)
        if not e:
            continue
        for k in sorted(e["c"]):
            sym.append("  %-28s det     library(%s)" % (k, m))
        for k in sorted(e["clauses"]):
            sym.append("  %-28s nondet  library(%s)" % (k, m))
    blocks.append(("D. symbols: C table and imports", "\n".join(sym), True))
    blocks.append(("D2. symbols: tier-1 library predicates", "\n".join(everyday), True))

    # E. reserved short names -- NEVER DROPPED
    blocks.append(("E. reserved short names",
                   "RESERVED SHORT NAMES -- do not define any of these, at any arity:\n\n  "
                   + " ".join(short_names(bl)), True))

    # F. exemplars, with what they print
    for tag in verdict["exemplar_tags"][:3]:
        r = by_tag.get(tag)
        if not r:
            continue
        src = open(os.path.join(ROOT, r["path"]), encoding="utf-8", errors="replace").read()
        if r.get("start_anchor"):
            i = src.index(r["start_anchor"])
            j = src.index(r["end_anchor"]) + len(r["end_anchor"])
            src = src[i:j]
        body = "EXEMPLAR (%s) -- %s\n%s\n\n%s" % (tag, r["path"], r["why"], src)
        if r.get("recorded_stdout"):
            body += "\n\nAND THIS IS WHAT IT ACTUALLY PRINTS:\n\n" + r["recorded_stdout"]
        blocks.append(("F. exemplar %s" % tag, body, True))

    # ---- the ladder ------------------------------------------------------
    #
    # DROP ORDER: third exemplar, second exemplar, largest header block, then
    # the symbol scope trimmed to the imported libraries only. Block E and the
    # router verdict are never dropped.
    def total():
        return sum(est(b) for _, b, keep in blocks if keep)

    def drop(pred, why):
        for i, (name, body, keep) in enumerate(blocks):
            if keep and pred(name):
                blocks[i] = (name + "  [DROPPED: %s]" % why, body, False)
                return True
        return False

    # THE DESIGN'S DROP ORDER IS CORRECTED HERE, and the correction is
    # measured. It read: third exemplar, second exemplar, largest header, then
    # the symbol scope. That was written expecting block D at 0.8-2k tokens;
    # counted, the C table plus the everyday tier-1 predicates is 4.7k, and on
    # a request importing eleven libraries the whole symbol block reaches 13k.
    # Following the stated order there leaves the model ONE exemplar and a 13k
    # name dump -- the wrong half kept, because the exemplars are the only
    # grounding signal in the turn and the symbol list is what the gates check
    # perfectly. So D2, the tier-1 library predicates, goes FIRST: SWI's
    # documentation covers most of them, G1 catches a name that does not exist,
    # and losing member/2 from the vocabulary costs far less than losing a
    # whole worked file.
    #
    # Never dropped, in any order: block E and the router verdict.
    while total() > USER_CAP:
        if drop(lambda n: n.startswith("D2."),
                "the gates check names perfectly; an exemplar cannot be replaced"):
            continue
        exs_names = [n for n, _, k in blocks if n.startswith("F. exemplar") and k]
        if len(exs_names) > 2 and drop(lambda n: n == exs_names[-1], "over budget"):
            continue
        if len(exs_names) > 1 and drop(lambda n: n == exs_names[-1], "over budget"):
            continue
        surfaces = sorted([(est(b), n) for n, b, k in blocks
                           if n.startswith("C. surface") and k], reverse=True)
        if surfaces and drop(lambda n, t=surfaces[0][1]: n == t, "largest header, over budget"):
            continue
        break

    text = "\n\n" + ("\n\n" + "-" * 70 + "\n\n").join(b for _, b, k in blocks if k)
    return text, [(n, est(b), k) for n, b, k in blocks]


def over_cap(text):
    """How far over, once every rung is spent. NOT SILENT: a request that
    imports eleven libraries cannot be made to fit by dropping anything the
    ladder is allowed to drop -- the tier-2 symbol rows dominate and dropping
    those while keeping the imports would hand the model a library it may use
    and no names for it. The honest answer is to say so and let the caller
    narrow the request, which is DESIGN.md section 11's territory."""
    n = est(text)
    return max(0, n - USER_CAP)


def main(argv):
    show = None
    if "--show" in argv:
        i = argv.index("--show")
        show = argv[i + 1]
        del argv[i:i + 2]
    sizes = "--sizes" in argv
    argv = [a for a in argv if a != "--sizes"]
    # --cap is for exercising the ladder: the default is DESIGN.md's 24000 and
    # nothing on a real request should change it.
    if "--cap" in argv:
        i = argv.index("--cap")
        global USER_CAP
        USER_CAP = int(argv[i + 1])
        del argv[i:i + 2]
    req = " ".join(a for a in argv if not a.startswith("-"))
    if not req:
        sys.stderr.write('usage: assemble.py [--show system|user] [--sizes] "REQUEST"\n')
        return 2

    traps = T.load()
    bl = load("blocklist.json")
    surf = load("surface.jsonl")
    exs = load("exemplars.jsonl")
    caps = load("capabilities.json")

    verdict = route(req, caps)
    sysp = system_prompt(traps, bl, surf)
    usr, parts = user_turn(req, verdict, surf, exs, bl)

    if show == "system":
        print(sysp)
        return 0
    if show == "user":
        print(usr)
        return 0

    print("request : %s" % req)
    print("router  : %s | %s | imports %s | exemplars %s"
          % (verdict["router"].split(" --")[0], verdict["arrangement"],
             verdict["tier2_imports"] or "none", verdict["exemplar_tags"]))
    print("          topics matched: %s" % (", ".join(verdict["topics"]) or "none"))
    print()
    print("system  : ~%d tokens" % est(sysp))
    if sizes:
        for name, n, keep in parts:
            print("  %-40s ~%5d %s" % (name, n, "" if keep else "(dropped)"))
    print("user    : ~%d tokens of a %d cap" % (est(usr), USER_CAP))
    if over_cap(usr):
        print("          OVER CAP by ~%d tokens with every rung spent. The tier-2"
              % over_cap(usr))
        print("          symbol rows dominate; narrow the request or split it.")
    print("total   : ~%d tokens per request" % (est(sysp) + est(usr)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
