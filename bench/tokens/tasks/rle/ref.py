import re
import sys

for line in sys.stdin.read().splitlines():
    op, text = line.split(" ", 1)
    if op == "E":
        print("".join(f"{len(m.group(0))}{m.group(1)}" for m in re.finditer(r"(.)\1*", text)))
    else:
        print("".join(c * int(n) for n, c in re.findall(r"(\d+)(\D)", text)))
