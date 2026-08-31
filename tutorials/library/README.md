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
| 23-sha | `library/sha.so` | digests and HMAC | a built ZiguratIP |
| 24-aes | `library/aes.so` | a block cipher, and what it does not do | a built ZiguratIP |
| 25-der | `library/der.so` | the encoding everything X.509 is made of | a built ZiguratIP |
| 26-x509 | `library/x509.so` | certificates, and the CA that issues them | a built ZiguratIP |
| 27-ca | `library/ca.pl` | a certificate authority, as rules | `x509` |
| 28-tls | `library/tls.so` | a connection that knows who is on it | a built ZiguratIP |
| 29-ray | `library/ray.so` | a game window, 2D and 3D, from clauses | raylib |
| 30-hex | `library/hex.pl` | hexagonal-grid arithmetic | nothing |
| 31-astar | `library/astar.pl` | shortest paths over a graph of goals | nothing |
| 32-process | `library/process.so` | run, capture, spawn, wait, kill | `sh modules/process/build.sh` |
| 33-text | `library/text.so` | grep, sed and the line tools, as clauses | `sh modules/text/build.sh` |
| 34-kbs | `library/kbs.pl` | many knowledge bases from one script | a running server |
| 35-os | `library/os.so` | which system, who am I, cores, environment | `sh modules/os/build.sh` |
| 36-llm | `library/llm.pl` | a language model as a GOAL | `curl`, an API key |
| 37-lint | *(a tool, not a library)* | cocolint: the dialect linter, and why it is clauses | nothing |

22 is the introduction to torch; `../torch/` is the collection. 37 is the
odd one out and says so in its header: cocolint is a TOOL under
`tools/coco-agent`, not a library on the path, so there is no
`use_module(library(lint))' and the lesson loads its two halves by plain
path instead.

## THE CONVENTION

**A new library gets a file here in the same commit.** The numbering is
one per library and a gap is visible, which is the point: a library with
no tutorial is a library nobody has demonstrated end to end. Each of the
thirty-eight above found something while being written — a predicate that
did not exist, an arity that was wrong, a return value documented as
`-1/0/1` and actually `<`/`=`/`>`. 37 found an arithmetic slip in its own
claim: it asserted that `halt' begins at offset 3 of `"x halt y"' and the
must/3 answered 2.

Copy any file in here for the shape: a header saying the tier, the
import and the surface; a `main` that walks that surface with `must/3`;
the two helpers repeated at the bottom.
