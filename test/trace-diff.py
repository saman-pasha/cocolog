"""Compare two four-port traces, SWI's and cocolog's, for test/trace.sh.

Reads the query and the two raw outputs from argv, keeps only the port
lines, and normalises what the two writers are entitled to disagree on:
the depth base (each trace's first line becomes depth 1), unbound
variable names (_438 there, _G34 here), module qualifiers on SWI's side,
and spacing inside terms. Exits 0 when the traces say the same thing,
1 with the first difference printed when they do not."""

import re
import sys

PORT = re.compile(r'^\s*\^?\s*(Call|Exit|Redo|Fail):\s*\((\d+)\)\s*(.*?)\s*$')


def ports(text):
    out = []
    for line in text.splitlines():
        m = PORT.match(line)
        if not m:
            continue
        port, depth, goal = m.group(1), int(m.group(2)), m.group(3)
        goal = re.sub(r'\b[a-z][a-zA-Z0-9_]*:', '', goal)   # lists:member
        goal = re.sub(r'_G?\d+', '_', goal)                 # _438, _G34
        goal = re.sub(r'\s+', '', goal)
        out.append((port, depth, goal))
    base = out[0][1] - 1 if out else 0
    return [(p, d - base, g) for p, d, g in out]


def main():
    query, swi_text, coco_text = sys.argv[1], sys.argv[2], sys.argv[3]
    swi, coco = ports(swi_text), ports(coco_text)
    for i in range(max(len(swi), len(coco))):
        a = swi[i] if i < len(swi) else None
        b = coco[i] if i < len(coco) else None
        if a != b:
            print("  ?- %s.   line %d differs" % (query, i + 1))
            print("    swipl  : %s" % (a and "%s: (%d) %s" % a or "<nothing>"))
            print("    cocolog: %s" % (b and "%s: (%d) %s" % b or "<nothing>"))
            return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
