#!/bin/sh
# What a Colab VM must have before the build starts -- checked, named and
# reported, rather than discovered twenty minutes later as a linker error.
#
# WHY THIS EXISTS. The notebook's install cell used to read
#
#     !apt-get -qq install -y build-essential sbcl >/dev/null 2>&1 || true
#
# which is three ways of not knowing: -qq quiets it, the redirect discards
# it, `|| true' forgives it. A Colab image with stale package lists fails
# that install, the cell prints nothing, and the first symptom is
# `sbcl: not found' inside a sub-make -- or, worse, a ZiguratIP that
# builds thirteen libraries instead of fourteen and a server that dies on
# its first insert. THE COST OF A HIDDEN ERROR IS THE TIME TO THE NEXT
# ONE, and here that was the whole build.
#
# Run it before building. Every line it prints is a fact about THIS VM;
# a missing tool names the package that carries it and stops.
#
#   sh colab/preflight.sh          # report and check
#
# Exit 0 means the build may start. Anything else names what is wrong.

fail=0
say() { printf '  %-22s %s\n' "$1" "$2"; }
bad() { printf '  %-22s MISSING -- %s\n' "$1" "$2"; fail=1; }

echo "== the machine"
say "os" "$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || uname -s)"
say "arch/cores" "$(uname -m), $(nproc 2>/dev/null || echo '?') cores"
say "memory" "$(awk '/MemTotal/{printf "%.1f GB", $2/1048576}' /proc/meminfo 2>/dev/null)"
say "disk here" "$(df -h . 2>/dev/null | awk 'NR==2{print $4" free"}')"

echo
echo "== the toolchain the build needs"

# The C and C++ compilers, and make. build-essential carries all three.
if command -v gcc >/dev/null 2>&1; then say "gcc" "$(gcc -dumpversion)"
else bad "gcc" "apt-get install -y build-essential"; fi
if command -v g++ >/dev/null 2>&1; then say "g++" "$(g++ -dumpversion)"
else bad "g++" "apt-get install -y build-essential"; fi
if command -v make >/dev/null 2>&1; then say "make" "$(make --version | head -1)"
else bad "make" "apt-get install -y build-essential"; fi

# SBCL runs Cicili, which emits every line of C in cocolog and of the
# storage engine in ZiguratIP. Without it there is no build at all, and
# its absence is the failure this file was written for.
if command -v sbcl >/dev/null 2>&1; then
  say "sbcl" "$(sbcl --version)"
else
  bad "sbcl" "apt-get update && apt-get install -y sbcl"
fi

# libtool: Cicili compiles and links through it -- config.lisp's compiler
# is literally ("libtool" "--tag=CC" "--mode=compile" "gcc" ...), so the
# SCRIPT at /usr/bin/libtool has to exist.
#
# AND THE PACKAGE THAT CARRIES IT IS `libtool-bin', NOT `libtool'.
# Debian and Ubuntu split them: `libtool' is architecture-independent and
# ships libtoolize, the m4 macros and the manuals; the script itself is
# in libtool-bin. Installing `libtool' therefore succeeds, prints
# nothing alarming, and leaves the build with no libtool -- which is
# precisely the shape of failure this file exists to name, and it named
# the wrong cure until a Colab run proved it.
if command -v libtool >/dev/null 2>&1; then say "libtool" "$(libtool --version | head -1)"
else bad "libtool" "apt-get install -y libtool-bin  (NOT libtool -- see the note here)"; fi

echo
echo "== libtorch, which the one cocolog binary links"
if python3 -c "import torch" >/dev/null 2>&1; then
  say "torch" "$(python3 -c 'import torch;print(torch.__version__)' 2>/dev/null)"
  say "torch lib" "$(python3 -c "import torch,os;print(os.path.join(os.path.dirname(torch.__file__),'lib'))" 2>/dev/null)"
  # THE ABI IS THE TRAP. A pip wheel built with _GLIBCXX_USE_CXX11_ABI=0
  # links against std::string spelled the old way; g++ here spells it the
  # new way by default, and the two do not resolve -- the error arrives at
  # the FINAL link as undefined `c10::' symbols full of __cxx11, long
  # after anything that could explain it. Recent wheels are ABI=1 and
  # match; an ABI=0 wheel needs -D_GLIBCXX_USE_CXX11_ABI=0 on every C++
  # translation unit that touches torch, which is a build change, not a
  # flag you can add at the end.
  abi=$(python3 -c "import torch;print(torch._C._GLIBCXX_USE_CXX11_ABI)" 2>/dev/null)
  if [ "$abi" = "True" ]; then
    say "torch C++11 ABI" "True -- matches g++'s default"
  elif [ "$abi" = "False" ]; then
    # LOUD, BUT NOT FATAL. This was fatal at first, and that was wrong:
    # it stopped the whole build -- ZiguratIP, the client, the
    # interpreter, all of which are indifferent to it -- over something
    # that can only break the FINAL link, and only the part of it that
    # touches libtorch. A warning that lets the build run and then fails
    # with a named cause is worth more than a refusal that guesses.
    printf '  %-22s %s\n' "torch C++11 ABI" "FALSE -- g++ defaults to the new spelling,"
    printf '  %-22s %s\n' "" "so the final link may fail on c10:: symbols"
    printf '  %-22s %s\n' "" "full of __cxx11. Not stopping: see COLAB.md."
  else
    say "torch C++11 ABI" "unknown (torch too old to say)"
  fi
  # THE GPU, ASKED TWICE, BECAUSE THE TWO ANSWERS CAN DIFFER -- and this
  # check used to throw the difference away. It was
  #
  #     if python3 -c "...torch.cuda.is_available()..." >/dev/null 2>&1
  #
  # which is the same "three ways of not knowing" this file was written
  # to stamp out, applied to the one question a GPU runtime exists to
  # answer: the redirect discarded the REASON torch said no, and the
  # report then blamed the runtime type -- advice already followed by
  # anyone reading it, on a machine sitting in GPU mode.
  #
  # So the DRIVER is asked first, by nvidia-smi, which knows nothing
  # about torch. A driver with no torch behind it and no driver at all
  # are different findings with different cures, and the cure for the
  # second one is not in the Runtime menu as often as it looks.
  gpus=$(nvidia-smi -L 2>&1)
  case "$gpus" in
    GPU\ *) driver_gpu=$(echo "$gpus" | head -1 | cut -c1-58) ;;
    *)      driver_gpu="" ;;
  esac

  cuda_err=$(python3 -c "import torch; torch.cuda.is_available()" 2>&1 >/dev/null \
             | grep -v '^ *$' | head -2)
  if python3 -c "import torch;raise SystemExit(0 if torch.cuda.is_available() else 1)" 2>/dev/null; then
    say "cuda" "$(python3 -c 'import torch;print(torch.cuda.get_device_name(0))' 2>/dev/null)"
  elif [ -n "$driver_gpu" ]; then
    # THE HARD CASE. The machine HAS a GPU and torch will not use it, so
    # nothing in the Runtime menu is the answer. Print what each side
    # believes and let the mismatch name itself.
    printf '  %-22s %s\n' "cuda" "the DRIVER sees a GPU and TORCH will not use it:"
    printf '  %-22s %s\n' "" "  $driver_gpu"
    printf '  %-22s %s\n' "" "  torch $(python3 -c 'import torch;print(torch.__version__)' 2>/dev/null), built for CUDA $(python3 -c 'import torch;print(torch.version.cuda)' 2>/dev/null), sees $(python3 -c 'import torch;print(torch.cuda.device_count())' 2>/dev/null) device(s)"
    printf '  %-22s %s\n' "" "  driver $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)"
    [ -n "$cuda_err" ] && echo "$cuda_err" | while read -r l; do
      printf '  %-22s %s\n' "" "  $l"
    done
    printf '  %-22s %s\n' "" "Not stopping: training falls back to the CPU."
  else
    # NO DRIVER AT ALL. Worth being precise about, because the obvious
    # cure is often already done: Colab hands back a CPU runtime when the
    # GPU quota is spent AND LEAVES THE DROPDOWN READING GPU, and a
    # runtime type changed without the session reconnecting looks the
    # same from in here.
    printf '  %-22s %s\n' "cuda" "no GPU on this VM -- nvidia-smi finds no device."
    printf '  %-22s %s\n' "" "  If the Runtime menu already says GPU, the menu is not"
    printf '  %-22s %s\n' "" "  the answer: check Runtime -> View resources for a GPU"
    printf '  %-22s %s\n' "" "  line, and Runtime -> Disconnect and delete runtime, then"
    printf '  %-22s %s\n' "" "  reconnect. Colab gives back a CPU VM when the GPU quota"
    printf '  %-22s %s\n' "" "  is spent and leaves the dropdown reading GPU."
    printf '  %-22s %s\n' "" "Not stopping: training runs on the CPU, slower."
  fi
else
  bad "torch" "it ships with Colab; off Colab: pip install torch"
fi

echo
echo "== the three checkouts"
for pair in "CICILI:${CICILI:-}:cicili.lisp" \
            "ZIGURATIP:${ZIGURATIP:-}:Makefile.global" \
            "COCOLOG:${COCOLOG:-}:cocolog.cicili"; do
  name=${pair%%:*}; rest=${pair#*:}; path=${rest%:*}; marker=${rest##*:}
  if [ -z "$path" ]; then bad "$name" "not set in the environment"
  elif [ -f "$path/$marker" ]; then say "$name" "$path"
  else bad "$name" "$path holds no $marker"; fi
done

echo
if [ "$fail" = 0 ]; then
  echo "preflight GREEN -- the build may start"
else
  echo "preflight RED -- fix what is named above, then run this again"
fi
exit $fail
