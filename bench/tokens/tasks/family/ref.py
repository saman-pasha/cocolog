import sys

parents = {}
children = {}


def parents_of(x):
    return parents.get(x, set())


def closure(x, step):
    seen, todo = set(), [x]
    while todo:
        for y in step.get(todo.pop(), ()):
            if y not in seen:
                seen.add(y)
                todo.append(y)
    return seen


def siblings(x):
    return {y for p in parents_of(x) for y in children[p] if y != x}


def cousins(x):
    sib = siblings(x)
    return {y for p in parents_of(x) for s in siblings(p) for y in children.get(s, ())
            if y != x and y not in sib}


for line in sys.stdin.read().splitlines():
    words = line.split()
    if words[0] == "parent":
        parents.setdefault(words[2], set()).add(words[1])
        children.setdefault(words[1], set()).add(words[2])
        continue
    kind, x = words
    if kind == "ancestors":
        found = closure(x, parents)
    elif kind == "descendants":
        found = closure(x, children)
    elif kind == "siblings":
        found = siblings(x)
    else:
        found = cousins(x)
    print(" ".join(sorted(found)) if found else "none")
