import re
import sys
from collections import Counter

first, _, text = sys.stdin.read().partition("\n")
k = int(first)
counts = Counter(w.lower() for w in re.findall(r"[A-Za-z]+", text))
for word, n in sorted(counts.items(), key=lambda p: (-p[1], p[0]))[:k]:
    print(word, n)
