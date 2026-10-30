# Run-length encoding

Each line of the input is a command: the letter `E` or `D`, a space, and a
text of one or more letters (A to Z and a to z, upper and lower case being
different letters).

For `E`, print the text run-length encoded: each maximal run of one letter
repeated becomes the run's length in decimal followed by the letter, so
`aaabcc` becomes `3a1b2c`.

For `D`, the text is such an encoding, a count of one or more digits before
each letter; print the text it encodes, so `3a1b2c` becomes `aaabcc` and
`12z` becomes twelve `z`.

Example input:

```text
E aaabcc
D 3a1b2c
```

Example output:

```text
3a1b2c
aaabcc
```
