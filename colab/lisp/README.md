# The two Lisp systems Cicili needs and nothing ships

`cicili.asd` says

```lisp
:depends-on ("sha1" "base64" "str" "cl-ppcre")
```

Two of those four come from Quicklisp — `str` (the `cl-str` library, whose
system really is named `str`) and `cl-ppcre`. **The other two exist under
those names nowhere public.** They are small local systems, and on the
machine this project was developed on they sit in `~/common-lisp/`, found
by ASDF's default source registry and therefore invisible: the build
worked for years and nobody had to know why.

Colab is where that stopped being invisible. A fresh VM has no
`~/common-lisp`, so `(asdf:load-system "cicili")` answers

```
Unhandled ASDF/FIND-COMPONENT:MISSING-COMPONENT: Component "cicili" not found
```

— and every later failure in that build (`cannot find -lMVCCS`, no
`parsi`, no `ziguratip`) is downstream of it.

They are copied here rather than reimplemented against `ironclad` and
`cl-base64`, and the reason is in `core.lisp`:

```lisp
(intern (format nil "cicili~A" ... (sha1:sha1-base64 r-name #'base64:base64-encode) ...))
```

**Cicili derives generated module names from this digest.** A different
SHA-1 or a differently-padded base64 would produce different C symbol
names — not wrong, but not the same, and "not the same" is the thing a
compiled object in a ZiguratIP home cannot survive. Byte-identical
shims give byte-identical names.

`colab/prereqs.sh` copies both into `~/common-lisp/` and symlinks the
Cicili checkout beside them, which is all ASDF needs.

**This is a Cicili packaging gap, not a Cicili bug**, and Cicili is
frozen: the proper fix is upstream, either vendoring these two under
`lib/` or depending on `ironclad` and `cl-base64` and accepting the
one-time change of generated names. Until then this directory is the
diagnosis made runnable.
