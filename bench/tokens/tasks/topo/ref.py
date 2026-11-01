import heapq
import sys

edges = [line.split() for line in sys.stdin.read().splitlines() if line]
nodes = {x for e in edges for x in e}
indegree = {x: 0 for x in nodes}
after = {x: [] for x in nodes}
for a, b in edges:
    after[a].append(b)
    indegree[b] += 1
ready = sorted(x for x in nodes if indegree[x] == 0)
order = []
while ready:
    x = heapq.heappop(ready)
    order.append(x)
    for y in after[x]:
        indegree[y] -= 1
        if indegree[y] == 0:
            heapq.heappush(ready, y)
print(" ".join(order) if len(order) == len(nodes) else "cycle")
