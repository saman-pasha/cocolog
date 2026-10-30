import sys
from collections import deque

nums = iter(map(int, sys.stdin.read().split()))
n, m = next(nums), next(nums)
adj = {u: [] for u in range(1, n + 1)}
for _ in range(m):
    u, v = next(nums), next(nums)
    adj[u].append(v)
for _ in range(next(nums)):
    s, t = next(nums), next(nums)
    dist = {s: 0}
    queue = deque([s])
    while queue and t not in dist:
        u = queue.popleft()
        for v in adj[u]:
            if v not in dist:
                dist[v] = dist[u] + 1
                queue.append(v)
    print(dist.get(t, -1))
