# Word frequencies

The first line of the input is a positive integer K, and the lines after it
are text. A word is a maximal run of ASCII letters (A to Z and a to z); two
words are the same when they are equal once lowered, so `The` and `the` are
one word, written `the`. The text may hold any characters, and its spaces
need not be single.

Print the K most frequent words, one per line, each as the word, a space and
the number of times it occurs. A word that occurs more often comes before
one that occurs less often, and words that occur equally often come in
alphabetical order. If the text has fewer than K different words, print all
of them; if it has none, print nothing.

Example input:

```text
3
the cat and the hat
The end
```

Example output:

```text
the 3
and 1
cat 1
```
