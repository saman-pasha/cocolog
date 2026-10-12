#!/bin/sh
# tools/flow/zero.sh -- what the UNTRACED engine executes, counted to the
# instruction.
#
#     sh tools/flow/zero.sh [BINARY ...]        from the checkout root
#
# library(flow/debug) is built on one promise (DESIGN-flow.md 9.1): the run
# it explains is never slowed down, because everything it adds to the
# engine sits on a path only tracing takes. This is how that is checked.
# Each BINARY (./cocolog when none is named) runs three programs from
# bench/langs untraced under callgrind -- naive reverse (deterministic
# calls, registers, no choice point), eight queens (choice points, guards,
# findall/3, backtracking) and lookup (asserted facts, the index, an
# if-then-else) -- and two numbers are printed for each: the WORK, the
# instructions the program costs beyond the same program with no rep, and
# the work's PADDING, the no-op instructions among them.
#
# THE PADDING IS WHY THERE ARE TWO. Every binary here is built with
# -mbranches-within-32B-boundaries (CLAUDE.md, the owner's rule), which pads
# each jump off a 32-byte boundary with no-ops -- `nop' in its forms and
# `xchg %ax,%ax' -- chosen by where the jump falls. A change anywhere in the
# file moves the functions after it, and a function nobody touched pads
# differently: 1.10.12's first build ran `coco_try_clause' with three
# 2-byte no-ops fewer and two more instructions an inference, the code
# otherwise the same instruction for instruction. So a change that keeps
# its promise prints the same WORK LESS PADDING as the binary before it; the
# padding is reported, never hidden.
#
# One binary counted twice in one invocation answers the same to the last
# instruction. Compare within ONE invocation: the start-up reads the
# environment, and the same binary from another shell counts a hundred
# instructions more or less. Time is no evidence here -- this box drifts
# 20 % between runs of one build -- and the count is: CLAUDE.md, Measuring.
#
# Needs valgrind and objdump. About fifteen seconds a binary.

set -e
[ $# -eq 0 ] && set -- ./cocolog
for t in valgrind objdump; do
  command -v $t >/dev/null 2>&1 || { echo "zero.sh: no $t" >&2; exit 2; }
done
for b in "$@"; do
  [ -x "$b" ] || { echo "zero.sh: $b is not an executable" >&2; exit 2; }
done
TMP=${TMPDIR:-/tmp}/zero.$$
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

# the addresses of a binary's no-ops, one a line, as objdump writes them
nops() {
  objdump -d --no-show-raw-insn "$1" |
    awk -F'\t' '/^ *[0-9a-f]+:/ && ($2 ~ /nop/ || $2 ~ /^xchg +%ax,%ax/) {
                  a = $1; sub(/^ */, "", a); sub(/:.*/, "", a); print a }'
}

# one run under callgrind: "TOTAL PADDING", the answer checked. PADDING is
# the instructions callgrind counted at the binary's own no-op addresses
# (`--dump-instr': a cost line per instruction, its address absolute as
# 0x..., relative as +N or -N, or `*' for the last; the line after a
# `calls=' is the call's inclusive cost and is not the instruction's own).
ir() {
  valgrind --tool=callgrind --dump-instr=yes --dump-line=no \
           --callgrind-out-file="$TMP/cg" "$1" run "bench/langs/$2.pl" "$3" \
           > "$TMP/out" 2>&1
  _ans=$(grep -aoE '^answer\([^)]*\)' "$TMP/out" | head -1)
  [ "$_ans" = "$4" ] || { echo "zero.sh: $1 $2 $3 answered '$_ans', not $4" >&2; exit 1; }
  awk -v bin="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")" '
    function hex(s,   i, n, c) {
      n = 0; s = tolower(s); sub(/^0x/, "", s)
      for (i = 1; i <= length(s); i++) {
        c = index("0123456789abcdef", substr(s, i, 1)) - 1
        n = n * 16 + c
      }
      return n
    }
    FNR == NR { nop[hex($1)] = 1; next }
    /^summary:/ { total = $2; next }
    /^c?ob=\(/ {
      id = $0; sub(/^c?ob=\(/, "", id); sub(/\).*/, "", id)
      nm = $0; if (sub(/^c?ob=\([0-9]+\) /, "", nm)) name[id] = nm
      if ($0 ~ /^ob=/) cur = id
      next }
    /^calls=/ { skip = 1; next }
    /^(0x|\+|-|\*)/ {
      a = $1
      if (a ~ /^0x/) at = hex(a)
      else if (a ~ /^\+/) at += substr(a, 2) + 0
      else if (a ~ /^-/) at -= substr(a, 2) + 0
      if (skip) { skip = 0; next }
      if (name[cur] == bin && (at in nop)) pad += $2
      next }
    END { printf "%d %d\n", total, pad }
  ' "$TMP/nops" "$TMP/cg"
}

BINS="$*"
printf '%-24s' "program"
for b in $BINS; do printf ' %16s %10s' "work: $(basename "$b")" "padding"; done
printf ' %14s\n' "work less pad"
for t in "nrev main(100,20) answer(216498) main(100,0) answer(0)" \
         "queens main(8,1) answer(92) main(8,0) answer(0)" \
         "lookup main(2000,20) answer(499500) main(2000,0) answer(0)"; do
  set -- $t
  printf '%-24s' "$1 $2"
  less=""
  for b in $BINS; do
    nops "$b" > "$TMP/nops"
    set -- $t
    w=$(ir "$b" "$1" "$2" "$3")
    z=$(ir "$b" "$1" "$4" "$5")
    work=$(( ${w% *} - ${z% *} ))
    pad=$(( ${w#* } - ${z#* } ))
    printf ' %16s %10s' "$work" "$pad"
    less="$less $((work - pad))"
  done
  printf ' %s\n' "$less"
done
