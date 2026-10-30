# Family relations

The input is a list of facts followed by a list of questions. A fact is a
line `parent X Y`: X is a parent of Y. A question is a line `ancestors X`,
`descendants X`, `siblings X` or `cousins X`. Names are words of lowercase
letters, every fact comes before every question, and nobody is their own
ancestor.

- The ancestors of X are X's parents, their parents, and so on.
- The descendants of X are X's children, their children, and so on.
- X and Y are siblings when they are two different people with at least one
  parent in common.
- X and Y are cousins when they are two different people who are not
  siblings, and a parent of X and a parent of Y are siblings.

For each question print, on a line of its own, the names it asks for in
alphabetical order, separated by single spaces, or `none` if there are none.

Example input:

```text
parent ann bob
parent ann cat
parent bob dan
parent cat eve
ancestors dan
cousins dan
siblings bob
```

Example output:

```text
ann bob
eve
cat
```
