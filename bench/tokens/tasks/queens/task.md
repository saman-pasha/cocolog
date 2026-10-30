# N queens

The input is one integer N, from 1 to 9.

Print, on the first line, the number of ways to place N queens on an N by N
chessboard so that no two attack each other: no two share a row, a column or
a diagonal.

On the second line print the first such placement in lexicographic order, as
N numbers separated by single spaces: the column, from 1 to N, of the queen
in row 1, then in row 2, and so on to row N. If there is no placement, print
`none` on the second line.

Example input:

```text
4
```

Example output:

```text
2
2 4 1 3
```
