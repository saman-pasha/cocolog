#!/bin/sh
# `call_metered/4' -- a goal under a ceiling, and WHAT IT COST.
#
# The engine has counted inferences since the day it was written: the
# machine runner prints "finished after N inference(s)", and
# `coco_engine_call_limited' fills in a `used' it keeps for its own
# accounting. Both of those are outside the proof -- one is C, the other a
# line on a terminal -- so nothing a PROGRAM ran could read the number.
# `call_metered/4' hands it to Prolog, and this case is what it promises.
#
# WHAT IS BEING CHECKED, and why each part is here:
#
#   IT IS A MEASUREMENT, NOT AN ECHO. A tiny goal under a huge ceiling
#   costs a tiny number, and ten times the work costs strictly more than
#   the work. A meter that answered the limit back, or a constant, would
#   pass a check that only asked whether it answered.
#
#   IT ANSWERS FOR A GOAL THAT FAILED, which is the whole reason it is not
#   `call_limited/3'. Searching for a proof that is not there is real work
#   -- it is precisely the work somebody would like to be free -- and a
#   meter that goes silent on failure cannot charge for it.
#
#   THE COUNT IS DETERMINISTIC ACROSS PROCESSES. Two invocations that
#   share nothing but the goal report the same number. That is the
#   property that makes a count usable as a PRICE: two parties who never
#   met can compute the same fee and check each other's arithmetic.
#
#   AND EVERY LAW `call_limited/3' HAS, this one has too, because it is the
#   same engine call underneath: the ceiling narrows to what an outer
#   budget has left, a limit below 1 is a domain error rather than
#   "unlimited", bindings survive only a success, and an exception inside
#   is an exception outside -- with the composition that makes a throwing
#   goal chargeable (a `catch/3' INSIDE the meter) checked beside it.
#
# No server: every check here is a `--local' proof, and the one that needs
# an outer budget uses `--embed' on a scratch directory, because `step' is
# the only thing that sets one.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-56s %s\n' "$1" "$(echo "$2" | cut -c1-20)"
  else
    printf 'FAIL %-56s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

[ -x "$C" ] || { echo "SKIP (build cocolog first)"; exit 0; }

q() { timeout 60 "$C" query "$1" 2>/dev/null \
      | grep -aE '^answer\(.*\)$' | head -1 | sed 's/^answer(//; s/)$//'; }

echo "-- the three outcomes, each with its count"
check "a goal that succeeds says so, and what it spent" \
  "$(q "call_metered(append(X, [c], [a,b,c]), 10000, U, R),
        ( integer(U), U > 0 -> W = R-counted ; W = R-U ),
        write(answer(W)), nl")" "true-counted"
# THE DIFFERENCE FROM call_limited/3, and the reason for the second
# predicate: /3 fails when the goal fails, which is the right shape for
# `once/1' and the wrong one for a meter. A failed search is work.
check "a goal that FAILS still answers, and still has a bill" \
  "$(q "( call_metered((between(1, 200, _), fail), 100000, U, R)
        -> ( integer(U), U > 100 -> W = R-counted ; W = R-U )
        ;  W = 'THE METER FAILED WITH THE GOAL' ),
        write(answer(W)), nl")" "failed-counted"
check "and a runaway is stopped, at its ceiling" \
  "$(q "call_metered((between(1, 100000000, _), fail), 5000, U, R),
        ( U >= 5000, U =< 5100 -> W = R-at_the_ceiling ; W = R-U ),
        write(answer(W)), nl")" "inference_limit_exceeded-at_the_ceiling"

echo
echo "-- it is a MEASUREMENT, not the argument read back"
# A meter that answered its own Limit, or any constant, would pass
# everything above. These two are what make it a number about the goal.
check "a small goal under a huge ceiling costs a small number" \
  "$(q "call_metered(true, 1000000, U, _),
        ( U < 100 -> W = small ; W = U ), write(answer(W)), nl")" "small"
check "ten times the work costs strictly more" \
  "$(q "call_metered((between(1, 100, _), fail), 100000, A, _),
        call_metered((between(1, 1000, _), fail), 100000, B, _),
        ( B > A -> W = more ; W = A-B ), write(answer(W)), nl")" "more"

echo
echo "-- the count is deterministic, which is what makes it a PRICE"
# Two processes that share nothing but the goal. This is the property a
# fee schedule stands on: whoever charges and whoever checks must arrive
# at the same number without talking to each other.
G="call_metered((between(1, 500, N), N > 499), 100000, U, _), write(answer(U)), nl"
A=$(q "$G")
B=$(q "$G")
check "two processes report the same number for the same goal" \
  "$(if [ -n "$A" ] && [ "$A" = "$B" ]; then echo "agreed"; else echo "$A vs $B"; fi)" \
  "agreed"
check "and it is the same number again in-process" \
  "$(q "call_metered((between(1, 500, N), N > 499), 100000, U1, _),
        call_metered((between(1, 500, M), M > 499), 100000, U2, _),
        ( U1 =:= U2 -> W = stable ; W = U1-U2 ), write(answer(W)), nl")" "stable"

echo
echo "-- the laws it shares with call_limited/3"
check "bindings survive a success" \
  "$(q "call_metered(append(X, [c], [a,b,c]), 10000, _, _),
        write(answer(X)), nl")" "[a,b]"
check "and the ceiling leaves none behind" \
  "$(q "call_metered((X = bound, between(1,100000000,_), fail), 5000, _, _),
        ( var(X) -> W = unbound ; W = X ), write(answer(W)), nl")" "unbound"
check "a ceiling of zero is refused, not read as unlimited" \
  "$(q "catch(call_metered(true, 0, _, _), error(E, _),
        ( E = domain_error(positive_integer, _) -> write(answer(refused))
        ; write(answer(other)) )), nl")" "refused"
check "a non-integer ceiling is a type error" \
  "$(q "catch(call_metered(true, plenty, _, _), error(E, _),
        ( E = type_error(integer, _) -> write(answer(type_error))
        ; write(answer(other)) )), nl")" "type_error"

echo
echo "-- a goal that throws, and how a caller charges for one anyway"
# The count is lost with the frame that carried it, which is honest: the
# ball is re-thrown exactly as `call_limited/3' re-throws it.
check "an exception inside is an exception outside" \
  "$(q "catch(call_metered((X is 1/0, write(X)), 10000, _, _), error(E, _),
        ( E = evaluation_error(zero_divisor) -> write(answer(reraised))
        ; write(answer(other)) )), nl")" "reraised"
# ...and this is the composition a caller that must bill everything uses:
# its own catch INSIDE the meter turns the throw into an outcome, which
# is counted like any other. Which exceptions are failures is the
# caller's policy, and a meter that decided would decide for everybody.
check "a catch INSIDE the meter makes a throwing goal chargeable" \
  "$(q "call_metered(catch((X is 1/0, write(X)), _, true), 10000, U, R),
        ( integer(U), U > 0 -> W = R-counted ; W = R-U ),
        write(answer(W)), nl")" "true-counted"

echo
echo "-- the outer budget narrows the meter too"
# A metered goal inside a metered turn cannot buy its way out of the
# turn's budget: the ceiling is the LOWER of the two, and the count comes
# back accordingly. `step' is the only thing that sets an outer budget,
# and `--embed' is one without a server.
D=$(mktemp -d)
KB="$D/meterkb"
mkdir -p "$KB"
if timeout 60 "$C" --embed "$KB" start metered \
     "call_metered((between(1,100000000,_), fail), 100000000, U, R),
      write(answer(R-U)), nl" >/dev/null 2>&1; then
  got=$(timeout 120 "$C" --embed "$KB" --steps 3000 step metered 2>&1 \
        | grep -aoE 'suspended at [0-9]+' | head -1)
  check "an outer budget of 3000 narrows an inner ceiling of 100 million" \
    "$(echo "$got" | grep -qE 'suspended at 3[0-9]{3}$' && echo narrowed || echo "$got")" \
    "narrowed"
else
  echo "FAIL could not start a machine in $KB"
  failures=$((failures + 1))
fi
rm -rf "$D"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
