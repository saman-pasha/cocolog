# Build order

Each line of the input holds two task names, `A B`, saying that task A must
be done before task B. A task name is a word of lowercase letters; the same
line may appear more than once.

Print an order that does every task named in the input exactly once and
keeps every line's rule. When several tasks could be done next, do the one
whose name comes first alphabetically. Print the order on one line, the names
separated by single spaces. If no such order exists, print `cycle`.

Example input:

```text
wash dry
dress leave
dry dress
eat leave
```

Example output:

```text
eat wash dry dress leave
```
