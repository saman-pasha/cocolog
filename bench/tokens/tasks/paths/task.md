# Shortest paths

The first line of the input holds two numbers, N and M: a directed graph has
the nodes 1 to N and M edges. Each of the next M lines holds an edge `u v`,
from node u to node v; an edge may appear more than once, and may go from a
node to itself. The next line holds a number Q, and each of the next Q lines
holds a query `s t`.

For each query print, on a line of its own, the number of edges on a
shortest path from s to t: 0 when s and t are the same node, and -1 when t
cannot be reached from s.

Example input:

```text
4 3
1 2
2 3
3 1
3
1 3
3 2
1 4
```

Example output:

```text
2
2
-1
```
