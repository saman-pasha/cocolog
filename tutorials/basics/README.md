# Basics: the language, eleven lessons

*One of three tutorial categories — this is the language, `../library/`
is what ships, `../torch/` is the deep end.*

Nothing here needs a library path, a database, or a build flag. A
cocolog binary on its own runs every one of them:

    ./cocolog run tutorials/basics/01-facts-and-rules.pl main

| file | teaches |
|---|---|
| 01-facts-and-rules | a fact, a rule, a query, and what a variable is |
| 02-unification | the one operation underneath everything; `=`, `\=`, `==`, occurs check |
| 03-lists | `[H\|T]`, and why `append/3` runs backwards |
| 04-arithmetic | `is` vs `=`, integer division, the evaluable functors |
| 05-backtracking-and-cut | choice points, `!`, and the four shapes it appears in |
| 06-findall-and-friends | `findall`, `bagof`, `setof`, `aggregate_all` and the free-variable rule |
| 07-assert-and-retract | a program that edits itself, and `retract/1`'s determinism |
| 08-atoms-text-and-codes | atoms, codes, and the string type this Prolog does not have |
| 09-exceptions | failure is not an error; `catch/3`, `throw/1`, ISO error terms — and the three that are cocolog's: `cocolog_error/1`, an unbound context that matches anyway, cleanup by hand |
| 10-grammars | `-->`, `phrase/2,3`, pushback, and a parser that also generates |
| 11-the-knowledge-base | what makes THIS Prolog different: the store outlives the process |

Read them in order — each leans on the one before, and 11 is the one
that is not in any other Prolog book.

## Where cocolog differs, and every one of these is a lesson here

Each is checked by a `must/3` in the file that teaches it, so if one of
these ever stops being true the tutorial fails and names both answers.

* **`double_quotes` DEFAULTS to `codes`.** `"hi"` IS `[104,105]` in a
  file that says nothing — and every one of these eleven says nothing.
  There IS a string type, and a file gets one out of `"..."` only by
  setting the flag; 08 is the whole lesson, and the default is why
  `library(json)` needs `str/1`.
* **EVERY BUILTIN IS DETERMINISTIC.** Not one leaves a choice point,
  which retires the classic `retract(X), fail` failure-driven loop (07)
  and makes `atom_concat(A, B, abc)` with both unbound an
  `instantiation_error` rather than three solutions (08).
* **`2 ** 10` is `1024`, an integer** — not `1024.0` (04).
* **`type_error(evaluable, foo)`**, naming the atom, where SWI names
  `foo/0` (09).
* **The knowledge base is a DATABASE**, and `assertz` in one process is
  visible to the next one (11). That is the claim the whole project
  exists to make, and it is four lines of Prolog to see it.

## The two helpers, repeated in every file

`show/2` prints; `must/3` is why these are tests. Both are at the bottom
of all eleven files rather than in a shared one, on purpose: a tutorial
you can copy anywhere and run is worth six duplicated lines, and one
that needs a support file beside it stops working the moment it moves.
