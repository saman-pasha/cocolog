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

# libtool: Cicili compiles and links through it.
if command -v libtool >/dev/null 2>&1; then say "libtool" "$(libtool --version | head -1)"
else bad "libtool" "apt-get install -y libtool"; fi

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
  if python3 -c "import torch;raise SystemExit(0 if torch.cuda.is_available() else 1)" >/dev/null 2>&1; then
    say "cuda" "$(python3 -c 'import torch;print(torch.cuda.get_device_name(0))' 2>/dev/null)"
  else
    say "cuda" "no GPU visible -- training runs on the CPU (Runtime -> Change runtime type)"
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
