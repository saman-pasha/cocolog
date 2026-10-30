import json
import sys


def total(x):
    if isinstance(x, bool):
        return 0
    if isinstance(x, int):
        return x
    if isinstance(x, list):
        return sum(map(total, x))
    if isinstance(x, dict):
        return sum(map(total, x.values()))
    return 0


print(total(json.load(sys.stdin)))
