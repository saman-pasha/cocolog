# Calculator

Each line of the input is meant to be an arithmetic expression built from
non-negative integer literals, the binary operators `+`, `-`, `*` and `/`,
unary minus, and parentheses, with any number of spaces (including none)
between the tokens.

`*` and `/` bind tighter than `+` and `-`, and operators of the same
precedence group to the left, so `10 - 4 - 3` is 3. Unary minus binds tighter
than all four: `-2 * 3` is `(-2) * 3`, `2 - -3` is 5 and `--4` is 4. `/` is
integer division that truncates toward zero: `7 / 2` is 3, `-7 / 2` is -3 and
`7 / -2` is -3.

For each line print its value, or `error` if the line is not such an
expression or divides by zero anywhere.

Example input:

```text
1 + 2 * 3
(1 + 2) * 3
7 / (2 - 2)
2 +
```

Example output:

```text
7
9
error
error
```
