# `modules/` — the loadable modules

One directory each, all the same shape: a `.cicili`, a `build.sh`, and
output nobody commits. **None of them is part of `make`**, which is the
point: a cocolog with no libtorch, no ZiguratIP headers and no libcurl
still builds and still runs.

    make modules           # builds every one that can be built here,
                           # and says SKIPPED, by name, for the rest
    sh modules/sha/build.sh

| | is | needs |
|---|---|---|
| `tcp` | the socket seam: a handle is an index into this module's own table, never a descriptor | nothing |
| `thread` | threads and channels, sharing nothing | nothing |
| `process` | run, capture, spawn, wait, kill -- the test-suite vocabulary (`timeout ... \| grep`, check/3, the sleep-poll loop) as predicates, so a suite can be a .pl file | nothing |
| `text` | grep, sed and the line tools as clauses over libc's own POSIX regex (`re_match`, `re_first`, `re_replace` with & and \1..\9; lines, head, tail, chomp in the Prolog half) | nothing |
| `curl` | an HTTP client | libcurl |
| `bigint` | `Zigurat::BigInt` — integers that do not wrap | a built ZiguratIP |
| `torch` | Prolog that trains | libtorch |
| `sha` | SHA-1/224/256/384/512 and HMAC | a built ZiguratIP |
| `aes` | AES-128/192/256, CBC and ECB | a built ZiguratIP |
| `der` | Distinguished Encoding Rules, both directions | a built ZiguratIP |
| `x509` | certificates, and the CA that issues them | a built ZiguratIP |
| `tls` | a secure connection: `library(tcp)` with a handshake | a built ZiguratIP |

`MODULES.md` at the root is the mechanism; this is the inventory.

## What the five ZiguratIP crypto modules share

They bind `Zigurat::SHA`, `Zigurat::AES`, `Zigurat::DER`,
`Zigurat::X509` and `Zigurat::tlsstream` — the same code ZiguratIP's own
`ca` tool and secure server use. **There is no hash, cipher or ASN.1 implementation in any of
them**: a second implementation would be a second thing to disagree with
the first.

`tls` is the one that keeps a C++ object alive across calls, and it is
the pattern to copy for anything else that has to: the `tlsstream` never
leaves the module, and Prolog is handed an index into a 256-slot table
— `modules/tcp`'s rule, applied to something that is not a descriptor.

`der` is the odd one and deliberately so: it links **libEncoding, Core
and StreamIO and nothing else** — no libCryptography, no OpenSSL —
because `Zigurat::DER` is an *encoding* rather than a secret. Everything
a certificate is made of can be taken apart with no cipher in the
process.

## Three things that bite a `:cpp #t` module

Each cost real time and each is written out at the top of the file that
hit it:

* **Declare the SDK's prototypes RAW, inside `extern "C"`, BEFORE
  `(coco-sdk)`.** C++ otherwise gives them C++ linkage, the `.so` links
  cleanly, and `use_module` fails with
  `undefined symbol: _Z11coco_m_textP18coco_engine_opaquemPcm`.
  Wrapping `(coco-sdk)` in `(extern-c ...)` is **not** the fix: a Cicili
  macro must emit ONE form, and several leaves every symbol unregistered
  — the next reference is `unknown symbol: coco_m_domain_error`, which
  names the use and not the cause.
* **Name every transitive dependency on the link line.** `-rpath`
  applies to what *this* link records as needed; a library the loader
  reaches through another is looked for on the system path.
  `libConfiguration.so: cannot open shared object file`, at
  `use_module`, from a link that succeeded.
* **Which library a symbol is in is not guessable, and a miss LINKS
  FINE** — a shared object may leave a symbol undefined.
  `nm -D --defined-only` over `$ZIGURATIP/home/lib` settles it.

And one that bites the Prolog half: **`$`-prefixed predicate names must
be quoted.** `$` is a symbol character and `x` is alphanumeric, so
`$x509_issue` is two tokens to the reader and the clause will not read —
surfacing as `use_module: its clauses would not consult`, which names
the module and not the line.

## Output is never committed

The `.o`, the `.so`, the C or C++ Cicili generates, **and the symlinks**
— `sdk.cicili` points inside this checkout and `zigheaders` inside
ZiguratIP's, and both dangle in anyone else's clone.

The test is to delete everything a `build.sh` makes and run it. What
comes back was output; what does not was source.
