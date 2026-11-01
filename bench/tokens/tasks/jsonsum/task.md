# Numbers in JSON

The input is one JSON document, which may run over several lines. Print the
sum of every number in it: in arrays, in the values of objects, nested at any
depth. A number that only appears inside a string is not a number, and
neither are `true`, `false` and `null`. Every number in the input is an
integer, and the sum fits in 64 bits.

Example input:

```text
{"a": [1, 2, {"b": 3}], "c": "4", "d": true, "e": -5}
```

Example output:

```text
1
```
