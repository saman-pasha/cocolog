# Library: one lesson per library that ships

*One of three tutorial categories — `../basics/` is the language, this
is what ships, `../torch/` is the deep end.*

    COCOLOG_LIBRARY=$PWD/library ./cocolog run tutorials/library/12-json.pl main

Set `COCOLOG_LIBRARY` for anything in tier 2 — it is a colon-separated
LIST and this puts our `library/` at the front of it. Tier 1 needs
nothing at all, which is what 00 is about.

## TIER 1 — compiled in or preloaded, no import needed

Sixteen libraries answer before the first goal runs. `use_module` on any
of them succeeds instantly and does nothing, which is why none is
written anywhere in this repository.

| file | library | teaches |
|---|---|---|
| 00-the-library-path | — | the two tiers, the four search directories, and how to check which tier something is in |
| 01-lists | `lists` | SWI's list library, and the ones people reimplement by mistake |
| 02-apply | `apply` | `maplist/2..5`, `foldl`, `include`, `exclude`, `partition` |
| 03-files | `files` | paths, globs, `read_file_to_codes/2` — and the stream layer that is not here |
| 04-builtins | `builtins` | the ISO core, `format/2`, `code_type/2`, `must_be/2` |
| 05-dcg | `dcg`, `dcg_basics` | `-->` at library scale, and SWI's `dcg/basics` |
| 06-assoc | `assoc` | an AVL map that is one term |
| 07-pairs | `pairs` | `Key-Value`, and the sort-by-key idiom |
| 08-ordsets | `ordsets` | sets as sorted lists, and why that is the right representation |
| 09-yall | `yall` | `[X]>>Goal`, and when a lambda beats a helper predicate |
| 10-aggregate | `aggregate` | counting and summing without building the list |
| 11-ugraphs | `ugraphs` | graphs as sorted adjacency lists, reachability, `top_sort/2` |

## TIER 2 — on the library path, loaded when asked

| file | library | is | needs |
|---|---|---|---|
| 12-json | `library/json.pl` | a term as JSON, both directions | — |
| 13-xml | `library/xml.pl` | an element tree, both directions | — |
| 14-html | `library/html.pl` | a page as a term, both directions | — |
| 15-http | `library/http.pl` | HTTP/1.1 as a grammar | — |
| 16-httpd | `library/httpd.pl` | a server whose pages are clauses | `tcp`, `thread` |
| 17-tcp | `library/tcp.so` | the socket seam | `sh modules/tcp/build.sh` |
| 18-thread | `library/thread.so` | threads and channels, sharing nothing | `sh modules/thread/build.sh` |
| 19-zigurat | `zigurat` | the database connection, steered from Prolog | a running server |
| 20-curl | `library/curl.so` | an HTTP client | libcurl |
| 21-bigint | `library/bigint.so` | integers that do not wrap | a built ZiguratIP |
| 22-torch | `library/torch.so` | Prolog that trains | libtorch |

22 is the introduction; `../torch/` is the collection.

## THE CONVENTION

**A new library gets a file here in the same commit.** The numbering is
one per library and a gap is visible, which is the point: a library with
no tutorial is a library nobody has demonstrated end to end. Each of the
twenty-nine above found something while it was being written — a
predicate that did not exist, an arity that was wrong, a return value
documented as `-1/0/1` and actually `<`/`=`/`>`.

Copy any file in here for the shape: a header saying the tier, the
import and the surface; a `main` that walks that surface with `must/3`;
the two helpers repeated at the bottom.
