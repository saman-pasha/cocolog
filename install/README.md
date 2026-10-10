# install/ — from a clone to a cocolog that answers, on one machine

Two scripts, one per operating system, and the part they share. Each one
takes a fresh checkout of cocolog to a built binary with ZiguratIP built
beside it, its Parsi objects compiled into the ZiguratIP home, and every
loadable module whose dependency is present.

| file | what it is |
|---|---|
| `install-linux.sh` | Debian and Ubuntu through `apt-get`, Fedora and the Red Hat family through `dnf`: the packages, a clang 16+ (Fedora's own; on Ubuntu clang 18 from apt.llvm.org, because apt's is 14), then the common part |
| `install-macos.sh` | macOS: the Xcode command line tools for clang, Homebrew for `sbcl`, `libtool`, `openssl@3` and, when asked, `pytorch`, then the common part |
| `common.sh` | sourced by both: the two sibling checkouts (found or cloned), the four Lisp systems Cicili is built from, ZiguratIP in Release with its **artifacts** checked, then `make`, `make schema`, `make modules`, and one query the binary must answer |

```sh
sh install/install-linux.sh        # or install-macos.sh
```

It ends by printing the exports a shell needs — `CICILI`, `ZIGURATIP`,
`ZIGURATIP_HOME`, the library path, and the libtorch trio when one was
found — for your shell profile. `make test` is the suite; the database
cases SKIP until a server is up, and the last line printed says how to
raise one.

## Knobs

* `NO_PACKAGES=1` skips the package step: no root, or already done.
* Run as yourself, the Linux script asks `sudo` only for the packages.
  `sudo sh install/install-linux.sh` works too: the packages go in as root,
  and everything after them runs again as the user who called `sudo`, in
  that user's own home. Quicklisp and `~/common-lisp` are found through
  `$HOME`, which `sudo` sets to `/root`, so done as root they landed where
  the user's own `sbcl` never looks. A root login with no `sudo` (a
  container, Colab) uses root's home, which is its own. The macOS script
  refuses root outright, as Homebrew does.
* `WITH_TORCH=1` installs a libtorch — `brew install pytorch` on macOS,
  `pip install torch` on Linux — so `library(torch)` builds. Without it the
  module is SKIPPED, which the modules step says; everything else is
  unaffected, since the cocolog binary links no libtorch. On Linux,
  `TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu` takes the CPU-only
  wheels, and a Python that refuses a system-wide install (PEP 668, Ubuntu
  24.04) is asked again with `--break-system-packages`. The version is
  `TORCH_SPEC`, `torch==2.13.*` unless told: 2.14's headers need C++20 and
  the module is compiled as C++17, so an unpinned install builds nothing. A
  machine that already has another torch (Colab's) gets 2.13 in its place;
  `TORCH_SPEC=torch` keeps whatever is there.
* `WITH_NUMPY=1` installs `python3` with its headers and NumPy on Linux, so
  `library(numpy)` builds. It is the one module that embeds CPython, and
  nothing else cocolog builds or runs needs Python, so neither script asks
  for `python3` without this or `WITH_TORCH=1`. (On macOS nothing is
  installed for it: a `python3` with NumPy and a shared libpython on `PATH`,
  as pyenv gives, is what the module looks for.)
* `WITH_OPENCV=1` installs OpenCV 4 — `libopencv-dev`, `opencv-devel`, or
  `brew install opencv` — so `library(opencv)` builds. Off by default, for the
  same reason: it is the largest thing either script would install.
* `WITH_RAY=1` gives `library(ray)` (and `library(clay_ray)`, which draws
  through it) a raylib. Homebrew has one; Ubuntu 24.04 does not, so on Linux
  raylib `RAYLIB_TAG` (6.0) is cloned beside the checkouts and built with PIC
  objects, as `modules/ray/build.sh` asks, together with X11 and GL headers
  and Xvfb — `test/ray.pl` runs its window under `xvfb-run` where there is no
  screen. `RAYLIB` in the environment names a raylib of your own instead.
* `CICILI=/path`, `ZIGURATIP=/path` name checkouts elsewhere; the defaults
  are the two directories beside this one, cloned there when absent.
* `CICILI_CC=...`, `CICILI_CXX=...` name a particular clang (`clang-18`, a
  path). Every build here is clang — the interpreter, ZiguratIP, every
  module and every Parsi object — and the scripts refuse a compiler that
  is not.
* On Red Hat Enterprise Linux and its rebuilds, `sbcl` is in EPEL.
* `LOG=/path` moves the logs from `/tmp/cocolog-install.*`. A log there
  that is not yours to write (an earlier run as root left it) is refused by
  name before anything is built, rather than read back as this run's failure.

## Quicklisp

When `$QUICKLISP_HOME` (`~/quicklisp`) has no Quicklisp, it is installed as
[its own page](https://www.quicklisp.org/beta/) says: `quicklisp.lisp` and
its signature are fetched, the signature is checked against Quicklisp's
release key with `gpgv` — the key is held to the fingerprint that page
publishes, `D7A3489DDEFE32B7D0E7CC61307965AB028B5FF7`, and nothing is
installed when it does not verify — and then `(quicklisp-quickstart:install)`.
Either way `(ql:add-to-init-file)` follows, unless `~/.sbclrc` loads a
Quicklisp already, so your own `sbcl` has it too. `gnupg` is among the
packages for this; with `NO_PACKAGES=1` and no `gpg`, the script stops and
says so.

`QUICKLISP_HOME` elsewhere than `~/quicklisp` wants Cicili 1.0.1 or later.
Every build runs `sbcl --script cicili.lisp`, which reads no `~/.sbclrc`, so
Cicili finds Quicklisp itself: from `$QUICKLISP_HOME`, or `~/quicklisp` when
that is unset. An older Cicili loads `(user-homedir-pathname)/quicklisp/setup.lisp`
and nothing else, and a Quicklisp anywhere else would install, load cicili,
and then fail every build with `Component "str" not found` — so against
such a checkout the scripts refuse it by name before Quicklisp is installed
(update the checkout, or make `~/quicklisp` a symlink to it), and so does
`colab/prereqs.sh`. It must be an absolute path, and it must stay exported
for every later build too; the exports printed at the end include it.

Without `WITH_RAY=1`, `library(ray)` is SKIPPED, and
`modules/ray/build.sh` says what it wants.

## The same lessons as colab/

`colab/prereqs.sh`, `preflight.sh` and `build.sh` are the Colab-shaped
version of this: the same package list, the same clang, the same Lisp
side. What one learned the other carries, and both say the two things that
cost real time: install the compiler **before** the first make, because a
make without one leaves ZiguratIP dependency files with no object rules
that are never regenerated; and on Ubuntu 22.04 the apt clang is 14 while
the compiler wrapper's flag needs 16.

## Tested where

`install-macos.sh` was run end to end on fresh clones of the three
checkouts on a macOS 26 Intel machine, under a HOME that had no Quicklisp:
ZiguratIP, cocolog, 38 schema objects, every module including torch and
ray, and the binary answering, in 7 min 26 s. `install-linux.sh` was run end
to end on an Ubuntu 22.04 Colab VM through its `apt-get` branch in 7 min
10 s, every module but `ray` (no raylib there, and it says so) -- a VM whose
packages the same commands had installed earlier that day, so the apt step
was exercised but not from empty. The `dnf` branch has not been run.

And from empty, inside `docker build` (the `Dockerfile` at the root), on
Ubuntu 24.04 on 2026-10-01: every package the apt branch names, the Lisp
side, ZiguratIP, cocolog, its schema and every module but torch, tensorflow
and ray, in 27 minutes over a slow connection -- 21 of them packages -- and
in 8 with the packages cached. The Dockerfile installs Ubuntu's own clang
18 first, so the apt.llvm.org branch was not taken. That run is what found
`library(numpy)` needing NumPy 2's headers (24.04 ships 1.26) and then not
starting on Linux; both fixed in 1.8.37.
