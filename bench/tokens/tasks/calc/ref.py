import re
import sys


class Bad(Exception):
    pass


def evaluate(line):
    if re.search(r"[^0-9+\-*/() ]", line):
        raise Bad
    toks = re.findall(r"\d+|[-+*/()]", line)
    pos = 0

    def peek():
        return toks[pos] if pos < len(toks) else None

    def take():
        nonlocal pos
        if pos == len(toks):
            raise Bad
        pos += 1
        return toks[pos - 1]

    def expr():
        v = term()
        while peek() in ("+", "-"):
            v = v + term() if take() == "+" else v - term()
        return v

    def term():
        v = unary()
        while peek() in ("*", "/"):
            op, r = take(), unary()
            if op == "*":
                v *= r
            elif r == 0:
                raise Bad
            else:
                q = abs(v) // abs(r)
                v = q if (v < 0) == (r < 0) else -q
        return v

    def unary():
        if peek() == "-":
            take()
            return -unary()
        t = take()
        if t == "(":
            v = expr()
            if take() != ")":
                raise Bad
            return v
        if t.isdigit():
            return int(t)
        raise Bad

    v = expr()
    if pos != len(toks):
        raise Bad
    return v


for line in sys.stdin.read().splitlines():
    try:
        print(evaluate(line))
    except Bad:
        print("error")
