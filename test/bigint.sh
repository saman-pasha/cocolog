#!/bin/sh
# library(bigint) -- Zigurat's arbitrary-precision integers as predicates.
#
# WHY THE CASE EXISTS, and it is not hypothetical: cocolog's own integers
# are 64 bits and they WRAP IN SILENCE. The first check asks `is/2' for
# the first product a decentralised exchange computes at the scale tokens
# actually use, and PINS THE WRONG ANSWER it gives. That check passing is
# the reason for every other check in the file; if a future cocolog grows
# wide integers it will fail, and this file should be read rather than
# patched.
#
# WHAT IS PINNED:
#
#   THE ARITHMETIC IS ZIGURAT'S, NOT A SECOND COPY. libCore is already
#   linked into cocolog for the embedded engine, so BigInt was in the
#   process before library(bigint) existed. These checks are that the
#   Prolog surface reaches it correctly, not that bignum arithmetic
#   works -- ZiguratIP's own suite covers that.
#
#   THE NUMBERS COME FROM OUTSIDE. 2^256 is a constant anyone can look
#   up; gcd(462,1071)=21 and 3*4=1 (mod 11) are school arithmetic;
#   2^1000 mod 1000007 = 783922 is reproducible in any language with
#   wide integers. Nothing here was computed by the thing being tested.
#
#   ARBITRARY PRECISION IS ARBITRARY COST, and the refusal must come
#   BEFORE the cost. bigint_pow(2,20000) is refused for naming a 6021
#   digit number; bigint_pow(2,10000) is allowed and answers 3011
#   digits. The first version of that guard estimated the size as
#   digits(base)*exponent, read 10000 for base 2 where the truth is
#   3011, and refused work it could easily have done -- so the estimate
#   is a logarithm now, and both sides of the line are checked here.
#
#   AND IT REFUSES TO TRUNCATE. bigint_int/2 gives a cocolog integer
#   back only when one can hold the value; above that it raises, because
#   the silent version of that conversion is the bug the whole library
#   exists to avoid.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-44s %s\n' "$1" "$(echo "$2" | cut -c1-28)"
  else
    printf 'FAIL %-44s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$C" ]; then echo "no cocolog binary at $C"; exit 1; fi

B="use_module(library(bigint))"
if ! "$C" query "$B, write(ok), nl" 2>/dev/null | grep -aq ok; then
  echo "SKIP (this build carries no bigint module)"
  exit 0
fi

q()   { timeout 120 "$C" query "$1" 2>/dev/null | grep -aoE "$2" | head -1; }
err() { timeout 120 "$C" query "$B, $1" 2>&1 \
        | grep -aoE 'bigint [a-z ]+|bigint does not fit an integer' | head -1; }

# ---- the reason ------------------------------------------------------
check "cocolog's 64-bit is/2 wraps, silently" \
  "$(q "X is 1000000000000000000*997, write(X), nl" '[0-9]+')" \
  "875820019684212736"
check "bigint gets it right" \
  "$(q "$B, bigint_mul('1000000000000000000', 997, X), write(X), nl" '[0-9]+')" \
  "997000000000000000000"

# ---- arithmetic, against numbers from the world ----------------------
check "2^256, a constant anyone can look up" \
  "$(q "$B, bigint_pow(2, 256, X), write(X), nl" '[0-9]{70,}')" \
  "115792089237316195423570985008687907853269984665640564039457584007913129639936"
check "and one less is 2^256-1" \
  "$(q "$B, bigint_pow(2,256,P), bigint_sub(P,1,X), write(X), nl" '[0-9]{70,}')" \
  "115792089237316195423570985008687907853269984665640564039457584007913129639935"
check "add"        "$(q "$B, bigint_add('99999999999999999999', 1, X), write(X), nl" '[0-9]+')" "100000000000000000000"
check "a negative difference is negative" \
  "$(q "$B, bigint_sub(5, 12, X), write(X), nl" '\-?[0-9]+')" "-7"
check "div is the floor" "$(q "$B, bigint_div(7, 2, X), write(X), nl" '^[0-9]+$')" "3"
check "mod"              "$(q "$B, bigint_mod(7, 2, X), write(X), nl" '^[0-9]+$')" "1"
check "div by zero raises" "$(err "bigint_div(5, 0, X)")" "bigint division by zero"

# ---- the number theory Zigurat brought with it -----------------------
check "gcd(462, 1071)"   "$(q "$B, bigint_gcd(462, 1071, X), write(X), nl" '^[0-9]+$')" "21"
check "lcm(4, 6)"        "$(q "$B, bigint_lcm(4, 6, X), write(X), nl" '^[0-9]+$')" "12"
check "3 * 4 = 1 (mod 11), so the inverse is 4" \
  "$(q "$B, bigint_inverse(3, 11, X), write(X), nl" '^[0-9]+$')" "4"
check "no inverse when not coprime, and it says so" \
  "$(err "bigint_inverse(4, 8, X)")" "bigint has no inverse"
check "2^1000 mod 1000007" \
  "$(q "$B, bigint_mod_pow(2, 1000, 1000007, X), write(X), nl" '^[0-9]+$')" "783922"
check "sqrt(10^36) is 10^18 exactly" \
  "$(q "$B, bigint_sqrt('1000000000000000000000000000000000000', X), write(X), nl" '[0-9]+')" \
  "1000000000000000000"
check "sqrt(10^36 - 1) is one less" \
  "$(q "$B, bigint_sqrt('999999999999999999999999999999999999', X), write(X), nl" '[0-9]+')" \
  "999999999999999999"

# ---- the cost guard, on both sides of its line -----------------------
check "2^10000 is allowed, and is 3011 digits" \
  "$(q "$B, bigint_pow(2,10000,X), atom_length(X,L), write(len(L)), nl" 'len\([0-9]+\)')" \
  "len(3011)"
check "2^20000 would be 6021, and is refused" \
  "$(err "bigint_pow(2,20000,X)")" "bigint result too large"

# ---- spelling --------------------------------------------------------
check "hex in, decimal out" "$(q "$B, bigint_dec('0xff', X), write(X), nl" '^[0-9]+$')" "255"
check "decimal in, hex out" "$(q "$B, bigint_hex(255, X), write(X), nl" '^[0-9a-f]+$')" "ff"
check "cmp <" "$(q "$B, bigint_cmp('99999999999999999999', '100000000000000000000', X), write(X), nl" '^[<=>]$')" "<"
check "cmp = at width" "$(q "$B, bigint_cmp('12345678901234567890123', '12345678901234567890123', X), write(X), nl" '^[<=>]$')" "="
check "an integer comes back an integer" \
  "$(q "$B, bigint_int('42', X), Y is X + 1, write(Y), nl" '^[0-9]+$')" "43"
check "2^64 will not fit one, and refuses to truncate" \
  "$(err "bigint_int('18446744073709551616', X)")" "bigint does not fit an integer"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
