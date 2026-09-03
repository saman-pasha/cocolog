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
| `numpy` | numpy arrays as handles, over numpy's C API and nothing Python-level: `.npy` and CSV files written and read in C, `np_store`/`np_fetch` into the knowledge base as rows or clause chunks | a python3 with numpy and a shared libpython |
| `opencv` | OpenCV 4 as predicates -- images as handles; imgcodecs, imgproc, drawing, features2d, objdetect (cascades, HOG, QR), photo, video, calib3d and dnn -- ONE Cicili `:cpp #t` file, the C++ as Cicili clauses over `cicili/lib/cpp/opencv`; `tutorials/opencv/` is its course | an OpenCV 4 with those modules, found through pkg-config (`libopencv-dev`, `opencv-devel`, or a source build into `~/opencv4`) |

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

And the emitter's habits, met while writing eight modules' C++ AS Cicili
(the traps of the language itself are in the Cicili checkout's
`CLAUDE.md` and `doc/DOC-CPP.md`):

* **A method call or a zero-argument call as an `if`/`?` condition
  breaks the emitter**: `(if (($ m empty)) …)`, `(if (torch::cuda::is_available) …)`.
  Every module defines `(DEFMACRO bool? (x) `(not (not ,x)))` and writes
  `(if (bool? (($ m empty))) …)`; a comparison works too.
* **A member reached through `$` must have a declared type, and a
  template-id is a type of its own**: `(decl) (struct (t<> std::vector CtLayer))`
  in the target (it emits nothing) before a struct holds one. A
  template-id spelled with a two-word builtin (`uchar`, `llong`) cannot be
  declared at all — write `u8`, `i64`.
* **What `(extern-c …)` defines is not visible by name outside the
  block.** Route through a file-local function (`ct_backend_name` calls
  nothing, `coco_tensor_backend_name` calls it).
* **One signature per name**, so where a class overloads (a getter and a
  setter, a bytes form and a stream form) declare the one the module
  reaches for and get the other effect another way: a `bufferstream` is
  BUILT from a string, a BigInt is negated by subtraction, a digest is
  taken through the stream overload for bytes and files alike.
* **`letin*` writes the DECLARED type of a call**, so a wrong declaration
  in the binding is a C++ error at the letin* — the LSTM forward's tuple
  was one; and `(t<> std::make_shared T)` infers nothing, so the
  shared_ptr is spelled: `(let (((t<> std::shared_ptr T) p . #'((t<> std::make_shared T)))) …)`.

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
