# `modules/` — the seventeen loadable modules

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
| `thread` | threads and channels, sharing nothing -- plus mutexes and condition variables for what they DO share, which is everything outside the interpreter | nothing |
| `process` | run, capture, spawn, wait, kill -- the test-suite vocabulary (`timeout ... \| grep`, check/3, the sleep-poll loop) as predicates, so a suite can be a .pl file | nothing |
| `text` | grep, sed and the line tools as clauses over libc's own POSIX regex (`re_match`, `re_first`, `re_replace` with & and \1..\9; lines, head, tail, chomp in the Prolog half) | nothing |
| `os` | which operating system, who am I, how many cores, what is in the environment, where is a tool -- the questions a suite used to put to `uname`, `command -v`, `nproc` and `$TMPDIR`, answered by libc | nothing |
| `curl` | an HTTP client | libcurl |
| `bigint` | `Zigurat::BigInt` — integers that do not wrap | a built ZiguratIP |
| `torch` | Prolog that trains | libtorch |
| `sha` | SHA-1/224/256/384/512 and HMAC | a built ZiguratIP |
| `aes` | AES-128/192/256, CBC and ECB | a built ZiguratIP |
| `der` | Distinguished Encoding Rules, both directions | a built ZiguratIP |
| `x509` | certificates, and the CA that issues them | a built ZiguratIP |
| `tls` | a secure connection: `library(tcp)` with a handshake | a built ZiguratIP |
| `tensorflow` | the same `tensor_*` predicates over TensorFlow's C library, as a second BACKEND behind `library(torch)`'s switch -- `tensor_execution(tensorflow, graph)` and every call after it is TensorFlow's | libtensorflow (the C API) |
| `ray` | raylib as predicates, 2D, 3D, textures and input. **The caller owns the game loop**, which is why raylib and not another engine: input is polled, a frame is what happens between `BeginDrawing` and `EndDrawing`, and nothing calls back. A texture is a handle in the module's own table, a sprite is a `rect/4` of one, and a canvas (a texture drawn into) draws like any other, the right way up | raylib |
| `numpy` | numpy arrays as handles, over numpy's C API and nothing Python-level: `.npy` and CSV files written and read in C, `np_store`/`np_fetch` into the knowledge base as rows or clause chunks | a python3 with numpy and a shared libpython |
| `opencv` | OpenCV 4 as predicates -- images as handles; imgcodecs, imgproc, drawing, features2d, objdetect (cascades, HOG, QR), photo, video, calib3d and dnn -- ONE Cicili `:cpp #t` file, the C++ as Cicili clauses over `cicili/lib/cpp/opencv`, plus ONE vendored C file: `pil/Resample.c` is Pillow 11.3.0's antialiased resize, unchanged, behind `cv_resample` (the shim `pil/Imaging.h` declares what it reads, `pil/pil-resample.c` allocates and carries a Mat's bytes across); `tutorials/opencv/` is its course | an OpenCV 4 with those modules, found through pkg-config (`libopencv-dev`, `opencv-devel`, or a source build into `~/opencv4`) |

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

And one that bites the raw-C escape in any module: **a `(code "...")`
statement gets its `;` from the emitter.** Write one inside the string and
the line carries two, the second an empty statement -- harmless anywhere
except between an `if` and its `else`, where it ends the `if` and clang
says `expected expression` at the `else`, a line with nothing wrong on it.
`modules/process/process.cicili`'s spawn is written without them.

And one that bites the SDK side of any module, C or C++: **an error call's
value is the machine's, and it is RETURNED, never tested.** `coco_m_domain_error`
and its siblings answer a value that is neither 1 nor 0, and a predicate
returns it as its own answer. A helper that calls one and is then tested as
a boolean -- `(if (not (t_execution2 e g)) (return 0))` -- goes on, succeeds
OVER the raised error, and the machine loses the continuation: a
`catch/3` around the call reports one answer and runs nothing after it,
which is how tutorial 42's `predict` stopped drawing on a machine without
library(tensorflow). Keep the value: `(let ((int r . #'(helper e g))) (if (!= r 1) (return r)))`.

## Output is never committed

The `.o`, the `.so`, the C or C++ Cicili generates, **and the symlinks**
— `sdk.cicili` points inside this checkout and `zigheaders` inside
ZiguratIP's, and both dangle in anyone else's clone.

The test is to delete everything a `build.sh` makes and run it. What
comes back was output; what does not was source.

## A proposal, not applied: naming the no-window crash

**A ray drawing call with no window open segfaults**, and nothing catches
it — no ball, no message, no exit status a caller can read. Confirmed on
this binary and on the module as it stood before 1.2.15, so it is raylib's
rather than ours and it predates the guard work:

```sh
cocolog query 'use_module(library(ray)), catch(ray_circle(1,2,3,white), E, true)'
# exit 139
```

This is written down rather than done because it touches how every ray
predicate is entered, and that is the owner's call. **CivV makes the case
better than "it is cheap"**: a segfault with no ball is indistinguishable
from a memory death, and a session there went a day down that road before
the cause turned out to be elsewhere. A crash that names itself is worth
more than the crash it replaces. CivV also checked and is **not exposed
today** — three independent reasons, not an absence of reports: nothing in
that program polls the close flag, its six `ray_open` sites each pair with
their own close or a deliberate `halt/1`, and nothing draws off the main
thread.

**THE SHAPE IS THE TABLE'S, not twenty-eight edits.** `*ray-predicates*`
already drives the dispatcher through `coco-emit-module-dispatch`, which
reads a row's first three elements and ignores the rest — so a **fourth
element** marks the rows that need a window and a second small emitter
turns those into a name test:

```lisp
("$ray_circle"     7 ray_p_circle       t)     ; needs a window
("ray_open"        3 ray_p_open)               ; makes one
("ray_ready"       0 ray_p_ready)              ; asks about one
("$ray_log_level"  1 ray_p_log_level)          ; neither

(DEFMACRO ray-emit-needs-window (fname table)
  (LET ((rows (REMOVE-IF-NOT #'FOURTH (SYMBOL-VALUE table))))
    `(func ,fname ((const char * name)) (out int)
       (cond ,@(MAPCAR (LAMBDA (r) `((== 0 (strcmp name ,(FIRST r))) (return 1)))
                       rows)
             (#t (return 0))))))
```

and one wrapper in front of the generated dispatcher:

```lisp
(static) (coco-emit-module-dispatch ray_dispatch_open *ray-predicates*)
(static) (ray-emit-needs-window ray_needs_window *ray-predicates*)

(static)
(func ray_dispatch ((coco_engine * e) (const char * name) (u32 arity)
                    (size_t g) (int * found)) (out int)
      ;; THE READY TEST COMES FIRST AND IS THE WHOLE COST. A window is open
      ;; on every call but the broken one, so the name chain below is walked
      ;; only when there is no window at all -- never on the hot path.
      (if (not (rw_ready))
          (if (ray_needs_window name)
              (return (coco_m_existence_error e "ray_window"
                                              (coco_m_new_atom e name)))))
      (return (ray_dispatch_open e name arity g found)))
```

**What it costs**: one `IsWindowReady()` per ray call, which is a field
read behind a function call. A frame loop makes thousands of those a
second, so it is not free and it is not measurable either; if it ever
were, the answer is a cached flag set by `ray_open`/`ray_close` rather
than a call. `lib/sdk.cicili` is untouched — the guard is ray's business
and every other module keeps the dispatcher it has.

**What it does not fix**, and the reason to hold the claim narrow: a
window that raylib tore down on its own (the platform layer failing, the
display going away) leaves `IsWindowReady()` answering what it last knew,
so this catches the ordered mistake — drawing before `ray_open`, or after
`ray_close`, or in a teardown path that drew one frame too many — and not
a context lost underneath a running program. That is the case worth
catching, because it is the one a program can be written wrong into.

**The error to raise is the open question.** `existence_error(ray_window,
Name)` reads as "the thing you are drawing on is not there", which is
true and is ISO's shape for it. `permission_error(draw, ray_window, Name)`
says it is an ordering mistake, which is nearer the cause. The module's
own rule is that a refusal FAILS and only a genuine error raises
(`test/ray.pl`: "existence_error for no file, failure for the rest"), and
this is a genuine error — a program that draws with no window is wrong,
where a program handed a closed texture handle may simply be finished with
it. So it raises, and the name is the thing left to choose.
