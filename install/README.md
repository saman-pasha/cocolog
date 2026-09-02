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
* `WITH_TORCH=1` installs a libtorch — `brew install pytorch` on macOS,
  `pip install torch` on Linux — so `library(torch)` builds. Without it the
  module is SKIPPED, which the modules step says; everything else is
  unaffected, since the cocolog binary links no libtorch.
* `CICILI=/path`, `ZIGURATIP=/path` name checkouts elsewhere; the defaults
  are the two directories beside this one, cloned there when absent.
* `CICILI_CC=gcc CICILI_CXX=g++` builds with gcc and needs no clang (Linux).
  On Red Hat Enterprise Linux and its rebuilds, `sbcl` is in EPEL.
* `LOG=/path` moves the logs from `/tmp/cocolog-install.*`.

`library(ray)` needs raylib and is not installed by either script;
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
