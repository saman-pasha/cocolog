import sys

n = int(sys.stdin.read())
solutions = []


def place(cols):
    if len(cols) == n:
        solutions.append(cols)
        return
    row = len(cols)
    for c in range(1, n + 1):
        if all(c != q and abs(c - q) != row - r for r, q in enumerate(cols)):
            place(cols + [c])


place([])
print(len(solutions))
print(" ".join(map(str, solutions[0])) if solutions else "none")
