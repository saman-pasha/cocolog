import sys

nums = list(map(int, sys.stdin.read().split()))
n, w = nums[0], nums[1]
best = [0] * (w + 1)
for i in range(n):
    weight, value = nums[2 + 2 * i], nums[3 + 2 * i]
    for c in range(w, weight - 1, -1):
        best[c] = max(best[c], best[c - weight] + value)
print(best[w])
